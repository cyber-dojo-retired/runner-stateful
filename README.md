
[![Build Status](https://travis-ci.org/cyber-dojo/runner.svg?branch=master)]
(https://travis-ci.org/cyber-dojo/runner)

<img src="https://raw.githubusercontent.com/cyber-dojo/nginx/master/images/home_page_logo.png"
alt="cyber-dojo yin/yang logo" width="50px" height="50px"/>

# cyberdojo/runner docker image

- A micro-service for [cyber-dojo](http://cyber-dojo.org)
- Runs an avatar's tests.

There are three runner implementations in this repo with varying
speed/sharing/security tradeoffs. They all use the same tests.
Pick your runner by specifying CYBER_DOJO_RUNNER_CLASS in docker-compose.yml
  * [DockerKavaVolumeRunner](https://github.com/cyber-dojo/runner/blob/master/server/src/docker_kata_container_runner.rb)
  * [DockerAvatarVolumeRunner](https://github.com/cyber-dojo/runner/blob/master/server/src/docker_avatar_volume_runner.rb)
  * [DockerKataContainerRunner](https://github.com/cyber-dojo/runner/blob/master/server/src/docker_kata_volume_runner.rb)

API:
  * All methods receive their arguments in a json object.
  * All methods return a json object with a single key.
  * If successful, the key equals the method's name.
  * If unsuccessful, the key equals "exception".

- - - -

# kata_exists?
Asks whether the kata with the given kata_id exists.
- parameters, eg
```
  { "image_name": "cyberdojofoundation/gcc_assert",
       "kata_id": "15B9AD6C42"
  }
```
- returns true if it does, false if it doesn't.
```
  { "kata_exists?": true   }
  { "kata_exists?": false  }
```

# new_kata
The kata with the given kata_id has been set up.
Must be called before new_avatar.
- parameters, eg
```
  { "image_name": "cyberdojofoundation/gcc_assert",
       "kata_id": "15B9AD6C42"
  }
```
# old_kata
The kata with the given kata_id has been torn down.
- parameters, eg
```
  { "image_name": "cyberdojofoundation/gcc_assert",
       "kata_id": "15B9AD6C42"
  }
```

- - - -

# avatar_exists?
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
  { "avatar_exists?": true   }
  { "avatar_exists?": false  }
```

# new_avatar
The avatar with the given avatar_name has entered the
kata with the given kata with the given starting files.
Must be called before run.
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

# old_avatar
The avatar with the given avatar_name_ has left
the kata with the given kata_id.
- parameters, eg
```
  {  "image_name": "cyberdojofoundation/gcc_assert",
        "kata_id": "15B9AD6C42",
    "avatar_name": "salmon"
  }
```

- - - -

# run
For the avatar with the given avatar_name, in the kata with the given kata_id,
removes the deleted_filenames, saves changed_files, runs cyber-dojo.sh
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
- returns an integer status, stdout, and stderr, if the run completed in max_seconds, eg
```
    { "run": {
        "status": 2,
        "stdout": "makefile:17: recipe for target 'test' failed\n",
        "stderr": "invalid suffix sss on integer constant"
    }
```
- returns the string status "timed_out" if the run did not complete in max_seconds, eg
```
    { "run": { "status": "timed_out" } }
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
- amber: tests did not run (syntax error)
- green: tests test and passed
- grey: tests did not complete (in 3 seconds)

![Alt text](red_amber_green_demo.png?raw=true "title")
