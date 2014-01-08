
#Install
#Usage
##parse_gpa.pl
Perl script to parse raw transcript file and compute GPAs
```
usage: parse_gpa [arguments] file

Arguments:
   -W			Weigh courses by their credit hours instead of equally (disabled by default)
   -T=<intervals>	Specify intervals to compute GPA over (default: all courses, cumulative)
   -A=<file>		Specify file containing lists of courses to be used for the academic GPA
   -M=<minweight>	Speciy minimum course weight required for course to be included in the academic GPA (0.0 by default)
   -FR=[file]		Specify file containing courses which only replace the grades of those previously FAILED. If no file specified, ONLY failing grades (F) are replaced globally (disabled by default, C/D/F's are replaced globally)
   -NR=[file]		Specify file containing courses which NEVER replace the grades of those previously taken. If no file specified, no replacements are made i.e, course retakes count as a new course (disabled by default)
   -NS			Do not include courses taken over the summer in the fall semester. No effect on replacement courses taken over the summer (disabled by default)
   -NG			Use student's nominal grade level (ie. they advance to the next grade level every year regardless of course failures)
   -BS			Keep best score (instead of most recent) when performing grade replacement instead of latest i.e., exlude the retake of a course resulted in a lower score than previous attempt. (disabled by default)
   -KD			Keep duplicate courses within the same semester i.e., retakes must occur in a later semester to be considered retakes (disabled by default)
   -PH			Print column headers in output (disabled by default)
```
###Examples:

Calculate the cumulative overall GPAs for all students for their entire academic history in raw.txt and output the result to the screen.
```
./parse_gpa.pl raw.txt
```
Calculate the cumulative overall GPAs for all students for their entire academic history in raw.txt, weigh each class by its number of credit hours (3rd column of raw.txt) and output the result to the file out.txt.
```
./scripts/parse_gpa.pl input/raw.txt -W > output/out.txt
```
Calculate the overall GPAs and academic GPAs (determined using the courses in academic courses in selected.txt), in 9th grade and output the result to out.txt.
```
 ./scripts/parse_gpa.pl -A='selected.txt' -T='09/09A' input/raw.txt > output/out.txt
```
Calculate the overall and academic GPAs for 9th grade, the 10th grade fall semester overall GPAs, the 10th grade spring academic GPAs, the cumulative 9th-10th grade GPAs, the cumulative 8-10th grade academic GPAs, the overall and academic cumulative GPAs for the entire entire history of raw.txt. Output the result to out.txt.
```
./scripts/parse_gpa.pl -A='input/selected.txt' -T='09/09A/F10/S10A/C0910/C080910A/C/CA' input/raw.txt > output/out.txt
```
Calculate overall GPAs for fall and spring of 7th through 10th grades, excluding summers, without any grade replacement, a min course weight of 5.0, nominal grade advancement (student never held back), keeping the best scores on retakes, and enforcing policy that retakes must occur in a later semester. Output result to out.txt.
```
./scripts/parse_gpa.pl -T='F07/S07/F08/S08/F09/S09/F10/S10' -NS -NR -M=5.0 -NG -BS -KD input/raw.txt > output/out.txt 
```
Additional examples
```
./scripts/parse_gpa.pl -T='F07/S07/F08/S08/F09/S09/F10/S10' -NR=input/noreplace.txt -FR=input/failonly.txt -M=5.0 -NG -BS -KD input/raw.txt > output/out.txt
./scripts/parse_gpa.pl -A=input/selected.txt -NR=input/noreplace.txt -T='F07A/S07A/F07/S07/F08A/S08A/F08/S08/F09A/S09A/F09/S09/F10A/S10A/F10/S10/' -M=5.0 input/raw.txt > output/out.txt
./scripts/parse_gpa.pl -A=input/selected.txt -NR=input/noreplace.txt -FR=input/failonly.txt -T='F09/S09/F10/S10' -M=5.0 -NS -NG input/raw.txt > output/out.txt
```
###extract_class_list.pl
Perl script to parse raw transcript file and compute generate list of unique
course numbers and their associated course names

```
usage: extract_class_list file

Examples:
   ./extract_class_list.pl input/raw.txt > input/classes_all_aliases.txt
```

