import os, glob

from build_constants import *

if not os.path.isdir(BUILD_PATH):
	os.mkdir(BUILD_PATH)

try:
	print("assembling the payload...")
	retval = 0		#if any thing has a return value of not 0 then this will be != 0

	for FILE in glob.glob(PAYLOAD_SRC_PATH + "program_*.asm"):
		ext = FILE[len(PAYLOAD_SRC_PATH + "program_") : -len(".asm")]		#this will remove everything except the "version"
		print("building the", ext, "version:")

		TEMPFILE_NAME = ext + ".temp"					#name of the temp file that will be created
		BUILT_NAME = f"{BUILD_PATH}/bytes_{ext}.txt"	#name of the built file

		retval += os.system(f'{VASM_PATH} {VASM_ARGS} -o "{TEMPFILE_NAME}" "{FILE}"')

		print()
		print("writing the bytes.txt file...")
		with open(TEMPFILE_NAME, "rb") as ifile, open(BUILT_NAME, "w") as ofile:
			allbytes = list(ifile.read(-1))
			res = ""
			for byte in allbytes:
				byte = "%0.2X" % byte
				res += byte + "\n"
			res = res[:-1]	#get rid of the last endline
			ofile.write(res)

		print()
		print("removing temp file...")
		os.remove(TEMPFILE_NAME)
		print("\n\n")

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
