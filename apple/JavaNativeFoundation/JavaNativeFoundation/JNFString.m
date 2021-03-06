/*
 * Copyright (c) 2008-2020 Apple Inc. All rights reserved.
 *
 * @GPLv2-CPE_LICENSE_HEADER_START@
 *
 * The contents of this file are licensed under the terms of the
 * GNU Public License (version 2 only) with the "Classpath" exception.
 *
 * This code is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 only with
 * classpath exception, as published by the Free Software Foundation.
 *
 * This code is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * version 2 for more details (a copy is included in the LICENSE file that
 * accompanied this code).
 *
 * @GPLv2-CPE_LICENSE_HEADER_END@
 */

#import "JNFString.h"

#import "JNFJNI.h"
#import "JNFAssert.h"
#import "debug.h"

#define STACK_BUFFER_SIZE 64

/*
 * Utility function to convert java String to NSString. We don't go through intermediate cString
 * representation, since we are trying to preserve unicode characters from Java to NSString.
 */
NSString *JNFJavaToNSString(JNIEnv *env, jstring javaString)
{
    // We try very hard to only allocate and memcopy once.
    if (javaString == NULL) return nil;

    jsize length = (*env)->GetStringLength(env, javaString);
    unichar *buffer = (unichar *)calloc((size_t)length, sizeof(unichar));
    (*env)->GetStringRegion(env, javaString, 0, length, buffer);
    NSString *str = (NSString *)CFStringCreateWithCharactersNoCopy(NULL, buffer, length, kCFAllocatorMalloc);
    //	NSLog(@"%@", str);
    return [(NSString *)CFMakeCollectable(str) autorelease];
}

/*
 * Utility function to convert NSString to Java string. We don't go through intermediate cString
 * representation, since we are trying to preserve unicode characters in translation.
 */
jstring JNFNSToJavaString(JNIEnv *env, NSString *nsString)
{
    jstring res = nil;
    if (nsString == nil) return NULL;

    unsigned long length = [nsString length];
    unichar *buffer;
    unichar stackBuffer[STACK_BUFFER_SIZE];
    if (length > STACK_BUFFER_SIZE) {
        buffer = (unichar *)calloc(length, sizeof(unichar));
    } else {
        buffer = stackBuffer;
    }

    JNF_ASSERT_COND(buffer != NULL);
    [nsString getCharacters:buffer];
    res = (*env)->NewString(env, buffer, (jsize)length);
    if (buffer != stackBuffer) free(buffer);
    return res;
}

const unichar *JNFGetStringUTF16UniChars(JNIEnv *env, jstring javaString)
{
    const jchar *unichars = NULL;
    JNF_ASSERT_COND(javaString != NULL);
    unichars = (*env)->GetStringChars(env, javaString, NULL);
    if (unichars == NULL) [JNFException raise:env as:kNullPointerException reason:"unable to obtain characters from GetStringChars"];
    return (const unichar *)unichars;
}

void JNFReleaseStringUTF16UniChars(JNIEnv *env, jstring javaString, const unichar *unichars)
{
    JNF_ASSERT_COND(unichars != NULL);
    (*env)->ReleaseStringChars(env, javaString, (const jchar *)unichars);
}

const char *JNFGetStringUTF8Chars(JNIEnv *env, jstring javaString)
{
    const char *chars = NULL;
    JNF_ASSERT_COND(javaString != NULL);
    chars = (*env)->GetStringUTFChars(env, javaString, NULL);
    if (chars == NULL) [JNFException raise:env as:kNullPointerException reason:"unable to obtain characters from GetStringUTFChars"];
    return chars;
}

void JNFReleaseStringUTF8Chars(JNIEnv *env, jstring javaString, const char *chars)
{
    JNF_ASSERT_COND(chars != NULL);
    (*env)->ReleaseStringUTFChars(env, javaString, (const char *)chars);
}
