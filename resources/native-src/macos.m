#import <Foundation/Foundation.h>

/* Compile using gcc -framework Foundation -x objective-c mac.c */
char* mac_native() {
    /* Pool needed for garbage collection */
    id pool=[NSAutoreleasePool new];

    /* NSLog(@"%@", [[NSProcessInfo processInfo] arguments]); */

    NSString *str = @"Hello, World";

    /* Obtain the user's current locale */
    NSLocale *locale = [NSLocale currentLocale];

    /*NSString *language = [locale objectForKey: NSLocaleCountryCode]*/
    NSString *language = [locale languageCode];
    NSString *region   = [locale  countryCode];
    NSString *script   = [locale   scriptCode];
    NSString *variant  = [locale  variantCode];

    NSString *calendar  = [locale  calendarIdentifier];
    NSString *collation = [locale collationIdentifier];
    NSString *collator  = [locale  collatorIdentifier];
    NSString *measure   = [locale   objectForKey: NSLocaleMeasurementSystem];

    /*fprintf(stdout, "%s", [measure UTF8String]);*/

    /* End using the pool */
    [pool drain];

    return [measure UTF8String];
}