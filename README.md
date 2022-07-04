# AWS ECS Demo with Github Action

This project mainly demonstrates how to use Github Action to automate the deployment of code to AWS ECS clusters. Among them, the ECS cluster is created and recycled using the Terraform tool. Terraform is a very useful IaC tool that is favored by DevOps.

## ECS 

+ __What is ECS? __

  > __Amazon Elastic Container Service (Amazon ECS) is a highly scalable and fast container management service that you can use to manage containers on a cluster.__  -- <big>*The Official words.*</big>

  ECS runs your containers on an EC2 cluster with Docker pre-installed(Your can use Fargate to control the EC2 resource). It handles installing containers, scaling, monitoring, and managing these instances through the API and the AWS Management Console. It allows you to simplify your view of EC2 instances into resource pools.

+ __The Term__

  + `task definition`

    This is the blueprint that describes which Docker containers to run and represents your application. The image to use, CPU and memory to allocate, environment variables, ports to expose, and how the container interacts will be detailed.

  + `tasks`

    An instance of a task definition that runs the container detailed in it. A task definition can create as many tasks as needed.

  + `service`

    Defines the minimum and maximum tasks in one task definition to run at any given time, with autoscaling and load balancing.

  + `cluster`

    A cluster is a group of ECS container instances. A cluster can run many services. ECS handles the logic to schedule, maintain, and handle scaling requests to these instances. If you have multiple applications in your product, you may want to put several of them on a cluster. This makes more efficient use of available resources and minimizes setup time.

## Infrastructure

All the code you can check and view in the folder of "IaC" in this Repo.

### Build Steps

__*The steps to run and build infrastructure as below.*__

+ initialization: Initialize the terraform environment

  ```shell
  terraform init
  ```
+ Validation: Check the syntax error

  ```shell
  terraform validation
  ```
+ Plan: check the deploy plan

  ```shell
  terraform plan
  ```
+ Apply: deploy the infrastructure

  ```shell
  terraform apply
  ```
+ Destroy: Delete all the infrastructure

  ```shell
  terraform destroy
  ```

### Build Resource

+ VPC and Subnet
+ Security Gateway(SG)
+ Elastic Balance(ALB)
+ ECR
+ ECS
+ IAM Role

### Notes

1. If you are using a Windows system, be sure to install the windows docker desktop and run the Docker daemon. Otherwise, the process of pushing image to ECR will fail because the local Docker process is not enabled.

2. Since the AWS CLI command line is used in the process of pushing the Image to the ECR warehouse, you need to configure the credentials for the AWS CLI first, otherwise the AWS CLI cannot link to the AWS service console.

3. The python code in the src foder is the Minimum usable program which is used to build the initial image and push to ECR.

4. You must provide your AWS key and secret, and give the value in the "terraform.tfvars" as below:

   ```shell
   # provider
   aws_region = "us-east-1"
   aws_access_key = "xxxxxx"
   aws_secret_key = "xxxxxx"
   ```

If the terminal output as below, it means all infrastructure build success.

```shell
Apply complete! Resources: 38 added, 0 changed, 0 destroyed.

Outputs:

ecr_repo_url = "xxx.dkr.ecr.us-east-1.amazonaws.com/ecs-demo-repo"
endpoint_url = "ecs-demo-alb-xxx.us-east-1.elb.amazonaws.com"
```

__*Open your Brower and visit the endpoint url, you can see "Hello,word" display on the page.*__

## Github Action 

### Overview

__*All the workflow fo CICD pipeline code you can check and review in the folder of ".github".*__
In this case, our automated deployment pipeline is divided into two types of jobs: CI and CD. CI mainly implements static analysis and unit testing of code, and CD mainly implements packaging and updating Elastic Beanstalk status. Please pay attention to the conditions for executing CICD actions in this case, and you can adjust all the pipeline job steps according to the actual situation.
The workflow as below:

+ CI
  + Checkout the Code to the github runner
  + Lint the code, you can run flake8 or other tools to check the code format.
  + Run the unittest, you can use tox, pytets, unittest or some tools to implement the unit test of the code.
+ CD
  + Checkout the Code to the github runner
  + Configure AWS Credentials
  + Login to Amazon ECR
  + Build, tag, and push image to Amazon ECR
  + Download task definition
  + Fill in the new image ID in the Amazon ECS task definition
  + Deploy Amazon ECS task definition

### Notes

1. The parameters you can found in the IaC code.

   ```shell
   task-definition: ecs-demo-td
   ecs service: ecs-demo-app
   ecs cluster: ecs-cluster-for-demo
   ecs container-name: ecs-demo-app
   ecr repository: ecs-demo-repo
   ```

2. The `task-definition .json` file you can generated by this command.

   ```shell
   aws ecs describe-task-definition \
      --task-definition ecs-demo-td \
      --query taskDefinition > task-definition.json
   ```

   __Don`t worry, I download the task definition json file in the cicd jobs__

3. The CICD execution is preconditions. Only when the branch is tagged and pushed to github, or when a release is required, only the CICD pipeline is needed. Please view and modify the .github.yml file according to the actual situation.

## Summary

For containerized deployment and operation and maintenance, ECS is a very useful service launched by AWS. If you are familiar with Docker, then just read the official ECS documentation to get started. This demo project mainly uses Terraform to build and destroy the required infrastructure, and uses Github Action for automated deployment (update the Image of Task Definition). You can refer to this case to learn and deploy your own code.

__*Welcome to Fork and Star, thanks for reading.*__

## Reference

+ [Amazon ECS "Deploy Task Definition" Action for GitHub Actions](https://github.com/aws-actions/amazon-ecs-deploy-task-definition)
+ [Gentle Introduction to How AWS ECS Works with Example Tutorial](https://medium.com/boltops/gentle-introduction-to-how-aws-ecs-works-with-example-tutorial-cea3d27ce63d)
+ [Deploying Clustered Akka Applications on Amazon ECS](https://medium.com/@ukayani/deploying-clustered-akka-applications-on-amazon-ecs-fbcca762a44c)
+ [Building Blocks of Amazon ECS](https://medium.com/containers-on-aws/building-blocks-of-amazon-ecs-db7fdfeeaa6f)
+ [Introduction to Amazon EC2 Container Service (ECS) — Docker Management on AWS](https://www.youtube.com/watch?v=zBqjh61QcB4)
+ [Using Amazon ECR with the AWS CLI](https://docs.aws.amazon.com/AmazonECR/latest/userguide/getting-started-cli.html)
+ [Configuration and credential file settings](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)

