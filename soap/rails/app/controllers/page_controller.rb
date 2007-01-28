class PageController < ApplicationController
    PageFormat = 'html/RailsDemo'

    def view
        @page = get_page(:page => params[:pname], :format => PageFormat)
        redirect_to_page(@page.page_uri) if @page.page_uri != params[:pname]
    end

    def home
        @page = get_page(:page => '', :format => PageFormat)
        redirect_to_page(@page.page_uri)
    end

    def edit
        @page = get_page(:page => params[:pname], :format => 'wikitext')
    end

    def update
        page = set_page(:page => params[:pname], :content => params[:page_body])
        redirect_to_page(page.page_uri)
    end

    private
    def redirect_to_page(name)
        redirect_to :action => 'view',
                    :pname => name,
                    :workspace => @workspace
    end
end
