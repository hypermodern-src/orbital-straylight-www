// Catch-all for /sensenet/build/* routes - PureScript handles rendering

interface Props {
  params: Promise<{ slug: string[] }>
}

export default async function SensenetBuildCatchAll({ params }: Props) {
  const { slug } = await params
  const path = `/sensenet/build/${slug.join('/')}`
  
  return (
    <script
      dangerouslySetInnerHTML={{
        __html: `window.__STRAYLIGHT_PAGE__ = { pageType: 'sensenetBuild', currentPath: '${path}' };`
      }}
    />
  )
}
