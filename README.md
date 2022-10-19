![Intl::UserLanguage for Raku](docs/logo.png)

This is a incredibly simple module for Raku designed to do one thing and one thing
only: obtain the current user’s preferred language(s).  There is no universal way
to do this, so this module aims to be the one-stop shop to get that information.

To use, simply ask for the preferred language (if you just want one) or
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

  - **macOS**  
    Full list of languages (as defined in *System Preferences → Language & Region → Preferred Languages*).  Paralinguistic preferences (e.g. calendar type) are not set on a per-language basis, so they carry to all languages.
  - **Linux**: If `$LANGUAGE` is set, then an ordered list is provided.  Otherwise, it falls back to the more universal `$LANG`, which only provides a single language.  
  - **Windows**: If the registry value `Languages` is set in `HKCU\Control Panel\International\User Profile`, uses the ordered list found there.  Otherwise, it falls back to the registry value `LocaleName` found in at `HKCU\Control Panel\International`.

Support is not available for *nix machines right now, but only because I am not
sure what the `$*DISTRO` value is for those systems.  I imagine detection will be
similar if not identical to Linux.  Please contact me with your `$*DISTRO` value
and how to detect your system language(s) and I'll gladly add it.

# Lightweight mode (under development)

If your program only needs the language code to pass it through to something that only employs strings (e.g. to directly create a , it may
be useful to `use` the module in `:light` mode.
Instead of receiving a `LanguageTag` object, you will get a `Str` that can be passed into other modules.

# Version History

- 0.4.0 
  - Moved individual OS versions into separate submodules.  This will be more maintainable long term
  - Adjusted OS detection for macOS (Rakudo no longer reports it as `macosx` but rather `macos`)
  - Completely rewritten Mac code to support some extended attributes.
    - Sets up a model for using NativeCall when possible, and falling back to a slower method if not (Windows will eventually adopt a similar approach)
- 0.3
  - Cache language(s) on first call to `user-language[s]`  
    This should provide a substantial speed up for modules like `Intl::*` that call this frequently as a fall back.

# Licenses and Legal Stuff

This module is licensed under the Artistic License 2.0 which is included
with the source.  Camelia (the butterfly) is a trademark belonging to
Larry Walls and used in accordance with his terms.