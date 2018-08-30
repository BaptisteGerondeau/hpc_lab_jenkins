#!/bin/bash
set -x

helpmsg="cluster_provision.sh --workspace [workspace] --machine_type [machine_type] --scripts_branch [scripts_branch] --v(erbose) --h(elp)" 
ARGUMENT_LIST=(
	"workspace"
	"machine_type"
	"scripts_branch"
)

. files/scripts/argparse.sh

if [ $help == True ]; then
	echo $helpmsg
	exit 0
elif [ $verbose == True ]; then
	set -ex
fi


if [ ! -n $workspace ] || [ ! -n $machine_type ] || [ ! -n $scripts_branch ]; then
	echo "Missing Required Argument(s) !!!"
	echo $helpmsg
	exit 1
fi

if [ ! -d ${workspace} ]; then
	exit 2
fi

# Chose known good kernel/initrd/cmdline
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

# Build trigger machine_provision job
cat << EOF > ${workspace}/machine_provision
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
