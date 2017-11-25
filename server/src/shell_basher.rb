require_relative 'runner_error'
require 'open3'

class ShellBasher

  def initialize(external)
    @external = external
  end

  # - - - - - - - - - - - - - - - - - - - - -

  def assert(command)
    stdout,stderr,r = Open3.capture3(command)
    status = r.exitstatus
    unless status == success
      raise RunnerError.new({
        'command':"shell.assert(#{quoted(command)})",
        'stdout':stdout,
        'stderr':stderr,
        'status':status
      })
    end
    stdout
  rescue RunnerError => error
    raise error
  rescue StandardError => error
    raise RunnerError.new({
      'command':"shell.assert(#{quoted(command)})",
      'stdout':stdout,
      'stderr':stderr,
      'status':status,
      'message':error.message
    })
  end

  # - - - - - - - - - - - - - - - - - - - - -

  def exec(command)
    stdout,stderr,r = Open3.capture3(command)
    status = r.exitstatus
    unless status == success
      log << {
        'command':"shell.exec(#{quoted(command)})",
        'stdout':stdout,
        'stderr':stderr,
        'status':status
      }
    end
    [stdout, stderr, status]
  rescue StandardError => error
    raise RunnerError.new({
      'command':"shell.exec(#{quoted(command)})",
      'stdout':stdout,
      'stderr':stderr,
      'status':status,
      'message':error.message
    })
  end

  def success
    0
  end

  private

  def log
    @external.log
  end

  def quoted(s)
    '"' + s + '"'
  end

end

