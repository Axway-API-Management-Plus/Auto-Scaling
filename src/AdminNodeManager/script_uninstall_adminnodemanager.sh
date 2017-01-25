#!/bin/sh -x
. /var/common_variables.sh
echo "UNINSTALL START TIME = $(date)" >> /tmp/admin.log
${VINSTDIR}/apigateway/posix/bin/nodemanager -k
echo "Node Manager stopped"
sleep 60
${VINSTDIR}/apigateway/posix/bin/managedomain --delete_host --host $(hostname -f) --anm_host ${elbdnsname} --username admin --password changeme
echo "Node Manager unregistered from Group"
rm -fr ${VINSTDIR}apigateway/groups/
echo "UNINSTALL FINISH TIME = $(date)" >> /tmp/admin.log
