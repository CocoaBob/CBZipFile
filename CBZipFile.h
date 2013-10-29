//
//  CBZipFile.h
//  CBZipFile
//
//  Created by CocoaBob on 18/09/13.
//  Copyright (c) 2013 CocoaBob. All rights reserved.
//

#import "unzip.h"

/**
 `CBZipFile` is a Cocoa wrapper of minizip to read zip packages.
 */
@interface CBZipFile : NSObject

/**
 The file system path where the zip file is located.
 */
@property (nonatomic, readonly) NSString *path;

///-----------------------------------------------
/// @name Initializing
///-----------------------------------------------

/**
 Initializes a new zip file with a file path.

 @param filePath The file system path of the zip file.

 @return A new zip file, or `nil` if the file doesn't exist.

 @warning You can't change the file path after initilizing.
 */
- (instancetype)initWithFileAtPath:(NSString *)filePath;

///-----------------------------------------------
/// @name Opening & Closing
///-----------------------------------------------

/**
 Open the zip file.

 @return `YES` if a zip file is opened successfully. Otherwise, `NO`.

 @note It's thread-safe.

 @warning You can't open a zip file twice. You should check if it's open before opening it.

 @see - isOpen
 */
- (BOOL)open;

/**
 Returns whether or not the zip file is opened.

 @return `YES` if a zip file is open. Otherwise, `NO`.

 @see - open

 @see - close
 */
- (BOOL)isOpen;

/**
 Close the zip file.

 @note It's thread-safe.

 @warning You can't close a zip file twice. You should check if it's open before closing it.

 @see - isOpen
 */
- (void)close;

///-----------------------------------
/// @name Random Access Support
///-----------------------------------

/**
 Build an internal hash table to support random access.

 @discussion It will spend some time to build the hash table, depending on the number of files in the zip file.

 @note It's unnecessary to build the hash table twice.

 @note It's thread-safe.

 @warning You have to open the zip file manually building the hash table.

 @see - open
 */
- (void)buildHashTable;

/**
 Returns whether or not the hash table has already been built.

 @return `YES` if the hash table has been built. Otherwise, `NO`.

 @see - buildHashTable
 */
- (BOOL)hasHashTable;

///-----------------------------------
/// @name Getting Contents
///-----------------------------------

/**
 Return all the file names in the zip file.

 @return An array containing all the file names.

 @discussion If the hash table hasn't been built, it will spend some time to collect all the names, but the names will be in alphabetical order. If the hash table has already been built, it returns instantly, but the file names are in random order.

 @note It's thread-safe.

 @warning If the hash table hasn't been built, you have to open the zip file manually.

 @see - buildHashTable

 @see - open
 */
- (NSArray *)fileNames;

/**
 Return the first file name in the zip file.

 @return A string of the first file's name.

 @note It's thread-safe.

 @warning You have to open the zip file manually.

 @see - open
 */
- (NSString *)firstFileName;

/**
 Check if a given file name exists in the zip file.

 @param fileName The file name which needs to be checked.

 @param caseSensitive If it's a case-sensitive search or not.

 @return `YES` if the given file name exists in the zip file. Otherwise, `NO`.

 @note It's thread-safe.

 @warning If the hash table hasn't been built, you have to open the zip file manually.

 @see - buildHashTable

 @see - open
 */
- (BOOL)fileExistsWithName:(NSString *)fileName caseSensitive:(BOOL)caseSensitive;

/**
 Return all the sub-paths of a given path.

 @param path The path which is going be searched.

 @return An array containing all the sub-paths.

 @note It's thread-safe.

 @warning If the hash table hasn't been built, you have to open the zip file manually.

 @see - buildHashTable

 @see - open
 */
- (NSArray *)subpathsAtPath:(NSString *)path;

/**
 Return the data of a file.

 @param fileName The name of the file.

 @param caseSensitive If it's a case-sensitive search or not.

 @param maxLength The maximum lengh of data to read.

 @return The data of the file or nil if it doesn't exist.

 @note It's thread-safe.

 @note In the case that the zip file contains many files, the performance will be much better if the hash table has been built and if it's case sensitive.

 @warning If the hash table hasn't been built, you have to open the zip file manually.

 @see - buildHashTable

 @see - open
 */
- (NSData *)readWithFileName:(NSString *)fileName caseSensitive:(BOOL)caseSensitive maxLength:(NSUInteger)maxLength;

@end