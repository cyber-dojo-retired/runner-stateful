require_relative 'runner_test_base'

class DockerRunnerAvatarTest < RunnerTestBase

  def self.hex_prefix; 'FEA56'; end
  def hex_setup; @image_name = 'cyberdojofoundation/gcc_assert'; new_kata; end
  def hex_teardown; old_kata; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'DBC',
  "before new_avatar avatar's volume does not exist,",
  'after new_avatar it does' do
    refute volume_exists?
    new_avatar
    begin
      assert volume_exists?
    ensure
      old_avatar
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '9A9',
  "before old_avatar avatar's volume exists,",
  'after old_avatar its does not' do
    new_avatar
    old_avatar
    refute volume_exists?
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '5C8',
  'new_avatar is idempotent because [docker volume create] is!!' do
    new_avatar
    new_avatar
    old_avatar
  end

  private

  def volume_exists?
    name = volume_name
    stdout,_ = assert_exec("docker volume ls --quiet --filter 'name=#{name}'")
    stdout.include? volume_name
  end

  def volume_name
    'cyber_dojo_' + kata_id + '_' + avatar_name
  end

end
