import sys, subprocess, json


# Check if `experimental_codegen` is enabled in the
# Foundry profile.
def is_experimental_codegen():
    try:
        result = subprocess.run(
            ["forge", "config", "--json"], capture_output=True, text=True, check=True
        )
        config = json.loads(result.stdout)
        return config.get("vyper", {}).get("experimental_codegen", False) == True
    except (subprocess.CalledProcessError, json.JSONDecodeError, KeyError):
        return False


# Build the Vyper command.
command = (
    ["vyper", "--experimental-codegen"] if is_experimental_codegen() else ["vyper"]
)
command += sys.argv[1:]

result = subprocess.run(command, capture_output=True, text=True)
if result.returncode != 0:
    raise Exception(f"Error compiling: {sys.argv[1]}")

# Remove any leading and trailing whitespace characters
# from the compilation result.
sys.stdout.write(result.stdout.strip())
