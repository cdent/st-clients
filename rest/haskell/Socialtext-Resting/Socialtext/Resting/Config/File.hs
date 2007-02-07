module Socialtext.Resting.Config.File (
    Config,
    load_config,
    load_default_config
) where

import Char (isSpace)
import System.Directory (getHomeDirectory, doesFileExist)

type ConfigEntry = (String, String)
type Config = [ConfigEntry]

load_config :: String -> IO Config
load_config file = parse_config file

load_default_config :: IO Config
load_default_config = default_config >>= load_config

default_config :: IO FilePath
default_config = do
    home <- getHomeDirectory
    return $ home ++ "/.wikeditrc"

parse_config :: FilePath -> IO Config
parse_config file = do
    file_exists <- doesFileExist file
    if file_exists 
        then do
            contents <- readFile file 
            return $ map parse_line (lines contents)
        else
            return []

parse_line :: String -> ConfigEntry
parse_line l = (key l, value l)
    where
        key = eatSpace.(takeWhile (/= '=')).eatSpace
        value = eatSpace.(drop 1).(dropWhile (/= '='))
        eatSpace = reverse.strip.reverse.strip
        strip = dropWhile isSpace
