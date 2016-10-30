# coverage must come first
require_relative '../coverage'
require_relative '../hex_mini_test'
require_relative './docker_runner_helpers'
require_relative './../../src/docker_runner'
require_relative './../../src/externals'

class RunnerTestBase < HexMiniTest

  include Externals
  def runner; DockerRunner.new(self); end

  include DockerRunnerHelpers

end
