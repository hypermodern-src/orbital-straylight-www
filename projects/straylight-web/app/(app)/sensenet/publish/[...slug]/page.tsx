// Catch-all for /sensenet/publish/* routes - PureScript handles rendering

interface Props {
  params: Promise<{ slug: string[] }>
}

export default async function SensenetPublishCatchAll({ params }: Props) {
  const { slug } = await params
  const path = `/sensenet/publish/${slug.join('/')}`
  
  return (
    <script
      dangerouslySetInnerHTML={{
        __html: `window.__STRAYLIGHT_PAGE__ = { pageType: 'sensenetPublish', currentPath: '${path}' };`
      }}
    />
  )
}
