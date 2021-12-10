EMU=..\..\..\emulator\msvc\x64\Release\Hbc56Emu.exe
ACME=acme -I ..\lib -I ..\kernel


%.o: %.asm
	$(ACME) -o $@ -l $@.lmap $<
	
remake: default

default: hbc56_mon

%: %.o
	$(EMU) --keyboard --rom $^

.PHONY: clean

clean:
	rm -f *.o *.lmap
	
