
## Running a copy of Humanitarianresponse locally

### How to

*Mac users, please see OSX.md instead.*

1. Set up your machine based on the instructions in SETUP.md
2. Build the docker containers with Docker compose: `docker-compose build`
3. Create a .password file in which you will put the password of snapshots.humanitarianresponse.info
4. Clone the code in /code: git clone --branch=dev git@github.com:humanitarianresponse/site.git code
5. Start the docker containers: `docker-compose up`
6. Run the build.sh file as root: sudo ./build.sh. This will download the database snapshot and install it in your docker container.
7. In your browser, go to http://www.hrinfo.vm. The site should run properly (it might take a while to respond the first time)
