import sys, subprocess

result = subprocess.run(["vyper"] + sys.argv[1:], capture_output=True, text=True)
if result.returncode != 0:
    raise Exception("Error compiling: " + sys.argv[1])

# Remove any leading and trailing whitespace characters
# from the compilation result.
sys.stdout.write(result.stdout.strip())
