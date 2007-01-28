function BackView(model) {
    this.model = model;
    this.selectPane('servers');
    this.workspaceView =
        new WorkspaceView(model, document.getElementById('workspaces_pane'));

    this.setupGlobalCallbacks();
    this.createButtons();
}

BackView.prototype.panes = ['servers', 'workspaces', 'filters'];

BackView.prototype.selectPane = function(name) {
    for (var ii = 0; ii < this.panes.length; ++ii) {
        var tab = document.getElementById(this.panes[ii] + '_tab');
        var pane = this.getPane(this.panes[ii]);
        if (name == this.panes[ii]) {
            tab.style.backgroundColor = '#555';
            pane.style.display = 'block';
        } else {
            tab.style.backgroundColor = '#222';
            pane.style.display = 'none';
        }
    }
    if (name == 'workspaces')
        this.workspaceView.display();
}

BackView.prototype.display = function() {
    var servers = this.model.servers;
    var servers_list = document.getElementById('servers_list');
    servers_list.innerHTML = '';

    for (var ii = 0; ii < servers.length; ++ii) {
        servers_list.appendChild(document.createTextNode(servers[ii]));

        var button = document.createElement('span');
        button.setAttribute('class', 'button');
        createGenericButton(
            button,
            '-',
            makeRemover(servers[ii])
        );
        button.style['float'] = 'right';
        servers_list.appendChild(button);

        servers_list.appendChild(document.createElement('br'));
        servers_list.appendChild(document.createElement('br'));
    }
}

BackView.prototype.getPane = function(name) {
    return document.getElementById(name + '_pane');
}

BackView.prototype.setupGlobalCallbacks = function() {
    var self = this;

    selectPane = function(name) {
        self.selectPane(name);
    }

    makeRemover = function(name) {
        return function() { removeServer(name) }
    }

    removeServer = function(name) {
        self.model.removeServer(name);
        self.display();
    }

    addServer = function() {
        var input = document.getElementById('new_server_input');
        self.model.addServer(input.value);
        input.value = '';
        self.display();
    }

    done = function() {
        self.model.writeToPrefs();
        hideBack();
    }
}

BackView.prototype.createButtons = function() {
    createGenericButton(
        document.getElementById('add_server'),
        '+',
        addServer
    );

    createGenericButton(
        document.getElementById('done'),
        'Done',
        done
    );
}
