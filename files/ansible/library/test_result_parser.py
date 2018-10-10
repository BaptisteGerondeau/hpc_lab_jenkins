#!/usr/bin/env python3

ANSIBLE_METADATA = {
    'metadata_version': '1.1',
    'status': ['preview'],
    'supported_by': 'community'
}

DOCUMENTATION = '''
---
module: my_sample_module

short_description: This is my sample module

version_added: "2.4"

description:
    - "This is my longer description explaining my sample module"

options:
    name:
        description:
            - This is the message to send to the sample module
        required: true
    new:
        description:
            - Control to demo if the result of this module is changed or not
        required: false

extends_documentation_fragment:
    - azure

author:
    - Your Name (@yourhandle)
'''

EXAMPLES = '''
# Pass in a message
- name: Test with a message
  my_new_test_module:
    name: hello world

# pass in a message and have changed true
- name: Test with a message and changed output
  my_new_test_module:
    name: hello world
    new: true

# fail the module
- name: Test failure of the module
  my_new_test_module:
    name: fail me
'''

RETURN = '''
original_message:
    description: The original name param that was passed in
    type: str
message:
    description: The output message that the sample module generates
'''
import os
import re

from ansible.module_utils.test_result_parser.test_parser import TestParser
from ansible.module_utils.basic import AnsibleModule

def run_module():
    # define the available arguments/parameters that a user can pass to
    # the module
    module_args = dict(
        test_output_path=dict(type='str', required=True),
        test_threshold=dict(type='str', required=True),
        json_or_xml=dict(type='str', required=False, default='xml'),
        junit_write_path=dict(type='str', required=False, default='./'),
        extra_flags=dict(type='str', required=False, default='')
    )

    # seed the result dict in the object
    # we primarily care about changed and state
    # change is if this module effectively modified the target
    # state will include any data that you want your module to pass back
    # for consumption, for example, in a subsequent task
    result = dict(
        changed=False,
        original_message='Nothing done by the test parser',
        message='Nothing done by the test parser'
    )

    # the AnsibleModule object will be our abstraction working with Ansible
    # this includes instantiation, a couple of common attr would be the
    # args/params passed to the execution, as well as if the module
    # supports check mode
    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=True
    )

    # if the user is working with this module in only check mode we do not
    # want to make any changes to the environment, just return the current
    # state with no modifications
    if module.check_mode:
        return result

    # manipulate or modify the state as needed (this is going to be the
    # part where your module will do what it needs to do)
    result['original_message'] = repr(module.params)

    try:
        test_parser = TestParser(module.params['json_or_xml'])
        test_parser.main(module.params['test_output_path'],
                         module.params['test_threshold'],
                         module.params['junit_write_path'],
                         module.params['extra_flags'])
        result['message'] = 'Test parsed succesfully : result saved here, %s' % module_args['junit_write_path']
        result['changed'] = True
        # in the event of a successful module execution, you will want to
        # simple AnsibleModule.exit_json(), passing the key/value results
        module.exit_json(**result)
    except Exception as err:
        result['message'] = 'Failed to parse test !'
        result['changed'] = False
        module.fail_json(msg=repr(err), **result)

def main():
    run_module()

if __name__ == '__main__':
    main()
