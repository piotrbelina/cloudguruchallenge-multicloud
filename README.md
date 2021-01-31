# CloudGuruChallenge Multi-Cloud Madness

This is a repository for [Cloud Guru Challenge Multi-Cloud Madness](https://acloudguru.com/blog/engineering/cloudguruchallenge-multi-cloud-madness).

Here is [my article describing my solution](https://www.piotrbelina.com/cloudguru-multi-cloud-challenge/).

## Prerequisites
Following packages are needed to deploy the code.
* Terraform
* AWS CLI
* AWS SAM CLI
* Azure CLI
* GCP CLI
* Docker
* Python 3.8

## Deploy
```bash
cd lambda
sam build --use-container
sam deploy --guided
cd ..
terraform init
terraform apply
```
