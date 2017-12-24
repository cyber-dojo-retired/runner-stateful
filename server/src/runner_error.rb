require 'json'

class RunnerError < StandardError

  def initialize(info)
    @info = info
  end

  attr_reader :info

  #def message
  #  JSON.pretty_generate(info)
  #end

end