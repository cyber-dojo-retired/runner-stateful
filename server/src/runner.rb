require_relative 'all_avatars_names'
require_relative 'logger_null'
require_relative 'string_cleaner'
require_relative 'string_truncater'
require_relative 'valid_image_name'
require 'timeout'

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Uses a new short-lived docker container per run().
# Uses a long-lived docker volume per kata.
# Positives:
#   o) avatars can share disk-state (eg sqlite database in /sandboxes/shared)
#   o) short-lived container per run() is pretty secure.
# Negatives:
#   o) avatars cannot share processes.
#   o) bit slower than runner_processful.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

class Runner # stateful

  def initialize(parent, image_name, kata_id)
    @disk = parent.disk
    @shell = parent.shell
    @image_name = image_name
    @kata_id = kata_id
    assert_valid_image_name
    assert_valid_kata_id
  end

  attr_reader :image_name, :kata_id

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
    kata_volume_exists?
  end

  def kata_new
    refute_kata_exists
    create_kata_volume
  end

  def kata_old
    assert_kata_exists
    remove_kata_volume
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
      run_timeout_cyber_dojo_sh(cid, avatar_name, starting_files, 10)
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

  def run_cyber_dojo_sh(
    avatar_name,
    deleted_filenames,
    unchanged_files, changed_files, new_files,
    max_seconds
    )
    all_files = [*unchanged_files, *changed_files, *new_files].to_h
    run(avatar_name, deleted_filenames, all_files, max_seconds)
  end

  def run(avatar_name, deleted_filenames, changed_files, max_seconds)
    assert_kata_exists
    assert_valid_avatar_name(avatar_name)
    in_container(avatar_name) do |cid|
      assert_avatar_exists(cid, avatar_name)
      delete_files(cid, avatar_name, deleted_filenames)
      args = [ avatar_name, changed_files, max_seconds ]
      stdout,stderr,status,colour = run_timeout_cyber_dojo_sh(cid, *args)
      { stdout:stdout, stderr:stderr, status:status, colour:colour }
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # properties
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

  attr_reader :disk, :shell

  def in_container(avatar_name, &block)
    cid = create_container(avatar_name)
    begin
      block.call(cid)
    ensure
      # [docker rm] could be backgrounded with a trailing &
      # but it does not make a test-event discernably
      # faster when measuring to 100th of a second
      assert_exec("docker rm --force #{cid}")
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def create_container(avatar_name)
    # The [docker run] must be guarded by argument checks
    # because it volume mounts...
    #     [docker run ... --volume ...]
    # Volume V must already exist.
    # If volume V does _not_ exist the [docker run]
    # will nevertheless succeed, create the container,
    # and create a temporary /sandboxes/ folder in it!
    # Viz, the runner would be stateless and not stateful.
    # See https://github.com/docker/docker/issues/13121
    dir = avatar_dir(avatar_name)
    home = home_dir(avatar_name)
    name = container_name(avatar_name)
    mb8 = 8 * 1024 * 1024
    mb16 = 16 * 1024 * 1024
    gb4 = 4 * 1024 * 1024 * 1024
    args = [
      '--detach',
      "--env CYBER_DOJO_AVATAR_NAME=#{avatar_name}",
      "--env CYBER_DOJO_KATA_ID=#{kata_id}",
      '--env CYBER_DOJO_RUNNER=stateful',
      "--env CYBER_DOJO_SANDBOX=#{dir}",
      "--env HOME=#{home}",
      '--init',                            # pid-1 process
      '--interactive',                     # for later execs
      "--name=#{name}",                    # for easy clean up
      '--net=none',                        # for security
      '--pids-limit=128',                  # no fork bombs
      '--security-opt=no-new-privileges',  # no escalation
      "--ulimit data=#{gb4}:#{gb4}",       # max data segment size
      '--ulimit core=0:0',                 # max core file size
      "--ulimit fsize=#{mb16}:#{mb16}",    # max file size
      '--ulimit locks=128:128',            # max number of file locks
      '--ulimit nofile=128:128',           # max number of files
      '--ulimit nproc=128:128',            # max number processes
      "--ulimit stack=#{mb8}:#{mb8}",      # max stack size
      '--user=root',
      "--volume #{kata_volume_name}:#{sandboxes_root_dir}:rw"
    ].join(space)
    stdout,_ = assert_exec("docker run #{args} #{image_name} sh")
    stdout.strip # cid
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def run_timeout_cyber_dojo_sh(cid, avatar_name, files, max_seconds)
    # See comment at end of file about slower alternative.
    Dir.mktmpdir('runner') do |tmp_dir|
      # Save the files onto the host...
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
              '-zcf', # create tar file
              '-',    # write it to stdout
              '.',    # tar the current directory
              '|',    # pipe the tarfile...
                  'docker exec',  # ...into docker container
                    "--user=#{uid}:#{gid}", # [1]
                    '--interactive',
                    cid,
                    'sh -c',
                    "'",          # open quote
                    "cd #{dir}",
                    '&& tar',
                          '--touch', # [2]
                          '-zxf', # extract tar file
                          '-',    # which is read from stdin
                          '-C',   # save the extracted files to
                          '.',    # the current directory
                    '&& sh ./cyber-dojo.sh',
                    "'"           # close quote
      ].join(space)
      # The files written into the container need the correct
      # content, ownership, and date-time file-stamps.
      # [1] is for the correct ownership.
      # [2] is for the date-time stamps, in particular the
      #     modification-date (stat %y). The tar --touch option
      #     is not available in a default Alpine container.
      #     So the test-framework container needs to update tar:
      #        $ apk add --update tar
      #     Also, in a default Alpine container the date-time
      #     file-stamps have a granularity of one second. In other
      #     words the microseconds value is always zero.
      #     So the test-framework container also needs to fix this:
      #        $ apk add --update coreutils
      if files == {}
        cyber_dojo_sh = [
          'docker exec',
          "--user=#{uid}:#{gid}",
          '--interactive',
          cid,
          "sh -c 'cd #{dir} && sh ./cyber-dojo.sh'"
        ].join(space)
        run_timeout(cid, cyber_dojo_sh, max_seconds)
      else
        run_timeout(cid, tar_pipe, max_seconds)
      end
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  include StringCleaner
  include StringTruncater

  def run_timeout(cid, cmd, max_seconds)
    # This kills the container from the "outside".
    # Originally I also time-limited the cpu-time from the "inside"
    # using the cpu ulimit. However a cpu-ulimit of 10 seconds could
    # kill the container after only 5 seconds. This is because the
    # cpu-ulimit assumes one core. The host system running the docker
    # container can have multiple cores or use hyperthreading. So a
    # piece of code running on 2 cores, both 100% utilized could be
    # killed after 5 seconds. So there is no longer a cpu-ulimit.
    r_stdout, w_stdout = IO.pipe
    r_stderr, w_stderr = IO.pipe
    pid = Process.spawn(cmd, {
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
        colour = red_amber_green(cid, stdout, stderr, status)
        [stdout, stderr, status, colour]
      end
    rescue Timeout::Error
      # Kill the [docker exec] processes running
      # on the host. This does __not__ kill the
      # cyber-dojo.sh process running __inside__
      # the docker container. See
      # https://github.com/docker/docker/issues/9098
      # The container is killed in the ensure
      # block of in_container()
      Process.kill(-9, pid)
      Process.detach(pid)
      ['', '', 137, timed_out]
    ensure
      w_stdout.close unless w_stdout.closed?
      w_stderr.close unless w_stderr.closed?
      r_stdout.close
      r_stderr.close
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def delete_files(cid, avatar_name, pathed_filenames)
    # most of the time, pathed_filenames == []
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

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # images
  # - - - - - - - - - - - - - - - - - - - - - - - -

  def image_names
    cmd = 'docker images --format "{{.Repository}}"'
    stdout,_ = assert_exec(cmd)
    names = stdout.split("\n")
    names.uniq - ['<none>']
  end

  def container_name(avatar_name)
    # Give containers a name with a specific prefix so they
    # can be cleaned up if any fail to be removed/reaped.
    # Does not have a trailing uuid. This ensures that
    # an in_container() call is not accidentally nested inside
    # another in_container() call.
    [ name_prefix, kata_id, avatar_name ].join('_')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -
  # volumes
  # - - - - - - - - - - - - - - - - - - - - - - - -

  def kata_volume_exists?
    cmd = "docker volume ls --quiet --filter 'name=#{kata_volume_name}'"
    stdout,_ = assert_exec(cmd)
    stdout.strip != ''
  end

  def create_kata_volume
    cmd = "docker volume create --name #{kata_volume_name}"
    assert_exec(cmd)
  end

  def remove_kata_volume
    cmd = "docker volume rm #{kata_volume_name}"
    assert_exec(cmd)
  end

  def kata_volume_name
    [ name_prefix, kata_id ].join('_')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # dirs
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def make_avatar_dir(cid, avatar_name)
    dir = avatar_dir(avatar_name)
    assert_docker_exec(cid, "mkdir -m 755 #{dir}")
  end

  def chown_avatar_dir(cid, avatar_name)
    dir = avatar_dir(avatar_name)
    uid = user_id(avatar_name)
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

  # - - - - - - - - - - - - - - - - - - - - - - - -
  # validation
  # - - - - - - - - - - - - - - - - - - - - - - - -

  include ValidImageName

  def assert_valid_image_name
    unless valid_image_name?(image_name)
      fail_image_name('invalid')
    end
  end

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

  include AllAvatarsNames

  def valid_avatar_name?(avatar_name)
    all_avatars_names.include?(avatar_name)
  end

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
    # check is for avatar's sandboxes/ subdir and
    # not its /home/ subdir which is pre-created
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

  def name_prefix
    'test_run__runner_stateful_'
  end

  def success
    shell.success
  end

  def space
    ' '
  end

end

# - - - - - - - - - - - - - - - - - - - - - - - -
# The implementation of run_timeout_cyber_dojo_sh is
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
