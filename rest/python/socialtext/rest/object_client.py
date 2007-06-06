import base64
import urllib
import urllib2
import httplib
import simplejson
import re
import functools

from common import routes


def make_uri(thing, replacements):
    uri = routes[thing]
    return urllib.quote(uri % replacements)

def name_to_id(page_name):
    id = page_name or ''
    id, num = re.compile("[^\w0-9_-]+", re.U).subn('_', id)
    id, num = re.compile("_+").subn('_', id)
    id = re.compile("^_(?=.)").sub('', id)
    id = re.compile("(?<=.)_$").sub('', id)
    id = re.compile("^0$").sub('_', id)
    return id.lower()


class WikiError(Exception):
    pass


class Requester:

    def __init__(self, connector, server, username, password):
        self.connection = connector(server)
        self.creds = {'Authorization': "Basic %s" % base64.encodestring('%s:%s' % (username, password))[:-1]}
        self.GET = functools.partial(self.request, 'GET')
        self.PUT = functools.partial(self.request, 'PUT')
        self.POST = functools.partial(self.request, 'POST')
        self.DELETE = functools.partial(self.request, 'DELETE')

    def request(self, method, uri, accept='text/plain', content_type=None, content=None):
        self.connection.close() # close any previous connection
        headers = self.creds.copy()
        if content_type:
            headers.update({'Content-type': content_type})
        if accept:
            headers.update({'Accept': accept})

        self.connection.connect()
        self.connection.request(method, uri, content, headers)
        response = self.connection.getresponse()
        return response.status, response.read(), response


class Client:

    def __init__(self, server, username, password):
        """ Create a new Client instance that will be the base for querying a
            Socialtext application.
        """
        scheme, server = urllib2.urlparse.urlparse(server)[:2]
        connector = (((scheme == 'http') and
                      httplib.HTTPConnection) or
                     httplib.HTTPSConnection)

        self.server = server
        self.username = username

        self.requester = Requester(connector, server, username, password)
        self.workspaces = WorkspaceCollection(self.requester)
        self.users = UserCollection(self.requester)

    def __repr__(self):
        return '<Client %s as %s>' % (self.server, self.username)


class UserCollection:

    def __init__(self, requester):
        pass


class WorkspaceCollection:

    def __init__(self, requester):
        self.requester = requester
        self.workspace_map = {}
        self.populate_workspace_keys()

    def populate_workspace_keys(self):
        status, content, response = self.requester.GET(
            routes['workspaces'], accept='application/json')
        for ws_dict in simplejson.loads(content):
            self.workspace_map[ws_dict[u'name']] = None

    # mapping protocol

    def __getitem__(self, workspace_name):
        try:
            ws = self.workspace_map[workspace_name]
            if ws is None:
                ws = self.workspace_map[workspace_name] = Workspace(requester=self.requester,
                                                                    name=workspace_name)
            return ws
        except KeyError:
            raise

    def __setitem__(self, workspace_name, workspace):
        raise NotImplementedError("Not yet")

    def __delitem__(self, workspace_name):
        raise NotImplementedError("Not yet")

    def __len__(self):
        return len(self.workspace_map)

    def keys(self):
        return self.workspace_map.keys()

    def values(self):
        # this will go through and fully instantiate each workspace
        return [self[x] for x in self.keys()]


class Workspace:

    def __init__(self, requester=None, title=None, name=None):
        self.requester = requester
        self.name = name
        self.title = title
        self.pages = PageCollection(self)

        if requester and name:
            uri = make_uri('workspace', {'ws': name})
            status, content, response = self.requester.GET(
                uri, accept='application/json')
            ws = simplejson.loads(content)
            self.title = ws['title']

    def __repr__(self):
        return '<Workspace %s>' % self.title


class PageCollection:

    def __init__(self, workspace):
        self.workspace = workspace
        self.requester = workspace.requester
        self.page_map = {}
        self.populate_page_keys()

    def populate_page_keys(self):
        uri = make_uri('pages', dict(ws=self.workspace.name))
        status, content, response = self.requester.GET(
            uri, accept='application/json')
        for page_dict in simplejson.loads(content):
            self.page_map[page_dict[u'uri']] = None

    # mapping protocol

    def __getitem__(self, page_name):
        page_uri = name_to_id(urllib.unquote(page_name))
        try:
            page = self.page_map.get(page_uri)
            if page is None:
                page = self.page_map[page_uri] = Page(requester=self.requester,
                                                      workspace_name=self.workspace.name,
                                                      page_uri=page_uri)
            return page
        except KeyError:
            raise

    def __setitem__(self, page_name, page):
        uri = make_uri('page', dict(ws=self.workspace.name, pname=page_name))
        status, content, response = self.requester.PUT(
            uri, content_type='text/x.socialtext-wiki', content=page)

    def __delitem__(self, page_name):
        uri = make_uri('page', dict(ws=self.workspace.name, pname=page_name))
        status, content, response = self.requester.DELETE(uri)

    def __len__(self):
        return len(self.page_map)

    def keys(self):
        return self.page_map.keys()

    def values(self):
        # this will go through and fully instantiate each page
        return [self[x] for x in self.keys()]


class Page:

    def __init__(self, requester=None, name=None, page_uri=None, workspace_name=None):
        self.requester = requester
        self.page_uri = page_uri
        self.workspace_name = workspace_name
        self.name = name

        if requester and page_uri:
            uri = make_uri('page', {'ws': self.workspace_name, 'pname': page_uri})
            status, content, response = self.requester.GET(
                uri, accept='application/json')
            if status in [404, 500]:
                raise WikiError(content)
            page = simplejson.loads(content)
            self.name = page['name']

    def __repr__(self):
        return '<Page %s>' % self.name


class Tag:
    pass


