module Socialtext.Resting.Config.CommandLine (
    CommandLine,
    Opt(..),
    lookup_opt,
    parse_command_line
) where

import Socialtext.Resting.Config.Types
import System.Console.GetOpt
import System.Environment (getArgs)

type CommandLine = [Opt]
data Opt = Opt {opt_name :: String, opt_value :: String }
    deriving (Show, Eq)

lookup_opt :: CommandLine -> String -> Maybe String
lookup_opt [] _ = Nothing
lookup_opt (x:xs) k | k == opt_name x = Just (opt_value x)
                    | otherwise = lookup_opt xs k

switches2opts :: [SettingDescr] -> [OptDescr Opt]
switches2opts xs = map toOpt (filter isSwitch xs)
    where
        toOpt s = Option [short_name s] [long_name s] (arg_desc s) (desc s)
        arg_desc s = ReqArg (Opt (long_name s)) (sample_value s)

parse_command_line :: [SettingDescr] -> IO CommandLine
parse_command_line sd = do
    argv <- getArgs
    options <- return $ switches2opts sd
    return $ case getOpt Permute options argv of
        (opts, not_opts, []) -> opts ++ (parse_bare_opts sd not_opts)
        (_, _, errs) -> die_with_errors sd errs

parse_bare_opts :: [SettingDescr] -> [String] -> CommandLine
parse_bare_opts sd opts = _parse (filter isBareOpt sd) opts []
    where
        _parse [] ys@(_:_) _ = die_with_errors sd (err_unknown_args ys)
        _parse _ [] rv = rv
        _parse (x:xs) (y:ys) rv = _parse xs ys ((new_opt x y):rv)
        new_opt (BareOpt n _) v = Opt n v
        err_unknown_args xs = map (\x -> "Unknown argument: "++x++"\n") xs
