

#if defined(__MACOS8__)

void __CFSpinLock(volatile UInt32 *p) {
#pragma unused (p)
}
void __CFSpinUnlock(volatile UInt32 *p) {
#pragma unused (p)
}

#else

// void __CFSpinLock(volatile UInt32 *p);
__asm__ (
".globl ___CFSpinLock\n"
"___CFSpinLock:\n"
#if defined(__ppc__)
	"or r11,r3,r3\n"
	"b 1f\n"
	"2: addi r3,0,0\n"
	"li r0,-59\n"	// call swtch_pri(0)
	"sc\n"		// really, really bad to do it this way!
	"1: addi r4,0,1\n"
	"lwarx r5,0,r11\n"
        "stwcx. r4,0,r11\n"
        "cmpwi cr1,r5,0\n"
	"crand 2,2,6\n"
        "bc 4,2,2b\n"	// if either EQ bit was 0
        "isync\n"
	"blr\n"
#elif defined(__i386__)
	"pushl %ebp\n"
	"movl %esp,%ebp\n"
	"movl 8(%ebp),%ecx\n"
        "movl $1,%eax\n"
	"1: lock\n"
	"xchgl %eax,(%ecx)\n"
        "testl %eax,%eax\n"
        "jnz 1b\n"
	"leave\n"
	"ret\n"
#else
#error __CFSpinLock not implemented on this architecture
#endif
);

// void __CFSpinUnlock(volatile UInt32 *p);
__asm__ (
".globl ___CFSpinUnlock\n"
"___CFSpinUnlock:\n"
#if defined(__ppc__)
	"sync\n"
	"addi r4,0,0\n"
	"stw r4,0(r3)\n"
	"blr\n"
#elif defined(__i386__)
	"pushl %ebp\n"
	"movl %esp,%ebp\n"
	"movl 8(%ebp),%ecx\n"
	"movl $0,%eax\n"
	"lock\n"
	"xchgl %eax,(%ecx)\n"
	"leave\n"
	"ret\n"
#else
#error __CFSpinUnlock not implemented on this architecture
#endif
);

#endif
