//
// Copyright (c) Microsoft. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
//
//
// Implementation of _CONTEXT_CaptureContext for the Intel x86 platform.
// This function is processor dependent.  It is used by exception handling,
// and is always apply to the current thread.
//

.intel_syntax noprefix
#include "unixasmmacros.inc"

#ifdef BIT64

#define CONTEXT_AMD64   0x100000

#define CONTEXT_CONTROL 1 // SegSs, Rsp, SegCs, Rip, and EFlags
#define CONTEXT_INTEGER 2 // Rax, Rcx, Rdx, Rbx, Rbp, Rsi, Rdi, R8-R15
#define CONTEXT_SEGMENTS 4 // SegDs, SegEs, SegFs, SegGs
#define CONTEXT_FLOATING_POINT 8
#define CONTEXT_DEBUG_REGISTERS 16 // Dr0-Dr3 and Dr6-Dr7

#define CONTEXT_FULL (CONTEXT_CONTROL | CONTEXT_INTEGER | CONTEXT_FLOATING_POINT)

#define CONTEXT_ContextFlags 6*8
#define CONTEXT_SegCs CONTEXT_ContextFlags+8
#define CONTEXT_SegDs CONTEXT_SegCs+2
#define CONTEXT_SegEs CONTEXT_SegDs+2
#define CONTEXT_SegFs CONTEXT_SegEs+2
#define CONTEXT_SegGs CONTEXT_SegFs+2
#define CONTEXT_SegSs CONTEXT_SegGs+2
#define CONTEXT_EFlags CONTEXT_SegSs+2
#define CONTEXT_Dr0 CONTEXT_EFlags+4
#define CONTEXT_Dr1 CONTEXT_Dr0+8
#define CONTEXT_Dr2 CONTEXT_Dr1+8
#define CONTEXT_Dr3 CONTEXT_Dr2+8
#define CONTEXT_Dr6 CONTEXT_Dr3+8
#define CONTEXT_Dr7 CONTEXT_Dr6+8
#define CONTEXT_Rax CONTEXT_Dr7+8
#define CONTEXT_Rcx CONTEXT_Rax+8
#define CONTEXT_Rdx CONTEXT_Rcx+8
#define CONTEXT_Rbx CONTEXT_Rdx+8
#define CONTEXT_Rsp CONTEXT_Rbx+8
#define CONTEXT_Rbp CONTEXT_Rsp+8
#define CONTEXT_Rsi CONTEXT_Rbp+8
#define CONTEXT_Rdi CONTEXT_Rsi+8
#define CONTEXT_R8 CONTEXT_Rdi+8
#define CONTEXT_R9 CONTEXT_R8+8
#define CONTEXT_R10 CONTEXT_R9+8
#define CONTEXT_R11 CONTEXT_R10+8
#define CONTEXT_R12 CONTEXT_R11+8
#define CONTEXT_R13 CONTEXT_R12+8
#define CONTEXT_R14 CONTEXT_R13+8
#define CONTEXT_R15 CONTEXT_R14+8
#define CONTEXT_Rip CONTEXT_R15+8
#define CONTEXT_FltSave CONTEXT_Rip+8
#define FLOATING_SAVE_AREA_SIZE 4*8+24*16+96
#define CONTEXT_Xmm0 CONTEXT_FltSave+10*16
#define CONTEXT_Xmm1 CONTEXT_Xmm0+16
#define CONTEXT_Xmm2 CONTEXT_Xmm1+16
#define CONTEXT_Xmm3 CONTEXT_Xmm2+16
#define CONTEXT_Xmm4 CONTEXT_Xmm3+16
#define CONTEXT_Xmm5 CONTEXT_Xmm4+16
#define CONTEXT_Xmm6 CONTEXT_Xmm5+16
#define CONTEXT_Xmm7 CONTEXT_Xmm6+16
#define CONTEXT_Xmm8 CONTEXT_Xmm7+16
#define CONTEXT_Xmm9 CONTEXT_Xmm8+16
#define CONTEXT_Xmm10 CONTEXT_Xmm9+16
#define CONTEXT_Xmm11 CONTEXT_Xmm10+16
#define CONTEXT_Xmm12 CONTEXT_Xmm11+16
#define CONTEXT_Xmm13 CONTEXT_Xmm12+16
#define CONTEXT_Xmm14 CONTEXT_Xmm13+16
#define CONTEXT_Xmm15 CONTEXT_Xmm14+16
#define CONTEXT_VectorRegister CONTEXT_Xmm15+16
#define CONTEXT_VectorControl CONTEXT_VectorRegister+16*26
#define CONTEXT_DebugControl CONTEXT_VectorControl+8
#define CONTEXT_LastBranchToRip CONTEXT_DebugControl+8
#define CONTEXT_LastBranchFromRip CONTEXT_LastBranchToRip+8
#define CONTEXT_LastExceptionToRip CONTEXT_LastBranchFromRip+8
#define CONTEXT_LastExceptionFromRip CONTEXT_LastExceptionToRip+8

