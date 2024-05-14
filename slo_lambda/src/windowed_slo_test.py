import os
import boto3
import json
from botocore.stub import Stubber, ANY
import pytest

os.environ["WINDOW_DAYS"] = "24"
SLI_NAMESPACE = "test/sli"
SLI_PREFIX = "test"
os.environ["SLIS"] = ""

# This import relies on our env var insertions above, so can't be reordered
# autopep8: off
from windowed_slo import parse_sli_json, publish_slis, Cloudwatch

# autopep8: on

LOAD_BALANCER_ID = "app/login-idp-alb-pretend/1234"


def get_metric_statistics(metric_name, datapoints_sum):
    return [
        "get_metric_statistics",
        {"Datapoints": [{"Sum": datapoints_sum}]},
        {
            "Dimensions": [
                {"Name": "LoadBalancer", "Value": "app/login-idp-alb-pretend/1234"}
            ],
            "EndTime": ANY,
            "MetricName": metric_name,
            "Namespace": "AWS/ApplicationELB",
            "Period": 2073600,
            "StartTime": ANY,
            "Statistics": ["Sum"],
        },
    ]


def put_metric_data(metric_name, value):
    return [
        "put_metric_data",
        {},
        {
            "MetricData": [{"MetricName": metric_name, "Value": value}],
            "Namespace": "test/sli",
        },
    ]


def test_simple_sli():
    cw = boto3.client("cloudwatch")
    with Stubber(cw) as stubber:
        stubber.add_response(*get_metric_statistics("HTTPCode_Target_2XX_Count", 2))
        stubber.add_response(*get_metric_statistics("RequestCount", 4))
        stubber.add_response(*get_metric_statistics("HTTPCode_ELB_5XX_Count", 2))
        stubber.add_response(*put_metric_data("test-http-200-availability", 1 / 3))

        Cloudwatch.cloudwatch_client = cw

        sli_config = {
            "http-200-availability": {
                "window_days": None,
                "numerator": [
                    {
                        "namespace": "AWS/ApplicationELB",
                        "metric_name": "HTTPCode_Target_2XX_Count",
                        "dimensions": [
                            {
                                "Name": "LoadBalancer",
                                "Value": LOAD_BALANCER_ID,
                            },
                        ],
                    },
                ],
                "denominator": [
                    {
                        "namespace": "AWS/ApplicationELB",
                        "metric_name": "RequestCount",
                        "dimensions": [
                            {
                                "Name": "LoadBalancer",
                                "Value": LOAD_BALANCER_ID,
                            },
                        ],
                    },
                    {
                        "namespace": "AWS/ApplicationELB",
                        "metric_name": "HTTPCode_ELB_5XX_Count",
                        "dimensions": [
                            {
                                "Name": "LoadBalancer",
                                "Value": LOAD_BALANCER_ID,
                            },
                        ],
                    },
                ],
            }
        }

        # The SLI config is assumed to be json, so convert the dict to json
        slis = parse_sli_json(json.dumps(sli_config), handle_exceptions=False)
        publish_slis(slis, SLI_NAMESPACE, SLI_PREFIX, handle_exceptions=False)


def test_multiple_metric_sli():
    cw = boto3.client("cloudwatch")

    with Stubber(cw) as stubber:
        stubber.add_response(*get_metric_statistics("HTTPCode_Target_2XX_Count", 2))
        stubber.add_response(*get_metric_statistics("HTTPCode_Target_3XX_Count", 1))
        stubber.add_response(*get_metric_statistics("HTTPCode_Target_4XX_Count", 1))
        stubber.add_response(*get_metric_statistics("RequestCount", 6))
        stubber.add_response(*get_metric_statistics("HTTPCode_ELB_5XX_Count", 2))
        stubber.add_response(*put_metric_data("test-all-availability", 0.5))

        Cloudwatch.cloudwatch_client = cw

        sli_config = {
            "all-availability": {
                "window_days": 24,
                "numerator": [
                    {
                        "namespace": "AWS/ApplicationELB",
                        "metric_name": "HTTPCode_Target_2XX_Count",
                        "dimensions": [
                            {
                                "Name": "LoadBalancer",
                                "Value": LOAD_BALANCER_ID,
                            },
                        ],
                    },
                    {
                        "namespace": "AWS/ApplicationELB",
                        "metric_name": "HTTPCode_Target_3XX_Count",
                        "dimensions": [
                            {
                                "Name": "LoadBalancer",
                                "Value": LOAD_BALANCER_ID,
                            },
                        ],
                    },
                    {
                        "namespace": "AWS/ApplicationELB",
                        "metric_name": "HTTPCode_Target_4XX_Count",
                        "dimensions": [
                            {
                                "Name": "LoadBalancer",
                                "Value": LOAD_BALANCER_ID,
                            },
                        ],
                    },
                ],
                "denominator": [
                    {
                        "namespace": "AWS/ApplicationELB",
                        "metric_name": "RequestCount",
                        "dimensions": [
                            {
                                "Name": "LoadBalancer",
                                "Value": LOAD_BALANCER_ID,
                            },
                        ],
                    },
                    {
                        "namespace": "AWS/ApplicationELB",
                        "metric_name": "HTTPCode_ELB_5XX_Count",
                        "dimensions": [
                            {
                                "Name": "LoadBalancer",
                                "Value": LOAD_BALANCER_ID,
                            },
                        ],
                    },
                ],
            }
        }
        # The SLI config is assumed to be json, so convert the dict to json
        slis = parse_sli_json(json.dumps(sli_config), handle_exceptions=False)
        publish_slis(slis, SLI_NAMESPACE, SLI_PREFIX, handle_exceptions=False)


def test_sad_config():
    # By default, blithely continue on
    with open(
        os.path.join(os.path.dirname(__file__), "windowed_slo_fixture_sad.json")
    ) as f:
        parse_sli_json(f.read())

    # But internally, know that the config is bad
    with pytest.raises(TypeError) as excinfo:

        with open(
            os.path.join(os.path.dirname(__file__), "windowed_slo_fixture_sad.json")
        ) as f:
            parse_sli_json(f.read(), handle_exceptions=False)

    assert "unexpected keyword argument 'nomnomnomerator'" in str(excinfo.value)


def test_happy_config():
    # Ensure we can actually parse
    with open(
        os.path.join(os.path.dirname(__file__), "windowed_slo_fixture_happy.json")
    ) as f:
        parse_sli_json(f.read(), handle_exceptions=False)
