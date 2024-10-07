import sys, subprocess


# Check if `experimental_codegen` is enabled in the
# Foundry profile.
def is_experimental_codegen():
    return (
        subprocess.run(
            ["bash", "-c", 'forge config --json | jq -r ".vyper.experimental_codegen"'],
            capture_output=True,
            text=True,
        )
        .stdout.strip()
        .lower()
        == "true"
    )


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
