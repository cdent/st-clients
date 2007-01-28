// reserve some namespace
var ST = {};

//
// Inheritance model described at
// http://www.kevlindev.com/tutorials/javascript/inheritance/
//
ST.extend = function(subClass, baseClass) {
    function inheritance() {}
    inheritance.prototype = baseClass.prototype;

    subClass.prototype = new inheritance();
    subClass.prototype.constructor = subClass;
    subClass.baseConstructor = baseClass;
    subClass.superClass = baseClass.prototype;
}

// Base Class
ST.Resource = function() {
}

ST.Resource.prototype.route = function () {
    return '/data';
}

// Incomplete
ST.Resource.prototype._commitRepresentation = function(type, content, callback) {
    if(this.deferred) {
        this.deferred.cancel();
    }

    var req = getXMLHttpRequest();
    req.open("PUT", this.route(), true);
    req.setRequestHeader('Content-Type', type);
    var d = sendXMLHttpRequest(req, content).addCallback(callback);
    this.deferred = d;

    var self = this;
    d.addBoth(function (res) {
        self.deferred = null;
        return res;
    });
    d.addErrback(function (err) {
        if (err instanceof CancelledError) {
            return;
        }
        alert("PUT xhr error: " + err + " status: " + err.req.status + " route: " + self.route());
    });
}

