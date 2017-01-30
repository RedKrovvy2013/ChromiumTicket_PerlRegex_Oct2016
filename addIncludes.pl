#!/usr/bin/perl -w

use File::Basename "dirname";
use Cwd  "abs_path";
use lib dirname(abs_path $0) . '/lib';
use NoFly "isInNoFly";
use GetFileHeader "getFileHeader";
use RefChecker;
use NetLogTypeData;
use NoT;
use Adds;

sub recurseFiles {

	opendir DIR, $_[0];
	my @files = reverse readdir(DIR);
	foreach $file (@files) {
	  my $filepath = "$_[0]/$file";
	  if(-f $filepath) {
	  
	    #print "$filepath\n";

		if ( ($filepath =~ m/(?:cc|h)$/) && (not isInNoFly($filepath)) ) {
		    our $gFilepath = $filepath;
			changeFile();
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

sub changeFile {

	my $file;
	{
	    local $/;
	    open my $fh, '<', $gFilepath
	    	or die "can't open $gFilepath: $!";
	    $file = <$fh>;
	}
	
    my $fileHeader;
	getFileHeader($gFilepath, \$fileHeader, \$file);
	

	my $r1 = maybeAddInclude(\$file, \$fileHeader, $NetLogWithSource_regEx, $NetLogWithSourceInst_regEx,
    	           '#include "net/log/net_log_with_source.h"',
    	           $incNetLogWithSource_regEx,
    	           $NetLogWithSourceParens_regEx);
	
	my $r2 = maybeAddInclude(\$file, \$fileHeader, $NetLogSource_regEx, $NetLogSourceInst_regEx,
    	           '#include "net/log/net_log_source.h"',
    	           $incNetLogSource_regEx,
    	           $NetLogSourceParens_regEx);
    
    my $r3 = maybeAddInclude(\$file, \$fileHeader, $NetLogEntry_regEx, $NetLogEntryInst_regEx,
                   '#include "net/log/net_log_entry.h"',
                   $incNetLogEntry_regEx);

    my $r4 = maybeAddInclude(\$file, \$fileHeader, $NetLogEntryData_regEx, $NetLogEntryDataInst_regEx,
                   '#include "net/log/net_log_entry.h"',
                   $incNetLogEntry_regEx);
    
    my $r5 = maybeAddInclude(\$file, \$fileHeader, $NetLogParametersCallback_regEx, $NetLogParametersCallbackInst_regEx,
                   '#include "net/log/net_log_parameters_callback_typedef.h"',
                   $incNetLogParametersCallback_regEx);


	if($r1+$r2+$r3+$r4+$r5 > 0) {
		open my $fh, ">", $gFilepath
			or die "can't open $gFilepath: $!";
		print($fh $file);
	} else {
	   #print "$gFilepath\n";
	}

}

sub maybeAddInclude {

    my ($fileRef, $fileHeaderRef, $netLogType_regEx, $netLogTypeInst_regEx,
        $incToAdd, $incToAdd_regEx, $netLogTypeParens_regEx) = @_;
    
    my $forwardRegEx = qr/class\s+$netLogType_regEx;/x;
    
    if( findRegEx($incToAdd_regEx, $fileRef) ) {
        return 0;
    }
    
    if( (findRegEx($netLogType_regEx, $fileRef)) &&
        (noT(findRegEx($forwardRegEx, $fileRef))) ) {           # note: recently changed to not check in $fileHeaderRef...
        
            if ( (noT(findRegEx($netLogTypeInst_regEx, $fileHeaderRef))) &&
                 (noT(findRegEx($incToAdd_regEx, $fileHeaderRef))) ) {  # this is for handling NetLogParametersCallback inc...
                #print "$gFilepath\n";
            
                if(noT(addInclude($fileRef, $incToAdd))) {
                    print "$gFilepath\n";
                    return 0;
                }
                return 1;
            }
    }
                                            # we're seeing a NetLogSource forwarded in header
                                            # and used in .cc file -- add inc here...
    if( (findRegEx($forwardRegEx, $fileHeaderRef)) &&
        (noT(findRegEx($incToAdd_regEx, $fileRef, $fileHeaderRef))) &&
        (checkForRefUsage($fileRef, $fileHeaderRef, $netLogType_regEx)) ) {
        
              if(noT(addInclude($fileRef, $incToAdd))) {
                    print "$gFilepath\n";
                    return 0;
               }
               return 1;
    }
    
    if( defined $netLogTypeParens_regEx ) {
        if( (checkForCallOffParens($fileRef, $netLogTypeParens_regEx, $netLogType_regEx)) &&
            (noT(findRegEx($incToAdd_regEx, $fileRef, $fileHeaderRef))) ) {
        
               if(noT(addInclude($fileRef, $incToAdd))) {
                    print "$gFilepath\n";
                    return 0;
               }
               return 1;
        }
    }
    
    return 0;
}

removeImproperForwards();

recurseFiles("/chromium/src");


#recurseFiles("/chromium2/src/content/browser/download");

#recurseFiles("/chromium/src/net/http");

#our $gFilepath = "/chromium/src/net/http/http_transaction_test_util.cc";
#changeFile();

#$gFilepath = "/chromium/src/components/data_reduction_proxy/core/common/data_reduction_proxy_event_creator.h";
#changeFile();
#$gFilepath = "/chromium/src/components/data_reduction_proxy/core/common/data_reduction_proxy_event_creator.cc";
#changeFile();

#our $gFilepath = "/chromium/src/net/dns/dns_transaction.cc";
#our $gFilepath = "/chromium/src/net/dns/host_resolver_mojo_unittest.cc";
#changeFile();


sub removeImproperForwards {
    
    my %improperForwards;
    $improperForwards{"/chromium/src/net/socket/socks_client_socket.h"} = "class NetLogWithSource;";
    $improperForwards{"/chromium/src/net/socket/socks5_client_socket.h"} = "class NetLogWithSource;";

    for my $filepath ( keys %improperForwards ) {
    
        my $file;
        {
            local $/;
            open my $fh, "<", $filepath;
            $file = <$fh>;
        }
        
        $file =~ s{$improperForwards{$filepath}\n}{};
        
        open my $fh, ">", $filepath;
        print($fh $file);
    }

}


