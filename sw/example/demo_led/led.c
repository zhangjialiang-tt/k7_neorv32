#include <neorv32.h>
#include "led.h"

// Mapping from logical LED ID to GPIO bit position
static const uint8_t led_gpio_map[8] = {
    LED0_GPIO_BIT, LED1_GPIO_BIT, LED2_GPIO_BIT, LED3_GPIO_BIT,
    LED4_GPIO_BIT, LED5_GPIO_BIT, LED6_GPIO_BIT, LED7_GPIO_BIT
};

/**********************************************************************//**
 * Initialize LED GPIO pins.
 * Clears all LEDs (sets them to 0/OFF).
 **************************************************************************/
void led_init(void) {
    for (int i = 0; i < 8; i++) {
        neorv32_gpio_pin_set(led_gpio_map[i], 0);
    }
}

/**********************************************************************//**
 * Set the state of a specific LED.
 *
 * @param[in] id LED index (0-7).
 * @param[in] state LED_ON or LED_OFF.
 **************************************************************************/
void led_set(uint8_t id, uint8_t state) {
    if (id > 7) return;

    neorv32_gpio_pin_set(led_gpio_map[id], state);
}

/**********************************************************************//**
 * Toggle a specific LED.
 *
 * @param[in] id LED index (0-7).
 **************************************************************************/
void led_toggle(uint8_t id) {
    if (id > 7) return;
    neorv32_gpio_pin_toggle(led_gpio_map[id]);
}

/**********************************************************************//**
 * Set all 8 LEDs based on an 8-bit value.
 *
 * @param[in] value 8-bit value where each bit corresponds to an LED.
 **************************************************************************/
void led_set_byte(uint8_t value) {
    for (int i = 0; i < 8; i++) {
        neorv32_gpio_pin_set(led_gpio_map[i], (value >> i) & 0x01);
    }
}
