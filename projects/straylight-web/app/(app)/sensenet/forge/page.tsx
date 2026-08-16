// PureScript takes over rendering - this is the SSR fallback

export default function SensenetForge() {
  return (
    <script
      dangerouslySetInnerHTML={{
        __html: `window.__STRAYLIGHT_PAGE__ = { pageType: 'sensenetForge', currentPath: '/sensenet/forge' };`
      }}
    />
  )
}
