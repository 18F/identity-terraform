#!/usr/bin/env python3
import boto3
import botocore
import json
import os
import re
import urllib3
from typing import Any

REQUIRED_ENVARS = [
    "SNOW_ASSIGNMENT_GROUP",
    "SNOW_INCIDENT_URL",
    "SNOW_CATEGORY",
    "SNOW_SUBCATEGORY",
    "SNOW_PARAMETER_BASE",
]


def get_env_settings() -> dict:
    missing = [i for i in REQUIRED_ENVARS if os.environ.get(i) is None]
    if missing:
        raise ValueError(f"Missing required environment variables: {missing}")

    settings = {
        "url": os.environ["SNOW_INCIDENT_URL"],
        "default_body": {
            "assignment_group": os.environ["SNOW_ASSIGNMENT_GROUP"],
            "category": os.environ["SNOW_CATEGORY"],
            "subcategory": os.environ["SNOW_SUBCATEGORY"],
            "item": "Issue"
        },
        "parameter_base": os.environ["SNOW_PARAMETER_BASE"],
    }

    return settings


def get_auth(parameter_base, auth_type="basic") -> Any:
    # Allow username and password as environment variables for testing,
    # but default to using SSM
    if "SNOW_USERNAME" in os.environ and "SNOW_PASSWORD" in os.environ:
        return (os.environ["SNOW_USERNAME"], os.environ["SNOW_PASSWORD"])

    ssm = boto3.client("ssm")
    if auth_type == "basic":
        return (
            get_ssm_param(ssm, parameter_base + "/snow_username"),
            get_ssm_param(ssm, parameter_base + "/snow_password",
                          encrypted=True),
        )

    return None


def get_ssm_param(
    client: botocore.client,
    path: str,
    encrypted: bool = False,
    allow_missing: bool = False,
) -> str:
    try:
        ret = client.get_parameter(Name=path, WithDecryption=encrypted)
        value = ret["Parameter"]["Value"]
    except botocore.errorfactory.ParameterNotFound:
        if allow_missing:
            value = None
        else:
            raise KeyError(f"Could not find SSM Parameter {path}")

    return value


def parse_event(event: dict) -> dict:
    """
    Given a SNS event, extract a short description, long description, and
    priority level.

    * If the message parses as JSON, the priority key can set the priority.
    * If not in the message, priority can be included in the subject using
      the format: [Px]
      For example, the subject: "Really bad thing [P0]" would set a priority
      of 0
    * A default priority of 4 is used if priority is not specified

    Allowed priorities are 0 (highest) to 5 (lowest)
    """
    data = {"priority": 2}

    try:
        data["short_description"] = event["Records"][0]["Sns"]["Subject"]
        data["description"] = event["Records"][0]["Sns"]["Message"]
        data["timestamp"] = event["Records"][0]["Sns"]["Timestamp"]
    except KeyError:
        missing = [
            i
            for i in ["Subject", "Message", "Timestamp"]
            if i not in event["Records"][0]["Sns"]
        ]

        raise KeyError(
              'Malformed event: {"Records": [ {"Sns": {}: missing: ' +
              ','.join(missing))

    # If message is JSON, parse for additional information
    try:
        jmessage = json.loads(data["description"])
        # Format the JSON for readability while we are here
        data["description"] = json.dumps(jmessage, indent=2)
    except json.decoder.JSONDecodeError:
        jmessage = {}

    # Extract priority from subject or JSON if present
    m = re.search(r"\[p([0-5])\]", data["short_description"], re.I)
    if m:
        data["priority"] = int(m[1])

    if "priority" in jmessage:
        try:
            data["priority"] = int(jmessage["priority"])
            if data["priority"] < 0 or data["priority"] > 5:
                raise ValueError
        except ValueError:
            raise ValueError(
                f"Invalid priority {jmessage['priority']}: Valid range 0 to 5"
            )

    return data


def create_body(
    default_body: dict,
    short_description: str,
    description: str,
    priority: int = 4,
):
    """
    Merge defaults with parsed event elements.

    default_body      - Set of defaults including category and subcategory
    short_description - Summary
    description       - Multiline detail of incident
    priority          - 0 (highest) to 5 (lowest) (Default: 4)
    """
    # Truncate descriptions
    short_description = short_description[:120]
    description = description[:4000]

    body = default_body.copy()

    body.update(
        {
            "short_description": short_description,
            "description": description,
            "priority": priority,
        }
    )

    return body


def create_incident(url: str, auth: Any, body: dict) -> str:
    headers = urllib3.make_headers(basic_auth=":".join(auth))
    headers.update(
        {"Content-Type": "application/json", "Accept": "application/json"}
    )

    encoded_body = json.dumps(body).encode("utf-8")

    http = urllib3.PoolManager()

    response = http.request("POST", url, headers=headers, body=encoded_body)

    if response.status != 201:
        full_error = (
            f"SNOW request failed with status {response.status}, ",
            f"Headers: {response.headers}, ",
            f"Response: {response.data.decode('utf-8')}",
        )
        raise ValueError(full_error)

    return json.loads(response.data.decode("utf-8"))


def lambda_handler(event, context):
    parsed_event = parse_event(event)

    settings = get_env_settings()
    auth = get_auth(settings["parameter_base"])

    body = create_body(
        settings["default_body"],
        parsed_event["short_description"],
        parsed_event["description"],
        priority=parsed_event["priority"],
    )

    incident = create_incident(settings["url"], auth, body)

    try:
        incident_id = incident["result"]["number"]
    except KeyError:
        raise ValueError(
            f"Did not find incident number in ServiceNow response: {incident}"
        )

    print(f"Created incident: {incident_id}")
