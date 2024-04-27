resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = "files"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "id" # Partition Key

  # defining type of partition key: S - String
  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_iam_policy" "lambda_iam_policy_putItem" {
    name        = "asr_test_lambda_iam_policy_putItem"
    path        = "/"
    description = "AWS IAM Policy for Putting Items into DynamoDB"
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = [
                    "dynamodb:PutItem",
                ]
                Effect   = "Allow"
                Resource = "${aws_dynamodb_table.basic-dynamodb-table.arn}"
            },
        ]
    })
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_iam_role_dynamo"{
    role        = aws_iam_role.lambda_role.name
    policy_arn  = aws_iam_policy.lambda_iam_policy_putItem.arn
}