package Adds;

use base "Exporter";

our @EXPORT = qw(addForwards addForward addIncludes addInclude);


sub addForwards {
    
    my $fileRef = $_[0];
    my @forwards = @{$_[1]};
    
    for $forward ( @forwards ) {

        my ($ns) = $forward =~ m{(\w+)};
        my ($forwardText) = $forward =~ m[ { (.*) } ]x;

        addForward($fileRef, $ns, $forwardText);
    }  
}

sub addForward {

    my ($fileRef, $ns, $forwardText) = @_;
    
    if ( not $$fileRef =~ s{ ( namespace \s+ $ns \s* \{ \n
                               (?: \s*class\s+\w+\s*;\n )+ )
                           }{$1$forwardText\n}x
                       ) {
    
        #TODO: solve for when there are random includes later on in the file...
        if ( not $$fileRef =~ s{ ( (?:\#include .+? \n)+
                                   (?:\#endif\n\n)?
                                   #(?: .*? (?>using.*?;)+ \n\n )?
                                     ) (?!.*\#include) }
                               {$1namespace $ns \{\n\n$forwardText\n\n\}  // namespace $ns\n\n}sx) {
            return 0;
        }
    }
    
    return 1;
}

sub addIncludes {

    my $fileRef = $_[0];
    my @includes = @{$_[1]};
    
    for $include ( @includes ) {

        addInclude($fileRef, $include);
    }  
}

sub addInclude {

    my ($fileRef, $incToAdd) = @_;

    if( not $$fileRef =~ s{ ( (?:\#include.+?"\n\n)? 
                             (?:\#include.+?>\n\n)?    
                             (?:\#include.+?"\n(?=\n)) ) }
                          {$1$incToAdd\n}sx ) {
        
        if( not $$fileRef =~ s{ ( \#include.+?\n ) }{$1$incToAdd\n}sx ) {
            return 0;
        }
    }
    return 1;
}