require_relative '../../src/all_avatars_names'

module OsHelper

  module_function

  include AllAvatarsNames

  def kata_id_env_vars_test
    env = {}
    cmd = 'printenv CYBER_DOJO_KATA_ID'
    env[:kata_id] = assert_cyber_dojo_sh(cmd).strip
    cmd = 'printenv CYBER_DOJO_AVATAR_NAME'
    env[:avatar_name] = assert_cyber_dojo_sh(cmd).strip
    cmd = 'printenv CYBER_DOJO_SANDBOX'
    env[:sandbox] = assert_cyber_dojo_sh(cmd).strip

    assert_equal kata_id,     env[:kata_id]
    assert_equal avatar_name, env[:avatar_name]
    assert_equal sandbox,     env[:sandbox]
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_avatar_users_exist
    etc_passwd = assert_docker_run 'cat /etc/passwd'
    all_avatars_names.each do |name|
      uid = runner.user_id(name).to_s
      assert etc_passwd.include?(uid),
        "#{name}:#{uid}\n\n#{etc_passwd}\n\n#{image_name}"
    end
  end

  def assert_group_exists
    stdout = assert_cyber_dojo_sh("getent group #{group}").strip
    entries = stdout.split(':')  # cyber-dojo:x:5000
    assert_equal group, entries[0], stdout
    assert_equal gid, entries[2].to_i, stdout
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def avatar_new_home_test
    home = assert_cyber_dojo_sh('printenv HOME').strip
    assert_equal "/home/#{avatar_name}", home

    cd_home_pwd = assert_cyber_dojo_sh('cd ~ && pwd').strip
    assert_equal "/home/#{avatar_name}", cd_home_pwd
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def avatar_new_sandbox_setup_test
    assert_cyber_dojo_sh "[ -d #{sandbox} ]" # sandbox exists

    ls = assert_cyber_dojo_sh "ls -A #{sandbox}"
    refute_equal '', ls # sandbox is not empty

    stat = {}
    stat[:user_id] = assert_cyber_dojo_sh("stat -c '%u' #{sandbox}").strip.to_i
    stat[:gid]     = assert_cyber_dojo_sh("stat -c '%g' #{sandbox}").strip.to_i
    stat[:perms]   = assert_cyber_dojo_sh("stat -c '%A' #{sandbox}").strip

    assert_equal user_id,      stat[:user_id]
    assert_equal gid,          stat[:gid]
    assert_equal 'drwxr-xr-x', stat[:perms]
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def avatar_new_starting_files_test
    # kata_setup has already called avatar_new() which
    # has setup a salmon. So I create a new avatar with
    # known ls-starting-files. Note that kata_teardown
    # calls avatar_old('salmon')
    as('lion', ls_starting_files) {
      run4({
          avatar_name:'lion',
        changed_files:{}
      })
      assert_colour 'amber' # doing an ls
      assert_status success
      assert_stderr ''
      ls_stdout = stdout
      ls_files = ls_parse(ls_stdout)
      assert_equal ls_starting_files.keys.sort, ls_files.keys.sort
      uid = user_id('lion')
      assert_equal_atts('empty.txt',     '-rw-r--r--', uid, group,  0, ls_files)
      assert_equal_atts('cyber-dojo.sh', '-rw-r--r--', uid, group, 29, ls_files)
      assert_equal_atts('hello.txt',     '-rw-r--r--', uid, group, 11, ls_files)
      assert_equal_atts('hello.sh',      '-rw-r--r--', uid, group, 16, ls_files)
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def unchanged_files_test
    named_args = { changed_files:ls_starting_files }
    before_ls = assert_run_succeeds(named_args)
    named_args = { changed_files:{} }
    after_ls = assert_run_succeeds(named_args)
    assert_equal before_ls, after_ls
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def deleted_files_test
    named_args = { changed_files:ls_starting_files }
    ls_stdout = assert_run_succeeds(named_args)
    before = ls_parse(ls_stdout)
    before_filenames = before.keys

    deleted_filenames = ['hello.txt']
    named_args = {
          changed_files:{},
      deleted_filenames:deleted_filenames
    }
    ls_stdout = assert_run_succeeds(named_args)
    after = ls_parse(ls_stdout)
    after_filenames = after.keys

    actual_deleted_filenames = before_filenames - after_filenames
    assert_equal deleted_filenames, actual_deleted_filenames
    after.each { |filename, attr|
      assert_equal before[filename], attr
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def new_files_test
    named_args = { changed_files:ls_starting_files }
    ls_stdout = assert_run_succeeds(named_args)
    before = ls_parse(ls_stdout)
    before_filenames = before.keys

    new_filename = 'fizz_buzz.h'
    new_file_content = '#ifndef...'
    named_args = {
      changed_files:{ new_filename => new_file_content }
    }
    ls_stdout = assert_run_succeeds(named_args)
    after = ls_parse(ls_stdout)
    after_filenames = after.keys

    actual_new_filenames = after_filenames - before_filenames
    assert_equal [ new_filename ], actual_new_filenames
    attr = after[new_filename]
    assert_equal '-rw-r--r--', attr[:permissions]
    assert_equal user_id,      attr[:user]
    assert_equal group,        attr[:group]
    assert_equal new_file_content.size, attr[:size]
    before.each { |filename, attr|
      assert_equal after[filename], attr
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def changed_file_test
    named_args = {
      changed_files:ls_starting_files
    }
    ls_stdout = assert_run_succeeds(named_args)
    before = ls_parse(ls_stdout)

    sleep 2

    hello_txt = ls_starting_files['hello.txt']
    extra = "\ngreetings"
    named_args = {
      changed_files:{ 'hello.txt' => hello_txt + extra }
    }
    ls_stdout = assert_run_succeeds(named_args)
    after = ls_parse(ls_stdout)

    assert_equal before.keys, after.keys
    before.each do |filename, was_attr|
      now_attr = after[filename]
      same = lambda { |sym|
        assert_equal was_attr[sym], now_attr[sym]
      }
      same.call(:permissions)
      same.call(:user)
      same.call(:group)
      if filename == 'hello.txt'
        refute_equal now_attr[:time_stamp], was_attr[:time_stamp]
        assert_equal now_attr[:size], was_attr[:size] + extra.size
      else
        same.call(:time_stamp)
        same.call(:size)
      end
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def ulimit_test
    etc_issue = assert_cyber_dojo_sh('cat /etc/issue')
    lines = assert_cyber_dojo_sh('ulimit -a').split("\n")

    assert_equal    0, ulimit(lines, :core_size,  etc_issue)
    assert_equal   10, ulimit(lines, :cpu_time,   etc_issue)
    assert_equal  128, ulimit(lines, :file_locks, etc_issue)
    assert_equal  128, ulimit(lines, :no_files,   etc_issue)
    assert_equal  128, ulimit(lines, :processes,  etc_issue)

    expected_data_size = 4 * gb / kb
    assert_equal expected_data_size,  ulimit(lines, :data_size,  etc_issue)

    expected_file_size = 16 * mb / (block_size = 512)
    assert_equal expected_file_size,  ulimit(lines, :file_size,  etc_issue)

    expected_stack_size = 4 * mb / kb
    assert_equal expected_stack_size, ulimit(lines, :stack_size, etc_issue)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def ulimit(lines, key, etc_issue)
    table = {             # alpine,                       ubuntu
      :core_size  => [ '-c: core file size (blocks)', 'coredump(blocks)'],
      :cpu_time   => [ '-t: cpu time (seconds)',      'time(seconds)'   ],
      :data_size  => [ '-d: data seg size (kb)',      'data(kbytes)'    ],
      :file_locks => [ '-w: locks',                   'locks'           ],
      :file_size  => [ '-f: file size (blocks)',      'file(blocks)'    ],
      :no_files   => [ '-n: file descriptors',        'nofiles'         ],
      :processes  => [ '-p: processes',               'process'         ],
      :stack_size => [ '-s: stack size (kb)',         'stack(kbytes)'   ],
    }
    if alpine?(etc_issue)
      txt = table[key][0]
    end
    if ubuntu?(etc_issue)
      txt = table[key][1]
    end
    line = lines.detect { |limit| limit.start_with? txt }
    line.split[-1].to_i
  end

  private

  def ls_starting_files
    {
      'cyber-dojo.sh' => ls_cmd,
      'empty.txt'     => '',
      'hello.txt'     => 'hello world',
      'hello.sh'      => 'echo hello world',
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def alpine?(etc_issue)
    etc_issue.include? 'Alpine'
  end

  def ubuntu?(etc_issue)
    etc_issue.include? 'Ubuntu'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def kb
    1024
  end

  def mb
    kb * 1024
  end

  def gb
    mb * 1024
  end

end
