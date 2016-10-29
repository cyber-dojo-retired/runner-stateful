require_relative './runner_test_base'
require_relative './spy_logger'


class ExternalShellerTest < RunnerTestBase

  def self.hex_prefix
    'C89'
  end

  def hex_setup
    ENV[env_name('log')] = 'SpyLogger'
    @app = App.new
  end

  # - - - - - - - - - - - - - - - - -

  class App; include Externals; end

  def shell; @app.shell; end
  def log  ; @app.log  ; end

  # - - - - - - - - - - - - - - - - -

  test 'DBB',
  'when exec(cmd) succeeds:',
  '(1)output,status are captured and returned,',
  '(2)nothing is logged' do
    shell_exec('echo -n Hello')
    assert_output 'Hello'
    assert_status 0
    assert_log []
  end

  # - - - - - - - - - - - - - - - - -

  test '490',
  'when exec(cmd) with no output fails:',
  '(1)output,status are captured and returned,',
  '(2)cmd,output,status are logged' do
    shell_exec('false')
    assert_output ''
    assert_status 1
    assert_log [
      'COMMAND:false',
      'OUTPUT:',
      'STATUS:1'
    ]
  end

  # - - - - - - - - - - - - - - - - -

  test '46B',
  'when exec(cmd) with output fails:',
  '(1)output,status are captured and returned',
  '(2)cmd,output,status are logged' do
    shell_exec('sed salmon 2>&1')
    assert_output "sed: unmatched 'a'\n"
    assert_status 1
    assert_log [
      'COMMAND:sed salmon 2>&1',
      "OUTPUT:sed: unmatched 'a'\n",
      'STATUS:1'
    ]
  end

  # - - - - - - - - - - - - - - - - -

  test 'AF6',
  'when exec() raises:',
  '(0)exception is raised,',
  '(1)output is captured,' +
  '(2)exit-status is not success,',
  '(3)log records failure' do
    assert_raises { shell_exec('zzzz') }
    assert_log [
      'COMMAND:zzzz',
      'RAISED-CLASS:Errno::ENOENT',
      'RAISED-TO_S:No such file or directory - zzzz'
    ]
  end

  # - - - - - - - - - - - - - - - - -

  def shell_exec(command)
    @output, @status = shell.exec(command)
  end

  def assert_output(expected)
    assert_equal expected, @output
  end

  def assert_status(expected)
    assert_equal expected, @status
  end

  def assert_log(expected)
    line = '-' * 40
    expected = [line] + expected if expected != []
    assert_equal expected, log.spied
  end

end
