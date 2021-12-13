EMU=..\..\..\..\emulator\bin\Hbc56Emu.exe
ACME=acme -I ..\..\lib -I ..\..\kernel

LCD_MODEL = 12864

lcd12864%.o: lcd12864%.asm
	$(ACME) -o $@ -l $@.lmap $<

%.o: %.asm
	$(ACME) -DLCD_MODEL=$(LCD_MODEL) -o $@ -l $@.lmap $<
	
remake: clean default

default: lcdtype

lcd12864%: lcd12864%.o
	$(EMU) --lcd 12864 --keyboard --rom $^

%: %.o
	$(EMU) --lcd $(LCD_MODEL) --keyboard --rom $^

.PHONY: clean

clean:
	rm -f *.o *.lmap
	
