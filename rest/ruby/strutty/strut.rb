require 'net/https'
require "net/http"
require 'uri'
require 'date'

ST_CONFIG_FILE = File.expand_path("~/Library/Preferences/com.ruby.socialtext.txt")

class Dispatcher

  def initialize(klass, filename)
    configs = {}
    if File.exist?(ST_CONFIG_FILE)
      IO.readlines(ST_CONFIG_FILE).each do | line |
        next if line =~ /^\s*#/
          if line =~ /^(.+?):\s+(.+?)$/
            configs[$1] = $2
          end
      end
    end

    if !filename or not filename.match(/\w/)
      now = Time.new
      datestring = now.strftime(", %Y-%m-%d")
      filename = configs['postprefix'] + datestring
    end

    configs['filename'] = filename

    configs['filepath'] = '/data/workspaces/' + configs['workspace'] + '/pages/' + URI.escape(filename)

    @courier = klass.new(configs)
  end

  def dispatch(command)
    if (command == 'get')
      @courier.get
    elsif (command == 'put')
      @courier.put
    elsif (command == 'newpost')
      @courier.newpost
      @courier.get
    else
      puts "You dumb."
    end
  end
end

class Social

  attr_accessor :configs, :var, :value

  def initialize(configs)
    # convert all key/value pairs to instance variables
    configs.each { |k, v| instance_variable_set(('@' + k).to_sym, v) }

    @protocol = @port =~ /443/ ? 'https' : 'http'

    @http = Net::HTTP.new(@hostname, @port)

    if (@protocol == 'https')
       @http.use_ssl=true
       @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    fetch_credentials_from_keychain()
    at_exit { finalize() }
  end

  def finalize
    finally_save_internet_password() if @save_password_on_success
  end

  #
  # Password diddling
  #

  def keychain_add_internet_password(user, proto, host, path, pass)
    %x{security add-internet-password -a "#{user}" -s "#{host}" -r "#{proto}" -p "#{path}" -w "#{pass}"}
  end

  def keychain_find_internet_password(user, proto, host, path)
    result = %x{security find-internet-password -g -a "#{user}" -s "#{host}" -p "#{path}" -r #{proto} 2>&1 >/dev/null}
    result =~ /^password: "(.*)"$/ ? $1 : nil
  end

  def find_internet_password
    keychain_find_internet_password(@username, @protocol, @hostname, @workspace)
  end

  def finally_save_internet_password
    keychain_add_internet_password(@username, @protocol, @hostname, @workspace, @password)
  end

  def fetch_credentials_from_keychain
     if @password == nil
       @password = find_internet_password()
       if @password == nil
         @password = get_password()
         exit_discard if @password == nil
         @save_password_on_success = true
       end
     end
  end

  def exit_discard
    exit 200
  end

  def get_password
    print "Enter a password: "
    $stdout.flush
    s = gets
    s = s.chomp!
    return s.chomp
  end

  #
  # These are the actual 'doers'
  #

  def _get
    @http.start do |@http|
    request =
        Net::HTTP::Get.new(@filepath,
                           initheader = {'Accept' => 'text/x.socialtext-wiki'})
    request.basic_auth @username, @password
    response = @http.request(request)
    response.value
    return response.body
    end
  end

  def get
    puts _get()
  end

  def put
    lines = STDIN.readlines
    linestring = lines.join
    req = Net::HTTP::Put.new(@filepath, initheader={'Content-type' => 'text/x.socialtext-wiki'})
    req.basic_auth @username, @password
    @http.start { @http.request(req, linestring) }.body
  end

  def newpost
    req = Net::HTTP::Put.new(@filepath, initheader={'Content-type' => 'text/x.socialtext-wiki'})
    req.basic_auth @username, @password
    @http.start { @http.request(req, 'Write your nifty new post here') }.body

    categories = @categories.scan(/\"[^\"]+\"/)
    categories.each do | category |
       category = category.gsub(/\"/, '')
       path = @filepath + '/tags/' + URI::escape(category)
       req = Net::HTTP::Put.new(path)
       req.basic_auth @username, @password
       @http.start { @http.request(req) }.body
    end
  end
end
