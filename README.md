
[![Build Status](https://travis-ci.org/cyber-dojo/runner.svg?branch=master)](https://travis-ci.org/cyber-dojo/runner)

<img src="https://raw.githubusercontent.com/cyber-dojo/nginx/master/images/home_page_logo.png" alt="cyber-dojo yin/yang logo" width="50px" height="50px"/>

# cyberdojo/runner docker image

A micro-service for [cyber-dojo](http://cyber-dojo.org).
A **cyberdojo/runner** docker container runs sinatra on port 4557.
It's API is as follows:

- - - -

# pulled
Asks the runner-service if the given image has been pulled.
- parameters
  * image_name, eg 'cyberdojofoundation/gcc_assert'
- returns
  * { "status":true  } -> image_name has been pulled
  * { "status":false  } -> image_name has not been pulled

- - - -

# pull
Tells the runner-service to pull the given image.
- parameters
  * image_name, eg 'cyberdojofoundation/gcc_assert'
- returns
  * { "status":0  } -> succeeded

- - - -

# new_kata
Tells the runner-service a kata with the given id and image_name has been set up.
Must be called before new_avatar.
- parameters
  * image_name, eg 'cyberdojofoundation/gcc_assert'
  * kata_id, eg '15B9AD6C42'
- returns
  * { "status":0  } -> succeeded

- - - -

# old_kata
Tells the runner-service the kata with the given id has been torn down.
- parameters
  * kata_id, eg '15B9AD6C42'
- returns
  * { "status":0 } -> succeeded

- - - -

# new_avatar
Tells the runner-service the given avatar has entered the given kata with the given starting files.
Must be called before run.
- parameters
  * image_name, eg 'cyberdojofoundation/gcc_assert'
  * kata_id, eg '15B9AD6C42'
  * avatar_name, eg 'salmon'
  * starting_files, eg { 'fizz_buzz.h' => '#include', ... }
- returns
  * { "status":0 } -> succeeded

- - - -

# old_avatar
Tells the runner-service the given avatar has left the given kata.
- parameters
  * kata_id, eg '15B9AD6C42'
  * avatar_name, eg 'salmon'
- returns
  * { "status":0 } -> succeeded

- - - -

# run
- Runs cyber-dojo.sh for the given avatar in the given kata, after:
  * removing the deleted_filenames
  * saving changed_files
- parameters
  * image_name, eg 'cyberdojofoundation/gcc_assert'
  * kata_id, eg '15B9AD6C42'
  * avatar_name, eg 'salmon'
  * deleted_filenames, eg [ 'hiker.h', ... ]
  * changed_files, eg { 'fizz_buzz.h' => '#include', ... }
  * max_seconds, eg '10'
- returns
  * { "status":integer,   "stdout":..., "stderr":... } -> completed
  * { "status":"timed_out", "stdout":"", "stderr":"" } -> did not complete in max_seconds

- - - -

- if something unexpected goes wrong all methods return a ["status","stdout","stderr"]
triple with status equal to a (non "timed_out") string.


- - - -
- - - -

# build the docker images
Builds the runner-server image and an example runner-client image.
```
$ ./build.sh
```

# bring up the docker containers
Brings up a runner-server container and a runner-client container.

```
$ ./up.sh
```

# run the tests
Runs the runner-server's tests from inside a runner-server container
and then the runner-client's tests from inside the runner-client container.
```
$ ./test.sh
```

# run the demo
```
$ ./demo.sh
```
Runs inside the runner-client's container.
Calls the runner-server's micro-service methods
and displays their json results and how long they took.
If the runner-client's IP address is 192.168.99.100 then put
192.168.99.100:4558 into your browser to see the output.
- red: tests ran but failed
- amber: tests did not run (eg syntax error)
- green: tests test and passed
- grey: tests did not complete (in 3 seconds)

![Alt text](red_amber_green_demo.png?raw=true "title")
