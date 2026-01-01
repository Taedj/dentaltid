const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Configuration
const APP_ROOT = process.cwd();
const WEBSITE_ROOT = 'D:\\work\\Dev\\Websites\\My Website\\Frontend';

const CONFIG_PATH = path.join(APP_ROOT, 'CONTROL_WEBSITE', 'product.config.json');
const WEBSITE_MD_PATH = path.join(APP_ROOT, 'CONTROL_WEBSITE', 'WEBSITE.md');
const PROJECTS_JSON_PATH = path.join(WEBSITE_ROOT, 'data', 'projects.json');
const PUBLIC_ASSETS_PATH = path.join(WEBSITE_ROOT, 'public', 'assets', 'projects');
const APP_PAGES_PATH = path.join(WEBSITE_ROOT, 'app', 'projects');
const CONTROL_DIR = path.join(APP_ROOT, 'CONTROL_WEBSITE');
const REGISTRATION_TEMPLATE_PATH = path.join(CONTROL_DIR, 'RegistrationUI.tsx');
const DASHBOARD_TEMPLATE_PATH = path.join(CONTROL_DIR, 'DashboardUI.tsx');
const FIREBASE_CONFIG_PATH = path.join(WEBSITE_ROOT, 'lib', 'firebase.ts');
// Gist URL for Pricing (Latest Raw)
const GIST_URL = 'https://gist.githubusercontent.com/Taedj/9bf1dae53f37681b9c13dab8cde8472f/raw/config.json';

