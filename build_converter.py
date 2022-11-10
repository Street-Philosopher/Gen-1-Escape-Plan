import os
from build_constants import *

#wtf is this lmao
# from sqlite3 import ProgrammingError

if not os.path.isdir(BUILD_PATH):
	os.mkdir(BUILD_PATH)

try:
	command = f'{CSC_PATH} ' + "".join(
		f'/r:"{CONV_DEPENDENCIES_PATH}/{dependency}" ' for dependency in CONV_DEPENDENCIES
	) + f'/out:{BUILD_PATH}/{CONV_BUILD_NAME} {CONV_SRC_PATH}'
	retval = os.system(command)
	if retval != 0:
		RET_CODE = 1
	else:
		print("done!")
		RET_CODE = 0
except Exception as e:
	print("error while building:\n" + str(e))
	RET_CODE = 1

#don't ask for input, if this is called from build_all it will have a parameter
import sys
if len(sys.argv) == 1:
	# /bin/bash -c 'read -s -n 1 -p \"Press any key to continue...\n\"'
	os.system("" if os.name == "posix" else "pause")

exit(RET_CODE)
