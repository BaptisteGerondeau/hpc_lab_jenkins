#!/bin/bash
set -ex

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
cat << EOF > machine_provision
machine_list=${machine_list}
os_type=${os_type}
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
