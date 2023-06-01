import subprocess, glob

for filename in glob.glob("**/*.vy", recursive=True):
    result = subprocess.run(
        ["vyper", "-f", "userdoc,devdoc", filename], capture_output=True, text=True
    )
    if result.stderr != "":
        raise Exception("Error compiling: " + filename)
    print("stdout:", result.stdout)
