#!/bin/bash

URL=http://cha-ching.noisebridge.net/v1/donations/list/all/json/noisetor

set -e
cd $(dirname $0)
git pull -q

#wget -T 60 -q -O noisetor.json $URL
curl -sS -f --connect-timeout 30 --max-time 60 -o noisetor.json $URL

./tabular.pl > finances.html
