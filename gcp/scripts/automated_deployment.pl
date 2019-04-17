#!/usr/bin/perl 

my $operation = $ARGV[0];

if ($operation eq "delete") {

    print ("\n******************************************************\n");
    print ("Starting to Delete the entire deployment");
    print ("\n******************************************************\n");

    print ("\n******************************************************\n");
    print ("Deleting the VPX");
    print ("\n******************************************************\n"); 
    qx#gcloud -q deployment-manager deployments delete tier1-vpx#;

    print ("\n******************************************************\n");
    print ("Deleting the GKE Kubernetes cluster");
    print ("\n******************************************************\n"); 
    qx#gcloud -q beta container clusters delete "k8s-cluster-with-cpx" --zone "asia-northeast1-b"#;

    print ("\n******************************************************\n");
    print ("Deleting the VPC and Subnets");
    print ("\n******************************************************\n"); 
    qx#gcloud -q compute networks subnets delete vpx-snet-mgmt --region=asia-northeast1#;
    qx#gcloud -q compute networks delete vpx-snet-mgmt#;

    qx#gcloud -q compute networks subnets delete vpx-snet-vip --region=asia-northeast1#;
    qx#gcloud -q compute networks delete vpx-snet-vip#;

    qx#gcloud -q compute networks subnets delete vpx-snet-snip --region=asia-northeast1#;
    qx#gcloud -q compute networks delete vpx-snet-snip#;

    print ("\n******************************************************\n");
    print ("Deleting the git repository");
    print ("\n******************************************************\n"); 
    qx#rm -rf ~/example-cpx-vpx-for-kubernetes-2-tier-microservices/#;

    exit;

}

my $project_id = $ENV{'GOOGLE_CLOUD_PROJECT'}; 
my $home_dir = $ENV{'HOME'}; 
my $repo_path = $ENV{'HOME'} . "/example-cpx-vpx-for-kubernetes-2-tier-microservices/";
my $config_dir = $repo_path . "/gcp/config-files/";
my $vpx_deployment_config_file = $config_dir . "/configuration.yml";
my $zone = "asia-northeast1-b";
my $vpx_instance_name = "citrix-adc-tier1-vpx";

my $CLONE_REPO = "TRUE";
my $CREATE_VPX_IMAGE = "TRUE";
my $CREATE_GKE = "TRUE";
my $CREATE_VPC = "TRUE";
my $CREATE_VPX = "TRUE";
my $CONFIG_VPX = "TRUE";
my $ENABLE_APIS = "TRUE";

print ("\n******************************************************\n");
print ("Stating Automated Deployment for the training lab");
print ("\n******************************************************\n");

if ($CREATE_VPX_IMAGE eq "TRUE") {
    # Forking a new process for Image creation
    my $image_creation_pid = fork();
    if (not $image_creation_pid) {
       print ("\nImage Creation Child Process: Entering\n");
       my $out = qx#gcloud -q compute images create netscaler12-1 --source-uri=gs://gcpvpx-freemiumimage/NSVPX-GCP-12.1-51.19_nc.tar.gz --guest-os-features=MULTI_IP_SUBNET#;

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
print ("3. Create VPC Networks\n");
print ("4. Create VPC Subnets\n");
print ("5. Create GKE Kubernetes cluster\n");
print ("6. Create a VPX instance\n");
print ("7. Configure basic configs in VPX instance");
print ("\n******************************************************\n");


if ($CREATE_VPC eq "TRUE") {
    print ("\n******************************************************\n");
    print ("Creating VPC for Management Network");
    print ("\n******************************************************\n");
    qx#gcloud -q compute networks create vpx-snet-mgmt --subnet-mode=custom#;
    qx#gcloud -q compute networks subnets create vpx-snet-mgmt --network=vpx-snet-mgmt --region=asia-northeast1 --range=192.168.10.0/24#;

    print ("\n******************************************************\n");
    print ("Creating VPC for Client Network");
    print ("\n******************************************************\n");
    qx#gcloud -q compute networks create vpx-snet-vip --subnet-mode=custom#;
    qx#gcloud -q compute networks subnets create vpx-snet-vip --network=vpx-snet-vip --region=asia-northeast1 --range=172.16.10.0/24#;

    print ("\n******************************************************\n");
    print ("Creating VPC for Server Network");
    print ("\n******************************************************\n");
    qx#gcloud -q compute networks create vpx-snet-snip --subnet-mode=custom#;
    qx#gcloud -q compute networks subnets create vpx-snet-snip --network=vpx-snet-snip --region=asia-northeast1 --range=10.10.10.0/24#;
}

if ($CREATE_GKE eq "TRUE") {
    print ("\n******************************************************\n");
    print ("Creating a 3 node GKE Cluster");
    print ("\n******************************************************\n");
	qx#gcloud -q beta container clusters create "k8s-cluster-with-cpx" --zone "asia-northeast1-b" --username "admin" --machine-type "n1-standard-1" --image-type "COS" --disk-type "pd-standard" --disk-size "100" --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --num-nodes "3" --enable-cloud-logging --enable-cloud-monitoring --no-enable-ip-alias --network "projects/$project_id/global/networks/vpx-snet-snip" --subnetwork "projects/$project_id/regions/asia-northeast1/subnetworks/vpx-snet-snip" --addons HorizontalPodAutoscaling,HttpLoadBalancing --enable-autoupgrade --enable-autorepair#;
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
    qx#gcloud -q deployment-manager deployments create tier1-vpx --config $vpx_deployment_config_file#;
}

if ($CONFIG_VPX eq "TRUE") {

    print ("\n******************************************************\n");
    print ("Waiting for the VPX to boot up");
    print ("\n******************************************************\n");
    sleep(60);
    print ("\n******************************************************\n");
    print ("Doing basic VPX Configuration");
    print ("\n******************************************************\n");
    qx#gcloud -q compute ssh $vpx_instance_name --zone $zone --command "show version"#;
    qx#gcloud -q compute ssh $vpx_instance_name --zone $zone --command "show version"#;
    qx#gcloud -q compute ssh $vpx_instance_name --zone $zone --command "add ns ip 10.10.10.20 255.255.255.0 -type snip -mgmt enabled"#;
    qx#gcloud -q compute ssh $vpx_instance_name --zone $zone --command "enable ns mode mbf"#;

}

print ("\n******************************************************\n");
print ("Deployment Done");
print ("\n******************************************************\n");

print ("\n******************************************************\n");
print ("End of Automated Deployment for the training lab");
print ("\n******************************************************\n");


