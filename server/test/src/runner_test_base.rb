# coverage require must come first
require_relative '../coverage'
require_relative '../base'
require_relative '../../src/micro_service'
require_relative './docker_runner_helpers'
require 'json'

class RunnerTestBase < TestBase

  include DockerRunnerHelpers

end
