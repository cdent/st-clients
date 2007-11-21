"""
Accept a PUT byte stream and uuid and write content to disk.
"""

import selector
import closet

@closet.write_access(closet.private_auth_cookie)
def putter(environ, start_response):
    """accept input stream from PUT request and write it at the given uuid"""
    uuid = environ['selector.vars']['uuid'] # wsgi.routing_args coming soon?
    input = environ['wsgi.input']
    length = environ['CONTENT_LENGTH']

    _write(input, int(length), uuid)
    uri = _uri(uuid)

    start_response("204 Updated", [('Location', uri)])

    return [uri]

def _write(input, length, uuid):
    f = open(closet.file_store + uuid, 'wb')
    f.write(input.read(length))
    f.close

def _uri(uuid):
    return closet.getter_server + uuid

port = closet.putter_port
urls = selector.Selector()
urls.add('/{uuid}', PUT=putter)
