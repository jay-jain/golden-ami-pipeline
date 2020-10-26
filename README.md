# Golden AMI Pipeline
This project has two main components:
* The [terraform](./terraform/) repository used to deploy the pipeline (CodeCommit, CodeBuild, CodePipeline, S3 Artifact Bucket, Launch Template, AutoScaling Group, Lambda Function, and SNS Topic) 

* The [repo-source](./repo-source/) repository which contains the Packer script, the build script used in the Packer AMI build, the buildspec file used in CodeBuild, and the CloudWatch Event JSON template.

## How to Use
To deploy this pipeline, you must deploy the terraform project first with:
` terraform init`
` terraform apply -auto-approve`
* Make sure your AWS CLI is configured correctly before you run these commands.
* This will construct your pipeline components and will output the SSH URL of your Code Commit Repository.
* If you have not configured Code Commit for SSH access you will have to go in the console to upload your SSH public key and you will also need to modify your git configuration on your local machine. If you got to the Code Commit console, you will find instructions there on how to set this up before you can successfully clone your repo.
* Once you have cloned your empty repo, you should add the contents of the [repo-source](./repo-source/) directory to your new Code Commmit repository.
* Now you can commit and push the code with:
```
git add .
git commit -m "Build new AMI"
git push -u origin master
```

This will trigger the pipeline process. Once the AMI has been built, a CloudWatch Event will trigger a Lambda function that:
* Updates the Launch Template with the new AMI ID
* Updates the AutoScaling Group by increasing the desired capacity to 2. This launches a new instance in the ASG with the new AMI ID. Then the desired capacity is lowered back down to one. This forces the ASG to delete the instance with the old AMI. Note: This strategy assumes that the original AutoScaling Group has a min capacity of 1, max capacity of 2, and desired capacity of 1.
* Deletes unused AMIs, AMIS older than 14 days, and snapshots not associated with an AMI
* Notify an SNS topic that a user is subscribed to (Note, you must manually go into the console to subscribe to SNS topics. Terraform does not support SNS topic Email subscriptions as of Oct. 2020) 

Notes:
* Currently, the packer script (`build-ami.json`) uses the `scripts/bootstrap.sh` file. This script simply installs and configures a basic web page on an Apache web server. 
* Remember, the first time you deploy the terraform, the AMI will be the one specified in the ```base_ami``` variable. I recommend using one of the quick start AMIs. Remember to use the correct AMI ID based on what region you intend to use. 

## References

https://github.com/awslabs/ami-builder-packer

https://aws.amazon.com/blogs/devops/how-to-create-an-ami-builder-with-aws-codebuild-and-hashicorp-packer/

https://misterorion.com/lambda-update-ami

## To Dos:

* Lambda function (located in `lambda-asg-updater/` directory) needs to be integrated into main `terraform/` directory once it is fixed.

* Restricting IP for the temporary Security Group created by Packer.
For example, in the packer script in the builder section:
```"temporary_security_group_source_cidrs" : "['10.0.0.0/8']"```

* In the terraform code, make sure snapshots, AMIs, volumes, are encrypted

* In the `buildspec.yml` file, fix the `CODEBUILD_RESOLVED_SOURCE_VERSION` environment variable so that it can be used as a tag on the AMI.

* In the `buildspec.yml`, pass in a region variable to `packer build` that can be used to specify region the Packer build instance will be launched in. 

* In the `buildspec.yml`, pass in a application prefix variable to `packer build` that can be used in the ami name. 

* Integrate `snapshots.py` into main lambda function ( `lambda_handler.py`)

* ~~Add support gov-cloud arns: ```aws-us-gov```~~

## Sample terraform.tfvars file
```
vpc_id = "vpc-a1e205d9"

subnet_id = "subnet-c81a0be6"

account_id = "194030451624"

application = "GitLab"

base_ami = "ami-0dba2cb6798deb6d8" # Ubuntu 20.04 Server x64 for us-east-1 region

region = "us-east-1"

availability_zones = ["us-east-1a","us-east-1b","us-east-1c","us-east-1d","us-east-1e","us-east-1f"]

key_name = "MyKP"

vpc_security_group_ids = ["sg-1523542748q3j3628"]

```

