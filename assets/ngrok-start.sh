#!/bin/bash
mkdir -p $HOME/logs
ngrok http $NGROK_TUNNEL_PORT --url=$NGROK_TUNNEL_URL --authtoken=$NGROK_AUTH_TOKEN --log=$NGROK_LOG
