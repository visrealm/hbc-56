EMU=..\..\..\emulator\msvc\x64\Release\Hbc56Emu.exe
ACME=acme -I ..\lib


%.o: %.asm
	$(ACME) -o $@ -l $@.lmap $<

default: kernel.o

remake: clean default

%: %.o
	$(EMU) --rom $^

.PHONY: clean default

clean:
	rm -f *.o *.lmap
	
