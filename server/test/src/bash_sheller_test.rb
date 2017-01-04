require_relative 'test_base'
require_relative 'spy_logger'

class BashShellerTest < TestBase

  def self.hex_prefix; 'C89'; end

  def hex_setup
    @log = SpyLogger.new(self)
  end

  attr_reader :log

  # - - - - - - - - - - - - - - - - -

  test 'DBB',
  'exec(cmd) succeeds with output' do
    shell_exec('echo Hello')
    assert_status 0
    assert_stdout "Hello\n"
    assert_stderr ''
    assert_log []
  end

  # - - - - - - - - - - - - - - - - -

  test '490',
  'exec(cmd) succeeds with no output' do
    shell_exec('false')
    assert_status 1
    assert_stdout ''
    assert_stderr ''
    assert_log [
      'COMMAND:false',
      'STATUS:1',
      'STDOUT:',
      'STDERR:'
    ]
  end

  # - - - - - - - - - - - - - - - - -

  test '46B',
  'exec(cmd) fails with output' do
    shell_exec('sed salmon')
    assert_status 1
    assert_stdout ''
    assert_stderr "sed: unmatched 'a'\n"
    assert_log [
      'COMMAND:sed salmon',
      'STATUS:1',
      'STDOUT:',
      "STDERR:sed: unmatched 'a'\n"
    ]
  end

  # - - - - - - - - - - - - - - - - -

  test '6D5',
  'exec(cmd,logging=false) with output' do
    shell_exec('sed salmon', logging = false)
    assert_status 1
    assert_stdout ''
    assert_stderr "sed: unmatched 'a'\n"
    assert_log []
  end

  # - - - - - - - - - - - - - - - - -

  test 'AF6',
  'exec(cmd) raises' do
    assert_raises { shell_exec('zzzz') }
    assert_log [
      'COMMAND:zzzz',
      'RAISED-CLASS:Errno::ENOENT',
      'RAISED-TO_S:No such file or directory - zzzz'
    ]
  end

  # - - - - - - - - - - - - - - - - -

  def shell_exec(command, logging = true)
    @stdout,@stderr,@status = shell.exec(command, logging)
  end

  def assert_status(expected)
    assert_equal expected, @status
  end

  def assert_stdout(expected)
    assert_equal expected, @stdout
  end

  def assert_stderr(expected)
    assert_equal expected, @stderr
  end

  def assert_log(expected)
    line = '-' * 40
    expected.unshift(line) unless expected == []
    assert_equal expected, log.spied
  end

end
