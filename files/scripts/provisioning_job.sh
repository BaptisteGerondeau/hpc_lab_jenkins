#!/bin/bash
set -x

helpmsg="provisioning_job.sh -w [WORKSPACE] -m [machine_name] -k [kernel_description] -i [initrd_description] -b [ansible_client_branch] -n [preseed_name] -t [preseed_type] -a [machine_arch] -s [machine_subarch] -o kernel_options -p kernel_path -y initrd_path -u preseed_path -v -h"

while getopts "w:m:k:i:b:n:t:a:s:o:p:y:u:hv" flag ; do
	case "$flag" in
		w) WORKSPACE=$OPTARG;;
		m) machine_name=$OPTARG;;
		k) kernel_desc=$OPTARG;;
		i) initrd_desc=$OPTARG;;
		b) branch=$OPTARG;;
		n) preseed_name=$OPTARG;;
		t) preseed_type=$OPTARG;;
		a) machine_arch=$OPTARG;;
		s) machine_subarch=$OPTARG;;
		o) kernel_opts=$OPTARG;;
		p) kernel_path=$OPTARG;;
		y) initrd_path=$OPTARG;;
		u) preseed_path=$OPTARG;;
		h ) echo $helpmsg
		    exit 0
		    ;;
		v ) set -ex ;;
		* ) echo 'Illegal Argument' && echo $helpmsg && exit 42 ;;
	esac
done
if [ ! -n $WORKSPACE ] || [ ! -n $machine_name ] || [ ! -n $kernel_desc ] || [ ! -n $initrd_desc ] || [ ! -n $branch ] || [ ! -n $preseed_name ] || [ ! -n $preseed_type ] || [ ! -n $machine_arch ] || [ ! -n $machine_subarch ]; then
	echo "Missing Required Argument !!!"
	echo $helpmsg
	exit 1
fi

if [ ! -d ${WORKSPACE} ]; then
	exit 2
fi

mname=$( echo $machine_name| cut -d',' -f 1)
DIR_NAME=${mname}$(date +%s)
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

echo "Provisioning ${mname} with ${kernel_desc} and ${intrd_desc}"
mkdir ${WORKSPACE}/${DIR_NAME}

# TODO: provisioning.py needs this repo to work
# remove the need for the python script altogether
git clone -b ${branch} https://github.com/Linaro/ansible-role-mr-provisioner.git ${WORKSPACE}/${DIR_NAME}/ansible-role-mr-provisioner
provisioner_url=http://10.40.0.11:5000
provisioner_token=$(cat "/home/$(whoami)/mrp_token")

${DIR}/provisioning.py "${WORKSPACE}/${DIR_NAME}" "${machine_name}" "${provisioner_url}" "${provisioner_token}" "${kernel_desc}" "${initrd_desc}" "${preseed_name}" "${preseed_type}" "${machine_arch}" "${machine_subarch}" "${kernel_opts}" "${kernel_path}" "${initrd_path}" "${preseed_path}"

if [ ! -f ${WORKSPACE}/${DIR_NAME}/hosts ]; then
	exit 1
fi

if [ ! -f ${WORKSPACE}/${DIR_NAME}/provisioning${mname}.yml ]; then
	exit 1
fi

eval `ssh-agent`
ssh-add

ansible-playbook ${WORKSPACE}/${DIR_NAME}/provisioning${mname}.yml -i ${WORKSPACE}/${DIR_NAME}/hosts --ssh-common-args="-o UserKnownHostsFile=/dev/null"

ssh-agent -k
