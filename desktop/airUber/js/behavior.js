
var log = air.Introspector.Console.log;
var trace = air.trace;

var stc = {
    nav: {},
    utils: {
        re: {
            link: new RegExp('(http.*?)[ $]?'),
            at: new RegExp('(@\S+) ')
        }
    },
    signals: {
        initialized: false,
        acive: false,
        last_fetch: '0',
        timerID: null
    },
    activity: {
        initialized: false,
        active: false
    },
    workspaces: {
        initialized: false,
        active: false
    },
    user: {
        username: 'tracy.ruggles@socialtext.com',
        password: '2soleil',
        userid: 3397,
        server: 'https://www2.socialtext.net'
    }
}

stc.setup = function() {
    stc.nav.setup();
    stc.signals.setup();
    stc.activity.setup();
    stc.workspaces.setup();
    stc.signals.resize();
}
// ----------  utils  ----------

stc.utils.showWaiting = function(selector) {
    var ajaxDiv = $('<div>')
        .css({
            'text-align':'center',
            'padding':'4em 0'
        })
        .addClass('spinner')
        .text(' Loading...');
    var ajaxSpinner = $('<img>')
        .attr({
            'src':'../img/wait26.gif',
            'align':'center'
        });
    ajaxDiv.prepend(ajaxSpinner);
    $(selector).html(ajaxDiv);
}

stc.utils.getStream = function(url, callback) {
    var loader = new air.URLLoader();
    loader.addEventListener(air.Event.COMPLETE, function(event){
        callback(eval(event.target.data));
    });
    var request = new air.URLRequest(stc.user.server + url);
    request.requestHeaders = new Array(new air.URLRequestHeader("Accept", "application/json"));
    var authHeader = new air.URLRequestHeader();
    authHeader.name = 'Authorization';
    authHeader.value = 'Basic ' + Base64.encode(stc.user.username + ':' + stc.user.password);
    request.requestHeaders.push(authHeader);
    trace(Date() + ': loading ' + url);
    loader.load(request);
}

stc.utils.handleLinkClick = function(ev) {
    var url = ev.target.href.replace("app:", signals.baseURI);
    var urlRequest = new air.URLRequest(url);
    air.navigateToURL(urlRequest);
    return false;
}

stc.utils.highlight = function(el, t) {
    $(el).addClass('highlight');
    var remove = function() {
        $(el).removeClass('highlight');
    }
    setTimeout(remove, t);
}

// ----------  navigation  ----------

stc.nav.setup = function() {
    stc.nav.el = $('#app-nav ul')
    $.each(stc.nav.el.children(), function(i,item){
        $(item).click(stc.nav.handleTabClick);
    })
}

stc.nav.handleTabClick = function(ev) {
    var name = $(ev.currentTarget).text().toLowerCase();
    $.each(stc.nav.el.children(), function(i, item){
        var item = $(item);
        var text = item.text().toLowerCase();
        var appDiv = $('#'+text+'-app');
        if (name==text) {
            $(item).addClass('active');
            appDiv.addClass('active');
            trace(name); trace(text); trace(item);
            stc[name].active = true;
            stc[name].load();
        } else {
            $(item).removeClass('active');
            appDiv.removeClass('active');
            stc[name].active = false;
        }
    });
}
