// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// https://astro.build/config
export default defineConfig({
  base: '/smb-office-it-blueprint/', // 👈 Required for GitHub Pages

  integrations: [
    starlight({
      title: 'My Docs',
      social: [
        {
          icon: 'github',
          label: 'GitHub',
          href: 'https://github.com/withastro/starlight'
        }
      ],
      sidebar: [
        {
          label: 'Guides',
          items: [
            { label: 'Example Guide', slug: 'guides/example' }
          ]
        },
        {
          label: 'Reference',
          autogenerate: { directory: 'reference' }
        }
      ]
    })
  ]
});
