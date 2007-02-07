module Socialtext.Resting.Control where

import Socialtext.Resting.Types

-----------------------
-- Control Structures
-----------------------
rest :: RestAuth -> Rest a -> IO a
rest auth action = runReaderT action (rest_state {auth_info=auth})

local' rs action = local (const rs) action

with_workspace :: String -> Rest a -> Rest a
with_workspace x action = ask >>= \rs -> local' (rs {workspace=x}) action

with_accept :: String -> Rest a -> Rest a
with_accept x action = ask >>= \rs -> local' (rs {accept=x}) action

with_content_type :: String -> Rest a -> Rest a
with_content_type x action = ask >>= \rs -> local' (rs {content_type=x}) action

with_mime_type :: String -> Rest a -> Rest a
with_mime_type mime action = with_accept mime (with_content_type mime action)

--------------------------------
-- Binary Versions of Controls
--------------------------------
withAuth :: Rest a -> RestAuth -> IO a
withAuth = flip rest

inWorkspace :: Rest a -> String -> Rest a
inWorkspace = flip with_workspace

accepting :: Rest a -> String -> Rest a
accepting = flip with_accept

representedAs :: Rest a -> String -> Rest a
representedAs = flip with_content_type

as :: Rest a -> String -> Rest a
as = flip with_mime_type
