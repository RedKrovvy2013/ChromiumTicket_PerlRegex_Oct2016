#!/usr/bin/perl -w

use File::Basename "dirname";
use Cwd  "abs_path";
use lib dirname(abs_path $0) . '/lib';
use NoFly "isInNoFly";
use GetFileHeader "getFileHeader";
use RefChecker;
use NetLogTypeData;
use Adds;
use NoT;

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
    {  local $/;
       open my $fh, "<", $gFilepath
         or die "can't open $gFilepath : $!";
       $file = <$fh>;
    }

    if( $gFilepath =~ m{ \.h$ }x ) {
        changeH(\$file);
    }
    
    if( $gFilepath =~ m{ \.cc$ }x ) {
        changeCC(\$file);              #changeCC needs $gFilepath for opening
                                       #up associated header file
    }
    
    {
        open my $fh, ">", $gFilepath
            or die "can't open $gFilepath: $!";
        print($fh $file);
    }
    
}

sub changeH {
    
    my ($fileRef) = @_;
    
    removeAdd($fileRef, $fileRef, $NetLogForward, $NetLog_regEx, $incNetLog_regEx, $NetLogParens_regEx);
    
    removeAdd($fileRef, $fileRef, $NetLogWithSourceForward, $NetLogWithSource_regEx, $incNetLogWithSource_regEx, $NetLogWithSourceParens_regEx);
    
    removeAdd($fileRef, $fileRef, $NetLogSourceForward, $NetLogSource_regEx, $incNetLogSource_regEx, $NetLogSourceParens_regEx);
    
    removeAdd($fileRef, $fileRef, $NetLogEntryForward, $NetLogEntry_regEx, $incNetLogEntry_regEx);
    
}

sub changeCC {
    
    my ($fileRef) = @_;
    
    my $fileHeader;
    getFileHeader($gFilepath, \$fileHeader, $fileRef);
    
    removeAdd($fileRef, \$fileHeader, $NetLogForward, $NetLog_regEx, $incNetLog_regEx, $NetLogParens_regEx);
    
    removeAdd($fileRef, \$fileHeader, $NetLogWithSourceForward, $NetLogWithSource_regEx, $incNetLogWithSource_regEx, $NetLogWithSourceParens_regEx);
    
    removeAdd($fileRef, \$fileHeader, $NetLogSourceForward, $NetLogSource_regEx, $incNetLogSource_regEx, $NetLogSourceParens_regEx);
    
    removeAdd($fileRef, \$fileHeader, $NetLogEntryForward, $NetLogEntry_regEx, $incNetLogEntry_regEx);
}

sub removeAdd {

    my ($fileRef, $fileHeaderRef, $netLogTypeForward, $netLogType_regEx, $incToRemove_regEx, $netLogTypeParens_regEx) = @_;

    if( $$fileRef !~ m{ $incToRemove_regEx }x ) {
        #print "Skipping, no include found:\n";
        #print "$gFilepath\n\n";
        return;
    }
    
    print "Working on:\n";
    print "$gFilepath\n\n";
    
    my $netLogTypeInst_regEx = qr/ $netLogType_regEx $inst_regEx /x;
    if(  (noT(findRegEx($netLogTypeInst_regEx, $fileRef))) &&             #this currently false-positives for "net::NetLogSource *"
         (noT(checkForRefUsage($fileRef, $fileHeaderRef, $netLogType_regEx)))  ) {
    
        if( (defined $netLogTypeParens_regEx) &&
            (checkForCallOffParens($fileRef, $netLogTypeParens_regEx, $netLogType_regEx)) ) {
            return;
        }
    
        $$fileRef =~ s{ $incToRemove_regEx\n }{}x;
        
        if( noT(checkForNonOverrideRefs($fileRef, $netLogType_regEx)) ) {
            #print "checkForNonOverrideRefs() returned false\n";
            return;
        }
        
        if( $gFilepath =~ m{\.cc$} ) {
          if( defined $$fileHeaderRef ) {
              if ( (findRegEx($netLogTypeForward, $fileHeaderRef)) ||     # .h being processed first
                   (findRegEx($incToRemove_regEx, $fileHeaderRef)) ) {    # makes this code work!
                 return;    
              }
          }
        }
                            # "net" is namespace...
        if(noT(addForward($fileRef, "net", $netLogTypeForward))) {
            print "addForward did not work for:\n";
            print $gFilepath;
        }
    }

}


