require_relative 'all_avatars_names'
require_relative 'nearest_ancestors'
require_relative 'logger_null'
require_relative 'string_cleaner'
require_relative 'string_truncater'
require 'timeout'

module DockerRunnerMixIn

  def initialize(parent, image_name, kata_id)
    @parent = parent
    @image_name = image_name
    @kata_id = kata_id
    assert_valid_image_name
    assert_valid_kata_id
  end

  attr_reader :parent # For nearest_ancestors()
  attr_reader :image_name
  attr_reader :kata_id

  def image_exists?
    stdout,_ = assert_exec("docker search #{image_name}")
    lines = stdout.split("\n")
    lines.shift # HEADINGS
    images = lines.map { |line| line.split[0] }
    images.include? image_name
  end

  # - - - - - - - - - - - - - - - - - -

  def image_pulled?
    image_names.include? image_name
  end

  # - - - - - - - - - - - - - - - - - -

  def image_pull
    # [1] The contents of stderr seem to vary depending
    # on what your running on, eg DockerToolbox or not
    # and where, eg Travis or not. I'm using 'not found'
    # as that always seems to be present.
    _stdout,stderr,status = quiet_exec("docker pull #{image_name}")
    if status == shell.success
      return true
    elsif stderr.include?('not found') # [1]
      return false
    else
      fail stderr
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def group; 'cyber-dojo'; end
  def gid; 5000; end

  def user_id(avatar_name)
    assert_valid_avatar_name(avatar_name)
    40000 + all_avatars_names.index(avatar_name)
  end

  def home_dir(avatar_name)
    assert_valid_avatar_name(avatar_name)
    "/home/#{avatar_name}"
  end

  def avatar_dir(avatar_name)
    # TODO?: change to sandbox_dir
    assert_valid_avatar_name(avatar_name)
    "#{sandboxes_root_dir}/#{avatar_name}"
  end

  def sandboxes_root_dir; '/sandboxes'; end
  def timed_out; 'timed_out'; end

  module_function

  include StringCleaner
  include StringTruncater

  def image_names
    cmd = 'docker images --format "{{.Repository}}"'
    stdout,_ = assert_exec(cmd)
    names = stdout.split("\n")
    names.uniq - ['<none>']
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def run_timeout(docker_cmd, max_seconds)
    r_stdout, w_stdout = IO.pipe
    r_stderr, w_stderr = IO.pipe
    pid = Process.spawn(docker_cmd, {
      pgroup:true,
         out:w_stdout,
         err:w_stderr
    })
    begin
      Timeout::timeout(max_seconds) do
        Process.waitpid(pid)
        status = $?.exitstatus
        w_stdout.close
        w_stderr.close
        stdout = truncated(cleaned(r_stdout.read))
        stderr = truncated(cleaned(r_stderr.read))
        [stdout, stderr, status]
      end
    rescue Timeout::Error
      # Kill the [docker exec] processes running
      # on the host. This does __not__ kill the
      # cyber-dojo.sh process running __inside__
      # the docker container. See
      # https://github.com/docker/docker/issues/9098
      Process.kill(-9, pid)
      Process.detach(pid)
      ['', '', timed_out]
    ensure
      w_stdout.close unless w_stdout.closed?
      w_stderr.close unless w_stderr.closed?
      r_stdout.close
      r_stderr.close
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def alpine_add_group_cmd
    "addgroup -g #{gid} #{group}"
  end

  def ubuntu_add_group_cmd
    "addgroup --gid #{gid} #{group}"
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def alpine_add_user_cmd(avatar_name)
    # Alpine linux has an existing web-proxy user
    # called squid which I have to work round.
    # See avatar_exists?() in docker_avatar_volume_runner.rb
    home = home_dir(avatar_name)
    uid = user_id(avatar_name)
    [ "(deluser #{avatar_name}",
       ';',
       'adduser',
         '-D',             # don't assign a password
         "-G #{group}",
         "-h #{home}",
         '-s /bin/sh',     # shell
         "-u #{uid}",
         avatar_name,
      ')'
    ].join(space)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def ubuntu_add_user_cmd(avatar_name)
    home = home_dir(avatar_name)
    uid = user_id(avatar_name)
    [ 'adduser',
        '--disabled-password',
        '--gecos ""',          # don't ask for details
        "--home #{home}",
        "--ingroup #{group}",
        "--uid #{uid}",
        avatar_name
    ].join(space)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def create_volume_cmd(name)
    "docker volume create --name #{name}"
  end

  def remove_volume_cmd(name)
    "docker volume rm #{name}"
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_valid_image_name
    unless valid_image_name?
      fail_image_name('invalid')
    end
  end

  def valid_image_name?
    # http://stackoverflow.com/questions/37861791/
    # https://github.com/docker/docker/blob/master/image/spec/v1.1.md
    # Simplified, no hostname, no :tag
    alpha_numeric = '[a-z0-9]+'
    separator = '[_.-]+'
    component = "#{alpha_numeric}(#{separator}#{alpha_numeric})*"
    name = "#{component}(/#{component})*"
    tag = '[\w][\w.-]{0,127}'
    image_name =~ /^(#{name})(:#{tag})?$/o
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_valid_kata_id
    unless valid_kata_id?
      fail_kata_id('invalid')
    end
  end

  def valid_kata_id?
    kata_id.class.name == 'String' &&
      kata_id.length == 10 &&
        kata_id.chars.all? { |char| hex?(char) }
  end

  def hex?(char)
    '0123456789ABCDEF'.include?(char)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_valid_avatar_name(avatar_name)
    unless valid_avatar_name?(avatar_name)
      fail_avatar_name('invalid')
    end
  end

  include AllAvatarsNames

  def valid_avatar_name?(avatar_name)
    all_avatars_names.include?(avatar_name)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def fail_image_name(message)
    fail bad_argument("image_name:#{message}")
  end

  def fail_kata_id(message)
    fail bad_argument("kata_id:#{message}")
  end

  def fail_avatar_name(message)
    fail bad_argument("avatar_name:#{message}")
  end

  def bad_argument(message)
    ArgumentError.new(message)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_exec(cmd)
    shell.assert_exec(cmd)
  end

  def quiet_exec(cmd)
    shell.exec(cmd, LoggerNull.new(self))
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - -

  def success; shell.success; end
  def space; ' '; end

  include NearestAncestors

  def ragger; nearest_ancestors(:ragger); end

  def shell; nearest_ancestors(:shell); end
  def  disk; nearest_ancestors(:disk ); end
  def   log; nearest_ancestors(:log  ); end

end

