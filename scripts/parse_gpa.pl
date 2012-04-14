#!/usr/bin/perl -ws

#parse_gpa.pl
#Copyright: Nick Vandal 2009
#Calculates GPAs from a transcripts

use strict;
use feature 'switch';
use POSIX;


#Command line switches
our($W, $T, $A, $M, $NR, $NS, $FR, $NG, $h); #Weighted, interval_string, academic_course_file, minWeight, noReplacement
if(not defined $W) {$W = 0;}
if(not defined $T) {$T = 'C';}
if(not defined $A) {$A = '';}
if(not defined $M) {$M = 0;}
if(not defined $NR) {$NR = '';}
if(not defined $NS) {$NS = 0;}
if(not defined $NG) {$NG = 0;}

print "NG=$NG\n\n";

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
	print "   -M=<minweight>\tSpeciy minimum course weight required for course to be included in the academic GPA (0.0 by default)\n";
	print "   -FR=[file]\t\tSpecify file containing courses which only replace the grades of those previously FAILED. If no file specified, ONLY failing grades (F) are replaced globally (disabled by default, C/D/F's are replaced globally)\n";
	print "   -NR=[file]\t\tSpecify file containing courses which NEVER replace the grades of those previously taken. If no file specified, no replacements are made (disabled by default)\n";
	print "   -NS\t\t\tDo not include courses taken over the summer in the fall semester. No effect on replacement courses taken over the summer (disabled by default)\n";
	print "   -NG\t\t\tUse student's nominal grade level (ie. they advance to the next grade level every year regardless of course failures)\n";
	print "\n";
	print "\n";
	print "Examples:\n";
	print "   ./parse_gpa.pl input/raw.txt\n";
	print "   ./parse_gpa.pl -A='input/selected.txt' -T='09/09A/F10/S10A/C0910/C080910A/C/CA' input/raw.txt\n";
	print "   ./parse_gpa.pl -A=input/selected.txt -NR=input/noreplace.txt -T='F07A/S07A/F07/S07/F08A/S08A/F08/S08/F09A/S09A/F09/S09/F10A/S10A/F10/S10/' -M=5.0 input/raw.txt > output/out.txt\n";
	print "   ./parse_gpa.pl -A=input/selected.txt -NR=input/noreplace.txt -FR=input/failonly.txt -T='F09/S09/F10/S10' -M=5.0 -NS -NG input/raw.txt > output/out.txt\n";
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
my $course_semester;
my $course_school_string;
my %courses_taken;
my $course_struct;
my %semester_groups;
my $course_ref;

#Required maps
my %grade_mapping_std = ('A',4.0,'B',3.0,'C',2.0,'D',1.0,'F',0.0);
my %grade_mapping_ap = ('A',5.0,'B',4.0,'C',3.0,'D',2.0,'F',0.0);
my %semester_map = ('01','F','02','F','03','F','04','S','05','S','06','S','07','S','08','S','09','S','10','F','11','F','12','F');
my @summer_interval = ('05','09'); #[may sep] inclusive
my $max_summer_courses = 3;

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
	close FILE;
}


#Parse the noreplacement course spec file
my @nr_course_list=();
my $nr_all;
if($NR =~ /^(0|false)$/)
{
	$nr_all = 0;
}
elsif($NR =~ /^(1|true)$/)
{
	$nr_all = 1;
}
elsif(length($NR))
{
	$nr_all = 0;
	open FILE, "<", $NR or die $!;
	while (<FILE>)
	{
		chomp;
		while($_ =~ /(\d{6})/g)
		{
			push @nr_course_list,$1;
		}
	}
	close FILE;
}
else
{
	$nr_all = 0;
}

sub round_gpa
{
	if($_[0] =~ m/^(?!N\/A$)/){
		return sprintf("%.2f",$_[0]);
	}
	return "N/A";
}

