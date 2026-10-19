/*
 * Copyright (c) 2007 Apple Inc. All rights reserved.
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

/* ELF/non-PAC adaptation of cswitch.s. Context records and continuation
 * semantics remain XNU's. C helpers update Linux TLS instead of TPIDR_EL1;
 * Linux's TPIDR_EL0 must never be overwritten with a guest thread identifier. */
#include <arm64/usermode_context.h>
#if HAS_APPLE_PAC
#error USERMODE context switching requires non-arm64e kernel state
#endif

.section .text.Switch_context,"ax",%progbits
.p2align 2
.global Switch_context
.type Switch_context,%function
Switch_context:
    /* Preserve original FP/LR and all arguments across the C accessors. */
    stp x29, x30, [sp, #-64]!
    stp x0, x1, [sp, #16]
    str x2, [sp, #32]
    cbnz x1, .Lswitch_new
    bl xnu_host_thread_kernel_context
    mov x3, x0
    stp x19, x20, [x3, #HOST_CTX_X19]
    stp x21, x22, [x3, #(HOST_CTX_X19 + 16)]
    stp x23, x24, [x3, #(HOST_CTX_X19 + 32)]
    stp x25, x26, [x3, #(HOST_CTX_X19 + 48)]
    stp x27, x28, [x3, #(HOST_CTX_X19 + 64)]
    ldp x4, x5, [sp]
    stp x4, x5, [x3, #HOST_CTX_FP]
    add x4, sp, #64
    str x4, [x3, #HOST_CTX_SP]
    strb wzr, [x3, #HOST_CTX_USER_PC]
    stp d8, d9, [x3, #HOST_CTX_D8]
    stp d10, d11, [x3, #(HOST_CTX_D8 + 16)]
    stp d12, d13, [x3, #(HOST_CTX_D8 + 32)]
    stp d14, d15, [x3, #(HOST_CTX_D8 + 48)]
    mrs x4, FPCR
    str w4, [x3, #HOST_CTX_FPCR]
.Lswitch_new:
    ldr x0, [sp, #32]
    bl machine_set_current_thread
    ldr x0, [sp, #32]
    bl xnu_host_thread_kernel_context
    mov x3, x0
    ldr x0, [sp, #16] /* Return the switched-out thread to XNU. */
    b .Lrestore_context
.size Switch_context, .-Switch_context

.section .text.machine_load_context,"ax",%progbits
.p2align 2
.global machine_load_context
.type machine_load_context,%function
machine_load_context:
    mov x19, x0
    bl machine_set_current_thread
    mov x0, x19
    bl xnu_host_thread_kernel_context
    mov x3, x0
    mov x0, #0
.Lrestore_context:
    ldr w4, [x3, #HOST_CTX_FPCR]
    msr FPCR, x4
    ldp x19, x20, [x3, #HOST_CTX_X19]
    ldp x21, x22, [x3, #(HOST_CTX_X19 + 16)]
    ldp x23, x24, [x3, #(HOST_CTX_X19 + 32)]
    ldp x25, x26, [x3, #(HOST_CTX_X19 + 48)]
    ldp x27, x28, [x3, #(HOST_CTX_X19 + 64)]
    ldp x29, x30, [x3, #HOST_CTX_FP]
    ldr x4, [x3, #HOST_CTX_SP]
    ldp d8, d9, [x3, #HOST_CTX_D8]
    ldp d10, d11, [x3, #(HOST_CTX_D8 + 16)]
    ldp d12, d13, [x3, #(HOST_CTX_D8 + 32)]
    ldp d14, d15, [x3, #(HOST_CTX_D8 + 48)]
    mov sp, x4
    ret
.size machine_load_context, .-machine_load_context

.section .text.Call_continuation,"ax",%progbits
.p2align 2
.global Call_continuation
.type Call_continuation,%function
Call_continuation:
    mov x20, x0
    mov x21, x1
    mov x22, x2
    mov x23, x3
    bl xnu_host_current_thread
    bl xnu_host_thread_stack_top
    mov sp, x0
    mov x29, #0
    cbz x23, .Lcontinue
    mov w0, #1
    bl ml_set_interrupts_enabled
.Lcontinue:
    mov x0, x21
    mov x1, x22
    blr x20
    bl xnu_host_current_thread
    bl thread_terminate
    bl xnu_host_continuation_returned
.size Call_continuation, .-Call_continuation

.section .text.xnu_host_run_on_stack,"ax",%progbits
.p2align 2
.global xnu_host_run_on_stack
.type xnu_host_run_on_stack,%function
xnu_host_run_on_stack:
    stp x29, x30, [sp, #-48]!
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    mov x19, x0
    mov x20, sp
    mrs x21, FPCR
    mov sp, x1
    mov x29, #0
    blr x19
    mov sp, x20
    msr FPCR, x21
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret
.size xnu_host_run_on_stack, .-xnu_host_run_on_stack
.section .note.GNU-stack,"",%progbits
