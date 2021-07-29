# w.sh
# -----
# Opinionated automation of the initial enumeration on windows HTB machines
# Expects a base directory exported to HTB_DIR environment variable

# Make things pretty
LIGHT_GREEN='\033[1;32m'
NO_COLOR='\033[0m'

# Create variables for directory and file paths
if [ -z "$HTB_DIR" ]; then
  echo "HTB_DIR environment variable not set. Exiting..."
  exit 1
fi

if [ $# -ne 2 ]; then
  echo "USAGE: w.sh <machine_name> <machine_ip>"
  exit 2
fi

WINDOWS_DIR="$HTB_DIR/windows"
# LINUX_DIR="$HTB_DIR/linux"
MACHINE_IP=$2
MACHINE_NAME=$1
MACHINE_DIR="$WINDOWS_DIR/$MACHINE_NAME"
NMAP_DIR="$MACHINE_DIR/nmap"
PORTS_FILE="$MACHINE_DIR/ports"
NMAP_FILE="$NMAP_DIR/default"
MACHINE_WWW_DIR="$MACHINE_DIR/machine_www"
BUST_DIR="$MACHINE_DIR/bust"

# Get open/filtered ports
echo -e "[+] Creating ${LIGHT_GREEN}$NMAP_DIR${NO_COLOR} (if it doesn't exist)..."
mkdir -p $NMAP_DIR
echo "[+] Running fast nmap scan to discover open ports (this may take a while)..."
ports=$(nmap -p- --min-rate=10000 -Pn -T4 $MACHINE_IP | grep '^[0-9]' | cut -d '/' -f 1)

comma_separated_ports_list=$(echo $ports | tr ' ' ',' | sed s/,$//)
echo -e "[+] Discovered ports: ${LIGHT_GREEN}$comma_separated_ports_list${NO_COLOR}. Saving to ${LIGHT_GREEN}$PORTS_FILE${NO_COLOR}."
touch $PORTS_FILE
printf "%s $ports\n" > $PORTS_FILE

# Run a complete nmap scan
echo -e "[+] Running default nmap scripts and version scan. Saving output to ${LIGHT_GREEN}$NMAP_FILE${NO_COLOR}."
nmap -v -p $comma_separated_ports_list -Pn -sC -sV $MACHINE_IP -oA $NMAP_FILE

if grep -q "80" $PORTS_FILE; then
    echo -e "[+] Probing port 80..."
    echo -e "[+] Creating ${LIGHT_GREEN}$MACHINE_WWW_DIR${NO_COLOR} (if it doesn't exist)..."
    mkdir -p $MACHINE_WWW_DIR

    echo -e "Testing for http://$MACHINE_IP/${LIGHT_GREEN}index.php${NO_COLOR}"
    curl -s -S -f "http://$MACHINE_IP/index.php" -o "$MACHINE_WWW_DIR/index.php"
    echo -e "Testing for http://$MACHINE_IP/${LIGHT_GREEN}index.html${NO_COLOR}"
    curl -s -S -f "http://$MACHINE_IP/index.html" -o "$MACHINE_WWW_DIR/index.html"
    echo -e "Testing for http://$MACHINE_IP/${LIGHT_GREEN}robots.txt${NO_COLOR}"
    curl -s -S -f "http://$MACHINE_IP/robots.txt" -o "$MACHINE_WWW_DIR/robots.txt"
    EXTENSIONS=""
    if ls -la $MACHINE_WWW_DIR | grep -q "php"; then
        EXTENSIONS+="php"
        if ls -la $MACHINE_WWW_DIR | grep -q "html"; then
            EXTENSIONS+=",html"
        fi
    fi
    if ls -la $MACHINE_WWW_DIR | grep -q "html"; then
            EXTENSIONS+="html"
    fi
    mkdir -p $BUST_DIR
    if [ -z "$EXTENSIONS" ]; then
        echo "[+] Running gobuster with extensions ${LIGHT_GREEN}"$EXTENSIONS"${NO_COLOR}..."
        gobuster dir -x $EXTENSIONS -o $BUST_DIR/default.gobuster -u http://$MACHINE_IP -w /usr/share/SecLists/Discovery/Web-Content/raft-small-words-lowercase.txt
    else
        echo "[+] Running gobuster with no extensions..."
        gobuster dir -o $BUST_DIR/default.gobuster -u http://$MACHINE_IP -w /usr/share/SecLists/Discovery/Web-Content/raft-small-words-lowercase.txt
    fi
fi
