module Example.Main where

import Prelude
import Data.Maybe (Maybe(..))
import Data.Traversable (traverse_)
import Effect (Effect)
import Effect.Exception (throw)
import Web.DOM.Document (createElement)
import Web.DOM.Element (toNode) as Element
import Web.DOM.Element (setAttribute)
import Web.DOM.Node (appendChild, setTextContent)
import Web.HTML (window)
import Web.HTML.HTMLDocument (body, toDocument)
import Web.HTML.HTMLElement (toNode) as HTMLElement
import Web.HTML.Window (document)
import Web.ResizeObserver (ResizeObserverBoxOptions(..), resizeObserver, observe)

main :: Effect Unit
main = do
  win <- window
  doc <- document win
  maybeBody <- body doc
  case maybeBody of
    Just body' -> do
      let htmlDoc = toDocument doc
      el <- createElement "div" htmlDoc
      el #
        setAttribute
          "style"
          """
            height:100px;
            background:#000;
            color:#fff;
            display:flex;
            align-items:center;
            justify-content:center;
            font:48px sans-serif;
          """
      let outputWidth w = setTextContent (show w <> "px") $ Element.toNode el 
      appendChild (Element.toNode el) (HTMLElement.toNode body')
      observer <- resizeObserver $
                    const <<< traverse_ (outputWidth <<< _.contentRect.width)
      observe el { box: ContentBox } observer
    Nothing ->
      throw "Could not find body element."
