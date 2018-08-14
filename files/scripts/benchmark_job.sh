#!/bin/bash

if [ "$#" -gt 13 ] || [ "$#" -lt 7 ]; then
	echo "Illegal number of arguments !"
	echo "benchmark_job.sh [WORKSPACE] [node] [compiler] [JENKINS_HOME (scripts)] [BUILD_NUMBER] [benchmark_gitbranch] [benchmark_name] compiler_flags link_flags benchmark_options benchmark_build_deps benchmark_run_deps -v (for set -ex)"
	echo "[required] optional"
	exit 1
fi

if [ "${13}" == '-v' ]; then
	set -ex
fi

WORKSPACE=$1
node=$2
compiler=$3
JENKINS_HOME=$4
BUILD_NUMBER=$5
branch=$6
benchmark=$7
compiler_flags=$8
link_flags=$9
benchmark_options=${10}
benchmark_build_deps=${11}
benchmark_run_deps=${12}
	
cd ${WORKSPACE}
eval `ssh-agent`
ssh-add

case ${node} in
d03*)
    vendor='huawei'
    node_type=d03
    machine_type=aarch64
    ;;
d05*)
    vendor='huawei'
    node_type=d05
    machine_type=aarch64
    ;;
qdc*)
    vendor='qualcomm'
    node_type=qdc
    machine_type=aarch64
    ;;
tx*)
    vendor='cavium'
    node_type=tx2
    machine_type=aarch64
    ;;
x86_64*)
    vendor='intel'
    node_type=x86
    machine_type=x86_64
    ;;
esac

if [[ ${compiler} = *"http://"* ]] || [[ ${compiler} = *"ftp://"* ]]; then
	${JENKINS_HOME}/scripts/tarball_cacher.py ${compiler} /tmp/ --upload=sftp://10.40.0.13/toolchains
	file=$(basename ${compiler})
	compiler="http://10.40.0.13/toolchains/${file}"
fi

cat << EOF > benchmark_job.yml
mr_provisioner_url: http://10.40.0.11:5000
mr_provisioner_token: $(cat "/home/$(whoami)/mrp_token")
mr_provisioner_machine_name: ${node_type}bench
sftp_dirname: ${node_type}-${BUILD_NUMBER}
sftp_user: $(whoami)
sftp_server_ip: 10.40.0.13
vendor: ${vendor}
branch: ${branch}
benchmark: ${benchmark}
machine_type: ${machine_type}
compiler: ${compiler}
compiler_flags: ${compiler_flags}
link_flags: ${link_flags}
benchmark_options: ${benchmark_options}
benchmark_build_deps: ${benchmark_build_deps}
benchmark_run_deps: ${benchmark_run_deps}
EOF

if [ -d ansible-deploy-benchmarks ]; then
    rm -rf ansible-deploy-benchmarks
fi
git clone -b ${branch} https://github.com/Linaro/ansible-deploy-benchmarks.git
cd ansible-deploy-benchmarks
ansible-playbook deploy_benchmarks.yml --extra-vars="@../benchmark_job.yml"
ssh-agent -k 
