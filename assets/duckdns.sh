#!/bin/bash
# This script updates the DDNS record for a domain using DuckDNS.
mkdir -p $HOME/logs
echo "$(date) Updating DuckDNS..." >> $HOME/logs/duckdns.log
echo 'curl -s "https://www.duckdns.org/update?domains=app-owfema&token=$DUCKDNS_TOKEN&ip="' >> $HOME/logs/duckdns.log
curl -s "https://www.duckdns.org/update?domains=app-owfema&token=$DUCKDNS_TOKEN&ip=" >> $HOME/logs/duckdns.log
