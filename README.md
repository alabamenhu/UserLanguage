![Intl::UserLanguage for Raku](docs/logo.png)

This is a incredibly simple module for Raku designed to do one thing and one thing
only: obtain the current user’s preferred language(s).  There is no universal way
to do this, so this module aims to be the one-stop shop to get that information.

To use, simple ask for the preferred language (if you just want one) or
preferred languages (more common).

```raku
use Intl::UserLanguage;
user-language;  # ↪︎ [ast-US] (on my system)
user-languages; # ↪︎ [ast-US], [es-US], [en-US], [pt-PT] (on my system)
                #   (sidenote: no idea why Apple adds -US onto ast…)
                #   (sidenote: Microsoft makes it ast-Latn… weird.)
```

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

```raku
use Intl::UserLanguage :override;  # imports override functions
user-languages; # ↪︎ [ast-US], [es-US], [en-US], [pt-PT] (on my system)
override-user-languages('jp','zh');
user-languages; # ↪︎ [jp], [zh]
```

The override can be cleared at any time with `clear-user-language-override`.
Note that the override is *global*, and there is no current way to lexically
scope it;

# Support

Support is current available for the following OSes:

  - **macOS**: Full list of languages (as defined in System Preferences → Language & Region → Preferred Languages)
  - **Linux**: If `$LANGUAGE` is set, then an ordered list is provided.  Otherwise, it falls back to the more universal `$LANG`, which only provides a single language.  
  - **Windows**: If the registry value `Languages` is set in `HKCU\Control Panel\International\User Profile`, uses the ordered list found there.  Otherwise, it falls back to the registry value `LocaleName` found in at `HKCU\Control Panel\International`.

Support is not available for *nix machines right now, but only because I am not
sure what the `$*DISTRO` value is for those systems.  I imagine detection will be
similar if not identical to Linux.  Please contact me with your `$*DISTRO` value
and how to detect your system language(s) and I'll gladly add it.

# Licenses and Legal Stuff

This module is licensed under the Artistic License 2.0 which is included
with the source.  Camelia (the butterfly) is a trademark belonging to
Larry Walls and used in accordance with his terms.