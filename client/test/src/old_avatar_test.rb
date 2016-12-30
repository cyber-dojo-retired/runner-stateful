require_relative 'client_test_base'

class OldAvatarTest < ClientTestBase

  def self.hex_prefix; '33A'; end

  test '70F',
  'old_avatar with illegal volume name raises' do
    error = assert_raises { old_avatar('a', ':') }
    assert error.message.start_with? 'RunnerService:old_avatar'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  test '1ED',
  'old_avatar sunny-day scenario' do
    new_kata
    new_avatar
    old_avatar
    old_kata
  end

end
