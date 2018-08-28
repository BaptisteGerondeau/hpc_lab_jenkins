#!/bin/bash
set -x

helpmsg="benchmark_job.sh -w [WORKSPACE] -n [node] -c [compiler] -b [BUILD_NUMBER] -g [benchmark_gitbranch] -m [benchmark_name] -f compiler_flags -l linker_flags -o run_flags -e harness_options -s size -i iterations -v (for set -ex)"

while getopts 'w:n:c:b:g:m:f:l:o:e:s:i:vh' flag
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
		l ) linker_flags=$OPTARG;;
		o ) run_flags=$OPTARG;;
		e ) harness_options=$OPTARG;;
		s ) size=$OPTARG;;
		i ) iterations=$OPTARG;;
		h ) echo $helpmsg
		    exit 0
		    ;;
		v ) set -ex ;;
		* ) echo 'Illegal argument' && echo $helpmsg && exit 42 ;;
	esac
done

if [ ! -n "${WORKSPACE}" ] || [ ! -n $node ] || [ ! -n $compiler ] || [ ! -n $BUILD_NUMBER ] || [ ! -n $branch ] || [ ! -n $benchmark ]; then
	echo "Missing Required Argument(s) !!!"
	echo $helpmsg
	exit 1
fi

echo "${WORKSPACE}"
if [ ! -d $WORKSPACE ]; then
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
size: ${size}
iterations: ${iterations}
machine_type: ${machine_type}
compiler: ${compiler}
compiler_flags: ${compiler_flags}
linker_flags: ${link_flags}
run_flags: ${run_flags}
harness_options: ${harness_options}
EOF

if [ -d ${WORKSPACE}/ansible-deploy-benchmarks ]; then
    rm -rf ansible-deploy-benchmarks
fi

eval `ssh-agent`
ssh-add

git clone -b ${branch} https://github.com/Linaro/ansible-deploy-benchmarks.git ${WORKSPACE}/ansible-deploy-benchmarks
ansible-playbook ${WORKSPACE}/ansible-deploy-benchmarks/deploy_benchmarks.yml --extra-vars="@${WORKSPACE}/benchmark_job.yml"

ssh-agent -k
