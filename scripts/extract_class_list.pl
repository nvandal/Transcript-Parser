#!/usr/bin/perl -w -l
use strict;
if ( @ARGV <= 0 )
{
    print "extract_class_list";
    print "";
    print "Perl script to parse raw transcript file and compute generate list of unique";
    print "course numbers and their associated course names";
    print "";
    print "Copyright: 2012 Nicholas Vandal";
    print "There is ABSOLUTELY NO WARRANTY; not even for MERCHANTABILITY or";
    print "FITNESS FOR A PARTICULAR PURPOSE.";
    print "";
    print "usage: extract_class_list file";
    print "";
	print "Examples:";
	print "   ./extract_class_list.pl input/raw.txt > input/classes_all_aliases.txt";
    print "";
    exit 0;
}

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
