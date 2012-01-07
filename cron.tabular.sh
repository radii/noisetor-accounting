#!/bin/bash

URL=http://cha-ching.noisebridge.net/v1/donations/list/all/json/noisetor

set -e
cd $(dirname $0)
wget -T 60 -q -O noisetor.json $URL
./tabular.pl > finances.html
