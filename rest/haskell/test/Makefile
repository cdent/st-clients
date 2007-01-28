
# Chris has figured out how to pass around this info, so it is
# written into the source file.

USER=youruser
PASS=yourpass
TYPE=text/html

get: get.hs
	ghc --make -package HTTP $< -o $@
	ln -f -s $@ put
	ln -f -s $@ post

clean:
	rm -f get put post *.o *.hi a.out

test: get
	./get $(USER) $(PASS) $(TYPE) http://www.socialtext.net/data/workspaces/st-rest-docs/pages?order=newest\;count=2
