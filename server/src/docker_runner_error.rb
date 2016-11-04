
class DockerRunnerError < StandardError

  def initialize(stdout, stderr, status, command)
    @stdout = stdout.strip
    @stderr = stderr.strip
    @status = status
    @command = command
  end

  attr_reader :stdout, :stderr, :status, :command

end
