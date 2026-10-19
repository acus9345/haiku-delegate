const fs = require('fs');
fs.mkdirSync('dist', { recursive: true });
fs.copyFileSync('src/index.js', 'dist/index.js');
