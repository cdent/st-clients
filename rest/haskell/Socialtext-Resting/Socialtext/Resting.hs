module Socialtext.Resting (
    module Socialtext.Resting.Control,
    module Socialtext.Resting.MimeTypes,
    module Socialtext.Resting.Page,
    module Socialtext.Resting.Types,
    module Socialtext.Resting.User,
    module Socialtext.Resting.Workspace,
    test, testM, check
) where

import Socialtext.Resting.Control
import Socialtext.Resting.MimeTypes
import Socialtext.Resting.Page
import Socialtext.Resting.Types
import Socialtext.Resting.User
import Socialtext.Resting.Workspace

with_dev_env x = rest (dev_env 21022) x

test :: Rest String -> IO ()
test x = with_dev_env x >>= putStrLn

testM :: Show a => Rest a -> IO ()
testM x = with_dev_env x >>= print

check :: IO ()
check = test $ get_page "Admin Wiki" `as` json `inWorkspace` "admin"
