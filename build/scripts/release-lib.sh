#!/usr/bin/env bash
# =============================================================================
# release-lib.sh - Helpers sourced by .github/workflows/unlocked-package.yml
# =============================================================================
# Sourced (not executed) by workflow steps so the logic lives in one place.
#
#   source build/scripts/release-lib.sh
# =============================================================================

# push_alias <branch>
# Pushes HEAD (the package alias commit) to <branch> on origin. On a
# non-fast-forward rejection (branch moved during the run) rebases once and
# retries. Prints "pushed" or "pending"; push errors go to stderr.
push_alias() {
  local branch="$1" err
  if err="$(git push origin "HEAD:${branch}" 2>&1)"; then
    echo pushed; return 0
  fi
  echo "${err}" >&2
  if grep -Eq '\[rejected\].*\((fetch first|non-fast-forward)\)' <<<"${err}" \
    && git fetch -q origin "${branch}" >&2 \
    && git rebase -q FETCH_HEAD >&2 \
    && git push origin "HEAD:${branch}" >&2; then
    echo pushed; return 0
  fi
  git rebase --abort >/dev/null 2>&1
  echo pending
  return 1
}

# make_latest_for <tag>
# Prints "true" when <tag> is the highest final (non-prerelease) v* tag, else
# "false", so resuming an older release never steals GitHub's "Latest" badge.
make_latest_for() {
  local highest
  highest="$(git tag --list 'v*' | grep -v -- '-' | sort -V | tail -n 1)"
  [[ "$1" == "${highest}" ]] && echo true || echo false
}

# install_url_outputs <04t ID>
# Prints the sandbox/production install URLs as GITHUB_OUTPUT lines.
install_url_outputs() {
  echo "sandbox_install_url=https://test.salesforce.com/packaging/installPackage.apexp?p0=$1"
  echo "production_install_url=https://login.salesforce.com/packaging/installPackage.apexp?p0=$1"
}

# package_name [sfdx-project.json]
# Prints the package of the default packageDirectory (or the only one), so no
# step hardcodes the package name. Non-zero when none is configured.
package_name() {
  local name
  name="$(jq -r '([.packageDirectories[] | select(.default == true)][0] // .packageDirectories[0]).package // empty' "${1:-sfdx-project.json}")"
  [[ -n "${name}" ]] || return 1
  echo "${name}"
}

# resolve_released_version <sf package version list --json stdout> <version>
# Prints the 04t ID of the promoted build of <version> (exact X.Y.Z.BUILD).
# Exit: 0 found, 2 non-JSON output, 3 version not in Dev Hub, 4 not promoted.
resolve_released_version() {
  local list="$1" version="$2" builds released
  jq empty <<<"${list}" 2>/dev/null || return 2
  builds="$(jq --arg v "${version}" '[(.result // [])[] | select(.Version == $v)]' <<<"${list}")"
  [[ "$(jq length <<<"${builds}")" -gt 0 ]] || return 3
  # The Dev Hub allows only one promoted build per version number.
  released="$(jq -r '[.[] | select(.IsReleased == true)][0].SubscriberPackageVersionId // empty' <<<"${builds}")"
  [[ -n "${released}" ]] || return 4
  echo "${released}"
}
