#import <Foundation/Foundation.h>
// Compiling from the command line:
//     gcc -framework Foundation -x objective-c -o macos.o macos.m // this does a Linux-style library
//     clang -undefined dynamic_lookup -framework Foundation -dynamiclib -o macos.dylib macos.m // this does a Mac-style dylib
// This should be handled automatically by the build-native.raku script

const char* mac_native() {

    // Pool needed for garbage collection
    id pool=[NSAutoreleasePool new];

    /* NSLog(@"%@", [[NSProcessInfo processInfo] arguments]); */

    NSString *hyphen = @"-";

    // Obtain the user's current locale
    NSLocale *locale = [NSLocale currentLocale];

    // NSString *language = [locale objectForKey: NSLocaleCountryCode]
    // NSString *language = [locale languageCode];
    // NSString *region   = [locale  countryCode];
    // NSString *script   = [locale   scriptCode];
    // NSString *variant  = [locale  variantCode];

    NSString  *measure  =  [locale objectForKey: NSLocaleMeasurementSystem];
    NSString  *calendar =  [locale calendarIdentifier];
    NSUInteger firstDay = [[locale objectForKey:NSLocaleCalendar] firstWeekday];
    NSString  *collator = [[locale collatorIdentifier] rangeOfString:@"@collation"].location == NSNotFound
        ? nil
        : [[locale collatorIdentifier] substringFromIndex: NSMaxRange([[locale collatorIdentifier] rangeOfString:@"@collation"]) + 1];
    //  I'm not sure what collation is and how it's supposed to be materially distinct from collator.
    // We ignore it for now, but should check with new Foundation releases to see if anything here is of use.
    // NSString *collation  = [locale  collationIdentifier];


    NSMutableString *extTag = [NSMutableString stringWithString:@""];

    // BASE TAG
    // This code should be unnecessary, but remains here for the time being.
    //
    // [extTag appendString: language];
    // [extTag appendString:   hyphen];
    // [extTag appendString:   region];
    //
    // if (script != nil) {
    //     [extTag appendString: hyphen];
    //     [extTag appendString: script];
    // }
    // if (variant != nil) {
    //     [extTag appendString:  hyphen];
    //     [extTag appendString: variant];
    // }

    // EXTENSION
    // If any of the extension tags are available, then we add '-u'
    // and then add them in individually. (generally the answer is "yes",
    // but this is just in case)
    if (calendar  != nil
    ||  collator  != nil
    ||  measure   != nil) {
        [extTag appendString: @"-u"];

        /* CALENDAR */
        if (calendar != nil) {
            // Add the initial subtag for calendar
            [extTag appendString: @"-ca-"];

            if      ([calendar isEqualToString:@"gregorian"          ]) { [extTag appendString: @"gregory"      ]; }
            else if ([calendar isEqualToString:@"ethiopic-amete-alem"]) { [extTag appendString: @"ethioaa"      ]; }
            else if ([calendar isEqualToString:@"islamicc"           ]) { [extTag appendString: @"islamic-civil"]; }
            else                                                        { [extTag appendString:   calendar      ]; }

            // FIRST DAY OF THE WEEK
            [extTag appendString: @"-fw-"];
            NSString* weekDayNames[] = { @"sun", @"mon", @"tue", @"wed", @"thu", @"fri", @"sat"};
            [extTag appendString: weekDayNames[firstDay - 1]];
        }


        // COLLATOR
        if (collator != nil) {
            [extTag appendString: @"-co-"];

            if      ([collator isEqualToString:@"dictionary" ]) { [extTag appendString: @"dict"    ]; }
            else if ([collator isEqualToString:@"gb2312han"  ]) { [extTag appendString: @"gb2313"  ]; }
            else if ([collator isEqualToString:@"phonebook"  ]) { [extTag appendString: @"phonebk" ]; }
            else if ([collator isEqualToString:@"traditional"]) { [extTag appendString: @"trad"    ]; }
            else                                                { [extTag appendString:   collator ]; }
        }
        // MEASUREMENT SYSTEM
        if (measure != nil) {
            [extTag appendString: @"-ms-"];

            if      ([measure isEqualToString:@"U.S."  ]) { [extTag appendString: @"ussystem"]; }
            else if ([measure isEqualToString:@"U.K."  ]) { [extTag appendString: @"uksystem"]; }
            else if ([measure isEqualToString:@"metric"]) { [extTag appendString: @"metric"  ]; }
            else                                          { [extTag appendString:   measure  ]; }
        }
    }


    // The list of languages provided by preferredLanguages is, thankfully,
    // actually regular old BCP-47 tags and include script information for
    // dual script languages like Chinese.
    NSArray<NSString*> *languageList = [NSLocale preferredLanguages];

    // Join up each of the language tags with a ';' delimiter, but first
    // add on the extended tag information.  Unfortunately, on the Mac,
    // this information is not set on a per-language basis, but rather
    // system-wide.  This is why we can semi-cheat and add the same extTag
    // to every language on the system.
    NSMutableString* result = [NSMutableString stringWithString:@""];
    BOOL isContinuation = NO;

    for (NSString* languageAndRegion in languageList) {

        if (isContinuation) {
            [result appendString: @";"];
        }

        [result appendString: languageAndRegion];
        if ([extTag length] != 0) {
            [result appendString: extTag];
        }

        isContinuation = YES;
    }

    // Returning the result of [tag UTF8String] can't be done because,
    // per NSString documentation, it's an internal pointer. By making
    // a copy, we guarantee that NativeCall won't end up with deallocated
    // stuff (results in a segmentation fault!)
    //
    // Also, I know it seems weird that I'm creating a flattened string,
    // before grabbing the UTF-8 char[], but there's something off on
    // when things are released and it causes weird/unexpected output
    // otherwise.
    const char* final = [[NSString stringWithString: result] UTF8String];

    // End using the pool
    [pool drain];

    return final;
}

/** MAIN
 * Exists only in case we need to test our code and don't want to have
 * to call it from NativeCall.  It won't ever be called by Raku code.
 * The simplest way to compile this one to test would be
 *    clang -framework Foundation macos.m -o macos_test; ./macos_test
 */
int main() {
    fprintf(
        stdout,
        "Per macOS, the BCP-47 language tag would be '%s'.\n",
        mac_native()
    );
    return 0;
}