require_relative 'test_base'
require_relative '../../src/all_avatars_names'

class AllAvatarsNamesTest < TestBase

  include AllAvatarsNames

  def self.hex_prefix; '7BE'; end

  # - - - - - - - - - - - - - - - - -

  test '229',
  'avatars_names are in sorted order for uid-indexing' do
    assert_equal all_avatars_names.sort, all_avatars_names
  end

end
