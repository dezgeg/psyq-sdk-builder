#!/usr/bin/env python3
import sys
import os
import shutil
import subprocess

def extract_news(archive_path, outdir):
    os.makedirs(outdir, exist_ok=True)

    # Copy README.TXT if present in the same directory as NEWSLIB.Z
    archive_dir = os.path.dirname(archive_path)
    for readme_name in ["README.TXT", "readme.txt"]:
        readme_path = os.path.join(archive_dir, readme_name)
        if os.path.isfile(readme_path):
            shutil.copy2(readme_path, os.path.join(outdir, "README.TXT"))
            break

    # Decompress .Z archive using gzip -dc
    p = subprocess.Popen(["gzip", "-dc", archive_path], stdout=subprocess.PIPE)
    data, _ = p.communicate()
    if p.returncode != 0:
        sys.exit(f"Failed to decompress {archive_path}")

    # Parse CPIO datastream
    pos = 0
    while pos < len(data):
        idx1 = data.find(b"070701", pos)
        idx2 = data.find(b"070702", pos)
        if idx1 == -1 and idx2 == -1:
            break
        if idx1 != -1 and idx2 != -1:
            pos = min(idx1, idx2)
        else:
            pos = max(idx1, idx2)

        while pos + 110 <= len(data):
            magic = data[pos:pos+6]
            if magic not in (b"070701", b"070702"):
                break
            filesize = int(data[pos+54:pos+62], 16)
            namesize = int(data[pos+94:pos+102], 16)
            name_start = pos + 110
            name_end = name_start + namesize - 1  # drop null terminator
            name = data[name_start:name_end].decode("latin1", errors="ignore")
            pos = ((name_start + namesize + 3) // 4) * 4
            content = data[pos:pos+filesize]
            pos = ((pos + filesize + 3) // 4) * 4

            if name == "TRAILER!!!":
                break

            # Filter for Sony PSX include and lib files
            prefix = "root/usr/sony/psx/"
            if name.startswith(prefix):
                rel = name[len(prefix):]
                parts = rel.split("/")
                category = parts[0].lower()

                if category == "lib":
                    # Only keep .a and .o library files directly under lib
                    if len(parts) == 2 and (parts[1].lower().endswith(".a") or parts[1].lower().endswith(".o")):
                        dest_file = os.path.join(outdir, "LIB", parts[1].upper())
                        os.makedirs(os.path.dirname(dest_file), exist_ok=True)
                        with open(dest_file, "wb") as f:
                            f.write(content)
                elif category == "include":
                    # Keep all header files under include
                    upper_parts = [p.upper() for p in parts[1:]]
                    dest_file = os.path.join(outdir, "INCLUDE", *upper_parts)
                    os.makedirs(os.path.dirname(dest_file), exist_ok=True)
                    with open(dest_file, "wb") as f:
                        f.write(content)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(f"Usage: {sys.argv[0]} <path-to-NEWSLIB.Z> <output-directory>")
    extract_news(sys.argv[1], sys.argv[2])
