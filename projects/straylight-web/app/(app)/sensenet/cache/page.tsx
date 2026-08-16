// PureScript takes over rendering - this is the SSR fallback

export default function SensenetCache() {
  return (
    <script
      dangerouslySetInnerHTML={{
        __html: `window.__STRAYLIGHT_PAGE__ = { pageType: 'sensenetCache', currentPath: '/sensenet/cache' };`
      }}
    />
  )
}
