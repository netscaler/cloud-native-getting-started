#!/usr/bin/perl 

my $operation = $ARGV[0];

if ($operation eq "delete") {

    print ("\n******************************************************\n");
    print ("Starting to Delete the entire deployment");
    print ("\n******************************************************\n");

    print ("\n******************************************************\n");
    print ("Deleting the ADM VPX");
    print ("\n******************************************************\n"); 
    qx#gcloud -q deployment-manager deployments delete tier1-vpx-adm#;

    print ("\n******************************************************\n");
    print ("Deleting the ADM GKE Kubernetes cluster");
    print ("\n******************************************************\n"); 
    qx#gcloud -q beta container clusters delete "k8s-cluster-with-adm" --zone "us-west1-b"#;
	
    print ("\n******************************************************\n");
    print ("Deleting the ADM NFS Storage");
    print ("\n******************************************************\n"); 
    qx#gcloud -q compute instances delete "nfs-adm" --zone "us-west1-b"#;

    print ("\n******************************************************\n");
    print ("Deleting the ADM VPC and Subnets");
    print ("\n******************************************************\n"); 
    qx#gcloud -q compute networks subnets delete vpx-snet-mgmt-adm --region=us-west1#;
    qx#gcloud -q compute networks delete vpx-snet-mgmt-adm#;

    qx#gcloud -q compute networks subnets delete vpx-snet-vip-adm --region=us-west1#;
    qx#gcloud -q compute networks delete vpx-snet-vip-adm#;

    qx#gcloud -q compute networks subnets delete vpx-snet-snip-adm --region=us-west1#;
    qx#gcloud -q compute networks delete vpx-snet-snip-adm#;

    print ("\n******************************************************\n");
    print ("Deleting the git repository");
    print ("\n******************************************************\n"); 
    qx#rm -rf ~/example-cpx-vpx-for-kubernetes-2-tier-microservices/#;

    exit;

}

my $project_id = $ENV{'GOOGLE_CLOUD_PROJECT'}; 
my $home_dir = $ENV{'HOME'}; 
my $repo_path = $ENV{'HOME'} . "/example-cpx-vpx-for-kubernetes-2-tier-microservices/";
my $config_dir = $repo_path . "/gcp/citrixadm-config-files/";
my $vpx_deployment_config_file = $config_dir . "/admvpxconfiguration.yml";
my $zone = "us-west1-b";
my $vpx_instance_name = "citrix-adc-tier1-vpx-adm";
my $nfs_adm_name = "nfs-adm";

my $CLONE_REPO = "TRUE";
my $CREATE_VPX_IMAGE = "TRUE";
my $CREATE_GKE = "TRUE";
my $CREATE_VPC = "TRUE";
my $CREATE_VPX = "TRUE";
my $CONFIG_VPX = "TRUE";
my $ENABLE_APIS = "TRUE";
my $NFS_ADM = "TRUE";
my $CONFIG_NFS_ADM = "TRUE";

print ("\n******************************************************\n");
print ("Starting Automated Deployment for the training lab");
print ("\n******************************************************\n");

if ($CREATE_VPX_IMAGE eq "TRUE") {
    # Forking a new process for Image creation
    my $image_creation_pid = fork();
    if (not $image_creation_pid) {
       print ("\nImage Creation Child Process: Entering\n");
       my $out = qx#gcloud -q compute images create netscaler12-1 --source-uri=gcp-vpximage/NSVPX-GCP-12.1-51.19_nc.tar.gz --guest-os-features=MULTI_IP_SUBNET#;

       print ("\nOutput of Image Creation is \n$out\n");
       print ("\nImage Creation Child Process: Exiting\n");
       exit;
    }
}

if ($ENABLE_APIS eq "TRUE") {
    print ("\n******************************************************\n");
    print ("Enabling necessary Google Cloud APIs");
    print ("\n******************************************************\n");
    qx#gcloud -q services enable containerregistry.googleapis.com#;
    qx#gcloud -q services enable deploymentmanager.googleapis.com#;
}


if ($CLONE_REPO eq "TRUE") {
    print ("\n******************************************************\n");
    print ("Cloning the GIT repo to your home directory");
    print ("\n******************************************************\n");
    qx#git clone https://github.com/citrix/example-cpx-vpx-for-kubernetes-2-tier-microservices.git $repo_path#;
}

print ("\n******************************************************\n");
print ("This automated deployment would: \n");
print ("1. Clone the git repository\n");
print ("2. Create a Google Image for VPX\n");
print ("3. Create VPC Networks for ADM\n");
print ("4. Create VPC Subnets for ADM\n");
print ("5. Create ADM GKE Kubernetes cluster\n");
print ("6. Create a ADM VPX instance\n");
print ("7. Configure basic configs in ADM VPX instance\n");
print ("8. Create a ADM NFS instance\n");
print ("9. Configure basic configs in ADM NFS instance");
print ("\n******************************************************\n");

