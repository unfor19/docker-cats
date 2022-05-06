#!/usr/bin/env bash

set -e
set -o pipefail

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT
ctrl_c() {
    exit 0
}


# Helper Functions
error_msg(){
  local msg="$1"
  echo -e "[ERROR] $(date) :: $msg"
  exit 1
}


log_msg(){
  local msg="$1"
  echo -e "[LOG] $(date) :: $msg"
}


revoke_sg_inbound(){
    local sg_id="$1"
    local protocol="$2"
    local port="$3"
    local cidr_range="$4"
    sleep 1
    log_msg "Attempting to REMOVE existing rule for CIDR ${cidr_range} on port ${_INBOUND_PORT}"
    if aws ec2 revoke-security-group-ingress \
        --group-id "$sg_id" \
        --protocol "$protocol" \
        --port "$port" \
        --cidr "$cidr_range" 2>>.errors.logs ; then
        log_msg "Successfully REMOVED rule for CIDR ${cidr_range} on port ${_INBOUND_PORT}"
    fi
}


authorize_sg_inbound(){
    # https://awscli.amazonaws.com/v2/documentation/api/latest/reference/ec2/authorize-security-group-ingress.html#examples
    local sg_id="$1"
    local protocol="$2"
    local port="$3"
    local cidr_range="$4"
    sleep 1    
    log_msg "Attempting to UPDATE rule for CIDR ${cidr_range} on port ${_INBOUND_PORT}"
    aws ec2 authorize-security-group-ingress \
        --group-id "$sg_id" \
        --protocol "$protocol" \
        --port "$port" \
        --cidr "$cidr_range" 1>/dev/null
    log_msg "Successfully UPDATED rule for CIDR ${cidr_range} on port ${_INBOUND_PORT}"
}


revoke_inbound_rule_loop(){
    local sg_id="$1"
    local protocol="$2"
    local port="$3"
    local cidr_ranges="$4"
    for cidr_range in ${cidr_ranges[*]}; do
        revoke_sg_inbound "$sg_id" "$protocol" "$port" "$cidr_range" 1>/dev/null &
    done
    wait
}


update_inbound_rule_loop(){
    local sg_id="$1"
    local protocol="$2"
    local port="$3"
    local cidr_ranges="$4"
    for cidr_range in ${cidr_ranges[*]}; do
        authorize_sg_inbound "$sg_id" "$protocol" "$port" "$cidr_range" &
    done
    wait
}


main(){
    local sg_id="$1"
    local protocol="$2"
    local port="$3"
    local cidr_ranges="$4"
    log_msg "Setting inbound rules for security group ID '${sg_id}'"
    log_msg "Protocol: ${protocol}"
    log_msg "Port: ${port}"
    log_msg "CIDR Ranges:"
    echo "$cidr_ranges"
    revoke_inbound_rule_loop "$sg_id" "$protocol" "$port" "$cidr_ranges"
    update_inbound_rule_loop "$sg_id" "$protocol" "$port" "$cidr_ranges"
    log_msg "Completed setting inbound rules for ${_SECURITY_GROUP_ID}"
}

# Global variables
_SECURITY_GROUP_ID="${SECURITY_GROUP_ID:-""}"
_INBOUND_PROTOCOL="${INBOUND_PROTOCOL:-"tcp"}"
_INBOUND_PORT="${INBOUND_PORT:-"80"}"

_CIDR_RANGES_URL="${CIDR_RANGES_URL:-"https://www.cloudflare.com/ips-v4"}"
_CIDR_RANGES="${CIDR_RANGES:-$(curl -sL "$_CIDR_RANGES_URL")}"

# Main
main "$_SECURITY_GROUP_ID" "$_INBOUND_PROTOCOL" "$_INBOUND_PORT" "$_CIDR_RANGES"
