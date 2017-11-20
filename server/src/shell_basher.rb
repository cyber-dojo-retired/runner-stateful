require 'open3'

class ShellBasher

  def initialize(external)
    @external = external
  end

  def assert(command)
    stdout,_stderr,status = exec(command)
    unless status == success
      raise ArgumentError.new("command:#{command}")
    end
    stdout
  end

  def exec(command, verbose = log)
    begin
      stdout,stderr,r = Open3.capture3(command)
      status = r.exitstatus
      unless status == success
        verbose << line
        verbose << "COMMAND:#{command}"
        verbose << "STATUS:#{status}"
        verbose << "STDOUT:#{stdout}"
        verbose << "STDERR:#{stderr}"
      end
      [stdout, stderr, status]
    rescue StandardError => error
      log << line
      log << "COMMAND:#{command}"
      log << "RAISED-CLASS:#{error.class.name}"
      log << "RAISED-TO_S:#{error.to_s}"
      raise error
    end
  end

  def success
    0
  end

  private

  def log
    @external.log
  end

  def line
    '-' * 40
  end

end

