const fs = require('fs');
const file = process.cwd() + '/lib/screens/pdf_converter_screen.dart';
const lines = fs.readFileSync(file,'utf8').split('\n');
let patch = '*** Begin Patch\n*** Update File: '+file+'\n@@\n '+lines[0]+'\n+import \'../widgets/scrollable_sheet_body.dart\';\n';
for(let i=0;i<lines.length;i++) {
  if(lines[i].trim() !== 'child: Column(') continue;
  const prefix=lines.slice(Math.max(0,i-12),i).join('\n');
  if(!prefix.includes('return Container(') || !prefix.includes('MediaQuery.of(context).size.height')) continue;
  patch+='@@\n'+lines.slice(i-9,i).map(l=>' '+l+'\n').join('')+'-'+lines[i]+'\n+'+lines[i].replace('Column(', 'ScrollableSheetBody(')+'\n'+lines.slice(i+1,i+3).map(l=>' '+l+'\n').join('');
}
process.stdout.write(patch+'*** End Patch\n');
