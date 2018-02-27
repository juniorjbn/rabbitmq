#!/bin/bash

set -xe

N=${HOSTNAME##*-}
FQDN=${HOSTNAME}.${SERVICE_NAME}.${NAMESPACE}.svc.cluster.local

cat <<EOF > /etc/rabbitmq/rabbitmq.conf
vm_memory_high_watermark.absolute = MEMORY_LIMIT
listeners.tcp.default = 5672
management.listener.port = 15672
management.listener.ssl = false
hipe_compile = true
loopback_users = none
EOF

sed -i "s/MEMORY_LIMIT/$MEMORY_LIMIT/" /etc/rabbitmq/rabbitmq.conf

# ensure we resolve service domain first
sed "s/search \(.*\)/search ${SERVICE_NAME}.${NAMESPACE}.svc.cluster.local \1/g" < /etc/resolv.conf > /tmp/resolv.conf
cat /tmp/resolv.conf > /etc/resolv.conf

if [ -n "${HOSTNAME}" -a -n "${SERVICE_NAME}" -a -n "${NAMESPACE}" ]; then
    #export RABBITMQ_NODENAME="rabbit@${FQDN}"
    export RABBITMQ_NODENAME="rabbit@${HOSTNAME}"
fi

if [ -n "${RABBIT_COOKIE}" ]; then
    echo ${RABBIT_COOKIE} > /var/lib/rabbitmq/.erlang.cookie
    chmod 600 /var/lib/rabbitmq/.erlang.cookie
fi

if [ -n "$N" -a -z "$PRESERVE_DATABASE_DIR" ]; then
    rm -rf /var/lib/rabbitmq/mnesia/rabbit@rabbitmq-$N*
fi

if [ -n "$N" -a "${N}" != 0 -a -n "${START_DELAY}" ]; then
    sleep ${START_DELAY}
fi

exec "$@"
