#  Copyright 2020 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
#  This file is licensed to you under the AWS Customer Agreement (the "License").
#  You may not use this file except in compliance with the License.
#  A copy of the License is located at http://aws.amazon.com/agreement/ .
#  This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
#  See the License for the specific language governing permissions and limitations under the License.

from boto3 import client
import os
import time
from ipaddress import ip_network, ip_address
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)
logger.handlers[0].setFormatter(
    logging.Formatter("[%(asctime)s][%(levelname)s] %(message)s")
)
logging.getLogger("boto3").setLevel(logging.ERROR)
logging.getLogger("botocore").setLevel(logging.ERROR)


def lambda_handler(event, context):
    print(event)
    secret_id = event["context"]["secret-id"]
    output_bucket = event["context"]["output-bucket"]

    # Source IP ranges to allow requests from, if the IP is in one of these the request will not be checked for an api key
    ip_ranges = []
    if event["context"]["allowed-ips"]:
        for i in event["context"]["allowed-ips"].split(","):
            ip_ranges.append(ip_network("%s" % i))
    secure = False
    source_ip = ip_address(event['context']['source-ip'])
    if ip_ranges:
        for net in ip_ranges:
            if source_ip in net:
                secure = True
    if not secure:
        logger.error("Source IP %s is not allowed" % source_ip)
        raise Exception("Source IP %s is not allowed" % source_ip)

    # only GitHub supported for now
    github_repo_name = event["body-json"]["repository"]["full_name"]
    github_ssh_url = event["body-json"]["repository"]["ssh_url"]
    github_branch = (
        event["body-json"]["ref"]
        .replace("refs/heads/", "")
        .replace("refs/tags/", "tags/")
    )

    try:
        codebuild_client = client(service_name="codebuild")
        new_build = codebuild_client.start_build(
            projectName=os.getenv("codebuild_project_name"),
            environmentVariablesOverride=[
                {
                    "name": "GITHUB_SSH_URL",
                    "value": github_ssh_url,
                    "type": "PLAINTEXT",
                },
                {"name": "GITHUB_BRANCH", "value": github_branch, "type": "PLAINTEXT"},
                {"name": "SECRET_ID", "value": secret_id, "type": "PLAINTEXT"},
                {"name": "OUTPUT_BUCKET", "value": output_bucket, "type": "PLAINTEXT"},
                {
                    "name": "OUTPUT_BUCKET_KEY",
                    "value": "%s" % (github_repo_name.replace("/", "_")) + ".zip",
                    "type": "PLAINTEXT",
                },
                {
                    "name": "OUTPUT_BUCKET_PATH",
                    "value": "%s/%s/" % (github_repo_name, github_branch),
                    "type": "PLAINTEXT",
                },
            ],
        )
        build_id = new_build["build"]["id"]
        logger.info("CodeBuild Build ID is %s" % (build_id))
        build_status = "NOT_KNOWN"
        counter = 0
        while (
            counter < 60 and build_status != "SUCCEEDED"
        ):  # capped this, so it just fails if it takes too long
            logger.info("Waiting for CodeBuild to complete")
            time.sleep(5)
            logger.info(counter)
            counter = counter + 1
            current_build = codebuild_client.batch_get_builds(ids=[build_id])
            print(current_build)
            build_status = current_build["builds"][0]["buildStatus"]
            logger.info("CodeBuild Build Status is %s" % (build_status))
            if build_status == "SUCCEEDED":
                env_variables = current_build["builds"][0][
                    "exportedEnvironmentVariables"
                ]
                commit_id = [
                    env for env in env_variables if env["name"] == "GIT_COMMIT_ID"
                ][0]["value"]
                commit_message = [
                    env for env in env_variables if env["name"] == "GIT_COMMIT_MSG"
                ][0]["value"]
                print("commit_id: " + commit_id)
                print("commit_msg: " + commit_message)
                break
            elif (
                build_status == "FAILED"
                or build_status == "FAULT"
                or build_status == "STOPPED"
                or build_status == "TIMED_OUT"
            ):
                break
    except Exception as e:
        logger.info("Error in Function: %s" % (e))
