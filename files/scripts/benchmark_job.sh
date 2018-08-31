#!/bin/bash
set -ex

helpmsg="benchmark_job.sh --workspace [WORKSPACE] --sftp_user [sftp_user] --node [node] --compiler [compiler] --build-number [build_number] --git-branch [harness_gitbranch] --benchmark [benchmark_name] --compiler_flags compiler_flags --linker_flags linker_flags --harness_options harness_options --run_flags run_flags --iterations iterations --size size"

ARGUMENT_LIST=(
	"workspace"
	"node"
	"sftp_user"
	"compiler"
	"build_number"
	"harness_branch"
	"benchmark"
	"compiler_flags"
	"linker_flags"
	"harness_options"
	"iterations"
	"size"
	"run_flags"
)

root_dir="$(realpath $(dirname $0))"

. ${root_dir}/argparse.sh

if [ ! -n "${workspace}" ] || [ ! -n ${node} ] || [ ! -n ${compiler} ] || [ ! -n ${build_number} ] || [ ! -n ${harness_branch} ] || [ ! -n ${benchmark} ]; then
	echo "Missing Required Argument(s)"
	echo $helpmsg
	exit 1
fi

if [ ! -d "${workspace}" ]; then
	echo "No Workspace at ${workspace}"
	exit 2
fi

case "${node}" in
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
*)
    echo "Unknown node type : ${node} , Exiting..."
    exit 2
    ;;
esac
if [[ ${compiler} = *"http://"* ]] || [[ ${compiler} = *"ftp://"* ]]; then
	${root_dir}/tarball_cacher.py ${compiler} /tmp/ --upload=sftp://10.40.0.13/toolchains
	file=$(basename ${compiler})
	compiler="http://10.40.0.13/toolchains/${file}"
fi

cat << EOF > benchmark_job.yml
mr_provisioner_url: http://10.40.0.11:5000
mr_provisioner_token: $(cat "/home/${sftp_user}/mrp_token")
mr_provisioner_machine_name: ${node_type}bench
sftp_dirname: ${node_type}-${build_number}
sftp_user: ${sftp_user}
sftp_server_ip: 10.40.0.13
sftp_path: ${vendor}/benchmark
machine_type: ${machine_type}
branch: master
benchmark: ${benchmark}
size: ${size}
iterations: ${iterations}
compiler: ${compiler}
compiler_flags: ${compiler_flags}
linker_flags: ${linker_flags}
run_flags: ${run_flags}
harness_options: ${harness_options}
EOF

if [ -d "${workspace}/ansible-deploy-benchmarks" ]; then
    rm -rf "${workspace}/ansible-deploy-benchmarks"
fi

git clone -b ${harness_branch} https://github.com/Linaro/ansible-deploy-benchmarks.git "${workspace}/ansible-deploy-benchmarks"

eval `ssh-agent`
ssh-add

ansible-playbook -v "${workspace}/ansible-deploy-benchmarks/deploy_benchmarks.yml" --extra-vars="@${workspace}/benchmark_job.yml"

ssh-agent -k
