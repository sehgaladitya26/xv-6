
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	ab813103          	ld	sp,-1352(sp) # 80008ab8 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000052:	00009717          	auipc	a4,0x9
    80000056:	abe70713          	addi	a4,a4,-1346 # 80008b10 <timer_scratch>
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
    80000064:	00006797          	auipc	a5,0x6
    80000068:	3ac78793          	addi	a5,a5,940 # 80006410 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd9887>
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
    80000130:	8e8080e7          	jalr	-1816(ra) # 80002a14 <either_copyin>
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
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ac450513          	addi	a0,a0,-1340 # 80010c50 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a56080e7          	jalr	-1450(ra) # 80000bea <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	ab448493          	addi	s1,s1,-1356 # 80010c50 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	b4290913          	addi	s2,s2,-1214 # 80010ce8 <cons+0x98>
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
    800001c8:	9f0080e7          	jalr	-1552(ra) # 80001bb4 <myproc>
    800001cc:	00002097          	auipc	ra,0x2
    800001d0:	692080e7          	jalr	1682(ra) # 8000285e <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	284080e7          	jalr	644(ra) # 8000245e <sleep>
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
    8000021a:	7a8080e7          	jalr	1960(ra) # 800029be <either_copyout>
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
    8000022a:	00011517          	auipc	a0,0x11
    8000022e:	a2650513          	addi	a0,a0,-1498 # 80010c50 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a6c080e7          	jalr	-1428(ra) # 80000c9e <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	a1050513          	addi	a0,a0,-1520 # 80010c50 <cons>
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
    80000278:	00011717          	auipc	a4,0x11
    8000027c:	a6f72823          	sw	a5,-1424(a4) # 80010ce8 <cons+0x98>
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
    800002d2:	00011517          	auipc	a0,0x11
    800002d6:	97e50513          	addi	a0,a0,-1666 # 80010c50 <cons>
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
    800002fc:	772080e7          	jalr	1906(ra) # 80002a6a <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00011517          	auipc	a0,0x11
    80000304:	95050513          	addi	a0,a0,-1712 # 80010c50 <cons>
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
    80000324:	00011717          	auipc	a4,0x11
    80000328:	92c70713          	addi	a4,a4,-1748 # 80010c50 <cons>
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
    8000034e:	00011797          	auipc	a5,0x11
    80000352:	90278793          	addi	a5,a5,-1790 # 80010c50 <cons>
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
    8000037c:	00011797          	auipc	a5,0x11
    80000380:	96c7a783          	lw	a5,-1684(a5) # 80010ce8 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00011717          	auipc	a4,0x11
    80000394:	8c070713          	addi	a4,a4,-1856 # 80010c50 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00011497          	auipc	s1,0x11
    800003a4:	8b048493          	addi	s1,s1,-1872 # 80010c50 <cons>
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
    800003dc:	00011717          	auipc	a4,0x11
    800003e0:	87470713          	addi	a4,a4,-1932 # 80010c50 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00011717          	auipc	a4,0x11
    800003f6:	8ef72f23          	sw	a5,-1794(a4) # 80010cf0 <cons+0xa0>
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
    80000418:	00011797          	auipc	a5,0x11
    8000041c:	83878793          	addi	a5,a5,-1992 # 80010c50 <cons>
    80000420:	0a07a703          	lw	a4,160(a5)
    80000424:	0017069b          	addiw	a3,a4,1
    80000428:	0006861b          	sext.w	a2,a3
    8000042c:	0ad7a023          	sw	a3,160(a5)
    80000430:	07f77713          	andi	a4,a4,127
    80000434:	97ba                	add	a5,a5,a4
    80000436:	4729                	li	a4,10
    80000438:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043c:	00011797          	auipc	a5,0x11
    80000440:	8ac7a823          	sw	a2,-1872(a5) # 80010cec <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00011517          	auipc	a0,0x11
    80000448:	8a450513          	addi	a0,a0,-1884 # 80010ce8 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	1c2080e7          	jalr	450(ra) # 8000260e <wakeup>
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
    8000045e:	00008597          	auipc	a1,0x8
    80000462:	bb258593          	addi	a1,a1,-1102 # 80008010 <etext+0x10>
    80000466:	00010517          	auipc	a0,0x10
    8000046a:	7ea50513          	addi	a0,a0,2026 # 80010c50 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	6ec080e7          	jalr	1772(ra) # 80000b5a <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00022797          	auipc	a5,0x22
    80000482:	5e278793          	addi	a5,a5,1506 # 80022a60 <devsw>
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
    800004c0:	00008617          	auipc	a2,0x8
    800004c4:	b8060613          	addi	a2,a2,-1152 # 80008040 <digits>
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
    80000550:	00010797          	auipc	a5,0x10
    80000554:	7c07a023          	sw	zero,1984(a5) # 80010d10 <pr+0x18>
  printf("panic: ");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	ac050513          	addi	a0,a0,-1344 # 80008018 <etext+0x18>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	02e080e7          	jalr	46(ra) # 8000058e <printf>
  printf(s);
    80000568:	8526                	mv	a0,s1
    8000056a:	00000097          	auipc	ra,0x0
    8000056e:	024080e7          	jalr	36(ra) # 8000058e <printf>
  printf("\n");
    80000572:	00008517          	auipc	a0,0x8
    80000576:	b5650513          	addi	a0,a0,-1194 # 800080c8 <digits+0x88>
    8000057a:	00000097          	auipc	ra,0x0
    8000057e:	014080e7          	jalr	20(ra) # 8000058e <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000582:	4785                	li	a5,1
    80000584:	00008717          	auipc	a4,0x8
    80000588:	54f72623          	sw	a5,1356(a4) # 80008ad0 <panicked>
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
    800005c0:	00010d97          	auipc	s11,0x10
    800005c4:	750dad83          	lw	s11,1872(s11) # 80010d10 <pr+0x18>
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
    800005ec:	00008b97          	auipc	s7,0x8
    800005f0:	a54b8b93          	addi	s7,s7,-1452 # 80008040 <digits>
    switch(c){
    800005f4:	07300c93          	li	s9,115
    800005f8:	06400c13          	li	s8,100
    800005fc:	a82d                	j	80000636 <printf+0xa8>
    acquire(&pr.lock);
    800005fe:	00010517          	auipc	a0,0x10
    80000602:	6fa50513          	addi	a0,a0,1786 # 80010cf8 <pr>
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	5e4080e7          	jalr	1508(ra) # 80000bea <acquire>
    8000060e:	bf7d                	j	800005cc <printf+0x3e>
    panic("null fmt");
    80000610:	00008517          	auipc	a0,0x8
    80000614:	a1850513          	addi	a0,a0,-1512 # 80008028 <etext+0x28>
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
    80000710:	00008917          	auipc	s2,0x8
    80000714:	91090913          	addi	s2,s2,-1776 # 80008020 <etext+0x20>
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
    80000762:	00010517          	auipc	a0,0x10
    80000766:	59650513          	addi	a0,a0,1430 # 80010cf8 <pr>
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
    8000077e:	00010497          	auipc	s1,0x10
    80000782:	57a48493          	addi	s1,s1,1402 # 80010cf8 <pr>
    80000786:	00008597          	auipc	a1,0x8
    8000078a:	8b258593          	addi	a1,a1,-1870 # 80008038 <etext+0x38>
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
    800007d6:	00008597          	auipc	a1,0x8
    800007da:	88258593          	addi	a1,a1,-1918 # 80008058 <digits+0x18>
    800007de:	00010517          	auipc	a0,0x10
    800007e2:	53a50513          	addi	a0,a0,1338 # 80010d18 <uart_tx_lock>
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
    8000080a:	00008797          	auipc	a5,0x8
    8000080e:	2c67a783          	lw	a5,710(a5) # 80008ad0 <panicked>
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
    80000846:	00008717          	auipc	a4,0x8
    8000084a:	29273703          	ld	a4,658(a4) # 80008ad8 <uart_tx_r>
    8000084e:	00008797          	auipc	a5,0x8
    80000852:	2927b783          	ld	a5,658(a5) # 80008ae0 <uart_tx_w>
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
    80000870:	00010a17          	auipc	s4,0x10
    80000874:	4a8a0a13          	addi	s4,s4,1192 # 80010d18 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	26048493          	addi	s1,s1,608 # 80008ad8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	26098993          	addi	s3,s3,608 # 80008ae0 <uart_tx_w>
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
    800008aa:	d68080e7          	jalr	-664(ra) # 8000260e <wakeup>
    
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
    800008e2:	00010517          	auipc	a0,0x10
    800008e6:	43650513          	addi	a0,a0,1078 # 80010d18 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	300080e7          	jalr	768(ra) # 80000bea <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	1de7a783          	lw	a5,478(a5) # 80008ad0 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008797          	auipc	a5,0x8
    80000900:	1e47b783          	ld	a5,484(a5) # 80008ae0 <uart_tx_w>
    80000904:	00008717          	auipc	a4,0x8
    80000908:	1d473703          	ld	a4,468(a4) # 80008ad8 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010a17          	auipc	s4,0x10
    80000914:	408a0a13          	addi	s4,s4,1032 # 80010d18 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	1c048493          	addi	s1,s1,448 # 80008ad8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	1c090913          	addi	s2,s2,448 # 80008ae0 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00002097          	auipc	ra,0x2
    80000934:	b2e080e7          	jalr	-1234(ra) # 8000245e <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	3d248493          	addi	s1,s1,978 # 80010d18 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00008717          	auipc	a4,0x8
    8000095e:	18f73323          	sd	a5,390(a4) # 80008ae0 <uart_tx_w>
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
    800009d0:	00010497          	auipc	s1,0x10
    800009d4:	34848493          	addi	s1,s1,840 # 80010d18 <uart_tx_lock>
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
    80000a12:	00024797          	auipc	a5,0x24
    80000a16:	56678793          	addi	a5,a5,1382 # 80024f78 <end>
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
    80000a32:	00010917          	auipc	s2,0x10
    80000a36:	31e90913          	addi	s2,s2,798 # 80010d50 <kmem>
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
    80000a64:	00007517          	auipc	a0,0x7
    80000a68:	5fc50513          	addi	a0,a0,1532 # 80008060 <digits+0x20>
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
    80000ac6:	00007597          	auipc	a1,0x7
    80000aca:	5a258593          	addi	a1,a1,1442 # 80008068 <digits+0x28>
    80000ace:	00010517          	auipc	a0,0x10
    80000ad2:	28250513          	addi	a0,a0,642 # 80010d50 <kmem>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	084080e7          	jalr	132(ra) # 80000b5a <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ade:	45c5                	li	a1,17
    80000ae0:	05ee                	slli	a1,a1,0x1b
    80000ae2:	00024517          	auipc	a0,0x24
    80000ae6:	49650513          	addi	a0,a0,1174 # 80024f78 <end>
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
    80000b04:	00010497          	auipc	s1,0x10
    80000b08:	24c48493          	addi	s1,s1,588 # 80010d50 <kmem>
    80000b0c:	8526                	mv	a0,s1
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	0dc080e7          	jalr	220(ra) # 80000bea <acquire>
  r = kmem.freelist;
    80000b16:	6c84                	ld	s1,24(s1)
  if(r)
    80000b18:	c885                	beqz	s1,80000b48 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b1a:	609c                	ld	a5,0(s1)
    80000b1c:	00010517          	auipc	a0,0x10
    80000b20:	23450513          	addi	a0,a0,564 # 80010d50 <kmem>
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
    80000b48:	00010517          	auipc	a0,0x10
    80000b4c:	20850513          	addi	a0,a0,520 # 80010d50 <kmem>
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
    80000b88:	014080e7          	jalr	20(ra) # 80001b98 <mycpu>
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
    80000bba:	fe2080e7          	jalr	-30(ra) # 80001b98 <mycpu>
    80000bbe:	5d3c                	lw	a5,120(a0)
    80000bc0:	cf89                	beqz	a5,80000bda <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bc2:	00001097          	auipc	ra,0x1
    80000bc6:	fd6080e7          	jalr	-42(ra) # 80001b98 <mycpu>
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
    80000bde:	fbe080e7          	jalr	-66(ra) # 80001b98 <mycpu>
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
    80000c1e:	f7e080e7          	jalr	-130(ra) # 80001b98 <mycpu>
    80000c22:	e888                	sd	a0,16(s1)
}
    80000c24:	60e2                	ld	ra,24(sp)
    80000c26:	6442                	ld	s0,16(sp)
    80000c28:	64a2                	ld	s1,8(sp)
    80000c2a:	6105                	addi	sp,sp,32
    80000c2c:	8082                	ret
    panic("acquire");
    80000c2e:	00007517          	auipc	a0,0x7
    80000c32:	44250513          	addi	a0,a0,1090 # 80008070 <digits+0x30>
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
    80000c4a:	f52080e7          	jalr	-174(ra) # 80001b98 <mycpu>
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
    80000c7e:	00007517          	auipc	a0,0x7
    80000c82:	3fa50513          	addi	a0,a0,1018 # 80008078 <digits+0x38>
    80000c86:	00000097          	auipc	ra,0x0
    80000c8a:	8be080e7          	jalr	-1858(ra) # 80000544 <panic>
    panic("pop_off");
    80000c8e:	00007517          	auipc	a0,0x7
    80000c92:	40250513          	addi	a0,a0,1026 # 80008090 <digits+0x50>
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
    80000cd6:	00007517          	auipc	a0,0x7
    80000cda:	3c250513          	addi	a0,a0,962 # 80008098 <digits+0x58>
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
    80000ea0:	cec080e7          	jalr	-788(ra) # 80001b88 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ea4:	00008717          	auipc	a4,0x8
    80000ea8:	c4470713          	addi	a4,a4,-956 # 80008ae8 <started>
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
    80000ebc:	cd0080e7          	jalr	-816(ra) # 80001b88 <cpuid>
    80000ec0:	85aa                	mv	a1,a0
    80000ec2:	00007517          	auipc	a0,0x7
    80000ec6:	1f650513          	addi	a0,a0,502 # 800080b8 <digits+0x78>
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	6c4080e7          	jalr	1732(ra) # 8000058e <printf>
    kvminithart();    // turn on paging
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	0d8080e7          	jalr	216(ra) # 80000faa <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eda:	00002097          	auipc	ra,0x2
    80000ede:	cd0080e7          	jalr	-816(ra) # 80002baa <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00005097          	auipc	ra,0x5
    80000ee6:	56e080e7          	jalr	1390(ra) # 80006450 <plicinithart>
  }

  scheduler();        
    80000eea:	00001097          	auipc	ra,0x1
    80000eee:	20a080e7          	jalr	522(ra) # 800020f4 <scheduler>
    consoleinit();
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	564080e7          	jalr	1380(ra) # 80000456 <consoleinit>
    printfinit();
    80000efa:	00000097          	auipc	ra,0x0
    80000efe:	87a080e7          	jalr	-1926(ra) # 80000774 <printfinit>
    printf("\n");
    80000f02:	00007517          	auipc	a0,0x7
    80000f06:	1c650513          	addi	a0,a0,454 # 800080c8 <digits+0x88>
    80000f0a:	fffff097          	auipc	ra,0xfffff
    80000f0e:	684080e7          	jalr	1668(ra) # 8000058e <printf>
    printf("xv6 kernel is booting\n");
    80000f12:	00007517          	auipc	a0,0x7
    80000f16:	18e50513          	addi	a0,a0,398 # 800080a0 <digits+0x60>
    80000f1a:	fffff097          	auipc	ra,0xfffff
    80000f1e:	674080e7          	jalr	1652(ra) # 8000058e <printf>
    printf("\n");
    80000f22:	00007517          	auipc	a0,0x7
    80000f26:	1a650513          	addi	a0,a0,422 # 800080c8 <digits+0x88>
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
    80000f4e:	b8a080e7          	jalr	-1142(ra) # 80001ad4 <procinit>
    trapinit();      // trap vectors
    80000f52:	00002097          	auipc	ra,0x2
    80000f56:	c30080e7          	jalr	-976(ra) # 80002b82 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00002097          	auipc	ra,0x2
    80000f5e:	c50080e7          	jalr	-944(ra) # 80002baa <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	4d8080e7          	jalr	1240(ra) # 8000643a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00005097          	auipc	ra,0x5
    80000f6e:	4e6080e7          	jalr	1254(ra) # 80006450 <plicinithart>
    binit();         // buffer cache
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	69e080e7          	jalr	1694(ra) # 80003610 <binit>
    iinit();         // inode table
    80000f7a:	00003097          	auipc	ra,0x3
    80000f7e:	d42080e7          	jalr	-702(ra) # 80003cbc <iinit>
    fileinit();      // file table
    80000f82:	00004097          	auipc	ra,0x4
    80000f86:	ce0080e7          	jalr	-800(ra) # 80004c62 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	5ce080e7          	jalr	1486(ra) # 80006558 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	f40080e7          	jalr	-192(ra) # 80001ed2 <userinit>
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    started = 1;
    80000f9e:	4785                	li	a5,1
    80000fa0:	00008717          	auipc	a4,0x8
    80000fa4:	b4f72423          	sw	a5,-1208(a4) # 80008ae8 <started>
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
    80000fb4:	00008797          	auipc	a5,0x8
    80000fb8:	b3c7b783          	ld	a5,-1220(a5) # 80008af0 <kernel_pagetable>
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
    80000ff8:	00007517          	auipc	a0,0x7
    80000ffc:	0d850513          	addi	a0,a0,216 # 800080d0 <digits+0x90>
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
    800010f0:	00007517          	auipc	a0,0x7
    800010f4:	fe850513          	addi	a0,a0,-24 # 800080d8 <digits+0x98>
    800010f8:	fffff097          	auipc	ra,0xfffff
    800010fc:	44c080e7          	jalr	1100(ra) # 80000544 <panic>
      panic("mappages: remap");
    80001100:	00007517          	auipc	a0,0x7
    80001104:	fe850513          	addi	a0,a0,-24 # 800080e8 <digits+0xa8>
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
    8000117a:	00007517          	auipc	a0,0x7
    8000117e:	f7e50513          	addi	a0,a0,-130 # 800080f8 <digits+0xb8>
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
    800011f0:	00007917          	auipc	s2,0x7
    800011f4:	e1090913          	addi	s2,s2,-496 # 80008000 <etext>
    800011f8:	4729                	li	a4,10
    800011fa:	80007697          	auipc	a3,0x80007
    800011fe:	e0668693          	addi	a3,a3,-506 # 8000 <_entry-0x7fff8000>
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
    8000122e:	00006617          	auipc	a2,0x6
    80001232:	dd260613          	addi	a2,a2,-558 # 80007000 <_trampoline>
    80001236:	040005b7          	lui	a1,0x4000
    8000123a:	15fd                	addi	a1,a1,-1
    8000123c:	05b2                	slli	a1,a1,0xc
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	f1a080e7          	jalr	-230(ra) # 8000115a <kvmmap>
  proc_mapstacks(kpgtbl);
    80001248:	8526                	mv	a0,s1
    8000124a:	00000097          	auipc	ra,0x0
    8000124e:	7f4080e7          	jalr	2036(ra) # 80001a3e <proc_mapstacks>
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
    80001270:	00008797          	auipc	a5,0x8
    80001274:	88a7b023          	sd	a0,-1920(a5) # 80008af0 <kernel_pagetable>
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
    800012c6:	00007517          	auipc	a0,0x7
    800012ca:	e3a50513          	addi	a0,a0,-454 # 80008100 <digits+0xc0>
    800012ce:	fffff097          	auipc	ra,0xfffff
    800012d2:	276080e7          	jalr	630(ra) # 80000544 <panic>
      panic("uvmunmap: walk");
    800012d6:	00007517          	auipc	a0,0x7
    800012da:	e4250513          	addi	a0,a0,-446 # 80008118 <digits+0xd8>
    800012de:	fffff097          	auipc	ra,0xfffff
    800012e2:	266080e7          	jalr	614(ra) # 80000544 <panic>
      panic("uvmunmap: not mapped");
    800012e6:	00007517          	auipc	a0,0x7
    800012ea:	e4250513          	addi	a0,a0,-446 # 80008128 <digits+0xe8>
    800012ee:	fffff097          	auipc	ra,0xfffff
    800012f2:	256080e7          	jalr	598(ra) # 80000544 <panic>
      panic("uvmunmap: not a leaf");
    800012f6:	00007517          	auipc	a0,0x7
    800012fa:	e4a50513          	addi	a0,a0,-438 # 80008140 <digits+0x100>
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
    800013d4:	00007517          	auipc	a0,0x7
    800013d8:	d8450513          	addi	a0,a0,-636 # 80008158 <digits+0x118>
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
    8000151e:	00007517          	auipc	a0,0x7
    80001522:	c5a50513          	addi	a0,a0,-934 # 80008178 <digits+0x138>
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
    800015fa:	00007517          	auipc	a0,0x7
    800015fe:	b8e50513          	addi	a0,a0,-1138 # 80008188 <digits+0x148>
    80001602:	fffff097          	auipc	ra,0xfffff
    80001606:	f42080e7          	jalr	-190(ra) # 80000544 <panic>
      panic("uvmcopy: page not present");
    8000160a:	00007517          	auipc	a0,0x7
    8000160e:	b9e50513          	addi	a0,a0,-1122 # 800081a8 <digits+0x168>
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
    80001674:	00007517          	auipc	a0,0x7
    80001678:	b5450513          	addi	a0,a0,-1196 # 800081c8 <digits+0x188>
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
    80001850:	19852703          	lw	a4,408(a0)
  //printf("%d %d\n",queues[idx].back, queues[idx].length);
  if (queues[idx].length == NPROC)
    80001854:	21800793          	li	a5,536
    80001858:	02f706b3          	mul	a3,a4,a5
    8000185c:	00010797          	auipc	a5,0x10
    80001860:	94478793          	addi	a5,a5,-1724 # 800111a0 <queues>
    80001864:	97b6                	add	a5,a5,a3
    80001866:	4790                	lw	a2,8(a5)
    80001868:	04000793          	li	a5,64
    8000186c:	06f60363          	beq	a2,a5,800018d2 <enqueue+0x82>
    panic("Full queue");

  queues[idx].procs[queues[idx].back] = process;
    80001870:	00010597          	auipc	a1,0x10
    80001874:	93058593          	addi	a1,a1,-1744 # 800111a0 <queues>
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
    800018a2:	04f58463          	beq	a1,a5,800018ea <enqueue+0x9a>
  queues[idx].back++;  
    800018a6:	21800793          	li	a5,536
    800018aa:	02f705b3          	mul	a1,a4,a5
    800018ae:	00010797          	auipc	a5,0x10
    800018b2:	8f278793          	addi	a5,a5,-1806 # 800111a0 <queues>
    800018b6:	97ae                	add	a5,a5,a1
    800018b8:	c3d4                	sw	a3,4(a5)
  queues[idx].length++;
    800018ba:	21800793          	li	a5,536
    800018be:	02f70733          	mul	a4,a4,a5
    800018c2:	00010797          	auipc	a5,0x10
    800018c6:	8de78793          	addi	a5,a5,-1826 # 800111a0 <queues>
    800018ca:	973e                	add	a4,a4,a5
    800018cc:	2605                	addiw	a2,a2,1
    800018ce:	c710                	sw	a2,8(a4)
    800018d0:	8082                	ret
{
    800018d2:	1141                	addi	sp,sp,-16
    800018d4:	e406                	sd	ra,8(sp)
    800018d6:	e022                	sd	s0,0(sp)
    800018d8:	0800                	addi	s0,sp,16
    panic("Full queue");
    800018da:	00007517          	auipc	a0,0x7
    800018de:	8fe50513          	addi	a0,a0,-1794 # 800081d8 <digits+0x198>
    800018e2:	fffff097          	auipc	ra,0xfffff
    800018e6:	c62080e7          	jalr	-926(ra) # 80000544 <panic>
  if (queues[idx].back == NPROC + 1) queues[idx].back = 0;
    800018ea:	21800793          	li	a5,536
    800018ee:	02f706b3          	mul	a3,a4,a5
    800018f2:	00010797          	auipc	a5,0x10
    800018f6:	8ae78793          	addi	a5,a5,-1874 # 800111a0 <queues>
    800018fa:	97b6                	add	a5,a5,a3
    800018fc:	0007a223          	sw	zero,4(a5)
    80001900:	bf6d                	j	800018ba <enqueue+0x6a>

0000000080001902 <dequeue>:
  //printf("size: %d\n",q->size);
}

void dequeue(struct proc *process)
{
  int idx = process->priority;
    80001902:	19852783          	lw	a5,408(a0)
  if (queues[idx].length == 0)
    80001906:	21800713          	li	a4,536
    8000190a:	02e786b3          	mul	a3,a5,a4
    8000190e:	00010717          	auipc	a4,0x10
    80001912:	89270713          	addi	a4,a4,-1902 # 800111a0 <queues>
    80001916:	9736                	add	a4,a4,a3
    80001918:	4718                	lw	a4,8(a4)
    8000191a:	cb21                	beqz	a4,8000196a <dequeue+0x68>
    panic("Empty queue");
  
  queues[idx].front++;
    8000191c:	21800693          	li	a3,536
    80001920:	02d78633          	mul	a2,a5,a3
    80001924:	00010697          	auipc	a3,0x10
    80001928:	87c68693          	addi	a3,a3,-1924 # 800111a0 <queues>
    8000192c:	96b2                	add	a3,a3,a2
    8000192e:	4294                	lw	a3,0(a3)
    80001930:	2685                	addiw	a3,a3,1
    80001932:	0006859b          	sext.w	a1,a3
  if (queues[idx].front == NPROC + 1) queues[idx].front = 0;
    80001936:	04100613          	li	a2,65
    8000193a:	04c58463          	beq	a1,a2,80001982 <dequeue+0x80>
  queues[idx].front++;
    8000193e:	21800613          	li	a2,536
    80001942:	02c785b3          	mul	a1,a5,a2
    80001946:	00010617          	auipc	a2,0x10
    8000194a:	85a60613          	addi	a2,a2,-1958 # 800111a0 <queues>
    8000194e:	962e                	add	a2,a2,a1
    80001950:	c214                	sw	a3,0(a2)
  queues[idx].length--;
    80001952:	21800693          	li	a3,536
    80001956:	02d787b3          	mul	a5,a5,a3
    8000195a:	00010697          	auipc	a3,0x10
    8000195e:	84668693          	addi	a3,a3,-1978 # 800111a0 <queues>
    80001962:	97b6                	add	a5,a5,a3
    80001964:	377d                	addiw	a4,a4,-1
    80001966:	c798                	sw	a4,8(a5)
    80001968:	8082                	ret
{
    8000196a:	1141                	addi	sp,sp,-16
    8000196c:	e406                	sd	ra,8(sp)
    8000196e:	e022                	sd	s0,0(sp)
    80001970:	0800                	addi	s0,sp,16
    panic("Empty queue");
    80001972:	00007517          	auipc	a0,0x7
    80001976:	87650513          	addi	a0,a0,-1930 # 800081e8 <digits+0x1a8>
    8000197a:	fffff097          	auipc	ra,0xfffff
    8000197e:	bca080e7          	jalr	-1078(ra) # 80000544 <panic>
  if (queues[idx].front == NPROC + 1) queues[idx].front = 0;
    80001982:	21800693          	li	a3,536
    80001986:	02d78633          	mul	a2,a5,a3
    8000198a:	00010697          	auipc	a3,0x10
    8000198e:	81668693          	addi	a3,a3,-2026 # 800111a0 <queues>
    80001992:	96b2                	add	a3,a3,a2
    80001994:	0006a023          	sw	zero,0(a3)
    80001998:	bf6d                	j	80001952 <dequeue+0x50>

000000008000199a <delqueue>:
}

void delqueue(struct proc *process)
{
    8000199a:	1141                	addi	sp,sp,-16
    8000199c:	e422                	sd	s0,8(sp)
    8000199e:	0800                	addi	s0,sp,16
  int idx = process->priority;
    800019a0:	19852883          	lw	a7,408(a0)
  int curr = queues[idx].front;
    800019a4:	21800793          	li	a5,536
    800019a8:	02f88733          	mul	a4,a7,a5
    800019ac:	0000f797          	auipc	a5,0xf
    800019b0:	7f478793          	addi	a5,a5,2036 # 800111a0 <queues>
    800019b4:	97ba                	add	a5,a5,a4
    800019b6:	4394                	lw	a3,0(a5)
  while (curr != queues[idx].back)
    800019b8:	43c8                	lw	a0,4(a5)
    800019ba:	02a68f63          	beq	a3,a0,800019f8 <delqueue+0x5e>
  {
      //struct proc *temp = queues[idx].procs[curr];
    queues[idx].procs[curr] = queues[idx].procs[(curr + 1) % (NPROC + 1)];
    800019be:	04100813          	li	a6,65
    800019c2:	0000f597          	auipc	a1,0xf
    800019c6:	7de58593          	addi	a1,a1,2014 # 800111a0 <queues>
    800019ca:	00489613          	slli	a2,a7,0x4
    800019ce:	9646                	add	a2,a2,a7
    800019d0:	060a                	slli	a2,a2,0x2
    800019d2:	41160633          	sub	a2,a2,a7
    800019d6:	87b6                	mv	a5,a3
    800019d8:	2685                	addiw	a3,a3,1
    800019da:	0306e6bb          	remw	a3,a3,a6
    800019de:	00d60733          	add	a4,a2,a3
    800019e2:	0709                	addi	a4,a4,2
    800019e4:	070e                	slli	a4,a4,0x3
    800019e6:	972e                	add	a4,a4,a1
    800019e8:	6318                	ld	a4,0(a4)
    800019ea:	97b2                	add	a5,a5,a2
    800019ec:	0789                	addi	a5,a5,2
    800019ee:	078e                	slli	a5,a5,0x3
    800019f0:	97ae                	add	a5,a5,a1
    800019f2:	e398                	sd	a4,0(a5)
  while (curr != queues[idx].back)
    800019f4:	fea691e3          	bne	a3,a0,800019d6 <delqueue+0x3c>
      //queues[idx].procs[(curr + 1) % (NPROC + 1)] = temp;
    curr = (curr + 1) % (NPROC + 1);
  }

  queues[idx].back--;
    800019f8:	357d                	addiw	a0,a0,-1
    800019fa:	21800793          	li	a5,536
    800019fe:	02f88733          	mul	a4,a7,a5
    80001a02:	0000f797          	auipc	a5,0xf
    80001a06:	79e78793          	addi	a5,a5,1950 # 800111a0 <queues>
    80001a0a:	97ba                	add	a5,a5,a4
    80001a0c:	c3c8                	sw	a0,4(a5)
  queues[idx].length--;
    80001a0e:	4798                	lw	a4,8(a5)
    80001a10:	377d                	addiw	a4,a4,-1
    80001a12:	c798                	sw	a4,8(a5)
  if (queues[idx].back < 0)
    80001a14:	02051793          	slli	a5,a0,0x20
    80001a18:	0007c563          	bltz	a5,80001a22 <delqueue+0x88>
    queues[idx].back = NPROC;
}
    80001a1c:	6422                	ld	s0,8(sp)
    80001a1e:	0141                	addi	sp,sp,16
    80001a20:	8082                	ret
    queues[idx].back = NPROC;
    80001a22:	21800793          	li	a5,536
    80001a26:	02f888b3          	mul	a7,a7,a5
    80001a2a:	0000f797          	auipc	a5,0xf
    80001a2e:	77678793          	addi	a5,a5,1910 # 800111a0 <queues>
    80001a32:	98be                	add	a7,a7,a5
    80001a34:	04000793          	li	a5,64
    80001a38:	00f8a223          	sw	a5,4(a7)
}
    80001a3c:	b7c5                	j	80001a1c <delqueue+0x82>

0000000080001a3e <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001a3e:	7139                	addi	sp,sp,-64
    80001a40:	fc06                	sd	ra,56(sp)
    80001a42:	f822                	sd	s0,48(sp)
    80001a44:	f426                	sd	s1,40(sp)
    80001a46:	f04a                	sd	s2,32(sp)
    80001a48:	ec4e                	sd	s3,24(sp)
    80001a4a:	e852                	sd	s4,16(sp)
    80001a4c:	e456                	sd	s5,8(sp)
    80001a4e:	e05a                	sd	s6,0(sp)
    80001a50:	0080                	addi	s0,sp,64
    80001a52:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a54:	00010497          	auipc	s1,0x10
    80001a58:	1c448493          	addi	s1,s1,452 # 80011c18 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001a5c:	8b26                	mv	s6,s1
    80001a5e:	00006a97          	auipc	s5,0x6
    80001a62:	5a2a8a93          	addi	s5,s5,1442 # 80008000 <etext>
    80001a66:	04000937          	lui	s2,0x4000
    80001a6a:	197d                	addi	s2,s2,-1
    80001a6c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a6e:	00017a17          	auipc	s4,0x17
    80001a72:	daaa0a13          	addi	s4,s4,-598 # 80018818 <tickslock>
    char *pa = kalloc();
    80001a76:	fffff097          	auipc	ra,0xfffff
    80001a7a:	084080e7          	jalr	132(ra) # 80000afa <kalloc>
    80001a7e:	862a                	mv	a2,a0
    if(pa == 0)
    80001a80:	c131                	beqz	a0,80001ac4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001a82:	416485b3          	sub	a1,s1,s6
    80001a86:	8591                	srai	a1,a1,0x4
    80001a88:	000ab783          	ld	a5,0(s5)
    80001a8c:	02f585b3          	mul	a1,a1,a5
    80001a90:	2585                	addiw	a1,a1,1
    80001a92:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a96:	4719                	li	a4,6
    80001a98:	6685                	lui	a3,0x1
    80001a9a:	40b905b3          	sub	a1,s2,a1
    80001a9e:	854e                	mv	a0,s3
    80001aa0:	fffff097          	auipc	ra,0xfffff
    80001aa4:	6ba080e7          	jalr	1722(ra) # 8000115a <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001aa8:	1b048493          	addi	s1,s1,432
    80001aac:	fd4495e3          	bne	s1,s4,80001a76 <proc_mapstacks+0x38>
  }
}
    80001ab0:	70e2                	ld	ra,56(sp)
    80001ab2:	7442                	ld	s0,48(sp)
    80001ab4:	74a2                	ld	s1,40(sp)
    80001ab6:	7902                	ld	s2,32(sp)
    80001ab8:	69e2                	ld	s3,24(sp)
    80001aba:	6a42                	ld	s4,16(sp)
    80001abc:	6aa2                	ld	s5,8(sp)
    80001abe:	6b02                	ld	s6,0(sp)
    80001ac0:	6121                	addi	sp,sp,64
    80001ac2:	8082                	ret
      panic("kalloc");
    80001ac4:	00006517          	auipc	a0,0x6
    80001ac8:	73450513          	addi	a0,a0,1844 # 800081f8 <digits+0x1b8>
    80001acc:	fffff097          	auipc	ra,0xfffff
    80001ad0:	a78080e7          	jalr	-1416(ra) # 80000544 <panic>

0000000080001ad4 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001ad4:	7139                	addi	sp,sp,-64
    80001ad6:	fc06                	sd	ra,56(sp)
    80001ad8:	f822                	sd	s0,48(sp)
    80001ada:	f426                	sd	s1,40(sp)
    80001adc:	f04a                	sd	s2,32(sp)
    80001ade:	ec4e                	sd	s3,24(sp)
    80001ae0:	e852                	sd	s4,16(sp)
    80001ae2:	e456                	sd	s5,8(sp)
    80001ae4:	e05a                	sd	s6,0(sp)
    80001ae6:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001ae8:	00006597          	auipc	a1,0x6
    80001aec:	71858593          	addi	a1,a1,1816 # 80008200 <digits+0x1c0>
    80001af0:	0000f517          	auipc	a0,0xf
    80001af4:	28050513          	addi	a0,a0,640 # 80010d70 <pid_lock>
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	062080e7          	jalr	98(ra) # 80000b5a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001b00:	00006597          	auipc	a1,0x6
    80001b04:	70858593          	addi	a1,a1,1800 # 80008208 <digits+0x1c8>
    80001b08:	0000f517          	auipc	a0,0xf
    80001b0c:	28050513          	addi	a0,a0,640 # 80010d88 <wait_lock>
    80001b10:	fffff097          	auipc	ra,0xfffff
    80001b14:	04a080e7          	jalr	74(ra) # 80000b5a <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b18:	00010497          	auipc	s1,0x10
    80001b1c:	10048493          	addi	s1,s1,256 # 80011c18 <proc>
      initlock(&p->lock, "proc");
    80001b20:	00006b17          	auipc	s6,0x6
    80001b24:	6f8b0b13          	addi	s6,s6,1784 # 80008218 <digits+0x1d8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001b28:	8aa6                	mv	s5,s1
    80001b2a:	00006a17          	auipc	s4,0x6
    80001b2e:	4d6a0a13          	addi	s4,s4,1238 # 80008000 <etext>
    80001b32:	04000937          	lui	s2,0x4000
    80001b36:	197d                	addi	s2,s2,-1
    80001b38:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b3a:	00017997          	auipc	s3,0x17
    80001b3e:	cde98993          	addi	s3,s3,-802 # 80018818 <tickslock>
      initlock(&p->lock, "proc");
    80001b42:	85da                	mv	a1,s6
    80001b44:	8526                	mv	a0,s1
    80001b46:	fffff097          	auipc	ra,0xfffff
    80001b4a:	014080e7          	jalr	20(ra) # 80000b5a <initlock>
      p->state = UNUSED;
    80001b4e:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001b52:	415487b3          	sub	a5,s1,s5
    80001b56:	8791                	srai	a5,a5,0x4
    80001b58:	000a3703          	ld	a4,0(s4)
    80001b5c:	02e787b3          	mul	a5,a5,a4
    80001b60:	2785                	addiw	a5,a5,1
    80001b62:	00d7979b          	slliw	a5,a5,0xd
    80001b66:	40f907b3          	sub	a5,s2,a5
    80001b6a:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b6c:	1b048493          	addi	s1,s1,432
    80001b70:	fd3499e3          	bne	s1,s3,80001b42 <procinit+0x6e>
  }
}
    80001b74:	70e2                	ld	ra,56(sp)
    80001b76:	7442                	ld	s0,48(sp)
    80001b78:	74a2                	ld	s1,40(sp)
    80001b7a:	7902                	ld	s2,32(sp)
    80001b7c:	69e2                	ld	s3,24(sp)
    80001b7e:	6a42                	ld	s4,16(sp)
    80001b80:	6aa2                	ld	s5,8(sp)
    80001b82:	6b02                	ld	s6,0(sp)
    80001b84:	6121                	addi	sp,sp,64
    80001b86:	8082                	ret

0000000080001b88 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001b88:	1141                	addi	sp,sp,-16
    80001b8a:	e422                	sd	s0,8(sp)
    80001b8c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b8e:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001b90:	2501                	sext.w	a0,a0
    80001b92:	6422                	ld	s0,8(sp)
    80001b94:	0141                	addi	sp,sp,16
    80001b96:	8082                	ret

0000000080001b98 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001b98:	1141                	addi	sp,sp,-16
    80001b9a:	e422                	sd	s0,8(sp)
    80001b9c:	0800                	addi	s0,sp,16
    80001b9e:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001ba0:	2781                	sext.w	a5,a5
    80001ba2:	079e                	slli	a5,a5,0x7
  return c;
}
    80001ba4:	0000f517          	auipc	a0,0xf
    80001ba8:	1fc50513          	addi	a0,a0,508 # 80010da0 <cpus>
    80001bac:	953e                	add	a0,a0,a5
    80001bae:	6422                	ld	s0,8(sp)
    80001bb0:	0141                	addi	sp,sp,16
    80001bb2:	8082                	ret

0000000080001bb4 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001bb4:	1101                	addi	sp,sp,-32
    80001bb6:	ec06                	sd	ra,24(sp)
    80001bb8:	e822                	sd	s0,16(sp)
    80001bba:	e426                	sd	s1,8(sp)
    80001bbc:	1000                	addi	s0,sp,32
  push_off();
    80001bbe:	fffff097          	auipc	ra,0xfffff
    80001bc2:	fe0080e7          	jalr	-32(ra) # 80000b9e <push_off>
    80001bc6:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001bc8:	2781                	sext.w	a5,a5
    80001bca:	079e                	slli	a5,a5,0x7
    80001bcc:	0000f717          	auipc	a4,0xf
    80001bd0:	1a470713          	addi	a4,a4,420 # 80010d70 <pid_lock>
    80001bd4:	97ba                	add	a5,a5,a4
    80001bd6:	7b84                	ld	s1,48(a5)
  pop_off();
    80001bd8:	fffff097          	auipc	ra,0xfffff
    80001bdc:	066080e7          	jalr	102(ra) # 80000c3e <pop_off>
  return p;
}
    80001be0:	8526                	mv	a0,s1
    80001be2:	60e2                	ld	ra,24(sp)
    80001be4:	6442                	ld	s0,16(sp)
    80001be6:	64a2                	ld	s1,8(sp)
    80001be8:	6105                	addi	sp,sp,32
    80001bea:	8082                	ret

0000000080001bec <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001bec:	1141                	addi	sp,sp,-16
    80001bee:	e406                	sd	ra,8(sp)
    80001bf0:	e022                	sd	s0,0(sp)
    80001bf2:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001bf4:	00000097          	auipc	ra,0x0
    80001bf8:	fc0080e7          	jalr	-64(ra) # 80001bb4 <myproc>
    80001bfc:	fffff097          	auipc	ra,0xfffff
    80001c00:	0a2080e7          	jalr	162(ra) # 80000c9e <release>

  if (first) {
    80001c04:	00007797          	auipc	a5,0x7
    80001c08:	d7c7a783          	lw	a5,-644(a5) # 80008980 <first.1757>
    80001c0c:	eb89                	bnez	a5,80001c1e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001c0e:	00001097          	auipc	ra,0x1
    80001c12:	fb4080e7          	jalr	-76(ra) # 80002bc2 <usertrapret>
}
    80001c16:	60a2                	ld	ra,8(sp)
    80001c18:	6402                	ld	s0,0(sp)
    80001c1a:	0141                	addi	sp,sp,16
    80001c1c:	8082                	ret
    first = 0;
    80001c1e:	00007797          	auipc	a5,0x7
    80001c22:	d607a123          	sw	zero,-670(a5) # 80008980 <first.1757>
    fsinit(ROOTDEV);
    80001c26:	4505                	li	a0,1
    80001c28:	00002097          	auipc	ra,0x2
    80001c2c:	014080e7          	jalr	20(ra) # 80003c3c <fsinit>
    80001c30:	bff9                	j	80001c0e <forkret+0x22>

0000000080001c32 <allocpid>:
{
    80001c32:	1101                	addi	sp,sp,-32
    80001c34:	ec06                	sd	ra,24(sp)
    80001c36:	e822                	sd	s0,16(sp)
    80001c38:	e426                	sd	s1,8(sp)
    80001c3a:	e04a                	sd	s2,0(sp)
    80001c3c:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001c3e:	0000f917          	auipc	s2,0xf
    80001c42:	13290913          	addi	s2,s2,306 # 80010d70 <pid_lock>
    80001c46:	854a                	mv	a0,s2
    80001c48:	fffff097          	auipc	ra,0xfffff
    80001c4c:	fa2080e7          	jalr	-94(ra) # 80000bea <acquire>
  pid = nextpid;
    80001c50:	00007797          	auipc	a5,0x7
    80001c54:	d3478793          	addi	a5,a5,-716 # 80008984 <nextpid>
    80001c58:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c5a:	0014871b          	addiw	a4,s1,1
    80001c5e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c60:	854a                	mv	a0,s2
    80001c62:	fffff097          	auipc	ra,0xfffff
    80001c66:	03c080e7          	jalr	60(ra) # 80000c9e <release>
}
    80001c6a:	8526                	mv	a0,s1
    80001c6c:	60e2                	ld	ra,24(sp)
    80001c6e:	6442                	ld	s0,16(sp)
    80001c70:	64a2                	ld	s1,8(sp)
    80001c72:	6902                	ld	s2,0(sp)
    80001c74:	6105                	addi	sp,sp,32
    80001c76:	8082                	ret

0000000080001c78 <proc_pagetable>:
{
    80001c78:	1101                	addi	sp,sp,-32
    80001c7a:	ec06                	sd	ra,24(sp)
    80001c7c:	e822                	sd	s0,16(sp)
    80001c7e:	e426                	sd	s1,8(sp)
    80001c80:	e04a                	sd	s2,0(sp)
    80001c82:	1000                	addi	s0,sp,32
    80001c84:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c86:	fffff097          	auipc	ra,0xfffff
    80001c8a:	6be080e7          	jalr	1726(ra) # 80001344 <uvmcreate>
    80001c8e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001c90:	c121                	beqz	a0,80001cd0 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c92:	4729                	li	a4,10
    80001c94:	00005697          	auipc	a3,0x5
    80001c98:	36c68693          	addi	a3,a3,876 # 80007000 <_trampoline>
    80001c9c:	6605                	lui	a2,0x1
    80001c9e:	040005b7          	lui	a1,0x4000
    80001ca2:	15fd                	addi	a1,a1,-1
    80001ca4:	05b2                	slli	a1,a1,0xc
    80001ca6:	fffff097          	auipc	ra,0xfffff
    80001caa:	414080e7          	jalr	1044(ra) # 800010ba <mappages>
    80001cae:	02054863          	bltz	a0,80001cde <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001cb2:	4719                	li	a4,6
    80001cb4:	05893683          	ld	a3,88(s2)
    80001cb8:	6605                	lui	a2,0x1
    80001cba:	020005b7          	lui	a1,0x2000
    80001cbe:	15fd                	addi	a1,a1,-1
    80001cc0:	05b6                	slli	a1,a1,0xd
    80001cc2:	8526                	mv	a0,s1
    80001cc4:	fffff097          	auipc	ra,0xfffff
    80001cc8:	3f6080e7          	jalr	1014(ra) # 800010ba <mappages>
    80001ccc:	02054163          	bltz	a0,80001cee <proc_pagetable+0x76>
}
    80001cd0:	8526                	mv	a0,s1
    80001cd2:	60e2                	ld	ra,24(sp)
    80001cd4:	6442                	ld	s0,16(sp)
    80001cd6:	64a2                	ld	s1,8(sp)
    80001cd8:	6902                	ld	s2,0(sp)
    80001cda:	6105                	addi	sp,sp,32
    80001cdc:	8082                	ret
    uvmfree(pagetable, 0);
    80001cde:	4581                	li	a1,0
    80001ce0:	8526                	mv	a0,s1
    80001ce2:	00000097          	auipc	ra,0x0
    80001ce6:	866080e7          	jalr	-1946(ra) # 80001548 <uvmfree>
    return 0;
    80001cea:	4481                	li	s1,0
    80001cec:	b7d5                	j	80001cd0 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cee:	4681                	li	a3,0
    80001cf0:	4605                	li	a2,1
    80001cf2:	040005b7          	lui	a1,0x4000
    80001cf6:	15fd                	addi	a1,a1,-1
    80001cf8:	05b2                	slli	a1,a1,0xc
    80001cfa:	8526                	mv	a0,s1
    80001cfc:	fffff097          	auipc	ra,0xfffff
    80001d00:	584080e7          	jalr	1412(ra) # 80001280 <uvmunmap>
    uvmfree(pagetable, 0);
    80001d04:	4581                	li	a1,0
    80001d06:	8526                	mv	a0,s1
    80001d08:	00000097          	auipc	ra,0x0
    80001d0c:	840080e7          	jalr	-1984(ra) # 80001548 <uvmfree>
    return 0;
    80001d10:	4481                	li	s1,0
    80001d12:	bf7d                	j	80001cd0 <proc_pagetable+0x58>

0000000080001d14 <proc_freepagetable>:
{
    80001d14:	1101                	addi	sp,sp,-32
    80001d16:	ec06                	sd	ra,24(sp)
    80001d18:	e822                	sd	s0,16(sp)
    80001d1a:	e426                	sd	s1,8(sp)
    80001d1c:	e04a                	sd	s2,0(sp)
    80001d1e:	1000                	addi	s0,sp,32
    80001d20:	84aa                	mv	s1,a0
    80001d22:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d24:	4681                	li	a3,0
    80001d26:	4605                	li	a2,1
    80001d28:	040005b7          	lui	a1,0x4000
    80001d2c:	15fd                	addi	a1,a1,-1
    80001d2e:	05b2                	slli	a1,a1,0xc
    80001d30:	fffff097          	auipc	ra,0xfffff
    80001d34:	550080e7          	jalr	1360(ra) # 80001280 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d38:	4681                	li	a3,0
    80001d3a:	4605                	li	a2,1
    80001d3c:	020005b7          	lui	a1,0x2000
    80001d40:	15fd                	addi	a1,a1,-1
    80001d42:	05b6                	slli	a1,a1,0xd
    80001d44:	8526                	mv	a0,s1
    80001d46:	fffff097          	auipc	ra,0xfffff
    80001d4a:	53a080e7          	jalr	1338(ra) # 80001280 <uvmunmap>
  uvmfree(pagetable, sz);
    80001d4e:	85ca                	mv	a1,s2
    80001d50:	8526                	mv	a0,s1
    80001d52:	fffff097          	auipc	ra,0xfffff
    80001d56:	7f6080e7          	jalr	2038(ra) # 80001548 <uvmfree>
}
    80001d5a:	60e2                	ld	ra,24(sp)
    80001d5c:	6442                	ld	s0,16(sp)
    80001d5e:	64a2                	ld	s1,8(sp)
    80001d60:	6902                	ld	s2,0(sp)
    80001d62:	6105                	addi	sp,sp,32
    80001d64:	8082                	ret

0000000080001d66 <freeproc>:
{
    80001d66:	1101                	addi	sp,sp,-32
    80001d68:	ec06                	sd	ra,24(sp)
    80001d6a:	e822                	sd	s0,16(sp)
    80001d6c:	e426                	sd	s1,8(sp)
    80001d6e:	1000                	addi	s0,sp,32
    80001d70:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001d72:	6d28                	ld	a0,88(a0)
    80001d74:	c509                	beqz	a0,80001d7e <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001d76:	fffff097          	auipc	ra,0xfffff
    80001d7a:	c88080e7          	jalr	-888(ra) # 800009fe <kfree>
  p->trapframe = 0;
    80001d7e:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001d82:	68a8                	ld	a0,80(s1)
    80001d84:	c511                	beqz	a0,80001d90 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d86:	64ac                	ld	a1,72(s1)
    80001d88:	00000097          	auipc	ra,0x0
    80001d8c:	f8c080e7          	jalr	-116(ra) # 80001d14 <proc_freepagetable>
  p->pagetable = 0;
    80001d90:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001d94:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d98:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001d9c:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001da0:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001da4:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001da8:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001dac:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001db0:	0004ac23          	sw	zero,24(s1)
  p->etime = 0;
    80001db4:	1604a823          	sw	zero,368(s1)
  p->rtime = 0;
    80001db8:	1604a423          	sw	zero,360(s1)
  p->ctime = 0;
    80001dbc:	1604a623          	sw	zero,364(s1)
}
    80001dc0:	60e2                	ld	ra,24(sp)
    80001dc2:	6442                	ld	s0,16(sp)
    80001dc4:	64a2                	ld	s1,8(sp)
    80001dc6:	6105                	addi	sp,sp,32
    80001dc8:	8082                	ret

0000000080001dca <allocproc>:
{
    80001dca:	1101                	addi	sp,sp,-32
    80001dcc:	ec06                	sd	ra,24(sp)
    80001dce:	e822                	sd	s0,16(sp)
    80001dd0:	e426                	sd	s1,8(sp)
    80001dd2:	e04a                	sd	s2,0(sp)
    80001dd4:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001dd6:	00010497          	auipc	s1,0x10
    80001dda:	e4248493          	addi	s1,s1,-446 # 80011c18 <proc>
    80001dde:	00017917          	auipc	s2,0x17
    80001de2:	a3a90913          	addi	s2,s2,-1478 # 80018818 <tickslock>
    acquire(&p->lock);
    80001de6:	8526                	mv	a0,s1
    80001de8:	fffff097          	auipc	ra,0xfffff
    80001dec:	e02080e7          	jalr	-510(ra) # 80000bea <acquire>
    if(p->state == UNUSED) {
    80001df0:	4c9c                	lw	a5,24(s1)
    80001df2:	cf81                	beqz	a5,80001e0a <allocproc+0x40>
      release(&p->lock);
    80001df4:	8526                	mv	a0,s1
    80001df6:	fffff097          	auipc	ra,0xfffff
    80001dfa:	ea8080e7          	jalr	-344(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001dfe:	1b048493          	addi	s1,s1,432
    80001e02:	ff2492e3          	bne	s1,s2,80001de6 <allocproc+0x1c>
  return 0;
    80001e06:	4481                	li	s1,0
    80001e08:	a071                	j	80001e94 <allocproc+0xca>
  p->pid = allocpid();
    80001e0a:	00000097          	auipc	ra,0x0
    80001e0e:	e28080e7          	jalr	-472(ra) # 80001c32 <allocpid>
    80001e12:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001e14:	4785                	li	a5,1
    80001e16:	cc9c                	sw	a5,24(s1)
  p->tick_creation_time = ticks;
    80001e18:	00007797          	auipc	a5,0x7
    80001e1c:	ce87a783          	lw	a5,-792(a5) # 80008b00 <ticks>
    80001e20:	18f4a823          	sw	a5,400(s1)
  p->tickets = 10;
    80001e24:	47a9                	li	a5,10
    80001e26:	18f4aa23          	sw	a5,404(s1)
  p->priority = 0;
    80001e2a:	1804ac23          	sw	zero,408(s1)
  p->in_queue = 0;
    80001e2e:	1804ae23          	sw	zero,412(s1)
  p->curr_rtime = 0;
    80001e32:	1a04a023          	sw	zero,416(s1)
  p->curr_wtime = 0;
    80001e36:	1a04a223          	sw	zero,420(s1)
  p->itime = 0;
    80001e3a:	1a04a423          	sw	zero,424(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001e3e:	fffff097          	auipc	ra,0xfffff
    80001e42:	cbc080e7          	jalr	-836(ra) # 80000afa <kalloc>
    80001e46:	892a                	mv	s2,a0
    80001e48:	eca8                	sd	a0,88(s1)
    80001e4a:	cd21                	beqz	a0,80001ea2 <allocproc+0xd8>
  p->pagetable = proc_pagetable(p);
    80001e4c:	8526                	mv	a0,s1
    80001e4e:	00000097          	auipc	ra,0x0
    80001e52:	e2a080e7          	jalr	-470(ra) # 80001c78 <proc_pagetable>
    80001e56:	892a                	mv	s2,a0
    80001e58:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001e5a:	c125                	beqz	a0,80001eba <allocproc+0xf0>
  memset(&p->context, 0, sizeof(p->context));
    80001e5c:	07000613          	li	a2,112
    80001e60:	4581                	li	a1,0
    80001e62:	06048513          	addi	a0,s1,96
    80001e66:	fffff097          	auipc	ra,0xfffff
    80001e6a:	e80080e7          	jalr	-384(ra) # 80000ce6 <memset>
  p->context.ra = (uint64)forkret;
    80001e6e:	00000797          	auipc	a5,0x0
    80001e72:	d7e78793          	addi	a5,a5,-642 # 80001bec <forkret>
    80001e76:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e78:	60bc                	ld	a5,64(s1)
    80001e7a:	6705                	lui	a4,0x1
    80001e7c:	97ba                	add	a5,a5,a4
    80001e7e:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001e80:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001e84:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001e88:	00007797          	auipc	a5,0x7
    80001e8c:	c787a783          	lw	a5,-904(a5) # 80008b00 <ticks>
    80001e90:	16f4a623          	sw	a5,364(s1)
}
    80001e94:	8526                	mv	a0,s1
    80001e96:	60e2                	ld	ra,24(sp)
    80001e98:	6442                	ld	s0,16(sp)
    80001e9a:	64a2                	ld	s1,8(sp)
    80001e9c:	6902                	ld	s2,0(sp)
    80001e9e:	6105                	addi	sp,sp,32
    80001ea0:	8082                	ret
    freeproc(p);
    80001ea2:	8526                	mv	a0,s1
    80001ea4:	00000097          	auipc	ra,0x0
    80001ea8:	ec2080e7          	jalr	-318(ra) # 80001d66 <freeproc>
    release(&p->lock);
    80001eac:	8526                	mv	a0,s1
    80001eae:	fffff097          	auipc	ra,0xfffff
    80001eb2:	df0080e7          	jalr	-528(ra) # 80000c9e <release>
    return 0;
    80001eb6:	84ca                	mv	s1,s2
    80001eb8:	bff1                	j	80001e94 <allocproc+0xca>
    freeproc(p);
    80001eba:	8526                	mv	a0,s1
    80001ebc:	00000097          	auipc	ra,0x0
    80001ec0:	eaa080e7          	jalr	-342(ra) # 80001d66 <freeproc>
    release(&p->lock);
    80001ec4:	8526                	mv	a0,s1
    80001ec6:	fffff097          	auipc	ra,0xfffff
    80001eca:	dd8080e7          	jalr	-552(ra) # 80000c9e <release>
    return 0;
    80001ece:	84ca                	mv	s1,s2
    80001ed0:	b7d1                	j	80001e94 <allocproc+0xca>

0000000080001ed2 <userinit>:
{
    80001ed2:	1101                	addi	sp,sp,-32
    80001ed4:	ec06                	sd	ra,24(sp)
    80001ed6:	e822                	sd	s0,16(sp)
    80001ed8:	e426                	sd	s1,8(sp)
    80001eda:	1000                	addi	s0,sp,32
  p = allocproc();
    80001edc:	00000097          	auipc	ra,0x0
    80001ee0:	eee080e7          	jalr	-274(ra) # 80001dca <allocproc>
    80001ee4:	84aa                	mv	s1,a0
  initproc = p;
    80001ee6:	00007797          	auipc	a5,0x7
    80001eea:	c0a7b923          	sd	a0,-1006(a5) # 80008af8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001eee:	03400613          	li	a2,52
    80001ef2:	00007597          	auipc	a1,0x7
    80001ef6:	a9e58593          	addi	a1,a1,-1378 # 80008990 <initcode>
    80001efa:	6928                	ld	a0,80(a0)
    80001efc:	fffff097          	auipc	ra,0xfffff
    80001f00:	476080e7          	jalr	1142(ra) # 80001372 <uvmfirst>
  p->sz = PGSIZE;
    80001f04:	6785                	lui	a5,0x1
    80001f06:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001f08:	6cb8                	ld	a4,88(s1)
    80001f0a:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001f0e:	6cb8                	ld	a4,88(s1)
    80001f10:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f12:	4641                	li	a2,16
    80001f14:	00006597          	auipc	a1,0x6
    80001f18:	30c58593          	addi	a1,a1,780 # 80008220 <digits+0x1e0>
    80001f1c:	15848513          	addi	a0,s1,344
    80001f20:	fffff097          	auipc	ra,0xfffff
    80001f24:	f18080e7          	jalr	-232(ra) # 80000e38 <safestrcpy>
  p->cwd = namei("/");
    80001f28:	00006517          	auipc	a0,0x6
    80001f2c:	30850513          	addi	a0,a0,776 # 80008230 <digits+0x1f0>
    80001f30:	00002097          	auipc	ra,0x2
    80001f34:	72e080e7          	jalr	1838(ra) # 8000465e <namei>
    80001f38:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001f3c:	478d                	li	a5,3
    80001f3e:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001f40:	8526                	mv	a0,s1
    80001f42:	fffff097          	auipc	ra,0xfffff
    80001f46:	d5c080e7          	jalr	-676(ra) # 80000c9e <release>
}
    80001f4a:	60e2                	ld	ra,24(sp)
    80001f4c:	6442                	ld	s0,16(sp)
    80001f4e:	64a2                	ld	s1,8(sp)
    80001f50:	6105                	addi	sp,sp,32
    80001f52:	8082                	ret

0000000080001f54 <growproc>:
{
    80001f54:	1101                	addi	sp,sp,-32
    80001f56:	ec06                	sd	ra,24(sp)
    80001f58:	e822                	sd	s0,16(sp)
    80001f5a:	e426                	sd	s1,8(sp)
    80001f5c:	e04a                	sd	s2,0(sp)
    80001f5e:	1000                	addi	s0,sp,32
    80001f60:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001f62:	00000097          	auipc	ra,0x0
    80001f66:	c52080e7          	jalr	-942(ra) # 80001bb4 <myproc>
    80001f6a:	84aa                	mv	s1,a0
  sz = p->sz;
    80001f6c:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001f6e:	01204c63          	bgtz	s2,80001f86 <growproc+0x32>
  } else if(n < 0){
    80001f72:	02094663          	bltz	s2,80001f9e <growproc+0x4a>
  p->sz = sz;
    80001f76:	e4ac                	sd	a1,72(s1)
  return 0;
    80001f78:	4501                	li	a0,0
}
    80001f7a:	60e2                	ld	ra,24(sp)
    80001f7c:	6442                	ld	s0,16(sp)
    80001f7e:	64a2                	ld	s1,8(sp)
    80001f80:	6902                	ld	s2,0(sp)
    80001f82:	6105                	addi	sp,sp,32
    80001f84:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001f86:	4691                	li	a3,4
    80001f88:	00b90633          	add	a2,s2,a1
    80001f8c:	6928                	ld	a0,80(a0)
    80001f8e:	fffff097          	auipc	ra,0xfffff
    80001f92:	49e080e7          	jalr	1182(ra) # 8000142c <uvmalloc>
    80001f96:	85aa                	mv	a1,a0
    80001f98:	fd79                	bnez	a0,80001f76 <growproc+0x22>
      return -1;
    80001f9a:	557d                	li	a0,-1
    80001f9c:	bff9                	j	80001f7a <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f9e:	00b90633          	add	a2,s2,a1
    80001fa2:	6928                	ld	a0,80(a0)
    80001fa4:	fffff097          	auipc	ra,0xfffff
    80001fa8:	440080e7          	jalr	1088(ra) # 800013e4 <uvmdealloc>
    80001fac:	85aa                	mv	a1,a0
    80001fae:	b7e1                	j	80001f76 <growproc+0x22>

0000000080001fb0 <fork>:
{
    80001fb0:	7179                	addi	sp,sp,-48
    80001fb2:	f406                	sd	ra,40(sp)
    80001fb4:	f022                	sd	s0,32(sp)
    80001fb6:	ec26                	sd	s1,24(sp)
    80001fb8:	e84a                	sd	s2,16(sp)
    80001fba:	e44e                	sd	s3,8(sp)
    80001fbc:	e052                	sd	s4,0(sp)
    80001fbe:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fc0:	00000097          	auipc	ra,0x0
    80001fc4:	bf4080e7          	jalr	-1036(ra) # 80001bb4 <myproc>
    80001fc8:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001fca:	00000097          	auipc	ra,0x0
    80001fce:	e00080e7          	jalr	-512(ra) # 80001dca <allocproc>
    80001fd2:	10050f63          	beqz	a0,800020f0 <fork+0x140>
    80001fd6:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001fd8:	04893603          	ld	a2,72(s2)
    80001fdc:	692c                	ld	a1,80(a0)
    80001fde:	05093503          	ld	a0,80(s2)
    80001fe2:	fffff097          	auipc	ra,0xfffff
    80001fe6:	59e080e7          	jalr	1438(ra) # 80001580 <uvmcopy>
    80001fea:	04054a63          	bltz	a0,8000203e <fork+0x8e>
  np->sz = p->sz;
    80001fee:	04893783          	ld	a5,72(s2)
    80001ff2:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001ff6:	05893683          	ld	a3,88(s2)
    80001ffa:	87b6                	mv	a5,a3
    80001ffc:	0589b703          	ld	a4,88(s3)
    80002000:	12068693          	addi	a3,a3,288
    80002004:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002008:	6788                	ld	a0,8(a5)
    8000200a:	6b8c                	ld	a1,16(a5)
    8000200c:	6f90                	ld	a2,24(a5)
    8000200e:	01073023          	sd	a6,0(a4)
    80002012:	e708                	sd	a0,8(a4)
    80002014:	eb0c                	sd	a1,16(a4)
    80002016:	ef10                	sd	a2,24(a4)
    80002018:	02078793          	addi	a5,a5,32
    8000201c:	02070713          	addi	a4,a4,32
    80002020:	fed792e3          	bne	a5,a3,80002004 <fork+0x54>
  np->trace_flag = p->trace_flag;
    80002024:	17492783          	lw	a5,372(s2)
    80002028:	16f9aa23          	sw	a5,372(s3)
  np->trapframe->a0 = 0;
    8000202c:	0589b783          	ld	a5,88(s3)
    80002030:	0607b823          	sd	zero,112(a5)
    80002034:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80002038:	15000a13          	li	s4,336
    8000203c:	a03d                	j	8000206a <fork+0xba>
    freeproc(np);
    8000203e:	854e                	mv	a0,s3
    80002040:	00000097          	auipc	ra,0x0
    80002044:	d26080e7          	jalr	-730(ra) # 80001d66 <freeproc>
    release(&np->lock);
    80002048:	854e                	mv	a0,s3
    8000204a:	fffff097          	auipc	ra,0xfffff
    8000204e:	c54080e7          	jalr	-940(ra) # 80000c9e <release>
    return -1;
    80002052:	5a7d                	li	s4,-1
    80002054:	a069                	j	800020de <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    80002056:	00003097          	auipc	ra,0x3
    8000205a:	c9e080e7          	jalr	-866(ra) # 80004cf4 <filedup>
    8000205e:	009987b3          	add	a5,s3,s1
    80002062:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002064:	04a1                	addi	s1,s1,8
    80002066:	01448763          	beq	s1,s4,80002074 <fork+0xc4>
    if(p->ofile[i])
    8000206a:	009907b3          	add	a5,s2,s1
    8000206e:	6388                	ld	a0,0(a5)
    80002070:	f17d                	bnez	a0,80002056 <fork+0xa6>
    80002072:	bfcd                	j	80002064 <fork+0xb4>
  np->cwd = idup(p->cwd);
    80002074:	15093503          	ld	a0,336(s2)
    80002078:	00002097          	auipc	ra,0x2
    8000207c:	e02080e7          	jalr	-510(ra) # 80003e7a <idup>
    80002080:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002084:	4641                	li	a2,16
    80002086:	15890593          	addi	a1,s2,344
    8000208a:	15898513          	addi	a0,s3,344
    8000208e:	fffff097          	auipc	ra,0xfffff
    80002092:	daa080e7          	jalr	-598(ra) # 80000e38 <safestrcpy>
  pid = np->pid;
    80002096:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    8000209a:	854e                	mv	a0,s3
    8000209c:	fffff097          	auipc	ra,0xfffff
    800020a0:	c02080e7          	jalr	-1022(ra) # 80000c9e <release>
  acquire(&wait_lock);
    800020a4:	0000f497          	auipc	s1,0xf
    800020a8:	ce448493          	addi	s1,s1,-796 # 80010d88 <wait_lock>
    800020ac:	8526                	mv	a0,s1
    800020ae:	fffff097          	auipc	ra,0xfffff
    800020b2:	b3c080e7          	jalr	-1220(ra) # 80000bea <acquire>
  np->parent = p;
    800020b6:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    800020ba:	8526                	mv	a0,s1
    800020bc:	fffff097          	auipc	ra,0xfffff
    800020c0:	be2080e7          	jalr	-1054(ra) # 80000c9e <release>
  acquire(&np->lock);
    800020c4:	854e                	mv	a0,s3
    800020c6:	fffff097          	auipc	ra,0xfffff
    800020ca:	b24080e7          	jalr	-1244(ra) # 80000bea <acquire>
  np->state = RUNNABLE;
    800020ce:	478d                	li	a5,3
    800020d0:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    800020d4:	854e                	mv	a0,s3
    800020d6:	fffff097          	auipc	ra,0xfffff
    800020da:	bc8080e7          	jalr	-1080(ra) # 80000c9e <release>
}
    800020de:	8552                	mv	a0,s4
    800020e0:	70a2                	ld	ra,40(sp)
    800020e2:	7402                	ld	s0,32(sp)
    800020e4:	64e2                	ld	s1,24(sp)
    800020e6:	6942                	ld	s2,16(sp)
    800020e8:	69a2                	ld	s3,8(sp)
    800020ea:	6a02                	ld	s4,0(sp)
    800020ec:	6145                	addi	sp,sp,48
    800020ee:	8082                	ret
    return -1;
    800020f0:	5a7d                	li	s4,-1
    800020f2:	b7f5                	j	800020de <fork+0x12e>

00000000800020f4 <scheduler>:
{
    800020f4:	7175                	addi	sp,sp,-144
    800020f6:	e506                	sd	ra,136(sp)
    800020f8:	e122                	sd	s0,128(sp)
    800020fa:	fca6                	sd	s1,120(sp)
    800020fc:	f8ca                	sd	s2,112(sp)
    800020fe:	f4ce                	sd	s3,104(sp)
    80002100:	f0d2                	sd	s4,96(sp)
    80002102:	ecd6                	sd	s5,88(sp)
    80002104:	e8da                	sd	s6,80(sp)
    80002106:	e4de                	sd	s7,72(sp)
    80002108:	e0e2                	sd	s8,64(sp)
    8000210a:	fc66                	sd	s9,56(sp)
    8000210c:	f86a                	sd	s10,48(sp)
    8000210e:	f46e                	sd	s11,40(sp)
    80002110:	0900                	addi	s0,sp,144
    80002112:	8792                	mv	a5,tp
  int id = r_tp();
    80002114:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002116:	00779693          	slli	a3,a5,0x7
    8000211a:	0000f717          	auipc	a4,0xf
    8000211e:	c5670713          	addi	a4,a4,-938 # 80010d70 <pid_lock>
    80002122:	9736                	add	a4,a4,a3
    80002124:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &proc_to_run->context);
    80002128:	0000f717          	auipc	a4,0xf
    8000212c:	c8070713          	addi	a4,a4,-896 # 80010da8 <cpus+0x8>
    80002130:	9736                	add	a4,a4,a3
    80002132:	f8e43023          	sd	a4,-128(s0)
          p->in_queue = 1;
    80002136:	4d85                	li	s11,1
      for (p = proc; p < &proc[NPROC]; p++)
    80002138:	00016a97          	auipc	s5,0x16
    8000213c:	6e0a8a93          	addi	s5,s5,1760 # 80018818 <tickslock>
          p = queues[i].procs[queues[i].front];
    80002140:	0000fc17          	auipc	s8,0xf
    80002144:	060c0c13          	addi	s8,s8,96 # 800111a0 <queues>
        c->proc = proc_to_run;
    80002148:	0000f717          	auipc	a4,0xf
    8000214c:	c2870713          	addi	a4,a4,-984 # 80010d70 <pid_lock>
    80002150:	00d707b3          	add	a5,a4,a3
    80002154:	f6f43c23          	sd	a5,-136(s0)
    80002158:	a841                	j	800021e8 <scheduler+0xf4>
          enqueue(p);
    8000215a:	8526                	mv	a0,s1
    8000215c:	fffff097          	auipc	ra,0xfffff
    80002160:	6f4080e7          	jalr	1780(ra) # 80001850 <enqueue>
          p->curr_rtime = 0;
    80002164:	1a04a023          	sw	zero,416(s1)
          p->curr_wtime = 0;
    80002168:	1a04a223          	sw	zero,420(s1)
          p->in_queue = 1;
    8000216c:	19b4ae23          	sw	s11,412(s1)
        release(&p->lock);
    80002170:	8526                	mv	a0,s1
    80002172:	fffff097          	auipc	ra,0xfffff
    80002176:	b2c080e7          	jalr	-1236(ra) # 80000c9e <release>
      for (p = proc; p < &proc[NPROC]; p++)
    8000217a:	1b048493          	addi	s1,s1,432
    8000217e:	01548e63          	beq	s1,s5,8000219a <scheduler+0xa6>
        acquire(&p->lock);
    80002182:	8526                	mv	a0,s1
    80002184:	fffff097          	auipc	ra,0xfffff
    80002188:	a66080e7          	jalr	-1434(ra) # 80000bea <acquire>
        if (p->state == RUNNABLE && p->in_queue == 0)
    8000218c:	4c9c                	lw	a5,24(s1)
    8000218e:	ff3791e3          	bne	a5,s3,80002170 <scheduler+0x7c>
    80002192:	19c4a783          	lw	a5,412(s1)
    80002196:	ffe9                	bnez	a5,80002170 <scheduler+0x7c>
    80002198:	b7c9                	j	8000215a <scheduler+0x66>
    8000219a:	0000fd17          	auipc	s10,0xf
    8000219e:	00ed0d13          	addi	s10,s10,14 # 800111a8 <queues+0x8>
      for (int i = 0; i < 5; i++)
    800021a2:	4c81                	li	s9,0
    800021a4:	a0b5                	j	80002210 <scheduler+0x11c>
            p->itime = ticks;
    800021a6:	00007917          	auipc	s2,0x7
    800021aa:	95a90913          	addi	s2,s2,-1702 # 80008b00 <ticks>
    800021ae:	00092783          	lw	a5,0(s2)
    800021b2:	1af4a423          	sw	a5,424(s1)
        proc_to_run->state = RUNNING;
    800021b6:	4791                	li	a5,4
    800021b8:	cc9c                	sw	a5,24(s1)
        c->proc = proc_to_run;
    800021ba:	f7843983          	ld	s3,-136(s0)
    800021be:	0299b823          	sd	s1,48(s3)
        swtch(&c->context, &proc_to_run->context);
    800021c2:	06048593          	addi	a1,s1,96
    800021c6:	f8043503          	ld	a0,-128(s0)
    800021ca:	00001097          	auipc	ra,0x1
    800021ce:	94e080e7          	jalr	-1714(ra) # 80002b18 <swtch>
        c->proc = 0;
    800021d2:	0209b823          	sd	zero,48(s3)
        proc_to_run->itime = ticks;
    800021d6:	00092783          	lw	a5,0(s2)
    800021da:	1af4a423          	sw	a5,424(s1)
        release(&proc_to_run->lock);
    800021de:	8526                	mv	a0,s1
    800021e0:	fffff097          	auipc	ra,0xfffff
    800021e4:	abe080e7          	jalr	-1346(ra) # 80000c9e <release>
        if (p->state == RUNNABLE && p->in_queue == 0)
    800021e8:	498d                	li	s3,3
        for(int j = 0; j < queues[i].length; j++)
    800021ea:	f8043423          	sd	zero,-120(s0)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021ee:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021f2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800021f6:	10079073          	csrw	sstatus,a5
      for (p = proc; p < &proc[NPROC]; p++)
    800021fa:	00010497          	auipc	s1,0x10
    800021fe:	a1e48493          	addi	s1,s1,-1506 # 80011c18 <proc>
    80002202:	b741                	j	80002182 <scheduler+0x8e>
      for (int i = 0; i < 5; i++)
    80002204:	2c85                	addiw	s9,s9,1
    80002206:	218d0d13          	addi	s10,s10,536
    8000220a:	4795                	li	a5,5
    8000220c:	fefc81e3          	beq	s9,a5,800021ee <scheduler+0xfa>
        for(int j = 0; j < queues[i].length; j++)
    80002210:	8a6a                	mv	s4,s10
    80002212:	000d2783          	lw	a5,0(s10)
    80002216:	f8843903          	ld	s2,-120(s0)
    8000221a:	fef055e3          	blez	a5,80002204 <scheduler+0x110>
          p = queues[i].procs[queues[i].front];
    8000221e:	004c9b13          	slli	s6,s9,0x4
    80002222:	9b66                	add	s6,s6,s9
    80002224:	0b0a                	slli	s6,s6,0x2
    80002226:	419b0b33          	sub	s6,s6,s9
    8000222a:	ff8a2783          	lw	a5,-8(s4)
    8000222e:	97da                	add	a5,a5,s6
    80002230:	0789                	addi	a5,a5,2
    80002232:	078e                	slli	a5,a5,0x3
    80002234:	97e2                	add	a5,a5,s8
    80002236:	6384                	ld	s1,0(a5)
          acquire(&p->lock);
    80002238:	8526                	mv	a0,s1
    8000223a:	fffff097          	auipc	ra,0xfffff
    8000223e:	9b0080e7          	jalr	-1616(ra) # 80000bea <acquire>
          dequeue(p);  // clear out all the processes as it goes through all the levels
    80002242:	8526                	mv	a0,s1
    80002244:	fffff097          	auipc	ra,0xfffff
    80002248:	6be080e7          	jalr	1726(ra) # 80001902 <dequeue>
          p->in_queue = 0;
    8000224c:	1804ae23          	sw	zero,412(s1)
          if (p->state == RUNNABLE)
    80002250:	4c9c                	lw	a5,24(s1)
    80002252:	f5378ae3          	beq	a5,s3,800021a6 <scheduler+0xb2>
          release(&p->lock);
    80002256:	8526                	mv	a0,s1
    80002258:	fffff097          	auipc	ra,0xfffff
    8000225c:	a46080e7          	jalr	-1466(ra) # 80000c9e <release>
        for(int j = 0; j < queues[i].length; j++)
    80002260:	2905                	addiw	s2,s2,1
    80002262:	000a2783          	lw	a5,0(s4)
    80002266:	fcf942e3          	blt	s2,a5,8000222a <scheduler+0x136>
    8000226a:	bf69                	j	80002204 <scheduler+0x110>

000000008000226c <sched>:
{
    8000226c:	7179                	addi	sp,sp,-48
    8000226e:	f406                	sd	ra,40(sp)
    80002270:	f022                	sd	s0,32(sp)
    80002272:	ec26                	sd	s1,24(sp)
    80002274:	e84a                	sd	s2,16(sp)
    80002276:	e44e                	sd	s3,8(sp)
    80002278:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000227a:	00000097          	auipc	ra,0x0
    8000227e:	93a080e7          	jalr	-1734(ra) # 80001bb4 <myproc>
    80002282:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002284:	fffff097          	auipc	ra,0xfffff
    80002288:	8ec080e7          	jalr	-1812(ra) # 80000b70 <holding>
    8000228c:	c93d                	beqz	a0,80002302 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000228e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002290:	2781                	sext.w	a5,a5
    80002292:	079e                	slli	a5,a5,0x7
    80002294:	0000f717          	auipc	a4,0xf
    80002298:	adc70713          	addi	a4,a4,-1316 # 80010d70 <pid_lock>
    8000229c:	97ba                	add	a5,a5,a4
    8000229e:	0a87a703          	lw	a4,168(a5)
    800022a2:	4785                	li	a5,1
    800022a4:	06f71763          	bne	a4,a5,80002312 <sched+0xa6>
  if(p->state == RUNNING)
    800022a8:	4c98                	lw	a4,24(s1)
    800022aa:	4791                	li	a5,4
    800022ac:	06f70b63          	beq	a4,a5,80002322 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022b0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800022b4:	8b89                	andi	a5,a5,2
  if(intr_get())
    800022b6:	efb5                	bnez	a5,80002332 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022b8:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800022ba:	0000f917          	auipc	s2,0xf
    800022be:	ab690913          	addi	s2,s2,-1354 # 80010d70 <pid_lock>
    800022c2:	2781                	sext.w	a5,a5
    800022c4:	079e                	slli	a5,a5,0x7
    800022c6:	97ca                	add	a5,a5,s2
    800022c8:	0ac7a983          	lw	s3,172(a5)
    800022cc:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800022ce:	2781                	sext.w	a5,a5
    800022d0:	079e                	slli	a5,a5,0x7
    800022d2:	0000f597          	auipc	a1,0xf
    800022d6:	ad658593          	addi	a1,a1,-1322 # 80010da8 <cpus+0x8>
    800022da:	95be                	add	a1,a1,a5
    800022dc:	06048513          	addi	a0,s1,96
    800022e0:	00001097          	auipc	ra,0x1
    800022e4:	838080e7          	jalr	-1992(ra) # 80002b18 <swtch>
    800022e8:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800022ea:	2781                	sext.w	a5,a5
    800022ec:	079e                	slli	a5,a5,0x7
    800022ee:	97ca                	add	a5,a5,s2
    800022f0:	0b37a623          	sw	s3,172(a5)
}
    800022f4:	70a2                	ld	ra,40(sp)
    800022f6:	7402                	ld	s0,32(sp)
    800022f8:	64e2                	ld	s1,24(sp)
    800022fa:	6942                	ld	s2,16(sp)
    800022fc:	69a2                	ld	s3,8(sp)
    800022fe:	6145                	addi	sp,sp,48
    80002300:	8082                	ret
    panic("sched p->lock");
    80002302:	00006517          	auipc	a0,0x6
    80002306:	f3650513          	addi	a0,a0,-202 # 80008238 <digits+0x1f8>
    8000230a:	ffffe097          	auipc	ra,0xffffe
    8000230e:	23a080e7          	jalr	570(ra) # 80000544 <panic>
    panic("sched locks");
    80002312:	00006517          	auipc	a0,0x6
    80002316:	f3650513          	addi	a0,a0,-202 # 80008248 <digits+0x208>
    8000231a:	ffffe097          	auipc	ra,0xffffe
    8000231e:	22a080e7          	jalr	554(ra) # 80000544 <panic>
    panic("sched running");
    80002322:	00006517          	auipc	a0,0x6
    80002326:	f3650513          	addi	a0,a0,-202 # 80008258 <digits+0x218>
    8000232a:	ffffe097          	auipc	ra,0xffffe
    8000232e:	21a080e7          	jalr	538(ra) # 80000544 <panic>
    panic("sched interruptible");
    80002332:	00006517          	auipc	a0,0x6
    80002336:	f3650513          	addi	a0,a0,-202 # 80008268 <digits+0x228>
    8000233a:	ffffe097          	auipc	ra,0xffffe
    8000233e:	20a080e7          	jalr	522(ra) # 80000544 <panic>

0000000080002342 <yield>:
{
    80002342:	1101                	addi	sp,sp,-32
    80002344:	ec06                	sd	ra,24(sp)
    80002346:	e822                	sd	s0,16(sp)
    80002348:	e426                	sd	s1,8(sp)
    8000234a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000234c:	00000097          	auipc	ra,0x0
    80002350:	868080e7          	jalr	-1944(ra) # 80001bb4 <myproc>
    80002354:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002356:	fffff097          	auipc	ra,0xfffff
    8000235a:	894080e7          	jalr	-1900(ra) # 80000bea <acquire>
  p->state = RUNNABLE;
    8000235e:	478d                	li	a5,3
    80002360:	cc9c                	sw	a5,24(s1)
  sched();
    80002362:	00000097          	auipc	ra,0x0
    80002366:	f0a080e7          	jalr	-246(ra) # 8000226c <sched>
  release(&p->lock);
    8000236a:	8526                	mv	a0,s1
    8000236c:	fffff097          	auipc	ra,0xfffff
    80002370:	932080e7          	jalr	-1742(ra) # 80000c9e <release>
}
    80002374:	60e2                	ld	ra,24(sp)
    80002376:	6442                	ld	s0,16(sp)
    80002378:	64a2                	ld	s1,8(sp)
    8000237a:	6105                	addi	sp,sp,32
    8000237c:	8082                	ret

000000008000237e <update_time>:
{
    8000237e:	715d                	addi	sp,sp,-80
    80002380:	e486                	sd	ra,72(sp)
    80002382:	e0a2                	sd	s0,64(sp)
    80002384:	fc26                	sd	s1,56(sp)
    80002386:	f84a                	sd	s2,48(sp)
    80002388:	f44e                	sd	s3,40(sp)
    8000238a:	f052                	sd	s4,32(sp)
    8000238c:	ec56                	sd	s5,24(sp)
    8000238e:	e85a                	sd	s6,16(sp)
    80002390:	e45e                	sd	s7,8(sp)
    80002392:	0880                	addi	s0,sp,80
  for(p = proc; p < &proc[NPROC]; p++){
    80002394:	00010497          	auipc	s1,0x10
    80002398:	88448493          	addi	s1,s1,-1916 # 80011c18 <proc>
    if(p->state == RUNNING) {
    8000239c:	4991                	li	s3,4
    else if(p->state == RUNNABLE) {
    8000239e:	4a0d                	li	s4,3
    if(ticks - p->itime >= 8 && p->state == RUNNABLE) {
    800023a0:	00006a97          	auipc	s5,0x6
    800023a4:	760a8a93          	addi	s5,s5,1888 # 80008b00 <ticks>
    800023a8:	4b1d                	li	s6,7
      printf("%d %d\n",ticks-p->itime, p->curr_wtime);
    800023aa:	00006b97          	auipc	s7,0x6
    800023ae:	ed6b8b93          	addi	s7,s7,-298 # 80008280 <digits+0x240>
  for(p = proc; p < &proc[NPROC]; p++){
    800023b2:	00016917          	auipc	s2,0x16
    800023b6:	46690913          	addi	s2,s2,1126 # 80018818 <tickslock>
    800023ba:	a025                	j	800023e2 <update_time+0x64>
      p->curr_rtime++;
    800023bc:	1a04a783          	lw	a5,416(s1)
    800023c0:	2785                	addiw	a5,a5,1
    800023c2:	1af4a023          	sw	a5,416(s1)
      p->rtime++;
    800023c6:	1684a783          	lw	a5,360(s1)
    800023ca:	2785                	addiw	a5,a5,1
    800023cc:	16f4a423          	sw	a5,360(s1)
    release(&p->lock);
    800023d0:	8526                	mv	a0,s1
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	8cc080e7          	jalr	-1844(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023da:	1b048493          	addi	s1,s1,432
    800023de:	07248563          	beq	s1,s2,80002448 <update_time+0xca>
    acquire(&p->lock);
    800023e2:	8526                	mv	a0,s1
    800023e4:	fffff097          	auipc	ra,0xfffff
    800023e8:	806080e7          	jalr	-2042(ra) # 80000bea <acquire>
    if(p->state == RUNNING) {
    800023ec:	4c9c                	lw	a5,24(s1)
    800023ee:	fd3787e3          	beq	a5,s3,800023bc <update_time+0x3e>
    else if(p->state == RUNNABLE) {
    800023f2:	fd479fe3          	bne	a5,s4,800023d0 <update_time+0x52>
      p->curr_wtime++;
    800023f6:	1a44a783          	lw	a5,420(s1)
    800023fa:	2785                	addiw	a5,a5,1
    800023fc:	0007861b          	sext.w	a2,a5
    80002400:	1af4a223          	sw	a5,420(s1)
    if(ticks - p->itime >= 8 && p->state == RUNNABLE) {
    80002404:	000aa583          	lw	a1,0(s5)
    80002408:	1a84a783          	lw	a5,424(s1)
    8000240c:	9d9d                	subw	a1,a1,a5
    8000240e:	fcbb71e3          	bgeu	s6,a1,800023d0 <update_time+0x52>
      printf("%d %d\n",ticks-p->itime, p->curr_wtime);
    80002412:	855e                	mv	a0,s7
    80002414:	ffffe097          	auipc	ra,0xffffe
    80002418:	17a080e7          	jalr	378(ra) # 8000058e <printf>
      if(p->in_queue != 0) {
    8000241c:	19c4a783          	lw	a5,412(s1)
    80002420:	eb81                	bnez	a5,80002430 <update_time+0xb2>
      if(p->priority != 0) {
    80002422:	1984a783          	lw	a5,408(s1)
    80002426:	d7cd                	beqz	a5,800023d0 <update_time+0x52>
        p->priority--;
    80002428:	37fd                	addiw	a5,a5,-1
    8000242a:	18f4ac23          	sw	a5,408(s1)
    8000242e:	b74d                	j	800023d0 <update_time+0x52>
        p->itime = ticks;
    80002430:	000aa783          	lw	a5,0(s5)
    80002434:	1af4a423          	sw	a5,424(s1)
        delqueue(p);
    80002438:	8526                	mv	a0,s1
    8000243a:	fffff097          	auipc	ra,0xfffff
    8000243e:	560080e7          	jalr	1376(ra) # 8000199a <delqueue>
        p->in_queue = 0;
    80002442:	1804ae23          	sw	zero,412(s1)
    80002446:	bff1                	j	80002422 <update_time+0xa4>
}
    80002448:	60a6                	ld	ra,72(sp)
    8000244a:	6406                	ld	s0,64(sp)
    8000244c:	74e2                	ld	s1,56(sp)
    8000244e:	7942                	ld	s2,48(sp)
    80002450:	79a2                	ld	s3,40(sp)
    80002452:	7a02                	ld	s4,32(sp)
    80002454:	6ae2                	ld	s5,24(sp)
    80002456:	6b42                	ld	s6,16(sp)
    80002458:	6ba2                	ld	s7,8(sp)
    8000245a:	6161                	addi	sp,sp,80
    8000245c:	8082                	ret

000000008000245e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000245e:	7179                	addi	sp,sp,-48
    80002460:	f406                	sd	ra,40(sp)
    80002462:	f022                	sd	s0,32(sp)
    80002464:	ec26                	sd	s1,24(sp)
    80002466:	e84a                	sd	s2,16(sp)
    80002468:	e44e                	sd	s3,8(sp)
    8000246a:	1800                	addi	s0,sp,48
    8000246c:	89aa                	mv	s3,a0
    8000246e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002470:	fffff097          	auipc	ra,0xfffff
    80002474:	744080e7          	jalr	1860(ra) # 80001bb4 <myproc>
    80002478:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000247a:	ffffe097          	auipc	ra,0xffffe
    8000247e:	770080e7          	jalr	1904(ra) # 80000bea <acquire>
  release(lk);
    80002482:	854a                	mv	a0,s2
    80002484:	fffff097          	auipc	ra,0xfffff
    80002488:	81a080e7          	jalr	-2022(ra) # 80000c9e <release>

  // Go to sleep.
  p->chan = chan;
    8000248c:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002490:	4789                	li	a5,2
    80002492:	cc9c                	sw	a5,24(s1)

  sched();
    80002494:	00000097          	auipc	ra,0x0
    80002498:	dd8080e7          	jalr	-552(ra) # 8000226c <sched>

  // Tidy up.
  p->chan = 0;
    8000249c:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800024a0:	8526                	mv	a0,s1
    800024a2:	ffffe097          	auipc	ra,0xffffe
    800024a6:	7fc080e7          	jalr	2044(ra) # 80000c9e <release>
  acquire(lk);
    800024aa:	854a                	mv	a0,s2
    800024ac:	ffffe097          	auipc	ra,0xffffe
    800024b0:	73e080e7          	jalr	1854(ra) # 80000bea <acquire>
}
    800024b4:	70a2                	ld	ra,40(sp)
    800024b6:	7402                	ld	s0,32(sp)
    800024b8:	64e2                	ld	s1,24(sp)
    800024ba:	6942                	ld	s2,16(sp)
    800024bc:	69a2                	ld	s3,8(sp)
    800024be:	6145                	addi	sp,sp,48
    800024c0:	8082                	ret

00000000800024c2 <waitx>:
{
    800024c2:	711d                	addi	sp,sp,-96
    800024c4:	ec86                	sd	ra,88(sp)
    800024c6:	e8a2                	sd	s0,80(sp)
    800024c8:	e4a6                	sd	s1,72(sp)
    800024ca:	e0ca                	sd	s2,64(sp)
    800024cc:	fc4e                	sd	s3,56(sp)
    800024ce:	f852                	sd	s4,48(sp)
    800024d0:	f456                	sd	s5,40(sp)
    800024d2:	f05a                	sd	s6,32(sp)
    800024d4:	ec5e                	sd	s7,24(sp)
    800024d6:	e862                	sd	s8,16(sp)
    800024d8:	e466                	sd	s9,8(sp)
    800024da:	e06a                	sd	s10,0(sp)
    800024dc:	1080                	addi	s0,sp,96
    800024de:	8b2a                	mv	s6,a0
    800024e0:	8bae                	mv	s7,a1
    800024e2:	8c32                	mv	s8,a2
  struct proc *p = myproc();
    800024e4:	fffff097          	auipc	ra,0xfffff
    800024e8:	6d0080e7          	jalr	1744(ra) # 80001bb4 <myproc>
    800024ec:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800024ee:	0000f517          	auipc	a0,0xf
    800024f2:	89a50513          	addi	a0,a0,-1894 # 80010d88 <wait_lock>
    800024f6:	ffffe097          	auipc	ra,0xffffe
    800024fa:	6f4080e7          	jalr	1780(ra) # 80000bea <acquire>
    havekids = 0;
    800024fe:	4c81                	li	s9,0
        if(np->state == ZOMBIE){
    80002500:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002502:	00016997          	auipc	s3,0x16
    80002506:	31698993          	addi	s3,s3,790 # 80018818 <tickslock>
        havekids = 1;
    8000250a:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000250c:	0000fd17          	auipc	s10,0xf
    80002510:	87cd0d13          	addi	s10,s10,-1924 # 80010d88 <wait_lock>
    havekids = 0;
    80002514:	8766                	mv	a4,s9
    for(np = proc; np < &proc[NPROC]; np++){
    80002516:	0000f497          	auipc	s1,0xf
    8000251a:	70248493          	addi	s1,s1,1794 # 80011c18 <proc>
    8000251e:	a059                	j	800025a4 <waitx+0xe2>
          pid = np->pid;
    80002520:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002524:	1684a703          	lw	a4,360(s1)
    80002528:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    8000252c:	16c4a783          	lw	a5,364(s1)
    80002530:	9f3d                	addw	a4,a4,a5
    80002532:	1704a783          	lw	a5,368(s1)
    80002536:	9f99                	subw	a5,a5,a4
    80002538:	00fba023          	sw	a5,0(s7)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000253c:	000b0e63          	beqz	s6,80002558 <waitx+0x96>
    80002540:	4691                	li	a3,4
    80002542:	02c48613          	addi	a2,s1,44
    80002546:	85da                	mv	a1,s6
    80002548:	05093503          	ld	a0,80(s2)
    8000254c:	fffff097          	auipc	ra,0xfffff
    80002550:	138080e7          	jalr	312(ra) # 80001684 <copyout>
    80002554:	02054563          	bltz	a0,8000257e <waitx+0xbc>
          freeproc(np);
    80002558:	8526                	mv	a0,s1
    8000255a:	00000097          	auipc	ra,0x0
    8000255e:	80c080e7          	jalr	-2036(ra) # 80001d66 <freeproc>
          release(&np->lock);
    80002562:	8526                	mv	a0,s1
    80002564:	ffffe097          	auipc	ra,0xffffe
    80002568:	73a080e7          	jalr	1850(ra) # 80000c9e <release>
          release(&wait_lock);
    8000256c:	0000f517          	auipc	a0,0xf
    80002570:	81c50513          	addi	a0,a0,-2020 # 80010d88 <wait_lock>
    80002574:	ffffe097          	auipc	ra,0xffffe
    80002578:	72a080e7          	jalr	1834(ra) # 80000c9e <release>
          return pid;
    8000257c:	a09d                	j	800025e2 <waitx+0x120>
            release(&np->lock);
    8000257e:	8526                	mv	a0,s1
    80002580:	ffffe097          	auipc	ra,0xffffe
    80002584:	71e080e7          	jalr	1822(ra) # 80000c9e <release>
            release(&wait_lock);
    80002588:	0000f517          	auipc	a0,0xf
    8000258c:	80050513          	addi	a0,a0,-2048 # 80010d88 <wait_lock>
    80002590:	ffffe097          	auipc	ra,0xffffe
    80002594:	70e080e7          	jalr	1806(ra) # 80000c9e <release>
            return -1;
    80002598:	59fd                	li	s3,-1
    8000259a:	a0a1                	j	800025e2 <waitx+0x120>
    for(np = proc; np < &proc[NPROC]; np++){
    8000259c:	1b048493          	addi	s1,s1,432
    800025a0:	03348463          	beq	s1,s3,800025c8 <waitx+0x106>
      if(np->parent == p){
    800025a4:	7c9c                	ld	a5,56(s1)
    800025a6:	ff279be3          	bne	a5,s2,8000259c <waitx+0xda>
        acquire(&np->lock);
    800025aa:	8526                	mv	a0,s1
    800025ac:	ffffe097          	auipc	ra,0xffffe
    800025b0:	63e080e7          	jalr	1598(ra) # 80000bea <acquire>
        if(np->state == ZOMBIE){
    800025b4:	4c9c                	lw	a5,24(s1)
    800025b6:	f74785e3          	beq	a5,s4,80002520 <waitx+0x5e>
        release(&np->lock);
    800025ba:	8526                	mv	a0,s1
    800025bc:	ffffe097          	auipc	ra,0xffffe
    800025c0:	6e2080e7          	jalr	1762(ra) # 80000c9e <release>
        havekids = 1;
    800025c4:	8756                	mv	a4,s5
    800025c6:	bfd9                	j	8000259c <waitx+0xda>
    if(!havekids || p->killed){
    800025c8:	c701                	beqz	a4,800025d0 <waitx+0x10e>
    800025ca:	02892783          	lw	a5,40(s2)
    800025ce:	cb8d                	beqz	a5,80002600 <waitx+0x13e>
      release(&wait_lock);
    800025d0:	0000e517          	auipc	a0,0xe
    800025d4:	7b850513          	addi	a0,a0,1976 # 80010d88 <wait_lock>
    800025d8:	ffffe097          	auipc	ra,0xffffe
    800025dc:	6c6080e7          	jalr	1734(ra) # 80000c9e <release>
      return -1;
    800025e0:	59fd                	li	s3,-1
}
    800025e2:	854e                	mv	a0,s3
    800025e4:	60e6                	ld	ra,88(sp)
    800025e6:	6446                	ld	s0,80(sp)
    800025e8:	64a6                	ld	s1,72(sp)
    800025ea:	6906                	ld	s2,64(sp)
    800025ec:	79e2                	ld	s3,56(sp)
    800025ee:	7a42                	ld	s4,48(sp)
    800025f0:	7aa2                	ld	s5,40(sp)
    800025f2:	7b02                	ld	s6,32(sp)
    800025f4:	6be2                	ld	s7,24(sp)
    800025f6:	6c42                	ld	s8,16(sp)
    800025f8:	6ca2                	ld	s9,8(sp)
    800025fa:	6d02                	ld	s10,0(sp)
    800025fc:	6125                	addi	sp,sp,96
    800025fe:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002600:	85ea                	mv	a1,s10
    80002602:	854a                	mv	a0,s2
    80002604:	00000097          	auipc	ra,0x0
    80002608:	e5a080e7          	jalr	-422(ra) # 8000245e <sleep>
    havekids = 0;
    8000260c:	b721                	j	80002514 <waitx+0x52>

000000008000260e <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000260e:	7139                	addi	sp,sp,-64
    80002610:	fc06                	sd	ra,56(sp)
    80002612:	f822                	sd	s0,48(sp)
    80002614:	f426                	sd	s1,40(sp)
    80002616:	f04a                	sd	s2,32(sp)
    80002618:	ec4e                	sd	s3,24(sp)
    8000261a:	e852                	sd	s4,16(sp)
    8000261c:	e456                	sd	s5,8(sp)
    8000261e:	0080                	addi	s0,sp,64
    80002620:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002622:	0000f497          	auipc	s1,0xf
    80002626:	5f648493          	addi	s1,s1,1526 # 80011c18 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000262a:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000262c:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000262e:	00016917          	auipc	s2,0x16
    80002632:	1ea90913          	addi	s2,s2,490 # 80018818 <tickslock>
    80002636:	a821                	j	8000264e <wakeup+0x40>
        p->state = RUNNABLE;
    80002638:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    8000263c:	8526                	mv	a0,s1
    8000263e:	ffffe097          	auipc	ra,0xffffe
    80002642:	660080e7          	jalr	1632(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002646:	1b048493          	addi	s1,s1,432
    8000264a:	03248463          	beq	s1,s2,80002672 <wakeup+0x64>
    if(p != myproc()){
    8000264e:	fffff097          	auipc	ra,0xfffff
    80002652:	566080e7          	jalr	1382(ra) # 80001bb4 <myproc>
    80002656:	fea488e3          	beq	s1,a0,80002646 <wakeup+0x38>
      acquire(&p->lock);
    8000265a:	8526                	mv	a0,s1
    8000265c:	ffffe097          	auipc	ra,0xffffe
    80002660:	58e080e7          	jalr	1422(ra) # 80000bea <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002664:	4c9c                	lw	a5,24(s1)
    80002666:	fd379be3          	bne	a5,s3,8000263c <wakeup+0x2e>
    8000266a:	709c                	ld	a5,32(s1)
    8000266c:	fd4798e3          	bne	a5,s4,8000263c <wakeup+0x2e>
    80002670:	b7e1                	j	80002638 <wakeup+0x2a>
    }
  }
}
    80002672:	70e2                	ld	ra,56(sp)
    80002674:	7442                	ld	s0,48(sp)
    80002676:	74a2                	ld	s1,40(sp)
    80002678:	7902                	ld	s2,32(sp)
    8000267a:	69e2                	ld	s3,24(sp)
    8000267c:	6a42                	ld	s4,16(sp)
    8000267e:	6aa2                	ld	s5,8(sp)
    80002680:	6121                	addi	sp,sp,64
    80002682:	8082                	ret

0000000080002684 <reparent>:
{
    80002684:	7179                	addi	sp,sp,-48
    80002686:	f406                	sd	ra,40(sp)
    80002688:	f022                	sd	s0,32(sp)
    8000268a:	ec26                	sd	s1,24(sp)
    8000268c:	e84a                	sd	s2,16(sp)
    8000268e:	e44e                	sd	s3,8(sp)
    80002690:	e052                	sd	s4,0(sp)
    80002692:	1800                	addi	s0,sp,48
    80002694:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002696:	0000f497          	auipc	s1,0xf
    8000269a:	58248493          	addi	s1,s1,1410 # 80011c18 <proc>
      pp->parent = initproc;
    8000269e:	00006a17          	auipc	s4,0x6
    800026a2:	45aa0a13          	addi	s4,s4,1114 # 80008af8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800026a6:	00016997          	auipc	s3,0x16
    800026aa:	17298993          	addi	s3,s3,370 # 80018818 <tickslock>
    800026ae:	a029                	j	800026b8 <reparent+0x34>
    800026b0:	1b048493          	addi	s1,s1,432
    800026b4:	01348d63          	beq	s1,s3,800026ce <reparent+0x4a>
    if(pp->parent == p){
    800026b8:	7c9c                	ld	a5,56(s1)
    800026ba:	ff279be3          	bne	a5,s2,800026b0 <reparent+0x2c>
      pp->parent = initproc;
    800026be:	000a3503          	ld	a0,0(s4)
    800026c2:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800026c4:	00000097          	auipc	ra,0x0
    800026c8:	f4a080e7          	jalr	-182(ra) # 8000260e <wakeup>
    800026cc:	b7d5                	j	800026b0 <reparent+0x2c>
}
    800026ce:	70a2                	ld	ra,40(sp)
    800026d0:	7402                	ld	s0,32(sp)
    800026d2:	64e2                	ld	s1,24(sp)
    800026d4:	6942                	ld	s2,16(sp)
    800026d6:	69a2                	ld	s3,8(sp)
    800026d8:	6a02                	ld	s4,0(sp)
    800026da:	6145                	addi	sp,sp,48
    800026dc:	8082                	ret

00000000800026de <exit>:
{
    800026de:	7179                	addi	sp,sp,-48
    800026e0:	f406                	sd	ra,40(sp)
    800026e2:	f022                	sd	s0,32(sp)
    800026e4:	ec26                	sd	s1,24(sp)
    800026e6:	e84a                	sd	s2,16(sp)
    800026e8:	e44e                	sd	s3,8(sp)
    800026ea:	e052                	sd	s4,0(sp)
    800026ec:	1800                	addi	s0,sp,48
    800026ee:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800026f0:	fffff097          	auipc	ra,0xfffff
    800026f4:	4c4080e7          	jalr	1220(ra) # 80001bb4 <myproc>
    800026f8:	89aa                	mv	s3,a0
  if(p == initproc)
    800026fa:	00006797          	auipc	a5,0x6
    800026fe:	3fe7b783          	ld	a5,1022(a5) # 80008af8 <initproc>
    80002702:	0d050493          	addi	s1,a0,208
    80002706:	15050913          	addi	s2,a0,336
    8000270a:	02a79363          	bne	a5,a0,80002730 <exit+0x52>
    panic("init exiting");
    8000270e:	00006517          	auipc	a0,0x6
    80002712:	b7a50513          	addi	a0,a0,-1158 # 80008288 <digits+0x248>
    80002716:	ffffe097          	auipc	ra,0xffffe
    8000271a:	e2e080e7          	jalr	-466(ra) # 80000544 <panic>
      fileclose(f);
    8000271e:	00002097          	auipc	ra,0x2
    80002722:	628080e7          	jalr	1576(ra) # 80004d46 <fileclose>
      p->ofile[fd] = 0;
    80002726:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000272a:	04a1                	addi	s1,s1,8
    8000272c:	01248563          	beq	s1,s2,80002736 <exit+0x58>
    if(p->ofile[fd]){
    80002730:	6088                	ld	a0,0(s1)
    80002732:	f575                	bnez	a0,8000271e <exit+0x40>
    80002734:	bfdd                	j	8000272a <exit+0x4c>
  begin_op();
    80002736:	00002097          	auipc	ra,0x2
    8000273a:	144080e7          	jalr	324(ra) # 8000487a <begin_op>
  iput(p->cwd);
    8000273e:	1509b503          	ld	a0,336(s3)
    80002742:	00002097          	auipc	ra,0x2
    80002746:	930080e7          	jalr	-1744(ra) # 80004072 <iput>
  end_op();
    8000274a:	00002097          	auipc	ra,0x2
    8000274e:	1b0080e7          	jalr	432(ra) # 800048fa <end_op>
  p->cwd = 0;
    80002752:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002756:	0000e497          	auipc	s1,0xe
    8000275a:	63248493          	addi	s1,s1,1586 # 80010d88 <wait_lock>
    8000275e:	8526                	mv	a0,s1
    80002760:	ffffe097          	auipc	ra,0xffffe
    80002764:	48a080e7          	jalr	1162(ra) # 80000bea <acquire>
  reparent(p);
    80002768:	854e                	mv	a0,s3
    8000276a:	00000097          	auipc	ra,0x0
    8000276e:	f1a080e7          	jalr	-230(ra) # 80002684 <reparent>
  wakeup(p->parent);
    80002772:	0389b503          	ld	a0,56(s3)
    80002776:	00000097          	auipc	ra,0x0
    8000277a:	e98080e7          	jalr	-360(ra) # 8000260e <wakeup>
  acquire(&p->lock);
    8000277e:	854e                	mv	a0,s3
    80002780:	ffffe097          	auipc	ra,0xffffe
    80002784:	46a080e7          	jalr	1130(ra) # 80000bea <acquire>
  p->xstate = status;
    80002788:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000278c:	4795                	li	a5,5
    8000278e:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002792:	00006797          	auipc	a5,0x6
    80002796:	36e7a783          	lw	a5,878(a5) # 80008b00 <ticks>
    8000279a:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    8000279e:	8526                	mv	a0,s1
    800027a0:	ffffe097          	auipc	ra,0xffffe
    800027a4:	4fe080e7          	jalr	1278(ra) # 80000c9e <release>
  sched();
    800027a8:	00000097          	auipc	ra,0x0
    800027ac:	ac4080e7          	jalr	-1340(ra) # 8000226c <sched>
  panic("zombie exit");
    800027b0:	00006517          	auipc	a0,0x6
    800027b4:	ae850513          	addi	a0,a0,-1304 # 80008298 <digits+0x258>
    800027b8:	ffffe097          	auipc	ra,0xffffe
    800027bc:	d8c080e7          	jalr	-628(ra) # 80000544 <panic>

00000000800027c0 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800027c0:	7179                	addi	sp,sp,-48
    800027c2:	f406                	sd	ra,40(sp)
    800027c4:	f022                	sd	s0,32(sp)
    800027c6:	ec26                	sd	s1,24(sp)
    800027c8:	e84a                	sd	s2,16(sp)
    800027ca:	e44e                	sd	s3,8(sp)
    800027cc:	1800                	addi	s0,sp,48
    800027ce:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800027d0:	0000f497          	auipc	s1,0xf
    800027d4:	44848493          	addi	s1,s1,1096 # 80011c18 <proc>
    800027d8:	00016997          	auipc	s3,0x16
    800027dc:	04098993          	addi	s3,s3,64 # 80018818 <tickslock>
    acquire(&p->lock);
    800027e0:	8526                	mv	a0,s1
    800027e2:	ffffe097          	auipc	ra,0xffffe
    800027e6:	408080e7          	jalr	1032(ra) # 80000bea <acquire>
    if(p->pid == pid){
    800027ea:	589c                	lw	a5,48(s1)
    800027ec:	01278d63          	beq	a5,s2,80002806 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800027f0:	8526                	mv	a0,s1
    800027f2:	ffffe097          	auipc	ra,0xffffe
    800027f6:	4ac080e7          	jalr	1196(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800027fa:	1b048493          	addi	s1,s1,432
    800027fe:	ff3491e3          	bne	s1,s3,800027e0 <kill+0x20>
  }
  return -1;
    80002802:	557d                	li	a0,-1
    80002804:	a829                	j	8000281e <kill+0x5e>
      p->killed = 1;
    80002806:	4785                	li	a5,1
    80002808:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000280a:	4c98                	lw	a4,24(s1)
    8000280c:	4789                	li	a5,2
    8000280e:	00f70f63          	beq	a4,a5,8000282c <kill+0x6c>
      release(&p->lock);
    80002812:	8526                	mv	a0,s1
    80002814:	ffffe097          	auipc	ra,0xffffe
    80002818:	48a080e7          	jalr	1162(ra) # 80000c9e <release>
      return 0;
    8000281c:	4501                	li	a0,0
}
    8000281e:	70a2                	ld	ra,40(sp)
    80002820:	7402                	ld	s0,32(sp)
    80002822:	64e2                	ld	s1,24(sp)
    80002824:	6942                	ld	s2,16(sp)
    80002826:	69a2                	ld	s3,8(sp)
    80002828:	6145                	addi	sp,sp,48
    8000282a:	8082                	ret
        p->state = RUNNABLE;
    8000282c:	478d                	li	a5,3
    8000282e:	cc9c                	sw	a5,24(s1)
    80002830:	b7cd                	j	80002812 <kill+0x52>

0000000080002832 <setkilled>:

void
setkilled(struct proc *p)
{
    80002832:	1101                	addi	sp,sp,-32
    80002834:	ec06                	sd	ra,24(sp)
    80002836:	e822                	sd	s0,16(sp)
    80002838:	e426                	sd	s1,8(sp)
    8000283a:	1000                	addi	s0,sp,32
    8000283c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000283e:	ffffe097          	auipc	ra,0xffffe
    80002842:	3ac080e7          	jalr	940(ra) # 80000bea <acquire>
  p->killed = 1;
    80002846:	4785                	li	a5,1
    80002848:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000284a:	8526                	mv	a0,s1
    8000284c:	ffffe097          	auipc	ra,0xffffe
    80002850:	452080e7          	jalr	1106(ra) # 80000c9e <release>
}
    80002854:	60e2                	ld	ra,24(sp)
    80002856:	6442                	ld	s0,16(sp)
    80002858:	64a2                	ld	s1,8(sp)
    8000285a:	6105                	addi	sp,sp,32
    8000285c:	8082                	ret

000000008000285e <killed>:

int
killed(struct proc *p)
{
    8000285e:	1101                	addi	sp,sp,-32
    80002860:	ec06                	sd	ra,24(sp)
    80002862:	e822                	sd	s0,16(sp)
    80002864:	e426                	sd	s1,8(sp)
    80002866:	e04a                	sd	s2,0(sp)
    80002868:	1000                	addi	s0,sp,32
    8000286a:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    8000286c:	ffffe097          	auipc	ra,0xffffe
    80002870:	37e080e7          	jalr	894(ra) # 80000bea <acquire>
  k = p->killed;
    80002874:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002878:	8526                	mv	a0,s1
    8000287a:	ffffe097          	auipc	ra,0xffffe
    8000287e:	424080e7          	jalr	1060(ra) # 80000c9e <release>
  return k;
}
    80002882:	854a                	mv	a0,s2
    80002884:	60e2                	ld	ra,24(sp)
    80002886:	6442                	ld	s0,16(sp)
    80002888:	64a2                	ld	s1,8(sp)
    8000288a:	6902                	ld	s2,0(sp)
    8000288c:	6105                	addi	sp,sp,32
    8000288e:	8082                	ret

0000000080002890 <wait>:
{
    80002890:	715d                	addi	sp,sp,-80
    80002892:	e486                	sd	ra,72(sp)
    80002894:	e0a2                	sd	s0,64(sp)
    80002896:	fc26                	sd	s1,56(sp)
    80002898:	f84a                	sd	s2,48(sp)
    8000289a:	f44e                	sd	s3,40(sp)
    8000289c:	f052                	sd	s4,32(sp)
    8000289e:	ec56                	sd	s5,24(sp)
    800028a0:	e85a                	sd	s6,16(sp)
    800028a2:	e45e                	sd	s7,8(sp)
    800028a4:	e062                	sd	s8,0(sp)
    800028a6:	0880                	addi	s0,sp,80
    800028a8:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800028aa:	fffff097          	auipc	ra,0xfffff
    800028ae:	30a080e7          	jalr	778(ra) # 80001bb4 <myproc>
    800028b2:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800028b4:	0000e517          	auipc	a0,0xe
    800028b8:	4d450513          	addi	a0,a0,1236 # 80010d88 <wait_lock>
    800028bc:	ffffe097          	auipc	ra,0xffffe
    800028c0:	32e080e7          	jalr	814(ra) # 80000bea <acquire>
    havekids = 0;
    800028c4:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    800028c6:	4a15                	li	s4,5
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800028c8:	00016997          	auipc	s3,0x16
    800028cc:	f5098993          	addi	s3,s3,-176 # 80018818 <tickslock>
        havekids = 1;
    800028d0:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800028d2:	0000ec17          	auipc	s8,0xe
    800028d6:	4b6c0c13          	addi	s8,s8,1206 # 80010d88 <wait_lock>
    havekids = 0;
    800028da:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800028dc:	0000f497          	auipc	s1,0xf
    800028e0:	33c48493          	addi	s1,s1,828 # 80011c18 <proc>
    800028e4:	a0bd                	j	80002952 <wait+0xc2>
          pid = pp->pid;
    800028e6:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800028ea:	000b0e63          	beqz	s6,80002906 <wait+0x76>
    800028ee:	4691                	li	a3,4
    800028f0:	02c48613          	addi	a2,s1,44
    800028f4:	85da                	mv	a1,s6
    800028f6:	05093503          	ld	a0,80(s2)
    800028fa:	fffff097          	auipc	ra,0xfffff
    800028fe:	d8a080e7          	jalr	-630(ra) # 80001684 <copyout>
    80002902:	02054563          	bltz	a0,8000292c <wait+0x9c>
          freeproc(pp);
    80002906:	8526                	mv	a0,s1
    80002908:	fffff097          	auipc	ra,0xfffff
    8000290c:	45e080e7          	jalr	1118(ra) # 80001d66 <freeproc>
          release(&pp->lock);
    80002910:	8526                	mv	a0,s1
    80002912:	ffffe097          	auipc	ra,0xffffe
    80002916:	38c080e7          	jalr	908(ra) # 80000c9e <release>
          release(&wait_lock);
    8000291a:	0000e517          	auipc	a0,0xe
    8000291e:	46e50513          	addi	a0,a0,1134 # 80010d88 <wait_lock>
    80002922:	ffffe097          	auipc	ra,0xffffe
    80002926:	37c080e7          	jalr	892(ra) # 80000c9e <release>
          return pid;
    8000292a:	a0b5                	j	80002996 <wait+0x106>
            release(&pp->lock);
    8000292c:	8526                	mv	a0,s1
    8000292e:	ffffe097          	auipc	ra,0xffffe
    80002932:	370080e7          	jalr	880(ra) # 80000c9e <release>
            release(&wait_lock);
    80002936:	0000e517          	auipc	a0,0xe
    8000293a:	45250513          	addi	a0,a0,1106 # 80010d88 <wait_lock>
    8000293e:	ffffe097          	auipc	ra,0xffffe
    80002942:	360080e7          	jalr	864(ra) # 80000c9e <release>
            return -1;
    80002946:	59fd                	li	s3,-1
    80002948:	a0b9                	j	80002996 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000294a:	1b048493          	addi	s1,s1,432
    8000294e:	03348463          	beq	s1,s3,80002976 <wait+0xe6>
      if(pp->parent == p){
    80002952:	7c9c                	ld	a5,56(s1)
    80002954:	ff279be3          	bne	a5,s2,8000294a <wait+0xba>
        acquire(&pp->lock);
    80002958:	8526                	mv	a0,s1
    8000295a:	ffffe097          	auipc	ra,0xffffe
    8000295e:	290080e7          	jalr	656(ra) # 80000bea <acquire>
        if(pp->state == ZOMBIE){
    80002962:	4c9c                	lw	a5,24(s1)
    80002964:	f94781e3          	beq	a5,s4,800028e6 <wait+0x56>
        release(&pp->lock);
    80002968:	8526                	mv	a0,s1
    8000296a:	ffffe097          	auipc	ra,0xffffe
    8000296e:	334080e7          	jalr	820(ra) # 80000c9e <release>
        havekids = 1;
    80002972:	8756                	mv	a4,s5
    80002974:	bfd9                	j	8000294a <wait+0xba>
    if(!havekids || killed(p)){
    80002976:	c719                	beqz	a4,80002984 <wait+0xf4>
    80002978:	854a                	mv	a0,s2
    8000297a:	00000097          	auipc	ra,0x0
    8000297e:	ee4080e7          	jalr	-284(ra) # 8000285e <killed>
    80002982:	c51d                	beqz	a0,800029b0 <wait+0x120>
      release(&wait_lock);
    80002984:	0000e517          	auipc	a0,0xe
    80002988:	40450513          	addi	a0,a0,1028 # 80010d88 <wait_lock>
    8000298c:	ffffe097          	auipc	ra,0xffffe
    80002990:	312080e7          	jalr	786(ra) # 80000c9e <release>
      return -1;
    80002994:	59fd                	li	s3,-1
}
    80002996:	854e                	mv	a0,s3
    80002998:	60a6                	ld	ra,72(sp)
    8000299a:	6406                	ld	s0,64(sp)
    8000299c:	74e2                	ld	s1,56(sp)
    8000299e:	7942                	ld	s2,48(sp)
    800029a0:	79a2                	ld	s3,40(sp)
    800029a2:	7a02                	ld	s4,32(sp)
    800029a4:	6ae2                	ld	s5,24(sp)
    800029a6:	6b42                	ld	s6,16(sp)
    800029a8:	6ba2                	ld	s7,8(sp)
    800029aa:	6c02                	ld	s8,0(sp)
    800029ac:	6161                	addi	sp,sp,80
    800029ae:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800029b0:	85e2                	mv	a1,s8
    800029b2:	854a                	mv	a0,s2
    800029b4:	00000097          	auipc	ra,0x0
    800029b8:	aaa080e7          	jalr	-1366(ra) # 8000245e <sleep>
    havekids = 0;
    800029bc:	bf39                	j	800028da <wait+0x4a>

00000000800029be <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800029be:	7179                	addi	sp,sp,-48
    800029c0:	f406                	sd	ra,40(sp)
    800029c2:	f022                	sd	s0,32(sp)
    800029c4:	ec26                	sd	s1,24(sp)
    800029c6:	e84a                	sd	s2,16(sp)
    800029c8:	e44e                	sd	s3,8(sp)
    800029ca:	e052                	sd	s4,0(sp)
    800029cc:	1800                	addi	s0,sp,48
    800029ce:	84aa                	mv	s1,a0
    800029d0:	892e                	mv	s2,a1
    800029d2:	89b2                	mv	s3,a2
    800029d4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800029d6:	fffff097          	auipc	ra,0xfffff
    800029da:	1de080e7          	jalr	478(ra) # 80001bb4 <myproc>
  if(user_dst){
    800029de:	c08d                	beqz	s1,80002a00 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800029e0:	86d2                	mv	a3,s4
    800029e2:	864e                	mv	a2,s3
    800029e4:	85ca                	mv	a1,s2
    800029e6:	6928                	ld	a0,80(a0)
    800029e8:	fffff097          	auipc	ra,0xfffff
    800029ec:	c9c080e7          	jalr	-868(ra) # 80001684 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800029f0:	70a2                	ld	ra,40(sp)
    800029f2:	7402                	ld	s0,32(sp)
    800029f4:	64e2                	ld	s1,24(sp)
    800029f6:	6942                	ld	s2,16(sp)
    800029f8:	69a2                	ld	s3,8(sp)
    800029fa:	6a02                	ld	s4,0(sp)
    800029fc:	6145                	addi	sp,sp,48
    800029fe:	8082                	ret
    memmove((char *)dst, src, len);
    80002a00:	000a061b          	sext.w	a2,s4
    80002a04:	85ce                	mv	a1,s3
    80002a06:	854a                	mv	a0,s2
    80002a08:	ffffe097          	auipc	ra,0xffffe
    80002a0c:	33e080e7          	jalr	830(ra) # 80000d46 <memmove>
    return 0;
    80002a10:	8526                	mv	a0,s1
    80002a12:	bff9                	j	800029f0 <either_copyout+0x32>

0000000080002a14 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002a14:	7179                	addi	sp,sp,-48
    80002a16:	f406                	sd	ra,40(sp)
    80002a18:	f022                	sd	s0,32(sp)
    80002a1a:	ec26                	sd	s1,24(sp)
    80002a1c:	e84a                	sd	s2,16(sp)
    80002a1e:	e44e                	sd	s3,8(sp)
    80002a20:	e052                	sd	s4,0(sp)
    80002a22:	1800                	addi	s0,sp,48
    80002a24:	892a                	mv	s2,a0
    80002a26:	84ae                	mv	s1,a1
    80002a28:	89b2                	mv	s3,a2
    80002a2a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a2c:	fffff097          	auipc	ra,0xfffff
    80002a30:	188080e7          	jalr	392(ra) # 80001bb4 <myproc>
  if(user_src){
    80002a34:	c08d                	beqz	s1,80002a56 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002a36:	86d2                	mv	a3,s4
    80002a38:	864e                	mv	a2,s3
    80002a3a:	85ca                	mv	a1,s2
    80002a3c:	6928                	ld	a0,80(a0)
    80002a3e:	fffff097          	auipc	ra,0xfffff
    80002a42:	cd2080e7          	jalr	-814(ra) # 80001710 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002a46:	70a2                	ld	ra,40(sp)
    80002a48:	7402                	ld	s0,32(sp)
    80002a4a:	64e2                	ld	s1,24(sp)
    80002a4c:	6942                	ld	s2,16(sp)
    80002a4e:	69a2                	ld	s3,8(sp)
    80002a50:	6a02                	ld	s4,0(sp)
    80002a52:	6145                	addi	sp,sp,48
    80002a54:	8082                	ret
    memmove(dst, (char*)src, len);
    80002a56:	000a061b          	sext.w	a2,s4
    80002a5a:	85ce                	mv	a1,s3
    80002a5c:	854a                	mv	a0,s2
    80002a5e:	ffffe097          	auipc	ra,0xffffe
    80002a62:	2e8080e7          	jalr	744(ra) # 80000d46 <memmove>
    return 0;
    80002a66:	8526                	mv	a0,s1
    80002a68:	bff9                	j	80002a46 <either_copyin+0x32>

0000000080002a6a <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002a6a:	715d                	addi	sp,sp,-80
    80002a6c:	e486                	sd	ra,72(sp)
    80002a6e:	e0a2                	sd	s0,64(sp)
    80002a70:	fc26                	sd	s1,56(sp)
    80002a72:	f84a                	sd	s2,48(sp)
    80002a74:	f44e                	sd	s3,40(sp)
    80002a76:	f052                	sd	s4,32(sp)
    80002a78:	ec56                	sd	s5,24(sp)
    80002a7a:	e85a                	sd	s6,16(sp)
    80002a7c:	e45e                	sd	s7,8(sp)
    80002a7e:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002a80:	00005517          	auipc	a0,0x5
    80002a84:	64850513          	addi	a0,a0,1608 # 800080c8 <digits+0x88>
    80002a88:	ffffe097          	auipc	ra,0xffffe
    80002a8c:	b06080e7          	jalr	-1274(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a90:	0000f497          	auipc	s1,0xf
    80002a94:	2e048493          	addi	s1,s1,736 # 80011d70 <proc+0x158>
    80002a98:	00016917          	auipc	s2,0x16
    80002a9c:	ed890913          	addi	s2,s2,-296 # 80018970 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002aa0:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002aa2:	00006997          	auipc	s3,0x6
    80002aa6:	80698993          	addi	s3,s3,-2042 # 800082a8 <digits+0x268>
    printf("%d %s %s", p->pid, state, p->name);
    80002aaa:	00006a97          	auipc	s5,0x6
    80002aae:	806a8a93          	addi	s5,s5,-2042 # 800082b0 <digits+0x270>
    printf("\n");
    80002ab2:	00005a17          	auipc	s4,0x5
    80002ab6:	616a0a13          	addi	s4,s4,1558 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002aba:	00006b97          	auipc	s7,0x6
    80002abe:	836b8b93          	addi	s7,s7,-1994 # 800082f0 <states.1801>
    80002ac2:	a00d                	j	80002ae4 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002ac4:	ed86a583          	lw	a1,-296(a3)
    80002ac8:	8556                	mv	a0,s5
    80002aca:	ffffe097          	auipc	ra,0xffffe
    80002ace:	ac4080e7          	jalr	-1340(ra) # 8000058e <printf>
    printf("\n");
    80002ad2:	8552                	mv	a0,s4
    80002ad4:	ffffe097          	auipc	ra,0xffffe
    80002ad8:	aba080e7          	jalr	-1350(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002adc:	1b048493          	addi	s1,s1,432
    80002ae0:	03248163          	beq	s1,s2,80002b02 <procdump+0x98>
    if(p->state == UNUSED)
    80002ae4:	86a6                	mv	a3,s1
    80002ae6:	ec04a783          	lw	a5,-320(s1)
    80002aea:	dbed                	beqz	a5,80002adc <procdump+0x72>
      state = "???";
    80002aec:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002aee:	fcfb6be3          	bltu	s6,a5,80002ac4 <procdump+0x5a>
    80002af2:	1782                	slli	a5,a5,0x20
    80002af4:	9381                	srli	a5,a5,0x20
    80002af6:	078e                	slli	a5,a5,0x3
    80002af8:	97de                	add	a5,a5,s7
    80002afa:	6390                	ld	a2,0(a5)
    80002afc:	f661                	bnez	a2,80002ac4 <procdump+0x5a>
      state = "???";
    80002afe:	864e                	mv	a2,s3
    80002b00:	b7d1                	j	80002ac4 <procdump+0x5a>
  }
}
    80002b02:	60a6                	ld	ra,72(sp)
    80002b04:	6406                	ld	s0,64(sp)
    80002b06:	74e2                	ld	s1,56(sp)
    80002b08:	7942                	ld	s2,48(sp)
    80002b0a:	79a2                	ld	s3,40(sp)
    80002b0c:	7a02                	ld	s4,32(sp)
    80002b0e:	6ae2                	ld	s5,24(sp)
    80002b10:	6b42                	ld	s6,16(sp)
    80002b12:	6ba2                	ld	s7,8(sp)
    80002b14:	6161                	addi	sp,sp,80
    80002b16:	8082                	ret

0000000080002b18 <swtch>:
    80002b18:	00153023          	sd	ra,0(a0)
    80002b1c:	00253423          	sd	sp,8(a0)
    80002b20:	e900                	sd	s0,16(a0)
    80002b22:	ed04                	sd	s1,24(a0)
    80002b24:	03253023          	sd	s2,32(a0)
    80002b28:	03353423          	sd	s3,40(a0)
    80002b2c:	03453823          	sd	s4,48(a0)
    80002b30:	03553c23          	sd	s5,56(a0)
    80002b34:	05653023          	sd	s6,64(a0)
    80002b38:	05753423          	sd	s7,72(a0)
    80002b3c:	05853823          	sd	s8,80(a0)
    80002b40:	05953c23          	sd	s9,88(a0)
    80002b44:	07a53023          	sd	s10,96(a0)
    80002b48:	07b53423          	sd	s11,104(a0)
    80002b4c:	0005b083          	ld	ra,0(a1)
    80002b50:	0085b103          	ld	sp,8(a1)
    80002b54:	6980                	ld	s0,16(a1)
    80002b56:	6d84                	ld	s1,24(a1)
    80002b58:	0205b903          	ld	s2,32(a1)
    80002b5c:	0285b983          	ld	s3,40(a1)
    80002b60:	0305ba03          	ld	s4,48(a1)
    80002b64:	0385ba83          	ld	s5,56(a1)
    80002b68:	0405bb03          	ld	s6,64(a1)
    80002b6c:	0485bb83          	ld	s7,72(a1)
    80002b70:	0505bc03          	ld	s8,80(a1)
    80002b74:	0585bc83          	ld	s9,88(a1)
    80002b78:	0605bd03          	ld	s10,96(a1)
    80002b7c:	0685bd83          	ld	s11,104(a1)
    80002b80:	8082                	ret

0000000080002b82 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002b82:	1141                	addi	sp,sp,-16
    80002b84:	e406                	sd	ra,8(sp)
    80002b86:	e022                	sd	s0,0(sp)
    80002b88:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002b8a:	00005597          	auipc	a1,0x5
    80002b8e:	79658593          	addi	a1,a1,1942 # 80008320 <states.1801+0x30>
    80002b92:	00016517          	auipc	a0,0x16
    80002b96:	c8650513          	addi	a0,a0,-890 # 80018818 <tickslock>
    80002b9a:	ffffe097          	auipc	ra,0xffffe
    80002b9e:	fc0080e7          	jalr	-64(ra) # 80000b5a <initlock>
}
    80002ba2:	60a2                	ld	ra,8(sp)
    80002ba4:	6402                	ld	s0,0(sp)
    80002ba6:	0141                	addi	sp,sp,16
    80002ba8:	8082                	ret

0000000080002baa <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002baa:	1141                	addi	sp,sp,-16
    80002bac:	e422                	sd	s0,8(sp)
    80002bae:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bb0:	00003797          	auipc	a5,0x3
    80002bb4:	7d078793          	addi	a5,a5,2000 # 80006380 <kernelvec>
    80002bb8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002bbc:	6422                	ld	s0,8(sp)
    80002bbe:	0141                	addi	sp,sp,16
    80002bc0:	8082                	ret

0000000080002bc2 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002bc2:	1141                	addi	sp,sp,-16
    80002bc4:	e406                	sd	ra,8(sp)
    80002bc6:	e022                	sd	s0,0(sp)
    80002bc8:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002bca:	fffff097          	auipc	ra,0xfffff
    80002bce:	fea080e7          	jalr	-22(ra) # 80001bb4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bd2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002bd6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bd8:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002bdc:	00004617          	auipc	a2,0x4
    80002be0:	42460613          	addi	a2,a2,1060 # 80007000 <_trampoline>
    80002be4:	00004697          	auipc	a3,0x4
    80002be8:	41c68693          	addi	a3,a3,1052 # 80007000 <_trampoline>
    80002bec:	8e91                	sub	a3,a3,a2
    80002bee:	040007b7          	lui	a5,0x4000
    80002bf2:	17fd                	addi	a5,a5,-1
    80002bf4:	07b2                	slli	a5,a5,0xc
    80002bf6:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bf8:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002bfc:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002bfe:	180026f3          	csrr	a3,satp
    80002c02:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c04:	6d38                	ld	a4,88(a0)
    80002c06:	6134                	ld	a3,64(a0)
    80002c08:	6585                	lui	a1,0x1
    80002c0a:	96ae                	add	a3,a3,a1
    80002c0c:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002c0e:	6d38                	ld	a4,88(a0)
    80002c10:	00000697          	auipc	a3,0x0
    80002c14:	13e68693          	addi	a3,a3,318 # 80002d4e <usertrap>
    80002c18:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002c1a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c1c:	8692                	mv	a3,tp
    80002c1e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c20:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c24:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c28:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c2c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002c30:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c32:	6f18                	ld	a4,24(a4)
    80002c34:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002c38:	6928                	ld	a0,80(a0)
    80002c3a:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002c3c:	00004717          	auipc	a4,0x4
    80002c40:	46070713          	addi	a4,a4,1120 # 8000709c <userret>
    80002c44:	8f11                	sub	a4,a4,a2
    80002c46:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002c48:	577d                	li	a4,-1
    80002c4a:	177e                	slli	a4,a4,0x3f
    80002c4c:	8d59                	or	a0,a0,a4
    80002c4e:	9782                	jalr	a5
}
    80002c50:	60a2                	ld	ra,8(sp)
    80002c52:	6402                	ld	s0,0(sp)
    80002c54:	0141                	addi	sp,sp,16
    80002c56:	8082                	ret

0000000080002c58 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002c58:	1101                	addi	sp,sp,-32
    80002c5a:	ec06                	sd	ra,24(sp)
    80002c5c:	e822                	sd	s0,16(sp)
    80002c5e:	e426                	sd	s1,8(sp)
    80002c60:	e04a                	sd	s2,0(sp)
    80002c62:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002c64:	00016917          	auipc	s2,0x16
    80002c68:	bb490913          	addi	s2,s2,-1100 # 80018818 <tickslock>
    80002c6c:	854a                	mv	a0,s2
    80002c6e:	ffffe097          	auipc	ra,0xffffe
    80002c72:	f7c080e7          	jalr	-132(ra) # 80000bea <acquire>
  ticks++;
    80002c76:	00006497          	auipc	s1,0x6
    80002c7a:	e8a48493          	addi	s1,s1,-374 # 80008b00 <ticks>
    80002c7e:	409c                	lw	a5,0(s1)
    80002c80:	2785                	addiw	a5,a5,1
    80002c82:	c09c                	sw	a5,0(s1)
  update_time();
    80002c84:	fffff097          	auipc	ra,0xfffff
    80002c88:	6fa080e7          	jalr	1786(ra) # 8000237e <update_time>
  wakeup(&ticks);
    80002c8c:	8526                	mv	a0,s1
    80002c8e:	00000097          	auipc	ra,0x0
    80002c92:	980080e7          	jalr	-1664(ra) # 8000260e <wakeup>
  release(&tickslock);
    80002c96:	854a                	mv	a0,s2
    80002c98:	ffffe097          	auipc	ra,0xffffe
    80002c9c:	006080e7          	jalr	6(ra) # 80000c9e <release>
}
    80002ca0:	60e2                	ld	ra,24(sp)
    80002ca2:	6442                	ld	s0,16(sp)
    80002ca4:	64a2                	ld	s1,8(sp)
    80002ca6:	6902                	ld	s2,0(sp)
    80002ca8:	6105                	addi	sp,sp,32
    80002caa:	8082                	ret

0000000080002cac <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002cac:	1101                	addi	sp,sp,-32
    80002cae:	ec06                	sd	ra,24(sp)
    80002cb0:	e822                	sd	s0,16(sp)
    80002cb2:	e426                	sd	s1,8(sp)
    80002cb4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cb6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002cba:	00074d63          	bltz	a4,80002cd4 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002cbe:	57fd                	li	a5,-1
    80002cc0:	17fe                	slli	a5,a5,0x3f
    80002cc2:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002cc4:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002cc6:	06f70363          	beq	a4,a5,80002d2c <devintr+0x80>
  }
}
    80002cca:	60e2                	ld	ra,24(sp)
    80002ccc:	6442                	ld	s0,16(sp)
    80002cce:	64a2                	ld	s1,8(sp)
    80002cd0:	6105                	addi	sp,sp,32
    80002cd2:	8082                	ret
     (scause & 0xff) == 9){
    80002cd4:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002cd8:	46a5                	li	a3,9
    80002cda:	fed792e3          	bne	a5,a3,80002cbe <devintr+0x12>
    int irq = plic_claim();
    80002cde:	00003097          	auipc	ra,0x3
    80002ce2:	7aa080e7          	jalr	1962(ra) # 80006488 <plic_claim>
    80002ce6:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002ce8:	47a9                	li	a5,10
    80002cea:	02f50763          	beq	a0,a5,80002d18 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002cee:	4785                	li	a5,1
    80002cf0:	02f50963          	beq	a0,a5,80002d22 <devintr+0x76>
    return 1;
    80002cf4:	4505                	li	a0,1
    } else if(irq){
    80002cf6:	d8f1                	beqz	s1,80002cca <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002cf8:	85a6                	mv	a1,s1
    80002cfa:	00005517          	auipc	a0,0x5
    80002cfe:	62e50513          	addi	a0,a0,1582 # 80008328 <states.1801+0x38>
    80002d02:	ffffe097          	auipc	ra,0xffffe
    80002d06:	88c080e7          	jalr	-1908(ra) # 8000058e <printf>
      plic_complete(irq);
    80002d0a:	8526                	mv	a0,s1
    80002d0c:	00003097          	auipc	ra,0x3
    80002d10:	7a0080e7          	jalr	1952(ra) # 800064ac <plic_complete>
    return 1;
    80002d14:	4505                	li	a0,1
    80002d16:	bf55                	j	80002cca <devintr+0x1e>
      uartintr();
    80002d18:	ffffe097          	auipc	ra,0xffffe
    80002d1c:	c96080e7          	jalr	-874(ra) # 800009ae <uartintr>
    80002d20:	b7ed                	j	80002d0a <devintr+0x5e>
      virtio_disk_intr();
    80002d22:	00004097          	auipc	ra,0x4
    80002d26:	cb4080e7          	jalr	-844(ra) # 800069d6 <virtio_disk_intr>
    80002d2a:	b7c5                	j	80002d0a <devintr+0x5e>
    if(cpuid() == 0){
    80002d2c:	fffff097          	auipc	ra,0xfffff
    80002d30:	e5c080e7          	jalr	-420(ra) # 80001b88 <cpuid>
    80002d34:	c901                	beqz	a0,80002d44 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002d36:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002d3a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002d3c:	14479073          	csrw	sip,a5
    return 2;
    80002d40:	4509                	li	a0,2
    80002d42:	b761                	j	80002cca <devintr+0x1e>
      clockintr();
    80002d44:	00000097          	auipc	ra,0x0
    80002d48:	f14080e7          	jalr	-236(ra) # 80002c58 <clockintr>
    80002d4c:	b7ed                	j	80002d36 <devintr+0x8a>

0000000080002d4e <usertrap>:
{
    80002d4e:	7179                	addi	sp,sp,-48
    80002d50:	f406                	sd	ra,40(sp)
    80002d52:	f022                	sd	s0,32(sp)
    80002d54:	ec26                	sd	s1,24(sp)
    80002d56:	e84a                	sd	s2,16(sp)
    80002d58:	e44e                	sd	s3,8(sp)
    80002d5a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d5c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002d60:	1007f793          	andi	a5,a5,256
    80002d64:	e3a5                	bnez	a5,80002dc4 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d66:	00003797          	auipc	a5,0x3
    80002d6a:	61a78793          	addi	a5,a5,1562 # 80006380 <kernelvec>
    80002d6e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002d72:	fffff097          	auipc	ra,0xfffff
    80002d76:	e42080e7          	jalr	-446(ra) # 80001bb4 <myproc>
    80002d7a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002d7c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d7e:	14102773          	csrr	a4,sepc
    80002d82:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d84:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002d88:	47a1                	li	a5,8
    80002d8a:	04f70563          	beq	a4,a5,80002dd4 <usertrap+0x86>
  } else if((which_dev = devintr()) != 0){
    80002d8e:	00000097          	auipc	ra,0x0
    80002d92:	f1e080e7          	jalr	-226(ra) # 80002cac <devintr>
    80002d96:	892a                	mv	s2,a0
    80002d98:	cd69                	beqz	a0,80002e72 <usertrap+0x124>
    if(which_dev == 2 && myproc()->interval) {
    80002d9a:	4789                	li	a5,2
    80002d9c:	06f50763          	beq	a0,a5,80002e0a <usertrap+0xbc>
  if(killed(p))
    80002da0:	8526                	mv	a0,s1
    80002da2:	00000097          	auipc	ra,0x0
    80002da6:	abc080e7          	jalr	-1348(ra) # 8000285e <killed>
    80002daa:	10051163          	bnez	a0,80002eac <usertrap+0x15e>
  usertrapret();
    80002dae:	00000097          	auipc	ra,0x0
    80002db2:	e14080e7          	jalr	-492(ra) # 80002bc2 <usertrapret>
}
    80002db6:	70a2                	ld	ra,40(sp)
    80002db8:	7402                	ld	s0,32(sp)
    80002dba:	64e2                	ld	s1,24(sp)
    80002dbc:	6942                	ld	s2,16(sp)
    80002dbe:	69a2                	ld	s3,8(sp)
    80002dc0:	6145                	addi	sp,sp,48
    80002dc2:	8082                	ret
    panic("usertrap: not from user mode");
    80002dc4:	00005517          	auipc	a0,0x5
    80002dc8:	58450513          	addi	a0,a0,1412 # 80008348 <states.1801+0x58>
    80002dcc:	ffffd097          	auipc	ra,0xffffd
    80002dd0:	778080e7          	jalr	1912(ra) # 80000544 <panic>
    if(killed(p))
    80002dd4:	00000097          	auipc	ra,0x0
    80002dd8:	a8a080e7          	jalr	-1398(ra) # 8000285e <killed>
    80002ddc:	e10d                	bnez	a0,80002dfe <usertrap+0xb0>
    p->trapframe->epc += 4;
    80002dde:	6cb8                	ld	a4,88(s1)
    80002de0:	6f1c                	ld	a5,24(a4)
    80002de2:	0791                	addi	a5,a5,4
    80002de4:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002de6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002dea:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002dee:	10079073          	csrw	sstatus,a5
    syscall();
    80002df2:	00000097          	auipc	ra,0x0
    80002df6:	404080e7          	jalr	1028(ra) # 800031f6 <syscall>
  int which_dev = 0;
    80002dfa:	4901                	li	s2,0
    80002dfc:	b755                	j	80002da0 <usertrap+0x52>
      exit(-1);
    80002dfe:	557d                	li	a0,-1
    80002e00:	00000097          	auipc	ra,0x0
    80002e04:	8de080e7          	jalr	-1826(ra) # 800026de <exit>
    80002e08:	bfd9                	j	80002dde <usertrap+0x90>
    if(which_dev == 2 && myproc()->interval) {
    80002e0a:	fffff097          	auipc	ra,0xfffff
    80002e0e:	daa080e7          	jalr	-598(ra) # 80001bb4 <myproc>
    80002e12:	17852783          	lw	a5,376(a0)
    80002e16:	ef89                	bnez	a5,80002e30 <usertrap+0xe2>
  if(killed(p))
    80002e18:	8526                	mv	a0,s1
    80002e1a:	00000097          	auipc	ra,0x0
    80002e1e:	a44080e7          	jalr	-1468(ra) # 8000285e <killed>
    80002e22:	cd49                	beqz	a0,80002ebc <usertrap+0x16e>
    exit(-1);
    80002e24:	557d                	li	a0,-1
    80002e26:	00000097          	auipc	ra,0x0
    80002e2a:	8b8080e7          	jalr	-1864(ra) # 800026de <exit>
    if(which_dev == 2 && myproc()->state == RUNNING && myproc() != 0) {
    80002e2e:	a079                	j	80002ebc <usertrap+0x16e>
      myproc()->ticks_left--;
    80002e30:	fffff097          	auipc	ra,0xfffff
    80002e34:	d84080e7          	jalr	-636(ra) # 80001bb4 <myproc>
    80002e38:	17c52783          	lw	a5,380(a0)
    80002e3c:	37fd                	addiw	a5,a5,-1
    80002e3e:	16f52e23          	sw	a5,380(a0)
      if(myproc()->ticks_left == 0) {
    80002e42:	fffff097          	auipc	ra,0xfffff
    80002e46:	d72080e7          	jalr	-654(ra) # 80001bb4 <myproc>
    80002e4a:	17c52783          	lw	a5,380(a0)
    80002e4e:	f7e9                	bnez	a5,80002e18 <usertrap+0xca>
        p->sigalarm_tf = kalloc();
    80002e50:	ffffe097          	auipc	ra,0xffffe
    80002e54:	caa080e7          	jalr	-854(ra) # 80000afa <kalloc>
    80002e58:	18a4b423          	sd	a0,392(s1)
        memmove(p->sigalarm_tf, p->trapframe, PGSIZE);
    80002e5c:	6605                	lui	a2,0x1
    80002e5e:	6cac                	ld	a1,88(s1)
    80002e60:	ffffe097          	auipc	ra,0xffffe
    80002e64:	ee6080e7          	jalr	-282(ra) # 80000d46 <memmove>
        p->trapframe->epc = p->sig_handler;
    80002e68:	6cbc                	ld	a5,88(s1)
    80002e6a:	1804b703          	ld	a4,384(s1)
    80002e6e:	ef98                	sd	a4,24(a5)
    80002e70:	b765                	j	80002e18 <usertrap+0xca>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e72:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002e76:	5890                	lw	a2,48(s1)
    80002e78:	00005517          	auipc	a0,0x5
    80002e7c:	4f050513          	addi	a0,a0,1264 # 80008368 <states.1801+0x78>
    80002e80:	ffffd097          	auipc	ra,0xffffd
    80002e84:	70e080e7          	jalr	1806(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e88:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e8c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e90:	00005517          	auipc	a0,0x5
    80002e94:	50850513          	addi	a0,a0,1288 # 80008398 <states.1801+0xa8>
    80002e98:	ffffd097          	auipc	ra,0xffffd
    80002e9c:	6f6080e7          	jalr	1782(ra) # 8000058e <printf>
    setkilled(p);
    80002ea0:	8526                	mv	a0,s1
    80002ea2:	00000097          	auipc	ra,0x0
    80002ea6:	990080e7          	jalr	-1648(ra) # 80002832 <setkilled>
    80002eaa:	bddd                	j	80002da0 <usertrap+0x52>
    exit(-1);
    80002eac:	557d                	li	a0,-1
    80002eae:	00000097          	auipc	ra,0x0
    80002eb2:	830080e7          	jalr	-2000(ra) # 800026de <exit>
    if(which_dev == 2 && myproc()->state == RUNNING && myproc() != 0) {
    80002eb6:	4789                	li	a5,2
    80002eb8:	eef91be3          	bne	s2,a5,80002dae <usertrap+0x60>
    80002ebc:	fffff097          	auipc	ra,0xfffff
    80002ec0:	cf8080e7          	jalr	-776(ra) # 80001bb4 <myproc>
    80002ec4:	4d18                	lw	a4,24(a0)
    80002ec6:	4791                	li	a5,4
    80002ec8:	eef713e3          	bne	a4,a5,80002dae <usertrap+0x60>
    80002ecc:	fffff097          	auipc	ra,0xfffff
    80002ed0:	ce8080e7          	jalr	-792(ra) # 80001bb4 <myproc>
    80002ed4:	ec050de3          	beqz	a0,80002dae <usertrap+0x60>
      if(p->curr_rtime >= priority_levels[p->priority]) {
    80002ed8:	1984a703          	lw	a4,408(s1)
    80002edc:	00271693          	slli	a3,a4,0x2
    80002ee0:	00006797          	auipc	a5,0x6
    80002ee4:	ae878793          	addi	a5,a5,-1304 # 800089c8 <priority_levels>
    80002ee8:	97b6                	add	a5,a5,a3
    80002eea:	1a04a683          	lw	a3,416(s1)
    80002eee:	439c                	lw	a5,0(a5)
    80002ef0:	00f6da63          	bge	a3,a5,80002f04 <usertrap+0x1b6>
        for(int i = 0; i < p->priority; i++) {
    80002ef4:	0000e997          	auipc	s3,0xe
    80002ef8:	2b498993          	addi	s3,s3,692 # 800111a8 <queues+0x8>
    80002efc:	4901                	li	s2,0
    80002efe:	02e04963          	bgtz	a4,80002f30 <usertrap+0x1e2>
    80002f02:	b575                	j	80002dae <usertrap+0x60>
        if(p->priority != 4) {
    80002f04:	4791                	li	a5,4
    80002f06:	00f70563          	beq	a4,a5,80002f10 <usertrap+0x1c2>
          p->priority++;
    80002f0a:	2705                	addiw	a4,a4,1
    80002f0c:	18e4ac23          	sw	a4,408(s1)
        p->curr_rtime = 0;
    80002f10:	1a04a023          	sw	zero,416(s1)
        p->curr_wtime = 0;
    80002f14:	1a04a223          	sw	zero,420(s1)
        yield();
    80002f18:	fffff097          	auipc	ra,0xfffff
    80002f1c:	42a080e7          	jalr	1066(ra) # 80002342 <yield>
    80002f20:	b579                	j	80002dae <usertrap+0x60>
        for(int i = 0; i < p->priority; i++) {
    80002f22:	2905                	addiw	s2,s2,1
    80002f24:	21898993          	addi	s3,s3,536
    80002f28:	1984a783          	lw	a5,408(s1)
    80002f2c:	e8f951e3          	bge	s2,a5,80002dae <usertrap+0x60>
          if(queues[i].length > 0) {
    80002f30:	0009a783          	lw	a5,0(s3)
    80002f34:	fef057e3          	blez	a5,80002f22 <usertrap+0x1d4>
            yield();
    80002f38:	fffff097          	auipc	ra,0xfffff
    80002f3c:	40a080e7          	jalr	1034(ra) # 80002342 <yield>
    80002f40:	b7cd                	j	80002f22 <usertrap+0x1d4>

0000000080002f42 <kerneltrap>:
{
    80002f42:	7139                	addi	sp,sp,-64
    80002f44:	fc06                	sd	ra,56(sp)
    80002f46:	f822                	sd	s0,48(sp)
    80002f48:	f426                	sd	s1,40(sp)
    80002f4a:	f04a                	sd	s2,32(sp)
    80002f4c:	ec4e                	sd	s3,24(sp)
    80002f4e:	e852                	sd	s4,16(sp)
    80002f50:	e456                	sd	s5,8(sp)
    80002f52:	0080                	addi	s0,sp,64
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f54:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f58:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f5c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002f60:	1004f793          	andi	a5,s1,256
    80002f64:	cb95                	beqz	a5,80002f98 <kerneltrap+0x56>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f66:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002f6a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002f6c:	ef95                	bnez	a5,80002fa8 <kerneltrap+0x66>
  if((which_dev = devintr()) == 0){
    80002f6e:	00000097          	auipc	ra,0x0
    80002f72:	d3e080e7          	jalr	-706(ra) # 80002cac <devintr>
    80002f76:	c129                	beqz	a0,80002fb8 <kerneltrap+0x76>
    if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING) {
    80002f78:	4789                	li	a5,2
    80002f7a:	06f50c63          	beq	a0,a5,80002ff2 <kerneltrap+0xb0>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f7e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f82:	10049073          	csrw	sstatus,s1
}
    80002f86:	70e2                	ld	ra,56(sp)
    80002f88:	7442                	ld	s0,48(sp)
    80002f8a:	74a2                	ld	s1,40(sp)
    80002f8c:	7902                	ld	s2,32(sp)
    80002f8e:	69e2                	ld	s3,24(sp)
    80002f90:	6a42                	ld	s4,16(sp)
    80002f92:	6aa2                	ld	s5,8(sp)
    80002f94:	6121                	addi	sp,sp,64
    80002f96:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002f98:	00005517          	auipc	a0,0x5
    80002f9c:	42050513          	addi	a0,a0,1056 # 800083b8 <states.1801+0xc8>
    80002fa0:	ffffd097          	auipc	ra,0xffffd
    80002fa4:	5a4080e7          	jalr	1444(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    80002fa8:	00005517          	auipc	a0,0x5
    80002fac:	43850513          	addi	a0,a0,1080 # 800083e0 <states.1801+0xf0>
    80002fb0:	ffffd097          	auipc	ra,0xffffd
    80002fb4:	594080e7          	jalr	1428(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    80002fb8:	85ce                	mv	a1,s3
    80002fba:	00005517          	auipc	a0,0x5
    80002fbe:	44650513          	addi	a0,a0,1094 # 80008400 <states.1801+0x110>
    80002fc2:	ffffd097          	auipc	ra,0xffffd
    80002fc6:	5cc080e7          	jalr	1484(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fca:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002fce:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002fd2:	00005517          	auipc	a0,0x5
    80002fd6:	43e50513          	addi	a0,a0,1086 # 80008410 <states.1801+0x120>
    80002fda:	ffffd097          	auipc	ra,0xffffd
    80002fde:	5b4080e7          	jalr	1460(ra) # 8000058e <printf>
    panic("kerneltrap");
    80002fe2:	00005517          	auipc	a0,0x5
    80002fe6:	44650513          	addi	a0,a0,1094 # 80008428 <states.1801+0x138>
    80002fea:	ffffd097          	auipc	ra,0xffffd
    80002fee:	55a080e7          	jalr	1370(ra) # 80000544 <panic>
    if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING) {
    80002ff2:	fffff097          	auipc	ra,0xfffff
    80002ff6:	bc2080e7          	jalr	-1086(ra) # 80001bb4 <myproc>
    80002ffa:	d151                	beqz	a0,80002f7e <kerneltrap+0x3c>
    80002ffc:	fffff097          	auipc	ra,0xfffff
    80003000:	bb8080e7          	jalr	-1096(ra) # 80001bb4 <myproc>
    80003004:	4d18                	lw	a4,24(a0)
    80003006:	4791                	li	a5,4
    80003008:	f6f71be3          	bne	a4,a5,80002f7e <kerneltrap+0x3c>
      struct proc* p = myproc();
    8000300c:	fffff097          	auipc	ra,0xfffff
    80003010:	ba8080e7          	jalr	-1112(ra) # 80001bb4 <myproc>
    80003014:	8aaa                	mv	s5,a0
      if(p->curr_rtime >= priority_levels[p->priority]) {
    80003016:	19852703          	lw	a4,408(a0)
    8000301a:	00271693          	slli	a3,a4,0x2
    8000301e:	00006797          	auipc	a5,0x6
    80003022:	9aa78793          	addi	a5,a5,-1622 # 800089c8 <priority_levels>
    80003026:	97b6                	add	a5,a5,a3
    80003028:	1a052683          	lw	a3,416(a0)
    8000302c:	439c                	lw	a5,0(a5)
    8000302e:	00f6da63          	bge	a3,a5,80003042 <kerneltrap+0x100>
        for(int i = 0; i < p->priority; i++) {
    80003032:	0000ea17          	auipc	s4,0xe
    80003036:	176a0a13          	addi	s4,s4,374 # 800111a8 <queues+0x8>
    8000303a:	4981                	li	s3,0
    8000303c:	02e04563          	bgtz	a4,80003066 <kerneltrap+0x124>
    80003040:	bf3d                	j	80002f7e <kerneltrap+0x3c>
        if(p->priority != 4) {
    80003042:	4791                	li	a5,4
    80003044:	00f70563          	beq	a4,a5,8000304e <kerneltrap+0x10c>
          p->priority++;
    80003048:	2705                	addiw	a4,a4,1
    8000304a:	18e52c23          	sw	a4,408(a0)
        yield();
    8000304e:	fffff097          	auipc	ra,0xfffff
    80003052:	2f4080e7          	jalr	756(ra) # 80002342 <yield>
    80003056:	b725                	j	80002f7e <kerneltrap+0x3c>
        for(int i = 0; i < p->priority; i++) {
    80003058:	2985                	addiw	s3,s3,1
    8000305a:	218a0a13          	addi	s4,s4,536
    8000305e:	198aa783          	lw	a5,408(s5)
    80003062:	f0f9dee3          	bge	s3,a5,80002f7e <kerneltrap+0x3c>
          if(queues[i].length > 0) {
    80003066:	000a2783          	lw	a5,0(s4)
    8000306a:	fef057e3          	blez	a5,80003058 <kerneltrap+0x116>
            yield();
    8000306e:	fffff097          	auipc	ra,0xfffff
    80003072:	2d4080e7          	jalr	724(ra) # 80002342 <yield>
    80003076:	b7cd                	j	80003058 <kerneltrap+0x116>

0000000080003078 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003078:	1101                	addi	sp,sp,-32
    8000307a:	ec06                	sd	ra,24(sp)
    8000307c:	e822                	sd	s0,16(sp)
    8000307e:	e426                	sd	s1,8(sp)
    80003080:	1000                	addi	s0,sp,32
    80003082:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003084:	fffff097          	auipc	ra,0xfffff
    80003088:	b30080e7          	jalr	-1232(ra) # 80001bb4 <myproc>
  switch (n) {
    8000308c:	4795                	li	a5,5
    8000308e:	0497e163          	bltu	a5,s1,800030d0 <argraw+0x58>
    80003092:	048a                	slli	s1,s1,0x2
    80003094:	00005717          	auipc	a4,0x5
    80003098:	4ac70713          	addi	a4,a4,1196 # 80008540 <states.1801+0x250>
    8000309c:	94ba                	add	s1,s1,a4
    8000309e:	409c                	lw	a5,0(s1)
    800030a0:	97ba                	add	a5,a5,a4
    800030a2:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800030a4:	6d3c                	ld	a5,88(a0)
    800030a6:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800030a8:	60e2                	ld	ra,24(sp)
    800030aa:	6442                	ld	s0,16(sp)
    800030ac:	64a2                	ld	s1,8(sp)
    800030ae:	6105                	addi	sp,sp,32
    800030b0:	8082                	ret
    return p->trapframe->a1;
    800030b2:	6d3c                	ld	a5,88(a0)
    800030b4:	7fa8                	ld	a0,120(a5)
    800030b6:	bfcd                	j	800030a8 <argraw+0x30>
    return p->trapframe->a2;
    800030b8:	6d3c                	ld	a5,88(a0)
    800030ba:	63c8                	ld	a0,128(a5)
    800030bc:	b7f5                	j	800030a8 <argraw+0x30>
    return p->trapframe->a3;
    800030be:	6d3c                	ld	a5,88(a0)
    800030c0:	67c8                	ld	a0,136(a5)
    800030c2:	b7dd                	j	800030a8 <argraw+0x30>
    return p->trapframe->a4;
    800030c4:	6d3c                	ld	a5,88(a0)
    800030c6:	6bc8                	ld	a0,144(a5)
    800030c8:	b7c5                	j	800030a8 <argraw+0x30>
    return p->trapframe->a5;
    800030ca:	6d3c                	ld	a5,88(a0)
    800030cc:	6fc8                	ld	a0,152(a5)
    800030ce:	bfe9                	j	800030a8 <argraw+0x30>
  panic("argraw");
    800030d0:	00005517          	auipc	a0,0x5
    800030d4:	36850513          	addi	a0,a0,872 # 80008438 <states.1801+0x148>
    800030d8:	ffffd097          	auipc	ra,0xffffd
    800030dc:	46c080e7          	jalr	1132(ra) # 80000544 <panic>

00000000800030e0 <fetchaddr>:
{
    800030e0:	1101                	addi	sp,sp,-32
    800030e2:	ec06                	sd	ra,24(sp)
    800030e4:	e822                	sd	s0,16(sp)
    800030e6:	e426                	sd	s1,8(sp)
    800030e8:	e04a                	sd	s2,0(sp)
    800030ea:	1000                	addi	s0,sp,32
    800030ec:	84aa                	mv	s1,a0
    800030ee:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800030f0:	fffff097          	auipc	ra,0xfffff
    800030f4:	ac4080e7          	jalr	-1340(ra) # 80001bb4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    800030f8:	653c                	ld	a5,72(a0)
    800030fa:	02f4f863          	bgeu	s1,a5,8000312a <fetchaddr+0x4a>
    800030fe:	00848713          	addi	a4,s1,8
    80003102:	02e7e663          	bltu	a5,a4,8000312e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003106:	46a1                	li	a3,8
    80003108:	8626                	mv	a2,s1
    8000310a:	85ca                	mv	a1,s2
    8000310c:	6928                	ld	a0,80(a0)
    8000310e:	ffffe097          	auipc	ra,0xffffe
    80003112:	602080e7          	jalr	1538(ra) # 80001710 <copyin>
    80003116:	00a03533          	snez	a0,a0
    8000311a:	40a00533          	neg	a0,a0
}
    8000311e:	60e2                	ld	ra,24(sp)
    80003120:	6442                	ld	s0,16(sp)
    80003122:	64a2                	ld	s1,8(sp)
    80003124:	6902                	ld	s2,0(sp)
    80003126:	6105                	addi	sp,sp,32
    80003128:	8082                	ret
    return -1;
    8000312a:	557d                	li	a0,-1
    8000312c:	bfcd                	j	8000311e <fetchaddr+0x3e>
    8000312e:	557d                	li	a0,-1
    80003130:	b7fd                	j	8000311e <fetchaddr+0x3e>

0000000080003132 <fetchstr>:
{
    80003132:	7179                	addi	sp,sp,-48
    80003134:	f406                	sd	ra,40(sp)
    80003136:	f022                	sd	s0,32(sp)
    80003138:	ec26                	sd	s1,24(sp)
    8000313a:	e84a                	sd	s2,16(sp)
    8000313c:	e44e                	sd	s3,8(sp)
    8000313e:	1800                	addi	s0,sp,48
    80003140:	892a                	mv	s2,a0
    80003142:	84ae                	mv	s1,a1
    80003144:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003146:	fffff097          	auipc	ra,0xfffff
    8000314a:	a6e080e7          	jalr	-1426(ra) # 80001bb4 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    8000314e:	86ce                	mv	a3,s3
    80003150:	864a                	mv	a2,s2
    80003152:	85a6                	mv	a1,s1
    80003154:	6928                	ld	a0,80(a0)
    80003156:	ffffe097          	auipc	ra,0xffffe
    8000315a:	646080e7          	jalr	1606(ra) # 8000179c <copyinstr>
    8000315e:	00054e63          	bltz	a0,8000317a <fetchstr+0x48>
  return strlen(buf);
    80003162:	8526                	mv	a0,s1
    80003164:	ffffe097          	auipc	ra,0xffffe
    80003168:	d06080e7          	jalr	-762(ra) # 80000e6a <strlen>
}
    8000316c:	70a2                	ld	ra,40(sp)
    8000316e:	7402                	ld	s0,32(sp)
    80003170:	64e2                	ld	s1,24(sp)
    80003172:	6942                	ld	s2,16(sp)
    80003174:	69a2                	ld	s3,8(sp)
    80003176:	6145                	addi	sp,sp,48
    80003178:	8082                	ret
    return -1;
    8000317a:	557d                	li	a0,-1
    8000317c:	bfc5                	j	8000316c <fetchstr+0x3a>

000000008000317e <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    8000317e:	1101                	addi	sp,sp,-32
    80003180:	ec06                	sd	ra,24(sp)
    80003182:	e822                	sd	s0,16(sp)
    80003184:	e426                	sd	s1,8(sp)
    80003186:	1000                	addi	s0,sp,32
    80003188:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000318a:	00000097          	auipc	ra,0x0
    8000318e:	eee080e7          	jalr	-274(ra) # 80003078 <argraw>
    80003192:	c088                	sw	a0,0(s1)
}
    80003194:	60e2                	ld	ra,24(sp)
    80003196:	6442                	ld	s0,16(sp)
    80003198:	64a2                	ld	s1,8(sp)
    8000319a:	6105                	addi	sp,sp,32
    8000319c:	8082                	ret

000000008000319e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    8000319e:	1101                	addi	sp,sp,-32
    800031a0:	ec06                	sd	ra,24(sp)
    800031a2:	e822                	sd	s0,16(sp)
    800031a4:	e426                	sd	s1,8(sp)
    800031a6:	1000                	addi	s0,sp,32
    800031a8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800031aa:	00000097          	auipc	ra,0x0
    800031ae:	ece080e7          	jalr	-306(ra) # 80003078 <argraw>
    800031b2:	e088                	sd	a0,0(s1)
}
    800031b4:	60e2                	ld	ra,24(sp)
    800031b6:	6442                	ld	s0,16(sp)
    800031b8:	64a2                	ld	s1,8(sp)
    800031ba:	6105                	addi	sp,sp,32
    800031bc:	8082                	ret

00000000800031be <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800031be:	7179                	addi	sp,sp,-48
    800031c0:	f406                	sd	ra,40(sp)
    800031c2:	f022                	sd	s0,32(sp)
    800031c4:	ec26                	sd	s1,24(sp)
    800031c6:	e84a                	sd	s2,16(sp)
    800031c8:	1800                	addi	s0,sp,48
    800031ca:	84ae                	mv	s1,a1
    800031cc:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800031ce:	fd840593          	addi	a1,s0,-40
    800031d2:	00000097          	auipc	ra,0x0
    800031d6:	fcc080e7          	jalr	-52(ra) # 8000319e <argaddr>
  return fetchstr(addr, buf, max);
    800031da:	864a                	mv	a2,s2
    800031dc:	85a6                	mv	a1,s1
    800031de:	fd843503          	ld	a0,-40(s0)
    800031e2:	00000097          	auipc	ra,0x0
    800031e6:	f50080e7          	jalr	-176(ra) # 80003132 <fetchstr>
}
    800031ea:	70a2                	ld	ra,40(sp)
    800031ec:	7402                	ld	s0,32(sp)
    800031ee:	64e2                	ld	s1,24(sp)
    800031f0:	6942                	ld	s2,16(sp)
    800031f2:	6145                	addi	sp,sp,48
    800031f4:	8082                	ret

00000000800031f6 <syscall>:
[SYS_sigreturn] "sigreturn ",
};

void
syscall(void)
{
    800031f6:	7179                	addi	sp,sp,-48
    800031f8:	f406                	sd	ra,40(sp)
    800031fa:	f022                	sd	s0,32(sp)
    800031fc:	ec26                	sd	s1,24(sp)
    800031fe:	e84a                	sd	s2,16(sp)
    80003200:	e44e                	sd	s3,8(sp)
    80003202:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80003204:	fffff097          	auipc	ra,0xfffff
    80003208:	9b0080e7          	jalr	-1616(ra) # 80001bb4 <myproc>
    8000320c:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000320e:	05853903          	ld	s2,88(a0)
    80003212:	0a893783          	ld	a5,168(s2)
    80003216:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000321a:	37fd                	addiw	a5,a5,-1
    8000321c:	4769                	li	a4,26
    8000321e:	04f76763          	bltu	a4,a5,8000326c <syscall+0x76>
    80003222:	00399713          	slli	a4,s3,0x3
    80003226:	00005797          	auipc	a5,0x5
    8000322a:	33278793          	addi	a5,a5,818 # 80008558 <syscalls>
    8000322e:	97ba                	add	a5,a5,a4
    80003230:	639c                	ld	a5,0(a5)
    80003232:	cf8d                	beqz	a5,8000326c <syscall+0x76>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80003234:	9782                	jalr	a5
    80003236:	06a93823          	sd	a0,112(s2)

    // Check for trace_flag to be on
    if(p->trace_flag >> num) {  // check for '=='
    8000323a:	1744a783          	lw	a5,372(s1)
    8000323e:	4137d7bb          	sraw	a5,a5,s3
    80003242:	c7a1                	beqz	a5,8000328a <syscall+0x94>
      printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0);
    80003244:	6cb8                	ld	a4,88(s1)
    80003246:	098e                	slli	s3,s3,0x3
    80003248:	00005797          	auipc	a5,0x5
    8000324c:	79878793          	addi	a5,a5,1944 # 800089e0 <syscall_names>
    80003250:	99be                	add	s3,s3,a5
    80003252:	7b34                	ld	a3,112(a4)
    80003254:	0009b603          	ld	a2,0(s3)
    80003258:	588c                	lw	a1,48(s1)
    8000325a:	00005517          	auipc	a0,0x5
    8000325e:	1e650513          	addi	a0,a0,486 # 80008440 <states.1801+0x150>
    80003262:	ffffd097          	auipc	ra,0xffffd
    80003266:	32c080e7          	jalr	812(ra) # 8000058e <printf>
    8000326a:	a005                	j	8000328a <syscall+0x94>
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    8000326c:	86ce                	mv	a3,s3
    8000326e:	15848613          	addi	a2,s1,344
    80003272:	588c                	lw	a1,48(s1)
    80003274:	00005517          	auipc	a0,0x5
    80003278:	1e450513          	addi	a0,a0,484 # 80008458 <states.1801+0x168>
    8000327c:	ffffd097          	auipc	ra,0xffffd
    80003280:	312080e7          	jalr	786(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003284:	6cbc                	ld	a5,88(s1)
    80003286:	577d                	li	a4,-1
    80003288:	fbb8                	sd	a4,112(a5)
  }
}
    8000328a:	70a2                	ld	ra,40(sp)
    8000328c:	7402                	ld	s0,32(sp)
    8000328e:	64e2                	ld	s1,24(sp)
    80003290:	6942                	ld	s2,16(sp)
    80003292:	69a2                	ld	s3,8(sp)
    80003294:	6145                	addi	sp,sp,48
    80003296:	8082                	ret

0000000080003298 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003298:	1101                	addi	sp,sp,-32
    8000329a:	ec06                	sd	ra,24(sp)
    8000329c:	e822                	sd	s0,16(sp)
    8000329e:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    800032a0:	fec40593          	addi	a1,s0,-20
    800032a4:	4501                	li	a0,0
    800032a6:	00000097          	auipc	ra,0x0
    800032aa:	ed8080e7          	jalr	-296(ra) # 8000317e <argint>
  exit(n);
    800032ae:	fec42503          	lw	a0,-20(s0)
    800032b2:	fffff097          	auipc	ra,0xfffff
    800032b6:	42c080e7          	jalr	1068(ra) # 800026de <exit>
  return 0;  // not reached
}
    800032ba:	4501                	li	a0,0
    800032bc:	60e2                	ld	ra,24(sp)
    800032be:	6442                	ld	s0,16(sp)
    800032c0:	6105                	addi	sp,sp,32
    800032c2:	8082                	ret

00000000800032c4 <sys_getpid>:

uint64
sys_getpid(void)
{
    800032c4:	1141                	addi	sp,sp,-16
    800032c6:	e406                	sd	ra,8(sp)
    800032c8:	e022                	sd	s0,0(sp)
    800032ca:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800032cc:	fffff097          	auipc	ra,0xfffff
    800032d0:	8e8080e7          	jalr	-1816(ra) # 80001bb4 <myproc>
}
    800032d4:	5908                	lw	a0,48(a0)
    800032d6:	60a2                	ld	ra,8(sp)
    800032d8:	6402                	ld	s0,0(sp)
    800032da:	0141                	addi	sp,sp,16
    800032dc:	8082                	ret

00000000800032de <sys_fork>:

uint64
sys_fork(void)
{
    800032de:	1141                	addi	sp,sp,-16
    800032e0:	e406                	sd	ra,8(sp)
    800032e2:	e022                	sd	s0,0(sp)
    800032e4:	0800                	addi	s0,sp,16
  return fork();
    800032e6:	fffff097          	auipc	ra,0xfffff
    800032ea:	cca080e7          	jalr	-822(ra) # 80001fb0 <fork>
}
    800032ee:	60a2                	ld	ra,8(sp)
    800032f0:	6402                	ld	s0,0(sp)
    800032f2:	0141                	addi	sp,sp,16
    800032f4:	8082                	ret

00000000800032f6 <sys_wait>:

uint64
sys_wait(void)
{
    800032f6:	1101                	addi	sp,sp,-32
    800032f8:	ec06                	sd	ra,24(sp)
    800032fa:	e822                	sd	s0,16(sp)
    800032fc:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    800032fe:	fe840593          	addi	a1,s0,-24
    80003302:	4501                	li	a0,0
    80003304:	00000097          	auipc	ra,0x0
    80003308:	e9a080e7          	jalr	-358(ra) # 8000319e <argaddr>
  return wait(p);
    8000330c:	fe843503          	ld	a0,-24(s0)
    80003310:	fffff097          	auipc	ra,0xfffff
    80003314:	580080e7          	jalr	1408(ra) # 80002890 <wait>
}
    80003318:	60e2                	ld	ra,24(sp)
    8000331a:	6442                	ld	s0,16(sp)
    8000331c:	6105                	addi	sp,sp,32
    8000331e:	8082                	ret

0000000080003320 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003320:	7179                	addi	sp,sp,-48
    80003322:	f406                	sd	ra,40(sp)
    80003324:	f022                	sd	s0,32(sp)
    80003326:	ec26                	sd	s1,24(sp)
    80003328:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    8000332a:	fdc40593          	addi	a1,s0,-36
    8000332e:	4501                	li	a0,0
    80003330:	00000097          	auipc	ra,0x0
    80003334:	e4e080e7          	jalr	-434(ra) # 8000317e <argint>
  addr = myproc()->sz;
    80003338:	fffff097          	auipc	ra,0xfffff
    8000333c:	87c080e7          	jalr	-1924(ra) # 80001bb4 <myproc>
    80003340:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80003342:	fdc42503          	lw	a0,-36(s0)
    80003346:	fffff097          	auipc	ra,0xfffff
    8000334a:	c0e080e7          	jalr	-1010(ra) # 80001f54 <growproc>
    8000334e:	00054863          	bltz	a0,8000335e <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80003352:	8526                	mv	a0,s1
    80003354:	70a2                	ld	ra,40(sp)
    80003356:	7402                	ld	s0,32(sp)
    80003358:	64e2                	ld	s1,24(sp)
    8000335a:	6145                	addi	sp,sp,48
    8000335c:	8082                	ret
    return -1;
    8000335e:	54fd                	li	s1,-1
    80003360:	bfcd                	j	80003352 <sys_sbrk+0x32>

0000000080003362 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003362:	7139                	addi	sp,sp,-64
    80003364:	fc06                	sd	ra,56(sp)
    80003366:	f822                	sd	s0,48(sp)
    80003368:	f426                	sd	s1,40(sp)
    8000336a:	f04a                	sd	s2,32(sp)
    8000336c:	ec4e                	sd	s3,24(sp)
    8000336e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80003370:	fcc40593          	addi	a1,s0,-52
    80003374:	4501                	li	a0,0
    80003376:	00000097          	auipc	ra,0x0
    8000337a:	e08080e7          	jalr	-504(ra) # 8000317e <argint>
  acquire(&tickslock);
    8000337e:	00015517          	auipc	a0,0x15
    80003382:	49a50513          	addi	a0,a0,1178 # 80018818 <tickslock>
    80003386:	ffffe097          	auipc	ra,0xffffe
    8000338a:	864080e7          	jalr	-1948(ra) # 80000bea <acquire>
  ticks0 = ticks;
    8000338e:	00005917          	auipc	s2,0x5
    80003392:	77292903          	lw	s2,1906(s2) # 80008b00 <ticks>
  while(ticks - ticks0 < n){
    80003396:	fcc42783          	lw	a5,-52(s0)
    8000339a:	cf9d                	beqz	a5,800033d8 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000339c:	00015997          	auipc	s3,0x15
    800033a0:	47c98993          	addi	s3,s3,1148 # 80018818 <tickslock>
    800033a4:	00005497          	auipc	s1,0x5
    800033a8:	75c48493          	addi	s1,s1,1884 # 80008b00 <ticks>
    if(killed(myproc())){
    800033ac:	fffff097          	auipc	ra,0xfffff
    800033b0:	808080e7          	jalr	-2040(ra) # 80001bb4 <myproc>
    800033b4:	fffff097          	auipc	ra,0xfffff
    800033b8:	4aa080e7          	jalr	1194(ra) # 8000285e <killed>
    800033bc:	ed15                	bnez	a0,800033f8 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    800033be:	85ce                	mv	a1,s3
    800033c0:	8526                	mv	a0,s1
    800033c2:	fffff097          	auipc	ra,0xfffff
    800033c6:	09c080e7          	jalr	156(ra) # 8000245e <sleep>
  while(ticks - ticks0 < n){
    800033ca:	409c                	lw	a5,0(s1)
    800033cc:	412787bb          	subw	a5,a5,s2
    800033d0:	fcc42703          	lw	a4,-52(s0)
    800033d4:	fce7ece3          	bltu	a5,a4,800033ac <sys_sleep+0x4a>
  }
  release(&tickslock);
    800033d8:	00015517          	auipc	a0,0x15
    800033dc:	44050513          	addi	a0,a0,1088 # 80018818 <tickslock>
    800033e0:	ffffe097          	auipc	ra,0xffffe
    800033e4:	8be080e7          	jalr	-1858(ra) # 80000c9e <release>
  return 0;
    800033e8:	4501                	li	a0,0
}
    800033ea:	70e2                	ld	ra,56(sp)
    800033ec:	7442                	ld	s0,48(sp)
    800033ee:	74a2                	ld	s1,40(sp)
    800033f0:	7902                	ld	s2,32(sp)
    800033f2:	69e2                	ld	s3,24(sp)
    800033f4:	6121                	addi	sp,sp,64
    800033f6:	8082                	ret
      release(&tickslock);
    800033f8:	00015517          	auipc	a0,0x15
    800033fc:	42050513          	addi	a0,a0,1056 # 80018818 <tickslock>
    80003400:	ffffe097          	auipc	ra,0xffffe
    80003404:	89e080e7          	jalr	-1890(ra) # 80000c9e <release>
      return -1;
    80003408:	557d                	li	a0,-1
    8000340a:	b7c5                	j	800033ea <sys_sleep+0x88>

000000008000340c <sys_kill>:

uint64
sys_kill(void)
{
    8000340c:	1101                	addi	sp,sp,-32
    8000340e:	ec06                	sd	ra,24(sp)
    80003410:	e822                	sd	s0,16(sp)
    80003412:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003414:	fec40593          	addi	a1,s0,-20
    80003418:	4501                	li	a0,0
    8000341a:	00000097          	auipc	ra,0x0
    8000341e:	d64080e7          	jalr	-668(ra) # 8000317e <argint>
  return kill(pid);
    80003422:	fec42503          	lw	a0,-20(s0)
    80003426:	fffff097          	auipc	ra,0xfffff
    8000342a:	39a080e7          	jalr	922(ra) # 800027c0 <kill>
}
    8000342e:	60e2                	ld	ra,24(sp)
    80003430:	6442                	ld	s0,16(sp)
    80003432:	6105                	addi	sp,sp,32
    80003434:	8082                	ret

0000000080003436 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003436:	1101                	addi	sp,sp,-32
    80003438:	ec06                	sd	ra,24(sp)
    8000343a:	e822                	sd	s0,16(sp)
    8000343c:	e426                	sd	s1,8(sp)
    8000343e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003440:	00015517          	auipc	a0,0x15
    80003444:	3d850513          	addi	a0,a0,984 # 80018818 <tickslock>
    80003448:	ffffd097          	auipc	ra,0xffffd
    8000344c:	7a2080e7          	jalr	1954(ra) # 80000bea <acquire>
  xticks = ticks;
    80003450:	00005497          	auipc	s1,0x5
    80003454:	6b04a483          	lw	s1,1712(s1) # 80008b00 <ticks>
  release(&tickslock);
    80003458:	00015517          	auipc	a0,0x15
    8000345c:	3c050513          	addi	a0,a0,960 # 80018818 <tickslock>
    80003460:	ffffe097          	auipc	ra,0xffffe
    80003464:	83e080e7          	jalr	-1986(ra) # 80000c9e <release>
  return xticks;
}
    80003468:	02049513          	slli	a0,s1,0x20
    8000346c:	9101                	srli	a0,a0,0x20
    8000346e:	60e2                	ld	ra,24(sp)
    80003470:	6442                	ld	s0,16(sp)
    80003472:	64a2                	ld	s1,8(sp)
    80003474:	6105                	addi	sp,sp,32
    80003476:	8082                	ret

0000000080003478 <sys_trace>:

// sets the trace_flag to the first argument (a0)
uint64
sys_trace(void)
{
    80003478:	1141                	addi	sp,sp,-16
    8000347a:	e406                	sd	ra,8(sp)
    8000347c:	e022                	sd	s0,0(sp)
    8000347e:	0800                	addi	s0,sp,16
  argint(0, &myproc()->trace_flag); //arg(a0, trace_flag) // returns void
    80003480:	ffffe097          	auipc	ra,0xffffe
    80003484:	734080e7          	jalr	1844(ra) # 80001bb4 <myproc>
    80003488:	17450593          	addi	a1,a0,372
    8000348c:	4501                	li	a0,0
    8000348e:	00000097          	auipc	ra,0x0
    80003492:	cf0080e7          	jalr	-784(ra) # 8000317e <argint>
  return 0;
}
    80003496:	4501                	li	a0,0
    80003498:	60a2                	ld	ra,8(sp)
    8000349a:	6402                	ld	s0,0(sp)
    8000349c:	0141                	addi	sp,sp,16
    8000349e:	8082                	ret

00000000800034a0 <sys_sigalarm>:

// sets the 
uint64
sys_sigalarm(void)
{
    800034a0:	1101                	addi	sp,sp,-32
    800034a2:	ec06                	sd	ra,24(sp)
    800034a4:	e822                	sd	s0,16(sp)
    800034a6:	e426                	sd	s1,8(sp)
    800034a8:	1000                	addi	s0,sp,32
  // sets the interval and handler after every tick
  argint(0, &myproc()->interval);
    800034aa:	ffffe097          	auipc	ra,0xffffe
    800034ae:	70a080e7          	jalr	1802(ra) # 80001bb4 <myproc>
    800034b2:	17850593          	addi	a1,a0,376
    800034b6:	4501                	li	a0,0
    800034b8:	00000097          	auipc	ra,0x0
    800034bc:	cc6080e7          	jalr	-826(ra) # 8000317e <argint>
  argaddr(1, &myproc()->sig_handler);
    800034c0:	ffffe097          	auipc	ra,0xffffe
    800034c4:	6f4080e7          	jalr	1780(ra) # 80001bb4 <myproc>
    800034c8:	18050593          	addi	a1,a0,384
    800034cc:	4505                	li	a0,1
    800034ce:	00000097          	auipc	ra,0x0
    800034d2:	cd0080e7          	jalr	-816(ra) # 8000319e <argaddr>
  
  // sets ticks_passed as the interval
  myproc()->ticks_left = myproc()->interval;
    800034d6:	ffffe097          	auipc	ra,0xffffe
    800034da:	6de080e7          	jalr	1758(ra) # 80001bb4 <myproc>
    800034de:	84aa                	mv	s1,a0
    800034e0:	ffffe097          	auipc	ra,0xffffe
    800034e4:	6d4080e7          	jalr	1748(ra) # 80001bb4 <myproc>
    800034e8:	1784a783          	lw	a5,376(s1)
    800034ec:	16f52e23          	sw	a5,380(a0)
  return 0;
}
    800034f0:	4501                	li	a0,0
    800034f2:	60e2                	ld	ra,24(sp)
    800034f4:	6442                	ld	s0,16(sp)
    800034f6:	64a2                	ld	s1,8(sp)
    800034f8:	6105                	addi	sp,sp,32
    800034fa:	8082                	ret

00000000800034fc <sys_sigreturn>:

uint64 
sys_sigreturn(void)
{
    800034fc:	1101                	addi	sp,sp,-32
    800034fe:	ec06                	sd	ra,24(sp)
    80003500:	e822                	sd	s0,16(sp)
    80003502:	e426                	sd	s1,8(sp)
    80003504:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80003506:	ffffe097          	auipc	ra,0xffffe
    8000350a:	6ae080e7          	jalr	1710(ra) # 80001bb4 <myproc>
    8000350e:	84aa                	mv	s1,a0
  memmove(p->trapframe, p->sigalarm_tf, PGSIZE);
    80003510:	6605                	lui	a2,0x1
    80003512:	18853583          	ld	a1,392(a0)
    80003516:	6d28                	ld	a0,88(a0)
    80003518:	ffffe097          	auipc	ra,0xffffe
    8000351c:	82e080e7          	jalr	-2002(ra) # 80000d46 <memmove>
  kfree(p->sigalarm_tf);
    80003520:	1884b503          	ld	a0,392(s1)
    80003524:	ffffd097          	auipc	ra,0xffffd
    80003528:	4da080e7          	jalr	1242(ra) # 800009fe <kfree>
  p->ticks_left = p->interval;
    8000352c:	1784a783          	lw	a5,376(s1)
    80003530:	16f4ae23          	sw	a5,380(s1)
  return p->trapframe->a0;
    80003534:	6cbc                	ld	a5,88(s1)
}
    80003536:	7ba8                	ld	a0,112(a5)
    80003538:	60e2                	ld	ra,24(sp)
    8000353a:	6442                	ld	s0,16(sp)
    8000353c:	64a2                	ld	s1,8(sp)
    8000353e:	6105                	addi	sp,sp,32
    80003540:	8082                	ret

0000000080003542 <sys_settickets>:

uint64 
sys_settickets(void)
{
    80003542:	1141                	addi	sp,sp,-16
    80003544:	e406                	sd	ra,8(sp)
    80003546:	e022                	sd	s0,0(sp)
    80003548:	0800                	addi	s0,sp,16
  argint(0, &myproc()->tickets);
    8000354a:	ffffe097          	auipc	ra,0xffffe
    8000354e:	66a080e7          	jalr	1642(ra) # 80001bb4 <myproc>
    80003552:	19450593          	addi	a1,a0,404
    80003556:	4501                	li	a0,0
    80003558:	00000097          	auipc	ra,0x0
    8000355c:	c26080e7          	jalr	-986(ra) # 8000317e <argint>
  return myproc()->tickets;
    80003560:	ffffe097          	auipc	ra,0xffffe
    80003564:	654080e7          	jalr	1620(ra) # 80001bb4 <myproc>
}
    80003568:	19452503          	lw	a0,404(a0)
    8000356c:	60a2                	ld	ra,8(sp)
    8000356e:	6402                	ld	s0,0(sp)
    80003570:	0141                	addi	sp,sp,16
    80003572:	8082                	ret

0000000080003574 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003574:	7139                	addi	sp,sp,-64
    80003576:	fc06                	sd	ra,56(sp)
    80003578:	f822                	sd	s0,48(sp)
    8000357a:	f426                	sd	s1,40(sp)
    8000357c:	f04a                	sd	s2,32(sp)
    8000357e:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80003580:	fd840593          	addi	a1,s0,-40
    80003584:	4501                	li	a0,0
    80003586:	00000097          	auipc	ra,0x0
    8000358a:	c18080e7          	jalr	-1000(ra) # 8000319e <argaddr>
  argaddr(1, &addr1); // user virtual memory
    8000358e:	fd040593          	addi	a1,s0,-48
    80003592:	4505                	li	a0,1
    80003594:	00000097          	auipc	ra,0x0
    80003598:	c0a080e7          	jalr	-1014(ra) # 8000319e <argaddr>
  argaddr(2, &addr2);
    8000359c:	fc840593          	addi	a1,s0,-56
    800035a0:	4509                	li	a0,2
    800035a2:	00000097          	auipc	ra,0x0
    800035a6:	bfc080e7          	jalr	-1028(ra) # 8000319e <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    800035aa:	fc040613          	addi	a2,s0,-64
    800035ae:	fc440593          	addi	a1,s0,-60
    800035b2:	fd843503          	ld	a0,-40(s0)
    800035b6:	fffff097          	auipc	ra,0xfffff
    800035ba:	f0c080e7          	jalr	-244(ra) # 800024c2 <waitx>
    800035be:	892a                	mv	s2,a0
  struct proc* p = myproc();
    800035c0:	ffffe097          	auipc	ra,0xffffe
    800035c4:	5f4080e7          	jalr	1524(ra) # 80001bb4 <myproc>
    800035c8:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    800035ca:	4691                	li	a3,4
    800035cc:	fc440613          	addi	a2,s0,-60
    800035d0:	fd043583          	ld	a1,-48(s0)
    800035d4:	6928                	ld	a0,80(a0)
    800035d6:	ffffe097          	auipc	ra,0xffffe
    800035da:	0ae080e7          	jalr	174(ra) # 80001684 <copyout>
    return -1;
    800035de:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    800035e0:	00054f63          	bltz	a0,800035fe <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    800035e4:	4691                	li	a3,4
    800035e6:	fc040613          	addi	a2,s0,-64
    800035ea:	fc843583          	ld	a1,-56(s0)
    800035ee:	68a8                	ld	a0,80(s1)
    800035f0:	ffffe097          	auipc	ra,0xffffe
    800035f4:	094080e7          	jalr	148(ra) # 80001684 <copyout>
    800035f8:	00054a63          	bltz	a0,8000360c <sys_waitx+0x98>
    return -1;
  return ret;
    800035fc:	87ca                	mv	a5,s2
}
    800035fe:	853e                	mv	a0,a5
    80003600:	70e2                	ld	ra,56(sp)
    80003602:	7442                	ld	s0,48(sp)
    80003604:	74a2                	ld	s1,40(sp)
    80003606:	7902                	ld	s2,32(sp)
    80003608:	6121                	addi	sp,sp,64
    8000360a:	8082                	ret
    return -1;
    8000360c:	57fd                	li	a5,-1
    8000360e:	bfc5                	j	800035fe <sys_waitx+0x8a>

0000000080003610 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003610:	7179                	addi	sp,sp,-48
    80003612:	f406                	sd	ra,40(sp)
    80003614:	f022                	sd	s0,32(sp)
    80003616:	ec26                	sd	s1,24(sp)
    80003618:	e84a                	sd	s2,16(sp)
    8000361a:	e44e                	sd	s3,8(sp)
    8000361c:	e052                	sd	s4,0(sp)
    8000361e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003620:	00005597          	auipc	a1,0x5
    80003624:	01858593          	addi	a1,a1,24 # 80008638 <syscalls+0xe0>
    80003628:	00015517          	auipc	a0,0x15
    8000362c:	20850513          	addi	a0,a0,520 # 80018830 <bcache>
    80003630:	ffffd097          	auipc	ra,0xffffd
    80003634:	52a080e7          	jalr	1322(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003638:	0001d797          	auipc	a5,0x1d
    8000363c:	1f878793          	addi	a5,a5,504 # 80020830 <bcache+0x8000>
    80003640:	0001d717          	auipc	a4,0x1d
    80003644:	45870713          	addi	a4,a4,1112 # 80020a98 <bcache+0x8268>
    80003648:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000364c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003650:	00015497          	auipc	s1,0x15
    80003654:	1f848493          	addi	s1,s1,504 # 80018848 <bcache+0x18>
    b->next = bcache.head.next;
    80003658:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000365a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000365c:	00005a17          	auipc	s4,0x5
    80003660:	fe4a0a13          	addi	s4,s4,-28 # 80008640 <syscalls+0xe8>
    b->next = bcache.head.next;
    80003664:	2b893783          	ld	a5,696(s2)
    80003668:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000366a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000366e:	85d2                	mv	a1,s4
    80003670:	01048513          	addi	a0,s1,16
    80003674:	00001097          	auipc	ra,0x1
    80003678:	4c4080e7          	jalr	1220(ra) # 80004b38 <initsleeplock>
    bcache.head.next->prev = b;
    8000367c:	2b893783          	ld	a5,696(s2)
    80003680:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003682:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003686:	45848493          	addi	s1,s1,1112
    8000368a:	fd349de3          	bne	s1,s3,80003664 <binit+0x54>
  }
}
    8000368e:	70a2                	ld	ra,40(sp)
    80003690:	7402                	ld	s0,32(sp)
    80003692:	64e2                	ld	s1,24(sp)
    80003694:	6942                	ld	s2,16(sp)
    80003696:	69a2                	ld	s3,8(sp)
    80003698:	6a02                	ld	s4,0(sp)
    8000369a:	6145                	addi	sp,sp,48
    8000369c:	8082                	ret

000000008000369e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000369e:	7179                	addi	sp,sp,-48
    800036a0:	f406                	sd	ra,40(sp)
    800036a2:	f022                	sd	s0,32(sp)
    800036a4:	ec26                	sd	s1,24(sp)
    800036a6:	e84a                	sd	s2,16(sp)
    800036a8:	e44e                	sd	s3,8(sp)
    800036aa:	1800                	addi	s0,sp,48
    800036ac:	89aa                	mv	s3,a0
    800036ae:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800036b0:	00015517          	auipc	a0,0x15
    800036b4:	18050513          	addi	a0,a0,384 # 80018830 <bcache>
    800036b8:	ffffd097          	auipc	ra,0xffffd
    800036bc:	532080e7          	jalr	1330(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800036c0:	0001d497          	auipc	s1,0x1d
    800036c4:	4284b483          	ld	s1,1064(s1) # 80020ae8 <bcache+0x82b8>
    800036c8:	0001d797          	auipc	a5,0x1d
    800036cc:	3d078793          	addi	a5,a5,976 # 80020a98 <bcache+0x8268>
    800036d0:	02f48f63          	beq	s1,a5,8000370e <bread+0x70>
    800036d4:	873e                	mv	a4,a5
    800036d6:	a021                	j	800036de <bread+0x40>
    800036d8:	68a4                	ld	s1,80(s1)
    800036da:	02e48a63          	beq	s1,a4,8000370e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800036de:	449c                	lw	a5,8(s1)
    800036e0:	ff379ce3          	bne	a5,s3,800036d8 <bread+0x3a>
    800036e4:	44dc                	lw	a5,12(s1)
    800036e6:	ff2799e3          	bne	a5,s2,800036d8 <bread+0x3a>
      b->refcnt++;
    800036ea:	40bc                	lw	a5,64(s1)
    800036ec:	2785                	addiw	a5,a5,1
    800036ee:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800036f0:	00015517          	auipc	a0,0x15
    800036f4:	14050513          	addi	a0,a0,320 # 80018830 <bcache>
    800036f8:	ffffd097          	auipc	ra,0xffffd
    800036fc:	5a6080e7          	jalr	1446(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80003700:	01048513          	addi	a0,s1,16
    80003704:	00001097          	auipc	ra,0x1
    80003708:	46e080e7          	jalr	1134(ra) # 80004b72 <acquiresleep>
      return b;
    8000370c:	a8b9                	j	8000376a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000370e:	0001d497          	auipc	s1,0x1d
    80003712:	3d24b483          	ld	s1,978(s1) # 80020ae0 <bcache+0x82b0>
    80003716:	0001d797          	auipc	a5,0x1d
    8000371a:	38278793          	addi	a5,a5,898 # 80020a98 <bcache+0x8268>
    8000371e:	00f48863          	beq	s1,a5,8000372e <bread+0x90>
    80003722:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003724:	40bc                	lw	a5,64(s1)
    80003726:	cf81                	beqz	a5,8000373e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003728:	64a4                	ld	s1,72(s1)
    8000372a:	fee49de3          	bne	s1,a4,80003724 <bread+0x86>
  panic("bget: no buffers");
    8000372e:	00005517          	auipc	a0,0x5
    80003732:	f1a50513          	addi	a0,a0,-230 # 80008648 <syscalls+0xf0>
    80003736:	ffffd097          	auipc	ra,0xffffd
    8000373a:	e0e080e7          	jalr	-498(ra) # 80000544 <panic>
      b->dev = dev;
    8000373e:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003742:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003746:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000374a:	4785                	li	a5,1
    8000374c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000374e:	00015517          	auipc	a0,0x15
    80003752:	0e250513          	addi	a0,a0,226 # 80018830 <bcache>
    80003756:	ffffd097          	auipc	ra,0xffffd
    8000375a:	548080e7          	jalr	1352(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    8000375e:	01048513          	addi	a0,s1,16
    80003762:	00001097          	auipc	ra,0x1
    80003766:	410080e7          	jalr	1040(ra) # 80004b72 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000376a:	409c                	lw	a5,0(s1)
    8000376c:	cb89                	beqz	a5,8000377e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000376e:	8526                	mv	a0,s1
    80003770:	70a2                	ld	ra,40(sp)
    80003772:	7402                	ld	s0,32(sp)
    80003774:	64e2                	ld	s1,24(sp)
    80003776:	6942                	ld	s2,16(sp)
    80003778:	69a2                	ld	s3,8(sp)
    8000377a:	6145                	addi	sp,sp,48
    8000377c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000377e:	4581                	li	a1,0
    80003780:	8526                	mv	a0,s1
    80003782:	00003097          	auipc	ra,0x3
    80003786:	fc6080e7          	jalr	-58(ra) # 80006748 <virtio_disk_rw>
    b->valid = 1;
    8000378a:	4785                	li	a5,1
    8000378c:	c09c                	sw	a5,0(s1)
  return b;
    8000378e:	b7c5                	j	8000376e <bread+0xd0>

0000000080003790 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003790:	1101                	addi	sp,sp,-32
    80003792:	ec06                	sd	ra,24(sp)
    80003794:	e822                	sd	s0,16(sp)
    80003796:	e426                	sd	s1,8(sp)
    80003798:	1000                	addi	s0,sp,32
    8000379a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000379c:	0541                	addi	a0,a0,16
    8000379e:	00001097          	auipc	ra,0x1
    800037a2:	46e080e7          	jalr	1134(ra) # 80004c0c <holdingsleep>
    800037a6:	cd01                	beqz	a0,800037be <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800037a8:	4585                	li	a1,1
    800037aa:	8526                	mv	a0,s1
    800037ac:	00003097          	auipc	ra,0x3
    800037b0:	f9c080e7          	jalr	-100(ra) # 80006748 <virtio_disk_rw>
}
    800037b4:	60e2                	ld	ra,24(sp)
    800037b6:	6442                	ld	s0,16(sp)
    800037b8:	64a2                	ld	s1,8(sp)
    800037ba:	6105                	addi	sp,sp,32
    800037bc:	8082                	ret
    panic("bwrite");
    800037be:	00005517          	auipc	a0,0x5
    800037c2:	ea250513          	addi	a0,a0,-350 # 80008660 <syscalls+0x108>
    800037c6:	ffffd097          	auipc	ra,0xffffd
    800037ca:	d7e080e7          	jalr	-642(ra) # 80000544 <panic>

00000000800037ce <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800037ce:	1101                	addi	sp,sp,-32
    800037d0:	ec06                	sd	ra,24(sp)
    800037d2:	e822                	sd	s0,16(sp)
    800037d4:	e426                	sd	s1,8(sp)
    800037d6:	e04a                	sd	s2,0(sp)
    800037d8:	1000                	addi	s0,sp,32
    800037da:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800037dc:	01050913          	addi	s2,a0,16
    800037e0:	854a                	mv	a0,s2
    800037e2:	00001097          	auipc	ra,0x1
    800037e6:	42a080e7          	jalr	1066(ra) # 80004c0c <holdingsleep>
    800037ea:	c92d                	beqz	a0,8000385c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800037ec:	854a                	mv	a0,s2
    800037ee:	00001097          	auipc	ra,0x1
    800037f2:	3da080e7          	jalr	986(ra) # 80004bc8 <releasesleep>

  acquire(&bcache.lock);
    800037f6:	00015517          	auipc	a0,0x15
    800037fa:	03a50513          	addi	a0,a0,58 # 80018830 <bcache>
    800037fe:	ffffd097          	auipc	ra,0xffffd
    80003802:	3ec080e7          	jalr	1004(ra) # 80000bea <acquire>
  b->refcnt--;
    80003806:	40bc                	lw	a5,64(s1)
    80003808:	37fd                	addiw	a5,a5,-1
    8000380a:	0007871b          	sext.w	a4,a5
    8000380e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003810:	eb05                	bnez	a4,80003840 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003812:	68bc                	ld	a5,80(s1)
    80003814:	64b8                	ld	a4,72(s1)
    80003816:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003818:	64bc                	ld	a5,72(s1)
    8000381a:	68b8                	ld	a4,80(s1)
    8000381c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000381e:	0001d797          	auipc	a5,0x1d
    80003822:	01278793          	addi	a5,a5,18 # 80020830 <bcache+0x8000>
    80003826:	2b87b703          	ld	a4,696(a5)
    8000382a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000382c:	0001d717          	auipc	a4,0x1d
    80003830:	26c70713          	addi	a4,a4,620 # 80020a98 <bcache+0x8268>
    80003834:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003836:	2b87b703          	ld	a4,696(a5)
    8000383a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000383c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003840:	00015517          	auipc	a0,0x15
    80003844:	ff050513          	addi	a0,a0,-16 # 80018830 <bcache>
    80003848:	ffffd097          	auipc	ra,0xffffd
    8000384c:	456080e7          	jalr	1110(ra) # 80000c9e <release>
}
    80003850:	60e2                	ld	ra,24(sp)
    80003852:	6442                	ld	s0,16(sp)
    80003854:	64a2                	ld	s1,8(sp)
    80003856:	6902                	ld	s2,0(sp)
    80003858:	6105                	addi	sp,sp,32
    8000385a:	8082                	ret
    panic("brelse");
    8000385c:	00005517          	auipc	a0,0x5
    80003860:	e0c50513          	addi	a0,a0,-500 # 80008668 <syscalls+0x110>
    80003864:	ffffd097          	auipc	ra,0xffffd
    80003868:	ce0080e7          	jalr	-800(ra) # 80000544 <panic>

000000008000386c <bpin>:

void
bpin(struct buf *b) {
    8000386c:	1101                	addi	sp,sp,-32
    8000386e:	ec06                	sd	ra,24(sp)
    80003870:	e822                	sd	s0,16(sp)
    80003872:	e426                	sd	s1,8(sp)
    80003874:	1000                	addi	s0,sp,32
    80003876:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003878:	00015517          	auipc	a0,0x15
    8000387c:	fb850513          	addi	a0,a0,-72 # 80018830 <bcache>
    80003880:	ffffd097          	auipc	ra,0xffffd
    80003884:	36a080e7          	jalr	874(ra) # 80000bea <acquire>
  b->refcnt++;
    80003888:	40bc                	lw	a5,64(s1)
    8000388a:	2785                	addiw	a5,a5,1
    8000388c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000388e:	00015517          	auipc	a0,0x15
    80003892:	fa250513          	addi	a0,a0,-94 # 80018830 <bcache>
    80003896:	ffffd097          	auipc	ra,0xffffd
    8000389a:	408080e7          	jalr	1032(ra) # 80000c9e <release>
}
    8000389e:	60e2                	ld	ra,24(sp)
    800038a0:	6442                	ld	s0,16(sp)
    800038a2:	64a2                	ld	s1,8(sp)
    800038a4:	6105                	addi	sp,sp,32
    800038a6:	8082                	ret

00000000800038a8 <bunpin>:

void
bunpin(struct buf *b) {
    800038a8:	1101                	addi	sp,sp,-32
    800038aa:	ec06                	sd	ra,24(sp)
    800038ac:	e822                	sd	s0,16(sp)
    800038ae:	e426                	sd	s1,8(sp)
    800038b0:	1000                	addi	s0,sp,32
    800038b2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800038b4:	00015517          	auipc	a0,0x15
    800038b8:	f7c50513          	addi	a0,a0,-132 # 80018830 <bcache>
    800038bc:	ffffd097          	auipc	ra,0xffffd
    800038c0:	32e080e7          	jalr	814(ra) # 80000bea <acquire>
  b->refcnt--;
    800038c4:	40bc                	lw	a5,64(s1)
    800038c6:	37fd                	addiw	a5,a5,-1
    800038c8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800038ca:	00015517          	auipc	a0,0x15
    800038ce:	f6650513          	addi	a0,a0,-154 # 80018830 <bcache>
    800038d2:	ffffd097          	auipc	ra,0xffffd
    800038d6:	3cc080e7          	jalr	972(ra) # 80000c9e <release>
}
    800038da:	60e2                	ld	ra,24(sp)
    800038dc:	6442                	ld	s0,16(sp)
    800038de:	64a2                	ld	s1,8(sp)
    800038e0:	6105                	addi	sp,sp,32
    800038e2:	8082                	ret

00000000800038e4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800038e4:	1101                	addi	sp,sp,-32
    800038e6:	ec06                	sd	ra,24(sp)
    800038e8:	e822                	sd	s0,16(sp)
    800038ea:	e426                	sd	s1,8(sp)
    800038ec:	e04a                	sd	s2,0(sp)
    800038ee:	1000                	addi	s0,sp,32
    800038f0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800038f2:	00d5d59b          	srliw	a1,a1,0xd
    800038f6:	0001d797          	auipc	a5,0x1d
    800038fa:	6167a783          	lw	a5,1558(a5) # 80020f0c <sb+0x1c>
    800038fe:	9dbd                	addw	a1,a1,a5
    80003900:	00000097          	auipc	ra,0x0
    80003904:	d9e080e7          	jalr	-610(ra) # 8000369e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003908:	0074f713          	andi	a4,s1,7
    8000390c:	4785                	li	a5,1
    8000390e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003912:	14ce                	slli	s1,s1,0x33
    80003914:	90d9                	srli	s1,s1,0x36
    80003916:	00950733          	add	a4,a0,s1
    8000391a:	05874703          	lbu	a4,88(a4)
    8000391e:	00e7f6b3          	and	a3,a5,a4
    80003922:	c69d                	beqz	a3,80003950 <bfree+0x6c>
    80003924:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003926:	94aa                	add	s1,s1,a0
    80003928:	fff7c793          	not	a5,a5
    8000392c:	8ff9                	and	a5,a5,a4
    8000392e:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003932:	00001097          	auipc	ra,0x1
    80003936:	120080e7          	jalr	288(ra) # 80004a52 <log_write>
  brelse(bp);
    8000393a:	854a                	mv	a0,s2
    8000393c:	00000097          	auipc	ra,0x0
    80003940:	e92080e7          	jalr	-366(ra) # 800037ce <brelse>
}
    80003944:	60e2                	ld	ra,24(sp)
    80003946:	6442                	ld	s0,16(sp)
    80003948:	64a2                	ld	s1,8(sp)
    8000394a:	6902                	ld	s2,0(sp)
    8000394c:	6105                	addi	sp,sp,32
    8000394e:	8082                	ret
    panic("freeing free block");
    80003950:	00005517          	auipc	a0,0x5
    80003954:	d2050513          	addi	a0,a0,-736 # 80008670 <syscalls+0x118>
    80003958:	ffffd097          	auipc	ra,0xffffd
    8000395c:	bec080e7          	jalr	-1044(ra) # 80000544 <panic>

0000000080003960 <balloc>:
{
    80003960:	711d                	addi	sp,sp,-96
    80003962:	ec86                	sd	ra,88(sp)
    80003964:	e8a2                	sd	s0,80(sp)
    80003966:	e4a6                	sd	s1,72(sp)
    80003968:	e0ca                	sd	s2,64(sp)
    8000396a:	fc4e                	sd	s3,56(sp)
    8000396c:	f852                	sd	s4,48(sp)
    8000396e:	f456                	sd	s5,40(sp)
    80003970:	f05a                	sd	s6,32(sp)
    80003972:	ec5e                	sd	s7,24(sp)
    80003974:	e862                	sd	s8,16(sp)
    80003976:	e466                	sd	s9,8(sp)
    80003978:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000397a:	0001d797          	auipc	a5,0x1d
    8000397e:	57a7a783          	lw	a5,1402(a5) # 80020ef4 <sb+0x4>
    80003982:	10078163          	beqz	a5,80003a84 <balloc+0x124>
    80003986:	8baa                	mv	s7,a0
    80003988:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000398a:	0001db17          	auipc	s6,0x1d
    8000398e:	566b0b13          	addi	s6,s6,1382 # 80020ef0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003992:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003994:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003996:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003998:	6c89                	lui	s9,0x2
    8000399a:	a061                	j	80003a22 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000399c:	974a                	add	a4,a4,s2
    8000399e:	8fd5                	or	a5,a5,a3
    800039a0:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800039a4:	854a                	mv	a0,s2
    800039a6:	00001097          	auipc	ra,0x1
    800039aa:	0ac080e7          	jalr	172(ra) # 80004a52 <log_write>
        brelse(bp);
    800039ae:	854a                	mv	a0,s2
    800039b0:	00000097          	auipc	ra,0x0
    800039b4:	e1e080e7          	jalr	-482(ra) # 800037ce <brelse>
  bp = bread(dev, bno);
    800039b8:	85a6                	mv	a1,s1
    800039ba:	855e                	mv	a0,s7
    800039bc:	00000097          	auipc	ra,0x0
    800039c0:	ce2080e7          	jalr	-798(ra) # 8000369e <bread>
    800039c4:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800039c6:	40000613          	li	a2,1024
    800039ca:	4581                	li	a1,0
    800039cc:	05850513          	addi	a0,a0,88
    800039d0:	ffffd097          	auipc	ra,0xffffd
    800039d4:	316080e7          	jalr	790(ra) # 80000ce6 <memset>
  log_write(bp);
    800039d8:	854a                	mv	a0,s2
    800039da:	00001097          	auipc	ra,0x1
    800039de:	078080e7          	jalr	120(ra) # 80004a52 <log_write>
  brelse(bp);
    800039e2:	854a                	mv	a0,s2
    800039e4:	00000097          	auipc	ra,0x0
    800039e8:	dea080e7          	jalr	-534(ra) # 800037ce <brelse>
}
    800039ec:	8526                	mv	a0,s1
    800039ee:	60e6                	ld	ra,88(sp)
    800039f0:	6446                	ld	s0,80(sp)
    800039f2:	64a6                	ld	s1,72(sp)
    800039f4:	6906                	ld	s2,64(sp)
    800039f6:	79e2                	ld	s3,56(sp)
    800039f8:	7a42                	ld	s4,48(sp)
    800039fa:	7aa2                	ld	s5,40(sp)
    800039fc:	7b02                	ld	s6,32(sp)
    800039fe:	6be2                	ld	s7,24(sp)
    80003a00:	6c42                	ld	s8,16(sp)
    80003a02:	6ca2                	ld	s9,8(sp)
    80003a04:	6125                	addi	sp,sp,96
    80003a06:	8082                	ret
    brelse(bp);
    80003a08:	854a                	mv	a0,s2
    80003a0a:	00000097          	auipc	ra,0x0
    80003a0e:	dc4080e7          	jalr	-572(ra) # 800037ce <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003a12:	015c87bb          	addw	a5,s9,s5
    80003a16:	00078a9b          	sext.w	s5,a5
    80003a1a:	004b2703          	lw	a4,4(s6)
    80003a1e:	06eaf363          	bgeu	s5,a4,80003a84 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003a22:	41fad79b          	sraiw	a5,s5,0x1f
    80003a26:	0137d79b          	srliw	a5,a5,0x13
    80003a2a:	015787bb          	addw	a5,a5,s5
    80003a2e:	40d7d79b          	sraiw	a5,a5,0xd
    80003a32:	01cb2583          	lw	a1,28(s6)
    80003a36:	9dbd                	addw	a1,a1,a5
    80003a38:	855e                	mv	a0,s7
    80003a3a:	00000097          	auipc	ra,0x0
    80003a3e:	c64080e7          	jalr	-924(ra) # 8000369e <bread>
    80003a42:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a44:	004b2503          	lw	a0,4(s6)
    80003a48:	000a849b          	sext.w	s1,s5
    80003a4c:	8662                	mv	a2,s8
    80003a4e:	faa4fde3          	bgeu	s1,a0,80003a08 <balloc+0xa8>
      m = 1 << (bi % 8);
    80003a52:	41f6579b          	sraiw	a5,a2,0x1f
    80003a56:	01d7d69b          	srliw	a3,a5,0x1d
    80003a5a:	00c6873b          	addw	a4,a3,a2
    80003a5e:	00777793          	andi	a5,a4,7
    80003a62:	9f95                	subw	a5,a5,a3
    80003a64:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003a68:	4037571b          	sraiw	a4,a4,0x3
    80003a6c:	00e906b3          	add	a3,s2,a4
    80003a70:	0586c683          	lbu	a3,88(a3)
    80003a74:	00d7f5b3          	and	a1,a5,a3
    80003a78:	d195                	beqz	a1,8000399c <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a7a:	2605                	addiw	a2,a2,1
    80003a7c:	2485                	addiw	s1,s1,1
    80003a7e:	fd4618e3          	bne	a2,s4,80003a4e <balloc+0xee>
    80003a82:	b759                	j	80003a08 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003a84:	00005517          	auipc	a0,0x5
    80003a88:	c0450513          	addi	a0,a0,-1020 # 80008688 <syscalls+0x130>
    80003a8c:	ffffd097          	auipc	ra,0xffffd
    80003a90:	b02080e7          	jalr	-1278(ra) # 8000058e <printf>
  return 0;
    80003a94:	4481                	li	s1,0
    80003a96:	bf99                	j	800039ec <balloc+0x8c>

0000000080003a98 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003a98:	7179                	addi	sp,sp,-48
    80003a9a:	f406                	sd	ra,40(sp)
    80003a9c:	f022                	sd	s0,32(sp)
    80003a9e:	ec26                	sd	s1,24(sp)
    80003aa0:	e84a                	sd	s2,16(sp)
    80003aa2:	e44e                	sd	s3,8(sp)
    80003aa4:	e052                	sd	s4,0(sp)
    80003aa6:	1800                	addi	s0,sp,48
    80003aa8:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003aaa:	47ad                	li	a5,11
    80003aac:	02b7e763          	bltu	a5,a1,80003ada <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003ab0:	02059493          	slli	s1,a1,0x20
    80003ab4:	9081                	srli	s1,s1,0x20
    80003ab6:	048a                	slli	s1,s1,0x2
    80003ab8:	94aa                	add	s1,s1,a0
    80003aba:	0504a903          	lw	s2,80(s1)
    80003abe:	06091e63          	bnez	s2,80003b3a <bmap+0xa2>
      addr = balloc(ip->dev);
    80003ac2:	4108                	lw	a0,0(a0)
    80003ac4:	00000097          	auipc	ra,0x0
    80003ac8:	e9c080e7          	jalr	-356(ra) # 80003960 <balloc>
    80003acc:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003ad0:	06090563          	beqz	s2,80003b3a <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003ad4:	0524a823          	sw	s2,80(s1)
    80003ad8:	a08d                	j	80003b3a <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003ada:	ff45849b          	addiw	s1,a1,-12
    80003ade:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003ae2:	0ff00793          	li	a5,255
    80003ae6:	08e7e563          	bltu	a5,a4,80003b70 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003aea:	08052903          	lw	s2,128(a0)
    80003aee:	00091d63          	bnez	s2,80003b08 <bmap+0x70>
      addr = balloc(ip->dev);
    80003af2:	4108                	lw	a0,0(a0)
    80003af4:	00000097          	auipc	ra,0x0
    80003af8:	e6c080e7          	jalr	-404(ra) # 80003960 <balloc>
    80003afc:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003b00:	02090d63          	beqz	s2,80003b3a <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003b04:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003b08:	85ca                	mv	a1,s2
    80003b0a:	0009a503          	lw	a0,0(s3)
    80003b0e:	00000097          	auipc	ra,0x0
    80003b12:	b90080e7          	jalr	-1136(ra) # 8000369e <bread>
    80003b16:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003b18:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003b1c:	02049593          	slli	a1,s1,0x20
    80003b20:	9181                	srli	a1,a1,0x20
    80003b22:	058a                	slli	a1,a1,0x2
    80003b24:	00b784b3          	add	s1,a5,a1
    80003b28:	0004a903          	lw	s2,0(s1)
    80003b2c:	02090063          	beqz	s2,80003b4c <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003b30:	8552                	mv	a0,s4
    80003b32:	00000097          	auipc	ra,0x0
    80003b36:	c9c080e7          	jalr	-868(ra) # 800037ce <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003b3a:	854a                	mv	a0,s2
    80003b3c:	70a2                	ld	ra,40(sp)
    80003b3e:	7402                	ld	s0,32(sp)
    80003b40:	64e2                	ld	s1,24(sp)
    80003b42:	6942                	ld	s2,16(sp)
    80003b44:	69a2                	ld	s3,8(sp)
    80003b46:	6a02                	ld	s4,0(sp)
    80003b48:	6145                	addi	sp,sp,48
    80003b4a:	8082                	ret
      addr = balloc(ip->dev);
    80003b4c:	0009a503          	lw	a0,0(s3)
    80003b50:	00000097          	auipc	ra,0x0
    80003b54:	e10080e7          	jalr	-496(ra) # 80003960 <balloc>
    80003b58:	0005091b          	sext.w	s2,a0
      if(addr){
    80003b5c:	fc090ae3          	beqz	s2,80003b30 <bmap+0x98>
        a[bn] = addr;
    80003b60:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003b64:	8552                	mv	a0,s4
    80003b66:	00001097          	auipc	ra,0x1
    80003b6a:	eec080e7          	jalr	-276(ra) # 80004a52 <log_write>
    80003b6e:	b7c9                	j	80003b30 <bmap+0x98>
  panic("bmap: out of range");
    80003b70:	00005517          	auipc	a0,0x5
    80003b74:	b3050513          	addi	a0,a0,-1232 # 800086a0 <syscalls+0x148>
    80003b78:	ffffd097          	auipc	ra,0xffffd
    80003b7c:	9cc080e7          	jalr	-1588(ra) # 80000544 <panic>

0000000080003b80 <iget>:
{
    80003b80:	7179                	addi	sp,sp,-48
    80003b82:	f406                	sd	ra,40(sp)
    80003b84:	f022                	sd	s0,32(sp)
    80003b86:	ec26                	sd	s1,24(sp)
    80003b88:	e84a                	sd	s2,16(sp)
    80003b8a:	e44e                	sd	s3,8(sp)
    80003b8c:	e052                	sd	s4,0(sp)
    80003b8e:	1800                	addi	s0,sp,48
    80003b90:	89aa                	mv	s3,a0
    80003b92:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003b94:	0001d517          	auipc	a0,0x1d
    80003b98:	37c50513          	addi	a0,a0,892 # 80020f10 <itable>
    80003b9c:	ffffd097          	auipc	ra,0xffffd
    80003ba0:	04e080e7          	jalr	78(ra) # 80000bea <acquire>
  empty = 0;
    80003ba4:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003ba6:	0001d497          	auipc	s1,0x1d
    80003baa:	38248493          	addi	s1,s1,898 # 80020f28 <itable+0x18>
    80003bae:	0001f697          	auipc	a3,0x1f
    80003bb2:	e0a68693          	addi	a3,a3,-502 # 800229b8 <log>
    80003bb6:	a039                	j	80003bc4 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003bb8:	02090b63          	beqz	s2,80003bee <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003bbc:	08848493          	addi	s1,s1,136
    80003bc0:	02d48a63          	beq	s1,a3,80003bf4 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003bc4:	449c                	lw	a5,8(s1)
    80003bc6:	fef059e3          	blez	a5,80003bb8 <iget+0x38>
    80003bca:	4098                	lw	a4,0(s1)
    80003bcc:	ff3716e3          	bne	a4,s3,80003bb8 <iget+0x38>
    80003bd0:	40d8                	lw	a4,4(s1)
    80003bd2:	ff4713e3          	bne	a4,s4,80003bb8 <iget+0x38>
      ip->ref++;
    80003bd6:	2785                	addiw	a5,a5,1
    80003bd8:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003bda:	0001d517          	auipc	a0,0x1d
    80003bde:	33650513          	addi	a0,a0,822 # 80020f10 <itable>
    80003be2:	ffffd097          	auipc	ra,0xffffd
    80003be6:	0bc080e7          	jalr	188(ra) # 80000c9e <release>
      return ip;
    80003bea:	8926                	mv	s2,s1
    80003bec:	a03d                	j	80003c1a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003bee:	f7f9                	bnez	a5,80003bbc <iget+0x3c>
    80003bf0:	8926                	mv	s2,s1
    80003bf2:	b7e9                	j	80003bbc <iget+0x3c>
  if(empty == 0)
    80003bf4:	02090c63          	beqz	s2,80003c2c <iget+0xac>
  ip->dev = dev;
    80003bf8:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003bfc:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003c00:	4785                	li	a5,1
    80003c02:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003c06:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003c0a:	0001d517          	auipc	a0,0x1d
    80003c0e:	30650513          	addi	a0,a0,774 # 80020f10 <itable>
    80003c12:	ffffd097          	auipc	ra,0xffffd
    80003c16:	08c080e7          	jalr	140(ra) # 80000c9e <release>
}
    80003c1a:	854a                	mv	a0,s2
    80003c1c:	70a2                	ld	ra,40(sp)
    80003c1e:	7402                	ld	s0,32(sp)
    80003c20:	64e2                	ld	s1,24(sp)
    80003c22:	6942                	ld	s2,16(sp)
    80003c24:	69a2                	ld	s3,8(sp)
    80003c26:	6a02                	ld	s4,0(sp)
    80003c28:	6145                	addi	sp,sp,48
    80003c2a:	8082                	ret
    panic("iget: no inodes");
    80003c2c:	00005517          	auipc	a0,0x5
    80003c30:	a8c50513          	addi	a0,a0,-1396 # 800086b8 <syscalls+0x160>
    80003c34:	ffffd097          	auipc	ra,0xffffd
    80003c38:	910080e7          	jalr	-1776(ra) # 80000544 <panic>

0000000080003c3c <fsinit>:
fsinit(int dev) {
    80003c3c:	7179                	addi	sp,sp,-48
    80003c3e:	f406                	sd	ra,40(sp)
    80003c40:	f022                	sd	s0,32(sp)
    80003c42:	ec26                	sd	s1,24(sp)
    80003c44:	e84a                	sd	s2,16(sp)
    80003c46:	e44e                	sd	s3,8(sp)
    80003c48:	1800                	addi	s0,sp,48
    80003c4a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003c4c:	4585                	li	a1,1
    80003c4e:	00000097          	auipc	ra,0x0
    80003c52:	a50080e7          	jalr	-1456(ra) # 8000369e <bread>
    80003c56:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003c58:	0001d997          	auipc	s3,0x1d
    80003c5c:	29898993          	addi	s3,s3,664 # 80020ef0 <sb>
    80003c60:	02000613          	li	a2,32
    80003c64:	05850593          	addi	a1,a0,88
    80003c68:	854e                	mv	a0,s3
    80003c6a:	ffffd097          	auipc	ra,0xffffd
    80003c6e:	0dc080e7          	jalr	220(ra) # 80000d46 <memmove>
  brelse(bp);
    80003c72:	8526                	mv	a0,s1
    80003c74:	00000097          	auipc	ra,0x0
    80003c78:	b5a080e7          	jalr	-1190(ra) # 800037ce <brelse>
  if(sb.magic != FSMAGIC)
    80003c7c:	0009a703          	lw	a4,0(s3)
    80003c80:	102037b7          	lui	a5,0x10203
    80003c84:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003c88:	02f71263          	bne	a4,a5,80003cac <fsinit+0x70>
  initlog(dev, &sb);
    80003c8c:	0001d597          	auipc	a1,0x1d
    80003c90:	26458593          	addi	a1,a1,612 # 80020ef0 <sb>
    80003c94:	854a                	mv	a0,s2
    80003c96:	00001097          	auipc	ra,0x1
    80003c9a:	b40080e7          	jalr	-1216(ra) # 800047d6 <initlog>
}
    80003c9e:	70a2                	ld	ra,40(sp)
    80003ca0:	7402                	ld	s0,32(sp)
    80003ca2:	64e2                	ld	s1,24(sp)
    80003ca4:	6942                	ld	s2,16(sp)
    80003ca6:	69a2                	ld	s3,8(sp)
    80003ca8:	6145                	addi	sp,sp,48
    80003caa:	8082                	ret
    panic("invalid file system");
    80003cac:	00005517          	auipc	a0,0x5
    80003cb0:	a1c50513          	addi	a0,a0,-1508 # 800086c8 <syscalls+0x170>
    80003cb4:	ffffd097          	auipc	ra,0xffffd
    80003cb8:	890080e7          	jalr	-1904(ra) # 80000544 <panic>

0000000080003cbc <iinit>:
{
    80003cbc:	7179                	addi	sp,sp,-48
    80003cbe:	f406                	sd	ra,40(sp)
    80003cc0:	f022                	sd	s0,32(sp)
    80003cc2:	ec26                	sd	s1,24(sp)
    80003cc4:	e84a                	sd	s2,16(sp)
    80003cc6:	e44e                	sd	s3,8(sp)
    80003cc8:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003cca:	00005597          	auipc	a1,0x5
    80003cce:	a1658593          	addi	a1,a1,-1514 # 800086e0 <syscalls+0x188>
    80003cd2:	0001d517          	auipc	a0,0x1d
    80003cd6:	23e50513          	addi	a0,a0,574 # 80020f10 <itable>
    80003cda:	ffffd097          	auipc	ra,0xffffd
    80003cde:	e80080e7          	jalr	-384(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    80003ce2:	0001d497          	auipc	s1,0x1d
    80003ce6:	25648493          	addi	s1,s1,598 # 80020f38 <itable+0x28>
    80003cea:	0001f997          	auipc	s3,0x1f
    80003cee:	cde98993          	addi	s3,s3,-802 # 800229c8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003cf2:	00005917          	auipc	s2,0x5
    80003cf6:	9f690913          	addi	s2,s2,-1546 # 800086e8 <syscalls+0x190>
    80003cfa:	85ca                	mv	a1,s2
    80003cfc:	8526                	mv	a0,s1
    80003cfe:	00001097          	auipc	ra,0x1
    80003d02:	e3a080e7          	jalr	-454(ra) # 80004b38 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003d06:	08848493          	addi	s1,s1,136
    80003d0a:	ff3498e3          	bne	s1,s3,80003cfa <iinit+0x3e>
}
    80003d0e:	70a2                	ld	ra,40(sp)
    80003d10:	7402                	ld	s0,32(sp)
    80003d12:	64e2                	ld	s1,24(sp)
    80003d14:	6942                	ld	s2,16(sp)
    80003d16:	69a2                	ld	s3,8(sp)
    80003d18:	6145                	addi	sp,sp,48
    80003d1a:	8082                	ret

0000000080003d1c <ialloc>:
{
    80003d1c:	715d                	addi	sp,sp,-80
    80003d1e:	e486                	sd	ra,72(sp)
    80003d20:	e0a2                	sd	s0,64(sp)
    80003d22:	fc26                	sd	s1,56(sp)
    80003d24:	f84a                	sd	s2,48(sp)
    80003d26:	f44e                	sd	s3,40(sp)
    80003d28:	f052                	sd	s4,32(sp)
    80003d2a:	ec56                	sd	s5,24(sp)
    80003d2c:	e85a                	sd	s6,16(sp)
    80003d2e:	e45e                	sd	s7,8(sp)
    80003d30:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d32:	0001d717          	auipc	a4,0x1d
    80003d36:	1ca72703          	lw	a4,458(a4) # 80020efc <sb+0xc>
    80003d3a:	4785                	li	a5,1
    80003d3c:	04e7fa63          	bgeu	a5,a4,80003d90 <ialloc+0x74>
    80003d40:	8aaa                	mv	s5,a0
    80003d42:	8bae                	mv	s7,a1
    80003d44:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003d46:	0001da17          	auipc	s4,0x1d
    80003d4a:	1aaa0a13          	addi	s4,s4,426 # 80020ef0 <sb>
    80003d4e:	00048b1b          	sext.w	s6,s1
    80003d52:	0044d593          	srli	a1,s1,0x4
    80003d56:	018a2783          	lw	a5,24(s4)
    80003d5a:	9dbd                	addw	a1,a1,a5
    80003d5c:	8556                	mv	a0,s5
    80003d5e:	00000097          	auipc	ra,0x0
    80003d62:	940080e7          	jalr	-1728(ra) # 8000369e <bread>
    80003d66:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003d68:	05850993          	addi	s3,a0,88
    80003d6c:	00f4f793          	andi	a5,s1,15
    80003d70:	079a                	slli	a5,a5,0x6
    80003d72:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003d74:	00099783          	lh	a5,0(s3)
    80003d78:	c3a1                	beqz	a5,80003db8 <ialloc+0x9c>
    brelse(bp);
    80003d7a:	00000097          	auipc	ra,0x0
    80003d7e:	a54080e7          	jalr	-1452(ra) # 800037ce <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d82:	0485                	addi	s1,s1,1
    80003d84:	00ca2703          	lw	a4,12(s4)
    80003d88:	0004879b          	sext.w	a5,s1
    80003d8c:	fce7e1e3          	bltu	a5,a4,80003d4e <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003d90:	00005517          	auipc	a0,0x5
    80003d94:	96050513          	addi	a0,a0,-1696 # 800086f0 <syscalls+0x198>
    80003d98:	ffffc097          	auipc	ra,0xffffc
    80003d9c:	7f6080e7          	jalr	2038(ra) # 8000058e <printf>
  return 0;
    80003da0:	4501                	li	a0,0
}
    80003da2:	60a6                	ld	ra,72(sp)
    80003da4:	6406                	ld	s0,64(sp)
    80003da6:	74e2                	ld	s1,56(sp)
    80003da8:	7942                	ld	s2,48(sp)
    80003daa:	79a2                	ld	s3,40(sp)
    80003dac:	7a02                	ld	s4,32(sp)
    80003dae:	6ae2                	ld	s5,24(sp)
    80003db0:	6b42                	ld	s6,16(sp)
    80003db2:	6ba2                	ld	s7,8(sp)
    80003db4:	6161                	addi	sp,sp,80
    80003db6:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003db8:	04000613          	li	a2,64
    80003dbc:	4581                	li	a1,0
    80003dbe:	854e                	mv	a0,s3
    80003dc0:	ffffd097          	auipc	ra,0xffffd
    80003dc4:	f26080e7          	jalr	-218(ra) # 80000ce6 <memset>
      dip->type = type;
    80003dc8:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003dcc:	854a                	mv	a0,s2
    80003dce:	00001097          	auipc	ra,0x1
    80003dd2:	c84080e7          	jalr	-892(ra) # 80004a52 <log_write>
      brelse(bp);
    80003dd6:	854a                	mv	a0,s2
    80003dd8:	00000097          	auipc	ra,0x0
    80003ddc:	9f6080e7          	jalr	-1546(ra) # 800037ce <brelse>
      return iget(dev, inum);
    80003de0:	85da                	mv	a1,s6
    80003de2:	8556                	mv	a0,s5
    80003de4:	00000097          	auipc	ra,0x0
    80003de8:	d9c080e7          	jalr	-612(ra) # 80003b80 <iget>
    80003dec:	bf5d                	j	80003da2 <ialloc+0x86>

0000000080003dee <iupdate>:
{
    80003dee:	1101                	addi	sp,sp,-32
    80003df0:	ec06                	sd	ra,24(sp)
    80003df2:	e822                	sd	s0,16(sp)
    80003df4:	e426                	sd	s1,8(sp)
    80003df6:	e04a                	sd	s2,0(sp)
    80003df8:	1000                	addi	s0,sp,32
    80003dfa:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003dfc:	415c                	lw	a5,4(a0)
    80003dfe:	0047d79b          	srliw	a5,a5,0x4
    80003e02:	0001d597          	auipc	a1,0x1d
    80003e06:	1065a583          	lw	a1,262(a1) # 80020f08 <sb+0x18>
    80003e0a:	9dbd                	addw	a1,a1,a5
    80003e0c:	4108                	lw	a0,0(a0)
    80003e0e:	00000097          	auipc	ra,0x0
    80003e12:	890080e7          	jalr	-1904(ra) # 8000369e <bread>
    80003e16:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e18:	05850793          	addi	a5,a0,88
    80003e1c:	40c8                	lw	a0,4(s1)
    80003e1e:	893d                	andi	a0,a0,15
    80003e20:	051a                	slli	a0,a0,0x6
    80003e22:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003e24:	04449703          	lh	a4,68(s1)
    80003e28:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003e2c:	04649703          	lh	a4,70(s1)
    80003e30:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003e34:	04849703          	lh	a4,72(s1)
    80003e38:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003e3c:	04a49703          	lh	a4,74(s1)
    80003e40:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003e44:	44f8                	lw	a4,76(s1)
    80003e46:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003e48:	03400613          	li	a2,52
    80003e4c:	05048593          	addi	a1,s1,80
    80003e50:	0531                	addi	a0,a0,12
    80003e52:	ffffd097          	auipc	ra,0xffffd
    80003e56:	ef4080e7          	jalr	-268(ra) # 80000d46 <memmove>
  log_write(bp);
    80003e5a:	854a                	mv	a0,s2
    80003e5c:	00001097          	auipc	ra,0x1
    80003e60:	bf6080e7          	jalr	-1034(ra) # 80004a52 <log_write>
  brelse(bp);
    80003e64:	854a                	mv	a0,s2
    80003e66:	00000097          	auipc	ra,0x0
    80003e6a:	968080e7          	jalr	-1688(ra) # 800037ce <brelse>
}
    80003e6e:	60e2                	ld	ra,24(sp)
    80003e70:	6442                	ld	s0,16(sp)
    80003e72:	64a2                	ld	s1,8(sp)
    80003e74:	6902                	ld	s2,0(sp)
    80003e76:	6105                	addi	sp,sp,32
    80003e78:	8082                	ret

0000000080003e7a <idup>:
{
    80003e7a:	1101                	addi	sp,sp,-32
    80003e7c:	ec06                	sd	ra,24(sp)
    80003e7e:	e822                	sd	s0,16(sp)
    80003e80:	e426                	sd	s1,8(sp)
    80003e82:	1000                	addi	s0,sp,32
    80003e84:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e86:	0001d517          	auipc	a0,0x1d
    80003e8a:	08a50513          	addi	a0,a0,138 # 80020f10 <itable>
    80003e8e:	ffffd097          	auipc	ra,0xffffd
    80003e92:	d5c080e7          	jalr	-676(ra) # 80000bea <acquire>
  ip->ref++;
    80003e96:	449c                	lw	a5,8(s1)
    80003e98:	2785                	addiw	a5,a5,1
    80003e9a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e9c:	0001d517          	auipc	a0,0x1d
    80003ea0:	07450513          	addi	a0,a0,116 # 80020f10 <itable>
    80003ea4:	ffffd097          	auipc	ra,0xffffd
    80003ea8:	dfa080e7          	jalr	-518(ra) # 80000c9e <release>
}
    80003eac:	8526                	mv	a0,s1
    80003eae:	60e2                	ld	ra,24(sp)
    80003eb0:	6442                	ld	s0,16(sp)
    80003eb2:	64a2                	ld	s1,8(sp)
    80003eb4:	6105                	addi	sp,sp,32
    80003eb6:	8082                	ret

0000000080003eb8 <ilock>:
{
    80003eb8:	1101                	addi	sp,sp,-32
    80003eba:	ec06                	sd	ra,24(sp)
    80003ebc:	e822                	sd	s0,16(sp)
    80003ebe:	e426                	sd	s1,8(sp)
    80003ec0:	e04a                	sd	s2,0(sp)
    80003ec2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003ec4:	c115                	beqz	a0,80003ee8 <ilock+0x30>
    80003ec6:	84aa                	mv	s1,a0
    80003ec8:	451c                	lw	a5,8(a0)
    80003eca:	00f05f63          	blez	a5,80003ee8 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003ece:	0541                	addi	a0,a0,16
    80003ed0:	00001097          	auipc	ra,0x1
    80003ed4:	ca2080e7          	jalr	-862(ra) # 80004b72 <acquiresleep>
  if(ip->valid == 0){
    80003ed8:	40bc                	lw	a5,64(s1)
    80003eda:	cf99                	beqz	a5,80003ef8 <ilock+0x40>
}
    80003edc:	60e2                	ld	ra,24(sp)
    80003ede:	6442                	ld	s0,16(sp)
    80003ee0:	64a2                	ld	s1,8(sp)
    80003ee2:	6902                	ld	s2,0(sp)
    80003ee4:	6105                	addi	sp,sp,32
    80003ee6:	8082                	ret
    panic("ilock");
    80003ee8:	00005517          	auipc	a0,0x5
    80003eec:	82050513          	addi	a0,a0,-2016 # 80008708 <syscalls+0x1b0>
    80003ef0:	ffffc097          	auipc	ra,0xffffc
    80003ef4:	654080e7          	jalr	1620(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ef8:	40dc                	lw	a5,4(s1)
    80003efa:	0047d79b          	srliw	a5,a5,0x4
    80003efe:	0001d597          	auipc	a1,0x1d
    80003f02:	00a5a583          	lw	a1,10(a1) # 80020f08 <sb+0x18>
    80003f06:	9dbd                	addw	a1,a1,a5
    80003f08:	4088                	lw	a0,0(s1)
    80003f0a:	fffff097          	auipc	ra,0xfffff
    80003f0e:	794080e7          	jalr	1940(ra) # 8000369e <bread>
    80003f12:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003f14:	05850593          	addi	a1,a0,88
    80003f18:	40dc                	lw	a5,4(s1)
    80003f1a:	8bbd                	andi	a5,a5,15
    80003f1c:	079a                	slli	a5,a5,0x6
    80003f1e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003f20:	00059783          	lh	a5,0(a1)
    80003f24:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003f28:	00259783          	lh	a5,2(a1)
    80003f2c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003f30:	00459783          	lh	a5,4(a1)
    80003f34:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003f38:	00659783          	lh	a5,6(a1)
    80003f3c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003f40:	459c                	lw	a5,8(a1)
    80003f42:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003f44:	03400613          	li	a2,52
    80003f48:	05b1                	addi	a1,a1,12
    80003f4a:	05048513          	addi	a0,s1,80
    80003f4e:	ffffd097          	auipc	ra,0xffffd
    80003f52:	df8080e7          	jalr	-520(ra) # 80000d46 <memmove>
    brelse(bp);
    80003f56:	854a                	mv	a0,s2
    80003f58:	00000097          	auipc	ra,0x0
    80003f5c:	876080e7          	jalr	-1930(ra) # 800037ce <brelse>
    ip->valid = 1;
    80003f60:	4785                	li	a5,1
    80003f62:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003f64:	04449783          	lh	a5,68(s1)
    80003f68:	fbb5                	bnez	a5,80003edc <ilock+0x24>
      panic("ilock: no type");
    80003f6a:	00004517          	auipc	a0,0x4
    80003f6e:	7a650513          	addi	a0,a0,1958 # 80008710 <syscalls+0x1b8>
    80003f72:	ffffc097          	auipc	ra,0xffffc
    80003f76:	5d2080e7          	jalr	1490(ra) # 80000544 <panic>

0000000080003f7a <iunlock>:
{
    80003f7a:	1101                	addi	sp,sp,-32
    80003f7c:	ec06                	sd	ra,24(sp)
    80003f7e:	e822                	sd	s0,16(sp)
    80003f80:	e426                	sd	s1,8(sp)
    80003f82:	e04a                	sd	s2,0(sp)
    80003f84:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003f86:	c905                	beqz	a0,80003fb6 <iunlock+0x3c>
    80003f88:	84aa                	mv	s1,a0
    80003f8a:	01050913          	addi	s2,a0,16
    80003f8e:	854a                	mv	a0,s2
    80003f90:	00001097          	auipc	ra,0x1
    80003f94:	c7c080e7          	jalr	-900(ra) # 80004c0c <holdingsleep>
    80003f98:	cd19                	beqz	a0,80003fb6 <iunlock+0x3c>
    80003f9a:	449c                	lw	a5,8(s1)
    80003f9c:	00f05d63          	blez	a5,80003fb6 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003fa0:	854a                	mv	a0,s2
    80003fa2:	00001097          	auipc	ra,0x1
    80003fa6:	c26080e7          	jalr	-986(ra) # 80004bc8 <releasesleep>
}
    80003faa:	60e2                	ld	ra,24(sp)
    80003fac:	6442                	ld	s0,16(sp)
    80003fae:	64a2                	ld	s1,8(sp)
    80003fb0:	6902                	ld	s2,0(sp)
    80003fb2:	6105                	addi	sp,sp,32
    80003fb4:	8082                	ret
    panic("iunlock");
    80003fb6:	00004517          	auipc	a0,0x4
    80003fba:	76a50513          	addi	a0,a0,1898 # 80008720 <syscalls+0x1c8>
    80003fbe:	ffffc097          	auipc	ra,0xffffc
    80003fc2:	586080e7          	jalr	1414(ra) # 80000544 <panic>

0000000080003fc6 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003fc6:	7179                	addi	sp,sp,-48
    80003fc8:	f406                	sd	ra,40(sp)
    80003fca:	f022                	sd	s0,32(sp)
    80003fcc:	ec26                	sd	s1,24(sp)
    80003fce:	e84a                	sd	s2,16(sp)
    80003fd0:	e44e                	sd	s3,8(sp)
    80003fd2:	e052                	sd	s4,0(sp)
    80003fd4:	1800                	addi	s0,sp,48
    80003fd6:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003fd8:	05050493          	addi	s1,a0,80
    80003fdc:	08050913          	addi	s2,a0,128
    80003fe0:	a021                	j	80003fe8 <itrunc+0x22>
    80003fe2:	0491                	addi	s1,s1,4
    80003fe4:	01248d63          	beq	s1,s2,80003ffe <itrunc+0x38>
    if(ip->addrs[i]){
    80003fe8:	408c                	lw	a1,0(s1)
    80003fea:	dde5                	beqz	a1,80003fe2 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003fec:	0009a503          	lw	a0,0(s3)
    80003ff0:	00000097          	auipc	ra,0x0
    80003ff4:	8f4080e7          	jalr	-1804(ra) # 800038e4 <bfree>
      ip->addrs[i] = 0;
    80003ff8:	0004a023          	sw	zero,0(s1)
    80003ffc:	b7dd                	j	80003fe2 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003ffe:	0809a583          	lw	a1,128(s3)
    80004002:	e185                	bnez	a1,80004022 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004004:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004008:	854e                	mv	a0,s3
    8000400a:	00000097          	auipc	ra,0x0
    8000400e:	de4080e7          	jalr	-540(ra) # 80003dee <iupdate>
}
    80004012:	70a2                	ld	ra,40(sp)
    80004014:	7402                	ld	s0,32(sp)
    80004016:	64e2                	ld	s1,24(sp)
    80004018:	6942                	ld	s2,16(sp)
    8000401a:	69a2                	ld	s3,8(sp)
    8000401c:	6a02                	ld	s4,0(sp)
    8000401e:	6145                	addi	sp,sp,48
    80004020:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004022:	0009a503          	lw	a0,0(s3)
    80004026:	fffff097          	auipc	ra,0xfffff
    8000402a:	678080e7          	jalr	1656(ra) # 8000369e <bread>
    8000402e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004030:	05850493          	addi	s1,a0,88
    80004034:	45850913          	addi	s2,a0,1112
    80004038:	a811                	j	8000404c <itrunc+0x86>
        bfree(ip->dev, a[j]);
    8000403a:	0009a503          	lw	a0,0(s3)
    8000403e:	00000097          	auipc	ra,0x0
    80004042:	8a6080e7          	jalr	-1882(ra) # 800038e4 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80004046:	0491                	addi	s1,s1,4
    80004048:	01248563          	beq	s1,s2,80004052 <itrunc+0x8c>
      if(a[j])
    8000404c:	408c                	lw	a1,0(s1)
    8000404e:	dde5                	beqz	a1,80004046 <itrunc+0x80>
    80004050:	b7ed                	j	8000403a <itrunc+0x74>
    brelse(bp);
    80004052:	8552                	mv	a0,s4
    80004054:	fffff097          	auipc	ra,0xfffff
    80004058:	77a080e7          	jalr	1914(ra) # 800037ce <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000405c:	0809a583          	lw	a1,128(s3)
    80004060:	0009a503          	lw	a0,0(s3)
    80004064:	00000097          	auipc	ra,0x0
    80004068:	880080e7          	jalr	-1920(ra) # 800038e4 <bfree>
    ip->addrs[NDIRECT] = 0;
    8000406c:	0809a023          	sw	zero,128(s3)
    80004070:	bf51                	j	80004004 <itrunc+0x3e>

0000000080004072 <iput>:
{
    80004072:	1101                	addi	sp,sp,-32
    80004074:	ec06                	sd	ra,24(sp)
    80004076:	e822                	sd	s0,16(sp)
    80004078:	e426                	sd	s1,8(sp)
    8000407a:	e04a                	sd	s2,0(sp)
    8000407c:	1000                	addi	s0,sp,32
    8000407e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004080:	0001d517          	auipc	a0,0x1d
    80004084:	e9050513          	addi	a0,a0,-368 # 80020f10 <itable>
    80004088:	ffffd097          	auipc	ra,0xffffd
    8000408c:	b62080e7          	jalr	-1182(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004090:	4498                	lw	a4,8(s1)
    80004092:	4785                	li	a5,1
    80004094:	02f70363          	beq	a4,a5,800040ba <iput+0x48>
  ip->ref--;
    80004098:	449c                	lw	a5,8(s1)
    8000409a:	37fd                	addiw	a5,a5,-1
    8000409c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000409e:	0001d517          	auipc	a0,0x1d
    800040a2:	e7250513          	addi	a0,a0,-398 # 80020f10 <itable>
    800040a6:	ffffd097          	auipc	ra,0xffffd
    800040aa:	bf8080e7          	jalr	-1032(ra) # 80000c9e <release>
}
    800040ae:	60e2                	ld	ra,24(sp)
    800040b0:	6442                	ld	s0,16(sp)
    800040b2:	64a2                	ld	s1,8(sp)
    800040b4:	6902                	ld	s2,0(sp)
    800040b6:	6105                	addi	sp,sp,32
    800040b8:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800040ba:	40bc                	lw	a5,64(s1)
    800040bc:	dff1                	beqz	a5,80004098 <iput+0x26>
    800040be:	04a49783          	lh	a5,74(s1)
    800040c2:	fbf9                	bnez	a5,80004098 <iput+0x26>
    acquiresleep(&ip->lock);
    800040c4:	01048913          	addi	s2,s1,16
    800040c8:	854a                	mv	a0,s2
    800040ca:	00001097          	auipc	ra,0x1
    800040ce:	aa8080e7          	jalr	-1368(ra) # 80004b72 <acquiresleep>
    release(&itable.lock);
    800040d2:	0001d517          	auipc	a0,0x1d
    800040d6:	e3e50513          	addi	a0,a0,-450 # 80020f10 <itable>
    800040da:	ffffd097          	auipc	ra,0xffffd
    800040de:	bc4080e7          	jalr	-1084(ra) # 80000c9e <release>
    itrunc(ip);
    800040e2:	8526                	mv	a0,s1
    800040e4:	00000097          	auipc	ra,0x0
    800040e8:	ee2080e7          	jalr	-286(ra) # 80003fc6 <itrunc>
    ip->type = 0;
    800040ec:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800040f0:	8526                	mv	a0,s1
    800040f2:	00000097          	auipc	ra,0x0
    800040f6:	cfc080e7          	jalr	-772(ra) # 80003dee <iupdate>
    ip->valid = 0;
    800040fa:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800040fe:	854a                	mv	a0,s2
    80004100:	00001097          	auipc	ra,0x1
    80004104:	ac8080e7          	jalr	-1336(ra) # 80004bc8 <releasesleep>
    acquire(&itable.lock);
    80004108:	0001d517          	auipc	a0,0x1d
    8000410c:	e0850513          	addi	a0,a0,-504 # 80020f10 <itable>
    80004110:	ffffd097          	auipc	ra,0xffffd
    80004114:	ada080e7          	jalr	-1318(ra) # 80000bea <acquire>
    80004118:	b741                	j	80004098 <iput+0x26>

000000008000411a <iunlockput>:
{
    8000411a:	1101                	addi	sp,sp,-32
    8000411c:	ec06                	sd	ra,24(sp)
    8000411e:	e822                	sd	s0,16(sp)
    80004120:	e426                	sd	s1,8(sp)
    80004122:	1000                	addi	s0,sp,32
    80004124:	84aa                	mv	s1,a0
  iunlock(ip);
    80004126:	00000097          	auipc	ra,0x0
    8000412a:	e54080e7          	jalr	-428(ra) # 80003f7a <iunlock>
  iput(ip);
    8000412e:	8526                	mv	a0,s1
    80004130:	00000097          	auipc	ra,0x0
    80004134:	f42080e7          	jalr	-190(ra) # 80004072 <iput>
}
    80004138:	60e2                	ld	ra,24(sp)
    8000413a:	6442                	ld	s0,16(sp)
    8000413c:	64a2                	ld	s1,8(sp)
    8000413e:	6105                	addi	sp,sp,32
    80004140:	8082                	ret

0000000080004142 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004142:	1141                	addi	sp,sp,-16
    80004144:	e422                	sd	s0,8(sp)
    80004146:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004148:	411c                	lw	a5,0(a0)
    8000414a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000414c:	415c                	lw	a5,4(a0)
    8000414e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004150:	04451783          	lh	a5,68(a0)
    80004154:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004158:	04a51783          	lh	a5,74(a0)
    8000415c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004160:	04c56783          	lwu	a5,76(a0)
    80004164:	e99c                	sd	a5,16(a1)
}
    80004166:	6422                	ld	s0,8(sp)
    80004168:	0141                	addi	sp,sp,16
    8000416a:	8082                	ret

000000008000416c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000416c:	457c                	lw	a5,76(a0)
    8000416e:	0ed7e963          	bltu	a5,a3,80004260 <readi+0xf4>
{
    80004172:	7159                	addi	sp,sp,-112
    80004174:	f486                	sd	ra,104(sp)
    80004176:	f0a2                	sd	s0,96(sp)
    80004178:	eca6                	sd	s1,88(sp)
    8000417a:	e8ca                	sd	s2,80(sp)
    8000417c:	e4ce                	sd	s3,72(sp)
    8000417e:	e0d2                	sd	s4,64(sp)
    80004180:	fc56                	sd	s5,56(sp)
    80004182:	f85a                	sd	s6,48(sp)
    80004184:	f45e                	sd	s7,40(sp)
    80004186:	f062                	sd	s8,32(sp)
    80004188:	ec66                	sd	s9,24(sp)
    8000418a:	e86a                	sd	s10,16(sp)
    8000418c:	e46e                	sd	s11,8(sp)
    8000418e:	1880                	addi	s0,sp,112
    80004190:	8b2a                	mv	s6,a0
    80004192:	8bae                	mv	s7,a1
    80004194:	8a32                	mv	s4,a2
    80004196:	84b6                	mv	s1,a3
    80004198:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    8000419a:	9f35                	addw	a4,a4,a3
    return 0;
    8000419c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000419e:	0ad76063          	bltu	a4,a3,8000423e <readi+0xd2>
  if(off + n > ip->size)
    800041a2:	00e7f463          	bgeu	a5,a4,800041aa <readi+0x3e>
    n = ip->size - off;
    800041a6:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041aa:	0a0a8963          	beqz	s5,8000425c <readi+0xf0>
    800041ae:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800041b0:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800041b4:	5c7d                	li	s8,-1
    800041b6:	a82d                	j	800041f0 <readi+0x84>
    800041b8:	020d1d93          	slli	s11,s10,0x20
    800041bc:	020ddd93          	srli	s11,s11,0x20
    800041c0:	05890613          	addi	a2,s2,88
    800041c4:	86ee                	mv	a3,s11
    800041c6:	963a                	add	a2,a2,a4
    800041c8:	85d2                	mv	a1,s4
    800041ca:	855e                	mv	a0,s7
    800041cc:	ffffe097          	auipc	ra,0xffffe
    800041d0:	7f2080e7          	jalr	2034(ra) # 800029be <either_copyout>
    800041d4:	05850d63          	beq	a0,s8,8000422e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800041d8:	854a                	mv	a0,s2
    800041da:	fffff097          	auipc	ra,0xfffff
    800041de:	5f4080e7          	jalr	1524(ra) # 800037ce <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041e2:	013d09bb          	addw	s3,s10,s3
    800041e6:	009d04bb          	addw	s1,s10,s1
    800041ea:	9a6e                	add	s4,s4,s11
    800041ec:	0559f763          	bgeu	s3,s5,8000423a <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    800041f0:	00a4d59b          	srliw	a1,s1,0xa
    800041f4:	855a                	mv	a0,s6
    800041f6:	00000097          	auipc	ra,0x0
    800041fa:	8a2080e7          	jalr	-1886(ra) # 80003a98 <bmap>
    800041fe:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004202:	cd85                	beqz	a1,8000423a <readi+0xce>
    bp = bread(ip->dev, addr);
    80004204:	000b2503          	lw	a0,0(s6)
    80004208:	fffff097          	auipc	ra,0xfffff
    8000420c:	496080e7          	jalr	1174(ra) # 8000369e <bread>
    80004210:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004212:	3ff4f713          	andi	a4,s1,1023
    80004216:	40ec87bb          	subw	a5,s9,a4
    8000421a:	413a86bb          	subw	a3,s5,s3
    8000421e:	8d3e                	mv	s10,a5
    80004220:	2781                	sext.w	a5,a5
    80004222:	0006861b          	sext.w	a2,a3
    80004226:	f8f679e3          	bgeu	a2,a5,800041b8 <readi+0x4c>
    8000422a:	8d36                	mv	s10,a3
    8000422c:	b771                	j	800041b8 <readi+0x4c>
      brelse(bp);
    8000422e:	854a                	mv	a0,s2
    80004230:	fffff097          	auipc	ra,0xfffff
    80004234:	59e080e7          	jalr	1438(ra) # 800037ce <brelse>
      tot = -1;
    80004238:	59fd                	li	s3,-1
  }
  return tot;
    8000423a:	0009851b          	sext.w	a0,s3
}
    8000423e:	70a6                	ld	ra,104(sp)
    80004240:	7406                	ld	s0,96(sp)
    80004242:	64e6                	ld	s1,88(sp)
    80004244:	6946                	ld	s2,80(sp)
    80004246:	69a6                	ld	s3,72(sp)
    80004248:	6a06                	ld	s4,64(sp)
    8000424a:	7ae2                	ld	s5,56(sp)
    8000424c:	7b42                	ld	s6,48(sp)
    8000424e:	7ba2                	ld	s7,40(sp)
    80004250:	7c02                	ld	s8,32(sp)
    80004252:	6ce2                	ld	s9,24(sp)
    80004254:	6d42                	ld	s10,16(sp)
    80004256:	6da2                	ld	s11,8(sp)
    80004258:	6165                	addi	sp,sp,112
    8000425a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000425c:	89d6                	mv	s3,s5
    8000425e:	bff1                	j	8000423a <readi+0xce>
    return 0;
    80004260:	4501                	li	a0,0
}
    80004262:	8082                	ret

0000000080004264 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004264:	457c                	lw	a5,76(a0)
    80004266:	10d7e863          	bltu	a5,a3,80004376 <writei+0x112>
{
    8000426a:	7159                	addi	sp,sp,-112
    8000426c:	f486                	sd	ra,104(sp)
    8000426e:	f0a2                	sd	s0,96(sp)
    80004270:	eca6                	sd	s1,88(sp)
    80004272:	e8ca                	sd	s2,80(sp)
    80004274:	e4ce                	sd	s3,72(sp)
    80004276:	e0d2                	sd	s4,64(sp)
    80004278:	fc56                	sd	s5,56(sp)
    8000427a:	f85a                	sd	s6,48(sp)
    8000427c:	f45e                	sd	s7,40(sp)
    8000427e:	f062                	sd	s8,32(sp)
    80004280:	ec66                	sd	s9,24(sp)
    80004282:	e86a                	sd	s10,16(sp)
    80004284:	e46e                	sd	s11,8(sp)
    80004286:	1880                	addi	s0,sp,112
    80004288:	8aaa                	mv	s5,a0
    8000428a:	8bae                	mv	s7,a1
    8000428c:	8a32                	mv	s4,a2
    8000428e:	8936                	mv	s2,a3
    80004290:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004292:	00e687bb          	addw	a5,a3,a4
    80004296:	0ed7e263          	bltu	a5,a3,8000437a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000429a:	00043737          	lui	a4,0x43
    8000429e:	0ef76063          	bltu	a4,a5,8000437e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042a2:	0c0b0863          	beqz	s6,80004372 <writei+0x10e>
    800042a6:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800042a8:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800042ac:	5c7d                	li	s8,-1
    800042ae:	a091                	j	800042f2 <writei+0x8e>
    800042b0:	020d1d93          	slli	s11,s10,0x20
    800042b4:	020ddd93          	srli	s11,s11,0x20
    800042b8:	05848513          	addi	a0,s1,88
    800042bc:	86ee                	mv	a3,s11
    800042be:	8652                	mv	a2,s4
    800042c0:	85de                	mv	a1,s7
    800042c2:	953a                	add	a0,a0,a4
    800042c4:	ffffe097          	auipc	ra,0xffffe
    800042c8:	750080e7          	jalr	1872(ra) # 80002a14 <either_copyin>
    800042cc:	07850263          	beq	a0,s8,80004330 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800042d0:	8526                	mv	a0,s1
    800042d2:	00000097          	auipc	ra,0x0
    800042d6:	780080e7          	jalr	1920(ra) # 80004a52 <log_write>
    brelse(bp);
    800042da:	8526                	mv	a0,s1
    800042dc:	fffff097          	auipc	ra,0xfffff
    800042e0:	4f2080e7          	jalr	1266(ra) # 800037ce <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042e4:	013d09bb          	addw	s3,s10,s3
    800042e8:	012d093b          	addw	s2,s10,s2
    800042ec:	9a6e                	add	s4,s4,s11
    800042ee:	0569f663          	bgeu	s3,s6,8000433a <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    800042f2:	00a9559b          	srliw	a1,s2,0xa
    800042f6:	8556                	mv	a0,s5
    800042f8:	fffff097          	auipc	ra,0xfffff
    800042fc:	7a0080e7          	jalr	1952(ra) # 80003a98 <bmap>
    80004300:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004304:	c99d                	beqz	a1,8000433a <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004306:	000aa503          	lw	a0,0(s5)
    8000430a:	fffff097          	auipc	ra,0xfffff
    8000430e:	394080e7          	jalr	916(ra) # 8000369e <bread>
    80004312:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004314:	3ff97713          	andi	a4,s2,1023
    80004318:	40ec87bb          	subw	a5,s9,a4
    8000431c:	413b06bb          	subw	a3,s6,s3
    80004320:	8d3e                	mv	s10,a5
    80004322:	2781                	sext.w	a5,a5
    80004324:	0006861b          	sext.w	a2,a3
    80004328:	f8f674e3          	bgeu	a2,a5,800042b0 <writei+0x4c>
    8000432c:	8d36                	mv	s10,a3
    8000432e:	b749                	j	800042b0 <writei+0x4c>
      brelse(bp);
    80004330:	8526                	mv	a0,s1
    80004332:	fffff097          	auipc	ra,0xfffff
    80004336:	49c080e7          	jalr	1180(ra) # 800037ce <brelse>
  }

  if(off > ip->size)
    8000433a:	04caa783          	lw	a5,76(s5)
    8000433e:	0127f463          	bgeu	a5,s2,80004346 <writei+0xe2>
    ip->size = off;
    80004342:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004346:	8556                	mv	a0,s5
    80004348:	00000097          	auipc	ra,0x0
    8000434c:	aa6080e7          	jalr	-1370(ra) # 80003dee <iupdate>

  return tot;
    80004350:	0009851b          	sext.w	a0,s3
}
    80004354:	70a6                	ld	ra,104(sp)
    80004356:	7406                	ld	s0,96(sp)
    80004358:	64e6                	ld	s1,88(sp)
    8000435a:	6946                	ld	s2,80(sp)
    8000435c:	69a6                	ld	s3,72(sp)
    8000435e:	6a06                	ld	s4,64(sp)
    80004360:	7ae2                	ld	s5,56(sp)
    80004362:	7b42                	ld	s6,48(sp)
    80004364:	7ba2                	ld	s7,40(sp)
    80004366:	7c02                	ld	s8,32(sp)
    80004368:	6ce2                	ld	s9,24(sp)
    8000436a:	6d42                	ld	s10,16(sp)
    8000436c:	6da2                	ld	s11,8(sp)
    8000436e:	6165                	addi	sp,sp,112
    80004370:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004372:	89da                	mv	s3,s6
    80004374:	bfc9                	j	80004346 <writei+0xe2>
    return -1;
    80004376:	557d                	li	a0,-1
}
    80004378:	8082                	ret
    return -1;
    8000437a:	557d                	li	a0,-1
    8000437c:	bfe1                	j	80004354 <writei+0xf0>
    return -1;
    8000437e:	557d                	li	a0,-1
    80004380:	bfd1                	j	80004354 <writei+0xf0>

0000000080004382 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004382:	1141                	addi	sp,sp,-16
    80004384:	e406                	sd	ra,8(sp)
    80004386:	e022                	sd	s0,0(sp)
    80004388:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000438a:	4639                	li	a2,14
    8000438c:	ffffd097          	auipc	ra,0xffffd
    80004390:	a32080e7          	jalr	-1486(ra) # 80000dbe <strncmp>
}
    80004394:	60a2                	ld	ra,8(sp)
    80004396:	6402                	ld	s0,0(sp)
    80004398:	0141                	addi	sp,sp,16
    8000439a:	8082                	ret

000000008000439c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000439c:	7139                	addi	sp,sp,-64
    8000439e:	fc06                	sd	ra,56(sp)
    800043a0:	f822                	sd	s0,48(sp)
    800043a2:	f426                	sd	s1,40(sp)
    800043a4:	f04a                	sd	s2,32(sp)
    800043a6:	ec4e                	sd	s3,24(sp)
    800043a8:	e852                	sd	s4,16(sp)
    800043aa:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800043ac:	04451703          	lh	a4,68(a0)
    800043b0:	4785                	li	a5,1
    800043b2:	00f71a63          	bne	a4,a5,800043c6 <dirlookup+0x2a>
    800043b6:	892a                	mv	s2,a0
    800043b8:	89ae                	mv	s3,a1
    800043ba:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800043bc:	457c                	lw	a5,76(a0)
    800043be:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800043c0:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043c2:	e79d                	bnez	a5,800043f0 <dirlookup+0x54>
    800043c4:	a8a5                	j	8000443c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800043c6:	00004517          	auipc	a0,0x4
    800043ca:	36250513          	addi	a0,a0,866 # 80008728 <syscalls+0x1d0>
    800043ce:	ffffc097          	auipc	ra,0xffffc
    800043d2:	176080e7          	jalr	374(ra) # 80000544 <panic>
      panic("dirlookup read");
    800043d6:	00004517          	auipc	a0,0x4
    800043da:	36a50513          	addi	a0,a0,874 # 80008740 <syscalls+0x1e8>
    800043de:	ffffc097          	auipc	ra,0xffffc
    800043e2:	166080e7          	jalr	358(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043e6:	24c1                	addiw	s1,s1,16
    800043e8:	04c92783          	lw	a5,76(s2)
    800043ec:	04f4f763          	bgeu	s1,a5,8000443a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043f0:	4741                	li	a4,16
    800043f2:	86a6                	mv	a3,s1
    800043f4:	fc040613          	addi	a2,s0,-64
    800043f8:	4581                	li	a1,0
    800043fa:	854a                	mv	a0,s2
    800043fc:	00000097          	auipc	ra,0x0
    80004400:	d70080e7          	jalr	-656(ra) # 8000416c <readi>
    80004404:	47c1                	li	a5,16
    80004406:	fcf518e3          	bne	a0,a5,800043d6 <dirlookup+0x3a>
    if(de.inum == 0)
    8000440a:	fc045783          	lhu	a5,-64(s0)
    8000440e:	dfe1                	beqz	a5,800043e6 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004410:	fc240593          	addi	a1,s0,-62
    80004414:	854e                	mv	a0,s3
    80004416:	00000097          	auipc	ra,0x0
    8000441a:	f6c080e7          	jalr	-148(ra) # 80004382 <namecmp>
    8000441e:	f561                	bnez	a0,800043e6 <dirlookup+0x4a>
      if(poff)
    80004420:	000a0463          	beqz	s4,80004428 <dirlookup+0x8c>
        *poff = off;
    80004424:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004428:	fc045583          	lhu	a1,-64(s0)
    8000442c:	00092503          	lw	a0,0(s2)
    80004430:	fffff097          	auipc	ra,0xfffff
    80004434:	750080e7          	jalr	1872(ra) # 80003b80 <iget>
    80004438:	a011                	j	8000443c <dirlookup+0xa0>
  return 0;
    8000443a:	4501                	li	a0,0
}
    8000443c:	70e2                	ld	ra,56(sp)
    8000443e:	7442                	ld	s0,48(sp)
    80004440:	74a2                	ld	s1,40(sp)
    80004442:	7902                	ld	s2,32(sp)
    80004444:	69e2                	ld	s3,24(sp)
    80004446:	6a42                	ld	s4,16(sp)
    80004448:	6121                	addi	sp,sp,64
    8000444a:	8082                	ret

000000008000444c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000444c:	711d                	addi	sp,sp,-96
    8000444e:	ec86                	sd	ra,88(sp)
    80004450:	e8a2                	sd	s0,80(sp)
    80004452:	e4a6                	sd	s1,72(sp)
    80004454:	e0ca                	sd	s2,64(sp)
    80004456:	fc4e                	sd	s3,56(sp)
    80004458:	f852                	sd	s4,48(sp)
    8000445a:	f456                	sd	s5,40(sp)
    8000445c:	f05a                	sd	s6,32(sp)
    8000445e:	ec5e                	sd	s7,24(sp)
    80004460:	e862                	sd	s8,16(sp)
    80004462:	e466                	sd	s9,8(sp)
    80004464:	1080                	addi	s0,sp,96
    80004466:	84aa                	mv	s1,a0
    80004468:	8b2e                	mv	s6,a1
    8000446a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000446c:	00054703          	lbu	a4,0(a0)
    80004470:	02f00793          	li	a5,47
    80004474:	02f70363          	beq	a4,a5,8000449a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004478:	ffffd097          	auipc	ra,0xffffd
    8000447c:	73c080e7          	jalr	1852(ra) # 80001bb4 <myproc>
    80004480:	15053503          	ld	a0,336(a0)
    80004484:	00000097          	auipc	ra,0x0
    80004488:	9f6080e7          	jalr	-1546(ra) # 80003e7a <idup>
    8000448c:	89aa                	mv	s3,a0
  while(*path == '/')
    8000448e:	02f00913          	li	s2,47
  len = path - s;
    80004492:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004494:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004496:	4c05                	li	s8,1
    80004498:	a865                	j	80004550 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000449a:	4585                	li	a1,1
    8000449c:	4505                	li	a0,1
    8000449e:	fffff097          	auipc	ra,0xfffff
    800044a2:	6e2080e7          	jalr	1762(ra) # 80003b80 <iget>
    800044a6:	89aa                	mv	s3,a0
    800044a8:	b7dd                	j	8000448e <namex+0x42>
      iunlockput(ip);
    800044aa:	854e                	mv	a0,s3
    800044ac:	00000097          	auipc	ra,0x0
    800044b0:	c6e080e7          	jalr	-914(ra) # 8000411a <iunlockput>
      return 0;
    800044b4:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800044b6:	854e                	mv	a0,s3
    800044b8:	60e6                	ld	ra,88(sp)
    800044ba:	6446                	ld	s0,80(sp)
    800044bc:	64a6                	ld	s1,72(sp)
    800044be:	6906                	ld	s2,64(sp)
    800044c0:	79e2                	ld	s3,56(sp)
    800044c2:	7a42                	ld	s4,48(sp)
    800044c4:	7aa2                	ld	s5,40(sp)
    800044c6:	7b02                	ld	s6,32(sp)
    800044c8:	6be2                	ld	s7,24(sp)
    800044ca:	6c42                	ld	s8,16(sp)
    800044cc:	6ca2                	ld	s9,8(sp)
    800044ce:	6125                	addi	sp,sp,96
    800044d0:	8082                	ret
      iunlock(ip);
    800044d2:	854e                	mv	a0,s3
    800044d4:	00000097          	auipc	ra,0x0
    800044d8:	aa6080e7          	jalr	-1370(ra) # 80003f7a <iunlock>
      return ip;
    800044dc:	bfe9                	j	800044b6 <namex+0x6a>
      iunlockput(ip);
    800044de:	854e                	mv	a0,s3
    800044e0:	00000097          	auipc	ra,0x0
    800044e4:	c3a080e7          	jalr	-966(ra) # 8000411a <iunlockput>
      return 0;
    800044e8:	89d2                	mv	s3,s4
    800044ea:	b7f1                	j	800044b6 <namex+0x6a>
  len = path - s;
    800044ec:	40b48633          	sub	a2,s1,a1
    800044f0:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800044f4:	094cd463          	bge	s9,s4,8000457c <namex+0x130>
    memmove(name, s, DIRSIZ);
    800044f8:	4639                	li	a2,14
    800044fa:	8556                	mv	a0,s5
    800044fc:	ffffd097          	auipc	ra,0xffffd
    80004500:	84a080e7          	jalr	-1974(ra) # 80000d46 <memmove>
  while(*path == '/')
    80004504:	0004c783          	lbu	a5,0(s1)
    80004508:	01279763          	bne	a5,s2,80004516 <namex+0xca>
    path++;
    8000450c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000450e:	0004c783          	lbu	a5,0(s1)
    80004512:	ff278de3          	beq	a5,s2,8000450c <namex+0xc0>
    ilock(ip);
    80004516:	854e                	mv	a0,s3
    80004518:	00000097          	auipc	ra,0x0
    8000451c:	9a0080e7          	jalr	-1632(ra) # 80003eb8 <ilock>
    if(ip->type != T_DIR){
    80004520:	04499783          	lh	a5,68(s3)
    80004524:	f98793e3          	bne	a5,s8,800044aa <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004528:	000b0563          	beqz	s6,80004532 <namex+0xe6>
    8000452c:	0004c783          	lbu	a5,0(s1)
    80004530:	d3cd                	beqz	a5,800044d2 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004532:	865e                	mv	a2,s7
    80004534:	85d6                	mv	a1,s5
    80004536:	854e                	mv	a0,s3
    80004538:	00000097          	auipc	ra,0x0
    8000453c:	e64080e7          	jalr	-412(ra) # 8000439c <dirlookup>
    80004540:	8a2a                	mv	s4,a0
    80004542:	dd51                	beqz	a0,800044de <namex+0x92>
    iunlockput(ip);
    80004544:	854e                	mv	a0,s3
    80004546:	00000097          	auipc	ra,0x0
    8000454a:	bd4080e7          	jalr	-1068(ra) # 8000411a <iunlockput>
    ip = next;
    8000454e:	89d2                	mv	s3,s4
  while(*path == '/')
    80004550:	0004c783          	lbu	a5,0(s1)
    80004554:	05279763          	bne	a5,s2,800045a2 <namex+0x156>
    path++;
    80004558:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000455a:	0004c783          	lbu	a5,0(s1)
    8000455e:	ff278de3          	beq	a5,s2,80004558 <namex+0x10c>
  if(*path == 0)
    80004562:	c79d                	beqz	a5,80004590 <namex+0x144>
    path++;
    80004564:	85a6                	mv	a1,s1
  len = path - s;
    80004566:	8a5e                	mv	s4,s7
    80004568:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000456a:	01278963          	beq	a5,s2,8000457c <namex+0x130>
    8000456e:	dfbd                	beqz	a5,800044ec <namex+0xa0>
    path++;
    80004570:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004572:	0004c783          	lbu	a5,0(s1)
    80004576:	ff279ce3          	bne	a5,s2,8000456e <namex+0x122>
    8000457a:	bf8d                	j	800044ec <namex+0xa0>
    memmove(name, s, len);
    8000457c:	2601                	sext.w	a2,a2
    8000457e:	8556                	mv	a0,s5
    80004580:	ffffc097          	auipc	ra,0xffffc
    80004584:	7c6080e7          	jalr	1990(ra) # 80000d46 <memmove>
    name[len] = 0;
    80004588:	9a56                	add	s4,s4,s5
    8000458a:	000a0023          	sb	zero,0(s4)
    8000458e:	bf9d                	j	80004504 <namex+0xb8>
  if(nameiparent){
    80004590:	f20b03e3          	beqz	s6,800044b6 <namex+0x6a>
    iput(ip);
    80004594:	854e                	mv	a0,s3
    80004596:	00000097          	auipc	ra,0x0
    8000459a:	adc080e7          	jalr	-1316(ra) # 80004072 <iput>
    return 0;
    8000459e:	4981                	li	s3,0
    800045a0:	bf19                	j	800044b6 <namex+0x6a>
  if(*path == 0)
    800045a2:	d7fd                	beqz	a5,80004590 <namex+0x144>
  while(*path != '/' && *path != 0)
    800045a4:	0004c783          	lbu	a5,0(s1)
    800045a8:	85a6                	mv	a1,s1
    800045aa:	b7d1                	j	8000456e <namex+0x122>

00000000800045ac <dirlink>:
{
    800045ac:	7139                	addi	sp,sp,-64
    800045ae:	fc06                	sd	ra,56(sp)
    800045b0:	f822                	sd	s0,48(sp)
    800045b2:	f426                	sd	s1,40(sp)
    800045b4:	f04a                	sd	s2,32(sp)
    800045b6:	ec4e                	sd	s3,24(sp)
    800045b8:	e852                	sd	s4,16(sp)
    800045ba:	0080                	addi	s0,sp,64
    800045bc:	892a                	mv	s2,a0
    800045be:	8a2e                	mv	s4,a1
    800045c0:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800045c2:	4601                	li	a2,0
    800045c4:	00000097          	auipc	ra,0x0
    800045c8:	dd8080e7          	jalr	-552(ra) # 8000439c <dirlookup>
    800045cc:	e93d                	bnez	a0,80004642 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800045ce:	04c92483          	lw	s1,76(s2)
    800045d2:	c49d                	beqz	s1,80004600 <dirlink+0x54>
    800045d4:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800045d6:	4741                	li	a4,16
    800045d8:	86a6                	mv	a3,s1
    800045da:	fc040613          	addi	a2,s0,-64
    800045de:	4581                	li	a1,0
    800045e0:	854a                	mv	a0,s2
    800045e2:	00000097          	auipc	ra,0x0
    800045e6:	b8a080e7          	jalr	-1142(ra) # 8000416c <readi>
    800045ea:	47c1                	li	a5,16
    800045ec:	06f51163          	bne	a0,a5,8000464e <dirlink+0xa2>
    if(de.inum == 0)
    800045f0:	fc045783          	lhu	a5,-64(s0)
    800045f4:	c791                	beqz	a5,80004600 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800045f6:	24c1                	addiw	s1,s1,16
    800045f8:	04c92783          	lw	a5,76(s2)
    800045fc:	fcf4ede3          	bltu	s1,a5,800045d6 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004600:	4639                	li	a2,14
    80004602:	85d2                	mv	a1,s4
    80004604:	fc240513          	addi	a0,s0,-62
    80004608:	ffffc097          	auipc	ra,0xffffc
    8000460c:	7f2080e7          	jalr	2034(ra) # 80000dfa <strncpy>
  de.inum = inum;
    80004610:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004614:	4741                	li	a4,16
    80004616:	86a6                	mv	a3,s1
    80004618:	fc040613          	addi	a2,s0,-64
    8000461c:	4581                	li	a1,0
    8000461e:	854a                	mv	a0,s2
    80004620:	00000097          	auipc	ra,0x0
    80004624:	c44080e7          	jalr	-956(ra) # 80004264 <writei>
    80004628:	1541                	addi	a0,a0,-16
    8000462a:	00a03533          	snez	a0,a0
    8000462e:	40a00533          	neg	a0,a0
}
    80004632:	70e2                	ld	ra,56(sp)
    80004634:	7442                	ld	s0,48(sp)
    80004636:	74a2                	ld	s1,40(sp)
    80004638:	7902                	ld	s2,32(sp)
    8000463a:	69e2                	ld	s3,24(sp)
    8000463c:	6a42                	ld	s4,16(sp)
    8000463e:	6121                	addi	sp,sp,64
    80004640:	8082                	ret
    iput(ip);
    80004642:	00000097          	auipc	ra,0x0
    80004646:	a30080e7          	jalr	-1488(ra) # 80004072 <iput>
    return -1;
    8000464a:	557d                	li	a0,-1
    8000464c:	b7dd                	j	80004632 <dirlink+0x86>
      panic("dirlink read");
    8000464e:	00004517          	auipc	a0,0x4
    80004652:	10250513          	addi	a0,a0,258 # 80008750 <syscalls+0x1f8>
    80004656:	ffffc097          	auipc	ra,0xffffc
    8000465a:	eee080e7          	jalr	-274(ra) # 80000544 <panic>

000000008000465e <namei>:

struct inode*
namei(char *path)
{
    8000465e:	1101                	addi	sp,sp,-32
    80004660:	ec06                	sd	ra,24(sp)
    80004662:	e822                	sd	s0,16(sp)
    80004664:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004666:	fe040613          	addi	a2,s0,-32
    8000466a:	4581                	li	a1,0
    8000466c:	00000097          	auipc	ra,0x0
    80004670:	de0080e7          	jalr	-544(ra) # 8000444c <namex>
}
    80004674:	60e2                	ld	ra,24(sp)
    80004676:	6442                	ld	s0,16(sp)
    80004678:	6105                	addi	sp,sp,32
    8000467a:	8082                	ret

000000008000467c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000467c:	1141                	addi	sp,sp,-16
    8000467e:	e406                	sd	ra,8(sp)
    80004680:	e022                	sd	s0,0(sp)
    80004682:	0800                	addi	s0,sp,16
    80004684:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004686:	4585                	li	a1,1
    80004688:	00000097          	auipc	ra,0x0
    8000468c:	dc4080e7          	jalr	-572(ra) # 8000444c <namex>
}
    80004690:	60a2                	ld	ra,8(sp)
    80004692:	6402                	ld	s0,0(sp)
    80004694:	0141                	addi	sp,sp,16
    80004696:	8082                	ret

0000000080004698 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004698:	1101                	addi	sp,sp,-32
    8000469a:	ec06                	sd	ra,24(sp)
    8000469c:	e822                	sd	s0,16(sp)
    8000469e:	e426                	sd	s1,8(sp)
    800046a0:	e04a                	sd	s2,0(sp)
    800046a2:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800046a4:	0001e917          	auipc	s2,0x1e
    800046a8:	31490913          	addi	s2,s2,788 # 800229b8 <log>
    800046ac:	01892583          	lw	a1,24(s2)
    800046b0:	02892503          	lw	a0,40(s2)
    800046b4:	fffff097          	auipc	ra,0xfffff
    800046b8:	fea080e7          	jalr	-22(ra) # 8000369e <bread>
    800046bc:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800046be:	02c92683          	lw	a3,44(s2)
    800046c2:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800046c4:	02d05763          	blez	a3,800046f2 <write_head+0x5a>
    800046c8:	0001e797          	auipc	a5,0x1e
    800046cc:	32078793          	addi	a5,a5,800 # 800229e8 <log+0x30>
    800046d0:	05c50713          	addi	a4,a0,92
    800046d4:	36fd                	addiw	a3,a3,-1
    800046d6:	1682                	slli	a3,a3,0x20
    800046d8:	9281                	srli	a3,a3,0x20
    800046da:	068a                	slli	a3,a3,0x2
    800046dc:	0001e617          	auipc	a2,0x1e
    800046e0:	31060613          	addi	a2,a2,784 # 800229ec <log+0x34>
    800046e4:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800046e6:	4390                	lw	a2,0(a5)
    800046e8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800046ea:	0791                	addi	a5,a5,4
    800046ec:	0711                	addi	a4,a4,4
    800046ee:	fed79ce3          	bne	a5,a3,800046e6 <write_head+0x4e>
  }
  bwrite(buf);
    800046f2:	8526                	mv	a0,s1
    800046f4:	fffff097          	auipc	ra,0xfffff
    800046f8:	09c080e7          	jalr	156(ra) # 80003790 <bwrite>
  brelse(buf);
    800046fc:	8526                	mv	a0,s1
    800046fe:	fffff097          	auipc	ra,0xfffff
    80004702:	0d0080e7          	jalr	208(ra) # 800037ce <brelse>
}
    80004706:	60e2                	ld	ra,24(sp)
    80004708:	6442                	ld	s0,16(sp)
    8000470a:	64a2                	ld	s1,8(sp)
    8000470c:	6902                	ld	s2,0(sp)
    8000470e:	6105                	addi	sp,sp,32
    80004710:	8082                	ret

0000000080004712 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004712:	0001e797          	auipc	a5,0x1e
    80004716:	2d27a783          	lw	a5,722(a5) # 800229e4 <log+0x2c>
    8000471a:	0af05d63          	blez	a5,800047d4 <install_trans+0xc2>
{
    8000471e:	7139                	addi	sp,sp,-64
    80004720:	fc06                	sd	ra,56(sp)
    80004722:	f822                	sd	s0,48(sp)
    80004724:	f426                	sd	s1,40(sp)
    80004726:	f04a                	sd	s2,32(sp)
    80004728:	ec4e                	sd	s3,24(sp)
    8000472a:	e852                	sd	s4,16(sp)
    8000472c:	e456                	sd	s5,8(sp)
    8000472e:	e05a                	sd	s6,0(sp)
    80004730:	0080                	addi	s0,sp,64
    80004732:	8b2a                	mv	s6,a0
    80004734:	0001ea97          	auipc	s5,0x1e
    80004738:	2b4a8a93          	addi	s5,s5,692 # 800229e8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000473c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000473e:	0001e997          	auipc	s3,0x1e
    80004742:	27a98993          	addi	s3,s3,634 # 800229b8 <log>
    80004746:	a035                	j	80004772 <install_trans+0x60>
      bunpin(dbuf);
    80004748:	8526                	mv	a0,s1
    8000474a:	fffff097          	auipc	ra,0xfffff
    8000474e:	15e080e7          	jalr	350(ra) # 800038a8 <bunpin>
    brelse(lbuf);
    80004752:	854a                	mv	a0,s2
    80004754:	fffff097          	auipc	ra,0xfffff
    80004758:	07a080e7          	jalr	122(ra) # 800037ce <brelse>
    brelse(dbuf);
    8000475c:	8526                	mv	a0,s1
    8000475e:	fffff097          	auipc	ra,0xfffff
    80004762:	070080e7          	jalr	112(ra) # 800037ce <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004766:	2a05                	addiw	s4,s4,1
    80004768:	0a91                	addi	s5,s5,4
    8000476a:	02c9a783          	lw	a5,44(s3)
    8000476e:	04fa5963          	bge	s4,a5,800047c0 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004772:	0189a583          	lw	a1,24(s3)
    80004776:	014585bb          	addw	a1,a1,s4
    8000477a:	2585                	addiw	a1,a1,1
    8000477c:	0289a503          	lw	a0,40(s3)
    80004780:	fffff097          	auipc	ra,0xfffff
    80004784:	f1e080e7          	jalr	-226(ra) # 8000369e <bread>
    80004788:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000478a:	000aa583          	lw	a1,0(s5)
    8000478e:	0289a503          	lw	a0,40(s3)
    80004792:	fffff097          	auipc	ra,0xfffff
    80004796:	f0c080e7          	jalr	-244(ra) # 8000369e <bread>
    8000479a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000479c:	40000613          	li	a2,1024
    800047a0:	05890593          	addi	a1,s2,88
    800047a4:	05850513          	addi	a0,a0,88
    800047a8:	ffffc097          	auipc	ra,0xffffc
    800047ac:	59e080e7          	jalr	1438(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    800047b0:	8526                	mv	a0,s1
    800047b2:	fffff097          	auipc	ra,0xfffff
    800047b6:	fde080e7          	jalr	-34(ra) # 80003790 <bwrite>
    if(recovering == 0)
    800047ba:	f80b1ce3          	bnez	s6,80004752 <install_trans+0x40>
    800047be:	b769                	j	80004748 <install_trans+0x36>
}
    800047c0:	70e2                	ld	ra,56(sp)
    800047c2:	7442                	ld	s0,48(sp)
    800047c4:	74a2                	ld	s1,40(sp)
    800047c6:	7902                	ld	s2,32(sp)
    800047c8:	69e2                	ld	s3,24(sp)
    800047ca:	6a42                	ld	s4,16(sp)
    800047cc:	6aa2                	ld	s5,8(sp)
    800047ce:	6b02                	ld	s6,0(sp)
    800047d0:	6121                	addi	sp,sp,64
    800047d2:	8082                	ret
    800047d4:	8082                	ret

00000000800047d6 <initlog>:
{
    800047d6:	7179                	addi	sp,sp,-48
    800047d8:	f406                	sd	ra,40(sp)
    800047da:	f022                	sd	s0,32(sp)
    800047dc:	ec26                	sd	s1,24(sp)
    800047de:	e84a                	sd	s2,16(sp)
    800047e0:	e44e                	sd	s3,8(sp)
    800047e2:	1800                	addi	s0,sp,48
    800047e4:	892a                	mv	s2,a0
    800047e6:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800047e8:	0001e497          	auipc	s1,0x1e
    800047ec:	1d048493          	addi	s1,s1,464 # 800229b8 <log>
    800047f0:	00004597          	auipc	a1,0x4
    800047f4:	f7058593          	addi	a1,a1,-144 # 80008760 <syscalls+0x208>
    800047f8:	8526                	mv	a0,s1
    800047fa:	ffffc097          	auipc	ra,0xffffc
    800047fe:	360080e7          	jalr	864(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    80004802:	0149a583          	lw	a1,20(s3)
    80004806:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004808:	0109a783          	lw	a5,16(s3)
    8000480c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000480e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004812:	854a                	mv	a0,s2
    80004814:	fffff097          	auipc	ra,0xfffff
    80004818:	e8a080e7          	jalr	-374(ra) # 8000369e <bread>
  log.lh.n = lh->n;
    8000481c:	4d3c                	lw	a5,88(a0)
    8000481e:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004820:	02f05563          	blez	a5,8000484a <initlog+0x74>
    80004824:	05c50713          	addi	a4,a0,92
    80004828:	0001e697          	auipc	a3,0x1e
    8000482c:	1c068693          	addi	a3,a3,448 # 800229e8 <log+0x30>
    80004830:	37fd                	addiw	a5,a5,-1
    80004832:	1782                	slli	a5,a5,0x20
    80004834:	9381                	srli	a5,a5,0x20
    80004836:	078a                	slli	a5,a5,0x2
    80004838:	06050613          	addi	a2,a0,96
    8000483c:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000483e:	4310                	lw	a2,0(a4)
    80004840:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004842:	0711                	addi	a4,a4,4
    80004844:	0691                	addi	a3,a3,4
    80004846:	fef71ce3          	bne	a4,a5,8000483e <initlog+0x68>
  brelse(buf);
    8000484a:	fffff097          	auipc	ra,0xfffff
    8000484e:	f84080e7          	jalr	-124(ra) # 800037ce <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004852:	4505                	li	a0,1
    80004854:	00000097          	auipc	ra,0x0
    80004858:	ebe080e7          	jalr	-322(ra) # 80004712 <install_trans>
  log.lh.n = 0;
    8000485c:	0001e797          	auipc	a5,0x1e
    80004860:	1807a423          	sw	zero,392(a5) # 800229e4 <log+0x2c>
  write_head(); // clear the log
    80004864:	00000097          	auipc	ra,0x0
    80004868:	e34080e7          	jalr	-460(ra) # 80004698 <write_head>
}
    8000486c:	70a2                	ld	ra,40(sp)
    8000486e:	7402                	ld	s0,32(sp)
    80004870:	64e2                	ld	s1,24(sp)
    80004872:	6942                	ld	s2,16(sp)
    80004874:	69a2                	ld	s3,8(sp)
    80004876:	6145                	addi	sp,sp,48
    80004878:	8082                	ret

000000008000487a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000487a:	1101                	addi	sp,sp,-32
    8000487c:	ec06                	sd	ra,24(sp)
    8000487e:	e822                	sd	s0,16(sp)
    80004880:	e426                	sd	s1,8(sp)
    80004882:	e04a                	sd	s2,0(sp)
    80004884:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004886:	0001e517          	auipc	a0,0x1e
    8000488a:	13250513          	addi	a0,a0,306 # 800229b8 <log>
    8000488e:	ffffc097          	auipc	ra,0xffffc
    80004892:	35c080e7          	jalr	860(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    80004896:	0001e497          	auipc	s1,0x1e
    8000489a:	12248493          	addi	s1,s1,290 # 800229b8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000489e:	4979                	li	s2,30
    800048a0:	a039                	j	800048ae <begin_op+0x34>
      sleep(&log, &log.lock);
    800048a2:	85a6                	mv	a1,s1
    800048a4:	8526                	mv	a0,s1
    800048a6:	ffffe097          	auipc	ra,0xffffe
    800048aa:	bb8080e7          	jalr	-1096(ra) # 8000245e <sleep>
    if(log.committing){
    800048ae:	50dc                	lw	a5,36(s1)
    800048b0:	fbed                	bnez	a5,800048a2 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800048b2:	509c                	lw	a5,32(s1)
    800048b4:	0017871b          	addiw	a4,a5,1
    800048b8:	0007069b          	sext.w	a3,a4
    800048bc:	0027179b          	slliw	a5,a4,0x2
    800048c0:	9fb9                	addw	a5,a5,a4
    800048c2:	0017979b          	slliw	a5,a5,0x1
    800048c6:	54d8                	lw	a4,44(s1)
    800048c8:	9fb9                	addw	a5,a5,a4
    800048ca:	00f95963          	bge	s2,a5,800048dc <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800048ce:	85a6                	mv	a1,s1
    800048d0:	8526                	mv	a0,s1
    800048d2:	ffffe097          	auipc	ra,0xffffe
    800048d6:	b8c080e7          	jalr	-1140(ra) # 8000245e <sleep>
    800048da:	bfd1                	j	800048ae <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800048dc:	0001e517          	auipc	a0,0x1e
    800048e0:	0dc50513          	addi	a0,a0,220 # 800229b8 <log>
    800048e4:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800048e6:	ffffc097          	auipc	ra,0xffffc
    800048ea:	3b8080e7          	jalr	952(ra) # 80000c9e <release>
      break;
    }
  }
}
    800048ee:	60e2                	ld	ra,24(sp)
    800048f0:	6442                	ld	s0,16(sp)
    800048f2:	64a2                	ld	s1,8(sp)
    800048f4:	6902                	ld	s2,0(sp)
    800048f6:	6105                	addi	sp,sp,32
    800048f8:	8082                	ret

00000000800048fa <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800048fa:	7139                	addi	sp,sp,-64
    800048fc:	fc06                	sd	ra,56(sp)
    800048fe:	f822                	sd	s0,48(sp)
    80004900:	f426                	sd	s1,40(sp)
    80004902:	f04a                	sd	s2,32(sp)
    80004904:	ec4e                	sd	s3,24(sp)
    80004906:	e852                	sd	s4,16(sp)
    80004908:	e456                	sd	s5,8(sp)
    8000490a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000490c:	0001e497          	auipc	s1,0x1e
    80004910:	0ac48493          	addi	s1,s1,172 # 800229b8 <log>
    80004914:	8526                	mv	a0,s1
    80004916:	ffffc097          	auipc	ra,0xffffc
    8000491a:	2d4080e7          	jalr	724(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    8000491e:	509c                	lw	a5,32(s1)
    80004920:	37fd                	addiw	a5,a5,-1
    80004922:	0007891b          	sext.w	s2,a5
    80004926:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004928:	50dc                	lw	a5,36(s1)
    8000492a:	efb9                	bnez	a5,80004988 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000492c:	06091663          	bnez	s2,80004998 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004930:	0001e497          	auipc	s1,0x1e
    80004934:	08848493          	addi	s1,s1,136 # 800229b8 <log>
    80004938:	4785                	li	a5,1
    8000493a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000493c:	8526                	mv	a0,s1
    8000493e:	ffffc097          	auipc	ra,0xffffc
    80004942:	360080e7          	jalr	864(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004946:	54dc                	lw	a5,44(s1)
    80004948:	06f04763          	bgtz	a5,800049b6 <end_op+0xbc>
    acquire(&log.lock);
    8000494c:	0001e497          	auipc	s1,0x1e
    80004950:	06c48493          	addi	s1,s1,108 # 800229b8 <log>
    80004954:	8526                	mv	a0,s1
    80004956:	ffffc097          	auipc	ra,0xffffc
    8000495a:	294080e7          	jalr	660(ra) # 80000bea <acquire>
    log.committing = 0;
    8000495e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004962:	8526                	mv	a0,s1
    80004964:	ffffe097          	auipc	ra,0xffffe
    80004968:	caa080e7          	jalr	-854(ra) # 8000260e <wakeup>
    release(&log.lock);
    8000496c:	8526                	mv	a0,s1
    8000496e:	ffffc097          	auipc	ra,0xffffc
    80004972:	330080e7          	jalr	816(ra) # 80000c9e <release>
}
    80004976:	70e2                	ld	ra,56(sp)
    80004978:	7442                	ld	s0,48(sp)
    8000497a:	74a2                	ld	s1,40(sp)
    8000497c:	7902                	ld	s2,32(sp)
    8000497e:	69e2                	ld	s3,24(sp)
    80004980:	6a42                	ld	s4,16(sp)
    80004982:	6aa2                	ld	s5,8(sp)
    80004984:	6121                	addi	sp,sp,64
    80004986:	8082                	ret
    panic("log.committing");
    80004988:	00004517          	auipc	a0,0x4
    8000498c:	de050513          	addi	a0,a0,-544 # 80008768 <syscalls+0x210>
    80004990:	ffffc097          	auipc	ra,0xffffc
    80004994:	bb4080e7          	jalr	-1100(ra) # 80000544 <panic>
    wakeup(&log);
    80004998:	0001e497          	auipc	s1,0x1e
    8000499c:	02048493          	addi	s1,s1,32 # 800229b8 <log>
    800049a0:	8526                	mv	a0,s1
    800049a2:	ffffe097          	auipc	ra,0xffffe
    800049a6:	c6c080e7          	jalr	-916(ra) # 8000260e <wakeup>
  release(&log.lock);
    800049aa:	8526                	mv	a0,s1
    800049ac:	ffffc097          	auipc	ra,0xffffc
    800049b0:	2f2080e7          	jalr	754(ra) # 80000c9e <release>
  if(do_commit){
    800049b4:	b7c9                	j	80004976 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800049b6:	0001ea97          	auipc	s5,0x1e
    800049ba:	032a8a93          	addi	s5,s5,50 # 800229e8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800049be:	0001ea17          	auipc	s4,0x1e
    800049c2:	ffaa0a13          	addi	s4,s4,-6 # 800229b8 <log>
    800049c6:	018a2583          	lw	a1,24(s4)
    800049ca:	012585bb          	addw	a1,a1,s2
    800049ce:	2585                	addiw	a1,a1,1
    800049d0:	028a2503          	lw	a0,40(s4)
    800049d4:	fffff097          	auipc	ra,0xfffff
    800049d8:	cca080e7          	jalr	-822(ra) # 8000369e <bread>
    800049dc:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800049de:	000aa583          	lw	a1,0(s5)
    800049e2:	028a2503          	lw	a0,40(s4)
    800049e6:	fffff097          	auipc	ra,0xfffff
    800049ea:	cb8080e7          	jalr	-840(ra) # 8000369e <bread>
    800049ee:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800049f0:	40000613          	li	a2,1024
    800049f4:	05850593          	addi	a1,a0,88
    800049f8:	05848513          	addi	a0,s1,88
    800049fc:	ffffc097          	auipc	ra,0xffffc
    80004a00:	34a080e7          	jalr	842(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    80004a04:	8526                	mv	a0,s1
    80004a06:	fffff097          	auipc	ra,0xfffff
    80004a0a:	d8a080e7          	jalr	-630(ra) # 80003790 <bwrite>
    brelse(from);
    80004a0e:	854e                	mv	a0,s3
    80004a10:	fffff097          	auipc	ra,0xfffff
    80004a14:	dbe080e7          	jalr	-578(ra) # 800037ce <brelse>
    brelse(to);
    80004a18:	8526                	mv	a0,s1
    80004a1a:	fffff097          	auipc	ra,0xfffff
    80004a1e:	db4080e7          	jalr	-588(ra) # 800037ce <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a22:	2905                	addiw	s2,s2,1
    80004a24:	0a91                	addi	s5,s5,4
    80004a26:	02ca2783          	lw	a5,44(s4)
    80004a2a:	f8f94ee3          	blt	s2,a5,800049c6 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004a2e:	00000097          	auipc	ra,0x0
    80004a32:	c6a080e7          	jalr	-918(ra) # 80004698 <write_head>
    install_trans(0); // Now install writes to home locations
    80004a36:	4501                	li	a0,0
    80004a38:	00000097          	auipc	ra,0x0
    80004a3c:	cda080e7          	jalr	-806(ra) # 80004712 <install_trans>
    log.lh.n = 0;
    80004a40:	0001e797          	auipc	a5,0x1e
    80004a44:	fa07a223          	sw	zero,-92(a5) # 800229e4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004a48:	00000097          	auipc	ra,0x0
    80004a4c:	c50080e7          	jalr	-944(ra) # 80004698 <write_head>
    80004a50:	bdf5                	j	8000494c <end_op+0x52>

0000000080004a52 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004a52:	1101                	addi	sp,sp,-32
    80004a54:	ec06                	sd	ra,24(sp)
    80004a56:	e822                	sd	s0,16(sp)
    80004a58:	e426                	sd	s1,8(sp)
    80004a5a:	e04a                	sd	s2,0(sp)
    80004a5c:	1000                	addi	s0,sp,32
    80004a5e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004a60:	0001e917          	auipc	s2,0x1e
    80004a64:	f5890913          	addi	s2,s2,-168 # 800229b8 <log>
    80004a68:	854a                	mv	a0,s2
    80004a6a:	ffffc097          	auipc	ra,0xffffc
    80004a6e:	180080e7          	jalr	384(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004a72:	02c92603          	lw	a2,44(s2)
    80004a76:	47f5                	li	a5,29
    80004a78:	06c7c563          	blt	a5,a2,80004ae2 <log_write+0x90>
    80004a7c:	0001e797          	auipc	a5,0x1e
    80004a80:	f587a783          	lw	a5,-168(a5) # 800229d4 <log+0x1c>
    80004a84:	37fd                	addiw	a5,a5,-1
    80004a86:	04f65e63          	bge	a2,a5,80004ae2 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004a8a:	0001e797          	auipc	a5,0x1e
    80004a8e:	f4e7a783          	lw	a5,-178(a5) # 800229d8 <log+0x20>
    80004a92:	06f05063          	blez	a5,80004af2 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004a96:	4781                	li	a5,0
    80004a98:	06c05563          	blez	a2,80004b02 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004a9c:	44cc                	lw	a1,12(s1)
    80004a9e:	0001e717          	auipc	a4,0x1e
    80004aa2:	f4a70713          	addi	a4,a4,-182 # 800229e8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004aa6:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004aa8:	4314                	lw	a3,0(a4)
    80004aaa:	04b68c63          	beq	a3,a1,80004b02 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004aae:	2785                	addiw	a5,a5,1
    80004ab0:	0711                	addi	a4,a4,4
    80004ab2:	fef61be3          	bne	a2,a5,80004aa8 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004ab6:	0621                	addi	a2,a2,8
    80004ab8:	060a                	slli	a2,a2,0x2
    80004aba:	0001e797          	auipc	a5,0x1e
    80004abe:	efe78793          	addi	a5,a5,-258 # 800229b8 <log>
    80004ac2:	963e                	add	a2,a2,a5
    80004ac4:	44dc                	lw	a5,12(s1)
    80004ac6:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004ac8:	8526                	mv	a0,s1
    80004aca:	fffff097          	auipc	ra,0xfffff
    80004ace:	da2080e7          	jalr	-606(ra) # 8000386c <bpin>
    log.lh.n++;
    80004ad2:	0001e717          	auipc	a4,0x1e
    80004ad6:	ee670713          	addi	a4,a4,-282 # 800229b8 <log>
    80004ada:	575c                	lw	a5,44(a4)
    80004adc:	2785                	addiw	a5,a5,1
    80004ade:	d75c                	sw	a5,44(a4)
    80004ae0:	a835                	j	80004b1c <log_write+0xca>
    panic("too big a transaction");
    80004ae2:	00004517          	auipc	a0,0x4
    80004ae6:	c9650513          	addi	a0,a0,-874 # 80008778 <syscalls+0x220>
    80004aea:	ffffc097          	auipc	ra,0xffffc
    80004aee:	a5a080e7          	jalr	-1446(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    80004af2:	00004517          	auipc	a0,0x4
    80004af6:	c9e50513          	addi	a0,a0,-866 # 80008790 <syscalls+0x238>
    80004afa:	ffffc097          	auipc	ra,0xffffc
    80004afe:	a4a080e7          	jalr	-1462(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    80004b02:	00878713          	addi	a4,a5,8
    80004b06:	00271693          	slli	a3,a4,0x2
    80004b0a:	0001e717          	auipc	a4,0x1e
    80004b0e:	eae70713          	addi	a4,a4,-338 # 800229b8 <log>
    80004b12:	9736                	add	a4,a4,a3
    80004b14:	44d4                	lw	a3,12(s1)
    80004b16:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004b18:	faf608e3          	beq	a2,a5,80004ac8 <log_write+0x76>
  }
  release(&log.lock);
    80004b1c:	0001e517          	auipc	a0,0x1e
    80004b20:	e9c50513          	addi	a0,a0,-356 # 800229b8 <log>
    80004b24:	ffffc097          	auipc	ra,0xffffc
    80004b28:	17a080e7          	jalr	378(ra) # 80000c9e <release>
}
    80004b2c:	60e2                	ld	ra,24(sp)
    80004b2e:	6442                	ld	s0,16(sp)
    80004b30:	64a2                	ld	s1,8(sp)
    80004b32:	6902                	ld	s2,0(sp)
    80004b34:	6105                	addi	sp,sp,32
    80004b36:	8082                	ret

0000000080004b38 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004b38:	1101                	addi	sp,sp,-32
    80004b3a:	ec06                	sd	ra,24(sp)
    80004b3c:	e822                	sd	s0,16(sp)
    80004b3e:	e426                	sd	s1,8(sp)
    80004b40:	e04a                	sd	s2,0(sp)
    80004b42:	1000                	addi	s0,sp,32
    80004b44:	84aa                	mv	s1,a0
    80004b46:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004b48:	00004597          	auipc	a1,0x4
    80004b4c:	c6858593          	addi	a1,a1,-920 # 800087b0 <syscalls+0x258>
    80004b50:	0521                	addi	a0,a0,8
    80004b52:	ffffc097          	auipc	ra,0xffffc
    80004b56:	008080e7          	jalr	8(ra) # 80000b5a <initlock>
  lk->name = name;
    80004b5a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004b5e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b62:	0204a423          	sw	zero,40(s1)
}
    80004b66:	60e2                	ld	ra,24(sp)
    80004b68:	6442                	ld	s0,16(sp)
    80004b6a:	64a2                	ld	s1,8(sp)
    80004b6c:	6902                	ld	s2,0(sp)
    80004b6e:	6105                	addi	sp,sp,32
    80004b70:	8082                	ret

0000000080004b72 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004b72:	1101                	addi	sp,sp,-32
    80004b74:	ec06                	sd	ra,24(sp)
    80004b76:	e822                	sd	s0,16(sp)
    80004b78:	e426                	sd	s1,8(sp)
    80004b7a:	e04a                	sd	s2,0(sp)
    80004b7c:	1000                	addi	s0,sp,32
    80004b7e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b80:	00850913          	addi	s2,a0,8
    80004b84:	854a                	mv	a0,s2
    80004b86:	ffffc097          	auipc	ra,0xffffc
    80004b8a:	064080e7          	jalr	100(ra) # 80000bea <acquire>
  while (lk->locked) {
    80004b8e:	409c                	lw	a5,0(s1)
    80004b90:	cb89                	beqz	a5,80004ba2 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004b92:	85ca                	mv	a1,s2
    80004b94:	8526                	mv	a0,s1
    80004b96:	ffffe097          	auipc	ra,0xffffe
    80004b9a:	8c8080e7          	jalr	-1848(ra) # 8000245e <sleep>
  while (lk->locked) {
    80004b9e:	409c                	lw	a5,0(s1)
    80004ba0:	fbed                	bnez	a5,80004b92 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004ba2:	4785                	li	a5,1
    80004ba4:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004ba6:	ffffd097          	auipc	ra,0xffffd
    80004baa:	00e080e7          	jalr	14(ra) # 80001bb4 <myproc>
    80004bae:	591c                	lw	a5,48(a0)
    80004bb0:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004bb2:	854a                	mv	a0,s2
    80004bb4:	ffffc097          	auipc	ra,0xffffc
    80004bb8:	0ea080e7          	jalr	234(ra) # 80000c9e <release>
}
    80004bbc:	60e2                	ld	ra,24(sp)
    80004bbe:	6442                	ld	s0,16(sp)
    80004bc0:	64a2                	ld	s1,8(sp)
    80004bc2:	6902                	ld	s2,0(sp)
    80004bc4:	6105                	addi	sp,sp,32
    80004bc6:	8082                	ret

0000000080004bc8 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004bc8:	1101                	addi	sp,sp,-32
    80004bca:	ec06                	sd	ra,24(sp)
    80004bcc:	e822                	sd	s0,16(sp)
    80004bce:	e426                	sd	s1,8(sp)
    80004bd0:	e04a                	sd	s2,0(sp)
    80004bd2:	1000                	addi	s0,sp,32
    80004bd4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004bd6:	00850913          	addi	s2,a0,8
    80004bda:	854a                	mv	a0,s2
    80004bdc:	ffffc097          	auipc	ra,0xffffc
    80004be0:	00e080e7          	jalr	14(ra) # 80000bea <acquire>
  lk->locked = 0;
    80004be4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004be8:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004bec:	8526                	mv	a0,s1
    80004bee:	ffffe097          	auipc	ra,0xffffe
    80004bf2:	a20080e7          	jalr	-1504(ra) # 8000260e <wakeup>
  release(&lk->lk);
    80004bf6:	854a                	mv	a0,s2
    80004bf8:	ffffc097          	auipc	ra,0xffffc
    80004bfc:	0a6080e7          	jalr	166(ra) # 80000c9e <release>
}
    80004c00:	60e2                	ld	ra,24(sp)
    80004c02:	6442                	ld	s0,16(sp)
    80004c04:	64a2                	ld	s1,8(sp)
    80004c06:	6902                	ld	s2,0(sp)
    80004c08:	6105                	addi	sp,sp,32
    80004c0a:	8082                	ret

0000000080004c0c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004c0c:	7179                	addi	sp,sp,-48
    80004c0e:	f406                	sd	ra,40(sp)
    80004c10:	f022                	sd	s0,32(sp)
    80004c12:	ec26                	sd	s1,24(sp)
    80004c14:	e84a                	sd	s2,16(sp)
    80004c16:	e44e                	sd	s3,8(sp)
    80004c18:	1800                	addi	s0,sp,48
    80004c1a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004c1c:	00850913          	addi	s2,a0,8
    80004c20:	854a                	mv	a0,s2
    80004c22:	ffffc097          	auipc	ra,0xffffc
    80004c26:	fc8080e7          	jalr	-56(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c2a:	409c                	lw	a5,0(s1)
    80004c2c:	ef99                	bnez	a5,80004c4a <holdingsleep+0x3e>
    80004c2e:	4481                	li	s1,0
  release(&lk->lk);
    80004c30:	854a                	mv	a0,s2
    80004c32:	ffffc097          	auipc	ra,0xffffc
    80004c36:	06c080e7          	jalr	108(ra) # 80000c9e <release>
  return r;
}
    80004c3a:	8526                	mv	a0,s1
    80004c3c:	70a2                	ld	ra,40(sp)
    80004c3e:	7402                	ld	s0,32(sp)
    80004c40:	64e2                	ld	s1,24(sp)
    80004c42:	6942                	ld	s2,16(sp)
    80004c44:	69a2                	ld	s3,8(sp)
    80004c46:	6145                	addi	sp,sp,48
    80004c48:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c4a:	0284a983          	lw	s3,40(s1)
    80004c4e:	ffffd097          	auipc	ra,0xffffd
    80004c52:	f66080e7          	jalr	-154(ra) # 80001bb4 <myproc>
    80004c56:	5904                	lw	s1,48(a0)
    80004c58:	413484b3          	sub	s1,s1,s3
    80004c5c:	0014b493          	seqz	s1,s1
    80004c60:	bfc1                	j	80004c30 <holdingsleep+0x24>

0000000080004c62 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004c62:	1141                	addi	sp,sp,-16
    80004c64:	e406                	sd	ra,8(sp)
    80004c66:	e022                	sd	s0,0(sp)
    80004c68:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004c6a:	00004597          	auipc	a1,0x4
    80004c6e:	b5658593          	addi	a1,a1,-1194 # 800087c0 <syscalls+0x268>
    80004c72:	0001e517          	auipc	a0,0x1e
    80004c76:	e8e50513          	addi	a0,a0,-370 # 80022b00 <ftable>
    80004c7a:	ffffc097          	auipc	ra,0xffffc
    80004c7e:	ee0080e7          	jalr	-288(ra) # 80000b5a <initlock>
}
    80004c82:	60a2                	ld	ra,8(sp)
    80004c84:	6402                	ld	s0,0(sp)
    80004c86:	0141                	addi	sp,sp,16
    80004c88:	8082                	ret

0000000080004c8a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004c8a:	1101                	addi	sp,sp,-32
    80004c8c:	ec06                	sd	ra,24(sp)
    80004c8e:	e822                	sd	s0,16(sp)
    80004c90:	e426                	sd	s1,8(sp)
    80004c92:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004c94:	0001e517          	auipc	a0,0x1e
    80004c98:	e6c50513          	addi	a0,a0,-404 # 80022b00 <ftable>
    80004c9c:	ffffc097          	auipc	ra,0xffffc
    80004ca0:	f4e080e7          	jalr	-178(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004ca4:	0001e497          	auipc	s1,0x1e
    80004ca8:	e7448493          	addi	s1,s1,-396 # 80022b18 <ftable+0x18>
    80004cac:	0001f717          	auipc	a4,0x1f
    80004cb0:	e0c70713          	addi	a4,a4,-500 # 80023ab8 <disk>
    if(f->ref == 0){
    80004cb4:	40dc                	lw	a5,4(s1)
    80004cb6:	cf99                	beqz	a5,80004cd4 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004cb8:	02848493          	addi	s1,s1,40
    80004cbc:	fee49ce3          	bne	s1,a4,80004cb4 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004cc0:	0001e517          	auipc	a0,0x1e
    80004cc4:	e4050513          	addi	a0,a0,-448 # 80022b00 <ftable>
    80004cc8:	ffffc097          	auipc	ra,0xffffc
    80004ccc:	fd6080e7          	jalr	-42(ra) # 80000c9e <release>
  return 0;
    80004cd0:	4481                	li	s1,0
    80004cd2:	a819                	j	80004ce8 <filealloc+0x5e>
      f->ref = 1;
    80004cd4:	4785                	li	a5,1
    80004cd6:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004cd8:	0001e517          	auipc	a0,0x1e
    80004cdc:	e2850513          	addi	a0,a0,-472 # 80022b00 <ftable>
    80004ce0:	ffffc097          	auipc	ra,0xffffc
    80004ce4:	fbe080e7          	jalr	-66(ra) # 80000c9e <release>
}
    80004ce8:	8526                	mv	a0,s1
    80004cea:	60e2                	ld	ra,24(sp)
    80004cec:	6442                	ld	s0,16(sp)
    80004cee:	64a2                	ld	s1,8(sp)
    80004cf0:	6105                	addi	sp,sp,32
    80004cf2:	8082                	ret

0000000080004cf4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004cf4:	1101                	addi	sp,sp,-32
    80004cf6:	ec06                	sd	ra,24(sp)
    80004cf8:	e822                	sd	s0,16(sp)
    80004cfa:	e426                	sd	s1,8(sp)
    80004cfc:	1000                	addi	s0,sp,32
    80004cfe:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004d00:	0001e517          	auipc	a0,0x1e
    80004d04:	e0050513          	addi	a0,a0,-512 # 80022b00 <ftable>
    80004d08:	ffffc097          	auipc	ra,0xffffc
    80004d0c:	ee2080e7          	jalr	-286(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004d10:	40dc                	lw	a5,4(s1)
    80004d12:	02f05263          	blez	a5,80004d36 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004d16:	2785                	addiw	a5,a5,1
    80004d18:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004d1a:	0001e517          	auipc	a0,0x1e
    80004d1e:	de650513          	addi	a0,a0,-538 # 80022b00 <ftable>
    80004d22:	ffffc097          	auipc	ra,0xffffc
    80004d26:	f7c080e7          	jalr	-132(ra) # 80000c9e <release>
  return f;
}
    80004d2a:	8526                	mv	a0,s1
    80004d2c:	60e2                	ld	ra,24(sp)
    80004d2e:	6442                	ld	s0,16(sp)
    80004d30:	64a2                	ld	s1,8(sp)
    80004d32:	6105                	addi	sp,sp,32
    80004d34:	8082                	ret
    panic("filedup");
    80004d36:	00004517          	auipc	a0,0x4
    80004d3a:	a9250513          	addi	a0,a0,-1390 # 800087c8 <syscalls+0x270>
    80004d3e:	ffffc097          	auipc	ra,0xffffc
    80004d42:	806080e7          	jalr	-2042(ra) # 80000544 <panic>

0000000080004d46 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004d46:	7139                	addi	sp,sp,-64
    80004d48:	fc06                	sd	ra,56(sp)
    80004d4a:	f822                	sd	s0,48(sp)
    80004d4c:	f426                	sd	s1,40(sp)
    80004d4e:	f04a                	sd	s2,32(sp)
    80004d50:	ec4e                	sd	s3,24(sp)
    80004d52:	e852                	sd	s4,16(sp)
    80004d54:	e456                	sd	s5,8(sp)
    80004d56:	0080                	addi	s0,sp,64
    80004d58:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004d5a:	0001e517          	auipc	a0,0x1e
    80004d5e:	da650513          	addi	a0,a0,-602 # 80022b00 <ftable>
    80004d62:	ffffc097          	auipc	ra,0xffffc
    80004d66:	e88080e7          	jalr	-376(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004d6a:	40dc                	lw	a5,4(s1)
    80004d6c:	06f05163          	blez	a5,80004dce <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004d70:	37fd                	addiw	a5,a5,-1
    80004d72:	0007871b          	sext.w	a4,a5
    80004d76:	c0dc                	sw	a5,4(s1)
    80004d78:	06e04363          	bgtz	a4,80004dde <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004d7c:	0004a903          	lw	s2,0(s1)
    80004d80:	0094ca83          	lbu	s5,9(s1)
    80004d84:	0104ba03          	ld	s4,16(s1)
    80004d88:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004d8c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004d90:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004d94:	0001e517          	auipc	a0,0x1e
    80004d98:	d6c50513          	addi	a0,a0,-660 # 80022b00 <ftable>
    80004d9c:	ffffc097          	auipc	ra,0xffffc
    80004da0:	f02080e7          	jalr	-254(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    80004da4:	4785                	li	a5,1
    80004da6:	04f90d63          	beq	s2,a5,80004e00 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004daa:	3979                	addiw	s2,s2,-2
    80004dac:	4785                	li	a5,1
    80004dae:	0527e063          	bltu	a5,s2,80004dee <fileclose+0xa8>
    begin_op();
    80004db2:	00000097          	auipc	ra,0x0
    80004db6:	ac8080e7          	jalr	-1336(ra) # 8000487a <begin_op>
    iput(ff.ip);
    80004dba:	854e                	mv	a0,s3
    80004dbc:	fffff097          	auipc	ra,0xfffff
    80004dc0:	2b6080e7          	jalr	694(ra) # 80004072 <iput>
    end_op();
    80004dc4:	00000097          	auipc	ra,0x0
    80004dc8:	b36080e7          	jalr	-1226(ra) # 800048fa <end_op>
    80004dcc:	a00d                	j	80004dee <fileclose+0xa8>
    panic("fileclose");
    80004dce:	00004517          	auipc	a0,0x4
    80004dd2:	a0250513          	addi	a0,a0,-1534 # 800087d0 <syscalls+0x278>
    80004dd6:	ffffb097          	auipc	ra,0xffffb
    80004dda:	76e080e7          	jalr	1902(ra) # 80000544 <panic>
    release(&ftable.lock);
    80004dde:	0001e517          	auipc	a0,0x1e
    80004de2:	d2250513          	addi	a0,a0,-734 # 80022b00 <ftable>
    80004de6:	ffffc097          	auipc	ra,0xffffc
    80004dea:	eb8080e7          	jalr	-328(ra) # 80000c9e <release>
  }
}
    80004dee:	70e2                	ld	ra,56(sp)
    80004df0:	7442                	ld	s0,48(sp)
    80004df2:	74a2                	ld	s1,40(sp)
    80004df4:	7902                	ld	s2,32(sp)
    80004df6:	69e2                	ld	s3,24(sp)
    80004df8:	6a42                	ld	s4,16(sp)
    80004dfa:	6aa2                	ld	s5,8(sp)
    80004dfc:	6121                	addi	sp,sp,64
    80004dfe:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004e00:	85d6                	mv	a1,s5
    80004e02:	8552                	mv	a0,s4
    80004e04:	00000097          	auipc	ra,0x0
    80004e08:	34c080e7          	jalr	844(ra) # 80005150 <pipeclose>
    80004e0c:	b7cd                	j	80004dee <fileclose+0xa8>

0000000080004e0e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004e0e:	715d                	addi	sp,sp,-80
    80004e10:	e486                	sd	ra,72(sp)
    80004e12:	e0a2                	sd	s0,64(sp)
    80004e14:	fc26                	sd	s1,56(sp)
    80004e16:	f84a                	sd	s2,48(sp)
    80004e18:	f44e                	sd	s3,40(sp)
    80004e1a:	0880                	addi	s0,sp,80
    80004e1c:	84aa                	mv	s1,a0
    80004e1e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004e20:	ffffd097          	auipc	ra,0xffffd
    80004e24:	d94080e7          	jalr	-620(ra) # 80001bb4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004e28:	409c                	lw	a5,0(s1)
    80004e2a:	37f9                	addiw	a5,a5,-2
    80004e2c:	4705                	li	a4,1
    80004e2e:	04f76763          	bltu	a4,a5,80004e7c <filestat+0x6e>
    80004e32:	892a                	mv	s2,a0
    ilock(f->ip);
    80004e34:	6c88                	ld	a0,24(s1)
    80004e36:	fffff097          	auipc	ra,0xfffff
    80004e3a:	082080e7          	jalr	130(ra) # 80003eb8 <ilock>
    stati(f->ip, &st);
    80004e3e:	fb840593          	addi	a1,s0,-72
    80004e42:	6c88                	ld	a0,24(s1)
    80004e44:	fffff097          	auipc	ra,0xfffff
    80004e48:	2fe080e7          	jalr	766(ra) # 80004142 <stati>
    iunlock(f->ip);
    80004e4c:	6c88                	ld	a0,24(s1)
    80004e4e:	fffff097          	auipc	ra,0xfffff
    80004e52:	12c080e7          	jalr	300(ra) # 80003f7a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004e56:	46e1                	li	a3,24
    80004e58:	fb840613          	addi	a2,s0,-72
    80004e5c:	85ce                	mv	a1,s3
    80004e5e:	05093503          	ld	a0,80(s2)
    80004e62:	ffffd097          	auipc	ra,0xffffd
    80004e66:	822080e7          	jalr	-2014(ra) # 80001684 <copyout>
    80004e6a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004e6e:	60a6                	ld	ra,72(sp)
    80004e70:	6406                	ld	s0,64(sp)
    80004e72:	74e2                	ld	s1,56(sp)
    80004e74:	7942                	ld	s2,48(sp)
    80004e76:	79a2                	ld	s3,40(sp)
    80004e78:	6161                	addi	sp,sp,80
    80004e7a:	8082                	ret
  return -1;
    80004e7c:	557d                	li	a0,-1
    80004e7e:	bfc5                	j	80004e6e <filestat+0x60>

0000000080004e80 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004e80:	7179                	addi	sp,sp,-48
    80004e82:	f406                	sd	ra,40(sp)
    80004e84:	f022                	sd	s0,32(sp)
    80004e86:	ec26                	sd	s1,24(sp)
    80004e88:	e84a                	sd	s2,16(sp)
    80004e8a:	e44e                	sd	s3,8(sp)
    80004e8c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004e8e:	00854783          	lbu	a5,8(a0)
    80004e92:	c3d5                	beqz	a5,80004f36 <fileread+0xb6>
    80004e94:	84aa                	mv	s1,a0
    80004e96:	89ae                	mv	s3,a1
    80004e98:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e9a:	411c                	lw	a5,0(a0)
    80004e9c:	4705                	li	a4,1
    80004e9e:	04e78963          	beq	a5,a4,80004ef0 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ea2:	470d                	li	a4,3
    80004ea4:	04e78d63          	beq	a5,a4,80004efe <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ea8:	4709                	li	a4,2
    80004eaa:	06e79e63          	bne	a5,a4,80004f26 <fileread+0xa6>
    ilock(f->ip);
    80004eae:	6d08                	ld	a0,24(a0)
    80004eb0:	fffff097          	auipc	ra,0xfffff
    80004eb4:	008080e7          	jalr	8(ra) # 80003eb8 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004eb8:	874a                	mv	a4,s2
    80004eba:	5094                	lw	a3,32(s1)
    80004ebc:	864e                	mv	a2,s3
    80004ebe:	4585                	li	a1,1
    80004ec0:	6c88                	ld	a0,24(s1)
    80004ec2:	fffff097          	auipc	ra,0xfffff
    80004ec6:	2aa080e7          	jalr	682(ra) # 8000416c <readi>
    80004eca:	892a                	mv	s2,a0
    80004ecc:	00a05563          	blez	a0,80004ed6 <fileread+0x56>
      f->off += r;
    80004ed0:	509c                	lw	a5,32(s1)
    80004ed2:	9fa9                	addw	a5,a5,a0
    80004ed4:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004ed6:	6c88                	ld	a0,24(s1)
    80004ed8:	fffff097          	auipc	ra,0xfffff
    80004edc:	0a2080e7          	jalr	162(ra) # 80003f7a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004ee0:	854a                	mv	a0,s2
    80004ee2:	70a2                	ld	ra,40(sp)
    80004ee4:	7402                	ld	s0,32(sp)
    80004ee6:	64e2                	ld	s1,24(sp)
    80004ee8:	6942                	ld	s2,16(sp)
    80004eea:	69a2                	ld	s3,8(sp)
    80004eec:	6145                	addi	sp,sp,48
    80004eee:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004ef0:	6908                	ld	a0,16(a0)
    80004ef2:	00000097          	auipc	ra,0x0
    80004ef6:	3ce080e7          	jalr	974(ra) # 800052c0 <piperead>
    80004efa:	892a                	mv	s2,a0
    80004efc:	b7d5                	j	80004ee0 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004efe:	02451783          	lh	a5,36(a0)
    80004f02:	03079693          	slli	a3,a5,0x30
    80004f06:	92c1                	srli	a3,a3,0x30
    80004f08:	4725                	li	a4,9
    80004f0a:	02d76863          	bltu	a4,a3,80004f3a <fileread+0xba>
    80004f0e:	0792                	slli	a5,a5,0x4
    80004f10:	0001e717          	auipc	a4,0x1e
    80004f14:	b5070713          	addi	a4,a4,-1200 # 80022a60 <devsw>
    80004f18:	97ba                	add	a5,a5,a4
    80004f1a:	639c                	ld	a5,0(a5)
    80004f1c:	c38d                	beqz	a5,80004f3e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004f1e:	4505                	li	a0,1
    80004f20:	9782                	jalr	a5
    80004f22:	892a                	mv	s2,a0
    80004f24:	bf75                	j	80004ee0 <fileread+0x60>
    panic("fileread");
    80004f26:	00004517          	auipc	a0,0x4
    80004f2a:	8ba50513          	addi	a0,a0,-1862 # 800087e0 <syscalls+0x288>
    80004f2e:	ffffb097          	auipc	ra,0xffffb
    80004f32:	616080e7          	jalr	1558(ra) # 80000544 <panic>
    return -1;
    80004f36:	597d                	li	s2,-1
    80004f38:	b765                	j	80004ee0 <fileread+0x60>
      return -1;
    80004f3a:	597d                	li	s2,-1
    80004f3c:	b755                	j	80004ee0 <fileread+0x60>
    80004f3e:	597d                	li	s2,-1
    80004f40:	b745                	j	80004ee0 <fileread+0x60>

0000000080004f42 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004f42:	715d                	addi	sp,sp,-80
    80004f44:	e486                	sd	ra,72(sp)
    80004f46:	e0a2                	sd	s0,64(sp)
    80004f48:	fc26                	sd	s1,56(sp)
    80004f4a:	f84a                	sd	s2,48(sp)
    80004f4c:	f44e                	sd	s3,40(sp)
    80004f4e:	f052                	sd	s4,32(sp)
    80004f50:	ec56                	sd	s5,24(sp)
    80004f52:	e85a                	sd	s6,16(sp)
    80004f54:	e45e                	sd	s7,8(sp)
    80004f56:	e062                	sd	s8,0(sp)
    80004f58:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004f5a:	00954783          	lbu	a5,9(a0)
    80004f5e:	10078663          	beqz	a5,8000506a <filewrite+0x128>
    80004f62:	892a                	mv	s2,a0
    80004f64:	8aae                	mv	s5,a1
    80004f66:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004f68:	411c                	lw	a5,0(a0)
    80004f6a:	4705                	li	a4,1
    80004f6c:	02e78263          	beq	a5,a4,80004f90 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004f70:	470d                	li	a4,3
    80004f72:	02e78663          	beq	a5,a4,80004f9e <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004f76:	4709                	li	a4,2
    80004f78:	0ee79163          	bne	a5,a4,8000505a <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004f7c:	0ac05d63          	blez	a2,80005036 <filewrite+0xf4>
    int i = 0;
    80004f80:	4981                	li	s3,0
    80004f82:	6b05                	lui	s6,0x1
    80004f84:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004f88:	6b85                	lui	s7,0x1
    80004f8a:	c00b8b9b          	addiw	s7,s7,-1024
    80004f8e:	a861                	j	80005026 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004f90:	6908                	ld	a0,16(a0)
    80004f92:	00000097          	auipc	ra,0x0
    80004f96:	22e080e7          	jalr	558(ra) # 800051c0 <pipewrite>
    80004f9a:	8a2a                	mv	s4,a0
    80004f9c:	a045                	j	8000503c <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004f9e:	02451783          	lh	a5,36(a0)
    80004fa2:	03079693          	slli	a3,a5,0x30
    80004fa6:	92c1                	srli	a3,a3,0x30
    80004fa8:	4725                	li	a4,9
    80004faa:	0cd76263          	bltu	a4,a3,8000506e <filewrite+0x12c>
    80004fae:	0792                	slli	a5,a5,0x4
    80004fb0:	0001e717          	auipc	a4,0x1e
    80004fb4:	ab070713          	addi	a4,a4,-1360 # 80022a60 <devsw>
    80004fb8:	97ba                	add	a5,a5,a4
    80004fba:	679c                	ld	a5,8(a5)
    80004fbc:	cbdd                	beqz	a5,80005072 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004fbe:	4505                	li	a0,1
    80004fc0:	9782                	jalr	a5
    80004fc2:	8a2a                	mv	s4,a0
    80004fc4:	a8a5                	j	8000503c <filewrite+0xfa>
    80004fc6:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004fca:	00000097          	auipc	ra,0x0
    80004fce:	8b0080e7          	jalr	-1872(ra) # 8000487a <begin_op>
      ilock(f->ip);
    80004fd2:	01893503          	ld	a0,24(s2)
    80004fd6:	fffff097          	auipc	ra,0xfffff
    80004fda:	ee2080e7          	jalr	-286(ra) # 80003eb8 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004fde:	8762                	mv	a4,s8
    80004fe0:	02092683          	lw	a3,32(s2)
    80004fe4:	01598633          	add	a2,s3,s5
    80004fe8:	4585                	li	a1,1
    80004fea:	01893503          	ld	a0,24(s2)
    80004fee:	fffff097          	auipc	ra,0xfffff
    80004ff2:	276080e7          	jalr	630(ra) # 80004264 <writei>
    80004ff6:	84aa                	mv	s1,a0
    80004ff8:	00a05763          	blez	a0,80005006 <filewrite+0xc4>
        f->off += r;
    80004ffc:	02092783          	lw	a5,32(s2)
    80005000:	9fa9                	addw	a5,a5,a0
    80005002:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005006:	01893503          	ld	a0,24(s2)
    8000500a:	fffff097          	auipc	ra,0xfffff
    8000500e:	f70080e7          	jalr	-144(ra) # 80003f7a <iunlock>
      end_op();
    80005012:	00000097          	auipc	ra,0x0
    80005016:	8e8080e7          	jalr	-1816(ra) # 800048fa <end_op>

      if(r != n1){
    8000501a:	009c1f63          	bne	s8,s1,80005038 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000501e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005022:	0149db63          	bge	s3,s4,80005038 <filewrite+0xf6>
      int n1 = n - i;
    80005026:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000502a:	84be                	mv	s1,a5
    8000502c:	2781                	sext.w	a5,a5
    8000502e:	f8fb5ce3          	bge	s6,a5,80004fc6 <filewrite+0x84>
    80005032:	84de                	mv	s1,s7
    80005034:	bf49                	j	80004fc6 <filewrite+0x84>
    int i = 0;
    80005036:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005038:	013a1f63          	bne	s4,s3,80005056 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000503c:	8552                	mv	a0,s4
    8000503e:	60a6                	ld	ra,72(sp)
    80005040:	6406                	ld	s0,64(sp)
    80005042:	74e2                	ld	s1,56(sp)
    80005044:	7942                	ld	s2,48(sp)
    80005046:	79a2                	ld	s3,40(sp)
    80005048:	7a02                	ld	s4,32(sp)
    8000504a:	6ae2                	ld	s5,24(sp)
    8000504c:	6b42                	ld	s6,16(sp)
    8000504e:	6ba2                	ld	s7,8(sp)
    80005050:	6c02                	ld	s8,0(sp)
    80005052:	6161                	addi	sp,sp,80
    80005054:	8082                	ret
    ret = (i == n ? n : -1);
    80005056:	5a7d                	li	s4,-1
    80005058:	b7d5                	j	8000503c <filewrite+0xfa>
    panic("filewrite");
    8000505a:	00003517          	auipc	a0,0x3
    8000505e:	79650513          	addi	a0,a0,1942 # 800087f0 <syscalls+0x298>
    80005062:	ffffb097          	auipc	ra,0xffffb
    80005066:	4e2080e7          	jalr	1250(ra) # 80000544 <panic>
    return -1;
    8000506a:	5a7d                	li	s4,-1
    8000506c:	bfc1                	j	8000503c <filewrite+0xfa>
      return -1;
    8000506e:	5a7d                	li	s4,-1
    80005070:	b7f1                	j	8000503c <filewrite+0xfa>
    80005072:	5a7d                	li	s4,-1
    80005074:	b7e1                	j	8000503c <filewrite+0xfa>

0000000080005076 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005076:	7179                	addi	sp,sp,-48
    80005078:	f406                	sd	ra,40(sp)
    8000507a:	f022                	sd	s0,32(sp)
    8000507c:	ec26                	sd	s1,24(sp)
    8000507e:	e84a                	sd	s2,16(sp)
    80005080:	e44e                	sd	s3,8(sp)
    80005082:	e052                	sd	s4,0(sp)
    80005084:	1800                	addi	s0,sp,48
    80005086:	84aa                	mv	s1,a0
    80005088:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000508a:	0005b023          	sd	zero,0(a1)
    8000508e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005092:	00000097          	auipc	ra,0x0
    80005096:	bf8080e7          	jalr	-1032(ra) # 80004c8a <filealloc>
    8000509a:	e088                	sd	a0,0(s1)
    8000509c:	c551                	beqz	a0,80005128 <pipealloc+0xb2>
    8000509e:	00000097          	auipc	ra,0x0
    800050a2:	bec080e7          	jalr	-1044(ra) # 80004c8a <filealloc>
    800050a6:	00aa3023          	sd	a0,0(s4)
    800050aa:	c92d                	beqz	a0,8000511c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800050ac:	ffffc097          	auipc	ra,0xffffc
    800050b0:	a4e080e7          	jalr	-1458(ra) # 80000afa <kalloc>
    800050b4:	892a                	mv	s2,a0
    800050b6:	c125                	beqz	a0,80005116 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800050b8:	4985                	li	s3,1
    800050ba:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800050be:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800050c2:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800050c6:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800050ca:	00003597          	auipc	a1,0x3
    800050ce:	3c658593          	addi	a1,a1,966 # 80008490 <states.1801+0x1a0>
    800050d2:	ffffc097          	auipc	ra,0xffffc
    800050d6:	a88080e7          	jalr	-1400(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    800050da:	609c                	ld	a5,0(s1)
    800050dc:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800050e0:	609c                	ld	a5,0(s1)
    800050e2:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800050e6:	609c                	ld	a5,0(s1)
    800050e8:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800050ec:	609c                	ld	a5,0(s1)
    800050ee:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800050f2:	000a3783          	ld	a5,0(s4)
    800050f6:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800050fa:	000a3783          	ld	a5,0(s4)
    800050fe:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005102:	000a3783          	ld	a5,0(s4)
    80005106:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000510a:	000a3783          	ld	a5,0(s4)
    8000510e:	0127b823          	sd	s2,16(a5)
  return 0;
    80005112:	4501                	li	a0,0
    80005114:	a025                	j	8000513c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005116:	6088                	ld	a0,0(s1)
    80005118:	e501                	bnez	a0,80005120 <pipealloc+0xaa>
    8000511a:	a039                	j	80005128 <pipealloc+0xb2>
    8000511c:	6088                	ld	a0,0(s1)
    8000511e:	c51d                	beqz	a0,8000514c <pipealloc+0xd6>
    fileclose(*f0);
    80005120:	00000097          	auipc	ra,0x0
    80005124:	c26080e7          	jalr	-986(ra) # 80004d46 <fileclose>
  if(*f1)
    80005128:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000512c:	557d                	li	a0,-1
  if(*f1)
    8000512e:	c799                	beqz	a5,8000513c <pipealloc+0xc6>
    fileclose(*f1);
    80005130:	853e                	mv	a0,a5
    80005132:	00000097          	auipc	ra,0x0
    80005136:	c14080e7          	jalr	-1004(ra) # 80004d46 <fileclose>
  return -1;
    8000513a:	557d                	li	a0,-1
}
    8000513c:	70a2                	ld	ra,40(sp)
    8000513e:	7402                	ld	s0,32(sp)
    80005140:	64e2                	ld	s1,24(sp)
    80005142:	6942                	ld	s2,16(sp)
    80005144:	69a2                	ld	s3,8(sp)
    80005146:	6a02                	ld	s4,0(sp)
    80005148:	6145                	addi	sp,sp,48
    8000514a:	8082                	ret
  return -1;
    8000514c:	557d                	li	a0,-1
    8000514e:	b7fd                	j	8000513c <pipealloc+0xc6>

0000000080005150 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005150:	1101                	addi	sp,sp,-32
    80005152:	ec06                	sd	ra,24(sp)
    80005154:	e822                	sd	s0,16(sp)
    80005156:	e426                	sd	s1,8(sp)
    80005158:	e04a                	sd	s2,0(sp)
    8000515a:	1000                	addi	s0,sp,32
    8000515c:	84aa                	mv	s1,a0
    8000515e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005160:	ffffc097          	auipc	ra,0xffffc
    80005164:	a8a080e7          	jalr	-1398(ra) # 80000bea <acquire>
  if(writable){
    80005168:	02090d63          	beqz	s2,800051a2 <pipeclose+0x52>
    pi->writeopen = 0;
    8000516c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005170:	21848513          	addi	a0,s1,536
    80005174:	ffffd097          	auipc	ra,0xffffd
    80005178:	49a080e7          	jalr	1178(ra) # 8000260e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000517c:	2204b783          	ld	a5,544(s1)
    80005180:	eb95                	bnez	a5,800051b4 <pipeclose+0x64>
    release(&pi->lock);
    80005182:	8526                	mv	a0,s1
    80005184:	ffffc097          	auipc	ra,0xffffc
    80005188:	b1a080e7          	jalr	-1254(ra) # 80000c9e <release>
    kfree((char*)pi);
    8000518c:	8526                	mv	a0,s1
    8000518e:	ffffc097          	auipc	ra,0xffffc
    80005192:	870080e7          	jalr	-1936(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80005196:	60e2                	ld	ra,24(sp)
    80005198:	6442                	ld	s0,16(sp)
    8000519a:	64a2                	ld	s1,8(sp)
    8000519c:	6902                	ld	s2,0(sp)
    8000519e:	6105                	addi	sp,sp,32
    800051a0:	8082                	ret
    pi->readopen = 0;
    800051a2:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800051a6:	21c48513          	addi	a0,s1,540
    800051aa:	ffffd097          	auipc	ra,0xffffd
    800051ae:	464080e7          	jalr	1124(ra) # 8000260e <wakeup>
    800051b2:	b7e9                	j	8000517c <pipeclose+0x2c>
    release(&pi->lock);
    800051b4:	8526                	mv	a0,s1
    800051b6:	ffffc097          	auipc	ra,0xffffc
    800051ba:	ae8080e7          	jalr	-1304(ra) # 80000c9e <release>
}
    800051be:	bfe1                	j	80005196 <pipeclose+0x46>

00000000800051c0 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800051c0:	7159                	addi	sp,sp,-112
    800051c2:	f486                	sd	ra,104(sp)
    800051c4:	f0a2                	sd	s0,96(sp)
    800051c6:	eca6                	sd	s1,88(sp)
    800051c8:	e8ca                	sd	s2,80(sp)
    800051ca:	e4ce                	sd	s3,72(sp)
    800051cc:	e0d2                	sd	s4,64(sp)
    800051ce:	fc56                	sd	s5,56(sp)
    800051d0:	f85a                	sd	s6,48(sp)
    800051d2:	f45e                	sd	s7,40(sp)
    800051d4:	f062                	sd	s8,32(sp)
    800051d6:	ec66                	sd	s9,24(sp)
    800051d8:	1880                	addi	s0,sp,112
    800051da:	84aa                	mv	s1,a0
    800051dc:	8aae                	mv	s5,a1
    800051de:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800051e0:	ffffd097          	auipc	ra,0xffffd
    800051e4:	9d4080e7          	jalr	-1580(ra) # 80001bb4 <myproc>
    800051e8:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800051ea:	8526                	mv	a0,s1
    800051ec:	ffffc097          	auipc	ra,0xffffc
    800051f0:	9fe080e7          	jalr	-1538(ra) # 80000bea <acquire>
  while(i < n){
    800051f4:	0d405463          	blez	s4,800052bc <pipewrite+0xfc>
    800051f8:	8ba6                	mv	s7,s1
  int i = 0;
    800051fa:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800051fc:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800051fe:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005202:	21c48c13          	addi	s8,s1,540
    80005206:	a08d                	j	80005268 <pipewrite+0xa8>
      release(&pi->lock);
    80005208:	8526                	mv	a0,s1
    8000520a:	ffffc097          	auipc	ra,0xffffc
    8000520e:	a94080e7          	jalr	-1388(ra) # 80000c9e <release>
      return -1;
    80005212:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005214:	854a                	mv	a0,s2
    80005216:	70a6                	ld	ra,104(sp)
    80005218:	7406                	ld	s0,96(sp)
    8000521a:	64e6                	ld	s1,88(sp)
    8000521c:	6946                	ld	s2,80(sp)
    8000521e:	69a6                	ld	s3,72(sp)
    80005220:	6a06                	ld	s4,64(sp)
    80005222:	7ae2                	ld	s5,56(sp)
    80005224:	7b42                	ld	s6,48(sp)
    80005226:	7ba2                	ld	s7,40(sp)
    80005228:	7c02                	ld	s8,32(sp)
    8000522a:	6ce2                	ld	s9,24(sp)
    8000522c:	6165                	addi	sp,sp,112
    8000522e:	8082                	ret
      wakeup(&pi->nread);
    80005230:	8566                	mv	a0,s9
    80005232:	ffffd097          	auipc	ra,0xffffd
    80005236:	3dc080e7          	jalr	988(ra) # 8000260e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000523a:	85de                	mv	a1,s7
    8000523c:	8562                	mv	a0,s8
    8000523e:	ffffd097          	auipc	ra,0xffffd
    80005242:	220080e7          	jalr	544(ra) # 8000245e <sleep>
    80005246:	a839                	j	80005264 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005248:	21c4a783          	lw	a5,540(s1)
    8000524c:	0017871b          	addiw	a4,a5,1
    80005250:	20e4ae23          	sw	a4,540(s1)
    80005254:	1ff7f793          	andi	a5,a5,511
    80005258:	97a6                	add	a5,a5,s1
    8000525a:	f9f44703          	lbu	a4,-97(s0)
    8000525e:	00e78c23          	sb	a4,24(a5)
      i++;
    80005262:	2905                	addiw	s2,s2,1
  while(i < n){
    80005264:	05495063          	bge	s2,s4,800052a4 <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80005268:	2204a783          	lw	a5,544(s1)
    8000526c:	dfd1                	beqz	a5,80005208 <pipewrite+0x48>
    8000526e:	854e                	mv	a0,s3
    80005270:	ffffd097          	auipc	ra,0xffffd
    80005274:	5ee080e7          	jalr	1518(ra) # 8000285e <killed>
    80005278:	f941                	bnez	a0,80005208 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000527a:	2184a783          	lw	a5,536(s1)
    8000527e:	21c4a703          	lw	a4,540(s1)
    80005282:	2007879b          	addiw	a5,a5,512
    80005286:	faf705e3          	beq	a4,a5,80005230 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000528a:	4685                	li	a3,1
    8000528c:	01590633          	add	a2,s2,s5
    80005290:	f9f40593          	addi	a1,s0,-97
    80005294:	0509b503          	ld	a0,80(s3)
    80005298:	ffffc097          	auipc	ra,0xffffc
    8000529c:	478080e7          	jalr	1144(ra) # 80001710 <copyin>
    800052a0:	fb6514e3          	bne	a0,s6,80005248 <pipewrite+0x88>
  wakeup(&pi->nread);
    800052a4:	21848513          	addi	a0,s1,536
    800052a8:	ffffd097          	auipc	ra,0xffffd
    800052ac:	366080e7          	jalr	870(ra) # 8000260e <wakeup>
  release(&pi->lock);
    800052b0:	8526                	mv	a0,s1
    800052b2:	ffffc097          	auipc	ra,0xffffc
    800052b6:	9ec080e7          	jalr	-1556(ra) # 80000c9e <release>
  return i;
    800052ba:	bfa9                	j	80005214 <pipewrite+0x54>
  int i = 0;
    800052bc:	4901                	li	s2,0
    800052be:	b7dd                	j	800052a4 <pipewrite+0xe4>

00000000800052c0 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800052c0:	715d                	addi	sp,sp,-80
    800052c2:	e486                	sd	ra,72(sp)
    800052c4:	e0a2                	sd	s0,64(sp)
    800052c6:	fc26                	sd	s1,56(sp)
    800052c8:	f84a                	sd	s2,48(sp)
    800052ca:	f44e                	sd	s3,40(sp)
    800052cc:	f052                	sd	s4,32(sp)
    800052ce:	ec56                	sd	s5,24(sp)
    800052d0:	e85a                	sd	s6,16(sp)
    800052d2:	0880                	addi	s0,sp,80
    800052d4:	84aa                	mv	s1,a0
    800052d6:	892e                	mv	s2,a1
    800052d8:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800052da:	ffffd097          	auipc	ra,0xffffd
    800052de:	8da080e7          	jalr	-1830(ra) # 80001bb4 <myproc>
    800052e2:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800052e4:	8b26                	mv	s6,s1
    800052e6:	8526                	mv	a0,s1
    800052e8:	ffffc097          	auipc	ra,0xffffc
    800052ec:	902080e7          	jalr	-1790(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800052f0:	2184a703          	lw	a4,536(s1)
    800052f4:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800052f8:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800052fc:	02f71763          	bne	a4,a5,8000532a <piperead+0x6a>
    80005300:	2244a783          	lw	a5,548(s1)
    80005304:	c39d                	beqz	a5,8000532a <piperead+0x6a>
    if(killed(pr)){
    80005306:	8552                	mv	a0,s4
    80005308:	ffffd097          	auipc	ra,0xffffd
    8000530c:	556080e7          	jalr	1366(ra) # 8000285e <killed>
    80005310:	e941                	bnez	a0,800053a0 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005312:	85da                	mv	a1,s6
    80005314:	854e                	mv	a0,s3
    80005316:	ffffd097          	auipc	ra,0xffffd
    8000531a:	148080e7          	jalr	328(ra) # 8000245e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000531e:	2184a703          	lw	a4,536(s1)
    80005322:	21c4a783          	lw	a5,540(s1)
    80005326:	fcf70de3          	beq	a4,a5,80005300 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000532a:	09505263          	blez	s5,800053ae <piperead+0xee>
    8000532e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005330:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005332:	2184a783          	lw	a5,536(s1)
    80005336:	21c4a703          	lw	a4,540(s1)
    8000533a:	02f70d63          	beq	a4,a5,80005374 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000533e:	0017871b          	addiw	a4,a5,1
    80005342:	20e4ac23          	sw	a4,536(s1)
    80005346:	1ff7f793          	andi	a5,a5,511
    8000534a:	97a6                	add	a5,a5,s1
    8000534c:	0187c783          	lbu	a5,24(a5)
    80005350:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005354:	4685                	li	a3,1
    80005356:	fbf40613          	addi	a2,s0,-65
    8000535a:	85ca                	mv	a1,s2
    8000535c:	050a3503          	ld	a0,80(s4)
    80005360:	ffffc097          	auipc	ra,0xffffc
    80005364:	324080e7          	jalr	804(ra) # 80001684 <copyout>
    80005368:	01650663          	beq	a0,s6,80005374 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000536c:	2985                	addiw	s3,s3,1
    8000536e:	0905                	addi	s2,s2,1
    80005370:	fd3a91e3          	bne	s5,s3,80005332 <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005374:	21c48513          	addi	a0,s1,540
    80005378:	ffffd097          	auipc	ra,0xffffd
    8000537c:	296080e7          	jalr	662(ra) # 8000260e <wakeup>
  release(&pi->lock);
    80005380:	8526                	mv	a0,s1
    80005382:	ffffc097          	auipc	ra,0xffffc
    80005386:	91c080e7          	jalr	-1764(ra) # 80000c9e <release>
  return i;
}
    8000538a:	854e                	mv	a0,s3
    8000538c:	60a6                	ld	ra,72(sp)
    8000538e:	6406                	ld	s0,64(sp)
    80005390:	74e2                	ld	s1,56(sp)
    80005392:	7942                	ld	s2,48(sp)
    80005394:	79a2                	ld	s3,40(sp)
    80005396:	7a02                	ld	s4,32(sp)
    80005398:	6ae2                	ld	s5,24(sp)
    8000539a:	6b42                	ld	s6,16(sp)
    8000539c:	6161                	addi	sp,sp,80
    8000539e:	8082                	ret
      release(&pi->lock);
    800053a0:	8526                	mv	a0,s1
    800053a2:	ffffc097          	auipc	ra,0xffffc
    800053a6:	8fc080e7          	jalr	-1796(ra) # 80000c9e <release>
      return -1;
    800053aa:	59fd                	li	s3,-1
    800053ac:	bff9                	j	8000538a <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800053ae:	4981                	li	s3,0
    800053b0:	b7d1                	j	80005374 <piperead+0xb4>

00000000800053b2 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    800053b2:	1141                	addi	sp,sp,-16
    800053b4:	e422                	sd	s0,8(sp)
    800053b6:	0800                	addi	s0,sp,16
    800053b8:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800053ba:	8905                	andi	a0,a0,1
    800053bc:	c111                	beqz	a0,800053c0 <flags2perm+0xe>
      perm = PTE_X;
    800053be:	4521                	li	a0,8
    if(flags & 0x2)
    800053c0:	8b89                	andi	a5,a5,2
    800053c2:	c399                	beqz	a5,800053c8 <flags2perm+0x16>
      perm |= PTE_W;
    800053c4:	00456513          	ori	a0,a0,4
    return perm;
}
    800053c8:	6422                	ld	s0,8(sp)
    800053ca:	0141                	addi	sp,sp,16
    800053cc:	8082                	ret

00000000800053ce <exec>:

int
exec(char *path, char **argv)
{
    800053ce:	df010113          	addi	sp,sp,-528
    800053d2:	20113423          	sd	ra,520(sp)
    800053d6:	20813023          	sd	s0,512(sp)
    800053da:	ffa6                	sd	s1,504(sp)
    800053dc:	fbca                	sd	s2,496(sp)
    800053de:	f7ce                	sd	s3,488(sp)
    800053e0:	f3d2                	sd	s4,480(sp)
    800053e2:	efd6                	sd	s5,472(sp)
    800053e4:	ebda                	sd	s6,464(sp)
    800053e6:	e7de                	sd	s7,456(sp)
    800053e8:	e3e2                	sd	s8,448(sp)
    800053ea:	ff66                	sd	s9,440(sp)
    800053ec:	fb6a                	sd	s10,432(sp)
    800053ee:	f76e                	sd	s11,424(sp)
    800053f0:	0c00                	addi	s0,sp,528
    800053f2:	84aa                	mv	s1,a0
    800053f4:	dea43c23          	sd	a0,-520(s0)
    800053f8:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800053fc:	ffffc097          	auipc	ra,0xffffc
    80005400:	7b8080e7          	jalr	1976(ra) # 80001bb4 <myproc>
    80005404:	892a                	mv	s2,a0

  begin_op();
    80005406:	fffff097          	auipc	ra,0xfffff
    8000540a:	474080e7          	jalr	1140(ra) # 8000487a <begin_op>

  if((ip = namei(path)) == 0){
    8000540e:	8526                	mv	a0,s1
    80005410:	fffff097          	auipc	ra,0xfffff
    80005414:	24e080e7          	jalr	590(ra) # 8000465e <namei>
    80005418:	c92d                	beqz	a0,8000548a <exec+0xbc>
    8000541a:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000541c:	fffff097          	auipc	ra,0xfffff
    80005420:	a9c080e7          	jalr	-1380(ra) # 80003eb8 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005424:	04000713          	li	a4,64
    80005428:	4681                	li	a3,0
    8000542a:	e5040613          	addi	a2,s0,-432
    8000542e:	4581                	li	a1,0
    80005430:	8526                	mv	a0,s1
    80005432:	fffff097          	auipc	ra,0xfffff
    80005436:	d3a080e7          	jalr	-710(ra) # 8000416c <readi>
    8000543a:	04000793          	li	a5,64
    8000543e:	00f51a63          	bne	a0,a5,80005452 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005442:	e5042703          	lw	a4,-432(s0)
    80005446:	464c47b7          	lui	a5,0x464c4
    8000544a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000544e:	04f70463          	beq	a4,a5,80005496 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005452:	8526                	mv	a0,s1
    80005454:	fffff097          	auipc	ra,0xfffff
    80005458:	cc6080e7          	jalr	-826(ra) # 8000411a <iunlockput>
    end_op();
    8000545c:	fffff097          	auipc	ra,0xfffff
    80005460:	49e080e7          	jalr	1182(ra) # 800048fa <end_op>
  }
  return -1;
    80005464:	557d                	li	a0,-1
}
    80005466:	20813083          	ld	ra,520(sp)
    8000546a:	20013403          	ld	s0,512(sp)
    8000546e:	74fe                	ld	s1,504(sp)
    80005470:	795e                	ld	s2,496(sp)
    80005472:	79be                	ld	s3,488(sp)
    80005474:	7a1e                	ld	s4,480(sp)
    80005476:	6afe                	ld	s5,472(sp)
    80005478:	6b5e                	ld	s6,464(sp)
    8000547a:	6bbe                	ld	s7,456(sp)
    8000547c:	6c1e                	ld	s8,448(sp)
    8000547e:	7cfa                	ld	s9,440(sp)
    80005480:	7d5a                	ld	s10,432(sp)
    80005482:	7dba                	ld	s11,424(sp)
    80005484:	21010113          	addi	sp,sp,528
    80005488:	8082                	ret
    end_op();
    8000548a:	fffff097          	auipc	ra,0xfffff
    8000548e:	470080e7          	jalr	1136(ra) # 800048fa <end_op>
    return -1;
    80005492:	557d                	li	a0,-1
    80005494:	bfc9                	j	80005466 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005496:	854a                	mv	a0,s2
    80005498:	ffffc097          	auipc	ra,0xffffc
    8000549c:	7e0080e7          	jalr	2016(ra) # 80001c78 <proc_pagetable>
    800054a0:	8baa                	mv	s7,a0
    800054a2:	d945                	beqz	a0,80005452 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800054a4:	e7042983          	lw	s3,-400(s0)
    800054a8:	e8845783          	lhu	a5,-376(s0)
    800054ac:	c7ad                	beqz	a5,80005516 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800054ae:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800054b0:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    800054b2:	6c85                	lui	s9,0x1
    800054b4:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800054b8:	def43823          	sd	a5,-528(s0)
    800054bc:	ac0d                	j	800056ee <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800054be:	00003517          	auipc	a0,0x3
    800054c2:	34250513          	addi	a0,a0,834 # 80008800 <syscalls+0x2a8>
    800054c6:	ffffb097          	auipc	ra,0xffffb
    800054ca:	07e080e7          	jalr	126(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800054ce:	8756                	mv	a4,s5
    800054d0:	012d86bb          	addw	a3,s11,s2
    800054d4:	4581                	li	a1,0
    800054d6:	8526                	mv	a0,s1
    800054d8:	fffff097          	auipc	ra,0xfffff
    800054dc:	c94080e7          	jalr	-876(ra) # 8000416c <readi>
    800054e0:	2501                	sext.w	a0,a0
    800054e2:	1aaa9a63          	bne	s5,a0,80005696 <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    800054e6:	6785                	lui	a5,0x1
    800054e8:	0127893b          	addw	s2,a5,s2
    800054ec:	77fd                	lui	a5,0xfffff
    800054ee:	01478a3b          	addw	s4,a5,s4
    800054f2:	1f897563          	bgeu	s2,s8,800056dc <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    800054f6:	02091593          	slli	a1,s2,0x20
    800054fa:	9181                	srli	a1,a1,0x20
    800054fc:	95ea                	add	a1,a1,s10
    800054fe:	855e                	mv	a0,s7
    80005500:	ffffc097          	auipc	ra,0xffffc
    80005504:	b78080e7          	jalr	-1160(ra) # 80001078 <walkaddr>
    80005508:	862a                	mv	a2,a0
    if(pa == 0)
    8000550a:	d955                	beqz	a0,800054be <exec+0xf0>
      n = PGSIZE;
    8000550c:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    8000550e:	fd9a70e3          	bgeu	s4,s9,800054ce <exec+0x100>
      n = sz - i;
    80005512:	8ad2                	mv	s5,s4
    80005514:	bf6d                	j	800054ce <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005516:	4a01                	li	s4,0
  iunlockput(ip);
    80005518:	8526                	mv	a0,s1
    8000551a:	fffff097          	auipc	ra,0xfffff
    8000551e:	c00080e7          	jalr	-1024(ra) # 8000411a <iunlockput>
  end_op();
    80005522:	fffff097          	auipc	ra,0xfffff
    80005526:	3d8080e7          	jalr	984(ra) # 800048fa <end_op>
  p = myproc();
    8000552a:	ffffc097          	auipc	ra,0xffffc
    8000552e:	68a080e7          	jalr	1674(ra) # 80001bb4 <myproc>
    80005532:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005534:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005538:	6785                	lui	a5,0x1
    8000553a:	17fd                	addi	a5,a5,-1
    8000553c:	9a3e                	add	s4,s4,a5
    8000553e:	757d                	lui	a0,0xfffff
    80005540:	00aa77b3          	and	a5,s4,a0
    80005544:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005548:	4691                	li	a3,4
    8000554a:	6609                	lui	a2,0x2
    8000554c:	963e                	add	a2,a2,a5
    8000554e:	85be                	mv	a1,a5
    80005550:	855e                	mv	a0,s7
    80005552:	ffffc097          	auipc	ra,0xffffc
    80005556:	eda080e7          	jalr	-294(ra) # 8000142c <uvmalloc>
    8000555a:	8b2a                	mv	s6,a0
  ip = 0;
    8000555c:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000555e:	12050c63          	beqz	a0,80005696 <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005562:	75f9                	lui	a1,0xffffe
    80005564:	95aa                	add	a1,a1,a0
    80005566:	855e                	mv	a0,s7
    80005568:	ffffc097          	auipc	ra,0xffffc
    8000556c:	0ea080e7          	jalr	234(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    80005570:	7c7d                	lui	s8,0xfffff
    80005572:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005574:	e0043783          	ld	a5,-512(s0)
    80005578:	6388                	ld	a0,0(a5)
    8000557a:	c535                	beqz	a0,800055e6 <exec+0x218>
    8000557c:	e9040993          	addi	s3,s0,-368
    80005580:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005584:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005586:	ffffc097          	auipc	ra,0xffffc
    8000558a:	8e4080e7          	jalr	-1820(ra) # 80000e6a <strlen>
    8000558e:	2505                	addiw	a0,a0,1
    80005590:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005594:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005598:	13896663          	bltu	s2,s8,800056c4 <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000559c:	e0043d83          	ld	s11,-512(s0)
    800055a0:	000dba03          	ld	s4,0(s11)
    800055a4:	8552                	mv	a0,s4
    800055a6:	ffffc097          	auipc	ra,0xffffc
    800055aa:	8c4080e7          	jalr	-1852(ra) # 80000e6a <strlen>
    800055ae:	0015069b          	addiw	a3,a0,1
    800055b2:	8652                	mv	a2,s4
    800055b4:	85ca                	mv	a1,s2
    800055b6:	855e                	mv	a0,s7
    800055b8:	ffffc097          	auipc	ra,0xffffc
    800055bc:	0cc080e7          	jalr	204(ra) # 80001684 <copyout>
    800055c0:	10054663          	bltz	a0,800056cc <exec+0x2fe>
    ustack[argc] = sp;
    800055c4:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800055c8:	0485                	addi	s1,s1,1
    800055ca:	008d8793          	addi	a5,s11,8
    800055ce:	e0f43023          	sd	a5,-512(s0)
    800055d2:	008db503          	ld	a0,8(s11)
    800055d6:	c911                	beqz	a0,800055ea <exec+0x21c>
    if(argc >= MAXARG)
    800055d8:	09a1                	addi	s3,s3,8
    800055da:	fb3c96e3          	bne	s9,s3,80005586 <exec+0x1b8>
  sz = sz1;
    800055de:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055e2:	4481                	li	s1,0
    800055e4:	a84d                	j	80005696 <exec+0x2c8>
  sp = sz;
    800055e6:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800055e8:	4481                	li	s1,0
  ustack[argc] = 0;
    800055ea:	00349793          	slli	a5,s1,0x3
    800055ee:	f9040713          	addi	a4,s0,-112
    800055f2:	97ba                	add	a5,a5,a4
    800055f4:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800055f8:	00148693          	addi	a3,s1,1
    800055fc:	068e                	slli	a3,a3,0x3
    800055fe:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005602:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005606:	01897663          	bgeu	s2,s8,80005612 <exec+0x244>
  sz = sz1;
    8000560a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000560e:	4481                	li	s1,0
    80005610:	a059                	j	80005696 <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005612:	e9040613          	addi	a2,s0,-368
    80005616:	85ca                	mv	a1,s2
    80005618:	855e                	mv	a0,s7
    8000561a:	ffffc097          	auipc	ra,0xffffc
    8000561e:	06a080e7          	jalr	106(ra) # 80001684 <copyout>
    80005622:	0a054963          	bltz	a0,800056d4 <exec+0x306>
  p->trapframe->a1 = sp;
    80005626:	058ab783          	ld	a5,88(s5)
    8000562a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000562e:	df843783          	ld	a5,-520(s0)
    80005632:	0007c703          	lbu	a4,0(a5)
    80005636:	cf11                	beqz	a4,80005652 <exec+0x284>
    80005638:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000563a:	02f00693          	li	a3,47
    8000563e:	a039                	j	8000564c <exec+0x27e>
      last = s+1;
    80005640:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005644:	0785                	addi	a5,a5,1
    80005646:	fff7c703          	lbu	a4,-1(a5)
    8000564a:	c701                	beqz	a4,80005652 <exec+0x284>
    if(*s == '/')
    8000564c:	fed71ce3          	bne	a4,a3,80005644 <exec+0x276>
    80005650:	bfc5                	j	80005640 <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80005652:	4641                	li	a2,16
    80005654:	df843583          	ld	a1,-520(s0)
    80005658:	158a8513          	addi	a0,s5,344
    8000565c:	ffffb097          	auipc	ra,0xffffb
    80005660:	7dc080e7          	jalr	2012(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    80005664:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005668:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    8000566c:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005670:	058ab783          	ld	a5,88(s5)
    80005674:	e6843703          	ld	a4,-408(s0)
    80005678:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000567a:	058ab783          	ld	a5,88(s5)
    8000567e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005682:	85ea                	mv	a1,s10
    80005684:	ffffc097          	auipc	ra,0xffffc
    80005688:	690080e7          	jalr	1680(ra) # 80001d14 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000568c:	0004851b          	sext.w	a0,s1
    80005690:	bbd9                	j	80005466 <exec+0x98>
    80005692:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005696:	e0843583          	ld	a1,-504(s0)
    8000569a:	855e                	mv	a0,s7
    8000569c:	ffffc097          	auipc	ra,0xffffc
    800056a0:	678080e7          	jalr	1656(ra) # 80001d14 <proc_freepagetable>
  if(ip){
    800056a4:	da0497e3          	bnez	s1,80005452 <exec+0x84>
  return -1;
    800056a8:	557d                	li	a0,-1
    800056aa:	bb75                	j	80005466 <exec+0x98>
    800056ac:	e1443423          	sd	s4,-504(s0)
    800056b0:	b7dd                	j	80005696 <exec+0x2c8>
    800056b2:	e1443423          	sd	s4,-504(s0)
    800056b6:	b7c5                	j	80005696 <exec+0x2c8>
    800056b8:	e1443423          	sd	s4,-504(s0)
    800056bc:	bfe9                	j	80005696 <exec+0x2c8>
    800056be:	e1443423          	sd	s4,-504(s0)
    800056c2:	bfd1                	j	80005696 <exec+0x2c8>
  sz = sz1;
    800056c4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800056c8:	4481                	li	s1,0
    800056ca:	b7f1                	j	80005696 <exec+0x2c8>
  sz = sz1;
    800056cc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800056d0:	4481                	li	s1,0
    800056d2:	b7d1                	j	80005696 <exec+0x2c8>
  sz = sz1;
    800056d4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800056d8:	4481                	li	s1,0
    800056da:	bf75                	j	80005696 <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800056dc:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800056e0:	2b05                	addiw	s6,s6,1
    800056e2:	0389899b          	addiw	s3,s3,56
    800056e6:	e8845783          	lhu	a5,-376(s0)
    800056ea:	e2fb57e3          	bge	s6,a5,80005518 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800056ee:	2981                	sext.w	s3,s3
    800056f0:	03800713          	li	a4,56
    800056f4:	86ce                	mv	a3,s3
    800056f6:	e1840613          	addi	a2,s0,-488
    800056fa:	4581                	li	a1,0
    800056fc:	8526                	mv	a0,s1
    800056fe:	fffff097          	auipc	ra,0xfffff
    80005702:	a6e080e7          	jalr	-1426(ra) # 8000416c <readi>
    80005706:	03800793          	li	a5,56
    8000570a:	f8f514e3          	bne	a0,a5,80005692 <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    8000570e:	e1842783          	lw	a5,-488(s0)
    80005712:	4705                	li	a4,1
    80005714:	fce796e3          	bne	a5,a4,800056e0 <exec+0x312>
    if(ph.memsz < ph.filesz)
    80005718:	e4043903          	ld	s2,-448(s0)
    8000571c:	e3843783          	ld	a5,-456(s0)
    80005720:	f8f966e3          	bltu	s2,a5,800056ac <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005724:	e2843783          	ld	a5,-472(s0)
    80005728:	993e                	add	s2,s2,a5
    8000572a:	f8f964e3          	bltu	s2,a5,800056b2 <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    8000572e:	df043703          	ld	a4,-528(s0)
    80005732:	8ff9                	and	a5,a5,a4
    80005734:	f3d1                	bnez	a5,800056b8 <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005736:	e1c42503          	lw	a0,-484(s0)
    8000573a:	00000097          	auipc	ra,0x0
    8000573e:	c78080e7          	jalr	-904(ra) # 800053b2 <flags2perm>
    80005742:	86aa                	mv	a3,a0
    80005744:	864a                	mv	a2,s2
    80005746:	85d2                	mv	a1,s4
    80005748:	855e                	mv	a0,s7
    8000574a:	ffffc097          	auipc	ra,0xffffc
    8000574e:	ce2080e7          	jalr	-798(ra) # 8000142c <uvmalloc>
    80005752:	e0a43423          	sd	a0,-504(s0)
    80005756:	d525                	beqz	a0,800056be <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005758:	e2843d03          	ld	s10,-472(s0)
    8000575c:	e2042d83          	lw	s11,-480(s0)
    80005760:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005764:	f60c0ce3          	beqz	s8,800056dc <exec+0x30e>
    80005768:	8a62                	mv	s4,s8
    8000576a:	4901                	li	s2,0
    8000576c:	b369                	j	800054f6 <exec+0x128>

000000008000576e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000576e:	7179                	addi	sp,sp,-48
    80005770:	f406                	sd	ra,40(sp)
    80005772:	f022                	sd	s0,32(sp)
    80005774:	ec26                	sd	s1,24(sp)
    80005776:	e84a                	sd	s2,16(sp)
    80005778:	1800                	addi	s0,sp,48
    8000577a:	892e                	mv	s2,a1
    8000577c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000577e:	fdc40593          	addi	a1,s0,-36
    80005782:	ffffe097          	auipc	ra,0xffffe
    80005786:	9fc080e7          	jalr	-1540(ra) # 8000317e <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000578a:	fdc42703          	lw	a4,-36(s0)
    8000578e:	47bd                	li	a5,15
    80005790:	02e7eb63          	bltu	a5,a4,800057c6 <argfd+0x58>
    80005794:	ffffc097          	auipc	ra,0xffffc
    80005798:	420080e7          	jalr	1056(ra) # 80001bb4 <myproc>
    8000579c:	fdc42703          	lw	a4,-36(s0)
    800057a0:	01a70793          	addi	a5,a4,26
    800057a4:	078e                	slli	a5,a5,0x3
    800057a6:	953e                	add	a0,a0,a5
    800057a8:	611c                	ld	a5,0(a0)
    800057aa:	c385                	beqz	a5,800057ca <argfd+0x5c>
    return -1;
  if(pfd)
    800057ac:	00090463          	beqz	s2,800057b4 <argfd+0x46>
    *pfd = fd;
    800057b0:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800057b4:	4501                	li	a0,0
  if(pf)
    800057b6:	c091                	beqz	s1,800057ba <argfd+0x4c>
    *pf = f;
    800057b8:	e09c                	sd	a5,0(s1)
}
    800057ba:	70a2                	ld	ra,40(sp)
    800057bc:	7402                	ld	s0,32(sp)
    800057be:	64e2                	ld	s1,24(sp)
    800057c0:	6942                	ld	s2,16(sp)
    800057c2:	6145                	addi	sp,sp,48
    800057c4:	8082                	ret
    return -1;
    800057c6:	557d                	li	a0,-1
    800057c8:	bfcd                	j	800057ba <argfd+0x4c>
    800057ca:	557d                	li	a0,-1
    800057cc:	b7fd                	j	800057ba <argfd+0x4c>

00000000800057ce <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800057ce:	1101                	addi	sp,sp,-32
    800057d0:	ec06                	sd	ra,24(sp)
    800057d2:	e822                	sd	s0,16(sp)
    800057d4:	e426                	sd	s1,8(sp)
    800057d6:	1000                	addi	s0,sp,32
    800057d8:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800057da:	ffffc097          	auipc	ra,0xffffc
    800057de:	3da080e7          	jalr	986(ra) # 80001bb4 <myproc>
    800057e2:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800057e4:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffda158>
    800057e8:	4501                	li	a0,0
    800057ea:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800057ec:	6398                	ld	a4,0(a5)
    800057ee:	cb19                	beqz	a4,80005804 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800057f0:	2505                	addiw	a0,a0,1
    800057f2:	07a1                	addi	a5,a5,8
    800057f4:	fed51ce3          	bne	a0,a3,800057ec <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800057f8:	557d                	li	a0,-1
}
    800057fa:	60e2                	ld	ra,24(sp)
    800057fc:	6442                	ld	s0,16(sp)
    800057fe:	64a2                	ld	s1,8(sp)
    80005800:	6105                	addi	sp,sp,32
    80005802:	8082                	ret
      p->ofile[fd] = f;
    80005804:	01a50793          	addi	a5,a0,26
    80005808:	078e                	slli	a5,a5,0x3
    8000580a:	963e                	add	a2,a2,a5
    8000580c:	e204                	sd	s1,0(a2)
      return fd;
    8000580e:	b7f5                	j	800057fa <fdalloc+0x2c>

0000000080005810 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005810:	715d                	addi	sp,sp,-80
    80005812:	e486                	sd	ra,72(sp)
    80005814:	e0a2                	sd	s0,64(sp)
    80005816:	fc26                	sd	s1,56(sp)
    80005818:	f84a                	sd	s2,48(sp)
    8000581a:	f44e                	sd	s3,40(sp)
    8000581c:	f052                	sd	s4,32(sp)
    8000581e:	ec56                	sd	s5,24(sp)
    80005820:	e85a                	sd	s6,16(sp)
    80005822:	0880                	addi	s0,sp,80
    80005824:	8b2e                	mv	s6,a1
    80005826:	89b2                	mv	s3,a2
    80005828:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000582a:	fb040593          	addi	a1,s0,-80
    8000582e:	fffff097          	auipc	ra,0xfffff
    80005832:	e4e080e7          	jalr	-434(ra) # 8000467c <nameiparent>
    80005836:	84aa                	mv	s1,a0
    80005838:	16050063          	beqz	a0,80005998 <create+0x188>
    return 0;

  ilock(dp);
    8000583c:	ffffe097          	auipc	ra,0xffffe
    80005840:	67c080e7          	jalr	1660(ra) # 80003eb8 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005844:	4601                	li	a2,0
    80005846:	fb040593          	addi	a1,s0,-80
    8000584a:	8526                	mv	a0,s1
    8000584c:	fffff097          	auipc	ra,0xfffff
    80005850:	b50080e7          	jalr	-1200(ra) # 8000439c <dirlookup>
    80005854:	8aaa                	mv	s5,a0
    80005856:	c931                	beqz	a0,800058aa <create+0x9a>
    iunlockput(dp);
    80005858:	8526                	mv	a0,s1
    8000585a:	fffff097          	auipc	ra,0xfffff
    8000585e:	8c0080e7          	jalr	-1856(ra) # 8000411a <iunlockput>
    ilock(ip);
    80005862:	8556                	mv	a0,s5
    80005864:	ffffe097          	auipc	ra,0xffffe
    80005868:	654080e7          	jalr	1620(ra) # 80003eb8 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000586c:	000b059b          	sext.w	a1,s6
    80005870:	4789                	li	a5,2
    80005872:	02f59563          	bne	a1,a5,8000589c <create+0x8c>
    80005876:	044ad783          	lhu	a5,68(s5)
    8000587a:	37f9                	addiw	a5,a5,-2
    8000587c:	17c2                	slli	a5,a5,0x30
    8000587e:	93c1                	srli	a5,a5,0x30
    80005880:	4705                	li	a4,1
    80005882:	00f76d63          	bltu	a4,a5,8000589c <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005886:	8556                	mv	a0,s5
    80005888:	60a6                	ld	ra,72(sp)
    8000588a:	6406                	ld	s0,64(sp)
    8000588c:	74e2                	ld	s1,56(sp)
    8000588e:	7942                	ld	s2,48(sp)
    80005890:	79a2                	ld	s3,40(sp)
    80005892:	7a02                	ld	s4,32(sp)
    80005894:	6ae2                	ld	s5,24(sp)
    80005896:	6b42                	ld	s6,16(sp)
    80005898:	6161                	addi	sp,sp,80
    8000589a:	8082                	ret
    iunlockput(ip);
    8000589c:	8556                	mv	a0,s5
    8000589e:	fffff097          	auipc	ra,0xfffff
    800058a2:	87c080e7          	jalr	-1924(ra) # 8000411a <iunlockput>
    return 0;
    800058a6:	4a81                	li	s5,0
    800058a8:	bff9                	j	80005886 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800058aa:	85da                	mv	a1,s6
    800058ac:	4088                	lw	a0,0(s1)
    800058ae:	ffffe097          	auipc	ra,0xffffe
    800058b2:	46e080e7          	jalr	1134(ra) # 80003d1c <ialloc>
    800058b6:	8a2a                	mv	s4,a0
    800058b8:	c921                	beqz	a0,80005908 <create+0xf8>
  ilock(ip);
    800058ba:	ffffe097          	auipc	ra,0xffffe
    800058be:	5fe080e7          	jalr	1534(ra) # 80003eb8 <ilock>
  ip->major = major;
    800058c2:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800058c6:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800058ca:	4785                	li	a5,1
    800058cc:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    800058d0:	8552                	mv	a0,s4
    800058d2:	ffffe097          	auipc	ra,0xffffe
    800058d6:	51c080e7          	jalr	1308(ra) # 80003dee <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800058da:	000b059b          	sext.w	a1,s6
    800058de:	4785                	li	a5,1
    800058e0:	02f58b63          	beq	a1,a5,80005916 <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    800058e4:	004a2603          	lw	a2,4(s4)
    800058e8:	fb040593          	addi	a1,s0,-80
    800058ec:	8526                	mv	a0,s1
    800058ee:	fffff097          	auipc	ra,0xfffff
    800058f2:	cbe080e7          	jalr	-834(ra) # 800045ac <dirlink>
    800058f6:	06054f63          	bltz	a0,80005974 <create+0x164>
  iunlockput(dp);
    800058fa:	8526                	mv	a0,s1
    800058fc:	fffff097          	auipc	ra,0xfffff
    80005900:	81e080e7          	jalr	-2018(ra) # 8000411a <iunlockput>
  return ip;
    80005904:	8ad2                	mv	s5,s4
    80005906:	b741                	j	80005886 <create+0x76>
    iunlockput(dp);
    80005908:	8526                	mv	a0,s1
    8000590a:	fffff097          	auipc	ra,0xfffff
    8000590e:	810080e7          	jalr	-2032(ra) # 8000411a <iunlockput>
    return 0;
    80005912:	8ad2                	mv	s5,s4
    80005914:	bf8d                	j	80005886 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005916:	004a2603          	lw	a2,4(s4)
    8000591a:	00003597          	auipc	a1,0x3
    8000591e:	f0658593          	addi	a1,a1,-250 # 80008820 <syscalls+0x2c8>
    80005922:	8552                	mv	a0,s4
    80005924:	fffff097          	auipc	ra,0xfffff
    80005928:	c88080e7          	jalr	-888(ra) # 800045ac <dirlink>
    8000592c:	04054463          	bltz	a0,80005974 <create+0x164>
    80005930:	40d0                	lw	a2,4(s1)
    80005932:	00003597          	auipc	a1,0x3
    80005936:	ef658593          	addi	a1,a1,-266 # 80008828 <syscalls+0x2d0>
    8000593a:	8552                	mv	a0,s4
    8000593c:	fffff097          	auipc	ra,0xfffff
    80005940:	c70080e7          	jalr	-912(ra) # 800045ac <dirlink>
    80005944:	02054863          	bltz	a0,80005974 <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    80005948:	004a2603          	lw	a2,4(s4)
    8000594c:	fb040593          	addi	a1,s0,-80
    80005950:	8526                	mv	a0,s1
    80005952:	fffff097          	auipc	ra,0xfffff
    80005956:	c5a080e7          	jalr	-934(ra) # 800045ac <dirlink>
    8000595a:	00054d63          	bltz	a0,80005974 <create+0x164>
    dp->nlink++;  // for ".."
    8000595e:	04a4d783          	lhu	a5,74(s1)
    80005962:	2785                	addiw	a5,a5,1
    80005964:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005968:	8526                	mv	a0,s1
    8000596a:	ffffe097          	auipc	ra,0xffffe
    8000596e:	484080e7          	jalr	1156(ra) # 80003dee <iupdate>
    80005972:	b761                	j	800058fa <create+0xea>
  ip->nlink = 0;
    80005974:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005978:	8552                	mv	a0,s4
    8000597a:	ffffe097          	auipc	ra,0xffffe
    8000597e:	474080e7          	jalr	1140(ra) # 80003dee <iupdate>
  iunlockput(ip);
    80005982:	8552                	mv	a0,s4
    80005984:	ffffe097          	auipc	ra,0xffffe
    80005988:	796080e7          	jalr	1942(ra) # 8000411a <iunlockput>
  iunlockput(dp);
    8000598c:	8526                	mv	a0,s1
    8000598e:	ffffe097          	auipc	ra,0xffffe
    80005992:	78c080e7          	jalr	1932(ra) # 8000411a <iunlockput>
  return 0;
    80005996:	bdc5                	j	80005886 <create+0x76>
    return 0;
    80005998:	8aaa                	mv	s5,a0
    8000599a:	b5f5                	j	80005886 <create+0x76>

000000008000599c <sys_dup>:
{
    8000599c:	7179                	addi	sp,sp,-48
    8000599e:	f406                	sd	ra,40(sp)
    800059a0:	f022                	sd	s0,32(sp)
    800059a2:	ec26                	sd	s1,24(sp)
    800059a4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800059a6:	fd840613          	addi	a2,s0,-40
    800059aa:	4581                	li	a1,0
    800059ac:	4501                	li	a0,0
    800059ae:	00000097          	auipc	ra,0x0
    800059b2:	dc0080e7          	jalr	-576(ra) # 8000576e <argfd>
    return -1;
    800059b6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800059b8:	02054363          	bltz	a0,800059de <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800059bc:	fd843503          	ld	a0,-40(s0)
    800059c0:	00000097          	auipc	ra,0x0
    800059c4:	e0e080e7          	jalr	-498(ra) # 800057ce <fdalloc>
    800059c8:	84aa                	mv	s1,a0
    return -1;
    800059ca:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800059cc:	00054963          	bltz	a0,800059de <sys_dup+0x42>
  filedup(f);
    800059d0:	fd843503          	ld	a0,-40(s0)
    800059d4:	fffff097          	auipc	ra,0xfffff
    800059d8:	320080e7          	jalr	800(ra) # 80004cf4 <filedup>
  return fd;
    800059dc:	87a6                	mv	a5,s1
}
    800059de:	853e                	mv	a0,a5
    800059e0:	70a2                	ld	ra,40(sp)
    800059e2:	7402                	ld	s0,32(sp)
    800059e4:	64e2                	ld	s1,24(sp)
    800059e6:	6145                	addi	sp,sp,48
    800059e8:	8082                	ret

00000000800059ea <sys_read>:
{
    800059ea:	7179                	addi	sp,sp,-48
    800059ec:	f406                	sd	ra,40(sp)
    800059ee:	f022                	sd	s0,32(sp)
    800059f0:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800059f2:	fd840593          	addi	a1,s0,-40
    800059f6:	4505                	li	a0,1
    800059f8:	ffffd097          	auipc	ra,0xffffd
    800059fc:	7a6080e7          	jalr	1958(ra) # 8000319e <argaddr>
  argint(2, &n);
    80005a00:	fe440593          	addi	a1,s0,-28
    80005a04:	4509                	li	a0,2
    80005a06:	ffffd097          	auipc	ra,0xffffd
    80005a0a:	778080e7          	jalr	1912(ra) # 8000317e <argint>
  if(argfd(0, 0, &f) < 0)
    80005a0e:	fe840613          	addi	a2,s0,-24
    80005a12:	4581                	li	a1,0
    80005a14:	4501                	li	a0,0
    80005a16:	00000097          	auipc	ra,0x0
    80005a1a:	d58080e7          	jalr	-680(ra) # 8000576e <argfd>
    80005a1e:	87aa                	mv	a5,a0
    return -1;
    80005a20:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005a22:	0007cc63          	bltz	a5,80005a3a <sys_read+0x50>
  return fileread(f, p, n);
    80005a26:	fe442603          	lw	a2,-28(s0)
    80005a2a:	fd843583          	ld	a1,-40(s0)
    80005a2e:	fe843503          	ld	a0,-24(s0)
    80005a32:	fffff097          	auipc	ra,0xfffff
    80005a36:	44e080e7          	jalr	1102(ra) # 80004e80 <fileread>
}
    80005a3a:	70a2                	ld	ra,40(sp)
    80005a3c:	7402                	ld	s0,32(sp)
    80005a3e:	6145                	addi	sp,sp,48
    80005a40:	8082                	ret

0000000080005a42 <sys_write>:
{
    80005a42:	7179                	addi	sp,sp,-48
    80005a44:	f406                	sd	ra,40(sp)
    80005a46:	f022                	sd	s0,32(sp)
    80005a48:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005a4a:	fd840593          	addi	a1,s0,-40
    80005a4e:	4505                	li	a0,1
    80005a50:	ffffd097          	auipc	ra,0xffffd
    80005a54:	74e080e7          	jalr	1870(ra) # 8000319e <argaddr>
  argint(2, &n);
    80005a58:	fe440593          	addi	a1,s0,-28
    80005a5c:	4509                	li	a0,2
    80005a5e:	ffffd097          	auipc	ra,0xffffd
    80005a62:	720080e7          	jalr	1824(ra) # 8000317e <argint>
  if(argfd(0, 0, &f) < 0)
    80005a66:	fe840613          	addi	a2,s0,-24
    80005a6a:	4581                	li	a1,0
    80005a6c:	4501                	li	a0,0
    80005a6e:	00000097          	auipc	ra,0x0
    80005a72:	d00080e7          	jalr	-768(ra) # 8000576e <argfd>
    80005a76:	87aa                	mv	a5,a0
    return -1;
    80005a78:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005a7a:	0007cc63          	bltz	a5,80005a92 <sys_write+0x50>
  return filewrite(f, p, n);
    80005a7e:	fe442603          	lw	a2,-28(s0)
    80005a82:	fd843583          	ld	a1,-40(s0)
    80005a86:	fe843503          	ld	a0,-24(s0)
    80005a8a:	fffff097          	auipc	ra,0xfffff
    80005a8e:	4b8080e7          	jalr	1208(ra) # 80004f42 <filewrite>
}
    80005a92:	70a2                	ld	ra,40(sp)
    80005a94:	7402                	ld	s0,32(sp)
    80005a96:	6145                	addi	sp,sp,48
    80005a98:	8082                	ret

0000000080005a9a <sys_close>:
{
    80005a9a:	1101                	addi	sp,sp,-32
    80005a9c:	ec06                	sd	ra,24(sp)
    80005a9e:	e822                	sd	s0,16(sp)
    80005aa0:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005aa2:	fe040613          	addi	a2,s0,-32
    80005aa6:	fec40593          	addi	a1,s0,-20
    80005aaa:	4501                	li	a0,0
    80005aac:	00000097          	auipc	ra,0x0
    80005ab0:	cc2080e7          	jalr	-830(ra) # 8000576e <argfd>
    return -1;
    80005ab4:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005ab6:	02054463          	bltz	a0,80005ade <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005aba:	ffffc097          	auipc	ra,0xffffc
    80005abe:	0fa080e7          	jalr	250(ra) # 80001bb4 <myproc>
    80005ac2:	fec42783          	lw	a5,-20(s0)
    80005ac6:	07e9                	addi	a5,a5,26
    80005ac8:	078e                	slli	a5,a5,0x3
    80005aca:	97aa                	add	a5,a5,a0
    80005acc:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005ad0:	fe043503          	ld	a0,-32(s0)
    80005ad4:	fffff097          	auipc	ra,0xfffff
    80005ad8:	272080e7          	jalr	626(ra) # 80004d46 <fileclose>
  return 0;
    80005adc:	4781                	li	a5,0
}
    80005ade:	853e                	mv	a0,a5
    80005ae0:	60e2                	ld	ra,24(sp)
    80005ae2:	6442                	ld	s0,16(sp)
    80005ae4:	6105                	addi	sp,sp,32
    80005ae6:	8082                	ret

0000000080005ae8 <sys_fstat>:
{
    80005ae8:	1101                	addi	sp,sp,-32
    80005aea:	ec06                	sd	ra,24(sp)
    80005aec:	e822                	sd	s0,16(sp)
    80005aee:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005af0:	fe040593          	addi	a1,s0,-32
    80005af4:	4505                	li	a0,1
    80005af6:	ffffd097          	auipc	ra,0xffffd
    80005afa:	6a8080e7          	jalr	1704(ra) # 8000319e <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005afe:	fe840613          	addi	a2,s0,-24
    80005b02:	4581                	li	a1,0
    80005b04:	4501                	li	a0,0
    80005b06:	00000097          	auipc	ra,0x0
    80005b0a:	c68080e7          	jalr	-920(ra) # 8000576e <argfd>
    80005b0e:	87aa                	mv	a5,a0
    return -1;
    80005b10:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005b12:	0007ca63          	bltz	a5,80005b26 <sys_fstat+0x3e>
  return filestat(f, st);
    80005b16:	fe043583          	ld	a1,-32(s0)
    80005b1a:	fe843503          	ld	a0,-24(s0)
    80005b1e:	fffff097          	auipc	ra,0xfffff
    80005b22:	2f0080e7          	jalr	752(ra) # 80004e0e <filestat>
}
    80005b26:	60e2                	ld	ra,24(sp)
    80005b28:	6442                	ld	s0,16(sp)
    80005b2a:	6105                	addi	sp,sp,32
    80005b2c:	8082                	ret

0000000080005b2e <sys_link>:
{
    80005b2e:	7169                	addi	sp,sp,-304
    80005b30:	f606                	sd	ra,296(sp)
    80005b32:	f222                	sd	s0,288(sp)
    80005b34:	ee26                	sd	s1,280(sp)
    80005b36:	ea4a                	sd	s2,272(sp)
    80005b38:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b3a:	08000613          	li	a2,128
    80005b3e:	ed040593          	addi	a1,s0,-304
    80005b42:	4501                	li	a0,0
    80005b44:	ffffd097          	auipc	ra,0xffffd
    80005b48:	67a080e7          	jalr	1658(ra) # 800031be <argstr>
    return -1;
    80005b4c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b4e:	10054e63          	bltz	a0,80005c6a <sys_link+0x13c>
    80005b52:	08000613          	li	a2,128
    80005b56:	f5040593          	addi	a1,s0,-176
    80005b5a:	4505                	li	a0,1
    80005b5c:	ffffd097          	auipc	ra,0xffffd
    80005b60:	662080e7          	jalr	1634(ra) # 800031be <argstr>
    return -1;
    80005b64:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b66:	10054263          	bltz	a0,80005c6a <sys_link+0x13c>
  begin_op();
    80005b6a:	fffff097          	auipc	ra,0xfffff
    80005b6e:	d10080e7          	jalr	-752(ra) # 8000487a <begin_op>
  if((ip = namei(old)) == 0){
    80005b72:	ed040513          	addi	a0,s0,-304
    80005b76:	fffff097          	auipc	ra,0xfffff
    80005b7a:	ae8080e7          	jalr	-1304(ra) # 8000465e <namei>
    80005b7e:	84aa                	mv	s1,a0
    80005b80:	c551                	beqz	a0,80005c0c <sys_link+0xde>
  ilock(ip);
    80005b82:	ffffe097          	auipc	ra,0xffffe
    80005b86:	336080e7          	jalr	822(ra) # 80003eb8 <ilock>
  if(ip->type == T_DIR){
    80005b8a:	04449703          	lh	a4,68(s1)
    80005b8e:	4785                	li	a5,1
    80005b90:	08f70463          	beq	a4,a5,80005c18 <sys_link+0xea>
  ip->nlink++;
    80005b94:	04a4d783          	lhu	a5,74(s1)
    80005b98:	2785                	addiw	a5,a5,1
    80005b9a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b9e:	8526                	mv	a0,s1
    80005ba0:	ffffe097          	auipc	ra,0xffffe
    80005ba4:	24e080e7          	jalr	590(ra) # 80003dee <iupdate>
  iunlock(ip);
    80005ba8:	8526                	mv	a0,s1
    80005baa:	ffffe097          	auipc	ra,0xffffe
    80005bae:	3d0080e7          	jalr	976(ra) # 80003f7a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005bb2:	fd040593          	addi	a1,s0,-48
    80005bb6:	f5040513          	addi	a0,s0,-176
    80005bba:	fffff097          	auipc	ra,0xfffff
    80005bbe:	ac2080e7          	jalr	-1342(ra) # 8000467c <nameiparent>
    80005bc2:	892a                	mv	s2,a0
    80005bc4:	c935                	beqz	a0,80005c38 <sys_link+0x10a>
  ilock(dp);
    80005bc6:	ffffe097          	auipc	ra,0xffffe
    80005bca:	2f2080e7          	jalr	754(ra) # 80003eb8 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005bce:	00092703          	lw	a4,0(s2)
    80005bd2:	409c                	lw	a5,0(s1)
    80005bd4:	04f71d63          	bne	a4,a5,80005c2e <sys_link+0x100>
    80005bd8:	40d0                	lw	a2,4(s1)
    80005bda:	fd040593          	addi	a1,s0,-48
    80005bde:	854a                	mv	a0,s2
    80005be0:	fffff097          	auipc	ra,0xfffff
    80005be4:	9cc080e7          	jalr	-1588(ra) # 800045ac <dirlink>
    80005be8:	04054363          	bltz	a0,80005c2e <sys_link+0x100>
  iunlockput(dp);
    80005bec:	854a                	mv	a0,s2
    80005bee:	ffffe097          	auipc	ra,0xffffe
    80005bf2:	52c080e7          	jalr	1324(ra) # 8000411a <iunlockput>
  iput(ip);
    80005bf6:	8526                	mv	a0,s1
    80005bf8:	ffffe097          	auipc	ra,0xffffe
    80005bfc:	47a080e7          	jalr	1146(ra) # 80004072 <iput>
  end_op();
    80005c00:	fffff097          	auipc	ra,0xfffff
    80005c04:	cfa080e7          	jalr	-774(ra) # 800048fa <end_op>
  return 0;
    80005c08:	4781                	li	a5,0
    80005c0a:	a085                	j	80005c6a <sys_link+0x13c>
    end_op();
    80005c0c:	fffff097          	auipc	ra,0xfffff
    80005c10:	cee080e7          	jalr	-786(ra) # 800048fa <end_op>
    return -1;
    80005c14:	57fd                	li	a5,-1
    80005c16:	a891                	j	80005c6a <sys_link+0x13c>
    iunlockput(ip);
    80005c18:	8526                	mv	a0,s1
    80005c1a:	ffffe097          	auipc	ra,0xffffe
    80005c1e:	500080e7          	jalr	1280(ra) # 8000411a <iunlockput>
    end_op();
    80005c22:	fffff097          	auipc	ra,0xfffff
    80005c26:	cd8080e7          	jalr	-808(ra) # 800048fa <end_op>
    return -1;
    80005c2a:	57fd                	li	a5,-1
    80005c2c:	a83d                	j	80005c6a <sys_link+0x13c>
    iunlockput(dp);
    80005c2e:	854a                	mv	a0,s2
    80005c30:	ffffe097          	auipc	ra,0xffffe
    80005c34:	4ea080e7          	jalr	1258(ra) # 8000411a <iunlockput>
  ilock(ip);
    80005c38:	8526                	mv	a0,s1
    80005c3a:	ffffe097          	auipc	ra,0xffffe
    80005c3e:	27e080e7          	jalr	638(ra) # 80003eb8 <ilock>
  ip->nlink--;
    80005c42:	04a4d783          	lhu	a5,74(s1)
    80005c46:	37fd                	addiw	a5,a5,-1
    80005c48:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005c4c:	8526                	mv	a0,s1
    80005c4e:	ffffe097          	auipc	ra,0xffffe
    80005c52:	1a0080e7          	jalr	416(ra) # 80003dee <iupdate>
  iunlockput(ip);
    80005c56:	8526                	mv	a0,s1
    80005c58:	ffffe097          	auipc	ra,0xffffe
    80005c5c:	4c2080e7          	jalr	1218(ra) # 8000411a <iunlockput>
  end_op();
    80005c60:	fffff097          	auipc	ra,0xfffff
    80005c64:	c9a080e7          	jalr	-870(ra) # 800048fa <end_op>
  return -1;
    80005c68:	57fd                	li	a5,-1
}
    80005c6a:	853e                	mv	a0,a5
    80005c6c:	70b2                	ld	ra,296(sp)
    80005c6e:	7412                	ld	s0,288(sp)
    80005c70:	64f2                	ld	s1,280(sp)
    80005c72:	6952                	ld	s2,272(sp)
    80005c74:	6155                	addi	sp,sp,304
    80005c76:	8082                	ret

0000000080005c78 <sys_unlink>:
{
    80005c78:	7151                	addi	sp,sp,-240
    80005c7a:	f586                	sd	ra,232(sp)
    80005c7c:	f1a2                	sd	s0,224(sp)
    80005c7e:	eda6                	sd	s1,216(sp)
    80005c80:	e9ca                	sd	s2,208(sp)
    80005c82:	e5ce                	sd	s3,200(sp)
    80005c84:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005c86:	08000613          	li	a2,128
    80005c8a:	f3040593          	addi	a1,s0,-208
    80005c8e:	4501                	li	a0,0
    80005c90:	ffffd097          	auipc	ra,0xffffd
    80005c94:	52e080e7          	jalr	1326(ra) # 800031be <argstr>
    80005c98:	18054163          	bltz	a0,80005e1a <sys_unlink+0x1a2>
  begin_op();
    80005c9c:	fffff097          	auipc	ra,0xfffff
    80005ca0:	bde080e7          	jalr	-1058(ra) # 8000487a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005ca4:	fb040593          	addi	a1,s0,-80
    80005ca8:	f3040513          	addi	a0,s0,-208
    80005cac:	fffff097          	auipc	ra,0xfffff
    80005cb0:	9d0080e7          	jalr	-1584(ra) # 8000467c <nameiparent>
    80005cb4:	84aa                	mv	s1,a0
    80005cb6:	c979                	beqz	a0,80005d8c <sys_unlink+0x114>
  ilock(dp);
    80005cb8:	ffffe097          	auipc	ra,0xffffe
    80005cbc:	200080e7          	jalr	512(ra) # 80003eb8 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005cc0:	00003597          	auipc	a1,0x3
    80005cc4:	b6058593          	addi	a1,a1,-1184 # 80008820 <syscalls+0x2c8>
    80005cc8:	fb040513          	addi	a0,s0,-80
    80005ccc:	ffffe097          	auipc	ra,0xffffe
    80005cd0:	6b6080e7          	jalr	1718(ra) # 80004382 <namecmp>
    80005cd4:	14050a63          	beqz	a0,80005e28 <sys_unlink+0x1b0>
    80005cd8:	00003597          	auipc	a1,0x3
    80005cdc:	b5058593          	addi	a1,a1,-1200 # 80008828 <syscalls+0x2d0>
    80005ce0:	fb040513          	addi	a0,s0,-80
    80005ce4:	ffffe097          	auipc	ra,0xffffe
    80005ce8:	69e080e7          	jalr	1694(ra) # 80004382 <namecmp>
    80005cec:	12050e63          	beqz	a0,80005e28 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005cf0:	f2c40613          	addi	a2,s0,-212
    80005cf4:	fb040593          	addi	a1,s0,-80
    80005cf8:	8526                	mv	a0,s1
    80005cfa:	ffffe097          	auipc	ra,0xffffe
    80005cfe:	6a2080e7          	jalr	1698(ra) # 8000439c <dirlookup>
    80005d02:	892a                	mv	s2,a0
    80005d04:	12050263          	beqz	a0,80005e28 <sys_unlink+0x1b0>
  ilock(ip);
    80005d08:	ffffe097          	auipc	ra,0xffffe
    80005d0c:	1b0080e7          	jalr	432(ra) # 80003eb8 <ilock>
  if(ip->nlink < 1)
    80005d10:	04a91783          	lh	a5,74(s2)
    80005d14:	08f05263          	blez	a5,80005d98 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005d18:	04491703          	lh	a4,68(s2)
    80005d1c:	4785                	li	a5,1
    80005d1e:	08f70563          	beq	a4,a5,80005da8 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005d22:	4641                	li	a2,16
    80005d24:	4581                	li	a1,0
    80005d26:	fc040513          	addi	a0,s0,-64
    80005d2a:	ffffb097          	auipc	ra,0xffffb
    80005d2e:	fbc080e7          	jalr	-68(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d32:	4741                	li	a4,16
    80005d34:	f2c42683          	lw	a3,-212(s0)
    80005d38:	fc040613          	addi	a2,s0,-64
    80005d3c:	4581                	li	a1,0
    80005d3e:	8526                	mv	a0,s1
    80005d40:	ffffe097          	auipc	ra,0xffffe
    80005d44:	524080e7          	jalr	1316(ra) # 80004264 <writei>
    80005d48:	47c1                	li	a5,16
    80005d4a:	0af51563          	bne	a0,a5,80005df4 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005d4e:	04491703          	lh	a4,68(s2)
    80005d52:	4785                	li	a5,1
    80005d54:	0af70863          	beq	a4,a5,80005e04 <sys_unlink+0x18c>
  iunlockput(dp);
    80005d58:	8526                	mv	a0,s1
    80005d5a:	ffffe097          	auipc	ra,0xffffe
    80005d5e:	3c0080e7          	jalr	960(ra) # 8000411a <iunlockput>
  ip->nlink--;
    80005d62:	04a95783          	lhu	a5,74(s2)
    80005d66:	37fd                	addiw	a5,a5,-1
    80005d68:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005d6c:	854a                	mv	a0,s2
    80005d6e:	ffffe097          	auipc	ra,0xffffe
    80005d72:	080080e7          	jalr	128(ra) # 80003dee <iupdate>
  iunlockput(ip);
    80005d76:	854a                	mv	a0,s2
    80005d78:	ffffe097          	auipc	ra,0xffffe
    80005d7c:	3a2080e7          	jalr	930(ra) # 8000411a <iunlockput>
  end_op();
    80005d80:	fffff097          	auipc	ra,0xfffff
    80005d84:	b7a080e7          	jalr	-1158(ra) # 800048fa <end_op>
  return 0;
    80005d88:	4501                	li	a0,0
    80005d8a:	a84d                	j	80005e3c <sys_unlink+0x1c4>
    end_op();
    80005d8c:	fffff097          	auipc	ra,0xfffff
    80005d90:	b6e080e7          	jalr	-1170(ra) # 800048fa <end_op>
    return -1;
    80005d94:	557d                	li	a0,-1
    80005d96:	a05d                	j	80005e3c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005d98:	00003517          	auipc	a0,0x3
    80005d9c:	a9850513          	addi	a0,a0,-1384 # 80008830 <syscalls+0x2d8>
    80005da0:	ffffa097          	auipc	ra,0xffffa
    80005da4:	7a4080e7          	jalr	1956(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005da8:	04c92703          	lw	a4,76(s2)
    80005dac:	02000793          	li	a5,32
    80005db0:	f6e7f9e3          	bgeu	a5,a4,80005d22 <sys_unlink+0xaa>
    80005db4:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005db8:	4741                	li	a4,16
    80005dba:	86ce                	mv	a3,s3
    80005dbc:	f1840613          	addi	a2,s0,-232
    80005dc0:	4581                	li	a1,0
    80005dc2:	854a                	mv	a0,s2
    80005dc4:	ffffe097          	auipc	ra,0xffffe
    80005dc8:	3a8080e7          	jalr	936(ra) # 8000416c <readi>
    80005dcc:	47c1                	li	a5,16
    80005dce:	00f51b63          	bne	a0,a5,80005de4 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005dd2:	f1845783          	lhu	a5,-232(s0)
    80005dd6:	e7a1                	bnez	a5,80005e1e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005dd8:	29c1                	addiw	s3,s3,16
    80005dda:	04c92783          	lw	a5,76(s2)
    80005dde:	fcf9ede3          	bltu	s3,a5,80005db8 <sys_unlink+0x140>
    80005de2:	b781                	j	80005d22 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005de4:	00003517          	auipc	a0,0x3
    80005de8:	a6450513          	addi	a0,a0,-1436 # 80008848 <syscalls+0x2f0>
    80005dec:	ffffa097          	auipc	ra,0xffffa
    80005df0:	758080e7          	jalr	1880(ra) # 80000544 <panic>
    panic("unlink: writei");
    80005df4:	00003517          	auipc	a0,0x3
    80005df8:	a6c50513          	addi	a0,a0,-1428 # 80008860 <syscalls+0x308>
    80005dfc:	ffffa097          	auipc	ra,0xffffa
    80005e00:	748080e7          	jalr	1864(ra) # 80000544 <panic>
    dp->nlink--;
    80005e04:	04a4d783          	lhu	a5,74(s1)
    80005e08:	37fd                	addiw	a5,a5,-1
    80005e0a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005e0e:	8526                	mv	a0,s1
    80005e10:	ffffe097          	auipc	ra,0xffffe
    80005e14:	fde080e7          	jalr	-34(ra) # 80003dee <iupdate>
    80005e18:	b781                	j	80005d58 <sys_unlink+0xe0>
    return -1;
    80005e1a:	557d                	li	a0,-1
    80005e1c:	a005                	j	80005e3c <sys_unlink+0x1c4>
    iunlockput(ip);
    80005e1e:	854a                	mv	a0,s2
    80005e20:	ffffe097          	auipc	ra,0xffffe
    80005e24:	2fa080e7          	jalr	762(ra) # 8000411a <iunlockput>
  iunlockput(dp);
    80005e28:	8526                	mv	a0,s1
    80005e2a:	ffffe097          	auipc	ra,0xffffe
    80005e2e:	2f0080e7          	jalr	752(ra) # 8000411a <iunlockput>
  end_op();
    80005e32:	fffff097          	auipc	ra,0xfffff
    80005e36:	ac8080e7          	jalr	-1336(ra) # 800048fa <end_op>
  return -1;
    80005e3a:	557d                	li	a0,-1
}
    80005e3c:	70ae                	ld	ra,232(sp)
    80005e3e:	740e                	ld	s0,224(sp)
    80005e40:	64ee                	ld	s1,216(sp)
    80005e42:	694e                	ld	s2,208(sp)
    80005e44:	69ae                	ld	s3,200(sp)
    80005e46:	616d                	addi	sp,sp,240
    80005e48:	8082                	ret

0000000080005e4a <sys_open>:

uint64
sys_open(void)
{
    80005e4a:	7131                	addi	sp,sp,-192
    80005e4c:	fd06                	sd	ra,184(sp)
    80005e4e:	f922                	sd	s0,176(sp)
    80005e50:	f526                	sd	s1,168(sp)
    80005e52:	f14a                	sd	s2,160(sp)
    80005e54:	ed4e                	sd	s3,152(sp)
    80005e56:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005e58:	f4c40593          	addi	a1,s0,-180
    80005e5c:	4505                	li	a0,1
    80005e5e:	ffffd097          	auipc	ra,0xffffd
    80005e62:	320080e7          	jalr	800(ra) # 8000317e <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005e66:	08000613          	li	a2,128
    80005e6a:	f5040593          	addi	a1,s0,-176
    80005e6e:	4501                	li	a0,0
    80005e70:	ffffd097          	auipc	ra,0xffffd
    80005e74:	34e080e7          	jalr	846(ra) # 800031be <argstr>
    80005e78:	87aa                	mv	a5,a0
    return -1;
    80005e7a:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005e7c:	0a07c963          	bltz	a5,80005f2e <sys_open+0xe4>

  begin_op();
    80005e80:	fffff097          	auipc	ra,0xfffff
    80005e84:	9fa080e7          	jalr	-1542(ra) # 8000487a <begin_op>

  if(omode & O_CREATE){
    80005e88:	f4c42783          	lw	a5,-180(s0)
    80005e8c:	2007f793          	andi	a5,a5,512
    80005e90:	cfc5                	beqz	a5,80005f48 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005e92:	4681                	li	a3,0
    80005e94:	4601                	li	a2,0
    80005e96:	4589                	li	a1,2
    80005e98:	f5040513          	addi	a0,s0,-176
    80005e9c:	00000097          	auipc	ra,0x0
    80005ea0:	974080e7          	jalr	-1676(ra) # 80005810 <create>
    80005ea4:	84aa                	mv	s1,a0
    if(ip == 0){
    80005ea6:	c959                	beqz	a0,80005f3c <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005ea8:	04449703          	lh	a4,68(s1)
    80005eac:	478d                	li	a5,3
    80005eae:	00f71763          	bne	a4,a5,80005ebc <sys_open+0x72>
    80005eb2:	0464d703          	lhu	a4,70(s1)
    80005eb6:	47a5                	li	a5,9
    80005eb8:	0ce7ed63          	bltu	a5,a4,80005f92 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005ebc:	fffff097          	auipc	ra,0xfffff
    80005ec0:	dce080e7          	jalr	-562(ra) # 80004c8a <filealloc>
    80005ec4:	89aa                	mv	s3,a0
    80005ec6:	10050363          	beqz	a0,80005fcc <sys_open+0x182>
    80005eca:	00000097          	auipc	ra,0x0
    80005ece:	904080e7          	jalr	-1788(ra) # 800057ce <fdalloc>
    80005ed2:	892a                	mv	s2,a0
    80005ed4:	0e054763          	bltz	a0,80005fc2 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005ed8:	04449703          	lh	a4,68(s1)
    80005edc:	478d                	li	a5,3
    80005ede:	0cf70563          	beq	a4,a5,80005fa8 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005ee2:	4789                	li	a5,2
    80005ee4:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005ee8:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005eec:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005ef0:	f4c42783          	lw	a5,-180(s0)
    80005ef4:	0017c713          	xori	a4,a5,1
    80005ef8:	8b05                	andi	a4,a4,1
    80005efa:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005efe:	0037f713          	andi	a4,a5,3
    80005f02:	00e03733          	snez	a4,a4
    80005f06:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005f0a:	4007f793          	andi	a5,a5,1024
    80005f0e:	c791                	beqz	a5,80005f1a <sys_open+0xd0>
    80005f10:	04449703          	lh	a4,68(s1)
    80005f14:	4789                	li	a5,2
    80005f16:	0af70063          	beq	a4,a5,80005fb6 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005f1a:	8526                	mv	a0,s1
    80005f1c:	ffffe097          	auipc	ra,0xffffe
    80005f20:	05e080e7          	jalr	94(ra) # 80003f7a <iunlock>
  end_op();
    80005f24:	fffff097          	auipc	ra,0xfffff
    80005f28:	9d6080e7          	jalr	-1578(ra) # 800048fa <end_op>

  return fd;
    80005f2c:	854a                	mv	a0,s2
}
    80005f2e:	70ea                	ld	ra,184(sp)
    80005f30:	744a                	ld	s0,176(sp)
    80005f32:	74aa                	ld	s1,168(sp)
    80005f34:	790a                	ld	s2,160(sp)
    80005f36:	69ea                	ld	s3,152(sp)
    80005f38:	6129                	addi	sp,sp,192
    80005f3a:	8082                	ret
      end_op();
    80005f3c:	fffff097          	auipc	ra,0xfffff
    80005f40:	9be080e7          	jalr	-1602(ra) # 800048fa <end_op>
      return -1;
    80005f44:	557d                	li	a0,-1
    80005f46:	b7e5                	j	80005f2e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005f48:	f5040513          	addi	a0,s0,-176
    80005f4c:	ffffe097          	auipc	ra,0xffffe
    80005f50:	712080e7          	jalr	1810(ra) # 8000465e <namei>
    80005f54:	84aa                	mv	s1,a0
    80005f56:	c905                	beqz	a0,80005f86 <sys_open+0x13c>
    ilock(ip);
    80005f58:	ffffe097          	auipc	ra,0xffffe
    80005f5c:	f60080e7          	jalr	-160(ra) # 80003eb8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005f60:	04449703          	lh	a4,68(s1)
    80005f64:	4785                	li	a5,1
    80005f66:	f4f711e3          	bne	a4,a5,80005ea8 <sys_open+0x5e>
    80005f6a:	f4c42783          	lw	a5,-180(s0)
    80005f6e:	d7b9                	beqz	a5,80005ebc <sys_open+0x72>
      iunlockput(ip);
    80005f70:	8526                	mv	a0,s1
    80005f72:	ffffe097          	auipc	ra,0xffffe
    80005f76:	1a8080e7          	jalr	424(ra) # 8000411a <iunlockput>
      end_op();
    80005f7a:	fffff097          	auipc	ra,0xfffff
    80005f7e:	980080e7          	jalr	-1664(ra) # 800048fa <end_op>
      return -1;
    80005f82:	557d                	li	a0,-1
    80005f84:	b76d                	j	80005f2e <sys_open+0xe4>
      end_op();
    80005f86:	fffff097          	auipc	ra,0xfffff
    80005f8a:	974080e7          	jalr	-1676(ra) # 800048fa <end_op>
      return -1;
    80005f8e:	557d                	li	a0,-1
    80005f90:	bf79                	j	80005f2e <sys_open+0xe4>
    iunlockput(ip);
    80005f92:	8526                	mv	a0,s1
    80005f94:	ffffe097          	auipc	ra,0xffffe
    80005f98:	186080e7          	jalr	390(ra) # 8000411a <iunlockput>
    end_op();
    80005f9c:	fffff097          	auipc	ra,0xfffff
    80005fa0:	95e080e7          	jalr	-1698(ra) # 800048fa <end_op>
    return -1;
    80005fa4:	557d                	li	a0,-1
    80005fa6:	b761                	j	80005f2e <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005fa8:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005fac:	04649783          	lh	a5,70(s1)
    80005fb0:	02f99223          	sh	a5,36(s3)
    80005fb4:	bf25                	j	80005eec <sys_open+0xa2>
    itrunc(ip);
    80005fb6:	8526                	mv	a0,s1
    80005fb8:	ffffe097          	auipc	ra,0xffffe
    80005fbc:	00e080e7          	jalr	14(ra) # 80003fc6 <itrunc>
    80005fc0:	bfa9                	j	80005f1a <sys_open+0xd0>
      fileclose(f);
    80005fc2:	854e                	mv	a0,s3
    80005fc4:	fffff097          	auipc	ra,0xfffff
    80005fc8:	d82080e7          	jalr	-638(ra) # 80004d46 <fileclose>
    iunlockput(ip);
    80005fcc:	8526                	mv	a0,s1
    80005fce:	ffffe097          	auipc	ra,0xffffe
    80005fd2:	14c080e7          	jalr	332(ra) # 8000411a <iunlockput>
    end_op();
    80005fd6:	fffff097          	auipc	ra,0xfffff
    80005fda:	924080e7          	jalr	-1756(ra) # 800048fa <end_op>
    return -1;
    80005fde:	557d                	li	a0,-1
    80005fe0:	b7b9                	j	80005f2e <sys_open+0xe4>

0000000080005fe2 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005fe2:	7175                	addi	sp,sp,-144
    80005fe4:	e506                	sd	ra,136(sp)
    80005fe6:	e122                	sd	s0,128(sp)
    80005fe8:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005fea:	fffff097          	auipc	ra,0xfffff
    80005fee:	890080e7          	jalr	-1904(ra) # 8000487a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005ff2:	08000613          	li	a2,128
    80005ff6:	f7040593          	addi	a1,s0,-144
    80005ffa:	4501                	li	a0,0
    80005ffc:	ffffd097          	auipc	ra,0xffffd
    80006000:	1c2080e7          	jalr	450(ra) # 800031be <argstr>
    80006004:	02054963          	bltz	a0,80006036 <sys_mkdir+0x54>
    80006008:	4681                	li	a3,0
    8000600a:	4601                	li	a2,0
    8000600c:	4585                	li	a1,1
    8000600e:	f7040513          	addi	a0,s0,-144
    80006012:	fffff097          	auipc	ra,0xfffff
    80006016:	7fe080e7          	jalr	2046(ra) # 80005810 <create>
    8000601a:	cd11                	beqz	a0,80006036 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000601c:	ffffe097          	auipc	ra,0xffffe
    80006020:	0fe080e7          	jalr	254(ra) # 8000411a <iunlockput>
  end_op();
    80006024:	fffff097          	auipc	ra,0xfffff
    80006028:	8d6080e7          	jalr	-1834(ra) # 800048fa <end_op>
  return 0;
    8000602c:	4501                	li	a0,0
}
    8000602e:	60aa                	ld	ra,136(sp)
    80006030:	640a                	ld	s0,128(sp)
    80006032:	6149                	addi	sp,sp,144
    80006034:	8082                	ret
    end_op();
    80006036:	fffff097          	auipc	ra,0xfffff
    8000603a:	8c4080e7          	jalr	-1852(ra) # 800048fa <end_op>
    return -1;
    8000603e:	557d                	li	a0,-1
    80006040:	b7fd                	j	8000602e <sys_mkdir+0x4c>

0000000080006042 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006042:	7135                	addi	sp,sp,-160
    80006044:	ed06                	sd	ra,152(sp)
    80006046:	e922                	sd	s0,144(sp)
    80006048:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000604a:	fffff097          	auipc	ra,0xfffff
    8000604e:	830080e7          	jalr	-2000(ra) # 8000487a <begin_op>
  argint(1, &major);
    80006052:	f6c40593          	addi	a1,s0,-148
    80006056:	4505                	li	a0,1
    80006058:	ffffd097          	auipc	ra,0xffffd
    8000605c:	126080e7          	jalr	294(ra) # 8000317e <argint>
  argint(2, &minor);
    80006060:	f6840593          	addi	a1,s0,-152
    80006064:	4509                	li	a0,2
    80006066:	ffffd097          	auipc	ra,0xffffd
    8000606a:	118080e7          	jalr	280(ra) # 8000317e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000606e:	08000613          	li	a2,128
    80006072:	f7040593          	addi	a1,s0,-144
    80006076:	4501                	li	a0,0
    80006078:	ffffd097          	auipc	ra,0xffffd
    8000607c:	146080e7          	jalr	326(ra) # 800031be <argstr>
    80006080:	02054b63          	bltz	a0,800060b6 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006084:	f6841683          	lh	a3,-152(s0)
    80006088:	f6c41603          	lh	a2,-148(s0)
    8000608c:	458d                	li	a1,3
    8000608e:	f7040513          	addi	a0,s0,-144
    80006092:	fffff097          	auipc	ra,0xfffff
    80006096:	77e080e7          	jalr	1918(ra) # 80005810 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000609a:	cd11                	beqz	a0,800060b6 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000609c:	ffffe097          	auipc	ra,0xffffe
    800060a0:	07e080e7          	jalr	126(ra) # 8000411a <iunlockput>
  end_op();
    800060a4:	fffff097          	auipc	ra,0xfffff
    800060a8:	856080e7          	jalr	-1962(ra) # 800048fa <end_op>
  return 0;
    800060ac:	4501                	li	a0,0
}
    800060ae:	60ea                	ld	ra,152(sp)
    800060b0:	644a                	ld	s0,144(sp)
    800060b2:	610d                	addi	sp,sp,160
    800060b4:	8082                	ret
    end_op();
    800060b6:	fffff097          	auipc	ra,0xfffff
    800060ba:	844080e7          	jalr	-1980(ra) # 800048fa <end_op>
    return -1;
    800060be:	557d                	li	a0,-1
    800060c0:	b7fd                	j	800060ae <sys_mknod+0x6c>

00000000800060c2 <sys_chdir>:

uint64
sys_chdir(void)
{
    800060c2:	7135                	addi	sp,sp,-160
    800060c4:	ed06                	sd	ra,152(sp)
    800060c6:	e922                	sd	s0,144(sp)
    800060c8:	e526                	sd	s1,136(sp)
    800060ca:	e14a                	sd	s2,128(sp)
    800060cc:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800060ce:	ffffc097          	auipc	ra,0xffffc
    800060d2:	ae6080e7          	jalr	-1306(ra) # 80001bb4 <myproc>
    800060d6:	892a                	mv	s2,a0
  
  begin_op();
    800060d8:	ffffe097          	auipc	ra,0xffffe
    800060dc:	7a2080e7          	jalr	1954(ra) # 8000487a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800060e0:	08000613          	li	a2,128
    800060e4:	f6040593          	addi	a1,s0,-160
    800060e8:	4501                	li	a0,0
    800060ea:	ffffd097          	auipc	ra,0xffffd
    800060ee:	0d4080e7          	jalr	212(ra) # 800031be <argstr>
    800060f2:	04054b63          	bltz	a0,80006148 <sys_chdir+0x86>
    800060f6:	f6040513          	addi	a0,s0,-160
    800060fa:	ffffe097          	auipc	ra,0xffffe
    800060fe:	564080e7          	jalr	1380(ra) # 8000465e <namei>
    80006102:	84aa                	mv	s1,a0
    80006104:	c131                	beqz	a0,80006148 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006106:	ffffe097          	auipc	ra,0xffffe
    8000610a:	db2080e7          	jalr	-590(ra) # 80003eb8 <ilock>
  if(ip->type != T_DIR){
    8000610e:	04449703          	lh	a4,68(s1)
    80006112:	4785                	li	a5,1
    80006114:	04f71063          	bne	a4,a5,80006154 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006118:	8526                	mv	a0,s1
    8000611a:	ffffe097          	auipc	ra,0xffffe
    8000611e:	e60080e7          	jalr	-416(ra) # 80003f7a <iunlock>
  iput(p->cwd);
    80006122:	15093503          	ld	a0,336(s2)
    80006126:	ffffe097          	auipc	ra,0xffffe
    8000612a:	f4c080e7          	jalr	-180(ra) # 80004072 <iput>
  end_op();
    8000612e:	ffffe097          	auipc	ra,0xffffe
    80006132:	7cc080e7          	jalr	1996(ra) # 800048fa <end_op>
  p->cwd = ip;
    80006136:	14993823          	sd	s1,336(s2)
  return 0;
    8000613a:	4501                	li	a0,0
}
    8000613c:	60ea                	ld	ra,152(sp)
    8000613e:	644a                	ld	s0,144(sp)
    80006140:	64aa                	ld	s1,136(sp)
    80006142:	690a                	ld	s2,128(sp)
    80006144:	610d                	addi	sp,sp,160
    80006146:	8082                	ret
    end_op();
    80006148:	ffffe097          	auipc	ra,0xffffe
    8000614c:	7b2080e7          	jalr	1970(ra) # 800048fa <end_op>
    return -1;
    80006150:	557d                	li	a0,-1
    80006152:	b7ed                	j	8000613c <sys_chdir+0x7a>
    iunlockput(ip);
    80006154:	8526                	mv	a0,s1
    80006156:	ffffe097          	auipc	ra,0xffffe
    8000615a:	fc4080e7          	jalr	-60(ra) # 8000411a <iunlockput>
    end_op();
    8000615e:	ffffe097          	auipc	ra,0xffffe
    80006162:	79c080e7          	jalr	1948(ra) # 800048fa <end_op>
    return -1;
    80006166:	557d                	li	a0,-1
    80006168:	bfd1                	j	8000613c <sys_chdir+0x7a>

000000008000616a <sys_exec>:

uint64
sys_exec(void)
{
    8000616a:	7145                	addi	sp,sp,-464
    8000616c:	e786                	sd	ra,456(sp)
    8000616e:	e3a2                	sd	s0,448(sp)
    80006170:	ff26                	sd	s1,440(sp)
    80006172:	fb4a                	sd	s2,432(sp)
    80006174:	f74e                	sd	s3,424(sp)
    80006176:	f352                	sd	s4,416(sp)
    80006178:	ef56                	sd	s5,408(sp)
    8000617a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    8000617c:	e3840593          	addi	a1,s0,-456
    80006180:	4505                	li	a0,1
    80006182:	ffffd097          	auipc	ra,0xffffd
    80006186:	01c080e7          	jalr	28(ra) # 8000319e <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    8000618a:	08000613          	li	a2,128
    8000618e:	f4040593          	addi	a1,s0,-192
    80006192:	4501                	li	a0,0
    80006194:	ffffd097          	auipc	ra,0xffffd
    80006198:	02a080e7          	jalr	42(ra) # 800031be <argstr>
    8000619c:	87aa                	mv	a5,a0
    return -1;
    8000619e:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    800061a0:	0c07c263          	bltz	a5,80006264 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800061a4:	10000613          	li	a2,256
    800061a8:	4581                	li	a1,0
    800061aa:	e4040513          	addi	a0,s0,-448
    800061ae:	ffffb097          	auipc	ra,0xffffb
    800061b2:	b38080e7          	jalr	-1224(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800061b6:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800061ba:	89a6                	mv	s3,s1
    800061bc:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800061be:	02000a13          	li	s4,32
    800061c2:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800061c6:	00391513          	slli	a0,s2,0x3
    800061ca:	e3040593          	addi	a1,s0,-464
    800061ce:	e3843783          	ld	a5,-456(s0)
    800061d2:	953e                	add	a0,a0,a5
    800061d4:	ffffd097          	auipc	ra,0xffffd
    800061d8:	f0c080e7          	jalr	-244(ra) # 800030e0 <fetchaddr>
    800061dc:	02054a63          	bltz	a0,80006210 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    800061e0:	e3043783          	ld	a5,-464(s0)
    800061e4:	c3b9                	beqz	a5,8000622a <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800061e6:	ffffb097          	auipc	ra,0xffffb
    800061ea:	914080e7          	jalr	-1772(ra) # 80000afa <kalloc>
    800061ee:	85aa                	mv	a1,a0
    800061f0:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800061f4:	cd11                	beqz	a0,80006210 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800061f6:	6605                	lui	a2,0x1
    800061f8:	e3043503          	ld	a0,-464(s0)
    800061fc:	ffffd097          	auipc	ra,0xffffd
    80006200:	f36080e7          	jalr	-202(ra) # 80003132 <fetchstr>
    80006204:	00054663          	bltz	a0,80006210 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80006208:	0905                	addi	s2,s2,1
    8000620a:	09a1                	addi	s3,s3,8
    8000620c:	fb491be3          	bne	s2,s4,800061c2 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006210:	10048913          	addi	s2,s1,256
    80006214:	6088                	ld	a0,0(s1)
    80006216:	c531                	beqz	a0,80006262 <sys_exec+0xf8>
    kfree(argv[i]);
    80006218:	ffffa097          	auipc	ra,0xffffa
    8000621c:	7e6080e7          	jalr	2022(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006220:	04a1                	addi	s1,s1,8
    80006222:	ff2499e3          	bne	s1,s2,80006214 <sys_exec+0xaa>
  return -1;
    80006226:	557d                	li	a0,-1
    80006228:	a835                	j	80006264 <sys_exec+0xfa>
      argv[i] = 0;
    8000622a:	0a8e                	slli	s5,s5,0x3
    8000622c:	fc040793          	addi	a5,s0,-64
    80006230:	9abe                	add	s5,s5,a5
    80006232:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006236:	e4040593          	addi	a1,s0,-448
    8000623a:	f4040513          	addi	a0,s0,-192
    8000623e:	fffff097          	auipc	ra,0xfffff
    80006242:	190080e7          	jalr	400(ra) # 800053ce <exec>
    80006246:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006248:	10048993          	addi	s3,s1,256
    8000624c:	6088                	ld	a0,0(s1)
    8000624e:	c901                	beqz	a0,8000625e <sys_exec+0xf4>
    kfree(argv[i]);
    80006250:	ffffa097          	auipc	ra,0xffffa
    80006254:	7ae080e7          	jalr	1966(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006258:	04a1                	addi	s1,s1,8
    8000625a:	ff3499e3          	bne	s1,s3,8000624c <sys_exec+0xe2>
  return ret;
    8000625e:	854a                	mv	a0,s2
    80006260:	a011                	j	80006264 <sys_exec+0xfa>
  return -1;
    80006262:	557d                	li	a0,-1
}
    80006264:	60be                	ld	ra,456(sp)
    80006266:	641e                	ld	s0,448(sp)
    80006268:	74fa                	ld	s1,440(sp)
    8000626a:	795a                	ld	s2,432(sp)
    8000626c:	79ba                	ld	s3,424(sp)
    8000626e:	7a1a                	ld	s4,416(sp)
    80006270:	6afa                	ld	s5,408(sp)
    80006272:	6179                	addi	sp,sp,464
    80006274:	8082                	ret

0000000080006276 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006276:	7139                	addi	sp,sp,-64
    80006278:	fc06                	sd	ra,56(sp)
    8000627a:	f822                	sd	s0,48(sp)
    8000627c:	f426                	sd	s1,40(sp)
    8000627e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006280:	ffffc097          	auipc	ra,0xffffc
    80006284:	934080e7          	jalr	-1740(ra) # 80001bb4 <myproc>
    80006288:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    8000628a:	fd840593          	addi	a1,s0,-40
    8000628e:	4501                	li	a0,0
    80006290:	ffffd097          	auipc	ra,0xffffd
    80006294:	f0e080e7          	jalr	-242(ra) # 8000319e <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006298:	fc840593          	addi	a1,s0,-56
    8000629c:	fd040513          	addi	a0,s0,-48
    800062a0:	fffff097          	auipc	ra,0xfffff
    800062a4:	dd6080e7          	jalr	-554(ra) # 80005076 <pipealloc>
    return -1;
    800062a8:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800062aa:	0c054463          	bltz	a0,80006372 <sys_pipe+0xfc>
  fd0 = -1;
    800062ae:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800062b2:	fd043503          	ld	a0,-48(s0)
    800062b6:	fffff097          	auipc	ra,0xfffff
    800062ba:	518080e7          	jalr	1304(ra) # 800057ce <fdalloc>
    800062be:	fca42223          	sw	a0,-60(s0)
    800062c2:	08054b63          	bltz	a0,80006358 <sys_pipe+0xe2>
    800062c6:	fc843503          	ld	a0,-56(s0)
    800062ca:	fffff097          	auipc	ra,0xfffff
    800062ce:	504080e7          	jalr	1284(ra) # 800057ce <fdalloc>
    800062d2:	fca42023          	sw	a0,-64(s0)
    800062d6:	06054863          	bltz	a0,80006346 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800062da:	4691                	li	a3,4
    800062dc:	fc440613          	addi	a2,s0,-60
    800062e0:	fd843583          	ld	a1,-40(s0)
    800062e4:	68a8                	ld	a0,80(s1)
    800062e6:	ffffb097          	auipc	ra,0xffffb
    800062ea:	39e080e7          	jalr	926(ra) # 80001684 <copyout>
    800062ee:	02054063          	bltz	a0,8000630e <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800062f2:	4691                	li	a3,4
    800062f4:	fc040613          	addi	a2,s0,-64
    800062f8:	fd843583          	ld	a1,-40(s0)
    800062fc:	0591                	addi	a1,a1,4
    800062fe:	68a8                	ld	a0,80(s1)
    80006300:	ffffb097          	auipc	ra,0xffffb
    80006304:	384080e7          	jalr	900(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006308:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000630a:	06055463          	bgez	a0,80006372 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    8000630e:	fc442783          	lw	a5,-60(s0)
    80006312:	07e9                	addi	a5,a5,26
    80006314:	078e                	slli	a5,a5,0x3
    80006316:	97a6                	add	a5,a5,s1
    80006318:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000631c:	fc042503          	lw	a0,-64(s0)
    80006320:	0569                	addi	a0,a0,26
    80006322:	050e                	slli	a0,a0,0x3
    80006324:	94aa                	add	s1,s1,a0
    80006326:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    8000632a:	fd043503          	ld	a0,-48(s0)
    8000632e:	fffff097          	auipc	ra,0xfffff
    80006332:	a18080e7          	jalr	-1512(ra) # 80004d46 <fileclose>
    fileclose(wf);
    80006336:	fc843503          	ld	a0,-56(s0)
    8000633a:	fffff097          	auipc	ra,0xfffff
    8000633e:	a0c080e7          	jalr	-1524(ra) # 80004d46 <fileclose>
    return -1;
    80006342:	57fd                	li	a5,-1
    80006344:	a03d                	j	80006372 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006346:	fc442783          	lw	a5,-60(s0)
    8000634a:	0007c763          	bltz	a5,80006358 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    8000634e:	07e9                	addi	a5,a5,26
    80006350:	078e                	slli	a5,a5,0x3
    80006352:	94be                	add	s1,s1,a5
    80006354:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006358:	fd043503          	ld	a0,-48(s0)
    8000635c:	fffff097          	auipc	ra,0xfffff
    80006360:	9ea080e7          	jalr	-1558(ra) # 80004d46 <fileclose>
    fileclose(wf);
    80006364:	fc843503          	ld	a0,-56(s0)
    80006368:	fffff097          	auipc	ra,0xfffff
    8000636c:	9de080e7          	jalr	-1570(ra) # 80004d46 <fileclose>
    return -1;
    80006370:	57fd                	li	a5,-1
}
    80006372:	853e                	mv	a0,a5
    80006374:	70e2                	ld	ra,56(sp)
    80006376:	7442                	ld	s0,48(sp)
    80006378:	74a2                	ld	s1,40(sp)
    8000637a:	6121                	addi	sp,sp,64
    8000637c:	8082                	ret
	...

0000000080006380 <kernelvec>:
    80006380:	7111                	addi	sp,sp,-256
    80006382:	e006                	sd	ra,0(sp)
    80006384:	e40a                	sd	sp,8(sp)
    80006386:	e80e                	sd	gp,16(sp)
    80006388:	ec12                	sd	tp,24(sp)
    8000638a:	f016                	sd	t0,32(sp)
    8000638c:	f41a                	sd	t1,40(sp)
    8000638e:	f81e                	sd	t2,48(sp)
    80006390:	fc22                	sd	s0,56(sp)
    80006392:	e0a6                	sd	s1,64(sp)
    80006394:	e4aa                	sd	a0,72(sp)
    80006396:	e8ae                	sd	a1,80(sp)
    80006398:	ecb2                	sd	a2,88(sp)
    8000639a:	f0b6                	sd	a3,96(sp)
    8000639c:	f4ba                	sd	a4,104(sp)
    8000639e:	f8be                	sd	a5,112(sp)
    800063a0:	fcc2                	sd	a6,120(sp)
    800063a2:	e146                	sd	a7,128(sp)
    800063a4:	e54a                	sd	s2,136(sp)
    800063a6:	e94e                	sd	s3,144(sp)
    800063a8:	ed52                	sd	s4,152(sp)
    800063aa:	f156                	sd	s5,160(sp)
    800063ac:	f55a                	sd	s6,168(sp)
    800063ae:	f95e                	sd	s7,176(sp)
    800063b0:	fd62                	sd	s8,184(sp)
    800063b2:	e1e6                	sd	s9,192(sp)
    800063b4:	e5ea                	sd	s10,200(sp)
    800063b6:	e9ee                	sd	s11,208(sp)
    800063b8:	edf2                	sd	t3,216(sp)
    800063ba:	f1f6                	sd	t4,224(sp)
    800063bc:	f5fa                	sd	t5,232(sp)
    800063be:	f9fe                	sd	t6,240(sp)
    800063c0:	b83fc0ef          	jal	ra,80002f42 <kerneltrap>
    800063c4:	6082                	ld	ra,0(sp)
    800063c6:	6122                	ld	sp,8(sp)
    800063c8:	61c2                	ld	gp,16(sp)
    800063ca:	7282                	ld	t0,32(sp)
    800063cc:	7322                	ld	t1,40(sp)
    800063ce:	73c2                	ld	t2,48(sp)
    800063d0:	7462                	ld	s0,56(sp)
    800063d2:	6486                	ld	s1,64(sp)
    800063d4:	6526                	ld	a0,72(sp)
    800063d6:	65c6                	ld	a1,80(sp)
    800063d8:	6666                	ld	a2,88(sp)
    800063da:	7686                	ld	a3,96(sp)
    800063dc:	7726                	ld	a4,104(sp)
    800063de:	77c6                	ld	a5,112(sp)
    800063e0:	7866                	ld	a6,120(sp)
    800063e2:	688a                	ld	a7,128(sp)
    800063e4:	692a                	ld	s2,136(sp)
    800063e6:	69ca                	ld	s3,144(sp)
    800063e8:	6a6a                	ld	s4,152(sp)
    800063ea:	7a8a                	ld	s5,160(sp)
    800063ec:	7b2a                	ld	s6,168(sp)
    800063ee:	7bca                	ld	s7,176(sp)
    800063f0:	7c6a                	ld	s8,184(sp)
    800063f2:	6c8e                	ld	s9,192(sp)
    800063f4:	6d2e                	ld	s10,200(sp)
    800063f6:	6dce                	ld	s11,208(sp)
    800063f8:	6e6e                	ld	t3,216(sp)
    800063fa:	7e8e                	ld	t4,224(sp)
    800063fc:	7f2e                	ld	t5,232(sp)
    800063fe:	7fce                	ld	t6,240(sp)
    80006400:	6111                	addi	sp,sp,256
    80006402:	10200073          	sret
    80006406:	00000013          	nop
    8000640a:	00000013          	nop
    8000640e:	0001                	nop

0000000080006410 <timervec>:
    80006410:	34051573          	csrrw	a0,mscratch,a0
    80006414:	e10c                	sd	a1,0(a0)
    80006416:	e510                	sd	a2,8(a0)
    80006418:	e914                	sd	a3,16(a0)
    8000641a:	6d0c                	ld	a1,24(a0)
    8000641c:	7110                	ld	a2,32(a0)
    8000641e:	6194                	ld	a3,0(a1)
    80006420:	96b2                	add	a3,a3,a2
    80006422:	e194                	sd	a3,0(a1)
    80006424:	4589                	li	a1,2
    80006426:	14459073          	csrw	sip,a1
    8000642a:	6914                	ld	a3,16(a0)
    8000642c:	6510                	ld	a2,8(a0)
    8000642e:	610c                	ld	a1,0(a0)
    80006430:	34051573          	csrrw	a0,mscratch,a0
    80006434:	30200073          	mret
	...

000000008000643a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000643a:	1141                	addi	sp,sp,-16
    8000643c:	e422                	sd	s0,8(sp)
    8000643e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006440:	0c0007b7          	lui	a5,0xc000
    80006444:	4705                	li	a4,1
    80006446:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006448:	c3d8                	sw	a4,4(a5)
}
    8000644a:	6422                	ld	s0,8(sp)
    8000644c:	0141                	addi	sp,sp,16
    8000644e:	8082                	ret

0000000080006450 <plicinithart>:

void
plicinithart(void)
{
    80006450:	1141                	addi	sp,sp,-16
    80006452:	e406                	sd	ra,8(sp)
    80006454:	e022                	sd	s0,0(sp)
    80006456:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006458:	ffffb097          	auipc	ra,0xffffb
    8000645c:	730080e7          	jalr	1840(ra) # 80001b88 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006460:	0085171b          	slliw	a4,a0,0x8
    80006464:	0c0027b7          	lui	a5,0xc002
    80006468:	97ba                	add	a5,a5,a4
    8000646a:	40200713          	li	a4,1026
    8000646e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006472:	00d5151b          	slliw	a0,a0,0xd
    80006476:	0c2017b7          	lui	a5,0xc201
    8000647a:	953e                	add	a0,a0,a5
    8000647c:	00052023          	sw	zero,0(a0)
}
    80006480:	60a2                	ld	ra,8(sp)
    80006482:	6402                	ld	s0,0(sp)
    80006484:	0141                	addi	sp,sp,16
    80006486:	8082                	ret

0000000080006488 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006488:	1141                	addi	sp,sp,-16
    8000648a:	e406                	sd	ra,8(sp)
    8000648c:	e022                	sd	s0,0(sp)
    8000648e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006490:	ffffb097          	auipc	ra,0xffffb
    80006494:	6f8080e7          	jalr	1784(ra) # 80001b88 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006498:	00d5179b          	slliw	a5,a0,0xd
    8000649c:	0c201537          	lui	a0,0xc201
    800064a0:	953e                	add	a0,a0,a5
  return irq;
}
    800064a2:	4148                	lw	a0,4(a0)
    800064a4:	60a2                	ld	ra,8(sp)
    800064a6:	6402                	ld	s0,0(sp)
    800064a8:	0141                	addi	sp,sp,16
    800064aa:	8082                	ret

00000000800064ac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800064ac:	1101                	addi	sp,sp,-32
    800064ae:	ec06                	sd	ra,24(sp)
    800064b0:	e822                	sd	s0,16(sp)
    800064b2:	e426                	sd	s1,8(sp)
    800064b4:	1000                	addi	s0,sp,32
    800064b6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800064b8:	ffffb097          	auipc	ra,0xffffb
    800064bc:	6d0080e7          	jalr	1744(ra) # 80001b88 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800064c0:	00d5151b          	slliw	a0,a0,0xd
    800064c4:	0c2017b7          	lui	a5,0xc201
    800064c8:	97aa                	add	a5,a5,a0
    800064ca:	c3c4                	sw	s1,4(a5)
}
    800064cc:	60e2                	ld	ra,24(sp)
    800064ce:	6442                	ld	s0,16(sp)
    800064d0:	64a2                	ld	s1,8(sp)
    800064d2:	6105                	addi	sp,sp,32
    800064d4:	8082                	ret

00000000800064d6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800064d6:	1141                	addi	sp,sp,-16
    800064d8:	e406                	sd	ra,8(sp)
    800064da:	e022                	sd	s0,0(sp)
    800064dc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800064de:	479d                	li	a5,7
    800064e0:	04a7cc63          	blt	a5,a0,80006538 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800064e4:	0001d797          	auipc	a5,0x1d
    800064e8:	5d478793          	addi	a5,a5,1492 # 80023ab8 <disk>
    800064ec:	97aa                	add	a5,a5,a0
    800064ee:	0187c783          	lbu	a5,24(a5)
    800064f2:	ebb9                	bnez	a5,80006548 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800064f4:	00451613          	slli	a2,a0,0x4
    800064f8:	0001d797          	auipc	a5,0x1d
    800064fc:	5c078793          	addi	a5,a5,1472 # 80023ab8 <disk>
    80006500:	6394                	ld	a3,0(a5)
    80006502:	96b2                	add	a3,a3,a2
    80006504:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006508:	6398                	ld	a4,0(a5)
    8000650a:	9732                	add	a4,a4,a2
    8000650c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006510:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006514:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006518:	953e                	add	a0,a0,a5
    8000651a:	4785                	li	a5,1
    8000651c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80006520:	0001d517          	auipc	a0,0x1d
    80006524:	5b050513          	addi	a0,a0,1456 # 80023ad0 <disk+0x18>
    80006528:	ffffc097          	auipc	ra,0xffffc
    8000652c:	0e6080e7          	jalr	230(ra) # 8000260e <wakeup>
}
    80006530:	60a2                	ld	ra,8(sp)
    80006532:	6402                	ld	s0,0(sp)
    80006534:	0141                	addi	sp,sp,16
    80006536:	8082                	ret
    panic("free_desc 1");
    80006538:	00002517          	auipc	a0,0x2
    8000653c:	33850513          	addi	a0,a0,824 # 80008870 <syscalls+0x318>
    80006540:	ffffa097          	auipc	ra,0xffffa
    80006544:	004080e7          	jalr	4(ra) # 80000544 <panic>
    panic("free_desc 2");
    80006548:	00002517          	auipc	a0,0x2
    8000654c:	33850513          	addi	a0,a0,824 # 80008880 <syscalls+0x328>
    80006550:	ffffa097          	auipc	ra,0xffffa
    80006554:	ff4080e7          	jalr	-12(ra) # 80000544 <panic>

0000000080006558 <virtio_disk_init>:
{
    80006558:	1101                	addi	sp,sp,-32
    8000655a:	ec06                	sd	ra,24(sp)
    8000655c:	e822                	sd	s0,16(sp)
    8000655e:	e426                	sd	s1,8(sp)
    80006560:	e04a                	sd	s2,0(sp)
    80006562:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006564:	00002597          	auipc	a1,0x2
    80006568:	32c58593          	addi	a1,a1,812 # 80008890 <syscalls+0x338>
    8000656c:	0001d517          	auipc	a0,0x1d
    80006570:	67450513          	addi	a0,a0,1652 # 80023be0 <disk+0x128>
    80006574:	ffffa097          	auipc	ra,0xffffa
    80006578:	5e6080e7          	jalr	1510(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000657c:	100017b7          	lui	a5,0x10001
    80006580:	4398                	lw	a4,0(a5)
    80006582:	2701                	sext.w	a4,a4
    80006584:	747277b7          	lui	a5,0x74727
    80006588:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000658c:	14f71e63          	bne	a4,a5,800066e8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006590:	100017b7          	lui	a5,0x10001
    80006594:	43dc                	lw	a5,4(a5)
    80006596:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006598:	4709                	li	a4,2
    8000659a:	14e79763          	bne	a5,a4,800066e8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000659e:	100017b7          	lui	a5,0x10001
    800065a2:	479c                	lw	a5,8(a5)
    800065a4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800065a6:	14e79163          	bne	a5,a4,800066e8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800065aa:	100017b7          	lui	a5,0x10001
    800065ae:	47d8                	lw	a4,12(a5)
    800065b0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800065b2:	554d47b7          	lui	a5,0x554d4
    800065b6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800065ba:	12f71763          	bne	a4,a5,800066e8 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    800065be:	100017b7          	lui	a5,0x10001
    800065c2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800065c6:	4705                	li	a4,1
    800065c8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800065ca:	470d                	li	a4,3
    800065cc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800065ce:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800065d0:	c7ffe737          	lui	a4,0xc7ffe
    800065d4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd97e7>
    800065d8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800065da:	2701                	sext.w	a4,a4
    800065dc:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800065de:	472d                	li	a4,11
    800065e0:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800065e2:	0707a903          	lw	s2,112(a5)
    800065e6:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800065e8:	00897793          	andi	a5,s2,8
    800065ec:	10078663          	beqz	a5,800066f8 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800065f0:	100017b7          	lui	a5,0x10001
    800065f4:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800065f8:	43fc                	lw	a5,68(a5)
    800065fa:	2781                	sext.w	a5,a5
    800065fc:	10079663          	bnez	a5,80006708 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006600:	100017b7          	lui	a5,0x10001
    80006604:	5bdc                	lw	a5,52(a5)
    80006606:	2781                	sext.w	a5,a5
  if(max == 0)
    80006608:	10078863          	beqz	a5,80006718 <virtio_disk_init+0x1c0>
  if(max < NUM)
    8000660c:	471d                	li	a4,7
    8000660e:	10f77d63          	bgeu	a4,a5,80006728 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80006612:	ffffa097          	auipc	ra,0xffffa
    80006616:	4e8080e7          	jalr	1256(ra) # 80000afa <kalloc>
    8000661a:	0001d497          	auipc	s1,0x1d
    8000661e:	49e48493          	addi	s1,s1,1182 # 80023ab8 <disk>
    80006622:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006624:	ffffa097          	auipc	ra,0xffffa
    80006628:	4d6080e7          	jalr	1238(ra) # 80000afa <kalloc>
    8000662c:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000662e:	ffffa097          	auipc	ra,0xffffa
    80006632:	4cc080e7          	jalr	1228(ra) # 80000afa <kalloc>
    80006636:	87aa                	mv	a5,a0
    80006638:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    8000663a:	6088                	ld	a0,0(s1)
    8000663c:	cd75                	beqz	a0,80006738 <virtio_disk_init+0x1e0>
    8000663e:	0001d717          	auipc	a4,0x1d
    80006642:	48273703          	ld	a4,1154(a4) # 80023ac0 <disk+0x8>
    80006646:	cb6d                	beqz	a4,80006738 <virtio_disk_init+0x1e0>
    80006648:	cbe5                	beqz	a5,80006738 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    8000664a:	6605                	lui	a2,0x1
    8000664c:	4581                	li	a1,0
    8000664e:	ffffa097          	auipc	ra,0xffffa
    80006652:	698080e7          	jalr	1688(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006656:	0001d497          	auipc	s1,0x1d
    8000665a:	46248493          	addi	s1,s1,1122 # 80023ab8 <disk>
    8000665e:	6605                	lui	a2,0x1
    80006660:	4581                	li	a1,0
    80006662:	6488                	ld	a0,8(s1)
    80006664:	ffffa097          	auipc	ra,0xffffa
    80006668:	682080e7          	jalr	1666(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    8000666c:	6605                	lui	a2,0x1
    8000666e:	4581                	li	a1,0
    80006670:	6888                	ld	a0,16(s1)
    80006672:	ffffa097          	auipc	ra,0xffffa
    80006676:	674080e7          	jalr	1652(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000667a:	100017b7          	lui	a5,0x10001
    8000667e:	4721                	li	a4,8
    80006680:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006682:	4098                	lw	a4,0(s1)
    80006684:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006688:	40d8                	lw	a4,4(s1)
    8000668a:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000668e:	6498                	ld	a4,8(s1)
    80006690:	0007069b          	sext.w	a3,a4
    80006694:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006698:	9701                	srai	a4,a4,0x20
    8000669a:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000669e:	6898                	ld	a4,16(s1)
    800066a0:	0007069b          	sext.w	a3,a4
    800066a4:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800066a8:	9701                	srai	a4,a4,0x20
    800066aa:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800066ae:	4685                	li	a3,1
    800066b0:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    800066b2:	4705                	li	a4,1
    800066b4:	00d48c23          	sb	a3,24(s1)
    800066b8:	00e48ca3          	sb	a4,25(s1)
    800066bc:	00e48d23          	sb	a4,26(s1)
    800066c0:	00e48da3          	sb	a4,27(s1)
    800066c4:	00e48e23          	sb	a4,28(s1)
    800066c8:	00e48ea3          	sb	a4,29(s1)
    800066cc:	00e48f23          	sb	a4,30(s1)
    800066d0:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800066d4:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800066d8:	0727a823          	sw	s2,112(a5)
}
    800066dc:	60e2                	ld	ra,24(sp)
    800066de:	6442                	ld	s0,16(sp)
    800066e0:	64a2                	ld	s1,8(sp)
    800066e2:	6902                	ld	s2,0(sp)
    800066e4:	6105                	addi	sp,sp,32
    800066e6:	8082                	ret
    panic("could not find virtio disk");
    800066e8:	00002517          	auipc	a0,0x2
    800066ec:	1b850513          	addi	a0,a0,440 # 800088a0 <syscalls+0x348>
    800066f0:	ffffa097          	auipc	ra,0xffffa
    800066f4:	e54080e7          	jalr	-428(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    800066f8:	00002517          	auipc	a0,0x2
    800066fc:	1c850513          	addi	a0,a0,456 # 800088c0 <syscalls+0x368>
    80006700:	ffffa097          	auipc	ra,0xffffa
    80006704:	e44080e7          	jalr	-444(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80006708:	00002517          	auipc	a0,0x2
    8000670c:	1d850513          	addi	a0,a0,472 # 800088e0 <syscalls+0x388>
    80006710:	ffffa097          	auipc	ra,0xffffa
    80006714:	e34080e7          	jalr	-460(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80006718:	00002517          	auipc	a0,0x2
    8000671c:	1e850513          	addi	a0,a0,488 # 80008900 <syscalls+0x3a8>
    80006720:	ffffa097          	auipc	ra,0xffffa
    80006724:	e24080e7          	jalr	-476(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    80006728:	00002517          	auipc	a0,0x2
    8000672c:	1f850513          	addi	a0,a0,504 # 80008920 <syscalls+0x3c8>
    80006730:	ffffa097          	auipc	ra,0xffffa
    80006734:	e14080e7          	jalr	-492(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    80006738:	00002517          	auipc	a0,0x2
    8000673c:	20850513          	addi	a0,a0,520 # 80008940 <syscalls+0x3e8>
    80006740:	ffffa097          	auipc	ra,0xffffa
    80006744:	e04080e7          	jalr	-508(ra) # 80000544 <panic>

0000000080006748 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006748:	7159                	addi	sp,sp,-112
    8000674a:	f486                	sd	ra,104(sp)
    8000674c:	f0a2                	sd	s0,96(sp)
    8000674e:	eca6                	sd	s1,88(sp)
    80006750:	e8ca                	sd	s2,80(sp)
    80006752:	e4ce                	sd	s3,72(sp)
    80006754:	e0d2                	sd	s4,64(sp)
    80006756:	fc56                	sd	s5,56(sp)
    80006758:	f85a                	sd	s6,48(sp)
    8000675a:	f45e                	sd	s7,40(sp)
    8000675c:	f062                	sd	s8,32(sp)
    8000675e:	ec66                	sd	s9,24(sp)
    80006760:	e86a                	sd	s10,16(sp)
    80006762:	1880                	addi	s0,sp,112
    80006764:	892a                	mv	s2,a0
    80006766:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006768:	00c52c83          	lw	s9,12(a0)
    8000676c:	001c9c9b          	slliw	s9,s9,0x1
    80006770:	1c82                	slli	s9,s9,0x20
    80006772:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006776:	0001d517          	auipc	a0,0x1d
    8000677a:	46a50513          	addi	a0,a0,1130 # 80023be0 <disk+0x128>
    8000677e:	ffffa097          	auipc	ra,0xffffa
    80006782:	46c080e7          	jalr	1132(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    80006786:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006788:	4ba1                	li	s7,8
      disk.free[i] = 0;
    8000678a:	0001db17          	auipc	s6,0x1d
    8000678e:	32eb0b13          	addi	s6,s6,814 # 80023ab8 <disk>
  for(int i = 0; i < 3; i++){
    80006792:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006794:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006796:	0001dc17          	auipc	s8,0x1d
    8000679a:	44ac0c13          	addi	s8,s8,1098 # 80023be0 <disk+0x128>
    8000679e:	a8b5                	j	8000681a <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    800067a0:	00fb06b3          	add	a3,s6,a5
    800067a4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800067a8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800067aa:	0207c563          	bltz	a5,800067d4 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800067ae:	2485                	addiw	s1,s1,1
    800067b0:	0711                	addi	a4,a4,4
    800067b2:	1f548a63          	beq	s1,s5,800069a6 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    800067b6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800067b8:	0001d697          	auipc	a3,0x1d
    800067bc:	30068693          	addi	a3,a3,768 # 80023ab8 <disk>
    800067c0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800067c2:	0186c583          	lbu	a1,24(a3)
    800067c6:	fde9                	bnez	a1,800067a0 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800067c8:	2785                	addiw	a5,a5,1
    800067ca:	0685                	addi	a3,a3,1
    800067cc:	ff779be3          	bne	a5,s7,800067c2 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800067d0:	57fd                	li	a5,-1
    800067d2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800067d4:	02905a63          	blez	s1,80006808 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800067d8:	f9042503          	lw	a0,-112(s0)
    800067dc:	00000097          	auipc	ra,0x0
    800067e0:	cfa080e7          	jalr	-774(ra) # 800064d6 <free_desc>
      for(int j = 0; j < i; j++)
    800067e4:	4785                	li	a5,1
    800067e6:	0297d163          	bge	a5,s1,80006808 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800067ea:	f9442503          	lw	a0,-108(s0)
    800067ee:	00000097          	auipc	ra,0x0
    800067f2:	ce8080e7          	jalr	-792(ra) # 800064d6 <free_desc>
      for(int j = 0; j < i; j++)
    800067f6:	4789                	li	a5,2
    800067f8:	0097d863          	bge	a5,s1,80006808 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800067fc:	f9842503          	lw	a0,-104(s0)
    80006800:	00000097          	auipc	ra,0x0
    80006804:	cd6080e7          	jalr	-810(ra) # 800064d6 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006808:	85e2                	mv	a1,s8
    8000680a:	0001d517          	auipc	a0,0x1d
    8000680e:	2c650513          	addi	a0,a0,710 # 80023ad0 <disk+0x18>
    80006812:	ffffc097          	auipc	ra,0xffffc
    80006816:	c4c080e7          	jalr	-948(ra) # 8000245e <sleep>
  for(int i = 0; i < 3; i++){
    8000681a:	f9040713          	addi	a4,s0,-112
    8000681e:	84ce                	mv	s1,s3
    80006820:	bf59                	j	800067b6 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006822:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    80006826:	00479693          	slli	a3,a5,0x4
    8000682a:	0001d797          	auipc	a5,0x1d
    8000682e:	28e78793          	addi	a5,a5,654 # 80023ab8 <disk>
    80006832:	97b6                	add	a5,a5,a3
    80006834:	4685                	li	a3,1
    80006836:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006838:	0001d597          	auipc	a1,0x1d
    8000683c:	28058593          	addi	a1,a1,640 # 80023ab8 <disk>
    80006840:	00a60793          	addi	a5,a2,10
    80006844:	0792                	slli	a5,a5,0x4
    80006846:	97ae                	add	a5,a5,a1
    80006848:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    8000684c:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006850:	f6070693          	addi	a3,a4,-160
    80006854:	619c                	ld	a5,0(a1)
    80006856:	97b6                	add	a5,a5,a3
    80006858:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000685a:	6188                	ld	a0,0(a1)
    8000685c:	96aa                	add	a3,a3,a0
    8000685e:	47c1                	li	a5,16
    80006860:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006862:	4785                	li	a5,1
    80006864:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006868:	f9442783          	lw	a5,-108(s0)
    8000686c:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006870:	0792                	slli	a5,a5,0x4
    80006872:	953e                	add	a0,a0,a5
    80006874:	05890693          	addi	a3,s2,88
    80006878:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000687a:	6188                	ld	a0,0(a1)
    8000687c:	97aa                	add	a5,a5,a0
    8000687e:	40000693          	li	a3,1024
    80006882:	c794                	sw	a3,8(a5)
  if(write)
    80006884:	100d0d63          	beqz	s10,8000699e <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006888:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000688c:	00c7d683          	lhu	a3,12(a5)
    80006890:	0016e693          	ori	a3,a3,1
    80006894:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    80006898:	f9842583          	lw	a1,-104(s0)
    8000689c:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800068a0:	0001d697          	auipc	a3,0x1d
    800068a4:	21868693          	addi	a3,a3,536 # 80023ab8 <disk>
    800068a8:	00260793          	addi	a5,a2,2
    800068ac:	0792                	slli	a5,a5,0x4
    800068ae:	97b6                	add	a5,a5,a3
    800068b0:	587d                	li	a6,-1
    800068b2:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800068b6:	0592                	slli	a1,a1,0x4
    800068b8:	952e                	add	a0,a0,a1
    800068ba:	f9070713          	addi	a4,a4,-112
    800068be:	9736                	add	a4,a4,a3
    800068c0:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    800068c2:	6298                	ld	a4,0(a3)
    800068c4:	972e                	add	a4,a4,a1
    800068c6:	4585                	li	a1,1
    800068c8:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800068ca:	4509                	li	a0,2
    800068cc:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    800068d0:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800068d4:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    800068d8:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800068dc:	6698                	ld	a4,8(a3)
    800068de:	00275783          	lhu	a5,2(a4)
    800068e2:	8b9d                	andi	a5,a5,7
    800068e4:	0786                	slli	a5,a5,0x1
    800068e6:	97ba                	add	a5,a5,a4
    800068e8:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    800068ec:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800068f0:	6698                	ld	a4,8(a3)
    800068f2:	00275783          	lhu	a5,2(a4)
    800068f6:	2785                	addiw	a5,a5,1
    800068f8:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800068fc:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006900:	100017b7          	lui	a5,0x10001
    80006904:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006908:	00492703          	lw	a4,4(s2)
    8000690c:	4785                	li	a5,1
    8000690e:	02f71163          	bne	a4,a5,80006930 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    80006912:	0001d997          	auipc	s3,0x1d
    80006916:	2ce98993          	addi	s3,s3,718 # 80023be0 <disk+0x128>
  while(b->disk == 1) {
    8000691a:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000691c:	85ce                	mv	a1,s3
    8000691e:	854a                	mv	a0,s2
    80006920:	ffffc097          	auipc	ra,0xffffc
    80006924:	b3e080e7          	jalr	-1218(ra) # 8000245e <sleep>
  while(b->disk == 1) {
    80006928:	00492783          	lw	a5,4(s2)
    8000692c:	fe9788e3          	beq	a5,s1,8000691c <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    80006930:	f9042903          	lw	s2,-112(s0)
    80006934:	00290793          	addi	a5,s2,2
    80006938:	00479713          	slli	a4,a5,0x4
    8000693c:	0001d797          	auipc	a5,0x1d
    80006940:	17c78793          	addi	a5,a5,380 # 80023ab8 <disk>
    80006944:	97ba                	add	a5,a5,a4
    80006946:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000694a:	0001d997          	auipc	s3,0x1d
    8000694e:	16e98993          	addi	s3,s3,366 # 80023ab8 <disk>
    80006952:	00491713          	slli	a4,s2,0x4
    80006956:	0009b783          	ld	a5,0(s3)
    8000695a:	97ba                	add	a5,a5,a4
    8000695c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006960:	854a                	mv	a0,s2
    80006962:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006966:	00000097          	auipc	ra,0x0
    8000696a:	b70080e7          	jalr	-1168(ra) # 800064d6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000696e:	8885                	andi	s1,s1,1
    80006970:	f0ed                	bnez	s1,80006952 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006972:	0001d517          	auipc	a0,0x1d
    80006976:	26e50513          	addi	a0,a0,622 # 80023be0 <disk+0x128>
    8000697a:	ffffa097          	auipc	ra,0xffffa
    8000697e:	324080e7          	jalr	804(ra) # 80000c9e <release>
}
    80006982:	70a6                	ld	ra,104(sp)
    80006984:	7406                	ld	s0,96(sp)
    80006986:	64e6                	ld	s1,88(sp)
    80006988:	6946                	ld	s2,80(sp)
    8000698a:	69a6                	ld	s3,72(sp)
    8000698c:	6a06                	ld	s4,64(sp)
    8000698e:	7ae2                	ld	s5,56(sp)
    80006990:	7b42                	ld	s6,48(sp)
    80006992:	7ba2                	ld	s7,40(sp)
    80006994:	7c02                	ld	s8,32(sp)
    80006996:	6ce2                	ld	s9,24(sp)
    80006998:	6d42                	ld	s10,16(sp)
    8000699a:	6165                	addi	sp,sp,112
    8000699c:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000699e:	4689                	li	a3,2
    800069a0:	00d79623          	sh	a3,12(a5)
    800069a4:	b5e5                	j	8000688c <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800069a6:	f9042603          	lw	a2,-112(s0)
    800069aa:	00a60713          	addi	a4,a2,10
    800069ae:	0712                	slli	a4,a4,0x4
    800069b0:	0001d517          	auipc	a0,0x1d
    800069b4:	11050513          	addi	a0,a0,272 # 80023ac0 <disk+0x8>
    800069b8:	953a                	add	a0,a0,a4
  if(write)
    800069ba:	e60d14e3          	bnez	s10,80006822 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800069be:	00a60793          	addi	a5,a2,10
    800069c2:	00479693          	slli	a3,a5,0x4
    800069c6:	0001d797          	auipc	a5,0x1d
    800069ca:	0f278793          	addi	a5,a5,242 # 80023ab8 <disk>
    800069ce:	97b6                	add	a5,a5,a3
    800069d0:	0007a423          	sw	zero,8(a5)
    800069d4:	b595                	j	80006838 <virtio_disk_rw+0xf0>

00000000800069d6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800069d6:	1101                	addi	sp,sp,-32
    800069d8:	ec06                	sd	ra,24(sp)
    800069da:	e822                	sd	s0,16(sp)
    800069dc:	e426                	sd	s1,8(sp)
    800069de:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800069e0:	0001d497          	auipc	s1,0x1d
    800069e4:	0d848493          	addi	s1,s1,216 # 80023ab8 <disk>
    800069e8:	0001d517          	auipc	a0,0x1d
    800069ec:	1f850513          	addi	a0,a0,504 # 80023be0 <disk+0x128>
    800069f0:	ffffa097          	auipc	ra,0xffffa
    800069f4:	1fa080e7          	jalr	506(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800069f8:	10001737          	lui	a4,0x10001
    800069fc:	533c                	lw	a5,96(a4)
    800069fe:	8b8d                	andi	a5,a5,3
    80006a00:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006a02:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006a06:	689c                	ld	a5,16(s1)
    80006a08:	0204d703          	lhu	a4,32(s1)
    80006a0c:	0027d783          	lhu	a5,2(a5)
    80006a10:	04f70863          	beq	a4,a5,80006a60 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006a14:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006a18:	6898                	ld	a4,16(s1)
    80006a1a:	0204d783          	lhu	a5,32(s1)
    80006a1e:	8b9d                	andi	a5,a5,7
    80006a20:	078e                	slli	a5,a5,0x3
    80006a22:	97ba                	add	a5,a5,a4
    80006a24:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006a26:	00278713          	addi	a4,a5,2
    80006a2a:	0712                	slli	a4,a4,0x4
    80006a2c:	9726                	add	a4,a4,s1
    80006a2e:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006a32:	e721                	bnez	a4,80006a7a <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006a34:	0789                	addi	a5,a5,2
    80006a36:	0792                	slli	a5,a5,0x4
    80006a38:	97a6                	add	a5,a5,s1
    80006a3a:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006a3c:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006a40:	ffffc097          	auipc	ra,0xffffc
    80006a44:	bce080e7          	jalr	-1074(ra) # 8000260e <wakeup>

    disk.used_idx += 1;
    80006a48:	0204d783          	lhu	a5,32(s1)
    80006a4c:	2785                	addiw	a5,a5,1
    80006a4e:	17c2                	slli	a5,a5,0x30
    80006a50:	93c1                	srli	a5,a5,0x30
    80006a52:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006a56:	6898                	ld	a4,16(s1)
    80006a58:	00275703          	lhu	a4,2(a4)
    80006a5c:	faf71ce3          	bne	a4,a5,80006a14 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006a60:	0001d517          	auipc	a0,0x1d
    80006a64:	18050513          	addi	a0,a0,384 # 80023be0 <disk+0x128>
    80006a68:	ffffa097          	auipc	ra,0xffffa
    80006a6c:	236080e7          	jalr	566(ra) # 80000c9e <release>
}
    80006a70:	60e2                	ld	ra,24(sp)
    80006a72:	6442                	ld	s0,16(sp)
    80006a74:	64a2                	ld	s1,8(sp)
    80006a76:	6105                	addi	sp,sp,32
    80006a78:	8082                	ret
      panic("virtio_disk_intr status");
    80006a7a:	00002517          	auipc	a0,0x2
    80006a7e:	ede50513          	addi	a0,a0,-290 # 80008958 <syscalls+0x400>
    80006a82:	ffffa097          	auipc	ra,0xffffa
    80006a86:	ac2080e7          	jalr	-1342(ra) # 80000544 <panic>

0000000080006a8a <sgenrand>:
static int mti=N+1; /* mti==N+1 means mt[N] is not initialized */

/* initializing the array with a NONZERO seed */
void
sgenrand(unsigned long seed)
{
    80006a8a:	1141                	addi	sp,sp,-16
    80006a8c:	e422                	sd	s0,8(sp)
    80006a8e:	0800                	addi	s0,sp,16
    /* setting initial seeds to mt[N] using         */
    /* the generator Line 25 of Table 1 in          */
    /* [KNUTH 1981, The Art of Computer Programming */
    /*    Vol. 2 (2nd Ed.), pp102]                  */
    mt[0]= seed & 0xffffffff;
    80006a90:	0001d717          	auipc	a4,0x1d
    80006a94:	16870713          	addi	a4,a4,360 # 80023bf8 <mt>
    80006a98:	1502                	slli	a0,a0,0x20
    80006a9a:	9101                	srli	a0,a0,0x20
    80006a9c:	e308                	sd	a0,0(a4)
    for (mti=1; mti<N; mti++)
    80006a9e:	0001e597          	auipc	a1,0x1e
    80006aa2:	4d258593          	addi	a1,a1,1234 # 80024f70 <mt+0x1378>
        mt[mti] = (69069 * mt[mti-1]) & 0xffffffff;
    80006aa6:	6645                	lui	a2,0x11
    80006aa8:	dcd60613          	addi	a2,a2,-563 # 10dcd <_entry-0x7ffef233>
    80006aac:	56fd                	li	a3,-1
    80006aae:	9281                	srli	a3,a3,0x20
    80006ab0:	631c                	ld	a5,0(a4)
    80006ab2:	02c787b3          	mul	a5,a5,a2
    80006ab6:	8ff5                	and	a5,a5,a3
    80006ab8:	e71c                	sd	a5,8(a4)
    for (mti=1; mti<N; mti++)
    80006aba:	0721                	addi	a4,a4,8
    80006abc:	feb71ae3          	bne	a4,a1,80006ab0 <sgenrand+0x26>
    80006ac0:	27000793          	li	a5,624
    80006ac4:	00002717          	auipc	a4,0x2
    80006ac8:	ecf72223          	sw	a5,-316(a4) # 80008988 <mti>
}
    80006acc:	6422                	ld	s0,8(sp)
    80006ace:	0141                	addi	sp,sp,16
    80006ad0:	8082                	ret

0000000080006ad2 <genrand>:

long /* for integer generation */
genrand()
{
    80006ad2:	1141                	addi	sp,sp,-16
    80006ad4:	e406                	sd	ra,8(sp)
    80006ad6:	e022                	sd	s0,0(sp)
    80006ad8:	0800                	addi	s0,sp,16
    unsigned long y;
    static unsigned long mag01[2]={0x0, MATRIX_A};
    /* mag01[x] = x * MATRIX_A  for x=0,1 */

    if (mti >= N) { /* generate N words at one time */
    80006ada:	00002797          	auipc	a5,0x2
    80006ade:	eae7a783          	lw	a5,-338(a5) # 80008988 <mti>
    80006ae2:	26f00713          	li	a4,623
    80006ae6:	0ef75963          	bge	a4,a5,80006bd8 <genrand+0x106>
        int kk;

        if (mti == N+1)   /* if sgenrand() has not been called, */
    80006aea:	27100713          	li	a4,625
    80006aee:	12e78f63          	beq	a5,a4,80006c2c <genrand+0x15a>
            sgenrand(4357); /* a default initial seed is used   */

        for (kk=0;kk<N-M;kk++) {
    80006af2:	0001d817          	auipc	a6,0x1d
    80006af6:	10680813          	addi	a6,a6,262 # 80023bf8 <mt>
    80006afa:	0001ee17          	auipc	t3,0x1e
    80006afe:	816e0e13          	addi	t3,t3,-2026 # 80024310 <mt+0x718>
{
    80006b02:	8742                	mv	a4,a6
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    80006b04:	4885                	li	a7,1
    80006b06:	08fe                	slli	a7,a7,0x1f
    80006b08:	80000537          	lui	a0,0x80000
    80006b0c:	fff54513          	not	a0,a0
            mt[kk] = mt[kk+M] ^ (y >> 1) ^ mag01[y & 0x1];
    80006b10:	6585                	lui	a1,0x1
    80006b12:	c6858593          	addi	a1,a1,-920 # c68 <_entry-0x7ffff398>
    80006b16:	00002317          	auipc	t1,0x2
    80006b1a:	e5a30313          	addi	t1,t1,-422 # 80008970 <mag01.985>
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    80006b1e:	631c                	ld	a5,0(a4)
    80006b20:	0117f7b3          	and	a5,a5,a7
    80006b24:	6714                	ld	a3,8(a4)
    80006b26:	8ee9                	and	a3,a3,a0
    80006b28:	8fd5                	or	a5,a5,a3
            mt[kk] = mt[kk+M] ^ (y >> 1) ^ mag01[y & 0x1];
    80006b2a:	00b70633          	add	a2,a4,a1
    80006b2e:	0017d693          	srli	a3,a5,0x1
    80006b32:	6210                	ld	a2,0(a2)
    80006b34:	8eb1                	xor	a3,a3,a2
    80006b36:	8b85                	andi	a5,a5,1
    80006b38:	078e                	slli	a5,a5,0x3
    80006b3a:	979a                	add	a5,a5,t1
    80006b3c:	639c                	ld	a5,0(a5)
    80006b3e:	8fb5                	xor	a5,a5,a3
    80006b40:	e31c                	sd	a5,0(a4)
        for (kk=0;kk<N-M;kk++) {
    80006b42:	0721                	addi	a4,a4,8
    80006b44:	fdc71de3          	bne	a4,t3,80006b1e <genrand+0x4c>
        }
        for (;kk<N-1;kk++) {
    80006b48:	6605                	lui	a2,0x1
    80006b4a:	c6060613          	addi	a2,a2,-928 # c60 <_entry-0x7ffff3a0>
    80006b4e:	9642                	add	a2,a2,a6
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    80006b50:	4505                	li	a0,1
    80006b52:	057e                	slli	a0,a0,0x1f
    80006b54:	800005b7          	lui	a1,0x80000
    80006b58:	fff5c593          	not	a1,a1
            mt[kk] = mt[kk+(M-N)] ^ (y >> 1) ^ mag01[y & 0x1];
    80006b5c:	00002897          	auipc	a7,0x2
    80006b60:	e1488893          	addi	a7,a7,-492 # 80008970 <mag01.985>
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    80006b64:	71883783          	ld	a5,1816(a6)
    80006b68:	8fe9                	and	a5,a5,a0
    80006b6a:	72083703          	ld	a4,1824(a6)
    80006b6e:	8f6d                	and	a4,a4,a1
    80006b70:	8fd9                	or	a5,a5,a4
            mt[kk] = mt[kk+(M-N)] ^ (y >> 1) ^ mag01[y & 0x1];
    80006b72:	0017d713          	srli	a4,a5,0x1
    80006b76:	00083683          	ld	a3,0(a6)
    80006b7a:	8f35                	xor	a4,a4,a3
    80006b7c:	8b85                	andi	a5,a5,1
    80006b7e:	078e                	slli	a5,a5,0x3
    80006b80:	97c6                	add	a5,a5,a7
    80006b82:	639c                	ld	a5,0(a5)
    80006b84:	8fb9                	xor	a5,a5,a4
    80006b86:	70f83c23          	sd	a5,1816(a6)
        for (;kk<N-1;kk++) {
    80006b8a:	0821                	addi	a6,a6,8
    80006b8c:	fcc81ce3          	bne	a6,a2,80006b64 <genrand+0x92>
        }
        y = (mt[N-1]&UPPER_MASK)|(mt[0]&LOWER_MASK);
    80006b90:	0001e697          	auipc	a3,0x1e
    80006b94:	06868693          	addi	a3,a3,104 # 80024bf8 <mt+0x1000>
    80006b98:	3786b783          	ld	a5,888(a3)
    80006b9c:	4705                	li	a4,1
    80006b9e:	077e                	slli	a4,a4,0x1f
    80006ba0:	8ff9                	and	a5,a5,a4
    80006ba2:	0001d717          	auipc	a4,0x1d
    80006ba6:	05673703          	ld	a4,86(a4) # 80023bf8 <mt>
    80006baa:	1706                	slli	a4,a4,0x21
    80006bac:	9305                	srli	a4,a4,0x21
    80006bae:	8fd9                	or	a5,a5,a4
        mt[N-1] = mt[M-1] ^ (y >> 1) ^ mag01[y & 0x1];
    80006bb0:	0017d713          	srli	a4,a5,0x1
    80006bb4:	c606b603          	ld	a2,-928(a3)
    80006bb8:	8f31                	xor	a4,a4,a2
    80006bba:	8b85                	andi	a5,a5,1
    80006bbc:	078e                	slli	a5,a5,0x3
    80006bbe:	00002617          	auipc	a2,0x2
    80006bc2:	db260613          	addi	a2,a2,-590 # 80008970 <mag01.985>
    80006bc6:	97b2                	add	a5,a5,a2
    80006bc8:	639c                	ld	a5,0(a5)
    80006bca:	8fb9                	xor	a5,a5,a4
    80006bcc:	36f6bc23          	sd	a5,888(a3)

        mti = 0;
    80006bd0:	00002797          	auipc	a5,0x2
    80006bd4:	da07ac23          	sw	zero,-584(a5) # 80008988 <mti>
    }
  
    y = mt[mti++];
    80006bd8:	00002717          	auipc	a4,0x2
    80006bdc:	db070713          	addi	a4,a4,-592 # 80008988 <mti>
    80006be0:	431c                	lw	a5,0(a4)
    80006be2:	0017869b          	addiw	a3,a5,1
    80006be6:	c314                	sw	a3,0(a4)
    80006be8:	078e                	slli	a5,a5,0x3
    80006bea:	0001d717          	auipc	a4,0x1d
    80006bee:	00e70713          	addi	a4,a4,14 # 80023bf8 <mt>
    80006bf2:	97ba                	add	a5,a5,a4
    80006bf4:	6398                	ld	a4,0(a5)
    y ^= TEMPERING_SHIFT_U(y);
    80006bf6:	00b75793          	srli	a5,a4,0xb
    80006bfa:	8f3d                	xor	a4,a4,a5
    y ^= TEMPERING_SHIFT_S(y) & TEMPERING_MASK_B;
    80006bfc:	013a67b7          	lui	a5,0x13a6
    80006c00:	8ad78793          	addi	a5,a5,-1875 # 13a58ad <_entry-0x7ec5a753>
    80006c04:	8ff9                	and	a5,a5,a4
    80006c06:	079e                	slli	a5,a5,0x7
    80006c08:	8fb9                	xor	a5,a5,a4
    y ^= TEMPERING_SHIFT_T(y) & TEMPERING_MASK_C;
    80006c0a:	00f79713          	slli	a4,a5,0xf
    80006c0e:	077e36b7          	lui	a3,0x77e3
    80006c12:	0696                	slli	a3,a3,0x5
    80006c14:	8f75                	and	a4,a4,a3
    80006c16:	8fb9                	xor	a5,a5,a4
    y ^= TEMPERING_SHIFT_L(y);
    80006c18:	0127d513          	srli	a0,a5,0x12
    80006c1c:	8fa9                	xor	a5,a5,a0

    // Strip off uppermost bit because we want a long,
    // not an unsigned long
    return y & RAND_MAX;
    80006c1e:	02179513          	slli	a0,a5,0x21
}
    80006c22:	9105                	srli	a0,a0,0x21
    80006c24:	60a2                	ld	ra,8(sp)
    80006c26:	6402                	ld	s0,0(sp)
    80006c28:	0141                	addi	sp,sp,16
    80006c2a:	8082                	ret
            sgenrand(4357); /* a default initial seed is used   */
    80006c2c:	6505                	lui	a0,0x1
    80006c2e:	10550513          	addi	a0,a0,261 # 1105 <_entry-0x7fffeefb>
    80006c32:	00000097          	auipc	ra,0x0
    80006c36:	e58080e7          	jalr	-424(ra) # 80006a8a <sgenrand>
    80006c3a:	bd65                	j	80006af2 <genrand+0x20>

0000000080006c3c <random_at_most>:

// Assumes 0 <= max <= RAND_MAX
// Returns in the half-open interval [0, max]
long random_at_most(long max) {
    80006c3c:	1101                	addi	sp,sp,-32
    80006c3e:	ec06                	sd	ra,24(sp)
    80006c40:	e822                	sd	s0,16(sp)
    80006c42:	e426                	sd	s1,8(sp)
    80006c44:	e04a                	sd	s2,0(sp)
    80006c46:	1000                	addi	s0,sp,32
  unsigned long
    // max <= RAND_MAX < ULONG_MAX, so this is okay.
    num_bins = (unsigned long) max + 1,
    80006c48:	0505                	addi	a0,a0,1
    num_rand = (unsigned long) RAND_MAX + 1,
    bin_size = num_rand / num_bins,
    80006c4a:	4485                	li	s1,1
    80006c4c:	04fe                	slli	s1,s1,0x1f
    80006c4e:	02a4d933          	divu	s2,s1,a0
    defect   = num_rand % num_bins;
    80006c52:	02a4f533          	remu	a0,s1,a0
  long x;
  do {
   x = genrand();
  }
  // This is carefully written not to overflow
  while (num_rand - defect <= (unsigned long)x);
    80006c56:	4485                	li	s1,1
    80006c58:	04fe                	slli	s1,s1,0x1f
    80006c5a:	8c89                	sub	s1,s1,a0
   x = genrand();
    80006c5c:	00000097          	auipc	ra,0x0
    80006c60:	e76080e7          	jalr	-394(ra) # 80006ad2 <genrand>
  while (num_rand - defect <= (unsigned long)x);
    80006c64:	fe957ce3          	bgeu	a0,s1,80006c5c <random_at_most+0x20>

  // Truncated division is intentional
  return x/bin_size;
    80006c68:	03255533          	divu	a0,a0,s2
    80006c6c:	60e2                	ld	ra,24(sp)
    80006c6e:	6442                	ld	s0,16(sp)
    80006c70:	64a2                	ld	s1,8(sp)
    80006c72:	6902                	ld	s2,0(sp)
    80006c74:	6105                	addi	sp,sp,32
    80006c76:	8082                	ret
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
