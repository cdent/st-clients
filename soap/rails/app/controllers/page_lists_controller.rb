class PageListsController < ApplicationController
    def search
        @query = params[:q] || ""
        @results = get_search(:query => @query)
    end

    def changes
        @category = params[:category] || 'recent changes'
        @count = params[:count] || 50
        @results = get_changes(:category => @category, :count => @count)
    end
end
