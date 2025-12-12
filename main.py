#!/usr/bin/env python3
"""
main.py
Entry point for running SheepRL experiments from exp.sh.
Accepts arbitrary CLI arguments and passes them to sheeprl.
"""

import sys
import subprocess

def main():
    # Collect all command-line arguments passed to main.py
    # Example usage: python main.py exp=ppo env=gym env.id=CartPole-v1
    args = sys.argv[1:]

    if not args:
        print("No arguments provided. Example usage:")
        print("python main.py exp=ppo env=gym env.id=CartPole-v1")
        sys.exit(1)

    # Construct the command to run SheepRL
    # If installed via PyPI: "sheeprl ..."
    # If running from repo clone: "python sheeprl.py ..."
    cmd = ["python3", "sheeprl.py"] + args

    print(f"Running command: {' '.join(cmd)}")
    
    # Run the command
    result = subprocess.run(cmd)
    
    if result.returncode != 0:
        print(f"SheepRL experiment failed with return code {result.returncode}")
        sys.exit(result.returncode)
    else:
        print("Experiment completed successfully.")

if __name__ == "__main__":
    main()
