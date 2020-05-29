# How do I provision license to Citrix ADC CPX from ADM

In this guide you will learn:
* What are licensing modes available for Citrix ADC CPX
* Who does provisioning of license to Citrix ADC CPX
* How to apply license to Citrix ADC CPX from ADM service as well as ADM on prem

Citrix ADC CPX is container-based ADC deployed in Kubernetes cluster to load balance microservices. By default, CPX runs with 20 Mbps bandwidth called as CPX express however for better performance and production deployment customer needs licensed CPX instances.  Customer has to use Citrix ADM (ADM on-prem or ADM service) for checking out the license. There are three types of licensing available for CPX today, 
*	Bandwidth based pool license (one SKU shared across all Citrix ADC form factors)
*	vCPU based pool license (one SKU shared across all Citrix ADC form factors)

Let’s see the CPX licensing work-flow,

| Section | Description |
| ------- | ----------- |
| [Section A]() | Provision Bandwidth based licensing to Citrix ADC CPX from ADM service |
| [Section B]() | Provision vCPU based licensing to Citrix ADC CPX from ADM service |
| [Section C]() | Provision Bandwidth based licensing to Citrix ADC CPX from ADM on-premise |
| [Section D]() | Provision vCPU based licensing to Citrix ADC CPX from ADM on-premise |


#### How do I license a CPX from ADM service
In this deployment guide, we will show you how to provision bandwidth and vCPU licensing to CPX.

###### Section A: Provision Bandwidth based licensing to Citrix ADC CPX from ADM service
1. Setting up Citrix Application Delivery Management (Citrix ADM) for the first time

    Please make sure that ADM service setup is ready with ADM agent configuration. We need ADM service account and ADM agent both to CPX licensing to be functional.
    If you are first time user of ADM service, please visit - https://docs.citrix.com/en-us/citrix-application-delivery-management-service/getting-started.html guide for setting up ADM service and ADM agent in your lab.
    **Note**: For this demo, I have used On a Hypervisor (On premises) ADM agent setup. From below screenshot you can see that "10.105.158.166" is my on-prem agent used for licensing CPX.

2. Add Citrix ADC instance license pool to ADM service
    
    I assume that you have pool of bandwidth license available in you ADM service. If you want to know how to upload licensing file to ADM, refer to https://docs.citrix.com/en-us/citrix-application-delivery-management-service/manage-licenses/pooled-licenses/configuring-pooled-capacity.html
    From the below screenshot you will see that "CNS_PBW10MB_10GB_RetailS.lic" bandwidth license pool will be used for this demo.

3. Deploy CPX in Kubernetes cluster
    Make sure that below environment variables are added to CPX yaml file to license CPX instance.
    
    ```
          - name: "LS_IP"
            value: "10.105.158.166" //ADM agent IP as mentioned in step 1
          - name: "LS_PORT"
            value: "38000"          // port on which ADM license server listen
          - name: "BANDWIDTH"
            value: "3000"           //capacity in Mbps wants to allocate to CPX
    ```

    Edit CPX yaml file and update above EVN variable
    ```
    kubectl create namespace bandwidth
    wget https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/cpx-licensing/manifest/cpx-bandwidth-license-adm-service.yaml
    ```
    Make the changes to ``cpx-bandwidth-license-adm-service.yaml`` file and deploy in K8s cluster
    ```
    kubectl create -f cpx-bandwidth-license-adm-service.yaml -n bandwidth
    ```
    Login to CPX for checking instancing information.
    ```
    kubectl exec -it <cpx-pod-ip-name> bash -n bandwidth
    ```
    Execute below command to see the licensing information for given CPX instance
    ```
    sh licenseserver
    sh capacity
    ```
    You can also track the allocated bandwidth capacity from ADM service portal.

###### Section B: Provision vCPU based licensing to Citrix ADC CPX from ADM service
1. Setting up Citrix Application Delivery Management (Citrix ADM) for the first time

    Please make sure that ADM service setup is ready with ADM agent configuration. We need ADM service account and ADM agent both to CPX licensing to be functional.
    If you are first time user of ADM service, please visit - https://docs.citrix.com/en-us/citrix-application-delivery-management-service/getting-started.html guide for setting up ADM service and ADM agent in your lab.
    **Note**: For this demo, I have used On a Hypervisor (On premises) ADM agent setup. From below screenshot you can see that "10.105.158.166" is my on-prem agent used for licensing CPX.

2. Add Citrix ADC instance license pool to ADM service
    
    I assume that you have vCPU pool license available in you ADM service. If you want to know how to upload licensing file to ADM, refer to https://docs.citrix.com/en-us/citrix-application-delivery-management-service/manage-licenses/pooled-licenses/configuring-pooled-capacity.html
    From the below screenshot you will see that "****" vCPU pool will be used for this demo.

3. Deploy CPX in Kubernetes cluster
    Make sure that below environment variables are added to CPX yaml file to license CPX instance.
    
    ```
          - name: "LS_IP"
            value: "10.102.216.173" //ADM agent IP as mentioned in step 1
          - name: "LS_PORT"
            value: "38000"          // port on which ADM license server listen
          - name: "PLATFORM"
            value: "CORES"         // used for specifying type of pool licensing
          - name: "CPX_CORES"
            value: "4"              // number of core you want to allocate
    ```

    Edit CPX yaml file and update above EVN variable
    ```
    kubectl create namespace core
    wget https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/cpx-licensing/manifest/cpx-core-license-adm-service.yaml
    ```
    Make the changes to ``cpx-core-license-adm-service.yaml`` file and deploy in K8s cluster
    ```
    kubectl create -f cpx-core-license-adm-service.yaml -n core
    ```
    Login to CPX for checking instancing information.
    ```
    kubectl exec -it <cpx-pod-ip-name> bash -n core
    ```
    Execute below command to see the licensing information for given CPX instance
    ```
    sh licenseserver
    sh capacity
    ```
    You can also track the allocated vCPU capacity from ADM service portal.


