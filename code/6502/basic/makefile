EMU=..\..\..\emulator\msvc\x64\Release\Hbc56Emu.exe
ACME=acme -I ..\lib -I ..\kernel


%.o: %.asm
	$(ACME) -o $@ -l $@.lmap $<
	
remake: default

default: basic_tms

.PHONY: clean default

clean:
	rm -f *.o *.lmap
	
basic_tms: basic_tms.o
	$(EMU) --keyboard --rom $^

basic_lcd: basic_lcd.o
	$(EMU) --lcd 2004 --keyboard --rom $^

basic_glcd: basic_glcd.o
	$(EMU) --lcd 12864 --keyboard --rom $^
