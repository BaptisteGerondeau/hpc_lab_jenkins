#!/bin/bash
set -ex

helpmsg="benchmark_job.sh --workspace [WORKSPACE] --sftp_path [sftp_path] --sftp_user [sftp_user] --node_type [node_type] --machine_type [machine_type] --sftp_server_ip [sftp_server_ip]  --compiler [compiler] --build-number [build_number] --ansible-branch [branch for ansible_deploy_harness] --harness-branch [harness_gitbranch] --benchmark [benchmark_name] --compiler_flags compiler_flags --linker_flags linker_flags --harness_options harness_options --run_flags run_flags --iterations iterations --size size "

ARGUMENT_LIST=(
	"workspace"
	"sftp_path"
	"sftp_user"
	"sftp_server_ip"
	"machine_ip"
	"node_type"
	"machine_type"
	"compiler"
	"build_number"
	"ansible_branch"
	"harness_branch"
	"benchmark"
	"compiler_flags"
	"linker_flags"
	"harness_options"
	"run_flags"
	"iterations"
	"size"
)

root_dir="$(realpath $(dirname $0))"

. ${root_dir}/argparse.sh

if [[ ! -n "${workspace}" ]] || [[ ! -n "${sftp_path}" ]] || [[ ! -n "${sftp_user}" ]] || [[ ! -n ${sftp_server_ip} ]] || [[ ! -n ${node_type} ]] || [[ ! -n ${machine_ip} ]] || [[ ! -n ${machine_type} ]] || [[ ! -n ${compiler} ]] || [[ ! -n ${build_number} ]] || [[ ! -n ${harness_branch} ]] || [[ ! -n ${benchmark} ]] || [[ ! -n ${ansible_branch} ]]; then
	echo "Missing Required Argument(s)"
	echo $helpmsg
	exit 1
fi

if [ ! -d "${workspace}" ]; then
	echo "No Workspace at ${workspace}"
	exit 2
fi

cat << EOF > "${WORKSPACE}/hosts"
[target]
${machine_ip}
EOF

cat << EOF > benchmark_job.yml
sftp_dirname: ${node_type}-${BUILD_NUMBER}
sftp_user: ${sftp_user}
sftp_server_ip: ${sftp_server_ip}
sftp_path: ${sftp_path}
machine_type: ${machine_type}
branch: ${harness_branch}
benchmark: ${benchmark}
size: ${size}
iterations: ${iterations}
compiler: ${compiler}
compiler_flags: ${compiler_flags}
linker_flags: ${linker_flags}
run_flags: ${run_flags}
harness_options: ${harness_options}
EOF

if [ -d "${WORKSPACE}/hpc_lab_setup" ]; then
    rm -rf "${WORKSPACE}/hpc_lab_setup"
fi
git clone -b ${ansible_branch} https://github.com/Linaro/hpc_lab_setup.git "${WORKSPACE}/hpc_lab_setup"

eval `ssh-agent`
ssh-add

ANSIBLE_CONFIG="${WORKSPACE}/hpc_lab_setup/files/ansible/ansible.cfg" ansible-playbook -v -u root "${WORKSPACE}/hpc_lab_setup/files/ansible/deploy_benchmarks.yml" -i "${WORKSPACE}/hosts"  --extra-vars="@${WORKSPACE}/benchmark_job.yml"
ssh-agent -k 
