function Workspace(server, name) {
    this.server = server;
    this.name = name;
}

Workspace.prototype.pickle = function() {
    var elements = [];

    // This turns '=' into '==' and separates elements with 'c='.
    // So '=' is like an escape character, but it comes AFTER the
    // thing it escapes.  Putting it after makes it easy to pull
    // things apart using a split with a zero-width negative
    // lookahead assertion.  If javascript had lookbehind assertions,
    // I'd probably have chosen to put the escape character in
    // the more normal position (first).
    elements.push(this.server.replace(/=/g, '=='));
    elements.push(this.name.replace(/=/g, '=='));
    return elements.join('c=');
}

Workspace.unpickle = function(str) {
    var elements = str.split(/c=(?!=)/);
    var server = elements[0].replace(/==/g, '=');
    var name = elements[1].replace(/==/g, '=');

    return new Workspace(server, name);
}
