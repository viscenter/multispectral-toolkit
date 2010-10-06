%: %.cpp
	$(CXX) $(CFLAGS) $< $(LIBS) -o $@

CC = gcc
CXX = g++

CFLAGS += `pkg-config --cflags opencv`
LIBS += `pkg-config --libs opencv`

BUILDBINS = flatten flatfield

all: $(BUILDBINS)

clean:
	rm -f $(BUILDBINS)
