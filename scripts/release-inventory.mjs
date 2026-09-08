import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, lstatSync, readFileSync, mkdirSync, writeFileSync } from 'node:fs';
import { dirname, resolve, relative, extname, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const paths = [...new Set(execFileSync('git', ['ls-files', '-z', '--cached', '--others', '--exclude-standard'], {
  cwd: root, encoding: 'utf8', maxBuffer: 16 * 1024 * 1024,
}).split('\0').filter(Boolean))].sort();
const excluded = /(^|\/)(node_modules|build|artifacts|\.dart_tool|\.git|\.agents|\.codex)(\/|$)|(^|\/)\.env(\.|$)|(^|\/)(key|local)\.properties$|\.(jks|keystore|p12|pem|mobileprovision)$|^config\/release\.json$/i;
const textExtensions = new Set(['.dart', '.ts', '.js', '.mjs', '.json', '.yaml', '.yml', '.md', '.xml', '.plist', '.pbxproj', '.kts', '.gradle', '.properties', '.sql', '.ps1', '.html', '.css', '.txt', '.template', '.swift', '.kt', '.h', '.cc', '.cpp', '.cmake']);
const files = [];
const runtimeWarnings = [];
for (const path of paths) {
  if (excluded.test(path)) continue;
  const absolute = resolve(root, path);
  const within = relative(root, absolute);
  if (within.startsWith('..' + sep) || within === '..' || !existsSync(absolute)) continue;
  const stat = lstatSync(absolute);
  if (!stat.isFile() || stat.isSymbolicLink()) continue;
  const bytes = readFileSync(absolute);
  const isText = textExtensions.has(extname(path)) || /(^|\/)(Dockerfile|Podfile|\.gitignore|_headers|_redirects)$/.test(path);
  if (isText && /^(lib\/|backend\/src\/)/.test(path) && !path.includes('/__tests__/')) {
    const lines = bytes.toString('utf8').split('\n');
    for (const [index, line] of lines.entries()) {
      if (/password123|demo credentials|seeded login|OTP.{0,20}123456/i.test(line)) {
        runtimeWarnings.push({ path, line: index + 1, reason: 'Legacy authentication placeholder' });
      }
    }
  }
  files.push({
    path, bytes: bytes.length,
    sha256: createHash('sha256').update(bytes).digest('hex'),
    ...(isText ? { lines: bytes.length === 0 ? 0 : bytes.toString('utf8').split('\n').length - (bytes.at(-1) === 10 ? 1 : 0) } : {}),
  });
}
const byDirectory = {};
for (const file of files) {
  const group = file.path.includes('/') ? file.path.split('/')[0] : '(root)';
  byDirectory[group] ??= { files: 0, textLines: 0 };
  byDirectory[group].files++;
  byDirectory[group].textLines += file.lines ?? 0;
}
const report = {
  generatedAt: new Date().toISOString(),
  scope: 'Versioned and non-ignored project files; excludes secrets, dependency installations and build output. Structural inventory, not proof of semantic review or security certification.',
  fileCount: files.length, byDirectory, runtimeWarnings, files,
};
mkdirSync(resolve(root, 'artifacts'), { recursive: true });
writeFileSync(resolve(root, 'artifacts/release-inventory.json'), JSON.stringify(report, null, 2) + '\n');
console.log(JSON.stringify({ fileCount: report.fileCount, byDirectory, runtimeWarnings, report: 'artifacts/release-inventory.json' }, null, 2));
if (runtimeWarnings.length) process.exitCode = 1;
