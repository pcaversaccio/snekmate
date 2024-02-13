import os, subprocess, shutil

base_path = os.path.join(os.getcwd(), "src")
dir_list = ["auth", "extensions", "governance", "tokens", "utils"]
dest_build = os.path.join(base_path, "snekmate")

# Create a dedicated `snekmate` directory.
os.mkdir(dest_build)

# Before generating the distribution package, move all
# contracts to a dedicated `snekmate` directory.
for dir in dir_list:
    source = os.path.join(base_path, dir)
    if os.path.isdir(source):
        shutil.move(source, dest_build)

# Build a binary wheel and a source tarball.
subprocess.run(["python3", "-m", "build"])

# After generating the distribution package, move all
# contracts back to the original destination.
for dir in dir_list:
    source = os.path.join(base_path, "snekmate", dir)
    if os.path.isdir(source):
        shutil.move(source, base_path)

# Delete the dedicated `snekmate` directory.
shutil.rmtree(dest_build)
