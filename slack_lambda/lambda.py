#!/usr/bin/python3.6
import urllib3
import json
http = urllib3.PoolManager()
def lambda_handler(event, context):
    url = "${slack_webhook_url}"
    eventmsg = event['Records'][0]['Sns']['Message']
    try:
      data = json.loads(eventmsg)
      if data['detailType'] == 'CodePipeline Pipeline Execution State Change':
        msgtext = 'auto-terraform:  ' + data['detail']['pipeline'] + ' pipeline ' + data['detail']['state'] + ' with execution ID ' + data['detail']['execution-id']
    except:
      msgtext = eventmsg
    msg = {
        "channel": "#${slack_channel}",
        "username": "${slack_username}",
        "text": msgtext,
        "icon_emoji": "${slack_icon}"
    }
    
    encoded_msg = json.dumps(msg).encode('utf-8')
    resp = http.request('POST',url, body=encoded_msg)
    print({
        "message": event['Records'][0]['Sns']['Message'], 
        "status_code": resp.status, 
        "response": resp.data
    })