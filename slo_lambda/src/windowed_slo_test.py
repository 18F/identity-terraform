import datetime
import os
import boto3
import pytest
from botocore.stub import Stubber, ANY

os.environ['WINDOW_DAYS'] = '24'
os.environ['SLI_NAMESPACE'] = 'test/sli'
os.environ['LOAD_BALANCER_ARN'] = 'arn:aws:elasticloadbalancing:us-west-2:123:loadbalancer/app/login-idp-alb-pretend/1234'
os.environ['SLI_PREFIX'] = 'test'

from windowed_slo import create_slis, SLI, METRICS

def get_metric_statistics(metric_name, datapoints_sum):
    return [
        'get_metric_statistics',
        {
            'Datapoints': [
                {'Sum': datapoints_sum}
            ]
        },
        {
            'Dimensions': [{'Name': 'LoadBalancer',
                            'Value': 'app/login-idp-alb-pretend/1234'}],
            'EndTime': ANY,
            'MetricName': metric_name,
            'Namespace': 'AWS/ApplicationELB',
            'Period': 2073600,
            'StartTime': ANY,
            'Statistics': ['Sum']
        },
    ]

def put_metric_data(metric_name, value):
    return [
        'put_metric_data',
        {},
        {
            'MetricData': [{'MetricName': metric_name,
                            'Value': value}],
            'Namespace': 'test/sli'
        },
    ]

def test_simple_sli():
    cw = boto3.client('cloudwatch')
    with Stubber(cw) as stubber:
        stubber.add_response(*get_metric_statistics('HTTPCode_Target_2XX_Count', 2))
        stubber.add_response(*get_metric_statistics('RequestCount', 4))
        stubber.add_response(*get_metric_statistics('HTTPCode_ELB_5XX_Count', 2))
        stubber.add_response(*put_metric_data('test-http-200-availability', 1/3))
        slis = {
            'http_200_availability': SLI(
                "http-200-availability",
                METRICS['target_200s'],
                METRICS['total_requests'],
            ),
        }
        create_slis(cw, slis)

def test_multiple_metric_sli():
    cw = boto3.client('cloudwatch')
    with Stubber(cw) as stubber:
        stubber.add_response(*get_metric_statistics('RequestCount', 4))
        stubber.add_response(*get_metric_statistics('HTTPCode_ELB_5XX_Count', 2))
        stubber.add_response(*get_metric_statistics('HTTPCode_Target_5XX_Count', 1))
        stubber.add_response(*get_metric_statistics('RequestCount', 4))
        stubber.add_response(*get_metric_statistics('HTTPCode_ELB_5XX_Count', 2))
        stubber.add_response(*put_metric_data('test-all-availability', 0.5))
        slis = {
            'all_availability': SLI(
                "all-availability",
                METRICS['backend_success'],
                METRICS['total_requests'],
            ),
        }
        create_slis(cw, slis)
