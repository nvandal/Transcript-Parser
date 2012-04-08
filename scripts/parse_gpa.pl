#!/usr/bin/perl -ws

#parse_gpa.pl
#Copyright: Nick Vandal 2009
#Calculates GPAs from a transcripts

use strict;
use feature 'switch';
use POSIX;


#Command line switches
our($W, $T, $A, $M, $h); #Weighted, interval_string, academic_course_file, minWeight
if(not defined $W) {$W = 0;}
if(not defined $T) {$T = 'C';}
if(not defined $A) {$A = '';}
if(not defined $M) {$M = 0;}

if ( @ARGV <= 0 or $h)
{
	print "parse_gpa.pl\n";
	print "\n";
	print "Perl script to parse raw transcript file and compute GPAs\n";
	print "\n";
	print "Copyright: 2012 Nicholas Vandal\n";
	print "There is ABSOLUTELY NO WARRANTY; not even for MERCHANTABILITY or\n";
	print "FITNESS FOR A PARTICULAR PURPOSE.\n";
	print "\n";
	print "usage: parse_gpa [arguments] file\n";
	print "\n";
	print "Arguments:\n";
   	print "   -W\t\t\tWeigh courses by their credit hours instead of equally (disabled by default)\n";
	print "   -T=<intervals>\tSpecify intervals to compute GPA over (default: all courses, cumulative)\n";
	print "   -A=<file>\t\tSpecify file containing lists of courses to be used for the academic GPA\n";
	print "   -M=<minweight>\tSpeciy minimum course weight required for course to be included in the academic GPA\n";
	print "\n";
	print "\n";
	print "Examples:\n";
	print "   ./parse_gpa.pl input/raw.txt\n";
	print "   ./parse_gpa.pl -A='input/selected.txt' -T='09/09A/F10/S10A/C0910/C080910A/C/CA' input/raw.txt\n";
	print "   ./parse_gpa.pl -A=input/selected.txt -T='F07A/S07A/F07/S07/F08A/S08A/F08/S08/F09A/S09A/F09/S09/F10A/S10A/F10/S10/' -M=5.0 input/raw.txt > output/out.txt\n";
	print "\n";

	exit 0;
}

my $id_num;
my $name_string;
my $last_name;
my $first_name;
my $middle_name;
my $grade_current;
my $gender;
my $birth_date_string;
my $course_num;
my $course_name;
my $course_weight;
my $course_score;
my $course_score_num;
my $course_grade;
my $course_date;
my $course_school_string;
my %courses_taken;
my $course_struct;

#Required maps
my %grade_mapping_std = ('A',4.0,'B',3.0,'C',2.0,'D',1.0,'F',0.0);
my %grade_mapping_ap = ('A',5.0,'B',4.0,'C',3.0,'D',2.0,'F',0.0);
my %semester_map = ('01','F','02','F','03','F','04','S','05','S','06','S','07','S','08','S','09','S','10','F','11','F','12','F');

#Parse the interval list
my @interval_list = split(/[^A|^F|^S|^C|^\d]/,$T);

#Parse the academic course spec file
my @ac_course_list=();
if(length($A))
{
	open FILE, "<", $A or die $!;
	while (<FILE>)
	{
		chomp;
		while($_ =~ /(\d{6})/g)
		{
			push @ac_course_list,$1;
		}
	}
}

sub round_gpa
{
	if($_[0] =~ m/^(?!N\/A$)/){
		return sprintf("%.2f",$_[0]);
	}
	return "N/A";
}

