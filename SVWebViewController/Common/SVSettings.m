//
//  SVSettings.m
//  Videohog-iOS
//
//  Created by Ben Pettit on 20/06/13.
//  Copyright (c) 2013 Digimulti PTY LTD. All rights reserved.
//

#import "SVSettings.h"

#import <objc/runtime.h>
#import <objc/message.h>

@implementation SVSettings

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    for (NSString *key in [self propertyKeys]) {
        id value = [self valueForKey:key];
        [aCoder encodeObject:value forKey:key];
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [self init])) {
        for (NSString *key in [self propertyKeys]) {
            id value = [aDecoder decodeObjectForKey:key];
            [self setValue:value forKey:key];
        }
    }
    
    return self;
}

#pragma mark - Function to populate an array consisting of the object's properties.

- (NSArray *)propertyKeys
{
    NSMutableArray *array = [NSMutableArray array];
    Class class = [self class];
    while (class != [NSObject class]) {
        unsigned int propertyCount;
        objc_property_t *properties = class_copyPropertyList(class, &propertyCount);
        for (int i = 0; i < propertyCount; i++) {
                //get property
            objc_property_t property = properties[i];
            const char *propertyName = property_getName(property);
            NSString *key = [NSString stringWithCString:propertyName encoding:NSUTF8StringEncoding];
            
                //check if read-only
            BOOL readonly = NO;
            const char *attributes = property_getAttributes(property);
            NSString *encoding = [NSString stringWithCString:attributes encoding:NSUTF8StringEncoding];
            NSArray *encodingComponents = [encoding componentsSeparatedByString:@","];
            if ([encodingComponents containsObject:@"R"]) {
                readonly = YES;
                
                    //see if there is a backing ivar with a KVC-compliant name
                NSRange iVarRange = [encoding rangeOfString:@",V"];
                if (iVarRange.location != NSNotFound) {
                    NSString *iVarName = [encoding substringFromIndex:iVarRange.location + 2];
                    if ([iVarName isEqualToString:key] ||
                        [iVarName isEqualToString:[@"_" stringByAppendingString:key]]) {
                            //setValue:forKey: will still work
                        readonly = NO;
                    }
                }
            }
            
            if (!readonly) {
                    //exclude read-only properties
                [array addObject:key];
            }
        }
        free(properties);
        class = [class superclass];
    }
    return array;
}

@end
