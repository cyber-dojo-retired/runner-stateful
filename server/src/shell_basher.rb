require 'open3'

class ShellBasher

  def initialize(external)
    @external = external
  end

  def assert(command)
    stdout,stderr,status = exec(command)
    unless status == success
      raise ArgumentError.new("command:#{command}")
    end
    stdout
  end

  def exec(command)
    begin
      stdout,stderr,r = Open3.capture3(command)
      status = r.exitstatus
      unless status == success
        log << line
        log << "COMMAND:#{command}"
        log << "STATUS:#{status}"
        log << "STDOUT:#{stdout}"
        log << "STDERR:#{stderr}"
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

