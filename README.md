# Inbound webhook throttling via SQS

This is a really rough proof of concept for throttling inbound webhooks using SQS and reserved concurrency.

![Inbound webhook throttling drawio(1)](https://user-images.githubusercontent.com/3620459/151139876-a572b6ee-e240-420f-88ba-4eb4f725fe45.png)

## Usage

### Deployment

In order to deploy this, you will need to run the following command:

```
$ serverless deploy
```

After running deploy, you should see output similar to:

```bash
Serverless: Packaging service...
Serverless: Excluding development dependencies...
Serverless: Creating Stack...
Serverless: Checking Stack create progress...
........
Serverless: Stack create finished...
Serverless: Uploading CloudFormation file to S3...
Serverless: Uploading artifacts...
Serverless: Uploading service webhook-test-2.zip file to S3 (711.23 KB)...
Serverless: Validating template...
Serverless: Updating Stack...
Serverless: Checking Stack update progress...
.................................
Serverless: Stack update finished...
Service Information
...
```

### Invocation

After successful deployment, you can invoke the deployed function by using the following command:

```bash
serverless invoke --function processRequest --data '{"test": "hello!"}'
```

Which should result in a response similar to the following:

```json
{
  "statusCode": 200,
  "body": {
    "message": "Pushed into SQS!",
    "input": {
      "test": "hello!"
    }
  }
}
```

If you have configured an API endpoint to receive these requests via REQUEST_BIN_URL (see handler.rb), this endpoint should receive a request containing the parsed value from the "test" object:

```
body:
  original_event: "{\"test\": \"hello!\"}"
  parsed_test_value: "hello!"
headers:
  accept: "*/*"
  content-type: "application/json"
host: "enmw2ww7ngty8tf.m.pipedream.net"
user-agent: "Ruby"
method: "POST"
```
