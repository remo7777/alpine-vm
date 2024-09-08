#!/bin/bash

# Variables

# BIOS="/data/data/com.termux/files/usr/share/qemu/edk2-x86_64-secure-code.fd"
# -drive if=pflash,format=raw,read-only=on,file=${BIOS} \
PWd="${PWD}"
user="$(mktemp)"
szf="File Size of"
# lb="${TMPDIR}/LB"
ALPINE_ISO="alpine-x86_64"  # Alpine ISO file
x01="alpine_sha256"         # sha256 checksum
QCOW2_IMAGE="alpine.qcow2"      # Disk image for Alpine
SHARED_FOLDER="$HOME/vm-shared" # Shared folder with host
ISO_URL="https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/x86_64/alpine-virt-3.20.3-x86_64.iso"
ISO_SHA256="https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/x86_64/alpine-virt-3.20.3-x86_64.iso.sha256"
DOCKER_HOST_ADD="$HOME/.profile"

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
    local prefix=""  # 15 spaces
    while IFS= read -r line; do
        printf "%s%s\n" "$prefix" "$line"
    done <<< "$content"
}

print_prefixed_file() {
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
    echo -e "\e[32mSetup Script \e[33m2.0\e[0m"
    PUT 10 0
    echo
    NORM
}

progress() {

    local pid=$!
    local delay=0.25
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do

        for i in "$(if test -e ${PWd}/${1}.iso; then cd ${PWd}/;du -h ${1}.iso | awk '{print $1}';else echo -e "\e[94m  \e[0m";fi)"
        do
            tput civis
            echo -ne "\033[34m\r[*] Downloading \e[1;33m${1}\e[34m	: \e[33m[\033[36m\033[32m$i\033[33m]\033[0m   ";
            sleep $delay
            printf "\b\b\b\b\b\b\b\b";
        done
    done
    printf "   \b\b\b\b"
    tput cnorm
    printf "\e[32m [\e[32m Done \e[32m]\e[0m";
    echo "";
}
spin22 () {
    HIDECURSOR(){ echo -en "\033[?25l";}
    NORM(){ echo -en "\033[?12l\033[?25h";}
    local pid=$!
    local delay=0.25
    local spinner=( '█■■■■' '■█■■■' '■■█■■' '■■■█■' '■■■■█' )

    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do

        for i in "${spinner[@]}"
        do
            HIDECURSOR
            echo -ne "\033[34m\r[*] "${3}" \e[1;33m${1}\e[34m 	: \e[33m[\033[32m$i\033[33m]\033[0m   ";
            sleep $delay
            printf "\b\b\b\b\b\b\b\b";
        done
    done
    printf "   \b\b\b\b\b\b"
    NORM
    printf "\e[32m [ ${2}]\e[0m";
    echo "";
}
check_internet () {

	echo -ne "\033[33m\r[*] \033[4;32mChecking Your Internet Connection... \e[0m"; 
	(ping -c 3 google.com) &> /dev/null 2>&1
    if [[ "$?" != 0 ]];then
	    echo -ne "\033[31m\r[*] \033[4;32mPlease Check Your Internet Connection... \e[0m"; 
	    sleep 1
	    exit 0
    fi
}
d_size () {
    stl3=$(curl -sIL "${ISO_URL}" | awk -F: '/content-length:/{sub("\r", "", $2); print $2}' | numfmt --to iec --format "%8.1f" | tail -1)
    (sleep 3) &> /dev/null & spin22 "${ALPINE_ISO}" ${stl3} "${szf}"
}

dowload_zip () {
    #yes | cp x* ${PWd}
    if [[ -f ${PWd}/${ALPINE_ISO}.iso ]] && [[ "$(cat ${PWd}/${x01} | awk '{print $1}')" == "$(sha256sum ${PWd}/${ALPINE_ISO}.iso|awk '{print $1}')" ]]; then
	    (sleep 1) &> /dev/null & spin22 "${ALPINE_ISO}" " \bDone " "Downloading"
    else
        (curl --fail --retry 3 --location --output ${PWd}/${ALPINE_ISO}.iso "${ISO_URL}" --silent) &> /dev/null & progress ${ALPINE_ISO};
    fi
    sleep 2
}
install_package () {
    (apt install root-repo && apt update && yes|apt install docker qemu-system-x86-64-headless qemu-common qemu-utils wget curl figlet openssh coreutils termux-api) &> /dev/null & spin22 "Packages" " \bDone " "Installing"
}
setup_qemu () {

# Remove existing QCOW2 image if present
[ -f $QCOW2_IMAGE ] && rm $QCOW2_IMAGE

# Remove existing QCOW2 image if present
[ -d "$SHARED_FOLDER" ] && rm -rf $SHARED_FOLDER
sleep 2
# Create a disk image for Alpine
qemu-img create -f qcow2 $QCOW2_IMAGE 10G &> /dev/null & spin22 "${QCOW2_IMAGE}" " \bDone " "virtual-drive" 

# Create shared folder if it doesn't exist
mkdir -p $SHARED_FOLDER
cp answers.txt docker_conf.sh $SHARED_FOLDER/
sleep 2
# Create Clickboard command
termux-clipboard-set "mkdir -p /mnt/vm-shared && mount -t 9p -o trans=virtio vm-shared /mnt/vm-shared && setup-alpine -f /mnt/vm-shared/answers.txt" &> /dev/null & spin22 "clipboard-set" " \bDone " "Copied" 

# Add Docker environment variable to ~/.profile if not present
if ! grep -q "DOCKER_HOST" "$DOCKER_HOST_ADD"; then
    echo "export DOCKER_HOST=\"tcp://localhost:2375\"" >> "$DOCKER_HOST_ADD"
fi

# Source ~/.profile based on the current shell
case "$SHELL" in
    *bash)
        if ! grep -q 'source "$HOME/.profile"' ~/.bashrc; then
            echo 'source "$HOME/.profile"' >> ~/.bashrc
        fi
        ;;
    *zsh)
        if ! grep -q 'source "$HOME/.profile"' ~/.zshrc; then
            echo 'source "$HOME/.profile"' >> ~/.zshrc
        fi
        ;;
    *)
        echo "Unsupported shell: $SHELL. Please source ~/.profile manually."
        ;;
esac
sleep 2
echo -e "\e[1;32m[*] \e[1;33mnow preparing installation ( wait 5-10 minutes )\e[1;0m"
sleep 2
# Start QEMU VM with Alpine ISO and disk image (background process)
qemu-system-x86_64 -machine q35 -m 2048M -smp cpus=4 -cpu qemu64 \
    -drive file=$QCOW2_IMAGE,if=virtio \
    -netdev user,id=n1,hostfwd=tcp::2222-:22,hostfwd=tcp::2375-:2375 \
    -device virtio-net,netdev=n1 \
    -virtfs local,path=$SHARED_FOLDER,mount_tag=vm-shared,security_model=mapped \
    -cdrom ${ALPINE_ISO}.iso \
    -boot d \
    -serial mon:stdio \
    -vga none \
    -display none 
}

#Print banner
banner "${PWd}/.object/fig_qemu.txt" "${PWd}/.object/qemu.txt" >> ${user}
cat "${user}"
check_internet
echo "";
install_package
d_size
dowload_zip
setup_qemu
