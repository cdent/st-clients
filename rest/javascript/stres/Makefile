all: jemplate-runtime.js jemplate-compiled.js

jemplate-runtime.js:
	jemplate --runtime > $@

jemplate-compiled.js: jemplate
	jemplate --compile $< > $@
