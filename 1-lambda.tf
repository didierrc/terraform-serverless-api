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