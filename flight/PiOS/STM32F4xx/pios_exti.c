/**
 ******************************************************************************
 *
 * @addtogroup PIOS PIOS Core hardware abstraction layer
 * @{
 * @addtogroup PIOS_EXTI External Interrupt Handlers
 * @brief External interrupt handler functions
 * @{
 *
 * @file       pios_exti.c
 * @author     The OpenPilot Team, http://www.openpilot.org Copyright (C) 2010.
 * @author     Tau Labs, http://taulabs.org, Copyright (C) 2014
 * @brief      External Interrupt Handlers
 * @see        The GNU Public License (GPL) Version 3
 *
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

/* Project Includes */
#include "pios.h"

#if defined(PIOS_INCLUDE_EXTI)

/* Map EXTI line to full config */
#define EXTI_MAX_LINES 16
#define PIOS_EXTI_INVALID 0xFF
static uint8_t pios_exti_line_to_cfg_map[EXTI_MAX_LINES] = {
	[0 ... EXTI_MAX_LINES-1] = PIOS_EXTI_INVALID,
};

/* Table of exti configs registered at compile time */
extern struct pios_exti_cfg __start__exti __attribute__((weak));
extern struct pios_exti_cfg __stop__exti  __attribute__((weak));

static uint8_t PIOS_EXTI_line_to_index (uint32_t line)
{
	switch (line) {
	case EXTI_Line0: return 0;
	case EXTI_Line1: return 1;
	case EXTI_Line2: return 2;
	case EXTI_Line3: return 3;
	case EXTI_Line4: return 4;
	case EXTI_Line5: return 5;
	case EXTI_Line6: return 6;
	case EXTI_Line7: return 7;
	case EXTI_Line8: return 8;
	case EXTI_Line9: return 9;
	case EXTI_Line10: return 10;
	case EXTI_Line11: return 11;
	case EXTI_Line12: return 12;
	case EXTI_Line13: return 13;
	case EXTI_Line14: return 14;
	case EXTI_Line15: return 15;
	}

	PIOS_Assert(0);
	return 0xFF;
}

uint8_t PIOS_EXTI_gpio_port_to_exti_source_port(GPIO_TypeDef * gpio_port)
{
	switch((uint32_t)gpio_port) {
		case (uint32_t)GPIOA: return (EXTI_PortSourceGPIOA);
		case (uint32_t)GPIOB: return (EXTI_PortSourceGPIOB);
		case (uint32_t)GPIOC: return (EXTI_PortSourceGPIOC);
		case (uint32_t)GPIOD: return (EXTI_PortSourceGPIOD);
		case (uint32_t)GPIOE: return (EXTI_PortSourceGPIOE);
		case (uint32_t)GPIOF: return (EXTI_PortSourceGPIOF);
		case (uint32_t)GPIOG: return (EXTI_PortSourceGPIOG);
	}

	PIOS_Assert(0);
	return 0xFF;
}

uint8_t PIOS_EXTI_gpio_pin_to_exti_source_pin(uint32_t gpio_pin)
{
	switch((uint32_t)gpio_pin) {
	case GPIO_Pin_0: return (GPIO_PinSource0);
	case GPIO_Pin_1: return (GPIO_PinSource1);
	case GPIO_Pin_2: return (GPIO_PinSource2);
	case GPIO_Pin_3: return (GPIO_PinSource3);
	case GPIO_Pin_4: return (GPIO_PinSource4);
	case GPIO_Pin_5: return (GPIO_PinSource5);
	case GPIO_Pin_6: return (GPIO_PinSource6);
	case GPIO_Pin_7: return (GPIO_PinSource7);
	case GPIO_Pin_8: return (GPIO_PinSource8);
	case GPIO_Pin_9: return (GPIO_PinSource9);
	case GPIO_Pin_10: return (GPIO_PinSource10);
	case GPIO_Pin_11: return (GPIO_PinSource11);
	case GPIO_Pin_12: return (GPIO_PinSource12);
	case GPIO_Pin_13: return (GPIO_PinSource13);
	case GPIO_Pin_14: return (GPIO_PinSource14);
	case GPIO_Pin_15: return (GPIO_PinSource15);
	}

	PIOS_Assert(0);
	return 0xFF;
}

