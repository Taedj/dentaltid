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
const CONTROL_DIR = path.join(APP_ROOT, 'CONTROL_WEBSITE');
// No CSV support; using only txt files.

function main() {
  console.log('[SYNC] Starting sync for Taedj Dev Project...');

  if (!fs.existsSync(CONFIG_PATH)) {
    console.error('[ERROR] product.config.json not found.');
    process.exit(1);
  }

  const config = JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));
  const websiteContent = fs.existsSync(WEBSITE_MD_PATH) ? fs.readFileSync(WEBSITE_MD_PATH, 'utf8') : '';
  // Empty dashboard object; CSV disabled.
  const dashboard = {};

  config.slug = config.slug.toLowerCase();
  console.log(`[INFO] Syncing project: ${config.name} (${config.slug})`);

  // 1. Asset & Screenshots Configuration
  const customScreenshotsPath = readControlFile('3_DESIGN_STUDIO/SCREENSHOTS_PATH.txt', extractValue(websiteContent, '**Screenshots Path:**', 'UI & Styling') || 'screenshots');
  const screenshotsDir = path.isAbsolute(customScreenshotsPath) ? customScreenshotsPath : path.join(APP_ROOT, customScreenshotsPath);
  const targetAssetsDir = path.join(PUBLIC_ASSETS_PATH, config.slug);
  let cardImage = '';
  let heroImage = '';

  if (fs.existsSync(screenshotsDir)) {
    ensureDirectory(targetAssetsDir);
    const files = fs.readdirSync(screenshotsDir);

    // Copy all files
    files.forEach(file => {
      const src = path.join(screenshotsDir, file);
      if (fs.statSync(src).isFile()) {
        const dest = path.join(targetAssetsDir, file);
        if (!fs.existsSync(dest) || fs.statSync(src).mtime > fs.statSync(dest).mtime) {
          fs.copyFileSync(src, dest);
        }
      }
    });

    const cardFileFromMd = readControlFile('3_DESIGN_STUDIO/CARD_IMAGE.txt', extractValue(websiteContent, '**Card Image:**', 'UI & Styling'));
    const heroFileFromMd = readControlFile('3_DESIGN_STUDIO/HERO_IMAGE.txt', extractValue(websiteContent, '**Hero Image:**', 'UI & Styling'));

    const cardFile = cardFileFromMd || files.find(f => f.startsWith('card')) || files.find(f => f.startsWith('cover')) || files.find(f => /\.(png|jpg|jpeg|webp|gif)$/i.test(f));
    const heroFile = heroFileFromMd || files.find(f => f.startsWith('hero')) || files.find(f => f.startsWith('cover')) || files.find(f => /\.(png|jpg|jpeg|webp|gif)$/i.test(f));

    if (cardFile) cardImage = `/assets/projects/${config.slug}/${path.basename(cardFile)}`;
    if (heroFile) heroImage = `/assets/projects/${config.slug}/${path.basename(heroFile)}`;

    console.log(`[ASSET] Assets synced from: ${screenshotsDir}`);
  }

  // 2. Parse Content & Styles
  const chapters = parseChapters(websiteContent);
  const heroTitle = readControlFile('1_HERO_AND_HEADER/TITLE.txt', extractValue(websiteContent, '**Title:**', 'Hero Section'));
  const heroSubtitle = readControlFile('1_HERO_AND_HEADER/SUBTITLE.txt', extractValue(websiteContent, '**Subtitle:**', 'Hero Section'));
  const ctaPrimaryLabel = readControlFile('1_HERO_AND_HEADER/BTN_PRIMARY_TEXT.txt', extractValue(websiteContent, '**CTA Primary Label:**', 'Hero Section') || 'Download Now');
  const ctaPrimaryLink = readControlFile('1_HERO_AND_HEADER/BTN_PRIMARY_LINK.txt', extractValue(websiteContent, '**CTA Primary Link:**', 'Hero Section') || '#');
  const ctaSecondaryLabel = readControlFile('1_HERO_AND_HEADER/BTN_SECONDARY_TEXT.txt', extractValue(websiteContent, '**CTA Secondary Label:**', 'Hero Section') || 'Learn More');
  const ctaSecondaryLink = readControlFile('1_HERO_AND_HEADER/BTN_SECONDARY_LINK.txt', extractValue(websiteContent, '**CTA Secondary Link:**', 'Hero Section') || '#');
  const visionCaption = readControlFile('4_FINAL_CONVERSION/CAPTION.txt', extractValue(websiteContent, '**Caption:**', 'Demo & Vision'));
  const techStackRaw = readControlFile('4_FINAL_CONVERSION/TECH_STACK.txt', '');
  const techStack = techStackRaw ? techStackRaw.split(' ') : extractList(websiteContent, 'Tech Stack');
  const finalCTATitle = readControlFile('4_FINAL_CONVERSION/TITLE.txt', extractValue(websiteContent, '**Title:**', 'Final CTA'));
  const finalCTASubtitle = readControlFile('4_FINAL_CONVERSION/SUBTITLE.txt', extractValue(websiteContent, '**Subtitle:**', 'Final CTA'));
  const finalCTAButtonLabel = readControlFile('4_FINAL_CONVERSION/BUTTON_TEXT.txt', extractValue(websiteContent, '**Button Label:**', 'Final CTA') || 'Get Started');
  const finalCTAButtonLink = readControlFile('4_FINAL_CONVERSION/BUTTON_LINK.txt', extractValue(websiteContent, '**Button Link:**', 'Final CTA') || '#');

  // Mega UI Friendly Style Logic
  const styles = {
    heroTitleSize: parseInt(readControlFile('3_DESIGN_STUDIO/HERO_FONT_SIZE_PX.txt', extractValue(websiteContent, '**Hero Title Size:**', 'UI & Styling'))) || 120,
    buttonPaddingX: parseInt(readControlFile('3_DESIGN_STUDIO/BUTTON_PADDING_X_PX.txt', extractValue(websiteContent, '**Button Padding X:**', 'UI & Styling'))) || 64,
    buttonPaddingY: parseInt(readControlFile('3_DESIGN_STUDIO/BUTTON_PADDING_Y_PX.txt', extractValue(websiteContent, '**Button Padding Y:**', 'UI & Styling'))) || 32,
    buttonTextSize: parseInt(readControlFile('3_DESIGN_STUDIO/BUTTON_TEXT_SIZE_PX.txt', extractValue(websiteContent, '**Button Text Size:**', 'UI & Styling'))) || 32,
    sectionSpacing: parseInt(readControlFile('3_DESIGN_STUDIO/SECTION_SPACING_PX.txt', extractValue(websiteContent, '**Section Spacing:**', 'UI & Styling'))) || 160,
    borderRadius: parseInt(readControlFile('3_DESIGN_STUDIO/CORNER_ROUNDNESS_PX.txt', extractValue(websiteContent, '**Border Radius:**', 'UI & Styling'))) || 32,
    heroImgScale: parseInt(readControlFile('3_DESIGN_STUDIO/HERO_IMG_SCALE.txt', extractValue(websiteContent, '**Hero Img Scale:**', 'UI & Styling'))) || 100,
    heroImgOffsetY: parseInt(readControlFile('3_DESIGN_STUDIO/HERO_IMG_OFFSET_Y.txt', extractValue(websiteContent, '**Hero Img Offset Y:**', 'UI & Styling'))) || 0,
    heroImgWidth: parseInt(readControlFile('3_DESIGN_STUDIO/HERO_IMG_WIDTH.txt', extractValue(websiteContent, '**Hero Img Width:**', 'UI & Styling'))) || 100,
    brandLogo: readControlFile('3_DESIGN_STUDIO/BRAND_LOGO.txt', extractValue(websiteContent, '**Brand Logo:**', 'UI & Styling')),
    heroBackground: readControlFile('3_DESIGN_STUDIO/HERO_BACKGROUND.txt', extractValue(websiteContent, '**Hero Background:**', 'UI & Styling')),
  };

  // 3. Update projects.json
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
    image: cardImage || heroImage,
  };

  const existingIndex = projectsData.findIndex(p => p.slug === config.slug);
  if (existingIndex >= 0) {
    projectsData[existingIndex] = { ...projectsData[existingIndex], ...projectEntry };
  } else {
    projectsData.push(projectEntry);
  }

  fs.writeFileSync(PROJECTS_JSON_PATH, JSON.stringify(projectsData, null, 2));

  // 4. Generate Page
  const pageDir = path.join(APP_PAGES_PATH, config.slug);
  ensureDirectory(pageDir);

  const pageContent = generatePageContent(config, {
    heroTitle, heroSubtitle,
    ctaPrimaryLabel, ctaPrimaryLink,
    ctaSecondaryLabel, ctaSecondaryLink,
    chapters, heroImage, visionCaption, techStack,
    finalCTATitle, finalCTASubtitle,
    finalCTAButtonLabel, finalCTAButtonLink,
    styles
  });
  fs.writeFileSync(path.join(pageDir, 'page.tsx'), pageContent);

  // 5. Git Automation
  try {
    process.chdir(WEBSITE_ROOT);
    execSync('git add .');
    execSync(`git commit -m "feat: sync project ${config.slug} via txt control files"`);
    execSync('git push');
  } catch (e) { }

  console.log('\n[SUCCESS] SYNC COMPLETED SUCCESSFULLY');
}

