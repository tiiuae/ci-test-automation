# Brainstem2Example C

CPP = g++
CPPFLAGS = -std=c++11
ROOT = .
TARGET = AcronameHubCLI
OUT := linux_$(TARGET)
DBG_DST := $(OUT)/Debug
REL_DST := $(OUT)/Release
STC_DST := $(OUT)/Static

# We are looking for the BrainStem2 library in
# a lib folder sibling to this makefile. Change
# these defines to point somewhere else if this
# is not the case.
LIBRARIES := -L$(ROOT)/lib -lBrainStem2
STATICLIBS := lib/libBrainStem2.a -lpthread -ludev
INCLUDES := -Ilib/

# We add the current directory to the rpath expecting
# that libBrainStem2.so will be copied into the build
# folder. If this is not the case adjust the rpath
# do match your needs.
CFLAGS = -Wall -Werror -Wl,-rpath,. $(INCLUDES)

all :
	make app

app : debug release static

.PHONY : debug
debug:
	mkdir -p $(DBG_DST)
	$(CPP) $(CPPFLAGS) $(CFLAGS) $(TARGET)/main.cpp $(LIBRARIES) -o $(DBG_DST)/$(TARGET)
	cp lib/libBrainStem2.so $(DBG_DST)

.PHONY : release
release:
	mkdir -p $(REL_DST)
	$(CPP) $(CPPFLAGS) $(CFLAGS) -DNDEBUG $(TARGET)/main.cpp $(LIBRARIES) -o $(REL_DST)/$(TARGET)
	cp lib/libBrainStem2.so $(REL_DST)

.PHONY : static
static:
	mkdir -p $(STC_DST)
	$(CPP) $(CPPFLAGS) $(CFLAGS) -DNDEBUG $(TARGET)/main.cpp $(STATICLIBS) -o $(STC_DST)/$(TARGET)

clean:
	rm -rf $(OUT)

