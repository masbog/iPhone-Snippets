// With SMS text & address contributions from Saurik

#import <UIKit/UIKit.h>
#import <UIKit/UIApplication.h>
#include <notify.h>
#include <stdio.h>
#include <stdarg.h>

#import <CoreTelephony/CoreTelephony.h>

typedef struct __CTSMSMessage CTSMSMessage;
NSString *CTSMSMessageCopyAddress(void *, CTSMSMessage *);
NSString *CTSMSMessageCopyText(void *, CTSMSMessage *);

void dolog(id formatstring,...)
{
   va_list arglist;
   if (formatstring)
   {
     va_start(arglist, formatstring);
     id outstring = [[NSString alloc] initWithFormat:formatstring arguments:arglist];
     printf("%s\n", [outstring UTF8String]);
     va_end(arglist);
   }
}

static void callback(CFNotificationCenterRef center, void *observer, NSString *name, const void *object, NSDictionary *userInfo) {

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    printf("NOTIFICATION: %s\n", [name UTF8String]);
    if (!userInfo) return;

    NSDictionary *info = userInfo;
    int dcount = CFDictionaryGetCount(userInfo);
    id keys = [userInfo allKeys];
    int i;
    for (i = 0; i < dcount; i++)
    {
       id key = [keys objectAtIndex:i];
       dolog(@"  %@: %@", key, [info objectForKey:key]);
    }    
    

    if ([[(NSDictionary *)userInfo allKeys] 
           containsObject:@"kCTSMSMessage"]) // SMS Message 
    {
      CTSMSMessage *message = (CTSMSMessage *) 
         [(NSDictionary *)userInfo objectForKey:@"kCTSMSMessage"];
      NSString *address = CTSMSMessageCopyAddress(NULL, message);
      NSString *text = CTSMSMessageCopyText(NULL, message);
      NSArray *lines = [text componentsSeparatedByString:@"\n"];

      printf("  %s %d\n", [address cString], [lines count]);
      printf("  %s\n", [text cString]);
      fflush(stdout);
    }

    [pool release];

    return 0; 
}

static void signalHandler(int sigraised) {
    printf("\nInterrupted.\n"); exit(0); }

int main(int argc, char **argv)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    // Initialize listener by adding CT Center observer
    extern NSString* const kCTSMSMessageReceivedNotification;
    id ct = CTTelephonyCenterGetDefault();
    CTTelephonyCenterAddObserver(
       ct, 
       NULL, 
       callback,
       NULL,
       NULL,
       CFNotificationSuspensionBehaviorHold);

    // Handle Interrupts
    sig_t oldHandler = signal(SIGINT, signalHandler);
    if (oldHandler == SIG_ERR) {
         printf("Could not establish new signal handler");
	 exit(1); }

    // Run loop lets me catch notifications
    printf("Starting run loop and watching for notification.\n");
    CFRunLoopRun();

    // Shouldn't ever get here. Bzzzt
    printf("Unexpectedly back from CFRunLoopRun()!\n");
}


