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
        self.type = {'Bidirectional BW Test':
                     r'\s+RDMA_Write\s(\w+\s\w+\s\w+)'}
        self.fail_msg = "Less than X Gb/s of BW !"
        self.parameters_regex = {
            'Dual-port': r'\bDual-port\s+:\s(\w+)',
            'Number of qps': r'\bNumber of qps\s+:\s(\d+)',
            'Connection type': r'\bConnection type\s+:\s(\w+)',
            'TX depth': r'\bTX depth\s+:\s(\d+)',
            'CQ Moderation': r'\bCQ Moderation\s+:\s(\d+)',
            'Mtu': r'\bMtu\s+:\s(\d+\[\w\])',
            'Link type': r'\bLink type\s+:\s(\w+)',
            'Max inline data': r'\bMax inline data\s+:\s(\d+\[\w\])',
            'rdma_cm QPs': r'\brdma_cm QPs\s+:\s(\w+)',
            'Data ex. method': r'\bData ex. method\s+:\s(\w+)',
            'Device': r'\bDevice\s+:\s(\w+)',
            'Transport type': r'\bTransport type\s+:\s(\w+)',
            'Using SRQ': r'\bUsing SRQ\s+:\s(\w+)'
        }
        self.result_list = ['bytes', 'iterations', 'BW Peak[Gb/s]', 'BW avg[Gb/s]', 'MsgRate[Mbps]']
        self.result_regex = re.compile(r'^\s+(\d+)\s+(\d+)\s+(\d+.\d+)\s+(\d+.\d+)\s+(\d+.\d+)\s+', re.M)

    def failed(self, parsed_results, test_threshold):
        if float(parsed_results['BW avg[Gb/s]']) < float(test_threshold):
            self.fail_msg = "FAIL: Bandwidth of %s against threshold of %s Gb/s" % (parsed_results['BW avg[Gb/s]'], test_threshold)
            return True
        return False

