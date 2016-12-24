
module DockerRunnerOsHelper

  module_function

  def kata_id_env_vars_test
    stdout = assert_cyber_dojo_sh_no_stderr 'printenv CYBER_DOJO_KATA_ID'
    assert_equal kata_id, stdout.strip
    stdout = assert_cyber_dojo_sh_no_stderr 'printenv CYBER_DOJO_AVATAR_NAME'
    assert_equal avatar_name, stdout.strip
    stdout = assert_cyber_dojo_sh_no_stderr 'printenv CYBER_DOJO_SANDBOX'
    assert_equal sandbox, stdout.strip
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_user_exists
    stdout = assert_cyber_dojo_sh_no_stderr "getent passwd #{user}"
    assert stdout.start_with?(user), stdout
  end

  def assert_group_exists
    stdout = assert_cyber_dojo_sh_no_stderr "getent group #{group}"
    assert stdout.start_with?(group), stdout
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def new_avatar_sandbox_setup_test
    # sandbox exists
    assert_cyber_dojo_sh_no_stderr "[ -d #{sandbox} ]"
    # sandbox is not empty
    stdout = assert_cyber_dojo_sh_no_stderr "ls -A #{sandbox}"
    refute_equal '', stdout
    # sandbox's user is set
    stdout = assert_cyber_dojo_sh_no_stderr "stat -c '%U' #{sandbox}"
    assert_equal user, stdout.strip
    # sandbox's group is set
    stdout = assert_cyber_dojo_sh_no_stderr "stat -c '%G' #{sandbox}"
    assert_equal group, stdout.strip
    # sandbox's permissions are set
    stdout = assert_cyber_dojo_sh_no_stderr "stat -c '%A' #{sandbox}"
    assert_equal 'drwxr-xr-x', stdout.strip
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def new_avatar_starting_files_test
    # kata_setup has already called new_avatar() which has setup
    # a salmon with the starting-files associated with @image_name
    # So I create a new avatar with known starting-files
    # kata_teardown calls old_kata which deletes all the avatar's volumes.
    runner.new_avatar(@image_name, kata_id, 'lion', ls_starting_files)
    args = []
    args << @image_name
    args << kata_id
    args << 'lion'
    args << (deleted_filenames=[])
    args << (changed_files={})
    args << (max_seconds=10)
    sss = runner.run(*args)
    ls_stdout = sss[:stdout]
    stderr = sss[:stderr]
    status = sss[:status]
    assert_equal success, status
    assert_equal '', stderr
    ls_files = ls_parse(ls_stdout)
    assert_equal ls_starting_files.keys.sort, ls_files.keys.sort
    assert_equal_atts('empty.txt',     '-rw-r--r--', user, group,  0, ls_files)
    assert_equal_atts('cyber-dojo.sh', '-rwxr-xr-x', user, group, 29, ls_files)
    assert_equal_atts('hello.txt',     '-rw-r--r--', user, group, 11, ls_files)
    assert_equal_atts('hello.sh',      '-rwxr-xr-x', user, group, 16, ls_files)
  end

  def assert_equal_atts(filename, permissions, user, group, size, ls_files)
    atts = ls_files[filename]
    refute_nil atts, filename
    assert_equal user, atts[:user], { filename => atts }
    assert_equal group, atts[:group], { filename => atts }
    assert_equal size, atts[:size], { filename => atts }
    assert_equal permissions, atts[:permissions], { filename => atts }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def unchanged_files_test
    before_ls = assert_run_succeeds_no_stderr(ls_starting_files)
    after_ls = assert_run_succeeds_no_stderr(changed_files = {})
    assert_equal before_ls, after_ls
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def deleted_files_test
    ls_stdout = assert_run_succeeds_no_stderr(ls_starting_files)
    before = ls_parse(ls_stdout)
    before_filenames = before.keys

    changed_files = {}
    max_seconds = 10
    deleted_filenames = ['hello.txt']
    ls_stdout = assert_run_succeeds_no_stderr(changed_files, max_seconds, deleted_filenames)
    after = ls_parse(ls_stdout)
    after_filenames = after.keys

    actual_deleted_filenames = before_filenames - after_filenames
    assert_equal deleted_filenames, actual_deleted_filenames
    after.each { |filename, attr| assert_equal before[filename], attr }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def new_files_test
    ls_stdout = assert_run_succeeds_no_stderr(ls_starting_files)
    before = ls_parse(ls_stdout)
    before_filenames = before.keys

    new_filename = 'fizz_buzz.h'
    new_file_content = '#ifndef...'
    changed_files = { new_filename => new_file_content }
    ls_stdout = assert_run_succeeds_no_stderr(changed_files)
    after = ls_parse(ls_stdout)
    after_filenames = after.keys

    actual_new_filenames = after_filenames - before_filenames
    assert_equal [ new_filename ], actual_new_filenames
    attr = after[new_filename]
    assert_equal '-rw-r--r--', attr[:permissions]
    assert_equal user, attr[:user]
    assert_equal group, attr[:group]
    assert_equal new_file_content.size, attr[:size]
    before.each { |filename, attr| assert_equal after[filename], attr }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def changed_file_test
    ls_stdout = assert_run_succeeds_no_stderr(ls_starting_files)
    before = ls_parse(ls_stdout)

    sleep 2

    hello_txt = ls_starting_files['hello.txt']
    extra = "\ngreetings"
    changed_files = { 'hello.txt' => hello_txt + extra }
    ls_stdout = assert_run_succeeds_no_stderr(changed_files)
    after = ls_parse(ls_stdout)

    assert_equal before.keys, after.keys
    before.each do |filename, was_attr|
      now_attr = after[filename]
      same = lambda { |sym| assert_equal was_attr[sym], now_attr[sym] }
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

  private

  def ls_starting_files
    @ls_starting_files ||= {
      'cyber-dojo.sh' => ls_cmd,
      'empty.txt'     => '',
      'hello.txt'     => 'hello world',
      'hello.sh'      => 'echo hello world',
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def ls_cmd;
    # Works on Ubuntu and Alpine
    'stat -c "%n %A %U %G %s %z" *'
    # hiker.h  -rw-r--r--  nobody nogroup 136  2016-06-05 07:03:14.000000000
    # |        |           |      |       |    |          |
    # filename permissions user   group   size date       time
    # 0        1           2      3       4    5          6
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def ls_parse(ls_stdout)
    Hash[ls_stdout.split("\n").collect { |line|
      attr = line.split
      [filename = attr[0], {
        permissions: attr[1],
               user: attr[2],
              group: attr[3],
               size: attr[4].to_i,
         time_stamp: attr[6],
      }]
    }]
  end

end
