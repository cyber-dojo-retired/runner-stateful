
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
    # NB: sudoless [docker images]...
    # o) locally on a Mac using Docker-Toolbox it _can_ be run, and this test fails
    # o) on a proper Travis CI Linux box it can't be run, and this test passes
    command = "docker images >#{stdoutFile} 2>#{stderrFile}"
    output, exit_status = shell.exec([command])
    refute_equal success, exit_status, '[docker image] can be run without sudo!!'
    assert `cat #{stderrFile}`.start_with? 'Cannot connect to the Docker daemon'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '279',
  'sudo docker command succeeds and exits zero' do
    # NB: sudo [docker images]...
    # o) locally on a Mac using Docker-Toolbox this test is no good (see above)
    # o) on a proper Travis CI Linux box this test is currently passing...
    command = "#{sudo} docker images >#{stdoutFile} 2>#{stderrFile}"
    output, exit_status = shell.exec([command])
    assert_equal success, exit_status
    docker_images = `cat #{stdoutFile}`
    assert docker_images.include? 'cyberdojo/runner'
  end

    # - - - - - - - - - - - - - - - - - - - - - - - - - -
    # Why do the above tests break on Docker-Toolbox setup?
    # Get them working on both?
    # Detect if on Docker-Toolbox and don't run?
    # - - - - - - - - - - - - - - - - - - - - - - - - - -
    # On Ubuntu 14.04 host, after installing docker,
    # if you [$ cat /etc/group] you see
    #    docker:x:999:
    # if you [$ cd /var/run && ls -al] you see
    #    srw-rw----  1 root     docker        0 Oct 19 10:17 docker.sock
    #
    # On Mac with Docker-Toolbox
    # $ docker-machine ssh default
    # $ whoami
    # $ docker run --rm -i --tty --volume=/var/run/docker.sock:/var/run/docker.sock \
    #     cyberdojo/runner:1.12.2 sh
    # $ cd /var/run
    # $ ls -al
    # srw-rw----    1 root     users            0 Oct 14 19:33 docker.sock
    # $ cat /etc/group
    # users:x:100:games
    #
    #
    #
    # Inside the runner:1.12.2 container on Mac with Docker-Toolbox
    # if you [$ cat /etc/group] you see
    #    ping:x:999:
    # if you [$ cd /var/run && ls -al] you see
    #    srw-rw----  1 root     ping          0 Oct 19 10:17 docker.sock
    #
    # So owner:rw-
    #    group:rw-
    #    everyone:---
    #
    # - - - - - - - - - - - - - - - - - - - - - - - - - -
    # On Ubuntu 14.04 host, after installing docker,
    # if you [$ cd /usr/bin && ls -al docker*] you see
    # -rwxr-xr-x 1 root root 15096408 Oct 11 18:19 docker
    #
    # Inside the runner:1.12.2 container
    # $ if you [$ cd /usr/bin && ls -al docker*]
    # -rwxr-xr-x 1 root root 15673856 Oct 11 17:05 docker
    #
    # - - - - - - - - - - - - - - - - - - - - - - - - - -

  private

  include Externals

  def success
    0
  end

  def sudo
    'sudo -u docker-runner sudo'
  end

end