// duped with above
ST.Resource.prototype._requestRepresentation = function(type, callback) {
    if(this.deferred) {
        this.deferred.cancel();
    }

    var req = getXMLHttpRequest();
    req.open("GET", this.route(), true);
    req.setRequestHeader('Accept', type);
    var d = sendXMLHttpRequest(req).addCallback(callback);
    this.deferred = d;

    var self = this;
    d.addBoth(function (res) {
        self.deferred = null;
        return res;
    });
    d.addErrback(function (err) {
        var status = err.req.status;
        if (err instanceof CancelledError) {
            return;
        }
        // FIXME: oh hack hack
        if (self.route().match(/pages\//) && status == '404') {
            callback(err);
            return;
        }
        alert("GET xhr error: " + err + " status: " + status + " route: " + self.route());
    });
}

ST.Resource.prototype.toString = function() {
    return "[Resource] at " + this.route();
}
// END Resource

// Superclass of anything that needs a workspace to work
ST.WorkspaceResource = function(workspace) {
    ST.WorkspaceResource.baseConstructor.call(this);
    this.workspace = workspace;
}

ST.extend(ST.WorkspaceResource, ST.Resource);

ST.WorkspaceResource.prototype.route = function() {
    return ST.WorkspaceResource.superClass.route.call(this) + '/workspaces/' + this.workspace;
}
// END WorkspaceResource

// Entity Superclass
ST.Entity = function(workspace) {
    ST.Entity.baseConstructor.call(this, workspace);
}
ST.extend(ST.Entity, ST.WorkspaceResource);
// END Entity

// Collection Superclass
ST.Collection = function(workspace) {
    ST.Entity.baseConstructor.call(this, workspace);
}
ST.extend(ST.Collection, ST.WorkspaceResource);

// Get the results list into an items array
ST.Collection.prototype.getList = function(params) {
    var self = this;
    var callback = function(response) {
        self.items = eval(response.responseText);
        params.callback(response);
    };
    this._requestRepresentation('application/json', callback);
}
// END Collection

// Page Class
ST.Page = function(workspace, pageName) {
    ST.Page.baseConstructor.call(this, workspace);
    this.pageName = pageName;
}
ST.extend(ST.Page, ST.Entity);

ST.Page.prototype.route = function() {
    return ST.Page.superClass.route.call(this) + '/pages/' +
        encodeURIComponent(this.pageName);
}

// Here be confusion over when to asynch and how to handle it.
// It would be nice to set this.content at some point in the
// game, automagically
ST.Page.prototype.getContent = function(params) {
    var self = this;
    // prepend sticking the content somewhere useful
    // onto the function
    var callback = function(response) {
        self.content = response.responseText;
        params.callback(response);
    }
    this._requestRepresentation(params.type, callback); 
}
// END Page

// EditablePage Class
ST.EditablePage = function(workspace, pageName, div) {
    ST.EditablePage.baseConstructor.call(this, workspace, pageName);
    this.div = document.getElementById(div); 
}
ST.extend(ST.EditablePage, ST.Page);

ST.EditablePage.prototype.display = function() {
    var self = this;
    this.getContent({
        type: 'text/html',
        callback: function(response) {
            self._updateViewDiv();
            connect(self.div, 'ondblclick', function(e) { self.edit()});
        }
    });
}

ST.EditablePage.prototype._updateViewDiv = function() {
    var innerDiv = DIV({id: this.div.getAttribute('id')});
    window.location.hash =
        encodeURIComponent(this.workspace + '/' + this.pageName);
    innerDiv.innerHTML = '<h1>' + this.pageName + '</h1>' + this.content;
    swapDOM(this.div, innerDiv);
    this.activateLinks(innerDiv);
    this.div = innerDiv;
}

ST.EditablePage.prototype.activateLinks = function(contentDiv) {
    var links = contentDiv.getElementsByTagName('a');
    var self = this;
    for (var i = 0; i < links.length; i++) {
        var link = links[i];
        var href = link.getAttribute('href');
        if (href) {
            // FIXME: this isn't good for other sorts of links!!!!
            if (href.match('^[^#/]+$') && !href.match('mailto') ){
                this._setLink(link);
            }
            else {
                var matches =
                    href.match('^/data/workspaces/([^/]+)/pages/[^/]+$');
                if (matches && matches[1]) {
                    this._setLink(link, matches[1]);
                }
            }

        }
    }
}

ST.EditablePage.prototype._setLink = function(link, workspace) {
    var targetWorkspace = workspace ? workspace : this.workspace;
    var href= encodeURIComponent(targetWorkspace + '/' + link.innerHTML);
    link.setAttribute('href', '#' + href);
    connect(link, 'onclick', function(e) {
        window.location.hash = href;
        window.location.reload();
        //e.stop();
    }); 
}

ST.EditablePage.prototype.edit = function() {
    var self = this;
    this.getContent({
        type: 'text/x.socialtext-wiki',
        callback: function(response) {
            self._updateEditDiv();
            connect(document.forms.editor, 'onsubmit', function(e) {
                document.forms.editor.elements['Edit'].value = 'Sending';
                self._commitText(document.forms.editor.elements['wikitext'].value);
                // consume the event
                e.stop();
            });
        }
    });
}

ST.EditablePage.prototype._commitText = function(content) {
    var self = this;

    this._commitRepresentation('text/x.socialtext-wiki', content,
        function(response) {
            window.location.hash =
                encodeURIComponent(self.workspace + '/' + self.pageName);
            window.location.reload();
        }
    );
}

ST.EditablePage.prototype._updateEditDiv = function() {
    var innerDiv = DIV(null,
        FORM({name: 'editor', method: 'POST',
              action: '#' + encodeURIComponent(this.workspace + '/' +this.pageName)},
        TEXTAREA({rows: 20, cols: 80, name: 'wikitext'},null, this.content),
        INPUT({name: 'Edit', value: 'Edit', type: 'Submit'})));
    swapDOM(this.div, innerDiv);
    this.div = innerDiv;
}
// END EditablePage

// Pages Class
ST.Pages = function(workspace) {
    ST.Pages.baseConstructor.call(this, workspace);
}

ST.extend(ST.Pages, ST.Collection);

ST.Pages.prototype.route = function() {
    return ST.Pages.superClass.route.call(this) + '/pages';
}

ST.Pages.prototype.getContent = function(params) {
    var self = this;
    // prepend sticking the content somewhere useful
    // onto the function
    var callback = function(response) {
        self.content = response.responseText;
        params.callback(response);
    }
    this._requestRepresentation(params.type, callback); 
}

// END Pages

// ClickablePages Class
ST.ClickablePages = function(workspace, div) {
    ST.ClickablePages.baseConstructor.call(this, workspace);
    this.div = div;
}
ST.extend(ST.ClickablePages, ST.Pages);

ST.ClickablePages.prototype.display = function() {
    var self = this;
    this.getList({
        callback: function(response) {
            self._updateViewDiv();
        }
    });
}

ST.ClickablePages.prototype._updateViewDiv = function() {
    var innerDiv = DIV();
    Jemplate.process(
        'recent.html', {
            workspace: this.workspace,
            pages: this.items
        },
        innerDiv
    );

    swapDOM(this.div, innerDiv);
    this.div = innerDiv;
}
// END ClickablePages

// ChangedPages Class
ST.ChangedPages = function(workspace, div, count) {
    ST.ChangedPages.baseConstructor.call(this, workspace, div);
    this._count = count;
}
ST.extend(ST.ChangedPages, ST.ClickablePages);

ST.ChangedPages.prototype.count = function() {
    return this._count;
}

ST.ChangedPages.prototype.route = function() {
    return ST.ChangedPages.superClass.route.call(this) +
        '?order=newest;count=' + this.count();
}
// END ChangedPages

// Backlinks Class
ST.Backlinks = function(workspace, pageName, div) {
    ST.Backlinks.baseConstructor.call(this, workspace, div);
    this.pageName = pageName;
}
ST.extend(ST.Backlinks, ST.ClickablePages);

ST.Backlinks.prototype.route = function() {
    return ST.Backlinks.superClass.route.call(this) +
        '/' + encodeURIComponent(this.pageName) + '/backlinks';
}
// END Backlinks

// Classs thingies


ST.LoadPage = function(x) {
    // This is a bit tortured
    var href = x.getAttribute('href');
    href = href.replace(/.*#/, '');
    window.location.hash = href;
    window.location.reload();
}
