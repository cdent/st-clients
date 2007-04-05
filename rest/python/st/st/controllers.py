from turbogears import controllers, expose
# from model import *
from turbogears import identity, redirect
from cherrypy import request, response
# from st import json
# import logging
# log = logging.getLogger("st.controllers")
from st.model import Page, Pages, Changes, Tags, TaggedPages

class Root(controllers.RootController):

    @expose()
    def index(self):
# replace this with a get_homepage method that doesn't
# yet exist on socialtext.rest.RESTClient
        raise redirect("page/Admin Wiki")

    @expose(template="st.templates.welcome")
    # @identity.require(identity.in_group("admin"))
    # If pagename is not set get the homepage
    def page(self, pagename):
        page = Page(pagename, 'text/html')
        return dict(page=page.GET())

    @expose(template="st.templates.pagelist")
    # @identity.require(identity.in_group("admin"))
    def all(self):
        pages = Pages('application/json')
        pages = pages.GET()
        return dict(title='All Pages', pages=pages, page=None)

    @expose(template="st.templates.pagelist")
    # @identity.require(identity.in_group("admin"))
    def changes(self):
        pages = Changes('application/json')
        pages = pages.GET()
        return dict(title='Recent Changes', pages=pages, page=None)

    @expose(template="st.templates.pagelist")
    # @identity.require(identity.in_group("admin"))
    def tagged(self, tag=""):
        if (tag):
            pages = TaggedPages('application/json')
            pages = pages.GET(tag)
            return dict(title='Tagged Pages', pages=pages, page=None)
        else:
            raise redirect("tags")

    @expose(template="st.templates.taglist")
    def tags(self):
        tags = Tags('application/json')
        tags = tags.GET()
        return dict(title='Tags', tags=tags, page=None)

    @expose(template="st.templates.edit")
    #@identity.require(identity.in_group("admin"))
    def edit(self, pagename):
        page = Page(pagename, 'text/x.socialtext-wiki')
        page.GET() # presumably this should be auto, but let's play
        return dict(page=page)

    @expose()
    def save(self, pagename, content, submit):
        page = Page(pagename, 'text/x.socialtext-wiki')
        try:
            page.PUT(content)
        except ValueError:
            pass  # XXX: httlib bug?  Seems to die even when PUT is successful.
        raise redirect("page/%s" % pagename)

    @expose(template="st.templates.login")
    def login(self, forward_url=None, previous_url=None, *args, **kw):

        if not identity.current.anonymous \
            and identity.was_login_attempted() \
            and not identity.get_identity_errors():
            raise redirect(forward_url)

        forward_url=None
        previous_url= request.path

        if identity.was_login_attempted():
            msg=_("The credentials you supplied were not correct or "
                   "did not grant access to this resource.")
        elif identity.get_identity_errors():
            msg=_("You must provide your credentials before accessing "
                   "this resource.")
        else:
            msg=_("Please log in.")
            forward_url= request.headers.get("Referer", "/")
            
        response.status=403
        return dict(message=msg, previous_url=previous_url, logging_in=True,
                    original_parameters=request.params,
                    forward_url=forward_url)

    @expose()
    def logout(self):
        identity.current.logout()
        raise redirect("/")
