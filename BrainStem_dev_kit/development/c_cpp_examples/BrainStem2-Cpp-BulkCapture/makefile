# Brainstem2A2DBulkCapture Cpp

CPP = g++
ROOT = .
TARGET = Brainstem2A2DBulkCapture
OUT := linux_$(TARGET)
DBG_DST := $(OUT)/Debug
REL_DST := $(OUT)/Release

# We are looking for the BrainStem2 library in
# a lib folder sibling to this makefile. Change
# these defines to point somewhere else if this
# is not the case.
LIBRARIES := -L$(ROOT)/lib -lBrainStem2
INCLUDES := -Ilib/

# We add the current directory to the rpath expecting
# that libBrainStem2.so will be copied into the build
# folder. If this is not the case adjust the rpath
# do match your needs.
CFLAGS = -Wall -Werror -Wl,-rpath,. $(INCLUDES)

all : dirs
	make app

app : debug release

.PHONY : debug
debug:
	$(CPP) $(CFLAGS) BrainStem2A2DBulkCapture/main.cpp $(LIBRARIES) -o $(DBG_DST)/BrainStem2A2DBulkCapture
	cp lib/libBrainStem2.so $(DBG_DST)
.PHONY : release
release:
	$(CPP) $(CFLAGS) -DNDEBUG BrainStem2A2DBulkCapture/main.cpp $(LIBRARIES) -o $(REL_DST)/BrainStem2A2DBulkCapture
	cp lib/libBrainStem2.so $(REL_DST)

.PHONY : dirs
dirs:
	mkdir -p $(DBG_DST)
	mkdir -p $(REL_DST)

clean:
	rm -rf $(OUT)
