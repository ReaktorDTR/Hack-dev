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
FOLDER_POSTBUILD=$(FOLDER_ROOT)postbuild_processing/
FOLDER_PREHINT=$(FOLDER_POSTBUILD)prehinted_builds/
FOLDER_POSTHINT=$(FOLDER_POSTBUILD)posthinted_builds/
FOLDER_TOOLS=$(FOLDER_ROOT)tools/

UFOS=Hack-Regular.ufo Hack-Italic.ufo Hack-Bold.ufo Hack-BoldItalic.ufo
OTFS=$(UFOS:.ufo=.otf)
TTFS=$(UFOS:.ufo=.ttf)

all: ufo2ttf

check_featurefiles:

check_makeotf:
	command -v makeotf >/dev/null 2>&1 || { echo "MakeOTF is required, but not installed.\nMakeOTF is part of the Adobe Font Development Kit for OpenType.\n" >&2; exit 1; }

hinting_otf:
	cd $(FOLDER_PREBUILD); \
	autohint Hack-Regular.otf; \
	autohint Hack-Italic.otf; \
	autohint Hack-Bold.otf; \
	autohint Hack-BoldItalic.otf

hinting_ttf:
	cd $(FOLDER_POSTBUILD)tt-hinting; \
	./autohint.sh; \
	./release.sh

move_built_otf:
	mv $(FOLDER_PREBUILD)/*.otf $(FOLDER_OTF)

move_built_ttf:
	mv $(FOLDER_PREBUILD)/*.ttf $(FOLDER_PREHINT)



ufo2otf: check_makeotf check_featurefiles ufo2otf_call_makeotf hinting_otf move_built_otf

ufo2otf_call_makeotf: ufo2otf_call_makeotf_regular ufo2otf_call_makeotf_italic ufo2otf_call_makeotf_bold ufo2otf_call_makeotf_bolditalic makeotf_cleanup

ufo2otf_call_makeotf_regular:
	cd $(FOLDER_PREBUILD)Hack-Regular; \
	makeotf -f $(FOLDER_SOURCE)Hack-Regular.ufo -o ../Hack-Regular.otf -mf FontMenuNameDB -ff features.fea -osbOn 6 -fs -ga -gf GlyphOrderAndAliasDB -r

ufo2otf_call_makeotf_italic:
	cd $(FOLDER_PREBUILD)Hack-Italic; \
	makeotf -f $(FOLDER_SOURCE)Hack-Italic.ufo -o ../Hack-Italic.otf -mf FontMenuNameDB -ff features.fea -i -fs -ga -gf GlyphOrderAndAliasDB -r

ufo2otf_call_makeotf_bold:
	cd $(FOLDER_PREBUILD)Hack-Bold; \
	makeotf -f $(FOLDER_SOURCE)Hack-Bold.ufo -o ../Hack-Bold.otf -mf FontMenuNameDB -ff features.fea -b -fs -ga -gf GlyphOrderAndAliasDB -r

ufo2otf_call_makeotf_bolditalic:
	cd $(FOLDER_PREBUILD)Hack-BoldItalic; \
	makeotf -f $(FOLDER_SOURCE)Hack-BoldItalic.ufo -o ../Hack-BoldItalic.otf -mf FontMenuNameDB -ff features.fea -b -i -fs -ga -gf GlyphOrderAndAliasDB -r



ufo2ttf: check_makeotf check_featurefiles ufo2ttf_call_makeotf move_built_ttf hinting_ttf

ufo2ttf_call_makeotf: ufo2ttf_call_makeotf_regular ufo2ttf_call_makeotf_italic ufo2ttf_call_makeotf_bold ufo2ttf_call_makeotf_bolditalic makeotf_cleanup

ufo2ttf_call_makeotf_regular:
	cd $(FOLDER_PREBUILD)Hack-Regular; \
	makeotf -f $(FOLDER_SOURCE)Hack-Regular.ufo -o ../Hack-Regular.ttf -mf FontMenuNameDB -ff features.fea -fs -ga -gf GlyphOrderAndAliasDB -r

ufo2ttf_call_makeotf_italic:
	cd $(FOLDER_PREBUILD)Hack-Italic; \
	makeotf -f $(FOLDER_SOURCE)Hack-Italic.ufo -o ../Hack-Italic.ttf -mf FontMenuNameDB -ff features.fea -i -fs -ga -gf GlyphOrderAndAliasDB -r

ufo2ttf_call_makeotf_bold:
	cd $(FOLDER_PREBUILD)Hack-Bold; \
	makeotf -f $(FOLDER_SOURCE)Hack-Bold.ufo -o ../Hack-Bold.ttf -mf FontMenuNameDB -ff features.fea -b -fs -ga -gf GlyphOrderAndAliasDB -r

ufo2ttf_call_makeotf_bolditalic:
	cd $(FOLDER_PREBUILD)Hack-BoldItalic; \
	makeotf -f $(FOLDER_SOURCE)Hack-BoldItalic.ufo -o ../Hack-BoldItalic.ttf -mf FontMenuNameDB -ff features.fea -b -i -fs -ga -gf GlyphOrderAndAliasDB -r

makeotf_cleanup:
	rm $(FOLDER_SOURCE)current.fpr
