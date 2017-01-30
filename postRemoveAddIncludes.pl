#!/usr/bin/perl -w

use File::Basename "dirname";
use Cwd  "abs_path";
use lib dirname(abs_path $0) . '/lib';
use GetFileHeader "getFileHeader";
use RefChecker;
use NetLogTypeData;
use Adds;
use NoT;

my $diffFile;
{
    local $/;
    open my $fh, "<", "/chromium/diff_RIAF.txt"
        or die "$!\n";
    $diffFile = <$fh>;
}

sub postRemoveAddIncludes {

    my ($incRemoved_regEx, $incToAdd, $netLogTypeInst_regEx, $netLogType) = @_;
    my @filepaths;

    while( $diffFile =~ m{(diff.*?)(?=diff --git|$)}gs ) {
    
        my $diffData = $1;
        if( $diffData =~ m{(-$incRemoved_regEx)} ) {
            my ($filepath) = $diffData =~ m{ a/(.+) };
                if( $filepath =~ m{\.h$} ) {
                    push @filepaths, $filepath;
                }
        }
    }
    
    for $filesuffix ( reverse sort @filepaths ) {
        
        $filesuffix =~ m{(.*)\.h$};
        my $filesuffix_prefix = $1;

        my $netLogTypeParens_regEx;
        
        if( $netLogType == $NetLog_regEx ) {
            $netLogTypeParens_regEx = $NetLogParens_regEx;
        }
        if( $netLogType == $NetLogWithSource_regEx ) {
            $netLogTypeParens_regEx = $NetLogWithSourceParens_regEx;
        }
        if( $netLogType == $NetLogSource_regEx ) {
            $netLogTypeParens_regEx = $NetLogSourceParens_regEx;
        }

        
        my $ccFilesuffix = "$filesuffix_prefix.cc";
        our $gFilepath = "/chromium/src/" . $ccFilesuffix;
        
        preChangeFile($incToAdd, $netLogTypeInst_regEx, $netLogType, $netLogTypeParens_regEx, $incRemoved_regEx);

        
        my $unittestFilesuffix = $filesuffix_prefix . "_unittest.cc";
        $gFilepath = "/chromium/src/" . $unittestFilesuffix;
        
        preChangeFile($incToAdd, $netLogTypeInst_regEx, $netLogType, $netLogTypeParens_regEx, $incRemoved_regEx);
    }
}

sub preChangeFile {
    my ($incToAdd, $netLogTypeInst_regEx, $netLogType, $netLogTypeParens_regEx, $incToAdd_regEx) = @_;
    
    if(-f $gFilepath) {
    
        my $file;
        {
            local $/;
            open my $fh, "<", $gFilepath
                or die "$!\n";
            $file = <$fh>;
        }
        my $fileHeader;
        getFileHeader($gFilepath, \$fileHeader, \$file);
        
        if( changeFile(\$file, \$fileHeader, $incToAdd, $netLogTypeInst_regEx, $netLogType,
                       $netLogTypeParens_regEx, $incToAdd_regEx) ) {
            {
            open my $fh, ">", $gFilepath
                or die "can't open $gFilepath: $!";
            print($fh $file);
            }
        }
    }
}

sub changeFile {
    my ($fileRef, $fileHeaderRef, $incToAdd, $netLogTypeInst_regEx, $netLogType, $netLogTypeParens_regEx, $incToAdd_regEx) = @_;
    
    if( noT(findRegEx($incToAdd_regEx, $fileRef)) ) {
        if( (findRegEx($netLogTypeInst_regEx, $fileRef)) ||
            (checkForRefUsage($fileRef, $fileHeaderRef, $netLogType)) ) {
        
            if( noT(addInclude($fileRef, $incToAdd)) ) {
                print "This file was supposed to add include but could not:\n";
                print $gFilepath;
                return 0;
            }
            return 1;
        }
    }
    
    if( defined $netLogTypeParens_regEx ) {
        if( (noT(findRegEx($incToAdd_regEx, $fileRef))) &&
            (checkForCallOffParens($fileRef, $netLogTypeParens_regEx, $netLogType)) ) {
     
            if( noT(addInclude($fileRef, $incToAdd)) ) {
                print "This file was supposed to add include but could not:\n";
                print $gFilepath;
                return 0;
            }
            return 1;        
        }
    }
    
    return 0;
}

postRemoveAddIncludes($incNetLog_regEx, $incNetLog, $NetLogInst_regEx, $NetLog_regEx);

postRemoveAddIncludes($incNetLogWithSource_regEx, $incNetLogWithSource, $NetLogWithSourceInst_regEx, $NetLogWithSource_regEx);

postRemoveAddIncludes($incNetLogSource_regEx, $incNetLogSource, $NetLogSourceInst_regEx, $NetLogSource_regEx);

postRemoveAddIncludes($incNetLogEntry_regEx, $incNetLogEntry, $NetLogEntryInst_regEx, $NetLogEntry_regEx);
    

