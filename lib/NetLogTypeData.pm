package NetLogTypeData;

use base qw(Exporter);

our @EXPORT = qw($NetLog_regEx $NetLogWithSource_regEx $NetLogSource_regEx $NetLogEntry_regEx $NetLogEntryData_regEx $NetLogTSObs_regEx $NetLogParametersCallback_regEx $NetLogCMode_regEx $BaseValue_regEx $BaseDicValue_regEx
                 $NetLogInst_regEx $NetLogWithSourceInst_regEx $NetLogSourceInst_regEx $NetLogEntryInst_regEx $NetLogEntryDataInst_regEx $NetLogTSObsInst_regEx $NetLogParametersCallbackInst_regEx
                 $incNetLog_regEx $incNetLogWithSource_regEx $incNetLogSource_regEx $incNetLogEntry_regEx $incNetLogParametersCallback_regEx $incNetLogCMode_regEx $incBaseValue_regEx $incBaseDicValue_regEx
                 $NetLogForward $NetLogWithSourceForward $NetLogSourceForward $NetLogEntryForward $NetLogEntryDataForward $BaseValueForward $BaseDicValueForward
                 $incNetLog $incNetLogWithSource $incNetLogSource $incNetLogEntry $incNetLogCMode
                 $inst_regEx
                 $NetLogParens_regEx $NetLogWithSourceParens_regEx $NetLogSourceParens_regEx
                 findRegEx checkForCallOffParens
                 %NetLogFxs %NetLogWithSourceFxs %NetLogSourceFxs);


