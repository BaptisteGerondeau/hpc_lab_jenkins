#!/bin/bash
set -x

helpmsg="benchmark_job.sh -w [WORKSPACE] -n [node] -c [compiler] -b [BUILD_NUMBER] -g [benchmark_gitbranch] -m [benchmark_name] -f compiler_flags -l link_flags -o benchmark_options -d benchmark_build_deps -r benchmark_run_deps -v (for set -ex)"

while getopts 'w:n:c:b:g:m:f:l:o:d:r:vh' flag
do
	echo $OPTARG
	case $flag in
		w ) WORKSPACE=$OPTARG;;
		n ) node=$OPTARG;;
		c ) compiler=$OPTARG;;
		b ) BUILD_NUMBER=$OPTARG;;
		g ) branch=$OPTARG;;
		m ) benchmark=$OPTARG;;
		f ) compiler_flags=$OPTARG;;
		l ) link_flags=$OPTARG;;
		o ) benchmark_options=$OPTARG;;
		d ) benchmark_build_deps=$OPTARG;;
		r ) benchmark_run_deps=$OPTARG;;
		h ) echo $helpmsg
		    exit 0
		    ;;
		v ) set -ex ;;
		* ) exit 69 ;;
	esac
done

if [ ! -n "${WORKSPACE}" ] || [ ! -n $node ] || [ ! -n $compiler ] || [ ! -n $BUILD_NUMBER ] || [ ! -n $branch ] || [ ! -n $benchmark ]; then
	echo "MISSING REQUIRED ARGUMENT !!!"
	echo $helpmsg
	exit 1
fi

echo "${WORKSPACE}"
if [ ! -d $WORKSPACE ]; then
	exit 2
fi

eval `ssh-agent`
ssh-add

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
    echo "UNKNOWN MACHINE TYPE, Exiting..."
    exit 2
    ;;
esac
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
if [[ ${compiler} = *"http://"* ]] || [[ ${compiler} = *"ftp://"* ]]; then
	${DIR}/tarball_cacher.py ${compiler} /tmp/ --upload=sftp://10.40.0.13/toolchains
	file=$(basename ${compiler})
	compiler="http://10.40.0.13/toolchains/${file}"
fi

cat << EOF > ${WORKSPACE}/benchmark_job.yml
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

if [ -d ${WORKSPACE}/ansible-deploy-benchmarks ]; then
    rm -rf ansible-deploy-benchmarks
fi
git clone -b ${branch} https://github.com/Linaro/ansible-deploy-benchmarks.git ${WORKSPACE}/ansible-deploy-benchmarks
ansible-playbook ${WORKSPACE}/ansible-deploy-benchmarks/deploy_benchmarks.yml --extra-vars="@${WORKSPACE}/benchmark_job.yml"
ssh-agent -k
