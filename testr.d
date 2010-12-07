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
    string defaultReportDir = "testreports";
    string[] include;
    string[] exclude;
    bool nomain = false;
    bool flat = false;
    bool help = false;
    bool coverage;
    bool report = false; //todo
    string reportDir;    //todo

    void printHelp()
    {
        writeln("D unittest runner. Usage: testr [options] [dmdoptions]");
        writeln();
        writeln("  -i, --include <path>      .d file or directory to scan for, defaults to");
        writeln("                            the current directory");
        writeln("  -n, --nomain              do not link in a main entry point");
        writeln("  -e, --exclude <pattern>   pattern to exclude modules, enquote to prevent");
        writeln("                            shell expansion");
        writeln("  -f, --flat                directories are recursively scanned by default, ");
        writeln("                            this option will prevent it");
        writeln();
        writeln("Every module found will be unittested, options not recognized will be passed ");
        writeln("to (r)dmd. The exit code of testr is the number of tests that have failed.");
    }

    try getopt(args,
               std.getopt.config.passThrough,
               "include|i", &include,
               "exclude|e", &exclude,
               "nomain|n", &nomain,
               "flat|f", &flat,
               "help|h", &help,
               "coverage|cc", &coverage,
               "report|r", &report
               "reportdir|rd", &reportDir);
    catch(Exception ex)
    {
        writeln(ex);
        printHelp();
        return 1;
    }

    if (help)
    {
        printHelp();
        return 0;
    }

    args = args[1..$];
    if (!include) include ~= ".";
    if (report)
    {
        if (!reportDir)
        {
            reportDir = defaultReportDir;
        }
    }
    else if (reportDir)
    {
        report = true;
    }

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
                if (filepath.isfile() && filepath.getExt() == "d")
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

    string[] modules = findModules(include);
    
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

    string cmd = "rdmd -unittest ";
    if (!nomain) cmd ~= "--main ";
    if (coverage) cmd ~= " -cov ";
    cmd ~= std.string.join(args, " ") ~ " ";
    
    executeTests(modules, cmd);

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
