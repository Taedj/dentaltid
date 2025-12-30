const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Configuration
const APP_ROOT = process.cwd();
const WEBSITE_ROOT = 'D:\\work\\Dev\\Websites\\My Website\\Frontend';

const CONFIG_PATH = path.join(APP_ROOT, 'product.config.json');
const WEBSITE_MD_PATH = path.join(APP_ROOT, 'WEBSITE.md');
const PROJECTS_JSON_PATH = path.join(WEBSITE_ROOT, 'data', 'projects.json');
const PUBLIC_ASSETS_PATH = path.join(WEBSITE_ROOT, 'public', 'assets', 'projects');
const APP_PAGES_PATH = path.join(WEBSITE_ROOT, 'app', 'projects');

function main() {
  console.log('🚀 Starting sync for Taedj Dev Project...');

  if (!fs.existsSync(CONFIG_PATH)) {
    console.error('❌ Error: product.config.json not found.');
    process.exit(1);
  }

  const config = JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));
  const websiteContent = fs.existsSync(WEBSITE_MD_PATH) ? fs.readFileSync(WEBSITE_MD_PATH, 'utf8') : '';

  console.log(`📦 Syncing project: ${config.name} (${config.slug})`);

  // 1. Copy Assets & Determine Cover Image
  const screenshotsDir = path.join(APP_ROOT, 'screenshots');
  const targetAssetsDir = path.join(PUBLIC_ASSETS_PATH, config.slug);
  let coverImage = '';

  if (fs.existsSync(screenshotsDir)) {
    ensureDirectory(targetAssetsDir);
    const files = fs.readdirSync(screenshotsDir);

    // Find cover specifically or fallback to first image (supports png, jpg, gif, etc.)
    const coverFile = files.find(f => f.startsWith('cover')) || files.find(f => /\.(png|jpg|jpeg|webp|gif)$/i.test(f));
    if (coverFile) {
      coverImage = `/assets/projects/${config.slug}/${coverFile}`;
    }

    files.forEach(file => {
      if (file === '.keep') return;
      const src = path.join(screenshotsDir, file);
      const dest = path.join(targetAssetsDir, file);
      if (fs.statSync(src).isFile()) {
        fs.copyFileSync(src, dest);
      }
    });
    console.log(`📸 Assets copied to Hub: ${targetAssetsDir}`);
  }

  // 2. Parse Content
  const chapters = parseChapters(websiteContent);
  const heroTitle = extractValue(websiteContent, '**Title:**', 'Hero Section');
  const heroSubtitle = extractValue(websiteContent, '**Subtitle:**', 'Hero Section');
  const ctaPrimary = extractValue(websiteContent, '**CTA Primary:**', 'Hero Section') || 'Download Now';
  const ctaSecondary = extractValue(websiteContent, '**CTA Secondary:**', 'Hero Section') || 'Learn More';
  const visionCaption = extractValue(websiteContent, '**Caption:**', 'Demo & Vision');
  const techStack = extractList(websiteContent, 'Tech Stack');
  const finalCTATitle = extractValue(websiteContent, '**Title:**', 'Final CTA');
  const finalCTASubtitle = extractValue(websiteContent, '**Subtitle:**', 'Final CTA');

  // 3. Update projects.json (Central Registry)
  ensureDirectoryExistence(PROJECTS_JSON_PATH);
  let projectsData = [];
  if (fs.existsSync(PROJECTS_JSON_PATH)) {
    projectsData = JSON.parse(fs.readFileSync(PROJECTS_JSON_PATH, 'utf8'));
  }

  const projectEntry = {
    name: config.name,
    slug: config.slug,
    category: config.category,
    brand: config.brand,
    status: config.status,
    lastUpdated: new Date().toISOString(),
    description: heroSubtitle || 'No description available',
    image: coverImage,
  };

  const existingIndex = projectsData.findIndex(p => p.slug === config.slug);
  if (existingIndex >= 0) {
    projectsData[existingIndex] = { ...projectsData[existingIndex], ...projectEntry };
  } else {
    projectsData.push(projectEntry);
  }

  fs.writeFileSync(PROJECTS_JSON_PATH, JSON.stringify(projectsData, null, 2));
  console.log('✅ Updated data/projects.json');

  // 4. Generate Scroll-Telling Page
  const pageDir = path.join(APP_PAGES_PATH, config.slug);
  ensureDirectory(pageDir);

  const pageContent = generatePageContent(config, {
    heroTitle,
    heroSubtitle,
    ctaPrimary,
    ctaSecondary,
    chapters,
    coverImage,
    visionCaption,
    techStack,
    finalCTATitle,
    finalCTASubtitle
  });
  fs.writeFileSync(path.join(pageDir, 'page.tsx'), pageContent);
  console.log('📜 Generated high-fidelity landing page (page.tsx)');

  // 5. Git Automation (Optional but part of protocol)
  try {
    console.log('🔗 Automating Git commit in Website Hub...');
    process.chdir(WEBSITE_ROOT);
    execSync('git add .');
    execSync(`git commit -m "feat: sync project ${config.slug}"`);
    console.log('🚀 Git commit successful in Hub.');
  } catch (e) {
    console.log('⚠️ Git automation skipped or failed (likely no changes or git not init).');
  }

  console.log('\n✨ SYNC COMPLETED SUCCESSFULLY ✨');
}

