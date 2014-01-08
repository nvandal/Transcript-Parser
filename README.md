#Usage
```
parse_gpa.pl

Perl script to parse raw transcript file and compute GPAs

Copyright: 2012 Nicholas Vandal
There is ABSOLUTELY NO WARRANTY; not even for MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.

usage: parse_gpa [arguments] file

Arguments:
   -W			Weigh courses by their credit hours instead of equally (disabled by default)
   -T=<intervals>	Specify intervals to compute GPA over (default: all courses, cumulative)
   -A=<file>		Specify file containing lists of courses to be used for the academic GPA
   -M=<minweight>	Speciy minimum course weight required for course to be included in the academic GPA (0.0 by default)
   -FR=[file]		Specify file containing courses which only replace the grades of those previously FAILED. If no file specified, ONLY failing grades (F) are replaced globally (disabled by default, C/D/F's are replaced globally)
   -NR=[file]		Specify file containing courses which NEVER replace the grades of those previously taken. If no file specified, no replacements are made (disabled by default)
   -NS			Do not include courses taken over the summer in the fall semester. No effect on replacement courses taken over the summer (disabled by default)
   -NG			Use student's nominal grade level (ie. they advance to the next grade level every year regardless of course failures)
   -BS			Keep best score (instead of most recent) when performing grade replacement (disabled by default)
   -KD			Keep duplicate courses within the same semester i.e., don't perform grade replacement (disabled by default)
   -PH			Print column headers in output (disabled by default)


Examples:
   ./parse_gpa.pl input/raw.txt
   ./parse_gpa.pl -A='input/selected.txt' -T='09/09A/F10/S10A/C0910/C080910A/C/CA' input/raw.txt
   ./parse_gpa.pl -A=input/selected.txt -NR=input/noreplace.txt -T='F07A/S07A/F07/S07/F08A/S08A/F08/S08/F09A/S09A/F09/S09/F10A/S10A/F10/S10/' -M=5.0 input/raw.txt > output/out.txt
   ./parse_gpa.pl -A=input/selected.txt -NR=input/noreplace.txt -FR=input/failonly.txt -T='F09/S09/F10/S10' -M=5.0 -NS -NG input/raw.txt > output/out.txt
```
