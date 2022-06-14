import os

VASM_PATH = "vasmz80_oldstyle_win32.exe"
VASM_ARGS = "-gbz80 -nocase -chklabels -dotdir -Fbin"
TEMPFILE_NAME = "temp.bin"
BUILT_NAME = "build/bytes.txt"
ASM_PATH = "payload/program_en.asm"

try:
	print("assembling...")
	os.system(f'{VASM_PATH} {VASM_ARGS} -o "{TEMPFILE_NAME}" "{ASM_PATH}"')

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

	print("done!")
except Exception as e:
	print("error while building:\n" + str(e))

#don't ask for input, if this is called from build_all it will have a parameter
import sys
if len(sys.argv) == 1:
	os.system("/bin/bash -c 'read -s -n 1 -p \"Press any key to continue...\"'" if os.name == "posix" else "pause")
