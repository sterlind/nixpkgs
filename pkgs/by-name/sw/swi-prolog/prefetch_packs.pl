:- use_module(library(http/json)).
:- use_module(library(prolog_pack)).

ext_fetcher(tgz, tarball).
ext_fetcher(git, git).
ext_fetcher(zip, zip).

prefetch(pack(Name, _, Desc, Ver, Urls), json([name=Name, ver=Ver, fetcher=Fetcher, desc=Desc, url=Url, sha256=Hash])) :-
    member(Url, Urls),
    parse_url(Url, Parsed),
    member(path(Path), Parsed),
    directory_file_path(_, File, Path),
    file_name_extension(_, Ext, File),
    ext_fetcher(Ext, Fetcher),
    setup_call_cleanup(
        process_create(path('nix-prefetch-url'), [Url], [stdout(pipe(Out))]),
        (
            read_lines(Out, Lines),
            last(Lines, Hash)
        ),
        close(Out)).

try_prefetch(Pack, Result) :-
    catch(
        (prefetch(Pack, Result) -> true; Result = err),
        _,
        Result = err).
    
next_line(_, end_of_file, []).
next_line(Stream, H, [H|T]) :- H \= end_of_file, read_lines(Stream, T).    
read_lines(Stream, Lines) :- read_line_to_string(Stream, Str), next_line(Stream, Str, Lines).

run :-
    prolog_pack:query_pack_server(search(''), true(Packs), []),
    concurrent_maplist(try_prefetch, Packs, Results),
    exclude(=(err), Results, Good),
    setup_call_cleanup(
        open('out.json', write, Out),
        json_write(Out, Good),
        close(Out)).