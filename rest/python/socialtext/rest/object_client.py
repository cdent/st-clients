import base64
import urllib
import urllib2
import httplib
import simplejson as json


from common import routes

class Server:

    def __init__(self, server, username, password):
        """ Create a new Server instance that will be the base for querying a
            Socialtext instance.
        """
        scheme, server, port = urllib2.urlparse.urlparse(server)[:3]
        connector = (((scheme == 'http') and 
                      httplib.HTTPConnection) or
                     httplib.HTTPSConnection)
        port = port and int(port) or None

        self.connection = connector(server, port)
        self.creds = {'Authorization': "Basic %s" % base64.encodestring('%s:%s' % (username, password))[:-1]}
        self.workspaces = WorkspaceCollection(self)
        self.users = UserCollection(self)

    def request(self, method, uri, accept='text/plain', type=None, content=None):
        headers = self.creds.copy()
        if type:
            headers.update({'Content-type': type})
        if accept:
            headers.update({'Accept': accept})

        self.connection.request(method, uri, content, headers)
        response = self.connection.getresponse()
        return response.status, response.read(), response

class UserCollection:

    def __init__(self, server):
        pass

class WorkspaceCollection:

    def __init__(self, server):
        self.server = server
        self.workspace_map = {}
        for ws_name in self._fetch_workspaces_list():
            self.workspace_map[ws_name] = Workspace(server=server, name=ws_name)

    def _fetch_workspaces_list(self):
        status,content,resp= self.server.request('GET', routes['workspaces'])
        return content.split("\n")

    def __getitem__(self, workspace_name):
        return self.workspace_map[workspace_name]

class Workspace:

    def __init__(self, server=None, title=None, name=None):
        self.server = server
        self.name = name
        self._title = title

        if server and name:
            uri = self._make_uri('workspace', {'ws': name})
            app_json = 'application/json'
            status,content,resp = self.server.request('GET', uri, accept=app_json)
            ws = json.loads(content)
            self._title = ws['title']


    def _make_uri(self, thing, replacements):
        uri = routes[thing]
        return urllib.quote(uri % replacements)

    @property
    def title(self):
        if self._title:
            return self._title
        elif self.ws:
            return self.ws['title']

class Page:
    pass

class Tag:
    pass


