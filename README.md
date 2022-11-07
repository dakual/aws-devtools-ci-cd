SSH connections to AWS CodeCommit repositories
```sh
$ ssh-keygen    # /home/your-user-name/.ssh/codecommit_rsa
$ cat ~/.ssh/codecommit_rsa.pub
> Upload SSH public key to AWS IAM and save the information in SSH Key ID

$ nano ~/.ssh/config

Host git-codecommit.*.amazonaws.com
  User APKAEIBAERJR2EXAMPLE
  IdentityFile ~/.ssh/codecommit_rsa

$ chmod 600 config
$ ssh git-codecommit.eu-central-1.amazonaws.com
```

Create a repository (AWS CLI)
```sh
aws codecommit create-repository --repository-name devtools-demo --repository-description "AWS Dev Tolls CI/CD Demo" --tags Env=dev
```

To delete the CodeCommit repository (AWS CLI)
```sh
aws codecommit delete-repository --repository-name devtools-demo
```

Demo Application
```sh
docker build -t demo-app --no-cache .
docker run -it --rm --name demo-app -p 8080:8080 demo-app:latest
```