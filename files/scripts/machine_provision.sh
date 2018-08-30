#!/bin/bash
set -x

helpmsg="machine_provision.sh --workspace [workspace] --machine_list [machine_list] --machine_type [machine_type] --job_type [job_type] --scripts_branch [scripts_branch] --machine_arch [machine_arch] --machine_subarch [machine_subarch] --kernel_opts [kernel_opts] --kernel_desc [kernel_desc] --initrd_desc [initrd_desc] --preseed_name [preseed_name] --preseed_type [preseed_type] --kernel_path kernel_path --initrd_path initrd_path --preseed_path preseed_path --v(erbose) --h(elp)"

ARGUMENT_LIST=(
	"workspace"
	"machine_list"
	"machine_type"
	"job_type"
	"scripts_branch"
	"machine_arch"
	"machine_subarch"
	"kernel_opts"
	"kernel_desc"
	"initrd_desc"
	"preseed_name"
	"preseed_type"
	"kernel_path"
	"initrd_path"
	"preseed_path"
)

. files/scripts/argparse.sh

if [ $help == True ]; then
	echo $helpmsg
	exit 0
elif [ $verbose == True ]; then
	set -ex
fi


if [ ! -n $workspace ] || [ ! -n $machine_list ] || [ ! -n $machine_type ] || [ ! -n $scripts_branch ] || [ ! -n $job_type ] || [ ! -n $machine_arch ] || [ ! -n $machine_subarch ] || [ ! -n $kernel_opts ] || [ ! -n $kernel_desc ] || [ ! -n $initrd_desc ] || [ ! -n $initrd_desc ] || [ ! -n $preseed_name ] || [ ! -n $preseed_type ]; then
	echo "Missing Required Argument(s) !!!"
	echo $helpmsg
	exit 1
fi

if [ ! -d ${workspace} ]; then
	exit 2
fi

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

# Build trigger file
cat << EOF > ${workspace}/mrp_provision
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
