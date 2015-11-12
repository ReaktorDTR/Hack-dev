ifndef VERBOSE
.SILENT:
endif

FOLDER_ROOT=$(shell pwd)/
FOLDER_SOURCE=$(FOLDER_ROOT)source/ufo/Hack/
FOLDER_BUILD=$(FOLDER_ROOT)build/
FOLDER_OTF=$(FOLDER_BUILD)otf/
FOLDER_TTF=$(FOLDER_BUILD)ttf/
FOLDER_WEBFONTS=$(FOLDER_BUILD)webfonts/
FOLDER_PREBUILD=$(FOLDER_ROOT)prebuild/
FOLDER_TOOLS=$(FOLDER_ROOT)tools/
FOLDER_TEMP=$(FOLDER_BUILD)temp/
FILE_VERSION=$(FOLDER_PREBUILD)version.txt

# If the first argument is "version"...
ifeq (version,$(firstword $(MAKECMDGOALS)))
  # use the second argument as version
  SET_VERSION := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn it into do-nothing target
  $(eval $(SET_VERSION):;@:)
endif

# external commands
all: check make_temp build_otf build_ttf copy_otf copy_ttf webfonts cleanup
desktop: check_desktop make_temp build_otf build_ttf copy_otf copy_ttf cleanup
check: check_tools_otf check_tools_ttf check_tools_svg check_tools_eot check_tools_woff check_tools_woff2
check_desktop: check_tools_otf check_tools_ttf
otf: make_temp build_otf copy_otf cleanup
ttf: make_temp build_otf build_ttf copy_ttf cleanup
version: version_set
webfonts: make_temp build_otf build_ttf build_svg build_eot build_woff build_woff2 copy_webfonts update_css cleanup

# build chains
build_otf: check_tools_otf build_otf_setversion build_otf_run hinting_otf
build_ttf: check_tools_ttf build_ttf_run hinting_ttf
build_svg: check_tools_svg build_svg_run
build_eot: check_tools_eot build_eot_run
build_woff: check_tools_woff build_woff_run
build_woff2: check_tools_woff2 build_woff2_run

# set version from $(SET_VERSION) in build file
version_set:
	if [ x$(SET_VERSION)y == xy ]; then \
	echo "Usage: make version 1.234\n"; \
	exit 2; \
	fi
	printf "$(SET_VERSION)" > $(FILE_VERSION)
	echo "Version set to $(SET_VERSION).\n"

# create temporary build folder
make_temp:
	printf "Creating temporary folder... "
	mkdir -p $(FOLDER_TEMP)
	echo "done"

# clean up temporary build files
cleanup:
	printf "Cleaning up... "
	rm -f $(FOLDER_SOURCE)current.fpr
	rm -rf $(FOLDER_TEMP)
	rm -f $(FOLDER_PREBUILD)/*/*_versioned.fea
	echo "done"

# check if all tools required for OTF build are available
check_tools_otf:
	printf "Checking if MakeOTF is available... "
	command -v makeotf >/dev/null 2>&1 || { echo "no\n\nPlease install MakeOTF, which is part of the Adobe Font Development Kit for OpenType.\n" >&2; exit 1; }
	echo "yes"

# check if all tools required for TTF build are available
check_tools_ttf:
	printf "Checking if FontForge is available... "
	command -v fontforge >/dev/null 2>&1 || { echo "no\n\nPlease install FontForge.\n" >&2; exit 1; }
	echo "yes"

# check if all tools required for SVG build are available
check_tools_svg:
	# TODO

# check if all tools required for EOT build are available
check_tools_eot:
	printf "Checking if ttf2eot is available... "
	command -v ttf2eot >/dev/null 2>&1 || { echo "no\n\nPlease install ttf2eot.\n" >&2; exit 1; }
	echo "yes"

# check if all tools required for WOFF build are available
check_tools_woff:
	# TODO

# check if all tools required for WOFF2 build are available
check_tools_woff2:
	# TODO

# add version info to OTF feature files
build_otf_setversion:
	[ -r $(FILE_VERSION) ] || { echo "Version is undefined. Call make version 1.234 first.\n"; exit 2; }
	printf "Preparing versioned OTF feature files... "
	VERSION_CURRENT=`cat $(FILE_VERSION)`; \
	cd $(FOLDER_PREBUILD); \
	cp Hack-Regular/features.fea    Hack-Regular/features_versioned.fea; \
	cp Hack-Italic/features.fea     Hack-Italic/features_versioned.fea; \
	cp Hack-Bold/features.fea       Hack-Bold/features_versioned.fea; \
	cp Hack-BoldItalic/features.fea Hack-BoldItalic/features_versioned.fea; \
	find . -type f -name "features_versioned.fea" -exec sed -i.bak s/xVERSIONx/$$VERSION_CURRENT/g {} +; \
	rm -f */features_versioned.fea.bak
	echo "done"

