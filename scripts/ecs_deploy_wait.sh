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


_AWS_REGION="${AWS_REGION:-"eu-west-1"}"
_SLEEP_SECONDS="${SLEEP_SECONDS:-"15"}"
_ECS_CLUSTER_NAME="${ECS_CLUSTER_NAME:-""}"
_ECS_SERVICE_NAME="${ECS_SERVICE_NAME:-""}"

is_in_progress(){
    local describe_services_results
    local services_deployments_rolloutstates
    local state
    describe_services_results="$(aws ecs describe-services --region "$_AWS_REGION" --cluster "$_ECS_CLUSTER_NAME" --services "$_ECS_SERVICE_NAME")"
    services_deployments_rolloutstates=$(echo "$describe_services_results" | jq -cr '.services[].deployments[].rolloutState')
    state="$(echo "$services_deployments_rolloutstates" | grep IN_PROGRESS)"
    if [[ -n "$state" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

main(){
    local in_progress
    log_msg "Checking if ${_ECS_SERVICE_NAME} is in progress"    
    while : ; do
        in_progress=$(is_in_progress)
        if [[ "$in_progress" = "false" ]] ; then
            log_msg "Service is ready to be deployed - $_ECS_SERVICE_NAME"
            return
        fi
        log_msg "Deployment in progress, sleeping for $_SLEEP_SECONDS"
        sleep "$_SLEEP_SECONDS"
    done
    error_msg "Timed out"
}


# Run
main
