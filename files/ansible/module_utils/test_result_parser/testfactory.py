#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
    Base Factory class, with common logic for finding and loading models
"""
import os
import re
import importlib

from ansible.module_utils.test_result_parser.modelloader import ModelLoader

class TestFactory(object):
    def __init__(self):
        self.models_dir = os.path.join('/tmp/', 'test_models')

    def getTest(self, test_output):
        return self._find_model(test_output)

    def _load_model(self, name):
        if name is None:
            raise ValueError('Model name is empty')
        if not isinstance(name, str):
            raise TypeError('Model name has to be a string')
        if not re.search('_model.py', name):
            return None

        filename = os.path.join(self.models_dir, name)
        if not os.path.isfile(filename):
            return None

        return ModelLoader(filename).load()

    def _find_model(self, condition):
        """Checks compiler models against binary dir"""
        models = []
        for model in [f for f in os.listdir(self.models_dir)
                        if re.match(r'.*\.py*', f)]:
            models += model
            loaded_model = self._load_model(model)
            if loaded_model and loaded_model.check(condition):
                return loaded_model

        # If did not find module that satisfies the conditions, bail
        raise ImportError('No corresponding module %s found for this test output %s' % (models, condition))
