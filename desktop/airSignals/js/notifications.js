

function Notification(content, timeout) {
    this.content = content; 
    this.width = 250;
    this.height = 120;
    this.margin = 10;
    this.timeout=timeout;
}

Notification.prototype = {
show: function() {
          var visibleBounds = air.Screen.mainScreen.visibleBounds;

          var bounds = new air.Rectangle(
                  /* left */ visibleBounds.right - this.width - this.margin,
                  /* top */ visibleBounds.bottom - this.height - (2*this.margin),
                  /* width */ this.width,
                  /* height */ this.height
                  );
          var options = new air.NativeWindowInitOptions();
          options.transparent = true;
          options.systemChrome = air.NativeWindowSystemChrome.NONE;
          options.type = air.NativeWindowType.LIGHTWEIGHT;


          this.htmlLoader = air.HTMLLoader.createRootWindow(
                  true, 
                  options,
                  false, //no scrollbars
                  bounds
                  );

          var self = this;

          this.htmlLoader.paintsDefaultBackground = false;
          this.htmlLoader.loadString("<div style='background-color: #a0a0a0; border-style:solid; border-color: #101010;'><div style='margin:3px'>"+this.content+"<br/><br/><br/></div></div>");
          this.htmlLoader.addEventListener("click", function(){
                  if(self.onclick){
                  self.onclick();
                  }
                  });


          // We should close all the notifications when the window is closing
          this.windowCloseEvent = function(){
              self.close();
          }

          if (this.timeout != null) {
              this.setTimeout(this.timeout);
            }
          window.addEventListener('unload', this.windowCloseEvent);
      },
close: function() {
           if (this.htmlLoader != null) {
               this.htmlLoader.stage.nativeWindow.close();
               this.htmlLoader = null;
            }
       },

onclick: function(){
             note.close();
         },
setTimeout: function(thetime) {
                var self=this;
                setTimeout(function () {
                        self.close();
                        }, thetime);


            }
}
