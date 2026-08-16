// PureScript takes over rendering - this is the SSR fallback

export default function OmegaBoost() {
  return (
    <script
      dangerouslySetInnerHTML={{
        __html: `window.__STRAYLIGHT_PAGE__ = { pageType: 'omegaBoost', currentPath: '/omega/boost' };`
      }}
    />
  )
}
