=begin pod
    Because UserLanguage is designed to be a core Intl module, it is allowed only *one*
    dependency: C<Intl::LanguageTag>. This means that many operations that would be very
    simple elsewhere by, e.g. consulting Intl::CLDR must be 100% self-contained here.

    Due to the added complexity of handling potentially complicated lookups, it is
    recommended that highly specialized look ups (e.g. major distributions of operating
    systems) be farmed out into specialized modules C<Intl::UserLanguage::OS-Name>.
    At the present moment, these are called individually by subs, but as that necessitates
    some overhead for each one, a different solution will be devised later that will
    load on demand.  (This cannot be done at compile-time, as theoretically precompiled
    things should be transferable from one system to another).

=end pod

my package UserLanguage {
    my @languages;        #= The user's preferred languages
    my @languages-backup; #= The 'backup' when overriding, effectively a temp var
    my @fallback;         #= The fallback, in case languages could not be determined (rare)
}

# Because we allow the positional arguments,
# the use of the EXPORT sub is obligatory.

#| Exports the UserLanguage routines into the current scope
sub EXPORT (
        +@fallback-languages #= The language tag(s) to use as the fallback if language detection fails
) {
  use Intl::LanguageTag:ver<0.11>;
  use Intl::UserLanguage::Linux;
  use Intl::UserLanguage::Mac;
  use Intl::UserLanguage::Windows;

  # There are only three variables that need to be persistent
  my @languages;        #= The user's preferred languages
  my @languages-backup; #= The 'backup' when overriding, effectively a temp var
  my @fallback;         #= The fallback, in case languages could not be determined (rare)

  # The fallback can either be specified in the 'use' statement, or defaults
  # to English (because linguistic hegemony and all -- but don't think I haven't
  # been tempted to set it to something like Guarani just for funsies).
  if @fallback-languages {
    @fallback = @fallback-languages.&to-lang-tag;
  } else {
    @fallback := LanguageTag.new('en').list
  }


  # The primary function for us to use
  proto sub user-languages(|c) { * }
  proto sub user-language( |c) { * }

  #| Obtains the user’s preferred language(s) in LanguageTag format.
  multi sub user-languages (+@default) is export {
    .return if @languages;

    @languages =
        do given $*DISTRO  {
            when .is-win   {        windows        }
            when /macosx/  {          mac          }
            when /linux/   {         linux         }
            CATCH          {        default {}     } # By doing nothing, we fall through to…
        } //               ( @default.&to-lang-tag   # Return the fallback,
                             || @fallback          ) #   or defined at 'use'
  }

  #| Obtains the user’s preferred language in LanguageTag format.
  multi sub user-language (|default) is export {
    user-languages(default).head;
  }


  # These should technically be methods but then they can't be multi.
  # These are only really needed until a Str->LanguageTag coercion method
  # is possible in core (e.g. FROM() ).
  multi sub to-lang-tag(LanguageTag \tag ) {                  tag }
  multi sub to-lang-tag(Str()       \tag ) { LanguageTag.new: tag }
  multi sub to-lang-tag(Iterable    \tags) is default { gather {take .&to-lang-tag for tags} }


  Map.new:
         # '&clear-user-language-override' => &clear-user-language-override,
         # '&override-user-languages'      => &override-user-languages,
          '&user-language'                => &user-language,
          '&user-languages'               => &user-languages,
}




my package EXPORT::override {

    sub override-user-languages(+@languages is copy) is export(:override) {
        use Intl::LanguageTag;
        @UserLanguage::languages-backup = @languages;
        @languages := lazy gather {
            for @languages -> $language {
                ($language ~~ LanguageTag)
                        ?? (take $language)
                        !! (take LanguageTag.new: $language)
            }
        }
    }

    sub clear-user-language-override is export(:override) {
        @UserLanguage::languages = @UserLanguage::languages-backup;
    }
}

