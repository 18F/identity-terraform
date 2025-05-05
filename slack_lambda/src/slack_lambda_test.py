import boto3
import logging
import os
import pytest
import json
import unittest
import urllib3
from moto import mock_aws
from unittest.mock import patch, MagicMock
from slack_lambda import (
    lambda_handler,
    SlackNotificationFormatter,
    send_slack_notification,
    get_slack_message_payload,
)


@unittest.mock.patch.dict(
    os.environ,
    {
        "slack_webhook_url_parameter": "/slackurl/param",
        "slack_channel": "#login-otherevents",
        "slack_username": "SNSToSlack Notifier",
        "slack_icon": ":login-dot-gov:",
        "slack_alarm_emoji": "",
        "slack_ok_emoji": "",
    },
    clear=True,
)
class SlackNotificationsTest(unittest.TestCase):

    def test_compose_payload(self):
        payload = SlackNotificationFormatter(
            event={"Records": [{"Sns": {"Message": "pytest message"}}]},
            default_slack_username=os.environ["slack_username"],
            default_slack_icon=os.environ["slack_icon"],
            slack_channel=os.environ["slack_channel"],
        ).compose_payload(text="TEST", blocks=["a", "b", "c"])

        self.assertEqual(payload["channel"], os.environ["slack_channel"])
        self.assertEqual(payload["username"], os.environ["slack_username"])
        self.assertEqual(payload["text"], "TEST")
        self.assertEqual(payload["blocks"], ["a", "b", "c"])
        self.assertEqual(payload["icon_emoji"], os.environ["slack_icon"])

    def test_format_codepipeline_message(self):
        event = self.load_file("codepipeline_message")
        payload = SlackNotificationFormatter(
            event=event,
            default_slack_username=os.environ["slack_username"],
            default_slack_icon=os.environ["slack_icon"],
            slack_channel=os.environ["slack_channel"],
        ).format_codepipeline_message(
            json.loads(event["Records"][0]["Sns"]["Message"]),
            slack_username="AWS CodePipeline",
        )
        self.assertEqual(payload["channel"], os.environ["slack_channel"])
        self.assertEqual(payload["username"], "AWS CodePipeline")
        self.assertIn("Execution ID", payload["text"])
        self.assertIn("56bd28bc-37af-4c7b-bc69-6ef89a2d59f4", payload["text"])
        self.assertEqual(payload["icon_emoji"], os.environ["slack_icon"])

    def test_format_cloudwatch_alarm_message(self):
        event = self.load_file("cloudwatch_alarm_message")
        payload = SlackNotificationFormatter(
            event=event,
            default_slack_username=os.environ["slack_username"],
            default_slack_icon=os.environ["slack_icon"],
            slack_channel=os.environ["slack_channel"],
        ).format_cloudwatch_alarm_message(
            json.loads(event["Records"][0]["Sns"]["Message"]),
            slack_username="AWS Cloudwatch Alarm",
            slack_icon=":aws:",
        )
        self.assertEqual(payload["channel"], os.environ["slack_channel"])
        self.assertEqual(payload["username"], "AWS Cloudwatch Alarm")
        self.assertIn("test-idp-unhealthy-instances", payload["text"])
        self.assertEqual(payload["icon_emoji"], ":aws:")

    def test_format_generic_slack_message(self):
        event = self.load_file("generic_message")
        eventmsg = event["Records"][0]["Sns"]["Message"]
        payload = SlackNotificationFormatter(
            event=event,
            default_slack_username=os.environ["slack_username"],
            default_slack_icon=os.environ["slack_icon"],
            slack_channel=os.environ["slack_channel"],
        ).format_generic_slack_message(
            eventmsg,
        )
        self.assertEqual(payload["channel"], os.environ["slack_channel"])
        self.assertEqual(payload["username"], os.environ["slack_username"])
        self.assertEqual(payload["text"], "This is a generic text message")
        self.assertEqual(payload["icon_emoji"], os.environ["slack_icon"])

    def test_format_aws_incident_manager_shift_message(self):

        event = self.load_file("aws_incident_manager_shift_message")
        payload = SlackNotificationFormatter(
            event=event,
            default_slack_username=os.environ["slack_username"],
            default_slack_icon=os.environ["slack_icon"],
            slack_channel=os.environ["slack_channel"],
        ).format_aws_incident_manager_message(
            json.loads(event["Records"][0]["Sns"]["Message"]),
            slack_username="AWS Incident Manager",
        )
        self.assertEqual(payload["channel"], os.environ["slack_channel"])
        self.assertEqual(payload["username"], "AWS Incident Manager")
        self.assertEqual(
            payload["text"],
            "*ON-CALL CHANGE:* j_doe is OFF for the Platform Primary rotation",
        )
        self.assertEqual(payload["icon_emoji"], os.environ["slack_icon"])

    def load_file(self, filename):
        with open(os.path.join(os.path.dirname(__file__), f"{filename}.json")) as f:
            return json.loads(f.read())
