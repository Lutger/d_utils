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

   -i, --include <path>      .d file or directory to unittest, defaults to the current directory
   -n, --nomain  <path>      same as above, except that these contain a main entry
   -e, --exclude <pattern>   pattern to exclude modules, enquote to prevent shell expansion
   -f, --flat                directories are recursively scanned by default, this option will prevent it

Every module found will be unittested, options not recognized will be passed to (r)dmd.
</pre>
