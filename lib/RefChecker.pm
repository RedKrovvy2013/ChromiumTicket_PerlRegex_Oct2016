use File::Basename "dirname";
use Cwd  "abs_path";
use lib dirname(abs_path $0) . '/lib';


package RefChecker;
use Exporter "import";
 
our @EXPORT = qw(checkForRefUsage $refRegEx);

use NetLogTypeData;    #important: keep enclosed within/underneath package...


our $refRegEx = qr/ (?:(?:(?:\*|&)\s+)|(?:\s+(?:\*|&))) ([a-z0-9_]+)? /x;

sub checkForRefUsage {

    my ($fileRef, $fileHeaderRef, $netLogType) = @_;
    pos($$fileRef) = 0;
    if( defined $$fileHeaderRef ) {
        pos($$fileHeaderRef) = 0;
    }
    
    my %refNames;
    my $netLogTypeRefMatch = qr{ \w+_ptr<$netLogType>\s+([a-z0-9_]+) |
                                 $netLogType $refRegEx }x;
    
    while( $$fileRef =~ m{$netLogTypeRefMatch}xg ) {
        if( (defined $+) && (not exists $refNames{$+}) ) {
            $refNames{$+} = 1;
        }
    }

    if( defined $$fileHeaderRef ) {
        while( $$fileHeaderRef =~ m{$netLogTypeRefMatch}xg ) {
            if( (defined $+) && (not exists $refNames{$+}) ) {
                $refNames{$+} = 1;
            }
        }
    }
    
    if( $netLogType != $NetLogWithSource_regEx ) {
    
        for my $refName ( keys %refNames ) {
            while( $$fileRef =~ m{  " .*? " | // .*? \n |
                                   ( $refName (?: - | \. ) )  }xg ) {
                if( defined $+ ) {
                    return 1;
                }
            }
        }
    } else {
    
        for my $refName ( keys %refNames ) {
            
            while( $$fileRef =~ m{ " .*? " | // .*? \n |
                                   (?: $refName (?: -> | \. ) ) (\w+)\(  }xg ) {
                                
                if( (defined $+) && (exists $NetLogWithSourceFxs{$+}) ) {
                    return 1;
                }
            }
        }
    }
    
    return 0;
}


