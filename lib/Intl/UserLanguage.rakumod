sub EXPORT (|c) {
    use User::Language;
    note  "⎡ The module Intl::UserLanguage has been renamed to User::Language. ⎤\n"
        ~ "⎢ Please use this name in the future. If you received this message  ⎥\n"
        ~ "⎢ without having explicitly used the module, please contact the     ⎥\n"
        ~ "⎢ author whose module called this to have them update accordingly.  ⎥\n"
        ~ "⎢                                                                   ⎥\n"
        ~ "⎢ Please be aware that fallback languages are not supported when    ⎥\n"
        ~ "⎢ calling by the old name for compile time reasons                  ⎥\n"
        ~ "⎢                                                                   ⎥\n"
        ~ "⎢ You may dismiss this by setting the environment variable          ⎥\n"
        ~ "⎢ RAKU_USER_LANGUAGE_NAMECHANGE_WARNING to OFF. Updates after 2024  ⎥\n"
        ~ "⎣ will no longer provide under the old name.                        ⎦"
    unless %*ENV<RAKU_USER_LANGUAGE_NAMECHANGE_WARNING> // '' eq 'OFF';
    Map.new:
        '&user-language'  => &user-language,
        '&user-languages' => &user-languages,

}

my package EXPORT::override {
    use User::Language:auth<zef:guifa> :override;
    OUR::<&clear-user-language-override> = &clear-user-language-override;
    OUR::<&override-user-languages>      = &override-user-languages;
}