function readControlFile(relPath, fallback) {
  const fullPath = path.join(CONTROL_DIR, relPath);
  if (fs.existsSync(fullPath)) {
    try {
      return fs.readFileSync(fullPath, 'utf8').trim();
    } catch (e) {
      return fallback;
    }
  }
  return fallback;
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
  let collecting = false;
  let collected = [];

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const trimmed = line.trim();

    if (trimmed.startsWith('## ')) {
      currentSection = trimmed.replace('## ', '').trim();
      if (collecting) break; // Stop at next section
    }

    if (sectionName && !currentSection.includes(sectionName)) continue;

    if (line.includes(key)) {
      collecting = true;
      let firstLineValue = line.split(key)[1].trim();
      if (firstLineValue) collected.push(firstLineValue);
      continue;
    }

    if (collecting) {
      // Stop if we hit another key or a header
      if (trimmed.startsWith('**') || trimmed.startsWith('#')) break;
      if (trimmed) collected.push(trimmed);
    }
  }
  return collected.join(' ').trim();
}

function extractList(content, sectionName) {
  const lines = content.split('\n');
  let inSection = false;
  const items = [];
  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed.startsWith('## ') && trimmed.toLowerCase().includes(sectionName.toLowerCase())) {
      inSection = true;
      continue;
    }
    if (inSection && trimmed.startsWith('## ') && !trimmed.toLowerCase().includes(sectionName.toLowerCase())) {
      inSection = false;
    }
    if (inSection && (trimmed.startsWith('- ') || trimmed.startsWith('* '))) {
      items.push(trimmed.substring(2).trim());
    }
  }
  return items;
}

