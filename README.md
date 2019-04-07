# ADM as Microservices on GCP for Monitoring and Service Graph

## Section A - Prerequisites (mandatory)

1. Now we will run automated template script to bring GCP Infrastructure components required for ADM in K8s cluster hands-on. Script will run on your cloud shell which needs internet access so please make sure your system(laptop) is active.

   > It will take around 15 mins to run script and wait till you get message from cloud shell as `End of Automated deployment for the training lab`

    ```gcloudsdk
    curl https://raw.githubusercontent.com/citrix/example-cpx-vpx-for-kubernetes-2-tier-microservices/master/gcp/scripts/adm_automated_deployment.pl | perl
    ```

    Automated perl script creates below GCP Infrastructure components required for ADM in K8s cluster hands-on

    ![GCP](./media/gcp-free-tier-image-31.png)

    After Successful deployment you will get a message on `Cloud Shell` as shown

    ![GCP](./media/gcp-free-tier-image-26.png)

    > If automation script fails don't create project with same name . Instead Go to **"Section E - Delete deployment Steps"** at page end and retry the script after successful deletion and re-login to your GCP account or delete the project using URL <https://cloud.google.com/go/getting-started/delete-tutorial-resources> and re-login to your GCP account.

1. Once GCP Infrastructure is up with automated script. we have to initialise NFS Storage for ADM

    Select the `nfs-adm` instance on `Compute Engine` and click on `View gcloud command` as shown
    ![GCP](./media/gcp-free-tier-image-33.png)

    Copy and paste the `gcloud command` to SSH `nfs-adm`

    ![GCP](./media/gcp-free-tier-image-34.png)

    Run below commands to make instance as nfs-server

     ```cloudshell
        sudo apt-get update
        sudo apt install nfs-kernel-server
     ```

    Open `exports` file

     ```cloudshell
        sudo nano /etc/exports
     ```

    Add below entries in exports file and close by clicking keys `Ctrl+X` and `Y`

     ```cloudshell
        /var/citrixadm_nfs/config       *(rw,sync,no_root_squash)
        /var/citrixadm_nfs/datastore    *(rw,sync,no_root_squash)
     ```

    Run below to make nfs-service up and give `logout` to exit from nfs-storage

     ```cloudshell
        sudo systemctl start nfs-kernel-server.service
        sudo service nfs-kernel-server restart
     ```

    ![GCP](./media/gcp-free-tier-image-35.png)

1. Access kubernetes cluster `k8s-cluster-with-adm` from the cloud shell to install ADM as microservices in K8s cluster

    Go to **Kubernetes Engine > Clusters** and click **Connect** icon

     ![GCP](./media/gcp-free-tier-image-32.png)

    Copy paste command line access on your cloud shell

     ![GCP](./media/cpx-ingress-image-26.png)

1. Install `helm` in `k8s-cluster-with-adm` cluster

    `Helm` package installation required for `ADM K8s installation`

    ```cloudshell
    cd example-cpx-vpx-for-kubernetes-2-tier-microservices/gcp/citrixadm-config-files/helm/
    ```

    ```cloudshell
    curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
    chmod 700 get_helm.sh
    ./get_helm.sh
    ```

    ```cloudshell
    kubectl create -f tiller-rbac.yaml
    ```

    ```cloudshell
    helm init --service-account tiller --upgrade
    ```

    Validate the helm `Client` and `Server` version to confirm helm installation, if you didn't see version instantly wait for some time and retry `helm version`

    ```cloudshell
    helm version
    ```

    ![GCP](./media/gcp-free-tier-image-36.png)

## Section B - Steps for installation of ADM(Application Delivery Management) Microservices

1. Now it's time to install ADM in K8s cluster

    Create `adm` namespace to deploy `adm microservices`

    ```cloudshell
    kubectl create namespace adm
    ```

    ```cloudshell
    cd ..
    ```

    Deploy `ADM Microservices` using `helm` package

    ```cloudshell
    helm install -n citrixadm --namespace adm ./citrixadm
    ```

    ![GCP](./media/gcp-free-tier-image-37.png)

    Check the `status` of pods in `adm` namespace

    ```cloudshell
    watch kubectl get pods -n adm
    ```

    ![GCP](./media/gcp-free-tier-image-38.png)

    Generate a `bash` file to install in  `citrix-adc-tier1-vpx-adm` to make it as an `tier1-ingress`

    ```cloudshell
    bash generate_ingress_conf.sh 172.16.20.20 customeradm
    ```

    SCP to `citrix-adc-tier1-vpx-adm` using its public ip to transfer above batch file

    Go to **Compute Engine > VM instances** 

    ![GCP](./media/gcp-free-tier-image-40.png)

    >Replace **"external IP of citrix-adc-tier1-vpx-adm"** with `External IP of Citrix-adc-tier1-vpx-adm` to send file to tier1-vpx-adm

    ```cloudshell
    scp customeradm-batch.txt nsroot@External IP of citrix-adc-tier1-vpx-adm:/nsconfig
    ```

    ![GCP](./media/gcp-free-tier-image-41.png)

    SSH to `citrix-adc-tier1-vpx-adm` and run below command

    ```cloudshell
    batch -f /nsconfig/customeradm-batch.txt
    ````

    ![GCP](./media/gcp-free-tier-image-42.png)

    Double click on `citrix-adc-tier1-vpx-adm` to get ADM IP

    ![GCP](./media/gcp-free-tier-image-43.png)

    Scroll down and Copy ADM IP as shown here on your browser to access `For Example: http://35.199.148.128`

    ![GCP](./media/gcp-free-tier-image-44.png)

