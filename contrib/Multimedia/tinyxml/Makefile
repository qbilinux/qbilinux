INCS = tinystr.h tinyxml.h
SRCS = tinystr.cpp tinyxmlerror.cpp tinyxml.cpp tinyxmlparser.cpp
OBJS = $(SRCS:.cpp=.o)
TARGET = libtinyxml.so
CXX = g++
CXXFLAGS = -O3 -Wall -fPIC
LDFLAGS = -shared
LIBS = 
LIBDIR = /usr/lib
# INSTFLAGS = -s
INSTFLAGS = 

all: $(OBJS)
	$(CXX) $(LDFLAGS) $(OBJS) $(LIBS) -o $(TARGET)
	@echo done.

install: all
	install -d $(DESTDIR)/usr/include $(DESTDIR)$(LIBDIR)
	install $(INSTFLAGS) $(INCS) $(DESTDIR)/usr/include
	install $(INSTFLAGS) $(TARGET) $(DESTDIR)$(LIBDIR)

$(OBJS): $(SRCS) $(INCS)
	$(CXX) $(CXXFLAGS) $(SRCS) -c

clean:
	rm -rf *.o core.* *# *~ $(TARGET)
