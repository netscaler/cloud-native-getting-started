#!/usr/bin/perl 

my $operation = $ARGV[0];

if ($operation eq "delete") {

    qx#gcloud -q deployment-manager deployments delete tier1-vpx#;
    qx#gcloud -q beta container clusters delete "k8s-cluster-with-cpx" --zone "us-east1-b"#;

    qx#gcloud -q compute networks subnets delete vpx-snet-mgmt --region=us-east1#;
    qx#gcloud -q compute --project=netscaler-networking-k8 networks delete vpx-snet-mgmt#;

    qx#gcloud -q compute networks subnets delete vpx-snet-vip --region=us-east1#;
    qx#gcloud -q compute --project=netscaler-networking-k8 networks delete vpx-snet-vip#;

    qx#gcloud -q compute networks subnets delete vpx-snet-snip --region=us-east1#;
    qx#gcloud -q compute --project=netscaler-networking-k8 networks delete vpx-snet-snip#;

    qx#rm -rf ~/example-cpx-vpx-for-kubernetes-2-tier-microservices/#;

    exit;

}

my $project_id = $ENV{'GOOGLE_CLOUD_PROJECT'}; 
my $home_dir = $ENV{'HOME'}; 
my $repo_path = $ENV{'HOME'} . "/example-cpx-vpx-for-kubernetes-2-tier-microservices/";
my $config_dir = $repo_path . "/gcp/config-files/";
my $vpx_deployment_config_file = $config_dir . "/configuration.yml";
my $zone = "us-east1-b";
my $vpx_instance_name = "citrix-adc-tier1-vpx";

my $CLONE_REPO = "TRUE";
my $CREATE_VPX_IMAGE = "TRUE";
my $CREATE_GKE = "TRUE";
my $CREATE_VPC = "TRUE";
my $CREATE_VPX = "TRUE";
my $CONFIG_VPX = "TRUE";

if ($CREATE_VPX_IMAGE eq "TRUE") {
    # Forking a new process for Image creation
    my $image_creation_pid = fork();
    if (not $image_creation_pid) {
       print ("\nImage Creation Child Process: Entering\n");
       my $out = qx#gcloud -q compute images create netscaler12-1 --source-uri=gs://tme-cpx-storage/NSVPX-GCP-12.1-50.28_nc.tar.gz --guest-os-features=MULTI_IP_SUBNET#;

       print ("\nOutput of Image Creation is \n$out\n");
       print ("\nImage Creation Child Process: Exiting\n");
       exit;
    }
}

print ("\nStating Automated Deployment for the training lab\n\n");

if ($CLONE_REPO eq "TRUE") {
    print ("\nCloning the GIT repo to your home directory\n");
    qx#git clone https://github.com/citrix/example-cpx-vpx-for-kubernetes-2-tier-microservices.git $repo_path#;
}

print ("This automated deployment would create: \n");
print ("1. VPC Networks\n");
print ("2. VPC Subnets\n");
print ("3. GKE Kubernetes cluster\n");


if ($CREATE_VPC eq "TRUE") {
    print ("\nCreating VPC for Management Network\n");
    qx#gcloud -q compute networks create vpx-snet-mgmt --subnet-mode=custom#;
    qx#gcloud -q compute networks subnets create vpx-snet-mgmt --network=vpx-snet-mgmt --region=us-east1 --range=192.168.10.0/24#;

    print ("\nCreating VPC for Client Network\n");
    qx#gcloud -q compute networks create vpx-snet-vip --subnet-mode=custom#;
    qx#gcloud -q compute networks subnets create vpx-snet-vip --network=vpx-snet-vip --region=us-east1 --range=172.16.10.0/24#;

    print ("\nCreating VPC for Server Network\n");
    qx#gcloud -q compute networks create vpx-snet-snip --subnet-mode=custom#;
    qx#gcloud -q compute networks subnets create vpx-snet-snip --network=vpx-snet-snip --region=us-east1 --range=10.10.10.0/24#;
}

if ($CREATE_GKE eq "TRUE") {
    print ("\nCreating a 3 node GKE Cluster\n");
    qx#gcloud -q beta container --project "$project_id" clusters create "k8s-cluster-with-cpx" --zone "us-east1-b" --username "admin" --cluster-version "1.11.7-gke.12" --machine-type "n1-standard-1" --image-type "COS" --disk-type "pd-standard" --disk-size "100" --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --num-nodes "3" --enable-cloud-logging --enable-cloud-monitoring --no-enable-ip-alias --network "projects/$project_id/global/networks/vpx-snet-snip" --subnetwork "projects/$project_id/regions/us-east1/subnetworks/vpx-snet-snip" --addons HorizontalPodAutoscaling,HttpLoadBalancing --enable-autoupgrade --enable-autorepair#;
}

if ($CREATE_VPX == "TRUE") {
    print ("\nEditing the deployment manager configuration file\n");
    qx#sed -i "s/<your project name>/$project_id/g" $vpx_deployment_config_file#;
}

if ($CREATE_VPX_IMAGE eq "TRUE") {
    # Before VPX creation - Image creation should finish. Wait for that to complete
    print ("\nWaiting for the Image creation to complete\n");
    my $finished = wait();
    print ("\nImage creation process for VPX has been completed\n");
}

if ($CREATE_VPX == "TRUE") {
    print ("\n Creating VPX using GDM Template\n");
    qx#gcloud -q deployment-manager deployments create tier1-vpx --config $vpx_deployment_config_file#;
}

if ($CONFIG_VPX == "TRUE") {
    print ("\nDoing basic VPX Configuration\n");
    qx#gcloud -q compute ssh $vpx_instance_name --zone $zone --command "show version"#;
    qx#gcloud -q compute ssh $vpx_instance_name --zone $zone --command "show version"#;
    qx#gcloud -q compute ssh $vpx_instance_name --zone $zone --command "add ns ip 10.10.10.20 255.255.255.0 -type snip -mgmt enabled"#;
    qx#gcloud -q compute ssh $vpx_instance_name --zone $zone --command "enable ns mode mbf"#;
}
