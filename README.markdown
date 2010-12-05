Scripts and utilities for D
================================
A couple of things for the D programming language

d-completion.sh
--------------------------------
This enables bash completion for the dmd compiler and rdmd. To use it, the *bash-completion* package must have been installed. To try it out, run the script:
    . d-completion.sh
Now options to dmd and rdmd should be autocompleted by hitting the tab key. To enable completion without invoking the script everytime, copy it to some directory of choice and run it from .bashrc. For example if you install it as ~/bin/d-completion.sh add the following lines to ~/.bashrc:
    . ~/bin/d-completion.sh

For more information on making your own bash completion scripts, this is a handy tutorial: 
[introduction to bash completion](http://www.debian-administration.org/article/An_introduction_to_bash_completion_part_1)


shBrushD.js 
--------------------------------
Brush for the [syntaxhighlighter](http://alexgorbatchev.com/SyntaxHighlighter/) javascript library. See shBrushD.html for an example.


testr.d
--------------------------------
A simple unittest runner that recursively scans a directory for .d files to unittest.

<pre>
D unittest runner. Usage: testr [options] [dmdoptions]

  -i, --include <path>      .d file or directory to scan for, defaults to
                            the current directory
  -n, --nomain              do not link in a main entry point
  -e, --exclude <pattern>   pattern to exclude modules, enquote to prevent
                            shell expansion
  -f, --flat                directories are recursively scanned by default,
                            this option will prevent it

Every module found will be unittested, options not recognized will be passed
to (r)dmd. The exit code of testr is the number of tests that have failed.
</pre>


traceviewer.d
--------------------------------
This tool can create an html page from the trace.log file produced by the builtin dmd profile. It will demangle the symbols found, and tries to make a
more readable html page from the trace log. All symbols are hyperlinked for easy navigation. At the moment, you have to feed a trace.log file to it
through stdin, and the html will be returned through stdout. Demangling is done with core.demangle.