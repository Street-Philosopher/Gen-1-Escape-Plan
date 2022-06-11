import os

print("building the converter...")
os.system("build_converter.py no")
#i could do this but i don't want pycache
# import build_converter

print("\n\n")
print("building the payload...")
os.system("build_payload.py no")
# import build_payload

os.system("/bin/bash -c 'read -s -n 1 -p \"Press any key to continue...\"'" if os.name == "posix" else "pause")
