EMU=..\..\..\..\emulator\msvc\x64\Release\Hbc56Emu.exe
ACME=acme -I ..\..\lib -I ..\..\kernel


%.o: %.asm
	$(ACME) -o $@ -l $@.lmap $<
	
remake: clean default

default: tms9918type

%: %.o
	$(EMU) --keyboard --rom $^

tms9918nes: tms9918nes.o
	$(EMU) --rom $^

.PHONY: clean

clean:
	rm -f *.o *.lmap
	
