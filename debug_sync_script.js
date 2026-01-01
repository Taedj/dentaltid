const fs = require('fs');
const path = require('path');

const APP_ROOT = process.cwd();
const websiteContent = fs.readFileSync('CONTROL_WEBSITE/WEBSITE.md', 'utf8');

function extractValue(content, key, sectionName) {
  const lines = content.split('\n');
  let inSection = !sectionName;
  for (const line of lines) {
    if (sectionName && line.startsWith('## ') && line.includes(sectionName)) inSection = true;
    else if (sectionName && line.startsWith('## ') && inSection) inSection = false;
    if (inSection && line.includes(key)) return line.split(key)[1].trim();
  }
  return '';
}

const customScreenshotsPath = extractValue(websiteContent, '**Screenshots Path:**', 'UI & Styling') || 'screenshots';
const screenshotsDir = path.isAbsolute(customScreenshotsPath) ? customScreenshotsPath : path.join(APP_ROOT, customScreenshotsPath);

console.log('screenshotsDir:', screenshotsDir);
console.log('Exists:', fs.existsSync(screenshotsDir));

if (fs.existsSync(screenshotsDir)) {
  const files = fs.readdirSync(screenshotsDir);
  console.log('Files:', files);
  const cardFile = files.find(f => f.startsWith('card'));
  console.log('cardFile:', cardFile);
}
