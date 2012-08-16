#ifndef stud_h
#define stud_h

#include <sys/types.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <netdb.h>
#include <sys/wait.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <getopt.h>
#include <limits.h>

#include <sched.h>

#include <openssl/x509.h>
#include <openssl/ssl.h>
#include <openssl/err.h>
#include <ev.h>

#include "ringbuffer.h"

#ifdef PROTO_HTTP
#include "proto_http.h"
#endif

/* Command line Options */
typedef enum {
    ENC_TLS,
    ENC_SSL
} ENC_TYPE;

/* What agent/state requests the shutdown--for proper half-closed
 * handling */
typedef enum _SHUTDOWN_REQUESTOR {
    SHUTDOWN_HARD,
    SHUTDOWN_DOWN,
    SHUTDOWN_UP
} SHUTDOWN_REQUESTOR;

/*
 * Proxied State
 *
 * All state associated with one proxied connection
 */
typedef struct proxystate {
    ringbuffer ring_down; /* pushing bytes from client to backend */
    ringbuffer ring_up;   /* pushing bytes from backend to client */

    ev_io ev_r_up;        /* Upstream write event */
    ev_io ev_w_up;        /* Upstream read event */

    ev_io ev_r_handshake; /* Downstream write event */
    ev_io ev_w_handshake; /* Downstream read event */

    ev_io ev_r_down;      /* Downstream write event */
    ev_io ev_w_down;      /* Downstream read event */

    int fd_up;            /* Upstream (client) socket */
    int fd_down;          /* Downstream (backend) socket */

    int want_shutdown;    /* Connection is half-shutdown */

    SSL *ssl;             /* OpenSSL SSL state */

#ifdef PROTO_HTTP
    struct proto_http ph;
#endif

    struct sockaddr_storage remote_ip;  /* Remote ip returned from `accept` */
} proxystate;

#endif
