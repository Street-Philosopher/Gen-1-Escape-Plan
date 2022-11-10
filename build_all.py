import os, glob, shutil

from build_constants import *

try:
	if not os.path.isdir(BUILD_PATH):
		os.mkdir(BUILD_PATH)

	print("building the converter...")
	if os.system("python3 " if os.name == "posix" else "" + "build_converter.py no") != 0:
		print("build aborted")
		exit(-1)

	print("\n")
	if os.system("python3 " if os.name == "posix" else "" + "build_payload.py no")   != 0:
		print("build aborted")
		exit(-1)

	print("\n")
	print("moving everything in a folder...")
	os.mkdir (f"{BUILD_PATH}/{CONVERTER_FOLDER}")
	os.mkdir (f"{BUILD_PATH}/{PAYLOAD_FOLDER}")
	os.mkdir (f"{BUILD_PATH}/{PAYLOAD_FOLDER}/res")

	os.rename(f"{BUILD_PATH}/{CONV_BUILD_NAME}", f"{BUILD_PATH}/{CONVERTER_FOLDER}/{CONV_BUILD_NAME}")
	shutil.copyfile("converter/dependencies/PKHeX.Core.dll", f'{BUILD_PATH}/{CONVERTER_FOLDER}/PKHeX.Core.dll')

	#copy py script into pyw
	shutil.copyfile("byteReader.py", f"{BUILD_PATH}/{PAYLOAD_FOLDER}/reader.pyw")
	#copy bytes files
	for file in glob.glob(f"{BUILD_PATH}/*.txt"):
		os.rename(file, f"{BUILD_PATH}/{PAYLOAD_FOLDER}/res/{os.path.basename(file)}")
	#copy any asset
	for file in glob.glob("byteReader/res/*"):
		shutil.copyfile(file, f"{BUILD_PATH}/{PAYLOAD_FOLDER}/res/{os.path.basename(file)}")

	print("zipping...")
	shutil.make_archive(f"{BUILD_PATH}/{CONVERTER_FOLDER}", 'zip', f"{BUILD_PATH}/{CONVERTER_FOLDER}")
	shutil.make_archive(f"{BUILD_PATH}/{PAYLOAD_FOLDER}",   'zip', f"{BUILD_PATH}/{PAYLOAD_FOLDER}")

	print("done!")
	RET_CODE = 0
except Exception as e:
	print("error while building:\n" + str(e))
	RET_CODE = 1
finally:
	print("cleaning up build files")
	files_for_cleanup = [
		f"{BUILD_PATH}/{CONVERTER_FOLDER}.zip",
		f"{BUILD_PATH}/{PAYLOAD_FOLDER}.zip",
		f"{BUILD_PATH}/{CONV_BUILD_NAME}",
		f"{BUILD_PATH}/{CONVERTER_FOLDER}/{CONV_BUILD_NAME}",
	]
	dirs_for_cleanup = [
		f"{BUILD_PATH}/{CONVERTER_FOLDER}",
		f"{BUILD_PATH}/{PAYLOAD_FOLDER}"
	]
	for dir in dirs_for_cleanup:
		if os.path.isdir(dir):
			os.remove(dir)
	for file in glob.glob(f"{BUILD_PATH}/*.txt"):
		os.remove(file)
	for file in files_for_cleanup:
		if os.path.isfile(file):
			os.remove(file)

print("all finished!\n")
# /bin/bash -c 'read -s -n 1 -p \"Press any key to continue...\n\"'
os.system("" if os.name == "posix" else "pause")
exit(RET_CODE)
