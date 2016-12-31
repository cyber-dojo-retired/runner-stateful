
[![Build Status](https://travis-ci.org/cyber-dojo/runner.svg?branch=master)]
(https://travis-ci.org/cyber-dojo/runner)

<img src="https://raw.githubusercontent.com/cyber-dojo/nginx/master/images/home_page_logo.png"
alt="cyber-dojo yin/yang logo" width="50px" height="50px"/>

# cyberdojo/runner docker image

- A micro-service for [cyber-dojo](http://cyber-dojo.org)
- A **cyberdojo/runner** docker container runs on port **4557**.
- Runs avatar's tests in a docker container.
- API:
  * All methods return a json object with a single key.
  * If successful, the key equals the method's name.
  * If unsuccessful, the key equals "exception".

- - - -

# pulled
Asks the runner-service if the given image has been pulled.
- parameter
  * image_name, eg "cyberdojofoundation/gcc_assert"
- returns true if the image has been pulled.
```
  { "pulled":true   }
```
- returns false if the image has not been pulled.
```
  { "pulled":false  }
```

- - - -

# pull
Tells the runner-service to pull the given image.
- parameter
  * image_name, eg "cyberdojofoundation/gcc_assert"

- - - -

# new_kata
Tells the runner-service the kata with the given id
and image_name has been set up.
Must be called before new_avatar.
- parameters
  * image_name, eg "cyberdojofoundation/gcc_assert"
  * kata_id,    eg "15B9AD6C42"

- - - -

# old_kata
Tells the runner-service the kata with the given id
and image_name has been torn down.
- parameters
  * image_name, eg "cyberdojofoundation/gcc_assert"
  * kata_id,    eg "15B9AD6C42"

- - - -

# new_avatar
Tells the runner-service the given avatar has entered
the given kata with the given starting files.
Must be called before run.
- parameters
  * image_name,     eg "cyberdojofoundation/gcc_assert"
  * kata_id,        eg "15B9AD6C42"
  * avatar_name,    eg "salmon"
  * starting_files, eg { "fizz_buzz.h" : "#include...", ... }

- - - -

# old_avatar
Tells the runner-service the given avatar has left the given kata.
- parameters
  * image_name,  eg "cyberdojofoundation/gcc_assert"
  * kata_id,     eg "15B9AD6C42"
  * avatar_name, eg "salmon"

- - - -

# run
- Runs cyber-dojo.sh for the given avatar in the given kata, after:
  * removing the deleted_filenames
  * saving changed_files
- parameters
  * image_name,        eg "cyberdojofoundation/gcc_assert"
  * kata_id,           eg "15B9AD6C42"
  * avatar_name,       eg "salmon"
  * deleted_filenames, eg [ "hiker.h", ... ]
  * changed_files,     eg { "fizz_buzz.h": "#include...", ... }
  * max_seconds,       eg "10"
- returns an integer status if the run completed in max_seconds, eg
```
    { "run": {
        "status": 0,
        "stdout": "All tests passed\n",
        "stderr": ""
    }
```
- returns the status string "timed_out" if the run did not complete in max_seconds, eg
```
    { "run": {
        "status": "timed_out",
        "stdout": "",
        "stderr": ""
    }
```

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
