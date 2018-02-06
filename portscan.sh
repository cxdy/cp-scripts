#!/bin/bash
# portscan.sh
# To output to log file, run ./portscan.sh > portscan.txt
# No log? ./portscan.sh

# exit out if we're not root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

echo "Installing NMAP.."

apt-get install nmap

echo "Scanning open ports.."

nmap -v -sT localhost

echo "SYN scanning.."

nmap -v -sS localhost
