#!/usr/bin/python3.9
import boto3
import urllib3
import json
import os
import re
import datetime
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    eventmsg = event["Records"][0]["Sns"]["Message"]

    try:
        data = json.loads(eventmsg)

        if (
            "detail-type" in data
            and data["detail-type"] == "CodePipeline Pipeline Execution State Change"
        ):
            codebuild_message(event, data)
        elif "AlarmName" in data and "AlarmDescription" in data:
            cloudwatch_alarm_message(event, data)
        elif "detail-type" in data and data["detail-type"] == "AWS Health Event":
            aws_health_event_message(event, data)
        elif "IncidentManagerEvent" in data:
            aws_incident_manager_message(event, data)
        else:
            generic_slack_message(event, eventmsg)

    except Exception as e:
        generic_slack_message(event, eventmsg)


def notify_slack(
    event={}, msgtext="", blocks=None, slackChannel="", slackUsername="", slackIcon=""
):
    ssm = boto3.client("ssm")
    slackUrlParam = os.environ["slack_webhook_url_parameter"]
    url = ssm.get_parameter(Name=slackUrlParam, WithDecryption=True)["Parameter"][
        "Value"
    ]

    http = urllib3.PoolManager()

    msg = {
        "channel": slackChannel,
        "username": slackUsername,
        "text": msgtext,
        "icon_emoji": slackIcon,
    }

    if blocks:
        msg["blocks"] = blocks

    resp = http.request("POST", url, body=json.dumps(msg).encode("utf-8"))

    logger.info(
        {
            "message": event["Records"][0]["Sns"]["Message"],
            "status_code": resp.status,
            "response": resp.data,
        }
    )


def format_aws_health_event(json_message):
    try:
        details = json_message["detail"]
        blocks = [
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": "".join(
                        [
                            "*AWS Health Event*\n",
                            f'*{details["service"]}*\n',
                            f'Event Type: {details["eventTypeCode"]}\n',
                            f'Status: {details["statusCode"]}',
                        ]
                    ),
                },
            },
        ]

        blocks.append(
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": details["eventArn"],
                },
            }
        )

        blocks.append(
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": details["eventDescription"]["latestDescription"],
                },
            }
        )

        if len(json_message["resources"]) > 0:
            affected_resources = "Affected Resources:\n"

            for resource in json_message["resources"]:
                affected_resources = f"{resource}\n"

            blocks.append(
                {
                    "type": "section",
                    "text": {"type": "mrkdwn", "text": affected_resources},
                }
            )

        blocks.append(
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": "".join(
                        [
                            f"Account: {details['account']}\n",
                            f"Region: {details['eventRegion']}",
                        ]
                    ),
                },
            }
        )

        try:
            iso_time = datetime.fromisoformat(json_message["time"])
            formatted_time = iso_time.strftime("%Y-%m-%d %H:%M:%S %Z")
        except:
            formatted_time = json_message["time"]

        time_information = f"Notification Time: {formatted_time}"

        if "startTime" in details:
            time_information += f"\nStart Time: {details['startTime']}"

        if "endTime" in details:
            time_information += f"\nEnd Time: {details['endTime']}"

        if "lastUpdatedTime" in details:
            time_information += f"\nLast Updated: {details['lastUpdatedTime']}"

        blocks.append(
            {
                "type": "section",
                "text": {"type": "mrkdwn", "text": time_information},
            }
        )

        return blocks
    except:
        return None


def codebuild_message(event, data):
    msgtext = (
        "auto-terraform:  "
        + data["detail"]["pipeline"]
        + " pipeline "
        + data["detail"]["state"]
        + " with execution ID "
        + data["detail"]["execution-id"]
    )
    notify_slack(
        event=event,
        msgtext=msgtext,
        blocks=blocks,
        slackChannel=slackChannel,
        slackUsername=slackUsername,
        slackIcon=slackIcon,
    )


def cloudwatch_alarm_message(event, data):
    slackAlarmEmoji = os.environ["slack_alarm_emoji"]
    slackOkEmoji = os.environ["slack_ok_emoji"]

    if data["NewStateValue"] == "ALARM":
        alertState = f"{slackAlarmEmoji} *ALARM:* "
    else:
        alertState = f"{slackOkEmoji} *OK:* "

    blocks = [
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": f'{alertState} *{data["AlarmName"]}*',
            },
        },
    ]

    try:
        iso_time = datetime.fromisoformat(
            data["StateChangeTime"].replace("+0000", "+00:00")
        )
        formatted_time = iso_time.strftime("%Y-%m-%d %H:%M:%S %Z")
    except:
        formatted_time = data["StateChangeTime"]

    match = re.search(r"Runbook: (https://\S+)", data["AlarmDescription"])
    if match:
        runbook_url = match.group(1)

        blocks[0]["accessory"] = {
            "type": "button",
            "text": {
                "type": "plain_text",
                "text": "View Runbook :books:",
                "emoji": True,
            },
            "value": "runbook-id",
            "url": runbook_url,
            "action_id": "button-action",
        }

        description_no_runbook = re.sub(
            "Runbook: (https://\S+)\n", "", data["AlarmDescription"]
        )
        blocks[0]["text"]["text"] += f"\n{description_no_runbook}"
    else:
        blocks.append(
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": data["AlarmDescription"],
                },
            }
        )

    blocks.append(
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": "\n".join(
                    [
                        data["NewStateReason"],
                        f"*Time*: {formatted_time}",
                        f'*Region*: {data["Region"]}',
                    ]
                ),
            },
        }
    )

    msgtext = "\n".join(
        [
            f'{alertState} *{data["AlarmName"]}*',
            data["AlarmDescription"],
            data["NewStateReason"],
            f"*Time*: {formatted_time}",
            f'*Region*: {data["Region"]}',
        ]
    )

    notify_slack(
        event=event,
        msgtext=msgtext,
        blocks=blocks,
        slackChannel=slackChannel,
        slackUsername="AWS Cloudwatch Alarm",
        slackIcon=slackIcon,
    )


def aws_health_event_message(event, data):
    blocks = format_aws_health_event(data)
    msgtext = "".join(
        [
            "*AWS Health Event*\n",
            f'*{data["detail"]["service"]}*\n',
            f'Event Type: {data["detail"]["eventTypeCode"]}\n',
            f'Status: {data["detail"]["statusCode"]}\n',
            data["detail"]["eventDescription"]["latestDescription"],
        ]
    )

    notify_slack(
        event=event,
        msgtext=msgtext,
        blocks=blocks,
        slackChannel=slackChannel,
        slackUsername="AWS Health Event",
        slackIcon=":aws:",
    )


def generic_slack_message(event, eventmsg):
    msgtext = eventmsg
    notify_slack(
        event=event,
        msgtext=msgtext,
        blocks=blocks,
        slackChannel=slackChannel,
        slackUsername=slackUsername,
        slackIcon=slackIcon,
    )


def aws_incident_manager_message(event, data):
    blocks = []

    msgtext = "".join(
        [
            "*AWS Health Event*\n",
            f'*{data["detail"]["service"]}*\n',
            f'Event Type: {data["detail"]["eventTypeCode"]}\n',
            f'Status: {data["detail"]["statusCode"]}\n',
            data["detail"]["eventDescription"]["latestDescription"],
        ]
    )

    notify_slack(
        event=event,
        msgtext=msgtext,
        blocks=blocks,
        slackChannel=slackChannel,
        slackUsername="AWS Incident Manager",
        slackIcon=slackIcon,
    )