if ($CREATE_VPC eq "TRUE") {
    print ("\n******************************************************\n");
    print ("Creating VPC for Management Network");
    print ("\n******************************************************\n");
    qx#gcloud -q compute networks create vpx-snet-mgmt-adm --subnet-mode=custom#;
    qx#gcloud -q compute networks subnets create vpx-snet-mgmt-adm --network=vpx-snet-mgmt-adm --region=us-west1 --range=192.168.20.0/24#;

    print ("\n******************************************************\n");
    print ("Creating VPC for Client Network");
    print ("\n******************************************************\n");
    qx#gcloud -q compute networks create vpx-snet-vip-adm --subnet-mode=custom#;
    qx#gcloud -q compute networks subnets create vpx-snet-vip-adm --network=vpx-snet-vip-adm --region=us-west1 --range=172.16.20.0/24#;

    print ("\n******************************************************\n");
    print ("Creating VPC for Server Network");
    print ("\n******************************************************\n");
    qx#gcloud -q compute networks create vpx-snet-snip-adm --subnet-mode=custom#;
    qx#gcloud -q compute networks subnets create vpx-snet-snip-adm --network=vpx-snet-snip-adm --region=us-west1 --range=10.10.20.0/24#;
}


if ($CREATE_GKE eq "TRUE") {
    print ("\n******************************************************\n");
    print ("Creating a 1 node GKE Cluster for ADM");
    print ("\n******************************************************\n");
    qx#gcloud -q beta container clusters create "k8s-cluster-with-adm" --zone "us-west1-b" --username "admin" --cluster-version "1.11.7-gke.12" --machine-type "n1-standard-8" --image-type "UBUNTU" --disk-type "pd-standard" --disk-size "100" --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --num-nodes "1" --enable-cloud-logging --enable-cloud-monitoring --no-enable-ip-alias --network "projects/$project_id/global/networks/vpx-snet-snip-adm" --subnetwork "projects/$project_id/regions/us-west1/subnetworks/vpx-snet-snip-adm" --addons HorizontalPodAutoscaling,HttpLoadBalancing --enable-autoupgrade --enable-autorepair#;
}

if ($CREATE_VPX eq "TRUE") {
    print ("\n******************************************************\n");
    print ("Editing the deployment manager configuration file");
    print ("\n******************************************************\n");
    qx#sed -i "s/<your project name>/$project_id/g" $vpx_deployment_config_file#;
}

if ($CREATE_VPX_IMAGE eq "TRUE") {
    # Before VPX creation - Image creation should finish. Wait for that to complete
    print ("\n******************************************************\n");
    print ("Waiting for the Image creation to complete");
    print ("\n******************************************************\n");
    my $finished = wait();
    print ("\n******************************************************\n");
    print ("Image creation process for VPX has been completed");
    print ("\n******************************************************\n");
}

if ($CREATE_VPX eq "TRUE") {
    print ("\n******************************************************\n");
    print ("Creating VPX using GDM Template");
    print ("\n******************************************************\n");
    qx#gcloud -q deployment-manager deployments create tier1-vpx-adm --config $vpx_deployment_config_file#;
}

if ($CONFIG_VPX eq "TRUE") {

    print ("\n******************************************************\n");
    print ("Waiting for the ADM VPX to boot up");
    print ("\n******************************************************\n");
    sleep(60);
    print ("\n******************************************************\n");
    print ("Doing basic ADM VPX Configuration");
    print ("\n******************************************************\n");
    qx#gcloud -q compute ssh $vpx_instance_name --zone $zone --command "show version"#;
    qx#gcloud -q compute ssh $vpx_instance_name --zone $zone --command "show version"#;
    qx#gcloud -q compute ssh $vpx_instance_name --zone $zone --command "add ns ip 10.10.20.20 255.255.255.0 -type snip -mgmt enabled"#;
    qx#gcloud -q compute ssh $vpx_instance_name --zone $zone --command "enable ns mode mbf"#;

}

if ($NFS_ADM eq "TRUE") {
    print ("\n******************************************************\n");
    print ("Creating NFS storage for ADM");
    print ("\n******************************************************\n");
	qx#gcloud -q compute instances create nfs-adm --zone=us-west1-b --machine-type=n1-standard-4 --subnet=vpx-snet-snip-adm --private-network-ip=10.10.20.50 --network-tier=PREMIUM --maintenance-policy=MIGRATE --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --image=ubuntu-1604-xenial-v20190325 --image-project=ubuntu-os-cloud --boot-disk-size=100GB --boot-disk-type=pd-ssd --boot-disk-device-name=nfs-adm#;
}

if ($CONFIG_NFS_ADM eq "TRUE") {

    print ("\n******************************************************\n");
    print ("Waiting for the ADM NFS to boot up");
    print ("\n******************************************************\n");
    sleep(100);
    print ("\n******************************************************\n");
    print ("Doing basic ADM NFS Configuration");
    print ("\n******************************************************\n");
	qx#gcloud -q compute ssh $nfs_adm_name --zone $zone --command "sudo mkdir -p /var/citrixadm_nfs/config"#;
    qx#gcloud -q compute ssh $nfs_adm_name --zone $zone --command "sudo chmod 777 /var/citrixadm_nfs/config"#;
	qx#gcloud -q compute ssh $nfs_adm_name --zone $zone --command "sudo mkdir -p /var/citrixadm_nfs/datastore"#;
    qx#gcloud -q compute ssh $nfs_adm_name --zone $zone --command "sudo chmod 777 /var/citrixadm_nfs/datastore"#;
}

print ("\n******************************************************\n");
print ("Deployment Done");
print ("\n******************************************************\n");

print ("\n******************************************************\n");
print ("End of Automated Deployment for the training lab");
print ("\n******************************************************\n");

