EMU=..\..\..\..\emulator\msvc\x64\Release\Hbc56Emu.exe
ACME=acme -I ..\..\lib


%.o: %.asm
	$(ACME) -o $@ -l $@.lmap $<

default: tms9918type

run %: %.o
	$(EMU) --rom $^

.PHONY: clean default

clean:
	rm -f *.o *.lmap
	
