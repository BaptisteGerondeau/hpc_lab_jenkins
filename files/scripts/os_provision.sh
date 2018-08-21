#!/bin/bash
set -x

helpmsg="os_provision.sh -w [WORKSPACE] -s [scripts_branch] -m [machine_type] -j [job_type] -o [os_type] -h -v"

if [ "$#" -gt 11 ] || [ "$#" -lt 10 ]; then
	echo "Illegal number of arguments !"
	echo $helpmsg 
	echo "[required] optional"
	exit 1
fi

while getopts "w:s:m:j:o:hv" flag ; do
	case "$flag" in
		w) WORKSPACE=$OPTARG;;
		s) scripts_branch=$OPTARG;;
		m) machine_type=$OPTARG;;
		j) job_type=$OPTARG;;
		o) os_type=$OPTARG;;
		h ) echo $helpmsg
		    exit 0
		    ;;
		v ) set -ex ;;
		* ) exit 69 ;;
	esac
done
if [ ! -n $WORKSPACE ] || [ ! -n $scripts_branch ] || [ ! -n $machine_type ] || [ ! -n $job_type ] || [ ! -n $os_type ]; then 
	echo "MISSING REQUIRED ARGUMENTS !!!"
	echo $helpmsg
fi

if [ ! -d ${WORKSPACE} ]; then
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

# Build trigger machine_provision job
cat << EOF > ${WORKSPACE}/machine_provision
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
