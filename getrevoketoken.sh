#!/bin/bash

username=""
password=""
URL=""

encodedCredentials=$( printf "${username}:${password}" | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i - )

authToken=$( /usr/bin/curl "${URL}/uapi/auth/tokens" --silent --request POST --header "Authorization: Basic ${encodedCredentials}" )

token=$( /usr/bin/awk -F \" '{ print $4 }' <<< "${authToken}" | /usr/bin/xargs )

#Invalidate it
curl --request POST --url ${URL}/api/v1/auth/invalidate-token --header 'accept: application/json' --header "Authorization: Bearer $token"