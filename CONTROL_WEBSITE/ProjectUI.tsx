'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { FaArrowLeft, FaDownload, FaRocket } from 'react-icons/fa';

// Types and Interfaces
interface PricingPlan {
    monthly: string;
    yearly: string;
    lifetime: string;
}

interface CurrencyConfig {
    symbol: string;
    position: 'prefix' | 'suffix';
    plans: {
        [key: string]: PricingPlan;
    };
}

interface PlanStructureItem {
    name: string;
    subtitle?: string;
    price: string;
    features: string[];
}

interface StylesConfig {
    heroTitleSize: number;
    buttonPaddingX: number;
    buttonPaddingY: number;
    buttonTextSize: number;
    borderRadius: number;
    sectionSpacing: number;
    brandLogo: string;
    heroBackground: string;
    heroImgWidth: number;
    heroImgOffsetY: number;
    heroImgScale: number;
    heroVideoWidth: number;
    heroVideoHeight: number;
}

// Data injected by sync script
const PRICING_DATA: Record<string, CurrencyConfig> = {{ PRICING_DATA_JSON }};
const PLAN_STRUCTURE: PlanStructureItem[] = {{ PLAN_STRUCTURE_JSON }};
const STYLES: StylesConfig = {{ STYLES_JSON }};
const PROJECT_CONFIG = {
    name: '{{META_TITLE}}',
    slug: '{{SLUG}}',
    brand: '{{BRAND_NAME}}',
    email: '{{SUPPORT_EMAIL}}',
    phone: '{{SUPPORT_PHONE}}'
};

