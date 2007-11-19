"""
Startup the closet servers.

Port and url information is found from the servers themselves.
"""
import os, sys

def run(selector):
    """Run the server provided by selector"""

    print selector
    exec "from  " + selector + " import urls, port"

    if os.environ.get("REQUEST_METHOD", ""):
        from wsgiref.handlers import BaseCGIHandler
        BaseCGIHandler(sys.stdin, sys.stdout, sys.stderr, os.environ) \
                .run(urls)
    else:
        from wsgiref.simple_server import WSGIServer, WSGIRequestHandler
        httpd = WSGIServer(('', port), WSGIRequestHandler)
        httpd.set_app(urls)
        print "Serving HTTP on %s port %s ..." % httpd.socket.getsockname()
        httpd.serve_forever()

if __name__ == '__main__':
    if 'run' in sys.argv:
        run(sys.argv[2])
