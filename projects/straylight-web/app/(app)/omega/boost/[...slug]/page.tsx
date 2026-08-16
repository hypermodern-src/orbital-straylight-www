// Catch-all for /omega/boost/* routes - PureScript handles rendering

interface Props {
  params: Promise<{ slug: string[] }>
}

export default async function OmegaBoostCatchAll({ params }: Props) {
  const { slug } = await params
  const path = `/omega/boost/${slug.join('/')}`
  
  return (
    <script
      dangerouslySetInnerHTML={{
        __html: `window.__STRAYLIGHT_PAGE__ = { pageType: 'omegaBoost', currentPath: '${path}' };`
      }}
    />
  )
}
