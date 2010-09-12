_dmd()
{
    local cur opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD -1 ]}"
    opts="-c -cov -d -Dd -debug -debug= -debuglib= -defaultlib= -deps= -Df -D -fPIC -g -gc -Hd --help -Hf -H -ignore -inline -I -J -lib -L -man -map -noboundscheck -nofloat -od -o- -of  -O -op -profile -quiet -release -run -unittest -version= -vtls -v -w -wi -Xf -X"
    
    if [[ "$cur" == -L-* ]]; then
        COMPREPLY=( $( compgen -W "$( ld --help 2>&1 | \
            sed -ne 's/.*\(--[-A-Za-z0-9]\{1,\}\).*/-L\1/p' | sort -u )" -- "$cur" ) )
            return 0;
    elif [[ "$cur" == -L* ]]; then
        COMPREPLY=( $(compgen -f -X '\.*' -P "-L" -- ${cur#-L}) )
        return 0;
    elif [[ ${cur} == -* ]] ; then
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
    else
        _filedir '@(d|di|D|DI|ddoc|DDOC)'
        return 0
    fi
}

complete -F _dmd dmd

_rdmd()
{
    local cur sofar opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    sofar="${COMP_WORDS[@]:1:COMP_CWORD}"
    opts="--main --build-only --chatty --compiler= --help --eval= --man --force --dry-run --loop -c -cov -d -Dd -debug -debug= -debuglib= -defaultlib= -deps= -Df -D -fPIC -g -gc -Hd --help -Hf -H -ignore -inline -I -J -lib -L -man -map -noboundscheck -nofloat -od -o- -of  -O -op -profile -quiet -release -run -unittest -version= -vtls -v -w -wi -Xf -X"

    for i in $sofar
    do
        if [ -e $i ]
        then
            _filedir '@(*)'
            return 0
        fi
    done
    
    if [[ ${cur} == -* ]] ; then
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
    else
        _filedir '@(d|di|D|DI|ddoc|DDOC)'
        return 0
    fi
}

complete  -F _rdmd rdmd
