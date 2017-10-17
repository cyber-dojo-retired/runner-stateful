require_relative 'test_base'

class RunTest < TestBase

  def self.hex_prefix
    '58410'
  end

  def hex_setup
    set_image_name "#{cdf}/gcc_assert"
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '8A9',
  %w( run returns red-amber-green traffic-light colour ) do
    in_kata {
      as('lion') {
        run4({
          avatar_name:'lion',
              kata_id:kata_id
        })
        assert_colour 'red'
      }
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'B82',
  %w( files can be in sub-dirs of sandbox ) do
    in_kata {
      as('salmon') {
        run4({
          changed_files: {
            'a/hello.txt'   => 'hello world',
            'cyber-dojo.sh' => ls_cmd
          }
        })
        ls_files = ls_parse(stdout)
        uid = runner.user_id('salmon')
        group = runner.group
        assert_equal_atts('a', 'drwxr-xr-x', uid, group, 4096, ls_files)
      }
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'B83',
  %w( files can be in sub-sub-dirs of sandbox ) do
    in_kata {
      as('salmon') {
        run4({
          changed_files: {
            'a/b/hello.txt' => 'hello world',
            'cyber-dojo.sh' => "cd a && #{ls_cmd}"
          }
        })
        ls_files = ls_parse(stdout)
        uid = runner.user_id('salmon')
        group = runner.group
        assert_equal_atts('b', 'drwxr-xr-x', uid, group, 4096, ls_files)
      }
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '12B',
  %w( files in sub-dirs of sandbox can be deleted ) do
    in_kata {
      as('salmon') {
        run4({
          changed_files: {
            'a/hello.txt'   => 'hello world',
            'cyber-dojo.sh' => "cd a && #{ls_cmd}"
          }
        })
        ls_files = ls_parse(stdout)
        uid = runner.user_id('salmon')
        group = runner.group
        assert_equal_atts('hello.txt', '-rw-r--r--', uid, group, 11, ls_files)

        run4({
          deleted_filenames: [ 'a/hello.txt' ],
              changed_files: {}
        })
        assert_equal '', stdout
      }
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '1DC',
  %w( run with valid kata_id that does not exist raises ) do
    kata_id = '0C67EC0416'
    assert_raises_kata_id(kata_id, '!exists')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '7FE',
  %w( run with kata_id that exists but invalid avatar_name raises ) do
    in_kata {
      assert_raises_avatar_name(kata_id, 'scissors', 'invalid')
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '951', %w(
  run with kata_id that exists
    and valid avatar_name that does not exist yet
      raises
  ) do
    in_kata {
      assert_raises_avatar_name(kata_id, 'salmon', '!exists')
    }
  end

  private

  def assert_raises_kata_id(kata_id, message)
    error = assert_raises(ArgumentError) {
      run4({ kata_id:kata_id })
    }
    assert_equal "kata_id:#{message}", error.message
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_raises_avatar_name(kata_id, avatar_name, message)
    error = assert_raises(ArgumentError) {
      run4({
            kata_id:kata_id,
        avatar_name:avatar_name
      })
    }
    assert_equal "avatar_name:#{message}", error.message
  end

end
