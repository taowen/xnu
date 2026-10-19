/*
 * Copyright (c) 2007-2015 Apple Inc. All rights reserved.
 *
 * @APPLE_OSREFERENCE_LICENSE_HEADER_START@
 *
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apple Public Source License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. The rights granted to you under the License
 * may not be used to create, or enable the creation or redistribution of,
 * unlawful or unlicensed copies of an Apple operating system, or to
 * circumvent, violate, or enable the circumvention or violation of, any
 * terms of an Apple operating system software license agreement.
 *
 * Please obtain a copy of the License at
 * http://www.opensource.apple.com/apsl/ and read it before using this file.
 *
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 *
 * @APPLE_OSREFERENCE_LICENSE_HEADER_END@
 */

/* ELF adaptation of machine_routines_asm.s's byte/string/scalar copies.
 * XNU copyio.c retains address, zone, size and alignment validation. Linux's
 * signal context redirects only this marked range to the EFAULT return.
 * Leaf routines use no stack frame or callee-saved registers. */
#include <sys/errno.h>
.section .text.xnu_host_copyio,"ax",%progbits
.p2align 2
.global xnu_host_copyio_fault_start, xnu_host_copyio_fault_end
.global xnu_host_copyio_fault_return
xnu_host_copyio_fault_start:

.global _bcopyin, _bcopyout
.type _bcopyin,%function
.type _bcopyout,%function
_bcopyin:
_bcopyout:
    cbz x2, .Lcopy_success
.Lcopy_byte:
    ldrb w8, [x0], #1
    strb w8, [x1], #1
    subs x2, x2, #1
    b.ne .Lcopy_byte
.Lcopy_success:
    mov w0, #0
    ret
.size _bcopyin, .-_bcopyin
.size _bcopyout, .-_bcopyout

.global _bcopyinstr
.type _bcopyinstr,%function
_bcopyinstr:
    mov x4, #0
    cbz x2, .Lstring_long
.Lstring_byte:
    ldrb w5, [x0], #1
    strb w5, [x1], #1
    add x4, x4, #1
    cbz w5, .Lstring_done
    cmp x4, x2
    b.ne .Lstring_byte
.Lstring_long:
    mov w5, #ENAMETOOLONG
.Lstring_done:
    str x4, [x3]
    mov w0, w5
    ret
.size _bcopyinstr, .-_bcopyinstr

.macro copyin_scalar bits, reg, mask
.global _copyin_atomic\bits
.type _copyin_atomic\bits,%function
_copyin_atomic\bits:
    tst x0, #\mask
    b.ne .Lcopy_alignment
    ldr \reg, [x0]
    str \reg, [x1]
    b .Lcopy_success
.size _copyin_atomic\bits, .-_copyin_atomic\bits
.endm
copyin_scalar 32, w8, 3
copyin_scalar 64, x8, 7

.macro copyout_scalar bits, reg, mask
.global _copyout_atomic\bits
.type _copyout_atomic\bits,%function
_copyout_atomic\bits:
    tst x1, #\mask
    b.ne .Lcopy_alignment
    str \reg, [x1]
    b .Lcopy_success
.size _copyout_atomic\bits, .-_copyout_atomic\bits
.endm
copyout_scalar 32, w0, 3
copyout_scalar 64, x0, 7

.global _copyin_atomic32_wait_if_equals
.type _copyin_atomic32_wait_if_equals,%function
_copyin_atomic32_wait_if_equals:
    tst x0, #3
    b.ne .Lcopy_alignment
    ldxr w8, [x0]
    cmp w8, w1
    mov w0, #ESTALE
    b.ne .Lwait_done
    mov w0, #0
    wfe
.Lwait_done:
    clrex
    ret
.size _copyin_atomic32_wait_if_equals, .-_copyin_atomic32_wait_if_equals
.Lcopy_alignment:
    mov w0, #EINVAL
    ret
xnu_host_copyio_fault_end:
xnu_host_copyio_fault_return:
    clrex
    mov w0, #EFAULT
    ret
.section .note.GNU-stack,"",%progbits
