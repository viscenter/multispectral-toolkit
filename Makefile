%: %.cpp
	$(CXX) $(CFLAGS) $< $(LIBS) -o $@

CC = gcc
CXX = g++

UNAME := $(shell uname -s)

# Mac-specific flags
ifneq (,$(findstring Darwin,$(UNAME)))
	CFLAGS += -I/opt/local/include
	LIBS += -L/opt/local/lib
endif

CFLAGS += `pkg-config --cflags opencv`
LIBS += `pkg-config --libs opencv`

BUILDBINS = flatten flatfield

all: $(BUILDBINS)

clean:
	rm -f $(BUILDBINS)
