import os, glob
from pickle import BUILD

from build_constants import *

if not os.path.isdir(BUILD_PATH):
	os.mkdir(BUILD_PATH)

# rgbasm [file] -o [out]
# rgblink [out] -x -o out.temp
# out.temp->remove_unnecessary
# writebytes.txt(out.temp)
# remove(out, out.temp)

try:
	print("assembling the payloads...")
	retval = 0		#if any thing has a return value of not 0 then this will be != 0

	TEMPFILE_NAME = f"{BUILD_PATH}/payload.temp"		#name of the temp file created by the assembler
	LINK_TEMP_NAME= f"{BUILD_PATH}/payload.link"		#name of the temp file created by the linker

	for VERSION in PAYLOAD_BUILDS:
		print("building the", VERSION, "version")

		BUILT_NAME = f"{BUILD_PATH}/{VERSION}.txt"		#name of the built file

		retval += os.system(f'{ASM_PATH} {ASM_ARGS} -D VERSION={PAYLOAD_BUILDS[VERSION]} -o "{TEMPFILE_NAME}" "{PAYLOAD_SRC_PATH}"')
		retval += os.system(f'{LINK_PATH} {LINK_ARGS} -x -o "{LINK_TEMP_NAME}" "{TEMPFILE_NAME}"')

		print("writing the bytes.txt file...")
		with open(LINK_TEMP_NAME, "rb") as ifile, open(BUILT_NAME, "w") as ofile:
			allbytes = list(ifile.read(-1))
			res = ""
			for byte in allbytes:
				byte = "%0.2X" % byte
				res += byte + "\n"
			res = res[:-1]	#get rid of the last endline
			ofile.write(res)

		print("removing temp files...")
		os.remove(TEMPFILE_NAME)
		os.remove(LINK_TEMP_NAME)
		print("\n\n")
	#END FOR

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
	os.system("/bin/bash -c 'read -s -n 1 -p \"Press any key to continue...\n\"'" if os.name == "posix" else "pause")

exit(RET_CODE)
