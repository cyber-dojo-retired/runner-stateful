
module TestExternalHelper

  module_function

  def setup
    external_setup
  end

  def external_setup
  end

  # - - - - - - - - - - - - - - - - - - - - -

  def teardown
    external_teardown
  end

  def external_teardown
  end

  # - - - - - - - - - - - - - - - - - - - - -

  def test_id
    ENV['TEST_ID']
  end

end
