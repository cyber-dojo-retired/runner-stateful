require_relative 'test_base'

class KataTest < TestBase

  def self.hex_prefix; 'D2E7E'; end

  # - - - - - - - - - - - - - - - - - - - - - - - -
  # positive test cases
  # - - - - - - - - - - - - - - - - - - - - - - - -

  test 'C7A',
  'new_kata/old_kata' do
    new_kata
    old_kata
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -
  # negative test cases
  # - - - - - - - - - - - - - - - - - - - - - - - -

  #...

end
