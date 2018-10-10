#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import re

class TestModel(object):
    def __init__(self):
        self.type = dict()
        self.fail_msg = "Default Failure Message"
        self.parameters_regex = dict()
        self.result_regex = re.compile(r'', re.M)
        self.result_list = []

    def check(self, test_output):
        for field, regex in self.type.items():
            match = re.search(regex, test_output)
            if match is not None and match.group(1) == field:
                return True

        return False

    def failed(self, parsed_results, test_threshold):
        return False

    def parse_output(self, test_output):
        parsed_results = dict()
        parsed_params = dict()

        match_result = re.findall(self.result_regex, test_output)

        if len(match_result) == 1 and len(match_result[0]) != len(self.result_list):
            raise RuntimeError("Couldn't parse enough results")

        for i in range(0, len(self.result_list)):
            parsed_results[self.result_list[i]] = str(match_result[0][i])

        for field, regex in self.parameters_regex.items():
            match = re.search(regex, test_output)
            if match is not None:
                parsed_params[field] = str(match.group(1))
            else:
                raise RuntimeError("Couldn't parse parameters correctly : %s" %
                                  regex)

        return parsed_results, parsed_params
