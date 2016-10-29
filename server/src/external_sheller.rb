require_relative './nearest_ancestors'
require_relative './string_cleaner'

class ExternalSheller

  def initialize(parent)
    @parent = parent
  end

  attr_reader :parent

  def exec(*commands)
    command = commands.join(' && ')
    begin
      output = `#{command}`
    rescue Exception => e
      log << '-' * 40
      log << "COMMAND:#{command}"
      log << "RAISED-CLASS:#{e.class.name}"
      log << "RAISED-TO_S:#{e.to_s}"
      raise e
    end

    status = $?.exitstatus
    if status != success
      log << '-' * 40
      log << "COMMAND:#{command}"
      log << "OUTPUT:#{output}"
      log << "STATUS:#{status}"
    end
    [cleaned(output), status]
  end

  private

  include NearestAncestors
  include StringCleaner

  def log; nearest_ancestors(:log); end
  def success; 0; end

end
