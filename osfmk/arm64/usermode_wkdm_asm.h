/* Object-format adaptation only; the original WKdm algorithm stays unchanged. */
#if CONFIG_USERMODE && defined(__ELF__)
#define _WKdm_compress_16k WKdm_compress_16k
#define _WKdm_decompress_16k WKdm_decompress_16k
#define _hashLookupTable hashLookupTable
#define _table_2bits table_2bits
#define _table_4bits table_4bits
#define _table_10bits table_10bits
#define WKDM_ADRP(reg, symbol) adrp reg, :got:symbol
#define WKDM_LDR(reg, symbol) ldr reg, [reg, :got_lo12:symbol]
#define WKDM_CONST .section .rodata
#define WKDM_GNU_STACK .section .note.GNU-stack,"",%progbits
/* Linux owns cache configuration. Clear exactly 64 bytes without assuming
 * DC ZVA availability or its host-dependent block size. */
#define WKDM_ZERO64(reg) stp xzr, xzr, [reg]; stp xzr, xzr, [reg, 16]; stp xzr, xzr, [reg, 32]; stp xzr, xzr, [reg, 48]
#else
#define WKDM_ADRP(reg, symbol) adrp reg, symbol@GOTPAGE
#define WKDM_LDR(reg, symbol) ldr reg, [reg, symbol@GOTPAGEOFF]
#define WKDM_CONST .const
#define WKDM_GNU_STACK
#define WKDM_ZERO64(reg) dc zva, reg
#endif
