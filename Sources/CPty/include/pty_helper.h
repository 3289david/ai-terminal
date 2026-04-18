#ifndef PTY_HELPER_H
#define PTY_HELPER_H

#include <sys/types.h>

/// Fork a new PTY session, exec the given shell in the child process.
/// Returns the child PID to the parent (>0), or -1 on error.
/// The child never returns from this call.
pid_t pty_start(int *master_fd, unsigned short rows, unsigned short cols,
                const char *shell, const char *working_dir);

/// Resize the PTY window.
int pty_resize(int fd, unsigned short rows, unsigned short cols);

#endif
