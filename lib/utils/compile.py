import sys, subprocess

path = sys.argv[1]

if len(sys.argv) > 2:
    # If the EVM version is configured.
    result = subprocess.run(
        ["vyper", path, sys.argv[2], sys.argv[3]], capture_output=True, text=True
    )
else:
    result = subprocess.run(["vyper", path], capture_output=True, text=True)

if result.stderr != "":
    raise Exception("Error compiling: " + path)

# Remove any leading and trailing whitespace characters
# from the compilation result.
sys.stdout.write(result.stdout.strip())
