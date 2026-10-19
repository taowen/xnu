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

/* ELF adaptation of the untagged ARMv8.0 primitive in machine_routines_asm.s.
 * Linux returns synchronous faults in the marked range to the invalid exit.
 * The host handler supplies recovery; no privileged instructions are used. */
#include <kern/ticket_lock.h>
#if KASAN_TBI
#error Tagged ticket-lock recovery is not implemented by the userspace host
#endif

.section .text.hw_lck_ticket_reserve_orig_allow_invalid,"ax",%progbits
.p2align 2
.global hw_lck_ticket_reserve_orig_allow_invalid
.type hw_lck_ticket_reserve_orig_allow_invalid,%function
.global xnu_host_ticket_fault_start
.global xnu_host_ticket_fault_end
.global xnu_host_ticket_fault_return
hw_lck_ticket_reserve_orig_allow_invalid:
    .cfi_startproc
    mov x8, x0
    mov w9, #HW_LCK_TICKET_LOCK_INC_WORD
xnu_host_ticket_fault_start:
1:  ldaxr w0, [x8]
    tbz w0, #HW_LCK_TICKET_LOCK_VALID_BIT, xnu_host_ticket_fault_return
    add w11, w0, w9
    stxr w12, w11, [x8]
    cbnz w12, 1b
xnu_host_ticket_fault_end:
    ret
xnu_host_ticket_fault_return:
    clrex
    mov w0, #0
    ret
    .cfi_endproc
.size hw_lck_ticket_reserve_orig_allow_invalid, .-hw_lck_ticket_reserve_orig_allow_invalid
.section .note.GNU-stack,"",%progbits
