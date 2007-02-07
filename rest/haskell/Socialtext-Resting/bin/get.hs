import Socialtext.Resting
import Socialtext.Resting.Settings

settings :: [SettingDescr]
settings = [
        Switch 's' "server" "URI" Required "The base URI for requests",
        Switch 'u' "username" "USER" Required "Username for API access",
        Switch 'p' "password" "PASS" Required "Password for API access",
        Switch 'w' "workspace" "WS" Required "Workspace for requests",
        Switch 'a' "accept" "MIME" (Optional wikitext) "Accept header",
        BareOpt "page" Required 
    ]

make_auth :: Settings -> IO RestAuth
make_auth s = return $
    rest_auth {
        base_uri = lookup_setting' s "server",
        username = lookup_setting' s "username",
        password = lookup_setting' s "password"
    }

main :: IO ()
main = do
    s <- load_settings settings
    auth <- make_auth s
    ws <- return $ lookup_setting' s "workspace"
    mime <- return $ lookup_setting' s "accept"
    page <- return $ lookup_setting' s "page"
    text <- get_page page `inWorkspace` ws `accepting` mime `withAuth` auth
    putStrLn text
