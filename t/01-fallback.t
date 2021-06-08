use Test;
use Intl::UserLanguage 'es-CL', 'pt-PT';
.say for user-languages.list;
.say for user-languages(<ar ja-JP>);

done-testing;
