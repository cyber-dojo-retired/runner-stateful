require_relative './runner_test_base'

class DockerRunnerStoringTest < RunnerTestBase

  def self.hex_prefix; 'FEA56'; end
  def hex_setup; @image_name = 'cyberdojofoundation/gcc_assert'; new_kata; end
  def hex_teardown; old_kata; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'DBC',
  'before new_avatar volume does not exist,',
  'after new_avatar it does' do
    refute volume_exists?
    _,_,status = new_avatar
    begin
      assert_equal success, status
      assert volume_exists?
    ensure
      old_avatar
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '9A9',
  'before old_avatar volume exists,',
  'after old_avatar its does not' do
    new_avatar
    old_avatar
    refute volume_exists?
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '5C8',
  'new_avatar is idempotent' do
    _,_,status = new_avatar
    begin
      assert_equal success, status
      _,_,status = new_avatar
      assert_equal success, status
    ensure
      old_avatar
    end
  end

  private

  def volume_exists?
    volume_name = 'cyber_dojo_' + kata_id + '_' + avatar_name
    stdout, _ = assert_exec('docker volume ls')
    stdout.include? volume_name
  end

end
