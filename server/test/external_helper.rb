
module TestExternalHelper # mix-in

  module_function

  def setup
    @config = {}
    env_map.keys.each { |key| @config[key] = ENV[key] }
    external_setup
  end

  def external_setup
  end

  # - - - - - - - - - - - - - - - - - - - - -

  def teardown
    env_map.keys.each { |key| ENV[key] = @config[key] }
    external_teardown
  end

  def external_teardown
  end

  # - - - - - - - - - - - - - - - - - - - - -

  def test_id
    ENV['RUNNER_TEST_ID']
  end

end
