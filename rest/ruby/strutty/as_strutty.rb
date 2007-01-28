#!/usr/local/bin/ruby

require 'strut.rb'

command = ARGV.shift
lines = STDIN.read() # lines is a string
lines_list = lines.split(/\r|\n/) # lines is an array
filename = lines_list[0]
filename = filename ? filename.chomp : ''
rest = lines_list.slice(2, lines_list.length) # rest is an array
$linestring = rest ? rest.join("\n") : ""

class Inferno < Social
  def get
    puts @filename + "\n\n" + _get()
  end

  def put
    req = Net::HTTP::Put.new(@filepath, initheader={'Content-type' => 'text/x.socialtext-wiki'})
    req.basic_auth @username, @password
    @http.start { @http.request(req, $linestring) }.body
  end
end

Dispatcher.new(Inferno, filename).dispatch(command)
