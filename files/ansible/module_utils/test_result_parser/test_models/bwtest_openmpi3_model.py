#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import re
import os
import sys

if os.path.dirname(os.path.realpath(__file__)) not in sys.path:
    sys.path.append(os.path.dirname(os.path.realpath(__file__)))
import testmodel

class TestModelImpl(testmodel.TestModel):
    def __init__(self):
        super().__init__()
        self.type = {'Bandwidth Test': r'\s+OSU\sMPI\s(\w+\s\w+)'}
        self.result_list = ['Size', 'Bandwidth']
        self.result_regex = re.compile(r'^(\d+)\s+(\d+.\d+)', re.M)

    def failed(self, parsed_results, test_threshold):
        if parsed_results['4194304'] < test_threshold:
            self.fail_msg = "FAIL: MPI Bandwidth at size max %s below %s threshold" % (parsed_results['4194304'], test_threshold)
            return True
        return False

    def parse_output(self, test_output):
        parsed_results = dict()
        parsed_params = dict()


        match_result = re.findall(self.result_regex, test_output)

        if match_result == 1 and len(match_result[0]) != len(self.result_list):
            raise RuntimeError("Couldn't parse enough results : %s" %
                               match_result)

        for j in range(0, len(match_result)):
            for i in range(0, len(self.result_list)):
                parsed_results[str(match_result[j][0])] = str(match_result[j][1])

        for field, regex in self.parameters_regex.items():
            match = re.search(regex, test_output)
            if match is not None:
                parsed_params[field] = str(match.group(1))
            else:
                raise RuntimeError("Couldn't parse parameters correctly : %s" %
                                  regex)

        return parsed_results, parsed_params
