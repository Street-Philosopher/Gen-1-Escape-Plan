import os

print("building the converter...")
os.system("build_converter.py no")

print("\n\n")
print("building the payload...")
os.system("build_payload.py no")

os.system("/bin/bash -c 'read -s -n 1 -p \"Press any key to continue...\n\"'" if os.name == "posix" else "pause")
