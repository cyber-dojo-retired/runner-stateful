require_relative 'disk'
require_relative 'shell_basher'
require_relative 'logger_stdout'

class External

  def shell
    @shell ||= ShellBasher.new(self)
  end
  def shell=(doppel)
    @shell = doppel
  end

  def disk
    @disk ||= Disk.new
  end

  def log
    @log ||= LoggerStdout.new(self)
  end

end
