#!/usr/bin/env python
import sys
import SOAPpy
import time

from optparse import OptionParser

class SocialtextClient:

    def __init__(self, wsdl, *args):
        self.tokens = {}
        self.act_as = None
        self.connect_to_server(wsdl)
        if len(args) > 0:
            self.set_default_auth(*args)

    def connect_to_server(self, wsdl):
        self.wsdl = wsdl
        self.soap = SOAPpy.WSDL.Proxy(wsdl or self.wsdl)

    def set_default_auth(self, user, password, ws, act_as=None):
        self.username = user
        self.password = password
        self.workspace = ws
        self.default_token =  self.get_auth(user, password, ws, act_as)

    def act_as_default(self):
        self.act_as = None

    def act_as_user(self, act_as):
        self.act_as = act_as
        self.tokens[act_as] = self.get_auth(self.username,
                                            self.password,
                                            self.workspace,
                                            act_as)

    def current_token(self):
        if self.act_as:
            return self.tokens[self.act_as]
        else:
            return self.default_token

    def get_auth(self, *args):
        return self.soap.getAuth(*args)

    def heartbeat(self):
        return self.soap.heartBeat()

    def get_page(self, page, format='wikitext'):
        return self.soap.getPage(self.current_token(), page)

    def get_changes(self, num=4, name='recent changes'):
        changes = self.soap.getChanges(self.current_token(), name, num)
        return changes['pageMetadata']

    def get_search(self, query):
        result = self.soap.getSearch(self.current_token(), query)
        return result['pageMetadata']

    def set_page(self, page, content):
        result = self.soap.setPage(self.current_token(), page, content)
        return result

if __name__ == '__main__':
    NEW_PAGE_NAME = u'99\N{CENT SIGN} Snakeburger';
    NEW_PAGE_BODY = (u"At McSOAPie's\N{TRADE MARK SIGN}, "
                     u"you can get a Snakeburger\N{TRADE MARK SIGN} "
                     u"for only 99\N{CENT SIGN}.")

    parser = OptionParser()
    parser.add_option("-W", "--workspace",
            help="The Workspace to address")
    parser.add_option("-w", "--wsdl",
            default="https://www.socialtext.net/static/wsdl/0.9.wsdl",
            help="The URL of the WSDL")
    parser.add_option("-u", "--username",
            help="Username to use the service")
    parser.add_option("-p", "--password",
            help="The password of the username")
    parser.add_option("-o", "--other-user", dest="act_as",
            help="The name of the user to impersonate if the service")
    (options, args) = parser.parse_args()

    # Get command line arguments
    wsdl = options.wsdl
    auth = (options.username, options.password, options.workspace,
            options.act_as)

    # Create a Socialtext Client and do heartbeat
    st = SocialtextClient(wsdl, *auth)

    # Heartbeat
    print "=== HEARTBEAT ==="
    print st.heartbeat()

    print "\n=== MAKE PAGE %s ===" % NEW_PAGE_NAME
    print st.set_page(NEW_PAGE_NAME, NEW_PAGE_BODY)['pageContent']

    # Get page
    print "\n=== GET PAGE admin_wiki ==="
    print st.get_page('admin_wiki')['pageContent']

    # Set page
    print "\n=== SET PAGE admin_wiki ==="
    print st.set_page('admin_wiki', 'this is tensegrity')['pageContent']
    time.sleep(10)  # Give time for page to get indexed

    # Search for the changes we just added
    print "\n=== SEARCH tensegrity ==="
    for result in st.get_search("tensegrity"):
        print "%s - %s - %s" % (result['subject'], result['author'], 
                                result['date'])

    # Recent changes
    print "\n=== RECENT CHANGES ==="
    for change in st.get_changes():
        print "%s - %s - %s" % (change['subject'], change['author'], 
                                change['date'])

    # Set page as someone else
    print "\n=== SET PAGE cows_are_good AS devnull2@socialtext.com ==="
    st.act_as_user('devnull2@socialtext.com')
    print st.set_page('cows_are_good', 'I like cows')['pageContent']

    # Recent changes
    print "\n=== RECENT CHANGES  ==="
    for change in st.get_changes():
        print "%s - %s - %s" % (change['subject'], change['author'], 
                                change['date'])
