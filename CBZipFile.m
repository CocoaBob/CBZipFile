//
//  CBZipFile.m
//  CBZipFile
//
//  Created by CocoaBob on 18/09/13.
//  Copyright (c) 2013 CocoaBob. All rights reserved.
//

#import "CBZipFile.h"

static const unsigned int BUFFER_SIZE = 8192;

static int CaseInsensitiveComparer (unzFile file, const char *filename1, const char *filename2) {
    return strcasecmp(filename1,filename2);
}

@interface CBZipFile ()

@property (nonatomic, strong) NSMutableDictionary *hashTable;

@end

@implementation CBZipFile {
	unzFile _unzipFile;
    dispatch_queue_t _workingQueue;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (self) {
        _hashTable = [[decoder decodeObjectForKey:@"hashTable"] mutableCopy];
        _path = [decoder decodeObjectForKey:@"path"];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder {
    if (![coder isKindOfClass:[NSKeyedArchiver class]]) {
        [NSException raise:NSInvalidArchiveOperationException
                    format:@"Only supports NSKeyedArchiver coders"];
        return;
    }

    [coder encodeObject:_hashTable forKey:@"hashTable"];
    [coder encodeObject:_path forKey:@"path"];
}

- (instancetype)initWithFileAtPath:(NSString *)filePath {
	NSAssert(filePath, @"path");

    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
        return nil;
    
	if (self = [super init]) {
		_path = filePath;
		_unzipFile = NULL;
	}
	return self;
}

- (BOOL)open {
	NSAssert(!_unzipFile, @"!_unzipFile");

    void (^Block)(void) = ^void (void) {
        _unzipFile = unzOpen64([_path UTF8String]);
    };

    dispatch_sync([self workingQueue], ^{
        Block();
    });
    return _unzipFile != NULL;
}

- (BOOL)isOpen {
    return _unzipFile != NULL;
}

- (void)close {
	NSAssert(_unzipFile, @"_unzipFile");

    void (^Block)(void) = ^void (void) {
        unzClose(_unzipFile);
        _unzipFile = NULL;
    };

    dispatch_sync([self workingQueue], ^{
        Block();
    });
}

- (void)buildHashTable {
	NSAssert(_unzipFile, @"_unzipFile");

    void (^Block)(void) = ^void (void) {
        if (!self.hashTable) {
            NSMutableDictionary *tempHashTable = [@{} mutableCopy];
            int err = unzGoToFirstFile(_unzipFile);
            while (err == UNZ_OK && err != UNZ_END_OF_LIST_OF_FILE) {
                char fileName[PATH_MAX];
                if (unzGetCurrentFileInfo64(_unzipFile, NULL, fileName, PATH_MAX, NULL, 0, NULL, 0) == UNZ_OK) {
                    unz64_file_pos file_pos;
                    if (unzGetFilePos64(_unzipFile, &file_pos) == UNZ_OK) {
                        NSData *fileInfoData = [NSData dataWithBytes:&file_pos length:sizeof(unz64_file_pos)];
                        if (fileInfoData)
                            [tempHashTable setObject:fileInfoData forKey:@(fileName)];

                    }
                }
                err = unzGoToNextFile(_unzipFile);
            }
            self.hashTable = tempHashTable;
        }
    };

    dispatch_sync([self workingQueue], ^{
        Block();
    });
}

- (BOOL)hasHashTable {
    return self.hashTable != nil;
}

- (NSArray *)fileNames {
	if (_hashTable) {
        return [_hashTable allKeys];
    }
    else {
        NSAssert(_unzipFile, @"_unzipFile");

        NSMutableArray *results = [@[] mutableCopy];

        void (^Block)(void) = ^void (void) {
            int err = unzGoToFirstFile(_unzipFile);
            while (err == UNZ_OK && err != UNZ_END_OF_LIST_OF_FILE) {
                int error = unzGoToNextFile(_unzipFile);
                char fileName[PATH_MAX];
                if (unzGetCurrentFileInfo(_unzipFile, NULL, fileName, PATH_MAX, NULL, 0, NULL, 0) == UNZ_OK){
                    [results addObject:@(fileName)];
                }
            }
        };

        dispatch_sync([self workingQueue], ^{
            Block();
        });

        return results;
    }
}

- (NSString *)firstFileName {
	NSAssert(_unzipFile, @"_unzipFile");

    __block NSString *returnValue = nil;

    void (^Block)(void) = ^void (void) {
        if (unzGoToFirstFile(_unzipFile) == UNZ_OK) {
            char fileName[PATH_MAX];
            if (unzGetCurrentFileInfo(_unzipFile, NULL, fileName, PATH_MAX, NULL, 0, NULL, 0) == UNZ_OK) {
                returnValue = @(fileName);
            }
        }
    };

    dispatch_sync([self workingQueue], ^{
        Block();
    });

    return returnValue;
}

- (BOOL)fileExistsWithName:(NSString *)fileName caseSensitive:(BOOL)caseSensitive {
	NSAssert(fileName, @"fileName");

    __block BOOL returnValue = NO;
    if (_hashTable) {
        [[self fileNames] enumerateObjectsWithOptions:NSEnumerationConcurrent
                                           usingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
                                               if (caseSensitive?
                                                   [obj isEqualToString:fileName]:
                                                   ([obj caseInsensitiveCompare:fileName] == NSOrderedSame)) {
                                                   returnValue = *stop = YES;
                                               }
                                           }];
    }
    else {
        NSAssert(_unzipFile, @"_unzipFile");

        void (^Block)(void) = ^void (void) {
            returnValue = (unzLocateFile(_unzipFile, [fileName UTF8String], caseSensitive?NULL:CaseInsensitiveComparer) == UNZ_OK)?YES:NO;
        };

        dispatch_sync([self workingQueue], ^{
            Block();
        });
    }
	return returnValue;
}

- (NSArray *)subpathsAtPath:(NSString *)path {
	NSAssert(path, @"path");

    NSUInteger pathLengh = [path length];
	NSMutableArray *returnValue = [@[] mutableCopy];

    if (_hashTable) {
        [[self fileNames] enumerateObjectsWithOptions:NSEnumerationConcurrent
                                           usingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
                                               if ([obj length] > pathLengh && [obj hasPrefix:path]) {
                                                   [returnValue addObject:obj];
                                               }
                                           }];
    }
    else {
        NSAssert(_unzipFile, @"_unzipFile");

        void (^Block)(void) = ^void (void) {
            int err = unzLocateFile(_unzipFile, [path UTF8String], NULL);
            while (err == UNZ_OK && err != UNZ_END_OF_LIST_OF_FILE) {
                int error = unzGoToNextFile(_unzipFile);
                char fileName[PATH_MAX];
                if (unzGetCurrentFileInfo(_unzipFile, NULL, fileName, PATH_MAX, NULL, 0, NULL, 0) == UNZ_OK){
                    NSString *currentPath = @(fileName);
                    if ([currentPath length] > pathLengh && [currentPath hasPrefix:path]) {
                        [returnValue addObject:currentPath];
                    }
                }
            }
        };

        dispatch_sync([self workingQueue], ^{
            Block();
        });
    }
	return ([returnValue count] > 0)?returnValue:nil;
}

