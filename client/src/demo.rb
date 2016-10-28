require 'sinatra'
require 'sinatra/base'

require_relative './runner'

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
    json = nil

    duration = timed { json = pulled?(image_name) }
    html += pre('pulled?', duration, json)

    duration = timed { json = pull(image_name) }
    html += pre('pull', duration, json)

    duration = timed { json = hello(kata_id, avatar_name) }
    html += pre('hello', duration, json)

    duration = timed { json =
      execute(image_name, kata_id, avatar_name, max_seconds, deleted_filenames, changed_files)
    }
    html += pre('execute', duration, json)

    duration = timed { json = goodbye(kata_id, avatar_name) }
    html += pre('goodbye', duration, json)
  end

  include Runner

  def read(filename)
    IO.read("/app/start_files/gcc_assert/#{filename}")
  end

  def timed
    started = Time.now
    yield
    finished = Time.now
    '%.2f' % (finished - started)
  end

  def pre(name, duration, json)
    "<pre>/#{name}(#{duration}s)->#{JSON.pretty_unparse(json)}</pre>"
  end

end


