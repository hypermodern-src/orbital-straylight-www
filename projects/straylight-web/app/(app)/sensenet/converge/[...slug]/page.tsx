// Catch-all for /sensenet/converge/* routes - PureScript handles rendering

interface Props {
  params: Promise<{ slug: string[] }>
}

export default async function SensenetConvergeCatchAll({ params }: Props) {
  const { slug } = await params
  const path = `/sensenet/converge/${slug.join('/')}`
  
  return (
    <script
      dangerouslySetInnerHTML={{
        __html: `window.__STRAYLIGHT_PAGE__ = { pageType: 'sensenetConverge', currentPath: '${path}' };`
      }}
    />
  )
}
