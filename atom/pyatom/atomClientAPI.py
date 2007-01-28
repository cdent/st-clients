__author__ = "Joe Gregorio <http://bitworking.org/>"
__version__ = "Revision: 1.00"
__copyright__ = "Copyright (c) 2003 Joe Gregorio"
__license__ = """All Rights Reserved"""

import urlparse, httplib, urllib2
import StringIO
import sha, base64
import libxml2


class _authentication:
    def __init__(self, username, password):
        self.username = username
        self.password = password

    def currentISOTime(self):
        import time
        tz = time.timezone/3600
        return time.strftime("%Y-%m-%dT%H:%M:%S-", time.localtime()) + ("%(tz)02d:00" % vars())

    def auth_header(self):
        nonce = '000011112222'
        print self.username
        print self.password
        created = self.currentISOTime()
        digest = base64.encodestring(sha.sha(nonce + created +
            self.password).digest()).strip()
        return 'UsernameToken Username="%s", PasswordDigest="%s", Nonce="%s", Created="%s"' %  (self.username, digest, base64.encodestring(nonce).strip(), created)


class interface:
    def __init__(self):
        """If you don't pass in the FeedURI then we automatically 
            load up the config.xml file out of the local directory and read
            the introspection URI out of there."""
        config = libxml2.parseFile('config.xml')
        self.feedURI = config.xpathEval("//config/feeduri")[0].content
        self.username = config.xpathEval("//config/username")[0].content
        password = config.xpathEval("//config/password")[0].content
        self.authclient = _authentication(self.username, password)


        uriParts = urlparse.urlparse(self.feedURI)
        (response,content) = self.doRequest(uriParts[1], "GET",
                "?".join([uriParts[2], uriParts[4]]), '', {})
        self.servicefeed = libxml2.parseDoc(content)
        ctxt = self.servicefeed.xpathNewContext()
        ctxt.xpathRegisterNs('atom', 'http://www.w3.org/2005/Atom')

        self.postURI = ctxt.xpathEval("//atom:link[@rel='service.post' and @type='application/atom+xml']/@href")[0].content
        self.servicefeed.freeDoc()

    def doRequest(self, server, verb, url, xml, headers):
        conn = httplib.HTTPConnection(server)
        if self.username:
            headers['X-WSSE'] = self.authclient.auth_header()
        
        conn.request(verb, url, xml, headers)
        response = conn.getresponse()
        content = response.read()            
        conn.close()
        return (response, content)
        
    def createEntry(self, xml):
        """Creates an Entry. Returns a tuple of (status code, status text, the location header, the response content)"""
        uriParts = urlparse.urlparse(self.postURI)
        (response, content) =  self.doRequest(uriParts[1], "POST",
                "?".join([uriParts[2], uriParts[4]]), xml, {"Content-type": 'application/atom+xml'})
        return (response.status, response.reason, response.status == 201 and response.getheader('location') or None, content)
    
    def getEntry(self, uri):
        """Retrieves the Atom Entry from the given URI"""
        uriParts = urlparse.urlparse(uri)
        (response, content) =  self.doRequest(uriParts[1], "GET",
                "?".join([uriParts[2], uriParts[4]]), None, {"Accept": 'application/atom+xml'})
        return (response.status, response.reason, content)
      
    def updateEntry(self, xml, uri):
        """Updates an Entry. Returns a tuple of (status code, status text, the response content)"""
        uriParts = urlparse.urlparse(uri)
        (response, content) =  self.doRequest(uriParts[1], "PUT", "?".join([uriParts[2], uriParts[4]]), xml, {"Content-type": 'application/atom+xml'})
        return (response.status, response.reason, content)
    
    def deleteEntry(self, uri):
        uriParts = urlparse.urlparse(uri)
        (response, content) =  self.doRequest(uriParts[1], "DELETE", "?".join([uriParts[2], uriParts[4]]), None, {})
        return (response.status, response.reason, content)
   
    def getEntryList(self):
        # dupe with above
        uriParts = urlparse.urlparse(self.feedURI)
        (response,content) = self.doRequest(uriParts[1], "GET",
                "?".join([uriParts[2], uriParts[4]]), '', {})
        self.servicefeed = libxml2.parseDoc(content)

        ctxt = self.servicefeed.xpathNewContext()
        ctxt.xpathRegisterNs('atom', 'http://www.w3.org/2005/Atom')
        entries = ctxt.xpathEval("//atom:entry")
        ret = []
        for entry in entries:
            ctxt.setContextNode(entry)
            uri = ctxt.xpathEval("atom:link[@rel='service.edit' and @type='application/atom+xml']/@href")[0].content
            title = ctxt.xpathEval("atom:title")[0].content
            ret.append((uri, title))
        return ret         
    
    
