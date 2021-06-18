#!/bin/bash

pageContents=$(curl -s https://api.github.com/repos/joaquimguimaraes/farmr/releases/latest)
latestVer=$(grep "linux-x86_64.tar.gz" <<< "$pageContents" | cut -d '"' -f 4 | tail -1)
echo "latestVer: $latestVer"
filename=$(grep "linux-x86_64.tar.gz" <<< "$pageContents" | cut -d '"' -f 4 | sort -r | tail -1)
echo "filename: $filename"
echo "Downloading $filename"
curl -s -LJO $latestVer
echo "Extracting $filename"
tar -xf $filename
rm -rf config.json
rm -rf $filename
echo "Done"
