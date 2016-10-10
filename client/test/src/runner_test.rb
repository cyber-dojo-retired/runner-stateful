
# NB: if you call this file app_test.rb then SimpleCov fails to see it?!

require_relative './lib_test_base'
require 'net/http'

class RunnerAppTest < LibTestBase

  def self.hex(suffix)
    '201' + suffix
  end

  test '348',
  '....' do
    #@now_files = {}
    #@was_files = { 'wibble.h' => 'X'*45*1024 }
    #json = get_diff
    #refute_nil json['wibble.h']
  end


  # - - - - - - - - - - - - - - - - - - - -
  # >10k query is not reject by thin
  # - - - - - - - - - - - - - - - - - - - -

  def do_run
    # don't call this run as MiniTest gets confused
    Runner::run #(@was_files, @now_files)
  end

end
