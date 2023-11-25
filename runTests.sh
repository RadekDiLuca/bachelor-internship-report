#!/bin/bash
bold=$(tput bold)
normal=$(tput sgr0)

MOSQUITTO_CONTAINER_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mosquittoContainer)

testConfigurations=(
    "mosquitto.conf"
    "mosquitto-self-signed.conf"
    "mosquitto-fake-ca.conf"
    "mosquitto-alt1.conf"
    "mosquitto-alt2.conf"
    "mosquitto-alt3.conf"
    "mosquitto-alt4.conf"
    "mosquitto-using-client-cert.conf"
    "mosquitto-longer-chain-of-trust.conf"
    "mosquitto-altered-common-name-longer-chain-of-trust.conf"
    "mosquitto-altered-public-key-longer-chain-of-trust.conf"
)

testTitles=("Test Case 1 - Legal Connection"
    "Test Case 2 - Self Signed Attacker"
    "Test Case 3 - Self Signed Attacker Fake CA"
    "Test Case 4 - Alteration 1 (Common Name)"
    "Test Case 5 - Expired Certificate altered Expiration Date (Alteration 2)"
    "Test Case 6 - Alteration 3 (Public Key)"
    "Test Case 7 - Expired CA (for laboratory purposes, Alteration 4)"
    "Test Case 8 - Certificate Extension (MQTT Broker Client Certificate)"
    "Test Case 9 - Longer Chain Of Trust Legal Connection"
    "Test Case 10 - Altered Intermediate CA Common Name"
    "Test Case 11 - Altered Intermediate CA Public Key"
)

# Test Case 7 has to be validated against expired ca on client side, not default legal ca.
caPathOverride=(
    ""
    ""
    ""
    ""
    ""
    ""
    "certificates/expired-ca/ca.pem"
    ""
    ""
    ""
    ""
)

for i in ${!testConfigurations[@]}; do
    echo "${bold}Running ${testTitles[$i]}${normal}"
    CONFIGURATION_FOR_CURRENT_TEST=${testConfigurations[$i]}
    echo "Configuring mosquittoContainer with new certificates..."
    docker exec mosquittoContainer cp /mosquitto/config/test-configurations/$CONFIGURATION_FOR_CURRENT_TEST /mosquitto/config/mosquitto.conf
    sleep 1
    echo "Restarting mosquittoContainer..."
    docker restart mosquittoContainer
    sleep 3
    docker exec testerContainer bash -c "cd /app/src && sh testMQTTBroker.sh $MOSQUITTO_CONTAINER_IP ${caPathOverride[$i]}"
done
