// PureScript takes over rendering - this is the SSR fallback

export default function SensenetConfirm() {
  return (
    <script
      dangerouslySetInnerHTML={{
        __html: `window.__STRAYLIGHT_PAGE__ = { pageType: 'sensenetConfirm', currentPath: '/sensenet/confirm' };`
      }}
    />
  )
}
