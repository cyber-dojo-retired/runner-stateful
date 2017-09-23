require_relative 'test_base'
require_relative 'os_helper'

class RunAlpineKataTest < TestBase

  include OsHelper

  def self.hex_prefix
    '89079'
  end

  def hex_setup
    set_image_name image_for_test
    kata_new
  end

  def hex_teardown
    kata_old
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'CA0', %w( [Alpine]
  image is indeed based on Alpine
  ) do
    etc_issue = assert_docker_run 'cat /etc/issue'
    assert etc_issue.include?('Alpine'), etc_issue
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '214', %w( [Alpine]
  image has tini installed to do zombie reaping
  ) do
    ps = assert_docker_run 'ps'
    ps_lines = ps.strip.split("\n")
    # PID   USER     TIME   COMMAND
    #   1   root     0:00   /sbin/tini -- sh -c sleep 1d
    #   5   root     0:00   sh -c sleep 1d
    #   |   |        |      |  |  |
    #   0   1        2      3  4  5 ...
    ps_lines.shift
    procs = Hash[ps_lines.collect { |ps_line|
      ps_atts = ps_line.split
      pid = ps_atts[0].to_i
      cmd = ps_atts[3..-1].join(' ')
      [pid,cmd]
    }]
    refute_nil procs[1], 'no process at pid 1!'
    assert procs[1].include?('/sbin/tini'), 'no tini at pid 1'
  end

end