function ensureDirectoryExistence(filePath) {
  const dirname = path.dirname(filePath);
  if (fs.existsSync(dirname)) return true;
  ensureDirectoryExistence(dirname);
  fs.mkdirSync(dirname);
}

function ensureDirectory(dirPath) {
  if (!fs.existsSync(dirPath)) fs.mkdirSync(dirPath, { recursive: true });
}

function extractValue(content, key, sectionName = null) {
  const lines = content.split('\n');
  let currentSection = '';

  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed.startsWith('## ')) {
      currentSection = trimmed.replace('## ', '').trim();
    }

    if (sectionName && currentSection !== sectionName) continue;

    if (line.includes(key)) {
      return line.split(key)[1].trim();
    }
  }
  return '';
}

function extractList(content, sectionName) {
  const lines = content.split('\n');
  let inSection = false;
  const items = [];

  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed.startsWith('## ') && trimmed.includes(sectionName)) {
      inSection = true;
      continue;
    }
    if (inSection && trimmed.startsWith('## ') && !trimmed.includes(sectionName)) { // Exit section if new section starts
      inSection = false;
    }

    if (inSection && trimmed.startsWith('- ')) {
      items.push(trimmed.replace('- ', '').trim());
    }
  }
  return items;
}

function parseChapters(content) {
  const chapters = [];
  const sections = content.split('### Chapter ');
  sections.shift(); // Remove intro

  sections.forEach(s => {
    const lines = s.split('\n');
    const titleLine = lines[0].split(': ')[1] || lines[0];
    const descLine = s.split('**Description:**')[1]?.split('\n')[0]?.trim() || '';
    const visualLine = s.split('**Visual Hint:**')[1]?.split('\n')[0]?.trim() || '';

    chapters.push({
      title: titleLine.trim(),
      description: descLine,
      image: visualLine ? visualLine : null
    });
  });
  return chapters;
}

