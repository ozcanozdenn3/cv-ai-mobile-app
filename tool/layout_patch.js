const fs = require('fs');
const path = require('path');
const root = process.cwd();
const targets = new Map();
for (const name of fs.readdirSync('/tmp').filter(n => n.startsWith('layout-details-'))) {
  const text = fs.readFileSync('/tmp/' + name, 'utf8');
  for (const m of text.matchAll(/Row:file:\/\/(.*?\.dart):(\d+):\d+/g)) {
    if (!m[1].startsWith(root)) continue;
    if (!targets.has(m[1])) targets.set(m[1], new Set());
    targets.get(m[1]).add(Number(m[2]) - 1);
  }
}
let patch = '*** Begin Patch\n';
for (const [file, numbers] of targets) {
  const lines = fs.readFileSync(file, 'utf8').split('\n');
  patch += '*** Update File: ' + file + '\n';
  if (!lines.some(l => l.includes("import '../widgets/responsive_row.dart'"))) {
    patch += '@@\n ' + lines[0] + '\n+import \'../widgets/responsive_row.dart\';\n';
  }
  for (const n of [...numbers].sort((a,b) => a-b)) {
    if (!/\bRow\(/.test(lines[n])) continue;
    patch += '@@\n' + lines.slice(Math.max(0,n-16),n).map(l=>' '+l+'\n').join('') +
      '-' + lines[n] + '\n+' + lines[n].replace(/\bRow\(/,'ResponsiveRow(') + '\n' +
      lines.slice(n+1,n+3).map(l=>' '+l+'\n').join('');
  }
}
process.stdout.write(patch + '*** End Patch\n');
