=begin pod
It should obtain the active language on most recent (NT and higher) versions.
If not, please submit Github issue with your version of Windows and a way to
detect the language.

On most (?) Windows, we can get the LocaleName by reading the registry.
The output of the command run below looks like

    HKEY_CURRENT_USER\Control Panel\International
       Locale    REG_SZ    00000409
       LocaleName    REG_SZ    en-US
       […]

According to Window's docs, it is possible for Windows to be run "regionless"
but I'm not sure how that would work.  The region code is "-" in that
theoretical case.

For later versions of Windows, it is possible to get an ordered list of languages.
As with the Linux code, the first attempt is to get an ordered list. If that fails,
then the more fool-proof LocaleName will be used.
=end pod

unit module Windows;

#| Obtains the default language(s) assuming a Windows system.
sub windows is export {

    my $text = (run 'reg', 'query', 'HKCU\Control Panel\International\User Profile', :out).out.slurp;
    if my $entry = ($text.lines.first(*.contains: "Languages")) {
        return $entry.words[2].split('\0');
    }

    $text = (run 'reg', 'query', 'HKCU\Control Panel\International', :out).out.slurp;
    $text.lines.first(*.contains: 'LocaleName').words[2];
}
