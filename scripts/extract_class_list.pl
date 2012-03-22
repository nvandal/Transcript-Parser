#!/usr/bin/perl -w -l
use strict;

my %hash=();

sub uniq {
	    return keys %{{ map { $_ => 1 } @_ }};
    }


while (<>) {
    if(m/(^\d{6}) (.+?)  \d.\d  /){
        
	#Strip extra trailing whitespace of description
	my $desc = $2;
	my $course_num =$1;
	$desc =~ s/\s+$//;
	#print "\"$desc\"";

	#Add to hash table
	push( @{$hash{$course_num}}, $desc); 
    }
   
    } continue {
      close ARGV if eof;
      }
      
      my @unique = sort keys %hash;
      foreach my $key (@unique)
      {
	my @aliases = @{$hash{$key}};
	my @uniq_aliases = uniq(@aliases);	
	print "$key|" . join("|",@uniq_aliases);

      }
