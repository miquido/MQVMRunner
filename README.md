# MQVMRunner
A GitLab pipeline runner for running builds in virtual machine on Apple Silicon Macs.

## Prerequisites
- [Tart](https://tart.run/) installed
- [GitLab Runner](https://docs.gitlab.com/runner/install/osx.html) installed

## Installation
Installation process consists of several steps:
- creating base VM image
- setting SSH key
- setting up GitLab runner
- setting up GitLab CI

## Create base VM image
To create VM image, you need to IPSW file with desired version of macOS - you can get one [here](https://ipsw.me/product/Mac)
Create a VM with command:

``
tart create <VM_NAME> --from-ipsw <PATH_TO_IPSW_FILE> --disk-size 150
tart run <VM_NAME>
``

Follow process to finish OS installation, including account creation.
Once initial system is set up, you need to tweak some system settings:
- turn on remote login on `General -> Sharing -> Remote Login`
- set your newly created user in `Users & Groups -> Automatically log in as`
- in `Lock Screen` section set to `Never` following:
  - Start Screen saver when inactive
  - Turn display off when inactive
  - Require password after screen saver begins or display is turned off.

Finally, you need to set up all tools for your build flow, like Xcode, fastlane etc.
Once base image is ready, it will be used as a snapshot for all builds.

### Finding VM IP address
Just run `tart ip <VM NAME>` on host machine - ip address will be echoed to console.

### Moving data between host and VM
*Copy/paste* is not possible between host and VM. However, there are a few options to deal with moving data:
- if you need to send just text, you can do that with NetCat 
  - run `nc -l 2137` on receiving machine (for example, VM)
  - run `nc <RECEIVING MACHINE IP> 2137` on sending machine and then type/paste content you want to send
- if you need to pass single file, you can do that with `scp`
- if you need to transfer multiple files or transfer them in both directions, perhaps easiest would be to mount directory from host as volume on VM. To do so, simply run VM with option like: `tart run --dir=<MOUNT NAME>:<PATH TO DIR ON HOST> <VM NAME>` 
- alternatively, you can use network and login to machine via Finder.

## Setup GitLab runner
To set up runner on host machine, you need to have its registration token obtained from CI configuration.
Clone or download this repository and run `make install` - it will build MQVMRunner executable and perform setup by asking you a few questions:
- where you would like to store scripts for runner
- username for VM, which you configured during VM setup
- authorization method to your VM for runner, one of:
  - password - password you configured for your VM user during VM setup
  - private key - path to private key which would be used for authorization (for configuration, see below). ECDSA and ED25519 keys are supported.
- GitLab instance URL (i.e. https://gitlab.com/)
- GitLab runner registration token
- path for GitLab cache (optional)

Alternatively, you can set up runner manually by:
- running `gitlab-runner register` command - use "custom" executor
- running `make build` to build MQVMRunner executable
- copying scripts from `scripts` directory to location of your choice and replacing placeholders with actual values
  - RUNNER_PATH - path to MQVMRunner executable
  - VM_USER - username for VM
  - AUTH - `--private-key <path to private key>` if you want to authenticate with private key or `--password-authorization <password>` if you want to use password instead
  - CACHE_MOUNT - `--mount <path to gitlab_cache directory>=Cache` if you want to use GitLab cache or empty string if you don't want to use it
- editing `config.toml` file (located in `~/.gitlab-runner`) and adding modified content of following snippet to your newly created runner:
```
  builds_dir = "/Users/VM_USER/gitlab_builds"
  cache_dir = "/Users/My Shared Files/gitlab_cache" # if you want to use GitLab cache, drop the line otherwise
  [runners.cache]
    MaxUploadedArchiveSize = 0
  [runners.custom]
    prepare_exec = "PATH_TO_SCRIPTS/prepare.sh"
    run_exec = "PATH_TO_SCRIPTS/run.sh"
    cleanup_exec = "PATH_TO_SCRIPTS/cleanup.sh"
```

In both methods, last steps are to install and start runner with `gitlab-runner install` and `gitlab-runner start` commands.

### Authorizing on VM with private key.
If you have set up runner to use private key for authorization, you need to do a few more steps to make it work.
Firstly, if you don't have private key on host machine yet, you need to generate one with `ssh-keygen -t ECDSA` command.
Then, you need to copy public key to VM with `ssh-copy-id -i <path to your newly created key> <VM USER>@<VM IP>` command.

## Setup GitLab CI
Last step is to update your pipeline configuration to use newly created VM for builds.
To do that, add `image: <VM NAME>` to your job definition, like:
```
test-build:
    stage: test
    image: <VM NAME>
    script:
        - xcodebuild (...)
```
## Caching
By default, all builds are done on clean VM, which means that all dependencies are downloaded and installed on each run.
To speed up builds, you can use caching mechanism. Since VM is ephemeral, cache is stored on host machine and mounted to VM as a volume.

### GitLab cache
If you decided to skip GitLab cache during `make install`, you can do it manually as described below.
You can run `make install` again and setup cache there - then you should manually clean up `~/.gitlab-runner/config.toml` to avoid duplicate runner configuration.
To enable GitLab cache manually, you need to perform following steps:
- create directory on host machine, which will be used for storing cache, like `gitlab_cache`.
- edit `~/.gitlab-runner/config.toml` by adding `cache_dir = "/Users/My Shared Files/Cache"` line for your runner. `Cache` will be used as mount name. 
- edit `prepare.sh` script by adding `--mount <path to gitlab_cache directory>=Cache` 
- configure your `.gitlab-ci.yml` to use cache. Check [GitLab documentation](https://docs.gitlab.com/ee/ci/caching/) for details or examples below.
Note that only directories or files from project directory can be cached.

### Shared cache/mounted directories
Shared cache can be a directory on host machine, which is mounted to VM as a volume - it will be available for every project and build.
Additionally, it can be used to share data between host and VMs, like build artifacts.
To share it with VM, you need to perform following steps:
- create directory on host machine, which will be used for storing cache, like `shared_cache`.
- edit `prepare.sh` script by adding `--mount <path to shared cache directory>=SharedCache`

If you need to mount multiple directories, simply add multiple `--mount` arguments.

### Examples
Note: those are just examples to show what is possible - you might adjust them to fit your needs or even drop some parts if you find them irrelevant.

#### Example cache setup for Swift Package Manager with Xcodebuild
```
build:
  stage: Build
  image: BuildVMImage
  cache:
    - key:
        files:
            - <path to Package.resolved>
      paths:
        - SwiftPackageManager/  
```

Update your xcodebuild command to use `SwiftPackageManager` directory as a cache directory, like:
```
xcodebuild (...) -clonedSourcePackagesDirPath SwiftPackageManager
```
This will checkout dependencies to `SwiftPackageManager` directory.
`Package.resolved` will be used as a key for GitLab cache, so unless you change dependencies, it will be used for all builds.

#### Example cache setup for CocoaPods
```
variables:
  CP_HOME_DIR: "/Volumes/My Shared Files/CocoaPods"

build:
  stage: Build
  image: BuildVMImage
  cache:
    - key:
        files:
            - Podfile.lock
      paths:
        - Pods/
```
`CocoaPods` is shared cache directory, replacing default `~/.cocoapods`, so main spec repo will be downloaded only once and shared between subsequent builds.
`Podfile.lock` will be used as a key for GitLab cache, so unless you change dependencies, it will be used for all builds.

## License
Copyright 2023 Miquido

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
