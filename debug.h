/*
 *  debug.h
 *  GPG Checker
 *
 *  Created by Sven-S. Porst on Wed Jan 16 2002.
 *  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
 *
 */


#define debugbuild

#ifdef debugbuild
#define debugLog(X) NSLog(X);
#else
#define debugLog(X)
#endif
