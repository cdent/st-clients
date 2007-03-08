import urllib
import urllib2
import httplib
import base64
import re

from common import routes

GET = 'GET'
PUT = 'PUT'
POST = 'POST'
DELETE = 'DELETE'

class ClientError(Exception):

    def __init__(self, status, content):
        self.status = status
        self.content = content

    def __str__(self):
        return 'ClientError: %s: %s' % (self.status, self.content)


class RESTClient:

    accept = 'text/x.socialtext-wiki'
    filter = ''
    query = ''
    order = ''
    count = ''

    def __init__(self, server, username, password):
        self.server = server
        self.username = username
        self.password = password
        self.etag_cache = {}

        # are there reasonable defaults for:
        # - accept - text/plain  application/json
        # - workspace (first of 'workspaces'?)

    # Singular Gets

    def get_page(self, page_name):
        page_name = self._name_to_id(page_name)
        accept = self.accept or 'text/x.socialtext-wiki'

        uri = self._make_uri('page', dict(pname=page_name, ws=self.workspace))
        status, content, response = self._request(uri, GET, accept=accept)

        if status in [200, 404]:
            self.etag_cache[page_name] = response.getheader('etag')
            return content

        raise ClientError(status, content)

    def get_attachment(self, attachment_id):
        uri = self._make_uri('workspaceattachment',
                             dict(attachment_id=attachment_id,
                                  ws=self.workspace))
        status, content, response = self._request(uri, GET)

        if status in [200, 404]:
            return content

        raise ClientError(status, content)

    # Collective Gets

    def get_pages(self):
        return self._get_collection('pages')

    def get_page_attachments(self, page_name):
        return self._get_collection('pageattachments', dict(pname=page_name))

    def get_workspace_tags(self):
        return self._get_collection('workspacetags')

    def get_backlinks(self, page_name):
        page_name = self._name_to_id(page_name)

        return self._get_collection('backlinks', dict(pname=page_name))

    def get_frontlinks(self, page_name, incipients=0):
        page_name = self._name_to_id(page_name)

        replacements = dict(pname=page_name)

        if incipients:
            replacements.update(dict(_query=dict(incipient=1)))

        return self._get_collection('frontlinks', replacements)

    def get_pagetags(self, page_name):
        page_name = self._name_to_id(page_name)

        return self._get_collection('pagetags', dict(pname=page_name))

    def get_taggedpages(self, tag):
        return self._get_collection('taggedpages', dict(tag=tag))

    def get_tag(self, tag):
        accept = self.accept or 'text/html'

        uri = self._make_uri('workspacetag', dict(tag=tag, ws=self.workspace))

        status, content, response = self._request(uri, GET, accept=accept)

        if status in [200, 404]:
            return content

        raise ClientError(status, content)

    def get_breadcrumbs(self):
        return self._get_collection('breadcrumbs')

    def get_workspaces(self):
        return self._get_collection('workspaces')

    # Puts

    def put_page(self, page_name, content):
        page_name = self._name_to_id(page_name)

        uri = self._make_uri('page', dict(pname=page_name, ws=self.workspace))

        type = 'text/x.socialtext-wiki'
        prev_etag = self.etag_cache.get(page_name)

        status, content, response = \
            self._request(uri, PUT, content=content, type=type,
                    if_match=prev_etag)

        if status in [201, 204]:
            return content

        raise ClientError(status, content)

    def put_workspacetag(self, tag):
        uri = self._make_uri('workspacetag', dict(ws=self.workspace, tag=tag))

        status, content, response = self._request(uri, PUT)

        if status in [204, 201]:
            return content

        raise ClientError(status, content)

    def put_pagetag(self, page_name, tag):
        page_name = self._name_to_id(page_name)

        uri = self._make_uri('pagetag', dict(pname=page_name,
            ws=self.workspace, tag=tag))

        status, content, response = self._request(uri, PUT)

        if status in [204, 201]:
            return content

        raise ClientError(status, content)

    # Deletes

    def delete_workspacetag(self, tag):
        uri = self._make_uri('workspacetag', dict(ws=self.workspace, tag=tag))

        status, content, response = self._request(uri, DELETE)

        if status == 204:
            return content

        raise ClientError(status, content)

    def delete_pagetag(self, page_name, tag):
        page_name = self._name_to_id(page_name)

        uri = self._make_uri('pagetag', dict(pname=page_name,
            ws=self.workspace, tag=tag))

        status, content, response = self._request(uri, DELETE)

        if status == 204:
            return content

        raise ClientError(status, content)

    # Posts

    def post_attachment(self, page_name, attachment_id, content, type):
        page_name = self._name_to_id(page_name)

        uri = self._make_uri('pageattachments', dict(pname=page_name,
            ws=self.workspace)) + ("?name=%s" % attachment_id)

        status, content, response = self._request(uri, POST, type=type,
                content=content)

        if status in [204, 201]:
            return content

        raise ClientError(status, content)

    def post_comment(self, page_name, comment):
        page_name = self._name_to_id(page_name)

        uri = self._make_uri('pagecomments', dict(pname=page_name,
            ws=self.workspace))

        status, content, response = self._request(uri, POST,
                type='text/x.socialtext-wiki', content=comment)

        if status != 204:
            raise ClientError(status, content)


    # private helpers

    def _name_to_id(self, page_name):
        id = page_name or ''
        id, num = re.compile("[^\w0-9_-]+", re.U).subn('_', id)
        id, num = re.compile("_+").subn('_', id)
        id = re.compile("^_(?=.)").sub('', id)
        id = re.compile("(?<=.)_$").sub('', id)
        id = re.compile("^0$").sub('_', id)
        return id.lower()

    def _make_uri(self, thing, replacements):
        uri = routes[thing]

        return urllib.quote(uri % replacements)

    def _extend_uri(self, uri):
        return "%s?%s" % (uri, urllib.urlencode(dict(filter=self.filter,
            q=self.query, order=self.order, count=self.count)))

    def _get_collection(self, collection, replacements=None):
        replacements = replacements or {}
        replacements.update(dict(ws=self.workspace))
        accept = self.accept or 'text/plain'

        uri = self._extend_uri(self._make_uri(collection, replacements))

        status, content, response = self._request(uri, GET, accept=accept)

        if status == 200:
            return content

        if status == 404:
            return ''

        raise ClientError(status, content)

    def _request(self, uri, method, accept=None, type=None, content=None,
            if_match=None):
        scheme, server, port = urllib2.urlparse.urlparse(self.server)[:3]
        port = port and int(port) or None

        connector = (scheme == 'http') and httplib.HTTPConnection or httplib.HTTPSConnection

        connection = connector(server, port=port)

        headers = {'Authorization': "Basic %s" % base64.encodestring('%s:%s' %
            (self.username, self.password))[:-1]}
        if type:
            headers.update({'Content-type': type})
        if accept:
            headers.update({'Accept': accept})
        if if_match:
            headers.update({'If-Match': if_match})

        connection.request(method, uri, content, headers)
        response = connection.getresponse()

        return response.status, response.read(), response


client = RESTClient(server='http://www.socialtext.net',
    username='zac.bir@socialtext.com',
    password='wsbwnl')

if __name__ == '__main__':
    client = RESTClient(server='http://www.socialtext.net',
            username='zac.bir@socialtext.com',
            password='wsbwnl')

    client.workspace = 'stoss'
    try:
        print client.get_pages()
    except ClientError, e:
        print e
