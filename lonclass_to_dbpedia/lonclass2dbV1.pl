#!/usr/bin/perl

$lcfile = $ARGV[0];
$dbfile = $ARGV[1];

%db=();
%lc=();
%titles=();
%matched = ();

$oops = "LonclassToDB_ERR.txt";
open (OOPS, ">$oops") || die "could not open $oops, $!";

open (FILE, $lcfile) || die "could not open $lcfile, $!";
while ($line = <FILE>)
{
	#"3"645.42|BED TIME|
        if($line=~m/^(.*?)\|(.*)([\|])?.+/)

	{
		chomp $line;
		$code=$1;
		$lcterm=$2;
                $lcterm=~s/\(.*\)//;
		$lclcterm=lc($lcterm);
		#warn $lclcterm;
		$lc{$lclcterm}=$code;
		$titles{$lclcterm}=$lcterm;
	}
}


open (FILED, $dbfile) || die "could not open $wnfile, $!";
while ($ligne = <FILED>)
{
	chomp $ligne;
	#<http://dbpedia.org/resource/AmericA> <http://www.w3.org/2000/01/rdf-schema#label> "AmericA"@en .
	$ligne=~m/<http:\/\/dbpedia\.org\/resource\/(.+?)>.+?\"(.+?)\"@en/;
	$label = $2;
	$label=lc($label);
#	$uri = "http://dbpedia.org/resource/".$1;
	$uri = "http://en.wikipedia.org/wiki/".$1;
		$labePl=$label."s";
		$db{$label}=$uri;
		$dbpl{$labelPl}=$uri;
}

foreach $w (keys %db)
{
	if(length($w) > 2)
	{
		$labelS=$w."s";
		if($lc{$w})
		{
			print "exact match\t$w\t$lc{$w}\t$db{$w}\t$w\n";
			$matched{$w}=$lc{$w};

		}elsif($lc{$labelS})
		{
			print "sg/pl\t$w\t$lc{$labelS}\t$db{$w}\t$labelS\n";
			$matched{$labelS}=$lc{$labelS};
		}else{
#			print OOPS "Not matched: $w $labelS\n"
		}

		#to do: add partial matchings
	}
}

close(OOPS);
close(FILE);
close(FILED);

open (OUT, ">lc.txt") || die "could not open $oops, $!";
print OUT join("\n",keys %lc);

close(OUT);

my $a = scalar keys %lc;
my $b = scalar keys %db;
my $c = scalar keys %matched;

print STDERR "LC size ".$a."\n";
print STDERR "DB size ".$b."\n";
print STDERR "MATCHED size ".$c."\n";

