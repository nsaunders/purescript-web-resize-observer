{ name = "web-resize-observer"
, license = "MIT"
, repository = "https://github.com/nsaunders/purescript-web-resize-observer"
, dependencies =
  [ "arrays"
  , "console"
  , "control"
  , "effect"
  , "either"
  , "foldable-traversable"
  , "foreign"
  , "prelude"
  , "record"
  , "transformers"
  , "web-dom"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
}
