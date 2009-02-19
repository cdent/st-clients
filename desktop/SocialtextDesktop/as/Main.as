function onAppInit() {
    Foo.visible = true;
}

function domInitialized() {
    HTML.htmlLoader.window.hideFrame = function() {
        Foo.visible = false;
    };
}
