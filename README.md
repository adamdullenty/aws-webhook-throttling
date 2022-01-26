# Inbound webhook throttling via SQS

This is a really rough proof of concept for throttling inbound webhooks using SQS and reserved concurrency.

![Inbound webhook throttling drawio(1)](https://user-images.githubusercontent.com/3620459/151139876-a572b6ee-e240-420f-88ba-4eb4f725fe45.png)

This consists of:

* An API Gateway endpoint that triggers a Lambda function
* A Lambda function to push webhook payloads into SQS unaltered
* An SQS queue
* A Lambda function that receives SQS events (batch size 1), parses the event body, and posts it to an API endpoint
  * This Lambda has a max concurrency of 1, which enables this method of throttling inbound API requests

This will allow the API Gateway endpoint to receive spikes of inbound webhook traffic, and these requests will then be smoothed out when they are eventually posted to our internal API endpoint.

## Real-world enhancements

* Pull all config into the handlers via env vars set in `serverless.yml`
* Handle HMAC verification within the API Gateway config
* Configure API Gateway endpoint to push events directly into SQS, remove the initial Lambda function (AWS supports API Gateway pushing events directly into SQS, but I had issues getting this working via Serverless plugins)
* Error handling
* Observability (metrics, better logging)
* If our internal API endpoint supported batched updates, we could increase the batch size and post multiple updates to our API at once

## Usage

### Deployment

In order to deploy this, you will need to run the following command:

```bash
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

After successful deployment, you can invoke the deployed function by posting the below example payload to the deployed API Gateway endpoint URL:

```json
{
  "test": "hello!"
}
```

You should receive a response similar to the following:

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

### Teardown

You can remove all of the deployed infrastructure by running the following command:

```bash
$ serverless remove
```