function generatePageContent(config, data) {
  const { heroTitle, heroSubtitle, ctaPrimary, ctaSecondary, chapters, coverImage, visionCaption, techStack, finalCTATitle, finalCTASubtitle } = data;

  const words = heroTitle.split(' ');
  const lastWord = words.pop();
  const heroTitleFormatted = `${words.join(' ')} <span className="bg-gradient-to-r from-emerald-400 to-cyan-400 bg-clip-text text-transparent">${lastWord}</span>`;

  const chaptersHtml = chapters.map((c, i) => `
        <section key={${i}} className="min-h-screen flex flex-col md:flex-row items-center justify-between py-24 gap-12">
          <div className="w-full md:w-1/2 space-y-6">
            <span className="text-emerald-500 font-mono text-sm tracking-widest uppercase">Chapter 0${i + 1}</span>
            <h2 className="text-4xl font-bold text-white">${c.title}</h2>
            <p className="text-xl text-neutral-400 leading-relaxed">${c.description}</p>
          </div>
          <div className="w-full md:w-1/2">
            <div className="aspect-video bg-neutral-800 rounded-2xl border border-neutral-700 overflow-hidden shadow-2xl relative">
              ${c.image ? `
                <img 
                  src={\`/assets/projects/${config.slug}/${c.image}\`} 
                  alt="${c.title}" 
                  className="w-full h-full object-cover"
                />
              ` : `
                <div className="w-full h-full flex items-center justify-center text-neutral-600 italic">
                  Visual for ${c.title} coming soon
                </div>
              `}
            </div>
          </div>
        </section>
    `).join('');

  const techStackHtml = techStack.map(item => `
        <div key="${item}" className="bg-white/5 border border-white/10 p-6 rounded-2xl hover:bg-white/10 transition-colors">
          <p className="text-neutral-300 font-medium">${item}</p>
        </div>
    `).join('');

  return `
import React from 'react';
import { Metadata } from 'next';
import Link from 'next/link';
import { FaArrowLeft, FaDownload, FaExternalLinkAlt } from 'react-icons/fa';

export const metadata: Metadata = {
  title: '${config.name} | ${config.brand}',
  description: '${heroSubtitle}',
};

export default function ProjectPage() {
  return (
    <div className="min-h-screen bg-[#0E1116] text-white selection:bg-emerald-500/30">
      {/* Navigation Backdrop */}
      <div className="fixed top-0 left-0 right-0 h-20 bg-[#0E1116]/80 backdrop-blur-md z-40 border-b border-white/5" />
      
      <main className="relative z-10 px-4 sm:px-8 max-w-7xl mx-auto">
        {/* Back Link */}
        <div className="pt-32 pb-12">
          <Link href="/#Taedj-Dev-Projects" className="group flex items-center gap-2 text-neutral-500 hover:text-white transition-colors">
            <FaArrowLeft className="group-hover:-translate-x-1 transition-transform" />
            <span>Back to Projects</span>
          </Link>
        </div>

        {/* Hero Section */}
        <section className="py-20 text-center md:text-left flex flex-col md:flex-row items-center gap-16">
          <div className="flex-1 space-y-8">
            <div className="inline-block px-4 py-1.5 bg-emerald-500/10 border border-emerald-500/20 rounded-full text-emerald-400 text-sm font-medium">
              ${config.status}
            </div>
            <h1 className="text-6xl md:text-8xl font-black tracking-tighter leading-none" dangerouslySetInnerHTML={{ __html: \`${heroTitleFormatted}\` }} />
            <p className="text-xl md:text-2xl text-neutral-400 max-w-2xl leading-relaxed">
              ${heroSubtitle}
            </p>
            <div className="flex flex-wrap gap-4 pt-4 justify-center md:justify-start">
              <button className="px-8 py-4 bg-emerald-500 hover:bg-emerald-400 text-[#0E1116] font-bold rounded-xl transition-all flex items-center gap-2 shadow-lg shadow-emerald-500/20">
                <FaDownload /> ${ctaPrimary}
              </button>
              <button className="px-8 py-4 bg-white/5 border border-white/10 hover:bg-white/10 text-white font-bold rounded-xl transition-all flex items-center gap-2">
                ${ctaSecondary}
              </button>
            </div>
          </div>
          
          <div className="flex-1 w-full max-w-2xl">
            <div className="relative aspect-square rounded-[3rem] overflow-hidden border border-white/10 shadow-3xl bg-neutral-800">
               ${coverImage ? `
                 <img src="${coverImage}" alt="${config.name} Hero" className="w-full h-full object-cover" />
               ` : `
                 <div className="w-full h-full flex items-center justify-center text-neutral-700 italic">Hero Visual Coming Soon</div>
               `}
            </div>
          </div>
        </section>

        {/* Story Chapters */}
        <div className="py-32">
          <div className="h-px w-full bg-gradient-to-r from-transparent via-white/10 to-transparent mb-32" />
          ${chaptersHtml}
        </div>

        {/* Vision Section */}
        ${visionCaption ? `
          <section className="py-32 text-center">
            <div className="max-w-3xl mx-auto px-4">
              <div className="w-12 h-1 bg-emerald-500 mx-auto mb-8 rounded-full" />
              <blockquote className="text-3xl md:text-4xl font-medium text-neutral-200 italic leading-snug">
                "${visionCaption}"
              </blockquote>
            </div>
          </section>
        ` : ''}

        {/* Tech Stack Section */}
        ${techStack.length > 0 ? `
          <section className="py-32">
            <h2 className="text-3xl font-bold mb-12 text-center">The Tech Behind the Magic</h2>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
              ${techStackHtml}
            </div>
          </section>
        ` : ''}

        {/* Final CTA */}
        <section className="py-40 text-center">
          <div className="bg-gradient-to-br from-emerald-500/20 to-cyan-500/20 p-20 rounded-[4rem] border border-emerald-500/20">
             <h2 className="text-5xl font-bold mb-6">${finalCTATitle}</h2>
             <p className="text-xl text-neutral-400 mb-10 max-w-xl mx-auto">
               ${finalCTASubtitle}
             </p>
             <button className="px-12 py-5 bg-white text-black font-black text-xl rounded-2xl hover:scale-105 transition-transform">
               Get Started for Free
             </button>
          </div>
        </section>
      </main>

      {/* Footer Branding */}
      <footer className="py-20 border-t border-white/5 text-center text-neutral-600">
         <p>© ${new Date().getFullYear()} ${config.brand}. Powered by the Taedj Ecosystem.</p>
      </footer>
    </div>
  );
}
    `;
}

main();
