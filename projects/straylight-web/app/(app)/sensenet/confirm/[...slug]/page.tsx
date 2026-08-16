// Catch-all for /sensenet/confirm/* routes - PureScript handles rendering

interface Props {
  params: Promise<{ slug: string[] }>
}

export default async function SensenetConfirmCatchAll({ params }: Props) {
  const { slug } = await params
  const path = `/sensenet/confirm/${slug.join('/')}`
  
  return (
    <script
      dangerouslySetInnerHTML={{
        __html: `window.__STRAYLIGHT_PAGE__ = { pageType: 'sensenetConfirm', currentPath: '${path}' };`
      }}
    />
  )
}
