require_relative './runner_test_base'
require_relative './mock_sheller'

class DockerRunnerKataTest < RunnerTestBase

  def self.hex_prefix; 'FB0D4'; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'FA0',
  "[gcc,assert] old_kata removes all avatar's volumes" do
    @image_name = 'cyberdojofoundation/gcc_assert'
    new_kata
    expected = []
    ['lion','salmon'].each do |avatar_name|
      runner.new_avatar(@image_name, kata_id, avatar_name, files)
      expected << volume_name(avatar_name)
    end
    assert_equal expected, volume_names.sort
    old_kata
    assert_equal [], volume_names.sort
  end

  private

  def volume_names
    stdout,_ = assert_exec("docker volume ls --quiet --filter 'name=#{volume_name}'")
    stdout.split("\n")
  end

  def volume_name(avatar_name = nil)
    parts = [ 'cyber', 'dojo', kata_id ]
    parts << avatar_name unless avatar_name.nil?
    parts.join('_')
  end

end

