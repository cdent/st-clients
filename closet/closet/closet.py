
"""Configuration for closet, a generic web store for content 
objects."""

# where do our servers run
host_url = 'http://0.0.0.0'

# on what ports
poster_port = 8000
putter_port = 8001
getter_port = 8002

# what are their urls
poster_server = host_url + ':' + str(poster_port) + '/'
putter_server = host_url + ':' + str(putter_port) + '/'
getter_server = host_url + ':' + str(getter_port) + '/'

# where are we putting stuff
file_store = 'storage/'

# what cookie must the client provide for write access
public_auth_cookie = 'holdem'
private_auth_cookie = 'storem'

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

