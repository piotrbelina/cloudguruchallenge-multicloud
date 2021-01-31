# CloudGuruChallenge Multi-Cloud Madness

This is a repository for [Cloud Guru Challenge Multi-Cloud Madness](https://acloudguru.com/blog/engineering/cloudguruchallenge-multi-cloud-madness).

Here is [my article describing my solution](http://piotrbelina.com/cloudguru-multi-cloud-challenge/).

## Deploy
```bash
cd lambda
sam build --use-container
sam deploy --guided
cd ..
terraform init
terraform apply
```