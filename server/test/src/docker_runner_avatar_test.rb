require_relative 'runner_test_base'

class DockerRunnerAvatarTest < RunnerTestBase

  def self.hex_prefix; 'FEA56'; end
  def hex_setup; @image_name = 'cyberdojofoundation/gcc_assert'; new_kata; end
  def hex_teardown; old_kata; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '5C8',
  'before new_avatar sandbox does not exist, after it does' do
    #new_avatar
    #new_avatar
    #old_avatar
  end

end
