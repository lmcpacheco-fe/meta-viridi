/*
 * check-rs485-support.c
 * 
 * Usage: check-rs485-support /dev/ttyLPX
 */

#include <stdio.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/serial.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>

void print_usage(const char *prog) {
    fprintf(stderr, "Usage: %s /dev/ttyLPX\n", prog);
    fprintf(stderr, "\nExample:\n");
    fprintf(stderr, "  %s /dev/ttyLP6\n", prog);
}

const char* flag_to_string(unsigned int flags) {
    static char buf[256];
    buf[0] = '\0';
    
    if (flags & SER_RS485_ENABLED)
        strcat(buf, "ENABLED ");
    if (flags & SER_RS485_RTS_ON_SEND)
        strcat(buf, "RTS_ON_SEND ");
    if (flags & SER_RS485_RTS_AFTER_SEND)
        strcat(buf, "RTS_AFTER_SEND ");
    if (flags & SER_RS485_RX_DURING_TX)
        strcat(buf, "RX_DURING_TX ");
    
    if (buf[0] == '\0')
        strcpy(buf, "NONE");
    
    return buf;
}

int main(int argc, char *argv[]) {
    int fd;
    struct serial_rs485 rs485;
    
    if (argc != 2) {
        print_usage(argv[0]);
        return 1;
    }
    
    fd = open(argv[1], O_RDWR | O_NOCTTY);
    if (fd < 0) {
        fprintf(stderr, "Error: Unable to open %s: %s\n", 
                argv[1], strerror(errno));
        return 1;
    }
    
    memset(&rs485, 0, sizeof(rs485));
    
    printf("===========================================\n");
    printf("RS485 Support Check: %s\n", argv[1]);
    printf("===========================================\n\n");
    
    /* Test TIOCGRS485 (read RS485 config) */
    if (ioctl(fd, TIOCGRS485, &rs485) < 0) {
        printf("RS485 ioctl NOT supported\n");
        printf("   Error: %s (errno=%d)\n\n", strerror(errno), errno);
        printf("Possible causes:\n");
        printf("  1. Kernel driver doesn't have RS485 support compiled in\n");
        printf("  2. Device tree missing RS485 properties:\n");
        printf("     - rs485-rts-active-high\n");
        printf("     - rs485-rts-delay\n");
        printf("  3. Wrong device node specified\n");
        printf("  4. CONFIG_SERIAL_FSL_LPUART not enabled in kernel\n");
        close(fd);
        return 1;
    }
    
    printf("RS485 ioctl is supported\n\n");
    
    printf("Current Configuration:\n");
    printf("  Mode:              %s\n", 
           (rs485.flags & SER_RS485_ENABLED) ? "RS485" : "RS232");
    printf("  Flags:             0x%08x (%s)\n", 
           rs485.flags, flag_to_string(rs485.flags));
    
    if (rs485.flags & SER_RS485_ENABLED) {
        printf("\n  RS485 Settings:\n");
        printf("    RTS on send:       %s\n", 
               (rs485.flags & SER_RS485_RTS_ON_SEND) ? "Yes" : "No");
        printf("    RTS after send:    %s\n", 
               (rs485.flags & SER_RS485_RTS_AFTER_SEND) ? "Yes" : "No");
        printf("    RX during TX:      %s\n", 
               (rs485.flags & SER_RS485_RX_DURING_TX) ? "Yes (echo!)" : "No");
        printf("    Delay before send: %u ms\n", rs485.delay_rts_before_send);
        printf("    Delay after send:  %u ms\n", rs485.delay_rts_after_send);
    }
    
    printf("\nDevice is ready for RS232/RS485 mode switching\n");
    printf("\nUsage:\n");
    printf("  rs485-enable %s         # Switch to RS485\n", argv[1]);
    printf("  rs232-enable %s         # Switch to RS232\n", argv[1]);
    printf("  rs232-enable %s crtscts # RS232 with flow control\n", argv[1]);
    printf("\n");
    
    close(fd);
    return 0;
}
