require_relative 'test_base'
require_relative 'os_helper'

class RunAlpineKataTest < TestBase

  include OsHelper

  def self.hex_prefix; '89079'; end

  def hex_setup
    set_image_name image_for_test
    new_kata
  end

  def hex_teardown
    old_kata
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'CA0',
  '[Alpine] image is indeed based on Alpine' do
    etc_issue = assert_docker_exec 'cat /etc/issue'
    assert etc_issue.include?('Alpine'), etc_issue
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '214',
  '[Alpine] container must have tini installed to do zombie reaping' do
    ps = assert_docker_exec 'ps'
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

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '267',
  "[Alpine] none of the 64 avatar's uid's are already taken" do
    refute_avatar_users_exist
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '582',
  '[Alpine] has group used for dir/file ownership' do
    assert_group_exists
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '3B1',
  '[Alpine] after new_kata timeout script is in /usr/bin' do
    src = assert_docker_exec('cat /usr/bin/timeout_cyber_dojo.sh')
    lines = src.split("\n")
    assert_equal '#!/bin/bash', lines[0]
    assert_equal 'AVATAR=$1', lines[1]
  end

end
