## Locations - must be absolute

SRCDIR = src
DESTDIR = build
OUTDIR = out

UPDATEDIR = $(DESTDIR)/META-INF/com/google/android
XBINDIR = $(DESTDIR)/system/xbin

## Source and destination files

UPDATE_BINARY_SRC = $(SRCDIR)/updater
UPDATE_BINARY_DST = $(UPDATEDIR)/update-binary

UPDATE_SCRIPT_SRC = $(SRCDIR)/updater-script
UPDATE_SCRIPT_DST = $(UPDATEDIR)/updater-script

SU_BINARY_SRC = $(SRCDIR)/su
SU_BINARY_DST = $(XBINDIR)/su

DST_FILES = $(UPDATE_BINARY_DST) $(UPDATE_SCRIPT_DST) $(SU_BINARY_DST)

## Output files

OUT_ZIPPED = $(OUTDIR)/update-zipped.zip
OUT_SIGNED = $(OUTDIR)/update-signed.zip
OUT_ALIGNED = $(OUTDIR)/update-final.zip

## Signing data

KEYTOOL = keytool
# dir must exist if not stored in OUTDIR
KEYSTORE = $(OUTDIR)/nandroot.keystore
KEYSTOREPASS = nandroot
KEYALIAS = nandroot
KEYPASS = nandroot
JARSIGNER = jarsigner

## SDK tools

ZIPALIGN_DIR = $(SDKDIR)/tools
ZIPALIGN = $(ZIPALIGN_DIR)/zipalign

## Targets

all: $(OUT_ALIGNED)

$(ZIPALIGN):
	@echo "ERROR: zipalign not found ZIPALIGN_DIR"
	@echo "  maybe you forgot to specify the SDKDIR?"
	@echo "  use make flag SDKDIR=<path-to-sdk> to fix"
	@false

$(UPDATE_BINARY_DST): $(UPDATE_BINARY_SRC)
	mkdir -p $(UPDATEDIR)
	cp $(UPDATE_BINARY_SRC) $(UPDATE_BINARY_DST)
	chmod 755 $(UPDATE_BINARY_DST)

$(UPDATE_SCRIPT_DST): $(UPDATE_SCRIPT_SRC)
	mkdir -p $(UPDATEDIR)
	cp $(UPDATE_SCRIPT_SRC) $(UPDATE_SCRIPT_DST)
	chmod 644 $(UPDATE_SCRIPT_DST)

$(SU_BINARY_DST): $(SU_BINARY_SRC)
	mkdir -p $(XBINDIR)
	cp $(SU_BINARY_SRC) $(SU_BINARY_DST)
	chmod 755 $(SU_BINARY_DST)

$(KEYSTORE):
	mkdir -p $(OUTDIR)
	$(KEYTOOL) -genkey -v -keystore $(KEYSTORE) -alias $(KEYALIAS) \
		-storepass $(KEYSTOREPASS) -keypass $(KEYPASS) \
		-keyalg RSA -keysize 2048 -validity 10000

$(OUT_ZIPPED): $(DST_FILES)
	mkdir -p $(OUTDIR)
	(cd $(DESTDIR) && zip -r ../$(OUT_ZIPPED) *)

$(OUT_SIGNED): $(OUT_ZIPPED) $(KEYSTORE)
	$(JARSIGNER) -keystore $(KEYSTORE) \
		-storepass $(KEYSTOREPASS) -keypass $(KEYPASS) \
		-digestalg SHA1 -sigalg MD5withRSA \
		-signedjar $(OUT_SIGNED) $(OUT_ZIPPED) $(KEYALIAS)

$(OUT_ALIGNED): $(ZIPALIGN) $(OUT_SIGNED)
	$(ZIPALIGN) -v 4 $(OUT_SIGNED) $(OUT_ALIGNED)

.PHONY: clean
clean:
	rm -rf $(OUTDIR) $(DSTDIR)

