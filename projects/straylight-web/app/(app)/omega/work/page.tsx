// PureScript takes over rendering - this is the SSR fallback

export default function OmegaWork() {
  return (
    <script
      dangerouslySetInnerHTML={{
        __html: `window.__STRAYLIGHT_PAGE__ = { pageType: 'omegaWork', currentPath: '/omega/work' };`
      }}
    />
  )
}
