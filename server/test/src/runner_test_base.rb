require_relative '../all'
require_relative './docker_runner_helpers'

class RunnerTestBase < TestBase

  include DockerRunnerHelpers

end
