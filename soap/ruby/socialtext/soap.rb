module Socialtext
module Soap
module Client

require 'soap/wsdlDriver'

DefaultAuthArgs = {
    :wsdl => 'https://www.socialtext.net/static/wsdl/0.9.wsdl',
    :username => 'soap.test@socialtext.com',
    :password => 'bubbles',
    :workspace => 'st-soap-test',
    :act_as => ''
}

attr_reader :st_wsdl
attr_reader :st_act_as
attr_reader :st_workspace
attr_accessor :st_username
attr_accessor :st_password

def st_init(opts={})
    opts = DefaultAuthArgs.merge(opts)
    @st_wsdl = opts[:wsdl]
    @st_soap = SOAP::WSDLDriverFactory.new(@st_wsdl).create_rpc_driver
    authenticate(opts)
end

def authenticate(opts={})
    @st_token = get_auth(opts)
end

def get_auth(opts={})
    self.st_username = opts[:username]
    self.st_password = opts[:password]
    @st_workspace = opts[:workspace]
    @st_act_as = opts[:act_as]
    @st_soap.getAuth(
        self.st_username,
        self.st_password,
        self.st_workspace,
        self.st_act_as
    )
end

def st_act_as=(username='')
    authenticate(:act_as => username, :password => self.st_password,
                 :workspace => self.st_workspace, :username => self.st_username)
    @st_act_as = username
end

def st_workspace=(workspace='')
    authenticate(:act_as => self.st_act_as, :password => self.st_password,
                 :workspace => workspace, :username => self.st_username)
    @st_workspace = workspace
end

def heartbeat()
    @st_soap.heartBeat()
end

def get_page(opts={})
    opts = {:page => '', :format => 'html'}.merge(opts)
    @st_soap.getPage(@st_token, opts[:page], opts[:format])
end

def set_page(opts={})
    opts = {:page => '', :content => ''}.merge(opts)
    @st_soap.setPage(@st_token, opts[:page], opts[:content])
end

def get_changes(opts={})
    opts = {:category => 'recent changes', :count => 10}.merge(opts)
    @st_soap.getChanges(@st_token, opts[:category], opts[:count])
end

def get_search(opts={})
    opts = {:query => ''}.merge(opts)
    @st_soap.getSearch(@st_token, opts[:query])
end

end
end
end
