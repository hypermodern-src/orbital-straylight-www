// Catch-all for /omega/proxy/* routes - PureScript handles rendering

interface Props {
  params: Promise<{ slug: string[] }>
}

export default async function OmegaProxyCatchAll({ params }: Props) {
  const { slug } = await params
  const path = `/omega/proxy/${slug.join('/')}`
  
  return (
    <script
      dangerouslySetInnerHTML={{
        __html: `window.__STRAYLIGHT_PAGE__ = { pageType: 'omegaProxy', currentPath: '${path}' };`
      }}
    />
  )
}
