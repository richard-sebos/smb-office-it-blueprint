import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
  base: '/smb-office-it-blueprint/',

  integrations: [
    starlight({
      title: 'SMB IT Blueprint Docs',
      social: [
        {
          icon: 'github',
          label: 'GitHub',
          href: 'https://github.com/richard-sebos/smb-office-it-blueprint'
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

