import { Metadata } from 'next';
import ProjectUI from './ProjectUI';

export const metadata: Metadata = {
    title: '{{META_TITLE}}',
    description: '{{META_DESCRIPTION}}'
};

export default function Page() {
    return <ProjectUI />;
}
