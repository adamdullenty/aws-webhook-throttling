# Inbound webhook throttling via SQS

This is a really rough proof of concept for throttling inbound webhooks using SQS and reserved concurrency.

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

### Local development

You can invoke your function locally by using the following command:

```bash
serverless invoke local --function processRequest --data '{"test": "hello!"}'
```
