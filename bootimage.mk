# Commands to build boot.img
# They assume that the device tree image and initrd are in their places

MKBOOTIMG := tools/mkbootimg/mkbootimg
$(MKBOOTIMG):
	make -C tools/mkbootimg

DTBTOOL := tools/dtbtool/dtbtool
$(DTBTOOL):
	make -C tools/dtbtool

MKBOOTFS := tools/mkbootfs/mkbootfs
$(MKBOOTFS):
	make -j1 -C tools/mkbootfs

BOOT_IMAGE_OUT := arch/arm/boot/boot.img
KERNEL_IMAGE := arch/arm/boot/zImage
RAMDISK := arch/arm/boot/initramfs.cpio.gz
DEVTREE := arch/arm/boot/dt.img
KERNEL_BASE := 0x00000000
KERNEL_CMDL := 'console=ttyHSL0,115200,n8 androidboot.console=ttyHSL0 androidboot.hardware=qcom user_debug=31 msm_rtb.filter=0x37 utags.blkdev=/dev/block/platform/msm_sdcc.1/by-name/utags vmalloc=400M androidboot.write_protect=0'
BOARD_KERNEL_PAGESIZE := 2048

$(KERNEL_IMAGE): zImage

.PHONY: ramdisk FORCE_RDISK
ramdisk: $(RAMDISK)
FORCE_RDISK:

RAMDISK_ROOT = "boot/ramdisk_$(VARIANT)"

ifneq ($(shell test -d $(RAMDISK_ROOT); echo $$?),0)
$(error Variant $(VARIANT) not found)
endif

$(RAMDISK): $(MKBOOTFS) FORCE_RDISK
	$(MKBOOTFS) $(RAMDISK_ROOT) | gzip -9 -n >$@

.PHONY: dtimage
dtimage: $(DEVTREE)

$(DEVTREE): dtbs $(DTBTOOL)
	$(call pretty,"Target dt image: $(DEVTREE)")
	$(DTBTOOL) -o $@ -s $(BOARD_KERNEL_PAGESIZE) -p scripts/dtc/ arch/arm/boot/
	chmod a+r $@

MKBOOTIMG_ARGS := --kernel ${KERNEL_IMAGE} --ramdisk ${RAMDISK} --dt ${DEVTREE} \
    --base ${KERNEL_BASE} --cmdline ${KERNEL_CMDL} --ramdisk_offset 0x01000000 --tags_offset 0x00000100

.PHONY: bootimage
bootimage: $(BOOT_IMAGE_OUT)

$(BOOT_IMAGE_OUT): $(KERNEL_IMAGE) $(RAMDISK) $(DEVTREE) $(MKBOOTIMG)
	$(MKBOOTIMG) $(MKBOOTIMG_ARGS) -o $@
