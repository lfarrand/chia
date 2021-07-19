#!/bin/bash

pageContents=$(curl -s https://api.github.com/repos/joaquimguimaraes/farmr/releases/latest)
latestVer=$(grep "linux-x86_64.tar.gz" <<< "$pageContents" | cut -d '"' -f 4 | tail -1)
echo "latestVer: $latestVer"
filename=$(grep "linux-x86_64.tar.gz" <<< "$pageContents" | cut -d '"' -f 4 | sort -r | tail -1)
echo "filename: $filename"
mkdir latestver
cd latestver
echo "Current dir: $(pwd)"
echo "Downloading $filename"
curl -s -LJO "$latestVer"
echo "Extracting $filename"
tar -xf "$filename"
rm -rf "$filename"
echo "Extracted $filename"

if [ -e ../blockchain ]; then
    rsync -a ../blockchain/* ./blockchain/
fi

if [ -e ../cache ]; then
    rsync -a ../cache/* ./cache/
fi

if [ -e ../config ]; then
    rsync -a ../config/* ./config/
fi

cd ..
rsync -a latestver/* .
rm -rf latestver
echo "Done"
