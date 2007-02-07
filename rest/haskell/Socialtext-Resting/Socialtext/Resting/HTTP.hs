module Socialtext.Resting.HTTP where

import Network.URI
import Network.HTTP hiding (password)
import Codec.Base64 (encode)
import System (exitFailure)
import Socialtext.Resting.Types
import Socialtext.Resting.Templates (joinPathM)

get_uri :: Rest String -> Rest String
get_uri u = do
    uri <- make_uri u
    headers <- default_headers
    response <- io $ send_request (Request uri GET headers "")
    return (rspBody response)

post_uri :: Rest String -> String -> Rest String
post_uri = request_with_content POST

put_uri :: Rest String -> String -> Rest String
put_uri = request_with_content PUT

request_with_content :: RequestMethod -> Rest String -> String -> Rest String
request_with_content m u c = do
    uri <- make_uri u
    headers <- make_headers_for_content c
    response <- io $ send_request (Request uri m headers c)
    return (rspBody response)

make_uri :: Rest String -> Rest URI
make_uri path = do
    ai <- asks auth_info
    s <- return (base_uri ai)
    p <- path
    uri <- return $ if (last s) == '/' then s ++ p else s ++ "/" ++ p
    parse_uri uri
        
parse_uri :: String -> Rest URI
parse_uri uri =
    case (parseURI uri) of 
        Nothing -> error "Could not parse URI"
        Just x -> return x

default_headers :: Rest [Header]
default_headers = sequence [auth_hdr, accept_hdr]

make_headers_for_content :: String -> Rest [Header]
make_headers_for_content c = do
    headers <- default_headers
    ct <- asks content_type
    ctype <- return $ Header HdrContentType ct
    clen <- return $ Header HdrContentLength (show (length c))
    return $ headers ++ [ctype, clen]

auth_hdr :: Rest Header
auth_hdr = do
    ai <- asks auth_info
    user <- return $ (username ai)
    pass <- return $ (password ai)
    return $ Header HdrAuthorization ("basic " ++ encode(user ++ ":" ++ pass))

accept_hdr :: Rest Header
accept_hdr = do
    mime <- asks accept
    return $ Header HdrAccept mime

send_request :: Request -> IO Response
send_request req = do
    either_response <- simpleHTTP req
    case (either_response) of
        (Left err) -> putStrLn (show err) >> exitFailure
        (Right response) -> return response
