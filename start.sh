#!/bin/bash

DATETIME=`date +"%Y-%m-%d_%H"`

if [ "${RESTORE_DB_CHARSET}" = "" ]; then
  export RESTORE_DB_CHARSET=utf8
fi

if [ "${RESTORE_DB_COLLATION}" = "" ]; then
  export RESTORE_DB_COLLATION=utf8_bin
fi

PASS_OPT=

if [ -n $MYSQL_PASSWORD ]; then
    PASS_OPT="--password=${MYSQL_PASSWORD}"
fi


databases=`mysql --user=$MYSQL_USER --host=$MYSQL_HOST --port=$MYSQL_PORT ${PASS_OPT} -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema)"`

for db in $databases; do
    echo "dumping $db"

    mysqldump --force --opt --host=$MYSQL_HOST --port=$MYSQL_PORT --user=$MYSQL_USER --databases $db ${PASS_OPT} | gzip > "/tmp/$db-$DATETIME.gz"

    if [ $? == 0 ]; then
        az storage blob upload --connection-string "DefaultEndpointsProtocol=https;AccountName=$AZURE_STORAGE_ACCOUNT;AccountKey=$AZURE_STORAGE_ACCESS_KEY;EndpointSuffix=core.windows.net" --container-name $AZURE_STORAGE_CONTAINER --name $db-$DATETIME.gz --file /tmp/$db-$DATETIME.gz

        if [ $? == 0 ]; then
            rm /tmp/$db-$DATETIME.gz
        else
            >&2 echo "couldn't transfer $db-$DATETIME.gz to Azure"
        fi
    else
        >&2 echo "couldn't dump $db"
    fi
done