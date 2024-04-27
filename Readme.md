# Serverless Application and Terraform to Automate Infrastructure

Explain what is Terraform and the usage of it. Explain also the goal
related to previous project (trying to automate that process)

Along creating the TF code, we can also show the corresponding parts
doing manually "to increase pages" 😉

## Setting up Terraform
- Go to https://developer.hashicorp.com/terraform/install?product_intent=terraform
- Download the file realated to your OS (this case, Windows)
- A zip is downloaded, unzip it on C:\terraform f.i.
- Go to Advanced System Settings > Environmente Variables
- Select the *path* variable > Add the paht where Terraform executable is C:\terraform
- Powershell: terraform -version

### Syntax for terraform
You can visit de docs https://developer.hashicorp.com/terraform/docs
But mainly:

- Configuration of Terraform
``
  terraform {
      required_version = ">= 0.13"
      required_providers {
         source = "hashicorp/aws"
         aws = "~> 5.0"
      }
      ...more providers ...
  }
``

- Configuration of Providers
``
  provider "name" {
      ...see docs of providers in https://registry.terraform.io/browse/providers ...
  }
``

- Configuration of Resources ("the things you can create")
``
  resource "name" "nameToReferInsideTF" {
      ...see docs of resources...
  }
`` 

## Before Setting up Lambda

For this, the initial part was followed: https://www.youtube.com/watch?v=nn5cRu8O70Y&t=310s

The main thing is to create an IAM User. It is highly recommendable
to create one and not use the credentials of ROOT account. Also, it is not
advisable to write up in front the credentials.

1. Go to the IAM section
2. Create a new user: Name, Attach policies (this case AdminAccess but
   in real world we have to give limited access to create new resources
   otherwise, someone can take advantage of that)
3. Once created, press in "Create access key"
4. Just select an option (this is just Amazon's way to warn you on creating
   these keys for certain use cases. Ex: if token is used for third party like
   Terraform we can see that a best practice is ... -> Just an advise)
5. I haven't captured it but after creation it shows to you
   ID Key (public) and Secret Key (private) and an option to download a CSV file
   with these info.
6. If we go to https://registry.terraform.io/providers/hashicorp/aws/latest/docs
   we can find the section of "Authentication and Configuration". There it is shown
   a lot of ways to input the credentials. The one chosen is called "Shared credentials files"
   This simply means having a file with our credentials and referring from Terraform to there.
7. Create a directory on C:\Users\YourUser\.aws
8. Create a file there called credentials
9. This file is of the form //Image//
    Basically, we can define several profiles "[myProfile]" and assign to it the public
    and secret key.
10. Copy your credentials in that format (later it is pointed from TF)

## Setting up a Simple Lambda (first step)

For this, we followed https://spacelift.io/blog/terraform-aws-lambda

0. Setting up TF and Provider
   Simply we specify the provider to use by terraform and the versions of both.
   Then we configure the provider with the Credentials we built before.

1. Setting up the IAM role together with a Policy
   This is the same as in PDF when we had access to CloudWatch
   to monitor our Lambda fx.
2. Create the lambda function to show
   In this case, it is simply a "Hello world" (as in previous pdf)
   file in JS
3. ZIP JS file
   The resource to create a lambda function does not allow file uploading
   and all must be inside a zip.
4. Create the Lambda resource
   If you follow the URL found in main.tf, you will find that has everything explained
   in the blog. The main difference that I see is the usage of "data" entries.
   
   I think that previously TF did not allow JSON inside the resources so two ways
   to doing that was: data entries (specific of providers) and "<<EOF"

   Then, I think jsonEncode was introduced to replace the ugly "<<EOF". So in reality
   I think that using data is "cleaner" to keep the configuration appart from the
   resources initialisation.
5. $ terraform init -> Initialise Terraform with corresponding providers
6. $ terraform plan -> A plan of what will Terraform do (in sequential order)
7. $ terraform apply -> Automate!! 

## Full main.tf
```js
// Setting the terraform configuration
// Docs on providers:  https://developer.hashicorp.com/terraform/language/providers
// For this project, AWS provider is required: 
// https://registry.terraform.io/providers/hashicorp/aws/latest/docs
terraform {
  required_version = ">= 0.12"
    
  required_providers {
    aws = {
        source  = "hashicorp/aws"
        version = "~> 5.0"
    }
  }
}

// Configuring the provider
// We could also define a profile = "nameProfile"
// If not set, "default" profile is taken
provider "aws" {
    region = "eu-central-1"
    shared_credentials_files = ["/Users/didie/.aws/credentials"]
}

// Creating IAM Role
// https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
// If following blog, you need to <<EOF but seems with newer versions now JSON is supported
resource "aws_iam_role" "lambda_role"{
    name    =   "asr_test_lambda_role"
    assume_role_policy  = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Sid    = ""
                Principal = {
                    Service = "lambda.amazonaws.com"
                }
            }
        ]
    })
}

// Creating IAM Policy (to be attached into Role and allow creating logs in CloudWatch)
// https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy
// Only allowing the logs resources. If all: Resource = "*"
resource "aws_iam_policy" "lambda_iam_policy" {
    name        = "asr_test_lambda_iam_policy"
    path        = "/"
    description = "AWS IAM Policy for Managing AWS Lambda Role"
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = [
                    "logs:CreateLogGroup",
                    "logs:CreateLogStream",
                    "logs:PutLogEvents"
                ]
                Effect   = "Allow"
                Resource = "arn:aws:logs:*:*:*"
            },
        ]
    })
}

// Attaching IAM Policy to IAM Role
// https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment
resource "aws_iam_role_policy_attachment" "attach_iam_policy_iam_role"{
    role        = aws_iam_role.lambda_role.name
    policy_arn  = aws_iam_policy.lambda_iam_policy.arn
}

// Creating ZIP
// https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file
data "archive_file" "zip_js_code" {
    type = "zip"
    source_dir = "${path.module}/awsTest/"
    output_path = "${path.module}/awsTest/lambdaHelloWorld.zip"
}

// Creating the Lambda Resource
// https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function
// role = TF name of role created previosuly
// handler = JS_File "." Name_FX
// depends_on = not built until attachment is performed
resource "aws_lambda_function" "test_lambda_asr" {
    filename        = "${path.module}/awsTest/lambdaHelloWorld.zip"
    function_name   = "My_Incredible_Lambda_Test"
    role            = aws_iam_role.lambda_role.arn
    handler         = "lambda.handler"
    runtime         = "nodejs20.x"
    depends_on      = [aws_iam_role_policy_attachment.attach_iam_policy_iam_role]
}
``
