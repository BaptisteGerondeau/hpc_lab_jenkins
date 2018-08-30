#!/bin/bash
set -ex

helpmsg="os_provision.sh --workspace [WORKSPACE] --scripts_branch [scripts_branch] --machine_type [machine_type] --job_type [job_type] --os_type [os_type]"

ARGUMENT_LIST=(
	"workspace"
	"scripts_branch"
	"machine_type"
	"job_type"
	"os_type"
)

. files/scripts/argparse.sh

if [ ! -n "${workspace}" ] || [ ! -n "${scripts_branch}" ] || [ ! -n "${machine_type}" ] || [ ! -n "${job_type}" ] || [ ! -n "${os_type}" ]; then 
	echo "Missing Required Arguments"
	echo "${helpmsg}"
fi

if [ ! -d "${workspace}" ]; then
	exit 2
fi

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
    echo "Not Implemented Yet"
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
  echo "Not Implemented Yet"
fi

# Special options for special machines
if [ "${machine_type}" == "d03" ]; then
  kernel_opts="${kernel_opts} modprobe.blacklist=hibmc_drm"
fi

# Build trigger machine_provision job
cat << EOF > ${workspace}/machine_provision
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
