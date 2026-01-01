'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { FaArrowLeft, FaUserMd, FaFileMedical, FaLock, FaServer, FaChartBar, FaShieldAlt } from 'react-icons/fa';

const PROJECT_CONFIG = {
    name: '{{META_TITLE}}',
    slug: '{{SLUG}}',
    brand: '{{BRAND_NAME}}'
};

type Language = 'EN' | 'FR' | 'AR';

const SECTIONS = [
    {
        id: 'dashboard',
        icon: FaChartBar,
        EN: {
            title: 'Intelligent Dashboard',
            description: 'The Command Center of your clinic. Designed for zero-latency awareness and proactive management.',
            details: [
                'Dynamic 3D KPI Cards for real-time status visibility.',
                'Integrated Broadcast Banner for system-wide announcements.',
                'Live appointment flow tracking with status indicators.',
                'Clinic-wide "Smooth Running" diagnostic indicators.',
                'High-fidelity live clock and localized date tracking.'
            ]
        },
        FR: {
            title: 'Tableau de Bord Intelligent',
            description: 'Le centre de commandement de votre clinique. Conçu pour une réactivité totale et une gestion proactive.',
            details: [
                'Cartes KPI 3D dynamiques pour une visibilité d\'état en temps réel.',
                'Bannière de diffusion intégrée pour les annonces du système.',
                'Suivi du flux de rendez-vous en direct avec indicateurs de statut.',
                'Indicateurs de diagnostic "Smooth Running" pour toute la clinique.',
                'Horloge haute fidélité et suivi de date localisé.'
            ]
        },
        AR: {
            title: 'لوحة التحكم الذكية',
            description: 'مركز القيادة لعيادتك. مصمم للاستجابة الفورية والإدارة الاستباقية.',
            details: [
                'بطاقات KPI ثلاثية الأبعاد لدقة المتابعة الفورية.',
                'شريط تنبيهات متكامل لإعلانات النظام والعيادة.',
                'تتبع حي لتدفق المواعيد مع مؤشرات الحالة.',
                'مؤشرات تشخيصية لضمان عمل العيادة بسلاسة.',
                'ساعة عالية الدقة وتتبع التاريخ المحلي.'
            ]
        }
    },
    {
        id: 'clinical',
        icon: FaUserMd,
        EN: {
            title: 'Clinical Practice Suite',
            description: 'Beyond records: a multi-dimensional approach to patient care and practice logistics.',
            details: [
                'Patient Blacklist & Severity prioritizing system.',
                'Granular health alerts and chronic condition tracking.',
                'Visit-by-visit treatment history with diagnosis logs.',
                'Integrated Imaging Gallery for intraoral and extraoral X-rays.',
                'NanoPix Live Sync: Automatic bi-directional image import/export.'
            ]
        },
        FR: {
            title: 'Suite de Pratique Clinique',
            description: 'Au-delà des dossiers : une approche multidimensionnelle des soins aux patients et de la logistique.',
            details: [
                'Système de liste noire et de priorité de sévérité des patients.',
                'Alertes de santé granulaires et suivi des maladies chroniques.',
                'Historique des traitements visite par visite avec journaux de diagnostic.',
                'Galerie d\'imagerie intégrée pour les radiographies intraorales et extraorales.',
                'NanoPix Live Sync : Import/export automatique d\'images bidirectionnel.'
            ]
        },
        AR: {
            title: 'جناح الممارسة السريرية',
            description: 'أكثر من مجرد سجلات: نهج متعدد الأبعاد لرعاية المرضى ولوجستيات العيادة.',
            details: [
                'نظام القائمة السوداء وتحديد أولويات خطورة الحالة.',
                'تنبيهات صحية دقيقة وتتبع الحالات المزمنة.',
                'سجل العلاج لكل زيارة مع مذكرات التشخيص.',
                'معرض صور متكامل للأشعة السنية الداخلية والخارجية.',
                'مزامنة نانوبيكس الحية: استيراد وتصدير الصور آلياً.'
            ]
        }
    },
    {
        id: 'prescriptions',
        icon: FaFileMedical,
        EN: {
            title: 'Advanced Medical Prescriptions',
            description: 'Professional-grade documentation with zero redundant data and extreme customizability.',
            details: [
                'Multilingual generation (EN, FR, AR) with native font support.',
                'Precision Posology: Automated formatting for dosage and route.',
                'Layout Studio: Adjustable background transparency and custom logos.',
                'Medicine Preset Engine for instant complex list creation.',
                'Digital Verification: Dynamic QR code integration on every print.'
            ]
        },
        FR: {
            title: 'Ordonnances Médicales Avancées',
            description: 'Documentation de qualité professionnelle avec zéro redondance et personnalisation extrême.',
            details: [
                'Génération multilingue (EN, FR, AR) avec support de polices natives.',
                'Posologie de précision : Formatage automatique du dosage et de la voie.',
                'Studio de mise en page : Transparence ajustable et logos personnalisés.',
                'Moteur de préréglages de médicaments pour création instantanée.',
                'Vérification numérique : Intégration de code QR dynamique sur chaque impression.'
            ]
        },
        AR: {
            title: 'الوصفات الطبية المتقدمة',
            description: 'وثائق احترافية مع دقة متناهية وقابلية تخصيص كاملة.',
            details: [
                'إنشاء متعدد اللغات (EN, FR, AR) مع دعم الخطوط الأصلية.',
                'دقة الجرعات: تنسيق تلقائي للكمية وطريقة الاستخدام.',
                'استوديو التنسيق: شفافية خلفية قابلة للتعديل وشعارات مخصصة.',
                'محرك ضبط الأدوية المسبق للإنشاء الفوري للقوائم المعقدة.',
                'التحقق الرقمي: تكامل رمز QR ديناميكي في كل طباعة.'
            ]
        }
    },
    {
        id: 'collaboration',
        icon: FaServer,
        EN: {
            title: 'Enterprise Staff Collaboration',
            description: 'A 100% Local LAN architecture ensuring data privacy and instant clinic-wide synchronization.',
            details: [
                'Zero-Latency Sync: No internet required for clinic-wide data flow.',
                'Dentist-Host / Staff-Client hierarchical architecture.',
                'Role-Based Security: Specialized views for Assistants and Receptionists.',
                'Real-time staff connection monitoring and server diagnostics.'
            ]
        },
        FR: {
            title: 'Collaboration d\'Équipe Entreprise',
            description: 'Une architecture LAN 100% locale garantissant la confidentialité des données et une synchro instantanée.',
            details: [
                'Synchronisation sans latence : Aucun internet requis pour le flux de données.',
                'Architecture hiérarchique Dentiste-Hôte / Personnel-Client.',
                'Sécurité par rôle : Vues spécialisées pour Assistantes et Réceptionnistes.',
                'Surveillance des connexions du personnel et diagnostics du serveur.'
            ]
        },
        AR: {
            title: 'تعاون الطاقم المتكامل',
            description: 'بنية تحتية محلية 100% تضمن خصوصية البيانات والمزامنة الفورية.',
            details: [
                'مزامنة فورية: لا حاجة للإنترنت لتدفق بيانات العيادة.',
                'بنية الطبيب (المضيف) والطاقم (العميل) الهرمية.',
                'أمان مبني على الأدوار: واجهات مخصصة للمساعدين وموظفي الاستقبال.',
                'مراقبة حية لاتصال الطاقم وتشخيصات الخادم.'
            ]
        }
    },
    {
        id: 'logistics',
        icon: FaShieldAlt,
        EN: {
            title: 'Automated Logistics & Finance',
            description: 'Remove the administrative burden with automated auditing and inventory intelligence.',
            details: [
                'Smart Inventory: Automated low-stock and expiration threshold alerts.',
                'Financial Auditing: Full transaction history with audit event logging.',
                'Recurring Charges: Automated tracking for Rent, Salaries, and Utilities.',
                'Daily & Weekly Financial Summaries with pro-rated expense tracking.'
            ]
        },
        FR: {
            title: 'Logistique et Finance Automatisées',
            description: 'Éliminez la charge administrative avec l\'audit automatique et l\'intelligence d\'inventaire.',
            details: [
                'Inventaire intelligent : Alertes automatiques de stock faible et d\'expiration.',
                'Audit financier : Historique complet avec journalisation des événements.',
                'Charges récurrentes : Suivi automatique du loyer, des salaires et des charges.',
                'Résumés financiers quotidiens et hebdomadaires avec suivi pro-rata.'
            ]
        },
        AR: {
            title: 'اللوجستيات والمالية المؤتمتة',
            description: 'إزالة العبء الإداري مع التدقيق الآلي وذكاء المخزون.',
            details: [
                'المخزون الذكي: تنبيهات آلية لنقص المخزون وانتهاء الصلاحية.',
                'التدقيق المالي: سجل معاملات كامل مع توثيق الأحداث.',
                'المصاريف المتكررة: تتبع آلي للإيجار، الرواتب، والمرافق.',
                'ملخصات مالية يومية وأسبوعية مع تتبع النفقات النسبية.'
            ]
        }
    },
    {
        id: 'security',
        icon: FaLock,
        EN: {
            title: 'Security & Data Redundancy',
            description: 'Military-grade data protection tailored for medical privacy standards.',
            details: [
                'Offline-First: Your database stays on your machine, always.',
                'SQLCipher Integration: Encrypted-at-rest local database.',
                'Dual-Shield Redundancy: Automated local backups + secure Cloud Sync.',
                'Device-level blocking and secure activation key validation.'
            ]
        },
        FR: {
            title: 'Sécurité et Redondance des Données',
            description: 'Protection des données de classe militaire adaptée aux normes de confidentialité médicale.',
            details: [
                'Offline-First : Votre base de données reste sur votre machine, toujours.',
                'Intégration SQLCipher : Base de données locale cryptée au repos.',
                'Redondance Dual-Shield : Sauvegardes locales + Cloud Sync sécurisé.',
                'Blocage au niveau de l\'appareil et validation par clé d\'activation.'
            ]
        },
        AR: {
            title: 'الأمن واحتياط البيانات',
            description: 'حماية بيانات بمعايير عسكرية مصممة لخصوصية السجلات الطبية.',
            details: [
                'الأولوية للمحلي: قاعدة بياناتك تبقى في جهازك دائماً.',
                'تكامل SQLCipher: تشفير قاعدة البيانات المحلية بالكامل.',
                'الاحتياط المزدوج: نسخ احتياطي محلي آلي + مزامنة سحابية آمنة.',
                'حظر الأجهزة غير المصرح بها والتحقق من مفاتيح التفعيل.'
            ]
        }
    }
];

