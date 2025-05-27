{ fetchGit, fetchZip }:
let
    packsJson = builtins.fromJSON (builtins.readFile ./packs.json);
    fetchers = {
        tarball = fetchTarball;
        zip = fetchZip;
        git = fetchGit;
    };
    makePack = {name, url, sha256, ...}: { inherit name; value = fetchers { inherit url sha256; }; };
in builtins.listToAttrs makePack packsJson