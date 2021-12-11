EMU=..\..\..\emulator\msvc\x64\Release\Hbc56Emu.exe
ACME=acme -I ..\lib -I ..\kernel


%.o: %.asm
	$(ACME) -o $@ -l $@.lmap $<
	
remake: default

default: basic_tms

.PHONY: clean default

clean:
	rm -f *.o *.lmap
	
%: %.o
	$(EMU) --keyboard --rom $^

