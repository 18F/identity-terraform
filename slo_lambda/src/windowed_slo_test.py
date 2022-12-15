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
from windowed_slo import parse_sli_json, create_slis, Cloudwatch, load_balancer_id
# autopep8: on

LOAD_BALANCER_ARN = 'arn:aws:elasticloadbalancing:us-west-2:123:loadbalancer/app/login-idp-alb-pretend/1234'


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
        stubber.add_response(*get_metric_statistics('RequestCount', 4))
        stubber.add_response(
            *get_metric_statistics('HTTPCode_ELB_5XX_Count', 2))
        stubber.add_response(
            *put_metric_data('test-http-200-availability', 1/3))
        Cloudwatch.cloudwatch_client = cw

        sli_config = {
            "http-200-availability": {
                'type': 'AvailabilitySLI',
                'numerator': {
                    'type': 'SingleMetric',
                    'namespace': 'AWS/ApplicationELB',
                    'metric_name': 'HTTPCode_Target_2XX_Count',
                    'dimensions': [
                        {
                            'Name': 'LoadBalancer',
                            'Value': load_balancer_id(LOAD_BALANCER_ARN),
                        },
                    ],
                },
                'denominator': {
                    'type':  "LBValidRequestMetric",
                    'load_balancer_arn': LOAD_BALANCER_ARN,
                },
            }
        }

        # The SLI config is assumed to be json, so convert the dict to json
        slis = parse_sli_json(json.dumps(sli_config))
        create_slis(slis)


def test_multiple_metric_sli():
    cw = boto3.client('cloudwatch')

    with Stubber(cw) as stubber:
        stubber.add_response(
            *get_metric_statistics('HTTPCode_Target_2XX_Count', 2))
        stubber.add_response(
            *get_metric_statistics('HTTPCode_Target_3XX_Count', 1))
        stubber.add_response(
            *get_metric_statistics('HTTPCode_Target_4XX_Count', 1))

        stubber.add_response(*get_metric_statistics('RequestCount', 6))
        stubber.add_response(
            *get_metric_statistics('HTTPCode_ELB_5XX_Count', 2))
        stubber.add_response(*put_metric_data('test-all-availability', 0.5))

        Cloudwatch.cloudwatch_client = cw

        sli_config = {
            'all-availability': {
                'type': 'AvailabilitySLI',
                'numerator': {
                    'type':  "LBGoodResponseMetric",
                    'load_balancer_arn': LOAD_BALANCER_ARN,
                },
                'denominator': {
                    'type':  "LBValidRequestMetric",
                    'load_balancer_arn': LOAD_BALANCER_ARN,
                },
            }
        }
        # The SLI config is assumed to be json, so convert the dict to json
        slis = parse_sli_json(json.dumps(sli_config))
        create_slis(slis)
