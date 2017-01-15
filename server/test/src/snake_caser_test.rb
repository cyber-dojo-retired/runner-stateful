require_relative 'test_base'
require_relative '../../src/snake_caser'

class SnakeCaserTest < TestBase

  include SnakeCaser

  def self.hex_prefix; 'A67'; end

  test 'C2B',
  'only two cases I need to work' do
    assert_equal 'docker_kata_container_runner', snake_cased('DockerKataContainerRunner')
    assert_equal 'docker_kata_volume_runner',    snake_cased('DockerKataVolumeRunner')
  end

end
