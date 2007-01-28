require 'net/http'
require 'net/https'
require 'rexml/document'

class Tunes

  SONG_LIST_FILE = "/Users/kirsten/test.txt"
  FILEPATH       = "/data/workspaces/testspace/pages/Kirsten%20Itunes%20List"
  SERVER         = "www2.socialtext.net"
  PORT           = "443"
  USERNAME       = "kirsten.jones@socialtext.com"
  PASSWORD       = "wouldntyouliketoknow"

  attr_accessor :body, :orig

  def get_orig
    @orig = ''
    http = Net::HTTP.new(SERVER, PORT)
    http.use_ssl=true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.start do |http|
    request =
      Net::HTTP::Get.new(FILEPATH,initheader = {'Accept' => 'text/x.socialtext-wiki'})
    request.basic_auth USERNAME, PASSWORD
    response = http.request(request)
    response.value
    @orig = response.body
    end
    return @orig
  end

  def put
    req = Net::HTTP::Put.new(FILEPATH)
    req.basic_auth 'kirsten.jones@socialtext.com', 'password'
    http = Net::HTTP.new('www2.socialtext.net', 443)
       http.use_ssl=true
       http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.start { http.request(req, @body) }.body
  end
  
  def get
    require 'parsedate'
    @body = "| *Song* | *Artist* | *Time* |\n"
    url = URI.parse('http://ws.audioscrobbler.com/1.0/user/synedra/recenttracks.xml')
    req = Net::HTTP::Get.new(url.path)
    res = Net::HTTP.start(url.host, url.port) {|http|
          http.request(req)
    }
    REXML::Document.new(res.body).elements.each('//track') do |el|
      datestring = el.elements["date"].text
      vals = ParseDate::parsedate(datestring)
      time = Time.local(*vals.compact)
      time = time - (7 * 3600)
      timestr = time.strftime "%m/%d/%y %H:%M"
      @body = @body + "| " + '"' + el.elements["name"].text + '"<' + el.elements["url"].text + '> | ' + el.elements["artist"].text +  '| ' + timestr + " |\n"
    end
    return @body
  end
end  

mytunes = Tunes.new
orig = mytunes.get_orig
new = mytunes.get
if (new != orig) and (new =~ /\w/)
  mytunes.put
end
