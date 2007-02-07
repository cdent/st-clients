RUN=runhaskell
SETUP=Setup.hs
AOUT=a.out

socialtext: configure build

configure build install:
	$(RUN) $(SETUP) $@

clean:
	rm -fR dist
	find . -type f -name '*.hi' | xargs -r rm -f
	find . -type f -name '*.o' | xargs -r rm -f
	rm -f $(AOUT)
