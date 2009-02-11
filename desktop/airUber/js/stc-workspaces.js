// ----------  workspaces  ----------

stc.workspaces.setup = function() {
    var selector = $('#workspaces-selector');
    stc.utils.getStream('/data/workspaces', function(data){
        $(data).each(function(i, item){
            selector.append($('<option>').attr('value', item.name).text(item.title));
        });
    });
    selector.change(stc.workspaces.handleSelectorChange);
}

stc.workspaces.load = function() {
    if (!stc.workspaces.initialized) {
        // 1. set the config from preferences
        // 2. fetch the relevant recent changes
        stc.workspaces.initialized = true;
    }
}

stc.workspaces.handleSelectorChange = function() {
    stc.utils.showWaiting('#workspaces-app ul');
    var selector = $('#workspaces-selector');
    $.each(selector.children(), function(i, item){
        if (item.selected) {
            var url = '/data/workspaces/' + item.value + '/pages';
            stc.utils.getStream(url, stc.workspaces.handleStream);
        }
    });
}

stc.workspaces.handleStream = function(data) {
    var workspacesUL = $('#workspaces-app ul');
    workspacesUL.html("")
    $(data.reverse()).each(function(i, item){
        workspacesUL.prepend($('<li>')
            .html($('<a>')
            .attr('href', item.page_uri)
            .text(item.name)));
    });
}

stc.workspaces.resize = function() {
    // pass
}
