require_relative 'all_avatars_names'
require_relative 'string_cleaner'
require_relative 'string_truncater'
require_relative 'valid_image_name'
require 'timeout'

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Uses a new short-lived docker container per run.
# Uses a long-lived docker volume per kata.
#
# Positives:
#   o) avatars can share disk-state
#      (eg sqlite database in /sandboxes/shared)
#   o) short-lived container per run() is pretty secure.
#
# Negatives:
#   o) avatars cannot share processes.
#   o) bit slower than runner_processful.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

class Runner # stateful

  def initialize(external, image_name, kata_id)
    @external = external
    @image_name = image_name
    @kata_id = kata_id
    assert_valid_image_name
    assert_valid_kata_id
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # image
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def image_pulled?
    cmd = 'docker images --format "{{.Repository}}"'
    shell.assert(cmd).split("\n").include?(image_name)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def image_pull
    # [1] The contents of stderr vary depending on Docker version
    docker_pull = "docker pull #{image_name}"
    _stdout,stderr,status = shell.exec(docker_pull)
    if status == shell.success
      return true
    elsif stderr.include?('not found') || stderr.include?('not exist')
      return false # [1]
    else
      argument_error('image_name', 'invalid')
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # kata
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def kata_new
    refute_kata_exists
    create_kata_volume
    nil
  end

  def kata_old
    assert_kata_exists
    remove_kata_volume
    nil
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # avatar
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def avatar_new(avatar_name, starting_files)
    @avatar_name = avatar_name
    assert_kata_exists
    in_container {
      refute_avatar_exists
      make_and_chown_dirs
      Dir.mktmpdir { |tmp_dir|
        save_to(starting_files, tmp_dir)
        shell.assert(tar_pipe_cmd(tmp_dir, 'true'))
      }
    }
    nil
  end

  def avatar_old(avatar_name)
    @avatar_name = avatar_name
    assert_kata_exists
    in_container {
      assert_avatar_exists
      remove_sandbox_dir
    }
    nil
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # run
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def run_cyber_dojo_sh(
    avatar_name,
    new_files, deleted_files, unchanged_files, changed_files,
    max_seconds
  )
    @avatar_name = avatar_name
    assert_kata_exists
    unchanged_files = nil # we're stateful!
    all_files = [*changed_files, *new_files].to_h
    in_container(max_seconds) {
      assert_avatar_exists
      deleted_files.each_key do |pathed_filename|
        shell.assert(docker_exec("rm #{sandbox_dir}/#{pathed_filename}"))
      end
      run_timeout_cyber_dojo_sh(all_files, max_seconds)
      @colour = @timed_out ? 'timed_out' : red_amber_green
    }
    { stdout:@stdout, stderr:@stderr, status:@status, colour:@colour }
  end

  private # = = = = = = = = = = = = = = = = = = = = = = = =

  def save_to(files, tmp_dir)
    files.each do |pathed_filename, content|
      sub_dir = File.dirname(pathed_filename)
      unless sub_dir == '.'
        src_dir = tmp_dir + '/' + sub_dir
        shell.assert("mkdir -p #{src_dir}")
      end
      src_filename = tmp_dir + '/' + pathed_filename
      disk.write(src_filename, content)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def tar_pipe_cmd(tmp_dir, cmd = 'sh ./cyber-dojo.sh')
    # [1] is for file-stamp date-time granularity
    # This relates to the modification-date (stat %y).
    # The tar --touch option is not available in a default Alpine
    # container. To add it:
    #    $ apk add --update tar
    # Also, in a default Alpine container the date-time
    # file-stamps have a granularity of one second. In other
    # words the microseconds value is always zero.
    # To add microsecond granularity:
    #    $ apk add --update coreutils
    # See the file builder/image_builder.rb on
    # https://github.com/cyber-dojo-languages/image_builder/blob/master/
    # In particular the methods
    #    o) update_tar_command
    #    o) install_coreutils_command
    <<~SHELL.strip
      chmod 755 #{tmp_dir} &&                                          \
      cd #{tmp_dir} &&                                                 \
      tar                                                              \
        -zcf                           `# create tar file`             \
        -                              `# write it to stdout`          \
        .                              `# tar the current directory`   \
        |                              `# pipe the tarfile...`         \
          docker exec                  `# ...into docker container`    \
            --user=#{uid}:#{gid}                                       \
            --interactive                                              \
            #{container_name}                                          \
            sh -c                                                      \
              '                        `# open quote`                  \
              cd #{sandbox_dir} &&                                     \
              tar                                                      \
                --touch                `# [1]`                         \
                -zxf                   `# extract tar file`            \
                -                      `# which is read from stdin`    \
                -C                     `# save the extracted files to` \
                .                      `# the current directory`       \
                && #{cmd}                                              \
              '                        `# close quote`
    SHELL
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def run_timeout(cmd, max_seconds)
    # The [docker exec] running on the _host_ is
    # killed by Process.kill. This does _not_ kill
    # the cyber-dojo.sh running _inside_ the docker
    # container. The container is killed in the ensure
    # block of in_container()
    # See https://github.com/docker/docker/issues/9098
    # 137=128+9 means Fatal error signal "n"
    r_stdout, w_stdout = IO.pipe
    r_stderr, w_stderr = IO.pipe
    pid = Process.spawn(cmd, {
      pgroup:true,  # become process leader
      out:w_stdout, # redirection
      err:w_stderr  # redirection
    })
    begin
      Timeout::timeout(max_seconds) do
        _, ps = Process.waitpid2(pid)
        @status = ps.exitstatus
        @timed_out = (@status == 137)
      end
    rescue Timeout::Error
      Process.kill(-9, pid) # -ve means kill process-group
      Process.detach(pid)   # prevent zombie-child
      @status = 137         # don't wait for status from detach
      @timed_out = true
    ensure
      w_stdout.close unless w_stdout.closed?
      w_stderr.close unless w_stderr.closed?
      @stdout = truncated(cleaned(r_stdout.read))
      @stderr = truncated(cleaned(r_stderr.read))
      r_stdout.close
      r_stderr.close
    end
  end

  include StringCleaner
  include StringTruncater

  # - - - - - - - - - - - - - - - - - - - - - -

  def red_amber_green
    # @stdout and @stderr have been truncated and cleaned.
    begin
      rag = eval(rag_lambda)
      colour = rag.call(@stdout, @stderr, @status).to_s
      unless ['red','amber','green'].include? colour
        colour = 'amber'
      end
      colour
    rescue
      'amber'
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def rag_lambda
    # In a crippled container (eg fork-bomb)
    # the [docker exec] will mostly likely raise.
    # Not worth creating a new container for this.
    cmd = 'cat /usr/local/bin/red_amber_green.rb'
    begin
      shell.assert(docker_exec(cmd))
    rescue
      nil
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def run_timeout_cyber_dojo_sh(files, max_seconds)
    # See comment at end of file about slower alternative.
    Dir.mktmpdir('runner') do |tmp_dir|
      if files == {} # nothing has changed!
        cmd = [
          'docker exec',
          "--user=#{uid}:#{gid}",
          '--interactive',
          container_name,
          "sh -c 'cd #{sandbox_dir} && sh ./cyber-dojo.sh'"
        ].join(space)
      else
        save_to(files, tmp_dir)
        cmd = tar_pipe_cmd(tmp_dir)
      end
      run_timeout(cmd, max_seconds)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -
  # image/container
  # - - - - - - - - - - - - - - - - - - - - - - - -

  attr_reader :image_name

  def assert_valid_image_name
    unless valid_image_name?(image_name)
      argument_error('image_name', 'invalid')
    end
  end

  include ValidImageName

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def in_container(max_seconds = 10)
    create_container(max_seconds)
    begin
      yield
    ensure
      remove_container
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def create_container(max_seconds)
    # The [docker run] must be guarded by argument checks
    # because it volume mounts...
    #     [docker run ... --volume ...]
    # Volume V must already exist.
    # If volume V does _not_ exist the [docker run]
    # will nevertheless succeed, create the container,
    # and create a _temporary_ sandboxes dir in it!
    # Viz, the runner would be stateless and not stateful.
    # See https://github.com/docker/docker/issues/13121
    args = [
      '--detach',                 # for later execs
      env_vars,
      '--init',                   # pid-1 process
      '--interactive',            # for tar-pipe
      "--name=#{container_name}", # for easy clean up
      limits,
      '--user=root',
      "--volume #{kata_volume_name}:#{sandboxes_root_dir}:rw"
    ].join(space)
    shell.assert("docker run #{args} #{image_name} sh -c 'sleep #{max_seconds}'")
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def remove_container
    # The [docker run] is --detach'd so even if its [sleep]
    # has finished the container will still exist.
    # [docker rm] could be backgrounded with a trailing &
    # but it does not make a test-event discernably
    # faster when measuring to 100th of a second
    shell.assert("docker rm --force #{container_name}")
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def container_name
    [ name_prefix, kata_id, avatar_name ].join('_')
  end

  def name_prefix
    'test_run__runner_stateful_'
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def env_vars
    [
      env_var('AVATAR_NAME', avatar_name),
      env_var('IMAGE_NAME',  image_name),
      env_var('KATA_ID',     kata_id),
      env_var('RUNNER',      'stateful'),
      env_var('SANDBOX',     sandbox_dir),
    ].join(space)
  end

  def env_var(name, value)
    "--env CYBER_DOJO_#{name}=#{value}"
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def limits
    # There is no cpu-ulimit... a cpu-ulimit of 10
    # seconds could kill a container after only 5
    # seconds... The cpu-ulimit assumes one core.
    # The host system running the docker container
    # can have multiple cores or use hyperthreading.
    # So a piece of code running on 2 cores, both 100%
    # utilized could be killed after 5 seconds.
    [
      ulimit('data',   4*GB),  # data segment size
      ulimit('core',   0),     # core file size
      ulimit('fsize',  16*MB), # file size
      ulimit('locks',  128),   # number of file locks
      ulimit('nofile', 128),   # number of files
      ulimit('nproc',  128),   # number of processes
      ulimit('stack',  8*MB),  # stack size
      '--memory=512m',                   # max 512MB ram
      '--net=none',                      # no network
      '--pids-limit=128',                # no fork bombs
      '--security-opt=no-new-privileges' # no escalation
    ].join(space)
  end

  def ulimit(name, limit)
    "--ulimit #{name}=#{limit}"
  end

  KB = 1024
  MB = 1024 * KB
  GB = 1024 * MB

  # - - - - - - - - - - - - - - - - - - - - - - - -
  # kata
  # - - - - - - - - - - - - - - - - - - - - - - - -

  attr_reader :kata_id

  def assert_valid_kata_id
    unless valid_kata_id?
      argument_error('kata_id', 'invalid')
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

  def assert_kata_exists
    unless kata_exists?
      argument_error('kata_id', '!exists')
    end
  end

  def refute_kata_exists
    if kata_exists?
      argument_error('kata_id', 'exists')
    end
  end

  def kata_exists?
    kata_volume_exists?
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def kata_volume_exists?
    cmd = "docker volume ls --quiet --filter 'name=#{kata_volume_name}'"
    shell.assert(cmd).strip == kata_volume_name
  end

  def create_kata_volume
    shell.assert("docker volume create --name #{kata_volume_name}")
  end

  def remove_kata_volume
    shell.assert("docker volume rm #{kata_volume_name}")
  end

  def kata_volume_name
    [ name_prefix, kata_id ].join('_')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -
  # avatar
  # - - - - - - - - - - - - - - - - - - - - - - - -

  attr_reader :avatar_name

  def assert_avatar_exists
    assert_valid_avatar_name
    unless avatar_exists_cid?
      argument_error('avatar_name', '!exists')
    end
  end

  def refute_avatar_exists
    assert_valid_avatar_name
    if avatar_exists_cid?
      argument_error('avatar_name', 'exists')
    end
  end

  def assert_valid_avatar_name
    unless valid_avatar_name?
      argument_error('avatar_name', 'invalid')
    end
  end

  def valid_avatar_name?
    all_avatars_names.include?(avatar_name)
  end

  include AllAvatarsNames

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def group
    'cyber-dojo'
  end

  def gid
    5000
  end

  def uid
    40000 + all_avatars_names.index(avatar_name)
  end

  def sandbox_dir
    "#{sandboxes_root_dir}/#{avatar_name}"
  end

  def sandboxes_root_dir
    '/sandboxes'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def avatar_exists_cid?
    # check is for avatar's sandboxes/ subdir and
    # not its /home/ subdir which is pre-created
    # in the docker image.
    cmd = "[ -d #{sandbox_dir} ] || printf 'not_found'"
    stdout = shell.assert(docker_exec(cmd))
    stdout != 'not_found'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def make_and_chown_dirs
    # first avatar makes the shared dir
    shared_dir = "#{sandboxes_root_dir}/shared"
    shell.assert(docker_exec("mkdir -m 775 #{shared_dir} || true"))
    shell.assert(docker_exec("mkdir -m 755 #{sandbox_dir}"))
    shell.assert(docker_exec("chown root:#{group} #{shared_dir}"))
    shell.assert(docker_exec("chown #{uid}:#{gid} #{sandbox_dir}"))
  end

  def remove_sandbox_dir
    shell.assert(docker_exec("rm -rf #{sandbox_dir}"))
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -
  # assertions
  # - - - - - - - - - - - - - - - - - - - - - - - -

  def docker_exec(cmd)
    "docker exec #{container_name} sh -c '#{cmd}'"
  end

  def argument_error(name, message)
    raise ArgumentError.new("#{name}:#{message}")
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - -

  def space
    ' '
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - -

  def disk
    @external.disk
  end

  def shell
    @external.shell
  end

