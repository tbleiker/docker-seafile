#!/bin/bash

SEAFILE_INSTALL_DIR=${SEAFILE_ROOT_DIR}/seafile-server-latest


# function to run some commands as user seafile
run_as_user() {
   # use -m to preserve environment variables
   su seafile -s /bin/bash -m -c "$1"
}


# stop seafile server if running and continue, exit otherwise
if [[ $SEAFILE_SERVICES == *"seafile"* ]]; then
   run_as_user "${SEAFILE_INSTALL_DIR}/seafile.sh stop"
else
   echo "seafile server not running"
   exit
fi

echo "Giving the server some time to shut down..."
sleep 5


# run garbage cleaner as user seafile
(
   run_as_user "${SEAFILE_INSTALL_DIR}/seaf-gc.sh "$@" | tee -a $SEAFILE_DATA_DIR/logs/gc.log"
   # preserve the exit code of seaf-gc.sh
   exit "${PIPESTATUS[0]}"
)
gc_exit_code=$?


echo "Giving the server some time..."
sleep 3
run_as_user "${SEAFILE_INSTALL_DIR}/seafile.sh start"


exit $gc_exit_code
