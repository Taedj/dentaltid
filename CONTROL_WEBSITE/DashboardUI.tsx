'use client';

import React from 'react';
import { useRouter } from 'next/navigation';
import { FaCheckCircle, FaWindows, FaArrowRight } from 'react-icons/fa';

const PROJECT_CONFIG = {
    name: '{{META_TITLE}}',
    slug: '{{SLUG}}',
    brand: '{{BRAND_NAME}}'
};

export default function DashboardUI() {
    const router = useRouter();

    return (
        <div className="min-h-screen bg-[#080A0E] text-white selection:bg-emerald-500/30 flex flex-col items-center justify-center p-6 relative overflow-hidden">

            {/* Background Effects */}
            <div className="absolute top-0 left-0 w-full h-full overflow-hidden pointer-events-none">
                <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-emerald-500/10 rounded-full blur-[120px]" />
            </div>

            <div className="relative z-10 max-w-2xl w-full bg-[#0A0C10]/80 backdrop-blur-2xl border border-white/10 rounded-3xl p-12 text-center shadow-2xl">

                <div className="inline-flex items-center justify-center w-24 h-24 rounded-full bg-emerald-500/20 mb-8 animate-bounce-slow">
                    <FaCheckCircle className="text-6xl text-emerald-500" />
                </div>

                <h1 className="text-4xl md:text-5xl font-black mb-6 tracking-tight text-white">
                    Registration <span className="text-emerald-500">Successful!</span>
                </h1>

                <p className="text-xl text-neutral-400 mb-12 leading-relaxed">
                    Your account for <strong className="text-emerald-400">{PROJECT_CONFIG.brand}</strong> has been created.
                    <br />
                    To start managing your clinic, please download and sign in to the desktop application.
                </p>

                <div className="space-y-6">
                    <button
                        onClick={() => window.open('{{CTA_PRIMARY_LINK}}', '_blank')}
                        className="w-full py-5 rounded-xl bg-emerald-500 hover:bg-emerald-400 text-[#080A0E] font-black text-xl transition-all shadow-[0_10px_40px_rgba(16,185,129,0.3)] hover:scale-[1.02] active:scale-[0.98] flex items-center justify-center gap-4"
                    >
                        <FaWindows size={28} /> Download for Windows
                    </button>

                    <button
                        onClick={() => router.push(`/projects/${PROJECT_CONFIG.slug}`)}
                        className="text-neutral-500 hover:text-white font-medium transition-colors flex items-center justify-center gap-2 mx-auto"
                    >
                        Back to Home <FaArrowRight size={14} />
                    </button>
                </div>
            </div>

            <footer className="absolute bottom-10 text-neutral-600 text-sm font-medium">
                © {new Date().getFullYear()} {PROJECT_CONFIG.brand}. All rights reserved.
            </footer>
        </div>
    );
}
