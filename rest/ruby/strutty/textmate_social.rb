#!/usr/local/bin/ruby

require '/Users/kirsten/src/clients/rest/ruby/strut.rb'

command = ARGV.shift
filename = ARGV.shift

class SocialTextMate < Social
  #
  # Textmate specific stuff here
  #
  def get_password
    return secure_standard_input_box("Socialtext",
                                     "Enter the password to login at " + @hostname)
  end

  def _standard_input_box(type, title, prompt, text = "", button1 = "Okay", button2 = "Cancel")
    require "#{ENV['TM_SUPPORT_PATH']}/lib/escape.rb"
    _result = _dialog(type, %Q{--title #{e_sh title} \
      --informative-text #{e_sh prompt} --text #{e_sh text} \
      --button1 #{e_sh button1} --button2 #{e_sh button2}})
    _result = _result.split(/\n/)
    _result[0] == '1' ? _result[1] : nil
  end

  def _dialog(type, options)
    %x{"#{ENV['TM_SUPPORT_PATH']}/bin/CocoaDialog.app/Contents/MacOS/CocoaDialog" 2>/dev/console #{type} #{options}}
  end

  def exit_show_tool_tip(out = nil)
    print out if out
    exit 206
  end

  def secure_standard_input_box(title, prompt)
    _standard_input_box('secure-standard-inputbox', title, prompt)
  end
end

Dispatcher.new(SocialTextMate, filename).dispatch(command)
