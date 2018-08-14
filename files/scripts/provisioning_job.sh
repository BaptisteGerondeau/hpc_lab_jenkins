#!/bin/bash
set -ex


 cd ${WORKSPACE}
 mname=$( echo $machine_name| cut -d',' -f 1)
 echo "Provisioning ${mname} with ${kernel_desc} and ${intrd_desc}"
 DIR_NAME=${mname}$(date +%s)
 mkdir ${DIR_NAME}
 cd ${DIR_NAME}
 # TODO: provisioning.py needs this repo to work
 # remove the need for the python script altogether
 git clone -b ${branch} https://github.com/Linaro/ansible-role-mr-provisioner.git
 provisioner_url=http://10.40.0.11:5000
 provisioner_token=$(cat "/home/${NODE_NAME}/mrp_token")
 ${JENKINS_HOME}/scripts/provisioning.py "${PWD}" "${machine_name}" "${provisioner_url}" "${provisioner_token}" "${kernel_desc}" "${initrd_desc}" "${preseed_name}" "${preseed_type}" "${machine_arch}" "${machine_subarch}" "${kernel_opts}" "${kernel_path}" "${initrd_path}" "${preseed_path}"
 if [ ! -f hosts ]; then
	exit 1
 fi
 if [ ! -f provisioning${mname}.yml ]; then
	exit 1
 fi

 ansible-playbook provisioning${mname}.yml -i hosts --ssh-common-args="-o UserKnownHostsFile=/dev/null"