export default function ProjectUI() {
    const [currency, setCurrency] = useState('DZD');
    const [duration, setDuration] = useState<'monthly' | 'yearly' | 'lifetime'>('yearly');

    const getPrice = (planName: string, includeDuration: boolean = true) => {
        const tier = planName.toLowerCase().includes('crown') ? 'crown' : (planName.toLowerCase().includes('premium') ? 'premium' : null);
        if (!tier) return 'Free';

        const p = PRICING_DATA[currency];
        if (p && p.plans && p.plans[tier]) {
            const val = p.plans[tier][duration];
            const symbol = p.symbol || '';
            const position = p.position || 'suffix';

            const formatted = position === 'prefix' ? `${symbol}${val}` : `${val} ${symbol}`;
            if (!includeDuration) return formatted;
            return formatted + (duration === 'lifetime' ? '' : (duration === 'monthly' ? ' /mo' : ' /yr'));
        }
        return 'N/A';
    };

    const handleSelectPlan = (planName: string) => {
        if (planName.toLowerCase().includes('trial')) {
            window.location.href = "{{CTA_PRIMARY_LINK}}";
            return;
        }

        const price = getPrice(planName, false);
        const message = `Hello ${PROJECT_CONFIG.brand}, I would like to upgrade to the ${planName} plan (${duration}) for ${PROJECT_CONFIG.name} for ${price}. (Currency: ${currency})`;
        const encodedMessage = encodeURIComponent(message);

        // Prefer WhatsApp if available, otherwise Email
        if (PROJECT_CONFIG.phone) {
            const phone = PROJECT_CONFIG.phone.replace(/[\s+]/g, '');
            window.open(`https://wa.me/${phone}?text=${encodedMessage}`, '_blank');
        } else {
            window.location.href = `mailto:${PROJECT_CONFIG.email}?subject=Plan Upgrade: ${planName}&body=${encodedMessage}`;
        }
    };

    return (
        <div className="min-h-screen bg-[#080A0E] text-white selection:bg-emerald-500/30 overflow-x-hidden relative">
            {{ HERO_BACKGROUND_ELEMENT }}

            <div className="fixed top-0 left-0 right-0 h-24 bg-[#080A0E]/90 backdrop-blur-2xl z-40 border-b border-white/5 flex items-center px-10">
                {{ BRAND_LOGO_ELEMENT }}
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
                        <h1
                            style={{ filter: 'drop-shadow(0 20px 50px rgba(0,0,0,0.5))', fontSize: `clamp(3rem, 8vw, ${STYLES.heroTitleSize}px)` }}
                            className="font-black tracking-tighter leading-[0.9] text-white"
                        >
                            {{ HERO_TITLE_HTML }}
                        </h1>
                        <p className="text-xl md:text-4xl text-neutral-400 max-w-5xl mx-auto leading-tight font-medium px-4">{{ HERO_SUBTITLE }}</p>

                        <div className="flex flex-col md:flex-row flex-wrap gap-4 md:gap-8 pt-10 justify-center items-center px-6">
                            <Link
                                href="{{CTA_PRIMARY_LINK}}"
                                style={{ 
                                    padding: `clamp(16px, 4vw, ${STYLES.buttonPaddingY}px) clamp(32px, 5vw, ${STYLES.buttonPaddingX}px)`, 
                                    fontSize: `clamp(16px, 4vw, ${STYLES.buttonTextSize}px)`, 
                                    borderRadius: `${STYLES.borderRadius}px` 
                                }}
                                className="w-full md:w-auto bg-emerald-500 hover:bg-emerald-400 text-[#080A0E] font-black transition-all flex items-center justify-center gap-4 shadow-[0_20px_60px_rgba(16,185,129,0.3)] hover:scale-105 active:scale-95"
                            >
                                <FaDownload className="text-lg md:text-2xl" /> {{ CTA_PRIMARY_LABEL }}
                            </Link>
                            <Link
                                href="{{CTA_SECONDARY_LINK}}"
                                style={{ 
                                    padding: `clamp(16px, 4vw, ${STYLES.buttonPaddingY}px) clamp(32px, 5vw, ${STYLES.buttonPaddingX}px)`, 
                                    fontSize: `clamp(16px, 4vw, ${STYLES.buttonTextSize}px)`, 
                                    borderRadius: `${STYLES.borderRadius}px` 
                                }}
                                className="w-full md:w-auto bg-white/5 border border-white/10 hover:bg-white/10 text-white font-black transition-all flex items-center justify-center gap-4 hover:scale-105 active:scale-95"
                            >
                                {{ CTA_SECONDARY_LABEL }}
                            </Link>
                        </div>
                    </div>
                </section>

                <section className="pb-20 md:pb-40 w-full px-4 md:px-10">
                    <div style={{ borderRadius: `${STYLES.borderRadius}px` }} className="relative aspect-video overflow-hidden border border-white/5 shadow-[0_0_150px_rgba(16,185,129,0.1)] bg-[#0A0C10] group/hero w-full mx-auto flex items-center justify-center">
                        <div className="absolute top-0 left-0 right-0 h-10 md:h-16 bg-[#14171C] border-b border-white/5 flex items-center px-4 md:px-10 gap-2 md:gap-3 z-20">
                            <div className="w-3 h-3 md:w-5 md:h-5 rounded-full bg-red-500/40" />
                            <div className="w-3 h-3 md:w-5 md:h-5 rounded-full bg-yellow-500/40" />
                            <div className="w-3 h-3 md:w-5 md:h-5 rounded-full bg-green-500/40" />
                            <div className="ml-10 h-9 px-8 bg-white/5 rounded-xl border border-white/5 flex-grow max-w-2xl hidden lg:flex text-sm text-neutral-500 items-center font-mono tracking-widest text-left">{PROJECT_CONFIG.slug}.app/dashboard</div>
                        </div>
                        {{ HERO_IMAGE_ELEMENT }}
                    </div>
                </section>

                <div className="py-40 max-w-[95%] mx-auto text-left">
                    <div className="h-px w-full bg-gradient-to-r from-transparent via-white/10 to-transparent mb-40" />
                    {{ CHAPTERS_HTML }}
                </div>

                {{ VISION_SECTION_HTML }}

                {PLAN_STRUCTURE && PLAN_STRUCTURE.length > 0 && (
                    <section className="py-20 w-full px-6 text-center">
                        <h2 className="text-5xl md:text-7xl font-black text-white mb-10 tracking-tighter">Choose Your Plan</h2>

                        <div className="flex flex-col md:flex-row justify-center items-center gap-6 mb-20">
                            <div className="flex bg-white/5 rounded-full p-2 border border-white/10">
                                {Object.keys(PRICING_DATA).map(c => (
                                    <button key={c} onClick={() => setCurrency(c)} className={`px-6 py-2 rounded-full font-bold transition-all ${currency === c ? 'bg-emerald-500 text-black shadow-lg' : 'text-neutral-400 hover:text-white'}`}>{c}</button>
                                ))}
                            </div>

                            <div className="flex bg-white/5 rounded-full p-2 border border-white/10">
                                {(['monthly', 'yearly', 'lifetime'] as const).map(d => (
                                    <button key={d} onClick={() => setDuration(d)} className={`px-6 py-2 rounded-full font-bold transition-all capitalize ${duration === d ? 'bg-white text-black shadow-lg' : 'text-neutral-400 hover:text-white'}`}>{d}</button>
                                ))}
                            </div>
                        </div>

                        <div className="max-w-7xl mx-auto grid grid-cols-1 md:grid-cols-3 gap-8">
                            {PLAN_STRUCTURE.map((plan, i) => (
                                <div key={i} style={{ borderRadius: `${STYLES.borderRadius}px` }} className="bg-[#0A0C10] border border-white/5 p-10 flex flex-col text-left group hover:border-emerald-500/50 transition-all duration-500 relative overflow-hidden">
                                    <div className="absolute top-0 right-0 p-32 bg-emerald-500/10 rounded-full blur-3xl -translate-y-1/2 translate-x-1/2 group-hover:bg-emerald-500/20 transition-all" />
                                    <h3 className="text-3xl font-bold text-white mb-2">{plan.name}</h3>
                                    <p className="text-emerald-400 font-mono text-sm mb-6">{plan.subtitle || ''}</p>
                                    <div className="text-4xl font-black text-white mb-8 transition-all min-h-[3rem]">{getPrice(plan.name)}</div>
                                    <ul className="space-y-4 mb-10 flex-grow">
                                        {plan.features.map((f, fi) => <li key={fi} className="flex items-start gap-3 text-neutral-400"><span className="text-emerald-500 mt-1">✔</span> {f}</li>)}
                                    </ul>
                                    <button
                                        onClick={() => handleSelectPlan(plan.name)}
                                        className="w-full py-4 rounded-xl bg-white/5 hover:bg-emerald-600 hover:text-white text-white font-bold transition-all text-center border border-white/10"
                                    >
                                        Select Plan
                                    </button>
                                </div>
                            ))}
                        </div>
                    </section>
                )}

                <section className="py-20 md:py-60 text-center px-4 md:px-6">
                    <div className="bg-gradient-to-br from-emerald-600/20 via-[#0A0C10] to-cyan-600/20 p-8 md:p-40 border border-white/5 shadow-2xl relative overflow-hidden group" style={{ borderRadius: `${STYLES.borderRadius * 2}px` }}>
                        <div className="absolute inset-0 bg-emerald-500/5 opacity-0 group-hover:opacity-100 transition-opacity duration-1000" />
                        <h2 className="text-5xl md:text-[10rem] font-black mb-6 md:mb-12 tracking-tighter leading-none relative z-10" style={{ fontSize: 'clamp(3rem, 10vw, 10rem)' }}>{{ FINAL_CTA_TITLE }}</h2>
                        <p className="text-xl md:text-4xl text-neutral-400 mb-10 md:mb-20 max-w-4xl mx-auto leading-tight font-medium relative z-10">{{ FINAL_CTA_SUBTITLE }}</p>
                        <Link
                            href="{{FINAL_CTA_BUTTON_LINK}}"
                            style={{ 
                                padding: `clamp(16px, 4vw, ${STYLES.buttonPaddingY}px) clamp(32px, 5vw, ${STYLES.buttonPaddingX}px)`, 
                                fontSize: `clamp(20px, 4vw, ${STYLES.buttonTextSize}px)`, 
                                borderRadius: `${STYLES.borderRadius}px` 
                            }}
                            className="relative z-10 bg-white text-black font-black rounded-[2.5rem] hover:scale-105 active:scale-95 transition-all inline-flex items-center justify-center gap-4 md:gap-6 shadow-[0_30px_100px_rgba(255,255,255,0.15)] w-full md:w-auto"
                        >
                            <FaRocket className="text-2xl md:text-4xl" /> {{ FINAL_CTA_BUTTON_LABEL }}
                        </Link>
                    </div>
                </section>
            </main>

            <footer className="py-32 border-t border-white/5 text-center">
                <div className="mb-10 text-3xl font-black tracking-tighter text-white/20">TAEDJ ECOSYSTEM</div>
                <p className="text-xl text-neutral-600 font-medium">© {{ YEAR }} {{ BRAND_NAME }}. Finality through Precision.</p>
            </footer>
        </div>
    );
}