sub checkForNonOverrideRefs {

    my ($fileRef, $netLogType_regEx) = @_;
    pos($$fileRef) = 0;
    
    my $classesN;
    $classesN = qr{ (?> [^{}]+ | \{ (??{ $classesN }) \}\s*;? )* }xs;
    my $bracketsN;
    $bracketsN = qr{ (?> [^{}]+ | \{ (??{ $bracketsN }) \} )* }xs;
    my $parensN;
    $parensN = qr{ (?> [^()]+ | \( (??{ $parensN }) \) )* }xs;
    
    our %notDefineds;
    my $loopNo = 0;
    while( $$fileRef =~ m{  (") .*? " | (//) .*? \n    |
                            ((?:class|struct)\s+\w+;)    (?{print "class forward fx\n"})  |
                            ((?:class|struct)\s+)\w+ .*?(?=\{)         (?{print "class def\n"})  |
                            ( \w+::\w+ \( (??{$parensN}) \) ) .*? \{ (??{$bracketsN}) \}     (?{print "method def\n"})  |  
                            ( (?<=\n) \w+ ) \( (??{$parensN}) \) .*? \{ (??{$bracketsN}) \}       (?{print "macro fx\n"})  | 
                            ( [^\s]+? (?:(?:\s(?<!\n))+[^\s:]+)+ \( (??{$parensN}) \) ) .*? (?=(?:\{|;))  (?{print "anon-ns fx\n"})  }xsg ) {
                                                    #currently cuts off ns via ^:, but seems benign
                                     #TODO: handle where return value is on line above method name... e.g.-sdch_net_log_params.h
        
        $matchHook = $+;
        
        if( not defined $+ ) {
            if( not exists $notDefineds{$gFilepath} ) {
                $notDefineds{$gFilepath} = 1;
            }
        }

        ++$loopNo;
        if($loopNo > 2500) {
            print "This file's loopNo went to high\n";
            print "$gFilepath\n\n";
            last;
        }

        #print " checkForNonOverrideRefs";

        if( $matchHook =~ m{ \G (?:"|//) }x ) {
            next;
        }
        
        #print "$matchHook\n\n\n";

        if( $matchHook =~ m/class\s+\w+;|struct\s+\w+;/ ) {
            next;
        }

        if( $matchHook =~ m[\G(?:class |struct )] ) {                   # in derived class definition
            
            #print "$matchHook\n\n\n";
            #print "inside class match!\n\n\n";
            
            $$fileRef =~ m{ .*? (\{ (??{$classesN}) \};) }xgs;
            if( not defined pos($$fileRef) ) {
                print "($gFilepath)\nUh-oh, 'in derived class definition block' faulted!\n\n";
                last;
            }
            my $classData = $1;
            
            while( $classData =~ m{ (") .*? " | (//) .*? \n  |
                                    ( (?:(?:\s(?<!\n))+\S+)+
                                      \( (??{$parensN}) \)
                                         )                      }xsg ) {
                if( $+ =~ m{ " | // }x ) {
                    next;
                }
                #print "$+\n\n\n";
                                #TODO: have this handle *_ptrs
                if( ($+ =~ m/$netLogType_regEx $refRegEx/x)  &&
                    ($classData !~ m{(?=\G\s*override)}) ) {
                  return 1;
                }
                $classData =~ m{ .*?; | .*? \{ (??{$bracketsN}) \} }xsg; # now past param section;  
                                                                         # just iterate past fx code block
                                                                         # or ";" if just fx declaration
                if( not defined pos($classData) ) {
                    print "($gFilepath)\nUh-oh, class method did not end with ; or brackets!\n\n";
                    last;
                }
            }
            next;
        }
        
        #print "$matchHook\n\n\n";
        
        if( $matchHook =~ m{\w+::\w+\(} ) {
            #print "nexting cuz matched a method definition\n\n";
            next;               # do not check inside of class method definitions, to avoid false-positiving
        }
        
        if( $matchHook !~ m/[a-z]/ ) {
            #print "mackaroo capture found and jumped!\n";
            next;               # we are in a macro/test macro; jump past..
        }
        
        #last block reached, which should only match anon-ns functions;
        #method definitions should be skipped...
        
        #TODO: have this handle *_ptrs
        #TODO: parse out comments, quotations
        if( $matchHook =~ m/$netLogType_regEx $refRegEx/x ) {
            #print "found \$netLogType_regEx in a macro/anon-ns fx\n";
            return 1;
        }
        
        if( $$fileRef =~ m[ \G\{ ]x )  {
            #print "found anon-ns, now skipping past its block\n\n";
            $$fileRef =~ m[ \{ (??{$bracketsN}) \} ]xgs;
        }
    }
    return 0;
}

recurseFiles("/chromium/src");


#recurseFiles("/chromium2/src/content/browser/download");

#recurseFiles("/chromium/src/net");
#recurseFiles("/chromium/src/extensions/browser/api/web_request");
#changeFile("/chromium/src/content/browser/loader/netlog_observer.h");
#changeFile("/chromium/src/net/quic/chromium/quic_stream_factory.cc");
#changeFile("/Users/michaelcirone/code/Projects/Chromium/inner classes extraction 2/test/download_browsertest.cc");


#our $gFilepath = "/chromium/src/net/proxy/proxy_list.h";
#our $gFilepath = "/chromium/src/net/disk_cache/net_log_parameters.h";
#our $gFilepath = "/chromium/src/net/http/http_auth_handler_negotiate.cc";
#our $gFilepath = "/chromium/src/content/browser/download/download_browsertest.cc";
#our $gFilepath = "/chromium/src/net/disk_cache/net_log_parameters.h";
#our $gFilepath = "/chromium/src/net/base/sdch_net_log_params.h";
#our $gFilepath = "/chromium/src/net/socket/socket_net_log_params.h";
#our $gFilepath = "/chromium/src/net/cert/ct_policy_enforcer.cc";
#our $gFilepath = "/Users/michaelcirone/code/Projects/Chromium/inner classes extraction 2/test/download_browsertest.cc";
#changeFile();


if( keys %notDefineds > 0 ) {
    print "These are files where checkForNonoverrideRefs fx wasn't capturing:\n\n";
    for my $file ( keys %notDefineds ) {
        print "$file\n";
    }
}

