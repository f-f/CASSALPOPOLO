module Main where

import Prelude hiding (min)
import Markov

main :: IO ()
main = do
  _ <- parseMatrix
  pure ()
