#!/usr/bin/env python3
import argparse
import subprocess
import time
import os

def str2bool(v):
    return v.lower() in ("yes", "true", "t", "1", "y")

parser = argparse.ArgumentParser(description="Submit SheepRL experiments to CHTC via Condor")

# Experiment arguments
parser.add_argument("--result_directory", type=str, required=True,
                    help="Directory to save experiment results")
parser.add_argument("--condor", action="store_true",
                    help="Submit job(s) to Condor")
parser.add_argument("--num_seeds", type=int, default=1,
                    help="Number of random seeds to run")
parser.add_argument("--extra_args", type=str, default="",
                    help="Extra arguments to pass directly to main.py / SheepRL")
parser.add_argument("--use_gpu", type=str2bool, default=True,
                    help="Whether to request GPU in Condor jobs")

FLAGS = parser.parse_args()

# Make sure the results directory exists
os.makedirs(FLAGS.result_directory, exist_ok=True)

def make_arguments(seed):
    # Parse FLAGS.extra_args
    extra = FLAGS.extra_args.split() if FLAGS.extra_args else []
    
    args_list = []
    
    for token in extra:
        # Pass through tokens as-is - don't add extra + symbols
        args_list.append(token)
    
    # Add seed
    args_list.append(f"seed={seed}")
    
    return " ".join(args_list)

def submit_job(seed):
    args = make_arguments(seed)

    sub = ""
    sub += "universe = vanilla\n"
    sub += "executable = exp.sh\n"
    sub += f"arguments = {args}\n"
    sub += "log = condor.log\n"
    sub += "output = condor.out\n"
    sub += "error = condor.err\n"

    # enable live streaming
    sub += "stream_output = true\n"

    sub += "should_transfer_files = YES\n"
    sub += "when_to_transfer_output = ON_EXIT\n"
    sub += "container_image = osdf:///chtc/staging/pandey36/sheeprl-local.sif\n"
    sub += (
        "transfer_input_files = assets, benchmarks, docs, hydra_plugins, "
        "notebooks, sheeprl, tests, setup.py, sheeprl_eval.py, "
        "sheeprl_model_manager.py, sheeprl.py, apptainer, main.py, exp.sh\n"
    )
    sub += "requirements = (OpSysMajorVer > 7)\n"

    if FLAGS.use_gpu:
        sub += "+WantGPULab = true\n"
        sub += '+GPUJobLength = "medium"\n'
        sub += "request_gpus = 1\n"
        sub += "+GPU_MEMORY = 20000\n"  # MB
        sub += "request_cpus = 4\n"
        sub += "request_memory = 50GB\n"
        sub += "request_disk = 50GB\n"
    else:
        sub += "request_cpus = 4\n"
        sub += "request_memory = 16GB\n"
        sub += "request_disk = 50GB\n"

    # Submit the job
    p = subprocess.Popen("condor_submit", stdin=subprocess.PIPE, text=True)
    p.stdin.write(sub)
    p.stdin.close()
    time.sleep(0.3)

def main():
    if not FLAGS.condor:
        print("ERROR: You must pass --condor to actually submit.")
        return

    for seed in range(FLAGS.num_seeds):
        print(f"Submitting job seed={seed}")
        submit_job(seed)

    print(f"Submitted {FLAGS.num_seeds} jobs.")

if __name__ == "__main__":
    main()
