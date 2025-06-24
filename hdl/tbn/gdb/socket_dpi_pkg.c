///////////////////////////////////////////////////////////////////////////////
// socket
//
// Copyright 2025 Iztok Jeras <iztok.jeras@gmail.com>
//
// Licensed under CERN-OHL-P v2 or later
///////////////////////////////////////////////////////////////////////////////

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <errno.h>

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>

#include "svdpi.h"

#ifdef __cplusplus
extern "C" {
#endif

int test (int val) {
    return val+1;
}

int server_start(const char* name) {
  struct sockaddr_un server;

  printf("Creating socket %s\n", name);
  // check file name length
  if (strlen(name) == 0 || strlen(name) > sizeof(server.sun_path)-1) {
    printf("Server socket path too long: %s\n", name);
    return -1;
  }

  // delete socket file if it exists
  if (remove(name) == -1 && errno != ENOENT) {
    printf("failed to remove file %s\n", name);
  }

  int sfd = socket(AF_UNIX, SOCK_STREAM, 0);
  printf("Socket fd = %d\n", sfd);

  memset(&server, 0, sizeof(struct sockaddr_un));
  server.sun_family = AF_UNIX;
  strncpy(server.sun_path, name, sizeof(server.sun_path) - 1);

  if (bind(sfd, (struct sockaddr *) &server, sizeof(struct sockaddr_un)) == -1) {
    printf("Bind failed with errno = %0d.\n", errno);
    return -1;
  }

  if (listen(sfd, 5) == -1) {
    printf("Listen failed.\n");
    return -1;
  }

  printf("Waiting for client to connect...\n");
  int cfd = accept(sfd, NULL, NULL);
  printf("Accepted connection fd = %d\n", cfd);

  return cfd;
}

int server_stop (int fd) {
  return close(fd);
}

int server_send (int fd, const svOpenArrayHandle data, int flags) {
  int status;
  status = send(fd, svGetArrayPtr(data), svSizeOfArray(data), flags);
  if (status == -1) {
    // https://en.wikipedia.org/wiki/Errno.h
    printf("SEND failed with errno = %0d.\n", errno);
    return -1;
  }
  return status;
}

int server_recv (int fd, const svOpenArrayHandle data, int flags) {
  int status;
  status = recv(fd, svGetArrayPtr(data), svSizeOfArray(data), flags);
  if (status == -1) {
    // https://en.wikipedia.org/wiki/Errno.h
    printf("RECV failed with errno = %0d.\n", errno);
    return -1;
  }
  return status;
}

#ifdef __cplusplus
}
#endif
