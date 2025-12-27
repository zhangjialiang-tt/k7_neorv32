// LED 对应的 GPIO 位偏移（GPIO[31:24] 对应 LED[7:0]）
#ifndef LED_H
#define LED_H

#include <stdint.h>

#define LED0_GPIO_BIT 24
#define LED1_GPIO_BIT 25
#define LED2_GPIO_BIT 26
#define LED3_GPIO_BIT 27
#define LED4_GPIO_BIT 28
#define LED5_GPIO_BIT 29
#define LED6_GPIO_BIT 30
#define LED7_GPIO_BIT 31

// LED 状态定义
#define LED_OFF 0
#define LED_ON 1

// Function prototypes
void led_init(void);
void led_set(uint8_t id, uint8_t state);
void led_toggle(uint8_t id);
void led_set_byte(uint8_t value);

#endif // LED_H
