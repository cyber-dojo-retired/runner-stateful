require_relative './nearest_external'

class ExternalSheller

  def initialize(parent)
    @parent = parent
  end

  attr_reader :parent

  def exec(command, logging = true)
    begin
      output = `#{command}`
      status = $?.exitstatus
      if status != success && logging
        log << line
        log << "COMMAND:#{command}"
        log << "OUTPUT:#{output}"
        log << "STATUS:#{status}"
      end
      [output, stderr='', status]
    rescue StandardError => error
      log << line
      log << "COMMAND:#{command}"
      log << "RAISED-CLASS:#{error.class.name}"
      log << "RAISED-TO_S:#{error.to_s}"
      raise error
    end
  end

  private

  include NearestExternal
  def log; nearest_external(:log); end

  def success; 0; end
  def line; '-' * 40; end
end
