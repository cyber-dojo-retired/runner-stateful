require_relative './runner_test_base'
require_relative './mock_sheller'

class MockShellerTest < RunnerTestBase

  def self.hex_prefix; 'F03'; end

  def X_setup_mock_sheller
    @shell = MockSheller.new(nil)
  end

  #attr_reader :shell

  # - - - - - - - - - - - - - - -
  # initialize
  # - - - - - - - - - - - - - - -

  test 'B51',
  'MockSheller ctor only sets mocks=[] when file does not already exist' do
    # eg when a test issues a controller GET then it goes through the rails routers
    # which creates a new MockSheller object in a new thread.
    # So the Mock has to work when it is "re-created" in different threads
    shell_1 = MockSheller.new(nil)
    shell_1.mock_exec(pwd, wd, stderr='', success)

    shell_2 = MockSheller.new(nil)
    stdout,stderr,status = shell_2.exec('pwd')
    assert_equal wd, stdout
    assert_equal '', stderr
    assert_equal success, status
    shell_1.teardown
    shell_2.teardown
  end

  # - - - - - - - - - - - - - - -

  test '4A5',
  "teardown does not raise when no mock_exec's are setup and no exec's are made" do
    shell = MockSheller.new(nil)
    shell.teardown
  end

  # - - - - - - - - - - - - - - -

  test '181',
  'exec(command) raises when mock_exec is for a dfferent command' do
    shell = MockSheller.new(nil)
    shell.mock_exec(pwd, wd, stderr='', success)
    assert_raises { shell.exec(not_pwd = "cd #{wd}") }
  end

  # - - - - - - - - - - - - - - -

  test 'B4E',
  'teardown does not raise when one mock_exec is setup and a matching exec is made' do
    shell = MockSheller.new(nil)
    shell.mock_exec(pwd, wd, stderr='', success)
    stdout,stderr,status = shell.exec('pwd')
    assert_equal wd, stdout
    assert_equal '', stderr
    assert_equal success, status
    shell.teardown
  end

  # - - - - - - - - - - - - - - -

  test 'D0C',
  'teardown raises when one mock exec setup and no calls are made' do
    shell = MockSheller.new(nil)
    shell.mock_exec(pwd, wd, stderr='', success)
    assert_raises { shell.teardown }
  end

  # - - - - - - - - - - - - - - -

  private

  def pwd; 'pwd'; end
  def wd; '/Users/jonjagger/repos/web'; end
  def success; 0; end

end
