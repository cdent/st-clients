module Socialtext.Resting.Page where

import Socialtext.Resting.HTTP
import Socialtext.Resting.Templates
import Socialtext.Resting.Types

--------------
-- General
--------------
get_pages :: Rest String
get_pages = get_uri pages

get_page :: String -> Rest String
get_page p = get_uri (page p)

put_page :: String -> String -> Rest String
put_page p c = put_uri (page p) c

--------------
-- Comments
--------------
get_page_comments :: String -> Rest String
get_page_comments = get_uri.page_comments

post_page_comments :: String -> String -> Rest String
post_page_comments p c = post_uri (page_comments p) c

--------------
-- Tags
--------------
get_page_tags :: String -> Rest String
get_page_tags = get_uri.page_tags

post_page_tags :: String -> String -> Rest String
post_page_tags p t = post_uri (page_tags p) t

get_page_tag :: String -> String -> Rest String
get_page_tag p = get_uri.(page_tag p)

put_page_tag :: String -> String -> Rest String
put_page_tag p t = put_uri (page_tag p t) ""

----------------
-- Attachments
----------------
get_page_attachments :: String -> Rest String
get_page_attachments = get_uri.page_attachments

get_page_attachment :: String -> String -> Rest String
get_page_attachment p = get_uri.(page_attachment p)
