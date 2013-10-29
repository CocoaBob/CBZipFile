CBZipFile
=========

CBZipFile is a Cocoa wrapper of minizip to read zip packages, it's thread-safe and particularly optimized for random accessing.

Getting started
===============

1. Get minizip.

    [Official web site](http://www.winimage.com/zLibDll/minizip.html)

    [GitHub mirror](https://github.com/nmoinvaz/minizip)
    
2. Add the following files to your project.
	* ioapi.c
	* ioapi.h
	* unzip.c
	* unzip.h

3. Add libz.dylib to your __Link Binary With Libraries__ project build phase.

4. Add CBZipFile.h/.m to your project.

How to use CBZipFile
==================

```Objective-C

// Initialize a zip file
CBZipFile *zipFile = [[CBZipFile alloc] initWithFileAtPath:@"foo.zip"];

// Open the zip file
[zipFile open];

// Get file list
[zipFile fileNames];

// Build hash table to support random access
[zipFile buildHashTable];

// Get file contents
[zipFile readWithFileName:@"bar.jpg" caseSensitive:YES maxLength:NSUIntegerMax];

// Close the zip file
[zipFile close];

```

Compatibilities
===============

Developed with Xcode 5.0, ARC enabled.


License
=======

The MIT License (MIT)

Copyright (c) 2013 CocoaBob

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
