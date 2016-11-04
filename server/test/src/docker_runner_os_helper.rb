
module DockerRunnerOsHelper

  module_function

  def assert_user_exists
    cmd = "getent passwd #{user}"
    stdout, _ = assert_run_succeeds_no_stderr({ 'cyber-dojo.sh' => cmd })
    assert stdout.start_with?(user), stdout
  end

  def assert_group_exists
    cmd = "getent group #{group}"
    stdout, _ = assert_run_succeeds_no_stderr({ 'cyber-dojo.sh' => cmd })
    assert stdout.start_with?(group), stdout
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def create_container_test
    cid = runner.create_container(@image_name, kata_id, avatar_name)
    begin
      assert_docker_exec(cid, "[ -d #{sandbox} ]")

      _,_,status = exec("docker exec #{cid} sh -c '[ \"$(ls -A #{sandbox})\" ]'", logging = false)
      assert_equal 1, status, "#{sandbox} is not empty"

      stdout,_ = assert_docker_exec(cid, "stat -c '%U' #{sandbox}")
      assert_equal user, stdout.strip

      stdout,_ = assert_docker_exec(cid, "stat -c '%G' #{sandbox}")
      assert_equal group, stdout.strip

      stdout,_ = assert_docker_exec(cid, "stat -c '%A' #{sandbox}")
      assert_equal 'drwxr-xr-x', (permissions = stdout.strip)
    ensure
      runner.remove_container(cid)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def starting_files_test
    ls_stdout,_ = assert_run_succeeds_no_stderr(starting_files)
    ls_files = ls_parse(ls_stdout)
    assert_equal starting_files.keys.sort, ls_files.keys.sort
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
    before_ls,_ = assert_run_succeeds_no_stderr(starting_files)
    after_ls,_ = assert_run_succeeds_no_stderr(changed_files = {})
    assert_equal before_ls, after_ls
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def deleted_files_test
    ls_stdout,_ = assert_run_succeeds_no_stderr(starting_files)
    before = ls_parse(ls_stdout)
    before_filenames = before.keys

    changed_files = {}
    max_seconds = 10
    deleted_filenames = ['hello.txt']
    ls_stdout,_ = assert_run_succeeds_no_stderr(changed_files, max_seconds, deleted_filenames)
    after = ls_parse(ls_stdout)
    after_filenames = after.keys

    actual_deleted_filenames = before_filenames - after_filenames
    assert_equal deleted_filenames, actual_deleted_filenames
    after.each { |filename, attr| assert_equal before[filename], attr }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def new_files_test
    ls_stdout,_ = assert_run_succeeds_no_stderr(starting_files)
    before = ls_parse(ls_stdout)
    before_filenames = before.keys

    new_filename = 'fizz_buzz.h'
    new_file_content = '#ifndef...'
    changed_files = { new_filename => new_file_content }
    ls_stdout,_ = assert_run_succeeds_no_stderr(changed_files)
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
    ls_stdout,_ = assert_run_succeeds_no_stderr(starting_files)
    before = ls_parse(ls_stdout)

    sleep 2

    hello_txt = starting_files['hello.txt']
    extra = "\ngreetings"
    changed_files = { 'hello.txt' => hello_txt + extra }
    ls_stdout,_ = assert_run_succeeds_no_stderr(changed_files)
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

  def starting_files
    @starting_files ||= {
      'cyber-dojo.sh' => ls_cmd,
      'empty.txt' => '',
      'hello.txt' => 'hello world',
      'hello.sh' => 'echo hello world',
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
