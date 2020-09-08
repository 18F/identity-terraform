#!/usr/bin/python3.6
import urllib3
import json
http = urllib3.PoolManager()
def lambda_handler(event, context):
    url = "${slack_webhook_url}"
    msg = {
        "channel": "#${slack_channel}",
        "username": "${slack_username}",
        "text": event['Records'][0]['Sns']['Message'],
        "icon_emoji": "${slack_icon}"
    }
    
    encoded_msg = json.dumps(msg).encode('utf-8')
    resp = http.request('POST',url, body=encoded_msg)
    print({
        "message": event['Records'][0]['Sns']['Message'], 
        "status_code": resp.status, 
        "response": resp.data
    })