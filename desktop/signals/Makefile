distfile = Signals.air

run = env PATH=${PATH}:/opt/flex/bin

objects = bin/Main.mxml.swf

$(objects): bin/%.mxml.swf: mxml/%.mxml as/*.as css/*.css
	@-mkdir bin
	$(run) amxmlc -incremental -output $@ $<

default: all

all: check-deps $(objects)

run: $(objects)
	@rsync -au --delete html js css bin
	$(run) adl Signals.xml bin

dist: $(objects)
	@rsync -au --delete html js css bin
	$(run) adt -package -storetype pkcs12 -keystore /etc/selfsigned.p12 $(distfile) Signals.xml -C bin .

clean:
	-rm -rf bin
	-rm $(distfile)

check-deps:
	@java -version >/dev/null 2>/dev/null || (echo "*** Java runtime must be installed and included in PATH.\n\n    You can download it from: http://java.com/." && exit 1)
	@amxmlc -version >/dev/null 2>/dev/null || (echo "*** Flex SDK must be installed and included in PATH.\n\n    You can download it from: http://www.adobe.com/products/flex/flexdownloads/.\n\n    Please extract it somewhere and add its bin/ directory to your PATH." && exit 1)
