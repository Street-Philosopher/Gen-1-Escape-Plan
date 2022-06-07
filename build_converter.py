import os

#wtf is this lmao
# from sqlite3 import ProgrammingError

DEPENDENCIES_PATH = "converter\dependencies"
SCRIPT_PATH = f"converter\converter.cs"
BUILD_PATH = "build/converter.exe"

try:
	os.system(f'csc /r:"{DEPENDENCIES_PATH}\PKHeX.Core.dll" /r:"{DEPENDENCIES_PATH}\\netstandard.dll" /out:{BUILD_PATH} {SCRIPT_PATH}')
	print("done!")
except Exception as e:
	print("error while building:\n" + str(e))

#don't ask for input, if this is called from build_all it will have a parameter
import sys
if len(sys.argv) == 1:
	input()