{-# LANGUAGE LambdaCase          #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}
{-# OPTIONS_GHC -Wall #-}
{-# OPTIONS_GHC -fno-warn-unused-binds #-}

{- |

https://www.microsoft.com/en-us/research/project/data-driven-exploration-musical-chord-sequences/

-}
module Markov
  ( render
  , renderChord
  , runMarkov
  , getHarmony
  , transitions
  ) where

import qualified Control.Monad.Random as Random
import qualified Data.List
import qualified Data.Map.Strict      as Data.Map

import           Data.Bifunctor       (second)
import           Data.Char            (toLower)
import           Data.FileEmbed       (embedStringFile, makeRelativeToProject)
import           Data.List            (intercalate)
import           Data.Map.Strict      (Map)
import           Data.Maybe           (Maybe (..), catMaybes)
import           Prelude              hiding (min)

data Note
  = C
  | Cs
  | D
  | Ds
  | E
  | F
  | Fs
  | G
  | Gs
  | A
  | As
  | B
  | Rest
  deriving (Ord, Eq, Show)

data Chord
  = TriadMaj Note
  | TriadMin Note
  | TriadDim Note
  | TriadAug Note
  | TriadSus Note
  | Start
  | End
  deriving (Ord, Eq, Show)

type Transitions = Map Chord (Map Chord Double)

maj, min, dim, aug, sus :: (Int, Int, Int)
maj = (0, 4, 7)
min = (0, 3 ,7)
dim = (0, 3, 6)
aug = (0, 4, 8)
sus = (0, 5, 7)

notes :: [Note]
notes = [C, Cs, D, Ds, E, F, G, Gs, A, As, B]

variants :: [Note -> Chord]
variants = [TriadMaj, TriadMin, TriadDim, TriadAug, TriadSus]

transpose :: Note -> Int -> Note
transpose C  1      = Cs
transpose Cs 1      = D
transpose D  1      = Ds
transpose Ds 1      = E
transpose E  1      = F
transpose F  1      = Fs
transpose Fs 1      = G
transpose G  1      = Gs
transpose Gs 1      = A
transpose A  1      = As
transpose As 1      = B
transpose B  1      = C
transpose Rest _    = Rest
transpose note 0    = note
transpose note more = transpose (transpose note (subtract 1 (mod more 12))) 1

-- | PCA is for "principal component analysis"
pcaTransmodelMean :: String
pcaTransmodelMean = $(makeRelativeToProject "pca_transmodel_mean.txt" >>= embedStringFile)

transitions :: Transitions
transitions = processInput $ tail $ lines pcaTransmodelMean

processInput :: [String] -> Transitions
processInput ls = foldr (Data.Map.unionWith Data.Map.union)
                       (Data.Map.singleton Start starts)
                       [mids, ends]
  where
    combs :: [Chord]
    combs = [mkTriad note | note <- notes, mkTriad <- variants]

    (startWs, midAndEnds) = Data.List.span (/= "60 60") (tail ls)
    (midWs, endWs) = Data.List.span (/= "60") (tail midAndEnds)

    starts :: Map Chord Double
    starts = Data.Map.fromList $ catMaybes $ map
      (\(c, w) -> case read w of
          0.0 -> Nothing
          wn  -> Just (c, wn))
      (zip combs startWs)

    mids :: Transitions
    mids = foldr (Data.Map.unionWith Data.Map.union) mempty $ catMaybes $ map
      (\(weight, (c1, c2)) -> case read weight of
          0.0 -> Nothing
          w   -> Just $ Data.Map.singleton c1 (Data.Map.singleton c2 w))
      (zip midWs [(c1, c2) | c1 <- combs, c2 <- combs])

    ends :: Transitions
    ends = foldr Data.Map.union mempty $ map
      (\(triad, weight) -> Data.Map.singleton triad (Data.Map.singleton End (read weight)))
      (zip combs (tail endWs))

runMarkov :: Chord -> IO [Chord]
runMarkov chord = fmap (reverse . tail) $ go chord []
  where
    go End acc = pure acc
    go c acc = do
      next <- nextChord c
      go next (next : acc)

    nextChord :: Chord -> IO Chord
    nextChord c = case Data.Map.lookup c transitions of
      Just from -> pickChord $ Data.Map.toList from
      Nothing   -> pure End

    pickChord :: [(Chord, Double)] -> IO Chord
    pickChord probs = do
      gen <- Random.newStdGen
      pure $ head $ weightedList gen $ fmap (second toRational) probs

    weightedList :: Random.RandomGen g => g -> [(a, Rational)] -> [a]
    weightedList gen weights = Random.evalRand m gen
      where m = sequence . repeat . Random.fromList $ weights

getHarmony :: Int -> IO [Chord]
getHarmony n = go []
  where
    go lastSeq = do
      case (length lastSeq) == n of
        True  -> pure lastSeq
        False -> runMarkov Start >>= go

renderChord :: Chord -> Maybe String
renderChord = \case
  TriadMaj n -> Just $ renderNote n <> "'maj"
  TriadMin n -> Just $ renderNote n <> "'min"
  TriadAug n -> Just $ renderNote n <> "'aug"
  TriadDim n -> Just $ renderNote n <> "'dim"
  TriadSus n -> Just $ renderNote n <> "'sus4"
  _ -> Nothing
  where
    renderNote = \case
      Rest -> error "Cannot render a chord with Rest"
      n -> fmap toLower $ show n

render :: [Chord] -> String
render cs = intercalate " " (catMaybes $ map renderChord cs)
