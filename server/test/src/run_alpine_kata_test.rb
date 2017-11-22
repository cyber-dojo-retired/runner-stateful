require_relative 'test_base'

class RunAlpineKataTest < TestBase

  def self.hex_prefix
    '89079'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'CA0', %w( [Alpine] image is indeed based on Alpine ) do
    etc_issue = assert_docker_run 'cat /etc/issue'
    assert etc_issue.include?('Alpine'), etc_issue
  end

end
