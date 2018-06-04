#!/bin/bash

set -euo pipefail

archs=('x86_64')

user="${1}"
if [[ -z ${user} ]]; then
    user=${USER}
    if [[ ${EUID} -eq 0 ]]; then
        echo "Warning: You should specify a username as first argument or run \
the script as a normal user."
        echo "Some parts requires root access (like building the image and \
cleaning pacman's cache)."
        echo "If you plan to build automatically, run the script as root and \
give a normal username as first argument."
    fi
fi


# Clean local repository
echo "Cleaning local repository (as \"${user}\")"
cd repo && su ${user} -c './clean.sh'
cd ..

# Clean image folder
echo "Cleaning the image folder (as \"root\")"
cd iso && su -c './clean.sh'
cd ..

# Clean packages folder
echo "Cleaning packages folder (as \"${user}\")"
cd pkg && su ${user} -c './clean.sh'
cd ..

# Build custom packages.
echo "Building custom packages (as \"${user}\")"
cd pkg && su ${user} -c "./build.sh ${archs}"
if [ $? -ne 0 ]; then
	echo "Failed to build custom packages!"
	exit 1
fi
cd ..

# Build the custom local repository.
echo "Building the local repository (as \"${user}\")"
cd repo && su ${user} -c "./build.sh ${archs}"
if [ $? -ne 0 ]; then
	echo "Failed to build the custom local repository!"
	exit 1
fi
cd ..

# Build the latest Linux kernel and Nouveau DRM.
echo "Building Linux and Nouveau (as \"${user}\")"
cd src && su ${user} -c "./build.sh"
if [ $? -ne 0 ]; then
	echo "Failed to build the latest Linux kernel or Nouveau DRM!"
	exit 1
fi
cd ..

# Build the image.
echo "Building the image (as \"root\")"
cd iso && su -c "./build.sh -v ${archs}"
if [ $? -ne 0 ]; then
	echo "Failed to build the image!"
	exit 1
fi
cd ..

exit 0
