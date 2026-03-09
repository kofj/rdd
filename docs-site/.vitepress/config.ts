import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'RDD Framework',
  description: 'Roadmap Driven Development Framework for AI Agents',

  head: [
    ['meta', { name: 'theme-color', content: '#3eaf7c' }],
    ['meta', { name: 'apple-mobile-web-app-capable', content: 'yes' }],
    ['meta', { name: 'apple-mobile-web-app-status-bar-style', content: 'black' }]
  ],

  themeConfig: {
    repo: 'kofj/rdd',
    repoLabel: 'GitHub',

    docsDir: 'docs-site',
    docsBranch: 'main',

    editLinks: true,
    editLinkText: 'Edit this page on GitHub',

    lastUpdated: 'Last Updated',

    nav: [
      { text: 'Guide', link: '/getting-started/installation' },
      { text: 'Concepts', link: '/concepts/roadmap' },
      { text: 'API', link: '/api/skills' },
      { text: 'Examples', link: '/examples/simple-project' }
    ],

    sidebar: {
      '/getting-started/': [
        {
          text: 'Getting Started',
          items: [
            { text: 'Installation', link: '/getting-started/installation' },
            { text: 'Quick Start', link: '/getting-started/quick-start' },
            { text: 'First Project', link: '/getting-started/first-project' }
          ]
        }
      ],
      '/concepts/': [
        {
          text: 'Concepts',
          items: [
            { text: 'Roadmap', link: '/concepts/roadmap' },
            { text: 'Stages', link: '/concepts/stages' },
            { text: 'Gates', link: '/concepts/gates' },
            { text: 'Decisions (ADR)', link: '/concepts/decisions' },
            { text: 'Tech Debt', link: '/concepts/tech-debt' }
          ]
        }
      ],
      '/api/': [
        {
          text: 'API Reference',
          items: [
            { text: 'Skills', link: '/api/skills' },
            { text: 'Commands', link: '/api/commands' },
            { text: 'Hooks', link: '/api/hooks' },
            { text: 'Scripts', link: '/api/scripts' }
          ]
        }
      ],
      '/guides/': [
        {
          text: 'Guides',
          items: [
            { text: 'Project Setup', link: '/guides/project-setup' },
            { text: 'Stage Execution', link: '/guides/stage-execution' },
            { text: 'Review Process', link: '/guides/review-process' },
            { text: 'Notifications', link: '/guides/notifications' }
          ]
        }
      ],
      '/examples/': [
        {
          text: 'Examples',
          items: [
            { text: 'Simple Project', link: '/examples/simple-project' },
            { text: 'Multi-Stage Project', link: '/examples/multi-stage' }
          ]
        }
      ]
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/kofj/rdd' }
    ],

    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2026 kofj'
    },

    search: {
      provider: 'local'
    }
  }
})
