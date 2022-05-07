#!/usr/bin/env python

# Cloudflare Python SDK/API
# https://blog.cloudflare.com/python-cloudflare/
# https://github.com/cloudflare/python-cloudflare
# https://api.cloudflare.com/

# AWS Lambda Function - Python with dependencies
# https://docs.aws.amazon.com/lambda/latest/dg/python-package.html
# python -m pip install --target ./lambdas/update-cloudflare-dns/package cloudflare
# rm ./lambdas/update-cloudflare-dns.zip && cd ./lambdas/update-cloudflare-dns/package && zip -rq ../../update-cloudflare-dns.zip . && cd -
# cd ./lambdas/update-cloudflare-dns && zip -g ../update-cloudflare-dns.zip ./main.py && cd -

# Deploy your .zip file to the function
# https://docs.aws.amazon.com/lambda/latest/dg/python-package.html#python-package-upload-code
# cd - # get back to root dir
# aws lambda update-function-code --function-name docker-cats-update-cloudflare-dns --zip-file fileb://lambdas/update-cloudflare-dns.zip

# Requirements:
# python -m pip install cloudflare

# Environment variables:
# CLOUDFLARE_EMAIL
# CLOUDFLARE_API_KEY
# CLOUDFLARE_ZONE_ID
# CLOUDFLARE_DNS_RECORD_NAME
# CLOUDFLARE_DNS_RECORD_TYPE
# CLOUDFLARE_DNS_RECORD_VALUE

import boto3
import CloudFlare
from os import environ


def extract_publicip_from_event(event, context=None):
    client = boto3.client('ec2')

    def get_eni_public_ip(client, eni_id):

        response = client.describe_network_interfaces(
            NetworkInterfaceIds=[
                eni_id,
            ]
        )
        eni_public_ip = response['NetworkInterfaces'][0]['Association']['PublicIp']
        print("eni public ip:", eni_public_ip)
        return eni_public_ip

    attachment_details_list = event['detail']['attachments'][0]['details']
    task_eni_id = [item['value']
                   for item in attachment_details_list if item['name'] == 'networkInterfaceId'][0]
    print("task eni id:", task_eni_id[0])
    task_public_ip = get_eni_public_ip(client, task_eni_id)
    return task_public_ip


def main(event=None, context=None):
    dns_record_name = environ.get('CLOUDFLARE_DNS_RECORD_NAME')
    dns_record_type = environ.get('CLOUDFLARE_DNS_RECORD_TYPE') if environ.get(
        'CLOUDFLARE_DNS_RECORD_TYPE') else "A"
    dns_record_value = environ.get('CLOUDFLARE_DNS_RECORD_VALUE')

    # If AWS Lambda function, override record value with event context
    # AWS_LAMBDA_RUNTIME_API - determines if running in an AWS Lambda Function - https://docs.aws.amazon.com/lambda/latest/dg/configuration-envvars.html
    is_lambda = environ.get('AWS_LAMBDA_RUNTIME_API')
    if is_lambda:
        dns_record_value = extract_publicip_from_event(event)

    print("dns_record_value:", dns_record_value)

    # All calls through the Cloudflare Client API are rate-limited by Cloudflare account to 1200 requests every 5 minutes.
    # https://support.cloudflare.com/hc/en-us/articles/200171456-How-many-API-calls-can-I-make
    cf = CloudFlare.CloudFlare()
    zone_id = environ.get('CLOUDFLARE_ZONE_ID')
    try:
        dns_records = cf.zones.dns_records.get(zone_id)
    except CloudFlare.exceptions.CloudFlareAPIError as e:
        exit(f'/zones/dns_records:edit {e} - api call failed')

    for item in dns_records:
        print(item)
        if 'name' in item and dns_record_name in item['name']:
            print(f'Found {dns_record_name}!')
            try:
                cf.zones.put(
                    f"{zone_id}/dns_records/{item['id']}",
                    data={
                        "name": dns_record_name,
                        "content": dns_record_value,
                        "type": dns_record_type,
                        "proxied": True
                    })
            except Exception as e:
                print("Failed to update DNS record", e)
            print(
                f"Updated successfully with type {dns_record_type} and value {dns_record_value}")
            return True


if __name__ == '__main__':
    main()
