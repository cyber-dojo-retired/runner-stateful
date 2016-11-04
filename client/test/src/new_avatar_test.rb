require_relative './client_test_base'

class NewAvatarTest < ClientTestBase

  def self.hex_prefix; '4F725'; end

  test 'C43',
  'new_avatar with illegal volume name is non-zero integer error' do
    new_avatar('a', ':')
    assert_equal 'Fixnum', status.class.name
    refute_equal completed, status
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  test '26D',
  'new_avatar with legal name succeeds' do
    new_avatar(test_id, 'salmon')
    begin
      assert_equal completed, status
    ensure
      old_avatar(test_id, 'salmon')
    end
  end

end
