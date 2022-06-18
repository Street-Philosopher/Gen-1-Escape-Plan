import os, glob

VASM_PATH = "vasmz80_oldstyle_win32.exe"
VASM_ARGS = "-gbz80 -nocase -chklabels -dotdir -Fbin"
BUILD_PATH = "build/"
ASM_PATH = "payload/"

try:
	print("assembling...")

	for FILE in glob.glob(ASM_PATH + "program_*.asm"):
		ext = FILE[len(ASM_PATH + "program_"):-4]		#this will remove everything except the "version"
		print("building the", ext, "version:")

		TEMPFILE_NAME = ext + ".temp"					#name of the temp file that will be created
		BUILT_NAME = BUILD_PATH + f"bytes_{ext}.txt"	#name of the built file

		os.system(f'{VASM_PATH} {VASM_ARGS} -o "{TEMPFILE_NAME}" "{FILE}"')

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

	print("done!")
except Exception as e:
	print("error while building:\n" + str(e))

#don't ask for input, if this is called from build_all it will have a parameter
import sys
if len(sys.argv) == 1:
	os.system("/bin/bash -c 'read -s -n 1 -p \"Press any key to continue...\"'" if os.name == "posix" else "pause")
