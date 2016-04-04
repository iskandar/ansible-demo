#!/bin/bash

set -e
#set -x

# Override-able env vars
ENVIRONMENT_NAME=${ENVIRONMENT_NAME:-${1:-demo}}

# Credential IDs
CREDENTIALS_ID=${CREDENTIALS_ID:-}
API_KEY_ID=${API_KEY_ID:-}

RAX_API_KEY=${RAX_API_KEY:-}
OS_AUTH_URL=${OS_AUTH_URL:-https://identity.api.rackspacecloud.com/v2.0/}
OS_TENANT_ID=${OS_TENANT_ID:-}
OS_USERNAME=${OS_USERNAME:-}
OS_PASSWORD=${OS_PASSWORD:-}
OS_REGION_NAME=${OS_REGION_NAME:-LON}

KEY_PAIR=${KEY_PAIR:-}
BASE_DOMAIN=${BASE_DOMAIN:-}
NOTIFICATION_URL=${NOTIFICATION_URL:-}
GROUP_ID=${GROUP_ID:-999}

#${LB_ID:-}
#LB_ID=d01be237-d87c-40c0-8c34-b13aa0d9d1b7

if [ -z $RAX_API_KEY ]; then
    echo "Please set a value for RAX_API_KEY"
    exit 1
fi
if [ -z $KEY_PAIR ]; then
    echo "Please set a value for KEY_PAIR"
    exit 1
fi
if [ -z $OS_TENANT_ID ]; then
    echo "Please set a value for OS_TENANT_ID"
    exit 1
fi
if [ -z $OS_USERNAME ]; then
    echo "Please set a value for OS_USERNAME"
    exit 1
fi
if [ -z $OS_PASSWORD ]; then
    echo "Please set a value for OS_PASSWORD"
    exit 1
fi

# Derived env vars
RAX_USERNAME=${OS_USERNAME}
RAX_REGION=${OS_REGION_NAME}
LB_NAME=${ENVIRONMENT_NAME}-lb
ANSIBLE_HOST_KEY_CHECKING=False

HEAT_VARIANT=
if [ ! -z $LB_ID ]; then
    HEAT_VARIANT="-rcv3"
fi
HEAT_FILE=./orchestration/infrastructure${HEAT_VARIANT}.yaml

echo "Using HEAT template: " $HEAT_FILE

echo
echo "Creating resources..."
heat stack-create --template-file ${HEAT_FILE} ${ENVIRONMENT_NAME} \
    -P credentials_id=${CREDENTIALS_ID} \
    -P api_key_id=${API_KEY_ID} \
    -P environment_name=${ENVIRONMENT_NAME} \
    -P group_id=${GROUP_ID} \
    -P load_balancer_id=${LB_ID} \
    -P ssh_keypair_name=${KEY_PAIR} \
    -P post_init_notification_url=${NOTIFICATION_URL} \
      2>&1 | grep -v InsecurePlatformWarning | grep -v SubjectAltNameWarning
echo "Done"
echo

echo "Waiting for resources. This may take a few minutes..."
while true; do
    STATUS=$(heat stack-show ${ENVIRONMENT_NAME} 2>/dev/null | grep stack_status | grep -v reason | awk '{print $4}' 2>/dev/null)
    echo "Stack Status: $STATUS"
    if [ "$STATUS" = "CREATE_COMPLETE" ]; then
       echo "Done" && break;
    fi
    sleep 15
done
echo

# Store outputs as JSON
heat output-show --all ${ENVIRONMENT_NAME} 2>/dev/null > ${ENVIRONMENT_NAME}-output.json

# Extract the controller server IP and LB IP
LB_IP=$(cat ${ENVIRONMENT_NAME}-output.json | jq --raw-output -c '.[] | select(.output_key | contains("lb_public_ip")) | .output_value')

if [ ! -z $LB_IP ]; then
    echo
    echo "------------------------------------------------------"
    echo "LOAD BALANCER IP:    ${LB_IP}"
    echo "------------------------------------------------------"
    echo

    if [ ! -z $BASE_DOMAIN ]; then

        # Update DNS
        export RAX_USERNAME
        export RAX_API_KEY

        echo "Updating DNS for ${LB_NAME}: ${CLUSTER_IP}..."
        ansible-playbook -i /dev/null \
          -e base_name=${BASE_DOMAIN} \
          -e name=${LB_NAME}\
          -e ip=${LB_IP} \
          orchestration/dns.yaml
        echo "Done"
        echo
    fi
fi

echo "Tidying up..."
rm -f *output.json
echo "Done"
echo

echo
echo
echo "------------------------------------------------------"
echo " All done!"
[ ! -z $LB_IP ] && echo "Load-Balanced Nodes: http://${LB_IP}/"
[ ! -z $BASE_DOMAIN ] && echo "  * http://${LB_NAME}.${BASE_DOMAIN}/"
echo "------------------------------------------------------"
echo
echo
