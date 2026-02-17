/*
 * rs485-enable.c
 * * Purpose:
 * 1. Sets the Hardware Transceiver Mode (via GPIO on PCA9555)
 * 2. Sets the UART Driver Mode (RX_DURING_TX flag)
 * 3. Verifies both states before exiting
 * * Usage:
 * rs485-enable /dev/ttyLPX half             -> GPIO=1, Echo DISABLED
 * rs485-enable /dev/ttyLPX half force-echo  -> GPIO=1, Echo ENABLED (Debug)
 * rs485-enable /dev/ttyLPX full             -> GPIO=0, Echo ENABLED
 */

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/serial.h>
#include <linux/gpio.h>
#include <termios.h>
#include <string.h>
#include <errno.h>

/* The line name defined in viridi-common.dtsi */
#define TARGET_LINE_NAME "RSTRAN_DUP_1V8"
/* The pin index on the PCA9555 (3rd pin -> index 2) */
#define TARGET_LINE_OFFSET 2

/*
 * Helper: Find the GPIO chip path dynamically by looking for a specific line name.
 * This makes the code immune to gpiochip renumbering.
 */
int find_correct_gpio_chip(char *path_out, size_t max_len) {
    char path[32];
    int i, fd;
    struct gpioline_info info;

    for (i = 0; i < 16; i++) {
        snprintf(path, sizeof(path), "/dev/gpiochip%d", i);
        fd = open(path, O_RDONLY);
        if (fd < 0) continue;

        memset(&info, 0, sizeof(info));
        info.line_offset = TARGET_LINE_OFFSET;

        if (ioctl(fd, GPIO_GET_LINEINFO_IOCTL, &info) == 0) {
            if (strcmp(info.name, TARGET_LINE_NAME) == 0) {
                strncpy(path_out, path, max_len);
                path_out[max_len - 1] = '\0';
                close(fd);
                return 0;
            }
        }
        close(fd);
    }
    return -1;
}

/*
 * Drive the GPIO to set Hardware Mode
 * value: 1 = Half Duplex (High), 0 = Full Duplex (Low)
 * Returns: file descriptor to keep line held (caller must close), or -1 on error
 */
int set_hardware_mode(const char *gpio_chip, int value) {
    int fd, ret;
    struct gpiohandle_request req;
    struct gpiohandle_data data;

    fd = open(gpio_chip, O_RDONLY);
    if (fd < 0) {
        fprintf(stderr, "Error: Cannot open GPIO chip %s: %s\n", gpio_chip, strerror(errno));
        return -1;
    }

    memset(&req, 0, sizeof(req));
    req.lineoffsets[0] = TARGET_LINE_OFFSET;

    /* Request as OUTPUT to drive the SP330E pin */
    req.flags = GPIOHANDLE_REQUEST_OUTPUT;

    /* Set default value immediately */
    req.default_values[0] = value;

    req.lines = 1;
    strncpy(req.consumer_label, "rs485-mode-ctrl", sizeof(req.consumer_label) - 1);
    req.consumer_label[sizeof(req.consumer_label) - 1] = '\0';

    /* Request the line handle */
    ret = ioctl(fd, GPIO_GET_LINEHANDLE_IOCTL, &req);
    close(fd); /* Close chip fd, we only need the line handle now */

    if (ret < 0) {
        fprintf(stderr, "Error: Cannot get GPIO handle to drive pin: %s\n", strerror(errno));
        return -1;
    }

    /* Verify the value was set correctly */
    memset(&data, 0, sizeof(data));
    if (ioctl(req.fd, GPIOHANDLE_GET_LINE_VALUES_IOCTL, &data) == 0) {
        if (data.values[0] != value) {
            fprintf(stderr, "Warning: GPIO readback mismatch (expected %d, got %d)\n",
                    value, data.values[0]);
        }
    }

    /* Return the handle fd so caller can keep it open during operation. */
    return req.fd;
}

