/////////////////////////////////////////////////////////////////////
//                                                                 //
// file: aDirectory.h                                              //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
// description: Directory utilities.                               //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
// Copyright (c) 2018 Acroname Inc. - All Rights Reserved          //
//                                                                 //
// This file is part of the BrainStem release. See the license.txt //
// file included with this package or go to                        //
// https://acroname.com/software/brainstem-development-kit         //
// for full license details.                                       //
/////////////////////////////////////////////////////////////////////

//
//  aDirectory.h
//  Updater
//
//  Created by acroname on 11/5/15.
//  Copyright (c) 2015 acroname. All rights reserved.
//

#ifndef _aDirectory_H_
#define _aDirectory_H_

#include "aDefs.h"
#include "aError.h"

#ifdef __cplusplus
extern "C" {
#endif
    
    extern const char *aDIR_PATH_SEP;

    //
    // Checks the path given to verify it is a valid directory
    //      Returns true if the path exists and the path is to a directory
    //
    aLIBEXPORT bool aDirectory_Exists(const char* dirPath);
    
    //
    // Ensure that the directory exists
    //      If the directory 'dirPath' does not exist, it is created.
    //      On Unix systems, the directory is created using 'createMode' permissions.
    //      On Windows systems, the 'createMode' parameter is ignored.
    //
    aLIBEXPORT aErr aDirectory_Ensure(const char* dirPath, uint16_t createMode);

    //
    // Data structure passed to callback routine for enumeration of directory entries
    //
    typedef struct aDirectoryListData {
        char        *file_name; // full path name to file
        uint32_t	file_size;  // number of bytes of data in file
        uint32_t    file_type;  // DIR or FILE
    } aDirectoryListData;

    //
    // Constants passed to callback routine for enumeration of directory entries
    //
    typedef enum aDirectoryFileType {
        aDIRECTORY = 1, /**< Perform a seek from the beginning of the file. */
        aFILE = 0
    } aDirectoryFileType;
    

    //
    // Callback routine for enumeration of directory entries
    //
    typedef bool (*aDirectoryListProc)(const aDirectoryListData* file_attr, void* vpRef);

    //
    // Enumerate the list of entries in the given directory
    //      The callback routine is called once for each entry in the directory
    //
    aLIBEXPORT aErr aDirectory_List(const char* dirPath, aDirectoryListProc listProc, void* vpRef);
    
    //
    // Delete the direcory at the given path.
    //      - Directory must be empty to be deleted
    //
    aLIBEXPORT aErr aDirectory_Delete(const char* dirPath);
    
    //
    // Delete the direcory tree starting at the given path.
    //      If directory is not empty, files are "unlink"-ed and
    //      aDirectory_DeleteTree is called recursively on each directory
    //
    // !!! dangerous - will delete all files in all directories !!!
    //
    aLIBEXPORT aErr aDirectory_DeleteTree(const char* dirPath);

    //
    // Path functions
    //
    
    //
    // Get Current Working Directory
    //
    aLIBEXPORT aErr aDirectory_CWD(char* dirPath, const size_t maxPathLen);
    
    //
    // Get the path to the executable currently running
    //
    aLIBEXPORT aErr aDirectory_ExecutableFilePath(char* dirPath, const size_t maxPathLen);
    
    //
    // Get the home directory of the current user
    //
    aLIBEXPORT aErr aDirectory_GetHomeDirectory(char* dirPath, const size_t maxPathLen);
    
    //
    // Build a path from path and filename arguments.
    //
    // Example:
    //      aDirectory_JoinPath(joinedPath, joinedMaxLength, "home_directory", "file.ext", NULL);
    //
    //  Unix systems produce: "home_directory/file.ext"
    //
    //  Windows systems produce: "home_directory\file.ext"
    //
    aLIBEXPORT aErr aDirectory_JoinPath(char* joinedPath, const size_t joinedMaxLength, const char* path, const char* subPath);
    
    //
    // Build a path from multiple arguments.
    // !!! Variable parameter list MUST end with parameter 'NULL' !!!
    //
    // Example:
    //      aDirectory_BuildPath(joinedPath, joinedMaxLength, aDIR_PATH_SEP, "home_directory", ".acroname", "Updater", "device1", "settings.txt", NULL);
    //
    //  Unix systems produce: "/home_directory/.acroname/Updater/device1/settings.txt"
    //
    //  Windows systems produce: "\home_directory\.acroname\Updater\device1\settings.txt"
    //
    aLIBEXPORT aErr aDirectory_BuildPath(char *joinedPath, const size_t joinedMaxLength, const char *arg1, ...);
    

#ifdef __cplusplus
}
#endif


#endif /* defined(_aDirectory_H_) */
