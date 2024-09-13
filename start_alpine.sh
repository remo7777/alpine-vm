#!/bin/bash

# Variables
# BIOS="/data/data/com.termux/files/usr/share/qemu/edk2-x86_64-secure-code.fd"
PWd="${PWD}"
boot="$(mktemp)"
QCOW2_IMAGE="alpine.qcow2"                  # Disk image for Alpine
SHARED_FOLDER="$HOME/vm-shared"             # Shared folder with host

VAR4=$(echo $(( $(stty size | cut -d ' ' -f 2) - 17)))
PUT(){ echo -en "\033[${1};${2}H";}
DRAW(){ echo -en "\033%";echo -en "\033(0";}
WRITE(){ echo -en "\033(B";}
HIDECURSOR(){ echo -en "\033[?25l";}
NORM(){ echo -en "\033[?12l\033[?25h";}

print_center_file()
{
    local file="$1"
    local content
    if [[ -f "$file" ]]; then
        content=$(sed "s/\x1B\[[^0-9;]*[mGK]//g" "$file")
    else
        echo "Error: File '$file' not found."
        return 1
    fi
    local prefix=""  # zero space
    while IFS= read -r line; do
        printf "%s%s\n" "$prefix" "$line"
    done <<< "$content"
}

print_prefixed_file()
{
    local file="$1"
    local content
    if [[ -f "$file" ]]; then
        content=$(sed "s/\x1B\[[^0-9;]*[mGK]//g" "$file")
    else
        echo "Error: File '$file' not found."
        return 1
    fi
    local prefix="                           "  # 15 spaces
    while IFS= read -r line; do
        printf "%s%s\n" "$prefix" "$line"
    done <<< "$content"
}
# ${1}=figlet, ${2}=logo
banner () {
    HIDECURSOR
    clear
    echo -e "\033[35;1m"
    PUT 0 0
    echo "┌$(seq -s─ $(( $(stty size | cut -d ' ' -f 2) - 1)) | tr -d '[:digit:]')┐"
    for ((i=1; i<=8; i++)); do
        echo "│$(seq -s\  $(( $(stty size | cut -d ' ' -f 2) - 1)) | tr -d '[:digit:]')│"
    done;
    echo "└$(seq -s─ $(( $(stty size | cut -d ' ' -f 2) - 1)) | tr -d '[:digit:]')┘"
    PUT 5 0
    print_prefixed_file "${1}"
    PUT 1 0
    print_center_file "${2}"
    PUT 1 0
    echo -e "\033[35;1m"
    for ((i=1; i<=8; i++)); do
        echo "│"
    done
    PUT 9 ${VAR4}
    echo -e "\e[32mBoot Script \e[33m2.0\e[0m"
    PUT 10 0
    echo
    NORM
}
check_internet () {

	echo -ne "\033[34m\r[*] \033[4;32mChecking Your Internet Connection... \e[0m"; 
	(ping -c 3 google.com) &> /dev/null 2>&1
    if [[ "$?" != 0 ]];then
	    echo -ne "\033[31m\r[*] \033[4;32mPlease Check Your Internet Connection... \e[0m"; 
	    sleep 1
	    exit 0
    fi
}
#start from here ---

banner "${PWd}/.object/fig_alpine.txt" "${PWd}/.object/alpine.txt" >> ${boot}
cat "${boot}"
check_internet
echo "";
termux-clipboard-set "chmod +x /vm-shared/docker_conf.sh && ./../vm-shared/docker_conf.sh" &> /dev/null & echo -e "\e[1;33m[*] \e[1;32mtermux-clipboard-set copied...\e[1;0m"
sleep 2
echo -e "\e[1;34m[*] \e[1;33mnow preparing for boot ( wait 5-10 minutes )\e[1;0m"
sleep 2
# Start QEMU VM with Alpine ISO and disk image (background process)
qemu-system-x86_64 -machine q35 -m 2048M -smp cpus=4 -cpu qemu64 \
    -drive file=$QCOW2_IMAGE,if=virtio \
    -netdev user,id=n1,hostfwd=tcp::2222-:22,hostfwd=tcp::2375-:2375,hostfwd=tcp::9000-:9000 \
    -device virtio-net,netdev=n1 \
    -virtfs local,path=$SHARED_FOLDER,mount_tag=vm-shared,security_model=mapped \
    -serial mon:stdio \
    -vga none \
    -display none 
