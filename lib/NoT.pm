package NoT;

use base qw(Exporter);

our @EXPORT = qw(noT);


sub noT {
    
    my ($bool) = @_;
    
    if( $bool ) {
        return 0;
    } else {
        return 1;
    }
}