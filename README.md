## Learn how to use Citrix ADC in two tier microservices architecture

* Get three virtual machines running with minimum following specifications:
  - VM type – Ubuntu 16.04
  - vCPUs – 4 
  - Memory – 6GB

* Install Kubernetes cluster on these three VMs where one VM act as master node and rest two are worker nodes. 

* Login to Master node console and execute following commands.

* Create 5 namespaces (tier-2-adc, team-hotdrink, team-colddrink,team-guestbook,monitoring) e.g. kubectl create namespace tier-2-adc

* Deploy yaml files into respective namespace to allow tier 1 VPX and tier 2 CPX communication.

* Login to VPX box and check for the dynamically pushed ADC configuration.

* Goto browser and access the applications over SSL. e.g hotdrink.beverages.com for monitoring and visibility graphs – grafana.beverages.com

--
