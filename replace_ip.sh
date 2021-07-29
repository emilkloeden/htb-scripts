#! /bin/bash
if [ -z "$HTB_DIR" ]; then
  echo "HTB_DIR environment variable not set. Exiting..."
  exit 1
fi

if [ $# -ne 1 ]; then
  echo "USAGE: replace_ip.sh <machine_name>"
  exit 2
fi

MY_IP=$(ifconfig tun0 | grep -oE "(10\.10\.14\.[0-9]+)" | head -1)
echo -e "Current tun0 IP: $MY_IP\n"
echo -e "Files to replace..."
grep -RE "10\.10\.14\..+" "$HTB_DIR/windows/$1/"
echo -e "\nReplacing..."
find "$HTB_DIR/windows/$1" -type f -print0 | xargs -0 sed -i -r 's/10\.10\.14\.[0-9]+/'"${MY_IP}"'/g'
echo -e "Done."
