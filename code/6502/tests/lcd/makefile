EMU=..\..\..\..\emulator\msvc\x64\Release\Hbc56Emu.exe
ACME=acme -I ..\..\lib -I ..\..\kernel


%.o: %.asm
	$(ACME) -o $@ -l $@.lmap $<
	
remake: clean default

default: lcdtype

lcd12864%: lcd12864%.o
	$(EMU) --lcd 12864 --keyboard --rom $^

%: %.o
	$(EMU) --lcd 2004 --keyboard --rom $^

tms9918nes: tms9918nes.o
	$(EMU) --rom $^

.PHONY: clean

clean:
	rm -f *.o *.lmap
	
