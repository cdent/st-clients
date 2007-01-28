PREFIX=st-soap-
ZIP=zip -r
TAR=tar -czvf
TMP_DIR=tmp.build
EXAMPLE_CLIENTS=cpp csharp java perl python rails ruby
CLEAN_FILES=*.zip *.tgz st-soap* tmp.*

# Common commands
CD=cd
RM=rm -f
CP=cp
MKDIR=mkdir
RM_DIR=$(RM) -R
CP_DIR=$(CP) -a

all: zip tarball

zip: zip_r rm_tmp_dir
zip_r: rm_tmp_dir mktmp
	for i in $(EXAMPLE_CLIENTS); do                                 \
	   ($(CD) $(TMP_DIR); $(ZIP) ../$(PREFIX)$$i.zip $(PREFIX)$$i); \
	done

tarball: tarball_r rm_tmp_dir
tarball_r: rm_tmp_dir mktmp
	for i in $(EXAMPLE_CLIENTS); do                                 \
	   ($(CD) $(TMP_DIR); $(TAR) ../$(PREFIX)$$i.tgz $(PREFIX)$$i); \
	done

mktmp:
	$(MKDIR) $(TMP_DIR)
	for i in $(EXAMPLE_CLIENTS); do            \
	   $(CP_DIR) $$i $(TMP_DIR)/$(PREFIX)$$i;  \
	done

rm_tmp_dir:
	$(RM_DIR) $(TMP_DIR)

clean: rm_tmp_dir
	$(RM_DIR) $(CLEAN_FILES)

.PHONY: all zip zip_r tarball tarball_r mktmp rm_tmp_dir clean
