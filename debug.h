/*
 *  debug.h
 *  GPG Checker
 *
 *  Created by Sven-S. Porst on Wed Jan 16 2002.
 *  Copyright (c) 2001 earthlingsoft. All rights reserved.
 *
*/


#define debugbuild

#ifdef debugbuild
#define debugLog NSLog
#else
#define debugLog
#endif
