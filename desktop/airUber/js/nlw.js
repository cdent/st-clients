/*
    Wiki
    ----
*/
var Wiki = {
    baseURI: 'https://www2.socialtext.net',
}
/*
    EventList
    ---------
*/
var EventList = {
    lastevent_timestamp: Date.now(),
    displayEvent: function(nlwevent) {
        if (nlwevent.getTimestamp() > this.lastevent_timestamp) {
            this.lastevent_timestamp = nlwevent.getTimestamp();
            item = nlwevent.build();
            jQuery("#activityStream").prepend(item);
            item.appear();
        }
    }
}
/*
    NLWEvent
    --------
*/
function NLWEvent(nlwevent) {
    this._item = null;
    this.event = nlwevent;
    this.baseURI = Wiki.baseURI;
}
NLWEvent.prototype.handleClick = function(ev) {
    ev.preventDefault();
    var url = domevent.target.href.replace("app:", wiki.baseURI);
    var urlRequest = new air.URLRequest(url);
    air.navigateToURL(urlRequest);
    return false;
}
NLWEvent.prototype.handleToggle = function(ev) {
    ev.preventDefault();
    this.showInformation(ev.target);
    console.log(this);
    console.log(ev.target);
}
NLWEvent.prototype.getTimestamp = function() {
    return this.event.at;
}
NLWEvent.prototype.avatar = function() {
    return jQuery('<img').attr({
        'class': 'avatar',
        'src': this.baseURI + '/data/people/' + this.nlwevent.actor.id + '/small_photo'
    });
}
NLWEvent.prototype.madlib = function() {
    return jQuery(madlib_render_event(this.nlwevent));
}
NLWEvent.prototype.toggle = function() {
    return jQuery('<strong>').attr({
        'class': 'toggle'
    }).text('+').click(this.handleToggle);
}
NLWEvent.prototype.info = function() {
    return jQuery('<div>').attr({
        'class': 'info hidden'
    }).text('Loading...');
}
NLWEvent.prototype.buildItem = function() {
    item = jQuery('<li>').attr({
        'class': 'activity'
    });
    item.append(this.avatar());
    item.append(this.madlib());
    item.append(this.toggle());
    item.append(this.info());
    jQuery('a' item).click(this.handleClick);
    this.item = item;
}
NLWEvent.prototype.item = function() {
    if (this._item == null) {
        this._item = this.buildItem();
    }
    return this._item
}
NLWEvent.prototype.appear = function() {
    this.item.slideDown(3000, this.highlight);
}
NLWEvent.prototype.highlight = function() {
    this.item.addClass('highlight');
    setTimeout(this.normal, 2000);
}
NLWEvent.prototype.normal = function() {
    this.item.removeClass('highlight');
}
