'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { FaArrowLeft, FaUserMd, FaClinicMedical, FaLock, FaEnvelope } from 'react-icons/fa';
import { createUserWithEmailAndPassword } from 'firebase/auth';
import { doc, setDoc, serverTimestamp } from 'firebase/firestore';
// ASSUMPTION: You have a centralized firebase export. Adjust path if necessary.
import { auth, db } from '../../../../lib/firebase';

const PROJECT_CONFIG = {
    name: '{{META_TITLE}}',
    slug: '{{SLUG}}',
    brand: '{{BRAND_NAME}}'
};

export default function RegistrationUI() {
    const router = useRouter();
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState('');

    // Form State
    const [formData, setFormData] = useState({
        email: '',
        password: '',
        confirmPassword: '',
        clinicName: '',
        dentistName: '',
        phoneNumber: '',
        medicalLicense: '',
        province: '',
        country: '',
        address: ''
    });

    const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        setFormData({ ...formData, [e.target.name]: e.target.value });
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');
        setIsLoading(true);

        // Validation
        if (formData.password !== formData.confirmPassword) {
            setError("Passwords do not match");
            setIsLoading(false);
            return;
        }

        try {
            // 1. Create Auth User
            const userCredential = await createUserWithEmailAndPassword(auth, formData.email, formData.password);
            const user = userCredential.user;

            // 2. Create Firestore Profile (Matching user_model.dart structure)
            const userProfile = {
                uid: user.uid,
                email: user.email,
                clinicName: formData.clinicName,
                dentistName: formData.dentistName,
                phoneNumber: formData.phoneNumber,
                medicalLicenseNumber: formData.medicalLicense,
                province: formData.province,
                country: formData.country,
                clinicAddress: formData.address,
                plan: 'trial',
                licenseKey: typeof crypto !== 'undefined' && crypto.randomUUID ? crypto.randomUUID() : Math.random().toString(36).substring(2) + Math.random().toString(36).substring(2), 
                status: 'active',
                isPremium: false,
                role: 'dentist',
                createdAt: serverTimestamp(),
                lastLogin: serverTimestamp(),
                lastSync: serverTimestamp(),
                trialStartDate: serverTimestamp(),
                cumulativePatients: 0,
                cumulativeAppointments: 0
            };

            await setDoc(doc(db, 'users', user.uid), userProfile);

            // 3. Success -> Redirect
            router.push(`/projects/${PROJECT_CONFIG.slug}/dashboard`); // Or success page
        } catch (err: unknown) {
            console.error("Registration Error: ", err);
            let errorMessage = "Failed to register. Please try again.";
            if (err instanceof Error) {
                errorMessage = err.message;
            }
            setError(errorMessage);
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="min-h-screen bg-[#080A0E] text-white selection:bg-emerald-500/30 overflow-x-hidden relative flex flex-col">
            {/* Background elements reused from landing */}
            {{ HERO_BACKGROUND_ELEMENT }}

            <div className="fixed top-0 left-0 right-0 h-24 bg-[#080A0E]/90 backdrop-blur-2xl z-40 border-b border-white/5 flex items-center px-10">
                {{ BRAND_LOGO_ELEMENT }}
            </div>

            <main className="relative z-10 w-full flex-grow flex items-center justify-center pt-32 pb-20 px-4">
                <div className="w-full max-w-5xl grid grid-cols-1 lg:grid-cols-2 gap-0 lg:gap-8 items-stretch">

                    {/* Left Panel: Info */}
                    <div className="hidden lg:flex flex-col justify-center p-10 bg-white/5 border border-white/10 rounded-l-3xl backdrop-blur-sm relative overflow-hidden">
                        <div className="absolute inset-0 bg-gradient-to-br from-emerald-500/10 to-transparent pointer-events-none" />
                        <h2 className="text-4xl font-black mb-6 z-10">Join {PROJECT_CONFIG.name}</h2>
                        <p className="text-xl text-neutral-400 mb-8 z-10">Start your 30-day free trial today. No credit card required. Experience the future of dental management.</p>

                        <div className="space-y-6 z-10">
                            <div className="flex items-center gap-4 text-emerald-400">
                                <div className="w-10 h-10 rounded-full bg-emerald-500/20 flex items-center justify-center"><FaUserMd /></div>
                                <span className="text-white font-medium">For Modern Dentists</span>
                            </div>
                            <div className="flex items-center gap-4 text-emerald-400">
                                <div className="w-10 h-10 rounded-full bg-emerald-500/20 flex items-center justify-center"><FaClinicMedical /></div>
                                <span className="text-white font-medium">Complete Clinic Management</span>
                            </div>
                            <div className="flex items-center gap-4 text-emerald-400">
                                <div className="w-10 h-10 rounded-full bg-emerald-500/20 flex items-center justify-center"><FaLock /></div>
                                <span className="text-white font-medium">Secure & Offline First</span>
                            </div>
                        </div>

                        <div className="mt-auto pt-10 z-10">
                            <Link href="https://www.tidjanizitouni.com/projects/dentaltid" className="flex items-center gap-2 text-neutral-500 hover:text-white transition-colors">
                                <FaArrowLeft /> Back to Home
                            </Link>
                        </div>
                    </div>

                    {/* Right Panel: Form */}
                    <div className="bg-[#0A0C10] border border-white/10 rounded-3xl lg:rounded-r-3xl lg:rounded-l-none p-8 md:p-12 shadow-2xl relative">
                        <h2 className="text-3xl font-bold mb-8 text-center lg:text-left">Create Account</h2>

                        {error && (
                            <div className="mb-6 p-4 bg-red-500/10 border border-red-500/20 rounded-xl text-red-400 text-sm">
                                {error}
                            </div>
                        )}

                        <form onSubmit={handleSubmit} className="space-y-6">
                            {/* Section: Credentials */}
                            <div className="space-y-4">
                                <h3 className="text-xs font-bold text-neutral-500 uppercase tracking-widest">Account</h3>
                                <div className="grid grid-cols-1 gap-4">
                                    <div className="relative group">
                                        <FaEnvelope className="absolute left-4 top-1/2 -translate-y-1/2 text-neutral-500 group-focus-within:text-emerald-500 transition-colors" />
                                        <input required type="email" name="email" placeholder="Email Address" onChange={handleChange} className="w-full bg-white/5 border border-white/10 rounded-xl py-3 pl-12 pr-4 text-white placeholder-neutral-500 focus:outline-none focus:border-emerald-500 focus:ring-1 focus:ring-emerald-500 transition-all font-medium" />
                                    </div>
                                    <div className="grid grid-cols-2 gap-4">
                                        <div className="relative group">
                                            <FaLock className="absolute left-4 top-1/2 -translate-y-1/2 text-neutral-500 group-focus-within:text-emerald-500 transition-colors" />
                                            <input required type="password" name="password" placeholder="Password" onChange={handleChange} className="w-full bg-white/5 border border-white/10 rounded-xl py-3 pl-12 pr-4 text-white placeholder-neutral-500 focus:outline-none focus:border-emerald-500 focus:ring-1 focus:ring-emerald-500 transition-all font-medium" />
                                        </div>
                                        <div className="relative group">
                                            <FaLock className="absolute left-4 top-1/2 -translate-y-1/2 text-neutral-500 group-focus-within:text-emerald-500 transition-colors" />
                                            <input required type="password" name="confirmPassword" placeholder="Confirm" onChange={handleChange} className="w-full bg-white/5 border border-white/10 rounded-xl py-3 pl-12 pr-4 text-white placeholder-neutral-500 focus:outline-none focus:border-emerald-500 focus:ring-1 focus:ring-emerald-500 transition-all font-medium" />
                                        </div>
                                    </div>
                                </div>
                            </div>

                            {/* Section: Professional Info */}
                            <div className="space-y-4 pt-4 border-t border-white/5">
                                <h3 className="text-xs font-bold text-neutral-500 uppercase tracking-widest">Profile</h3>
                                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                    <input required type="text" name="dentistName" placeholder="Dr. Full Name" onChange={handleChange} className="bg-white/5 border border-white/10 rounded-xl py-3 px-4 text-white focus:outline-none focus:border-emerald-500 transition-all" />
                                    <input required type="text" name="medicalLicense" placeholder="License Number" onChange={handleChange} className="bg-white/5 border border-white/10 rounded-xl py-3 px-4 text-white focus:outline-none focus:border-emerald-500 transition-all" />
                                </div>
                            </div>

                            {/* Section: Clinic Info */}
                            <div className="space-y-4 pt-4 border-t border-white/5">
                                <h3 className="text-xs font-bold text-neutral-500 uppercase tracking-widest">Clinic</h3>
                                <div className="grid grid-cols-1 gap-4">
                                    <input required type="text" name="clinicName" placeholder="Clinic Name" onChange={handleChange} className="w-full bg-white/5 border border-white/10 rounded-xl py-3 px-4 text-white focus:outline-none focus:border-emerald-500 transition-all" />
                                    <input required type="text" name="address" placeholder="Clinic Address" onChange={handleChange} className="w-full bg-white/5 border border-white/10 rounded-xl py-3 px-4 text-white focus:outline-none focus:border-emerald-500 transition-all" />
                                    <div className="grid grid-cols-2 gap-4">
                                        <input required type="text" name="country" placeholder="Country" onChange={handleChange} className="bg-white/5 border border-white/10 rounded-xl py-3 px-4 text-white focus:outline-none focus:border-emerald-500 transition-all" />
                                        <input required type="text" name="province" placeholder="Province/State" onChange={handleChange} className="bg-white/5 border border-white/10 rounded-xl py-3 px-4 text-white focus:outline-none focus:border-emerald-500 transition-all" />
                                    </div>
                                    <input required type="tel" name="phoneNumber" placeholder="Phone Number" onChange={handleChange} className="w-full bg-white/5 border border-white/10 rounded-xl py-3 px-4 text-white focus:outline-none focus:border-emerald-500 transition-all" />
                                </div>
                            </div>

                            <button
                                type="submit"
                                disabled={isLoading}
                                className="w-full bg-emerald-500 hover:bg-emerald-400 disabled:opacity-50 disabled:cursor-not-allowed text-black font-bold py-4 rounded-xl shadow-lg shadow-emerald-500/20 transition-all transform active:scale-95 text-lg mt-6"
                            >
                                {isLoading ? 'Creating Account...' : 'Create Account'}
                            </button>

                            <p className="text-neutral-500 text-sm text-center">
                                By registering, you agree to our Terms of Service and Privacy Policy.
                            </p>
                        </form>
                    </div>
                </div>
            </main>
        </div>
    );
}
