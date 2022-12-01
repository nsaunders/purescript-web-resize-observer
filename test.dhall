let conf = ./spago.dhall

in conf // {
  sources = conf.sources # ["test/**/*.purs"],
  dependencies =
    conf.dependencies #
      [ "aff"
      , "assert"
      , "console"
      , "exceptions"
      , "maybe"
      , "node-buffer"
      , "node-child-process"
      , "node-fs-aff"
      , "node-path"
      , "node-process"
      , "numbers"
      , "posix-types"
      , "strings"
      , "sunde"
      , "toppokki"
      ]
}
