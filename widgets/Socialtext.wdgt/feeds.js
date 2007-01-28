window.onload = function() {
    model = new Model();
    fetcher = new Fetcher(model);
    frontView = new FrontView(model);
    backView = new BackView(model);
}

function open_url(url) {
    if (typeof(widget) == 'undefined')
        window.open(url);
    else
        widget.openURL(url);
}

function xml_get(url, callback) {
    var req = new XMLHttpRequest();

    req.overrideMimeType('text/xml');
    req.open('GET', url);
    req.onreadystatechange = function() {
        if (req.readyState == 4 && req.status == 200)
            callback(req.responseXML);
    }

    req.send(null);
}
