#! /usr/bin/env perl

#
# The BVBRC App wrapper for Genomad
# https://github.com/apcamargo/genomad
#

use Carp::Always;
use Bio::KBase::AppService::AppScript;
use File::Slurp;
use strict;
use Data::Dumper;

my $db = "/home/jjdavis/CEPI/Services/dev_container/modules/genomad/genomad_db"; 
my $script = Bio::KBase::AppService::AppScript->new(\&genomad, \&preflight);
$script->run(\@ARGV);

sub preflight
{
    my($app, $app_def, $raw_params, $params) = @_;    
	   
    #
    # Ensure the contigs are valid, and look up their size.
    #

    my $ctg = $params->{input_file};
    $ctg or die "Assembled contigs must be specified\n";
    my $res = $app->workspace->stat($ctg);
    my $size = $res->size;
    $size > 0 or die "Contigs not found\n";
	
	
	# actual usage estimates, wall time will be cushioned.
	# 1MB jobs: ~5–6 minutes (with 8–16 threads).
	# 10MB jobs: ~10 minutes (with 16 threads).
	# 100MB jobs: ~30–35 minutes (with 16-32 threads).
	# 1000MB jobs: ~6 hours (with 16–32 threads).
	# 10GB jobs (extrapolated): expect ~60 hours (2.5 days) with 16–32 threads.

	# Jobs never exceed 25GB mem, but I'm setting this at 32 to have some wiggle room
	# if the database ever gets updated. 
	
	# Genomad does a bad job running in parallel, there is actually a slight degredation of 
	# performance beyond 32 threads. 
	
	my $runtime;
	if ($size < 10000000)
	{
		$runtime = 3600; #1hr wall time for jobs < 10MB
	}
	elsif (($size >= 10000000) && ($size < 100000000))
	{
		$runtime = (3600 * 4); # 4 hr wall time for job < 100MB
	}
	elsif (($size >= 100000000) && ($size < 1000000000))
	{
		$runtime = (3600 * 12); # 12 hr wall time for job 100MB-1GB
	}
	elsif ($size >= 1000000000)
	{
		$runtime = (3600 * 72); # 3 day wall time for job > 1GB
	}
    return { cpu => 16, memory => '32G', runtime => $runtime };
}

sub genomad
{
    my($app, $app_def, $raw_params, $params) = @_;

    print "App-Genomad: ", Dumper($app_def, $raw_params, $params);
	my $threads = $ENV{P3_ALLOCATED_CPU} // 16;
	
    my $input_path = $params->{'input_file'};
    my $input_file = $input_path;
	$input_file =~ s/.+\///g; 

    $app->workspace->download_file($input_path,
    				   "$input_file",
				   1 # Use Shock if file is in Shock
				   );

	#ensure input is a fasta file of assembled contigs:
	open my $fh, "<", $input_file or die "could not open fasta file of contigs for vaildation\n";
	my @lines = map { scalar <$fh> } 1..4;
	close $fh;	
	die "Input File is not fasta format.\n" unless $lines[0] =~ /^>/; 
	die "Input file is likley FASTQ format. Assembled contigs are required.\n" if grep { /^\+/ } @lines;  
	die "Not DNA FASTA\n" if grep { !/^>/ && /[^ACGTRYKMSWBDHVN\s]/i } @lines;
	
	
	# Usage: genomad end-to-end [OPTIONS] INPUT OUTPUT DATABASE                                                                   
	my @command;
	my $of = $params->{'output_file'};
	push @command, ("genomad", "end-to-end", "--threads", "$threads"); 
	if ($params->{'cleanup'}){push @command, "--cleanup";}
	if ($params->{'restart'}){push @command, "--restart";}
	if ($params->{'verbose'}){push @command, "--verbose";}
	if ($params->{'lenient-taxonomy'}){push @command, "--lenient-taxonomy";}
	if ($params->{'full-ictv-lineage'}){push @command, "--full-ictv-lineage";}
	if ($params->{'force-auto'}){push @command, "--force-auto";}
    if ($params->{'filtering-preset'}){push @command, "--$params->{'filtering-preset'}";}
    if ($params->{'composition'})
    {	push @command, "--composition";
    	push @command, $params->{'composition'};
    }
	push @command, $input_file;
	push @command, $of;
	push @command, $db;
	
    my $rc = system(@command);   
    die "Failure running genomad" if $rc != 0;
	
	#I want to concatenate the log files into a single file in the right order so 
	#that it can be kept.  It has some useful info on the run with versions, etc.
	my $cat = "cat $of/final.contigs_annotate.log $of/final.contigs_find_proviruses.log $of/final.contigs_marker_classification.log $of/final.contigs_nn_classification.log $of/final.contigs_aggregated_classification.log $of/final.contigs_summary.log > $of/geNomad_run.stderr"; 
	my $rc = system($cat);   
    die "Failure concatenating log file" if $rc != 0;
	
	my $folder = $app->result_folder();

	my @to_move = 	opendir (DIR, "$of/final.contigs_summary/");
	my @reorg = grep{$_ !~ /^\./ && $_ !~ /log/ }readdir(DIR); 
	closedir DIR;
	foreach (@reorg)
	{
		if ($_ =~ /\.tsv$/)
		{
			$app->workspace->save_file_to_file("$of/final.contigs_summary/$_", {}, "$folder/$_", 'tsv', 1);
		}
		elsif ($_ =~ /\.faa$/)
		{
			$app->workspace->save_file_to_file("$of/final.contigs_summary/$_", {}, "$folder/$_", 'feature_protein_fasta', 1);
		}
		elsif ($_ =~ /\.fna$/)
		{
			$app->workspace->save_file_to_file("$of/final.contigs_summary/$_", {}, "$folder/$_", 'contigs', 1);
		}
		elsif ($_ =~ /\.json$/)
		{
			$app->workspace->save_file_to_file("$of/final.contigs_summary/$_", {}, "$folder/$_", 'json', 1);
		}
	}

	$app->workspace->save_file_to_file("$of/geNomad_run.stderr", {}, "$folder/geNomad_run.stderr", 'txt', 1);
}
