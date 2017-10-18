
* [Take me to cyber-dojo's home github repo](https://github.com/cyber-dojo/cyber-dojo).
* [Take me to the http://cyber-dojo.org site](http://cyber-dojo.org).

<img width="707" alt="cyber-dojo-screen-shot" src="https://cloud.githubusercontent.com/assets/252118/25101292/9bdca322-23ab-11e7-9acb-0aa5f9c5e005.png">

- - - -

[![Build Status](https://travis-ci.org/cyber-dojo/runner_stateful.svg?branch=master)](https://travis-ci.org/cyber-dojo/runner_stateful)

<img src="https://raw.githubusercontent.com/cyber-dojo/nginx/master/images/home_page_logo.png"
alt="cyber-dojo yin/yang logo" width="50px" height="50px"/>

# cyberdojo/runner_stateful docker image

- A stateful micro-service for [cyber-dojo](http://cyber-dojo.org)
- Runs an avatar's tests.

API:
  * All methods receive their named arguments in a json hash.
  * All methods return a json hash with a single key.
    * If the method completes, the key equals the method's name.
    * If the method raises an exception, the key equals "exception".

- - - -

# GET image_pulled?
Asks whether the image with the given image_name has been pulled.
- parameters, eg
```
  { "image_name": "cyberdojofoundation/gcc_assert",
       "kata_id": "15B9AD6C42"
  }
```
- returns true if it has, false if it hasn't.
```
  { "image_pulled?": true  }
  { "image_pulled?": false }
```

# POST image_pull
Pulls the image with the given image_name.
- parameters, eg
```
  { "image_name": "cyberdojofoundation/gcc_assert",
       "kata_id": "15B9AD6C42"
  }
```
- returns true if the pull succeeded, false if it failed.
```
  { "image_pull": true  }
  { "image_pull": false }
```

- - - -

# GET kata_exists?
Asks whether the kata with the given kata_id exists.
- parameters, eg
```
  { "image_name": "cyberdojofoundation/gcc_assert",
       "kata_id": "15B9AD6C42"
  }
```
- returns true if it does, false if it doesn't.
```
  { "kata_exists?": true  }
  { "kata_exists?": false }
```

# POST kata_new
Sets up the kata with the given kata_id.
Must be called once before any call to avatar_new with the same kata_id.
- parameters, eg
```
  { "image_name": "cyberdojofoundation/gcc_assert",
       "kata_id": "15B9AD6C42"
  }
```

# POST kata_old
Tears down the kata with the given kata_id.
- parameters, eg
```
  { "image_name": "cyberdojofoundation/gcc_assert",
       "kata_id": "15B9AD6C42"
  }
```

- - - -

# GET avatar_exists?
Asks whether the avatar with the given avatar_name
has entered the kata with the given kata_id.
- parameters, eg
```
  {  "image_name": "cyberdojofoundation/gcc_assert",
        "kata_id": "15B9AD6C42",
    "avatar_name": "salmon"
  }
```
- returns true if it does, false if it doesn't
```
  { "avatar_exists?": true  }
  { "avatar_exists?": false }
```

# POST avatar_new
Sets up the avatar with the given avatar_name, in the
kata with the given kata_id_, with the given starting files.
Must be called once before any call to run with the same
kata_id and avatar_name.
- parameters, eg
```
  {     "image_name": "cyberdojofoundation/gcc_assert",
           "kata_id": "15B9AD6C42",
       "avatar_name": "salmon",
    "starting_files": { "hiker.h": "#ifndef HIKER_INCLUDED...",
                        "hiker.c": "#include...",
                        ...
                      }
  }
```

# POST avatar_old
Tears down the avatar with the given avatar_name,
in the kata with the given kata_id.
- parameters, eg
```
  {  "image_name": "cyberdojofoundation/gcc_assert",
        "kata_id": "15B9AD6C42",
    "avatar_name": "salmon"
  }
```

- - - -

# POST run
For the avatar with the given avatar_name, in the kata with the given kata_id,
removes the deleted_filenames, saves changed_files, runs cyber-dojo.sh
Calls to run must be preceeded by one call to kata_new with the same kata_id,
and one call to avatar_new with the same kata_id and avatar_name.
- parameters, eg
```
  {        "image_name": "cyberdojofoundation/gcc_assert",
              "kata_id": "15B9AD6C42",
          "avatar_name": "salmon",
    "deleted_filenames": [ "hiker.h", "hiker.c", ... ],
        "changed_files": { "fizz_buzz.h": "#ifndef FIZZ_BUZZ_INCLUDED...",
                           "fizz_buzz.c": "#include...",
                           ...
                         },
          "max_seconds": 10
  }
```
- returns status, stdout, stderr, and colour.
If the run completed in max_seconds,
the [traffic-light colour](http://blog.cyber-dojo.org/2014/10/cyber-dojo-traffic-lights.html)
will be "red", "amber", or "green". eg
```
    { "run": {
        "status": 2,
        "stdout": "makefile:17: recipe for target 'test' failed\n",
        "stderr": "invalid suffix sss on integer constant",
        "colour": "red"
    }
```
If the run did not complete in max_seconds,
the [traffic-light colour](http://blog.cyber-dojo.org/2014/10/cyber-dojo-traffic-lights.html)
will be "timed_out". eg
```
    { "run": {
        "status": 137,
        "stdout": "",
        "stderr": "",
        "colour": "timed_out"
    }
```

- - - -
- - - -

# build the docker images
Builds the runner-server image and an example runner-client image.
```
$ ./sh/build_docker_images.sh
```

# bring up the docker containers
Brings up a runner-server container and a runner-client container.

```
$ ./sh/docker_containers_up.sh
```

# run the tests
Runs the runner-server's tests from inside a runner-server container
and then the runner-client's tests from inside the runner-client container.
```
$ ./sh/run_tests_in_containers.sh
```

# run the demo
```
$ ./sh/run_demo.sh
```
Runs inside the runner-client's container.
Calls the runner-server's micro-service methods
and displays their json results and how long they took.
If the runner-client's IP address is 192.168.99.100 then put
192.168.99.100:4558 into your browser to see the output.
- red: tests ran but failed
- amber: tests did not run (syntax error)
- green: tests test and passed
- grey: tests did not complete (in 3 seconds)

# demo screenshot

![red amber green demo](img/red_amber_green_demo.png?raw=true "red amber green demo")
