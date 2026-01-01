const fs = require('fs');
const path = 'D:\\work\\Dev\\Websites\\My Website\\Frontend\\components\\Projects\\Projects.tsx';
if (fs.existsSync(path)) {
    let content = fs.readFileSync(path, 'utf8');

    const target = /{project\.image \? \(.*?\)/s;
    const replacement = `{project.image ? (
                                    project.image.match(/\\.(mp4|webm)$/i) ? (
                                        <video
                                            src={project.image}
                                            autoPlay
                                            muted
                                            loop
                                            playsInline
                                            className="object-cover w-full h-full opacity-80 group-hover:opacity-100 group-hover:scale-105 transition-all duration-700"
                                        />
                                    ) : (
                                        <Image
                                            src={project.image}
                                            alt={project.name}
                                            fill
                                            className="object-cover opacity-80 group-hover:opacity-100 group-hover:scale-105 transition-all duration-700"
                                            unoptimized={project.image.endsWith(".gif")}
                                        />
                                    )
                                ) : (`;

    // Using simple string replacement if regex is tricky
    const oldCode = `{project.image ? (
                                        <Image
                                            src={project.image}
                                            alt={project.name}
                                            fill
                                            className="object-cover opacity-80 group-hover:opacity-100 group-hover:scale-105 transition-all duration-700"
                                        />
                                    ) : (`;

    if (content.includes(oldCode)) {
        content = content.replace(oldCode, replacement);
        fs.writeFileSync(path, content, 'utf8');
        console.log('Updated Projects.tsx with video and gif support');
    } else {
        console.error('Target code block not found in Projects.tsx');
        // Let's try a more flexible regex
        const flexRegex = /\{project\.image \? \(\s*<Image.*?src=\{project\.image\}.*?\/>\s*\) : \(/s;
        if (flexRegex.test(content)) {
            content = content.replace(flexRegex, replacement);
            fs.writeFileSync(path, content, 'utf8');
            console.log('Updated Projects.tsx with video and gif support (regex fallback)');
        } else {
            console.error('Could not find Image block even with regex');
        }
    }
}
