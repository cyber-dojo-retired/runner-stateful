require 'sinatra'
require 'sinatra/base'

require_relative './runner'

# Leaves behind a docker volume called cyber_dojo_D4C8A65D61_lion

class Demo < Sinatra::Base

  get '/' do
    kata_id = 'D4C8A65D61'
    avatar_name = 'lion'
    image_name = 'cyberdojofoundation/gcc_assert'
    max_seconds = 10
    deleted_filenames = []
    changed_files = {
      'hiker.c'       => read('hiker.c'),
      'hiker.h'       => read('hiker.h'),
      'hiker.tests.c' => read('hiker.tests.c'),
      'cyber-dojo.sh' => read('cyber-dojo.sh'),
      'makefile'      => read('makefile')
    }
    html = ''
    json = pulled?(image_name)
    html += "<pre>/pulled?->#{unparse(json)}</pre>"
    json = pull(image_name)
    html += "<pre>/pull->#{unparse(json)}</pre>"
    json = hello_avatar(kata_id, avatar_name)
    html += "<pre>/hello_avatar->#{unparse(json)}</pre>"
    json = run(image_name, kata_id, avatar_name, max_seconds, deleted_filenames, changed_files)
    html += "<pre>/run->#{unparse(json)}</pre>"
    json = goodbye_avatar(kata_id, avatar_name)
    html += "<pre>/goodbye_avatar->#{unparse(json)}</pre>"
  end

  include Runner

  def read(filename)
    IO.read("/app/src/start_files/#{filename}")
  end

  def unparse(json)
    JSON.pretty_unparse(json)
  end

end


