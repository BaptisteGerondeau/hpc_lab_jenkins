# Ansible Deploy Benchmarks

This Ansible playbook deploys benchmarks using the benchmark harness:
https://github.com/Linaro/benchmark_harness

And using Mr-Provisioner's client:
https://github.com/Linaro/mr-provisioner-client

Both of which will be checked out by the playbook.

# Extra arguments

These are the extra arguments needed to get it to run

## Required

* mr_provisioner_url: URL
* mr_provisioner_token: TOKEN
* mr_provisioner_machine_name: name in MrP
* branch: harness' branch
* benchmark: "lulesh, himeno, ..."
* machine_type: "x86_64, aarch64, ..."
* compiler: "gcc, clang, URL"

## Optional flags

* compiler_flags:
* link_flags:
* benchmark_options:
* benchmark_build_deps:
* benchmark_run_deps:

## SFTP results push

* sftp_dirname:
* sftp_user:
* sftp_server_ip:
* sftp_path:
