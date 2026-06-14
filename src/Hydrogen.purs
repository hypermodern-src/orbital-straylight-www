-- | Hydrogen Web Framework
-- |
-- | A PureScript/Halogen web framework for building robust web applications
-- | with type-safe routing, API clients, SSG support, and accessible UI components.
-- |
-- | ## Quick Start
-- |
-- | ```purescript
-- | import Hydrogen.Runtime.Router (class IsRoute, parseRoute, routeToPath)
-- | import Hydrogen.Data.Client (get, post, withAuth)
-- | import Hydrogen.UI.Core (cls, row, column)
-- | import Hydrogen.UI.Loading (loadingState, spinnerMd)
-- | import Hydrogen.UI.Error (errorState, emptyState)
-- | import Hydrogen.UI.Dialog as Dialog
-- | import Hydrogen.UI.Tabs as Tabs
-- | import Hydrogen.Data.Format (formatBytes, formatDuration)
-- | import Hydrogen.Data.RemoteData (RemoteData(..))
-- | import Hydrogen.Data.Query as Q
-- | ```
-- |
-- | ## Modules
-- |
-- | - **Hydrogen.Runtime.Router** - Type-safe client-side routing
-- | - **Hydrogen.Data.Client** - HTTP client with JSON encoding
-- | - **Hydrogen.UI.Core** - Layout and class utilities
-- | - **Hydrogen.UI.Loading** - Loading states and skeletons
-- | - **Hydrogen.UI.Error** - Error and empty states
-- | - **Hydrogen.UI.Dialog** - Accessible modal dialog with focus trapping
-- | - **Hydrogen.UI.Tabs** - Accessible tabs with keyboard navigation
-- | - **Hydrogen.UI.FocusTrap** - Focus management utilities
-- | - **Hydrogen.UI.AriaHider** - Screen reader isolation utilities
-- | - **Hydrogen.UI.Id** - Unique ID generation for accessibility
-- | - **Hydrogen.Data.Format** - Number/byte/duration formatting
-- | - **Hydrogen.Data.RemoteData** - RemoteData type for async state (lawful Monad)
-- | - **Hydrogen.Runtime.SSG** - Static site generation
-- | - **Hydrogen.Runtime.Renderer** - Render Halogen HTML to strings
-- | - **Hydrogen.Data.Query** - Data fetching with caching, deduplication, and QueryState
module Hydrogen
  ( module Hydrogen.Runtime.Router
  , module Hydrogen.Data.Client
  , module Hydrogen.UI.Core
  , module Hydrogen.UI.Loading
  , module Hydrogen.UI.Error
  , module Hydrogen.UI.FocusTrap
  , module Hydrogen.UI.AriaHider
  , module Hydrogen.UI.Id
  , module Hydrogen.Data.Format
  , module Hydrogen.Data.RemoteData
  , module Hydrogen.Runtime.SSG
  , module Hydrogen.Runtime.Renderer
  ) where

import Hydrogen.Runtime.Router (class IsRoute, class RouteMetadata, parseRoute, routeToPath, isProtected, isStaticRoute, routeTitle, routeDescription, routeOgImage, getPathname, getHostname, getOrigin, pushState, replaceState, onPopState, interceptLinks, navigate, normalizeTrailingSlash)
import Hydrogen.Data.Client (ApiConfig, defaultConfig, withAuth, withLogging, get, post, put, patch, delete, ApiResult)
import Hydrogen.UI.Core (classes, cls, svgCls, flex, row, column, box, container, section, svgNS)
import Hydrogen.UI.Loading (spinner, spinnerSm, spinnerMd, spinnerLg, loadingState, loadingInline, loadingCard, loadingCardLarge, skeletonText, skeletonRow)
import Hydrogen.UI.Error (errorState, errorCard, errorBadge, errorInline, emptyState)
import Hydrogen.UI.FocusTrap (FocusScope, createFocusScope, destroyFocusScope, trapFocus, releaseFocus, handleTabKey, focusFirst, focusLast, getTabbableElements)
import Hydrogen.UI.AriaHider (AriaHiderState, hideOthers, restoreOthers)
import Hydrogen.UI.Id (IdGenerator, createIdGenerator, nextId, useId)
import Hydrogen.Data.Format (formatBytes, formatBytesCompact, parseBytes, kb, mb, gb, tb, formatNum, formatNumCompact, formatPercent, formatCount, formatDuration, formatDurationCompact, formatDurationMs, percentage, rate, ratio)
import Hydrogen.Data.RemoteData (RemoteData(..), fromEither, fromMaybe, toEither, toMaybe, fold, withDefault, isNotAsked, isLoading, isFailure, isSuccess, mapError, map2, map3, map4, sequence, traverse)
import Hydrogen.Runtime.SSG (DocConfig, defaultDocConfig, PageMeta, renderPage, renderDocument, pageMetaFromRoute, renderRouteStatic, metaTags, ogTags, twitterTags)
import Hydrogen.Runtime.Renderer (render, renderWith, RenderOptions, defaultOptions)