#### How do I license a CPX from ADM on-premise
In this deployment guide, we will show you how to provision bandwidth and CP1000 licensing to CPX.

###### Section C: Provision Bandwidth based licensing to Citrix ADC CPX from ADM on-premise
1. Setting up Citrix Application Delivery Management (Citrix ADM) for the first time

    Please make sure that ADM onprem setup is ready. We can have ADM onprem with and without ADM agent deployment for CPX licensing to be functional.
    If you are first time user of ADM onprem, please visit - https://docs.citrix.com/en-us/citrix-application-delivery-management-software/13/get-started.html guide for setting up ADM onprem and ADM agent (optional) in your lab.
    **Note**: For this demo, I have used inbuilt ADM agent with ADM onprem. From below screenshot you can see that there is no agent deployed.

2. Add Citrix ADC instance license pool to ADM onprem
    
    I assume that you have pool of bandwidth license available in you ADM onprem. If you want to know how to upload licensing file to ADM, refer to https://docs.citrix.com/en-us/citrix-application-delivery-management-software/13/license-server/licenses-in-adm-license-server-in-high-availability.html
    From the below screenshot you will see that "CNS_PBW10MB_10GB_RetailS.lic" bandwidth license pool will be used for this demo.

3. Deploy CPX in Kubernetes cluster
    Make sure that below environment variables are added to CPX yaml file to license CPX instance.
    
    ```
          - name: "LS_IP"
            value: "10.105.158.144" // ADM onprem instance IP, If you have ADM agent deployment then this will be your agent IP as described in step 1
          - name: "LS_PORT"
            value: "27000"          // port on which ADM license server listen
          - name: "BANDWIDTH"
            value: "3000"           //capacity in Mbps wants to allocate to CPX
    ```

    Edit CPX yaml file and update above EVN variable
    ```
    kubectl create namespace bandwidth
    wget https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/cpx-licensing/manifest/cpx-bandwidth-license-adm-onprem.yaml
    ```
    Make the changes to ``cpx-bandwidth-license-adm-onprem.yaml`` file and deploy in K8s cluster
    ```
    kubectl create -f cpx-bandwidth-license-adm-onprem.yaml -n bandwidth
    ```
    Login to CPX for checking instancing information.
    ```
    kubectl exec -it <cpx-pod-ip-name> bash -n bandwidth
    ```
    Execute below command to see the licensing information for given CPX instance
    ```
    sh licenseserver
    sh capacity
    ```
    You can also track the allocated bandwidth capacity from ADM onprem portal.

###### Section D: Provision vCPU based licensing to Citrix ADC CPX from ADM on-premise
1. Setting up Citrix Application Delivery Management (Citrix ADM) for the first time

    Please make sure that ADM onprem setup is ready. We can have ADM onprem with and without ADM agent deployment for CPX licensing to be functional.
    If you are first time user of ADM onprem, please visit - https://docs.citrix.com/en-us/citrix-application-delivery-management-software/13/get-started.html guide for setting up ADM onprem and ADM agent (optional) in your lab.
    **Note**: For this demo, I have used inbuilt ADM agent with ADM onprem. From below screenshot you can see that there is no agent deployed.

2. Add Citrix ADC instance license pool to ADM onprem
    
    I assume that you have pool of bandwidth license available in you ADM onprem. If you want to know how to upload licensing file to ADM, refer to https://docs.citrix.com/en-us/citrix-application-delivery-management-software/13/license-server/licenses-in-adm-license-server-in-high-availability.html
    From the below screenshot you will see that "*****" vCPU license pool will be used for this demo.

3. Deploy CPX in Kubernetes cluster
    Make sure that below environment variables are added to CPX yaml file to license CPX instance.
    
    ```
          - name: "LS_IP"
            value: "10.105.158.144" // ADM onprem instance IP, If you have ADM agent deployment then this will be your agent IP as described in step 1
          - name: "LS_PORT"
            value: "27000"          // port on which ADM license server listen
          - name: "PLATFORM"
            value: "CORES"         // used for specifying type of pool licensing
          - name: "CPX_CORES"
            value: "4"              // number of core you want to allocate
    ```

    Edit CPX yaml file and update above EVN variable
    ```
    kubectl create namespace core
    wget https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/cpx-licensing/manifest/cpx-core-license-adm-onprem.yaml
    ```
    Make the changes to ``cpx-core-license-adm-onprem.yaml`` file and deploy in K8s cluster
    ```
    kubectl create -f cpx-core-license-adm-onprem.yaml -n core
    ```
    Login to CPX for checking instancing information.
    ```
    kubectl exec -it <cpx-pod-ip-name> bash -n core
    ```
    Execute below command to see the licensing information for given CPX instance
    ```
    sh licenseserver
    sh capacity
    ```
    You can also track the allocated vCPU capacity from ADM onprem portal.


