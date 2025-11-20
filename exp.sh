#!/bin/sh
set -e
export PYTHONUNBUFFERED=1
export PYTHONPATH="${PWD}"
sleep 5
export WANDB_API_KEY="e22c8d6c2c046a38c883e26623be674e4f096748"
xvfb-run -a -s "-screen 0 1024x768x24 -ac +extension GLX +render -noreset" python3 -u main.py "$@"
cp zip_dirs.sh wandb_tests/wandb/
cd wandb_tests/wandb/
./zip_dirs.sh
mv *.zip ../../