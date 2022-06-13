## Prerequisites 
Please review the [PREREQUISITES.md](PREREQUISITES.md) section prior to deploying the environment. It will assist in the creation of a dedicated GCP project to support this Terraform plan.  

## Environment Deployment and Destruction

### Updating Variables
**Copy** [terraform.tfvars.sample](terraform.tfvars.sample) to `terraform.tfvars` and customize to suit your environment. 

| Variable               | Description                                                                                                                                          |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| GCP Variables          | \-----                                                                                                                                               |
| project                | The Google Project ID to deploy into.                                                                                                                |
| basename               | The base cluster name as a prefix to the GKE cluster creation.                                                                                       |
| zone                   | Specify a specific zone to deploy into to keep costs low. Specifying a region instead will create a regional cluster.                                |
| node\_type             | The node type for each GKE worker node                                                                                                               |
| max\_node\_count       | The maximum number of nodes to autoscale the GKE cluster to. The pool size has a default minimum of 1 node to keep costs low.                        |
| VPX Configuration      | \-----                                                                                                                                               |
| vpx\_image\_path       | The https url to a publicly available VPX image. You may need to create this in your project if this has not already been done.                      |
| vpx\_cidr\_range       | A dedicated private IP range for the VPX 2nd nic to connect to which contains the VIPs.                                                              |
| vpx\_new\_password     | Set a password for the VPX. The GKE cluster will also obtain these values so that it can automatically configure the VPX.                            |
| ACM Repository Details | \-----                                                                                                                                               |
| github\_owner          | The GitHub Owner name in which to create the repository.                                                                                             |
| github\_reponame       | The name of the GitHub repository to upload content to and sync the cluster from.                                                                    |
| github\_email          | The email address of the github account associated with the GITHUB\_TOKEN.                                                                           |
| gke\_hub\_sa\_name     | The service account name for GKE Connect / GKE Hub connectivity.                                                                                     |
| Demo App Details       | \-----                                                                                                                                               |
| demo\_app\_url\_1      | A host name to be used for the Pet API. This must either exist in DNS or be configured in your local hosts file for accessing the API.               |
| demo\_app\_url\_2      | A host name to be used for the User API. This must either exist in DNS or be configured in your local hosts file for accessing the API.              |
| demo\_app\_url\_2      | A host name to be used for the Play API. This must either exist in DNS or be configured in your local hosts file for accessing the API.              |



### Deployment Timing
While timing varies on a number of factors, with the [PREREQUISITES.md](PREREQUISITES.md) already completed, the following approximate timing applies: 
- Infrastructure Creation - 10-15 minutes
- Infrastructure Destruction - 10-15 minutes

### Deployment Steps

```shell
terraform init
terraform plan 
terraform apply
```
![terraform-init](../assets/1-tf-init.gif)

![terraform-plan](../assets/2-tf-plan.gif)

![terraform-plan](../assets/3-tf-apply.gif)

**Important**
Please note that ADC VPX security features require ADC to be licensed. After ADC VPX is in place, please make sure to follow the steps required to apply your license in one of the various ways that are supported. For simplicity, for this demonstration we are [Using a standalone Citrix ADC VPX license](Licensing.md). For production deployment scenarios you are encouraged to apply different licensing schemes.
- [Licensing overview](https://docs.citrix.com/en-us/citrix-adc/current-release/licensing.html)
- [Citrix ADC pooled capacity](https://docs.citrix.com/en-us/citrix-application-delivery-management-software/current-release/license-server/adc-pooled-capacity.html)

### Destroying the environment

```shell
terraform destroy
```

## Environment Validation
Verify the cluster configuration and VPX configuration once the environment has been deployed. 
- Cluster Login
  ```shell
  $ gcloud container clusters get-credentials ctx-lab-cluster --zone northamerica-northeast1-a --project $GCP_PROJECT
  Fetching cluster endpoint and auth data.
  kubeconfig entry generated for ctx-lab-cluster.
  ```

- Google Anthos Config Management Validation
  ```shell
  $ kubectl get pods -n config-management-system
  NAME                                          READY   STATUS    RESTARTS   AGE
  config-management-operator-75bcc8dcc9-hfmr2   1/1     Running   5          18m
  reconciler-manager-6f64d4f564-k9v7b           2/2     Running   0          12m
  root-reconciler-9fb555d8-vx5f2                4/4     Running   0          12m
  ```

- Citrix Ingress Controller and Node Controller Validation
  ```shell
  $ kubectl get pods -n ctx-ingress
  NAME                                                              READY   STATUS    RESTARTS   AGE
  cic-k8s-ingress-controller-9f7559c7d-l7tt8                        1/1     Running   0          37m
  citrix-node-controller-579dfc466f-g5v27                           1/1     Running   0          37m
  kube-cnc-router-gke-ctx-lab-cluster-ctx-lab-nodes-6f50cacc-8p7n   1/1     Running   0          37m
  ```
- CPX Validation
  ```shell
  $ kubectl get pods -n demoapp
  NAME                           READY   STATUS    RESTARTS   AGE
  cpx-ingress-65fb478bb5-thxth   2/2     Running   0          110s
  ```
- Keycloak Validation
  ```shell
  $ kubectl get pods -n keycloak
  NAME                        READY   STATUS    RESTARTS   AGE
  keycloak-654745c7dd-w7x9z   1/1     Running   0          5m40s
  postgres-0                  1/1     Running   0          5m40s
  ```
- Keycloak External IP
  ```shell
  $ kubectl get svc keycloak -n keycloak
  NAME       TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)          AGE
  keycloak   LoadBalancer   10.3.248.62   35.203.18.96   8080:30564/TCP   7m57s
  ```

## What's Next
See one of the following two personas for details on the Dual-tier API Gateway use case: 
- [Developer Persona](../PERSONA_DEVELOPER.md)
- [Platform Persona](../PERSONA_PLATFORM.md)