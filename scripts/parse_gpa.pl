#!/usr/bin/perl -wls
use strict;
use feature 'switch';
use POSIX;

our($weighted);
if(not defined $weighted) {$weighted = 0;}

sub uniq {
	    return keys %{{ map { $_ => 1 } @_ }};
    }

sub date_cmp {
	(my $month0, my $day0, my $year0) = split(/\//,$_[0]);
	(my $month1, my $day1, my $year1) = split(/\//,$_[1]);
	if($year0 < $year1) { return 1; }
	elsif($year1 < $year0) { return -1;}
	else{
		if($month0 < $month1) { return 1;}
		elsif($month1 < $month0) { return -1; }
		else{
			if($day0 < $day1) { return 1; }
			elsif($day1 < $day0) {return -1;}
		       	else { return 0; }	
		}
	}
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

my %grade_mapping_std = ('A',4.0,'B',3.0,'C',2.0,'D',1.0,'F',0.0);
my %grade_mapping_ap = ('A',5.0,'B',4.0,'C',3.0,'D',2.0,'F',0.0);


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

			#Determine if this course should be part of the academic GPA
			#my @regex_list = map { qr{$_} } ('ALGEBRA','GEOMETRY');
			#if($course_name ~~ @regex_list)
			{	
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
						#print "push $course_name!";
						push @{$courses_taken{$course_num}},$rec
					}
					else{
						$courses_taken{$course_num}[-1]{grade}=$course_grade;
					}
				}
			}

		}

		#Finalize student
		when(/^Date Printed: (\d\d\/\d\d\/\d\d)/){
			my $gpa = 0.0;
			my $weight_sum = 0.0;
			my $course_array;

			#Compute weighted GPA...
			
			print "****$id_num $name_string $birth_date_string $gender $grade_current $gpa";
			#Iterate over all course numbers
			while( ($course_num, $course_array) = each %courses_taken){
				
				#Iterate over all courses w/ same course number, ie. were not retakes
				foreach $course_struct (@{$course_array})
				{
				
					#Add to apporiate sum
					if($course_struct->{grade} =~ /10/){

						print "$course_struct->{name} $course_struct->{weight} $course_struct->{score} $course_struct->{grade} $course_struct->{date}";
						$weight_sum += $course_struct->{weight};
						$gpa += ($course_struct->{weight} * $course_struct->{score});
					}
				}
			}
			
			if($weight_sum > 0.0){
				$gpa /= $weight_sum;
			}
			else{
				$gpa = "N/A";
			}
			
			#$gpa = sprintf("%.2f",$gpa);
			print "$id_num $name_string $birth_date_string $gender $grade_current $gpa";
		}
	}
	
    } 
    continue 
    {
      close ARGV if eof;
	}
      
