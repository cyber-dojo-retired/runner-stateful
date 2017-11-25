require_relative 'runner_error'
require 'open3'

class ShellBasher

  def initialize(external)
    @external = external
  end

  # - - - - - - - - - - - - - - - - - - - - -

  def assert(command)
    stdout,stderr,status = open3capture3('assert', command)
    unless status == success
      raise RunnerError.new(info('assert', command, stdout, stderr, status))
    end
    stdout
  end

  # - - - - - - - - - - - - - - - - - - - - -

  def exec(command)
    stdout,stderr,status = open3capture3('exec', command)
    unless status == success
      log << info('exec', command, stdout, stderr, status)
    end
    [stdout, stderr, status]
  end

  # - - - - - - - - - - - - - - - - - - - - -

  def success
    0
  end

  private # = = = = = = = = = = = = = = = = =

  def open3capture3(method_name, command)
    stdout,stderr,r = Open3.capture3(command)
    [stdout, stderr, r.exitstatus]
  rescue StandardError => error
    raise RunnerError.new({
      'command':"shell.#{method_name}(#{quoted(command)})",
      'message':error.message
    })
  end

  # - - - - - - - - - - - - - - - - - - - - -

  def info(method, command, stdout, stderr, status)
    { 'command':"shell.#{method}(#{quoted(command)})",
      'stdout':stdout,
      'stderr':stderr,
      'status':status
    }
  end

  def log
    @external.log
  end

  def quoted(s)
    '"' + s + '"'
  end

end

