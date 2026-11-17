// =============================================================================
// assemble-guards.cjs - the guards of the Assembled tree
// =============================================================================
// Each guard is a pure function: file contents and listings in, an array of findings (strings) out.
// An empty array is a pass. The CLI (assemble.cjs) collects every finding, prints one
// annotation per finding and exits 1 when there is any.
// A guard exists only when neither the compiler nor the deploy validation would catch the problem.
// =============================================================================

// The two upstream repositories (the only allowed submodules) and the folder each lives in.
const SUBMODULES = [
  { path: 'dependencies/fflib-apex-common', url: 'https://github.com/apex-enterprise-patterns/fflib-apex-common' },
  { path: 'dependencies/fflib-apex-mocks', url: 'https://github.com/apex-enterprise-patterns/fflib-apex-mocks' },
];
const ALLOWED_KEYS = ['path', 'url', 'branch'];

// Parses .gitmodules text into { sections: [{ header, kind, name, keys: { key: value } }] }.
function parseGitmodules(text) {
  const sections = [];
  const stray = [];
  let current = null;
  for (const raw of text.replace(/\r\n?/g, '\n').split('\n')) {
    const line = raw.trim();
    if (line === '' || line.startsWith('#') || line.startsWith(';')) continue;
    const header = /^\[\s*([^\s\]"]+)(?:\s+"([^"]*)")?\s*\]$/.exec(line);
    if (header) {
      current = { header: line, kind: header[1].toLowerCase(), name: header[2], keys: {}, repeated: [] };
      sections.push(current);
    } else if (current) {
      const eq = line.indexOf('=');
      const key = (eq < 0 ? line : line.slice(0, eq)).trim().toLowerCase();
      if (Object.prototype.hasOwnProperty.call(current.keys, key)) current.repeated.push(key);
      current.keys[key] = eq < 0 ? '' : line.slice(eq + 1).trim();
    } else {
      stray.push(line);
    }
  }
  return { sections, stray };
}

const normaliseUrl = (url) => url.trim().toLowerCase().replace(/\.git$/, '').replace(/\/$/, '');

// Guard 1: the .gitmodules URL allowlist.
function checkGitmodules(text) {
  const findings = [];
  const { sections, stray } = parseGitmodules(text);
  const seen = new Set();
  for (const line of stray) findings.push(`.gitmodules has a line outside any section: ${line}`);
  for (const section of sections) {
    for (const key of section.repeated) findings.push(`.gitmodules repeats the key ${key} in ${section.header}`);
    if (section.kind !== 'submodule') {
      findings.push(`.gitmodules has a section that is not a submodule: ${section.header}`);
      continue;
    }
    for (const key of Object.keys(section.keys)) {
      if (!ALLOWED_KEYS.includes(key)) findings.push(`.gitmodules key not allowed in ${section.header}: ${key}`);
    }
    const expected = SUBMODULES.find((s) => s.path === section.keys.path);
    if (!expected) {
      findings.push(`.gitmodules submodule path not allowed: ${section.keys.path || '(none)'}`);
      continue;
    }
    if (seen.has(expected.path)) findings.push(`.gitmodules has more than one section for ${expected.path}`);
    seen.add(expected.path);
    if (normaliseUrl(section.keys.url || '') !== expected.url) {
      findings.push(`.gitmodules url for ${expected.path} is not the upstream repository: ${section.keys.url || '(none)'}`);
    }
  }
  for (const expected of SUBMODULES) {
    if (!seen.has(expected.path)) findings.push(`.gitmodules is missing the submodule ${expected.path}`);
  }
  return findings;
}

// Guard 2: the only tracked entries under dependencies/ are the two gitlinks (mode 160000), and the
// submodule status shows no +, - or U prefix. staged: `git ls-files -s -- dependencies`; status: `git submodule status`.
function checkGitlinks({ staged, status }) {
  const findings = [];
  const expected = SUBMODULES.map((s) => s.path);
  const links = new Set();
  const reported = new Set();
  for (const line of staged.split(/\r?\n/).filter((l) => l.trim() !== '')) {
    const m = /^(\d{6}) \S+ \d\t(.+)$/.exec(line);
    if (!m) { findings.push(`unreadable git index entry: ${line}`); continue; }
    const [, mode, file] = m;
    if (mode === '160000' && expected.includes(file)) links.add(file);
    else { findings.push(`tracked entry under dependencies/ is not one of the two gitlinks: ${file} (mode ${mode})`); reported.add(file); }
  }
  for (const p of expected) if (!links.has(p) && !reported.has(p)) findings.push(`gitlink missing: ${p}`);
  for (const line of status.split(/\r?\n/)) {
    if (/^[+\-U]/.test(line)) findings.push(`submodule status is not clean: ${line.trim()}`);
  }
  return findings;
}

// Guard 3: the output folder (assembled by default) is never committed and git ignores it. tracked: `git ls-files -- <folder>`;
// ignored: whether `git check-ignore` reports the folder as ignored (git's own answer, so negations and nested rules count).
function checkAssembledUntracked({ folder = 'assembled', tracked, ignored }) {
  const findings = [];
  const files = tracked.split(/\r?\n/).filter((l) => l.trim() !== '');
  if (files.length > 0) findings.push(`${folder}/ has tracked files (${files.length}), first: ${files[0]}`);
  if (!ignored) findings.push(`${folder}/ is not in .gitignore`);
  return findings;
}

// Guard 4: no duplicate names across the sources. files: [{ source, path, content? }] where path is relative
// to the source root and content is needed only for *.labels-meta.xml. The key starts at the first path segment
// that is a metadata type folder, so main/classes, main/default/classes and database/classes all give classes/X.cls.
// Names are compared case-insensitively. A file under no known type folder is a finding, so nothing is skipped silently.
const TYPE_FOLDERS = new Set([
  'applications', 'approvalprocesses', 'aura', 'classes', 'custommetadata', 'customobjecttranslations', 'datacategorygroups',
  'documents', 'email', 'flexipages', 'flows', 'globalvaluesets', 'groups', 'labels', 'layouts', 'lwc', 'objects',
  'objecttranslations', 'pages', 'permissionsets', 'permissionsetgroups', 'profiles', 'queues', 'quickactions', 'remotesites',
  'reports', 'roles', 'sharingrules', 'staticresources', 'tabs', 'triggers', 'translations', 'workflows', 'components', 'dashboards',
].map((s) => s.toLowerCase()));

const LABEL_FILE = /\.labels-meta\.xml$/i;

function typeKey(filePath) {
  const segments = filePath.split(/[\\/]+/).filter((s) => s !== '');
  const at = segments.findIndex((s) => TYPE_FOLDERS.has(s.toLowerCase()));
  return at < 0 ? null : segments.slice(at).join('/');
}

function labelNames(xml) {
  const names = [];
  for (const block of xml.match(/<labels>[\s\S]*?<\/labels>/g) || []) {
    const m = /<fullName>\s*([^<]+?)\s*<\/fullName>/.exec(block);
    if (m) names.push(m[1]);
  }
  return names;
}

function checkDuplicateNames(files) {
  const findings = [];
  const byKey = new Map();
  const add = (key, display, source) => {
    const k = key.toLowerCase();
    if (!byKey.has(k)) byKey.set(k, { display, sources: [] });
    byKey.get(k).sources.push(source);
  };
  for (const file of files) {
    const key = typeKey(file.path);
    if (key === null) {
      findings.push(`file under an unknown metadata type folder (${file.source}): ${file.path}`);
      continue;
    }
    if (LABEL_FILE.test(file.path)) {
      for (const name of labelNames(file.content || '')) add(`label:${name}`, `label ${name}`, file.source);
    } else {
      add(key, key, file.source);
    }
  }
  for (const { display, sources } of byKey.values()) {
    if (sources.length > 1) findings.push(`duplicate name ${display} in: ${sources.join(', ')}`);
  }
  return findings;
}

// Guard 5: no dfflib_ class references an fflib_X class that has a dfflib_X twin. files: [{ path, content }] of
// every Apex class and trigger of the Assembled tree. A dfflib_ class using an fflib_ class WITHOUT a twin is fine.
// The scan is a case-insensitive whole-word search of the raw source: comments and string literals count
// (Type.forName('fflib_X') is a real reference; a stale name in a comment is a documentation bug).
// A file name is untrusted input: escape it before it becomes part of a pattern.
// TWIN_ALLOWED_REFERENCES are the exact nested fflib types a dfflib_ class may reference for backward compatibility
// (legacy IDML implementations): they are removed before the scan, so any other reference to the twin still fails.
const escapeRegExp = (text) => text.replace(/[.*+?^${}()|[\]\\]/g, (c) => '\\' + c);
const TWIN_ALLOWED_REFERENCES = [
  'fflib_SObjectUnitOfWork.IDML',
  'fflib_SObjectUnitOfWork.IDMLUpsertable',
  'fflib_SObjectUnitOfWork.SimpleDML',
  'fflib_SObjectUnitOfWork.UserModeDML',
];
const ALLOWED_REFERENCE_PATTERN = new RegExp(`\\b(?:${TWIN_ALLOWED_REFERENCES.map(escapeRegExp).join('|')})\\b`, 'gi');

function checkTwins(files) {
  const base = (p) => p.split(/[\\/]/).pop().replace(/\.(cls|trigger)$/i, '');
  const names = new Map(files.map((f) => [base(f.path).toLowerCase(), base(f.path)]));
  const twins = [...names].filter(([lower]) => lower.startsWith('fflib_') && names.has(`d${lower}`));
  const findings = [];
  for (const file of files) {
    const name = base(file.path);
    if (!name.toLowerCase().startsWith('dfflib_')) continue;
    const content = file.content.replace(ALLOWED_REFERENCE_PATTERN, '');
    for (const [lower, original] of twins) {
      if (new RegExp(`\\b${escapeRegExp(lower)}\\b`, 'i').test(content)) findings.push(`${name} references ${original}, which has the twin ${names.get(`d${lower}`)}`);
    }
  }
  return findings;
}

// One workflow error annotation. %, CR and LF are escaped so a hostile file name or URL cannot start a second command.
function annotate(guard, item) {
  const escaped = `${guard}: ${item}`.replace(/%/g, '%25').replace(/\r/g, '%0D').replace(/\n/g, '%0A');
  return `::error::${escaped}`;
}

module.exports = { SUBMODULES, parseGitmodules, checkGitmodules, checkGitlinks, checkAssembledUntracked, checkDuplicateNames, checkTwins, annotate };
