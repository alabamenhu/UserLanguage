#!/usr/bin/env perl6
=begin pod
    This script will likely need to be run on a separate machine for each person
=end pod
sub MAIN(:$target) {
    die "You should specify a target (e.g. 'macos')." unless $target;
    given $target {
        when /:i mac[os[x]?]?/ { build-mac }
        default { say 'Sorry! Unknown target.' }
    }
}


sub build-mac {
    my \input  = $*PROGRAM.sibling('native-src').add('macos.m'    );
    my \output = $*PROGRAM.sibling('native-lib').add('macos.dylib');

    my $result = run
            'clang', #'-ObjC',
            '-undefined', 'dynamic_lookup',
            '-framework', 'Foundation',
            '-dynamiclib',
            '-o', output, input,
            :err, :out;
    say do $result
        ?? "Compilation for macOS was successful!"
        !! "There was an error during compilation:\n{$result.err.slurp(:close)}";
}