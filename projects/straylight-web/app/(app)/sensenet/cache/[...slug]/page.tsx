// Catch-all for /sensenet/cache/* routes - PureScript handles rendering

interface Props {
  params: Promise<{ slug: string[] }>
}

export default async function SensenetCacheCatchAll({ params }: Props) {
  const { slug } = await params
  const path = `/sensenet/cache/${slug.join('/')}`
  
  return (
    <script
      dangerouslySetInnerHTML={{
        __html: `window.__STRAYLIGHT_PAGE__ = { pageType: 'sensenetCache', currentPath: '${path}' };`
      }}
    />
  )
}
