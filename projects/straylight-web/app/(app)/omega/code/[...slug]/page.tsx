// Catch-all for /omega/code/* routes - PureScript handles rendering

interface Props {
  params: Promise<{ slug: string[] }>
}

export default async function OmegaCodeCatchAll({ params }: Props) {
  const { slug } = await params
  const path = `/omega/code/${slug.join('/')}`
  
  return (
    <script
      dangerouslySetInnerHTML={{
        __html: `window.__STRAYLIGHT_PAGE__ = { pageType: 'omegaCode', currentPath: '${path}' };`
      }}
    />
  )
}
