module Socialtext.Resting.Types (
    module Control.Monad.Reader,
    io,
    Rest,
    RestAuth(..),
    RestState(..),
    rest_auth,
    dev_env,
    rest_state
) where

import Control.Monad.Reader

------------------
-- Helper alias 
------------------
io :: IO a -> Rest a
io = liftIO

----------
-- Types
----------
type Rest a = ReaderT RestState IO a

data RestAuth = RestAuth {
    base_uri :: String,
    username :: String,
    password :: String
} deriving (Show, Eq)

data RestState = RestState {
    auth_info :: RestAuth,
    workspace :: String,
    accept :: String,
    content_type :: String
} deriving (Show, Eq)

------------------------
-- Auth constructors
------------------------
rest_auth :: RestAuth
rest_auth = RestAuth {
    base_uri = "",
    username = "",
    password = ""
}

---------------------------
-- Example Server to Use
---------------------------
dev_env :: Int -> RestAuth
dev_env port = rest_auth {
    base_uri = "http://talc.socialtext.net:" ++ (show port),
    username = "devnull1@socialtext.com",
    password = "d3vnu11l"
}

------------------------------
-- Default State Constructor
------------------------------
rest_state :: RestState
rest_state = RestState {
    auth_info = rest_auth,
    workspace = "",
    accept = "",
    content_type = ""
}
