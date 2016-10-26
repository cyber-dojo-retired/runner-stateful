require_relative './env_vars'
require_relative './name_of_caller'

module Externals

  def disk ; @disk  ||= external; end
  def log  ; @log   ||= external; end
  def shell; @shell ||= external; end

  private

  def external
    name = env_name(name_of(caller))
    var = ENV[name] || fail("ENV[#{name}] not set")
    Object.const_get(var).new(self)
  end

  include NameOfCaller

end
