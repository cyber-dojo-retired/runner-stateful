require_relative './nearest_ancestors'

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
      [output, status]
    rescue Exception => e
      log << line
      log << "COMMAND:#{command}"
      log << "RAISED-CLASS:#{e.class.name}"
      log << "RAISED-TO_S:#{e.to_s}"
      raise e
    end
  end

  private

  include NearestAncestors

  def log; nearest_ancestors(:log); end
  def success; 0; end
  def line; '-' * 40; end
end
