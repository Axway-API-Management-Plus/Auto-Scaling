#!/bin/sh -x
#. $(dirname $0)/common_variables.sh
. /var/common_variables.sh
echo ${elbdnsname}
echo ${csrkeyloc}
echo "INSTALL START TIME = $(date)" >> /tmp/admin.log
### Download the CSR to local 
#aws s3 cp  $csrkeyloc unprotected.p12
wget -q https://s3.amazonaws.com/admin-node-manager/CSR%2Bkey/unprotected.p12
wget -q https://s3-ap-southeast-2.amazonaws.com/api-gateway-license/API+7.5+Temp.lic
cp *.lic ${VINSTDIR}/apigateway/conf/licenses/
rescode=$(curl -I --stderr /dev/null --insecure https://$elbdnsname:8090/login/ | head -1 | cut -d' ' -f2)
echo $rescode
if [ $rescode != "200" ] ; then
### Create ADMIN NODE MANAGER 
echo "CREATE ADMIN NODE MANAGER"
	echo "ADMIN NODE MANAGER CREATED"
	${VINSTDIR}apigateway/posix/bin/managedomain --username ${adminusername} --password ${adminpassword} -i --host $(hostname -f) --name ANM_ON_$(hostname -f) --sign_with_user_provided --ca=unprotected.p12
else
	echo "Create Node Manager with admin capabilities"
	${VINSTDIR}/apigateway/posix/bin/managedomain --anm_host ${elbdnsname} --is_admin --username ${adminusername} --password ${adminpassword} --add --host $(hostname -f) --name NMA_ON_$(hostname -f) --sign_with_user_provided --ca=unprotected.p12
	echo "NODE MANAGER WITH ADMIN CAPABILITY CREATED"
fi
### START ADMIN NODE MANAGER
${VINSTDIR}/apigateway/posix/bin/nodemanager -d
echo "Node Manager started"
echo "INSTALL FINISH TIME = $(date)" >> /tmp/admin.log

