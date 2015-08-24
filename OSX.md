
## Tweaks and tips to get HRinfo running on OSX.

OSX can't run Docker in a native way, so a VM is required to install the bits
and pieces from HRinfo.
You can follow SETUP.md for installing docker and dnsdock manually or you can
download and install Docker Toolbox from https://docs.docker.com/installation/mac/
and install the devtools VM, following the instructions from
https://bitbucket.org/phase2tech/_devtools_vm

## Option 1: Docker machine (formerly known as boot2docker) with devtools_vm

Note: Make sure that the hr_docker repo (this one) is cloned somewhere in your
/Users folder. Docker machine will mount this folder automatically.

1. Clone the repo from https://bitbucket.org/phase2tech/_devtools_vm
2. Follow the README.md from the devtools_vm repository to install the virtualbox VM
3. Make the following modifications to the Dockerfile, docker-compose.yml and build.sh files:
    - Dockerfile: Add the following line just after the install supervisor one.
      RUN usermod -u 1000 www-data
    - docker-compose.yml: Replace `/data/hrinfo/pgsql:/var/lib/pgsql/9.3/data` by
      `./hrinfo_snapshot.sh:/tmp/hrinfo_snapshot.sh`
    - build.sh: Replace
      `cp hrinfo_snapshot.sh ./data/hrinfo/pgsql
       docker exec -it $DOCKER_PGSQL sh /var/lib/pgsql/9.3/data/hrinfo_snapshot.sh $PASSWORD`
      by
      `docker exec -it $DOCKER_PGSQL sh /tmp/hrinfo_snapshot.sh $PASSWORD`

    Note that in build.sh you might also need to change the variables
    DOCKER_PGSQL and DOCKER_WEB  to use `hrinfo` instead of `${BASE}`

4. Create a .password file in which you will put the password of snapshots.humanitarianresponse.info
5. Clone the code in /code: git clone --branch=dev git@github.com:humanitarianresponse/site.git code
6. Build the docker containers with Docker compose: `docker-compose build` from the hr_docker folder.
7. Start the docker containers: `docker-compose up`
8. Run `./build.sh`. This will download the database snapshot and install it in your docker container.
9. In your browser, go to http://www.hrinfo.vm. The site should run properly (it might take a while to respond the first time)

## Option 2: Use Vagrant

@TODO
