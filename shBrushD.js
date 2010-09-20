/**
 * SyntaxHighlighter
 * http://alexgorbatchev.com/SyntaxHighlighter
 *
 * @version
 * 3.0.83 (July 02 2010)
 * 
 * @copyright
 * Copyright (C) 2004-2010 Alex Gorbatchev.
 *
 * @license
 * Dual licensed under the MIT and GPL licenses.
 */
;(function()
{
    /** 
     * Brush for the D programming language: http://www.digitalmars.com/d
     * Lutger Blijdestijn 2010
     */
   
    typeof(require) != 'undefined' ? SyntaxHighlighter = require('shCore').SyntaxHighlighter : null;
    
    function Brush()
    {
        var builtins  = 'toString toHash opCmp opEquals ' +
                        'opUnary opBinary opApply opCall opAssign opIndexAssign opSliceAssign opOpAssign ' +
                        'opIndex opSlice opDispatch' +
                        'toString toHash opCmp opEquals Monitor factory classinfo vtbl offset getHash equals compare tsize swap next init flags offTi destroy postblit toString toHash' +
                        'factory classinfo Throwable Exception Error capacity reserve assumeSafeAppend clear ' +
                        'ModuleInfo ClassInfo MemberInfo TypeInfo' ;

        var properties = '.sizeof .stringof .mangleof .nan .init .alignof .max .min .infinity .epsilon .mant_dig ' +
                        '.max_10_exp .max_exp .min_10_exp .min_exp .min_normal .re .im';

        var special_tokens = '__FILE__ __LINE__ __DATE__ __EOF__ __TIME__ __TIMESTAMP__ __VENDOR__ __VERSION__ #line';

        var keywords =  '@property @disable abstract alias align asm assert auto body bool break byte case cast catch ' +
                        'cdouble cent cfloat char class const continue creal dchar debug default delegate delete deprecated ' +
                        'do double else enum export extern false final finally float for foreach foreach_reverse ' +
                        'function goto idouble if ifloat immutable import in inout int interface invariant ireal ' +
                        'is lazy long macro mixin module new nothrow null out override package pragma private ' +
                        'protected public pure real ref return scope shared short static struct super switch ' +
                        'synchronized template this throw true try typedef typeid typeof ubyte ucent uint ulong ' +
                        'union unittest ushort version void volatile wchar while with __gshared ' +
                        '__thread __traits ' + 
                        'string wstring dstring size_t hash_t ptrdiff_t equals_t '; // aliases

        this.regexList = [
            { regex: /\/\/\/.*$/gm, css: 'color3' }, 
            { regex: SyntaxHighlighter.regexLib.singleLineCComments,            css: 'comments' },
            { regex: SyntaxHighlighter.regexLib.multiLineCComments,             css: 'comments' },
            { regex: /\/\+[\s\S]*?\+\//g,                                       css: 'color1' },
            { regex: SyntaxHighlighter.regexLib.multiLineDoubleQuotedString,    css: 'string' },
            { regex: SyntaxHighlighter.regexLib.multiLineSingleQuotedString,    css: 'string' },
            { regex: SyntaxHighlighter.regexLib.doubleQuotedString,             css: 'string' },
            { regex: SyntaxHighlighter.regexLib.singleQuotedString,             css: 'string' },
            { regex: new RegExp(this.getKeywords(properties), 'gm'),            css: 'color2' },
            { regex: new RegExp(this.getKeywords(special_tokens), 'gm'),        css: 'constants' },
            { regex: new RegExp(this.getKeywords(builtins), 'gm'),              css: 'color2' },
            { regex: new RegExp(this.getKeywords(keywords), 'gm'),              css: 'keyword' }
            ];
    };
    
    Brush.prototype = new SyntaxHighlighter.Highlighter();
    Brush.aliases   = ['d', 'di'];

    SyntaxHighlighter.brushes.D = Brush;

    // CommonJS
    typeof(exports) != 'undefined' ? exports.Brush = Brush : null;
})();