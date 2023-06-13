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

function setregion() {
    _logger "[+] Setting region"
    echo  "REGION=$(curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)" >>$work_dir/set_vars.sh
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

function getapiurl(){
    _logger "[+] getapiurl()"
    api=`aws cloudformation describe-stacks --stack-name $sam_stack_name --query "Stacks[].Outputs[] | [?OutputKey=='ApiURL'].OutputValue" --output text`
    echo "api=$api" >> $work_dir/set_vars.sh

}

function initdb(){
  _logger "[+] initdb()"
  mysql -h $AuroraEndpoint -u admin --password=Corp123! < $work_dir/init.sql
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

function getauthorizer(){
    _logger "[+] getauthorizer"
    source $work_dir/set_vars.sh
    user_pool=`aws cognito-idp list-user-pools --max-results 10 --query "UserPools[?Name=='customizeunicorns-users'].Id" --output text`
    client_id=`aws cognito-idp list-user-pool-clients --user-pool-id $user_pool --query "UserPoolClients[?ClientName=='Admin'].ClientId" --output text`
    client_secret=`aws cognito-idp describe-user-pool-client --user-pool-id $user_pool --client-id $client_id --query "UserPoolClient.ClientSecret" --output text`
    domain=`aws cognito-idp describe-user-pool --user-pool-id $user_pool --query "UserPool.Domain"`
    cognito_domain="https://${domain}.auth.${REGION}.amazoncognito.com"
    echo "user_pool=$user_pool" >> $work_dir/set_vars.sh
    echo "client_id=$client_id" >> $work_dir/set_vars.sh
    echo "client_secret=$client_secret" >> $work_dir/set_vars.sh
    echo "cognito_domain=$cognito_domain" >> $work_dir/set_vars.sh
}

function main() {
    install_utility_tools
    setcfoutput
    setregion
    getapiurl
    initdb
    getauthorizer
    testapi
}


if [ -d "$HOME/environment" ];
then
  echo "we are in a Cloud9 environment"
  export work_dir="$HOME/environment/aws-samples/securing-serverless-applications/setup"
  export stack_name='secure-serverless'
  export sam_stack_name='customizeunicorns'
  cd $work_dir
  if [ -f 'set_vars.sh' ]; then
    rm set_vars.sh
  fi
else
  echo "Script must be run from Cloud9 environment.  See instructions for accessing Cloud9"
  exit 1
fi

main
source $work_dir/set_vars.sh
cd $HOME/environment
