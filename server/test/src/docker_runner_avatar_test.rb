require_relative 'runner_test_base'

class DockerRunnerAvatarTest < RunnerTestBase

  def self.hex_prefix; 'FEA56'; end
  def hex_setup; @image_name = 'cyberdojofoundation/gcc_assert'; new_kata; end
  def hex_teardown; old_kata; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '5C8',
  'new_avatar is idempotent because [docker volume create] is!!' do
    new_avatar
    new_avatar
    old_avatar
  end

  private

  def volume_name
    'cyber_dojo_' + kata_id + '_' + avatar_name
  end

end