function main() {
  console.log('[SYNC] Starting sync for Taedj Dev Project...');

  if (!fs.existsSync(CONFIG_PATH)) {
    console.error('[ERROR] product.config.json not found.');
    process.exit(1);
  }

  const config = JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));
  const websiteContent = fs.existsSync(WEBSITE_MD_PATH) ? fs.readFileSync(WEBSITE_MD_PATH, 'utf8') : '';

  // Fetch Remote Config (Pricing)
  let remoteConfig = {};
  console.log('[INFO] Fetching pricing from Gist...');
  try {
    const curlOutput = execSync(`curl.exe -s "${GIST_URL}"`, { encoding: 'utf8' }).toString();
    remoteConfig = JSON.parse(curlOutput);
    console.log('[INFO] Pricing fetched successfully.');
  } catch (e) {
    console.warn('[WARN] Failed to fetch pricing from Gist. Using local fallback.');
    remoteConfig = {
      pricing: {
        'DZD': { 'symbol': 'DZD', 'position': 'suffix', 'plans': { 'premium': { 'monthly': '2,000', 'yearly': '20,000', 'lifetime': '60,000' }, 'crown': { 'monthly': '4,000', 'yearly': '40,000', 'lifetime': '100,000' } } },
        'USD': { 'symbol': '$', 'position': 'prefix', 'plans': { 'premium': { 'monthly': '15', 'yearly': '150', 'lifetime': '450' }, 'crown': { 'monthly': '30', 'yearly': '300', 'lifetime': '900' } } },
        'EUR': { 'symbol': '€', 'position': 'suffix', 'plans': { 'premium': { 'monthly': '14', 'yearly': '140', 'lifetime': '420' }, 'crown': { 'monthly': '28', 'yearly': '280', 'lifetime': '840' } } }
      }
    };
  }

  config.slug = config.slug.toLowerCase();
  console.log(`[INFO] Syncing project: ${config.name} (${config.slug})`);

  // 1. Asset & Screenshots Configuration
  const customScreenshotsPath = readControlFile('3_DESIGN_STUDIO/SCREENSHOTS_PATH.txt', extractValue(websiteContent, '**Screenshots Path:**', 'UI & Styling') || 'screenshots');
  const screenshotsDir = path.isAbsolute(customScreenshotsPath) ? customScreenshotsPath : path.join(APP_ROOT, customScreenshotsPath);
  const targetAssetsDir = path.join(PUBLIC_ASSETS_PATH, config.slug);
  let cardImage = '';
  let heroImage = '';

  console.log('[DEBUG] Custom Screenshots Path:', customScreenshotsPath);
  console.log('[DEBUG] Resolved Screenshots Dir:', screenshotsDir);

  if (fs.existsSync(screenshotsDir)) {
    ensureDirectory(targetAssetsDir);
    const files = fs.readdirSync(screenshotsDir);
    console.log('[DEBUG] Files found:', files);

    files.forEach(file => {
      const src = path.join(screenshotsDir, file);
      if (fs.statSync(src).isFile()) {
        const dest = path.join(targetAssetsDir, file.toLowerCase());
        if (!fs.existsSync(dest) || fs.statSync(src).mtime > fs.statSync(dest).mtime) {
          fs.copyFileSync(src, dest);
          console.log(`[INFO] Copied asset (forced lowercase): ${file} -> ${dest}`);
        }
      }
    });

    const cardFile = readControlFile('3_DESIGN_STUDIO/CARD_IMAGE.txt', null) || extractValue(websiteContent, '**Card Image:**', 'UI & Styling') || files.find(f => f.startsWith('card')) || files.find(f => f.startsWith('cover')) || files.find(f => /\.(png|jpg|jpeg|webp|gif|mp4|webm)$/i.test(f));
    const heroFile = readControlFile('3_DESIGN_STUDIO/HERO_IMAGE.txt', null) || extractValue(websiteContent, '**Hero Image:**', 'UI & Styling') || files.find(f => f.startsWith('hero')) || files.find(f => f.startsWith('cover')) || files.find(f => /\.(png|jpg|jpeg|webp|gif|mp4|webm)$/i.test(f));

    if (cardFile) {
      cardImage = `/assets/projects/${config.slug}/${path.basename(cardFile).toLowerCase()}`;
      console.log(`[INFO] Selected Card Image: ${cardImage}`);
    }
    if (heroFile) {
      heroImage = `/assets/projects/${config.slug}/${path.basename(heroFile).toLowerCase()}`;
      console.log(`[INFO] Selected Hero Image: ${heroImage}`);
    }
  } else {
    console.warn('[WARN] Screenshots directory not found at:', screenshotsDir);
  }

  // 2. Parse Content & Styles
  const chapters = parseChapters(websiteContent);
  const pricing = parsePricing(websiteContent);
  const heroTitle = readControlFile('1_HERO_AND_HEADER/TITLE.txt', extractValue(websiteContent, '**Title:**', 'Hero Section'));
  const heroSubtitle = readControlFile('1_HERO_AND_HEADER/SUBTITLE.txt', extractValue(websiteContent, '**Subtitle:**', 'Hero Section'));
  const ctaPrimaryLabel = readControlFile('1_HERO_AND_HEADER/BTN_PRIMARY_TEXT.txt', extractValue(websiteContent, '**CTA Primary Label:**', 'Hero Section') || 'Download Now');
  const ctaPrimaryLink = readControlFile('1_HERO_AND_HEADER/BTN_PRIMARY_LINK.txt', extractValue(websiteContent, '**CTA Primary Link:**', 'Hero Section') || '#');
  const ctaSecondaryLabel = readControlFile('1_HERO_AND_HEADER/BTN_SECONDARY_TEXT.txt', extractValue(websiteContent, '**CTA Secondary Label:**', 'Hero Section') || 'Learn More');
  const ctaSecondaryLink = readControlFile('1_HERO_AND_HEADER/BTN_SECONDARY_LINK.txt', extractValue(websiteContent, '**CTA Secondary Link:**', 'Hero Section') || '#');
  const visionCaption = readControlFile('4_FINAL_CONVERSION/CAPTION.txt', extractValue(websiteContent, '**Caption:**', 'Demo & Vision'));
  const finalCTATitle = readControlFile('4_FINAL_CONVERSION/TITLE.txt', extractValue(websiteContent, '**Title:**', 'Final CTA'));
  const finalCTASubtitle = readControlFile('4_FINAL_CONVERSION/SUBTITLE.txt', extractValue(websiteContent, '**Subtitle:**', 'Final CTA'));
  const finalCTAButtonLabel = readControlFile('4_FINAL_CONVERSION/BUTTON_TEXT.txt', extractValue(websiteContent, '**Button Label:**', 'Final CTA') || 'Get Started');
  const finalCTAButtonLink = readControlFile('4_FINAL_CONVERSION/BUTTON_LINK.txt', extractValue(websiteContent, '**Button Link:**', 'Final CTA') || '#');

  const styles = {
    heroTitleSize: parseInt(readControlFile('3_DESIGN_STUDIO/HERO_FONT_SIZE_PX.txt', extractValue(websiteContent, '**Hero Title Size:**', 'UI & Styling'))) || 120,
    buttonPaddingX: parseInt(readControlFile('3_DESIGN_STUDIO/BUTTON_PADDING_X_PX.txt', extractValue(websiteContent, '**Button Padding X:**', 'UI & Styling'))) || 64,
    buttonPaddingY: parseInt(readControlFile('3_DESIGN_STUDIO/BUTTON_PADDING_Y_PX.txt', extractValue(websiteContent, '**Button Padding Y:**', 'UI & Styling'))) || 32,
    buttonTextSize: parseInt(readControlFile('3_DESIGN_STUDIO/BUTTON_TEXT_SIZE_PX.txt', extractValue(websiteContent, '**Button Text Size:**', 'UI & Styling'))) || 32,
    sectionSpacing: parseInt(readControlFile('3_DESIGN_STUDIO/SECTION_SPACING_PX.txt', extractValue(websiteContent, '**Section Spacing:**', 'UI & Styling'))) || 160,
    borderRadius: parseInt(readControlFile('3_DESIGN_STUDIO/CORNER_ROUNDNESS_PX.txt', extractValue(websiteContent, '**Border Radius:**', 'UI & Styling'))) || 32,
    brandLogo: readControlFile('3_DESIGN_STUDIO/BRAND_LOGO.txt', extractValue(websiteContent, '**Brand Logo:**', 'UI & Styling')),
    heroBackground: readControlFile('3_DESIGN_STUDIO/HERO_BACKGROUND.txt', extractValue(websiteContent, '**Hero Background:**', 'UI & Styling')),
    heroImgWidth: parseInt(readControlFile('3_DESIGN_STUDIO/HERO_IMG_WIDTH.txt', extractValue(websiteContent, '**Hero Img Width:**', 'UI & Styling'))) || 100,
    heroImgOffsetY: parseInt(readControlFile('3_DESIGN_STUDIO/HERO_IMG_OFFSET_Y.txt', extractValue(websiteContent, '**Hero Img Offset Y:**', 'UI & Styling'))) || 0,
    heroImgScale: parseInt(readControlFile('3_DESIGN_STUDIO/HERO_IMG_SCALE.txt', extractValue(websiteContent, '**Hero Img Scale:**', 'UI & Styling'))) || 100,
    heroVideoWidth: parseInt(readControlFile('3_DESIGN_STUDIO/HERO_VIDEO_WIDTH.txt', extractValue(websiteContent, '**Hero Video Width (px):**', 'UI & Styling') || '0')) || 0,
    heroVideoHeight: parseInt(readControlFile('3_DESIGN_STUDIO/HERO_VIDEO_HEIGHT.txt', extractValue(websiteContent, '**Hero Video Height (px):**', 'UI & Styling') || '0')) || 0,
  };

  // 3. Generate Project Files
  const pageDir = path.join(APP_PAGES_PATH, config.slug);
  ensureDirectory(pageDir);

  const data = {
    heroTitle, heroSubtitle, ctaPrimaryLabel, ctaPrimaryLink, ctaSecondaryLabel, ctaSecondaryLink,
    chapters, pricing, heroImage, visionCaption, finalCTATitle, finalCTASubtitle,
    finalCTAButtonLabel, finalCTAButtonLink, styles, remoteConfig, config,
    supportEmail: remoteConfig.support_email || 'zitounitidjani@gmail.com',
    supportPhone: remoteConfig.support_phone || '+213657293332'
  };

  // Generate page.tsx (Server Shell)
  const serverTemplatePath = path.join(CONTROL_DIR, 'template.tsx');
  let serverContent = fs.readFileSync(serverTemplatePath, 'utf8');
  serverContent = performReplacements(serverContent, data);
  fs.writeFileSync(path.join(pageDir, 'page.tsx'), serverContent, 'utf8');

  // Generate ProjectUI.tsx (Client UI)
  const clientTemplatePath = path.join(CONTROL_DIR, 'ProjectUI.tsx');
  let clientContent = fs.readFileSync(clientTemplatePath, 'utf8');
  clientContent = performReplacements(clientContent, data);
  fs.writeFileSync(path.join(pageDir, 'ProjectUI.tsx'), clientContent, 'utf8');

  // 4. Generate Registration Page
  const registerSlugDir = path.join(pageDir, 'register');
  if (!fs.existsSync(registerSlugDir)) fs.mkdirSync(registerSlugDir, { recursive: true });

  const registerServerShell = `
import { Metadata } from 'next';
import RegistrationUI from './RegistrationUI';

export const metadata: Metadata = {
  title: 'Register - ${config.name}',
  description: 'Create your account for ${config.name}',
};

export default function RegisterPage() {
  return <RegistrationUI />;
}
`;
  fs.writeFileSync(path.join(registerSlugDir, 'page.tsx'), registerServerShell);
  console.log(`[OK] Generated page.tsx for ${config.name} Registration`);

  // Generate RegistrationUI.tsx
  if (fs.existsSync(REGISTRATION_TEMPLATE_PATH)) {
    let regTemplate = fs.readFileSync(REGISTRATION_TEMPLATE_PATH, 'utf8');
    const regContent = performReplacements(regTemplate, data);
    fs.writeFileSync(path.join(registerSlugDir, 'RegistrationUI.tsx'), regContent);
    console.log(`[OK] Generated RegistrationUI.tsx for ${config.name}`);
  } else {
    console.warn('[WARN] RegistrationUI.tsx template not found in CONTROL_WEBSITE.');
  }

  // 4.5. Generate Dashboard Page (New Step)
  const dashboardSlugDir = path.join(pageDir, 'dashboard');
  ensureDirectory(dashboardSlugDir);

  const dashboardServerShell = `
import { Metadata } from 'next';
import DashboardUI from './DashboardUI';

export const metadata: Metadata = {
  title: 'Dashboard - ${config.name}',
  description: 'Manage your ${config.name} account',
};

export default function DashboardPage() {
  return <DashboardUI />;
}
`;
  fs.writeFileSync(path.join(dashboardSlugDir, 'page.tsx'), dashboardServerShell);
  console.log(`[OK] Generated page.tsx for ${config.name} Dashboard`);

  if (fs.existsSync(DASHBOARD_TEMPLATE_PATH)) {
    let dashTemplate = fs.readFileSync(DASHBOARD_TEMPLATE_PATH, 'utf8');
    const dashContent = performReplacements(dashTemplate, data);
    fs.writeFileSync(path.join(dashboardSlugDir, 'DashboardUI.tsx'), dashContent);
    console.log(`[OK] Generated DashboardUI.tsx for ${config.name}`);
  } else {
    console.warn('[WARN] DashboardUI.tsx template not found in CONTROL_WEBSITE.');
  }

  // 5. Generate lib/firebase.ts (if missing)
  const libDir = path.join(WEBSITE_ROOT, 'lib');
  ensureDirectory(libDir);

  const firebaseConfigContent = `
import { initializeApp, getApps, getApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";

const firebaseConfig = {
  apiKey: "AIzaSyDqW_c9YRyxM8GnICR9kSRvs1T-GhseZzY",
  authDomain: "dentaltid.firebaseapp.com",
  projectId: "dentaltid",
  storageBucket: "dentaltid.firebasestorage.app",
  messagingSenderId: "698475695605",
  appId: "1:698475695605:web:1e576e008f891e543964bc"
};

const app = !getApps().length ? initializeApp(firebaseConfig) : getApp();
const auth = getAuth(app);
const db = getFirestore(app);

export { auth, db };
`;

  // Always overwrite to ensure correctness
  fs.writeFileSync(FIREBASE_CONFIG_PATH, firebaseConfigContent);
  console.log('[OK] Generated/Updated lib/firebase.ts');

  // 6. Update projects.json
  const finalCardImage = cardImage || heroImage;
  console.log(`[INFO] Final Card Image for Registry: ${finalCardImage}`);
  updateProjectsJson(config, heroSubtitle, finalCardImage);

  // 7. Git Automation
  try {
    process.chdir(WEBSITE_ROOT);
    execSync('git add .');
    execSync(`git commit -m "feat: sync project ${config.slug} with Type-safe Server-Client split"`);
    execSync('git push');
  } catch (e) { }

  console.log('\n[SUCCESS] SYNC COMPLETED SUCCESSFULLY');
}

