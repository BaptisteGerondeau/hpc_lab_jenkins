#!/usr/bin/python3

import argparse
import os.path

class Cluster(object):
    def __init__(self, cluster_type):
        self.getComposition(cluster_type)
        self.os_params = OSParams()
        self.os_params.getByCluster(cluster_type)
        self.machine_params_list = []

        for mtype in self.machine_types:
            params = MachineParams()
            params.getByType(mtype)
            self.machine_params_list.append(params)

    def getComposition(self, cluster_type):
        if cluster_type == "qdc":
            self.node = 'qdcohpc'
            self.machine_list=['qdcohpc', 'qdc01', 'qdc02', 'qdc03']
            self.machine_types=['qdc', 'qdc', 'qdc', 'qdc']
        elif cluster_type == "d05":
            self.node = 'd05ohpc'
            self.machine_list=['d05ohpc', 'd0301', 'd0302', 'd0303']
            self.machine_types=['d05', 'd03', 'd03', 'd03']
        else:
            print("Unknown Cluster Type")
            exit(1)

class IndividualMachine(object):
    def __init__(self, machine_type, job_type, os_type):
        self.node = str(machine_type) + str(job_type)
        self.machine_list = [self.node]
        self.os_type = os_type

        if os_type == "default":
            self.os_type = self.getDefaultOS(machine_type, job_type)

        self.os_params = OSParams()
        self.os_params.getByType(self.os_type)

        params = MachineParams()
        params.getByType(machine_type)

        self.machine_params_list = []
        self.machine_params_list.append(params)

    def getDefaultOS(self, machine_type, job_type):
        if job_type == "bench":
            os_type = "debian"
        elif job_type == "ohpc":
            os_type = "centos"
            if machine_type == "qdc":
                os_type = "centos-upstream"
        else:
            print("Unknown Job Type")
            exit(1)

        return os_type

class MachineParams(object):
    def __init__(self):
        self.arch = None
        self.subarch = None
        self.kernel_opts = None

    def getByType(self, mtype):
        if mtype == 'd03':
            self.arch = 'AArch64'
            self.subarch = 'Grub'
            self.kernel_opts = "modprobe.blacklist=hibmc_drm earlycon console=ttyS0,115200"

        elif mtype == 'd05':
            self.arch = 'AArch64'
            self.subarch = 'Grub'
            self.kernel_opts = "earlycon console=ttyAMA0,115200"

        elif mtype == 'qdc':
            self.arch = 'AArch64'
            self.subarch = "GrubWithOptionEfiboot"
            self.kernel_opts = "earlycon console=ttyAMA0,115200"

        else:
            print("Unknown Machine Type")
            exit(1)

class OSParams(object):
    def __init__(self):
        self.preseed_type = None
        self.kernel_desc = None
        self.initrd_desc = None
        self.preseed_name = None
        self.kernel_opts = None

    def getByType(self, os_type):
        if os_type == "debian":
            self.preseed_type = "preseed"
            self.kernel_desc = "Debian ERP 18.06"
            self.initrd_desc = "Debian ERP 18.06"
            self.preseed_name = "Debian"
            self.kernel_opts = ""

        elif os_type == "centos":
            self.preseed_type = "kickstart"
            self.kernel_desc = "CentOS ERP 18.06"
            self.initrd_desc = "CentOS ERP 18.06"
            self.preseed_name = "CentOS"
            self.kernel_opts = "ip=dhcp text inst.stage2=http://10.40.0.13/releases.linaro.org/reference-platform/enterprise/18.06/centos-installer/ inst.repo=http://10.40.0.13/mirror.centos.org/altarch/7/os/aarch64/ inst.ks=file:/ks.cfg"

        elif os_type == "centos-upstream":
            self.preseed_type = "kickstart"
            self.kernel_desc = "CentOS 7.5"
            self.initrd_desc = "CentOS 7.5"
            self.preseed_name = "CentOS Upstream"
            self.kernel_opts = "ip=dhcp text inst.stage2=http://10.40.0.13/mirror.centos.org/altarch/7/os/aarch64/ inst.repo=http://10.40.0.13/mirror.centos.org/altarch/7/os/aarch64/ inst.ks=file:/ks.cfg"

    def getByCluster(self, cluster_name):
        if cluster_name == 'd05':
            self.preseed_type="kickstart"
            self.kernel_desc="CentOS ERP 18.06"
            self.initrd_desc="CentOS ERP 18.06"
            self.preseed_name="CentOS"
            self.kernel_opts="ip=dhcp text inst.stage2=http://releases.linaro.org/reference-platform/enterprise/18.06/centos-installer/ inst.repo=http://mirror.centos.org/altarch/7/os/aarch64/ inst.ks=file:/ks.cfg"

        elif cluster_name == 'qdc':
            self.preseed_type="kickstart"
            self.kernel_desc="CentOS 7.5"
            self.initrd_desc="CentOS 7.5"
            self.preseed_name="CentOS Upstream"
            self.kernel_opts="ip=dhcp text inst.stage2=http://mirror.centos.org/altarch/7/os/aarch64/ inst.repo=http://mirror.centos.org/altarch/7/os/aarch64/ inst.ks=file:/ks.cfg"

