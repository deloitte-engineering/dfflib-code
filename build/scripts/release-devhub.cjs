// =============================================================================
// release-devhub.cjs - The Dev Hub adapter: read a package version, promote it
// =============================================================================
// The real form of the Dev Hub adapter, over the `sf` CLI. The interface any form has:
//   readVersion(ref)     Promise<row>              ref is a 04t ID or a package alias
//   promoteVersion(ref)  Promise<{ promoted: true }>
//   listVersions(package)                     Promise<row[]>
//   createVersion({ package, version, tag })  Promise<{ id, version }>   version is X.Y.Z; sf adds the build
// with row = { id, version, tag, isReleased, coverage, hasPassedCoverageCheck, validationSkipped }; the two
// check fields are true, false or null (the report has no recognisable value: unknown, never a pass).
// Failures are Errors with a `code`: 'not-found', 'already-promoted', 'auth', 'failed'.
// An in-memory form has the same interface and named fault modes.
// `run(args)` runs `sf` with the argument list and resolves to its stdout; when sf exits
// non-zero it rejects, and sf still prints its JSON error on stdout, which is read from the
// rejection (`error.stdout`).
// Observed from the Dev Hub CLI: the report keys normalise() reads, promote, and the error codes
// 'not-found' and 'auth'. UNVERIFIED: the error text 'already-promoted' is mapped from.
// No org is contacted by the tests.
// Used by publish (release-publish.cjs: read, promote) and by the beta build (release-beta.cjs
// buildBeta: list, create, read), which checks the coverage and validation fields of the versions
// it would reuse or record.
// CommonJS so actions/github-script can require() it from the checked-out repo.
// =============================================================================

const devHubError = (code, message) => Object.assign(new Error(message), { code });

// sf's JSON error -> the adapter's error code. The match is on sf's name and message.
function errorCodeOf(output) {
  const text = `${output.name || ''} ${output.message || ''}`;
  if (/auth|login|expired|NoOrg/i.test(text)) return 'auth';
  if (/already (been )?(released|promoted)/i.test(text)) return 'already-promoted';
  if (/not found|no package version|invalid.*id/i.test(text)) return 'not-found';
  return 'failed';
}

// CodeCoverage is a number, a text such as "82%" or an object with the percentage.
function coveragePercent(value) {
  if (value && typeof value === 'object') return Number(value.apexCodeCoveragePercentage);
  return Number.parseFloat(value);
}

// Unknown (null) is never read as a pass: the build check refuses it (release-rules.cjs).
const flag = (value) => (typeof value === 'boolean' ? value : null);

function normalise(report) {
  return {
    id: report.SubscriberPackageVersionId,
    version: report.Version,
    tag: report.Tag,
    isReleased: report.IsReleased === true,
    coverage: coveragePercent(report.CodeCoverage),
    hasPassedCoverageCheck: flag(report.HasPassedCodeCoverageCheck),
    validationSkipped: flag(report.ValidationSkipped),
  };
}

function sfDevHub({ run, targetDevHub }) {
  // Runs sf and returns the parsed JSON of a successful run; throws a coded error otherwise.
  async function sf(args) {
    let stdout;
    try {
      stdout = await run(args);
    } catch (error) {
      stdout = error.stdout;
      if (!stdout) throw devHubError('failed', `sf ${args.slice(0, 3).join(' ')} failed: ${error.message}`);
    }
    let output;
    try {
      output = JSON.parse(stdout);
    } catch {
      throw devHubError('failed', `sf ${args.slice(0, 3).join(' ')} did not print JSON`);
    }
    if (output.status !== 0) throw devHubError(errorCodeOf(output), output.message || `sf ${args.slice(0, 3).join(' ')} failed`);
    return output.result;
  }

  return {
    async readVersion(ref) {
      const result = await sf(['package', 'version', 'report', '--package', ref, '--target-dev-hub', targetDevHub, '--verbose', '--json']);
      const report = Array.isArray(result) ? result[0] : result;
      if (!report) throw devHubError('not-found', `No package version found for ${ref}`);
      return normalise(report);
    },
    // Every version of a package, as adapter rows (the list is verbose: it carries the coverage and validation fields).
    async listVersions(packageName) {
      const result = await sf(['package', 'version', 'list', '--verbose', '--packages', packageName, '--target-dev-hub', targetDevHub, '--json']);
      return (Array.isArray(result) ? result : []).map(normalise);
    },
    // Creates a version of `package` (X.Y.Z comes from `version`; sf takes the build number
    // from sfdx-project.json) and waits for it. Returns { id, version }; the row is read with
    // readVersion. Runs in the project directory of the build.
    async createVersion({ package: packageName, version, tag }) {
      const result = await sf(['package', 'version', 'create', '--package', packageName, '--code-coverage', '--installation-key-bypass',
        '--tag', tag, '--wait', '60', '--target-dev-hub', targetDevHub, '--json']);
      const id = result && result.SubscriberPackageVersionId;
      const created = result && result.VersionNumber;
      if (!id || !created) throw devHubError('failed', 'The create response has no SubscriberPackageVersionId or VersionNumber');
      if (!String(created).startsWith(`${version}.`)) throw devHubError('failed', `The created version ${created} is not a build of ${version}`);
      return { id, version: String(created) };
    },
    async promoteVersion(ref) {
      await sf(['package', 'version', 'promote', '--package', ref, '--target-dev-hub', targetDevHub, '--no-prompt', '--json']);
      return { promoted: true };
    },
  };
}

module.exports = { sfDevHub };