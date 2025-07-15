from aws_lambda_powertools import Logger
import base64
import gzip
import json
import os
import boto3
import traceback

logger = Logger()
ec2_client = boto3.client('ec2')
sns_client = boto3.client('sns')

sns_topic_arn  = os.getenv('SNS_TOPIC_ARN')

def lambda_handler(event, context):
    try: 
        data = base64.b64decode(event['awslogs']['data'])
        data_decomp = gzip.decompress(data).decode('utf-8')
        payload = json.loads(data_decomp)
        
        logStream = payload['logStream']    
        
        logger.info('Sending alarm: ')
        msgs = []
        for logEvent in payload['logEvents']:
            extractedFields = logEvent['extractedFields']
            ip = extractedFields['ip']
            mmdd = f"{extractedFields['mm']} {extractedFields['dd']}"
            hhmmss = extractedFields['time']
            text2  = extractedFields['text2']
            
            msgs.append(f"SSH detected in the instance {logStream} with ip {ip} at {mmdd} {hhmmss}: {text2}")

        sns_client.publish (
            TopicArn = sns_topic_arn,
            Subject = "SSH Access Detected",
            Message = "{}".format("\n".join(msgs))
        )
        
        logger.info('Terminating instance: '+ logStream)        
        response = ec2_client.stop_instances (InstanceIds=[logStream],Force=True)

        logger.info(response)
    except Exception as e:
        traceback.print_exc()

