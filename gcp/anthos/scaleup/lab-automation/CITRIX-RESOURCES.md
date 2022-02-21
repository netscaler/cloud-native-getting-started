## Resources
This is a collection of resources and notes that were referenced during the build of this infrastrucre.  

**GitHub Resources**    
[Terraform ADC Provider](https://github.com/citrix/terraform-provider-citrixadc)  
- Only available for AWS/Azure  

[K8S Node Controller](https://github.com/citrix/citrix-k8s-node-controller)  
[K8S Ingress Controller](https://github.com/citrix/citrix-k8s-ingress-controller) 
[CPX Docs](https://docs.citrix.com/en-us/citrix-adc-cpx/)  
[CPX Configuration](https://docs.citrix.com/en-us/citrix-adc-cpx/current-release/configure-cpx.html)  
[CPX on GCP Configuration](https://docs.citrix.com/en-us/citrix-adc-cpx/current-release/deploy-cpx-proxy-on-google-compute-engine.html)  
[Ingress Controller with Anthos](https://github.com/citrix/citrix-k8s-ingress-controller/tree/master/deployment/anthos) 
[Citrix CPX](https://github.com/citrix/citrix-adc-cpx-gcp-marketplace)  
[Observabililty Exporter](https://github.com/citrix/citrix-observability-exporter)  
[Terraform Cloud Scripts](https://github.com/citrix/terraform-cloud-scripts)  
[Citrix Tech Zone](https://github.com/citrix/en-us-tech-zone)  
[Citrix Google GDM Docs](https://github.com/citrix/citrix-adc-gdm-templates/tree/master/standalone-templates)  

**Citrix Docs**  
[K8s Ingress Solution](https://docs.citrix.com/en-us/citrix-adc/current-release/cloud-native-solution/ingress-solution.html)  
[Citrix ADC CPX on Azure](https://developer-docs.citrix.com/projects/citrix-k8s-ingress-controller/en/latest/deploy/deploy-azure/#deploy-citrix-adc-cpx-as-an-ingress-device-in-an-aks-cluster)  
[Citrix Ingress Controller with YAML](https://developer-docs.citrix.com/projects/citrix-k8s-ingress-controller/en/latest/deploy/deploy-cic-yaml/)  
[Citrix Deployment Topologies](https://developer-docs.citrix.com/projects/citrix-k8s-ingress-controller/en/latest/deployment-topologies/)  


### Notes and Comments
- Deploying the Single Tier architecture specifies a single Pod, but a Deployment will be needed for ACM since Pods are immutable to many changes
- Installed the node controller, and the container needed a kick to reconfigure the VPX once or twice
- Have not tested multiple replicas of the node controller or the ingress controller
