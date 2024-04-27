# Building an HTTP API using default settings
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api
# https://advancedweb.hu/how-to-use-the-aws_apigatewayv2_api-to-add-an-http-api-to-a-lambda-function/#default-stage-and-route
resource "aws_apigatewayv2_api" "gw_test" {
    name            = "asr_apigw_for_lambda"
    protocol_type   = "HTTP"
    target          = aws_lambda_function.test_lambda_asr.arn
}

resource "aws_lambda_permission" "lambda_access_permission"{
    action          = "lambda:InvokeFunction"
    function_name   = aws_lambda_function.test_lambda_asr.arn
    principal       = "apigateway.amazonaws.com"

    source_arn      = "${aws_apigatewayv2_api.gw_test.execution_arn}/*/*"
}

resource "aws_apigatewayv2_route" "files_route"{
    api_id          = aws_apigatewayv2_api.gw_test.id
    route_key       = "POST /files"
}

output "endpoint"{
    description     = "HTTP API endpoint URL"
    value           = aws_apigatewayv2_api.gw_test.api_endpoint
}

