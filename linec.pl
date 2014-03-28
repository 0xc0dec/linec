#!/usr/bin/perl

# Source code lines counter v1.1
# Script for counting non-empty and non-comment source code lines.
# The following comments are supported:
#	/* ... */
#	// ...
#	# ...
# Usage: linec.pl [-r] [FOLDER]
# Parameters:
#	-r: 	makes script to watch folders recursively
#	FOLDER: input folder. If not specified, folder '.' is used
#
# Copyright (c) 2010 Aleksey "0xc0dec" Fedotov

use locale;


# Config options section begin

# File extensions. Only files with these extensions will be read
$extensions = ".c, .cpp, .cxx, .h, .hpp, .cs, .java, .pl, .pm";

# Config options section end


$total_count = 0;
$file_number = 0;

$folder = ".";
$r = 0;

@ext_list = map { quotemeta if !/^$/ } split(/[, ]+/, $extensions);


sub count($)
{
	open FILE, shift or die "Cannot open file \"$name\"\n";
	my $fc = join "", ;
	close FILE;
	$fc =~ s|/\*.*?\*/||gsx;
	my @fc_list = grep { !/^\s*$/ && !/^\s*\/\// && !/^\s*#/ } split(/\n/, $fc);
	$total_count += $#fc_list + 1;
	return $#fc_list + 1;
}

sub process($)
{
	my $name = shift;
	$name =~ tr(\\/)s;
	if (-f $name && (grep { $name =~ /$_$/ } @ext_list) != 0)
	{
		($report_number, $report_file, $report_count) = (++$file_number, $name, count($name));
		write;
	}
	# maybe '-d' check here is not necessary
	elsif (-d $name)
	{
		return if ($name ne $folder && $r == 0);
		opendir DIR, $name;
		my @content = readdir DIR;
		closedir DIR;
		foreach (@content)
		{
			process("$name/$_") if ($_ ne "." && $_ ne "..");
		}
	}
}

# Read command line parameters
if (defined $ARGV[0])
{
	if ($ARGV[0] eq '-r')
	{
		$r = 1;
		$folder = $ARGV[1] if (defined $ARGV[1]);
	}
	else
	{
		$folder = $ARGV[0] if (defined $ARGV[0]);
	}
}

unless (-d $folder)
{ 
	print "Invalid dir\n"; 
	exit;
}


$~ = HEADER;
($report_folder, $report_recursive) = ($folder, $r);
write;

$~ = EACH;
process($folder);

$~ = FOOTER;
($report_file_number, $report_total_count) = ($file_number, $total_count);
write;


# Formats

format HEADER=
********************************************************************************
* Input folder:   ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< *
$report_folder
*                 ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< *~~
$report_folder
* Recursive mode: @<                                                           *
$report_recursive
********************************************************************************
.

format EACH=
* ^||||||| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | ^||||||| *
$report_number, $report_file, $report_count
* ^||||||| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | ^||||||| *~~
$report_number, $report_file, $report_count
.

format FOOTER=
********************************************************************************
* Files count:       @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< *
$report_file_number
* Total lines count: @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< *
$report_total_count
********************************************************************************
.
