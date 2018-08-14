#!/bin/bash
set -ex


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
cat << EOF > mrp_provision
node="${machine_type}${job_type}"
joblogic_branch=${joblogic_branch}
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