int32_t PIOS_EXTI_Init(const struct pios_exti_cfg * cfg)
{
  	PIOS_Assert(cfg);
	PIOS_Assert(&__start__exti);
	PIOS_Assert(cfg >= &__start__exti);
	PIOS_Assert(cfg < &__stop__exti);

	uint8_t cfg_index = cfg - &__start__exti;

	/* Connect this config to the requested vector */
	uint8_t line_index = PIOS_EXTI_line_to_index(cfg->line);

	if (pios_exti_line_to_cfg_map[line_index] != PIOS_EXTI_INVALID) {
		/* Someone else already has this mapped */
		goto out_fail;
	}

	/* Bind the config to the exti line */
	pios_exti_line_to_cfg_map[line_index] = cfg_index;

	/* Initialize the GPIO pin */
	GPIO_Init(cfg->pin.gpio, (GPIO_InitTypeDef*)&cfg->pin.init);

	/* Set up the EXTI interrupt source */
	uint8_t exti_source_port = PIOS_EXTI_gpio_port_to_exti_source_port(cfg->pin.gpio);
	uint8_t exti_source_pin = PIOS_EXTI_gpio_pin_to_exti_source_pin(cfg->pin.init.GPIO_Pin);
	SYSCFG_EXTILineConfig(exti_source_port, exti_source_pin);
	EXTI_Init((EXTI_InitTypeDef*)&cfg->exti.init);

	/* Enable the interrupt channel */
	NVIC_Init((NVIC_InitTypeDef*)&cfg->irq.init);

	return 0;

out_fail:
	return -1;
}

void PIOS_EXTI_DeInit(const struct pios_exti_cfg *cfg)
{
	PIOS_Assert(cfg);
	PIOS_Assert(&__start__exti);
	PIOS_Assert(cfg >= &__start__exti);
	PIOS_Assert(cfg < &__stop__exti);

	/* Disconnect this config from the requested vector */
	uint8_t line_index = PIOS_EXTI_line_to_index(cfg->line);
	pios_exti_line_to_cfg_map[line_index] = PIOS_EXTI_INVALID;

	/* Disconnect EXTI */
	uint8_t exti_source_pin = PIOS_EXTI_gpio_pin_to_exti_source_pin(cfg->pin.init.GPIO_Pin);
	// sadly std-periph doesn't provide a way to disable the exti line
	uint32_t tmp = ((uint32_t)0x0F) << (0x04 * (exti_source_pin & (uint8_t)0x03));
	SYSCFG->EXTICR[exti_source_pin >> 0x02] &= ~tmp;

	/* Disable EXTI */
	EXTI_InitTypeDef init = {
		.EXTI_LineCmd = DISABLE,
		.EXTI_Mode = cfg->exti.init.EXTI_Mode,
		.EXTI_Line = cfg->exti.init.EXTI_Line,
	};
	EXTI_Init(&init);
}

static bool PIOS_EXTI_generic_irq_handler(uint8_t line_index)
{
	uint8_t cfg_index = pios_exti_line_to_cfg_map[line_index];

	PIOS_Assert(&__start__exti);

	if (cfg_index > NELEMENTS(pios_exti_line_to_cfg_map) ||
		cfg_index == PIOS_EXTI_INVALID) {
		/* Unconfigured interrupt just fired! */
		return false;
	}

	struct pios_exti_cfg * cfg = &__start__exti + cfg_index;
	return cfg->vector();
}

/* Bind Interrupt Handlers */

