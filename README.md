# nuvlabox-os-common
Common configurations and procedures for all NuvlaBox OS images.

## Understanding the process

The build process it stage-based, with a **stage** being any folder containing subfolders that have a **run_stage.sh** file.

The build stages must be mentioned in the configuration file in order to be considered by the build. 

Certain stages and recipes are either inherited or inspired from other open-source projects. For those cases, you'll find the respective original LICENSE notice under the respective stage (i.e. _raspberrypi_).

### Creating your own stage

If you want to create your own custom stage, or add a new recipe to a stage, simply follow these steps:

 1. create your stage folder (if it doesn't exist already)
 
    ```bash
    mkdir -p mystage
    ```
 
 2. inside that folder, create one subfolder per recipe you want to add. For example, let's say your stage will install some packages and also add a new user to the system. One way to do it would be:
 
    ```bash
    mkdir -p mystage/0_install-packages
    mkdir -p mystage/1_users
    ```
    Finally, for it to be considered for exercution, make sure you have your recipe scripts inside, in an executable file called `run_stage.sh`.
    
    ```bash
    # just an example
    cat >mystage/0_install-packages/run_stage.sh <<EOF
    #!/bin/bash
    # your recipe
    EOF
    
    chmod +x mystage/0_install-packages/run_stage.sh
    
    # ...same for all recipes
    ```
    
 3. (optional) do you want your recipes to be executed in a specific order? If so, add a file to the stage folder, called `.order`. By default, recipes are executed alphabetically.
 
    ```bash
    # configure users first
    cat >mystage/.order <<EOF
    1_users
    0_install-packages
    EOF
    ```
 
### Configure your build

There's a file named `config`. That's the baseline. **Please do not touch this file unless you must and you know what you're doing**.

To add new configuration attributes to your build, or to override the original ones from `config`, simple create a new config file:

```bash
touch config.my_machine
```

Inside, you can define whatever build attributes you need. See `config.raspberrypi` as an example.

**NOTE: **In `config` you'll find the explanation and defaults for all the supported build attributes.


### Start a build with Docker (recommended)

It is recommended to build the NuvlaBox OS within a Docker container:

```bash
# if you don't have any custom config, then you don't need to pass any arguments...config is always taken by default
./launch_build_in_docker.sh <config.your_custom_conf>
```

### Start a build

To build a NuvlaBox OS without Docker, it is recommended that you run this script from within a Debian OS.

 ```bash
# if you don't have any custom config, then you don't need to pass any arguments...config is always taken by default
./build.sh <config.your_custom_conf>
```


### Output

At the end of the file, when successfull, you find:
 - the image .zip file in your folder, next to the build script
 - all the build files, including the original .img and .zip files under the WORKDIR, as defined in `config`
    - if you've built with Docker, those will be inside the container...you can restart it to get access
