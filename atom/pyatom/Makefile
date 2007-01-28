VERSION=`svn info | grep "^Revision:" | sed 's/Revision:\s*//'`

release: clean
	rm -f downloads/client_version_$(VERSION).tar.gz
	tar --create --file=downloads/client_version_$(VERSION).tar.gz --gzip --exclude=.svn --exclude=downloads --exclude=archives .
	

test_all:
	make -f test/Makefile

clean:
	rm --force *.pyc
	rm --force *.cgic

