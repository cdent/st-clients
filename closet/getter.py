"""
GET a blob from the content store
"""

import selector
import closet

def getter(environ, start_response):
    """GET request with UUID and return output"""
    uuid = environ['selector.vars']['uuid']

    f = _read(uuid)

    #start_response("200 OK", [('Content-type', 'application/binary')])
    start_response("200 OK", [])

    return f

def _read(uuid):
    """Read a file from the store given uuid"""
    f = open(closet.file_store + uuid, 'rb')
    return f

port = closet.getter_port
urls = selector.Selector()
urls.add('/{uuid}', GET=getter)
