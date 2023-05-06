#!/bin/bash
# Compares our pipeline's writeback.out to the writeback.out
# generated by the project 3 pipeline
# Prints results to test_results.out
make nuke
ans="test_progs/correct_writeback"
failed="FALSE"
touch test_results.out
echo "		RUNNING TEST SUITE" > test_results.out
echo "" >> test_results.out
for file in test_progs/*.s; do
	file=$(echo $file | cut -d'.' -f1)
	echo "Assembling $file"
	make SOURCE="$file.s" assembly
	echo "Running $file"
	make pipeline
	echo "Comparing $file result to correct_writeback"
	file=$(echo $file | cut -d'/' -f2)

	diff $ans/$file.writeback.out writeback.out > $file.writeback.diff.out
	if [ -s $file.writeback.diff.out ]; then
		echo "FAILED $file.s" >> test_results.out
		failed="TRUE"
	else
		echo "PASSED $file.s" >> test_results.out
	fi
	rm $file.writeback.diff.out
done
for file in test_progs/*.c; do
	file=$(echo $file | cut -d'.' -f1)
	echo "Assembling $file"
	make SOURCE="$file.c" program
	echo "Running $file"
	make pipeline
	echo "Comparing $file result to correct_writeback"
	file=$(echo $file | cut -d'/' -f2)

	diff $ans/$file.writeback.out writeback.out > $file.writeback.diff.out
	if [ -s $file.writeback.diff.out ] then
		echo "FAILED $file.c" >> test_results.out
		failed="TRUE"
	else
		echo "PASSED $file.c" >> test_results.out
	fi
	rm $file.writeback.diff.out
done
echo ""
if [ "$failed" == "FALSE" ]; then
    echo "PASSED TEST SUITE"
    echo "		PASSED TEST SUITE" >> test_results.out
else
    echo "FAILED TEST SUITE"
    echo "		FAILED TEST SUITE" >> test_results.out
fi