
class LoggerStdout

  def initialize(_parent)
  end

  def <<(message)
    #STDERR.puts "LoggerStdout<<:#{message}:"
    p message
  end

end
