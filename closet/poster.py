"""
Accept a POSTed byte stream and store it.

The poster generates a uuid and then uses that uuid
to PUT data to the putter. The putter returns a uri
which the poster returns to the client.
"""

import selector
import sys
import httplib2
import closet
from uuid import uuid4

def poster(environ, start_response):
    """accept input stream from POST request and send it to the putter"""
    input = environ['wsgi.input']
    length = environ['CONTENT_LENGTH']

    # mom wants exception handling here!
    uri = _put(input, int(length), uuid4().hex)

    start_response("201 Created", [('Location', uri)])

    return [uri]

def _put(input, length, uuid):
    h = httplib2.Http()
# JJP notes we badly need an explicit timeout and handling 
# structure here, or get ourselves in heap big trouble
    response, content = h.request(closet.putter_server + uuid, 'PUT', input.read(length))

    assert response.status == 204

    return response['location']

port = closet.poster_port
urls = selector.Selector()
urls.add('/', POST=poster)
