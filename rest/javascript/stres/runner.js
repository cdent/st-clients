
// connect on load to running the "app"
// this makes page history work pretty okay
connect(window, "onload", STInit);

function STInit() {
    var hash = window.location.hash;
    var page;
    var pageName = 'admin wiki';
    var workspace = 'admin';

    if (hash) {
        hash = hash.replace(/#/g, '');
        var pageInfo = unescape(hash);
        var infos = pageInfo.split('/');
        workspace = infos[0];
        pageName = infos[1];

    }

    // new on ST.Resource should take a parameters
    var page = new ST.EditablePage(workspace, pageName, 'mypage');
    page.display();
    var changes = new ST.ChangedPages(workspace, 'mychanges', 15);
    changes.display();
    var backlinks = new ST.Backlinks(workspace, pageName, 'mybacklinks');
    backlinks.display();
}

