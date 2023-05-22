#!/bin/bash

#
# Cloud9 Bootstrap Script
# updated 12/6/2022
# Tested on Amazon Linux 2
# Checks for AWS Event or Cloudformation setup
# 1. Installs JQ
# 2. Creates Environment Variables
# 3. NPM Installs and Deploys Application
#
# Usually takes less than one minute to complete
#
# NOTES
# As currently written only works in Cloud9

set -exo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

function _logger() {
    echo -e "$(date) ${YELLOW}[*] $@ ${NC}"
}


function install_utility_tools() {
    _logger "[+] Installing jq"
    sudo yum install -y jq
}

function checkstack() {
    _logger "[+] Setting StackName"

    stack=$(aws cloudformation list-stacks --query "StackSummaries[?StackStatus == 'CREATE_COMPLETE' && StackName == '$stack_name'].StackName")

    if [ "$stack" = "[]" ];
        then
            echo "Stack Set missing.  Check out running the stack set in the instructions."
            exit 0
        else
            echo "Found stack: $stack_name"
    fi
}


function setclustername() {
    _logger "[+] Setting Auora Cluster name"
    sed -i "s/secure-aurora-cluster.cluster-xxxxxxx.xxxxxxx.rds.amazonaws.com/$AuroraEndpoint/g" $work_dir/src/app/dbUtils.js
}

function setregion() {
    _logger "[+] Setting region"
    echo  "REGION=$(curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)" >>$work_dir/set_vars.sh
}

function checkfile(){
    _logger "[+] Checkfile"
    export FILE=$work_dir/src/app/dbUtils.js
    if [ -f $FILE ];
    then
        echo "Files cloned from Git!"
    else
        echo "Missing files. Please be sure to clone the file from Git: git clone https://github.com/aws-samples/aws-serverless-security-workshop.git"
        exit 0
    fi
}

function setcfoutput() {

    # load outputs to env vars
    _logger "[+] get Cloudformation outputs and set variables"
    for output in $(aws cloudformation describe-stacks --stack-name $stack_name --query 'Stacks[].Outputs[].OutputKey' --output text)
    do
        echo "$output=$(aws cloudformation describe-stacks --stack-name $stack_name --query 'Stacks[].Outputs[?OutputKey==`'$output'`].OutputValue' --output text)" >> $work_dir/set_vars.sh
    done
    source $work_dir/set_vars.sh
}

function deployapp() {
    _logger "[+] Deploying app"
    cd $work_dir/src/app
    _logger "[+] npm install"
    npm install
    cd  $work_dir/src
    _logger "[+] sam deploy"
    sam deploy --stack-name CustomizeUnicorns --s3-bucket $DeploymentS3Bucket --capabilities CAPABILITY_IAM --parameter-overrides ParameterKey=InitResourceStack,ParameterValue=$stack_name || true
    cd  $work_dir

}

function getapiurl(){
    _logger "[+] getapiurl()"
    sam_stack_name="CustomizeUnicorns"
    api="$(aws cloudformation describe-stacks --stack-name $sam_stack_name --query 'Stacks[].Outputs[].OutputValue' --output text)"
    export api=${api%/} # remove trailing /
    echo "api=$api" >> $work_dir/set_vars.sh

}

function initdb(){
  _logger "[+] initdb()"
  mysql -h $AuroraEndpoint -u admin --password=Corp123! < $work_dir/src/init/db/queries.sql
  mysql -h $AuroraEndpoint -u admin --password=Corp123! -e "show tables" unicorn_customization
}

function testapi(){
    _logger "[+] testapi"
    curl $api/socks | python -m json.tool
    res=$?
    if test "$res" != "0"; then
        _logger "[+] api test failed with return code $res"
        _logger "[+] review output and instructions"
        exit $res
    fi
}

function main() {
    install_utility_tools
#    checkfile
#    checkstack
    setcfoutput
    setclustername
    setregion
    deployapp
    getapiurl
    initdb
    testapi
}


if [ -d "$HOME/environment" ];
then
  echo "we are in a Cloud9 environment"
  export work_dir="$HOME/environment/securing-serverless-applications/setup"
  cd $work_dir
  if [ -f 'set_vars.sh' ]; then
    rm set_vars.sh
  fi
else
  echo "Script must be run from Cloud9 environment.  See instructions for accessing Cloud9"
  exit 1
fi

if [ -z "${1}" ]; then
  _logger "Error: must provide stack_name"
  _logger "> bash setup/bootstrap.sh 'cloudfomration-stack-name'"
  _logger "see workshop instructions for details"
  exit 1
fi

export stack_name=${1}
main
source $work_dir/set_vars.sh
cd $work_dir/..
