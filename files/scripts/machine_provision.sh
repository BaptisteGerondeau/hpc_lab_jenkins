#!/bin/bash

if [ "$#" -gt 16 ] || [ "$#" -lt 12 ]; then
	echo "Illegal number of arguments !"
	echo "machine_provision.sh [WORKSPACE] [machine_list] [machine_type] [job_type] [scripts_branch] [machine_arch] [machine_subarch] [kernel_opts] [kernel_desc] [initrd_desc] [preseed_name] [preseed_type] kernel_path initrd_path preseed_path -v"
	echo "[required] optional"
	exit 1
fi

if [ "${16}" == '-v' ]; then
	set -ex
fi

WORKSPACE=$1
machine_list=$2
machine_type=$3
job_type=$4
scripts_branch=$5
machine_arch=$6
machine_subarch=$7
kernel_opts=$8
kernel_desc=$9
initrd_desc=${10}
preseed_name=${11}
preseed_type=${12}
kernel_path=${13}
initrd_path=${14}
preseed_path=${15}

# Defaults
if [[ ${machine_list} == '' ]]; then
	machine_name="${machine_type}${job_type}"
else
	machine_list="$( echo "$machine_list"| tr -d '[:space:]')"
	machine_name=${machine_list}
fi
machine_arch=AArch64
machine_subarch=Grub

# Special cases
if [ "${machine_type}" == "d03" ]; then
    kernel_opts="${kernel_opts} earlycon console=ttyS0,115200"
else
    kernel_opts="${kernel_opts} earlycon console=ttyAMA0,115200"
fi

if [ "${machine_type}" == "qdc" ]; then
    machine_subarch=GrubWithOptionEfiboot
fi

cd ${WORKSPACE}
# Build trigger file
cat << EOF > mrp_provision
node="${machine_type}${job_type}"
scripts_branch=${scripts_branch}
machine_name=${machine_name}
machine_arch=${machine_arch}
machine_subarch=${machine_subarch}
kernel_opts=${kernel_opts}
kernel_desc=${kernel_desc}
initrd_desc=${initrd_desc}
preseed_name=${preseed_name}
preseed_type=${preseed_type}
kernel_path=${kernel_path}
initrd_path=${initrd_path}
preseed_path=${preseed_path}
EOF
