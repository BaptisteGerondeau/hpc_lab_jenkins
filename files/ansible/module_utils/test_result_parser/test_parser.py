#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import re

from junitparser import TestCase, TestSuite, JUnitXml, Skipped, Error
from ansible.module_utils.test_result_parser.testfactory import TestFactory
from ansible.module_utils.test_result_parser.test_models import *

class TestParser(object):
    def __init__(self, json_or_xml):
        if str(json_or_xml) == "xml":
            self.formatter = JUnitXml()
            self.format = '.xml'
        else:
            # TODO: Implement a JSON format compatible with SQUAD
            # This means using the python (l)xml ElementTree (<=> TestSuite())
            self.formatter = None
            self.format = '.json'

        self.test_factory = TestFactory()

    def main(self, results_path, test_threshold, output_path, extra=''):
        result = ""
        filename = os.path.basename(results_path)
        with open(results_path, 'r') as output:
            for line in output.readlines():
                result += line

        test = self.test_factory.getTest(result)
        results, params = test.parse_output(result)
        test_type = list(test.type.keys())[0]

        testcase = TestCase(test_type)

        if test.failed(results, test_threshold):
            testcase.result = Error(test.fail_msg, test_type)

        suite = TestSuite(test_type + extra)
        for name, value in results.items():
            suite.add_property(name, value)

        for name, value in params.items():
            suite.add_property(name, value)

        testcase.system_out = result
        suite.add_testcase(testcase)

        if self.formatter is None:
            raise ValueError("No Formatter given !")

        junit = self.formatter
        junit.add_testsuite(suite)

        if output_path[-1] != '/':
            output_path+='/'
        junit.write(output_path + 'junit-' + filename + '-' + extra + self.format)
