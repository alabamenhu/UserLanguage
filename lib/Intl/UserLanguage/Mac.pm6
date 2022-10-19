=begin pod
The Mac stores language information in several locations in the global
preferences domain.  Thus, we read them all using the shell command
'defaults read -g X' where X is the property that we want.  Parsing is
regrettably not consistent, but will be documented at each stage.

Per one of Apple's support posts (which I regrettably did not save a
link to), use of these defaults calls is I<not> considered a public
API, and is subject to change.  Nonetheless, they appear to be
generally stable and should work going back to at least 2012 (OS X
Mountain Lion), and probably a good bit further back than that.
If we need to version guard any piece, I've specifically designed
this file to make that straightforward.

The stable API requires a call to Apple's Foundation frameworks.
This is done via NativeCall.  Because of the way that GateKeeper works,
I'm not entirely convinced that this is something that can be
guaranteed to function long term without requiring users to build
on their system (which requires clang or gcc to be installed).
For this reason, I have also maintained similar code in Raku using
the aforementioned non-public/non-stable (but very in the open,
very unchanged) API provided through defaults.
=end pod

unit module Mac;

use NativeCall;
sub mac_native
        returns Str is encoded('utf8')
        is native(%?RESOURCES<macos/userlanguage.dylib>) {*}

#| Obtains the default language(s) assuming a macOS system.
sub mac is export {
    my $native = mac_native();

    # Guard to ensure we got something back
    if $native {
        return $native.split(';');
    }

    # Not actually sure what a GateKeeper error would look like,
    # but hopefully this will actually catch it.  Just fallback
    # to the defaults method, which should get *something*
    CATCH {
        return mac_non-native
    }

    # One last just-in-case call of the non-native one.
    return mac_non-native;
}


sub mac_non-native {
    # Extended information can can be obtained through the following commands (all defaults read -g)
    #    AppleCollationOrder      # e.g. 'en' English
    #                                    'es' Spanish
    #                                    'es@collation=traditional' Spanish traditional sort
    #    AppleICUForce24HourTime  # 1 if 24, 0 if 12, not present if defaults
    #    AppleMetricUnits         # 0 / 1
    #    AppleTemperatureUnit     # e.g. 'Celsius' / 'Fahrenheit'
    # TODO: add in extended information
    # -t-k0
    #   defaults read com.apple.HIToolbox # NOT com.apple.keyboard
    # -u (other)
    #   defaults read NSGlobalDomain
    #   ^^ the names vary; must check exact names by testing customized values
    #      as only those that differ from the defaults are used

    my $calendar  = get-calendar;
    my $collation = get-collation;
    my $first-day = get-first-day-of-week($calendar);

    my $extensions = "";
    if $calendar || $collation || $first-day {
        $extensions = '-u';
        $extensions ~= '-ca-' ~ $calendar<bcp47> if $calendar;
        $extensions ~= '-co-' ~ $collation       if $collation;
        $extensions ~= '-fw-' ~ $first-day       if $first-day;
        #$extensions ~= '-ms-' ~ $measure   if $measure;
    }

    return get-basetags.map(* ~ $extensions);
}

sub get-basetags {
    # The ordered list of languages is found in the NSGlobalDomain key AppleLanguages.
    # It returns a list formatted as such:
    # (           # opening parenthesis
    #    "foo",   #   language tag in quotes
    #    "bar"    #   with no final comma
    # )           # closing parenthesis
    # They will have language, region, and (rarely) script.
    my $text = (run 'defaults', 'read', '-g', 'AppleLanguages', :out, :err).out.slurp;

    return .list>>.Str
        given $text ~~ m:g/<[a..zA..Z0..9-]>+/;
}

sub get-collation {
    # Collation order on macOS can be distinct from the system language.  This is not representable
    # in BCP-47.  Our best option is to add the the additional collation information if present,
    # but otherwise leave it blank (hence the gate on matching @collation)
    constant %collation = :big5han<big5han>, :compat<compat>, :dict<dict>, :dictionary<dict>,
                          :direct<direct>, :ducet<ducet>, :emoji<emoji>, :eor<eor>, :gb2313<gb2313>,
                          :gb2312han<gb2313>, :phonebk<phonebk>,  :phonebook<phonebk>,
                          :phonetic<phonetic>, :pinyin<pinyin>, :reformed<reformed>, :search<search>,
                          :searchjl<searchjl>, :standard<standard>, :stroke<stroke>, :trad<trad>,
                          :traditional<trad>, :unihan<unihan>, :zhuyin<zhuyin>;

    my $user-collation = (run 'defaults', 'read', '-g', 'AppleCollationOrder', :out, :err).out.slurp;
    my $collation = "";
    if $user-collation ~~ /'@collation=' <( .* )> $$ / {
        $collation = %collation{$/.Str}
    }
    return $collation;
}

sub get-measurement-system {
   ...
}

sub get-temperature-system {
    ...
}

sub get-calendar {
    # macOS basically assumes gregorian (safe bet) and will only specify the calendar in the
    # locale if the user asks for a different one.  We must hold on to the original calendar
    # name (potentially > 8 chars) for capturing the first day of the week if it's not Sunday
    constant %calendar = :buddhist<buddhist>, :chinese<chinese>, :coptic<coptic>, :dangi<dangi>,
                         :ethiopic<ethiopic>, :ethioaa<ethioaa>, :ethiopic-amete-alem<ethioaa>,
                         :gregorian<gregory>, :gregory<gregory>, :hebrew<hebrew>, :indian<indian>,
                         :islamic<islamic>, :islamicc<islamic-civil> #`[←deprecated],
                         :islamic-civil<islamic-civil>, :islamic-rgsa<islamic-rgsa>,
                         :islamic-tbla<islamic-tbla>, :islamic-umalqura<islamic-umalqura>,
                         :iso8601<iso8601>, :japanese<japanese>, :persian<persian>, :roc<roc>;

    my $user-calendar = (run 'defaults', 'read', '-g', 'AppleLocale', :out, :err).out.slurp;
    my $calendar = "gregory";
    my $orig-calendar = "gregorian";
    if $user-calendar ~~ /'calendar=' <( .* )> $$ / {
        $orig-calendar = $/.Str;
        $calendar = %calendar{$/.Str}
    }
    return %(bcp47 => $calendar, original => $orig-calendar);
}

sub get-first-day-of-week (%calendar ) {
    # If it's not Sunday, it will get listed with the following meanings
    constant %days = '1' => 'sun', '2' => 'mon', '3' => 'tue', '4' => 'wed', '5' => 'thu', '6' => 'fri', '7' => 'sat';
    my $user-first-day = (run 'defaults', 'read', '-g', 'AppleFirstWeekday', :out, :err).out.slurp;
    my $first-day = "sun";
    if $user-first-day ~~ / {%calendar<original>} \h+ '=' \h <( \d )> / {
        $first-day = %days{$/.Str}
    }
    return $first-day;
}