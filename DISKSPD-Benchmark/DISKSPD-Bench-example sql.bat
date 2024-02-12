DiskSpd.exe -c10G -d30 -r -w0 -t10 -o1 -b8K -h -L E:\testfile.dat > result-sqlbench01.txt

DiskSpd.exe -c10G -d30 -r -w100 -t10 -1 -b8K -h -L E:\testfile.dat > result-sqlbench02.txt

DiskSpd.exe -c10G -d30 -r -w40 -t10 -o1 -b8K -h -L E:\testfile.dat > result-sqlbench03.txt

DiskSpd.exe -c10G -d30 -r -w0 -t10 -o1 -b64K -h -L E:\testfile.dat > result-sqlbench04.txt

DiskSpd.exe -c10G -d30 -r -w100 -t10 -o1 -b64K -h -L E:\testfile.dat > result-sqlbench05.txt

DiskSpd.exe -c10G -d30 -r -w40 -t10 -o1 -b64K -h -L E:\testfile.dat > result-sqlbench06.txt

DiskSpd.exe -c10G -d30 -r -w100 -t10 -o1 -b128K -h -L E:\testfile.dat > result-sqlbench07.txt

DiskSpd.exe -c10G -d30 -r -w0 -t10 -o1 -b512K -h -L E:\testfile.dat > result-sqlbench08.txt

DiskSpd.exe -c10G -d30 -r -w0 -t10 -o1 -b512K -h -L E:\testfile.dat > result-sqlbench09.txt





REM DiskSpd.exe -c10G -w0 -b64K -F4 -T1b -s8b -o8 -d300 -h G:\testfile-LOGSQL.dat

REM DiskSpd.exe -c10G -w100 -b64K -F4 -T1b -s8b -o116 -d300 -h G:\testfile-LOGSQL.dat

REM DiskSpd.exe -c10G -w60 -b64K -F4 -T1b -s8b -o8 -d300 -h G:\testfile-LOGSQL.dat

