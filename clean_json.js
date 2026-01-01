const fs = require('fs');
const path = 'D:\\work\\Dev\\Websites\\My Website\\Frontend\\data\\projects.json';
if (fs.existsSync(path)) {
    const data = JSON.parse(fs.readFileSync(path, 'utf8'));
    const cleaned = data.map(p => {
        const { thumbnail, imageUrl, ...rest } = p;
        return rest;
    });
    fs.writeFileSync(path, JSON.stringify(cleaned, null, 2), 'utf8');
    console.log('Cleaned projects.json');
}
