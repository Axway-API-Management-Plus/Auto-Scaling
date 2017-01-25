#!/bin/sh -x
. /var/common_variables.sh
echo ${elbdnsname}
echo ${csrkeyloc}
### Download the CSR to local 
#aws s3 cp  $csrkeyloc unprotected.p12
wget -q https://s3.amazonaws.com/admin-node-manager/CSR%2Bkey/unprotected.p12
wget -q https://s3.amazonaws.com/axway-api-gateway/artefacts/prod/ascale.env
wget -q https://s3.amazonaws.com/axway-api-gateway/artefacts/prod/ascale.pol
wget -q https://s3-ap-southeast-2.amazonaws.com/api-gateway-license/API+7.5+Temp.lic

rescode=$(curl -I --stderr /dev/null --insecure https://$elbdnsname:8090/login/ | head -1 | cut -d' ' -f2)
echo $rescode
echo "INSTALL START TIME = $(date)" >> /tmp/admin.log
cp *.lic ${VINSTDIR}/apigateway/conf/licenses/
if [ $rescode != "200" ] ; then
### Create NODE MANAGER 
echo "WAIT"
sleep 300
else
echo "ADMIN NM IS UP AND RUNNING LETS CREATE NODE MANAGER"
fi
echo "Create Node Manager"
        ${VINSTDIR}/apigateway/posix/bin/managedomain --anm_host ${elbdnsname} --username ${adminusername} --password ${adminpassword} --add --host $(hostname -f) --name NM_ON_$(hostname -f) --sign_with_user_provided --ca=unprotected.p12
        echo "NODE MANAGER CREATED"

### START ADMIN NODE MANAGER
${VINSTDIR}/apigateway/posix/bin/nodemanager -d
echo "Node Manager started"
${VINSTDIR}/apigateway/posix/bin/managedomain  --create_instance --name $(hostname) --group "${gname}" --username ${adminusername} --password ${adminpassword} --sign_with_user_provided --ca=unprotected.p12
echo "API Gateway started"
${VINSTDIR}/apigateway/posix/bin/startinstance -g "${gname}" -n "$(hostname)" -d
echo "API Gateway started"
${VINSTDIR}/apigateway/posix/bin/managedomain --deploy --group "${gname}" --name $(hostname)  --username ${adminusername} --password ${adminpassword} --policy_archive_filename ascale.pol --env_archive_filename ascale.env
echo "LATEST CONFIG DEPLOYED TO API GATEWAY"
echo "INSTALL FINISH TIME = $(date)" >> /tmp/admin.log

