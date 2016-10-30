require_relative './runner_test_base'

class DockerRunnerRunningTest < RunnerTestBase

  def self.hex_prefix
    '4D87A'
  end

  def hex_setup
    new_avatar
  end

  def hex_teardown
    old_avatar
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # These all rely on using gcc_assert being an Alpine-based
  # image in which [ls -el] works
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  # TODO: new empty file
  # TODO: new .sh file

  test '0C9',
  'newly created container has empty sandbox',
  'with appropriate wonership and permissions' do
    image_name = 'cyberdojofoundation/ruby_mini_test'
    cid = runner.create_container(image_name, kata_id, avatar_name)
    begin
      _, status = exec("docker exec #{cid} sh -c '[ -d #{sandbox} ]'")
      assert_equal 0, status, "#{sandbox} does not exist"
      _, status = exec("docker exec #{cid} sh -c '[ \"$(ls -A #{sandbox})\" ]'", logging = false)
      assert_equal 1, status, "#{sandbox} is not empty"
      stdout, _ = assert_exec("docker exec #{cid} sh -c 'stat -c \"%U\" #{sandbox}'")
      assert_equal 'nobody', (user_name = stdout.strip)
      stdout, _ = assert_exec("docker exec #{cid} sh -c 'stat -c \"%G\" #{sandbox}'")
      assert_equal 'nogroup', (group_name = stdout.strip)

      # TODO permission

    ensure
      runner.remove_container(cid)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '1FB',
  'starting-files are copied into sandbox',
  'with appropriate ownership and permissions' do
    start_filenames = %w( hiker.h hiker.c hiker.tests.c cyber-dojo.sh makefile )
    assert_equal start_filenames.sort, gcc_assert_files.keys.sort

    gcc_assert_files['cyber-dojo.sh'] = 'ls -el | tail -n +2'
    ls_stdout, _ = assert_run_completes_no_stderr(gcc_assert_files)
    files = ls_parse(ls_stdout)
    assert_equal start_filenames.sort, files.keys.sort
    files.each do |filename, attr|
      assert_equal 'nobody', attr[:user], filename
      assert_equal 'nogroup', attr[:group], filename
      if filename != 'cyber-dojo.sh'
        assert_equal '-rw-r--r--', attr[:permissions], filename
      else
        assert_equal '-rwxr-xr-x', attr[:permissions], filename
      end
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '4E8',
  'unchanged files still exist and are unchanged' do
    gcc_assert_files['cyber-dojo.sh'] = 'ls -el | tail -n +2'
    before_ls, _ = assert_run_completes_no_stderr(gcc_assert_files)
    after_ls, _ = assert_run_completes_no_stderr(changed_files = {})
    assert_equal before_ls, after_ls
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '385',
  'deleted files are removed',
  'and all previous files are unchanged' do
    gcc_assert_files['cyber-dojo.sh'] = 'ls -el | tail -n +2'
    ls_stdout, _ = assert_run_completes_no_stderr(gcc_assert_files)
    before = ls_parse(ls_stdout)
    before_filenames = before.keys

    changed_files = {}
    max_seconds = 10
    deleted_filenames = ['makefile']
    ls_stdout, _ = assert_run_completes_no_stderr(changed_files, max_seconds, deleted_filenames)
    after = ls_parse(ls_stdout)
    after_filenames = after.keys

    actual_deleted_filenames = before_filenames - after_filenames
    assert_equal deleted_filenames, actual_deleted_filenames

    after.each do |filename, attr|
      assert_equal before[filename], attr
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '232',
  'new files are added with appropriate ownership and permissions',
  'and all previous files are unchanged' do
    gcc_assert_files['cyber-dojo.sh'] = 'ls -el | tail -n +2'
    ls_stdout, _ = assert_run_completes_no_stderr(gcc_assert_files)
    before = ls_parse(ls_stdout)
    before_filenames = before.keys

    new_filename = 'fizz_buzz.h'
    changed_files = { new_filename => '#ifndef...' }
    ls_stdout, _ = assert_run_completes_no_stderr(changed_files)
    after = ls_parse(ls_stdout)
    after_filenames = after.keys

    actual_new_filenames = after_filenames - before_filenames
    assert_equal [ new_filename ], actual_new_filenames
    attr = after[new_filename]
    assert_equal 'nobody', attr[:user]
    assert_equal 'nogroup', attr[:group]
    assert_equal '-rw-r--r--', attr[:permissions]

    before.each do |filename, attr|
      assert_equal after[filename], attr
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '9A7',
  'a changed file is resaved and its size and time-stamp updates',
  'and all previous files are unchanged' do
    gcc_assert_files['cyber-dojo.sh'] = 'ls -el | tail -n +2'
    ls_output, _ = assert_run_completes_no_stderr(gcc_assert_files)
    before = ls_parse(ls_output)

    sleep 2

    hiker_h = gcc_assert_files['hiker.h']
    extra = '//hello'
    changed_files = { 'hiker.h' => hiker_h + extra }
    ls_output, _ = assert_run_completes_no_stderr(changed_files)
    after = ls_parse(ls_output)

    assert_equal before.keys, after.keys
    before.each do |filename, was_attr|
      now_attr = after[filename]
      same = lambda { |sym| assert_equal was_attr[sym], now_attr[sym] }
      same.call(:permissions)
      same.call(:user)
      same.call(:group)
      if filename == 'hiker.h'
        refute_equal now_attr[:time_stamp], was_attr[:time_stamp]
        assert_equal now_attr[:size], was_attr[:size] + extra.size
      else
        same.call(:time_stamp)
        same.call(:size)
      end
    end
  end

  private

  def ls_parse(ls_output)
    # each line looks like this...
    # -rwxr-xr-x 1 nobody root 19 Sun Oct 23 19:15:35 2016 cyber-dojo.sh
    # 0          1 2      3    4  5   6   7  8        9    10
    Hash[ls_output.split("\n").collect { |line|
      info = line.split
      filename = info[10]
      [filename, {
        permissions: info[0],
               user: info[2],
              group: info[3],
               size: info[4].to_i,
         time_stamp: info[8],
      }]
    }]
  end

end
