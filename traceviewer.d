module traceviewer;

import std.stdio;
import std.string;
import std.algorithm;
import std.typecons;
import std.conv;
import core.demangle;
import std.exception;
import std.array;
import std.path;
import std.getopt;

struct CallGraphCall
{
    string symbol;
    int calls;
    long tree;
    long func;
    Tuple!(int, string)[] fanIn;
    Tuple!(int, string)[] fanOut;
}

struct Timing
{
    string symbol;
    int numCalls;
    long tree;
    long func;
    long call;
}

void main(string[] args)
{
    bool help = false;
    getopt(args, "help|h", &help);
    if (help)
    {
        writeln("traceviewer takes input from stdin and prints its work to stdout. "
                "It can only understand a valid trace.log file as produced by dmd where no multiple runs have been been merged in.");
        return;
    }

    
    CallGraphCall[string] callGraph;
    Timing[] timings;
    long ticksPerSecond;

    CallGraphCall parseCallGraphCall(R)(R lines)
    {
        CallGraphCall result;
        while( !lines.empty ) 
        {
            auto line = lines.front();

            if (!line.length || line.startsWith('-') || line.startsWith('='))
                break;

            if (line.startsWith('\t') )
            {
                Tuple!(int, string) fan;
                line.munch(whitespace);
                fan[0] = to!int(line.munch(digits));
                line.munch(whitespace);
                fan[1] = line.demangle().idup;
                if (result.calls) result.fanOut ~= fan;
                else result.fanIn ~= fan;
            }
            else
            {
                enforce( line.startsWith('_') );
                auto callParts = line.split();
                enforce( callParts.length == 4);
                result.symbol = callParts[0].demangle().idup;
                result.calls = to!int(callParts[1]);
                result.tree = to!long(callParts[2]);
                result.func = to!long(callParts[3]);
            }
            lines.popFront();
        }
        return result;
    }

    void parseCallGraph(R)(ref R lines)
    {
        while( !lines.empty && lines.front.length) 
        {
            auto line = lines.front;
            if (line.startsWith('=') )
                break;

            if (line.startsWith('-'))
            {
                lines.popFront();
                auto cfg = parseCallGraphCall(lines);
                callGraph[cfg.symbol] = cfg;
            }
            else
                lines.popFront();
        }
    }

    auto lines = stdin.byLine();
    parseCallGraph( lines );
    auto line = lines.front();
    enforce( line.startsWith('='));
    line.munch("^" ~ digits);
    ticksPerSecond = to!long( line.munch(digits) );
    lines.popFront();
    while( !lines.empty )
    {
        line = lines.front();
        line = line.stripl();
        if (line.munch(digits).length)
            break;
        lines.popFront();
    }
    while( !lines.empty && lines.front.length )
    {
        auto parts = lines.front().split();
        enforce( parts.length == 5 );
        Timing timing;
        timing.numCalls = to!int( parts[0] );
        timing.tree = to!long( parts[1] );
        timing.func = to!long( parts[2] );
        timing.call = to!long( parts[3] );
        timing.symbol = parts[4].demangle.idup;
        timings ~= timing;
        lines.popFront();
    }
    writeln( toHtml(timings, callGraph));
}

class XmlNode
{
    static string istr = "  ";
    
    this()
    {
        
    }
    
    this(string text)
    {
        this.text = text;
    }

    void writeTo(ref Appender!string buf, int ident)
    {
        buf.put(istr.repeat(ident));
        buf.put(this.text);
        buf.put(linesep);
    }

    string text;

    protected:
        XmlNode[] children;
}

class XmlElement : XmlNode
{
    override void writeTo(ref Appender!string buf, int ident)
    {
        buf.put(istr.repeat(ident));
        buf.put("<");
        buf.put(this.name);
        foreach( k,v; this.attributes )
        {
            buf.put(" ");
            buf.put(k);
            buf.put("=\"");
            buf.put(v);
            buf.put("\"");
        }
        buf.put(">");
        if (this.children)
        {
            buf.put(linesep);
            foreach(XmlNode child; super.children)
                child.writeTo(buf, ident + 1);
            buf.put(istr.repeat(ident));
        }
        buf.put("</");
        buf.put(this.name);
        buf.put(">");
        buf.put(linesep);
    }

    this(string elementName)
    {
        this.name = elementName;
    }
    
    XmlElement opDispatch(string element, T)(T attributes, string text = "")
        if ( is(T == string[string] ) )
    {
        auto result = new XmlElement(element);
        result.attributes = attributes;
        if (text)
            result.text = text;
        this.children ~= result;
        return result;
    }

    XmlElement opDispatch(string element, T)(T text)
        if (!is(T == string[string]))
    {
        auto result = new XmlElement(element);
        result.text = to!string(text);
        this.children ~= result;
        return result;
    }

    XmlElement opDispatch(string element)()
    {
        auto result = new XmlElement(element);
        this.children ~= result;
        return result;
    }

    XmlElement opDispatch(string element, E, D)( E[] r, D callBack)
        if ( !is(E == string[string] ) )
    {
        foreach( e; r )
        {
            auto ele = new XmlElement(element);
            callBack(ele, e);
            this.children ~= ele;
        }
        return this;
    }

