#  Copyright 2020 Amazon Web Services, Inc. or its affiliates.
#  All Rights Reserved.
#  This file is licensed to you under the AWS Customer Agreement
#  (the "License").
#  You may not use this file except in compliance with the License.
#  A copy of the License is located at http://aws.amazon.com/agreement/ .
#  This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#  CONDITIONS OF ANY KIND, express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

import traceback
import boto3
from cryptography.hazmat.primitives import serialization as \
    crypto_serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.backends import default_backend as \
    crypto_default_backend

def lambda_handler(event,context):
    try:
        if event['RequestType'] == 'Create':
            # Generate keys
            new_key = rsa.generate_private_key(
                backend=crypto_default_backend(), public_exponent=65537,
                key_size=2048)
            priv_key = str(new_key.private_bytes(
                crypto_serialization.Encoding.PEM,
                crypto_serialization.PrivateFormat.PKCS8,
                crypto_serialization.NoEncryption()
            ), 'utf-8')
            pub_key = str(new_key.public_key().public_bytes(
                crypto_serialization.Encoding.OpenSSH,
                crypto_serialization.PublicFormat.OpenSSH
            ), 'utf-8')
            print(priv_key)
            print(pub_key)

            kms = boto3.client(
                'kms', region_name=event["ResourceProperties"]["Region"])
            # Encrypt private key
            enc_key = kms.encrypt(
                KeyId=event["ResourceProperties"]["KMSKey"],
                Plaintext=priv_key)['CiphertextBlob']
            priv_file = open('/tmp/enc_key', 'wb')
            priv_file.write(enc_key)
            priv_file.close()
            # Encrypt public key
            enc_pub = kms.encrypt(
                KeyId=event["ResourceProperties"]["KMSKey"],
                Plaintext=pub_key)['CiphertextBlob']
            pub_file = open('/tmp/enc_pub', 'wb')
            pub_file.write(enc_pub)
            pub_file.close()

            # Upload keys to S3
            s3 = boto3.client('s3')
            enc_key_path = event["ResourceProperties"]["BucketPath"] + '/enc_key'
            enc_pub_path = event["ResourceProperties"]["BucketPath"] + '/enc_pub'
            s3.upload_file('/tmp/enc_key',
                           event["ResourceProperties"]["KeyBucket"], enc_key_path)
            s3.upload_file('/tmp/enc_pub',
                           event["ResourceProperties"]["KeyBucket"], enc_pub_path)
        else:
            pub_key = event['PhysicalResourceId']
        return {
            "pub_key": pub_key
        }
    except:
        traceback.print_exc()

