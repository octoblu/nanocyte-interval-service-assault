#!/usr/bin/env bash

MESHBLU_SERVER="${MESHBLU_SERVER:-localhost}"
MESHBLU_PORT="${MESHBLU_PORT:-3000}"
MESHBLU_PROTOCOL="${MESHBLU_PROTOCOL:-http}"
INTERVAL_SERVICE_UUID="${INTERVAL_SERVICE_UUID:-39498add-91ff-425f-bb13-b575030eb871}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-2}"
DEVICE_DIR="${DEVICE_DIR:-tmpDevices}"

mkdir $DEVICE_DIR 2>/dev/null

PIDS=()

#for t in $(cat 3.sub  | jq '.payload.timestamp'); do if [ $p ]; then expr $t - $p; fi; p=$t; done

intervalString=$(cat <<EOF
{"devices":["${INTERVAL_SERVICE_UUID}"], \
  "payload" : {\
    "nodeId" : "123456", \
    "nonce" : "", \
    "intervalTime": 1000 }, \
  "topic":"register-interval"}
EOF
)

cronString=$(cat <<EOF
{"devices":["${INTERVAL_SERVICE_UUID}"], \
  "payload" : {\
    "nodeId" : "123456", \
    "nonce" : "", \
    "cronString": "* * * * * *" }, \
  "topic":"register-cron"}
EOF
)

unsubscribe=$(cat <<EOF
{"devices":["${INTERVAL_SERVICE_UUID}"], \
  "payload" : {\
    "nodeId" : "123456", \
    "nonce" : "" }, \
  "topic":"unregister-interval"}
EOF
)

for i in $(seq 1 ${MAX_ATTEMPTS}); do
  echo 'adding device #' $i
  meshblu-util register -s ${MESHBLU_SERVER}:${MESHBLU_PORT} -o >${DEVICE_DIR}/${i}.json
  MESHBLU_PROTOCOL=${MESHBLU_PROTOCOL} meshblu-util-subscribe ${DEVICE_DIR}/${i}.json >${DEVICE_DIR}/${i}.sub &
  PIDS[$i]=$!

  if [ $((${i}%2)) -eq 0 ]; then
    MESSAGE_DATA=${intervalString}
  else
    MESSAGE_DATA=${cronString}
  fi

  meshblu-util message -d "${MESSAGE_DATA}" ${DEVICE_DIR}/${i}.json
  sleep 1
done

sleep 1

for i in $(seq 1 ${MAX_ATTEMPTS}); do
  echo "unsubscribing ${i}"
  meshblu-util message -d "${unsubscribe}" ${DEVICE_DIR}/${i}.json
done

sleep 1

for i in "${PIDS[@]}"; do
  echo killing $i
  kill $i
done