end

# - - - - - - - - - - - - - - - - - - - - - - - -
# The implementation of run_timeout_cyber_dojo_sh is
#   o) create copies of all files off /tmp
#   o) one tar-pipe copying /tmp files into the container
#   o) run cyber-dojo.sh inside the container
#
# An alternative implementation is
#   o) don't create copies of files off /tmp
#   o) N tar-pipes for N files, each copying directly into the container
#   o) run cyber-dojo.sh inside the container
#
# If only one file has changed you might image this is quicker
# but testing shows its actually a bit slower.
#
# For interests sake here's how you tar pipe without the
# intermediate /tmp files. I don't know how this would
# affect the date-time file-stamp granularity (stat %y).
#
# require 'open3'
# files.each do |name,content|
#   filename = sandbox_dir + '/' + name
#   dir = File.dirname(filename)
#   shell_cmd = "mkdir -p #{dir};"
#   shell_cmd += "cat > #{filename}"
#   shell_cmd += " && chown #{uid}:#{gid} #{filename}"
#   cmd = [
#     'docker exec',
#     '--interactive',
#     '--user=root',
#     container_name,
#     "sh -c '#{shell_cmd}'"
#   ].join(space)
#   stdout,stderr,ps = Open3.capture3(cmd, :stdin_data => content)
#   assert ps.success?
# end
# - - - - - - - - - - - - - - - - - - - - - - - -
