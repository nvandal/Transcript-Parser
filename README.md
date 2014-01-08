This is a set of scripts written for the bulk computation of GPAs from Los Angeles Unified School District transcripts. The scripts are completely specific to the transcript format, but are designed to be flexible with the exact methodology used to compute a student's GPA. This replaced an extremely manual process in a psychology research lab and was my first perl program of any length. I’m not actively developing this, just documenting, but others may find it useful. 

#Install

The following is written with non-technical users in mind.

#####Get perl
These scripts only require a perl interpreter to run. Windows users will have to install a perl distribution from http://www.perl.org/get.html. Mac OSX and Linux should have perl built in and don't require this step. The rest of the install directions assume Mac OSX.

#####Download and extract the zipfile.
Click the "Download ZIP" link on the right. Either leave the file "Transcript-Parser-master.zip" in your Downloads folder or move it to another folder. Unzip the .zip file by double clicking or opening it.

#####Open Terminal
Press and hold ⌘Command and Space to open up Spotlight. Type: "Terminal" and Enter to open up the Terminal command line. Or navigate to Applications->Other->Terminal.

#####Terminal basics
You should be presented with a terminal command prompt that looks like a dollar sign. 
```
$
```
This is where you enter text commands. In all examples below do not type the dollar sign in, it only indicate that the computer is ready to execute a new command. The text on lines following the dollar sign displays the computer's response to your command.  Be careful in the terminal, it is exteremly powerful, but not forgiving if you enter the wrong commands.

You can determine which directory you are currently in (aka a Folder) by typing `pwd` (for print working directory).  
```
$ pwd
/Users/nvandal
```
This indicates that I am in my home directory. To see which folders are in your current directory by type `ls` (for list the directory).
```
$ ls
Applications
Desktop
Documents
Downloads
Library
Movies
Music
Pictures
Public
```
Notice these directories correspond with all of my folders that are represented graphically in Finder. You can move to a different directory by typing `cd` (for change directory). 
```
$ cd Downloads
$ pwd
/Users/nvandal/Downloads
```
I've moved to my Downloads directory. I can move up one level in the folder hierachy by typing `cd ..`
```
$ cd ..
$ pwd
/Users/nvandal
```
I've moved back to my home directory. Your home directory can also be shortened as `~`. 
```
$ cd Downloads
$ pwd 
/Users/nvandal/Downloads
$ cd ~
$ pwd 
/Users/nvandal
```
Once again I'm back to my home directory. You can also move through multiple directories at once.
```
$ cd ~/Downloads/Transcript-Parser-master
$ pwd
/Users/nvandal/Downloads/Transcript-Parser-master
```
#####Navigate to the directory
Navigate to the Transcript-Parser-master folder in the terminal using the cd command. If you left the zip file in your Downloads folder when you extracted it, the following should work:
```
$ cd ~/Downloads/Transcript-Parser-master
```
All commands listed below are assumed to occur in the Transcript-Parser-master directory (aka the top level directory).
#####Run the commands
Running commands without any additional arguments displays built in help information
```
$ scripts/extract_class_list.pl
$ scripts/parse_gpa.pl
```
If you see verbose help messages then everything should be working correctly. Refer to the Usage section below.

#Usage
##extract_class_list.pl
Perl script to parse raw transcript file and compute generate list of unique
course numbers and their associated course names

