import { defineCollection, defineContentConfig, z } from '@nuxt/content'

export default defineContentConfig({
  collections: {
    docs: defineCollection({
      type: 'page',
      source: 'docs/**/*.md',
      schema: z.object({
        title: z.string(),
        description: z.string().optional(),
        layout: z.string().default('docs'),
        canonical: z.string().optional()
      })
    }),
    hub: defineCollection({
      type: 'page',
      source: 'hub/**/*.md',
      schema: z.object({
        title: z.string(),
        description: z.string().optional(),
        layout: z.string().default('hubdetail'),
        image: z.string().optional(),
        author: z.string().optional(),
        authorImage: z.string().optional(),
        category: z.string().optional()
      })
    }),
    landing: defineCollection({
      type: 'page',
      source: '*.md',
      schema: z.object({
        title: z.string(),
        description: z.string().optional(),
        layout: z.string().default('marketing')
      })
    })
  }
})
