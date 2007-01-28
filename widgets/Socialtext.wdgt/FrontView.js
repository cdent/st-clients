function FrontView(model) {
    this.model = model;
    this.listingTable = document.getElementById('listing');
    this.scrolledDiv = document.getElementById('front_scrolled');

    // toggleDebug(); // Uncomment for Scroller debugging.
    scrollerInit(
        document.getElementById('front_scrollbar'),
        document.getElementById('front_scrolltrack'),
        document.getElementById('front_scrollthumb'));

    this.displayAll = function() {
        this.listingTable.innerHTML = '';
        var sortedItems = model.allItemsNewestFirst();
        for (var ii = 0; ii < sortedItems.length; ++ii)
            this.displayItem(sortedItems[ii]);
        calculateAndShowThumb(this.scrolledDiv);
    }

    this.displayItems = function(feedItems) {
        for (var ii = 0; ii < feedItems.length; ++ii)
            this.displayItem(feedItems[ii]);
    }

    this.displayItem = function(feedItem) {
        var tr = document.createElement('tr');
        tr.innerHTML =
            '<td>'
            + feedItem.feed.workspace + ': '
            + '<a href="#" onclick=\'open_url("' + feedItem.url + '")\'>'
            + feedItem.title + '</a>'
            + '</td><td>' + feedItem.author
            + '</td>';
        this.listingTable.appendChild(tr);
    }
}


