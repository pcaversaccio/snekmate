import os


def add_venom_pragma(filepath):
    with open(filepath, "r") as file:
        lines = file.readlines()

    # Insert `pragma experimental-codegen` in the second line to activate the `venom` backend.
    if len(lines) >= 2:
        lines.insert(1, "# pragma experimental-codegen\n")
    else:
        lines.append("# pragma experimental-codegen\n")

    # Write the modified lines back to the file.
    with open(filepath, "w") as file:
        file.writelines(lines)


def process_directory(directory):
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".vy") or file.endswith(".vyi"):
                filepath = os.path.join(root, file)
                add_venom_pragma(filepath)


if __name__ == "__main__":
    src_directory = "src/snekmate"
    process_directory(src_directory)
