require_relative './client_test_base'

class NewAvatarTest < ClientTestBase

  def self.hex_prefix; '4F725'; end

  test 'C43',
  'new_avatar with illegal volume name is error' do
    new_avatar('a', ':')
    assert_equal 'error', status
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  test '26D',
  'new_avatar with legal name succeeds' do
    new_avatar(test_id, 'salmon')
    begin
      assert_equal 0, status
    ensure
      old_avatar(test_id, 'salmon')
    end
  end

end
