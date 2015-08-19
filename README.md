
## Running a copy of Humanitarianresponse locally

### How to

1. Set up your machine based on the instructions in SETUP.md and start dnsdock: docker start dnsdock
1. Build the docker containers with fig: fig build(NOTE: Fig is now deprecated, use docker-compose build instead)
1. Create a .password file in which you will put the password of snapshots.humanitarianresponse.info
1. Clone the code in /code: git clone --branch=dev git@github.com:humanitarianresponse/site.git code
1. Start the docker containers: fig up(NOTE: Fig is now deprecated, use docker-compose up instead)
1. Run the build.sh file as root: sudo ./build.sh or ./build for OS X users. This will download the database snapshot and install it in your docker container.
1. In your browser, go to http://www.hrinfo.vm. The site should run properly (it might take a while to respond the first time)
