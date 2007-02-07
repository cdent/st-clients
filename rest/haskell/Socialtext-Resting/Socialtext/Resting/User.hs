module Socialtext.Resting.User where

import Socialtext.Resting.HTTP
import qualified Socialtext.Resting.Templates as T
import Socialtext.Resting.Types
import Control.Monad.State

get_users :: Rest String
get_users = get_uri T.users

get_user :: String -> Rest String
get_user = (get_uri.(T.user))
