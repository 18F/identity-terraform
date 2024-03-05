#!/usr/bin/python3.9
import boto3
import urllib3
import json
import os
import re
import datetime

ssm = boto3.client('ssm')
slackChannel = os.environ['slack_channel']
slackUsername = os.environ['slack_username']
slackIcon = os.environ['slack_icon']
slackAlarmEmoji = os.environ['slack_alarm_emoji']
slackOkEmoji = os.environ['slack_ok_emoji']
slackUrlParam = os.environ['slack_webhook_url_parameter']
parameter = ssm.get_parameter(Name=slackUrlParam, WithDecryption=True)
http = urllib3.PoolManager()

def lambda_handler(event, context):
    url = parameter['Parameter']['Value']
    eventmsg = event['Records'][0]['Sns']['Message']
    blocks = None
    try:
      data = json.loads(eventmsg)
      if 'detailType' in data and data['detailType'] == 'CodePipeline Pipeline Execution State Change':
        msgtext = 'auto-terraform:  ' + data['detail']['pipeline'] + ' pipeline ' + data['detail']['state'] + ' with execution ID ' + data['detail']['execution-id']
      elif 'AlarmName' in data and 'AlarmDescription' in data:
        if data['NewStateValue'] == 'ALARM':
          alertState = f'{slackAlarmEmoji} *ALARM:* '
        else:
          alertState = f'{slackOkEmoji} *OK:* '
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
          iso_time = datetime.fromisoformat(data["StateChangeTime"].replace("+0000", "+00:00"))
          formatted_time = iso_time.strftime("%Y-%m-%d %H:%M:%S %Z")
        except:
          formatted_time = data["StateChangeTime"]

        match = re.search(r'Runbook: (https://\S+)', data["AlarmDescription"])
        if match:
          runbook_url = match.group(1)

          blocks[0]["accessory"] = {
            "type": "button",
            "text": {
              "type": "plain_text",
              "text": "View Runbook :books:",
              "emoji": True
            },
            "value": "runbook-id",
            "url": runbook_url,
            "action_id": "button-action",
          }

          description_no_runbook = re.sub('Runbook: (https://\S+)\n', '', data["AlarmDescription"])
          blocks[0]["text"]["text"] += f'\n{description_no_runbook}'
        else:
          blocks.append({
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": data["AlarmDescription"],
            },
          })

        blocks.append({
          "type": "section",
          "text": {
            "type": "mrkdwn",
            "text": '\n'.join([
              data["NewStateReason"],
              f'*Time*: {formatted_time}',
              f'*Region*: {data["Region"]}'
            ]),
          }
        })

        msgtext = '\n'.join([
          f'{alertState} *{data["AlarmName"]}*',
          data["AlarmDescription"],
          data["NewStateReason"],
          f'*Time*: {formatted_time}',
          f'*Region*: {data["Region"]}'])
      elif 'detailType' in data and data['detailType'] == 'AWS Health Event':
          blocks = aws_health_event(data)
          msgtext = ''.join([
              '*AWS Health Event*\n',
              f'*{data["detail"]["service"]}*\n',
              f'Event Type: {data["detail"]["eventTypeCode"]}\n',
              f'Status: {data["detail"]["statusCode"]}\n',
              data["detail"]["eventDescription"]["latestDescription"],
              ])
      else:
        msgtext = eventmsg
    except Exception as e:
      msgtext = eventmsg
    msg = {
        "channel": slackChannel,
        "username": slackUsername,
        "text": msgtext,
        "icon_emoji": slackIcon,
    }
    if blocks:
      msg["blocks"] = blocks

    encoded_msg = json.dumps(msg).encode('utf-8')
    resp = http.request('POST',url, body=encoded_msg)
    print({
        "message": event['Records'][0]['Sns']['Message'],
        "status_code": resp.status,
        "response": resp.data
    })


def aws_health_event(json_message):
    try:
        details = json_message["detail"]
        blocks = [
                {
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": ''.join([
                            '*AWS Health Event*\n',
                            f'*{details["service"]}*\n',
                            f'Event Type: {details["eventTypeCode"]}\n',
                            f'Status: {details["statusCode"]}',
                            ])
                        },
                    },
                ]

        blocks.append({
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": details["eventArn"],
                },
            })

        blocks.append({
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": details["eventDescription"]["latestDescription"],
                },
            })

        if len(json_message["resources"]) > 0:
            affected_resources = "Affected Resources:\n"

            for resource in json_message["resources"]:
                affected_resources = f"{resource}\n"

            blocks.append({
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": affected_resources
                    },
                })

        blocks.append({
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": ''.join([
                    f"Account: {details['account']}\n",
                    f"Region: {details['eventRegion']}",
                    ])
                },
            })

        try:
            iso_time = datetime.fromisoformat(json_message["time"])
            formatted_time = iso_time.strftime("%Y-%m-%d %H:%M:%S %Z")
        except:
            formatted_time = json_message["time"]

        time_information = f"Notification Time: {formatted_time}"

        if 'startTime' in details:
            time_information += f"\nStart Time: {details['startTime']}"

        if 'endTime' in details:
            time_information += f"\nEnd Time: {details['endTime']}"

        if 'lastUpdatedTime' in details:
            time_information += f"\nLast Updated: {details['lastUpdatedTime']}"

        blocks.append({
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": time_information
                },
            })

        return blocks
    except:
        return None
