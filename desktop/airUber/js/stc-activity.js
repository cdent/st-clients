// ----------  activity  ----------

stc.activity.setup = function() {
    $('#activity-feed-selector').change(stc.activity.handleSelectorChange);
    setTimeout(stc.activity.refresh, 10000);
}

stc.activity.load = function() {
    if (!stc.activity.initialized) {
        // 1. set the config from preferences
        // 2. fetch relevant activity stream
        stc.activity.initialized = true;
    }
}

stc.activity.refresh = function() {
    
}

stc.activity.handleSelectorChange = function() {
    stc.utils.showWaiting('#activity-app ul');
    var selector = $('#activity-feed-selector');
    $.each(selector.children(), function(i, item){
        if (item.selected) {
            var url = '/data/events' + item.value + '/' + stc.user.userid;
            stc.utils.getStream(url, stc.activity.handleStream);
        }
    });
}

stc.activity.handleStream = function(data) {
    var activityUL = $('#activity-app ul');
    activityUL.html("");
    $(data.reverse()).each(function(i, item) {
        try {
            var eventHTML = madlib_render_event(item);
        } catch (err) {
            log(item);
            var eventHTML = $('<span>').text('Error: ' + err.description);
        }
        activityUL.prepend($('<li>').html(eventHTML));
    });
}

stc.activity.resize = function() {
    // pass
}
