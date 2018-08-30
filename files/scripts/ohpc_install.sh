#!/bin/bash
set -x

helpmsg="ohpc_install.sh --workspace [workspace] --git_branch [git_branch] --mrp_branch [mrp_branch] --node [node] --method [method] --slurmconf slurmconf --v(erbose) --h(elp)" 

ARGUMENT_LIST=(
	"workspace"
	"git_branch"
	"mrp_branch"
	"node"
	"method"
	"slurmconf"
)

. files/scripts/argparse.sh

if [ $help == True ]; then
	echo $helpmsg
	exit 0
elif [ $verbose == True ]; then
	set -ex
fi


if [ ! -n $workspace ] || [ ! -n $git_branch ] || [ ! -n $node ] || [ ! -n $method ]; then
	echo "Missing Required Arguments !!!"
	echo $helpmsg
fi

if [ ! -d ${workspace} ]; then
	exit 2
fi

if [ -d ${workspace}/mr-provisioner-client ]; then
    rm -rf ${workspace}/mr-provisioner-client
fi

git clone -b ${mrp_branch} https://github.com/Linaro/mr-provisioner-client.git ${workspace}/mr-provisioner-client

arch='aarch64'
mr_provisioner_url='http://10.40.0.11:5000'
mr_provisioner_token=$(cat "/home/$(whoami)/mrp_token")

# BMC IP is a parameter for Warewulf conf. Warewulf doesn't have to touch them, so dummy IP.
cnode01bmc="10.41.0.0"
cnode02bmc=$cnode01bmc
cnode03bmc=$cnode01bmc

if [ ${node} == 'qdcohpc' ]; then
	master_name='qdcohpc'
	cnode01='qdc01'
	cnode02='qdc02'
	cnode03='qdc03'
	master_eth_internal='eth0'
	eth_provision='eth0'
	num_compute='3'
	master_ip=$( ${workspace}/mr-provisioner-client/mrp_client.py getip qdcohpc --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
	cnode01ip=$( ${workspace}/mr-provisioner-client/mrp_client.py getip qdc01 --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
	cnode01mac=$( ${workspace}/mr-provisioner-client/mrp_client.py getmac qdc01 --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
	cnode02ip=$( ${workspace}/mr-provisioner-client/mrp_client.py getip qdc02 --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
	cnode02mac=$( ${workspace}/mr-provisioner-client/mrp_client.py getmac qdc02 --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
	cnode03ip=$( ${workspace}/mr-provisioner-client/mrp_client.py getip qdc03 --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
	cnode03mac=$( ${workspace}/mr-provisioner-client/mrp_client.py getmac qdc03 --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
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
	master_ip=$( ${workspace}/mr-provisioner-client/mrp_client.py getip d05ohpc --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
	cnode01ip=$( ${workspace}/mr-provisioner-client/mrp_client.py getip d0301 --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
	cnode01mac=$( ${workspace}/mr-provisioner-client/mrp_client.py getmac d0301 --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
	cnode02ip=$( ${workspace}/mr-provisioner-client/mrp_client.py getip d0302 --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
	cnode02mac=$( ${workspace}/mr-provisioner-client/mrp_client.py getmac d0302 --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
	cnode03ip=$( ${workspace}/mr-provisioner-client/mrp_client.py getip d0303 --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
	cnode03mac=$( ${workspace}/mr-provisioner-client/mrp_client.py getmac d0303 --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
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

if [ -d ${workspace}/ansible-playbook-for-ohpc ]; then
    rm -rf ${workspace}/ansible-playbook-for-ohpc
fi
git clone -b ${git_branch} https://github.com/Linaro/ansible-playbook-for-ohpc.git ${workspace}/ansible-playbook-for-ohpc


# Retrieve the slurm.conf file
if [ ${slurmconf} != '' ]; then
	olddir=$(pwd)
	cd ${workspace}/ansible-playbook-for-ohpc/roles/slurm-client/files
	sftp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no 10.40.0.13:${slurmconf}
	mv $(basename ${slurmconf}) slurm.conf
	cd ${olddir}
fi

cat << EOF > ${workspace}/hosts
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


cat << EOF > ${workspace}/ohpc_installation.yml
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
- { num: 1, c_name: "${cnode01}", c_ip: "${cnode01ip}", c_mac: "${cnode01mac}", c_bmc: "${cnode01bmc}"}
- { num: 2, c_name: "${cnode02}", c_ip: "${cnode02ip}", c_mac: "${cnode02mac}", c_bmc: "${cnode02bmc}"}
- { num: 3, c_name: "${cnode03}", c_ip: "${cnode03ip}", c_mac: "${cnode03mac}", c_bmc: "${cnode03bmc}"}
EOF

eval `ssh-agent`
ssh-add
	
ansible-playbook ${workspace}/ansible-playbook-for-ohpc/site.yml --extra-vars="@${workspace}/ohpc_installation.yml" -i ${workspace}/hosts

ssh-agent -k 
