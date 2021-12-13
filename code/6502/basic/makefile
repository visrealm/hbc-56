EMU=..\..\..\emulator\bin\Hbc56Emu.exe
ACME=acme -I ..\lib -I ..\kernel

LCD_MODEL = 12864

%.o: %.asm
	$(ACME) -DLCD_MODEL=$(LCD_MODEL) -o $@ -l $@.lmap $<
	
remake: default

default: basic_tms

.PHONY: clean

clean:
	rm -f *.o *.lmap

basic_tms: basic_tms.o
	$(EMU) --keyboard --rom $^

basic_lcd: basic_lcd.o
	$(EMU) --lcd $(LCD_MODEL) --keyboard --rom $^

basic_glcd: basic_glcd.o
	$(EMU) --lcd 12864  --keyboard --rom $^
