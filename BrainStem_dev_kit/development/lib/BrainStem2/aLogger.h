/////////////////////////////////////////////////////////////////////
//                                                                 //
// file: aLogger.h                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
// description: Definition for BrainStem packet FIFO queue.        //
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

#ifndef _aLogger_H_
#define _aLogger_H_

#ifndef _aDefs_H_
#include "aDefs.h"
#endif // _aDeft_H_

#include "aError.h"
#include "aPacket.h"
#include "aStream.h"
#include "aLink.h"

typedef void* aLoggerRef;

#ifdef __cplusplus
extern "C" {
#endif

	/////////////////////////////////////////////////////////////////////
	/// Typedef #aLogCallbackProc.

	/**
	* This callback is called to excersize the log function on the logger.
	* It takes a FileRef parameter and a vpRef that represents the subject
	* of the logging.
	*/
	typedef void(*aLogCallbackProc) (aFileRef logfile, aLinkRef vpRef);

	/////////////////////////////////////////////////////////////////////
	/// Create a logger object.

	/**
	* Creates a logger object, that will create and start a thread for
	* logging to a file when it is enabled.
	*
	* \param vpRef  logging subject.
	* \param process Callback for performing the log function given the subject (vpRef).
	* \param filename Log File path and file name.
	*
	* \returns NULL if an error occured creating the output file, or a logger object on success.
	*/
    aLIBEXPORT aLoggerRef aLogger_Create(aLinkRef vpRef, aLogCallbackProc process, const char* filename);
    

	/////////////////////////////////////////////////////////////////////
	/// Enable logging on the logger object.

	/**
	* Starts the Subthread that calls the logCallback, to process log messages.
	*
	* \param logger - The logger to enable.
	*
	* \returns aErrNone on success.
	* \returns various aError if an error occured starting the thread.
	*/
	aLIBEXPORT aErr aLogger_Enable(aLoggerRef logger);


	/////////////////////////////////////////////////////////////////////
	/// Disable logging on the logger object.

	/**
	* Stops the Subthread that calls the logCallback, to process log messages.
	*
	* \param logger - The logger to disable.
	*
	* \returns aErrNone on success.
	* \returns various aError if an error occured stopping the thread.
	*/
	aLIBEXPORT aErr aLogger_Disable(aLoggerRef logger);


	/////////////////////////////////////////////////////////////////////
	/// Destroy the logger.

	/**
	* Destroys a logger reference. deallocating associated resources cleanly.
	*
	* Currently enabled loggers will first be stopped, then the output file handles closed,
	* and the resources deallocated.
	*
	* \param loggerRef  a Pointer to a valid LoggerRef. The loggerRef will be set to
	*                   NULL on succesful completion of the Destroy call.
	* \returns aError aErrNone on success, and various aError values on failure.
	*/

	aLIBEXPORT aErr aLogger_Destroy(aLoggerRef* loggerRef);
    
    
#ifdef __cplusplus
}
#endif

#endif /* _aLogger_H_ */

