#!/bin/bash

if [ "$#" -gt 6 ] || [ "$#" -lt 5 ]; then
	echo "Illegal number of arguments !"
	echo "os_provision.sh [WORKSPACE] [scripts_branch] [machine_type] [job_type] [os_type]"
	echo "[required] optional"
	exit 1
fi

if [ "$6" == '-v' ]; then
	set -ex
fi

WORKSPACE=$1
scripts_branch=$2
machine_type=$3
job_type=$4
os_type=$5

# Chose default OS
if [ "${os_type}" == "default" ]; then
  if [ "${job_type}" == "bench" ]; then
    os_type=debian
  elif [ "${job_type}" == "ohpc" ]; then
    os_type=centos
    if [ "${machine_type}" == "qdc" ]; then
	os_type=centos-upstream
    fi
  else
    echo "Not Implemented Yet!!!!"
  fi
fi

# Chose known good kernel/initrd/cmdline
if [ "${os_type}" == "debian" ]; then
  preseed_type="preseed"
  kernel_desc="Debian ERP 18.06"
  initrd_desc="Debian ERP 18.06"
  preseed_name="Debian"
  kernel_opts=
elif [ "${os_type}" == "centos" ]; then
  preseed_type="kickstart"
  kernel_desc="CentOS ERP 18.06"
  initrd_desc="CentOS ERP 18.06"
  preseed_name="CentOS"
  kernel_opts="ip=dhcp text inst.stage2=http://10.40.0.13/releases.linaro.org/reference-platform/enterprise/18.06/centos-installer/ inst.repo=http://10.40.0.13/mirror.centos.org/altarch/7/os/aarch64/ inst.ks=file:/ks.cfg"
elif [ "${os_type}" == "centos-upstream" ]; then
  preseed_type="kickstart"
  kernel_desc="CentOS 7.5"
  initrd_desc="CentOS 7.5"
  preseed_name="CentOS Upstream"
  kernel_opts="ip=dhcp text inst.stage2=http://10.40.0.13/mirror.centos.org/altarch/7/os/aarch64/ inst.repo=http://10.40.0.13/mirror.centos.org/altarch/7/os/aarch64/ inst.ks=file:/ks.cfg"
else
  echo "Not Implemented Yet!!!!"
fi

# Special options for special machines
if [ "${machine_type}" == "d03" ]; then
  kernel_opts="$kernel_opts modprobe.blacklist=hibmc_drm"
fi

cd ${WORKSPACE}
# Build trigger machine_provision job
cat << EOF > machine_provision
scripts_branch=${scripts_branch}
machine_type=${machine_type}
job_type=${job_type}
kernel_desc=${kernel_desc}
initrd_desc=${initrd_desc}
preseed_name=${preseed_name}
preseed_type=${preseed_type}
kernel_opts=${kernel_opts}
kernel_path=
initrd_path=
preseed_path=
EOF
