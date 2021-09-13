//Vaibhav Gogia
//400253615
//MacID: gogiav

//Bus Speed = 30 Mhz
//Distance Status = PN0

#include <stdint.h>
#include "tm4c1294ncpdt.h"
#include "onboardLEDs.h"
#include "PLL.h"
#include "SysTick.h"

int status=0;
int counter = 0, angleCount = 64;

void PortN_Init(void);
void PortE_Init(void);
void PortM_Init(void);

void rotate(int delay);

int main(void) {
	PLL_Init();	
	SysTick_Init();
	onboardLEDs_Init();
	PortE_Init();
	PortM_Init();
	PortN_Init();
	
		FlashAllLEDs();

while(1){
 if (GPIO_PORTM_DATA_R == 0b1){
   rotate(5);
  }
 }
}

void PortN_Init(void){	//onboard LED
	SYSCTL_RCGCGPIO_R |= SYSCTL_RCGCGPIO_R12; // activate the clock for Port N
	while((SYSCTL_PRGPIO_R&SYSCTL_PRGPIO_R12) == 0){}; // allow time for clock to stabilize
	GPIO_PORTN_DIR_R = 0b00000001;
	GPIO_PORTN_DEN_R = 0b00000001; // Enable PN0 as digital output (for onboard LED)
	return;
}

void PortE_Init(void){	//drive motor
	SYSCTL_RCGCGPIO_R |= SYSCTL_RCGCGPIO_R4; //activate the clock for Port E (drives motor)
	while((SYSCTL_PRGPIO_R&SYSCTL_PRGPIO_R4) == 0){}; //allow time for clock to stabilize
	GPIO_PORTE_DEN_R = 0b00001111;
	GPIO_PORTE_DIR_R = 0b00001111;
	return;
}

void PortM_Init(void){	//button
	SYSCTL_RCGCGPIO_R |= SYSCTL_RCGCGPIO_R11; //activate the clock for Port M (reads in push button)
	while((SYSCTL_PRGPIO_R&SYSCTL_PRGPIO_R11) == 0){}; //allow time for clock to stabilize
	GPIO_PORTM_DEN_R = 0b00000001;
	GPIO_PORTM_DIR_R = 0b00000000;
	return;
}

void rotate(int delay){
	//blinks PN0 LED every 8th step (45 deg)
	//LED blinks over duration of the next step
	for(int i = 0; i < 512; i++) {
				GPIO_PORTN_DATA_R = 0b0;
		    if(i%64==0){
				GPIO_PORTN_DATA_R = 0b1;
				}
	
	
	GPIO_PORTE_DATA_R = 0b1100;
	SysTick_Wait10ms(delay);
	GPIO_PORTE_DATA_R = 0b0110;
	SysTick_Wait10ms(delay);
	GPIO_PORTE_DATA_R = 0b0011;
	SysTick_Wait10ms(delay);
	GPIO_PORTE_DATA_R = 0b1001;
	SysTick_Wait10ms(delay);
	
}
}
