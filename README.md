
## Running a copy of Humanitarianresponse locally

### How to

1. Set up your machine based on the instructions in SETUP.md.
1. You may need to build the unocha/apache container: sudo docker build -t unocha/apache .
1. If you're on Linux, it may be much easier to `export FIG_FILE=linux.yml`. If you do, you can remove the `-f linux.yml` from any commands in this README file.
1. Log into the Docker hub with the UN OCHA credentials.
1. Run `fig -f linux.yml up` to start the containers.
1. Create a .password file in which you will put the password of snapshots.humanitarianresponse.info
1. Run the build.sh file as root: sudo ./build.sh. This will download the latest code and database snapshots and install them in your docker containers. When asked for the password of the hrinfo database, enter "hrinfo".
1. In your browser, connect to http://www.hrinfo.vm. The site should run properly (it might take a while to respond the first time)