- (NSData *)readCurrentFile:(NSUInteger)maxLength {
	NSAssert(_unzipFile, @"_unzipFile");
    
    if (unzOpenCurrentFile(_unzipFile) == UNZ_OK) {
        NSMutableData *data = [NSMutableData data];
        NSUInteger length = 0;
        void *buffer = (void *)malloc(BUFFER_SIZE);
        while (YES) {
            unsigned size = length + BUFFER_SIZE <= maxLength ? BUFFER_SIZE : maxLength - length;
            int readLength = unzReadCurrentFile(_unzipFile, buffer, size);
            if (readLength < 0) {
                free(buffer);
                unzCloseCurrentFile(_unzipFile);
                return nil;
            }
            if (readLength > 0) {
                [data appendBytes:buffer length:readLength];
                length += readLength;
            }
            if (readLength == 0) {
                break;
            }
        };
        free(buffer);
        
        unzCloseCurrentFile(_unzipFile);
        
        return data;
    }
    return nil;
}

- (NSData *)readWithFileName:(NSString *)fileName caseSensitive:(BOOL)caseSensitive maxLength:(NSUInteger)maxLength {
	NSAssert(_unzipFile, @"_unzipFile");
	NSAssert(fileName, @"fileName");

    __block NSData *returnValue = nil;
    void (^Block)(void) = ^void (void) {
        if (_hashTable) {
            __block NSString *_fileName = fileName;
            if (!caseSensitive) {
                [[self fileNames] enumerateObjectsWithOptions:NSEnumerationConcurrent
                                                   usingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
                                                       if ([obj caseInsensitiveCompare:fileName] == NSOrderedSame) {
                                                           _fileName = obj;
                                                           *stop = YES;
                                                       }
                                                   }];
            }
            NSData *data = _hashTable[_fileName];

            if (data) {
                unz64_file_pos file_pos;
                [data getBytes:&file_pos];
                if (&file_pos != NULL) {
                    if (unzGoToFilePos64(_unzipFile, &file_pos) == UNZ_OK) {
                        returnValue = [self readCurrentFile:maxLength];
                    }
                }
            }
        }
        else {
            if (unzLocateFile(_unzipFile, [fileName UTF8String], caseSensitive?NULL:CaseInsensitiveComparer) == UNZ_OK) {
                returnValue = [self readCurrentFile:maxLength];
            }
        }
    };

    dispatch_sync([self workingQueue], ^{
        Block();
    });

    return returnValue;
}

#pragma mark - Thread Safety

- (dispatch_queue_t)workingQueue {
    if (!_workingQueue) {
        const char *label = [[NSString stringWithFormat:@"CBZipFileWorkingQueue_%@",_path] UTF8String];
        _workingQueue = dispatch_queue_create(label, DISPATCH_QUEUE_SERIAL);
    }
    return _workingQueue;
}

@end