function parseChapters(content) {
  // Try folders first
  const chapterFoldersDir = path.join(CONTROL_DIR, '2_NARRATIVE_CHAPTERS');
  if (fs.existsSync(chapterFoldersDir)) {
    const folders = fs.readdirSync(chapterFoldersDir).filter(f => fs.statSync(path.join(chapterFoldersDir, f)).isDirectory());
    if (folders.length > 0) {
      return folders.map((f, i) => {
        const rel = path.join('2_NARRATIVE_CHAPTERS', f);
        return {
          title: readControlFile(path.join(rel, 'TITLE.txt'), `Feature ${i + 1}`),
          description: readControlFile(path.join(rel, 'DESCRIPTION.txt'), ''),
          image: readControlFile(path.join(rel, 'IMAGE_NAME.txt'), `feature${i + 1}.png`),
          styles: {
            imgWidth: parseInt(readControlFile(path.join(rel, 'IMG_WIDTH.txt'), '100')) || 100,
            imgOffsetY: parseInt(readControlFile(path.join(rel, 'IMG_OFFSET.txt'), '0')) || 0,
            imgScale: parseInt(readControlFile(path.join(rel, 'IMG_ZOOM.txt'), '100')) || 100,
          }
        };
      });
    }
  }
  // Fallback to Markdown parsing (same as before)
  const mdChapters = [];
  const sections = content.split('### Chapter ');
  sections.shift();
  sections.forEach(s => {
    const lines = s.split('\n');
    const titleLine = lines[0].split(': ')[1] || lines[0];
    const descLine = s.split('**Description:**')[1]?.split('\n')[0]?.trim() || '';
    const visualLine = s.split('**Visual Hint:**')[1]?.split('\n')[0]?.trim() || '';
    const imgWidth = parseInt(s.split('**Img Width:**')[1]?.split('\n')[0]?.trim()) || 100;
    const imgOffsetY = parseInt(s.split('**Img Offset Y:**')[1]?.split('\n')[0]?.trim()) || 0;
    const imgScale = parseInt(s.split('**Img Scale:**')[1]?.split('\n')[0]?.trim()) || 100;
    mdChapters.push({
      title: titleLine.trim(),
      description: descLine,
      image: visualLine ? visualLine : null,
      styles: { imgWidth, imgOffsetY, imgScale }
    });
  });
  return mdChapters;
}

