VASM_PATH = "vasmz80_oldstyle_win32.exe"
TEMPFILE_NAME = "temp.bin"
BUILT_NAME = "payload/bytes.txt"
ASM_PATH = "payload/program.asm"

try:
	import os

	def ByteToHex(byte):
		pass

	print("assembling...")
	os.system(f'{VASM_PATH} -gbz80 -nocase -chklabels -dotdir -Fbin -o "{TEMPFILE_NAME}" "{ASM_PATH}"')

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

input()