#!/bin/sh

NC='\033[0;0m'
RED='\033[0;31m'
GREEN='\033[0;32m'

echo "Setting up MQTT client subscription..."

if [ -z $2 ];
then
    caPath=certificates/ca/ca.pem
else
    caPath=$2
fi

echo "Using validation ca certificate on tester client: $caPath"
mosquitto_sub -h $1 -p 8883 -i 'subid' -t 'test' --cafile $caPath &
subPID=$!

sleep 1.5

echo "Killing $subPID"
kill $subPID

if [ $? = "0" ]
then
    echo "${GREEN}The MQTT client subscription was working correctly${NC}"
else
    echo "${RED}The MQTT client subcription was not active${NC}"
fi