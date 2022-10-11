
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	aa013103          	ld	sp,-1376(sp) # 80008aa0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

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
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	ab070713          	addi	a4,a4,-1360 # 80008b00 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	efe78793          	addi	a5,a5,-258 # 80005f60 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffda30f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dcc78793          	addi	a5,a5,-564 # 80000e78 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	4d8080e7          	jalr	1240(ra) # 80002602 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
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
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	ab650513          	addi	a0,a0,-1354 # 80010c40 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	aa648493          	addi	s1,s1,-1370 # 80010c40 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	b3690913          	addi	s2,s2,-1226 # 80010cd8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	284080e7          	jalr	644(ra) # 8000244c <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	fce080e7          	jalr	-50(ra) # 800021a4 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	39a080e7          	jalr	922(ra) # 800025ac <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	a1a50513          	addi	a0,a0,-1510 # 80010c40 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	a0450513          	addi	a0,a0,-1532 # 80010c40 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	a6f72323          	sw	a5,-1434(a4) # 80010cd8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	97450513          	addi	a0,a0,-1676 # 80010c40 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	366080e7          	jalr	870(ra) # 80002658 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	94650513          	addi	a0,a0,-1722 # 80010c40 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	92270713          	addi	a4,a4,-1758 # 80010c40 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	8f878793          	addi	a5,a5,-1800 # 80010c40 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	9627a783          	lw	a5,-1694(a5) # 80010cd8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	8b670713          	addi	a4,a4,-1866 # 80010c40 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	8a648493          	addi	s1,s1,-1882 # 80010c40 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	86a70713          	addi	a4,a4,-1942 # 80010c40 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	8ef72a23          	sw	a5,-1804(a4) # 80010ce0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	82e78793          	addi	a5,a5,-2002 # 80010c40 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	8ac7a323          	sw	a2,-1882(a5) # 80010cdc <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	89a50513          	addi	a0,a0,-1894 # 80010cd8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	dc2080e7          	jalr	-574(ra) # 80002208 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	7e050513          	addi	a0,a0,2016 # 80010c40 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00022797          	auipc	a5,0x22
    8000047c:	b6078793          	addi	a5,a5,-1184 # 80021fd8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	7a07aa23          	sw	zero,1972(a5) # 80010d00 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	54f72023          	sw	a5,1344(a4) # 80008ac0 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	744dad83          	lw	s11,1860(s11) # 80010d00 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	6ee50513          	addi	a0,a0,1774 # 80010ce8 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	59050513          	addi	a0,a0,1424 # 80010ce8 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	52a080e7          	jalr	1322(ra) # 80000c8a <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	57448493          	addi	s1,s1,1396 # 80010ce8 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3c0080e7          	jalr	960(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	53450513          	addi	a0,a0,1332 # 80010d08 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	36a080e7          	jalr	874(ra) # 80000b46 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	392080e7          	jalr	914(ra) # 80000b8a <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	2c07a783          	lw	a5,704(a5) # 80008ac0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	404080e7          	jalr	1028(ra) # 80000c2a <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	2907b783          	ld	a5,656(a5) # 80008ac8 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	29073703          	ld	a4,656(a4) # 80008ad0 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	4a6a0a13          	addi	s4,s4,1190 # 80010d08 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	25e48493          	addi	s1,s1,606 # 80008ac8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	25e98993          	addi	s3,s3,606 # 80008ad0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	974080e7          	jalr	-1676(ra) # 80002208 <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	43850513          	addi	a0,a0,1080 # 80010d08 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	1e07a783          	lw	a5,480(a5) # 80008ac0 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	1e673703          	ld	a4,486(a4) # 80008ad0 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	1d67b783          	ld	a5,470(a5) # 80008ac8 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	40a98993          	addi	s3,s3,1034 # 80010d08 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	1c248493          	addi	s1,s1,450 # 80008ac8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	1c290913          	addi	s2,s2,450 # 80008ad0 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	886080e7          	jalr	-1914(ra) # 800021a4 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	3d448493          	addi	s1,s1,980 # 80010d08 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	18e7b423          	sd	a4,392(a5) # 80008ad0 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	34e48493          	addi	s1,s1,846 # 80010d08 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2b4080e7          	jalr	692(ra) # 80000c8a <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00024797          	auipc	a5,0x24
    80000a00:	af478793          	addi	a5,a5,-1292 # 800244f0 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2be080e7          	jalr	702(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	32490913          	addi	s2,s2,804 # 80010d40 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	28650513          	addi	a0,a0,646 # 80010d40 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00024517          	auipc	a0,0x24
    80000ad2:	a2250513          	addi	a0,a0,-1502 # 800244f0 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	25048493          	addi	s1,s1,592 # 80010d40 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	23850513          	addi	a0,a0,568 # 80010d40 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	20c50513          	addi	a0,a0,524 # 80010d40 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	876080e7          	jalr	-1930(ra) # 80000540 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdab11>
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	40d707bb          	subw	a5,a4,a3
    80000e0c:	37fd                	addiw	a5,a5,-1
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	c5070713          	addi	a4,a4,-944 # 80008ad8 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	9c6080e7          	jalr	-1594(ra) # 80002884 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	0da080e7          	jalr	218(ra) # 80005fa0 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	064080e7          	jalr	100(ra) # 80001f32 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67c080e7          	jalr	1660(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	926080e7          	jalr	-1754(ra) # 8000285c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	946080e7          	jalr	-1722(ra) # 80002884 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	044080e7          	jalr	68(ra) # 80005f8a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	052080e7          	jalr	82(ra) # 80005fa0 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	1ee080e7          	jalr	494(ra) # 80003144 <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	88e080e7          	jalr	-1906(ra) # 800037ec <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	834080e7          	jalr	-1996(ra) # 8000479a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	13a080e7          	jalr	314(ra) # 800060a8 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d3e080e7          	jalr	-706(ra) # 80001cb4 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	b4f72a23          	sw	a5,-1196(a4) # 80008ad8 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	b487b783          	ld	a5,-1208(a5) # 80008ae0 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55c080e7          	jalr	1372(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdab07>
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	83a9                	srli	a5,a5,0xa
    80001094:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	777d                	lui	a4,0xfffff
    800010bc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	fff58993          	addi	s3,a1,-1
    800010c4:	99b2                	add	s3,s3,a2
    800010c6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ca:	893e                	mv	s2,a5
    800010cc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3da080e7          	jalr	986(ra) # 80000540 <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00008797          	auipc	a5,0x8
    80001258:	88a7b623          	sd	a0,-1908(a5) # 80008ae0 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6ca080e7          	jalr	1738(ra) # 800009e8 <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	180080e7          	jalr	384(ra) # 80000540 <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	76fd                	lui	a3,0xfffff
    800013e4:	8f75                	and	a4,a4,a3
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff5                	and	a5,a5,a3
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6785                	lui	a5,0x1
    8000142e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001430:	95be                	add	a1,a1,a5
    80001432:	77fd                	lui	a5,0xfffff
    80001434:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	548080e7          	jalr	1352(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a829                	j	800014f6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014e0:	00c79513          	slli	a0,a5,0xc
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	fde080e7          	jalr	-34(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f0:	04a1                	addi	s1,s1,8
    800014f2:	03248163          	beq	s1,s2,80001514 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f8:	00f7f713          	andi	a4,a5,15
    800014fc:	ff3701e3          	beq	a4,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001500:	8b85                	andi	a5,a5,1
    80001502:	d7fd                	beqz	a5,800014f0 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001504:	00007517          	auipc	a0,0x7
    80001508:	c7450513          	addi	a0,a0,-908 # 80008178 <digits+0x138>
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	034080e7          	jalr	52(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001514:	8552                	mv	a0,s4
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	4d2080e7          	jalr	1234(ra) # 800009e8 <kfree>
}
    8000151e:	70a2                	ld	ra,40(sp)
    80001520:	7402                	ld	s0,32(sp)
    80001522:	64e2                	ld	s1,24(sp)
    80001524:	6942                	ld	s2,16(sp)
    80001526:	69a2                	ld	s3,8(sp)
    80001528:	6a02                	ld	s4,0(sp)
    8000152a:	6145                	addi	sp,sp,48
    8000152c:	8082                	ret

000000008000152e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152e:	1101                	addi	sp,sp,-32
    80001530:	ec06                	sd	ra,24(sp)
    80001532:	e822                	sd	s0,16(sp)
    80001534:	e426                	sd	s1,8(sp)
    80001536:	1000                	addi	s0,sp,32
    80001538:	84aa                	mv	s1,a0
  if(sz > 0)
    8000153a:	e999                	bnez	a1,80001550 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153c:	8526                	mv	a0,s1
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f84080e7          	jalr	-124(ra) # 800014c2 <freewalk>
}
    80001546:	60e2                	ld	ra,24(sp)
    80001548:	6442                	ld	s0,16(sp)
    8000154a:	64a2                	ld	s1,8(sp)
    8000154c:	6105                	addi	sp,sp,32
    8000154e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001550:	6785                	lui	a5,0x1
    80001552:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001554:	95be                	add	a1,a1,a5
    80001556:	4685                	li	a3,1
    80001558:	00c5d613          	srli	a2,a1,0xc
    8000155c:	4581                	li	a1,0
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	d06080e7          	jalr	-762(ra) # 80001264 <uvmunmap>
    80001566:	bfd9                	j	8000153c <uvmfree+0xe>

0000000080001568 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001568:	c679                	beqz	a2,80001636 <uvmcopy+0xce>
{
    8000156a:	715d                	addi	sp,sp,-80
    8000156c:	e486                	sd	ra,72(sp)
    8000156e:	e0a2                	sd	s0,64(sp)
    80001570:	fc26                	sd	s1,56(sp)
    80001572:	f84a                	sd	s2,48(sp)
    80001574:	f44e                	sd	s3,40(sp)
    80001576:	f052                	sd	s4,32(sp)
    80001578:	ec56                	sd	s5,24(sp)
    8000157a:	e85a                	sd	s6,16(sp)
    8000157c:	e45e                	sd	s7,8(sp)
    8000157e:	0880                	addi	s0,sp,80
    80001580:	8b2a                	mv	s6,a0
    80001582:	8aae                	mv	s5,a1
    80001584:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001586:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001588:	4601                	li	a2,0
    8000158a:	85ce                	mv	a1,s3
    8000158c:	855a                	mv	a0,s6
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	a28080e7          	jalr	-1496(ra) # 80000fb6 <walk>
    80001596:	c531                	beqz	a0,800015e2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001598:	6118                	ld	a4,0(a0)
    8000159a:	00177793          	andi	a5,a4,1
    8000159e:	cbb1                	beqz	a5,800015f2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a0:	00a75593          	srli	a1,a4,0xa
    800015a4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	53a080e7          	jalr	1338(ra) # 80000ae6 <kalloc>
    800015b4:	892a                	mv	s2,a0
    800015b6:	c939                	beqz	a0,8000160c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	85de                	mv	a1,s7
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	772080e7          	jalr	1906(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c4:	8726                	mv	a4,s1
    800015c6:	86ca                	mv	a3,s2
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85ce                	mv	a1,s3
    800015cc:	8556                	mv	a0,s5
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	ad0080e7          	jalr	-1328(ra) # 8000109e <mappages>
    800015d6:	e515                	bnez	a0,80001602 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d8:	6785                	lui	a5,0x1
    800015da:	99be                	add	s3,s3,a5
    800015dc:	fb49e6e3          	bltu	s3,s4,80001588 <uvmcopy+0x20>
    800015e0:	a081                	j	80001620 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e2:	00007517          	auipc	a0,0x7
    800015e6:	ba650513          	addi	a0,a0,-1114 # 80008188 <digits+0x148>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	bb650513          	addi	a0,a0,-1098 # 800081a8 <digits+0x168>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>
      kfree(mem);
    80001602:	854a                	mv	a0,s2
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	3e4080e7          	jalr	996(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000160c:	4685                	li	a3,1
    8000160e:	00c9d613          	srli	a2,s3,0xc
    80001612:	4581                	li	a1,0
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	c4e080e7          	jalr	-946(ra) # 80001264 <uvmunmap>
  return -1;
    8000161e:	557d                	li	a0,-1
}
    80001620:	60a6                	ld	ra,72(sp)
    80001622:	6406                	ld	s0,64(sp)
    80001624:	74e2                	ld	s1,56(sp)
    80001626:	7942                	ld	s2,48(sp)
    80001628:	79a2                	ld	s3,40(sp)
    8000162a:	7a02                	ld	s4,32(sp)
    8000162c:	6ae2                	ld	s5,24(sp)
    8000162e:	6b42                	ld	s6,16(sp)
    80001630:	6ba2                	ld	s7,8(sp)
    80001632:	6161                	addi	sp,sp,80
    80001634:	8082                	ret
  return 0;
    80001636:	4501                	li	a0,0
}
    80001638:	8082                	ret

000000008000163a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163a:	1141                	addi	sp,sp,-16
    8000163c:	e406                	sd	ra,8(sp)
    8000163e:	e022                	sd	s0,0(sp)
    80001640:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001642:	4601                	li	a2,0
    80001644:	00000097          	auipc	ra,0x0
    80001648:	972080e7          	jalr	-1678(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000164c:	c901                	beqz	a0,8000165c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164e:	611c                	ld	a5,0(a0)
    80001650:	9bbd                	andi	a5,a5,-17
    80001652:	e11c                	sd	a5,0(a0)
}
    80001654:	60a2                	ld	ra,8(sp)
    80001656:	6402                	ld	s0,0(sp)
    80001658:	0141                	addi	sp,sp,16
    8000165a:	8082                	ret
    panic("uvmclear");
    8000165c:	00007517          	auipc	a0,0x7
    80001660:	b6c50513          	addi	a0,a0,-1172 # 800081c8 <digits+0x188>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	edc080e7          	jalr	-292(ra) # 80000540 <panic>

000000008000166c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000166c:	c6bd                	beqz	a3,800016da <copyout+0x6e>
{
    8000166e:	715d                	addi	sp,sp,-80
    80001670:	e486                	sd	ra,72(sp)
    80001672:	e0a2                	sd	s0,64(sp)
    80001674:	fc26                	sd	s1,56(sp)
    80001676:	f84a                	sd	s2,48(sp)
    80001678:	f44e                	sd	s3,40(sp)
    8000167a:	f052                	sd	s4,32(sp)
    8000167c:	ec56                	sd	s5,24(sp)
    8000167e:	e85a                	sd	s6,16(sp)
    80001680:	e45e                	sd	s7,8(sp)
    80001682:	e062                	sd	s8,0(sp)
    80001684:	0880                	addi	s0,sp,80
    80001686:	8b2a                	mv	s6,a0
    80001688:	8c2e                	mv	s8,a1
    8000168a:	8a32                	mv	s4,a2
    8000168c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001690:	6a85                	lui	s5,0x1
    80001692:	a015                	j	800016b6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001694:	9562                	add	a0,a0,s8
    80001696:	0004861b          	sext.w	a2,s1
    8000169a:	85d2                	mv	a1,s4
    8000169c:	41250533          	sub	a0,a0,s2
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	68e080e7          	jalr	1678(ra) # 80000d2e <memmove>

    len -= n;
    800016a8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ac:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ae:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b2:	02098263          	beqz	s3,800016d6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ba:	85ca                	mv	a1,s2
    800016bc:	855a                	mv	a0,s6
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	99e080e7          	jalr	-1634(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c6:	cd01                	beqz	a0,800016de <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c8:	418904b3          	sub	s1,s2,s8
    800016cc:	94d6                	add	s1,s1,s5
    800016ce:	fc99f3e3          	bgeu	s3,s1,80001694 <copyout+0x28>
    800016d2:	84ce                	mv	s1,s3
    800016d4:	b7c1                	j	80001694 <copyout+0x28>
  }
  return 0;
    800016d6:	4501                	li	a0,0
    800016d8:	a021                	j	800016e0 <copyout+0x74>
    800016da:	4501                	li	a0,0
}
    800016dc:	8082                	ret
      return -1;
    800016de:	557d                	li	a0,-1
}
    800016e0:	60a6                	ld	ra,72(sp)
    800016e2:	6406                	ld	s0,64(sp)
    800016e4:	74e2                	ld	s1,56(sp)
    800016e6:	7942                	ld	s2,48(sp)
    800016e8:	79a2                	ld	s3,40(sp)
    800016ea:	7a02                	ld	s4,32(sp)
    800016ec:	6ae2                	ld	s5,24(sp)
    800016ee:	6b42                	ld	s6,16(sp)
    800016f0:	6ba2                	ld	s7,8(sp)
    800016f2:	6c02                	ld	s8,0(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret

00000000800016f8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f8:	caa5                	beqz	a3,80001768 <copyin+0x70>
{
    800016fa:	715d                	addi	sp,sp,-80
    800016fc:	e486                	sd	ra,72(sp)
    800016fe:	e0a2                	sd	s0,64(sp)
    80001700:	fc26                	sd	s1,56(sp)
    80001702:	f84a                	sd	s2,48(sp)
    80001704:	f44e                	sd	s3,40(sp)
    80001706:	f052                	sd	s4,32(sp)
    80001708:	ec56                	sd	s5,24(sp)
    8000170a:	e85a                	sd	s6,16(sp)
    8000170c:	e45e                	sd	s7,8(sp)
    8000170e:	e062                	sd	s8,0(sp)
    80001710:	0880                	addi	s0,sp,80
    80001712:	8b2a                	mv	s6,a0
    80001714:	8a2e                	mv	s4,a1
    80001716:	8c32                	mv	s8,a2
    80001718:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000171c:	6a85                	lui	s5,0x1
    8000171e:	a01d                	j	80001744 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001720:	018505b3          	add	a1,a0,s8
    80001724:	0004861b          	sext.w	a2,s1
    80001728:	412585b3          	sub	a1,a1,s2
    8000172c:	8552                	mv	a0,s4
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	600080e7          	jalr	1536(ra) # 80000d2e <memmove>

    len -= n;
    80001736:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000173c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001740:	02098263          	beqz	s3,80001764 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001744:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001748:	85ca                	mv	a1,s2
    8000174a:	855a                	mv	a0,s6
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	910080e7          	jalr	-1776(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001754:	cd01                	beqz	a0,8000176c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001756:	418904b3          	sub	s1,s2,s8
    8000175a:	94d6                	add	s1,s1,s5
    8000175c:	fc99f2e3          	bgeu	s3,s1,80001720 <copyin+0x28>
    80001760:	84ce                	mv	s1,s3
    80001762:	bf7d                	j	80001720 <copyin+0x28>
  }
  return 0;
    80001764:	4501                	li	a0,0
    80001766:	a021                	j	8000176e <copyin+0x76>
    80001768:	4501                	li	a0,0
}
    8000176a:	8082                	ret
      return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6c02                	ld	s8,0(sp)
    80001782:	6161                	addi	sp,sp,80
    80001784:	8082                	ret

0000000080001786 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001786:	c2dd                	beqz	a3,8000182c <copyinstr+0xa6>
{
    80001788:	715d                	addi	sp,sp,-80
    8000178a:	e486                	sd	ra,72(sp)
    8000178c:	e0a2                	sd	s0,64(sp)
    8000178e:	fc26                	sd	s1,56(sp)
    80001790:	f84a                	sd	s2,48(sp)
    80001792:	f44e                	sd	s3,40(sp)
    80001794:	f052                	sd	s4,32(sp)
    80001796:	ec56                	sd	s5,24(sp)
    80001798:	e85a                	sd	s6,16(sp)
    8000179a:	e45e                	sd	s7,8(sp)
    8000179c:	0880                	addi	s0,sp,80
    8000179e:	8a2a                	mv	s4,a0
    800017a0:	8b2e                	mv	s6,a1
    800017a2:	8bb2                	mv	s7,a2
    800017a4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a8:	6985                	lui	s3,0x1
    800017aa:	a02d                	j	800017d4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ac:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b2:	37fd                	addiw	a5,a5,-1
    800017b4:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b8:	60a6                	ld	ra,72(sp)
    800017ba:	6406                	ld	s0,64(sp)
    800017bc:	74e2                	ld	s1,56(sp)
    800017be:	7942                	ld	s2,48(sp)
    800017c0:	79a2                	ld	s3,40(sp)
    800017c2:	7a02                	ld	s4,32(sp)
    800017c4:	6ae2                	ld	s5,24(sp)
    800017c6:	6b42                	ld	s6,16(sp)
    800017c8:	6ba2                	ld	s7,8(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ce:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d2:	c8a9                	beqz	s1,80001824 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017d4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d8:	85ca                	mv	a1,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	880080e7          	jalr	-1920(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e4:	c131                	beqz	a0,80001828 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e6:	417906b3          	sub	a3,s2,s7
    800017ea:	96ce                	add	a3,a3,s3
    800017ec:	00d4f363          	bgeu	s1,a3,800017f2 <copyinstr+0x6c>
    800017f0:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f2:	955e                	add	a0,a0,s7
    800017f4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f8:	daf9                	beqz	a3,800017ce <copyinstr+0x48>
    800017fa:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fc:	41650633          	sub	a2,a0,s6
    80001800:	fff48593          	addi	a1,s1,-1
    80001804:	95da                	add	a1,a1,s6
    while(n > 0){
    80001806:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001808:	00f60733          	add	a4,a2,a5
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdab10>
    80001810:	df51                	beqz	a4,800017ac <copyinstr+0x26>
        *dst = *p;
    80001812:	00e78023          	sb	a4,0(a5)
      --max;
    80001816:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000181a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181c:	fed796e3          	bne	a5,a3,80001808 <copyinstr+0x82>
      dst++;
    80001820:	8b3e                	mv	s6,a5
    80001822:	b775                	j	800017ce <copyinstr+0x48>
    80001824:	4781                	li	a5,0
    80001826:	b771                	j	800017b2 <copyinstr+0x2c>
      return -1;
    80001828:	557d                	li	a0,-1
    8000182a:	b779                	j	800017b8 <copyinstr+0x32>
  int got_null = 0;
    8000182c:	4781                	li	a5,0
  if(got_null){
    8000182e:	37fd                	addiw	a5,a5,-1
    80001830:	0007851b          	sext.w	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000184c:	00010497          	auipc	s1,0x10
    80001850:	94448493          	addi	s1,s1,-1724 # 80011190 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001864:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001866:	00016a17          	auipc	s4,0x16
    8000186a:	52aa0a13          	addi	s4,s4,1322 # 80017d90 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if (pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	8591                	srai	a1,a1,0x4
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018a0:	1b048493          	addi	s1,s1,432
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7c080e7          	jalr	-900(ra) # 80000540 <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	47850513          	addi	a0,a0,1144 # 80010d60 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	47850513          	addi	a0,a0,1144 # 80010d78 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001910:	00010497          	auipc	s1,0x10
    80001914:	88048493          	addi	s1,s1,-1920 # 80011190 <proc>
  {
    initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001930:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001932:	00016997          	auipc	s3,0x16
    80001936:	45e98993          	addi	s3,s3,1118 # 80017d90 <tickslock>
    initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	8791                	srai	a5,a5,0x4
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001964:	1b048493          	addi	s1,s1,432
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	3f450513          	addi	a0,a0,1012 # 80010d90 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	39c70713          	addi	a4,a4,924 # 80010d60 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first)
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	f747a783          	lw	a5,-140(a5) # 80008970 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	e96080e7          	jalr	-362(ra) # 8000289c <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	f407ad23          	sw	zero,-166(a5) # 80008970 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	d4c080e7          	jalr	-692(ra) # 8000376c <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	32a90913          	addi	s2,s2,810 # 80010d60 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	f2c78793          	addi	a5,a5,-212 # 80008974 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	05893683          	ld	a3,88(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a54080e7          	jalr	-1452(ra) # 8000152e <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2e080e7          	jalr	-1490(ra) # 8000152e <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e4080e7          	jalr	-1564(ra) # 8000152e <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b6a:	6d28                	ld	a0,88(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7a080e7          	jalr	-390(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001b76:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001b7a:	68a8                	ld	a0,80(s1)
    80001b7c:	c511                	beqz	a0,80001b88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b7e:	64ac                	ld	a1,72(s1)
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f8c080e7          	jalr	-116(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b88:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b8c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b94:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b98:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba8:	0004ac23          	sw	zero,24(s1)
}
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6105                	addi	sp,sp,32
    80001bb4:	8082                	ret

0000000080001bb6 <allocproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	e04a                	sd	s2,0(sp)
    80001bc0:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bc2:	0000f497          	auipc	s1,0xf
    80001bc6:	5ce48493          	addi	s1,s1,1486 # 80011190 <proc>
    80001bca:	00016917          	auipc	s2,0x16
    80001bce:	1c690913          	addi	s2,s2,454 # 80017d90 <tickslock>
    acquire(&p->lock);
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	002080e7          	jalr	2(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001bdc:	4c9c                	lw	a5,24(s1)
    80001bde:	cf81                	beqz	a5,80001bf6 <allocproc+0x40>
      release(&p->lock);
    80001be0:	8526                	mv	a0,s1
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	0a8080e7          	jalr	168(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001bea:	1b048493          	addi	s1,s1,432
    80001bee:	ff2492e3          	bne	s1,s2,80001bd2 <allocproc+0x1c>
  return 0;
    80001bf2:	4481                	li	s1,0
    80001bf4:	a049                	j	80001c76 <allocproc+0xc0>
  p->pid = allocpid();
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	e34080e7          	jalr	-460(ra) # 80001a2a <allocpid>
    80001bfe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c00:	4785                	li	a5,1
    80001c02:	cc9c                	sw	a5,24(s1)
  p->tick_creation_time = ticks;
    80001c04:	00007797          	auipc	a5,0x7
    80001c08:	eec7a783          	lw	a5,-276(a5) # 80008af0 <ticks>
    80001c0c:	18f4a423          	sw	a5,392(s1)
  p->tickets = 10;
    80001c10:	4729                	li	a4,10
    80001c12:	18e4a623          	sw	a4,396(s1)
  p->priority = 60;
    80001c16:	03c00713          	li	a4,60
    80001c1a:	18e4ac23          	sw	a4,408(s1)
  p->niceness_var = 5;
    80001c1e:	4715                	li	a4,5
    80001c20:	18e4ae23          	sw	a4,412(s1)
  p->start_time_pbs = ticks;
    80001c24:	18f4a823          	sw	a5,400(s1)
  p->number_times = 0;
    80001c28:	1804aa23          	sw	zero,404(s1)
  p->last_run_time = 0;
    80001c2c:	1a04a223          	sw	zero,420(s1)
  p->last_sleep_time = 0;
    80001c30:	1a04a023          	sw	zero,416(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c34:	fffff097          	auipc	ra,0xfffff
    80001c38:	eb2080e7          	jalr	-334(ra) # 80000ae6 <kalloc>
    80001c3c:	892a                	mv	s2,a0
    80001c3e:	eca8                	sd	a0,88(s1)
    80001c40:	c131                	beqz	a0,80001c84 <allocproc+0xce>
  p->pagetable = proc_pagetable(p);
    80001c42:	8526                	mv	a0,s1
    80001c44:	00000097          	auipc	ra,0x0
    80001c48:	e2c080e7          	jalr	-468(ra) # 80001a70 <proc_pagetable>
    80001c4c:	892a                	mv	s2,a0
    80001c4e:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c50:	c531                	beqz	a0,80001c9c <allocproc+0xe6>
  memset(&p->context, 0, sizeof(p->context));
    80001c52:	07000613          	li	a2,112
    80001c56:	4581                	li	a1,0
    80001c58:	06048513          	addi	a0,s1,96
    80001c5c:	fffff097          	auipc	ra,0xfffff
    80001c60:	076080e7          	jalr	118(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c64:	00000797          	auipc	a5,0x0
    80001c68:	d8078793          	addi	a5,a5,-640 # 800019e4 <forkret>
    80001c6c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c6e:	60bc                	ld	a5,64(s1)
    80001c70:	6705                	lui	a4,0x1
    80001c72:	97ba                	add	a5,a5,a4
    80001c74:	f4bc                	sd	a5,104(s1)
}
    80001c76:	8526                	mv	a0,s1
    80001c78:	60e2                	ld	ra,24(sp)
    80001c7a:	6442                	ld	s0,16(sp)
    80001c7c:	64a2                	ld	s1,8(sp)
    80001c7e:	6902                	ld	s2,0(sp)
    80001c80:	6105                	addi	sp,sp,32
    80001c82:	8082                	ret
    freeproc(p);
    80001c84:	8526                	mv	a0,s1
    80001c86:	00000097          	auipc	ra,0x0
    80001c8a:	ed8080e7          	jalr	-296(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c8e:	8526                	mv	a0,s1
    80001c90:	fffff097          	auipc	ra,0xfffff
    80001c94:	ffa080e7          	jalr	-6(ra) # 80000c8a <release>
    return 0;
    80001c98:	84ca                	mv	s1,s2
    80001c9a:	bff1                	j	80001c76 <allocproc+0xc0>
    freeproc(p);
    80001c9c:	8526                	mv	a0,s1
    80001c9e:	00000097          	auipc	ra,0x0
    80001ca2:	ec0080e7          	jalr	-320(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001ca6:	8526                	mv	a0,s1
    80001ca8:	fffff097          	auipc	ra,0xfffff
    80001cac:	fe2080e7          	jalr	-30(ra) # 80000c8a <release>
    return 0;
    80001cb0:	84ca                	mv	s1,s2
    80001cb2:	b7d1                	j	80001c76 <allocproc+0xc0>

0000000080001cb4 <userinit>:
{
    80001cb4:	1101                	addi	sp,sp,-32
    80001cb6:	ec06                	sd	ra,24(sp)
    80001cb8:	e822                	sd	s0,16(sp)
    80001cba:	e426                	sd	s1,8(sp)
    80001cbc:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cbe:	00000097          	auipc	ra,0x0
    80001cc2:	ef8080e7          	jalr	-264(ra) # 80001bb6 <allocproc>
    80001cc6:	84aa                	mv	s1,a0
  initproc = p;
    80001cc8:	00007797          	auipc	a5,0x7
    80001ccc:	e2a7b023          	sd	a0,-480(a5) # 80008ae8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cd0:	03400613          	li	a2,52
    80001cd4:	00007597          	auipc	a1,0x7
    80001cd8:	cac58593          	addi	a1,a1,-852 # 80008980 <initcode>
    80001cdc:	6928                	ld	a0,80(a0)
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	678080e7          	jalr	1656(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001ce6:	6785                	lui	a5,0x1
    80001ce8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001cea:	6cb8                	ld	a4,88(s1)
    80001cec:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001cf0:	6cb8                	ld	a4,88(s1)
    80001cf2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cf4:	4641                	li	a2,16
    80001cf6:	00006597          	auipc	a1,0x6
    80001cfa:	50a58593          	addi	a1,a1,1290 # 80008200 <digits+0x1c0>
    80001cfe:	15848513          	addi	a0,s1,344
    80001d02:	fffff097          	auipc	ra,0xfffff
    80001d06:	11a080e7          	jalr	282(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001d0a:	00006517          	auipc	a0,0x6
    80001d0e:	50650513          	addi	a0,a0,1286 # 80008210 <digits+0x1d0>
    80001d12:	00002097          	auipc	ra,0x2
    80001d16:	484080e7          	jalr	1156(ra) # 80004196 <namei>
    80001d1a:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d1e:	478d                	li	a5,3
    80001d20:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d22:	8526                	mv	a0,s1
    80001d24:	fffff097          	auipc	ra,0xfffff
    80001d28:	f66080e7          	jalr	-154(ra) # 80000c8a <release>
}
    80001d2c:	60e2                	ld	ra,24(sp)
    80001d2e:	6442                	ld	s0,16(sp)
    80001d30:	64a2                	ld	s1,8(sp)
    80001d32:	6105                	addi	sp,sp,32
    80001d34:	8082                	ret

0000000080001d36 <growproc>:
{
    80001d36:	1101                	addi	sp,sp,-32
    80001d38:	ec06                	sd	ra,24(sp)
    80001d3a:	e822                	sd	s0,16(sp)
    80001d3c:	e426                	sd	s1,8(sp)
    80001d3e:	e04a                	sd	s2,0(sp)
    80001d40:	1000                	addi	s0,sp,32
    80001d42:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d44:	00000097          	auipc	ra,0x0
    80001d48:	c68080e7          	jalr	-920(ra) # 800019ac <myproc>
    80001d4c:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d4e:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001d50:	01204c63          	bgtz	s2,80001d68 <growproc+0x32>
  else if (n < 0)
    80001d54:	02094663          	bltz	s2,80001d80 <growproc+0x4a>
  p->sz = sz;
    80001d58:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d5a:	4501                	li	a0,0
}
    80001d5c:	60e2                	ld	ra,24(sp)
    80001d5e:	6442                	ld	s0,16(sp)
    80001d60:	64a2                	ld	s1,8(sp)
    80001d62:	6902                	ld	s2,0(sp)
    80001d64:	6105                	addi	sp,sp,32
    80001d66:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d68:	4691                	li	a3,4
    80001d6a:	00b90633          	add	a2,s2,a1
    80001d6e:	6928                	ld	a0,80(a0)
    80001d70:	fffff097          	auipc	ra,0xfffff
    80001d74:	6a0080e7          	jalr	1696(ra) # 80001410 <uvmalloc>
    80001d78:	85aa                	mv	a1,a0
    80001d7a:	fd79                	bnez	a0,80001d58 <growproc+0x22>
      return -1;
    80001d7c:	557d                	li	a0,-1
    80001d7e:	bff9                	j	80001d5c <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d80:	00b90633          	add	a2,s2,a1
    80001d84:	6928                	ld	a0,80(a0)
    80001d86:	fffff097          	auipc	ra,0xfffff
    80001d8a:	642080e7          	jalr	1602(ra) # 800013c8 <uvmdealloc>
    80001d8e:	85aa                	mv	a1,a0
    80001d90:	b7e1                	j	80001d58 <growproc+0x22>

0000000080001d92 <fork>:
{
    80001d92:	7139                	addi	sp,sp,-64
    80001d94:	fc06                	sd	ra,56(sp)
    80001d96:	f822                	sd	s0,48(sp)
    80001d98:	f426                	sd	s1,40(sp)
    80001d9a:	f04a                	sd	s2,32(sp)
    80001d9c:	ec4e                	sd	s3,24(sp)
    80001d9e:	e852                	sd	s4,16(sp)
    80001da0:	e456                	sd	s5,8(sp)
    80001da2:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001da4:	00000097          	auipc	ra,0x0
    80001da8:	c08080e7          	jalr	-1016(ra) # 800019ac <myproc>
    80001dac:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001dae:	00000097          	auipc	ra,0x0
    80001db2:	e08080e7          	jalr	-504(ra) # 80001bb6 <allocproc>
    80001db6:	12050063          	beqz	a0,80001ed6 <fork+0x144>
    80001dba:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001dbc:	048ab603          	ld	a2,72(s5)
    80001dc0:	692c                	ld	a1,80(a0)
    80001dc2:	050ab503          	ld	a0,80(s5)
    80001dc6:	fffff097          	auipc	ra,0xfffff
    80001dca:	7a2080e7          	jalr	1954(ra) # 80001568 <uvmcopy>
    80001dce:	04054c63          	bltz	a0,80001e26 <fork+0x94>
  np->sz = p->sz;
    80001dd2:	048ab783          	ld	a5,72(s5)
    80001dd6:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dda:	058ab683          	ld	a3,88(s5)
    80001dde:	87b6                	mv	a5,a3
    80001de0:	0589b703          	ld	a4,88(s3)
    80001de4:	12068693          	addi	a3,a3,288
    80001de8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dec:	6788                	ld	a0,8(a5)
    80001dee:	6b8c                	ld	a1,16(a5)
    80001df0:	6f90                	ld	a2,24(a5)
    80001df2:	01073023          	sd	a6,0(a4)
    80001df6:	e708                	sd	a0,8(a4)
    80001df8:	eb0c                	sd	a1,16(a4)
    80001dfa:	ef10                	sd	a2,24(a4)
    80001dfc:	02078793          	addi	a5,a5,32
    80001e00:	02070713          	addi	a4,a4,32
    80001e04:	fed792e3          	bne	a5,a3,80001de8 <fork+0x56>
  np->trace_flag = p->trace_flag;
    80001e08:	168aa783          	lw	a5,360(s5)
    80001e0c:	16f9a423          	sw	a5,360(s3)
  np->trapframe->a0 = 0;
    80001e10:	0589b783          	ld	a5,88(s3)
    80001e14:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001e18:	0d0a8493          	addi	s1,s5,208
    80001e1c:	0d098913          	addi	s2,s3,208
    80001e20:	150a8a13          	addi	s4,s5,336
    80001e24:	a00d                	j	80001e46 <fork+0xb4>
    freeproc(np);
    80001e26:	854e                	mv	a0,s3
    80001e28:	00000097          	auipc	ra,0x0
    80001e2c:	d36080e7          	jalr	-714(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001e30:	854e                	mv	a0,s3
    80001e32:	fffff097          	auipc	ra,0xfffff
    80001e36:	e58080e7          	jalr	-424(ra) # 80000c8a <release>
    return -1;
    80001e3a:	597d                	li	s2,-1
    80001e3c:	a059                	j	80001ec2 <fork+0x130>
  for (i = 0; i < NOFILE; i++)
    80001e3e:	04a1                	addi	s1,s1,8
    80001e40:	0921                	addi	s2,s2,8
    80001e42:	01448b63          	beq	s1,s4,80001e58 <fork+0xc6>
    if (p->ofile[i])
    80001e46:	6088                	ld	a0,0(s1)
    80001e48:	d97d                	beqz	a0,80001e3e <fork+0xac>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e4a:	00003097          	auipc	ra,0x3
    80001e4e:	9e2080e7          	jalr	-1566(ra) # 8000482c <filedup>
    80001e52:	00a93023          	sd	a0,0(s2)
    80001e56:	b7e5                	j	80001e3e <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e58:	150ab503          	ld	a0,336(s5)
    80001e5c:	00002097          	auipc	ra,0x2
    80001e60:	b50080e7          	jalr	-1200(ra) # 800039ac <idup>
    80001e64:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e68:	4641                	li	a2,16
    80001e6a:	158a8593          	addi	a1,s5,344
    80001e6e:	15898513          	addi	a0,s3,344
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	faa080e7          	jalr	-86(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e7a:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001e7e:	854e                	mv	a0,s3
    80001e80:	fffff097          	auipc	ra,0xfffff
    80001e84:	e0a080e7          	jalr	-502(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e88:	0000f497          	auipc	s1,0xf
    80001e8c:	ef048493          	addi	s1,s1,-272 # 80010d78 <wait_lock>
    80001e90:	8526                	mv	a0,s1
    80001e92:	fffff097          	auipc	ra,0xfffff
    80001e96:	d44080e7          	jalr	-700(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e9a:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80001e9e:	8526                	mv	a0,s1
    80001ea0:	fffff097          	auipc	ra,0xfffff
    80001ea4:	dea080e7          	jalr	-534(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001ea8:	854e                	mv	a0,s3
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	d2c080e7          	jalr	-724(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001eb2:	478d                	li	a5,3
    80001eb4:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001eb8:	854e                	mv	a0,s3
    80001eba:	fffff097          	auipc	ra,0xfffff
    80001ebe:	dd0080e7          	jalr	-560(ra) # 80000c8a <release>
}
    80001ec2:	854a                	mv	a0,s2
    80001ec4:	70e2                	ld	ra,56(sp)
    80001ec6:	7442                	ld	s0,48(sp)
    80001ec8:	74a2                	ld	s1,40(sp)
    80001eca:	7902                	ld	s2,32(sp)
    80001ecc:	69e2                	ld	s3,24(sp)
    80001ece:	6a42                	ld	s4,16(sp)
    80001ed0:	6aa2                	ld	s5,8(sp)
    80001ed2:	6121                	addi	sp,sp,64
    80001ed4:	8082                	ret
    return -1;
    80001ed6:	597d                	li	s2,-1
    80001ed8:	b7ed                	j	80001ec2 <fork+0x130>

0000000080001eda <dynamic_priority>:
{
    80001eda:	1141                	addi	sp,sp,-16
    80001edc:	e422                	sd	s0,8(sp)
    80001ede:	0800                	addi	s0,sp,16
  if (proc_to_calc->number_times == 0) // If the process is being schedules for the first time
    80001ee0:	19452783          	lw	a5,404(a0)
    80001ee4:	c7a1                	beqz	a5,80001f2c <dynamic_priority+0x52>
    int numerator = proc_to_calc->last_sleep_time;
    80001ee6:	1a052703          	lw	a4,416(a0)
    int denominator = proc_to_calc->last_run_time + proc_to_calc->last_sleep_time;
    80001eea:	1a452783          	lw	a5,420(a0)
    80001eee:	9fb9                	addw	a5,a5,a4
    int noiceness = ((numerator / denominator) * 10); // Calculates 'niceness'
    80001ef0:	02f7473b          	divw	a4,a4,a5
    80001ef4:	0027179b          	slliw	a5,a4,0x2
    80001ef8:	9fb9                	addw	a5,a5,a4
    80001efa:	0017979b          	slliw	a5,a5,0x1
    if (proc_to_calc->priority + noiceness - 5 <= 100)
    80001efe:	19852703          	lw	a4,408(a0)
    80001f02:	9fb9                	addw	a5,a5,a4
    80001f04:	0007869b          	sext.w	a3,a5
    80001f08:	06900713          	li	a4,105
      min = 100;
    80001f0c:	06400513          	li	a0,100
    if (proc_to_calc->priority + noiceness - 5 <= 100)
    80001f10:	00d74b63          	blt	a4,a3,80001f26 <dynamic_priority+0x4c>
      min = proc_to_calc->priority + noiceness - 5;
    80001f14:	ffb7851b          	addiw	a0,a5,-5
    80001f18:	0005079b          	sext.w	a5,a0
    80001f1c:	fff7c793          	not	a5,a5
    80001f20:	97fd                	srai	a5,a5,0x3f
    80001f22:	8d7d                	and	a0,a0,a5
    80001f24:	2501                	sext.w	a0,a0
}
    80001f26:	6422                	ld	s0,8(sp)
    80001f28:	0141                	addi	sp,sp,16
    80001f2a:	8082                	ret
    return proc_to_calc->priority; // returns DP as 60 (SP).
    80001f2c:	19852503          	lw	a0,408(a0)
    80001f30:	bfdd                	j	80001f26 <dynamic_priority+0x4c>

0000000080001f32 <scheduler>:
{
    80001f32:	7119                	addi	sp,sp,-128
    80001f34:	fc86                	sd	ra,120(sp)
    80001f36:	f8a2                	sd	s0,112(sp)
    80001f38:	f4a6                	sd	s1,104(sp)
    80001f3a:	f0ca                	sd	s2,96(sp)
    80001f3c:	ecce                	sd	s3,88(sp)
    80001f3e:	e8d2                	sd	s4,80(sp)
    80001f40:	e4d6                	sd	s5,72(sp)
    80001f42:	e0da                	sd	s6,64(sp)
    80001f44:	fc5e                	sd	s7,56(sp)
    80001f46:	f862                	sd	s8,48(sp)
    80001f48:	f466                	sd	s9,40(sp)
    80001f4a:	f06a                	sd	s10,32(sp)
    80001f4c:	ec6e                	sd	s11,24(sp)
    80001f4e:	0100                	addi	s0,sp,128
    80001f50:	8792                	mv	a5,tp
  int id = r_tp();
    80001f52:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f54:	00779d93          	slli	s11,a5,0x7
    80001f58:	0000f717          	auipc	a4,0xf
    80001f5c:	e0870713          	addi	a4,a4,-504 # 80010d60 <pid_lock>
    80001f60:	976e                	add	a4,a4,s11
    80001f62:	02073823          	sd	zero,48(a4)
      swtch(&c->context, &pbs_proc_to_run->context);
    80001f66:	0000f717          	auipc	a4,0xf
    80001f6a:	e3270713          	addi	a4,a4,-462 # 80010d98 <cpus+0x8>
    80001f6e:	9dba                	add	s11,s11,a4
    int min_priority = __INT_MAX__, temp_dp;
    80001f70:	80000737          	lui	a4,0x80000
    80001f74:	fff74713          	not	a4,a4
    80001f78:	f8e43423          	sd	a4,-120(s0)
      if (p->state != RUNNABLE)
    80001f7c:	4c8d                	li	s9,3
    for (p = proc; p < &proc[NPROC]; p++)
    80001f7e:	00016c17          	auipc	s8,0x16
    80001f82:	e12c0c13          	addi	s8,s8,-494 # 80017d90 <tickslock>
      c->proc = pbs_proc_to_run;
    80001f86:	079e                	slli	a5,a5,0x7
    80001f88:	0000fd17          	auipc	s10,0xf
    80001f8c:	dd8d0d13          	addi	s10,s10,-552 # 80010d60 <pid_lock>
    80001f90:	9d3e                	add	s10,s10,a5
    80001f92:	a089                	j	80001fd4 <scheduler+0xa2>
        release(&p->lock);
    80001f94:	8526                	mv	a0,s1
    80001f96:	fffff097          	auipc	ra,0xfffff
    80001f9a:	cf4080e7          	jalr	-780(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f9e:	09896a63          	bltu	s2,s8,80002032 <scheduler+0x100>
    if (pbs_proc_to_run != 0)
    80001fa2:	020b8963          	beqz	s7,80001fd4 <scheduler+0xa2>
      pbs_proc_to_run->state = RUNNING;
    80001fa6:	4791                	li	a5,4
    80001fa8:	00fbac23          	sw	a5,24(s7) # fffffffffffff018 <end+0xffffffff7ffdab28>
      pbs_proc_to_run->last_run_time = 0;
    80001fac:	1a0ba223          	sw	zero,420(s7)
      pbs_proc_to_run->last_sleep_time = 0;
    80001fb0:	1a0ba023          	sw	zero,416(s7)
      c->proc = pbs_proc_to_run;
    80001fb4:	037d3823          	sd	s7,48(s10)
      swtch(&c->context, &pbs_proc_to_run->context);
    80001fb8:	060b8593          	addi	a1,s7,96
    80001fbc:	856e                	mv	a0,s11
    80001fbe:	00001097          	auipc	ra,0x1
    80001fc2:	834080e7          	jalr	-1996(ra) # 800027f2 <swtch>
      c->proc = 0;
    80001fc6:	020d3823          	sd	zero,48(s10)
      release(&pbs_proc_to_run->lock);
    80001fca:	855e                	mv	a0,s7
    80001fcc:	fffff097          	auipc	ra,0xfffff
    80001fd0:	cbe080e7          	jalr	-834(ra) # 80000c8a <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fd4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fd8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fdc:	10079073          	csrw	sstatus,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001fe0:	0000f497          	auipc	s1,0xf
    80001fe4:	1b048493          	addi	s1,s1,432 # 80011190 <proc>
    80001fe8:	0000f917          	auipc	s2,0xf
    80001fec:	35890913          	addi	s2,s2,856 # 80011340 <proc+0x1b0>
    int min_priority = __INT_MAX__, temp_dp;
    80001ff0:	f8843b03          	ld	s6,-120(s0)
    struct proc *pbs_proc_to_run = 0;
    80001ff4:	4b81                	li	s7,0
    80001ff6:	a091                	j	8000203a <scheduler+0x108>
          temp_dp = dynamic_priority(p);
    80001ff8:	8526                	mv	a0,s1
    80001ffa:	00000097          	auipc	ra,0x0
    80001ffe:	ee0080e7          	jalr	-288(ra) # 80001eda <dynamic_priority>
    80002002:	8b2a                	mv	s6,a0
          continue;
    80002004:	8ba6                	mv	s7,s1
    80002006:	a025                	j	8000202e <scheduler+0xfc>
            release(&pbs_proc_to_run->lock);
    80002008:	855e                	mv	a0,s7
    8000200a:	fffff097          	auipc	ra,0xfffff
    8000200e:	c80080e7          	jalr	-896(ra) # 80000c8a <release>
            min_priority = temp_dp;
    80002012:	8b4e                	mv	s6,s3
            continue;
    80002014:	8ba6                	mv	s7,s1
    80002016:	a821                	j	8000202e <scheduler+0xfc>
              release(&pbs_proc_to_run->lock);
    80002018:	855e                	mv	a0,s7
    8000201a:	fffff097          	auipc	ra,0xfffff
    8000201e:	c70080e7          	jalr	-912(ra) # 80000c8a <release>
              min_priority = temp_dp;
    80002022:	8ba6                	mv	s7,s1
      release(&p->lock);
    80002024:	8552                	mv	a0,s4
    80002026:	fffff097          	auipc	ra,0xfffff
    8000202a:	c64080e7          	jalr	-924(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000202e:	f78afce3          	bgeu	s5,s8,80001fa6 <scheduler+0x74>
    80002032:	1b048493          	addi	s1,s1,432
    80002036:	1b090913          	addi	s2,s2,432
    8000203a:	8a26                	mv	s4,s1
      acquire(&p->lock);
    8000203c:	8526                	mv	a0,s1
    8000203e:	fffff097          	auipc	ra,0xfffff
    80002042:	b98080e7          	jalr	-1128(ra) # 80000bd6 <acquire>
      if (p->state != RUNNABLE)
    80002046:	8aca                	mv	s5,s2
    80002048:	e6892783          	lw	a5,-408(s2)
    8000204c:	f59794e3          	bne	a5,s9,80001f94 <scheduler+0x62>
        if (pbs_proc_to_run == 0)
    80002050:	fa0b84e3          	beqz	s7,80001ff8 <scheduler+0xc6>
          temp_dp = dynamic_priority(p);
    80002054:	8526                	mv	a0,s1
    80002056:	00000097          	auipc	ra,0x0
    8000205a:	e84080e7          	jalr	-380(ra) # 80001eda <dynamic_priority>
    8000205e:	89aa                	mv	s3,a0
          if (temp_dp < min_priority)
    80002060:	fb6544e3          	blt	a0,s6,80002008 <scheduler+0xd6>
          else if (temp_dp == min_priority)
    80002064:	fd6510e3          	bne	a0,s6,80002024 <scheduler+0xf2>
            if (pbs_proc_to_run->number_times > p->number_times)
    80002068:	194ba703          	lw	a4,404(s7)
    8000206c:	fe492783          	lw	a5,-28(s2)
    80002070:	fae7c4e3          	blt	a5,a4,80002018 <scheduler+0xe6>
            else if ((pbs_proc_to_run->number_times == p->number_times) && (pbs_proc_to_run->tick_creation_time > p->tick_creation_time))
    80002074:	faf718e3          	bne	a4,a5,80002024 <scheduler+0xf2>
    80002078:	188ba703          	lw	a4,392(s7)
    8000207c:	fd892783          	lw	a5,-40(s2)
    80002080:	fae7d2e3          	bge	a5,a4,80002024 <scheduler+0xf2>
              release(&pbs_proc_to_run->lock);
    80002084:	855e                	mv	a0,s7
    80002086:	fffff097          	auipc	ra,0xfffff
    8000208a:	c04080e7          	jalr	-1020(ra) # 80000c8a <release>
    8000208e:	8ba6                	mv	s7,s1
    80002090:	bf51                	j	80002024 <scheduler+0xf2>

0000000080002092 <sched>:
{
    80002092:	7179                	addi	sp,sp,-48
    80002094:	f406                	sd	ra,40(sp)
    80002096:	f022                	sd	s0,32(sp)
    80002098:	ec26                	sd	s1,24(sp)
    8000209a:	e84a                	sd	s2,16(sp)
    8000209c:	e44e                	sd	s3,8(sp)
    8000209e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020a0:	00000097          	auipc	ra,0x0
    800020a4:	90c080e7          	jalr	-1780(ra) # 800019ac <myproc>
    800020a8:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800020aa:	fffff097          	auipc	ra,0xfffff
    800020ae:	ab2080e7          	jalr	-1358(ra) # 80000b5c <holding>
    800020b2:	c93d                	beqz	a0,80002128 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020b4:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800020b6:	2781                	sext.w	a5,a5
    800020b8:	079e                	slli	a5,a5,0x7
    800020ba:	0000f717          	auipc	a4,0xf
    800020be:	ca670713          	addi	a4,a4,-858 # 80010d60 <pid_lock>
    800020c2:	97ba                	add	a5,a5,a4
    800020c4:	0a87a703          	lw	a4,168(a5)
    800020c8:	4785                	li	a5,1
    800020ca:	06f71763          	bne	a4,a5,80002138 <sched+0xa6>
  if (p->state == RUNNING)
    800020ce:	4c98                	lw	a4,24(s1)
    800020d0:	4791                	li	a5,4
    800020d2:	06f70b63          	beq	a4,a5,80002148 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020d6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020da:	8b89                	andi	a5,a5,2
  if (intr_get())
    800020dc:	efb5                	bnez	a5,80002158 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020de:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020e0:	0000f917          	auipc	s2,0xf
    800020e4:	c8090913          	addi	s2,s2,-896 # 80010d60 <pid_lock>
    800020e8:	2781                	sext.w	a5,a5
    800020ea:	079e                	slli	a5,a5,0x7
    800020ec:	97ca                	add	a5,a5,s2
    800020ee:	0ac7a983          	lw	s3,172(a5)
    800020f2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020f4:	2781                	sext.w	a5,a5
    800020f6:	079e                	slli	a5,a5,0x7
    800020f8:	0000f597          	auipc	a1,0xf
    800020fc:	ca058593          	addi	a1,a1,-864 # 80010d98 <cpus+0x8>
    80002100:	95be                	add	a1,a1,a5
    80002102:	06048513          	addi	a0,s1,96
    80002106:	00000097          	auipc	ra,0x0
    8000210a:	6ec080e7          	jalr	1772(ra) # 800027f2 <swtch>
    8000210e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002110:	2781                	sext.w	a5,a5
    80002112:	079e                	slli	a5,a5,0x7
    80002114:	993e                	add	s2,s2,a5
    80002116:	0b392623          	sw	s3,172(s2)
}
    8000211a:	70a2                	ld	ra,40(sp)
    8000211c:	7402                	ld	s0,32(sp)
    8000211e:	64e2                	ld	s1,24(sp)
    80002120:	6942                	ld	s2,16(sp)
    80002122:	69a2                	ld	s3,8(sp)
    80002124:	6145                	addi	sp,sp,48
    80002126:	8082                	ret
    panic("sched p->lock");
    80002128:	00006517          	auipc	a0,0x6
    8000212c:	0f050513          	addi	a0,a0,240 # 80008218 <digits+0x1d8>
    80002130:	ffffe097          	auipc	ra,0xffffe
    80002134:	410080e7          	jalr	1040(ra) # 80000540 <panic>
    panic("sched locks");
    80002138:	00006517          	auipc	a0,0x6
    8000213c:	0f050513          	addi	a0,a0,240 # 80008228 <digits+0x1e8>
    80002140:	ffffe097          	auipc	ra,0xffffe
    80002144:	400080e7          	jalr	1024(ra) # 80000540 <panic>
    panic("sched running");
    80002148:	00006517          	auipc	a0,0x6
    8000214c:	0f050513          	addi	a0,a0,240 # 80008238 <digits+0x1f8>
    80002150:	ffffe097          	auipc	ra,0xffffe
    80002154:	3f0080e7          	jalr	1008(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002158:	00006517          	auipc	a0,0x6
    8000215c:	0f050513          	addi	a0,a0,240 # 80008248 <digits+0x208>
    80002160:	ffffe097          	auipc	ra,0xffffe
    80002164:	3e0080e7          	jalr	992(ra) # 80000540 <panic>

0000000080002168 <yield>:
{
    80002168:	1101                	addi	sp,sp,-32
    8000216a:	ec06                	sd	ra,24(sp)
    8000216c:	e822                	sd	s0,16(sp)
    8000216e:	e426                	sd	s1,8(sp)
    80002170:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002172:	00000097          	auipc	ra,0x0
    80002176:	83a080e7          	jalr	-1990(ra) # 800019ac <myproc>
    8000217a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000217c:	fffff097          	auipc	ra,0xfffff
    80002180:	a5a080e7          	jalr	-1446(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002184:	478d                	li	a5,3
    80002186:	cc9c                	sw	a5,24(s1)
  sched();
    80002188:	00000097          	auipc	ra,0x0
    8000218c:	f0a080e7          	jalr	-246(ra) # 80002092 <sched>
  release(&p->lock);
    80002190:	8526                	mv	a0,s1
    80002192:	fffff097          	auipc	ra,0xfffff
    80002196:	af8080e7          	jalr	-1288(ra) # 80000c8a <release>
}
    8000219a:	60e2                	ld	ra,24(sp)
    8000219c:	6442                	ld	s0,16(sp)
    8000219e:	64a2                	ld	s1,8(sp)
    800021a0:	6105                	addi	sp,sp,32
    800021a2:	8082                	ret

00000000800021a4 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800021a4:	7179                	addi	sp,sp,-48
    800021a6:	f406                	sd	ra,40(sp)
    800021a8:	f022                	sd	s0,32(sp)
    800021aa:	ec26                	sd	s1,24(sp)
    800021ac:	e84a                	sd	s2,16(sp)
    800021ae:	e44e                	sd	s3,8(sp)
    800021b0:	1800                	addi	s0,sp,48
    800021b2:	89aa                	mv	s3,a0
    800021b4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800021b6:	fffff097          	auipc	ra,0xfffff
    800021ba:	7f6080e7          	jalr	2038(ra) # 800019ac <myproc>
    800021be:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	a16080e7          	jalr	-1514(ra) # 80000bd6 <acquire>
  release(lk);
    800021c8:	854a                	mv	a0,s2
    800021ca:	fffff097          	auipc	ra,0xfffff
    800021ce:	ac0080e7          	jalr	-1344(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    800021d2:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800021d6:	4789                	li	a5,2
    800021d8:	cc9c                	sw	a5,24(s1)

  sched();
    800021da:	00000097          	auipc	ra,0x0
    800021de:	eb8080e7          	jalr	-328(ra) # 80002092 <sched>

  // Tidy up.
  p->chan = 0;
    800021e2:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800021e6:	8526                	mv	a0,s1
    800021e8:	fffff097          	auipc	ra,0xfffff
    800021ec:	aa2080e7          	jalr	-1374(ra) # 80000c8a <release>
  acquire(lk);
    800021f0:	854a                	mv	a0,s2
    800021f2:	fffff097          	auipc	ra,0xfffff
    800021f6:	9e4080e7          	jalr	-1564(ra) # 80000bd6 <acquire>
}
    800021fa:	70a2                	ld	ra,40(sp)
    800021fc:	7402                	ld	s0,32(sp)
    800021fe:	64e2                	ld	s1,24(sp)
    80002200:	6942                	ld	s2,16(sp)
    80002202:	69a2                	ld	s3,8(sp)
    80002204:	6145                	addi	sp,sp,48
    80002206:	8082                	ret

0000000080002208 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002208:	7139                	addi	sp,sp,-64
    8000220a:	fc06                	sd	ra,56(sp)
    8000220c:	f822                	sd	s0,48(sp)
    8000220e:	f426                	sd	s1,40(sp)
    80002210:	f04a                	sd	s2,32(sp)
    80002212:	ec4e                	sd	s3,24(sp)
    80002214:	e852                	sd	s4,16(sp)
    80002216:	e456                	sd	s5,8(sp)
    80002218:	0080                	addi	s0,sp,64
    8000221a:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000221c:	0000f497          	auipc	s1,0xf
    80002220:	f7448493          	addi	s1,s1,-140 # 80011190 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002224:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002226:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002228:	00016917          	auipc	s2,0x16
    8000222c:	b6890913          	addi	s2,s2,-1176 # 80017d90 <tickslock>
    80002230:	a811                	j	80002244 <wakeup+0x3c>
      }
      release(&p->lock);
    80002232:	8526                	mv	a0,s1
    80002234:	fffff097          	auipc	ra,0xfffff
    80002238:	a56080e7          	jalr	-1450(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000223c:	1b048493          	addi	s1,s1,432
    80002240:	03248663          	beq	s1,s2,8000226c <wakeup+0x64>
    if (p != myproc())
    80002244:	fffff097          	auipc	ra,0xfffff
    80002248:	768080e7          	jalr	1896(ra) # 800019ac <myproc>
    8000224c:	fea488e3          	beq	s1,a0,8000223c <wakeup+0x34>
      acquire(&p->lock);
    80002250:	8526                	mv	a0,s1
    80002252:	fffff097          	auipc	ra,0xfffff
    80002256:	984080e7          	jalr	-1660(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    8000225a:	4c9c                	lw	a5,24(s1)
    8000225c:	fd379be3          	bne	a5,s3,80002232 <wakeup+0x2a>
    80002260:	709c                	ld	a5,32(s1)
    80002262:	fd4798e3          	bne	a5,s4,80002232 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002266:	0154ac23          	sw	s5,24(s1)
    8000226a:	b7e1                	j	80002232 <wakeup+0x2a>
    }
  }
}
    8000226c:	70e2                	ld	ra,56(sp)
    8000226e:	7442                	ld	s0,48(sp)
    80002270:	74a2                	ld	s1,40(sp)
    80002272:	7902                	ld	s2,32(sp)
    80002274:	69e2                	ld	s3,24(sp)
    80002276:	6a42                	ld	s4,16(sp)
    80002278:	6aa2                	ld	s5,8(sp)
    8000227a:	6121                	addi	sp,sp,64
    8000227c:	8082                	ret

000000008000227e <reparent>:
{
    8000227e:	7179                	addi	sp,sp,-48
    80002280:	f406                	sd	ra,40(sp)
    80002282:	f022                	sd	s0,32(sp)
    80002284:	ec26                	sd	s1,24(sp)
    80002286:	e84a                	sd	s2,16(sp)
    80002288:	e44e                	sd	s3,8(sp)
    8000228a:	e052                	sd	s4,0(sp)
    8000228c:	1800                	addi	s0,sp,48
    8000228e:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002290:	0000f497          	auipc	s1,0xf
    80002294:	f0048493          	addi	s1,s1,-256 # 80011190 <proc>
      pp->parent = initproc;
    80002298:	00007a17          	auipc	s4,0x7
    8000229c:	850a0a13          	addi	s4,s4,-1968 # 80008ae8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800022a0:	00016997          	auipc	s3,0x16
    800022a4:	af098993          	addi	s3,s3,-1296 # 80017d90 <tickslock>
    800022a8:	a029                	j	800022b2 <reparent+0x34>
    800022aa:	1b048493          	addi	s1,s1,432
    800022ae:	01348d63          	beq	s1,s3,800022c8 <reparent+0x4a>
    if (pp->parent == p)
    800022b2:	7c9c                	ld	a5,56(s1)
    800022b4:	ff279be3          	bne	a5,s2,800022aa <reparent+0x2c>
      pp->parent = initproc;
    800022b8:	000a3503          	ld	a0,0(s4)
    800022bc:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022be:	00000097          	auipc	ra,0x0
    800022c2:	f4a080e7          	jalr	-182(ra) # 80002208 <wakeup>
    800022c6:	b7d5                	j	800022aa <reparent+0x2c>
}
    800022c8:	70a2                	ld	ra,40(sp)
    800022ca:	7402                	ld	s0,32(sp)
    800022cc:	64e2                	ld	s1,24(sp)
    800022ce:	6942                	ld	s2,16(sp)
    800022d0:	69a2                	ld	s3,8(sp)
    800022d2:	6a02                	ld	s4,0(sp)
    800022d4:	6145                	addi	sp,sp,48
    800022d6:	8082                	ret

00000000800022d8 <exit>:
{
    800022d8:	7179                	addi	sp,sp,-48
    800022da:	f406                	sd	ra,40(sp)
    800022dc:	f022                	sd	s0,32(sp)
    800022de:	ec26                	sd	s1,24(sp)
    800022e0:	e84a                	sd	s2,16(sp)
    800022e2:	e44e                	sd	s3,8(sp)
    800022e4:	e052                	sd	s4,0(sp)
    800022e6:	1800                	addi	s0,sp,48
    800022e8:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022ea:	fffff097          	auipc	ra,0xfffff
    800022ee:	6c2080e7          	jalr	1730(ra) # 800019ac <myproc>
    800022f2:	89aa                	mv	s3,a0
  if (p == initproc)
    800022f4:	00006797          	auipc	a5,0x6
    800022f8:	7f47b783          	ld	a5,2036(a5) # 80008ae8 <initproc>
    800022fc:	0d050493          	addi	s1,a0,208
    80002300:	15050913          	addi	s2,a0,336
    80002304:	02a79363          	bne	a5,a0,8000232a <exit+0x52>
    panic("init exiting");
    80002308:	00006517          	auipc	a0,0x6
    8000230c:	f5850513          	addi	a0,a0,-168 # 80008260 <digits+0x220>
    80002310:	ffffe097          	auipc	ra,0xffffe
    80002314:	230080e7          	jalr	560(ra) # 80000540 <panic>
      fileclose(f);
    80002318:	00002097          	auipc	ra,0x2
    8000231c:	566080e7          	jalr	1382(ra) # 8000487e <fileclose>
      p->ofile[fd] = 0;
    80002320:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002324:	04a1                	addi	s1,s1,8
    80002326:	01248563          	beq	s1,s2,80002330 <exit+0x58>
    if (p->ofile[fd])
    8000232a:	6088                	ld	a0,0(s1)
    8000232c:	f575                	bnez	a0,80002318 <exit+0x40>
    8000232e:	bfdd                	j	80002324 <exit+0x4c>
  begin_op();
    80002330:	00002097          	auipc	ra,0x2
    80002334:	086080e7          	jalr	134(ra) # 800043b6 <begin_op>
  iput(p->cwd);
    80002338:	1509b503          	ld	a0,336(s3)
    8000233c:	00002097          	auipc	ra,0x2
    80002340:	868080e7          	jalr	-1944(ra) # 80003ba4 <iput>
  end_op();
    80002344:	00002097          	auipc	ra,0x2
    80002348:	0f0080e7          	jalr	240(ra) # 80004434 <end_op>
  p->cwd = 0;
    8000234c:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002350:	0000f497          	auipc	s1,0xf
    80002354:	a2848493          	addi	s1,s1,-1496 # 80010d78 <wait_lock>
    80002358:	8526                	mv	a0,s1
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	87c080e7          	jalr	-1924(ra) # 80000bd6 <acquire>
  reparent(p);
    80002362:	854e                	mv	a0,s3
    80002364:	00000097          	auipc	ra,0x0
    80002368:	f1a080e7          	jalr	-230(ra) # 8000227e <reparent>
  wakeup(p->parent);
    8000236c:	0389b503          	ld	a0,56(s3)
    80002370:	00000097          	auipc	ra,0x0
    80002374:	e98080e7          	jalr	-360(ra) # 80002208 <wakeup>
  acquire(&p->lock);
    80002378:	854e                	mv	a0,s3
    8000237a:	fffff097          	auipc	ra,0xfffff
    8000237e:	85c080e7          	jalr	-1956(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002382:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002386:	4795                	li	a5,5
    80002388:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000238c:	8526                	mv	a0,s1
    8000238e:	fffff097          	auipc	ra,0xfffff
    80002392:	8fc080e7          	jalr	-1796(ra) # 80000c8a <release>
  sched();
    80002396:	00000097          	auipc	ra,0x0
    8000239a:	cfc080e7          	jalr	-772(ra) # 80002092 <sched>
  panic("zombie exit");
    8000239e:	00006517          	auipc	a0,0x6
    800023a2:	ed250513          	addi	a0,a0,-302 # 80008270 <digits+0x230>
    800023a6:	ffffe097          	auipc	ra,0xffffe
    800023aa:	19a080e7          	jalr	410(ra) # 80000540 <panic>

00000000800023ae <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800023ae:	7179                	addi	sp,sp,-48
    800023b0:	f406                	sd	ra,40(sp)
    800023b2:	f022                	sd	s0,32(sp)
    800023b4:	ec26                	sd	s1,24(sp)
    800023b6:	e84a                	sd	s2,16(sp)
    800023b8:	e44e                	sd	s3,8(sp)
    800023ba:	1800                	addi	s0,sp,48
    800023bc:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800023be:	0000f497          	auipc	s1,0xf
    800023c2:	dd248493          	addi	s1,s1,-558 # 80011190 <proc>
    800023c6:	00016997          	auipc	s3,0x16
    800023ca:	9ca98993          	addi	s3,s3,-1590 # 80017d90 <tickslock>
  {
    acquire(&p->lock);
    800023ce:	8526                	mv	a0,s1
    800023d0:	fffff097          	auipc	ra,0xfffff
    800023d4:	806080e7          	jalr	-2042(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    800023d8:	589c                	lw	a5,48(s1)
    800023da:	01278d63          	beq	a5,s2,800023f4 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023de:	8526                	mv	a0,s1
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	8aa080e7          	jalr	-1878(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800023e8:	1b048493          	addi	s1,s1,432
    800023ec:	ff3491e3          	bne	s1,s3,800023ce <kill+0x20>
  }
  return -1;
    800023f0:	557d                	li	a0,-1
    800023f2:	a829                	j	8000240c <kill+0x5e>
      p->killed = 1;
    800023f4:	4785                	li	a5,1
    800023f6:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800023f8:	4c98                	lw	a4,24(s1)
    800023fa:	4789                	li	a5,2
    800023fc:	00f70f63          	beq	a4,a5,8000241a <kill+0x6c>
      release(&p->lock);
    80002400:	8526                	mv	a0,s1
    80002402:	fffff097          	auipc	ra,0xfffff
    80002406:	888080e7          	jalr	-1912(ra) # 80000c8a <release>
      return 0;
    8000240a:	4501                	li	a0,0
}
    8000240c:	70a2                	ld	ra,40(sp)
    8000240e:	7402                	ld	s0,32(sp)
    80002410:	64e2                	ld	s1,24(sp)
    80002412:	6942                	ld	s2,16(sp)
    80002414:	69a2                	ld	s3,8(sp)
    80002416:	6145                	addi	sp,sp,48
    80002418:	8082                	ret
        p->state = RUNNABLE;
    8000241a:	478d                	li	a5,3
    8000241c:	cc9c                	sw	a5,24(s1)
    8000241e:	b7cd                	j	80002400 <kill+0x52>

0000000080002420 <setkilled>:

void setkilled(struct proc *p)
{
    80002420:	1101                	addi	sp,sp,-32
    80002422:	ec06                	sd	ra,24(sp)
    80002424:	e822                	sd	s0,16(sp)
    80002426:	e426                	sd	s1,8(sp)
    80002428:	1000                	addi	s0,sp,32
    8000242a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000242c:	ffffe097          	auipc	ra,0xffffe
    80002430:	7aa080e7          	jalr	1962(ra) # 80000bd6 <acquire>
  p->killed = 1;
    80002434:	4785                	li	a5,1
    80002436:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002438:	8526                	mv	a0,s1
    8000243a:	fffff097          	auipc	ra,0xfffff
    8000243e:	850080e7          	jalr	-1968(ra) # 80000c8a <release>
}
    80002442:	60e2                	ld	ra,24(sp)
    80002444:	6442                	ld	s0,16(sp)
    80002446:	64a2                	ld	s1,8(sp)
    80002448:	6105                	addi	sp,sp,32
    8000244a:	8082                	ret

000000008000244c <killed>:

int killed(struct proc *p)
{
    8000244c:	1101                	addi	sp,sp,-32
    8000244e:	ec06                	sd	ra,24(sp)
    80002450:	e822                	sd	s0,16(sp)
    80002452:	e426                	sd	s1,8(sp)
    80002454:	e04a                	sd	s2,0(sp)
    80002456:	1000                	addi	s0,sp,32
    80002458:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    8000245a:	ffffe097          	auipc	ra,0xffffe
    8000245e:	77c080e7          	jalr	1916(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002462:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002466:	8526                	mv	a0,s1
    80002468:	fffff097          	auipc	ra,0xfffff
    8000246c:	822080e7          	jalr	-2014(ra) # 80000c8a <release>
  return k;
}
    80002470:	854a                	mv	a0,s2
    80002472:	60e2                	ld	ra,24(sp)
    80002474:	6442                	ld	s0,16(sp)
    80002476:	64a2                	ld	s1,8(sp)
    80002478:	6902                	ld	s2,0(sp)
    8000247a:	6105                	addi	sp,sp,32
    8000247c:	8082                	ret

000000008000247e <wait>:
{
    8000247e:	715d                	addi	sp,sp,-80
    80002480:	e486                	sd	ra,72(sp)
    80002482:	e0a2                	sd	s0,64(sp)
    80002484:	fc26                	sd	s1,56(sp)
    80002486:	f84a                	sd	s2,48(sp)
    80002488:	f44e                	sd	s3,40(sp)
    8000248a:	f052                	sd	s4,32(sp)
    8000248c:	ec56                	sd	s5,24(sp)
    8000248e:	e85a                	sd	s6,16(sp)
    80002490:	e45e                	sd	s7,8(sp)
    80002492:	e062                	sd	s8,0(sp)
    80002494:	0880                	addi	s0,sp,80
    80002496:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002498:	fffff097          	auipc	ra,0xfffff
    8000249c:	514080e7          	jalr	1300(ra) # 800019ac <myproc>
    800024a0:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800024a2:	0000f517          	auipc	a0,0xf
    800024a6:	8d650513          	addi	a0,a0,-1834 # 80010d78 <wait_lock>
    800024aa:	ffffe097          	auipc	ra,0xffffe
    800024ae:	72c080e7          	jalr	1836(ra) # 80000bd6 <acquire>
    havekids = 0;
    800024b2:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    800024b4:	4a15                	li	s4,5
        havekids = 1;
    800024b6:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800024b8:	00016997          	auipc	s3,0x16
    800024bc:	8d898993          	addi	s3,s3,-1832 # 80017d90 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800024c0:	0000fc17          	auipc	s8,0xf
    800024c4:	8b8c0c13          	addi	s8,s8,-1864 # 80010d78 <wait_lock>
    havekids = 0;
    800024c8:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800024ca:	0000f497          	auipc	s1,0xf
    800024ce:	cc648493          	addi	s1,s1,-826 # 80011190 <proc>
    800024d2:	a0bd                	j	80002540 <wait+0xc2>
          pid = pp->pid;
    800024d4:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800024d8:	000b0e63          	beqz	s6,800024f4 <wait+0x76>
    800024dc:	4691                	li	a3,4
    800024de:	02c48613          	addi	a2,s1,44
    800024e2:	85da                	mv	a1,s6
    800024e4:	05093503          	ld	a0,80(s2)
    800024e8:	fffff097          	auipc	ra,0xfffff
    800024ec:	184080e7          	jalr	388(ra) # 8000166c <copyout>
    800024f0:	02054563          	bltz	a0,8000251a <wait+0x9c>
          freeproc(pp);
    800024f4:	8526                	mv	a0,s1
    800024f6:	fffff097          	auipc	ra,0xfffff
    800024fa:	668080e7          	jalr	1640(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    800024fe:	8526                	mv	a0,s1
    80002500:	ffffe097          	auipc	ra,0xffffe
    80002504:	78a080e7          	jalr	1930(ra) # 80000c8a <release>
          release(&wait_lock);
    80002508:	0000f517          	auipc	a0,0xf
    8000250c:	87050513          	addi	a0,a0,-1936 # 80010d78 <wait_lock>
    80002510:	ffffe097          	auipc	ra,0xffffe
    80002514:	77a080e7          	jalr	1914(ra) # 80000c8a <release>
          return pid;
    80002518:	a0b5                	j	80002584 <wait+0x106>
            release(&pp->lock);
    8000251a:	8526                	mv	a0,s1
    8000251c:	ffffe097          	auipc	ra,0xffffe
    80002520:	76e080e7          	jalr	1902(ra) # 80000c8a <release>
            release(&wait_lock);
    80002524:	0000f517          	auipc	a0,0xf
    80002528:	85450513          	addi	a0,a0,-1964 # 80010d78 <wait_lock>
    8000252c:	ffffe097          	auipc	ra,0xffffe
    80002530:	75e080e7          	jalr	1886(ra) # 80000c8a <release>
            return -1;
    80002534:	59fd                	li	s3,-1
    80002536:	a0b9                	j	80002584 <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002538:	1b048493          	addi	s1,s1,432
    8000253c:	03348463          	beq	s1,s3,80002564 <wait+0xe6>
      if (pp->parent == p)
    80002540:	7c9c                	ld	a5,56(s1)
    80002542:	ff279be3          	bne	a5,s2,80002538 <wait+0xba>
        acquire(&pp->lock);
    80002546:	8526                	mv	a0,s1
    80002548:	ffffe097          	auipc	ra,0xffffe
    8000254c:	68e080e7          	jalr	1678(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    80002550:	4c9c                	lw	a5,24(s1)
    80002552:	f94781e3          	beq	a5,s4,800024d4 <wait+0x56>
        release(&pp->lock);
    80002556:	8526                	mv	a0,s1
    80002558:	ffffe097          	auipc	ra,0xffffe
    8000255c:	732080e7          	jalr	1842(ra) # 80000c8a <release>
        havekids = 1;
    80002560:	8756                	mv	a4,s5
    80002562:	bfd9                	j	80002538 <wait+0xba>
    if (!havekids || killed(p))
    80002564:	c719                	beqz	a4,80002572 <wait+0xf4>
    80002566:	854a                	mv	a0,s2
    80002568:	00000097          	auipc	ra,0x0
    8000256c:	ee4080e7          	jalr	-284(ra) # 8000244c <killed>
    80002570:	c51d                	beqz	a0,8000259e <wait+0x120>
      release(&wait_lock);
    80002572:	0000f517          	auipc	a0,0xf
    80002576:	80650513          	addi	a0,a0,-2042 # 80010d78 <wait_lock>
    8000257a:	ffffe097          	auipc	ra,0xffffe
    8000257e:	710080e7          	jalr	1808(ra) # 80000c8a <release>
      return -1;
    80002582:	59fd                	li	s3,-1
}
    80002584:	854e                	mv	a0,s3
    80002586:	60a6                	ld	ra,72(sp)
    80002588:	6406                	ld	s0,64(sp)
    8000258a:	74e2                	ld	s1,56(sp)
    8000258c:	7942                	ld	s2,48(sp)
    8000258e:	79a2                	ld	s3,40(sp)
    80002590:	7a02                	ld	s4,32(sp)
    80002592:	6ae2                	ld	s5,24(sp)
    80002594:	6b42                	ld	s6,16(sp)
    80002596:	6ba2                	ld	s7,8(sp)
    80002598:	6c02                	ld	s8,0(sp)
    8000259a:	6161                	addi	sp,sp,80
    8000259c:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000259e:	85e2                	mv	a1,s8
    800025a0:	854a                	mv	a0,s2
    800025a2:	00000097          	auipc	ra,0x0
    800025a6:	c02080e7          	jalr	-1022(ra) # 800021a4 <sleep>
    havekids = 0;
    800025aa:	bf39                	j	800024c8 <wait+0x4a>

00000000800025ac <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800025ac:	7179                	addi	sp,sp,-48
    800025ae:	f406                	sd	ra,40(sp)
    800025b0:	f022                	sd	s0,32(sp)
    800025b2:	ec26                	sd	s1,24(sp)
    800025b4:	e84a                	sd	s2,16(sp)
    800025b6:	e44e                	sd	s3,8(sp)
    800025b8:	e052                	sd	s4,0(sp)
    800025ba:	1800                	addi	s0,sp,48
    800025bc:	84aa                	mv	s1,a0
    800025be:	892e                	mv	s2,a1
    800025c0:	89b2                	mv	s3,a2
    800025c2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025c4:	fffff097          	auipc	ra,0xfffff
    800025c8:	3e8080e7          	jalr	1000(ra) # 800019ac <myproc>
  if (user_dst)
    800025cc:	c08d                	beqz	s1,800025ee <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800025ce:	86d2                	mv	a3,s4
    800025d0:	864e                	mv	a2,s3
    800025d2:	85ca                	mv	a1,s2
    800025d4:	6928                	ld	a0,80(a0)
    800025d6:	fffff097          	auipc	ra,0xfffff
    800025da:	096080e7          	jalr	150(ra) # 8000166c <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800025de:	70a2                	ld	ra,40(sp)
    800025e0:	7402                	ld	s0,32(sp)
    800025e2:	64e2                	ld	s1,24(sp)
    800025e4:	6942                	ld	s2,16(sp)
    800025e6:	69a2                	ld	s3,8(sp)
    800025e8:	6a02                	ld	s4,0(sp)
    800025ea:	6145                	addi	sp,sp,48
    800025ec:	8082                	ret
    memmove((char *)dst, src, len);
    800025ee:	000a061b          	sext.w	a2,s4
    800025f2:	85ce                	mv	a1,s3
    800025f4:	854a                	mv	a0,s2
    800025f6:	ffffe097          	auipc	ra,0xffffe
    800025fa:	738080e7          	jalr	1848(ra) # 80000d2e <memmove>
    return 0;
    800025fe:	8526                	mv	a0,s1
    80002600:	bff9                	j	800025de <either_copyout+0x32>

0000000080002602 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002602:	7179                	addi	sp,sp,-48
    80002604:	f406                	sd	ra,40(sp)
    80002606:	f022                	sd	s0,32(sp)
    80002608:	ec26                	sd	s1,24(sp)
    8000260a:	e84a                	sd	s2,16(sp)
    8000260c:	e44e                	sd	s3,8(sp)
    8000260e:	e052                	sd	s4,0(sp)
    80002610:	1800                	addi	s0,sp,48
    80002612:	892a                	mv	s2,a0
    80002614:	84ae                	mv	s1,a1
    80002616:	89b2                	mv	s3,a2
    80002618:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000261a:	fffff097          	auipc	ra,0xfffff
    8000261e:	392080e7          	jalr	914(ra) # 800019ac <myproc>
  if (user_src)
    80002622:	c08d                	beqz	s1,80002644 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002624:	86d2                	mv	a3,s4
    80002626:	864e                	mv	a2,s3
    80002628:	85ca                	mv	a1,s2
    8000262a:	6928                	ld	a0,80(a0)
    8000262c:	fffff097          	auipc	ra,0xfffff
    80002630:	0cc080e7          	jalr	204(ra) # 800016f8 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002634:	70a2                	ld	ra,40(sp)
    80002636:	7402                	ld	s0,32(sp)
    80002638:	64e2                	ld	s1,24(sp)
    8000263a:	6942                	ld	s2,16(sp)
    8000263c:	69a2                	ld	s3,8(sp)
    8000263e:	6a02                	ld	s4,0(sp)
    80002640:	6145                	addi	sp,sp,48
    80002642:	8082                	ret
    memmove(dst, (char *)src, len);
    80002644:	000a061b          	sext.w	a2,s4
    80002648:	85ce                	mv	a1,s3
    8000264a:	854a                	mv	a0,s2
    8000264c:	ffffe097          	auipc	ra,0xffffe
    80002650:	6e2080e7          	jalr	1762(ra) # 80000d2e <memmove>
    return 0;
    80002654:	8526                	mv	a0,s1
    80002656:	bff9                	j	80002634 <either_copyin+0x32>

0000000080002658 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002658:	715d                	addi	sp,sp,-80
    8000265a:	e486                	sd	ra,72(sp)
    8000265c:	e0a2                	sd	s0,64(sp)
    8000265e:	fc26                	sd	s1,56(sp)
    80002660:	f84a                	sd	s2,48(sp)
    80002662:	f44e                	sd	s3,40(sp)
    80002664:	f052                	sd	s4,32(sp)
    80002666:	ec56                	sd	s5,24(sp)
    80002668:	e85a                	sd	s6,16(sp)
    8000266a:	e45e                	sd	s7,8(sp)
    8000266c:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    8000266e:	00006517          	auipc	a0,0x6
    80002672:	a5a50513          	addi	a0,a0,-1446 # 800080c8 <digits+0x88>
    80002676:	ffffe097          	auipc	ra,0xffffe
    8000267a:	f14080e7          	jalr	-236(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000267e:	0000f497          	auipc	s1,0xf
    80002682:	c6a48493          	addi	s1,s1,-918 # 800112e8 <proc+0x158>
    80002686:	00016917          	auipc	s2,0x16
    8000268a:	86290913          	addi	s2,s2,-1950 # 80017ee8 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000268e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002690:	00006997          	auipc	s3,0x6
    80002694:	bf098993          	addi	s3,s3,-1040 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002698:	00006a97          	auipc	s5,0x6
    8000269c:	bf0a8a93          	addi	s5,s5,-1040 # 80008288 <digits+0x248>
    printf("\n");
    800026a0:	00006a17          	auipc	s4,0x6
    800026a4:	a28a0a13          	addi	s4,s4,-1496 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026a8:	00006b97          	auipc	s7,0x6
    800026ac:	c20b8b93          	addi	s7,s7,-992 # 800082c8 <states.0>
    800026b0:	a00d                	j	800026d2 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800026b2:	ed86a583          	lw	a1,-296(a3)
    800026b6:	8556                	mv	a0,s5
    800026b8:	ffffe097          	auipc	ra,0xffffe
    800026bc:	ed2080e7          	jalr	-302(ra) # 8000058a <printf>
    printf("\n");
    800026c0:	8552                	mv	a0,s4
    800026c2:	ffffe097          	auipc	ra,0xffffe
    800026c6:	ec8080e7          	jalr	-312(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800026ca:	1b048493          	addi	s1,s1,432
    800026ce:	03248263          	beq	s1,s2,800026f2 <procdump+0x9a>
    if (p->state == UNUSED)
    800026d2:	86a6                	mv	a3,s1
    800026d4:	ec04a783          	lw	a5,-320(s1)
    800026d8:	dbed                	beqz	a5,800026ca <procdump+0x72>
      state = "???";
    800026da:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026dc:	fcfb6be3          	bltu	s6,a5,800026b2 <procdump+0x5a>
    800026e0:	02079713          	slli	a4,a5,0x20
    800026e4:	01d75793          	srli	a5,a4,0x1d
    800026e8:	97de                	add	a5,a5,s7
    800026ea:	6390                	ld	a2,0(a5)
    800026ec:	f279                	bnez	a2,800026b2 <procdump+0x5a>
      state = "???";
    800026ee:	864e                	mv	a2,s3
    800026f0:	b7c9                	j	800026b2 <procdump+0x5a>
  }
}
    800026f2:	60a6                	ld	ra,72(sp)
    800026f4:	6406                	ld	s0,64(sp)
    800026f6:	74e2                	ld	s1,56(sp)
    800026f8:	7942                	ld	s2,48(sp)
    800026fa:	79a2                	ld	s3,40(sp)
    800026fc:	7a02                	ld	s4,32(sp)
    800026fe:	6ae2                	ld	s5,24(sp)
    80002700:	6b42                	ld	s6,16(sp)
    80002702:	6ba2                	ld	s7,8(sp)
    80002704:	6161                	addi	sp,sp,80
    80002706:	8082                	ret

0000000080002708 <update_timer>:

// CUSTOM FUNCTIONS TO IMPLEMENT PBS SCHEDULER
void update_timer()
{
    80002708:	7179                	addi	sp,sp,-48
    8000270a:	f406                	sd	ra,40(sp)
    8000270c:	f022                	sd	s0,32(sp)
    8000270e:	ec26                	sd	s1,24(sp)
    80002710:	e84a                	sd	s2,16(sp)
    80002712:	e44e                	sd	s3,8(sp)
    80002714:	e052                	sd	s4,0(sp)
    80002716:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002718:	0000f497          	auipc	s1,0xf
    8000271c:	a7848493          	addi	s1,s1,-1416 # 80011190 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002720:	4991                	li	s3,4
    {
      p->last_run_time++;
      p->total_run_time++;
    }
    if (p->state == SLEEPING)
    80002722:	4a09                	li	s4,2
  for (p = proc; p < &proc[NPROC]; p++)
    80002724:	00015917          	auipc	s2,0x15
    80002728:	66c90913          	addi	s2,s2,1644 # 80017d90 <tickslock>
    8000272c:	a025                	j	80002754 <update_timer+0x4c>
      p->last_run_time++;
    8000272e:	1a44a783          	lw	a5,420(s1)
    80002732:	2785                	addiw	a5,a5,1
    80002734:	1af4a223          	sw	a5,420(s1)
      p->total_run_time++;
    80002738:	1a84a783          	lw	a5,424(s1)
    8000273c:	2785                	addiw	a5,a5,1
    8000273e:	1af4a423          	sw	a5,424(s1)
    {
      p->last_sleep_time++;
    }
    release(&p->lock);
    80002742:	8526                	mv	a0,s1
    80002744:	ffffe097          	auipc	ra,0xffffe
    80002748:	546080e7          	jalr	1350(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000274c:	1b048493          	addi	s1,s1,432
    80002750:	03248263          	beq	s1,s2,80002774 <update_timer+0x6c>
    acquire(&p->lock);
    80002754:	8526                	mv	a0,s1
    80002756:	ffffe097          	auipc	ra,0xffffe
    8000275a:	480080e7          	jalr	1152(ra) # 80000bd6 <acquire>
    if (p->state == RUNNING)
    8000275e:	4c9c                	lw	a5,24(s1)
    80002760:	fd3787e3          	beq	a5,s3,8000272e <update_timer+0x26>
    if (p->state == SLEEPING)
    80002764:	fd479fe3          	bne	a5,s4,80002742 <update_timer+0x3a>
      p->last_sleep_time++;
    80002768:	1a04a783          	lw	a5,416(s1)
    8000276c:	2785                	addiw	a5,a5,1
    8000276e:	1af4a023          	sw	a5,416(s1)
    80002772:	bfc1                	j	80002742 <update_timer+0x3a>
  }
}
    80002774:	70a2                	ld	ra,40(sp)
    80002776:	7402                	ld	s0,32(sp)
    80002778:	64e2                	ld	s1,24(sp)
    8000277a:	6942                	ld	s2,16(sp)
    8000277c:	69a2                	ld	s3,8(sp)
    8000277e:	6a02                	ld	s4,0(sp)
    80002780:	6145                	addi	sp,sp,48
    80002782:	8082                	ret

0000000080002784 <setpriority>:

int setpriority(int new_priority, int proc_pid)
{
    80002784:	7179                	addi	sp,sp,-48
    80002786:	f406                	sd	ra,40(sp)
    80002788:	f022                	sd	s0,32(sp)
    8000278a:	ec26                	sd	s1,24(sp)
    8000278c:	e84a                	sd	s2,16(sp)
    8000278e:	e44e                	sd	s3,8(sp)
    80002790:	e052                	sd	s4,0(sp)
    80002792:	1800                	addi	s0,sp,48
    80002794:	8a2a                	mv	s4,a0
    80002796:	892e                	mv	s2,a1
  struct proc* p;
  int old_priority;
  int found_proc = 0;
  for(p = proc; p < &proc[NPROC]; p++)
    80002798:	0000f497          	auipc	s1,0xf
    8000279c:	9f848493          	addi	s1,s1,-1544 # 80011190 <proc>
    800027a0:	00015997          	auipc	s3,0x15
    800027a4:	5f098993          	addi	s3,s3,1520 # 80017d90 <tickslock>
  {
    acquire(&p->lock);
    800027a8:	8526                	mv	a0,s1
    800027aa:	ffffe097          	auipc	ra,0xffffe
    800027ae:	42c080e7          	jalr	1068(ra) # 80000bd6 <acquire>
    if (p->pid == proc_pid)
    800027b2:	589c                	lw	a5,48(s1)
    800027b4:	01278d63          	beq	a5,s2,800027ce <setpriority+0x4a>
      p->priority = new_priority;
      release(&p->lock);
      found_proc = 1;
      break;
    }
    release(&p->lock);
    800027b8:	8526                	mv	a0,s1
    800027ba:	ffffe097          	auipc	ra,0xffffe
    800027be:	4d0080e7          	jalr	1232(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++)
    800027c2:	1b048493          	addi	s1,s1,432
    800027c6:	ff3491e3          	bne	s1,s3,800027a8 <setpriority+0x24>
  {
    return old_priority;
  }
  else
  {
    return -1;
    800027ca:	597d                	li	s2,-1
    800027cc:	a811                	j	800027e0 <setpriority+0x5c>
      old_priority = p->priority;
    800027ce:	1984a903          	lw	s2,408(s1)
      p->priority = new_priority;
    800027d2:	1944ac23          	sw	s4,408(s1)
      release(&p->lock);
    800027d6:	8526                	mv	a0,s1
    800027d8:	ffffe097          	auipc	ra,0xffffe
    800027dc:	4b2080e7          	jalr	1202(ra) # 80000c8a <release>
  }
    800027e0:	854a                	mv	a0,s2
    800027e2:	70a2                	ld	ra,40(sp)
    800027e4:	7402                	ld	s0,32(sp)
    800027e6:	64e2                	ld	s1,24(sp)
    800027e8:	6942                	ld	s2,16(sp)
    800027ea:	69a2                	ld	s3,8(sp)
    800027ec:	6a02                	ld	s4,0(sp)
    800027ee:	6145                	addi	sp,sp,48
    800027f0:	8082                	ret

00000000800027f2 <swtch>:
    800027f2:	00153023          	sd	ra,0(a0)
    800027f6:	00253423          	sd	sp,8(a0)
    800027fa:	e900                	sd	s0,16(a0)
    800027fc:	ed04                	sd	s1,24(a0)
    800027fe:	03253023          	sd	s2,32(a0)
    80002802:	03353423          	sd	s3,40(a0)
    80002806:	03453823          	sd	s4,48(a0)
    8000280a:	03553c23          	sd	s5,56(a0)
    8000280e:	05653023          	sd	s6,64(a0)
    80002812:	05753423          	sd	s7,72(a0)
    80002816:	05853823          	sd	s8,80(a0)
    8000281a:	05953c23          	sd	s9,88(a0)
    8000281e:	07a53023          	sd	s10,96(a0)
    80002822:	07b53423          	sd	s11,104(a0)
    80002826:	0005b083          	ld	ra,0(a1)
    8000282a:	0085b103          	ld	sp,8(a1)
    8000282e:	6980                	ld	s0,16(a1)
    80002830:	6d84                	ld	s1,24(a1)
    80002832:	0205b903          	ld	s2,32(a1)
    80002836:	0285b983          	ld	s3,40(a1)
    8000283a:	0305ba03          	ld	s4,48(a1)
    8000283e:	0385ba83          	ld	s5,56(a1)
    80002842:	0405bb03          	ld	s6,64(a1)
    80002846:	0485bb83          	ld	s7,72(a1)
    8000284a:	0505bc03          	ld	s8,80(a1)
    8000284e:	0585bc83          	ld	s9,88(a1)
    80002852:	0605bd03          	ld	s10,96(a1)
    80002856:	0685bd83          	ld	s11,104(a1)
    8000285a:	8082                	ret

000000008000285c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000285c:	1141                	addi	sp,sp,-16
    8000285e:	e406                	sd	ra,8(sp)
    80002860:	e022                	sd	s0,0(sp)
    80002862:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002864:	00006597          	auipc	a1,0x6
    80002868:	a9458593          	addi	a1,a1,-1388 # 800082f8 <states.0+0x30>
    8000286c:	00015517          	auipc	a0,0x15
    80002870:	52450513          	addi	a0,a0,1316 # 80017d90 <tickslock>
    80002874:	ffffe097          	auipc	ra,0xffffe
    80002878:	2d2080e7          	jalr	722(ra) # 80000b46 <initlock>
}
    8000287c:	60a2                	ld	ra,8(sp)
    8000287e:	6402                	ld	s0,0(sp)
    80002880:	0141                	addi	sp,sp,16
    80002882:	8082                	ret

0000000080002884 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002884:	1141                	addi	sp,sp,-16
    80002886:	e422                	sd	s0,8(sp)
    80002888:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000288a:	00003797          	auipc	a5,0x3
    8000288e:	64678793          	addi	a5,a5,1606 # 80005ed0 <kernelvec>
    80002892:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002896:	6422                	ld	s0,8(sp)
    80002898:	0141                	addi	sp,sp,16
    8000289a:	8082                	ret

000000008000289c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000289c:	1141                	addi	sp,sp,-16
    8000289e:	e406                	sd	ra,8(sp)
    800028a0:	e022                	sd	s0,0(sp)
    800028a2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800028a4:	fffff097          	auipc	ra,0xfffff
    800028a8:	108080e7          	jalr	264(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800028b0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028b2:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800028b6:	00004697          	auipc	a3,0x4
    800028ba:	74a68693          	addi	a3,a3,1866 # 80007000 <_trampoline>
    800028be:	00004717          	auipc	a4,0x4
    800028c2:	74270713          	addi	a4,a4,1858 # 80007000 <_trampoline>
    800028c6:	8f15                	sub	a4,a4,a3
    800028c8:	040007b7          	lui	a5,0x4000
    800028cc:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800028ce:	07b2                	slli	a5,a5,0xc
    800028d0:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028d2:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800028d6:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800028d8:	18002673          	csrr	a2,satp
    800028dc:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800028de:	6d30                	ld	a2,88(a0)
    800028e0:	6138                	ld	a4,64(a0)
    800028e2:	6585                	lui	a1,0x1
    800028e4:	972e                	add	a4,a4,a1
    800028e6:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800028e8:	6d38                	ld	a4,88(a0)
    800028ea:	00000617          	auipc	a2,0x0
    800028ee:	13e60613          	addi	a2,a2,318 # 80002a28 <usertrap>
    800028f2:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800028f4:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800028f6:	8612                	mv	a2,tp
    800028f8:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028fa:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028fe:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002902:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002906:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000290a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000290c:	6f18                	ld	a4,24(a4)
    8000290e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002912:	6928                	ld	a0,80(a0)
    80002914:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002916:	00004717          	auipc	a4,0x4
    8000291a:	78670713          	addi	a4,a4,1926 # 8000709c <userret>
    8000291e:	8f15                	sub	a4,a4,a3
    80002920:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002922:	577d                	li	a4,-1
    80002924:	177e                	slli	a4,a4,0x3f
    80002926:	8d59                	or	a0,a0,a4
    80002928:	9782                	jalr	a5
}
    8000292a:	60a2                	ld	ra,8(sp)
    8000292c:	6402                	ld	s0,0(sp)
    8000292e:	0141                	addi	sp,sp,16
    80002930:	8082                	ret

0000000080002932 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002932:	1101                	addi	sp,sp,-32
    80002934:	ec06                	sd	ra,24(sp)
    80002936:	e822                	sd	s0,16(sp)
    80002938:	e426                	sd	s1,8(sp)
    8000293a:	e04a                	sd	s2,0(sp)
    8000293c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000293e:	00015917          	auipc	s2,0x15
    80002942:	45290913          	addi	s2,s2,1106 # 80017d90 <tickslock>
    80002946:	854a                	mv	a0,s2
    80002948:	ffffe097          	auipc	ra,0xffffe
    8000294c:	28e080e7          	jalr	654(ra) # 80000bd6 <acquire>
  ticks++;
    80002950:	00006497          	auipc	s1,0x6
    80002954:	1a048493          	addi	s1,s1,416 # 80008af0 <ticks>
    80002958:	409c                	lw	a5,0(s1)
    8000295a:	2785                	addiw	a5,a5,1
    8000295c:	c09c                	sw	a5,0(s1)
  update_timer();
    8000295e:	00000097          	auipc	ra,0x0
    80002962:	daa080e7          	jalr	-598(ra) # 80002708 <update_timer>
  wakeup(&ticks);
    80002966:	8526                	mv	a0,s1
    80002968:	00000097          	auipc	ra,0x0
    8000296c:	8a0080e7          	jalr	-1888(ra) # 80002208 <wakeup>
  release(&tickslock);
    80002970:	854a                	mv	a0,s2
    80002972:	ffffe097          	auipc	ra,0xffffe
    80002976:	318080e7          	jalr	792(ra) # 80000c8a <release>
}
    8000297a:	60e2                	ld	ra,24(sp)
    8000297c:	6442                	ld	s0,16(sp)
    8000297e:	64a2                	ld	s1,8(sp)
    80002980:	6902                	ld	s2,0(sp)
    80002982:	6105                	addi	sp,sp,32
    80002984:	8082                	ret

0000000080002986 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002986:	1101                	addi	sp,sp,-32
    80002988:	ec06                	sd	ra,24(sp)
    8000298a:	e822                	sd	s0,16(sp)
    8000298c:	e426                	sd	s1,8(sp)
    8000298e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002990:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002994:	00074d63          	bltz	a4,800029ae <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002998:	57fd                	li	a5,-1
    8000299a:	17fe                	slli	a5,a5,0x3f
    8000299c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000299e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800029a0:	06f70363          	beq	a4,a5,80002a06 <devintr+0x80>
  }
}
    800029a4:	60e2                	ld	ra,24(sp)
    800029a6:	6442                	ld	s0,16(sp)
    800029a8:	64a2                	ld	s1,8(sp)
    800029aa:	6105                	addi	sp,sp,32
    800029ac:	8082                	ret
     (scause & 0xff) == 9){
    800029ae:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    800029b2:	46a5                	li	a3,9
    800029b4:	fed792e3          	bne	a5,a3,80002998 <devintr+0x12>
    int irq = plic_claim();
    800029b8:	00003097          	auipc	ra,0x3
    800029bc:	620080e7          	jalr	1568(ra) # 80005fd8 <plic_claim>
    800029c0:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800029c2:	47a9                	li	a5,10
    800029c4:	02f50763          	beq	a0,a5,800029f2 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800029c8:	4785                	li	a5,1
    800029ca:	02f50963          	beq	a0,a5,800029fc <devintr+0x76>
    return 1;
    800029ce:	4505                	li	a0,1
    } else if(irq){
    800029d0:	d8f1                	beqz	s1,800029a4 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800029d2:	85a6                	mv	a1,s1
    800029d4:	00006517          	auipc	a0,0x6
    800029d8:	92c50513          	addi	a0,a0,-1748 # 80008300 <states.0+0x38>
    800029dc:	ffffe097          	auipc	ra,0xffffe
    800029e0:	bae080e7          	jalr	-1106(ra) # 8000058a <printf>
      plic_complete(irq);
    800029e4:	8526                	mv	a0,s1
    800029e6:	00003097          	auipc	ra,0x3
    800029ea:	616080e7          	jalr	1558(ra) # 80005ffc <plic_complete>
    return 1;
    800029ee:	4505                	li	a0,1
    800029f0:	bf55                	j	800029a4 <devintr+0x1e>
      uartintr();
    800029f2:	ffffe097          	auipc	ra,0xffffe
    800029f6:	fa6080e7          	jalr	-90(ra) # 80000998 <uartintr>
    800029fa:	b7ed                	j	800029e4 <devintr+0x5e>
      virtio_disk_intr();
    800029fc:	00004097          	auipc	ra,0x4
    80002a00:	ac8080e7          	jalr	-1336(ra) # 800064c4 <virtio_disk_intr>
    80002a04:	b7c5                	j	800029e4 <devintr+0x5e>
    if(cpuid() == 0){
    80002a06:	fffff097          	auipc	ra,0xfffff
    80002a0a:	f7a080e7          	jalr	-134(ra) # 80001980 <cpuid>
    80002a0e:	c901                	beqz	a0,80002a1e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a10:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a14:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a16:	14479073          	csrw	sip,a5
    return 2;
    80002a1a:	4509                	li	a0,2
    80002a1c:	b761                	j	800029a4 <devintr+0x1e>
      clockintr();
    80002a1e:	00000097          	auipc	ra,0x0
    80002a22:	f14080e7          	jalr	-236(ra) # 80002932 <clockintr>
    80002a26:	b7ed                	j	80002a10 <devintr+0x8a>

0000000080002a28 <usertrap>:
{
    80002a28:	1101                	addi	sp,sp,-32
    80002a2a:	ec06                	sd	ra,24(sp)
    80002a2c:	e822                	sd	s0,16(sp)
    80002a2e:	e426                	sd	s1,8(sp)
    80002a30:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a32:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a36:	1007f793          	andi	a5,a5,256
    80002a3a:	efa1                	bnez	a5,80002a92 <usertrap+0x6a>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a3c:	00003797          	auipc	a5,0x3
    80002a40:	49478793          	addi	a5,a5,1172 # 80005ed0 <kernelvec>
    80002a44:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a48:	fffff097          	auipc	ra,0xfffff
    80002a4c:	f64080e7          	jalr	-156(ra) # 800019ac <myproc>
    80002a50:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a52:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a54:	14102773          	csrr	a4,sepc
    80002a58:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a5a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a5e:	47a1                	li	a5,8
    80002a60:	04f70163          	beq	a4,a5,80002aa2 <usertrap+0x7a>
  } else if((which_dev = devintr()) != 0){
    80002a64:	00000097          	auipc	ra,0x0
    80002a68:	f22080e7          	jalr	-222(ra) # 80002986 <devintr>
    80002a6c:	cd4d                	beqz	a0,80002b26 <usertrap+0xfe>
    if(which_dev == 2 && myproc()->interval) {
    80002a6e:	4789                	li	a5,2
    80002a70:	06f50363          	beq	a0,a5,80002ad6 <usertrap+0xae>
  if(killed(p))
    80002a74:	8526                	mv	a0,s1
    80002a76:	00000097          	auipc	ra,0x0
    80002a7a:	9d6080e7          	jalr	-1578(ra) # 8000244c <killed>
    80002a7e:	e16d                	bnez	a0,80002b60 <usertrap+0x138>
  usertrapret();
    80002a80:	00000097          	auipc	ra,0x0
    80002a84:	e1c080e7          	jalr	-484(ra) # 8000289c <usertrapret>
}
    80002a88:	60e2                	ld	ra,24(sp)
    80002a8a:	6442                	ld	s0,16(sp)
    80002a8c:	64a2                	ld	s1,8(sp)
    80002a8e:	6105                	addi	sp,sp,32
    80002a90:	8082                	ret
    panic("usertrap: not from user mode");
    80002a92:	00006517          	auipc	a0,0x6
    80002a96:	88e50513          	addi	a0,a0,-1906 # 80008320 <states.0+0x58>
    80002a9a:	ffffe097          	auipc	ra,0xffffe
    80002a9e:	aa6080e7          	jalr	-1370(ra) # 80000540 <panic>
    if(killed(p))
    80002aa2:	00000097          	auipc	ra,0x0
    80002aa6:	9aa080e7          	jalr	-1622(ra) # 8000244c <killed>
    80002aaa:	e105                	bnez	a0,80002aca <usertrap+0xa2>
    p->trapframe->epc += 4;
    80002aac:	6cb8                	ld	a4,88(s1)
    80002aae:	6f1c                	ld	a5,24(a4)
    80002ab0:	0791                	addi	a5,a5,4
    80002ab2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ab4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002ab8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002abc:	10079073          	csrw	sstatus,a5
    syscall();
    80002ac0:	00000097          	auipc	ra,0x0
    80002ac4:	2cc080e7          	jalr	716(ra) # 80002d8c <syscall>
    80002ac8:	b775                	j	80002a74 <usertrap+0x4c>
      exit(-1);
    80002aca:	557d                	li	a0,-1
    80002acc:	00000097          	auipc	ra,0x0
    80002ad0:	80c080e7          	jalr	-2036(ra) # 800022d8 <exit>
    80002ad4:	bfe1                	j	80002aac <usertrap+0x84>
    if(which_dev == 2 && myproc()->interval) {
    80002ad6:	fffff097          	auipc	ra,0xfffff
    80002ada:	ed6080e7          	jalr	-298(ra) # 800019ac <myproc>
    80002ade:	16c52783          	lw	a5,364(a0)
    80002ae2:	dbc9                	beqz	a5,80002a74 <usertrap+0x4c>
      myproc()->ticks_left--;
    80002ae4:	fffff097          	auipc	ra,0xfffff
    80002ae8:	ec8080e7          	jalr	-312(ra) # 800019ac <myproc>
    80002aec:	17052783          	lw	a5,368(a0)
    80002af0:	37fd                	addiw	a5,a5,-1
    80002af2:	16f52823          	sw	a5,368(a0)
      if(myproc()->ticks_left == 0) {
    80002af6:	fffff097          	auipc	ra,0xfffff
    80002afa:	eb6080e7          	jalr	-330(ra) # 800019ac <myproc>
    80002afe:	17052783          	lw	a5,368(a0)
    80002b02:	fbad                	bnez	a5,80002a74 <usertrap+0x4c>
        p->sigalarm_tf = kalloc();
    80002b04:	ffffe097          	auipc	ra,0xffffe
    80002b08:	fe2080e7          	jalr	-30(ra) # 80000ae6 <kalloc>
    80002b0c:	18a4b023          	sd	a0,384(s1)
        memmove(p->sigalarm_tf, p->trapframe, PGSIZE);
    80002b10:	6605                	lui	a2,0x1
    80002b12:	6cac                	ld	a1,88(s1)
    80002b14:	ffffe097          	auipc	ra,0xffffe
    80002b18:	21a080e7          	jalr	538(ra) # 80000d2e <memmove>
        p->trapframe->epc = p->sig_handler;
    80002b1c:	6cbc                	ld	a5,88(s1)
    80002b1e:	1784b703          	ld	a4,376(s1)
    80002b22:	ef98                	sd	a4,24(a5)
    80002b24:	bf81                	j	80002a74 <usertrap+0x4c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b26:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b2a:	5890                	lw	a2,48(s1)
    80002b2c:	00006517          	auipc	a0,0x6
    80002b30:	81450513          	addi	a0,a0,-2028 # 80008340 <states.0+0x78>
    80002b34:	ffffe097          	auipc	ra,0xffffe
    80002b38:	a56080e7          	jalr	-1450(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b3c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b40:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b44:	00006517          	auipc	a0,0x6
    80002b48:	82c50513          	addi	a0,a0,-2004 # 80008370 <states.0+0xa8>
    80002b4c:	ffffe097          	auipc	ra,0xffffe
    80002b50:	a3e080e7          	jalr	-1474(ra) # 8000058a <printf>
    setkilled(p);
    80002b54:	8526                	mv	a0,s1
    80002b56:	00000097          	auipc	ra,0x0
    80002b5a:	8ca080e7          	jalr	-1846(ra) # 80002420 <setkilled>
    80002b5e:	bf19                	j	80002a74 <usertrap+0x4c>
    exit(-1);
    80002b60:	557d                	li	a0,-1
    80002b62:	fffff097          	auipc	ra,0xfffff
    80002b66:	776080e7          	jalr	1910(ra) # 800022d8 <exit>
    80002b6a:	bf19                	j	80002a80 <usertrap+0x58>

0000000080002b6c <kerneltrap>:
{
    80002b6c:	7179                	addi	sp,sp,-48
    80002b6e:	f406                	sd	ra,40(sp)
    80002b70:	f022                	sd	s0,32(sp)
    80002b72:	ec26                	sd	s1,24(sp)
    80002b74:	e84a                	sd	s2,16(sp)
    80002b76:	e44e                	sd	s3,8(sp)
    80002b78:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b7a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b7e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b82:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b86:	1004f793          	andi	a5,s1,256
    80002b8a:	c78d                	beqz	a5,80002bb4 <kerneltrap+0x48>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b8c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b90:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b92:	eb8d                	bnez	a5,80002bc4 <kerneltrap+0x58>
  if((which_dev = devintr()) == 0){
    80002b94:	00000097          	auipc	ra,0x0
    80002b98:	df2080e7          	jalr	-526(ra) # 80002986 <devintr>
    80002b9c:	cd05                	beqz	a0,80002bd4 <kerneltrap+0x68>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b9e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ba2:	10049073          	csrw	sstatus,s1
}
    80002ba6:	70a2                	ld	ra,40(sp)
    80002ba8:	7402                	ld	s0,32(sp)
    80002baa:	64e2                	ld	s1,24(sp)
    80002bac:	6942                	ld	s2,16(sp)
    80002bae:	69a2                	ld	s3,8(sp)
    80002bb0:	6145                	addi	sp,sp,48
    80002bb2:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002bb4:	00005517          	auipc	a0,0x5
    80002bb8:	7dc50513          	addi	a0,a0,2012 # 80008390 <states.0+0xc8>
    80002bbc:	ffffe097          	auipc	ra,0xffffe
    80002bc0:	984080e7          	jalr	-1660(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002bc4:	00005517          	auipc	a0,0x5
    80002bc8:	7f450513          	addi	a0,a0,2036 # 800083b8 <states.0+0xf0>
    80002bcc:	ffffe097          	auipc	ra,0xffffe
    80002bd0:	974080e7          	jalr	-1676(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002bd4:	85ce                	mv	a1,s3
    80002bd6:	00006517          	auipc	a0,0x6
    80002bda:	80250513          	addi	a0,a0,-2046 # 800083d8 <states.0+0x110>
    80002bde:	ffffe097          	auipc	ra,0xffffe
    80002be2:	9ac080e7          	jalr	-1620(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002be6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bea:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bee:	00005517          	auipc	a0,0x5
    80002bf2:	7fa50513          	addi	a0,a0,2042 # 800083e8 <states.0+0x120>
    80002bf6:	ffffe097          	auipc	ra,0xffffe
    80002bfa:	994080e7          	jalr	-1644(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002bfe:	00006517          	auipc	a0,0x6
    80002c02:	80250513          	addi	a0,a0,-2046 # 80008400 <states.0+0x138>
    80002c06:	ffffe097          	auipc	ra,0xffffe
    80002c0a:	93a080e7          	jalr	-1734(ra) # 80000540 <panic>

0000000080002c0e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c0e:	1101                	addi	sp,sp,-32
    80002c10:	ec06                	sd	ra,24(sp)
    80002c12:	e822                	sd	s0,16(sp)
    80002c14:	e426                	sd	s1,8(sp)
    80002c16:	1000                	addi	s0,sp,32
    80002c18:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c1a:	fffff097          	auipc	ra,0xfffff
    80002c1e:	d92080e7          	jalr	-622(ra) # 800019ac <myproc>
  switch (n) {
    80002c22:	4795                	li	a5,5
    80002c24:	0497e163          	bltu	a5,s1,80002c66 <argraw+0x58>
    80002c28:	048a                	slli	s1,s1,0x2
    80002c2a:	00006717          	auipc	a4,0x6
    80002c2e:	8fe70713          	addi	a4,a4,-1794 # 80008528 <states.0+0x260>
    80002c32:	94ba                	add	s1,s1,a4
    80002c34:	409c                	lw	a5,0(s1)
    80002c36:	97ba                	add	a5,a5,a4
    80002c38:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c3a:	6d3c                	ld	a5,88(a0)
    80002c3c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c3e:	60e2                	ld	ra,24(sp)
    80002c40:	6442                	ld	s0,16(sp)
    80002c42:	64a2                	ld	s1,8(sp)
    80002c44:	6105                	addi	sp,sp,32
    80002c46:	8082                	ret
    return p->trapframe->a1;
    80002c48:	6d3c                	ld	a5,88(a0)
    80002c4a:	7fa8                	ld	a0,120(a5)
    80002c4c:	bfcd                	j	80002c3e <argraw+0x30>
    return p->trapframe->a2;
    80002c4e:	6d3c                	ld	a5,88(a0)
    80002c50:	63c8                	ld	a0,128(a5)
    80002c52:	b7f5                	j	80002c3e <argraw+0x30>
    return p->trapframe->a3;
    80002c54:	6d3c                	ld	a5,88(a0)
    80002c56:	67c8                	ld	a0,136(a5)
    80002c58:	b7dd                	j	80002c3e <argraw+0x30>
    return p->trapframe->a4;
    80002c5a:	6d3c                	ld	a5,88(a0)
    80002c5c:	6bc8                	ld	a0,144(a5)
    80002c5e:	b7c5                	j	80002c3e <argraw+0x30>
    return p->trapframe->a5;
    80002c60:	6d3c                	ld	a5,88(a0)
    80002c62:	6fc8                	ld	a0,152(a5)
    80002c64:	bfe9                	j	80002c3e <argraw+0x30>
  panic("argraw");
    80002c66:	00005517          	auipc	a0,0x5
    80002c6a:	7aa50513          	addi	a0,a0,1962 # 80008410 <states.0+0x148>
    80002c6e:	ffffe097          	auipc	ra,0xffffe
    80002c72:	8d2080e7          	jalr	-1838(ra) # 80000540 <panic>

0000000080002c76 <fetchaddr>:
{
    80002c76:	1101                	addi	sp,sp,-32
    80002c78:	ec06                	sd	ra,24(sp)
    80002c7a:	e822                	sd	s0,16(sp)
    80002c7c:	e426                	sd	s1,8(sp)
    80002c7e:	e04a                	sd	s2,0(sp)
    80002c80:	1000                	addi	s0,sp,32
    80002c82:	84aa                	mv	s1,a0
    80002c84:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c86:	fffff097          	auipc	ra,0xfffff
    80002c8a:	d26080e7          	jalr	-730(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002c8e:	653c                	ld	a5,72(a0)
    80002c90:	02f4f863          	bgeu	s1,a5,80002cc0 <fetchaddr+0x4a>
    80002c94:	00848713          	addi	a4,s1,8
    80002c98:	02e7e663          	bltu	a5,a4,80002cc4 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c9c:	46a1                	li	a3,8
    80002c9e:	8626                	mv	a2,s1
    80002ca0:	85ca                	mv	a1,s2
    80002ca2:	6928                	ld	a0,80(a0)
    80002ca4:	fffff097          	auipc	ra,0xfffff
    80002ca8:	a54080e7          	jalr	-1452(ra) # 800016f8 <copyin>
    80002cac:	00a03533          	snez	a0,a0
    80002cb0:	40a00533          	neg	a0,a0
}
    80002cb4:	60e2                	ld	ra,24(sp)
    80002cb6:	6442                	ld	s0,16(sp)
    80002cb8:	64a2                	ld	s1,8(sp)
    80002cba:	6902                	ld	s2,0(sp)
    80002cbc:	6105                	addi	sp,sp,32
    80002cbe:	8082                	ret
    return -1;
    80002cc0:	557d                	li	a0,-1
    80002cc2:	bfcd                	j	80002cb4 <fetchaddr+0x3e>
    80002cc4:	557d                	li	a0,-1
    80002cc6:	b7fd                	j	80002cb4 <fetchaddr+0x3e>

0000000080002cc8 <fetchstr>:
{
    80002cc8:	7179                	addi	sp,sp,-48
    80002cca:	f406                	sd	ra,40(sp)
    80002ccc:	f022                	sd	s0,32(sp)
    80002cce:	ec26                	sd	s1,24(sp)
    80002cd0:	e84a                	sd	s2,16(sp)
    80002cd2:	e44e                	sd	s3,8(sp)
    80002cd4:	1800                	addi	s0,sp,48
    80002cd6:	892a                	mv	s2,a0
    80002cd8:	84ae                	mv	s1,a1
    80002cda:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002cdc:	fffff097          	auipc	ra,0xfffff
    80002ce0:	cd0080e7          	jalr	-816(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002ce4:	86ce                	mv	a3,s3
    80002ce6:	864a                	mv	a2,s2
    80002ce8:	85a6                	mv	a1,s1
    80002cea:	6928                	ld	a0,80(a0)
    80002cec:	fffff097          	auipc	ra,0xfffff
    80002cf0:	a9a080e7          	jalr	-1382(ra) # 80001786 <copyinstr>
    80002cf4:	00054e63          	bltz	a0,80002d10 <fetchstr+0x48>
  return strlen(buf);
    80002cf8:	8526                	mv	a0,s1
    80002cfa:	ffffe097          	auipc	ra,0xffffe
    80002cfe:	154080e7          	jalr	340(ra) # 80000e4e <strlen>
}
    80002d02:	70a2                	ld	ra,40(sp)
    80002d04:	7402                	ld	s0,32(sp)
    80002d06:	64e2                	ld	s1,24(sp)
    80002d08:	6942                	ld	s2,16(sp)
    80002d0a:	69a2                	ld	s3,8(sp)
    80002d0c:	6145                	addi	sp,sp,48
    80002d0e:	8082                	ret
    return -1;
    80002d10:	557d                	li	a0,-1
    80002d12:	bfc5                	j	80002d02 <fetchstr+0x3a>

0000000080002d14 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002d14:	1101                	addi	sp,sp,-32
    80002d16:	ec06                	sd	ra,24(sp)
    80002d18:	e822                	sd	s0,16(sp)
    80002d1a:	e426                	sd	s1,8(sp)
    80002d1c:	1000                	addi	s0,sp,32
    80002d1e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d20:	00000097          	auipc	ra,0x0
    80002d24:	eee080e7          	jalr	-274(ra) # 80002c0e <argraw>
    80002d28:	c088                	sw	a0,0(s1)
}
    80002d2a:	60e2                	ld	ra,24(sp)
    80002d2c:	6442                	ld	s0,16(sp)
    80002d2e:	64a2                	ld	s1,8(sp)
    80002d30:	6105                	addi	sp,sp,32
    80002d32:	8082                	ret

0000000080002d34 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002d34:	1101                	addi	sp,sp,-32
    80002d36:	ec06                	sd	ra,24(sp)
    80002d38:	e822                	sd	s0,16(sp)
    80002d3a:	e426                	sd	s1,8(sp)
    80002d3c:	1000                	addi	s0,sp,32
    80002d3e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d40:	00000097          	auipc	ra,0x0
    80002d44:	ece080e7          	jalr	-306(ra) # 80002c0e <argraw>
    80002d48:	e088                	sd	a0,0(s1)
}
    80002d4a:	60e2                	ld	ra,24(sp)
    80002d4c:	6442                	ld	s0,16(sp)
    80002d4e:	64a2                	ld	s1,8(sp)
    80002d50:	6105                	addi	sp,sp,32
    80002d52:	8082                	ret

0000000080002d54 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d54:	7179                	addi	sp,sp,-48
    80002d56:	f406                	sd	ra,40(sp)
    80002d58:	f022                	sd	s0,32(sp)
    80002d5a:	ec26                	sd	s1,24(sp)
    80002d5c:	e84a                	sd	s2,16(sp)
    80002d5e:	1800                	addi	s0,sp,48
    80002d60:	84ae                	mv	s1,a1
    80002d62:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002d64:	fd840593          	addi	a1,s0,-40
    80002d68:	00000097          	auipc	ra,0x0
    80002d6c:	fcc080e7          	jalr	-52(ra) # 80002d34 <argaddr>
  return fetchstr(addr, buf, max);
    80002d70:	864a                	mv	a2,s2
    80002d72:	85a6                	mv	a1,s1
    80002d74:	fd843503          	ld	a0,-40(s0)
    80002d78:	00000097          	auipc	ra,0x0
    80002d7c:	f50080e7          	jalr	-176(ra) # 80002cc8 <fetchstr>
}
    80002d80:	70a2                	ld	ra,40(sp)
    80002d82:	7402                	ld	s0,32(sp)
    80002d84:	64e2                	ld	s1,24(sp)
    80002d86:	6942                	ld	s2,16(sp)
    80002d88:	6145                	addi	sp,sp,48
    80002d8a:	8082                	ret

0000000080002d8c <syscall>:
[SYS_setpriority] "setpriority",
};

void
syscall(void)
{
    80002d8c:	7179                	addi	sp,sp,-48
    80002d8e:	f406                	sd	ra,40(sp)
    80002d90:	f022                	sd	s0,32(sp)
    80002d92:	ec26                	sd	s1,24(sp)
    80002d94:	e84a                	sd	s2,16(sp)
    80002d96:	e44e                	sd	s3,8(sp)
    80002d98:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80002d9a:	fffff097          	auipc	ra,0xfffff
    80002d9e:	c12080e7          	jalr	-1006(ra) # 800019ac <myproc>
    80002da2:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002da4:	05853903          	ld	s2,88(a0)
    80002da8:	0a893783          	ld	a5,168(s2)
    80002dac:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002db0:	37fd                	addiw	a5,a5,-1
    80002db2:	4769                	li	a4,26
    80002db4:	04f76663          	bltu	a4,a5,80002e00 <syscall+0x74>
    80002db8:	00399713          	slli	a4,s3,0x3
    80002dbc:	00005797          	auipc	a5,0x5
    80002dc0:	78478793          	addi	a5,a5,1924 # 80008540 <syscalls>
    80002dc4:	97ba                	add	a5,a5,a4
    80002dc6:	639c                	ld	a5,0(a5)
    80002dc8:	cf85                	beqz	a5,80002e00 <syscall+0x74>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002dca:	9782                	jalr	a5
    80002dcc:	06a93823          	sd	a0,112(s2)

    // Check for trace_flag to be on
    if(p->trace_flag >> num) {  // check for '=='
    80002dd0:	1684a783          	lw	a5,360(s1)
    80002dd4:	4137d7bb          	sraw	a5,a5,s3
    80002dd8:	c3b9                	beqz	a5,80002e1e <syscall+0x92>
      printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0);
    80002dda:	6cb8                	ld	a4,88(s1)
    80002ddc:	098e                	slli	s3,s3,0x3
    80002dde:	00006797          	auipc	a5,0x6
    80002de2:	bda78793          	addi	a5,a5,-1062 # 800089b8 <syscall_names>
    80002de6:	97ce                	add	a5,a5,s3
    80002de8:	7b34                	ld	a3,112(a4)
    80002dea:	6390                	ld	a2,0(a5)
    80002dec:	588c                	lw	a1,48(s1)
    80002dee:	00005517          	auipc	a0,0x5
    80002df2:	62a50513          	addi	a0,a0,1578 # 80008418 <states.0+0x150>
    80002df6:	ffffd097          	auipc	ra,0xffffd
    80002dfa:	794080e7          	jalr	1940(ra) # 8000058a <printf>
    80002dfe:	a005                	j	80002e1e <syscall+0x92>
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e00:	86ce                	mv	a3,s3
    80002e02:	15848613          	addi	a2,s1,344
    80002e06:	588c                	lw	a1,48(s1)
    80002e08:	00005517          	auipc	a0,0x5
    80002e0c:	62850513          	addi	a0,a0,1576 # 80008430 <states.0+0x168>
    80002e10:	ffffd097          	auipc	ra,0xffffd
    80002e14:	77a080e7          	jalr	1914(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e18:	6cbc                	ld	a5,88(s1)
    80002e1a:	577d                	li	a4,-1
    80002e1c:	fbb8                	sd	a4,112(a5)
  }
}
    80002e1e:	70a2                	ld	ra,40(sp)
    80002e20:	7402                	ld	s0,32(sp)
    80002e22:	64e2                	ld	s1,24(sp)
    80002e24:	6942                	ld	s2,16(sp)
    80002e26:	69a2                	ld	s3,8(sp)
    80002e28:	6145                	addi	sp,sp,48
    80002e2a:	8082                	ret

0000000080002e2c <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e2c:	1101                	addi	sp,sp,-32
    80002e2e:	ec06                	sd	ra,24(sp)
    80002e30:	e822                	sd	s0,16(sp)
    80002e32:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002e34:	fec40593          	addi	a1,s0,-20
    80002e38:	4501                	li	a0,0
    80002e3a:	00000097          	auipc	ra,0x0
    80002e3e:	eda080e7          	jalr	-294(ra) # 80002d14 <argint>
  exit(n);
    80002e42:	fec42503          	lw	a0,-20(s0)
    80002e46:	fffff097          	auipc	ra,0xfffff
    80002e4a:	492080e7          	jalr	1170(ra) # 800022d8 <exit>
  return 0;  // not reached
}
    80002e4e:	4501                	li	a0,0
    80002e50:	60e2                	ld	ra,24(sp)
    80002e52:	6442                	ld	s0,16(sp)
    80002e54:	6105                	addi	sp,sp,32
    80002e56:	8082                	ret

0000000080002e58 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e58:	1141                	addi	sp,sp,-16
    80002e5a:	e406                	sd	ra,8(sp)
    80002e5c:	e022                	sd	s0,0(sp)
    80002e5e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e60:	fffff097          	auipc	ra,0xfffff
    80002e64:	b4c080e7          	jalr	-1204(ra) # 800019ac <myproc>
}
    80002e68:	5908                	lw	a0,48(a0)
    80002e6a:	60a2                	ld	ra,8(sp)
    80002e6c:	6402                	ld	s0,0(sp)
    80002e6e:	0141                	addi	sp,sp,16
    80002e70:	8082                	ret

0000000080002e72 <sys_fork>:

uint64
sys_fork(void)
{
    80002e72:	1141                	addi	sp,sp,-16
    80002e74:	e406                	sd	ra,8(sp)
    80002e76:	e022                	sd	s0,0(sp)
    80002e78:	0800                	addi	s0,sp,16
  return fork();
    80002e7a:	fffff097          	auipc	ra,0xfffff
    80002e7e:	f18080e7          	jalr	-232(ra) # 80001d92 <fork>
}
    80002e82:	60a2                	ld	ra,8(sp)
    80002e84:	6402                	ld	s0,0(sp)
    80002e86:	0141                	addi	sp,sp,16
    80002e88:	8082                	ret

0000000080002e8a <sys_wait>:

uint64
sys_wait(void)
{
    80002e8a:	1101                	addi	sp,sp,-32
    80002e8c:	ec06                	sd	ra,24(sp)
    80002e8e:	e822                	sd	s0,16(sp)
    80002e90:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002e92:	fe840593          	addi	a1,s0,-24
    80002e96:	4501                	li	a0,0
    80002e98:	00000097          	auipc	ra,0x0
    80002e9c:	e9c080e7          	jalr	-356(ra) # 80002d34 <argaddr>
  return wait(p);
    80002ea0:	fe843503          	ld	a0,-24(s0)
    80002ea4:	fffff097          	auipc	ra,0xfffff
    80002ea8:	5da080e7          	jalr	1498(ra) # 8000247e <wait>
}
    80002eac:	60e2                	ld	ra,24(sp)
    80002eae:	6442                	ld	s0,16(sp)
    80002eb0:	6105                	addi	sp,sp,32
    80002eb2:	8082                	ret

0000000080002eb4 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002eb4:	7179                	addi	sp,sp,-48
    80002eb6:	f406                	sd	ra,40(sp)
    80002eb8:	f022                	sd	s0,32(sp)
    80002eba:	ec26                	sd	s1,24(sp)
    80002ebc:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002ebe:	fdc40593          	addi	a1,s0,-36
    80002ec2:	4501                	li	a0,0
    80002ec4:	00000097          	auipc	ra,0x0
    80002ec8:	e50080e7          	jalr	-432(ra) # 80002d14 <argint>
  addr = myproc()->sz;
    80002ecc:	fffff097          	auipc	ra,0xfffff
    80002ed0:	ae0080e7          	jalr	-1312(ra) # 800019ac <myproc>
    80002ed4:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002ed6:	fdc42503          	lw	a0,-36(s0)
    80002eda:	fffff097          	auipc	ra,0xfffff
    80002ede:	e5c080e7          	jalr	-420(ra) # 80001d36 <growproc>
    80002ee2:	00054863          	bltz	a0,80002ef2 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002ee6:	8526                	mv	a0,s1
    80002ee8:	70a2                	ld	ra,40(sp)
    80002eea:	7402                	ld	s0,32(sp)
    80002eec:	64e2                	ld	s1,24(sp)
    80002eee:	6145                	addi	sp,sp,48
    80002ef0:	8082                	ret
    return -1;
    80002ef2:	54fd                	li	s1,-1
    80002ef4:	bfcd                	j	80002ee6 <sys_sbrk+0x32>

0000000080002ef6 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002ef6:	7139                	addi	sp,sp,-64
    80002ef8:	fc06                	sd	ra,56(sp)
    80002efa:	f822                	sd	s0,48(sp)
    80002efc:	f426                	sd	s1,40(sp)
    80002efe:	f04a                	sd	s2,32(sp)
    80002f00:	ec4e                	sd	s3,24(sp)
    80002f02:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002f04:	fcc40593          	addi	a1,s0,-52
    80002f08:	4501                	li	a0,0
    80002f0a:	00000097          	auipc	ra,0x0
    80002f0e:	e0a080e7          	jalr	-502(ra) # 80002d14 <argint>
  acquire(&tickslock);
    80002f12:	00015517          	auipc	a0,0x15
    80002f16:	e7e50513          	addi	a0,a0,-386 # 80017d90 <tickslock>
    80002f1a:	ffffe097          	auipc	ra,0xffffe
    80002f1e:	cbc080e7          	jalr	-836(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002f22:	00006917          	auipc	s2,0x6
    80002f26:	bce92903          	lw	s2,-1074(s2) # 80008af0 <ticks>
  while(ticks - ticks0 < n){
    80002f2a:	fcc42783          	lw	a5,-52(s0)
    80002f2e:	cf9d                	beqz	a5,80002f6c <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f30:	00015997          	auipc	s3,0x15
    80002f34:	e6098993          	addi	s3,s3,-416 # 80017d90 <tickslock>
    80002f38:	00006497          	auipc	s1,0x6
    80002f3c:	bb848493          	addi	s1,s1,-1096 # 80008af0 <ticks>
    if(killed(myproc())){
    80002f40:	fffff097          	auipc	ra,0xfffff
    80002f44:	a6c080e7          	jalr	-1428(ra) # 800019ac <myproc>
    80002f48:	fffff097          	auipc	ra,0xfffff
    80002f4c:	504080e7          	jalr	1284(ra) # 8000244c <killed>
    80002f50:	ed15                	bnez	a0,80002f8c <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002f52:	85ce                	mv	a1,s3
    80002f54:	8526                	mv	a0,s1
    80002f56:	fffff097          	auipc	ra,0xfffff
    80002f5a:	24e080e7          	jalr	590(ra) # 800021a4 <sleep>
  while(ticks - ticks0 < n){
    80002f5e:	409c                	lw	a5,0(s1)
    80002f60:	412787bb          	subw	a5,a5,s2
    80002f64:	fcc42703          	lw	a4,-52(s0)
    80002f68:	fce7ece3          	bltu	a5,a4,80002f40 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002f6c:	00015517          	auipc	a0,0x15
    80002f70:	e2450513          	addi	a0,a0,-476 # 80017d90 <tickslock>
    80002f74:	ffffe097          	auipc	ra,0xffffe
    80002f78:	d16080e7          	jalr	-746(ra) # 80000c8a <release>
  return 0;
    80002f7c:	4501                	li	a0,0
}
    80002f7e:	70e2                	ld	ra,56(sp)
    80002f80:	7442                	ld	s0,48(sp)
    80002f82:	74a2                	ld	s1,40(sp)
    80002f84:	7902                	ld	s2,32(sp)
    80002f86:	69e2                	ld	s3,24(sp)
    80002f88:	6121                	addi	sp,sp,64
    80002f8a:	8082                	ret
      release(&tickslock);
    80002f8c:	00015517          	auipc	a0,0x15
    80002f90:	e0450513          	addi	a0,a0,-508 # 80017d90 <tickslock>
    80002f94:	ffffe097          	auipc	ra,0xffffe
    80002f98:	cf6080e7          	jalr	-778(ra) # 80000c8a <release>
      return -1;
    80002f9c:	557d                	li	a0,-1
    80002f9e:	b7c5                	j	80002f7e <sys_sleep+0x88>

0000000080002fa0 <sys_kill>:

uint64
sys_kill(void)
{
    80002fa0:	1101                	addi	sp,sp,-32
    80002fa2:	ec06                	sd	ra,24(sp)
    80002fa4:	e822                	sd	s0,16(sp)
    80002fa6:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002fa8:	fec40593          	addi	a1,s0,-20
    80002fac:	4501                	li	a0,0
    80002fae:	00000097          	auipc	ra,0x0
    80002fb2:	d66080e7          	jalr	-666(ra) # 80002d14 <argint>
  return kill(pid);
    80002fb6:	fec42503          	lw	a0,-20(s0)
    80002fba:	fffff097          	auipc	ra,0xfffff
    80002fbe:	3f4080e7          	jalr	1012(ra) # 800023ae <kill>
}
    80002fc2:	60e2                	ld	ra,24(sp)
    80002fc4:	6442                	ld	s0,16(sp)
    80002fc6:	6105                	addi	sp,sp,32
    80002fc8:	8082                	ret

0000000080002fca <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002fca:	1101                	addi	sp,sp,-32
    80002fcc:	ec06                	sd	ra,24(sp)
    80002fce:	e822                	sd	s0,16(sp)
    80002fd0:	e426                	sd	s1,8(sp)
    80002fd2:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002fd4:	00015517          	auipc	a0,0x15
    80002fd8:	dbc50513          	addi	a0,a0,-580 # 80017d90 <tickslock>
    80002fdc:	ffffe097          	auipc	ra,0xffffe
    80002fe0:	bfa080e7          	jalr	-1030(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002fe4:	00006497          	auipc	s1,0x6
    80002fe8:	b0c4a483          	lw	s1,-1268(s1) # 80008af0 <ticks>
  release(&tickslock);
    80002fec:	00015517          	auipc	a0,0x15
    80002ff0:	da450513          	addi	a0,a0,-604 # 80017d90 <tickslock>
    80002ff4:	ffffe097          	auipc	ra,0xffffe
    80002ff8:	c96080e7          	jalr	-874(ra) # 80000c8a <release>
  return xticks;
}
    80002ffc:	02049513          	slli	a0,s1,0x20
    80003000:	9101                	srli	a0,a0,0x20
    80003002:	60e2                	ld	ra,24(sp)
    80003004:	6442                	ld	s0,16(sp)
    80003006:	64a2                	ld	s1,8(sp)
    80003008:	6105                	addi	sp,sp,32
    8000300a:	8082                	ret

000000008000300c <sys_trace>:

// sets the trace_flag to the first argument (a0)
uint64
sys_trace(void)
{
    8000300c:	1141                	addi	sp,sp,-16
    8000300e:	e406                	sd	ra,8(sp)
    80003010:	e022                	sd	s0,0(sp)
    80003012:	0800                	addi	s0,sp,16
  argint(0, &myproc()->trace_flag); //arg(a0, trace_flag) // returns void
    80003014:	fffff097          	auipc	ra,0xfffff
    80003018:	998080e7          	jalr	-1640(ra) # 800019ac <myproc>
    8000301c:	16850593          	addi	a1,a0,360
    80003020:	4501                	li	a0,0
    80003022:	00000097          	auipc	ra,0x0
    80003026:	cf2080e7          	jalr	-782(ra) # 80002d14 <argint>
  return 0;
}
    8000302a:	4501                	li	a0,0
    8000302c:	60a2                	ld	ra,8(sp)
    8000302e:	6402                	ld	s0,0(sp)
    80003030:	0141                	addi	sp,sp,16
    80003032:	8082                	ret

0000000080003034 <sys_sigalarm>:

// sets the 
uint64
sys_sigalarm(void)
{
    80003034:	1101                	addi	sp,sp,-32
    80003036:	ec06                	sd	ra,24(sp)
    80003038:	e822                	sd	s0,16(sp)
    8000303a:	e426                	sd	s1,8(sp)
    8000303c:	1000                	addi	s0,sp,32
  // sets the interval and handler after every tick
  argint(0, &myproc()->interval);
    8000303e:	fffff097          	auipc	ra,0xfffff
    80003042:	96e080e7          	jalr	-1682(ra) # 800019ac <myproc>
    80003046:	16c50593          	addi	a1,a0,364
    8000304a:	4501                	li	a0,0
    8000304c:	00000097          	auipc	ra,0x0
    80003050:	cc8080e7          	jalr	-824(ra) # 80002d14 <argint>
  argaddr(1, &myproc()->sig_handler);
    80003054:	fffff097          	auipc	ra,0xfffff
    80003058:	958080e7          	jalr	-1704(ra) # 800019ac <myproc>
    8000305c:	17850593          	addi	a1,a0,376
    80003060:	4505                	li	a0,1
    80003062:	00000097          	auipc	ra,0x0
    80003066:	cd2080e7          	jalr	-814(ra) # 80002d34 <argaddr>
  
  // sets ticks_passed as the interval
  myproc()->ticks_left = myproc()->interval;
    8000306a:	fffff097          	auipc	ra,0xfffff
    8000306e:	942080e7          	jalr	-1726(ra) # 800019ac <myproc>
    80003072:	84aa                	mv	s1,a0
    80003074:	fffff097          	auipc	ra,0xfffff
    80003078:	938080e7          	jalr	-1736(ra) # 800019ac <myproc>
    8000307c:	16c4a783          	lw	a5,364(s1)
    80003080:	16f52823          	sw	a5,368(a0)
  return 0;
}
    80003084:	4501                	li	a0,0
    80003086:	60e2                	ld	ra,24(sp)
    80003088:	6442                	ld	s0,16(sp)
    8000308a:	64a2                	ld	s1,8(sp)
    8000308c:	6105                	addi	sp,sp,32
    8000308e:	8082                	ret

0000000080003090 <sys_sigreturn>:

uint64 
sys_sigreturn(void)
{
    80003090:	1101                	addi	sp,sp,-32
    80003092:	ec06                	sd	ra,24(sp)
    80003094:	e822                	sd	s0,16(sp)
    80003096:	e426                	sd	s1,8(sp)
    80003098:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000309a:	fffff097          	auipc	ra,0xfffff
    8000309e:	912080e7          	jalr	-1774(ra) # 800019ac <myproc>
    800030a2:	84aa                	mv	s1,a0
  memmove(p->trapframe, p->sigalarm_tf, PGSIZE);
    800030a4:	6605                	lui	a2,0x1
    800030a6:	18053583          	ld	a1,384(a0)
    800030aa:	6d28                	ld	a0,88(a0)
    800030ac:	ffffe097          	auipc	ra,0xffffe
    800030b0:	c82080e7          	jalr	-894(ra) # 80000d2e <memmove>
  kfree(p->sigalarm_tf);
    800030b4:	1804b503          	ld	a0,384(s1)
    800030b8:	ffffe097          	auipc	ra,0xffffe
    800030bc:	930080e7          	jalr	-1744(ra) # 800009e8 <kfree>
  p->ticks_left = p->interval;
    800030c0:	16c4a783          	lw	a5,364(s1)
    800030c4:	16f4a823          	sw	a5,368(s1)
  return p->trapframe->a0;
    800030c8:	6cbc                	ld	a5,88(s1)
}
    800030ca:	7ba8                	ld	a0,112(a5)
    800030cc:	60e2                	ld	ra,24(sp)
    800030ce:	6442                	ld	s0,16(sp)
    800030d0:	64a2                	ld	s1,8(sp)
    800030d2:	6105                	addi	sp,sp,32
    800030d4:	8082                	ret

00000000800030d6 <sys_settickets>:

uint64 
sys_settickets(void)
{
    800030d6:	1141                	addi	sp,sp,-16
    800030d8:	e406                	sd	ra,8(sp)
    800030da:	e022                	sd	s0,0(sp)
    800030dc:	0800                	addi	s0,sp,16
  argint(0, &myproc()->tickets);
    800030de:	fffff097          	auipc	ra,0xfffff
    800030e2:	8ce080e7          	jalr	-1842(ra) # 800019ac <myproc>
    800030e6:	18c50593          	addi	a1,a0,396
    800030ea:	4501                	li	a0,0
    800030ec:	00000097          	auipc	ra,0x0
    800030f0:	c28080e7          	jalr	-984(ra) # 80002d14 <argint>
  return myproc()->tickets;
    800030f4:	fffff097          	auipc	ra,0xfffff
    800030f8:	8b8080e7          	jalr	-1864(ra) # 800019ac <myproc>
}
    800030fc:	18c52503          	lw	a0,396(a0)
    80003100:	60a2                	ld	ra,8(sp)
    80003102:	6402                	ld	s0,0(sp)
    80003104:	0141                	addi	sp,sp,16
    80003106:	8082                	ret

0000000080003108 <sys_setpriority>:

uint64
sys_setpriority(void)
{
    80003108:	1101                	addi	sp,sp,-32
    8000310a:	ec06                	sd	ra,24(sp)
    8000310c:	e822                	sd	s0,16(sp)
    8000310e:	1000                	addi	s0,sp,32
  int new_priority, proc_pid;

  argint(0, &new_priority);
    80003110:	fec40593          	addi	a1,s0,-20
    80003114:	4501                	li	a0,0
    80003116:	00000097          	auipc	ra,0x0
    8000311a:	bfe080e7          	jalr	-1026(ra) # 80002d14 <argint>
  // {
  //   printf("This is invalid priority\n");
  //   return -1;
  // }
  
  argint(1, &proc_pid);
    8000311e:	fe840593          	addi	a1,s0,-24
    80003122:	4505                	li	a0,1
    80003124:	00000097          	auipc	ra,0x0
    80003128:	bf0080e7          	jalr	-1040(ra) # 80002d14 <argint>
  // {
  //   printf("This is invalid PID\n");
  //   return -1;
  // }

  return setpriority(new_priority, proc_pid);
    8000312c:	fe842583          	lw	a1,-24(s0)
    80003130:	fec42503          	lw	a0,-20(s0)
    80003134:	fffff097          	auipc	ra,0xfffff
    80003138:	650080e7          	jalr	1616(ra) # 80002784 <setpriority>
    8000313c:	60e2                	ld	ra,24(sp)
    8000313e:	6442                	ld	s0,16(sp)
    80003140:	6105                	addi	sp,sp,32
    80003142:	8082                	ret

0000000080003144 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003144:	7179                	addi	sp,sp,-48
    80003146:	f406                	sd	ra,40(sp)
    80003148:	f022                	sd	s0,32(sp)
    8000314a:	ec26                	sd	s1,24(sp)
    8000314c:	e84a                	sd	s2,16(sp)
    8000314e:	e44e                	sd	s3,8(sp)
    80003150:	e052                	sd	s4,0(sp)
    80003152:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003154:	00005597          	auipc	a1,0x5
    80003158:	4cc58593          	addi	a1,a1,1228 # 80008620 <syscalls+0xe0>
    8000315c:	00015517          	auipc	a0,0x15
    80003160:	c4c50513          	addi	a0,a0,-948 # 80017da8 <bcache>
    80003164:	ffffe097          	auipc	ra,0xffffe
    80003168:	9e2080e7          	jalr	-1566(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000316c:	0001d797          	auipc	a5,0x1d
    80003170:	c3c78793          	addi	a5,a5,-964 # 8001fda8 <bcache+0x8000>
    80003174:	0001d717          	auipc	a4,0x1d
    80003178:	e9c70713          	addi	a4,a4,-356 # 80020010 <bcache+0x8268>
    8000317c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003180:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003184:	00015497          	auipc	s1,0x15
    80003188:	c3c48493          	addi	s1,s1,-964 # 80017dc0 <bcache+0x18>
    b->next = bcache.head.next;
    8000318c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000318e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003190:	00005a17          	auipc	s4,0x5
    80003194:	498a0a13          	addi	s4,s4,1176 # 80008628 <syscalls+0xe8>
    b->next = bcache.head.next;
    80003198:	2b893783          	ld	a5,696(s2)
    8000319c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000319e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800031a2:	85d2                	mv	a1,s4
    800031a4:	01048513          	addi	a0,s1,16
    800031a8:	00001097          	auipc	ra,0x1
    800031ac:	4c8080e7          	jalr	1224(ra) # 80004670 <initsleeplock>
    bcache.head.next->prev = b;
    800031b0:	2b893783          	ld	a5,696(s2)
    800031b4:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800031b6:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031ba:	45848493          	addi	s1,s1,1112
    800031be:	fd349de3          	bne	s1,s3,80003198 <binit+0x54>
  }
}
    800031c2:	70a2                	ld	ra,40(sp)
    800031c4:	7402                	ld	s0,32(sp)
    800031c6:	64e2                	ld	s1,24(sp)
    800031c8:	6942                	ld	s2,16(sp)
    800031ca:	69a2                	ld	s3,8(sp)
    800031cc:	6a02                	ld	s4,0(sp)
    800031ce:	6145                	addi	sp,sp,48
    800031d0:	8082                	ret

00000000800031d2 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800031d2:	7179                	addi	sp,sp,-48
    800031d4:	f406                	sd	ra,40(sp)
    800031d6:	f022                	sd	s0,32(sp)
    800031d8:	ec26                	sd	s1,24(sp)
    800031da:	e84a                	sd	s2,16(sp)
    800031dc:	e44e                	sd	s3,8(sp)
    800031de:	1800                	addi	s0,sp,48
    800031e0:	892a                	mv	s2,a0
    800031e2:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800031e4:	00015517          	auipc	a0,0x15
    800031e8:	bc450513          	addi	a0,a0,-1084 # 80017da8 <bcache>
    800031ec:	ffffe097          	auipc	ra,0xffffe
    800031f0:	9ea080e7          	jalr	-1558(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800031f4:	0001d497          	auipc	s1,0x1d
    800031f8:	e6c4b483          	ld	s1,-404(s1) # 80020060 <bcache+0x82b8>
    800031fc:	0001d797          	auipc	a5,0x1d
    80003200:	e1478793          	addi	a5,a5,-492 # 80020010 <bcache+0x8268>
    80003204:	02f48f63          	beq	s1,a5,80003242 <bread+0x70>
    80003208:	873e                	mv	a4,a5
    8000320a:	a021                	j	80003212 <bread+0x40>
    8000320c:	68a4                	ld	s1,80(s1)
    8000320e:	02e48a63          	beq	s1,a4,80003242 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003212:	449c                	lw	a5,8(s1)
    80003214:	ff279ce3          	bne	a5,s2,8000320c <bread+0x3a>
    80003218:	44dc                	lw	a5,12(s1)
    8000321a:	ff3799e3          	bne	a5,s3,8000320c <bread+0x3a>
      b->refcnt++;
    8000321e:	40bc                	lw	a5,64(s1)
    80003220:	2785                	addiw	a5,a5,1
    80003222:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003224:	00015517          	auipc	a0,0x15
    80003228:	b8450513          	addi	a0,a0,-1148 # 80017da8 <bcache>
    8000322c:	ffffe097          	auipc	ra,0xffffe
    80003230:	a5e080e7          	jalr	-1442(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003234:	01048513          	addi	a0,s1,16
    80003238:	00001097          	auipc	ra,0x1
    8000323c:	472080e7          	jalr	1138(ra) # 800046aa <acquiresleep>
      return b;
    80003240:	a8b9                	j	8000329e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003242:	0001d497          	auipc	s1,0x1d
    80003246:	e164b483          	ld	s1,-490(s1) # 80020058 <bcache+0x82b0>
    8000324a:	0001d797          	auipc	a5,0x1d
    8000324e:	dc678793          	addi	a5,a5,-570 # 80020010 <bcache+0x8268>
    80003252:	00f48863          	beq	s1,a5,80003262 <bread+0x90>
    80003256:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003258:	40bc                	lw	a5,64(s1)
    8000325a:	cf81                	beqz	a5,80003272 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000325c:	64a4                	ld	s1,72(s1)
    8000325e:	fee49de3          	bne	s1,a4,80003258 <bread+0x86>
  panic("bget: no buffers");
    80003262:	00005517          	auipc	a0,0x5
    80003266:	3ce50513          	addi	a0,a0,974 # 80008630 <syscalls+0xf0>
    8000326a:	ffffd097          	auipc	ra,0xffffd
    8000326e:	2d6080e7          	jalr	726(ra) # 80000540 <panic>
      b->dev = dev;
    80003272:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003276:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000327a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000327e:	4785                	li	a5,1
    80003280:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003282:	00015517          	auipc	a0,0x15
    80003286:	b2650513          	addi	a0,a0,-1242 # 80017da8 <bcache>
    8000328a:	ffffe097          	auipc	ra,0xffffe
    8000328e:	a00080e7          	jalr	-1536(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003292:	01048513          	addi	a0,s1,16
    80003296:	00001097          	auipc	ra,0x1
    8000329a:	414080e7          	jalr	1044(ra) # 800046aa <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000329e:	409c                	lw	a5,0(s1)
    800032a0:	cb89                	beqz	a5,800032b2 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800032a2:	8526                	mv	a0,s1
    800032a4:	70a2                	ld	ra,40(sp)
    800032a6:	7402                	ld	s0,32(sp)
    800032a8:	64e2                	ld	s1,24(sp)
    800032aa:	6942                	ld	s2,16(sp)
    800032ac:	69a2                	ld	s3,8(sp)
    800032ae:	6145                	addi	sp,sp,48
    800032b0:	8082                	ret
    virtio_disk_rw(b, 0);
    800032b2:	4581                	li	a1,0
    800032b4:	8526                	mv	a0,s1
    800032b6:	00003097          	auipc	ra,0x3
    800032ba:	fdc080e7          	jalr	-36(ra) # 80006292 <virtio_disk_rw>
    b->valid = 1;
    800032be:	4785                	li	a5,1
    800032c0:	c09c                	sw	a5,0(s1)
  return b;
    800032c2:	b7c5                	j	800032a2 <bread+0xd0>

00000000800032c4 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800032c4:	1101                	addi	sp,sp,-32
    800032c6:	ec06                	sd	ra,24(sp)
    800032c8:	e822                	sd	s0,16(sp)
    800032ca:	e426                	sd	s1,8(sp)
    800032cc:	1000                	addi	s0,sp,32
    800032ce:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032d0:	0541                	addi	a0,a0,16
    800032d2:	00001097          	auipc	ra,0x1
    800032d6:	472080e7          	jalr	1138(ra) # 80004744 <holdingsleep>
    800032da:	cd01                	beqz	a0,800032f2 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800032dc:	4585                	li	a1,1
    800032de:	8526                	mv	a0,s1
    800032e0:	00003097          	auipc	ra,0x3
    800032e4:	fb2080e7          	jalr	-78(ra) # 80006292 <virtio_disk_rw>
}
    800032e8:	60e2                	ld	ra,24(sp)
    800032ea:	6442                	ld	s0,16(sp)
    800032ec:	64a2                	ld	s1,8(sp)
    800032ee:	6105                	addi	sp,sp,32
    800032f0:	8082                	ret
    panic("bwrite");
    800032f2:	00005517          	auipc	a0,0x5
    800032f6:	35650513          	addi	a0,a0,854 # 80008648 <syscalls+0x108>
    800032fa:	ffffd097          	auipc	ra,0xffffd
    800032fe:	246080e7          	jalr	582(ra) # 80000540 <panic>

0000000080003302 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003302:	1101                	addi	sp,sp,-32
    80003304:	ec06                	sd	ra,24(sp)
    80003306:	e822                	sd	s0,16(sp)
    80003308:	e426                	sd	s1,8(sp)
    8000330a:	e04a                	sd	s2,0(sp)
    8000330c:	1000                	addi	s0,sp,32
    8000330e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003310:	01050913          	addi	s2,a0,16
    80003314:	854a                	mv	a0,s2
    80003316:	00001097          	auipc	ra,0x1
    8000331a:	42e080e7          	jalr	1070(ra) # 80004744 <holdingsleep>
    8000331e:	c92d                	beqz	a0,80003390 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003320:	854a                	mv	a0,s2
    80003322:	00001097          	auipc	ra,0x1
    80003326:	3de080e7          	jalr	990(ra) # 80004700 <releasesleep>

  acquire(&bcache.lock);
    8000332a:	00015517          	auipc	a0,0x15
    8000332e:	a7e50513          	addi	a0,a0,-1410 # 80017da8 <bcache>
    80003332:	ffffe097          	auipc	ra,0xffffe
    80003336:	8a4080e7          	jalr	-1884(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000333a:	40bc                	lw	a5,64(s1)
    8000333c:	37fd                	addiw	a5,a5,-1
    8000333e:	0007871b          	sext.w	a4,a5
    80003342:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003344:	eb05                	bnez	a4,80003374 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003346:	68bc                	ld	a5,80(s1)
    80003348:	64b8                	ld	a4,72(s1)
    8000334a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000334c:	64bc                	ld	a5,72(s1)
    8000334e:	68b8                	ld	a4,80(s1)
    80003350:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003352:	0001d797          	auipc	a5,0x1d
    80003356:	a5678793          	addi	a5,a5,-1450 # 8001fda8 <bcache+0x8000>
    8000335a:	2b87b703          	ld	a4,696(a5)
    8000335e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003360:	0001d717          	auipc	a4,0x1d
    80003364:	cb070713          	addi	a4,a4,-848 # 80020010 <bcache+0x8268>
    80003368:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000336a:	2b87b703          	ld	a4,696(a5)
    8000336e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003370:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003374:	00015517          	auipc	a0,0x15
    80003378:	a3450513          	addi	a0,a0,-1484 # 80017da8 <bcache>
    8000337c:	ffffe097          	auipc	ra,0xffffe
    80003380:	90e080e7          	jalr	-1778(ra) # 80000c8a <release>
}
    80003384:	60e2                	ld	ra,24(sp)
    80003386:	6442                	ld	s0,16(sp)
    80003388:	64a2                	ld	s1,8(sp)
    8000338a:	6902                	ld	s2,0(sp)
    8000338c:	6105                	addi	sp,sp,32
    8000338e:	8082                	ret
    panic("brelse");
    80003390:	00005517          	auipc	a0,0x5
    80003394:	2c050513          	addi	a0,a0,704 # 80008650 <syscalls+0x110>
    80003398:	ffffd097          	auipc	ra,0xffffd
    8000339c:	1a8080e7          	jalr	424(ra) # 80000540 <panic>

00000000800033a0 <bpin>:

void
bpin(struct buf *b) {
    800033a0:	1101                	addi	sp,sp,-32
    800033a2:	ec06                	sd	ra,24(sp)
    800033a4:	e822                	sd	s0,16(sp)
    800033a6:	e426                	sd	s1,8(sp)
    800033a8:	1000                	addi	s0,sp,32
    800033aa:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033ac:	00015517          	auipc	a0,0x15
    800033b0:	9fc50513          	addi	a0,a0,-1540 # 80017da8 <bcache>
    800033b4:	ffffe097          	auipc	ra,0xffffe
    800033b8:	822080e7          	jalr	-2014(ra) # 80000bd6 <acquire>
  b->refcnt++;
    800033bc:	40bc                	lw	a5,64(s1)
    800033be:	2785                	addiw	a5,a5,1
    800033c0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033c2:	00015517          	auipc	a0,0x15
    800033c6:	9e650513          	addi	a0,a0,-1562 # 80017da8 <bcache>
    800033ca:	ffffe097          	auipc	ra,0xffffe
    800033ce:	8c0080e7          	jalr	-1856(ra) # 80000c8a <release>
}
    800033d2:	60e2                	ld	ra,24(sp)
    800033d4:	6442                	ld	s0,16(sp)
    800033d6:	64a2                	ld	s1,8(sp)
    800033d8:	6105                	addi	sp,sp,32
    800033da:	8082                	ret

00000000800033dc <bunpin>:

void
bunpin(struct buf *b) {
    800033dc:	1101                	addi	sp,sp,-32
    800033de:	ec06                	sd	ra,24(sp)
    800033e0:	e822                	sd	s0,16(sp)
    800033e2:	e426                	sd	s1,8(sp)
    800033e4:	1000                	addi	s0,sp,32
    800033e6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033e8:	00015517          	auipc	a0,0x15
    800033ec:	9c050513          	addi	a0,a0,-1600 # 80017da8 <bcache>
    800033f0:	ffffd097          	auipc	ra,0xffffd
    800033f4:	7e6080e7          	jalr	2022(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800033f8:	40bc                	lw	a5,64(s1)
    800033fa:	37fd                	addiw	a5,a5,-1
    800033fc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033fe:	00015517          	auipc	a0,0x15
    80003402:	9aa50513          	addi	a0,a0,-1622 # 80017da8 <bcache>
    80003406:	ffffe097          	auipc	ra,0xffffe
    8000340a:	884080e7          	jalr	-1916(ra) # 80000c8a <release>
}
    8000340e:	60e2                	ld	ra,24(sp)
    80003410:	6442                	ld	s0,16(sp)
    80003412:	64a2                	ld	s1,8(sp)
    80003414:	6105                	addi	sp,sp,32
    80003416:	8082                	ret

0000000080003418 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003418:	1101                	addi	sp,sp,-32
    8000341a:	ec06                	sd	ra,24(sp)
    8000341c:	e822                	sd	s0,16(sp)
    8000341e:	e426                	sd	s1,8(sp)
    80003420:	e04a                	sd	s2,0(sp)
    80003422:	1000                	addi	s0,sp,32
    80003424:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003426:	00d5d59b          	srliw	a1,a1,0xd
    8000342a:	0001d797          	auipc	a5,0x1d
    8000342e:	05a7a783          	lw	a5,90(a5) # 80020484 <sb+0x1c>
    80003432:	9dbd                	addw	a1,a1,a5
    80003434:	00000097          	auipc	ra,0x0
    80003438:	d9e080e7          	jalr	-610(ra) # 800031d2 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000343c:	0074f713          	andi	a4,s1,7
    80003440:	4785                	li	a5,1
    80003442:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003446:	14ce                	slli	s1,s1,0x33
    80003448:	90d9                	srli	s1,s1,0x36
    8000344a:	00950733          	add	a4,a0,s1
    8000344e:	05874703          	lbu	a4,88(a4)
    80003452:	00e7f6b3          	and	a3,a5,a4
    80003456:	c69d                	beqz	a3,80003484 <bfree+0x6c>
    80003458:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000345a:	94aa                	add	s1,s1,a0
    8000345c:	fff7c793          	not	a5,a5
    80003460:	8f7d                	and	a4,a4,a5
    80003462:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003466:	00001097          	auipc	ra,0x1
    8000346a:	126080e7          	jalr	294(ra) # 8000458c <log_write>
  brelse(bp);
    8000346e:	854a                	mv	a0,s2
    80003470:	00000097          	auipc	ra,0x0
    80003474:	e92080e7          	jalr	-366(ra) # 80003302 <brelse>
}
    80003478:	60e2                	ld	ra,24(sp)
    8000347a:	6442                	ld	s0,16(sp)
    8000347c:	64a2                	ld	s1,8(sp)
    8000347e:	6902                	ld	s2,0(sp)
    80003480:	6105                	addi	sp,sp,32
    80003482:	8082                	ret
    panic("freeing free block");
    80003484:	00005517          	auipc	a0,0x5
    80003488:	1d450513          	addi	a0,a0,468 # 80008658 <syscalls+0x118>
    8000348c:	ffffd097          	auipc	ra,0xffffd
    80003490:	0b4080e7          	jalr	180(ra) # 80000540 <panic>

0000000080003494 <balloc>:
{
    80003494:	711d                	addi	sp,sp,-96
    80003496:	ec86                	sd	ra,88(sp)
    80003498:	e8a2                	sd	s0,80(sp)
    8000349a:	e4a6                	sd	s1,72(sp)
    8000349c:	e0ca                	sd	s2,64(sp)
    8000349e:	fc4e                	sd	s3,56(sp)
    800034a0:	f852                	sd	s4,48(sp)
    800034a2:	f456                	sd	s5,40(sp)
    800034a4:	f05a                	sd	s6,32(sp)
    800034a6:	ec5e                	sd	s7,24(sp)
    800034a8:	e862                	sd	s8,16(sp)
    800034aa:	e466                	sd	s9,8(sp)
    800034ac:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800034ae:	0001d797          	auipc	a5,0x1d
    800034b2:	fbe7a783          	lw	a5,-66(a5) # 8002046c <sb+0x4>
    800034b6:	cff5                	beqz	a5,800035b2 <balloc+0x11e>
    800034b8:	8baa                	mv	s7,a0
    800034ba:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800034bc:	0001db17          	auipc	s6,0x1d
    800034c0:	facb0b13          	addi	s6,s6,-84 # 80020468 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034c4:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800034c6:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034c8:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800034ca:	6c89                	lui	s9,0x2
    800034cc:	a061                	j	80003554 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800034ce:	97ca                	add	a5,a5,s2
    800034d0:	8e55                	or	a2,a2,a3
    800034d2:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800034d6:	854a                	mv	a0,s2
    800034d8:	00001097          	auipc	ra,0x1
    800034dc:	0b4080e7          	jalr	180(ra) # 8000458c <log_write>
        brelse(bp);
    800034e0:	854a                	mv	a0,s2
    800034e2:	00000097          	auipc	ra,0x0
    800034e6:	e20080e7          	jalr	-480(ra) # 80003302 <brelse>
  bp = bread(dev, bno);
    800034ea:	85a6                	mv	a1,s1
    800034ec:	855e                	mv	a0,s7
    800034ee:	00000097          	auipc	ra,0x0
    800034f2:	ce4080e7          	jalr	-796(ra) # 800031d2 <bread>
    800034f6:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800034f8:	40000613          	li	a2,1024
    800034fc:	4581                	li	a1,0
    800034fe:	05850513          	addi	a0,a0,88
    80003502:	ffffd097          	auipc	ra,0xffffd
    80003506:	7d0080e7          	jalr	2000(ra) # 80000cd2 <memset>
  log_write(bp);
    8000350a:	854a                	mv	a0,s2
    8000350c:	00001097          	auipc	ra,0x1
    80003510:	080080e7          	jalr	128(ra) # 8000458c <log_write>
  brelse(bp);
    80003514:	854a                	mv	a0,s2
    80003516:	00000097          	auipc	ra,0x0
    8000351a:	dec080e7          	jalr	-532(ra) # 80003302 <brelse>
}
    8000351e:	8526                	mv	a0,s1
    80003520:	60e6                	ld	ra,88(sp)
    80003522:	6446                	ld	s0,80(sp)
    80003524:	64a6                	ld	s1,72(sp)
    80003526:	6906                	ld	s2,64(sp)
    80003528:	79e2                	ld	s3,56(sp)
    8000352a:	7a42                	ld	s4,48(sp)
    8000352c:	7aa2                	ld	s5,40(sp)
    8000352e:	7b02                	ld	s6,32(sp)
    80003530:	6be2                	ld	s7,24(sp)
    80003532:	6c42                	ld	s8,16(sp)
    80003534:	6ca2                	ld	s9,8(sp)
    80003536:	6125                	addi	sp,sp,96
    80003538:	8082                	ret
    brelse(bp);
    8000353a:	854a                	mv	a0,s2
    8000353c:	00000097          	auipc	ra,0x0
    80003540:	dc6080e7          	jalr	-570(ra) # 80003302 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003544:	015c87bb          	addw	a5,s9,s5
    80003548:	00078a9b          	sext.w	s5,a5
    8000354c:	004b2703          	lw	a4,4(s6)
    80003550:	06eaf163          	bgeu	s5,a4,800035b2 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003554:	41fad79b          	sraiw	a5,s5,0x1f
    80003558:	0137d79b          	srliw	a5,a5,0x13
    8000355c:	015787bb          	addw	a5,a5,s5
    80003560:	40d7d79b          	sraiw	a5,a5,0xd
    80003564:	01cb2583          	lw	a1,28(s6)
    80003568:	9dbd                	addw	a1,a1,a5
    8000356a:	855e                	mv	a0,s7
    8000356c:	00000097          	auipc	ra,0x0
    80003570:	c66080e7          	jalr	-922(ra) # 800031d2 <bread>
    80003574:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003576:	004b2503          	lw	a0,4(s6)
    8000357a:	000a849b          	sext.w	s1,s5
    8000357e:	8762                	mv	a4,s8
    80003580:	faa4fde3          	bgeu	s1,a0,8000353a <balloc+0xa6>
      m = 1 << (bi % 8);
    80003584:	00777693          	andi	a3,a4,7
    80003588:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000358c:	41f7579b          	sraiw	a5,a4,0x1f
    80003590:	01d7d79b          	srliw	a5,a5,0x1d
    80003594:	9fb9                	addw	a5,a5,a4
    80003596:	4037d79b          	sraiw	a5,a5,0x3
    8000359a:	00f90633          	add	a2,s2,a5
    8000359e:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    800035a2:	00c6f5b3          	and	a1,a3,a2
    800035a6:	d585                	beqz	a1,800034ce <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035a8:	2705                	addiw	a4,a4,1
    800035aa:	2485                	addiw	s1,s1,1
    800035ac:	fd471ae3          	bne	a4,s4,80003580 <balloc+0xec>
    800035b0:	b769                	j	8000353a <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800035b2:	00005517          	auipc	a0,0x5
    800035b6:	0be50513          	addi	a0,a0,190 # 80008670 <syscalls+0x130>
    800035ba:	ffffd097          	auipc	ra,0xffffd
    800035be:	fd0080e7          	jalr	-48(ra) # 8000058a <printf>
  return 0;
    800035c2:	4481                	li	s1,0
    800035c4:	bfa9                	j	8000351e <balloc+0x8a>

00000000800035c6 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800035c6:	7179                	addi	sp,sp,-48
    800035c8:	f406                	sd	ra,40(sp)
    800035ca:	f022                	sd	s0,32(sp)
    800035cc:	ec26                	sd	s1,24(sp)
    800035ce:	e84a                	sd	s2,16(sp)
    800035d0:	e44e                	sd	s3,8(sp)
    800035d2:	e052                	sd	s4,0(sp)
    800035d4:	1800                	addi	s0,sp,48
    800035d6:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800035d8:	47ad                	li	a5,11
    800035da:	02b7e863          	bltu	a5,a1,8000360a <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800035de:	02059793          	slli	a5,a1,0x20
    800035e2:	01e7d593          	srli	a1,a5,0x1e
    800035e6:	00b504b3          	add	s1,a0,a1
    800035ea:	0504a903          	lw	s2,80(s1)
    800035ee:	06091e63          	bnez	s2,8000366a <bmap+0xa4>
      addr = balloc(ip->dev);
    800035f2:	4108                	lw	a0,0(a0)
    800035f4:	00000097          	auipc	ra,0x0
    800035f8:	ea0080e7          	jalr	-352(ra) # 80003494 <balloc>
    800035fc:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003600:	06090563          	beqz	s2,8000366a <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003604:	0524a823          	sw	s2,80(s1)
    80003608:	a08d                	j	8000366a <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000360a:	ff45849b          	addiw	s1,a1,-12
    8000360e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003612:	0ff00793          	li	a5,255
    80003616:	08e7e563          	bltu	a5,a4,800036a0 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000361a:	08052903          	lw	s2,128(a0)
    8000361e:	00091d63          	bnez	s2,80003638 <bmap+0x72>
      addr = balloc(ip->dev);
    80003622:	4108                	lw	a0,0(a0)
    80003624:	00000097          	auipc	ra,0x0
    80003628:	e70080e7          	jalr	-400(ra) # 80003494 <balloc>
    8000362c:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003630:	02090d63          	beqz	s2,8000366a <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003634:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003638:	85ca                	mv	a1,s2
    8000363a:	0009a503          	lw	a0,0(s3)
    8000363e:	00000097          	auipc	ra,0x0
    80003642:	b94080e7          	jalr	-1132(ra) # 800031d2 <bread>
    80003646:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003648:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000364c:	02049713          	slli	a4,s1,0x20
    80003650:	01e75593          	srli	a1,a4,0x1e
    80003654:	00b784b3          	add	s1,a5,a1
    80003658:	0004a903          	lw	s2,0(s1)
    8000365c:	02090063          	beqz	s2,8000367c <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003660:	8552                	mv	a0,s4
    80003662:	00000097          	auipc	ra,0x0
    80003666:	ca0080e7          	jalr	-864(ra) # 80003302 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000366a:	854a                	mv	a0,s2
    8000366c:	70a2                	ld	ra,40(sp)
    8000366e:	7402                	ld	s0,32(sp)
    80003670:	64e2                	ld	s1,24(sp)
    80003672:	6942                	ld	s2,16(sp)
    80003674:	69a2                	ld	s3,8(sp)
    80003676:	6a02                	ld	s4,0(sp)
    80003678:	6145                	addi	sp,sp,48
    8000367a:	8082                	ret
      addr = balloc(ip->dev);
    8000367c:	0009a503          	lw	a0,0(s3)
    80003680:	00000097          	auipc	ra,0x0
    80003684:	e14080e7          	jalr	-492(ra) # 80003494 <balloc>
    80003688:	0005091b          	sext.w	s2,a0
      if(addr){
    8000368c:	fc090ae3          	beqz	s2,80003660 <bmap+0x9a>
        a[bn] = addr;
    80003690:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003694:	8552                	mv	a0,s4
    80003696:	00001097          	auipc	ra,0x1
    8000369a:	ef6080e7          	jalr	-266(ra) # 8000458c <log_write>
    8000369e:	b7c9                	j	80003660 <bmap+0x9a>
  panic("bmap: out of range");
    800036a0:	00005517          	auipc	a0,0x5
    800036a4:	fe850513          	addi	a0,a0,-24 # 80008688 <syscalls+0x148>
    800036a8:	ffffd097          	auipc	ra,0xffffd
    800036ac:	e98080e7          	jalr	-360(ra) # 80000540 <panic>

00000000800036b0 <iget>:
{
    800036b0:	7179                	addi	sp,sp,-48
    800036b2:	f406                	sd	ra,40(sp)
    800036b4:	f022                	sd	s0,32(sp)
    800036b6:	ec26                	sd	s1,24(sp)
    800036b8:	e84a                	sd	s2,16(sp)
    800036ba:	e44e                	sd	s3,8(sp)
    800036bc:	e052                	sd	s4,0(sp)
    800036be:	1800                	addi	s0,sp,48
    800036c0:	89aa                	mv	s3,a0
    800036c2:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800036c4:	0001d517          	auipc	a0,0x1d
    800036c8:	dc450513          	addi	a0,a0,-572 # 80020488 <itable>
    800036cc:	ffffd097          	auipc	ra,0xffffd
    800036d0:	50a080e7          	jalr	1290(ra) # 80000bd6 <acquire>
  empty = 0;
    800036d4:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036d6:	0001d497          	auipc	s1,0x1d
    800036da:	dca48493          	addi	s1,s1,-566 # 800204a0 <itable+0x18>
    800036de:	0001f697          	auipc	a3,0x1f
    800036e2:	85268693          	addi	a3,a3,-1966 # 80021f30 <log>
    800036e6:	a039                	j	800036f4 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036e8:	02090b63          	beqz	s2,8000371e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036ec:	08848493          	addi	s1,s1,136
    800036f0:	02d48a63          	beq	s1,a3,80003724 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800036f4:	449c                	lw	a5,8(s1)
    800036f6:	fef059e3          	blez	a5,800036e8 <iget+0x38>
    800036fa:	4098                	lw	a4,0(s1)
    800036fc:	ff3716e3          	bne	a4,s3,800036e8 <iget+0x38>
    80003700:	40d8                	lw	a4,4(s1)
    80003702:	ff4713e3          	bne	a4,s4,800036e8 <iget+0x38>
      ip->ref++;
    80003706:	2785                	addiw	a5,a5,1
    80003708:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000370a:	0001d517          	auipc	a0,0x1d
    8000370e:	d7e50513          	addi	a0,a0,-642 # 80020488 <itable>
    80003712:	ffffd097          	auipc	ra,0xffffd
    80003716:	578080e7          	jalr	1400(ra) # 80000c8a <release>
      return ip;
    8000371a:	8926                	mv	s2,s1
    8000371c:	a03d                	j	8000374a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000371e:	f7f9                	bnez	a5,800036ec <iget+0x3c>
    80003720:	8926                	mv	s2,s1
    80003722:	b7e9                	j	800036ec <iget+0x3c>
  if(empty == 0)
    80003724:	02090c63          	beqz	s2,8000375c <iget+0xac>
  ip->dev = dev;
    80003728:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000372c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003730:	4785                	li	a5,1
    80003732:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003736:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000373a:	0001d517          	auipc	a0,0x1d
    8000373e:	d4e50513          	addi	a0,a0,-690 # 80020488 <itable>
    80003742:	ffffd097          	auipc	ra,0xffffd
    80003746:	548080e7          	jalr	1352(ra) # 80000c8a <release>
}
    8000374a:	854a                	mv	a0,s2
    8000374c:	70a2                	ld	ra,40(sp)
    8000374e:	7402                	ld	s0,32(sp)
    80003750:	64e2                	ld	s1,24(sp)
    80003752:	6942                	ld	s2,16(sp)
    80003754:	69a2                	ld	s3,8(sp)
    80003756:	6a02                	ld	s4,0(sp)
    80003758:	6145                	addi	sp,sp,48
    8000375a:	8082                	ret
    panic("iget: no inodes");
    8000375c:	00005517          	auipc	a0,0x5
    80003760:	f4450513          	addi	a0,a0,-188 # 800086a0 <syscalls+0x160>
    80003764:	ffffd097          	auipc	ra,0xffffd
    80003768:	ddc080e7          	jalr	-548(ra) # 80000540 <panic>

000000008000376c <fsinit>:
fsinit(int dev) {
    8000376c:	7179                	addi	sp,sp,-48
    8000376e:	f406                	sd	ra,40(sp)
    80003770:	f022                	sd	s0,32(sp)
    80003772:	ec26                	sd	s1,24(sp)
    80003774:	e84a                	sd	s2,16(sp)
    80003776:	e44e                	sd	s3,8(sp)
    80003778:	1800                	addi	s0,sp,48
    8000377a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000377c:	4585                	li	a1,1
    8000377e:	00000097          	auipc	ra,0x0
    80003782:	a54080e7          	jalr	-1452(ra) # 800031d2 <bread>
    80003786:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003788:	0001d997          	auipc	s3,0x1d
    8000378c:	ce098993          	addi	s3,s3,-800 # 80020468 <sb>
    80003790:	02000613          	li	a2,32
    80003794:	05850593          	addi	a1,a0,88
    80003798:	854e                	mv	a0,s3
    8000379a:	ffffd097          	auipc	ra,0xffffd
    8000379e:	594080e7          	jalr	1428(ra) # 80000d2e <memmove>
  brelse(bp);
    800037a2:	8526                	mv	a0,s1
    800037a4:	00000097          	auipc	ra,0x0
    800037a8:	b5e080e7          	jalr	-1186(ra) # 80003302 <brelse>
  if(sb.magic != FSMAGIC)
    800037ac:	0009a703          	lw	a4,0(s3)
    800037b0:	102037b7          	lui	a5,0x10203
    800037b4:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800037b8:	02f71263          	bne	a4,a5,800037dc <fsinit+0x70>
  initlog(dev, &sb);
    800037bc:	0001d597          	auipc	a1,0x1d
    800037c0:	cac58593          	addi	a1,a1,-852 # 80020468 <sb>
    800037c4:	854a                	mv	a0,s2
    800037c6:	00001097          	auipc	ra,0x1
    800037ca:	b4a080e7          	jalr	-1206(ra) # 80004310 <initlog>
}
    800037ce:	70a2                	ld	ra,40(sp)
    800037d0:	7402                	ld	s0,32(sp)
    800037d2:	64e2                	ld	s1,24(sp)
    800037d4:	6942                	ld	s2,16(sp)
    800037d6:	69a2                	ld	s3,8(sp)
    800037d8:	6145                	addi	sp,sp,48
    800037da:	8082                	ret
    panic("invalid file system");
    800037dc:	00005517          	auipc	a0,0x5
    800037e0:	ed450513          	addi	a0,a0,-300 # 800086b0 <syscalls+0x170>
    800037e4:	ffffd097          	auipc	ra,0xffffd
    800037e8:	d5c080e7          	jalr	-676(ra) # 80000540 <panic>

00000000800037ec <iinit>:
{
    800037ec:	7179                	addi	sp,sp,-48
    800037ee:	f406                	sd	ra,40(sp)
    800037f0:	f022                	sd	s0,32(sp)
    800037f2:	ec26                	sd	s1,24(sp)
    800037f4:	e84a                	sd	s2,16(sp)
    800037f6:	e44e                	sd	s3,8(sp)
    800037f8:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800037fa:	00005597          	auipc	a1,0x5
    800037fe:	ece58593          	addi	a1,a1,-306 # 800086c8 <syscalls+0x188>
    80003802:	0001d517          	auipc	a0,0x1d
    80003806:	c8650513          	addi	a0,a0,-890 # 80020488 <itable>
    8000380a:	ffffd097          	auipc	ra,0xffffd
    8000380e:	33c080e7          	jalr	828(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003812:	0001d497          	auipc	s1,0x1d
    80003816:	c9e48493          	addi	s1,s1,-866 # 800204b0 <itable+0x28>
    8000381a:	0001e997          	auipc	s3,0x1e
    8000381e:	72698993          	addi	s3,s3,1830 # 80021f40 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003822:	00005917          	auipc	s2,0x5
    80003826:	eae90913          	addi	s2,s2,-338 # 800086d0 <syscalls+0x190>
    8000382a:	85ca                	mv	a1,s2
    8000382c:	8526                	mv	a0,s1
    8000382e:	00001097          	auipc	ra,0x1
    80003832:	e42080e7          	jalr	-446(ra) # 80004670 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003836:	08848493          	addi	s1,s1,136
    8000383a:	ff3498e3          	bne	s1,s3,8000382a <iinit+0x3e>
}
    8000383e:	70a2                	ld	ra,40(sp)
    80003840:	7402                	ld	s0,32(sp)
    80003842:	64e2                	ld	s1,24(sp)
    80003844:	6942                	ld	s2,16(sp)
    80003846:	69a2                	ld	s3,8(sp)
    80003848:	6145                	addi	sp,sp,48
    8000384a:	8082                	ret

000000008000384c <ialloc>:
{
    8000384c:	715d                	addi	sp,sp,-80
    8000384e:	e486                	sd	ra,72(sp)
    80003850:	e0a2                	sd	s0,64(sp)
    80003852:	fc26                	sd	s1,56(sp)
    80003854:	f84a                	sd	s2,48(sp)
    80003856:	f44e                	sd	s3,40(sp)
    80003858:	f052                	sd	s4,32(sp)
    8000385a:	ec56                	sd	s5,24(sp)
    8000385c:	e85a                	sd	s6,16(sp)
    8000385e:	e45e                	sd	s7,8(sp)
    80003860:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003862:	0001d717          	auipc	a4,0x1d
    80003866:	c1272703          	lw	a4,-1006(a4) # 80020474 <sb+0xc>
    8000386a:	4785                	li	a5,1
    8000386c:	04e7fa63          	bgeu	a5,a4,800038c0 <ialloc+0x74>
    80003870:	8aaa                	mv	s5,a0
    80003872:	8bae                	mv	s7,a1
    80003874:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003876:	0001da17          	auipc	s4,0x1d
    8000387a:	bf2a0a13          	addi	s4,s4,-1038 # 80020468 <sb>
    8000387e:	00048b1b          	sext.w	s6,s1
    80003882:	0044d593          	srli	a1,s1,0x4
    80003886:	018a2783          	lw	a5,24(s4)
    8000388a:	9dbd                	addw	a1,a1,a5
    8000388c:	8556                	mv	a0,s5
    8000388e:	00000097          	auipc	ra,0x0
    80003892:	944080e7          	jalr	-1724(ra) # 800031d2 <bread>
    80003896:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003898:	05850993          	addi	s3,a0,88
    8000389c:	00f4f793          	andi	a5,s1,15
    800038a0:	079a                	slli	a5,a5,0x6
    800038a2:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800038a4:	00099783          	lh	a5,0(s3)
    800038a8:	c3a1                	beqz	a5,800038e8 <ialloc+0x9c>
    brelse(bp);
    800038aa:	00000097          	auipc	ra,0x0
    800038ae:	a58080e7          	jalr	-1448(ra) # 80003302 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800038b2:	0485                	addi	s1,s1,1
    800038b4:	00ca2703          	lw	a4,12(s4)
    800038b8:	0004879b          	sext.w	a5,s1
    800038bc:	fce7e1e3          	bltu	a5,a4,8000387e <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800038c0:	00005517          	auipc	a0,0x5
    800038c4:	e1850513          	addi	a0,a0,-488 # 800086d8 <syscalls+0x198>
    800038c8:	ffffd097          	auipc	ra,0xffffd
    800038cc:	cc2080e7          	jalr	-830(ra) # 8000058a <printf>
  return 0;
    800038d0:	4501                	li	a0,0
}
    800038d2:	60a6                	ld	ra,72(sp)
    800038d4:	6406                	ld	s0,64(sp)
    800038d6:	74e2                	ld	s1,56(sp)
    800038d8:	7942                	ld	s2,48(sp)
    800038da:	79a2                	ld	s3,40(sp)
    800038dc:	7a02                	ld	s4,32(sp)
    800038de:	6ae2                	ld	s5,24(sp)
    800038e0:	6b42                	ld	s6,16(sp)
    800038e2:	6ba2                	ld	s7,8(sp)
    800038e4:	6161                	addi	sp,sp,80
    800038e6:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800038e8:	04000613          	li	a2,64
    800038ec:	4581                	li	a1,0
    800038ee:	854e                	mv	a0,s3
    800038f0:	ffffd097          	auipc	ra,0xffffd
    800038f4:	3e2080e7          	jalr	994(ra) # 80000cd2 <memset>
      dip->type = type;
    800038f8:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800038fc:	854a                	mv	a0,s2
    800038fe:	00001097          	auipc	ra,0x1
    80003902:	c8e080e7          	jalr	-882(ra) # 8000458c <log_write>
      brelse(bp);
    80003906:	854a                	mv	a0,s2
    80003908:	00000097          	auipc	ra,0x0
    8000390c:	9fa080e7          	jalr	-1542(ra) # 80003302 <brelse>
      return iget(dev, inum);
    80003910:	85da                	mv	a1,s6
    80003912:	8556                	mv	a0,s5
    80003914:	00000097          	auipc	ra,0x0
    80003918:	d9c080e7          	jalr	-612(ra) # 800036b0 <iget>
    8000391c:	bf5d                	j	800038d2 <ialloc+0x86>

000000008000391e <iupdate>:
{
    8000391e:	1101                	addi	sp,sp,-32
    80003920:	ec06                	sd	ra,24(sp)
    80003922:	e822                	sd	s0,16(sp)
    80003924:	e426                	sd	s1,8(sp)
    80003926:	e04a                	sd	s2,0(sp)
    80003928:	1000                	addi	s0,sp,32
    8000392a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000392c:	415c                	lw	a5,4(a0)
    8000392e:	0047d79b          	srliw	a5,a5,0x4
    80003932:	0001d597          	auipc	a1,0x1d
    80003936:	b4e5a583          	lw	a1,-1202(a1) # 80020480 <sb+0x18>
    8000393a:	9dbd                	addw	a1,a1,a5
    8000393c:	4108                	lw	a0,0(a0)
    8000393e:	00000097          	auipc	ra,0x0
    80003942:	894080e7          	jalr	-1900(ra) # 800031d2 <bread>
    80003946:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003948:	05850793          	addi	a5,a0,88
    8000394c:	40d8                	lw	a4,4(s1)
    8000394e:	8b3d                	andi	a4,a4,15
    80003950:	071a                	slli	a4,a4,0x6
    80003952:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003954:	04449703          	lh	a4,68(s1)
    80003958:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    8000395c:	04649703          	lh	a4,70(s1)
    80003960:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003964:	04849703          	lh	a4,72(s1)
    80003968:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    8000396c:	04a49703          	lh	a4,74(s1)
    80003970:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003974:	44f8                	lw	a4,76(s1)
    80003976:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003978:	03400613          	li	a2,52
    8000397c:	05048593          	addi	a1,s1,80
    80003980:	00c78513          	addi	a0,a5,12
    80003984:	ffffd097          	auipc	ra,0xffffd
    80003988:	3aa080e7          	jalr	938(ra) # 80000d2e <memmove>
  log_write(bp);
    8000398c:	854a                	mv	a0,s2
    8000398e:	00001097          	auipc	ra,0x1
    80003992:	bfe080e7          	jalr	-1026(ra) # 8000458c <log_write>
  brelse(bp);
    80003996:	854a                	mv	a0,s2
    80003998:	00000097          	auipc	ra,0x0
    8000399c:	96a080e7          	jalr	-1686(ra) # 80003302 <brelse>
}
    800039a0:	60e2                	ld	ra,24(sp)
    800039a2:	6442                	ld	s0,16(sp)
    800039a4:	64a2                	ld	s1,8(sp)
    800039a6:	6902                	ld	s2,0(sp)
    800039a8:	6105                	addi	sp,sp,32
    800039aa:	8082                	ret

00000000800039ac <idup>:
{
    800039ac:	1101                	addi	sp,sp,-32
    800039ae:	ec06                	sd	ra,24(sp)
    800039b0:	e822                	sd	s0,16(sp)
    800039b2:	e426                	sd	s1,8(sp)
    800039b4:	1000                	addi	s0,sp,32
    800039b6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800039b8:	0001d517          	auipc	a0,0x1d
    800039bc:	ad050513          	addi	a0,a0,-1328 # 80020488 <itable>
    800039c0:	ffffd097          	auipc	ra,0xffffd
    800039c4:	216080e7          	jalr	534(ra) # 80000bd6 <acquire>
  ip->ref++;
    800039c8:	449c                	lw	a5,8(s1)
    800039ca:	2785                	addiw	a5,a5,1
    800039cc:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039ce:	0001d517          	auipc	a0,0x1d
    800039d2:	aba50513          	addi	a0,a0,-1350 # 80020488 <itable>
    800039d6:	ffffd097          	auipc	ra,0xffffd
    800039da:	2b4080e7          	jalr	692(ra) # 80000c8a <release>
}
    800039de:	8526                	mv	a0,s1
    800039e0:	60e2                	ld	ra,24(sp)
    800039e2:	6442                	ld	s0,16(sp)
    800039e4:	64a2                	ld	s1,8(sp)
    800039e6:	6105                	addi	sp,sp,32
    800039e8:	8082                	ret

00000000800039ea <ilock>:
{
    800039ea:	1101                	addi	sp,sp,-32
    800039ec:	ec06                	sd	ra,24(sp)
    800039ee:	e822                	sd	s0,16(sp)
    800039f0:	e426                	sd	s1,8(sp)
    800039f2:	e04a                	sd	s2,0(sp)
    800039f4:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800039f6:	c115                	beqz	a0,80003a1a <ilock+0x30>
    800039f8:	84aa                	mv	s1,a0
    800039fa:	451c                	lw	a5,8(a0)
    800039fc:	00f05f63          	blez	a5,80003a1a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003a00:	0541                	addi	a0,a0,16
    80003a02:	00001097          	auipc	ra,0x1
    80003a06:	ca8080e7          	jalr	-856(ra) # 800046aa <acquiresleep>
  if(ip->valid == 0){
    80003a0a:	40bc                	lw	a5,64(s1)
    80003a0c:	cf99                	beqz	a5,80003a2a <ilock+0x40>
}
    80003a0e:	60e2                	ld	ra,24(sp)
    80003a10:	6442                	ld	s0,16(sp)
    80003a12:	64a2                	ld	s1,8(sp)
    80003a14:	6902                	ld	s2,0(sp)
    80003a16:	6105                	addi	sp,sp,32
    80003a18:	8082                	ret
    panic("ilock");
    80003a1a:	00005517          	auipc	a0,0x5
    80003a1e:	cd650513          	addi	a0,a0,-810 # 800086f0 <syscalls+0x1b0>
    80003a22:	ffffd097          	auipc	ra,0xffffd
    80003a26:	b1e080e7          	jalr	-1250(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a2a:	40dc                	lw	a5,4(s1)
    80003a2c:	0047d79b          	srliw	a5,a5,0x4
    80003a30:	0001d597          	auipc	a1,0x1d
    80003a34:	a505a583          	lw	a1,-1456(a1) # 80020480 <sb+0x18>
    80003a38:	9dbd                	addw	a1,a1,a5
    80003a3a:	4088                	lw	a0,0(s1)
    80003a3c:	fffff097          	auipc	ra,0xfffff
    80003a40:	796080e7          	jalr	1942(ra) # 800031d2 <bread>
    80003a44:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a46:	05850593          	addi	a1,a0,88
    80003a4a:	40dc                	lw	a5,4(s1)
    80003a4c:	8bbd                	andi	a5,a5,15
    80003a4e:	079a                	slli	a5,a5,0x6
    80003a50:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003a52:	00059783          	lh	a5,0(a1)
    80003a56:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003a5a:	00259783          	lh	a5,2(a1)
    80003a5e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003a62:	00459783          	lh	a5,4(a1)
    80003a66:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a6a:	00659783          	lh	a5,6(a1)
    80003a6e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a72:	459c                	lw	a5,8(a1)
    80003a74:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a76:	03400613          	li	a2,52
    80003a7a:	05b1                	addi	a1,a1,12
    80003a7c:	05048513          	addi	a0,s1,80
    80003a80:	ffffd097          	auipc	ra,0xffffd
    80003a84:	2ae080e7          	jalr	686(ra) # 80000d2e <memmove>
    brelse(bp);
    80003a88:	854a                	mv	a0,s2
    80003a8a:	00000097          	auipc	ra,0x0
    80003a8e:	878080e7          	jalr	-1928(ra) # 80003302 <brelse>
    ip->valid = 1;
    80003a92:	4785                	li	a5,1
    80003a94:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a96:	04449783          	lh	a5,68(s1)
    80003a9a:	fbb5                	bnez	a5,80003a0e <ilock+0x24>
      panic("ilock: no type");
    80003a9c:	00005517          	auipc	a0,0x5
    80003aa0:	c5c50513          	addi	a0,a0,-932 # 800086f8 <syscalls+0x1b8>
    80003aa4:	ffffd097          	auipc	ra,0xffffd
    80003aa8:	a9c080e7          	jalr	-1380(ra) # 80000540 <panic>

0000000080003aac <iunlock>:
{
    80003aac:	1101                	addi	sp,sp,-32
    80003aae:	ec06                	sd	ra,24(sp)
    80003ab0:	e822                	sd	s0,16(sp)
    80003ab2:	e426                	sd	s1,8(sp)
    80003ab4:	e04a                	sd	s2,0(sp)
    80003ab6:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003ab8:	c905                	beqz	a0,80003ae8 <iunlock+0x3c>
    80003aba:	84aa                	mv	s1,a0
    80003abc:	01050913          	addi	s2,a0,16
    80003ac0:	854a                	mv	a0,s2
    80003ac2:	00001097          	auipc	ra,0x1
    80003ac6:	c82080e7          	jalr	-894(ra) # 80004744 <holdingsleep>
    80003aca:	cd19                	beqz	a0,80003ae8 <iunlock+0x3c>
    80003acc:	449c                	lw	a5,8(s1)
    80003ace:	00f05d63          	blez	a5,80003ae8 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003ad2:	854a                	mv	a0,s2
    80003ad4:	00001097          	auipc	ra,0x1
    80003ad8:	c2c080e7          	jalr	-980(ra) # 80004700 <releasesleep>
}
    80003adc:	60e2                	ld	ra,24(sp)
    80003ade:	6442                	ld	s0,16(sp)
    80003ae0:	64a2                	ld	s1,8(sp)
    80003ae2:	6902                	ld	s2,0(sp)
    80003ae4:	6105                	addi	sp,sp,32
    80003ae6:	8082                	ret
    panic("iunlock");
    80003ae8:	00005517          	auipc	a0,0x5
    80003aec:	c2050513          	addi	a0,a0,-992 # 80008708 <syscalls+0x1c8>
    80003af0:	ffffd097          	auipc	ra,0xffffd
    80003af4:	a50080e7          	jalr	-1456(ra) # 80000540 <panic>

0000000080003af8 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003af8:	7179                	addi	sp,sp,-48
    80003afa:	f406                	sd	ra,40(sp)
    80003afc:	f022                	sd	s0,32(sp)
    80003afe:	ec26                	sd	s1,24(sp)
    80003b00:	e84a                	sd	s2,16(sp)
    80003b02:	e44e                	sd	s3,8(sp)
    80003b04:	e052                	sd	s4,0(sp)
    80003b06:	1800                	addi	s0,sp,48
    80003b08:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003b0a:	05050493          	addi	s1,a0,80
    80003b0e:	08050913          	addi	s2,a0,128
    80003b12:	a021                	j	80003b1a <itrunc+0x22>
    80003b14:	0491                	addi	s1,s1,4
    80003b16:	01248d63          	beq	s1,s2,80003b30 <itrunc+0x38>
    if(ip->addrs[i]){
    80003b1a:	408c                	lw	a1,0(s1)
    80003b1c:	dde5                	beqz	a1,80003b14 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003b1e:	0009a503          	lw	a0,0(s3)
    80003b22:	00000097          	auipc	ra,0x0
    80003b26:	8f6080e7          	jalr	-1802(ra) # 80003418 <bfree>
      ip->addrs[i] = 0;
    80003b2a:	0004a023          	sw	zero,0(s1)
    80003b2e:	b7dd                	j	80003b14 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003b30:	0809a583          	lw	a1,128(s3)
    80003b34:	e185                	bnez	a1,80003b54 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b36:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003b3a:	854e                	mv	a0,s3
    80003b3c:	00000097          	auipc	ra,0x0
    80003b40:	de2080e7          	jalr	-542(ra) # 8000391e <iupdate>
}
    80003b44:	70a2                	ld	ra,40(sp)
    80003b46:	7402                	ld	s0,32(sp)
    80003b48:	64e2                	ld	s1,24(sp)
    80003b4a:	6942                	ld	s2,16(sp)
    80003b4c:	69a2                	ld	s3,8(sp)
    80003b4e:	6a02                	ld	s4,0(sp)
    80003b50:	6145                	addi	sp,sp,48
    80003b52:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003b54:	0009a503          	lw	a0,0(s3)
    80003b58:	fffff097          	auipc	ra,0xfffff
    80003b5c:	67a080e7          	jalr	1658(ra) # 800031d2 <bread>
    80003b60:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003b62:	05850493          	addi	s1,a0,88
    80003b66:	45850913          	addi	s2,a0,1112
    80003b6a:	a021                	j	80003b72 <itrunc+0x7a>
    80003b6c:	0491                	addi	s1,s1,4
    80003b6e:	01248b63          	beq	s1,s2,80003b84 <itrunc+0x8c>
      if(a[j])
    80003b72:	408c                	lw	a1,0(s1)
    80003b74:	dde5                	beqz	a1,80003b6c <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003b76:	0009a503          	lw	a0,0(s3)
    80003b7a:	00000097          	auipc	ra,0x0
    80003b7e:	89e080e7          	jalr	-1890(ra) # 80003418 <bfree>
    80003b82:	b7ed                	j	80003b6c <itrunc+0x74>
    brelse(bp);
    80003b84:	8552                	mv	a0,s4
    80003b86:	fffff097          	auipc	ra,0xfffff
    80003b8a:	77c080e7          	jalr	1916(ra) # 80003302 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b8e:	0809a583          	lw	a1,128(s3)
    80003b92:	0009a503          	lw	a0,0(s3)
    80003b96:	00000097          	auipc	ra,0x0
    80003b9a:	882080e7          	jalr	-1918(ra) # 80003418 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b9e:	0809a023          	sw	zero,128(s3)
    80003ba2:	bf51                	j	80003b36 <itrunc+0x3e>

0000000080003ba4 <iput>:
{
    80003ba4:	1101                	addi	sp,sp,-32
    80003ba6:	ec06                	sd	ra,24(sp)
    80003ba8:	e822                	sd	s0,16(sp)
    80003baa:	e426                	sd	s1,8(sp)
    80003bac:	e04a                	sd	s2,0(sp)
    80003bae:	1000                	addi	s0,sp,32
    80003bb0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003bb2:	0001d517          	auipc	a0,0x1d
    80003bb6:	8d650513          	addi	a0,a0,-1834 # 80020488 <itable>
    80003bba:	ffffd097          	auipc	ra,0xffffd
    80003bbe:	01c080e7          	jalr	28(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003bc2:	4498                	lw	a4,8(s1)
    80003bc4:	4785                	li	a5,1
    80003bc6:	02f70363          	beq	a4,a5,80003bec <iput+0x48>
  ip->ref--;
    80003bca:	449c                	lw	a5,8(s1)
    80003bcc:	37fd                	addiw	a5,a5,-1
    80003bce:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003bd0:	0001d517          	auipc	a0,0x1d
    80003bd4:	8b850513          	addi	a0,a0,-1864 # 80020488 <itable>
    80003bd8:	ffffd097          	auipc	ra,0xffffd
    80003bdc:	0b2080e7          	jalr	178(ra) # 80000c8a <release>
}
    80003be0:	60e2                	ld	ra,24(sp)
    80003be2:	6442                	ld	s0,16(sp)
    80003be4:	64a2                	ld	s1,8(sp)
    80003be6:	6902                	ld	s2,0(sp)
    80003be8:	6105                	addi	sp,sp,32
    80003bea:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003bec:	40bc                	lw	a5,64(s1)
    80003bee:	dff1                	beqz	a5,80003bca <iput+0x26>
    80003bf0:	04a49783          	lh	a5,74(s1)
    80003bf4:	fbf9                	bnez	a5,80003bca <iput+0x26>
    acquiresleep(&ip->lock);
    80003bf6:	01048913          	addi	s2,s1,16
    80003bfa:	854a                	mv	a0,s2
    80003bfc:	00001097          	auipc	ra,0x1
    80003c00:	aae080e7          	jalr	-1362(ra) # 800046aa <acquiresleep>
    release(&itable.lock);
    80003c04:	0001d517          	auipc	a0,0x1d
    80003c08:	88450513          	addi	a0,a0,-1916 # 80020488 <itable>
    80003c0c:	ffffd097          	auipc	ra,0xffffd
    80003c10:	07e080e7          	jalr	126(ra) # 80000c8a <release>
    itrunc(ip);
    80003c14:	8526                	mv	a0,s1
    80003c16:	00000097          	auipc	ra,0x0
    80003c1a:	ee2080e7          	jalr	-286(ra) # 80003af8 <itrunc>
    ip->type = 0;
    80003c1e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003c22:	8526                	mv	a0,s1
    80003c24:	00000097          	auipc	ra,0x0
    80003c28:	cfa080e7          	jalr	-774(ra) # 8000391e <iupdate>
    ip->valid = 0;
    80003c2c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003c30:	854a                	mv	a0,s2
    80003c32:	00001097          	auipc	ra,0x1
    80003c36:	ace080e7          	jalr	-1330(ra) # 80004700 <releasesleep>
    acquire(&itable.lock);
    80003c3a:	0001d517          	auipc	a0,0x1d
    80003c3e:	84e50513          	addi	a0,a0,-1970 # 80020488 <itable>
    80003c42:	ffffd097          	auipc	ra,0xffffd
    80003c46:	f94080e7          	jalr	-108(ra) # 80000bd6 <acquire>
    80003c4a:	b741                	j	80003bca <iput+0x26>

0000000080003c4c <iunlockput>:
{
    80003c4c:	1101                	addi	sp,sp,-32
    80003c4e:	ec06                	sd	ra,24(sp)
    80003c50:	e822                	sd	s0,16(sp)
    80003c52:	e426                	sd	s1,8(sp)
    80003c54:	1000                	addi	s0,sp,32
    80003c56:	84aa                	mv	s1,a0
  iunlock(ip);
    80003c58:	00000097          	auipc	ra,0x0
    80003c5c:	e54080e7          	jalr	-428(ra) # 80003aac <iunlock>
  iput(ip);
    80003c60:	8526                	mv	a0,s1
    80003c62:	00000097          	auipc	ra,0x0
    80003c66:	f42080e7          	jalr	-190(ra) # 80003ba4 <iput>
}
    80003c6a:	60e2                	ld	ra,24(sp)
    80003c6c:	6442                	ld	s0,16(sp)
    80003c6e:	64a2                	ld	s1,8(sp)
    80003c70:	6105                	addi	sp,sp,32
    80003c72:	8082                	ret

0000000080003c74 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c74:	1141                	addi	sp,sp,-16
    80003c76:	e422                	sd	s0,8(sp)
    80003c78:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c7a:	411c                	lw	a5,0(a0)
    80003c7c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c7e:	415c                	lw	a5,4(a0)
    80003c80:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c82:	04451783          	lh	a5,68(a0)
    80003c86:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c8a:	04a51783          	lh	a5,74(a0)
    80003c8e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c92:	04c56783          	lwu	a5,76(a0)
    80003c96:	e99c                	sd	a5,16(a1)
}
    80003c98:	6422                	ld	s0,8(sp)
    80003c9a:	0141                	addi	sp,sp,16
    80003c9c:	8082                	ret

0000000080003c9e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c9e:	457c                	lw	a5,76(a0)
    80003ca0:	0ed7e963          	bltu	a5,a3,80003d92 <readi+0xf4>
{
    80003ca4:	7159                	addi	sp,sp,-112
    80003ca6:	f486                	sd	ra,104(sp)
    80003ca8:	f0a2                	sd	s0,96(sp)
    80003caa:	eca6                	sd	s1,88(sp)
    80003cac:	e8ca                	sd	s2,80(sp)
    80003cae:	e4ce                	sd	s3,72(sp)
    80003cb0:	e0d2                	sd	s4,64(sp)
    80003cb2:	fc56                	sd	s5,56(sp)
    80003cb4:	f85a                	sd	s6,48(sp)
    80003cb6:	f45e                	sd	s7,40(sp)
    80003cb8:	f062                	sd	s8,32(sp)
    80003cba:	ec66                	sd	s9,24(sp)
    80003cbc:	e86a                	sd	s10,16(sp)
    80003cbe:	e46e                	sd	s11,8(sp)
    80003cc0:	1880                	addi	s0,sp,112
    80003cc2:	8b2a                	mv	s6,a0
    80003cc4:	8bae                	mv	s7,a1
    80003cc6:	8a32                	mv	s4,a2
    80003cc8:	84b6                	mv	s1,a3
    80003cca:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003ccc:	9f35                	addw	a4,a4,a3
    return 0;
    80003cce:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003cd0:	0ad76063          	bltu	a4,a3,80003d70 <readi+0xd2>
  if(off + n > ip->size)
    80003cd4:	00e7f463          	bgeu	a5,a4,80003cdc <readi+0x3e>
    n = ip->size - off;
    80003cd8:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cdc:	0a0a8963          	beqz	s5,80003d8e <readi+0xf0>
    80003ce0:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ce2:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ce6:	5c7d                	li	s8,-1
    80003ce8:	a82d                	j	80003d22 <readi+0x84>
    80003cea:	020d1d93          	slli	s11,s10,0x20
    80003cee:	020ddd93          	srli	s11,s11,0x20
    80003cf2:	05890613          	addi	a2,s2,88
    80003cf6:	86ee                	mv	a3,s11
    80003cf8:	963a                	add	a2,a2,a4
    80003cfa:	85d2                	mv	a1,s4
    80003cfc:	855e                	mv	a0,s7
    80003cfe:	fffff097          	auipc	ra,0xfffff
    80003d02:	8ae080e7          	jalr	-1874(ra) # 800025ac <either_copyout>
    80003d06:	05850d63          	beq	a0,s8,80003d60 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003d0a:	854a                	mv	a0,s2
    80003d0c:	fffff097          	auipc	ra,0xfffff
    80003d10:	5f6080e7          	jalr	1526(ra) # 80003302 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d14:	013d09bb          	addw	s3,s10,s3
    80003d18:	009d04bb          	addw	s1,s10,s1
    80003d1c:	9a6e                	add	s4,s4,s11
    80003d1e:	0559f763          	bgeu	s3,s5,80003d6c <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003d22:	00a4d59b          	srliw	a1,s1,0xa
    80003d26:	855a                	mv	a0,s6
    80003d28:	00000097          	auipc	ra,0x0
    80003d2c:	89e080e7          	jalr	-1890(ra) # 800035c6 <bmap>
    80003d30:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d34:	cd85                	beqz	a1,80003d6c <readi+0xce>
    bp = bread(ip->dev, addr);
    80003d36:	000b2503          	lw	a0,0(s6)
    80003d3a:	fffff097          	auipc	ra,0xfffff
    80003d3e:	498080e7          	jalr	1176(ra) # 800031d2 <bread>
    80003d42:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d44:	3ff4f713          	andi	a4,s1,1023
    80003d48:	40ec87bb          	subw	a5,s9,a4
    80003d4c:	413a86bb          	subw	a3,s5,s3
    80003d50:	8d3e                	mv	s10,a5
    80003d52:	2781                	sext.w	a5,a5
    80003d54:	0006861b          	sext.w	a2,a3
    80003d58:	f8f679e3          	bgeu	a2,a5,80003cea <readi+0x4c>
    80003d5c:	8d36                	mv	s10,a3
    80003d5e:	b771                	j	80003cea <readi+0x4c>
      brelse(bp);
    80003d60:	854a                	mv	a0,s2
    80003d62:	fffff097          	auipc	ra,0xfffff
    80003d66:	5a0080e7          	jalr	1440(ra) # 80003302 <brelse>
      tot = -1;
    80003d6a:	59fd                	li	s3,-1
  }
  return tot;
    80003d6c:	0009851b          	sext.w	a0,s3
}
    80003d70:	70a6                	ld	ra,104(sp)
    80003d72:	7406                	ld	s0,96(sp)
    80003d74:	64e6                	ld	s1,88(sp)
    80003d76:	6946                	ld	s2,80(sp)
    80003d78:	69a6                	ld	s3,72(sp)
    80003d7a:	6a06                	ld	s4,64(sp)
    80003d7c:	7ae2                	ld	s5,56(sp)
    80003d7e:	7b42                	ld	s6,48(sp)
    80003d80:	7ba2                	ld	s7,40(sp)
    80003d82:	7c02                	ld	s8,32(sp)
    80003d84:	6ce2                	ld	s9,24(sp)
    80003d86:	6d42                	ld	s10,16(sp)
    80003d88:	6da2                	ld	s11,8(sp)
    80003d8a:	6165                	addi	sp,sp,112
    80003d8c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d8e:	89d6                	mv	s3,s5
    80003d90:	bff1                	j	80003d6c <readi+0xce>
    return 0;
    80003d92:	4501                	li	a0,0
}
    80003d94:	8082                	ret

0000000080003d96 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d96:	457c                	lw	a5,76(a0)
    80003d98:	10d7e863          	bltu	a5,a3,80003ea8 <writei+0x112>
{
    80003d9c:	7159                	addi	sp,sp,-112
    80003d9e:	f486                	sd	ra,104(sp)
    80003da0:	f0a2                	sd	s0,96(sp)
    80003da2:	eca6                	sd	s1,88(sp)
    80003da4:	e8ca                	sd	s2,80(sp)
    80003da6:	e4ce                	sd	s3,72(sp)
    80003da8:	e0d2                	sd	s4,64(sp)
    80003daa:	fc56                	sd	s5,56(sp)
    80003dac:	f85a                	sd	s6,48(sp)
    80003dae:	f45e                	sd	s7,40(sp)
    80003db0:	f062                	sd	s8,32(sp)
    80003db2:	ec66                	sd	s9,24(sp)
    80003db4:	e86a                	sd	s10,16(sp)
    80003db6:	e46e                	sd	s11,8(sp)
    80003db8:	1880                	addi	s0,sp,112
    80003dba:	8aaa                	mv	s5,a0
    80003dbc:	8bae                	mv	s7,a1
    80003dbe:	8a32                	mv	s4,a2
    80003dc0:	8936                	mv	s2,a3
    80003dc2:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003dc4:	00e687bb          	addw	a5,a3,a4
    80003dc8:	0ed7e263          	bltu	a5,a3,80003eac <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003dcc:	00043737          	lui	a4,0x43
    80003dd0:	0ef76063          	bltu	a4,a5,80003eb0 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003dd4:	0c0b0863          	beqz	s6,80003ea4 <writei+0x10e>
    80003dd8:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dda:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003dde:	5c7d                	li	s8,-1
    80003de0:	a091                	j	80003e24 <writei+0x8e>
    80003de2:	020d1d93          	slli	s11,s10,0x20
    80003de6:	020ddd93          	srli	s11,s11,0x20
    80003dea:	05848513          	addi	a0,s1,88
    80003dee:	86ee                	mv	a3,s11
    80003df0:	8652                	mv	a2,s4
    80003df2:	85de                	mv	a1,s7
    80003df4:	953a                	add	a0,a0,a4
    80003df6:	fffff097          	auipc	ra,0xfffff
    80003dfa:	80c080e7          	jalr	-2036(ra) # 80002602 <either_copyin>
    80003dfe:	07850263          	beq	a0,s8,80003e62 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003e02:	8526                	mv	a0,s1
    80003e04:	00000097          	auipc	ra,0x0
    80003e08:	788080e7          	jalr	1928(ra) # 8000458c <log_write>
    brelse(bp);
    80003e0c:	8526                	mv	a0,s1
    80003e0e:	fffff097          	auipc	ra,0xfffff
    80003e12:	4f4080e7          	jalr	1268(ra) # 80003302 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e16:	013d09bb          	addw	s3,s10,s3
    80003e1a:	012d093b          	addw	s2,s10,s2
    80003e1e:	9a6e                	add	s4,s4,s11
    80003e20:	0569f663          	bgeu	s3,s6,80003e6c <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003e24:	00a9559b          	srliw	a1,s2,0xa
    80003e28:	8556                	mv	a0,s5
    80003e2a:	fffff097          	auipc	ra,0xfffff
    80003e2e:	79c080e7          	jalr	1948(ra) # 800035c6 <bmap>
    80003e32:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003e36:	c99d                	beqz	a1,80003e6c <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003e38:	000aa503          	lw	a0,0(s5)
    80003e3c:	fffff097          	auipc	ra,0xfffff
    80003e40:	396080e7          	jalr	918(ra) # 800031d2 <bread>
    80003e44:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e46:	3ff97713          	andi	a4,s2,1023
    80003e4a:	40ec87bb          	subw	a5,s9,a4
    80003e4e:	413b06bb          	subw	a3,s6,s3
    80003e52:	8d3e                	mv	s10,a5
    80003e54:	2781                	sext.w	a5,a5
    80003e56:	0006861b          	sext.w	a2,a3
    80003e5a:	f8f674e3          	bgeu	a2,a5,80003de2 <writei+0x4c>
    80003e5e:	8d36                	mv	s10,a3
    80003e60:	b749                	j	80003de2 <writei+0x4c>
      brelse(bp);
    80003e62:	8526                	mv	a0,s1
    80003e64:	fffff097          	auipc	ra,0xfffff
    80003e68:	49e080e7          	jalr	1182(ra) # 80003302 <brelse>
  }

  if(off > ip->size)
    80003e6c:	04caa783          	lw	a5,76(s5)
    80003e70:	0127f463          	bgeu	a5,s2,80003e78 <writei+0xe2>
    ip->size = off;
    80003e74:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003e78:	8556                	mv	a0,s5
    80003e7a:	00000097          	auipc	ra,0x0
    80003e7e:	aa4080e7          	jalr	-1372(ra) # 8000391e <iupdate>

  return tot;
    80003e82:	0009851b          	sext.w	a0,s3
}
    80003e86:	70a6                	ld	ra,104(sp)
    80003e88:	7406                	ld	s0,96(sp)
    80003e8a:	64e6                	ld	s1,88(sp)
    80003e8c:	6946                	ld	s2,80(sp)
    80003e8e:	69a6                	ld	s3,72(sp)
    80003e90:	6a06                	ld	s4,64(sp)
    80003e92:	7ae2                	ld	s5,56(sp)
    80003e94:	7b42                	ld	s6,48(sp)
    80003e96:	7ba2                	ld	s7,40(sp)
    80003e98:	7c02                	ld	s8,32(sp)
    80003e9a:	6ce2                	ld	s9,24(sp)
    80003e9c:	6d42                	ld	s10,16(sp)
    80003e9e:	6da2                	ld	s11,8(sp)
    80003ea0:	6165                	addi	sp,sp,112
    80003ea2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ea4:	89da                	mv	s3,s6
    80003ea6:	bfc9                	j	80003e78 <writei+0xe2>
    return -1;
    80003ea8:	557d                	li	a0,-1
}
    80003eaa:	8082                	ret
    return -1;
    80003eac:	557d                	li	a0,-1
    80003eae:	bfe1                	j	80003e86 <writei+0xf0>
    return -1;
    80003eb0:	557d                	li	a0,-1
    80003eb2:	bfd1                	j	80003e86 <writei+0xf0>

0000000080003eb4 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003eb4:	1141                	addi	sp,sp,-16
    80003eb6:	e406                	sd	ra,8(sp)
    80003eb8:	e022                	sd	s0,0(sp)
    80003eba:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ebc:	4639                	li	a2,14
    80003ebe:	ffffd097          	auipc	ra,0xffffd
    80003ec2:	ee4080e7          	jalr	-284(ra) # 80000da2 <strncmp>
}
    80003ec6:	60a2                	ld	ra,8(sp)
    80003ec8:	6402                	ld	s0,0(sp)
    80003eca:	0141                	addi	sp,sp,16
    80003ecc:	8082                	ret

0000000080003ece <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003ece:	7139                	addi	sp,sp,-64
    80003ed0:	fc06                	sd	ra,56(sp)
    80003ed2:	f822                	sd	s0,48(sp)
    80003ed4:	f426                	sd	s1,40(sp)
    80003ed6:	f04a                	sd	s2,32(sp)
    80003ed8:	ec4e                	sd	s3,24(sp)
    80003eda:	e852                	sd	s4,16(sp)
    80003edc:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ede:	04451703          	lh	a4,68(a0)
    80003ee2:	4785                	li	a5,1
    80003ee4:	00f71a63          	bne	a4,a5,80003ef8 <dirlookup+0x2a>
    80003ee8:	892a                	mv	s2,a0
    80003eea:	89ae                	mv	s3,a1
    80003eec:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eee:	457c                	lw	a5,76(a0)
    80003ef0:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ef2:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ef4:	e79d                	bnez	a5,80003f22 <dirlookup+0x54>
    80003ef6:	a8a5                	j	80003f6e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ef8:	00005517          	auipc	a0,0x5
    80003efc:	81850513          	addi	a0,a0,-2024 # 80008710 <syscalls+0x1d0>
    80003f00:	ffffc097          	auipc	ra,0xffffc
    80003f04:	640080e7          	jalr	1600(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003f08:	00005517          	auipc	a0,0x5
    80003f0c:	82050513          	addi	a0,a0,-2016 # 80008728 <syscalls+0x1e8>
    80003f10:	ffffc097          	auipc	ra,0xffffc
    80003f14:	630080e7          	jalr	1584(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f18:	24c1                	addiw	s1,s1,16
    80003f1a:	04c92783          	lw	a5,76(s2)
    80003f1e:	04f4f763          	bgeu	s1,a5,80003f6c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f22:	4741                	li	a4,16
    80003f24:	86a6                	mv	a3,s1
    80003f26:	fc040613          	addi	a2,s0,-64
    80003f2a:	4581                	li	a1,0
    80003f2c:	854a                	mv	a0,s2
    80003f2e:	00000097          	auipc	ra,0x0
    80003f32:	d70080e7          	jalr	-656(ra) # 80003c9e <readi>
    80003f36:	47c1                	li	a5,16
    80003f38:	fcf518e3          	bne	a0,a5,80003f08 <dirlookup+0x3a>
    if(de.inum == 0)
    80003f3c:	fc045783          	lhu	a5,-64(s0)
    80003f40:	dfe1                	beqz	a5,80003f18 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003f42:	fc240593          	addi	a1,s0,-62
    80003f46:	854e                	mv	a0,s3
    80003f48:	00000097          	auipc	ra,0x0
    80003f4c:	f6c080e7          	jalr	-148(ra) # 80003eb4 <namecmp>
    80003f50:	f561                	bnez	a0,80003f18 <dirlookup+0x4a>
      if(poff)
    80003f52:	000a0463          	beqz	s4,80003f5a <dirlookup+0x8c>
        *poff = off;
    80003f56:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003f5a:	fc045583          	lhu	a1,-64(s0)
    80003f5e:	00092503          	lw	a0,0(s2)
    80003f62:	fffff097          	auipc	ra,0xfffff
    80003f66:	74e080e7          	jalr	1870(ra) # 800036b0 <iget>
    80003f6a:	a011                	j	80003f6e <dirlookup+0xa0>
  return 0;
    80003f6c:	4501                	li	a0,0
}
    80003f6e:	70e2                	ld	ra,56(sp)
    80003f70:	7442                	ld	s0,48(sp)
    80003f72:	74a2                	ld	s1,40(sp)
    80003f74:	7902                	ld	s2,32(sp)
    80003f76:	69e2                	ld	s3,24(sp)
    80003f78:	6a42                	ld	s4,16(sp)
    80003f7a:	6121                	addi	sp,sp,64
    80003f7c:	8082                	ret

0000000080003f7e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f7e:	711d                	addi	sp,sp,-96
    80003f80:	ec86                	sd	ra,88(sp)
    80003f82:	e8a2                	sd	s0,80(sp)
    80003f84:	e4a6                	sd	s1,72(sp)
    80003f86:	e0ca                	sd	s2,64(sp)
    80003f88:	fc4e                	sd	s3,56(sp)
    80003f8a:	f852                	sd	s4,48(sp)
    80003f8c:	f456                	sd	s5,40(sp)
    80003f8e:	f05a                	sd	s6,32(sp)
    80003f90:	ec5e                	sd	s7,24(sp)
    80003f92:	e862                	sd	s8,16(sp)
    80003f94:	e466                	sd	s9,8(sp)
    80003f96:	e06a                	sd	s10,0(sp)
    80003f98:	1080                	addi	s0,sp,96
    80003f9a:	84aa                	mv	s1,a0
    80003f9c:	8b2e                	mv	s6,a1
    80003f9e:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003fa0:	00054703          	lbu	a4,0(a0)
    80003fa4:	02f00793          	li	a5,47
    80003fa8:	02f70363          	beq	a4,a5,80003fce <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003fac:	ffffe097          	auipc	ra,0xffffe
    80003fb0:	a00080e7          	jalr	-1536(ra) # 800019ac <myproc>
    80003fb4:	15053503          	ld	a0,336(a0)
    80003fb8:	00000097          	auipc	ra,0x0
    80003fbc:	9f4080e7          	jalr	-1548(ra) # 800039ac <idup>
    80003fc0:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003fc2:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003fc6:	4cb5                	li	s9,13
  len = path - s;
    80003fc8:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003fca:	4c05                	li	s8,1
    80003fcc:	a87d                	j	8000408a <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003fce:	4585                	li	a1,1
    80003fd0:	4505                	li	a0,1
    80003fd2:	fffff097          	auipc	ra,0xfffff
    80003fd6:	6de080e7          	jalr	1758(ra) # 800036b0 <iget>
    80003fda:	8a2a                	mv	s4,a0
    80003fdc:	b7dd                	j	80003fc2 <namex+0x44>
      iunlockput(ip);
    80003fde:	8552                	mv	a0,s4
    80003fe0:	00000097          	auipc	ra,0x0
    80003fe4:	c6c080e7          	jalr	-916(ra) # 80003c4c <iunlockput>
      return 0;
    80003fe8:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003fea:	8552                	mv	a0,s4
    80003fec:	60e6                	ld	ra,88(sp)
    80003fee:	6446                	ld	s0,80(sp)
    80003ff0:	64a6                	ld	s1,72(sp)
    80003ff2:	6906                	ld	s2,64(sp)
    80003ff4:	79e2                	ld	s3,56(sp)
    80003ff6:	7a42                	ld	s4,48(sp)
    80003ff8:	7aa2                	ld	s5,40(sp)
    80003ffa:	7b02                	ld	s6,32(sp)
    80003ffc:	6be2                	ld	s7,24(sp)
    80003ffe:	6c42                	ld	s8,16(sp)
    80004000:	6ca2                	ld	s9,8(sp)
    80004002:	6d02                	ld	s10,0(sp)
    80004004:	6125                	addi	sp,sp,96
    80004006:	8082                	ret
      iunlock(ip);
    80004008:	8552                	mv	a0,s4
    8000400a:	00000097          	auipc	ra,0x0
    8000400e:	aa2080e7          	jalr	-1374(ra) # 80003aac <iunlock>
      return ip;
    80004012:	bfe1                	j	80003fea <namex+0x6c>
      iunlockput(ip);
    80004014:	8552                	mv	a0,s4
    80004016:	00000097          	auipc	ra,0x0
    8000401a:	c36080e7          	jalr	-970(ra) # 80003c4c <iunlockput>
      return 0;
    8000401e:	8a4e                	mv	s4,s3
    80004020:	b7e9                	j	80003fea <namex+0x6c>
  len = path - s;
    80004022:	40998633          	sub	a2,s3,s1
    80004026:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    8000402a:	09acd863          	bge	s9,s10,800040ba <namex+0x13c>
    memmove(name, s, DIRSIZ);
    8000402e:	4639                	li	a2,14
    80004030:	85a6                	mv	a1,s1
    80004032:	8556                	mv	a0,s5
    80004034:	ffffd097          	auipc	ra,0xffffd
    80004038:	cfa080e7          	jalr	-774(ra) # 80000d2e <memmove>
    8000403c:	84ce                	mv	s1,s3
  while(*path == '/')
    8000403e:	0004c783          	lbu	a5,0(s1)
    80004042:	01279763          	bne	a5,s2,80004050 <namex+0xd2>
    path++;
    80004046:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004048:	0004c783          	lbu	a5,0(s1)
    8000404c:	ff278de3          	beq	a5,s2,80004046 <namex+0xc8>
    ilock(ip);
    80004050:	8552                	mv	a0,s4
    80004052:	00000097          	auipc	ra,0x0
    80004056:	998080e7          	jalr	-1640(ra) # 800039ea <ilock>
    if(ip->type != T_DIR){
    8000405a:	044a1783          	lh	a5,68(s4)
    8000405e:	f98790e3          	bne	a5,s8,80003fde <namex+0x60>
    if(nameiparent && *path == '\0'){
    80004062:	000b0563          	beqz	s6,8000406c <namex+0xee>
    80004066:	0004c783          	lbu	a5,0(s1)
    8000406a:	dfd9                	beqz	a5,80004008 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000406c:	865e                	mv	a2,s7
    8000406e:	85d6                	mv	a1,s5
    80004070:	8552                	mv	a0,s4
    80004072:	00000097          	auipc	ra,0x0
    80004076:	e5c080e7          	jalr	-420(ra) # 80003ece <dirlookup>
    8000407a:	89aa                	mv	s3,a0
    8000407c:	dd41                	beqz	a0,80004014 <namex+0x96>
    iunlockput(ip);
    8000407e:	8552                	mv	a0,s4
    80004080:	00000097          	auipc	ra,0x0
    80004084:	bcc080e7          	jalr	-1076(ra) # 80003c4c <iunlockput>
    ip = next;
    80004088:	8a4e                	mv	s4,s3
  while(*path == '/')
    8000408a:	0004c783          	lbu	a5,0(s1)
    8000408e:	01279763          	bne	a5,s2,8000409c <namex+0x11e>
    path++;
    80004092:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004094:	0004c783          	lbu	a5,0(s1)
    80004098:	ff278de3          	beq	a5,s2,80004092 <namex+0x114>
  if(*path == 0)
    8000409c:	cb9d                	beqz	a5,800040d2 <namex+0x154>
  while(*path != '/' && *path != 0)
    8000409e:	0004c783          	lbu	a5,0(s1)
    800040a2:	89a6                	mv	s3,s1
  len = path - s;
    800040a4:	8d5e                	mv	s10,s7
    800040a6:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800040a8:	01278963          	beq	a5,s2,800040ba <namex+0x13c>
    800040ac:	dbbd                	beqz	a5,80004022 <namex+0xa4>
    path++;
    800040ae:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800040b0:	0009c783          	lbu	a5,0(s3)
    800040b4:	ff279ce3          	bne	a5,s2,800040ac <namex+0x12e>
    800040b8:	b7ad                	j	80004022 <namex+0xa4>
    memmove(name, s, len);
    800040ba:	2601                	sext.w	a2,a2
    800040bc:	85a6                	mv	a1,s1
    800040be:	8556                	mv	a0,s5
    800040c0:	ffffd097          	auipc	ra,0xffffd
    800040c4:	c6e080e7          	jalr	-914(ra) # 80000d2e <memmove>
    name[len] = 0;
    800040c8:	9d56                	add	s10,s10,s5
    800040ca:	000d0023          	sb	zero,0(s10)
    800040ce:	84ce                	mv	s1,s3
    800040d0:	b7bd                	j	8000403e <namex+0xc0>
  if(nameiparent){
    800040d2:	f00b0ce3          	beqz	s6,80003fea <namex+0x6c>
    iput(ip);
    800040d6:	8552                	mv	a0,s4
    800040d8:	00000097          	auipc	ra,0x0
    800040dc:	acc080e7          	jalr	-1332(ra) # 80003ba4 <iput>
    return 0;
    800040e0:	4a01                	li	s4,0
    800040e2:	b721                	j	80003fea <namex+0x6c>

00000000800040e4 <dirlink>:
{
    800040e4:	7139                	addi	sp,sp,-64
    800040e6:	fc06                	sd	ra,56(sp)
    800040e8:	f822                	sd	s0,48(sp)
    800040ea:	f426                	sd	s1,40(sp)
    800040ec:	f04a                	sd	s2,32(sp)
    800040ee:	ec4e                	sd	s3,24(sp)
    800040f0:	e852                	sd	s4,16(sp)
    800040f2:	0080                	addi	s0,sp,64
    800040f4:	892a                	mv	s2,a0
    800040f6:	8a2e                	mv	s4,a1
    800040f8:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800040fa:	4601                	li	a2,0
    800040fc:	00000097          	auipc	ra,0x0
    80004100:	dd2080e7          	jalr	-558(ra) # 80003ece <dirlookup>
    80004104:	e93d                	bnez	a0,8000417a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004106:	04c92483          	lw	s1,76(s2)
    8000410a:	c49d                	beqz	s1,80004138 <dirlink+0x54>
    8000410c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000410e:	4741                	li	a4,16
    80004110:	86a6                	mv	a3,s1
    80004112:	fc040613          	addi	a2,s0,-64
    80004116:	4581                	li	a1,0
    80004118:	854a                	mv	a0,s2
    8000411a:	00000097          	auipc	ra,0x0
    8000411e:	b84080e7          	jalr	-1148(ra) # 80003c9e <readi>
    80004122:	47c1                	li	a5,16
    80004124:	06f51163          	bne	a0,a5,80004186 <dirlink+0xa2>
    if(de.inum == 0)
    80004128:	fc045783          	lhu	a5,-64(s0)
    8000412c:	c791                	beqz	a5,80004138 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000412e:	24c1                	addiw	s1,s1,16
    80004130:	04c92783          	lw	a5,76(s2)
    80004134:	fcf4ede3          	bltu	s1,a5,8000410e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004138:	4639                	li	a2,14
    8000413a:	85d2                	mv	a1,s4
    8000413c:	fc240513          	addi	a0,s0,-62
    80004140:	ffffd097          	auipc	ra,0xffffd
    80004144:	c9e080e7          	jalr	-866(ra) # 80000dde <strncpy>
  de.inum = inum;
    80004148:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000414c:	4741                	li	a4,16
    8000414e:	86a6                	mv	a3,s1
    80004150:	fc040613          	addi	a2,s0,-64
    80004154:	4581                	li	a1,0
    80004156:	854a                	mv	a0,s2
    80004158:	00000097          	auipc	ra,0x0
    8000415c:	c3e080e7          	jalr	-962(ra) # 80003d96 <writei>
    80004160:	1541                	addi	a0,a0,-16
    80004162:	00a03533          	snez	a0,a0
    80004166:	40a00533          	neg	a0,a0
}
    8000416a:	70e2                	ld	ra,56(sp)
    8000416c:	7442                	ld	s0,48(sp)
    8000416e:	74a2                	ld	s1,40(sp)
    80004170:	7902                	ld	s2,32(sp)
    80004172:	69e2                	ld	s3,24(sp)
    80004174:	6a42                	ld	s4,16(sp)
    80004176:	6121                	addi	sp,sp,64
    80004178:	8082                	ret
    iput(ip);
    8000417a:	00000097          	auipc	ra,0x0
    8000417e:	a2a080e7          	jalr	-1494(ra) # 80003ba4 <iput>
    return -1;
    80004182:	557d                	li	a0,-1
    80004184:	b7dd                	j	8000416a <dirlink+0x86>
      panic("dirlink read");
    80004186:	00004517          	auipc	a0,0x4
    8000418a:	5b250513          	addi	a0,a0,1458 # 80008738 <syscalls+0x1f8>
    8000418e:	ffffc097          	auipc	ra,0xffffc
    80004192:	3b2080e7          	jalr	946(ra) # 80000540 <panic>

0000000080004196 <namei>:

struct inode*
namei(char *path)
{
    80004196:	1101                	addi	sp,sp,-32
    80004198:	ec06                	sd	ra,24(sp)
    8000419a:	e822                	sd	s0,16(sp)
    8000419c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000419e:	fe040613          	addi	a2,s0,-32
    800041a2:	4581                	li	a1,0
    800041a4:	00000097          	auipc	ra,0x0
    800041a8:	dda080e7          	jalr	-550(ra) # 80003f7e <namex>
}
    800041ac:	60e2                	ld	ra,24(sp)
    800041ae:	6442                	ld	s0,16(sp)
    800041b0:	6105                	addi	sp,sp,32
    800041b2:	8082                	ret

00000000800041b4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800041b4:	1141                	addi	sp,sp,-16
    800041b6:	e406                	sd	ra,8(sp)
    800041b8:	e022                	sd	s0,0(sp)
    800041ba:	0800                	addi	s0,sp,16
    800041bc:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800041be:	4585                	li	a1,1
    800041c0:	00000097          	auipc	ra,0x0
    800041c4:	dbe080e7          	jalr	-578(ra) # 80003f7e <namex>
}
    800041c8:	60a2                	ld	ra,8(sp)
    800041ca:	6402                	ld	s0,0(sp)
    800041cc:	0141                	addi	sp,sp,16
    800041ce:	8082                	ret

00000000800041d0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800041d0:	1101                	addi	sp,sp,-32
    800041d2:	ec06                	sd	ra,24(sp)
    800041d4:	e822                	sd	s0,16(sp)
    800041d6:	e426                	sd	s1,8(sp)
    800041d8:	e04a                	sd	s2,0(sp)
    800041da:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800041dc:	0001e917          	auipc	s2,0x1e
    800041e0:	d5490913          	addi	s2,s2,-684 # 80021f30 <log>
    800041e4:	01892583          	lw	a1,24(s2)
    800041e8:	02892503          	lw	a0,40(s2)
    800041ec:	fffff097          	auipc	ra,0xfffff
    800041f0:	fe6080e7          	jalr	-26(ra) # 800031d2 <bread>
    800041f4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800041f6:	02c92683          	lw	a3,44(s2)
    800041fa:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800041fc:	02d05863          	blez	a3,8000422c <write_head+0x5c>
    80004200:	0001e797          	auipc	a5,0x1e
    80004204:	d6078793          	addi	a5,a5,-672 # 80021f60 <log+0x30>
    80004208:	05c50713          	addi	a4,a0,92
    8000420c:	36fd                	addiw	a3,a3,-1
    8000420e:	02069613          	slli	a2,a3,0x20
    80004212:	01e65693          	srli	a3,a2,0x1e
    80004216:	0001e617          	auipc	a2,0x1e
    8000421a:	d4e60613          	addi	a2,a2,-690 # 80021f64 <log+0x34>
    8000421e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004220:	4390                	lw	a2,0(a5)
    80004222:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004224:	0791                	addi	a5,a5,4
    80004226:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004228:	fed79ce3          	bne	a5,a3,80004220 <write_head+0x50>
  }
  bwrite(buf);
    8000422c:	8526                	mv	a0,s1
    8000422e:	fffff097          	auipc	ra,0xfffff
    80004232:	096080e7          	jalr	150(ra) # 800032c4 <bwrite>
  brelse(buf);
    80004236:	8526                	mv	a0,s1
    80004238:	fffff097          	auipc	ra,0xfffff
    8000423c:	0ca080e7          	jalr	202(ra) # 80003302 <brelse>
}
    80004240:	60e2                	ld	ra,24(sp)
    80004242:	6442                	ld	s0,16(sp)
    80004244:	64a2                	ld	s1,8(sp)
    80004246:	6902                	ld	s2,0(sp)
    80004248:	6105                	addi	sp,sp,32
    8000424a:	8082                	ret

000000008000424c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000424c:	0001e797          	auipc	a5,0x1e
    80004250:	d107a783          	lw	a5,-752(a5) # 80021f5c <log+0x2c>
    80004254:	0af05d63          	blez	a5,8000430e <install_trans+0xc2>
{
    80004258:	7139                	addi	sp,sp,-64
    8000425a:	fc06                	sd	ra,56(sp)
    8000425c:	f822                	sd	s0,48(sp)
    8000425e:	f426                	sd	s1,40(sp)
    80004260:	f04a                	sd	s2,32(sp)
    80004262:	ec4e                	sd	s3,24(sp)
    80004264:	e852                	sd	s4,16(sp)
    80004266:	e456                	sd	s5,8(sp)
    80004268:	e05a                	sd	s6,0(sp)
    8000426a:	0080                	addi	s0,sp,64
    8000426c:	8b2a                	mv	s6,a0
    8000426e:	0001ea97          	auipc	s5,0x1e
    80004272:	cf2a8a93          	addi	s5,s5,-782 # 80021f60 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004276:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004278:	0001e997          	auipc	s3,0x1e
    8000427c:	cb898993          	addi	s3,s3,-840 # 80021f30 <log>
    80004280:	a00d                	j	800042a2 <install_trans+0x56>
    brelse(lbuf);
    80004282:	854a                	mv	a0,s2
    80004284:	fffff097          	auipc	ra,0xfffff
    80004288:	07e080e7          	jalr	126(ra) # 80003302 <brelse>
    brelse(dbuf);
    8000428c:	8526                	mv	a0,s1
    8000428e:	fffff097          	auipc	ra,0xfffff
    80004292:	074080e7          	jalr	116(ra) # 80003302 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004296:	2a05                	addiw	s4,s4,1
    80004298:	0a91                	addi	s5,s5,4
    8000429a:	02c9a783          	lw	a5,44(s3)
    8000429e:	04fa5e63          	bge	s4,a5,800042fa <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042a2:	0189a583          	lw	a1,24(s3)
    800042a6:	014585bb          	addw	a1,a1,s4
    800042aa:	2585                	addiw	a1,a1,1
    800042ac:	0289a503          	lw	a0,40(s3)
    800042b0:	fffff097          	auipc	ra,0xfffff
    800042b4:	f22080e7          	jalr	-222(ra) # 800031d2 <bread>
    800042b8:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800042ba:	000aa583          	lw	a1,0(s5)
    800042be:	0289a503          	lw	a0,40(s3)
    800042c2:	fffff097          	auipc	ra,0xfffff
    800042c6:	f10080e7          	jalr	-240(ra) # 800031d2 <bread>
    800042ca:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800042cc:	40000613          	li	a2,1024
    800042d0:	05890593          	addi	a1,s2,88
    800042d4:	05850513          	addi	a0,a0,88
    800042d8:	ffffd097          	auipc	ra,0xffffd
    800042dc:	a56080e7          	jalr	-1450(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    800042e0:	8526                	mv	a0,s1
    800042e2:	fffff097          	auipc	ra,0xfffff
    800042e6:	fe2080e7          	jalr	-30(ra) # 800032c4 <bwrite>
    if(recovering == 0)
    800042ea:	f80b1ce3          	bnez	s6,80004282 <install_trans+0x36>
      bunpin(dbuf);
    800042ee:	8526                	mv	a0,s1
    800042f0:	fffff097          	auipc	ra,0xfffff
    800042f4:	0ec080e7          	jalr	236(ra) # 800033dc <bunpin>
    800042f8:	b769                	j	80004282 <install_trans+0x36>
}
    800042fa:	70e2                	ld	ra,56(sp)
    800042fc:	7442                	ld	s0,48(sp)
    800042fe:	74a2                	ld	s1,40(sp)
    80004300:	7902                	ld	s2,32(sp)
    80004302:	69e2                	ld	s3,24(sp)
    80004304:	6a42                	ld	s4,16(sp)
    80004306:	6aa2                	ld	s5,8(sp)
    80004308:	6b02                	ld	s6,0(sp)
    8000430a:	6121                	addi	sp,sp,64
    8000430c:	8082                	ret
    8000430e:	8082                	ret

0000000080004310 <initlog>:
{
    80004310:	7179                	addi	sp,sp,-48
    80004312:	f406                	sd	ra,40(sp)
    80004314:	f022                	sd	s0,32(sp)
    80004316:	ec26                	sd	s1,24(sp)
    80004318:	e84a                	sd	s2,16(sp)
    8000431a:	e44e                	sd	s3,8(sp)
    8000431c:	1800                	addi	s0,sp,48
    8000431e:	892a                	mv	s2,a0
    80004320:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004322:	0001e497          	auipc	s1,0x1e
    80004326:	c0e48493          	addi	s1,s1,-1010 # 80021f30 <log>
    8000432a:	00004597          	auipc	a1,0x4
    8000432e:	41e58593          	addi	a1,a1,1054 # 80008748 <syscalls+0x208>
    80004332:	8526                	mv	a0,s1
    80004334:	ffffd097          	auipc	ra,0xffffd
    80004338:	812080e7          	jalr	-2030(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    8000433c:	0149a583          	lw	a1,20(s3)
    80004340:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004342:	0109a783          	lw	a5,16(s3)
    80004346:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004348:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000434c:	854a                	mv	a0,s2
    8000434e:	fffff097          	auipc	ra,0xfffff
    80004352:	e84080e7          	jalr	-380(ra) # 800031d2 <bread>
  log.lh.n = lh->n;
    80004356:	4d34                	lw	a3,88(a0)
    80004358:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000435a:	02d05663          	blez	a3,80004386 <initlog+0x76>
    8000435e:	05c50793          	addi	a5,a0,92
    80004362:	0001e717          	auipc	a4,0x1e
    80004366:	bfe70713          	addi	a4,a4,-1026 # 80021f60 <log+0x30>
    8000436a:	36fd                	addiw	a3,a3,-1
    8000436c:	02069613          	slli	a2,a3,0x20
    80004370:	01e65693          	srli	a3,a2,0x1e
    80004374:	06050613          	addi	a2,a0,96
    80004378:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000437a:	4390                	lw	a2,0(a5)
    8000437c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000437e:	0791                	addi	a5,a5,4
    80004380:	0711                	addi	a4,a4,4
    80004382:	fed79ce3          	bne	a5,a3,8000437a <initlog+0x6a>
  brelse(buf);
    80004386:	fffff097          	auipc	ra,0xfffff
    8000438a:	f7c080e7          	jalr	-132(ra) # 80003302 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000438e:	4505                	li	a0,1
    80004390:	00000097          	auipc	ra,0x0
    80004394:	ebc080e7          	jalr	-324(ra) # 8000424c <install_trans>
  log.lh.n = 0;
    80004398:	0001e797          	auipc	a5,0x1e
    8000439c:	bc07a223          	sw	zero,-1084(a5) # 80021f5c <log+0x2c>
  write_head(); // clear the log
    800043a0:	00000097          	auipc	ra,0x0
    800043a4:	e30080e7          	jalr	-464(ra) # 800041d0 <write_head>
}
    800043a8:	70a2                	ld	ra,40(sp)
    800043aa:	7402                	ld	s0,32(sp)
    800043ac:	64e2                	ld	s1,24(sp)
    800043ae:	6942                	ld	s2,16(sp)
    800043b0:	69a2                	ld	s3,8(sp)
    800043b2:	6145                	addi	sp,sp,48
    800043b4:	8082                	ret

00000000800043b6 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800043b6:	1101                	addi	sp,sp,-32
    800043b8:	ec06                	sd	ra,24(sp)
    800043ba:	e822                	sd	s0,16(sp)
    800043bc:	e426                	sd	s1,8(sp)
    800043be:	e04a                	sd	s2,0(sp)
    800043c0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800043c2:	0001e517          	auipc	a0,0x1e
    800043c6:	b6e50513          	addi	a0,a0,-1170 # 80021f30 <log>
    800043ca:	ffffd097          	auipc	ra,0xffffd
    800043ce:	80c080e7          	jalr	-2036(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    800043d2:	0001e497          	auipc	s1,0x1e
    800043d6:	b5e48493          	addi	s1,s1,-1186 # 80021f30 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043da:	4979                	li	s2,30
    800043dc:	a039                	j	800043ea <begin_op+0x34>
      sleep(&log, &log.lock);
    800043de:	85a6                	mv	a1,s1
    800043e0:	8526                	mv	a0,s1
    800043e2:	ffffe097          	auipc	ra,0xffffe
    800043e6:	dc2080e7          	jalr	-574(ra) # 800021a4 <sleep>
    if(log.committing){
    800043ea:	50dc                	lw	a5,36(s1)
    800043ec:	fbed                	bnez	a5,800043de <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043ee:	5098                	lw	a4,32(s1)
    800043f0:	2705                	addiw	a4,a4,1
    800043f2:	0007069b          	sext.w	a3,a4
    800043f6:	0027179b          	slliw	a5,a4,0x2
    800043fa:	9fb9                	addw	a5,a5,a4
    800043fc:	0017979b          	slliw	a5,a5,0x1
    80004400:	54d8                	lw	a4,44(s1)
    80004402:	9fb9                	addw	a5,a5,a4
    80004404:	00f95963          	bge	s2,a5,80004416 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004408:	85a6                	mv	a1,s1
    8000440a:	8526                	mv	a0,s1
    8000440c:	ffffe097          	auipc	ra,0xffffe
    80004410:	d98080e7          	jalr	-616(ra) # 800021a4 <sleep>
    80004414:	bfd9                	j	800043ea <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004416:	0001e517          	auipc	a0,0x1e
    8000441a:	b1a50513          	addi	a0,a0,-1254 # 80021f30 <log>
    8000441e:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004420:	ffffd097          	auipc	ra,0xffffd
    80004424:	86a080e7          	jalr	-1942(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004428:	60e2                	ld	ra,24(sp)
    8000442a:	6442                	ld	s0,16(sp)
    8000442c:	64a2                	ld	s1,8(sp)
    8000442e:	6902                	ld	s2,0(sp)
    80004430:	6105                	addi	sp,sp,32
    80004432:	8082                	ret

0000000080004434 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004434:	7139                	addi	sp,sp,-64
    80004436:	fc06                	sd	ra,56(sp)
    80004438:	f822                	sd	s0,48(sp)
    8000443a:	f426                	sd	s1,40(sp)
    8000443c:	f04a                	sd	s2,32(sp)
    8000443e:	ec4e                	sd	s3,24(sp)
    80004440:	e852                	sd	s4,16(sp)
    80004442:	e456                	sd	s5,8(sp)
    80004444:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004446:	0001e497          	auipc	s1,0x1e
    8000444a:	aea48493          	addi	s1,s1,-1302 # 80021f30 <log>
    8000444e:	8526                	mv	a0,s1
    80004450:	ffffc097          	auipc	ra,0xffffc
    80004454:	786080e7          	jalr	1926(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004458:	509c                	lw	a5,32(s1)
    8000445a:	37fd                	addiw	a5,a5,-1
    8000445c:	0007891b          	sext.w	s2,a5
    80004460:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004462:	50dc                	lw	a5,36(s1)
    80004464:	e7b9                	bnez	a5,800044b2 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004466:	04091e63          	bnez	s2,800044c2 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000446a:	0001e497          	auipc	s1,0x1e
    8000446e:	ac648493          	addi	s1,s1,-1338 # 80021f30 <log>
    80004472:	4785                	li	a5,1
    80004474:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004476:	8526                	mv	a0,s1
    80004478:	ffffd097          	auipc	ra,0xffffd
    8000447c:	812080e7          	jalr	-2030(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004480:	54dc                	lw	a5,44(s1)
    80004482:	06f04763          	bgtz	a5,800044f0 <end_op+0xbc>
    acquire(&log.lock);
    80004486:	0001e497          	auipc	s1,0x1e
    8000448a:	aaa48493          	addi	s1,s1,-1366 # 80021f30 <log>
    8000448e:	8526                	mv	a0,s1
    80004490:	ffffc097          	auipc	ra,0xffffc
    80004494:	746080e7          	jalr	1862(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004498:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000449c:	8526                	mv	a0,s1
    8000449e:	ffffe097          	auipc	ra,0xffffe
    800044a2:	d6a080e7          	jalr	-662(ra) # 80002208 <wakeup>
    release(&log.lock);
    800044a6:	8526                	mv	a0,s1
    800044a8:	ffffc097          	auipc	ra,0xffffc
    800044ac:	7e2080e7          	jalr	2018(ra) # 80000c8a <release>
}
    800044b0:	a03d                	j	800044de <end_op+0xaa>
    panic("log.committing");
    800044b2:	00004517          	auipc	a0,0x4
    800044b6:	29e50513          	addi	a0,a0,670 # 80008750 <syscalls+0x210>
    800044ba:	ffffc097          	auipc	ra,0xffffc
    800044be:	086080e7          	jalr	134(ra) # 80000540 <panic>
    wakeup(&log);
    800044c2:	0001e497          	auipc	s1,0x1e
    800044c6:	a6e48493          	addi	s1,s1,-1426 # 80021f30 <log>
    800044ca:	8526                	mv	a0,s1
    800044cc:	ffffe097          	auipc	ra,0xffffe
    800044d0:	d3c080e7          	jalr	-708(ra) # 80002208 <wakeup>
  release(&log.lock);
    800044d4:	8526                	mv	a0,s1
    800044d6:	ffffc097          	auipc	ra,0xffffc
    800044da:	7b4080e7          	jalr	1972(ra) # 80000c8a <release>
}
    800044de:	70e2                	ld	ra,56(sp)
    800044e0:	7442                	ld	s0,48(sp)
    800044e2:	74a2                	ld	s1,40(sp)
    800044e4:	7902                	ld	s2,32(sp)
    800044e6:	69e2                	ld	s3,24(sp)
    800044e8:	6a42                	ld	s4,16(sp)
    800044ea:	6aa2                	ld	s5,8(sp)
    800044ec:	6121                	addi	sp,sp,64
    800044ee:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800044f0:	0001ea97          	auipc	s5,0x1e
    800044f4:	a70a8a93          	addi	s5,s5,-1424 # 80021f60 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800044f8:	0001ea17          	auipc	s4,0x1e
    800044fc:	a38a0a13          	addi	s4,s4,-1480 # 80021f30 <log>
    80004500:	018a2583          	lw	a1,24(s4)
    80004504:	012585bb          	addw	a1,a1,s2
    80004508:	2585                	addiw	a1,a1,1
    8000450a:	028a2503          	lw	a0,40(s4)
    8000450e:	fffff097          	auipc	ra,0xfffff
    80004512:	cc4080e7          	jalr	-828(ra) # 800031d2 <bread>
    80004516:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004518:	000aa583          	lw	a1,0(s5)
    8000451c:	028a2503          	lw	a0,40(s4)
    80004520:	fffff097          	auipc	ra,0xfffff
    80004524:	cb2080e7          	jalr	-846(ra) # 800031d2 <bread>
    80004528:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000452a:	40000613          	li	a2,1024
    8000452e:	05850593          	addi	a1,a0,88
    80004532:	05848513          	addi	a0,s1,88
    80004536:	ffffc097          	auipc	ra,0xffffc
    8000453a:	7f8080e7          	jalr	2040(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    8000453e:	8526                	mv	a0,s1
    80004540:	fffff097          	auipc	ra,0xfffff
    80004544:	d84080e7          	jalr	-636(ra) # 800032c4 <bwrite>
    brelse(from);
    80004548:	854e                	mv	a0,s3
    8000454a:	fffff097          	auipc	ra,0xfffff
    8000454e:	db8080e7          	jalr	-584(ra) # 80003302 <brelse>
    brelse(to);
    80004552:	8526                	mv	a0,s1
    80004554:	fffff097          	auipc	ra,0xfffff
    80004558:	dae080e7          	jalr	-594(ra) # 80003302 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000455c:	2905                	addiw	s2,s2,1
    8000455e:	0a91                	addi	s5,s5,4
    80004560:	02ca2783          	lw	a5,44(s4)
    80004564:	f8f94ee3          	blt	s2,a5,80004500 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004568:	00000097          	auipc	ra,0x0
    8000456c:	c68080e7          	jalr	-920(ra) # 800041d0 <write_head>
    install_trans(0); // Now install writes to home locations
    80004570:	4501                	li	a0,0
    80004572:	00000097          	auipc	ra,0x0
    80004576:	cda080e7          	jalr	-806(ra) # 8000424c <install_trans>
    log.lh.n = 0;
    8000457a:	0001e797          	auipc	a5,0x1e
    8000457e:	9e07a123          	sw	zero,-1566(a5) # 80021f5c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004582:	00000097          	auipc	ra,0x0
    80004586:	c4e080e7          	jalr	-946(ra) # 800041d0 <write_head>
    8000458a:	bdf5                	j	80004486 <end_op+0x52>

000000008000458c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000458c:	1101                	addi	sp,sp,-32
    8000458e:	ec06                	sd	ra,24(sp)
    80004590:	e822                	sd	s0,16(sp)
    80004592:	e426                	sd	s1,8(sp)
    80004594:	e04a                	sd	s2,0(sp)
    80004596:	1000                	addi	s0,sp,32
    80004598:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000459a:	0001e917          	auipc	s2,0x1e
    8000459e:	99690913          	addi	s2,s2,-1642 # 80021f30 <log>
    800045a2:	854a                	mv	a0,s2
    800045a4:	ffffc097          	auipc	ra,0xffffc
    800045a8:	632080e7          	jalr	1586(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800045ac:	02c92603          	lw	a2,44(s2)
    800045b0:	47f5                	li	a5,29
    800045b2:	06c7c563          	blt	a5,a2,8000461c <log_write+0x90>
    800045b6:	0001e797          	auipc	a5,0x1e
    800045ba:	9967a783          	lw	a5,-1642(a5) # 80021f4c <log+0x1c>
    800045be:	37fd                	addiw	a5,a5,-1
    800045c0:	04f65e63          	bge	a2,a5,8000461c <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800045c4:	0001e797          	auipc	a5,0x1e
    800045c8:	98c7a783          	lw	a5,-1652(a5) # 80021f50 <log+0x20>
    800045cc:	06f05063          	blez	a5,8000462c <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800045d0:	4781                	li	a5,0
    800045d2:	06c05563          	blez	a2,8000463c <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800045d6:	44cc                	lw	a1,12(s1)
    800045d8:	0001e717          	auipc	a4,0x1e
    800045dc:	98870713          	addi	a4,a4,-1656 # 80021f60 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800045e0:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800045e2:	4314                	lw	a3,0(a4)
    800045e4:	04b68c63          	beq	a3,a1,8000463c <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800045e8:	2785                	addiw	a5,a5,1
    800045ea:	0711                	addi	a4,a4,4
    800045ec:	fef61be3          	bne	a2,a5,800045e2 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800045f0:	0621                	addi	a2,a2,8
    800045f2:	060a                	slli	a2,a2,0x2
    800045f4:	0001e797          	auipc	a5,0x1e
    800045f8:	93c78793          	addi	a5,a5,-1732 # 80021f30 <log>
    800045fc:	97b2                	add	a5,a5,a2
    800045fe:	44d8                	lw	a4,12(s1)
    80004600:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004602:	8526                	mv	a0,s1
    80004604:	fffff097          	auipc	ra,0xfffff
    80004608:	d9c080e7          	jalr	-612(ra) # 800033a0 <bpin>
    log.lh.n++;
    8000460c:	0001e717          	auipc	a4,0x1e
    80004610:	92470713          	addi	a4,a4,-1756 # 80021f30 <log>
    80004614:	575c                	lw	a5,44(a4)
    80004616:	2785                	addiw	a5,a5,1
    80004618:	d75c                	sw	a5,44(a4)
    8000461a:	a82d                	j	80004654 <log_write+0xc8>
    panic("too big a transaction");
    8000461c:	00004517          	auipc	a0,0x4
    80004620:	14450513          	addi	a0,a0,324 # 80008760 <syscalls+0x220>
    80004624:	ffffc097          	auipc	ra,0xffffc
    80004628:	f1c080e7          	jalr	-228(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    8000462c:	00004517          	auipc	a0,0x4
    80004630:	14c50513          	addi	a0,a0,332 # 80008778 <syscalls+0x238>
    80004634:	ffffc097          	auipc	ra,0xffffc
    80004638:	f0c080e7          	jalr	-244(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    8000463c:	00878693          	addi	a3,a5,8
    80004640:	068a                	slli	a3,a3,0x2
    80004642:	0001e717          	auipc	a4,0x1e
    80004646:	8ee70713          	addi	a4,a4,-1810 # 80021f30 <log>
    8000464a:	9736                	add	a4,a4,a3
    8000464c:	44d4                	lw	a3,12(s1)
    8000464e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004650:	faf609e3          	beq	a2,a5,80004602 <log_write+0x76>
  }
  release(&log.lock);
    80004654:	0001e517          	auipc	a0,0x1e
    80004658:	8dc50513          	addi	a0,a0,-1828 # 80021f30 <log>
    8000465c:	ffffc097          	auipc	ra,0xffffc
    80004660:	62e080e7          	jalr	1582(ra) # 80000c8a <release>
}
    80004664:	60e2                	ld	ra,24(sp)
    80004666:	6442                	ld	s0,16(sp)
    80004668:	64a2                	ld	s1,8(sp)
    8000466a:	6902                	ld	s2,0(sp)
    8000466c:	6105                	addi	sp,sp,32
    8000466e:	8082                	ret

0000000080004670 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004670:	1101                	addi	sp,sp,-32
    80004672:	ec06                	sd	ra,24(sp)
    80004674:	e822                	sd	s0,16(sp)
    80004676:	e426                	sd	s1,8(sp)
    80004678:	e04a                	sd	s2,0(sp)
    8000467a:	1000                	addi	s0,sp,32
    8000467c:	84aa                	mv	s1,a0
    8000467e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004680:	00004597          	auipc	a1,0x4
    80004684:	11858593          	addi	a1,a1,280 # 80008798 <syscalls+0x258>
    80004688:	0521                	addi	a0,a0,8
    8000468a:	ffffc097          	auipc	ra,0xffffc
    8000468e:	4bc080e7          	jalr	1212(ra) # 80000b46 <initlock>
  lk->name = name;
    80004692:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004696:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000469a:	0204a423          	sw	zero,40(s1)
}
    8000469e:	60e2                	ld	ra,24(sp)
    800046a0:	6442                	ld	s0,16(sp)
    800046a2:	64a2                	ld	s1,8(sp)
    800046a4:	6902                	ld	s2,0(sp)
    800046a6:	6105                	addi	sp,sp,32
    800046a8:	8082                	ret

00000000800046aa <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800046aa:	1101                	addi	sp,sp,-32
    800046ac:	ec06                	sd	ra,24(sp)
    800046ae:	e822                	sd	s0,16(sp)
    800046b0:	e426                	sd	s1,8(sp)
    800046b2:	e04a                	sd	s2,0(sp)
    800046b4:	1000                	addi	s0,sp,32
    800046b6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046b8:	00850913          	addi	s2,a0,8
    800046bc:	854a                	mv	a0,s2
    800046be:	ffffc097          	auipc	ra,0xffffc
    800046c2:	518080e7          	jalr	1304(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    800046c6:	409c                	lw	a5,0(s1)
    800046c8:	cb89                	beqz	a5,800046da <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800046ca:	85ca                	mv	a1,s2
    800046cc:	8526                	mv	a0,s1
    800046ce:	ffffe097          	auipc	ra,0xffffe
    800046d2:	ad6080e7          	jalr	-1322(ra) # 800021a4 <sleep>
  while (lk->locked) {
    800046d6:	409c                	lw	a5,0(s1)
    800046d8:	fbed                	bnez	a5,800046ca <acquiresleep+0x20>
  }
  lk->locked = 1;
    800046da:	4785                	li	a5,1
    800046dc:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800046de:	ffffd097          	auipc	ra,0xffffd
    800046e2:	2ce080e7          	jalr	718(ra) # 800019ac <myproc>
    800046e6:	591c                	lw	a5,48(a0)
    800046e8:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800046ea:	854a                	mv	a0,s2
    800046ec:	ffffc097          	auipc	ra,0xffffc
    800046f0:	59e080e7          	jalr	1438(ra) # 80000c8a <release>
}
    800046f4:	60e2                	ld	ra,24(sp)
    800046f6:	6442                	ld	s0,16(sp)
    800046f8:	64a2                	ld	s1,8(sp)
    800046fa:	6902                	ld	s2,0(sp)
    800046fc:	6105                	addi	sp,sp,32
    800046fe:	8082                	ret

0000000080004700 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004700:	1101                	addi	sp,sp,-32
    80004702:	ec06                	sd	ra,24(sp)
    80004704:	e822                	sd	s0,16(sp)
    80004706:	e426                	sd	s1,8(sp)
    80004708:	e04a                	sd	s2,0(sp)
    8000470a:	1000                	addi	s0,sp,32
    8000470c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000470e:	00850913          	addi	s2,a0,8
    80004712:	854a                	mv	a0,s2
    80004714:	ffffc097          	auipc	ra,0xffffc
    80004718:	4c2080e7          	jalr	1218(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    8000471c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004720:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004724:	8526                	mv	a0,s1
    80004726:	ffffe097          	auipc	ra,0xffffe
    8000472a:	ae2080e7          	jalr	-1310(ra) # 80002208 <wakeup>
  release(&lk->lk);
    8000472e:	854a                	mv	a0,s2
    80004730:	ffffc097          	auipc	ra,0xffffc
    80004734:	55a080e7          	jalr	1370(ra) # 80000c8a <release>
}
    80004738:	60e2                	ld	ra,24(sp)
    8000473a:	6442                	ld	s0,16(sp)
    8000473c:	64a2                	ld	s1,8(sp)
    8000473e:	6902                	ld	s2,0(sp)
    80004740:	6105                	addi	sp,sp,32
    80004742:	8082                	ret

0000000080004744 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004744:	7179                	addi	sp,sp,-48
    80004746:	f406                	sd	ra,40(sp)
    80004748:	f022                	sd	s0,32(sp)
    8000474a:	ec26                	sd	s1,24(sp)
    8000474c:	e84a                	sd	s2,16(sp)
    8000474e:	e44e                	sd	s3,8(sp)
    80004750:	1800                	addi	s0,sp,48
    80004752:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004754:	00850913          	addi	s2,a0,8
    80004758:	854a                	mv	a0,s2
    8000475a:	ffffc097          	auipc	ra,0xffffc
    8000475e:	47c080e7          	jalr	1148(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004762:	409c                	lw	a5,0(s1)
    80004764:	ef99                	bnez	a5,80004782 <holdingsleep+0x3e>
    80004766:	4481                	li	s1,0
  release(&lk->lk);
    80004768:	854a                	mv	a0,s2
    8000476a:	ffffc097          	auipc	ra,0xffffc
    8000476e:	520080e7          	jalr	1312(ra) # 80000c8a <release>
  return r;
}
    80004772:	8526                	mv	a0,s1
    80004774:	70a2                	ld	ra,40(sp)
    80004776:	7402                	ld	s0,32(sp)
    80004778:	64e2                	ld	s1,24(sp)
    8000477a:	6942                	ld	s2,16(sp)
    8000477c:	69a2                	ld	s3,8(sp)
    8000477e:	6145                	addi	sp,sp,48
    80004780:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004782:	0284a983          	lw	s3,40(s1)
    80004786:	ffffd097          	auipc	ra,0xffffd
    8000478a:	226080e7          	jalr	550(ra) # 800019ac <myproc>
    8000478e:	5904                	lw	s1,48(a0)
    80004790:	413484b3          	sub	s1,s1,s3
    80004794:	0014b493          	seqz	s1,s1
    80004798:	bfc1                	j	80004768 <holdingsleep+0x24>

000000008000479a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000479a:	1141                	addi	sp,sp,-16
    8000479c:	e406                	sd	ra,8(sp)
    8000479e:	e022                	sd	s0,0(sp)
    800047a0:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800047a2:	00004597          	auipc	a1,0x4
    800047a6:	00658593          	addi	a1,a1,6 # 800087a8 <syscalls+0x268>
    800047aa:	0001e517          	auipc	a0,0x1e
    800047ae:	8ce50513          	addi	a0,a0,-1842 # 80022078 <ftable>
    800047b2:	ffffc097          	auipc	ra,0xffffc
    800047b6:	394080e7          	jalr	916(ra) # 80000b46 <initlock>
}
    800047ba:	60a2                	ld	ra,8(sp)
    800047bc:	6402                	ld	s0,0(sp)
    800047be:	0141                	addi	sp,sp,16
    800047c0:	8082                	ret

00000000800047c2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800047c2:	1101                	addi	sp,sp,-32
    800047c4:	ec06                	sd	ra,24(sp)
    800047c6:	e822                	sd	s0,16(sp)
    800047c8:	e426                	sd	s1,8(sp)
    800047ca:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800047cc:	0001e517          	auipc	a0,0x1e
    800047d0:	8ac50513          	addi	a0,a0,-1876 # 80022078 <ftable>
    800047d4:	ffffc097          	auipc	ra,0xffffc
    800047d8:	402080e7          	jalr	1026(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047dc:	0001e497          	auipc	s1,0x1e
    800047e0:	8b448493          	addi	s1,s1,-1868 # 80022090 <ftable+0x18>
    800047e4:	0001f717          	auipc	a4,0x1f
    800047e8:	84c70713          	addi	a4,a4,-1972 # 80023030 <disk>
    if(f->ref == 0){
    800047ec:	40dc                	lw	a5,4(s1)
    800047ee:	cf99                	beqz	a5,8000480c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047f0:	02848493          	addi	s1,s1,40
    800047f4:	fee49ce3          	bne	s1,a4,800047ec <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800047f8:	0001e517          	auipc	a0,0x1e
    800047fc:	88050513          	addi	a0,a0,-1920 # 80022078 <ftable>
    80004800:	ffffc097          	auipc	ra,0xffffc
    80004804:	48a080e7          	jalr	1162(ra) # 80000c8a <release>
  return 0;
    80004808:	4481                	li	s1,0
    8000480a:	a819                	j	80004820 <filealloc+0x5e>
      f->ref = 1;
    8000480c:	4785                	li	a5,1
    8000480e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004810:	0001e517          	auipc	a0,0x1e
    80004814:	86850513          	addi	a0,a0,-1944 # 80022078 <ftable>
    80004818:	ffffc097          	auipc	ra,0xffffc
    8000481c:	472080e7          	jalr	1138(ra) # 80000c8a <release>
}
    80004820:	8526                	mv	a0,s1
    80004822:	60e2                	ld	ra,24(sp)
    80004824:	6442                	ld	s0,16(sp)
    80004826:	64a2                	ld	s1,8(sp)
    80004828:	6105                	addi	sp,sp,32
    8000482a:	8082                	ret

000000008000482c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000482c:	1101                	addi	sp,sp,-32
    8000482e:	ec06                	sd	ra,24(sp)
    80004830:	e822                	sd	s0,16(sp)
    80004832:	e426                	sd	s1,8(sp)
    80004834:	1000                	addi	s0,sp,32
    80004836:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004838:	0001e517          	auipc	a0,0x1e
    8000483c:	84050513          	addi	a0,a0,-1984 # 80022078 <ftable>
    80004840:	ffffc097          	auipc	ra,0xffffc
    80004844:	396080e7          	jalr	918(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004848:	40dc                	lw	a5,4(s1)
    8000484a:	02f05263          	blez	a5,8000486e <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000484e:	2785                	addiw	a5,a5,1
    80004850:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004852:	0001e517          	auipc	a0,0x1e
    80004856:	82650513          	addi	a0,a0,-2010 # 80022078 <ftable>
    8000485a:	ffffc097          	auipc	ra,0xffffc
    8000485e:	430080e7          	jalr	1072(ra) # 80000c8a <release>
  return f;
}
    80004862:	8526                	mv	a0,s1
    80004864:	60e2                	ld	ra,24(sp)
    80004866:	6442                	ld	s0,16(sp)
    80004868:	64a2                	ld	s1,8(sp)
    8000486a:	6105                	addi	sp,sp,32
    8000486c:	8082                	ret
    panic("filedup");
    8000486e:	00004517          	auipc	a0,0x4
    80004872:	f4250513          	addi	a0,a0,-190 # 800087b0 <syscalls+0x270>
    80004876:	ffffc097          	auipc	ra,0xffffc
    8000487a:	cca080e7          	jalr	-822(ra) # 80000540 <panic>

000000008000487e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000487e:	7139                	addi	sp,sp,-64
    80004880:	fc06                	sd	ra,56(sp)
    80004882:	f822                	sd	s0,48(sp)
    80004884:	f426                	sd	s1,40(sp)
    80004886:	f04a                	sd	s2,32(sp)
    80004888:	ec4e                	sd	s3,24(sp)
    8000488a:	e852                	sd	s4,16(sp)
    8000488c:	e456                	sd	s5,8(sp)
    8000488e:	0080                	addi	s0,sp,64
    80004890:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004892:	0001d517          	auipc	a0,0x1d
    80004896:	7e650513          	addi	a0,a0,2022 # 80022078 <ftable>
    8000489a:	ffffc097          	auipc	ra,0xffffc
    8000489e:	33c080e7          	jalr	828(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800048a2:	40dc                	lw	a5,4(s1)
    800048a4:	06f05163          	blez	a5,80004906 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800048a8:	37fd                	addiw	a5,a5,-1
    800048aa:	0007871b          	sext.w	a4,a5
    800048ae:	c0dc                	sw	a5,4(s1)
    800048b0:	06e04363          	bgtz	a4,80004916 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800048b4:	0004a903          	lw	s2,0(s1)
    800048b8:	0094ca83          	lbu	s5,9(s1)
    800048bc:	0104ba03          	ld	s4,16(s1)
    800048c0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800048c4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800048c8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800048cc:	0001d517          	auipc	a0,0x1d
    800048d0:	7ac50513          	addi	a0,a0,1964 # 80022078 <ftable>
    800048d4:	ffffc097          	auipc	ra,0xffffc
    800048d8:	3b6080e7          	jalr	950(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    800048dc:	4785                	li	a5,1
    800048de:	04f90d63          	beq	s2,a5,80004938 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800048e2:	3979                	addiw	s2,s2,-2
    800048e4:	4785                	li	a5,1
    800048e6:	0527e063          	bltu	a5,s2,80004926 <fileclose+0xa8>
    begin_op();
    800048ea:	00000097          	auipc	ra,0x0
    800048ee:	acc080e7          	jalr	-1332(ra) # 800043b6 <begin_op>
    iput(ff.ip);
    800048f2:	854e                	mv	a0,s3
    800048f4:	fffff097          	auipc	ra,0xfffff
    800048f8:	2b0080e7          	jalr	688(ra) # 80003ba4 <iput>
    end_op();
    800048fc:	00000097          	auipc	ra,0x0
    80004900:	b38080e7          	jalr	-1224(ra) # 80004434 <end_op>
    80004904:	a00d                	j	80004926 <fileclose+0xa8>
    panic("fileclose");
    80004906:	00004517          	auipc	a0,0x4
    8000490a:	eb250513          	addi	a0,a0,-334 # 800087b8 <syscalls+0x278>
    8000490e:	ffffc097          	auipc	ra,0xffffc
    80004912:	c32080e7          	jalr	-974(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004916:	0001d517          	auipc	a0,0x1d
    8000491a:	76250513          	addi	a0,a0,1890 # 80022078 <ftable>
    8000491e:	ffffc097          	auipc	ra,0xffffc
    80004922:	36c080e7          	jalr	876(ra) # 80000c8a <release>
  }
}
    80004926:	70e2                	ld	ra,56(sp)
    80004928:	7442                	ld	s0,48(sp)
    8000492a:	74a2                	ld	s1,40(sp)
    8000492c:	7902                	ld	s2,32(sp)
    8000492e:	69e2                	ld	s3,24(sp)
    80004930:	6a42                	ld	s4,16(sp)
    80004932:	6aa2                	ld	s5,8(sp)
    80004934:	6121                	addi	sp,sp,64
    80004936:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004938:	85d6                	mv	a1,s5
    8000493a:	8552                	mv	a0,s4
    8000493c:	00000097          	auipc	ra,0x0
    80004940:	34c080e7          	jalr	844(ra) # 80004c88 <pipeclose>
    80004944:	b7cd                	j	80004926 <fileclose+0xa8>

0000000080004946 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004946:	715d                	addi	sp,sp,-80
    80004948:	e486                	sd	ra,72(sp)
    8000494a:	e0a2                	sd	s0,64(sp)
    8000494c:	fc26                	sd	s1,56(sp)
    8000494e:	f84a                	sd	s2,48(sp)
    80004950:	f44e                	sd	s3,40(sp)
    80004952:	0880                	addi	s0,sp,80
    80004954:	84aa                	mv	s1,a0
    80004956:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004958:	ffffd097          	auipc	ra,0xffffd
    8000495c:	054080e7          	jalr	84(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004960:	409c                	lw	a5,0(s1)
    80004962:	37f9                	addiw	a5,a5,-2
    80004964:	4705                	li	a4,1
    80004966:	04f76763          	bltu	a4,a5,800049b4 <filestat+0x6e>
    8000496a:	892a                	mv	s2,a0
    ilock(f->ip);
    8000496c:	6c88                	ld	a0,24(s1)
    8000496e:	fffff097          	auipc	ra,0xfffff
    80004972:	07c080e7          	jalr	124(ra) # 800039ea <ilock>
    stati(f->ip, &st);
    80004976:	fb840593          	addi	a1,s0,-72
    8000497a:	6c88                	ld	a0,24(s1)
    8000497c:	fffff097          	auipc	ra,0xfffff
    80004980:	2f8080e7          	jalr	760(ra) # 80003c74 <stati>
    iunlock(f->ip);
    80004984:	6c88                	ld	a0,24(s1)
    80004986:	fffff097          	auipc	ra,0xfffff
    8000498a:	126080e7          	jalr	294(ra) # 80003aac <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000498e:	46e1                	li	a3,24
    80004990:	fb840613          	addi	a2,s0,-72
    80004994:	85ce                	mv	a1,s3
    80004996:	05093503          	ld	a0,80(s2)
    8000499a:	ffffd097          	auipc	ra,0xffffd
    8000499e:	cd2080e7          	jalr	-814(ra) # 8000166c <copyout>
    800049a2:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800049a6:	60a6                	ld	ra,72(sp)
    800049a8:	6406                	ld	s0,64(sp)
    800049aa:	74e2                	ld	s1,56(sp)
    800049ac:	7942                	ld	s2,48(sp)
    800049ae:	79a2                	ld	s3,40(sp)
    800049b0:	6161                	addi	sp,sp,80
    800049b2:	8082                	ret
  return -1;
    800049b4:	557d                	li	a0,-1
    800049b6:	bfc5                	j	800049a6 <filestat+0x60>

00000000800049b8 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800049b8:	7179                	addi	sp,sp,-48
    800049ba:	f406                	sd	ra,40(sp)
    800049bc:	f022                	sd	s0,32(sp)
    800049be:	ec26                	sd	s1,24(sp)
    800049c0:	e84a                	sd	s2,16(sp)
    800049c2:	e44e                	sd	s3,8(sp)
    800049c4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800049c6:	00854783          	lbu	a5,8(a0)
    800049ca:	c3d5                	beqz	a5,80004a6e <fileread+0xb6>
    800049cc:	84aa                	mv	s1,a0
    800049ce:	89ae                	mv	s3,a1
    800049d0:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800049d2:	411c                	lw	a5,0(a0)
    800049d4:	4705                	li	a4,1
    800049d6:	04e78963          	beq	a5,a4,80004a28 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049da:	470d                	li	a4,3
    800049dc:	04e78d63          	beq	a5,a4,80004a36 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800049e0:	4709                	li	a4,2
    800049e2:	06e79e63          	bne	a5,a4,80004a5e <fileread+0xa6>
    ilock(f->ip);
    800049e6:	6d08                	ld	a0,24(a0)
    800049e8:	fffff097          	auipc	ra,0xfffff
    800049ec:	002080e7          	jalr	2(ra) # 800039ea <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800049f0:	874a                	mv	a4,s2
    800049f2:	5094                	lw	a3,32(s1)
    800049f4:	864e                	mv	a2,s3
    800049f6:	4585                	li	a1,1
    800049f8:	6c88                	ld	a0,24(s1)
    800049fa:	fffff097          	auipc	ra,0xfffff
    800049fe:	2a4080e7          	jalr	676(ra) # 80003c9e <readi>
    80004a02:	892a                	mv	s2,a0
    80004a04:	00a05563          	blez	a0,80004a0e <fileread+0x56>
      f->off += r;
    80004a08:	509c                	lw	a5,32(s1)
    80004a0a:	9fa9                	addw	a5,a5,a0
    80004a0c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004a0e:	6c88                	ld	a0,24(s1)
    80004a10:	fffff097          	auipc	ra,0xfffff
    80004a14:	09c080e7          	jalr	156(ra) # 80003aac <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004a18:	854a                	mv	a0,s2
    80004a1a:	70a2                	ld	ra,40(sp)
    80004a1c:	7402                	ld	s0,32(sp)
    80004a1e:	64e2                	ld	s1,24(sp)
    80004a20:	6942                	ld	s2,16(sp)
    80004a22:	69a2                	ld	s3,8(sp)
    80004a24:	6145                	addi	sp,sp,48
    80004a26:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004a28:	6908                	ld	a0,16(a0)
    80004a2a:	00000097          	auipc	ra,0x0
    80004a2e:	3c6080e7          	jalr	966(ra) # 80004df0 <piperead>
    80004a32:	892a                	mv	s2,a0
    80004a34:	b7d5                	j	80004a18 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004a36:	02451783          	lh	a5,36(a0)
    80004a3a:	03079693          	slli	a3,a5,0x30
    80004a3e:	92c1                	srli	a3,a3,0x30
    80004a40:	4725                	li	a4,9
    80004a42:	02d76863          	bltu	a4,a3,80004a72 <fileread+0xba>
    80004a46:	0792                	slli	a5,a5,0x4
    80004a48:	0001d717          	auipc	a4,0x1d
    80004a4c:	59070713          	addi	a4,a4,1424 # 80021fd8 <devsw>
    80004a50:	97ba                	add	a5,a5,a4
    80004a52:	639c                	ld	a5,0(a5)
    80004a54:	c38d                	beqz	a5,80004a76 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004a56:	4505                	li	a0,1
    80004a58:	9782                	jalr	a5
    80004a5a:	892a                	mv	s2,a0
    80004a5c:	bf75                	j	80004a18 <fileread+0x60>
    panic("fileread");
    80004a5e:	00004517          	auipc	a0,0x4
    80004a62:	d6a50513          	addi	a0,a0,-662 # 800087c8 <syscalls+0x288>
    80004a66:	ffffc097          	auipc	ra,0xffffc
    80004a6a:	ada080e7          	jalr	-1318(ra) # 80000540 <panic>
    return -1;
    80004a6e:	597d                	li	s2,-1
    80004a70:	b765                	j	80004a18 <fileread+0x60>
      return -1;
    80004a72:	597d                	li	s2,-1
    80004a74:	b755                	j	80004a18 <fileread+0x60>
    80004a76:	597d                	li	s2,-1
    80004a78:	b745                	j	80004a18 <fileread+0x60>

0000000080004a7a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004a7a:	715d                	addi	sp,sp,-80
    80004a7c:	e486                	sd	ra,72(sp)
    80004a7e:	e0a2                	sd	s0,64(sp)
    80004a80:	fc26                	sd	s1,56(sp)
    80004a82:	f84a                	sd	s2,48(sp)
    80004a84:	f44e                	sd	s3,40(sp)
    80004a86:	f052                	sd	s4,32(sp)
    80004a88:	ec56                	sd	s5,24(sp)
    80004a8a:	e85a                	sd	s6,16(sp)
    80004a8c:	e45e                	sd	s7,8(sp)
    80004a8e:	e062                	sd	s8,0(sp)
    80004a90:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004a92:	00954783          	lbu	a5,9(a0)
    80004a96:	10078663          	beqz	a5,80004ba2 <filewrite+0x128>
    80004a9a:	892a                	mv	s2,a0
    80004a9c:	8b2e                	mv	s6,a1
    80004a9e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004aa0:	411c                	lw	a5,0(a0)
    80004aa2:	4705                	li	a4,1
    80004aa4:	02e78263          	beq	a5,a4,80004ac8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004aa8:	470d                	li	a4,3
    80004aaa:	02e78663          	beq	a5,a4,80004ad6 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004aae:	4709                	li	a4,2
    80004ab0:	0ee79163          	bne	a5,a4,80004b92 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004ab4:	0ac05d63          	blez	a2,80004b6e <filewrite+0xf4>
    int i = 0;
    80004ab8:	4981                	li	s3,0
    80004aba:	6b85                	lui	s7,0x1
    80004abc:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004ac0:	6c05                	lui	s8,0x1
    80004ac2:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004ac6:	a861                	j	80004b5e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004ac8:	6908                	ld	a0,16(a0)
    80004aca:	00000097          	auipc	ra,0x0
    80004ace:	22e080e7          	jalr	558(ra) # 80004cf8 <pipewrite>
    80004ad2:	8a2a                	mv	s4,a0
    80004ad4:	a045                	j	80004b74 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004ad6:	02451783          	lh	a5,36(a0)
    80004ada:	03079693          	slli	a3,a5,0x30
    80004ade:	92c1                	srli	a3,a3,0x30
    80004ae0:	4725                	li	a4,9
    80004ae2:	0cd76263          	bltu	a4,a3,80004ba6 <filewrite+0x12c>
    80004ae6:	0792                	slli	a5,a5,0x4
    80004ae8:	0001d717          	auipc	a4,0x1d
    80004aec:	4f070713          	addi	a4,a4,1264 # 80021fd8 <devsw>
    80004af0:	97ba                	add	a5,a5,a4
    80004af2:	679c                	ld	a5,8(a5)
    80004af4:	cbdd                	beqz	a5,80004baa <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004af6:	4505                	li	a0,1
    80004af8:	9782                	jalr	a5
    80004afa:	8a2a                	mv	s4,a0
    80004afc:	a8a5                	j	80004b74 <filewrite+0xfa>
    80004afe:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004b02:	00000097          	auipc	ra,0x0
    80004b06:	8b4080e7          	jalr	-1868(ra) # 800043b6 <begin_op>
      ilock(f->ip);
    80004b0a:	01893503          	ld	a0,24(s2)
    80004b0e:	fffff097          	auipc	ra,0xfffff
    80004b12:	edc080e7          	jalr	-292(ra) # 800039ea <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004b16:	8756                	mv	a4,s5
    80004b18:	02092683          	lw	a3,32(s2)
    80004b1c:	01698633          	add	a2,s3,s6
    80004b20:	4585                	li	a1,1
    80004b22:	01893503          	ld	a0,24(s2)
    80004b26:	fffff097          	auipc	ra,0xfffff
    80004b2a:	270080e7          	jalr	624(ra) # 80003d96 <writei>
    80004b2e:	84aa                	mv	s1,a0
    80004b30:	00a05763          	blez	a0,80004b3e <filewrite+0xc4>
        f->off += r;
    80004b34:	02092783          	lw	a5,32(s2)
    80004b38:	9fa9                	addw	a5,a5,a0
    80004b3a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004b3e:	01893503          	ld	a0,24(s2)
    80004b42:	fffff097          	auipc	ra,0xfffff
    80004b46:	f6a080e7          	jalr	-150(ra) # 80003aac <iunlock>
      end_op();
    80004b4a:	00000097          	auipc	ra,0x0
    80004b4e:	8ea080e7          	jalr	-1814(ra) # 80004434 <end_op>

      if(r != n1){
    80004b52:	009a9f63          	bne	s5,s1,80004b70 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004b56:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004b5a:	0149db63          	bge	s3,s4,80004b70 <filewrite+0xf6>
      int n1 = n - i;
    80004b5e:	413a04bb          	subw	s1,s4,s3
    80004b62:	0004879b          	sext.w	a5,s1
    80004b66:	f8fbdce3          	bge	s7,a5,80004afe <filewrite+0x84>
    80004b6a:	84e2                	mv	s1,s8
    80004b6c:	bf49                	j	80004afe <filewrite+0x84>
    int i = 0;
    80004b6e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004b70:	013a1f63          	bne	s4,s3,80004b8e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b74:	8552                	mv	a0,s4
    80004b76:	60a6                	ld	ra,72(sp)
    80004b78:	6406                	ld	s0,64(sp)
    80004b7a:	74e2                	ld	s1,56(sp)
    80004b7c:	7942                	ld	s2,48(sp)
    80004b7e:	79a2                	ld	s3,40(sp)
    80004b80:	7a02                	ld	s4,32(sp)
    80004b82:	6ae2                	ld	s5,24(sp)
    80004b84:	6b42                	ld	s6,16(sp)
    80004b86:	6ba2                	ld	s7,8(sp)
    80004b88:	6c02                	ld	s8,0(sp)
    80004b8a:	6161                	addi	sp,sp,80
    80004b8c:	8082                	ret
    ret = (i == n ? n : -1);
    80004b8e:	5a7d                	li	s4,-1
    80004b90:	b7d5                	j	80004b74 <filewrite+0xfa>
    panic("filewrite");
    80004b92:	00004517          	auipc	a0,0x4
    80004b96:	c4650513          	addi	a0,a0,-954 # 800087d8 <syscalls+0x298>
    80004b9a:	ffffc097          	auipc	ra,0xffffc
    80004b9e:	9a6080e7          	jalr	-1626(ra) # 80000540 <panic>
    return -1;
    80004ba2:	5a7d                	li	s4,-1
    80004ba4:	bfc1                	j	80004b74 <filewrite+0xfa>
      return -1;
    80004ba6:	5a7d                	li	s4,-1
    80004ba8:	b7f1                	j	80004b74 <filewrite+0xfa>
    80004baa:	5a7d                	li	s4,-1
    80004bac:	b7e1                	j	80004b74 <filewrite+0xfa>

0000000080004bae <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004bae:	7179                	addi	sp,sp,-48
    80004bb0:	f406                	sd	ra,40(sp)
    80004bb2:	f022                	sd	s0,32(sp)
    80004bb4:	ec26                	sd	s1,24(sp)
    80004bb6:	e84a                	sd	s2,16(sp)
    80004bb8:	e44e                	sd	s3,8(sp)
    80004bba:	e052                	sd	s4,0(sp)
    80004bbc:	1800                	addi	s0,sp,48
    80004bbe:	84aa                	mv	s1,a0
    80004bc0:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004bc2:	0005b023          	sd	zero,0(a1)
    80004bc6:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004bca:	00000097          	auipc	ra,0x0
    80004bce:	bf8080e7          	jalr	-1032(ra) # 800047c2 <filealloc>
    80004bd2:	e088                	sd	a0,0(s1)
    80004bd4:	c551                	beqz	a0,80004c60 <pipealloc+0xb2>
    80004bd6:	00000097          	auipc	ra,0x0
    80004bda:	bec080e7          	jalr	-1044(ra) # 800047c2 <filealloc>
    80004bde:	00aa3023          	sd	a0,0(s4)
    80004be2:	c92d                	beqz	a0,80004c54 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004be4:	ffffc097          	auipc	ra,0xffffc
    80004be8:	f02080e7          	jalr	-254(ra) # 80000ae6 <kalloc>
    80004bec:	892a                	mv	s2,a0
    80004bee:	c125                	beqz	a0,80004c4e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004bf0:	4985                	li	s3,1
    80004bf2:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004bf6:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004bfa:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004bfe:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004c02:	00004597          	auipc	a1,0x4
    80004c06:	86658593          	addi	a1,a1,-1946 # 80008468 <states.0+0x1a0>
    80004c0a:	ffffc097          	auipc	ra,0xffffc
    80004c0e:	f3c080e7          	jalr	-196(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004c12:	609c                	ld	a5,0(s1)
    80004c14:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004c18:	609c                	ld	a5,0(s1)
    80004c1a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004c1e:	609c                	ld	a5,0(s1)
    80004c20:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c24:	609c                	ld	a5,0(s1)
    80004c26:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004c2a:	000a3783          	ld	a5,0(s4)
    80004c2e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004c32:	000a3783          	ld	a5,0(s4)
    80004c36:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c3a:	000a3783          	ld	a5,0(s4)
    80004c3e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c42:	000a3783          	ld	a5,0(s4)
    80004c46:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c4a:	4501                	li	a0,0
    80004c4c:	a025                	j	80004c74 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c4e:	6088                	ld	a0,0(s1)
    80004c50:	e501                	bnez	a0,80004c58 <pipealloc+0xaa>
    80004c52:	a039                	j	80004c60 <pipealloc+0xb2>
    80004c54:	6088                	ld	a0,0(s1)
    80004c56:	c51d                	beqz	a0,80004c84 <pipealloc+0xd6>
    fileclose(*f0);
    80004c58:	00000097          	auipc	ra,0x0
    80004c5c:	c26080e7          	jalr	-986(ra) # 8000487e <fileclose>
  if(*f1)
    80004c60:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c64:	557d                	li	a0,-1
  if(*f1)
    80004c66:	c799                	beqz	a5,80004c74 <pipealloc+0xc6>
    fileclose(*f1);
    80004c68:	853e                	mv	a0,a5
    80004c6a:	00000097          	auipc	ra,0x0
    80004c6e:	c14080e7          	jalr	-1004(ra) # 8000487e <fileclose>
  return -1;
    80004c72:	557d                	li	a0,-1
}
    80004c74:	70a2                	ld	ra,40(sp)
    80004c76:	7402                	ld	s0,32(sp)
    80004c78:	64e2                	ld	s1,24(sp)
    80004c7a:	6942                	ld	s2,16(sp)
    80004c7c:	69a2                	ld	s3,8(sp)
    80004c7e:	6a02                	ld	s4,0(sp)
    80004c80:	6145                	addi	sp,sp,48
    80004c82:	8082                	ret
  return -1;
    80004c84:	557d                	li	a0,-1
    80004c86:	b7fd                	j	80004c74 <pipealloc+0xc6>

0000000080004c88 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c88:	1101                	addi	sp,sp,-32
    80004c8a:	ec06                	sd	ra,24(sp)
    80004c8c:	e822                	sd	s0,16(sp)
    80004c8e:	e426                	sd	s1,8(sp)
    80004c90:	e04a                	sd	s2,0(sp)
    80004c92:	1000                	addi	s0,sp,32
    80004c94:	84aa                	mv	s1,a0
    80004c96:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c98:	ffffc097          	auipc	ra,0xffffc
    80004c9c:	f3e080e7          	jalr	-194(ra) # 80000bd6 <acquire>
  if(writable){
    80004ca0:	02090d63          	beqz	s2,80004cda <pipeclose+0x52>
    pi->writeopen = 0;
    80004ca4:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ca8:	21848513          	addi	a0,s1,536
    80004cac:	ffffd097          	auipc	ra,0xffffd
    80004cb0:	55c080e7          	jalr	1372(ra) # 80002208 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004cb4:	2204b783          	ld	a5,544(s1)
    80004cb8:	eb95                	bnez	a5,80004cec <pipeclose+0x64>
    release(&pi->lock);
    80004cba:	8526                	mv	a0,s1
    80004cbc:	ffffc097          	auipc	ra,0xffffc
    80004cc0:	fce080e7          	jalr	-50(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004cc4:	8526                	mv	a0,s1
    80004cc6:	ffffc097          	auipc	ra,0xffffc
    80004cca:	d22080e7          	jalr	-734(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004cce:	60e2                	ld	ra,24(sp)
    80004cd0:	6442                	ld	s0,16(sp)
    80004cd2:	64a2                	ld	s1,8(sp)
    80004cd4:	6902                	ld	s2,0(sp)
    80004cd6:	6105                	addi	sp,sp,32
    80004cd8:	8082                	ret
    pi->readopen = 0;
    80004cda:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004cde:	21c48513          	addi	a0,s1,540
    80004ce2:	ffffd097          	auipc	ra,0xffffd
    80004ce6:	526080e7          	jalr	1318(ra) # 80002208 <wakeup>
    80004cea:	b7e9                	j	80004cb4 <pipeclose+0x2c>
    release(&pi->lock);
    80004cec:	8526                	mv	a0,s1
    80004cee:	ffffc097          	auipc	ra,0xffffc
    80004cf2:	f9c080e7          	jalr	-100(ra) # 80000c8a <release>
}
    80004cf6:	bfe1                	j	80004cce <pipeclose+0x46>

0000000080004cf8 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004cf8:	711d                	addi	sp,sp,-96
    80004cfa:	ec86                	sd	ra,88(sp)
    80004cfc:	e8a2                	sd	s0,80(sp)
    80004cfe:	e4a6                	sd	s1,72(sp)
    80004d00:	e0ca                	sd	s2,64(sp)
    80004d02:	fc4e                	sd	s3,56(sp)
    80004d04:	f852                	sd	s4,48(sp)
    80004d06:	f456                	sd	s5,40(sp)
    80004d08:	f05a                	sd	s6,32(sp)
    80004d0a:	ec5e                	sd	s7,24(sp)
    80004d0c:	e862                	sd	s8,16(sp)
    80004d0e:	1080                	addi	s0,sp,96
    80004d10:	84aa                	mv	s1,a0
    80004d12:	8aae                	mv	s5,a1
    80004d14:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004d16:	ffffd097          	auipc	ra,0xffffd
    80004d1a:	c96080e7          	jalr	-874(ra) # 800019ac <myproc>
    80004d1e:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004d20:	8526                	mv	a0,s1
    80004d22:	ffffc097          	auipc	ra,0xffffc
    80004d26:	eb4080e7          	jalr	-332(ra) # 80000bd6 <acquire>
  while(i < n){
    80004d2a:	0b405663          	blez	s4,80004dd6 <pipewrite+0xde>
  int i = 0;
    80004d2e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d30:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004d32:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d36:	21c48b93          	addi	s7,s1,540
    80004d3a:	a089                	j	80004d7c <pipewrite+0x84>
      release(&pi->lock);
    80004d3c:	8526                	mv	a0,s1
    80004d3e:	ffffc097          	auipc	ra,0xffffc
    80004d42:	f4c080e7          	jalr	-180(ra) # 80000c8a <release>
      return -1;
    80004d46:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004d48:	854a                	mv	a0,s2
    80004d4a:	60e6                	ld	ra,88(sp)
    80004d4c:	6446                	ld	s0,80(sp)
    80004d4e:	64a6                	ld	s1,72(sp)
    80004d50:	6906                	ld	s2,64(sp)
    80004d52:	79e2                	ld	s3,56(sp)
    80004d54:	7a42                	ld	s4,48(sp)
    80004d56:	7aa2                	ld	s5,40(sp)
    80004d58:	7b02                	ld	s6,32(sp)
    80004d5a:	6be2                	ld	s7,24(sp)
    80004d5c:	6c42                	ld	s8,16(sp)
    80004d5e:	6125                	addi	sp,sp,96
    80004d60:	8082                	ret
      wakeup(&pi->nread);
    80004d62:	8562                	mv	a0,s8
    80004d64:	ffffd097          	auipc	ra,0xffffd
    80004d68:	4a4080e7          	jalr	1188(ra) # 80002208 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d6c:	85a6                	mv	a1,s1
    80004d6e:	855e                	mv	a0,s7
    80004d70:	ffffd097          	auipc	ra,0xffffd
    80004d74:	434080e7          	jalr	1076(ra) # 800021a4 <sleep>
  while(i < n){
    80004d78:	07495063          	bge	s2,s4,80004dd8 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004d7c:	2204a783          	lw	a5,544(s1)
    80004d80:	dfd5                	beqz	a5,80004d3c <pipewrite+0x44>
    80004d82:	854e                	mv	a0,s3
    80004d84:	ffffd097          	auipc	ra,0xffffd
    80004d88:	6c8080e7          	jalr	1736(ra) # 8000244c <killed>
    80004d8c:	f945                	bnez	a0,80004d3c <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004d8e:	2184a783          	lw	a5,536(s1)
    80004d92:	21c4a703          	lw	a4,540(s1)
    80004d96:	2007879b          	addiw	a5,a5,512
    80004d9a:	fcf704e3          	beq	a4,a5,80004d62 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d9e:	4685                	li	a3,1
    80004da0:	01590633          	add	a2,s2,s5
    80004da4:	faf40593          	addi	a1,s0,-81
    80004da8:	0509b503          	ld	a0,80(s3)
    80004dac:	ffffd097          	auipc	ra,0xffffd
    80004db0:	94c080e7          	jalr	-1716(ra) # 800016f8 <copyin>
    80004db4:	03650263          	beq	a0,s6,80004dd8 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004db8:	21c4a783          	lw	a5,540(s1)
    80004dbc:	0017871b          	addiw	a4,a5,1
    80004dc0:	20e4ae23          	sw	a4,540(s1)
    80004dc4:	1ff7f793          	andi	a5,a5,511
    80004dc8:	97a6                	add	a5,a5,s1
    80004dca:	faf44703          	lbu	a4,-81(s0)
    80004dce:	00e78c23          	sb	a4,24(a5)
      i++;
    80004dd2:	2905                	addiw	s2,s2,1
    80004dd4:	b755                	j	80004d78 <pipewrite+0x80>
  int i = 0;
    80004dd6:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004dd8:	21848513          	addi	a0,s1,536
    80004ddc:	ffffd097          	auipc	ra,0xffffd
    80004de0:	42c080e7          	jalr	1068(ra) # 80002208 <wakeup>
  release(&pi->lock);
    80004de4:	8526                	mv	a0,s1
    80004de6:	ffffc097          	auipc	ra,0xffffc
    80004dea:	ea4080e7          	jalr	-348(ra) # 80000c8a <release>
  return i;
    80004dee:	bfa9                	j	80004d48 <pipewrite+0x50>

0000000080004df0 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004df0:	715d                	addi	sp,sp,-80
    80004df2:	e486                	sd	ra,72(sp)
    80004df4:	e0a2                	sd	s0,64(sp)
    80004df6:	fc26                	sd	s1,56(sp)
    80004df8:	f84a                	sd	s2,48(sp)
    80004dfa:	f44e                	sd	s3,40(sp)
    80004dfc:	f052                	sd	s4,32(sp)
    80004dfe:	ec56                	sd	s5,24(sp)
    80004e00:	e85a                	sd	s6,16(sp)
    80004e02:	0880                	addi	s0,sp,80
    80004e04:	84aa                	mv	s1,a0
    80004e06:	892e                	mv	s2,a1
    80004e08:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004e0a:	ffffd097          	auipc	ra,0xffffd
    80004e0e:	ba2080e7          	jalr	-1118(ra) # 800019ac <myproc>
    80004e12:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e14:	8526                	mv	a0,s1
    80004e16:	ffffc097          	auipc	ra,0xffffc
    80004e1a:	dc0080e7          	jalr	-576(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e1e:	2184a703          	lw	a4,536(s1)
    80004e22:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e26:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e2a:	02f71763          	bne	a4,a5,80004e58 <piperead+0x68>
    80004e2e:	2244a783          	lw	a5,548(s1)
    80004e32:	c39d                	beqz	a5,80004e58 <piperead+0x68>
    if(killed(pr)){
    80004e34:	8552                	mv	a0,s4
    80004e36:	ffffd097          	auipc	ra,0xffffd
    80004e3a:	616080e7          	jalr	1558(ra) # 8000244c <killed>
    80004e3e:	e949                	bnez	a0,80004ed0 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e40:	85a6                	mv	a1,s1
    80004e42:	854e                	mv	a0,s3
    80004e44:	ffffd097          	auipc	ra,0xffffd
    80004e48:	360080e7          	jalr	864(ra) # 800021a4 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e4c:	2184a703          	lw	a4,536(s1)
    80004e50:	21c4a783          	lw	a5,540(s1)
    80004e54:	fcf70de3          	beq	a4,a5,80004e2e <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e58:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e5a:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e5c:	05505463          	blez	s5,80004ea4 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004e60:	2184a783          	lw	a5,536(s1)
    80004e64:	21c4a703          	lw	a4,540(s1)
    80004e68:	02f70e63          	beq	a4,a5,80004ea4 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e6c:	0017871b          	addiw	a4,a5,1
    80004e70:	20e4ac23          	sw	a4,536(s1)
    80004e74:	1ff7f793          	andi	a5,a5,511
    80004e78:	97a6                	add	a5,a5,s1
    80004e7a:	0187c783          	lbu	a5,24(a5)
    80004e7e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e82:	4685                	li	a3,1
    80004e84:	fbf40613          	addi	a2,s0,-65
    80004e88:	85ca                	mv	a1,s2
    80004e8a:	050a3503          	ld	a0,80(s4)
    80004e8e:	ffffc097          	auipc	ra,0xffffc
    80004e92:	7de080e7          	jalr	2014(ra) # 8000166c <copyout>
    80004e96:	01650763          	beq	a0,s6,80004ea4 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e9a:	2985                	addiw	s3,s3,1
    80004e9c:	0905                	addi	s2,s2,1
    80004e9e:	fd3a91e3          	bne	s5,s3,80004e60 <piperead+0x70>
    80004ea2:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004ea4:	21c48513          	addi	a0,s1,540
    80004ea8:	ffffd097          	auipc	ra,0xffffd
    80004eac:	360080e7          	jalr	864(ra) # 80002208 <wakeup>
  release(&pi->lock);
    80004eb0:	8526                	mv	a0,s1
    80004eb2:	ffffc097          	auipc	ra,0xffffc
    80004eb6:	dd8080e7          	jalr	-552(ra) # 80000c8a <release>
  return i;
}
    80004eba:	854e                	mv	a0,s3
    80004ebc:	60a6                	ld	ra,72(sp)
    80004ebe:	6406                	ld	s0,64(sp)
    80004ec0:	74e2                	ld	s1,56(sp)
    80004ec2:	7942                	ld	s2,48(sp)
    80004ec4:	79a2                	ld	s3,40(sp)
    80004ec6:	7a02                	ld	s4,32(sp)
    80004ec8:	6ae2                	ld	s5,24(sp)
    80004eca:	6b42                	ld	s6,16(sp)
    80004ecc:	6161                	addi	sp,sp,80
    80004ece:	8082                	ret
      release(&pi->lock);
    80004ed0:	8526                	mv	a0,s1
    80004ed2:	ffffc097          	auipc	ra,0xffffc
    80004ed6:	db8080e7          	jalr	-584(ra) # 80000c8a <release>
      return -1;
    80004eda:	59fd                	li	s3,-1
    80004edc:	bff9                	j	80004eba <piperead+0xca>

0000000080004ede <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004ede:	1141                	addi	sp,sp,-16
    80004ee0:	e422                	sd	s0,8(sp)
    80004ee2:	0800                	addi	s0,sp,16
    80004ee4:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004ee6:	8905                	andi	a0,a0,1
    80004ee8:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004eea:	8b89                	andi	a5,a5,2
    80004eec:	c399                	beqz	a5,80004ef2 <flags2perm+0x14>
      perm |= PTE_W;
    80004eee:	00456513          	ori	a0,a0,4
    return perm;
}
    80004ef2:	6422                	ld	s0,8(sp)
    80004ef4:	0141                	addi	sp,sp,16
    80004ef6:	8082                	ret

0000000080004ef8 <exec>:

int
exec(char *path, char **argv)
{
    80004ef8:	de010113          	addi	sp,sp,-544
    80004efc:	20113c23          	sd	ra,536(sp)
    80004f00:	20813823          	sd	s0,528(sp)
    80004f04:	20913423          	sd	s1,520(sp)
    80004f08:	21213023          	sd	s2,512(sp)
    80004f0c:	ffce                	sd	s3,504(sp)
    80004f0e:	fbd2                	sd	s4,496(sp)
    80004f10:	f7d6                	sd	s5,488(sp)
    80004f12:	f3da                	sd	s6,480(sp)
    80004f14:	efde                	sd	s7,472(sp)
    80004f16:	ebe2                	sd	s8,464(sp)
    80004f18:	e7e6                	sd	s9,456(sp)
    80004f1a:	e3ea                	sd	s10,448(sp)
    80004f1c:	ff6e                	sd	s11,440(sp)
    80004f1e:	1400                	addi	s0,sp,544
    80004f20:	892a                	mv	s2,a0
    80004f22:	dea43423          	sd	a0,-536(s0)
    80004f26:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004f2a:	ffffd097          	auipc	ra,0xffffd
    80004f2e:	a82080e7          	jalr	-1406(ra) # 800019ac <myproc>
    80004f32:	84aa                	mv	s1,a0

  begin_op();
    80004f34:	fffff097          	auipc	ra,0xfffff
    80004f38:	482080e7          	jalr	1154(ra) # 800043b6 <begin_op>

  if((ip = namei(path)) == 0){
    80004f3c:	854a                	mv	a0,s2
    80004f3e:	fffff097          	auipc	ra,0xfffff
    80004f42:	258080e7          	jalr	600(ra) # 80004196 <namei>
    80004f46:	c93d                	beqz	a0,80004fbc <exec+0xc4>
    80004f48:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f4a:	fffff097          	auipc	ra,0xfffff
    80004f4e:	aa0080e7          	jalr	-1376(ra) # 800039ea <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004f52:	04000713          	li	a4,64
    80004f56:	4681                	li	a3,0
    80004f58:	e5040613          	addi	a2,s0,-432
    80004f5c:	4581                	li	a1,0
    80004f5e:	8556                	mv	a0,s5
    80004f60:	fffff097          	auipc	ra,0xfffff
    80004f64:	d3e080e7          	jalr	-706(ra) # 80003c9e <readi>
    80004f68:	04000793          	li	a5,64
    80004f6c:	00f51a63          	bne	a0,a5,80004f80 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004f70:	e5042703          	lw	a4,-432(s0)
    80004f74:	464c47b7          	lui	a5,0x464c4
    80004f78:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f7c:	04f70663          	beq	a4,a5,80004fc8 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f80:	8556                	mv	a0,s5
    80004f82:	fffff097          	auipc	ra,0xfffff
    80004f86:	cca080e7          	jalr	-822(ra) # 80003c4c <iunlockput>
    end_op();
    80004f8a:	fffff097          	auipc	ra,0xfffff
    80004f8e:	4aa080e7          	jalr	1194(ra) # 80004434 <end_op>
  }
  return -1;
    80004f92:	557d                	li	a0,-1
}
    80004f94:	21813083          	ld	ra,536(sp)
    80004f98:	21013403          	ld	s0,528(sp)
    80004f9c:	20813483          	ld	s1,520(sp)
    80004fa0:	20013903          	ld	s2,512(sp)
    80004fa4:	79fe                	ld	s3,504(sp)
    80004fa6:	7a5e                	ld	s4,496(sp)
    80004fa8:	7abe                	ld	s5,488(sp)
    80004faa:	7b1e                	ld	s6,480(sp)
    80004fac:	6bfe                	ld	s7,472(sp)
    80004fae:	6c5e                	ld	s8,464(sp)
    80004fb0:	6cbe                	ld	s9,456(sp)
    80004fb2:	6d1e                	ld	s10,448(sp)
    80004fb4:	7dfa                	ld	s11,440(sp)
    80004fb6:	22010113          	addi	sp,sp,544
    80004fba:	8082                	ret
    end_op();
    80004fbc:	fffff097          	auipc	ra,0xfffff
    80004fc0:	478080e7          	jalr	1144(ra) # 80004434 <end_op>
    return -1;
    80004fc4:	557d                	li	a0,-1
    80004fc6:	b7f9                	j	80004f94 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004fc8:	8526                	mv	a0,s1
    80004fca:	ffffd097          	auipc	ra,0xffffd
    80004fce:	aa6080e7          	jalr	-1370(ra) # 80001a70 <proc_pagetable>
    80004fd2:	8b2a                	mv	s6,a0
    80004fd4:	d555                	beqz	a0,80004f80 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fd6:	e7042783          	lw	a5,-400(s0)
    80004fda:	e8845703          	lhu	a4,-376(s0)
    80004fde:	c735                	beqz	a4,8000504a <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004fe0:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fe2:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004fe6:	6a05                	lui	s4,0x1
    80004fe8:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004fec:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004ff0:	6d85                	lui	s11,0x1
    80004ff2:	7d7d                	lui	s10,0xfffff
    80004ff4:	ac3d                	j	80005232 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004ff6:	00003517          	auipc	a0,0x3
    80004ffa:	7f250513          	addi	a0,a0,2034 # 800087e8 <syscalls+0x2a8>
    80004ffe:	ffffb097          	auipc	ra,0xffffb
    80005002:	542080e7          	jalr	1346(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005006:	874a                	mv	a4,s2
    80005008:	009c86bb          	addw	a3,s9,s1
    8000500c:	4581                	li	a1,0
    8000500e:	8556                	mv	a0,s5
    80005010:	fffff097          	auipc	ra,0xfffff
    80005014:	c8e080e7          	jalr	-882(ra) # 80003c9e <readi>
    80005018:	2501                	sext.w	a0,a0
    8000501a:	1aa91963          	bne	s2,a0,800051cc <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    8000501e:	009d84bb          	addw	s1,s11,s1
    80005022:	013d09bb          	addw	s3,s10,s3
    80005026:	1f74f663          	bgeu	s1,s7,80005212 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    8000502a:	02049593          	slli	a1,s1,0x20
    8000502e:	9181                	srli	a1,a1,0x20
    80005030:	95e2                	add	a1,a1,s8
    80005032:	855a                	mv	a0,s6
    80005034:	ffffc097          	auipc	ra,0xffffc
    80005038:	028080e7          	jalr	40(ra) # 8000105c <walkaddr>
    8000503c:	862a                	mv	a2,a0
    if(pa == 0)
    8000503e:	dd45                	beqz	a0,80004ff6 <exec+0xfe>
      n = PGSIZE;
    80005040:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005042:	fd49f2e3          	bgeu	s3,s4,80005006 <exec+0x10e>
      n = sz - i;
    80005046:	894e                	mv	s2,s3
    80005048:	bf7d                	j	80005006 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000504a:	4901                	li	s2,0
  iunlockput(ip);
    8000504c:	8556                	mv	a0,s5
    8000504e:	fffff097          	auipc	ra,0xfffff
    80005052:	bfe080e7          	jalr	-1026(ra) # 80003c4c <iunlockput>
  end_op();
    80005056:	fffff097          	auipc	ra,0xfffff
    8000505a:	3de080e7          	jalr	990(ra) # 80004434 <end_op>
  p = myproc();
    8000505e:	ffffd097          	auipc	ra,0xffffd
    80005062:	94e080e7          	jalr	-1714(ra) # 800019ac <myproc>
    80005066:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005068:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000506c:	6785                	lui	a5,0x1
    8000506e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80005070:	97ca                	add	a5,a5,s2
    80005072:	777d                	lui	a4,0xfffff
    80005074:	8ff9                	and	a5,a5,a4
    80005076:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000507a:	4691                	li	a3,4
    8000507c:	6609                	lui	a2,0x2
    8000507e:	963e                	add	a2,a2,a5
    80005080:	85be                	mv	a1,a5
    80005082:	855a                	mv	a0,s6
    80005084:	ffffc097          	auipc	ra,0xffffc
    80005088:	38c080e7          	jalr	908(ra) # 80001410 <uvmalloc>
    8000508c:	8c2a                	mv	s8,a0
  ip = 0;
    8000508e:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005090:	12050e63          	beqz	a0,800051cc <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005094:	75f9                	lui	a1,0xffffe
    80005096:	95aa                	add	a1,a1,a0
    80005098:	855a                	mv	a0,s6
    8000509a:	ffffc097          	auipc	ra,0xffffc
    8000509e:	5a0080e7          	jalr	1440(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    800050a2:	7afd                	lui	s5,0xfffff
    800050a4:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800050a6:	df043783          	ld	a5,-528(s0)
    800050aa:	6388                	ld	a0,0(a5)
    800050ac:	c925                	beqz	a0,8000511c <exec+0x224>
    800050ae:	e9040993          	addi	s3,s0,-368
    800050b2:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800050b6:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800050b8:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800050ba:	ffffc097          	auipc	ra,0xffffc
    800050be:	d94080e7          	jalr	-620(ra) # 80000e4e <strlen>
    800050c2:	0015079b          	addiw	a5,a0,1
    800050c6:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800050ca:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800050ce:	13596663          	bltu	s2,s5,800051fa <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800050d2:	df043d83          	ld	s11,-528(s0)
    800050d6:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800050da:	8552                	mv	a0,s4
    800050dc:	ffffc097          	auipc	ra,0xffffc
    800050e0:	d72080e7          	jalr	-654(ra) # 80000e4e <strlen>
    800050e4:	0015069b          	addiw	a3,a0,1
    800050e8:	8652                	mv	a2,s4
    800050ea:	85ca                	mv	a1,s2
    800050ec:	855a                	mv	a0,s6
    800050ee:	ffffc097          	auipc	ra,0xffffc
    800050f2:	57e080e7          	jalr	1406(ra) # 8000166c <copyout>
    800050f6:	10054663          	bltz	a0,80005202 <exec+0x30a>
    ustack[argc] = sp;
    800050fa:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800050fe:	0485                	addi	s1,s1,1
    80005100:	008d8793          	addi	a5,s11,8
    80005104:	def43823          	sd	a5,-528(s0)
    80005108:	008db503          	ld	a0,8(s11)
    8000510c:	c911                	beqz	a0,80005120 <exec+0x228>
    if(argc >= MAXARG)
    8000510e:	09a1                	addi	s3,s3,8
    80005110:	fb3c95e3          	bne	s9,s3,800050ba <exec+0x1c2>
  sz = sz1;
    80005114:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005118:	4a81                	li	s5,0
    8000511a:	a84d                	j	800051cc <exec+0x2d4>
  sp = sz;
    8000511c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000511e:	4481                	li	s1,0
  ustack[argc] = 0;
    80005120:	00349793          	slli	a5,s1,0x3
    80005124:	f9078793          	addi	a5,a5,-112
    80005128:	97a2                	add	a5,a5,s0
    8000512a:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000512e:	00148693          	addi	a3,s1,1
    80005132:	068e                	slli	a3,a3,0x3
    80005134:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005138:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000513c:	01597663          	bgeu	s2,s5,80005148 <exec+0x250>
  sz = sz1;
    80005140:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005144:	4a81                	li	s5,0
    80005146:	a059                	j	800051cc <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005148:	e9040613          	addi	a2,s0,-368
    8000514c:	85ca                	mv	a1,s2
    8000514e:	855a                	mv	a0,s6
    80005150:	ffffc097          	auipc	ra,0xffffc
    80005154:	51c080e7          	jalr	1308(ra) # 8000166c <copyout>
    80005158:	0a054963          	bltz	a0,8000520a <exec+0x312>
  p->trapframe->a1 = sp;
    8000515c:	058bb783          	ld	a5,88(s7)
    80005160:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005164:	de843783          	ld	a5,-536(s0)
    80005168:	0007c703          	lbu	a4,0(a5)
    8000516c:	cf11                	beqz	a4,80005188 <exec+0x290>
    8000516e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005170:	02f00693          	li	a3,47
    80005174:	a039                	j	80005182 <exec+0x28a>
      last = s+1;
    80005176:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    8000517a:	0785                	addi	a5,a5,1
    8000517c:	fff7c703          	lbu	a4,-1(a5)
    80005180:	c701                	beqz	a4,80005188 <exec+0x290>
    if(*s == '/')
    80005182:	fed71ce3          	bne	a4,a3,8000517a <exec+0x282>
    80005186:	bfc5                	j	80005176 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    80005188:	4641                	li	a2,16
    8000518a:	de843583          	ld	a1,-536(s0)
    8000518e:	158b8513          	addi	a0,s7,344
    80005192:	ffffc097          	auipc	ra,0xffffc
    80005196:	c8a080e7          	jalr	-886(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    8000519a:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    8000519e:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800051a2:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800051a6:	058bb783          	ld	a5,88(s7)
    800051aa:	e6843703          	ld	a4,-408(s0)
    800051ae:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800051b0:	058bb783          	ld	a5,88(s7)
    800051b4:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800051b8:	85ea                	mv	a1,s10
    800051ba:	ffffd097          	auipc	ra,0xffffd
    800051be:	952080e7          	jalr	-1710(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800051c2:	0004851b          	sext.w	a0,s1
    800051c6:	b3f9                	j	80004f94 <exec+0x9c>
    800051c8:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800051cc:	df843583          	ld	a1,-520(s0)
    800051d0:	855a                	mv	a0,s6
    800051d2:	ffffd097          	auipc	ra,0xffffd
    800051d6:	93a080e7          	jalr	-1734(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    800051da:	da0a93e3          	bnez	s5,80004f80 <exec+0x88>
  return -1;
    800051de:	557d                	li	a0,-1
    800051e0:	bb55                	j	80004f94 <exec+0x9c>
    800051e2:	df243c23          	sd	s2,-520(s0)
    800051e6:	b7dd                	j	800051cc <exec+0x2d4>
    800051e8:	df243c23          	sd	s2,-520(s0)
    800051ec:	b7c5                	j	800051cc <exec+0x2d4>
    800051ee:	df243c23          	sd	s2,-520(s0)
    800051f2:	bfe9                	j	800051cc <exec+0x2d4>
    800051f4:	df243c23          	sd	s2,-520(s0)
    800051f8:	bfd1                	j	800051cc <exec+0x2d4>
  sz = sz1;
    800051fa:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051fe:	4a81                	li	s5,0
    80005200:	b7f1                	j	800051cc <exec+0x2d4>
  sz = sz1;
    80005202:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005206:	4a81                	li	s5,0
    80005208:	b7d1                	j	800051cc <exec+0x2d4>
  sz = sz1;
    8000520a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000520e:	4a81                	li	s5,0
    80005210:	bf75                	j	800051cc <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005212:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005216:	e0843783          	ld	a5,-504(s0)
    8000521a:	0017869b          	addiw	a3,a5,1
    8000521e:	e0d43423          	sd	a3,-504(s0)
    80005222:	e0043783          	ld	a5,-512(s0)
    80005226:	0387879b          	addiw	a5,a5,56
    8000522a:	e8845703          	lhu	a4,-376(s0)
    8000522e:	e0e6dfe3          	bge	a3,a4,8000504c <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005232:	2781                	sext.w	a5,a5
    80005234:	e0f43023          	sd	a5,-512(s0)
    80005238:	03800713          	li	a4,56
    8000523c:	86be                	mv	a3,a5
    8000523e:	e1840613          	addi	a2,s0,-488
    80005242:	4581                	li	a1,0
    80005244:	8556                	mv	a0,s5
    80005246:	fffff097          	auipc	ra,0xfffff
    8000524a:	a58080e7          	jalr	-1448(ra) # 80003c9e <readi>
    8000524e:	03800793          	li	a5,56
    80005252:	f6f51be3          	bne	a0,a5,800051c8 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80005256:	e1842783          	lw	a5,-488(s0)
    8000525a:	4705                	li	a4,1
    8000525c:	fae79de3          	bne	a5,a4,80005216 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80005260:	e4043483          	ld	s1,-448(s0)
    80005264:	e3843783          	ld	a5,-456(s0)
    80005268:	f6f4ede3          	bltu	s1,a5,800051e2 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000526c:	e2843783          	ld	a5,-472(s0)
    80005270:	94be                	add	s1,s1,a5
    80005272:	f6f4ebe3          	bltu	s1,a5,800051e8 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80005276:	de043703          	ld	a4,-544(s0)
    8000527a:	8ff9                	and	a5,a5,a4
    8000527c:	fbad                	bnez	a5,800051ee <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000527e:	e1c42503          	lw	a0,-484(s0)
    80005282:	00000097          	auipc	ra,0x0
    80005286:	c5c080e7          	jalr	-932(ra) # 80004ede <flags2perm>
    8000528a:	86aa                	mv	a3,a0
    8000528c:	8626                	mv	a2,s1
    8000528e:	85ca                	mv	a1,s2
    80005290:	855a                	mv	a0,s6
    80005292:	ffffc097          	auipc	ra,0xffffc
    80005296:	17e080e7          	jalr	382(ra) # 80001410 <uvmalloc>
    8000529a:	dea43c23          	sd	a0,-520(s0)
    8000529e:	d939                	beqz	a0,800051f4 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800052a0:	e2843c03          	ld	s8,-472(s0)
    800052a4:	e2042c83          	lw	s9,-480(s0)
    800052a8:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800052ac:	f60b83e3          	beqz	s7,80005212 <exec+0x31a>
    800052b0:	89de                	mv	s3,s7
    800052b2:	4481                	li	s1,0
    800052b4:	bb9d                	j	8000502a <exec+0x132>

00000000800052b6 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800052b6:	7179                	addi	sp,sp,-48
    800052b8:	f406                	sd	ra,40(sp)
    800052ba:	f022                	sd	s0,32(sp)
    800052bc:	ec26                	sd	s1,24(sp)
    800052be:	e84a                	sd	s2,16(sp)
    800052c0:	1800                	addi	s0,sp,48
    800052c2:	892e                	mv	s2,a1
    800052c4:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800052c6:	fdc40593          	addi	a1,s0,-36
    800052ca:	ffffe097          	auipc	ra,0xffffe
    800052ce:	a4a080e7          	jalr	-1462(ra) # 80002d14 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800052d2:	fdc42703          	lw	a4,-36(s0)
    800052d6:	47bd                	li	a5,15
    800052d8:	02e7eb63          	bltu	a5,a4,8000530e <argfd+0x58>
    800052dc:	ffffc097          	auipc	ra,0xffffc
    800052e0:	6d0080e7          	jalr	1744(ra) # 800019ac <myproc>
    800052e4:	fdc42703          	lw	a4,-36(s0)
    800052e8:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdab2a>
    800052ec:	078e                	slli	a5,a5,0x3
    800052ee:	953e                	add	a0,a0,a5
    800052f0:	611c                	ld	a5,0(a0)
    800052f2:	c385                	beqz	a5,80005312 <argfd+0x5c>
    return -1;
  if(pfd)
    800052f4:	00090463          	beqz	s2,800052fc <argfd+0x46>
    *pfd = fd;
    800052f8:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800052fc:	4501                	li	a0,0
  if(pf)
    800052fe:	c091                	beqz	s1,80005302 <argfd+0x4c>
    *pf = f;
    80005300:	e09c                	sd	a5,0(s1)
}
    80005302:	70a2                	ld	ra,40(sp)
    80005304:	7402                	ld	s0,32(sp)
    80005306:	64e2                	ld	s1,24(sp)
    80005308:	6942                	ld	s2,16(sp)
    8000530a:	6145                	addi	sp,sp,48
    8000530c:	8082                	ret
    return -1;
    8000530e:	557d                	li	a0,-1
    80005310:	bfcd                	j	80005302 <argfd+0x4c>
    80005312:	557d                	li	a0,-1
    80005314:	b7fd                	j	80005302 <argfd+0x4c>

0000000080005316 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005316:	1101                	addi	sp,sp,-32
    80005318:	ec06                	sd	ra,24(sp)
    8000531a:	e822                	sd	s0,16(sp)
    8000531c:	e426                	sd	s1,8(sp)
    8000531e:	1000                	addi	s0,sp,32
    80005320:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005322:	ffffc097          	auipc	ra,0xffffc
    80005326:	68a080e7          	jalr	1674(ra) # 800019ac <myproc>
    8000532a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000532c:	0d050793          	addi	a5,a0,208
    80005330:	4501                	li	a0,0
    80005332:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005334:	6398                	ld	a4,0(a5)
    80005336:	cb19                	beqz	a4,8000534c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005338:	2505                	addiw	a0,a0,1
    8000533a:	07a1                	addi	a5,a5,8
    8000533c:	fed51ce3          	bne	a0,a3,80005334 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005340:	557d                	li	a0,-1
}
    80005342:	60e2                	ld	ra,24(sp)
    80005344:	6442                	ld	s0,16(sp)
    80005346:	64a2                	ld	s1,8(sp)
    80005348:	6105                	addi	sp,sp,32
    8000534a:	8082                	ret
      p->ofile[fd] = f;
    8000534c:	01a50793          	addi	a5,a0,26
    80005350:	078e                	slli	a5,a5,0x3
    80005352:	963e                	add	a2,a2,a5
    80005354:	e204                	sd	s1,0(a2)
      return fd;
    80005356:	b7f5                	j	80005342 <fdalloc+0x2c>

0000000080005358 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005358:	715d                	addi	sp,sp,-80
    8000535a:	e486                	sd	ra,72(sp)
    8000535c:	e0a2                	sd	s0,64(sp)
    8000535e:	fc26                	sd	s1,56(sp)
    80005360:	f84a                	sd	s2,48(sp)
    80005362:	f44e                	sd	s3,40(sp)
    80005364:	f052                	sd	s4,32(sp)
    80005366:	ec56                	sd	s5,24(sp)
    80005368:	e85a                	sd	s6,16(sp)
    8000536a:	0880                	addi	s0,sp,80
    8000536c:	8b2e                	mv	s6,a1
    8000536e:	89b2                	mv	s3,a2
    80005370:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005372:	fb040593          	addi	a1,s0,-80
    80005376:	fffff097          	auipc	ra,0xfffff
    8000537a:	e3e080e7          	jalr	-450(ra) # 800041b4 <nameiparent>
    8000537e:	84aa                	mv	s1,a0
    80005380:	14050f63          	beqz	a0,800054de <create+0x186>
    return 0;

  ilock(dp);
    80005384:	ffffe097          	auipc	ra,0xffffe
    80005388:	666080e7          	jalr	1638(ra) # 800039ea <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000538c:	4601                	li	a2,0
    8000538e:	fb040593          	addi	a1,s0,-80
    80005392:	8526                	mv	a0,s1
    80005394:	fffff097          	auipc	ra,0xfffff
    80005398:	b3a080e7          	jalr	-1222(ra) # 80003ece <dirlookup>
    8000539c:	8aaa                	mv	s5,a0
    8000539e:	c931                	beqz	a0,800053f2 <create+0x9a>
    iunlockput(dp);
    800053a0:	8526                	mv	a0,s1
    800053a2:	fffff097          	auipc	ra,0xfffff
    800053a6:	8aa080e7          	jalr	-1878(ra) # 80003c4c <iunlockput>
    ilock(ip);
    800053aa:	8556                	mv	a0,s5
    800053ac:	ffffe097          	auipc	ra,0xffffe
    800053b0:	63e080e7          	jalr	1598(ra) # 800039ea <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800053b4:	000b059b          	sext.w	a1,s6
    800053b8:	4789                	li	a5,2
    800053ba:	02f59563          	bne	a1,a5,800053e4 <create+0x8c>
    800053be:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdab54>
    800053c2:	37f9                	addiw	a5,a5,-2
    800053c4:	17c2                	slli	a5,a5,0x30
    800053c6:	93c1                	srli	a5,a5,0x30
    800053c8:	4705                	li	a4,1
    800053ca:	00f76d63          	bltu	a4,a5,800053e4 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800053ce:	8556                	mv	a0,s5
    800053d0:	60a6                	ld	ra,72(sp)
    800053d2:	6406                	ld	s0,64(sp)
    800053d4:	74e2                	ld	s1,56(sp)
    800053d6:	7942                	ld	s2,48(sp)
    800053d8:	79a2                	ld	s3,40(sp)
    800053da:	7a02                	ld	s4,32(sp)
    800053dc:	6ae2                	ld	s5,24(sp)
    800053de:	6b42                	ld	s6,16(sp)
    800053e0:	6161                	addi	sp,sp,80
    800053e2:	8082                	ret
    iunlockput(ip);
    800053e4:	8556                	mv	a0,s5
    800053e6:	fffff097          	auipc	ra,0xfffff
    800053ea:	866080e7          	jalr	-1946(ra) # 80003c4c <iunlockput>
    return 0;
    800053ee:	4a81                	li	s5,0
    800053f0:	bff9                	j	800053ce <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800053f2:	85da                	mv	a1,s6
    800053f4:	4088                	lw	a0,0(s1)
    800053f6:	ffffe097          	auipc	ra,0xffffe
    800053fa:	456080e7          	jalr	1110(ra) # 8000384c <ialloc>
    800053fe:	8a2a                	mv	s4,a0
    80005400:	c539                	beqz	a0,8000544e <create+0xf6>
  ilock(ip);
    80005402:	ffffe097          	auipc	ra,0xffffe
    80005406:	5e8080e7          	jalr	1512(ra) # 800039ea <ilock>
  ip->major = major;
    8000540a:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000540e:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005412:	4905                	li	s2,1
    80005414:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005418:	8552                	mv	a0,s4
    8000541a:	ffffe097          	auipc	ra,0xffffe
    8000541e:	504080e7          	jalr	1284(ra) # 8000391e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005422:	000b059b          	sext.w	a1,s6
    80005426:	03258b63          	beq	a1,s2,8000545c <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    8000542a:	004a2603          	lw	a2,4(s4)
    8000542e:	fb040593          	addi	a1,s0,-80
    80005432:	8526                	mv	a0,s1
    80005434:	fffff097          	auipc	ra,0xfffff
    80005438:	cb0080e7          	jalr	-848(ra) # 800040e4 <dirlink>
    8000543c:	06054f63          	bltz	a0,800054ba <create+0x162>
  iunlockput(dp);
    80005440:	8526                	mv	a0,s1
    80005442:	fffff097          	auipc	ra,0xfffff
    80005446:	80a080e7          	jalr	-2038(ra) # 80003c4c <iunlockput>
  return ip;
    8000544a:	8ad2                	mv	s5,s4
    8000544c:	b749                	j	800053ce <create+0x76>
    iunlockput(dp);
    8000544e:	8526                	mv	a0,s1
    80005450:	ffffe097          	auipc	ra,0xffffe
    80005454:	7fc080e7          	jalr	2044(ra) # 80003c4c <iunlockput>
    return 0;
    80005458:	8ad2                	mv	s5,s4
    8000545a:	bf95                	j	800053ce <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000545c:	004a2603          	lw	a2,4(s4)
    80005460:	00003597          	auipc	a1,0x3
    80005464:	3a858593          	addi	a1,a1,936 # 80008808 <syscalls+0x2c8>
    80005468:	8552                	mv	a0,s4
    8000546a:	fffff097          	auipc	ra,0xfffff
    8000546e:	c7a080e7          	jalr	-902(ra) # 800040e4 <dirlink>
    80005472:	04054463          	bltz	a0,800054ba <create+0x162>
    80005476:	40d0                	lw	a2,4(s1)
    80005478:	00003597          	auipc	a1,0x3
    8000547c:	39858593          	addi	a1,a1,920 # 80008810 <syscalls+0x2d0>
    80005480:	8552                	mv	a0,s4
    80005482:	fffff097          	auipc	ra,0xfffff
    80005486:	c62080e7          	jalr	-926(ra) # 800040e4 <dirlink>
    8000548a:	02054863          	bltz	a0,800054ba <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    8000548e:	004a2603          	lw	a2,4(s4)
    80005492:	fb040593          	addi	a1,s0,-80
    80005496:	8526                	mv	a0,s1
    80005498:	fffff097          	auipc	ra,0xfffff
    8000549c:	c4c080e7          	jalr	-948(ra) # 800040e4 <dirlink>
    800054a0:	00054d63          	bltz	a0,800054ba <create+0x162>
    dp->nlink++;  // for ".."
    800054a4:	04a4d783          	lhu	a5,74(s1)
    800054a8:	2785                	addiw	a5,a5,1
    800054aa:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800054ae:	8526                	mv	a0,s1
    800054b0:	ffffe097          	auipc	ra,0xffffe
    800054b4:	46e080e7          	jalr	1134(ra) # 8000391e <iupdate>
    800054b8:	b761                	j	80005440 <create+0xe8>
  ip->nlink = 0;
    800054ba:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800054be:	8552                	mv	a0,s4
    800054c0:	ffffe097          	auipc	ra,0xffffe
    800054c4:	45e080e7          	jalr	1118(ra) # 8000391e <iupdate>
  iunlockput(ip);
    800054c8:	8552                	mv	a0,s4
    800054ca:	ffffe097          	auipc	ra,0xffffe
    800054ce:	782080e7          	jalr	1922(ra) # 80003c4c <iunlockput>
  iunlockput(dp);
    800054d2:	8526                	mv	a0,s1
    800054d4:	ffffe097          	auipc	ra,0xffffe
    800054d8:	778080e7          	jalr	1912(ra) # 80003c4c <iunlockput>
  return 0;
    800054dc:	bdcd                	j	800053ce <create+0x76>
    return 0;
    800054de:	8aaa                	mv	s5,a0
    800054e0:	b5fd                	j	800053ce <create+0x76>

00000000800054e2 <sys_dup>:
{
    800054e2:	7179                	addi	sp,sp,-48
    800054e4:	f406                	sd	ra,40(sp)
    800054e6:	f022                	sd	s0,32(sp)
    800054e8:	ec26                	sd	s1,24(sp)
    800054ea:	e84a                	sd	s2,16(sp)
    800054ec:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800054ee:	fd840613          	addi	a2,s0,-40
    800054f2:	4581                	li	a1,0
    800054f4:	4501                	li	a0,0
    800054f6:	00000097          	auipc	ra,0x0
    800054fa:	dc0080e7          	jalr	-576(ra) # 800052b6 <argfd>
    return -1;
    800054fe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005500:	02054363          	bltz	a0,80005526 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005504:	fd843903          	ld	s2,-40(s0)
    80005508:	854a                	mv	a0,s2
    8000550a:	00000097          	auipc	ra,0x0
    8000550e:	e0c080e7          	jalr	-500(ra) # 80005316 <fdalloc>
    80005512:	84aa                	mv	s1,a0
    return -1;
    80005514:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005516:	00054863          	bltz	a0,80005526 <sys_dup+0x44>
  filedup(f);
    8000551a:	854a                	mv	a0,s2
    8000551c:	fffff097          	auipc	ra,0xfffff
    80005520:	310080e7          	jalr	784(ra) # 8000482c <filedup>
  return fd;
    80005524:	87a6                	mv	a5,s1
}
    80005526:	853e                	mv	a0,a5
    80005528:	70a2                	ld	ra,40(sp)
    8000552a:	7402                	ld	s0,32(sp)
    8000552c:	64e2                	ld	s1,24(sp)
    8000552e:	6942                	ld	s2,16(sp)
    80005530:	6145                	addi	sp,sp,48
    80005532:	8082                	ret

0000000080005534 <sys_read>:
{
    80005534:	7179                	addi	sp,sp,-48
    80005536:	f406                	sd	ra,40(sp)
    80005538:	f022                	sd	s0,32(sp)
    8000553a:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000553c:	fd840593          	addi	a1,s0,-40
    80005540:	4505                	li	a0,1
    80005542:	ffffd097          	auipc	ra,0xffffd
    80005546:	7f2080e7          	jalr	2034(ra) # 80002d34 <argaddr>
  argint(2, &n);
    8000554a:	fe440593          	addi	a1,s0,-28
    8000554e:	4509                	li	a0,2
    80005550:	ffffd097          	auipc	ra,0xffffd
    80005554:	7c4080e7          	jalr	1988(ra) # 80002d14 <argint>
  if(argfd(0, 0, &f) < 0)
    80005558:	fe840613          	addi	a2,s0,-24
    8000555c:	4581                	li	a1,0
    8000555e:	4501                	li	a0,0
    80005560:	00000097          	auipc	ra,0x0
    80005564:	d56080e7          	jalr	-682(ra) # 800052b6 <argfd>
    80005568:	87aa                	mv	a5,a0
    return -1;
    8000556a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000556c:	0007cc63          	bltz	a5,80005584 <sys_read+0x50>
  return fileread(f, p, n);
    80005570:	fe442603          	lw	a2,-28(s0)
    80005574:	fd843583          	ld	a1,-40(s0)
    80005578:	fe843503          	ld	a0,-24(s0)
    8000557c:	fffff097          	auipc	ra,0xfffff
    80005580:	43c080e7          	jalr	1084(ra) # 800049b8 <fileread>
}
    80005584:	70a2                	ld	ra,40(sp)
    80005586:	7402                	ld	s0,32(sp)
    80005588:	6145                	addi	sp,sp,48
    8000558a:	8082                	ret

000000008000558c <sys_write>:
{
    8000558c:	7179                	addi	sp,sp,-48
    8000558e:	f406                	sd	ra,40(sp)
    80005590:	f022                	sd	s0,32(sp)
    80005592:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005594:	fd840593          	addi	a1,s0,-40
    80005598:	4505                	li	a0,1
    8000559a:	ffffd097          	auipc	ra,0xffffd
    8000559e:	79a080e7          	jalr	1946(ra) # 80002d34 <argaddr>
  argint(2, &n);
    800055a2:	fe440593          	addi	a1,s0,-28
    800055a6:	4509                	li	a0,2
    800055a8:	ffffd097          	auipc	ra,0xffffd
    800055ac:	76c080e7          	jalr	1900(ra) # 80002d14 <argint>
  if(argfd(0, 0, &f) < 0)
    800055b0:	fe840613          	addi	a2,s0,-24
    800055b4:	4581                	li	a1,0
    800055b6:	4501                	li	a0,0
    800055b8:	00000097          	auipc	ra,0x0
    800055bc:	cfe080e7          	jalr	-770(ra) # 800052b6 <argfd>
    800055c0:	87aa                	mv	a5,a0
    return -1;
    800055c2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800055c4:	0007cc63          	bltz	a5,800055dc <sys_write+0x50>
  return filewrite(f, p, n);
    800055c8:	fe442603          	lw	a2,-28(s0)
    800055cc:	fd843583          	ld	a1,-40(s0)
    800055d0:	fe843503          	ld	a0,-24(s0)
    800055d4:	fffff097          	auipc	ra,0xfffff
    800055d8:	4a6080e7          	jalr	1190(ra) # 80004a7a <filewrite>
}
    800055dc:	70a2                	ld	ra,40(sp)
    800055de:	7402                	ld	s0,32(sp)
    800055e0:	6145                	addi	sp,sp,48
    800055e2:	8082                	ret

00000000800055e4 <sys_close>:
{
    800055e4:	1101                	addi	sp,sp,-32
    800055e6:	ec06                	sd	ra,24(sp)
    800055e8:	e822                	sd	s0,16(sp)
    800055ea:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800055ec:	fe040613          	addi	a2,s0,-32
    800055f0:	fec40593          	addi	a1,s0,-20
    800055f4:	4501                	li	a0,0
    800055f6:	00000097          	auipc	ra,0x0
    800055fa:	cc0080e7          	jalr	-832(ra) # 800052b6 <argfd>
    return -1;
    800055fe:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005600:	02054463          	bltz	a0,80005628 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005604:	ffffc097          	auipc	ra,0xffffc
    80005608:	3a8080e7          	jalr	936(ra) # 800019ac <myproc>
    8000560c:	fec42783          	lw	a5,-20(s0)
    80005610:	07e9                	addi	a5,a5,26
    80005612:	078e                	slli	a5,a5,0x3
    80005614:	953e                	add	a0,a0,a5
    80005616:	00053023          	sd	zero,0(a0)
  fileclose(f);
    8000561a:	fe043503          	ld	a0,-32(s0)
    8000561e:	fffff097          	auipc	ra,0xfffff
    80005622:	260080e7          	jalr	608(ra) # 8000487e <fileclose>
  return 0;
    80005626:	4781                	li	a5,0
}
    80005628:	853e                	mv	a0,a5
    8000562a:	60e2                	ld	ra,24(sp)
    8000562c:	6442                	ld	s0,16(sp)
    8000562e:	6105                	addi	sp,sp,32
    80005630:	8082                	ret

0000000080005632 <sys_fstat>:
{
    80005632:	1101                	addi	sp,sp,-32
    80005634:	ec06                	sd	ra,24(sp)
    80005636:	e822                	sd	s0,16(sp)
    80005638:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000563a:	fe040593          	addi	a1,s0,-32
    8000563e:	4505                	li	a0,1
    80005640:	ffffd097          	auipc	ra,0xffffd
    80005644:	6f4080e7          	jalr	1780(ra) # 80002d34 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005648:	fe840613          	addi	a2,s0,-24
    8000564c:	4581                	li	a1,0
    8000564e:	4501                	li	a0,0
    80005650:	00000097          	auipc	ra,0x0
    80005654:	c66080e7          	jalr	-922(ra) # 800052b6 <argfd>
    80005658:	87aa                	mv	a5,a0
    return -1;
    8000565a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000565c:	0007ca63          	bltz	a5,80005670 <sys_fstat+0x3e>
  return filestat(f, st);
    80005660:	fe043583          	ld	a1,-32(s0)
    80005664:	fe843503          	ld	a0,-24(s0)
    80005668:	fffff097          	auipc	ra,0xfffff
    8000566c:	2de080e7          	jalr	734(ra) # 80004946 <filestat>
}
    80005670:	60e2                	ld	ra,24(sp)
    80005672:	6442                	ld	s0,16(sp)
    80005674:	6105                	addi	sp,sp,32
    80005676:	8082                	ret

0000000080005678 <sys_link>:
{
    80005678:	7169                	addi	sp,sp,-304
    8000567a:	f606                	sd	ra,296(sp)
    8000567c:	f222                	sd	s0,288(sp)
    8000567e:	ee26                	sd	s1,280(sp)
    80005680:	ea4a                	sd	s2,272(sp)
    80005682:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005684:	08000613          	li	a2,128
    80005688:	ed040593          	addi	a1,s0,-304
    8000568c:	4501                	li	a0,0
    8000568e:	ffffd097          	auipc	ra,0xffffd
    80005692:	6c6080e7          	jalr	1734(ra) # 80002d54 <argstr>
    return -1;
    80005696:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005698:	10054e63          	bltz	a0,800057b4 <sys_link+0x13c>
    8000569c:	08000613          	li	a2,128
    800056a0:	f5040593          	addi	a1,s0,-176
    800056a4:	4505                	li	a0,1
    800056a6:	ffffd097          	auipc	ra,0xffffd
    800056aa:	6ae080e7          	jalr	1710(ra) # 80002d54 <argstr>
    return -1;
    800056ae:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056b0:	10054263          	bltz	a0,800057b4 <sys_link+0x13c>
  begin_op();
    800056b4:	fffff097          	auipc	ra,0xfffff
    800056b8:	d02080e7          	jalr	-766(ra) # 800043b6 <begin_op>
  if((ip = namei(old)) == 0){
    800056bc:	ed040513          	addi	a0,s0,-304
    800056c0:	fffff097          	auipc	ra,0xfffff
    800056c4:	ad6080e7          	jalr	-1322(ra) # 80004196 <namei>
    800056c8:	84aa                	mv	s1,a0
    800056ca:	c551                	beqz	a0,80005756 <sys_link+0xde>
  ilock(ip);
    800056cc:	ffffe097          	auipc	ra,0xffffe
    800056d0:	31e080e7          	jalr	798(ra) # 800039ea <ilock>
  if(ip->type == T_DIR){
    800056d4:	04449703          	lh	a4,68(s1)
    800056d8:	4785                	li	a5,1
    800056da:	08f70463          	beq	a4,a5,80005762 <sys_link+0xea>
  ip->nlink++;
    800056de:	04a4d783          	lhu	a5,74(s1)
    800056e2:	2785                	addiw	a5,a5,1
    800056e4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056e8:	8526                	mv	a0,s1
    800056ea:	ffffe097          	auipc	ra,0xffffe
    800056ee:	234080e7          	jalr	564(ra) # 8000391e <iupdate>
  iunlock(ip);
    800056f2:	8526                	mv	a0,s1
    800056f4:	ffffe097          	auipc	ra,0xffffe
    800056f8:	3b8080e7          	jalr	952(ra) # 80003aac <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800056fc:	fd040593          	addi	a1,s0,-48
    80005700:	f5040513          	addi	a0,s0,-176
    80005704:	fffff097          	auipc	ra,0xfffff
    80005708:	ab0080e7          	jalr	-1360(ra) # 800041b4 <nameiparent>
    8000570c:	892a                	mv	s2,a0
    8000570e:	c935                	beqz	a0,80005782 <sys_link+0x10a>
  ilock(dp);
    80005710:	ffffe097          	auipc	ra,0xffffe
    80005714:	2da080e7          	jalr	730(ra) # 800039ea <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005718:	00092703          	lw	a4,0(s2)
    8000571c:	409c                	lw	a5,0(s1)
    8000571e:	04f71d63          	bne	a4,a5,80005778 <sys_link+0x100>
    80005722:	40d0                	lw	a2,4(s1)
    80005724:	fd040593          	addi	a1,s0,-48
    80005728:	854a                	mv	a0,s2
    8000572a:	fffff097          	auipc	ra,0xfffff
    8000572e:	9ba080e7          	jalr	-1606(ra) # 800040e4 <dirlink>
    80005732:	04054363          	bltz	a0,80005778 <sys_link+0x100>
  iunlockput(dp);
    80005736:	854a                	mv	a0,s2
    80005738:	ffffe097          	auipc	ra,0xffffe
    8000573c:	514080e7          	jalr	1300(ra) # 80003c4c <iunlockput>
  iput(ip);
    80005740:	8526                	mv	a0,s1
    80005742:	ffffe097          	auipc	ra,0xffffe
    80005746:	462080e7          	jalr	1122(ra) # 80003ba4 <iput>
  end_op();
    8000574a:	fffff097          	auipc	ra,0xfffff
    8000574e:	cea080e7          	jalr	-790(ra) # 80004434 <end_op>
  return 0;
    80005752:	4781                	li	a5,0
    80005754:	a085                	j	800057b4 <sys_link+0x13c>
    end_op();
    80005756:	fffff097          	auipc	ra,0xfffff
    8000575a:	cde080e7          	jalr	-802(ra) # 80004434 <end_op>
    return -1;
    8000575e:	57fd                	li	a5,-1
    80005760:	a891                	j	800057b4 <sys_link+0x13c>
    iunlockput(ip);
    80005762:	8526                	mv	a0,s1
    80005764:	ffffe097          	auipc	ra,0xffffe
    80005768:	4e8080e7          	jalr	1256(ra) # 80003c4c <iunlockput>
    end_op();
    8000576c:	fffff097          	auipc	ra,0xfffff
    80005770:	cc8080e7          	jalr	-824(ra) # 80004434 <end_op>
    return -1;
    80005774:	57fd                	li	a5,-1
    80005776:	a83d                	j	800057b4 <sys_link+0x13c>
    iunlockput(dp);
    80005778:	854a                	mv	a0,s2
    8000577a:	ffffe097          	auipc	ra,0xffffe
    8000577e:	4d2080e7          	jalr	1234(ra) # 80003c4c <iunlockput>
  ilock(ip);
    80005782:	8526                	mv	a0,s1
    80005784:	ffffe097          	auipc	ra,0xffffe
    80005788:	266080e7          	jalr	614(ra) # 800039ea <ilock>
  ip->nlink--;
    8000578c:	04a4d783          	lhu	a5,74(s1)
    80005790:	37fd                	addiw	a5,a5,-1
    80005792:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005796:	8526                	mv	a0,s1
    80005798:	ffffe097          	auipc	ra,0xffffe
    8000579c:	186080e7          	jalr	390(ra) # 8000391e <iupdate>
  iunlockput(ip);
    800057a0:	8526                	mv	a0,s1
    800057a2:	ffffe097          	auipc	ra,0xffffe
    800057a6:	4aa080e7          	jalr	1194(ra) # 80003c4c <iunlockput>
  end_op();
    800057aa:	fffff097          	auipc	ra,0xfffff
    800057ae:	c8a080e7          	jalr	-886(ra) # 80004434 <end_op>
  return -1;
    800057b2:	57fd                	li	a5,-1
}
    800057b4:	853e                	mv	a0,a5
    800057b6:	70b2                	ld	ra,296(sp)
    800057b8:	7412                	ld	s0,288(sp)
    800057ba:	64f2                	ld	s1,280(sp)
    800057bc:	6952                	ld	s2,272(sp)
    800057be:	6155                	addi	sp,sp,304
    800057c0:	8082                	ret

00000000800057c2 <sys_unlink>:
{
    800057c2:	7151                	addi	sp,sp,-240
    800057c4:	f586                	sd	ra,232(sp)
    800057c6:	f1a2                	sd	s0,224(sp)
    800057c8:	eda6                	sd	s1,216(sp)
    800057ca:	e9ca                	sd	s2,208(sp)
    800057cc:	e5ce                	sd	s3,200(sp)
    800057ce:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800057d0:	08000613          	li	a2,128
    800057d4:	f3040593          	addi	a1,s0,-208
    800057d8:	4501                	li	a0,0
    800057da:	ffffd097          	auipc	ra,0xffffd
    800057de:	57a080e7          	jalr	1402(ra) # 80002d54 <argstr>
    800057e2:	18054163          	bltz	a0,80005964 <sys_unlink+0x1a2>
  begin_op();
    800057e6:	fffff097          	auipc	ra,0xfffff
    800057ea:	bd0080e7          	jalr	-1072(ra) # 800043b6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800057ee:	fb040593          	addi	a1,s0,-80
    800057f2:	f3040513          	addi	a0,s0,-208
    800057f6:	fffff097          	auipc	ra,0xfffff
    800057fa:	9be080e7          	jalr	-1602(ra) # 800041b4 <nameiparent>
    800057fe:	84aa                	mv	s1,a0
    80005800:	c979                	beqz	a0,800058d6 <sys_unlink+0x114>
  ilock(dp);
    80005802:	ffffe097          	auipc	ra,0xffffe
    80005806:	1e8080e7          	jalr	488(ra) # 800039ea <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000580a:	00003597          	auipc	a1,0x3
    8000580e:	ffe58593          	addi	a1,a1,-2 # 80008808 <syscalls+0x2c8>
    80005812:	fb040513          	addi	a0,s0,-80
    80005816:	ffffe097          	auipc	ra,0xffffe
    8000581a:	69e080e7          	jalr	1694(ra) # 80003eb4 <namecmp>
    8000581e:	14050a63          	beqz	a0,80005972 <sys_unlink+0x1b0>
    80005822:	00003597          	auipc	a1,0x3
    80005826:	fee58593          	addi	a1,a1,-18 # 80008810 <syscalls+0x2d0>
    8000582a:	fb040513          	addi	a0,s0,-80
    8000582e:	ffffe097          	auipc	ra,0xffffe
    80005832:	686080e7          	jalr	1670(ra) # 80003eb4 <namecmp>
    80005836:	12050e63          	beqz	a0,80005972 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000583a:	f2c40613          	addi	a2,s0,-212
    8000583e:	fb040593          	addi	a1,s0,-80
    80005842:	8526                	mv	a0,s1
    80005844:	ffffe097          	auipc	ra,0xffffe
    80005848:	68a080e7          	jalr	1674(ra) # 80003ece <dirlookup>
    8000584c:	892a                	mv	s2,a0
    8000584e:	12050263          	beqz	a0,80005972 <sys_unlink+0x1b0>
  ilock(ip);
    80005852:	ffffe097          	auipc	ra,0xffffe
    80005856:	198080e7          	jalr	408(ra) # 800039ea <ilock>
  if(ip->nlink < 1)
    8000585a:	04a91783          	lh	a5,74(s2)
    8000585e:	08f05263          	blez	a5,800058e2 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005862:	04491703          	lh	a4,68(s2)
    80005866:	4785                	li	a5,1
    80005868:	08f70563          	beq	a4,a5,800058f2 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000586c:	4641                	li	a2,16
    8000586e:	4581                	li	a1,0
    80005870:	fc040513          	addi	a0,s0,-64
    80005874:	ffffb097          	auipc	ra,0xffffb
    80005878:	45e080e7          	jalr	1118(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000587c:	4741                	li	a4,16
    8000587e:	f2c42683          	lw	a3,-212(s0)
    80005882:	fc040613          	addi	a2,s0,-64
    80005886:	4581                	li	a1,0
    80005888:	8526                	mv	a0,s1
    8000588a:	ffffe097          	auipc	ra,0xffffe
    8000588e:	50c080e7          	jalr	1292(ra) # 80003d96 <writei>
    80005892:	47c1                	li	a5,16
    80005894:	0af51563          	bne	a0,a5,8000593e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005898:	04491703          	lh	a4,68(s2)
    8000589c:	4785                	li	a5,1
    8000589e:	0af70863          	beq	a4,a5,8000594e <sys_unlink+0x18c>
  iunlockput(dp);
    800058a2:	8526                	mv	a0,s1
    800058a4:	ffffe097          	auipc	ra,0xffffe
    800058a8:	3a8080e7          	jalr	936(ra) # 80003c4c <iunlockput>
  ip->nlink--;
    800058ac:	04a95783          	lhu	a5,74(s2)
    800058b0:	37fd                	addiw	a5,a5,-1
    800058b2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800058b6:	854a                	mv	a0,s2
    800058b8:	ffffe097          	auipc	ra,0xffffe
    800058bc:	066080e7          	jalr	102(ra) # 8000391e <iupdate>
  iunlockput(ip);
    800058c0:	854a                	mv	a0,s2
    800058c2:	ffffe097          	auipc	ra,0xffffe
    800058c6:	38a080e7          	jalr	906(ra) # 80003c4c <iunlockput>
  end_op();
    800058ca:	fffff097          	auipc	ra,0xfffff
    800058ce:	b6a080e7          	jalr	-1174(ra) # 80004434 <end_op>
  return 0;
    800058d2:	4501                	li	a0,0
    800058d4:	a84d                	j	80005986 <sys_unlink+0x1c4>
    end_op();
    800058d6:	fffff097          	auipc	ra,0xfffff
    800058da:	b5e080e7          	jalr	-1186(ra) # 80004434 <end_op>
    return -1;
    800058de:	557d                	li	a0,-1
    800058e0:	a05d                	j	80005986 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800058e2:	00003517          	auipc	a0,0x3
    800058e6:	f3650513          	addi	a0,a0,-202 # 80008818 <syscalls+0x2d8>
    800058ea:	ffffb097          	auipc	ra,0xffffb
    800058ee:	c56080e7          	jalr	-938(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058f2:	04c92703          	lw	a4,76(s2)
    800058f6:	02000793          	li	a5,32
    800058fa:	f6e7f9e3          	bgeu	a5,a4,8000586c <sys_unlink+0xaa>
    800058fe:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005902:	4741                	li	a4,16
    80005904:	86ce                	mv	a3,s3
    80005906:	f1840613          	addi	a2,s0,-232
    8000590a:	4581                	li	a1,0
    8000590c:	854a                	mv	a0,s2
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	390080e7          	jalr	912(ra) # 80003c9e <readi>
    80005916:	47c1                	li	a5,16
    80005918:	00f51b63          	bne	a0,a5,8000592e <sys_unlink+0x16c>
    if(de.inum != 0)
    8000591c:	f1845783          	lhu	a5,-232(s0)
    80005920:	e7a1                	bnez	a5,80005968 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005922:	29c1                	addiw	s3,s3,16
    80005924:	04c92783          	lw	a5,76(s2)
    80005928:	fcf9ede3          	bltu	s3,a5,80005902 <sys_unlink+0x140>
    8000592c:	b781                	j	8000586c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000592e:	00003517          	auipc	a0,0x3
    80005932:	f0250513          	addi	a0,a0,-254 # 80008830 <syscalls+0x2f0>
    80005936:	ffffb097          	auipc	ra,0xffffb
    8000593a:	c0a080e7          	jalr	-1014(ra) # 80000540 <panic>
    panic("unlink: writei");
    8000593e:	00003517          	auipc	a0,0x3
    80005942:	f0a50513          	addi	a0,a0,-246 # 80008848 <syscalls+0x308>
    80005946:	ffffb097          	auipc	ra,0xffffb
    8000594a:	bfa080e7          	jalr	-1030(ra) # 80000540 <panic>
    dp->nlink--;
    8000594e:	04a4d783          	lhu	a5,74(s1)
    80005952:	37fd                	addiw	a5,a5,-1
    80005954:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005958:	8526                	mv	a0,s1
    8000595a:	ffffe097          	auipc	ra,0xffffe
    8000595e:	fc4080e7          	jalr	-60(ra) # 8000391e <iupdate>
    80005962:	b781                	j	800058a2 <sys_unlink+0xe0>
    return -1;
    80005964:	557d                	li	a0,-1
    80005966:	a005                	j	80005986 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005968:	854a                	mv	a0,s2
    8000596a:	ffffe097          	auipc	ra,0xffffe
    8000596e:	2e2080e7          	jalr	738(ra) # 80003c4c <iunlockput>
  iunlockput(dp);
    80005972:	8526                	mv	a0,s1
    80005974:	ffffe097          	auipc	ra,0xffffe
    80005978:	2d8080e7          	jalr	728(ra) # 80003c4c <iunlockput>
  end_op();
    8000597c:	fffff097          	auipc	ra,0xfffff
    80005980:	ab8080e7          	jalr	-1352(ra) # 80004434 <end_op>
  return -1;
    80005984:	557d                	li	a0,-1
}
    80005986:	70ae                	ld	ra,232(sp)
    80005988:	740e                	ld	s0,224(sp)
    8000598a:	64ee                	ld	s1,216(sp)
    8000598c:	694e                	ld	s2,208(sp)
    8000598e:	69ae                	ld	s3,200(sp)
    80005990:	616d                	addi	sp,sp,240
    80005992:	8082                	ret

0000000080005994 <sys_open>:

uint64
sys_open(void)
{
    80005994:	7131                	addi	sp,sp,-192
    80005996:	fd06                	sd	ra,184(sp)
    80005998:	f922                	sd	s0,176(sp)
    8000599a:	f526                	sd	s1,168(sp)
    8000599c:	f14a                	sd	s2,160(sp)
    8000599e:	ed4e                	sd	s3,152(sp)
    800059a0:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800059a2:	f4c40593          	addi	a1,s0,-180
    800059a6:	4505                	li	a0,1
    800059a8:	ffffd097          	auipc	ra,0xffffd
    800059ac:	36c080e7          	jalr	876(ra) # 80002d14 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800059b0:	08000613          	li	a2,128
    800059b4:	f5040593          	addi	a1,s0,-176
    800059b8:	4501                	li	a0,0
    800059ba:	ffffd097          	auipc	ra,0xffffd
    800059be:	39a080e7          	jalr	922(ra) # 80002d54 <argstr>
    800059c2:	87aa                	mv	a5,a0
    return -1;
    800059c4:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800059c6:	0a07c963          	bltz	a5,80005a78 <sys_open+0xe4>

  begin_op();
    800059ca:	fffff097          	auipc	ra,0xfffff
    800059ce:	9ec080e7          	jalr	-1556(ra) # 800043b6 <begin_op>

  if(omode & O_CREATE){
    800059d2:	f4c42783          	lw	a5,-180(s0)
    800059d6:	2007f793          	andi	a5,a5,512
    800059da:	cfc5                	beqz	a5,80005a92 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800059dc:	4681                	li	a3,0
    800059de:	4601                	li	a2,0
    800059e0:	4589                	li	a1,2
    800059e2:	f5040513          	addi	a0,s0,-176
    800059e6:	00000097          	auipc	ra,0x0
    800059ea:	972080e7          	jalr	-1678(ra) # 80005358 <create>
    800059ee:	84aa                	mv	s1,a0
    if(ip == 0){
    800059f0:	c959                	beqz	a0,80005a86 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800059f2:	04449703          	lh	a4,68(s1)
    800059f6:	478d                	li	a5,3
    800059f8:	00f71763          	bne	a4,a5,80005a06 <sys_open+0x72>
    800059fc:	0464d703          	lhu	a4,70(s1)
    80005a00:	47a5                	li	a5,9
    80005a02:	0ce7ed63          	bltu	a5,a4,80005adc <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005a06:	fffff097          	auipc	ra,0xfffff
    80005a0a:	dbc080e7          	jalr	-580(ra) # 800047c2 <filealloc>
    80005a0e:	89aa                	mv	s3,a0
    80005a10:	10050363          	beqz	a0,80005b16 <sys_open+0x182>
    80005a14:	00000097          	auipc	ra,0x0
    80005a18:	902080e7          	jalr	-1790(ra) # 80005316 <fdalloc>
    80005a1c:	892a                	mv	s2,a0
    80005a1e:	0e054763          	bltz	a0,80005b0c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005a22:	04449703          	lh	a4,68(s1)
    80005a26:	478d                	li	a5,3
    80005a28:	0cf70563          	beq	a4,a5,80005af2 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005a2c:	4789                	li	a5,2
    80005a2e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005a32:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005a36:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005a3a:	f4c42783          	lw	a5,-180(s0)
    80005a3e:	0017c713          	xori	a4,a5,1
    80005a42:	8b05                	andi	a4,a4,1
    80005a44:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005a48:	0037f713          	andi	a4,a5,3
    80005a4c:	00e03733          	snez	a4,a4
    80005a50:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005a54:	4007f793          	andi	a5,a5,1024
    80005a58:	c791                	beqz	a5,80005a64 <sys_open+0xd0>
    80005a5a:	04449703          	lh	a4,68(s1)
    80005a5e:	4789                	li	a5,2
    80005a60:	0af70063          	beq	a4,a5,80005b00 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a64:	8526                	mv	a0,s1
    80005a66:	ffffe097          	auipc	ra,0xffffe
    80005a6a:	046080e7          	jalr	70(ra) # 80003aac <iunlock>
  end_op();
    80005a6e:	fffff097          	auipc	ra,0xfffff
    80005a72:	9c6080e7          	jalr	-1594(ra) # 80004434 <end_op>

  return fd;
    80005a76:	854a                	mv	a0,s2
}
    80005a78:	70ea                	ld	ra,184(sp)
    80005a7a:	744a                	ld	s0,176(sp)
    80005a7c:	74aa                	ld	s1,168(sp)
    80005a7e:	790a                	ld	s2,160(sp)
    80005a80:	69ea                	ld	s3,152(sp)
    80005a82:	6129                	addi	sp,sp,192
    80005a84:	8082                	ret
      end_op();
    80005a86:	fffff097          	auipc	ra,0xfffff
    80005a8a:	9ae080e7          	jalr	-1618(ra) # 80004434 <end_op>
      return -1;
    80005a8e:	557d                	li	a0,-1
    80005a90:	b7e5                	j	80005a78 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a92:	f5040513          	addi	a0,s0,-176
    80005a96:	ffffe097          	auipc	ra,0xffffe
    80005a9a:	700080e7          	jalr	1792(ra) # 80004196 <namei>
    80005a9e:	84aa                	mv	s1,a0
    80005aa0:	c905                	beqz	a0,80005ad0 <sys_open+0x13c>
    ilock(ip);
    80005aa2:	ffffe097          	auipc	ra,0xffffe
    80005aa6:	f48080e7          	jalr	-184(ra) # 800039ea <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005aaa:	04449703          	lh	a4,68(s1)
    80005aae:	4785                	li	a5,1
    80005ab0:	f4f711e3          	bne	a4,a5,800059f2 <sys_open+0x5e>
    80005ab4:	f4c42783          	lw	a5,-180(s0)
    80005ab8:	d7b9                	beqz	a5,80005a06 <sys_open+0x72>
      iunlockput(ip);
    80005aba:	8526                	mv	a0,s1
    80005abc:	ffffe097          	auipc	ra,0xffffe
    80005ac0:	190080e7          	jalr	400(ra) # 80003c4c <iunlockput>
      end_op();
    80005ac4:	fffff097          	auipc	ra,0xfffff
    80005ac8:	970080e7          	jalr	-1680(ra) # 80004434 <end_op>
      return -1;
    80005acc:	557d                	li	a0,-1
    80005ace:	b76d                	j	80005a78 <sys_open+0xe4>
      end_op();
    80005ad0:	fffff097          	auipc	ra,0xfffff
    80005ad4:	964080e7          	jalr	-1692(ra) # 80004434 <end_op>
      return -1;
    80005ad8:	557d                	li	a0,-1
    80005ada:	bf79                	j	80005a78 <sys_open+0xe4>
    iunlockput(ip);
    80005adc:	8526                	mv	a0,s1
    80005ade:	ffffe097          	auipc	ra,0xffffe
    80005ae2:	16e080e7          	jalr	366(ra) # 80003c4c <iunlockput>
    end_op();
    80005ae6:	fffff097          	auipc	ra,0xfffff
    80005aea:	94e080e7          	jalr	-1714(ra) # 80004434 <end_op>
    return -1;
    80005aee:	557d                	li	a0,-1
    80005af0:	b761                	j	80005a78 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005af2:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005af6:	04649783          	lh	a5,70(s1)
    80005afa:	02f99223          	sh	a5,36(s3)
    80005afe:	bf25                	j	80005a36 <sys_open+0xa2>
    itrunc(ip);
    80005b00:	8526                	mv	a0,s1
    80005b02:	ffffe097          	auipc	ra,0xffffe
    80005b06:	ff6080e7          	jalr	-10(ra) # 80003af8 <itrunc>
    80005b0a:	bfa9                	j	80005a64 <sys_open+0xd0>
      fileclose(f);
    80005b0c:	854e                	mv	a0,s3
    80005b0e:	fffff097          	auipc	ra,0xfffff
    80005b12:	d70080e7          	jalr	-656(ra) # 8000487e <fileclose>
    iunlockput(ip);
    80005b16:	8526                	mv	a0,s1
    80005b18:	ffffe097          	auipc	ra,0xffffe
    80005b1c:	134080e7          	jalr	308(ra) # 80003c4c <iunlockput>
    end_op();
    80005b20:	fffff097          	auipc	ra,0xfffff
    80005b24:	914080e7          	jalr	-1772(ra) # 80004434 <end_op>
    return -1;
    80005b28:	557d                	li	a0,-1
    80005b2a:	b7b9                	j	80005a78 <sys_open+0xe4>

0000000080005b2c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005b2c:	7175                	addi	sp,sp,-144
    80005b2e:	e506                	sd	ra,136(sp)
    80005b30:	e122                	sd	s0,128(sp)
    80005b32:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005b34:	fffff097          	auipc	ra,0xfffff
    80005b38:	882080e7          	jalr	-1918(ra) # 800043b6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005b3c:	08000613          	li	a2,128
    80005b40:	f7040593          	addi	a1,s0,-144
    80005b44:	4501                	li	a0,0
    80005b46:	ffffd097          	auipc	ra,0xffffd
    80005b4a:	20e080e7          	jalr	526(ra) # 80002d54 <argstr>
    80005b4e:	02054963          	bltz	a0,80005b80 <sys_mkdir+0x54>
    80005b52:	4681                	li	a3,0
    80005b54:	4601                	li	a2,0
    80005b56:	4585                	li	a1,1
    80005b58:	f7040513          	addi	a0,s0,-144
    80005b5c:	fffff097          	auipc	ra,0xfffff
    80005b60:	7fc080e7          	jalr	2044(ra) # 80005358 <create>
    80005b64:	cd11                	beqz	a0,80005b80 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b66:	ffffe097          	auipc	ra,0xffffe
    80005b6a:	0e6080e7          	jalr	230(ra) # 80003c4c <iunlockput>
  end_op();
    80005b6e:	fffff097          	auipc	ra,0xfffff
    80005b72:	8c6080e7          	jalr	-1850(ra) # 80004434 <end_op>
  return 0;
    80005b76:	4501                	li	a0,0
}
    80005b78:	60aa                	ld	ra,136(sp)
    80005b7a:	640a                	ld	s0,128(sp)
    80005b7c:	6149                	addi	sp,sp,144
    80005b7e:	8082                	ret
    end_op();
    80005b80:	fffff097          	auipc	ra,0xfffff
    80005b84:	8b4080e7          	jalr	-1868(ra) # 80004434 <end_op>
    return -1;
    80005b88:	557d                	li	a0,-1
    80005b8a:	b7fd                	j	80005b78 <sys_mkdir+0x4c>

0000000080005b8c <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b8c:	7135                	addi	sp,sp,-160
    80005b8e:	ed06                	sd	ra,152(sp)
    80005b90:	e922                	sd	s0,144(sp)
    80005b92:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b94:	fffff097          	auipc	ra,0xfffff
    80005b98:	822080e7          	jalr	-2014(ra) # 800043b6 <begin_op>
  argint(1, &major);
    80005b9c:	f6c40593          	addi	a1,s0,-148
    80005ba0:	4505                	li	a0,1
    80005ba2:	ffffd097          	auipc	ra,0xffffd
    80005ba6:	172080e7          	jalr	370(ra) # 80002d14 <argint>
  argint(2, &minor);
    80005baa:	f6840593          	addi	a1,s0,-152
    80005bae:	4509                	li	a0,2
    80005bb0:	ffffd097          	auipc	ra,0xffffd
    80005bb4:	164080e7          	jalr	356(ra) # 80002d14 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bb8:	08000613          	li	a2,128
    80005bbc:	f7040593          	addi	a1,s0,-144
    80005bc0:	4501                	li	a0,0
    80005bc2:	ffffd097          	auipc	ra,0xffffd
    80005bc6:	192080e7          	jalr	402(ra) # 80002d54 <argstr>
    80005bca:	02054b63          	bltz	a0,80005c00 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005bce:	f6841683          	lh	a3,-152(s0)
    80005bd2:	f6c41603          	lh	a2,-148(s0)
    80005bd6:	458d                	li	a1,3
    80005bd8:	f7040513          	addi	a0,s0,-144
    80005bdc:	fffff097          	auipc	ra,0xfffff
    80005be0:	77c080e7          	jalr	1916(ra) # 80005358 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005be4:	cd11                	beqz	a0,80005c00 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005be6:	ffffe097          	auipc	ra,0xffffe
    80005bea:	066080e7          	jalr	102(ra) # 80003c4c <iunlockput>
  end_op();
    80005bee:	fffff097          	auipc	ra,0xfffff
    80005bf2:	846080e7          	jalr	-1978(ra) # 80004434 <end_op>
  return 0;
    80005bf6:	4501                	li	a0,0
}
    80005bf8:	60ea                	ld	ra,152(sp)
    80005bfa:	644a                	ld	s0,144(sp)
    80005bfc:	610d                	addi	sp,sp,160
    80005bfe:	8082                	ret
    end_op();
    80005c00:	fffff097          	auipc	ra,0xfffff
    80005c04:	834080e7          	jalr	-1996(ra) # 80004434 <end_op>
    return -1;
    80005c08:	557d                	li	a0,-1
    80005c0a:	b7fd                	j	80005bf8 <sys_mknod+0x6c>

0000000080005c0c <sys_chdir>:

uint64
sys_chdir(void)
{
    80005c0c:	7135                	addi	sp,sp,-160
    80005c0e:	ed06                	sd	ra,152(sp)
    80005c10:	e922                	sd	s0,144(sp)
    80005c12:	e526                	sd	s1,136(sp)
    80005c14:	e14a                	sd	s2,128(sp)
    80005c16:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c18:	ffffc097          	auipc	ra,0xffffc
    80005c1c:	d94080e7          	jalr	-620(ra) # 800019ac <myproc>
    80005c20:	892a                	mv	s2,a0
  
  begin_op();
    80005c22:	ffffe097          	auipc	ra,0xffffe
    80005c26:	794080e7          	jalr	1940(ra) # 800043b6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005c2a:	08000613          	li	a2,128
    80005c2e:	f6040593          	addi	a1,s0,-160
    80005c32:	4501                	li	a0,0
    80005c34:	ffffd097          	auipc	ra,0xffffd
    80005c38:	120080e7          	jalr	288(ra) # 80002d54 <argstr>
    80005c3c:	04054b63          	bltz	a0,80005c92 <sys_chdir+0x86>
    80005c40:	f6040513          	addi	a0,s0,-160
    80005c44:	ffffe097          	auipc	ra,0xffffe
    80005c48:	552080e7          	jalr	1362(ra) # 80004196 <namei>
    80005c4c:	84aa                	mv	s1,a0
    80005c4e:	c131                	beqz	a0,80005c92 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005c50:	ffffe097          	auipc	ra,0xffffe
    80005c54:	d9a080e7          	jalr	-614(ra) # 800039ea <ilock>
  if(ip->type != T_DIR){
    80005c58:	04449703          	lh	a4,68(s1)
    80005c5c:	4785                	li	a5,1
    80005c5e:	04f71063          	bne	a4,a5,80005c9e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c62:	8526                	mv	a0,s1
    80005c64:	ffffe097          	auipc	ra,0xffffe
    80005c68:	e48080e7          	jalr	-440(ra) # 80003aac <iunlock>
  iput(p->cwd);
    80005c6c:	15093503          	ld	a0,336(s2)
    80005c70:	ffffe097          	auipc	ra,0xffffe
    80005c74:	f34080e7          	jalr	-204(ra) # 80003ba4 <iput>
  end_op();
    80005c78:	ffffe097          	auipc	ra,0xffffe
    80005c7c:	7bc080e7          	jalr	1980(ra) # 80004434 <end_op>
  p->cwd = ip;
    80005c80:	14993823          	sd	s1,336(s2)
  return 0;
    80005c84:	4501                	li	a0,0
}
    80005c86:	60ea                	ld	ra,152(sp)
    80005c88:	644a                	ld	s0,144(sp)
    80005c8a:	64aa                	ld	s1,136(sp)
    80005c8c:	690a                	ld	s2,128(sp)
    80005c8e:	610d                	addi	sp,sp,160
    80005c90:	8082                	ret
    end_op();
    80005c92:	ffffe097          	auipc	ra,0xffffe
    80005c96:	7a2080e7          	jalr	1954(ra) # 80004434 <end_op>
    return -1;
    80005c9a:	557d                	li	a0,-1
    80005c9c:	b7ed                	j	80005c86 <sys_chdir+0x7a>
    iunlockput(ip);
    80005c9e:	8526                	mv	a0,s1
    80005ca0:	ffffe097          	auipc	ra,0xffffe
    80005ca4:	fac080e7          	jalr	-84(ra) # 80003c4c <iunlockput>
    end_op();
    80005ca8:	ffffe097          	auipc	ra,0xffffe
    80005cac:	78c080e7          	jalr	1932(ra) # 80004434 <end_op>
    return -1;
    80005cb0:	557d                	li	a0,-1
    80005cb2:	bfd1                	j	80005c86 <sys_chdir+0x7a>

0000000080005cb4 <sys_exec>:

uint64
sys_exec(void)
{
    80005cb4:	7145                	addi	sp,sp,-464
    80005cb6:	e786                	sd	ra,456(sp)
    80005cb8:	e3a2                	sd	s0,448(sp)
    80005cba:	ff26                	sd	s1,440(sp)
    80005cbc:	fb4a                	sd	s2,432(sp)
    80005cbe:	f74e                	sd	s3,424(sp)
    80005cc0:	f352                	sd	s4,416(sp)
    80005cc2:	ef56                	sd	s5,408(sp)
    80005cc4:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005cc6:	e3840593          	addi	a1,s0,-456
    80005cca:	4505                	li	a0,1
    80005ccc:	ffffd097          	auipc	ra,0xffffd
    80005cd0:	068080e7          	jalr	104(ra) # 80002d34 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005cd4:	08000613          	li	a2,128
    80005cd8:	f4040593          	addi	a1,s0,-192
    80005cdc:	4501                	li	a0,0
    80005cde:	ffffd097          	auipc	ra,0xffffd
    80005ce2:	076080e7          	jalr	118(ra) # 80002d54 <argstr>
    80005ce6:	87aa                	mv	a5,a0
    return -1;
    80005ce8:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005cea:	0c07c363          	bltz	a5,80005db0 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005cee:	10000613          	li	a2,256
    80005cf2:	4581                	li	a1,0
    80005cf4:	e4040513          	addi	a0,s0,-448
    80005cf8:	ffffb097          	auipc	ra,0xffffb
    80005cfc:	fda080e7          	jalr	-38(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005d00:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005d04:	89a6                	mv	s3,s1
    80005d06:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005d08:	02000a13          	li	s4,32
    80005d0c:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005d10:	00391513          	slli	a0,s2,0x3
    80005d14:	e3040593          	addi	a1,s0,-464
    80005d18:	e3843783          	ld	a5,-456(s0)
    80005d1c:	953e                	add	a0,a0,a5
    80005d1e:	ffffd097          	auipc	ra,0xffffd
    80005d22:	f58080e7          	jalr	-168(ra) # 80002c76 <fetchaddr>
    80005d26:	02054a63          	bltz	a0,80005d5a <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005d2a:	e3043783          	ld	a5,-464(s0)
    80005d2e:	c3b9                	beqz	a5,80005d74 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005d30:	ffffb097          	auipc	ra,0xffffb
    80005d34:	db6080e7          	jalr	-586(ra) # 80000ae6 <kalloc>
    80005d38:	85aa                	mv	a1,a0
    80005d3a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005d3e:	cd11                	beqz	a0,80005d5a <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005d40:	6605                	lui	a2,0x1
    80005d42:	e3043503          	ld	a0,-464(s0)
    80005d46:	ffffd097          	auipc	ra,0xffffd
    80005d4a:	f82080e7          	jalr	-126(ra) # 80002cc8 <fetchstr>
    80005d4e:	00054663          	bltz	a0,80005d5a <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005d52:	0905                	addi	s2,s2,1
    80005d54:	09a1                	addi	s3,s3,8
    80005d56:	fb491be3          	bne	s2,s4,80005d0c <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d5a:	f4040913          	addi	s2,s0,-192
    80005d5e:	6088                	ld	a0,0(s1)
    80005d60:	c539                	beqz	a0,80005dae <sys_exec+0xfa>
    kfree(argv[i]);
    80005d62:	ffffb097          	auipc	ra,0xffffb
    80005d66:	c86080e7          	jalr	-890(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d6a:	04a1                	addi	s1,s1,8
    80005d6c:	ff2499e3          	bne	s1,s2,80005d5e <sys_exec+0xaa>
  return -1;
    80005d70:	557d                	li	a0,-1
    80005d72:	a83d                	j	80005db0 <sys_exec+0xfc>
      argv[i] = 0;
    80005d74:	0a8e                	slli	s5,s5,0x3
    80005d76:	fc0a8793          	addi	a5,s5,-64
    80005d7a:	00878ab3          	add	s5,a5,s0
    80005d7e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005d82:	e4040593          	addi	a1,s0,-448
    80005d86:	f4040513          	addi	a0,s0,-192
    80005d8a:	fffff097          	auipc	ra,0xfffff
    80005d8e:	16e080e7          	jalr	366(ra) # 80004ef8 <exec>
    80005d92:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d94:	f4040993          	addi	s3,s0,-192
    80005d98:	6088                	ld	a0,0(s1)
    80005d9a:	c901                	beqz	a0,80005daa <sys_exec+0xf6>
    kfree(argv[i]);
    80005d9c:	ffffb097          	auipc	ra,0xffffb
    80005da0:	c4c080e7          	jalr	-948(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005da4:	04a1                	addi	s1,s1,8
    80005da6:	ff3499e3          	bne	s1,s3,80005d98 <sys_exec+0xe4>
  return ret;
    80005daa:	854a                	mv	a0,s2
    80005dac:	a011                	j	80005db0 <sys_exec+0xfc>
  return -1;
    80005dae:	557d                	li	a0,-1
}
    80005db0:	60be                	ld	ra,456(sp)
    80005db2:	641e                	ld	s0,448(sp)
    80005db4:	74fa                	ld	s1,440(sp)
    80005db6:	795a                	ld	s2,432(sp)
    80005db8:	79ba                	ld	s3,424(sp)
    80005dba:	7a1a                	ld	s4,416(sp)
    80005dbc:	6afa                	ld	s5,408(sp)
    80005dbe:	6179                	addi	sp,sp,464
    80005dc0:	8082                	ret

0000000080005dc2 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005dc2:	7139                	addi	sp,sp,-64
    80005dc4:	fc06                	sd	ra,56(sp)
    80005dc6:	f822                	sd	s0,48(sp)
    80005dc8:	f426                	sd	s1,40(sp)
    80005dca:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005dcc:	ffffc097          	auipc	ra,0xffffc
    80005dd0:	be0080e7          	jalr	-1056(ra) # 800019ac <myproc>
    80005dd4:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005dd6:	fd840593          	addi	a1,s0,-40
    80005dda:	4501                	li	a0,0
    80005ddc:	ffffd097          	auipc	ra,0xffffd
    80005de0:	f58080e7          	jalr	-168(ra) # 80002d34 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005de4:	fc840593          	addi	a1,s0,-56
    80005de8:	fd040513          	addi	a0,s0,-48
    80005dec:	fffff097          	auipc	ra,0xfffff
    80005df0:	dc2080e7          	jalr	-574(ra) # 80004bae <pipealloc>
    return -1;
    80005df4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005df6:	0c054463          	bltz	a0,80005ebe <sys_pipe+0xfc>
  fd0 = -1;
    80005dfa:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005dfe:	fd043503          	ld	a0,-48(s0)
    80005e02:	fffff097          	auipc	ra,0xfffff
    80005e06:	514080e7          	jalr	1300(ra) # 80005316 <fdalloc>
    80005e0a:	fca42223          	sw	a0,-60(s0)
    80005e0e:	08054b63          	bltz	a0,80005ea4 <sys_pipe+0xe2>
    80005e12:	fc843503          	ld	a0,-56(s0)
    80005e16:	fffff097          	auipc	ra,0xfffff
    80005e1a:	500080e7          	jalr	1280(ra) # 80005316 <fdalloc>
    80005e1e:	fca42023          	sw	a0,-64(s0)
    80005e22:	06054863          	bltz	a0,80005e92 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e26:	4691                	li	a3,4
    80005e28:	fc440613          	addi	a2,s0,-60
    80005e2c:	fd843583          	ld	a1,-40(s0)
    80005e30:	68a8                	ld	a0,80(s1)
    80005e32:	ffffc097          	auipc	ra,0xffffc
    80005e36:	83a080e7          	jalr	-1990(ra) # 8000166c <copyout>
    80005e3a:	02054063          	bltz	a0,80005e5a <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005e3e:	4691                	li	a3,4
    80005e40:	fc040613          	addi	a2,s0,-64
    80005e44:	fd843583          	ld	a1,-40(s0)
    80005e48:	0591                	addi	a1,a1,4
    80005e4a:	68a8                	ld	a0,80(s1)
    80005e4c:	ffffc097          	auipc	ra,0xffffc
    80005e50:	820080e7          	jalr	-2016(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e54:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e56:	06055463          	bgez	a0,80005ebe <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005e5a:	fc442783          	lw	a5,-60(s0)
    80005e5e:	07e9                	addi	a5,a5,26
    80005e60:	078e                	slli	a5,a5,0x3
    80005e62:	97a6                	add	a5,a5,s1
    80005e64:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005e68:	fc042783          	lw	a5,-64(s0)
    80005e6c:	07e9                	addi	a5,a5,26
    80005e6e:	078e                	slli	a5,a5,0x3
    80005e70:	94be                	add	s1,s1,a5
    80005e72:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005e76:	fd043503          	ld	a0,-48(s0)
    80005e7a:	fffff097          	auipc	ra,0xfffff
    80005e7e:	a04080e7          	jalr	-1532(ra) # 8000487e <fileclose>
    fileclose(wf);
    80005e82:	fc843503          	ld	a0,-56(s0)
    80005e86:	fffff097          	auipc	ra,0xfffff
    80005e8a:	9f8080e7          	jalr	-1544(ra) # 8000487e <fileclose>
    return -1;
    80005e8e:	57fd                	li	a5,-1
    80005e90:	a03d                	j	80005ebe <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005e92:	fc442783          	lw	a5,-60(s0)
    80005e96:	0007c763          	bltz	a5,80005ea4 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005e9a:	07e9                	addi	a5,a5,26
    80005e9c:	078e                	slli	a5,a5,0x3
    80005e9e:	97a6                	add	a5,a5,s1
    80005ea0:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005ea4:	fd043503          	ld	a0,-48(s0)
    80005ea8:	fffff097          	auipc	ra,0xfffff
    80005eac:	9d6080e7          	jalr	-1578(ra) # 8000487e <fileclose>
    fileclose(wf);
    80005eb0:	fc843503          	ld	a0,-56(s0)
    80005eb4:	fffff097          	auipc	ra,0xfffff
    80005eb8:	9ca080e7          	jalr	-1590(ra) # 8000487e <fileclose>
    return -1;
    80005ebc:	57fd                	li	a5,-1
}
    80005ebe:	853e                	mv	a0,a5
    80005ec0:	70e2                	ld	ra,56(sp)
    80005ec2:	7442                	ld	s0,48(sp)
    80005ec4:	74a2                	ld	s1,40(sp)
    80005ec6:	6121                	addi	sp,sp,64
    80005ec8:	8082                	ret
    80005eca:	0000                	unimp
    80005ecc:	0000                	unimp
	...

0000000080005ed0 <kernelvec>:
    80005ed0:	7111                	addi	sp,sp,-256
    80005ed2:	e006                	sd	ra,0(sp)
    80005ed4:	e40a                	sd	sp,8(sp)
    80005ed6:	e80e                	sd	gp,16(sp)
    80005ed8:	ec12                	sd	tp,24(sp)
    80005eda:	f016                	sd	t0,32(sp)
    80005edc:	f41a                	sd	t1,40(sp)
    80005ede:	f81e                	sd	t2,48(sp)
    80005ee0:	fc22                	sd	s0,56(sp)
    80005ee2:	e0a6                	sd	s1,64(sp)
    80005ee4:	e4aa                	sd	a0,72(sp)
    80005ee6:	e8ae                	sd	a1,80(sp)
    80005ee8:	ecb2                	sd	a2,88(sp)
    80005eea:	f0b6                	sd	a3,96(sp)
    80005eec:	f4ba                	sd	a4,104(sp)
    80005eee:	f8be                	sd	a5,112(sp)
    80005ef0:	fcc2                	sd	a6,120(sp)
    80005ef2:	e146                	sd	a7,128(sp)
    80005ef4:	e54a                	sd	s2,136(sp)
    80005ef6:	e94e                	sd	s3,144(sp)
    80005ef8:	ed52                	sd	s4,152(sp)
    80005efa:	f156                	sd	s5,160(sp)
    80005efc:	f55a                	sd	s6,168(sp)
    80005efe:	f95e                	sd	s7,176(sp)
    80005f00:	fd62                	sd	s8,184(sp)
    80005f02:	e1e6                	sd	s9,192(sp)
    80005f04:	e5ea                	sd	s10,200(sp)
    80005f06:	e9ee                	sd	s11,208(sp)
    80005f08:	edf2                	sd	t3,216(sp)
    80005f0a:	f1f6                	sd	t4,224(sp)
    80005f0c:	f5fa                	sd	t5,232(sp)
    80005f0e:	f9fe                	sd	t6,240(sp)
    80005f10:	c5dfc0ef          	jal	ra,80002b6c <kerneltrap>
    80005f14:	6082                	ld	ra,0(sp)
    80005f16:	6122                	ld	sp,8(sp)
    80005f18:	61c2                	ld	gp,16(sp)
    80005f1a:	7282                	ld	t0,32(sp)
    80005f1c:	7322                	ld	t1,40(sp)
    80005f1e:	73c2                	ld	t2,48(sp)
    80005f20:	7462                	ld	s0,56(sp)
    80005f22:	6486                	ld	s1,64(sp)
    80005f24:	6526                	ld	a0,72(sp)
    80005f26:	65c6                	ld	a1,80(sp)
    80005f28:	6666                	ld	a2,88(sp)
    80005f2a:	7686                	ld	a3,96(sp)
    80005f2c:	7726                	ld	a4,104(sp)
    80005f2e:	77c6                	ld	a5,112(sp)
    80005f30:	7866                	ld	a6,120(sp)
    80005f32:	688a                	ld	a7,128(sp)
    80005f34:	692a                	ld	s2,136(sp)
    80005f36:	69ca                	ld	s3,144(sp)
    80005f38:	6a6a                	ld	s4,152(sp)
    80005f3a:	7a8a                	ld	s5,160(sp)
    80005f3c:	7b2a                	ld	s6,168(sp)
    80005f3e:	7bca                	ld	s7,176(sp)
    80005f40:	7c6a                	ld	s8,184(sp)
    80005f42:	6c8e                	ld	s9,192(sp)
    80005f44:	6d2e                	ld	s10,200(sp)
    80005f46:	6dce                	ld	s11,208(sp)
    80005f48:	6e6e                	ld	t3,216(sp)
    80005f4a:	7e8e                	ld	t4,224(sp)
    80005f4c:	7f2e                	ld	t5,232(sp)
    80005f4e:	7fce                	ld	t6,240(sp)
    80005f50:	6111                	addi	sp,sp,256
    80005f52:	10200073          	sret
    80005f56:	00000013          	nop
    80005f5a:	00000013          	nop
    80005f5e:	0001                	nop

0000000080005f60 <timervec>:
    80005f60:	34051573          	csrrw	a0,mscratch,a0
    80005f64:	e10c                	sd	a1,0(a0)
    80005f66:	e510                	sd	a2,8(a0)
    80005f68:	e914                	sd	a3,16(a0)
    80005f6a:	6d0c                	ld	a1,24(a0)
    80005f6c:	7110                	ld	a2,32(a0)
    80005f6e:	6194                	ld	a3,0(a1)
    80005f70:	96b2                	add	a3,a3,a2
    80005f72:	e194                	sd	a3,0(a1)
    80005f74:	4589                	li	a1,2
    80005f76:	14459073          	csrw	sip,a1
    80005f7a:	6914                	ld	a3,16(a0)
    80005f7c:	6510                	ld	a2,8(a0)
    80005f7e:	610c                	ld	a1,0(a0)
    80005f80:	34051573          	csrrw	a0,mscratch,a0
    80005f84:	30200073          	mret
	...

0000000080005f8a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f8a:	1141                	addi	sp,sp,-16
    80005f8c:	e422                	sd	s0,8(sp)
    80005f8e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f90:	0c0007b7          	lui	a5,0xc000
    80005f94:	4705                	li	a4,1
    80005f96:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f98:	c3d8                	sw	a4,4(a5)
}
    80005f9a:	6422                	ld	s0,8(sp)
    80005f9c:	0141                	addi	sp,sp,16
    80005f9e:	8082                	ret

0000000080005fa0 <plicinithart>:

void
plicinithart(void)
{
    80005fa0:	1141                	addi	sp,sp,-16
    80005fa2:	e406                	sd	ra,8(sp)
    80005fa4:	e022                	sd	s0,0(sp)
    80005fa6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fa8:	ffffc097          	auipc	ra,0xffffc
    80005fac:	9d8080e7          	jalr	-1576(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005fb0:	0085171b          	slliw	a4,a0,0x8
    80005fb4:	0c0027b7          	lui	a5,0xc002
    80005fb8:	97ba                	add	a5,a5,a4
    80005fba:	40200713          	li	a4,1026
    80005fbe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005fc2:	00d5151b          	slliw	a0,a0,0xd
    80005fc6:	0c2017b7          	lui	a5,0xc201
    80005fca:	97aa                	add	a5,a5,a0
    80005fcc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005fd0:	60a2                	ld	ra,8(sp)
    80005fd2:	6402                	ld	s0,0(sp)
    80005fd4:	0141                	addi	sp,sp,16
    80005fd6:	8082                	ret

0000000080005fd8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005fd8:	1141                	addi	sp,sp,-16
    80005fda:	e406                	sd	ra,8(sp)
    80005fdc:	e022                	sd	s0,0(sp)
    80005fde:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fe0:	ffffc097          	auipc	ra,0xffffc
    80005fe4:	9a0080e7          	jalr	-1632(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005fe8:	00d5151b          	slliw	a0,a0,0xd
    80005fec:	0c2017b7          	lui	a5,0xc201
    80005ff0:	97aa                	add	a5,a5,a0
  return irq;
}
    80005ff2:	43c8                	lw	a0,4(a5)
    80005ff4:	60a2                	ld	ra,8(sp)
    80005ff6:	6402                	ld	s0,0(sp)
    80005ff8:	0141                	addi	sp,sp,16
    80005ffa:	8082                	ret

0000000080005ffc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005ffc:	1101                	addi	sp,sp,-32
    80005ffe:	ec06                	sd	ra,24(sp)
    80006000:	e822                	sd	s0,16(sp)
    80006002:	e426                	sd	s1,8(sp)
    80006004:	1000                	addi	s0,sp,32
    80006006:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006008:	ffffc097          	auipc	ra,0xffffc
    8000600c:	978080e7          	jalr	-1672(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006010:	00d5151b          	slliw	a0,a0,0xd
    80006014:	0c2017b7          	lui	a5,0xc201
    80006018:	97aa                	add	a5,a5,a0
    8000601a:	c3c4                	sw	s1,4(a5)
}
    8000601c:	60e2                	ld	ra,24(sp)
    8000601e:	6442                	ld	s0,16(sp)
    80006020:	64a2                	ld	s1,8(sp)
    80006022:	6105                	addi	sp,sp,32
    80006024:	8082                	ret

0000000080006026 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006026:	1141                	addi	sp,sp,-16
    80006028:	e406                	sd	ra,8(sp)
    8000602a:	e022                	sd	s0,0(sp)
    8000602c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000602e:	479d                	li	a5,7
    80006030:	04a7cc63          	blt	a5,a0,80006088 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006034:	0001d797          	auipc	a5,0x1d
    80006038:	ffc78793          	addi	a5,a5,-4 # 80023030 <disk>
    8000603c:	97aa                	add	a5,a5,a0
    8000603e:	0187c783          	lbu	a5,24(a5)
    80006042:	ebb9                	bnez	a5,80006098 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006044:	00451693          	slli	a3,a0,0x4
    80006048:	0001d797          	auipc	a5,0x1d
    8000604c:	fe878793          	addi	a5,a5,-24 # 80023030 <disk>
    80006050:	6398                	ld	a4,0(a5)
    80006052:	9736                	add	a4,a4,a3
    80006054:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006058:	6398                	ld	a4,0(a5)
    8000605a:	9736                	add	a4,a4,a3
    8000605c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006060:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006064:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006068:	97aa                	add	a5,a5,a0
    8000606a:	4705                	li	a4,1
    8000606c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006070:	0001d517          	auipc	a0,0x1d
    80006074:	fd850513          	addi	a0,a0,-40 # 80023048 <disk+0x18>
    80006078:	ffffc097          	auipc	ra,0xffffc
    8000607c:	190080e7          	jalr	400(ra) # 80002208 <wakeup>
}
    80006080:	60a2                	ld	ra,8(sp)
    80006082:	6402                	ld	s0,0(sp)
    80006084:	0141                	addi	sp,sp,16
    80006086:	8082                	ret
    panic("free_desc 1");
    80006088:	00002517          	auipc	a0,0x2
    8000608c:	7d050513          	addi	a0,a0,2000 # 80008858 <syscalls+0x318>
    80006090:	ffffa097          	auipc	ra,0xffffa
    80006094:	4b0080e7          	jalr	1200(ra) # 80000540 <panic>
    panic("free_desc 2");
    80006098:	00002517          	auipc	a0,0x2
    8000609c:	7d050513          	addi	a0,a0,2000 # 80008868 <syscalls+0x328>
    800060a0:	ffffa097          	auipc	ra,0xffffa
    800060a4:	4a0080e7          	jalr	1184(ra) # 80000540 <panic>

00000000800060a8 <virtio_disk_init>:
{
    800060a8:	1101                	addi	sp,sp,-32
    800060aa:	ec06                	sd	ra,24(sp)
    800060ac:	e822                	sd	s0,16(sp)
    800060ae:	e426                	sd	s1,8(sp)
    800060b0:	e04a                	sd	s2,0(sp)
    800060b2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800060b4:	00002597          	auipc	a1,0x2
    800060b8:	7c458593          	addi	a1,a1,1988 # 80008878 <syscalls+0x338>
    800060bc:	0001d517          	auipc	a0,0x1d
    800060c0:	09c50513          	addi	a0,a0,156 # 80023158 <disk+0x128>
    800060c4:	ffffb097          	auipc	ra,0xffffb
    800060c8:	a82080e7          	jalr	-1406(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060cc:	100017b7          	lui	a5,0x10001
    800060d0:	4398                	lw	a4,0(a5)
    800060d2:	2701                	sext.w	a4,a4
    800060d4:	747277b7          	lui	a5,0x74727
    800060d8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800060dc:	14f71b63          	bne	a4,a5,80006232 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800060e0:	100017b7          	lui	a5,0x10001
    800060e4:	43dc                	lw	a5,4(a5)
    800060e6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060e8:	4709                	li	a4,2
    800060ea:	14e79463          	bne	a5,a4,80006232 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060ee:	100017b7          	lui	a5,0x10001
    800060f2:	479c                	lw	a5,8(a5)
    800060f4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800060f6:	12e79e63          	bne	a5,a4,80006232 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800060fa:	100017b7          	lui	a5,0x10001
    800060fe:	47d8                	lw	a4,12(a5)
    80006100:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006102:	554d47b7          	lui	a5,0x554d4
    80006106:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000610a:	12f71463          	bne	a4,a5,80006232 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000610e:	100017b7          	lui	a5,0x10001
    80006112:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006116:	4705                	li	a4,1
    80006118:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000611a:	470d                	li	a4,3
    8000611c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000611e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006120:	c7ffe6b7          	lui	a3,0xc7ffe
    80006124:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fda26f>
    80006128:	8f75                	and	a4,a4,a3
    8000612a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000612c:	472d                	li	a4,11
    8000612e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006130:	5bbc                	lw	a5,112(a5)
    80006132:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006136:	8ba1                	andi	a5,a5,8
    80006138:	10078563          	beqz	a5,80006242 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000613c:	100017b7          	lui	a5,0x10001
    80006140:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006144:	43fc                	lw	a5,68(a5)
    80006146:	2781                	sext.w	a5,a5
    80006148:	10079563          	bnez	a5,80006252 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000614c:	100017b7          	lui	a5,0x10001
    80006150:	5bdc                	lw	a5,52(a5)
    80006152:	2781                	sext.w	a5,a5
  if(max == 0)
    80006154:	10078763          	beqz	a5,80006262 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006158:	471d                	li	a4,7
    8000615a:	10f77c63          	bgeu	a4,a5,80006272 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000615e:	ffffb097          	auipc	ra,0xffffb
    80006162:	988080e7          	jalr	-1656(ra) # 80000ae6 <kalloc>
    80006166:	0001d497          	auipc	s1,0x1d
    8000616a:	eca48493          	addi	s1,s1,-310 # 80023030 <disk>
    8000616e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006170:	ffffb097          	auipc	ra,0xffffb
    80006174:	976080e7          	jalr	-1674(ra) # 80000ae6 <kalloc>
    80006178:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000617a:	ffffb097          	auipc	ra,0xffffb
    8000617e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80006182:	87aa                	mv	a5,a0
    80006184:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006186:	6088                	ld	a0,0(s1)
    80006188:	cd6d                	beqz	a0,80006282 <virtio_disk_init+0x1da>
    8000618a:	0001d717          	auipc	a4,0x1d
    8000618e:	eae73703          	ld	a4,-338(a4) # 80023038 <disk+0x8>
    80006192:	cb65                	beqz	a4,80006282 <virtio_disk_init+0x1da>
    80006194:	c7fd                	beqz	a5,80006282 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006196:	6605                	lui	a2,0x1
    80006198:	4581                	li	a1,0
    8000619a:	ffffb097          	auipc	ra,0xffffb
    8000619e:	b38080e7          	jalr	-1224(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    800061a2:	0001d497          	auipc	s1,0x1d
    800061a6:	e8e48493          	addi	s1,s1,-370 # 80023030 <disk>
    800061aa:	6605                	lui	a2,0x1
    800061ac:	4581                	li	a1,0
    800061ae:	6488                	ld	a0,8(s1)
    800061b0:	ffffb097          	auipc	ra,0xffffb
    800061b4:	b22080e7          	jalr	-1246(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    800061b8:	6605                	lui	a2,0x1
    800061ba:	4581                	li	a1,0
    800061bc:	6888                	ld	a0,16(s1)
    800061be:	ffffb097          	auipc	ra,0xffffb
    800061c2:	b14080e7          	jalr	-1260(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800061c6:	100017b7          	lui	a5,0x10001
    800061ca:	4721                	li	a4,8
    800061cc:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800061ce:	4098                	lw	a4,0(s1)
    800061d0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800061d4:	40d8                	lw	a4,4(s1)
    800061d6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800061da:	6498                	ld	a4,8(s1)
    800061dc:	0007069b          	sext.w	a3,a4
    800061e0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800061e4:	9701                	srai	a4,a4,0x20
    800061e6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800061ea:	6898                	ld	a4,16(s1)
    800061ec:	0007069b          	sext.w	a3,a4
    800061f0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800061f4:	9701                	srai	a4,a4,0x20
    800061f6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800061fa:	4705                	li	a4,1
    800061fc:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800061fe:	00e48c23          	sb	a4,24(s1)
    80006202:	00e48ca3          	sb	a4,25(s1)
    80006206:	00e48d23          	sb	a4,26(s1)
    8000620a:	00e48da3          	sb	a4,27(s1)
    8000620e:	00e48e23          	sb	a4,28(s1)
    80006212:	00e48ea3          	sb	a4,29(s1)
    80006216:	00e48f23          	sb	a4,30(s1)
    8000621a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000621e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006222:	0727a823          	sw	s2,112(a5)
}
    80006226:	60e2                	ld	ra,24(sp)
    80006228:	6442                	ld	s0,16(sp)
    8000622a:	64a2                	ld	s1,8(sp)
    8000622c:	6902                	ld	s2,0(sp)
    8000622e:	6105                	addi	sp,sp,32
    80006230:	8082                	ret
    panic("could not find virtio disk");
    80006232:	00002517          	auipc	a0,0x2
    80006236:	65650513          	addi	a0,a0,1622 # 80008888 <syscalls+0x348>
    8000623a:	ffffa097          	auipc	ra,0xffffa
    8000623e:	306080e7          	jalr	774(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006242:	00002517          	auipc	a0,0x2
    80006246:	66650513          	addi	a0,a0,1638 # 800088a8 <syscalls+0x368>
    8000624a:	ffffa097          	auipc	ra,0xffffa
    8000624e:	2f6080e7          	jalr	758(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006252:	00002517          	auipc	a0,0x2
    80006256:	67650513          	addi	a0,a0,1654 # 800088c8 <syscalls+0x388>
    8000625a:	ffffa097          	auipc	ra,0xffffa
    8000625e:	2e6080e7          	jalr	742(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006262:	00002517          	auipc	a0,0x2
    80006266:	68650513          	addi	a0,a0,1670 # 800088e8 <syscalls+0x3a8>
    8000626a:	ffffa097          	auipc	ra,0xffffa
    8000626e:	2d6080e7          	jalr	726(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006272:	00002517          	auipc	a0,0x2
    80006276:	69650513          	addi	a0,a0,1686 # 80008908 <syscalls+0x3c8>
    8000627a:	ffffa097          	auipc	ra,0xffffa
    8000627e:	2c6080e7          	jalr	710(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006282:	00002517          	auipc	a0,0x2
    80006286:	6a650513          	addi	a0,a0,1702 # 80008928 <syscalls+0x3e8>
    8000628a:	ffffa097          	auipc	ra,0xffffa
    8000628e:	2b6080e7          	jalr	694(ra) # 80000540 <panic>

0000000080006292 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006292:	7119                	addi	sp,sp,-128
    80006294:	fc86                	sd	ra,120(sp)
    80006296:	f8a2                	sd	s0,112(sp)
    80006298:	f4a6                	sd	s1,104(sp)
    8000629a:	f0ca                	sd	s2,96(sp)
    8000629c:	ecce                	sd	s3,88(sp)
    8000629e:	e8d2                	sd	s4,80(sp)
    800062a0:	e4d6                	sd	s5,72(sp)
    800062a2:	e0da                	sd	s6,64(sp)
    800062a4:	fc5e                	sd	s7,56(sp)
    800062a6:	f862                	sd	s8,48(sp)
    800062a8:	f466                	sd	s9,40(sp)
    800062aa:	f06a                	sd	s10,32(sp)
    800062ac:	ec6e                	sd	s11,24(sp)
    800062ae:	0100                	addi	s0,sp,128
    800062b0:	8aaa                	mv	s5,a0
    800062b2:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800062b4:	00c52d03          	lw	s10,12(a0)
    800062b8:	001d1d1b          	slliw	s10,s10,0x1
    800062bc:	1d02                	slli	s10,s10,0x20
    800062be:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800062c2:	0001d517          	auipc	a0,0x1d
    800062c6:	e9650513          	addi	a0,a0,-362 # 80023158 <disk+0x128>
    800062ca:	ffffb097          	auipc	ra,0xffffb
    800062ce:	90c080e7          	jalr	-1780(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    800062d2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800062d4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800062d6:	0001db97          	auipc	s7,0x1d
    800062da:	d5ab8b93          	addi	s7,s7,-678 # 80023030 <disk>
  for(int i = 0; i < 3; i++){
    800062de:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800062e0:	0001dc97          	auipc	s9,0x1d
    800062e4:	e78c8c93          	addi	s9,s9,-392 # 80023158 <disk+0x128>
    800062e8:	a08d                	j	8000634a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800062ea:	00fb8733          	add	a4,s7,a5
    800062ee:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800062f2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800062f4:	0207c563          	bltz	a5,8000631e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800062f8:	2905                	addiw	s2,s2,1
    800062fa:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    800062fc:	05690c63          	beq	s2,s6,80006354 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006300:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006302:	0001d717          	auipc	a4,0x1d
    80006306:	d2e70713          	addi	a4,a4,-722 # 80023030 <disk>
    8000630a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000630c:	01874683          	lbu	a3,24(a4)
    80006310:	fee9                	bnez	a3,800062ea <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006312:	2785                	addiw	a5,a5,1
    80006314:	0705                	addi	a4,a4,1
    80006316:	fe979be3          	bne	a5,s1,8000630c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000631a:	57fd                	li	a5,-1
    8000631c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000631e:	01205d63          	blez	s2,80006338 <virtio_disk_rw+0xa6>
    80006322:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006324:	000a2503          	lw	a0,0(s4)
    80006328:	00000097          	auipc	ra,0x0
    8000632c:	cfe080e7          	jalr	-770(ra) # 80006026 <free_desc>
      for(int j = 0; j < i; j++)
    80006330:	2d85                	addiw	s11,s11,1
    80006332:	0a11                	addi	s4,s4,4
    80006334:	ff2d98e3          	bne	s11,s2,80006324 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006338:	85e6                	mv	a1,s9
    8000633a:	0001d517          	auipc	a0,0x1d
    8000633e:	d0e50513          	addi	a0,a0,-754 # 80023048 <disk+0x18>
    80006342:	ffffc097          	auipc	ra,0xffffc
    80006346:	e62080e7          	jalr	-414(ra) # 800021a4 <sleep>
  for(int i = 0; i < 3; i++){
    8000634a:	f8040a13          	addi	s4,s0,-128
{
    8000634e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006350:	894e                	mv	s2,s3
    80006352:	b77d                	j	80006300 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006354:	f8042503          	lw	a0,-128(s0)
    80006358:	00a50713          	addi	a4,a0,10
    8000635c:	0712                	slli	a4,a4,0x4

  if(write)
    8000635e:	0001d797          	auipc	a5,0x1d
    80006362:	cd278793          	addi	a5,a5,-814 # 80023030 <disk>
    80006366:	00e786b3          	add	a3,a5,a4
    8000636a:	01803633          	snez	a2,s8
    8000636e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006370:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006374:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006378:	f6070613          	addi	a2,a4,-160
    8000637c:	6394                	ld	a3,0(a5)
    8000637e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006380:	00870593          	addi	a1,a4,8
    80006384:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006386:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006388:	0007b803          	ld	a6,0(a5)
    8000638c:	9642                	add	a2,a2,a6
    8000638e:	46c1                	li	a3,16
    80006390:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006392:	4585                	li	a1,1
    80006394:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006398:	f8442683          	lw	a3,-124(s0)
    8000639c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800063a0:	0692                	slli	a3,a3,0x4
    800063a2:	9836                	add	a6,a6,a3
    800063a4:	058a8613          	addi	a2,s5,88
    800063a8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800063ac:	0007b803          	ld	a6,0(a5)
    800063b0:	96c2                	add	a3,a3,a6
    800063b2:	40000613          	li	a2,1024
    800063b6:	c690                	sw	a2,8(a3)
  if(write)
    800063b8:	001c3613          	seqz	a2,s8
    800063bc:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800063c0:	00166613          	ori	a2,a2,1
    800063c4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800063c8:	f8842603          	lw	a2,-120(s0)
    800063cc:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800063d0:	00250693          	addi	a3,a0,2
    800063d4:	0692                	slli	a3,a3,0x4
    800063d6:	96be                	add	a3,a3,a5
    800063d8:	58fd                	li	a7,-1
    800063da:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800063de:	0612                	slli	a2,a2,0x4
    800063e0:	9832                	add	a6,a6,a2
    800063e2:	f9070713          	addi	a4,a4,-112
    800063e6:	973e                	add	a4,a4,a5
    800063e8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800063ec:	6398                	ld	a4,0(a5)
    800063ee:	9732                	add	a4,a4,a2
    800063f0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800063f2:	4609                	li	a2,2
    800063f4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800063f8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800063fc:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006400:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006404:	6794                	ld	a3,8(a5)
    80006406:	0026d703          	lhu	a4,2(a3)
    8000640a:	8b1d                	andi	a4,a4,7
    8000640c:	0706                	slli	a4,a4,0x1
    8000640e:	96ba                	add	a3,a3,a4
    80006410:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006414:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006418:	6798                	ld	a4,8(a5)
    8000641a:	00275783          	lhu	a5,2(a4)
    8000641e:	2785                	addiw	a5,a5,1
    80006420:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006424:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006428:	100017b7          	lui	a5,0x10001
    8000642c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006430:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006434:	0001d917          	auipc	s2,0x1d
    80006438:	d2490913          	addi	s2,s2,-732 # 80023158 <disk+0x128>
  while(b->disk == 1) {
    8000643c:	4485                	li	s1,1
    8000643e:	00b79c63          	bne	a5,a1,80006456 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006442:	85ca                	mv	a1,s2
    80006444:	8556                	mv	a0,s5
    80006446:	ffffc097          	auipc	ra,0xffffc
    8000644a:	d5e080e7          	jalr	-674(ra) # 800021a4 <sleep>
  while(b->disk == 1) {
    8000644e:	004aa783          	lw	a5,4(s5)
    80006452:	fe9788e3          	beq	a5,s1,80006442 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006456:	f8042903          	lw	s2,-128(s0)
    8000645a:	00290713          	addi	a4,s2,2
    8000645e:	0712                	slli	a4,a4,0x4
    80006460:	0001d797          	auipc	a5,0x1d
    80006464:	bd078793          	addi	a5,a5,-1072 # 80023030 <disk>
    80006468:	97ba                	add	a5,a5,a4
    8000646a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000646e:	0001d997          	auipc	s3,0x1d
    80006472:	bc298993          	addi	s3,s3,-1086 # 80023030 <disk>
    80006476:	00491713          	slli	a4,s2,0x4
    8000647a:	0009b783          	ld	a5,0(s3)
    8000647e:	97ba                	add	a5,a5,a4
    80006480:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006484:	854a                	mv	a0,s2
    80006486:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000648a:	00000097          	auipc	ra,0x0
    8000648e:	b9c080e7          	jalr	-1124(ra) # 80006026 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006492:	8885                	andi	s1,s1,1
    80006494:	f0ed                	bnez	s1,80006476 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006496:	0001d517          	auipc	a0,0x1d
    8000649a:	cc250513          	addi	a0,a0,-830 # 80023158 <disk+0x128>
    8000649e:	ffffa097          	auipc	ra,0xffffa
    800064a2:	7ec080e7          	jalr	2028(ra) # 80000c8a <release>
}
    800064a6:	70e6                	ld	ra,120(sp)
    800064a8:	7446                	ld	s0,112(sp)
    800064aa:	74a6                	ld	s1,104(sp)
    800064ac:	7906                	ld	s2,96(sp)
    800064ae:	69e6                	ld	s3,88(sp)
    800064b0:	6a46                	ld	s4,80(sp)
    800064b2:	6aa6                	ld	s5,72(sp)
    800064b4:	6b06                	ld	s6,64(sp)
    800064b6:	7be2                	ld	s7,56(sp)
    800064b8:	7c42                	ld	s8,48(sp)
    800064ba:	7ca2                	ld	s9,40(sp)
    800064bc:	7d02                	ld	s10,32(sp)
    800064be:	6de2                	ld	s11,24(sp)
    800064c0:	6109                	addi	sp,sp,128
    800064c2:	8082                	ret

00000000800064c4 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800064c4:	1101                	addi	sp,sp,-32
    800064c6:	ec06                	sd	ra,24(sp)
    800064c8:	e822                	sd	s0,16(sp)
    800064ca:	e426                	sd	s1,8(sp)
    800064cc:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800064ce:	0001d497          	auipc	s1,0x1d
    800064d2:	b6248493          	addi	s1,s1,-1182 # 80023030 <disk>
    800064d6:	0001d517          	auipc	a0,0x1d
    800064da:	c8250513          	addi	a0,a0,-894 # 80023158 <disk+0x128>
    800064de:	ffffa097          	auipc	ra,0xffffa
    800064e2:	6f8080e7          	jalr	1784(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800064e6:	10001737          	lui	a4,0x10001
    800064ea:	533c                	lw	a5,96(a4)
    800064ec:	8b8d                	andi	a5,a5,3
    800064ee:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800064f0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800064f4:	689c                	ld	a5,16(s1)
    800064f6:	0204d703          	lhu	a4,32(s1)
    800064fa:	0027d783          	lhu	a5,2(a5)
    800064fe:	04f70863          	beq	a4,a5,8000654e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006502:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006506:	6898                	ld	a4,16(s1)
    80006508:	0204d783          	lhu	a5,32(s1)
    8000650c:	8b9d                	andi	a5,a5,7
    8000650e:	078e                	slli	a5,a5,0x3
    80006510:	97ba                	add	a5,a5,a4
    80006512:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006514:	00278713          	addi	a4,a5,2
    80006518:	0712                	slli	a4,a4,0x4
    8000651a:	9726                	add	a4,a4,s1
    8000651c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006520:	e721                	bnez	a4,80006568 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006522:	0789                	addi	a5,a5,2
    80006524:	0792                	slli	a5,a5,0x4
    80006526:	97a6                	add	a5,a5,s1
    80006528:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000652a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000652e:	ffffc097          	auipc	ra,0xffffc
    80006532:	cda080e7          	jalr	-806(ra) # 80002208 <wakeup>

    disk.used_idx += 1;
    80006536:	0204d783          	lhu	a5,32(s1)
    8000653a:	2785                	addiw	a5,a5,1
    8000653c:	17c2                	slli	a5,a5,0x30
    8000653e:	93c1                	srli	a5,a5,0x30
    80006540:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006544:	6898                	ld	a4,16(s1)
    80006546:	00275703          	lhu	a4,2(a4)
    8000654a:	faf71ce3          	bne	a4,a5,80006502 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000654e:	0001d517          	auipc	a0,0x1d
    80006552:	c0a50513          	addi	a0,a0,-1014 # 80023158 <disk+0x128>
    80006556:	ffffa097          	auipc	ra,0xffffa
    8000655a:	734080e7          	jalr	1844(ra) # 80000c8a <release>
}
    8000655e:	60e2                	ld	ra,24(sp)
    80006560:	6442                	ld	s0,16(sp)
    80006562:	64a2                	ld	s1,8(sp)
    80006564:	6105                	addi	sp,sp,32
    80006566:	8082                	ret
      panic("virtio_disk_intr status");
    80006568:	00002517          	auipc	a0,0x2
    8000656c:	3d850513          	addi	a0,a0,984 # 80008940 <syscalls+0x400>
    80006570:	ffffa097          	auipc	ra,0xffffa
    80006574:	fd0080e7          	jalr	-48(ra) # 80000540 <panic>

0000000080006578 <sgenrand>:
static int mti=N+1; /* mti==N+1 means mt[N] is not initialized */

/* initializing the array with a NONZERO seed */
void
sgenrand(unsigned long seed)
{
    80006578:	1141                	addi	sp,sp,-16
    8000657a:	e422                	sd	s0,8(sp)
    8000657c:	0800                	addi	s0,sp,16
    /* setting initial seeds to mt[N] using         */
    /* the generator Line 25 of Table 1 in          */
    /* [KNUTH 1981, The Art of Computer Programming */
    /*    Vol. 2 (2nd Ed.), pp102]                  */
    mt[0]= seed & 0xffffffff;
    8000657e:	0001d717          	auipc	a4,0x1d
    80006582:	bf270713          	addi	a4,a4,-1038 # 80023170 <mt>
    80006586:	1502                	slli	a0,a0,0x20
    80006588:	9101                	srli	a0,a0,0x20
    8000658a:	e308                	sd	a0,0(a4)
    for (mti=1; mti<N; mti++)
    8000658c:	0001e597          	auipc	a1,0x1e
    80006590:	f5c58593          	addi	a1,a1,-164 # 800244e8 <mt+0x1378>
        mt[mti] = (69069 * mt[mti-1]) & 0xffffffff;
    80006594:	6645                	lui	a2,0x11
    80006596:	dcd60613          	addi	a2,a2,-563 # 10dcd <_entry-0x7ffef233>
    8000659a:	56fd                	li	a3,-1
    8000659c:	9281                	srli	a3,a3,0x20
    8000659e:	631c                	ld	a5,0(a4)
    800065a0:	02c787b3          	mul	a5,a5,a2
    800065a4:	8ff5                	and	a5,a5,a3
    800065a6:	e71c                	sd	a5,8(a4)
    for (mti=1; mti<N; mti++)
    800065a8:	0721                	addi	a4,a4,8
    800065aa:	feb71ae3          	bne	a4,a1,8000659e <sgenrand+0x26>
    800065ae:	27000793          	li	a5,624
    800065b2:	00002717          	auipc	a4,0x2
    800065b6:	3cf72323          	sw	a5,966(a4) # 80008978 <mti>
}
    800065ba:	6422                	ld	s0,8(sp)
    800065bc:	0141                	addi	sp,sp,16
    800065be:	8082                	ret

00000000800065c0 <genrand>:

long /* for integer generation */
genrand()
{
    800065c0:	1141                	addi	sp,sp,-16
    800065c2:	e406                	sd	ra,8(sp)
    800065c4:	e022                	sd	s0,0(sp)
    800065c6:	0800                	addi	s0,sp,16
    unsigned long y;
    static unsigned long mag01[2]={0x0, MATRIX_A};
    /* mag01[x] = x * MATRIX_A  for x=0,1 */

    if (mti >= N) { /* generate N words at one time */
    800065c8:	00002797          	auipc	a5,0x2
    800065cc:	3b07a783          	lw	a5,944(a5) # 80008978 <mti>
    800065d0:	26f00713          	li	a4,623
    800065d4:	0ef75963          	bge	a4,a5,800066c6 <genrand+0x106>
        int kk;

        if (mti == N+1)   /* if sgenrand() has not been called, */
    800065d8:	27100713          	li	a4,625
    800065dc:	12e78e63          	beq	a5,a4,80006718 <genrand+0x158>
            sgenrand(4357); /* a default initial seed is used   */

        for (kk=0;kk<N-M;kk++) {
    800065e0:	0001d817          	auipc	a6,0x1d
    800065e4:	b9080813          	addi	a6,a6,-1136 # 80023170 <mt>
    800065e8:	0001de17          	auipc	t3,0x1d
    800065ec:	2a0e0e13          	addi	t3,t3,672 # 80023888 <mt+0x718>
{
    800065f0:	8742                	mv	a4,a6
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    800065f2:	4885                	li	a7,1
    800065f4:	08fe                	slli	a7,a7,0x1f
    800065f6:	80000537          	lui	a0,0x80000
    800065fa:	fff54513          	not	a0,a0
            mt[kk] = mt[kk+M] ^ (y >> 1) ^ mag01[y & 0x1];
    800065fe:	6585                	lui	a1,0x1
    80006600:	c6858593          	addi	a1,a1,-920 # c68 <_entry-0x7ffff398>
    80006604:	00002317          	auipc	t1,0x2
    80006608:	35430313          	addi	t1,t1,852 # 80008958 <mag01.0>
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    8000660c:	631c                	ld	a5,0(a4)
    8000660e:	0117f7b3          	and	a5,a5,a7
    80006612:	6714                	ld	a3,8(a4)
    80006614:	8ee9                	and	a3,a3,a0
    80006616:	8fd5                	or	a5,a5,a3
            mt[kk] = mt[kk+M] ^ (y >> 1) ^ mag01[y & 0x1];
    80006618:	00b70633          	add	a2,a4,a1
    8000661c:	0017d693          	srli	a3,a5,0x1
    80006620:	6210                	ld	a2,0(a2)
    80006622:	8eb1                	xor	a3,a3,a2
    80006624:	8b85                	andi	a5,a5,1
    80006626:	078e                	slli	a5,a5,0x3
    80006628:	979a                	add	a5,a5,t1
    8000662a:	639c                	ld	a5,0(a5)
    8000662c:	8fb5                	xor	a5,a5,a3
    8000662e:	e31c                	sd	a5,0(a4)
        for (kk=0;kk<N-M;kk++) {
    80006630:	0721                	addi	a4,a4,8
    80006632:	fdc71de3          	bne	a4,t3,8000660c <genrand+0x4c>
        }
        for (;kk<N-1;kk++) {
    80006636:	6605                	lui	a2,0x1
    80006638:	c6060613          	addi	a2,a2,-928 # c60 <_entry-0x7ffff3a0>
    8000663c:	9642                	add	a2,a2,a6
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    8000663e:	4505                	li	a0,1
    80006640:	057e                	slli	a0,a0,0x1f
    80006642:	800005b7          	lui	a1,0x80000
    80006646:	fff5c593          	not	a1,a1
            mt[kk] = mt[kk+(M-N)] ^ (y >> 1) ^ mag01[y & 0x1];
    8000664a:	00002897          	auipc	a7,0x2
    8000664e:	30e88893          	addi	a7,a7,782 # 80008958 <mag01.0>
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    80006652:	71883783          	ld	a5,1816(a6)
    80006656:	8fe9                	and	a5,a5,a0
    80006658:	72083703          	ld	a4,1824(a6)
    8000665c:	8f6d                	and	a4,a4,a1
    8000665e:	8fd9                	or	a5,a5,a4
            mt[kk] = mt[kk+(M-N)] ^ (y >> 1) ^ mag01[y & 0x1];
    80006660:	0017d713          	srli	a4,a5,0x1
    80006664:	00083683          	ld	a3,0(a6)
    80006668:	8f35                	xor	a4,a4,a3
    8000666a:	8b85                	andi	a5,a5,1
    8000666c:	078e                	slli	a5,a5,0x3
    8000666e:	97c6                	add	a5,a5,a7
    80006670:	639c                	ld	a5,0(a5)
    80006672:	8fb9                	xor	a5,a5,a4
    80006674:	70f83c23          	sd	a5,1816(a6)
        for (;kk<N-1;kk++) {
    80006678:	0821                	addi	a6,a6,8
    8000667a:	fcc81ce3          	bne	a6,a2,80006652 <genrand+0x92>
        }
        y = (mt[N-1]&UPPER_MASK)|(mt[0]&LOWER_MASK);
    8000667e:	0001e697          	auipc	a3,0x1e
    80006682:	af268693          	addi	a3,a3,-1294 # 80024170 <mt+0x1000>
    80006686:	3786b783          	ld	a5,888(a3)
    8000668a:	4705                	li	a4,1
    8000668c:	077e                	slli	a4,a4,0x1f
    8000668e:	8ff9                	and	a5,a5,a4
    80006690:	0001d717          	auipc	a4,0x1d
    80006694:	ae073703          	ld	a4,-1312(a4) # 80023170 <mt>
    80006698:	1706                	slli	a4,a4,0x21
    8000669a:	9305                	srli	a4,a4,0x21
    8000669c:	8fd9                	or	a5,a5,a4
        mt[N-1] = mt[M-1] ^ (y >> 1) ^ mag01[y & 0x1];
    8000669e:	0017d713          	srli	a4,a5,0x1
    800066a2:	c606b603          	ld	a2,-928(a3)
    800066a6:	8f31                	xor	a4,a4,a2
    800066a8:	8b85                	andi	a5,a5,1
    800066aa:	078e                	slli	a5,a5,0x3
    800066ac:	00002617          	auipc	a2,0x2
    800066b0:	2ac60613          	addi	a2,a2,684 # 80008958 <mag01.0>
    800066b4:	97b2                	add	a5,a5,a2
    800066b6:	639c                	ld	a5,0(a5)
    800066b8:	8fb9                	xor	a5,a5,a4
    800066ba:	36f6bc23          	sd	a5,888(a3)

        mti = 0;
    800066be:	00002797          	auipc	a5,0x2
    800066c2:	2a07ad23          	sw	zero,698(a5) # 80008978 <mti>
    }
  
    y = mt[mti++];
    800066c6:	00002717          	auipc	a4,0x2
    800066ca:	2b270713          	addi	a4,a4,690 # 80008978 <mti>
    800066ce:	431c                	lw	a5,0(a4)
    800066d0:	0017869b          	addiw	a3,a5,1
    800066d4:	c314                	sw	a3,0(a4)
    800066d6:	078e                	slli	a5,a5,0x3
    800066d8:	0001d717          	auipc	a4,0x1d
    800066dc:	a9870713          	addi	a4,a4,-1384 # 80023170 <mt>
    800066e0:	97ba                	add	a5,a5,a4
    800066e2:	639c                	ld	a5,0(a5)
    y ^= TEMPERING_SHIFT_U(y);
    800066e4:	00b7d713          	srli	a4,a5,0xb
    800066e8:	8f3d                	xor	a4,a4,a5
    y ^= TEMPERING_SHIFT_S(y) & TEMPERING_MASK_B;
    800066ea:	013a67b7          	lui	a5,0x13a6
    800066ee:	8ad78793          	addi	a5,a5,-1875 # 13a58ad <_entry-0x7ec5a753>
    800066f2:	8ff9                	and	a5,a5,a4
    800066f4:	079e                	slli	a5,a5,0x7
    800066f6:	8fb9                	xor	a5,a5,a4
    y ^= TEMPERING_SHIFT_T(y) & TEMPERING_MASK_C;
    800066f8:	00f79713          	slli	a4,a5,0xf
    800066fc:	077e36b7          	lui	a3,0x77e3
    80006700:	0696                	slli	a3,a3,0x5
    80006702:	8f75                	and	a4,a4,a3
    80006704:	8fb9                	xor	a5,a5,a4
    y ^= TEMPERING_SHIFT_L(y);
    80006706:	0127d513          	srli	a0,a5,0x12
    8000670a:	8d3d                	xor	a0,a0,a5

    // Strip off uppermost bit because we want a long,
    // not an unsigned long
    return y & RAND_MAX;
    8000670c:	1506                	slli	a0,a0,0x21
}
    8000670e:	9105                	srli	a0,a0,0x21
    80006710:	60a2                	ld	ra,8(sp)
    80006712:	6402                	ld	s0,0(sp)
    80006714:	0141                	addi	sp,sp,16
    80006716:	8082                	ret
            sgenrand(4357); /* a default initial seed is used   */
    80006718:	6505                	lui	a0,0x1
    8000671a:	10550513          	addi	a0,a0,261 # 1105 <_entry-0x7fffeefb>
    8000671e:	00000097          	auipc	ra,0x0
    80006722:	e5a080e7          	jalr	-422(ra) # 80006578 <sgenrand>
    80006726:	bd6d                	j	800065e0 <genrand+0x20>

0000000080006728 <random_at_most>:

// Assumes 0 <= max <= RAND_MAX
// Returns in the half-open interval [0, max]
long random_at_most(long max) {
    80006728:	1101                	addi	sp,sp,-32
    8000672a:	ec06                	sd	ra,24(sp)
    8000672c:	e822                	sd	s0,16(sp)
    8000672e:	e426                	sd	s1,8(sp)
    80006730:	e04a                	sd	s2,0(sp)
    80006732:	1000                	addi	s0,sp,32
  unsigned long
    // max <= RAND_MAX < ULONG_MAX, so this is okay.
    num_bins = (unsigned long) max + 1,
    80006734:	0505                	addi	a0,a0,1
    num_rand = (unsigned long) RAND_MAX + 1,
    bin_size = num_rand / num_bins,
    80006736:	4785                	li	a5,1
    80006738:	07fe                	slli	a5,a5,0x1f
    8000673a:	02a7d933          	divu	s2,a5,a0
    defect   = num_rand % num_bins;
    8000673e:	02a7f7b3          	remu	a5,a5,a0
  long x;
  do {
   x = genrand();
  }
  // This is carefully written not to overflow
  while (num_rand - defect <= (unsigned long)x);
    80006742:	4485                	li	s1,1
    80006744:	04fe                	slli	s1,s1,0x1f
    80006746:	8c9d                	sub	s1,s1,a5
   x = genrand();
    80006748:	00000097          	auipc	ra,0x0
    8000674c:	e78080e7          	jalr	-392(ra) # 800065c0 <genrand>
  while (num_rand - defect <= (unsigned long)x);
    80006750:	fe957ce3          	bgeu	a0,s1,80006748 <random_at_most+0x20>

  // Truncated division is intentional
  return x/bin_size;
    80006754:	03255533          	divu	a0,a0,s2
    80006758:	60e2                	ld	ra,24(sp)
    8000675a:	6442                	ld	s0,16(sp)
    8000675c:	64a2                	ld	s1,8(sp)
    8000675e:	6902                	ld	s2,0(sp)
    80006760:	6105                	addi	sp,sp,32
    80006762:	8082                	ret
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
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
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
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