    void text(string text)
    {
        if (text.length)
            this.children ~= new XmlNode(text);
    }

    string name;
    string[string] attributes;
}

string toHtml(Timing[] timings, CallGraphCall[string] callGraph)
{
    auto calls = callGraph.values;

    auto root = new XmlElement("html");
    
    root.head.style(css);
    auto html = root.opDispatch!"body"();

    void initFanNode(XmlElement node, Tuple!(int, string) fanCall)
    {
        node.attributes = [ "Symbol" : fanCall[1], "NumCalls" : to!string(fanCall[0]) ];
    }

    void initFan(XmlElement f, Tuple!(int, string) fan)
    {
        auto sym = to!string(fan[1]);
        f.span(["class" : "calls"], to!string(fan[0]) ) ;
        f.span(["class" : "symbol"])
        .a(["href" : "#" ~ sym.replace(" ", "_")], sym );
    }    

    auto callGraphSection =  html.section(["class" :"callgraph"]);
    callGraphSection.opDispatch!("h1")( "CallGraph");
    callGraphSection.section( calls, (XmlElement node, CallGraphCall cfg) {
            node.attributes = [ "class" : "call" ];
            
            auto dl = node.dl();
            dl.dt("function")
              .dd
              .a(["name": cfg.symbol.replace(" ", "_"),
                  "href" : "#T" ~ cfg.symbol.replace(" ", "_")],
                 cfg.symbol, );
            dl.dt("times called").dd(cfg.calls);
            dl.dt("tree time").dd(cfg.tree);
            dl.dt("function time").dd(cfg.func);
            node.ul(["class" : "fan_in"]).li(cfg.fanIn, &initFan);
            node.ul(["class" : "fan_out"]).li(cfg.fanOut, &initFan);
        });

    auto timingsSection = html.section(["class":"timings"]);
    timingsSection.opDispatch!("h1")("Table of timings");
    auto table = timingsSection.table;
    auto header = table.tr;
    
    header.th("calls");
    header.th("tree");
    header.th("func");
    header.th("per call");
    header.th("Symbol");

    table.tr( timings, (XmlElement node, Timing t) {
        node.td(t.numCalls);
        node.td(t.tree);
        node.td(t.func);
        node.td(t.call);
        node.td.a(["name" : "T" ~ t.symbol.replace(" ", "_"), "href" : "#" ~ t.symbol.replace(" ", "_")], t.symbol);
    });

    Appender!string buf;
    root.writeTo(buf,0);
    return buf.data;
}

string toXml(Timing[] timings, CallGraphCall[string] callGraph)
{
    auto xml = new XmlElement("TraceLog");
    auto calls = callGraph.values;

    void initFanNode(XmlElement node, Tuple!(int, string) fanCall)
    {
        node.attributes = [ "Symbol" : fanCall[1], "NumCalls" : to!string(fanCall[0]) ];
    }

    xml.CallGraph()
       .FunctionCall( calls, (XmlElement node, CallGraphCall cfg) {
            node.attributes = [
                "Symbol" : cfg.symbol,
                "Tree" : to!string(cfg.tree),
                "NumCalls" : to!string(cfg.calls),
                "Func" : to!string(cfg.func)
            ];
            node.FanIn( cfg.fanIn, &initFanNode );
            node.FanOut( cfg.fanOut, &initFanNode );
        });

    xml.Timings
       .FunctionCall( timings, (XmlElement node, Timing timing)
        {
            node.attributes = [
                "Symbol" : timing.symbol,
                "NumCalls" : to!string(timing.numCalls),
                "Tree" : to!string(timing.tree),
                "Func" : to!string(timing.func),
                "Call" : to!string(timing.call)
            ];
        });

    Appender!string buf;
    xml.writeTo(buf,0);
    return buf.data;
}

enum css = q"CSS

* {
    margin: 0;
    padding: 0;
}

h1 {
    margin: 1em;
}

a {
    text-decoration:none;
    color:black;
}

section {
    display:block;
}

section.callgraph,
section.timings {
    margin:2em 0em;
    padding-bottom: 2em 2em;
}

section.timings table  {
    text-align:left;
    border-top: dotted lightgrey;
    border-spacing: 9px;
}

section.timings table th {
    font-size: 1.1em;
}
section.timings table th td{
    padding: 6px;
}

section.call dl {
    border-top: dotted lightgrey;
    padding-top:6px;
    padding-bottom:6px;
    margin-top:9px;
    width:100%;
    overflow:hidden;

}

section.call dl dt {
    padding:3px;
    float:left;
    width:120px;
    text-align:right;
    margin-right:30px;
    clear:left;
    color:darkgray;
}

section.call dl dd {
    padding:3px;
    float:left;
}

section.call ul li {
    font-size:0.9em;
    padding:3px;
    list-style-type:none;
}

section.call ul.fan_in li:before {
    content: ">>";
    color:darkgray;
}

section.call ul.fan_out li:before {
    content: "<<";
    color:darkgray;
}

section.call ul.fan_in li span.calls {
    width:150px;
    text-align:right;
}

section.call ul.fan_in li span.calls:after {
    color:darkgray;
    content: "calls by";
}

section.call ul.fan_out li span.calls:after {
    color:darkgray;
    content: "calls to";
}

CSS";