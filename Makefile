CC=gcc

STATIC_JEM=yes
STATIC_LIBEV=yes

STUD_C=ringbuffer.c stud.c
STUD_HTTP_C=$(STUD_C) proto_http.c http-parser/http_parser.o

BASIC_DEPS=$(STUD_C) Makefile
HTTP_DEPS=http-parser/http_parser.o proto_http.c proto_http.h
JEM_DEPS=jemalloc/lib/libjemalloc.a
LIBEV_DEPS=libev/lib/libev.a

LIBEV_STATIC=libev/lib/libev.a -lm
JEM_STATIC=jemalloc/lib/libjemalloc.a -ldl -lpthread

LDFLAGS=-L/usr/local/lib -L/sw/lib

CFLAGS=-O2 -g --std=c99 -fno-strict-aliasing -Wall -W -D_GNU_SOURCE
CFLAGS+=-I/usr/local/include -I./libev/include -I/sw/include
HTTP_CFLAGS=-DPROTO_HTTP $(CFLAGS)

ifeq ($(STATIC_JEM), yes)
  JEM=$(JEM_STATIC)
else
  JEM=-ljemalloc
  JEM_DEPS=
endif

ifeq ($(STATIC_LIBEV), yes)
  LIBEV=$(LIBEV_STATIC)
else
  LIBEV=-lev
  LIBEV_DEPS=
endif

LIBS=-lssl -lcrypto $(LIBEV)

.PHONY: default bonus

default: stud
all: stud stud-jem stud-http stud-http-jem

stud: $(BASIC_DEPS) $(LIBEV_DEPS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(STUD_C) $(LIBS)

stud-jem: $(BASIC_DEPS) $(JEM_DEPS) $(LIBEV_DEPS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(STUD_C) $(LIBS) $(JEM)

stud-http: $(BASIC_DEPS) $(HTTP_DEPS) $(LIBEV_DEPS)
	$(CC) $(HTTP_CFLAGS) $(LDFLAGS) -o $@ $(STUD_HTTP_C) $(LIBS)

stud-http-jem: $(BASIC_DEPS) $(HTTP_DEPS) $(JEM_DEPS) $(LIBEV_DEPS)
	$(CC) $(HTTP_CFLAGS) $(LDFLAGS) -o $@ $(STUD_HTTP_C) $(LIBS) $(JEM)

http-parser/http_parser.o: http-parser/README.md
	make -C http-parser http_parser.o

http-parser/README.md:
	git clone http://github.com/joyent/http-parser
	cd http-parser # && git checkout -b jul6_stable 1786fdae36d3d40d59463dacab1cfb4165cf9f1d

jemalloc/lib/libjemalloc.a: jemalloc/autogen.sh

jemalloc/autogen.sh:
	git clone git://canonware.com/jemalloc.git
	cd jemalloc; ./autogen.sh; make -j4

libev/lib/libev.a:
	curl -O http://dist.schmorp.de/libev/Attic/libev-4.04.tar.gz
	tar xfvzp libev*.gz
	cd libev-*; ./configure --prefix=`pwd`/../libev/; make install

install: stud
	cp stud /usr/local/bin

clean:
	rm -f stud stud-jem stud-http stud-http-jem *.o tags
	rm -rf jemalloc/ http-parser/ libev*
