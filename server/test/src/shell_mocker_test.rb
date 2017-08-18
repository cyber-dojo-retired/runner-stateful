require_relative 'test_base'
require_relative 'shell_mocker'

class ShellMockerTest < TestBase

  def self.hex_prefix
    'F03'
  end

  # - - - - - - - - - - - - - - -

  test 'B51',
  %w( when file does not already exist
      MockSheller ctor only sets mocks=[]
  ) do
    # has to work when it is "re-created" in different threads
    shell_1 = ShellMocker.new(nil)
    shell_1.mock_exec(pwd, wd, stderr='', success)

    shell_2 = ShellMocker.new(nil)
    stdout,stderr,status = shell_2.exec(pwd)
    assert_equal wd, stdout
    assert_equal '', stderr
    assert_equal success, status
    shell_1.teardown
    shell_2.teardown
  end

  # - - - - - - - - - - - - - - -

  test '4A5',
  %w( when no mock_exec's are setup
      and no exec's are made
      teardown does not raise
  ) do
    shell = ShellMocker.new(nil)
    shell.teardown
  end

  # - - - - - - - - - - - - - - -

  test '652',
  %w( when an exec is made
      and there are no mock_exec's
      exec(command) raises
  ) do
    shell = ShellMocker.new(nil)
    assert_raises { shell.exec(pwd) }
  end

  # - - - - - - - - - - - - - - -

  test '181',
  %w( when mock_exec is for a different command
      exec(command) raises
  ) do
    shell = ShellMocker.new(nil)
    shell.mock_exec(pwd, wd, stderr='', success)
    assert_raises { shell.exec(not_pwd = "cd #{wd}") }
  end

  # - - - - - - - - - - - - - - -

  test 'B4E',
  %w( when one mock_exec is setup
      and a matching exec is made
      teardown does not raise
  ) do
    shell = ShellMocker.new(nil)
    shell.mock_exec(pwd, wd, stderr='', success)
    stdout,stderr,status = shell.exec('pwd')
    assert_equal wd, stdout
    assert_equal '', stderr
    assert_equal success, status
    shell.teardown
  end

  # - - - - - - - - - - - - - - -

  test 'D0C',
  %w( when one mock_exec setup
      and no calls are made
      teardown raises
  ) do
    shell = ShellMocker.new(nil)
    shell.mock_exec(pwd, wd, stderr='', success)
    assert_raises { shell.teardown }
  end

  # - - - - - - - - - - - - - - -

  test '470',
  %w( when there is an uncaught exception
      teardown does not raise
  ) do
    shell = ShellMocker.new(nil)
    shell.mock_exec(pwd, wd, stderr='', success)
    error = assert_raises {
      begin
        fail 'forced'
      ensure
        shell.teardown
      end
    }
    assert_equal 'forced', error.message
  end

  # - - - - - - - - - - - - - - -

  test '4FF',
  %w( when status is non-zero
      assert_exec raises
  ) do
    shell = ShellMocker.new(nil)
    shell.mock_exec('false', '', '', 1)
    error = assert_raises { shell.assert_exec('false') }
    assert_equal 'command:false', error.message
  end

  # - - - - - - - - - - - - - - -

  test '3BE',
  %w( success has a value of zero ) do
    shell = ShellMocker.new(nil)
    assert_equal 0, shell.success
  end

  private

  def pwd
    'pwd'
  end

  def wd
    '/Users/jonjagger/repos/web'
  end

  def success
    0
  end

end
