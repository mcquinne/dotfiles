#!/bin/bash
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

###
# Help
#
# This script is intended to be used in concert with the `ProxyCommand` directive for a `Host` defined in `~/.ssh/config`
# For example:
#
# ~/.ssh/config defining a Host for connecting to a bastion host:
# ...
# ## Name of Host doesn't matter, use this in ssh commands, e.g. `ssh my_host_name`
# Host my_host_name
#   ## Either an instance ID (e.g. i-0123456789abcdefg) OR the value of the Name: tag on an instance
#   HostName ec2_instance_id_or_name
#   ## The name of the user to log in as on the target machine
#   User ec2-user
#   ## Path to this script (e.g. via symlink) and its arguments (see below)
#   ProxyCommand sh -c "~/.local/bin/ssm-proxy.sh %h %p aws_profile"
#   ## Path to a custom identity file, e.g. an EC2 PEM key
#   IdentityFile ~/.ssh/ec2.pem
#   ## Creates a dynamic SOCKS proxy from the local machine through the target machine
#   DynamicForward 61234
# ...
# 
# The inputs to the ssm-proxy.sh script as are follows:
#        %h - passed by ssh, corresponds to the HostName value
#        %p - passed by ssh, dynamic port number to be used for the connection
# <profile> - optional, the name of an AWS_PROFILE to use to create the connection (defaults to "default")
# <region>  - optional, the name of an AWS_REGION to use to create the connection (defaults to "us-east-1")
###

# Configuration
# Change these values to reflect your environment
MAX_ITERATION=5
SLEEP_DURATION=10

# Arguments passed from SSH client
HOST=$1
PORT=$2
AWS_PROFILE=${3:-default}
AWS_REGION=${4:-us-east-1}

# log to stderr, stdout is used by ssh for proxying
log() { echo "$@" 1>&2; }

log " INFO: Connecting to HOST \"${HOST}\" using AWS_PROFILE \"${AWS_PROFILE}\" in AWS_REGION \"${AWS_REGION}\""

# Log in w/ sso if not already logged in
AWS_ID=`aws --profile ${AWS_PROFILE} sts get-caller-identity --output text --query 'Arn'`
if [ -z "${AWS_ID}" ]; then
    if [ -n "$(aws configure get sso_account_id --profile ${AWS_PROFILE})" ]; then
        log " INFO: User is not logged in but profile \"${AWS_PROFILE}\" has sso configured. Logging in..."
        aws --profile ${AWS_PROFILE} sso login 1>&2
    fi
else
    log " INFO: Using AWS identity: \"${AWS_ID}\""
fi

# If host is not already an instance ID, look up the instance ID
if [[ $HOST =~ ^i-[0-9a-z]+$ ]]; then
    INST_ID="${HOST}"
    log " INFO: Using configured instance ID \"${INST_ID}\""
else
    log " INFO: Looking up instance ID via Name tag..."
    INST_ID=`aws --profile ${AWS_PROFILE} ec2 describe-instances --filter Name=tag:Name,Values=${HOST} --query 'Reservations[*].Instances[*].{Instance:InstanceId}' --max-items 1 --output text`
    if [ -z "${INST_ID}" ]; then
        log "ERROR: Could not find an instance with tag Name=\"$HOST\" using AWS Profile \"$AWS_PROFILE\""
        exit 1
    else
        log " INFO: Found instance ID \"${INST_ID}\""
    fi
fi

# Check the current status of the target machine
STATUS=`aws ssm describe-instance-information --filters Key=InstanceIds,Values=${INST_ID} --output text --query 'InstanceInformationList[0].PingStatus' --profile ${AWS_PROFILE} --region ${AWS_REGION}`

# If the instance is NOT online, start the instance
if [ $STATUS != 'Online' ]; then
    log " INFO: Instance is offline, starting..."
    aws ec2 start-instances --instance-ids $INST_ID --profile ${AWS_PROFILE} --region ${AWS_REGION}
    sleep ${SLEEP_DURATION}
    COUNT=0
    while [ ${COUNT} -le ${MAX_ITERATION} ]; do
        STATUS=`aws ssm describe-instance-information --filters Key=InstanceIds,Values=${INST_ID} --output text --query 'InstanceInformationList[0].PingStatus' --profile ${AWS_PROFILE} --region ${AWS_REGION}`
        if [ ${STATUS} == 'Online' ]; then
            log " INFO: Instance is online"
            break
        fi
        # Max attempts reached, exit
        if [ ${COUNT} -eq ${MAX_ITERATION} ]; then
            log "ERROR: Timeout while starting instance ${INST_ID}"
            exit 1
        else
            let COUNT=COUNT+1
            sleep ${SLEEP_DURATION}
        fi
    done
fi

# Start the session
log " INFO: Starting SSH session..."
aws ssm start-session --target $INST_ID --document-name AWS-StartSSHSession --parameters portNumber=${PORT} --profile ${AWS_PROFILE} --region ${AWS_REGION}
