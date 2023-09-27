/* priv_rdmsr.c
 *
 * Demonstrate sucessful execution of priveleged instruction RDMSR
 * in Linux kernelspace
 */
#include <linux/module.h>
#include <linux/init.h>
MODULE_LICENSE("GPL");
static int priv_demo_init(void) {
		/* arbitrary poison values */
		int result_lower_32 = -0xAF, result_upper_32 = -0xBF;
		pr_info("EDX:EAX := MSR[ECX];");
		asm ( "rdmsr"
		: "=r" (result_upper_32), "=r" (result_lower_32) : : );
		pr_info("rdmsr: EDX=0x%x, EAX=0x%x\n",
				result_lower_32, result_upper_32);
		return 0;
}
static void priv_demo_exit(void) {
		pr_info("rdmsr exiting");
}
module_init(priv_demo_init);
module_exit(priv_demo_exit)
