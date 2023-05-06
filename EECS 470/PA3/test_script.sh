#!/bin/bash
DIR=/home/seanfan/project3
FILES=/home/seanfan/project3/test_progs/*

rm -rf ${DIR}/test/*

for file in test_progs/*.s; do
file=$(echo $file | cut -d'.' -f1)
echo "Assembling $file"
# How do you assemble a testcase?
make assembly >/dev/null

echo "Running $file"
# How do you run a testcase?
make >/dev/null

echo "Saving $file output"
# How do you want to save the output?
# What files do you want to save?
cat program.out | grep "@@@" > test/$(basename $file)_program.out
cp writeback.out test/$(basename $file)_writeback.out

diff ${DIR}/test/$(basename $file)_writeback.out ${DIR}/test/$(basename $file)_writeback.out
DIFF1=$?
diff ${DIR}/test/$(basename $file)_program.out ${DIR}/test/$(basename $file)_program.out
DIFF2=$?

if [ $DIFF1 -eq 1 ]
then
    echo "$file $(tput setaf 1) failed $(tput setaf 7)"
elif [ $DIFF2 -eq 1 ]
then
    echo "$file failed"
else
    echo "$file $(tput setaf 2) passed $(tput setaf 7)"
fi


done