---

## Section C - Configure AppFlow Collector on CPX , ADD Application K8s Cluster on ADM for Service Graph and Monitoring on ADM

1. Access CPX which we deployed in `Section C` through Cloud shell, go to `step 10 of Section C`

    ![GCP](./media/gcp-free-tier-image-45.png)

1. We will enable `App Flow` on `Hotdrinks CPX` to collect logs on ADM

    > Replace ADM External IP with your ADM IP

    ```gcloudshell
    add appflow collector af_mas_collector_logstream -IPAddress <ADM External IP> -port 5557 -Transport logstream
    add appflow action af_mas_action_logstream -collectors af_mas_collector_logstream
    add appflow policy af_mas_policy_logstream true af_mas_action_logstream
    bind appflow global af_mas_policy_logstream 20 END -type REQ_DEFAULT
    enable feature appflow
    enable ns mode ULFD
    ```

    ![GCP](./media/gcp-free-tier-image-46.png)

1. Access ADM IP and add `citrix-adc-tier1-vpx`

    ![GCP](./media/gcp-free-tier-image-51.png)

1. On ADM go to Orchestration > Kubernetes > Clusters and follow steps shown on image to see service graph

    Access Application k8s cluster on cloud shell

    ![GCP](./media/gcp-free-tier-image-52.png)

    * `Name:`  Give Application cluster name, for example:k8s-cluster-with-cpx

    * `API Server URL:`  Master node URL is the API server URL of Application K8s cluster. copy and paste as shown in above image

        ```cloudshell
        kubectl cluster-info
        ```

    * `Authentication Token:` To get this token we have to install cluster role and service account on Application K8s cluster

        ```cloudshell
        cd example-cpx-vpx-for-kubernetes-2-tier-microservices/gcp/citrixadm-config-files/orchestartor-yamls
        ```

        ```cloudshell
        kubectl create -f cluster-role.yaml
        kubectl create -f service-account.yaml
        ```

        ```cloudshell
        kubectl get secret -n kube-system
        ```

        ![GCP](./media/gcp-free-tier-image-49.png)

        Describe the secret service to get Authentication token

        ```cloudshell
        kubectl describe secret <admin-service-name> -n kube-system
        ```

        ![GCP](./media/gcp-free-tier-image-50.png)

1. On ADM go to `Applications > ServiceGraph` to see the service graph of Microservices and Summary Panel to check Latency,Errors..

    `Graphic` Layout for Service Graph

    ![GCP](./media/gcp-free-tier-image-54.png)

    `Grid` Layout for Service Graph

    ![GCP](./media/gcp-free-tier-image-55.png)

    `Concentric` Layout for Service Graph

    ![GCP](./media/gcp-free-tier-image-56.png)

---

## Section D - Integration with Open source tools for Monitoring (Prometheus/Grafana)

1. Deploy Cloud Native Computing Foundation (CNCF) monitoring tools, such as Prometheus and Grafana to collect ADC proxy stats.

     ```gcloudsdkkubectl
     kubectl create -f monitoring.yaml -n monitoring
     kubectl create -f ingress_vpx_monitoring.yaml -n monitoring
     ```

    ![GCP](./media/gcp-free-tier-image-21.png)

2. **`Prometheus log aggregator :`** Log in to `http://grafana.beverages.com:8080` and complete the following one-time setup.

     * Log in to the portal using `admin/admin` credentials and click  **`skip`** on next page
     * Click **`Add data source`** and select the **`Prometheus`** data source
 
    ![GCP](./media/gcp-free-tier-image-22.png)

    ![GCP](./media/gcp-free-tier-image-23.png)

     * Configure the following settings and click on **`Save and test`** button and you will get a prompt that `Data Source is working`
     >Make sure all **`prometheus`** shoud be in small letters

    ![GCP](./media/cpx-ingress-image15.png)

3. **`Grafana visual dashboard :`** To monitor traffic stats of Citrix ADC
  
   * As shown above from the left panel, select the **Import** option and  `click url` <https://raw.githubusercontent.com/citrix/example-cpx-vpx-for-kubernetes-2-tier-microservices/master/gcp/config-files/grafana_config.json> to copy entire content and paste in to JSON.
   * Click on 'Load' and than 'Import' in next page

    ![GCP](./media/gcp-free-tier-image-24.png)

    ![GCP](./media/cpx-ingress-image16.png)

---

## Section E - Delete deployment

To delete the entire deployment go to your cloud shell and run below commands to start the delete process

1. >`This Step has to be used only if Automation script fails before cloning the config-files for you otheriwse go to next step`

    ```cloudshell
    git clone https://github.com/citrix/example-cpx-vpx-for-kubernetes-2-tier-microservices.git
    ```

2. Now Go to scripts directory to start delete process using automated scripts

    ```cloudshell
    cd example-cpx-vpx-for-kubernetes-2-tier-microservices/gcp/scripts
    ```

    > `Delete Process takes around 10 mins`

    ```cloudshell
    perl adm_automated_deployment.pl delete
    ```

---