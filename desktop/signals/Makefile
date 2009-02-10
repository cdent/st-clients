objects = bin/Main.mxml.swf

$(objects): bin/%.swf: src/%
	@-mkdir bin
	amxmlc -output $@ $<

all: $(objects)

run: all
	adl Signals.xml bin

dist: all
	adt -package -storetype pkcs12 -keystore etc/selfsigned.p12 Signals.air Signals.xml -C bin .
