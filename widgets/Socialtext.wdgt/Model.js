function Model() {
    if (window.widget) {
        this.restoreFromPrefs();
    }
}

Model.prototype.items = { };
Model.prototype.servers = [ ];
Model.prototype.workspaces = { };
Model.prototype.listeners = [ ];

Model.prototype.restoreFromPrefs = function() {
    alert('reading prefs...');
    var serverList = widget.preferenceForKey('servers');
    if (typeof(serverList) == 'undefined') {
        this.setDefaults();
        this.writeToPrefs();
        return;
    }
    var servers = widget.preferenceForKey('servers').split(/#/);
    for (var ii = 0; ii < servers.length; ++ii) {
        var server = servers[ii];

        this.addServer(server);
        var workspace_count =
            widget.preferenceForKey(server + '_workspace_count');
        for (var jj = 0; jj < workspace_count; ++jj) {
            this.addWorkspace(
                Workspace.unpickle(
                    widget.preferenceForKey(server + '_workspace_' + jj)));
        }
    }
    this.alertChange();
}

Model.prototype.setDefaults = function() {
    alert('setting defaults...');
    var server = 'https://www.socialtext.net/';
    this.addServer(server);
    this.addWorkspace(new Workspace(server, 'exchange'));
}

Model.prototype.writeToPrefs = function() {
    alert('writing prefs...');
    widget.setPreferenceForKey(this.servers.join('#'), 'servers');
    for (var ii = 0; ii < this.servers.length; ++ii) {
        var server = this.servers[ii];
        var workspaces = this.workspaces[server];
        widget.setPreferenceForKey(
            workspaces.length, server + '_workspace_count')
        for (var jj = 0; jj < workspaces.length; ++jj) {
            widget.setPreferenceForKey(
                workspaces[jj].pickle(), server + '_workspace_' + jj);
        }
    }
}

Model.prototype.alertChange = function() {
    alert('model changed.');
    for (var ii = 0; ii < this.listeners.length; ++ii)
        this.listeners[ii].handleChange(this);
}

Model.prototype.addChangeListener = function(listener) {
    this.listeners.push(listener);
}

Model.prototype.allItemsNewestFirst = function() {
    var sortedItems = [];
    for (var url in this.items)
        sortedItems.push(model.items[url]);
    return sortedItems.sort(byPubDate);

    function byPubDate(a, b) { return b.pubDate - a.pubDate }
}

Model.prototype.addItems = function(feedItems) {
    for (var ii = 0; ii < feedItems.length; ++ii)
        this.items[feedItems[ii].url] = feedItems[ii];
}

Model.prototype.addServer = function(server) {
    this.servers.push(server);
    this.workspaces[server] = [];
    this.alertChange();
}

Model.prototype.removeServer = function(server) {
    var newServers = [];

    for (var ii = 0; ii < this.servers.length; ++ii)
        if (this.servers[ii] != server)
            newServers.push(this.servers[ii])

    this.servers = newServers;
    this.workspaces[server] = null;
    this.alertChange();
}

Model.prototype.addWorkspace = function(workspace) {
    this.workspaces[workspace.server].push(workspace);
    this.alertChange();
}

Model.prototype.getFeeds = function() {
    var feeds = [];

    for (var ii = 0; ii < this.servers.length; ++ii) {
        var workspaces = this.workspaces[this.servers[ii]];
        for (var jj = 0; jj < workspaces.length; ++jj) {
            var workspace = workspaces[jj];
            feeds.push(
                new WorkspaceFeed(
                    this.servers[ii], workspace.name, 'Recent Changes', true));
        }
    }

    return feeds;
}
