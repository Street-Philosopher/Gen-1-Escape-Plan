import os

#wtf is this lmao
# from sqlite3 import ProgrammingError

DEPENDENCIES_PATH = "converter\dependencies"
SCRIPT_PATH = f"converter\converter.cs"
BUILD_PATH = "build/converter.exe"
CSC_PATH = "csc"

try:
	os.system(f'{CSC_PATH} /r:"{DEPENDENCIES_PATH}\PKHeX.Core.dll" /r:"{DEPENDENCIES_PATH}\\netstandard.dll" /out:{BUILD_PATH} {SCRIPT_PATH}')
	print("done!")
except Exception as e:
	print("error while building:\n" + str(e))

#don't ask for input, if this is called from build_all it will have a parameter
import sys
if len(sys.argv) == 1:
	os.system("/bin/bash -c 'read -s -n 1 -p \"Press any key to continue...\"'" if os.name == "posix" else "pause")
