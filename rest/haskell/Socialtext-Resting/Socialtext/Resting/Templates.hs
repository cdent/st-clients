module Socialtext.Resting.Templates where


import Socialtext.Resting.Types (Rest, asks)
import qualified Socialtext.Resting.Types as R
import Network.URI (escapeURIString)

uri_escape :: String -> String
uri_escape = (escapeURIString good_char)
    where
        good_char = (`elem` uric)
        uric = "ABCDEFGHIJKLMNOPQRSTUVWXYZ" ++
               "abcdefghijklmnopwrstuvwxyz0123456789\\-_.!~*'()"

joinPath :: Rest String -> String -> Rest String
joinPath rs s = rs >>= \str -> return (str ++ "/"++ (uri_escape s))

joinPathM :: Rest String -> Rest String -> Rest String
joinPathM rs1 rs2 = rs2 >>= (rs1 `joinPath`)

data_root :: Rest String
data_root = return "data"

users :: Rest String
users = data_root `joinPath` "users"

user :: String -> Rest String
user = (users `joinPath`)

workspaces :: Rest String
workspaces = data_root `joinPath` "workspaces"

workspace :: Rest String
workspace = workspaces `joinPathM` (asks R.workspace)

workspace_users :: Rest String
workspace_users = workspace `joinPath` "users"

workspace_user :: String -> Rest String
workspace_user = (workspace_users `joinPath`)

workspace_attachments :: Rest String
workspace_attachments = workspace `joinPath` "attachments"

workspace_attachment :: String -> Rest String
workspace_attachment = (workspace_attachments `joinPath`)

workspace_tags :: Rest String
workspace_tags = workspace `joinPath` "tags"

workspace_tag :: String -> Rest String
workspace_tag = (workspace_tags `joinPath`)

tagged_pages :: String -> Rest String
tagged_pages tag = (workspace_tag tag) `joinPath` "pages"

pages :: Rest String
pages = workspace `joinPath` "pages"

page :: String -> Rest String
page = (pages `joinPath`)

page_comments :: String -> Rest String
page_comments p = (page p) `joinPath` "comments"

page_tags :: String -> Rest String
page_tags p = (page p) `joinPath` "tags"

page_tag :: String -> String -> Rest String
page_tag p = ((page_tags p) `joinPath`)

page_attachments :: String -> Rest String
page_attachments p = (page p) `joinPath` "attachments"

page_attachment :: String -> String -> Rest String
page_attachment p = ((page_attachments p) `joinPath`)
