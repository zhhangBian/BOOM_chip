## Board Info

[Nexys 4 DDR](https://digilent.com/reference/programmable-logic/nexys-4-ddr/start)

## How to program SPI Flash?

There is no `program_by_uart.bit` for this board, but you can program it in an easier way.

1. Goto **Hardware Manager** in Vivado.
2. Connect your board and open target.
3. Right click **xc7a100t_0**, enter **Add Configuration Memory Device**.
4. Select **s25fl128sxxxxxx0-spi-x1_x2_x4**.
5. Program the flash by `gzrom.bin`.

## How to run linux?

There is no nand controller for Nexys 4 DDR, so we removed it.

You must modify the device tree in Linux and remove the NAND controller, or you will see Linux boot stuck at `Scanning device for bad blocks`.

```patch
diff --git a/arch/loongarch/boot/dts/loongson/loongson32_ls.dts b/arch/loongarch/boot/dts/loongson/loongson32_ls.dts
index f33c0ce23863..89224322f057 100644
--- a/arch/loongarch/boot/dts/loongson/loongson32_ls.dts
+++ b/arch/loongarch/boot/dts/loongson/loongson32_ls.dts
@@ -78,6 +78,7 @@ ahci@0x1fe30000{
             };
 #endif
 
+#if 0
         nand@0x1fe78000{
              #address-cells = <1>;
              #size-cells = <1>;
@@ -100,6 +101,7 @@ partition@0x01400000 {
              };
          };
 
+#endif
     };
 };
```
