#!/bin/bash

if [ -z "$cognito_domain" ]; then
    read -p 'Enter cognito domain: ' cognito_domain
    export cognito_domain
fi
if [ -z "$client_id" ]; then
    read -p 'Enter client id: ' client_id
    export client_id
fi
if [ -z "$client_secret" ]; then
    read -p 'Enter client secret: ' client_secret
    export client_secret
fi
export token=`curl --request POST \
--url $cognito_domain/oauth2/token \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data grant_type=client_credentials \
--data client_id=$client_id \
--data client_secret=$client_secret | jq '.access_token' | sed 's/\"//g'`

echo "cognito_domain=$cognito_domain"
echo "client_id=$client_id"
echo "client_secret=$client_secret"
echo "token=$token"
