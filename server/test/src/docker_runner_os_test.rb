require_relative './runner_test_base'

class DockerRunnerRunOSTest < RunnerTestBase

  def self.hex_prefix; '4D'; end
  def self.alpine_hex; '51D'; end
  def self.ubuntu_hex; 'A7E'; end

  def hex_setup; new_avatar; end
  def hex_teardown; old_avatar; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '778012',
  'calling set_image_for_os with a test whose test_id does not include the',
  'alpine_hex or the ubuntu_hex raises' do
    assert_raises { set_image_for_os }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test alpine_hex+'CA0',
  '[Alpine] image is indeed Alpine and has user:nobody and group:nogroup' do
    set_image_for_os
    stdout, _ = assert_run_completes_no_stderr({ 'cyber-dojo.sh' => 'cat /etc/issue'})
    assert stdout.include?('Alpine'), stdout
    assert_user_nobody_exists
    assert_group_nogroup_exists
  end

  test ubuntu_hex+'CA0',
  '[Ubuntu] image is indeed Ubuntu and has user:nobody and group:nogroup' do
    set_image_for_os
    stdout, _ = assert_run_completes_no_stderr({ 'cyber-dojo.sh' => 'cat /etc/issue'})
    assert stdout.include?('Ubuntu'), stdout
    assert_user_nobody_exists
    assert_group_nogroup_exists
  end

  def assert_user_nobody_exists
    stdout, _ = assert_run_completes_no_stderr({ 'cyber-dojo.sh' => 'getent passwd nobody' })
    assert stdout.start_with?(user), stdout
  end

  def assert_group_nogroup_exists
    stdout, _ = assert_run_completes_no_stderr({ 'cyber-dojo.sh' => 'getent group nogroup' })
    assert stdout.start_with?(group), stdout
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test alpine_hex+'0C9',
  '[Alpine] newly created container has empty sandbox with ownership/permissions' do
    create_container_test
  end

  test ubuntu_hex+'0C9',
  '[Ubuntu] newly created container has empty sandbox with ownership/permissions' do
    create_container_test
  end

  def create_container_test
    set_image_for_os
    cid = runner.create_container(@image_name, kata_id, avatar_name)
    begin
      _, status = exec("docker exec #{cid} sh -c '[ -d #{sandbox} ]'")
      assert_equal 0, status, "#{sandbox} does not exist"
      _, status = exec("docker exec #{cid} sh -c '[ \"$(ls -A #{sandbox})\" ]'", logging = false)
      assert_equal 1, status, "#{sandbox} is not empty"
      stdout, _ = assert_exec("docker exec #{cid} sh -c 'stat -c \"%U\" #{sandbox}'")
      assert_equal 'nobody', (user_name = stdout.strip)
      stdout, _ = assert_exec("docker exec #{cid} sh -c 'stat -c \"%G\" #{sandbox}'")
      assert_equal 'nogroup', (group_name = stdout.strip)

      # TODO permission of sandbox dir

    ensure
      runner.remove_container(cid)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test alpine_hex+'1FB',
  '[Alpine] starting-files are copied into sandbox with ownership/permissions' do
    starting_files_test
  end

  test ubuntu_hex+'1FB',
  '[Ubuntu] starting-files are copied into sandbox with ownership/permissions' do
    starting_files_test
  end

  def starting_files_test
    set_image_for_os
    ls_stdout, _ = assert_run_completes_no_stderr(starting_files)
    ls_files = ls_parse(ls_stdout)
    assert_equal starting_files.keys.sort, ls_files.keys.sort
    assert_equal_atts('empty.txt',     '-rw-r--r--', 'nobody', 'nogroup',  0, ls_files)
    assert_equal_atts('cyber-dojo.sh', '-rwxr-xr-x', 'nobody', 'nogroup', 29, ls_files)
    assert_equal_atts('hello.txt',     '-rw-r--r--', 'nobody', 'nogroup', 11, ls_files)
    assert_equal_atts('hello.sh',      '-rwxr-xr-x', 'nobody', 'nogroup', 16, ls_files)
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

  test alpine_hex+'4E8',
  '[Alpine] unchanged files still exist and are unchanged' do
    unchanged_files_test
  end

  test ubuntu_hex+'4E8',
  '[Ubuntu] unchanged files still exist and are unchanged' do
    unchanged_files_test
  end

  def unchanged_files_test
    set_image_for_os
    before_ls, _ = assert_run_completes_no_stderr(starting_files)
    after_ls, _ = assert_run_completes_no_stderr(changed_files = {})
    assert_equal before_ls, after_ls
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test alpine_hex+'385',
  '[Alpine] deleted files are removed and all previous files are unchanged' do
    deleted_files_test
  end

  test ubuntu_hex+'385',
  '[Ubuntu] deleted files are removed and all previous files are unchanged' do
    deleted_files_test
  end

  def deleted_files_test
    set_image_for_os
    ls_stdout, _ = assert_run_completes_no_stderr(starting_files)
    before = ls_parse(ls_stdout)
    before_filenames = before.keys

    changed_files = {}
    max_seconds = 10
    deleted_filenames = ['hello.txt']
    ls_stdout, _ = assert_run_completes_no_stderr(changed_files, max_seconds, deleted_filenames)
    after = ls_parse(ls_stdout)
    after_filenames = after.keys

    actual_deleted_filenames = before_filenames - after_filenames
    assert_equal deleted_filenames, actual_deleted_filenames
    after.each { |filename, attr| assert_equal before[filename], attr }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test alpine_hex+'232',
  '[Alpine] new files are added with ownership/permissions and all previous files are unchanged' do
    new_files_test
  end

  test ubuntu_hex+'232',
  '[Ubuntu] new files are added with ownership/permissions and all previous files are unchanged' do
    new_files_test
  end

  def new_files_test
    set_image_for_os
    ls_stdout, _ = assert_run_completes_no_stderr(starting_files)
    before = ls_parse(ls_stdout)
    before_filenames = before.keys

    new_filename = 'fizz_buzz.h'
    new_file_content = '#ifndef...'
    changed_files = { new_filename => new_file_content }
    ls_stdout, _ = assert_run_completes_no_stderr(changed_files)
    after = ls_parse(ls_stdout)
    after_filenames = after.keys

    actual_new_filenames = after_filenames - before_filenames
    assert_equal [ new_filename ], actual_new_filenames
    attr = after[new_filename]
    assert_equal '-rw-r--r--', attr[:permissions]
    assert_equal 'nobody', attr[:user]
    assert_equal 'nogroup', attr[:group]
    assert_equal new_file_content.size, attr[:size]
    before.each { |filename, attr| assert_equal after[filename], attr }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test alpine_hex+'9A7',
  '[Alpine] a changed file is resaved and its size and time-stamp updates',
  'and all previous files are unchanged' do
    changed_file_test
  end

  test ubuntu_hex+'9A7',
  '[Ubuntu] a changed file is resaved and its size and time-stamp updates',
  'and all previous files are unchanged' do
    changed_file_test
  end

  def changed_file_test
    set_image_for_os
    ls_output, _ = assert_run_completes_no_stderr(starting_files)
    before = ls_parse(ls_output)

    sleep 2

    hello_txt = starting_files['hello.txt']
    extra = "\ngreetings"
    changed_files = { 'hello.txt' => hello_txt + extra }
    ls_output, _ = assert_run_completes_no_stderr(changed_files)
    after = ls_parse(ls_output)

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

  def set_image_for_os
    if test_id.include? self.class.alpine_hex
      return @image_name = 'cyberdojofoundation/gcc_assert'
    end
    if test_id.include? self.class.ubuntu_hex
      return @image_name = 'cyberdojofoundation/csharp_nunit'
    end
    fail "cannot set os from test 'HEX_ID'"
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def ls_cmd;
    # Works on Ubuntu and Alpine
    'stat -c "%n %A %U %G %s %z" *'
    # hiker.h  -rw-r--r--  nobody nogroup 136  2016-06-05 07:03:14.000000000
    # |        |           |      |       |    |          |
    # 0        1           2      3       4    5          6
    # filename permissions user   group   size date       time
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def ls_parse(ls_output)
    Hash[ls_output.split("\n").collect { |line|
      attr = line.split
      filename = attr[0]
      [filename, {
        permissions: attr[1],
               user: attr[2],
              group: attr[3],
               size: attr[4].to_i,
         time_stamp: attr[6],
      }]
    }]
  end

end
