import json
import boto3
import urllib.request
import os

ssm = boto3.client('ssm')

def get_discord_webhook():
    response = ssm.get_parameter(
        Name='/otelapp/discord_webhook_url',
        WithDecryption=True
    )
    return response['Parameter']['Value']


def lambda_handler(event, context):
    DISCORD_WEBHOOK_URL = get_discord_webhook()
    for record in event['Records']:
        sns_message = record['Sns']['Message']
        subject = record['Sns'].get('Subject', 'Alert')
        
        try: 
            alarm_message = json.loads(record['Sns']['Message'])
            discord_payload = {
                "embeds": [
                    {
                        "title": f"Alarm: {alarm_message['AlarmName']}",
                        "color": 16711680 if alarm_message['NewStateValue'] == "ALARM" else 3066993,
                        "fields": [
                            {
                                "name": "Description",
                                "value": alarm_message['AlarmDescription'],
                                "inline": False
                            },
                            {
                                "name": "State",
                                "value": alarm_message['NewStateValue'],
                                "inline": True
                            },
                            {
                                "name": "Reason",
                                "value": alarm_message['NewStateReason'],
                                "inline": False
                            },
                            {
                                "name": "Metric",
                                "value": alarm_message['Trigger']['MetricName'],
                                "inline": True
                            },
                            {
                                "name": "Namespace",
                                "value": alarm_message['Trigger']['Namespace'],
                                "inline": True
                            },
                            {
                                "name": "Time",
                                "value": alarm_message['StateChangeTime'],
                                "inline": False
                            }
                        ],
                        "footer": {
                            "text": "CloudWatch Alarm Notification"
                        }
                    }
                ]
            }
        
        except Exception as e:
            discord_payload = {
                "embeds": [
                    {
                        "title": subject,
                        "description": sns_message,
                        "color": 16711680
                    }
                ]
            }

        data = json.dumps(discord_payload).encode('utf-8')

        req = urllib.request.Request(DISCORD_WEBHOOK_URL, data=data, headers={
            'Content-Type': 'application/json',
            'User-Agent': 'Mozilla/5.0 (compatible; LambdaBot/1.0; +https://aws.amazon.com/lambda/)'
        })
        
        try:
            with urllib.request.urlopen(req) as response:
                response.read()
            print("Alert sent to Discord")
        except Exception as e:
            print("Failed to send alert:", e)

    return {"statusCode": 200, "body": "Messages processed"}
