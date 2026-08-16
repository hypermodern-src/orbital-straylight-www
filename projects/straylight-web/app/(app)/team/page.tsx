// PureScript takes over rendering - this is the SSR fallback

export default function Team() {
  return (
    <script
      dangerouslySetInnerHTML={{
        __html: `window.__STRAYLIGHT_PAGE__ = { pageType: 'team', currentPath: '/team' };`
      }}
    />
  )
}
