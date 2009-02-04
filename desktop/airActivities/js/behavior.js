var wiki = {
    'baseURI': 'https://www2.socialtext.net',
    'imagesDir': '/nlw/plugin/widgets/images/asset-icons/',
    'credentials': {
        'username': '',
        'password': ''
        },
    'lastevent_timestamp': '0',
    'timer': new air.Timer(30000, 1),
    'tstimer': new air.Timer(5000, 0),
    'assetMap': {
        'edit_save': 'edit-16.png',
        'comment': 'comment-16.png',
        'tag_add': 'tag-16.png',
        'duplicate': 'upload-16.png',
        'rename': 'upload-16.png',
    }
}

wiki.setup = function() {
    air.URLRequestDefaults.manageCookies = true;
    air.URLRequestDefaults.useCache = true;
    air.URLRequestDefaults.authenticate = true;
    wiki.timer.addEventListener(air.TimerEvent.TIMER, wiki.getActivityStream);
    wiki.tstimer.addEventListener(air.TimerEvent.TIMER, updateTimestamps);
    wiki.tstimer.start();
    jQuery("#clearActivity").click(wiki.clearEvents);
    jQuery("#updateActivity").click(wiki.updateEvents);
    jQuery("#loginSave").click(wiki.loginOK);
    jQuery('#logout').click(wiki.logout);
    wiki.login();
    //air.Introspector.Console.log(document);
}

wiki.loginOK = function(evt) {
    wiki.credentials.username=jQuery("#usernameinput")[0].value;
    wiki.credentials.password=jQuery("#passwordinput")[0].value;
    wiki.saveCredentials();
    jQuery('#login').hide();
    wiki.getActivityStream(); 
    jQuery('#content').show();
    return false;
}

wiki.login = function() {
    wiki.loadCredentials();
    if (wiki.credentials.username == '') {
        jQuery('#content').hide();
        jQuery('#login').show();
    } else {
        jQuery("#login").hide();
        jQuery("#content").show();
        wiki.getActivityStream();
    }
}

wiki.logout = function() {
    wiki.timer.reset();
    wiki.clearEvents();
    wiki.lastevent_timestamp = '0';
    air.trace("stopped timer");
    // clear the in-memory object
    wiki.credentials.username = '';
    wiki.credentials.password = '';
    air.trace("cleared credentials object");
    
    // clear out the credentials file
    var credFile = air.File.applicationStorageDirectory;
    credFile = credFile.resolvePath("credentials.txt");
    air.trace(credFile);
    var credString="\n";
    var now = new Date();
    var fs = new air.FileStream();
    fs.open(credFile, air.FileMode.WRITE);
    air.trace(fs);
    fs.writeUTFBytes(credString);
    air.trace(fs);
    fs.close();
    air.trace("finished logging out");
    
    // redisplay the login div
    wiki.login();
}

wiki.saveCredentials = function() {
    var credFile = air.File.applicationStorageDirectory;
    credFile = credFile.resolvePath("credentials.txt");
    var credString = wiki.credentials.username + '\n' + wiki.credentials.password;
    var fs = new air.FileStream();
    fs.open(credFile, air.FileMode.WRITE);
    fs.writeUTFBytes(credString);
    fs.close();
    air.trace("finished saving credentials");
}

wiki.loadCredentials = function() {
    var credFile = air.File.applicationStorageDirectory;
    credFile = credFile.resolvePath("credentials.txt");
    try {
    
        var fs = new air.FileStream();
        fs.open(credFile, air.FileMode.READ);
        var credString = fs.readMultiByte(credFile.size, air.File.systemCharset);
        air.trace(credString);
        fs.close();
        air.trace(fs);
        var credparts=credString.split("\n");
        wiki.credentials.username=credparts[0];
        wiki.credentials.password=credparts[1];
        //air.Introspector.Console.log(wiki.credentials);
    } catch (err) {
        air.trace("bad credentials file");
        air.trace(err);
    }
}

wiki.handleActivityStream = function(event) {
    var data = eval(event.target.data);
    jQuery.each(data.reverse(), wiki.displayEvent);
}

