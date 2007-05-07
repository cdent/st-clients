module Socialtext
module Resting

require 'net/https'
require 'uri'
require 'json'

Routes = {
    'page'           => '/data/workspaces/:ws/pages/:pname',
    'pages'          => '/data/workspaces/:ws/pages',
    'pagetag'        => '/data/workspaces/:ws/pages/:pname/tags/:tag',
    'pagetags'       => '/data/workspaces/:ws/pages/:pname/tags',
    'pagecomments'   => '/data/workspaces/:ws/pages/:pname/comments',
    'pageattachment' => '/data/workspaces/:ws/pages/:pname/attachments/:attachment_id',
    'pageattachments'      => '/data/workspaces/:ws/pages/:pname/attachments',
    'taggedpages'          => '/data/workspaces/:ws/tags/:tag/pages',
    'workspace'            => '/data/workspaces/:ws',
    'workspaces'           => '/data/workspaces',
    'workspacetag'         => '/data/workspaces/:ws/tags/:tag',
    'workspacetags'        => '/data/workspaces/:ws/tags',
    'workspaceattachment'  => '/data/workspaces/:ws/attachments/:attachment_id',
    'workspaceattachments' => '/data/workspaces/:ws/attachments',
    'workspaceuser'        => '/data/workspaces/:ws/users/:user_id',
    'workspaceusers'       => '/data/workspaces/:ws/users',
    'user'                 => '/data/users/:user_id',
    'users'                => '/data/users',
}

DefaultRequestArgs = {
    :method => 'Get',
    :content_type => 'text/x.socialtext-wiki',
    :content => "",
    :accept => "",
    :path => ""
}

Username = 'devnull1@socialtext.com'
Password = 'd3vnu11l'

attr_accessor :workspace
attr_accessor :server
attr_accessor :accept
attr_accessor :username
attr_accessor :password

def add_comment(pname="", comment="")
    uri = make_uri('pagecomments', :ws => self.workspace, :pname => pname)
    request(:method => 'Post', :url => uri, :content => comment)
end

def get_page(pname="")
    uri = make_uri('page', :ws => self.workspace, :pname => pname)
    request(:method => 'Get', :url => uri, :accept => self.accept)
end

def put_page(pname="", content="", content_type='text/x.socialtext-wiki')
    uri = make_uri('page', :ws => self.workspace, :pname => pname)
    request(:method => 'Put', 
            :url => uri, 
            :content_type => content_type, 
            :content => content)
end

def get_workspaces()
    uri = make_uri('workspaces')
    get_collection(:url => uri, :accept => self.accept)
end

def get_pages(query={})
    uri = make_uri('pages', {:ws => self.workspace}, query)
    get_collection(:url => uri, :accept => self.accept)
end

def get_pagetags(pname)
    uri = make_uri('pagetags', :ws => self.workspace, :pname => pname)
    get_collection(:url => uri, :accept => self.accept)
end

def get_pageattachments(pname)
    uri = make_uri('pageattachments', :ws => self.workspace, :pname => pname)
    get_collection(:url => uri, :accept => self.accept)
end

def get_taggedpages(tag)
    uri = make_uri('taggedpages', :ws => self.workspace, :tag => tag)
    get_collection(:url => uri, :accept => self.accept)
end

def request(opts)
    opts= DefaultRequestArgs.merge(opts)
    url = URI.parse(self.server + opts[:url][:path])
    path = opts[:url][:path] + opts[:url][:query]

    req = make_request(opts.merge(:path => path))
    #req.basic_auth Username, Password
    req.basic_auth self.username, self.password

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = (url.scheme == 'https')
    #http.ca_path = './cacert.pem'
    #http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    res = http.request(req)
    if res.is_a? Net::HTTPOK
        if res.content_type == 'application/json'
            return JSON.parse(res.body)
        else
            return res.body
        end
    else
        return res.code + " " + res.message
    end
end

private

def get_collection(opts)
    res = request(opts.merge({:method => 'Get'}))
    if opts[:accept] == "text/plain"
        res.split("\n")
    else
        res
    end
end

def make_request(opts={})
    opts = DefaultRequestArgs.merge(opts)
    req = eval("Net::HTTP::#{opts[:method]}").new(opts[:path])
    req.body = opts[:content]
    req.content_type = opts[:content_type] 
    req['Accept'] = opts[:accept]
    return req
end

def make_uri(route, opts={}, query={})
    uri = Routes[route]
    opts.each_pair {|var, value| uri.gsub!(":#{var}", URI.escape(value))}
    qs = query.size ? '?' : ''
    params = []
    query.each_pair {|x, y| params << [x.to_s, URI.escape(y.to_s)]}
    qs += params.map {|e| e.join('=')}.join('&')
    return {
        :server => self.server,
        :path => uri,
        :query => qs,
    }
end

end
end
