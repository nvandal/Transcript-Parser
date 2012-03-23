#!/usr/bin/perl -ws
use strict;
use feature 'switch';
use POSIX;

#Command line switches
our($weighted);
if(not defined $weighted) {$weighted = 0;}

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

my %grade_mapping_std = ('A',4.0,'B',3.0,'C',2.0,'D',1.0,'F',0.0);
my %grade_mapping_ap = ('A',5.0,'B',4.0,'C',3.0,'D',2.0,'F',0.0);
my %semester_map = ('01','F','02','F','03','F','04','S','05','S','06','S','07','S','08','S','09','S','10','F','11','F','12','F');

my @interval_list = ('F09','S09','09','F10','S10','10');


sub round_gpa
{
	if($_[0] =~ m/^\d+.\d+$/){
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
			$course_weight = $weighted ? $3 : 1.0; #Check to apply equal weighting or not
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
			my %ac_gpa = ();
			my %ac_weight_sum = ();
			my %ov_gpa_round = ();
			my %ac_gpa_round = ();
			foreach(@interval_list){
				$ov_gpa{$_}=0.0;
				$ac_gpa{$_}=0.0;
				$ov_weight_sum{$_}=0.0;
				$ac_weight_sum{$_}=0.0;
			}

			#Compute weighted GPA...
			
			#print "****$id_num $name_string $birth_date_string $gender $grade_current $gpa";
			#Iterate over all course numbers
			while( ($course_num, $course_array) = each %courses_taken)
			{
				
				#Iterate over all courses w/ same course number, ie. were not retakes
				foreach $course_struct (@{$course_array})
				{
					#Determine if is an ACADEMIC course
					#TODO
					
					#Iterate over all time intervals 
					foreach  $current_interval (@interval_list)
					{
						#Parse interval format and extract semester/year
						if($current_interval =~ m/([F|S]?)(\d\d)/)
						{
							my $current_sem = $1;
							my $current_year = $2;
							
							#Match grade_year?
							if($course_struct->{grade} =~ $current_year)
							{
								#Semesters match, or full academic year
								if((not length($current_sem)) || (length($current_sem) and ($semester_map{substr($course_struct->{date},0,2)} =~ $current_sem)))
								{
									#Add to appropriate running sum	
									$ov_gpa{$current_interval} += ($course_struct->{weight} * $course_struct->{score});
									$ov_weight_sum{$current_interval} += $course_struct->{weight};
								}

							}
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
		
			print "$id_num $name_string  $grade_current ";
			print map { "$ov_gpa_round{$_} " } @interval_list;
			print "\n";
		}
	}	
    } 
    continue 
    {
      close ARGV if eof;
    }
      