# build OTF from UFO using MakeOTF and the tables
build_otf_run:
	printf "Building OTF font Regular... "
	cd $(FOLDER_PREBUILD)Hack-Regular; \
	makeotf -f $(FOLDER_SOURCE)Hack-Regular.ufo -o $(FOLDER_TEMP)Hack-Regular.otf -mf FontMenuNameDB -ff features_versioned.fea -osbOn 6 -fs -ga -gf GlyphOrderAndAliasDB -r
	echo "done"

	printf "Building OTF font Italic... "
	cd $(FOLDER_PREBUILD)Hack-Italic; \
	makeotf -f $(FOLDER_SOURCE)Hack-Italic.ufo -o $(FOLDER_TEMP)Hack-Italic.otf -mf FontMenuNameDB -ff features_versioned.fea -i -osbOn 6 -fs -ga -gf GlyphOrderAndAliasDB -r
	echo "done"

	printf "Building OTF font Bold... "
	cd $(FOLDER_PREBUILD)Hack-Bold; \
	makeotf -f $(FOLDER_SOURCE)Hack-Bold.ufo -o $(FOLDER_TEMP)Hack-Bold.otf -mf FontMenuNameDB -ff features_versioned.fea -b -osbOn 6 -fs -ga -gf GlyphOrderAndAliasDB -r
	echo "done"

	printf "Building OTF font BoldItalic... "
	cd $(FOLDER_PREBUILD)Hack-BoldItalic; \
	makeotf -f $(FOLDER_SOURCE)Hack-BoldItalic.ufo -o $(FOLDER_TEMP)Hack-BoldItalic.otf -mf FontMenuNameDB -ff features_versioned.fea -b -i -osbOn 6 -fs -ga -gf GlyphOrderAndAliasDB -r
	echo "done"

# build TTF from OTF using FontForge Python scripting
build_ttf_run:
	cd $(FOLDER_TEMP); \
	printf "Building TTF font Regular... "; \
	fontforge -c "f = open('Hack-Regular.otf'); f.generate('Hack-Regular.ttf'); quit();" \
	echo "done"; \
	printf "Building TTF font Italic... "; \
	fontforge -c "f = open('Hack-Italic.otf'); f.generate('Hack-Italic.ttf'); quit();" \
	echo "done"; \
	printf "Building TTF font Bold... "; \
	fontforge -c "f = open('Hack-Bold.otf'); f.generate('Hack-Bold.ttf'); quit();" \
	echo "done"; \
	printf "Building TTF font BoldItalic... "; \
	fontforge -c "f = open('Hack-BoldItalic.otf'); f.generate('Hack-BoldItalic.ttf'); quit();"; \
	echo "done"

# build SVG
build_svg_run:
	# TODO

# build EOT
build_eot_run:
	printf "Building Latin subset EOT fonts... "
	cd $(FOLDER_TEMP); \
	ttf2eot hack-regular-latin-webfont.ttf    hack-regular-latin-webfont.eot; \
	ttf2eot hack-italic-latin-webfont.ttf     hack-italic-latin-webfont.eot; \
	ttf2eot hack-bold-latin-webfont.ttf       hack-bold-latin-webfont.eot; \
	ttf2eot hack-bolditalic-latin-webfont.ttf hack-bolditalic-latin-webfont.eot
	echo "done"

	printf "Building complete EOT fonts... "
	cd $(FOLDER_TEMP); \
	ttf2eot hack-regular-webfont.ttf    hack-regular-webfont.eot; \
	ttf2eot hack-italic-webfont.ttf     hack-italic-webfont.eot; \
	ttf2eot hack-bold-webfont.ttf       hack-bold-webfont.eot; \
	ttf2eot hack-bolditalic-webfont.ttf hack-bolditalic-webfont.eot
	echo "done"

# build WOFF
build_woff_run:
	# TODO

# build WOFF2
build_woff2_run:
	# TODO

# hint OTF using AFDKO Adobe autohinter
hinting_otf:
	cd $(FOLDER_TEMP); \
	printf "Hinting OTF font Regular... "; \
	autohint Hack-Regular.otf; \
	echo "done"; \
	printf "Hinting OTF font Italic... "; \
	autohint Hack-Italic.otf; \
	echo "done"; \
	printf "Hinting OTF font Bold... "; \
	autohint Hack-Bold.otf; \
	echo "done"; \
	printf "Hinting OTF font BoldItalic... "; \
	autohint Hack-BoldItalic.otf; \
	echo "done"

