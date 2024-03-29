# cloudwatch event rule to capture cloudtrail kms decryption events
# this filter will only capture events where the
# encryption context is set and has the values of
# password-digest or pii-encryption
resource "aws_cloudwatch_event_rule" "decrypt" {
  name        = "${var.env_name}-mr-decryption-events"
  description = "Capture decryption events"

  event_pattern = <<PATTERN
{
    "source": [
        "aws.kms"
    ],
    "detail-type": [
        "AWS API Call via CloudTrail"
    ],
    "detail": {
        "eventSource": [
            "kms.amazonaws.com"
        ],
        "requestParameters": {
            "encryptionContext": {
                "context": [
                    "password-digest",
                    "pii-encryption"
                ]
            }
        },
        "resources": {
            "ARN": [
                "${aws_kms_replica_key.login_dot_gov_keymaker_multi_region_replica.arn}"
            ]
        },
        "eventName": [
            "Decrypt"
        ]
    }
}
PATTERN

}

# https://docs.aws.amazon.com/kms/latest/developerguide/ct-replicate-key.html
resource "aws_cloudwatch_event_rule" "replicate" {
  name        = "${var.env_name}-mr-replicate-events"
  description = "Capture disallowed replicate events"

  event_pattern = <<PATTERN
{
    "eventName": ["ReplicateKey"],
    "eventSource": ["kms.amazonaws.com"],
    "requestParameters": {
        "keyId": [ "${aws_kms_replica_key.login_dot_gov_keymaker_multi_region_replica.key_id}" ],
        "replicaRegion": [
            {
                "anything-but": [
                    "us-west-2",
                    "us-east-1"
                ]
            }
        ] 
    }
}
PATTERN
}

# https://docs.aws.amazon.com/kms/latest/developerguide/ct-update-primary-region.html
resource "aws_cloudwatch_event_rule" "update_primary_region" {
  name        = "${var.env_name}-mr-update-primary-region-events"
  description = "Capture disallowed update primary region events"

  event_pattern = <<PATTERN
{
    "eventName": ["UpdatePrimaryRegion"],
    "eventSource": ["kms.amazonaws.com"],
    "requestParameters": {
        "keyId": [ "${aws_kms_replica_key.login_dot_gov_keymaker_multi_region_replica.key_id}" ],
        "replicaRegion": [
            {
                "anything-but": [
                    "us-west-2",
                    "us-east-1"
                ]
            }
        ] 
    }
}
PATTERN
}
