#!/usr/bin/env python

# Cloudflare Python SDK/API
# https://blog.cloudflare.com/python-cloudflare/
# https://github.com/cloudflare/python-cloudflare
# https://api.cloudflare.com/


# Requirements:
# python -m pip install cloudflare

# Environment variables:
# CLOUDFLARE_EMAIL
# CLOUDFLARE_API_KEY
# CLOUDFLARE_DNS_RECORD_NAME
# CLOUDFLARE_DNS_RECORD_TYPE
# CLOUDFLARE_DNS_RECORD_VALUE

import CloudFlare
from os import environ


def main():
    dns_record_name = environ.get('CLOUDFLARE_DNS_RECORD_NAME')
    dns_record_type = environ.get('CLOUDFLARE_DNS_RECORD_TYPE') if environ.get(
        'CLOUDFLARE_DNS_RECORD_TYPE') else "A"
    dns_record_value = environ.get('CLOUDFLARE_DNS_RECORD_VALUE')
    cf = CloudFlare.CloudFlare()
    zones = cf.zones.get()
    for zone in zones:
        zone_id = zone['id']
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
                            "type": dns_record_type
                        })
                except Exception as e:
                    print("Failed to update DNS record", e)
                print(f"Updated successfully with type {dns_record_type} and value {dns_record_value}")
                exit(0)


if __name__ == '__main__':
    main()
