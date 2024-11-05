#!/bin/bash

# Check if username and password are provided as arguments
if [[ -z "$1" || -z "$2" ]]; then
  echo "Usage: $0 <username> <password>"
  exit 1
fi

# Assign command-line arguments to variables
username="$1"
password="$2"

# URL-encode username and password
urle () { [[ "${1}" ]] || return 1; local LANG=C i x; for (( i = 0; i < ${#1}; i++ )); do x="${1:i:1}"; [[ "${x}" == [a-zA-Z0-9.~-] ]] && echo -n "${x}" || printf '%%%02X' "'${x}"; done; echo; }
username=$(urle "$username")
password=$(urle "$password")

# Download SHAPY data
wget --post-data "username=$username&password=$password" 'https://download.is.tue.mpg.de/download.php?domain=shapy&resume=1&sfile=shapy_data.zip' -O 'shapy_data.zip' --no-check-certificate --continue
unzip shapy_data.zip
rm shapy_data.zip

# Download SMPL model
wget --post-data "username=$username&password=$password" 'https://download.is.tue.mpg.de/download.php?domain=smplx&sfile=models_smplx_v1_1.zip&resume=1' -O 'models_smplx_v1_1.zip' --no-check-certificate --continue
unzip models_smplx_v1_1.zip
mv models body_models
rm models_smplx_v1_1.zip
