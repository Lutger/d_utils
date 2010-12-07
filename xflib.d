/** api to access information contained the json files produced by dmd -Xf in a
 *  structured way.
 *
 *  Status: being worked on, don't use it yet.
**/
module xflib;
import std.stdio;
import std.json;
import std.string;
import std.algorithm;
import std.functional;
import std.range;
import std.uni, std.utf;
import std.conv;
import std.array;
import std.string;
import std.exception;
import std.traits;
import test;

/***/
enum Kind
{
    /***/
    Class,
    /***/
    Constructor,
    /***/
    Destructor,
    /***/
    Enum,
    /***/
    EnumMember,
    /***/
    Function,
    /***/
    Module,
    /***/
    Template,
    /***/
    Struct,
    /***/
    Variable,
    /***/
    Void
}

/***/
Kind toKind(string kind)
{
    switch(kind)
    {
        case "class": return Kind.Class;
        case "constructor": return Kind.Constructor;
        case "destructor": return Kind.Destructor;
        case "enum": return Kind.Enum;
        case "enum member": return Kind.EnumMember;
        case "function": return Kind.Function;
        case "module": return Kind.Module;
        case "template": return Kind.Template;
        case "struct": return Kind.Struct;
        case "variable": return Kind.Variable;
        default:
            throw new Exception(text("kind '", kind, "' not recognized"));
    }
}

/***/
alias EnumMembers!Kind AllKinds;

/***/
class DSymbol
{
    @property const nothrow
    {
        /** Identifier */
        string name() { return _name; }

        /** a dot seperated string containing the fully qualified name */
        string fullyQualifiedName() { return _fqn; }

        /** same as fullyQualifiedName, except it doesn't include the module */
        string qualifiedName() { return _qn; }
        
        /***/
        long line() { return _line; }

        /***/
        string file() { return _file; }

        /***/
        string type() { return _type; }

        /***/
        Kind kind() { return _kind; }

        /***/
        string templateParameters() { return _templateParameters; }


        /***/
        bool isParametrized() { return _templateParameters.length > 0; }

        /** Base class name
         *
         *  Note that in some case it is ambiguous from the json source which
         *  base class is implemented
         */
        string base() { return _base; }

        /** Array of interface names.
         *
         *  Note that in some case it is ambiguous from the json source which
         *  interfaces are implemented
         */
        const(string[]) interfaces() { return _interfaces; }

        /***/
        const(DSymbol) parent() { return _parent; }
        
        /***/
        const(DSymbol[]) members() { return _members; }
    }

private:
    this(JSONValue obj, DSymbol parent)
    {
        auto name = splitTemplateArgs( getValueOf(obj, "name", "") );
        this._name = name[0];
        this._templateParameters = name[1];
        if (parent)
        {
            this._qn = parent._qn ~ "." ~ this._name;
            this._fqn = parent._fqn ~ "." ~ this._name;
        }
        else
        {
            this._qn = this._name;
            this._fqn = this._name;
        }

        this._line = getValueOf(obj, "line", 0L);
        if (parent)
            this._file = parent._file;
        else
            this._file = getValueOf(obj, "file", "");
        this._type = getValueOf(obj, "type", "");
        this._base = getValueOf(obj, "base", "");
        this._kind = toKind(getValueOf(obj, "kind", "Void"));
        this._parent = parent;

        foreach( member; jsonArrayIterator(obj, "members") )
            this._members ~= new DSymbol(member, this);

        foreach( iface; jsonArrayIterator(obj, "interfaces") )
            this._interfaces ~= iface.str;
    }
    
    string _fqn;
    string _qn;
    long _line;
    string _file;
    string _type;
    string _name;
    Kind _kind;
    string _base ;
    DSymbol _parent;
    DSymbol[] _members;
    string[] _interfaces;
    string _templateParameters;
}

unittest
{
    // test DSymbol 
}

/***/
class XfInfo
{
    /** construct from a json string */
    this(string json)
    {
        foreach( rootObject; jsonArrayIterator(parseJSON(json)))
            _roots ~= new immutable(DSymbol)(rootObject, null);
    }
    
    /** depth-first iteration of all symbols */
    int opApply(scope int delegate (ref const(DSymbol)) dg)
    {
        return visit(roots, dg);
    }

    /** all root symbols (modules) */
    @property const
    immutable(DSymbol[]) roots()
    {
        return _roots;
    }
    
private:
    // implementation of opApply
    int visit(const(DSymbol)[] symbols, scope int delegate (ref const(DSymbol)) dg)
    {
        int result = 0;

        foreach(sym; symbols)
        {
            result = dg(sym);
            if (result)
                return result;
            if (sym.members.length)
            {
                result = visit(sym.members, dg);
                if (result)
                    return result;
            }
        }
        return result;
    }
    
    immutable(DSymbol)[][string] nameMap;
    immutable(DSymbol[]) _roots;
}

unittest
{
    // test XfInfo
}

private:

auto getValueOf(T)(JSONValue jsonObject, string field, T defaultValue)
{
    auto result = defaultValue;
    auto fieldPtr = field in jsonObject.object;
    if (fieldPtr)
    {
        static if ( is(T == string) )
        {
            // check
            result = fieldPtr.str;
        }
        else static if ( is(T == long) )
        {
            // check
            result = fieldPtr.integer;
        }
        else
        {
            static assert(false, "not supported:" ~ T.stringof);
        }

    }
    return result;
}

unittest
{
    auto jsonObject = q{{ "foo" : "bar", "num" : 42 }}.parseJSON();
    assert( getValueOf(jsonObject, "foo", "") == "bar" );
    assert( getValueOf(jsonObject, "fooNotFound", "default") == "default" );
    assert( getValueOf(jsonObject, "num", 0L) == 42L );
}

string[2] splitTemplateArgs(string identifier)
{
    string[2] result;
    auto indexOfParen = std.string.indexOf(identifier, '(');
    if (indexOfParen > -1)
    {
        result[0] = identifier[0..indexOfParen];
        result[1] = identifier[indexOfParen..$];
    }
    else
        result[0] = identifier;
    return result;
}

unittest
{
    string[2] fooBar = splitTemplateArgs("foo(bar)");
    assert( fooBar[0] == "foo" );
    assert( fooBar[1] == "(bar)" );
    
    string[2] b = splitTemplateArgs("(b)");
    assert( b[0] == "");
    assert( b[1] == "(b)");
}

struct jsonArrayIterator
{
    this(JSONValue value, string field = "")
    {
        setArrayNull();
        
        if (value.type == JSON_TYPE.OBJECT)
        {
            auto fieldPtr = field in value.object;
            if (fieldPtr && fieldPtr.type == JSON_TYPE.ARRAY)
                this.array = *fieldPtr;
        }
        else if (value.type == JSON_TYPE.ARRAY)
        {
            this.array = value;
        }
    }

    int opApply(scope int delegate(ref JSONValue) dg)
    in
    {
        assert( this.array.type == JSON_TYPE.ARRAY ||
                isArrayNull());
    }
    body
    {
        int result = 0;

        if (isArrayNull())
            return 0;
        
        foreach(value; array.array)
        {
            result = dg(value);
            if (result)
                return result;
        }
        
        return result;
    }
    
private:
    void setArrayNull()
    {
        this.array = JSONValue();
        this.array.type = JSON_TYPE.NULL;
    }

    bool isArrayNull()
    {
        return this.array.type == JSON_TYPE.NULL;
    }

    JSONValue array;
}

unittest
{
    // jsonArrayIterator
}
