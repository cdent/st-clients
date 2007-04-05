from datetime import datetime
from turbogears.database import PackageHub
from sqlobject import *
from turbogears import identity 
#from st import json
import simplejson

from socialtext.rest.simple_client import RESTClient

hub = PackageHub("st")
__connection__ = hub

# class YourDataClass(SQLObject):
#     pass

# identity models.
class Visit(SQLObject):
    class sqlmeta:
        table = "visit"

    visit_key = StringCol(length=40, alternateID=True,
                          alternateMethodName="by_visit_key")
    created = DateTimeCol(default=datetime.now)
    expiry = DateTimeCol()

    def lookup_visit(cls, visit_key):
        try:
            return cls.by_visit_key(visit_key)
        except SQLObjectNotFound:
            return None
    lookup_visit = classmethod(lookup_visit)

class VisitIdentity(SQLObject):
    visit_key = StringCol(length=40, alternateID=True,
                          alternateMethodName="by_visit_key")
    user_id = IntCol()


class Group(SQLObject):
    """
    An ultra-simple group definition.
    """

    # names like "Group", "Order" and "User" are reserved words in SQL
    # so we set the name to something safe for SQL
    class sqlmeta:
        table = "tg_group"

    group_name = UnicodeCol(length=16, alternateID=True,
                            alternateMethodName="by_group_name")
    display_name = UnicodeCol(length=255)
    created = DateTimeCol(default=datetime.now)

    # collection of all users belonging to this group
    users = RelatedJoin("User", intermediateTable="user_group",
                        joinColumn="group_id", otherColumn="user_id")

    # collection of all permissions for this group
    permissions = RelatedJoin("Permission", joinColumn="group_id", 
                              intermediateTable="group_permission",
                              otherColumn="permission_id")


class User(SQLObject):
    """
    Reasonably basic User definition. Probably would want additional attributes.
    """
    # names like "Group", "Order" and "User" are reserved words in SQL
    # so we set the name to something safe for SQL
    class sqlmeta:
        table = "tg_user"

    user_name = UnicodeCol(length=16, alternateID=True,
                           alternateMethodName="by_user_name")
    email_address = UnicodeCol(length=255, alternateID=True,
                               alternateMethodName="by_email_address")
    display_name = UnicodeCol(length=255)
    password = UnicodeCol(length=40)
    created = DateTimeCol(default=datetime.now)

    # groups this user belongs to
    groups = RelatedJoin("Group", intermediateTable="user_group",
                         joinColumn="user_id", otherColumn="group_id")

    def _get_permissions(self):
        perms = set()
        for g in self.groups:
            perms = perms | set(g.permissions)
        return perms

    def _set_password(self, cleartext_password):
        "Runs cleartext_password through the hash algorithm before saving."
        password_hash = identity.encrypt_password(cleartext_password)
        self._SO_set_password(password_hash)

    def set_password_raw(self, password):
        "Saves the password as-is to the database."
        self._SO_set_password(password)



class Permission(SQLObject):
    permission_name = UnicodeCol(length=16, alternateID=True,
                                 alternateMethodName="by_permission_name")
    description = UnicodeCol(length=255)

    groups = RelatedJoin("Group",
                        intermediateTable="group_permission",
                         joinColumn="permission_id", 
                         otherColumn="group_id")


# this stuff should come from somewhere else
server = 'http://localhost:21002'
username = 'devnull1@socialtext.com'
password = 'd3vnu11l'
workspace = 'admin'

# parent
class RestModel:
    pass

class Entity(RestModel):
    def __init__(self, name, type="text/x.socialtext-wiki"):
        self.name = name
        self.type = type
        client = RESTClient(server, username, password)
        client.workspace = workspace
        client.accept = self.type
        self.client = client

class Page(Entity):
    def GET(self):
        self.content = self.client.get_page(self.name)
        return self

    def PUT(self, content):
        self.client.put_page(self.name, content)


class Collection(RestModel):
    def __init__(self, type="application/json"):
        self.type = type
        self.client = RESTClient(server, username, password)
        self.client.workspace = workspace
        self.client.accept = self.type

class Tags(Collection):
    def GET(self):
        self.client.order = 'alpha'
        self.content = self.client.get_workspace_tags()
        return simplejson.loads(self.content)
    
class Pages(Collection):
    def GET(self):
        self.content = self.client.get_pages()
        return simplejson.loads(self.content)

class Changes(Pages):
    def GET(self):
        self.client.count = 5
        self.client.order = 'newest'
        return Pages.GET(self)

class TaggedPages(Pages):
    def GET(self, tag):
        self.client.order = 'alpha'
        self.content = self.client.get_taggedpages(tag)
        return simplejson.loads(self.content)
