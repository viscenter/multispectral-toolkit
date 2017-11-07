%: %.cpp
	$(CXX) $(CFLAGS) $< $(LIBS) -o $@

CC = gcc
CXX = g++

CFLAGS += -Wall -std=c++11 $(shell pkg-config --cflags opencv)
LIBS += -lopencv_core -lopencv_highgui -lopencv_imgcodecs -lopencv_imgproc -lopencv_photo

BUILDBINS = pngflatten despot

all: $(BUILDBINS)

clean:
	rm -f $(BUILDBINS)
