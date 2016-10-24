
require_relative './lib_test_base'
require_relative './../../src/string_truncater'

class StringTruncaterTest < LibTestBase

  include StringTruncater

  def self.hex
    '767'
  end

  # - - - - - - - - - - - - - - - - - - - - - - -

  test '5A7',
  'output of less than 10k is not truncated' do
    output = 'x'* (10*1024 - 1)
    assert_equal output, truncated(output)
  end

  # - - - - - - - - - - - - - - - - - - - - - - -

  test 'D8F',
  'output of exactly 10k is not truncated' do
    output = 'x'* (10*1024)
    assert_equal output, truncated(output)
  end

  # - - - - - - - - - - - - - - - - - - - - - - -

  test 'A48',
  'output of greater than 10k is truncated and truncated-message is appended' do
    output = 'x'* (10*1024)
    message = 'output truncated by cyber-dojo server'
    assert_equal output + "\n" + message, truncated(output + 'x')
  end

end
