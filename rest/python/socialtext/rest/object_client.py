import base64
import urllib
import urllib2
import httplib
import simplejson
import re

from common import routes


GET = 'GET'
PUT = 'PUT'
POST = 'POST'
DELETE = 'DELETE'

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

        self.connection = connector(server)
        self.creds = {'Authorization': "Basic %s" % base64.encodestring('%s:%s' % (username, password))[:-1]}
        self.workspaces = WorkspaceCollection(self.request)
        self.users = UserCollection(self.request)

    def request(self, method, uri, accept='text/plain', type=None, content=None):
        self.connection.close() # close any previous connection
        headers = self.creds.copy()
        if type:
            headers.update({'Content-type': type})
        if accept:
            headers.update({'Accept': accept})

        self.connection.connect()
        self.connection.request(method, uri, content, headers)
        response = self.connection.getresponse()
        return response.status, response.read(), response

    def __repr__(self):
        return '<Client %s as %s>' % (self.server, self.username)


class UserCollection:

    def __init__(self, server):
        pass


class WorkspaceCollection:

    def __init__(self, request):
        self.request = request
        self.workspace_map = {}
        for ws_dict in self._fetch_workspaces_list():
            ws_name = ws_dict[u'name']
            self.workspace_map[ws_name] = Workspace(request=request,
                                                    name=ws_name)

    def _fetch_workspaces_list(self):
        status, content, response = self.request(
            GET, routes['workspaces'], accept='application/json')
        return simplejson.loads(content)

    # mapping protocol

    def __getitem__(self, workspace_name):
        return self.workspace_map[workspace_name]

    def __setitem__(self, workspace_name, workspace):
        raise NotImplementedError("Not yet")

    def __delitem__(self, workspace_name):
        raise NotImplementedError("Not yet")

    def __len__(self):
        return len(self.workspace_map)

    def keys(self):
        return self.workspace_map.keys()

    def values(self):
        return self.workspace_map.values()


class Workspace:

    def __init__(self, request=None, title=None, name=None):
        self.request = request
        self.name = name
        self.title = title
        self.pages = PageCollection(self)

        if request and name:
            uri = make_uri('workspace', {'ws': name})
            status, content, response = self.request(
                GET, uri, accept='application/json')
            ws = simplejson.loads(content)
            self.title = ws['title']

    def __repr__(self):
        return '<Workspace %s>' % self.title


class PageCollection:

    def __init__(self, workspace):
        self.workspace = workspace
        self.request = workspace.request
        self.page_map = {}
        for page_dict in self._fetch_pages_list():
            page_uri = page_dict[u'uri']
            self.page_map[page_uri] = Page(request=self.request,
                                           workspace_name=workspace.name,
                                           page_uri=page_uri)

    def _fetch_pages_list(self):
        uri = make_uri('pages', dict(ws=self.workspace.name))
        status, content, response = self.request(
            GET, uri, accept='application/json')
        return simplejson.loads(content)

    # mapping protocol

    def __getitem__(self, page_name):
        return self.page_map[name_to_id(page_name)]

    def __setitem__(self, page_name, page):
        raise NotImplementedError("Not yet")

    def __delitem__(self, page_name):
        raise NotImplementedError("Not yet")

    def __len__(self):
        return len(self.page_map)

    def keys(self):
        return self.page_map.keys()

    def values(self):
        return self.page_map.values()


class Page:

    def __init__(self, request=None, name=None, page_uri=None, workspace_name=None):
        self.request = request
        self.page_uri = page_uri
        self.workspace_name = workspace_name
        self.name = name

        if request and page_uri:
            uri = make_uri('page', {'ws': self.workspace_name, 'pname': page_uri})
            status, content, response = self.request(
                GET, uri, accept='application/json')
            try:
                page = simplejson.loads(content)
            except ValueError:
                import pdb;pdb.set_trace()
            self.name = page['name']

    def __repr__(self):
        return '<Page %s>' % self.name


class Tag:
    pass


