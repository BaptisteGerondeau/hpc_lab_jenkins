#!/bin/bash
set -x

helpmsg="cluster_provision.sh -w [WORKSPACE] -t [machine_type] -g [scripts_branch] -v -h" 

while getopts "w:t:g:vh" flag ; do
	case "$flag" in
		w) WORKSPACE=$OPTARG;;
		t) machine_type=$OPTARG;;
		g) scripts_branch=$OPTARG;;
		h ) echo $helpmsg
		    exit 0
		    ;;
		v ) set -ex ;;
		* ) exit 69 ;;
	esac
done

if [ ! -n $WORKSPACE ] || [ ! -n $machine_type ] || [ ! -n $scripts_branch ]; then
	echo "MISSING REQUIRED ARGUMENTS !!!"
	echo $helpmsg
	exit 1
fi

if [ ! -d ${WORKSPACE} ]; then
	exit 2
fi

if [ ${machine_type} == "qdc" ]; then
	machine_list="qdcohpc, qdc01, qdc02, qdc03"
	preseed_type="kickstart"
	kernel_desc="CentOS 7.5"
	initrd_desc="CentOS 7.5"
	preseed_name="CentOS Upstream"
	kernel_opts="ip=dhcp text inst.stage2=http://mirror.centos.org/altarch/7/os/aarch64/ inst.repo=http://mirror.centos.org/altarch/7/os/aarch64/ inst.ks=file:/ks.cfg"
elif [ ${machine_type} == "d05" ]; then
	machine_list="d05ohpc, d0301, d0302, d0303"
	preseed_type="kickstart"
	kernel_desc="CentOS ERP 18.06"
	initrd_desc="CentOS ERP 18.06"
	preseed_name="CentOS"
	kernel_opts="ip=dhcp text inst.stage2=http://releases.linaro.org/reference-platform/enterprise/18.06/centos-installer/ inst.repo=http://mirror.centos.org/altarch/7/os/aarch64/ inst.ks=file:/ks.cfg"
fi

# Chose known good kernel/initrd/cmdline

# Build trigger machine_provision job
cat << EOF > ${WORKSPACE}/machine_provision
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
