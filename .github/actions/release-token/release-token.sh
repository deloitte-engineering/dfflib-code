#!/usr/bin/env bash
# =============================================================================
# release-token.sh - Helpers sourced by .github/actions/release-token/action.yml
# =============================================================================
# Sourced (not executed) by the action's steps.
# =============================================================================

# release_token_guard <event> <ref>
# Succeeds only for a push or workflow_dispatch on refs/heads/main.
release_token_guard() {
  if [[ "$1" == push || "$1" == workflow_dispatch ]] && [[ "$2" == refs/heads/main ]]; then
    return 0
  fi
  echo "::error::release-token only runs on push or workflow_dispatch to refs/heads/main (got event '$1', ref '$2')"
  return 1
}

# release_token_require <has-token>
# Succeeds when a token is given. The flag is "true"/"false".
release_token_require() {
  if [[ "$1" == true ]]; then return 0; fi
  echo "::error::release-token: no token configured; set secrets.RELEASE_TOKEN on the release environment" >&2
  return 1
}

# release_token_identity
# Prints git-user/git-email GITHUB_OUTPUT lines for the token owner. Needs
# GH_TOKEN set to the token.
release_token_identity() {
  local login id who
  who="$(gh api user --jq '.login + " " + (.id | tostring)')" || who=""
  login="${who% *}"
  id="${who##* }"
  if [[ -z "${login}" || ! "${id}" =~ ^[0-9]+$ ]]; then
    echo "::error::release-token: could not look up the token's GitHub user" >&2
    return 1
  fi
  echo "git-user=${login}"
  echo "git-email=${id}+${login}@users.noreply.github.com"
}
