#!/bin/bash

if [ "$#" -gt 6 ] || [ "$#" -lt 5 ]; then
	echo "Illegal number of arguments !"
	echo "ohpc_install.sh [WORKSPACE] [git_branch] [node] [method] slurmconf -v" 
	echo "[required] optional"
	exit 1
fi

if [ "$6" == '-v' ]; then
	set -ex
fi

WORKSPACE=$1
git_branch=$2
node=$3
method=$4
slurmconf=$5


cd ${WORKSPACE}
eval `ssh-agent`
ssh-add
	
if [ -d mr-provisioner-client ]; then
    rm -rf mr-provisioner-client
fi
git clone https://github.com/Linaro/mr-provisioner-client.git
arch='aarch64'
mr_provisioner_url='http://10.40.0.11:5000'
mr_provisioner_token=$(cat "/home/$(whoami)/mrp_token")

if [ ${node} == 'qdcohpc' ]; then
	master_name='qdcohpc'
	cnode01='qdc01'
	cnode02='qdc02'
	cnode03='qdc03'
	master_eth_internal='eth0'
	eth_provision='eth0'
	num_compute='3'
	master_ip=$( ./mr-provisioner-client/mrp_client.py getip qdcohpc --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
	cnode01ip=$( ./mr-provisioner-client/mrp_client.py getip qdc01 --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
	cnode01mac=$( ./mr-provisioner-client/mrp_client.py getmac qdc01 --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
	cnode02ip=$( ./mr-provisioner-client/mrp_client.py getip qdc02 --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
	cnode02mac=$( ./mr-provisioner-client/mrp_client.py getmac qdc02 --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
	cnode03ip=$( ./mr-provisioner-client/mrp_client.py getip qdc03 --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
	cnode03mac=$( ./mr-provisioner-client/mrp_client.py getmac qdc03 --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
	compute_prefix='qdc0'
	compute_regex='qdc0[1-3]'
	kargs=''
	additional_modules='qcom_emac'
elif [ ${node} == 'd05ohpc' ]; then
	master_name='d05ohpc'
	cnode01='d0301'
	cnode02='d0302'
	cnode03='d0303'
	master_eth_internal='enahisic2i1'
	eth_provision='enahisic2i1'
	num_compute='3' 
	master_ip=$( ./mr-provisioner-client/mrp_client.py getip d05ohpc --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
	cnode01ip=$( ./mr-provisioner-client/mrp_client.py getip d0301 --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
	cnode01mac=$( ./mr-provisioner-client/mrp_client.py getmac d0301 --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
	cnode02ip=$( ./mr-provisioner-client/mrp_client.py getip d0302 --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
	cnode02mac=$( ./mr-provisioner-client/mrp_client.py getmac d0302 --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
	cnode03ip=$( ./mr-provisioner-client/mrp_client.py getip d0303 --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
	cnode03mac=$( ./mr-provisioner-client/mrp_client.py getmac d0303 --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
	compute_prefix='d030'
	compute_regex='d030[1-3]'
	kargs=''
fi

if [ ${method} == 'stateful' ]; then
	internal_network='10.40.0.0'
	internal_netmask='255.255.0.0'
	internal_broadcast='10.40.255.255'
	internal_gateway='10.40.0.1'
	internal_dns=${internal_gateway}
	internal_domain_name=''
	# Enable components optionis
	enable_beegfs_client=False
	enable_mpi_defaults=True
	enable_mpi_opa=False
	enable_clustershell=True
	enable_ipmisol=False
	enable_opensm=False
	enable_ipoib=False
	enable_ganglia=False
	enable_genders=False
	enable_kargs=False
	enable_lustre_client=False
	enable_mrsh=False
	enable_nagios=False
	enable_powerman=False
	enable_intel_packages=False
	enable_dhcpd_server=False
	enable_ifup=False
	enable_warewulf=False
	enable_nfs_ohpc=True
	enable_nfs_home=True
	enable_helloworld=True

else
	echo 'Not implemented yet !!'
fi

if [ -d ansible-playbook-for-ohpc ]; then
    rm -rf ansible-playbook-for-ohpc
fi
git clone -b ${git_branch} https://github.com/Linaro/ansible-playbook-for-ohpc.git


# Retrieve the slurm.conf file
if [ ${slurmconf} != '' ]; then
	olddir=$(pwd)
	cd ansible-playbook-for-ohpc/roles/slurm-client/files
	sftp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no 10.40.0.13:${slurmconf}
	mv $(basename ${slurmconf}) slurm.conf
	cd ${olddir}
fi

cat << EOF > hosts
[sms]
${master_ip}
[cnodes]
${cnode01ip}
${cnode02ip}
${cnode03ip}
[ionodes]
${master_ip}
[devnodes]
${master_ip}
EOF


cat << EOF > ohpc_installation.yml
sms_name: ${master_name}
sms_ip: ${master_ip}
sms_eth_internal: ${master_eth_internal}
internal_network: ${internal_network}
internal_netmask: ${internal_netmask}
internal_broadcast: ${internal_broadcast}
internal_gateway: ${internal_gateway}
internal_domain_name: ${internal_domain_name}
internal_domain_name_servers: ${internal_dns}
eth_provision: ${eth_provision}
cnode_eth_internal: ${eth_provision}
enable_beegfs_client: ${enable_beegfs_client}
enable_mpi_defaults: ${enable_mpi_defaults} 
enable_mpi_opa: ${enable_mpi_opa}
enable_clustershell: ${enable_clustershell}
enable_ipmisol: ${enable_ipmisol}
enable_opensm: ${enable_opensm}
enable_ipoib: ${enable_ipoib}
enable_ganglia: ${enable_ganglia}
enable_genders: ${enable_genders}
enable_kargs: ${enable_kargs}
enable_lustre_client: ${enable_lustre_client}
enable_mrsh: ${enable_mrsh}
enable_nagios: ${enable_nagios}
enable_powerman: ${enable_powerman}
enable_intel_packages: ${enable_intel_packages}
enable_dhcpd_server: ${enable_dhcpd_server}
enable_ifup: ${enable_ifup}
enable_warewulf: ${enable_warewulf}
enable_nfs_ohpc: ${enable_nfs_ohpc}
enable_nfs_home: ${enable_nfs_home}
enable_helloworld: ${enable_helloworld}
kargs: ${kargs}
additional_modules: ${additional_modules}
num_computes: ${num_compute}
compute_regex: ${compute_regex}
compute_prefix: ${compute_prefix}
compute_nodes:
- { num: 1, c_name: "${cnode01}", c_ip: "${cnode01ip}", c_mac: "${cnode01mac}", c_bmc: "10.41.1.0"}
- { num: 2, c_name: "${cnode02}", c_ip: "${cnode02ip}", c_mac: "${cnode02mac}", c_bmc: "10.41.1.0"}
- { num: 3, c_name: "${cnode03}", c_ip: "${cnode03ip}", c_mac: "${cnode03mac}", c_bmc: "10.41.1.0"}
EOF

cd ansible-playbook-for-ohpc
ansible-playbook site.yml --extra-vars="@../ohpc_installation.yml" -i ../hosts

ssh-agent -k 
