
class MockSheller

  def initialize(_parent)
    test_id =  ENV['CYBER_DOJO_TEST_HEX_ID']
    @filename = Dir.tmpdir + '/cyber_dojo_mock_sheller_' + test_id + '.json'
    write([]) unless File.file?(filename)
  end

  # - - - - - - - - - - - - - - - - - - - - - - -

  def teardown
    mocks = read
    fail "#{filename}: uncalled mocks(#{mocks})" unless mocks == []
  end

  # - - - - - - - - - - - - - - - - - - - - - - -

  def mock_exec(command, stdout, stderr, status)
    mocks = read
    mock = { command:command,
              stdout:stdout,
              stderr:stderr,
              status:status
    }
    write(mocks << mock)
  end

  # - - - - - - - - - - - - - - - - - - - - - - -

  def exec(command, logging = true)
    mocks = read
    mock = mocks.shift
    write(mocks)
    if mock.nil?
      raise [
        self.class.name,
        "exec(command) - no mock",
        "actual-command: #{command}",
      ].join("\n") + "\n"
    end
    if command != mock['command']
      raise [
        self.class.name,
        "exec(command) - does not match mock",
        "actual-command: #{command}",
        "mocked-command: #{mock['command']}}"
      ].join("\n") + "\n"
    end
    [mock['stdout'], mock['stderr'], mock['status']]
  end

  def success
    0
  end

  private

  def read
    JSON.parse(IO.read(filename))
  end

  def write(mocks)
    IO.write(filename, JSON.unparse(mocks))
  end

  def filename
    @filename
  end

end
