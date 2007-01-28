// FIXME - rename to WorkspacesView

function WorkspaceView(model, container) {
    this.model = model;
    this.container = container;
    this.selectedServerIndex = 0;

    this.setupGlobalCallbacks();
    this.createButtons();
}

WorkspaceView.prototype.display = function() {
    this.populateServerSelector();
    this.populateWorkspaceList();
}

WorkspaceView.prototype.populateServerSelector = function() {
    var selector = document.getElementById('server_selector');
    var servers = this.model.servers;

    selector.innerHTML = '';
    for (var ii = 0; ii < servers.length; ++ii) {
        var option = document.createElement('option');
        option.setAttribute('value', servers[ii]);
        option.innerHTML = servers[ii];
        selector.appendChild(option);
    }
    selector.selectedIndex = this.selectedServerIndex;
}

WorkspaceView.prototype.populateWorkspaceList = function() {
    var container = document.getElementById('workspaces_list');
    container.innerHTML = '';

    var workspaces = this.model.workspaces[this.getSelectedServer()];
    for (var ii = 0; ii < workspaces.length; ++ii) {
        container.appendChild(document.createTextNode(workspaces[ii].name));

        var button = document.createElement('span');
        createGenericButton(button, '-', this.makeRemover(workspaces[ii]));
        button.style['float'] = 'right';
        container.appendChild(button);

        container.appendChild(document.createElement('br'));
        container.appendChild(document.createElement('br'));
    }
}

WorkspaceView.prototype.makeRemover = function(workspace) {
    return function() { this.model.removeWorkspace(workspace) }
}

WorkspaceView.prototype.getSelectedServer = function() {
    var selector = document.getElementById('server_selector');

    return selector.options[selector.selectedIndex].getAttribute('value');
}

WorkspaceView.prototype.getNewWorkspaceName = function() {
    return document.getElementById('new_workspace_input').value;
}

WorkspaceView.prototype.clearNewWorkspaceName = function() {
    document.getElementById('new_workspace_input').value = '';
}

WorkspaceView.prototype.setupGlobalCallbacks = function() {
    var self = this;

    serverChanged = function() {
        var selector = document.getElementById('server_selector');
        self.selectedServerIndex = selector.selectedIndex;
        self.display();
    }

    addWorkspace = function() {
        var workspace = self.getNewWorkspaceName();
        if (workspace != '') {
            var server = self.getSelectedServer();
            self.clearNewWorkspaceName();
            self.model.addWorkspace(new Workspace(server, workspace));
            self.display();
        }
    }
}

WorkspaceView.prototype.createButtons = function() {
    createGenericButton(
        document.getElementById('add_workspace'),
        '+',
        addWorkspace
    );
}
