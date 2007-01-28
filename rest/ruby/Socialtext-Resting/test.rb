#!/usr/bin/env ruby
$: << "."

require 'Resting.rb'

class Test
    include Socialtext::Resting
end

def section(name)
    puts "\n========== #{name.upcase} =========="
end

Server = 'http://talc.socialtext.net:21022'

section('Raw Put Request')
puts Test.new.request(:method => 'Put', 
                      :url => "#{Server}/data/workspaces/admin/pages/admin_wiki", 
                      :content => "^ Cows\nlike me")

section('Raw Post Request')
puts Test.new.request(:method => 'Post', 
                      :url => "#{Server}/data/workspaces/admin/pages/admin_wiki/comments", 
                      :content => "hello world")

section('Creating Test Object')
t = Test.new
t.server = Server
t.workspace = 'admin'

section('comments')
puts t.add_comment("Admin Wiki", "cows ate matthew")

section('get page')
t.accept = 'text/html'
puts t.get_page("Admin Wiki")

section('put page')
t.accept = 'text/html'
puts t.put_page("Admin Wiki", "COWS ARE AWESOME")

section('get workspaces')
t.accept = 'text/plain'
puts t.get_workspaces()

section('get pages')
t.accept = 'text/plain'
puts t.get_pages()

section('get page tags')
t.accept = 'text/plain'
puts t.get_pagetags("admin_wiki")

section('get page tags (as json)')
t.accept = 'application/json'
p t.get_pagetags("admin_wiki")

section('get page attachments')
t.accept = 'text/plain'
puts t.get_pageattachments("FormattingTest")

section('get page attachments')
t.accept = 'text/plain'
puts t.get_taggedpages("watch")
