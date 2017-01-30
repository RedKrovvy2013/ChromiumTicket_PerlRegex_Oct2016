package NoFly;
 
use Exporter qw(import);
 
our @EXPORT_OK = qw(isInNoFly);

my %noFlyFiles;
$noFlyFiles{"net_log.h"} = 1;
$noFlyFiles{"net_log.cc"} = 1;
$noFlyFiles{"net_log_with_source.h"} = 1;
$noFlyFiles{"net_log_with_source.cc"} = 1;
$noFlyFiles{"net_log_source.h"} = 1;
$noFlyFiles{"net_log_source.cc"} = 1;
$noFlyFiles{"net_log_entry.h"} = 1;
$noFlyFiles{"net_log_entry.cc"} = 1;
$noFlyFiles{"net_log_parameters_callback_typedef.h"} = 1;

sub isInNoFly {

    my $filepath = $_[0];
    
    $filepath =~ m{ ([^/]+)$ }x;
    
    if( exists $noFlyFiles{$1} ) {
        return 1;
    }
    return 0;
}