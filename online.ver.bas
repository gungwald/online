10  REM PRINT ONLINE VERSION
20  REM
23  REM SAVE LOCATION 6
25  LET M6=PEEK(6)
27  REM
30  REM PUT "V" FLAG FOR "VERSION"
40  REM INTO MEMORY LOCATION 6
50  REM WHERE THE ONLINE PROGRAM
60  REM WILL LOOK FOR IT.
70  POKE 6, ASC("V")
80  REM
90  REM RUN THE PROGRAM
100 PRINT CHR$(4);"-ONLINE"
110 REM
120 REM RESTORE THE MEMORY LOCATION
130 POKE 6,M6
140 END 
