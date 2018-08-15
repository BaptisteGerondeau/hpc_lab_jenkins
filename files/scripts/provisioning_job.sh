#!/bin/bash

if [ "$#" -gt 15 ] || [ "$#" -lt 10 ]; then
	echo "Illegal number of arguments !"
	echo "provisioning_job.sh [WORKSPACE] [machine_name] [kernel_description] [initrd_description] [ansible_client_branch] [JENKINS_HOME] [preseed_name] [preseed_type] [machine_arch] [machine_subarch] kernel_options kernel_path initrd_path preseed_path -v"
	echo "[required] optional"
	exit 1
fi

if [ "${15}" == '-v' ]; then
	set -ex
fi

WORKSPACE=$1
machine_name=$2
kernel_desc=$3
initrd_desc=$4
branch=$5
JENKINS_HOME=$6
preseed_name=$7
preseed_type=$8
machine_arch=$9
machine_subarch=${10}
kernel_opts=${11}
kernel_path=${12}
initrd_path=${13}
preseed_path=${14}

cd ${WORKSPACE}

mname=$( echo $machine_name| cut -d',' -f 1)
DIR_NAME=${mname}$(date +%s)

echo "Provisioning ${mname} with ${kernel_desc} and ${intrd_desc}"
mkdir ${DIR_NAME}
cd ${DIR_NAME}

# TODO: provisioning.py needs this repo to work
# remove the need for the python script altogether
git clone -b ${branch} https://github.com/Linaro/ansible-role-mr-provisioner.git
provisioner_url=http://10.40.0.11:5000
provisioner_token=$(cat "/home/$(whoami)/mrp_token")

${JENKINS_HOME}/scripts/provisioning.py "${PWD}" "${machine_name}" "${provisioner_url}" "${provisioner_token}" "${kernel_desc}" "${initrd_desc}" "${preseed_name}" "${preseed_type}" "${machine_arch}" "${machine_subarch}" "${kernel_opts}" "${kernel_path}" "${initrd_path}" "${preseed_path}"

if [ ! -f hosts ]; then
	exit 1
fi

if [ ! -f provisioning${mname}.yml ]; then
	exit 1
fi

ansible-playbook provisioning${mname}.yml -i hosts --ssh-common-args="-o UserKnownHostsFile=/dev/null"
