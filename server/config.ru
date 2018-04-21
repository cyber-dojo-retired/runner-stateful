require_relative './src/external'
require_relative './src/rack_dispatcher'
require_relative './src/runner'

external = External.new
runner = Runner.new(external)
run RackDispatcher.new(runner)
