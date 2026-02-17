/*
 * check-uart-config.c
 * 
 * Usage: check-uart-config /dev/ttyLPX
 */

#include <stdio.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/serial.h>
#include <termios.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
    int fd;
    struct serial_rs485 rs485;
    struct termios tty;
    
    if (argc != 2) {
        fprintf(stderr, "Usage: %s /dev/ttyLPX\n", argv[0]);
        return 1;
    }
    
    fd = open(argv[1], O_RDWR | O_NOCTTY | O_NONBLOCK);
    if (fd < 0) {
        fprintf(stderr, "Error: Unable to open %s: %s\n", argv[1], strerror(errno));
        return 1;
    }
    
    printf("===========================================\n");
    printf("UART Configuration: %s\n", argv[1]);
    printf("===========================================\n\n");
    
    /* Check RS485 configuration */
    memset(&rs485, 0, sizeof(rs485));
    if (ioctl(fd, TIOCGRS485, &rs485) == 0) {
        printf("RS485 Configuration:\n");
        printf("  Mode:              %s\n", 
               (rs485.flags & SER_RS485_ENABLED) ? "RS485" : "RS232");
        printf("  Flags:             0x%08x\n", rs485.flags);
        if (rs485.flags & SER_RS485_ENABLED) {
            printf("  RTS on send:       %s\n", 
                   (rs485.flags & SER_RS485_RTS_ON_SEND) ? "Yes" : "No");
            printf("  RX during TX:      %s\n", 
                   (rs485.flags & SER_RS485_RX_DURING_TX) ? "Yes (echo)" : "No");
        }
    } else {
        printf("RS485: Not supported\n");
    }
    
    printf("\n");
    
    /* Check termios configuration */
    if (tcgetattr(fd, &tty) == 0) {
        printf("Termios Configuration:\n");
        printf("  Hardware Flow Control: %s\n", 
               (tty.c_cflag & CRTSCTS) ? "ENABLED (CTS/RTS)" : "DISABLED");
        printf("  Software Flow Control: %s\n", 
               (tty.c_iflag & (IXON | IXOFF)) ? "ENABLED (XON/XOFF)" : "DISABLED");
        printf("  Canonical Mode:        %s\n", 
               (tty.c_lflag & ICANON) ? "Yes" : "No (raw)");
        printf("  Echo:                  %s\n", 
               (tty.c_lflag & ECHO) ? "Yes" : "No");
        
        speed_t speed = cfgetospeed(&tty);
        printf("  Baud Rate:             ");
        switch(speed) {
            case B9600:   printf("9600\n"); break;
            case B19200:  printf("19200\n"); break;
            case B38400:  printf("38400\n"); break;
            case B57600:  printf("57600\n"); break;
            case B115200: printf("115200\n"); break;
            default:      printf("0x%x\n", speed); break;
        }
    } else {
        printf("Termios: Failed to read settings\n");
    }
    
    printf("\n");
    
    close(fd);
    return 0;
}
