/** A script for running unittests
 * 
 * Author: Lutger Blijdestijn
 *
 * Website: https://github.com/Lutger/d_utils
 *
 * Written in the D programming language
 */
module testr;
import std.algorithm;
import std.stdio;
import std.file;
import std.path;
import std.conv;
import std.process;
import std.string;
import std.traits;
import std.getopt;
import std.array;

int main(string[] args)
{
    string[] include;
    string[] exclude;
    string[] nomain;
    bool flat = false;
    bool help = false;

    void printHelp()
    {
        writeln("D unittest runner. Usage: testr [options] [dmdoptions]");
        writeln();
        writeln("   -i, --include <path>      .d file or directory to unittest, defaults to the current directory");
        writeln("   -n, --nomain  <path>      same as above, except that for these modules a main entry point will not be linked in");
        writeln("   -e, --exclude <pattern>   pattern to exclude modules, enquote to prevent shell expansion");
        writeln("   -f, --flat                directories are recursively scanned by default, this option will prevent it");
        writeln();
        writeln("Every module found will be unittested, options not recognized will be passed to (r)dmd.");
    }

    try getopt(args,
               std.getopt.config.passThrough,
               "include|i", &include,
               "exclude|e", &exclude,
               "nomain|n", &nomain,
               "flat|f", &flat,
               "help|h", &help);
    catch(Exception ex)
    {
        printHelp();
        return 1;
    }

    if (help)
    {
        printHelp();
        return 0;
    }

    args = args[1..$];

    string[] modules;
    string[] modulesWithMain;

    if (include.length + modulesWithMain.length == 0)
        include ~= ".";

    bool isExcluded(string filepath)
    {
        foreach( exclusion; exclude )
            if (std.path.fnmatch(filepath, exclusion))
                return true;
        return false;
    }

    string[] findModules(string[] paths)
    {
        string result[];
        
        foreach(filepath; paths)
        {
            if (filepath.exists() && !isExcluded(filepath) )
            {
                if (filepath.isfile() && filepath.getExt() == ".d")
                {
                    result ~= filepath;
                }
                else if(filepath.isdir())
                {
                    foreach( string f; glob(filepath ~ sep ~ "*.d", flat ? SpanMode.shallow : SpanMode.depth) )
                        if ( !isExcluded(f) )
                            result ~= f;
                }
            }
        }
        return result;
        
    }

    modules ~= findModules(include);
    modulesWithMain ~= findModules(nomain);

    int numTested;
    string[] failedModules;

    void executeTests(string[] filepaths, string cmd)
    {
        foreach(filepath; filepaths)
        {
            numTested++;
            auto cmdline = cmd ~ " " ~ filepath;
            writefln("testing: %s ( %s )", filepath, cmdline);
            if ( system(cmdline) )
            {
                failedModules ~= filepath;
                writeln("...failed");
            }
            else
                writeln("...passed");
            writeln();
        }
    }
    
    executeTests(modules, "rdmd --main -unittest " ~ std.string.join(args, " "));
    executeTests(modulesWithMain, "rdmd -unittest " ~ std.string.join(args, " "));

    if ( failedModules.length )
    {
        writefln("failures: (%s of %s)", failedModules.length, numTested);
        writeln( failedModules.join(linesep) );
    }
    return failedModules.length;
}

/***/
GlobIterator glob(string path, SpanMode mode)
{
    GlobIterator result;
    result.dirIter = dirEntries(dirname(path), mode);
    result.pattern = basename(path);
    return result;
}

/***/
struct GlobIterator
{
    DirIterator dirIter;
    string pattern;

    int opApply(D)(scope D dg)
    {
        alias ParameterTypeTuple!dg Params;

        foreach(Params[0] path; dirIter)
        {
            int stop = 0;
            static if ( is ( Params[0] == string))
            {
                if ( fnmatch(path.basename(), pattern) )
                    stop = dg(path);
            }
            else static if ( is ( Params[0] == DirEntry) )
            {
                if ( fnmatch(path.name.basename(), pattern) )
                    stop = dg(path);
            }
            else
            {
                static assert(false, "Dunno how to enumerate directory entries"
                          " against type " ~ Params[0].stringof);
            }

        }
        return 0;
    }
}
