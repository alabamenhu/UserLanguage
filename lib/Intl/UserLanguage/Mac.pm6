=begin pod
   This should work on machines going back at least to 2012 (OS X Mountain
   Lion) and quite possibly a good bit further back than that.  If anyone
   has an older machine I can test on...

   The Mac stores language information in several locations in the global
   preferences domain.  Thus, we read them all using the shell command
   'defaults read -g X' where X is the property that we want.  Parsing is
   regrettably not consistent, but will be documented at each stage.
=end pod

unit module Mac;

use Intl::LanguageTag:ver<0.11>;

use NativeCall;
sub mac_native()
        returns Str is encoded('utf8') #`[int32]
        is native(%?RESOURCES<native-lib/macos.dylib>) {*}

#| Obtains the default language(s) assuming a macOS system.
sub mac is export {
    # Extended information can can be obtained through the following commands (all defaults read -g)
    #    AppleCollationOrder      # e.g. 'en' English
    #                                    'es' Spanish
    #                                    'es@collation=traditional' Spanish traditional sort
    #    AppleICUForce24HourTime  # 1 if 24, 0 if 12, not present if defaults
    #    AppleMetricUnits         # 0 / 1
    #    AppleTemperatureUnit     # e.g. 'Celsius' / 'Fahrenheit'

    # First calculate the extensions strings because these will be attached
    # The collation values appear in CLDR's BCP47, but are C&P'd in here
    #                     ↓ literal values    ↓ shortened
    constant %collation = :big5han<big5han>,
                          :compat<compat>,
                          :dict<dict>,        :dictionary<dict>,
                          :direct<direct>,
                          :ducet<ducet>,
                          :emoji<emoji>,
                          :eor<eor>,
                          :gb2313<gb2313>,    :gb2312han<gb2313>,
                          :phonebk<phonebk>,  :phonebook<phonebk>,
                          :phonetic<phonetic>,
                          :pinyin<pinyin>,
                          :reformed<reformed>,
                          :search<search>,
                          :searchjl<searchjl>,
                          :standard<standard>,
                          :stroke<stroke>,
                          :trad<trad>,        :traditional<trad>,
                          :unihan<unihan>,
                          :zhuyin<zhuyin>;

    # First we handle the collation
    # Collation order on macOS can be distinct from the system language.  This is not representable
    # in BCP-47.  Our best option is to add the the additional collation information if present,
    # but otherwise leave it blank (hence the gate on matching @collation)
    my $user-collation = (run 'defaults', 'read', '-g', 'AppleCollationOrder', :out, :err).out.slurp;
    my $collation = "";
    if $user-collation ~~ /'@collation=' <( .* )> $$ / {
        $collation = %collation{$/.Str}
    }

    constant %calendar =
        :buddhist<buddhist>,
        :chinese<chinese>,
        :coptic<coptic>,
        :dangi<dangi>,
        :ethiopic<ethiopic>,
        :ethioaa<ethioaa>, :ethiopic-amete-alem<ethioaa>,
        :gregorian<gregory>, :gregory<gregory>,
        :hebrew<hebrew>,
        :indian<indian>,
        :islamic<islamic>,
        :islamicc<islamic-civil>, # deprecated
        :islamic-civil<islamic-civil>,
        :islamic-rgsa<islamic-rgsa>,
        :islamic-tbla<islamic-tbla>,
        :islamic-umalqura<islamic-umalqura>,
        :iso8601<iso8601>,
        :japanese<japanese>,
        :persian<persian>,
        :roc<roc>;

    # Next handle the calendar system
    # macOS basically assumes gregorian (safe bet) and will only specify the calendar in the
    # locale if the user asks for a different one.  We must hold on to the original calendar
    # name (potentially > 8 chars) for capturing the first day of the week if it's not Sunday
    my $user-calendar = (run 'defaults', 'read', '-g', 'AppleLocale', :out, :err).out.slurp;
    my $calendar = "gregory";
    my $orig-calendar = "gregorian";
    if $user-calendar ~~ /'calendar=' <( .* )> $$ / {
        $orig-calendar = $/.Str;
        $calendar = %calendar{$/.Str}
    }

    # Next we capture the first day of the week.  If it's not Sunday, it will get listed with the
    # following meanings
    constant %days = '1' => 'sun', '2' => 'mon', '3' => 'tue', '4' => 'wed', '5' => 'thu', '6' => 'fri', '7' => 'sat';
    my $user-first-day = (run 'defaults', 'read', '-g', 'AppleFirstWeekday', :out, :err).out.slurp;
    my $first-day = "sun";
    if $user-first-day ~~ / $orig-calendar \h+ '=' \h <( \d )> / {
        $first-day = %days{$/.Str}
    }

    # I'm not sure yet if Apple handles the UK system at all.  I don't think so.
    # In any case, the measurements part of the tags are set for a revision in
    # CLDR 40, so no need to stress too much for now.
    constant %measures = 'U.S' => 'ussystem', 'U.K.' => 'uksystem', :metric<metric>;
    my $user-measure = mac_native;
    my $measure =  %measures{$user-measure};


    my $extensions = "";
    if $calendar || $collation || $first-day {
        $extensions = '-u';
        $extensions ~= '-ca-' ~ $calendar  if $calendar;
        $extensions ~= '-co-' ~ $collation if $collation;
        $extensions ~= '-fw-' ~ $first-day if $first-day;
        $extensions ~= '-ms-' ~ $measure   if $measure;
    }


    # The ordered list of languages is found in the NSGlobalDomain key AppleLanguages.
    # Reading it with 'defaults' returns a list formatted as such:
    # (           # opening parenthesis
    #    "foo",   #   language tag in quotes
    #    "bar"    #   with no final comma
    # )           # closing parenthesis
    # To these we attach the extensions information we have just built up.
    my $text = (run 'defaults', 'read', '-g', 'AppleLanguages', :out, :err).out.slurp;
    $text ~~ m:g/<[a..zA..Z0..9-]>+/; # grab runs of tags
    gather {
        take LanguageTag.new($/[$_].Str ~ $extensions) for ^$/.elems;
    }


    # TODO: add in extended information
    # -t-k0
    #   defaults read com.apple.HIToolbox # NOT com.apple.keyboard
    # -u (other)
    #   defaults read NSGlobalDomain
    #   ^^ the names vary; must check exact names by testing customized values
    #      as only those that differ from the defaults are used
}
