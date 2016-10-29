# coverage must come first
require_relative '../coverage'
require_relative '../hex_mini_test'
require_relative '../../src/micro_service'
# docker_runner_helpers must come last
require_relative './docker_runner_helpers'

class RunnerTestBase < HexMiniTest

  include DockerRunnerHelpers

end