# hint TTF using ttfautohint and our hint files
hinting_ttf:
	cd $(FOLDER_TEMP); \
	mkdir hinted; \
	printf "Hinting TTF font Regular... "; \
	ttfautohint -l 4 -r 80 -G 350 -x 0 -H 181 -D latn -f latn -w G -W -t -X "" -I -m $(FOLDER_PREBUILD)Hack-Regular/ttfautohint.txt Hack-Regular.ttf hinted/Hack-Regular.ttf; \
	echo "done"; \
	printf "Hinting OTF font Italic... "; \
	ttfautohint -l 4 -r 80 -G 350 -x 0 -H 145 -D latn -f latn -w G -W -t -X "" -I -m $(FOLDER_PREBUILD)Hack-Italic/ttfautohint.txt Hack-Italic.ttf hinted/Hack-Italic.ttf; \
	echo "done"; \
	printf "Hinting OTF font Bold... "; \
	ttfautohint -l 4 -r 80 -G 350 -x 0 -H 260 -D latn -f latn -w G -W -t -X "" -I -m $(FOLDER_PREBUILD)Hack-Bold/ttfautohint.txt Hack-Bold.ttf hinted/Hack-Bold.ttf; \
	echo "done"; \
	printf "Hinting OTF font BoldItalic... "; \
	ttfautohint -l 4 -r 80 -G 350 -x 0 -H 265 -D latn -f latn -w G -W -t -X "" -I -m $(FOLDER_PREBUILD)Hack-BoldItalic/ttfautohint.txt Hack-BoldItalic.ttf hinted/Hack-BoldItalic.ttf; \
	echo "done"; \
	printf "Overwriting unhinted fonts with hinted ones... "; \
	mv hinted/*.ttf .; \
	rmdir hinted; \
	echo "done"

# copy OTF to build folder
copy_otf:
	printf "Copying OTF fonts to build/otf... "
	cp $(FOLDER_TEMP)*.otf $(FOLDER_OTF)
	echo "done"

# copy TTF to release folder
copy_ttf:
	printf "Copying TTF fonts to build/ttf... "
	cp $(FOLDER_TEMP)*.ttf $(FOLDER_TTF)
	echo "done"

# copy web fonts to build folder
copy_webfonts:
	printf "Copying Latin subset EOT fonts... "
	cd $(FOLDER_TEMP); \
	cp hack-regular-latin-webfont.eot    $(FOLDER_WEBFONTS)fonts/eot/latin/hack-regular-latin-webfont.eot; \
	cp hack-italic-latin-webfont.eot     $(FOLDER_WEBFONTS)fonts/eot/latin/hack-italic-latin-webfont.eot; \
	cp hack-bold-latin-webfont.eot       $(FOLDER_WEBFONTS)fonts/eot/latin/hack-bold-latin-webfont.eot; \
	cp hack-bolditalic-latin-webfont.eot $(FOLDER_WEBFONTS)fonts/eot/latin/hack-bolditalic-latin-webfont.eot; \
	echo "done"

	printf "Copying complete EOT fonts... "
	cd $(FOLDER_TEMP); \
	cp hack-regular-webfont.eot    $(FOLDER_WEBFONTS)fonts/eot/hack-regular-webfont.eot; \
	cp hack-italic-webfont.eot     $(FOLDER_WEBFONTS)fonts/eot/hack-italic-webfont.eot; \
	cp hack-bold-webfont.eot       $(FOLDER_WEBFONTS)fonts/eot/hack-bold-webfont.eot; \
	cp hack-bolditalic-webfont.eot $(FOLDER_WEBFONTS)fonts/eot/hack-bolditalic-webfont.eot; \
	echo "done"

	printf "Copying Latin subset SVG fonts... "
	cd $(FOLDER_TEMP); \
	cp hack-regular-latin-webfont.svg    $(FOLDER_WEBFONTS)fonts/svg/latin/hack-regular-latin-webfont.svg; \
	cp hack-italic-latin-webfont.svg     $(FOLDER_WEBFONTS)fonts/svg/latin/hack-italic-latin-webfont.svg; \
	cp hack-bold-latin-webfont.svg       $(FOLDER_WEBFONTS)fonts/svg/latin/hack-bold-latin-webfont.svg; \
	cp hack-bolditalic-latin-webfont.svg $(FOLDER_WEBFONTS)fonts/svg/latin/hack-bolditalic-latin-webfont.svg; \
	echo "done"

	printf "Copying complete SVG fonts... "
	cd $(FOLDER_TEMP); \
	cp hack-regular-webfont.svg    $(FOLDER_WEBFONTS)fonts/svg/hack-regular-webfont.svg; \
	cp hack-italic-webfont.svg     $(FOLDER_WEBFONTS)fonts/svg/hack-italic-webfont.svg; \
	cp hack-bold-webfont.svg       $(FOLDER_WEBFONTS)fonts/svg/hack-bold-webfont.svg; \
	cp hack-bolditalic-webfont.svg $(FOLDER_WEBFONTS)fonts/svg/hack-bolditalic-webfont.svg; \
	echo "done"

	printf "Copying Latin subset web TTF fonts... "
	cd $(FOLDER_TEMP); \
	cp hack-regular-latin-webfont.ttf    $(FOLDER_WEBFONTS)fonts/web-ttf/latin/hack-regular-latin-webfont.ttf; \
	cp hack-italic-latin-webfont.ttf     $(FOLDER_WEBFONTS)fonts/web-ttf/latin/hack-italic-latin-webfont.ttf; \
	cp hack-bold-latin-webfont.ttf       $(FOLDER_WEBFONTS)fonts/web-ttf/latin/hack-bold-latin-webfont.ttf; \
	cp hack-bolditalic-latin-webfont.ttf $(FOLDER_WEBFONTS)fonts/web-ttf/latin/hack-bolditalic-latin-webfont.ttf; \
	echo "done"

	printf "Copying complete web TTF fonts... "
	cp hack-regular-webfont.ttf    $(FOLDER_WEBFONTS)fonts/web-ttf/hack-regular-webfont.ttf; \
	cp hack-italic-webfont.ttf     $(FOLDER_WEBFONTS)fonts/web-ttf/hack-italic-webfont.ttf; \
	cp hack-bold-webfont.ttf       $(FOLDER_WEBFONTS)fonts/web-ttf/hack-bold-webfont.ttf; \
	cp hack-bolditalic-webfont.ttf $(FOLDER_WEBFONTS)fonts/web-ttf/hack-bolditalic-webfont.ttf; \
	echo "done"

	printf "Copying Latin subset WOFF fonts... "
	cd $(FOLDER_TEMP); \
	cp hack-regular-latin-webfont.woff    $(FOLDER_WEBFONTS)fonts/woff/latin/hack-regular-latin-webfont.woff; \
	cp hack-italic-latin-webfont.woff     $(FOLDER_WEBFONTS)fonts/woff/latin/hack-italic-latin-webfont.woff; \
	cp hack-bold-latin-webfont.woff       $(FOLDER_WEBFONTS)fonts/woff/latin/hack-bold-latin-webfont.woff; \
	cp hack-bolditalic-latin-webfont.woff $(FOLDER_WEBFONTS)fonts/woff/latin/hack-bolditalic-latin-webfont.woff; \
	echo "done"

	printf "Copying complete WOFF fonts... "
	cd $(FOLDER_TEMP); \
	cp hack-regular-webfont.woff    $(FOLDER_WEBFONTS)fonts/woff/hack-regular-webfont.woff; \
	cp hack-italic-webfont.woff     $(FOLDER_WEBFONTS)fonts/woff/hack-italic-webfont.woff; \
	cp hack-bold-webfont.woff       $(FOLDER_WEBFONTS)fonts/woff/hack-bold-webfont.woff; \
	cp hack-bolditalic-webfont.woff $(FOLDER_WEBFONTS)fonts/woff/hack-bolditalic-webfont.woff; \
	echo "done"

	printf "Copying Latin subset WOFF2 fonts... "
	cd $(FOLDER_TEMP); \
	cp hack-regular-latin-webfont.woff2    $(FOLDER_WEBFONTS)fonts/woff2/latin/hack-regular-latin-webfont.woff2; \
	cp hack-italic-latin-webfont.woff2     $(FOLDER_WEBFONTS)fonts/woff2/latin/hack-italic-latin-webfont.woff2; \
	cp hack-bold-latin-webfont.woff2       $(FOLDER_WEBFONTS)fonts/woff2/latin/hack-bold-latin-webfont.woff2; \
	cp hack-bolditalic-latin-webfont.woff2 $(FOLDER_WEBFONTS)fonts/woff2/latin/hack-bolditalic-latin-webfont.woff2; \
	echo "done"

	printf "Copying complete WOFF2 fonts... "
	cd $(FOLDER_TEMP); \
	cp hack-regular-webfont.woff2    $(FOLDER_WEBFONTS)fonts/woff2/hack-regular-webfont.woff2; \
	cp hack-italic-webfont.woff2     $(FOLDER_WEBFONTS)fonts/woff2/hack-italic-webfont.woff2; \
	cp hack-bold-webfont.woff2       $(FOLDER_WEBFONTS)fonts/woff2/hack-bold-webfont.woff2; \
	cp hack-bolditalic-webfont.woff2 $(FOLDER_WEBFONTS)fonts/woff2/hack-bolditalic-webfont.woff2; \
	echo "done"

# update CSS files with current version
update_css:
	# TODO
