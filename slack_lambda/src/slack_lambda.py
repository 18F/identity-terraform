#!/usr/bin/python3.8
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
        blocks = [
          {
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": f'*Alarm has gone off!*\n*{data["AlarmName"]}*',
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

          description_no_runbook = data["AlarmDescription"].split('Runbook:')[0]
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
          '*Alarm has gone off!*',
          f'*{data["AlarmName"]}*',
          data["AlarmDescription"],
          data["NewStateReason"],
          f'*Time*: {formatted_time}',
          f'*Region*: {data["Region"]}'])
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