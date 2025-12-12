#!/bin/sh
set -e
export PYTHONUNBUFFERED=1
export PYTHONPATH="${PWD}"
sleep 5

# Set wandb API key
export WANDB_API_KEY="e22c8d6c2c046a38c883e26623be674e4f096748"

# Set openGL env
export LIBGL_ALWAYS_SOFTWARE=1
export PYOPENGL_PLATFORM=osmesa

# Print debug info
echo "---"
echo "Starting SheepRL experiment"
echo "Working directory: $(pwd)"
echo "Python version:"
python3 --version
echo "NumPy version:"
python3 -c "import numpy; print(numpy.__version__)"
echo "Wandb version:"
python3 -c "import wandb; print(wandb.__version__)"
echo "Arguments: $@"
echo "---"

# Run SheepRL
echo "Running: python3 sheeprl.py $@"
xvfb-run -a -s "-screen 0 1024x768x24 -ac +extension GLX +render -noreset" \
    python3 -u sheeprl.py "$@"
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    echo "SheepRL failed with exit code $EXIT_CODE"
    exit $EXIT_CODE
fi

echo "---"
echo "SheepRL training completed successfully"
echo "Preparing results for transfer..."
echo "---"

# Find and compress logs
if [ -d "logs" ] && [ "$(ls -A logs 2>/dev/null)" ]; then
    echo "Compressing logs directory..."
    tar -czf logs_$(date +%Y%m%d_%H%M%S).tar.gz logs/ 2>/dev/null || echo "Warning: logs compression failed"
fi

# Compress other output directories
for dir in checkpoints outputs wandb; do
    if [ -d "$dir" ] && [ "$(ls -A $dir 2>/dev/null)" ]; then
        echo "Compressing $dir directory..."
        tar -czf ${dir}_$(date +%Y%m%d_%H%M%S).tar.gz $dir/ 2>/dev/null || echo "Warning: $dir compression failed"
    fi
done

echo "---"
echo "Results compressed. Final files:"
ls -lh *.tar.gz 2>/dev/null || echo "No compressed files created"
echo "---"
echo "Job completed successfully!"