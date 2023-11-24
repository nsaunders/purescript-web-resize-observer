module Web.ResizeObserver
  ( ResizeObserver
  , ResizeObserverBoxOptions(..)
  , ResizeObserverEntry
  , ResizeObserverEntry'
  , ResizeObserverSize
  , resizeObserver
  , observe
  , unobserve
  , disconnect
  ) where

import Prelude

import Control.Alt ((<|>))
import Control.Monad.Except (runExcept)
import Data.Array (singleton) as A
import Data.Either (fromRight)
import Data.Traversable (traverse)
import Effect (Effect)
import Effect.Uncurried
  ( EffectFn1
  , EffectFn2
  , EffectFn3
  , mkEffectFn2
  , runEffectFn1
  , runEffectFn2
  , runEffectFn3
  )
import Foreign (Foreign, readArray, readNumber)
import Foreign.Index (readProp)
import Prim.Row (class Nub, class Union)
import Record (merge, modify)
import Type.Proxy (Proxy(..))
import Web.DOM (Element)
import Web.DOM.Element (DOMRect)

data ResizeObserverBoxOptions
  = BorderBox
  | ContentBox
  | DevicePixelContentBox

printBoxOption :: ResizeObserverBoxOptions -> String
printBoxOption = case _ of
  BorderBox -> "border-box"
  ContentBox -> "content-box"
  DevicePixelContentBox -> "device-pixel-content-box"

type ResizeObserverOptions = (box :: ResizeObserverBoxOptions)

type ResizeObserverSize =
  { blockSize :: Number
  , inlineSize :: Number
  }

type ResizeObserverEntry' x =
  { target :: Element
  , contentRect :: DOMRect
  , borderBoxSize :: x
  , contentBoxSize :: x
  , devicePixelContentBoxSize :: x
  }

type ResizeObserverEntry = ResizeObserverEntry' (Array ResizeObserverSize)

foreign import data ResizeObserver :: Type

cmapEffectFn2Arg0
  :: forall a a' b c
   . (a -> a')
  -> EffectFn2 a' b c
  -> EffectFn2 a b c
cmapEffectFn2Arg0 f effFn = mkEffectFn2 \a b -> runEffectFn2 effFn (f a) b

normalizeEntry :: ResizeObserverEntry' Foreign -> ResizeObserverEntry
normalizeEntry entry =
  { target: entry.target
  , contentRect: entry.contentRect
  , borderBoxSize: normalizeBoxSize entry.borderBoxSize
  , contentBoxSize: normalizeBoxSize entry.contentBoxSize
  , devicePixelContentBoxSize: normalizeBoxSize entry.devicePixelContentBoxSize
  }
  where
  normalizeBoxSize boxSize =
    fromRight []
      $ runExcept
      $
        (readArray boxSize >>= traverse readBoxSize)
          <|> (A.singleton <$> readBoxSize boxSize)
          <|> pure []
  readBoxSize boxSize =
    (\blockSize inlineSize -> { blockSize, inlineSize })
      <$> (readProp "blockSize" boxSize >>= readNumber)
      <*> (readProp "inlineSize" boxSize >>= readNumber)

resizeObserver
  :: (Array ResizeObserverEntry -> ResizeObserver -> Effect Unit)
  -> Effect ResizeObserver
resizeObserver =
  runEffectFn1 _resizeObserver
    <<< cmapEffectFn2Arg0 (map normalizeEntry)
    <<< mkEffectFn2

foreign import _resizeObserver
  :: EffectFn1
       (EffectFn2 (Array (ResizeObserverEntry' Foreign)) ResizeObserver Unit)
       ResizeObserver

observe
  :: forall sub all
   . Nub all ResizeObserverOptions
  => Union sub ResizeObserverOptions all
  => Element
  -> { | sub }
  -> ResizeObserver
  -> Effect Unit
observe element =
  runEffectFn3 _observe element
    <<< modify (Proxy :: Proxy "box") printBoxOption
    <<< flip merge { box: ContentBox }

foreign import _observe
  :: EffectFn3 Element { box :: String } ResizeObserver Unit

unobserve :: Element -> ResizeObserver -> Effect Unit
unobserve = runEffectFn2 _unobserve

foreign import _unobserve :: EffectFn2 Element ResizeObserver Unit

disconnect :: ResizeObserver -> Effect Unit
disconnect = runEffectFn1 _disconnect

foreign import _disconnect :: EffectFn1 ResizeObserver Unit
