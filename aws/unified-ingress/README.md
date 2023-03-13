# Load balance microserviced based applications using NetScaler VPX (Tier 1 ADC as NetScaler VPX, Tier 2 as microservice applications in EKS)

In this guide you will learn:

* How to deploy a microservice application exposed as NodePort type service.
* How to configure NetScaler VPX (Tier 1 ADC) using Citrix Ingress Controller to load balance applications.

NetScaler supports Unified Ingress architecture to load balance an enterprise grade applications deployed as microservices in AWS kubernetes service - EKS. NetScaler VPX acts as high scale North-South proxy. Lets understand the Unified Ingress topology using below diagram.


##### Deployment steps:

1. Pre-requisite

	* Ensure that you have VPX and EKS running on AWS.
	* To bring EKS follow EKS guide
	* To bring VPX follow VPX guide
	* Install [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl) and [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) on your machine to access VPX and EKS locally.

2. Access EKS cluster from AWS CLI

	```
	aws eks --region ap-south-1 update-kubeconfig --name cloud-native-eks
	```
	![eks](images/eks.png)


2. Deploy Citrix Ingress controller using HELM

	Lets add the citrix helm repo
	```
	helm repo add citrix https://citrix.github.io/citrix-helm-charts/
	```
	Note: In case you do not have HELM installed on terminal, please install HELM from https://helm.sh/docs/intro/install/ 

	
	Create VPX login secret
	```
	kubectl create secret generic nsvpxlogin --from-literal=username='nsroot' --from-literal=password='mypassword'
	```
	Note: Update username and password which is used while instantiating the VPX.

	Install CIC
	```
	helm install cic citrix/citrix-ingress-controller --set nsIP=10.0.6.37,license.accept=yes,adcCredentialSecret=nsvpxlogin,crds.install=true,cic.ingressClass[0]=vpx
	```

	Note: From MAC terminal use below command
	```
	helm install cic citrix/citrix-ingress-controller --set nsIP=10.0.6.37,license.accept=yes,adcCredentialSecret=nsvpxlogin,crds.install=true,cic.ingressClass\[0\]=vpx
	```

	nsIP = Use primary private IP associated to VPX NIC (Goto to EC2 -> Instances -> Cloud-Native-vpx instance ID -> Check for Private IPv4 addresses in instance summary)

	![cic](images/cic.png)

3. Install sample application exposed as NodePort

	```
	kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/beginners-guide/manifest/cloudnative-demoapp.yaml
	```

4. Expose application using Ingress

	```
	kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/beginners-guide/manifest/cloudnative-demoapp-ingress.yaml
	```

