
require_relative './lib_test_base'
require_relative './docker_runner_helpers'

class DockerRunnerInfrastructureTest < LibTestBase

  def self.hex
    '4D87A'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'DBC',
  'start creates a docker-volume and returns its name' do
    vol_name, status = runner_start
    assert_equal success, status
    assert_equal volume_name, vol_name

    output, status = exec('docker volume ls')
    assert_equal success, status
    assert output.include? volume_name
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '385',
  'deleted files are removed and all previous files still exist' do
    runner_start

    files = language_files('gcc_assert')
    files['cyber-dojo.sh'] = 'ls'
    ls_output, status = runner_run(files)
    assert_equal success, status
    before_filenames = ls_output.split

    ls_output, status = runner_run({}, max_seconds = 10, [ 'makefile' ])
    assert_equal success, status
    after_filenames = ls_output.split
    deleted_filenames = before_filenames - after_filenames

    assert_equal [ 'makefile' ], deleted_filenames
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '232',
  'new files are added and all previous files still exist' do
    runner_start

    files = language_files('gcc_assert')
    files['cyber-dojo.sh'] = 'ls'
    ls_output, status = runner_run(files)
    assert_equal success, status
    before_filenames = ls_output.split

    files = { 'newfile.txt' => 'hello world' }
    ls_output, status = runner_run(files)
    assert_equal success, status
    after_filenames = ls_output.split

    new_filenames = after_filenames - before_filenames
    assert_equal [ 'newfile.txt' ], new_filenames
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '4E8',
  "unchanged files still exist and don't get touched at all" do
    runner_start

    files = language_files('gcc_assert')
    files['cyber-dojo.sh'] = 'ls -el'
    before_ls, status = runner_run(files)
    assert_equal success, status
    after_ls, status = runner_run({})
    assert_equal success, status

    assert_equal before_ls, after_ls
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '9A7',
  'a changed file is resaved and its size and time-stamp updates' do
    runner_start

    files = language_files('gcc_assert')
    files['cyber-dojo.sh'] = 'ls -el | tail -n +2'
    ls_output, status = runner_run(files)
    assert_equal success, status
    # each line looks like this...
    # -rwxr-xr-x 1 nobody root 19 Sun Oct 23 19:15:35 2016 cyber-dojo.sh
    before = parse(ls_output)
    assert_equal 5, before.size

    sleep 2

    hiker_h = files['hiker.h']
    extra = '//hello'
    files = { 'hiker.h' => hiker_h + extra }
    ls_output, status = runner_run(files)
    assert_equal success, status
    after = parse(ls_output)

    assert_equal before.keys, after.keys
    before.keys.each do |filename|
      was = before[filename]
      now = after[filename]
      same = lambda { |name| assert_equal was[name], now[name] }
      same.call('permissions')
      same.call('user')
      same.call('group')
      if filename == 'hiker.h'
        refute_equal now['time-stamp'], was['time-stamp']
        assert_equal now['size'], was['size'] + extra.size
      else
        same.call('time-stamp')
        same.call('size')
      end
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  private

  include DockerRunnerHelpers

  def parse(ls_output)
    # each line looks like this...
    # -rwxr-xr-x 1 nobody root 19 Sun Oct 23 19:15:35 2016 cyber-dojo.sh
    # 0          1 2      3    4  5   6   7  8        9    10
    Hash[ls_output.split("\n").collect { |line|
      info = line.split
      filename = info[10]
      [filename, {
        'permissions' => info[0],
        'user'        => info[2],
        'group'       => info[3],
        'size'        => info[4].to_i,
        'time-stamp'  => info[8],
      }]
    }]
  end

end

