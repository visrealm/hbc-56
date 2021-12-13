EMU=..\..\..\..\emulator\bin\Hbc56Emu.exe
ACME=acme -I ..\..\lib -I ..\..\kernel


%.o: %.asm
	$(ACME) -o $@ -l $@.lmap $<
	
remake: clean default

default: mario

%: %.o
	$(EMU) --keyboard --rom $^

.PHONY: clean

clean:
	rm -f *.o *.lmap
	
