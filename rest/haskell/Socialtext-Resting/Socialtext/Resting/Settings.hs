module Socialtext.Resting.Settings (
    module Socialtext.Resting.Config.Types,
    Settings,
    load_settings,
    lookup_setting,
    lookup_setting'
) where

import Socialtext.Resting.Config.Types
import Socialtext.Resting.Config.CommandLine
import Socialtext.Resting.Config.File
import Maybe (catMaybes, listToMaybe, fromJust)

data Settings = Settings Config CommandLine [SettingDescr]
    deriving (Show, Eq)

load_settings :: [SettingDescr] -> IO Settings
load_settings sd = do
    cl <- parse_command_line sd                -- parse command line
    conf <- case lookup_opt cl "config" of     -- Check for config param
        Just file -> load_config file          -- if exist, use custom config
        Nothing -> load_default_config         -- else use default config
    assert_required_settings (Settings conf cl sd) -- Assert req. values exist

lookup_setting :: Settings -> String -> Maybe String
lookup_setting (Settings conf cl sd) k =
    (listToMaybe.catMaybes) [
        lookup_opt cl k,            -- Look on the command line first
        lookup k conf,              -- Then in the conf file
        lookup_default_value sd k   -- Then for a hard coded default value
    ]

lookup_setting' :: Settings -> String -> String
lookup_setting' s k = fromJust $ lookup_setting s k

assert_required_settings :: Settings -> IO Settings
assert_required_settings s@(Settings _ _ sd) = _do_check (filter isRequired sd)
    where
        missing x = "Missing Setting: " ++ (getSettingName x) ++ "\n"
        _do_check sd = 
            case (_check sd []) of
                (s, []) -> return s
                (_, errs) -> die_with_errors sd errs
        _check [] errs = (s, errs)
        _check (x:xs) errs = 
            case lookup_setting s (getSettingName x) of
                Just v -> _check xs errs
                Nothing -> _check xs ((missing x):errs)
