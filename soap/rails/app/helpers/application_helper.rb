
module ApplicationHelper
    def link_page(page, text=nil, *opts)
        text = text.is_a?(Symbol) ? h(page.send(text)) : text
        text = text.nil? ? h(page.subject) : text
        link_to text, {:controller => 'page',
                       :action => 'view',
                       :pname => page.page_uri},
                      *opts
    end

    def link_home(text, *args)
        link_to text, :controller => 'page', :action => 'home', *args
    end
    
    def link_rc(text, *args)
        link_to text, :controller => 'page_lists', :action => 'changes', *args
    end
end
