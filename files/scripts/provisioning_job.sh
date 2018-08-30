#!/bin/bash
set -x

helpmsg="provisioning_job.sh --workspace [WORKSPACE] --machine_name [machine_name] --kernel_desc [kernel_description] --initrd_desc [initrd_description] --branch [ansible_client_branch] --preseed_name [preseed_name] --preseed_type [preseed_type] --machine_arch [machine_arch] --machine_subarch [machine_subarch] --kernel_opts kernel_options --kernel_path kernel_path --initrd_path initrd_path --preseed_path preseed_path"

ARGUMENT_LIST=(
	"workspace"
	"machine_name"
	"kernel_desc"
	"initrd_desc"
	"branch"
	"preseed_name"
	"preseed_type"
	"machine_arch"
	"machine_subarch"
	"kernel_opts"
	"kernel_path"
	"initrd_path"
	"preseed_path"
)

. files/scripts/argparse.sh

if [ ! -n "${workspace}" ] || [ ! -n "${machine_name}" ] || [ ! -n "${kernel_desc}" ] || [ ! -n "${initrd_desc}" ] || [ ! -n "${branch}" ] || [ ! -n "${preseed_name}" ] || [ ! -n "${preseed_type}" ] || [ ! -n "${machine_arch}" ] || [ ! -n "${machine_subarch}" ]; then
	echo "Missing Required Argument"
	echo "${helpmsg}"
	exit 1
fi

if [ ! -d "${workspace}" ]; then
	exit 2
fi

mname=$( echo $machine_name| cut -d',' -f 1)
DIR_NAME=${mname}$(date +%s)
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

echo "Provisioning ${mname} with ${kernel_desc} and ${intrd_desc}"
mkdir "${workspace}/${DIR_NAME}"

# TODO: provisioning.py needs this repo to work
# remove the need for the python script altogether
git clone -b ${branch} https://github.com/Linaro/ansible-role-mr-provisioner.git "${workspace}/${DIR_NAME}/ansible-role-mr-provisioner"
provisioner_url=http://10.40.0.11:5000
provisioner_token=$(cat "/home/$(whoami)/mrp_token")

"${DIR}/provisioning.py" ""${workspace}"/${DIR_NAME}" "${machine_name}" "${provisioner_url}" "${provisioner_token}" "${kernel_desc}" "${initrd_desc}" "${preseed_name}" "${preseed_type}" "${machine_arch}" "${machine_subarch}" "${kernel_opts}" "${kernel_path}" "${initrd_path}" "${preseed_path}"

if [ ! -f "${workspace}/${DIR_NAME}/hosts" ] && [ ! -f "${workspace}/${DIR_NAME}/provisioning${mname}.yml" ]; then
	exit 1
fi

eval `ssh-agent`
ssh-add

ansible-playbook "${workspace}/${DIR_NAME}/provisioning${mname}.yml" -i "${workspace}/${DIR_NAME}/hosts" --ssh-common-args="-o UserKnownHostsFile=/dev/null"

ssh-agent -k