const UI_TEXT = {
    EN: {
        title: 'Feature Report',
        subtitle: 'A comprehensive deep-dive into DentalTid capabilities',
        back: 'Back to Overview',
        footer: 'Finality through Precision.'
    },
    FR: {
        title: 'Rapport des Fonctionnalités',
        subtitle: 'Une plongée complète dans les capacités de DentalTid',
        back: 'Retour à la vue d\'ensemble',
        footer: 'La finalité par la précision.'
    },
    AR: {
        title: 'تقرير المميزات',
        subtitle: 'غوص شامل في قدرات DentalTid',
        back: 'العودة للملف الشخصي',
        footer: 'الكمال من خلال الدقة.'
    }
};

export default function FeaturesUI() {
    const [lang, setLang] = useState<Language>('EN');
    const [isMounted, setIsMounted] = useState(false);

    useEffect(() => {
        setIsMounted(true);
    }, []);

    if (!isMounted) return <div className="min-h-screen bg-[#080A0E]" />;

    const isAr = lang === 'AR';
    const t = UI_TEXT[lang];

    return (
        <div className={`min-h-screen bg-[#080A0E] text-white selection:bg-emerald-500/30 overflow-x-hidden relative flex flex-col ${isAr ? 'rtl' : 'ltr'}`} dir={isAr ? 'rtl' : 'ltr'} > 
            
            {/* Language Switcher */}
            <div className={`fixed top-8 z-50 flex bg-[#0A0C10]/80 backdrop-blur-xl border border-white/10 rounded-full p-1 shadow-2xl ${isAr ? 'left-8' : 'right-8'}`}>
                {(['EN', 'FR', 'AR'] as const).map((l) => (
                    <button
                        key={l}
                        onClick={() => setLang(l)}
                        className={`px-4 py-2 rounded-full text-sm font-bold transition-all ${lang === l ? 'bg-emerald-500 text-black shadow-lg' : 'text-neutral-400 hover:text-white'}`}
                    >
                        {l}
                    </button>
                ))}
            </div>

            <main className="relative z-10 w-full flex-grow py-20 px-6">
                <div className="max-w-6xl mx-auto"> 
                    
                    <Link href={`/projects/${PROJECT_CONFIG.slug}`} className="group inline-flex items-center gap-4 text-neutral-500 hover:text-white transition-all text-lg font-medium mb-20">
                        <div className="w-10 h-10 rounded-full border border-white/10 flex items-center justify-center group-hover:bg-white group-hover:text-black transition-all">
                            <FaArrowLeft className={`${isAr ? 'rotate-180' : ''} group-hover:-translate-x-1 transition-transform`} />
                        </div>
                        <span>{t.back}</span>
                    </Link>

                    <header className="mb-32 space-y-6 text-center md:text-left">
                        <h1 className="text-6xl md:text-8xl font-black tracking-tighter leading-none bg-gradient-to-r from-white via-white to-white/40 bg-clip-text text-transparent">
                            {t.title}
                        </h1>
                        <p className="text-xl md:text-3xl text-neutral-400 font-medium max-w-3xl mx-auto md:mx-0">
                            {t.subtitle}
                        </p>
                    </header>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-12">
                        {SECTIONS.map((section) => {
                            const Icon = section.icon;
                            const content = section[lang];
                            return (
                                <div key={section.id} className="group p-10 bg-[#0A0C10] border border-white/5 rounded-3xl hover:border-emerald-500/30 transition-all duration-500 relative overflow-hidden">
                                    <div className="absolute top-0 right-0 p-32 bg-emerald-500/5 rounded-full blur-3xl -translate-y-1/2 translate-x-1/2 opacity-0 group-hover:opacity-100 transition-opacity" />
                                    
                                    <div className="w-16 h-16 rounded-2xl bg-emerald-500/10 flex items-center justify-center text-emerald-500 text-3xl mb-8 group-hover:scale-110 transition-transform duration-500">
                                        <Icon />
                                    </div>

                                    <h2 className="text-3xl font-black mb-4 tracking-tight">{content.title}</h2>
                                    <p className="text-neutral-400 text-lg mb-8 leading-relaxed">
                                        {content.description}
                                    </p>

                                    <ul className="space-y-4">
                                        {content.details.map((detail, dIdx) => (
                                            <li key={dIdx} className="flex items-start gap-3 text-neutral-500 group-hover:text-neutral-300 transition-colors">
                                                <span className="text-emerald-500 mt-1.5 text-xs">●</span>
                                                <span className="font-medium">{detail}</span>
                                            </li>
                                        ))}
                                    </ul>
                                </div>
                            );
                        })}
                    </div>
                </div>
            </main>

            <footer className="py-20 border-t border-white/5 text-center mt-20">
                <div className="text-neutral-600 font-bold tracking-widest uppercase text-xs mb-4">TAEDJ Dev Ecosystem</div>
                <p className="text-neutral-500 font-medium">© {new Date().getFullYear()} {PROJECT_CONFIG.name}. {t.footer}</p>
            </footer>
        </div>
    );
}
