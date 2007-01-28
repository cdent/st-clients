HOST=www.socialtext.net
#PORT=:21002
WSDL_FILE=0.9.wsdl
WSDL_URL=http://$(HOST)$(PORT)/static/wsdl/$(WSDL_FILE)

GENERATED_SOURCES = soapC.cpp soapClient.cpp soapStub.h soapH.h
CLIENT_SOURCES = st-client.cpp soapC.cpp soapClient.cpp stdsoap2.cpp

all: st-client

$(WSDL_FILE):
	GET $(WSDL_URL) > $@

st-wsdl.h: $(WSDL_FILE)
	wsdl2h -o $@ $(WSDL_FILE)

$(GENERATED_SOURCES): st-wsdl.h
	soapcpp2 -I /usr/include/gsoap $<

st-client: stdsoap2.h st-wsdl.h st-client.cpp $(GENERATED_SOURCES)
	g++ -o st-client -DWITH_OPENSSL -lssl $(CLIENT_SOURCES)

test: st-client
	./st-client

clean:
	find . -type f \
	    -not -name st-client.cpp \
	    -not -name st-client.h \
	    -not -name Makefile \
	    -not -name 'stdsoap2.*' \
	    -not -name tags \
	    -not -name TIPS \
	    -not -path '*.svn*' \
	| xargs rm

.PHONY: all test clean wsdl
