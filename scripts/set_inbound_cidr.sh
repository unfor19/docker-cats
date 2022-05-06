#!/usr/bin/env bash

set -e
set -o pipefail

_CIDR_RANGES_URL="https://www.cloudflare.com/ips-v4"
_CIDR_RANGES=$(curl -sL "$_CIDR_RANGES_URL")
_SECURITY_GROUP_ID="${SECURITY_GROUP_ID:-""}"
_INBOUND_PORT="${INBOUND_PORT:-"80"}"
_INBOUND_PROTOCOL="${INBOUND_PROTOCOL:-"tcp"}"

echo "$_SECURITY_GROUP_NAME, $_INBOUND_PORT, $_INBOUND_PROTOCOL"

for cidr_range in ${_CIDR_RANGES[*]}; do
    # https://awscli.amazonaws.com/v2/documentation/api/latest/reference/ec2/authorize-security-group-ingress.html#examples
    echo "Setting inbound CIDR for ${cidr_range} to ${_INBOUND_PORT}"
    aws ec2 authorize-security-group-ingress \
        --group-id "$_SECURITY_GROUP_ID" \
        --protocol "$_INBOUND_PROTOCOL" \
        --port "$_INBOUND_PORT" \
        --cidr "$cidr_range"
done
