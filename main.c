#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <time.h>
#include <sys/mman.h>
#include "hwlib.h"
#include "socal/socal.h"
#include "socal/hps.h"
#include "socal/alt_gpio.h"
#include "hps_0.h"
//#include "led.h"
//#include "seg7.h"
#include <stdbool.h>
#include <pthread.h>

/////////////////////////////////////////////////////////////////////////////////////////////
/* The base address byte offset for the start of the ALT_LWFPGASLVS component. */
#define ALT_LWFPGASLVS_OFST    0xff200000
/* The base address byte offset for the start of the ALT_STM component. */
#define ALT_STM_OFST    0xfc000000
#define ALT_AXI_FPGASLVS_OFST (0xC0000000) // axi_master
/////////////////////////////////////////////////////////////////////////////////////////////

#define HW_REGS_BASE ( ALT_STM_OFST )
#define HW_REGS_SPAN ( 0x04000000 )
#define HW_REGS_MASK ( HW_REGS_SPAN - 1 )

volatile unsigned long* h2p_lw_led_addr = NULL;
volatile unsigned long* h2p_lw_hex_addr = NULL;
//volatile unsigned long *h2p_lw_sw_addr=NULL;

int main(int argc, char** argv)
{
	//pthread_t id;
	//int ret;
	void* virtual_base;
	int fd;
	//int x, i, j;
	// map the address space for the LED registers into user space so we can interact with them.
	// we'll actually map in the entire CSR span of the HPS since we want to access various registers within that span
	if ((fd = open("/dev/mem", (O_RDWR | O_SYNC))) == -1) {
		printf("ERROR: could not open \"/dev/mem\"...\n");
		return(1);
	}
	virtual_base = mmap(NULL, HW_REGS_SPAN, (PROT_READ | PROT_WRITE), MAP_SHARED, fd, HW_REGS_BASE);
	if (virtual_base == MAP_FAILED) {
		printf("ERROR: mmap() failed...\n");
		close(fd);
		return(1);
	}
	//h2p_lw_led_addr=virtual_base + ( ( unsigned long  )( ALT_LWFPGASLVS_OFST + LED_PIO_BASE ) & ( unsigned long)( HW_REGS_MASK ) );
	h2p_lw_hex_addr = virtual_base + ((unsigned long)(ALT_LWFPGASLVS_OFST + SEG7_IF_0_BASE) & (unsigned long)(HW_REGS_MASK));
	//h2p_lw_sw_addr=virtual_base + ( ( unsigned long  )( ALT_LWFPGASLVS_OFST + SW_PIO_BASE ) & ( unsigned long)( HW_REGS_MASK ) );

	int a, b, c;
	//int temp = 1, count = 0;

	//scanf("%d %d %d %d %d %d",&a,&b,&c,&d,&e,&f);




	while (1)
	{
		
		printf("請輸入前兩碼初始值:\n");
		scanf("%d",&a);
		printf("請輸入中兩碼初始值:\n");
		scanf("%d",&b);
		printf("請輸入後一碼初始值:\n");
		scanf("%d",&c);
		*((uint8_t*)h2p_lw_hex_addr + 2) = a;
		*((uint8_t*)h2p_lw_hex_addr + 1) = b;
		*((uint8_t*)h2p_lw_hex_addr) = c;
		
		

	}


	usleep(1000 * 1000);

	if (munmap(virtual_base, HW_REGS_SPAN) != 0) {
		printf("ERROR: munmap() failed...\n");
		close(fd);
		return(1);

	}
	close(fd);
	return 0;
}