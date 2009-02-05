var temp = null;

var signals = {
    'baseURI': 'https://www2.socialtext.net',
    'credentials': {
        'username': '',
        'password': ''
    },
    'signalsURI': '/data/signals',
    'lastsignal_timestamp': '0',
    'timer': new air.Timer(20000, 1),
    'tstimer': new air.Timer(5000, 0),
    're': {
        'link': new RegExp('(http.*?) '),
        'at': new RegExp('(@\S+) ')
    }
}

signals.setup = function() {
    air.URLRequestDefaults.manageCookies = true;
    air.URLRequestDefaults.useCache = true;
    air.URLRequestDefaults.authenticate = true;
    signals.timer.addEventListener(air.TimerEvent.TIMER, signals.getSignalsStream);
    signals.tstimer.addEventListener(air.TimerEvent.TIMER, signals.updateSignalTimes);
    signals.tstimer.start();
    jQuery('#loginSave').click(signals.loginOK);
    jQuery('#signalBody').focus(signals.activateSignalBody);
    jQuery('#signalBody').blur(signals.deactivateSignalBody);
    jQuery('#signalForm').submit(signals.handleSignal);
    jQuery('#config-link').click(signals.showConfig);
    jQuery('#refreshSignals').click(signals.handleRefreshSignals);
    jQuery('#signalConfig').submit(signals.saveConfig);
    jQuery('#clearSignals').click(signals.handleClearSignals);
    jQuery('#filterSignals').click(signals.handleFilterSignals);
    signals.login();
    //air.Introspector.Console.log('test');
}

signals.updateSignalTimes = function() {
    jQuery('.madlib-ago').each(function(i, el){
        var then = new Date();
        then.setISO8601(jQuery(el).attr('id'));
        jQuery(el).text(getAgoString(then));
    });
}

signals.showConfig = function() {
    jQuery('#login').hide();
    jQuery('#signals').hide();
    jQuery('#config').show();
    return false;
}

signals.saveConfig = function() {
    // do something more interesting here
    jQuery('#login').hide();
    jQuery('#config').hide();
    jQuery('#signals').show();
}

signals.handleRefreshSignals = function() {
    signals.lastsignal_timestamp = '0';
    signals.getSignalsStream();
    return false;
}

signals.handleClearSignals = function() {
    jQuery("#signalItems").html("");
    return false;
}

signals.handleFilterSignals = function() {
    alert('not working yet');
    return false;
}

signals.login = function() {
    signals.loadCredentials();
    if (signals.credentials.username == '') {
        jQuery('#signals').hide();
        jQuery('#login').show();
    } else {
        jQuery('#login').hide();
        jQuery('#signals').show();
        signals.getSignalsStream();
    }
}

signals.loginOK = function(evt) {
    signals.credentials.username = jQuery('#usernameinput')[0].value;
    signals.credentials.password = jQuery('#passwordinput')[0].value;
    signals.saveCredentials();
    jQuery('#login').hide();
    jQuery('#config').hide();
    jQuery('#signals').show();
    signals.getSignalsStream();
    return false;
}

signals.loadCredentials = function() {
    var credFile = air.File.applicationStorageDirectory;
    credFile = credFile.resolvePath("credentials.txt");
    try {
        var fs = new air.FileStream();
        fs.open(credFile, air.FileMode.READ);
        var credString = fs.readMultiByte(credFile.size, air.File.systemCharset);
        fs.close();
        var credparts = credString.split("\n");
        signals.credentials.username = credparts[0];
        signals.credentials.password = credparts[1];
    } catch (err) {
        air.trace("bad credentials file");
        air.trace(err);
    }
}

signals.saveCredentials = function() {
    var credFile = air.File.applicationStorageDirectory;
    credFile = credFile.resolvePath("credentials.txt");
    var credString = signals.credentials.username + '\n' + signals.credentials.password;
    var fs = new air.FileStream();
    fs.open(credFile, air.FileMode.WRITE);
    fs.writeUTFBytes(credString);
    fs.close();
}

