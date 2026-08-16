// Catch-all for /sensenet/forge/* routes - PureScript handles rendering

interface Props {
  params: Promise<{ slug: string[] }>
}

export default async function SensenetForgeCatchAll({ params }: Props) {
  const { slug } = await params
  const path = `/sensenet/forge/${slug.join('/')}`
  
  return (
    <script
      dangerouslySetInnerHTML={{
        __html: `window.__STRAYLIGHT_PAGE__ = { pageType: 'sensenetForge', currentPath: '${path}' };`
      }}
    />
  )
}
