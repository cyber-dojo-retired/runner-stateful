require_relative 'test_base'

class RunTest < TestBase

  def self.hex_prefix; '58410'; end

  def hex_setup; @image_name = 'cyberdojofoundation/gcc_assert'; end

=begin
  test 'D7B',
  'run with an invalid kata_id raises' do
    invalid_kata_ids.each do |invalid_kata_id|
      assert_raises_kata_id(invalid_kata_id)
    end
  end

  def assert_raises_kata_id(kata_id)
    error = assert_raises(ArgumentError) {
      runner_run( { kata_id:kata_id })
    }
    assert error.message.start_with? 'kata_id'
  end
=end

end