wiki.getActivityStream = function() {
    var authHeader = new air.URLRequestHeader();
    authHeader.name = 'Authorization';
    authHeader.value = 'Basic ' + Base64.encode(wiki.credentials.username + ':' + wiki.credentials.password);
    air.trace("I want to get your activity stream!");
    wiki.showLoading();
    var URL = wiki.baseURI + "/data/events/conversations/"+escape(wiki.credentials.username);
    var request = new air.URLRequest(URL);
    request.requestHeaders = new Array(new air.URLRequestHeader("Accept", "application/json"));
    request.requestHeaders.push (authHeader);
    var loader = new air.URLLoader();
    loader.addEventListener(air.Event.COMPLETE, wiki.handleActivityStream);
    loader.load(request);
    air.trace("...done!");
    wiki.timer.reset();
    wiki.timer.start();
}

wiki.handleError = function(event) {
    air.Introspector.Console.log(event);    
}

wiki.linkClick = function(domevent) {
    //air.Introspector.Console.log(domevent);
    var url = domevent.target.href.replace("app:", wiki.baseURI);
    var urlRequest = new air.URLRequest(url);
    air.navigateToURL(urlRequest);
    return false;
}

wiki.showInformation = function(event) {
    var nlwevent = jQuery(event.target).data('nlwevent');
    //air.Introspector.Console.log(nlwevent);
    var listItem = jQuery(event.target).parent();
    var info = jQuery('div.info', listItem);
    info.html('<p>' + nlwevent.context.revision_count + ' revisions.  Most recent: ' + nlwevent.at + '.<br /><em>Watch this space for more info soon!</em></p>');
    info.slideDown('1000', function(){/* nothing */});
}

wiki.hideInformation = function(event) {
    var listItem = jQuery(event.target).parent();
    var info = jQuery('div.info', listItem);
    info.slideUp('1000', function(){/* nothing */});
}

wiki.displayEvent = function(index, nlwevent) {
    //air.Introspector.Console.log(nlwevent);
    if (nlwevent.at > wiki.lastevent_timestamp) {
        wiki.lastevent_timestamp = nlwevent.at;
        // -- make the list item --
        var eventItem = jQuery('<li>').attr({
            'class': 'activity'
        });
        // make and append the avatar
        var eventAvatar = jQuery('<img>').attr({
            'class': 'avatar',
            src: wiki.baseURI + '/data/people/' + nlwevent.actor.id + '/small_photo'
        });
        eventAvatar.data('nlwevent', nlwevent);
        eventAvatar.toggle(wiki.showInformation, wiki.hideInformation);
        eventItem.append(eventAvatar);
        // -- make and append the action icon --
        var eventAction = jQuery('<img>').attr({
            'class': 'action',
            src: wiki.baseURI + wiki.imagesDir + wiki.assetMap[nlwevent.action]
        })
        eventItem.append(eventAction);
        // -- make and append the madlib sentence --
        eventItem.append(madlib_render_event(nlwevent));
        // -- make and append the info toggle --
        var eventInformation = jQuery('<div>').attr({'class':'info hidden'});;
        eventItem.append(eventInformation)
        // -- setup and insert the event item --
        jQuery("#activityStream").prepend(eventItem);
        eventItem.slideDown(3000, function() {
            wiki.highlightItem(eventItem);
            setTimeout(function(){wiki.normalizeItem(eventItem)}, 2000);
        });
        // -- set up the click handlers for anchors --
        jQuery(".activity a").click(wiki.linkClick);
    }
}

wiki.highlightItem = function(item) {
    jQuery(item).addClass('highlight');
}

wiki.normalizeItem = function(item) {
    jQuery(item).removeClass('highlight');
}

wiki.showLoading = function() {
    //var dataContainer = document.getElementById('data');
    //dataContainer.innerHTML = "<p>Loading...</p>";
}

wiki.clearEvents = function() {
    jQuery("#activityStream").html("");
    return false;
}

wiki.updateEvents = function() {
    wiki.timer.reset();
    wiki.getActivityStream();
}
