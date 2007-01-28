#!/usr/bin/env ruby
# -*- coding: utf-8 -*- vim:fileencoding=utf-8:

require 'socialtext/soap'
require 'getoptlong'

DefaultOpts = {
    :wsdl => 'https://www.socialtext.net/static/wsdl/0.9.wsdl',
    :username => 'soap.test@socialtext.com',
    :password => 'bubbles',
    :workspace => 'st-soap-test',
    :page_name => 'Soap Test',
    :other_user => 'devnull11@socialtext.com'
}

getopt = GetoptLong.new(
    [ '--workspace',  '-W', GetoptLong::OPTIONAL_ARGUMENT ],
    [ '--wsdl',       '-w', GetoptLong::OPTIONAL_ARGUMENT ],
    [ '--username',   '-u', GetoptLong::OPTIONAL_ARGUMENT ],
    [ '--password',   '-p', GetoptLong::OPTIONAL_ARGUMENT ],
    [ '--page-name',  '-P', GetoptLong::OPTIONAL_ARGUMENT ],
    [ '--other-user', '-o', GetoptLong::OPTIONAL_ARGUMENT ],
    [ '--help',       '-h', GetoptLong::NO_ARGUMENT ]
)

opts = DefaultOpts
getopt.each do |key,value|
    key.gsub!("--", "");
    key.gsub!("-", "_");
    opts[key.to_sym] = value
end

if opts[:help]
    puts <<USAGE 
USAGE ./st-client.rb [OPTIONS]
OPTIONS:
  --workspace,-W  Set workspace (default '#{DefaultOpts[:workspace]}')
  --wsdl,-w       Set URL to wsdl (default '#{DefaultOpts[:wsdl]}')
  --username,-u   Set username (default '#{DefaultOpts[:username]}')
  --password,-p   Set password (default '#{DefaultOpts[:password]}')
  --page-name,-P  Set page to access (default '#{DefaultOpts[:page_name]}')
  --other-user,-u Set user to act_as (default '#{DefaultOpts[:other_user]}')
  --help,-h       This text.
USAGE
    exit 1
end

class MyClient
    include Socialtext::Soap::Client
    def initialize(*opts)
        self.st_init(*opts)
    end
end

st = MyClient.new(opts)
page_name = opts[:page_name]
other_user = opts[:other_user]

# Test the Heartbeat
puts "=== HEARTBEAT ==="
puts st.heartbeat()

# Get page
puts
puts "=== GET PAGE " + page_name + " ==="
puts st.get_page(:page => page_name, :format => 'wikitext').pageContent

# Set page
puts
puts "=== SET PAGE " + page_name + " ==="
page = st.set_page(:page => page_name, :content => 'this is tensegrity')
puts page.pageContent

# Make a new page
# Note that ruby pays no attention to the encoding set in your locale, and
# neither do we.  We assume here that your terminal expects UTF-8.
NEW_PAGE_NAME = '99¢ Veggieburger'
NEW_PAGE_BODY = <<'EOF'
At McSOAPie's™, you can get a Veggieburger™ for only 99¢.
EOF
puts
puts "=== MAKE #{NEW_PAGE_NAME} ===";
puts st.set_page(:page => NEW_PAGE_NAME, :content => NEW_PAGE_BODY).pageContent

# sleep a while to let indexing complete
sleep 10 

# Search for the changes
puts
puts "=== SEARCH tensegrity ==="
st.get_search(:query => 'tensegrity').each { |item|
    puts "#{item.subject} #{item.author} #{item.date}"
}

# Recent Changes
puts
puts "=== RECENT CHANGES ==="
st.get_changes(:count => 2).each { |item|
    puts "#{item.subject} #{item.author} #{item.date}"
}

# Set page as someone else
puts
puts "=== SET PAGE " + page_name + " as " + other_user + " ==="
st.st_act_as = other_user
puts st.set_page(:page => page_name, :content => 'I like cows').pageContent