```
usage: extract_class_list file
```
###Examples
Extract all unique class numbers and their aliases from sample_raw.txt and display the result to the command line
```
$ ./scripts/extract_class_list.pl input/sample_raw.txt 
180103|INTRO COMP
200101|GEN ART
200503|PHOTO 1A
200504|PHOTO 1B
230101|H ENG/READ 6A
230102|H ENG/READ 6B
230103|ENGLISH 7A
230104|H ENGLISH 7B|ENGLISH 7B
230105|H ENGLISH 8A|ENGLISH 8A
230106|H ENGLISH 8B|ENGLISH 8B
230107|ENGLISH 9A
230108|ENGLISH 9B
230109|H ENGLISH 10A|ENGLISH 10A
230110|H ENGLISH 10B|ENGLISH 10B
256011|SPANISH 1A
256012|SPANISH 1B
256013|SPANISH 2A
256014|SPANISH 2B
260101|HEALTH JH
260103|HEALTH SH
292501|EXPL ELECT
310101|H MATH 6A
310102|H MATH 6B
310103|MATH 7A
310104|H MATH 7B
310301|H ALGEBRA 1A|ALGEBRA 1A
310302|ALGEBRA 1B|H ALGEBRA 1B
310317|ALGEBRA READ A
310318|ALGEBRA READ B
310401|GEOMETRY A
310402|GEOMETRY B
330101|BEG PE A
330102|BEG PE B
330103|INT PE A
330104|INT PE B
330106|ADV PE 1B
330119|INTRO PE A
330120|INTRO PE B
330205|ADV COND
330629|TRACK FIELD
330705|BASKETBALL
360101|H SCI/HLTH 6A
360102|H SCI/HLTH 6B
360103|SCIENCE 7
360105|H SCIENCE 8A|SCIENCE 8A
360106|SCIENCE 8B|H SCIENCE 8B
360701|BIOLOGY A
360702|BIOLOGY B
361401|CHEMISTRY A
361402|CHEMISTRY B
370121|H WHG:AN CIV A
370122|H WHG:AN CIV B
370123|H WHG:MED/MD A
370124|WHG: MED/MOD B|H WHG:MED/MD B
370125|US HIST G&C A|H US HST G&C A
370126|US HIST G&C B|H US HST G&C B
370127|H WHG:MOD WL A|WHG: MOD WLD A
370128|H WHG:MOD WL B
420103|HOMEROOM|HOMEROOM 6TH|HOMEROOM 7M|HOMEROOM 8|HOMEROOM 7
420107|LIFE SKLS 21ST
460601|LEADER JH A
460602|LEADER JH B
494810|CAREER AWARE B
```
Extract all unique course numbers and their aliases from input/raw.txt and write result to input/classes_all_aliases.txt
```
./scripts/extract_class_list.pl input/raw.txt > input/classes_all_aliases.txt
```
The entries in this file can be moved to selected.txt, rejected.txt, etc. and passed via different arguments to parse_gpa.pl to have fine-grain control over how GPAs are calculated.

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

Calculate the cumulative overall GPAs for all students for their entire academic history in sample_raw.txt and output the result to the screen with column headers.
```
$ ./scripts/parse_gpa.pl input/sample_raw.txt -PH
IDNUM|NAME|DOB|C|
123454M612|WASHINGTON, GEORGE|04/30/98|1.86|
543221M062|ADAMS, JOHN QUINCY|03/04/24|3.11|
```
Calculate the cumulative overall GPAs for all students for their entire academic history in raw.txt, weigh each class by its number of credit hours (3rd column of raw.txt) and output the result to the file out.txt.
```
$ ./scripts/parse_gpa.pl input/raw.txt -W > output/out.txt
```
Calculate the overall GPAs and academic GPAs (determined using the courses in academic courses in selected.txt), in 9th grade and output the result to out.txt.
```
$  ./scripts/parse_gpa.pl -A='selected.txt' -T='09/09A' input/raw.txt > output/out.txt
```
Calculate the overall and academic GPAs for 9th grade, the 10th grade fall semester overall GPAs, the 10th grade spring academic GPAs, the cumulative 9th-10th grade GPAs, the cumulative 8-10th grade academic GPAs, the overall and academic cumulative GPAs for the entire entire history of raw.txt. Output the result to out.txt.
```
$ ./scripts/parse_gpa.pl -A='input/selected.txt' -T='09/09A/F10/S10A/C0910/C080910A/C/CA' input/raw.txt > output/out.txt
```
Calculate overall GPAs for fall and spring of 7th through 10th grades, excluding summers, without any grade replacement, a min course weight of 5.0, nominal grade advancement (student never held back), keeping the best scores on retakes, and enforcing policy that retakes must occur in a later semester. Output result to out.txt.
```
$ ./scripts/parse_gpa.pl -T='F07/S07/F08/S08/F09/S09/F10/S10' -NS -NR -M=5.0 -NG -BS -KD input/raw.txt > output/out.txt 
```
Additional examples
```
$ ./scripts/parse_gpa.pl -T='F07/S07/F08/S08/F09/S09/F10/S10' -NR=input/noreplace.txt -FR=input/failonly.txt -M=5.0 -NG -BS -KD input/raw.txt > output/out.txt
$ ./scripts/parse_gpa.pl -A=input/selected.txt -NR=input/noreplace.txt -T='F07A/S07A/F07/S07/F08A/S08A/F08/S08/F09A/S09A/F09/S09/F10A/S10A/F10/S10/' -M=5.0 input/raw.txt > output/out.txt
$ ./scripts/parse_gpa.pl -A=input/selected.txt -NR=input/noreplace.txt -FR=input/failonly.txt -T='F09/S09/F10/S10' -M=5.0 -NS -NG input/raw.txt > output/out.txt
```
