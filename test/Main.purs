module Test.Main where

import Prelude

import Ansi.Codes (Color(..))
import Ansi.Output (foreground, withGraphics)
import Control.Monad.Writer.Trans (WriterT, execWriterT, tell)
import Data.Array.NonEmpty (head)
import Data.Bifunctor (lmap, rmap)
import Data.Either (Either(..), either, isLeft, note)
import Data.Either.Nested (type (\/))
import Data.Foldable (foldr)
import Data.Maybe (Maybe(..))
import Data.Number.Format as Number
import Data.Posix.Signal as Signal
import Data.String.Regex (match, regex)
import Data.String.Regex.Flags (multiline)
import Data.Traversable (for_)
import Data.Tuple.Nested ((/\))
import Effect (Effect)
import Effect.Aff (Aff, launchAff_, throwError)
import Effect.Aff.Class (liftAff)
import Effect.Class (liftEffect)
import Effect.Console as Console
import Effect.Exception (error)
import Node.ChildProcess (Exit(..))
import Node.ChildProcess as CP
import Node.Encoding (Encoding(..))
import Node.FS.Aff (rmdir, unlink, writeTextFile)
import Node.Path as Path
import Node.Process (cwd, exit)
import Sunde as S
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
  results <-
    execWriterT do
      runTest defaultViewport.width page
      for_ [ 360.0, 1024.0, 1920.0 ] \width -> do
        liftAff $ T.setViewport defaultViewport { width = width } page
        runTest width page
  let
    failed /\ passed =
      foldr (\x -> (if isLeft x then lmap else rmap) (_ + 1)) (0 /\ 0) results
  liftEffect
    $ Console.log
    $
      if failed == 0 then green ("\n" <> show passed <> " test(s) passed")
      else red ("\n" <> show failed <> " test(s) failed")
  T.close browser
  unlink html
  unlink js
  rmdir tmp
  when (failed /= 0) $ liftEffect $ exit 1

runTest :: Number -> T.Page -> WriterT (Array (String \/ String)) Aff Unit
runTest width page = do
  content <- liftAff $ T.content page
  let
    result =
      lmap (const $ red "✘ Bad regex") (regex "[0-9\\.]+px" multiline)
        >>= flip match content >>> note (red "✘ Value not found")
        >>= head >>> case _ of
          Nothing ->
            Left $ red "✘ No matching value"
          Just actual ->
            let
              expected = Number.toString width <> "px"
            in
              if actual == expected then
                Right $ green $ "✓ Found expected value \"" <> actual <> "\""
              else
                Left
                  $ red
                  $ "✘ Expected value \""
                      <> expected
                      <> "\", but found \""
                      <> actual
                      <> "\""
  liftEffect $ Console.log $ either identity identity result
  tell [ result ]

red :: String -> String
red = withGraphics $ foreground Red

green :: String -> String
green = withGraphics $ foreground Green

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
