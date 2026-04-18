#include "pty_helper.h"
#include <util.h>
#include <sys/ioctl.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>

pid_t pty_start(int *master_fd, unsigned short rows, unsigned short cols,
                const char *shell, const char *working_dir) {
    struct winsize ws;
    ws.ws_row = rows;
    ws.ws_col = cols;
    ws.ws_xpixel = 0;
    ws.ws_ypixel = 0;

    pid_t pid = forkpty(master_fd, NULL, NULL, &ws);
    if (pid == 0) {
        /* Child process */

        /* Reset signal handlers */
        signal(SIGINT, SIG_DFL);
        signal(SIGQUIT, SIG_DFL);
        signal(SIGTSTP, SIG_DFL);
        signal(SIGTTIN, SIG_DFL);
        signal(SIGTTOU, SIG_DFL);
        signal(SIGCHLD, SIG_DFL);

        if (working_dir) {
            chdir(working_dir);
        }

        setenv("TERM", "xterm-256color", 1);
        setenv("COLORTERM", "truecolor", 1);
        setenv("LANG", "en_US.UTF-8", 1);
        setenv("LC_ALL", "en_US.UTF-8", 1);

        /* Suppress Apple system framework noise */
        setenv("OS_ACTIVITY_MODE", "disable", 1);

        execl(shell, shell, "--login", (char *)NULL);
        _exit(1);
    }
    return pid;
}

int pty_resize(int fd, unsigned short rows, unsigned short cols) {
    struct winsize ws;
    ws.ws_row = rows;
    ws.ws_col = cols;
    ws.ws_xpixel = 0;
    ws.ws_ypixel = 0;
    return ioctl(fd, TIOCSWINSZ, &ws);
}
