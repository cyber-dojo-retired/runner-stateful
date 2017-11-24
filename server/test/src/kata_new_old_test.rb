require_relative 'test_base'

class KataNewOldTest < TestBase

  def self.hex_prefix
    '20A7A'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'DBC', %w( resurrection requires kata_new to work after kata_old ) do
    kata_new
    kata_old
    kata_new
    kata_old
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'DBD', %w( kata_new is not idempotent ) do
    kata_new
    begin
      error = assert_raises(StandardError) { kata_new }
      assert_equal 'kata_id:exists', error.message
    ensure
      kata_old
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'DBE', %w( kata_old is not idempotent ) do
    kata_new
    kata_old
    error = assert_raises(StandardError) { kata_old }
    assert_equal 'kata_id:!exists', error.message
  end

end