signals.getSignalsStream = function() {
    // signals.showLoading();
    var loader = new air.URLLoader();
    loader.addEventListener(air.Event.COMPLETE, signals.handleSignalsStream);
    var request = new air.URLRequest(signals.baseURI + signals.signalsURI);
    request.requestHeaders = new Array(new air.URLRequestHeader("Accept", "application/json"));
    var authHeader = new air.URLRequestHeader();
    authHeader.name = 'Authorization';
    authHeader.value = 'Basic ' + Base64.encode(signals.credentials.username + ':' + signals.credentials.password);
    request.requestHeaders.push(authHeader);
    loader.load(request);
    signals.timer.reset();
    signals.timer.start();
}

signals.handleSignalsStream = function(event) {
    var data = eval(event.target.data);
    air.trace('check -> ' + Date() + ': retrieved ' + data.length + ' items');
    jQuery.each(data.reverse(), signals.displaySignal);
}

signals.displaySignal = function(index, signalEvent) {
    if (signalEvent.at > signals.lastsignal_timestamp) {
        // deal with the body
        var body = signalEvent.body;
        body = body.replace(signals.re.link, '<a href="$1" class="body">$1</a>');
        body = body.replace(signals.re.at, '<strong>$1</strong>');
        // deal with the timestamps
        signals.lastsignal_timestamp = signalEvent.at;
        var then = new Date();
        then.setISO8601(signalEvent.at);
        // ---------- make the list item ----------
        var signalItem = jQuery('<li>').attr('class', 'activity');
        // ---------- make & append the avatar ----------
        var signalAvatar = jQuery('<img>')
            .attr({
                'class': 'avatar',
                'src': signals.baseURI + '/data/people/' + signalEvent.user_id + '/small_photo'
            })
        signalItem.append(signalAvatar);
        // ---------- make & append the user ----------
        var signalUser = jQuery('<a>').attr({
           'class': 'user',
           'href': signals.baseURI + '/?profile/' + signalEvent.user_id
        }).text(signalEvent.best_full_name);
        signalItem.append(signalUser);
        signalItem
            .append(jQuery('<div>')
                .attr('class', 'madlib-ago')
                .attr('id', signalEvent.at)
                .text(getAgoString(then)))
            .append('<br />')
            .append(jQuery('<div>').attr('class', 'signal').html(body))
        jQuery('#signalItems').prepend(signalItem);
        signalItem.slideDown(2500, function() {
            // pass
        });
        jQuery(".activity a").click(signals.linkClick);
    }
}

signals.linkClick = function(domevent) {
    var url = domevent.target.href.replace("app:", signals.baseURI);
    var urlRequest = new air.URLRequest(url);
    air.navigateToURL(urlRequest);
    return false;
}

signals.activateSignalBody = function(evt) {
    if (evt.target.value == 'What are you working on?') {
        evt.target.value = '';
    }
    jQuery(evt.target).addClass('active');
}

signals.deactivateSignalBody = function(evt) {
    jQuery(evt.target).removeClass('active');
    
}

signals.handleSignal = function(evt) {
    var bodyInput = jQuery('#signalBody')[0]
    var signalBody = bodyInput.value;
    signals.postSignalBody(signalBody);
    bodyInput.value = "";
    evt.target.blur();
    return false;
}

signals.postSignalBody = function(body) {
    var auth = new air.URLRequestHeader("Authorization",
                                        'Basic ' + Base64.encode(signals.credentials.username + ':' + signals.credentials.password))
    var loader = new air.URLLoader();
    loader.addEventListener(air.Event.COMPLETE, signals.successfulSignal);
    var request = new air.URLRequest(signals.baseURI + signals.signalsURI);
    request.method = "POST";
    request.cacheResponse = false;
    request.useCache = false;
    request.data = '{"signal":"'+body+'"}'; // notice the double-quotes around the key/value pair
    request.contentType = "application/json";
    request.requestHeaders = new Array();
    request.requestHeaders.push(auth);
    loader.load(request);
    signals.timer.reset();
    signals.timer.start();
    return false;
}

signals.successfulSignal = function(msg) {
    signals.getSignalsStream();
}