
require_relative './lib_test_base'
require_relative './mock_sheller'

class SudoDockerTest < LibTestBase

  def self.hex(suffix)
    '1BF' + suffix
  end

  def setup
    super
    ENV[env_name('shell')]  = 'ExternalSheller'
    ENV[env_name('log')] = 'SpyLogger'
    test_id = ENV['DIFFER_TEST_ID']
    @stdoutFile = "/tmp/cyber-dojo/stdout.#{@test_id}"
    @stderrFile = "/tmp/cyber-dojo/stderr.#{@test_id}"
  end

  def teardown
    super
  end

  attr_reader :stdoutFile, :stderrFile

  test 'B4C',
  'sudoless docker command fails with exit_status non-zero' do
    command = "docker images >#{stdoutFile} 2>#{stderrFile}"
    output, exit_status = shell.exec([command])
    refute_equal success, exit_status, '[docker image] can be run without sudo'
    assert `cat #{stderrFile}`.start_with? 'Cannot connect to the Docker daemon'
  end

  test '279',
  'sudo docker command succeeds and exits zero' do
    command = "#{sudo} docker images >#{stdoutFile} 2>#{stderrFile}"
    output, exit_status = shell.exec([command])
    assert_equal success, exit_status
    docker_images = `cat #{stdoutFile}`
    assert docker_images.include? 'cyberdojo/differ'
  end

  private

  include Externals

  def success
    0
  end

  def sudo
    'sudo -u docker-runner sudo'
  end

end
