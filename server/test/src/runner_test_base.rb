# coverage require must come first
require_relative '../coverage'
#require_relative '../base'
require_relative '../../src/micro_service'
require_relative './docker_runner_helpers'
require 'json'

# This is what ../base gives you
require 'minitest/autorun'
require_relative '../hex_mini_test'
#class TestBase < HexMiniTest#MiniTest::Test
#end


class RunnerTestBase < HexMiniTest #TestBase

  include DockerRunnerHelpers

end
