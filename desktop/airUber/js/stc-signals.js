// ----------  signals  ----------

stc.signals.setup = function() {
    stc.signals.load();
    window.nativeWindow.addEventListener(air.Event.RESIZE, stc.signals.resize);
    stc.signals.active = true;
    setTimeout(stc.signals.refresh, 10000);
}

stc.signals.load = function() {
    if (!stc.signals.initialized) {
        stc.utils.showWaiting('#signals-app ul', 'Loading Signals...');
        stc.utils.getStream('/data/signals', stc.signals.handleStream);
        stc.signals.initialized = true;        
    }
}

stc.signals.refresh = function() {
    if (stc.signals.timerID != null) {
        clearTimeout(stc.signals.timerID);
        stc.signals.timerID = null;
    }
    stc.utils.getStream('/data/signals', stc.signals.handleStream);
    stc.signals.timerID = setTimeout(stc.signals.refresh, 5000);
}

stc.signals.increment = function(n) {
    var counter = $('#signals-tab span.counter');
    var val = eval(counter.text());
    val += n;
    counter.text(val);
}

stc.signals.handleStream = function(data) {
    var signalsUL = $('#signals-app ul');
    $('div.spinner').remove();
    $(data.reverse()).each(function(i, item) {
        if (item.at > stc.signals.last_fetch) {
            // deal with the signal body
            var body = item.body;
            body = body.replace(stc.utils.re.link, '<a href="$1" class="body">$1</a>');
            body = body.replace(stc.utils.re.at, '<strong>$1</strong>');
            // deal with the timestamps
            stc.signals.last_fetch = item.at;
            var then = new Date();
            then.setISO8601(item.at);
            // ---------- make the list item ----------
            var signalLI = $('<li>').attr('class', 'activity');
            if (!(i%2)) {signalLI.addClass('even')};
            // ---------- make & append the avatar ----------
            var avatarIMG = $('<img>')
                .attr({
                    'class': 'avatar',
                    'src': stc.user.server + '/data/people/' + item.user_id + '/small_photo'
                })
            signalLI.append(avatarIMG);
            // ---------- make & append the user ----------
            var userA = jQuery('<a>').attr({
               'class': 'user',
               'href': stc.user.server + '/?profile/' + item.user_id
            }).text(item.best_full_name);
            signalLI.append(userA);
            signalLI
                .append($('<div>')
                    .attr('class', 'madlib-ago')
                    .attr('id', item.at)
                    .text(getAgoString(then)))
                .append('<br />')
                .append(jQuery('<div>').attr('class', 'signal').html(body))
            signalLI.hide();
            signalsUL.prepend(signalLI);
            signalLI.slideDown(3000, function(){
                stc.utils.highlight(signalLI);
            });
            $(".activity a").click(stc.utils.handleLinkClick);
            // var note = new Notification(signalLI.html(), 6000);
            // note.show();
        }
    });
}

stc.signals.availableHeight = function() {
    var total = window.innerHeight;
    var taken = $('#header').height()
        + $('#app-nav').height()
        + $('#notifications').height()
        + $('#signals-app form').height()
        + $('#signals-app div').height()
        + $('#app-footer').height()
        + 48; // why 48?  I don't get it
    return total - taken;
}
stc.signals.resize = function() {
    if (stc.signals.active) {
        $('#signals-app ul').css({
            'height': stc.signals.availableHeight()
        });
    }
}

