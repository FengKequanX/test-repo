const {execSync} = require('child_process');
const fs = require('fs');
const path = require('path');

function uploadFile(filePath, repoPath) {
  const content = fs.readFileSync(filePath);
  const base64 = Buffer.from(content).toString('base64');
  
  try {
    let sha = null;
    try {
      const existing = JSON.parse(execSync('gh api repos/FengKequanX/test-repo/contents/' + repoPath, {encoding: 'utf8'}));
      sha = existing.sha;
    } catch(e) {}

    let cmd = 'gh api -X PUT repos/FengKequanX/test-repo/contents/' + repoPath + ' -f message="Add ' + repoPath + '" -f content="' + base64 + '"';
    if (sha) cmd += ' -f sha="' + sha + '"';
    
    execSync(cmd, {encoding: 'utf8'});
    console.log('Uploaded:', repoPath);
  } catch(e) {
    console.log('Error:', repoPath, '-', e.message.split('\n')[0]);
  }
}

function walkDir(dir, baseDir) {
  const items = fs.readdirSync(dir);
  for (const item of items) {
    const fullPath = path.join(dir, item);
    const stat = fs.statSync(fullPath);
    
    if (item === '.git') continue;
    
    if (stat.isDirectory()) {
      walkDir(fullPath, baseDir);
    } else {
      const repoPath = path.relative(baseDir, fullPath).replace(/\\/g, '/');
      uploadFile(fullPath, repoPath);
    }
  }
}

walkDir('.', '.');
console.log('\nDone!');