#!/bin/bash ../test_wrapper.sh

require_relative './lib_test_base'

class MockShellerTest < LibTestBase

  def self.hex(suffix)
    'A6E' + suffix
  end

  # - - - - - - - - - - - - - - -
  # initialize
  # - - - - - - - - - - - - - - -

  test 'B51',
  'MockHostShell ctor only sets mocks=[] when file does not already exist' do
    shell_1 = MockSheller.new(nil)
    shell_1.mock_exec(pwd, wd, success)
    shell_2 = MockSheller.new(@test_id)
    output,exit_status = shell_2.exec('pwd')
    assert_equal wd, output
    assert_equal success, exit_status
    shell_2.teardown
  end

  # - - - - - - - - - - - - - - -
  # teardown
  # - - - - - - - - - - - - - - -

  test '4A5',
  'teardown does not raise when no mocks are setup and no calls are made' do
    assert_equal 'A6E4A5', ENV['RUNNER_TEST_ID']
    shell.teardown
  end

  # - - - - - - - - - - - - - - -

  test 'B4E',
  'teardown does not raise when one mock exec setup and matching exec is made' do
    shell.mock_exec(pwd, wd, success)
    output,exit_status = shell.exec('pwd')
    assert_equal wd, output
    assert_equal success, exit_status
    shell.teardown
  end

  # - - - - - - - - - - - - - - -

  test 'E93',
  'teardown does not raise when one mock cd_exec setup and matching cd_exec is made' do
    shell.mock_cd_exec(wd, pwd, wd, success)
    output,exit_status = shell.cd_exec(wd, 'pwd')
    assert_equal wd, output
    assert_equal success, exit_status
    shell.teardown
  end

  # - - - - - - - - - - - - - - -

  test 'D0C',
  'teardown raises when one mock exec setup and no calls are made' do
    shell.mock_exec(pwd, wd, success)
    assert_raises { shell.teardown }
  end

  # - - - - - - - - - - - - - - -

  test '093',
  'teardown raises when one mock cd_exec setup and no calls are made' do
    shell.mock_cd_exec(wd, pwd, wd, success)
    assert_raises { shell.teardown }
  end

  # - - - - - - - - - - - - - - -
  # cd_exec
  # - - - - - - - - - - - - - - -

  test 'F00',
  'cd_exec raises when mock for exec has been setup' do
    shell.mock_exec(pwd, wd, success)
    assert_raises { shell.cd_exec(wd, pwd) }
  end

  # - - - - - - - - - - - - - - -

  test '77C',
  'cd_exec raises when mock for cd_exec has dfferent cd-path' do
    shell.mock_cd_exec(wd, pwd, wd, success)
    assert_raises { shell.cd_exec(wd+'X', pwd) }
  end

  # - - - - - - - - - - - - - - -

  test 'E05',
  'cd_exec raises when mock for cd_exec has dfferent command' do
    shell.mock_cd_exec(wd, pwd, wd, success)
    assert_raises { shell.cd_exec(wd, pwd+pwd) }
  end

  # - - - - - - - - - - - - - - -
  # exec
  # - - - - - - - - - - - - - - -

  test '4C1',
  'exec raises when mock for cd_exec has been setup' do
    shell.mock_cd_exec(wd, pwd, wd, success)
    assert_raises { shell.exec(pwd) }
  end

  # - - - - - - - - - - - - - - -

  test '181',
  'exec raises when mock for exec has dfferent command' do
    shell.mock_exec(pwd, wd, success)
    assert_raises { shell.exec(not_pwd = "cd #{wd}") }
  end

  # - - - - - - - - - - - - - - -

  private

  def shell
    @shell ||= MockSheller.new(nil)
  end

  def pwd; ['pwd']; end
  def wd; '/Users/jonjagger/repos/web'; end
  def success; 0; end

end
