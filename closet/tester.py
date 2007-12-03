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

def test():
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

def teardown():
    """Make sure the servers are killed off when done."""
    for server in pids:
        print "killing " + server + " at " + str(pids[server])
        os.kill(pids[server], 15)

if __name__ == '__main__':
    atexit.register(teardown)
    startup()
    test()
