# Seafile Docker Image 

Yet another attempt to write a docker image for seafile.

_**IMPORTANT NOTE:** This image is still under heavy development! Running this docker image in production might badly break things (even whole data centres...)!_


## Purpose

This image is created with the following in mind:
- only run seafile/seahub in the container (services like mysql, ngnix etc. has to be run separately)
- be able to only run seafile server or seahub in the container
- be able to configure main settings with environment variables 
- write as little additional code as possible (e.g. use existing scripts from seafile and tools like crudini to edit config files)


## Development

**To Do List**
- failure handling in entrypoint.sh (e.g. if seafile setup script fails)
- implement script to run garbage collector
- run update scripts if necessary (none are run at the moment)
- ability to configure (external) mysql
- ability to configure Collabora and Onlyoffice
- ability to set SMTP settings
- ability to set uid/gid of seafile files (incl. uploaded user files)
- ... (you tell me...)


## Usage

Coming soon?
