#!/bin/bash
set -x

helpmsg="machine_provision.sh -w [WORKSPACE] -m [machine_list] -t [machine_type] -j [job_type] -g [scripts_branch] -a [machine_arch] -s [machine_subarch] -o [kernel_opts] -k [kernel_desc] -i [initrd_desc] -p [preseed_name] -e [preseed_type] -y kernel_path -u initrd_path -i preseed_path -v -h"

while getopts "w:m:t:j:g:a:s:o:k:i:p:e:y:u:i:vh" flag ; do
	case "$flag" in
		w) WORKSPACE=$OPTARG;;
		m) machine_list=$OPTARG;;
		t) machine_type=$OPTARG;;
		j) job_type=$OPTARG;;
		g) scripts_branch=$OPTARG;;
		a) machine_arch=$OPTARG;;
		s) machine_subarch=$OPTARG;;
		o) kernel_opts=$OPTARG;;
		k) kernel_desc=$OPTARG;;
		i) initrd_desc=$OPTARG;;
		p) preseed_name=$OPTARG;;
		e) preseed_type=$OPTARG;;
		z) kernel_path=$OPTARG;;
		y) initrd_path=$OPTARG;;
		x) preseed_path=$OPTARG;;
		h ) echo $helpmsg
		    exit 0
		    ;;
		v ) set -ex ;;
		* ) echo 'Illegal Argument' && echo $helpmsg && exit 42 ;;
	esac
done

if [ ! -n $WORKSPACE ] || [ ! -n $machine_type ] || [ ! -n $scripts_branch ] || [ ! -n $job_type ] || [ ! -n $machine_arch ] || [ ! -n $machine_subarch ] || [ ! -n $kernel_opts ] || [ ! -n $kernel_desc ] || [ ! -n $initrd_desc ] || [ ! -n $initrd_desc ] || [ ! -n $preseed_name ] || [ ! -n $preseed_type ]; then
	echo "Missing Required Argument(s) !!!"
	echo $helpmsg
	exit 1
fi

if [ ! -d ${WORKSPACE} ]; then
	exit 2
fi

# Defaults
if [[ ${machine_list} == '' ]]; then
	machine_name="${machine_type}${job_type}"
else
	machine_list="$( echo "$machine_list"| tr -d '[:space:]')"
	machine_name=${machine_list}
fi
machine_arch=AArch64
machine_subarch=Grub

# Special cases
if [ "${machine_type}" == "d03" ]; then
    kernel_opts="${kernel_opts} earlycon console=ttyS0,115200"
else
    kernel_opts="${kernel_opts} earlycon console=ttyAMA0,115200"
fi

if [ "${machine_type}" == "qdc" ]; then
    machine_subarch=GrubWithOptionEfiboot
fi

# Build trigger file
cat << EOF > ${WORKSPACE}/mrp_provision
node="${machine_type}${job_type}"
scripts_branch=${scripts_branch}
machine_name=${machine_name}
machine_arch=${machine_arch}
machine_subarch=${machine_subarch}
kernel_opts=${kernel_opts}
kernel_desc=${kernel_desc}
initrd_desc=${initrd_desc}
preseed_name=${preseed_name}
preseed_type=${preseed_type}
kernel_path=${kernel_path}
initrd_path=${initrd_path}
preseed_path=${preseed_path}
EOF
