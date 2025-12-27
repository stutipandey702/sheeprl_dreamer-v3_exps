#!/bin/bash
set -e
export PYTHONUNBUFFERED=1
export PYTHONPATH="${PWD}"
export HYDRA_FULL_ERROR=1

echo "=== System Information ==="
echo "Hostname: $(hostname)"
echo "Date: $(date)"
echo "CPUs: $(nproc)"
echo "Memory: $(free -h | grep Mem | awk '{print $2}')"
echo ""

echo "=== GPU Detection ==="
# Check via Python/PyTorch instead of nvidia-smi
CUDA_CHECK=$(python3 -c "import torch; print('1' if torch.cuda.is_available() else '0')" 2>/dev/null || echo "0")

if [ "$CUDA_CHECK" = "1" ]; then
    echo "GPU detected via PyTorch"
    python3 -c "import torch; print(f'Device: {torch.cuda.get_device_name(0)}'); print(f'Device count: {torch.cuda.device_count()}'); print(f'CUDA version: {torch.version.cuda}')"
    export CUDA_AVAILABLE=1
else
    echo "No GPU available"
    export CUDA_AVAILABLE=0
fi
echo ""

echo "=== Python & PyTorch Info ==="
python3 --version
python3 -c "import torch; print(f'PyTorch: {torch.__version__}')"
echo ""

# Configure rendering based on GPU availability
if [ "$CUDA_AVAILABLE" = "1" ]; then
    echo "Configuring for GPU-accelerated rendering"
    export MUJOCO_GL=egl
    # Make sure CUDA can see the device
    if [ -z "$CUDA_VISIBLE_DEVICES" ]; then
        export CUDA_VISIBLE_DEVICES=0
    fi
else
    echo "Configuring for software rendering"
    export MUJOCO_GL=osmesa
    export LIBGL_ALWAYS_SOFTWARE=1
    export PYOPENGL_PLATFORM=osmesa
fi

# WandB configuration
export WANDB_MODE=online
export WANDB_API_KEY="e22c8d6c2c046a38c883e26623be674e4f096748"

echo "=== Environment Variables ==="
echo "MUJOCO_GL: $MUJOCO_GL"
echo "CUDA_VISIBLE_DEVICES: ${CUDA_VISIBLE_DEVICES}"
echo ""

echo "=== Starting Training ==="
echo "Arguments: $@"
echo "================================"
echo ""

# Run training
START_TIME=$(date +%s)

if [ "$CUDA_AVAILABLE" = "1" ]; then
    # GPU mode - use EGL (no xvfb needed)
    python3 -u main.py "$@" 2>&1 | tee condor_stream.log
    EXIT_CODE=${PIPESTATUS[0]}
else
    # CPU mode - use xvfb
    xvfb-run -a -s "-screen 0 1024x768x24 -ac +extension GLX +render -noreset" \
        python3 -u main.py "$@" 2>&1 | tee condor_stream.log
    EXIT_CODE=${PIPESTATUS[0]}
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "================================"
echo "=== Training Complete ==="
echo "Exit code: $EXIT_CODE"
echo "Duration: $DURATION seconds"

if [ $EXIT_CODE -ne 0 ]; then
    echo "Training failed!"
    exit $EXIT_CODE
fi

# Compress outputs
echo ""
echo "=== Compressing Outputs ==="
for dir in logs checkpoints outputs wandb; do
    if [ -d "$dir" ] && [ "$(ls -A $dir 2>/dev/null)" ]; then
        echo "Compressing $dir..."
        tar -czf ${dir}_$(date +%Y%m%d_%H%M%S).tar.gz $dir/ 2>/dev/null || echo "Warning: $dir compression failed"
    fi
done

echo ""
echo "Final files:"
ls -lh *.tar.gz 2>/dev/null || echo "No compressed files"
echo ""
echo "Job completed successfully!"