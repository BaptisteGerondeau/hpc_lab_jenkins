#!/bin/bash
set -ex

helpmsg="machine_provision.sh --workspace [workspace] --machine_name [machine_name] --node [node] --scripts_branch [scripts_branch] --machine_arch [machine_arch] --machine_subarch [machine_subarch] --kernel_opts [kernel_opts] --kernel_desc [kernel_desc] --initrd_desc [initrd_desc] --preseed_name [preseed_name] --preseed_type [preseed_type] --kernel_path kernel_path --initrd_path initrd_path --preseed_path preseed_path"

ARGUMENT_LIST=(
	"workspace"
	"machine_name"
	"node"
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

if [ ! -n "${workspace}" ] || [ ! -n "${machine_name}" ] || [ ! -n "${scripts_branch}" ] || [ ! -n "${node}" ] || [ ! -n "${machine_arch}" ] || [ ! -n "${machine_subarch}" ] || [ ! -n "${kernel_opts}" ] || [ ! -n "${kernel_desc}" ] || [ ! -n "${initrd_desc}" ] || [ ! -n "${preseed_name}" ] || [ ! -n "${preseed_type}" ]; then
	echo "Missing Required Argument(s)"
	echo ${helpmsg}
	exit 1
fi

if [ ! -d "${workspace}" ]; then
	exit 2
fi

# Build trigger file
cat << EOF > "${workspace}/mrp_provision"
node=${node}
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
