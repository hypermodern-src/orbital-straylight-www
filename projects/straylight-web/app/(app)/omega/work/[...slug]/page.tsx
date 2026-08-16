// Catch-all for /omega/work/* routes - PureScript handles rendering

interface Props {
  params: Promise<{ slug: string[] }>
}

export default async function OmegaWorkCatchAll({ params }: Props) {
  const { slug } = await params
  const path = `/omega/work/${slug.join('/')}`
  
  return (
    <script
      dangerouslySetInnerHTML={{
        __html: `window.__STRAYLIGHT_PAGE__ = { pageType: 'omegaWork', currentPath: '${path}' };`
      }}
    />
  )
}
