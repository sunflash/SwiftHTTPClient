#!/bin/bash
if [ ! -d "./docs" ]; then
    mkdir docs
fi

jazzy --config jazzy.json
open ./docs/index.html
