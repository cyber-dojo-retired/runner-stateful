
# NB: if you call this file app_test.rb then SimpleCov fails to see it?!

require_relative './lib_test_base'
require 'net/http'

class StarterAppTest < LibTestBase

  def self.hex(suffix)
    '202' + suffix
  end

  test '349',
  '....' do
    #@now_files = {}
    #@was_files = { 'wibble.h' => 'X'*45*1024 }
    #json = get_diff
    #refute_nil json['wibble.h']
  end

  def start
    #Runner::run(@was_files, @now_files)
  end

end
