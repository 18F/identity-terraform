import datetime
import os
import boto3
import json
from botocore.stub import Stubber, ANY

os.environ['WINDOW_DAYS'] = '24'
os.environ['SLI_NAMESPACE'] = 'test/sli'
os.environ['SLI_PREFIX'] = 'test'
os.environ['SLIS'] = ''

# This import relies on our env var insertions above, so can't be reordered
# autopep8: off
from windowed_slo import parse_sli_json, publish_slis, Cloudwatch, SLI_NAMESPACE, SLI_PREFIX
# autopep8: on

LOAD_BALANCER_ID = 'app/login-idp-alb-pretend/1234'


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
        stubber.add_response(
            *get_metric_statistics('HTTPCode_Target_2XX_Count', 2))
        stubber.add_response(
            *get_metric_statistics('RequestCount', 4))
        stubber.add_response(
            *get_metric_statistics('HTTPCode_ELB_5XX_Count', 2))
        stubber.add_response(
            *put_metric_data('test-http-200-availability', 1/3))
        
        Cloudwatch.cloudwatch_client = cw

        sli_config = {
            "http-200-availability": {
                'numerator': [
                    {
                        'namespace': 'AWS/ApplicationELB',
                        'metric_name': 'HTTPCode_Target_2XX_Count',
                        'dimensions': [
                            {
                                'Name': 'LoadBalancer',
                                'Value': LOAD_BALANCER_ID,
                            },
                        ],
                    },
                ],
                'denominator': [
                    {
                        'namespace': 'AWS/ApplicationELB',
                        'metric_name': 'RequestCount',
                        'dimensions': [
                            {
                                'Name': 'LoadBalancer',
                                'Value': LOAD_BALANCER_ID,
                            },
                        ],
                    },
                    {
                        'namespace': 'AWS/ApplicationELB',
                        'metric_name': 'HTTPCode_ELB_5XX_Count',
                        'dimensions': [
                            {
                                'Name': 'LoadBalancer',
                                'Value': LOAD_BALANCER_ID,
                            },
                        ],
                    },
                ]
            }
        }

        # The SLI config is assumed to be json, so convert the dict to json
        slis = parse_sli_json(json.dumps(sli_config))
        publish_slis(slis, SLI_NAMESPACE, SLI_PREFIX)


def test_multiple_metric_sli():
    cw = boto3.client('cloudwatch')

    with Stubber(cw) as stubber:
        stubber.add_response(
            *get_metric_statistics('HTTPCode_Target_2XX_Count', 2))
        stubber.add_response(
            *get_metric_statistics('HTTPCode_Target_3XX_Count', 1))
        stubber.add_response(
            *get_metric_statistics('HTTPCode_Target_4XX_Count', 1))
        stubber.add_response(
            *get_metric_statistics('RequestCount', 6))
        stubber.add_response(
            *get_metric_statistics('HTTPCode_ELB_5XX_Count', 2))
        stubber.add_response(
            *put_metric_data('test-all-availability', 0.5))

        Cloudwatch.cloudwatch_client = cw

        sli_config = {
            'all-availability': {
                'numerator': [
                    {
                        'namespace': 'AWS/ApplicationELB',
                        'metric_name': 'HTTPCode_Target_2XX_Count',
                        'dimensions': [
                            {
                                'Name': 'LoadBalancer',
                                'Value': LOAD_BALANCER_ID,
                            },
                        ],
                    },
                    {
                        'namespace': 'AWS/ApplicationELB',
                        'metric_name': 'HTTPCode_Target_3XX_Count',
                        'dimensions': [
                            {
                                'Name': 'LoadBalancer',
                                'Value': LOAD_BALANCER_ID,
                            },
                        ],
                    },
                    {
                        'namespace': 'AWS/ApplicationELB',
                        'metric_name': 'HTTPCode_Target_4XX_Count',
                        'dimensions': [
                            {
                                'Name': 'LoadBalancer',
                                'Value': LOAD_BALANCER_ID,
                            },
                        ],
                    },
                ],
                'denominator': [
                                    {
                        'namespace': 'AWS/ApplicationELB',
                        'metric_name': 'RequestCountRequestCount',
                        'dimensions': [
                            {
                                'Name': 'LoadBalancer',
                                'Value': LOAD_BALANCER_ID,
                            },
                        ],
                    },
                    {
                        'namespace': 'AWS/ApplicationELB',
                        'metric_name': 'HTTPCode_ELB_5XX_Count',
                        'dimensions': [
                            {
                                'Name': 'LoadBalancer',
                                'Value': LOAD_BALANCER_ID,
                            },
                        ],
                    },
                ]
            }
        }
        # The SLI config is assumed to be json, so convert the dict to json
        slis = parse_sli_json(json.dumps(sli_config))
        publish_slis(slis, SLI_NAMESPACE, SLI_PREFIX)
