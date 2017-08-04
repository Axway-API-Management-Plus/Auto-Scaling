# Auto-Scaling
Scripts to implement auto scaling in AWS.

![alt text][Overview]

# Description

### KPS Subnet

Is to house fixed size Cassandra cluster.The subnet should have restricted access with rpc traffic allowed for API Gateway subnet only and shh access from a bastion hosts. It provides persistence to API Manager state. It's a matter of debate if Cassandra should be auto scaled as adding a node and redistributing data across the cluster is an expensive operations which might be a performance impact during auto scaling activities and can lead to opposite consequences. It's  suggested to have KPS cluster to be of fixed sized nodes spread across multiple zones  and regions for DR purposes, when there is a need for more capacity then scaling activity shoudl be performed outside of peak traffic hours. Consider every availability zone as a  RAC and regions to be data centers and make the overall  Cassandra topology Data center aware and API Manager to use "LOCAL QUORUM" instead of "QUORUM" consistency for read and writes.
 
### Admin Node Manage Subnet

Is to house a fixed size Node Manager nodes capable of performing domain management operations. The subnet should provide enough High Availability so that domain management operations can be performed uninterrupted of any Admin Node Manager failures.Admin Node Manager does not handles API Traffic hence there should be no need for elasticity. Having said that you would need HA(high availability) for Admin Node Manager so that you can manage API Gateway instances even if one of the Admin node managers is offline.
 
ANM performs Domain Management functionality which includes following
 
#### Topology and Domain Management
```sh 
Deployment Management - download/upload deployment 
KPS Administration
Real Time Traffic Monitoring
``` 
#### Management of following 
```sh
Creation, Modification, Deletion of Groups 
Creation, Modification, Deletion of API Gateway Instances
Creation, Modification, Deletion of Node Managers and Admin Node Managers 
```

#### Management Dashboard - web interface    
```sh
Real time Traffic Monitoring 
System Metric Monitoring
User defined Custom KPS Administration
User Administration 
```

#### Admin Node Manager Auto Scaling Architecture Overview 

![alt text][ANMOverview]

**While configuring Elastic Load Balancer incorporate following**
 
```sh
- Admin Node Manager listener port and ELB Port should be same - otherwise you might get CSRF issues
- Enable Session stickiness based on VIDUSR cookie - Only needed for Dashboard
- Use HTTPS or TCP(SSL) as load balancer and instance protocol - needed because for dashboard to work you would need ELB Stickiness which is supported only for HTTP and HTTPS protocol
```
 
## Install

```
1. Create an AMI with API Management Software pre-installed on Linux
2. Create an [ANM_INIT] script for run level corresponding to system start, stop and restart and embed in the AMI
3. Init.d script start method will pull the necessary scripts from S3 which would then be used to  register and start Admin Node Managers
4. Use a cert+private key managed externally for signing the Admin Node Manager certs(option 2 when registering Admin Node Manager through managedomain)
5. While adding admin node manager check if the domain/topology exists or brand new
```

**While configuring Auto Scaling Groups incorporate following**
 
```sh
- Auto Scaling Launch configuration should point to AMI with pre-installed Axway Software and init.d scripts 
- Min, Max and Desired should be same and >=2. Ideally you should have atleast one Admin Node Manager in each availability zone of target AWS region.
- Cooldown and healthcheck grace period should be greater than the time it takes the Admin Node Manager to come online which would be equal to sum of ' Time for Ec2 instance creation' + 'Time taken for scripts execution' + 'Time taken for instance to be added in service to Elastic load balancer'
- When Launching the Auto scaling group **you should always start with min and max equal to 1**
- Once the Admin Node Manager aka the first Node Manager is created than gradually change the auto scaling group to desired size incrementally. 
- Once the Auto Scaling group has reached the desired size it will take care of any failures and will maintain a constant size in case of any EC2 instance failure.
- Healthcheck on instances created by Auto Scaling group shoudl be based on ELB healthcheck
```

### API Gateway Subnet
Is API consumer facing subnet exposing API Gateway listeners expecting to take API traffic. The subnet is auto scaled with auto scaling triggers relying on SNS alerts.

