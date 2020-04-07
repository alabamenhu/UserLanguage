unit module Intl::UserLanguage:ver<0.2.0>:auth<Matthew Stephen Stuckwisch (mateu@softastur.org)>;
use Intl::LanguageTag;

my @defaults = ();

proto sub user-langauges(|c) { * }
proto sub user-langauge( |c) { * }

#| Obtains the user’s preferred language(s) in LanguageTag format.
multi sub user-languages (LanguageTag $default = LanguageTag.new('en')) is default is export {
  return @defaults if @defaults;

  given $*DISTRO {
    when .is-win   { try { CATCH { $default }; windows  }}
    when /macosx/  {                           mac       }
    when /linux/   {                           linux     }
    default        {                           $default, }
  }
}

#| Obtains the default language(s) assuming a macOS system.
sub mac {
  # This should work on machines going back at least to 2012 (OS X Mountain
  # Lion) and quite possibly a good bit further back than that. The defaults
  # command on the Mac returns a list formatted as such:
  # (           # opening parenthesis
  #    "foo",   #   language tag in quotes
  #    "bar"    #   with no final comma
  # )           # closing parenthesis

  my $text = (run 'defaults', 'read', '-g', 'AppleLanguages', :out).out.slurp;
  $text ~~ m:g/<[a..zA..Z0..9-]>+/;
  gather {
    take LanguageTag.new($/[$_].Str) for ^$/.elems;
  }
}

#| Obtains the default language(s) assuming a Linux system.
sub linux {
  # It should work on virtually all Linux machines and probably most *nix
  # machines as well, but should be tested before enabling by using the LANG
  # environmental variable.  On many Linux systems, the LANGUAGE variable is
  # also set, which has a colon delimited set of languages in preferred order.

  my $code = %*ENV<LANGUAGE> // %*ENV<LANG>;
  $code ~~ s/_/-/; # Often uses an underscore instead of a hyphen
  $code ~~ s/'.' <[a..zA..Z0..9_-]>+//; # Removes encoding information after the period
  $code ~~ m:g/<[a..zA..Z0..9-]>+/;     # the colon separator should be the only thing
                                        # left separating the elements
  gather {
    take LanguageTag.new($/[$_].Str) for ^$/.elems;
  }
}

#| Obtains the default language(s) assuming a Windows system.
sub windows {
  # It should obtain the active language on most recent (NT and higher) versions.
  # If not, please submit a bug request with your version of Windows and a way to
  # detect the language.
  # On most (?) Windows, we can get the LocaleName by reading the registry.
  # The output of the command run below looks like
  #
  # HKEY_CURRENT_USER\Control Panel\International
  #    Locale    REG_SZ    00000409
  #    LocaleName    REG_SZ    en-US
  #    […]
  # According to Window's docs, it is possible for Windows to be run "regionless"
  # but I'm not sure how that would work.  The region code is "-" in that
  # theoretical case.
  #
  # For later versions of Windows, it is possible to get an ordered list of languages.
  # As with the Linux code, the first attempt is to get an ordered list. If that fails,
  # then the more fool-proof LocaleName will be used.

  my $text = (run 'reg', 'query', 'HKCU\Control Panel\International\User Profile', :out).out.slurp;
  if my $entry = ($text.lines.first(*.contains: "Languages")) {
    return gather { take LanguageTag.new($_) for $entry.words[2].split('\0') }
  }

  $text = (run 'reg', 'query', 'HKCU\Control Panel\International', :out).out.slurp;
  $text.lines.first(*.contains: 'LocaleName').words[2];
}



multi sub user-languages (Str $default = 'en') is export {
  samewith LanguageTag($default)
}
multi sub user-language (Str $default = 'en') is export {
  samewith LanguageTag($default)
}
multi sub user-language (LanguageTag $default = LanguageTag.new('en')) is default is export {
  user-languages($default).head;
}

# Slurpies can't be typed, but that's fine.
# If it's a LanguageTag, it's taken as is, otherwise it's converted into one.
sub override-user-languages(**@languages is copy) is export(:override) {
  @defaults = do gather {
    for @languages -> $language {
      if $language ~~ LanguageTag {
        take $language
      } else {
        take LanguageTag.new($language)
      }
    }
  }
}
sub clear-user-language-override is export(:override) {
  @defaults = ();
}
