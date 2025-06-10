#!/bin/bash
# This script updates the DDNS record for a domain using DuckDNS.
mkdir -p $HOME/logs
command='curl -s "https://www.duckdns.org/update?domains=app-owfema&token=$DUCKDNS_TOKEN&ip="'
echo "$(date) Updating DuckDNS..." >> $HOME/logs/duckdns.log
echo "$command" >> $HOME/logs/duckdns.log
eval $command >> $HOME/logs/duckdns.log