![alt text][APIGWOverview]

## Install
```
1. Create an AMI with API Management Software pre-installed on Linux
2. Create an init.d script for run level corresponding to system start, stop and restart
3. Init.d script start method will pull the necessary scripts from S3 which would then be used to  register and start local Node Managers and also register and start API Gateway instance . The script will also deploy the latest config.
4. Use a private key + server cert managed externally for signing the Node Manager certs(option 2 when registering host through managedomain)
5. While adding Local Node Manager check if domain exists, if not then wait for domain creation. 
```
**While configuring Elastic Load Balancer incorporate following**
 
```sh
- Enable Session stickiness based on APIMANAGERSESSION cookie - Only needed for API Manager(Portal part)
- Use HTTPS or TCP(SSL) as load balancer and instance protocol.
- For API Manager portal  to work you would need ELB Stickiness which is supported only for HTTP and HTTPS protocol
```

**While configuring Auto Scaling Groups incorporate following**
```
- Auto Scaling Launch configuration should point to AMI with pre-installed Axway Software and init.d scripts 
- Cooldown and healthcheck grace period should be greater than the time it takes the API Gateway to come online which should be equal to sum of ' Time for Ec2 instance creation' + 'Time taken for scripts execution' + 'Time taken for instance to be added in service to Elastic load balancer'
- Auto Scaling triggers should add or delete one node at a time.  Adding or deleting multiple nodes during auto scaling might lead to an iterim inconsistency of domain.
- During Scaling activities there should be a time lag between two scaling activities(e.g scale up followed by another scale up, or any other combination of  scale up and or scale down) and the time lag should be higher than cool down period described in second point.   
- When Launching the Auto scaling group **you should always start with min < max**
- Healthcheck on instances created by Auto Scaling group should be based on ELB healthcheck
```

## API Management Version Compatibilty
This artefact was successfully tested for the following versions:
- V7.5.1
- V7.5.2

The scripts have been verified on Amazon Linux and hence for any other Unix flavor they might need some modifications.

## Usage

- Configure the common_variables.sh with correct values for Admin Node Manager ELB DNS names. 
 - Alternatively you can pass the content of common_variable.sh using user data feature of EC2 instances. 
 - Create the Admin Node Manager cluster
 - Once the Admin Node Manager ELb is ready to take domain management traffic you can create API gateway Auto Scaling Group.

## Bug and Caveats

```
1. Avoid adding/deleting more than one API Gateway instances simultaneously in  auto scaling activities, bigger size might lead to a race condition resulting in inconsistent topology. Any such occurrence will be mostly taken care by ELB which marks the instances as unhealthy and auto scaling group replaces it with healthy node
2. During scale down opsdb logs are lost - there might be a possible way to move them to other servers
3. Distributed cache don't work well with auto scaled instances. There are few workarounds i am exploring to solve the caching problem.
```

## Contributing

Please read [Contributing.md](https://github.com/Axway-API-Management/Common/blob/master/Contributing.md) for details on our code of conduct, and the process for submitting pull requests to us.


## Team

![alt text][Axwaylogo] Axway Team

## License
[Apache License 2.0](/LICENSE)

[ANMINIT]: https://github.com/Axway-API-Management-Plus/Auto-Scaling-/blob/master/src/AdminNodeManager/script_ANM_init.sh
[Overview]: https://github.com/Axway-API-Management-Plus/Auto-Scaling-/blob/master/docs/Images/AUTO%20SCALING.jpg "Auto Scaling Overview"
[APIGWOverview]: https://github.com/Axway-API-Management-Plus/Auto-Scaling-/blob/master/docs/Images/APIGatewayAutoScaling.png  "APIGW AUTO SCALE OVERVIEW"
[Axwaylogo]: https://github.com/Axway-API-Management/Common/blob/master/img/AxwayLogoSmall.png  "Axway logo"
[ANMOverview]: https://github.com/Axway-API-Management-Plus/Auto-Scaling-/blob/master/docs/Images/AdminNodeManagerHA.png "ANM HA Overview"
