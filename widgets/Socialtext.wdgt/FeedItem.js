function FeedItem(itemElement, feed) {
    this.feed = feed;

    var titles = itemElement.getElementsByTagName('title');
    if (titles.length)
        this.title = titles[0].firstChild.nodeValue;

    var authors = itemElement.getElementsByTagName('author');
    if (authors.length)
        this.author = authors[0].firstChild.nodeValue;

    var pubDates = itemElement.getElementsByTagName('pubDate');
    if (pubDates.length)
        this.pubDate = Date.parse(pubDates[0].firstChild.nodeValue);

    var guids = itemElement.getElementsByTagName('guid');
    if (guids.length)
        this.url = guids[0].firstChild.nodeValue;
}
