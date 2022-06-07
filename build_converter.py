import os
#TODO: add PKHeX import

#wtf is this lmao
# from sqlite3 import ProgrammingError

PROGRAM_PATH = f"converter\converter.cs"
BUILD_PATH = "build/converter.exe"

try:
	os.system(f'csc /r:"converter\dependencies\PKHeX.Core.dll" /r:"converter\dependencies\\netstandard.dll" /out:{BUILD_PATH} {PROGRAM_PATH}')
	# if os.path.isfile(BUILD_PATH):
	# 	os.remove(BUILD_PATH)
	print("done!")
except Exception as e:
	print("error while building:\n" + str(e))

#don't ask for input, if this is called from build_all it will have a parameter
import sys
if len(sys.argv) == 1:
	input()