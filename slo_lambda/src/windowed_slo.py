"""
Given CloudWatch metrics, writes new ones that aggregate over WINDOW_DAYS.
"""

from typing import List, Dict
import datetime
import json
import os
import boto3


# Env variables are typically set by Terraform
WINDOW_DAYS = int(os.environ['WINDOW_DAYS'])
SLI_NAMESPACE = os.environ['SLI_NAMESPACE']
SLI_PREFIX = os.environ['SLI_PREFIX']
SLIS = os.environ['SLIS']


def load_balancer_id(arn: str) -> str:
    return "/".join(arn.split("/")[-3:])


class Cloudwatch:
    cloudwatch_client = None

    @classmethod
    def client(cls):
        if cls.cloudwatch_client is None:
            cls.cloudwatch_client = boto3.client('cloudwatch')
        return cls.cloudwatch_client


class MetricBase:
    """
    This base class exists to record the subclass names,
    so we can reference them in our config.
    """

    metric_types = {}

    def __init_subclass__(cls):
        super().__init_subclass__()
        cls.metric_types[cls.__name__] = cls


class SingleMetric(MetricBase):
    """
    Holds what we need to query a CloudWatch metric.
    """

    def __init__(self, namespace: str, metric_name: str, dimensions: List):
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

    def sum(self) -> float:
        total = 0
        for datapoint in Cloudwatch.client().get_metric_statistics(
                Namespace=self.namespace,
                MetricName=self.metric_name,
                Dimensions=self.dimensions,
                **self.stat_args,
        )['Datapoints']:
            total += datapoint['Sum']
        return total


class LBValidRequestMetric(MetricBase):
    """
    Metric that encompasses all valid requests to the LB, including those that
    return before selecting a target group. Excludes 4XX reponses originiating
    from the LB.
    """

    def __init__(self, load_balancer_arn: str):
        self.lb_name = load_balancer_id(load_balancer_arn)

    def sum(self) -> float:
        self.request_count = SingleMetric(
            namespace='AWS/ApplicationELB',
            metric_name='RequestCount',
            dimensions=[
                {
                    'Name': 'LoadBalancer',
                    'Value': self.lb_name,
                }
            ]
        )

        self.elb_500s = SingleMetric(
            namespace='AWS/ApplicationELB',
            metric_name='HTTPCode_ELB_5XX_Count',
            dimensions=[
                {
                    'Name': 'LoadBalancer',
                    'Value': self.lb_name,
                }
            ]
        )
        return self.request_count.sum() + self.elb_500s.sum()


class LBGoodResponseMetric(MetricBase):
    """
    Metric that encompasses all good reponses from the target group. Excludes
    5XX responses and timeouts.
    """

    def __init__(self, load_balancer_arn: str):
        self.lb_name = load_balancer_id(load_balancer_arn)

    def sum(self) -> float:
        responses = [
            SingleMetric(
                namespace='AWS/ApplicationELB',
                metric_name='HTTPCode_Target_2XX_Count',
                dimensions=[
                    {
                            'Name': 'LoadBalancer',
                            'Value': self.lb_name,
                    }
                ]
            ),
            SingleMetric(
                namespace='AWS/ApplicationELB',
                metric_name='HTTPCode_Target_3XX_Count',
                dimensions=[
                    {
                        'Name': 'LoadBalancer',
                        'Value': self.lb_name,
                    }
                ]
            ),
            SingleMetric(
                namespace='AWS/ApplicationELB',
                metric_name='HTTPCode_Target_4XX_Count',
                dimensions=[
                    {
                        'Name': 'LoadBalancer',
                        'Value': self.lb_name,
                    }
                ]
            ),
        ]
        return sum([x.sum() for x in responses])


class SLIBase:
    """
    This base class exists to record the subclasss names,
    so we can reference them in our config.
    """

    sli_types = {}

    def __init_subclass__(cls):
        super().__init_subclass__()
        cls.sli_types[cls.__name__] = cls


class AvailabilitySLI(SLIBase):
    """
    N.B. numerator and denominator are assumed to be Dicts, not Metrics
    """

    def __init__(self, numerator: Dict, denominator: Dict):
        num_args = {k: v for (k, v) in numerator.items() if k != "type"}
        num = MetricBase.metric_types[numerator['type']](**num_args)
        self.num = num

        denom_args = {k: v for (k, v) in denominator.items() if k != "type"}
        denom = MetricBase.metric_types[denominator['type']](**denom_args)
        self.denom = denom

    def get_ratio(self) -> float:
        """
        Can return ZeroDivisonError. Make sure to catch it.
        """
        numerator = self.num.sum()
        denominator = self.denom.sum()

        return numerator / denominator


def create_slis(slis: Dict[str, Dict]):
    # Write Cloudwatch
    for sli_name, sli in slis.items():
        try:
            value = sli.get_ratio()
        except ZeroDivisionError:
            print("x/0 error for %s" % sli_name)
            continue
        print("%s: %f" % (sli_name, value))
        metric_data = [
            {
                'MetricName': SLI_PREFIX + "-" + sli_name,
                'Value': value,
            }
        ]
        Cloudwatch.client().put_metric_data(
            Namespace=SLI_NAMESPACE,
            MetricData=metric_data,
        )


def parse_sli_json(sli_json: str) -> Dict[str, SLIBase]:
    sli_configs = json.loads(sli_json)
    slis = {}
    for sli_name, sli_config in sli_configs.items():
        # Use everything but "type" as init arguments
        sli_args = {k: v for (k, v) in sli_config.items() if k != "type"}
        sli = SLIBase.sli_types[sli_config['type']](**sli_args)
        slis[sli_name] = sli
    return slis


def lambda_handler(event, context):
    # Parse SLIs
    slis = parse_sli_json(SLIS)
    create_slis(slis)


def main():
    lambda_handler(None, None)


if __name__ == '__main__':
    main()
