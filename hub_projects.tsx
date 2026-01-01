import React from "react";
import Link from "next/link";
import Image from "next/image";
import projectsData from "../../data/projects.json";
import BackgroundText from "../BackgroundText/BackgroundText";
import { MdArrowForward } from "react-icons/md";
import "./Projects.css";

interface Project {
    name: string;
    slug: string;
    category: string;
    brand: string;
    status: string;
    description: string;
    image: string;
}

const Projects = () => {
    // Re-enable animation as requested by user
    const shouldAnimate = projectsData.length > 0;

    // To make a single project look better in a marquee, we add a "Coming Soon" placeholder
    // if there's only one project, to avoid seeing the same card 4 times in a row.
    const baseData: Project[] = [...projectsData] as Project[];
    if (baseData.length === 1) {
        baseData.push({
            name: "More Coming Soon",
            slug: "coming-soon",
            category: "Future",
            brand: "Taedj Dev",
            status: "planning",
            description: "We are constantly working on new innovative solutions. Stay tuned for the next breakthrough in the Taedj ecosystem.",
            image: "" // This will trigger the gradient placeholder
        });
    }

    const displayData = [...baseData, ...baseData, ...baseData, ...baseData];

    return (
        <section id="Taedj-Dev-Projects" className="py-24 px-6 md:px-12 bg-bg-dark overflow-hidden">
            <div className="max-w-[1224px] mx-auto">
                {/* Header Section */}
                <div className="mb-16 flex flex-col md:flex-row items-start md:items-end justify-between gap-6">
                    <div>
                        <BackgroundText
                            backgroundText="ECOSYSTEM"
                            innerText="Taedj Dev Projects"
                        />
                        <p className="text-gray-400 mt-6 max-w-2xl text-xl leading-relaxed relative z-10">
                            Explore our ecosystem of applications and tools built for performance and scale.
                            Our software is designed with a focus on medical precision and premium user experience.
                        </p>
                    </div>

                    {/* View Ecosystem Button (Animated) */}
                    <Link
                        href="/projects"
                        className="group animate-attention relative z-10 flex items-center gap-4 px-8 py-4 rounded-full bg-gradient-to-r from-bg-less-dark to-black border border-primary/40 hover:border-primary shadow-xl hover:shadow-primary/20 transition-all duration-500"
                    >
                        <span className="font-bold text-white text-lg group-hover:text-primary transition-colors">
                            View All Hub
                        </span>
                        <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center group-hover:translate-x-2 transition-transform">
                            <MdArrowForward className="text-primary" size={24} />
                        </div>
                    </Link>
                </div>

                {/* Marquee Container */}
                <div className="relative w-screen left-1/2 -ml-[50vw]">
                    <div className={`flex ${shouldAnimate ? 'animate-scroll' : 'justify-center flex-wrap'} hover:pause gap-12 px-12`}>
                        {displayData.map((project, index) => (
                            <Link
                                key={`${project.slug}-${index}`}
                                href={`/projects/${project.slug}`}
                                className="flex-shrink-0 w-[500px] bg-bg-less-dark rounded-2xl border border-border-color overflow-hidden hover:border-primary transition-all duration-500 group cursor-pointer shadow-2xl hover:shadow-primary/10"
                            >
                                {/* Project Image / Visual */}
                                <div className="h-64 bg-black relative overflow-hidden">
                                    {project.image ? (
                                        <Image
                                            src={project.image}
                                            alt={project.name}
                                            fill
                                            className="object-cover opacity-80 group-hover:opacity-100 group-hover:scale-105 transition-all duration-700"
                                        />
                                    ) : (
                                        <div className="absolute inset-0 bg-gradient-to-br from-bg-less-dark to-black flex items-center justify-center">
                                            <div className="w-24 h-24 rounded-3xl bg-gradient-to-br from-primary to-cyan-500 flex items-center justify-center text-4xl font-bold text-white shadow-2xl">
                                                {project.name.substring(0, 1)}
                                            </div>
                                        </div>
                                    )}
                                    <div className="absolute inset-0 bg-gradient-to-t from-bg-less-dark to-transparent opacity-60"></div>

                                    {/* Overlay Badge */}
                                    <div className="absolute top-6 right-6">
                                        <span className="text-sm font-black tracking-tighter uppercase px-4 py-1.5 rounded-lg bg-black/60 backdrop-blur-md border border-white/10 text-primary">
                                            {project.category}
                                        </span>
                                    </div>
                                </div>

                                <div className="p-10">
                                    <h3 className="text-3xl font-extrabold text-white mb-4 group-hover:text-primary transition-colors tracking-tight">
                                        {project.name}
                                    </h3>

                                    {/* Description: Increased size and clarity */}
                                    <p className="text-gray-300 text-lg leading-relaxed mb-8 line-clamp-3 h-[5.4rem]">
                                        {project.description}
                                    </p>

                                    <div className="flex items-center text-sm font-black text-primary/60 group-hover:text-primary transition-colors uppercase tracking-[0.2em]">
                                        Launch Project <MdArrowForward className="ml-3 group-hover:translate-x-2 transition-transform text-xl" />
                                    </div>
                                </div>
                            </Link>
                        ))}
                    </div>
                </div>
            </div>
        </section>
    );
};

export default Projects;
