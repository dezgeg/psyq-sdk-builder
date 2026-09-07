#!/usr/bin/env python3
import sys
import os
import struct
import subprocess
import tempfile

IGNORED_MODULES = {"snmain", "2mbyte", "8mbyte", "cache"}

def convert_lib_file(parser_bin, lib_path, out_a_path):
    with open(lib_path, "rb") as f:
        data = f.read()

    modules = []
    if data.startswith(b"LIB\x01"):
        pos = 4
        while pos < len(data):
            mod_name = data[pos:pos+8].decode("latin1", errors="ignore").strip()
            if pos + 20 > len(data):
                break
            w1, w2 = struct.unpack("<II", data[pos+12:pos+20])
            if w2 == 0 or pos + w2 > len(data):
                break
            obj_data = data[pos+w1 : pos+w2]
            pos += w2
            modules.append((mod_name, obj_data))
    elif data.startswith(b"LIB\x02"):
        # Concatenated LNK objects
        indices = []
        pos = 0
        while True:
            idx = data.find(b"LNK\x02", pos)
            if idx == -1:
                break
            indices.append(idx)
            pos = idx + 4
        indices.append(len(data))
        for i in range(len(indices) - 1):
            chunk = data[indices[i]:indices[i+1]]
            modules.append((f"MOD_{i:03d}", chunk))
    else:
        print(f"Skipping unknown format: {lib_path}")
        return

    with tempfile.TemporaryDirectory() as td:
        o_files = []
        for mod_name, obj_data in modules:
            if mod_name.lower() in IGNORED_MODULES:
                continue
            obj_file = os.path.join(td, f"{mod_name}.OBJ")
            o_file = os.path.join(td, f"{mod_name}.o")
            with open(obj_file, "wb") as f_obj:
                f_obj.write(obj_data)

            res = subprocess.run([parser_bin, obj_file, "-o", o_file], capture_output=True)
            if res.returncode == 0 and os.path.exists(o_file):
                o_files.append(f"{mod_name}.o")
            else:
                # Log warning and skip unconvertible object
                err = res.stderr.decode(errors="ignore").strip() or res.stdout.decode(errors="ignore").strip()
                first_line = err.splitlines()[-1] if err else "unknown error"
                print(f"  [{os.path.basename(lib_path)}] Skipping {mod_name}: {first_line}")

        if o_files:
            if os.path.exists(out_a_path):
                os.unlink(out_a_path)
            subprocess.run(["ar", "rcs", out_a_path] + o_files, cwd=td, check=True)
            print(f"Created {out_a_path} ({len(o_files)} modules)")

def convert_standalone_obj(parser_bin, obj_path, out_o_path):
    base = os.path.splitext(os.path.basename(obj_path))[0].lower()
    if base in IGNORED_MODULES:
        return
    res = subprocess.run([parser_bin, obj_path, "-o", out_o_path], capture_output=True)
    if res.returncode == 0:
        print(f"Created {out_o_path}")
    else:
        err = res.stderr.decode(errors="ignore").strip() or res.stdout.decode(errors="ignore").strip()
        first_line = err.splitlines()[-1] if err else "unknown error"
        print(f"  Skipping {os.path.basename(obj_path)}: {first_line}")

def main():
    if len(sys.argv) != 4:
        sys.exit(f"Usage: {sys.argv[0]} <psyq-obj-parser> <input-lib-dir> <output-elf-dir>")

    parser_bin = os.path.abspath(sys.argv[1])
    lib_dir = os.path.abspath(sys.argv[2])
    elf_dir = os.path.abspath(sys.argv[3])

    if not os.path.isdir(lib_dir):
        print(f"Input dir {lib_dir} does not exist, skipping.")
        return

    os.makedirs(elf_dir, exist_ok=True)

    for item in sorted(os.listdir(lib_dir)):
        item_path = os.path.join(lib_dir, item)
        if not os.path.isfile(item_path):
            continue
        upper_item = item.upper()
        if upper_item.endswith(".LIB"):
            out_name = os.path.splitext(upper_item)[0] + ".A"
            out_path = os.path.join(elf_dir, out_name)
            convert_lib_file(parser_bin, item_path, out_path)
        elif upper_item.endswith(".OBJ"):
            out_name = os.path.splitext(upper_item)[0] + ".O"
            out_path = os.path.join(elf_dir, out_name)
            convert_standalone_obj(parser_bin, item_path, out_path)

if __name__ == "__main__":
    main()
