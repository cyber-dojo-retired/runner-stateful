require_relative 'file_delta'
require_relative 'string_cleaner'
require_relative 'string_truncater'
require 'find'
require 'timeout'

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Uses a new short-lived docker container per run.
# Uses a long-lived docker volume per kata.
#
# Positives:
#   o) persistent disk-state between test-runs can improve speed.
#   o) short-lived container per run() is pretty secure.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

class Runner # stateful

  def initialize(external, cache)
    @external = external
    @cache = cache
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def sha
    IO.read('/app/sha.txt').strip
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # kata
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def kata_new(image_name, id, starting_files)
    @image_name = image_name
    @id = id
    refute_kata_exists
    create_kata_volume
    in_container(3) { # max_seconds
      make_and_chown_dirs
      Dir.mktmpdir { |tmp_dir|
        save_to(starting_files, tmp_dir)
        shell.assert(tar_pipe_cmd(tmp_dir, 'true'))
      }
    }
    nil
  end

  def kata_old(image_name, id)
    @image_name = image_name
    @id = id
    assert_kata_exists
    remove_kata_volume
    nil
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # run
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def run_cyber_dojo_sh(
    image_name, id,
    new_files, deleted_files, unchanged_files, changed_files,
    max_seconds
  )
    @image_name = image_name
    @id = id

    ensure_kata_exists(unchanged_files)
    all_files = [*changed_files, *new_files].to_h
    in_container(max_seconds) {
      deleted_files.each_key do |pathed_filename|
        shell.assert(docker_exec("rm #{sandbox_dir}/#{pathed_filename}"))
      end
      run_timeout_cyber_dojo_sh(all_files, max_seconds)
      set_colour
      set_file_delta(all_files.merge(unchanged_files))
    }
    {
      stdout:@stdout,
      stderr:@stderr,
      status:@status,
      colour:@colour,
      new_files:@new_files,
      deleted_files:@deleted_files,
      changed_files:@changed_files
    }
  end

  private # = = = = = = = = = = = = = = = = = = = = = = = =

  attr_reader :image_name

  def id
    # Already checked to be a Base62.string
    # which means it can safely form a docker
    # container name.
    @id
  end

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

  def read_from(tmp_dir)
    # eg tmp_dir = /tmp/.../sandboxes/bee
    files = {}
    Find.find(tmp_dir) do |pathed_filename|
      # eg pathed_filename =
      # '/tmp/.../sandboxes/bee/features/shouty.feature
      unless File.directory?(pathed_filename)
        content = File.read(pathed_filename)
        filename = pathed_filename[tmp_dir.size+1..-1]
        # eg filename = features/shouty.feature
        files[filename] = sanitized(content)
      end
    end
    files
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
      @stdout = sanitized(r_stdout.read)
      @stderr = sanitized(r_stderr.read)
      r_stdout.close
      r_stderr.close
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - -
  # tar-piping text files into the container
  # - - - - - - - - - - - - - - - - - - - - - -

  def tar_pipe_cmd(tmp_dir, cmd = 'bash ./cyber-dojo.sh')
    # [1] is for file-stamp date-time granularity
    # This relates to the modification-date (stat %y).
    # The tar --touch option is not available in a
    # default Alpine container. To add it:
    #    $ apk add --update tar
    # Also, in a default Alpine container the date-time
    # file-stamps have a granularity of one second. In
    # other words the microseconds value is always zero.
    # To add microsecond granularity:
    #    $ apk add --update coreutils
    # See the file builder/image_builder.rb on
    # https://github.com/cyber-dojo-languages/image_builder/blob/master/
    # In particular the methods
    #    o) update_tar_command
    #    o) install_coreutils_command
    <<~SHELL.strip
      chmod 755 #{tmp_dir}                                 \
      &&                                                   \
      cd #{tmp_dir}                                        \
      &&                                                   \
      tar                                                  \
        -zcf                     `# create tar file`       \
        -                        `# write it to stdout`    \
        .                        `# tar current directory` \
        |                        `# pipe the tarfile`      \
          docker exec            `# into docker container` \
            --user=#{uid}:#{gid}                           \
            --interactive                                  \
            #{container_name}                              \
            sh -c                                          \
              '                  `# open quote`            \
              cd #{sandbox_dir}                            \
              &&                                           \
              tar                                          \
                --touch          `# [1]`                   \
                -zxf             `# extract tar file`      \
                -                `# read from stdin`       \
                -C               `# save to the`           \
                .                `# current directory`     \
                &&                                         \
                #{cmd}                                     \
              '                  `# close quote`
    SHELL
  end

  # - - - - - - - - - - - - - - - - - - - - - -
  # tar-piping text files out of the container
  # - - - - - - - - - - - - - - - - - - - - - -

  include FileDelta

  def set_file_delta(was_files)
    now_files = tar_pipe_out
    if now_files == {} || @timed_out
      @new_files = {}
      @deleted_files = {}
      @changed_files = {}
    else
      file_delta(was_files, now_files)
    end
  end

  def tar_pipe_out
    # The create_text_file_tar_list.sh file is injected
    # into the test-framework image by image_builder.
    # Passes the tar-list filename as an environment
    # variable because using bash -c means you
    # cannot pass it as an argument.
    Dir.mktmpdir do |tmp_dir|
      tar_list = '/tmp/tar.list'
      docker_tar_pipe = <<~SHELL.strip
        docker exec --user=root                           \
          --env TAR_LIST=#{tar_list}                      \
          #{container_name}                               \
          bash -c                                         \
            '                                             \
            /usr/local/bin/create_text_file_tar_list.sh   \
            &&                                            \
            tar -zcf - -T #{tar_list}                     \
            '                                             \
              | tar -zxf - -C #{tmp_dir}
      SHELL
      # A crippled container (eg fork-bomb) will
      # likely not be running causing the [docker exec]
      # to fail so you cannot use shell.assert() here.
      _stdout,_stderr,status = shell.exec(docker_tar_pipe)
      if status == 0
        read_from(tmp_dir + sandbox_dir)
      else
        {}
      end
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - -
  # red-amber-green colour of stdout,stderr,status
  # - - - - - - - - - - - - - - - - - - - - - -

  def set_colour
    if @timed_out
      @colour = 'timed_out'
    else
      @colour = red_amber_green
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def red_amber_green
    # @stdout and @stderr have been sanitized.
    rag_lambda = @cache.rag_lambda(image_name) { get_rag_lambda }
    colour = rag_lambda.call(@stdout, @stderr, @status)
    unless [:red,:amber,:green].include?(colour)
      # TODO: log
      colour = :amber
    end
    colour.to_s
  rescue
    # TODO: log
    'amber'
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def get_rag_lambda
    # In a crippled container (eg fork-bomb)
    # the [docker exec] will mostly likely raise.
    cat_cmd = 'cat /usr/local/bin/red_amber_green.rb'
    src = shell.assert(docker_exec(cat_cmd))
    eval(src)
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
          "sh -c 'cd #{sandbox_dir} && bash ./cyber-dojo.sh'"
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

  def in_container(max_seconds)
    create_container(max_seconds)
    begin
      yield
    ensure
      remove_container
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def create_container(max_seconds)
    # The [docker run] must be guarded by earlier argument
    # checks because it volume mounts...
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
      "--name=#{container_name}", # for easy clean up
      limits,
      '--user=root',
      "--volume #{kata_volume_name}:#{sandboxes_root_dir}:rw"
    ].join(space)
    shell.assert("docker run #{args} #{image_name} sleep #{max_seconds}")
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
    [ name_prefix, id ].join('_')
  end

  def name_prefix
    'test_run__runner_stateful_'
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def env_vars
    [
      env_var('IMAGE_NAME', image_name),
      env_var('ID',         id),
      env_var('RUNNER',     'stateful'),
      env_var('SANDBOX',    sandbox_dir),
    ].join(space)
  end

  def env_var(name, value)
    # Note: value must not contain a single quote
    "--env CYBER_DOJO_#{name}='#{value}'"
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
      ulimit('nofile', 256),   # number of files
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

  def ensure_kata_exists(starting_files)
    # resurrection. Assume we are revisiting
    # a kata the collector has collected.
    unless kata_exists?
      kata_new(image_name, id, starting_files)
    end
  end

  def assert_kata_exists
    unless kata_exists?
      argument_error('id', '!exists')
    end
  end

  def refute_kata_exists
    if kata_exists?
      argument_error('id', 'exists')
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
    [ name_prefix, id ].join('_')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -
  # sandbox user/group
  # - - - - - - - - - - - - - - - - - - - - - - - -

  def group
    'sandbox'
  end

  def gid
    51966 # sandbox group
  end

  def uid
    41966 # sandbox user
  end

  def sandbox_dir
    "#{sandboxes_root_dir}/#{id}"
  end

  def sandboxes_root_dir
    '/sandboxes'
  end

  def make_and_chown_dirs
    shell.assert(docker_exec("mkdir -m 755 #{sandbox_dir}"))
    shell.assert(docker_exec("chown #{uid}:#{gid} #{sandbox_dir}"))
  end

  def remove_sandbox_dir
    shell.assert(docker_exec("rm -rf #{sandbox_dir}"))
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -
  # assertions
  # - - - - - - - - - - - - - - - - - - - - - - - -

  def docker_exec(cmd)
    # This is _not_ the main docker-exec
    # for run_cyber_dojo_sh
    "docker exec --user root #{container_name} sh -c '#{cmd}'"
  end

  def argument_error(name, message)
    raise ArgumentError.new("#{name}:#{message}")
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - -
  # helpers
  # - - - - - - - - - - - - - - - - - - - - - - - - -

  include StringCleaner
  include StringTruncater

  def sanitized(string)
    truncated(cleaned(string))
  end

  def space
    ' '
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - -
  # externals
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
#   o) run one tar-pipe copying /tmp files into the container
#   o) run cyber-dojo.sh inside the container
#
# An alternative implementation is
#   o) don't create copies of files off /tmp
#   o) run N tar-pipes, each copying one file directly into the container
#   o) run cyber-dojo.sh inside the container
#
# If only one file has changed you might image this is quicker
# but timing shows its actually a bit slower.
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
