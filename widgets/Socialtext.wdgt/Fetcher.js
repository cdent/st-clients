// FIXME: Eventually, we should stagger the fetches.

function Fetcher(model) {
    this.model = model;
    model.addChangeListener(this);

    this.setupGlobalCallbacks();

    this.update();
    this.resetInterval();
}

Fetcher.prototype.interval = 120000;

Fetcher.prototype.resetInterval = function() {
    if (typeof(this.timerInterval) != 'undefined')
        clearInterval(this.timerInterval);
    this.timerInterval = setInterval(update, this.interval);

    var self = this;
    function update() { self.update() }
}

Fetcher.prototype.update = function() {
    var feeds = this.model.getFeeds();

    alert('updating...');
    for (var ii = 0; ii < feeds.length; ++ii)
        if (feeds[ii].enabled)
            feeds[ii].get(handleFeed);
}

Fetcher.prototype.handleChange = function(model) {
    if (this.model != model)
        return;
    this.update();
    this.resetInterval();
}

Fetcher.prototype.setupGlobalCallbacks = function() {
    var self = this;

    handleFeed = function(xmldoc, feed) {
        var itemElements = xmldoc.getElementsByTagName('item');
        var feedItems = [];

        for (var ii = 0; ii < itemElements.length; ++ii)
            feedItems.push(new FeedItem(itemElements[ii], feed));

        self.model.addItems(feedItems);
        // XXX - model.registerChangeListener() instead
        frontView.displayAll();
    }
}
