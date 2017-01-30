Main files used to complete Chromium [cleanup ticket](https://bugs.chromium.org/p/chromium/issues/detail?id=473710#c20).

[Youtube link](https://www.youtube.com/watch?v=7pnIfbL9V2M) to video explaining project and technical concepts.

Before refactoring references and C++ includes and forwarding across Chromium codebase, manually extracted NetLog inner classes into their own classes and files.

Order of execution for Perl files, which carried out refactoring of references:
* changeNaming.pl
* addIncludes.pl
* removeIncludesAddForwarding.pl
* postRemoveAddIncludes.pl
* addOrForward.pl
