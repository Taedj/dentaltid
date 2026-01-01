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

  if (fs.existsSync(screenshotsDir)) {
    ensureDirectory(targetAssetsDir);
    const files = fs.readdirSync(screenshotsDir);

    files.forEach(file => {
      const src = path.join(screenshotsDir, file);
      if (fs.statSync(src).isFile()) {
        const dest = path.join(targetAssetsDir, file);
        if (!fs.existsSync(dest) || fs.statSync(src).mtime > fs.statSync(dest).mtime) {
          fs.copyFileSync(src, dest);
        }
      }
    });

    const cardFile = readControlFile('3_DESIGN_STUDIO/CARD_IMAGE.txt', null) || files.find(f => f.startsWith('card')) || files.find(f => f.startsWith('cover')) || files.find(f => /\.(png|jpg|jpeg|webp|gif)$/i.test(f));
    const heroFile = readControlFile('3_DESIGN_STUDIO/HERO_IMAGE.txt', null) || files.find(f => f.startsWith('hero')) || files.find(f => f.startsWith('cover')) || files.find(f => /\.(png|jpg|jpeg|webp|gif)$/i.test(f));

    if (cardFile) cardImage = `/assets/projects/${config.slug}/${path.basename(cardFile)}`;
    if (heroFile) heroImage = `/assets/projects/${config.slug}/${path.basename(heroFile)}`;
  }

  // 2. Parse Content & Styles
  const chapters = parseChapters();
  const pricing = parsePricing(websiteContent);
  const heroTitle = readControlFile('1_HERO_AND_HEADER/TITLE.txt', extractValue(websiteContent, '**Title:**', 'Hero Section'));
  const heroSubtitle = readControlFile('1_HERO_AND_HEADER/SUBTITLE.txt', extractValue(websiteContent, '**Subtitle:**', 'Hero Section'));
  const ctaPrimaryLabel = readControlFile('1_HERO_AND_HEADER/BTN_PRIMARY_TEXT.txt', 'Download Now');
  const ctaPrimaryLink = readControlFile('1_HERO_AND_HEADER/BTN_PRIMARY_LINK.txt', '#');
  const ctaSecondaryLabel = readControlFile('1_HERO_AND_HEADER/BTN_SECONDARY_TEXT.txt', 'Learn More');
  const ctaSecondaryLink = readControlFile('1_HERO_AND_HEADER/BTN_SECONDARY_LINK.txt', '#');
  const visionCaption = readControlFile('4_FINAL_CONVERSION/CAPTION.txt', extractValue(websiteContent, '**Caption:**', 'Demo & Vision'));
  const finalCTATitle = readControlFile('4_FINAL_CONVERSION/TITLE.txt', extractValue(websiteContent, '**Title:**', 'Final CTA'));
  const finalCTASubtitle = readControlFile('4_FINAL_CONVERSION/SUBTITLE.txt', extractValue(websiteContent, '**Subtitle:**', 'Final CTA'));
  const finalCTAButtonLabel = readControlFile('4_FINAL_CONVERSION/BUTTON_TEXT.txt', 'Get Started');
  const finalCTAButtonLink = readControlFile('4_FINAL_CONVERSION/BUTTON_LINK.txt', '#');

  const styles = {
    heroTitleSize: parseInt(readControlFile('3_DESIGN_STUDIO/HERO_FONT_SIZE_PX.txt', '120')) || 120,
    buttonPaddingX: parseInt(readControlFile('3_DESIGN_STUDIO/BUTTON_PADDING_X_PX.txt', '64')) || 64,
    buttonPaddingY: parseInt(readControlFile('3_DESIGN_STUDIO/BUTTON_PADDING_Y_PX.txt', '32')) || 32,
    buttonTextSize: parseInt(readControlFile('3_DESIGN_STUDIO/BUTTON_TEXT_SIZE_PX.txt', '32')) || 32,
    sectionSpacing: parseInt(readControlFile('3_DESIGN_STUDIO/SECTION_SPACING_PX.txt', '160')) || 160,
    borderRadius: parseInt(readControlFile('3_DESIGN_STUDIO/CORNER_ROUNDNESS_PX.txt', '32')) || 32,
    brandLogo: readControlFile('3_DESIGN_STUDIO/BRAND_LOGO.txt', ''),
    heroBackground: readControlFile('3_DESIGN_STUDIO/HERO_BACKGROUND.txt', ''),
    heroImgWidth: parseInt(readControlFile('3_DESIGN_STUDIO/HERO_IMG_WIDTH.txt', '100')) || 100,
    heroImgOffsetY: parseInt(readControlFile('3_DESIGN_STUDIO/HERO_IMG_OFFSET_Y.txt', '0')) || 0,
    heroImgScale: parseInt(readControlFile('3_DESIGN_STUDIO/HERO_IMG_SCALE.txt', '100')) || 100,
  };

  // 3. Generate Project Files
  const pageDir = path.join(APP_PAGES_PATH, config.slug);
  ensureDirectory(pageDir);

  const data = {
    heroTitle, heroSubtitle, ctaPrimaryLabel, ctaPrimaryLink, ctaSecondaryLabel, ctaSecondaryLink,
    chapters, pricing, heroImage, visionCaption, finalCTATitle, finalCTASubtitle,
    finalCTAButtonLabel, finalCTAButtonLink, styles, remoteConfig, config
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

  // 4. Update projects.json
  updateProjectsJson(config, heroSubtitle, cardImage || heroImage);

  // 5. Git Automation
  try {
    process.chdir(WEBSITE_ROOT);
    execSync('git add .');
    execSync(`git commit -m "feat: sync project ${config.slug} with Server-Client split"`);
    execSync('git push');
  } catch (e) { }

  console.log('\n[SUCCESS] SYNC COMPLETED SUCCESSFULLY');
}

