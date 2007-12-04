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

@closet.write_access(closet.config['public_auth_cookie'])
def poster(environ, start_response):
    """accept input stream from POST request and send it to the putter"""
    input = environ['wsgi.input']
    length = environ['CONTENT_LENGTH']

    # mom wants exception handling here!
    response = _put(input, int(length), uuid4().hex)

    status = response['status']
    if status == '204':
        uri = response['location']
        start_response("201 Created", [('Location', uri)])
        return [uri]
    else:
        start_response("502 Proxy Error", [])
        return [status]

def _put(input, length, uuid):
    h = httplib2.Http()
# JJP notes we badly need an explicit timeout and handling 
# structure here, or get ourselves in heap big trouble
    putter_server = '%s:%s/' % (closet.config['host_url'], closet.config['putter']['port'])
    response, content = h.request(putter_server + uuid, 'PUT', body=input.read(length), headers={'X-Closet-Cookie': closet.config['private_auth_cookie']})

    return response

port = closet.config['poster']['port']
urls = selector.Selector()
urls.add('/', POST=poster)
