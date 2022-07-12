# Initial GCP Setup

This document outlines the setup and prerequisites required to run the lab automation. 

## Tooling
[Terraform v1.03+](https://www.terraform.io/downloads.html)  
[Google Cloud SDK](https://cloud.google.com/sdk/docs/install)  
[GitHub Account](https://github.com/join)  

## GCP Project and APIs

The following set of commands will create a new GCP project with the necessary API's enabled and service account credentials required to execute the lab automation. 
All credentials are stored in folder that is local to your machine and is ignored by git. 


```shell

# Create a unique project
gcloud projects create --name ctx-anthos

# Set the local environment variable to the GCP project ID
GCP_PROJECT=$(gcloud projects list  | grep PM-GCP-Anthos | awk '{print $1}')

# Link the GCP project to a billing account (substitute in your billing account ID) 
gcloud beta billing projects link $GCP_PROJECT --billing-account=[BILLING ACCOUNT ID]


# Enable APIs
gcloud services enable \
 --project=$GCP_PROJECT\
 anthos.googleapis.com \
 anthosaudit.googleapis.com \
 anthosconfigmanagement.googleapis.com \
 anthosgke.googleapis.com \
 anthosidentityservice.googleapis.com \
 container.googleapis.com \
 gkeconnect.googleapis.com \
 gkehub.googleapis.com \
 cloudresourcemanager.googleapis.com \
 iam.googleapis.com

# Create a local directory that is ignored by git
mkdir creds

# Create a service account, download the credential file, and provide OWNER rights to the project
gcloud iam service-accounts create ctx-bcom --project $GCP_PROJECT
gcloud iam service-accounts keys create creds/ctx-bcom.json --iam-account=ctx-bcom@$GCP_PROJECT.iam.gserviceaccount.com
gcloud projects add-iam-policy-binding $GCP_PROJECT --member="serviceAccount:ctx-bcom@$GCP_PROJECT.iam.gserviceaccount.com" --role='roles/owner'

```

**Continue on with [lab deployment](README.md)**