# imports (all private)
from os import name as _osname

# generic
BUILD_PATH = "build"

# executables / tools
CSC_PATH  = "mcs"      if _osname == "posix" else "csc.exe"
VASM_PATH = "./__vasm" if _osname == "posix" else "__vasm.exe"

CONVERTER_FOLDER = "converter"
PAYLOAD_FOLDER   = "bytes"

# converter stuff
CONV_BUILD_NAME = "converter" if _osname == "posix" else "converter.exe"
CONV_DEPENDENCIES = [
	"PKHeX.Core.dll",
	"netstandard.dll",
]
CONV_DEPENDENCIES_PATH = "converter/dependencies"
CONV_SRC_PATH = f"converter/converter.cs"

#payload stuff
VASM_ARGS = "-gbz80 -nocase -chklabels -dotdir -Fbin"
PAYLOAD_SRC_PATH = "payload/"