#define PIOS_EXTI_HANDLE_LINE(line)			\
	if (EXTI_GetITStatus(EXTI_Line##line) != RESET) {	\
		EXTI_ClearITPendingBit(EXTI_Line##line);	\
		PIOS_EXTI_generic_irq_handler(line);		\
	}

static void PIOS_EXTI_0_irq_handler (void)
{
#if defined(PIOS_INCLUDE_CHIBIOS)
	CH_IRQ_PROLOGUE();
#endif /* defined(PIOS_INCLUDE_CHIBIOS) */

	PIOS_EXTI_HANDLE_LINE(0);

#if defined(PIOS_INCLUDE_CHIBIOS)
	CH_IRQ_EPILOGUE();
#endif /* defined(PIOS_INCLUDE_CHIBIOS) */
}
void EXTI0_IRQHandler(void) __attribute__ ((alias ("PIOS_EXTI_0_irq_handler")));

static void PIOS_EXTI_1_irq_handler (void)
{
#if defined(PIOS_INCLUDE_CHIBIOS)
	CH_IRQ_PROLOGUE();
#endif /* defined(PIOS_INCLUDE_CHIBIOS) */

	PIOS_EXTI_HANDLE_LINE(1);

#if defined(PIOS_INCLUDE_CHIBIOS)
	CH_IRQ_EPILOGUE();
#endif /* defined(PIOS_INCLUDE_CHIBIOS) */
}
void EXTI1_IRQHandler(void) __attribute__ ((alias ("PIOS_EXTI_1_irq_handler")));

static void PIOS_EXTI_2_irq_handler (void)
{
#if defined(PIOS_INCLUDE_CHIBIOS)
	CH_IRQ_PROLOGUE();
#endif /* defined(PIOS_INCLUDE_CHIBIOS) */

	PIOS_EXTI_HANDLE_LINE(2);

#if defined(PIOS_INCLUDE_CHIBIOS)
	CH_IRQ_EPILOGUE();
#endif /* defined(PIOS_INCLUDE_CHIBIOS) */
}
void EXTI2_IRQHandler(void) __attribute__ ((alias ("PIOS_EXTI_2_irq_handler")));

static void PIOS_EXTI_3_irq_handler (void)
{
#if defined(PIOS_INCLUDE_CHIBIOS)
	CH_IRQ_PROLOGUE();
#endif /* defined(PIOS_INCLUDE_CHIBIOS) */

	PIOS_EXTI_HANDLE_LINE(3);

#if defined(PIOS_INCLUDE_CHIBIOS)
	CH_IRQ_EPILOGUE();
#endif /* defined(PIOS_INCLUDE_CHIBIOS) */
}
void EXTI3_IRQHandler(void) __attribute__ ((alias ("PIOS_EXTI_3_irq_handler")));

static void PIOS_EXTI_4_irq_handler (void)
{
#if defined(PIOS_INCLUDE_CHIBIOS)
	CH_IRQ_PROLOGUE();
#endif /* defined(PIOS_INCLUDE_CHIBIOS) */

	PIOS_EXTI_HANDLE_LINE(4);

#if defined(PIOS_INCLUDE_CHIBIOS)
	CH_IRQ_EPILOGUE();
#endif /* defined(PIOS_INCLUDE_CHIBIOS) */
}
void EXTI4_IRQHandler(void) __attribute__ ((alias ("PIOS_EXTI_4_irq_handler")));

static void PIOS_EXTI_9_5_irq_handler (void)
{
#if defined(PIOS_INCLUDE_CHIBIOS)
	CH_IRQ_PROLOGUE();
#endif /* defined(PIOS_INCLUDE_CHIBIOS) */

	PIOS_EXTI_HANDLE_LINE(5);
	PIOS_EXTI_HANDLE_LINE(6);
	PIOS_EXTI_HANDLE_LINE(7);
	PIOS_EXTI_HANDLE_LINE(8);
	PIOS_EXTI_HANDLE_LINE(9);

#if defined(PIOS_INCLUDE_CHIBIOS)
	CH_IRQ_EPILOGUE();
#endif /* defined(PIOS_INCLUDE_CHIBIOS) */
}
void EXTI9_5_IRQHandler(void) __attribute__ ((alias ("PIOS_EXTI_9_5_irq_handler")));

static void PIOS_EXTI_15_10_irq_handler (void)
{
#if defined(PIOS_INCLUDE_CHIBIOS)
	CH_IRQ_PROLOGUE();
#endif /* defined(PIOS_INCLUDE_CHIBIOS) */

	PIOS_EXTI_HANDLE_LINE(10);
	PIOS_EXTI_HANDLE_LINE(11);
	PIOS_EXTI_HANDLE_LINE(12);
	PIOS_EXTI_HANDLE_LINE(13);
	PIOS_EXTI_HANDLE_LINE(14);
	PIOS_EXTI_HANDLE_LINE(15);

#if defined(PIOS_INCLUDE_CHIBIOS)
	CH_IRQ_EPILOGUE();
#endif /* defined(PIOS_INCLUDE_CHIBIOS) */
}
void EXTI15_10_IRQHandler(void) __attribute__ ((alias ("PIOS_EXTI_15_10_irq_handler")));

#endif /* PIOS_INCLUDE_EXTI */

/**
  * @}
  * @}
  */
