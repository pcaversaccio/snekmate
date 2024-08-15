import os


def insert_venom_pragma(filepath):
    with open(filepath, "r+") as f:
        lines = f.readlines()
        if len(lines) < 2:
            lines.append("")
        # Insert `pragma experimental-codegen` on the second line to activate the `venom` backend.
        lines.insert(1, "# pragma experimental-codegen\n")
        # Move the file pointer back to the beginning of the file.
        f.seek(0)
        f.writelines(lines)


def process_directory(directory):
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith((".vy", ".vyi")):
                insert_venom_pragma(os.path.join(root, file))


if __name__ == "__main__":
    process_directory("src/snekmate")