#main row loop
while (<>) {

	#Determine what type of relevent data is encoded
	given($_)
	{
		#New student entry -- reset
		when(/^TR10.*ID (\d{6}[M|F]\d{3})/){
			#Clear the courses_taken hash
			%courses_taken = ();

			#Parse student ID number
			$id_num = $1;
		}

		#Parse additional student bio data
		when(/^Name: (.*)Birth: (\d\d\/\d\d\/\d\d)  Sex: ([M|F])/) {
			$name_string = $1;
		        $birth_date_string = $2;
			$gender = $3;	
			$name_string =~ s/\s+$//;
		}
		when(/.*Grade: (\d+)/)
		{
			$grade_current = $1;
			#print "$id_num $name_string $birth_date_string $gender $grade_current";
		}

		#Parse and process individual courses
		when(/(^\d{6}) (.+?)  (\d.\d)  (.{3})  Gr(\d\d)  (\d\d\/\d\d\/\d\d)  (.*)/) {
			$course_num = $1;
			$course_name = $2;
			$course_weight = $3;
			$course_score = $4;
			$course_grade = $5;
			$course_date = $6; #MM/DD/YY date format
			$course_school_string = $7; 
		
			#Determine numeric score
			if($course_name =~ /^AP .*/){ 
				$course_score_num = $grade_mapping_ap{substr($course_score,0,1)};
			}
			else{
				$course_score_num = $grade_mapping_std{substr($course_score,0,1)};
			}
			
			#Deal w/ invalid (ie. not A,B,C,D,F) scores
			if(not defined($course_score_num)){
				$course_score_num = 0.0;
				$course_weight = 0.0;
			}

				
			my $rec = {name => $course_name, weight => $course_weight, score => $course_score_num, grade => $course_grade, date => $course_date};
				
			#Add to courses_taken hash -> new entry
			if(not exists($courses_taken{$course_num})){
				$courses_taken{$course_num} = ();
				push @{$courses_taken{$course_num}},$rec
			}
			else { 
				#Same course already exists -> keep more recent date (top of file), but update to older grade (bottom of file, parsed later)
				#Only allowed if previously taken course was a D/F, otherwise don't replace, but just add an additonal instance
				if(not substr($course_score,0,1) =~ /[D|F]/){
					push @{$courses_taken{$course_num}},$rec
				}
				else{
					#Update grade_year and date...need both to determine semester
					$courses_taken{$course_num}[-1]{date}=$course_date;
					$courses_taken{$course_num}[-1]{grade}=$course_grade;
				}
			}
		}

		#Finalize student
		when(/^Date Printed: (\d\d\/\d\d\/\d\d)/){

			my $course_array;
			my $current_interval;

			#Intialize gpa accumulators
			my %ov_gpa = ();
			my %ov_weight_sum = ();
			my %ov_gpa_round = ();
			foreach(@interval_list){
				$ov_gpa{$_}=0.0;
				$ov_weight_sum{$_}=0.0;
			}

			#Compute weighted GPA...
			
			#print "****$id_num $name_string $birth_date_string $gender $grade_current $gpa";
			#Iterate over all course numbers
			while( ($course_num, $course_array) = each %courses_taken)
			{
				
				#Determine if is an ACADEMIC course
				my $is_academic_course = ($course_num ~~ @ac_course_list)? 1 : 0;
				
				#Iterate over all courses w/ same course number, ie. were not retakes
				foreach $course_struct (@{$course_array})
				{
					my $effective_weight = ($W or ($course_struct->{weight} == 0.0)) ? $course_struct->{weight} : 1.0; #Use contant weight? (Zero weight overides this)

					#Iterate over all time intervals 
					foreach  $current_interval (@interval_list)
					{
						#Cumulative overall/academic
						if($current_interval =~ m/^C((\d\d)*)([A|O]?)$/)
						{
							my $academic_interval = $3;
							my @valid_years = ( $1 =~ m/../g );
								
							#Match valid_years or is entire available history?
							if((not scalar(@valid_years)) or ($course_struct->{grade} ~~ @valid_years))
							{
								
								#Academic or overall?	
								if((length($academic_interval) == 0) or ($academic_interval =~"O") or ($is_academic_course and ($course_struct->{weight} >= $M) and ($academic_interval =~ "A"))){
									$ov_gpa{$current_interval} += ($effective_weight * $course_struct->{score});
									$ov_weight_sum{$current_interval} += $effective_weight;
									
								}

							}	
						}
						#Parse interval format and extract semester/year
						elsif($current_interval =~ m/^([F|S]?)(\d\d)([A|O]?)$/)
						{
							my $current_sem = $1;
							my $current_year = $2;
							my $academic_interval = $3;
						

							#Match grade_year?
							if($course_struct->{grade} =~ $current_year)
							{
								#Semesters match, or full academic year
								if((not length($current_sem)) || (length($current_sem) and ($semester_map{substr($course_struct->{date},0,2)} =~ $current_sem)))
								{
									#Academic or overall?	
									if((length($academic_interval) == 0) or ($academic_interval =~"O") or ($is_academic_course and ($course_struct->{weight} >= $M) and ($academic_interval =~ "A"))){
										$ov_gpa{$current_interval} += ($effective_weight * $course_struct->{score});
										$ov_weight_sum{$current_interval} += $effective_weight;
										
									}
								}

							}
						}
						else
						{
							print "ERROR: Invalid interval specifier string! Exiting...\n";
							exit 1;
						}
					}
				}
			}
		
			#Iterate over all intervals
			foreach  $current_interval (@interval_list)
			{
				$ov_gpa{$current_interval} = ($ov_weight_sum{$current_interval} > 0.0) ? $ov_gpa{$current_interval}/$ov_weight_sum{$current_interval} : "N/A";
				
				#Round gpa
				$ov_gpa_round{$current_interval} = round_gpa($ov_gpa{$current_interval});

			}
		
			print "$id_num|$name_string|$birth_date_string|";
			print map { "$ov_gpa_round{$_}|" } @interval_list;
			print "\n";
		}
	}	
    } 
    continue 
    {
      close ARGV if eof;
    }
      
