=begin pod
    This should work on virtually all Linux machines and probably most *nix
    machines as well, but should be tested before enabling by using the C<LANG>
    environmental variable.  On many Linux systems, the C<LANGUAGE> variable is
    also set, which has a colon delimited set of languages in preferred order.

    Linux tends to use a POSIX language tag.  Guidelines for converting these
    can be found in Intl::LanguageTag::POSIX, but should be self contained
    here to avoid providing excess information (like encoding) that a
    LanguageTag::POSIX.new(…).bcp-47 conversion would include.  This work
    will be done for a future version.
=end pod

unit module Linux;
    use Intl::LanguageTag;

#| Obtains the default language(s) assuming a Linux system.
sub linux is export {

    # This is overly simplified and should be refined
    my $code = %*ENV<LANGUAGE> // %*ENV<LANG>;
    $code ~~ s/_/-/;                        # Often uses an underscore instead of a hyphen
    $code ~~ s:g/'.' <[a..zA..Z0..9_-]>+//; # Removes encoding information after the period
    $code ~~ m:g/    <[a..zA..Z0..9-]> +/;  # The colon separator should be the only thing
                                            # left separating the elements
    gather {
        take LanguageTag.new($/[$_].Str) for ^$/.elems;
    }
}