#main row loop
while (<>)
{

	#Determine what type of relevent data is encoded
	given($_)
	{
		#New student entry -- reset
		when(/^TR10.*ID (\d{6}[M|F]\d{3})/){
			#Clear the courses_taken hash
			%courses_taken = ();
			%semester_groups = ();

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
		when(/(^\d{6}) (.+?)  (\d.\d)  (.{3})  Gr(\d\d)  (\d\d\/\d\d\/\d\d)  (.*)/)
		{
			$course_num = $1;
			$course_name = $2;
			$course_weight = $3;
			$course_score = $4;
			$course_grade = $5;
			$course_date = $6; #MM/DD/YY date format
			$course_school_string = $7; 
			$course_semester = $semester_map{substr($course_date,0,2)};

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

			my $rec = {name => $course_name, weight => $course_weight, score => $course_score_num, grade => $course_grade, nominal_grade => 0, date => $course_date, semester => $course_semester};

			#Add to courses_taken hash -> new entry
			if(not exists($courses_taken{$course_num}))
			{
				$courses_taken{$course_num} = ();
				push @{$courses_taken{$course_num}},$rec;
				$course_ref = \($courses_taken{$course_num}[-1]); 
			}
			else
			{ 
				#Same course already exists -> keep more recent date (top of file), but update to older grade (bottom of file, parsed later)
				#Only allowed if noReplacement is false and previously taken course was a C/D/F, otherwise don't replace, but just add an additonal instance
				if($nr_all or (not substr($course_score,0,1) =~ /[D|F|C]/) or ($course_num ~~ @nr_course_list) )
				{
					push @{$courses_taken{$course_num}},$rec;
					$course_ref = \($courses_taken{$course_num}[-1]); 
				}
				else
				{
					#Update grade_year and date...need both to determine semester
					$courses_taken{$course_num}[-1]{date}=$course_date;
					$courses_taken{$course_num}[-1]{grade}=$course_grade;
					$courses_taken{$course_num}[-1]{semester}=$course_semester;
					$course_ref = undef;
				}
			}

			#Add reference to course to semester grouping hash
			if(not exists($semester_groups{$course_date}))
			{
				$semester_groups{$course_date} = ();
			}
			push @{$semester_groups{$course_date}},$course_ref;
		}

		#Finalize student
		when(/^Date Printed: (\d\d\/\d\d\/\d\d)/)
		{

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

			#Update summer semesters (for nonreplaced courses ONLY), if required
# 			if($NS)
# 			{
# 				while( ($course_date, $course_array) = each %semester_groups)
# 				{
# 					my $num_courses = scalar(@{$course_array});
# 					my $course_month = substr($course_date,0,2);
# 					if($num_courses <= $max_summer_courses and $course_month >= $summer_interval[0] and $course_month <= $summer_interval[1]) #Summer conditions
# 					{
# 						foreach $course_ref (@{$course_array})
# 						{
# 							if(defined $course_ref)
# 							{
# 								$course_struct = $$course_ref;
# 								if($course_date =~ $course_struct->{date}) #nonreplaced
# 								{
# 									$course_struct->{semester} = 'R';
# 								}
# 							}
# 						}
# 					}
# 				}
# 
# 			}

			#Sort semesters MM/DD/YY
			my @sorted_semesters = reverse map {$_->[0]} 
				   sort {$b->[3] <=> $a->[3] || $b->[1] <=> $a->[1] ||  $b->[2] <=> $a->[2]}
			           map { [$_,split(/\//,$_)] } 
				   keys %semester_groups;

			my $nominal_grade;
			my $nominal_grade_shift = 0;
			my %nominal_grade_accum = ();

			#Convert semester grouping -> nominal grade level of student
			foreach $course_date (@sorted_semesters)
			{
				#Characteristics of the semester
				$course_array = $semester_groups{$course_date};
				my $num_courses = scalar(@{$course_array});
				my $course_month = substr($course_date,0,2);
				my $is_full_semester = ($num_courses > $max_summer_courses) ? 1 : 0;
			        my $is_summer = (not $is_full_semester and $course_month >= $summer_interval[0] and $course_month <= $summer_interval[1]) ? 1 : 0;
				my $semester_grade='N/A';
				my $semester_period = ($is_summer) ? "R" : $semester_map{$course_month};

				#Iterate through all courses to determine semester and apply summer correction
				foreach $course_ref (@{$course_array})
				{
					if(defined $course_ref)
					{
						$course_struct = $$course_ref;
						if($course_date =~ $course_struct->{date}) #nonreplaced
						{
							#Only if not including summer semesters in the next fall
							if($is_summer and $NS)
							{
								$course_struct->{semester} = 'R';
							}
							$semester_grade = $course_struct->{grade};
						}
					}
				}
				
				#Determine nominal grade
				$nominal_grade = $semester_grade;
				if($is_full_semester and $semester_grade =~ '09') #TODO: fix this to make more general case
				{

					my $sem_key = "$semester_period"."$semester_grade";
					if(not exists($nominal_grade_accum{$sem_key}))
					{

						$nominal_grade_accum{$sem_key}=0;
					}
					else
					{
						$nominal_grade_accum{$sem_key} = $nominal_grade_accum{$sem_key} + 1;
					}
					$nominal_grade += $nominal_grade_accum{$sem_key};
				}	

				#Iterate through coursees to apply nominal grade
				foreach $course_ref (@{$course_array})
				{
					if(defined $course_ref)
					{
						$course_struct = $$course_ref;
						if($course_date =~ $course_struct->{date}) #nonreplaced
						{
							$course_struct->{nominal_grade} = sprintf("%.2d",$nominal_grade); #TODO: need to apply this to replaced semesters also
						}
					}
				}


				print "$semester_period $semester_grade  $nominal_grade $is_full_semester :: ";

				print "$course_date $course_array\n";
				foreach $course_ref (@{$course_array})
				{
					if(defined $course_ref)
					{
						$course_struct = $$course_ref;
						print ">>> $course_struct->{name} $course_struct->{grade} $course_struct->{nominal_grade} $course_struct->{date} $course_struct->{semester}\n";
					}
				}
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
				my $effective_grade = (not $NG or $course_struct->{nominal_grade} == '0') ?  $course_struct->{grade} : $course_struct->{nominal_grade};
				print ">EG=$effective_grade $course_struct->{grade} $course_struct->{nominal_grade} \n";

				#Iterate over all time intervals 
				foreach  $current_interval (@interval_list)
				{
					#Cumulative overall/academic
					if($current_interval =~ m/^C((\d\d)*)([A|O]?)$/)
					{
						my $academic_interval = $3;
						my @valid_years = ( $1 =~ m/../g );

						#Match valid_years or is entire available history?
						if((not scalar(@valid_years)) or ($effective_grade  ~~ @valid_years))
						{
							#Academic or overall?	
							if((length($academic_interval) == 0) or ($academic_interval =~"O") or ($is_academic_course and ($course_struct->{weight} >= $M) and ($academic_interval =~ "A")))
							{
								$ov_gpa{$current_interval} += ($effective_weight * $course_struct->{score});
								$ov_weight_sum{$current_interval} += $effective_weight;
							}
						}	
					}
					#Parse interval format and extract semester/year
					elsif($current_interval =~ m/^([F|S|R]?)(\d\d)([A|O]?)$/)
					{
						my $current_sem = $1;
						my $current_year = $2;
						my $academic_interval = $3;


							#Match grade_year?
							if($effective_grade =~ $current_year)
							{
								#Semesters match, or full academic year
								if( ((not length($current_sem)) and $course_struct->{semester} !~ 'R') || (length($current_sem) and  ($course_struct->{semester} =~ $current_sem)))
								{
									#Academic or overall?	
									if((length($academic_interval) == 0) or ($academic_interval =~"O") or ($is_academic_course and ($course_struct->{weight} >= $M) and ($academic_interval =~ "A")))
									{
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

			#Print out the student info
			print "$id_num|$name_string|$birth_date_string|";

			#Print out the GPAs
			print map { "$ov_gpa_round{$_}|" } @interval_list;
			print "\n";
		}
	}	
} 
continue 
{
	close ARGV if eof;
}

