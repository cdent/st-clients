"""
Roundtrip test the poster, putter and getter.

Better would be some real unit tests, but this
is just a harness to manage the spike development.
"""

import closet.manage as manage
import os
import time
import httplib2
import atexit

poster_server = 'http://0.0.0.0:8000/'
pids = {}

def startup():
    """Start each of the servers by forking them."""
    for server in ['putter', 'poster', 'getter']:
        pid = os.fork()
        if pid == 0:

            manage.run(server)
        else:
            print "starting " + server + " at " + str(pid)
            pids[server] = pid

    # sleep a bit to get things rolling
    time.sleep(3)

def test_basic():
    """Send content to poster, the GET the learned URI"""
    h = httplib2.Http()

    sent_content = "hello\n"

    print "going to post hello with auth"
    response, content = h.request(poster_server, 'POST', body=sent_content, headers={'X-Closet-Cookie': 'holdem'})
    print content
    assert response['status'] == '201'
    assert 'http' in content
    assert '8002' in content
    
    print "going to get hello from " + response['location']
    response, content = h.request(response['location'], 'GET')
    print content
    assert content == sent_content

    print "going to post hello without auth"
    response, content = h.request(poster_server, 'POST', body=sent_content)
    print content
    assert response['status'] == '403'
    assert 'Denied' in content

def test_cache():
    """Use a cache, with etags, does it go?"""
    h = httplib2.Http('.cache')

    sent_content = "i can haz cash?\n"
    response, content1 = h.request(poster_server, 'POST', body=sent_content, headers={'X-Closet-Cookie': 'holdem'})
    print response
    uri = response['location']

    response, content2 = h.request(uri, 'GET')

    etag = response.get('etag')

    print etag

# here we watch the test output and cackle with glee as no requests are made
# to the server
    response, content3 = h.request(uri, 'GET')
    print content3
    assert content2 == content3

    response, content4 = h.request(uri, 'GET')
    print content4

    assert content3 == content4

# and now we wait
    time.sleep(15)
    response, content5 = h.request(uri, 'GET')
    print content5
    assert content4 == content5


def teardown():
    """Make sure the servers are killed off when done."""
    for server in pids:
        print "killing " + server + " at " + str(pids[server])
        os.kill(pids[server], 15)

if __name__ == '__main__':
    atexit.register(teardown)
    startup()
    test_basic()
    test_cache()