// Incoming:
//  RDI: Context*
//
LEAF_ENTRY CONTEXT_CaptureContext, _TEXT
    test    BYTE PTR [rdi + CONTEXT_ContextFlags], CONTEXT_INTEGER
    je      0f
    mov     [rdi + CONTEXT_Rdi], rdi
    mov     [rdi + CONTEXT_Rsi], rsi
    mov     [rdi + CONTEXT_Rbx], rbx
    mov     [rdi + CONTEXT_Rdx], rdx
    mov     [rdi + CONTEXT_Rcx], rcx
    mov     [rdi + CONTEXT_Rax], rax
    mov     [rdi + CONTEXT_Rbp], rbp
    mov     [rdi + CONTEXT_R8], r8
    mov     [rdi + CONTEXT_R9], r9
    mov     [rdi + CONTEXT_R10], r10
    mov     [rdi + CONTEXT_R11], r11
    mov     [rdi + CONTEXT_R12], r12
    mov     [rdi + CONTEXT_R13], r13
    mov     [rdi + CONTEXT_R14], r14
    mov     [rdi + CONTEXT_R15], r15   
    jmp     1f
0:
    nop
1:
    test    BYTE PTR [rdi + CONTEXT_ContextFlags], CONTEXT_CONTROL
    je      2f
    
    // Return address is @ RSP
    mov     rdx, [rsp]
    mov     [rdi + CONTEXT_Rip], rdx
.att_syntax 
    mov     %cs, CONTEXT_SegCs(%rdi)
.intel_syntax noprefix
    push_eflags
    pop_register rdx
    mov     [rdi + CONTEXT_EFlags], edx
    lea     rdx, [rsp + 8]
    mov     [rdi + CONTEXT_Rsp], rdx
.att_syntax 
    mov     %ss, CONTEXT_SegSs(%rdi)
.intel_syntax noprefix
2:
    // Need to double check this is producing the right result
    // also that FFSXR (fast save/restore) is not turned on
    // otherwise it omits the xmm registers.
    test    BYTE PTR [rdi + CONTEXT_ContextFlags], CONTEXT_FLOATING_POINT
    je      3f
    fxsave  [rdi + CONTEXT_FltSave]
3:
    test    BYTE PTR [rdi + CONTEXT_ContextFlags], CONTEXT_DEBUG_REGISTERS
    je      4f
    mov     rdx, dr0
    mov     [rdi + CONTEXT_Dr0], rdx
    mov     rdx, dr1
    mov     [rdi + CONTEXT_Dr1], rdx
    mov     rdx, dr2
    mov     [rdi + CONTEXT_Dr2], rdx
    mov     rdx, dr3
    mov     [rdi + CONTEXT_Dr3], rdx
    mov     rdx, dr6
    mov     [rdi + CONTEXT_Dr6], rdx
    mov     rdx, dr7
    mov     [rdi + CONTEXT_Dr7], rdx
4:
    ret
LEAF_END CONTEXT_CaptureContext, _TEXT

LEAF_ENTRY RtlCaptureContext, _TEXT
    mov     DWORD PTR [rdi + CONTEXT_ContextFlags], (CONTEXT_AMD64 | CONTEXT_FULL | CONTEXT_SEGMENTS)
    jmp     C_FUNC(CONTEXT_CaptureContext)