int main(int argc, char *argv[]) {
    int fd;
    int gpio_fd = -1;
    struct serial_rs485 rs485conf;
    struct termios tty;
    char *device;
    char *mode_str;
    char gpio_chip_path[32] = "";
    int target_half_duplex = 0;
    int force_echo = 0; /* New flag */

    if (argc < 3) {
        fprintf(stderr, "Usage: %s <device> <half|full> [force-echo]\n", argv[0]);
        fprintf(stderr, "\nMode Description:\n");
        fprintf(stderr, "  half        - 2-wire RS-485 (echo suppressed)\n");
        fprintf(stderr, "  full        - 4-wire RS-485 (simultaneous TX/RX)\n");
        fprintf(stderr, "  force-echo  - Optional: Enable local echo even in half mode\n");
        fprintf(stderr, "\nExample:\n");
        fprintf(stderr, "  %s /dev/5 half\n", argv[0]);
        return 1;
    }

    device = argv[1];
    mode_str = argv[2];

    /* Check for optional 3rd argument */
    if (argc > 3 && strcmp(argv[3], "force-echo") == 0) {
        force_echo = 1;
    }

    if (strcmp(mode_str, "full") == 0) {
        target_half_duplex = 0;
    } else if (strcmp(mode_str, "half") == 0) {
        target_half_duplex = 1;
    } else {
        fprintf(stderr, "Error: Invalid mode '%s'. Use 'half' or 'full'.\n", mode_str);
        return 1;
    }

    printf("===========================================\n");
    printf("RS-485 Configuration Utility\n");
    printf("===========================================\n\n");

    /* 1. Find and Configure Hardware (GPIO) */
    if (find_correct_gpio_chip(gpio_chip_path, sizeof(gpio_chip_path)) < 0) {
        fprintf(stderr, "Error: Could not find GPIO chip for %s\n", TARGET_LINE_NAME);
        fprintf(stderr, "Hardware mode will NOT be set! Continuing with software config only...\n\n");
    } else {
        printf("Step 1: Configure Hardware Transceiver\n");
        printf("  GPIO Chip: %s\n", gpio_chip_path);
        printf("  Setting RSTRAN_DUP_1V8 = %d (%s Duplex)\n",
               target_half_duplex, target_half_duplex ? "Half" : "Full");

        gpio_fd = set_hardware_mode(gpio_chip_path, target_half_duplex);
        if (gpio_fd < 0) {
            fprintf(stderr, "Error: Failed to set hardware mode\n");
            return 1;
        }
        printf("   Hardware transceiver configured\n\n");
    }

    /* 2. Configure Software (UART) */
    printf("Step 2: Configure UART Driver\n");
    printf("  Device: %s\n", device);

    fd = open(device, O_RDWR | O_NOCTTY | O_NONBLOCK);
    if (fd < 0) {
        fprintf(stderr, "Error: Unable to open %s: %s\n", device, strerror(errno));
        if (gpio_fd >= 0) close(gpio_fd);
        return 1;
    }

    /* Disable flow control */
    if (tcgetattr(fd, &tty) == 0) {
        tty.c_cflag &= ~CRTSCTS;
        if (tcsetattr(fd, TCSANOW, &tty) < 0) {
            fprintf(stderr, "Warning: Failed to disable flow control: %s\n", strerror(errno));
        }
    }

    memset(&rs485conf, 0, sizeof(rs485conf));
    rs485conf.flags = SER_RS485_ENABLED | SER_RS485_RTS_ON_SEND;
    rs485conf.delay_rts_before_send = 0;
    rs485conf.delay_rts_after_send = 0;

    /*
     * Logic:
     * If FULL DUPLEX  -> Enable Echo (RX_DURING_TX) because TX and RX are separate.
     * If FORCE ECHO   -> Enable Echo regardless of mode.
     * If HALF DUPLEX  -> Disable Echo (suppress local loopback).
     */
    if (target_half_duplex && !force_echo) {
        /* HALF DUPLEX and NO FORCE -> Kill Echo */
        rs485conf.flags &= ~SER_RS485_RX_DURING_TX;
        printf("  Mode: RS-485 HALF-DUPLEX (2-wire)\n");
        printf("  Bus: Shared A/Y and B/Z\n");
        printf("  RX During TX: DISABLED (echo suppressed)\n");
    } else {
        /* FULL DUPLEX or FORCE ECHO -> Keep RX On */
        rs485conf.flags |= SER_RS485_RX_DURING_TX;

        if (target_half_duplex && force_echo) {
             printf("  Mode: RS-485 HALF-DUPLEX (DEBUG: Force Echo)\n");
             printf("  RX During TX: ENABLED (Forced by user)\n");
        } else {
             printf("  Mode: RS-485 FULL-DUPLEX (4-wire)\n");
             printf("  RX During TX: ENABLED (simultaneous operation)\n");
        }
    }

    if (ioctl(fd, TIOCSRS485, &rs485conf) < 0) {
        fprintf(stderr, "Error: Failed to set RS485 ioctl: %s\n", strerror(errno));
        close(fd);
        if (gpio_fd >= 0) close(gpio_fd);
        return 1;
    }

    /* Verify configuration */
    struct serial_rs485 verify;
    if (ioctl(fd, TIOCGRS485, &verify) == 0) {
        printf("   UART driver configured\n\n");

        printf("Verification:\n");
        printf("  RS-485 Enabled: %s\n", (verify.flags & SER_RS485_ENABLED) ? "Yes" : "No");
        printf("  RX During TX: %s\n", (verify.flags & SER_RS485_RX_DURING_TX) ? "ENABLED" : "DISABLED");

        if (target_half_duplex && !force_echo && !(verify.flags & SER_RS485_RX_DURING_TX)) {
            printf("\n Configuration complete - Half-duplex echo suppression ACTIVE\n");
        } else if ((!target_half_duplex || force_echo) && (verify.flags & SER_RS485_RX_DURING_TX)) {
            printf("\n Configuration complete - RX enabled during TX\n");
        }
    }

    /* Remove O_NONBLOCK before closing */
    int flags = fcntl(fd, F_GETFL, 0);
    if (flags >= 0) {
        fcntl(fd, F_SETFL, flags & ~O_NONBLOCK);
    }

    close(fd);

    /* Keep GPIO held for a moment to ensure it latches, then release */
    if (gpio_fd >= 0) {
        usleep(10000); /* 10ms hold time for I2C expander to latch */
        close(gpio_fd);
    }

    return 0;
}