
[![Build Status](https://travis-ci.org/cyber-dojo/runner.svg?branch=master)](https://travis-ci.org/cyber-dojo/runner)

<img src="https://raw.githubusercontent.com/cyber-dojo/nginx/master/images/home_page_logo.png" alt="cyber-dojo yin/yang logo" width="50px" height="50px"/>

# cyberdojo/runner docker image

Work in progress. Not live yet.
A **cyberdojo/runner** docker container runs sinatra on port 4557.
It's API is as follows:

# pulled_image
Asks the question 'has the runner-server [docker pull]'ed image_name'?
- parameters
  * image_name, eg 'cyberdojofoundation/gcc_assert'
- returns
  * { "status":"true"  } -> pulled already
  * { "status":"false" } -> not pulled already

# pull_image
Commands the runner-server to [docker pull] image_name.
- parameters
  * image_name, eg 'cyberdojofoundation/gcc_assert'
- returns
  * { "status":"ok" } -> pull succeeded

# new_avatar
Informs the runner-server the given avatar will be issuing run commands.
- parameters
  * kata_id, eg '15B9AD6C42'
  * avatar_name, eg 'salmon'
- returns
  * { "status":"ok" } -> succeeded

# old_avatar
Informs the runner-server the given avatar will no longer be issuing run commands.
- parameters
  * kata_id, eg '15B9AD6C42'
  * avatar_name, eg 'salmon'
- returns
  * { "status":"ok" } -> succeeded

# run
Commands the runner-server to run the attached code.
A sequence of run commands must be preceeded by a call to new_avatar.
- parameters
  * image_name, eg 'cyberdojofoundation/gcc_assert'
  * kata_id, eg '15B9AD6C42'
  * avatar_name, eg 'salmon'
  * max_seconds, eg '10'
  * deleted_filenames, eg [ 'hiker.h', ... ]
  * changed_files, eg { 'fizz_buzz.h' => '#include', ... }
- returns
  * { "status":"0",   "stdout":output, "stderr":error } -> completed
  * { "status":"128", "stdout":"", "stderr":"" } -> did not complete in max_seconds

- if something unexpected goes wrong on the server all methods return
  * { "status":"error", "msg":msg } -> something went wrong


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

