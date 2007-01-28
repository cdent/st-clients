-- Based on test/get.hs at http://www.haskell.org/http/
-- A simple test program which takes a url on the commandline
-- and outputs the contents to stdout.

-- ghc --make -package HTTP get.hs -o get

import Data.Char (intToDigit)
import Network.HTTP
import Network.URI
import System.Environment (getArgs, getProgName)
import System.Exit (exitFailure)
import System.IO (hPutStrLn, stderr, stdin)

import Codec.Base64 (encode)

main = 
    do
    method <- getProgName
    args <- getArgs
    case args of 
	[user, pass, accept, addr] -> case parseURI addr of
                       Nothing -> err "Could not parse URI"
		       Just uri -> do
				   cont <- act method uri user pass accept
			           putStr cont
	_ -> err $ "Usage: " ++ method ++ " <user> <pass> <accept> <url>"

err :: String -> IO a
err msg = do 
	  hPutStrLn stderr msg
	  exitFailure

act :: String -> URI -> String -> String -> String -> IO String
act methodStr uri user pass accept =
    do
    req <- request uri (method methodStr) user pass accept
    eresp <- simpleHTTP req
    resp <- handleE (err . show) eresp
    case rspCode resp of
                      (2,0,_) -> return (rspBody resp)
                      _ -> err (httpError resp)
    where
    showRspCode (a,b,c) = map intToDigit [a,b,c]
    httpError resp = showRspCode (rspCode resp) ++ " " ++ rspReason resp

-- Generate a request method
method :: String -> RequestMethod
method "get" = GET
method "post" = POST
method "put" = PUT
method "head" = HEAD
method methodStr = GET
-- DELETE is not supported!

-- Generate an accept header
accept :: String -> Header
accept acceptType = Header HdrAccept acceptType

content_length :: String -> Header
content_length c = Header HdrContentLength $ show $ length c

content_type :: String -> Header
content_type = Header HdrContentType

-- Generate an authorization header
auth :: String -> String -> Header
auth user pass = Header HdrAuthorization ("basic " ++ encode(user ++ ":" ++ pass))

request :: URI -> RequestMethod -> String -> String -> String -> IO Request
request uri methodO user pass acceptType = do
        content <- do
            case methodO of
                GET -> return $ ""
                _ -> getContents
        return $ Request { 
            rqURI = uri,
            rqMethod = methodO,
            rqHeaders = [
                accept acceptType,
                auth user pass
            ] ++ (content_headers methodO content),
            rqBody = content
        }

content_headers :: RequestMethod -> String -> [Header]
content_headers method content = 
    case method of
        GET -> []
        _ -> [ content_type "text/x.socialtext-wiki", content_length content ]

handleE :: Monad m => (ConnError -> m a) -> Either ConnError a -> m a
handleE h (Left e) = h e
handleE _ (Right v) = return v

