module Test.Main where

import Prelude

import Data.Maybe (Maybe(..))
import Data.Number.Format as Number
import Data.Posix.Signal as Signal
import Data.String (Pattern(..))
import Data.String as String
import Data.Traversable (for_)
import Effect (Effect)
import Effect.Aff (Aff, launchAff_, throwError)
import Effect.Class (liftEffect)
import Effect.Console as Console
import Effect.Exception (error)
import Node.ChildProcess (Exit(..))
import Node.ChildProcess as CP
import Node.Encoding (Encoding(..))
import Node.FS.Aff (rmdir, unlink, writeTextFile)
import Node.Path as Path
import Node.Process (cwd)
import Sunde as S
import Test.Assert (assert')
import Toppokki as T

main :: Effect Unit
main = launchAff_ do
  root <- liftEffect cwd
  let
    tmp = Path.concat [ root, "tmp" ]
    html = Path.concat [ tmp, "index.html" ]
    js = Path.concat [ tmp, "index.js" ]
  build <- S.spawn
    { cmd: "spago"
    , args:
        [ "-x"
        , "example.dhall"
        , "bundle-app"
        , "-m"
        , "Example.Main"
        , "-t"
        , js
        ]
    , stdin: Nothing
    }
    CP.defaultSpawnOptions
  case build.exit of
    Normally code | code /= 0 -> do
      liftEffect $ Console.error build.stderr
      throwError $ error "Failed to build app."
    BySignal s ->
      throwError $ error $ "Unexpected signal: " <> Signal.toString s
    _ -> pure unit
  writeTextFile UTF8 html
    "<!DOCTYPE html><html><body style=\"margin:0\"><script src=\"index.js\"></script></body></html>"
  browser <- T.launch { defaultViewport, slowMo: 200.0 }
  page <- T.newPage browser
  url <- liftEffect $ T.URL <$> fileURL html
  T.goto url page
  _ <- T.pageWaitForSelector (T.Selector "div") {} page
  assertWidthDisplayed defaultViewport.width page
  for_ [ 360.0, 1024.0, 1920.0 ] \width -> do
    T.setViewport defaultViewport { width = width } page
    assertWidthDisplayed width page
  T.close browser
  unlink html
  unlink js
  rmdir tmp

assertWidthDisplayed :: Number -> T.Page -> Aff Unit
assertWidthDisplayed width page = do
  actual <- T.content page
  let expected = Number.toString width <> "px"
  liftEffect $
    assert'
      ("Width of " <> expected <> " should be displayed.")
      (String.contains (Pattern expected) actual)

defaultViewport :: { | T.DefaultViewPort }
defaultViewport =
  { width: 800.0
  , height: 600.0
  , deviceScaleFactor: 1.0
  , isMobile: false
  , hasTouch: false
  , isLandscape: false
  }

foreign import fileURL :: String -> Effect String
