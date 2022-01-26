require "json"
require "aws-sdk-sqs"
require "httparty"

# Hard coded queue URL - could be configured via Serverless in a real world example:
QUEUE_URL = "https://sqs.us-east-1.amazonaws.com/109917559150/webhook-test-2-dev-webhookQueue"
# Replace this URL with an endpoint that you own that that can receive and log POST requests:
REQUEST_BIN_URL = "https://enmw2ww7ngty8tf.m.pipedream.net/"

# Proof of concept SQS throttling solution for inbound webhooks
# This consists of:
# * API Gateway endpoint that triggers a Lambda function
#   * This Lambda pushes the webhook payload into SQS unaltered (so we capture the
#     data before introducing any chance of parsing errors occurring) - we could push
#     the entire API Gateway event, or include the headers for HMAC verification, etc
#   * It should be possible to handle the HMAC auth within the API Gateway config too
#   * In theory this intermediary Lambda function is not really required; AWS supports
#     API Gateway pushing events directly into SQS, but it was tricky to get this
#     working via Serverless
# * An SQS queue for webhook payloads
# * A Lambda function that receives SQS events (batch size 1), parses the event body,
#   and posts it to an API endpoint
#   * This Lambda has a max concurrency of 1, which enables this method of throttling
#     inbound API requests
#   * If our internal API endpoint could handle batched updates, we could also
#     increase the batch size here and post multiple updates to our API at once

def process_webhook_request(event:, context:)
  puts "Processing webhook request: #{event["body"]}"

  client = Aws::SQS::Client.new

  client.send_message(
    queue_url: QUEUE_URL,
    message_body: event["body"].to_json
  )

  {
    statusCode: 200,
    body: {
      message: 'Pushed into SQS!',
      input: event["body"]
    }.to_json
  }
end

def process_queue_event(event:, context:)
  puts "Received event from queue: #{event}"

  if event["Records"].count.zero?
    puts "Zero records received - exiting"
    return
  end

  puts "Processing #{event["Records"].count} events"

  event["Records"].each do |record|
    puts "Processing record: #{record}"
    parsed_body = JSON.parse(record["body"])

    parsed_test_value = parsed_body["test"]

    params = {
      original_event: record["body"]
      parsed_body: parsed_body,
      parsed_test_value: parsed_test_value,
    }

    response = HTTParty.post(
      REQUEST_BIN_URL,
      body: params,
      headers: { "Content-Type" => "application/json" }
    )

    puts "Posted event: #{params}"
    puts "Response code: #{response.code}"

    # Artificially slow down processing so we can verify that
    # queue-based throttling is working by just looking at the log timestamps
    sleep(2)
  end

  puts "Done!"
end
