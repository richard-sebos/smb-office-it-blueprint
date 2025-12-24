import { defineConfig } from 'astro/config';
import starlight from '@astro/starlight';

export default defineConfig({
  base: '/smb-office-it-blueprint/',
  integrations: [
    starlight({
      title: 'SMB IT Blueprint Docs',
      route: '/docs',
      sidebar: [
        {
          label: 'Start Here',
          items: [{ label: 'Overview', slug: 'index' }],
        },
      ],
    }),
  ],
});

