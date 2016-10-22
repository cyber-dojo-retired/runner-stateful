require 'sinatra'
require 'sinatra/base'

require_relative './runner'

class Demo < Sinatra::Base

  get '/' do
    kata_id = 'D4C8A65D61'
    avatar_name = 'lion'
    image_name = 'cyberdojofoundation/gcc_assert'
    max_seconds = 10
    delete_filenames = []
    changed_files = {
      'hiker.c'       => read('hiker.c'),
      'hiker.h'       => read('hiker.h'),
      'hiker.tests.c' => read('hiker.tests.c'),
      'cyber-dojo.sh' => read('cyber-dojo.sh'),
      'makefile'      => read('makefile')
    }
    start(kata_id, avatar_name)
    output = run(image_name, kata_id, avatar_name, max_seconds, delete_filenames, changed_files)

    '<pre>' + output + '</pre>'
  end

  include Runner

  def read(filename)
    IO.read("/app/src/start_files/#{filename}")
  end

end


