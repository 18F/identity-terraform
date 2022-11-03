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
            'Statistics': [
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

    def sum(self, client) -> float:
        request_count = METRICS['request_count'].sum(client)
        elb_500s = METRICS['elb_500s'].sum(client)
        target_500s = METRICS['target_500s'].sum(client)

        return request_count - target_500s


class ValidRequests:
    """
    Metric that encompasses all valid requests to the LB, including those that
    return before selecting a target group. Excludes 4XX reponses originiating
    from the LB.
    """

    def sum(self, client) -> float:
        request_count = METRICS['request_count'].sum(client)
        elb_500s = METRICS['elb_500s'].sum(client)

        return request_count + elb_500s


class GoodResponses:
    """
    Metric that encompasses all good reponses from the target group. Excludes
    5XX responses and timeouts.
    """

    def sum(self, client) -> float:
        responses = [
            METRICS['target_200s'],
            METRICS['target_300s'],
            METRICS['target_400s'],
        ]
        return sum([x.sum(client) for x in responses])


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
    'valid_requests': ValidRequests(),
    'good_responses': GoodResponses(),
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
    'target_300s': Metric(
        namespace='AWS/ApplicationELB',
        metric_name='HTTPCode_Target_3XX_Count',
        dimensions=[
            {
                'Name': 'LoadBalancer',
                'Value': LOAD_BALANCER_ID,
            }
        ]
    ),
    'target_400s': Metric(
        namespace='AWS/ApplicationELB',
        metric_name='HTTPCode_Target_4XX_Count',
        dimensions=[
            {
                'Name': 'LoadBalancer',
                'Value': LOAD_BALANCER_ID,
            }
        ]
    ),
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
    'backend_success': BackendSuccessMetric(),
    'filtered_uris_success': Metric(
        namespace=SLI_NAMESPACE,
        metric_name='FilteredUrisSuccess',
        dimensions=[],
    ),
    'filtered_uris_total': Metric(
        namespace=SLI_NAMESPACE,
        metric_name='FilteredUrisTotal',
        dimensions=[],
    ),
}


SLIS = {
    'all_availability': SLI(
        "all-availability",
        METRICS['good_responses'],
        METRICS['valid_requests'],
    ),
    'filtered_availability': SLI(
        'filtered-availability',
        METRICS['filtered_uris_success'],
        METRICS['filtered_uris_total'],
    )
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
