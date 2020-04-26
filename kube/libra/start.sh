#!/bin/bash
set -x
# create validator

j="0";
NUMBER_OF_VALIDATORS="1";
VALIDATOR_TEMPLATE="template/validator.tmpl.yaml";
FAUCET_TEMPLATE="template/faucet.tmpl.yaml";

# start validators
while [ $j -lt $NUMBER_OF_VALIDATORS ]
do
    VALIDATOR_YAML="generated/validator-node-$j.yaml";
    # generate file
    sed 's/\[validator_index\]/'$j'/g;s/\[number_of_validators\]/'$NUMBER_OF_VALIDATORS'/g' $VALIDATOR_TEMPLATE > $VALIDATOR_YAML;
    # start pod
    kubectl create -f ./generated/validator-node-$j.yaml;
    j=$[$j+1];
done

## start faucet
# wait for val-0
FIRST_VALIDATOR_IP=""
while [ -z "$FIRST_VALIDATOR_IP" ]; do
    sleep 5;
    FIRST_VALIDATOR_IP=$(kubectl get pod/val-0 -o=jsonpath='{.status.podIP}');
    echo "Waiting for pod/val-0 IP Address";
done;

FAUCET_YAML="./generated/faucet-node-"$FIRST_VALIDATOR_IP".yaml";
sed 's/\[ac_host\]/'$FIRST_VALIDATOR_IP'/g' $FAUCET_TEMPLATE > $FAUCET_YAML;

kubectl create -f $FAUCET_YAML;

## enable services
kubectl apply -f services/