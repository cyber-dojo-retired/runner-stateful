require_relative 'test_base'

class ApiTest < TestBase

  def self.hex_prefix
    '375'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  multi_os_test '8A1',
  'os-image correspondence' do
    in_kata {
      etc_issue = assert_cyber_dojo_sh('cat /etc/issue')
      diagnostic = [
        "image_name=:#{image_name}:",
        "did not find #{os} in etc/issue",
        etc_issue
      ].join("\n")
      assert etc_issue.include?(os.to_s), diagnostic
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # robustness
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  multi_os_test '2F0',
  'call to non existent method becomes exception' do
    assert_exception('does_not_exist', {}.to_json)
  end

  multi_os_test '2F1',
  'call to existing method with bad json becomes exception' do
    assert_exception('does_not_exist', '{x}')
  end

  multi_os_test '2F2',
  'call to existing method with missing argument becomes exception' do
    in_kata {
      args = { image_name:image_name }
      assert_exception('kata_new', args.to_json)
    }
  end

  multi_os_test '2F3',
  'call to existing method with bad argument type becomes exception' do
    in_kata {
      args = {
        image_name:image_name,
        id:id,
        avatar_name:avatar_name,
        new_files:2, # <=====
        deleted_files:{},
        unchanged_files:{},
        changed_files:{},
        max_seconds:2
      }
      assert_exception('run_cyber_dojo_sh', args.to_json)
    }
  end

  include HttpJsonService

  def hostname
    ENV['RUNNER_STATEFUL_SERVICE_NAME']
  end

  def port
    ENV['RUNNER_STATEFUL_SERVICE_PORT']
  end

  def assert_exception(method_name, jsoned_args)
    json = http(method_name, jsoned_args) { |uri|
      Net::HTTP::Post.new(uri)
    }
    refute_nil json['exception']
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # invalid arguments
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  METHOD_NAMES = [ :kata_new, :kata_old,
                   :run_cyber_dojo_sh ]

  multi_os_test 'D21',
  'all api methods raise when image_name is malformed' do
    in_kata {
      METHOD_NAMES.each { |method_name|
        error = assert_raises(StandardError, method_name.to_s) {
          self.send method_name, { image_name:INVALID_IMAGE_NAME }
        }
        expected = "RunnerService:#{method_name}:image_name:malformed"
        assert_equal expected, error.message
      }
    }
  end

  multi_os_test '656',
  'all api methods raise when id is malformed' do
    in_kata {
      METHOD_NAMES.each { |method_name|
        error = assert_raises(StandardError, method_name.to_s) {
          self.send method_name, { id:INVALID_ID }
        }
        expected = "RunnerService:#{method_name}:id:malformed"
        assert_equal expected, error.message
      }
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # vanilla red-amber-green
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '3DF',
  '[C,assert] run with initial 6*9 == 42 is red' do
    in_kata {
      run_cyber_dojo_sh
      assert red?
    }
  end

  test '3DE',
  '[C,assert] run with syntax error is amber' do
    in_kata {
      filename = 'hiker.c'
      content = starting_files[filename]
      run_cyber_dojo_sh({
        changed_files: { filename => content.sub('6 * 9', '6 * 9sd') }
      })
      assert amber?
    }
  end

  test '3DD',
  '[C,assert] run with 6*7 == 42 is green' do
    in_kata {
      filename = 'hiker.c'
      content = starting_files[filename]
      run_cyber_dojo_sh({
        changed_files: { filename => content.sub('6 * 9', '6 * 7') }
      })
      assert green?
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # timing out
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '3DC',
  '[C,assert] run with infinite loop times out' do
    in_kata {
      filename = 'hiker.c'
      content = starting_files[filename]
      from = 'return 6 * 9'
      to = "    for (;;);\n    return 6 * 7;"
      run_cyber_dojo_sh({
        changed_files: { filename => content.sub(from, to) },
          max_seconds: 3
      })
      assert timed_out?
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # large-files
  # docker-compose.yml need a tmpfs for this to pass
  #      tmpfs: /tmp
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  multi_os_test '3DB',
  'run with very large file is red' do
    in_kata {
      run_cyber_dojo_sh({
        new_files: { 'big_file' => 'X'*1023*500 }
      })
    }
    assert red?
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  multi_os_test 'ED4',
  'stdout greater than 10K is truncated' do
    # fold limit is 10000 so I do two smaller folds
    five_K_plus_1 = 5*1024+1
    command = [
      'cat /dev/urandom',
      "tr -dc 'a-zA-Z0-9'",
      "fold -w #{five_K_plus_1}",
      'head -n 1'
    ].join('|')
    in_kata {
      run_cyber_dojo_sh({
        changed_files: {
          'cyber-dojo.sh' => "seq 2 | xargs -I{} sh -c '#{command}'"
        }
      })
    }
    assert stdout.include? 'output truncated by cyber-dojo'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # container properties
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  multi_os_test '9FA',
  'container environment properties' do
    in_kata {
      assert_pid_1_is_running_init_process
      assert_cyber_dojo_runs_in_bash
      assert_time_stamp_microseconds_granularity
      assert_env_vars_exist
      assert_cyber_dojo_group_exists
      assert_user_home
      assert_user_properties
      assert_starting_files_properties
      assert_ulimits
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  multi_os_test 'F45',
  %w( cyber_dojo.sh is in starting files but is not run ) do
    files = starting_files
    new_filename = 'hello.txt'
    files['cyber-dojo.sh'] = "cat 'Hello' > #{new_filename}"
    in_kata {
      as(salmon, files) {
        run_cyber_dojo_sh({
          changed_files: { 'cyber-dojo.sh' => stat_cmd }
        })
        filenames = stdout_stats.keys
        refute filenames.include? new_filename
      }
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  multi_os_test '8A4',
  'files can be created in sandbox sub-dirs' do
    in_kata {
      assert_files_can_be_in_sub_dirs_of_sandbox
      assert_files_can_be_in_sub_sub_dirs_of_sandbox
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  multi_os_test '8A6',
  'baseline speed' do
    in_kata {
      assert_baseline_speed
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # bombs
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'CD4',
  '[C,assert] print-bomb does not run indefinitely and some output is returned' do
    in_kata {
      run_cyber_dojo_sh({
        changed_files: { 'hiker.c' => print_bomb }
      })
      assert timed_out?
      refute_equal '', stdout+stderr
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'CD5',
  '[C,assert] fork-bomb does not run indefinitely' do
    in_kata {
      run_cyber_dojo_sh({
        changed_files: { 'hiker.c' => fork_bomb }
      })
      assert timed_out? ||
        printed?('All tests passed') ||
          printed?('fork()'), json
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  multi_os_test 'CD6',
  'shell fork-bomb does not run indefinitely' do
    in_kata {
      run_cyber_dojo_sh({
        changed_files: { 'cyber-dojo.sh' => shell_fork_bomb }
      })
      cant_fork = (os == :Alpine ? "can't fork" : 'Cannot fork')
      assert timed_out? ||
        printed?(cant_fork) ||
          printed?('bomb'), json
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'DB3',
  '[C,assert] file-handles quickly become exhausted' do
    in_kata {
      run_cyber_dojo_sh({
        changed_files: { 'hiker.c' => exhaust_file_handles }
      })
      assert printed?('All tests passed'), json
      assert printed?('fopen() != NULL'),  json
      assert printed?('fopen() == NULL'),  json
    }
  end

  private

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_pid_1_is_running_init_process
    cmd = 'cat /proc/1/cmdline'
    proc1 = assert_cyber_dojo_sh(cmd)
    # odd, but there _is_ an embedded nul-character
    expected = '/dev/init' + 0.chr + '--'
    assert proc1.start_with?(expected), proc1
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_cyber_dojo_runs_in_bash
    assert_equal '/bin/bash', cyber_dojo_sh_shell
  end

  def cyber_dojo_sh_shell
    cmd = 'echo ${SHELL}'
    assert_cyber_dojo_sh(cmd)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_env_vars_exist
    assert_equal image_name,  env_var('IMAGE_NAME')
    assert_equal id,          env_var('ID')
    assert_equal 'stateful',  env_var('RUNNER')
    assert_equal sandbox_dir, env_var('SANDBOX')
  end

  def env_var(name)
    cmd = "printenv CYBER_DOJO_#{name}"
    assert_cyber_dojo_sh(cmd)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_cyber_dojo_group_exists
    assert_cyber_dojo_sh("getent group #{group}")
    entries = stdout.split(':')  # cyber-dojo:x:5000
    assert_equal group, entries[0], stdout
    assert_equal group_id, entries[2].to_i, stdout
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_user_home
    home = assert_cyber_dojo_sh('printenv HOME')
    assert_equal home_dir, home

    cd_home_pwd = assert_cyber_dojo_sh('cd ~ && pwd')
    assert_equal home_dir, cd_home_pwd
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_user_properties
    assert_cyber_dojo_sh "[ -d #{sandbox_dir} ]" # sandbox exists

    ls = assert_cyber_dojo_sh "ls -A #{sandbox_dir}"
    refute_equal '', ls # sandbox is not empty

    assert_equal user_id.to_s,  stat_user_dir('u'), 'stat <uid>  sandbox_dir'
    assert_equal group_id.to_s, stat_user_dir('g'), 'stat <gid>  sandbox_dir'
    assert_equal 'drwxr-xr-x',  stat_user_dir('A'), 'stat <perm> sandbox_dir'
  end

  def stat_user_dir(ch)
    assert_cyber_dojo_sh("stat -c '%#{ch}' #{sandbox_dir}")
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_starting_files_properties
    run_cyber_dojo_sh({
      changed_files: { 'cyber-dojo.sh' => stat_cmd }
    })
    assert amber?, json # doing a stat
    assert_equal '', stderr
    assert_equal starting_files.keys.sort, stdout_stats.keys.sort
    starting_files.each do |filename,content|
      if filename == 'cyber-dojo.sh'
        content = stat_cmd
      end
      assert_stats(filename, '-rw-r--r--', content.length)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_ulimits
    assert_cyber_dojo_sh("sh -c 'ulimit -a'")

    assert_equal   0, ulimit(:core_size)
    assert_equal 128, ulimit(:file_locks)
    assert_equal 256, ulimit(:no_files)
    assert_equal 128, ulimit(:processes)

    expected_max_data_size  =  4 * GB / KB
    expected_max_file_size  = 16 * MB / (block_size = 512)
    expected_max_stack_size =  8 * MB / KB

    assert_equal expected_max_data_size,  ulimit(:data_size)
    assert_equal expected_max_file_size,  ulimit(:file_size)
    assert_equal expected_max_stack_size, ulimit(:stack_size)
  end

  KB = 1024
  MB = 1024 * KB
  GB = 1024 * MB

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def ulimit(key)
    table = {             # alpine (sh),               ubuntu
      :core_size  => [ '-c: core file size (blocks)', 'coredump(blocks)'],
      :data_size  => [ '-d: data seg size (kb)',      'data(kbytes)'    ],
      :file_locks => [ '-w: locks',                   'locks'           ],
      :file_size  => [ '-f: file size (blocks)',      'file(blocks)'    ],
      :no_files   => [ '-n: file descriptors',        'nofiles'         ],
      :processes  => [ '-p: processes',               'process'         ],
      :stack_size => [ '-s: stack size (kb)',         'stack(kbytes)'   ],
    }
    row = table[key]
    diagnostic = "no ulimit table entry for #{key}"
    refute_nil row, diagnostic
    if os == :Alpine
      txt = row[0]
    end
    if os == :Ubuntu
      txt = row[1]
    end
    line = stdout.lines.detect { |limit| limit.start_with? txt }
    line.split[-1].to_i
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_baseline_speed
    timings = []
    (1..5).each do
      started_at = Time.now
      assert_cyber_dojo_sh('true')
      stopped_at = Time.now
      diff = Time.at(stopped_at - started_at).utc
      secs = diff.strftime("%S").to_i
      millisecs = diff.strftime("%L").to_i
      timings << (secs * 1000 + millisecs)
    end
    mean = timings.reduce(0, :+) / timings.size
    assert mean < max=1000, "mean=#{mean}ms, max=#{max}ms"
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_files_can_be_in_sub_dirs_of_sandbox
    sub_dir = 'z'
    filename = 'hello.txt'
    content = 'the boy stood on the burning deck'
    run_cyber_dojo_sh({
      changed_files: { 'cyber-dojo.sh' => "cd #{sub_dir} && #{stat_cmd}" },
          new_files: { "#{sub_dir}/#{filename}" => content }
    })
    assert_stats(filename, '-rw-r--r--', content.length)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_files_can_be_in_sub_sub_dirs_of_sandbox
    sub_sub_dir = 'a/b'
    filename = 'goodbye.txt'
    content = 'goodbye cruel world'
    run_cyber_dojo_sh({
      changed_files: { 'cyber-dojo.sh' => "cd #{sub_sub_dir} && #{stat_cmd}" },
          new_files: { "#{sub_sub_dir}/#{filename}" => content }
    })
    assert_stats(filename, '-rw-r--r--', content.length)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_time_stamp_microseconds_granularity
    # On _default_ Alpine date-time file-stamps are to
    # the second granularity. In other words, the
    # microseconds value is always '000000000'.
    # Make sure the tar-piped files have fixed this.
    run_cyber_dojo_sh({
      changed_files: { 'cyber-dojo.sh' => stat_cmd }
    })
    count = 0
    stdout_stats.each do |filename,atts|
      count += 1
      refute_nil atts, filename
      stamp = atts[:time_stamp] # eg '07:03:14.835233538'
      microsecs = stamp.split((/[\:\.]/))[-1]
      assert_equal 9, microsecs.length
      refute_equal '0'*9, microsecs
    end
    assert count > 0, count
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_stats(filename, permissions, size)
    stats = stdout_stats[filename]
    refute_nil stats, filename
    diagnostic = { filename => stats }
    assert_equal permissions, stats[:permissions], diagnostic
    assert_equal user_id, stats[:user ], diagnostic
    assert_equal group, stats[:group], diagnostic
    assert_equal size, stats[:size ], diagnostic
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def stdout_stats
    Hash[stdout.lines.collect { |line|
      attr = line.split
      [attr[0], { # filename
        permissions: attr[1],
               user: attr[2].to_i,
              group: attr[3],
               size: attr[4].to_i,
         time_stamp: attr[6],
      }]
    }]
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def stat_cmd;
    # Works on Ubuntu and Alpine
    'stat -c "%n %A %u %G %s %y" *'
    # hiker.h  -rw-r--r--  40045  cyber-dojo 136  2016-06-05 07:03:14.539952547
    # |        |           |      |          |    |          |
    # filename permissions user   group      size date       time
    # 0        1           2      3          4    5          6

    # Stat
    #  %z == time of last status change
    #  %y == time of last data modification <<=====
    #  %x == time of last access
    #  %w == time of file birth
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def print_bomb
    [ '#include "hiker.h"',
      '#include <stdio.h>',
      '',
      'int answer(void)',
      '{',
      '    for(;;)',
      '    {',
      '        fputs("Hello, world on stdout", stdout);',
      '        fflush(stdout);',
      '        fputs("Hello, world on stderr", stderr);',
      '        fflush(stderr);',
      '    }',
      '    return 6 * 7;',
      '}'
    ].join("\n")
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def fork_bomb
    [ '#include "hiker.h"',
      '#include <stdio.h>',
      '#include <unistd.h>',
      '',
      'int answer(void)',
      '{',
      '    for(;;)',
      '    {',
      '        int pid = fork();',
      '        fprintf(stdout, "fork() => %d\n", pid);',
      '        fflush(stdout);',
      '        if (pid == -1)',
      '            break;',
      '    }',
      '    return 6 * 7;',
      '}'
    ].join("\n")
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def shell_fork_bomb
    [
      'bomb()',
      '{',
      '   echo "bomb"',
      '   bomb | bomb &',
      '}',
      'bomb'
    ].join("\n")
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def exhaust_file_handles
    [ '#include "hiker.h"',
      '#include <stdio.h>',
      '',
      'int answer(void)',
      '{',
      '  for (int i = 0;;i++)',
      '  {',
      '    char filename[42];',
      '    sprintf(filename, "wibble%d.txt", i);',
      '    FILE * f = fopen(filename, "w");',
      '    if (f)',
      '      fprintf(stdout, "fopen() != NULL %s\n", filename);',
      '    else',
      '    {',
      '      fprintf(stdout, "fopen() == NULL %s\n", filename);',
      '      break;',
      '    }',
      '  }',
      '  return 6 * 7;',
      '}'
    ].join("\n")
  end

  def printed?(text)
    count = (stdout+stderr).lines.count { |line| line.include?(text) }
    count > 0
  end

end
