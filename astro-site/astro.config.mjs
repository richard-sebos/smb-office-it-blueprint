import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
  base: '/smb-office-it-blueprint/',
  integrations: [
    starlight({
      title: 'Linux Corporate Desktop',
      social: [
        {
          icon: 'github',
          label: 'GitHub',
          href: 'https://github.com/richard-sebos/smb-office-it-blueprint'
        }
      ],
      sidebar: [
        {
          label: 'Posts',
          items: [
            { label: 'Overview', slug: 'index' }
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

