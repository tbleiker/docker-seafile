FROM debian:buster-slim

MAINTAINER Tobi Bleiker <to.bleiker@gmail.com>


# the following packages are needed / used in the startup script(s):
#   patch:      to apply patches
#   curl:       to get seafile 
#   curdini:    to handle config files
# the following packages are needed by seafile
#   procps:     pgrep is used in seafile.sh
#   sqlite3:    standard db
#   python*:    needed by seafile
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y patch curl crudini procps sqlite3 python2.7 libpython2.7 \
           python-setuptools python-ldap python-urllib3  python-requests python-pil \
    && apt-get clean


ARG SEAFILE_USER_UID=5342
ARG SEAFILE_USER_GID=5342

ENV SEAFILE_VERSION=7.0.4 \ 
    SEAFILE_ROOT_DIR=/opt/seafile \
    SEAFILE_DATA_DIR=/shared \
    SEAFILE_SERVER_NAME=seafile \
    SEAFILE_SERVER_IP=www.example.com \
    SEAFILE_SERVER_PORT=8082 \
    SEAHUB_ADMIN_EMAIL=admin@example.com \
    SEAHUB_ADMIN_PWD=password \
    SEAFDAV_ENABLED=false \
    SEAFDAV_PORT=8080 \
    SEAFDAV_FASTCGI=false \
    SEAFDAV_SHARE_NAME=/ \
    SYNC_BACKUP_URL= \
    SYNC_PRIMARY_URL= \
    SYNC_TOKEN=c7a78c0210c2470e14a20a8244562ab8ad509734 \
    SYNC_POLL_INVERVALL=3 \
    SEAFILE_SERVICES=seafile,seahub \
    TIMEZONE=Europe/Zurich


RUN groupadd -g ${SEAFILE_USER_GID} seafile \
    && useradd -m -u ${SEAFILE_USER_UID} -g ${SEAFILE_USER_GID} -s /bin/false seafile \
    && mkdir $SEAFILE_ROOT_DIR \
    && mkdir $SEAFILE_DATA_DIR \
    && curl https://download.seadrive.org/seafile-server_${SEAFILE_VERSION}_x86-64.tar.gz | tar xz -C $SEAFILE_ROOT_DIR \
    && ln -s $SEAFILE_ROOT_DIR/seafile-server-${SEAFILE_VERSION} $SEAFILE_ROOT_DIR/seafile-server-latest \
    && chown -R seafile:seafile $SEAFILE_ROOT_DIR \
    && chown -R seafile:seafile $SEAFILE_DATA_DIR

COPY entrypoint.sh run_gc.sh /scripts/


EXPOSE 8000 8082 8080

VOLUME $SEAFILE_DATA_DIR

ENTRYPOINT ["/scripts/entrypoint.sh"]
