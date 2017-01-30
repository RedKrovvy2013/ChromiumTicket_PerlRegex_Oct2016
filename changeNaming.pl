#!/usr/bin/perl -w

use File::Basename "dirname";
use Cwd  "abs_path";
use lib dirname(abs_path $0) . '/lib';
use NoFly "isInNoFly";

sub recurseFiles {

	opendir DIR, $_[0];
	my @files = readdir(DIR);
	foreach $file (@files) {
	  my $filepath = "$_[0]/$file";
	  if(-f $filepath) {
	  
	    #print "$filepath\n";

		if ( ($filepath =~ m/(?:cc|h)$/) && (not isInNoFly($filepath)) ) {
			readFile($filepath);
		}
		
	  } else {
	  	#print "foo and $file\n";
		if( $file !~ m[^\.{1,2}|\.git$] ) {
			#print "opening $file folder\n";
			recurseFiles("$filepath");
		}
	  }
	}
}

sub readFile {
	
	my $filepath = $_[0];
	my $file;
	{
		local $/;
		open my $fh, "<", $filepath
			or die "can't open $filepath : $!";
		$file = <$fh>;
	}
	
	$file =~ s{NetLog::(Entry(?:Data)?)}{NetLog$1}g;
	
	$file =~ s{NetLog::Source(?!TypeToString)}{NetLogSource}g;
	
	$file =~ s{NetLog::ParametersCallback}{NetLogParametersCallback}g;
	
	
	open my $fh, ">", $filepath
		or die "can't open $filepath for writing : $!";
	
	print $fh $file;
	
}

recurseFiles("/chromium/src");


#recurseFiles("/chromium2/src/content/browser/download");

#recurseFiles("/Users/michaelcirone/code/Projects/Chromium/inner classes extraction 2/test");

