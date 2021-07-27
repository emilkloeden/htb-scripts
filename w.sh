# w.sh
# -----
# Opinionated automation of the initial enumeration on windows HTB machines
# Expects a base directory exported to HTB_DIR environment variable

# Make things pretty
LIGHT_GREEN='\033[1;32m'
NO_COLOR='\033[0m'

# Create variables for directory and file paths
WINDOWS_DIR="$HTB_DIR/windows"
# LINUX_DIR="$HTB_DIR/linux"
MACHINE_IP=$2
MACHINE_NAME=$1
MACHINE_DIR="$WINDOWS_DIR/$MACHINE_NAME"
NMAP_DIR="$MACHINE_DIR/nmap"
PORTS_FILE="$MACHINE_DIR/ports"
NMAP_FILE="$NMAP_DIR/default.nmap"

# Get open/filtered ports
echo -e "[+] Creating ${LIGHT_GREEN}$NMAP_DIR${NO_COLOR} if it doesn't exist..."
mkdir -p $NMAP_DIR
echo "[+] Running fast nmap scan to discover open ports (this may take a while)..."
ports=$(nmap -p 80,139,443,445,3306 --min-rate=1000 -Pn -T4 $MACHINE_IP | grep '^[0-9]' | cut -d '/' -f 1)

comma_separated_ports_list=$(echo $ports | tr '\n' ',' | sed s/,$//)
echo -e "[+] Discovered ports: ${LIGHT_GREEN}$comma_separated_ports_list${NO_COLOR}. Saving to ${LIGHT_GREEN}$PORTS_FILE${NO_COLOR}"
printf "%s $ports"
printf "%s $ports\n" > $PORTS_FILE

# Run a complete nmap scan
echo -e "[+] Running default nmap scripts and version scan. Saving output to ${LIGHT_GREEN}$NMAP_FILE${NO_COLOR}."
nmap -v -p $comma_separated_ports_list -Pn -sC -sV $MACHINE_IP -o $NMAP_FILE


