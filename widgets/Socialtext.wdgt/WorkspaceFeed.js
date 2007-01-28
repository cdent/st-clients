// server assumed to have trailing '/'
function WorkspaceFeed(server, workspace, category, enabled) {
    this.URL = server + 'feed/workspace/'
        + encodeURIComponent(workspace) + '?category='
        + encodeURIComponent(category);

    this.workspace = workspace;
    this.enabled = enabled;
}

WorkspaceFeed.prototype.get = function(callback) {
    var feed = this;

    xml_get(this.URL, ourCallback);

    function ourCallback(responseXML) {
        callback(responseXML, feed);
    }
};
