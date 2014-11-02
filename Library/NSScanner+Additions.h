//
//  NSScanner+Additions.h
//  MFLib
//
//  Created by finucane on 3/20/14.
//
#import <Foundation/Foundation.h>

@interface NSScanner (DFScannerCategory)

-(BOOL) scanPast:(NSString*)s;
-(BOOL) scanFrom:(unsigned)startLocation upTo:(unsigned)stopLocation intoString:(NSString**)aString;
-(BOOL) scanPast:(NSString*)s before:(NSString*)stopString;
-(BOOL) scanPast:(NSString*)s beforeStrings:(NSArray*)strings;

@end
