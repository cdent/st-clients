module Socialtext.Resting.Workspace where

import Control.Monad.State
import Socialtext.Resting.HTTP
import Socialtext.Resting.Templates
import Socialtext.Resting.Types hiding (workspace)

----------------
-- General
----------------
get_workspaces :: Rest String
get_workspaces = get_uri workspaces

get_workspace :: Rest String
get_workspace = get_uri workspace

----------------
-- Users
----------------
get_workspace_users :: Rest String
get_workspace_users = get_uri workspace_users

get_workspace_user :: String -> Rest String
get_workspace_user u = get_uri (workspace_user u)

----------------
-- Tags
----------------
get_workspace_tags :: Rest String
get_workspace_tags = get_uri workspace_tags

get_workspace_tag :: String -> Rest String
get_workspace_tag t = get_uri (workspace_tag t)

----------------
-- Attachments
----------------
get_workspace_attachments :: Rest String
get_workspace_attachments = get_uri workspace_attachments

get_workspace_attachment :: String -> Rest String
get_workspace_attachment = (get_uri.workspace_attachment)
