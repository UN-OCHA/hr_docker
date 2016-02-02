# Tweaks and tips to get HRinfo running on OSX.

OSX can't run Docker in a native way, so a VM is required to install the bits
and pieces from HRinfo.

## Option 1: Manual Setup

Use the instructions in SETUP.md for installing docker and dnsdock manually.

## Option 2: Semi-Automated Setup

There are several helper tools available for OSX. You will need to complete
each of the steps, which have been adjusted for installation on OSX.

### Install Docker and Related Dev Tools

Install Docker Compose. Although you may use other methods to install Docker, this is the method which has been tested for these instructions.

````
curl -L https://github.com/docker/compose/releases/download/1.2.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
````

Install the dev tools provided by Phase2. You will need to request access to the repository [_devtools_vm](https://bitbucket.org/phase2tech/_devtools_vm).

1. Create a new directory, `~/Projects`, and change into this directory (`cd ~/Projects`).
2. Clone the dev tools repo: `git clone https://bitbucket.org/phase2tech/_devtools_vm.git`
3. Change into the dev tools repository: `cd ~/Projects/_devtools_vm`

From the \_devtools_vm repository, read and complete all of the instructions in `README.md` file. As part of this process you will install VirtualBox. If you have previously installed VirtualBox, ensure you are running at least version 5.

By the end of this section, you should have installed Docker, and have one container running. You can check this by running the command `docker ps`. You should get output which is similar to the following (one container running):

````
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                                            NAMES
f5336356adde        phase2/dnsdock      "/dnsdock -domain=vm"    14 hours ago        Up 14 hours         172.17.42.1:53->53/udp                           dnsdock
````

Each time you start working on a ticket, ensure this docker container is running.

### Configure DNS for the `.vm` Domain Name

Ensure your containers are available on the `.vm` domain name.

1. Make sure the dns container from Phase2 is running. You can verify which containers are running with the command: `docker ps`
2. Add the nameserver to your configuration files: `echo 'nameserver 172.17.42.1' | sudo tee /etc/resolver/vm`

### Adjust the Local Build Files for OSX

1. Navigate to your home directory: `cd ~`.
2. Clone this repository: `git clone https://github.com/humanitarianresponse/hr_docker.git hrdocker`
3. Change into this repository: `cd hrdocker`
4. Checkout a new branch for local modifications: `git checkout -b local`
5. Create a new file `.password`, and add the password for `snapshots.humanitarianresponse.info`.
6. Modify `docker-compose.yml`. Remove: `/data/hrinfo/pgsql:/var/lib/pgsql/9.3/data`
7. Modify `build.sh`. Replace:

````
  cp hrinfo_snapshot.sh ./data/hrinfo/pgsql
  docker exec -it $DOCKER_PGSQL sh /var/lib/pgsql/9.3/data/hrinfo_snapshot.sh $PASSWORD
````

with:

````
  docker exec -it $DOCKER_PGSQL sh /tmp/hrinfo_snapshot.sh $PASSWORD
````

### Authenticate on Docker Hub

To complete all of the installation steps, you will need to login to the docker
hub as `rw-infra`. You may do this now:

````
$ docker login
````

You will be prompted for a username, password, and email. The credentials are stored in `UN OCHA Infrastructure Operations Manual`.


### Setup the HR.info Site

1. Navigate to the `hr_docker` repository folder: `cd ~/hrdocker`
1. Clone the HR.info site repository into a sub-folder named `code`:
````
git clone --branch=dev git@github.com:humanitarianresponse/site.git code
````
2. Build the docker containers: `docker-compose build`
3. Start the docker containers: `docker-compose up &`
4. Download the database snapshot and install Drupal in your docker container by running the setup script: `./build.sh`.

After running the command `docker-compose up` you should have four new containers running as follows:

````
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                                            NAMES
2fdcf00fa212        hrdocker_web        "/usr/bin/supervisord"   3 days ago          Up 7 seconds        80/tcp, 443/tcp, 1080/tcp                        hrdocker_web_1
42db72d25d7e        unocha/solr3        "/opt/bin/supervised_"   4 days ago          Up 8 seconds        8984/tcp                                         hrdocker_solr3_1
dd987f144619        mailhog/mailhog     "/go/bin/MailHog"        4 days ago          Up 8 seconds        0.0.0.0:1025->1025/tcp, 0.0.0.0:8025->8025/tcp   hrdocker_mailhog_1
1a406cd2a0fa        unocha/postgres93   "/opt/bin/supervised_"   4 days ago          Up 8 seconds        5432/tcp                                         hrdocker_pgsql_1
````

#### Troubleshooting

@TODO: There are known issues with the way VirtualBox handles permissions on mounted volumes. If you have errors when you run the script `build.sh` about not being able to make directories, or change ownership. This is probably relates to how OSX is mounting the shared volumes. There are boot2docker issues about this which point to VirtualBox as being the underlying problem. Changing the permissions "by hand" on the relevant Drupal folders may provide a sufficient work-around.

### View Your Dev Site

In a Web browser, go to http://www.hrinfo.vm. The site should run properly (it might take a while to respond the first time).

## Troubleshooting

If you get the following error:

````
Error response from daemon: no such id: hrinfo_pgsql_1
Error response from daemon: no such id: hrinfo_pgsql_1
(etc)
````

1. Ensure the docker images for these containers are running: `docker ps`
2. If the containers are not running, ensure you have started the Phase2 dev tools environment (instructions in section: Setup Common Dev Tools).
3. If the containers are running, it is likely you cloned the repository `hr_docker` without setting the folder name to `hrdocker`. This causes a name mismatch as the build script creates the name for the images from the current directory. You can force-set the machine names as follows: 
   1. Modify `build.sh`.
   2. Update the values for the variables `DOCKER_PGSQL` and `DOCKER_WEB` to use `hrdocker` instead of `${BASE}`.
   3. Re-run `build.sh`.

## Useful Commands

To find a list of running containers (and their names), use:

````
$ docker ps
````

You can get a root shell in a running container by running:

````
$ docker exec -it <container name> bash
````

If you need to destroy all images and containers (frees up space):

List all containers:
````
$ docker ps
````

stop individual containers:
````
$ docker stop <container name>
````

remove all containers and images (cannot be reversed! use this if troubleshooting an installation problem):
````
docker rm $(docker ps -a -q)
docker rmi $(docker images -q)
````

Resetting your password via Drush (must be completed from within the container):

````
$ docker exec -it hrdocker_web_1 bash
# cd /var/www/html/sites/www.hrinfo.vm
# drush upwd --password="1234" "email@yourHIDlogin.com"
````
