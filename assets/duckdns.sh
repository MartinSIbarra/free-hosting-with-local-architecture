#!/bin/bash
# This script updates the DDNS record for a domain using DuckDNS.
mkdir -p $HOME/logs
echo curl -s "https://www.duckdns.org/update?domains=app-owfema&token=$DUCKDNS_TOKEN&ip=" >> $HOME/logs/duckdns.log
echo " - DuckDNS updated at $(date)" >> $HOME/logs/duckdns.log
