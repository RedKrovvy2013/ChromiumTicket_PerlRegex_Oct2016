#!/usr/bin/perl -w

use File::Basename "dirname";
use Cwd  "abs_path";
use lib dirname(abs_path $0) . '/lib';
use GetFileHeader "getFileHeader";
use RefChecker;
use NetLogTypeData;
use Adds;
use NoT;

my $file;
{
    local $/;
    open my $fh, "<", "/chromium/diff_RIAF.txt"
        or die "$!\n";
    $file = <$fh>;
}

my @filepaths;
my $totalFileCount = 0;
while( $file =~ m{(diff.*?)(?=diff --git|$)}gs ) {

    ++$totalFileCount;
    
    my $diffData = $1;
    if( $diffData =~ m{(-\#include\s"net/log/net_log\.h")} ) {
    
        my ($filepath) = $diffData =~ m{ a/(.+) };
        push @filepaths, $filepath;
    }
}
#print "$totalFileCount\n"; #258-ish
#print "$#filepaths\n"; #165-ish

for $filesuffix ( reverse sort @filepaths ) {
    our $gFilepath = "/chromium/src/" . $filesuffix;
    my $file;
    {
        local $/;
        open my $fh, "<", $gFilepath
            or die "$!\n";
        $file = <$fh>;
    }
    
    if( $gFilepath =~ m{ \.h$ }x ) {
        changeH(\$file);
    }
    
    if( $gFilepath =~ m{ \.cc$ }x ) {
        changeCC(\$file);
    }
    
    {
    open my $fh, ">", $gFilepath
        or die "can't open $gFilepath: $!";
    print($fh $file);
    }
}

sub changeH {
    my ($fileRef) = @_;
    
    maybeAddInclude($fileRef, $fileRef, $incNetLogCMode, $incNetLogCMode_regEx, $NetLogCMode_regEx);
    
    maybeAddForward($fileRef, $fileRef, $BaseValueForward, "base", $BaseValue_regEx, $incBaseValue_regEx);
    
    maybeAddForward($fileRef, $fileRef, $BaseDicValueForward, "base", $BaseDicValue_regEx, $incBaseDicValue_regEx);
}

sub changeCC {   
    my ($fileRef) = @_;
    
    my $fileHeader;
    getFileHeader($gFilepath, \$fileHeader, $fileRef);
    
    maybeAddInclude($fileRef, $fileHeaderRef, $incNetLogCMode, $incNetLogCMode_regEx, $NetLogCMode_regEx);
    
    maybeAddForward($fileRef, $fileHeaderRef, $BaseValueForward, "base", $BaseValue_regEx, $incBaseValue_regEx);

    maybeAddForward($fileRef, $fileHeaderRef, $BaseDicValueForward, "base", $BaseDicValue_regEx, $incBaseDicValue_regEx);
}

sub maybeAddInclude {

    my ($fileRef, $fileHeaderRef, $incToAdd, $incRegEx, $cppType_regEx) = @_;
    
    if( (findRegEx($cppType_regEx, $fileRef)) &&
        (noT(findRegEx($incRegEx, $fileRef, $fileHeaderRef))) ) {
        
        print "Adding include to:\n";
        print "$gFilepath\n\n";
    
        if(noT(addInclude($fileRef, $incToAdd))) {
            print "Adding include did not work with:\n";
            print "$gFilepath\n\n";
            return 0;
        }
        return 1;
    }
    return 0;
}

sub maybeAddForward {

    my ($fileRef, $fileHeaderRef, $forwardToAdd, $ns, $cppType_regEx, $incRegEx) = @_;

    if( (findRegEx($cppType_regEx, $fileRef)) &&
        (noT(findRegEx($forwardToAdd, $fileRef, $fileHeaderRef))) &&
        (noT(findRegEx($incRegEx, $fileRef, $fileHeaderRef))) ) {
        
        print "Adding forward to:\n";
        print "$gFilepath\n\n";
    
        if( noT(addForward($fileRef, $ns, $forwardToAdd)) ) {
            print "Adding forward did not work with:\n";
            print "$gFilepath\n\n";
            return 0;
        }
        return 1;
    }
    return 0;
}
    

