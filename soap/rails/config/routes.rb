ActionController::Routing::Routes.draw do |map|
    map.connect ':workspace/changes', :controller => 'page_lists', 
                                      :action => 'changes'

    map.connect ':workspace/search', :controller => 'page_lists', 
                                     :action => 'search'

    map.connect ':workspace/pages/:pname/edit' , :controller => 'page', 
                                                 :action => 'edit'

    map.connect ':workspace/pages/:pname/update' , :controller => 'page', 
                                                   :action => 'update'

    map.connect ':workspace/pages/' , :controller => 'page', 
                                      :action => 'home'

    map.connect ':workspace/pages/:pname' , :controller => 'page', 
                                            :action => 'view'

    map.connect '/' , :controller => 'page', :action => 'home'
end
