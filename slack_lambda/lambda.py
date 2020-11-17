#!/usr/bin/python3.6
import urllib3
import json
import os
slackChannel = os.environ['slack_channel']
slackUsername = os.environ['slack_username']
slackIcon = os.environ['slack_icon']
http = urllib3.PoolManager()
def lambda_handler(event, context):
    url = ""
    msg = {
        "channel": slackChannel,
        "username": slackUsername,
        "text": event['Records'][0]['Sns']['Message'],
        "icon_emoji": slackIcon
    }
        
    encoded_msg = json.dumps(msg).encode('utf-8')
    resp = http.request('POST',url, body=encoded_msg)
    print({
        "message": event['Records'][0]['Sns']['Message'], 
        "status_code": resp.status, 
        "response": resp.data
    })
