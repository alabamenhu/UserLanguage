# Intl::UserLanguage

This is a incredibly simple module designed to do one thing and one thing only:
obtain the current user’s preferred language(s).  There is no universal way to
do this, so this module aims to be the one-stop shop to get that information.

To use, simple ask for the preferred language (if you just want one) or
preferred languages (more common).

    use Intl::UserLanguage;
    user-language;  # ↪︎ [ast] (on my system)
    user-languages; # ↪︎ [ast-US], [es-US], [en-US], [pt-PT] (on my system)
                    #   (sidenote: no idea why Apple adds -US onto ast…)

In truth, the preferred language is just a wrapper for calling `.head` on the
list.  I'd recommend against using `user-language`, as most times when you
need the languages (HTTP request headers, localization frameworks) there needs
to be a negotiation to find a best match.

In any case, both functions allow you to supply a default code which may be a
string in BCP47 format or a LanguageTag.  This is useful in case for some reason
the user’s language(s) cannot be determined, for example, if the user is
running an operating system that has not had its settings cataloged in this
module.  If you do not provide a default, and no language can be found, the
*default* default language is **en** (English).

As a final option, particularly if you want to test your code with other
languages, you can override the user’s system languages:

    user-languages; # ↪︎ [ast-US], [es-US], [en-US], [pt-PT] (on my system)
                    #   (sidenote: no idea why Apple adds -US onto ast…)
    override-user-languages('jp','zh');
    user-languages; # ↪︎ [jp], [zh]

The override can be cleared at any time with `clear-user-language-override`;

# Support

Support is current available for the following OSes:

  - **macOS**: Full list of languages (as defined in System Preferences → Language & Region → Preferred Languages)
  - **Linux**: If the `$LANGUAGE` is set, then an ordered list is provided.  Otherwise, it falls back to `$LANG`, which only provides a single language.  
