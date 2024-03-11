#include "lab_config.h"
//soc confreg
#define CONFREG_NULL            0xbfd08ffc

#define CONFREG_CR0             0xbfd08000
#define CONFREG_CR1             0xbfd08010
#define CONFREG_CR2             0xbfd08020
#define CONFREG_CR3             0xbfd08030
#define CONFREG_CR4             0xbfd08040
#define CONFREG_CR5             0xbfd08050
#define CONFREG_CR6             0xbfd08060
#define CONFREG_CR7             0xbfd08070

#define IO_SIMU_ADDR            0xbfd0ff00
#define UART_ADDR               0xbfd0ff10
#define SIMU_FLAG_ADDR          0xbfd0ff20
#define OPEN_TRACE_ADDR         0xbfd0ff30
#define NUM_MONITOR_ADDR        0xbfd0ff40
#define LED_ADDR                0xbfd0f020
#define LED_RG0_ADDR            0xbfd0f030
#define LED_RG1_ADDR            0xbfd0f040
#define NUM_ADDR                0xbfd0f050
#define SWITCH_ADDR             0xbfd0f060
#define BTN_KEY_ADDR            0xbfd0f070
#define BTN_STEP_ADDR           0xbfd0f080
#define SW_INTER_ADDR           0xbfd0f090 //switch interleave
#define TIMER_ADDR              0xbfd0e000

#define SOC_LED            (* (volatile unsigned *)  LED_ADDR      )
#define SOC_LED_RG0        (* (volatile unsigned *)  LED_RG0_ADDR  )
#define SOC_LED_RG1        (* (volatile unsigned *)  LED_RG1_ADDR  )
#define SOC_NUM            (* (volatile unsigned *)  NUM_ADDR      )
#define SOC_SWITCHE        (* (volatile unsigned *)  SWITCH_ADDR   )
#define SOC_BTN_KEY        (* (volatile unsigned *)  BTN_KEY_ADDR  )
#define SOC_BTN_STEP       (* (volatile unsigned *)  BTN_STEP_ADDR )
#define SOC_TIMER          (* (volatile unsigned *)  TIMER_ADDR    )

#define write_confreg_cr(num,data) *((volatile int *)(CONFREG_CR0+4*num)) = data
#define read_confreg_cr(num,data) data=*((volatile int *)(CONFREG_CR0+4*num))
