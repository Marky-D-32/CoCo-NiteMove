SET XROARPATH=C:\apps\xroar-1.6.3-w64
SET ASMPATH=C:\apps\asm6809-2.12-w64

SET path=%XROARPATH%;%ASMPATH%

asm6809.exe --coco NiteMove.asm -o NiteMove.bin -l NiteMove.lst

xroar.exe -default-machine coco -rompath %XROARPATH% -run NiteMove.bin