LEAF_END RtlCaptureContext, _TEXT

#else

#define CONTEXT_ContextFlags 0
#define CONTEXT_FLOATING_POINT 8
#define CONTEXT_FloatSave 7*4
#define FLOATING_SAVE_AREA_SIZE 8*4+80
#define CONTEXT_Edi CONTEXT_FloatSave + FLOATING_SAVE_AREA_SIZE + 4*4
#define CONTEXT_Esi CONTEXT_Edi+4
#define CONTEXT_Ebx CONTEXT_Esi+4
#define CONTEXT_Edx CONTEXT_Ebx+4
#define CONTEXT_Ecx CONTEXT_Edx+4
#define CONTEXT_Eax CONTEXT_Ecx+4
#define CONTEXT_Ebp CONTEXT_Eax+4
#define CONTEXT_Eip CONTEXT_Ebp+4
#define CONTEXT_SegCs CONTEXT_Eip+4
#define CONTEXT_EFlags CONTEXT_SegCs+4
#define CONTEXT_Esp CONTEXT_EFlags+4
#define CONTEXT_SegSs CONTEXT_Esp+4
#define CONTEXT_EXTENDED_REGISTERS 32
#define CONTEXT_ExtendedRegisters CONTEXT_SegSs+4
#define CONTEXT_Xmm0 CONTEXT_ExtendedRegisters+160
#define CONTEXT_Xmm1 CONTEXT_Xmm0+16
#define CONTEXT_Xmm2 CONTEXT_Xmm1+16
#define CONTEXT_Xmm3 CONTEXT_Xmm2+16
#define CONTEXT_Xmm4 CONTEXT_Xmm3+16
#define CONTEXT_Xmm5 CONTEXT_Xmm4+16
#define CONTEXT_Xmm6 CONTEXT_Xmm5+16
#define CONTEXT_Xmm7 CONTEXT_Xmm6+16

    .globl C_FUNC(CONTEXT_CaptureContext)
C_FUNC(CONTEXT_CaptureContext):
    push %eax
    mov 8(%esp), %eax
    mov %edi, CONTEXT_Edi(%eax)
    mov %esi, CONTEXT_Esi(%eax)
    mov %ebx, CONTEXT_Ebx(%eax)
    mov %edx, CONTEXT_Edx(%eax)
    mov %ecx, CONTEXT_Ecx(%eax)
    pop %ecx
    mov %ecx, CONTEXT_Eax(%eax)
    mov %ebp, CONTEXT_Ebp(%eax)
    mov (%esp), %edx
    mov %edx, CONTEXT_Eip(%eax)
    push %cs
    pop %edx
    mov %edx, CONTEXT_SegCs(%eax)
    pushf
    pop %edx
    mov %edx, CONTEXT_EFlags(%eax)
    lea 4(%esp), %edx
    mov %edx, CONTEXT_Esp(%eax)
    push %ss
    pop %edx
    mov %edx, CONTEXT_SegSs(%eax)
    testb $CONTEXT_FLOATING_POINT, CONTEXT_ContextFlags(%eax)
    je 0f
    fnsave CONTEXT_FloatSave(%eax)
    frstor CONTEXT_FloatSave(%eax)
0:
    testb $CONTEXT_EXTENDED_REGISTERS, CONTEXT_ContextFlags(%eax)
    je 2f
    movdqu %xmm0, CONTEXT_Xmm0(%eax)
    movdqu %xmm1, CONTEXT_Xmm1(%eax)
    movdqu %xmm2, CONTEXT_Xmm2(%eax)
    movdqu %xmm3, CONTEXT_Xmm3(%eax)
    movdqu %xmm4, CONTEXT_Xmm4(%eax)
    movdqu %xmm5, CONTEXT_Xmm5(%eax)
    movdqu %xmm6, CONTEXT_Xmm6(%eax)
    movdqu %xmm7, CONTEXT_Xmm7(%eax)
2:
    ret

#endif
