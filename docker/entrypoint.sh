#!/bin/bash

SEAFILE_INSTALL_DIR=${SEAFILE_ROOT_DIR}/seafile-server-latest

# set local to get rid of some warnings when starting seafile/seahub
export LANG=C.UTF-8
export LC_ALL=C.UTF-8


# function to run some commands as user seafile
run_as_user() {
   # use -m to preserve environment variables
   su seafile -s /bin/bash -m -c "$1"
}


setup_seafile() {
   # command to setup seafile with sqlite3
   # note: do not specify parameter -d --> data folder is moved and linked afterwards
   cmd="${SEAFILE_INSTALL_DIR}/setup-seafile.sh auto "
   cmd+="-n $SEAFILE_SERVER_NAME "
   cmd+="-i $SEAFILE_SERVER_IP "
   cmd+="-p $SEAFILE_SERVER_PORT "
   
   run_as_user "$cmd"
   
   # prevent seahub to ask for admin email and password on first startup
   sed -i 's/= ask_admin_email()/= '"\"${SEAHUB_ADMIN_EMAIL}\""'/' ${SEAFILE_INSTALL_DIR}/check_init_admin.py
   sed -i 's/= ask_admin_password()/= '"\"${SEAHUB_ADMIN_PWD}\""'/' ${SEAFILE_INSTALL_DIR}/check_init_admin.py
   
   # start and stop seafile/seahub in order to let them create some additional folders/files
   run_as_user "${SEAFILE_INSTALL_DIR}/seafile.sh start"
   run_as_user "${SEAFILE_INSTALL_DIR}/seahub.sh start"
   run_as_user "${SEAFILE_INSTALL_DIR}/seafile.sh stop"
   run_as_user "${SEAFILE_INSTALL_DIR}/seahub.sh stop"
   
   # move some folders to volume $SEAFILE_DATA_DIR to allow persistant storage
   for DIR in "ccnet" "conf" "logs" "seafile-data" "seahub-data"; do
      mv ${SEAFILE_ROOT_DIR}/$DIR $SEAFILE_DATA_DIR
   done
   
   # if sqlite is used, move seahub.db to volume $SEAFILE_DATA_DIR as well 
   if [ -e ${SEAFILE_ROOT_DIR}/seahub.db ]; then
      mv ${SEAFILE_ROOT_DIR}/seahub.db $SEAFILE_DATA_DIR
   fi
   
   # note: symlinks will be created whenever the script is run
}


update_seafile() {
   # to be implemented soon... :)
   sleep 1
}


shutdown() {
   # shut down both services regardless of wehter both are running
   run_as_user "${SEAFILE_INSTALL_DIR}/seafile.sh stop"
   run_as_user "${SEAFILE_INSTALL_DIR}/seahub.sh stop"
}


trap shutdown SIGINT SIGTERM


# set timezone
ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
echo $TIMEZONE > /etc/timezone


# if there is no version file on the volume $SEAFILE_DATA_DIR, assume that seafile
# is not yet installed -> install it!
if [ ! -e "$SEAFILE_DATA_DIR/version" ]; then
   setup_seafile
   
   # having installed seafile, create the version file
   touch $SEAFILE_DATA_DIR/version
   chown seafile:seafile $SEAFILE_DATA_DIR/version
   echo "$SEAFILE_VERSION" > $SEAFILE_DATA_DIR/version
fi


# check the verion and run the updates if necessary
check_version=`fgrep -c "$SEAFILE_VERSION" $SEAFILE_DATA_DIR/version`
if [ $check_version -eq 0 ]; then
   update_seafile
fi


# symlink the folders on the volume $SEAFILE_DATA_DIR
for DIR in "ccnet" "conf" "logs" "seafile-data" "seahub-data"; do
   ln -s $SEAFILE_DATA_DIR/$DIR ${SEAFILE_ROOT_DIR}/$DIR
done

# if sqlite is used, symlink the database seahub.db as well
if [ -e ${SEAFILE_DATA_DIR}/seahub.db ]; then
   ln -s $SEAFILE_DATA_DIR/seahub.db ${SEAFILE_ROOT_DIR}/seahub.db
fi

# now set all settings which can be specified with environment variables
crudini --set ${SEAFILE_DATA_DIR}/conf/seafdav.conf WEBDAV enabled $SEAFDAV_ENABLED
crudini --set ${SEAFILE_DATA_DIR}/conf/seafdav.conf WEBDAV port $SEAFDAV_PORT
crudini --set ${SEAFILE_DATA_DIR}/conf/seafdav.conf WEBDAV fastcgi $SEAFDAV_FASTCGI
crudini --set ${SEAFILE_DATA_DIR}/conf/seafdav.conf WEBDAV share_name $SEAFDAV_SHARE_NAME

if [ ! -z ${SYNC_BACKUP_URL} ]; then
   crudini --set ${SEAFILE_DATA_DIR}/conf/seafile.conf backup backup_url ${SYNC_BACKUP_URL}
   crudini --set ${SEAFILE_DATA_DIR}/conf/seafile.conf backup sync_token ${SYNC_TOKEN}
elif [ ! -z ${SYNC_PRIMARY_URL} ]; then
   crudini --set ${SEAFILE_DATA_DIR}/conf/seafile.conf backup primary_url ${SYNC_PRIMARY_URL}
   crudini --set ${SEAFILE_DATA_DIR}/conf/seafile.conf backup sync_token ${SYNC_TOKEN}
   crudini --set ${SEAFILE_DATA_DIR}/conf/seafile.conf backup sync_poll_intervall ${SYNC_POLL_INVERVALL}
else
   crudini --del ${SEAFILE_DATA_DIR}/conf/seafile.conf backup
fi


# start services
if [[ $SEAFILE_SERVICES == *"seafile"* ]]; then
   run_as_user "${SEAFILE_INSTALL_DIR}/seafile.sh start"
   log=${SEAFILE_ROOT_DIR}/logs/seafile.log
fi
if [[ $SEAFILE_SERVICES == *"seahub"* ]]; then
   run_as_user "${SEAFILE_INSTALL_DIR}/seahub.sh start"
   log=${SEAFILE_ROOT_DIR}/logs/seahub.log
fi

run_as_user "tail -n 0 -f $log"
