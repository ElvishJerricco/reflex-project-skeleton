{-# LANGUAGE OverloadedStrings #-}

module Run where

import GHCJS.DOM.Types
import Reflex.Dom.Core

main :: JSM ()
main = mainWidget $ text "hi"
