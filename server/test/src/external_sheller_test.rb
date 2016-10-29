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
  'when exec() succeeds:' +
  '(1)output is captured,' +
  '(2)exit-status is success,' +
  '(3)log records success' do
    shell_exec('echo -n Hello')
    assert_output 'Hello'
    assert_exit_status success
    assert_log [
      'COMMAND:echo -n Hello',
      'OUTPUT:Hello',
      'EXITED:0'
    ]
  end

  # - - - - - - - - - - - - - - - - -

  test 'AF6',
  'when exec() fails:' +
  '(0)exception is raised,' +
  '(1)output is captured,' +
  '(2)exit-status is not success,' +
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
    @output, @exit_status = shell.exec(command)
  end

  def assert_output(expected)
    assert_equal expected, @output
  end

  def assert_exit_status(expected)
    assert_equal expected, @exit_status
  end

  def assert_log(expected)
    line = '-' * 40
    assert_equal [line] + expected, log.spied
  end

  def success
    0
  end

end
