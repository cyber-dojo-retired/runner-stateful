require_relative './nearest_ancestors'
require_relative './string_cleaner'

class ExternalSheller

  def initialize(parent)
    @parent = parent
  end

  attr_reader :parent

  def exec(*commands)
    command = commands.join(' && ')
    log << '-'*40
    log << "COMMAND:#{command}"

    begin
      output = `#{command}`
    rescue Exception => e
      log << "RAISED-CLASS:#{e.class.name}"
      log << "RAISED-TO_S:#{e.to_s}"
      raise e
    end

    status = $?.exitstatus
    log << "NO-OUTPUT:" if output == ''
    log << "OUTPUT:#{output}" if output != ''
    log << "EXITED:#{status}"
    [cleaned(output), status]
  end

  private

  include NearestAncestors
  include StringCleaner

  def log; nearest_ancestors(:log); end

end
