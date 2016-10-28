# coverage require must come first
require_relative '../coverage'
require 'minitest/autorun'
require_relative '../hex_mini_test'
require_relative '../../src/micro_service'
require_relative './docker_runner_helpers'
require 'json'

class RunnerTestBase < HexMiniTest

  include DockerRunnerHelpers

end
