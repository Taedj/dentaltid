const fs = require('fs');
const path = require('path');

const template = "const PRICING_DATA = {{ PRICING_DATA_JSON }};";
const key = "PRICING_DATA_JSON";
const value = '{"test": 1}';

const regex1 = new RegExp(`{{\\s*${key}\\s*}}`, 'g');
console.log("Regex 1:", regex1);
console.log("Result 1:", template.replace(regex1, () => value));

const regex2 = new RegExp(`\\{\\{\\s*${key}\\s*\\}\\}`, 'g');
console.log("Regex 2:", regex2);
console.log("Result 2:", template.replace(regex2, () => value));

const regex3 = new RegExp('\\\\{\\\\{\\\\s*' + key + '\\\\s*\\\\}\\\\}', 'g');
console.log("Regex 3:", regex3);
console.log("Result 3:", template.replace(regex3, () => value));
