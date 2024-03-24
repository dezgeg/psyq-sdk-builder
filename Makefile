.SUFFIXES:
.SECONDARY:
SHELL := /bin/bash -O nullglob

VERSIONS := 20 26 30 33 35 36 40 41 42 43 44 46 47
URL_20 := https://archive.org/download/ps1_sdks/Programmer%20Tool%20-%20Runtime%20Library%20Version%202.0%20%28Japan%29%20%28En%2CJa%29_DTL-S2160_redump.zip
URL_26 := https://archive.org/download/ps1_sdks/Programmer%20Tool%20-%20Runtime%20Library%20Version%202.6%20%28Japan%29%20%28En%2CJa%29_DTL-S2170_redump.zip
URL_30 := https://archive.org/download/ps1_sdks/Programmer%20Tool%20-%20Runtime%20Library%20Version%203.0%20%28Japan%29%20%28En%2CJa%29_DTL-S2180_redump.zip
URL_33 := https://archive.org/download/ps1_sdks/Programmer%20Tool%20-%20Runtime%20Library%20Version%203.3%20%28Japan%29_DTL-S2190_redump.zip
URL_35 := https://archive.org/download/ps1_sdks/Programmer%20Tool%20-%20Runtime%20Library%20Version%203.5%20%28Japan%29%20%28En%2CJa%29_DTL-S2300_redump.zip
URL_36 := https://archive.org/download/ps1_sdks/Programmer%20Tool%20-%20Runtime%20Library%20Version%203.6%20%28Japan%29_DTL-S2310_redump.zip
URL_40 := https://archive.org/download/ps1_sdks/Programmer%20Tools%20-%20Run-time%20Library%204.0%20%28USA%29%20%28Release%202.0%29_DTL-S2002_redump.zip
URL_41 := https://archive.org/download/ps1_sdks/Programmer%20Tool%20-%20Runtime%20Library%20Version%204.1%20%28Japan%29_DTL-S2330_redump.zip
URL_42 := https://archive.org/download/play-station-programmer-tool-runtime-library-version-4.2.7z/PlayStation_Programmer_Tool_-_Runtime_Library_Version_4.2.7z
URL_43 := https://archive.org/download/ps1_sdks/Programmer%20Tool%20-%20Runtime%20Library%20Version%204.3%20%28Japan%29_DTL-S2340_redump.zip
URL_44 := https://archive.org/download/ps1_sdks/Programmer%20Tool%20-%20Runtime%20Library%20Version%204.4%20%28Japan%29_DTL-S2350_redump.zip
URL_46 := https://archive.org/download/ps1_sdks/Programmer%20Tool%20-%20Runtime%20Library%20Version%204.6%20%28Japan%29_DTL-S2360_redump.zip
URL_47 := https://archive.org/download/ps1_sdks/Runtime%20Library%204.7.zip

.PHONY: all
all: $(addprefix output/,$(VERSIONS))

.PHONY: tarballs
tarballs: $(addsuffix .tar.gz,$(addprefix tarballs/psyq-,$(VERSIONS)))

dl/%:
	mkdir -p dl
	wget --progress=dot:mega $(URL_$*) -O $@

extracted/%: dl/%
	mkdir -p $@
	7z x -o$@ $<
	# If in bin/cue format, extract 1st track (but it might not have 'Track 1' in its name)
	-rm $@/*Track*[2-9]*.bin
	-iat $@/*.bin $@/fs.iso
	-7z x -o$@ $@/fs.iso
	# 2.0 only
	-lha xw=$@ $@/PSX.LZH
	rename -d y/a-z/A-Z/ $@/*
	rename -d y/a-z/A-Z/ $@/*/*
	rename -d y/a-z/A-Z/ $@/*/*/*

output/%: extracted/%
	mkdir -p $@/BIN
	# Copy the libs for 4.2 & 4.7
	-cp -r $</{LIB,INCLUDE} $@/
	# Copy the libs for everything else
	-cp -r $</PSX/{LIB,INCLUDE} $@/
	# Apply 4.2 specific patches to libs
	-unzip -d $@ -o $@/LIB/42PATCH/J421PD.ZIP
	-unzip -d $@ -o $@/LIB/42PATCH/J421DS.ZIP
	-unzip -d $@ -o $@/LIB/MC42PTCH/MCRD421.ZIP
	-mv $@/*.H $@/INCLUDE/
	-mv $@/*.LIB $@/LIB/
	# Clean up 4.2 patch leftovers
	-rm -rf $@/*.txt $@/LIB/42PATCH $@/LIB/MC42PTCH
	# Clean up other crud from libs
	-rm -rf $@/LIB/OLD_LIBS $@/LIB/*.TXT $@/LIB/*.PDF
	# Copy the toolchain
	-cp $</{COMPILER,GNU,PSSN,PSSN/BIN,PSX/BIN,PSYQ}/{ASPSX,ASMPSX,CC1PLPSX,CC1PSX,CCPSX,CPLUSPSX,CPPPSX,DMPSX,DUMPOBJ,PSYLINK,PSYLIB,PSYMAKE}.EXE $@/BIN
	-chmod a+rx $@/BIN/*
	# Don't have empty BIN/ for libs-only releases
	-rmdir $@/BIN
	# Install lowercase-named wibo wrapper for each .EXE
	-for exe in $@/BIN/*.EXE; do cp wibo/build/wibo $@/; cp wrapper.sh $@/`basename -s.EXE $$exe | tr A-Z a-z`; done

tarballs/psyq-%.tar.gz: output/%
	@mkdir -p tarballs/
	tar -C $< -cvzf $@ .

wibo/build/wibo:
	cmake wibo -B wibo/build -DCMAKE_BUILD_TYPE=Release -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" -DCMAKE_EXE_LINKER_FLAGS="-static"
	make -C wibo/build

.PHONY: clean
clean:
	rm -rf wibo/build
	rm -rf extracted
	rm -rf output
