#!/bin/bash
set -x

NUMBER_OF_VALIDATORS="1";
VALIDATOR_TEMPLATE="template/validator.tmpl.yaml";
FAUCET_TEMPLATE="template/faucet.tmpl.yaml";
GRAPHANA_DATASOURCE_TEMPLATE="template/grafana/grafana-datasource-config.tmpl.yaml";

#apply namespace
kubectl apply -f namespace.yaml

# start validators
echo "-------- STARTING VALIDATORS --------"
j="0";
while [ $j -lt $NUMBER_OF_VALIDATORS ]
do
    VALIDATOR_YAML="generated/validator-node-$j.yaml";
    # generate file
    sed 's/\[validator_index\]/'$j'/g;s/\[number_of_validators\]/'$NUMBER_OF_VALIDATORS'/g' $VALIDATOR_TEMPLATE > $VALIDATOR_YAML;
    # start pod
    kubectl create -f ./generated/validator-node-$j.yaml;
    j=$[$j+1];
done

echo "-------- STARTING FAUCET --------"
## start faucet
# wait for val-0
FIRST_VALIDATOR_IP=""
while [ -z "$FIRST_VALIDATOR_IP" ]; do
    sleep 5;
    FIRST_VALIDATOR_IP=$(kubectl get pod/val-0 -n localnet -o=jsonpath='{.status.podIP}');
    echo "Waiting for pod/val-0 IP Address";
done;

FAUCET_YAML="./generated/faucet-node-"$FIRST_VALIDATOR_IP".yaml";
sed 's/\[ac_host\]/'$FIRST_VALIDATOR_IP'/g' $FAUCET_TEMPLATE > $FAUCET_YAML;

kubectl create -f $FAUCET_YAML;

## enable services
echo "-------- STARTING SERVICES --------"
kubectl apply -f services/

## enable monitoring
echo "-------- STARTING MONITORING --------"
kubectl apply -f prometheus/

## enable grafana
echo "-------- STARTING GRAFANA --------"
GRAPHANA_DATASOURCE_YAML="./generated/grafana-datasource-config.yaml";
# wait for prometheus pod
PROMETHEUS_IP="";
while [ -z "$PROMETHEUS_IP" ]; do
    sleep 5;
    PROMETHEUS_IP="$(kubectl get pods --namespace=localnet -o wide |grep -i "prometheus"|awk '{print $6;}')";
    echo "Waiting for prometheus data source";
done;

sed 's/\[prometheus_ip\]/'$PROMETHEUS_IP'/g' $GRAPHANA_DATASOURCE_TEMPLATE > $GRAPHANA_DATASOURCE_YAML;
kubectl create -f $GRAPHANA_DATASOURCE_YAML
kubectl create -f grafana/