"""
Given CloudWatch metrics, writes new ones that aggregate over WINDOW_DAYS.
"""

import datetime
import os
import boto3


WINDOW_DAYS = int(os.environ['WINDOW_DAYS'])
SLI_NAMESPACE = os.environ['SLI_NAMESPACE']
LOAD_BALANCER_ID = "/".join(os.environ['LOAD_BALANCER_ARN'].split("/")[-3:])
SLI_PREFIX = os.environ['SLI_PREFIX']


class Metric:
    """
    Holds what we need to query a CloudWatch metric.
    """
    def __init__(self, namespace: str, metric_name: str, dimensions: list):
        self.namespace = namespace
        self.metric_name = metric_name
        self.dimensions = dimensions
        self.stat_args = {
            'StartTime': datetime.datetime.utcnow() - datetime.timedelta(days=WINDOW_DAYS),
            'EndTime': datetime.datetime.utcnow(),
            'Period': WINDOW_DAYS * 24 * 60 * 60,
            'Statistics' :[
                'Sum',
            ],
        }

    def sum(self, client) -> float:
        total = 0
        for datapoint in client.get_metric_statistics(
                Namespace=self.namespace,
                MetricName=self.metric_name,
                Dimensions=self.dimensions,
                **self.stat_args,
        )['Datapoints']:
            total += datapoint['Sum']
        return total


class BackendSuccessMetric:
    """
    Metric that combines a few others 
    """
    def __init__(self):
        pass

    def sum(self, client) -> float:
        request_count = METRICS['request_count'].sum(client)
        elb_500s = METRICS['elb_500s'].sum(client)
        target_500s = METRICS['target_500s'].sum(client)

        return request_count - elb_500s - target_500s


class SLI:
    def __init__(self, name: str, num: Metric, denom: Metric):
        self.name = name
        self.num = num
        self.denom = denom

    def get_ratio(self, client) -> float:
        """
        Can return ZeroDivisonError. Make sure to catch it.
        """
        numerator = self.num.sum(client)
        denominator = self.denom.sum(client)

        return numerator / denominator


METRICS = {
    'target_500s': Metric(
        namespace='AWS/ApplicationELB',
        metric_name='HTTPCode_Target_5XX_Count',
        dimensions=[
            {
                'Name': 'LoadBalancer',
                'Value': LOAD_BALANCER_ID,
            }
        ]
    ),
    'elb_500s': Metric(
        namespace='AWS/ApplicationELB',
        metric_name='HTTPCode_ELB_5XX_Count',
        dimensions=[
            {
                'Name': 'LoadBalancer',
                'Value': LOAD_BALANCER_ID,
            }
        ]
    ),
    'request_count': Metric(
        namespace='AWS/ApplicationELB',
        metric_name='RequestCount',
        dimensions=[
            {
                'Name': 'LoadBalancer',
                'Value': LOAD_BALANCER_ID,
            }
        ]
    ),
    'target_200s': Metric(
        namespace='AWS/ApplicationELB',
        metric_name='HTTPCode_Target_2XX_Count',
        dimensions=[
            {
                'Name': 'LoadBalancer',
                'Value': LOAD_BALANCER_ID,
            }
        ]
    ),
    'backend_success': BackendSuccessMetric(),

}


SLIS = {
    'http_200_availability': SLI(
        "http-200-availability",
        METRICS['target_200s'],
        METRICS['request_count'],
    ),
    'all_availability': SLI(
        "all-availability",
        METRICS['backend_success'],
        METRICS['request_count'],
    ),
}

def create_slis(client, slis):
    # Write Cloudwatch
    for sli in slis.values():
        try:
            value = sli.get_ratio(client)
        except ZeroDivisionError:
            return
        print(value)
        metric_data = [
            {
                'MetricName': SLI_PREFIX + "-" + sli.name,
                'Value': value,
            }
        ]
        client.put_metric_data(
            Namespace=SLI_NAMESPACE,
            MetricData=metric_data,
        )

def lambda_handler(event, context):
    # Query Cloudwatch
    client = boto3.client('cloudwatch')
    create_slis(client, SLIS)

def main():
    lambda_handler(None, None)


if __name__ == '__main__':
    main()
