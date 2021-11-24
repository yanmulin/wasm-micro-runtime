#include "cwlib.h"
#include <unistd.h>
#include <fcntl.h>
#include <poll.h>

#define BUFSIZE 1024


int g_nfd;
struct pollfd *g_pfds;
bool g_quit_pending = false;

void init(wasm_exec_env_t exec_env, uint32 filenames_offset, int nfd) {
    wasm_module_inst_t module_inst = get_module_inst(exec_env);
    uint32 *argv = (uint32*)wasm_runtime_addr_app_to_native(module_inst, filenames_offset);

    g_pfds = malloc((nfd + 1) * sizeof(struct pollfd));
    if (g_pfds == NULL) {
        perror("malloc");
        exit(1);
    }

    for (int i=0;i<nfd;i++) {
        char *filename = (char*)wasm_runtime_addr_app_to_native(module_inst, argv[i]);
        printf("wamr: opening %s\n", filename);
        g_pfds[i].fd = open(filename, O_RDONLY);
        g_pfds[i].events = POLLRDNORM;
    }

    printf("wamr: opening signalfd\n");
    g_pfds[nfd].fd = open("/tmp/signalfd", O_RDONLY);
    g_pfds[nfd].events = POLLRDNORM;

    g_nfd = nfd + 1;

    char *v = getenv("JTEL"); // Jump to event loop
    if (v) {
        loop(exec_env, 5000);
    }
}

void loop(wasm_exec_env_t exec_env, int sleep_ms) {
    int n;
    char buf[BUFSIZE];
    while (1) {
        printf("wamr: Loop...\n");
        int retval = poll(g_pfds, g_nfd, sleep_ms);
        bool no_fd_input = true;
        if (retval < 0) {
            perror("poll");
            exit(1);
        } else if (retval == 0) {
            printf("wamr: timeout\n");
        } else {
            for (int i=0;retval>0&&i<g_nfd-1;i++) {
                if (g_pfds[i].revents == 0) continue;
                else if (g_pfds[i].revents == POLLRDNORM) {
                    n = read(g_pfds[i].fd, buf, BUFSIZE - 1);
                    if (n == 0) {
                        printf("wamr: close fd %d\n", i);
                    } else {
                        buf[n] = '\0';
                        printf("wamr(fd %d): %s\n", i, buf);
                    }
                }
                retval --;
                no_fd_input = false;
            }
            if (retval > 0 && g_pfds[g_nfd-1].revents == POLLRDNORM) {
                printf("wamr: receive signal\n");
                g_quit_pending = true;
            }
        }

        if (g_quit_pending && no_fd_input) {
            // checkpoint and exit
            printf("wamr: exit\n");
            exit(1);
        }
    }

}