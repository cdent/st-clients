require 'yaml'
require 'socialtext/soap'

class ApplicationController < ActionController::Base
    include Socialtext::Soap::Client

    before_filter :load_config
    before_filter :soap_init
    before_filter :changes_box

    private
    def load_config
        @config = {}
        yaml = YAML.load_file("#{RAILS_ROOT}/config/socialtext.yaml")
        yaml.each_pair {|k,v| @config[k.to_sym] = v}
    end

    def soap_init
        @workspace = params[:workspace] || @config[:workspace]
        st_init(@config.merge({:workspace => @workspace}))
    end

    def changes_box
        @changes_box = get_changes(:category => 'recent changes', :count => 10)
    end
end
