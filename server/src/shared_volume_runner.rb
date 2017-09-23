require_relative 'all_avatars_names'
require_relative 'logger_null'
require_relative 'nearest_ancestors'
require_relative 'string_cleaner'
require_relative 'string_truncater'
require_relative 'valid_image_name'
require 'securerandom'
require 'timeout'

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Uses a new short-lived docker container per run().
# Uses a long-lived docker volume per kata.
#
# Positives:
#   o) long-lived container per run() is harder to secure.
#   o) avatars can share state (eg sqlite database
#      in /sandboxes/shared)
#
# Negatives:
#   o) avatars cannot share processes.
#   o) bit slower than SharedContainerRunner.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

class SharedVolumeRunner

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

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # image
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def image_pulled?
    image_names.include? image_name
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def image_pull
    # [1] The contents of stderr vary depending on Docker version
    _stdout,stderr,status = quiet_exec("docker pull #{image_name}")
    if status == shell.success
      return true
    elsif stderr.include?('not found') || stderr.include?('not exist')
      return false # [1]
    else
      fail_image_name('invalid')
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # kata
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def kata_exists?
    volume_exists?(kata_volume_name)
  end

  def kata_new
    refute_kata_exists
    create_volume(kata_volume_name)
  end

  def kata_old
    assert_kata_exists
    remove_volume(kata_volume_name)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # avatar
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def avatar_exists?(avatar_name)
    assert_kata_exists
    assert_valid_avatar_name(avatar_name)
    in_container(avatar_name) do |cid|
      avatar_exists_cid?(cid, avatar_name)
    end
  end

  def avatar_new(avatar_name, starting_files)
    assert_kata_exists
    assert_valid_avatar_name(avatar_name)
    in_container(avatar_name) do |cid|
      refute_avatar_exists(cid, avatar_name)
      make_shared_dir(cid)
      chown_shared_dir(cid)
      make_avatar_dir(cid, avatar_name)
      chown_avatar_dir(cid, avatar_name)
      run(avatar_name, [], starting_files, 10)
    end
  end

  def avatar_old(avatar_name)
    assert_kata_exists
    assert_valid_avatar_name(avatar_name)
    in_container(avatar_name) do |cid|
      assert_avatar_exists(cid, avatar_name)
      remove_avatar_dir(cid, avatar_name)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # run
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Copes with infinite loops (eg) in the avatar's
  # code/tests by removing the container - which kills
  # all processes running inside the container.
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def run(avatar_name, deleted_filenames, changed_files, max_seconds)
    assert_kata_exists
    assert_valid_avatar_name(avatar_name)
    in_container(avatar_name) do |cid|
      assert_avatar_exists(cid, avatar_name)
      delete_files(cid, avatar_name, deleted_filenames)
      stdout,stderr,status = run_cyber_dojo_sh(cid, avatar_name, changed_files, max_seconds)
      colour = red_amber_green(cid, stdout, stderr, status)
      { stdout:stdout, stderr:stderr, status:status, colour:colour }
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def group
    'cyber-dojo'
  end

  def gid
    5000
  end

  def user_id(avatar_name)
    assert_valid_avatar_name(avatar_name)
    40000 + all_avatars_names.index(avatar_name)
  end

  def home_dir(avatar_name)
    assert_valid_avatar_name(avatar_name)
    "/home/#{avatar_name}"
  end

  def avatar_dir(avatar_name)
    assert_valid_avatar_name(avatar_name)
    "#{sandboxes_root_dir}/#{avatar_name}"
  end

  def sandboxes_root_dir
    '/sandboxes'
  end

  def timed_out
    'timed_out'
  end

  private

  def in_container(avatar_name, &block)
    cid = create_container(avatar_name, kata_volume_name, sandboxes_root_dir)
    begin
      block.call(cid)
    ensure
      remove_container(cid)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def create_container(avatar_name, volume_name, volume_root)
    # The [docker run] must be guarded by argument checks
    # because it volume mounts...
    #     [docker run ... --volume ...]
    # Volume V must already exist.
    # If volume V does _not_ exist the [docker run]
    # will nevertheless succeed, create the container,
    # and create a temporary /sandboxes/ folder in it!
    # See https://github.com/docker/docker/issues/13121

    dir = avatar_dir(avatar_name)
    home = home_dir(avatar_name)
    name = "test_run__runner_stateful_#{kata_id}_#{avatar_name}_#{uuid}"
    max = 128
    args = [
      '--detach',                          # get the cid
      '--interactive',                     # for later execs
      "--name=#{name}",                    # for easy clean up
      '--net=none',                        # for security
      '--security-opt=no-new-privileges',  # no escalation
      "--pids-limit=#{max}",               # no fork bombs
      "--ulimit nproc=#{max}:#{max}",      # max number processes
      "--ulimit nofile=#{max}:#{max}",     # max number of files
      '--ulimit core=0:0',                 # max core file size = 0 blocks
      "--env CYBER_DOJO_KATA_ID=#{kata_id}",
      "--env CYBER_DOJO_AVATAR_NAME=#{avatar_name}",
      "--env CYBER_DOJO_SANDBOX=#{dir}",
      "--env HOME=#{home}",
      '--user=root',
      "--volume #{volume_name}:#{volume_root}:rw"
    ].join(space)
    stdout,_ = assert_exec("docker run #{args} #{image_name} sh")
    stdout.strip # cid
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def uuid
    SecureRandom.hex[0..10].upcase
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def run_cyber_dojo_sh(cid, avatar_name, files, max_seconds)
    # See comment at end of file about slower alternative.
    Dir.mktmpdir('runner') do |tmp_dir|
      # save the files onto the host...
      files.each do |pathed_filename, content|
        sub_dir = File.dirname(pathed_filename)
        if sub_dir != '.'
          src_dir = tmp_dir + '/' + sub_dir
          shell.exec("mkdir -p #{src_dir}")
        end
        host_filename = tmp_dir + '/' + pathed_filename
        disk.write(host_filename, content)
      end
      # ...then tar-pipe them into the container
      # and run cyber-dojo.sh
      dir = avatar_dir(avatar_name)
      uid = user_id(avatar_name)
      tar_pipe = [
        "chmod 755 #{tmp_dir}",
        "&& cd #{tmp_dir}",
        '&& tar',
              "--owner=#{uid}",
              "--group=#{gid}",
              '-zcf',             # create a compressed tar file
              '-',                # write it to stdout
              '.',                # tar the current directory
              '|',
                  'docker exec',  # pipe the tarfile into docker container
                    "--user=#{uid}:#{gid}",
                    '--interactive',
                    cid,
                    'sh -c',
                    "'",          # open quote
                    "cd #{dir}",
                    '&& tar',
                          '-zxf', # extract from a compressed tar file
                          '-',    # which is read from stdin
                          '-C',   # save the extracted files to
                          '.',    # the current directory
                    '&& sh ./cyber-dojo.sh',
                    "'"           # close quote
      ].join(space)
      # Note: this tar-pipe stores file date-stamps to the second.
      # In other words, the microseconds are always zero.
      # This is very unlikely to matter for a real test-event from
      # the browser but could matter in tests.
      if files == {}
        cyber_dojo_sh = [
          'docker exec',
          "--user=#{uid}:#{gid}",
          '--interactive',
          cid,
          "sh -c 'cd #{dir} && sh ./cyber-dojo.sh'"
        ].join(space)
        run_timeout(cyber_dojo_sh, max_seconds)
      else
        run_timeout(tar_pipe, max_seconds)
      end
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  include StringCleaner
  include StringTruncater

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
      # The container is killed by remove_container().
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

  # - - - - - - - - - - - - - - - - - - - - - -

  def remove_container(cid)
    assert_exec("docker rm --force #{cid}")
    # The docker daemon responds to [docker rm]
    # asynchronously...
    # An 'immediately' following avatar_old()'s
    #    [docker volume rm]
    # might fail since the container is not quite dead yet.
    # This is unlikely to happen in real use but quite
    # likely in tests.
    # I'm waiting max 2 seconds for the container to die.
    # o) no delay if container_dead? is true 1st time.
    # o) 0.04s delay if container_dead? is true 2nd time, etc.
    removed = false
    tries = 0
    while !removed && tries < 50
      removed = container_dead?(cid)
      unless removed
        assert_exec("sleep #{1.0 / 25.0}")
      end
      tries += 1
    end
    unless removed
      log << "Failed to confirm:remove_container(#{cid})"
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def container_dead?(cid)
    cmd = "docker inspect --format='{{ .State.Running }}' #{cid}"
    _,stderr,status = quiet_exec(cmd)
    expected_stderr = "Error: No such image, container or task: #{cid}"
    (status == 1) && (stderr.strip == expected_stderr)
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def delete_files(cid, avatar_name, pathed_filenames)
    # most of the time pathed_filenames == []
    pathed_filenames.each do |pathed_filename|
      dir = avatar_dir(avatar_name)
      assert_docker_exec(cid, "rm #{dir}/#{pathed_filename}")
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def red_amber_green(cid, stdout_arg, stderr_arg, status_arg)
    cmd = 'cat /usr/local/bin/red_amber_green.rb'
    out,_err = assert_exec("docker exec #{cid} sh -c '#{cmd}'")
    rag = eval(out)
    rag.call(stdout_arg, stderr_arg, status_arg).to_s
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -
  # volumes
  # - - - - - - - - - - - - - - - - - - - - - - - -

  def volume_exists?(name)
    cmd = "docker volume ls --quiet --filter 'name=#{name}'"
    stdout,_ = assert_exec(cmd)
    stdout.strip != ''
  end

  def create_volume(name)
    assert_exec(create_volume_cmd(name))
  end

  def remove_volume(name)
    assert_exec(remove_volume_cmd(name))
  end

  def kata_volume_name
    'cyber_dojo_kata_volume_runner_' + kata_id
  end

  def create_volume_cmd(name)
    "docker volume create --name #{name}"
  end

  def remove_volume_cmd(name)
    "docker volume rm #{name}"
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # dirs
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def make_avatar_dir(cid, avatar_name)
    dir = avatar_dir(avatar_name)
    assert_docker_exec(cid, "mkdir -m 755 #{dir}")
  end

  def chown_avatar_dir(cid, avatar_name)
    uid = user_id(avatar_name)
    dir = avatar_dir(avatar_name)
    assert_docker_exec(cid, "chown #{uid}:#{gid} #{dir}")
  end

  def remove_avatar_dir(cid, avatar_name)
    dir = avatar_dir(avatar_name)
    assert_docker_exec(cid, "rm -rf #{dir}")
  end

  def make_shared_dir(cid)
    # first avatar makes the shared dir
    assert_docker_exec(cid, "mkdir -m 775 #{shared_dir} || true")
  end

  def chown_shared_dir(cid)
    assert_docker_exec(cid, "chown root:#{group} #{shared_dir}")
  end

  def shared_dir
    "#{sandboxes_root_dir}/shared"
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def image_names
    cmd = 'docker images --format "{{.Repository}}"'
    stdout,_ = assert_exec(cmd)
    names = stdout.split("\n")
    names.uniq - ['<none>']
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -
  # validation
  # - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_valid_image_name
    unless valid_image_name?(image_name)
      fail_image_name('invalid')
    end
  end

  include ValidImageName

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_kata_exists
    unless kata_exists?
      fail_kata_id('!exists')
    end
  end

  def refute_kata_exists
    if kata_exists?
      fail_kata_id('exists')
    end
  end

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

  def valid_avatar_name?(avatar_name)
    all_avatars_names.include?(avatar_name)
  end

  include AllAvatarsNames

  def assert_avatar_exists(cid, avatar_name)
    unless avatar_exists_cid?(cid, avatar_name)
      fail_avatar_name('!exists')
    end
  end

  def refute_avatar_exists(cid, avatar_name)
    if avatar_exists_cid?(cid, avatar_name)
      fail_avatar_name('exists')
    end
  end

  def avatar_exists_cid?(cid, avatar_name)
    # check for avatar's sandboxes/ subdir
    # and not its /home/ subdir which is pre-created
    # in the docker image.
    dir = avatar_dir(avatar_name)
    _,_,status = quiet_exec("docker exec #{cid} sh -c '[ -d #{dir} ]'")
    status == success
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def fail_kata_id(message)
    fail bad_argument("kata_id:#{message}")
  end

  def fail_image_name(message)
    fail bad_argument("image_name:#{message}")
  end

  def fail_avatar_name(message)
    fail bad_argument("avatar_name:#{message}")
  end

  def bad_argument(message)
    ArgumentError.new(message)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_docker_exec(cid, cmd)
    assert_exec("docker exec #{cid} sh -c '#{cmd}'")
  end

  def assert_exec(cmd)
    shell.assert_exec(cmd)
  end

  def quiet_exec(cmd)
    shell.exec(cmd, LoggerNull.new(self))
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - -

  def success
    shell.success
  end

  def space
    ' '
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - -

  include NearestAncestors

  def shell
    nearest_ancestors(:shell)
  end

  def disk
    nearest_ancestors(:disk)
  end

  def log
    nearest_ancestors(:log)
  end

end

# - - - - - - - - - - - - - - - - - - - - - - - -
# The implementation of run_cyber_dojo_sh is
#   o) Create copies of all (changed) files off /tmp
#   o) Tar pipe the /tmp files into the container
#   o) Run cyber-dojo.sh inside the container
#
# An alternative implementation is
#   o) Tar pipe each file's content directly into the container
#   o) Run cyber-dojo.sh inside the container
#
# If only one file has changed you might image this is quicker
# but testing shows its actually a bit slower.
#
# For interest's sake here's how you tar pipe from a string and
# avoid the intermediate /tmp files:
#
# require 'open3'
# files.each do |name,content|
#   filename = avatar_dir + '/' + name
#   dir = File.dirname(filename)
#   shell_cmd = "mkdir -p #{dir};"
#   shell_cmd += "cat >#{filename} && chown #{uid}:#{gid} #{filename}"
#   cmd = "docker exec --interactive --user=root #{cid} sh -c '#{shell_cmd}'"
#   stdout,stderr,ps = Open3.capture3(cmd, :stdin_data => content)
#   assert ps.success?
# end
# - - - - - - - - - - - - - - - - - - - - - - - -
