obj-m += priv_rdmsr.o
.PHONY: load unload lean user_app kernel_mod
define fmt
	@echo -e "[$(USER)@$(shell hostname)] $(1) \n=====[Output]====="
	@$(1)
	@echo "=================="
endef
define Echo
	@echo "[RDMSR Demo]: $(1)"
endef
all: clean run_user_app demo_kernel_mod

run_user_app: user_app
	$(call Echo, "Begin demo: Running RDMSR in userspace:")
	$(call fmt, ./rdmsr || true)
	$(call Echo, "As expected the CPU generates an exception")
	$(call Echo, "This diagnostic text is shown in dmesg")
	@echo "[$(USER)@$(shell hostname)] dmesg | grep \"general protection fault\" | tail -n 1"
	@echo "=====[Output]====="
	@dmesg | grep "general protection fault" | tail -n 1
	@echo "=================="
	$(call Echo, "End of RDMSR in userspace demo")
demo_kernel_mod: load
	$(call Echo, "Loaded module to run RDMSR in kernelspace")
	$(call Echo, "Diagnostic Output in dmesg from privileged execution of RDMSR")
	@echo "[$(USER)@$(shell hostname)] dmesg | grep -E 'EDX=.*EAX=.*' | tail -n 1"
	@echo "=====[Output]====="
	@dmesg | grep -E '.*EDX=.*EAX=.*' | tail -n 1
	@echo "=================="
	$(call fmt, echo "End of RDMSR in kernelspace demo")
user_app:
	$(call Echo, Asssemble rdmsr.o object file from AT\&T x86_64 assembly file rdmsr.src)
	$(call fmt, as rdmsr.src -o rdmsr.o)
	$(call Echo, "Link rdmsr.o object to create rdmsr executable binary")
	$(call Echo, "This step fails if _start does not have external linkage")
	$(call Echo, "The '.global _start' directive takes care of this for us")
	$(call fmt, ld rdmsr.o -o rdmsr)
kernel_mod: pre_msg kernel_devel
	@test -d /lib/modules/$(shell uname -r)/build && make -C /lib/modules/$(shell uname -r)/build modules M=$(PWD)
pre_msg:
	$(call Echo, "Begin demo: Running RDMSR in kernelspace")
kernel_devel:
	@rpm --quiet -q kernel-devel || dnf install -y kernel-devel && true
clean: unload
	$(call Echo, "Delete build artifacts")
	$(call fmt, rm -rf rdmsr rdmsr.o)
	@test -f priv_rdmsr.ko && ( make -C /lib/modules/$(shell uname -r)/build clean M=$(PWD) ) || true
load: kernel_mod
	$(call Echo "Pass priv_rdmsr.ko kernel object to insmod\(2\) syscall")
	$(call fmt, $(shell sudo insmod priv_rdmsr.ko))
unload:
	$(call Echo "Remove priv_rdmsr from Linux kernel")
	$(call fmt, $(shell sudo rmmod priv_rdmsr))
