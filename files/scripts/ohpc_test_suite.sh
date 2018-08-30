#!/bin/bash
set -ex

helpmsg="ohpc_install.sh --workspace [workspace] --node [node] --method [method] --test_type [test_type] --mrp_branch [mrp_branch] --ansible_ohpc_branch [ansible_ohpc_branch] --h(elp) --v(erbose)" 

ARGUMENT_LIST=(
	"workspace"
	"ansible_ohpc_branch"
	"mrp_branch"
	"node"
	"method"
	"test_type"
)

. files/scripts/argparse.sh

if [ ! -n "${workspace}" ] || [ ! -n "${ansible_ohpc_branch}" ] || [ ! -n "${node}" ] || [ ! -n "${method}" ] || [ ! -n "${test_type}" ] || [ ! -n "${mrp_branch}" ]; then
	echo "Missing Required Arguments"
	echo $helpmsg
fi

if [ ! -d "${workspace}" ]; then
	exit 2
fi

if [ -d "${workspace}/mr-provisioner-client" ]; then
    rm -rf "${workspace}/mr-provisioner-client"
fi
git clone -b ${mrp_branch} https://github.com/Linaro/mr-provisioner-client.git "${workspace}/mr-provisioner-client"
arch='aarch64'
mr_provisioner_url='http://10.40.0.11:5000'
mr_provisioner_token=$(cat "/home/$(whoami)/mrp_token")

if [ ${node} == 'qdcohpc' ]; then
	master_name='qdcohpc'
	cnode01='qdc01'
	cnode02='qdc02'
	cnode03='qdc03'
	num_compute='3'
	master_ip=$( "${workspace}/mr-provisioner-client/mrp_client.py" getip qdcohpc --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
	cnode01ip=$( "${workspace}/mr-provisioner-client/mrp_client.py" getip qdc01 --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
	cnode02ip=$( "${workspace}/mr-provisioner-client/mrp_client.py" getip qdc02 --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
	cnode03ip=$( "${workspace}/mr-provisioner-client/mrp_client.py" getip qdc03 --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
	compute_regex='qdc0[1-3]'
elif [ ${node} == 'd05ohpc' ]; then
	master_name='d05ohpc'
	cnode01='d0301'
	cnode02='d0302'
	cnode03='d0303'
	num_compute='3' 
	master_ip=$( "${workspace}/mr-provisioner-client/mrp_client.py" getip d05ohpc --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
	cnode01ip=$( "${workspace}/mr-provisioner-client/mrp_client.py" getip d0301 --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
	cnode02ip=$( "${workspace}/mr-provisioner-client/mrp_client.py" getip d0302 --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
	cnode03ip=$( "${workspace}/mr-provisioner-client/mrp_client.py" getip d0303 --mrp-url=${mr_provisioner_url} --mrp-token=${mr_provisioner_token})
	compute_regex='d030[1-3]'
fi

if [ ${method} == 'stateful' ]; then
	enable_warewulf=False
elif [ ${method} == 'stateless' ]; then
	enable_warewulf=True
fi

if [ -d "${workspace}/ansible-playbook-for-ohpc" ]; then
    rm -rf "${workspace}/ansible-playbook-for-ohpc"
fi

git clone -b ${ansible_ohpc_branch} https://github.com/Linaro/ansible-playbook-for-ohpc.git "${workspace}/ansible-playbook-for-ohpc"

cat << EOF > "${workspace}/hosts"
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

long='disable'

if [ ${test_type} == 'long' ]; then
	long='enable'
fi


cat << EOF > "${workspace}/ohpc_installation.yml"
sms_name: ${master_name}
sms_ip: ${master_ip}
enable_warewulf: ${enable_warewulf}
enable_testsuiteohpc: True
enable_junit: True
num_computes: ${num_compute}
compute_regex: ${compute_regex}
configure_packages:
  - name: long
    status: ${long}
  - name: adios
    status: disable
  - name: boost
    status: enable
  - name: boost-mpi
    status: enable
  - name: compilers
    status: enable
  - name: fftw
    status: enable
  - name: gsl
    status: enable
  - name: hdf5
    status: disable
  - name: hwloc
    status: enable
  - name: hypre
    status: disable
  - name: imb
    status: disable
  - name: mpi
    status: enable
  - name: mumps
    status: enable
  - name: mfem
    status: enable
  - name: minife
    status: disable
  - name: netcdf
    status: disable
  - name: numpy
    status: enable
  - name: ocr
    status: enable
  - name: petsc
    status: enable
  - name: phdf5
    status: disable
  - name: plasma
    status: enable
  - name: pnetcdf
    status: disable
  - name: ptscotch
    status: enable
  - name: R
    status: enable
  - name: scotch
    status: enable
  - name: slepc
    status: enable
  - name: superlu
    status: enable
  - name: superlu_dist
    status: enable
  - name: scalasca
    status: disable
  - name: scipy
    status: enable
  - name: tau
    status: disable
  - name: trilinos
    status: enable
  - name: valgrind
    status: enable
  - name: hpcg
    status: enable 
  - name: autotools
    status: enable
  - name: cmake
    status: enable
  - name: charliecloud
    status: disable
  - name: easybuild
    status: enable
  - name: metis
    status: enable
  - name: tbb
    status: disable
  - name: minidft
    status: disable
  - name: minife
    status: enable
  - name: cilk
    status: disable
  - name: munge
    status: enable
  - name: mpi4py
    status: enable
  - name: mpiP
    status: disable
  - name: openblas
    status: enable
  - name: rms-harness
    status: enable
  - name: scalapack
    status: enable
  - name: papi
    status: disable
  - name: likwid
    status: disable
  - name: packaging
    status: enable

mpi_families: openmpi3
compiler_families: gnu7
EOF

eval `ssh-agent`
ssh-add

ansible-playbook "${workspace}/ansible-playbook-for-ohpc/run_testsuite.yml" --extra-vars="@${workspace}/ohpc_installation.yml" -i "${workspace}/hosts"

if [ -f "${master_ip}/tmp/junit-results.tar.gz" ]; then
    rm -rf "${workspace}/results"
    mkdir "${workspace}/results"
    tar -xf ${master_ip}/tmp/junit-results.tar.gz -C "${workspace}/results"
else
    echo "FAILURE to find JUnit Results"
    exit 1
fi

ssh-agent -k 
