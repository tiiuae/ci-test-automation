/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/*                                                                 */
/* file: aSocket.h                                                 */
/*                                                                 */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/*                                                                 */
/* description: General cross-platform socket defines.	           */
/*                                                                 */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/*                                                                 */
/* Copyright (c) 2018 Acroname Inc. - All Rights Reserved          */
/*                                                                 */
/* This file is part of the BrainStem release. See the license.txt */
/* file included with this package or go to                        */
/* https://acroname.com/software/brainstem-development-kit         */
/* for full license details.                                       */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#ifndef _aSocket_H_
#define _aSocket_H_

#ifdef _WIN32 /* Platform is Windows. */

#include <winsock2.h>
#include <Ws2ipdef.h>
#include <stdint.h>
#include <iphlpapi.h>

#define aSOCKET_ERRVAL		WSAGetLastError()
#define aSOCKET_TCP_PROTO	IPPROTO_TCP
#define aSOCKET_BOOL_VAL	u_long
#define aSOCKET_ERR_WOULDBLOCK	WSAEWOULDBLOCK
#define aSOCKET_ERR_TIMEOUT     WSAETIMEDOUT
#define aSOCKET_ERR_CONNREFUSED WSAECONNREFUSED
#define aSOCKET_ERR_CONNRESET   WSAECONNRESET
#define aSOCKET_ERR_NOTCONN     WSAENOTCONN
#define aSOCKET_ERR_PIPE        WSAECONNABORTED
#define aSOCKET_ERR_INPROGRESS  WSAEINPROGRESS
#define aSOCKET_ERR_AGAIN       WSAEWOULDBLOCK
#define aSOCKET_SEND_SIZE       int
#define aSOCKET_LEN_TYPE        int
#define aSOCKET_CLOSE		closesocket
#define aSOCKET_INVALID		INVALID_SOCKET
#define aSOCKET_ERROR		SOCKET_ERROR
#define aSOCKET_IOCTL           ioctlsocket
#define aSOCKET_SHUTDOWN_RDWR   SD_BOTH
#define aSOCKET_MSG_WAITALL     0

#else // Else platform is Mac or Linux.

#include <unistd.h>
#include <errno.h>
#include <sys/socket.h>
#include <netdb.h>
#include <netinet/tcp.h>
#include <netinet/in.h>
#include <net/if.h>
#include <arpa/inet.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <ifaddrs.h>

typedef int32_t SOCKET;
#define aSOCKET_ERRVAL		errno
#define aSOCKET_TCP_PROTO	(getprotobyname("TCP")->p_proto)
#define aSOCKET_BOOL_VAL	int
#define aSOCKET_ERR_WOULDBLOCK	EWOULDBLOCK
#define aSOCKET_ERR_TIMEOUT     ETIMEDOUT
#define aSOCKET_ERR_CONNREFUSED ECONNREFUSED
#define aSOCKET_ERR_CONNRESET   ECONNRESET
#define aSOCKET_ERR_NOTCONN     ENOTCONN
#define aSOCKET_ERR_PIPE        EPIPE
#define aSOCKET_ERR_INPROGRESS  EINPROGRESS
#define aSOCKET_ERR_AGAIN       EAGAIN
#define aSOCKET_SEND_SIZE       ssize_t
#define aSOCKET_LEN_TYPE        unsigned int
#define aSOCKET_CLOSE		close
#define aSOCKET_INVALID		-1
#define aSOCKET_ERROR		-1
#define aSOCKET_IOCTL           ioctl
#define aSOCKET_SHUTDOWN_RDWR   SHUT_RDWR
#define aSOCKET_MSG_WAITALL     MSG_WAITALL

#endif /* End of Platform Specific defines. */

#define aIP4_BROADCAST                                    0xFFFFFFFF
#define aIP4_DISCOVER_MULTICAST                           0xE8020202
#define aIP4_DISCOVER_MULTICAST_NATIVE                    0x020202E8
#define aIP4_DISCOVER_REQUEST_PORT                              9888
#define aIP4_DISCOVER_REPLY_PORT                                9889

#define aIP4DISCOVERY_VERSION                                      1

#define aIPDISCOVERY_FLAG_SIMULATION                      0x00000001

typedef struct aIPDiscoveryInfo {
    uint8_t version;
    uint8_t module;
    uint16_t port;
    uint32_t serialNum;
    uint32_t flags;
    uint8_t model;
} aIPDiscoveryInfo;


#endif /* _aSocket_H_ */
