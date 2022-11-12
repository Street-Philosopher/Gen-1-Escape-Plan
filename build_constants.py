# imports (all private)
from os import name as _osname

# generic
BUILD_PATH = "build"

# executables / tools
CSC_PATH  = "mcs"      if _osname == "posix" else "csc.exe"
ASM_PATH  = "rgbasm"
LINK_PATH = "rgblink"

CONVERTER_BUILD_FOLDER = "monconverter"
PAYLOAD_BUILD_FOLDER   = "bytes"

# converter stuff
CONV_BUILD_NAME = "converter" if _osname == "posix" else "converter.exe"
CONV_DEPENDENCIES = [
	"PKHeX.Core.dll",
]
CONV_DEPENDENCIES_PATH = "converter/dependencies"
CONV_SRC_PATH = f"converter/converter.cs"

#payload stuff
ASM_ARGS  = ""			#"-gbz80 -nocase -chklabels -dotdir -Fbin"
LINK_ARGS = "-x"
PAYLOAD_SRC_PATH = "payload/payload.asm"
PAYLOAD_BUILDS = {
	"R-B_English" : 1,
	"R-B_Europe"  : 2,
	"G-S_English" : 3,
}

#reader
READER_PATH = "byteReader"
READER_NAME = "reader"