def generateTriggerFile(machines, workspace):
    node = machines.node
    kernel_desc = machines.os_params.kernel_desc
    initrd_desc = machines.os_params.initrd_desc
    preseed_name = machines.os_params.preseed_name
    preseed_type = machines.os_params.preseed_type
    machine_list = serialize(machines.machine_list)
    machine_arch = serializeMachineParams(machines.machine_params_list, 'arch')
    machine_subarch = serializeMachineParams(machines.machine_params_list,
                                             'subarch')
    kernel_opts = serializeMachineParams(machines.machine_params_list,
                                         'kernel_opts',
                                         machines.os_params.kernel_opts)

    path_to_trigger = os.path.abspath(os.path.join(workspace, 'mrp_provision'))
    print(path_to_trigger)
    with open(path_to_trigger, 'w+') as fd:
        fd.write("node=" + str(node) + '\n')
        fd.write("machine_name=" + str(machine_list) + '\n')
        fd.write("machine_arch=" + str(machine_arch) + '\n')
        fd.write("machine_subarch=" + str(machine_subarch) + '\n')
        fd.write("kernel_opts=" + str(kernel_opts) + '\n')
        fd.write("kernel_desc=" + str(kernel_desc) + '\n')
        fd.write("initrd_desc=" + str(initrd_desc) + '\n')
        fd.write("preseed_name=" + str(preseed_name) + '\n')
        fd.write("preseed_type=" + str(preseed_type) + '\n')


    # Write them

def serialize(array):
    separator = ';'
    serialized = ''
    for i in array:
        if serialized == '':
            serialized = str(i)
        else:
            serialized += separator + str(i)
    return serialized

def serializeMachineParams(params_array, field, base=''):
    array = []
    if base != '':
        base += ' '

    for params in params_array:
        if field == 'subarch':
            array.append(str(params.subarch))
        elif field == 'arch':
            array.append(str(params.arch))
        elif field == 'kernel_opts':
            array.append(str(base) + str(params.kernel_opts))
        else:
            print("Unknown field '{0}' in MachineParams".format(field))
            exit(1)

    return serialize(array)


def main(args):
    machines = None
    if args.cluster is not None:
        machines = Cluster(args.cluster)
    elif args.machine_type is not None and args.job_type is not None and args.os_type is not None:
        machines = IndividualMachine(args.machine_type, args.job_type,
                                     args.os_type)
    else:
        print("Invalid arguments")
        exit(1)

    if args.workspace is not None:
        generateTriggerFile(machines, args.workspace)
    else:
        print("Invalid arguments")
        exit(1)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Download and cache some tarballs')
    parser.add_argument('--cluster', type=str, default=None,
                        help='The name of the cluster to provision')
    parser.add_argument('--machine-type', type=str, default=None,
                        help='The type of the machine to be provisioned')
    parser.add_argument('--job-type', type=str, default=None,
                        help='The type of job the machine to be provisioned will do')
    parser.add_argument('--os-type', type=str, default=None,
                        help='The OS the machine should be provisioned with')
    parser.add_argument('--workspace', type=str, default=None, required=True,
                        help='Path to the directory in which the trigger file will be put')
    args = parser.parse_args()
    main(args)
