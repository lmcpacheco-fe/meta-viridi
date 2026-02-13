/*
 * rs232-enable.c
 * 
 * Usage: rs232-enable /dev/ttyLPX [crtscts]
 */

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/serial.h>
#include <termios.h>
#include <string.h>
#include <errno.h>

int main(int argc, char *argv[]) {
    int fd;
    struct serial_rs485 rs485conf;
    struct termios tty;
    int enable_flow = 0;
    
    if (argc < 2 || argc > 3) {
        fprintf(stderr, "Usage: %s /dev/ttyLPX [crtscts]\n", argv[0]);
        return 1;
    }
    
    if (argc == 3 && strcmp(argv[2], "crtscts") == 0) {
        enable_flow = 1;
    }
    
    /* Open with O_NONBLOCK to prevent blocking on CTS */
    fd = open(argv[1], O_RDWR | O_NOCTTY | O_NONBLOCK);
    if (fd < 0) {
        fprintf(stderr, "Error: Unable to open %s: %s\n", argv[1], strerror(errno));
        return 1;
    }
    
    /* Disable RS485 mode */
    memset(&rs485conf, 0, sizeof(rs485conf));
    rs485conf.flags = 0;
    
    if (ioctl(fd, TIOCSRS485, &rs485conf) < 0) {
        fprintf(stderr, "Error: Failed to disable RS485 mode: %s\n", strerror(errno));
        close(fd);
        return 1;
    }
    
    printf("RS232 mode enabled on %s\n", argv[1]);
    
    /* Get current terminal settings */
    if (tcgetattr(fd, &tty) < 0) {
        fprintf(stderr, "Warning: Failed to get terminal attributes: %s\n", strerror(errno));
        close(fd);
        return 1;
    }
    
    /* Configure hardware flow control */
    if (enable_flow) {
        tty.c_cflag |= CRTSCTS;
        printf("Hardware flow control (CTS/RTS) enabled\n");
    } else {
        tty.c_cflag &= ~CRTSCTS;
        printf("Hardware flow control disabled\n");
    }
    
    /* Apply settings */
    if (tcsetattr(fd, TCSANOW, &tty) < 0) {
        fprintf(stderr, "Error: Failed to set terminal attributes: %s\n", strerror(errno));
        close(fd);
        return 1;
    }
    
    printf("  Configuration:\n");
    printf("    - Full-duplex operation\n");
    if (enable_flow) {
        printf("    - RTS/CTS for flow control\n");
        printf("  Warning: Ensure CTS line is properly connected or tied high\n");
    } else {
        printf("    - No hardware flow control\n");
        printf("  Note: Use '%s %s crtscts' to enable flow control\n", argv[0], argv[1]);
    }
    
    /* Remove O_NONBLOCK flag before closing */
    int flags = fcntl(fd, F_GETFL, 0);
    fcntl(fd, F_SETFL, flags & ~O_NONBLOCK);
    
    close(fd);
    return 0;
}
