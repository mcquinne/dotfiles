#!/usr/bin/env bash

# Use ssm to start an ssh session on an aws ec2 instance
# designed for use as a proxy command in ~/.ssh/config, like:
#
# Host anyname
#   HostName i-0123456789abcdef0
#   ProxyCommand sh -c "ssm-proxy %h %p <aws_profile>"

# Arguments passed from SSH client
HOST=$1 # should be an ec2 instance-id
PORT=$2
AWS_PROFILE=${3:-default}
AWS_REGION=${4:-us-east-1}

# Configuration
# Change these values to reflect your environment
MAX_ITERATION=5
SLEEP_DURATION=10

ID=`aws --profile ${AWS_PROFILE} sts get-caller-identity`
if [ -z "${ID}" ]; then
    if [ -n "$(aws configure get sso_account_id --profile ${AWS_PROFILE})" ]; then
        aws --profile ${AWS_PROFILE} sso login
    fi
fi

STATUS=`aws ssm describe-instance-information --filters Key=InstanceIds,Values=${HOST} --output text --query 'InstanceInformationList[0].PingStatus' --profile ${AWS_PROFILE} --region ${AWS_REGION}`

# If the instance is online, start the session
if [ $STATUS != 'Online' ]; then
    echo "Instance is offline, starting..."
    aws ec2 start-instances --instance-ids $HOST --profile ${AWS_PROFILE} --region ${AWS_REGION}
    sleep ${SLEEP_DURATION}
    COUNT=0
    while [ ${COUNT} -le ${MAX_ITERATION} ]; do
        STATUS=`aws ssm describe-instance-information --filters Key=InstanceIds,Values=${HOST} --output text --query 'InstanceInformationList[0].PingStatus' --profile ${AWS_PROFILE} --region ${AWS_REGION}`
        if [ ${STATUS} == 'Online' ]; then
            break
        fi
        # Max attempts reached, exit
        if [ ${COUNT} -eq ${MAX_ITERATION} ]; then
            exit 1
        else
            let COUNT=COUNT+1
            sleep ${SLEEP_DURATION}
        fi
    done
fi

# Start the session
aws ssm start-session --target $HOST --document-name AWS-StartSSHSession --parameters portNumber=${PORT} --profile ${AWS_PROFILE} --region ${AWS_REGION}