our $inst_regEx = qr/ (?: \s | \( | :: )/x;


our $NetLog_regEx = qr/(?<!\w)NetLog(?!\w)/x;
our $NetLogInst_regEx = qr/ $NetLog_regEx $inst_regEx /x;

our $NetLogForward = "class NetLog;";

our $incNetLog_regEx = qr{\#include\s+"net/log/net_log\.h"}x;
our $incNetLog = '#include "net/log/net_log.h"';


our $NetLogWithSource_regEx = qr/(?<!\w)NetLogWithSource(?!\w)/x;
our $NetLogWithSourceInst_regEx = qr/ $NetLogWithSource_regEx $inst_regEx /x;

our $NetLogWithSourceForward = "class NetLogWithSource;";

our $incNetLogWithSource_regEx = qr{\#include\s+"net/log/net_log_with_source\.h"}x;
our $incNetLogWithSource = '#include "net/log/net_log_with_source.h"';


our $NetLogSource_regEx = qr/(?<!\w)NetLogSource(?!\w)/x;           
our $NetLogSourceInst_regEx = qr/ $NetLogSource_regEx $inst_regEx /x;

our $NetLogSourceForward = "struct NetLogSource;";   
    
our $incNetLogSource_regEx = qr{\#include\s+"net/log/net_log_source\.h"}x;
our $incNetLogSource = '#include "net/log/net_log_source.h"';

    
our $NetLogEntry_regEx = qr/(?<!\w)NetLogEntry(?!\w)/x;           
our $NetLogEntryInst_regEx = qr/ $NetLogEntry_regEx $inst_regEx /x;

our $NetLogEntryForward = "class NetLogEntry;";

our $incNetLogEntry_regEx = qr{\#include\s+"net/log/net_log_entry\.h"}x;
our $incNetLogEntry = '#include "net/log/net_log_entry.h"';


our $NetLogEntryData_regEx = qr/(?<!\w)NetLogEntryData(?!\w)/x;           
our $NetLogEntryDataInst_regEx = qr/ $NetLogEntry_regEx $inst_regEx /x;

our $NetLogEntryDataForward = "struct NetLogEntryData;";


our $NetLogTSObs_regEx = qr/(?<!\w)ThreadSafeObserver(?!\w)/x;
our $NetLogTSObsInst_regEx = qr/ $NetLogTSObs_regEx $inst_regEx /x;


our $NetLogParametersCallback_regEx = qr/(?<!\w)NetLogParametersCallback(?!\w)/x;
our $NetLogParametersCallbackInst_regEx = qr/ $NetLogParametersCallback_regEx $inst_regEx /x;

our $incNetLogParametersCallback_regEx = qr{\#include\s+"net/log/net_log_parameters_callback_typedef.h"}x;


our $NetLogCMode_regEx = qr/(?<!\w)NetLogCaptureMode(?!\w)/x;

our $incNetLogCMode_regEx = qr{\#include\s+"net/log/net_log_capture_mode\.h"}x;
our $incNetLogCMode = '#include "net/log/net_log_capture_mode.h"';


our $BaseValue_regEx = qr/(?<!\w)Value(?!\w)/x;
our $BaseValueForward = "class  Value;";
our $incBaseValue_regEx = qr{\#include\s+"base/values\.h"}x;

our $BaseDicValue_regEx = qr/(?<!\w)DictionaryValue(?!\w)/x;
our $BaseDicValueForward = "class  DictionaryValue;";
our $incBaseDicValue_regEx = qr{\#include\s+"base/values\.h"}x;


our $NetLogParens_regEx = qr{net(?:_)?log\(\)}ixs;
our $NetLogWithSourceParens_regEx = qr{net(?:_)?log\(\)}ixs;
our $NetLogSourceParens_regEx = qr{source\(\)}ixs;


sub findRegEx {

    my $regEx = $_[0];
    # rest of params are file refs...
    
    my $i = 0;
    for my $fileRef ( @_ ) {
        if( $i==0 ) {
            ++$i;
            next;
        }
        if( defined $$fileRef ) {
            pos($$fileRef) = 0;
            while( $$fileRef =~ m{ // .*? \n | " .*? " |
                                   ($regEx) }gx ) {
                #print " findRegEx";
                if (defined $1) {
                    pos($$fileRef) = 0;
                    return 1;
                }    
            }
        }
        ++$i;
    }
    return 0;
}


sub checkForCallOffParens {
    
    my ($fileRef, $netLogTypeParens_regEx, $netLogType_regEx) = @_;
    pos($$fileRef) = 0;
    
    my %fxs;
    if( $netLogType_regEx == $NetLog_regEx ) {
        %fxs = %NetLogFxs;
    }
    if( $netLogType_regEx == $NetLogWithSource_regEx ) {
        %fxs = %NetLogWithSourceFxs;
    }
    if( $netLogType_regEx == $NetLogSource_regEx ) {
        %fxs = %NetLogSourceFxs;
    }
    
    while( $$fileRef =~ m{ $netLogTypeParens_regEx (?: \.|-> ) (\w+) \( }xisg ) {
        if( exists($fxs{$+}) ) {
            return 1;
        }
    }
    return 0;
}


our %NetLogFxs;

$NetLogFxs{"AddGlobalEntry"} = 1;
$NetLogFxs{"NextID"} = 1;
$NetLogFxs{"IsCapturing"} = 1;
$NetLogFxs{"DeprecatedAddObserver"} = 1;
$NetLogFxs{"SetObserverCaptureMode"} = 1;
$NetLogFxs{"DeprecatedRemoveObserver"} = 1;
$NetLogFxs{"TickCountToString"} = 1;
$NetLogFxs{"EventTypeToString"} = 1;
$NetLogFxs{"GetEventTypesAsValue"} = 1;
$NetLogFxs{"SourceTypeToString"} = 1;
$NetLogFxs{"GetSourceTypesAsValue"} = 1;
$NetLogFxs{"EventPhaseToString"} = 1;
$NetLogFxs{"BoolCallback"} = 1;
$NetLogFxs{"IntCallback"} = 1;
$NetLogFxs{"Int64Callback"} = 1;
$NetLogFxs{"StringCallback"} = 1;


our %NetLogWithSourceFxs;

$NetLogWithSourceFxs{"AddEntry"} = 1;
$NetLogWithSourceFxs{"BeginEvent"} = 1;
$NetLogWithSourceFxs{"EndEvent"} = 1;
$NetLogWithSourceFxs{"AddEvent"} = 1;
$NetLogWithSourceFxs{"AddEventWithNetErrorCode"} = 1;
$NetLogWithSourceFxs{"EndEventWithNetErrorCode"} = 1;
$NetLogWithSourceFxs{"AddByteTransferEvent"} = 1;
$NetLogWithSourceFxs{"IsCapturing"} = 1;
$NetLogWithSourceFxs{"Make"} = 1;
$NetLogWithSourceFxs{"source"} = 1;
$NetLogWithSourceFxs{"net_log"} = 1;
$NetLogWithSourceFxs{"CrashIfInvalid"} = 1;


our %NetLogSourceFxs;

$NetLogSourceFxs{"AddToEventParameters"} = 1;
$NetLogSourceFxs{"ToEventParametersCallback"} = 1;
$NetLogSourceFxs{"FromEventParameters"} = 1;

