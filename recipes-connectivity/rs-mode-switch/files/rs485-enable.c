/*
 * rs485-enable.c
 * 
 * Usage: rs485-enable /dev/ttyLPX
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
    
    if (argc != 2) {
        fprintf(stderr, "Usage: %s /dev/ttyLPX\n", argv[0]);
        fprintf(stderr, "Example: %s /dev/ttyLP6\n", argv[0]);
        return 1;
    }
    
    /* Open with O_NONBLOCK to prevent blocking on CTS */
    fd = open(argv[1], O_RDWR | O_NOCTTY | O_NONBLOCK);
    if (fd < 0) {
        fprintf(stderr, "Error: Unable to open %s: %s\n", argv[1], strerror(errno));
        return 1;
    }
    
    /* First, disable hardware flow control (might be left enabled from RS232 mode) */
    if (tcgetattr(fd, &tty) == 0) {
        tty.c_cflag &= ~CRTSCTS;  /* Disable CTS/RTS flow control */
        if (tcsetattr(fd, TCSANOW, &tty) < 0) {
            fprintf(stderr, "Warning: Failed to disable flow control: %s\n", strerror(errno));
        }
    }
    
    memset(&rs485conf, 0, sizeof(rs485conf));
    
    /* Enable RS485 mode */
    rs485conf.flags = SER_RS485_ENABLED | SER_RS485_RTS_ON_SEND;
    rs485conf.delay_rts_before_send = 1;
    rs485conf.delay_rts_after_send = 1;
    
    if (ioctl(fd, TIOCSRS485, &rs485conf) < 0) {
        fprintf(stderr, "Error: Failed to enable RS485 mode: %s\n", strerror(errno));
        close(fd);
        return 1;
    }
    
    printf("RS485 mode enabled on %s\n", argv[1]);
    printf("Configuration:\n");
    printf("  - Half-duplex operation\n");
    printf("  - RTS controls transmit enable (active high)\n");
    printf("  - Delay before send: %d ms\n", rs485conf.delay_rts_before_send);
    printf("  - Delay after send: %d ms\n", rs485conf.delay_rts_after_send);
    printf("  - Receiver disabled during transmit (no echo)\n");
    printf("  - Hardware flow control disabled\n");
    
    /* Remove O_NONBLOCK before closing */
    int flags = fcntl(fd, F_GETFL, 0);
    fcntl(fd, F_SETFL, flags & ~O_NONBLOCK);
    
    close(fd);
    return 0;
}