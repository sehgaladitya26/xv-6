
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	b5813103          	ld	sp,-1192(sp) # 80009b58 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	0000a717          	auipc	a4,0xa
    80000056:	b5e70713          	addi	a4,a4,-1186 # 80009bb0 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00007797          	auipc	a5,0x7
    80000068:	84c78793          	addi	a5,a5,-1972 # 800068b0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd81e7>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de678793          	addi	a5,a5,-538 # 80000e94 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00003097          	auipc	ra,0x3
    80000130:	8ec080e7          	jalr	-1812(ra) # 80002a18 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	794080e7          	jalr	1940(ra) # 800008d0 <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00012517          	auipc	a0,0x12
    80000190:	b6450513          	addi	a0,a0,-1180 # 80011cf0 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a56080e7          	jalr	-1450(ra) # 80000bea <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00012497          	auipc	s1,0x12
    800001a0:	b5448493          	addi	s1,s1,-1196 # 80011cf0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00012917          	auipc	s2,0x12
    800001aa:	be290913          	addi	s2,s2,-1054 # 80011d88 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405b63          	blez	s4,8000022a <consoleread+0xc6>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71763          	bne	a4,a5,800001ee <consoleread+0x8a>
      if(killed(myproc())){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	a02080e7          	jalr	-1534(ra) # 80001bc6 <myproc>
    800001cc:	00002097          	auipc	ra,0x2
    800001d0:	696080e7          	jalr	1686(ra) # 80002862 <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	288080e7          	jalr	648(ra) # 80002462 <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fcf70de3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000204:	079c0663          	beq	s8,s9,80000270 <consoleread+0x10c>
    cbuf = c;
    80000208:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f8f40613          	addi	a2,s0,-113
    80000212:	85d6                	mv	a1,s5
    80000214:	855a                	mv	a0,s6
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	7ac080e7          	jalr	1964(ra) # 800029c2 <either_copyout>
    8000021e:	01a50663          	beq	a0,s10,8000022a <consoleread+0xc6>
    dst++;
    80000222:	0a85                	addi	s5,s5,1
    --n;
    80000224:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000226:	f9bc17e3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00012517          	auipc	a0,0x12
    8000022e:	ac650513          	addi	a0,a0,-1338 # 80011cf0 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a6c080e7          	jalr	-1428(ra) # 80000c9e <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00012517          	auipc	a0,0x12
    80000244:	ab050513          	addi	a0,a0,-1360 # 80011cf0 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	a56080e7          	jalr	-1450(ra) # 80000c9e <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70e6                	ld	ra,120(sp)
    80000254:	7446                	ld	s0,112(sp)
    80000256:	74a6                	ld	s1,104(sp)
    80000258:	7906                	ld	s2,96(sp)
    8000025a:	69e6                	ld	s3,88(sp)
    8000025c:	6a46                	ld	s4,80(sp)
    8000025e:	6aa6                	ld	s5,72(sp)
    80000260:	6b06                	ld	s6,64(sp)
    80000262:	7be2                	ld	s7,56(sp)
    80000264:	7c42                	ld	s8,48(sp)
    80000266:	7ca2                	ld	s9,40(sp)
    80000268:	7d02                	ld	s10,32(sp)
    8000026a:	6de2                	ld	s11,24(sp)
    8000026c:	6109                	addi	sp,sp,128
    8000026e:	8082                	ret
      if(n < target){
    80000270:	000a071b          	sext.w	a4,s4
    80000274:	fb777be3          	bgeu	a4,s7,8000022a <consoleread+0xc6>
        cons.r--;
    80000278:	00012717          	auipc	a4,0x12
    8000027c:	b0f72823          	sw	a5,-1264(a4) # 80011d88 <cons+0x98>
    80000280:	b76d                	j	8000022a <consoleread+0xc6>

0000000080000282 <consputc>:
{
    80000282:	1141                	addi	sp,sp,-16
    80000284:	e406                	sd	ra,8(sp)
    80000286:	e022                	sd	s0,0(sp)
    80000288:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028a:	10000793          	li	a5,256
    8000028e:	00f50a63          	beq	a0,a5,800002a2 <consputc+0x20>
    uartputc_sync(c);
    80000292:	00000097          	auipc	ra,0x0
    80000296:	564080e7          	jalr	1380(ra) # 800007f6 <uartputc_sync>
}
    8000029a:	60a2                	ld	ra,8(sp)
    8000029c:	6402                	ld	s0,0(sp)
    8000029e:	0141                	addi	sp,sp,16
    800002a0:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a2:	4521                	li	a0,8
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	552080e7          	jalr	1362(ra) # 800007f6 <uartputc_sync>
    800002ac:	02000513          	li	a0,32
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	546080e7          	jalr	1350(ra) # 800007f6 <uartputc_sync>
    800002b8:	4521                	li	a0,8
    800002ba:	00000097          	auipc	ra,0x0
    800002be:	53c080e7          	jalr	1340(ra) # 800007f6 <uartputc_sync>
    800002c2:	bfe1                	j	8000029a <consputc+0x18>

00000000800002c4 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c4:	1101                	addi	sp,sp,-32
    800002c6:	ec06                	sd	ra,24(sp)
    800002c8:	e822                	sd	s0,16(sp)
    800002ca:	e426                	sd	s1,8(sp)
    800002cc:	e04a                	sd	s2,0(sp)
    800002ce:	1000                	addi	s0,sp,32
    800002d0:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d2:	00012517          	auipc	a0,0x12
    800002d6:	a1e50513          	addi	a0,a0,-1506 # 80011cf0 <cons>
    800002da:	00001097          	auipc	ra,0x1
    800002de:	910080e7          	jalr	-1776(ra) # 80000bea <acquire>

  switch(c){
    800002e2:	47d5                	li	a5,21
    800002e4:	0af48663          	beq	s1,a5,80000390 <consoleintr+0xcc>
    800002e8:	0297ca63          	blt	a5,s1,8000031c <consoleintr+0x58>
    800002ec:	47a1                	li	a5,8
    800002ee:	0ef48763          	beq	s1,a5,800003dc <consoleintr+0x118>
    800002f2:	47c1                	li	a5,16
    800002f4:	10f49a63          	bne	s1,a5,80000408 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f8:	00002097          	auipc	ra,0x2
    800002fc:	776080e7          	jalr	1910(ra) # 80002a6e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00012517          	auipc	a0,0x12
    80000304:	9f050513          	addi	a0,a0,-1552 # 80011cf0 <cons>
    80000308:	00001097          	auipc	ra,0x1
    8000030c:	996080e7          	jalr	-1642(ra) # 80000c9e <release>
}
    80000310:	60e2                	ld	ra,24(sp)
    80000312:	6442                	ld	s0,16(sp)
    80000314:	64a2                	ld	s1,8(sp)
    80000316:	6902                	ld	s2,0(sp)
    80000318:	6105                	addi	sp,sp,32
    8000031a:	8082                	ret
  switch(c){
    8000031c:	07f00793          	li	a5,127
    80000320:	0af48e63          	beq	s1,a5,800003dc <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000324:	00012717          	auipc	a4,0x12
    80000328:	9cc70713          	addi	a4,a4,-1588 # 80011cf0 <cons>
    8000032c:	0a072783          	lw	a5,160(a4)
    80000330:	09872703          	lw	a4,152(a4)
    80000334:	9f99                	subw	a5,a5,a4
    80000336:	07f00713          	li	a4,127
    8000033a:	fcf763e3          	bltu	a4,a5,80000300 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033e:	47b5                	li	a5,13
    80000340:	0cf48763          	beq	s1,a5,8000040e <consoleintr+0x14a>
      consputc(c);
    80000344:	8526                	mv	a0,s1
    80000346:	00000097          	auipc	ra,0x0
    8000034a:	f3c080e7          	jalr	-196(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000034e:	00012797          	auipc	a5,0x12
    80000352:	9a278793          	addi	a5,a5,-1630 # 80011cf0 <cons>
    80000356:	0a07a683          	lw	a3,160(a5)
    8000035a:	0016871b          	addiw	a4,a3,1
    8000035e:	0007061b          	sext.w	a2,a4
    80000362:	0ae7a023          	sw	a4,160(a5)
    80000366:	07f6f693          	andi	a3,a3,127
    8000036a:	97b6                	add	a5,a5,a3
    8000036c:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000370:	47a9                	li	a5,10
    80000372:	0cf48563          	beq	s1,a5,8000043c <consoleintr+0x178>
    80000376:	4791                	li	a5,4
    80000378:	0cf48263          	beq	s1,a5,8000043c <consoleintr+0x178>
    8000037c:	00012797          	auipc	a5,0x12
    80000380:	a0c7a783          	lw	a5,-1524(a5) # 80011d88 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00012717          	auipc	a4,0x12
    80000394:	96070713          	addi	a4,a4,-1696 # 80011cf0 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00012497          	auipc	s1,0x12
    800003a4:	95048493          	addi	s1,s1,-1712 # 80011cf0 <cons>
    while(cons.e != cons.w &&
    800003a8:	4929                	li	s2,10
    800003aa:	f4f70be3          	beq	a4,a5,80000300 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003ae:	37fd                	addiw	a5,a5,-1
    800003b0:	07f7f713          	andi	a4,a5,127
    800003b4:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b6:	01874703          	lbu	a4,24(a4)
    800003ba:	f52703e3          	beq	a4,s2,80000300 <consoleintr+0x3c>
      cons.e--;
    800003be:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c2:	10000513          	li	a0,256
    800003c6:	00000097          	auipc	ra,0x0
    800003ca:	ebc080e7          	jalr	-324(ra) # 80000282 <consputc>
    while(cons.e != cons.w &&
    800003ce:	0a04a783          	lw	a5,160(s1)
    800003d2:	09c4a703          	lw	a4,156(s1)
    800003d6:	fcf71ce3          	bne	a4,a5,800003ae <consoleintr+0xea>
    800003da:	b71d                	j	80000300 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003dc:	00012717          	auipc	a4,0x12
    800003e0:	91470713          	addi	a4,a4,-1772 # 80011cf0 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00012717          	auipc	a4,0x12
    800003f6:	98f72f23          	sw	a5,-1634(a4) # 80011d90 <cons+0xa0>
      consputc(BACKSPACE);
    800003fa:	10000513          	li	a0,256
    800003fe:	00000097          	auipc	ra,0x0
    80000402:	e84080e7          	jalr	-380(ra) # 80000282 <consputc>
    80000406:	bded                	j	80000300 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000408:	ee048ce3          	beqz	s1,80000300 <consoleintr+0x3c>
    8000040c:	bf21                	j	80000324 <consoleintr+0x60>
      consputc(c);
    8000040e:	4529                	li	a0,10
    80000410:	00000097          	auipc	ra,0x0
    80000414:	e72080e7          	jalr	-398(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000418:	00012797          	auipc	a5,0x12
    8000041c:	8d878793          	addi	a5,a5,-1832 # 80011cf0 <cons>
    80000420:	0a07a703          	lw	a4,160(a5)
    80000424:	0017069b          	addiw	a3,a4,1
    80000428:	0006861b          	sext.w	a2,a3
    8000042c:	0ad7a023          	sw	a3,160(a5)
    80000430:	07f77713          	andi	a4,a4,127
    80000434:	97ba                	add	a5,a5,a4
    80000436:	4729                	li	a4,10
    80000438:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043c:	00012797          	auipc	a5,0x12
    80000440:	94c7a823          	sw	a2,-1712(a5) # 80011d8c <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00012517          	auipc	a0,0x12
    80000448:	94450513          	addi	a0,a0,-1724 # 80011d88 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	1c6080e7          	jalr	454(ra) # 80002612 <wakeup>
    80000454:	b575                	j	80000300 <consoleintr+0x3c>

0000000080000456 <consoleinit>:

void
consoleinit(void)
{
    80000456:	1141                	addi	sp,sp,-16
    80000458:	e406                	sd	ra,8(sp)
    8000045a:	e022                	sd	s0,0(sp)
    8000045c:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045e:	00009597          	auipc	a1,0x9
    80000462:	bb258593          	addi	a1,a1,-1102 # 80009010 <etext+0x10>
    80000466:	00012517          	auipc	a0,0x12
    8000046a:	88a50513          	addi	a0,a0,-1910 # 80011cf0 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	6ec080e7          	jalr	1772(ra) # 80000b5a <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00024797          	auipc	a5,0x24
    80000482:	c8278793          	addi	a5,a5,-894 # 80024100 <devsw>
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	cde70713          	addi	a4,a4,-802 # 80000164 <consoleread>
    8000048e:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000490:	00000717          	auipc	a4,0x0
    80000494:	c7270713          	addi	a4,a4,-910 # 80000102 <consolewrite>
    80000498:	ef98                	sd	a4,24(a5)
}
    8000049a:	60a2                	ld	ra,8(sp)
    8000049c:	6402                	ld	s0,0(sp)
    8000049e:	0141                	addi	sp,sp,16
    800004a0:	8082                	ret

00000000800004a2 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a2:	7179                	addi	sp,sp,-48
    800004a4:	f406                	sd	ra,40(sp)
    800004a6:	f022                	sd	s0,32(sp)
    800004a8:	ec26                	sd	s1,24(sp)
    800004aa:	e84a                	sd	s2,16(sp)
    800004ac:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ae:	c219                	beqz	a2,800004b4 <printint+0x12>
    800004b0:	08054663          	bltz	a0,8000053c <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b4:	2501                	sext.w	a0,a0
    800004b6:	4881                	li	a7,0
    800004b8:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004bc:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004be:	2581                	sext.w	a1,a1
    800004c0:	00009617          	auipc	a2,0x9
    800004c4:	b8060613          	addi	a2,a2,-1152 # 80009040 <digits>
    800004c8:	883a                	mv	a6,a4
    800004ca:	2705                	addiw	a4,a4,1
    800004cc:	02b577bb          	remuw	a5,a0,a1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	97b2                	add	a5,a5,a2
    800004d6:	0007c783          	lbu	a5,0(a5)
    800004da:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004de:	0005079b          	sext.w	a5,a0
    800004e2:	02b5553b          	divuw	a0,a0,a1
    800004e6:	0685                	addi	a3,a3,1
    800004e8:	feb7f0e3          	bgeu	a5,a1,800004c8 <printint+0x26>

  if(sign)
    800004ec:	00088b63          	beqz	a7,80000502 <printint+0x60>
    buf[i++] = '-';
    800004f0:	fe040793          	addi	a5,s0,-32
    800004f4:	973e                	add	a4,a4,a5
    800004f6:	02d00793          	li	a5,45
    800004fa:	fef70823          	sb	a5,-16(a4)
    800004fe:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000502:	02e05763          	blez	a4,80000530 <printint+0x8e>
    80000506:	fd040793          	addi	a5,s0,-48
    8000050a:	00e784b3          	add	s1,a5,a4
    8000050e:	fff78913          	addi	s2,a5,-1
    80000512:	993a                	add	s2,s2,a4
    80000514:	377d                	addiw	a4,a4,-1
    80000516:	1702                	slli	a4,a4,0x20
    80000518:	9301                	srli	a4,a4,0x20
    8000051a:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051e:	fff4c503          	lbu	a0,-1(s1)
    80000522:	00000097          	auipc	ra,0x0
    80000526:	d60080e7          	jalr	-672(ra) # 80000282 <consputc>
  while(--i >= 0)
    8000052a:	14fd                	addi	s1,s1,-1
    8000052c:	ff2499e3          	bne	s1,s2,8000051e <printint+0x7c>
}
    80000530:	70a2                	ld	ra,40(sp)
    80000532:	7402                	ld	s0,32(sp)
    80000534:	64e2                	ld	s1,24(sp)
    80000536:	6942                	ld	s2,16(sp)
    80000538:	6145                	addi	sp,sp,48
    8000053a:	8082                	ret
    x = -xx;
    8000053c:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000540:	4885                	li	a7,1
    x = -xx;
    80000542:	bf9d                	j	800004b8 <printint+0x16>

0000000080000544 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000544:	1101                	addi	sp,sp,-32
    80000546:	ec06                	sd	ra,24(sp)
    80000548:	e822                	sd	s0,16(sp)
    8000054a:	e426                	sd	s1,8(sp)
    8000054c:	1000                	addi	s0,sp,32
    8000054e:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000550:	00012797          	auipc	a5,0x12
    80000554:	8607a023          	sw	zero,-1952(a5) # 80011db0 <pr+0x18>
  printf("panic: ");
    80000558:	00009517          	auipc	a0,0x9
    8000055c:	ac050513          	addi	a0,a0,-1344 # 80009018 <etext+0x18>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	02e080e7          	jalr	46(ra) # 8000058e <printf>
  printf(s);
    80000568:	8526                	mv	a0,s1
    8000056a:	00000097          	auipc	ra,0x0
    8000056e:	024080e7          	jalr	36(ra) # 8000058e <printf>
  printf("\n");
    80000572:	00009517          	auipc	a0,0x9
    80000576:	b5650513          	addi	a0,a0,-1194 # 800090c8 <digits+0x88>
    8000057a:	00000097          	auipc	ra,0x0
    8000057e:	014080e7          	jalr	20(ra) # 8000058e <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000582:	4785                	li	a5,1
    80000584:	00009717          	auipc	a4,0x9
    80000588:	5ef72623          	sw	a5,1516(a4) # 80009b70 <panicked>
  for(;;)
    8000058c:	a001                	j	8000058c <panic+0x48>

000000008000058e <printf>:
{
    8000058e:	7131                	addi	sp,sp,-192
    80000590:	fc86                	sd	ra,120(sp)
    80000592:	f8a2                	sd	s0,112(sp)
    80000594:	f4a6                	sd	s1,104(sp)
    80000596:	f0ca                	sd	s2,96(sp)
    80000598:	ecce                	sd	s3,88(sp)
    8000059a:	e8d2                	sd	s4,80(sp)
    8000059c:	e4d6                	sd	s5,72(sp)
    8000059e:	e0da                	sd	s6,64(sp)
    800005a0:	fc5e                	sd	s7,56(sp)
    800005a2:	f862                	sd	s8,48(sp)
    800005a4:	f466                	sd	s9,40(sp)
    800005a6:	f06a                	sd	s10,32(sp)
    800005a8:	ec6e                	sd	s11,24(sp)
    800005aa:	0100                	addi	s0,sp,128
    800005ac:	8a2a                	mv	s4,a0
    800005ae:	e40c                	sd	a1,8(s0)
    800005b0:	e810                	sd	a2,16(s0)
    800005b2:	ec14                	sd	a3,24(s0)
    800005b4:	f018                	sd	a4,32(s0)
    800005b6:	f41c                	sd	a5,40(s0)
    800005b8:	03043823          	sd	a6,48(s0)
    800005bc:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c0:	00011d97          	auipc	s11,0x11
    800005c4:	7f0dad83          	lw	s11,2032(s11) # 80011db0 <pr+0x18>
  if(locking)
    800005c8:	020d9b63          	bnez	s11,800005fe <printf+0x70>
  if (fmt == 0)
    800005cc:	040a0263          	beqz	s4,80000610 <printf+0x82>
  va_start(ap, fmt);
    800005d0:	00840793          	addi	a5,s0,8
    800005d4:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d8:	000a4503          	lbu	a0,0(s4)
    800005dc:	16050263          	beqz	a0,80000740 <printf+0x1b2>
    800005e0:	4481                	li	s1,0
    if(c != '%'){
    800005e2:	02500a93          	li	s5,37
    switch(c){
    800005e6:	07000b13          	li	s6,112
  consputc('x');
    800005ea:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ec:	00009b97          	auipc	s7,0x9
    800005f0:	a54b8b93          	addi	s7,s7,-1452 # 80009040 <digits>
    switch(c){
    800005f4:	07300c93          	li	s9,115
    800005f8:	06400c13          	li	s8,100
    800005fc:	a82d                	j	80000636 <printf+0xa8>
    acquire(&pr.lock);
    800005fe:	00011517          	auipc	a0,0x11
    80000602:	79a50513          	addi	a0,a0,1946 # 80011d98 <pr>
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	5e4080e7          	jalr	1508(ra) # 80000bea <acquire>
    8000060e:	bf7d                	j	800005cc <printf+0x3e>
    panic("null fmt");
    80000610:	00009517          	auipc	a0,0x9
    80000614:	a1850513          	addi	a0,a0,-1512 # 80009028 <etext+0x28>
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	f2c080e7          	jalr	-212(ra) # 80000544 <panic>
      consputc(c);
    80000620:	00000097          	auipc	ra,0x0
    80000624:	c62080e7          	jalr	-926(ra) # 80000282 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000628:	2485                	addiw	s1,s1,1
    8000062a:	009a07b3          	add	a5,s4,s1
    8000062e:	0007c503          	lbu	a0,0(a5)
    80000632:	10050763          	beqz	a0,80000740 <printf+0x1b2>
    if(c != '%'){
    80000636:	ff5515e3          	bne	a0,s5,80000620 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063a:	2485                	addiw	s1,s1,1
    8000063c:	009a07b3          	add	a5,s4,s1
    80000640:	0007c783          	lbu	a5,0(a5)
    80000644:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000648:	cfe5                	beqz	a5,80000740 <printf+0x1b2>
    switch(c){
    8000064a:	05678a63          	beq	a5,s6,8000069e <printf+0x110>
    8000064e:	02fb7663          	bgeu	s6,a5,8000067a <printf+0xec>
    80000652:	09978963          	beq	a5,s9,800006e4 <printf+0x156>
    80000656:	07800713          	li	a4,120
    8000065a:	0ce79863          	bne	a5,a4,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000065e:	f8843783          	ld	a5,-120(s0)
    80000662:	00878713          	addi	a4,a5,8
    80000666:	f8e43423          	sd	a4,-120(s0)
    8000066a:	4605                	li	a2,1
    8000066c:	85ea                	mv	a1,s10
    8000066e:	4388                	lw	a0,0(a5)
    80000670:	00000097          	auipc	ra,0x0
    80000674:	e32080e7          	jalr	-462(ra) # 800004a2 <printint>
      break;
    80000678:	bf45                	j	80000628 <printf+0x9a>
    switch(c){
    8000067a:	0b578263          	beq	a5,s5,8000071e <printf+0x190>
    8000067e:	0b879663          	bne	a5,s8,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000682:	f8843783          	ld	a5,-120(s0)
    80000686:	00878713          	addi	a4,a5,8
    8000068a:	f8e43423          	sd	a4,-120(s0)
    8000068e:	4605                	li	a2,1
    80000690:	45a9                	li	a1,10
    80000692:	4388                	lw	a0,0(a5)
    80000694:	00000097          	auipc	ra,0x0
    80000698:	e0e080e7          	jalr	-498(ra) # 800004a2 <printint>
      break;
    8000069c:	b771                	j	80000628 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069e:	f8843783          	ld	a5,-120(s0)
    800006a2:	00878713          	addi	a4,a5,8
    800006a6:	f8e43423          	sd	a4,-120(s0)
    800006aa:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006ae:	03000513          	li	a0,48
    800006b2:	00000097          	auipc	ra,0x0
    800006b6:	bd0080e7          	jalr	-1072(ra) # 80000282 <consputc>
  consputc('x');
    800006ba:	07800513          	li	a0,120
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bc4080e7          	jalr	-1084(ra) # 80000282 <consputc>
    800006c6:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c8:	03c9d793          	srli	a5,s3,0x3c
    800006cc:	97de                	add	a5,a5,s7
    800006ce:	0007c503          	lbu	a0,0(a5)
    800006d2:	00000097          	auipc	ra,0x0
    800006d6:	bb0080e7          	jalr	-1104(ra) # 80000282 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006da:	0992                	slli	s3,s3,0x4
    800006dc:	397d                	addiw	s2,s2,-1
    800006de:	fe0915e3          	bnez	s2,800006c8 <printf+0x13a>
    800006e2:	b799                	j	80000628 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e4:	f8843783          	ld	a5,-120(s0)
    800006e8:	00878713          	addi	a4,a5,8
    800006ec:	f8e43423          	sd	a4,-120(s0)
    800006f0:	0007b903          	ld	s2,0(a5)
    800006f4:	00090e63          	beqz	s2,80000710 <printf+0x182>
      for(; *s; s++)
    800006f8:	00094503          	lbu	a0,0(s2)
    800006fc:	d515                	beqz	a0,80000628 <printf+0x9a>
        consputc(*s);
    800006fe:	00000097          	auipc	ra,0x0
    80000702:	b84080e7          	jalr	-1148(ra) # 80000282 <consputc>
      for(; *s; s++)
    80000706:	0905                	addi	s2,s2,1
    80000708:	00094503          	lbu	a0,0(s2)
    8000070c:	f96d                	bnez	a0,800006fe <printf+0x170>
    8000070e:	bf29                	j	80000628 <printf+0x9a>
        s = "(null)";
    80000710:	00009917          	auipc	s2,0x9
    80000714:	91090913          	addi	s2,s2,-1776 # 80009020 <etext+0x20>
      for(; *s; s++)
    80000718:	02800513          	li	a0,40
    8000071c:	b7cd                	j	800006fe <printf+0x170>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b62080e7          	jalr	-1182(ra) # 80000282 <consputc>
      break;
    80000728:	b701                	j	80000628 <printf+0x9a>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b56080e7          	jalr	-1194(ra) # 80000282 <consputc>
      consputc(c);
    80000734:	854a                	mv	a0,s2
    80000736:	00000097          	auipc	ra,0x0
    8000073a:	b4c080e7          	jalr	-1204(ra) # 80000282 <consputc>
      break;
    8000073e:	b5ed                	j	80000628 <printf+0x9a>
  if(locking)
    80000740:	020d9163          	bnez	s11,80000762 <printf+0x1d4>
}
    80000744:	70e6                	ld	ra,120(sp)
    80000746:	7446                	ld	s0,112(sp)
    80000748:	74a6                	ld	s1,104(sp)
    8000074a:	7906                	ld	s2,96(sp)
    8000074c:	69e6                	ld	s3,88(sp)
    8000074e:	6a46                	ld	s4,80(sp)
    80000750:	6aa6                	ld	s5,72(sp)
    80000752:	6b06                	ld	s6,64(sp)
    80000754:	7be2                	ld	s7,56(sp)
    80000756:	7c42                	ld	s8,48(sp)
    80000758:	7ca2                	ld	s9,40(sp)
    8000075a:	7d02                	ld	s10,32(sp)
    8000075c:	6de2                	ld	s11,24(sp)
    8000075e:	6129                	addi	sp,sp,192
    80000760:	8082                	ret
    release(&pr.lock);
    80000762:	00011517          	auipc	a0,0x11
    80000766:	63650513          	addi	a0,a0,1590 # 80011d98 <pr>
    8000076a:	00000097          	auipc	ra,0x0
    8000076e:	534080e7          	jalr	1332(ra) # 80000c9e <release>
}
    80000772:	bfc9                	j	80000744 <printf+0x1b6>

0000000080000774 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000774:	1101                	addi	sp,sp,-32
    80000776:	ec06                	sd	ra,24(sp)
    80000778:	e822                	sd	s0,16(sp)
    8000077a:	e426                	sd	s1,8(sp)
    8000077c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000077e:	00011497          	auipc	s1,0x11
    80000782:	61a48493          	addi	s1,s1,1562 # 80011d98 <pr>
    80000786:	00009597          	auipc	a1,0x9
    8000078a:	8b258593          	addi	a1,a1,-1870 # 80009038 <etext+0x38>
    8000078e:	8526                	mv	a0,s1
    80000790:	00000097          	auipc	ra,0x0
    80000794:	3ca080e7          	jalr	970(ra) # 80000b5a <initlock>
  pr.locking = 1;
    80000798:	4785                	li	a5,1
    8000079a:	cc9c                	sw	a5,24(s1)
}
    8000079c:	60e2                	ld	ra,24(sp)
    8000079e:	6442                	ld	s0,16(sp)
    800007a0:	64a2                	ld	s1,8(sp)
    800007a2:	6105                	addi	sp,sp,32
    800007a4:	8082                	ret

00000000800007a6 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a6:	1141                	addi	sp,sp,-16
    800007a8:	e406                	sd	ra,8(sp)
    800007aa:	e022                	sd	s0,0(sp)
    800007ac:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ae:	100007b7          	lui	a5,0x10000
    800007b2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b6:	f8000713          	li	a4,-128
    800007ba:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007be:	470d                	li	a4,3
    800007c0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007cc:	469d                	li	a3,7
    800007ce:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d6:	00009597          	auipc	a1,0x9
    800007da:	88258593          	addi	a1,a1,-1918 # 80009058 <digits+0x18>
    800007de:	00011517          	auipc	a0,0x11
    800007e2:	5da50513          	addi	a0,a0,1498 # 80011db8 <uart_tx_lock>
    800007e6:	00000097          	auipc	ra,0x0
    800007ea:	374080e7          	jalr	884(ra) # 80000b5a <initlock>
}
    800007ee:	60a2                	ld	ra,8(sp)
    800007f0:	6402                	ld	s0,0(sp)
    800007f2:	0141                	addi	sp,sp,16
    800007f4:	8082                	ret

00000000800007f6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f6:	1101                	addi	sp,sp,-32
    800007f8:	ec06                	sd	ra,24(sp)
    800007fa:	e822                	sd	s0,16(sp)
    800007fc:	e426                	sd	s1,8(sp)
    800007fe:	1000                	addi	s0,sp,32
    80000800:	84aa                	mv	s1,a0
  push_off();
    80000802:	00000097          	auipc	ra,0x0
    80000806:	39c080e7          	jalr	924(ra) # 80000b9e <push_off>

  if(panicked){
    8000080a:	00009797          	auipc	a5,0x9
    8000080e:	3667a783          	lw	a5,870(a5) # 80009b70 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	10000737          	lui	a4,0x10000
  if(panicked){
    80000816:	c391                	beqz	a5,8000081a <uartputc_sync+0x24>
    for(;;)
    80000818:	a001                	j	80000818 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000081e:	0ff7f793          	andi	a5,a5,255
    80000822:	0207f793          	andi	a5,a5,32
    80000826:	dbf5                	beqz	a5,8000081a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000828:	0ff4f793          	andi	a5,s1,255
    8000082c:	10000737          	lui	a4,0x10000
    80000830:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000834:	00000097          	auipc	ra,0x0
    80000838:	40a080e7          	jalr	1034(ra) # 80000c3e <pop_off>
}
    8000083c:	60e2                	ld	ra,24(sp)
    8000083e:	6442                	ld	s0,16(sp)
    80000840:	64a2                	ld	s1,8(sp)
    80000842:	6105                	addi	sp,sp,32
    80000844:	8082                	ret

0000000080000846 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000846:	00009717          	auipc	a4,0x9
    8000084a:	33273703          	ld	a4,818(a4) # 80009b78 <uart_tx_r>
    8000084e:	00009797          	auipc	a5,0x9
    80000852:	3327b783          	ld	a5,818(a5) # 80009b80 <uart_tx_w>
    80000856:	06e78c63          	beq	a5,a4,800008ce <uartstart+0x88>
{
    8000085a:	7139                	addi	sp,sp,-64
    8000085c:	fc06                	sd	ra,56(sp)
    8000085e:	f822                	sd	s0,48(sp)
    80000860:	f426                	sd	s1,40(sp)
    80000862:	f04a                	sd	s2,32(sp)
    80000864:	ec4e                	sd	s3,24(sp)
    80000866:	e852                	sd	s4,16(sp)
    80000868:	e456                	sd	s5,8(sp)
    8000086a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000086c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000870:	00011a17          	auipc	s4,0x11
    80000874:	548a0a13          	addi	s4,s4,1352 # 80011db8 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00009497          	auipc	s1,0x9
    8000087c:	30048493          	addi	s1,s1,768 # 80009b78 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00009997          	auipc	s3,0x9
    80000884:	30098993          	addi	s3,s3,768 # 80009b80 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000888:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000088c:	0ff7f793          	andi	a5,a5,255
    80000890:	0207f793          	andi	a5,a5,32
    80000894:	c785                	beqz	a5,800008bc <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000896:	01f77793          	andi	a5,a4,31
    8000089a:	97d2                	add	a5,a5,s4
    8000089c:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    800008a0:	0705                	addi	a4,a4,1
    800008a2:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a4:	8526                	mv	a0,s1
    800008a6:	00002097          	auipc	ra,0x2
    800008aa:	d6c080e7          	jalr	-660(ra) # 80002612 <wakeup>
    
    WriteReg(THR, c);
    800008ae:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008b2:	6098                	ld	a4,0(s1)
    800008b4:	0009b783          	ld	a5,0(s3)
    800008b8:	fce798e3          	bne	a5,a4,80000888 <uartstart+0x42>
  }
}
    800008bc:	70e2                	ld	ra,56(sp)
    800008be:	7442                	ld	s0,48(sp)
    800008c0:	74a2                	ld	s1,40(sp)
    800008c2:	7902                	ld	s2,32(sp)
    800008c4:	69e2                	ld	s3,24(sp)
    800008c6:	6a42                	ld	s4,16(sp)
    800008c8:	6aa2                	ld	s5,8(sp)
    800008ca:	6121                	addi	sp,sp,64
    800008cc:	8082                	ret
    800008ce:	8082                	ret

00000000800008d0 <uartputc>:
{
    800008d0:	7179                	addi	sp,sp,-48
    800008d2:	f406                	sd	ra,40(sp)
    800008d4:	f022                	sd	s0,32(sp)
    800008d6:	ec26                	sd	s1,24(sp)
    800008d8:	e84a                	sd	s2,16(sp)
    800008da:	e44e                	sd	s3,8(sp)
    800008dc:	e052                	sd	s4,0(sp)
    800008de:	1800                	addi	s0,sp,48
    800008e0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008e2:	00011517          	auipc	a0,0x11
    800008e6:	4d650513          	addi	a0,a0,1238 # 80011db8 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	300080e7          	jalr	768(ra) # 80000bea <acquire>
  if(panicked){
    800008f2:	00009797          	auipc	a5,0x9
    800008f6:	27e7a783          	lw	a5,638(a5) # 80009b70 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00009797          	auipc	a5,0x9
    80000900:	2847b783          	ld	a5,644(a5) # 80009b80 <uart_tx_w>
    80000904:	00009717          	auipc	a4,0x9
    80000908:	27473703          	ld	a4,628(a4) # 80009b78 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	4a8a0a13          	addi	s4,s4,1192 # 80011db8 <uart_tx_lock>
    80000918:	00009497          	auipc	s1,0x9
    8000091c:	26048493          	addi	s1,s1,608 # 80009b78 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00009917          	auipc	s2,0x9
    80000924:	26090913          	addi	s2,s2,608 # 80009b80 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00002097          	auipc	ra,0x2
    80000934:	b32080e7          	jalr	-1230(ra) # 80002462 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00011497          	auipc	s1,0x11
    8000094a:	47248493          	addi	s1,s1,1138 # 80011db8 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00009717          	auipc	a4,0x9
    8000095e:	22f73323          	sd	a5,550(a4) # 80009b80 <uart_tx_w>
  uartstart();
    80000962:	00000097          	auipc	ra,0x0
    80000966:	ee4080e7          	jalr	-284(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    8000096a:	8526                	mv	a0,s1
    8000096c:	00000097          	auipc	ra,0x0
    80000970:	332080e7          	jalr	818(ra) # 80000c9e <release>
}
    80000974:	70a2                	ld	ra,40(sp)
    80000976:	7402                	ld	s0,32(sp)
    80000978:	64e2                	ld	s1,24(sp)
    8000097a:	6942                	ld	s2,16(sp)
    8000097c:	69a2                	ld	s3,8(sp)
    8000097e:	6a02                	ld	s4,0(sp)
    80000980:	6145                	addi	sp,sp,48
    80000982:	8082                	ret
    for(;;)
    80000984:	a001                	j	80000984 <uartputc+0xb4>

0000000080000986 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000986:	1141                	addi	sp,sp,-16
    80000988:	e422                	sd	s0,8(sp)
    8000098a:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000098c:	100007b7          	lui	a5,0x10000
    80000990:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000994:	8b85                	andi	a5,a5,1
    80000996:	cb91                	beqz	a5,800009aa <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000998:	100007b7          	lui	a5,0x10000
    8000099c:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009a0:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009a4:	6422                	ld	s0,8(sp)
    800009a6:	0141                	addi	sp,sp,16
    800009a8:	8082                	ret
    return -1;
    800009aa:	557d                	li	a0,-1
    800009ac:	bfe5                	j	800009a4 <uartgetc+0x1e>

00000000800009ae <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009ae:	1101                	addi	sp,sp,-32
    800009b0:	ec06                	sd	ra,24(sp)
    800009b2:	e822                	sd	s0,16(sp)
    800009b4:	e426                	sd	s1,8(sp)
    800009b6:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b8:	54fd                	li	s1,-1
    int c = uartgetc();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	fcc080e7          	jalr	-52(ra) # 80000986 <uartgetc>
    if(c == -1)
    800009c2:	00950763          	beq	a0,s1,800009d0 <uartintr+0x22>
      break;
    consoleintr(c);
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	8fe080e7          	jalr	-1794(ra) # 800002c4 <consoleintr>
  while(1){
    800009ce:	b7f5                	j	800009ba <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009d0:	00011497          	auipc	s1,0x11
    800009d4:	3e848493          	addi	s1,s1,1000 # 80011db8 <uart_tx_lock>
    800009d8:	8526                	mv	a0,s1
    800009da:	00000097          	auipc	ra,0x0
    800009de:	210080e7          	jalr	528(ra) # 80000bea <acquire>
  uartstart();
    800009e2:	00000097          	auipc	ra,0x0
    800009e6:	e64080e7          	jalr	-412(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    800009ea:	8526                	mv	a0,s1
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	2b2080e7          	jalr	690(ra) # 80000c9e <release>
}
    800009f4:	60e2                	ld	ra,24(sp)
    800009f6:	6442                	ld	s0,16(sp)
    800009f8:	64a2                	ld	s1,8(sp)
    800009fa:	6105                	addi	sp,sp,32
    800009fc:	8082                	ret

00000000800009fe <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009fe:	1101                	addi	sp,sp,-32
    80000a00:	ec06                	sd	ra,24(sp)
    80000a02:	e822                	sd	s0,16(sp)
    80000a04:	e426                	sd	s1,8(sp)
    80000a06:	e04a                	sd	s2,0(sp)
    80000a08:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a0a:	03451793          	slli	a5,a0,0x34
    80000a0e:	ebb9                	bnez	a5,80000a64 <kfree+0x66>
    80000a10:	84aa                	mv	s1,a0
    80000a12:	00026797          	auipc	a5,0x26
    80000a16:	c0678793          	addi	a5,a5,-1018 # 80026618 <end>
    80000a1a:	04f56563          	bltu	a0,a5,80000a64 <kfree+0x66>
    80000a1e:	47c5                	li	a5,17
    80000a20:	07ee                	slli	a5,a5,0x1b
    80000a22:	04f57163          	bgeu	a0,a5,80000a64 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a26:	6605                	lui	a2,0x1
    80000a28:	4585                	li	a1,1
    80000a2a:	00000097          	auipc	ra,0x0
    80000a2e:	2bc080e7          	jalr	700(ra) # 80000ce6 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a32:	00011917          	auipc	s2,0x11
    80000a36:	3be90913          	addi	s2,s2,958 # 80011df0 <kmem>
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	1ae080e7          	jalr	430(ra) # 80000bea <acquire>
  r->next = kmem.freelist;
    80000a44:	01893783          	ld	a5,24(s2)
    80000a48:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a4a:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a4e:	854a                	mv	a0,s2
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	24e080e7          	jalr	590(ra) # 80000c9e <release>
}
    80000a58:	60e2                	ld	ra,24(sp)
    80000a5a:	6442                	ld	s0,16(sp)
    80000a5c:	64a2                	ld	s1,8(sp)
    80000a5e:	6902                	ld	s2,0(sp)
    80000a60:	6105                	addi	sp,sp,32
    80000a62:	8082                	ret
    panic("kfree");
    80000a64:	00008517          	auipc	a0,0x8
    80000a68:	5fc50513          	addi	a0,a0,1532 # 80009060 <digits+0x20>
    80000a6c:	00000097          	auipc	ra,0x0
    80000a70:	ad8080e7          	jalr	-1320(ra) # 80000544 <panic>

0000000080000a74 <freerange>:
{
    80000a74:	7179                	addi	sp,sp,-48
    80000a76:	f406                	sd	ra,40(sp)
    80000a78:	f022                	sd	s0,32(sp)
    80000a7a:	ec26                	sd	s1,24(sp)
    80000a7c:	e84a                	sd	s2,16(sp)
    80000a7e:	e44e                	sd	s3,8(sp)
    80000a80:	e052                	sd	s4,0(sp)
    80000a82:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a84:	6785                	lui	a5,0x1
    80000a86:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a8a:	94aa                	add	s1,s1,a0
    80000a8c:	757d                	lui	a0,0xfffff
    80000a8e:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a90:	94be                	add	s1,s1,a5
    80000a92:	0095ee63          	bltu	a1,s1,80000aae <freerange+0x3a>
    80000a96:	892e                	mv	s2,a1
    kfree(p);
    80000a98:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a9a:	6985                	lui	s3,0x1
    kfree(p);
    80000a9c:	01448533          	add	a0,s1,s4
    80000aa0:	00000097          	auipc	ra,0x0
    80000aa4:	f5e080e7          	jalr	-162(ra) # 800009fe <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa8:	94ce                	add	s1,s1,s3
    80000aaa:	fe9979e3          	bgeu	s2,s1,80000a9c <freerange+0x28>
}
    80000aae:	70a2                	ld	ra,40(sp)
    80000ab0:	7402                	ld	s0,32(sp)
    80000ab2:	64e2                	ld	s1,24(sp)
    80000ab4:	6942                	ld	s2,16(sp)
    80000ab6:	69a2                	ld	s3,8(sp)
    80000ab8:	6a02                	ld	s4,0(sp)
    80000aba:	6145                	addi	sp,sp,48
    80000abc:	8082                	ret

0000000080000abe <kinit>:
{
    80000abe:	1141                	addi	sp,sp,-16
    80000ac0:	e406                	sd	ra,8(sp)
    80000ac2:	e022                	sd	s0,0(sp)
    80000ac4:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac6:	00008597          	auipc	a1,0x8
    80000aca:	5a258593          	addi	a1,a1,1442 # 80009068 <digits+0x28>
    80000ace:	00011517          	auipc	a0,0x11
    80000ad2:	32250513          	addi	a0,a0,802 # 80011df0 <kmem>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	084080e7          	jalr	132(ra) # 80000b5a <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ade:	45c5                	li	a1,17
    80000ae0:	05ee                	slli	a1,a1,0x1b
    80000ae2:	00026517          	auipc	a0,0x26
    80000ae6:	b3650513          	addi	a0,a0,-1226 # 80026618 <end>
    80000aea:	00000097          	auipc	ra,0x0
    80000aee:	f8a080e7          	jalr	-118(ra) # 80000a74 <freerange>
}
    80000af2:	60a2                	ld	ra,8(sp)
    80000af4:	6402                	ld	s0,0(sp)
    80000af6:	0141                	addi	sp,sp,16
    80000af8:	8082                	ret

0000000080000afa <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000afa:	1101                	addi	sp,sp,-32
    80000afc:	ec06                	sd	ra,24(sp)
    80000afe:	e822                	sd	s0,16(sp)
    80000b00:	e426                	sd	s1,8(sp)
    80000b02:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b04:	00011497          	auipc	s1,0x11
    80000b08:	2ec48493          	addi	s1,s1,748 # 80011df0 <kmem>
    80000b0c:	8526                	mv	a0,s1
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	0dc080e7          	jalr	220(ra) # 80000bea <acquire>
  r = kmem.freelist;
    80000b16:	6c84                	ld	s1,24(s1)
  if(r)
    80000b18:	c885                	beqz	s1,80000b48 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b1a:	609c                	ld	a5,0(s1)
    80000b1c:	00011517          	auipc	a0,0x11
    80000b20:	2d450513          	addi	a0,a0,724 # 80011df0 <kmem>
    80000b24:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b26:	00000097          	auipc	ra,0x0
    80000b2a:	178080e7          	jalr	376(ra) # 80000c9e <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b2e:	6605                	lui	a2,0x1
    80000b30:	4595                	li	a1,5
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	1b2080e7          	jalr	434(ra) # 80000ce6 <memset>
  return (void*)r;
}
    80000b3c:	8526                	mv	a0,s1
    80000b3e:	60e2                	ld	ra,24(sp)
    80000b40:	6442                	ld	s0,16(sp)
    80000b42:	64a2                	ld	s1,8(sp)
    80000b44:	6105                	addi	sp,sp,32
    80000b46:	8082                	ret
  release(&kmem.lock);
    80000b48:	00011517          	auipc	a0,0x11
    80000b4c:	2a850513          	addi	a0,a0,680 # 80011df0 <kmem>
    80000b50:	00000097          	auipc	ra,0x0
    80000b54:	14e080e7          	jalr	334(ra) # 80000c9e <release>
  if(r)
    80000b58:	b7d5                	j	80000b3c <kalloc+0x42>

0000000080000b5a <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b5a:	1141                	addi	sp,sp,-16
    80000b5c:	e422                	sd	s0,8(sp)
    80000b5e:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b60:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b62:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b66:	00053823          	sd	zero,16(a0)
}
    80000b6a:	6422                	ld	s0,8(sp)
    80000b6c:	0141                	addi	sp,sp,16
    80000b6e:	8082                	ret

0000000080000b70 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b70:	411c                	lw	a5,0(a0)
    80000b72:	e399                	bnez	a5,80000b78 <holding+0x8>
    80000b74:	4501                	li	a0,0
  return r;
}
    80000b76:	8082                	ret
{
    80000b78:	1101                	addi	sp,sp,-32
    80000b7a:	ec06                	sd	ra,24(sp)
    80000b7c:	e822                	sd	s0,16(sp)
    80000b7e:	e426                	sd	s1,8(sp)
    80000b80:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b82:	6904                	ld	s1,16(a0)
    80000b84:	00001097          	auipc	ra,0x1
    80000b88:	026080e7          	jalr	38(ra) # 80001baa <mycpu>
    80000b8c:	40a48533          	sub	a0,s1,a0
    80000b90:	00153513          	seqz	a0,a0
}
    80000b94:	60e2                	ld	ra,24(sp)
    80000b96:	6442                	ld	s0,16(sp)
    80000b98:	64a2                	ld	s1,8(sp)
    80000b9a:	6105                	addi	sp,sp,32
    80000b9c:	8082                	ret

0000000080000b9e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b9e:	1101                	addi	sp,sp,-32
    80000ba0:	ec06                	sd	ra,24(sp)
    80000ba2:	e822                	sd	s0,16(sp)
    80000ba4:	e426                	sd	s1,8(sp)
    80000ba6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba8:	100024f3          	csrr	s1,sstatus
    80000bac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bb0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bb2:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb6:	00001097          	auipc	ra,0x1
    80000bba:	ff4080e7          	jalr	-12(ra) # 80001baa <mycpu>
    80000bbe:	5d3c                	lw	a5,120(a0)
    80000bc0:	cf89                	beqz	a5,80000bda <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bc2:	00001097          	auipc	ra,0x1
    80000bc6:	fe8080e7          	jalr	-24(ra) # 80001baa <mycpu>
    80000bca:	5d3c                	lw	a5,120(a0)
    80000bcc:	2785                	addiw	a5,a5,1
    80000bce:	dd3c                	sw	a5,120(a0)
}
    80000bd0:	60e2                	ld	ra,24(sp)
    80000bd2:	6442                	ld	s0,16(sp)
    80000bd4:	64a2                	ld	s1,8(sp)
    80000bd6:	6105                	addi	sp,sp,32
    80000bd8:	8082                	ret
    mycpu()->intena = old;
    80000bda:	00001097          	auipc	ra,0x1
    80000bde:	fd0080e7          	jalr	-48(ra) # 80001baa <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000be2:	8085                	srli	s1,s1,0x1
    80000be4:	8885                	andi	s1,s1,1
    80000be6:	dd64                	sw	s1,124(a0)
    80000be8:	bfe9                	j	80000bc2 <push_off+0x24>

0000000080000bea <acquire>:
{
    80000bea:	1101                	addi	sp,sp,-32
    80000bec:	ec06                	sd	ra,24(sp)
    80000bee:	e822                	sd	s0,16(sp)
    80000bf0:	e426                	sd	s1,8(sp)
    80000bf2:	1000                	addi	s0,sp,32
    80000bf4:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf6:	00000097          	auipc	ra,0x0
    80000bfa:	fa8080e7          	jalr	-88(ra) # 80000b9e <push_off>
  if(holding(lk))
    80000bfe:	8526                	mv	a0,s1
    80000c00:	00000097          	auipc	ra,0x0
    80000c04:	f70080e7          	jalr	-144(ra) # 80000b70 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c08:	4705                	li	a4,1
  if(holding(lk))
    80000c0a:	e115                	bnez	a0,80000c2e <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c0c:	87ba                	mv	a5,a4
    80000c0e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c12:	2781                	sext.w	a5,a5
    80000c14:	ffe5                	bnez	a5,80000c0c <acquire+0x22>
  __sync_synchronize();
    80000c16:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c1a:	00001097          	auipc	ra,0x1
    80000c1e:	f90080e7          	jalr	-112(ra) # 80001baa <mycpu>
    80000c22:	e888                	sd	a0,16(s1)
}
    80000c24:	60e2                	ld	ra,24(sp)
    80000c26:	6442                	ld	s0,16(sp)
    80000c28:	64a2                	ld	s1,8(sp)
    80000c2a:	6105                	addi	sp,sp,32
    80000c2c:	8082                	ret
    panic("acquire");
    80000c2e:	00008517          	auipc	a0,0x8
    80000c32:	44250513          	addi	a0,a0,1090 # 80009070 <digits+0x30>
    80000c36:	00000097          	auipc	ra,0x0
    80000c3a:	90e080e7          	jalr	-1778(ra) # 80000544 <panic>

0000000080000c3e <pop_off>:

void
pop_off(void)
{
    80000c3e:	1141                	addi	sp,sp,-16
    80000c40:	e406                	sd	ra,8(sp)
    80000c42:	e022                	sd	s0,0(sp)
    80000c44:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c46:	00001097          	auipc	ra,0x1
    80000c4a:	f64080e7          	jalr	-156(ra) # 80001baa <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c4e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c52:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c54:	e78d                	bnez	a5,80000c7e <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c56:	5d3c                	lw	a5,120(a0)
    80000c58:	02f05b63          	blez	a5,80000c8e <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c5c:	37fd                	addiw	a5,a5,-1
    80000c5e:	0007871b          	sext.w	a4,a5
    80000c62:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c64:	eb09                	bnez	a4,80000c76 <pop_off+0x38>
    80000c66:	5d7c                	lw	a5,124(a0)
    80000c68:	c799                	beqz	a5,80000c76 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c6a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c6e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c72:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c76:	60a2                	ld	ra,8(sp)
    80000c78:	6402                	ld	s0,0(sp)
    80000c7a:	0141                	addi	sp,sp,16
    80000c7c:	8082                	ret
    panic("pop_off - interruptible");
    80000c7e:	00008517          	auipc	a0,0x8
    80000c82:	3fa50513          	addi	a0,a0,1018 # 80009078 <digits+0x38>
    80000c86:	00000097          	auipc	ra,0x0
    80000c8a:	8be080e7          	jalr	-1858(ra) # 80000544 <panic>
    panic("pop_off");
    80000c8e:	00008517          	auipc	a0,0x8
    80000c92:	40250513          	addi	a0,a0,1026 # 80009090 <digits+0x50>
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	8ae080e7          	jalr	-1874(ra) # 80000544 <panic>

0000000080000c9e <release>:
{
    80000c9e:	1101                	addi	sp,sp,-32
    80000ca0:	ec06                	sd	ra,24(sp)
    80000ca2:	e822                	sd	s0,16(sp)
    80000ca4:	e426                	sd	s1,8(sp)
    80000ca6:	1000                	addi	s0,sp,32
    80000ca8:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	ec6080e7          	jalr	-314(ra) # 80000b70 <holding>
    80000cb2:	c115                	beqz	a0,80000cd6 <release+0x38>
  lk->cpu = 0;
    80000cb4:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb8:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cbc:	0f50000f          	fence	iorw,ow
    80000cc0:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	f7a080e7          	jalr	-134(ra) # 80000c3e <pop_off>
}
    80000ccc:	60e2                	ld	ra,24(sp)
    80000cce:	6442                	ld	s0,16(sp)
    80000cd0:	64a2                	ld	s1,8(sp)
    80000cd2:	6105                	addi	sp,sp,32
    80000cd4:	8082                	ret
    panic("release");
    80000cd6:	00008517          	auipc	a0,0x8
    80000cda:	3c250513          	addi	a0,a0,962 # 80009098 <digits+0x58>
    80000cde:	00000097          	auipc	ra,0x0
    80000ce2:	866080e7          	jalr	-1946(ra) # 80000544 <panic>

0000000080000ce6 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce6:	1141                	addi	sp,sp,-16
    80000ce8:	e422                	sd	s0,8(sp)
    80000cea:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cec:	ce09                	beqz	a2,80000d06 <memset+0x20>
    80000cee:	87aa                	mv	a5,a0
    80000cf0:	fff6071b          	addiw	a4,a2,-1
    80000cf4:	1702                	slli	a4,a4,0x20
    80000cf6:	9301                	srli	a4,a4,0x20
    80000cf8:	0705                	addi	a4,a4,1
    80000cfa:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cfc:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d00:	0785                	addi	a5,a5,1
    80000d02:	fee79de3          	bne	a5,a4,80000cfc <memset+0x16>
  }
  return dst;
}
    80000d06:	6422                	ld	s0,8(sp)
    80000d08:	0141                	addi	sp,sp,16
    80000d0a:	8082                	ret

0000000080000d0c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d12:	ca05                	beqz	a2,80000d42 <memcmp+0x36>
    80000d14:	fff6069b          	addiw	a3,a2,-1
    80000d18:	1682                	slli	a3,a3,0x20
    80000d1a:	9281                	srli	a3,a3,0x20
    80000d1c:	0685                	addi	a3,a3,1
    80000d1e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d20:	00054783          	lbu	a5,0(a0)
    80000d24:	0005c703          	lbu	a4,0(a1)
    80000d28:	00e79863          	bne	a5,a4,80000d38 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d2c:	0505                	addi	a0,a0,1
    80000d2e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d30:	fed518e3          	bne	a0,a3,80000d20 <memcmp+0x14>
  }

  return 0;
    80000d34:	4501                	li	a0,0
    80000d36:	a019                	j	80000d3c <memcmp+0x30>
      return *s1 - *s2;
    80000d38:	40e7853b          	subw	a0,a5,a4
}
    80000d3c:	6422                	ld	s0,8(sp)
    80000d3e:	0141                	addi	sp,sp,16
    80000d40:	8082                	ret
  return 0;
    80000d42:	4501                	li	a0,0
    80000d44:	bfe5                	j	80000d3c <memcmp+0x30>

0000000080000d46 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d46:	1141                	addi	sp,sp,-16
    80000d48:	e422                	sd	s0,8(sp)
    80000d4a:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d4c:	ca0d                	beqz	a2,80000d7e <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d4e:	00a5f963          	bgeu	a1,a0,80000d60 <memmove+0x1a>
    80000d52:	02061693          	slli	a3,a2,0x20
    80000d56:	9281                	srli	a3,a3,0x20
    80000d58:	00d58733          	add	a4,a1,a3
    80000d5c:	02e56463          	bltu	a0,a4,80000d84 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d60:	fff6079b          	addiw	a5,a2,-1
    80000d64:	1782                	slli	a5,a5,0x20
    80000d66:	9381                	srli	a5,a5,0x20
    80000d68:	0785                	addi	a5,a5,1
    80000d6a:	97ae                	add	a5,a5,a1
    80000d6c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d6e:	0585                	addi	a1,a1,1
    80000d70:	0705                	addi	a4,a4,1
    80000d72:	fff5c683          	lbu	a3,-1(a1)
    80000d76:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d7a:	fef59ae3          	bne	a1,a5,80000d6e <memmove+0x28>

  return dst;
}
    80000d7e:	6422                	ld	s0,8(sp)
    80000d80:	0141                	addi	sp,sp,16
    80000d82:	8082                	ret
    d += n;
    80000d84:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d86:	fff6079b          	addiw	a5,a2,-1
    80000d8a:	1782                	slli	a5,a5,0x20
    80000d8c:	9381                	srli	a5,a5,0x20
    80000d8e:	fff7c793          	not	a5,a5
    80000d92:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d94:	177d                	addi	a4,a4,-1
    80000d96:	16fd                	addi	a3,a3,-1
    80000d98:	00074603          	lbu	a2,0(a4)
    80000d9c:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000da0:	fef71ae3          	bne	a4,a5,80000d94 <memmove+0x4e>
    80000da4:	bfe9                	j	80000d7e <memmove+0x38>

0000000080000da6 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da6:	1141                	addi	sp,sp,-16
    80000da8:	e406                	sd	ra,8(sp)
    80000daa:	e022                	sd	s0,0(sp)
    80000dac:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dae:	00000097          	auipc	ra,0x0
    80000db2:	f98080e7          	jalr	-104(ra) # 80000d46 <memmove>
}
    80000db6:	60a2                	ld	ra,8(sp)
    80000db8:	6402                	ld	s0,0(sp)
    80000dba:	0141                	addi	sp,sp,16
    80000dbc:	8082                	ret

0000000080000dbe <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dbe:	1141                	addi	sp,sp,-16
    80000dc0:	e422                	sd	s0,8(sp)
    80000dc2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dc4:	ce11                	beqz	a2,80000de0 <strncmp+0x22>
    80000dc6:	00054783          	lbu	a5,0(a0)
    80000dca:	cf89                	beqz	a5,80000de4 <strncmp+0x26>
    80000dcc:	0005c703          	lbu	a4,0(a1)
    80000dd0:	00f71a63          	bne	a4,a5,80000de4 <strncmp+0x26>
    n--, p++, q++;
    80000dd4:	367d                	addiw	a2,a2,-1
    80000dd6:	0505                	addi	a0,a0,1
    80000dd8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dda:	f675                	bnez	a2,80000dc6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ddc:	4501                	li	a0,0
    80000dde:	a809                	j	80000df0 <strncmp+0x32>
    80000de0:	4501                	li	a0,0
    80000de2:	a039                	j	80000df0 <strncmp+0x32>
  if(n == 0)
    80000de4:	ca09                	beqz	a2,80000df6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de6:	00054503          	lbu	a0,0(a0)
    80000dea:	0005c783          	lbu	a5,0(a1)
    80000dee:	9d1d                	subw	a0,a0,a5
}
    80000df0:	6422                	ld	s0,8(sp)
    80000df2:	0141                	addi	sp,sp,16
    80000df4:	8082                	ret
    return 0;
    80000df6:	4501                	li	a0,0
    80000df8:	bfe5                	j	80000df0 <strncmp+0x32>

0000000080000dfa <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dfa:	1141                	addi	sp,sp,-16
    80000dfc:	e422                	sd	s0,8(sp)
    80000dfe:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e00:	872a                	mv	a4,a0
    80000e02:	8832                	mv	a6,a2
    80000e04:	367d                	addiw	a2,a2,-1
    80000e06:	01005963          	blez	a6,80000e18 <strncpy+0x1e>
    80000e0a:	0705                	addi	a4,a4,1
    80000e0c:	0005c783          	lbu	a5,0(a1)
    80000e10:	fef70fa3          	sb	a5,-1(a4)
    80000e14:	0585                	addi	a1,a1,1
    80000e16:	f7f5                	bnez	a5,80000e02 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e18:	00c05d63          	blez	a2,80000e32 <strncpy+0x38>
    80000e1c:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e1e:	0685                	addi	a3,a3,1
    80000e20:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e24:	fff6c793          	not	a5,a3
    80000e28:	9fb9                	addw	a5,a5,a4
    80000e2a:	010787bb          	addw	a5,a5,a6
    80000e2e:	fef048e3          	bgtz	a5,80000e1e <strncpy+0x24>
  return os;
}
    80000e32:	6422                	ld	s0,8(sp)
    80000e34:	0141                	addi	sp,sp,16
    80000e36:	8082                	ret

0000000080000e38 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e38:	1141                	addi	sp,sp,-16
    80000e3a:	e422                	sd	s0,8(sp)
    80000e3c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e3e:	02c05363          	blez	a2,80000e64 <safestrcpy+0x2c>
    80000e42:	fff6069b          	addiw	a3,a2,-1
    80000e46:	1682                	slli	a3,a3,0x20
    80000e48:	9281                	srli	a3,a3,0x20
    80000e4a:	96ae                	add	a3,a3,a1
    80000e4c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e4e:	00d58963          	beq	a1,a3,80000e60 <safestrcpy+0x28>
    80000e52:	0585                	addi	a1,a1,1
    80000e54:	0785                	addi	a5,a5,1
    80000e56:	fff5c703          	lbu	a4,-1(a1)
    80000e5a:	fee78fa3          	sb	a4,-1(a5)
    80000e5e:	fb65                	bnez	a4,80000e4e <safestrcpy+0x16>
    ;
  *s = 0;
    80000e60:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e64:	6422                	ld	s0,8(sp)
    80000e66:	0141                	addi	sp,sp,16
    80000e68:	8082                	ret

0000000080000e6a <strlen>:

int
strlen(const char *s)
{
    80000e6a:	1141                	addi	sp,sp,-16
    80000e6c:	e422                	sd	s0,8(sp)
    80000e6e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e70:	00054783          	lbu	a5,0(a0)
    80000e74:	cf91                	beqz	a5,80000e90 <strlen+0x26>
    80000e76:	0505                	addi	a0,a0,1
    80000e78:	87aa                	mv	a5,a0
    80000e7a:	4685                	li	a3,1
    80000e7c:	9e89                	subw	a3,a3,a0
    80000e7e:	00f6853b          	addw	a0,a3,a5
    80000e82:	0785                	addi	a5,a5,1
    80000e84:	fff7c703          	lbu	a4,-1(a5)
    80000e88:	fb7d                	bnez	a4,80000e7e <strlen+0x14>
    ;
  return n;
}
    80000e8a:	6422                	ld	s0,8(sp)
    80000e8c:	0141                	addi	sp,sp,16
    80000e8e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e90:	4501                	li	a0,0
    80000e92:	bfe5                	j	80000e8a <strlen+0x20>

0000000080000e94 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e406                	sd	ra,8(sp)
    80000e98:	e022                	sd	s0,0(sp)
    80000e9a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	cfe080e7          	jalr	-770(ra) # 80001b9a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ea4:	00009717          	auipc	a4,0x9
    80000ea8:	ce470713          	addi	a4,a4,-796 # 80009b88 <started>
  if(cpuid() == 0){
    80000eac:	c139                	beqz	a0,80000ef2 <main+0x5e>
    while(started == 0)
    80000eae:	431c                	lw	a5,0(a4)
    80000eb0:	2781                	sext.w	a5,a5
    80000eb2:	dff5                	beqz	a5,80000eae <main+0x1a>
      ;
    __sync_synchronize();
    80000eb4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb8:	00001097          	auipc	ra,0x1
    80000ebc:	ce2080e7          	jalr	-798(ra) # 80001b9a <cpuid>
    80000ec0:	85aa                	mv	a1,a0
    80000ec2:	00008517          	auipc	a0,0x8
    80000ec6:	1f650513          	addi	a0,a0,502 # 800090b8 <digits+0x78>
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	6c4080e7          	jalr	1732(ra) # 8000058e <printf>
    kvminithart();    // turn on paging
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	0d8080e7          	jalr	216(ra) # 80000faa <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eda:	00002097          	auipc	ra,0x2
    80000ede:	d42080e7          	jalr	-702(ra) # 80002c1c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00006097          	auipc	ra,0x6
    80000ee6:	a0e080e7          	jalr	-1522(ra) # 800068f0 <plicinithart>
  }

  scheduler();        
    80000eea:	00001097          	auipc	ra,0x1
    80000eee:	238080e7          	jalr	568(ra) # 80002122 <scheduler>
    consoleinit();
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	564080e7          	jalr	1380(ra) # 80000456 <consoleinit>
    printfinit();
    80000efa:	00000097          	auipc	ra,0x0
    80000efe:	87a080e7          	jalr	-1926(ra) # 80000774 <printfinit>
    printf("\n");
    80000f02:	00008517          	auipc	a0,0x8
    80000f06:	1c650513          	addi	a0,a0,454 # 800090c8 <digits+0x88>
    80000f0a:	fffff097          	auipc	ra,0xfffff
    80000f0e:	684080e7          	jalr	1668(ra) # 8000058e <printf>
    printf("xv6 kernel is booting\n");
    80000f12:	00008517          	auipc	a0,0x8
    80000f16:	18e50513          	addi	a0,a0,398 # 800090a0 <digits+0x60>
    80000f1a:	fffff097          	auipc	ra,0xfffff
    80000f1e:	674080e7          	jalr	1652(ra) # 8000058e <printf>
    printf("\n");
    80000f22:	00008517          	auipc	a0,0x8
    80000f26:	1a650513          	addi	a0,a0,422 # 800090c8 <digits+0x88>
    80000f2a:	fffff097          	auipc	ra,0xfffff
    80000f2e:	664080e7          	jalr	1636(ra) # 8000058e <printf>
    kinit();         // physical page allocator
    80000f32:	00000097          	auipc	ra,0x0
    80000f36:	b8c080e7          	jalr	-1140(ra) # 80000abe <kinit>
    kvminit();       // create kernel page table
    80000f3a:	00000097          	auipc	ra,0x0
    80000f3e:	326080e7          	jalr	806(ra) # 80001260 <kvminit>
    kvminithart();   // turn on paging
    80000f42:	00000097          	auipc	ra,0x0
    80000f46:	068080e7          	jalr	104(ra) # 80000faa <kvminithart>
    procinit();      // process table
    80000f4a:	00001097          	auipc	ra,0x1
    80000f4e:	b9c080e7          	jalr	-1124(ra) # 80001ae6 <procinit>
    trapinit();      // trap vectors
    80000f52:	00002097          	auipc	ra,0x2
    80000f56:	ca2080e7          	jalr	-862(ra) # 80002bf4 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00002097          	auipc	ra,0x2
    80000f5e:	cc2080e7          	jalr	-830(ra) # 80002c1c <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00006097          	auipc	ra,0x6
    80000f66:	978080e7          	jalr	-1672(ra) # 800068da <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00006097          	auipc	ra,0x6
    80000f6e:	986080e7          	jalr	-1658(ra) # 800068f0 <plicinithart>
    binit();         // buffer cache
    80000f72:	00003097          	auipc	ra,0x3
    80000f76:	b32080e7          	jalr	-1230(ra) # 80003aa4 <binit>
    iinit();         // inode table
    80000f7a:	00003097          	auipc	ra,0x3
    80000f7e:	1d6080e7          	jalr	470(ra) # 80004150 <iinit>
    fileinit();      // file table
    80000f82:	00004097          	auipc	ra,0x4
    80000f86:	174080e7          	jalr	372(ra) # 800050f6 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00006097          	auipc	ra,0x6
    80000f8e:	a6e080e7          	jalr	-1426(ra) # 800069f8 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	f6e080e7          	jalr	-146(ra) # 80001f00 <userinit>
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    started = 1;
    80000f9e:	4785                	li	a5,1
    80000fa0:	00009717          	auipc	a4,0x9
    80000fa4:	bef72423          	sw	a5,-1048(a4) # 80009b88 <started>
    80000fa8:	b789                	j	80000eea <main+0x56>

0000000080000faa <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000faa:	1141                	addi	sp,sp,-16
    80000fac:	e422                	sd	s0,8(sp)
    80000fae:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fb0:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb4:	00009797          	auipc	a5,0x9
    80000fb8:	bdc7b783          	ld	a5,-1060(a5) # 80009b90 <kernel_pagetable>
    80000fbc:	83b1                	srli	a5,a5,0xc
    80000fbe:	577d                	li	a4,-1
    80000fc0:	177e                	slli	a4,a4,0x3f
    80000fc2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc4:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fc8:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fcc:	6422                	ld	s0,8(sp)
    80000fce:	0141                	addi	sp,sp,16
    80000fd0:	8082                	ret

0000000080000fd2 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd2:	7139                	addi	sp,sp,-64
    80000fd4:	fc06                	sd	ra,56(sp)
    80000fd6:	f822                	sd	s0,48(sp)
    80000fd8:	f426                	sd	s1,40(sp)
    80000fda:	f04a                	sd	s2,32(sp)
    80000fdc:	ec4e                	sd	s3,24(sp)
    80000fde:	e852                	sd	s4,16(sp)
    80000fe0:	e456                	sd	s5,8(sp)
    80000fe2:	e05a                	sd	s6,0(sp)
    80000fe4:	0080                	addi	s0,sp,64
    80000fe6:	84aa                	mv	s1,a0
    80000fe8:	89ae                	mv	s3,a1
    80000fea:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fec:	57fd                	li	a5,-1
    80000fee:	83e9                	srli	a5,a5,0x1a
    80000ff0:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff2:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff4:	04b7f263          	bgeu	a5,a1,80001038 <walk+0x66>
    panic("walk");
    80000ff8:	00008517          	auipc	a0,0x8
    80000ffc:	0d850513          	addi	a0,a0,216 # 800090d0 <digits+0x90>
    80001000:	fffff097          	auipc	ra,0xfffff
    80001004:	544080e7          	jalr	1348(ra) # 80000544 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001008:	060a8663          	beqz	s5,80001074 <walk+0xa2>
    8000100c:	00000097          	auipc	ra,0x0
    80001010:	aee080e7          	jalr	-1298(ra) # 80000afa <kalloc>
    80001014:	84aa                	mv	s1,a0
    80001016:	c529                	beqz	a0,80001060 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001018:	6605                	lui	a2,0x1
    8000101a:	4581                	li	a1,0
    8000101c:	00000097          	auipc	ra,0x0
    80001020:	cca080e7          	jalr	-822(ra) # 80000ce6 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001024:	00c4d793          	srli	a5,s1,0xc
    80001028:	07aa                	slli	a5,a5,0xa
    8000102a:	0017e793          	ori	a5,a5,1
    8000102e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001032:	3a5d                	addiw	s4,s4,-9
    80001034:	036a0063          	beq	s4,s6,80001054 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001038:	0149d933          	srl	s2,s3,s4
    8000103c:	1ff97913          	andi	s2,s2,511
    80001040:	090e                	slli	s2,s2,0x3
    80001042:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001044:	00093483          	ld	s1,0(s2)
    80001048:	0014f793          	andi	a5,s1,1
    8000104c:	dfd5                	beqz	a5,80001008 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000104e:	80a9                	srli	s1,s1,0xa
    80001050:	04b2                	slli	s1,s1,0xc
    80001052:	b7c5                	j	80001032 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001054:	00c9d513          	srli	a0,s3,0xc
    80001058:	1ff57513          	andi	a0,a0,511
    8000105c:	050e                	slli	a0,a0,0x3
    8000105e:	9526                	add	a0,a0,s1
}
    80001060:	70e2                	ld	ra,56(sp)
    80001062:	7442                	ld	s0,48(sp)
    80001064:	74a2                	ld	s1,40(sp)
    80001066:	7902                	ld	s2,32(sp)
    80001068:	69e2                	ld	s3,24(sp)
    8000106a:	6a42                	ld	s4,16(sp)
    8000106c:	6aa2                	ld	s5,8(sp)
    8000106e:	6b02                	ld	s6,0(sp)
    80001070:	6121                	addi	sp,sp,64
    80001072:	8082                	ret
        return 0;
    80001074:	4501                	li	a0,0
    80001076:	b7ed                	j	80001060 <walk+0x8e>

0000000080001078 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001078:	57fd                	li	a5,-1
    8000107a:	83e9                	srli	a5,a5,0x1a
    8000107c:	00b7f463          	bgeu	a5,a1,80001084 <walkaddr+0xc>
    return 0;
    80001080:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001082:	8082                	ret
{
    80001084:	1141                	addi	sp,sp,-16
    80001086:	e406                	sd	ra,8(sp)
    80001088:	e022                	sd	s0,0(sp)
    8000108a:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000108c:	4601                	li	a2,0
    8000108e:	00000097          	auipc	ra,0x0
    80001092:	f44080e7          	jalr	-188(ra) # 80000fd2 <walk>
  if(pte == 0)
    80001096:	c105                	beqz	a0,800010b6 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001098:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000109a:	0117f693          	andi	a3,a5,17
    8000109e:	4745                	li	a4,17
    return 0;
    800010a0:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a2:	00e68663          	beq	a3,a4,800010ae <walkaddr+0x36>
}
    800010a6:	60a2                	ld	ra,8(sp)
    800010a8:	6402                	ld	s0,0(sp)
    800010aa:	0141                	addi	sp,sp,16
    800010ac:	8082                	ret
  pa = PTE2PA(*pte);
    800010ae:	00a7d513          	srli	a0,a5,0xa
    800010b2:	0532                	slli	a0,a0,0xc
  return pa;
    800010b4:	bfcd                	j	800010a6 <walkaddr+0x2e>
    return 0;
    800010b6:	4501                	li	a0,0
    800010b8:	b7fd                	j	800010a6 <walkaddr+0x2e>

00000000800010ba <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010ba:	715d                	addi	sp,sp,-80
    800010bc:	e486                	sd	ra,72(sp)
    800010be:	e0a2                	sd	s0,64(sp)
    800010c0:	fc26                	sd	s1,56(sp)
    800010c2:	f84a                	sd	s2,48(sp)
    800010c4:	f44e                	sd	s3,40(sp)
    800010c6:	f052                	sd	s4,32(sp)
    800010c8:	ec56                	sd	s5,24(sp)
    800010ca:	e85a                	sd	s6,16(sp)
    800010cc:	e45e                	sd	s7,8(sp)
    800010ce:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010d0:	c205                	beqz	a2,800010f0 <mappages+0x36>
    800010d2:	8aaa                	mv	s5,a0
    800010d4:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010d6:	77fd                	lui	a5,0xfffff
    800010d8:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010dc:	15fd                	addi	a1,a1,-1
    800010de:	00c589b3          	add	s3,a1,a2
    800010e2:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010e6:	8952                	mv	s2,s4
    800010e8:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ec:	6b85                	lui	s7,0x1
    800010ee:	a015                	j	80001112 <mappages+0x58>
    panic("mappages: size");
    800010f0:	00008517          	auipc	a0,0x8
    800010f4:	fe850513          	addi	a0,a0,-24 # 800090d8 <digits+0x98>
    800010f8:	fffff097          	auipc	ra,0xfffff
    800010fc:	44c080e7          	jalr	1100(ra) # 80000544 <panic>
      panic("mappages: remap");
    80001100:	00008517          	auipc	a0,0x8
    80001104:	fe850513          	addi	a0,a0,-24 # 800090e8 <digits+0xa8>
    80001108:	fffff097          	auipc	ra,0xfffff
    8000110c:	43c080e7          	jalr	1084(ra) # 80000544 <panic>
    a += PGSIZE;
    80001110:	995e                	add	s2,s2,s7
  for(;;){
    80001112:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001116:	4605                	li	a2,1
    80001118:	85ca                	mv	a1,s2
    8000111a:	8556                	mv	a0,s5
    8000111c:	00000097          	auipc	ra,0x0
    80001120:	eb6080e7          	jalr	-330(ra) # 80000fd2 <walk>
    80001124:	cd19                	beqz	a0,80001142 <mappages+0x88>
    if(*pte & PTE_V)
    80001126:	611c                	ld	a5,0(a0)
    80001128:	8b85                	andi	a5,a5,1
    8000112a:	fbf9                	bnez	a5,80001100 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000112c:	80b1                	srli	s1,s1,0xc
    8000112e:	04aa                	slli	s1,s1,0xa
    80001130:	0164e4b3          	or	s1,s1,s6
    80001134:	0014e493          	ori	s1,s1,1
    80001138:	e104                	sd	s1,0(a0)
    if(a == last)
    8000113a:	fd391be3          	bne	s2,s3,80001110 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    8000113e:	4501                	li	a0,0
    80001140:	a011                	j	80001144 <mappages+0x8a>
      return -1;
    80001142:	557d                	li	a0,-1
}
    80001144:	60a6                	ld	ra,72(sp)
    80001146:	6406                	ld	s0,64(sp)
    80001148:	74e2                	ld	s1,56(sp)
    8000114a:	7942                	ld	s2,48(sp)
    8000114c:	79a2                	ld	s3,40(sp)
    8000114e:	7a02                	ld	s4,32(sp)
    80001150:	6ae2                	ld	s5,24(sp)
    80001152:	6b42                	ld	s6,16(sp)
    80001154:	6ba2                	ld	s7,8(sp)
    80001156:	6161                	addi	sp,sp,80
    80001158:	8082                	ret

000000008000115a <kvmmap>:
{
    8000115a:	1141                	addi	sp,sp,-16
    8000115c:	e406                	sd	ra,8(sp)
    8000115e:	e022                	sd	s0,0(sp)
    80001160:	0800                	addi	s0,sp,16
    80001162:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001164:	86b2                	mv	a3,a2
    80001166:	863e                	mv	a2,a5
    80001168:	00000097          	auipc	ra,0x0
    8000116c:	f52080e7          	jalr	-174(ra) # 800010ba <mappages>
    80001170:	e509                	bnez	a0,8000117a <kvmmap+0x20>
}
    80001172:	60a2                	ld	ra,8(sp)
    80001174:	6402                	ld	s0,0(sp)
    80001176:	0141                	addi	sp,sp,16
    80001178:	8082                	ret
    panic("kvmmap");
    8000117a:	00008517          	auipc	a0,0x8
    8000117e:	f7e50513          	addi	a0,a0,-130 # 800090f8 <digits+0xb8>
    80001182:	fffff097          	auipc	ra,0xfffff
    80001186:	3c2080e7          	jalr	962(ra) # 80000544 <panic>

000000008000118a <kvmmake>:
{
    8000118a:	1101                	addi	sp,sp,-32
    8000118c:	ec06                	sd	ra,24(sp)
    8000118e:	e822                	sd	s0,16(sp)
    80001190:	e426                	sd	s1,8(sp)
    80001192:	e04a                	sd	s2,0(sp)
    80001194:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001196:	00000097          	auipc	ra,0x0
    8000119a:	964080e7          	jalr	-1692(ra) # 80000afa <kalloc>
    8000119e:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011a0:	6605                	lui	a2,0x1
    800011a2:	4581                	li	a1,0
    800011a4:	00000097          	auipc	ra,0x0
    800011a8:	b42080e7          	jalr	-1214(ra) # 80000ce6 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011ac:	4719                	li	a4,6
    800011ae:	6685                	lui	a3,0x1
    800011b0:	10000637          	lui	a2,0x10000
    800011b4:	100005b7          	lui	a1,0x10000
    800011b8:	8526                	mv	a0,s1
    800011ba:	00000097          	auipc	ra,0x0
    800011be:	fa0080e7          	jalr	-96(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c2:	4719                	li	a4,6
    800011c4:	6685                	lui	a3,0x1
    800011c6:	10001637          	lui	a2,0x10001
    800011ca:	100015b7          	lui	a1,0x10001
    800011ce:	8526                	mv	a0,s1
    800011d0:	00000097          	auipc	ra,0x0
    800011d4:	f8a080e7          	jalr	-118(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011d8:	4719                	li	a4,6
    800011da:	004006b7          	lui	a3,0x400
    800011de:	0c000637          	lui	a2,0xc000
    800011e2:	0c0005b7          	lui	a1,0xc000
    800011e6:	8526                	mv	a0,s1
    800011e8:	00000097          	auipc	ra,0x0
    800011ec:	f72080e7          	jalr	-142(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011f0:	00008917          	auipc	s2,0x8
    800011f4:	e1090913          	addi	s2,s2,-496 # 80009000 <etext>
    800011f8:	4729                	li	a4,10
    800011fa:	80008697          	auipc	a3,0x80008
    800011fe:	e0668693          	addi	a3,a3,-506 # 9000 <_entry-0x7fff7000>
    80001202:	4605                	li	a2,1
    80001204:	067e                	slli	a2,a2,0x1f
    80001206:	85b2                	mv	a1,a2
    80001208:	8526                	mv	a0,s1
    8000120a:	00000097          	auipc	ra,0x0
    8000120e:	f50080e7          	jalr	-176(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001212:	4719                	li	a4,6
    80001214:	46c5                	li	a3,17
    80001216:	06ee                	slli	a3,a3,0x1b
    80001218:	412686b3          	sub	a3,a3,s2
    8000121c:	864a                	mv	a2,s2
    8000121e:	85ca                	mv	a1,s2
    80001220:	8526                	mv	a0,s1
    80001222:	00000097          	auipc	ra,0x0
    80001226:	f38080e7          	jalr	-200(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000122a:	4729                	li	a4,10
    8000122c:	6685                	lui	a3,0x1
    8000122e:	00007617          	auipc	a2,0x7
    80001232:	dd260613          	addi	a2,a2,-558 # 80008000 <_trampoline>
    80001236:	040005b7          	lui	a1,0x4000
    8000123a:	15fd                	addi	a1,a1,-1
    8000123c:	05b2                	slli	a1,a1,0xc
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	f1a080e7          	jalr	-230(ra) # 8000115a <kvmmap>
  proc_mapstacks(kpgtbl);
    80001248:	8526                	mv	a0,s1
    8000124a:	00001097          	auipc	ra,0x1
    8000124e:	806080e7          	jalr	-2042(ra) # 80001a50 <proc_mapstacks>
}
    80001252:	8526                	mv	a0,s1
    80001254:	60e2                	ld	ra,24(sp)
    80001256:	6442                	ld	s0,16(sp)
    80001258:	64a2                	ld	s1,8(sp)
    8000125a:	6902                	ld	s2,0(sp)
    8000125c:	6105                	addi	sp,sp,32
    8000125e:	8082                	ret

0000000080001260 <kvminit>:
{
    80001260:	1141                	addi	sp,sp,-16
    80001262:	e406                	sd	ra,8(sp)
    80001264:	e022                	sd	s0,0(sp)
    80001266:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001268:	00000097          	auipc	ra,0x0
    8000126c:	f22080e7          	jalr	-222(ra) # 8000118a <kvmmake>
    80001270:	00009797          	auipc	a5,0x9
    80001274:	92a7b023          	sd	a0,-1760(a5) # 80009b90 <kernel_pagetable>
}
    80001278:	60a2                	ld	ra,8(sp)
    8000127a:	6402                	ld	s0,0(sp)
    8000127c:	0141                	addi	sp,sp,16
    8000127e:	8082                	ret

0000000080001280 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001280:	715d                	addi	sp,sp,-80
    80001282:	e486                	sd	ra,72(sp)
    80001284:	e0a2                	sd	s0,64(sp)
    80001286:	fc26                	sd	s1,56(sp)
    80001288:	f84a                	sd	s2,48(sp)
    8000128a:	f44e                	sd	s3,40(sp)
    8000128c:	f052                	sd	s4,32(sp)
    8000128e:	ec56                	sd	s5,24(sp)
    80001290:	e85a                	sd	s6,16(sp)
    80001292:	e45e                	sd	s7,8(sp)
    80001294:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001296:	03459793          	slli	a5,a1,0x34
    8000129a:	e795                	bnez	a5,800012c6 <uvmunmap+0x46>
    8000129c:	8a2a                	mv	s4,a0
    8000129e:	892e                	mv	s2,a1
    800012a0:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a2:	0632                	slli	a2,a2,0xc
    800012a4:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012a8:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012aa:	6b05                	lui	s6,0x1
    800012ac:	0735e863          	bltu	a1,s3,8000131c <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012b0:	60a6                	ld	ra,72(sp)
    800012b2:	6406                	ld	s0,64(sp)
    800012b4:	74e2                	ld	s1,56(sp)
    800012b6:	7942                	ld	s2,48(sp)
    800012b8:	79a2                	ld	s3,40(sp)
    800012ba:	7a02                	ld	s4,32(sp)
    800012bc:	6ae2                	ld	s5,24(sp)
    800012be:	6b42                	ld	s6,16(sp)
    800012c0:	6ba2                	ld	s7,8(sp)
    800012c2:	6161                	addi	sp,sp,80
    800012c4:	8082                	ret
    panic("uvmunmap: not aligned");
    800012c6:	00008517          	auipc	a0,0x8
    800012ca:	e3a50513          	addi	a0,a0,-454 # 80009100 <digits+0xc0>
    800012ce:	fffff097          	auipc	ra,0xfffff
    800012d2:	276080e7          	jalr	630(ra) # 80000544 <panic>
      panic("uvmunmap: walk");
    800012d6:	00008517          	auipc	a0,0x8
    800012da:	e4250513          	addi	a0,a0,-446 # 80009118 <digits+0xd8>
    800012de:	fffff097          	auipc	ra,0xfffff
    800012e2:	266080e7          	jalr	614(ra) # 80000544 <panic>
      panic("uvmunmap: not mapped");
    800012e6:	00008517          	auipc	a0,0x8
    800012ea:	e4250513          	addi	a0,a0,-446 # 80009128 <digits+0xe8>
    800012ee:	fffff097          	auipc	ra,0xfffff
    800012f2:	256080e7          	jalr	598(ra) # 80000544 <panic>
      panic("uvmunmap: not a leaf");
    800012f6:	00008517          	auipc	a0,0x8
    800012fa:	e4a50513          	addi	a0,a0,-438 # 80009140 <digits+0x100>
    800012fe:	fffff097          	auipc	ra,0xfffff
    80001302:	246080e7          	jalr	582(ra) # 80000544 <panic>
      uint64 pa = PTE2PA(*pte);
    80001306:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001308:	0532                	slli	a0,a0,0xc
    8000130a:	fffff097          	auipc	ra,0xfffff
    8000130e:	6f4080e7          	jalr	1780(ra) # 800009fe <kfree>
    *pte = 0;
    80001312:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001316:	995a                	add	s2,s2,s6
    80001318:	f9397ce3          	bgeu	s2,s3,800012b0 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000131c:	4601                	li	a2,0
    8000131e:	85ca                	mv	a1,s2
    80001320:	8552                	mv	a0,s4
    80001322:	00000097          	auipc	ra,0x0
    80001326:	cb0080e7          	jalr	-848(ra) # 80000fd2 <walk>
    8000132a:	84aa                	mv	s1,a0
    8000132c:	d54d                	beqz	a0,800012d6 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000132e:	6108                	ld	a0,0(a0)
    80001330:	00157793          	andi	a5,a0,1
    80001334:	dbcd                	beqz	a5,800012e6 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001336:	3ff57793          	andi	a5,a0,1023
    8000133a:	fb778ee3          	beq	a5,s7,800012f6 <uvmunmap+0x76>
    if(do_free){
    8000133e:	fc0a8ae3          	beqz	s5,80001312 <uvmunmap+0x92>
    80001342:	b7d1                	j	80001306 <uvmunmap+0x86>

0000000080001344 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001344:	1101                	addi	sp,sp,-32
    80001346:	ec06                	sd	ra,24(sp)
    80001348:	e822                	sd	s0,16(sp)
    8000134a:	e426                	sd	s1,8(sp)
    8000134c:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000134e:	fffff097          	auipc	ra,0xfffff
    80001352:	7ac080e7          	jalr	1964(ra) # 80000afa <kalloc>
    80001356:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001358:	c519                	beqz	a0,80001366 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000135a:	6605                	lui	a2,0x1
    8000135c:	4581                	li	a1,0
    8000135e:	00000097          	auipc	ra,0x0
    80001362:	988080e7          	jalr	-1656(ra) # 80000ce6 <memset>
  return pagetable;
}
    80001366:	8526                	mv	a0,s1
    80001368:	60e2                	ld	ra,24(sp)
    8000136a:	6442                	ld	s0,16(sp)
    8000136c:	64a2                	ld	s1,8(sp)
    8000136e:	6105                	addi	sp,sp,32
    80001370:	8082                	ret

0000000080001372 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001372:	7179                	addi	sp,sp,-48
    80001374:	f406                	sd	ra,40(sp)
    80001376:	f022                	sd	s0,32(sp)
    80001378:	ec26                	sd	s1,24(sp)
    8000137a:	e84a                	sd	s2,16(sp)
    8000137c:	e44e                	sd	s3,8(sp)
    8000137e:	e052                	sd	s4,0(sp)
    80001380:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001382:	6785                	lui	a5,0x1
    80001384:	04f67863          	bgeu	a2,a5,800013d4 <uvmfirst+0x62>
    80001388:	8a2a                	mv	s4,a0
    8000138a:	89ae                	mv	s3,a1
    8000138c:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000138e:	fffff097          	auipc	ra,0xfffff
    80001392:	76c080e7          	jalr	1900(ra) # 80000afa <kalloc>
    80001396:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001398:	6605                	lui	a2,0x1
    8000139a:	4581                	li	a1,0
    8000139c:	00000097          	auipc	ra,0x0
    800013a0:	94a080e7          	jalr	-1718(ra) # 80000ce6 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013a4:	4779                	li	a4,30
    800013a6:	86ca                	mv	a3,s2
    800013a8:	6605                	lui	a2,0x1
    800013aa:	4581                	li	a1,0
    800013ac:	8552                	mv	a0,s4
    800013ae:	00000097          	auipc	ra,0x0
    800013b2:	d0c080e7          	jalr	-756(ra) # 800010ba <mappages>
  memmove(mem, src, sz);
    800013b6:	8626                	mv	a2,s1
    800013b8:	85ce                	mv	a1,s3
    800013ba:	854a                	mv	a0,s2
    800013bc:	00000097          	auipc	ra,0x0
    800013c0:	98a080e7          	jalr	-1654(ra) # 80000d46 <memmove>
}
    800013c4:	70a2                	ld	ra,40(sp)
    800013c6:	7402                	ld	s0,32(sp)
    800013c8:	64e2                	ld	s1,24(sp)
    800013ca:	6942                	ld	s2,16(sp)
    800013cc:	69a2                	ld	s3,8(sp)
    800013ce:	6a02                	ld	s4,0(sp)
    800013d0:	6145                	addi	sp,sp,48
    800013d2:	8082                	ret
    panic("uvmfirst: more than a page");
    800013d4:	00008517          	auipc	a0,0x8
    800013d8:	d8450513          	addi	a0,a0,-636 # 80009158 <digits+0x118>
    800013dc:	fffff097          	auipc	ra,0xfffff
    800013e0:	168080e7          	jalr	360(ra) # 80000544 <panic>

00000000800013e4 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013e4:	1101                	addi	sp,sp,-32
    800013e6:	ec06                	sd	ra,24(sp)
    800013e8:	e822                	sd	s0,16(sp)
    800013ea:	e426                	sd	s1,8(sp)
    800013ec:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013ee:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013f0:	00b67d63          	bgeu	a2,a1,8000140a <uvmdealloc+0x26>
    800013f4:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013f6:	6785                	lui	a5,0x1
    800013f8:	17fd                	addi	a5,a5,-1
    800013fa:	00f60733          	add	a4,a2,a5
    800013fe:	767d                	lui	a2,0xfffff
    80001400:	8f71                	and	a4,a4,a2
    80001402:	97ae                	add	a5,a5,a1
    80001404:	8ff1                	and	a5,a5,a2
    80001406:	00f76863          	bltu	a4,a5,80001416 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000140a:	8526                	mv	a0,s1
    8000140c:	60e2                	ld	ra,24(sp)
    8000140e:	6442                	ld	s0,16(sp)
    80001410:	64a2                	ld	s1,8(sp)
    80001412:	6105                	addi	sp,sp,32
    80001414:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001416:	8f99                	sub	a5,a5,a4
    80001418:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000141a:	4685                	li	a3,1
    8000141c:	0007861b          	sext.w	a2,a5
    80001420:	85ba                	mv	a1,a4
    80001422:	00000097          	auipc	ra,0x0
    80001426:	e5e080e7          	jalr	-418(ra) # 80001280 <uvmunmap>
    8000142a:	b7c5                	j	8000140a <uvmdealloc+0x26>

000000008000142c <uvmalloc>:
  if(newsz < oldsz)
    8000142c:	0ab66563          	bltu	a2,a1,800014d6 <uvmalloc+0xaa>
{
    80001430:	7139                	addi	sp,sp,-64
    80001432:	fc06                	sd	ra,56(sp)
    80001434:	f822                	sd	s0,48(sp)
    80001436:	f426                	sd	s1,40(sp)
    80001438:	f04a                	sd	s2,32(sp)
    8000143a:	ec4e                	sd	s3,24(sp)
    8000143c:	e852                	sd	s4,16(sp)
    8000143e:	e456                	sd	s5,8(sp)
    80001440:	e05a                	sd	s6,0(sp)
    80001442:	0080                	addi	s0,sp,64
    80001444:	8aaa                	mv	s5,a0
    80001446:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001448:	6985                	lui	s3,0x1
    8000144a:	19fd                	addi	s3,s3,-1
    8000144c:	95ce                	add	a1,a1,s3
    8000144e:	79fd                	lui	s3,0xfffff
    80001450:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001454:	08c9f363          	bgeu	s3,a2,800014da <uvmalloc+0xae>
    80001458:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000145e:	fffff097          	auipc	ra,0xfffff
    80001462:	69c080e7          	jalr	1692(ra) # 80000afa <kalloc>
    80001466:	84aa                	mv	s1,a0
    if(mem == 0){
    80001468:	c51d                	beqz	a0,80001496 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000146a:	6605                	lui	a2,0x1
    8000146c:	4581                	li	a1,0
    8000146e:	00000097          	auipc	ra,0x0
    80001472:	878080e7          	jalr	-1928(ra) # 80000ce6 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001476:	875a                	mv	a4,s6
    80001478:	86a6                	mv	a3,s1
    8000147a:	6605                	lui	a2,0x1
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	c3a080e7          	jalr	-966(ra) # 800010ba <mappages>
    80001488:	e90d                	bnez	a0,800014ba <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000148a:	6785                	lui	a5,0x1
    8000148c:	993e                	add	s2,s2,a5
    8000148e:	fd4968e3          	bltu	s2,s4,8000145e <uvmalloc+0x32>
  return newsz;
    80001492:	8552                	mv	a0,s4
    80001494:	a809                	j	800014a6 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f48080e7          	jalr	-184(ra) # 800013e4 <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
}
    800014a6:	70e2                	ld	ra,56(sp)
    800014a8:	7442                	ld	s0,48(sp)
    800014aa:	74a2                	ld	s1,40(sp)
    800014ac:	7902                	ld	s2,32(sp)
    800014ae:	69e2                	ld	s3,24(sp)
    800014b0:	6a42                	ld	s4,16(sp)
    800014b2:	6aa2                	ld	s5,8(sp)
    800014b4:	6b02                	ld	s6,0(sp)
    800014b6:	6121                	addi	sp,sp,64
    800014b8:	8082                	ret
      kfree(mem);
    800014ba:	8526                	mv	a0,s1
    800014bc:	fffff097          	auipc	ra,0xfffff
    800014c0:	542080e7          	jalr	1346(ra) # 800009fe <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014c4:	864e                	mv	a2,s3
    800014c6:	85ca                	mv	a1,s2
    800014c8:	8556                	mv	a0,s5
    800014ca:	00000097          	auipc	ra,0x0
    800014ce:	f1a080e7          	jalr	-230(ra) # 800013e4 <uvmdealloc>
      return 0;
    800014d2:	4501                	li	a0,0
    800014d4:	bfc9                	j	800014a6 <uvmalloc+0x7a>
    return oldsz;
    800014d6:	852e                	mv	a0,a1
}
    800014d8:	8082                	ret
  return newsz;
    800014da:	8532                	mv	a0,a2
    800014dc:	b7e9                	j	800014a6 <uvmalloc+0x7a>

00000000800014de <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014de:	7179                	addi	sp,sp,-48
    800014e0:	f406                	sd	ra,40(sp)
    800014e2:	f022                	sd	s0,32(sp)
    800014e4:	ec26                	sd	s1,24(sp)
    800014e6:	e84a                	sd	s2,16(sp)
    800014e8:	e44e                	sd	s3,8(sp)
    800014ea:	e052                	sd	s4,0(sp)
    800014ec:	1800                	addi	s0,sp,48
    800014ee:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014f0:	84aa                	mv	s1,a0
    800014f2:	6905                	lui	s2,0x1
    800014f4:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f6:	4985                	li	s3,1
    800014f8:	a821                	j	80001510 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014fa:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014fc:	0532                	slli	a0,a0,0xc
    800014fe:	00000097          	auipc	ra,0x0
    80001502:	fe0080e7          	jalr	-32(ra) # 800014de <freewalk>
      pagetable[i] = 0;
    80001506:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000150a:	04a1                	addi	s1,s1,8
    8000150c:	03248163          	beq	s1,s2,8000152e <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001510:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001512:	00f57793          	andi	a5,a0,15
    80001516:	ff3782e3          	beq	a5,s3,800014fa <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000151a:	8905                	andi	a0,a0,1
    8000151c:	d57d                	beqz	a0,8000150a <freewalk+0x2c>
      panic("freewalk: leaf");
    8000151e:	00008517          	auipc	a0,0x8
    80001522:	c5a50513          	addi	a0,a0,-934 # 80009178 <digits+0x138>
    80001526:	fffff097          	auipc	ra,0xfffff
    8000152a:	01e080e7          	jalr	30(ra) # 80000544 <panic>
    }
  }
  kfree((void*)pagetable);
    8000152e:	8552                	mv	a0,s4
    80001530:	fffff097          	auipc	ra,0xfffff
    80001534:	4ce080e7          	jalr	1230(ra) # 800009fe <kfree>
}
    80001538:	70a2                	ld	ra,40(sp)
    8000153a:	7402                	ld	s0,32(sp)
    8000153c:	64e2                	ld	s1,24(sp)
    8000153e:	6942                	ld	s2,16(sp)
    80001540:	69a2                	ld	s3,8(sp)
    80001542:	6a02                	ld	s4,0(sp)
    80001544:	6145                	addi	sp,sp,48
    80001546:	8082                	ret

0000000080001548 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001548:	1101                	addi	sp,sp,-32
    8000154a:	ec06                	sd	ra,24(sp)
    8000154c:	e822                	sd	s0,16(sp)
    8000154e:	e426                	sd	s1,8(sp)
    80001550:	1000                	addi	s0,sp,32
    80001552:	84aa                	mv	s1,a0
  if(sz > 0)
    80001554:	e999                	bnez	a1,8000156a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001556:	8526                	mv	a0,s1
    80001558:	00000097          	auipc	ra,0x0
    8000155c:	f86080e7          	jalr	-122(ra) # 800014de <freewalk>
}
    80001560:	60e2                	ld	ra,24(sp)
    80001562:	6442                	ld	s0,16(sp)
    80001564:	64a2                	ld	s1,8(sp)
    80001566:	6105                	addi	sp,sp,32
    80001568:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000156a:	6605                	lui	a2,0x1
    8000156c:	167d                	addi	a2,a2,-1
    8000156e:	962e                	add	a2,a2,a1
    80001570:	4685                	li	a3,1
    80001572:	8231                	srli	a2,a2,0xc
    80001574:	4581                	li	a1,0
    80001576:	00000097          	auipc	ra,0x0
    8000157a:	d0a080e7          	jalr	-758(ra) # 80001280 <uvmunmap>
    8000157e:	bfe1                	j	80001556 <uvmfree+0xe>

0000000080001580 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001580:	c679                	beqz	a2,8000164e <uvmcopy+0xce>
{
    80001582:	715d                	addi	sp,sp,-80
    80001584:	e486                	sd	ra,72(sp)
    80001586:	e0a2                	sd	s0,64(sp)
    80001588:	fc26                	sd	s1,56(sp)
    8000158a:	f84a                	sd	s2,48(sp)
    8000158c:	f44e                	sd	s3,40(sp)
    8000158e:	f052                	sd	s4,32(sp)
    80001590:	ec56                	sd	s5,24(sp)
    80001592:	e85a                	sd	s6,16(sp)
    80001594:	e45e                	sd	s7,8(sp)
    80001596:	0880                	addi	s0,sp,80
    80001598:	8b2a                	mv	s6,a0
    8000159a:	8aae                	mv	s5,a1
    8000159c:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000159e:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015a0:	4601                	li	a2,0
    800015a2:	85ce                	mv	a1,s3
    800015a4:	855a                	mv	a0,s6
    800015a6:	00000097          	auipc	ra,0x0
    800015aa:	a2c080e7          	jalr	-1492(ra) # 80000fd2 <walk>
    800015ae:	c531                	beqz	a0,800015fa <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015b0:	6118                	ld	a4,0(a0)
    800015b2:	00177793          	andi	a5,a4,1
    800015b6:	cbb1                	beqz	a5,8000160a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015b8:	00a75593          	srli	a1,a4,0xa
    800015bc:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015c0:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015c4:	fffff097          	auipc	ra,0xfffff
    800015c8:	536080e7          	jalr	1334(ra) # 80000afa <kalloc>
    800015cc:	892a                	mv	s2,a0
    800015ce:	c939                	beqz	a0,80001624 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015d0:	6605                	lui	a2,0x1
    800015d2:	85de                	mv	a1,s7
    800015d4:	fffff097          	auipc	ra,0xfffff
    800015d8:	772080e7          	jalr	1906(ra) # 80000d46 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015dc:	8726                	mv	a4,s1
    800015de:	86ca                	mv	a3,s2
    800015e0:	6605                	lui	a2,0x1
    800015e2:	85ce                	mv	a1,s3
    800015e4:	8556                	mv	a0,s5
    800015e6:	00000097          	auipc	ra,0x0
    800015ea:	ad4080e7          	jalr	-1324(ra) # 800010ba <mappages>
    800015ee:	e515                	bnez	a0,8000161a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015f0:	6785                	lui	a5,0x1
    800015f2:	99be                	add	s3,s3,a5
    800015f4:	fb49e6e3          	bltu	s3,s4,800015a0 <uvmcopy+0x20>
    800015f8:	a081                	j	80001638 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015fa:	00008517          	auipc	a0,0x8
    800015fe:	b8e50513          	addi	a0,a0,-1138 # 80009188 <digits+0x148>
    80001602:	fffff097          	auipc	ra,0xfffff
    80001606:	f42080e7          	jalr	-190(ra) # 80000544 <panic>
      panic("uvmcopy: page not present");
    8000160a:	00008517          	auipc	a0,0x8
    8000160e:	b9e50513          	addi	a0,a0,-1122 # 800091a8 <digits+0x168>
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	f32080e7          	jalr	-206(ra) # 80000544 <panic>
      kfree(mem);
    8000161a:	854a                	mv	a0,s2
    8000161c:	fffff097          	auipc	ra,0xfffff
    80001620:	3e2080e7          	jalr	994(ra) # 800009fe <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001624:	4685                	li	a3,1
    80001626:	00c9d613          	srli	a2,s3,0xc
    8000162a:	4581                	li	a1,0
    8000162c:	8556                	mv	a0,s5
    8000162e:	00000097          	auipc	ra,0x0
    80001632:	c52080e7          	jalr	-942(ra) # 80001280 <uvmunmap>
  return -1;
    80001636:	557d                	li	a0,-1
}
    80001638:	60a6                	ld	ra,72(sp)
    8000163a:	6406                	ld	s0,64(sp)
    8000163c:	74e2                	ld	s1,56(sp)
    8000163e:	7942                	ld	s2,48(sp)
    80001640:	79a2                	ld	s3,40(sp)
    80001642:	7a02                	ld	s4,32(sp)
    80001644:	6ae2                	ld	s5,24(sp)
    80001646:	6b42                	ld	s6,16(sp)
    80001648:	6ba2                	ld	s7,8(sp)
    8000164a:	6161                	addi	sp,sp,80
    8000164c:	8082                	ret
  return 0;
    8000164e:	4501                	li	a0,0
}
    80001650:	8082                	ret

0000000080001652 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001652:	1141                	addi	sp,sp,-16
    80001654:	e406                	sd	ra,8(sp)
    80001656:	e022                	sd	s0,0(sp)
    80001658:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000165a:	4601                	li	a2,0
    8000165c:	00000097          	auipc	ra,0x0
    80001660:	976080e7          	jalr	-1674(ra) # 80000fd2 <walk>
  if(pte == 0)
    80001664:	c901                	beqz	a0,80001674 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001666:	611c                	ld	a5,0(a0)
    80001668:	9bbd                	andi	a5,a5,-17
    8000166a:	e11c                	sd	a5,0(a0)
}
    8000166c:	60a2                	ld	ra,8(sp)
    8000166e:	6402                	ld	s0,0(sp)
    80001670:	0141                	addi	sp,sp,16
    80001672:	8082                	ret
    panic("uvmclear");
    80001674:	00008517          	auipc	a0,0x8
    80001678:	b5450513          	addi	a0,a0,-1196 # 800091c8 <digits+0x188>
    8000167c:	fffff097          	auipc	ra,0xfffff
    80001680:	ec8080e7          	jalr	-312(ra) # 80000544 <panic>

0000000080001684 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001684:	c6bd                	beqz	a3,800016f2 <copyout+0x6e>
{
    80001686:	715d                	addi	sp,sp,-80
    80001688:	e486                	sd	ra,72(sp)
    8000168a:	e0a2                	sd	s0,64(sp)
    8000168c:	fc26                	sd	s1,56(sp)
    8000168e:	f84a                	sd	s2,48(sp)
    80001690:	f44e                	sd	s3,40(sp)
    80001692:	f052                	sd	s4,32(sp)
    80001694:	ec56                	sd	s5,24(sp)
    80001696:	e85a                	sd	s6,16(sp)
    80001698:	e45e                	sd	s7,8(sp)
    8000169a:	e062                	sd	s8,0(sp)
    8000169c:	0880                	addi	s0,sp,80
    8000169e:	8b2a                	mv	s6,a0
    800016a0:	8c2e                	mv	s8,a1
    800016a2:	8a32                	mv	s4,a2
    800016a4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016a6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016a8:	6a85                	lui	s5,0x1
    800016aa:	a015                	j	800016ce <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016ac:	9562                	add	a0,a0,s8
    800016ae:	0004861b          	sext.w	a2,s1
    800016b2:	85d2                	mv	a1,s4
    800016b4:	41250533          	sub	a0,a0,s2
    800016b8:	fffff097          	auipc	ra,0xfffff
    800016bc:	68e080e7          	jalr	1678(ra) # 80000d46 <memmove>

    len -= n;
    800016c0:	409989b3          	sub	s3,s3,s1
    src += n;
    800016c4:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016c6:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ca:	02098263          	beqz	s3,800016ee <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016ce:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016d2:	85ca                	mv	a1,s2
    800016d4:	855a                	mv	a0,s6
    800016d6:	00000097          	auipc	ra,0x0
    800016da:	9a2080e7          	jalr	-1630(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    800016de:	cd01                	beqz	a0,800016f6 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016e0:	418904b3          	sub	s1,s2,s8
    800016e4:	94d6                	add	s1,s1,s5
    if(n > len)
    800016e6:	fc99f3e3          	bgeu	s3,s1,800016ac <copyout+0x28>
    800016ea:	84ce                	mv	s1,s3
    800016ec:	b7c1                	j	800016ac <copyout+0x28>
  }
  return 0;
    800016ee:	4501                	li	a0,0
    800016f0:	a021                	j	800016f8 <copyout+0x74>
    800016f2:	4501                	li	a0,0
}
    800016f4:	8082                	ret
      return -1;
    800016f6:	557d                	li	a0,-1
}
    800016f8:	60a6                	ld	ra,72(sp)
    800016fa:	6406                	ld	s0,64(sp)
    800016fc:	74e2                	ld	s1,56(sp)
    800016fe:	7942                	ld	s2,48(sp)
    80001700:	79a2                	ld	s3,40(sp)
    80001702:	7a02                	ld	s4,32(sp)
    80001704:	6ae2                	ld	s5,24(sp)
    80001706:	6b42                	ld	s6,16(sp)
    80001708:	6ba2                	ld	s7,8(sp)
    8000170a:	6c02                	ld	s8,0(sp)
    8000170c:	6161                	addi	sp,sp,80
    8000170e:	8082                	ret

0000000080001710 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001710:	c6bd                	beqz	a3,8000177e <copyin+0x6e>
{
    80001712:	715d                	addi	sp,sp,-80
    80001714:	e486                	sd	ra,72(sp)
    80001716:	e0a2                	sd	s0,64(sp)
    80001718:	fc26                	sd	s1,56(sp)
    8000171a:	f84a                	sd	s2,48(sp)
    8000171c:	f44e                	sd	s3,40(sp)
    8000171e:	f052                	sd	s4,32(sp)
    80001720:	ec56                	sd	s5,24(sp)
    80001722:	e85a                	sd	s6,16(sp)
    80001724:	e45e                	sd	s7,8(sp)
    80001726:	e062                	sd	s8,0(sp)
    80001728:	0880                	addi	s0,sp,80
    8000172a:	8b2a                	mv	s6,a0
    8000172c:	8a2e                	mv	s4,a1
    8000172e:	8c32                	mv	s8,a2
    80001730:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001732:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001734:	6a85                	lui	s5,0x1
    80001736:	a015                	j	8000175a <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001738:	9562                	add	a0,a0,s8
    8000173a:	0004861b          	sext.w	a2,s1
    8000173e:	412505b3          	sub	a1,a0,s2
    80001742:	8552                	mv	a0,s4
    80001744:	fffff097          	auipc	ra,0xfffff
    80001748:	602080e7          	jalr	1538(ra) # 80000d46 <memmove>

    len -= n;
    8000174c:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001750:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001752:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001756:	02098263          	beqz	s3,8000177a <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000175a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000175e:	85ca                	mv	a1,s2
    80001760:	855a                	mv	a0,s6
    80001762:	00000097          	auipc	ra,0x0
    80001766:	916080e7          	jalr	-1770(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    8000176a:	cd01                	beqz	a0,80001782 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000176c:	418904b3          	sub	s1,s2,s8
    80001770:	94d6                	add	s1,s1,s5
    if(n > len)
    80001772:	fc99f3e3          	bgeu	s3,s1,80001738 <copyin+0x28>
    80001776:	84ce                	mv	s1,s3
    80001778:	b7c1                	j	80001738 <copyin+0x28>
  }
  return 0;
    8000177a:	4501                	li	a0,0
    8000177c:	a021                	j	80001784 <copyin+0x74>
    8000177e:	4501                	li	a0,0
}
    80001780:	8082                	ret
      return -1;
    80001782:	557d                	li	a0,-1
}
    80001784:	60a6                	ld	ra,72(sp)
    80001786:	6406                	ld	s0,64(sp)
    80001788:	74e2                	ld	s1,56(sp)
    8000178a:	7942                	ld	s2,48(sp)
    8000178c:	79a2                	ld	s3,40(sp)
    8000178e:	7a02                	ld	s4,32(sp)
    80001790:	6ae2                	ld	s5,24(sp)
    80001792:	6b42                	ld	s6,16(sp)
    80001794:	6ba2                	ld	s7,8(sp)
    80001796:	6c02                	ld	s8,0(sp)
    80001798:	6161                	addi	sp,sp,80
    8000179a:	8082                	ret

000000008000179c <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000179c:	c6c5                	beqz	a3,80001844 <copyinstr+0xa8>
{
    8000179e:	715d                	addi	sp,sp,-80
    800017a0:	e486                	sd	ra,72(sp)
    800017a2:	e0a2                	sd	s0,64(sp)
    800017a4:	fc26                	sd	s1,56(sp)
    800017a6:	f84a                	sd	s2,48(sp)
    800017a8:	f44e                	sd	s3,40(sp)
    800017aa:	f052                	sd	s4,32(sp)
    800017ac:	ec56                	sd	s5,24(sp)
    800017ae:	e85a                	sd	s6,16(sp)
    800017b0:	e45e                	sd	s7,8(sp)
    800017b2:	0880                	addi	s0,sp,80
    800017b4:	8a2a                	mv	s4,a0
    800017b6:	8b2e                	mv	s6,a1
    800017b8:	8bb2                	mv	s7,a2
    800017ba:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017bc:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017be:	6985                	lui	s3,0x1
    800017c0:	a035                	j	800017ec <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017c2:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017c6:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017c8:	0017b793          	seqz	a5,a5
    800017cc:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017d0:	60a6                	ld	ra,72(sp)
    800017d2:	6406                	ld	s0,64(sp)
    800017d4:	74e2                	ld	s1,56(sp)
    800017d6:	7942                	ld	s2,48(sp)
    800017d8:	79a2                	ld	s3,40(sp)
    800017da:	7a02                	ld	s4,32(sp)
    800017dc:	6ae2                	ld	s5,24(sp)
    800017de:	6b42                	ld	s6,16(sp)
    800017e0:	6ba2                	ld	s7,8(sp)
    800017e2:	6161                	addi	sp,sp,80
    800017e4:	8082                	ret
    srcva = va0 + PGSIZE;
    800017e6:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017ea:	c8a9                	beqz	s1,8000183c <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017ec:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017f0:	85ca                	mv	a1,s2
    800017f2:	8552                	mv	a0,s4
    800017f4:	00000097          	auipc	ra,0x0
    800017f8:	884080e7          	jalr	-1916(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    800017fc:	c131                	beqz	a0,80001840 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017fe:	41790833          	sub	a6,s2,s7
    80001802:	984e                	add	a6,a6,s3
    if(n > max)
    80001804:	0104f363          	bgeu	s1,a6,8000180a <copyinstr+0x6e>
    80001808:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000180a:	955e                	add	a0,a0,s7
    8000180c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001810:	fc080be3          	beqz	a6,800017e6 <copyinstr+0x4a>
    80001814:	985a                	add	a6,a6,s6
    80001816:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001818:	41650633          	sub	a2,a0,s6
    8000181c:	14fd                	addi	s1,s1,-1
    8000181e:	9b26                	add	s6,s6,s1
    80001820:	00f60733          	add	a4,a2,a5
    80001824:	00074703          	lbu	a4,0(a4)
    80001828:	df49                	beqz	a4,800017c2 <copyinstr+0x26>
        *dst = *p;
    8000182a:	00e78023          	sb	a4,0(a5)
      --max;
    8000182e:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001832:	0785                	addi	a5,a5,1
    while(n > 0){
    80001834:	ff0796e3          	bne	a5,a6,80001820 <copyinstr+0x84>
      dst++;
    80001838:	8b42                	mv	s6,a6
    8000183a:	b775                	j	800017e6 <copyinstr+0x4a>
    8000183c:	4781                	li	a5,0
    8000183e:	b769                	j	800017c8 <copyinstr+0x2c>
      return -1;
    80001840:	557d                	li	a0,-1
    80001842:	b779                	j	800017d0 <copyinstr+0x34>
  int got_null = 0;
    80001844:	4781                	li	a5,0
  if(got_null){
    80001846:	0017b793          	seqz	a5,a5
    8000184a:	40f00533          	neg	a0,a5
}
    8000184e:	8082                	ret

0000000080001850 <enqueue>:
struct priority_queue queues[5];
int priority_levels[5] = {1,2,4,8,16};

void enqueue(struct proc *process)
{
  int idx = process->priority;
    80001850:	1b452703          	lw	a4,436(a0)
  //printf("%d %d\n",queues[idx].back, queues[idx].length);
  if (queues[idx].length == NPROC)
    80001854:	21800793          	li	a5,536
    80001858:	02f706b3          	mul	a3,a4,a5
    8000185c:	00011797          	auipc	a5,0x11
    80001860:	9e478793          	addi	a5,a5,-1564 # 80012240 <queues>
    80001864:	97b6                	add	a5,a5,a3
    80001866:	4790                	lw	a2,8(a5)
    80001868:	04000793          	li	a5,64
    8000186c:	06f60a63          	beq	a2,a5,800018e0 <enqueue+0x90>
    panic("Full queue");

  queues[idx].procs[queues[idx].back] = process;
    80001870:	00011597          	auipc	a1,0x11
    80001874:	9d058593          	addi	a1,a1,-1584 # 80012240 <queues>
    80001878:	21800693          	li	a3,536
    8000187c:	02d706b3          	mul	a3,a4,a3
    80001880:	96ae                	add	a3,a3,a1
    80001882:	42d4                	lw	a3,4(a3)
    80001884:	00471793          	slli	a5,a4,0x4
    80001888:	97ba                	add	a5,a5,a4
    8000188a:	078a                	slli	a5,a5,0x2
    8000188c:	8f99                	sub	a5,a5,a4
    8000188e:	97b6                	add	a5,a5,a3
    80001890:	0789                	addi	a5,a5,2
    80001892:	078e                	slli	a5,a5,0x3
    80001894:	97ae                	add	a5,a5,a1
    80001896:	e388                	sd	a0,0(a5)
  queues[idx].back++;  
    80001898:	2685                	addiw	a3,a3,1
    8000189a:	0006859b          	sext.w	a1,a3
  if (queues[idx].back == NPROC + 1) queues[idx].back = 0;
    8000189e:	04100793          	li	a5,65
    800018a2:	04f58b63          	beq	a1,a5,800018f8 <enqueue+0xa8>
  queues[idx].back++;  
    800018a6:	21800793          	li	a5,536
    800018aa:	02f705b3          	mul	a1,a4,a5
    800018ae:	00011797          	auipc	a5,0x11
    800018b2:	99278793          	addi	a5,a5,-1646 # 80012240 <queues>
    800018b6:	97ae                	add	a5,a5,a1
    800018b8:	c3d4                	sw	a3,4(a5)
  queues[idx].length++;
    800018ba:	21800793          	li	a5,536
    800018be:	02f70733          	mul	a4,a4,a5
    800018c2:	00011797          	auipc	a5,0x11
    800018c6:	97e78793          	addi	a5,a5,-1666 # 80012240 <queues>
    800018ca:	973e                	add	a4,a4,a5
    800018cc:	2605                	addiw	a2,a2,1
    800018ce:	c710                	sw	a2,8(a4)
  process->curr_rtime = 0;
    800018d0:	1a052e23          	sw	zero,444(a0)
  process->curr_wtime = 0;
    800018d4:	1c052023          	sw	zero,448(a0)
  process->in_queue = 1;
    800018d8:	4785                	li	a5,1
    800018da:	1af52c23          	sw	a5,440(a0)
    800018de:	8082                	ret
{
    800018e0:	1141                	addi	sp,sp,-16
    800018e2:	e406                	sd	ra,8(sp)
    800018e4:	e022                	sd	s0,0(sp)
    800018e6:	0800                	addi	s0,sp,16
    panic("Full queue");
    800018e8:	00008517          	auipc	a0,0x8
    800018ec:	8f050513          	addi	a0,a0,-1808 # 800091d8 <digits+0x198>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	c54080e7          	jalr	-940(ra) # 80000544 <panic>
  if (queues[idx].back == NPROC + 1) queues[idx].back = 0;
    800018f8:	21800793          	li	a5,536
    800018fc:	02f706b3          	mul	a3,a4,a5
    80001900:	00011797          	auipc	a5,0x11
    80001904:	94078793          	addi	a5,a5,-1728 # 80012240 <queues>
    80001908:	97b6                	add	a5,a5,a3
    8000190a:	0007a223          	sw	zero,4(a5)
    8000190e:	b775                	j	800018ba <enqueue+0x6a>

0000000080001910 <dequeue>:
  //printf("size: %d\n",q->size);
}

void dequeue(struct proc *process)
{
  int idx = process->priority;
    80001910:	1b452783          	lw	a5,436(a0)
  if (queues[idx].length == 0)
    80001914:	21800713          	li	a4,536
    80001918:	02e786b3          	mul	a3,a5,a4
    8000191c:	00011717          	auipc	a4,0x11
    80001920:	92470713          	addi	a4,a4,-1756 # 80012240 <queues>
    80001924:	9736                	add	a4,a4,a3
    80001926:	4718                	lw	a4,8(a4)
    80001928:	cb31                	beqz	a4,8000197c <dequeue+0x6c>
    panic("Empty queue");
  
  queues[idx].front++;
    8000192a:	21800693          	li	a3,536
    8000192e:	02d78633          	mul	a2,a5,a3
    80001932:	00011697          	auipc	a3,0x11
    80001936:	90e68693          	addi	a3,a3,-1778 # 80012240 <queues>
    8000193a:	96b2                	add	a3,a3,a2
    8000193c:	4294                	lw	a3,0(a3)
    8000193e:	2685                	addiw	a3,a3,1
    80001940:	0006859b          	sext.w	a1,a3
  if (queues[idx].front == NPROC + 1) queues[idx].front = 0;
    80001944:	04100613          	li	a2,65
    80001948:	04c58663          	beq	a1,a2,80001994 <dequeue+0x84>
  queues[idx].front++;
    8000194c:	21800613          	li	a2,536
    80001950:	02c785b3          	mul	a1,a5,a2
    80001954:	00011617          	auipc	a2,0x11
    80001958:	8ec60613          	addi	a2,a2,-1812 # 80012240 <queues>
    8000195c:	962e                	add	a2,a2,a1
    8000195e:	c214                	sw	a3,0(a2)
  queues[idx].length--;
    80001960:	21800693          	li	a3,536
    80001964:	02d787b3          	mul	a5,a5,a3
    80001968:	00011697          	auipc	a3,0x11
    8000196c:	8d868693          	addi	a3,a3,-1832 # 80012240 <queues>
    80001970:	97b6                	add	a5,a5,a3
    80001972:	377d                	addiw	a4,a4,-1
    80001974:	c798                	sw	a4,8(a5)
  process->in_queue = 0;
    80001976:	1a052c23          	sw	zero,440(a0)
    8000197a:	8082                	ret
{
    8000197c:	1141                	addi	sp,sp,-16
    8000197e:	e406                	sd	ra,8(sp)
    80001980:	e022                	sd	s0,0(sp)
    80001982:	0800                	addi	s0,sp,16
    panic("Empty queue");
    80001984:	00008517          	auipc	a0,0x8
    80001988:	86450513          	addi	a0,a0,-1948 # 800091e8 <digits+0x1a8>
    8000198c:	fffff097          	auipc	ra,0xfffff
    80001990:	bb8080e7          	jalr	-1096(ra) # 80000544 <panic>
  if (queues[idx].front == NPROC + 1) queues[idx].front = 0;
    80001994:	21800693          	li	a3,536
    80001998:	02d78633          	mul	a2,a5,a3
    8000199c:	00011697          	auipc	a3,0x11
    800019a0:	8a468693          	addi	a3,a3,-1884 # 80012240 <queues>
    800019a4:	96b2                	add	a3,a3,a2
    800019a6:	0006a023          	sw	zero,0(a3)
    800019aa:	bf5d                	j	80001960 <dequeue+0x50>

00000000800019ac <delqueue>:
}

void delqueue(struct proc *process)
{
    800019ac:	1141                	addi	sp,sp,-16
    800019ae:	e422                	sd	s0,8(sp)
    800019b0:	0800                	addi	s0,sp,16
  int idx = process->priority;
    800019b2:	1b452883          	lw	a7,436(a0)
  int curr = queues[idx].front;
    800019b6:	21800793          	li	a5,536
    800019ba:	02f88733          	mul	a4,a7,a5
    800019be:	00011797          	auipc	a5,0x11
    800019c2:	88278793          	addi	a5,a5,-1918 # 80012240 <queues>
    800019c6:	97ba                	add	a5,a5,a4
    800019c8:	4394                	lw	a3,0(a5)
  while (curr != queues[idx].back)
    800019ca:	43c8                	lw	a0,4(a5)
    800019cc:	02a68f63          	beq	a3,a0,80001a0a <delqueue+0x5e>
  {
      //struct proc *temp = queues[idx].procs[curr];
    queues[idx].procs[curr] = queues[idx].procs[(curr + 1) % (NPROC + 1)];
    800019d0:	04100813          	li	a6,65
    800019d4:	00011597          	auipc	a1,0x11
    800019d8:	86c58593          	addi	a1,a1,-1940 # 80012240 <queues>
    800019dc:	00489613          	slli	a2,a7,0x4
    800019e0:	9646                	add	a2,a2,a7
    800019e2:	060a                	slli	a2,a2,0x2
    800019e4:	41160633          	sub	a2,a2,a7
    800019e8:	87b6                	mv	a5,a3
    800019ea:	2685                	addiw	a3,a3,1
    800019ec:	0306e6bb          	remw	a3,a3,a6
    800019f0:	00d60733          	add	a4,a2,a3
    800019f4:	0709                	addi	a4,a4,2
    800019f6:	070e                	slli	a4,a4,0x3
    800019f8:	972e                	add	a4,a4,a1
    800019fa:	6318                	ld	a4,0(a4)
    800019fc:	97b2                	add	a5,a5,a2
    800019fe:	0789                	addi	a5,a5,2
    80001a00:	078e                	slli	a5,a5,0x3
    80001a02:	97ae                	add	a5,a5,a1
    80001a04:	e398                	sd	a4,0(a5)
  while (curr != queues[idx].back)
    80001a06:	fea691e3          	bne	a3,a0,800019e8 <delqueue+0x3c>
      //queues[idx].procs[(curr + 1) % (NPROC + 1)] = temp;
    curr = (curr + 1) % (NPROC + 1);
  }

  queues[idx].back--;
    80001a0a:	357d                	addiw	a0,a0,-1
    80001a0c:	21800793          	li	a5,536
    80001a10:	02f88733          	mul	a4,a7,a5
    80001a14:	00011797          	auipc	a5,0x11
    80001a18:	82c78793          	addi	a5,a5,-2004 # 80012240 <queues>
    80001a1c:	97ba                	add	a5,a5,a4
    80001a1e:	c3c8                	sw	a0,4(a5)
  queues[idx].length--;
    80001a20:	4798                	lw	a4,8(a5)
    80001a22:	377d                	addiw	a4,a4,-1
    80001a24:	c798                	sw	a4,8(a5)
  if (queues[idx].back < 0)
    80001a26:	02051793          	slli	a5,a0,0x20
    80001a2a:	0007c563          	bltz	a5,80001a34 <delqueue+0x88>
    queues[idx].back = NPROC;
}
    80001a2e:	6422                	ld	s0,8(sp)
    80001a30:	0141                	addi	sp,sp,16
    80001a32:	8082                	ret
    queues[idx].back = NPROC;
    80001a34:	21800793          	li	a5,536
    80001a38:	02f888b3          	mul	a7,a7,a5
    80001a3c:	00011797          	auipc	a5,0x11
    80001a40:	80478793          	addi	a5,a5,-2044 # 80012240 <queues>
    80001a44:	98be                	add	a7,a7,a5
    80001a46:	04000793          	li	a5,64
    80001a4a:	00f8a223          	sw	a5,4(a7)
}
    80001a4e:	b7c5                	j	80001a2e <delqueue+0x82>

0000000080001a50 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001a50:	7139                	addi	sp,sp,-64
    80001a52:	fc06                	sd	ra,56(sp)
    80001a54:	f822                	sd	s0,48(sp)
    80001a56:	f426                	sd	s1,40(sp)
    80001a58:	f04a                	sd	s2,32(sp)
    80001a5a:	ec4e                	sd	s3,24(sp)
    80001a5c:	e852                	sd	s4,16(sp)
    80001a5e:	e456                	sd	s5,8(sp)
    80001a60:	e05a                	sd	s6,0(sp)
    80001a62:	0080                	addi	s0,sp,64
    80001a64:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a66:	00011497          	auipc	s1,0x11
    80001a6a:	25248493          	addi	s1,s1,594 # 80012cb8 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001a6e:	8b26                	mv	s6,s1
    80001a70:	00007a97          	auipc	s5,0x7
    80001a74:	590a8a93          	addi	s5,s5,1424 # 80009000 <etext>
    80001a78:	04000937          	lui	s2,0x4000
    80001a7c:	197d                	addi	s2,s2,-1
    80001a7e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a80:	00018a17          	auipc	s4,0x18
    80001a84:	438a0a13          	addi	s4,s4,1080 # 80019eb8 <tickslock>
    char *pa = kalloc();
    80001a88:	fffff097          	auipc	ra,0xfffff
    80001a8c:	072080e7          	jalr	114(ra) # 80000afa <kalloc>
    80001a90:	862a                	mv	a2,a0
    if(pa == 0)
    80001a92:	c131                	beqz	a0,80001ad6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001a94:	416485b3          	sub	a1,s1,s6
    80001a98:	858d                	srai	a1,a1,0x3
    80001a9a:	000ab783          	ld	a5,0(s5)
    80001a9e:	02f585b3          	mul	a1,a1,a5
    80001aa2:	2585                	addiw	a1,a1,1
    80001aa4:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001aa8:	4719                	li	a4,6
    80001aaa:	6685                	lui	a3,0x1
    80001aac:	40b905b3          	sub	a1,s2,a1
    80001ab0:	854e                	mv	a0,s3
    80001ab2:	fffff097          	auipc	ra,0xfffff
    80001ab6:	6a8080e7          	jalr	1704(ra) # 8000115a <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001aba:	1c848493          	addi	s1,s1,456
    80001abe:	fd4495e3          	bne	s1,s4,80001a88 <proc_mapstacks+0x38>
  }
}
    80001ac2:	70e2                	ld	ra,56(sp)
    80001ac4:	7442                	ld	s0,48(sp)
    80001ac6:	74a2                	ld	s1,40(sp)
    80001ac8:	7902                	ld	s2,32(sp)
    80001aca:	69e2                	ld	s3,24(sp)
    80001acc:	6a42                	ld	s4,16(sp)
    80001ace:	6aa2                	ld	s5,8(sp)
    80001ad0:	6b02                	ld	s6,0(sp)
    80001ad2:	6121                	addi	sp,sp,64
    80001ad4:	8082                	ret
      panic("kalloc");
    80001ad6:	00007517          	auipc	a0,0x7
    80001ada:	72250513          	addi	a0,a0,1826 # 800091f8 <digits+0x1b8>
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	a66080e7          	jalr	-1434(ra) # 80000544 <panic>

0000000080001ae6 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001ae6:	7139                	addi	sp,sp,-64
    80001ae8:	fc06                	sd	ra,56(sp)
    80001aea:	f822                	sd	s0,48(sp)
    80001aec:	f426                	sd	s1,40(sp)
    80001aee:	f04a                	sd	s2,32(sp)
    80001af0:	ec4e                	sd	s3,24(sp)
    80001af2:	e852                	sd	s4,16(sp)
    80001af4:	e456                	sd	s5,8(sp)
    80001af6:	e05a                	sd	s6,0(sp)
    80001af8:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001afa:	00007597          	auipc	a1,0x7
    80001afe:	70658593          	addi	a1,a1,1798 # 80009200 <digits+0x1c0>
    80001b02:	00010517          	auipc	a0,0x10
    80001b06:	30e50513          	addi	a0,a0,782 # 80011e10 <pid_lock>
    80001b0a:	fffff097          	auipc	ra,0xfffff
    80001b0e:	050080e7          	jalr	80(ra) # 80000b5a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001b12:	00007597          	auipc	a1,0x7
    80001b16:	6f658593          	addi	a1,a1,1782 # 80009208 <digits+0x1c8>
    80001b1a:	00010517          	auipc	a0,0x10
    80001b1e:	30e50513          	addi	a0,a0,782 # 80011e28 <wait_lock>
    80001b22:	fffff097          	auipc	ra,0xfffff
    80001b26:	038080e7          	jalr	56(ra) # 80000b5a <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b2a:	00011497          	auipc	s1,0x11
    80001b2e:	18e48493          	addi	s1,s1,398 # 80012cb8 <proc>
      initlock(&p->lock, "proc");
    80001b32:	00007b17          	auipc	s6,0x7
    80001b36:	6e6b0b13          	addi	s6,s6,1766 # 80009218 <digits+0x1d8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001b3a:	8aa6                	mv	s5,s1
    80001b3c:	00007a17          	auipc	s4,0x7
    80001b40:	4c4a0a13          	addi	s4,s4,1220 # 80009000 <etext>
    80001b44:	04000937          	lui	s2,0x4000
    80001b48:	197d                	addi	s2,s2,-1
    80001b4a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b4c:	00018997          	auipc	s3,0x18
    80001b50:	36c98993          	addi	s3,s3,876 # 80019eb8 <tickslock>
      initlock(&p->lock, "proc");
    80001b54:	85da                	mv	a1,s6
    80001b56:	8526                	mv	a0,s1
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	002080e7          	jalr	2(ra) # 80000b5a <initlock>
      p->state = UNUSED;
    80001b60:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001b64:	415487b3          	sub	a5,s1,s5
    80001b68:	878d                	srai	a5,a5,0x3
    80001b6a:	000a3703          	ld	a4,0(s4)
    80001b6e:	02e787b3          	mul	a5,a5,a4
    80001b72:	2785                	addiw	a5,a5,1
    80001b74:	00d7979b          	slliw	a5,a5,0xd
    80001b78:	40f907b3          	sub	a5,s2,a5
    80001b7c:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b7e:	1c848493          	addi	s1,s1,456
    80001b82:	fd3499e3          	bne	s1,s3,80001b54 <procinit+0x6e>
  }
}
    80001b86:	70e2                	ld	ra,56(sp)
    80001b88:	7442                	ld	s0,48(sp)
    80001b8a:	74a2                	ld	s1,40(sp)
    80001b8c:	7902                	ld	s2,32(sp)
    80001b8e:	69e2                	ld	s3,24(sp)
    80001b90:	6a42                	ld	s4,16(sp)
    80001b92:	6aa2                	ld	s5,8(sp)
    80001b94:	6b02                	ld	s6,0(sp)
    80001b96:	6121                	addi	sp,sp,64
    80001b98:	8082                	ret

0000000080001b9a <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001b9a:	1141                	addi	sp,sp,-16
    80001b9c:	e422                	sd	s0,8(sp)
    80001b9e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ba0:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001ba2:	2501                	sext.w	a0,a0
    80001ba4:	6422                	ld	s0,8(sp)
    80001ba6:	0141                	addi	sp,sp,16
    80001ba8:	8082                	ret

0000000080001baa <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001baa:	1141                	addi	sp,sp,-16
    80001bac:	e422                	sd	s0,8(sp)
    80001bae:	0800                	addi	s0,sp,16
    80001bb0:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001bb2:	2781                	sext.w	a5,a5
    80001bb4:	079e                	slli	a5,a5,0x7
  return c;
}
    80001bb6:	00010517          	auipc	a0,0x10
    80001bba:	28a50513          	addi	a0,a0,650 # 80011e40 <cpus>
    80001bbe:	953e                	add	a0,a0,a5
    80001bc0:	6422                	ld	s0,8(sp)
    80001bc2:	0141                	addi	sp,sp,16
    80001bc4:	8082                	ret

0000000080001bc6 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001bc6:	1101                	addi	sp,sp,-32
    80001bc8:	ec06                	sd	ra,24(sp)
    80001bca:	e822                	sd	s0,16(sp)
    80001bcc:	e426                	sd	s1,8(sp)
    80001bce:	1000                	addi	s0,sp,32
  push_off();
    80001bd0:	fffff097          	auipc	ra,0xfffff
    80001bd4:	fce080e7          	jalr	-50(ra) # 80000b9e <push_off>
    80001bd8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001bda:	2781                	sext.w	a5,a5
    80001bdc:	079e                	slli	a5,a5,0x7
    80001bde:	00010717          	auipc	a4,0x10
    80001be2:	23270713          	addi	a4,a4,562 # 80011e10 <pid_lock>
    80001be6:	97ba                	add	a5,a5,a4
    80001be8:	7b84                	ld	s1,48(a5)
  pop_off();
    80001bea:	fffff097          	auipc	ra,0xfffff
    80001bee:	054080e7          	jalr	84(ra) # 80000c3e <pop_off>
  return p;
}
    80001bf2:	8526                	mv	a0,s1
    80001bf4:	60e2                	ld	ra,24(sp)
    80001bf6:	6442                	ld	s0,16(sp)
    80001bf8:	64a2                	ld	s1,8(sp)
    80001bfa:	6105                	addi	sp,sp,32
    80001bfc:	8082                	ret

0000000080001bfe <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001bfe:	1141                	addi	sp,sp,-16
    80001c00:	e406                	sd	ra,8(sp)
    80001c02:	e022                	sd	s0,0(sp)
    80001c04:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001c06:	00000097          	auipc	ra,0x0
    80001c0a:	fc0080e7          	jalr	-64(ra) # 80001bc6 <myproc>
    80001c0e:	fffff097          	auipc	ra,0xfffff
    80001c12:	090080e7          	jalr	144(ra) # 80000c9e <release>

  if (first) {
    80001c16:	00008797          	auipc	a5,0x8
    80001c1a:	dfa7a783          	lw	a5,-518(a5) # 80009a10 <first.1767>
    80001c1e:	eb89                	bnez	a5,80001c30 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001c20:	00001097          	auipc	ra,0x1
    80001c24:	014080e7          	jalr	20(ra) # 80002c34 <usertrapret>
}
    80001c28:	60a2                	ld	ra,8(sp)
    80001c2a:	6402                	ld	s0,0(sp)
    80001c2c:	0141                	addi	sp,sp,16
    80001c2e:	8082                	ret
    first = 0;
    80001c30:	00008797          	auipc	a5,0x8
    80001c34:	de07a023          	sw	zero,-544(a5) # 80009a10 <first.1767>
    fsinit(ROOTDEV);
    80001c38:	4505                	li	a0,1
    80001c3a:	00002097          	auipc	ra,0x2
    80001c3e:	496080e7          	jalr	1174(ra) # 800040d0 <fsinit>
    80001c42:	bff9                	j	80001c20 <forkret+0x22>

0000000080001c44 <allocpid>:
{
    80001c44:	1101                	addi	sp,sp,-32
    80001c46:	ec06                	sd	ra,24(sp)
    80001c48:	e822                	sd	s0,16(sp)
    80001c4a:	e426                	sd	s1,8(sp)
    80001c4c:	e04a                	sd	s2,0(sp)
    80001c4e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001c50:	00010917          	auipc	s2,0x10
    80001c54:	1c090913          	addi	s2,s2,448 # 80011e10 <pid_lock>
    80001c58:	854a                	mv	a0,s2
    80001c5a:	fffff097          	auipc	ra,0xfffff
    80001c5e:	f90080e7          	jalr	-112(ra) # 80000bea <acquire>
  pid = nextpid;
    80001c62:	00008797          	auipc	a5,0x8
    80001c66:	db278793          	addi	a5,a5,-590 # 80009a14 <nextpid>
    80001c6a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c6c:	0014871b          	addiw	a4,s1,1
    80001c70:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c72:	854a                	mv	a0,s2
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	02a080e7          	jalr	42(ra) # 80000c9e <release>
}
    80001c7c:	8526                	mv	a0,s1
    80001c7e:	60e2                	ld	ra,24(sp)
    80001c80:	6442                	ld	s0,16(sp)
    80001c82:	64a2                	ld	s1,8(sp)
    80001c84:	6902                	ld	s2,0(sp)
    80001c86:	6105                	addi	sp,sp,32
    80001c88:	8082                	ret

0000000080001c8a <proc_pagetable>:
{
    80001c8a:	1101                	addi	sp,sp,-32
    80001c8c:	ec06                	sd	ra,24(sp)
    80001c8e:	e822                	sd	s0,16(sp)
    80001c90:	e426                	sd	s1,8(sp)
    80001c92:	e04a                	sd	s2,0(sp)
    80001c94:	1000                	addi	s0,sp,32
    80001c96:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	6ac080e7          	jalr	1708(ra) # 80001344 <uvmcreate>
    80001ca0:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ca2:	c121                	beqz	a0,80001ce2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ca4:	4729                	li	a4,10
    80001ca6:	00006697          	auipc	a3,0x6
    80001caa:	35a68693          	addi	a3,a3,858 # 80008000 <_trampoline>
    80001cae:	6605                	lui	a2,0x1
    80001cb0:	040005b7          	lui	a1,0x4000
    80001cb4:	15fd                	addi	a1,a1,-1
    80001cb6:	05b2                	slli	a1,a1,0xc
    80001cb8:	fffff097          	auipc	ra,0xfffff
    80001cbc:	402080e7          	jalr	1026(ra) # 800010ba <mappages>
    80001cc0:	02054863          	bltz	a0,80001cf0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001cc4:	4719                	li	a4,6
    80001cc6:	05893683          	ld	a3,88(s2)
    80001cca:	6605                	lui	a2,0x1
    80001ccc:	020005b7          	lui	a1,0x2000
    80001cd0:	15fd                	addi	a1,a1,-1
    80001cd2:	05b6                	slli	a1,a1,0xd
    80001cd4:	8526                	mv	a0,s1
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	3e4080e7          	jalr	996(ra) # 800010ba <mappages>
    80001cde:	02054163          	bltz	a0,80001d00 <proc_pagetable+0x76>
}
    80001ce2:	8526                	mv	a0,s1
    80001ce4:	60e2                	ld	ra,24(sp)
    80001ce6:	6442                	ld	s0,16(sp)
    80001ce8:	64a2                	ld	s1,8(sp)
    80001cea:	6902                	ld	s2,0(sp)
    80001cec:	6105                	addi	sp,sp,32
    80001cee:	8082                	ret
    uvmfree(pagetable, 0);
    80001cf0:	4581                	li	a1,0
    80001cf2:	8526                	mv	a0,s1
    80001cf4:	00000097          	auipc	ra,0x0
    80001cf8:	854080e7          	jalr	-1964(ra) # 80001548 <uvmfree>
    return 0;
    80001cfc:	4481                	li	s1,0
    80001cfe:	b7d5                	j	80001ce2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d00:	4681                	li	a3,0
    80001d02:	4605                	li	a2,1
    80001d04:	040005b7          	lui	a1,0x4000
    80001d08:	15fd                	addi	a1,a1,-1
    80001d0a:	05b2                	slli	a1,a1,0xc
    80001d0c:	8526                	mv	a0,s1
    80001d0e:	fffff097          	auipc	ra,0xfffff
    80001d12:	572080e7          	jalr	1394(ra) # 80001280 <uvmunmap>
    uvmfree(pagetable, 0);
    80001d16:	4581                	li	a1,0
    80001d18:	8526                	mv	a0,s1
    80001d1a:	00000097          	auipc	ra,0x0
    80001d1e:	82e080e7          	jalr	-2002(ra) # 80001548 <uvmfree>
    return 0;
    80001d22:	4481                	li	s1,0
    80001d24:	bf7d                	j	80001ce2 <proc_pagetable+0x58>

0000000080001d26 <proc_freepagetable>:
{
    80001d26:	1101                	addi	sp,sp,-32
    80001d28:	ec06                	sd	ra,24(sp)
    80001d2a:	e822                	sd	s0,16(sp)
    80001d2c:	e426                	sd	s1,8(sp)
    80001d2e:	e04a                	sd	s2,0(sp)
    80001d30:	1000                	addi	s0,sp,32
    80001d32:	84aa                	mv	s1,a0
    80001d34:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d36:	4681                	li	a3,0
    80001d38:	4605                	li	a2,1
    80001d3a:	040005b7          	lui	a1,0x4000
    80001d3e:	15fd                	addi	a1,a1,-1
    80001d40:	05b2                	slli	a1,a1,0xc
    80001d42:	fffff097          	auipc	ra,0xfffff
    80001d46:	53e080e7          	jalr	1342(ra) # 80001280 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d4a:	4681                	li	a3,0
    80001d4c:	4605                	li	a2,1
    80001d4e:	020005b7          	lui	a1,0x2000
    80001d52:	15fd                	addi	a1,a1,-1
    80001d54:	05b6                	slli	a1,a1,0xd
    80001d56:	8526                	mv	a0,s1
    80001d58:	fffff097          	auipc	ra,0xfffff
    80001d5c:	528080e7          	jalr	1320(ra) # 80001280 <uvmunmap>
  uvmfree(pagetable, sz);
    80001d60:	85ca                	mv	a1,s2
    80001d62:	8526                	mv	a0,s1
    80001d64:	fffff097          	auipc	ra,0xfffff
    80001d68:	7e4080e7          	jalr	2020(ra) # 80001548 <uvmfree>
}
    80001d6c:	60e2                	ld	ra,24(sp)
    80001d6e:	6442                	ld	s0,16(sp)
    80001d70:	64a2                	ld	s1,8(sp)
    80001d72:	6902                	ld	s2,0(sp)
    80001d74:	6105                	addi	sp,sp,32
    80001d76:	8082                	ret

0000000080001d78 <freeproc>:
{
    80001d78:	1101                	addi	sp,sp,-32
    80001d7a:	ec06                	sd	ra,24(sp)
    80001d7c:	e822                	sd	s0,16(sp)
    80001d7e:	e426                	sd	s1,8(sp)
    80001d80:	1000                	addi	s0,sp,32
    80001d82:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001d84:	6d28                	ld	a0,88(a0)
    80001d86:	c509                	beqz	a0,80001d90 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001d88:	fffff097          	auipc	ra,0xfffff
    80001d8c:	c76080e7          	jalr	-906(ra) # 800009fe <kfree>
  p->trapframe = 0;
    80001d90:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001d94:	68a8                	ld	a0,80(s1)
    80001d96:	c511                	beqz	a0,80001da2 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d98:	64ac                	ld	a1,72(s1)
    80001d9a:	00000097          	auipc	ra,0x0
    80001d9e:	f8c080e7          	jalr	-116(ra) # 80001d26 <proc_freepagetable>
  p->pagetable = 0;
    80001da2:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001da6:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001daa:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001dae:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001db2:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001db6:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001dba:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001dbe:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001dc2:	0004ac23          	sw	zero,24(s1)
  p->etime = 0;
    80001dc6:	1604a823          	sw	zero,368(s1)
  p->rtime = 0;
    80001dca:	1604a423          	sw	zero,360(s1)
  p->ctime = 0;
    80001dce:	1604a623          	sw	zero,364(s1)
}
    80001dd2:	60e2                	ld	ra,24(sp)
    80001dd4:	6442                	ld	s0,16(sp)
    80001dd6:	64a2                	ld	s1,8(sp)
    80001dd8:	6105                	addi	sp,sp,32
    80001dda:	8082                	ret

0000000080001ddc <allocproc>:
{
    80001ddc:	1101                	addi	sp,sp,-32
    80001dde:	ec06                	sd	ra,24(sp)
    80001de0:	e822                	sd	s0,16(sp)
    80001de2:	e426                	sd	s1,8(sp)
    80001de4:	e04a                	sd	s2,0(sp)
    80001de6:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001de8:	00011497          	auipc	s1,0x11
    80001dec:	ed048493          	addi	s1,s1,-304 # 80012cb8 <proc>
    80001df0:	00018917          	auipc	s2,0x18
    80001df4:	0c890913          	addi	s2,s2,200 # 80019eb8 <tickslock>
    acquire(&p->lock);
    80001df8:	8526                	mv	a0,s1
    80001dfa:	fffff097          	auipc	ra,0xfffff
    80001dfe:	df0080e7          	jalr	-528(ra) # 80000bea <acquire>
    if(p->state == UNUSED) {
    80001e02:	4c9c                	lw	a5,24(s1)
    80001e04:	cf81                	beqz	a5,80001e1c <allocproc+0x40>
      release(&p->lock);
    80001e06:	8526                	mv	a0,s1
    80001e08:	fffff097          	auipc	ra,0xfffff
    80001e0c:	e96080e7          	jalr	-362(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e10:	1c848493          	addi	s1,s1,456
    80001e14:	ff2492e3          	bne	s1,s2,80001df8 <allocproc+0x1c>
  return 0;
    80001e18:	4481                	li	s1,0
    80001e1a:	a065                	j	80001ec2 <allocproc+0xe6>
  p->pid = allocpid();
    80001e1c:	00000097          	auipc	ra,0x0
    80001e20:	e28080e7          	jalr	-472(ra) # 80001c44 <allocpid>
    80001e24:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001e26:	4705                	li	a4,1
    80001e28:	cc98                	sw	a4,24(s1)
  p->tick_creation_time = ticks;
    80001e2a:	00008797          	auipc	a5,0x8
    80001e2e:	d767a783          	lw	a5,-650(a5) # 80009ba0 <ticks>
    80001e32:	18f4a823          	sw	a5,400(s1)
  p->tickets = 1;
    80001e36:	18e4aa23          	sw	a4,404(s1)
  p->priority_pbs = 60;
    80001e3a:	03c00713          	li	a4,60
    80001e3e:	1ae4a023          	sw	a4,416(s1)
  p->niceness_var = 5;
    80001e42:	4715                	li	a4,5
    80001e44:	1ae4a223          	sw	a4,420(s1)
  p->start_time_pbs = ticks;
    80001e48:	18f4ac23          	sw	a5,408(s1)
  p->number_times = 0;
    80001e4c:	1804ae23          	sw	zero,412(s1)
  p->last_run_time = 0;
    80001e50:	1a04a623          	sw	zero,428(s1)
  p->last_sleep_time = 0;
    80001e54:	1a04a423          	sw	zero,424(s1)
  p->priority = 0;
    80001e58:	1a04aa23          	sw	zero,436(s1)
  p->in_queue = 0;
    80001e5c:	1a04ac23          	sw	zero,440(s1)
  p->curr_rtime = 0;
    80001e60:	1a04ae23          	sw	zero,444(s1)
  p->curr_wtime = 0;
    80001e64:	1c04a023          	sw	zero,448(s1)
  p->itime = 0;
    80001e68:	1c04a223          	sw	zero,452(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001e6c:	fffff097          	auipc	ra,0xfffff
    80001e70:	c8e080e7          	jalr	-882(ra) # 80000afa <kalloc>
    80001e74:	892a                	mv	s2,a0
    80001e76:	eca8                	sd	a0,88(s1)
    80001e78:	cd21                	beqz	a0,80001ed0 <allocproc+0xf4>
  p->pagetable = proc_pagetable(p);
    80001e7a:	8526                	mv	a0,s1
    80001e7c:	00000097          	auipc	ra,0x0
    80001e80:	e0e080e7          	jalr	-498(ra) # 80001c8a <proc_pagetable>
    80001e84:	892a                	mv	s2,a0
    80001e86:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001e88:	c125                	beqz	a0,80001ee8 <allocproc+0x10c>
  memset(&p->context, 0, sizeof(p->context));
    80001e8a:	07000613          	li	a2,112
    80001e8e:	4581                	li	a1,0
    80001e90:	06048513          	addi	a0,s1,96
    80001e94:	fffff097          	auipc	ra,0xfffff
    80001e98:	e52080e7          	jalr	-430(ra) # 80000ce6 <memset>
  p->context.ra = (uint64)forkret;
    80001e9c:	00000797          	auipc	a5,0x0
    80001ea0:	d6278793          	addi	a5,a5,-670 # 80001bfe <forkret>
    80001ea4:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001ea6:	60bc                	ld	a5,64(s1)
    80001ea8:	6705                	lui	a4,0x1
    80001eaa:	97ba                	add	a5,a5,a4
    80001eac:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001eae:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001eb2:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001eb6:	00008797          	auipc	a5,0x8
    80001eba:	cea7a783          	lw	a5,-790(a5) # 80009ba0 <ticks>
    80001ebe:	16f4a623          	sw	a5,364(s1)
}
    80001ec2:	8526                	mv	a0,s1
    80001ec4:	60e2                	ld	ra,24(sp)
    80001ec6:	6442                	ld	s0,16(sp)
    80001ec8:	64a2                	ld	s1,8(sp)
    80001eca:	6902                	ld	s2,0(sp)
    80001ecc:	6105                	addi	sp,sp,32
    80001ece:	8082                	ret
    freeproc(p);
    80001ed0:	8526                	mv	a0,s1
    80001ed2:	00000097          	auipc	ra,0x0
    80001ed6:	ea6080e7          	jalr	-346(ra) # 80001d78 <freeproc>
    release(&p->lock);
    80001eda:	8526                	mv	a0,s1
    80001edc:	fffff097          	auipc	ra,0xfffff
    80001ee0:	dc2080e7          	jalr	-574(ra) # 80000c9e <release>
    return 0;
    80001ee4:	84ca                	mv	s1,s2
    80001ee6:	bff1                	j	80001ec2 <allocproc+0xe6>
    freeproc(p);
    80001ee8:	8526                	mv	a0,s1
    80001eea:	00000097          	auipc	ra,0x0
    80001eee:	e8e080e7          	jalr	-370(ra) # 80001d78 <freeproc>
    release(&p->lock);
    80001ef2:	8526                	mv	a0,s1
    80001ef4:	fffff097          	auipc	ra,0xfffff
    80001ef8:	daa080e7          	jalr	-598(ra) # 80000c9e <release>
    return 0;
    80001efc:	84ca                	mv	s1,s2
    80001efe:	b7d1                	j	80001ec2 <allocproc+0xe6>

0000000080001f00 <userinit>:
{
    80001f00:	1101                	addi	sp,sp,-32
    80001f02:	ec06                	sd	ra,24(sp)
    80001f04:	e822                	sd	s0,16(sp)
    80001f06:	e426                	sd	s1,8(sp)
    80001f08:	1000                	addi	s0,sp,32
  p = allocproc();
    80001f0a:	00000097          	auipc	ra,0x0
    80001f0e:	ed2080e7          	jalr	-302(ra) # 80001ddc <allocproc>
    80001f12:	84aa                	mv	s1,a0
  initproc = p;
    80001f14:	00008797          	auipc	a5,0x8
    80001f18:	c8a7b223          	sd	a0,-892(a5) # 80009b98 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001f1c:	03400613          	li	a2,52
    80001f20:	00008597          	auipc	a1,0x8
    80001f24:	b0058593          	addi	a1,a1,-1280 # 80009a20 <initcode>
    80001f28:	6928                	ld	a0,80(a0)
    80001f2a:	fffff097          	auipc	ra,0xfffff
    80001f2e:	448080e7          	jalr	1096(ra) # 80001372 <uvmfirst>
  p->sz = PGSIZE;
    80001f32:	6785                	lui	a5,0x1
    80001f34:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001f36:	6cb8                	ld	a4,88(s1)
    80001f38:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001f3c:	6cb8                	ld	a4,88(s1)
    80001f3e:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f40:	4641                	li	a2,16
    80001f42:	00007597          	auipc	a1,0x7
    80001f46:	2de58593          	addi	a1,a1,734 # 80009220 <digits+0x1e0>
    80001f4a:	15848513          	addi	a0,s1,344
    80001f4e:	fffff097          	auipc	ra,0xfffff
    80001f52:	eea080e7          	jalr	-278(ra) # 80000e38 <safestrcpy>
  p->cwd = namei("/");
    80001f56:	00007517          	auipc	a0,0x7
    80001f5a:	2da50513          	addi	a0,a0,730 # 80009230 <digits+0x1f0>
    80001f5e:	00003097          	auipc	ra,0x3
    80001f62:	b94080e7          	jalr	-1132(ra) # 80004af2 <namei>
    80001f66:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001f6a:	478d                	li	a5,3
    80001f6c:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001f6e:	8526                	mv	a0,s1
    80001f70:	fffff097          	auipc	ra,0xfffff
    80001f74:	d2e080e7          	jalr	-722(ra) # 80000c9e <release>
}
    80001f78:	60e2                	ld	ra,24(sp)
    80001f7a:	6442                	ld	s0,16(sp)
    80001f7c:	64a2                	ld	s1,8(sp)
    80001f7e:	6105                	addi	sp,sp,32
    80001f80:	8082                	ret

0000000080001f82 <growproc>:
{
    80001f82:	1101                	addi	sp,sp,-32
    80001f84:	ec06                	sd	ra,24(sp)
    80001f86:	e822                	sd	s0,16(sp)
    80001f88:	e426                	sd	s1,8(sp)
    80001f8a:	e04a                	sd	s2,0(sp)
    80001f8c:	1000                	addi	s0,sp,32
    80001f8e:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001f90:	00000097          	auipc	ra,0x0
    80001f94:	c36080e7          	jalr	-970(ra) # 80001bc6 <myproc>
    80001f98:	84aa                	mv	s1,a0
  sz = p->sz;
    80001f9a:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001f9c:	01204c63          	bgtz	s2,80001fb4 <growproc+0x32>
  } else if(n < 0){
    80001fa0:	02094663          	bltz	s2,80001fcc <growproc+0x4a>
  p->sz = sz;
    80001fa4:	e4ac                	sd	a1,72(s1)
  return 0;
    80001fa6:	4501                	li	a0,0
}
    80001fa8:	60e2                	ld	ra,24(sp)
    80001faa:	6442                	ld	s0,16(sp)
    80001fac:	64a2                	ld	s1,8(sp)
    80001fae:	6902                	ld	s2,0(sp)
    80001fb0:	6105                	addi	sp,sp,32
    80001fb2:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001fb4:	4691                	li	a3,4
    80001fb6:	00b90633          	add	a2,s2,a1
    80001fba:	6928                	ld	a0,80(a0)
    80001fbc:	fffff097          	auipc	ra,0xfffff
    80001fc0:	470080e7          	jalr	1136(ra) # 8000142c <uvmalloc>
    80001fc4:	85aa                	mv	a1,a0
    80001fc6:	fd79                	bnez	a0,80001fa4 <growproc+0x22>
      return -1;
    80001fc8:	557d                	li	a0,-1
    80001fca:	bff9                	j	80001fa8 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001fcc:	00b90633          	add	a2,s2,a1
    80001fd0:	6928                	ld	a0,80(a0)
    80001fd2:	fffff097          	auipc	ra,0xfffff
    80001fd6:	412080e7          	jalr	1042(ra) # 800013e4 <uvmdealloc>
    80001fda:	85aa                	mv	a1,a0
    80001fdc:	b7e1                	j	80001fa4 <growproc+0x22>

0000000080001fde <fork>:
{
    80001fde:	7179                	addi	sp,sp,-48
    80001fe0:	f406                	sd	ra,40(sp)
    80001fe2:	f022                	sd	s0,32(sp)
    80001fe4:	ec26                	sd	s1,24(sp)
    80001fe6:	e84a                	sd	s2,16(sp)
    80001fe8:	e44e                	sd	s3,8(sp)
    80001fea:	e052                	sd	s4,0(sp)
    80001fec:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fee:	00000097          	auipc	ra,0x0
    80001ff2:	bd8080e7          	jalr	-1064(ra) # 80001bc6 <myproc>
    80001ff6:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001ff8:	00000097          	auipc	ra,0x0
    80001ffc:	de4080e7          	jalr	-540(ra) # 80001ddc <allocproc>
    80002000:	10050f63          	beqz	a0,8000211e <fork+0x140>
    80002004:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002006:	04893603          	ld	a2,72(s2)
    8000200a:	692c                	ld	a1,80(a0)
    8000200c:	05093503          	ld	a0,80(s2)
    80002010:	fffff097          	auipc	ra,0xfffff
    80002014:	570080e7          	jalr	1392(ra) # 80001580 <uvmcopy>
    80002018:	04054a63          	bltz	a0,8000206c <fork+0x8e>
  np->sz = p->sz;
    8000201c:	04893783          	ld	a5,72(s2)
    80002020:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80002024:	05893683          	ld	a3,88(s2)
    80002028:	87b6                	mv	a5,a3
    8000202a:	0589b703          	ld	a4,88(s3)
    8000202e:	12068693          	addi	a3,a3,288
    80002032:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002036:	6788                	ld	a0,8(a5)
    80002038:	6b8c                	ld	a1,16(a5)
    8000203a:	6f90                	ld	a2,24(a5)
    8000203c:	01073023          	sd	a6,0(a4)
    80002040:	e708                	sd	a0,8(a4)
    80002042:	eb0c                	sd	a1,16(a4)
    80002044:	ef10                	sd	a2,24(a4)
    80002046:	02078793          	addi	a5,a5,32
    8000204a:	02070713          	addi	a4,a4,32
    8000204e:	fed792e3          	bne	a5,a3,80002032 <fork+0x54>
  np->trace_flag = p->trace_flag;
    80002052:	17492783          	lw	a5,372(s2)
    80002056:	16f9aa23          	sw	a5,372(s3)
  np->trapframe->a0 = 0;
    8000205a:	0589b783          	ld	a5,88(s3)
    8000205e:	0607b823          	sd	zero,112(a5)
    80002062:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80002066:	15000a13          	li	s4,336
    8000206a:	a03d                	j	80002098 <fork+0xba>
    freeproc(np);
    8000206c:	854e                	mv	a0,s3
    8000206e:	00000097          	auipc	ra,0x0
    80002072:	d0a080e7          	jalr	-758(ra) # 80001d78 <freeproc>
    release(&np->lock);
    80002076:	854e                	mv	a0,s3
    80002078:	fffff097          	auipc	ra,0xfffff
    8000207c:	c26080e7          	jalr	-986(ra) # 80000c9e <release>
    return -1;
    80002080:	5a7d                	li	s4,-1
    80002082:	a069                	j	8000210c <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    80002084:	00003097          	auipc	ra,0x3
    80002088:	104080e7          	jalr	260(ra) # 80005188 <filedup>
    8000208c:	009987b3          	add	a5,s3,s1
    80002090:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002092:	04a1                	addi	s1,s1,8
    80002094:	01448763          	beq	s1,s4,800020a2 <fork+0xc4>
    if(p->ofile[i])
    80002098:	009907b3          	add	a5,s2,s1
    8000209c:	6388                	ld	a0,0(a5)
    8000209e:	f17d                	bnez	a0,80002084 <fork+0xa6>
    800020a0:	bfcd                	j	80002092 <fork+0xb4>
  np->cwd = idup(p->cwd);
    800020a2:	15093503          	ld	a0,336(s2)
    800020a6:	00002097          	auipc	ra,0x2
    800020aa:	268080e7          	jalr	616(ra) # 8000430e <idup>
    800020ae:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800020b2:	4641                	li	a2,16
    800020b4:	15890593          	addi	a1,s2,344
    800020b8:	15898513          	addi	a0,s3,344
    800020bc:	fffff097          	auipc	ra,0xfffff
    800020c0:	d7c080e7          	jalr	-644(ra) # 80000e38 <safestrcpy>
  pid = np->pid;
    800020c4:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    800020c8:	854e                	mv	a0,s3
    800020ca:	fffff097          	auipc	ra,0xfffff
    800020ce:	bd4080e7          	jalr	-1068(ra) # 80000c9e <release>
  acquire(&wait_lock);
    800020d2:	00010497          	auipc	s1,0x10
    800020d6:	d5648493          	addi	s1,s1,-682 # 80011e28 <wait_lock>
    800020da:	8526                	mv	a0,s1
    800020dc:	fffff097          	auipc	ra,0xfffff
    800020e0:	b0e080e7          	jalr	-1266(ra) # 80000bea <acquire>
  np->parent = p;
    800020e4:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    800020e8:	8526                	mv	a0,s1
    800020ea:	fffff097          	auipc	ra,0xfffff
    800020ee:	bb4080e7          	jalr	-1100(ra) # 80000c9e <release>
  acquire(&np->lock);
    800020f2:	854e                	mv	a0,s3
    800020f4:	fffff097          	auipc	ra,0xfffff
    800020f8:	af6080e7          	jalr	-1290(ra) # 80000bea <acquire>
  np->state = RUNNABLE;
    800020fc:	478d                	li	a5,3
    800020fe:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80002102:	854e                	mv	a0,s3
    80002104:	fffff097          	auipc	ra,0xfffff
    80002108:	b9a080e7          	jalr	-1126(ra) # 80000c9e <release>
}
    8000210c:	8552                	mv	a0,s4
    8000210e:	70a2                	ld	ra,40(sp)
    80002110:	7402                	ld	s0,32(sp)
    80002112:	64e2                	ld	s1,24(sp)
    80002114:	6942                	ld	s2,16(sp)
    80002116:	69a2                	ld	s3,8(sp)
    80002118:	6a02                	ld	s4,0(sp)
    8000211a:	6145                	addi	sp,sp,48
    8000211c:	8082                	ret
    return -1;
    8000211e:	5a7d                	li	s4,-1
    80002120:	b7f5                	j	8000210c <fork+0x12e>

0000000080002122 <scheduler>:
{
    80002122:	7175                	addi	sp,sp,-144
    80002124:	e506                	sd	ra,136(sp)
    80002126:	e122                	sd	s0,128(sp)
    80002128:	fca6                	sd	s1,120(sp)
    8000212a:	f8ca                	sd	s2,112(sp)
    8000212c:	f4ce                	sd	s3,104(sp)
    8000212e:	f0d2                	sd	s4,96(sp)
    80002130:	ecd6                	sd	s5,88(sp)
    80002132:	e8da                	sd	s6,80(sp)
    80002134:	e4de                	sd	s7,72(sp)
    80002136:	e0e2                	sd	s8,64(sp)
    80002138:	fc66                	sd	s9,56(sp)
    8000213a:	f86a                	sd	s10,48(sp)
    8000213c:	f46e                	sd	s11,40(sp)
    8000213e:	0900                	addi	s0,sp,144
    80002140:	8792                	mv	a5,tp
  int id = r_tp();
    80002142:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002144:	00779693          	slli	a3,a5,0x7
    80002148:	00010717          	auipc	a4,0x10
    8000214c:	cc870713          	addi	a4,a4,-824 # 80011e10 <pid_lock>
    80002150:	9736                	add	a4,a4,a3
    80002152:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &proc_to_run->context);
    80002156:	00010717          	auipc	a4,0x10
    8000215a:	cf270713          	addi	a4,a4,-782 # 80011e48 <cpus+0x8>
    8000215e:	9736                	add	a4,a4,a3
    80002160:	f8e43023          	sd	a4,-128(s0)
      for (p = proc; p < &proc[NPROC]; p++)
    80002164:	00018a97          	auipc	s5,0x18
    80002168:	d54a8a93          	addi	s5,s5,-684 # 80019eb8 <tickslock>
          p = queues[i].procs[queues[i].front];
    8000216c:	00010c17          	auipc	s8,0x10
    80002170:	0d4c0c13          	addi	s8,s8,212 # 80012240 <queues>
        for(int j = 0; j < queues[i].length; j++)
    80002174:	f8043423          	sd	zero,-120(s0)
        c->proc = proc_to_run;
    80002178:	00010717          	auipc	a4,0x10
    8000217c:	c9870713          	addi	a4,a4,-872 # 80011e10 <pid_lock>
    80002180:	00d707b3          	add	a5,a4,a3
    80002184:	f6f43c23          	sd	a5,-136(s0)
    80002188:	a051                	j	8000220c <scheduler+0xea>
          enqueue(p);
    8000218a:	8526                	mv	a0,s1
    8000218c:	fffff097          	auipc	ra,0xfffff
    80002190:	6c4080e7          	jalr	1732(ra) # 80001850 <enqueue>
        release(&p->lock);
    80002194:	8526                	mv	a0,s1
    80002196:	fffff097          	auipc	ra,0xfffff
    8000219a:	b08080e7          	jalr	-1272(ra) # 80000c9e <release>
      for (p = proc; p < &proc[NPROC]; p++)
    8000219e:	1c848493          	addi	s1,s1,456
    800021a2:	01548e63          	beq	s1,s5,800021be <scheduler+0x9c>
        acquire(&p->lock);
    800021a6:	8526                	mv	a0,s1
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	a42080e7          	jalr	-1470(ra) # 80000bea <acquire>
        if (p->state == RUNNABLE && p->in_queue == 0)
    800021b0:	4c9c                	lw	a5,24(s1)
    800021b2:	ff3791e3          	bne	a5,s3,80002194 <scheduler+0x72>
    800021b6:	1b84a783          	lw	a5,440(s1)
    800021ba:	ffe9                	bnez	a5,80002194 <scheduler+0x72>
    800021bc:	b7f9                	j	8000218a <scheduler+0x68>
    800021be:	00010d17          	auipc	s10,0x10
    800021c2:	08ad0d13          	addi	s10,s10,138 # 80012248 <queues+0x8>
      for (int i = 0; i < 5; i++)
    800021c6:	4c81                	li	s9,0
    800021c8:	a0a5                	j	80002230 <scheduler+0x10e>
            p->itime = ticks;
    800021ca:	00008917          	auipc	s2,0x8
    800021ce:	9d690913          	addi	s2,s2,-1578 # 80009ba0 <ticks>
    800021d2:	00092783          	lw	a5,0(s2)
    800021d6:	1cf4a223          	sw	a5,452(s1)
        proc_to_run->state = RUNNING;
    800021da:	4791                	li	a5,4
    800021dc:	cc9c                	sw	a5,24(s1)
        c->proc = proc_to_run;
    800021de:	f7843983          	ld	s3,-136(s0)
    800021e2:	0299b823          	sd	s1,48(s3)
        swtch(&c->context, &proc_to_run->context);
    800021e6:	06048593          	addi	a1,s1,96
    800021ea:	f8043503          	ld	a0,-128(s0)
    800021ee:	00001097          	auipc	ra,0x1
    800021f2:	99c080e7          	jalr	-1636(ra) # 80002b8a <swtch>
        c->proc = 0;
    800021f6:	0209b823          	sd	zero,48(s3)
        proc_to_run->itime = ticks;
    800021fa:	00092783          	lw	a5,0(s2)
    800021fe:	1cf4a223          	sw	a5,452(s1)
        release(&proc_to_run->lock);
    80002202:	8526                	mv	a0,s1
    80002204:	fffff097          	auipc	ra,0xfffff
    80002208:	a9a080e7          	jalr	-1382(ra) # 80000c9e <release>
        if (p->state == RUNNABLE && p->in_queue == 0)
    8000220c:	498d                	li	s3,3
      for (int i = 0; i < 5; i++)
    8000220e:	4d95                	li	s11,5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002210:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002214:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002218:	10079073          	csrw	sstatus,a5
      for (p = proc; p < &proc[NPROC]; p++)
    8000221c:	00011497          	auipc	s1,0x11
    80002220:	a9c48493          	addi	s1,s1,-1380 # 80012cb8 <proc>
    80002224:	b749                	j	800021a6 <scheduler+0x84>
      for (int i = 0; i < 5; i++)
    80002226:	2c85                	addiw	s9,s9,1
    80002228:	218d0d13          	addi	s10,s10,536
    8000222c:	ffbc82e3          	beq	s9,s11,80002210 <scheduler+0xee>
        for(int j = 0; j < queues[i].length; j++)
    80002230:	8a6a                	mv	s4,s10
    80002232:	000d2783          	lw	a5,0(s10)
    80002236:	f8843903          	ld	s2,-120(s0)
    8000223a:	fef056e3          	blez	a5,80002226 <scheduler+0x104>
          p = queues[i].procs[queues[i].front];
    8000223e:	004c9b13          	slli	s6,s9,0x4
    80002242:	9b66                	add	s6,s6,s9
    80002244:	0b0a                	slli	s6,s6,0x2
    80002246:	419b0b33          	sub	s6,s6,s9
    8000224a:	ff8a2783          	lw	a5,-8(s4)
    8000224e:	97da                	add	a5,a5,s6
    80002250:	0789                	addi	a5,a5,2
    80002252:	078e                	slli	a5,a5,0x3
    80002254:	97e2                	add	a5,a5,s8
    80002256:	6384                	ld	s1,0(a5)
          acquire(&p->lock);
    80002258:	8526                	mv	a0,s1
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	990080e7          	jalr	-1648(ra) # 80000bea <acquire>
          dequeue(p);  // clear out all the processes as it goes through all the levels
    80002262:	8526                	mv	a0,s1
    80002264:	fffff097          	auipc	ra,0xfffff
    80002268:	6ac080e7          	jalr	1708(ra) # 80001910 <dequeue>
          p->in_queue = 0;
    8000226c:	1a04ac23          	sw	zero,440(s1)
          if (p->state == RUNNABLE)
    80002270:	4c9c                	lw	a5,24(s1)
    80002272:	f5378ce3          	beq	a5,s3,800021ca <scheduler+0xa8>
          release(&p->lock);
    80002276:	8526                	mv	a0,s1
    80002278:	fffff097          	auipc	ra,0xfffff
    8000227c:	a26080e7          	jalr	-1498(ra) # 80000c9e <release>
        for(int j = 0; j < queues[i].length; j++)
    80002280:	2905                	addiw	s2,s2,1
    80002282:	000a2783          	lw	a5,0(s4)
    80002286:	fcf942e3          	blt	s2,a5,8000224a <scheduler+0x128>
    8000228a:	bf71                	j	80002226 <scheduler+0x104>

000000008000228c <sched>:
{
    8000228c:	7179                	addi	sp,sp,-48
    8000228e:	f406                	sd	ra,40(sp)
    80002290:	f022                	sd	s0,32(sp)
    80002292:	ec26                	sd	s1,24(sp)
    80002294:	e84a                	sd	s2,16(sp)
    80002296:	e44e                	sd	s3,8(sp)
    80002298:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000229a:	00000097          	auipc	ra,0x0
    8000229e:	92c080e7          	jalr	-1748(ra) # 80001bc6 <myproc>
    800022a2:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800022a4:	fffff097          	auipc	ra,0xfffff
    800022a8:	8cc080e7          	jalr	-1844(ra) # 80000b70 <holding>
    800022ac:	c93d                	beqz	a0,80002322 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022ae:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800022b0:	2781                	sext.w	a5,a5
    800022b2:	079e                	slli	a5,a5,0x7
    800022b4:	00010717          	auipc	a4,0x10
    800022b8:	b5c70713          	addi	a4,a4,-1188 # 80011e10 <pid_lock>
    800022bc:	97ba                	add	a5,a5,a4
    800022be:	0a87a703          	lw	a4,168(a5)
    800022c2:	4785                	li	a5,1
    800022c4:	06f71763          	bne	a4,a5,80002332 <sched+0xa6>
  if(p->state == RUNNING)
    800022c8:	4c98                	lw	a4,24(s1)
    800022ca:	4791                	li	a5,4
    800022cc:	06f70b63          	beq	a4,a5,80002342 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022d0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800022d4:	8b89                	andi	a5,a5,2
  if(intr_get())
    800022d6:	efb5                	bnez	a5,80002352 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022d8:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800022da:	00010917          	auipc	s2,0x10
    800022de:	b3690913          	addi	s2,s2,-1226 # 80011e10 <pid_lock>
    800022e2:	2781                	sext.w	a5,a5
    800022e4:	079e                	slli	a5,a5,0x7
    800022e6:	97ca                	add	a5,a5,s2
    800022e8:	0ac7a983          	lw	s3,172(a5)
    800022ec:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800022ee:	2781                	sext.w	a5,a5
    800022f0:	079e                	slli	a5,a5,0x7
    800022f2:	00010597          	auipc	a1,0x10
    800022f6:	b5658593          	addi	a1,a1,-1194 # 80011e48 <cpus+0x8>
    800022fa:	95be                	add	a1,a1,a5
    800022fc:	06048513          	addi	a0,s1,96
    80002300:	00001097          	auipc	ra,0x1
    80002304:	88a080e7          	jalr	-1910(ra) # 80002b8a <swtch>
    80002308:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000230a:	2781                	sext.w	a5,a5
    8000230c:	079e                	slli	a5,a5,0x7
    8000230e:	97ca                	add	a5,a5,s2
    80002310:	0b37a623          	sw	s3,172(a5)
}
    80002314:	70a2                	ld	ra,40(sp)
    80002316:	7402                	ld	s0,32(sp)
    80002318:	64e2                	ld	s1,24(sp)
    8000231a:	6942                	ld	s2,16(sp)
    8000231c:	69a2                	ld	s3,8(sp)
    8000231e:	6145                	addi	sp,sp,48
    80002320:	8082                	ret
    panic("sched p->lock");
    80002322:	00007517          	auipc	a0,0x7
    80002326:	f1650513          	addi	a0,a0,-234 # 80009238 <digits+0x1f8>
    8000232a:	ffffe097          	auipc	ra,0xffffe
    8000232e:	21a080e7          	jalr	538(ra) # 80000544 <panic>
    panic("sched locks");
    80002332:	00007517          	auipc	a0,0x7
    80002336:	f1650513          	addi	a0,a0,-234 # 80009248 <digits+0x208>
    8000233a:	ffffe097          	auipc	ra,0xffffe
    8000233e:	20a080e7          	jalr	522(ra) # 80000544 <panic>
    panic("sched running");
    80002342:	00007517          	auipc	a0,0x7
    80002346:	f1650513          	addi	a0,a0,-234 # 80009258 <digits+0x218>
    8000234a:	ffffe097          	auipc	ra,0xffffe
    8000234e:	1fa080e7          	jalr	506(ra) # 80000544 <panic>
    panic("sched interruptible");
    80002352:	00007517          	auipc	a0,0x7
    80002356:	f1650513          	addi	a0,a0,-234 # 80009268 <digits+0x228>
    8000235a:	ffffe097          	auipc	ra,0xffffe
    8000235e:	1ea080e7          	jalr	490(ra) # 80000544 <panic>

0000000080002362 <yield>:
{
    80002362:	1101                	addi	sp,sp,-32
    80002364:	ec06                	sd	ra,24(sp)
    80002366:	e822                	sd	s0,16(sp)
    80002368:	e426                	sd	s1,8(sp)
    8000236a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000236c:	00000097          	auipc	ra,0x0
    80002370:	85a080e7          	jalr	-1958(ra) # 80001bc6 <myproc>
    80002374:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002376:	fffff097          	auipc	ra,0xfffff
    8000237a:	874080e7          	jalr	-1932(ra) # 80000bea <acquire>
  p->state = RUNNABLE;
    8000237e:	478d                	li	a5,3
    80002380:	cc9c                	sw	a5,24(s1)
  sched();
    80002382:	00000097          	auipc	ra,0x0
    80002386:	f0a080e7          	jalr	-246(ra) # 8000228c <sched>
  release(&p->lock);
    8000238a:	8526                	mv	a0,s1
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	912080e7          	jalr	-1774(ra) # 80000c9e <release>
}
    80002394:	60e2                	ld	ra,24(sp)
    80002396:	6442                	ld	s0,16(sp)
    80002398:	64a2                	ld	s1,8(sp)
    8000239a:	6105                	addi	sp,sp,32
    8000239c:	8082                	ret

000000008000239e <update_time>:
{
    8000239e:	7139                	addi	sp,sp,-64
    800023a0:	fc06                	sd	ra,56(sp)
    800023a2:	f822                	sd	s0,48(sp)
    800023a4:	f426                	sd	s1,40(sp)
    800023a6:	f04a                	sd	s2,32(sp)
    800023a8:	ec4e                	sd	s3,24(sp)
    800023aa:	e852                	sd	s4,16(sp)
    800023ac:	e456                	sd	s5,8(sp)
    800023ae:	e05a                	sd	s6,0(sp)
    800023b0:	0080                	addi	s0,sp,64
  for(p = proc; p < &proc[NPROC]; p++){
    800023b2:	00011497          	auipc	s1,0x11
    800023b6:	90648493          	addi	s1,s1,-1786 # 80012cb8 <proc>
    if(p->state == RUNNING) {
    800023ba:	4991                	li	s3,4
    else if(p->state == RUNNABLE) {
    800023bc:	4a0d                	li	s4,3
    if(ticks - p->itime >= 32 && p->state == RUNNABLE) {
    800023be:	00007b17          	auipc	s6,0x7
    800023c2:	7e2b0b13          	addi	s6,s6,2018 # 80009ba0 <ticks>
    800023c6:	4afd                	li	s5,31
  for(p = proc; p < &proc[NPROC]; p++){
    800023c8:	00018917          	auipc	s2,0x18
    800023cc:	af090913          	addi	s2,s2,-1296 # 80019eb8 <tickslock>
    800023d0:	a025                	j	800023f8 <update_time+0x5a>
      p->curr_rtime++;
    800023d2:	1bc4a783          	lw	a5,444(s1)
    800023d6:	2785                	addiw	a5,a5,1
    800023d8:	1af4ae23          	sw	a5,444(s1)
      p->rtime++;
    800023dc:	1684a783          	lw	a5,360(s1)
    800023e0:	2785                	addiw	a5,a5,1
    800023e2:	16f4a423          	sw	a5,360(s1)
    release(&p->lock);
    800023e6:	8526                	mv	a0,s1
    800023e8:	fffff097          	auipc	ra,0xfffff
    800023ec:	8b6080e7          	jalr	-1866(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023f0:	1c848493          	addi	s1,s1,456
    800023f4:	05248d63          	beq	s1,s2,8000244e <update_time+0xb0>
    acquire(&p->lock);
    800023f8:	8526                	mv	a0,s1
    800023fa:	ffffe097          	auipc	ra,0xffffe
    800023fe:	7f0080e7          	jalr	2032(ra) # 80000bea <acquire>
    if(p->state == RUNNING) {
    80002402:	4c9c                	lw	a5,24(s1)
    80002404:	fd3787e3          	beq	a5,s3,800023d2 <update_time+0x34>
    else if(p->state == RUNNABLE) {
    80002408:	fd479fe3          	bne	a5,s4,800023e6 <update_time+0x48>
      p->curr_wtime++;
    8000240c:	1c04a783          	lw	a5,448(s1)
    80002410:	2785                	addiw	a5,a5,1
    80002412:	1cf4a023          	sw	a5,448(s1)
    if(ticks - p->itime >= 32 && p->state == RUNNABLE) {
    80002416:	000b2703          	lw	a4,0(s6)
    8000241a:	1c44a783          	lw	a5,452(s1)
    8000241e:	40f707bb          	subw	a5,a4,a5
    80002422:	fcfaf2e3          	bgeu	s5,a5,800023e6 <update_time+0x48>
      if(p->in_queue != 0) {
    80002426:	1b84a783          	lw	a5,440(s1)
    8000242a:	eb81                	bnez	a5,8000243a <update_time+0x9c>
      if(p->priority != 0) {
    8000242c:	1b44a783          	lw	a5,436(s1)
    80002430:	dbdd                	beqz	a5,800023e6 <update_time+0x48>
        p->priority--;
    80002432:	37fd                	addiw	a5,a5,-1
    80002434:	1af4aa23          	sw	a5,436(s1)
    80002438:	b77d                	j	800023e6 <update_time+0x48>
        p->itime = ticks;
    8000243a:	1ce4a223          	sw	a4,452(s1)
        delqueue(p);
    8000243e:	8526                	mv	a0,s1
    80002440:	fffff097          	auipc	ra,0xfffff
    80002444:	56c080e7          	jalr	1388(ra) # 800019ac <delqueue>
        p->in_queue = 0;
    80002448:	1a04ac23          	sw	zero,440(s1)
    8000244c:	b7c5                	j	8000242c <update_time+0x8e>
}
    8000244e:	70e2                	ld	ra,56(sp)
    80002450:	7442                	ld	s0,48(sp)
    80002452:	74a2                	ld	s1,40(sp)
    80002454:	7902                	ld	s2,32(sp)
    80002456:	69e2                	ld	s3,24(sp)
    80002458:	6a42                	ld	s4,16(sp)
    8000245a:	6aa2                	ld	s5,8(sp)
    8000245c:	6b02                	ld	s6,0(sp)
    8000245e:	6121                	addi	sp,sp,64
    80002460:	8082                	ret

0000000080002462 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002462:	7179                	addi	sp,sp,-48
    80002464:	f406                	sd	ra,40(sp)
    80002466:	f022                	sd	s0,32(sp)
    80002468:	ec26                	sd	s1,24(sp)
    8000246a:	e84a                	sd	s2,16(sp)
    8000246c:	e44e                	sd	s3,8(sp)
    8000246e:	1800                	addi	s0,sp,48
    80002470:	89aa                	mv	s3,a0
    80002472:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002474:	fffff097          	auipc	ra,0xfffff
    80002478:	752080e7          	jalr	1874(ra) # 80001bc6 <myproc>
    8000247c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000247e:	ffffe097          	auipc	ra,0xffffe
    80002482:	76c080e7          	jalr	1900(ra) # 80000bea <acquire>
  release(lk);
    80002486:	854a                	mv	a0,s2
    80002488:	fffff097          	auipc	ra,0xfffff
    8000248c:	816080e7          	jalr	-2026(ra) # 80000c9e <release>

  // Go to sleep.
  p->chan = chan;
    80002490:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002494:	4789                	li	a5,2
    80002496:	cc9c                	sw	a5,24(s1)

  sched();
    80002498:	00000097          	auipc	ra,0x0
    8000249c:	df4080e7          	jalr	-524(ra) # 8000228c <sched>

  // Tidy up.
  p->chan = 0;
    800024a0:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800024a4:	8526                	mv	a0,s1
    800024a6:	ffffe097          	auipc	ra,0xffffe
    800024aa:	7f8080e7          	jalr	2040(ra) # 80000c9e <release>
  acquire(lk);
    800024ae:	854a                	mv	a0,s2
    800024b0:	ffffe097          	auipc	ra,0xffffe
    800024b4:	73a080e7          	jalr	1850(ra) # 80000bea <acquire>
}
    800024b8:	70a2                	ld	ra,40(sp)
    800024ba:	7402                	ld	s0,32(sp)
    800024bc:	64e2                	ld	s1,24(sp)
    800024be:	6942                	ld	s2,16(sp)
    800024c0:	69a2                	ld	s3,8(sp)
    800024c2:	6145                	addi	sp,sp,48
    800024c4:	8082                	ret

00000000800024c6 <waitx>:
{
    800024c6:	711d                	addi	sp,sp,-96
    800024c8:	ec86                	sd	ra,88(sp)
    800024ca:	e8a2                	sd	s0,80(sp)
    800024cc:	e4a6                	sd	s1,72(sp)
    800024ce:	e0ca                	sd	s2,64(sp)
    800024d0:	fc4e                	sd	s3,56(sp)
    800024d2:	f852                	sd	s4,48(sp)
    800024d4:	f456                	sd	s5,40(sp)
    800024d6:	f05a                	sd	s6,32(sp)
    800024d8:	ec5e                	sd	s7,24(sp)
    800024da:	e862                	sd	s8,16(sp)
    800024dc:	e466                	sd	s9,8(sp)
    800024de:	e06a                	sd	s10,0(sp)
    800024e0:	1080                	addi	s0,sp,96
    800024e2:	8b2a                	mv	s6,a0
    800024e4:	8bae                	mv	s7,a1
    800024e6:	8c32                	mv	s8,a2
  struct proc *p = myproc();
    800024e8:	fffff097          	auipc	ra,0xfffff
    800024ec:	6de080e7          	jalr	1758(ra) # 80001bc6 <myproc>
    800024f0:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800024f2:	00010517          	auipc	a0,0x10
    800024f6:	93650513          	addi	a0,a0,-1738 # 80011e28 <wait_lock>
    800024fa:	ffffe097          	auipc	ra,0xffffe
    800024fe:	6f0080e7          	jalr	1776(ra) # 80000bea <acquire>
    havekids = 0;
    80002502:	4c81                	li	s9,0
        if(np->state == ZOMBIE){
    80002504:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002506:	00018997          	auipc	s3,0x18
    8000250a:	9b298993          	addi	s3,s3,-1614 # 80019eb8 <tickslock>
        havekids = 1;
    8000250e:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002510:	00010d17          	auipc	s10,0x10
    80002514:	918d0d13          	addi	s10,s10,-1768 # 80011e28 <wait_lock>
    havekids = 0;
    80002518:	8766                	mv	a4,s9
    for(np = proc; np < &proc[NPROC]; np++){
    8000251a:	00010497          	auipc	s1,0x10
    8000251e:	79e48493          	addi	s1,s1,1950 # 80012cb8 <proc>
    80002522:	a059                	j	800025a8 <waitx+0xe2>
          pid = np->pid;
    80002524:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002528:	1684a703          	lw	a4,360(s1)
    8000252c:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002530:	16c4a783          	lw	a5,364(s1)
    80002534:	9f3d                	addw	a4,a4,a5
    80002536:	1704a783          	lw	a5,368(s1)
    8000253a:	9f99                	subw	a5,a5,a4
    8000253c:	00fba023          	sw	a5,0(s7) # fffffffffffff000 <end+0xffffffff7ffd89e8>
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002540:	000b0e63          	beqz	s6,8000255c <waitx+0x96>
    80002544:	4691                	li	a3,4
    80002546:	02c48613          	addi	a2,s1,44
    8000254a:	85da                	mv	a1,s6
    8000254c:	05093503          	ld	a0,80(s2)
    80002550:	fffff097          	auipc	ra,0xfffff
    80002554:	134080e7          	jalr	308(ra) # 80001684 <copyout>
    80002558:	02054563          	bltz	a0,80002582 <waitx+0xbc>
          freeproc(np);
    8000255c:	8526                	mv	a0,s1
    8000255e:	00000097          	auipc	ra,0x0
    80002562:	81a080e7          	jalr	-2022(ra) # 80001d78 <freeproc>
          release(&np->lock);
    80002566:	8526                	mv	a0,s1
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	736080e7          	jalr	1846(ra) # 80000c9e <release>
          release(&wait_lock);
    80002570:	00010517          	auipc	a0,0x10
    80002574:	8b850513          	addi	a0,a0,-1864 # 80011e28 <wait_lock>
    80002578:	ffffe097          	auipc	ra,0xffffe
    8000257c:	726080e7          	jalr	1830(ra) # 80000c9e <release>
          return pid;
    80002580:	a09d                	j	800025e6 <waitx+0x120>
            release(&np->lock);
    80002582:	8526                	mv	a0,s1
    80002584:	ffffe097          	auipc	ra,0xffffe
    80002588:	71a080e7          	jalr	1818(ra) # 80000c9e <release>
            release(&wait_lock);
    8000258c:	00010517          	auipc	a0,0x10
    80002590:	89c50513          	addi	a0,a0,-1892 # 80011e28 <wait_lock>
    80002594:	ffffe097          	auipc	ra,0xffffe
    80002598:	70a080e7          	jalr	1802(ra) # 80000c9e <release>
            return -1;
    8000259c:	59fd                	li	s3,-1
    8000259e:	a0a1                	j	800025e6 <waitx+0x120>
    for(np = proc; np < &proc[NPROC]; np++){
    800025a0:	1c848493          	addi	s1,s1,456
    800025a4:	03348463          	beq	s1,s3,800025cc <waitx+0x106>
      if(np->parent == p){
    800025a8:	7c9c                	ld	a5,56(s1)
    800025aa:	ff279be3          	bne	a5,s2,800025a0 <waitx+0xda>
        acquire(&np->lock);
    800025ae:	8526                	mv	a0,s1
    800025b0:	ffffe097          	auipc	ra,0xffffe
    800025b4:	63a080e7          	jalr	1594(ra) # 80000bea <acquire>
        if(np->state == ZOMBIE){
    800025b8:	4c9c                	lw	a5,24(s1)
    800025ba:	f74785e3          	beq	a5,s4,80002524 <waitx+0x5e>
        release(&np->lock);
    800025be:	8526                	mv	a0,s1
    800025c0:	ffffe097          	auipc	ra,0xffffe
    800025c4:	6de080e7          	jalr	1758(ra) # 80000c9e <release>
        havekids = 1;
    800025c8:	8756                	mv	a4,s5
    800025ca:	bfd9                	j	800025a0 <waitx+0xda>
    if(!havekids || p->killed){
    800025cc:	c701                	beqz	a4,800025d4 <waitx+0x10e>
    800025ce:	02892783          	lw	a5,40(s2)
    800025d2:	cb8d                	beqz	a5,80002604 <waitx+0x13e>
      release(&wait_lock);
    800025d4:	00010517          	auipc	a0,0x10
    800025d8:	85450513          	addi	a0,a0,-1964 # 80011e28 <wait_lock>
    800025dc:	ffffe097          	auipc	ra,0xffffe
    800025e0:	6c2080e7          	jalr	1730(ra) # 80000c9e <release>
      return -1;
    800025e4:	59fd                	li	s3,-1
}
    800025e6:	854e                	mv	a0,s3
    800025e8:	60e6                	ld	ra,88(sp)
    800025ea:	6446                	ld	s0,80(sp)
    800025ec:	64a6                	ld	s1,72(sp)
    800025ee:	6906                	ld	s2,64(sp)
    800025f0:	79e2                	ld	s3,56(sp)
    800025f2:	7a42                	ld	s4,48(sp)
    800025f4:	7aa2                	ld	s5,40(sp)
    800025f6:	7b02                	ld	s6,32(sp)
    800025f8:	6be2                	ld	s7,24(sp)
    800025fa:	6c42                	ld	s8,16(sp)
    800025fc:	6ca2                	ld	s9,8(sp)
    800025fe:	6d02                	ld	s10,0(sp)
    80002600:	6125                	addi	sp,sp,96
    80002602:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002604:	85ea                	mv	a1,s10
    80002606:	854a                	mv	a0,s2
    80002608:	00000097          	auipc	ra,0x0
    8000260c:	e5a080e7          	jalr	-422(ra) # 80002462 <sleep>
    havekids = 0;
    80002610:	b721                	j	80002518 <waitx+0x52>

0000000080002612 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002612:	7139                	addi	sp,sp,-64
    80002614:	fc06                	sd	ra,56(sp)
    80002616:	f822                	sd	s0,48(sp)
    80002618:	f426                	sd	s1,40(sp)
    8000261a:	f04a                	sd	s2,32(sp)
    8000261c:	ec4e                	sd	s3,24(sp)
    8000261e:	e852                	sd	s4,16(sp)
    80002620:	e456                	sd	s5,8(sp)
    80002622:	0080                	addi	s0,sp,64
    80002624:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002626:	00010497          	auipc	s1,0x10
    8000262a:	69248493          	addi	s1,s1,1682 # 80012cb8 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000262e:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002630:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002632:	00018917          	auipc	s2,0x18
    80002636:	88690913          	addi	s2,s2,-1914 # 80019eb8 <tickslock>
    8000263a:	a821                	j	80002652 <wakeup+0x40>
        p->state = RUNNABLE;
    8000263c:	0154ac23          	sw	s5,24(s1)
        // #ifdef MLFQ
		    //   enqueue(p);
	      // #endif
      }
      release(&p->lock);
    80002640:	8526                	mv	a0,s1
    80002642:	ffffe097          	auipc	ra,0xffffe
    80002646:	65c080e7          	jalr	1628(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000264a:	1c848493          	addi	s1,s1,456
    8000264e:	03248463          	beq	s1,s2,80002676 <wakeup+0x64>
    if(p != myproc()){
    80002652:	fffff097          	auipc	ra,0xfffff
    80002656:	574080e7          	jalr	1396(ra) # 80001bc6 <myproc>
    8000265a:	fea488e3          	beq	s1,a0,8000264a <wakeup+0x38>
      acquire(&p->lock);
    8000265e:	8526                	mv	a0,s1
    80002660:	ffffe097          	auipc	ra,0xffffe
    80002664:	58a080e7          	jalr	1418(ra) # 80000bea <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002668:	4c9c                	lw	a5,24(s1)
    8000266a:	fd379be3          	bne	a5,s3,80002640 <wakeup+0x2e>
    8000266e:	709c                	ld	a5,32(s1)
    80002670:	fd4798e3          	bne	a5,s4,80002640 <wakeup+0x2e>
    80002674:	b7e1                	j	8000263c <wakeup+0x2a>
    }
  }
}
    80002676:	70e2                	ld	ra,56(sp)
    80002678:	7442                	ld	s0,48(sp)
    8000267a:	74a2                	ld	s1,40(sp)
    8000267c:	7902                	ld	s2,32(sp)
    8000267e:	69e2                	ld	s3,24(sp)
    80002680:	6a42                	ld	s4,16(sp)
    80002682:	6aa2                	ld	s5,8(sp)
    80002684:	6121                	addi	sp,sp,64
    80002686:	8082                	ret

0000000080002688 <reparent>:
{
    80002688:	7179                	addi	sp,sp,-48
    8000268a:	f406                	sd	ra,40(sp)
    8000268c:	f022                	sd	s0,32(sp)
    8000268e:	ec26                	sd	s1,24(sp)
    80002690:	e84a                	sd	s2,16(sp)
    80002692:	e44e                	sd	s3,8(sp)
    80002694:	e052                	sd	s4,0(sp)
    80002696:	1800                	addi	s0,sp,48
    80002698:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000269a:	00010497          	auipc	s1,0x10
    8000269e:	61e48493          	addi	s1,s1,1566 # 80012cb8 <proc>
      pp->parent = initproc;
    800026a2:	00007a17          	auipc	s4,0x7
    800026a6:	4f6a0a13          	addi	s4,s4,1270 # 80009b98 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800026aa:	00018997          	auipc	s3,0x18
    800026ae:	80e98993          	addi	s3,s3,-2034 # 80019eb8 <tickslock>
    800026b2:	a029                	j	800026bc <reparent+0x34>
    800026b4:	1c848493          	addi	s1,s1,456
    800026b8:	01348d63          	beq	s1,s3,800026d2 <reparent+0x4a>
    if(pp->parent == p){
    800026bc:	7c9c                	ld	a5,56(s1)
    800026be:	ff279be3          	bne	a5,s2,800026b4 <reparent+0x2c>
      pp->parent = initproc;
    800026c2:	000a3503          	ld	a0,0(s4)
    800026c6:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800026c8:	00000097          	auipc	ra,0x0
    800026cc:	f4a080e7          	jalr	-182(ra) # 80002612 <wakeup>
    800026d0:	b7d5                	j	800026b4 <reparent+0x2c>
}
    800026d2:	70a2                	ld	ra,40(sp)
    800026d4:	7402                	ld	s0,32(sp)
    800026d6:	64e2                	ld	s1,24(sp)
    800026d8:	6942                	ld	s2,16(sp)
    800026da:	69a2                	ld	s3,8(sp)
    800026dc:	6a02                	ld	s4,0(sp)
    800026de:	6145                	addi	sp,sp,48
    800026e0:	8082                	ret

00000000800026e2 <exit>:
{
    800026e2:	7179                	addi	sp,sp,-48
    800026e4:	f406                	sd	ra,40(sp)
    800026e6:	f022                	sd	s0,32(sp)
    800026e8:	ec26                	sd	s1,24(sp)
    800026ea:	e84a                	sd	s2,16(sp)
    800026ec:	e44e                	sd	s3,8(sp)
    800026ee:	e052                	sd	s4,0(sp)
    800026f0:	1800                	addi	s0,sp,48
    800026f2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800026f4:	fffff097          	auipc	ra,0xfffff
    800026f8:	4d2080e7          	jalr	1234(ra) # 80001bc6 <myproc>
    800026fc:	89aa                	mv	s3,a0
  if(p == initproc)
    800026fe:	00007797          	auipc	a5,0x7
    80002702:	49a7b783          	ld	a5,1178(a5) # 80009b98 <initproc>
    80002706:	0d050493          	addi	s1,a0,208
    8000270a:	15050913          	addi	s2,a0,336
    8000270e:	02a79363          	bne	a5,a0,80002734 <exit+0x52>
    panic("init exiting");
    80002712:	00007517          	auipc	a0,0x7
    80002716:	b6e50513          	addi	a0,a0,-1170 # 80009280 <digits+0x240>
    8000271a:	ffffe097          	auipc	ra,0xffffe
    8000271e:	e2a080e7          	jalr	-470(ra) # 80000544 <panic>
      fileclose(f);
    80002722:	00003097          	auipc	ra,0x3
    80002726:	ab8080e7          	jalr	-1352(ra) # 800051da <fileclose>
      p->ofile[fd] = 0;
    8000272a:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000272e:	04a1                	addi	s1,s1,8
    80002730:	01248563          	beq	s1,s2,8000273a <exit+0x58>
    if(p->ofile[fd]){
    80002734:	6088                	ld	a0,0(s1)
    80002736:	f575                	bnez	a0,80002722 <exit+0x40>
    80002738:	bfdd                	j	8000272e <exit+0x4c>
  begin_op();
    8000273a:	00002097          	auipc	ra,0x2
    8000273e:	5d4080e7          	jalr	1492(ra) # 80004d0e <begin_op>
  iput(p->cwd);
    80002742:	1509b503          	ld	a0,336(s3)
    80002746:	00002097          	auipc	ra,0x2
    8000274a:	dc0080e7          	jalr	-576(ra) # 80004506 <iput>
  end_op();
    8000274e:	00002097          	auipc	ra,0x2
    80002752:	640080e7          	jalr	1600(ra) # 80004d8e <end_op>
  p->cwd = 0;
    80002756:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000275a:	0000f497          	auipc	s1,0xf
    8000275e:	6ce48493          	addi	s1,s1,1742 # 80011e28 <wait_lock>
    80002762:	8526                	mv	a0,s1
    80002764:	ffffe097          	auipc	ra,0xffffe
    80002768:	486080e7          	jalr	1158(ra) # 80000bea <acquire>
  reparent(p);
    8000276c:	854e                	mv	a0,s3
    8000276e:	00000097          	auipc	ra,0x0
    80002772:	f1a080e7          	jalr	-230(ra) # 80002688 <reparent>
  wakeup(p->parent);
    80002776:	0389b503          	ld	a0,56(s3)
    8000277a:	00000097          	auipc	ra,0x0
    8000277e:	e98080e7          	jalr	-360(ra) # 80002612 <wakeup>
  acquire(&p->lock);
    80002782:	854e                	mv	a0,s3
    80002784:	ffffe097          	auipc	ra,0xffffe
    80002788:	466080e7          	jalr	1126(ra) # 80000bea <acquire>
  p->xstate = status;
    8000278c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002790:	4795                	li	a5,5
    80002792:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002796:	00007797          	auipc	a5,0x7
    8000279a:	40a7a783          	lw	a5,1034(a5) # 80009ba0 <ticks>
    8000279e:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    800027a2:	8526                	mv	a0,s1
    800027a4:	ffffe097          	auipc	ra,0xffffe
    800027a8:	4fa080e7          	jalr	1274(ra) # 80000c9e <release>
  sched();
    800027ac:	00000097          	auipc	ra,0x0
    800027b0:	ae0080e7          	jalr	-1312(ra) # 8000228c <sched>
  panic("zombie exit");
    800027b4:	00007517          	auipc	a0,0x7
    800027b8:	adc50513          	addi	a0,a0,-1316 # 80009290 <digits+0x250>
    800027bc:	ffffe097          	auipc	ra,0xffffe
    800027c0:	d88080e7          	jalr	-632(ra) # 80000544 <panic>

00000000800027c4 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800027c4:	7179                	addi	sp,sp,-48
    800027c6:	f406                	sd	ra,40(sp)
    800027c8:	f022                	sd	s0,32(sp)
    800027ca:	ec26                	sd	s1,24(sp)
    800027cc:	e84a                	sd	s2,16(sp)
    800027ce:	e44e                	sd	s3,8(sp)
    800027d0:	1800                	addi	s0,sp,48
    800027d2:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800027d4:	00010497          	auipc	s1,0x10
    800027d8:	4e448493          	addi	s1,s1,1252 # 80012cb8 <proc>
    800027dc:	00017997          	auipc	s3,0x17
    800027e0:	6dc98993          	addi	s3,s3,1756 # 80019eb8 <tickslock>
    acquire(&p->lock);
    800027e4:	8526                	mv	a0,s1
    800027e6:	ffffe097          	auipc	ra,0xffffe
    800027ea:	404080e7          	jalr	1028(ra) # 80000bea <acquire>
    if(p->pid == pid){
    800027ee:	589c                	lw	a5,48(s1)
    800027f0:	01278d63          	beq	a5,s2,8000280a <kill+0x46>
	      // #endif
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800027f4:	8526                	mv	a0,s1
    800027f6:	ffffe097          	auipc	ra,0xffffe
    800027fa:	4a8080e7          	jalr	1192(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800027fe:	1c848493          	addi	s1,s1,456
    80002802:	ff3491e3          	bne	s1,s3,800027e4 <kill+0x20>
  }
  return -1;
    80002806:	557d                	li	a0,-1
    80002808:	a829                	j	80002822 <kill+0x5e>
      p->killed = 1;
    8000280a:	4785                	li	a5,1
    8000280c:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000280e:	4c98                	lw	a4,24(s1)
    80002810:	4789                	li	a5,2
    80002812:	00f70f63          	beq	a4,a5,80002830 <kill+0x6c>
      release(&p->lock);
    80002816:	8526                	mv	a0,s1
    80002818:	ffffe097          	auipc	ra,0xffffe
    8000281c:	486080e7          	jalr	1158(ra) # 80000c9e <release>
      return 0;
    80002820:	4501                	li	a0,0
}
    80002822:	70a2                	ld	ra,40(sp)
    80002824:	7402                	ld	s0,32(sp)
    80002826:	64e2                	ld	s1,24(sp)
    80002828:	6942                	ld	s2,16(sp)
    8000282a:	69a2                	ld	s3,8(sp)
    8000282c:	6145                	addi	sp,sp,48
    8000282e:	8082                	ret
        p->state = RUNNABLE;
    80002830:	478d                	li	a5,3
    80002832:	cc9c                	sw	a5,24(s1)
    80002834:	b7cd                	j	80002816 <kill+0x52>

0000000080002836 <setkilled>:

void
setkilled(struct proc *p)
{
    80002836:	1101                	addi	sp,sp,-32
    80002838:	ec06                	sd	ra,24(sp)
    8000283a:	e822                	sd	s0,16(sp)
    8000283c:	e426                	sd	s1,8(sp)
    8000283e:	1000                	addi	s0,sp,32
    80002840:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002842:	ffffe097          	auipc	ra,0xffffe
    80002846:	3a8080e7          	jalr	936(ra) # 80000bea <acquire>
  p->killed = 1;
    8000284a:	4785                	li	a5,1
    8000284c:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000284e:	8526                	mv	a0,s1
    80002850:	ffffe097          	auipc	ra,0xffffe
    80002854:	44e080e7          	jalr	1102(ra) # 80000c9e <release>
}
    80002858:	60e2                	ld	ra,24(sp)
    8000285a:	6442                	ld	s0,16(sp)
    8000285c:	64a2                	ld	s1,8(sp)
    8000285e:	6105                	addi	sp,sp,32
    80002860:	8082                	ret

0000000080002862 <killed>:

int
killed(struct proc *p)
{
    80002862:	1101                	addi	sp,sp,-32
    80002864:	ec06                	sd	ra,24(sp)
    80002866:	e822                	sd	s0,16(sp)
    80002868:	e426                	sd	s1,8(sp)
    8000286a:	e04a                	sd	s2,0(sp)
    8000286c:	1000                	addi	s0,sp,32
    8000286e:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002870:	ffffe097          	auipc	ra,0xffffe
    80002874:	37a080e7          	jalr	890(ra) # 80000bea <acquire>
  k = p->killed;
    80002878:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000287c:	8526                	mv	a0,s1
    8000287e:	ffffe097          	auipc	ra,0xffffe
    80002882:	420080e7          	jalr	1056(ra) # 80000c9e <release>
  return k;
}
    80002886:	854a                	mv	a0,s2
    80002888:	60e2                	ld	ra,24(sp)
    8000288a:	6442                	ld	s0,16(sp)
    8000288c:	64a2                	ld	s1,8(sp)
    8000288e:	6902                	ld	s2,0(sp)
    80002890:	6105                	addi	sp,sp,32
    80002892:	8082                	ret

0000000080002894 <wait>:
{
    80002894:	715d                	addi	sp,sp,-80
    80002896:	e486                	sd	ra,72(sp)
    80002898:	e0a2                	sd	s0,64(sp)
    8000289a:	fc26                	sd	s1,56(sp)
    8000289c:	f84a                	sd	s2,48(sp)
    8000289e:	f44e                	sd	s3,40(sp)
    800028a0:	f052                	sd	s4,32(sp)
    800028a2:	ec56                	sd	s5,24(sp)
    800028a4:	e85a                	sd	s6,16(sp)
    800028a6:	e45e                	sd	s7,8(sp)
    800028a8:	e062                	sd	s8,0(sp)
    800028aa:	0880                	addi	s0,sp,80
    800028ac:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800028ae:	fffff097          	auipc	ra,0xfffff
    800028b2:	318080e7          	jalr	792(ra) # 80001bc6 <myproc>
    800028b6:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800028b8:	0000f517          	auipc	a0,0xf
    800028bc:	57050513          	addi	a0,a0,1392 # 80011e28 <wait_lock>
    800028c0:	ffffe097          	auipc	ra,0xffffe
    800028c4:	32a080e7          	jalr	810(ra) # 80000bea <acquire>
    havekids = 0;
    800028c8:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    800028ca:	4a15                	li	s4,5
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800028cc:	00017997          	auipc	s3,0x17
    800028d0:	5ec98993          	addi	s3,s3,1516 # 80019eb8 <tickslock>
        havekids = 1;
    800028d4:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800028d6:	0000fc17          	auipc	s8,0xf
    800028da:	552c0c13          	addi	s8,s8,1362 # 80011e28 <wait_lock>
    havekids = 0;
    800028de:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800028e0:	00010497          	auipc	s1,0x10
    800028e4:	3d848493          	addi	s1,s1,984 # 80012cb8 <proc>
    800028e8:	a0bd                	j	80002956 <wait+0xc2>
          pid = pp->pid;
    800028ea:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800028ee:	000b0e63          	beqz	s6,8000290a <wait+0x76>
    800028f2:	4691                	li	a3,4
    800028f4:	02c48613          	addi	a2,s1,44
    800028f8:	85da                	mv	a1,s6
    800028fa:	05093503          	ld	a0,80(s2)
    800028fe:	fffff097          	auipc	ra,0xfffff
    80002902:	d86080e7          	jalr	-634(ra) # 80001684 <copyout>
    80002906:	02054563          	bltz	a0,80002930 <wait+0x9c>
          freeproc(pp);
    8000290a:	8526                	mv	a0,s1
    8000290c:	fffff097          	auipc	ra,0xfffff
    80002910:	46c080e7          	jalr	1132(ra) # 80001d78 <freeproc>
          release(&pp->lock);
    80002914:	8526                	mv	a0,s1
    80002916:	ffffe097          	auipc	ra,0xffffe
    8000291a:	388080e7          	jalr	904(ra) # 80000c9e <release>
          release(&wait_lock);
    8000291e:	0000f517          	auipc	a0,0xf
    80002922:	50a50513          	addi	a0,a0,1290 # 80011e28 <wait_lock>
    80002926:	ffffe097          	auipc	ra,0xffffe
    8000292a:	378080e7          	jalr	888(ra) # 80000c9e <release>
          return pid;
    8000292e:	a0b5                	j	8000299a <wait+0x106>
            release(&pp->lock);
    80002930:	8526                	mv	a0,s1
    80002932:	ffffe097          	auipc	ra,0xffffe
    80002936:	36c080e7          	jalr	876(ra) # 80000c9e <release>
            release(&wait_lock);
    8000293a:	0000f517          	auipc	a0,0xf
    8000293e:	4ee50513          	addi	a0,a0,1262 # 80011e28 <wait_lock>
    80002942:	ffffe097          	auipc	ra,0xffffe
    80002946:	35c080e7          	jalr	860(ra) # 80000c9e <release>
            return -1;
    8000294a:	59fd                	li	s3,-1
    8000294c:	a0b9                	j	8000299a <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000294e:	1c848493          	addi	s1,s1,456
    80002952:	03348463          	beq	s1,s3,8000297a <wait+0xe6>
      if(pp->parent == p){
    80002956:	7c9c                	ld	a5,56(s1)
    80002958:	ff279be3          	bne	a5,s2,8000294e <wait+0xba>
        acquire(&pp->lock);
    8000295c:	8526                	mv	a0,s1
    8000295e:	ffffe097          	auipc	ra,0xffffe
    80002962:	28c080e7          	jalr	652(ra) # 80000bea <acquire>
        if(pp->state == ZOMBIE){
    80002966:	4c9c                	lw	a5,24(s1)
    80002968:	f94781e3          	beq	a5,s4,800028ea <wait+0x56>
        release(&pp->lock);
    8000296c:	8526                	mv	a0,s1
    8000296e:	ffffe097          	auipc	ra,0xffffe
    80002972:	330080e7          	jalr	816(ra) # 80000c9e <release>
        havekids = 1;
    80002976:	8756                	mv	a4,s5
    80002978:	bfd9                	j	8000294e <wait+0xba>
    if(!havekids || killed(p)){
    8000297a:	c719                	beqz	a4,80002988 <wait+0xf4>
    8000297c:	854a                	mv	a0,s2
    8000297e:	00000097          	auipc	ra,0x0
    80002982:	ee4080e7          	jalr	-284(ra) # 80002862 <killed>
    80002986:	c51d                	beqz	a0,800029b4 <wait+0x120>
      release(&wait_lock);
    80002988:	0000f517          	auipc	a0,0xf
    8000298c:	4a050513          	addi	a0,a0,1184 # 80011e28 <wait_lock>
    80002990:	ffffe097          	auipc	ra,0xffffe
    80002994:	30e080e7          	jalr	782(ra) # 80000c9e <release>
      return -1;
    80002998:	59fd                	li	s3,-1
}
    8000299a:	854e                	mv	a0,s3
    8000299c:	60a6                	ld	ra,72(sp)
    8000299e:	6406                	ld	s0,64(sp)
    800029a0:	74e2                	ld	s1,56(sp)
    800029a2:	7942                	ld	s2,48(sp)
    800029a4:	79a2                	ld	s3,40(sp)
    800029a6:	7a02                	ld	s4,32(sp)
    800029a8:	6ae2                	ld	s5,24(sp)
    800029aa:	6b42                	ld	s6,16(sp)
    800029ac:	6ba2                	ld	s7,8(sp)
    800029ae:	6c02                	ld	s8,0(sp)
    800029b0:	6161                	addi	sp,sp,80
    800029b2:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800029b4:	85e2                	mv	a1,s8
    800029b6:	854a                	mv	a0,s2
    800029b8:	00000097          	auipc	ra,0x0
    800029bc:	aaa080e7          	jalr	-1366(ra) # 80002462 <sleep>
    havekids = 0;
    800029c0:	bf39                	j	800028de <wait+0x4a>

00000000800029c2 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800029c2:	7179                	addi	sp,sp,-48
    800029c4:	f406                	sd	ra,40(sp)
    800029c6:	f022                	sd	s0,32(sp)
    800029c8:	ec26                	sd	s1,24(sp)
    800029ca:	e84a                	sd	s2,16(sp)
    800029cc:	e44e                	sd	s3,8(sp)
    800029ce:	e052                	sd	s4,0(sp)
    800029d0:	1800                	addi	s0,sp,48
    800029d2:	84aa                	mv	s1,a0
    800029d4:	892e                	mv	s2,a1
    800029d6:	89b2                	mv	s3,a2
    800029d8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800029da:	fffff097          	auipc	ra,0xfffff
    800029de:	1ec080e7          	jalr	492(ra) # 80001bc6 <myproc>
  if(user_dst){
    800029e2:	c08d                	beqz	s1,80002a04 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800029e4:	86d2                	mv	a3,s4
    800029e6:	864e                	mv	a2,s3
    800029e8:	85ca                	mv	a1,s2
    800029ea:	6928                	ld	a0,80(a0)
    800029ec:	fffff097          	auipc	ra,0xfffff
    800029f0:	c98080e7          	jalr	-872(ra) # 80001684 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800029f4:	70a2                	ld	ra,40(sp)
    800029f6:	7402                	ld	s0,32(sp)
    800029f8:	64e2                	ld	s1,24(sp)
    800029fa:	6942                	ld	s2,16(sp)
    800029fc:	69a2                	ld	s3,8(sp)
    800029fe:	6a02                	ld	s4,0(sp)
    80002a00:	6145                	addi	sp,sp,48
    80002a02:	8082                	ret
    memmove((char *)dst, src, len);
    80002a04:	000a061b          	sext.w	a2,s4
    80002a08:	85ce                	mv	a1,s3
    80002a0a:	854a                	mv	a0,s2
    80002a0c:	ffffe097          	auipc	ra,0xffffe
    80002a10:	33a080e7          	jalr	826(ra) # 80000d46 <memmove>
    return 0;
    80002a14:	8526                	mv	a0,s1
    80002a16:	bff9                	j	800029f4 <either_copyout+0x32>

0000000080002a18 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002a18:	7179                	addi	sp,sp,-48
    80002a1a:	f406                	sd	ra,40(sp)
    80002a1c:	f022                	sd	s0,32(sp)
    80002a1e:	ec26                	sd	s1,24(sp)
    80002a20:	e84a                	sd	s2,16(sp)
    80002a22:	e44e                	sd	s3,8(sp)
    80002a24:	e052                	sd	s4,0(sp)
    80002a26:	1800                	addi	s0,sp,48
    80002a28:	892a                	mv	s2,a0
    80002a2a:	84ae                	mv	s1,a1
    80002a2c:	89b2                	mv	s3,a2
    80002a2e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a30:	fffff097          	auipc	ra,0xfffff
    80002a34:	196080e7          	jalr	406(ra) # 80001bc6 <myproc>
  if(user_src){
    80002a38:	c08d                	beqz	s1,80002a5a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002a3a:	86d2                	mv	a3,s4
    80002a3c:	864e                	mv	a2,s3
    80002a3e:	85ca                	mv	a1,s2
    80002a40:	6928                	ld	a0,80(a0)
    80002a42:	fffff097          	auipc	ra,0xfffff
    80002a46:	cce080e7          	jalr	-818(ra) # 80001710 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002a4a:	70a2                	ld	ra,40(sp)
    80002a4c:	7402                	ld	s0,32(sp)
    80002a4e:	64e2                	ld	s1,24(sp)
    80002a50:	6942                	ld	s2,16(sp)
    80002a52:	69a2                	ld	s3,8(sp)
    80002a54:	6a02                	ld	s4,0(sp)
    80002a56:	6145                	addi	sp,sp,48
    80002a58:	8082                	ret
    memmove(dst, (char*)src, len);
    80002a5a:	000a061b          	sext.w	a2,s4
    80002a5e:	85ce                	mv	a1,s3
    80002a60:	854a                	mv	a0,s2
    80002a62:	ffffe097          	auipc	ra,0xffffe
    80002a66:	2e4080e7          	jalr	740(ra) # 80000d46 <memmove>
    return 0;
    80002a6a:	8526                	mv	a0,s1
    80002a6c:	bff9                	j	80002a4a <either_copyin+0x32>

0000000080002a6e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002a6e:	715d                	addi	sp,sp,-80
    80002a70:	e486                	sd	ra,72(sp)
    80002a72:	e0a2                	sd	s0,64(sp)
    80002a74:	fc26                	sd	s1,56(sp)
    80002a76:	f84a                	sd	s2,48(sp)
    80002a78:	f44e                	sd	s3,40(sp)
    80002a7a:	f052                	sd	s4,32(sp)
    80002a7c:	ec56                	sd	s5,24(sp)
    80002a7e:	e85a                	sd	s6,16(sp)
    80002a80:	e45e                	sd	s7,8(sp)
    80002a82:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002a84:	00006517          	auipc	a0,0x6
    80002a88:	64450513          	addi	a0,a0,1604 # 800090c8 <digits+0x88>
    80002a8c:	ffffe097          	auipc	ra,0xffffe
    80002a90:	b02080e7          	jalr	-1278(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a94:	00010497          	auipc	s1,0x10
    80002a98:	37c48493          	addi	s1,s1,892 # 80012e10 <proc+0x158>
    80002a9c:	00017917          	auipc	s2,0x17
    80002aa0:	57490913          	addi	s2,s2,1396 # 8001a010 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002aa4:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002aa6:	00006997          	auipc	s3,0x6
    80002aaa:	7fa98993          	addi	s3,s3,2042 # 800092a0 <digits+0x260>
    printf("%d %s %s", p->pid, state, p->name);
    80002aae:	00006a97          	auipc	s5,0x6
    80002ab2:	7faa8a93          	addi	s5,s5,2042 # 800092a8 <digits+0x268>
    printf("\n");
    80002ab6:	00006a17          	auipc	s4,0x6
    80002aba:	612a0a13          	addi	s4,s4,1554 # 800090c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002abe:	00007b97          	auipc	s7,0x7
    80002ac2:	82ab8b93          	addi	s7,s7,-2006 # 800092e8 <states.1811>
    80002ac6:	a00d                	j	80002ae8 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002ac8:	ed86a583          	lw	a1,-296(a3)
    80002acc:	8556                	mv	a0,s5
    80002ace:	ffffe097          	auipc	ra,0xffffe
    80002ad2:	ac0080e7          	jalr	-1344(ra) # 8000058e <printf>
    printf("\n");
    80002ad6:	8552                	mv	a0,s4
    80002ad8:	ffffe097          	auipc	ra,0xffffe
    80002adc:	ab6080e7          	jalr	-1354(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002ae0:	1c848493          	addi	s1,s1,456
    80002ae4:	03248163          	beq	s1,s2,80002b06 <procdump+0x98>
    if(p->state == UNUSED)
    80002ae8:	86a6                	mv	a3,s1
    80002aea:	ec04a783          	lw	a5,-320(s1)
    80002aee:	dbed                	beqz	a5,80002ae0 <procdump+0x72>
      state = "???";
    80002af0:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002af2:	fcfb6be3          	bltu	s6,a5,80002ac8 <procdump+0x5a>
    80002af6:	1782                	slli	a5,a5,0x20
    80002af8:	9381                	srli	a5,a5,0x20
    80002afa:	078e                	slli	a5,a5,0x3
    80002afc:	97de                	add	a5,a5,s7
    80002afe:	6390                	ld	a2,0(a5)
    80002b00:	f661                	bnez	a2,80002ac8 <procdump+0x5a>
      state = "???";
    80002b02:	864e                	mv	a2,s3
    80002b04:	b7d1                	j	80002ac8 <procdump+0x5a>
  }
}
    80002b06:	60a6                	ld	ra,72(sp)
    80002b08:	6406                	ld	s0,64(sp)
    80002b0a:	74e2                	ld	s1,56(sp)
    80002b0c:	7942                	ld	s2,48(sp)
    80002b0e:	79a2                	ld	s3,40(sp)
    80002b10:	7a02                	ld	s4,32(sp)
    80002b12:	6ae2                	ld	s5,24(sp)
    80002b14:	6b42                	ld	s6,16(sp)
    80002b16:	6ba2                	ld	s7,8(sp)
    80002b18:	6161                	addi	sp,sp,80
    80002b1a:	8082                	ret

0000000080002b1c <setpriority>:

int setpriority(int new_priority, int proc_pid)
{
    80002b1c:	7179                	addi	sp,sp,-48
    80002b1e:	f406                	sd	ra,40(sp)
    80002b20:	f022                	sd	s0,32(sp)
    80002b22:	ec26                	sd	s1,24(sp)
    80002b24:	e84a                	sd	s2,16(sp)
    80002b26:	e44e                	sd	s3,8(sp)
    80002b28:	e052                	sd	s4,0(sp)
    80002b2a:	1800                	addi	s0,sp,48
    80002b2c:	8a2a                	mv	s4,a0
    80002b2e:	892e                	mv	s2,a1
  struct proc* p;
  int old_priority;
  int found_proc = 0;
  for(p = proc; p < &proc[NPROC]; p++)
    80002b30:	00010497          	auipc	s1,0x10
    80002b34:	18848493          	addi	s1,s1,392 # 80012cb8 <proc>
    80002b38:	00017997          	auipc	s3,0x17
    80002b3c:	38098993          	addi	s3,s3,896 # 80019eb8 <tickslock>
  {
    acquire(&p->lock);
    80002b40:	8526                	mv	a0,s1
    80002b42:	ffffe097          	auipc	ra,0xffffe
    80002b46:	0a8080e7          	jalr	168(ra) # 80000bea <acquire>
    if (p->pid == proc_pid)
    80002b4a:	589c                	lw	a5,48(s1)
    80002b4c:	01278d63          	beq	a5,s2,80002b66 <setpriority+0x4a>
      p->priority_pbs = new_priority;
      release(&p->lock);
      found_proc = 1;
      break;
    }
    release(&p->lock);
    80002b50:	8526                	mv	a0,s1
    80002b52:	ffffe097          	auipc	ra,0xffffe
    80002b56:	14c080e7          	jalr	332(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++)
    80002b5a:	1c848493          	addi	s1,s1,456
    80002b5e:	ff3491e3          	bne	s1,s3,80002b40 <setpriority+0x24>
  {
    return old_priority;
  }
  else
  {
    return -1;
    80002b62:	597d                	li	s2,-1
    80002b64:	a811                	j	80002b78 <setpriority+0x5c>
      old_priority = p->priority_pbs;
    80002b66:	1a04a903          	lw	s2,416(s1)
      p->priority_pbs = new_priority;
    80002b6a:	1b44a023          	sw	s4,416(s1)
      release(&p->lock);
    80002b6e:	8526                	mv	a0,s1
    80002b70:	ffffe097          	auipc	ra,0xffffe
    80002b74:	12e080e7          	jalr	302(ra) # 80000c9e <release>
  }
    80002b78:	854a                	mv	a0,s2
    80002b7a:	70a2                	ld	ra,40(sp)
    80002b7c:	7402                	ld	s0,32(sp)
    80002b7e:	64e2                	ld	s1,24(sp)
    80002b80:	6942                	ld	s2,16(sp)
    80002b82:	69a2                	ld	s3,8(sp)
    80002b84:	6a02                	ld	s4,0(sp)
    80002b86:	6145                	addi	sp,sp,48
    80002b88:	8082                	ret

0000000080002b8a <swtch>:
    80002b8a:	00153023          	sd	ra,0(a0)
    80002b8e:	00253423          	sd	sp,8(a0)
    80002b92:	e900                	sd	s0,16(a0)
    80002b94:	ed04                	sd	s1,24(a0)
    80002b96:	03253023          	sd	s2,32(a0)
    80002b9a:	03353423          	sd	s3,40(a0)
    80002b9e:	03453823          	sd	s4,48(a0)
    80002ba2:	03553c23          	sd	s5,56(a0)
    80002ba6:	05653023          	sd	s6,64(a0)
    80002baa:	05753423          	sd	s7,72(a0)
    80002bae:	05853823          	sd	s8,80(a0)
    80002bb2:	05953c23          	sd	s9,88(a0)
    80002bb6:	07a53023          	sd	s10,96(a0)
    80002bba:	07b53423          	sd	s11,104(a0)
    80002bbe:	0005b083          	ld	ra,0(a1)
    80002bc2:	0085b103          	ld	sp,8(a1)
    80002bc6:	6980                	ld	s0,16(a1)
    80002bc8:	6d84                	ld	s1,24(a1)
    80002bca:	0205b903          	ld	s2,32(a1)
    80002bce:	0285b983          	ld	s3,40(a1)
    80002bd2:	0305ba03          	ld	s4,48(a1)
    80002bd6:	0385ba83          	ld	s5,56(a1)
    80002bda:	0405bb03          	ld	s6,64(a1)
    80002bde:	0485bb83          	ld	s7,72(a1)
    80002be2:	0505bc03          	ld	s8,80(a1)
    80002be6:	0585bc83          	ld	s9,88(a1)
    80002bea:	0605bd03          	ld	s10,96(a1)
    80002bee:	0685bd83          	ld	s11,104(a1)
    80002bf2:	8082                	ret

0000000080002bf4 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002bf4:	1141                	addi	sp,sp,-16
    80002bf6:	e406                	sd	ra,8(sp)
    80002bf8:	e022                	sd	s0,0(sp)
    80002bfa:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002bfc:	00006597          	auipc	a1,0x6
    80002c00:	71c58593          	addi	a1,a1,1820 # 80009318 <states.1811+0x30>
    80002c04:	00017517          	auipc	a0,0x17
    80002c08:	2b450513          	addi	a0,a0,692 # 80019eb8 <tickslock>
    80002c0c:	ffffe097          	auipc	ra,0xffffe
    80002c10:	f4e080e7          	jalr	-178(ra) # 80000b5a <initlock>
}
    80002c14:	60a2                	ld	ra,8(sp)
    80002c16:	6402                	ld	s0,0(sp)
    80002c18:	0141                	addi	sp,sp,16
    80002c1a:	8082                	ret

0000000080002c1c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002c1c:	1141                	addi	sp,sp,-16
    80002c1e:	e422                	sd	s0,8(sp)
    80002c20:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c22:	00004797          	auipc	a5,0x4
    80002c26:	bfe78793          	addi	a5,a5,-1026 # 80006820 <kernelvec>
    80002c2a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002c2e:	6422                	ld	s0,8(sp)
    80002c30:	0141                	addi	sp,sp,16
    80002c32:	8082                	ret

0000000080002c34 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002c34:	1141                	addi	sp,sp,-16
    80002c36:	e406                	sd	ra,8(sp)
    80002c38:	e022                	sd	s0,0(sp)
    80002c3a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002c3c:	fffff097          	auipc	ra,0xfffff
    80002c40:	f8a080e7          	jalr	-118(ra) # 80001bc6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c44:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002c48:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c4a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002c4e:	00005617          	auipc	a2,0x5
    80002c52:	3b260613          	addi	a2,a2,946 # 80008000 <_trampoline>
    80002c56:	00005697          	auipc	a3,0x5
    80002c5a:	3aa68693          	addi	a3,a3,938 # 80008000 <_trampoline>
    80002c5e:	8e91                	sub	a3,a3,a2
    80002c60:	040007b7          	lui	a5,0x4000
    80002c64:	17fd                	addi	a5,a5,-1
    80002c66:	07b2                	slli	a5,a5,0xc
    80002c68:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c6a:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002c6e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002c70:	180026f3          	csrr	a3,satp
    80002c74:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c76:	6d38                	ld	a4,88(a0)
    80002c78:	6134                	ld	a3,64(a0)
    80002c7a:	6585                	lui	a1,0x1
    80002c7c:	96ae                	add	a3,a3,a1
    80002c7e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002c80:	6d38                	ld	a4,88(a0)
    80002c82:	00000697          	auipc	a3,0x0
    80002c86:	13e68693          	addi	a3,a3,318 # 80002dc0 <usertrap>
    80002c8a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002c8c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c8e:	8692                	mv	a3,tp
    80002c90:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c92:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c96:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c9a:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c9e:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002ca2:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ca4:	6f18                	ld	a4,24(a4)
    80002ca6:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002caa:	6928                	ld	a0,80(a0)
    80002cac:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002cae:	00005717          	auipc	a4,0x5
    80002cb2:	3ee70713          	addi	a4,a4,1006 # 8000809c <userret>
    80002cb6:	8f11                	sub	a4,a4,a2
    80002cb8:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002cba:	577d                	li	a4,-1
    80002cbc:	177e                	slli	a4,a4,0x3f
    80002cbe:	8d59                	or	a0,a0,a4
    80002cc0:	9782                	jalr	a5
}
    80002cc2:	60a2                	ld	ra,8(sp)
    80002cc4:	6402                	ld	s0,0(sp)
    80002cc6:	0141                	addi	sp,sp,16
    80002cc8:	8082                	ret

0000000080002cca <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002cca:	1101                	addi	sp,sp,-32
    80002ccc:	ec06                	sd	ra,24(sp)
    80002cce:	e822                	sd	s0,16(sp)
    80002cd0:	e426                	sd	s1,8(sp)
    80002cd2:	e04a                	sd	s2,0(sp)
    80002cd4:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002cd6:	00017917          	auipc	s2,0x17
    80002cda:	1e290913          	addi	s2,s2,482 # 80019eb8 <tickslock>
    80002cde:	854a                	mv	a0,s2
    80002ce0:	ffffe097          	auipc	ra,0xffffe
    80002ce4:	f0a080e7          	jalr	-246(ra) # 80000bea <acquire>
  ticks++;
    80002ce8:	00007497          	auipc	s1,0x7
    80002cec:	eb848493          	addi	s1,s1,-328 # 80009ba0 <ticks>
    80002cf0:	409c                	lw	a5,0(s1)
    80002cf2:	2785                	addiw	a5,a5,1
    80002cf4:	c09c                	sw	a5,0(s1)
  update_time();
    80002cf6:	fffff097          	auipc	ra,0xfffff
    80002cfa:	6a8080e7          	jalr	1704(ra) # 8000239e <update_time>
  wakeup(&ticks);
    80002cfe:	8526                	mv	a0,s1
    80002d00:	00000097          	auipc	ra,0x0
    80002d04:	912080e7          	jalr	-1774(ra) # 80002612 <wakeup>
  release(&tickslock);
    80002d08:	854a                	mv	a0,s2
    80002d0a:	ffffe097          	auipc	ra,0xffffe
    80002d0e:	f94080e7          	jalr	-108(ra) # 80000c9e <release>
}
    80002d12:	60e2                	ld	ra,24(sp)
    80002d14:	6442                	ld	s0,16(sp)
    80002d16:	64a2                	ld	s1,8(sp)
    80002d18:	6902                	ld	s2,0(sp)
    80002d1a:	6105                	addi	sp,sp,32
    80002d1c:	8082                	ret

0000000080002d1e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002d1e:	1101                	addi	sp,sp,-32
    80002d20:	ec06                	sd	ra,24(sp)
    80002d22:	e822                	sd	s0,16(sp)
    80002d24:	e426                	sd	s1,8(sp)
    80002d26:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d28:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002d2c:	00074d63          	bltz	a4,80002d46 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002d30:	57fd                	li	a5,-1
    80002d32:	17fe                	slli	a5,a5,0x3f
    80002d34:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002d36:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002d38:	06f70363          	beq	a4,a5,80002d9e <devintr+0x80>
  }
}
    80002d3c:	60e2                	ld	ra,24(sp)
    80002d3e:	6442                	ld	s0,16(sp)
    80002d40:	64a2                	ld	s1,8(sp)
    80002d42:	6105                	addi	sp,sp,32
    80002d44:	8082                	ret
     (scause & 0xff) == 9){
    80002d46:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002d4a:	46a5                	li	a3,9
    80002d4c:	fed792e3          	bne	a5,a3,80002d30 <devintr+0x12>
    int irq = plic_claim();
    80002d50:	00004097          	auipc	ra,0x4
    80002d54:	bd8080e7          	jalr	-1064(ra) # 80006928 <plic_claim>
    80002d58:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002d5a:	47a9                	li	a5,10
    80002d5c:	02f50763          	beq	a0,a5,80002d8a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002d60:	4785                	li	a5,1
    80002d62:	02f50963          	beq	a0,a5,80002d94 <devintr+0x76>
    return 1;
    80002d66:	4505                	li	a0,1
    } else if(irq){
    80002d68:	d8f1                	beqz	s1,80002d3c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002d6a:	85a6                	mv	a1,s1
    80002d6c:	00006517          	auipc	a0,0x6
    80002d70:	5b450513          	addi	a0,a0,1460 # 80009320 <states.1811+0x38>
    80002d74:	ffffe097          	auipc	ra,0xffffe
    80002d78:	81a080e7          	jalr	-2022(ra) # 8000058e <printf>
      plic_complete(irq);
    80002d7c:	8526                	mv	a0,s1
    80002d7e:	00004097          	auipc	ra,0x4
    80002d82:	bce080e7          	jalr	-1074(ra) # 8000694c <plic_complete>
    return 1;
    80002d86:	4505                	li	a0,1
    80002d88:	bf55                	j	80002d3c <devintr+0x1e>
      uartintr();
    80002d8a:	ffffe097          	auipc	ra,0xffffe
    80002d8e:	c24080e7          	jalr	-988(ra) # 800009ae <uartintr>
    80002d92:	b7ed                	j	80002d7c <devintr+0x5e>
      virtio_disk_intr();
    80002d94:	00004097          	auipc	ra,0x4
    80002d98:	0e2080e7          	jalr	226(ra) # 80006e76 <virtio_disk_intr>
    80002d9c:	b7c5                	j	80002d7c <devintr+0x5e>
    if(cpuid() == 0){
    80002d9e:	fffff097          	auipc	ra,0xfffff
    80002da2:	dfc080e7          	jalr	-516(ra) # 80001b9a <cpuid>
    80002da6:	c901                	beqz	a0,80002db6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002da8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002dac:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002dae:	14479073          	csrw	sip,a5
    return 2;
    80002db2:	4509                	li	a0,2
    80002db4:	b761                	j	80002d3c <devintr+0x1e>
      clockintr();
    80002db6:	00000097          	auipc	ra,0x0
    80002dba:	f14080e7          	jalr	-236(ra) # 80002cca <clockintr>
    80002dbe:	b7ed                	j	80002da8 <devintr+0x8a>

0000000080002dc0 <usertrap>:
{
    80002dc0:	7179                	addi	sp,sp,-48
    80002dc2:	f406                	sd	ra,40(sp)
    80002dc4:	f022                	sd	s0,32(sp)
    80002dc6:	ec26                	sd	s1,24(sp)
    80002dc8:	e84a                	sd	s2,16(sp)
    80002dca:	e44e                	sd	s3,8(sp)
    80002dcc:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002dce:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002dd2:	1007f793          	andi	a5,a5,256
    80002dd6:	e3a5                	bnez	a5,80002e36 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002dd8:	00004797          	auipc	a5,0x4
    80002ddc:	a4878793          	addi	a5,a5,-1464 # 80006820 <kernelvec>
    80002de0:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002de4:	fffff097          	auipc	ra,0xfffff
    80002de8:	de2080e7          	jalr	-542(ra) # 80001bc6 <myproc>
    80002dec:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002dee:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002df0:	14102773          	csrr	a4,sepc
    80002df4:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002df6:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002dfa:	47a1                	li	a5,8
    80002dfc:	04f70563          	beq	a4,a5,80002e46 <usertrap+0x86>
  } else if((which_dev = devintr()) != 0){
    80002e00:	00000097          	auipc	ra,0x0
    80002e04:	f1e080e7          	jalr	-226(ra) # 80002d1e <devintr>
    80002e08:	892a                	mv	s2,a0
    80002e0a:	cd69                	beqz	a0,80002ee4 <usertrap+0x124>
    if(which_dev == 2 && myproc()->interval) {
    80002e0c:	4789                	li	a5,2
    80002e0e:	06f50763          	beq	a0,a5,80002e7c <usertrap+0xbc>
  if(killed(p))
    80002e12:	8526                	mv	a0,s1
    80002e14:	00000097          	auipc	ra,0x0
    80002e18:	a4e080e7          	jalr	-1458(ra) # 80002862 <killed>
    80002e1c:	10051163          	bnez	a0,80002f1e <usertrap+0x15e>
  usertrapret();
    80002e20:	00000097          	auipc	ra,0x0
    80002e24:	e14080e7          	jalr	-492(ra) # 80002c34 <usertrapret>
}
    80002e28:	70a2                	ld	ra,40(sp)
    80002e2a:	7402                	ld	s0,32(sp)
    80002e2c:	64e2                	ld	s1,24(sp)
    80002e2e:	6942                	ld	s2,16(sp)
    80002e30:	69a2                	ld	s3,8(sp)
    80002e32:	6145                	addi	sp,sp,48
    80002e34:	8082                	ret
    panic("usertrap: not from user mode");
    80002e36:	00006517          	auipc	a0,0x6
    80002e3a:	50a50513          	addi	a0,a0,1290 # 80009340 <states.1811+0x58>
    80002e3e:	ffffd097          	auipc	ra,0xffffd
    80002e42:	706080e7          	jalr	1798(ra) # 80000544 <panic>
    if(killed(p))
    80002e46:	00000097          	auipc	ra,0x0
    80002e4a:	a1c080e7          	jalr	-1508(ra) # 80002862 <killed>
    80002e4e:	e10d                	bnez	a0,80002e70 <usertrap+0xb0>
    p->trapframe->epc += 4;
    80002e50:	6cb8                	ld	a4,88(s1)
    80002e52:	6f1c                	ld	a5,24(a4)
    80002e54:	0791                	addi	a5,a5,4
    80002e56:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e58:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002e5c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e60:	10079073          	csrw	sstatus,a5
    syscall();
    80002e64:	00000097          	auipc	ra,0x0
    80002e68:	404080e7          	jalr	1028(ra) # 80003268 <syscall>
  int which_dev = 0;
    80002e6c:	4901                	li	s2,0
    80002e6e:	b755                	j	80002e12 <usertrap+0x52>
      exit(-1);
    80002e70:	557d                	li	a0,-1
    80002e72:	00000097          	auipc	ra,0x0
    80002e76:	870080e7          	jalr	-1936(ra) # 800026e2 <exit>
    80002e7a:	bfd9                	j	80002e50 <usertrap+0x90>
    if(which_dev == 2 && myproc()->interval) {
    80002e7c:	fffff097          	auipc	ra,0xfffff
    80002e80:	d4a080e7          	jalr	-694(ra) # 80001bc6 <myproc>
    80002e84:	17852783          	lw	a5,376(a0)
    80002e88:	ef89                	bnez	a5,80002ea2 <usertrap+0xe2>
  if(killed(p))
    80002e8a:	8526                	mv	a0,s1
    80002e8c:	00000097          	auipc	ra,0x0
    80002e90:	9d6080e7          	jalr	-1578(ra) # 80002862 <killed>
    80002e94:	cd49                	beqz	a0,80002f2e <usertrap+0x16e>
    exit(-1);
    80002e96:	557d                	li	a0,-1
    80002e98:	00000097          	auipc	ra,0x0
    80002e9c:	84a080e7          	jalr	-1974(ra) # 800026e2 <exit>
    if(which_dev == 2 && myproc()->state == RUNNING && myproc() != 0) {
    80002ea0:	a079                	j	80002f2e <usertrap+0x16e>
      myproc()->ticks_left--;
    80002ea2:	fffff097          	auipc	ra,0xfffff
    80002ea6:	d24080e7          	jalr	-732(ra) # 80001bc6 <myproc>
    80002eaa:	17c52783          	lw	a5,380(a0)
    80002eae:	37fd                	addiw	a5,a5,-1
    80002eb0:	16f52e23          	sw	a5,380(a0)
      if(myproc()->ticks_left == 0) {
    80002eb4:	fffff097          	auipc	ra,0xfffff
    80002eb8:	d12080e7          	jalr	-750(ra) # 80001bc6 <myproc>
    80002ebc:	17c52783          	lw	a5,380(a0)
    80002ec0:	f7e9                	bnez	a5,80002e8a <usertrap+0xca>
        p->sigalarm_tf = kalloc();
    80002ec2:	ffffe097          	auipc	ra,0xffffe
    80002ec6:	c38080e7          	jalr	-968(ra) # 80000afa <kalloc>
    80002eca:	18a4b423          	sd	a0,392(s1)
        memmove(p->sigalarm_tf, p->trapframe, PGSIZE);
    80002ece:	6605                	lui	a2,0x1
    80002ed0:	6cac                	ld	a1,88(s1)
    80002ed2:	ffffe097          	auipc	ra,0xffffe
    80002ed6:	e74080e7          	jalr	-396(ra) # 80000d46 <memmove>
        p->trapframe->epc = p->sig_handler;
    80002eda:	6cbc                	ld	a5,88(s1)
    80002edc:	1804b703          	ld	a4,384(s1)
    80002ee0:	ef98                	sd	a4,24(a5)
    80002ee2:	b765                	j	80002e8a <usertrap+0xca>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ee4:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002ee8:	5890                	lw	a2,48(s1)
    80002eea:	00006517          	auipc	a0,0x6
    80002eee:	47650513          	addi	a0,a0,1142 # 80009360 <states.1811+0x78>
    80002ef2:	ffffd097          	auipc	ra,0xffffd
    80002ef6:	69c080e7          	jalr	1692(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002efa:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002efe:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f02:	00006517          	auipc	a0,0x6
    80002f06:	48e50513          	addi	a0,a0,1166 # 80009390 <states.1811+0xa8>
    80002f0a:	ffffd097          	auipc	ra,0xffffd
    80002f0e:	684080e7          	jalr	1668(ra) # 8000058e <printf>
    setkilled(p);
    80002f12:	8526                	mv	a0,s1
    80002f14:	00000097          	auipc	ra,0x0
    80002f18:	922080e7          	jalr	-1758(ra) # 80002836 <setkilled>
    80002f1c:	bddd                	j	80002e12 <usertrap+0x52>
    exit(-1);
    80002f1e:	557d                	li	a0,-1
    80002f20:	fffff097          	auipc	ra,0xfffff
    80002f24:	7c2080e7          	jalr	1986(ra) # 800026e2 <exit>
    if(which_dev == 2 && myproc()->state == RUNNING && myproc() != 0) {
    80002f28:	4789                	li	a5,2
    80002f2a:	eef91be3          	bne	s2,a5,80002e20 <usertrap+0x60>
    80002f2e:	fffff097          	auipc	ra,0xfffff
    80002f32:	c98080e7          	jalr	-872(ra) # 80001bc6 <myproc>
    80002f36:	4d18                	lw	a4,24(a0)
    80002f38:	4791                	li	a5,4
    80002f3a:	eef713e3          	bne	a4,a5,80002e20 <usertrap+0x60>
    80002f3e:	fffff097          	auipc	ra,0xfffff
    80002f42:	c88080e7          	jalr	-888(ra) # 80001bc6 <myproc>
    80002f46:	ec050de3          	beqz	a0,80002e20 <usertrap+0x60>
      if(p->curr_rtime >= priority_levels[p->priority]) {
    80002f4a:	1b44a703          	lw	a4,436(s1)
    80002f4e:	00271693          	slli	a3,a4,0x2
    80002f52:	00007797          	auipc	a5,0x7
    80002f56:	b0678793          	addi	a5,a5,-1274 # 80009a58 <priority_levels>
    80002f5a:	97b6                	add	a5,a5,a3
    80002f5c:	1bc4a683          	lw	a3,444(s1)
    80002f60:	439c                	lw	a5,0(a5)
    80002f62:	00f6da63          	bge	a3,a5,80002f76 <usertrap+0x1b6>
        for(int i = 0; i < p->priority; i++) {
    80002f66:	0000f997          	auipc	s3,0xf
    80002f6a:	2e298993          	addi	s3,s3,738 # 80012248 <queues+0x8>
    80002f6e:	4901                	li	s2,0
    80002f70:	02e04963          	bgtz	a4,80002fa2 <usertrap+0x1e2>
    80002f74:	b575                	j	80002e20 <usertrap+0x60>
        if(p->priority != 4) {
    80002f76:	4791                	li	a5,4
    80002f78:	00f70563          	beq	a4,a5,80002f82 <usertrap+0x1c2>
          p->priority++;
    80002f7c:	2705                	addiw	a4,a4,1
    80002f7e:	1ae4aa23          	sw	a4,436(s1)
        p->curr_rtime = 0;
    80002f82:	1a04ae23          	sw	zero,444(s1)
        p->curr_wtime = 0;
    80002f86:	1c04a023          	sw	zero,448(s1)
        yield();
    80002f8a:	fffff097          	auipc	ra,0xfffff
    80002f8e:	3d8080e7          	jalr	984(ra) # 80002362 <yield>
    80002f92:	b579                	j	80002e20 <usertrap+0x60>
        for(int i = 0; i < p->priority; i++) {
    80002f94:	2905                	addiw	s2,s2,1
    80002f96:	21898993          	addi	s3,s3,536
    80002f9a:	1b44a783          	lw	a5,436(s1)
    80002f9e:	e8f951e3          	bge	s2,a5,80002e20 <usertrap+0x60>
          if(queues[i].length > 0) {
    80002fa2:	0009a783          	lw	a5,0(s3)
    80002fa6:	fef057e3          	blez	a5,80002f94 <usertrap+0x1d4>
            yield();
    80002faa:	fffff097          	auipc	ra,0xfffff
    80002fae:	3b8080e7          	jalr	952(ra) # 80002362 <yield>
    80002fb2:	b7cd                	j	80002f94 <usertrap+0x1d4>

0000000080002fb4 <kerneltrap>:
{
    80002fb4:	7139                	addi	sp,sp,-64
    80002fb6:	fc06                	sd	ra,56(sp)
    80002fb8:	f822                	sd	s0,48(sp)
    80002fba:	f426                	sd	s1,40(sp)
    80002fbc:	f04a                	sd	s2,32(sp)
    80002fbe:	ec4e                	sd	s3,24(sp)
    80002fc0:	e852                	sd	s4,16(sp)
    80002fc2:	e456                	sd	s5,8(sp)
    80002fc4:	0080                	addi	s0,sp,64
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fc6:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fca:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002fce:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002fd2:	1004f793          	andi	a5,s1,256
    80002fd6:	cb95                	beqz	a5,8000300a <kerneltrap+0x56>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fd8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002fdc:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002fde:	ef95                	bnez	a5,8000301a <kerneltrap+0x66>
  if((which_dev = devintr()) == 0){
    80002fe0:	00000097          	auipc	ra,0x0
    80002fe4:	d3e080e7          	jalr	-706(ra) # 80002d1e <devintr>
    80002fe8:	c129                	beqz	a0,8000302a <kerneltrap+0x76>
    if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING) {
    80002fea:	4789                	li	a5,2
    80002fec:	06f50c63          	beq	a0,a5,80003064 <kerneltrap+0xb0>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ff0:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ff4:	10049073          	csrw	sstatus,s1
}
    80002ff8:	70e2                	ld	ra,56(sp)
    80002ffa:	7442                	ld	s0,48(sp)
    80002ffc:	74a2                	ld	s1,40(sp)
    80002ffe:	7902                	ld	s2,32(sp)
    80003000:	69e2                	ld	s3,24(sp)
    80003002:	6a42                	ld	s4,16(sp)
    80003004:	6aa2                	ld	s5,8(sp)
    80003006:	6121                	addi	sp,sp,64
    80003008:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000300a:	00006517          	auipc	a0,0x6
    8000300e:	3a650513          	addi	a0,a0,934 # 800093b0 <states.1811+0xc8>
    80003012:	ffffd097          	auipc	ra,0xffffd
    80003016:	532080e7          	jalr	1330(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    8000301a:	00006517          	auipc	a0,0x6
    8000301e:	3be50513          	addi	a0,a0,958 # 800093d8 <states.1811+0xf0>
    80003022:	ffffd097          	auipc	ra,0xffffd
    80003026:	522080e7          	jalr	1314(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    8000302a:	85ce                	mv	a1,s3
    8000302c:	00006517          	auipc	a0,0x6
    80003030:	3cc50513          	addi	a0,a0,972 # 800093f8 <states.1811+0x110>
    80003034:	ffffd097          	auipc	ra,0xffffd
    80003038:	55a080e7          	jalr	1370(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000303c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003040:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003044:	00006517          	auipc	a0,0x6
    80003048:	3c450513          	addi	a0,a0,964 # 80009408 <states.1811+0x120>
    8000304c:	ffffd097          	auipc	ra,0xffffd
    80003050:	542080e7          	jalr	1346(ra) # 8000058e <printf>
    panic("kerneltrap");
    80003054:	00006517          	auipc	a0,0x6
    80003058:	3cc50513          	addi	a0,a0,972 # 80009420 <states.1811+0x138>
    8000305c:	ffffd097          	auipc	ra,0xffffd
    80003060:	4e8080e7          	jalr	1256(ra) # 80000544 <panic>
    if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING) {
    80003064:	fffff097          	auipc	ra,0xfffff
    80003068:	b62080e7          	jalr	-1182(ra) # 80001bc6 <myproc>
    8000306c:	d151                	beqz	a0,80002ff0 <kerneltrap+0x3c>
    8000306e:	fffff097          	auipc	ra,0xfffff
    80003072:	b58080e7          	jalr	-1192(ra) # 80001bc6 <myproc>
    80003076:	4d18                	lw	a4,24(a0)
    80003078:	4791                	li	a5,4
    8000307a:	f6f71be3          	bne	a4,a5,80002ff0 <kerneltrap+0x3c>
      struct proc* p = myproc();
    8000307e:	fffff097          	auipc	ra,0xfffff
    80003082:	b48080e7          	jalr	-1208(ra) # 80001bc6 <myproc>
    80003086:	8aaa                	mv	s5,a0
      if(p->curr_rtime >= priority_levels[p->priority]) {
    80003088:	1b452703          	lw	a4,436(a0)
    8000308c:	00271693          	slli	a3,a4,0x2
    80003090:	00007797          	auipc	a5,0x7
    80003094:	9c878793          	addi	a5,a5,-1592 # 80009a58 <priority_levels>
    80003098:	97b6                	add	a5,a5,a3
    8000309a:	1bc52683          	lw	a3,444(a0)
    8000309e:	439c                	lw	a5,0(a5)
    800030a0:	00f6da63          	bge	a3,a5,800030b4 <kerneltrap+0x100>
        for(int i = 0; i < p->priority; i++) {
    800030a4:	0000fa17          	auipc	s4,0xf
    800030a8:	1a4a0a13          	addi	s4,s4,420 # 80012248 <queues+0x8>
    800030ac:	4981                	li	s3,0
    800030ae:	02e04563          	bgtz	a4,800030d8 <kerneltrap+0x124>
    800030b2:	bf3d                	j	80002ff0 <kerneltrap+0x3c>
        if(p->priority != 4) {
    800030b4:	4791                	li	a5,4
    800030b6:	00f70563          	beq	a4,a5,800030c0 <kerneltrap+0x10c>
          p->priority++;
    800030ba:	2705                	addiw	a4,a4,1
    800030bc:	1ae52a23          	sw	a4,436(a0)
        yield();
    800030c0:	fffff097          	auipc	ra,0xfffff
    800030c4:	2a2080e7          	jalr	674(ra) # 80002362 <yield>
    800030c8:	b725                	j	80002ff0 <kerneltrap+0x3c>
        for(int i = 0; i < p->priority; i++) {
    800030ca:	2985                	addiw	s3,s3,1
    800030cc:	218a0a13          	addi	s4,s4,536
    800030d0:	1b4aa783          	lw	a5,436(s5)
    800030d4:	f0f9dee3          	bge	s3,a5,80002ff0 <kerneltrap+0x3c>
          if(queues[i].length > 0) {
    800030d8:	000a2783          	lw	a5,0(s4)
    800030dc:	fef057e3          	blez	a5,800030ca <kerneltrap+0x116>
            yield();
    800030e0:	fffff097          	auipc	ra,0xfffff
    800030e4:	282080e7          	jalr	642(ra) # 80002362 <yield>
    800030e8:	b7cd                	j	800030ca <kerneltrap+0x116>

00000000800030ea <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800030ea:	1101                	addi	sp,sp,-32
    800030ec:	ec06                	sd	ra,24(sp)
    800030ee:	e822                	sd	s0,16(sp)
    800030f0:	e426                	sd	s1,8(sp)
    800030f2:	1000                	addi	s0,sp,32
    800030f4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800030f6:	fffff097          	auipc	ra,0xfffff
    800030fa:	ad0080e7          	jalr	-1328(ra) # 80001bc6 <myproc>
  switch (n) {
    800030fe:	4795                	li	a5,5
    80003100:	0497e163          	bltu	a5,s1,80003142 <argraw+0x58>
    80003104:	048a                	slli	s1,s1,0x2
    80003106:	00006717          	auipc	a4,0x6
    8000310a:	4ca70713          	addi	a4,a4,1226 # 800095d0 <states.1811+0x2e8>
    8000310e:	94ba                	add	s1,s1,a4
    80003110:	409c                	lw	a5,0(s1)
    80003112:	97ba                	add	a5,a5,a4
    80003114:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003116:	6d3c                	ld	a5,88(a0)
    80003118:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000311a:	60e2                	ld	ra,24(sp)
    8000311c:	6442                	ld	s0,16(sp)
    8000311e:	64a2                	ld	s1,8(sp)
    80003120:	6105                	addi	sp,sp,32
    80003122:	8082                	ret
    return p->trapframe->a1;
    80003124:	6d3c                	ld	a5,88(a0)
    80003126:	7fa8                	ld	a0,120(a5)
    80003128:	bfcd                	j	8000311a <argraw+0x30>
    return p->trapframe->a2;
    8000312a:	6d3c                	ld	a5,88(a0)
    8000312c:	63c8                	ld	a0,128(a5)
    8000312e:	b7f5                	j	8000311a <argraw+0x30>
    return p->trapframe->a3;
    80003130:	6d3c                	ld	a5,88(a0)
    80003132:	67c8                	ld	a0,136(a5)
    80003134:	b7dd                	j	8000311a <argraw+0x30>
    return p->trapframe->a4;
    80003136:	6d3c                	ld	a5,88(a0)
    80003138:	6bc8                	ld	a0,144(a5)
    8000313a:	b7c5                	j	8000311a <argraw+0x30>
    return p->trapframe->a5;
    8000313c:	6d3c                	ld	a5,88(a0)
    8000313e:	6fc8                	ld	a0,152(a5)
    80003140:	bfe9                	j	8000311a <argraw+0x30>
  panic("argraw");
    80003142:	00006517          	auipc	a0,0x6
    80003146:	2ee50513          	addi	a0,a0,750 # 80009430 <states.1811+0x148>
    8000314a:	ffffd097          	auipc	ra,0xffffd
    8000314e:	3fa080e7          	jalr	1018(ra) # 80000544 <panic>

0000000080003152 <fetchaddr>:
{
    80003152:	1101                	addi	sp,sp,-32
    80003154:	ec06                	sd	ra,24(sp)
    80003156:	e822                	sd	s0,16(sp)
    80003158:	e426                	sd	s1,8(sp)
    8000315a:	e04a                	sd	s2,0(sp)
    8000315c:	1000                	addi	s0,sp,32
    8000315e:	84aa                	mv	s1,a0
    80003160:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003162:	fffff097          	auipc	ra,0xfffff
    80003166:	a64080e7          	jalr	-1436(ra) # 80001bc6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    8000316a:	653c                	ld	a5,72(a0)
    8000316c:	02f4f863          	bgeu	s1,a5,8000319c <fetchaddr+0x4a>
    80003170:	00848713          	addi	a4,s1,8
    80003174:	02e7e663          	bltu	a5,a4,800031a0 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003178:	46a1                	li	a3,8
    8000317a:	8626                	mv	a2,s1
    8000317c:	85ca                	mv	a1,s2
    8000317e:	6928                	ld	a0,80(a0)
    80003180:	ffffe097          	auipc	ra,0xffffe
    80003184:	590080e7          	jalr	1424(ra) # 80001710 <copyin>
    80003188:	00a03533          	snez	a0,a0
    8000318c:	40a00533          	neg	a0,a0
}
    80003190:	60e2                	ld	ra,24(sp)
    80003192:	6442                	ld	s0,16(sp)
    80003194:	64a2                	ld	s1,8(sp)
    80003196:	6902                	ld	s2,0(sp)
    80003198:	6105                	addi	sp,sp,32
    8000319a:	8082                	ret
    return -1;
    8000319c:	557d                	li	a0,-1
    8000319e:	bfcd                	j	80003190 <fetchaddr+0x3e>
    800031a0:	557d                	li	a0,-1
    800031a2:	b7fd                	j	80003190 <fetchaddr+0x3e>

00000000800031a4 <fetchstr>:
{
    800031a4:	7179                	addi	sp,sp,-48
    800031a6:	f406                	sd	ra,40(sp)
    800031a8:	f022                	sd	s0,32(sp)
    800031aa:	ec26                	sd	s1,24(sp)
    800031ac:	e84a                	sd	s2,16(sp)
    800031ae:	e44e                	sd	s3,8(sp)
    800031b0:	1800                	addi	s0,sp,48
    800031b2:	892a                	mv	s2,a0
    800031b4:	84ae                	mv	s1,a1
    800031b6:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800031b8:	fffff097          	auipc	ra,0xfffff
    800031bc:	a0e080e7          	jalr	-1522(ra) # 80001bc6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    800031c0:	86ce                	mv	a3,s3
    800031c2:	864a                	mv	a2,s2
    800031c4:	85a6                	mv	a1,s1
    800031c6:	6928                	ld	a0,80(a0)
    800031c8:	ffffe097          	auipc	ra,0xffffe
    800031cc:	5d4080e7          	jalr	1492(ra) # 8000179c <copyinstr>
    800031d0:	00054e63          	bltz	a0,800031ec <fetchstr+0x48>
  return strlen(buf);
    800031d4:	8526                	mv	a0,s1
    800031d6:	ffffe097          	auipc	ra,0xffffe
    800031da:	c94080e7          	jalr	-876(ra) # 80000e6a <strlen>
}
    800031de:	70a2                	ld	ra,40(sp)
    800031e0:	7402                	ld	s0,32(sp)
    800031e2:	64e2                	ld	s1,24(sp)
    800031e4:	6942                	ld	s2,16(sp)
    800031e6:	69a2                	ld	s3,8(sp)
    800031e8:	6145                	addi	sp,sp,48
    800031ea:	8082                	ret
    return -1;
    800031ec:	557d                	li	a0,-1
    800031ee:	bfc5                	j	800031de <fetchstr+0x3a>

00000000800031f0 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    800031f0:	1101                	addi	sp,sp,-32
    800031f2:	ec06                	sd	ra,24(sp)
    800031f4:	e822                	sd	s0,16(sp)
    800031f6:	e426                	sd	s1,8(sp)
    800031f8:	1000                	addi	s0,sp,32
    800031fa:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800031fc:	00000097          	auipc	ra,0x0
    80003200:	eee080e7          	jalr	-274(ra) # 800030ea <argraw>
    80003204:	c088                	sw	a0,0(s1)
}
    80003206:	60e2                	ld	ra,24(sp)
    80003208:	6442                	ld	s0,16(sp)
    8000320a:	64a2                	ld	s1,8(sp)
    8000320c:	6105                	addi	sp,sp,32
    8000320e:	8082                	ret

0000000080003210 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80003210:	1101                	addi	sp,sp,-32
    80003212:	ec06                	sd	ra,24(sp)
    80003214:	e822                	sd	s0,16(sp)
    80003216:	e426                	sd	s1,8(sp)
    80003218:	1000                	addi	s0,sp,32
    8000321a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000321c:	00000097          	auipc	ra,0x0
    80003220:	ece080e7          	jalr	-306(ra) # 800030ea <argraw>
    80003224:	e088                	sd	a0,0(s1)
}
    80003226:	60e2                	ld	ra,24(sp)
    80003228:	6442                	ld	s0,16(sp)
    8000322a:	64a2                	ld	s1,8(sp)
    8000322c:	6105                	addi	sp,sp,32
    8000322e:	8082                	ret

0000000080003230 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003230:	7179                	addi	sp,sp,-48
    80003232:	f406                	sd	ra,40(sp)
    80003234:	f022                	sd	s0,32(sp)
    80003236:	ec26                	sd	s1,24(sp)
    80003238:	e84a                	sd	s2,16(sp)
    8000323a:	1800                	addi	s0,sp,48
    8000323c:	84ae                	mv	s1,a1
    8000323e:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80003240:	fd840593          	addi	a1,s0,-40
    80003244:	00000097          	auipc	ra,0x0
    80003248:	fcc080e7          	jalr	-52(ra) # 80003210 <argaddr>
  return fetchstr(addr, buf, max);
    8000324c:	864a                	mv	a2,s2
    8000324e:	85a6                	mv	a1,s1
    80003250:	fd843503          	ld	a0,-40(s0)
    80003254:	00000097          	auipc	ra,0x0
    80003258:	f50080e7          	jalr	-176(ra) # 800031a4 <fetchstr>
}
    8000325c:	70a2                	ld	ra,40(sp)
    8000325e:	7402                	ld	s0,32(sp)
    80003260:	64e2                	ld	s1,24(sp)
    80003262:	6942                	ld	s2,16(sp)
    80003264:	6145                	addi	sp,sp,48
    80003266:	8082                	ret

0000000080003268 <syscall>:
[SYS_setpriority] "sys_setpriority",
};

void
syscall(void)
{
    80003268:	7179                	addi	sp,sp,-48
    8000326a:	f406                	sd	ra,40(sp)
    8000326c:	f022                	sd	s0,32(sp)
    8000326e:	ec26                	sd	s1,24(sp)
    80003270:	e84a                	sd	s2,16(sp)
    80003272:	e44e                	sd	s3,8(sp)
    80003274:	e052                	sd	s4,0(sp)
    80003276:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80003278:	fffff097          	auipc	ra,0xfffff
    8000327c:	94e080e7          	jalr	-1714(ra) # 80001bc6 <myproc>
    80003280:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003282:	05853903          	ld	s2,88(a0)
    80003286:	0a893783          	ld	a5,168(s2)
    8000328a:	0007899b          	sext.w	s3,a5
  unsigned int tmp = p->trapframe->a0;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000328e:	37fd                	addiw	a5,a5,-1
    80003290:	4769                	li	a4,26
    80003292:	42f76863          	bltu	a4,a5,800036c2 <syscall+0x45a>
    80003296:	00399713          	slli	a4,s3,0x3
    8000329a:	00006797          	auipc	a5,0x6
    8000329e:	34e78793          	addi	a5,a5,846 # 800095e8 <syscalls>
    800032a2:	97ba                	add	a5,a5,a4
    800032a4:	639c                	ld	a5,0(a5)
    800032a6:	40078e63          	beqz	a5,800036c2 <syscall+0x45a>
  unsigned int tmp = p->trapframe->a0;
    800032aa:	07093a03          	ld	s4,112(s2)
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    800032ae:	9782                	jalr	a5
    800032b0:	06a93823          	sd	a0,112(s2)

    // Check for trace_flag to be on
    if(p->trace_flag >> num) {  // check for '=='
    800032b4:	1744a783          	lw	a5,372(s1)
    800032b8:	4137d7bb          	sraw	a5,a5,s3
    800032bc:	42078263          	beqz	a5,800036e0 <syscall+0x478>
      if(num == 1)      printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0);   //fork  
    800032c0:	4785                	li	a5,1
    800032c2:	0cf98263          	beq	s3,a5,80003386 <syscall+0x11e>
  unsigned int tmp = p->trapframe->a0;
    800032c6:	000a069b          	sext.w	a3,s4
      else if(num == 2) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // exit
    800032ca:	4789                	li	a5,2
    800032cc:	0cf98d63          	beq	s3,a5,800033a6 <syscall+0x13e>
      else if(num == 3) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // wait
    800032d0:	478d                	li	a5,3
    800032d2:	0ef98a63          	beq	s3,a5,800033c6 <syscall+0x15e>
      else if(num == 4) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // pipe
    800032d6:	4791                	li	a5,4
    800032d8:	10f98763          	beq	s3,a5,800033e6 <syscall+0x17e>
      else if(num == 5) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp,  p->trapframe->a1,  p->trapframe->a2, p->trapframe->a0);  // read
    800032dc:	4795                	li	a5,5
    800032de:	12f98463          	beq	s3,a5,80003406 <syscall+0x19e>
      else if(num == 6) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // kill
    800032e2:	4799                	li	a5,6
    800032e4:	14f98463          	beq	s3,a5,8000342c <syscall+0x1c4>
      else if(num == 7) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp,  p->trapframe->a1, p->trapframe->a0);   // exec
    800032e8:	479d                	li	a5,7
    800032ea:	16f98163          	beq	s3,a5,8000344c <syscall+0x1e4>
      else if(num == 8) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp,  p->trapframe->a1, p->trapframe->a0);  // fstat
    800032ee:	47a1                	li	a5,8
    800032f0:	16f98f63          	beq	s3,a5,8000346e <syscall+0x206>
      else if(num == 9) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // chdir
    800032f4:	47a5                	li	a5,9
    800032f6:	18f98d63          	beq	s3,a5,80003490 <syscall+0x228>
      else if(num == 10) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // dup
    800032fa:	47a9                	li	a5,10
    800032fc:	1af98a63          	beq	s3,a5,800034b0 <syscall+0x248>
      else if(num == 11) printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0);  // getpid
    80003300:	47ad                	li	a5,11
    80003302:	1cf98763          	beq	s3,a5,800034d0 <syscall+0x268>
      else if(num == 12) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // sbrk
    80003306:	47b1                	li	a5,12
    80003308:	1ef98463          	beq	s3,a5,800034f0 <syscall+0x288>
      else if(num == 13) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // sleep
    8000330c:	47b5                	li	a5,13
    8000330e:	20f98163          	beq	s3,a5,80003510 <syscall+0x2a8>
      else if(num == 14) printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0); // uptime
    80003312:	47b9                	li	a5,14
    80003314:	20f98e63          	beq	s3,a5,80003530 <syscall+0x2c8>
      else if(num == 15) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a0); // open
    80003318:	47bd                	li	a5,15
    8000331a:	22f98b63          	beq	s3,a5,80003550 <syscall+0x2e8>
      else if(num == 16) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a3, p->trapframe->a0); // write
    8000331e:	47c1                	li	a5,16
    80003320:	24f98963          	beq	s3,a5,80003572 <syscall+0x30a>
      else if(num == 17) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a3, p->trapframe->a0); // mknod
    80003324:	47c5                	li	a5,17
    80003326:	26f98963          	beq	s3,a5,80003598 <syscall+0x330>
      else if(num == 18) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // unlink
    8000332a:	47c9                	li	a5,18
    8000332c:	28f98963          	beq	s3,a5,800035be <syscall+0x356>
      else if(num == 19) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a0); // link
    80003330:	47cd                	li	a5,19
    80003332:	2af98663          	beq	s3,a5,800035de <syscall+0x376>
      else if(num == 20) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // mkdir
    80003336:	47d1                	li	a5,20
    80003338:	2cf98463          	beq	s3,a5,80003600 <syscall+0x398>
      else if(num == 21) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // close
    8000333c:	47d5                	li	a5,21
    8000333e:	2ef98163          	beq	s3,a5,80003620 <syscall+0x3b8>
      else if(num == 22) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // trace
    80003342:	47d9                	li	a5,22
    80003344:	2ef98e63          	beq	s3,a5,80003640 <syscall+0x3d8>
      else if(num == 23) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a0); // sigalarm
    80003348:	47dd                	li	a5,23
    8000334a:	30f98b63          	beq	s3,a5,80003660 <syscall+0x3f8>
      else if(num == 24) printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0); // sigreturn
    8000334e:	47e1                	li	a5,24
    80003350:	32f98963          	beq	s3,a5,80003682 <syscall+0x41a>
      else if(num == 25) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // settickets
    80003354:	47e5                	li	a5,25
    80003356:	34f98663          	beq	s3,a5,800036a2 <syscall+0x43a>
      else if(num == 26) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a1, p->trapframe->a2, p->trapframe->a0); // waitx
    8000335a:	47e9                	li	a5,26
    8000335c:	38f99263          	bne	s3,a5,800036e0 <syscall+0x478>
    80003360:	6cb8                	ld	a4,88(s1)
    80003362:	07073803          	ld	a6,112(a4)
    80003366:	635c                	ld	a5,128(a4)
    80003368:	7f38                	ld	a4,120(a4)
    8000336a:	00006617          	auipc	a2,0x6
    8000336e:	7d663603          	ld	a2,2006(a2) # 80009b40 <syscall_names+0xd0>
    80003372:	588c                	lw	a1,48(s1)
    80003374:	00006517          	auipc	a0,0x6
    80003378:	0fc50513          	addi	a0,a0,252 # 80009470 <states.1811+0x188>
    8000337c:	ffffd097          	auipc	ra,0xffffd
    80003380:	212080e7          	jalr	530(ra) # 8000058e <printf>
    80003384:	aeb1                	j	800036e0 <syscall+0x478>
      if(num == 1)      printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0);   //fork  
    80003386:	6cbc                	ld	a5,88(s1)
    80003388:	7bb4                	ld	a3,112(a5)
    8000338a:	00006617          	auipc	a2,0x6
    8000338e:	6ee63603          	ld	a2,1774(a2) # 80009a78 <syscall_names+0x8>
    80003392:	588c                	lw	a1,48(s1)
    80003394:	00006517          	auipc	a0,0x6
    80003398:	0a450513          	addi	a0,a0,164 # 80009438 <states.1811+0x150>
    8000339c:	ffffd097          	auipc	ra,0xffffd
    800033a0:	1f2080e7          	jalr	498(ra) # 8000058e <printf>
    800033a4:	ae35                	j	800036e0 <syscall+0x478>
      else if(num == 2) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // exit
    800033a6:	6cbc                	ld	a5,88(s1)
    800033a8:	7bb8                	ld	a4,112(a5)
    800033aa:	00006617          	auipc	a2,0x6
    800033ae:	6d663603          	ld	a2,1750(a2) # 80009a80 <syscall_names+0x10>
    800033b2:	588c                	lw	a1,48(s1)
    800033b4:	00006517          	auipc	a0,0x6
    800033b8:	09c50513          	addi	a0,a0,156 # 80009450 <states.1811+0x168>
    800033bc:	ffffd097          	auipc	ra,0xffffd
    800033c0:	1d2080e7          	jalr	466(ra) # 8000058e <printf>
    800033c4:	ae31                	j	800036e0 <syscall+0x478>
      else if(num == 3) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // wait
    800033c6:	6cbc                	ld	a5,88(s1)
    800033c8:	7bb8                	ld	a4,112(a5)
    800033ca:	00006617          	auipc	a2,0x6
    800033ce:	6be63603          	ld	a2,1726(a2) # 80009a88 <syscall_names+0x18>
    800033d2:	588c                	lw	a1,48(s1)
    800033d4:	00006517          	auipc	a0,0x6
    800033d8:	07c50513          	addi	a0,a0,124 # 80009450 <states.1811+0x168>
    800033dc:	ffffd097          	auipc	ra,0xffffd
    800033e0:	1b2080e7          	jalr	434(ra) # 8000058e <printf>
    800033e4:	acf5                	j	800036e0 <syscall+0x478>
      else if(num == 4) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // pipe
    800033e6:	6cbc                	ld	a5,88(s1)
    800033e8:	7bb8                	ld	a4,112(a5)
    800033ea:	00006617          	auipc	a2,0x6
    800033ee:	6a663603          	ld	a2,1702(a2) # 80009a90 <syscall_names+0x20>
    800033f2:	588c                	lw	a1,48(s1)
    800033f4:	00006517          	auipc	a0,0x6
    800033f8:	05c50513          	addi	a0,a0,92 # 80009450 <states.1811+0x168>
    800033fc:	ffffd097          	auipc	ra,0xffffd
    80003400:	192080e7          	jalr	402(ra) # 8000058e <printf>
    80003404:	acf1                	j	800036e0 <syscall+0x478>
      else if(num == 5) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp,  p->trapframe->a1,  p->trapframe->a2, p->trapframe->a0);  // read
    80003406:	6cb8                	ld	a4,88(s1)
    80003408:	07073803          	ld	a6,112(a4)
    8000340c:	635c                	ld	a5,128(a4)
    8000340e:	7f38                	ld	a4,120(a4)
    80003410:	00006617          	auipc	a2,0x6
    80003414:	68863603          	ld	a2,1672(a2) # 80009a98 <syscall_names+0x28>
    80003418:	588c                	lw	a1,48(s1)
    8000341a:	00006517          	auipc	a0,0x6
    8000341e:	05650513          	addi	a0,a0,86 # 80009470 <states.1811+0x188>
    80003422:	ffffd097          	auipc	ra,0xffffd
    80003426:	16c080e7          	jalr	364(ra) # 8000058e <printf>
    8000342a:	ac5d                	j	800036e0 <syscall+0x478>
      else if(num == 6) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // kill
    8000342c:	6cbc                	ld	a5,88(s1)
    8000342e:	7bb8                	ld	a4,112(a5)
    80003430:	00006617          	auipc	a2,0x6
    80003434:	67063603          	ld	a2,1648(a2) # 80009aa0 <syscall_names+0x30>
    80003438:	588c                	lw	a1,48(s1)
    8000343a:	00006517          	auipc	a0,0x6
    8000343e:	01650513          	addi	a0,a0,22 # 80009450 <states.1811+0x168>
    80003442:	ffffd097          	auipc	ra,0xffffd
    80003446:	14c080e7          	jalr	332(ra) # 8000058e <printf>
    8000344a:	ac59                	j	800036e0 <syscall+0x478>
      else if(num == 7) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp,  p->trapframe->a1, p->trapframe->a0);   // exec
    8000344c:	6cb8                	ld	a4,88(s1)
    8000344e:	7b3c                	ld	a5,112(a4)
    80003450:	7f38                	ld	a4,120(a4)
    80003452:	00006617          	auipc	a2,0x6
    80003456:	65663603          	ld	a2,1622(a2) # 80009aa8 <syscall_names+0x38>
    8000345a:	588c                	lw	a1,48(s1)
    8000345c:	00006517          	auipc	a0,0x6
    80003460:	03c50513          	addi	a0,a0,60 # 80009498 <states.1811+0x1b0>
    80003464:	ffffd097          	auipc	ra,0xffffd
    80003468:	12a080e7          	jalr	298(ra) # 8000058e <printf>
    8000346c:	ac95                	j	800036e0 <syscall+0x478>
      else if(num == 8) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp,  p->trapframe->a1, p->trapframe->a0);  // fstat
    8000346e:	6cb8                	ld	a4,88(s1)
    80003470:	7b3c                	ld	a5,112(a4)
    80003472:	7f38                	ld	a4,120(a4)
    80003474:	00006617          	auipc	a2,0x6
    80003478:	63c63603          	ld	a2,1596(a2) # 80009ab0 <syscall_names+0x40>
    8000347c:	588c                	lw	a1,48(s1)
    8000347e:	00006517          	auipc	a0,0x6
    80003482:	01a50513          	addi	a0,a0,26 # 80009498 <states.1811+0x1b0>
    80003486:	ffffd097          	auipc	ra,0xffffd
    8000348a:	108080e7          	jalr	264(ra) # 8000058e <printf>
    8000348e:	ac89                	j	800036e0 <syscall+0x478>
      else if(num == 9) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // chdir
    80003490:	6cbc                	ld	a5,88(s1)
    80003492:	7bb8                	ld	a4,112(a5)
    80003494:	00006617          	auipc	a2,0x6
    80003498:	62463603          	ld	a2,1572(a2) # 80009ab8 <syscall_names+0x48>
    8000349c:	588c                	lw	a1,48(s1)
    8000349e:	00006517          	auipc	a0,0x6
    800034a2:	fb250513          	addi	a0,a0,-78 # 80009450 <states.1811+0x168>
    800034a6:	ffffd097          	auipc	ra,0xffffd
    800034aa:	0e8080e7          	jalr	232(ra) # 8000058e <printf>
    800034ae:	ac0d                	j	800036e0 <syscall+0x478>
      else if(num == 10) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // dup
    800034b0:	6cbc                	ld	a5,88(s1)
    800034b2:	7bb8                	ld	a4,112(a5)
    800034b4:	00006617          	auipc	a2,0x6
    800034b8:	60c63603          	ld	a2,1548(a2) # 80009ac0 <syscall_names+0x50>
    800034bc:	588c                	lw	a1,48(s1)
    800034be:	00006517          	auipc	a0,0x6
    800034c2:	f9250513          	addi	a0,a0,-110 # 80009450 <states.1811+0x168>
    800034c6:	ffffd097          	auipc	ra,0xffffd
    800034ca:	0c8080e7          	jalr	200(ra) # 8000058e <printf>
    800034ce:	ac09                	j	800036e0 <syscall+0x478>
      else if(num == 11) printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0);  // getpid
    800034d0:	6cbc                	ld	a5,88(s1)
    800034d2:	7bb4                	ld	a3,112(a5)
    800034d4:	00006617          	auipc	a2,0x6
    800034d8:	5f463603          	ld	a2,1524(a2) # 80009ac8 <syscall_names+0x58>
    800034dc:	588c                	lw	a1,48(s1)
    800034de:	00006517          	auipc	a0,0x6
    800034e2:	f5a50513          	addi	a0,a0,-166 # 80009438 <states.1811+0x150>
    800034e6:	ffffd097          	auipc	ra,0xffffd
    800034ea:	0a8080e7          	jalr	168(ra) # 8000058e <printf>
    800034ee:	aacd                	j	800036e0 <syscall+0x478>
      else if(num == 12) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // sbrk
    800034f0:	6cbc                	ld	a5,88(s1)
    800034f2:	7bb8                	ld	a4,112(a5)
    800034f4:	00006617          	auipc	a2,0x6
    800034f8:	5dc63603          	ld	a2,1500(a2) # 80009ad0 <syscall_names+0x60>
    800034fc:	588c                	lw	a1,48(s1)
    800034fe:	00006517          	auipc	a0,0x6
    80003502:	f5250513          	addi	a0,a0,-174 # 80009450 <states.1811+0x168>
    80003506:	ffffd097          	auipc	ra,0xffffd
    8000350a:	088080e7          	jalr	136(ra) # 8000058e <printf>
    8000350e:	aac9                	j	800036e0 <syscall+0x478>
      else if(num == 13) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // sleep
    80003510:	6cbc                	ld	a5,88(s1)
    80003512:	7bb8                	ld	a4,112(a5)
    80003514:	00006617          	auipc	a2,0x6
    80003518:	5c463603          	ld	a2,1476(a2) # 80009ad8 <syscall_names+0x68>
    8000351c:	588c                	lw	a1,48(s1)
    8000351e:	00006517          	auipc	a0,0x6
    80003522:	f3250513          	addi	a0,a0,-206 # 80009450 <states.1811+0x168>
    80003526:	ffffd097          	auipc	ra,0xffffd
    8000352a:	068080e7          	jalr	104(ra) # 8000058e <printf>
    8000352e:	aa4d                	j	800036e0 <syscall+0x478>
      else if(num == 14) printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0); // uptime
    80003530:	6cbc                	ld	a5,88(s1)
    80003532:	7bb4                	ld	a3,112(a5)
    80003534:	00006617          	auipc	a2,0x6
    80003538:	5ac63603          	ld	a2,1452(a2) # 80009ae0 <syscall_names+0x70>
    8000353c:	588c                	lw	a1,48(s1)
    8000353e:	00006517          	auipc	a0,0x6
    80003542:	efa50513          	addi	a0,a0,-262 # 80009438 <states.1811+0x150>
    80003546:	ffffd097          	auipc	ra,0xffffd
    8000354a:	048080e7          	jalr	72(ra) # 8000058e <printf>
    8000354e:	aa49                	j	800036e0 <syscall+0x478>
      else if(num == 15) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a0); // open
    80003550:	6cb8                	ld	a4,88(s1)
    80003552:	7b3c                	ld	a5,112(a4)
    80003554:	6358                	ld	a4,128(a4)
    80003556:	00006617          	auipc	a2,0x6
    8000355a:	59263603          	ld	a2,1426(a2) # 80009ae8 <syscall_names+0x78>
    8000355e:	588c                	lw	a1,48(s1)
    80003560:	00006517          	auipc	a0,0x6
    80003564:	f3850513          	addi	a0,a0,-200 # 80009498 <states.1811+0x1b0>
    80003568:	ffffd097          	auipc	ra,0xffffd
    8000356c:	026080e7          	jalr	38(ra) # 8000058e <printf>
    80003570:	aa85                	j	800036e0 <syscall+0x478>
      else if(num == 16) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a3, p->trapframe->a0); // write
    80003572:	6cb8                	ld	a4,88(s1)
    80003574:	07073803          	ld	a6,112(a4)
    80003578:	675c                	ld	a5,136(a4)
    8000357a:	6358                	ld	a4,128(a4)
    8000357c:	00006617          	auipc	a2,0x6
    80003580:	57463603          	ld	a2,1396(a2) # 80009af0 <syscall_names+0x80>
    80003584:	588c                	lw	a1,48(s1)
    80003586:	00006517          	auipc	a0,0x6
    8000358a:	eea50513          	addi	a0,a0,-278 # 80009470 <states.1811+0x188>
    8000358e:	ffffd097          	auipc	ra,0xffffd
    80003592:	000080e7          	jalr	ra # 8000058e <printf>
    80003596:	a2a9                	j	800036e0 <syscall+0x478>
      else if(num == 17) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a3, p->trapframe->a0); // mknod
    80003598:	6cb8                	ld	a4,88(s1)
    8000359a:	07073803          	ld	a6,112(a4)
    8000359e:	675c                	ld	a5,136(a4)
    800035a0:	6358                	ld	a4,128(a4)
    800035a2:	00006617          	auipc	a2,0x6
    800035a6:	55663603          	ld	a2,1366(a2) # 80009af8 <syscall_names+0x88>
    800035aa:	588c                	lw	a1,48(s1)
    800035ac:	00006517          	auipc	a0,0x6
    800035b0:	ec450513          	addi	a0,a0,-316 # 80009470 <states.1811+0x188>
    800035b4:	ffffd097          	auipc	ra,0xffffd
    800035b8:	fda080e7          	jalr	-38(ra) # 8000058e <printf>
    800035bc:	a215                	j	800036e0 <syscall+0x478>
      else if(num == 18) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // unlink
    800035be:	6cbc                	ld	a5,88(s1)
    800035c0:	7bb8                	ld	a4,112(a5)
    800035c2:	00006617          	auipc	a2,0x6
    800035c6:	53e63603          	ld	a2,1342(a2) # 80009b00 <syscall_names+0x90>
    800035ca:	588c                	lw	a1,48(s1)
    800035cc:	00006517          	auipc	a0,0x6
    800035d0:	e8450513          	addi	a0,a0,-380 # 80009450 <states.1811+0x168>
    800035d4:	ffffd097          	auipc	ra,0xffffd
    800035d8:	fba080e7          	jalr	-70(ra) # 8000058e <printf>
    800035dc:	a211                	j	800036e0 <syscall+0x478>
      else if(num == 19) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a0); // link
    800035de:	6cb8                	ld	a4,88(s1)
    800035e0:	7b3c                	ld	a5,112(a4)
    800035e2:	6358                	ld	a4,128(a4)
    800035e4:	00006617          	auipc	a2,0x6
    800035e8:	52463603          	ld	a2,1316(a2) # 80009b08 <syscall_names+0x98>
    800035ec:	588c                	lw	a1,48(s1)
    800035ee:	00006517          	auipc	a0,0x6
    800035f2:	eaa50513          	addi	a0,a0,-342 # 80009498 <states.1811+0x1b0>
    800035f6:	ffffd097          	auipc	ra,0xffffd
    800035fa:	f98080e7          	jalr	-104(ra) # 8000058e <printf>
    800035fe:	a0cd                	j	800036e0 <syscall+0x478>
      else if(num == 20) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // mkdir
    80003600:	6cbc                	ld	a5,88(s1)
    80003602:	7bb8                	ld	a4,112(a5)
    80003604:	00006617          	auipc	a2,0x6
    80003608:	50c63603          	ld	a2,1292(a2) # 80009b10 <syscall_names+0xa0>
    8000360c:	588c                	lw	a1,48(s1)
    8000360e:	00006517          	auipc	a0,0x6
    80003612:	e4250513          	addi	a0,a0,-446 # 80009450 <states.1811+0x168>
    80003616:	ffffd097          	auipc	ra,0xffffd
    8000361a:	f78080e7          	jalr	-136(ra) # 8000058e <printf>
    8000361e:	a0c9                	j	800036e0 <syscall+0x478>
      else if(num == 21) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // close
    80003620:	6cbc                	ld	a5,88(s1)
    80003622:	7bb8                	ld	a4,112(a5)
    80003624:	00006617          	auipc	a2,0x6
    80003628:	4f463603          	ld	a2,1268(a2) # 80009b18 <syscall_names+0xa8>
    8000362c:	588c                	lw	a1,48(s1)
    8000362e:	00006517          	auipc	a0,0x6
    80003632:	e2250513          	addi	a0,a0,-478 # 80009450 <states.1811+0x168>
    80003636:	ffffd097          	auipc	ra,0xffffd
    8000363a:	f58080e7          	jalr	-168(ra) # 8000058e <printf>
    8000363e:	a04d                	j	800036e0 <syscall+0x478>
      else if(num == 22) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // trace
    80003640:	6cbc                	ld	a5,88(s1)
    80003642:	7bb8                	ld	a4,112(a5)
    80003644:	00006617          	auipc	a2,0x6
    80003648:	4dc63603          	ld	a2,1244(a2) # 80009b20 <syscall_names+0xb0>
    8000364c:	588c                	lw	a1,48(s1)
    8000364e:	00006517          	auipc	a0,0x6
    80003652:	e0250513          	addi	a0,a0,-510 # 80009450 <states.1811+0x168>
    80003656:	ffffd097          	auipc	ra,0xffffd
    8000365a:	f38080e7          	jalr	-200(ra) # 8000058e <printf>
    8000365e:	a049                	j	800036e0 <syscall+0x478>
      else if(num == 23) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a0); // sigalarm
    80003660:	6cb8                	ld	a4,88(s1)
    80003662:	7b3c                	ld	a5,112(a4)
    80003664:	6358                	ld	a4,128(a4)
    80003666:	00006617          	auipc	a2,0x6
    8000366a:	4c263603          	ld	a2,1218(a2) # 80009b28 <syscall_names+0xb8>
    8000366e:	588c                	lw	a1,48(s1)
    80003670:	00006517          	auipc	a0,0x6
    80003674:	e2850513          	addi	a0,a0,-472 # 80009498 <states.1811+0x1b0>
    80003678:	ffffd097          	auipc	ra,0xffffd
    8000367c:	f16080e7          	jalr	-234(ra) # 8000058e <printf>
    80003680:	a085                	j	800036e0 <syscall+0x478>
      else if(num == 24) printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0); // sigreturn
    80003682:	6cbc                	ld	a5,88(s1)
    80003684:	7bb4                	ld	a3,112(a5)
    80003686:	00006617          	auipc	a2,0x6
    8000368a:	4aa63603          	ld	a2,1194(a2) # 80009b30 <syscall_names+0xc0>
    8000368e:	588c                	lw	a1,48(s1)
    80003690:	00006517          	auipc	a0,0x6
    80003694:	da850513          	addi	a0,a0,-600 # 80009438 <states.1811+0x150>
    80003698:	ffffd097          	auipc	ra,0xffffd
    8000369c:	ef6080e7          	jalr	-266(ra) # 8000058e <printf>
    800036a0:	a081                	j	800036e0 <syscall+0x478>
      else if(num == 25) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // settickets
    800036a2:	6cbc                	ld	a5,88(s1)
    800036a4:	7bb8                	ld	a4,112(a5)
    800036a6:	00006617          	auipc	a2,0x6
    800036aa:	49263603          	ld	a2,1170(a2) # 80009b38 <syscall_names+0xc8>
    800036ae:	588c                	lw	a1,48(s1)
    800036b0:	00006517          	auipc	a0,0x6
    800036b4:	da050513          	addi	a0,a0,-608 # 80009450 <states.1811+0x168>
    800036b8:	ffffd097          	auipc	ra,0xffffd
    800036bc:	ed6080e7          	jalr	-298(ra) # 8000058e <printf>
    800036c0:	a005                	j	800036e0 <syscall+0x478>
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    800036c2:	86ce                	mv	a3,s3
    800036c4:	15848613          	addi	a2,s1,344
    800036c8:	588c                	lw	a1,48(s1)
    800036ca:	00006517          	auipc	a0,0x6
    800036ce:	dee50513          	addi	a0,a0,-530 # 800094b8 <states.1811+0x1d0>
    800036d2:	ffffd097          	auipc	ra,0xffffd
    800036d6:	ebc080e7          	jalr	-324(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800036da:	6cbc                	ld	a5,88(s1)
    800036dc:	577d                	li	a4,-1
    800036de:	fbb8                	sd	a4,112(a5)
  }
}
    800036e0:	70a2                	ld	ra,40(sp)
    800036e2:	7402                	ld	s0,32(sp)
    800036e4:	64e2                	ld	s1,24(sp)
    800036e6:	6942                	ld	s2,16(sp)
    800036e8:	69a2                	ld	s3,8(sp)
    800036ea:	6a02                	ld	s4,0(sp)
    800036ec:	6145                	addi	sp,sp,48
    800036ee:	8082                	ret

00000000800036f0 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800036f0:	1101                	addi	sp,sp,-32
    800036f2:	ec06                	sd	ra,24(sp)
    800036f4:	e822                	sd	s0,16(sp)
    800036f6:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    800036f8:	fec40593          	addi	a1,s0,-20
    800036fc:	4501                	li	a0,0
    800036fe:	00000097          	auipc	ra,0x0
    80003702:	af2080e7          	jalr	-1294(ra) # 800031f0 <argint>
  exit(n);
    80003706:	fec42503          	lw	a0,-20(s0)
    8000370a:	fffff097          	auipc	ra,0xfffff
    8000370e:	fd8080e7          	jalr	-40(ra) # 800026e2 <exit>
  return 0;  // not reached
}
    80003712:	4501                	li	a0,0
    80003714:	60e2                	ld	ra,24(sp)
    80003716:	6442                	ld	s0,16(sp)
    80003718:	6105                	addi	sp,sp,32
    8000371a:	8082                	ret

000000008000371c <sys_getpid>:

uint64
sys_getpid(void)
{
    8000371c:	1141                	addi	sp,sp,-16
    8000371e:	e406                	sd	ra,8(sp)
    80003720:	e022                	sd	s0,0(sp)
    80003722:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003724:	ffffe097          	auipc	ra,0xffffe
    80003728:	4a2080e7          	jalr	1186(ra) # 80001bc6 <myproc>
}
    8000372c:	5908                	lw	a0,48(a0)
    8000372e:	60a2                	ld	ra,8(sp)
    80003730:	6402                	ld	s0,0(sp)
    80003732:	0141                	addi	sp,sp,16
    80003734:	8082                	ret

0000000080003736 <sys_fork>:

uint64
sys_fork(void)
{
    80003736:	1141                	addi	sp,sp,-16
    80003738:	e406                	sd	ra,8(sp)
    8000373a:	e022                	sd	s0,0(sp)
    8000373c:	0800                	addi	s0,sp,16
  return fork();
    8000373e:	fffff097          	auipc	ra,0xfffff
    80003742:	8a0080e7          	jalr	-1888(ra) # 80001fde <fork>
}
    80003746:	60a2                	ld	ra,8(sp)
    80003748:	6402                	ld	s0,0(sp)
    8000374a:	0141                	addi	sp,sp,16
    8000374c:	8082                	ret

000000008000374e <sys_wait>:

uint64
sys_wait(void)
{
    8000374e:	1101                	addi	sp,sp,-32
    80003750:	ec06                	sd	ra,24(sp)
    80003752:	e822                	sd	s0,16(sp)
    80003754:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003756:	fe840593          	addi	a1,s0,-24
    8000375a:	4501                	li	a0,0
    8000375c:	00000097          	auipc	ra,0x0
    80003760:	ab4080e7          	jalr	-1356(ra) # 80003210 <argaddr>
  return wait(p);
    80003764:	fe843503          	ld	a0,-24(s0)
    80003768:	fffff097          	auipc	ra,0xfffff
    8000376c:	12c080e7          	jalr	300(ra) # 80002894 <wait>
}
    80003770:	60e2                	ld	ra,24(sp)
    80003772:	6442                	ld	s0,16(sp)
    80003774:	6105                	addi	sp,sp,32
    80003776:	8082                	ret

0000000080003778 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003778:	7179                	addi	sp,sp,-48
    8000377a:	f406                	sd	ra,40(sp)
    8000377c:	f022                	sd	s0,32(sp)
    8000377e:	ec26                	sd	s1,24(sp)
    80003780:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80003782:	fdc40593          	addi	a1,s0,-36
    80003786:	4501                	li	a0,0
    80003788:	00000097          	auipc	ra,0x0
    8000378c:	a68080e7          	jalr	-1432(ra) # 800031f0 <argint>
  addr = myproc()->sz;
    80003790:	ffffe097          	auipc	ra,0xffffe
    80003794:	436080e7          	jalr	1078(ra) # 80001bc6 <myproc>
    80003798:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    8000379a:	fdc42503          	lw	a0,-36(s0)
    8000379e:	ffffe097          	auipc	ra,0xffffe
    800037a2:	7e4080e7          	jalr	2020(ra) # 80001f82 <growproc>
    800037a6:	00054863          	bltz	a0,800037b6 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    800037aa:	8526                	mv	a0,s1
    800037ac:	70a2                	ld	ra,40(sp)
    800037ae:	7402                	ld	s0,32(sp)
    800037b0:	64e2                	ld	s1,24(sp)
    800037b2:	6145                	addi	sp,sp,48
    800037b4:	8082                	ret
    return -1;
    800037b6:	54fd                	li	s1,-1
    800037b8:	bfcd                	j	800037aa <sys_sbrk+0x32>

00000000800037ba <sys_sleep>:

uint64
sys_sleep(void)
{
    800037ba:	7139                	addi	sp,sp,-64
    800037bc:	fc06                	sd	ra,56(sp)
    800037be:	f822                	sd	s0,48(sp)
    800037c0:	f426                	sd	s1,40(sp)
    800037c2:	f04a                	sd	s2,32(sp)
    800037c4:	ec4e                	sd	s3,24(sp)
    800037c6:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800037c8:	fcc40593          	addi	a1,s0,-52
    800037cc:	4501                	li	a0,0
    800037ce:	00000097          	auipc	ra,0x0
    800037d2:	a22080e7          	jalr	-1502(ra) # 800031f0 <argint>
  acquire(&tickslock);
    800037d6:	00016517          	auipc	a0,0x16
    800037da:	6e250513          	addi	a0,a0,1762 # 80019eb8 <tickslock>
    800037de:	ffffd097          	auipc	ra,0xffffd
    800037e2:	40c080e7          	jalr	1036(ra) # 80000bea <acquire>
  ticks0 = ticks;
    800037e6:	00006917          	auipc	s2,0x6
    800037ea:	3ba92903          	lw	s2,954(s2) # 80009ba0 <ticks>
  while(ticks - ticks0 < n){
    800037ee:	fcc42783          	lw	a5,-52(s0)
    800037f2:	cf9d                	beqz	a5,80003830 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800037f4:	00016997          	auipc	s3,0x16
    800037f8:	6c498993          	addi	s3,s3,1732 # 80019eb8 <tickslock>
    800037fc:	00006497          	auipc	s1,0x6
    80003800:	3a448493          	addi	s1,s1,932 # 80009ba0 <ticks>
    if(killed(myproc())){
    80003804:	ffffe097          	auipc	ra,0xffffe
    80003808:	3c2080e7          	jalr	962(ra) # 80001bc6 <myproc>
    8000380c:	fffff097          	auipc	ra,0xfffff
    80003810:	056080e7          	jalr	86(ra) # 80002862 <killed>
    80003814:	ed15                	bnez	a0,80003850 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003816:	85ce                	mv	a1,s3
    80003818:	8526                	mv	a0,s1
    8000381a:	fffff097          	auipc	ra,0xfffff
    8000381e:	c48080e7          	jalr	-952(ra) # 80002462 <sleep>
  while(ticks - ticks0 < n){
    80003822:	409c                	lw	a5,0(s1)
    80003824:	412787bb          	subw	a5,a5,s2
    80003828:	fcc42703          	lw	a4,-52(s0)
    8000382c:	fce7ece3          	bltu	a5,a4,80003804 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003830:	00016517          	auipc	a0,0x16
    80003834:	68850513          	addi	a0,a0,1672 # 80019eb8 <tickslock>
    80003838:	ffffd097          	auipc	ra,0xffffd
    8000383c:	466080e7          	jalr	1126(ra) # 80000c9e <release>
  return 0;
    80003840:	4501                	li	a0,0
}
    80003842:	70e2                	ld	ra,56(sp)
    80003844:	7442                	ld	s0,48(sp)
    80003846:	74a2                	ld	s1,40(sp)
    80003848:	7902                	ld	s2,32(sp)
    8000384a:	69e2                	ld	s3,24(sp)
    8000384c:	6121                	addi	sp,sp,64
    8000384e:	8082                	ret
      release(&tickslock);
    80003850:	00016517          	auipc	a0,0x16
    80003854:	66850513          	addi	a0,a0,1640 # 80019eb8 <tickslock>
    80003858:	ffffd097          	auipc	ra,0xffffd
    8000385c:	446080e7          	jalr	1094(ra) # 80000c9e <release>
      return -1;
    80003860:	557d                	li	a0,-1
    80003862:	b7c5                	j	80003842 <sys_sleep+0x88>

0000000080003864 <sys_kill>:

uint64
sys_kill(void)
{
    80003864:	1101                	addi	sp,sp,-32
    80003866:	ec06                	sd	ra,24(sp)
    80003868:	e822                	sd	s0,16(sp)
    8000386a:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    8000386c:	fec40593          	addi	a1,s0,-20
    80003870:	4501                	li	a0,0
    80003872:	00000097          	auipc	ra,0x0
    80003876:	97e080e7          	jalr	-1666(ra) # 800031f0 <argint>
  return kill(pid);
    8000387a:	fec42503          	lw	a0,-20(s0)
    8000387e:	fffff097          	auipc	ra,0xfffff
    80003882:	f46080e7          	jalr	-186(ra) # 800027c4 <kill>
}
    80003886:	60e2                	ld	ra,24(sp)
    80003888:	6442                	ld	s0,16(sp)
    8000388a:	6105                	addi	sp,sp,32
    8000388c:	8082                	ret

000000008000388e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000388e:	1101                	addi	sp,sp,-32
    80003890:	ec06                	sd	ra,24(sp)
    80003892:	e822                	sd	s0,16(sp)
    80003894:	e426                	sd	s1,8(sp)
    80003896:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003898:	00016517          	auipc	a0,0x16
    8000389c:	62050513          	addi	a0,a0,1568 # 80019eb8 <tickslock>
    800038a0:	ffffd097          	auipc	ra,0xffffd
    800038a4:	34a080e7          	jalr	842(ra) # 80000bea <acquire>
  xticks = ticks;
    800038a8:	00006497          	auipc	s1,0x6
    800038ac:	2f84a483          	lw	s1,760(s1) # 80009ba0 <ticks>
  release(&tickslock);
    800038b0:	00016517          	auipc	a0,0x16
    800038b4:	60850513          	addi	a0,a0,1544 # 80019eb8 <tickslock>
    800038b8:	ffffd097          	auipc	ra,0xffffd
    800038bc:	3e6080e7          	jalr	998(ra) # 80000c9e <release>
  return xticks;
}
    800038c0:	02049513          	slli	a0,s1,0x20
    800038c4:	9101                	srli	a0,a0,0x20
    800038c6:	60e2                	ld	ra,24(sp)
    800038c8:	6442                	ld	s0,16(sp)
    800038ca:	64a2                	ld	s1,8(sp)
    800038cc:	6105                	addi	sp,sp,32
    800038ce:	8082                	ret

00000000800038d0 <sys_trace>:

// sets the trace_flag to the first argument (a0)
uint64
sys_trace(void)
{
    800038d0:	1141                	addi	sp,sp,-16
    800038d2:	e406                	sd	ra,8(sp)
    800038d4:	e022                	sd	s0,0(sp)
    800038d6:	0800                	addi	s0,sp,16
  argint(0, &myproc()->trace_flag); //arg(a0, trace_flag) // returns void
    800038d8:	ffffe097          	auipc	ra,0xffffe
    800038dc:	2ee080e7          	jalr	750(ra) # 80001bc6 <myproc>
    800038e0:	17450593          	addi	a1,a0,372
    800038e4:	4501                	li	a0,0
    800038e6:	00000097          	auipc	ra,0x0
    800038ea:	90a080e7          	jalr	-1782(ra) # 800031f0 <argint>
  return 0;
}
    800038ee:	4501                	li	a0,0
    800038f0:	60a2                	ld	ra,8(sp)
    800038f2:	6402                	ld	s0,0(sp)
    800038f4:	0141                	addi	sp,sp,16
    800038f6:	8082                	ret

00000000800038f8 <sys_sigalarm>:

// sets the 
uint64
sys_sigalarm(void)
{
    800038f8:	1101                	addi	sp,sp,-32
    800038fa:	ec06                	sd	ra,24(sp)
    800038fc:	e822                	sd	s0,16(sp)
    800038fe:	e426                	sd	s1,8(sp)
    80003900:	1000                	addi	s0,sp,32
  // sets the interval and handler after every tick
  argint(0, &myproc()->interval);
    80003902:	ffffe097          	auipc	ra,0xffffe
    80003906:	2c4080e7          	jalr	708(ra) # 80001bc6 <myproc>
    8000390a:	17850593          	addi	a1,a0,376
    8000390e:	4501                	li	a0,0
    80003910:	00000097          	auipc	ra,0x0
    80003914:	8e0080e7          	jalr	-1824(ra) # 800031f0 <argint>
  argaddr(1, &myproc()->sig_handler);
    80003918:	ffffe097          	auipc	ra,0xffffe
    8000391c:	2ae080e7          	jalr	686(ra) # 80001bc6 <myproc>
    80003920:	18050593          	addi	a1,a0,384
    80003924:	4505                	li	a0,1
    80003926:	00000097          	auipc	ra,0x0
    8000392a:	8ea080e7          	jalr	-1814(ra) # 80003210 <argaddr>
  
  // sets ticks_passed as the interval
  myproc()->ticks_left = myproc()->interval;
    8000392e:	ffffe097          	auipc	ra,0xffffe
    80003932:	298080e7          	jalr	664(ra) # 80001bc6 <myproc>
    80003936:	84aa                	mv	s1,a0
    80003938:	ffffe097          	auipc	ra,0xffffe
    8000393c:	28e080e7          	jalr	654(ra) # 80001bc6 <myproc>
    80003940:	1784a783          	lw	a5,376(s1)
    80003944:	16f52e23          	sw	a5,380(a0)
  return 0;
}
    80003948:	4501                	li	a0,0
    8000394a:	60e2                	ld	ra,24(sp)
    8000394c:	6442                	ld	s0,16(sp)
    8000394e:	64a2                	ld	s1,8(sp)
    80003950:	6105                	addi	sp,sp,32
    80003952:	8082                	ret

0000000080003954 <sys_sigreturn>:

uint64 
sys_sigreturn(void)
{
    80003954:	1101                	addi	sp,sp,-32
    80003956:	ec06                	sd	ra,24(sp)
    80003958:	e822                	sd	s0,16(sp)
    8000395a:	e426                	sd	s1,8(sp)
    8000395c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000395e:	ffffe097          	auipc	ra,0xffffe
    80003962:	268080e7          	jalr	616(ra) # 80001bc6 <myproc>
    80003966:	84aa                	mv	s1,a0
  memmove(p->trapframe, p->sigalarm_tf, PGSIZE);
    80003968:	6605                	lui	a2,0x1
    8000396a:	18853583          	ld	a1,392(a0)
    8000396e:	6d28                	ld	a0,88(a0)
    80003970:	ffffd097          	auipc	ra,0xffffd
    80003974:	3d6080e7          	jalr	982(ra) # 80000d46 <memmove>
  kfree(p->sigalarm_tf);
    80003978:	1884b503          	ld	a0,392(s1)
    8000397c:	ffffd097          	auipc	ra,0xffffd
    80003980:	082080e7          	jalr	130(ra) # 800009fe <kfree>
  p->ticks_left = p->interval;
    80003984:	1784a783          	lw	a5,376(s1)
    80003988:	16f4ae23          	sw	a5,380(s1)
  return p->trapframe->a0;
    8000398c:	6cbc                	ld	a5,88(s1)
}
    8000398e:	7ba8                	ld	a0,112(a5)
    80003990:	60e2                	ld	ra,24(sp)
    80003992:	6442                	ld	s0,16(sp)
    80003994:	64a2                	ld	s1,8(sp)
    80003996:	6105                	addi	sp,sp,32
    80003998:	8082                	ret

000000008000399a <sys_settickets>:

uint64 
sys_settickets(void)
{
    8000399a:	1141                	addi	sp,sp,-16
    8000399c:	e406                	sd	ra,8(sp)
    8000399e:	e022                	sd	s0,0(sp)
    800039a0:	0800                	addi	s0,sp,16
  argint(0, &myproc()->tickets);
    800039a2:	ffffe097          	auipc	ra,0xffffe
    800039a6:	224080e7          	jalr	548(ra) # 80001bc6 <myproc>
    800039aa:	19450593          	addi	a1,a0,404
    800039ae:	4501                	li	a0,0
    800039b0:	00000097          	auipc	ra,0x0
    800039b4:	840080e7          	jalr	-1984(ra) # 800031f0 <argint>
  return myproc()->tickets;
    800039b8:	ffffe097          	auipc	ra,0xffffe
    800039bc:	20e080e7          	jalr	526(ra) # 80001bc6 <myproc>
}
    800039c0:	19452503          	lw	a0,404(a0)
    800039c4:	60a2                	ld	ra,8(sp)
    800039c6:	6402                	ld	s0,0(sp)
    800039c8:	0141                	addi	sp,sp,16
    800039ca:	8082                	ret

00000000800039cc <sys_waitx>:

uint64
sys_waitx(void)
{
    800039cc:	7139                	addi	sp,sp,-64
    800039ce:	fc06                	sd	ra,56(sp)
    800039d0:	f822                	sd	s0,48(sp)
    800039d2:	f426                	sd	s1,40(sp)
    800039d4:	f04a                	sd	s2,32(sp)
    800039d6:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800039d8:	fd840593          	addi	a1,s0,-40
    800039dc:	4501                	li	a0,0
    800039de:	00000097          	auipc	ra,0x0
    800039e2:	832080e7          	jalr	-1998(ra) # 80003210 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    800039e6:	fd040593          	addi	a1,s0,-48
    800039ea:	4505                	li	a0,1
    800039ec:	00000097          	auipc	ra,0x0
    800039f0:	824080e7          	jalr	-2012(ra) # 80003210 <argaddr>
  argaddr(2, &addr2);
    800039f4:	fc840593          	addi	a1,s0,-56
    800039f8:	4509                	li	a0,2
    800039fa:	00000097          	auipc	ra,0x0
    800039fe:	816080e7          	jalr	-2026(ra) # 80003210 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003a02:	fc040613          	addi	a2,s0,-64
    80003a06:	fc440593          	addi	a1,s0,-60
    80003a0a:	fd843503          	ld	a0,-40(s0)
    80003a0e:	fffff097          	auipc	ra,0xfffff
    80003a12:	ab8080e7          	jalr	-1352(ra) # 800024c6 <waitx>
    80003a16:	892a                	mv	s2,a0
  struct proc* p = myproc();
    80003a18:	ffffe097          	auipc	ra,0xffffe
    80003a1c:	1ae080e7          	jalr	430(ra) # 80001bc6 <myproc>
    80003a20:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80003a22:	4691                	li	a3,4
    80003a24:	fc440613          	addi	a2,s0,-60
    80003a28:	fd043583          	ld	a1,-48(s0)
    80003a2c:	6928                	ld	a0,80(a0)
    80003a2e:	ffffe097          	auipc	ra,0xffffe
    80003a32:	c56080e7          	jalr	-938(ra) # 80001684 <copyout>
    return -1;
    80003a36:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80003a38:	00054f63          	bltz	a0,80003a56 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    80003a3c:	4691                	li	a3,4
    80003a3e:	fc040613          	addi	a2,s0,-64
    80003a42:	fc843583          	ld	a1,-56(s0)
    80003a46:	68a8                	ld	a0,80(s1)
    80003a48:	ffffe097          	auipc	ra,0xffffe
    80003a4c:	c3c080e7          	jalr	-964(ra) # 80001684 <copyout>
    80003a50:	00054a63          	bltz	a0,80003a64 <sys_waitx+0x98>
    return -1;
  return ret;
    80003a54:	87ca                	mv	a5,s2
}
    80003a56:	853e                	mv	a0,a5
    80003a58:	70e2                	ld	ra,56(sp)
    80003a5a:	7442                	ld	s0,48(sp)
    80003a5c:	74a2                	ld	s1,40(sp)
    80003a5e:	7902                	ld	s2,32(sp)
    80003a60:	6121                	addi	sp,sp,64
    80003a62:	8082                	ret
    return -1;
    80003a64:	57fd                	li	a5,-1
    80003a66:	bfc5                	j	80003a56 <sys_waitx+0x8a>

0000000080003a68 <sys_setpriority>:

uint64
sys_setpriority(void)
{
    80003a68:	1101                	addi	sp,sp,-32
    80003a6a:	ec06                	sd	ra,24(sp)
    80003a6c:	e822                	sd	s0,16(sp)
    80003a6e:	1000                	addi	s0,sp,32
  int new_priority, proc_pid;

  argint(0, &new_priority);
    80003a70:	fec40593          	addi	a1,s0,-20
    80003a74:	4501                	li	a0,0
    80003a76:	fffff097          	auipc	ra,0xfffff
    80003a7a:	77a080e7          	jalr	1914(ra) # 800031f0 <argint>
  argint(1, &proc_pid);
    80003a7e:	fe840593          	addi	a1,s0,-24
    80003a82:	4505                	li	a0,1
    80003a84:	fffff097          	auipc	ra,0xfffff
    80003a88:	76c080e7          	jalr	1900(ra) # 800031f0 <argint>
  return setpriority(new_priority, proc_pid);
    80003a8c:	fe842583          	lw	a1,-24(s0)
    80003a90:	fec42503          	lw	a0,-20(s0)
    80003a94:	fffff097          	auipc	ra,0xfffff
    80003a98:	088080e7          	jalr	136(ra) # 80002b1c <setpriority>
}
    80003a9c:	60e2                	ld	ra,24(sp)
    80003a9e:	6442                	ld	s0,16(sp)
    80003aa0:	6105                	addi	sp,sp,32
    80003aa2:	8082                	ret

0000000080003aa4 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003aa4:	7179                	addi	sp,sp,-48
    80003aa6:	f406                	sd	ra,40(sp)
    80003aa8:	f022                	sd	s0,32(sp)
    80003aaa:	ec26                	sd	s1,24(sp)
    80003aac:	e84a                	sd	s2,16(sp)
    80003aae:	e44e                	sd	s3,8(sp)
    80003ab0:	e052                	sd	s4,0(sp)
    80003ab2:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003ab4:	00006597          	auipc	a1,0x6
    80003ab8:	c1458593          	addi	a1,a1,-1004 # 800096c8 <syscalls+0xe0>
    80003abc:	00016517          	auipc	a0,0x16
    80003ac0:	41450513          	addi	a0,a0,1044 # 80019ed0 <bcache>
    80003ac4:	ffffd097          	auipc	ra,0xffffd
    80003ac8:	096080e7          	jalr	150(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003acc:	0001e797          	auipc	a5,0x1e
    80003ad0:	40478793          	addi	a5,a5,1028 # 80021ed0 <bcache+0x8000>
    80003ad4:	0001e717          	auipc	a4,0x1e
    80003ad8:	66470713          	addi	a4,a4,1636 # 80022138 <bcache+0x8268>
    80003adc:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003ae0:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003ae4:	00016497          	auipc	s1,0x16
    80003ae8:	40448493          	addi	s1,s1,1028 # 80019ee8 <bcache+0x18>
    b->next = bcache.head.next;
    80003aec:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003aee:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003af0:	00006a17          	auipc	s4,0x6
    80003af4:	be0a0a13          	addi	s4,s4,-1056 # 800096d0 <syscalls+0xe8>
    b->next = bcache.head.next;
    80003af8:	2b893783          	ld	a5,696(s2)
    80003afc:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003afe:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003b02:	85d2                	mv	a1,s4
    80003b04:	01048513          	addi	a0,s1,16
    80003b08:	00001097          	auipc	ra,0x1
    80003b0c:	4c4080e7          	jalr	1220(ra) # 80004fcc <initsleeplock>
    bcache.head.next->prev = b;
    80003b10:	2b893783          	ld	a5,696(s2)
    80003b14:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003b16:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003b1a:	45848493          	addi	s1,s1,1112
    80003b1e:	fd349de3          	bne	s1,s3,80003af8 <binit+0x54>
  }
}
    80003b22:	70a2                	ld	ra,40(sp)
    80003b24:	7402                	ld	s0,32(sp)
    80003b26:	64e2                	ld	s1,24(sp)
    80003b28:	6942                	ld	s2,16(sp)
    80003b2a:	69a2                	ld	s3,8(sp)
    80003b2c:	6a02                	ld	s4,0(sp)
    80003b2e:	6145                	addi	sp,sp,48
    80003b30:	8082                	ret

0000000080003b32 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003b32:	7179                	addi	sp,sp,-48
    80003b34:	f406                	sd	ra,40(sp)
    80003b36:	f022                	sd	s0,32(sp)
    80003b38:	ec26                	sd	s1,24(sp)
    80003b3a:	e84a                	sd	s2,16(sp)
    80003b3c:	e44e                	sd	s3,8(sp)
    80003b3e:	1800                	addi	s0,sp,48
    80003b40:	89aa                	mv	s3,a0
    80003b42:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003b44:	00016517          	auipc	a0,0x16
    80003b48:	38c50513          	addi	a0,a0,908 # 80019ed0 <bcache>
    80003b4c:	ffffd097          	auipc	ra,0xffffd
    80003b50:	09e080e7          	jalr	158(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003b54:	0001e497          	auipc	s1,0x1e
    80003b58:	6344b483          	ld	s1,1588(s1) # 80022188 <bcache+0x82b8>
    80003b5c:	0001e797          	auipc	a5,0x1e
    80003b60:	5dc78793          	addi	a5,a5,1500 # 80022138 <bcache+0x8268>
    80003b64:	02f48f63          	beq	s1,a5,80003ba2 <bread+0x70>
    80003b68:	873e                	mv	a4,a5
    80003b6a:	a021                	j	80003b72 <bread+0x40>
    80003b6c:	68a4                	ld	s1,80(s1)
    80003b6e:	02e48a63          	beq	s1,a4,80003ba2 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003b72:	449c                	lw	a5,8(s1)
    80003b74:	ff379ce3          	bne	a5,s3,80003b6c <bread+0x3a>
    80003b78:	44dc                	lw	a5,12(s1)
    80003b7a:	ff2799e3          	bne	a5,s2,80003b6c <bread+0x3a>
      b->refcnt++;
    80003b7e:	40bc                	lw	a5,64(s1)
    80003b80:	2785                	addiw	a5,a5,1
    80003b82:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003b84:	00016517          	auipc	a0,0x16
    80003b88:	34c50513          	addi	a0,a0,844 # 80019ed0 <bcache>
    80003b8c:	ffffd097          	auipc	ra,0xffffd
    80003b90:	112080e7          	jalr	274(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80003b94:	01048513          	addi	a0,s1,16
    80003b98:	00001097          	auipc	ra,0x1
    80003b9c:	46e080e7          	jalr	1134(ra) # 80005006 <acquiresleep>
      return b;
    80003ba0:	a8b9                	j	80003bfe <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003ba2:	0001e497          	auipc	s1,0x1e
    80003ba6:	5de4b483          	ld	s1,1502(s1) # 80022180 <bcache+0x82b0>
    80003baa:	0001e797          	auipc	a5,0x1e
    80003bae:	58e78793          	addi	a5,a5,1422 # 80022138 <bcache+0x8268>
    80003bb2:	00f48863          	beq	s1,a5,80003bc2 <bread+0x90>
    80003bb6:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003bb8:	40bc                	lw	a5,64(s1)
    80003bba:	cf81                	beqz	a5,80003bd2 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003bbc:	64a4                	ld	s1,72(s1)
    80003bbe:	fee49de3          	bne	s1,a4,80003bb8 <bread+0x86>
  panic("bget: no buffers");
    80003bc2:	00006517          	auipc	a0,0x6
    80003bc6:	b1650513          	addi	a0,a0,-1258 # 800096d8 <syscalls+0xf0>
    80003bca:	ffffd097          	auipc	ra,0xffffd
    80003bce:	97a080e7          	jalr	-1670(ra) # 80000544 <panic>
      b->dev = dev;
    80003bd2:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003bd6:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003bda:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003bde:	4785                	li	a5,1
    80003be0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003be2:	00016517          	auipc	a0,0x16
    80003be6:	2ee50513          	addi	a0,a0,750 # 80019ed0 <bcache>
    80003bea:	ffffd097          	auipc	ra,0xffffd
    80003bee:	0b4080e7          	jalr	180(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80003bf2:	01048513          	addi	a0,s1,16
    80003bf6:	00001097          	auipc	ra,0x1
    80003bfa:	410080e7          	jalr	1040(ra) # 80005006 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003bfe:	409c                	lw	a5,0(s1)
    80003c00:	cb89                	beqz	a5,80003c12 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003c02:	8526                	mv	a0,s1
    80003c04:	70a2                	ld	ra,40(sp)
    80003c06:	7402                	ld	s0,32(sp)
    80003c08:	64e2                	ld	s1,24(sp)
    80003c0a:	6942                	ld	s2,16(sp)
    80003c0c:	69a2                	ld	s3,8(sp)
    80003c0e:	6145                	addi	sp,sp,48
    80003c10:	8082                	ret
    virtio_disk_rw(b, 0);
    80003c12:	4581                	li	a1,0
    80003c14:	8526                	mv	a0,s1
    80003c16:	00003097          	auipc	ra,0x3
    80003c1a:	fd2080e7          	jalr	-46(ra) # 80006be8 <virtio_disk_rw>
    b->valid = 1;
    80003c1e:	4785                	li	a5,1
    80003c20:	c09c                	sw	a5,0(s1)
  return b;
    80003c22:	b7c5                	j	80003c02 <bread+0xd0>

0000000080003c24 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003c24:	1101                	addi	sp,sp,-32
    80003c26:	ec06                	sd	ra,24(sp)
    80003c28:	e822                	sd	s0,16(sp)
    80003c2a:	e426                	sd	s1,8(sp)
    80003c2c:	1000                	addi	s0,sp,32
    80003c2e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003c30:	0541                	addi	a0,a0,16
    80003c32:	00001097          	auipc	ra,0x1
    80003c36:	46e080e7          	jalr	1134(ra) # 800050a0 <holdingsleep>
    80003c3a:	cd01                	beqz	a0,80003c52 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003c3c:	4585                	li	a1,1
    80003c3e:	8526                	mv	a0,s1
    80003c40:	00003097          	auipc	ra,0x3
    80003c44:	fa8080e7          	jalr	-88(ra) # 80006be8 <virtio_disk_rw>
}
    80003c48:	60e2                	ld	ra,24(sp)
    80003c4a:	6442                	ld	s0,16(sp)
    80003c4c:	64a2                	ld	s1,8(sp)
    80003c4e:	6105                	addi	sp,sp,32
    80003c50:	8082                	ret
    panic("bwrite");
    80003c52:	00006517          	auipc	a0,0x6
    80003c56:	a9e50513          	addi	a0,a0,-1378 # 800096f0 <syscalls+0x108>
    80003c5a:	ffffd097          	auipc	ra,0xffffd
    80003c5e:	8ea080e7          	jalr	-1814(ra) # 80000544 <panic>

0000000080003c62 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003c62:	1101                	addi	sp,sp,-32
    80003c64:	ec06                	sd	ra,24(sp)
    80003c66:	e822                	sd	s0,16(sp)
    80003c68:	e426                	sd	s1,8(sp)
    80003c6a:	e04a                	sd	s2,0(sp)
    80003c6c:	1000                	addi	s0,sp,32
    80003c6e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003c70:	01050913          	addi	s2,a0,16
    80003c74:	854a                	mv	a0,s2
    80003c76:	00001097          	auipc	ra,0x1
    80003c7a:	42a080e7          	jalr	1066(ra) # 800050a0 <holdingsleep>
    80003c7e:	c92d                	beqz	a0,80003cf0 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003c80:	854a                	mv	a0,s2
    80003c82:	00001097          	auipc	ra,0x1
    80003c86:	3da080e7          	jalr	986(ra) # 8000505c <releasesleep>

  acquire(&bcache.lock);
    80003c8a:	00016517          	auipc	a0,0x16
    80003c8e:	24650513          	addi	a0,a0,582 # 80019ed0 <bcache>
    80003c92:	ffffd097          	auipc	ra,0xffffd
    80003c96:	f58080e7          	jalr	-168(ra) # 80000bea <acquire>
  b->refcnt--;
    80003c9a:	40bc                	lw	a5,64(s1)
    80003c9c:	37fd                	addiw	a5,a5,-1
    80003c9e:	0007871b          	sext.w	a4,a5
    80003ca2:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003ca4:	eb05                	bnez	a4,80003cd4 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003ca6:	68bc                	ld	a5,80(s1)
    80003ca8:	64b8                	ld	a4,72(s1)
    80003caa:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003cac:	64bc                	ld	a5,72(s1)
    80003cae:	68b8                	ld	a4,80(s1)
    80003cb0:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003cb2:	0001e797          	auipc	a5,0x1e
    80003cb6:	21e78793          	addi	a5,a5,542 # 80021ed0 <bcache+0x8000>
    80003cba:	2b87b703          	ld	a4,696(a5)
    80003cbe:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003cc0:	0001e717          	auipc	a4,0x1e
    80003cc4:	47870713          	addi	a4,a4,1144 # 80022138 <bcache+0x8268>
    80003cc8:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003cca:	2b87b703          	ld	a4,696(a5)
    80003cce:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003cd0:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003cd4:	00016517          	auipc	a0,0x16
    80003cd8:	1fc50513          	addi	a0,a0,508 # 80019ed0 <bcache>
    80003cdc:	ffffd097          	auipc	ra,0xffffd
    80003ce0:	fc2080e7          	jalr	-62(ra) # 80000c9e <release>
}
    80003ce4:	60e2                	ld	ra,24(sp)
    80003ce6:	6442                	ld	s0,16(sp)
    80003ce8:	64a2                	ld	s1,8(sp)
    80003cea:	6902                	ld	s2,0(sp)
    80003cec:	6105                	addi	sp,sp,32
    80003cee:	8082                	ret
    panic("brelse");
    80003cf0:	00006517          	auipc	a0,0x6
    80003cf4:	a0850513          	addi	a0,a0,-1528 # 800096f8 <syscalls+0x110>
    80003cf8:	ffffd097          	auipc	ra,0xffffd
    80003cfc:	84c080e7          	jalr	-1972(ra) # 80000544 <panic>

0000000080003d00 <bpin>:

void
bpin(struct buf *b) {
    80003d00:	1101                	addi	sp,sp,-32
    80003d02:	ec06                	sd	ra,24(sp)
    80003d04:	e822                	sd	s0,16(sp)
    80003d06:	e426                	sd	s1,8(sp)
    80003d08:	1000                	addi	s0,sp,32
    80003d0a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003d0c:	00016517          	auipc	a0,0x16
    80003d10:	1c450513          	addi	a0,a0,452 # 80019ed0 <bcache>
    80003d14:	ffffd097          	auipc	ra,0xffffd
    80003d18:	ed6080e7          	jalr	-298(ra) # 80000bea <acquire>
  b->refcnt++;
    80003d1c:	40bc                	lw	a5,64(s1)
    80003d1e:	2785                	addiw	a5,a5,1
    80003d20:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003d22:	00016517          	auipc	a0,0x16
    80003d26:	1ae50513          	addi	a0,a0,430 # 80019ed0 <bcache>
    80003d2a:	ffffd097          	auipc	ra,0xffffd
    80003d2e:	f74080e7          	jalr	-140(ra) # 80000c9e <release>
}
    80003d32:	60e2                	ld	ra,24(sp)
    80003d34:	6442                	ld	s0,16(sp)
    80003d36:	64a2                	ld	s1,8(sp)
    80003d38:	6105                	addi	sp,sp,32
    80003d3a:	8082                	ret

0000000080003d3c <bunpin>:

void
bunpin(struct buf *b) {
    80003d3c:	1101                	addi	sp,sp,-32
    80003d3e:	ec06                	sd	ra,24(sp)
    80003d40:	e822                	sd	s0,16(sp)
    80003d42:	e426                	sd	s1,8(sp)
    80003d44:	1000                	addi	s0,sp,32
    80003d46:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003d48:	00016517          	auipc	a0,0x16
    80003d4c:	18850513          	addi	a0,a0,392 # 80019ed0 <bcache>
    80003d50:	ffffd097          	auipc	ra,0xffffd
    80003d54:	e9a080e7          	jalr	-358(ra) # 80000bea <acquire>
  b->refcnt--;
    80003d58:	40bc                	lw	a5,64(s1)
    80003d5a:	37fd                	addiw	a5,a5,-1
    80003d5c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003d5e:	00016517          	auipc	a0,0x16
    80003d62:	17250513          	addi	a0,a0,370 # 80019ed0 <bcache>
    80003d66:	ffffd097          	auipc	ra,0xffffd
    80003d6a:	f38080e7          	jalr	-200(ra) # 80000c9e <release>
}
    80003d6e:	60e2                	ld	ra,24(sp)
    80003d70:	6442                	ld	s0,16(sp)
    80003d72:	64a2                	ld	s1,8(sp)
    80003d74:	6105                	addi	sp,sp,32
    80003d76:	8082                	ret

0000000080003d78 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003d78:	1101                	addi	sp,sp,-32
    80003d7a:	ec06                	sd	ra,24(sp)
    80003d7c:	e822                	sd	s0,16(sp)
    80003d7e:	e426                	sd	s1,8(sp)
    80003d80:	e04a                	sd	s2,0(sp)
    80003d82:	1000                	addi	s0,sp,32
    80003d84:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003d86:	00d5d59b          	srliw	a1,a1,0xd
    80003d8a:	0001f797          	auipc	a5,0x1f
    80003d8e:	8227a783          	lw	a5,-2014(a5) # 800225ac <sb+0x1c>
    80003d92:	9dbd                	addw	a1,a1,a5
    80003d94:	00000097          	auipc	ra,0x0
    80003d98:	d9e080e7          	jalr	-610(ra) # 80003b32 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003d9c:	0074f713          	andi	a4,s1,7
    80003da0:	4785                	li	a5,1
    80003da2:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003da6:	14ce                	slli	s1,s1,0x33
    80003da8:	90d9                	srli	s1,s1,0x36
    80003daa:	00950733          	add	a4,a0,s1
    80003dae:	05874703          	lbu	a4,88(a4)
    80003db2:	00e7f6b3          	and	a3,a5,a4
    80003db6:	c69d                	beqz	a3,80003de4 <bfree+0x6c>
    80003db8:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003dba:	94aa                	add	s1,s1,a0
    80003dbc:	fff7c793          	not	a5,a5
    80003dc0:	8ff9                	and	a5,a5,a4
    80003dc2:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003dc6:	00001097          	auipc	ra,0x1
    80003dca:	120080e7          	jalr	288(ra) # 80004ee6 <log_write>
  brelse(bp);
    80003dce:	854a                	mv	a0,s2
    80003dd0:	00000097          	auipc	ra,0x0
    80003dd4:	e92080e7          	jalr	-366(ra) # 80003c62 <brelse>
}
    80003dd8:	60e2                	ld	ra,24(sp)
    80003dda:	6442                	ld	s0,16(sp)
    80003ddc:	64a2                	ld	s1,8(sp)
    80003dde:	6902                	ld	s2,0(sp)
    80003de0:	6105                	addi	sp,sp,32
    80003de2:	8082                	ret
    panic("freeing free block");
    80003de4:	00006517          	auipc	a0,0x6
    80003de8:	91c50513          	addi	a0,a0,-1764 # 80009700 <syscalls+0x118>
    80003dec:	ffffc097          	auipc	ra,0xffffc
    80003df0:	758080e7          	jalr	1880(ra) # 80000544 <panic>

0000000080003df4 <balloc>:
{
    80003df4:	711d                	addi	sp,sp,-96
    80003df6:	ec86                	sd	ra,88(sp)
    80003df8:	e8a2                	sd	s0,80(sp)
    80003dfa:	e4a6                	sd	s1,72(sp)
    80003dfc:	e0ca                	sd	s2,64(sp)
    80003dfe:	fc4e                	sd	s3,56(sp)
    80003e00:	f852                	sd	s4,48(sp)
    80003e02:	f456                	sd	s5,40(sp)
    80003e04:	f05a                	sd	s6,32(sp)
    80003e06:	ec5e                	sd	s7,24(sp)
    80003e08:	e862                	sd	s8,16(sp)
    80003e0a:	e466                	sd	s9,8(sp)
    80003e0c:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003e0e:	0001e797          	auipc	a5,0x1e
    80003e12:	7867a783          	lw	a5,1926(a5) # 80022594 <sb+0x4>
    80003e16:	10078163          	beqz	a5,80003f18 <balloc+0x124>
    80003e1a:	8baa                	mv	s7,a0
    80003e1c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003e1e:	0001eb17          	auipc	s6,0x1e
    80003e22:	772b0b13          	addi	s6,s6,1906 # 80022590 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e26:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003e28:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e2a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003e2c:	6c89                	lui	s9,0x2
    80003e2e:	a061                	j	80003eb6 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003e30:	974a                	add	a4,a4,s2
    80003e32:	8fd5                	or	a5,a5,a3
    80003e34:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003e38:	854a                	mv	a0,s2
    80003e3a:	00001097          	auipc	ra,0x1
    80003e3e:	0ac080e7          	jalr	172(ra) # 80004ee6 <log_write>
        brelse(bp);
    80003e42:	854a                	mv	a0,s2
    80003e44:	00000097          	auipc	ra,0x0
    80003e48:	e1e080e7          	jalr	-482(ra) # 80003c62 <brelse>
  bp = bread(dev, bno);
    80003e4c:	85a6                	mv	a1,s1
    80003e4e:	855e                	mv	a0,s7
    80003e50:	00000097          	auipc	ra,0x0
    80003e54:	ce2080e7          	jalr	-798(ra) # 80003b32 <bread>
    80003e58:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003e5a:	40000613          	li	a2,1024
    80003e5e:	4581                	li	a1,0
    80003e60:	05850513          	addi	a0,a0,88
    80003e64:	ffffd097          	auipc	ra,0xffffd
    80003e68:	e82080e7          	jalr	-382(ra) # 80000ce6 <memset>
  log_write(bp);
    80003e6c:	854a                	mv	a0,s2
    80003e6e:	00001097          	auipc	ra,0x1
    80003e72:	078080e7          	jalr	120(ra) # 80004ee6 <log_write>
  brelse(bp);
    80003e76:	854a                	mv	a0,s2
    80003e78:	00000097          	auipc	ra,0x0
    80003e7c:	dea080e7          	jalr	-534(ra) # 80003c62 <brelse>
}
    80003e80:	8526                	mv	a0,s1
    80003e82:	60e6                	ld	ra,88(sp)
    80003e84:	6446                	ld	s0,80(sp)
    80003e86:	64a6                	ld	s1,72(sp)
    80003e88:	6906                	ld	s2,64(sp)
    80003e8a:	79e2                	ld	s3,56(sp)
    80003e8c:	7a42                	ld	s4,48(sp)
    80003e8e:	7aa2                	ld	s5,40(sp)
    80003e90:	7b02                	ld	s6,32(sp)
    80003e92:	6be2                	ld	s7,24(sp)
    80003e94:	6c42                	ld	s8,16(sp)
    80003e96:	6ca2                	ld	s9,8(sp)
    80003e98:	6125                	addi	sp,sp,96
    80003e9a:	8082                	ret
    brelse(bp);
    80003e9c:	854a                	mv	a0,s2
    80003e9e:	00000097          	auipc	ra,0x0
    80003ea2:	dc4080e7          	jalr	-572(ra) # 80003c62 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003ea6:	015c87bb          	addw	a5,s9,s5
    80003eaa:	00078a9b          	sext.w	s5,a5
    80003eae:	004b2703          	lw	a4,4(s6)
    80003eb2:	06eaf363          	bgeu	s5,a4,80003f18 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003eb6:	41fad79b          	sraiw	a5,s5,0x1f
    80003eba:	0137d79b          	srliw	a5,a5,0x13
    80003ebe:	015787bb          	addw	a5,a5,s5
    80003ec2:	40d7d79b          	sraiw	a5,a5,0xd
    80003ec6:	01cb2583          	lw	a1,28(s6)
    80003eca:	9dbd                	addw	a1,a1,a5
    80003ecc:	855e                	mv	a0,s7
    80003ece:	00000097          	auipc	ra,0x0
    80003ed2:	c64080e7          	jalr	-924(ra) # 80003b32 <bread>
    80003ed6:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003ed8:	004b2503          	lw	a0,4(s6)
    80003edc:	000a849b          	sext.w	s1,s5
    80003ee0:	8662                	mv	a2,s8
    80003ee2:	faa4fde3          	bgeu	s1,a0,80003e9c <balloc+0xa8>
      m = 1 << (bi % 8);
    80003ee6:	41f6579b          	sraiw	a5,a2,0x1f
    80003eea:	01d7d69b          	srliw	a3,a5,0x1d
    80003eee:	00c6873b          	addw	a4,a3,a2
    80003ef2:	00777793          	andi	a5,a4,7
    80003ef6:	9f95                	subw	a5,a5,a3
    80003ef8:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003efc:	4037571b          	sraiw	a4,a4,0x3
    80003f00:	00e906b3          	add	a3,s2,a4
    80003f04:	0586c683          	lbu	a3,88(a3)
    80003f08:	00d7f5b3          	and	a1,a5,a3
    80003f0c:	d195                	beqz	a1,80003e30 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003f0e:	2605                	addiw	a2,a2,1
    80003f10:	2485                	addiw	s1,s1,1
    80003f12:	fd4618e3          	bne	a2,s4,80003ee2 <balloc+0xee>
    80003f16:	b759                	j	80003e9c <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003f18:	00006517          	auipc	a0,0x6
    80003f1c:	80050513          	addi	a0,a0,-2048 # 80009718 <syscalls+0x130>
    80003f20:	ffffc097          	auipc	ra,0xffffc
    80003f24:	66e080e7          	jalr	1646(ra) # 8000058e <printf>
  return 0;
    80003f28:	4481                	li	s1,0
    80003f2a:	bf99                	j	80003e80 <balloc+0x8c>

0000000080003f2c <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003f2c:	7179                	addi	sp,sp,-48
    80003f2e:	f406                	sd	ra,40(sp)
    80003f30:	f022                	sd	s0,32(sp)
    80003f32:	ec26                	sd	s1,24(sp)
    80003f34:	e84a                	sd	s2,16(sp)
    80003f36:	e44e                	sd	s3,8(sp)
    80003f38:	e052                	sd	s4,0(sp)
    80003f3a:	1800                	addi	s0,sp,48
    80003f3c:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003f3e:	47ad                	li	a5,11
    80003f40:	02b7e763          	bltu	a5,a1,80003f6e <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003f44:	02059493          	slli	s1,a1,0x20
    80003f48:	9081                	srli	s1,s1,0x20
    80003f4a:	048a                	slli	s1,s1,0x2
    80003f4c:	94aa                	add	s1,s1,a0
    80003f4e:	0504a903          	lw	s2,80(s1)
    80003f52:	06091e63          	bnez	s2,80003fce <bmap+0xa2>
      addr = balloc(ip->dev);
    80003f56:	4108                	lw	a0,0(a0)
    80003f58:	00000097          	auipc	ra,0x0
    80003f5c:	e9c080e7          	jalr	-356(ra) # 80003df4 <balloc>
    80003f60:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003f64:	06090563          	beqz	s2,80003fce <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003f68:	0524a823          	sw	s2,80(s1)
    80003f6c:	a08d                	j	80003fce <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003f6e:	ff45849b          	addiw	s1,a1,-12
    80003f72:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003f76:	0ff00793          	li	a5,255
    80003f7a:	08e7e563          	bltu	a5,a4,80004004 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003f7e:	08052903          	lw	s2,128(a0)
    80003f82:	00091d63          	bnez	s2,80003f9c <bmap+0x70>
      addr = balloc(ip->dev);
    80003f86:	4108                	lw	a0,0(a0)
    80003f88:	00000097          	auipc	ra,0x0
    80003f8c:	e6c080e7          	jalr	-404(ra) # 80003df4 <balloc>
    80003f90:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003f94:	02090d63          	beqz	s2,80003fce <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003f98:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003f9c:	85ca                	mv	a1,s2
    80003f9e:	0009a503          	lw	a0,0(s3)
    80003fa2:	00000097          	auipc	ra,0x0
    80003fa6:	b90080e7          	jalr	-1136(ra) # 80003b32 <bread>
    80003faa:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003fac:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003fb0:	02049593          	slli	a1,s1,0x20
    80003fb4:	9181                	srli	a1,a1,0x20
    80003fb6:	058a                	slli	a1,a1,0x2
    80003fb8:	00b784b3          	add	s1,a5,a1
    80003fbc:	0004a903          	lw	s2,0(s1)
    80003fc0:	02090063          	beqz	s2,80003fe0 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003fc4:	8552                	mv	a0,s4
    80003fc6:	00000097          	auipc	ra,0x0
    80003fca:	c9c080e7          	jalr	-868(ra) # 80003c62 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003fce:	854a                	mv	a0,s2
    80003fd0:	70a2                	ld	ra,40(sp)
    80003fd2:	7402                	ld	s0,32(sp)
    80003fd4:	64e2                	ld	s1,24(sp)
    80003fd6:	6942                	ld	s2,16(sp)
    80003fd8:	69a2                	ld	s3,8(sp)
    80003fda:	6a02                	ld	s4,0(sp)
    80003fdc:	6145                	addi	sp,sp,48
    80003fde:	8082                	ret
      addr = balloc(ip->dev);
    80003fe0:	0009a503          	lw	a0,0(s3)
    80003fe4:	00000097          	auipc	ra,0x0
    80003fe8:	e10080e7          	jalr	-496(ra) # 80003df4 <balloc>
    80003fec:	0005091b          	sext.w	s2,a0
      if(addr){
    80003ff0:	fc090ae3          	beqz	s2,80003fc4 <bmap+0x98>
        a[bn] = addr;
    80003ff4:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003ff8:	8552                	mv	a0,s4
    80003ffa:	00001097          	auipc	ra,0x1
    80003ffe:	eec080e7          	jalr	-276(ra) # 80004ee6 <log_write>
    80004002:	b7c9                	j	80003fc4 <bmap+0x98>
  panic("bmap: out of range");
    80004004:	00005517          	auipc	a0,0x5
    80004008:	72c50513          	addi	a0,a0,1836 # 80009730 <syscalls+0x148>
    8000400c:	ffffc097          	auipc	ra,0xffffc
    80004010:	538080e7          	jalr	1336(ra) # 80000544 <panic>

0000000080004014 <iget>:
{
    80004014:	7179                	addi	sp,sp,-48
    80004016:	f406                	sd	ra,40(sp)
    80004018:	f022                	sd	s0,32(sp)
    8000401a:	ec26                	sd	s1,24(sp)
    8000401c:	e84a                	sd	s2,16(sp)
    8000401e:	e44e                	sd	s3,8(sp)
    80004020:	e052                	sd	s4,0(sp)
    80004022:	1800                	addi	s0,sp,48
    80004024:	89aa                	mv	s3,a0
    80004026:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80004028:	0001e517          	auipc	a0,0x1e
    8000402c:	58850513          	addi	a0,a0,1416 # 800225b0 <itable>
    80004030:	ffffd097          	auipc	ra,0xffffd
    80004034:	bba080e7          	jalr	-1094(ra) # 80000bea <acquire>
  empty = 0;
    80004038:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000403a:	0001e497          	auipc	s1,0x1e
    8000403e:	58e48493          	addi	s1,s1,1422 # 800225c8 <itable+0x18>
    80004042:	00020697          	auipc	a3,0x20
    80004046:	01668693          	addi	a3,a3,22 # 80024058 <log>
    8000404a:	a039                	j	80004058 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000404c:	02090b63          	beqz	s2,80004082 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80004050:	08848493          	addi	s1,s1,136
    80004054:	02d48a63          	beq	s1,a3,80004088 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80004058:	449c                	lw	a5,8(s1)
    8000405a:	fef059e3          	blez	a5,8000404c <iget+0x38>
    8000405e:	4098                	lw	a4,0(s1)
    80004060:	ff3716e3          	bne	a4,s3,8000404c <iget+0x38>
    80004064:	40d8                	lw	a4,4(s1)
    80004066:	ff4713e3          	bne	a4,s4,8000404c <iget+0x38>
      ip->ref++;
    8000406a:	2785                	addiw	a5,a5,1
    8000406c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000406e:	0001e517          	auipc	a0,0x1e
    80004072:	54250513          	addi	a0,a0,1346 # 800225b0 <itable>
    80004076:	ffffd097          	auipc	ra,0xffffd
    8000407a:	c28080e7          	jalr	-984(ra) # 80000c9e <release>
      return ip;
    8000407e:	8926                	mv	s2,s1
    80004080:	a03d                	j	800040ae <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80004082:	f7f9                	bnez	a5,80004050 <iget+0x3c>
    80004084:	8926                	mv	s2,s1
    80004086:	b7e9                	j	80004050 <iget+0x3c>
  if(empty == 0)
    80004088:	02090c63          	beqz	s2,800040c0 <iget+0xac>
  ip->dev = dev;
    8000408c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80004090:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80004094:	4785                	li	a5,1
    80004096:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000409a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000409e:	0001e517          	auipc	a0,0x1e
    800040a2:	51250513          	addi	a0,a0,1298 # 800225b0 <itable>
    800040a6:	ffffd097          	auipc	ra,0xffffd
    800040aa:	bf8080e7          	jalr	-1032(ra) # 80000c9e <release>
}
    800040ae:	854a                	mv	a0,s2
    800040b0:	70a2                	ld	ra,40(sp)
    800040b2:	7402                	ld	s0,32(sp)
    800040b4:	64e2                	ld	s1,24(sp)
    800040b6:	6942                	ld	s2,16(sp)
    800040b8:	69a2                	ld	s3,8(sp)
    800040ba:	6a02                	ld	s4,0(sp)
    800040bc:	6145                	addi	sp,sp,48
    800040be:	8082                	ret
    panic("iget: no inodes");
    800040c0:	00005517          	auipc	a0,0x5
    800040c4:	68850513          	addi	a0,a0,1672 # 80009748 <syscalls+0x160>
    800040c8:	ffffc097          	auipc	ra,0xffffc
    800040cc:	47c080e7          	jalr	1148(ra) # 80000544 <panic>

00000000800040d0 <fsinit>:
fsinit(int dev) {
    800040d0:	7179                	addi	sp,sp,-48
    800040d2:	f406                	sd	ra,40(sp)
    800040d4:	f022                	sd	s0,32(sp)
    800040d6:	ec26                	sd	s1,24(sp)
    800040d8:	e84a                	sd	s2,16(sp)
    800040da:	e44e                	sd	s3,8(sp)
    800040dc:	1800                	addi	s0,sp,48
    800040de:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800040e0:	4585                	li	a1,1
    800040e2:	00000097          	auipc	ra,0x0
    800040e6:	a50080e7          	jalr	-1456(ra) # 80003b32 <bread>
    800040ea:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800040ec:	0001e997          	auipc	s3,0x1e
    800040f0:	4a498993          	addi	s3,s3,1188 # 80022590 <sb>
    800040f4:	02000613          	li	a2,32
    800040f8:	05850593          	addi	a1,a0,88
    800040fc:	854e                	mv	a0,s3
    800040fe:	ffffd097          	auipc	ra,0xffffd
    80004102:	c48080e7          	jalr	-952(ra) # 80000d46 <memmove>
  brelse(bp);
    80004106:	8526                	mv	a0,s1
    80004108:	00000097          	auipc	ra,0x0
    8000410c:	b5a080e7          	jalr	-1190(ra) # 80003c62 <brelse>
  if(sb.magic != FSMAGIC)
    80004110:	0009a703          	lw	a4,0(s3)
    80004114:	102037b7          	lui	a5,0x10203
    80004118:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000411c:	02f71263          	bne	a4,a5,80004140 <fsinit+0x70>
  initlog(dev, &sb);
    80004120:	0001e597          	auipc	a1,0x1e
    80004124:	47058593          	addi	a1,a1,1136 # 80022590 <sb>
    80004128:	854a                	mv	a0,s2
    8000412a:	00001097          	auipc	ra,0x1
    8000412e:	b40080e7          	jalr	-1216(ra) # 80004c6a <initlog>
}
    80004132:	70a2                	ld	ra,40(sp)
    80004134:	7402                	ld	s0,32(sp)
    80004136:	64e2                	ld	s1,24(sp)
    80004138:	6942                	ld	s2,16(sp)
    8000413a:	69a2                	ld	s3,8(sp)
    8000413c:	6145                	addi	sp,sp,48
    8000413e:	8082                	ret
    panic("invalid file system");
    80004140:	00005517          	auipc	a0,0x5
    80004144:	61850513          	addi	a0,a0,1560 # 80009758 <syscalls+0x170>
    80004148:	ffffc097          	auipc	ra,0xffffc
    8000414c:	3fc080e7          	jalr	1020(ra) # 80000544 <panic>

0000000080004150 <iinit>:
{
    80004150:	7179                	addi	sp,sp,-48
    80004152:	f406                	sd	ra,40(sp)
    80004154:	f022                	sd	s0,32(sp)
    80004156:	ec26                	sd	s1,24(sp)
    80004158:	e84a                	sd	s2,16(sp)
    8000415a:	e44e                	sd	s3,8(sp)
    8000415c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000415e:	00005597          	auipc	a1,0x5
    80004162:	61258593          	addi	a1,a1,1554 # 80009770 <syscalls+0x188>
    80004166:	0001e517          	auipc	a0,0x1e
    8000416a:	44a50513          	addi	a0,a0,1098 # 800225b0 <itable>
    8000416e:	ffffd097          	auipc	ra,0xffffd
    80004172:	9ec080e7          	jalr	-1556(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    80004176:	0001e497          	auipc	s1,0x1e
    8000417a:	46248493          	addi	s1,s1,1122 # 800225d8 <itable+0x28>
    8000417e:	00020997          	auipc	s3,0x20
    80004182:	eea98993          	addi	s3,s3,-278 # 80024068 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80004186:	00005917          	auipc	s2,0x5
    8000418a:	5f290913          	addi	s2,s2,1522 # 80009778 <syscalls+0x190>
    8000418e:	85ca                	mv	a1,s2
    80004190:	8526                	mv	a0,s1
    80004192:	00001097          	auipc	ra,0x1
    80004196:	e3a080e7          	jalr	-454(ra) # 80004fcc <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000419a:	08848493          	addi	s1,s1,136
    8000419e:	ff3498e3          	bne	s1,s3,8000418e <iinit+0x3e>
}
    800041a2:	70a2                	ld	ra,40(sp)
    800041a4:	7402                	ld	s0,32(sp)
    800041a6:	64e2                	ld	s1,24(sp)
    800041a8:	6942                	ld	s2,16(sp)
    800041aa:	69a2                	ld	s3,8(sp)
    800041ac:	6145                	addi	sp,sp,48
    800041ae:	8082                	ret

00000000800041b0 <ialloc>:
{
    800041b0:	715d                	addi	sp,sp,-80
    800041b2:	e486                	sd	ra,72(sp)
    800041b4:	e0a2                	sd	s0,64(sp)
    800041b6:	fc26                	sd	s1,56(sp)
    800041b8:	f84a                	sd	s2,48(sp)
    800041ba:	f44e                	sd	s3,40(sp)
    800041bc:	f052                	sd	s4,32(sp)
    800041be:	ec56                	sd	s5,24(sp)
    800041c0:	e85a                	sd	s6,16(sp)
    800041c2:	e45e                	sd	s7,8(sp)
    800041c4:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800041c6:	0001e717          	auipc	a4,0x1e
    800041ca:	3d672703          	lw	a4,982(a4) # 8002259c <sb+0xc>
    800041ce:	4785                	li	a5,1
    800041d0:	04e7fa63          	bgeu	a5,a4,80004224 <ialloc+0x74>
    800041d4:	8aaa                	mv	s5,a0
    800041d6:	8bae                	mv	s7,a1
    800041d8:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800041da:	0001ea17          	auipc	s4,0x1e
    800041de:	3b6a0a13          	addi	s4,s4,950 # 80022590 <sb>
    800041e2:	00048b1b          	sext.w	s6,s1
    800041e6:	0044d593          	srli	a1,s1,0x4
    800041ea:	018a2783          	lw	a5,24(s4)
    800041ee:	9dbd                	addw	a1,a1,a5
    800041f0:	8556                	mv	a0,s5
    800041f2:	00000097          	auipc	ra,0x0
    800041f6:	940080e7          	jalr	-1728(ra) # 80003b32 <bread>
    800041fa:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800041fc:	05850993          	addi	s3,a0,88
    80004200:	00f4f793          	andi	a5,s1,15
    80004204:	079a                	slli	a5,a5,0x6
    80004206:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80004208:	00099783          	lh	a5,0(s3)
    8000420c:	c3a1                	beqz	a5,8000424c <ialloc+0x9c>
    brelse(bp);
    8000420e:	00000097          	auipc	ra,0x0
    80004212:	a54080e7          	jalr	-1452(ra) # 80003c62 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80004216:	0485                	addi	s1,s1,1
    80004218:	00ca2703          	lw	a4,12(s4)
    8000421c:	0004879b          	sext.w	a5,s1
    80004220:	fce7e1e3          	bltu	a5,a4,800041e2 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80004224:	00005517          	auipc	a0,0x5
    80004228:	55c50513          	addi	a0,a0,1372 # 80009780 <syscalls+0x198>
    8000422c:	ffffc097          	auipc	ra,0xffffc
    80004230:	362080e7          	jalr	866(ra) # 8000058e <printf>
  return 0;
    80004234:	4501                	li	a0,0
}
    80004236:	60a6                	ld	ra,72(sp)
    80004238:	6406                	ld	s0,64(sp)
    8000423a:	74e2                	ld	s1,56(sp)
    8000423c:	7942                	ld	s2,48(sp)
    8000423e:	79a2                	ld	s3,40(sp)
    80004240:	7a02                	ld	s4,32(sp)
    80004242:	6ae2                	ld	s5,24(sp)
    80004244:	6b42                	ld	s6,16(sp)
    80004246:	6ba2                	ld	s7,8(sp)
    80004248:	6161                	addi	sp,sp,80
    8000424a:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000424c:	04000613          	li	a2,64
    80004250:	4581                	li	a1,0
    80004252:	854e                	mv	a0,s3
    80004254:	ffffd097          	auipc	ra,0xffffd
    80004258:	a92080e7          	jalr	-1390(ra) # 80000ce6 <memset>
      dip->type = type;
    8000425c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80004260:	854a                	mv	a0,s2
    80004262:	00001097          	auipc	ra,0x1
    80004266:	c84080e7          	jalr	-892(ra) # 80004ee6 <log_write>
      brelse(bp);
    8000426a:	854a                	mv	a0,s2
    8000426c:	00000097          	auipc	ra,0x0
    80004270:	9f6080e7          	jalr	-1546(ra) # 80003c62 <brelse>
      return iget(dev, inum);
    80004274:	85da                	mv	a1,s6
    80004276:	8556                	mv	a0,s5
    80004278:	00000097          	auipc	ra,0x0
    8000427c:	d9c080e7          	jalr	-612(ra) # 80004014 <iget>
    80004280:	bf5d                	j	80004236 <ialloc+0x86>

0000000080004282 <iupdate>:
{
    80004282:	1101                	addi	sp,sp,-32
    80004284:	ec06                	sd	ra,24(sp)
    80004286:	e822                	sd	s0,16(sp)
    80004288:	e426                	sd	s1,8(sp)
    8000428a:	e04a                	sd	s2,0(sp)
    8000428c:	1000                	addi	s0,sp,32
    8000428e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004290:	415c                	lw	a5,4(a0)
    80004292:	0047d79b          	srliw	a5,a5,0x4
    80004296:	0001e597          	auipc	a1,0x1e
    8000429a:	3125a583          	lw	a1,786(a1) # 800225a8 <sb+0x18>
    8000429e:	9dbd                	addw	a1,a1,a5
    800042a0:	4108                	lw	a0,0(a0)
    800042a2:	00000097          	auipc	ra,0x0
    800042a6:	890080e7          	jalr	-1904(ra) # 80003b32 <bread>
    800042aa:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800042ac:	05850793          	addi	a5,a0,88
    800042b0:	40c8                	lw	a0,4(s1)
    800042b2:	893d                	andi	a0,a0,15
    800042b4:	051a                	slli	a0,a0,0x6
    800042b6:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800042b8:	04449703          	lh	a4,68(s1)
    800042bc:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800042c0:	04649703          	lh	a4,70(s1)
    800042c4:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800042c8:	04849703          	lh	a4,72(s1)
    800042cc:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800042d0:	04a49703          	lh	a4,74(s1)
    800042d4:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800042d8:	44f8                	lw	a4,76(s1)
    800042da:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800042dc:	03400613          	li	a2,52
    800042e0:	05048593          	addi	a1,s1,80
    800042e4:	0531                	addi	a0,a0,12
    800042e6:	ffffd097          	auipc	ra,0xffffd
    800042ea:	a60080e7          	jalr	-1440(ra) # 80000d46 <memmove>
  log_write(bp);
    800042ee:	854a                	mv	a0,s2
    800042f0:	00001097          	auipc	ra,0x1
    800042f4:	bf6080e7          	jalr	-1034(ra) # 80004ee6 <log_write>
  brelse(bp);
    800042f8:	854a                	mv	a0,s2
    800042fa:	00000097          	auipc	ra,0x0
    800042fe:	968080e7          	jalr	-1688(ra) # 80003c62 <brelse>
}
    80004302:	60e2                	ld	ra,24(sp)
    80004304:	6442                	ld	s0,16(sp)
    80004306:	64a2                	ld	s1,8(sp)
    80004308:	6902                	ld	s2,0(sp)
    8000430a:	6105                	addi	sp,sp,32
    8000430c:	8082                	ret

000000008000430e <idup>:
{
    8000430e:	1101                	addi	sp,sp,-32
    80004310:	ec06                	sd	ra,24(sp)
    80004312:	e822                	sd	s0,16(sp)
    80004314:	e426                	sd	s1,8(sp)
    80004316:	1000                	addi	s0,sp,32
    80004318:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000431a:	0001e517          	auipc	a0,0x1e
    8000431e:	29650513          	addi	a0,a0,662 # 800225b0 <itable>
    80004322:	ffffd097          	auipc	ra,0xffffd
    80004326:	8c8080e7          	jalr	-1848(ra) # 80000bea <acquire>
  ip->ref++;
    8000432a:	449c                	lw	a5,8(s1)
    8000432c:	2785                	addiw	a5,a5,1
    8000432e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004330:	0001e517          	auipc	a0,0x1e
    80004334:	28050513          	addi	a0,a0,640 # 800225b0 <itable>
    80004338:	ffffd097          	auipc	ra,0xffffd
    8000433c:	966080e7          	jalr	-1690(ra) # 80000c9e <release>
}
    80004340:	8526                	mv	a0,s1
    80004342:	60e2                	ld	ra,24(sp)
    80004344:	6442                	ld	s0,16(sp)
    80004346:	64a2                	ld	s1,8(sp)
    80004348:	6105                	addi	sp,sp,32
    8000434a:	8082                	ret

000000008000434c <ilock>:
{
    8000434c:	1101                	addi	sp,sp,-32
    8000434e:	ec06                	sd	ra,24(sp)
    80004350:	e822                	sd	s0,16(sp)
    80004352:	e426                	sd	s1,8(sp)
    80004354:	e04a                	sd	s2,0(sp)
    80004356:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80004358:	c115                	beqz	a0,8000437c <ilock+0x30>
    8000435a:	84aa                	mv	s1,a0
    8000435c:	451c                	lw	a5,8(a0)
    8000435e:	00f05f63          	blez	a5,8000437c <ilock+0x30>
  acquiresleep(&ip->lock);
    80004362:	0541                	addi	a0,a0,16
    80004364:	00001097          	auipc	ra,0x1
    80004368:	ca2080e7          	jalr	-862(ra) # 80005006 <acquiresleep>
  if(ip->valid == 0){
    8000436c:	40bc                	lw	a5,64(s1)
    8000436e:	cf99                	beqz	a5,8000438c <ilock+0x40>
}
    80004370:	60e2                	ld	ra,24(sp)
    80004372:	6442                	ld	s0,16(sp)
    80004374:	64a2                	ld	s1,8(sp)
    80004376:	6902                	ld	s2,0(sp)
    80004378:	6105                	addi	sp,sp,32
    8000437a:	8082                	ret
    panic("ilock");
    8000437c:	00005517          	auipc	a0,0x5
    80004380:	41c50513          	addi	a0,a0,1052 # 80009798 <syscalls+0x1b0>
    80004384:	ffffc097          	auipc	ra,0xffffc
    80004388:	1c0080e7          	jalr	448(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000438c:	40dc                	lw	a5,4(s1)
    8000438e:	0047d79b          	srliw	a5,a5,0x4
    80004392:	0001e597          	auipc	a1,0x1e
    80004396:	2165a583          	lw	a1,534(a1) # 800225a8 <sb+0x18>
    8000439a:	9dbd                	addw	a1,a1,a5
    8000439c:	4088                	lw	a0,0(s1)
    8000439e:	fffff097          	auipc	ra,0xfffff
    800043a2:	794080e7          	jalr	1940(ra) # 80003b32 <bread>
    800043a6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800043a8:	05850593          	addi	a1,a0,88
    800043ac:	40dc                	lw	a5,4(s1)
    800043ae:	8bbd                	andi	a5,a5,15
    800043b0:	079a                	slli	a5,a5,0x6
    800043b2:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800043b4:	00059783          	lh	a5,0(a1)
    800043b8:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800043bc:	00259783          	lh	a5,2(a1)
    800043c0:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800043c4:	00459783          	lh	a5,4(a1)
    800043c8:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800043cc:	00659783          	lh	a5,6(a1)
    800043d0:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800043d4:	459c                	lw	a5,8(a1)
    800043d6:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800043d8:	03400613          	li	a2,52
    800043dc:	05b1                	addi	a1,a1,12
    800043de:	05048513          	addi	a0,s1,80
    800043e2:	ffffd097          	auipc	ra,0xffffd
    800043e6:	964080e7          	jalr	-1692(ra) # 80000d46 <memmove>
    brelse(bp);
    800043ea:	854a                	mv	a0,s2
    800043ec:	00000097          	auipc	ra,0x0
    800043f0:	876080e7          	jalr	-1930(ra) # 80003c62 <brelse>
    ip->valid = 1;
    800043f4:	4785                	li	a5,1
    800043f6:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800043f8:	04449783          	lh	a5,68(s1)
    800043fc:	fbb5                	bnez	a5,80004370 <ilock+0x24>
      panic("ilock: no type");
    800043fe:	00005517          	auipc	a0,0x5
    80004402:	3a250513          	addi	a0,a0,930 # 800097a0 <syscalls+0x1b8>
    80004406:	ffffc097          	auipc	ra,0xffffc
    8000440a:	13e080e7          	jalr	318(ra) # 80000544 <panic>

000000008000440e <iunlock>:
{
    8000440e:	1101                	addi	sp,sp,-32
    80004410:	ec06                	sd	ra,24(sp)
    80004412:	e822                	sd	s0,16(sp)
    80004414:	e426                	sd	s1,8(sp)
    80004416:	e04a                	sd	s2,0(sp)
    80004418:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000441a:	c905                	beqz	a0,8000444a <iunlock+0x3c>
    8000441c:	84aa                	mv	s1,a0
    8000441e:	01050913          	addi	s2,a0,16
    80004422:	854a                	mv	a0,s2
    80004424:	00001097          	auipc	ra,0x1
    80004428:	c7c080e7          	jalr	-900(ra) # 800050a0 <holdingsleep>
    8000442c:	cd19                	beqz	a0,8000444a <iunlock+0x3c>
    8000442e:	449c                	lw	a5,8(s1)
    80004430:	00f05d63          	blez	a5,8000444a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004434:	854a                	mv	a0,s2
    80004436:	00001097          	auipc	ra,0x1
    8000443a:	c26080e7          	jalr	-986(ra) # 8000505c <releasesleep>
}
    8000443e:	60e2                	ld	ra,24(sp)
    80004440:	6442                	ld	s0,16(sp)
    80004442:	64a2                	ld	s1,8(sp)
    80004444:	6902                	ld	s2,0(sp)
    80004446:	6105                	addi	sp,sp,32
    80004448:	8082                	ret
    panic("iunlock");
    8000444a:	00005517          	auipc	a0,0x5
    8000444e:	36650513          	addi	a0,a0,870 # 800097b0 <syscalls+0x1c8>
    80004452:	ffffc097          	auipc	ra,0xffffc
    80004456:	0f2080e7          	jalr	242(ra) # 80000544 <panic>

000000008000445a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000445a:	7179                	addi	sp,sp,-48
    8000445c:	f406                	sd	ra,40(sp)
    8000445e:	f022                	sd	s0,32(sp)
    80004460:	ec26                	sd	s1,24(sp)
    80004462:	e84a                	sd	s2,16(sp)
    80004464:	e44e                	sd	s3,8(sp)
    80004466:	e052                	sd	s4,0(sp)
    80004468:	1800                	addi	s0,sp,48
    8000446a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000446c:	05050493          	addi	s1,a0,80
    80004470:	08050913          	addi	s2,a0,128
    80004474:	a021                	j	8000447c <itrunc+0x22>
    80004476:	0491                	addi	s1,s1,4
    80004478:	01248d63          	beq	s1,s2,80004492 <itrunc+0x38>
    if(ip->addrs[i]){
    8000447c:	408c                	lw	a1,0(s1)
    8000447e:	dde5                	beqz	a1,80004476 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80004480:	0009a503          	lw	a0,0(s3)
    80004484:	00000097          	auipc	ra,0x0
    80004488:	8f4080e7          	jalr	-1804(ra) # 80003d78 <bfree>
      ip->addrs[i] = 0;
    8000448c:	0004a023          	sw	zero,0(s1)
    80004490:	b7dd                	j	80004476 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004492:	0809a583          	lw	a1,128(s3)
    80004496:	e185                	bnez	a1,800044b6 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004498:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000449c:	854e                	mv	a0,s3
    8000449e:	00000097          	auipc	ra,0x0
    800044a2:	de4080e7          	jalr	-540(ra) # 80004282 <iupdate>
}
    800044a6:	70a2                	ld	ra,40(sp)
    800044a8:	7402                	ld	s0,32(sp)
    800044aa:	64e2                	ld	s1,24(sp)
    800044ac:	6942                	ld	s2,16(sp)
    800044ae:	69a2                	ld	s3,8(sp)
    800044b0:	6a02                	ld	s4,0(sp)
    800044b2:	6145                	addi	sp,sp,48
    800044b4:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800044b6:	0009a503          	lw	a0,0(s3)
    800044ba:	fffff097          	auipc	ra,0xfffff
    800044be:	678080e7          	jalr	1656(ra) # 80003b32 <bread>
    800044c2:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800044c4:	05850493          	addi	s1,a0,88
    800044c8:	45850913          	addi	s2,a0,1112
    800044cc:	a811                	j	800044e0 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800044ce:	0009a503          	lw	a0,0(s3)
    800044d2:	00000097          	auipc	ra,0x0
    800044d6:	8a6080e7          	jalr	-1882(ra) # 80003d78 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800044da:	0491                	addi	s1,s1,4
    800044dc:	01248563          	beq	s1,s2,800044e6 <itrunc+0x8c>
      if(a[j])
    800044e0:	408c                	lw	a1,0(s1)
    800044e2:	dde5                	beqz	a1,800044da <itrunc+0x80>
    800044e4:	b7ed                	j	800044ce <itrunc+0x74>
    brelse(bp);
    800044e6:	8552                	mv	a0,s4
    800044e8:	fffff097          	auipc	ra,0xfffff
    800044ec:	77a080e7          	jalr	1914(ra) # 80003c62 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800044f0:	0809a583          	lw	a1,128(s3)
    800044f4:	0009a503          	lw	a0,0(s3)
    800044f8:	00000097          	auipc	ra,0x0
    800044fc:	880080e7          	jalr	-1920(ra) # 80003d78 <bfree>
    ip->addrs[NDIRECT] = 0;
    80004500:	0809a023          	sw	zero,128(s3)
    80004504:	bf51                	j	80004498 <itrunc+0x3e>

0000000080004506 <iput>:
{
    80004506:	1101                	addi	sp,sp,-32
    80004508:	ec06                	sd	ra,24(sp)
    8000450a:	e822                	sd	s0,16(sp)
    8000450c:	e426                	sd	s1,8(sp)
    8000450e:	e04a                	sd	s2,0(sp)
    80004510:	1000                	addi	s0,sp,32
    80004512:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004514:	0001e517          	auipc	a0,0x1e
    80004518:	09c50513          	addi	a0,a0,156 # 800225b0 <itable>
    8000451c:	ffffc097          	auipc	ra,0xffffc
    80004520:	6ce080e7          	jalr	1742(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004524:	4498                	lw	a4,8(s1)
    80004526:	4785                	li	a5,1
    80004528:	02f70363          	beq	a4,a5,8000454e <iput+0x48>
  ip->ref--;
    8000452c:	449c                	lw	a5,8(s1)
    8000452e:	37fd                	addiw	a5,a5,-1
    80004530:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004532:	0001e517          	auipc	a0,0x1e
    80004536:	07e50513          	addi	a0,a0,126 # 800225b0 <itable>
    8000453a:	ffffc097          	auipc	ra,0xffffc
    8000453e:	764080e7          	jalr	1892(ra) # 80000c9e <release>
}
    80004542:	60e2                	ld	ra,24(sp)
    80004544:	6442                	ld	s0,16(sp)
    80004546:	64a2                	ld	s1,8(sp)
    80004548:	6902                	ld	s2,0(sp)
    8000454a:	6105                	addi	sp,sp,32
    8000454c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000454e:	40bc                	lw	a5,64(s1)
    80004550:	dff1                	beqz	a5,8000452c <iput+0x26>
    80004552:	04a49783          	lh	a5,74(s1)
    80004556:	fbf9                	bnez	a5,8000452c <iput+0x26>
    acquiresleep(&ip->lock);
    80004558:	01048913          	addi	s2,s1,16
    8000455c:	854a                	mv	a0,s2
    8000455e:	00001097          	auipc	ra,0x1
    80004562:	aa8080e7          	jalr	-1368(ra) # 80005006 <acquiresleep>
    release(&itable.lock);
    80004566:	0001e517          	auipc	a0,0x1e
    8000456a:	04a50513          	addi	a0,a0,74 # 800225b0 <itable>
    8000456e:	ffffc097          	auipc	ra,0xffffc
    80004572:	730080e7          	jalr	1840(ra) # 80000c9e <release>
    itrunc(ip);
    80004576:	8526                	mv	a0,s1
    80004578:	00000097          	auipc	ra,0x0
    8000457c:	ee2080e7          	jalr	-286(ra) # 8000445a <itrunc>
    ip->type = 0;
    80004580:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004584:	8526                	mv	a0,s1
    80004586:	00000097          	auipc	ra,0x0
    8000458a:	cfc080e7          	jalr	-772(ra) # 80004282 <iupdate>
    ip->valid = 0;
    8000458e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004592:	854a                	mv	a0,s2
    80004594:	00001097          	auipc	ra,0x1
    80004598:	ac8080e7          	jalr	-1336(ra) # 8000505c <releasesleep>
    acquire(&itable.lock);
    8000459c:	0001e517          	auipc	a0,0x1e
    800045a0:	01450513          	addi	a0,a0,20 # 800225b0 <itable>
    800045a4:	ffffc097          	auipc	ra,0xffffc
    800045a8:	646080e7          	jalr	1606(ra) # 80000bea <acquire>
    800045ac:	b741                	j	8000452c <iput+0x26>

00000000800045ae <iunlockput>:
{
    800045ae:	1101                	addi	sp,sp,-32
    800045b0:	ec06                	sd	ra,24(sp)
    800045b2:	e822                	sd	s0,16(sp)
    800045b4:	e426                	sd	s1,8(sp)
    800045b6:	1000                	addi	s0,sp,32
    800045b8:	84aa                	mv	s1,a0
  iunlock(ip);
    800045ba:	00000097          	auipc	ra,0x0
    800045be:	e54080e7          	jalr	-428(ra) # 8000440e <iunlock>
  iput(ip);
    800045c2:	8526                	mv	a0,s1
    800045c4:	00000097          	auipc	ra,0x0
    800045c8:	f42080e7          	jalr	-190(ra) # 80004506 <iput>
}
    800045cc:	60e2                	ld	ra,24(sp)
    800045ce:	6442                	ld	s0,16(sp)
    800045d0:	64a2                	ld	s1,8(sp)
    800045d2:	6105                	addi	sp,sp,32
    800045d4:	8082                	ret

00000000800045d6 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800045d6:	1141                	addi	sp,sp,-16
    800045d8:	e422                	sd	s0,8(sp)
    800045da:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800045dc:	411c                	lw	a5,0(a0)
    800045de:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800045e0:	415c                	lw	a5,4(a0)
    800045e2:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800045e4:	04451783          	lh	a5,68(a0)
    800045e8:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800045ec:	04a51783          	lh	a5,74(a0)
    800045f0:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800045f4:	04c56783          	lwu	a5,76(a0)
    800045f8:	e99c                	sd	a5,16(a1)
}
    800045fa:	6422                	ld	s0,8(sp)
    800045fc:	0141                	addi	sp,sp,16
    800045fe:	8082                	ret

0000000080004600 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004600:	457c                	lw	a5,76(a0)
    80004602:	0ed7e963          	bltu	a5,a3,800046f4 <readi+0xf4>
{
    80004606:	7159                	addi	sp,sp,-112
    80004608:	f486                	sd	ra,104(sp)
    8000460a:	f0a2                	sd	s0,96(sp)
    8000460c:	eca6                	sd	s1,88(sp)
    8000460e:	e8ca                	sd	s2,80(sp)
    80004610:	e4ce                	sd	s3,72(sp)
    80004612:	e0d2                	sd	s4,64(sp)
    80004614:	fc56                	sd	s5,56(sp)
    80004616:	f85a                	sd	s6,48(sp)
    80004618:	f45e                	sd	s7,40(sp)
    8000461a:	f062                	sd	s8,32(sp)
    8000461c:	ec66                	sd	s9,24(sp)
    8000461e:	e86a                	sd	s10,16(sp)
    80004620:	e46e                	sd	s11,8(sp)
    80004622:	1880                	addi	s0,sp,112
    80004624:	8b2a                	mv	s6,a0
    80004626:	8bae                	mv	s7,a1
    80004628:	8a32                	mv	s4,a2
    8000462a:	84b6                	mv	s1,a3
    8000462c:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    8000462e:	9f35                	addw	a4,a4,a3
    return 0;
    80004630:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004632:	0ad76063          	bltu	a4,a3,800046d2 <readi+0xd2>
  if(off + n > ip->size)
    80004636:	00e7f463          	bgeu	a5,a4,8000463e <readi+0x3e>
    n = ip->size - off;
    8000463a:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000463e:	0a0a8963          	beqz	s5,800046f0 <readi+0xf0>
    80004642:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004644:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004648:	5c7d                	li	s8,-1
    8000464a:	a82d                	j	80004684 <readi+0x84>
    8000464c:	020d1d93          	slli	s11,s10,0x20
    80004650:	020ddd93          	srli	s11,s11,0x20
    80004654:	05890613          	addi	a2,s2,88
    80004658:	86ee                	mv	a3,s11
    8000465a:	963a                	add	a2,a2,a4
    8000465c:	85d2                	mv	a1,s4
    8000465e:	855e                	mv	a0,s7
    80004660:	ffffe097          	auipc	ra,0xffffe
    80004664:	362080e7          	jalr	866(ra) # 800029c2 <either_copyout>
    80004668:	05850d63          	beq	a0,s8,800046c2 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000466c:	854a                	mv	a0,s2
    8000466e:	fffff097          	auipc	ra,0xfffff
    80004672:	5f4080e7          	jalr	1524(ra) # 80003c62 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004676:	013d09bb          	addw	s3,s10,s3
    8000467a:	009d04bb          	addw	s1,s10,s1
    8000467e:	9a6e                	add	s4,s4,s11
    80004680:	0559f763          	bgeu	s3,s5,800046ce <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80004684:	00a4d59b          	srliw	a1,s1,0xa
    80004688:	855a                	mv	a0,s6
    8000468a:	00000097          	auipc	ra,0x0
    8000468e:	8a2080e7          	jalr	-1886(ra) # 80003f2c <bmap>
    80004692:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004696:	cd85                	beqz	a1,800046ce <readi+0xce>
    bp = bread(ip->dev, addr);
    80004698:	000b2503          	lw	a0,0(s6)
    8000469c:	fffff097          	auipc	ra,0xfffff
    800046a0:	496080e7          	jalr	1174(ra) # 80003b32 <bread>
    800046a4:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800046a6:	3ff4f713          	andi	a4,s1,1023
    800046aa:	40ec87bb          	subw	a5,s9,a4
    800046ae:	413a86bb          	subw	a3,s5,s3
    800046b2:	8d3e                	mv	s10,a5
    800046b4:	2781                	sext.w	a5,a5
    800046b6:	0006861b          	sext.w	a2,a3
    800046ba:	f8f679e3          	bgeu	a2,a5,8000464c <readi+0x4c>
    800046be:	8d36                	mv	s10,a3
    800046c0:	b771                	j	8000464c <readi+0x4c>
      brelse(bp);
    800046c2:	854a                	mv	a0,s2
    800046c4:	fffff097          	auipc	ra,0xfffff
    800046c8:	59e080e7          	jalr	1438(ra) # 80003c62 <brelse>
      tot = -1;
    800046cc:	59fd                	li	s3,-1
  }
  return tot;
    800046ce:	0009851b          	sext.w	a0,s3
}
    800046d2:	70a6                	ld	ra,104(sp)
    800046d4:	7406                	ld	s0,96(sp)
    800046d6:	64e6                	ld	s1,88(sp)
    800046d8:	6946                	ld	s2,80(sp)
    800046da:	69a6                	ld	s3,72(sp)
    800046dc:	6a06                	ld	s4,64(sp)
    800046de:	7ae2                	ld	s5,56(sp)
    800046e0:	7b42                	ld	s6,48(sp)
    800046e2:	7ba2                	ld	s7,40(sp)
    800046e4:	7c02                	ld	s8,32(sp)
    800046e6:	6ce2                	ld	s9,24(sp)
    800046e8:	6d42                	ld	s10,16(sp)
    800046ea:	6da2                	ld	s11,8(sp)
    800046ec:	6165                	addi	sp,sp,112
    800046ee:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800046f0:	89d6                	mv	s3,s5
    800046f2:	bff1                	j	800046ce <readi+0xce>
    return 0;
    800046f4:	4501                	li	a0,0
}
    800046f6:	8082                	ret

00000000800046f8 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800046f8:	457c                	lw	a5,76(a0)
    800046fa:	10d7e863          	bltu	a5,a3,8000480a <writei+0x112>
{
    800046fe:	7159                	addi	sp,sp,-112
    80004700:	f486                	sd	ra,104(sp)
    80004702:	f0a2                	sd	s0,96(sp)
    80004704:	eca6                	sd	s1,88(sp)
    80004706:	e8ca                	sd	s2,80(sp)
    80004708:	e4ce                	sd	s3,72(sp)
    8000470a:	e0d2                	sd	s4,64(sp)
    8000470c:	fc56                	sd	s5,56(sp)
    8000470e:	f85a                	sd	s6,48(sp)
    80004710:	f45e                	sd	s7,40(sp)
    80004712:	f062                	sd	s8,32(sp)
    80004714:	ec66                	sd	s9,24(sp)
    80004716:	e86a                	sd	s10,16(sp)
    80004718:	e46e                	sd	s11,8(sp)
    8000471a:	1880                	addi	s0,sp,112
    8000471c:	8aaa                	mv	s5,a0
    8000471e:	8bae                	mv	s7,a1
    80004720:	8a32                	mv	s4,a2
    80004722:	8936                	mv	s2,a3
    80004724:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004726:	00e687bb          	addw	a5,a3,a4
    8000472a:	0ed7e263          	bltu	a5,a3,8000480e <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000472e:	00043737          	lui	a4,0x43
    80004732:	0ef76063          	bltu	a4,a5,80004812 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004736:	0c0b0863          	beqz	s6,80004806 <writei+0x10e>
    8000473a:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000473c:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004740:	5c7d                	li	s8,-1
    80004742:	a091                	j	80004786 <writei+0x8e>
    80004744:	020d1d93          	slli	s11,s10,0x20
    80004748:	020ddd93          	srli	s11,s11,0x20
    8000474c:	05848513          	addi	a0,s1,88
    80004750:	86ee                	mv	a3,s11
    80004752:	8652                	mv	a2,s4
    80004754:	85de                	mv	a1,s7
    80004756:	953a                	add	a0,a0,a4
    80004758:	ffffe097          	auipc	ra,0xffffe
    8000475c:	2c0080e7          	jalr	704(ra) # 80002a18 <either_copyin>
    80004760:	07850263          	beq	a0,s8,800047c4 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004764:	8526                	mv	a0,s1
    80004766:	00000097          	auipc	ra,0x0
    8000476a:	780080e7          	jalr	1920(ra) # 80004ee6 <log_write>
    brelse(bp);
    8000476e:	8526                	mv	a0,s1
    80004770:	fffff097          	auipc	ra,0xfffff
    80004774:	4f2080e7          	jalr	1266(ra) # 80003c62 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004778:	013d09bb          	addw	s3,s10,s3
    8000477c:	012d093b          	addw	s2,s10,s2
    80004780:	9a6e                	add	s4,s4,s11
    80004782:	0569f663          	bgeu	s3,s6,800047ce <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004786:	00a9559b          	srliw	a1,s2,0xa
    8000478a:	8556                	mv	a0,s5
    8000478c:	fffff097          	auipc	ra,0xfffff
    80004790:	7a0080e7          	jalr	1952(ra) # 80003f2c <bmap>
    80004794:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004798:	c99d                	beqz	a1,800047ce <writei+0xd6>
    bp = bread(ip->dev, addr);
    8000479a:	000aa503          	lw	a0,0(s5)
    8000479e:	fffff097          	auipc	ra,0xfffff
    800047a2:	394080e7          	jalr	916(ra) # 80003b32 <bread>
    800047a6:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800047a8:	3ff97713          	andi	a4,s2,1023
    800047ac:	40ec87bb          	subw	a5,s9,a4
    800047b0:	413b06bb          	subw	a3,s6,s3
    800047b4:	8d3e                	mv	s10,a5
    800047b6:	2781                	sext.w	a5,a5
    800047b8:	0006861b          	sext.w	a2,a3
    800047bc:	f8f674e3          	bgeu	a2,a5,80004744 <writei+0x4c>
    800047c0:	8d36                	mv	s10,a3
    800047c2:	b749                	j	80004744 <writei+0x4c>
      brelse(bp);
    800047c4:	8526                	mv	a0,s1
    800047c6:	fffff097          	auipc	ra,0xfffff
    800047ca:	49c080e7          	jalr	1180(ra) # 80003c62 <brelse>
  }

  if(off > ip->size)
    800047ce:	04caa783          	lw	a5,76(s5)
    800047d2:	0127f463          	bgeu	a5,s2,800047da <writei+0xe2>
    ip->size = off;
    800047d6:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800047da:	8556                	mv	a0,s5
    800047dc:	00000097          	auipc	ra,0x0
    800047e0:	aa6080e7          	jalr	-1370(ra) # 80004282 <iupdate>

  return tot;
    800047e4:	0009851b          	sext.w	a0,s3
}
    800047e8:	70a6                	ld	ra,104(sp)
    800047ea:	7406                	ld	s0,96(sp)
    800047ec:	64e6                	ld	s1,88(sp)
    800047ee:	6946                	ld	s2,80(sp)
    800047f0:	69a6                	ld	s3,72(sp)
    800047f2:	6a06                	ld	s4,64(sp)
    800047f4:	7ae2                	ld	s5,56(sp)
    800047f6:	7b42                	ld	s6,48(sp)
    800047f8:	7ba2                	ld	s7,40(sp)
    800047fa:	7c02                	ld	s8,32(sp)
    800047fc:	6ce2                	ld	s9,24(sp)
    800047fe:	6d42                	ld	s10,16(sp)
    80004800:	6da2                	ld	s11,8(sp)
    80004802:	6165                	addi	sp,sp,112
    80004804:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004806:	89da                	mv	s3,s6
    80004808:	bfc9                	j	800047da <writei+0xe2>
    return -1;
    8000480a:	557d                	li	a0,-1
}
    8000480c:	8082                	ret
    return -1;
    8000480e:	557d                	li	a0,-1
    80004810:	bfe1                	j	800047e8 <writei+0xf0>
    return -1;
    80004812:	557d                	li	a0,-1
    80004814:	bfd1                	j	800047e8 <writei+0xf0>

0000000080004816 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004816:	1141                	addi	sp,sp,-16
    80004818:	e406                	sd	ra,8(sp)
    8000481a:	e022                	sd	s0,0(sp)
    8000481c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000481e:	4639                	li	a2,14
    80004820:	ffffc097          	auipc	ra,0xffffc
    80004824:	59e080e7          	jalr	1438(ra) # 80000dbe <strncmp>
}
    80004828:	60a2                	ld	ra,8(sp)
    8000482a:	6402                	ld	s0,0(sp)
    8000482c:	0141                	addi	sp,sp,16
    8000482e:	8082                	ret

0000000080004830 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004830:	7139                	addi	sp,sp,-64
    80004832:	fc06                	sd	ra,56(sp)
    80004834:	f822                	sd	s0,48(sp)
    80004836:	f426                	sd	s1,40(sp)
    80004838:	f04a                	sd	s2,32(sp)
    8000483a:	ec4e                	sd	s3,24(sp)
    8000483c:	e852                	sd	s4,16(sp)
    8000483e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004840:	04451703          	lh	a4,68(a0)
    80004844:	4785                	li	a5,1
    80004846:	00f71a63          	bne	a4,a5,8000485a <dirlookup+0x2a>
    8000484a:	892a                	mv	s2,a0
    8000484c:	89ae                	mv	s3,a1
    8000484e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004850:	457c                	lw	a5,76(a0)
    80004852:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004854:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004856:	e79d                	bnez	a5,80004884 <dirlookup+0x54>
    80004858:	a8a5                	j	800048d0 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000485a:	00005517          	auipc	a0,0x5
    8000485e:	f5e50513          	addi	a0,a0,-162 # 800097b8 <syscalls+0x1d0>
    80004862:	ffffc097          	auipc	ra,0xffffc
    80004866:	ce2080e7          	jalr	-798(ra) # 80000544 <panic>
      panic("dirlookup read");
    8000486a:	00005517          	auipc	a0,0x5
    8000486e:	f6650513          	addi	a0,a0,-154 # 800097d0 <syscalls+0x1e8>
    80004872:	ffffc097          	auipc	ra,0xffffc
    80004876:	cd2080e7          	jalr	-814(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000487a:	24c1                	addiw	s1,s1,16
    8000487c:	04c92783          	lw	a5,76(s2)
    80004880:	04f4f763          	bgeu	s1,a5,800048ce <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004884:	4741                	li	a4,16
    80004886:	86a6                	mv	a3,s1
    80004888:	fc040613          	addi	a2,s0,-64
    8000488c:	4581                	li	a1,0
    8000488e:	854a                	mv	a0,s2
    80004890:	00000097          	auipc	ra,0x0
    80004894:	d70080e7          	jalr	-656(ra) # 80004600 <readi>
    80004898:	47c1                	li	a5,16
    8000489a:	fcf518e3          	bne	a0,a5,8000486a <dirlookup+0x3a>
    if(de.inum == 0)
    8000489e:	fc045783          	lhu	a5,-64(s0)
    800048a2:	dfe1                	beqz	a5,8000487a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800048a4:	fc240593          	addi	a1,s0,-62
    800048a8:	854e                	mv	a0,s3
    800048aa:	00000097          	auipc	ra,0x0
    800048ae:	f6c080e7          	jalr	-148(ra) # 80004816 <namecmp>
    800048b2:	f561                	bnez	a0,8000487a <dirlookup+0x4a>
      if(poff)
    800048b4:	000a0463          	beqz	s4,800048bc <dirlookup+0x8c>
        *poff = off;
    800048b8:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800048bc:	fc045583          	lhu	a1,-64(s0)
    800048c0:	00092503          	lw	a0,0(s2)
    800048c4:	fffff097          	auipc	ra,0xfffff
    800048c8:	750080e7          	jalr	1872(ra) # 80004014 <iget>
    800048cc:	a011                	j	800048d0 <dirlookup+0xa0>
  return 0;
    800048ce:	4501                	li	a0,0
}
    800048d0:	70e2                	ld	ra,56(sp)
    800048d2:	7442                	ld	s0,48(sp)
    800048d4:	74a2                	ld	s1,40(sp)
    800048d6:	7902                	ld	s2,32(sp)
    800048d8:	69e2                	ld	s3,24(sp)
    800048da:	6a42                	ld	s4,16(sp)
    800048dc:	6121                	addi	sp,sp,64
    800048de:	8082                	ret

00000000800048e0 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800048e0:	711d                	addi	sp,sp,-96
    800048e2:	ec86                	sd	ra,88(sp)
    800048e4:	e8a2                	sd	s0,80(sp)
    800048e6:	e4a6                	sd	s1,72(sp)
    800048e8:	e0ca                	sd	s2,64(sp)
    800048ea:	fc4e                	sd	s3,56(sp)
    800048ec:	f852                	sd	s4,48(sp)
    800048ee:	f456                	sd	s5,40(sp)
    800048f0:	f05a                	sd	s6,32(sp)
    800048f2:	ec5e                	sd	s7,24(sp)
    800048f4:	e862                	sd	s8,16(sp)
    800048f6:	e466                	sd	s9,8(sp)
    800048f8:	1080                	addi	s0,sp,96
    800048fa:	84aa                	mv	s1,a0
    800048fc:	8b2e                	mv	s6,a1
    800048fe:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004900:	00054703          	lbu	a4,0(a0)
    80004904:	02f00793          	li	a5,47
    80004908:	02f70363          	beq	a4,a5,8000492e <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000490c:	ffffd097          	auipc	ra,0xffffd
    80004910:	2ba080e7          	jalr	698(ra) # 80001bc6 <myproc>
    80004914:	15053503          	ld	a0,336(a0)
    80004918:	00000097          	auipc	ra,0x0
    8000491c:	9f6080e7          	jalr	-1546(ra) # 8000430e <idup>
    80004920:	89aa                	mv	s3,a0
  while(*path == '/')
    80004922:	02f00913          	li	s2,47
  len = path - s;
    80004926:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004928:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000492a:	4c05                	li	s8,1
    8000492c:	a865                	j	800049e4 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000492e:	4585                	li	a1,1
    80004930:	4505                	li	a0,1
    80004932:	fffff097          	auipc	ra,0xfffff
    80004936:	6e2080e7          	jalr	1762(ra) # 80004014 <iget>
    8000493a:	89aa                	mv	s3,a0
    8000493c:	b7dd                	j	80004922 <namex+0x42>
      iunlockput(ip);
    8000493e:	854e                	mv	a0,s3
    80004940:	00000097          	auipc	ra,0x0
    80004944:	c6e080e7          	jalr	-914(ra) # 800045ae <iunlockput>
      return 0;
    80004948:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000494a:	854e                	mv	a0,s3
    8000494c:	60e6                	ld	ra,88(sp)
    8000494e:	6446                	ld	s0,80(sp)
    80004950:	64a6                	ld	s1,72(sp)
    80004952:	6906                	ld	s2,64(sp)
    80004954:	79e2                	ld	s3,56(sp)
    80004956:	7a42                	ld	s4,48(sp)
    80004958:	7aa2                	ld	s5,40(sp)
    8000495a:	7b02                	ld	s6,32(sp)
    8000495c:	6be2                	ld	s7,24(sp)
    8000495e:	6c42                	ld	s8,16(sp)
    80004960:	6ca2                	ld	s9,8(sp)
    80004962:	6125                	addi	sp,sp,96
    80004964:	8082                	ret
      iunlock(ip);
    80004966:	854e                	mv	a0,s3
    80004968:	00000097          	auipc	ra,0x0
    8000496c:	aa6080e7          	jalr	-1370(ra) # 8000440e <iunlock>
      return ip;
    80004970:	bfe9                	j	8000494a <namex+0x6a>
      iunlockput(ip);
    80004972:	854e                	mv	a0,s3
    80004974:	00000097          	auipc	ra,0x0
    80004978:	c3a080e7          	jalr	-966(ra) # 800045ae <iunlockput>
      return 0;
    8000497c:	89d2                	mv	s3,s4
    8000497e:	b7f1                	j	8000494a <namex+0x6a>
  len = path - s;
    80004980:	40b48633          	sub	a2,s1,a1
    80004984:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004988:	094cd463          	bge	s9,s4,80004a10 <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000498c:	4639                	li	a2,14
    8000498e:	8556                	mv	a0,s5
    80004990:	ffffc097          	auipc	ra,0xffffc
    80004994:	3b6080e7          	jalr	950(ra) # 80000d46 <memmove>
  while(*path == '/')
    80004998:	0004c783          	lbu	a5,0(s1)
    8000499c:	01279763          	bne	a5,s2,800049aa <namex+0xca>
    path++;
    800049a0:	0485                	addi	s1,s1,1
  while(*path == '/')
    800049a2:	0004c783          	lbu	a5,0(s1)
    800049a6:	ff278de3          	beq	a5,s2,800049a0 <namex+0xc0>
    ilock(ip);
    800049aa:	854e                	mv	a0,s3
    800049ac:	00000097          	auipc	ra,0x0
    800049b0:	9a0080e7          	jalr	-1632(ra) # 8000434c <ilock>
    if(ip->type != T_DIR){
    800049b4:	04499783          	lh	a5,68(s3)
    800049b8:	f98793e3          	bne	a5,s8,8000493e <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800049bc:	000b0563          	beqz	s6,800049c6 <namex+0xe6>
    800049c0:	0004c783          	lbu	a5,0(s1)
    800049c4:	d3cd                	beqz	a5,80004966 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800049c6:	865e                	mv	a2,s7
    800049c8:	85d6                	mv	a1,s5
    800049ca:	854e                	mv	a0,s3
    800049cc:	00000097          	auipc	ra,0x0
    800049d0:	e64080e7          	jalr	-412(ra) # 80004830 <dirlookup>
    800049d4:	8a2a                	mv	s4,a0
    800049d6:	dd51                	beqz	a0,80004972 <namex+0x92>
    iunlockput(ip);
    800049d8:	854e                	mv	a0,s3
    800049da:	00000097          	auipc	ra,0x0
    800049de:	bd4080e7          	jalr	-1068(ra) # 800045ae <iunlockput>
    ip = next;
    800049e2:	89d2                	mv	s3,s4
  while(*path == '/')
    800049e4:	0004c783          	lbu	a5,0(s1)
    800049e8:	05279763          	bne	a5,s2,80004a36 <namex+0x156>
    path++;
    800049ec:	0485                	addi	s1,s1,1
  while(*path == '/')
    800049ee:	0004c783          	lbu	a5,0(s1)
    800049f2:	ff278de3          	beq	a5,s2,800049ec <namex+0x10c>
  if(*path == 0)
    800049f6:	c79d                	beqz	a5,80004a24 <namex+0x144>
    path++;
    800049f8:	85a6                	mv	a1,s1
  len = path - s;
    800049fa:	8a5e                	mv	s4,s7
    800049fc:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800049fe:	01278963          	beq	a5,s2,80004a10 <namex+0x130>
    80004a02:	dfbd                	beqz	a5,80004980 <namex+0xa0>
    path++;
    80004a04:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004a06:	0004c783          	lbu	a5,0(s1)
    80004a0a:	ff279ce3          	bne	a5,s2,80004a02 <namex+0x122>
    80004a0e:	bf8d                	j	80004980 <namex+0xa0>
    memmove(name, s, len);
    80004a10:	2601                	sext.w	a2,a2
    80004a12:	8556                	mv	a0,s5
    80004a14:	ffffc097          	auipc	ra,0xffffc
    80004a18:	332080e7          	jalr	818(ra) # 80000d46 <memmove>
    name[len] = 0;
    80004a1c:	9a56                	add	s4,s4,s5
    80004a1e:	000a0023          	sb	zero,0(s4)
    80004a22:	bf9d                	j	80004998 <namex+0xb8>
  if(nameiparent){
    80004a24:	f20b03e3          	beqz	s6,8000494a <namex+0x6a>
    iput(ip);
    80004a28:	854e                	mv	a0,s3
    80004a2a:	00000097          	auipc	ra,0x0
    80004a2e:	adc080e7          	jalr	-1316(ra) # 80004506 <iput>
    return 0;
    80004a32:	4981                	li	s3,0
    80004a34:	bf19                	j	8000494a <namex+0x6a>
  if(*path == 0)
    80004a36:	d7fd                	beqz	a5,80004a24 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004a38:	0004c783          	lbu	a5,0(s1)
    80004a3c:	85a6                	mv	a1,s1
    80004a3e:	b7d1                	j	80004a02 <namex+0x122>

0000000080004a40 <dirlink>:
{
    80004a40:	7139                	addi	sp,sp,-64
    80004a42:	fc06                	sd	ra,56(sp)
    80004a44:	f822                	sd	s0,48(sp)
    80004a46:	f426                	sd	s1,40(sp)
    80004a48:	f04a                	sd	s2,32(sp)
    80004a4a:	ec4e                	sd	s3,24(sp)
    80004a4c:	e852                	sd	s4,16(sp)
    80004a4e:	0080                	addi	s0,sp,64
    80004a50:	892a                	mv	s2,a0
    80004a52:	8a2e                	mv	s4,a1
    80004a54:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004a56:	4601                	li	a2,0
    80004a58:	00000097          	auipc	ra,0x0
    80004a5c:	dd8080e7          	jalr	-552(ra) # 80004830 <dirlookup>
    80004a60:	e93d                	bnez	a0,80004ad6 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004a62:	04c92483          	lw	s1,76(s2)
    80004a66:	c49d                	beqz	s1,80004a94 <dirlink+0x54>
    80004a68:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004a6a:	4741                	li	a4,16
    80004a6c:	86a6                	mv	a3,s1
    80004a6e:	fc040613          	addi	a2,s0,-64
    80004a72:	4581                	li	a1,0
    80004a74:	854a                	mv	a0,s2
    80004a76:	00000097          	auipc	ra,0x0
    80004a7a:	b8a080e7          	jalr	-1142(ra) # 80004600 <readi>
    80004a7e:	47c1                	li	a5,16
    80004a80:	06f51163          	bne	a0,a5,80004ae2 <dirlink+0xa2>
    if(de.inum == 0)
    80004a84:	fc045783          	lhu	a5,-64(s0)
    80004a88:	c791                	beqz	a5,80004a94 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004a8a:	24c1                	addiw	s1,s1,16
    80004a8c:	04c92783          	lw	a5,76(s2)
    80004a90:	fcf4ede3          	bltu	s1,a5,80004a6a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004a94:	4639                	li	a2,14
    80004a96:	85d2                	mv	a1,s4
    80004a98:	fc240513          	addi	a0,s0,-62
    80004a9c:	ffffc097          	auipc	ra,0xffffc
    80004aa0:	35e080e7          	jalr	862(ra) # 80000dfa <strncpy>
  de.inum = inum;
    80004aa4:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004aa8:	4741                	li	a4,16
    80004aaa:	86a6                	mv	a3,s1
    80004aac:	fc040613          	addi	a2,s0,-64
    80004ab0:	4581                	li	a1,0
    80004ab2:	854a                	mv	a0,s2
    80004ab4:	00000097          	auipc	ra,0x0
    80004ab8:	c44080e7          	jalr	-956(ra) # 800046f8 <writei>
    80004abc:	1541                	addi	a0,a0,-16
    80004abe:	00a03533          	snez	a0,a0
    80004ac2:	40a00533          	neg	a0,a0
}
    80004ac6:	70e2                	ld	ra,56(sp)
    80004ac8:	7442                	ld	s0,48(sp)
    80004aca:	74a2                	ld	s1,40(sp)
    80004acc:	7902                	ld	s2,32(sp)
    80004ace:	69e2                	ld	s3,24(sp)
    80004ad0:	6a42                	ld	s4,16(sp)
    80004ad2:	6121                	addi	sp,sp,64
    80004ad4:	8082                	ret
    iput(ip);
    80004ad6:	00000097          	auipc	ra,0x0
    80004ada:	a30080e7          	jalr	-1488(ra) # 80004506 <iput>
    return -1;
    80004ade:	557d                	li	a0,-1
    80004ae0:	b7dd                	j	80004ac6 <dirlink+0x86>
      panic("dirlink read");
    80004ae2:	00005517          	auipc	a0,0x5
    80004ae6:	cfe50513          	addi	a0,a0,-770 # 800097e0 <syscalls+0x1f8>
    80004aea:	ffffc097          	auipc	ra,0xffffc
    80004aee:	a5a080e7          	jalr	-1446(ra) # 80000544 <panic>

0000000080004af2 <namei>:

struct inode*
namei(char *path)
{
    80004af2:	1101                	addi	sp,sp,-32
    80004af4:	ec06                	sd	ra,24(sp)
    80004af6:	e822                	sd	s0,16(sp)
    80004af8:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004afa:	fe040613          	addi	a2,s0,-32
    80004afe:	4581                	li	a1,0
    80004b00:	00000097          	auipc	ra,0x0
    80004b04:	de0080e7          	jalr	-544(ra) # 800048e0 <namex>
}
    80004b08:	60e2                	ld	ra,24(sp)
    80004b0a:	6442                	ld	s0,16(sp)
    80004b0c:	6105                	addi	sp,sp,32
    80004b0e:	8082                	ret

0000000080004b10 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004b10:	1141                	addi	sp,sp,-16
    80004b12:	e406                	sd	ra,8(sp)
    80004b14:	e022                	sd	s0,0(sp)
    80004b16:	0800                	addi	s0,sp,16
    80004b18:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004b1a:	4585                	li	a1,1
    80004b1c:	00000097          	auipc	ra,0x0
    80004b20:	dc4080e7          	jalr	-572(ra) # 800048e0 <namex>
}
    80004b24:	60a2                	ld	ra,8(sp)
    80004b26:	6402                	ld	s0,0(sp)
    80004b28:	0141                	addi	sp,sp,16
    80004b2a:	8082                	ret

0000000080004b2c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004b2c:	1101                	addi	sp,sp,-32
    80004b2e:	ec06                	sd	ra,24(sp)
    80004b30:	e822                	sd	s0,16(sp)
    80004b32:	e426                	sd	s1,8(sp)
    80004b34:	e04a                	sd	s2,0(sp)
    80004b36:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004b38:	0001f917          	auipc	s2,0x1f
    80004b3c:	52090913          	addi	s2,s2,1312 # 80024058 <log>
    80004b40:	01892583          	lw	a1,24(s2)
    80004b44:	02892503          	lw	a0,40(s2)
    80004b48:	fffff097          	auipc	ra,0xfffff
    80004b4c:	fea080e7          	jalr	-22(ra) # 80003b32 <bread>
    80004b50:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004b52:	02c92683          	lw	a3,44(s2)
    80004b56:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004b58:	02d05763          	blez	a3,80004b86 <write_head+0x5a>
    80004b5c:	0001f797          	auipc	a5,0x1f
    80004b60:	52c78793          	addi	a5,a5,1324 # 80024088 <log+0x30>
    80004b64:	05c50713          	addi	a4,a0,92
    80004b68:	36fd                	addiw	a3,a3,-1
    80004b6a:	1682                	slli	a3,a3,0x20
    80004b6c:	9281                	srli	a3,a3,0x20
    80004b6e:	068a                	slli	a3,a3,0x2
    80004b70:	0001f617          	auipc	a2,0x1f
    80004b74:	51c60613          	addi	a2,a2,1308 # 8002408c <log+0x34>
    80004b78:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004b7a:	4390                	lw	a2,0(a5)
    80004b7c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004b7e:	0791                	addi	a5,a5,4
    80004b80:	0711                	addi	a4,a4,4
    80004b82:	fed79ce3          	bne	a5,a3,80004b7a <write_head+0x4e>
  }
  bwrite(buf);
    80004b86:	8526                	mv	a0,s1
    80004b88:	fffff097          	auipc	ra,0xfffff
    80004b8c:	09c080e7          	jalr	156(ra) # 80003c24 <bwrite>
  brelse(buf);
    80004b90:	8526                	mv	a0,s1
    80004b92:	fffff097          	auipc	ra,0xfffff
    80004b96:	0d0080e7          	jalr	208(ra) # 80003c62 <brelse>
}
    80004b9a:	60e2                	ld	ra,24(sp)
    80004b9c:	6442                	ld	s0,16(sp)
    80004b9e:	64a2                	ld	s1,8(sp)
    80004ba0:	6902                	ld	s2,0(sp)
    80004ba2:	6105                	addi	sp,sp,32
    80004ba4:	8082                	ret

0000000080004ba6 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004ba6:	0001f797          	auipc	a5,0x1f
    80004baa:	4de7a783          	lw	a5,1246(a5) # 80024084 <log+0x2c>
    80004bae:	0af05d63          	blez	a5,80004c68 <install_trans+0xc2>
{
    80004bb2:	7139                	addi	sp,sp,-64
    80004bb4:	fc06                	sd	ra,56(sp)
    80004bb6:	f822                	sd	s0,48(sp)
    80004bb8:	f426                	sd	s1,40(sp)
    80004bba:	f04a                	sd	s2,32(sp)
    80004bbc:	ec4e                	sd	s3,24(sp)
    80004bbe:	e852                	sd	s4,16(sp)
    80004bc0:	e456                	sd	s5,8(sp)
    80004bc2:	e05a                	sd	s6,0(sp)
    80004bc4:	0080                	addi	s0,sp,64
    80004bc6:	8b2a                	mv	s6,a0
    80004bc8:	0001fa97          	auipc	s5,0x1f
    80004bcc:	4c0a8a93          	addi	s5,s5,1216 # 80024088 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004bd0:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004bd2:	0001f997          	auipc	s3,0x1f
    80004bd6:	48698993          	addi	s3,s3,1158 # 80024058 <log>
    80004bda:	a035                	j	80004c06 <install_trans+0x60>
      bunpin(dbuf);
    80004bdc:	8526                	mv	a0,s1
    80004bde:	fffff097          	auipc	ra,0xfffff
    80004be2:	15e080e7          	jalr	350(ra) # 80003d3c <bunpin>
    brelse(lbuf);
    80004be6:	854a                	mv	a0,s2
    80004be8:	fffff097          	auipc	ra,0xfffff
    80004bec:	07a080e7          	jalr	122(ra) # 80003c62 <brelse>
    brelse(dbuf);
    80004bf0:	8526                	mv	a0,s1
    80004bf2:	fffff097          	auipc	ra,0xfffff
    80004bf6:	070080e7          	jalr	112(ra) # 80003c62 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004bfa:	2a05                	addiw	s4,s4,1
    80004bfc:	0a91                	addi	s5,s5,4
    80004bfe:	02c9a783          	lw	a5,44(s3)
    80004c02:	04fa5963          	bge	s4,a5,80004c54 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004c06:	0189a583          	lw	a1,24(s3)
    80004c0a:	014585bb          	addw	a1,a1,s4
    80004c0e:	2585                	addiw	a1,a1,1
    80004c10:	0289a503          	lw	a0,40(s3)
    80004c14:	fffff097          	auipc	ra,0xfffff
    80004c18:	f1e080e7          	jalr	-226(ra) # 80003b32 <bread>
    80004c1c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004c1e:	000aa583          	lw	a1,0(s5)
    80004c22:	0289a503          	lw	a0,40(s3)
    80004c26:	fffff097          	auipc	ra,0xfffff
    80004c2a:	f0c080e7          	jalr	-244(ra) # 80003b32 <bread>
    80004c2e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004c30:	40000613          	li	a2,1024
    80004c34:	05890593          	addi	a1,s2,88
    80004c38:	05850513          	addi	a0,a0,88
    80004c3c:	ffffc097          	auipc	ra,0xffffc
    80004c40:	10a080e7          	jalr	266(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004c44:	8526                	mv	a0,s1
    80004c46:	fffff097          	auipc	ra,0xfffff
    80004c4a:	fde080e7          	jalr	-34(ra) # 80003c24 <bwrite>
    if(recovering == 0)
    80004c4e:	f80b1ce3          	bnez	s6,80004be6 <install_trans+0x40>
    80004c52:	b769                	j	80004bdc <install_trans+0x36>
}
    80004c54:	70e2                	ld	ra,56(sp)
    80004c56:	7442                	ld	s0,48(sp)
    80004c58:	74a2                	ld	s1,40(sp)
    80004c5a:	7902                	ld	s2,32(sp)
    80004c5c:	69e2                	ld	s3,24(sp)
    80004c5e:	6a42                	ld	s4,16(sp)
    80004c60:	6aa2                	ld	s5,8(sp)
    80004c62:	6b02                	ld	s6,0(sp)
    80004c64:	6121                	addi	sp,sp,64
    80004c66:	8082                	ret
    80004c68:	8082                	ret

0000000080004c6a <initlog>:
{
    80004c6a:	7179                	addi	sp,sp,-48
    80004c6c:	f406                	sd	ra,40(sp)
    80004c6e:	f022                	sd	s0,32(sp)
    80004c70:	ec26                	sd	s1,24(sp)
    80004c72:	e84a                	sd	s2,16(sp)
    80004c74:	e44e                	sd	s3,8(sp)
    80004c76:	1800                	addi	s0,sp,48
    80004c78:	892a                	mv	s2,a0
    80004c7a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004c7c:	0001f497          	auipc	s1,0x1f
    80004c80:	3dc48493          	addi	s1,s1,988 # 80024058 <log>
    80004c84:	00005597          	auipc	a1,0x5
    80004c88:	b6c58593          	addi	a1,a1,-1172 # 800097f0 <syscalls+0x208>
    80004c8c:	8526                	mv	a0,s1
    80004c8e:	ffffc097          	auipc	ra,0xffffc
    80004c92:	ecc080e7          	jalr	-308(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    80004c96:	0149a583          	lw	a1,20(s3)
    80004c9a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004c9c:	0109a783          	lw	a5,16(s3)
    80004ca0:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004ca2:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004ca6:	854a                	mv	a0,s2
    80004ca8:	fffff097          	auipc	ra,0xfffff
    80004cac:	e8a080e7          	jalr	-374(ra) # 80003b32 <bread>
  log.lh.n = lh->n;
    80004cb0:	4d3c                	lw	a5,88(a0)
    80004cb2:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004cb4:	02f05563          	blez	a5,80004cde <initlog+0x74>
    80004cb8:	05c50713          	addi	a4,a0,92
    80004cbc:	0001f697          	auipc	a3,0x1f
    80004cc0:	3cc68693          	addi	a3,a3,972 # 80024088 <log+0x30>
    80004cc4:	37fd                	addiw	a5,a5,-1
    80004cc6:	1782                	slli	a5,a5,0x20
    80004cc8:	9381                	srli	a5,a5,0x20
    80004cca:	078a                	slli	a5,a5,0x2
    80004ccc:	06050613          	addi	a2,a0,96
    80004cd0:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004cd2:	4310                	lw	a2,0(a4)
    80004cd4:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004cd6:	0711                	addi	a4,a4,4
    80004cd8:	0691                	addi	a3,a3,4
    80004cda:	fef71ce3          	bne	a4,a5,80004cd2 <initlog+0x68>
  brelse(buf);
    80004cde:	fffff097          	auipc	ra,0xfffff
    80004ce2:	f84080e7          	jalr	-124(ra) # 80003c62 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004ce6:	4505                	li	a0,1
    80004ce8:	00000097          	auipc	ra,0x0
    80004cec:	ebe080e7          	jalr	-322(ra) # 80004ba6 <install_trans>
  log.lh.n = 0;
    80004cf0:	0001f797          	auipc	a5,0x1f
    80004cf4:	3807aa23          	sw	zero,916(a5) # 80024084 <log+0x2c>
  write_head(); // clear the log
    80004cf8:	00000097          	auipc	ra,0x0
    80004cfc:	e34080e7          	jalr	-460(ra) # 80004b2c <write_head>
}
    80004d00:	70a2                	ld	ra,40(sp)
    80004d02:	7402                	ld	s0,32(sp)
    80004d04:	64e2                	ld	s1,24(sp)
    80004d06:	6942                	ld	s2,16(sp)
    80004d08:	69a2                	ld	s3,8(sp)
    80004d0a:	6145                	addi	sp,sp,48
    80004d0c:	8082                	ret

0000000080004d0e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004d0e:	1101                	addi	sp,sp,-32
    80004d10:	ec06                	sd	ra,24(sp)
    80004d12:	e822                	sd	s0,16(sp)
    80004d14:	e426                	sd	s1,8(sp)
    80004d16:	e04a                	sd	s2,0(sp)
    80004d18:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004d1a:	0001f517          	auipc	a0,0x1f
    80004d1e:	33e50513          	addi	a0,a0,830 # 80024058 <log>
    80004d22:	ffffc097          	auipc	ra,0xffffc
    80004d26:	ec8080e7          	jalr	-312(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    80004d2a:	0001f497          	auipc	s1,0x1f
    80004d2e:	32e48493          	addi	s1,s1,814 # 80024058 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004d32:	4979                	li	s2,30
    80004d34:	a039                	j	80004d42 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004d36:	85a6                	mv	a1,s1
    80004d38:	8526                	mv	a0,s1
    80004d3a:	ffffd097          	auipc	ra,0xffffd
    80004d3e:	728080e7          	jalr	1832(ra) # 80002462 <sleep>
    if(log.committing){
    80004d42:	50dc                	lw	a5,36(s1)
    80004d44:	fbed                	bnez	a5,80004d36 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004d46:	509c                	lw	a5,32(s1)
    80004d48:	0017871b          	addiw	a4,a5,1
    80004d4c:	0007069b          	sext.w	a3,a4
    80004d50:	0027179b          	slliw	a5,a4,0x2
    80004d54:	9fb9                	addw	a5,a5,a4
    80004d56:	0017979b          	slliw	a5,a5,0x1
    80004d5a:	54d8                	lw	a4,44(s1)
    80004d5c:	9fb9                	addw	a5,a5,a4
    80004d5e:	00f95963          	bge	s2,a5,80004d70 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004d62:	85a6                	mv	a1,s1
    80004d64:	8526                	mv	a0,s1
    80004d66:	ffffd097          	auipc	ra,0xffffd
    80004d6a:	6fc080e7          	jalr	1788(ra) # 80002462 <sleep>
    80004d6e:	bfd1                	j	80004d42 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004d70:	0001f517          	auipc	a0,0x1f
    80004d74:	2e850513          	addi	a0,a0,744 # 80024058 <log>
    80004d78:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004d7a:	ffffc097          	auipc	ra,0xffffc
    80004d7e:	f24080e7          	jalr	-220(ra) # 80000c9e <release>
      break;
    }
  }
}
    80004d82:	60e2                	ld	ra,24(sp)
    80004d84:	6442                	ld	s0,16(sp)
    80004d86:	64a2                	ld	s1,8(sp)
    80004d88:	6902                	ld	s2,0(sp)
    80004d8a:	6105                	addi	sp,sp,32
    80004d8c:	8082                	ret

0000000080004d8e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004d8e:	7139                	addi	sp,sp,-64
    80004d90:	fc06                	sd	ra,56(sp)
    80004d92:	f822                	sd	s0,48(sp)
    80004d94:	f426                	sd	s1,40(sp)
    80004d96:	f04a                	sd	s2,32(sp)
    80004d98:	ec4e                	sd	s3,24(sp)
    80004d9a:	e852                	sd	s4,16(sp)
    80004d9c:	e456                	sd	s5,8(sp)
    80004d9e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004da0:	0001f497          	auipc	s1,0x1f
    80004da4:	2b848493          	addi	s1,s1,696 # 80024058 <log>
    80004da8:	8526                	mv	a0,s1
    80004daa:	ffffc097          	auipc	ra,0xffffc
    80004dae:	e40080e7          	jalr	-448(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    80004db2:	509c                	lw	a5,32(s1)
    80004db4:	37fd                	addiw	a5,a5,-1
    80004db6:	0007891b          	sext.w	s2,a5
    80004dba:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004dbc:	50dc                	lw	a5,36(s1)
    80004dbe:	efb9                	bnez	a5,80004e1c <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004dc0:	06091663          	bnez	s2,80004e2c <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004dc4:	0001f497          	auipc	s1,0x1f
    80004dc8:	29448493          	addi	s1,s1,660 # 80024058 <log>
    80004dcc:	4785                	li	a5,1
    80004dce:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004dd0:	8526                	mv	a0,s1
    80004dd2:	ffffc097          	auipc	ra,0xffffc
    80004dd6:	ecc080e7          	jalr	-308(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004dda:	54dc                	lw	a5,44(s1)
    80004ddc:	06f04763          	bgtz	a5,80004e4a <end_op+0xbc>
    acquire(&log.lock);
    80004de0:	0001f497          	auipc	s1,0x1f
    80004de4:	27848493          	addi	s1,s1,632 # 80024058 <log>
    80004de8:	8526                	mv	a0,s1
    80004dea:	ffffc097          	auipc	ra,0xffffc
    80004dee:	e00080e7          	jalr	-512(ra) # 80000bea <acquire>
    log.committing = 0;
    80004df2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004df6:	8526                	mv	a0,s1
    80004df8:	ffffe097          	auipc	ra,0xffffe
    80004dfc:	81a080e7          	jalr	-2022(ra) # 80002612 <wakeup>
    release(&log.lock);
    80004e00:	8526                	mv	a0,s1
    80004e02:	ffffc097          	auipc	ra,0xffffc
    80004e06:	e9c080e7          	jalr	-356(ra) # 80000c9e <release>
}
    80004e0a:	70e2                	ld	ra,56(sp)
    80004e0c:	7442                	ld	s0,48(sp)
    80004e0e:	74a2                	ld	s1,40(sp)
    80004e10:	7902                	ld	s2,32(sp)
    80004e12:	69e2                	ld	s3,24(sp)
    80004e14:	6a42                	ld	s4,16(sp)
    80004e16:	6aa2                	ld	s5,8(sp)
    80004e18:	6121                	addi	sp,sp,64
    80004e1a:	8082                	ret
    panic("log.committing");
    80004e1c:	00005517          	auipc	a0,0x5
    80004e20:	9dc50513          	addi	a0,a0,-1572 # 800097f8 <syscalls+0x210>
    80004e24:	ffffb097          	auipc	ra,0xffffb
    80004e28:	720080e7          	jalr	1824(ra) # 80000544 <panic>
    wakeup(&log);
    80004e2c:	0001f497          	auipc	s1,0x1f
    80004e30:	22c48493          	addi	s1,s1,556 # 80024058 <log>
    80004e34:	8526                	mv	a0,s1
    80004e36:	ffffd097          	auipc	ra,0xffffd
    80004e3a:	7dc080e7          	jalr	2012(ra) # 80002612 <wakeup>
  release(&log.lock);
    80004e3e:	8526                	mv	a0,s1
    80004e40:	ffffc097          	auipc	ra,0xffffc
    80004e44:	e5e080e7          	jalr	-418(ra) # 80000c9e <release>
  if(do_commit){
    80004e48:	b7c9                	j	80004e0a <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004e4a:	0001fa97          	auipc	s5,0x1f
    80004e4e:	23ea8a93          	addi	s5,s5,574 # 80024088 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004e52:	0001fa17          	auipc	s4,0x1f
    80004e56:	206a0a13          	addi	s4,s4,518 # 80024058 <log>
    80004e5a:	018a2583          	lw	a1,24(s4)
    80004e5e:	012585bb          	addw	a1,a1,s2
    80004e62:	2585                	addiw	a1,a1,1
    80004e64:	028a2503          	lw	a0,40(s4)
    80004e68:	fffff097          	auipc	ra,0xfffff
    80004e6c:	cca080e7          	jalr	-822(ra) # 80003b32 <bread>
    80004e70:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004e72:	000aa583          	lw	a1,0(s5)
    80004e76:	028a2503          	lw	a0,40(s4)
    80004e7a:	fffff097          	auipc	ra,0xfffff
    80004e7e:	cb8080e7          	jalr	-840(ra) # 80003b32 <bread>
    80004e82:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004e84:	40000613          	li	a2,1024
    80004e88:	05850593          	addi	a1,a0,88
    80004e8c:	05848513          	addi	a0,s1,88
    80004e90:	ffffc097          	auipc	ra,0xffffc
    80004e94:	eb6080e7          	jalr	-330(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    80004e98:	8526                	mv	a0,s1
    80004e9a:	fffff097          	auipc	ra,0xfffff
    80004e9e:	d8a080e7          	jalr	-630(ra) # 80003c24 <bwrite>
    brelse(from);
    80004ea2:	854e                	mv	a0,s3
    80004ea4:	fffff097          	auipc	ra,0xfffff
    80004ea8:	dbe080e7          	jalr	-578(ra) # 80003c62 <brelse>
    brelse(to);
    80004eac:	8526                	mv	a0,s1
    80004eae:	fffff097          	auipc	ra,0xfffff
    80004eb2:	db4080e7          	jalr	-588(ra) # 80003c62 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004eb6:	2905                	addiw	s2,s2,1
    80004eb8:	0a91                	addi	s5,s5,4
    80004eba:	02ca2783          	lw	a5,44(s4)
    80004ebe:	f8f94ee3          	blt	s2,a5,80004e5a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004ec2:	00000097          	auipc	ra,0x0
    80004ec6:	c6a080e7          	jalr	-918(ra) # 80004b2c <write_head>
    install_trans(0); // Now install writes to home locations
    80004eca:	4501                	li	a0,0
    80004ecc:	00000097          	auipc	ra,0x0
    80004ed0:	cda080e7          	jalr	-806(ra) # 80004ba6 <install_trans>
    log.lh.n = 0;
    80004ed4:	0001f797          	auipc	a5,0x1f
    80004ed8:	1a07a823          	sw	zero,432(a5) # 80024084 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004edc:	00000097          	auipc	ra,0x0
    80004ee0:	c50080e7          	jalr	-944(ra) # 80004b2c <write_head>
    80004ee4:	bdf5                	j	80004de0 <end_op+0x52>

0000000080004ee6 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004ee6:	1101                	addi	sp,sp,-32
    80004ee8:	ec06                	sd	ra,24(sp)
    80004eea:	e822                	sd	s0,16(sp)
    80004eec:	e426                	sd	s1,8(sp)
    80004eee:	e04a                	sd	s2,0(sp)
    80004ef0:	1000                	addi	s0,sp,32
    80004ef2:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004ef4:	0001f917          	auipc	s2,0x1f
    80004ef8:	16490913          	addi	s2,s2,356 # 80024058 <log>
    80004efc:	854a                	mv	a0,s2
    80004efe:	ffffc097          	auipc	ra,0xffffc
    80004f02:	cec080e7          	jalr	-788(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004f06:	02c92603          	lw	a2,44(s2)
    80004f0a:	47f5                	li	a5,29
    80004f0c:	06c7c563          	blt	a5,a2,80004f76 <log_write+0x90>
    80004f10:	0001f797          	auipc	a5,0x1f
    80004f14:	1647a783          	lw	a5,356(a5) # 80024074 <log+0x1c>
    80004f18:	37fd                	addiw	a5,a5,-1
    80004f1a:	04f65e63          	bge	a2,a5,80004f76 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004f1e:	0001f797          	auipc	a5,0x1f
    80004f22:	15a7a783          	lw	a5,346(a5) # 80024078 <log+0x20>
    80004f26:	06f05063          	blez	a5,80004f86 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004f2a:	4781                	li	a5,0
    80004f2c:	06c05563          	blez	a2,80004f96 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004f30:	44cc                	lw	a1,12(s1)
    80004f32:	0001f717          	auipc	a4,0x1f
    80004f36:	15670713          	addi	a4,a4,342 # 80024088 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004f3a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004f3c:	4314                	lw	a3,0(a4)
    80004f3e:	04b68c63          	beq	a3,a1,80004f96 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004f42:	2785                	addiw	a5,a5,1
    80004f44:	0711                	addi	a4,a4,4
    80004f46:	fef61be3          	bne	a2,a5,80004f3c <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004f4a:	0621                	addi	a2,a2,8
    80004f4c:	060a                	slli	a2,a2,0x2
    80004f4e:	0001f797          	auipc	a5,0x1f
    80004f52:	10a78793          	addi	a5,a5,266 # 80024058 <log>
    80004f56:	963e                	add	a2,a2,a5
    80004f58:	44dc                	lw	a5,12(s1)
    80004f5a:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004f5c:	8526                	mv	a0,s1
    80004f5e:	fffff097          	auipc	ra,0xfffff
    80004f62:	da2080e7          	jalr	-606(ra) # 80003d00 <bpin>
    log.lh.n++;
    80004f66:	0001f717          	auipc	a4,0x1f
    80004f6a:	0f270713          	addi	a4,a4,242 # 80024058 <log>
    80004f6e:	575c                	lw	a5,44(a4)
    80004f70:	2785                	addiw	a5,a5,1
    80004f72:	d75c                	sw	a5,44(a4)
    80004f74:	a835                	j	80004fb0 <log_write+0xca>
    panic("too big a transaction");
    80004f76:	00005517          	auipc	a0,0x5
    80004f7a:	89250513          	addi	a0,a0,-1902 # 80009808 <syscalls+0x220>
    80004f7e:	ffffb097          	auipc	ra,0xffffb
    80004f82:	5c6080e7          	jalr	1478(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    80004f86:	00005517          	auipc	a0,0x5
    80004f8a:	89a50513          	addi	a0,a0,-1894 # 80009820 <syscalls+0x238>
    80004f8e:	ffffb097          	auipc	ra,0xffffb
    80004f92:	5b6080e7          	jalr	1462(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    80004f96:	00878713          	addi	a4,a5,8
    80004f9a:	00271693          	slli	a3,a4,0x2
    80004f9e:	0001f717          	auipc	a4,0x1f
    80004fa2:	0ba70713          	addi	a4,a4,186 # 80024058 <log>
    80004fa6:	9736                	add	a4,a4,a3
    80004fa8:	44d4                	lw	a3,12(s1)
    80004faa:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004fac:	faf608e3          	beq	a2,a5,80004f5c <log_write+0x76>
  }
  release(&log.lock);
    80004fb0:	0001f517          	auipc	a0,0x1f
    80004fb4:	0a850513          	addi	a0,a0,168 # 80024058 <log>
    80004fb8:	ffffc097          	auipc	ra,0xffffc
    80004fbc:	ce6080e7          	jalr	-794(ra) # 80000c9e <release>
}
    80004fc0:	60e2                	ld	ra,24(sp)
    80004fc2:	6442                	ld	s0,16(sp)
    80004fc4:	64a2                	ld	s1,8(sp)
    80004fc6:	6902                	ld	s2,0(sp)
    80004fc8:	6105                	addi	sp,sp,32
    80004fca:	8082                	ret

0000000080004fcc <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004fcc:	1101                	addi	sp,sp,-32
    80004fce:	ec06                	sd	ra,24(sp)
    80004fd0:	e822                	sd	s0,16(sp)
    80004fd2:	e426                	sd	s1,8(sp)
    80004fd4:	e04a                	sd	s2,0(sp)
    80004fd6:	1000                	addi	s0,sp,32
    80004fd8:	84aa                	mv	s1,a0
    80004fda:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004fdc:	00005597          	auipc	a1,0x5
    80004fe0:	86458593          	addi	a1,a1,-1948 # 80009840 <syscalls+0x258>
    80004fe4:	0521                	addi	a0,a0,8
    80004fe6:	ffffc097          	auipc	ra,0xffffc
    80004fea:	b74080e7          	jalr	-1164(ra) # 80000b5a <initlock>
  lk->name = name;
    80004fee:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004ff2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004ff6:	0204a423          	sw	zero,40(s1)
}
    80004ffa:	60e2                	ld	ra,24(sp)
    80004ffc:	6442                	ld	s0,16(sp)
    80004ffe:	64a2                	ld	s1,8(sp)
    80005000:	6902                	ld	s2,0(sp)
    80005002:	6105                	addi	sp,sp,32
    80005004:	8082                	ret

0000000080005006 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80005006:	1101                	addi	sp,sp,-32
    80005008:	ec06                	sd	ra,24(sp)
    8000500a:	e822                	sd	s0,16(sp)
    8000500c:	e426                	sd	s1,8(sp)
    8000500e:	e04a                	sd	s2,0(sp)
    80005010:	1000                	addi	s0,sp,32
    80005012:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80005014:	00850913          	addi	s2,a0,8
    80005018:	854a                	mv	a0,s2
    8000501a:	ffffc097          	auipc	ra,0xffffc
    8000501e:	bd0080e7          	jalr	-1072(ra) # 80000bea <acquire>
  while (lk->locked) {
    80005022:	409c                	lw	a5,0(s1)
    80005024:	cb89                	beqz	a5,80005036 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80005026:	85ca                	mv	a1,s2
    80005028:	8526                	mv	a0,s1
    8000502a:	ffffd097          	auipc	ra,0xffffd
    8000502e:	438080e7          	jalr	1080(ra) # 80002462 <sleep>
  while (lk->locked) {
    80005032:	409c                	lw	a5,0(s1)
    80005034:	fbed                	bnez	a5,80005026 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80005036:	4785                	li	a5,1
    80005038:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000503a:	ffffd097          	auipc	ra,0xffffd
    8000503e:	b8c080e7          	jalr	-1140(ra) # 80001bc6 <myproc>
    80005042:	591c                	lw	a5,48(a0)
    80005044:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80005046:	854a                	mv	a0,s2
    80005048:	ffffc097          	auipc	ra,0xffffc
    8000504c:	c56080e7          	jalr	-938(ra) # 80000c9e <release>
}
    80005050:	60e2                	ld	ra,24(sp)
    80005052:	6442                	ld	s0,16(sp)
    80005054:	64a2                	ld	s1,8(sp)
    80005056:	6902                	ld	s2,0(sp)
    80005058:	6105                	addi	sp,sp,32
    8000505a:	8082                	ret

000000008000505c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000505c:	1101                	addi	sp,sp,-32
    8000505e:	ec06                	sd	ra,24(sp)
    80005060:	e822                	sd	s0,16(sp)
    80005062:	e426                	sd	s1,8(sp)
    80005064:	e04a                	sd	s2,0(sp)
    80005066:	1000                	addi	s0,sp,32
    80005068:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000506a:	00850913          	addi	s2,a0,8
    8000506e:	854a                	mv	a0,s2
    80005070:	ffffc097          	auipc	ra,0xffffc
    80005074:	b7a080e7          	jalr	-1158(ra) # 80000bea <acquire>
  lk->locked = 0;
    80005078:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000507c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80005080:	8526                	mv	a0,s1
    80005082:	ffffd097          	auipc	ra,0xffffd
    80005086:	590080e7          	jalr	1424(ra) # 80002612 <wakeup>
  release(&lk->lk);
    8000508a:	854a                	mv	a0,s2
    8000508c:	ffffc097          	auipc	ra,0xffffc
    80005090:	c12080e7          	jalr	-1006(ra) # 80000c9e <release>
}
    80005094:	60e2                	ld	ra,24(sp)
    80005096:	6442                	ld	s0,16(sp)
    80005098:	64a2                	ld	s1,8(sp)
    8000509a:	6902                	ld	s2,0(sp)
    8000509c:	6105                	addi	sp,sp,32
    8000509e:	8082                	ret

00000000800050a0 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800050a0:	7179                	addi	sp,sp,-48
    800050a2:	f406                	sd	ra,40(sp)
    800050a4:	f022                	sd	s0,32(sp)
    800050a6:	ec26                	sd	s1,24(sp)
    800050a8:	e84a                	sd	s2,16(sp)
    800050aa:	e44e                	sd	s3,8(sp)
    800050ac:	1800                	addi	s0,sp,48
    800050ae:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800050b0:	00850913          	addi	s2,a0,8
    800050b4:	854a                	mv	a0,s2
    800050b6:	ffffc097          	auipc	ra,0xffffc
    800050ba:	b34080e7          	jalr	-1228(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800050be:	409c                	lw	a5,0(s1)
    800050c0:	ef99                	bnez	a5,800050de <holdingsleep+0x3e>
    800050c2:	4481                	li	s1,0
  release(&lk->lk);
    800050c4:	854a                	mv	a0,s2
    800050c6:	ffffc097          	auipc	ra,0xffffc
    800050ca:	bd8080e7          	jalr	-1064(ra) # 80000c9e <release>
  return r;
}
    800050ce:	8526                	mv	a0,s1
    800050d0:	70a2                	ld	ra,40(sp)
    800050d2:	7402                	ld	s0,32(sp)
    800050d4:	64e2                	ld	s1,24(sp)
    800050d6:	6942                	ld	s2,16(sp)
    800050d8:	69a2                	ld	s3,8(sp)
    800050da:	6145                	addi	sp,sp,48
    800050dc:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800050de:	0284a983          	lw	s3,40(s1)
    800050e2:	ffffd097          	auipc	ra,0xffffd
    800050e6:	ae4080e7          	jalr	-1308(ra) # 80001bc6 <myproc>
    800050ea:	5904                	lw	s1,48(a0)
    800050ec:	413484b3          	sub	s1,s1,s3
    800050f0:	0014b493          	seqz	s1,s1
    800050f4:	bfc1                	j	800050c4 <holdingsleep+0x24>

00000000800050f6 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800050f6:	1141                	addi	sp,sp,-16
    800050f8:	e406                	sd	ra,8(sp)
    800050fa:	e022                	sd	s0,0(sp)
    800050fc:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800050fe:	00004597          	auipc	a1,0x4
    80005102:	75258593          	addi	a1,a1,1874 # 80009850 <syscalls+0x268>
    80005106:	0001f517          	auipc	a0,0x1f
    8000510a:	09a50513          	addi	a0,a0,154 # 800241a0 <ftable>
    8000510e:	ffffc097          	auipc	ra,0xffffc
    80005112:	a4c080e7          	jalr	-1460(ra) # 80000b5a <initlock>
}
    80005116:	60a2                	ld	ra,8(sp)
    80005118:	6402                	ld	s0,0(sp)
    8000511a:	0141                	addi	sp,sp,16
    8000511c:	8082                	ret

000000008000511e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000511e:	1101                	addi	sp,sp,-32
    80005120:	ec06                	sd	ra,24(sp)
    80005122:	e822                	sd	s0,16(sp)
    80005124:	e426                	sd	s1,8(sp)
    80005126:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80005128:	0001f517          	auipc	a0,0x1f
    8000512c:	07850513          	addi	a0,a0,120 # 800241a0 <ftable>
    80005130:	ffffc097          	auipc	ra,0xffffc
    80005134:	aba080e7          	jalr	-1350(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005138:	0001f497          	auipc	s1,0x1f
    8000513c:	08048493          	addi	s1,s1,128 # 800241b8 <ftable+0x18>
    80005140:	00020717          	auipc	a4,0x20
    80005144:	01870713          	addi	a4,a4,24 # 80025158 <disk>
    if(f->ref == 0){
    80005148:	40dc                	lw	a5,4(s1)
    8000514a:	cf99                	beqz	a5,80005168 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000514c:	02848493          	addi	s1,s1,40
    80005150:	fee49ce3          	bne	s1,a4,80005148 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80005154:	0001f517          	auipc	a0,0x1f
    80005158:	04c50513          	addi	a0,a0,76 # 800241a0 <ftable>
    8000515c:	ffffc097          	auipc	ra,0xffffc
    80005160:	b42080e7          	jalr	-1214(ra) # 80000c9e <release>
  return 0;
    80005164:	4481                	li	s1,0
    80005166:	a819                	j	8000517c <filealloc+0x5e>
      f->ref = 1;
    80005168:	4785                	li	a5,1
    8000516a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000516c:	0001f517          	auipc	a0,0x1f
    80005170:	03450513          	addi	a0,a0,52 # 800241a0 <ftable>
    80005174:	ffffc097          	auipc	ra,0xffffc
    80005178:	b2a080e7          	jalr	-1238(ra) # 80000c9e <release>
}
    8000517c:	8526                	mv	a0,s1
    8000517e:	60e2                	ld	ra,24(sp)
    80005180:	6442                	ld	s0,16(sp)
    80005182:	64a2                	ld	s1,8(sp)
    80005184:	6105                	addi	sp,sp,32
    80005186:	8082                	ret

0000000080005188 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80005188:	1101                	addi	sp,sp,-32
    8000518a:	ec06                	sd	ra,24(sp)
    8000518c:	e822                	sd	s0,16(sp)
    8000518e:	e426                	sd	s1,8(sp)
    80005190:	1000                	addi	s0,sp,32
    80005192:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80005194:	0001f517          	auipc	a0,0x1f
    80005198:	00c50513          	addi	a0,a0,12 # 800241a0 <ftable>
    8000519c:	ffffc097          	auipc	ra,0xffffc
    800051a0:	a4e080e7          	jalr	-1458(ra) # 80000bea <acquire>
  if(f->ref < 1)
    800051a4:	40dc                	lw	a5,4(s1)
    800051a6:	02f05263          	blez	a5,800051ca <filedup+0x42>
    panic("filedup");
  f->ref++;
    800051aa:	2785                	addiw	a5,a5,1
    800051ac:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800051ae:	0001f517          	auipc	a0,0x1f
    800051b2:	ff250513          	addi	a0,a0,-14 # 800241a0 <ftable>
    800051b6:	ffffc097          	auipc	ra,0xffffc
    800051ba:	ae8080e7          	jalr	-1304(ra) # 80000c9e <release>
  return f;
}
    800051be:	8526                	mv	a0,s1
    800051c0:	60e2                	ld	ra,24(sp)
    800051c2:	6442                	ld	s0,16(sp)
    800051c4:	64a2                	ld	s1,8(sp)
    800051c6:	6105                	addi	sp,sp,32
    800051c8:	8082                	ret
    panic("filedup");
    800051ca:	00004517          	auipc	a0,0x4
    800051ce:	68e50513          	addi	a0,a0,1678 # 80009858 <syscalls+0x270>
    800051d2:	ffffb097          	auipc	ra,0xffffb
    800051d6:	372080e7          	jalr	882(ra) # 80000544 <panic>

00000000800051da <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800051da:	7139                	addi	sp,sp,-64
    800051dc:	fc06                	sd	ra,56(sp)
    800051de:	f822                	sd	s0,48(sp)
    800051e0:	f426                	sd	s1,40(sp)
    800051e2:	f04a                	sd	s2,32(sp)
    800051e4:	ec4e                	sd	s3,24(sp)
    800051e6:	e852                	sd	s4,16(sp)
    800051e8:	e456                	sd	s5,8(sp)
    800051ea:	0080                	addi	s0,sp,64
    800051ec:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800051ee:	0001f517          	auipc	a0,0x1f
    800051f2:	fb250513          	addi	a0,a0,-78 # 800241a0 <ftable>
    800051f6:	ffffc097          	auipc	ra,0xffffc
    800051fa:	9f4080e7          	jalr	-1548(ra) # 80000bea <acquire>
  if(f->ref < 1)
    800051fe:	40dc                	lw	a5,4(s1)
    80005200:	06f05163          	blez	a5,80005262 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80005204:	37fd                	addiw	a5,a5,-1
    80005206:	0007871b          	sext.w	a4,a5
    8000520a:	c0dc                	sw	a5,4(s1)
    8000520c:	06e04363          	bgtz	a4,80005272 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80005210:	0004a903          	lw	s2,0(s1)
    80005214:	0094ca83          	lbu	s5,9(s1)
    80005218:	0104ba03          	ld	s4,16(s1)
    8000521c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80005220:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80005224:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80005228:	0001f517          	auipc	a0,0x1f
    8000522c:	f7850513          	addi	a0,a0,-136 # 800241a0 <ftable>
    80005230:	ffffc097          	auipc	ra,0xffffc
    80005234:	a6e080e7          	jalr	-1426(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    80005238:	4785                	li	a5,1
    8000523a:	04f90d63          	beq	s2,a5,80005294 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000523e:	3979                	addiw	s2,s2,-2
    80005240:	4785                	li	a5,1
    80005242:	0527e063          	bltu	a5,s2,80005282 <fileclose+0xa8>
    begin_op();
    80005246:	00000097          	auipc	ra,0x0
    8000524a:	ac8080e7          	jalr	-1336(ra) # 80004d0e <begin_op>
    iput(ff.ip);
    8000524e:	854e                	mv	a0,s3
    80005250:	fffff097          	auipc	ra,0xfffff
    80005254:	2b6080e7          	jalr	694(ra) # 80004506 <iput>
    end_op();
    80005258:	00000097          	auipc	ra,0x0
    8000525c:	b36080e7          	jalr	-1226(ra) # 80004d8e <end_op>
    80005260:	a00d                	j	80005282 <fileclose+0xa8>
    panic("fileclose");
    80005262:	00004517          	auipc	a0,0x4
    80005266:	5fe50513          	addi	a0,a0,1534 # 80009860 <syscalls+0x278>
    8000526a:	ffffb097          	auipc	ra,0xffffb
    8000526e:	2da080e7          	jalr	730(ra) # 80000544 <panic>
    release(&ftable.lock);
    80005272:	0001f517          	auipc	a0,0x1f
    80005276:	f2e50513          	addi	a0,a0,-210 # 800241a0 <ftable>
    8000527a:	ffffc097          	auipc	ra,0xffffc
    8000527e:	a24080e7          	jalr	-1500(ra) # 80000c9e <release>
  }
}
    80005282:	70e2                	ld	ra,56(sp)
    80005284:	7442                	ld	s0,48(sp)
    80005286:	74a2                	ld	s1,40(sp)
    80005288:	7902                	ld	s2,32(sp)
    8000528a:	69e2                	ld	s3,24(sp)
    8000528c:	6a42                	ld	s4,16(sp)
    8000528e:	6aa2                	ld	s5,8(sp)
    80005290:	6121                	addi	sp,sp,64
    80005292:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80005294:	85d6                	mv	a1,s5
    80005296:	8552                	mv	a0,s4
    80005298:	00000097          	auipc	ra,0x0
    8000529c:	34c080e7          	jalr	844(ra) # 800055e4 <pipeclose>
    800052a0:	b7cd                	j	80005282 <fileclose+0xa8>

00000000800052a2 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800052a2:	715d                	addi	sp,sp,-80
    800052a4:	e486                	sd	ra,72(sp)
    800052a6:	e0a2                	sd	s0,64(sp)
    800052a8:	fc26                	sd	s1,56(sp)
    800052aa:	f84a                	sd	s2,48(sp)
    800052ac:	f44e                	sd	s3,40(sp)
    800052ae:	0880                	addi	s0,sp,80
    800052b0:	84aa                	mv	s1,a0
    800052b2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800052b4:	ffffd097          	auipc	ra,0xffffd
    800052b8:	912080e7          	jalr	-1774(ra) # 80001bc6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800052bc:	409c                	lw	a5,0(s1)
    800052be:	37f9                	addiw	a5,a5,-2
    800052c0:	4705                	li	a4,1
    800052c2:	04f76763          	bltu	a4,a5,80005310 <filestat+0x6e>
    800052c6:	892a                	mv	s2,a0
    ilock(f->ip);
    800052c8:	6c88                	ld	a0,24(s1)
    800052ca:	fffff097          	auipc	ra,0xfffff
    800052ce:	082080e7          	jalr	130(ra) # 8000434c <ilock>
    stati(f->ip, &st);
    800052d2:	fb840593          	addi	a1,s0,-72
    800052d6:	6c88                	ld	a0,24(s1)
    800052d8:	fffff097          	auipc	ra,0xfffff
    800052dc:	2fe080e7          	jalr	766(ra) # 800045d6 <stati>
    iunlock(f->ip);
    800052e0:	6c88                	ld	a0,24(s1)
    800052e2:	fffff097          	auipc	ra,0xfffff
    800052e6:	12c080e7          	jalr	300(ra) # 8000440e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800052ea:	46e1                	li	a3,24
    800052ec:	fb840613          	addi	a2,s0,-72
    800052f0:	85ce                	mv	a1,s3
    800052f2:	05093503          	ld	a0,80(s2)
    800052f6:	ffffc097          	auipc	ra,0xffffc
    800052fa:	38e080e7          	jalr	910(ra) # 80001684 <copyout>
    800052fe:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80005302:	60a6                	ld	ra,72(sp)
    80005304:	6406                	ld	s0,64(sp)
    80005306:	74e2                	ld	s1,56(sp)
    80005308:	7942                	ld	s2,48(sp)
    8000530a:	79a2                	ld	s3,40(sp)
    8000530c:	6161                	addi	sp,sp,80
    8000530e:	8082                	ret
  return -1;
    80005310:	557d                	li	a0,-1
    80005312:	bfc5                	j	80005302 <filestat+0x60>

0000000080005314 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80005314:	7179                	addi	sp,sp,-48
    80005316:	f406                	sd	ra,40(sp)
    80005318:	f022                	sd	s0,32(sp)
    8000531a:	ec26                	sd	s1,24(sp)
    8000531c:	e84a                	sd	s2,16(sp)
    8000531e:	e44e                	sd	s3,8(sp)
    80005320:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005322:	00854783          	lbu	a5,8(a0)
    80005326:	c3d5                	beqz	a5,800053ca <fileread+0xb6>
    80005328:	84aa                	mv	s1,a0
    8000532a:	89ae                	mv	s3,a1
    8000532c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000532e:	411c                	lw	a5,0(a0)
    80005330:	4705                	li	a4,1
    80005332:	04e78963          	beq	a5,a4,80005384 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005336:	470d                	li	a4,3
    80005338:	04e78d63          	beq	a5,a4,80005392 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000533c:	4709                	li	a4,2
    8000533e:	06e79e63          	bne	a5,a4,800053ba <fileread+0xa6>
    ilock(f->ip);
    80005342:	6d08                	ld	a0,24(a0)
    80005344:	fffff097          	auipc	ra,0xfffff
    80005348:	008080e7          	jalr	8(ra) # 8000434c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000534c:	874a                	mv	a4,s2
    8000534e:	5094                	lw	a3,32(s1)
    80005350:	864e                	mv	a2,s3
    80005352:	4585                	li	a1,1
    80005354:	6c88                	ld	a0,24(s1)
    80005356:	fffff097          	auipc	ra,0xfffff
    8000535a:	2aa080e7          	jalr	682(ra) # 80004600 <readi>
    8000535e:	892a                	mv	s2,a0
    80005360:	00a05563          	blez	a0,8000536a <fileread+0x56>
      f->off += r;
    80005364:	509c                	lw	a5,32(s1)
    80005366:	9fa9                	addw	a5,a5,a0
    80005368:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000536a:	6c88                	ld	a0,24(s1)
    8000536c:	fffff097          	auipc	ra,0xfffff
    80005370:	0a2080e7          	jalr	162(ra) # 8000440e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005374:	854a                	mv	a0,s2
    80005376:	70a2                	ld	ra,40(sp)
    80005378:	7402                	ld	s0,32(sp)
    8000537a:	64e2                	ld	s1,24(sp)
    8000537c:	6942                	ld	s2,16(sp)
    8000537e:	69a2                	ld	s3,8(sp)
    80005380:	6145                	addi	sp,sp,48
    80005382:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005384:	6908                	ld	a0,16(a0)
    80005386:	00000097          	auipc	ra,0x0
    8000538a:	3ce080e7          	jalr	974(ra) # 80005754 <piperead>
    8000538e:	892a                	mv	s2,a0
    80005390:	b7d5                	j	80005374 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005392:	02451783          	lh	a5,36(a0)
    80005396:	03079693          	slli	a3,a5,0x30
    8000539a:	92c1                	srli	a3,a3,0x30
    8000539c:	4725                	li	a4,9
    8000539e:	02d76863          	bltu	a4,a3,800053ce <fileread+0xba>
    800053a2:	0792                	slli	a5,a5,0x4
    800053a4:	0001f717          	auipc	a4,0x1f
    800053a8:	d5c70713          	addi	a4,a4,-676 # 80024100 <devsw>
    800053ac:	97ba                	add	a5,a5,a4
    800053ae:	639c                	ld	a5,0(a5)
    800053b0:	c38d                	beqz	a5,800053d2 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800053b2:	4505                	li	a0,1
    800053b4:	9782                	jalr	a5
    800053b6:	892a                	mv	s2,a0
    800053b8:	bf75                	j	80005374 <fileread+0x60>
    panic("fileread");
    800053ba:	00004517          	auipc	a0,0x4
    800053be:	4b650513          	addi	a0,a0,1206 # 80009870 <syscalls+0x288>
    800053c2:	ffffb097          	auipc	ra,0xffffb
    800053c6:	182080e7          	jalr	386(ra) # 80000544 <panic>
    return -1;
    800053ca:	597d                	li	s2,-1
    800053cc:	b765                	j	80005374 <fileread+0x60>
      return -1;
    800053ce:	597d                	li	s2,-1
    800053d0:	b755                	j	80005374 <fileread+0x60>
    800053d2:	597d                	li	s2,-1
    800053d4:	b745                	j	80005374 <fileread+0x60>

00000000800053d6 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800053d6:	715d                	addi	sp,sp,-80
    800053d8:	e486                	sd	ra,72(sp)
    800053da:	e0a2                	sd	s0,64(sp)
    800053dc:	fc26                	sd	s1,56(sp)
    800053de:	f84a                	sd	s2,48(sp)
    800053e0:	f44e                	sd	s3,40(sp)
    800053e2:	f052                	sd	s4,32(sp)
    800053e4:	ec56                	sd	s5,24(sp)
    800053e6:	e85a                	sd	s6,16(sp)
    800053e8:	e45e                	sd	s7,8(sp)
    800053ea:	e062                	sd	s8,0(sp)
    800053ec:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800053ee:	00954783          	lbu	a5,9(a0)
    800053f2:	10078663          	beqz	a5,800054fe <filewrite+0x128>
    800053f6:	892a                	mv	s2,a0
    800053f8:	8aae                	mv	s5,a1
    800053fa:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800053fc:	411c                	lw	a5,0(a0)
    800053fe:	4705                	li	a4,1
    80005400:	02e78263          	beq	a5,a4,80005424 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005404:	470d                	li	a4,3
    80005406:	02e78663          	beq	a5,a4,80005432 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000540a:	4709                	li	a4,2
    8000540c:	0ee79163          	bne	a5,a4,800054ee <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005410:	0ac05d63          	blez	a2,800054ca <filewrite+0xf4>
    int i = 0;
    80005414:	4981                	li	s3,0
    80005416:	6b05                	lui	s6,0x1
    80005418:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000541c:	6b85                	lui	s7,0x1
    8000541e:	c00b8b9b          	addiw	s7,s7,-1024
    80005422:	a861                	j	800054ba <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005424:	6908                	ld	a0,16(a0)
    80005426:	00000097          	auipc	ra,0x0
    8000542a:	22e080e7          	jalr	558(ra) # 80005654 <pipewrite>
    8000542e:	8a2a                	mv	s4,a0
    80005430:	a045                	j	800054d0 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005432:	02451783          	lh	a5,36(a0)
    80005436:	03079693          	slli	a3,a5,0x30
    8000543a:	92c1                	srli	a3,a3,0x30
    8000543c:	4725                	li	a4,9
    8000543e:	0cd76263          	bltu	a4,a3,80005502 <filewrite+0x12c>
    80005442:	0792                	slli	a5,a5,0x4
    80005444:	0001f717          	auipc	a4,0x1f
    80005448:	cbc70713          	addi	a4,a4,-836 # 80024100 <devsw>
    8000544c:	97ba                	add	a5,a5,a4
    8000544e:	679c                	ld	a5,8(a5)
    80005450:	cbdd                	beqz	a5,80005506 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005452:	4505                	li	a0,1
    80005454:	9782                	jalr	a5
    80005456:	8a2a                	mv	s4,a0
    80005458:	a8a5                	j	800054d0 <filewrite+0xfa>
    8000545a:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000545e:	00000097          	auipc	ra,0x0
    80005462:	8b0080e7          	jalr	-1872(ra) # 80004d0e <begin_op>
      ilock(f->ip);
    80005466:	01893503          	ld	a0,24(s2)
    8000546a:	fffff097          	auipc	ra,0xfffff
    8000546e:	ee2080e7          	jalr	-286(ra) # 8000434c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005472:	8762                	mv	a4,s8
    80005474:	02092683          	lw	a3,32(s2)
    80005478:	01598633          	add	a2,s3,s5
    8000547c:	4585                	li	a1,1
    8000547e:	01893503          	ld	a0,24(s2)
    80005482:	fffff097          	auipc	ra,0xfffff
    80005486:	276080e7          	jalr	630(ra) # 800046f8 <writei>
    8000548a:	84aa                	mv	s1,a0
    8000548c:	00a05763          	blez	a0,8000549a <filewrite+0xc4>
        f->off += r;
    80005490:	02092783          	lw	a5,32(s2)
    80005494:	9fa9                	addw	a5,a5,a0
    80005496:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000549a:	01893503          	ld	a0,24(s2)
    8000549e:	fffff097          	auipc	ra,0xfffff
    800054a2:	f70080e7          	jalr	-144(ra) # 8000440e <iunlock>
      end_op();
    800054a6:	00000097          	auipc	ra,0x0
    800054aa:	8e8080e7          	jalr	-1816(ra) # 80004d8e <end_op>

      if(r != n1){
    800054ae:	009c1f63          	bne	s8,s1,800054cc <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800054b2:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800054b6:	0149db63          	bge	s3,s4,800054cc <filewrite+0xf6>
      int n1 = n - i;
    800054ba:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800054be:	84be                	mv	s1,a5
    800054c0:	2781                	sext.w	a5,a5
    800054c2:	f8fb5ce3          	bge	s6,a5,8000545a <filewrite+0x84>
    800054c6:	84de                	mv	s1,s7
    800054c8:	bf49                	j	8000545a <filewrite+0x84>
    int i = 0;
    800054ca:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800054cc:	013a1f63          	bne	s4,s3,800054ea <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800054d0:	8552                	mv	a0,s4
    800054d2:	60a6                	ld	ra,72(sp)
    800054d4:	6406                	ld	s0,64(sp)
    800054d6:	74e2                	ld	s1,56(sp)
    800054d8:	7942                	ld	s2,48(sp)
    800054da:	79a2                	ld	s3,40(sp)
    800054dc:	7a02                	ld	s4,32(sp)
    800054de:	6ae2                	ld	s5,24(sp)
    800054e0:	6b42                	ld	s6,16(sp)
    800054e2:	6ba2                	ld	s7,8(sp)
    800054e4:	6c02                	ld	s8,0(sp)
    800054e6:	6161                	addi	sp,sp,80
    800054e8:	8082                	ret
    ret = (i == n ? n : -1);
    800054ea:	5a7d                	li	s4,-1
    800054ec:	b7d5                	j	800054d0 <filewrite+0xfa>
    panic("filewrite");
    800054ee:	00004517          	auipc	a0,0x4
    800054f2:	39250513          	addi	a0,a0,914 # 80009880 <syscalls+0x298>
    800054f6:	ffffb097          	auipc	ra,0xffffb
    800054fa:	04e080e7          	jalr	78(ra) # 80000544 <panic>
    return -1;
    800054fe:	5a7d                	li	s4,-1
    80005500:	bfc1                	j	800054d0 <filewrite+0xfa>
      return -1;
    80005502:	5a7d                	li	s4,-1
    80005504:	b7f1                	j	800054d0 <filewrite+0xfa>
    80005506:	5a7d                	li	s4,-1
    80005508:	b7e1                	j	800054d0 <filewrite+0xfa>

000000008000550a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000550a:	7179                	addi	sp,sp,-48
    8000550c:	f406                	sd	ra,40(sp)
    8000550e:	f022                	sd	s0,32(sp)
    80005510:	ec26                	sd	s1,24(sp)
    80005512:	e84a                	sd	s2,16(sp)
    80005514:	e44e                	sd	s3,8(sp)
    80005516:	e052                	sd	s4,0(sp)
    80005518:	1800                	addi	s0,sp,48
    8000551a:	84aa                	mv	s1,a0
    8000551c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000551e:	0005b023          	sd	zero,0(a1)
    80005522:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005526:	00000097          	auipc	ra,0x0
    8000552a:	bf8080e7          	jalr	-1032(ra) # 8000511e <filealloc>
    8000552e:	e088                	sd	a0,0(s1)
    80005530:	c551                	beqz	a0,800055bc <pipealloc+0xb2>
    80005532:	00000097          	auipc	ra,0x0
    80005536:	bec080e7          	jalr	-1044(ra) # 8000511e <filealloc>
    8000553a:	00aa3023          	sd	a0,0(s4)
    8000553e:	c92d                	beqz	a0,800055b0 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005540:	ffffb097          	auipc	ra,0xffffb
    80005544:	5ba080e7          	jalr	1466(ra) # 80000afa <kalloc>
    80005548:	892a                	mv	s2,a0
    8000554a:	c125                	beqz	a0,800055aa <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000554c:	4985                	li	s3,1
    8000554e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005552:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005556:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000555a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000555e:	00004597          	auipc	a1,0x4
    80005562:	f9258593          	addi	a1,a1,-110 # 800094f0 <states.1811+0x208>
    80005566:	ffffb097          	auipc	ra,0xffffb
    8000556a:	5f4080e7          	jalr	1524(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    8000556e:	609c                	ld	a5,0(s1)
    80005570:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005574:	609c                	ld	a5,0(s1)
    80005576:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000557a:	609c                	ld	a5,0(s1)
    8000557c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005580:	609c                	ld	a5,0(s1)
    80005582:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005586:	000a3783          	ld	a5,0(s4)
    8000558a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000558e:	000a3783          	ld	a5,0(s4)
    80005592:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005596:	000a3783          	ld	a5,0(s4)
    8000559a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000559e:	000a3783          	ld	a5,0(s4)
    800055a2:	0127b823          	sd	s2,16(a5)
  return 0;
    800055a6:	4501                	li	a0,0
    800055a8:	a025                	j	800055d0 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800055aa:	6088                	ld	a0,0(s1)
    800055ac:	e501                	bnez	a0,800055b4 <pipealloc+0xaa>
    800055ae:	a039                	j	800055bc <pipealloc+0xb2>
    800055b0:	6088                	ld	a0,0(s1)
    800055b2:	c51d                	beqz	a0,800055e0 <pipealloc+0xd6>
    fileclose(*f0);
    800055b4:	00000097          	auipc	ra,0x0
    800055b8:	c26080e7          	jalr	-986(ra) # 800051da <fileclose>
  if(*f1)
    800055bc:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800055c0:	557d                	li	a0,-1
  if(*f1)
    800055c2:	c799                	beqz	a5,800055d0 <pipealloc+0xc6>
    fileclose(*f1);
    800055c4:	853e                	mv	a0,a5
    800055c6:	00000097          	auipc	ra,0x0
    800055ca:	c14080e7          	jalr	-1004(ra) # 800051da <fileclose>
  return -1;
    800055ce:	557d                	li	a0,-1
}
    800055d0:	70a2                	ld	ra,40(sp)
    800055d2:	7402                	ld	s0,32(sp)
    800055d4:	64e2                	ld	s1,24(sp)
    800055d6:	6942                	ld	s2,16(sp)
    800055d8:	69a2                	ld	s3,8(sp)
    800055da:	6a02                	ld	s4,0(sp)
    800055dc:	6145                	addi	sp,sp,48
    800055de:	8082                	ret
  return -1;
    800055e0:	557d                	li	a0,-1
    800055e2:	b7fd                	j	800055d0 <pipealloc+0xc6>

00000000800055e4 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800055e4:	1101                	addi	sp,sp,-32
    800055e6:	ec06                	sd	ra,24(sp)
    800055e8:	e822                	sd	s0,16(sp)
    800055ea:	e426                	sd	s1,8(sp)
    800055ec:	e04a                	sd	s2,0(sp)
    800055ee:	1000                	addi	s0,sp,32
    800055f0:	84aa                	mv	s1,a0
    800055f2:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800055f4:	ffffb097          	auipc	ra,0xffffb
    800055f8:	5f6080e7          	jalr	1526(ra) # 80000bea <acquire>
  if(writable){
    800055fc:	02090d63          	beqz	s2,80005636 <pipeclose+0x52>
    pi->writeopen = 0;
    80005600:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005604:	21848513          	addi	a0,s1,536
    80005608:	ffffd097          	auipc	ra,0xffffd
    8000560c:	00a080e7          	jalr	10(ra) # 80002612 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005610:	2204b783          	ld	a5,544(s1)
    80005614:	eb95                	bnez	a5,80005648 <pipeclose+0x64>
    release(&pi->lock);
    80005616:	8526                	mv	a0,s1
    80005618:	ffffb097          	auipc	ra,0xffffb
    8000561c:	686080e7          	jalr	1670(ra) # 80000c9e <release>
    kfree((char*)pi);
    80005620:	8526                	mv	a0,s1
    80005622:	ffffb097          	auipc	ra,0xffffb
    80005626:	3dc080e7          	jalr	988(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    8000562a:	60e2                	ld	ra,24(sp)
    8000562c:	6442                	ld	s0,16(sp)
    8000562e:	64a2                	ld	s1,8(sp)
    80005630:	6902                	ld	s2,0(sp)
    80005632:	6105                	addi	sp,sp,32
    80005634:	8082                	ret
    pi->readopen = 0;
    80005636:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000563a:	21c48513          	addi	a0,s1,540
    8000563e:	ffffd097          	auipc	ra,0xffffd
    80005642:	fd4080e7          	jalr	-44(ra) # 80002612 <wakeup>
    80005646:	b7e9                	j	80005610 <pipeclose+0x2c>
    release(&pi->lock);
    80005648:	8526                	mv	a0,s1
    8000564a:	ffffb097          	auipc	ra,0xffffb
    8000564e:	654080e7          	jalr	1620(ra) # 80000c9e <release>
}
    80005652:	bfe1                	j	8000562a <pipeclose+0x46>

0000000080005654 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005654:	7159                	addi	sp,sp,-112
    80005656:	f486                	sd	ra,104(sp)
    80005658:	f0a2                	sd	s0,96(sp)
    8000565a:	eca6                	sd	s1,88(sp)
    8000565c:	e8ca                	sd	s2,80(sp)
    8000565e:	e4ce                	sd	s3,72(sp)
    80005660:	e0d2                	sd	s4,64(sp)
    80005662:	fc56                	sd	s5,56(sp)
    80005664:	f85a                	sd	s6,48(sp)
    80005666:	f45e                	sd	s7,40(sp)
    80005668:	f062                	sd	s8,32(sp)
    8000566a:	ec66                	sd	s9,24(sp)
    8000566c:	1880                	addi	s0,sp,112
    8000566e:	84aa                	mv	s1,a0
    80005670:	8aae                	mv	s5,a1
    80005672:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005674:	ffffc097          	auipc	ra,0xffffc
    80005678:	552080e7          	jalr	1362(ra) # 80001bc6 <myproc>
    8000567c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000567e:	8526                	mv	a0,s1
    80005680:	ffffb097          	auipc	ra,0xffffb
    80005684:	56a080e7          	jalr	1386(ra) # 80000bea <acquire>
  while(i < n){
    80005688:	0d405463          	blez	s4,80005750 <pipewrite+0xfc>
    8000568c:	8ba6                	mv	s7,s1
  int i = 0;
    8000568e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005690:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005692:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005696:	21c48c13          	addi	s8,s1,540
    8000569a:	a08d                	j	800056fc <pipewrite+0xa8>
      release(&pi->lock);
    8000569c:	8526                	mv	a0,s1
    8000569e:	ffffb097          	auipc	ra,0xffffb
    800056a2:	600080e7          	jalr	1536(ra) # 80000c9e <release>
      return -1;
    800056a6:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800056a8:	854a                	mv	a0,s2
    800056aa:	70a6                	ld	ra,104(sp)
    800056ac:	7406                	ld	s0,96(sp)
    800056ae:	64e6                	ld	s1,88(sp)
    800056b0:	6946                	ld	s2,80(sp)
    800056b2:	69a6                	ld	s3,72(sp)
    800056b4:	6a06                	ld	s4,64(sp)
    800056b6:	7ae2                	ld	s5,56(sp)
    800056b8:	7b42                	ld	s6,48(sp)
    800056ba:	7ba2                	ld	s7,40(sp)
    800056bc:	7c02                	ld	s8,32(sp)
    800056be:	6ce2                	ld	s9,24(sp)
    800056c0:	6165                	addi	sp,sp,112
    800056c2:	8082                	ret
      wakeup(&pi->nread);
    800056c4:	8566                	mv	a0,s9
    800056c6:	ffffd097          	auipc	ra,0xffffd
    800056ca:	f4c080e7          	jalr	-180(ra) # 80002612 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800056ce:	85de                	mv	a1,s7
    800056d0:	8562                	mv	a0,s8
    800056d2:	ffffd097          	auipc	ra,0xffffd
    800056d6:	d90080e7          	jalr	-624(ra) # 80002462 <sleep>
    800056da:	a839                	j	800056f8 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800056dc:	21c4a783          	lw	a5,540(s1)
    800056e0:	0017871b          	addiw	a4,a5,1
    800056e4:	20e4ae23          	sw	a4,540(s1)
    800056e8:	1ff7f793          	andi	a5,a5,511
    800056ec:	97a6                	add	a5,a5,s1
    800056ee:	f9f44703          	lbu	a4,-97(s0)
    800056f2:	00e78c23          	sb	a4,24(a5)
      i++;
    800056f6:	2905                	addiw	s2,s2,1
  while(i < n){
    800056f8:	05495063          	bge	s2,s4,80005738 <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    800056fc:	2204a783          	lw	a5,544(s1)
    80005700:	dfd1                	beqz	a5,8000569c <pipewrite+0x48>
    80005702:	854e                	mv	a0,s3
    80005704:	ffffd097          	auipc	ra,0xffffd
    80005708:	15e080e7          	jalr	350(ra) # 80002862 <killed>
    8000570c:	f941                	bnez	a0,8000569c <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000570e:	2184a783          	lw	a5,536(s1)
    80005712:	21c4a703          	lw	a4,540(s1)
    80005716:	2007879b          	addiw	a5,a5,512
    8000571a:	faf705e3          	beq	a4,a5,800056c4 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000571e:	4685                	li	a3,1
    80005720:	01590633          	add	a2,s2,s5
    80005724:	f9f40593          	addi	a1,s0,-97
    80005728:	0509b503          	ld	a0,80(s3)
    8000572c:	ffffc097          	auipc	ra,0xffffc
    80005730:	fe4080e7          	jalr	-28(ra) # 80001710 <copyin>
    80005734:	fb6514e3          	bne	a0,s6,800056dc <pipewrite+0x88>
  wakeup(&pi->nread);
    80005738:	21848513          	addi	a0,s1,536
    8000573c:	ffffd097          	auipc	ra,0xffffd
    80005740:	ed6080e7          	jalr	-298(ra) # 80002612 <wakeup>
  release(&pi->lock);
    80005744:	8526                	mv	a0,s1
    80005746:	ffffb097          	auipc	ra,0xffffb
    8000574a:	558080e7          	jalr	1368(ra) # 80000c9e <release>
  return i;
    8000574e:	bfa9                	j	800056a8 <pipewrite+0x54>
  int i = 0;
    80005750:	4901                	li	s2,0
    80005752:	b7dd                	j	80005738 <pipewrite+0xe4>

0000000080005754 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005754:	715d                	addi	sp,sp,-80
    80005756:	e486                	sd	ra,72(sp)
    80005758:	e0a2                	sd	s0,64(sp)
    8000575a:	fc26                	sd	s1,56(sp)
    8000575c:	f84a                	sd	s2,48(sp)
    8000575e:	f44e                	sd	s3,40(sp)
    80005760:	f052                	sd	s4,32(sp)
    80005762:	ec56                	sd	s5,24(sp)
    80005764:	e85a                	sd	s6,16(sp)
    80005766:	0880                	addi	s0,sp,80
    80005768:	84aa                	mv	s1,a0
    8000576a:	892e                	mv	s2,a1
    8000576c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000576e:	ffffc097          	auipc	ra,0xffffc
    80005772:	458080e7          	jalr	1112(ra) # 80001bc6 <myproc>
    80005776:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005778:	8b26                	mv	s6,s1
    8000577a:	8526                	mv	a0,s1
    8000577c:	ffffb097          	auipc	ra,0xffffb
    80005780:	46e080e7          	jalr	1134(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005784:	2184a703          	lw	a4,536(s1)
    80005788:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000578c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005790:	02f71763          	bne	a4,a5,800057be <piperead+0x6a>
    80005794:	2244a783          	lw	a5,548(s1)
    80005798:	c39d                	beqz	a5,800057be <piperead+0x6a>
    if(killed(pr)){
    8000579a:	8552                	mv	a0,s4
    8000579c:	ffffd097          	auipc	ra,0xffffd
    800057a0:	0c6080e7          	jalr	198(ra) # 80002862 <killed>
    800057a4:	e941                	bnez	a0,80005834 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800057a6:	85da                	mv	a1,s6
    800057a8:	854e                	mv	a0,s3
    800057aa:	ffffd097          	auipc	ra,0xffffd
    800057ae:	cb8080e7          	jalr	-840(ra) # 80002462 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800057b2:	2184a703          	lw	a4,536(s1)
    800057b6:	21c4a783          	lw	a5,540(s1)
    800057ba:	fcf70de3          	beq	a4,a5,80005794 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800057be:	09505263          	blez	s5,80005842 <piperead+0xee>
    800057c2:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800057c4:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800057c6:	2184a783          	lw	a5,536(s1)
    800057ca:	21c4a703          	lw	a4,540(s1)
    800057ce:	02f70d63          	beq	a4,a5,80005808 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800057d2:	0017871b          	addiw	a4,a5,1
    800057d6:	20e4ac23          	sw	a4,536(s1)
    800057da:	1ff7f793          	andi	a5,a5,511
    800057de:	97a6                	add	a5,a5,s1
    800057e0:	0187c783          	lbu	a5,24(a5)
    800057e4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800057e8:	4685                	li	a3,1
    800057ea:	fbf40613          	addi	a2,s0,-65
    800057ee:	85ca                	mv	a1,s2
    800057f0:	050a3503          	ld	a0,80(s4)
    800057f4:	ffffc097          	auipc	ra,0xffffc
    800057f8:	e90080e7          	jalr	-368(ra) # 80001684 <copyout>
    800057fc:	01650663          	beq	a0,s6,80005808 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005800:	2985                	addiw	s3,s3,1
    80005802:	0905                	addi	s2,s2,1
    80005804:	fd3a91e3          	bne	s5,s3,800057c6 <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005808:	21c48513          	addi	a0,s1,540
    8000580c:	ffffd097          	auipc	ra,0xffffd
    80005810:	e06080e7          	jalr	-506(ra) # 80002612 <wakeup>
  release(&pi->lock);
    80005814:	8526                	mv	a0,s1
    80005816:	ffffb097          	auipc	ra,0xffffb
    8000581a:	488080e7          	jalr	1160(ra) # 80000c9e <release>
  return i;
}
    8000581e:	854e                	mv	a0,s3
    80005820:	60a6                	ld	ra,72(sp)
    80005822:	6406                	ld	s0,64(sp)
    80005824:	74e2                	ld	s1,56(sp)
    80005826:	7942                	ld	s2,48(sp)
    80005828:	79a2                	ld	s3,40(sp)
    8000582a:	7a02                	ld	s4,32(sp)
    8000582c:	6ae2                	ld	s5,24(sp)
    8000582e:	6b42                	ld	s6,16(sp)
    80005830:	6161                	addi	sp,sp,80
    80005832:	8082                	ret
      release(&pi->lock);
    80005834:	8526                	mv	a0,s1
    80005836:	ffffb097          	auipc	ra,0xffffb
    8000583a:	468080e7          	jalr	1128(ra) # 80000c9e <release>
      return -1;
    8000583e:	59fd                	li	s3,-1
    80005840:	bff9                	j	8000581e <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005842:	4981                	li	s3,0
    80005844:	b7d1                	j	80005808 <piperead+0xb4>

0000000080005846 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005846:	1141                	addi	sp,sp,-16
    80005848:	e422                	sd	s0,8(sp)
    8000584a:	0800                	addi	s0,sp,16
    8000584c:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    8000584e:	8905                	andi	a0,a0,1
    80005850:	c111                	beqz	a0,80005854 <flags2perm+0xe>
      perm = PTE_X;
    80005852:	4521                	li	a0,8
    if(flags & 0x2)
    80005854:	8b89                	andi	a5,a5,2
    80005856:	c399                	beqz	a5,8000585c <flags2perm+0x16>
      perm |= PTE_W;
    80005858:	00456513          	ori	a0,a0,4
    return perm;
}
    8000585c:	6422                	ld	s0,8(sp)
    8000585e:	0141                	addi	sp,sp,16
    80005860:	8082                	ret

0000000080005862 <exec>:

int
exec(char *path, char **argv)
{
    80005862:	df010113          	addi	sp,sp,-528
    80005866:	20113423          	sd	ra,520(sp)
    8000586a:	20813023          	sd	s0,512(sp)
    8000586e:	ffa6                	sd	s1,504(sp)
    80005870:	fbca                	sd	s2,496(sp)
    80005872:	f7ce                	sd	s3,488(sp)
    80005874:	f3d2                	sd	s4,480(sp)
    80005876:	efd6                	sd	s5,472(sp)
    80005878:	ebda                	sd	s6,464(sp)
    8000587a:	e7de                	sd	s7,456(sp)
    8000587c:	e3e2                	sd	s8,448(sp)
    8000587e:	ff66                	sd	s9,440(sp)
    80005880:	fb6a                	sd	s10,432(sp)
    80005882:	f76e                	sd	s11,424(sp)
    80005884:	0c00                	addi	s0,sp,528
    80005886:	84aa                	mv	s1,a0
    80005888:	dea43c23          	sd	a0,-520(s0)
    8000588c:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005890:	ffffc097          	auipc	ra,0xffffc
    80005894:	336080e7          	jalr	822(ra) # 80001bc6 <myproc>
    80005898:	892a                	mv	s2,a0

  begin_op();
    8000589a:	fffff097          	auipc	ra,0xfffff
    8000589e:	474080e7          	jalr	1140(ra) # 80004d0e <begin_op>

  if((ip = namei(path)) == 0){
    800058a2:	8526                	mv	a0,s1
    800058a4:	fffff097          	auipc	ra,0xfffff
    800058a8:	24e080e7          	jalr	590(ra) # 80004af2 <namei>
    800058ac:	c92d                	beqz	a0,8000591e <exec+0xbc>
    800058ae:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800058b0:	fffff097          	auipc	ra,0xfffff
    800058b4:	a9c080e7          	jalr	-1380(ra) # 8000434c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800058b8:	04000713          	li	a4,64
    800058bc:	4681                	li	a3,0
    800058be:	e5040613          	addi	a2,s0,-432
    800058c2:	4581                	li	a1,0
    800058c4:	8526                	mv	a0,s1
    800058c6:	fffff097          	auipc	ra,0xfffff
    800058ca:	d3a080e7          	jalr	-710(ra) # 80004600 <readi>
    800058ce:	04000793          	li	a5,64
    800058d2:	00f51a63          	bne	a0,a5,800058e6 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800058d6:	e5042703          	lw	a4,-432(s0)
    800058da:	464c47b7          	lui	a5,0x464c4
    800058de:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800058e2:	04f70463          	beq	a4,a5,8000592a <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800058e6:	8526                	mv	a0,s1
    800058e8:	fffff097          	auipc	ra,0xfffff
    800058ec:	cc6080e7          	jalr	-826(ra) # 800045ae <iunlockput>
    end_op();
    800058f0:	fffff097          	auipc	ra,0xfffff
    800058f4:	49e080e7          	jalr	1182(ra) # 80004d8e <end_op>
  }
  return -1;
    800058f8:	557d                	li	a0,-1
}
    800058fa:	20813083          	ld	ra,520(sp)
    800058fe:	20013403          	ld	s0,512(sp)
    80005902:	74fe                	ld	s1,504(sp)
    80005904:	795e                	ld	s2,496(sp)
    80005906:	79be                	ld	s3,488(sp)
    80005908:	7a1e                	ld	s4,480(sp)
    8000590a:	6afe                	ld	s5,472(sp)
    8000590c:	6b5e                	ld	s6,464(sp)
    8000590e:	6bbe                	ld	s7,456(sp)
    80005910:	6c1e                	ld	s8,448(sp)
    80005912:	7cfa                	ld	s9,440(sp)
    80005914:	7d5a                	ld	s10,432(sp)
    80005916:	7dba                	ld	s11,424(sp)
    80005918:	21010113          	addi	sp,sp,528
    8000591c:	8082                	ret
    end_op();
    8000591e:	fffff097          	auipc	ra,0xfffff
    80005922:	470080e7          	jalr	1136(ra) # 80004d8e <end_op>
    return -1;
    80005926:	557d                	li	a0,-1
    80005928:	bfc9                	j	800058fa <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    8000592a:	854a                	mv	a0,s2
    8000592c:	ffffc097          	auipc	ra,0xffffc
    80005930:	35e080e7          	jalr	862(ra) # 80001c8a <proc_pagetable>
    80005934:	8baa                	mv	s7,a0
    80005936:	d945                	beqz	a0,800058e6 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005938:	e7042983          	lw	s3,-400(s0)
    8000593c:	e8845783          	lhu	a5,-376(s0)
    80005940:	c7ad                	beqz	a5,800059aa <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005942:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005944:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80005946:	6c85                	lui	s9,0x1
    80005948:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000594c:	def43823          	sd	a5,-528(s0)
    80005950:	ac0d                	j	80005b82 <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005952:	00004517          	auipc	a0,0x4
    80005956:	f3e50513          	addi	a0,a0,-194 # 80009890 <syscalls+0x2a8>
    8000595a:	ffffb097          	auipc	ra,0xffffb
    8000595e:	bea080e7          	jalr	-1046(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005962:	8756                	mv	a4,s5
    80005964:	012d86bb          	addw	a3,s11,s2
    80005968:	4581                	li	a1,0
    8000596a:	8526                	mv	a0,s1
    8000596c:	fffff097          	auipc	ra,0xfffff
    80005970:	c94080e7          	jalr	-876(ra) # 80004600 <readi>
    80005974:	2501                	sext.w	a0,a0
    80005976:	1aaa9a63          	bne	s5,a0,80005b2a <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    8000597a:	6785                	lui	a5,0x1
    8000597c:	0127893b          	addw	s2,a5,s2
    80005980:	77fd                	lui	a5,0xfffff
    80005982:	01478a3b          	addw	s4,a5,s4
    80005986:	1f897563          	bgeu	s2,s8,80005b70 <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    8000598a:	02091593          	slli	a1,s2,0x20
    8000598e:	9181                	srli	a1,a1,0x20
    80005990:	95ea                	add	a1,a1,s10
    80005992:	855e                	mv	a0,s7
    80005994:	ffffb097          	auipc	ra,0xffffb
    80005998:	6e4080e7          	jalr	1764(ra) # 80001078 <walkaddr>
    8000599c:	862a                	mv	a2,a0
    if(pa == 0)
    8000599e:	d955                	beqz	a0,80005952 <exec+0xf0>
      n = PGSIZE;
    800059a0:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800059a2:	fd9a70e3          	bgeu	s4,s9,80005962 <exec+0x100>
      n = sz - i;
    800059a6:	8ad2                	mv	s5,s4
    800059a8:	bf6d                	j	80005962 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800059aa:	4a01                	li	s4,0
  iunlockput(ip);
    800059ac:	8526                	mv	a0,s1
    800059ae:	fffff097          	auipc	ra,0xfffff
    800059b2:	c00080e7          	jalr	-1024(ra) # 800045ae <iunlockput>
  end_op();
    800059b6:	fffff097          	auipc	ra,0xfffff
    800059ba:	3d8080e7          	jalr	984(ra) # 80004d8e <end_op>
  p = myproc();
    800059be:	ffffc097          	auipc	ra,0xffffc
    800059c2:	208080e7          	jalr	520(ra) # 80001bc6 <myproc>
    800059c6:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800059c8:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800059cc:	6785                	lui	a5,0x1
    800059ce:	17fd                	addi	a5,a5,-1
    800059d0:	9a3e                	add	s4,s4,a5
    800059d2:	757d                	lui	a0,0xfffff
    800059d4:	00aa77b3          	and	a5,s4,a0
    800059d8:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800059dc:	4691                	li	a3,4
    800059de:	6609                	lui	a2,0x2
    800059e0:	963e                	add	a2,a2,a5
    800059e2:	85be                	mv	a1,a5
    800059e4:	855e                	mv	a0,s7
    800059e6:	ffffc097          	auipc	ra,0xffffc
    800059ea:	a46080e7          	jalr	-1466(ra) # 8000142c <uvmalloc>
    800059ee:	8b2a                	mv	s6,a0
  ip = 0;
    800059f0:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800059f2:	12050c63          	beqz	a0,80005b2a <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    800059f6:	75f9                	lui	a1,0xffffe
    800059f8:	95aa                	add	a1,a1,a0
    800059fa:	855e                	mv	a0,s7
    800059fc:	ffffc097          	auipc	ra,0xffffc
    80005a00:	c56080e7          	jalr	-938(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    80005a04:	7c7d                	lui	s8,0xfffff
    80005a06:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005a08:	e0043783          	ld	a5,-512(s0)
    80005a0c:	6388                	ld	a0,0(a5)
    80005a0e:	c535                	beqz	a0,80005a7a <exec+0x218>
    80005a10:	e9040993          	addi	s3,s0,-368
    80005a14:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005a18:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005a1a:	ffffb097          	auipc	ra,0xffffb
    80005a1e:	450080e7          	jalr	1104(ra) # 80000e6a <strlen>
    80005a22:	2505                	addiw	a0,a0,1
    80005a24:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005a28:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005a2c:	13896663          	bltu	s2,s8,80005b58 <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005a30:	e0043d83          	ld	s11,-512(s0)
    80005a34:	000dba03          	ld	s4,0(s11)
    80005a38:	8552                	mv	a0,s4
    80005a3a:	ffffb097          	auipc	ra,0xffffb
    80005a3e:	430080e7          	jalr	1072(ra) # 80000e6a <strlen>
    80005a42:	0015069b          	addiw	a3,a0,1
    80005a46:	8652                	mv	a2,s4
    80005a48:	85ca                	mv	a1,s2
    80005a4a:	855e                	mv	a0,s7
    80005a4c:	ffffc097          	auipc	ra,0xffffc
    80005a50:	c38080e7          	jalr	-968(ra) # 80001684 <copyout>
    80005a54:	10054663          	bltz	a0,80005b60 <exec+0x2fe>
    ustack[argc] = sp;
    80005a58:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005a5c:	0485                	addi	s1,s1,1
    80005a5e:	008d8793          	addi	a5,s11,8
    80005a62:	e0f43023          	sd	a5,-512(s0)
    80005a66:	008db503          	ld	a0,8(s11)
    80005a6a:	c911                	beqz	a0,80005a7e <exec+0x21c>
    if(argc >= MAXARG)
    80005a6c:	09a1                	addi	s3,s3,8
    80005a6e:	fb3c96e3          	bne	s9,s3,80005a1a <exec+0x1b8>
  sz = sz1;
    80005a72:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005a76:	4481                	li	s1,0
    80005a78:	a84d                	j	80005b2a <exec+0x2c8>
  sp = sz;
    80005a7a:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005a7c:	4481                	li	s1,0
  ustack[argc] = 0;
    80005a7e:	00349793          	slli	a5,s1,0x3
    80005a82:	f9040713          	addi	a4,s0,-112
    80005a86:	97ba                	add	a5,a5,a4
    80005a88:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005a8c:	00148693          	addi	a3,s1,1
    80005a90:	068e                	slli	a3,a3,0x3
    80005a92:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005a96:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005a9a:	01897663          	bgeu	s2,s8,80005aa6 <exec+0x244>
  sz = sz1;
    80005a9e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005aa2:	4481                	li	s1,0
    80005aa4:	a059                	j	80005b2a <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005aa6:	e9040613          	addi	a2,s0,-368
    80005aaa:	85ca                	mv	a1,s2
    80005aac:	855e                	mv	a0,s7
    80005aae:	ffffc097          	auipc	ra,0xffffc
    80005ab2:	bd6080e7          	jalr	-1066(ra) # 80001684 <copyout>
    80005ab6:	0a054963          	bltz	a0,80005b68 <exec+0x306>
  p->trapframe->a1 = sp;
    80005aba:	058ab783          	ld	a5,88(s5)
    80005abe:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005ac2:	df843783          	ld	a5,-520(s0)
    80005ac6:	0007c703          	lbu	a4,0(a5)
    80005aca:	cf11                	beqz	a4,80005ae6 <exec+0x284>
    80005acc:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005ace:	02f00693          	li	a3,47
    80005ad2:	a039                	j	80005ae0 <exec+0x27e>
      last = s+1;
    80005ad4:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005ad8:	0785                	addi	a5,a5,1
    80005ada:	fff7c703          	lbu	a4,-1(a5)
    80005ade:	c701                	beqz	a4,80005ae6 <exec+0x284>
    if(*s == '/')
    80005ae0:	fed71ce3          	bne	a4,a3,80005ad8 <exec+0x276>
    80005ae4:	bfc5                	j	80005ad4 <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80005ae6:	4641                	li	a2,16
    80005ae8:	df843583          	ld	a1,-520(s0)
    80005aec:	158a8513          	addi	a0,s5,344
    80005af0:	ffffb097          	auipc	ra,0xffffb
    80005af4:	348080e7          	jalr	840(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    80005af8:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005afc:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005b00:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005b04:	058ab783          	ld	a5,88(s5)
    80005b08:	e6843703          	ld	a4,-408(s0)
    80005b0c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005b0e:	058ab783          	ld	a5,88(s5)
    80005b12:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005b16:	85ea                	mv	a1,s10
    80005b18:	ffffc097          	auipc	ra,0xffffc
    80005b1c:	20e080e7          	jalr	526(ra) # 80001d26 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005b20:	0004851b          	sext.w	a0,s1
    80005b24:	bbd9                	j	800058fa <exec+0x98>
    80005b26:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005b2a:	e0843583          	ld	a1,-504(s0)
    80005b2e:	855e                	mv	a0,s7
    80005b30:	ffffc097          	auipc	ra,0xffffc
    80005b34:	1f6080e7          	jalr	502(ra) # 80001d26 <proc_freepagetable>
  if(ip){
    80005b38:	da0497e3          	bnez	s1,800058e6 <exec+0x84>
  return -1;
    80005b3c:	557d                	li	a0,-1
    80005b3e:	bb75                	j	800058fa <exec+0x98>
    80005b40:	e1443423          	sd	s4,-504(s0)
    80005b44:	b7dd                	j	80005b2a <exec+0x2c8>
    80005b46:	e1443423          	sd	s4,-504(s0)
    80005b4a:	b7c5                	j	80005b2a <exec+0x2c8>
    80005b4c:	e1443423          	sd	s4,-504(s0)
    80005b50:	bfe9                	j	80005b2a <exec+0x2c8>
    80005b52:	e1443423          	sd	s4,-504(s0)
    80005b56:	bfd1                	j	80005b2a <exec+0x2c8>
  sz = sz1;
    80005b58:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005b5c:	4481                	li	s1,0
    80005b5e:	b7f1                	j	80005b2a <exec+0x2c8>
  sz = sz1;
    80005b60:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005b64:	4481                	li	s1,0
    80005b66:	b7d1                	j	80005b2a <exec+0x2c8>
  sz = sz1;
    80005b68:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005b6c:	4481                	li	s1,0
    80005b6e:	bf75                	j	80005b2a <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005b70:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005b74:	2b05                	addiw	s6,s6,1
    80005b76:	0389899b          	addiw	s3,s3,56
    80005b7a:	e8845783          	lhu	a5,-376(s0)
    80005b7e:	e2fb57e3          	bge	s6,a5,800059ac <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005b82:	2981                	sext.w	s3,s3
    80005b84:	03800713          	li	a4,56
    80005b88:	86ce                	mv	a3,s3
    80005b8a:	e1840613          	addi	a2,s0,-488
    80005b8e:	4581                	li	a1,0
    80005b90:	8526                	mv	a0,s1
    80005b92:	fffff097          	auipc	ra,0xfffff
    80005b96:	a6e080e7          	jalr	-1426(ra) # 80004600 <readi>
    80005b9a:	03800793          	li	a5,56
    80005b9e:	f8f514e3          	bne	a0,a5,80005b26 <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    80005ba2:	e1842783          	lw	a5,-488(s0)
    80005ba6:	4705                	li	a4,1
    80005ba8:	fce796e3          	bne	a5,a4,80005b74 <exec+0x312>
    if(ph.memsz < ph.filesz)
    80005bac:	e4043903          	ld	s2,-448(s0)
    80005bb0:	e3843783          	ld	a5,-456(s0)
    80005bb4:	f8f966e3          	bltu	s2,a5,80005b40 <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005bb8:	e2843783          	ld	a5,-472(s0)
    80005bbc:	993e                	add	s2,s2,a5
    80005bbe:	f8f964e3          	bltu	s2,a5,80005b46 <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    80005bc2:	df043703          	ld	a4,-528(s0)
    80005bc6:	8ff9                	and	a5,a5,a4
    80005bc8:	f3d1                	bnez	a5,80005b4c <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005bca:	e1c42503          	lw	a0,-484(s0)
    80005bce:	00000097          	auipc	ra,0x0
    80005bd2:	c78080e7          	jalr	-904(ra) # 80005846 <flags2perm>
    80005bd6:	86aa                	mv	a3,a0
    80005bd8:	864a                	mv	a2,s2
    80005bda:	85d2                	mv	a1,s4
    80005bdc:	855e                	mv	a0,s7
    80005bde:	ffffc097          	auipc	ra,0xffffc
    80005be2:	84e080e7          	jalr	-1970(ra) # 8000142c <uvmalloc>
    80005be6:	e0a43423          	sd	a0,-504(s0)
    80005bea:	d525                	beqz	a0,80005b52 <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005bec:	e2843d03          	ld	s10,-472(s0)
    80005bf0:	e2042d83          	lw	s11,-480(s0)
    80005bf4:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005bf8:	f60c0ce3          	beqz	s8,80005b70 <exec+0x30e>
    80005bfc:	8a62                	mv	s4,s8
    80005bfe:	4901                	li	s2,0
    80005c00:	b369                	j	8000598a <exec+0x128>

0000000080005c02 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005c02:	7179                	addi	sp,sp,-48
    80005c04:	f406                	sd	ra,40(sp)
    80005c06:	f022                	sd	s0,32(sp)
    80005c08:	ec26                	sd	s1,24(sp)
    80005c0a:	e84a                	sd	s2,16(sp)
    80005c0c:	1800                	addi	s0,sp,48
    80005c0e:	892e                	mv	s2,a1
    80005c10:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005c12:	fdc40593          	addi	a1,s0,-36
    80005c16:	ffffd097          	auipc	ra,0xffffd
    80005c1a:	5da080e7          	jalr	1498(ra) # 800031f0 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005c1e:	fdc42703          	lw	a4,-36(s0)
    80005c22:	47bd                	li	a5,15
    80005c24:	02e7eb63          	bltu	a5,a4,80005c5a <argfd+0x58>
    80005c28:	ffffc097          	auipc	ra,0xffffc
    80005c2c:	f9e080e7          	jalr	-98(ra) # 80001bc6 <myproc>
    80005c30:	fdc42703          	lw	a4,-36(s0)
    80005c34:	01a70793          	addi	a5,a4,26
    80005c38:	078e                	slli	a5,a5,0x3
    80005c3a:	953e                	add	a0,a0,a5
    80005c3c:	611c                	ld	a5,0(a0)
    80005c3e:	c385                	beqz	a5,80005c5e <argfd+0x5c>
    return -1;
  if(pfd)
    80005c40:	00090463          	beqz	s2,80005c48 <argfd+0x46>
    *pfd = fd;
    80005c44:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005c48:	4501                	li	a0,0
  if(pf)
    80005c4a:	c091                	beqz	s1,80005c4e <argfd+0x4c>
    *pf = f;
    80005c4c:	e09c                	sd	a5,0(s1)
}
    80005c4e:	70a2                	ld	ra,40(sp)
    80005c50:	7402                	ld	s0,32(sp)
    80005c52:	64e2                	ld	s1,24(sp)
    80005c54:	6942                	ld	s2,16(sp)
    80005c56:	6145                	addi	sp,sp,48
    80005c58:	8082                	ret
    return -1;
    80005c5a:	557d                	li	a0,-1
    80005c5c:	bfcd                	j	80005c4e <argfd+0x4c>
    80005c5e:	557d                	li	a0,-1
    80005c60:	b7fd                	j	80005c4e <argfd+0x4c>

0000000080005c62 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005c62:	1101                	addi	sp,sp,-32
    80005c64:	ec06                	sd	ra,24(sp)
    80005c66:	e822                	sd	s0,16(sp)
    80005c68:	e426                	sd	s1,8(sp)
    80005c6a:	1000                	addi	s0,sp,32
    80005c6c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005c6e:	ffffc097          	auipc	ra,0xffffc
    80005c72:	f58080e7          	jalr	-168(ra) # 80001bc6 <myproc>
    80005c76:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005c78:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd8ab8>
    80005c7c:	4501                	li	a0,0
    80005c7e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005c80:	6398                	ld	a4,0(a5)
    80005c82:	cb19                	beqz	a4,80005c98 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005c84:	2505                	addiw	a0,a0,1
    80005c86:	07a1                	addi	a5,a5,8
    80005c88:	fed51ce3          	bne	a0,a3,80005c80 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005c8c:	557d                	li	a0,-1
}
    80005c8e:	60e2                	ld	ra,24(sp)
    80005c90:	6442                	ld	s0,16(sp)
    80005c92:	64a2                	ld	s1,8(sp)
    80005c94:	6105                	addi	sp,sp,32
    80005c96:	8082                	ret
      p->ofile[fd] = f;
    80005c98:	01a50793          	addi	a5,a0,26
    80005c9c:	078e                	slli	a5,a5,0x3
    80005c9e:	963e                	add	a2,a2,a5
    80005ca0:	e204                	sd	s1,0(a2)
      return fd;
    80005ca2:	b7f5                	j	80005c8e <fdalloc+0x2c>

0000000080005ca4 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005ca4:	715d                	addi	sp,sp,-80
    80005ca6:	e486                	sd	ra,72(sp)
    80005ca8:	e0a2                	sd	s0,64(sp)
    80005caa:	fc26                	sd	s1,56(sp)
    80005cac:	f84a                	sd	s2,48(sp)
    80005cae:	f44e                	sd	s3,40(sp)
    80005cb0:	f052                	sd	s4,32(sp)
    80005cb2:	ec56                	sd	s5,24(sp)
    80005cb4:	e85a                	sd	s6,16(sp)
    80005cb6:	0880                	addi	s0,sp,80
    80005cb8:	8b2e                	mv	s6,a1
    80005cba:	89b2                	mv	s3,a2
    80005cbc:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005cbe:	fb040593          	addi	a1,s0,-80
    80005cc2:	fffff097          	auipc	ra,0xfffff
    80005cc6:	e4e080e7          	jalr	-434(ra) # 80004b10 <nameiparent>
    80005cca:	84aa                	mv	s1,a0
    80005ccc:	16050063          	beqz	a0,80005e2c <create+0x188>
    return 0;

  ilock(dp);
    80005cd0:	ffffe097          	auipc	ra,0xffffe
    80005cd4:	67c080e7          	jalr	1660(ra) # 8000434c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005cd8:	4601                	li	a2,0
    80005cda:	fb040593          	addi	a1,s0,-80
    80005cde:	8526                	mv	a0,s1
    80005ce0:	fffff097          	auipc	ra,0xfffff
    80005ce4:	b50080e7          	jalr	-1200(ra) # 80004830 <dirlookup>
    80005ce8:	8aaa                	mv	s5,a0
    80005cea:	c931                	beqz	a0,80005d3e <create+0x9a>
    iunlockput(dp);
    80005cec:	8526                	mv	a0,s1
    80005cee:	fffff097          	auipc	ra,0xfffff
    80005cf2:	8c0080e7          	jalr	-1856(ra) # 800045ae <iunlockput>
    ilock(ip);
    80005cf6:	8556                	mv	a0,s5
    80005cf8:	ffffe097          	auipc	ra,0xffffe
    80005cfc:	654080e7          	jalr	1620(ra) # 8000434c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005d00:	000b059b          	sext.w	a1,s6
    80005d04:	4789                	li	a5,2
    80005d06:	02f59563          	bne	a1,a5,80005d30 <create+0x8c>
    80005d0a:	044ad783          	lhu	a5,68(s5)
    80005d0e:	37f9                	addiw	a5,a5,-2
    80005d10:	17c2                	slli	a5,a5,0x30
    80005d12:	93c1                	srli	a5,a5,0x30
    80005d14:	4705                	li	a4,1
    80005d16:	00f76d63          	bltu	a4,a5,80005d30 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005d1a:	8556                	mv	a0,s5
    80005d1c:	60a6                	ld	ra,72(sp)
    80005d1e:	6406                	ld	s0,64(sp)
    80005d20:	74e2                	ld	s1,56(sp)
    80005d22:	7942                	ld	s2,48(sp)
    80005d24:	79a2                	ld	s3,40(sp)
    80005d26:	7a02                	ld	s4,32(sp)
    80005d28:	6ae2                	ld	s5,24(sp)
    80005d2a:	6b42                	ld	s6,16(sp)
    80005d2c:	6161                	addi	sp,sp,80
    80005d2e:	8082                	ret
    iunlockput(ip);
    80005d30:	8556                	mv	a0,s5
    80005d32:	fffff097          	auipc	ra,0xfffff
    80005d36:	87c080e7          	jalr	-1924(ra) # 800045ae <iunlockput>
    return 0;
    80005d3a:	4a81                	li	s5,0
    80005d3c:	bff9                	j	80005d1a <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005d3e:	85da                	mv	a1,s6
    80005d40:	4088                	lw	a0,0(s1)
    80005d42:	ffffe097          	auipc	ra,0xffffe
    80005d46:	46e080e7          	jalr	1134(ra) # 800041b0 <ialloc>
    80005d4a:	8a2a                	mv	s4,a0
    80005d4c:	c921                	beqz	a0,80005d9c <create+0xf8>
  ilock(ip);
    80005d4e:	ffffe097          	auipc	ra,0xffffe
    80005d52:	5fe080e7          	jalr	1534(ra) # 8000434c <ilock>
  ip->major = major;
    80005d56:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005d5a:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005d5e:	4785                	li	a5,1
    80005d60:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    80005d64:	8552                	mv	a0,s4
    80005d66:	ffffe097          	auipc	ra,0xffffe
    80005d6a:	51c080e7          	jalr	1308(ra) # 80004282 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005d6e:	000b059b          	sext.w	a1,s6
    80005d72:	4785                	li	a5,1
    80005d74:	02f58b63          	beq	a1,a5,80005daa <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    80005d78:	004a2603          	lw	a2,4(s4)
    80005d7c:	fb040593          	addi	a1,s0,-80
    80005d80:	8526                	mv	a0,s1
    80005d82:	fffff097          	auipc	ra,0xfffff
    80005d86:	cbe080e7          	jalr	-834(ra) # 80004a40 <dirlink>
    80005d8a:	06054f63          	bltz	a0,80005e08 <create+0x164>
  iunlockput(dp);
    80005d8e:	8526                	mv	a0,s1
    80005d90:	fffff097          	auipc	ra,0xfffff
    80005d94:	81e080e7          	jalr	-2018(ra) # 800045ae <iunlockput>
  return ip;
    80005d98:	8ad2                	mv	s5,s4
    80005d9a:	b741                	j	80005d1a <create+0x76>
    iunlockput(dp);
    80005d9c:	8526                	mv	a0,s1
    80005d9e:	fffff097          	auipc	ra,0xfffff
    80005da2:	810080e7          	jalr	-2032(ra) # 800045ae <iunlockput>
    return 0;
    80005da6:	8ad2                	mv	s5,s4
    80005da8:	bf8d                	j	80005d1a <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005daa:	004a2603          	lw	a2,4(s4)
    80005dae:	00004597          	auipc	a1,0x4
    80005db2:	b0258593          	addi	a1,a1,-1278 # 800098b0 <syscalls+0x2c8>
    80005db6:	8552                	mv	a0,s4
    80005db8:	fffff097          	auipc	ra,0xfffff
    80005dbc:	c88080e7          	jalr	-888(ra) # 80004a40 <dirlink>
    80005dc0:	04054463          	bltz	a0,80005e08 <create+0x164>
    80005dc4:	40d0                	lw	a2,4(s1)
    80005dc6:	00004597          	auipc	a1,0x4
    80005dca:	af258593          	addi	a1,a1,-1294 # 800098b8 <syscalls+0x2d0>
    80005dce:	8552                	mv	a0,s4
    80005dd0:	fffff097          	auipc	ra,0xfffff
    80005dd4:	c70080e7          	jalr	-912(ra) # 80004a40 <dirlink>
    80005dd8:	02054863          	bltz	a0,80005e08 <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    80005ddc:	004a2603          	lw	a2,4(s4)
    80005de0:	fb040593          	addi	a1,s0,-80
    80005de4:	8526                	mv	a0,s1
    80005de6:	fffff097          	auipc	ra,0xfffff
    80005dea:	c5a080e7          	jalr	-934(ra) # 80004a40 <dirlink>
    80005dee:	00054d63          	bltz	a0,80005e08 <create+0x164>
    dp->nlink++;  // for ".."
    80005df2:	04a4d783          	lhu	a5,74(s1)
    80005df6:	2785                	addiw	a5,a5,1
    80005df8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005dfc:	8526                	mv	a0,s1
    80005dfe:	ffffe097          	auipc	ra,0xffffe
    80005e02:	484080e7          	jalr	1156(ra) # 80004282 <iupdate>
    80005e06:	b761                	j	80005d8e <create+0xea>
  ip->nlink = 0;
    80005e08:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005e0c:	8552                	mv	a0,s4
    80005e0e:	ffffe097          	auipc	ra,0xffffe
    80005e12:	474080e7          	jalr	1140(ra) # 80004282 <iupdate>
  iunlockput(ip);
    80005e16:	8552                	mv	a0,s4
    80005e18:	ffffe097          	auipc	ra,0xffffe
    80005e1c:	796080e7          	jalr	1942(ra) # 800045ae <iunlockput>
  iunlockput(dp);
    80005e20:	8526                	mv	a0,s1
    80005e22:	ffffe097          	auipc	ra,0xffffe
    80005e26:	78c080e7          	jalr	1932(ra) # 800045ae <iunlockput>
  return 0;
    80005e2a:	bdc5                	j	80005d1a <create+0x76>
    return 0;
    80005e2c:	8aaa                	mv	s5,a0
    80005e2e:	b5f5                	j	80005d1a <create+0x76>

0000000080005e30 <sys_dup>:
{
    80005e30:	7179                	addi	sp,sp,-48
    80005e32:	f406                	sd	ra,40(sp)
    80005e34:	f022                	sd	s0,32(sp)
    80005e36:	ec26                	sd	s1,24(sp)
    80005e38:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005e3a:	fd840613          	addi	a2,s0,-40
    80005e3e:	4581                	li	a1,0
    80005e40:	4501                	li	a0,0
    80005e42:	00000097          	auipc	ra,0x0
    80005e46:	dc0080e7          	jalr	-576(ra) # 80005c02 <argfd>
    return -1;
    80005e4a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005e4c:	02054363          	bltz	a0,80005e72 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005e50:	fd843503          	ld	a0,-40(s0)
    80005e54:	00000097          	auipc	ra,0x0
    80005e58:	e0e080e7          	jalr	-498(ra) # 80005c62 <fdalloc>
    80005e5c:	84aa                	mv	s1,a0
    return -1;
    80005e5e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005e60:	00054963          	bltz	a0,80005e72 <sys_dup+0x42>
  filedup(f);
    80005e64:	fd843503          	ld	a0,-40(s0)
    80005e68:	fffff097          	auipc	ra,0xfffff
    80005e6c:	320080e7          	jalr	800(ra) # 80005188 <filedup>
  return fd;
    80005e70:	87a6                	mv	a5,s1
}
    80005e72:	853e                	mv	a0,a5
    80005e74:	70a2                	ld	ra,40(sp)
    80005e76:	7402                	ld	s0,32(sp)
    80005e78:	64e2                	ld	s1,24(sp)
    80005e7a:	6145                	addi	sp,sp,48
    80005e7c:	8082                	ret

0000000080005e7e <sys_read>:
{
    80005e7e:	7179                	addi	sp,sp,-48
    80005e80:	f406                	sd	ra,40(sp)
    80005e82:	f022                	sd	s0,32(sp)
    80005e84:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005e86:	fd840593          	addi	a1,s0,-40
    80005e8a:	4505                	li	a0,1
    80005e8c:	ffffd097          	auipc	ra,0xffffd
    80005e90:	384080e7          	jalr	900(ra) # 80003210 <argaddr>
  argint(2, &n);
    80005e94:	fe440593          	addi	a1,s0,-28
    80005e98:	4509                	li	a0,2
    80005e9a:	ffffd097          	auipc	ra,0xffffd
    80005e9e:	356080e7          	jalr	854(ra) # 800031f0 <argint>
  if(argfd(0, 0, &f) < 0)
    80005ea2:	fe840613          	addi	a2,s0,-24
    80005ea6:	4581                	li	a1,0
    80005ea8:	4501                	li	a0,0
    80005eaa:	00000097          	auipc	ra,0x0
    80005eae:	d58080e7          	jalr	-680(ra) # 80005c02 <argfd>
    80005eb2:	87aa                	mv	a5,a0
    return -1;
    80005eb4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005eb6:	0007cc63          	bltz	a5,80005ece <sys_read+0x50>
  return fileread(f, p, n);
    80005eba:	fe442603          	lw	a2,-28(s0)
    80005ebe:	fd843583          	ld	a1,-40(s0)
    80005ec2:	fe843503          	ld	a0,-24(s0)
    80005ec6:	fffff097          	auipc	ra,0xfffff
    80005eca:	44e080e7          	jalr	1102(ra) # 80005314 <fileread>
}
    80005ece:	70a2                	ld	ra,40(sp)
    80005ed0:	7402                	ld	s0,32(sp)
    80005ed2:	6145                	addi	sp,sp,48
    80005ed4:	8082                	ret

0000000080005ed6 <sys_write>:
{
    80005ed6:	7179                	addi	sp,sp,-48
    80005ed8:	f406                	sd	ra,40(sp)
    80005eda:	f022                	sd	s0,32(sp)
    80005edc:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005ede:	fd840593          	addi	a1,s0,-40
    80005ee2:	4505                	li	a0,1
    80005ee4:	ffffd097          	auipc	ra,0xffffd
    80005ee8:	32c080e7          	jalr	812(ra) # 80003210 <argaddr>
  argint(2, &n);
    80005eec:	fe440593          	addi	a1,s0,-28
    80005ef0:	4509                	li	a0,2
    80005ef2:	ffffd097          	auipc	ra,0xffffd
    80005ef6:	2fe080e7          	jalr	766(ra) # 800031f0 <argint>
  if(argfd(0, 0, &f) < 0)
    80005efa:	fe840613          	addi	a2,s0,-24
    80005efe:	4581                	li	a1,0
    80005f00:	4501                	li	a0,0
    80005f02:	00000097          	auipc	ra,0x0
    80005f06:	d00080e7          	jalr	-768(ra) # 80005c02 <argfd>
    80005f0a:	87aa                	mv	a5,a0
    return -1;
    80005f0c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005f0e:	0007cc63          	bltz	a5,80005f26 <sys_write+0x50>
  return filewrite(f, p, n);
    80005f12:	fe442603          	lw	a2,-28(s0)
    80005f16:	fd843583          	ld	a1,-40(s0)
    80005f1a:	fe843503          	ld	a0,-24(s0)
    80005f1e:	fffff097          	auipc	ra,0xfffff
    80005f22:	4b8080e7          	jalr	1208(ra) # 800053d6 <filewrite>
}
    80005f26:	70a2                	ld	ra,40(sp)
    80005f28:	7402                	ld	s0,32(sp)
    80005f2a:	6145                	addi	sp,sp,48
    80005f2c:	8082                	ret

0000000080005f2e <sys_close>:
{
    80005f2e:	1101                	addi	sp,sp,-32
    80005f30:	ec06                	sd	ra,24(sp)
    80005f32:	e822                	sd	s0,16(sp)
    80005f34:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005f36:	fe040613          	addi	a2,s0,-32
    80005f3a:	fec40593          	addi	a1,s0,-20
    80005f3e:	4501                	li	a0,0
    80005f40:	00000097          	auipc	ra,0x0
    80005f44:	cc2080e7          	jalr	-830(ra) # 80005c02 <argfd>
    return -1;
    80005f48:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005f4a:	02054463          	bltz	a0,80005f72 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005f4e:	ffffc097          	auipc	ra,0xffffc
    80005f52:	c78080e7          	jalr	-904(ra) # 80001bc6 <myproc>
    80005f56:	fec42783          	lw	a5,-20(s0)
    80005f5a:	07e9                	addi	a5,a5,26
    80005f5c:	078e                	slli	a5,a5,0x3
    80005f5e:	97aa                	add	a5,a5,a0
    80005f60:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005f64:	fe043503          	ld	a0,-32(s0)
    80005f68:	fffff097          	auipc	ra,0xfffff
    80005f6c:	272080e7          	jalr	626(ra) # 800051da <fileclose>
  return 0;
    80005f70:	4781                	li	a5,0
}
    80005f72:	853e                	mv	a0,a5
    80005f74:	60e2                	ld	ra,24(sp)
    80005f76:	6442                	ld	s0,16(sp)
    80005f78:	6105                	addi	sp,sp,32
    80005f7a:	8082                	ret

0000000080005f7c <sys_fstat>:
{
    80005f7c:	1101                	addi	sp,sp,-32
    80005f7e:	ec06                	sd	ra,24(sp)
    80005f80:	e822                	sd	s0,16(sp)
    80005f82:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005f84:	fe040593          	addi	a1,s0,-32
    80005f88:	4505                	li	a0,1
    80005f8a:	ffffd097          	auipc	ra,0xffffd
    80005f8e:	286080e7          	jalr	646(ra) # 80003210 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005f92:	fe840613          	addi	a2,s0,-24
    80005f96:	4581                	li	a1,0
    80005f98:	4501                	li	a0,0
    80005f9a:	00000097          	auipc	ra,0x0
    80005f9e:	c68080e7          	jalr	-920(ra) # 80005c02 <argfd>
    80005fa2:	87aa                	mv	a5,a0
    return -1;
    80005fa4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005fa6:	0007ca63          	bltz	a5,80005fba <sys_fstat+0x3e>
  return filestat(f, st);
    80005faa:	fe043583          	ld	a1,-32(s0)
    80005fae:	fe843503          	ld	a0,-24(s0)
    80005fb2:	fffff097          	auipc	ra,0xfffff
    80005fb6:	2f0080e7          	jalr	752(ra) # 800052a2 <filestat>
}
    80005fba:	60e2                	ld	ra,24(sp)
    80005fbc:	6442                	ld	s0,16(sp)
    80005fbe:	6105                	addi	sp,sp,32
    80005fc0:	8082                	ret

0000000080005fc2 <sys_link>:
{
    80005fc2:	7169                	addi	sp,sp,-304
    80005fc4:	f606                	sd	ra,296(sp)
    80005fc6:	f222                	sd	s0,288(sp)
    80005fc8:	ee26                	sd	s1,280(sp)
    80005fca:	ea4a                	sd	s2,272(sp)
    80005fcc:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005fce:	08000613          	li	a2,128
    80005fd2:	ed040593          	addi	a1,s0,-304
    80005fd6:	4501                	li	a0,0
    80005fd8:	ffffd097          	auipc	ra,0xffffd
    80005fdc:	258080e7          	jalr	600(ra) # 80003230 <argstr>
    return -1;
    80005fe0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005fe2:	10054e63          	bltz	a0,800060fe <sys_link+0x13c>
    80005fe6:	08000613          	li	a2,128
    80005fea:	f5040593          	addi	a1,s0,-176
    80005fee:	4505                	li	a0,1
    80005ff0:	ffffd097          	auipc	ra,0xffffd
    80005ff4:	240080e7          	jalr	576(ra) # 80003230 <argstr>
    return -1;
    80005ff8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ffa:	10054263          	bltz	a0,800060fe <sys_link+0x13c>
  begin_op();
    80005ffe:	fffff097          	auipc	ra,0xfffff
    80006002:	d10080e7          	jalr	-752(ra) # 80004d0e <begin_op>
  if((ip = namei(old)) == 0){
    80006006:	ed040513          	addi	a0,s0,-304
    8000600a:	fffff097          	auipc	ra,0xfffff
    8000600e:	ae8080e7          	jalr	-1304(ra) # 80004af2 <namei>
    80006012:	84aa                	mv	s1,a0
    80006014:	c551                	beqz	a0,800060a0 <sys_link+0xde>
  ilock(ip);
    80006016:	ffffe097          	auipc	ra,0xffffe
    8000601a:	336080e7          	jalr	822(ra) # 8000434c <ilock>
  if(ip->type == T_DIR){
    8000601e:	04449703          	lh	a4,68(s1)
    80006022:	4785                	li	a5,1
    80006024:	08f70463          	beq	a4,a5,800060ac <sys_link+0xea>
  ip->nlink++;
    80006028:	04a4d783          	lhu	a5,74(s1)
    8000602c:	2785                	addiw	a5,a5,1
    8000602e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006032:	8526                	mv	a0,s1
    80006034:	ffffe097          	auipc	ra,0xffffe
    80006038:	24e080e7          	jalr	590(ra) # 80004282 <iupdate>
  iunlock(ip);
    8000603c:	8526                	mv	a0,s1
    8000603e:	ffffe097          	auipc	ra,0xffffe
    80006042:	3d0080e7          	jalr	976(ra) # 8000440e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80006046:	fd040593          	addi	a1,s0,-48
    8000604a:	f5040513          	addi	a0,s0,-176
    8000604e:	fffff097          	auipc	ra,0xfffff
    80006052:	ac2080e7          	jalr	-1342(ra) # 80004b10 <nameiparent>
    80006056:	892a                	mv	s2,a0
    80006058:	c935                	beqz	a0,800060cc <sys_link+0x10a>
  ilock(dp);
    8000605a:	ffffe097          	auipc	ra,0xffffe
    8000605e:	2f2080e7          	jalr	754(ra) # 8000434c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80006062:	00092703          	lw	a4,0(s2)
    80006066:	409c                	lw	a5,0(s1)
    80006068:	04f71d63          	bne	a4,a5,800060c2 <sys_link+0x100>
    8000606c:	40d0                	lw	a2,4(s1)
    8000606e:	fd040593          	addi	a1,s0,-48
    80006072:	854a                	mv	a0,s2
    80006074:	fffff097          	auipc	ra,0xfffff
    80006078:	9cc080e7          	jalr	-1588(ra) # 80004a40 <dirlink>
    8000607c:	04054363          	bltz	a0,800060c2 <sys_link+0x100>
  iunlockput(dp);
    80006080:	854a                	mv	a0,s2
    80006082:	ffffe097          	auipc	ra,0xffffe
    80006086:	52c080e7          	jalr	1324(ra) # 800045ae <iunlockput>
  iput(ip);
    8000608a:	8526                	mv	a0,s1
    8000608c:	ffffe097          	auipc	ra,0xffffe
    80006090:	47a080e7          	jalr	1146(ra) # 80004506 <iput>
  end_op();
    80006094:	fffff097          	auipc	ra,0xfffff
    80006098:	cfa080e7          	jalr	-774(ra) # 80004d8e <end_op>
  return 0;
    8000609c:	4781                	li	a5,0
    8000609e:	a085                	j	800060fe <sys_link+0x13c>
    end_op();
    800060a0:	fffff097          	auipc	ra,0xfffff
    800060a4:	cee080e7          	jalr	-786(ra) # 80004d8e <end_op>
    return -1;
    800060a8:	57fd                	li	a5,-1
    800060aa:	a891                	j	800060fe <sys_link+0x13c>
    iunlockput(ip);
    800060ac:	8526                	mv	a0,s1
    800060ae:	ffffe097          	auipc	ra,0xffffe
    800060b2:	500080e7          	jalr	1280(ra) # 800045ae <iunlockput>
    end_op();
    800060b6:	fffff097          	auipc	ra,0xfffff
    800060ba:	cd8080e7          	jalr	-808(ra) # 80004d8e <end_op>
    return -1;
    800060be:	57fd                	li	a5,-1
    800060c0:	a83d                	j	800060fe <sys_link+0x13c>
    iunlockput(dp);
    800060c2:	854a                	mv	a0,s2
    800060c4:	ffffe097          	auipc	ra,0xffffe
    800060c8:	4ea080e7          	jalr	1258(ra) # 800045ae <iunlockput>
  ilock(ip);
    800060cc:	8526                	mv	a0,s1
    800060ce:	ffffe097          	auipc	ra,0xffffe
    800060d2:	27e080e7          	jalr	638(ra) # 8000434c <ilock>
  ip->nlink--;
    800060d6:	04a4d783          	lhu	a5,74(s1)
    800060da:	37fd                	addiw	a5,a5,-1
    800060dc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800060e0:	8526                	mv	a0,s1
    800060e2:	ffffe097          	auipc	ra,0xffffe
    800060e6:	1a0080e7          	jalr	416(ra) # 80004282 <iupdate>
  iunlockput(ip);
    800060ea:	8526                	mv	a0,s1
    800060ec:	ffffe097          	auipc	ra,0xffffe
    800060f0:	4c2080e7          	jalr	1218(ra) # 800045ae <iunlockput>
  end_op();
    800060f4:	fffff097          	auipc	ra,0xfffff
    800060f8:	c9a080e7          	jalr	-870(ra) # 80004d8e <end_op>
  return -1;
    800060fc:	57fd                	li	a5,-1
}
    800060fe:	853e                	mv	a0,a5
    80006100:	70b2                	ld	ra,296(sp)
    80006102:	7412                	ld	s0,288(sp)
    80006104:	64f2                	ld	s1,280(sp)
    80006106:	6952                	ld	s2,272(sp)
    80006108:	6155                	addi	sp,sp,304
    8000610a:	8082                	ret

000000008000610c <sys_unlink>:
{
    8000610c:	7151                	addi	sp,sp,-240
    8000610e:	f586                	sd	ra,232(sp)
    80006110:	f1a2                	sd	s0,224(sp)
    80006112:	eda6                	sd	s1,216(sp)
    80006114:	e9ca                	sd	s2,208(sp)
    80006116:	e5ce                	sd	s3,200(sp)
    80006118:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000611a:	08000613          	li	a2,128
    8000611e:	f3040593          	addi	a1,s0,-208
    80006122:	4501                	li	a0,0
    80006124:	ffffd097          	auipc	ra,0xffffd
    80006128:	10c080e7          	jalr	268(ra) # 80003230 <argstr>
    8000612c:	18054163          	bltz	a0,800062ae <sys_unlink+0x1a2>
  begin_op();
    80006130:	fffff097          	auipc	ra,0xfffff
    80006134:	bde080e7          	jalr	-1058(ra) # 80004d0e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80006138:	fb040593          	addi	a1,s0,-80
    8000613c:	f3040513          	addi	a0,s0,-208
    80006140:	fffff097          	auipc	ra,0xfffff
    80006144:	9d0080e7          	jalr	-1584(ra) # 80004b10 <nameiparent>
    80006148:	84aa                	mv	s1,a0
    8000614a:	c979                	beqz	a0,80006220 <sys_unlink+0x114>
  ilock(dp);
    8000614c:	ffffe097          	auipc	ra,0xffffe
    80006150:	200080e7          	jalr	512(ra) # 8000434c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80006154:	00003597          	auipc	a1,0x3
    80006158:	75c58593          	addi	a1,a1,1884 # 800098b0 <syscalls+0x2c8>
    8000615c:	fb040513          	addi	a0,s0,-80
    80006160:	ffffe097          	auipc	ra,0xffffe
    80006164:	6b6080e7          	jalr	1718(ra) # 80004816 <namecmp>
    80006168:	14050a63          	beqz	a0,800062bc <sys_unlink+0x1b0>
    8000616c:	00003597          	auipc	a1,0x3
    80006170:	74c58593          	addi	a1,a1,1868 # 800098b8 <syscalls+0x2d0>
    80006174:	fb040513          	addi	a0,s0,-80
    80006178:	ffffe097          	auipc	ra,0xffffe
    8000617c:	69e080e7          	jalr	1694(ra) # 80004816 <namecmp>
    80006180:	12050e63          	beqz	a0,800062bc <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80006184:	f2c40613          	addi	a2,s0,-212
    80006188:	fb040593          	addi	a1,s0,-80
    8000618c:	8526                	mv	a0,s1
    8000618e:	ffffe097          	auipc	ra,0xffffe
    80006192:	6a2080e7          	jalr	1698(ra) # 80004830 <dirlookup>
    80006196:	892a                	mv	s2,a0
    80006198:	12050263          	beqz	a0,800062bc <sys_unlink+0x1b0>
  ilock(ip);
    8000619c:	ffffe097          	auipc	ra,0xffffe
    800061a0:	1b0080e7          	jalr	432(ra) # 8000434c <ilock>
  if(ip->nlink < 1)
    800061a4:	04a91783          	lh	a5,74(s2)
    800061a8:	08f05263          	blez	a5,8000622c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800061ac:	04491703          	lh	a4,68(s2)
    800061b0:	4785                	li	a5,1
    800061b2:	08f70563          	beq	a4,a5,8000623c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800061b6:	4641                	li	a2,16
    800061b8:	4581                	li	a1,0
    800061ba:	fc040513          	addi	a0,s0,-64
    800061be:	ffffb097          	auipc	ra,0xffffb
    800061c2:	b28080e7          	jalr	-1240(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800061c6:	4741                	li	a4,16
    800061c8:	f2c42683          	lw	a3,-212(s0)
    800061cc:	fc040613          	addi	a2,s0,-64
    800061d0:	4581                	li	a1,0
    800061d2:	8526                	mv	a0,s1
    800061d4:	ffffe097          	auipc	ra,0xffffe
    800061d8:	524080e7          	jalr	1316(ra) # 800046f8 <writei>
    800061dc:	47c1                	li	a5,16
    800061de:	0af51563          	bne	a0,a5,80006288 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800061e2:	04491703          	lh	a4,68(s2)
    800061e6:	4785                	li	a5,1
    800061e8:	0af70863          	beq	a4,a5,80006298 <sys_unlink+0x18c>
  iunlockput(dp);
    800061ec:	8526                	mv	a0,s1
    800061ee:	ffffe097          	auipc	ra,0xffffe
    800061f2:	3c0080e7          	jalr	960(ra) # 800045ae <iunlockput>
  ip->nlink--;
    800061f6:	04a95783          	lhu	a5,74(s2)
    800061fa:	37fd                	addiw	a5,a5,-1
    800061fc:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80006200:	854a                	mv	a0,s2
    80006202:	ffffe097          	auipc	ra,0xffffe
    80006206:	080080e7          	jalr	128(ra) # 80004282 <iupdate>
  iunlockput(ip);
    8000620a:	854a                	mv	a0,s2
    8000620c:	ffffe097          	auipc	ra,0xffffe
    80006210:	3a2080e7          	jalr	930(ra) # 800045ae <iunlockput>
  end_op();
    80006214:	fffff097          	auipc	ra,0xfffff
    80006218:	b7a080e7          	jalr	-1158(ra) # 80004d8e <end_op>
  return 0;
    8000621c:	4501                	li	a0,0
    8000621e:	a84d                	j	800062d0 <sys_unlink+0x1c4>
    end_op();
    80006220:	fffff097          	auipc	ra,0xfffff
    80006224:	b6e080e7          	jalr	-1170(ra) # 80004d8e <end_op>
    return -1;
    80006228:	557d                	li	a0,-1
    8000622a:	a05d                	j	800062d0 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000622c:	00003517          	auipc	a0,0x3
    80006230:	69450513          	addi	a0,a0,1684 # 800098c0 <syscalls+0x2d8>
    80006234:	ffffa097          	auipc	ra,0xffffa
    80006238:	310080e7          	jalr	784(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000623c:	04c92703          	lw	a4,76(s2)
    80006240:	02000793          	li	a5,32
    80006244:	f6e7f9e3          	bgeu	a5,a4,800061b6 <sys_unlink+0xaa>
    80006248:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000624c:	4741                	li	a4,16
    8000624e:	86ce                	mv	a3,s3
    80006250:	f1840613          	addi	a2,s0,-232
    80006254:	4581                	li	a1,0
    80006256:	854a                	mv	a0,s2
    80006258:	ffffe097          	auipc	ra,0xffffe
    8000625c:	3a8080e7          	jalr	936(ra) # 80004600 <readi>
    80006260:	47c1                	li	a5,16
    80006262:	00f51b63          	bne	a0,a5,80006278 <sys_unlink+0x16c>
    if(de.inum != 0)
    80006266:	f1845783          	lhu	a5,-232(s0)
    8000626a:	e7a1                	bnez	a5,800062b2 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000626c:	29c1                	addiw	s3,s3,16
    8000626e:	04c92783          	lw	a5,76(s2)
    80006272:	fcf9ede3          	bltu	s3,a5,8000624c <sys_unlink+0x140>
    80006276:	b781                	j	800061b6 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80006278:	00003517          	auipc	a0,0x3
    8000627c:	66050513          	addi	a0,a0,1632 # 800098d8 <syscalls+0x2f0>
    80006280:	ffffa097          	auipc	ra,0xffffa
    80006284:	2c4080e7          	jalr	708(ra) # 80000544 <panic>
    panic("unlink: writei");
    80006288:	00003517          	auipc	a0,0x3
    8000628c:	66850513          	addi	a0,a0,1640 # 800098f0 <syscalls+0x308>
    80006290:	ffffa097          	auipc	ra,0xffffa
    80006294:	2b4080e7          	jalr	692(ra) # 80000544 <panic>
    dp->nlink--;
    80006298:	04a4d783          	lhu	a5,74(s1)
    8000629c:	37fd                	addiw	a5,a5,-1
    8000629e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800062a2:	8526                	mv	a0,s1
    800062a4:	ffffe097          	auipc	ra,0xffffe
    800062a8:	fde080e7          	jalr	-34(ra) # 80004282 <iupdate>
    800062ac:	b781                	j	800061ec <sys_unlink+0xe0>
    return -1;
    800062ae:	557d                	li	a0,-1
    800062b0:	a005                	j	800062d0 <sys_unlink+0x1c4>
    iunlockput(ip);
    800062b2:	854a                	mv	a0,s2
    800062b4:	ffffe097          	auipc	ra,0xffffe
    800062b8:	2fa080e7          	jalr	762(ra) # 800045ae <iunlockput>
  iunlockput(dp);
    800062bc:	8526                	mv	a0,s1
    800062be:	ffffe097          	auipc	ra,0xffffe
    800062c2:	2f0080e7          	jalr	752(ra) # 800045ae <iunlockput>
  end_op();
    800062c6:	fffff097          	auipc	ra,0xfffff
    800062ca:	ac8080e7          	jalr	-1336(ra) # 80004d8e <end_op>
  return -1;
    800062ce:	557d                	li	a0,-1
}
    800062d0:	70ae                	ld	ra,232(sp)
    800062d2:	740e                	ld	s0,224(sp)
    800062d4:	64ee                	ld	s1,216(sp)
    800062d6:	694e                	ld	s2,208(sp)
    800062d8:	69ae                	ld	s3,200(sp)
    800062da:	616d                	addi	sp,sp,240
    800062dc:	8082                	ret

00000000800062de <sys_open>:

uint64
sys_open(void)
{
    800062de:	7131                	addi	sp,sp,-192
    800062e0:	fd06                	sd	ra,184(sp)
    800062e2:	f922                	sd	s0,176(sp)
    800062e4:	f526                	sd	s1,168(sp)
    800062e6:	f14a                	sd	s2,160(sp)
    800062e8:	ed4e                	sd	s3,152(sp)
    800062ea:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800062ec:	f4c40593          	addi	a1,s0,-180
    800062f0:	4505                	li	a0,1
    800062f2:	ffffd097          	auipc	ra,0xffffd
    800062f6:	efe080e7          	jalr	-258(ra) # 800031f0 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800062fa:	08000613          	li	a2,128
    800062fe:	f5040593          	addi	a1,s0,-176
    80006302:	4501                	li	a0,0
    80006304:	ffffd097          	auipc	ra,0xffffd
    80006308:	f2c080e7          	jalr	-212(ra) # 80003230 <argstr>
    8000630c:	87aa                	mv	a5,a0
    return -1;
    8000630e:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80006310:	0a07c963          	bltz	a5,800063c2 <sys_open+0xe4>

  begin_op();
    80006314:	fffff097          	auipc	ra,0xfffff
    80006318:	9fa080e7          	jalr	-1542(ra) # 80004d0e <begin_op>

  if(omode & O_CREATE){
    8000631c:	f4c42783          	lw	a5,-180(s0)
    80006320:	2007f793          	andi	a5,a5,512
    80006324:	cfc5                	beqz	a5,800063dc <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80006326:	4681                	li	a3,0
    80006328:	4601                	li	a2,0
    8000632a:	4589                	li	a1,2
    8000632c:	f5040513          	addi	a0,s0,-176
    80006330:	00000097          	auipc	ra,0x0
    80006334:	974080e7          	jalr	-1676(ra) # 80005ca4 <create>
    80006338:	84aa                	mv	s1,a0
    if(ip == 0){
    8000633a:	c959                	beqz	a0,800063d0 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000633c:	04449703          	lh	a4,68(s1)
    80006340:	478d                	li	a5,3
    80006342:	00f71763          	bne	a4,a5,80006350 <sys_open+0x72>
    80006346:	0464d703          	lhu	a4,70(s1)
    8000634a:	47a5                	li	a5,9
    8000634c:	0ce7ed63          	bltu	a5,a4,80006426 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006350:	fffff097          	auipc	ra,0xfffff
    80006354:	dce080e7          	jalr	-562(ra) # 8000511e <filealloc>
    80006358:	89aa                	mv	s3,a0
    8000635a:	10050363          	beqz	a0,80006460 <sys_open+0x182>
    8000635e:	00000097          	auipc	ra,0x0
    80006362:	904080e7          	jalr	-1788(ra) # 80005c62 <fdalloc>
    80006366:	892a                	mv	s2,a0
    80006368:	0e054763          	bltz	a0,80006456 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000636c:	04449703          	lh	a4,68(s1)
    80006370:	478d                	li	a5,3
    80006372:	0cf70563          	beq	a4,a5,8000643c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80006376:	4789                	li	a5,2
    80006378:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000637c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80006380:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80006384:	f4c42783          	lw	a5,-180(s0)
    80006388:	0017c713          	xori	a4,a5,1
    8000638c:	8b05                	andi	a4,a4,1
    8000638e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80006392:	0037f713          	andi	a4,a5,3
    80006396:	00e03733          	snez	a4,a4
    8000639a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000639e:	4007f793          	andi	a5,a5,1024
    800063a2:	c791                	beqz	a5,800063ae <sys_open+0xd0>
    800063a4:	04449703          	lh	a4,68(s1)
    800063a8:	4789                	li	a5,2
    800063aa:	0af70063          	beq	a4,a5,8000644a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800063ae:	8526                	mv	a0,s1
    800063b0:	ffffe097          	auipc	ra,0xffffe
    800063b4:	05e080e7          	jalr	94(ra) # 8000440e <iunlock>
  end_op();
    800063b8:	fffff097          	auipc	ra,0xfffff
    800063bc:	9d6080e7          	jalr	-1578(ra) # 80004d8e <end_op>

  return fd;
    800063c0:	854a                	mv	a0,s2
}
    800063c2:	70ea                	ld	ra,184(sp)
    800063c4:	744a                	ld	s0,176(sp)
    800063c6:	74aa                	ld	s1,168(sp)
    800063c8:	790a                	ld	s2,160(sp)
    800063ca:	69ea                	ld	s3,152(sp)
    800063cc:	6129                	addi	sp,sp,192
    800063ce:	8082                	ret
      end_op();
    800063d0:	fffff097          	auipc	ra,0xfffff
    800063d4:	9be080e7          	jalr	-1602(ra) # 80004d8e <end_op>
      return -1;
    800063d8:	557d                	li	a0,-1
    800063da:	b7e5                	j	800063c2 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800063dc:	f5040513          	addi	a0,s0,-176
    800063e0:	ffffe097          	auipc	ra,0xffffe
    800063e4:	712080e7          	jalr	1810(ra) # 80004af2 <namei>
    800063e8:	84aa                	mv	s1,a0
    800063ea:	c905                	beqz	a0,8000641a <sys_open+0x13c>
    ilock(ip);
    800063ec:	ffffe097          	auipc	ra,0xffffe
    800063f0:	f60080e7          	jalr	-160(ra) # 8000434c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800063f4:	04449703          	lh	a4,68(s1)
    800063f8:	4785                	li	a5,1
    800063fa:	f4f711e3          	bne	a4,a5,8000633c <sys_open+0x5e>
    800063fe:	f4c42783          	lw	a5,-180(s0)
    80006402:	d7b9                	beqz	a5,80006350 <sys_open+0x72>
      iunlockput(ip);
    80006404:	8526                	mv	a0,s1
    80006406:	ffffe097          	auipc	ra,0xffffe
    8000640a:	1a8080e7          	jalr	424(ra) # 800045ae <iunlockput>
      end_op();
    8000640e:	fffff097          	auipc	ra,0xfffff
    80006412:	980080e7          	jalr	-1664(ra) # 80004d8e <end_op>
      return -1;
    80006416:	557d                	li	a0,-1
    80006418:	b76d                	j	800063c2 <sys_open+0xe4>
      end_op();
    8000641a:	fffff097          	auipc	ra,0xfffff
    8000641e:	974080e7          	jalr	-1676(ra) # 80004d8e <end_op>
      return -1;
    80006422:	557d                	li	a0,-1
    80006424:	bf79                	j	800063c2 <sys_open+0xe4>
    iunlockput(ip);
    80006426:	8526                	mv	a0,s1
    80006428:	ffffe097          	auipc	ra,0xffffe
    8000642c:	186080e7          	jalr	390(ra) # 800045ae <iunlockput>
    end_op();
    80006430:	fffff097          	auipc	ra,0xfffff
    80006434:	95e080e7          	jalr	-1698(ra) # 80004d8e <end_op>
    return -1;
    80006438:	557d                	li	a0,-1
    8000643a:	b761                	j	800063c2 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000643c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006440:	04649783          	lh	a5,70(s1)
    80006444:	02f99223          	sh	a5,36(s3)
    80006448:	bf25                	j	80006380 <sys_open+0xa2>
    itrunc(ip);
    8000644a:	8526                	mv	a0,s1
    8000644c:	ffffe097          	auipc	ra,0xffffe
    80006450:	00e080e7          	jalr	14(ra) # 8000445a <itrunc>
    80006454:	bfa9                	j	800063ae <sys_open+0xd0>
      fileclose(f);
    80006456:	854e                	mv	a0,s3
    80006458:	fffff097          	auipc	ra,0xfffff
    8000645c:	d82080e7          	jalr	-638(ra) # 800051da <fileclose>
    iunlockput(ip);
    80006460:	8526                	mv	a0,s1
    80006462:	ffffe097          	auipc	ra,0xffffe
    80006466:	14c080e7          	jalr	332(ra) # 800045ae <iunlockput>
    end_op();
    8000646a:	fffff097          	auipc	ra,0xfffff
    8000646e:	924080e7          	jalr	-1756(ra) # 80004d8e <end_op>
    return -1;
    80006472:	557d                	li	a0,-1
    80006474:	b7b9                	j	800063c2 <sys_open+0xe4>

0000000080006476 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006476:	7175                	addi	sp,sp,-144
    80006478:	e506                	sd	ra,136(sp)
    8000647a:	e122                	sd	s0,128(sp)
    8000647c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000647e:	fffff097          	auipc	ra,0xfffff
    80006482:	890080e7          	jalr	-1904(ra) # 80004d0e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006486:	08000613          	li	a2,128
    8000648a:	f7040593          	addi	a1,s0,-144
    8000648e:	4501                	li	a0,0
    80006490:	ffffd097          	auipc	ra,0xffffd
    80006494:	da0080e7          	jalr	-608(ra) # 80003230 <argstr>
    80006498:	02054963          	bltz	a0,800064ca <sys_mkdir+0x54>
    8000649c:	4681                	li	a3,0
    8000649e:	4601                	li	a2,0
    800064a0:	4585                	li	a1,1
    800064a2:	f7040513          	addi	a0,s0,-144
    800064a6:	fffff097          	auipc	ra,0xfffff
    800064aa:	7fe080e7          	jalr	2046(ra) # 80005ca4 <create>
    800064ae:	cd11                	beqz	a0,800064ca <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800064b0:	ffffe097          	auipc	ra,0xffffe
    800064b4:	0fe080e7          	jalr	254(ra) # 800045ae <iunlockput>
  end_op();
    800064b8:	fffff097          	auipc	ra,0xfffff
    800064bc:	8d6080e7          	jalr	-1834(ra) # 80004d8e <end_op>
  return 0;
    800064c0:	4501                	li	a0,0
}
    800064c2:	60aa                	ld	ra,136(sp)
    800064c4:	640a                	ld	s0,128(sp)
    800064c6:	6149                	addi	sp,sp,144
    800064c8:	8082                	ret
    end_op();
    800064ca:	fffff097          	auipc	ra,0xfffff
    800064ce:	8c4080e7          	jalr	-1852(ra) # 80004d8e <end_op>
    return -1;
    800064d2:	557d                	li	a0,-1
    800064d4:	b7fd                	j	800064c2 <sys_mkdir+0x4c>

00000000800064d6 <sys_mknod>:

uint64
sys_mknod(void)
{
    800064d6:	7135                	addi	sp,sp,-160
    800064d8:	ed06                	sd	ra,152(sp)
    800064da:	e922                	sd	s0,144(sp)
    800064dc:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800064de:	fffff097          	auipc	ra,0xfffff
    800064e2:	830080e7          	jalr	-2000(ra) # 80004d0e <begin_op>
  argint(1, &major);
    800064e6:	f6c40593          	addi	a1,s0,-148
    800064ea:	4505                	li	a0,1
    800064ec:	ffffd097          	auipc	ra,0xffffd
    800064f0:	d04080e7          	jalr	-764(ra) # 800031f0 <argint>
  argint(2, &minor);
    800064f4:	f6840593          	addi	a1,s0,-152
    800064f8:	4509                	li	a0,2
    800064fa:	ffffd097          	auipc	ra,0xffffd
    800064fe:	cf6080e7          	jalr	-778(ra) # 800031f0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006502:	08000613          	li	a2,128
    80006506:	f7040593          	addi	a1,s0,-144
    8000650a:	4501                	li	a0,0
    8000650c:	ffffd097          	auipc	ra,0xffffd
    80006510:	d24080e7          	jalr	-732(ra) # 80003230 <argstr>
    80006514:	02054b63          	bltz	a0,8000654a <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006518:	f6841683          	lh	a3,-152(s0)
    8000651c:	f6c41603          	lh	a2,-148(s0)
    80006520:	458d                	li	a1,3
    80006522:	f7040513          	addi	a0,s0,-144
    80006526:	fffff097          	auipc	ra,0xfffff
    8000652a:	77e080e7          	jalr	1918(ra) # 80005ca4 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000652e:	cd11                	beqz	a0,8000654a <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006530:	ffffe097          	auipc	ra,0xffffe
    80006534:	07e080e7          	jalr	126(ra) # 800045ae <iunlockput>
  end_op();
    80006538:	fffff097          	auipc	ra,0xfffff
    8000653c:	856080e7          	jalr	-1962(ra) # 80004d8e <end_op>
  return 0;
    80006540:	4501                	li	a0,0
}
    80006542:	60ea                	ld	ra,152(sp)
    80006544:	644a                	ld	s0,144(sp)
    80006546:	610d                	addi	sp,sp,160
    80006548:	8082                	ret
    end_op();
    8000654a:	fffff097          	auipc	ra,0xfffff
    8000654e:	844080e7          	jalr	-1980(ra) # 80004d8e <end_op>
    return -1;
    80006552:	557d                	li	a0,-1
    80006554:	b7fd                	j	80006542 <sys_mknod+0x6c>

0000000080006556 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006556:	7135                	addi	sp,sp,-160
    80006558:	ed06                	sd	ra,152(sp)
    8000655a:	e922                	sd	s0,144(sp)
    8000655c:	e526                	sd	s1,136(sp)
    8000655e:	e14a                	sd	s2,128(sp)
    80006560:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006562:	ffffb097          	auipc	ra,0xffffb
    80006566:	664080e7          	jalr	1636(ra) # 80001bc6 <myproc>
    8000656a:	892a                	mv	s2,a0
  
  begin_op();
    8000656c:	ffffe097          	auipc	ra,0xffffe
    80006570:	7a2080e7          	jalr	1954(ra) # 80004d0e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006574:	08000613          	li	a2,128
    80006578:	f6040593          	addi	a1,s0,-160
    8000657c:	4501                	li	a0,0
    8000657e:	ffffd097          	auipc	ra,0xffffd
    80006582:	cb2080e7          	jalr	-846(ra) # 80003230 <argstr>
    80006586:	04054b63          	bltz	a0,800065dc <sys_chdir+0x86>
    8000658a:	f6040513          	addi	a0,s0,-160
    8000658e:	ffffe097          	auipc	ra,0xffffe
    80006592:	564080e7          	jalr	1380(ra) # 80004af2 <namei>
    80006596:	84aa                	mv	s1,a0
    80006598:	c131                	beqz	a0,800065dc <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000659a:	ffffe097          	auipc	ra,0xffffe
    8000659e:	db2080e7          	jalr	-590(ra) # 8000434c <ilock>
  if(ip->type != T_DIR){
    800065a2:	04449703          	lh	a4,68(s1)
    800065a6:	4785                	li	a5,1
    800065a8:	04f71063          	bne	a4,a5,800065e8 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800065ac:	8526                	mv	a0,s1
    800065ae:	ffffe097          	auipc	ra,0xffffe
    800065b2:	e60080e7          	jalr	-416(ra) # 8000440e <iunlock>
  iput(p->cwd);
    800065b6:	15093503          	ld	a0,336(s2)
    800065ba:	ffffe097          	auipc	ra,0xffffe
    800065be:	f4c080e7          	jalr	-180(ra) # 80004506 <iput>
  end_op();
    800065c2:	ffffe097          	auipc	ra,0xffffe
    800065c6:	7cc080e7          	jalr	1996(ra) # 80004d8e <end_op>
  p->cwd = ip;
    800065ca:	14993823          	sd	s1,336(s2)
  return 0;
    800065ce:	4501                	li	a0,0
}
    800065d0:	60ea                	ld	ra,152(sp)
    800065d2:	644a                	ld	s0,144(sp)
    800065d4:	64aa                	ld	s1,136(sp)
    800065d6:	690a                	ld	s2,128(sp)
    800065d8:	610d                	addi	sp,sp,160
    800065da:	8082                	ret
    end_op();
    800065dc:	ffffe097          	auipc	ra,0xffffe
    800065e0:	7b2080e7          	jalr	1970(ra) # 80004d8e <end_op>
    return -1;
    800065e4:	557d                	li	a0,-1
    800065e6:	b7ed                	j	800065d0 <sys_chdir+0x7a>
    iunlockput(ip);
    800065e8:	8526                	mv	a0,s1
    800065ea:	ffffe097          	auipc	ra,0xffffe
    800065ee:	fc4080e7          	jalr	-60(ra) # 800045ae <iunlockput>
    end_op();
    800065f2:	ffffe097          	auipc	ra,0xffffe
    800065f6:	79c080e7          	jalr	1948(ra) # 80004d8e <end_op>
    return -1;
    800065fa:	557d                	li	a0,-1
    800065fc:	bfd1                	j	800065d0 <sys_chdir+0x7a>

00000000800065fe <sys_exec>:

uint64
sys_exec(void)
{
    800065fe:	7145                	addi	sp,sp,-464
    80006600:	e786                	sd	ra,456(sp)
    80006602:	e3a2                	sd	s0,448(sp)
    80006604:	ff26                	sd	s1,440(sp)
    80006606:	fb4a                	sd	s2,432(sp)
    80006608:	f74e                	sd	s3,424(sp)
    8000660a:	f352                	sd	s4,416(sp)
    8000660c:	ef56                	sd	s5,408(sp)
    8000660e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80006610:	e3840593          	addi	a1,s0,-456
    80006614:	4505                	li	a0,1
    80006616:	ffffd097          	auipc	ra,0xffffd
    8000661a:	bfa080e7          	jalr	-1030(ra) # 80003210 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    8000661e:	08000613          	li	a2,128
    80006622:	f4040593          	addi	a1,s0,-192
    80006626:	4501                	li	a0,0
    80006628:	ffffd097          	auipc	ra,0xffffd
    8000662c:	c08080e7          	jalr	-1016(ra) # 80003230 <argstr>
    80006630:	87aa                	mv	a5,a0
    return -1;
    80006632:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80006634:	0c07c263          	bltz	a5,800066f8 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006638:	10000613          	li	a2,256
    8000663c:	4581                	li	a1,0
    8000663e:	e4040513          	addi	a0,s0,-448
    80006642:	ffffa097          	auipc	ra,0xffffa
    80006646:	6a4080e7          	jalr	1700(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000664a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000664e:	89a6                	mv	s3,s1
    80006650:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006652:	02000a13          	li	s4,32
    80006656:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000665a:	00391513          	slli	a0,s2,0x3
    8000665e:	e3040593          	addi	a1,s0,-464
    80006662:	e3843783          	ld	a5,-456(s0)
    80006666:	953e                	add	a0,a0,a5
    80006668:	ffffd097          	auipc	ra,0xffffd
    8000666c:	aea080e7          	jalr	-1302(ra) # 80003152 <fetchaddr>
    80006670:	02054a63          	bltz	a0,800066a4 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80006674:	e3043783          	ld	a5,-464(s0)
    80006678:	c3b9                	beqz	a5,800066be <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000667a:	ffffa097          	auipc	ra,0xffffa
    8000667e:	480080e7          	jalr	1152(ra) # 80000afa <kalloc>
    80006682:	85aa                	mv	a1,a0
    80006684:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006688:	cd11                	beqz	a0,800066a4 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000668a:	6605                	lui	a2,0x1
    8000668c:	e3043503          	ld	a0,-464(s0)
    80006690:	ffffd097          	auipc	ra,0xffffd
    80006694:	b14080e7          	jalr	-1260(ra) # 800031a4 <fetchstr>
    80006698:	00054663          	bltz	a0,800066a4 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    8000669c:	0905                	addi	s2,s2,1
    8000669e:	09a1                	addi	s3,s3,8
    800066a0:	fb491be3          	bne	s2,s4,80006656 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800066a4:	10048913          	addi	s2,s1,256
    800066a8:	6088                	ld	a0,0(s1)
    800066aa:	c531                	beqz	a0,800066f6 <sys_exec+0xf8>
    kfree(argv[i]);
    800066ac:	ffffa097          	auipc	ra,0xffffa
    800066b0:	352080e7          	jalr	850(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800066b4:	04a1                	addi	s1,s1,8
    800066b6:	ff2499e3          	bne	s1,s2,800066a8 <sys_exec+0xaa>
  return -1;
    800066ba:	557d                	li	a0,-1
    800066bc:	a835                	j	800066f8 <sys_exec+0xfa>
      argv[i] = 0;
    800066be:	0a8e                	slli	s5,s5,0x3
    800066c0:	fc040793          	addi	a5,s0,-64
    800066c4:	9abe                	add	s5,s5,a5
    800066c6:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800066ca:	e4040593          	addi	a1,s0,-448
    800066ce:	f4040513          	addi	a0,s0,-192
    800066d2:	fffff097          	auipc	ra,0xfffff
    800066d6:	190080e7          	jalr	400(ra) # 80005862 <exec>
    800066da:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800066dc:	10048993          	addi	s3,s1,256
    800066e0:	6088                	ld	a0,0(s1)
    800066e2:	c901                	beqz	a0,800066f2 <sys_exec+0xf4>
    kfree(argv[i]);
    800066e4:	ffffa097          	auipc	ra,0xffffa
    800066e8:	31a080e7          	jalr	794(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800066ec:	04a1                	addi	s1,s1,8
    800066ee:	ff3499e3          	bne	s1,s3,800066e0 <sys_exec+0xe2>
  return ret;
    800066f2:	854a                	mv	a0,s2
    800066f4:	a011                	j	800066f8 <sys_exec+0xfa>
  return -1;
    800066f6:	557d                	li	a0,-1
}
    800066f8:	60be                	ld	ra,456(sp)
    800066fa:	641e                	ld	s0,448(sp)
    800066fc:	74fa                	ld	s1,440(sp)
    800066fe:	795a                	ld	s2,432(sp)
    80006700:	79ba                	ld	s3,424(sp)
    80006702:	7a1a                	ld	s4,416(sp)
    80006704:	6afa                	ld	s5,408(sp)
    80006706:	6179                	addi	sp,sp,464
    80006708:	8082                	ret

000000008000670a <sys_pipe>:

uint64
sys_pipe(void)
{
    8000670a:	7139                	addi	sp,sp,-64
    8000670c:	fc06                	sd	ra,56(sp)
    8000670e:	f822                	sd	s0,48(sp)
    80006710:	f426                	sd	s1,40(sp)
    80006712:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006714:	ffffb097          	auipc	ra,0xffffb
    80006718:	4b2080e7          	jalr	1202(ra) # 80001bc6 <myproc>
    8000671c:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    8000671e:	fd840593          	addi	a1,s0,-40
    80006722:	4501                	li	a0,0
    80006724:	ffffd097          	auipc	ra,0xffffd
    80006728:	aec080e7          	jalr	-1300(ra) # 80003210 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    8000672c:	fc840593          	addi	a1,s0,-56
    80006730:	fd040513          	addi	a0,s0,-48
    80006734:	fffff097          	auipc	ra,0xfffff
    80006738:	dd6080e7          	jalr	-554(ra) # 8000550a <pipealloc>
    return -1;
    8000673c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000673e:	0c054463          	bltz	a0,80006806 <sys_pipe+0xfc>
  fd0 = -1;
    80006742:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006746:	fd043503          	ld	a0,-48(s0)
    8000674a:	fffff097          	auipc	ra,0xfffff
    8000674e:	518080e7          	jalr	1304(ra) # 80005c62 <fdalloc>
    80006752:	fca42223          	sw	a0,-60(s0)
    80006756:	08054b63          	bltz	a0,800067ec <sys_pipe+0xe2>
    8000675a:	fc843503          	ld	a0,-56(s0)
    8000675e:	fffff097          	auipc	ra,0xfffff
    80006762:	504080e7          	jalr	1284(ra) # 80005c62 <fdalloc>
    80006766:	fca42023          	sw	a0,-64(s0)
    8000676a:	06054863          	bltz	a0,800067da <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000676e:	4691                	li	a3,4
    80006770:	fc440613          	addi	a2,s0,-60
    80006774:	fd843583          	ld	a1,-40(s0)
    80006778:	68a8                	ld	a0,80(s1)
    8000677a:	ffffb097          	auipc	ra,0xffffb
    8000677e:	f0a080e7          	jalr	-246(ra) # 80001684 <copyout>
    80006782:	02054063          	bltz	a0,800067a2 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006786:	4691                	li	a3,4
    80006788:	fc040613          	addi	a2,s0,-64
    8000678c:	fd843583          	ld	a1,-40(s0)
    80006790:	0591                	addi	a1,a1,4
    80006792:	68a8                	ld	a0,80(s1)
    80006794:	ffffb097          	auipc	ra,0xffffb
    80006798:	ef0080e7          	jalr	-272(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000679c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000679e:	06055463          	bgez	a0,80006806 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    800067a2:	fc442783          	lw	a5,-60(s0)
    800067a6:	07e9                	addi	a5,a5,26
    800067a8:	078e                	slli	a5,a5,0x3
    800067aa:	97a6                	add	a5,a5,s1
    800067ac:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800067b0:	fc042503          	lw	a0,-64(s0)
    800067b4:	0569                	addi	a0,a0,26
    800067b6:	050e                	slli	a0,a0,0x3
    800067b8:	94aa                	add	s1,s1,a0
    800067ba:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800067be:	fd043503          	ld	a0,-48(s0)
    800067c2:	fffff097          	auipc	ra,0xfffff
    800067c6:	a18080e7          	jalr	-1512(ra) # 800051da <fileclose>
    fileclose(wf);
    800067ca:	fc843503          	ld	a0,-56(s0)
    800067ce:	fffff097          	auipc	ra,0xfffff
    800067d2:	a0c080e7          	jalr	-1524(ra) # 800051da <fileclose>
    return -1;
    800067d6:	57fd                	li	a5,-1
    800067d8:	a03d                	j	80006806 <sys_pipe+0xfc>
    if(fd0 >= 0)
    800067da:	fc442783          	lw	a5,-60(s0)
    800067de:	0007c763          	bltz	a5,800067ec <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    800067e2:	07e9                	addi	a5,a5,26
    800067e4:	078e                	slli	a5,a5,0x3
    800067e6:	94be                	add	s1,s1,a5
    800067e8:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800067ec:	fd043503          	ld	a0,-48(s0)
    800067f0:	fffff097          	auipc	ra,0xfffff
    800067f4:	9ea080e7          	jalr	-1558(ra) # 800051da <fileclose>
    fileclose(wf);
    800067f8:	fc843503          	ld	a0,-56(s0)
    800067fc:	fffff097          	auipc	ra,0xfffff
    80006800:	9de080e7          	jalr	-1570(ra) # 800051da <fileclose>
    return -1;
    80006804:	57fd                	li	a5,-1
}
    80006806:	853e                	mv	a0,a5
    80006808:	70e2                	ld	ra,56(sp)
    8000680a:	7442                	ld	s0,48(sp)
    8000680c:	74a2                	ld	s1,40(sp)
    8000680e:	6121                	addi	sp,sp,64
    80006810:	8082                	ret
	...

0000000080006820 <kernelvec>:
    80006820:	7111                	addi	sp,sp,-256
    80006822:	e006                	sd	ra,0(sp)
    80006824:	e40a                	sd	sp,8(sp)
    80006826:	e80e                	sd	gp,16(sp)
    80006828:	ec12                	sd	tp,24(sp)
    8000682a:	f016                	sd	t0,32(sp)
    8000682c:	f41a                	sd	t1,40(sp)
    8000682e:	f81e                	sd	t2,48(sp)
    80006830:	fc22                	sd	s0,56(sp)
    80006832:	e0a6                	sd	s1,64(sp)
    80006834:	e4aa                	sd	a0,72(sp)
    80006836:	e8ae                	sd	a1,80(sp)
    80006838:	ecb2                	sd	a2,88(sp)
    8000683a:	f0b6                	sd	a3,96(sp)
    8000683c:	f4ba                	sd	a4,104(sp)
    8000683e:	f8be                	sd	a5,112(sp)
    80006840:	fcc2                	sd	a6,120(sp)
    80006842:	e146                	sd	a7,128(sp)
    80006844:	e54a                	sd	s2,136(sp)
    80006846:	e94e                	sd	s3,144(sp)
    80006848:	ed52                	sd	s4,152(sp)
    8000684a:	f156                	sd	s5,160(sp)
    8000684c:	f55a                	sd	s6,168(sp)
    8000684e:	f95e                	sd	s7,176(sp)
    80006850:	fd62                	sd	s8,184(sp)
    80006852:	e1e6                	sd	s9,192(sp)
    80006854:	e5ea                	sd	s10,200(sp)
    80006856:	e9ee                	sd	s11,208(sp)
    80006858:	edf2                	sd	t3,216(sp)
    8000685a:	f1f6                	sd	t4,224(sp)
    8000685c:	f5fa                	sd	t5,232(sp)
    8000685e:	f9fe                	sd	t6,240(sp)
    80006860:	f54fc0ef          	jal	ra,80002fb4 <kerneltrap>
    80006864:	6082                	ld	ra,0(sp)
    80006866:	6122                	ld	sp,8(sp)
    80006868:	61c2                	ld	gp,16(sp)
    8000686a:	7282                	ld	t0,32(sp)
    8000686c:	7322                	ld	t1,40(sp)
    8000686e:	73c2                	ld	t2,48(sp)
    80006870:	7462                	ld	s0,56(sp)
    80006872:	6486                	ld	s1,64(sp)
    80006874:	6526                	ld	a0,72(sp)
    80006876:	65c6                	ld	a1,80(sp)
    80006878:	6666                	ld	a2,88(sp)
    8000687a:	7686                	ld	a3,96(sp)
    8000687c:	7726                	ld	a4,104(sp)
    8000687e:	77c6                	ld	a5,112(sp)
    80006880:	7866                	ld	a6,120(sp)
    80006882:	688a                	ld	a7,128(sp)
    80006884:	692a                	ld	s2,136(sp)
    80006886:	69ca                	ld	s3,144(sp)
    80006888:	6a6a                	ld	s4,152(sp)
    8000688a:	7a8a                	ld	s5,160(sp)
    8000688c:	7b2a                	ld	s6,168(sp)
    8000688e:	7bca                	ld	s7,176(sp)
    80006890:	7c6a                	ld	s8,184(sp)
    80006892:	6c8e                	ld	s9,192(sp)
    80006894:	6d2e                	ld	s10,200(sp)
    80006896:	6dce                	ld	s11,208(sp)
    80006898:	6e6e                	ld	t3,216(sp)
    8000689a:	7e8e                	ld	t4,224(sp)
    8000689c:	7f2e                	ld	t5,232(sp)
    8000689e:	7fce                	ld	t6,240(sp)
    800068a0:	6111                	addi	sp,sp,256
    800068a2:	10200073          	sret
    800068a6:	00000013          	nop
    800068aa:	00000013          	nop
    800068ae:	0001                	nop

00000000800068b0 <timervec>:
    800068b0:	34051573          	csrrw	a0,mscratch,a0
    800068b4:	e10c                	sd	a1,0(a0)
    800068b6:	e510                	sd	a2,8(a0)
    800068b8:	e914                	sd	a3,16(a0)
    800068ba:	6d0c                	ld	a1,24(a0)
    800068bc:	7110                	ld	a2,32(a0)
    800068be:	6194                	ld	a3,0(a1)
    800068c0:	96b2                	add	a3,a3,a2
    800068c2:	e194                	sd	a3,0(a1)
    800068c4:	4589                	li	a1,2
    800068c6:	14459073          	csrw	sip,a1
    800068ca:	6914                	ld	a3,16(a0)
    800068cc:	6510                	ld	a2,8(a0)
    800068ce:	610c                	ld	a1,0(a0)
    800068d0:	34051573          	csrrw	a0,mscratch,a0
    800068d4:	30200073          	mret
	...

00000000800068da <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800068da:	1141                	addi	sp,sp,-16
    800068dc:	e422                	sd	s0,8(sp)
    800068de:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800068e0:	0c0007b7          	lui	a5,0xc000
    800068e4:	4705                	li	a4,1
    800068e6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800068e8:	c3d8                	sw	a4,4(a5)
}
    800068ea:	6422                	ld	s0,8(sp)
    800068ec:	0141                	addi	sp,sp,16
    800068ee:	8082                	ret

00000000800068f0 <plicinithart>:

void
plicinithart(void)
{
    800068f0:	1141                	addi	sp,sp,-16
    800068f2:	e406                	sd	ra,8(sp)
    800068f4:	e022                	sd	s0,0(sp)
    800068f6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800068f8:	ffffb097          	auipc	ra,0xffffb
    800068fc:	2a2080e7          	jalr	674(ra) # 80001b9a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006900:	0085171b          	slliw	a4,a0,0x8
    80006904:	0c0027b7          	lui	a5,0xc002
    80006908:	97ba                	add	a5,a5,a4
    8000690a:	40200713          	li	a4,1026
    8000690e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006912:	00d5151b          	slliw	a0,a0,0xd
    80006916:	0c2017b7          	lui	a5,0xc201
    8000691a:	953e                	add	a0,a0,a5
    8000691c:	00052023          	sw	zero,0(a0)
}
    80006920:	60a2                	ld	ra,8(sp)
    80006922:	6402                	ld	s0,0(sp)
    80006924:	0141                	addi	sp,sp,16
    80006926:	8082                	ret

0000000080006928 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006928:	1141                	addi	sp,sp,-16
    8000692a:	e406                	sd	ra,8(sp)
    8000692c:	e022                	sd	s0,0(sp)
    8000692e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006930:	ffffb097          	auipc	ra,0xffffb
    80006934:	26a080e7          	jalr	618(ra) # 80001b9a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006938:	00d5179b          	slliw	a5,a0,0xd
    8000693c:	0c201537          	lui	a0,0xc201
    80006940:	953e                	add	a0,a0,a5
  return irq;
}
    80006942:	4148                	lw	a0,4(a0)
    80006944:	60a2                	ld	ra,8(sp)
    80006946:	6402                	ld	s0,0(sp)
    80006948:	0141                	addi	sp,sp,16
    8000694a:	8082                	ret

000000008000694c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000694c:	1101                	addi	sp,sp,-32
    8000694e:	ec06                	sd	ra,24(sp)
    80006950:	e822                	sd	s0,16(sp)
    80006952:	e426                	sd	s1,8(sp)
    80006954:	1000                	addi	s0,sp,32
    80006956:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006958:	ffffb097          	auipc	ra,0xffffb
    8000695c:	242080e7          	jalr	578(ra) # 80001b9a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006960:	00d5151b          	slliw	a0,a0,0xd
    80006964:	0c2017b7          	lui	a5,0xc201
    80006968:	97aa                	add	a5,a5,a0
    8000696a:	c3c4                	sw	s1,4(a5)
}
    8000696c:	60e2                	ld	ra,24(sp)
    8000696e:	6442                	ld	s0,16(sp)
    80006970:	64a2                	ld	s1,8(sp)
    80006972:	6105                	addi	sp,sp,32
    80006974:	8082                	ret

0000000080006976 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006976:	1141                	addi	sp,sp,-16
    80006978:	e406                	sd	ra,8(sp)
    8000697a:	e022                	sd	s0,0(sp)
    8000697c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000697e:	479d                	li	a5,7
    80006980:	04a7cc63          	blt	a5,a0,800069d8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006984:	0001e797          	auipc	a5,0x1e
    80006988:	7d478793          	addi	a5,a5,2004 # 80025158 <disk>
    8000698c:	97aa                	add	a5,a5,a0
    8000698e:	0187c783          	lbu	a5,24(a5)
    80006992:	ebb9                	bnez	a5,800069e8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006994:	00451613          	slli	a2,a0,0x4
    80006998:	0001e797          	auipc	a5,0x1e
    8000699c:	7c078793          	addi	a5,a5,1984 # 80025158 <disk>
    800069a0:	6394                	ld	a3,0(a5)
    800069a2:	96b2                	add	a3,a3,a2
    800069a4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800069a8:	6398                	ld	a4,0(a5)
    800069aa:	9732                	add	a4,a4,a2
    800069ac:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800069b0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800069b4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800069b8:	953e                	add	a0,a0,a5
    800069ba:	4785                	li	a5,1
    800069bc:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    800069c0:	0001e517          	auipc	a0,0x1e
    800069c4:	7b050513          	addi	a0,a0,1968 # 80025170 <disk+0x18>
    800069c8:	ffffc097          	auipc	ra,0xffffc
    800069cc:	c4a080e7          	jalr	-950(ra) # 80002612 <wakeup>
}
    800069d0:	60a2                	ld	ra,8(sp)
    800069d2:	6402                	ld	s0,0(sp)
    800069d4:	0141                	addi	sp,sp,16
    800069d6:	8082                	ret
    panic("free_desc 1");
    800069d8:	00003517          	auipc	a0,0x3
    800069dc:	f2850513          	addi	a0,a0,-216 # 80009900 <syscalls+0x318>
    800069e0:	ffffa097          	auipc	ra,0xffffa
    800069e4:	b64080e7          	jalr	-1180(ra) # 80000544 <panic>
    panic("free_desc 2");
    800069e8:	00003517          	auipc	a0,0x3
    800069ec:	f2850513          	addi	a0,a0,-216 # 80009910 <syscalls+0x328>
    800069f0:	ffffa097          	auipc	ra,0xffffa
    800069f4:	b54080e7          	jalr	-1196(ra) # 80000544 <panic>

00000000800069f8 <virtio_disk_init>:
{
    800069f8:	1101                	addi	sp,sp,-32
    800069fa:	ec06                	sd	ra,24(sp)
    800069fc:	e822                	sd	s0,16(sp)
    800069fe:	e426                	sd	s1,8(sp)
    80006a00:	e04a                	sd	s2,0(sp)
    80006a02:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006a04:	00003597          	auipc	a1,0x3
    80006a08:	f1c58593          	addi	a1,a1,-228 # 80009920 <syscalls+0x338>
    80006a0c:	0001f517          	auipc	a0,0x1f
    80006a10:	87450513          	addi	a0,a0,-1932 # 80025280 <disk+0x128>
    80006a14:	ffffa097          	auipc	ra,0xffffa
    80006a18:	146080e7          	jalr	326(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006a1c:	100017b7          	lui	a5,0x10001
    80006a20:	4398                	lw	a4,0(a5)
    80006a22:	2701                	sext.w	a4,a4
    80006a24:	747277b7          	lui	a5,0x74727
    80006a28:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006a2c:	14f71e63          	bne	a4,a5,80006b88 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006a30:	100017b7          	lui	a5,0x10001
    80006a34:	43dc                	lw	a5,4(a5)
    80006a36:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006a38:	4709                	li	a4,2
    80006a3a:	14e79763          	bne	a5,a4,80006b88 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006a3e:	100017b7          	lui	a5,0x10001
    80006a42:	479c                	lw	a5,8(a5)
    80006a44:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006a46:	14e79163          	bne	a5,a4,80006b88 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006a4a:	100017b7          	lui	a5,0x10001
    80006a4e:	47d8                	lw	a4,12(a5)
    80006a50:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006a52:	554d47b7          	lui	a5,0x554d4
    80006a56:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006a5a:	12f71763          	bne	a4,a5,80006b88 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a5e:	100017b7          	lui	a5,0x10001
    80006a62:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a66:	4705                	li	a4,1
    80006a68:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a6a:	470d                	li	a4,3
    80006a6c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006a6e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006a70:	c7ffe737          	lui	a4,0xc7ffe
    80006a74:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd8147>
    80006a78:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006a7a:	2701                	sext.w	a4,a4
    80006a7c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a7e:	472d                	li	a4,11
    80006a80:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006a82:	0707a903          	lw	s2,112(a5)
    80006a86:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006a88:	00897793          	andi	a5,s2,8
    80006a8c:	10078663          	beqz	a5,80006b98 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006a90:	100017b7          	lui	a5,0x10001
    80006a94:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006a98:	43fc                	lw	a5,68(a5)
    80006a9a:	2781                	sext.w	a5,a5
    80006a9c:	10079663          	bnez	a5,80006ba8 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006aa0:	100017b7          	lui	a5,0x10001
    80006aa4:	5bdc                	lw	a5,52(a5)
    80006aa6:	2781                	sext.w	a5,a5
  if(max == 0)
    80006aa8:	10078863          	beqz	a5,80006bb8 <virtio_disk_init+0x1c0>
  if(max < NUM)
    80006aac:	471d                	li	a4,7
    80006aae:	10f77d63          	bgeu	a4,a5,80006bc8 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80006ab2:	ffffa097          	auipc	ra,0xffffa
    80006ab6:	048080e7          	jalr	72(ra) # 80000afa <kalloc>
    80006aba:	0001e497          	auipc	s1,0x1e
    80006abe:	69e48493          	addi	s1,s1,1694 # 80025158 <disk>
    80006ac2:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006ac4:	ffffa097          	auipc	ra,0xffffa
    80006ac8:	036080e7          	jalr	54(ra) # 80000afa <kalloc>
    80006acc:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80006ace:	ffffa097          	auipc	ra,0xffffa
    80006ad2:	02c080e7          	jalr	44(ra) # 80000afa <kalloc>
    80006ad6:	87aa                	mv	a5,a0
    80006ad8:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006ada:	6088                	ld	a0,0(s1)
    80006adc:	cd75                	beqz	a0,80006bd8 <virtio_disk_init+0x1e0>
    80006ade:	0001e717          	auipc	a4,0x1e
    80006ae2:	68273703          	ld	a4,1666(a4) # 80025160 <disk+0x8>
    80006ae6:	cb6d                	beqz	a4,80006bd8 <virtio_disk_init+0x1e0>
    80006ae8:	cbe5                	beqz	a5,80006bd8 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    80006aea:	6605                	lui	a2,0x1
    80006aec:	4581                	li	a1,0
    80006aee:	ffffa097          	auipc	ra,0xffffa
    80006af2:	1f8080e7          	jalr	504(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006af6:	0001e497          	auipc	s1,0x1e
    80006afa:	66248493          	addi	s1,s1,1634 # 80025158 <disk>
    80006afe:	6605                	lui	a2,0x1
    80006b00:	4581                	li	a1,0
    80006b02:	6488                	ld	a0,8(s1)
    80006b04:	ffffa097          	auipc	ra,0xffffa
    80006b08:	1e2080e7          	jalr	482(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    80006b0c:	6605                	lui	a2,0x1
    80006b0e:	4581                	li	a1,0
    80006b10:	6888                	ld	a0,16(s1)
    80006b12:	ffffa097          	auipc	ra,0xffffa
    80006b16:	1d4080e7          	jalr	468(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006b1a:	100017b7          	lui	a5,0x10001
    80006b1e:	4721                	li	a4,8
    80006b20:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006b22:	4098                	lw	a4,0(s1)
    80006b24:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006b28:	40d8                	lw	a4,4(s1)
    80006b2a:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80006b2e:	6498                	ld	a4,8(s1)
    80006b30:	0007069b          	sext.w	a3,a4
    80006b34:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006b38:	9701                	srai	a4,a4,0x20
    80006b3a:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80006b3e:	6898                	ld	a4,16(s1)
    80006b40:	0007069b          	sext.w	a3,a4
    80006b44:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006b48:	9701                	srai	a4,a4,0x20
    80006b4a:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80006b4e:	4685                	li	a3,1
    80006b50:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80006b52:	4705                	li	a4,1
    80006b54:	00d48c23          	sb	a3,24(s1)
    80006b58:	00e48ca3          	sb	a4,25(s1)
    80006b5c:	00e48d23          	sb	a4,26(s1)
    80006b60:	00e48da3          	sb	a4,27(s1)
    80006b64:	00e48e23          	sb	a4,28(s1)
    80006b68:	00e48ea3          	sb	a4,29(s1)
    80006b6c:	00e48f23          	sb	a4,30(s1)
    80006b70:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006b74:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006b78:	0727a823          	sw	s2,112(a5)
}
    80006b7c:	60e2                	ld	ra,24(sp)
    80006b7e:	6442                	ld	s0,16(sp)
    80006b80:	64a2                	ld	s1,8(sp)
    80006b82:	6902                	ld	s2,0(sp)
    80006b84:	6105                	addi	sp,sp,32
    80006b86:	8082                	ret
    panic("could not find virtio disk");
    80006b88:	00003517          	auipc	a0,0x3
    80006b8c:	da850513          	addi	a0,a0,-600 # 80009930 <syscalls+0x348>
    80006b90:	ffffa097          	auipc	ra,0xffffa
    80006b94:	9b4080e7          	jalr	-1612(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006b98:	00003517          	auipc	a0,0x3
    80006b9c:	db850513          	addi	a0,a0,-584 # 80009950 <syscalls+0x368>
    80006ba0:	ffffa097          	auipc	ra,0xffffa
    80006ba4:	9a4080e7          	jalr	-1628(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80006ba8:	00003517          	auipc	a0,0x3
    80006bac:	dc850513          	addi	a0,a0,-568 # 80009970 <syscalls+0x388>
    80006bb0:	ffffa097          	auipc	ra,0xffffa
    80006bb4:	994080e7          	jalr	-1644(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80006bb8:	00003517          	auipc	a0,0x3
    80006bbc:	dd850513          	addi	a0,a0,-552 # 80009990 <syscalls+0x3a8>
    80006bc0:	ffffa097          	auipc	ra,0xffffa
    80006bc4:	984080e7          	jalr	-1660(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    80006bc8:	00003517          	auipc	a0,0x3
    80006bcc:	de850513          	addi	a0,a0,-536 # 800099b0 <syscalls+0x3c8>
    80006bd0:	ffffa097          	auipc	ra,0xffffa
    80006bd4:	974080e7          	jalr	-1676(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    80006bd8:	00003517          	auipc	a0,0x3
    80006bdc:	df850513          	addi	a0,a0,-520 # 800099d0 <syscalls+0x3e8>
    80006be0:	ffffa097          	auipc	ra,0xffffa
    80006be4:	964080e7          	jalr	-1692(ra) # 80000544 <panic>

0000000080006be8 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006be8:	7159                	addi	sp,sp,-112
    80006bea:	f486                	sd	ra,104(sp)
    80006bec:	f0a2                	sd	s0,96(sp)
    80006bee:	eca6                	sd	s1,88(sp)
    80006bf0:	e8ca                	sd	s2,80(sp)
    80006bf2:	e4ce                	sd	s3,72(sp)
    80006bf4:	e0d2                	sd	s4,64(sp)
    80006bf6:	fc56                	sd	s5,56(sp)
    80006bf8:	f85a                	sd	s6,48(sp)
    80006bfa:	f45e                	sd	s7,40(sp)
    80006bfc:	f062                	sd	s8,32(sp)
    80006bfe:	ec66                	sd	s9,24(sp)
    80006c00:	e86a                	sd	s10,16(sp)
    80006c02:	1880                	addi	s0,sp,112
    80006c04:	892a                	mv	s2,a0
    80006c06:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006c08:	00c52c83          	lw	s9,12(a0)
    80006c0c:	001c9c9b          	slliw	s9,s9,0x1
    80006c10:	1c82                	slli	s9,s9,0x20
    80006c12:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006c16:	0001e517          	auipc	a0,0x1e
    80006c1a:	66a50513          	addi	a0,a0,1642 # 80025280 <disk+0x128>
    80006c1e:	ffffa097          	auipc	ra,0xffffa
    80006c22:	fcc080e7          	jalr	-52(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    80006c26:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006c28:	4ba1                	li	s7,8
      disk.free[i] = 0;
    80006c2a:	0001eb17          	auipc	s6,0x1e
    80006c2e:	52eb0b13          	addi	s6,s6,1326 # 80025158 <disk>
  for(int i = 0; i < 3; i++){
    80006c32:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006c34:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006c36:	0001ec17          	auipc	s8,0x1e
    80006c3a:	64ac0c13          	addi	s8,s8,1610 # 80025280 <disk+0x128>
    80006c3e:	a8b5                	j	80006cba <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    80006c40:	00fb06b3          	add	a3,s6,a5
    80006c44:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006c48:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006c4a:	0207c563          	bltz	a5,80006c74 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006c4e:	2485                	addiw	s1,s1,1
    80006c50:	0711                	addi	a4,a4,4
    80006c52:	1f548a63          	beq	s1,s5,80006e46 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    80006c56:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006c58:	0001e697          	auipc	a3,0x1e
    80006c5c:	50068693          	addi	a3,a3,1280 # 80025158 <disk>
    80006c60:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006c62:	0186c583          	lbu	a1,24(a3)
    80006c66:	fde9                	bnez	a1,80006c40 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006c68:	2785                	addiw	a5,a5,1
    80006c6a:	0685                	addi	a3,a3,1
    80006c6c:	ff779be3          	bne	a5,s7,80006c62 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006c70:	57fd                	li	a5,-1
    80006c72:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006c74:	02905a63          	blez	s1,80006ca8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006c78:	f9042503          	lw	a0,-112(s0)
    80006c7c:	00000097          	auipc	ra,0x0
    80006c80:	cfa080e7          	jalr	-774(ra) # 80006976 <free_desc>
      for(int j = 0; j < i; j++)
    80006c84:	4785                	li	a5,1
    80006c86:	0297d163          	bge	a5,s1,80006ca8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006c8a:	f9442503          	lw	a0,-108(s0)
    80006c8e:	00000097          	auipc	ra,0x0
    80006c92:	ce8080e7          	jalr	-792(ra) # 80006976 <free_desc>
      for(int j = 0; j < i; j++)
    80006c96:	4789                	li	a5,2
    80006c98:	0097d863          	bge	a5,s1,80006ca8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006c9c:	f9842503          	lw	a0,-104(s0)
    80006ca0:	00000097          	auipc	ra,0x0
    80006ca4:	cd6080e7          	jalr	-810(ra) # 80006976 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006ca8:	85e2                	mv	a1,s8
    80006caa:	0001e517          	auipc	a0,0x1e
    80006cae:	4c650513          	addi	a0,a0,1222 # 80025170 <disk+0x18>
    80006cb2:	ffffb097          	auipc	ra,0xffffb
    80006cb6:	7b0080e7          	jalr	1968(ra) # 80002462 <sleep>
  for(int i = 0; i < 3; i++){
    80006cba:	f9040713          	addi	a4,s0,-112
    80006cbe:	84ce                	mv	s1,s3
    80006cc0:	bf59                	j	80006c56 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006cc2:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    80006cc6:	00479693          	slli	a3,a5,0x4
    80006cca:	0001e797          	auipc	a5,0x1e
    80006cce:	48e78793          	addi	a5,a5,1166 # 80025158 <disk>
    80006cd2:	97b6                	add	a5,a5,a3
    80006cd4:	4685                	li	a3,1
    80006cd6:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006cd8:	0001e597          	auipc	a1,0x1e
    80006cdc:	48058593          	addi	a1,a1,1152 # 80025158 <disk>
    80006ce0:	00a60793          	addi	a5,a2,10
    80006ce4:	0792                	slli	a5,a5,0x4
    80006ce6:	97ae                	add	a5,a5,a1
    80006ce8:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    80006cec:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006cf0:	f6070693          	addi	a3,a4,-160
    80006cf4:	619c                	ld	a5,0(a1)
    80006cf6:	97b6                	add	a5,a5,a3
    80006cf8:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006cfa:	6188                	ld	a0,0(a1)
    80006cfc:	96aa                	add	a3,a3,a0
    80006cfe:	47c1                	li	a5,16
    80006d00:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006d02:	4785                	li	a5,1
    80006d04:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006d08:	f9442783          	lw	a5,-108(s0)
    80006d0c:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006d10:	0792                	slli	a5,a5,0x4
    80006d12:	953e                	add	a0,a0,a5
    80006d14:	05890693          	addi	a3,s2,88
    80006d18:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    80006d1a:	6188                	ld	a0,0(a1)
    80006d1c:	97aa                	add	a5,a5,a0
    80006d1e:	40000693          	li	a3,1024
    80006d22:	c794                	sw	a3,8(a5)
  if(write)
    80006d24:	100d0d63          	beqz	s10,80006e3e <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006d28:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006d2c:	00c7d683          	lhu	a3,12(a5)
    80006d30:	0016e693          	ori	a3,a3,1
    80006d34:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    80006d38:	f9842583          	lw	a1,-104(s0)
    80006d3c:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006d40:	0001e697          	auipc	a3,0x1e
    80006d44:	41868693          	addi	a3,a3,1048 # 80025158 <disk>
    80006d48:	00260793          	addi	a5,a2,2
    80006d4c:	0792                	slli	a5,a5,0x4
    80006d4e:	97b6                	add	a5,a5,a3
    80006d50:	587d                	li	a6,-1
    80006d52:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006d56:	0592                	slli	a1,a1,0x4
    80006d58:	952e                	add	a0,a0,a1
    80006d5a:	f9070713          	addi	a4,a4,-112
    80006d5e:	9736                	add	a4,a4,a3
    80006d60:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    80006d62:	6298                	ld	a4,0(a3)
    80006d64:	972e                	add	a4,a4,a1
    80006d66:	4585                	li	a1,1
    80006d68:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006d6a:	4509                	li	a0,2
    80006d6c:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    80006d70:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006d74:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006d78:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006d7c:	6698                	ld	a4,8(a3)
    80006d7e:	00275783          	lhu	a5,2(a4)
    80006d82:	8b9d                	andi	a5,a5,7
    80006d84:	0786                	slli	a5,a5,0x1
    80006d86:	97ba                	add	a5,a5,a4
    80006d88:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    80006d8c:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006d90:	6698                	ld	a4,8(a3)
    80006d92:	00275783          	lhu	a5,2(a4)
    80006d96:	2785                	addiw	a5,a5,1
    80006d98:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006d9c:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006da0:	100017b7          	lui	a5,0x10001
    80006da4:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006da8:	00492703          	lw	a4,4(s2)
    80006dac:	4785                	li	a5,1
    80006dae:	02f71163          	bne	a4,a5,80006dd0 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    80006db2:	0001e997          	auipc	s3,0x1e
    80006db6:	4ce98993          	addi	s3,s3,1230 # 80025280 <disk+0x128>
  while(b->disk == 1) {
    80006dba:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006dbc:	85ce                	mv	a1,s3
    80006dbe:	854a                	mv	a0,s2
    80006dc0:	ffffb097          	auipc	ra,0xffffb
    80006dc4:	6a2080e7          	jalr	1698(ra) # 80002462 <sleep>
  while(b->disk == 1) {
    80006dc8:	00492783          	lw	a5,4(s2)
    80006dcc:	fe9788e3          	beq	a5,s1,80006dbc <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    80006dd0:	f9042903          	lw	s2,-112(s0)
    80006dd4:	00290793          	addi	a5,s2,2
    80006dd8:	00479713          	slli	a4,a5,0x4
    80006ddc:	0001e797          	auipc	a5,0x1e
    80006de0:	37c78793          	addi	a5,a5,892 # 80025158 <disk>
    80006de4:	97ba                	add	a5,a5,a4
    80006de6:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006dea:	0001e997          	auipc	s3,0x1e
    80006dee:	36e98993          	addi	s3,s3,878 # 80025158 <disk>
    80006df2:	00491713          	slli	a4,s2,0x4
    80006df6:	0009b783          	ld	a5,0(s3)
    80006dfa:	97ba                	add	a5,a5,a4
    80006dfc:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006e00:	854a                	mv	a0,s2
    80006e02:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006e06:	00000097          	auipc	ra,0x0
    80006e0a:	b70080e7          	jalr	-1168(ra) # 80006976 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006e0e:	8885                	andi	s1,s1,1
    80006e10:	f0ed                	bnez	s1,80006df2 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006e12:	0001e517          	auipc	a0,0x1e
    80006e16:	46e50513          	addi	a0,a0,1134 # 80025280 <disk+0x128>
    80006e1a:	ffffa097          	auipc	ra,0xffffa
    80006e1e:	e84080e7          	jalr	-380(ra) # 80000c9e <release>
}
    80006e22:	70a6                	ld	ra,104(sp)
    80006e24:	7406                	ld	s0,96(sp)
    80006e26:	64e6                	ld	s1,88(sp)
    80006e28:	6946                	ld	s2,80(sp)
    80006e2a:	69a6                	ld	s3,72(sp)
    80006e2c:	6a06                	ld	s4,64(sp)
    80006e2e:	7ae2                	ld	s5,56(sp)
    80006e30:	7b42                	ld	s6,48(sp)
    80006e32:	7ba2                	ld	s7,40(sp)
    80006e34:	7c02                	ld	s8,32(sp)
    80006e36:	6ce2                	ld	s9,24(sp)
    80006e38:	6d42                	ld	s10,16(sp)
    80006e3a:	6165                	addi	sp,sp,112
    80006e3c:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006e3e:	4689                	li	a3,2
    80006e40:	00d79623          	sh	a3,12(a5)
    80006e44:	b5e5                	j	80006d2c <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006e46:	f9042603          	lw	a2,-112(s0)
    80006e4a:	00a60713          	addi	a4,a2,10
    80006e4e:	0712                	slli	a4,a4,0x4
    80006e50:	0001e517          	auipc	a0,0x1e
    80006e54:	31050513          	addi	a0,a0,784 # 80025160 <disk+0x8>
    80006e58:	953a                	add	a0,a0,a4
  if(write)
    80006e5a:	e60d14e3          	bnez	s10,80006cc2 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006e5e:	00a60793          	addi	a5,a2,10
    80006e62:	00479693          	slli	a3,a5,0x4
    80006e66:	0001e797          	auipc	a5,0x1e
    80006e6a:	2f278793          	addi	a5,a5,754 # 80025158 <disk>
    80006e6e:	97b6                	add	a5,a5,a3
    80006e70:	0007a423          	sw	zero,8(a5)
    80006e74:	b595                	j	80006cd8 <virtio_disk_rw+0xf0>

0000000080006e76 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006e76:	1101                	addi	sp,sp,-32
    80006e78:	ec06                	sd	ra,24(sp)
    80006e7a:	e822                	sd	s0,16(sp)
    80006e7c:	e426                	sd	s1,8(sp)
    80006e7e:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006e80:	0001e497          	auipc	s1,0x1e
    80006e84:	2d848493          	addi	s1,s1,728 # 80025158 <disk>
    80006e88:	0001e517          	auipc	a0,0x1e
    80006e8c:	3f850513          	addi	a0,a0,1016 # 80025280 <disk+0x128>
    80006e90:	ffffa097          	auipc	ra,0xffffa
    80006e94:	d5a080e7          	jalr	-678(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006e98:	10001737          	lui	a4,0x10001
    80006e9c:	533c                	lw	a5,96(a4)
    80006e9e:	8b8d                	andi	a5,a5,3
    80006ea0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006ea2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006ea6:	689c                	ld	a5,16(s1)
    80006ea8:	0204d703          	lhu	a4,32(s1)
    80006eac:	0027d783          	lhu	a5,2(a5)
    80006eb0:	04f70863          	beq	a4,a5,80006f00 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006eb4:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006eb8:	6898                	ld	a4,16(s1)
    80006eba:	0204d783          	lhu	a5,32(s1)
    80006ebe:	8b9d                	andi	a5,a5,7
    80006ec0:	078e                	slli	a5,a5,0x3
    80006ec2:	97ba                	add	a5,a5,a4
    80006ec4:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006ec6:	00278713          	addi	a4,a5,2
    80006eca:	0712                	slli	a4,a4,0x4
    80006ecc:	9726                	add	a4,a4,s1
    80006ece:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006ed2:	e721                	bnez	a4,80006f1a <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006ed4:	0789                	addi	a5,a5,2
    80006ed6:	0792                	slli	a5,a5,0x4
    80006ed8:	97a6                	add	a5,a5,s1
    80006eda:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006edc:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006ee0:	ffffb097          	auipc	ra,0xffffb
    80006ee4:	732080e7          	jalr	1842(ra) # 80002612 <wakeup>

    disk.used_idx += 1;
    80006ee8:	0204d783          	lhu	a5,32(s1)
    80006eec:	2785                	addiw	a5,a5,1
    80006eee:	17c2                	slli	a5,a5,0x30
    80006ef0:	93c1                	srli	a5,a5,0x30
    80006ef2:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006ef6:	6898                	ld	a4,16(s1)
    80006ef8:	00275703          	lhu	a4,2(a4)
    80006efc:	faf71ce3          	bne	a4,a5,80006eb4 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006f00:	0001e517          	auipc	a0,0x1e
    80006f04:	38050513          	addi	a0,a0,896 # 80025280 <disk+0x128>
    80006f08:	ffffa097          	auipc	ra,0xffffa
    80006f0c:	d96080e7          	jalr	-618(ra) # 80000c9e <release>
}
    80006f10:	60e2                	ld	ra,24(sp)
    80006f12:	6442                	ld	s0,16(sp)
    80006f14:	64a2                	ld	s1,8(sp)
    80006f16:	6105                	addi	sp,sp,32
    80006f18:	8082                	ret
      panic("virtio_disk_intr status");
    80006f1a:	00003517          	auipc	a0,0x3
    80006f1e:	ace50513          	addi	a0,a0,-1330 # 800099e8 <syscalls+0x400>
    80006f22:	ffff9097          	auipc	ra,0xffff9
    80006f26:	622080e7          	jalr	1570(ra) # 80000544 <panic>

0000000080006f2a <sgenrand>:
static int mti=N+1; /* mti==N+1 means mt[N] is not initialized */

/* initializing the array with a NONZERO seed */
void
sgenrand(unsigned long seed)
{
    80006f2a:	1141                	addi	sp,sp,-16
    80006f2c:	e422                	sd	s0,8(sp)
    80006f2e:	0800                	addi	s0,sp,16
    /* setting initial seeds to mt[N] using         */
    /* the generator Line 25 of Table 1 in          */
    /* [KNUTH 1981, The Art of Computer Programming */
    /*    Vol. 2 (2nd Ed.), pp102]                  */
    mt[0]= seed & 0xffffffff;
    80006f30:	0001e717          	auipc	a4,0x1e
    80006f34:	36870713          	addi	a4,a4,872 # 80025298 <mt>
    80006f38:	1502                	slli	a0,a0,0x20
    80006f3a:	9101                	srli	a0,a0,0x20
    80006f3c:	e308                	sd	a0,0(a4)
    for (mti=1; mti<N; mti++)
    80006f3e:	0001f597          	auipc	a1,0x1f
    80006f42:	6d258593          	addi	a1,a1,1746 # 80026610 <mt+0x1378>
        mt[mti] = (69069 * mt[mti-1]) & 0xffffffff;
    80006f46:	6645                	lui	a2,0x11
    80006f48:	dcd60613          	addi	a2,a2,-563 # 10dcd <_entry-0x7ffef233>
    80006f4c:	56fd                	li	a3,-1
    80006f4e:	9281                	srli	a3,a3,0x20
    80006f50:	631c                	ld	a5,0(a4)
    80006f52:	02c787b3          	mul	a5,a5,a2
    80006f56:	8ff5                	and	a5,a5,a3
    80006f58:	e71c                	sd	a5,8(a4)
    for (mti=1; mti<N; mti++)
    80006f5a:	0721                	addi	a4,a4,8
    80006f5c:	feb71ae3          	bne	a4,a1,80006f50 <sgenrand+0x26>
    80006f60:	27000793          	li	a5,624
    80006f64:	00003717          	auipc	a4,0x3
    80006f68:	aaf72a23          	sw	a5,-1356(a4) # 80009a18 <mti>
}
    80006f6c:	6422                	ld	s0,8(sp)
    80006f6e:	0141                	addi	sp,sp,16
    80006f70:	8082                	ret

0000000080006f72 <genrand>:

long /* for integer generation */
genrand()
{
    80006f72:	1141                	addi	sp,sp,-16
    80006f74:	e406                	sd	ra,8(sp)
    80006f76:	e022                	sd	s0,0(sp)
    80006f78:	0800                	addi	s0,sp,16
    unsigned long y;
    static unsigned long mag01[2]={0x0, MATRIX_A};
    /* mag01[x] = x * MATRIX_A  for x=0,1 */

    if (mti >= N) { /* generate N words at one time */
    80006f7a:	00003797          	auipc	a5,0x3
    80006f7e:	a9e7a783          	lw	a5,-1378(a5) # 80009a18 <mti>
    80006f82:	26f00713          	li	a4,623
    80006f86:	0ef75963          	bge	a4,a5,80007078 <genrand+0x106>
        int kk;

        if (mti == N+1)   /* if sgenrand() has not been called, */
    80006f8a:	27100713          	li	a4,625
    80006f8e:	12e78f63          	beq	a5,a4,800070cc <genrand+0x15a>
            sgenrand(4357); /* a default initial seed is used   */

        for (kk=0;kk<N-M;kk++) {
    80006f92:	0001e817          	auipc	a6,0x1e
    80006f96:	30680813          	addi	a6,a6,774 # 80025298 <mt>
    80006f9a:	0001fe17          	auipc	t3,0x1f
    80006f9e:	a16e0e13          	addi	t3,t3,-1514 # 800259b0 <mt+0x718>
{
    80006fa2:	8742                	mv	a4,a6
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    80006fa4:	4885                	li	a7,1
    80006fa6:	08fe                	slli	a7,a7,0x1f
    80006fa8:	80000537          	lui	a0,0x80000
    80006fac:	fff54513          	not	a0,a0
            mt[kk] = mt[kk+M] ^ (y >> 1) ^ mag01[y & 0x1];
    80006fb0:	6585                	lui	a1,0x1
    80006fb2:	c6858593          	addi	a1,a1,-920 # c68 <_entry-0x7ffff398>
    80006fb6:	00003317          	auipc	t1,0x3
    80006fba:	a4a30313          	addi	t1,t1,-1462 # 80009a00 <mag01.985>
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    80006fbe:	631c                	ld	a5,0(a4)
    80006fc0:	0117f7b3          	and	a5,a5,a7
    80006fc4:	6714                	ld	a3,8(a4)
    80006fc6:	8ee9                	and	a3,a3,a0
    80006fc8:	8fd5                	or	a5,a5,a3
            mt[kk] = mt[kk+M] ^ (y >> 1) ^ mag01[y & 0x1];
    80006fca:	00b70633          	add	a2,a4,a1
    80006fce:	0017d693          	srli	a3,a5,0x1
    80006fd2:	6210                	ld	a2,0(a2)
    80006fd4:	8eb1                	xor	a3,a3,a2
    80006fd6:	8b85                	andi	a5,a5,1
    80006fd8:	078e                	slli	a5,a5,0x3
    80006fda:	979a                	add	a5,a5,t1
    80006fdc:	639c                	ld	a5,0(a5)
    80006fde:	8fb5                	xor	a5,a5,a3
    80006fe0:	e31c                	sd	a5,0(a4)
        for (kk=0;kk<N-M;kk++) {
    80006fe2:	0721                	addi	a4,a4,8
    80006fe4:	fdc71de3          	bne	a4,t3,80006fbe <genrand+0x4c>
        }
        for (;kk<N-1;kk++) {
    80006fe8:	6605                	lui	a2,0x1
    80006fea:	c6060613          	addi	a2,a2,-928 # c60 <_entry-0x7ffff3a0>
    80006fee:	9642                	add	a2,a2,a6
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    80006ff0:	4505                	li	a0,1
    80006ff2:	057e                	slli	a0,a0,0x1f
    80006ff4:	800005b7          	lui	a1,0x80000
    80006ff8:	fff5c593          	not	a1,a1
            mt[kk] = mt[kk+(M-N)] ^ (y >> 1) ^ mag01[y & 0x1];
    80006ffc:	00003897          	auipc	a7,0x3
    80007000:	a0488893          	addi	a7,a7,-1532 # 80009a00 <mag01.985>
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    80007004:	71883783          	ld	a5,1816(a6)
    80007008:	8fe9                	and	a5,a5,a0
    8000700a:	72083703          	ld	a4,1824(a6)
    8000700e:	8f6d                	and	a4,a4,a1
    80007010:	8fd9                	or	a5,a5,a4
            mt[kk] = mt[kk+(M-N)] ^ (y >> 1) ^ mag01[y & 0x1];
    80007012:	0017d713          	srli	a4,a5,0x1
    80007016:	00083683          	ld	a3,0(a6)
    8000701a:	8f35                	xor	a4,a4,a3
    8000701c:	8b85                	andi	a5,a5,1
    8000701e:	078e                	slli	a5,a5,0x3
    80007020:	97c6                	add	a5,a5,a7
    80007022:	639c                	ld	a5,0(a5)
    80007024:	8fb9                	xor	a5,a5,a4
    80007026:	70f83c23          	sd	a5,1816(a6)
        for (;kk<N-1;kk++) {
    8000702a:	0821                	addi	a6,a6,8
    8000702c:	fcc81ce3          	bne	a6,a2,80007004 <genrand+0x92>
        }
        y = (mt[N-1]&UPPER_MASK)|(mt[0]&LOWER_MASK);
    80007030:	0001f697          	auipc	a3,0x1f
    80007034:	26868693          	addi	a3,a3,616 # 80026298 <mt+0x1000>
    80007038:	3786b783          	ld	a5,888(a3)
    8000703c:	4705                	li	a4,1
    8000703e:	077e                	slli	a4,a4,0x1f
    80007040:	8ff9                	and	a5,a5,a4
    80007042:	0001e717          	auipc	a4,0x1e
    80007046:	25673703          	ld	a4,598(a4) # 80025298 <mt>
    8000704a:	1706                	slli	a4,a4,0x21
    8000704c:	9305                	srli	a4,a4,0x21
    8000704e:	8fd9                	or	a5,a5,a4
        mt[N-1] = mt[M-1] ^ (y >> 1) ^ mag01[y & 0x1];
    80007050:	0017d713          	srli	a4,a5,0x1
    80007054:	c606b603          	ld	a2,-928(a3)
    80007058:	8f31                	xor	a4,a4,a2
    8000705a:	8b85                	andi	a5,a5,1
    8000705c:	078e                	slli	a5,a5,0x3
    8000705e:	00003617          	auipc	a2,0x3
    80007062:	9a260613          	addi	a2,a2,-1630 # 80009a00 <mag01.985>
    80007066:	97b2                	add	a5,a5,a2
    80007068:	639c                	ld	a5,0(a5)
    8000706a:	8fb9                	xor	a5,a5,a4
    8000706c:	36f6bc23          	sd	a5,888(a3)

        mti = 0;
    80007070:	00003797          	auipc	a5,0x3
    80007074:	9a07a423          	sw	zero,-1624(a5) # 80009a18 <mti>
    }
  
    y = mt[mti++];
    80007078:	00003717          	auipc	a4,0x3
    8000707c:	9a070713          	addi	a4,a4,-1632 # 80009a18 <mti>
    80007080:	431c                	lw	a5,0(a4)
    80007082:	0017869b          	addiw	a3,a5,1
    80007086:	c314                	sw	a3,0(a4)
    80007088:	078e                	slli	a5,a5,0x3
    8000708a:	0001e717          	auipc	a4,0x1e
    8000708e:	20e70713          	addi	a4,a4,526 # 80025298 <mt>
    80007092:	97ba                	add	a5,a5,a4
    80007094:	6398                	ld	a4,0(a5)
    y ^= TEMPERING_SHIFT_U(y);
    80007096:	00b75793          	srli	a5,a4,0xb
    8000709a:	8f3d                	xor	a4,a4,a5
    y ^= TEMPERING_SHIFT_S(y) & TEMPERING_MASK_B;
    8000709c:	013a67b7          	lui	a5,0x13a6
    800070a0:	8ad78793          	addi	a5,a5,-1875 # 13a58ad <_entry-0x7ec5a753>
    800070a4:	8ff9                	and	a5,a5,a4
    800070a6:	079e                	slli	a5,a5,0x7
    800070a8:	8fb9                	xor	a5,a5,a4
    y ^= TEMPERING_SHIFT_T(y) & TEMPERING_MASK_C;
    800070aa:	00f79713          	slli	a4,a5,0xf
    800070ae:	077e36b7          	lui	a3,0x77e3
    800070b2:	0696                	slli	a3,a3,0x5
    800070b4:	8f75                	and	a4,a4,a3
    800070b6:	8fb9                	xor	a5,a5,a4
    y ^= TEMPERING_SHIFT_L(y);
    800070b8:	0127d513          	srli	a0,a5,0x12
    800070bc:	8fa9                	xor	a5,a5,a0

    // Strip off uppermost bit because we want a long,
    // not an unsigned long
    return y & RAND_MAX;
    800070be:	02179513          	slli	a0,a5,0x21
}
    800070c2:	9105                	srli	a0,a0,0x21
    800070c4:	60a2                	ld	ra,8(sp)
    800070c6:	6402                	ld	s0,0(sp)
    800070c8:	0141                	addi	sp,sp,16
    800070ca:	8082                	ret
            sgenrand(4357); /* a default initial seed is used   */
    800070cc:	6505                	lui	a0,0x1
    800070ce:	10550513          	addi	a0,a0,261 # 1105 <_entry-0x7fffeefb>
    800070d2:	00000097          	auipc	ra,0x0
    800070d6:	e58080e7          	jalr	-424(ra) # 80006f2a <sgenrand>
    800070da:	bd65                	j	80006f92 <genrand+0x20>

00000000800070dc <random>:

// Assumes 0 <= max <= RAND_MAX
// Returns in the half-open interval [0, max]
long random(long max) {
    800070dc:	1101                	addi	sp,sp,-32
    800070de:	ec06                	sd	ra,24(sp)
    800070e0:	e822                	sd	s0,16(sp)
    800070e2:	e426                	sd	s1,8(sp)
    800070e4:	1000                	addi	s0,sp,32
    800070e6:	84aa                	mv	s1,a0
    unsigned long random = (unsigned long)((long)genrand() % (max + 1)); 
    800070e8:	00000097          	auipc	ra,0x0
    800070ec:	e8a080e7          	jalr	-374(ra) # 80006f72 <genrand>
    800070f0:	0485                	addi	s1,s1,1
    return random;
    800070f2:	02956533          	rem	a0,a0,s1
    800070f6:	60e2                	ld	ra,24(sp)
    800070f8:	6442                	ld	s0,16(sp)
    800070fa:	64a2                	ld	s1,8(sp)
    800070fc:	6105                	addi	sp,sp,32
    800070fe:	8082                	ret
	...

0000000080008000 <_trampoline>:
    80008000:	14051073          	csrw	sscratch,a0
    80008004:	02000537          	lui	a0,0x2000
    80008008:	357d                	addiw	a0,a0,-1
    8000800a:	0536                	slli	a0,a0,0xd
    8000800c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80008010:	02253823          	sd	sp,48(a0)
    80008014:	02353c23          	sd	gp,56(a0)
    80008018:	04453023          	sd	tp,64(a0)
    8000801c:	04553423          	sd	t0,72(a0)
    80008020:	04653823          	sd	t1,80(a0)
    80008024:	04753c23          	sd	t2,88(a0)
    80008028:	f120                	sd	s0,96(a0)
    8000802a:	f524                	sd	s1,104(a0)
    8000802c:	fd2c                	sd	a1,120(a0)
    8000802e:	e150                	sd	a2,128(a0)
    80008030:	e554                	sd	a3,136(a0)
    80008032:	e958                	sd	a4,144(a0)
    80008034:	ed5c                	sd	a5,152(a0)
    80008036:	0b053023          	sd	a6,160(a0)
    8000803a:	0b153423          	sd	a7,168(a0)
    8000803e:	0b253823          	sd	s2,176(a0)
    80008042:	0b353c23          	sd	s3,184(a0)
    80008046:	0d453023          	sd	s4,192(a0)
    8000804a:	0d553423          	sd	s5,200(a0)
    8000804e:	0d653823          	sd	s6,208(a0)
    80008052:	0d753c23          	sd	s7,216(a0)
    80008056:	0f853023          	sd	s8,224(a0)
    8000805a:	0f953423          	sd	s9,232(a0)
    8000805e:	0fa53823          	sd	s10,240(a0)
    80008062:	0fb53c23          	sd	s11,248(a0)
    80008066:	11c53023          	sd	t3,256(a0)
    8000806a:	11d53423          	sd	t4,264(a0)
    8000806e:	11e53823          	sd	t5,272(a0)
    80008072:	11f53c23          	sd	t6,280(a0)
    80008076:	140022f3          	csrr	t0,sscratch
    8000807a:	06553823          	sd	t0,112(a0)
    8000807e:	00853103          	ld	sp,8(a0)
    80008082:	02053203          	ld	tp,32(a0)
    80008086:	01053283          	ld	t0,16(a0)
    8000808a:	00053303          	ld	t1,0(a0)
    8000808e:	12000073          	sfence.vma
    80008092:	18031073          	csrw	satp,t1
    80008096:	12000073          	sfence.vma
    8000809a:	8282                	jr	t0

000000008000809c <userret>:
    8000809c:	12000073          	sfence.vma
    800080a0:	18051073          	csrw	satp,a0
    800080a4:	12000073          	sfence.vma
    800080a8:	02000537          	lui	a0,0x2000
    800080ac:	357d                	addiw	a0,a0,-1
    800080ae:	0536                	slli	a0,a0,0xd
    800080b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800080b4:	03053103          	ld	sp,48(a0)
    800080b8:	03853183          	ld	gp,56(a0)
    800080bc:	04053203          	ld	tp,64(a0)
    800080c0:	04853283          	ld	t0,72(a0)
    800080c4:	05053303          	ld	t1,80(a0)
    800080c8:	05853383          	ld	t2,88(a0)
    800080cc:	7120                	ld	s0,96(a0)
    800080ce:	7524                	ld	s1,104(a0)
    800080d0:	7d2c                	ld	a1,120(a0)
    800080d2:	6150                	ld	a2,128(a0)
    800080d4:	6554                	ld	a3,136(a0)
    800080d6:	6958                	ld	a4,144(a0)
    800080d8:	6d5c                	ld	a5,152(a0)
    800080da:	0a053803          	ld	a6,160(a0)
    800080de:	0a853883          	ld	a7,168(a0)
    800080e2:	0b053903          	ld	s2,176(a0)
    800080e6:	0b853983          	ld	s3,184(a0)
    800080ea:	0c053a03          	ld	s4,192(a0)
    800080ee:	0c853a83          	ld	s5,200(a0)
    800080f2:	0d053b03          	ld	s6,208(a0)
    800080f6:	0d853b83          	ld	s7,216(a0)
    800080fa:	0e053c03          	ld	s8,224(a0)
    800080fe:	0e853c83          	ld	s9,232(a0)
    80008102:	0f053d03          	ld	s10,240(a0)
    80008106:	0f853d83          	ld	s11,248(a0)
    8000810a:	10053e03          	ld	t3,256(a0)
    8000810e:	10853e83          	ld	t4,264(a0)
    80008112:	11053f03          	ld	t5,272(a0)
    80008116:	11853f83          	ld	t6,280(a0)
    8000811a:	7928                	ld	a0,112(a0)
    8000811c:	10200073          	sret
	...
