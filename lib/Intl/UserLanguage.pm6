unit module Intl::UserLanguage:ver<0.2.0>:auth<Matthew Stephen Stuckwisch (mateu@softastur.org)>;
use Intl::BCP47;

my @defaults = ();

proto sub user-langauges(|c) { * }
proto sub user-langauge(|c)  { * }

multi sub user-languages (LanguageTag $default = LanguageTag.new('en')) is default is export {
  return @defaults if @defaults;

  given $*DISTRO {
    when /macosx/ { mac      }
    when /linux/  { linux    }
    default       { $default }
  }
}


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

sub linux {
  # This probably works for most *nix machines, but needs testing.
  # There may be better (list like) options, if anyone knows them, please
  # make a pull request or send me information on how to get them.
  my $code = %*ENV<LANG>;
  $code ~~ s/_/-/; # Often uses an underscore instead of a hyphen
  $code ~~ /<[a..zA..Z0..9-]>+/; # Only one code is provided, and often has
                                 # a period before an encoding: 'en-US.UTF-8'
                                 # The encoding is not part of a valid tag.
  LanguageTag.new: $code;
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
