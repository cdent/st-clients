base_uri = '/data/workspaces'

routes = dict(
    backlinks            = base_uri + '/%(ws)s/pages/%(pname)s/backlinks',
    breadcrumbs          = base_uri + '/%(ws)s/breadcrumbs',
    frontlinks           = base_uri + '/%(ws)s/pages/%(pname)/frontlinks',
    page                 = base_uri + '/%(ws)s/pages/%(pname)s',
    pages                = base_uri + '/%(ws)s/pages',
    pagetag              = base_uri + '/%(ws)s/pages/%(pname)s/tags/%(tag)s',
    pagetags             = base_uri + '/%(ws)s/pages/%(pname)s/tags',
    pagecomments         = base_uri + '/%(ws)s/pages/%(pname)s/comments',
    pageattachment       = base_uri + '/%(ws)s/pages/%(pname)s/attachments/%(attachment_id)s',
    pageattachments      = base_uri + '/%(ws)s/pages/%(pname)s/attachments',
    taggedpages          = base_uri + '/%(ws)s/tags/%(tag)s/pages',
    workspace            = base_uri + '/%(ws)s',
    workspaces           = base_uri,
    workspacetag         = base_uri + '/%(ws)s/tags/%(tag)s',
    workspacetags        = base_uri + '/%(ws)s/tags',
    workspaceattachment  = base_uri + '/%(ws)s/attachments/%(attachment_id)s',
    workspaceattachments = base_uri + '/%(ws)s/attachments',
    workspaceuser        = base_uri + '/%(ws)s/users/%(user_id)s',
    workspaceusers       = base_uri + '/%(ws)s/users',
    user                 = '/data/users/%(user_id)s',
    users                = '/data/users')

