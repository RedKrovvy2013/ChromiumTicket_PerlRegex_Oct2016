#! /usr/bin/python


from subprocess import Popen, PIPE, STDOUT

cmds = [ "ninja -C out/Default net_unittests",
         "ninja -C out/Default extensions_unittests",
         "ninja -C out/Default components_unittests",
         "ninja -C out/Default content_unittests",
         "ninja -C out/Default device_unittests",
         "ninja -C out/Default remoting_unittests" ]

logString = ""
for fullCmd in cmds:
    logString += "\n\n"
    logString += fullCmd    
    logString += "\n-----------------------------------\n"
    
    cmd = fullCmd.split()
    p = Popen(cmd, stdout=PIPE, stderr=STDOUT, bufsize=1)
    with p.stdout:
        for line in iter(p.stdout.readline, b''):
            print line,  #NOTE: the comma prevents duplicate newlines (softspace hack)
            logString += line
    p.wait()

logfile = open("log.txt", "w")
logfile.write(logString)


    
    
"""
for cmd in cmds:
    p = Popen(cmd, stdout=PIPE, stderr=STDOUT, bufsize=1)
    with p.stdout:
        for line in iter(p.stdout.readline, b''):
            print line,  #NOTE: the comma prevents duplicate newlines (softspace hack)
            logString += line
    p.wait()

logfile = open("log.txt", "w")
logfile.write(logString)



from subprocess import Popen, PIPE, STDOUT

scripts = [ "/Users/michaelcirone/code/C++/practice/foo/main.pl",
            "/Users/michaelcirone/code/C++/practice/foo/main2.pl" ];

for script in scripts:
    p = Popen(script, stdout=PIPE, stderr=STDOUT, bufsize=1)
    with p.stdout, open('logfile', 'ab') as file:
        for line in iter(p.stdout.readline, b''):
            print line,  #NOTE: the comma prevents duplicate newlines (softspace hack)
            file.write(line)
    p.wait()



import sys

logfile = open("out.txt", "w")

output = subprocess.Popen(["/Users/michaelcirone/code/C++/practice/foo/main.pl"],
                        stdout=subprocess.PIPE).communicate()[0]

logfile.write(output)



import sys
import subprocess

logfile = open('logfile', 'w')
proc=subprocess.Popen(["/Users/michaelcirone/code/C++/practice/foo/main.pl"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
for line in proc.stdout:
    sys.stdout.write(line)
    logfile.write(line)
proc.wait()

"""