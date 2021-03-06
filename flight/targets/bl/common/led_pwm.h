/**
 ******************************************************************************
 * @file       led_pwm.h
 * @author     Tau Labs, http://taulabs.org, Copyright (C) 2013
 * @addtogroup Bootloader
 * @{
 * @addtogroup Bootloader
 * @{
 * @brief LED PWM emulation for the Tau Labs unified bootloader
 *****************************************************************************/
/*
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
 * for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, see <http://www.gnu.org/licenses/>
 */

#ifndef LED_PWM_H_
#define LED_PWM_H_

#include <stdint.h>		/* uint*_t */
#include <stdbool.h>		/* bool */

struct led_pwm_state {
	uint32_t uptime_us;

	bool pwm_1_enabled;
	uint32_t pwm_1_period_us;
	uint32_t pwm_1_sweep_steps;

	bool pwm_2_enabled;
	uint32_t pwm_2_period_us;
	uint32_t pwm_2_sweep_steps;

#ifdef PIOS_INCLUDE_WS2811
	uint32_t last_ws2811_us;
#endif
};

extern void led_pwm_config(struct led_pwm_state * leds, uint32_t pwm_1_period_us, uint32_t pwm_1_sweep_steps, uint32_t pwm_2_period_us, uint32_t pwm_2_sweep_steps);

extern void led_pwm_add_ticks(struct led_pwm_state *leds, uint32_t elapsed_us);

extern bool led_pwm_update_leds(struct led_pwm_state *leds);

#endif	/* LED_PWM_H_ */

/**
 * @}
 * @}
 */
