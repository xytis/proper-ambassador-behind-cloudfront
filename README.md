# Important!

After deploying the security group update lambda, you have to manually execute it at least once:

Use test with the following data:

```json
{
  "Records": [
    {
      "EventVersion": "1.0",
      "EventSubscriptionArn": "arn:aws:sns:EXAMPLE",
      "EventSource": "aws:sns",
      "Sns": {
        "SignatureVersion": "1",
        "Timestamp": "1970-01-01T00:00:00.000Z",
        "Signature": "EXAMPLE",
        "SigningCertUrl": "EXAMPLE",
        "MessageId": "95df01b4-ee98-5cb9-9903-4c221d41eb5e",
        "Message": "{\"create-time\": \"yyyy-mm-ddThh:mm:ss+00:00\", \"synctoken\": \"0123456789\", \"md5\": \"7fd59f5c7f5cf643036cbd4443ad3e4b\", \"url\": \"https://ip-ranges.amazonaws.com/ip-ranges.json\"}",
        "Type": "Notification",
        "UnsubscribeUrl": "EXAMPLE",
        "TopicArn": "arn:aws:sns:EXAMPLE",
        "Subject": "TestInvoke"
      }
    }
  ]
}
```

First test will most probably fail, with error that say:

```
Updating from https://ip-ranges.amazonaws.com/ip-ranges.json
MD5 Mismatch: got 2e967e943cf98ae998efeec05d4f351c expected 7fd59f5c7f5cf643036cbd4443ad3e4b: Exception
Traceback (most recent call last):
  File "/var/task/lambda_function.py", line 29, in lambda_handler
    ip_ranges = json.loads(get_ip_groups_json(message['url'], message['md5']))
  File "/var/task/lambda_function.py", line 50, in get_ip_groups_json
    raise Exception('MD5 Missmatch: got ' + hash + ' expected ' + expected_hash)
Exception: MD5 Mismatch: got 2e967e943cf98ae998efeec05d4f351c expected 7fd59f5c7f5cf643036cbd4443ad3e4b
```

Take the received MD5 and place it in Message field. Then repeat the test.

Successful test will create several security groups and bind them to EKS nodes.
