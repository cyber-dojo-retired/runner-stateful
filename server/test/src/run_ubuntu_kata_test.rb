require_relative 'test_base'

class RunUbuntuKataTest < TestBase

  def self.hex_prefix
    '2C3B9'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'CA1', %w( [Ubuntu] image is indeed based on Ubuntu ) do
    etc_issue = assert_docker_run 'cat /etc/issue'
    assert etc_issue.include?('Ubuntu'), etc_issue
  end

end
