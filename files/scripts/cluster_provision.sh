#!/bin/bash
set -ex

helpmsg="cluster_provision.sh --workspace [workspace] --machine_type [machine_type] --machine_list [machine_list] --preseed_type [preseed_type] --kernel_desc [kernel_desc] --initrd_desc [initrd_desc] --preseed_name [preseed_name] --kernel_opts [kernel_opts] --scripts_branch [scripts_branch]"
ARGUMENT_LIST=(
	"workspace"
	"machine_type"
	"machine_list"
	"preseed_type"
	"kernel_desc"
	"initrd_desc"
	"preseed_name"
	"kernel_opts"
	"scripts_branch"
)

. files/scripts/argparse.sh

if [ ! -n "${workspace}" ] || [ ! -n "${machine_type}" ] || [ ! -n "${machine_list}" ] || [ ! -n "${preseed_type}" ] || [ ! -n "${kernel_desc}" ] || [ ! -n "${initrd_desc}" ] || [ ! -n "${preseed_name}" ] || [ ! -n "${kernel_opts}" ] || [ ! -n "${scripts_branch}" ]; then
	echo "Missing Required Argument(s)"
	echo "${helpmsg}"
	exit 1
fi

if [ ! -d "${workspace}" ]; then
	exit 2
fi

# Build trigger machine_provision job
cat << EOF > "${workspace}/machine_provision"
scripts_branch=${scripts_branch}
machine_list=${machine_list}
machine_type=${machine_type}
job_type=ohpc
kernel_desc=${kernel_desc}
initrd_desc=${initrd_desc}
preseed_name=${preseed_name}
preseed_type=${preseed_type}
kernel_opts=${kernel_opts}
kernel_path=
initrd_path=
preseed_path=
EOF
