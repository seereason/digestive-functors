{-# LANGUAGE OverloadedStrings #-}
module Text.Digestive.Tests.Fixtures
    ( TrainerM
    , runTrainerM
    , Type (..)
    , Pokemon (..)
    , pokemonForm
    , Ball (..)
    , ballForm
    , Catch (..)
    , catchForm
    , floatForm
    ) where

import Control.Applicative ((<$>), (<*>))
import Control.Monad.Reader (Reader, ask, runReader)

import Data.Text (Text)
import qualified Data.Text as T

import Text.Digestive.Form
import Text.Digestive.Types

-- Maximum level
type TrainerM = Reader Int

-- Default max level: 20
runTrainerM :: TrainerM a -> a
runTrainerM = flip runReader 20

data Type = Water | Fire | Leaf
    deriving (Eq, Show)

typeForm :: Monad m => Form Text m Type
typeForm = choice [(Water, "Water"), (Fire, "Fire"), (Leaf, "Leaf")] Nothing

data Pokemon = Pokemon
    { pokemonName  :: Text
    , pokemonLevel :: Maybe Int
    , pokemonType  :: Type
    , pokemonRare  :: Bool
    } deriving (Eq, Show)

levelForm :: Form Text TrainerM (Maybe Int)
levelForm =
    checkM "This pokemon will not obey you!" checkMaxLevel      $
    check  "Level should be at least 1"      (maybe True (> 1)) $
    optionalStringRead "Cannot parse level" Nothing
  where
    checkMaxLevel Nothing  = return True
    checkMaxLevel (Just l) = do
        maxLevel <- ask
        return $ l <= maxLevel

pokemonForm :: Form Text TrainerM Pokemon
pokemonForm = Pokemon
    <$> "name"  .: validate isPokemon (text Nothing)
    <*> "level" .: levelForm
    <*> "type"  .: typeForm
    <*> "rare"  .: bool Nothing
  where
    definitelyNoPokemon = ["dog", "cat"]
    isPokemon name
        | name `notElem` definitelyNoPokemon = Success name
        | otherwise                          =
            Error $ name `T.append` " is not a pokemon!"

data Ball = Poke | Great | Ultra | Master
    deriving (Eq, Show)

ballForm :: Monad m => Form Text m Ball
ballForm = choice
    [(Poke, "Poke"), (Great, "Great"), (Ultra, "Ultra"), (Master, "Master")]
    Nothing

data Catch = Catch
    { catchPokemon :: Pokemon
    , catchBall    :: Ball
    } deriving (Eq, Show)

catchForm :: Form Text TrainerM Catch
catchForm = check "You need a better ball" canCatch $ Catch
    <$> "pokemon" .: pokemonForm
    <*> "ball"    .: ballForm

canCatch :: Catch -> Bool
canCatch (Catch (Pokemon _ _ _ False) _)      = True
canCatch (Catch (Pokemon _ _ _ True)  Ultra)  = True
canCatch (Catch (Pokemon _ _ _ True)  Master) = True
canCatch _                                    = False

floatForm :: Monad m => Form Text m Float
floatForm = "f" .: stringRead "Can't parse float" Nothing