function performReplacements(template, data) {
  const { heroTitle, heroSubtitle, ctaPrimaryLabel, ctaPrimaryLink, ctaSecondaryLabel, ctaSecondaryLink, chapters, pricing, heroImage, visionCaption, finalCTATitle, finalCTASubtitle, finalCTAButtonLabel, finalCTAButtonLink, styles, remoteConfig, config, supportEmail, supportPhone } = data;

  const replace = (t, key, value) => {
    if (value === undefined || value === null) value = '';
    const regex = new RegExp(`{{\\s*${key}\\s*}}`, 'g');
    return t.replace(regex, () => value.toString());
  };

  let t = template;
  const words = (heroTitle || '').split(' ');
  const lastWord = words.pop();
  const heroTitleFormatted = `${words.join(' ')} <span className="bg-gradient-to-r from-emerald-400 to-cyan-400 bg-clip-text text-transparent">${lastWord}</span>`;

  const chaptersHtml = (chapters || []).map((c, i) => `
    <section key={${i}} style={{ paddingTop: '${styles.sectionSpacing}px', paddingBottom: '${styles.sectionSpacing}px' }} className="space-y-20">
      <div className="max-w-6xl mx-auto text-center space-y-10">
        <h2 className="text-6xl md:text-8xl font-black text-white tracking-tighter leading-tight">${c.title}</h2>
        <p className="text-2xl md:text-3xl text-neutral-400 leading-relaxed max-w-4xl mx-auto">${c.description}</p>
      </div>
      <div className="relative group/chapter w-full px-4 md:px-0">
        <div style={{ borderRadius: '${styles.borderRadius}px' }} className="aspect-video bg-[#0A0C10] border border-white/5 overflow-hidden shadow-[0_0_150px_rgba(0,0,0,0.8)] relative w-full">
           <div className="w-full h-full flex items-center justify-center overflow-hidden">
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

  const visionHtml = visionCaption ? `<section className="py-60 text-center w-full px-6 bg-gradient-to-b from-transparent via-emerald-500/5 to-transparent"><div className="max-w-6xl mx-auto"><div className="w-24 h-1.5 bg-emerald-500 mx-auto mb-16 rounded-full shadow-[0_0_20px_rgba(16,185,129,0.5)]" /><blockquote className="text-5xl md:text-7xl font-bold text-white italic leading-[1.1] tracking-tight">"${visionCaption}"</blockquote></div></section>` : '';
  const brandElement = styles.brandLogo ? `<img src="/assets/projects/${config.slug}/${styles.brandLogo}" className="h-12 w-auto object-contain" />` : `<div className="text-4xl font-black tracking-tighter text-white/90 underline decoration-emerald-500 decoration-4 underline-offset-8">${config.brand}</div>`;
  const heroImgElement = heroImage
    ? (heroImage.match(/\.(mp4|webm)$/i)
      ? `<video src="${heroImage}" autoPlay muted loop playsInline controls onClick={(e) => e.currentTarget.muted = !e.currentTarget.muted} style={{ width: '${styles.heroVideoWidth ? styles.heroVideoWidth + 'px' : '100%'}', height: '${styles.heroVideoHeight ? styles.heroVideoHeight + 'px' : 'auto'}', maxWidth: '${styles.heroImgWidth}%', transform: 'translateY(${styles.heroImgOffsetY}px) scale(${styles.heroImgScale / 100})', transition: 'all 1s cubic-bezier(0.4, 0, 0.2, 1)' }} className="object-cover transition-all duration-1000 group-hover/hero:scale-[1.01] cursor-pointer" />`
      : `<img src="${heroImage}" alt="${config.slug} Hero" style={{ maxWidth: '${styles.heroImgWidth}%', transform: 'translateY(${styles.heroImgOffsetY}px) scale(${styles.heroImgScale / 100})', transition: 'all 1s cubic-bezier(0.4, 0, 0.2, 1)' }} className="w-full h-full object-contain transition-all duration-1000 group-hover/hero:scale-[1.01]" />`)
    : `<div className="w-full h-full flex items-center justify-center text-neutral-800 italic text-4xl font-light">Hero Visual Coming Soon</div>`;
  const heroBgElement = styles.heroBackground ? `<div className="fixed inset-0 z-0 opacity-20"><img src="/assets/projects/${config.slug}/${styles.heroBackground}" className="w-full h-full object-cover" alt="" /></div>` : '';

  t = replace(t, 'META_TITLE', `${config.name} | ${config.brand}`);
  t = replace(t, 'META_DESCRIPTION', (heroSubtitle || '').replace(/'/g, "\\'"));
  t = replace(t, 'PRICING_DATA_JSON', JSON.stringify(remoteConfig.pricing || {}));
  t = replace(t, 'PLAN_STRUCTURE_JSON', JSON.stringify(pricing || []));
  t = replace(t, 'HERO_BACKGROUND_ELEMENT', heroBgElement); // FIXED NAME
  t = replace(t, 'BRAND_LOGO_ELEMENT', brandElement);
  t = replace(t, 'HERO_TITLE_HTML', heroTitleFormatted);
  t = replace(t, 'HERO_SUBTITLE', heroSubtitle);
  t = replace(t, 'CTA_PRIMARY_LINK', ctaPrimaryLink);
  t = replace(t, 'CTA_PRIMARY_LABEL', ctaPrimaryLabel);
  t = replace(t, 'CTA_SECONDARY_LINK', ctaSecondaryLink);
  t = replace(t, 'CTA_SECONDARY_LABEL', ctaSecondaryLabel);
  t = replace(t, 'SLUG', config.slug);
  t = replace(t, 'HERO_IMAGE_ELEMENT', heroImgElement);
  t = replace(t, 'CHAPTERS_HTML', chaptersHtml);
  t = replace(t, 'VISION_SECTION_HTML', visionHtml);
  t = replace(t, 'FINAL_CTA_TITLE', finalCTATitle);
  t = replace(t, 'FINAL_CTA_SUBTITLE', finalCTASubtitle);
  t = replace(t, 'FINAL_CTA_BUTTON_LINK', finalCTAButtonLink);
  t = replace(t, 'FINAL_CTA_BUTTON_LABEL', finalCTAButtonLabel);
  t = replace(t, 'YEAR', new Date().getFullYear());
  t = replace(t, 'BRAND_NAME', config.brand);
  t = replace(t, 'SUPPORT_EMAIL', supportEmail);
  t = replace(t, 'SUPPORT_PHONE', supportPhone);
  t = replace(t, 'STYLES_JSON', JSON.stringify(styles));

  return t;
}

function updateProjectsJson(config, subtitle, image) {
  ensureDirectoryExistence(PROJECTS_JSON_PATH);
  let projectsData = [];
  if (fs.existsSync(PROJECTS_JSON_PATH)) {
    projectsData = JSON.parse(fs.readFileSync(PROJECTS_JSON_PATH, 'utf8'));
  }
  const entry = {
    name: config.name,
    slug: config.slug,
    category: config.category,
    brand: config.brand,
    status: config.status,
    lastUpdated: new Date().toISOString(),
    description: subtitle || 'No description',
    image: image || '',
    thumbnail: image || '',
    imageUrl: image || '',
  };
  console.log(`[INFO] Updating projects.json entry for ${config.slug} with image: ${image}`);
  const idx = projectsData.findIndex(p => p.slug === config.slug);
  if (idx >= 0) projectsData[idx] = { ...projectsData[idx], ...entry };
  else projectsData.push(entry);
  fs.writeFileSync(PROJECTS_JSON_PATH, JSON.stringify(projectsData, null, 2), 'utf8');
}

function readControlFile(relPath, fallback) {
  const fullPath = path.join(CONTROL_DIR, relPath);
  return fs.existsSync(fullPath) ? fs.readFileSync(fullPath, 'utf8').trim() : fallback;
}

function ensureDirectoryExistence(filePath) {
  const dirname = path.dirname(filePath);
  if (!fs.existsSync(dirname)) {
    ensureDirectoryExistence(dirname);
    fs.mkdirSync(dirname);
  }
}

function ensureDirectory(dir) {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
}

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

function parseChapters(content) {
  const chaptersDir = path.join(CONTROL_DIR, '2_NARRATIVE_CHAPTERS');

  // Try parsing from the directory first (compatible with old structure)
  if (fs.existsSync(chaptersDir)) {
    const folders = fs.readdirSync(chaptersDir).filter(f => fs.statSync(path.join(chaptersDir, f)).isDirectory());
    if (folders.length > 0) {
      return folders.map((f, i) => ({
        title: readControlFile(path.join('2_NARRATIVE_CHAPTERS', f, 'TITLE.txt'), `Feature ${i + 1}`),
        description: readControlFile(path.join('2_NARRATIVE_CHAPTERS', f, 'DESCRIPTION.txt'), ''),
        image: readControlFile(path.join('2_NARRATIVE_CHAPTERS', f, 'IMAGE_NAME.txt'), ''),
        styles: {
          imgWidth: parseInt(readControlFile(path.join('2_NARRATIVE_CHAPTERS', f, 'IMG_WIDTH.txt'), '100')) || 100,
          imgOffsetY: parseInt(readControlFile(path.join('2_NARRATIVE_CHAPTERS', f, 'IMG_OFFSET.txt'), '0')) || 0,
          imgScale: parseInt(readControlFile(path.join('2_NARRATIVE_CHAPTERS', f, 'IMG_ZOOM.txt'), '100')) || 100,
        }
      }));
    }
  }

  // Fallback: Parse from WEBSITE.md
  const chapters = [];
  const lines = content.split('\n');
  let current = null;
  let inSection = false;

  for (const line of lines) {
    if (line.startsWith('## Feature Chapters')) inSection = true;
    else if (inSection && line.startsWith('## ') && !line.includes('Feature Chapters')) inSection = false;

    if (inSection && line.startsWith('### Chapter')) {
      if (current) chapters.push(current);
      current = {
        title: line.split(': ')[1] || line.replace('### Chapter ', '').trim(),
        styles: { imgWidth: 100, imgOffsetY: 0, imgScale: 100 }
      };
    } else if (inSection && current) {
      if (line.includes('**Description:**')) current.description = line.split('**Description:**')[1].trim();
      else if (line.includes('**Visual Hint:**')) current.image = line.split('**Visual Hint:**')[1].trim();
      else if (line.includes('**Img Width:**')) current.styles.imgWidth = parseInt(line.split('**Img Width:**')[1].trim()) || 100;
      else if (line.includes('**Img Offset Y:**')) current.styles.imgOffsetY = parseInt(line.split('**Img Offset Y:**')[1].trim()) || 0;
      else if (line.includes('**Img Scale:**')) current.styles.imgScale = parseInt(line.split('**Img Scale:**')[1].trim()) || 100;
    }
  }
  if (current) chapters.push(current);
  return chapters;
}

function parsePricing(content) {
  const plans = [];
  const lines = content.split('\n');
  let inPricing = false;
  let current = null;
  for (const line of lines) {
    if (line.startsWith('## Pricing')) inPricing = true;
    else if (inPricing && line.startsWith('## ')) inPricing = false;
    if (inPricing && line.startsWith('### Plan: ')) {
      if (current) plans.push(current);
      current = { name: line.replace('### Plan: ', '').trim(), features: [] };
    } else if (inPricing && current) {
      if (line.startsWith('**Price:**')) current.price = line.split('**Price:**')[1].trim();
      else if (line.startsWith('**Subtitle:**')) current.subtitle = line.split('**Subtitle:**')[1].trim();
      else if (line.startsWith('- ') || line.startsWith('* ')) current.features.push(line.substring(2).trim());
    }
  }
  if (current) plans.push(current);
  return plans;
}

main();
