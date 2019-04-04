unit module Intl::UserLanguage:ver<0.2.0>:auth<Matthew Stephen Stuckwisch (mateu@softastur.org)>;
use Intl::BCP47;

my @defaults = ();

proto sub user-langauges(|c) { * }
proto sub user-langauge(|c)  { * }

multi sub user-languages (LanguageTag $default = LanguageTag.new('en')) is default is export {
  return @defaults if @defaults;

  given $*DISTRO {
    when /macosx/ { mac       }
    when /linux/  { linux     }
    default       { $default, }
  }
}

#| The subroutine that obtains the user’s preferred languages for macOS.
#| It should work on Mac OS machines going back at least to 2012 (OS X Mountain
#| Lion) and quite possibly a good bit further back than that.
sub mac {
  # The defaults command on the Mac returns a list formatted as such:
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

#| The subroutine that obtains the user’s preferred languages for Linux.
#| It should work on virtually all Linux machines and probably most *nix
#| machines as well
sub linux {
  # This probably works for most *nix machines, but needs testing.
  # There may be better (list like) options, if anyone knows them, please
  # make a pull request or send me information on how to get them.
  #
  # On many Linux systems, the LANGUAGE variable is also set, which has a colon
  # delimited set of languages.
  my $code = %*ENV<LANGUAGE> // %*ENV<LANG>;
  $code ~~ s/_/-/; # Often uses an underscore instead of a hyphen
  $code ~~ s/'.' <[a..zA..Z0..9_-]>+// # Removes encoding information after the period
  $code ~~ m:g/<[a..zA..Z0..9-]>+/; # the colon separator should be the only thing
                                    # left separating the elements
  gather {
    take LanguageTag.new($/[$_].Str) for ^$/.elems;
  }
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
sub override-user-languages(**@languages is copy) {
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
sub clear-user-language-override {
  @defaults = ();
}