function performReplacements(template, data) {
  const { heroTitle, heroSubtitle, ctaPrimaryLabel, ctaPrimaryLink, ctaSecondaryLabel, ctaSecondaryLink, chapters, pricing, heroImage, visionCaption, finalCTATitle, finalCTASubtitle, finalCTAButtonLabel, finalCTAButtonLink, styles, remoteConfig, config } = data;

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

  const visionHtml = visionCaption ? `<section className="py-60 text-center w-full px-6 bg-gradient-to-b from-transparent via-emerald-500/5 to-transparent"><div className="max-w-6xl mx-auto"><div className="w-24 h-1.5 bg-emerald-500 mx-auto mb-16 rounded-full shadow-[0_0_20px_rgba(16,185,129,0.5)]" /><blockquote className="text-5xl md:text-7xl font-bold text-white italic leading-[1.1] tracking-tight">"${visionCaption}"</blockquote></div></section>` : '';
  const brandElement = styles.brandLogo ? `<img src="/assets/projects/${config.slug}/${styles.brandLogo}" className="h-12 w-auto object-contain" />` : `<div className="text-4xl font-black tracking-tighter text-white/90 underline decoration-emerald-500 decoration-4 underline-offset-8">${config.brand}</div>`;
  const heroImgElement = heroImage ? `<img src="${heroImage}" alt="${config.slug} Hero" style={{ maxWidth: '${styles.heroImgWidth}%', transform: 'translateY(${styles.heroImgOffsetY}px) scale(${styles.heroImgScale / 100})', transition: 'all 1s cubic-bezier(0.4, 0, 0.2, 1)' }} className="w-full h-full object-contain pt-16 transition-all duration-1000 group-hover/hero:scale-[1.01]" />` : `<div className="w-full h-full flex items-center justify-center text-neutral-800 italic text-4xl font-light">Hero Visual Coming Soon</div>`;

  t = replace(t, 'META_TITLE', `${config.name} | ${config.brand}`);
  t = replace(t, 'META_DESCRIPTION', (heroSubtitle || '').replace(/'/g, "\\'"));
  t = replace(t, 'PRICING_DATA_JSON', JSON.stringify(remoteConfig.pricing || {}));
  t = replace(t, 'PLAN_STRUCTURE_JSON', JSON.stringify(pricing || []));
  t = replace(t, 'HERO_BACKGROUND', styles.heroBackground ? `/assets/projects/${config.slug}/${styles.heroBackground}` : '');
  t = replace(t, 'BRAND_LOGO_ELEMENT', brandElement);
  t = replace(t, 'STYLE_HERO_TITLE_SIZE', styles.heroTitleSize);
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
  };
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

function parseChapters() {
  const chaptersDir = path.join(CONTROL_DIR, '2_NARRATIVE_CHAPTERS');
  if (!fs.existsSync(chaptersDir)) return [];
  return fs.readdirSync(chaptersDir)
    .filter(f => fs.statSync(path.join(chaptersDir, f)).isDirectory())
    .map((f, i) => ({
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
