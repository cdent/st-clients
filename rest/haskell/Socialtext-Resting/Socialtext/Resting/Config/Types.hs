module Socialtext.Resting.Config.Types where

data SettingDescr =
    BareOpt String SettingType |
    Switch {
        short_name :: Char, 
        long_name :: String,
        sample_value :: String, 
        setting_kind :: SettingType,
        desc :: String
    }
    deriving (Show, Eq)

data SettingType = Required | Optional {default_value :: String }
    deriving (Show, Eq)

isBareOpt :: SettingDescr -> Bool
isBareOpt (BareOpt _ _) = True
isBareOpt _ = False

isSwitch :: SettingDescr -> Bool
isSwitch = not . isBareOpt

isRequired :: SettingDescr -> Bool
isRequired (BareOpt _ Required) = True
isRequired (Switch _ _ _ Required _) = True
isRequired _ = False

isOptional :: SettingDescr -> Bool
isOptional = not . isRequired

getDefaultValue :: SettingDescr -> Maybe String
getDefaultValue (BareOpt _ (Optional v)) = Just v
getDefaultValue (Switch _ _ _ (Optional v) _) = Just v
getDefaultValue _ = Nothing

getSettingName :: SettingDescr -> String
getSettingName (BareOpt n _) = n
getSettingName switch = long_name switch

lookup_default_value :: [SettingDescr] -> String -> Maybe String
lookup_default_value sd k =
    case lookup_setting_descr sd k of
        Just descr -> getDefaultValue descr
        Nothing -> Nothing

lookup_setting_descr :: [SettingDescr] -> String -> Maybe SettingDescr
lookup_setting_descr [] name = Nothing
lookup_setting_descr (x:xs) name | name == (getSettingName x) = Just x
                                 | otherwise = lookup_setting_descr xs name

die_with_errors :: [SettingDescr] -> [String] -> a
die_with_errors _ errs = error $ concat errs
