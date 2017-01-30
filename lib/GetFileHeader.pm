package GetFileHeader;
 
use Exporter "import";
 
our @EXPORT_OK = "getFileHeader";


sub getFileHeader {

    my $filepath = $_[0];
    my $fileHeaderRef = $_[1];   #to be written to
    my $fileRef = $_[2];         #to be checked against
    
    {
      local $/;
      if( ($filepath =~ m{ ^(.+)\.cc$ }x) && (-f "$1.h") ) { 
          #print "opening header file for:\n$filepath\n";
          open my $fh, "<", "$1.h";
          $$fileHeaderRef = <$fh>;
      }
      if( ($filepath =~ m{ ^(.+)_unittest\.cc$ }x)     &&
          (-f "$1.h")                                  &&
          (checkUnitTestHasInclude("$1.h", $fileRef))
            ) {
                  #print "opening header file for:\n$filepath\n";
                  open my $fh, "<", "$1.h";
                  $$fileHeaderRef = <$fh>;
      }
    }
    
}

sub checkUnitTestHasInclude {

    my ($headerFilepath, $fileRef) = @_;
    
    my ($includepath) = $headerFilepath =~ m{/chromium/src/(.*)};
    
    my $include = '#include "' . $includepath . '"';
    
    if( $$fileRef =~ m/$include/ ) {
        #print "Just found header include in unittest file that is assoc with:\n";
        #print "$headerFilepath\n\n";
        return 1;
    }
    #print "Did not find header include in unittest file that is assoc with:\n";
    #print "$headerFilepath\n\n";
    return 0;
}