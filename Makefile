# Compiles with https://www.brutaldeluxe.fr/products/crossdevtools/merlin/
#
ifeq ($(OS),Windows_NT)
    MERLIN_DIR=C:/opt/Merlin32_v1.0
    MERLIN_LIB=$(MERLIN_DIR)/Library
    MERLIN=$(MERLIN_DIR)/Windows/Merlin32
    RM=del /s
    COPY=copy
    APPLEWIN="c:\opt\AppleWin1.26.2.3\applewin.exe"
else
    MERLIN_DIR=$(HOME)/opt/Merlin32_v1.0
    MERLIN_LIB=$(MERLIN_DIR)/Library
    MERLIN=$(MERLIN_DIR)/Linux64/Merlin32
    RM=rm -f
    COPY=cp
    APPLEWIN=applewin
endif

AC=java -jar AppleCommander-ac-1.4.0.jar
SRC=online.s
PGM=online
BASE_DSK=prodos-2.0.3-boot.dsk
VOL=$(PGM)
DSK=$(PGM).dsk

# There is some kind of problem with turning this into a boot disk
# after it is created by AppleCommander. So, copy an existing boot
# disk instead.
#$(AC) -pro140 $(DSK) $(VOL)

$(DSK): $(PGM)
	$(COPY) $(BASE_DSK) $(DSK)
	$(AC) -n $(DSK) $(VOL)
	$(AC) -p $(DSK) $(PGM) SYS < $(PGM)
	#cat $(PGM).VER.bas | tr '\n' '\r' | $(AC) -p $(DSK) $(PGM).VER TXT
	$(AC) -p $(DSK) $(PGM).VER TXT

$(PGM): $(SRC)
	$(MERLIN) $(MERLIN_LIB) $(SRC)

clean:
	$(RM) $(DSK) $(PGM)

test: $(DSK)
	$(APPLEWIN) -d1 $(DSK)

