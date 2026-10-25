import createMDX from '@next/mdx'

/** @type {import('next').NextConfig} */
const nextConfig = {
  // Self-contained server (.next/standalone/server.js) — the nix installPhase
  // copies this tree and the apps.default runner execs its server.js.
  // Vercel's @vercel/next builder handles output natively — standalone
  // produces a layout it doesn't expect.
  output: process.env.VERCEL ? undefined : 'standalone',
  images: {
    unoptimized: true,
  },
  pageExtensions: ['js', 'jsx', 'ts', 'tsx', 'md', 'mdx'],
}

const withMDX = createMDX({
  options: {
    remarkPlugins: [],
    rehypePlugins: [],
  },
})

export default withMDX(nextConfig)
