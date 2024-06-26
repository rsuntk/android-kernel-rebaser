#!/usr/bin/env bash

#
# Rissu changes on June 4 2024: Make it without
# cloning OEM source. Just rebase it where the script
# running, which is on the top of kernel tree
#

# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
NORMAL='\033[0m'

# Detect kernel tree
if [ ! -d $(pwd)/drivers ] && [ ! -d $(pwd)/kernel ] && [ ! -d $(pwd)/net ]; then
	printf "${RED}Invalid kernel tree${NORMAL}\n"
 	exit 1;
fi

# Project Directory
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

# Variables
ACK_REPO="https://android.googlesource.com/kernel/common.git"
ACK_BRANCH=${1}

# Help Function
usage() {
	echo -e "${0} \"ack-branch\"
	>> eg: ${0} \"android-4.9-q\""
}

if [ $# != 1 ]; then
	usage;
 	exit 1;
fi

# Abort Function
abort() {
	[ ! -z "${@}" ] && echo -e ${RED}"${@}"${NORMAL}
	exit 1
}

# Clone the Android Common Kernel Source
git clone --single-branch -b ${ACK_BRANCH} ${ACK_REPO} kernel_rebased

# Get the OEM Kernel's Version
OEM_KERNEL_VERSION=$(make kernelversion)

# Hard Reset ACK to ${OEM_KERNEL_VERSION}
cd kernel_rebased
OEM_KERNEL_VER_SHORT_SHA=$(git log --oneline ${ACK_BRANCH} Makefile | grep -i ${OEM_KERNEL_VERSION} | grep -i merge | cut -d ' ' -f1)
git reset --hard ${OEM_KERNEL_VER_SHORT_SHA}
cd -

# Get the list of Directories of the OEM Kernel
OEM_DIR_LIST=$(find -type d -printf "%P\n" | grep -v / | grep -v .git)

# Start Rebasing
cd kernel_rebased
for i in ${OEM_DIR_LIST}; do
	rm -rf ${i}
done

cd -
cp -r $(pwd)/* kernel_rebased/
cd kernel_rebased

# ensure kernel_rebased/ folder is not included into kernel_rebased/ folder!
if [ -d $(pwd)/kernel_rebased ]; then
	rm $(pwd)/kernel_rebased -f
fi

for i in ${OEM_DIR_LIST}; do
	git add ${i}
	git commit -s -m "${i}: Import OEM Changes"
done

git add .
git commit -s -m "Import Remaining OEM Changes"

cd -

echo -e ${GREEN}"Your Kernel has been successfully rebased to ACK. Please check kernel/"${NORMAL}

# Exit
exit 0
