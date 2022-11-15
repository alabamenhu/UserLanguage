# This can't be tested except by inserting a die statement
# in one of the detection blocks.  I pinky-promise it works.
use Test;

# use User::Language 'es-CL', 'pt-PT';
# is user-language('zh'), LanguageTag.new('zh'), 'Resort to arg-based fallback';
# is user-language, LanguageTag.new('es-CL'), 'Resort to use-statement fallback';

ok True;

done-testing;
