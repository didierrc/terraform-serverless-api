# Serverless Application and Terraform to Automate Infrastructure

## 🧑‍💻 Contributors 🧑‍💻

| Name                      | Email              |
| ------------------------- | ------------------ |
| Didier Yamil Reyes Castro | UO287866@uniovi.es |
| Raúl Mera Soto            | UO287827@uniovi.es |

## Setting up Terraform
- Go to [Terraform Donwload Page](https://developer.hashicorp.com/terraform/install?product_intent=terraform).
- Download the file related to your OS (for this guide, Windows).
- A zip is downloaded, unzip it on ``C:\terraform`` or any other folder you want.
- Go to Advanced System Settings > Environment Variables.
- Select the *path* variable and add to it the path where the Terraform executable is located (ex. C:\terraform).
- Go to Powershell to check everything is OK:
  ````console
  PS C:\Users\foo> terraform -version
  Terraform v1.8.2
  on windows_386
  ````

## Syntax for terraform
You can visit de [docs](https://developer.hashicorp.com/terraform/docs).
But mainly:

- Configuration of Terraform
````terraform
  terraform {
      required_version = ">= 0.13" # Version
      required_providers { # AWS Provider
         source = "hashicorp/aws"
         aws = "~> 5.0"
      }
      # ...more providers ...
  }
````

- Configuration of Providers
````terraform
  provider "foo" { # ex. provider "aws"
      # ... see docs of providers in https://registry.terraform.io/browse/providers ...
  }
````

- Configuration of Resources
````terraform
  resource "foo" "bar" { # ex. resource "aws_lambda_function" "my_lambda_test"
      # ...see docs of resources of each provider ...
  }
````
- Output (useful for creation of resources that generates an URL)
````terraform
output "foo"{ # ex. output "endpoint"
  description = "My incredible output"
  value = "bar" # ex. aws_apigatewayv2_api.gateway_test.endpoint
}
````

## Before Setting up Lambda

Thanks to https://www.youtube.com/watch?v=nn5cRu8O70Y for this first part.

The main thing is to create an IAM User. It is highly recommendable
to create one and not use the credentials of ROOT account. Also, it is not
advisable to write the credentials inside TF files and uploading to CVS sites.

1. Go to the IAM section
2. Create a new user: Provide a name and Attach policies (this case AdminAccess but,
   in real world, we have to give limited access to create new resources
   otherwise, someone can take advantage of that)
3. Once created, press in *Create access key*.
4. Just select an option. In this case, *Third party vendor*.
5. After creation it shows to you ID Key (public) and Secret Key (private) and an option to download a CSV file
   with these info. Do that.
6. In Terraform, there are a lot of ways of [authentication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
   in the section of *Authentication and Configuration*. The one chosen is called
   *Shared credentials files*. This simply means having a file with our credentials
   and referring from Terraform to that place.
8. Create a directory on ``C:\Users\foo\.aws``
9. Create a file there called **credentials**.
10. In this file, we can define several profiles and assign to it the public and secret key. Copy your credentials
    as follows.
    ````
    [default]
    aws_access_key_id=AAAAAAAABBBBBB
    aws_secret_access_key=5buibHHYInnlllLLLLLLoooo000
    ````

## Setting up a Simple Lambda

Thanks to https://spacelift.io/blog/terraform-aws-lambda

0. Setting up TF and Provider
   Simply we specify the provider to use by terraform and the versions of both.
   Then we configure the provider with the Credentials we built before.
   ````terraform
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
    shared_credentials_files = ["/Users/foo/.aws/credentials"]
   }
   ````

2. Setting up the IAM role together with a Policy
   `````terraform
     # Creating IAM Role
     # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
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
   
   # Creating IAM Policy (to be attached into Role and allow creating logs in CloudWatch)
   # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy
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

   # Attaching IAM Policy to IAM Role
   # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment
   resource "aws_iam_role_policy_attachment" "attach_iam_policy_iam_role"{
      role        = aws_iam_role.lambda_role.name
      policy_arn  = aws_iam_policy.lambda_iam_policy.arn
   } 
   
3. Create the lambda function to show
   In this case, it is simply a "Hello world" file. **(it is not simply lambda.js but lambda.mjs)**.
   ````javascript
   export const handler = async (event) =>{
      console.log(event);
      return {
        statusCode: 200,
        body: JSON.stringify("Hello from Lambda")
      }
   };
   ````
5. ZIP the file to upload
   The resource to create a lambda function does not allow file uploading and all must be inside a zip.
   ````terraform
     # Creating ZIP
     # https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file
     data "archive_file" "zip_js_code" {
        type = "zip"
        source_dir = "${path.module}/mjsFolder/"
        output_path = "${path.module}/mjsFolder/lambdaHelloWorld.zip"
     }
   ````
7. Create the Lambda resource
````terraform
# Creating the Lambda Resource
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function
# role = TF name of role created previously
# handler = MJS_File "." Name_FX
# depends_on = not built until attachment is performed
resource "aws_lambda_function" "test_lambda_asr" {
    filename        = "${path.module}/awsTest/lambdaHelloWorld.zip"
    function_name   = "My_Incredible_Lambda_Test"
    role            = aws_iam_role.lambda_role.arn
    handler         = "lambda.handler"
    runtime         = "nodejs20.x"
    depends_on      = [aws_iam_role_policy_attachment.attach_iam_policy_iam_role]
}
```` 
9. Initialise Terraform with corresponding providers
````console
PS C:\Users\foo> terraform init
````
11. See the plan of what will Terraform do.
````console
PS C:\Users\foo> terraform plan
````
13. Automate!!
````console
PS C:\Users\foo> terraform apply
...
Do you want to perform these actions? 
  Terraform will perform these actions described above.
  Only 'yes' will be accepted to approve.
  Enter a value: yes
...
````
14. If you want to destroy what has been created
````console
PS C:\Users\foo> terraform destroy
...
Do you really want to destroy all resources? 
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.
  Enter a value: yes
...
````
