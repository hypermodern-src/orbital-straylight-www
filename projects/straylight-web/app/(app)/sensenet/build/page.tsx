// PureScript takes over rendering - this is the SSR fallback

export default function SensenetBuild() {
  return (
    <script
      dangerouslySetInnerHTML={{
        __html: `window.__STRAYLIGHT_PAGE__ = { pageType: 'sensenetBuild', currentPath: '/sensenet/build' };`
      }}
    />
  )
}