function generatePageContent(config, data) {
  const { heroTitle, heroSubtitle, ctaPrimaryLabel, ctaPrimaryLink, ctaSecondaryLabel, ctaSecondaryLink, chapters, heroImage, brandLogo, heroBackground, visionCaption, techStack, finalCTATitle, finalCTASubtitle, finalCTAButtonLabel, finalCTAButtonLink, styles } = data;
  const words = heroTitle.split(' ');
  const lastWord = words.pop();
  const heroTitleFormatted = `${words.join(' ')} <span className="bg-gradient-to-r from-emerald-400 to-cyan-400 bg-clip-text text-transparent">${lastWord}</span>`;
  const chaptersHtml = chapters.map((c, i) => `
        <section key={${i}} style={{ paddingTop: '${styles.sectionSpacing}px', paddingBottom: '${styles.sectionSpacing}px' }} className="space-y-20">
          <div className="max-w-6xl mx-auto text-center space-y-10">
            <h2 className="text-6xl md:text-8xl font-black text-white tracking-tighter leading-tight">${c.title}</h2>
            <p className="text-2xl md:text-3xl text-neutral-400 leading-relaxed max-w-4xl mx-auto">${c.description}</p>
          </div>
          <div className="relative group/chapter w-full px-4 md:px-0">
            <div style={{ borderRadius: '${styles.borderRadius}px' }} className="aspect-video bg-[#0A0C10] border border-white/5 overflow-hidden shadow-[0_0_150px_rgba(0,0,0,0.8)] relative w-full">
               <div className="absolute top-0 left-0 right-0 h-14 bg-[#14171C] border-b border-white/5 flex items-center px-8 gap-3 z-20">
                 <div className="w-4 h-4 rounded-full bg-white/5" />
                 <div className="w-4 h-4 rounded-full bg-white/5" />
                 <div className="w-4 h-4 rounded-full bg-white/5" />
               </div>
               <div className="w-full h-full flex items-center justify-center overflow-hidden pt-14">
                 ${c.image ? `<img
                     src={\`/assets/projects/${config.slug}/${c.image}\`}
                     alt="${c.title}"
                     style={{
                       maxWidth: '${c.styles.imgWidth}%',
                       transform: 'translateY(${c.styles.imgOffsetY}px) scale(${c.styles.imgScale / 100})',
                       transition: 'all 1s cubic-bezier(0.4, 0, 0.2, 1)'
                     }}
                     className="object-contain h-full transition-all duration-1000 group-hover/chapter:scale-[1.05]"
                   />` : `<div className="w-full h-full flex items-center justify-center text-neutral-800 italic text-3xl font-light">Visual Coming Soon</div>`}
               </div>
            </div>
          </div>
        </section>`).join('');
  return `
import React from 'react';
import { Metadata } from 'next';
import Link from 'next/link';
import { FaArrowLeft, FaDownload, FaRocket } from 'react-icons/fa';

export const metadata: Metadata = { title: '${config.name} | ${config.brand}', description: '${heroSubtitle.replace(/'/g, "\\'")}' };

export default function ProjectPage() {
  return (
    <div className="min-h-screen bg-[#080A0E] text-white selection:bg-emerald-500/30 overflow-x-hidden relative">
      ${heroBackground ? `<div className="fixed inset-0 z-0 opacity-20"><img src="/assets/projects/${config.slug}/${heroBackground}" className="w-full h-full object-cover" /></div>` : ''}
      <div className="fixed top-0 left-0 right-0 h-24 bg-[#080A0E]/90 backdrop-blur-2xl z-40 border-b border-white/5 flex items-center px-10">
        ${brandLogo ? `<img src="/assets/projects/${config.slug}/${brandLogo}" className="h-12 w-auto object-contain" />` : `<div className="text-4xl font-black tracking-tighter text-white/90 underline decoration-emerald-500 decoration-4 underline-offset-8">${config.brand}</div>`}
      </div>
      <main className="relative z-10 w-full">
        <div className="max-w-[95%] mx-auto pt-40 pb-12">
          <Link href="/#Taedj-Dev-Projects" className="group inline-flex items-center gap-4 text-neutral-500 hover:text-white transition-all text-xl font-medium">
            <div className="w-12 h-12 rounded-full border border-white/10 flex items-center justify-center group-hover:bg-white group-hover:text-black transition-all">
              <FaArrowLeft className="group-hover:-translate-x-1 transition-transform" />
            </div>
            <span>Back to Projects Hub</span>
          </Link>
        </div>
        <section className="pt-20 pb-20 text-center w-full px-6">
          <div className="max-w-[95%] mx-auto space-y-12">
            <h1 style={{ filter: 'drop-shadow(0 20px 50px rgba(0,0,0,0.5))', fontSize: '${styles.heroTitleSize}px' }} className="font-black tracking-tighter leading-[0.85] text-white" dangerouslySetInnerHTML={{ __html: \`${heroTitleFormatted}\` }} />
            <p className="text-3xl md:text-4xl text-neutral-400 max-w-5xl mx-auto leading-tight font-medium">${heroSubtitle}</p>
            <div className="flex flex-wrap gap-8 pt-10 justify-center">
              <Link href="${ctaPrimaryLink}" style={{ padding: '${styles.buttonPaddingY}px ${styles.buttonPaddingX}px', fontSize: '${styles.buttonTextSize}px', borderRadius: '${styles.borderRadius}px' }} className="bg-emerald-500 hover:bg-emerald-400 text-[#080A0E] font-black rounded-[2rem] transition-all flex items-center gap-4 shadow-[0_20px_60px_rgba(16,185,129,0.3)] hover:scale-105 active:scale-95">
                <FaDownload /> ${ctaPrimaryLabel}
              </Link>
              <Link href="${ctaSecondaryLink}" style={{ padding: '${styles.buttonPaddingY}px ${styles.buttonPaddingX}px', fontSize: '${styles.buttonTextSize}px', borderRadius: '${styles.borderRadius}px' }} className="bg-white/5 border border-white/10 hover:bg-white/10 text-white font-black rounded-[2rem] transition-all flex items-center gap-4 hover:scale-105 active:scale-95">${ctaSecondaryLabel}</Link>
            </div>
          </div>
        </section>
        <section className="pb-40 w-full px-4 md:px-10">
          <div style={{ borderRadius: '${styles.borderRadius}px' }} className="relative aspect-video overflow-hidden border border-white/5 shadow-[0_0_150px_rgba(16,185,129,0.1)] bg-[#0A0C10] group/hero w-full mx-auto flex items-center justify-center">
            <div className="absolute top-0 left-0 right-0 h-16 bg-[#14171C] border-b border-white/5 flex items-center px-10 gap-3 z-20">
              <div className="w-5 h-5 rounded-full bg-red-500/40" />
              <div className="w-5 h-5 rounded-full bg-yellow-500/40" />
              <div className="w-5 h-5 rounded-full bg-green-500/40" />
              <div className="ml-10 h-9 px-8 bg-white/5 rounded-xl border border-white/5 flex-grow max-w-2xl hidden lg:flex text-sm text-neutral-500 items-center font-mono tracking-widest text-left">${config.name.toLowerCase()}.app/dashboard</div>
            </div>
            ${heroImage ? `<img
               src="${heroImage}"
               alt="${config.slug} Hero"
               style={{
                 maxWidth: '${styles.heroImgWidth}%',
                 transform: 'translateY(${styles.heroImgOffsetY}px) scale(${styles.heroImgScale / 100})',
                 transition: 'all 1s cubic-bezier(0.4, 0, 0.2, 1)'
               }}
               className="w-full h-full object-contain pt-16 transition-all duration-1000 group-hover/hero:scale-[1.01]" />` : `<div className="w-full h-full flex items-center justify-center text-neutral-800 italic text-4xl font-light">Hero Visual Coming Soon</div>`}
          </div>
        </section>
        <div className="py-40 max-w-[95%] mx-auto text-left">
          <div className="h-px w-full bg-gradient-to-r from-transparent via-white/10 to-transparent mb-40" />
          ${chaptersHtml}
        </div>
        ${visionCaption ? `<section className="py-60 text-center w-full px-6 bg-gradient-to-b from-transparent via-emerald-500/5 to-transparent"><div className="max-w-6xl mx-auto"><div className="w-24 h-1.5 bg-emerald-500 mx-auto mb-16 rounded-full shadow-[0_0_20px_rgba(16,185,129,0.5)]" /><blockquote className="text-5xl md:text-7xl font-bold text-white italic leading-[1.1] tracking-tight">"${visionCaption}"</blockquote></div></section>` : ''}
        <section className="py-60 text-center px-6">
          <div className="bg-gradient-to-br from-emerald-600/20 via-[#0A0C10] to-cyan-600/20 p-24 md:p-40 border border-white/5 shadow-2xl relative overflow-hidden group" style={{ borderRadius: '${styles.borderRadius * 2}px' }}>
            <div className="absolute inset-0 bg-emerald-500/5 opacity-0 group-hover:opacity-100 transition-opacity duration-1000" />
            <h2 className="text-6xl md:text-[10rem] font-black mb-12 tracking-tighter leading-none">${finalCTATitle}</h2>
            <p className="text-3xl md:text-4xl text-neutral-400 mb-20 max-w-4xl mx-auto leading-tight font-medium">${finalCTASubtitle}</p>
            <Link href="${finalCTAButtonLink}" style={{ padding: '${styles.buttonPaddingY}px ${styles.buttonPaddingX}px', fontSize: '${styles.buttonTextSize}px', borderRadius: '${styles.borderRadius}px' }} className="bg-white text-black font-black text-4xl rounded-[2.5rem] hover:scale-105 active:scale-95 transition-all inline-flex items-center gap-6 shadow-[0_30px_100px_rgba(255,255,255,0.15)]">
              <FaRocket size={40} /> ${finalCTAButtonLabel}
            </Link>
          </div>
        </section>
      </main>
      <footer className="py-32 border-t border-white/5 text-center">
        <div className="mb-10 text-3xl font-black tracking-tighter text-white/20">TAEDJ ECOSYSTEM</div>
        <p className="text-xl text-neutral-600 font-medium">© ${new Date().getFullYear()} ${config.brand}. Finality through Precision.</p>
      </footer>
    </div>
  );
}
`;
}

main();
