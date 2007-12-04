
"""Configuration for closet, a generic web store for content 
objects."""

def get_config(config_filename):
    import yaml
    print "getting config#################"
    f = open(config_filename)
    return yaml.load(f)

def write_access(auth_cookie):
    """
Decorate a wsgi action method with some auth handling.
"""
    def entangle(f):
        def write_access(environ, start_response, *args, **kwds):
            if _write_access(auth_cookie, environ):
                return f(environ, start_response)
            else:
                return _http_403(environ, start_response)
        return write_access
    return entangle

def _write_access(auth_cookie, environ):
    """
Look in the headers to see if we've got proper creds
"""
    try:
        cookie = environ['HTTP_X_CLOSET_COOKIE']
    except KeyError:
        cookie = ''
    if cookie == auth_cookie:
        return 1
    return 0

def _http_403(environ, start_response):
    start_response("403 Forbidden", ([]))
    return ['Access Denied']

config_file = './closet.yaml'
config = get_config(config_file)

