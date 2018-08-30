#!/bin/bash
set -x

helpmsg="benchmark_job.sh --workspace [WORKSPACE] --node [node] --compiler [compiler] --build-number [build_number] --git-branch [harness_gitbranch] --benchmark [benchmark_name] --compiler_flags compiler_flags --linker_flags linker_flags --harness_options harness_options --run_flags run_flags --iterations iterations --size size --verbose (for set -ex)"

ARGUMENT_LIST=(
	"workspace"
	"node"
	"compiler"
	"build_number"
	"git_branch"
	"benchmark"
	"compiler_flags"
	"linker_flags"
	"harness_options"
	"iterations"
	"size"
	"run_flags"
)

. files/scripts/argparse.sh

if [ $help == True ]; then
	echo $helpmsg
	exit 0
elif [ $verbose == True ]; then
	set -ex
fi

if [ ! -n "${workspace}" ] || [ ! -n $node ] || [ ! -n $compiler ] || [ ! -n $build_number ] || [ ! -n $git_branch ] || [ ! -n $benchmark ]; then
	echo "Missing Required Argument(s) !!!"
	echo $helpmsg
	exit 1
fi

echo "${workspace}"
if [ ! -d $workspace ]; then
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
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
if [[ ${compiler} = *"http://"* ]] || [[ ${compiler} = *"ftp://"* ]]; then
	${DIR}/tarball_cacher.py ${compiler} /tmp/ --upload=sftp://10.40.0.13/toolchains
	file=$(basename ${compiler})
	compiler="http://10.40.0.13/toolchains/${file}"
fi

cat << EOF > benchmark_job.yml
mr_provisioner_url: http://10.40.0.11:5000
mr_provisioner_token: $(cat "/home/$(whoami)/mrp_token")
mr_provisioner_machine_name: ${node_type}bench
sftp_dirname: ${node_type}-${build_number}
sftp_user: ${NODE_NAME}
sftp_server_ip: 10.40.0.13
sftp_path: ${vendor}/benchmark
machine_type: ${machine_type}
branch: ${git_branch}
benchmark: ${benchmark}
size: ${size}
iterations: ${iterations}
compiler: ${compiler}
compiler_flags: ${compiler_flags}
linker_flags: ${linker_flags}
run_flags: ${run_flags}
harness_options: ${harness_options}
EOF

if [ -d ${workspace}/ansible-deploy-benchmarks ]; then
    rm -rf ansible-deploy-benchmarks
fi

eval `ssh-agent`
ssh-add

git clone -b ${git_branch} https://github.com/Linaro/ansible-deploy-benchmarks.git ${workspace}/ansible-deploy-benchmarks
ansible-playbook ${workspace}/ansible-deploy-benchmarks/deploy_benchmarks.yml --extra-vars="@${workspace}/benchmark_job.yml"

ssh-agent -k
