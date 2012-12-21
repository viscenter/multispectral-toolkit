%: %.cpp
	$(CXX) $(CFLAGS) $< $(LIBS) -o $@

CC = gcc
CXX = g++

CFLAGS += $(shell pkg-config --cflags opencv)
LIBS += $(shell pkg-config --libs opencv)

BUILDBINS = flatten pngflatten

all: $(BUILDBINS)

clean:
	rm -f $(BUILDBINS)
