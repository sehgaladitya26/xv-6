
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
    80000068:	33c78793          	addi	a5,a5,828 # 800063a0 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd9a87>
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
    80000130:	87a080e7          	jalr	-1926(ra) # 800029a6 <either_copyin>
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
    800001d0:	624080e7          	jalr	1572(ra) # 800027f0 <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	21e080e7          	jalr	542(ra) # 800023f8 <sleep>
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
    8000021a:	73a080e7          	jalr	1850(ra) # 80002950 <either_copyout>
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
    800002fc:	704080e7          	jalr	1796(ra) # 800029fc <procdump>
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
    80000450:	154080e7          	jalr	340(ra) # 800025a0 <wakeup>
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
    80000482:	3e278793          	addi	a5,a5,994 # 80022860 <devsw>
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
    800008aa:	cfa080e7          	jalr	-774(ra) # 800025a0 <wakeup>
    
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
    80000934:	ac8080e7          	jalr	-1336(ra) # 800023f8 <sleep>
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
    80000a16:	36678793          	addi	a5,a5,870 # 80024d78 <end>
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
    80000ae6:	29650513          	addi	a0,a0,662 # 80024d78 <end>
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
    80000ede:	c62080e7          	jalr	-926(ra) # 80002b3c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00005097          	auipc	ra,0x5
    80000ee6:	4fe080e7          	jalr	1278(ra) # 800063e0 <plicinithart>
  }

  scheduler();        
    80000eea:	00001097          	auipc	ra,0x1
    80000eee:	1fa080e7          	jalr	506(ra) # 800020e4 <scheduler>
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
    80000f56:	bc2080e7          	jalr	-1086(ra) # 80002b14 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00002097          	auipc	ra,0x2
    80000f5e:	be2080e7          	jalr	-1054(ra) # 80002b3c <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	468080e7          	jalr	1128(ra) # 800063ca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00005097          	auipc	ra,0x5
    80000f6e:	476080e7          	jalr	1142(ra) # 800063e0 <plicinithart>
    binit();         // buffer cache
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	630080e7          	jalr	1584(ra) # 800035a2 <binit>
    iinit();         // inode table
    80000f7a:	00003097          	auipc	ra,0x3
    80000f7e:	cd4080e7          	jalr	-812(ra) # 80003c4e <iinit>
    fileinit();      // file table
    80000f82:	00004097          	auipc	ra,0x4
    80000f86:	c72080e7          	jalr	-910(ra) # 80004bf4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	55e080e7          	jalr	1374(ra) # 800064e8 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	f30080e7          	jalr	-208(ra) # 80001ec2 <userinit>
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
    80001a72:	baaa0a13          	addi	s4,s4,-1110 # 80018618 <tickslock>
    char *pa = kalloc();
    80001a76:	fffff097          	auipc	ra,0xfffff
    80001a7a:	084080e7          	jalr	132(ra) # 80000afa <kalloc>
    80001a7e:	862a                	mv	a2,a0
    if(pa == 0)
    80001a80:	c131                	beqz	a0,80001ac4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001a82:	416485b3          	sub	a1,s1,s6
    80001a86:	858d                	srai	a1,a1,0x3
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
    80001aa8:	1a848493          	addi	s1,s1,424
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
    80001b3e:	ade98993          	addi	s3,s3,-1314 # 80018618 <tickslock>
      initlock(&p->lock, "proc");
    80001b42:	85da                	mv	a1,s6
    80001b44:	8526                	mv	a0,s1
    80001b46:	fffff097          	auipc	ra,0xfffff
    80001b4a:	014080e7          	jalr	20(ra) # 80000b5a <initlock>
      p->state = UNUSED;
    80001b4e:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001b52:	415487b3          	sub	a5,s1,s5
    80001b56:	878d                	srai	a5,a5,0x3
    80001b58:	000a3703          	ld	a4,0(s4)
    80001b5c:	02e787b3          	mul	a5,a5,a4
    80001b60:	2785                	addiw	a5,a5,1
    80001b62:	00d7979b          	slliw	a5,a5,0xd
    80001b66:	40f907b3          	sub	a5,s2,a5
    80001b6a:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b6c:	1a848493          	addi	s1,s1,424
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
    80001c08:	d7c7a783          	lw	a5,-644(a5) # 80008980 <first.1756>
    80001c0c:	eb89                	bnez	a5,80001c1e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001c0e:	00001097          	auipc	ra,0x1
    80001c12:	f46080e7          	jalr	-186(ra) # 80002b54 <usertrapret>
}
    80001c16:	60a2                	ld	ra,8(sp)
    80001c18:	6402                	ld	s0,0(sp)
    80001c1a:	0141                	addi	sp,sp,16
    80001c1c:	8082                	ret
    first = 0;
    80001c1e:	00007797          	auipc	a5,0x7
    80001c22:	d607a123          	sw	zero,-670(a5) # 80008980 <first.1756>
    fsinit(ROOTDEV);
    80001c26:	4505                	li	a0,1
    80001c28:	00002097          	auipc	ra,0x2
    80001c2c:	fa6080e7          	jalr	-90(ra) # 80003bce <fsinit>
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
}
    80001db4:	60e2                	ld	ra,24(sp)
    80001db6:	6442                	ld	s0,16(sp)
    80001db8:	64a2                	ld	s1,8(sp)
    80001dba:	6105                	addi	sp,sp,32
    80001dbc:	8082                	ret

0000000080001dbe <allocproc>:
{
    80001dbe:	1101                	addi	sp,sp,-32
    80001dc0:	ec06                	sd	ra,24(sp)
    80001dc2:	e822                	sd	s0,16(sp)
    80001dc4:	e426                	sd	s1,8(sp)
    80001dc6:	e04a                	sd	s2,0(sp)
    80001dc8:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001dca:	00010497          	auipc	s1,0x10
    80001dce:	e4e48493          	addi	s1,s1,-434 # 80011c18 <proc>
    80001dd2:	00017917          	auipc	s2,0x17
    80001dd6:	84690913          	addi	s2,s2,-1978 # 80018618 <tickslock>
    acquire(&p->lock);
    80001dda:	8526                	mv	a0,s1
    80001ddc:	fffff097          	auipc	ra,0xfffff
    80001de0:	e0e080e7          	jalr	-498(ra) # 80000bea <acquire>
    if(p->state == UNUSED) {
    80001de4:	4c9c                	lw	a5,24(s1)
    80001de6:	cf81                	beqz	a5,80001dfe <allocproc+0x40>
      release(&p->lock);
    80001de8:	8526                	mv	a0,s1
    80001dea:	fffff097          	auipc	ra,0xfffff
    80001dee:	eb4080e7          	jalr	-332(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001df2:	1a848493          	addi	s1,s1,424
    80001df6:	ff2492e3          	bne	s1,s2,80001dda <allocproc+0x1c>
  return 0;
    80001dfa:	4481                	li	s1,0
    80001dfc:	a061                	j	80001e84 <allocproc+0xc6>
  p->pid = allocpid();
    80001dfe:	00000097          	auipc	ra,0x0
    80001e02:	e34080e7          	jalr	-460(ra) # 80001c32 <allocpid>
    80001e06:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001e08:	4785                	li	a5,1
    80001e0a:	cc9c                	sw	a5,24(s1)
  p->tick_creation_time = ticks;
    80001e0c:	00007797          	auipc	a5,0x7
    80001e10:	cf47a783          	lw	a5,-780(a5) # 80008b00 <ticks>
    80001e14:	18f4a823          	sw	a5,400(s1)
  p->tickets = 10;
    80001e18:	47a9                	li	a5,10
    80001e1a:	18f4aa23          	sw	a5,404(s1)
  p->priority = 0;
    80001e1e:	1804ac23          	sw	zero,408(s1)
  p->in_queue = 0;
    80001e22:	1804ae23          	sw	zero,412(s1)
  p->curr_rtime = 0;
    80001e26:	1a04a023          	sw	zero,416(s1)
  p->curr_wtime = 0;
    80001e2a:	1a04a223          	sw	zero,420(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001e2e:	fffff097          	auipc	ra,0xfffff
    80001e32:	ccc080e7          	jalr	-820(ra) # 80000afa <kalloc>
    80001e36:	892a                	mv	s2,a0
    80001e38:	eca8                	sd	a0,88(s1)
    80001e3a:	cd21                	beqz	a0,80001e92 <allocproc+0xd4>
  p->pagetable = proc_pagetable(p);
    80001e3c:	8526                	mv	a0,s1
    80001e3e:	00000097          	auipc	ra,0x0
    80001e42:	e3a080e7          	jalr	-454(ra) # 80001c78 <proc_pagetable>
    80001e46:	892a                	mv	s2,a0
    80001e48:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001e4a:	c125                	beqz	a0,80001eaa <allocproc+0xec>
  memset(&p->context, 0, sizeof(p->context));
    80001e4c:	07000613          	li	a2,112
    80001e50:	4581                	li	a1,0
    80001e52:	06048513          	addi	a0,s1,96
    80001e56:	fffff097          	auipc	ra,0xfffff
    80001e5a:	e90080e7          	jalr	-368(ra) # 80000ce6 <memset>
  p->context.ra = (uint64)forkret;
    80001e5e:	00000797          	auipc	a5,0x0
    80001e62:	d8e78793          	addi	a5,a5,-626 # 80001bec <forkret>
    80001e66:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e68:	60bc                	ld	a5,64(s1)
    80001e6a:	6705                	lui	a4,0x1
    80001e6c:	97ba                	add	a5,a5,a4
    80001e6e:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001e70:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001e74:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001e78:	00007797          	auipc	a5,0x7
    80001e7c:	c887a783          	lw	a5,-888(a5) # 80008b00 <ticks>
    80001e80:	16f4a623          	sw	a5,364(s1)
}
    80001e84:	8526                	mv	a0,s1
    80001e86:	60e2                	ld	ra,24(sp)
    80001e88:	6442                	ld	s0,16(sp)
    80001e8a:	64a2                	ld	s1,8(sp)
    80001e8c:	6902                	ld	s2,0(sp)
    80001e8e:	6105                	addi	sp,sp,32
    80001e90:	8082                	ret
    freeproc(p);
    80001e92:	8526                	mv	a0,s1
    80001e94:	00000097          	auipc	ra,0x0
    80001e98:	ed2080e7          	jalr	-302(ra) # 80001d66 <freeproc>
    release(&p->lock);
    80001e9c:	8526                	mv	a0,s1
    80001e9e:	fffff097          	auipc	ra,0xfffff
    80001ea2:	e00080e7          	jalr	-512(ra) # 80000c9e <release>
    return 0;
    80001ea6:	84ca                	mv	s1,s2
    80001ea8:	bff1                	j	80001e84 <allocproc+0xc6>
    freeproc(p);
    80001eaa:	8526                	mv	a0,s1
    80001eac:	00000097          	auipc	ra,0x0
    80001eb0:	eba080e7          	jalr	-326(ra) # 80001d66 <freeproc>
    release(&p->lock);
    80001eb4:	8526                	mv	a0,s1
    80001eb6:	fffff097          	auipc	ra,0xfffff
    80001eba:	de8080e7          	jalr	-536(ra) # 80000c9e <release>
    return 0;
    80001ebe:	84ca                	mv	s1,s2
    80001ec0:	b7d1                	j	80001e84 <allocproc+0xc6>

0000000080001ec2 <userinit>:
{
    80001ec2:	1101                	addi	sp,sp,-32
    80001ec4:	ec06                	sd	ra,24(sp)
    80001ec6:	e822                	sd	s0,16(sp)
    80001ec8:	e426                	sd	s1,8(sp)
    80001eca:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ecc:	00000097          	auipc	ra,0x0
    80001ed0:	ef2080e7          	jalr	-270(ra) # 80001dbe <allocproc>
    80001ed4:	84aa                	mv	s1,a0
  initproc = p;
    80001ed6:	00007797          	auipc	a5,0x7
    80001eda:	c2a7b123          	sd	a0,-990(a5) # 80008af8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ede:	03400613          	li	a2,52
    80001ee2:	00007597          	auipc	a1,0x7
    80001ee6:	aae58593          	addi	a1,a1,-1362 # 80008990 <initcode>
    80001eea:	6928                	ld	a0,80(a0)
    80001eec:	fffff097          	auipc	ra,0xfffff
    80001ef0:	486080e7          	jalr	1158(ra) # 80001372 <uvmfirst>
  p->sz = PGSIZE;
    80001ef4:	6785                	lui	a5,0x1
    80001ef6:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001ef8:	6cb8                	ld	a4,88(s1)
    80001efa:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001efe:	6cb8                	ld	a4,88(s1)
    80001f00:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f02:	4641                	li	a2,16
    80001f04:	00006597          	auipc	a1,0x6
    80001f08:	31c58593          	addi	a1,a1,796 # 80008220 <digits+0x1e0>
    80001f0c:	15848513          	addi	a0,s1,344
    80001f10:	fffff097          	auipc	ra,0xfffff
    80001f14:	f28080e7          	jalr	-216(ra) # 80000e38 <safestrcpy>
  p->cwd = namei("/");
    80001f18:	00006517          	auipc	a0,0x6
    80001f1c:	31850513          	addi	a0,a0,792 # 80008230 <digits+0x1f0>
    80001f20:	00002097          	auipc	ra,0x2
    80001f24:	6d0080e7          	jalr	1744(ra) # 800045f0 <namei>
    80001f28:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001f2c:	478d                	li	a5,3
    80001f2e:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001f30:	8526                	mv	a0,s1
    80001f32:	fffff097          	auipc	ra,0xfffff
    80001f36:	d6c080e7          	jalr	-660(ra) # 80000c9e <release>
}
    80001f3a:	60e2                	ld	ra,24(sp)
    80001f3c:	6442                	ld	s0,16(sp)
    80001f3e:	64a2                	ld	s1,8(sp)
    80001f40:	6105                	addi	sp,sp,32
    80001f42:	8082                	ret

0000000080001f44 <growproc>:
{
    80001f44:	1101                	addi	sp,sp,-32
    80001f46:	ec06                	sd	ra,24(sp)
    80001f48:	e822                	sd	s0,16(sp)
    80001f4a:	e426                	sd	s1,8(sp)
    80001f4c:	e04a                	sd	s2,0(sp)
    80001f4e:	1000                	addi	s0,sp,32
    80001f50:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001f52:	00000097          	auipc	ra,0x0
    80001f56:	c62080e7          	jalr	-926(ra) # 80001bb4 <myproc>
    80001f5a:	84aa                	mv	s1,a0
  sz = p->sz;
    80001f5c:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001f5e:	01204c63          	bgtz	s2,80001f76 <growproc+0x32>
  } else if(n < 0){
    80001f62:	02094663          	bltz	s2,80001f8e <growproc+0x4a>
  p->sz = sz;
    80001f66:	e4ac                	sd	a1,72(s1)
  return 0;
    80001f68:	4501                	li	a0,0
}
    80001f6a:	60e2                	ld	ra,24(sp)
    80001f6c:	6442                	ld	s0,16(sp)
    80001f6e:	64a2                	ld	s1,8(sp)
    80001f70:	6902                	ld	s2,0(sp)
    80001f72:	6105                	addi	sp,sp,32
    80001f74:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001f76:	4691                	li	a3,4
    80001f78:	00b90633          	add	a2,s2,a1
    80001f7c:	6928                	ld	a0,80(a0)
    80001f7e:	fffff097          	auipc	ra,0xfffff
    80001f82:	4ae080e7          	jalr	1198(ra) # 8000142c <uvmalloc>
    80001f86:	85aa                	mv	a1,a0
    80001f88:	fd79                	bnez	a0,80001f66 <growproc+0x22>
      return -1;
    80001f8a:	557d                	li	a0,-1
    80001f8c:	bff9                	j	80001f6a <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f8e:	00b90633          	add	a2,s2,a1
    80001f92:	6928                	ld	a0,80(a0)
    80001f94:	fffff097          	auipc	ra,0xfffff
    80001f98:	450080e7          	jalr	1104(ra) # 800013e4 <uvmdealloc>
    80001f9c:	85aa                	mv	a1,a0
    80001f9e:	b7e1                	j	80001f66 <growproc+0x22>

0000000080001fa0 <fork>:
{
    80001fa0:	7179                	addi	sp,sp,-48
    80001fa2:	f406                	sd	ra,40(sp)
    80001fa4:	f022                	sd	s0,32(sp)
    80001fa6:	ec26                	sd	s1,24(sp)
    80001fa8:	e84a                	sd	s2,16(sp)
    80001faa:	e44e                	sd	s3,8(sp)
    80001fac:	e052                	sd	s4,0(sp)
    80001fae:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fb0:	00000097          	auipc	ra,0x0
    80001fb4:	c04080e7          	jalr	-1020(ra) # 80001bb4 <myproc>
    80001fb8:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001fba:	00000097          	auipc	ra,0x0
    80001fbe:	e04080e7          	jalr	-508(ra) # 80001dbe <allocproc>
    80001fc2:	10050f63          	beqz	a0,800020e0 <fork+0x140>
    80001fc6:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001fc8:	04893603          	ld	a2,72(s2)
    80001fcc:	692c                	ld	a1,80(a0)
    80001fce:	05093503          	ld	a0,80(s2)
    80001fd2:	fffff097          	auipc	ra,0xfffff
    80001fd6:	5ae080e7          	jalr	1454(ra) # 80001580 <uvmcopy>
    80001fda:	04054a63          	bltz	a0,8000202e <fork+0x8e>
  np->sz = p->sz;
    80001fde:	04893783          	ld	a5,72(s2)
    80001fe2:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001fe6:	05893683          	ld	a3,88(s2)
    80001fea:	87b6                	mv	a5,a3
    80001fec:	0589b703          	ld	a4,88(s3)
    80001ff0:	12068693          	addi	a3,a3,288
    80001ff4:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001ff8:	6788                	ld	a0,8(a5)
    80001ffa:	6b8c                	ld	a1,16(a5)
    80001ffc:	6f90                	ld	a2,24(a5)
    80001ffe:	01073023          	sd	a6,0(a4)
    80002002:	e708                	sd	a0,8(a4)
    80002004:	eb0c                	sd	a1,16(a4)
    80002006:	ef10                	sd	a2,24(a4)
    80002008:	02078793          	addi	a5,a5,32
    8000200c:	02070713          	addi	a4,a4,32
    80002010:	fed792e3          	bne	a5,a3,80001ff4 <fork+0x54>
  np->trace_flag = p->trace_flag;
    80002014:	17492783          	lw	a5,372(s2)
    80002018:	16f9aa23          	sw	a5,372(s3)
  np->trapframe->a0 = 0;
    8000201c:	0589b783          	ld	a5,88(s3)
    80002020:	0607b823          	sd	zero,112(a5)
    80002024:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80002028:	15000a13          	li	s4,336
    8000202c:	a03d                	j	8000205a <fork+0xba>
    freeproc(np);
    8000202e:	854e                	mv	a0,s3
    80002030:	00000097          	auipc	ra,0x0
    80002034:	d36080e7          	jalr	-714(ra) # 80001d66 <freeproc>
    release(&np->lock);
    80002038:	854e                	mv	a0,s3
    8000203a:	fffff097          	auipc	ra,0xfffff
    8000203e:	c64080e7          	jalr	-924(ra) # 80000c9e <release>
    return -1;
    80002042:	5a7d                	li	s4,-1
    80002044:	a069                	j	800020ce <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    80002046:	00003097          	auipc	ra,0x3
    8000204a:	c40080e7          	jalr	-960(ra) # 80004c86 <filedup>
    8000204e:	009987b3          	add	a5,s3,s1
    80002052:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002054:	04a1                	addi	s1,s1,8
    80002056:	01448763          	beq	s1,s4,80002064 <fork+0xc4>
    if(p->ofile[i])
    8000205a:	009907b3          	add	a5,s2,s1
    8000205e:	6388                	ld	a0,0(a5)
    80002060:	f17d                	bnez	a0,80002046 <fork+0xa6>
    80002062:	bfcd                	j	80002054 <fork+0xb4>
  np->cwd = idup(p->cwd);
    80002064:	15093503          	ld	a0,336(s2)
    80002068:	00002097          	auipc	ra,0x2
    8000206c:	da4080e7          	jalr	-604(ra) # 80003e0c <idup>
    80002070:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002074:	4641                	li	a2,16
    80002076:	15890593          	addi	a1,s2,344
    8000207a:	15898513          	addi	a0,s3,344
    8000207e:	fffff097          	auipc	ra,0xfffff
    80002082:	dba080e7          	jalr	-582(ra) # 80000e38 <safestrcpy>
  pid = np->pid;
    80002086:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    8000208a:	854e                	mv	a0,s3
    8000208c:	fffff097          	auipc	ra,0xfffff
    80002090:	c12080e7          	jalr	-1006(ra) # 80000c9e <release>
  acquire(&wait_lock);
    80002094:	0000f497          	auipc	s1,0xf
    80002098:	cf448493          	addi	s1,s1,-780 # 80010d88 <wait_lock>
    8000209c:	8526                	mv	a0,s1
    8000209e:	fffff097          	auipc	ra,0xfffff
    800020a2:	b4c080e7          	jalr	-1204(ra) # 80000bea <acquire>
  np->parent = p;
    800020a6:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    800020aa:	8526                	mv	a0,s1
    800020ac:	fffff097          	auipc	ra,0xfffff
    800020b0:	bf2080e7          	jalr	-1038(ra) # 80000c9e <release>
  acquire(&np->lock);
    800020b4:	854e                	mv	a0,s3
    800020b6:	fffff097          	auipc	ra,0xfffff
    800020ba:	b34080e7          	jalr	-1228(ra) # 80000bea <acquire>
  np->state = RUNNABLE;
    800020be:	478d                	li	a5,3
    800020c0:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    800020c4:	854e                	mv	a0,s3
    800020c6:	fffff097          	auipc	ra,0xfffff
    800020ca:	bd8080e7          	jalr	-1064(ra) # 80000c9e <release>
}
    800020ce:	8552                	mv	a0,s4
    800020d0:	70a2                	ld	ra,40(sp)
    800020d2:	7402                	ld	s0,32(sp)
    800020d4:	64e2                	ld	s1,24(sp)
    800020d6:	6942                	ld	s2,16(sp)
    800020d8:	69a2                	ld	s3,8(sp)
    800020da:	6a02                	ld	s4,0(sp)
    800020dc:	6145                	addi	sp,sp,48
    800020de:	8082                	ret
    return -1;
    800020e0:	5a7d                	li	s4,-1
    800020e2:	b7f5                	j	800020ce <fork+0x12e>

00000000800020e4 <scheduler>:
{
    800020e4:	7175                	addi	sp,sp,-144
    800020e6:	e506                	sd	ra,136(sp)
    800020e8:	e122                	sd	s0,128(sp)
    800020ea:	fca6                	sd	s1,120(sp)
    800020ec:	f8ca                	sd	s2,112(sp)
    800020ee:	f4ce                	sd	s3,104(sp)
    800020f0:	f0d2                	sd	s4,96(sp)
    800020f2:	ecd6                	sd	s5,88(sp)
    800020f4:	e8da                	sd	s6,80(sp)
    800020f6:	e4de                	sd	s7,72(sp)
    800020f8:	e0e2                	sd	s8,64(sp)
    800020fa:	fc66                	sd	s9,56(sp)
    800020fc:	f86a                	sd	s10,48(sp)
    800020fe:	f46e                	sd	s11,40(sp)
    80002100:	0900                	addi	s0,sp,144
    80002102:	8792                	mv	a5,tp
  int id = r_tp();
    80002104:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002106:	00779693          	slli	a3,a5,0x7
    8000210a:	0000f717          	auipc	a4,0xf
    8000210e:	c6670713          	addi	a4,a4,-922 # 80010d70 <pid_lock>
    80002112:	9736                	add	a4,a4,a3
    80002114:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &chosen->context);
    80002118:	0000f717          	auipc	a4,0xf
    8000211c:	c9070713          	addi	a4,a4,-880 # 80010da8 <cpus+0x8>
    80002120:	9736                	add	a4,a4,a3
    80002122:	f8e43023          	sd	a4,-128(s0)
          p->in_queue = 1;
    80002126:	4d85                	li	s11,1
      for (p = proc; p < &proc[NPROC]; p++)
    80002128:	00016a97          	auipc	s5,0x16
    8000212c:	4f0a8a93          	addi	s5,s5,1264 # 80018618 <tickslock>
          p = queues[i].procs[queues[i].front];
    80002130:	0000fc17          	auipc	s8,0xf
    80002134:	070c0c13          	addi	s8,s8,112 # 800111a0 <queues>
        c->proc = chosen;
    80002138:	0000f717          	auipc	a4,0xf
    8000213c:	c3870713          	addi	a4,a4,-968 # 80010d70 <pid_lock>
    80002140:	00d707b3          	add	a5,a4,a3
    80002144:	f6f43c23          	sd	a5,-136(s0)
    80002148:	a0c5                	j	80002228 <scheduler+0x144>
          enqueue(p);
    8000214a:	8526                	mv	a0,s1
    8000214c:	fffff097          	auipc	ra,0xfffff
    80002150:	704080e7          	jalr	1796(ra) # 80001850 <enqueue>
          p->curr_rtime = 0;
    80002154:	1a04a023          	sw	zero,416(s1)
          p->curr_wtime = 0;
    80002158:	1a04a223          	sw	zero,420(s1)
          p->in_queue = 1;
    8000215c:	19b4ae23          	sw	s11,412(s1)
        release(&p->lock);
    80002160:	8526                	mv	a0,s1
    80002162:	fffff097          	auipc	ra,0xfffff
    80002166:	b3c080e7          	jalr	-1220(ra) # 80000c9e <release>
      for (p = proc; p < &proc[NPROC]; p++)
    8000216a:	1a848493          	addi	s1,s1,424
    8000216e:	01548e63          	beq	s1,s5,8000218a <scheduler+0xa6>
        acquire(&p->lock);
    80002172:	8526                	mv	a0,s1
    80002174:	fffff097          	auipc	ra,0xfffff
    80002178:	a76080e7          	jalr	-1418(ra) # 80000bea <acquire>
        if (p->state == RUNNABLE && p->in_queue == 0)
    8000217c:	4c9c                	lw	a5,24(s1)
    8000217e:	ff3791e3          	bne	a5,s3,80002160 <scheduler+0x7c>
    80002182:	19c4a783          	lw	a5,412(s1)
    80002186:	ffe9                	bnez	a5,80002160 <scheduler+0x7c>
    80002188:	b7c9                	j	8000214a <scheduler+0x66>
    8000218a:	0000fd17          	auipc	s10,0xf
    8000218e:	01ed0d13          	addi	s10,s10,30 # 800111a8 <queues+0x8>
      for (int i = 0; i < 5; i++)
    80002192:	4c81                	li	s9,0
    80002194:	a039                	j	800021a2 <scheduler+0xbe>
    80002196:	2c85                	addiw	s9,s9,1
    80002198:	218d0d13          	addi	s10,s10,536
    8000219c:	4795                	li	a5,5
    8000219e:	08fc8863          	beq	s9,a5,8000222e <scheduler+0x14a>
        for(int j = 0; j < queues[i].length; j++)
    800021a2:	8a6a                	mv	s4,s10
    800021a4:	000d2783          	lw	a5,0(s10)
    800021a8:	f8843903          	ld	s2,-120(s0)
    800021ac:	fef055e3          	blez	a5,80002196 <scheduler+0xb2>
          p = queues[i].procs[queues[i].front];
    800021b0:	004c9b13          	slli	s6,s9,0x4
    800021b4:	9b66                	add	s6,s6,s9
    800021b6:	0b0a                	slli	s6,s6,0x2
    800021b8:	419b0b33          	sub	s6,s6,s9
    800021bc:	ff8a2783          	lw	a5,-8(s4)
    800021c0:	97da                	add	a5,a5,s6
    800021c2:	0789                	addi	a5,a5,2
    800021c4:	078e                	slli	a5,a5,0x3
    800021c6:	97e2                	add	a5,a5,s8
    800021c8:	6384                	ld	s1,0(a5)
          acquire(&p->lock);
    800021ca:	8526                	mv	a0,s1
    800021cc:	fffff097          	auipc	ra,0xfffff
    800021d0:	a1e080e7          	jalr	-1506(ra) # 80000bea <acquire>
          dequeue(p);  // clear out all the processes as it goes through all the levels
    800021d4:	8526                	mv	a0,s1
    800021d6:	fffff097          	auipc	ra,0xfffff
    800021da:	72c080e7          	jalr	1836(ra) # 80001902 <dequeue>
          p->in_queue = 0;
    800021de:	1804ae23          	sw	zero,412(s1)
          if (p->state == RUNNABLE)
    800021e2:	4c9c                	lw	a5,24(s1)
    800021e4:	01378d63          	beq	a5,s3,800021fe <scheduler+0x11a>
          release(&p->lock);
    800021e8:	8526                	mv	a0,s1
    800021ea:	fffff097          	auipc	ra,0xfffff
    800021ee:	ab4080e7          	jalr	-1356(ra) # 80000c9e <release>
        for(int j = 0; j < queues[i].length; j++)
    800021f2:	2905                	addiw	s2,s2,1
    800021f4:	000a2783          	lw	a5,0(s4)
    800021f8:	fcf942e3          	blt	s2,a5,800021bc <scheduler+0xd8>
    800021fc:	bf69                	j	80002196 <scheduler+0xb2>
        chosen->state = RUNNING;
    800021fe:	4791                	li	a5,4
    80002200:	cc9c                	sw	a5,24(s1)
        c->proc = chosen;
    80002202:	f7843903          	ld	s2,-136(s0)
    80002206:	02993823          	sd	s1,48(s2)
        swtch(&c->context, &chosen->context);
    8000220a:	06048593          	addi	a1,s1,96
    8000220e:	f8043503          	ld	a0,-128(s0)
    80002212:	00001097          	auipc	ra,0x1
    80002216:	898080e7          	jalr	-1896(ra) # 80002aaa <swtch>
        c->proc = 0;
    8000221a:	02093823          	sd	zero,48(s2)
        release(&chosen->lock);
    8000221e:	8526                	mv	a0,s1
    80002220:	fffff097          	auipc	ra,0xfffff
    80002224:	a7e080e7          	jalr	-1410(ra) # 80000c9e <release>
        if (p->state == RUNNABLE && p->in_queue == 0)
    80002228:	498d                	li	s3,3
        for(int j = 0; j < queues[i].length; j++)
    8000222a:	f8043423          	sd	zero,-120(s0)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000222e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002232:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002236:	10079073          	csrw	sstatus,a5
      for (p = proc; p < &proc[NPROC]; p++)
    8000223a:	00010497          	auipc	s1,0x10
    8000223e:	9de48493          	addi	s1,s1,-1570 # 80011c18 <proc>
    80002242:	bf05                	j	80002172 <scheduler+0x8e>

0000000080002244 <sched>:
{
    80002244:	7179                	addi	sp,sp,-48
    80002246:	f406                	sd	ra,40(sp)
    80002248:	f022                	sd	s0,32(sp)
    8000224a:	ec26                	sd	s1,24(sp)
    8000224c:	e84a                	sd	s2,16(sp)
    8000224e:	e44e                	sd	s3,8(sp)
    80002250:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002252:	00000097          	auipc	ra,0x0
    80002256:	962080e7          	jalr	-1694(ra) # 80001bb4 <myproc>
    8000225a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000225c:	fffff097          	auipc	ra,0xfffff
    80002260:	914080e7          	jalr	-1772(ra) # 80000b70 <holding>
    80002264:	c93d                	beqz	a0,800022da <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002266:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002268:	2781                	sext.w	a5,a5
    8000226a:	079e                	slli	a5,a5,0x7
    8000226c:	0000f717          	auipc	a4,0xf
    80002270:	b0470713          	addi	a4,a4,-1276 # 80010d70 <pid_lock>
    80002274:	97ba                	add	a5,a5,a4
    80002276:	0a87a703          	lw	a4,168(a5)
    8000227a:	4785                	li	a5,1
    8000227c:	06f71763          	bne	a4,a5,800022ea <sched+0xa6>
  if(p->state == RUNNING)
    80002280:	4c98                	lw	a4,24(s1)
    80002282:	4791                	li	a5,4
    80002284:	06f70b63          	beq	a4,a5,800022fa <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002288:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000228c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000228e:	efb5                	bnez	a5,8000230a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002290:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002292:	0000f917          	auipc	s2,0xf
    80002296:	ade90913          	addi	s2,s2,-1314 # 80010d70 <pid_lock>
    8000229a:	2781                	sext.w	a5,a5
    8000229c:	079e                	slli	a5,a5,0x7
    8000229e:	97ca                	add	a5,a5,s2
    800022a0:	0ac7a983          	lw	s3,172(a5)
    800022a4:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800022a6:	2781                	sext.w	a5,a5
    800022a8:	079e                	slli	a5,a5,0x7
    800022aa:	0000f597          	auipc	a1,0xf
    800022ae:	afe58593          	addi	a1,a1,-1282 # 80010da8 <cpus+0x8>
    800022b2:	95be                	add	a1,a1,a5
    800022b4:	06048513          	addi	a0,s1,96
    800022b8:	00000097          	auipc	ra,0x0
    800022bc:	7f2080e7          	jalr	2034(ra) # 80002aaa <swtch>
    800022c0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800022c2:	2781                	sext.w	a5,a5
    800022c4:	079e                	slli	a5,a5,0x7
    800022c6:	97ca                	add	a5,a5,s2
    800022c8:	0b37a623          	sw	s3,172(a5)
}
    800022cc:	70a2                	ld	ra,40(sp)
    800022ce:	7402                	ld	s0,32(sp)
    800022d0:	64e2                	ld	s1,24(sp)
    800022d2:	6942                	ld	s2,16(sp)
    800022d4:	69a2                	ld	s3,8(sp)
    800022d6:	6145                	addi	sp,sp,48
    800022d8:	8082                	ret
    panic("sched p->lock");
    800022da:	00006517          	auipc	a0,0x6
    800022de:	f5e50513          	addi	a0,a0,-162 # 80008238 <digits+0x1f8>
    800022e2:	ffffe097          	auipc	ra,0xffffe
    800022e6:	262080e7          	jalr	610(ra) # 80000544 <panic>
    panic("sched locks");
    800022ea:	00006517          	auipc	a0,0x6
    800022ee:	f5e50513          	addi	a0,a0,-162 # 80008248 <digits+0x208>
    800022f2:	ffffe097          	auipc	ra,0xffffe
    800022f6:	252080e7          	jalr	594(ra) # 80000544 <panic>
    panic("sched running");
    800022fa:	00006517          	auipc	a0,0x6
    800022fe:	f5e50513          	addi	a0,a0,-162 # 80008258 <digits+0x218>
    80002302:	ffffe097          	auipc	ra,0xffffe
    80002306:	242080e7          	jalr	578(ra) # 80000544 <panic>
    panic("sched interruptible");
    8000230a:	00006517          	auipc	a0,0x6
    8000230e:	f5e50513          	addi	a0,a0,-162 # 80008268 <digits+0x228>
    80002312:	ffffe097          	auipc	ra,0xffffe
    80002316:	232080e7          	jalr	562(ra) # 80000544 <panic>

000000008000231a <yield>:
{
    8000231a:	1101                	addi	sp,sp,-32
    8000231c:	ec06                	sd	ra,24(sp)
    8000231e:	e822                	sd	s0,16(sp)
    80002320:	e426                	sd	s1,8(sp)
    80002322:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002324:	00000097          	auipc	ra,0x0
    80002328:	890080e7          	jalr	-1904(ra) # 80001bb4 <myproc>
    8000232c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000232e:	fffff097          	auipc	ra,0xfffff
    80002332:	8bc080e7          	jalr	-1860(ra) # 80000bea <acquire>
  p->state = RUNNABLE;
    80002336:	478d                	li	a5,3
    80002338:	cc9c                	sw	a5,24(s1)
  sched();
    8000233a:	00000097          	auipc	ra,0x0
    8000233e:	f0a080e7          	jalr	-246(ra) # 80002244 <sched>
  release(&p->lock);
    80002342:	8526                	mv	a0,s1
    80002344:	fffff097          	auipc	ra,0xfffff
    80002348:	95a080e7          	jalr	-1702(ra) # 80000c9e <release>
}
    8000234c:	60e2                	ld	ra,24(sp)
    8000234e:	6442                	ld	s0,16(sp)
    80002350:	64a2                	ld	s1,8(sp)
    80002352:	6105                	addi	sp,sp,32
    80002354:	8082                	ret

0000000080002356 <update_time>:
{
    80002356:	7139                	addi	sp,sp,-64
    80002358:	fc06                	sd	ra,56(sp)
    8000235a:	f822                	sd	s0,48(sp)
    8000235c:	f426                	sd	s1,40(sp)
    8000235e:	f04a                	sd	s2,32(sp)
    80002360:	ec4e                	sd	s3,24(sp)
    80002362:	e852                	sd	s4,16(sp)
    80002364:	e456                	sd	s5,8(sp)
    80002366:	0080                	addi	s0,sp,64
  for(p = proc; p < &proc[NPROC]; p++){
    80002368:	00010497          	auipc	s1,0x10
    8000236c:	8b048493          	addi	s1,s1,-1872 # 80011c18 <proc>
    if(p->state == RUNNING) {
    80002370:	4991                	li	s3,4
    else if(p->state == RUNNABLE) {
    80002372:	4a0d                	li	s4,3
    if(p->curr_wtime >= 32 && p->state == RUNNABLE) {
    80002374:	4afd                	li	s5,31
  for(p = proc; p < &proc[NPROC]; p++){
    80002376:	00016917          	auipc	s2,0x16
    8000237a:	2a290913          	addi	s2,s2,674 # 80018618 <tickslock>
    8000237e:	a839                	j	8000239c <update_time+0x46>
      p->curr_rtime++;
    80002380:	1a04a783          	lw	a5,416(s1)
    80002384:	2785                	addiw	a5,a5,1
    80002386:	1af4a023          	sw	a5,416(s1)
    release(&p->lock);
    8000238a:	8526                	mv	a0,s1
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	912080e7          	jalr	-1774(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002394:	1a848493          	addi	s1,s1,424
    80002398:	05248763          	beq	s1,s2,800023e6 <update_time+0x90>
    acquire(&p->lock);
    8000239c:	8526                	mv	a0,s1
    8000239e:	fffff097          	auipc	ra,0xfffff
    800023a2:	84c080e7          	jalr	-1972(ra) # 80000bea <acquire>
    if(p->state == RUNNING) {
    800023a6:	4c9c                	lw	a5,24(s1)
    800023a8:	fd378ce3          	beq	a5,s3,80002380 <update_time+0x2a>
    else if(p->state == RUNNABLE) {
    800023ac:	fd479fe3          	bne	a5,s4,8000238a <update_time+0x34>
      p->curr_wtime++;
    800023b0:	1a44a783          	lw	a5,420(s1)
    800023b4:	2785                	addiw	a5,a5,1
    800023b6:	0007871b          	sext.w	a4,a5
    800023ba:	1af4a223          	sw	a5,420(s1)
    if(p->curr_wtime >= 32 && p->state == RUNNABLE) {
    800023be:	fcead6e3          	bge	s5,a4,8000238a <update_time+0x34>
      if(p->in_queue != 0) {
    800023c2:	19c4a783          	lw	a5,412(s1)
    800023c6:	eb81                	bnez	a5,800023d6 <update_time+0x80>
      if(p->priority != 0) {
    800023c8:	1984a783          	lw	a5,408(s1)
    800023cc:	dfdd                	beqz	a5,8000238a <update_time+0x34>
        p->priority--;
    800023ce:	37fd                	addiw	a5,a5,-1
    800023d0:	18f4ac23          	sw	a5,408(s1)
    800023d4:	bf5d                	j	8000238a <update_time+0x34>
        delqueue(p);
    800023d6:	8526                	mv	a0,s1
    800023d8:	fffff097          	auipc	ra,0xfffff
    800023dc:	5c2080e7          	jalr	1474(ra) # 8000199a <delqueue>
        p->in_queue = 0;
    800023e0:	1804ae23          	sw	zero,412(s1)
    800023e4:	b7d5                	j	800023c8 <update_time+0x72>
}
    800023e6:	70e2                	ld	ra,56(sp)
    800023e8:	7442                	ld	s0,48(sp)
    800023ea:	74a2                	ld	s1,40(sp)
    800023ec:	7902                	ld	s2,32(sp)
    800023ee:	69e2                	ld	s3,24(sp)
    800023f0:	6a42                	ld	s4,16(sp)
    800023f2:	6aa2                	ld	s5,8(sp)
    800023f4:	6121                	addi	sp,sp,64
    800023f6:	8082                	ret

00000000800023f8 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800023f8:	7179                	addi	sp,sp,-48
    800023fa:	f406                	sd	ra,40(sp)
    800023fc:	f022                	sd	s0,32(sp)
    800023fe:	ec26                	sd	s1,24(sp)
    80002400:	e84a                	sd	s2,16(sp)
    80002402:	e44e                	sd	s3,8(sp)
    80002404:	1800                	addi	s0,sp,48
    80002406:	89aa                	mv	s3,a0
    80002408:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000240a:	fffff097          	auipc	ra,0xfffff
    8000240e:	7aa080e7          	jalr	1962(ra) # 80001bb4 <myproc>
    80002412:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002414:	ffffe097          	auipc	ra,0xffffe
    80002418:	7d6080e7          	jalr	2006(ra) # 80000bea <acquire>
  release(lk);
    8000241c:	854a                	mv	a0,s2
    8000241e:	fffff097          	auipc	ra,0xfffff
    80002422:	880080e7          	jalr	-1920(ra) # 80000c9e <release>

  // Go to sleep.
  p->chan = chan;
    80002426:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000242a:	4789                	li	a5,2
    8000242c:	cc9c                	sw	a5,24(s1)

  sched();
    8000242e:	00000097          	auipc	ra,0x0
    80002432:	e16080e7          	jalr	-490(ra) # 80002244 <sched>

  // Tidy up.
  p->chan = 0;
    80002436:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000243a:	8526                	mv	a0,s1
    8000243c:	fffff097          	auipc	ra,0xfffff
    80002440:	862080e7          	jalr	-1950(ra) # 80000c9e <release>
  acquire(lk);
    80002444:	854a                	mv	a0,s2
    80002446:	ffffe097          	auipc	ra,0xffffe
    8000244a:	7a4080e7          	jalr	1956(ra) # 80000bea <acquire>
}
    8000244e:	70a2                	ld	ra,40(sp)
    80002450:	7402                	ld	s0,32(sp)
    80002452:	64e2                	ld	s1,24(sp)
    80002454:	6942                	ld	s2,16(sp)
    80002456:	69a2                	ld	s3,8(sp)
    80002458:	6145                	addi	sp,sp,48
    8000245a:	8082                	ret

000000008000245c <waitx>:
{
    8000245c:	711d                	addi	sp,sp,-96
    8000245e:	ec86                	sd	ra,88(sp)
    80002460:	e8a2                	sd	s0,80(sp)
    80002462:	e4a6                	sd	s1,72(sp)
    80002464:	e0ca                	sd	s2,64(sp)
    80002466:	fc4e                	sd	s3,56(sp)
    80002468:	f852                	sd	s4,48(sp)
    8000246a:	f456                	sd	s5,40(sp)
    8000246c:	f05a                	sd	s6,32(sp)
    8000246e:	ec5e                	sd	s7,24(sp)
    80002470:	e862                	sd	s8,16(sp)
    80002472:	e466                	sd	s9,8(sp)
    80002474:	e06a                	sd	s10,0(sp)
    80002476:	1080                	addi	s0,sp,96
    80002478:	8b2a                	mv	s6,a0
    8000247a:	8bae                	mv	s7,a1
    8000247c:	8c32                	mv	s8,a2
  struct proc *p = myproc();
    8000247e:	fffff097          	auipc	ra,0xfffff
    80002482:	736080e7          	jalr	1846(ra) # 80001bb4 <myproc>
    80002486:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002488:	0000f517          	auipc	a0,0xf
    8000248c:	90050513          	addi	a0,a0,-1792 # 80010d88 <wait_lock>
    80002490:	ffffe097          	auipc	ra,0xffffe
    80002494:	75a080e7          	jalr	1882(ra) # 80000bea <acquire>
    havekids = 0;
    80002498:	4c81                	li	s9,0
        if(np->state == ZOMBIE){
    8000249a:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000249c:	00016997          	auipc	s3,0x16
    800024a0:	17c98993          	addi	s3,s3,380 # 80018618 <tickslock>
        havekids = 1;
    800024a4:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024a6:	0000fd17          	auipc	s10,0xf
    800024aa:	8e2d0d13          	addi	s10,s10,-1822 # 80010d88 <wait_lock>
    havekids = 0;
    800024ae:	8766                	mv	a4,s9
    for(np = proc; np < &proc[NPROC]; np++){
    800024b0:	0000f497          	auipc	s1,0xf
    800024b4:	76848493          	addi	s1,s1,1896 # 80011c18 <proc>
    800024b8:	a8bd                	j	80002536 <waitx+0xda>
          pid = np->pid;
    800024ba:	0304a983          	lw	s3,48(s1)
          *rtime = np->curr_rtime;
    800024be:	1a04a783          	lw	a5,416(s1)
    800024c2:	00fc2023          	sw	a5,0(s8)
          *wtime = np->curr_wtime;
    800024c6:	1a44a783          	lw	a5,420(s1)
    800024ca:	00fba023          	sw	a5,0(s7) # fffffffffffff000 <end+0xffffffff7ffda288>
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800024ce:	000b0e63          	beqz	s6,800024ea <waitx+0x8e>
    800024d2:	4691                	li	a3,4
    800024d4:	02c48613          	addi	a2,s1,44
    800024d8:	85da                	mv	a1,s6
    800024da:	05093503          	ld	a0,80(s2)
    800024de:	fffff097          	auipc	ra,0xfffff
    800024e2:	1a6080e7          	jalr	422(ra) # 80001684 <copyout>
    800024e6:	02054563          	bltz	a0,80002510 <waitx+0xb4>
          freeproc(np);
    800024ea:	8526                	mv	a0,s1
    800024ec:	00000097          	auipc	ra,0x0
    800024f0:	87a080e7          	jalr	-1926(ra) # 80001d66 <freeproc>
          release(&np->lock);
    800024f4:	8526                	mv	a0,s1
    800024f6:	ffffe097          	auipc	ra,0xffffe
    800024fa:	7a8080e7          	jalr	1960(ra) # 80000c9e <release>
          release(&wait_lock);
    800024fe:	0000f517          	auipc	a0,0xf
    80002502:	88a50513          	addi	a0,a0,-1910 # 80010d88 <wait_lock>
    80002506:	ffffe097          	auipc	ra,0xffffe
    8000250a:	798080e7          	jalr	1944(ra) # 80000c9e <release>
          return pid;
    8000250e:	a09d                	j	80002574 <waitx+0x118>
            release(&np->lock);
    80002510:	8526                	mv	a0,s1
    80002512:	ffffe097          	auipc	ra,0xffffe
    80002516:	78c080e7          	jalr	1932(ra) # 80000c9e <release>
            release(&wait_lock);
    8000251a:	0000f517          	auipc	a0,0xf
    8000251e:	86e50513          	addi	a0,a0,-1938 # 80010d88 <wait_lock>
    80002522:	ffffe097          	auipc	ra,0xffffe
    80002526:	77c080e7          	jalr	1916(ra) # 80000c9e <release>
            return -1;
    8000252a:	59fd                	li	s3,-1
    8000252c:	a0a1                	j	80002574 <waitx+0x118>
    for(np = proc; np < &proc[NPROC]; np++){
    8000252e:	1a848493          	addi	s1,s1,424
    80002532:	03348463          	beq	s1,s3,8000255a <waitx+0xfe>
      if(np->parent == p){
    80002536:	7c9c                	ld	a5,56(s1)
    80002538:	ff279be3          	bne	a5,s2,8000252e <waitx+0xd2>
        acquire(&np->lock);
    8000253c:	8526                	mv	a0,s1
    8000253e:	ffffe097          	auipc	ra,0xffffe
    80002542:	6ac080e7          	jalr	1708(ra) # 80000bea <acquire>
        if(np->state == ZOMBIE){
    80002546:	4c9c                	lw	a5,24(s1)
    80002548:	f74789e3          	beq	a5,s4,800024ba <waitx+0x5e>
        release(&np->lock);
    8000254c:	8526                	mv	a0,s1
    8000254e:	ffffe097          	auipc	ra,0xffffe
    80002552:	750080e7          	jalr	1872(ra) # 80000c9e <release>
        havekids = 1;
    80002556:	8756                	mv	a4,s5
    80002558:	bfd9                	j	8000252e <waitx+0xd2>
    if(!havekids || p->killed){
    8000255a:	c701                	beqz	a4,80002562 <waitx+0x106>
    8000255c:	02892783          	lw	a5,40(s2)
    80002560:	cb8d                	beqz	a5,80002592 <waitx+0x136>
      release(&wait_lock);
    80002562:	0000f517          	auipc	a0,0xf
    80002566:	82650513          	addi	a0,a0,-2010 # 80010d88 <wait_lock>
    8000256a:	ffffe097          	auipc	ra,0xffffe
    8000256e:	734080e7          	jalr	1844(ra) # 80000c9e <release>
      return -1;
    80002572:	59fd                	li	s3,-1
}
    80002574:	854e                	mv	a0,s3
    80002576:	60e6                	ld	ra,88(sp)
    80002578:	6446                	ld	s0,80(sp)
    8000257a:	64a6                	ld	s1,72(sp)
    8000257c:	6906                	ld	s2,64(sp)
    8000257e:	79e2                	ld	s3,56(sp)
    80002580:	7a42                	ld	s4,48(sp)
    80002582:	7aa2                	ld	s5,40(sp)
    80002584:	7b02                	ld	s6,32(sp)
    80002586:	6be2                	ld	s7,24(sp)
    80002588:	6c42                	ld	s8,16(sp)
    8000258a:	6ca2                	ld	s9,8(sp)
    8000258c:	6d02                	ld	s10,0(sp)
    8000258e:	6125                	addi	sp,sp,96
    80002590:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002592:	85ea                	mv	a1,s10
    80002594:	854a                	mv	a0,s2
    80002596:	00000097          	auipc	ra,0x0
    8000259a:	e62080e7          	jalr	-414(ra) # 800023f8 <sleep>
    havekids = 0;
    8000259e:	bf01                	j	800024ae <waitx+0x52>

00000000800025a0 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800025a0:	7139                	addi	sp,sp,-64
    800025a2:	fc06                	sd	ra,56(sp)
    800025a4:	f822                	sd	s0,48(sp)
    800025a6:	f426                	sd	s1,40(sp)
    800025a8:	f04a                	sd	s2,32(sp)
    800025aa:	ec4e                	sd	s3,24(sp)
    800025ac:	e852                	sd	s4,16(sp)
    800025ae:	e456                	sd	s5,8(sp)
    800025b0:	0080                	addi	s0,sp,64
    800025b2:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800025b4:	0000f497          	auipc	s1,0xf
    800025b8:	66448493          	addi	s1,s1,1636 # 80011c18 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800025bc:	4989                	li	s3,2
        p->state = RUNNABLE;
    800025be:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800025c0:	00016917          	auipc	s2,0x16
    800025c4:	05890913          	addi	s2,s2,88 # 80018618 <tickslock>
    800025c8:	a821                	j	800025e0 <wakeup+0x40>
        p->state = RUNNABLE;
    800025ca:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    800025ce:	8526                	mv	a0,s1
    800025d0:	ffffe097          	auipc	ra,0xffffe
    800025d4:	6ce080e7          	jalr	1742(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800025d8:	1a848493          	addi	s1,s1,424
    800025dc:	03248463          	beq	s1,s2,80002604 <wakeup+0x64>
    if(p != myproc()){
    800025e0:	fffff097          	auipc	ra,0xfffff
    800025e4:	5d4080e7          	jalr	1492(ra) # 80001bb4 <myproc>
    800025e8:	fea488e3          	beq	s1,a0,800025d8 <wakeup+0x38>
      acquire(&p->lock);
    800025ec:	8526                	mv	a0,s1
    800025ee:	ffffe097          	auipc	ra,0xffffe
    800025f2:	5fc080e7          	jalr	1532(ra) # 80000bea <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800025f6:	4c9c                	lw	a5,24(s1)
    800025f8:	fd379be3          	bne	a5,s3,800025ce <wakeup+0x2e>
    800025fc:	709c                	ld	a5,32(s1)
    800025fe:	fd4798e3          	bne	a5,s4,800025ce <wakeup+0x2e>
    80002602:	b7e1                	j	800025ca <wakeup+0x2a>
    }
  }
}
    80002604:	70e2                	ld	ra,56(sp)
    80002606:	7442                	ld	s0,48(sp)
    80002608:	74a2                	ld	s1,40(sp)
    8000260a:	7902                	ld	s2,32(sp)
    8000260c:	69e2                	ld	s3,24(sp)
    8000260e:	6a42                	ld	s4,16(sp)
    80002610:	6aa2                	ld	s5,8(sp)
    80002612:	6121                	addi	sp,sp,64
    80002614:	8082                	ret

0000000080002616 <reparent>:
{
    80002616:	7179                	addi	sp,sp,-48
    80002618:	f406                	sd	ra,40(sp)
    8000261a:	f022                	sd	s0,32(sp)
    8000261c:	ec26                	sd	s1,24(sp)
    8000261e:	e84a                	sd	s2,16(sp)
    80002620:	e44e                	sd	s3,8(sp)
    80002622:	e052                	sd	s4,0(sp)
    80002624:	1800                	addi	s0,sp,48
    80002626:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002628:	0000f497          	auipc	s1,0xf
    8000262c:	5f048493          	addi	s1,s1,1520 # 80011c18 <proc>
      pp->parent = initproc;
    80002630:	00006a17          	auipc	s4,0x6
    80002634:	4c8a0a13          	addi	s4,s4,1224 # 80008af8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002638:	00016997          	auipc	s3,0x16
    8000263c:	fe098993          	addi	s3,s3,-32 # 80018618 <tickslock>
    80002640:	a029                	j	8000264a <reparent+0x34>
    80002642:	1a848493          	addi	s1,s1,424
    80002646:	01348d63          	beq	s1,s3,80002660 <reparent+0x4a>
    if(pp->parent == p){
    8000264a:	7c9c                	ld	a5,56(s1)
    8000264c:	ff279be3          	bne	a5,s2,80002642 <reparent+0x2c>
      pp->parent = initproc;
    80002650:	000a3503          	ld	a0,0(s4)
    80002654:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002656:	00000097          	auipc	ra,0x0
    8000265a:	f4a080e7          	jalr	-182(ra) # 800025a0 <wakeup>
    8000265e:	b7d5                	j	80002642 <reparent+0x2c>
}
    80002660:	70a2                	ld	ra,40(sp)
    80002662:	7402                	ld	s0,32(sp)
    80002664:	64e2                	ld	s1,24(sp)
    80002666:	6942                	ld	s2,16(sp)
    80002668:	69a2                	ld	s3,8(sp)
    8000266a:	6a02                	ld	s4,0(sp)
    8000266c:	6145                	addi	sp,sp,48
    8000266e:	8082                	ret

0000000080002670 <exit>:
{
    80002670:	7179                	addi	sp,sp,-48
    80002672:	f406                	sd	ra,40(sp)
    80002674:	f022                	sd	s0,32(sp)
    80002676:	ec26                	sd	s1,24(sp)
    80002678:	e84a                	sd	s2,16(sp)
    8000267a:	e44e                	sd	s3,8(sp)
    8000267c:	e052                	sd	s4,0(sp)
    8000267e:	1800                	addi	s0,sp,48
    80002680:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002682:	fffff097          	auipc	ra,0xfffff
    80002686:	532080e7          	jalr	1330(ra) # 80001bb4 <myproc>
    8000268a:	89aa                	mv	s3,a0
  if(p == initproc)
    8000268c:	00006797          	auipc	a5,0x6
    80002690:	46c7b783          	ld	a5,1132(a5) # 80008af8 <initproc>
    80002694:	0d050493          	addi	s1,a0,208
    80002698:	15050913          	addi	s2,a0,336
    8000269c:	02a79363          	bne	a5,a0,800026c2 <exit+0x52>
    panic("init exiting");
    800026a0:	00006517          	auipc	a0,0x6
    800026a4:	be050513          	addi	a0,a0,-1056 # 80008280 <digits+0x240>
    800026a8:	ffffe097          	auipc	ra,0xffffe
    800026ac:	e9c080e7          	jalr	-356(ra) # 80000544 <panic>
      fileclose(f);
    800026b0:	00002097          	auipc	ra,0x2
    800026b4:	628080e7          	jalr	1576(ra) # 80004cd8 <fileclose>
      p->ofile[fd] = 0;
    800026b8:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800026bc:	04a1                	addi	s1,s1,8
    800026be:	01248563          	beq	s1,s2,800026c8 <exit+0x58>
    if(p->ofile[fd]){
    800026c2:	6088                	ld	a0,0(s1)
    800026c4:	f575                	bnez	a0,800026b0 <exit+0x40>
    800026c6:	bfdd                	j	800026bc <exit+0x4c>
  begin_op();
    800026c8:	00002097          	auipc	ra,0x2
    800026cc:	144080e7          	jalr	324(ra) # 8000480c <begin_op>
  iput(p->cwd);
    800026d0:	1509b503          	ld	a0,336(s3)
    800026d4:	00002097          	auipc	ra,0x2
    800026d8:	930080e7          	jalr	-1744(ra) # 80004004 <iput>
  end_op();
    800026dc:	00002097          	auipc	ra,0x2
    800026e0:	1b0080e7          	jalr	432(ra) # 8000488c <end_op>
  p->cwd = 0;
    800026e4:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800026e8:	0000e497          	auipc	s1,0xe
    800026ec:	6a048493          	addi	s1,s1,1696 # 80010d88 <wait_lock>
    800026f0:	8526                	mv	a0,s1
    800026f2:	ffffe097          	auipc	ra,0xffffe
    800026f6:	4f8080e7          	jalr	1272(ra) # 80000bea <acquire>
  reparent(p);
    800026fa:	854e                	mv	a0,s3
    800026fc:	00000097          	auipc	ra,0x0
    80002700:	f1a080e7          	jalr	-230(ra) # 80002616 <reparent>
  wakeup(p->parent);
    80002704:	0389b503          	ld	a0,56(s3)
    80002708:	00000097          	auipc	ra,0x0
    8000270c:	e98080e7          	jalr	-360(ra) # 800025a0 <wakeup>
  acquire(&p->lock);
    80002710:	854e                	mv	a0,s3
    80002712:	ffffe097          	auipc	ra,0xffffe
    80002716:	4d8080e7          	jalr	1240(ra) # 80000bea <acquire>
  p->xstate = status;
    8000271a:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000271e:	4795                	li	a5,5
    80002720:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002724:	00006797          	auipc	a5,0x6
    80002728:	3dc7a783          	lw	a5,988(a5) # 80008b00 <ticks>
    8000272c:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    80002730:	8526                	mv	a0,s1
    80002732:	ffffe097          	auipc	ra,0xffffe
    80002736:	56c080e7          	jalr	1388(ra) # 80000c9e <release>
  sched();
    8000273a:	00000097          	auipc	ra,0x0
    8000273e:	b0a080e7          	jalr	-1270(ra) # 80002244 <sched>
  panic("zombie exit");
    80002742:	00006517          	auipc	a0,0x6
    80002746:	b4e50513          	addi	a0,a0,-1202 # 80008290 <digits+0x250>
    8000274a:	ffffe097          	auipc	ra,0xffffe
    8000274e:	dfa080e7          	jalr	-518(ra) # 80000544 <panic>

0000000080002752 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002752:	7179                	addi	sp,sp,-48
    80002754:	f406                	sd	ra,40(sp)
    80002756:	f022                	sd	s0,32(sp)
    80002758:	ec26                	sd	s1,24(sp)
    8000275a:	e84a                	sd	s2,16(sp)
    8000275c:	e44e                	sd	s3,8(sp)
    8000275e:	1800                	addi	s0,sp,48
    80002760:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002762:	0000f497          	auipc	s1,0xf
    80002766:	4b648493          	addi	s1,s1,1206 # 80011c18 <proc>
    8000276a:	00016997          	auipc	s3,0x16
    8000276e:	eae98993          	addi	s3,s3,-338 # 80018618 <tickslock>
    acquire(&p->lock);
    80002772:	8526                	mv	a0,s1
    80002774:	ffffe097          	auipc	ra,0xffffe
    80002778:	476080e7          	jalr	1142(ra) # 80000bea <acquire>
    if(p->pid == pid){
    8000277c:	589c                	lw	a5,48(s1)
    8000277e:	01278d63          	beq	a5,s2,80002798 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002782:	8526                	mv	a0,s1
    80002784:	ffffe097          	auipc	ra,0xffffe
    80002788:	51a080e7          	jalr	1306(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000278c:	1a848493          	addi	s1,s1,424
    80002790:	ff3491e3          	bne	s1,s3,80002772 <kill+0x20>
  }
  return -1;
    80002794:	557d                	li	a0,-1
    80002796:	a829                	j	800027b0 <kill+0x5e>
      p->killed = 1;
    80002798:	4785                	li	a5,1
    8000279a:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000279c:	4c98                	lw	a4,24(s1)
    8000279e:	4789                	li	a5,2
    800027a0:	00f70f63          	beq	a4,a5,800027be <kill+0x6c>
      release(&p->lock);
    800027a4:	8526                	mv	a0,s1
    800027a6:	ffffe097          	auipc	ra,0xffffe
    800027aa:	4f8080e7          	jalr	1272(ra) # 80000c9e <release>
      return 0;
    800027ae:	4501                	li	a0,0
}
    800027b0:	70a2                	ld	ra,40(sp)
    800027b2:	7402                	ld	s0,32(sp)
    800027b4:	64e2                	ld	s1,24(sp)
    800027b6:	6942                	ld	s2,16(sp)
    800027b8:	69a2                	ld	s3,8(sp)
    800027ba:	6145                	addi	sp,sp,48
    800027bc:	8082                	ret
        p->state = RUNNABLE;
    800027be:	478d                	li	a5,3
    800027c0:	cc9c                	sw	a5,24(s1)
    800027c2:	b7cd                	j	800027a4 <kill+0x52>

00000000800027c4 <setkilled>:

void
setkilled(struct proc *p)
{
    800027c4:	1101                	addi	sp,sp,-32
    800027c6:	ec06                	sd	ra,24(sp)
    800027c8:	e822                	sd	s0,16(sp)
    800027ca:	e426                	sd	s1,8(sp)
    800027cc:	1000                	addi	s0,sp,32
    800027ce:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800027d0:	ffffe097          	auipc	ra,0xffffe
    800027d4:	41a080e7          	jalr	1050(ra) # 80000bea <acquire>
  p->killed = 1;
    800027d8:	4785                	li	a5,1
    800027da:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800027dc:	8526                	mv	a0,s1
    800027de:	ffffe097          	auipc	ra,0xffffe
    800027e2:	4c0080e7          	jalr	1216(ra) # 80000c9e <release>
}
    800027e6:	60e2                	ld	ra,24(sp)
    800027e8:	6442                	ld	s0,16(sp)
    800027ea:	64a2                	ld	s1,8(sp)
    800027ec:	6105                	addi	sp,sp,32
    800027ee:	8082                	ret

00000000800027f0 <killed>:

int
killed(struct proc *p)
{
    800027f0:	1101                	addi	sp,sp,-32
    800027f2:	ec06                	sd	ra,24(sp)
    800027f4:	e822                	sd	s0,16(sp)
    800027f6:	e426                	sd	s1,8(sp)
    800027f8:	e04a                	sd	s2,0(sp)
    800027fa:	1000                	addi	s0,sp,32
    800027fc:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800027fe:	ffffe097          	auipc	ra,0xffffe
    80002802:	3ec080e7          	jalr	1004(ra) # 80000bea <acquire>
  k = p->killed;
    80002806:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000280a:	8526                	mv	a0,s1
    8000280c:	ffffe097          	auipc	ra,0xffffe
    80002810:	492080e7          	jalr	1170(ra) # 80000c9e <release>
  return k;
}
    80002814:	854a                	mv	a0,s2
    80002816:	60e2                	ld	ra,24(sp)
    80002818:	6442                	ld	s0,16(sp)
    8000281a:	64a2                	ld	s1,8(sp)
    8000281c:	6902                	ld	s2,0(sp)
    8000281e:	6105                	addi	sp,sp,32
    80002820:	8082                	ret

0000000080002822 <wait>:
{
    80002822:	715d                	addi	sp,sp,-80
    80002824:	e486                	sd	ra,72(sp)
    80002826:	e0a2                	sd	s0,64(sp)
    80002828:	fc26                	sd	s1,56(sp)
    8000282a:	f84a                	sd	s2,48(sp)
    8000282c:	f44e                	sd	s3,40(sp)
    8000282e:	f052                	sd	s4,32(sp)
    80002830:	ec56                	sd	s5,24(sp)
    80002832:	e85a                	sd	s6,16(sp)
    80002834:	e45e                	sd	s7,8(sp)
    80002836:	e062                	sd	s8,0(sp)
    80002838:	0880                	addi	s0,sp,80
    8000283a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000283c:	fffff097          	auipc	ra,0xfffff
    80002840:	378080e7          	jalr	888(ra) # 80001bb4 <myproc>
    80002844:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002846:	0000e517          	auipc	a0,0xe
    8000284a:	54250513          	addi	a0,a0,1346 # 80010d88 <wait_lock>
    8000284e:	ffffe097          	auipc	ra,0xffffe
    80002852:	39c080e7          	jalr	924(ra) # 80000bea <acquire>
    havekids = 0;
    80002856:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002858:	4a15                	li	s4,5
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000285a:	00016997          	auipc	s3,0x16
    8000285e:	dbe98993          	addi	s3,s3,-578 # 80018618 <tickslock>
        havekids = 1;
    80002862:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002864:	0000ec17          	auipc	s8,0xe
    80002868:	524c0c13          	addi	s8,s8,1316 # 80010d88 <wait_lock>
    havekids = 0;
    8000286c:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000286e:	0000f497          	auipc	s1,0xf
    80002872:	3aa48493          	addi	s1,s1,938 # 80011c18 <proc>
    80002876:	a0bd                	j	800028e4 <wait+0xc2>
          pid = pp->pid;
    80002878:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000287c:	000b0e63          	beqz	s6,80002898 <wait+0x76>
    80002880:	4691                	li	a3,4
    80002882:	02c48613          	addi	a2,s1,44
    80002886:	85da                	mv	a1,s6
    80002888:	05093503          	ld	a0,80(s2)
    8000288c:	fffff097          	auipc	ra,0xfffff
    80002890:	df8080e7          	jalr	-520(ra) # 80001684 <copyout>
    80002894:	02054563          	bltz	a0,800028be <wait+0x9c>
          freeproc(pp);
    80002898:	8526                	mv	a0,s1
    8000289a:	fffff097          	auipc	ra,0xfffff
    8000289e:	4cc080e7          	jalr	1228(ra) # 80001d66 <freeproc>
          release(&pp->lock);
    800028a2:	8526                	mv	a0,s1
    800028a4:	ffffe097          	auipc	ra,0xffffe
    800028a8:	3fa080e7          	jalr	1018(ra) # 80000c9e <release>
          release(&wait_lock);
    800028ac:	0000e517          	auipc	a0,0xe
    800028b0:	4dc50513          	addi	a0,a0,1244 # 80010d88 <wait_lock>
    800028b4:	ffffe097          	auipc	ra,0xffffe
    800028b8:	3ea080e7          	jalr	1002(ra) # 80000c9e <release>
          return pid;
    800028bc:	a0b5                	j	80002928 <wait+0x106>
            release(&pp->lock);
    800028be:	8526                	mv	a0,s1
    800028c0:	ffffe097          	auipc	ra,0xffffe
    800028c4:	3de080e7          	jalr	990(ra) # 80000c9e <release>
            release(&wait_lock);
    800028c8:	0000e517          	auipc	a0,0xe
    800028cc:	4c050513          	addi	a0,a0,1216 # 80010d88 <wait_lock>
    800028d0:	ffffe097          	auipc	ra,0xffffe
    800028d4:	3ce080e7          	jalr	974(ra) # 80000c9e <release>
            return -1;
    800028d8:	59fd                	li	s3,-1
    800028da:	a0b9                	j	80002928 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800028dc:	1a848493          	addi	s1,s1,424
    800028e0:	03348463          	beq	s1,s3,80002908 <wait+0xe6>
      if(pp->parent == p){
    800028e4:	7c9c                	ld	a5,56(s1)
    800028e6:	ff279be3          	bne	a5,s2,800028dc <wait+0xba>
        acquire(&pp->lock);
    800028ea:	8526                	mv	a0,s1
    800028ec:	ffffe097          	auipc	ra,0xffffe
    800028f0:	2fe080e7          	jalr	766(ra) # 80000bea <acquire>
        if(pp->state == ZOMBIE){
    800028f4:	4c9c                	lw	a5,24(s1)
    800028f6:	f94781e3          	beq	a5,s4,80002878 <wait+0x56>
        release(&pp->lock);
    800028fa:	8526                	mv	a0,s1
    800028fc:	ffffe097          	auipc	ra,0xffffe
    80002900:	3a2080e7          	jalr	930(ra) # 80000c9e <release>
        havekids = 1;
    80002904:	8756                	mv	a4,s5
    80002906:	bfd9                	j	800028dc <wait+0xba>
    if(!havekids || killed(p)){
    80002908:	c719                	beqz	a4,80002916 <wait+0xf4>
    8000290a:	854a                	mv	a0,s2
    8000290c:	00000097          	auipc	ra,0x0
    80002910:	ee4080e7          	jalr	-284(ra) # 800027f0 <killed>
    80002914:	c51d                	beqz	a0,80002942 <wait+0x120>
      release(&wait_lock);
    80002916:	0000e517          	auipc	a0,0xe
    8000291a:	47250513          	addi	a0,a0,1138 # 80010d88 <wait_lock>
    8000291e:	ffffe097          	auipc	ra,0xffffe
    80002922:	380080e7          	jalr	896(ra) # 80000c9e <release>
      return -1;
    80002926:	59fd                	li	s3,-1
}
    80002928:	854e                	mv	a0,s3
    8000292a:	60a6                	ld	ra,72(sp)
    8000292c:	6406                	ld	s0,64(sp)
    8000292e:	74e2                	ld	s1,56(sp)
    80002930:	7942                	ld	s2,48(sp)
    80002932:	79a2                	ld	s3,40(sp)
    80002934:	7a02                	ld	s4,32(sp)
    80002936:	6ae2                	ld	s5,24(sp)
    80002938:	6b42                	ld	s6,16(sp)
    8000293a:	6ba2                	ld	s7,8(sp)
    8000293c:	6c02                	ld	s8,0(sp)
    8000293e:	6161                	addi	sp,sp,80
    80002940:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002942:	85e2                	mv	a1,s8
    80002944:	854a                	mv	a0,s2
    80002946:	00000097          	auipc	ra,0x0
    8000294a:	ab2080e7          	jalr	-1358(ra) # 800023f8 <sleep>
    havekids = 0;
    8000294e:	bf39                	j	8000286c <wait+0x4a>

0000000080002950 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002950:	7179                	addi	sp,sp,-48
    80002952:	f406                	sd	ra,40(sp)
    80002954:	f022                	sd	s0,32(sp)
    80002956:	ec26                	sd	s1,24(sp)
    80002958:	e84a                	sd	s2,16(sp)
    8000295a:	e44e                	sd	s3,8(sp)
    8000295c:	e052                	sd	s4,0(sp)
    8000295e:	1800                	addi	s0,sp,48
    80002960:	84aa                	mv	s1,a0
    80002962:	892e                	mv	s2,a1
    80002964:	89b2                	mv	s3,a2
    80002966:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002968:	fffff097          	auipc	ra,0xfffff
    8000296c:	24c080e7          	jalr	588(ra) # 80001bb4 <myproc>
  if(user_dst){
    80002970:	c08d                	beqz	s1,80002992 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002972:	86d2                	mv	a3,s4
    80002974:	864e                	mv	a2,s3
    80002976:	85ca                	mv	a1,s2
    80002978:	6928                	ld	a0,80(a0)
    8000297a:	fffff097          	auipc	ra,0xfffff
    8000297e:	d0a080e7          	jalr	-758(ra) # 80001684 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002982:	70a2                	ld	ra,40(sp)
    80002984:	7402                	ld	s0,32(sp)
    80002986:	64e2                	ld	s1,24(sp)
    80002988:	6942                	ld	s2,16(sp)
    8000298a:	69a2                	ld	s3,8(sp)
    8000298c:	6a02                	ld	s4,0(sp)
    8000298e:	6145                	addi	sp,sp,48
    80002990:	8082                	ret
    memmove((char *)dst, src, len);
    80002992:	000a061b          	sext.w	a2,s4
    80002996:	85ce                	mv	a1,s3
    80002998:	854a                	mv	a0,s2
    8000299a:	ffffe097          	auipc	ra,0xffffe
    8000299e:	3ac080e7          	jalr	940(ra) # 80000d46 <memmove>
    return 0;
    800029a2:	8526                	mv	a0,s1
    800029a4:	bff9                	j	80002982 <either_copyout+0x32>

00000000800029a6 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800029a6:	7179                	addi	sp,sp,-48
    800029a8:	f406                	sd	ra,40(sp)
    800029aa:	f022                	sd	s0,32(sp)
    800029ac:	ec26                	sd	s1,24(sp)
    800029ae:	e84a                	sd	s2,16(sp)
    800029b0:	e44e                	sd	s3,8(sp)
    800029b2:	e052                	sd	s4,0(sp)
    800029b4:	1800                	addi	s0,sp,48
    800029b6:	892a                	mv	s2,a0
    800029b8:	84ae                	mv	s1,a1
    800029ba:	89b2                	mv	s3,a2
    800029bc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800029be:	fffff097          	auipc	ra,0xfffff
    800029c2:	1f6080e7          	jalr	502(ra) # 80001bb4 <myproc>
  if(user_src){
    800029c6:	c08d                	beqz	s1,800029e8 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800029c8:	86d2                	mv	a3,s4
    800029ca:	864e                	mv	a2,s3
    800029cc:	85ca                	mv	a1,s2
    800029ce:	6928                	ld	a0,80(a0)
    800029d0:	fffff097          	auipc	ra,0xfffff
    800029d4:	d40080e7          	jalr	-704(ra) # 80001710 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800029d8:	70a2                	ld	ra,40(sp)
    800029da:	7402                	ld	s0,32(sp)
    800029dc:	64e2                	ld	s1,24(sp)
    800029de:	6942                	ld	s2,16(sp)
    800029e0:	69a2                	ld	s3,8(sp)
    800029e2:	6a02                	ld	s4,0(sp)
    800029e4:	6145                	addi	sp,sp,48
    800029e6:	8082                	ret
    memmove(dst, (char*)src, len);
    800029e8:	000a061b          	sext.w	a2,s4
    800029ec:	85ce                	mv	a1,s3
    800029ee:	854a                	mv	a0,s2
    800029f0:	ffffe097          	auipc	ra,0xffffe
    800029f4:	356080e7          	jalr	854(ra) # 80000d46 <memmove>
    return 0;
    800029f8:	8526                	mv	a0,s1
    800029fa:	bff9                	j	800029d8 <either_copyin+0x32>

00000000800029fc <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800029fc:	715d                	addi	sp,sp,-80
    800029fe:	e486                	sd	ra,72(sp)
    80002a00:	e0a2                	sd	s0,64(sp)
    80002a02:	fc26                	sd	s1,56(sp)
    80002a04:	f84a                	sd	s2,48(sp)
    80002a06:	f44e                	sd	s3,40(sp)
    80002a08:	f052                	sd	s4,32(sp)
    80002a0a:	ec56                	sd	s5,24(sp)
    80002a0c:	e85a                	sd	s6,16(sp)
    80002a0e:	e45e                	sd	s7,8(sp)
    80002a10:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002a12:	00005517          	auipc	a0,0x5
    80002a16:	6b650513          	addi	a0,a0,1718 # 800080c8 <digits+0x88>
    80002a1a:	ffffe097          	auipc	ra,0xffffe
    80002a1e:	b74080e7          	jalr	-1164(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a22:	0000f497          	auipc	s1,0xf
    80002a26:	34e48493          	addi	s1,s1,846 # 80011d70 <proc+0x158>
    80002a2a:	00016917          	auipc	s2,0x16
    80002a2e:	d4690913          	addi	s2,s2,-698 # 80018770 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a32:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002a34:	00006997          	auipc	s3,0x6
    80002a38:	86c98993          	addi	s3,s3,-1940 # 800082a0 <digits+0x260>
    printf("%d %s %s", p->pid, state, p->name);
    80002a3c:	00006a97          	auipc	s5,0x6
    80002a40:	86ca8a93          	addi	s5,s5,-1940 # 800082a8 <digits+0x268>
    printf("\n");
    80002a44:	00005a17          	auipc	s4,0x5
    80002a48:	684a0a13          	addi	s4,s4,1668 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a4c:	00006b97          	auipc	s7,0x6
    80002a50:	89cb8b93          	addi	s7,s7,-1892 # 800082e8 <states.1800>
    80002a54:	a00d                	j	80002a76 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002a56:	ed86a583          	lw	a1,-296(a3)
    80002a5a:	8556                	mv	a0,s5
    80002a5c:	ffffe097          	auipc	ra,0xffffe
    80002a60:	b32080e7          	jalr	-1230(ra) # 8000058e <printf>
    printf("\n");
    80002a64:	8552                	mv	a0,s4
    80002a66:	ffffe097          	auipc	ra,0xffffe
    80002a6a:	b28080e7          	jalr	-1240(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a6e:	1a848493          	addi	s1,s1,424
    80002a72:	03248163          	beq	s1,s2,80002a94 <procdump+0x98>
    if(p->state == UNUSED)
    80002a76:	86a6                	mv	a3,s1
    80002a78:	ec04a783          	lw	a5,-320(s1)
    80002a7c:	dbed                	beqz	a5,80002a6e <procdump+0x72>
      state = "???";
    80002a7e:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a80:	fcfb6be3          	bltu	s6,a5,80002a56 <procdump+0x5a>
    80002a84:	1782                	slli	a5,a5,0x20
    80002a86:	9381                	srli	a5,a5,0x20
    80002a88:	078e                	slli	a5,a5,0x3
    80002a8a:	97de                	add	a5,a5,s7
    80002a8c:	6390                	ld	a2,0(a5)
    80002a8e:	f661                	bnez	a2,80002a56 <procdump+0x5a>
      state = "???";
    80002a90:	864e                	mv	a2,s3
    80002a92:	b7d1                	j	80002a56 <procdump+0x5a>
  }
}
    80002a94:	60a6                	ld	ra,72(sp)
    80002a96:	6406                	ld	s0,64(sp)
    80002a98:	74e2                	ld	s1,56(sp)
    80002a9a:	7942                	ld	s2,48(sp)
    80002a9c:	79a2                	ld	s3,40(sp)
    80002a9e:	7a02                	ld	s4,32(sp)
    80002aa0:	6ae2                	ld	s5,24(sp)
    80002aa2:	6b42                	ld	s6,16(sp)
    80002aa4:	6ba2                	ld	s7,8(sp)
    80002aa6:	6161                	addi	sp,sp,80
    80002aa8:	8082                	ret

0000000080002aaa <swtch>:
    80002aaa:	00153023          	sd	ra,0(a0)
    80002aae:	00253423          	sd	sp,8(a0)
    80002ab2:	e900                	sd	s0,16(a0)
    80002ab4:	ed04                	sd	s1,24(a0)
    80002ab6:	03253023          	sd	s2,32(a0)
    80002aba:	03353423          	sd	s3,40(a0)
    80002abe:	03453823          	sd	s4,48(a0)
    80002ac2:	03553c23          	sd	s5,56(a0)
    80002ac6:	05653023          	sd	s6,64(a0)
    80002aca:	05753423          	sd	s7,72(a0)
    80002ace:	05853823          	sd	s8,80(a0)
    80002ad2:	05953c23          	sd	s9,88(a0)
    80002ad6:	07a53023          	sd	s10,96(a0)
    80002ada:	07b53423          	sd	s11,104(a0)
    80002ade:	0005b083          	ld	ra,0(a1)
    80002ae2:	0085b103          	ld	sp,8(a1)
    80002ae6:	6980                	ld	s0,16(a1)
    80002ae8:	6d84                	ld	s1,24(a1)
    80002aea:	0205b903          	ld	s2,32(a1)
    80002aee:	0285b983          	ld	s3,40(a1)
    80002af2:	0305ba03          	ld	s4,48(a1)
    80002af6:	0385ba83          	ld	s5,56(a1)
    80002afa:	0405bb03          	ld	s6,64(a1)
    80002afe:	0485bb83          	ld	s7,72(a1)
    80002b02:	0505bc03          	ld	s8,80(a1)
    80002b06:	0585bc83          	ld	s9,88(a1)
    80002b0a:	0605bd03          	ld	s10,96(a1)
    80002b0e:	0685bd83          	ld	s11,104(a1)
    80002b12:	8082                	ret

0000000080002b14 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002b14:	1141                	addi	sp,sp,-16
    80002b16:	e406                	sd	ra,8(sp)
    80002b18:	e022                	sd	s0,0(sp)
    80002b1a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002b1c:	00005597          	auipc	a1,0x5
    80002b20:	7fc58593          	addi	a1,a1,2044 # 80008318 <states.1800+0x30>
    80002b24:	00016517          	auipc	a0,0x16
    80002b28:	af450513          	addi	a0,a0,-1292 # 80018618 <tickslock>
    80002b2c:	ffffe097          	auipc	ra,0xffffe
    80002b30:	02e080e7          	jalr	46(ra) # 80000b5a <initlock>
}
    80002b34:	60a2                	ld	ra,8(sp)
    80002b36:	6402                	ld	s0,0(sp)
    80002b38:	0141                	addi	sp,sp,16
    80002b3a:	8082                	ret

0000000080002b3c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002b3c:	1141                	addi	sp,sp,-16
    80002b3e:	e422                	sd	s0,8(sp)
    80002b40:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b42:	00003797          	auipc	a5,0x3
    80002b46:	7ce78793          	addi	a5,a5,1998 # 80006310 <kernelvec>
    80002b4a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002b4e:	6422                	ld	s0,8(sp)
    80002b50:	0141                	addi	sp,sp,16
    80002b52:	8082                	ret

0000000080002b54 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002b54:	1141                	addi	sp,sp,-16
    80002b56:	e406                	sd	ra,8(sp)
    80002b58:	e022                	sd	s0,0(sp)
    80002b5a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002b5c:	fffff097          	auipc	ra,0xfffff
    80002b60:	058080e7          	jalr	88(ra) # 80001bb4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002b68:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b6a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002b6e:	00004617          	auipc	a2,0x4
    80002b72:	49260613          	addi	a2,a2,1170 # 80007000 <_trampoline>
    80002b76:	00004697          	auipc	a3,0x4
    80002b7a:	48a68693          	addi	a3,a3,1162 # 80007000 <_trampoline>
    80002b7e:	8e91                	sub	a3,a3,a2
    80002b80:	040007b7          	lui	a5,0x4000
    80002b84:	17fd                	addi	a5,a5,-1
    80002b86:	07b2                	slli	a5,a5,0xc
    80002b88:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b8a:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002b8e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002b90:	180026f3          	csrr	a3,satp
    80002b94:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002b96:	6d38                	ld	a4,88(a0)
    80002b98:	6134                	ld	a3,64(a0)
    80002b9a:	6585                	lui	a1,0x1
    80002b9c:	96ae                	add	a3,a3,a1
    80002b9e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002ba0:	6d38                	ld	a4,88(a0)
    80002ba2:	00000697          	auipc	a3,0x0
    80002ba6:	13e68693          	addi	a3,a3,318 # 80002ce0 <usertrap>
    80002baa:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002bac:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002bae:	8692                	mv	a3,tp
    80002bb0:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bb2:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002bb6:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002bba:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bbe:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002bc2:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002bc4:	6f18                	ld	a4,24(a4)
    80002bc6:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002bca:	6928                	ld	a0,80(a0)
    80002bcc:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002bce:	00004717          	auipc	a4,0x4
    80002bd2:	4ce70713          	addi	a4,a4,1230 # 8000709c <userret>
    80002bd6:	8f11                	sub	a4,a4,a2
    80002bd8:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002bda:	577d                	li	a4,-1
    80002bdc:	177e                	slli	a4,a4,0x3f
    80002bde:	8d59                	or	a0,a0,a4
    80002be0:	9782                	jalr	a5
}
    80002be2:	60a2                	ld	ra,8(sp)
    80002be4:	6402                	ld	s0,0(sp)
    80002be6:	0141                	addi	sp,sp,16
    80002be8:	8082                	ret

0000000080002bea <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002bea:	1101                	addi	sp,sp,-32
    80002bec:	ec06                	sd	ra,24(sp)
    80002bee:	e822                	sd	s0,16(sp)
    80002bf0:	e426                	sd	s1,8(sp)
    80002bf2:	e04a                	sd	s2,0(sp)
    80002bf4:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002bf6:	00016917          	auipc	s2,0x16
    80002bfa:	a2290913          	addi	s2,s2,-1502 # 80018618 <tickslock>
    80002bfe:	854a                	mv	a0,s2
    80002c00:	ffffe097          	auipc	ra,0xffffe
    80002c04:	fea080e7          	jalr	-22(ra) # 80000bea <acquire>
  ticks++;
    80002c08:	00006497          	auipc	s1,0x6
    80002c0c:	ef848493          	addi	s1,s1,-264 # 80008b00 <ticks>
    80002c10:	409c                	lw	a5,0(s1)
    80002c12:	2785                	addiw	a5,a5,1
    80002c14:	c09c                	sw	a5,0(s1)
  update_time();
    80002c16:	fffff097          	auipc	ra,0xfffff
    80002c1a:	740080e7          	jalr	1856(ra) # 80002356 <update_time>
  wakeup(&ticks);
    80002c1e:	8526                	mv	a0,s1
    80002c20:	00000097          	auipc	ra,0x0
    80002c24:	980080e7          	jalr	-1664(ra) # 800025a0 <wakeup>
  release(&tickslock);
    80002c28:	854a                	mv	a0,s2
    80002c2a:	ffffe097          	auipc	ra,0xffffe
    80002c2e:	074080e7          	jalr	116(ra) # 80000c9e <release>
}
    80002c32:	60e2                	ld	ra,24(sp)
    80002c34:	6442                	ld	s0,16(sp)
    80002c36:	64a2                	ld	s1,8(sp)
    80002c38:	6902                	ld	s2,0(sp)
    80002c3a:	6105                	addi	sp,sp,32
    80002c3c:	8082                	ret

0000000080002c3e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002c3e:	1101                	addi	sp,sp,-32
    80002c40:	ec06                	sd	ra,24(sp)
    80002c42:	e822                	sd	s0,16(sp)
    80002c44:	e426                	sd	s1,8(sp)
    80002c46:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c48:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002c4c:	00074d63          	bltz	a4,80002c66 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002c50:	57fd                	li	a5,-1
    80002c52:	17fe                	slli	a5,a5,0x3f
    80002c54:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002c56:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002c58:	06f70363          	beq	a4,a5,80002cbe <devintr+0x80>
  }
}
    80002c5c:	60e2                	ld	ra,24(sp)
    80002c5e:	6442                	ld	s0,16(sp)
    80002c60:	64a2                	ld	s1,8(sp)
    80002c62:	6105                	addi	sp,sp,32
    80002c64:	8082                	ret
     (scause & 0xff) == 9){
    80002c66:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002c6a:	46a5                	li	a3,9
    80002c6c:	fed792e3          	bne	a5,a3,80002c50 <devintr+0x12>
    int irq = plic_claim();
    80002c70:	00003097          	auipc	ra,0x3
    80002c74:	7a8080e7          	jalr	1960(ra) # 80006418 <plic_claim>
    80002c78:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002c7a:	47a9                	li	a5,10
    80002c7c:	02f50763          	beq	a0,a5,80002caa <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002c80:	4785                	li	a5,1
    80002c82:	02f50963          	beq	a0,a5,80002cb4 <devintr+0x76>
    return 1;
    80002c86:	4505                	li	a0,1
    } else if(irq){
    80002c88:	d8f1                	beqz	s1,80002c5c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002c8a:	85a6                	mv	a1,s1
    80002c8c:	00005517          	auipc	a0,0x5
    80002c90:	69450513          	addi	a0,a0,1684 # 80008320 <states.1800+0x38>
    80002c94:	ffffe097          	auipc	ra,0xffffe
    80002c98:	8fa080e7          	jalr	-1798(ra) # 8000058e <printf>
      plic_complete(irq);
    80002c9c:	8526                	mv	a0,s1
    80002c9e:	00003097          	auipc	ra,0x3
    80002ca2:	79e080e7          	jalr	1950(ra) # 8000643c <plic_complete>
    return 1;
    80002ca6:	4505                	li	a0,1
    80002ca8:	bf55                	j	80002c5c <devintr+0x1e>
      uartintr();
    80002caa:	ffffe097          	auipc	ra,0xffffe
    80002cae:	d04080e7          	jalr	-764(ra) # 800009ae <uartintr>
    80002cb2:	b7ed                	j	80002c9c <devintr+0x5e>
      virtio_disk_intr();
    80002cb4:	00004097          	auipc	ra,0x4
    80002cb8:	cb2080e7          	jalr	-846(ra) # 80006966 <virtio_disk_intr>
    80002cbc:	b7c5                	j	80002c9c <devintr+0x5e>
    if(cpuid() == 0){
    80002cbe:	fffff097          	auipc	ra,0xfffff
    80002cc2:	eca080e7          	jalr	-310(ra) # 80001b88 <cpuid>
    80002cc6:	c901                	beqz	a0,80002cd6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002cc8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002ccc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002cce:	14479073          	csrw	sip,a5
    return 2;
    80002cd2:	4509                	li	a0,2
    80002cd4:	b761                	j	80002c5c <devintr+0x1e>
      clockintr();
    80002cd6:	00000097          	auipc	ra,0x0
    80002cda:	f14080e7          	jalr	-236(ra) # 80002bea <clockintr>
    80002cde:	b7ed                	j	80002cc8 <devintr+0x8a>

0000000080002ce0 <usertrap>:
{
    80002ce0:	7179                	addi	sp,sp,-48
    80002ce2:	f406                	sd	ra,40(sp)
    80002ce4:	f022                	sd	s0,32(sp)
    80002ce6:	ec26                	sd	s1,24(sp)
    80002ce8:	e84a                	sd	s2,16(sp)
    80002cea:	e44e                	sd	s3,8(sp)
    80002cec:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cee:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002cf2:	1007f793          	andi	a5,a5,256
    80002cf6:	e3a5                	bnez	a5,80002d56 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cf8:	00003797          	auipc	a5,0x3
    80002cfc:	61878793          	addi	a5,a5,1560 # 80006310 <kernelvec>
    80002d00:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002d04:	fffff097          	auipc	ra,0xfffff
    80002d08:	eb0080e7          	jalr	-336(ra) # 80001bb4 <myproc>
    80002d0c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002d0e:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d10:	14102773          	csrr	a4,sepc
    80002d14:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d16:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002d1a:	47a1                	li	a5,8
    80002d1c:	04f70563          	beq	a4,a5,80002d66 <usertrap+0x86>
  } else if((which_dev = devintr()) != 0){
    80002d20:	00000097          	auipc	ra,0x0
    80002d24:	f1e080e7          	jalr	-226(ra) # 80002c3e <devintr>
    80002d28:	892a                	mv	s2,a0
    80002d2a:	cd69                	beqz	a0,80002e04 <usertrap+0x124>
    if(which_dev == 2 && myproc()->interval) {
    80002d2c:	4789                	li	a5,2
    80002d2e:	06f50763          	beq	a0,a5,80002d9c <usertrap+0xbc>
  if(killed(p))
    80002d32:	8526                	mv	a0,s1
    80002d34:	00000097          	auipc	ra,0x0
    80002d38:	abc080e7          	jalr	-1348(ra) # 800027f0 <killed>
    80002d3c:	10051163          	bnez	a0,80002e3e <usertrap+0x15e>
  usertrapret();
    80002d40:	00000097          	auipc	ra,0x0
    80002d44:	e14080e7          	jalr	-492(ra) # 80002b54 <usertrapret>
}
    80002d48:	70a2                	ld	ra,40(sp)
    80002d4a:	7402                	ld	s0,32(sp)
    80002d4c:	64e2                	ld	s1,24(sp)
    80002d4e:	6942                	ld	s2,16(sp)
    80002d50:	69a2                	ld	s3,8(sp)
    80002d52:	6145                	addi	sp,sp,48
    80002d54:	8082                	ret
    panic("usertrap: not from user mode");
    80002d56:	00005517          	auipc	a0,0x5
    80002d5a:	5ea50513          	addi	a0,a0,1514 # 80008340 <states.1800+0x58>
    80002d5e:	ffffd097          	auipc	ra,0xffffd
    80002d62:	7e6080e7          	jalr	2022(ra) # 80000544 <panic>
    if(killed(p))
    80002d66:	00000097          	auipc	ra,0x0
    80002d6a:	a8a080e7          	jalr	-1398(ra) # 800027f0 <killed>
    80002d6e:	e10d                	bnez	a0,80002d90 <usertrap+0xb0>
    p->trapframe->epc += 4;
    80002d70:	6cb8                	ld	a4,88(s1)
    80002d72:	6f1c                	ld	a5,24(a4)
    80002d74:	0791                	addi	a5,a5,4
    80002d76:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d78:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002d7c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d80:	10079073          	csrw	sstatus,a5
    syscall();
    80002d84:	00000097          	auipc	ra,0x0
    80002d88:	404080e7          	jalr	1028(ra) # 80003188 <syscall>
  int which_dev = 0;
    80002d8c:	4901                	li	s2,0
    80002d8e:	b755                	j	80002d32 <usertrap+0x52>
      exit(-1);
    80002d90:	557d                	li	a0,-1
    80002d92:	00000097          	auipc	ra,0x0
    80002d96:	8de080e7          	jalr	-1826(ra) # 80002670 <exit>
    80002d9a:	bfd9                	j	80002d70 <usertrap+0x90>
    if(which_dev == 2 && myproc()->interval) {
    80002d9c:	fffff097          	auipc	ra,0xfffff
    80002da0:	e18080e7          	jalr	-488(ra) # 80001bb4 <myproc>
    80002da4:	17852783          	lw	a5,376(a0)
    80002da8:	ef89                	bnez	a5,80002dc2 <usertrap+0xe2>
  if(killed(p))
    80002daa:	8526                	mv	a0,s1
    80002dac:	00000097          	auipc	ra,0x0
    80002db0:	a44080e7          	jalr	-1468(ra) # 800027f0 <killed>
    80002db4:	cd49                	beqz	a0,80002e4e <usertrap+0x16e>
    exit(-1);
    80002db6:	557d                	li	a0,-1
    80002db8:	00000097          	auipc	ra,0x0
    80002dbc:	8b8080e7          	jalr	-1864(ra) # 80002670 <exit>
    if(which_dev == 2 && myproc()->state == RUNNING && myproc() != 0) {
    80002dc0:	a079                	j	80002e4e <usertrap+0x16e>
      myproc()->ticks_left--;
    80002dc2:	fffff097          	auipc	ra,0xfffff
    80002dc6:	df2080e7          	jalr	-526(ra) # 80001bb4 <myproc>
    80002dca:	17c52783          	lw	a5,380(a0)
    80002dce:	37fd                	addiw	a5,a5,-1
    80002dd0:	16f52e23          	sw	a5,380(a0)
      if(myproc()->ticks_left == 0) {
    80002dd4:	fffff097          	auipc	ra,0xfffff
    80002dd8:	de0080e7          	jalr	-544(ra) # 80001bb4 <myproc>
    80002ddc:	17c52783          	lw	a5,380(a0)
    80002de0:	f7e9                	bnez	a5,80002daa <usertrap+0xca>
        p->sigalarm_tf = kalloc();
    80002de2:	ffffe097          	auipc	ra,0xffffe
    80002de6:	d18080e7          	jalr	-744(ra) # 80000afa <kalloc>
    80002dea:	18a4b423          	sd	a0,392(s1)
        memmove(p->sigalarm_tf, p->trapframe, PGSIZE);
    80002dee:	6605                	lui	a2,0x1
    80002df0:	6cac                	ld	a1,88(s1)
    80002df2:	ffffe097          	auipc	ra,0xffffe
    80002df6:	f54080e7          	jalr	-172(ra) # 80000d46 <memmove>
        p->trapframe->epc = p->sig_handler;
    80002dfa:	6cbc                	ld	a5,88(s1)
    80002dfc:	1804b703          	ld	a4,384(s1)
    80002e00:	ef98                	sd	a4,24(a5)
    80002e02:	b765                	j	80002daa <usertrap+0xca>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e04:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002e08:	5890                	lw	a2,48(s1)
    80002e0a:	00005517          	auipc	a0,0x5
    80002e0e:	55650513          	addi	a0,a0,1366 # 80008360 <states.1800+0x78>
    80002e12:	ffffd097          	auipc	ra,0xffffd
    80002e16:	77c080e7          	jalr	1916(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e1a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e1e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e22:	00005517          	auipc	a0,0x5
    80002e26:	56e50513          	addi	a0,a0,1390 # 80008390 <states.1800+0xa8>
    80002e2a:	ffffd097          	auipc	ra,0xffffd
    80002e2e:	764080e7          	jalr	1892(ra) # 8000058e <printf>
    setkilled(p);
    80002e32:	8526                	mv	a0,s1
    80002e34:	00000097          	auipc	ra,0x0
    80002e38:	990080e7          	jalr	-1648(ra) # 800027c4 <setkilled>
    80002e3c:	bddd                	j	80002d32 <usertrap+0x52>
    exit(-1);
    80002e3e:	557d                	li	a0,-1
    80002e40:	00000097          	auipc	ra,0x0
    80002e44:	830080e7          	jalr	-2000(ra) # 80002670 <exit>
    if(which_dev == 2 && myproc()->state == RUNNING && myproc() != 0) {
    80002e48:	4789                	li	a5,2
    80002e4a:	eef91be3          	bne	s2,a5,80002d40 <usertrap+0x60>
    80002e4e:	fffff097          	auipc	ra,0xfffff
    80002e52:	d66080e7          	jalr	-666(ra) # 80001bb4 <myproc>
    80002e56:	4d18                	lw	a4,24(a0)
    80002e58:	4791                	li	a5,4
    80002e5a:	eef713e3          	bne	a4,a5,80002d40 <usertrap+0x60>
    80002e5e:	fffff097          	auipc	ra,0xfffff
    80002e62:	d56080e7          	jalr	-682(ra) # 80001bb4 <myproc>
    80002e66:	ec050de3          	beqz	a0,80002d40 <usertrap+0x60>
      if(p->curr_rtime >= priority_levels[p->priority]) {
    80002e6a:	1984a703          	lw	a4,408(s1)
    80002e6e:	00271693          	slli	a3,a4,0x2
    80002e72:	00006797          	auipc	a5,0x6
    80002e76:	b5678793          	addi	a5,a5,-1194 # 800089c8 <priority_levels>
    80002e7a:	97b6                	add	a5,a5,a3
    80002e7c:	1a04a683          	lw	a3,416(s1)
    80002e80:	439c                	lw	a5,0(a5)
    80002e82:	00f6da63          	bge	a3,a5,80002e96 <usertrap+0x1b6>
        for(int i = 0; i < p->priority; i++) {
    80002e86:	0000e997          	auipc	s3,0xe
    80002e8a:	32298993          	addi	s3,s3,802 # 800111a8 <queues+0x8>
    80002e8e:	4901                	li	s2,0
    80002e90:	02e04963          	bgtz	a4,80002ec2 <usertrap+0x1e2>
    80002e94:	b575                	j	80002d40 <usertrap+0x60>
        if(p->priority != 4) {
    80002e96:	4791                	li	a5,4
    80002e98:	00f70563          	beq	a4,a5,80002ea2 <usertrap+0x1c2>
          p->priority++;
    80002e9c:	2705                	addiw	a4,a4,1
    80002e9e:	18e4ac23          	sw	a4,408(s1)
        p->curr_rtime = 0;
    80002ea2:	1a04a023          	sw	zero,416(s1)
        p->curr_wtime = 0;
    80002ea6:	1a04a223          	sw	zero,420(s1)
        yield();
    80002eaa:	fffff097          	auipc	ra,0xfffff
    80002eae:	470080e7          	jalr	1136(ra) # 8000231a <yield>
    80002eb2:	b579                	j	80002d40 <usertrap+0x60>
        for(int i = 0; i < p->priority; i++) {
    80002eb4:	2905                	addiw	s2,s2,1
    80002eb6:	21898993          	addi	s3,s3,536
    80002eba:	1984a783          	lw	a5,408(s1)
    80002ebe:	e8f951e3          	bge	s2,a5,80002d40 <usertrap+0x60>
          if(queues[i].length > 0) {
    80002ec2:	0009a783          	lw	a5,0(s3)
    80002ec6:	fef057e3          	blez	a5,80002eb4 <usertrap+0x1d4>
            yield();
    80002eca:	fffff097          	auipc	ra,0xfffff
    80002ece:	450080e7          	jalr	1104(ra) # 8000231a <yield>
    80002ed2:	b7cd                	j	80002eb4 <usertrap+0x1d4>

0000000080002ed4 <kerneltrap>:
{
    80002ed4:	7139                	addi	sp,sp,-64
    80002ed6:	fc06                	sd	ra,56(sp)
    80002ed8:	f822                	sd	s0,48(sp)
    80002eda:	f426                	sd	s1,40(sp)
    80002edc:	f04a                	sd	s2,32(sp)
    80002ede:	ec4e                	sd	s3,24(sp)
    80002ee0:	e852                	sd	s4,16(sp)
    80002ee2:	e456                	sd	s5,8(sp)
    80002ee4:	0080                	addi	s0,sp,64
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ee6:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002eea:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002eee:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002ef2:	1004f793          	andi	a5,s1,256
    80002ef6:	cb95                	beqz	a5,80002f2a <kerneltrap+0x56>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ef8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002efc:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002efe:	ef95                	bnez	a5,80002f3a <kerneltrap+0x66>
  if((which_dev = devintr()) == 0){
    80002f00:	00000097          	auipc	ra,0x0
    80002f04:	d3e080e7          	jalr	-706(ra) # 80002c3e <devintr>
    80002f08:	c129                	beqz	a0,80002f4a <kerneltrap+0x76>
    if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING) {
    80002f0a:	4789                	li	a5,2
    80002f0c:	06f50c63          	beq	a0,a5,80002f84 <kerneltrap+0xb0>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f10:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f14:	10049073          	csrw	sstatus,s1
}
    80002f18:	70e2                	ld	ra,56(sp)
    80002f1a:	7442                	ld	s0,48(sp)
    80002f1c:	74a2                	ld	s1,40(sp)
    80002f1e:	7902                	ld	s2,32(sp)
    80002f20:	69e2                	ld	s3,24(sp)
    80002f22:	6a42                	ld	s4,16(sp)
    80002f24:	6aa2                	ld	s5,8(sp)
    80002f26:	6121                	addi	sp,sp,64
    80002f28:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002f2a:	00005517          	auipc	a0,0x5
    80002f2e:	48650513          	addi	a0,a0,1158 # 800083b0 <states.1800+0xc8>
    80002f32:	ffffd097          	auipc	ra,0xffffd
    80002f36:	612080e7          	jalr	1554(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    80002f3a:	00005517          	auipc	a0,0x5
    80002f3e:	49e50513          	addi	a0,a0,1182 # 800083d8 <states.1800+0xf0>
    80002f42:	ffffd097          	auipc	ra,0xffffd
    80002f46:	602080e7          	jalr	1538(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    80002f4a:	85ce                	mv	a1,s3
    80002f4c:	00005517          	auipc	a0,0x5
    80002f50:	4ac50513          	addi	a0,a0,1196 # 800083f8 <states.1800+0x110>
    80002f54:	ffffd097          	auipc	ra,0xffffd
    80002f58:	63a080e7          	jalr	1594(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f5c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f60:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f64:	00005517          	auipc	a0,0x5
    80002f68:	4a450513          	addi	a0,a0,1188 # 80008408 <states.1800+0x120>
    80002f6c:	ffffd097          	auipc	ra,0xffffd
    80002f70:	622080e7          	jalr	1570(ra) # 8000058e <printf>
    panic("kerneltrap");
    80002f74:	00005517          	auipc	a0,0x5
    80002f78:	4ac50513          	addi	a0,a0,1196 # 80008420 <states.1800+0x138>
    80002f7c:	ffffd097          	auipc	ra,0xffffd
    80002f80:	5c8080e7          	jalr	1480(ra) # 80000544 <panic>
    if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING) {
    80002f84:	fffff097          	auipc	ra,0xfffff
    80002f88:	c30080e7          	jalr	-976(ra) # 80001bb4 <myproc>
    80002f8c:	d151                	beqz	a0,80002f10 <kerneltrap+0x3c>
    80002f8e:	fffff097          	auipc	ra,0xfffff
    80002f92:	c26080e7          	jalr	-986(ra) # 80001bb4 <myproc>
    80002f96:	4d18                	lw	a4,24(a0)
    80002f98:	4791                	li	a5,4
    80002f9a:	f6f71be3          	bne	a4,a5,80002f10 <kerneltrap+0x3c>
      struct proc* p = myproc();
    80002f9e:	fffff097          	auipc	ra,0xfffff
    80002fa2:	c16080e7          	jalr	-1002(ra) # 80001bb4 <myproc>
    80002fa6:	8aaa                	mv	s5,a0
      if(p->curr_rtime >= priority_levels[p->priority]) {
    80002fa8:	19852703          	lw	a4,408(a0)
    80002fac:	00271693          	slli	a3,a4,0x2
    80002fb0:	00006797          	auipc	a5,0x6
    80002fb4:	a1878793          	addi	a5,a5,-1512 # 800089c8 <priority_levels>
    80002fb8:	97b6                	add	a5,a5,a3
    80002fba:	1a052683          	lw	a3,416(a0)
    80002fbe:	439c                	lw	a5,0(a5)
    80002fc0:	00f6da63          	bge	a3,a5,80002fd4 <kerneltrap+0x100>
        for(int i = 0; i < p->priority; i++) {
    80002fc4:	0000ea17          	auipc	s4,0xe
    80002fc8:	1e4a0a13          	addi	s4,s4,484 # 800111a8 <queues+0x8>
    80002fcc:	4981                	li	s3,0
    80002fce:	02e04563          	bgtz	a4,80002ff8 <kerneltrap+0x124>
    80002fd2:	bf3d                	j	80002f10 <kerneltrap+0x3c>
        if(p->priority != 4) {
    80002fd4:	4791                	li	a5,4
    80002fd6:	00f70563          	beq	a4,a5,80002fe0 <kerneltrap+0x10c>
          p->priority++;
    80002fda:	2705                	addiw	a4,a4,1
    80002fdc:	18e52c23          	sw	a4,408(a0)
        yield();
    80002fe0:	fffff097          	auipc	ra,0xfffff
    80002fe4:	33a080e7          	jalr	826(ra) # 8000231a <yield>
    80002fe8:	b725                	j	80002f10 <kerneltrap+0x3c>
        for(int i = 0; i < p->priority; i++) {
    80002fea:	2985                	addiw	s3,s3,1
    80002fec:	218a0a13          	addi	s4,s4,536
    80002ff0:	198aa783          	lw	a5,408(s5)
    80002ff4:	f0f9dee3          	bge	s3,a5,80002f10 <kerneltrap+0x3c>
          if(queues[i].length > 0) {
    80002ff8:	000a2783          	lw	a5,0(s4)
    80002ffc:	fef057e3          	blez	a5,80002fea <kerneltrap+0x116>
            yield();
    80003000:	fffff097          	auipc	ra,0xfffff
    80003004:	31a080e7          	jalr	794(ra) # 8000231a <yield>
    80003008:	b7cd                	j	80002fea <kerneltrap+0x116>

000000008000300a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000300a:	1101                	addi	sp,sp,-32
    8000300c:	ec06                	sd	ra,24(sp)
    8000300e:	e822                	sd	s0,16(sp)
    80003010:	e426                	sd	s1,8(sp)
    80003012:	1000                	addi	s0,sp,32
    80003014:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003016:	fffff097          	auipc	ra,0xfffff
    8000301a:	b9e080e7          	jalr	-1122(ra) # 80001bb4 <myproc>
  switch (n) {
    8000301e:	4795                	li	a5,5
    80003020:	0497e163          	bltu	a5,s1,80003062 <argraw+0x58>
    80003024:	048a                	slli	s1,s1,0x2
    80003026:	00005717          	auipc	a4,0x5
    8000302a:	51270713          	addi	a4,a4,1298 # 80008538 <states.1800+0x250>
    8000302e:	94ba                	add	s1,s1,a4
    80003030:	409c                	lw	a5,0(s1)
    80003032:	97ba                	add	a5,a5,a4
    80003034:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003036:	6d3c                	ld	a5,88(a0)
    80003038:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000303a:	60e2                	ld	ra,24(sp)
    8000303c:	6442                	ld	s0,16(sp)
    8000303e:	64a2                	ld	s1,8(sp)
    80003040:	6105                	addi	sp,sp,32
    80003042:	8082                	ret
    return p->trapframe->a1;
    80003044:	6d3c                	ld	a5,88(a0)
    80003046:	7fa8                	ld	a0,120(a5)
    80003048:	bfcd                	j	8000303a <argraw+0x30>
    return p->trapframe->a2;
    8000304a:	6d3c                	ld	a5,88(a0)
    8000304c:	63c8                	ld	a0,128(a5)
    8000304e:	b7f5                	j	8000303a <argraw+0x30>
    return p->trapframe->a3;
    80003050:	6d3c                	ld	a5,88(a0)
    80003052:	67c8                	ld	a0,136(a5)
    80003054:	b7dd                	j	8000303a <argraw+0x30>
    return p->trapframe->a4;
    80003056:	6d3c                	ld	a5,88(a0)
    80003058:	6bc8                	ld	a0,144(a5)
    8000305a:	b7c5                	j	8000303a <argraw+0x30>
    return p->trapframe->a5;
    8000305c:	6d3c                	ld	a5,88(a0)
    8000305e:	6fc8                	ld	a0,152(a5)
    80003060:	bfe9                	j	8000303a <argraw+0x30>
  panic("argraw");
    80003062:	00005517          	auipc	a0,0x5
    80003066:	3ce50513          	addi	a0,a0,974 # 80008430 <states.1800+0x148>
    8000306a:	ffffd097          	auipc	ra,0xffffd
    8000306e:	4da080e7          	jalr	1242(ra) # 80000544 <panic>

0000000080003072 <fetchaddr>:
{
    80003072:	1101                	addi	sp,sp,-32
    80003074:	ec06                	sd	ra,24(sp)
    80003076:	e822                	sd	s0,16(sp)
    80003078:	e426                	sd	s1,8(sp)
    8000307a:	e04a                	sd	s2,0(sp)
    8000307c:	1000                	addi	s0,sp,32
    8000307e:	84aa                	mv	s1,a0
    80003080:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003082:	fffff097          	auipc	ra,0xfffff
    80003086:	b32080e7          	jalr	-1230(ra) # 80001bb4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    8000308a:	653c                	ld	a5,72(a0)
    8000308c:	02f4f863          	bgeu	s1,a5,800030bc <fetchaddr+0x4a>
    80003090:	00848713          	addi	a4,s1,8
    80003094:	02e7e663          	bltu	a5,a4,800030c0 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003098:	46a1                	li	a3,8
    8000309a:	8626                	mv	a2,s1
    8000309c:	85ca                	mv	a1,s2
    8000309e:	6928                	ld	a0,80(a0)
    800030a0:	ffffe097          	auipc	ra,0xffffe
    800030a4:	670080e7          	jalr	1648(ra) # 80001710 <copyin>
    800030a8:	00a03533          	snez	a0,a0
    800030ac:	40a00533          	neg	a0,a0
}
    800030b0:	60e2                	ld	ra,24(sp)
    800030b2:	6442                	ld	s0,16(sp)
    800030b4:	64a2                	ld	s1,8(sp)
    800030b6:	6902                	ld	s2,0(sp)
    800030b8:	6105                	addi	sp,sp,32
    800030ba:	8082                	ret
    return -1;
    800030bc:	557d                	li	a0,-1
    800030be:	bfcd                	j	800030b0 <fetchaddr+0x3e>
    800030c0:	557d                	li	a0,-1
    800030c2:	b7fd                	j	800030b0 <fetchaddr+0x3e>

00000000800030c4 <fetchstr>:
{
    800030c4:	7179                	addi	sp,sp,-48
    800030c6:	f406                	sd	ra,40(sp)
    800030c8:	f022                	sd	s0,32(sp)
    800030ca:	ec26                	sd	s1,24(sp)
    800030cc:	e84a                	sd	s2,16(sp)
    800030ce:	e44e                	sd	s3,8(sp)
    800030d0:	1800                	addi	s0,sp,48
    800030d2:	892a                	mv	s2,a0
    800030d4:	84ae                	mv	s1,a1
    800030d6:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800030d8:	fffff097          	auipc	ra,0xfffff
    800030dc:	adc080e7          	jalr	-1316(ra) # 80001bb4 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    800030e0:	86ce                	mv	a3,s3
    800030e2:	864a                	mv	a2,s2
    800030e4:	85a6                	mv	a1,s1
    800030e6:	6928                	ld	a0,80(a0)
    800030e8:	ffffe097          	auipc	ra,0xffffe
    800030ec:	6b4080e7          	jalr	1716(ra) # 8000179c <copyinstr>
    800030f0:	00054e63          	bltz	a0,8000310c <fetchstr+0x48>
  return strlen(buf);
    800030f4:	8526                	mv	a0,s1
    800030f6:	ffffe097          	auipc	ra,0xffffe
    800030fa:	d74080e7          	jalr	-652(ra) # 80000e6a <strlen>
}
    800030fe:	70a2                	ld	ra,40(sp)
    80003100:	7402                	ld	s0,32(sp)
    80003102:	64e2                	ld	s1,24(sp)
    80003104:	6942                	ld	s2,16(sp)
    80003106:	69a2                	ld	s3,8(sp)
    80003108:	6145                	addi	sp,sp,48
    8000310a:	8082                	ret
    return -1;
    8000310c:	557d                	li	a0,-1
    8000310e:	bfc5                	j	800030fe <fetchstr+0x3a>

0000000080003110 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80003110:	1101                	addi	sp,sp,-32
    80003112:	ec06                	sd	ra,24(sp)
    80003114:	e822                	sd	s0,16(sp)
    80003116:	e426                	sd	s1,8(sp)
    80003118:	1000                	addi	s0,sp,32
    8000311a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000311c:	00000097          	auipc	ra,0x0
    80003120:	eee080e7          	jalr	-274(ra) # 8000300a <argraw>
    80003124:	c088                	sw	a0,0(s1)
}
    80003126:	60e2                	ld	ra,24(sp)
    80003128:	6442                	ld	s0,16(sp)
    8000312a:	64a2                	ld	s1,8(sp)
    8000312c:	6105                	addi	sp,sp,32
    8000312e:	8082                	ret

0000000080003130 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80003130:	1101                	addi	sp,sp,-32
    80003132:	ec06                	sd	ra,24(sp)
    80003134:	e822                	sd	s0,16(sp)
    80003136:	e426                	sd	s1,8(sp)
    80003138:	1000                	addi	s0,sp,32
    8000313a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000313c:	00000097          	auipc	ra,0x0
    80003140:	ece080e7          	jalr	-306(ra) # 8000300a <argraw>
    80003144:	e088                	sd	a0,0(s1)
}
    80003146:	60e2                	ld	ra,24(sp)
    80003148:	6442                	ld	s0,16(sp)
    8000314a:	64a2                	ld	s1,8(sp)
    8000314c:	6105                	addi	sp,sp,32
    8000314e:	8082                	ret

0000000080003150 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003150:	7179                	addi	sp,sp,-48
    80003152:	f406                	sd	ra,40(sp)
    80003154:	f022                	sd	s0,32(sp)
    80003156:	ec26                	sd	s1,24(sp)
    80003158:	e84a                	sd	s2,16(sp)
    8000315a:	1800                	addi	s0,sp,48
    8000315c:	84ae                	mv	s1,a1
    8000315e:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80003160:	fd840593          	addi	a1,s0,-40
    80003164:	00000097          	auipc	ra,0x0
    80003168:	fcc080e7          	jalr	-52(ra) # 80003130 <argaddr>
  return fetchstr(addr, buf, max);
    8000316c:	864a                	mv	a2,s2
    8000316e:	85a6                	mv	a1,s1
    80003170:	fd843503          	ld	a0,-40(s0)
    80003174:	00000097          	auipc	ra,0x0
    80003178:	f50080e7          	jalr	-176(ra) # 800030c4 <fetchstr>
}
    8000317c:	70a2                	ld	ra,40(sp)
    8000317e:	7402                	ld	s0,32(sp)
    80003180:	64e2                	ld	s1,24(sp)
    80003182:	6942                	ld	s2,16(sp)
    80003184:	6145                	addi	sp,sp,48
    80003186:	8082                	ret

0000000080003188 <syscall>:
[SYS_sigreturn] "sigreturn ",
};

void
syscall(void)
{
    80003188:	7179                	addi	sp,sp,-48
    8000318a:	f406                	sd	ra,40(sp)
    8000318c:	f022                	sd	s0,32(sp)
    8000318e:	ec26                	sd	s1,24(sp)
    80003190:	e84a                	sd	s2,16(sp)
    80003192:	e44e                	sd	s3,8(sp)
    80003194:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80003196:	fffff097          	auipc	ra,0xfffff
    8000319a:	a1e080e7          	jalr	-1506(ra) # 80001bb4 <myproc>
    8000319e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800031a0:	05853903          	ld	s2,88(a0)
    800031a4:	0a893783          	ld	a5,168(s2)
    800031a8:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800031ac:	37fd                	addiw	a5,a5,-1
    800031ae:	4769                	li	a4,26
    800031b0:	04f76763          	bltu	a4,a5,800031fe <syscall+0x76>
    800031b4:	00399713          	slli	a4,s3,0x3
    800031b8:	00005797          	auipc	a5,0x5
    800031bc:	39878793          	addi	a5,a5,920 # 80008550 <syscalls>
    800031c0:	97ba                	add	a5,a5,a4
    800031c2:	639c                	ld	a5,0(a5)
    800031c4:	cf8d                	beqz	a5,800031fe <syscall+0x76>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    800031c6:	9782                	jalr	a5
    800031c8:	06a93823          	sd	a0,112(s2)

    // Check for trace_flag to be on
    if(p->trace_flag >> num) {  // check for '=='
    800031cc:	1744a783          	lw	a5,372(s1)
    800031d0:	4137d7bb          	sraw	a5,a5,s3
    800031d4:	c7a1                	beqz	a5,8000321c <syscall+0x94>
      printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0);
    800031d6:	6cb8                	ld	a4,88(s1)
    800031d8:	098e                	slli	s3,s3,0x3
    800031da:	00006797          	auipc	a5,0x6
    800031de:	80678793          	addi	a5,a5,-2042 # 800089e0 <syscall_names>
    800031e2:	99be                	add	s3,s3,a5
    800031e4:	7b34                	ld	a3,112(a4)
    800031e6:	0009b603          	ld	a2,0(s3)
    800031ea:	588c                	lw	a1,48(s1)
    800031ec:	00005517          	auipc	a0,0x5
    800031f0:	24c50513          	addi	a0,a0,588 # 80008438 <states.1800+0x150>
    800031f4:	ffffd097          	auipc	ra,0xffffd
    800031f8:	39a080e7          	jalr	922(ra) # 8000058e <printf>
    800031fc:	a005                	j	8000321c <syscall+0x94>
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    800031fe:	86ce                	mv	a3,s3
    80003200:	15848613          	addi	a2,s1,344
    80003204:	588c                	lw	a1,48(s1)
    80003206:	00005517          	auipc	a0,0x5
    8000320a:	24a50513          	addi	a0,a0,586 # 80008450 <states.1800+0x168>
    8000320e:	ffffd097          	auipc	ra,0xffffd
    80003212:	380080e7          	jalr	896(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003216:	6cbc                	ld	a5,88(s1)
    80003218:	577d                	li	a4,-1
    8000321a:	fbb8                	sd	a4,112(a5)
  }
}
    8000321c:	70a2                	ld	ra,40(sp)
    8000321e:	7402                	ld	s0,32(sp)
    80003220:	64e2                	ld	s1,24(sp)
    80003222:	6942                	ld	s2,16(sp)
    80003224:	69a2                	ld	s3,8(sp)
    80003226:	6145                	addi	sp,sp,48
    80003228:	8082                	ret

000000008000322a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000322a:	1101                	addi	sp,sp,-32
    8000322c:	ec06                	sd	ra,24(sp)
    8000322e:	e822                	sd	s0,16(sp)
    80003230:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80003232:	fec40593          	addi	a1,s0,-20
    80003236:	4501                	li	a0,0
    80003238:	00000097          	auipc	ra,0x0
    8000323c:	ed8080e7          	jalr	-296(ra) # 80003110 <argint>
  exit(n);
    80003240:	fec42503          	lw	a0,-20(s0)
    80003244:	fffff097          	auipc	ra,0xfffff
    80003248:	42c080e7          	jalr	1068(ra) # 80002670 <exit>
  return 0;  // not reached
}
    8000324c:	4501                	li	a0,0
    8000324e:	60e2                	ld	ra,24(sp)
    80003250:	6442                	ld	s0,16(sp)
    80003252:	6105                	addi	sp,sp,32
    80003254:	8082                	ret

0000000080003256 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003256:	1141                	addi	sp,sp,-16
    80003258:	e406                	sd	ra,8(sp)
    8000325a:	e022                	sd	s0,0(sp)
    8000325c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000325e:	fffff097          	auipc	ra,0xfffff
    80003262:	956080e7          	jalr	-1706(ra) # 80001bb4 <myproc>
}
    80003266:	5908                	lw	a0,48(a0)
    80003268:	60a2                	ld	ra,8(sp)
    8000326a:	6402                	ld	s0,0(sp)
    8000326c:	0141                	addi	sp,sp,16
    8000326e:	8082                	ret

0000000080003270 <sys_fork>:

uint64
sys_fork(void)
{
    80003270:	1141                	addi	sp,sp,-16
    80003272:	e406                	sd	ra,8(sp)
    80003274:	e022                	sd	s0,0(sp)
    80003276:	0800                	addi	s0,sp,16
  return fork();
    80003278:	fffff097          	auipc	ra,0xfffff
    8000327c:	d28080e7          	jalr	-728(ra) # 80001fa0 <fork>
}
    80003280:	60a2                	ld	ra,8(sp)
    80003282:	6402                	ld	s0,0(sp)
    80003284:	0141                	addi	sp,sp,16
    80003286:	8082                	ret

0000000080003288 <sys_wait>:

uint64
sys_wait(void)
{
    80003288:	1101                	addi	sp,sp,-32
    8000328a:	ec06                	sd	ra,24(sp)
    8000328c:	e822                	sd	s0,16(sp)
    8000328e:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003290:	fe840593          	addi	a1,s0,-24
    80003294:	4501                	li	a0,0
    80003296:	00000097          	auipc	ra,0x0
    8000329a:	e9a080e7          	jalr	-358(ra) # 80003130 <argaddr>
  return wait(p);
    8000329e:	fe843503          	ld	a0,-24(s0)
    800032a2:	fffff097          	auipc	ra,0xfffff
    800032a6:	580080e7          	jalr	1408(ra) # 80002822 <wait>
}
    800032aa:	60e2                	ld	ra,24(sp)
    800032ac:	6442                	ld	s0,16(sp)
    800032ae:	6105                	addi	sp,sp,32
    800032b0:	8082                	ret

00000000800032b2 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800032b2:	7179                	addi	sp,sp,-48
    800032b4:	f406                	sd	ra,40(sp)
    800032b6:	f022                	sd	s0,32(sp)
    800032b8:	ec26                	sd	s1,24(sp)
    800032ba:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    800032bc:	fdc40593          	addi	a1,s0,-36
    800032c0:	4501                	li	a0,0
    800032c2:	00000097          	auipc	ra,0x0
    800032c6:	e4e080e7          	jalr	-434(ra) # 80003110 <argint>
  addr = myproc()->sz;
    800032ca:	fffff097          	auipc	ra,0xfffff
    800032ce:	8ea080e7          	jalr	-1814(ra) # 80001bb4 <myproc>
    800032d2:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    800032d4:	fdc42503          	lw	a0,-36(s0)
    800032d8:	fffff097          	auipc	ra,0xfffff
    800032dc:	c6c080e7          	jalr	-916(ra) # 80001f44 <growproc>
    800032e0:	00054863          	bltz	a0,800032f0 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    800032e4:	8526                	mv	a0,s1
    800032e6:	70a2                	ld	ra,40(sp)
    800032e8:	7402                	ld	s0,32(sp)
    800032ea:	64e2                	ld	s1,24(sp)
    800032ec:	6145                	addi	sp,sp,48
    800032ee:	8082                	ret
    return -1;
    800032f0:	54fd                	li	s1,-1
    800032f2:	bfcd                	j	800032e4 <sys_sbrk+0x32>

00000000800032f4 <sys_sleep>:

uint64
sys_sleep(void)
{
    800032f4:	7139                	addi	sp,sp,-64
    800032f6:	fc06                	sd	ra,56(sp)
    800032f8:	f822                	sd	s0,48(sp)
    800032fa:	f426                	sd	s1,40(sp)
    800032fc:	f04a                	sd	s2,32(sp)
    800032fe:	ec4e                	sd	s3,24(sp)
    80003300:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80003302:	fcc40593          	addi	a1,s0,-52
    80003306:	4501                	li	a0,0
    80003308:	00000097          	auipc	ra,0x0
    8000330c:	e08080e7          	jalr	-504(ra) # 80003110 <argint>
  acquire(&tickslock);
    80003310:	00015517          	auipc	a0,0x15
    80003314:	30850513          	addi	a0,a0,776 # 80018618 <tickslock>
    80003318:	ffffe097          	auipc	ra,0xffffe
    8000331c:	8d2080e7          	jalr	-1838(ra) # 80000bea <acquire>
  ticks0 = ticks;
    80003320:	00005917          	auipc	s2,0x5
    80003324:	7e092903          	lw	s2,2016(s2) # 80008b00 <ticks>
  while(ticks - ticks0 < n){
    80003328:	fcc42783          	lw	a5,-52(s0)
    8000332c:	cf9d                	beqz	a5,8000336a <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000332e:	00015997          	auipc	s3,0x15
    80003332:	2ea98993          	addi	s3,s3,746 # 80018618 <tickslock>
    80003336:	00005497          	auipc	s1,0x5
    8000333a:	7ca48493          	addi	s1,s1,1994 # 80008b00 <ticks>
    if(killed(myproc())){
    8000333e:	fffff097          	auipc	ra,0xfffff
    80003342:	876080e7          	jalr	-1930(ra) # 80001bb4 <myproc>
    80003346:	fffff097          	auipc	ra,0xfffff
    8000334a:	4aa080e7          	jalr	1194(ra) # 800027f0 <killed>
    8000334e:	ed15                	bnez	a0,8000338a <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003350:	85ce                	mv	a1,s3
    80003352:	8526                	mv	a0,s1
    80003354:	fffff097          	auipc	ra,0xfffff
    80003358:	0a4080e7          	jalr	164(ra) # 800023f8 <sleep>
  while(ticks - ticks0 < n){
    8000335c:	409c                	lw	a5,0(s1)
    8000335e:	412787bb          	subw	a5,a5,s2
    80003362:	fcc42703          	lw	a4,-52(s0)
    80003366:	fce7ece3          	bltu	a5,a4,8000333e <sys_sleep+0x4a>
  }
  release(&tickslock);
    8000336a:	00015517          	auipc	a0,0x15
    8000336e:	2ae50513          	addi	a0,a0,686 # 80018618 <tickslock>
    80003372:	ffffe097          	auipc	ra,0xffffe
    80003376:	92c080e7          	jalr	-1748(ra) # 80000c9e <release>
  return 0;
    8000337a:	4501                	li	a0,0
}
    8000337c:	70e2                	ld	ra,56(sp)
    8000337e:	7442                	ld	s0,48(sp)
    80003380:	74a2                	ld	s1,40(sp)
    80003382:	7902                	ld	s2,32(sp)
    80003384:	69e2                	ld	s3,24(sp)
    80003386:	6121                	addi	sp,sp,64
    80003388:	8082                	ret
      release(&tickslock);
    8000338a:	00015517          	auipc	a0,0x15
    8000338e:	28e50513          	addi	a0,a0,654 # 80018618 <tickslock>
    80003392:	ffffe097          	auipc	ra,0xffffe
    80003396:	90c080e7          	jalr	-1780(ra) # 80000c9e <release>
      return -1;
    8000339a:	557d                	li	a0,-1
    8000339c:	b7c5                	j	8000337c <sys_sleep+0x88>

000000008000339e <sys_kill>:

uint64
sys_kill(void)
{
    8000339e:	1101                	addi	sp,sp,-32
    800033a0:	ec06                	sd	ra,24(sp)
    800033a2:	e822                	sd	s0,16(sp)
    800033a4:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    800033a6:	fec40593          	addi	a1,s0,-20
    800033aa:	4501                	li	a0,0
    800033ac:	00000097          	auipc	ra,0x0
    800033b0:	d64080e7          	jalr	-668(ra) # 80003110 <argint>
  return kill(pid);
    800033b4:	fec42503          	lw	a0,-20(s0)
    800033b8:	fffff097          	auipc	ra,0xfffff
    800033bc:	39a080e7          	jalr	922(ra) # 80002752 <kill>
}
    800033c0:	60e2                	ld	ra,24(sp)
    800033c2:	6442                	ld	s0,16(sp)
    800033c4:	6105                	addi	sp,sp,32
    800033c6:	8082                	ret

00000000800033c8 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800033c8:	1101                	addi	sp,sp,-32
    800033ca:	ec06                	sd	ra,24(sp)
    800033cc:	e822                	sd	s0,16(sp)
    800033ce:	e426                	sd	s1,8(sp)
    800033d0:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800033d2:	00015517          	auipc	a0,0x15
    800033d6:	24650513          	addi	a0,a0,582 # 80018618 <tickslock>
    800033da:	ffffe097          	auipc	ra,0xffffe
    800033de:	810080e7          	jalr	-2032(ra) # 80000bea <acquire>
  xticks = ticks;
    800033e2:	00005497          	auipc	s1,0x5
    800033e6:	71e4a483          	lw	s1,1822(s1) # 80008b00 <ticks>
  release(&tickslock);
    800033ea:	00015517          	auipc	a0,0x15
    800033ee:	22e50513          	addi	a0,a0,558 # 80018618 <tickslock>
    800033f2:	ffffe097          	auipc	ra,0xffffe
    800033f6:	8ac080e7          	jalr	-1876(ra) # 80000c9e <release>
  return xticks;
}
    800033fa:	02049513          	slli	a0,s1,0x20
    800033fe:	9101                	srli	a0,a0,0x20
    80003400:	60e2                	ld	ra,24(sp)
    80003402:	6442                	ld	s0,16(sp)
    80003404:	64a2                	ld	s1,8(sp)
    80003406:	6105                	addi	sp,sp,32
    80003408:	8082                	ret

000000008000340a <sys_trace>:

// sets the trace_flag to the first argument (a0)
uint64
sys_trace(void)
{
    8000340a:	1141                	addi	sp,sp,-16
    8000340c:	e406                	sd	ra,8(sp)
    8000340e:	e022                	sd	s0,0(sp)
    80003410:	0800                	addi	s0,sp,16
  argint(0, &myproc()->trace_flag); //arg(a0, trace_flag) // returns void
    80003412:	ffffe097          	auipc	ra,0xffffe
    80003416:	7a2080e7          	jalr	1954(ra) # 80001bb4 <myproc>
    8000341a:	17450593          	addi	a1,a0,372
    8000341e:	4501                	li	a0,0
    80003420:	00000097          	auipc	ra,0x0
    80003424:	cf0080e7          	jalr	-784(ra) # 80003110 <argint>
  return 0;
}
    80003428:	4501                	li	a0,0
    8000342a:	60a2                	ld	ra,8(sp)
    8000342c:	6402                	ld	s0,0(sp)
    8000342e:	0141                	addi	sp,sp,16
    80003430:	8082                	ret

0000000080003432 <sys_sigalarm>:

// sets the 
uint64
sys_sigalarm(void)
{
    80003432:	1101                	addi	sp,sp,-32
    80003434:	ec06                	sd	ra,24(sp)
    80003436:	e822                	sd	s0,16(sp)
    80003438:	e426                	sd	s1,8(sp)
    8000343a:	1000                	addi	s0,sp,32
  // sets the interval and handler after every tick
  argint(0, &myproc()->interval);
    8000343c:	ffffe097          	auipc	ra,0xffffe
    80003440:	778080e7          	jalr	1912(ra) # 80001bb4 <myproc>
    80003444:	17850593          	addi	a1,a0,376
    80003448:	4501                	li	a0,0
    8000344a:	00000097          	auipc	ra,0x0
    8000344e:	cc6080e7          	jalr	-826(ra) # 80003110 <argint>
  argaddr(1, &myproc()->sig_handler);
    80003452:	ffffe097          	auipc	ra,0xffffe
    80003456:	762080e7          	jalr	1890(ra) # 80001bb4 <myproc>
    8000345a:	18050593          	addi	a1,a0,384
    8000345e:	4505                	li	a0,1
    80003460:	00000097          	auipc	ra,0x0
    80003464:	cd0080e7          	jalr	-816(ra) # 80003130 <argaddr>
  
  // sets ticks_passed as the interval
  myproc()->ticks_left = myproc()->interval;
    80003468:	ffffe097          	auipc	ra,0xffffe
    8000346c:	74c080e7          	jalr	1868(ra) # 80001bb4 <myproc>
    80003470:	84aa                	mv	s1,a0
    80003472:	ffffe097          	auipc	ra,0xffffe
    80003476:	742080e7          	jalr	1858(ra) # 80001bb4 <myproc>
    8000347a:	1784a783          	lw	a5,376(s1)
    8000347e:	16f52e23          	sw	a5,380(a0)
  return 0;
}
    80003482:	4501                	li	a0,0
    80003484:	60e2                	ld	ra,24(sp)
    80003486:	6442                	ld	s0,16(sp)
    80003488:	64a2                	ld	s1,8(sp)
    8000348a:	6105                	addi	sp,sp,32
    8000348c:	8082                	ret

000000008000348e <sys_sigreturn>:

uint64 
sys_sigreturn(void)
{
    8000348e:	1101                	addi	sp,sp,-32
    80003490:	ec06                	sd	ra,24(sp)
    80003492:	e822                	sd	s0,16(sp)
    80003494:	e426                	sd	s1,8(sp)
    80003496:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80003498:	ffffe097          	auipc	ra,0xffffe
    8000349c:	71c080e7          	jalr	1820(ra) # 80001bb4 <myproc>
    800034a0:	84aa                	mv	s1,a0
  memmove(p->trapframe, p->sigalarm_tf, PGSIZE);
    800034a2:	6605                	lui	a2,0x1
    800034a4:	18853583          	ld	a1,392(a0)
    800034a8:	6d28                	ld	a0,88(a0)
    800034aa:	ffffe097          	auipc	ra,0xffffe
    800034ae:	89c080e7          	jalr	-1892(ra) # 80000d46 <memmove>
  kfree(p->sigalarm_tf);
    800034b2:	1884b503          	ld	a0,392(s1)
    800034b6:	ffffd097          	auipc	ra,0xffffd
    800034ba:	548080e7          	jalr	1352(ra) # 800009fe <kfree>
  p->ticks_left = p->interval;
    800034be:	1784a783          	lw	a5,376(s1)
    800034c2:	16f4ae23          	sw	a5,380(s1)
  return p->trapframe->a0;
    800034c6:	6cbc                	ld	a5,88(s1)
}
    800034c8:	7ba8                	ld	a0,112(a5)
    800034ca:	60e2                	ld	ra,24(sp)
    800034cc:	6442                	ld	s0,16(sp)
    800034ce:	64a2                	ld	s1,8(sp)
    800034d0:	6105                	addi	sp,sp,32
    800034d2:	8082                	ret

00000000800034d4 <sys_settickets>:

uint64 
sys_settickets(void)
{
    800034d4:	1141                	addi	sp,sp,-16
    800034d6:	e406                	sd	ra,8(sp)
    800034d8:	e022                	sd	s0,0(sp)
    800034da:	0800                	addi	s0,sp,16
  argint(0, &myproc()->tickets);
    800034dc:	ffffe097          	auipc	ra,0xffffe
    800034e0:	6d8080e7          	jalr	1752(ra) # 80001bb4 <myproc>
    800034e4:	19450593          	addi	a1,a0,404
    800034e8:	4501                	li	a0,0
    800034ea:	00000097          	auipc	ra,0x0
    800034ee:	c26080e7          	jalr	-986(ra) # 80003110 <argint>
  return myproc()->tickets;
    800034f2:	ffffe097          	auipc	ra,0xffffe
    800034f6:	6c2080e7          	jalr	1730(ra) # 80001bb4 <myproc>
}
    800034fa:	19452503          	lw	a0,404(a0)
    800034fe:	60a2                	ld	ra,8(sp)
    80003500:	6402                	ld	s0,0(sp)
    80003502:	0141                	addi	sp,sp,16
    80003504:	8082                	ret

0000000080003506 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003506:	7139                	addi	sp,sp,-64
    80003508:	fc06                	sd	ra,56(sp)
    8000350a:	f822                	sd	s0,48(sp)
    8000350c:	f426                	sd	s1,40(sp)
    8000350e:	f04a                	sd	s2,32(sp)
    80003510:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80003512:	fd840593          	addi	a1,s0,-40
    80003516:	4501                	li	a0,0
    80003518:	00000097          	auipc	ra,0x0
    8000351c:	c18080e7          	jalr	-1000(ra) # 80003130 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80003520:	fd040593          	addi	a1,s0,-48
    80003524:	4505                	li	a0,1
    80003526:	00000097          	auipc	ra,0x0
    8000352a:	c0a080e7          	jalr	-1014(ra) # 80003130 <argaddr>
  argaddr(2, &addr2);
    8000352e:	fc840593          	addi	a1,s0,-56
    80003532:	4509                	li	a0,2
    80003534:	00000097          	auipc	ra,0x0
    80003538:	bfc080e7          	jalr	-1028(ra) # 80003130 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    8000353c:	fc040613          	addi	a2,s0,-64
    80003540:	fc440593          	addi	a1,s0,-60
    80003544:	fd843503          	ld	a0,-40(s0)
    80003548:	fffff097          	auipc	ra,0xfffff
    8000354c:	f14080e7          	jalr	-236(ra) # 8000245c <waitx>
    80003550:	892a                	mv	s2,a0
  struct proc* p = myproc();
    80003552:	ffffe097          	auipc	ra,0xffffe
    80003556:	662080e7          	jalr	1634(ra) # 80001bb4 <myproc>
    8000355a:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    8000355c:	4691                	li	a3,4
    8000355e:	fc440613          	addi	a2,s0,-60
    80003562:	fd043583          	ld	a1,-48(s0)
    80003566:	6928                	ld	a0,80(a0)
    80003568:	ffffe097          	auipc	ra,0xffffe
    8000356c:	11c080e7          	jalr	284(ra) # 80001684 <copyout>
    return -1;
    80003570:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80003572:	00054f63          	bltz	a0,80003590 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    80003576:	4691                	li	a3,4
    80003578:	fc040613          	addi	a2,s0,-64
    8000357c:	fc843583          	ld	a1,-56(s0)
    80003580:	68a8                	ld	a0,80(s1)
    80003582:	ffffe097          	auipc	ra,0xffffe
    80003586:	102080e7          	jalr	258(ra) # 80001684 <copyout>
    8000358a:	00054a63          	bltz	a0,8000359e <sys_waitx+0x98>
    return -1;
  return ret;
    8000358e:	87ca                	mv	a5,s2
}
    80003590:	853e                	mv	a0,a5
    80003592:	70e2                	ld	ra,56(sp)
    80003594:	7442                	ld	s0,48(sp)
    80003596:	74a2                	ld	s1,40(sp)
    80003598:	7902                	ld	s2,32(sp)
    8000359a:	6121                	addi	sp,sp,64
    8000359c:	8082                	ret
    return -1;
    8000359e:	57fd                	li	a5,-1
    800035a0:	bfc5                	j	80003590 <sys_waitx+0x8a>

00000000800035a2 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800035a2:	7179                	addi	sp,sp,-48
    800035a4:	f406                	sd	ra,40(sp)
    800035a6:	f022                	sd	s0,32(sp)
    800035a8:	ec26                	sd	s1,24(sp)
    800035aa:	e84a                	sd	s2,16(sp)
    800035ac:	e44e                	sd	s3,8(sp)
    800035ae:	e052                	sd	s4,0(sp)
    800035b0:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800035b2:	00005597          	auipc	a1,0x5
    800035b6:	07e58593          	addi	a1,a1,126 # 80008630 <syscalls+0xe0>
    800035ba:	00015517          	auipc	a0,0x15
    800035be:	07650513          	addi	a0,a0,118 # 80018630 <bcache>
    800035c2:	ffffd097          	auipc	ra,0xffffd
    800035c6:	598080e7          	jalr	1432(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800035ca:	0001d797          	auipc	a5,0x1d
    800035ce:	06678793          	addi	a5,a5,102 # 80020630 <bcache+0x8000>
    800035d2:	0001d717          	auipc	a4,0x1d
    800035d6:	2c670713          	addi	a4,a4,710 # 80020898 <bcache+0x8268>
    800035da:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800035de:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800035e2:	00015497          	auipc	s1,0x15
    800035e6:	06648493          	addi	s1,s1,102 # 80018648 <bcache+0x18>
    b->next = bcache.head.next;
    800035ea:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800035ec:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800035ee:	00005a17          	auipc	s4,0x5
    800035f2:	04aa0a13          	addi	s4,s4,74 # 80008638 <syscalls+0xe8>
    b->next = bcache.head.next;
    800035f6:	2b893783          	ld	a5,696(s2)
    800035fa:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800035fc:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003600:	85d2                	mv	a1,s4
    80003602:	01048513          	addi	a0,s1,16
    80003606:	00001097          	auipc	ra,0x1
    8000360a:	4c4080e7          	jalr	1220(ra) # 80004aca <initsleeplock>
    bcache.head.next->prev = b;
    8000360e:	2b893783          	ld	a5,696(s2)
    80003612:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003614:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003618:	45848493          	addi	s1,s1,1112
    8000361c:	fd349de3          	bne	s1,s3,800035f6 <binit+0x54>
  }
}
    80003620:	70a2                	ld	ra,40(sp)
    80003622:	7402                	ld	s0,32(sp)
    80003624:	64e2                	ld	s1,24(sp)
    80003626:	6942                	ld	s2,16(sp)
    80003628:	69a2                	ld	s3,8(sp)
    8000362a:	6a02                	ld	s4,0(sp)
    8000362c:	6145                	addi	sp,sp,48
    8000362e:	8082                	ret

0000000080003630 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003630:	7179                	addi	sp,sp,-48
    80003632:	f406                	sd	ra,40(sp)
    80003634:	f022                	sd	s0,32(sp)
    80003636:	ec26                	sd	s1,24(sp)
    80003638:	e84a                	sd	s2,16(sp)
    8000363a:	e44e                	sd	s3,8(sp)
    8000363c:	1800                	addi	s0,sp,48
    8000363e:	89aa                	mv	s3,a0
    80003640:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003642:	00015517          	auipc	a0,0x15
    80003646:	fee50513          	addi	a0,a0,-18 # 80018630 <bcache>
    8000364a:	ffffd097          	auipc	ra,0xffffd
    8000364e:	5a0080e7          	jalr	1440(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003652:	0001d497          	auipc	s1,0x1d
    80003656:	2964b483          	ld	s1,662(s1) # 800208e8 <bcache+0x82b8>
    8000365a:	0001d797          	auipc	a5,0x1d
    8000365e:	23e78793          	addi	a5,a5,574 # 80020898 <bcache+0x8268>
    80003662:	02f48f63          	beq	s1,a5,800036a0 <bread+0x70>
    80003666:	873e                	mv	a4,a5
    80003668:	a021                	j	80003670 <bread+0x40>
    8000366a:	68a4                	ld	s1,80(s1)
    8000366c:	02e48a63          	beq	s1,a4,800036a0 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003670:	449c                	lw	a5,8(s1)
    80003672:	ff379ce3          	bne	a5,s3,8000366a <bread+0x3a>
    80003676:	44dc                	lw	a5,12(s1)
    80003678:	ff2799e3          	bne	a5,s2,8000366a <bread+0x3a>
      b->refcnt++;
    8000367c:	40bc                	lw	a5,64(s1)
    8000367e:	2785                	addiw	a5,a5,1
    80003680:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003682:	00015517          	auipc	a0,0x15
    80003686:	fae50513          	addi	a0,a0,-82 # 80018630 <bcache>
    8000368a:	ffffd097          	auipc	ra,0xffffd
    8000368e:	614080e7          	jalr	1556(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80003692:	01048513          	addi	a0,s1,16
    80003696:	00001097          	auipc	ra,0x1
    8000369a:	46e080e7          	jalr	1134(ra) # 80004b04 <acquiresleep>
      return b;
    8000369e:	a8b9                	j	800036fc <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800036a0:	0001d497          	auipc	s1,0x1d
    800036a4:	2404b483          	ld	s1,576(s1) # 800208e0 <bcache+0x82b0>
    800036a8:	0001d797          	auipc	a5,0x1d
    800036ac:	1f078793          	addi	a5,a5,496 # 80020898 <bcache+0x8268>
    800036b0:	00f48863          	beq	s1,a5,800036c0 <bread+0x90>
    800036b4:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800036b6:	40bc                	lw	a5,64(s1)
    800036b8:	cf81                	beqz	a5,800036d0 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800036ba:	64a4                	ld	s1,72(s1)
    800036bc:	fee49de3          	bne	s1,a4,800036b6 <bread+0x86>
  panic("bget: no buffers");
    800036c0:	00005517          	auipc	a0,0x5
    800036c4:	f8050513          	addi	a0,a0,-128 # 80008640 <syscalls+0xf0>
    800036c8:	ffffd097          	auipc	ra,0xffffd
    800036cc:	e7c080e7          	jalr	-388(ra) # 80000544 <panic>
      b->dev = dev;
    800036d0:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800036d4:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800036d8:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800036dc:	4785                	li	a5,1
    800036de:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800036e0:	00015517          	auipc	a0,0x15
    800036e4:	f5050513          	addi	a0,a0,-176 # 80018630 <bcache>
    800036e8:	ffffd097          	auipc	ra,0xffffd
    800036ec:	5b6080e7          	jalr	1462(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    800036f0:	01048513          	addi	a0,s1,16
    800036f4:	00001097          	auipc	ra,0x1
    800036f8:	410080e7          	jalr	1040(ra) # 80004b04 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800036fc:	409c                	lw	a5,0(s1)
    800036fe:	cb89                	beqz	a5,80003710 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003700:	8526                	mv	a0,s1
    80003702:	70a2                	ld	ra,40(sp)
    80003704:	7402                	ld	s0,32(sp)
    80003706:	64e2                	ld	s1,24(sp)
    80003708:	6942                	ld	s2,16(sp)
    8000370a:	69a2                	ld	s3,8(sp)
    8000370c:	6145                	addi	sp,sp,48
    8000370e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003710:	4581                	li	a1,0
    80003712:	8526                	mv	a0,s1
    80003714:	00003097          	auipc	ra,0x3
    80003718:	fc4080e7          	jalr	-60(ra) # 800066d8 <virtio_disk_rw>
    b->valid = 1;
    8000371c:	4785                	li	a5,1
    8000371e:	c09c                	sw	a5,0(s1)
  return b;
    80003720:	b7c5                	j	80003700 <bread+0xd0>

0000000080003722 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003722:	1101                	addi	sp,sp,-32
    80003724:	ec06                	sd	ra,24(sp)
    80003726:	e822                	sd	s0,16(sp)
    80003728:	e426                	sd	s1,8(sp)
    8000372a:	1000                	addi	s0,sp,32
    8000372c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000372e:	0541                	addi	a0,a0,16
    80003730:	00001097          	auipc	ra,0x1
    80003734:	46e080e7          	jalr	1134(ra) # 80004b9e <holdingsleep>
    80003738:	cd01                	beqz	a0,80003750 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000373a:	4585                	li	a1,1
    8000373c:	8526                	mv	a0,s1
    8000373e:	00003097          	auipc	ra,0x3
    80003742:	f9a080e7          	jalr	-102(ra) # 800066d8 <virtio_disk_rw>
}
    80003746:	60e2                	ld	ra,24(sp)
    80003748:	6442                	ld	s0,16(sp)
    8000374a:	64a2                	ld	s1,8(sp)
    8000374c:	6105                	addi	sp,sp,32
    8000374e:	8082                	ret
    panic("bwrite");
    80003750:	00005517          	auipc	a0,0x5
    80003754:	f0850513          	addi	a0,a0,-248 # 80008658 <syscalls+0x108>
    80003758:	ffffd097          	auipc	ra,0xffffd
    8000375c:	dec080e7          	jalr	-532(ra) # 80000544 <panic>

0000000080003760 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003760:	1101                	addi	sp,sp,-32
    80003762:	ec06                	sd	ra,24(sp)
    80003764:	e822                	sd	s0,16(sp)
    80003766:	e426                	sd	s1,8(sp)
    80003768:	e04a                	sd	s2,0(sp)
    8000376a:	1000                	addi	s0,sp,32
    8000376c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000376e:	01050913          	addi	s2,a0,16
    80003772:	854a                	mv	a0,s2
    80003774:	00001097          	auipc	ra,0x1
    80003778:	42a080e7          	jalr	1066(ra) # 80004b9e <holdingsleep>
    8000377c:	c92d                	beqz	a0,800037ee <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000377e:	854a                	mv	a0,s2
    80003780:	00001097          	auipc	ra,0x1
    80003784:	3da080e7          	jalr	986(ra) # 80004b5a <releasesleep>

  acquire(&bcache.lock);
    80003788:	00015517          	auipc	a0,0x15
    8000378c:	ea850513          	addi	a0,a0,-344 # 80018630 <bcache>
    80003790:	ffffd097          	auipc	ra,0xffffd
    80003794:	45a080e7          	jalr	1114(ra) # 80000bea <acquire>
  b->refcnt--;
    80003798:	40bc                	lw	a5,64(s1)
    8000379a:	37fd                	addiw	a5,a5,-1
    8000379c:	0007871b          	sext.w	a4,a5
    800037a0:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800037a2:	eb05                	bnez	a4,800037d2 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800037a4:	68bc                	ld	a5,80(s1)
    800037a6:	64b8                	ld	a4,72(s1)
    800037a8:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800037aa:	64bc                	ld	a5,72(s1)
    800037ac:	68b8                	ld	a4,80(s1)
    800037ae:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800037b0:	0001d797          	auipc	a5,0x1d
    800037b4:	e8078793          	addi	a5,a5,-384 # 80020630 <bcache+0x8000>
    800037b8:	2b87b703          	ld	a4,696(a5)
    800037bc:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800037be:	0001d717          	auipc	a4,0x1d
    800037c2:	0da70713          	addi	a4,a4,218 # 80020898 <bcache+0x8268>
    800037c6:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800037c8:	2b87b703          	ld	a4,696(a5)
    800037cc:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800037ce:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800037d2:	00015517          	auipc	a0,0x15
    800037d6:	e5e50513          	addi	a0,a0,-418 # 80018630 <bcache>
    800037da:	ffffd097          	auipc	ra,0xffffd
    800037de:	4c4080e7          	jalr	1220(ra) # 80000c9e <release>
}
    800037e2:	60e2                	ld	ra,24(sp)
    800037e4:	6442                	ld	s0,16(sp)
    800037e6:	64a2                	ld	s1,8(sp)
    800037e8:	6902                	ld	s2,0(sp)
    800037ea:	6105                	addi	sp,sp,32
    800037ec:	8082                	ret
    panic("brelse");
    800037ee:	00005517          	auipc	a0,0x5
    800037f2:	e7250513          	addi	a0,a0,-398 # 80008660 <syscalls+0x110>
    800037f6:	ffffd097          	auipc	ra,0xffffd
    800037fa:	d4e080e7          	jalr	-690(ra) # 80000544 <panic>

00000000800037fe <bpin>:

void
bpin(struct buf *b) {
    800037fe:	1101                	addi	sp,sp,-32
    80003800:	ec06                	sd	ra,24(sp)
    80003802:	e822                	sd	s0,16(sp)
    80003804:	e426                	sd	s1,8(sp)
    80003806:	1000                	addi	s0,sp,32
    80003808:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000380a:	00015517          	auipc	a0,0x15
    8000380e:	e2650513          	addi	a0,a0,-474 # 80018630 <bcache>
    80003812:	ffffd097          	auipc	ra,0xffffd
    80003816:	3d8080e7          	jalr	984(ra) # 80000bea <acquire>
  b->refcnt++;
    8000381a:	40bc                	lw	a5,64(s1)
    8000381c:	2785                	addiw	a5,a5,1
    8000381e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003820:	00015517          	auipc	a0,0x15
    80003824:	e1050513          	addi	a0,a0,-496 # 80018630 <bcache>
    80003828:	ffffd097          	auipc	ra,0xffffd
    8000382c:	476080e7          	jalr	1142(ra) # 80000c9e <release>
}
    80003830:	60e2                	ld	ra,24(sp)
    80003832:	6442                	ld	s0,16(sp)
    80003834:	64a2                	ld	s1,8(sp)
    80003836:	6105                	addi	sp,sp,32
    80003838:	8082                	ret

000000008000383a <bunpin>:

void
bunpin(struct buf *b) {
    8000383a:	1101                	addi	sp,sp,-32
    8000383c:	ec06                	sd	ra,24(sp)
    8000383e:	e822                	sd	s0,16(sp)
    80003840:	e426                	sd	s1,8(sp)
    80003842:	1000                	addi	s0,sp,32
    80003844:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003846:	00015517          	auipc	a0,0x15
    8000384a:	dea50513          	addi	a0,a0,-534 # 80018630 <bcache>
    8000384e:	ffffd097          	auipc	ra,0xffffd
    80003852:	39c080e7          	jalr	924(ra) # 80000bea <acquire>
  b->refcnt--;
    80003856:	40bc                	lw	a5,64(s1)
    80003858:	37fd                	addiw	a5,a5,-1
    8000385a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000385c:	00015517          	auipc	a0,0x15
    80003860:	dd450513          	addi	a0,a0,-556 # 80018630 <bcache>
    80003864:	ffffd097          	auipc	ra,0xffffd
    80003868:	43a080e7          	jalr	1082(ra) # 80000c9e <release>
}
    8000386c:	60e2                	ld	ra,24(sp)
    8000386e:	6442                	ld	s0,16(sp)
    80003870:	64a2                	ld	s1,8(sp)
    80003872:	6105                	addi	sp,sp,32
    80003874:	8082                	ret

0000000080003876 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003876:	1101                	addi	sp,sp,-32
    80003878:	ec06                	sd	ra,24(sp)
    8000387a:	e822                	sd	s0,16(sp)
    8000387c:	e426                	sd	s1,8(sp)
    8000387e:	e04a                	sd	s2,0(sp)
    80003880:	1000                	addi	s0,sp,32
    80003882:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003884:	00d5d59b          	srliw	a1,a1,0xd
    80003888:	0001d797          	auipc	a5,0x1d
    8000388c:	4847a783          	lw	a5,1156(a5) # 80020d0c <sb+0x1c>
    80003890:	9dbd                	addw	a1,a1,a5
    80003892:	00000097          	auipc	ra,0x0
    80003896:	d9e080e7          	jalr	-610(ra) # 80003630 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000389a:	0074f713          	andi	a4,s1,7
    8000389e:	4785                	li	a5,1
    800038a0:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800038a4:	14ce                	slli	s1,s1,0x33
    800038a6:	90d9                	srli	s1,s1,0x36
    800038a8:	00950733          	add	a4,a0,s1
    800038ac:	05874703          	lbu	a4,88(a4)
    800038b0:	00e7f6b3          	and	a3,a5,a4
    800038b4:	c69d                	beqz	a3,800038e2 <bfree+0x6c>
    800038b6:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800038b8:	94aa                	add	s1,s1,a0
    800038ba:	fff7c793          	not	a5,a5
    800038be:	8ff9                	and	a5,a5,a4
    800038c0:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800038c4:	00001097          	auipc	ra,0x1
    800038c8:	120080e7          	jalr	288(ra) # 800049e4 <log_write>
  brelse(bp);
    800038cc:	854a                	mv	a0,s2
    800038ce:	00000097          	auipc	ra,0x0
    800038d2:	e92080e7          	jalr	-366(ra) # 80003760 <brelse>
}
    800038d6:	60e2                	ld	ra,24(sp)
    800038d8:	6442                	ld	s0,16(sp)
    800038da:	64a2                	ld	s1,8(sp)
    800038dc:	6902                	ld	s2,0(sp)
    800038de:	6105                	addi	sp,sp,32
    800038e0:	8082                	ret
    panic("freeing free block");
    800038e2:	00005517          	auipc	a0,0x5
    800038e6:	d8650513          	addi	a0,a0,-634 # 80008668 <syscalls+0x118>
    800038ea:	ffffd097          	auipc	ra,0xffffd
    800038ee:	c5a080e7          	jalr	-934(ra) # 80000544 <panic>

00000000800038f2 <balloc>:
{
    800038f2:	711d                	addi	sp,sp,-96
    800038f4:	ec86                	sd	ra,88(sp)
    800038f6:	e8a2                	sd	s0,80(sp)
    800038f8:	e4a6                	sd	s1,72(sp)
    800038fa:	e0ca                	sd	s2,64(sp)
    800038fc:	fc4e                	sd	s3,56(sp)
    800038fe:	f852                	sd	s4,48(sp)
    80003900:	f456                	sd	s5,40(sp)
    80003902:	f05a                	sd	s6,32(sp)
    80003904:	ec5e                	sd	s7,24(sp)
    80003906:	e862                	sd	s8,16(sp)
    80003908:	e466                	sd	s9,8(sp)
    8000390a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000390c:	0001d797          	auipc	a5,0x1d
    80003910:	3e87a783          	lw	a5,1000(a5) # 80020cf4 <sb+0x4>
    80003914:	10078163          	beqz	a5,80003a16 <balloc+0x124>
    80003918:	8baa                	mv	s7,a0
    8000391a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000391c:	0001db17          	auipc	s6,0x1d
    80003920:	3d4b0b13          	addi	s6,s6,980 # 80020cf0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003924:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003926:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003928:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000392a:	6c89                	lui	s9,0x2
    8000392c:	a061                	j	800039b4 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000392e:	974a                	add	a4,a4,s2
    80003930:	8fd5                	or	a5,a5,a3
    80003932:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003936:	854a                	mv	a0,s2
    80003938:	00001097          	auipc	ra,0x1
    8000393c:	0ac080e7          	jalr	172(ra) # 800049e4 <log_write>
        brelse(bp);
    80003940:	854a                	mv	a0,s2
    80003942:	00000097          	auipc	ra,0x0
    80003946:	e1e080e7          	jalr	-482(ra) # 80003760 <brelse>
  bp = bread(dev, bno);
    8000394a:	85a6                	mv	a1,s1
    8000394c:	855e                	mv	a0,s7
    8000394e:	00000097          	auipc	ra,0x0
    80003952:	ce2080e7          	jalr	-798(ra) # 80003630 <bread>
    80003956:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003958:	40000613          	li	a2,1024
    8000395c:	4581                	li	a1,0
    8000395e:	05850513          	addi	a0,a0,88
    80003962:	ffffd097          	auipc	ra,0xffffd
    80003966:	384080e7          	jalr	900(ra) # 80000ce6 <memset>
  log_write(bp);
    8000396a:	854a                	mv	a0,s2
    8000396c:	00001097          	auipc	ra,0x1
    80003970:	078080e7          	jalr	120(ra) # 800049e4 <log_write>
  brelse(bp);
    80003974:	854a                	mv	a0,s2
    80003976:	00000097          	auipc	ra,0x0
    8000397a:	dea080e7          	jalr	-534(ra) # 80003760 <brelse>
}
    8000397e:	8526                	mv	a0,s1
    80003980:	60e6                	ld	ra,88(sp)
    80003982:	6446                	ld	s0,80(sp)
    80003984:	64a6                	ld	s1,72(sp)
    80003986:	6906                	ld	s2,64(sp)
    80003988:	79e2                	ld	s3,56(sp)
    8000398a:	7a42                	ld	s4,48(sp)
    8000398c:	7aa2                	ld	s5,40(sp)
    8000398e:	7b02                	ld	s6,32(sp)
    80003990:	6be2                	ld	s7,24(sp)
    80003992:	6c42                	ld	s8,16(sp)
    80003994:	6ca2                	ld	s9,8(sp)
    80003996:	6125                	addi	sp,sp,96
    80003998:	8082                	ret
    brelse(bp);
    8000399a:	854a                	mv	a0,s2
    8000399c:	00000097          	auipc	ra,0x0
    800039a0:	dc4080e7          	jalr	-572(ra) # 80003760 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800039a4:	015c87bb          	addw	a5,s9,s5
    800039a8:	00078a9b          	sext.w	s5,a5
    800039ac:	004b2703          	lw	a4,4(s6)
    800039b0:	06eaf363          	bgeu	s5,a4,80003a16 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    800039b4:	41fad79b          	sraiw	a5,s5,0x1f
    800039b8:	0137d79b          	srliw	a5,a5,0x13
    800039bc:	015787bb          	addw	a5,a5,s5
    800039c0:	40d7d79b          	sraiw	a5,a5,0xd
    800039c4:	01cb2583          	lw	a1,28(s6)
    800039c8:	9dbd                	addw	a1,a1,a5
    800039ca:	855e                	mv	a0,s7
    800039cc:	00000097          	auipc	ra,0x0
    800039d0:	c64080e7          	jalr	-924(ra) # 80003630 <bread>
    800039d4:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039d6:	004b2503          	lw	a0,4(s6)
    800039da:	000a849b          	sext.w	s1,s5
    800039de:	8662                	mv	a2,s8
    800039e0:	faa4fde3          	bgeu	s1,a0,8000399a <balloc+0xa8>
      m = 1 << (bi % 8);
    800039e4:	41f6579b          	sraiw	a5,a2,0x1f
    800039e8:	01d7d69b          	srliw	a3,a5,0x1d
    800039ec:	00c6873b          	addw	a4,a3,a2
    800039f0:	00777793          	andi	a5,a4,7
    800039f4:	9f95                	subw	a5,a5,a3
    800039f6:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800039fa:	4037571b          	sraiw	a4,a4,0x3
    800039fe:	00e906b3          	add	a3,s2,a4
    80003a02:	0586c683          	lbu	a3,88(a3)
    80003a06:	00d7f5b3          	and	a1,a5,a3
    80003a0a:	d195                	beqz	a1,8000392e <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a0c:	2605                	addiw	a2,a2,1
    80003a0e:	2485                	addiw	s1,s1,1
    80003a10:	fd4618e3          	bne	a2,s4,800039e0 <balloc+0xee>
    80003a14:	b759                	j	8000399a <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003a16:	00005517          	auipc	a0,0x5
    80003a1a:	c6a50513          	addi	a0,a0,-918 # 80008680 <syscalls+0x130>
    80003a1e:	ffffd097          	auipc	ra,0xffffd
    80003a22:	b70080e7          	jalr	-1168(ra) # 8000058e <printf>
  return 0;
    80003a26:	4481                	li	s1,0
    80003a28:	bf99                	j	8000397e <balloc+0x8c>

0000000080003a2a <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003a2a:	7179                	addi	sp,sp,-48
    80003a2c:	f406                	sd	ra,40(sp)
    80003a2e:	f022                	sd	s0,32(sp)
    80003a30:	ec26                	sd	s1,24(sp)
    80003a32:	e84a                	sd	s2,16(sp)
    80003a34:	e44e                	sd	s3,8(sp)
    80003a36:	e052                	sd	s4,0(sp)
    80003a38:	1800                	addi	s0,sp,48
    80003a3a:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003a3c:	47ad                	li	a5,11
    80003a3e:	02b7e763          	bltu	a5,a1,80003a6c <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003a42:	02059493          	slli	s1,a1,0x20
    80003a46:	9081                	srli	s1,s1,0x20
    80003a48:	048a                	slli	s1,s1,0x2
    80003a4a:	94aa                	add	s1,s1,a0
    80003a4c:	0504a903          	lw	s2,80(s1)
    80003a50:	06091e63          	bnez	s2,80003acc <bmap+0xa2>
      addr = balloc(ip->dev);
    80003a54:	4108                	lw	a0,0(a0)
    80003a56:	00000097          	auipc	ra,0x0
    80003a5a:	e9c080e7          	jalr	-356(ra) # 800038f2 <balloc>
    80003a5e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003a62:	06090563          	beqz	s2,80003acc <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003a66:	0524a823          	sw	s2,80(s1)
    80003a6a:	a08d                	j	80003acc <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003a6c:	ff45849b          	addiw	s1,a1,-12
    80003a70:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003a74:	0ff00793          	li	a5,255
    80003a78:	08e7e563          	bltu	a5,a4,80003b02 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003a7c:	08052903          	lw	s2,128(a0)
    80003a80:	00091d63          	bnez	s2,80003a9a <bmap+0x70>
      addr = balloc(ip->dev);
    80003a84:	4108                	lw	a0,0(a0)
    80003a86:	00000097          	auipc	ra,0x0
    80003a8a:	e6c080e7          	jalr	-404(ra) # 800038f2 <balloc>
    80003a8e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003a92:	02090d63          	beqz	s2,80003acc <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003a96:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003a9a:	85ca                	mv	a1,s2
    80003a9c:	0009a503          	lw	a0,0(s3)
    80003aa0:	00000097          	auipc	ra,0x0
    80003aa4:	b90080e7          	jalr	-1136(ra) # 80003630 <bread>
    80003aa8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003aaa:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003aae:	02049593          	slli	a1,s1,0x20
    80003ab2:	9181                	srli	a1,a1,0x20
    80003ab4:	058a                	slli	a1,a1,0x2
    80003ab6:	00b784b3          	add	s1,a5,a1
    80003aba:	0004a903          	lw	s2,0(s1)
    80003abe:	02090063          	beqz	s2,80003ade <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003ac2:	8552                	mv	a0,s4
    80003ac4:	00000097          	auipc	ra,0x0
    80003ac8:	c9c080e7          	jalr	-868(ra) # 80003760 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003acc:	854a                	mv	a0,s2
    80003ace:	70a2                	ld	ra,40(sp)
    80003ad0:	7402                	ld	s0,32(sp)
    80003ad2:	64e2                	ld	s1,24(sp)
    80003ad4:	6942                	ld	s2,16(sp)
    80003ad6:	69a2                	ld	s3,8(sp)
    80003ad8:	6a02                	ld	s4,0(sp)
    80003ada:	6145                	addi	sp,sp,48
    80003adc:	8082                	ret
      addr = balloc(ip->dev);
    80003ade:	0009a503          	lw	a0,0(s3)
    80003ae2:	00000097          	auipc	ra,0x0
    80003ae6:	e10080e7          	jalr	-496(ra) # 800038f2 <balloc>
    80003aea:	0005091b          	sext.w	s2,a0
      if(addr){
    80003aee:	fc090ae3          	beqz	s2,80003ac2 <bmap+0x98>
        a[bn] = addr;
    80003af2:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003af6:	8552                	mv	a0,s4
    80003af8:	00001097          	auipc	ra,0x1
    80003afc:	eec080e7          	jalr	-276(ra) # 800049e4 <log_write>
    80003b00:	b7c9                	j	80003ac2 <bmap+0x98>
  panic("bmap: out of range");
    80003b02:	00005517          	auipc	a0,0x5
    80003b06:	b9650513          	addi	a0,a0,-1130 # 80008698 <syscalls+0x148>
    80003b0a:	ffffd097          	auipc	ra,0xffffd
    80003b0e:	a3a080e7          	jalr	-1478(ra) # 80000544 <panic>

0000000080003b12 <iget>:
{
    80003b12:	7179                	addi	sp,sp,-48
    80003b14:	f406                	sd	ra,40(sp)
    80003b16:	f022                	sd	s0,32(sp)
    80003b18:	ec26                	sd	s1,24(sp)
    80003b1a:	e84a                	sd	s2,16(sp)
    80003b1c:	e44e                	sd	s3,8(sp)
    80003b1e:	e052                	sd	s4,0(sp)
    80003b20:	1800                	addi	s0,sp,48
    80003b22:	89aa                	mv	s3,a0
    80003b24:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003b26:	0001d517          	auipc	a0,0x1d
    80003b2a:	1ea50513          	addi	a0,a0,490 # 80020d10 <itable>
    80003b2e:	ffffd097          	auipc	ra,0xffffd
    80003b32:	0bc080e7          	jalr	188(ra) # 80000bea <acquire>
  empty = 0;
    80003b36:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003b38:	0001d497          	auipc	s1,0x1d
    80003b3c:	1f048493          	addi	s1,s1,496 # 80020d28 <itable+0x18>
    80003b40:	0001f697          	auipc	a3,0x1f
    80003b44:	c7868693          	addi	a3,a3,-904 # 800227b8 <log>
    80003b48:	a039                	j	80003b56 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b4a:	02090b63          	beqz	s2,80003b80 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003b4e:	08848493          	addi	s1,s1,136
    80003b52:	02d48a63          	beq	s1,a3,80003b86 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003b56:	449c                	lw	a5,8(s1)
    80003b58:	fef059e3          	blez	a5,80003b4a <iget+0x38>
    80003b5c:	4098                	lw	a4,0(s1)
    80003b5e:	ff3716e3          	bne	a4,s3,80003b4a <iget+0x38>
    80003b62:	40d8                	lw	a4,4(s1)
    80003b64:	ff4713e3          	bne	a4,s4,80003b4a <iget+0x38>
      ip->ref++;
    80003b68:	2785                	addiw	a5,a5,1
    80003b6a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003b6c:	0001d517          	auipc	a0,0x1d
    80003b70:	1a450513          	addi	a0,a0,420 # 80020d10 <itable>
    80003b74:	ffffd097          	auipc	ra,0xffffd
    80003b78:	12a080e7          	jalr	298(ra) # 80000c9e <release>
      return ip;
    80003b7c:	8926                	mv	s2,s1
    80003b7e:	a03d                	j	80003bac <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b80:	f7f9                	bnez	a5,80003b4e <iget+0x3c>
    80003b82:	8926                	mv	s2,s1
    80003b84:	b7e9                	j	80003b4e <iget+0x3c>
  if(empty == 0)
    80003b86:	02090c63          	beqz	s2,80003bbe <iget+0xac>
  ip->dev = dev;
    80003b8a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003b8e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003b92:	4785                	li	a5,1
    80003b94:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003b98:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003b9c:	0001d517          	auipc	a0,0x1d
    80003ba0:	17450513          	addi	a0,a0,372 # 80020d10 <itable>
    80003ba4:	ffffd097          	auipc	ra,0xffffd
    80003ba8:	0fa080e7          	jalr	250(ra) # 80000c9e <release>
}
    80003bac:	854a                	mv	a0,s2
    80003bae:	70a2                	ld	ra,40(sp)
    80003bb0:	7402                	ld	s0,32(sp)
    80003bb2:	64e2                	ld	s1,24(sp)
    80003bb4:	6942                	ld	s2,16(sp)
    80003bb6:	69a2                	ld	s3,8(sp)
    80003bb8:	6a02                	ld	s4,0(sp)
    80003bba:	6145                	addi	sp,sp,48
    80003bbc:	8082                	ret
    panic("iget: no inodes");
    80003bbe:	00005517          	auipc	a0,0x5
    80003bc2:	af250513          	addi	a0,a0,-1294 # 800086b0 <syscalls+0x160>
    80003bc6:	ffffd097          	auipc	ra,0xffffd
    80003bca:	97e080e7          	jalr	-1666(ra) # 80000544 <panic>

0000000080003bce <fsinit>:
fsinit(int dev) {
    80003bce:	7179                	addi	sp,sp,-48
    80003bd0:	f406                	sd	ra,40(sp)
    80003bd2:	f022                	sd	s0,32(sp)
    80003bd4:	ec26                	sd	s1,24(sp)
    80003bd6:	e84a                	sd	s2,16(sp)
    80003bd8:	e44e                	sd	s3,8(sp)
    80003bda:	1800                	addi	s0,sp,48
    80003bdc:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003bde:	4585                	li	a1,1
    80003be0:	00000097          	auipc	ra,0x0
    80003be4:	a50080e7          	jalr	-1456(ra) # 80003630 <bread>
    80003be8:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003bea:	0001d997          	auipc	s3,0x1d
    80003bee:	10698993          	addi	s3,s3,262 # 80020cf0 <sb>
    80003bf2:	02000613          	li	a2,32
    80003bf6:	05850593          	addi	a1,a0,88
    80003bfa:	854e                	mv	a0,s3
    80003bfc:	ffffd097          	auipc	ra,0xffffd
    80003c00:	14a080e7          	jalr	330(ra) # 80000d46 <memmove>
  brelse(bp);
    80003c04:	8526                	mv	a0,s1
    80003c06:	00000097          	auipc	ra,0x0
    80003c0a:	b5a080e7          	jalr	-1190(ra) # 80003760 <brelse>
  if(sb.magic != FSMAGIC)
    80003c0e:	0009a703          	lw	a4,0(s3)
    80003c12:	102037b7          	lui	a5,0x10203
    80003c16:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003c1a:	02f71263          	bne	a4,a5,80003c3e <fsinit+0x70>
  initlog(dev, &sb);
    80003c1e:	0001d597          	auipc	a1,0x1d
    80003c22:	0d258593          	addi	a1,a1,210 # 80020cf0 <sb>
    80003c26:	854a                	mv	a0,s2
    80003c28:	00001097          	auipc	ra,0x1
    80003c2c:	b40080e7          	jalr	-1216(ra) # 80004768 <initlog>
}
    80003c30:	70a2                	ld	ra,40(sp)
    80003c32:	7402                	ld	s0,32(sp)
    80003c34:	64e2                	ld	s1,24(sp)
    80003c36:	6942                	ld	s2,16(sp)
    80003c38:	69a2                	ld	s3,8(sp)
    80003c3a:	6145                	addi	sp,sp,48
    80003c3c:	8082                	ret
    panic("invalid file system");
    80003c3e:	00005517          	auipc	a0,0x5
    80003c42:	a8250513          	addi	a0,a0,-1406 # 800086c0 <syscalls+0x170>
    80003c46:	ffffd097          	auipc	ra,0xffffd
    80003c4a:	8fe080e7          	jalr	-1794(ra) # 80000544 <panic>

0000000080003c4e <iinit>:
{
    80003c4e:	7179                	addi	sp,sp,-48
    80003c50:	f406                	sd	ra,40(sp)
    80003c52:	f022                	sd	s0,32(sp)
    80003c54:	ec26                	sd	s1,24(sp)
    80003c56:	e84a                	sd	s2,16(sp)
    80003c58:	e44e                	sd	s3,8(sp)
    80003c5a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003c5c:	00005597          	auipc	a1,0x5
    80003c60:	a7c58593          	addi	a1,a1,-1412 # 800086d8 <syscalls+0x188>
    80003c64:	0001d517          	auipc	a0,0x1d
    80003c68:	0ac50513          	addi	a0,a0,172 # 80020d10 <itable>
    80003c6c:	ffffd097          	auipc	ra,0xffffd
    80003c70:	eee080e7          	jalr	-274(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    80003c74:	0001d497          	auipc	s1,0x1d
    80003c78:	0c448493          	addi	s1,s1,196 # 80020d38 <itable+0x28>
    80003c7c:	0001f997          	auipc	s3,0x1f
    80003c80:	b4c98993          	addi	s3,s3,-1204 # 800227c8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003c84:	00005917          	auipc	s2,0x5
    80003c88:	a5c90913          	addi	s2,s2,-1444 # 800086e0 <syscalls+0x190>
    80003c8c:	85ca                	mv	a1,s2
    80003c8e:	8526                	mv	a0,s1
    80003c90:	00001097          	auipc	ra,0x1
    80003c94:	e3a080e7          	jalr	-454(ra) # 80004aca <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003c98:	08848493          	addi	s1,s1,136
    80003c9c:	ff3498e3          	bne	s1,s3,80003c8c <iinit+0x3e>
}
    80003ca0:	70a2                	ld	ra,40(sp)
    80003ca2:	7402                	ld	s0,32(sp)
    80003ca4:	64e2                	ld	s1,24(sp)
    80003ca6:	6942                	ld	s2,16(sp)
    80003ca8:	69a2                	ld	s3,8(sp)
    80003caa:	6145                	addi	sp,sp,48
    80003cac:	8082                	ret

0000000080003cae <ialloc>:
{
    80003cae:	715d                	addi	sp,sp,-80
    80003cb0:	e486                	sd	ra,72(sp)
    80003cb2:	e0a2                	sd	s0,64(sp)
    80003cb4:	fc26                	sd	s1,56(sp)
    80003cb6:	f84a                	sd	s2,48(sp)
    80003cb8:	f44e                	sd	s3,40(sp)
    80003cba:	f052                	sd	s4,32(sp)
    80003cbc:	ec56                	sd	s5,24(sp)
    80003cbe:	e85a                	sd	s6,16(sp)
    80003cc0:	e45e                	sd	s7,8(sp)
    80003cc2:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003cc4:	0001d717          	auipc	a4,0x1d
    80003cc8:	03872703          	lw	a4,56(a4) # 80020cfc <sb+0xc>
    80003ccc:	4785                	li	a5,1
    80003cce:	04e7fa63          	bgeu	a5,a4,80003d22 <ialloc+0x74>
    80003cd2:	8aaa                	mv	s5,a0
    80003cd4:	8bae                	mv	s7,a1
    80003cd6:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003cd8:	0001da17          	auipc	s4,0x1d
    80003cdc:	018a0a13          	addi	s4,s4,24 # 80020cf0 <sb>
    80003ce0:	00048b1b          	sext.w	s6,s1
    80003ce4:	0044d593          	srli	a1,s1,0x4
    80003ce8:	018a2783          	lw	a5,24(s4)
    80003cec:	9dbd                	addw	a1,a1,a5
    80003cee:	8556                	mv	a0,s5
    80003cf0:	00000097          	auipc	ra,0x0
    80003cf4:	940080e7          	jalr	-1728(ra) # 80003630 <bread>
    80003cf8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003cfa:	05850993          	addi	s3,a0,88
    80003cfe:	00f4f793          	andi	a5,s1,15
    80003d02:	079a                	slli	a5,a5,0x6
    80003d04:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003d06:	00099783          	lh	a5,0(s3)
    80003d0a:	c3a1                	beqz	a5,80003d4a <ialloc+0x9c>
    brelse(bp);
    80003d0c:	00000097          	auipc	ra,0x0
    80003d10:	a54080e7          	jalr	-1452(ra) # 80003760 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d14:	0485                	addi	s1,s1,1
    80003d16:	00ca2703          	lw	a4,12(s4)
    80003d1a:	0004879b          	sext.w	a5,s1
    80003d1e:	fce7e1e3          	bltu	a5,a4,80003ce0 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003d22:	00005517          	auipc	a0,0x5
    80003d26:	9c650513          	addi	a0,a0,-1594 # 800086e8 <syscalls+0x198>
    80003d2a:	ffffd097          	auipc	ra,0xffffd
    80003d2e:	864080e7          	jalr	-1948(ra) # 8000058e <printf>
  return 0;
    80003d32:	4501                	li	a0,0
}
    80003d34:	60a6                	ld	ra,72(sp)
    80003d36:	6406                	ld	s0,64(sp)
    80003d38:	74e2                	ld	s1,56(sp)
    80003d3a:	7942                	ld	s2,48(sp)
    80003d3c:	79a2                	ld	s3,40(sp)
    80003d3e:	7a02                	ld	s4,32(sp)
    80003d40:	6ae2                	ld	s5,24(sp)
    80003d42:	6b42                	ld	s6,16(sp)
    80003d44:	6ba2                	ld	s7,8(sp)
    80003d46:	6161                	addi	sp,sp,80
    80003d48:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003d4a:	04000613          	li	a2,64
    80003d4e:	4581                	li	a1,0
    80003d50:	854e                	mv	a0,s3
    80003d52:	ffffd097          	auipc	ra,0xffffd
    80003d56:	f94080e7          	jalr	-108(ra) # 80000ce6 <memset>
      dip->type = type;
    80003d5a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003d5e:	854a                	mv	a0,s2
    80003d60:	00001097          	auipc	ra,0x1
    80003d64:	c84080e7          	jalr	-892(ra) # 800049e4 <log_write>
      brelse(bp);
    80003d68:	854a                	mv	a0,s2
    80003d6a:	00000097          	auipc	ra,0x0
    80003d6e:	9f6080e7          	jalr	-1546(ra) # 80003760 <brelse>
      return iget(dev, inum);
    80003d72:	85da                	mv	a1,s6
    80003d74:	8556                	mv	a0,s5
    80003d76:	00000097          	auipc	ra,0x0
    80003d7a:	d9c080e7          	jalr	-612(ra) # 80003b12 <iget>
    80003d7e:	bf5d                	j	80003d34 <ialloc+0x86>

0000000080003d80 <iupdate>:
{
    80003d80:	1101                	addi	sp,sp,-32
    80003d82:	ec06                	sd	ra,24(sp)
    80003d84:	e822                	sd	s0,16(sp)
    80003d86:	e426                	sd	s1,8(sp)
    80003d88:	e04a                	sd	s2,0(sp)
    80003d8a:	1000                	addi	s0,sp,32
    80003d8c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d8e:	415c                	lw	a5,4(a0)
    80003d90:	0047d79b          	srliw	a5,a5,0x4
    80003d94:	0001d597          	auipc	a1,0x1d
    80003d98:	f745a583          	lw	a1,-140(a1) # 80020d08 <sb+0x18>
    80003d9c:	9dbd                	addw	a1,a1,a5
    80003d9e:	4108                	lw	a0,0(a0)
    80003da0:	00000097          	auipc	ra,0x0
    80003da4:	890080e7          	jalr	-1904(ra) # 80003630 <bread>
    80003da8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003daa:	05850793          	addi	a5,a0,88
    80003dae:	40c8                	lw	a0,4(s1)
    80003db0:	893d                	andi	a0,a0,15
    80003db2:	051a                	slli	a0,a0,0x6
    80003db4:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003db6:	04449703          	lh	a4,68(s1)
    80003dba:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003dbe:	04649703          	lh	a4,70(s1)
    80003dc2:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003dc6:	04849703          	lh	a4,72(s1)
    80003dca:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003dce:	04a49703          	lh	a4,74(s1)
    80003dd2:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003dd6:	44f8                	lw	a4,76(s1)
    80003dd8:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003dda:	03400613          	li	a2,52
    80003dde:	05048593          	addi	a1,s1,80
    80003de2:	0531                	addi	a0,a0,12
    80003de4:	ffffd097          	auipc	ra,0xffffd
    80003de8:	f62080e7          	jalr	-158(ra) # 80000d46 <memmove>
  log_write(bp);
    80003dec:	854a                	mv	a0,s2
    80003dee:	00001097          	auipc	ra,0x1
    80003df2:	bf6080e7          	jalr	-1034(ra) # 800049e4 <log_write>
  brelse(bp);
    80003df6:	854a                	mv	a0,s2
    80003df8:	00000097          	auipc	ra,0x0
    80003dfc:	968080e7          	jalr	-1688(ra) # 80003760 <brelse>
}
    80003e00:	60e2                	ld	ra,24(sp)
    80003e02:	6442                	ld	s0,16(sp)
    80003e04:	64a2                	ld	s1,8(sp)
    80003e06:	6902                	ld	s2,0(sp)
    80003e08:	6105                	addi	sp,sp,32
    80003e0a:	8082                	ret

0000000080003e0c <idup>:
{
    80003e0c:	1101                	addi	sp,sp,-32
    80003e0e:	ec06                	sd	ra,24(sp)
    80003e10:	e822                	sd	s0,16(sp)
    80003e12:	e426                	sd	s1,8(sp)
    80003e14:	1000                	addi	s0,sp,32
    80003e16:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e18:	0001d517          	auipc	a0,0x1d
    80003e1c:	ef850513          	addi	a0,a0,-264 # 80020d10 <itable>
    80003e20:	ffffd097          	auipc	ra,0xffffd
    80003e24:	dca080e7          	jalr	-566(ra) # 80000bea <acquire>
  ip->ref++;
    80003e28:	449c                	lw	a5,8(s1)
    80003e2a:	2785                	addiw	a5,a5,1
    80003e2c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e2e:	0001d517          	auipc	a0,0x1d
    80003e32:	ee250513          	addi	a0,a0,-286 # 80020d10 <itable>
    80003e36:	ffffd097          	auipc	ra,0xffffd
    80003e3a:	e68080e7          	jalr	-408(ra) # 80000c9e <release>
}
    80003e3e:	8526                	mv	a0,s1
    80003e40:	60e2                	ld	ra,24(sp)
    80003e42:	6442                	ld	s0,16(sp)
    80003e44:	64a2                	ld	s1,8(sp)
    80003e46:	6105                	addi	sp,sp,32
    80003e48:	8082                	ret

0000000080003e4a <ilock>:
{
    80003e4a:	1101                	addi	sp,sp,-32
    80003e4c:	ec06                	sd	ra,24(sp)
    80003e4e:	e822                	sd	s0,16(sp)
    80003e50:	e426                	sd	s1,8(sp)
    80003e52:	e04a                	sd	s2,0(sp)
    80003e54:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003e56:	c115                	beqz	a0,80003e7a <ilock+0x30>
    80003e58:	84aa                	mv	s1,a0
    80003e5a:	451c                	lw	a5,8(a0)
    80003e5c:	00f05f63          	blez	a5,80003e7a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003e60:	0541                	addi	a0,a0,16
    80003e62:	00001097          	auipc	ra,0x1
    80003e66:	ca2080e7          	jalr	-862(ra) # 80004b04 <acquiresleep>
  if(ip->valid == 0){
    80003e6a:	40bc                	lw	a5,64(s1)
    80003e6c:	cf99                	beqz	a5,80003e8a <ilock+0x40>
}
    80003e6e:	60e2                	ld	ra,24(sp)
    80003e70:	6442                	ld	s0,16(sp)
    80003e72:	64a2                	ld	s1,8(sp)
    80003e74:	6902                	ld	s2,0(sp)
    80003e76:	6105                	addi	sp,sp,32
    80003e78:	8082                	ret
    panic("ilock");
    80003e7a:	00005517          	auipc	a0,0x5
    80003e7e:	88650513          	addi	a0,a0,-1914 # 80008700 <syscalls+0x1b0>
    80003e82:	ffffc097          	auipc	ra,0xffffc
    80003e86:	6c2080e7          	jalr	1730(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e8a:	40dc                	lw	a5,4(s1)
    80003e8c:	0047d79b          	srliw	a5,a5,0x4
    80003e90:	0001d597          	auipc	a1,0x1d
    80003e94:	e785a583          	lw	a1,-392(a1) # 80020d08 <sb+0x18>
    80003e98:	9dbd                	addw	a1,a1,a5
    80003e9a:	4088                	lw	a0,0(s1)
    80003e9c:	fffff097          	auipc	ra,0xfffff
    80003ea0:	794080e7          	jalr	1940(ra) # 80003630 <bread>
    80003ea4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003ea6:	05850593          	addi	a1,a0,88
    80003eaa:	40dc                	lw	a5,4(s1)
    80003eac:	8bbd                	andi	a5,a5,15
    80003eae:	079a                	slli	a5,a5,0x6
    80003eb0:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003eb2:	00059783          	lh	a5,0(a1)
    80003eb6:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003eba:	00259783          	lh	a5,2(a1)
    80003ebe:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003ec2:	00459783          	lh	a5,4(a1)
    80003ec6:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003eca:	00659783          	lh	a5,6(a1)
    80003ece:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003ed2:	459c                	lw	a5,8(a1)
    80003ed4:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003ed6:	03400613          	li	a2,52
    80003eda:	05b1                	addi	a1,a1,12
    80003edc:	05048513          	addi	a0,s1,80
    80003ee0:	ffffd097          	auipc	ra,0xffffd
    80003ee4:	e66080e7          	jalr	-410(ra) # 80000d46 <memmove>
    brelse(bp);
    80003ee8:	854a                	mv	a0,s2
    80003eea:	00000097          	auipc	ra,0x0
    80003eee:	876080e7          	jalr	-1930(ra) # 80003760 <brelse>
    ip->valid = 1;
    80003ef2:	4785                	li	a5,1
    80003ef4:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003ef6:	04449783          	lh	a5,68(s1)
    80003efa:	fbb5                	bnez	a5,80003e6e <ilock+0x24>
      panic("ilock: no type");
    80003efc:	00005517          	auipc	a0,0x5
    80003f00:	80c50513          	addi	a0,a0,-2036 # 80008708 <syscalls+0x1b8>
    80003f04:	ffffc097          	auipc	ra,0xffffc
    80003f08:	640080e7          	jalr	1600(ra) # 80000544 <panic>

0000000080003f0c <iunlock>:
{
    80003f0c:	1101                	addi	sp,sp,-32
    80003f0e:	ec06                	sd	ra,24(sp)
    80003f10:	e822                	sd	s0,16(sp)
    80003f12:	e426                	sd	s1,8(sp)
    80003f14:	e04a                	sd	s2,0(sp)
    80003f16:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003f18:	c905                	beqz	a0,80003f48 <iunlock+0x3c>
    80003f1a:	84aa                	mv	s1,a0
    80003f1c:	01050913          	addi	s2,a0,16
    80003f20:	854a                	mv	a0,s2
    80003f22:	00001097          	auipc	ra,0x1
    80003f26:	c7c080e7          	jalr	-900(ra) # 80004b9e <holdingsleep>
    80003f2a:	cd19                	beqz	a0,80003f48 <iunlock+0x3c>
    80003f2c:	449c                	lw	a5,8(s1)
    80003f2e:	00f05d63          	blez	a5,80003f48 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003f32:	854a                	mv	a0,s2
    80003f34:	00001097          	auipc	ra,0x1
    80003f38:	c26080e7          	jalr	-986(ra) # 80004b5a <releasesleep>
}
    80003f3c:	60e2                	ld	ra,24(sp)
    80003f3e:	6442                	ld	s0,16(sp)
    80003f40:	64a2                	ld	s1,8(sp)
    80003f42:	6902                	ld	s2,0(sp)
    80003f44:	6105                	addi	sp,sp,32
    80003f46:	8082                	ret
    panic("iunlock");
    80003f48:	00004517          	auipc	a0,0x4
    80003f4c:	7d050513          	addi	a0,a0,2000 # 80008718 <syscalls+0x1c8>
    80003f50:	ffffc097          	auipc	ra,0xffffc
    80003f54:	5f4080e7          	jalr	1524(ra) # 80000544 <panic>

0000000080003f58 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003f58:	7179                	addi	sp,sp,-48
    80003f5a:	f406                	sd	ra,40(sp)
    80003f5c:	f022                	sd	s0,32(sp)
    80003f5e:	ec26                	sd	s1,24(sp)
    80003f60:	e84a                	sd	s2,16(sp)
    80003f62:	e44e                	sd	s3,8(sp)
    80003f64:	e052                	sd	s4,0(sp)
    80003f66:	1800                	addi	s0,sp,48
    80003f68:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003f6a:	05050493          	addi	s1,a0,80
    80003f6e:	08050913          	addi	s2,a0,128
    80003f72:	a021                	j	80003f7a <itrunc+0x22>
    80003f74:	0491                	addi	s1,s1,4
    80003f76:	01248d63          	beq	s1,s2,80003f90 <itrunc+0x38>
    if(ip->addrs[i]){
    80003f7a:	408c                	lw	a1,0(s1)
    80003f7c:	dde5                	beqz	a1,80003f74 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003f7e:	0009a503          	lw	a0,0(s3)
    80003f82:	00000097          	auipc	ra,0x0
    80003f86:	8f4080e7          	jalr	-1804(ra) # 80003876 <bfree>
      ip->addrs[i] = 0;
    80003f8a:	0004a023          	sw	zero,0(s1)
    80003f8e:	b7dd                	j	80003f74 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003f90:	0809a583          	lw	a1,128(s3)
    80003f94:	e185                	bnez	a1,80003fb4 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003f96:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003f9a:	854e                	mv	a0,s3
    80003f9c:	00000097          	auipc	ra,0x0
    80003fa0:	de4080e7          	jalr	-540(ra) # 80003d80 <iupdate>
}
    80003fa4:	70a2                	ld	ra,40(sp)
    80003fa6:	7402                	ld	s0,32(sp)
    80003fa8:	64e2                	ld	s1,24(sp)
    80003faa:	6942                	ld	s2,16(sp)
    80003fac:	69a2                	ld	s3,8(sp)
    80003fae:	6a02                	ld	s4,0(sp)
    80003fb0:	6145                	addi	sp,sp,48
    80003fb2:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003fb4:	0009a503          	lw	a0,0(s3)
    80003fb8:	fffff097          	auipc	ra,0xfffff
    80003fbc:	678080e7          	jalr	1656(ra) # 80003630 <bread>
    80003fc0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003fc2:	05850493          	addi	s1,a0,88
    80003fc6:	45850913          	addi	s2,a0,1112
    80003fca:	a811                	j	80003fde <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003fcc:	0009a503          	lw	a0,0(s3)
    80003fd0:	00000097          	auipc	ra,0x0
    80003fd4:	8a6080e7          	jalr	-1882(ra) # 80003876 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003fd8:	0491                	addi	s1,s1,4
    80003fda:	01248563          	beq	s1,s2,80003fe4 <itrunc+0x8c>
      if(a[j])
    80003fde:	408c                	lw	a1,0(s1)
    80003fe0:	dde5                	beqz	a1,80003fd8 <itrunc+0x80>
    80003fe2:	b7ed                	j	80003fcc <itrunc+0x74>
    brelse(bp);
    80003fe4:	8552                	mv	a0,s4
    80003fe6:	fffff097          	auipc	ra,0xfffff
    80003fea:	77a080e7          	jalr	1914(ra) # 80003760 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003fee:	0809a583          	lw	a1,128(s3)
    80003ff2:	0009a503          	lw	a0,0(s3)
    80003ff6:	00000097          	auipc	ra,0x0
    80003ffa:	880080e7          	jalr	-1920(ra) # 80003876 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ffe:	0809a023          	sw	zero,128(s3)
    80004002:	bf51                	j	80003f96 <itrunc+0x3e>

0000000080004004 <iput>:
{
    80004004:	1101                	addi	sp,sp,-32
    80004006:	ec06                	sd	ra,24(sp)
    80004008:	e822                	sd	s0,16(sp)
    8000400a:	e426                	sd	s1,8(sp)
    8000400c:	e04a                	sd	s2,0(sp)
    8000400e:	1000                	addi	s0,sp,32
    80004010:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004012:	0001d517          	auipc	a0,0x1d
    80004016:	cfe50513          	addi	a0,a0,-770 # 80020d10 <itable>
    8000401a:	ffffd097          	auipc	ra,0xffffd
    8000401e:	bd0080e7          	jalr	-1072(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004022:	4498                	lw	a4,8(s1)
    80004024:	4785                	li	a5,1
    80004026:	02f70363          	beq	a4,a5,8000404c <iput+0x48>
  ip->ref--;
    8000402a:	449c                	lw	a5,8(s1)
    8000402c:	37fd                	addiw	a5,a5,-1
    8000402e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004030:	0001d517          	auipc	a0,0x1d
    80004034:	ce050513          	addi	a0,a0,-800 # 80020d10 <itable>
    80004038:	ffffd097          	auipc	ra,0xffffd
    8000403c:	c66080e7          	jalr	-922(ra) # 80000c9e <release>
}
    80004040:	60e2                	ld	ra,24(sp)
    80004042:	6442                	ld	s0,16(sp)
    80004044:	64a2                	ld	s1,8(sp)
    80004046:	6902                	ld	s2,0(sp)
    80004048:	6105                	addi	sp,sp,32
    8000404a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000404c:	40bc                	lw	a5,64(s1)
    8000404e:	dff1                	beqz	a5,8000402a <iput+0x26>
    80004050:	04a49783          	lh	a5,74(s1)
    80004054:	fbf9                	bnez	a5,8000402a <iput+0x26>
    acquiresleep(&ip->lock);
    80004056:	01048913          	addi	s2,s1,16
    8000405a:	854a                	mv	a0,s2
    8000405c:	00001097          	auipc	ra,0x1
    80004060:	aa8080e7          	jalr	-1368(ra) # 80004b04 <acquiresleep>
    release(&itable.lock);
    80004064:	0001d517          	auipc	a0,0x1d
    80004068:	cac50513          	addi	a0,a0,-852 # 80020d10 <itable>
    8000406c:	ffffd097          	auipc	ra,0xffffd
    80004070:	c32080e7          	jalr	-974(ra) # 80000c9e <release>
    itrunc(ip);
    80004074:	8526                	mv	a0,s1
    80004076:	00000097          	auipc	ra,0x0
    8000407a:	ee2080e7          	jalr	-286(ra) # 80003f58 <itrunc>
    ip->type = 0;
    8000407e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004082:	8526                	mv	a0,s1
    80004084:	00000097          	auipc	ra,0x0
    80004088:	cfc080e7          	jalr	-772(ra) # 80003d80 <iupdate>
    ip->valid = 0;
    8000408c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004090:	854a                	mv	a0,s2
    80004092:	00001097          	auipc	ra,0x1
    80004096:	ac8080e7          	jalr	-1336(ra) # 80004b5a <releasesleep>
    acquire(&itable.lock);
    8000409a:	0001d517          	auipc	a0,0x1d
    8000409e:	c7650513          	addi	a0,a0,-906 # 80020d10 <itable>
    800040a2:	ffffd097          	auipc	ra,0xffffd
    800040a6:	b48080e7          	jalr	-1208(ra) # 80000bea <acquire>
    800040aa:	b741                	j	8000402a <iput+0x26>

00000000800040ac <iunlockput>:
{
    800040ac:	1101                	addi	sp,sp,-32
    800040ae:	ec06                	sd	ra,24(sp)
    800040b0:	e822                	sd	s0,16(sp)
    800040b2:	e426                	sd	s1,8(sp)
    800040b4:	1000                	addi	s0,sp,32
    800040b6:	84aa                	mv	s1,a0
  iunlock(ip);
    800040b8:	00000097          	auipc	ra,0x0
    800040bc:	e54080e7          	jalr	-428(ra) # 80003f0c <iunlock>
  iput(ip);
    800040c0:	8526                	mv	a0,s1
    800040c2:	00000097          	auipc	ra,0x0
    800040c6:	f42080e7          	jalr	-190(ra) # 80004004 <iput>
}
    800040ca:	60e2                	ld	ra,24(sp)
    800040cc:	6442                	ld	s0,16(sp)
    800040ce:	64a2                	ld	s1,8(sp)
    800040d0:	6105                	addi	sp,sp,32
    800040d2:	8082                	ret

00000000800040d4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800040d4:	1141                	addi	sp,sp,-16
    800040d6:	e422                	sd	s0,8(sp)
    800040d8:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800040da:	411c                	lw	a5,0(a0)
    800040dc:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800040de:	415c                	lw	a5,4(a0)
    800040e0:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800040e2:	04451783          	lh	a5,68(a0)
    800040e6:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800040ea:	04a51783          	lh	a5,74(a0)
    800040ee:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800040f2:	04c56783          	lwu	a5,76(a0)
    800040f6:	e99c                	sd	a5,16(a1)
}
    800040f8:	6422                	ld	s0,8(sp)
    800040fa:	0141                	addi	sp,sp,16
    800040fc:	8082                	ret

00000000800040fe <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800040fe:	457c                	lw	a5,76(a0)
    80004100:	0ed7e963          	bltu	a5,a3,800041f2 <readi+0xf4>
{
    80004104:	7159                	addi	sp,sp,-112
    80004106:	f486                	sd	ra,104(sp)
    80004108:	f0a2                	sd	s0,96(sp)
    8000410a:	eca6                	sd	s1,88(sp)
    8000410c:	e8ca                	sd	s2,80(sp)
    8000410e:	e4ce                	sd	s3,72(sp)
    80004110:	e0d2                	sd	s4,64(sp)
    80004112:	fc56                	sd	s5,56(sp)
    80004114:	f85a                	sd	s6,48(sp)
    80004116:	f45e                	sd	s7,40(sp)
    80004118:	f062                	sd	s8,32(sp)
    8000411a:	ec66                	sd	s9,24(sp)
    8000411c:	e86a                	sd	s10,16(sp)
    8000411e:	e46e                	sd	s11,8(sp)
    80004120:	1880                	addi	s0,sp,112
    80004122:	8b2a                	mv	s6,a0
    80004124:	8bae                	mv	s7,a1
    80004126:	8a32                	mv	s4,a2
    80004128:	84b6                	mv	s1,a3
    8000412a:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    8000412c:	9f35                	addw	a4,a4,a3
    return 0;
    8000412e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004130:	0ad76063          	bltu	a4,a3,800041d0 <readi+0xd2>
  if(off + n > ip->size)
    80004134:	00e7f463          	bgeu	a5,a4,8000413c <readi+0x3e>
    n = ip->size - off;
    80004138:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000413c:	0a0a8963          	beqz	s5,800041ee <readi+0xf0>
    80004140:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004142:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004146:	5c7d                	li	s8,-1
    80004148:	a82d                	j	80004182 <readi+0x84>
    8000414a:	020d1d93          	slli	s11,s10,0x20
    8000414e:	020ddd93          	srli	s11,s11,0x20
    80004152:	05890613          	addi	a2,s2,88
    80004156:	86ee                	mv	a3,s11
    80004158:	963a                	add	a2,a2,a4
    8000415a:	85d2                	mv	a1,s4
    8000415c:	855e                	mv	a0,s7
    8000415e:	ffffe097          	auipc	ra,0xffffe
    80004162:	7f2080e7          	jalr	2034(ra) # 80002950 <either_copyout>
    80004166:	05850d63          	beq	a0,s8,800041c0 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000416a:	854a                	mv	a0,s2
    8000416c:	fffff097          	auipc	ra,0xfffff
    80004170:	5f4080e7          	jalr	1524(ra) # 80003760 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004174:	013d09bb          	addw	s3,s10,s3
    80004178:	009d04bb          	addw	s1,s10,s1
    8000417c:	9a6e                	add	s4,s4,s11
    8000417e:	0559f763          	bgeu	s3,s5,800041cc <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80004182:	00a4d59b          	srliw	a1,s1,0xa
    80004186:	855a                	mv	a0,s6
    80004188:	00000097          	auipc	ra,0x0
    8000418c:	8a2080e7          	jalr	-1886(ra) # 80003a2a <bmap>
    80004190:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004194:	cd85                	beqz	a1,800041cc <readi+0xce>
    bp = bread(ip->dev, addr);
    80004196:	000b2503          	lw	a0,0(s6)
    8000419a:	fffff097          	auipc	ra,0xfffff
    8000419e:	496080e7          	jalr	1174(ra) # 80003630 <bread>
    800041a2:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800041a4:	3ff4f713          	andi	a4,s1,1023
    800041a8:	40ec87bb          	subw	a5,s9,a4
    800041ac:	413a86bb          	subw	a3,s5,s3
    800041b0:	8d3e                	mv	s10,a5
    800041b2:	2781                	sext.w	a5,a5
    800041b4:	0006861b          	sext.w	a2,a3
    800041b8:	f8f679e3          	bgeu	a2,a5,8000414a <readi+0x4c>
    800041bc:	8d36                	mv	s10,a3
    800041be:	b771                	j	8000414a <readi+0x4c>
      brelse(bp);
    800041c0:	854a                	mv	a0,s2
    800041c2:	fffff097          	auipc	ra,0xfffff
    800041c6:	59e080e7          	jalr	1438(ra) # 80003760 <brelse>
      tot = -1;
    800041ca:	59fd                	li	s3,-1
  }
  return tot;
    800041cc:	0009851b          	sext.w	a0,s3
}
    800041d0:	70a6                	ld	ra,104(sp)
    800041d2:	7406                	ld	s0,96(sp)
    800041d4:	64e6                	ld	s1,88(sp)
    800041d6:	6946                	ld	s2,80(sp)
    800041d8:	69a6                	ld	s3,72(sp)
    800041da:	6a06                	ld	s4,64(sp)
    800041dc:	7ae2                	ld	s5,56(sp)
    800041de:	7b42                	ld	s6,48(sp)
    800041e0:	7ba2                	ld	s7,40(sp)
    800041e2:	7c02                	ld	s8,32(sp)
    800041e4:	6ce2                	ld	s9,24(sp)
    800041e6:	6d42                	ld	s10,16(sp)
    800041e8:	6da2                	ld	s11,8(sp)
    800041ea:	6165                	addi	sp,sp,112
    800041ec:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041ee:	89d6                	mv	s3,s5
    800041f0:	bff1                	j	800041cc <readi+0xce>
    return 0;
    800041f2:	4501                	li	a0,0
}
    800041f4:	8082                	ret

00000000800041f6 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800041f6:	457c                	lw	a5,76(a0)
    800041f8:	10d7e863          	bltu	a5,a3,80004308 <writei+0x112>
{
    800041fc:	7159                	addi	sp,sp,-112
    800041fe:	f486                	sd	ra,104(sp)
    80004200:	f0a2                	sd	s0,96(sp)
    80004202:	eca6                	sd	s1,88(sp)
    80004204:	e8ca                	sd	s2,80(sp)
    80004206:	e4ce                	sd	s3,72(sp)
    80004208:	e0d2                	sd	s4,64(sp)
    8000420a:	fc56                	sd	s5,56(sp)
    8000420c:	f85a                	sd	s6,48(sp)
    8000420e:	f45e                	sd	s7,40(sp)
    80004210:	f062                	sd	s8,32(sp)
    80004212:	ec66                	sd	s9,24(sp)
    80004214:	e86a                	sd	s10,16(sp)
    80004216:	e46e                	sd	s11,8(sp)
    80004218:	1880                	addi	s0,sp,112
    8000421a:	8aaa                	mv	s5,a0
    8000421c:	8bae                	mv	s7,a1
    8000421e:	8a32                	mv	s4,a2
    80004220:	8936                	mv	s2,a3
    80004222:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004224:	00e687bb          	addw	a5,a3,a4
    80004228:	0ed7e263          	bltu	a5,a3,8000430c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000422c:	00043737          	lui	a4,0x43
    80004230:	0ef76063          	bltu	a4,a5,80004310 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004234:	0c0b0863          	beqz	s6,80004304 <writei+0x10e>
    80004238:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000423a:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000423e:	5c7d                	li	s8,-1
    80004240:	a091                	j	80004284 <writei+0x8e>
    80004242:	020d1d93          	slli	s11,s10,0x20
    80004246:	020ddd93          	srli	s11,s11,0x20
    8000424a:	05848513          	addi	a0,s1,88
    8000424e:	86ee                	mv	a3,s11
    80004250:	8652                	mv	a2,s4
    80004252:	85de                	mv	a1,s7
    80004254:	953a                	add	a0,a0,a4
    80004256:	ffffe097          	auipc	ra,0xffffe
    8000425a:	750080e7          	jalr	1872(ra) # 800029a6 <either_copyin>
    8000425e:	07850263          	beq	a0,s8,800042c2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004262:	8526                	mv	a0,s1
    80004264:	00000097          	auipc	ra,0x0
    80004268:	780080e7          	jalr	1920(ra) # 800049e4 <log_write>
    brelse(bp);
    8000426c:	8526                	mv	a0,s1
    8000426e:	fffff097          	auipc	ra,0xfffff
    80004272:	4f2080e7          	jalr	1266(ra) # 80003760 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004276:	013d09bb          	addw	s3,s10,s3
    8000427a:	012d093b          	addw	s2,s10,s2
    8000427e:	9a6e                	add	s4,s4,s11
    80004280:	0569f663          	bgeu	s3,s6,800042cc <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004284:	00a9559b          	srliw	a1,s2,0xa
    80004288:	8556                	mv	a0,s5
    8000428a:	fffff097          	auipc	ra,0xfffff
    8000428e:	7a0080e7          	jalr	1952(ra) # 80003a2a <bmap>
    80004292:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004296:	c99d                	beqz	a1,800042cc <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004298:	000aa503          	lw	a0,0(s5)
    8000429c:	fffff097          	auipc	ra,0xfffff
    800042a0:	394080e7          	jalr	916(ra) # 80003630 <bread>
    800042a4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800042a6:	3ff97713          	andi	a4,s2,1023
    800042aa:	40ec87bb          	subw	a5,s9,a4
    800042ae:	413b06bb          	subw	a3,s6,s3
    800042b2:	8d3e                	mv	s10,a5
    800042b4:	2781                	sext.w	a5,a5
    800042b6:	0006861b          	sext.w	a2,a3
    800042ba:	f8f674e3          	bgeu	a2,a5,80004242 <writei+0x4c>
    800042be:	8d36                	mv	s10,a3
    800042c0:	b749                	j	80004242 <writei+0x4c>
      brelse(bp);
    800042c2:	8526                	mv	a0,s1
    800042c4:	fffff097          	auipc	ra,0xfffff
    800042c8:	49c080e7          	jalr	1180(ra) # 80003760 <brelse>
  }

  if(off > ip->size)
    800042cc:	04caa783          	lw	a5,76(s5)
    800042d0:	0127f463          	bgeu	a5,s2,800042d8 <writei+0xe2>
    ip->size = off;
    800042d4:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800042d8:	8556                	mv	a0,s5
    800042da:	00000097          	auipc	ra,0x0
    800042de:	aa6080e7          	jalr	-1370(ra) # 80003d80 <iupdate>

  return tot;
    800042e2:	0009851b          	sext.w	a0,s3
}
    800042e6:	70a6                	ld	ra,104(sp)
    800042e8:	7406                	ld	s0,96(sp)
    800042ea:	64e6                	ld	s1,88(sp)
    800042ec:	6946                	ld	s2,80(sp)
    800042ee:	69a6                	ld	s3,72(sp)
    800042f0:	6a06                	ld	s4,64(sp)
    800042f2:	7ae2                	ld	s5,56(sp)
    800042f4:	7b42                	ld	s6,48(sp)
    800042f6:	7ba2                	ld	s7,40(sp)
    800042f8:	7c02                	ld	s8,32(sp)
    800042fa:	6ce2                	ld	s9,24(sp)
    800042fc:	6d42                	ld	s10,16(sp)
    800042fe:	6da2                	ld	s11,8(sp)
    80004300:	6165                	addi	sp,sp,112
    80004302:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004304:	89da                	mv	s3,s6
    80004306:	bfc9                	j	800042d8 <writei+0xe2>
    return -1;
    80004308:	557d                	li	a0,-1
}
    8000430a:	8082                	ret
    return -1;
    8000430c:	557d                	li	a0,-1
    8000430e:	bfe1                	j	800042e6 <writei+0xf0>
    return -1;
    80004310:	557d                	li	a0,-1
    80004312:	bfd1                	j	800042e6 <writei+0xf0>

0000000080004314 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004314:	1141                	addi	sp,sp,-16
    80004316:	e406                	sd	ra,8(sp)
    80004318:	e022                	sd	s0,0(sp)
    8000431a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000431c:	4639                	li	a2,14
    8000431e:	ffffd097          	auipc	ra,0xffffd
    80004322:	aa0080e7          	jalr	-1376(ra) # 80000dbe <strncmp>
}
    80004326:	60a2                	ld	ra,8(sp)
    80004328:	6402                	ld	s0,0(sp)
    8000432a:	0141                	addi	sp,sp,16
    8000432c:	8082                	ret

000000008000432e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000432e:	7139                	addi	sp,sp,-64
    80004330:	fc06                	sd	ra,56(sp)
    80004332:	f822                	sd	s0,48(sp)
    80004334:	f426                	sd	s1,40(sp)
    80004336:	f04a                	sd	s2,32(sp)
    80004338:	ec4e                	sd	s3,24(sp)
    8000433a:	e852                	sd	s4,16(sp)
    8000433c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000433e:	04451703          	lh	a4,68(a0)
    80004342:	4785                	li	a5,1
    80004344:	00f71a63          	bne	a4,a5,80004358 <dirlookup+0x2a>
    80004348:	892a                	mv	s2,a0
    8000434a:	89ae                	mv	s3,a1
    8000434c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000434e:	457c                	lw	a5,76(a0)
    80004350:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004352:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004354:	e79d                	bnez	a5,80004382 <dirlookup+0x54>
    80004356:	a8a5                	j	800043ce <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004358:	00004517          	auipc	a0,0x4
    8000435c:	3c850513          	addi	a0,a0,968 # 80008720 <syscalls+0x1d0>
    80004360:	ffffc097          	auipc	ra,0xffffc
    80004364:	1e4080e7          	jalr	484(ra) # 80000544 <panic>
      panic("dirlookup read");
    80004368:	00004517          	auipc	a0,0x4
    8000436c:	3d050513          	addi	a0,a0,976 # 80008738 <syscalls+0x1e8>
    80004370:	ffffc097          	auipc	ra,0xffffc
    80004374:	1d4080e7          	jalr	468(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004378:	24c1                	addiw	s1,s1,16
    8000437a:	04c92783          	lw	a5,76(s2)
    8000437e:	04f4f763          	bgeu	s1,a5,800043cc <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004382:	4741                	li	a4,16
    80004384:	86a6                	mv	a3,s1
    80004386:	fc040613          	addi	a2,s0,-64
    8000438a:	4581                	li	a1,0
    8000438c:	854a                	mv	a0,s2
    8000438e:	00000097          	auipc	ra,0x0
    80004392:	d70080e7          	jalr	-656(ra) # 800040fe <readi>
    80004396:	47c1                	li	a5,16
    80004398:	fcf518e3          	bne	a0,a5,80004368 <dirlookup+0x3a>
    if(de.inum == 0)
    8000439c:	fc045783          	lhu	a5,-64(s0)
    800043a0:	dfe1                	beqz	a5,80004378 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800043a2:	fc240593          	addi	a1,s0,-62
    800043a6:	854e                	mv	a0,s3
    800043a8:	00000097          	auipc	ra,0x0
    800043ac:	f6c080e7          	jalr	-148(ra) # 80004314 <namecmp>
    800043b0:	f561                	bnez	a0,80004378 <dirlookup+0x4a>
      if(poff)
    800043b2:	000a0463          	beqz	s4,800043ba <dirlookup+0x8c>
        *poff = off;
    800043b6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800043ba:	fc045583          	lhu	a1,-64(s0)
    800043be:	00092503          	lw	a0,0(s2)
    800043c2:	fffff097          	auipc	ra,0xfffff
    800043c6:	750080e7          	jalr	1872(ra) # 80003b12 <iget>
    800043ca:	a011                	j	800043ce <dirlookup+0xa0>
  return 0;
    800043cc:	4501                	li	a0,0
}
    800043ce:	70e2                	ld	ra,56(sp)
    800043d0:	7442                	ld	s0,48(sp)
    800043d2:	74a2                	ld	s1,40(sp)
    800043d4:	7902                	ld	s2,32(sp)
    800043d6:	69e2                	ld	s3,24(sp)
    800043d8:	6a42                	ld	s4,16(sp)
    800043da:	6121                	addi	sp,sp,64
    800043dc:	8082                	ret

00000000800043de <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800043de:	711d                	addi	sp,sp,-96
    800043e0:	ec86                	sd	ra,88(sp)
    800043e2:	e8a2                	sd	s0,80(sp)
    800043e4:	e4a6                	sd	s1,72(sp)
    800043e6:	e0ca                	sd	s2,64(sp)
    800043e8:	fc4e                	sd	s3,56(sp)
    800043ea:	f852                	sd	s4,48(sp)
    800043ec:	f456                	sd	s5,40(sp)
    800043ee:	f05a                	sd	s6,32(sp)
    800043f0:	ec5e                	sd	s7,24(sp)
    800043f2:	e862                	sd	s8,16(sp)
    800043f4:	e466                	sd	s9,8(sp)
    800043f6:	1080                	addi	s0,sp,96
    800043f8:	84aa                	mv	s1,a0
    800043fa:	8b2e                	mv	s6,a1
    800043fc:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800043fe:	00054703          	lbu	a4,0(a0)
    80004402:	02f00793          	li	a5,47
    80004406:	02f70363          	beq	a4,a5,8000442c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000440a:	ffffd097          	auipc	ra,0xffffd
    8000440e:	7aa080e7          	jalr	1962(ra) # 80001bb4 <myproc>
    80004412:	15053503          	ld	a0,336(a0)
    80004416:	00000097          	auipc	ra,0x0
    8000441a:	9f6080e7          	jalr	-1546(ra) # 80003e0c <idup>
    8000441e:	89aa                	mv	s3,a0
  while(*path == '/')
    80004420:	02f00913          	li	s2,47
  len = path - s;
    80004424:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004426:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004428:	4c05                	li	s8,1
    8000442a:	a865                	j	800044e2 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000442c:	4585                	li	a1,1
    8000442e:	4505                	li	a0,1
    80004430:	fffff097          	auipc	ra,0xfffff
    80004434:	6e2080e7          	jalr	1762(ra) # 80003b12 <iget>
    80004438:	89aa                	mv	s3,a0
    8000443a:	b7dd                	j	80004420 <namex+0x42>
      iunlockput(ip);
    8000443c:	854e                	mv	a0,s3
    8000443e:	00000097          	auipc	ra,0x0
    80004442:	c6e080e7          	jalr	-914(ra) # 800040ac <iunlockput>
      return 0;
    80004446:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004448:	854e                	mv	a0,s3
    8000444a:	60e6                	ld	ra,88(sp)
    8000444c:	6446                	ld	s0,80(sp)
    8000444e:	64a6                	ld	s1,72(sp)
    80004450:	6906                	ld	s2,64(sp)
    80004452:	79e2                	ld	s3,56(sp)
    80004454:	7a42                	ld	s4,48(sp)
    80004456:	7aa2                	ld	s5,40(sp)
    80004458:	7b02                	ld	s6,32(sp)
    8000445a:	6be2                	ld	s7,24(sp)
    8000445c:	6c42                	ld	s8,16(sp)
    8000445e:	6ca2                	ld	s9,8(sp)
    80004460:	6125                	addi	sp,sp,96
    80004462:	8082                	ret
      iunlock(ip);
    80004464:	854e                	mv	a0,s3
    80004466:	00000097          	auipc	ra,0x0
    8000446a:	aa6080e7          	jalr	-1370(ra) # 80003f0c <iunlock>
      return ip;
    8000446e:	bfe9                	j	80004448 <namex+0x6a>
      iunlockput(ip);
    80004470:	854e                	mv	a0,s3
    80004472:	00000097          	auipc	ra,0x0
    80004476:	c3a080e7          	jalr	-966(ra) # 800040ac <iunlockput>
      return 0;
    8000447a:	89d2                	mv	s3,s4
    8000447c:	b7f1                	j	80004448 <namex+0x6a>
  len = path - s;
    8000447e:	40b48633          	sub	a2,s1,a1
    80004482:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004486:	094cd463          	bge	s9,s4,8000450e <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000448a:	4639                	li	a2,14
    8000448c:	8556                	mv	a0,s5
    8000448e:	ffffd097          	auipc	ra,0xffffd
    80004492:	8b8080e7          	jalr	-1864(ra) # 80000d46 <memmove>
  while(*path == '/')
    80004496:	0004c783          	lbu	a5,0(s1)
    8000449a:	01279763          	bne	a5,s2,800044a8 <namex+0xca>
    path++;
    8000449e:	0485                	addi	s1,s1,1
  while(*path == '/')
    800044a0:	0004c783          	lbu	a5,0(s1)
    800044a4:	ff278de3          	beq	a5,s2,8000449e <namex+0xc0>
    ilock(ip);
    800044a8:	854e                	mv	a0,s3
    800044aa:	00000097          	auipc	ra,0x0
    800044ae:	9a0080e7          	jalr	-1632(ra) # 80003e4a <ilock>
    if(ip->type != T_DIR){
    800044b2:	04499783          	lh	a5,68(s3)
    800044b6:	f98793e3          	bne	a5,s8,8000443c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800044ba:	000b0563          	beqz	s6,800044c4 <namex+0xe6>
    800044be:	0004c783          	lbu	a5,0(s1)
    800044c2:	d3cd                	beqz	a5,80004464 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800044c4:	865e                	mv	a2,s7
    800044c6:	85d6                	mv	a1,s5
    800044c8:	854e                	mv	a0,s3
    800044ca:	00000097          	auipc	ra,0x0
    800044ce:	e64080e7          	jalr	-412(ra) # 8000432e <dirlookup>
    800044d2:	8a2a                	mv	s4,a0
    800044d4:	dd51                	beqz	a0,80004470 <namex+0x92>
    iunlockput(ip);
    800044d6:	854e                	mv	a0,s3
    800044d8:	00000097          	auipc	ra,0x0
    800044dc:	bd4080e7          	jalr	-1068(ra) # 800040ac <iunlockput>
    ip = next;
    800044e0:	89d2                	mv	s3,s4
  while(*path == '/')
    800044e2:	0004c783          	lbu	a5,0(s1)
    800044e6:	05279763          	bne	a5,s2,80004534 <namex+0x156>
    path++;
    800044ea:	0485                	addi	s1,s1,1
  while(*path == '/')
    800044ec:	0004c783          	lbu	a5,0(s1)
    800044f0:	ff278de3          	beq	a5,s2,800044ea <namex+0x10c>
  if(*path == 0)
    800044f4:	c79d                	beqz	a5,80004522 <namex+0x144>
    path++;
    800044f6:	85a6                	mv	a1,s1
  len = path - s;
    800044f8:	8a5e                	mv	s4,s7
    800044fa:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800044fc:	01278963          	beq	a5,s2,8000450e <namex+0x130>
    80004500:	dfbd                	beqz	a5,8000447e <namex+0xa0>
    path++;
    80004502:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004504:	0004c783          	lbu	a5,0(s1)
    80004508:	ff279ce3          	bne	a5,s2,80004500 <namex+0x122>
    8000450c:	bf8d                	j	8000447e <namex+0xa0>
    memmove(name, s, len);
    8000450e:	2601                	sext.w	a2,a2
    80004510:	8556                	mv	a0,s5
    80004512:	ffffd097          	auipc	ra,0xffffd
    80004516:	834080e7          	jalr	-1996(ra) # 80000d46 <memmove>
    name[len] = 0;
    8000451a:	9a56                	add	s4,s4,s5
    8000451c:	000a0023          	sb	zero,0(s4)
    80004520:	bf9d                	j	80004496 <namex+0xb8>
  if(nameiparent){
    80004522:	f20b03e3          	beqz	s6,80004448 <namex+0x6a>
    iput(ip);
    80004526:	854e                	mv	a0,s3
    80004528:	00000097          	auipc	ra,0x0
    8000452c:	adc080e7          	jalr	-1316(ra) # 80004004 <iput>
    return 0;
    80004530:	4981                	li	s3,0
    80004532:	bf19                	j	80004448 <namex+0x6a>
  if(*path == 0)
    80004534:	d7fd                	beqz	a5,80004522 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004536:	0004c783          	lbu	a5,0(s1)
    8000453a:	85a6                	mv	a1,s1
    8000453c:	b7d1                	j	80004500 <namex+0x122>

000000008000453e <dirlink>:
{
    8000453e:	7139                	addi	sp,sp,-64
    80004540:	fc06                	sd	ra,56(sp)
    80004542:	f822                	sd	s0,48(sp)
    80004544:	f426                	sd	s1,40(sp)
    80004546:	f04a                	sd	s2,32(sp)
    80004548:	ec4e                	sd	s3,24(sp)
    8000454a:	e852                	sd	s4,16(sp)
    8000454c:	0080                	addi	s0,sp,64
    8000454e:	892a                	mv	s2,a0
    80004550:	8a2e                	mv	s4,a1
    80004552:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004554:	4601                	li	a2,0
    80004556:	00000097          	auipc	ra,0x0
    8000455a:	dd8080e7          	jalr	-552(ra) # 8000432e <dirlookup>
    8000455e:	e93d                	bnez	a0,800045d4 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004560:	04c92483          	lw	s1,76(s2)
    80004564:	c49d                	beqz	s1,80004592 <dirlink+0x54>
    80004566:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004568:	4741                	li	a4,16
    8000456a:	86a6                	mv	a3,s1
    8000456c:	fc040613          	addi	a2,s0,-64
    80004570:	4581                	li	a1,0
    80004572:	854a                	mv	a0,s2
    80004574:	00000097          	auipc	ra,0x0
    80004578:	b8a080e7          	jalr	-1142(ra) # 800040fe <readi>
    8000457c:	47c1                	li	a5,16
    8000457e:	06f51163          	bne	a0,a5,800045e0 <dirlink+0xa2>
    if(de.inum == 0)
    80004582:	fc045783          	lhu	a5,-64(s0)
    80004586:	c791                	beqz	a5,80004592 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004588:	24c1                	addiw	s1,s1,16
    8000458a:	04c92783          	lw	a5,76(s2)
    8000458e:	fcf4ede3          	bltu	s1,a5,80004568 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004592:	4639                	li	a2,14
    80004594:	85d2                	mv	a1,s4
    80004596:	fc240513          	addi	a0,s0,-62
    8000459a:	ffffd097          	auipc	ra,0xffffd
    8000459e:	860080e7          	jalr	-1952(ra) # 80000dfa <strncpy>
  de.inum = inum;
    800045a2:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800045a6:	4741                	li	a4,16
    800045a8:	86a6                	mv	a3,s1
    800045aa:	fc040613          	addi	a2,s0,-64
    800045ae:	4581                	li	a1,0
    800045b0:	854a                	mv	a0,s2
    800045b2:	00000097          	auipc	ra,0x0
    800045b6:	c44080e7          	jalr	-956(ra) # 800041f6 <writei>
    800045ba:	1541                	addi	a0,a0,-16
    800045bc:	00a03533          	snez	a0,a0
    800045c0:	40a00533          	neg	a0,a0
}
    800045c4:	70e2                	ld	ra,56(sp)
    800045c6:	7442                	ld	s0,48(sp)
    800045c8:	74a2                	ld	s1,40(sp)
    800045ca:	7902                	ld	s2,32(sp)
    800045cc:	69e2                	ld	s3,24(sp)
    800045ce:	6a42                	ld	s4,16(sp)
    800045d0:	6121                	addi	sp,sp,64
    800045d2:	8082                	ret
    iput(ip);
    800045d4:	00000097          	auipc	ra,0x0
    800045d8:	a30080e7          	jalr	-1488(ra) # 80004004 <iput>
    return -1;
    800045dc:	557d                	li	a0,-1
    800045de:	b7dd                	j	800045c4 <dirlink+0x86>
      panic("dirlink read");
    800045e0:	00004517          	auipc	a0,0x4
    800045e4:	16850513          	addi	a0,a0,360 # 80008748 <syscalls+0x1f8>
    800045e8:	ffffc097          	auipc	ra,0xffffc
    800045ec:	f5c080e7          	jalr	-164(ra) # 80000544 <panic>

00000000800045f0 <namei>:

struct inode*
namei(char *path)
{
    800045f0:	1101                	addi	sp,sp,-32
    800045f2:	ec06                	sd	ra,24(sp)
    800045f4:	e822                	sd	s0,16(sp)
    800045f6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800045f8:	fe040613          	addi	a2,s0,-32
    800045fc:	4581                	li	a1,0
    800045fe:	00000097          	auipc	ra,0x0
    80004602:	de0080e7          	jalr	-544(ra) # 800043de <namex>
}
    80004606:	60e2                	ld	ra,24(sp)
    80004608:	6442                	ld	s0,16(sp)
    8000460a:	6105                	addi	sp,sp,32
    8000460c:	8082                	ret

000000008000460e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000460e:	1141                	addi	sp,sp,-16
    80004610:	e406                	sd	ra,8(sp)
    80004612:	e022                	sd	s0,0(sp)
    80004614:	0800                	addi	s0,sp,16
    80004616:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004618:	4585                	li	a1,1
    8000461a:	00000097          	auipc	ra,0x0
    8000461e:	dc4080e7          	jalr	-572(ra) # 800043de <namex>
}
    80004622:	60a2                	ld	ra,8(sp)
    80004624:	6402                	ld	s0,0(sp)
    80004626:	0141                	addi	sp,sp,16
    80004628:	8082                	ret

000000008000462a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000462a:	1101                	addi	sp,sp,-32
    8000462c:	ec06                	sd	ra,24(sp)
    8000462e:	e822                	sd	s0,16(sp)
    80004630:	e426                	sd	s1,8(sp)
    80004632:	e04a                	sd	s2,0(sp)
    80004634:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004636:	0001e917          	auipc	s2,0x1e
    8000463a:	18290913          	addi	s2,s2,386 # 800227b8 <log>
    8000463e:	01892583          	lw	a1,24(s2)
    80004642:	02892503          	lw	a0,40(s2)
    80004646:	fffff097          	auipc	ra,0xfffff
    8000464a:	fea080e7          	jalr	-22(ra) # 80003630 <bread>
    8000464e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004650:	02c92683          	lw	a3,44(s2)
    80004654:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004656:	02d05763          	blez	a3,80004684 <write_head+0x5a>
    8000465a:	0001e797          	auipc	a5,0x1e
    8000465e:	18e78793          	addi	a5,a5,398 # 800227e8 <log+0x30>
    80004662:	05c50713          	addi	a4,a0,92
    80004666:	36fd                	addiw	a3,a3,-1
    80004668:	1682                	slli	a3,a3,0x20
    8000466a:	9281                	srli	a3,a3,0x20
    8000466c:	068a                	slli	a3,a3,0x2
    8000466e:	0001e617          	auipc	a2,0x1e
    80004672:	17e60613          	addi	a2,a2,382 # 800227ec <log+0x34>
    80004676:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004678:	4390                	lw	a2,0(a5)
    8000467a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000467c:	0791                	addi	a5,a5,4
    8000467e:	0711                	addi	a4,a4,4
    80004680:	fed79ce3          	bne	a5,a3,80004678 <write_head+0x4e>
  }
  bwrite(buf);
    80004684:	8526                	mv	a0,s1
    80004686:	fffff097          	auipc	ra,0xfffff
    8000468a:	09c080e7          	jalr	156(ra) # 80003722 <bwrite>
  brelse(buf);
    8000468e:	8526                	mv	a0,s1
    80004690:	fffff097          	auipc	ra,0xfffff
    80004694:	0d0080e7          	jalr	208(ra) # 80003760 <brelse>
}
    80004698:	60e2                	ld	ra,24(sp)
    8000469a:	6442                	ld	s0,16(sp)
    8000469c:	64a2                	ld	s1,8(sp)
    8000469e:	6902                	ld	s2,0(sp)
    800046a0:	6105                	addi	sp,sp,32
    800046a2:	8082                	ret

00000000800046a4 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800046a4:	0001e797          	auipc	a5,0x1e
    800046a8:	1407a783          	lw	a5,320(a5) # 800227e4 <log+0x2c>
    800046ac:	0af05d63          	blez	a5,80004766 <install_trans+0xc2>
{
    800046b0:	7139                	addi	sp,sp,-64
    800046b2:	fc06                	sd	ra,56(sp)
    800046b4:	f822                	sd	s0,48(sp)
    800046b6:	f426                	sd	s1,40(sp)
    800046b8:	f04a                	sd	s2,32(sp)
    800046ba:	ec4e                	sd	s3,24(sp)
    800046bc:	e852                	sd	s4,16(sp)
    800046be:	e456                	sd	s5,8(sp)
    800046c0:	e05a                	sd	s6,0(sp)
    800046c2:	0080                	addi	s0,sp,64
    800046c4:	8b2a                	mv	s6,a0
    800046c6:	0001ea97          	auipc	s5,0x1e
    800046ca:	122a8a93          	addi	s5,s5,290 # 800227e8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046ce:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800046d0:	0001e997          	auipc	s3,0x1e
    800046d4:	0e898993          	addi	s3,s3,232 # 800227b8 <log>
    800046d8:	a035                	j	80004704 <install_trans+0x60>
      bunpin(dbuf);
    800046da:	8526                	mv	a0,s1
    800046dc:	fffff097          	auipc	ra,0xfffff
    800046e0:	15e080e7          	jalr	350(ra) # 8000383a <bunpin>
    brelse(lbuf);
    800046e4:	854a                	mv	a0,s2
    800046e6:	fffff097          	auipc	ra,0xfffff
    800046ea:	07a080e7          	jalr	122(ra) # 80003760 <brelse>
    brelse(dbuf);
    800046ee:	8526                	mv	a0,s1
    800046f0:	fffff097          	auipc	ra,0xfffff
    800046f4:	070080e7          	jalr	112(ra) # 80003760 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046f8:	2a05                	addiw	s4,s4,1
    800046fa:	0a91                	addi	s5,s5,4
    800046fc:	02c9a783          	lw	a5,44(s3)
    80004700:	04fa5963          	bge	s4,a5,80004752 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004704:	0189a583          	lw	a1,24(s3)
    80004708:	014585bb          	addw	a1,a1,s4
    8000470c:	2585                	addiw	a1,a1,1
    8000470e:	0289a503          	lw	a0,40(s3)
    80004712:	fffff097          	auipc	ra,0xfffff
    80004716:	f1e080e7          	jalr	-226(ra) # 80003630 <bread>
    8000471a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000471c:	000aa583          	lw	a1,0(s5)
    80004720:	0289a503          	lw	a0,40(s3)
    80004724:	fffff097          	auipc	ra,0xfffff
    80004728:	f0c080e7          	jalr	-244(ra) # 80003630 <bread>
    8000472c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000472e:	40000613          	li	a2,1024
    80004732:	05890593          	addi	a1,s2,88
    80004736:	05850513          	addi	a0,a0,88
    8000473a:	ffffc097          	auipc	ra,0xffffc
    8000473e:	60c080e7          	jalr	1548(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004742:	8526                	mv	a0,s1
    80004744:	fffff097          	auipc	ra,0xfffff
    80004748:	fde080e7          	jalr	-34(ra) # 80003722 <bwrite>
    if(recovering == 0)
    8000474c:	f80b1ce3          	bnez	s6,800046e4 <install_trans+0x40>
    80004750:	b769                	j	800046da <install_trans+0x36>
}
    80004752:	70e2                	ld	ra,56(sp)
    80004754:	7442                	ld	s0,48(sp)
    80004756:	74a2                	ld	s1,40(sp)
    80004758:	7902                	ld	s2,32(sp)
    8000475a:	69e2                	ld	s3,24(sp)
    8000475c:	6a42                	ld	s4,16(sp)
    8000475e:	6aa2                	ld	s5,8(sp)
    80004760:	6b02                	ld	s6,0(sp)
    80004762:	6121                	addi	sp,sp,64
    80004764:	8082                	ret
    80004766:	8082                	ret

0000000080004768 <initlog>:
{
    80004768:	7179                	addi	sp,sp,-48
    8000476a:	f406                	sd	ra,40(sp)
    8000476c:	f022                	sd	s0,32(sp)
    8000476e:	ec26                	sd	s1,24(sp)
    80004770:	e84a                	sd	s2,16(sp)
    80004772:	e44e                	sd	s3,8(sp)
    80004774:	1800                	addi	s0,sp,48
    80004776:	892a                	mv	s2,a0
    80004778:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000477a:	0001e497          	auipc	s1,0x1e
    8000477e:	03e48493          	addi	s1,s1,62 # 800227b8 <log>
    80004782:	00004597          	auipc	a1,0x4
    80004786:	fd658593          	addi	a1,a1,-42 # 80008758 <syscalls+0x208>
    8000478a:	8526                	mv	a0,s1
    8000478c:	ffffc097          	auipc	ra,0xffffc
    80004790:	3ce080e7          	jalr	974(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    80004794:	0149a583          	lw	a1,20(s3)
    80004798:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000479a:	0109a783          	lw	a5,16(s3)
    8000479e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800047a0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800047a4:	854a                	mv	a0,s2
    800047a6:	fffff097          	auipc	ra,0xfffff
    800047aa:	e8a080e7          	jalr	-374(ra) # 80003630 <bread>
  log.lh.n = lh->n;
    800047ae:	4d3c                	lw	a5,88(a0)
    800047b0:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800047b2:	02f05563          	blez	a5,800047dc <initlog+0x74>
    800047b6:	05c50713          	addi	a4,a0,92
    800047ba:	0001e697          	auipc	a3,0x1e
    800047be:	02e68693          	addi	a3,a3,46 # 800227e8 <log+0x30>
    800047c2:	37fd                	addiw	a5,a5,-1
    800047c4:	1782                	slli	a5,a5,0x20
    800047c6:	9381                	srli	a5,a5,0x20
    800047c8:	078a                	slli	a5,a5,0x2
    800047ca:	06050613          	addi	a2,a0,96
    800047ce:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800047d0:	4310                	lw	a2,0(a4)
    800047d2:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800047d4:	0711                	addi	a4,a4,4
    800047d6:	0691                	addi	a3,a3,4
    800047d8:	fef71ce3          	bne	a4,a5,800047d0 <initlog+0x68>
  brelse(buf);
    800047dc:	fffff097          	auipc	ra,0xfffff
    800047e0:	f84080e7          	jalr	-124(ra) # 80003760 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800047e4:	4505                	li	a0,1
    800047e6:	00000097          	auipc	ra,0x0
    800047ea:	ebe080e7          	jalr	-322(ra) # 800046a4 <install_trans>
  log.lh.n = 0;
    800047ee:	0001e797          	auipc	a5,0x1e
    800047f2:	fe07ab23          	sw	zero,-10(a5) # 800227e4 <log+0x2c>
  write_head(); // clear the log
    800047f6:	00000097          	auipc	ra,0x0
    800047fa:	e34080e7          	jalr	-460(ra) # 8000462a <write_head>
}
    800047fe:	70a2                	ld	ra,40(sp)
    80004800:	7402                	ld	s0,32(sp)
    80004802:	64e2                	ld	s1,24(sp)
    80004804:	6942                	ld	s2,16(sp)
    80004806:	69a2                	ld	s3,8(sp)
    80004808:	6145                	addi	sp,sp,48
    8000480a:	8082                	ret

000000008000480c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000480c:	1101                	addi	sp,sp,-32
    8000480e:	ec06                	sd	ra,24(sp)
    80004810:	e822                	sd	s0,16(sp)
    80004812:	e426                	sd	s1,8(sp)
    80004814:	e04a                	sd	s2,0(sp)
    80004816:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004818:	0001e517          	auipc	a0,0x1e
    8000481c:	fa050513          	addi	a0,a0,-96 # 800227b8 <log>
    80004820:	ffffc097          	auipc	ra,0xffffc
    80004824:	3ca080e7          	jalr	970(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    80004828:	0001e497          	auipc	s1,0x1e
    8000482c:	f9048493          	addi	s1,s1,-112 # 800227b8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004830:	4979                	li	s2,30
    80004832:	a039                	j	80004840 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004834:	85a6                	mv	a1,s1
    80004836:	8526                	mv	a0,s1
    80004838:	ffffe097          	auipc	ra,0xffffe
    8000483c:	bc0080e7          	jalr	-1088(ra) # 800023f8 <sleep>
    if(log.committing){
    80004840:	50dc                	lw	a5,36(s1)
    80004842:	fbed                	bnez	a5,80004834 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004844:	509c                	lw	a5,32(s1)
    80004846:	0017871b          	addiw	a4,a5,1
    8000484a:	0007069b          	sext.w	a3,a4
    8000484e:	0027179b          	slliw	a5,a4,0x2
    80004852:	9fb9                	addw	a5,a5,a4
    80004854:	0017979b          	slliw	a5,a5,0x1
    80004858:	54d8                	lw	a4,44(s1)
    8000485a:	9fb9                	addw	a5,a5,a4
    8000485c:	00f95963          	bge	s2,a5,8000486e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004860:	85a6                	mv	a1,s1
    80004862:	8526                	mv	a0,s1
    80004864:	ffffe097          	auipc	ra,0xffffe
    80004868:	b94080e7          	jalr	-1132(ra) # 800023f8 <sleep>
    8000486c:	bfd1                	j	80004840 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000486e:	0001e517          	auipc	a0,0x1e
    80004872:	f4a50513          	addi	a0,a0,-182 # 800227b8 <log>
    80004876:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004878:	ffffc097          	auipc	ra,0xffffc
    8000487c:	426080e7          	jalr	1062(ra) # 80000c9e <release>
      break;
    }
  }
}
    80004880:	60e2                	ld	ra,24(sp)
    80004882:	6442                	ld	s0,16(sp)
    80004884:	64a2                	ld	s1,8(sp)
    80004886:	6902                	ld	s2,0(sp)
    80004888:	6105                	addi	sp,sp,32
    8000488a:	8082                	ret

000000008000488c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000488c:	7139                	addi	sp,sp,-64
    8000488e:	fc06                	sd	ra,56(sp)
    80004890:	f822                	sd	s0,48(sp)
    80004892:	f426                	sd	s1,40(sp)
    80004894:	f04a                	sd	s2,32(sp)
    80004896:	ec4e                	sd	s3,24(sp)
    80004898:	e852                	sd	s4,16(sp)
    8000489a:	e456                	sd	s5,8(sp)
    8000489c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000489e:	0001e497          	auipc	s1,0x1e
    800048a2:	f1a48493          	addi	s1,s1,-230 # 800227b8 <log>
    800048a6:	8526                	mv	a0,s1
    800048a8:	ffffc097          	auipc	ra,0xffffc
    800048ac:	342080e7          	jalr	834(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    800048b0:	509c                	lw	a5,32(s1)
    800048b2:	37fd                	addiw	a5,a5,-1
    800048b4:	0007891b          	sext.w	s2,a5
    800048b8:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800048ba:	50dc                	lw	a5,36(s1)
    800048bc:	efb9                	bnez	a5,8000491a <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800048be:	06091663          	bnez	s2,8000492a <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800048c2:	0001e497          	auipc	s1,0x1e
    800048c6:	ef648493          	addi	s1,s1,-266 # 800227b8 <log>
    800048ca:	4785                	li	a5,1
    800048cc:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800048ce:	8526                	mv	a0,s1
    800048d0:	ffffc097          	auipc	ra,0xffffc
    800048d4:	3ce080e7          	jalr	974(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800048d8:	54dc                	lw	a5,44(s1)
    800048da:	06f04763          	bgtz	a5,80004948 <end_op+0xbc>
    acquire(&log.lock);
    800048de:	0001e497          	auipc	s1,0x1e
    800048e2:	eda48493          	addi	s1,s1,-294 # 800227b8 <log>
    800048e6:	8526                	mv	a0,s1
    800048e8:	ffffc097          	auipc	ra,0xffffc
    800048ec:	302080e7          	jalr	770(ra) # 80000bea <acquire>
    log.committing = 0;
    800048f0:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800048f4:	8526                	mv	a0,s1
    800048f6:	ffffe097          	auipc	ra,0xffffe
    800048fa:	caa080e7          	jalr	-854(ra) # 800025a0 <wakeup>
    release(&log.lock);
    800048fe:	8526                	mv	a0,s1
    80004900:	ffffc097          	auipc	ra,0xffffc
    80004904:	39e080e7          	jalr	926(ra) # 80000c9e <release>
}
    80004908:	70e2                	ld	ra,56(sp)
    8000490a:	7442                	ld	s0,48(sp)
    8000490c:	74a2                	ld	s1,40(sp)
    8000490e:	7902                	ld	s2,32(sp)
    80004910:	69e2                	ld	s3,24(sp)
    80004912:	6a42                	ld	s4,16(sp)
    80004914:	6aa2                	ld	s5,8(sp)
    80004916:	6121                	addi	sp,sp,64
    80004918:	8082                	ret
    panic("log.committing");
    8000491a:	00004517          	auipc	a0,0x4
    8000491e:	e4650513          	addi	a0,a0,-442 # 80008760 <syscalls+0x210>
    80004922:	ffffc097          	auipc	ra,0xffffc
    80004926:	c22080e7          	jalr	-990(ra) # 80000544 <panic>
    wakeup(&log);
    8000492a:	0001e497          	auipc	s1,0x1e
    8000492e:	e8e48493          	addi	s1,s1,-370 # 800227b8 <log>
    80004932:	8526                	mv	a0,s1
    80004934:	ffffe097          	auipc	ra,0xffffe
    80004938:	c6c080e7          	jalr	-916(ra) # 800025a0 <wakeup>
  release(&log.lock);
    8000493c:	8526                	mv	a0,s1
    8000493e:	ffffc097          	auipc	ra,0xffffc
    80004942:	360080e7          	jalr	864(ra) # 80000c9e <release>
  if(do_commit){
    80004946:	b7c9                	j	80004908 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004948:	0001ea97          	auipc	s5,0x1e
    8000494c:	ea0a8a93          	addi	s5,s5,-352 # 800227e8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004950:	0001ea17          	auipc	s4,0x1e
    80004954:	e68a0a13          	addi	s4,s4,-408 # 800227b8 <log>
    80004958:	018a2583          	lw	a1,24(s4)
    8000495c:	012585bb          	addw	a1,a1,s2
    80004960:	2585                	addiw	a1,a1,1
    80004962:	028a2503          	lw	a0,40(s4)
    80004966:	fffff097          	auipc	ra,0xfffff
    8000496a:	cca080e7          	jalr	-822(ra) # 80003630 <bread>
    8000496e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004970:	000aa583          	lw	a1,0(s5)
    80004974:	028a2503          	lw	a0,40(s4)
    80004978:	fffff097          	auipc	ra,0xfffff
    8000497c:	cb8080e7          	jalr	-840(ra) # 80003630 <bread>
    80004980:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004982:	40000613          	li	a2,1024
    80004986:	05850593          	addi	a1,a0,88
    8000498a:	05848513          	addi	a0,s1,88
    8000498e:	ffffc097          	auipc	ra,0xffffc
    80004992:	3b8080e7          	jalr	952(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    80004996:	8526                	mv	a0,s1
    80004998:	fffff097          	auipc	ra,0xfffff
    8000499c:	d8a080e7          	jalr	-630(ra) # 80003722 <bwrite>
    brelse(from);
    800049a0:	854e                	mv	a0,s3
    800049a2:	fffff097          	auipc	ra,0xfffff
    800049a6:	dbe080e7          	jalr	-578(ra) # 80003760 <brelse>
    brelse(to);
    800049aa:	8526                	mv	a0,s1
    800049ac:	fffff097          	auipc	ra,0xfffff
    800049b0:	db4080e7          	jalr	-588(ra) # 80003760 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800049b4:	2905                	addiw	s2,s2,1
    800049b6:	0a91                	addi	s5,s5,4
    800049b8:	02ca2783          	lw	a5,44(s4)
    800049bc:	f8f94ee3          	blt	s2,a5,80004958 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800049c0:	00000097          	auipc	ra,0x0
    800049c4:	c6a080e7          	jalr	-918(ra) # 8000462a <write_head>
    install_trans(0); // Now install writes to home locations
    800049c8:	4501                	li	a0,0
    800049ca:	00000097          	auipc	ra,0x0
    800049ce:	cda080e7          	jalr	-806(ra) # 800046a4 <install_trans>
    log.lh.n = 0;
    800049d2:	0001e797          	auipc	a5,0x1e
    800049d6:	e007a923          	sw	zero,-494(a5) # 800227e4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800049da:	00000097          	auipc	ra,0x0
    800049de:	c50080e7          	jalr	-944(ra) # 8000462a <write_head>
    800049e2:	bdf5                	j	800048de <end_op+0x52>

00000000800049e4 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800049e4:	1101                	addi	sp,sp,-32
    800049e6:	ec06                	sd	ra,24(sp)
    800049e8:	e822                	sd	s0,16(sp)
    800049ea:	e426                	sd	s1,8(sp)
    800049ec:	e04a                	sd	s2,0(sp)
    800049ee:	1000                	addi	s0,sp,32
    800049f0:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800049f2:	0001e917          	auipc	s2,0x1e
    800049f6:	dc690913          	addi	s2,s2,-570 # 800227b8 <log>
    800049fa:	854a                	mv	a0,s2
    800049fc:	ffffc097          	auipc	ra,0xffffc
    80004a00:	1ee080e7          	jalr	494(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004a04:	02c92603          	lw	a2,44(s2)
    80004a08:	47f5                	li	a5,29
    80004a0a:	06c7c563          	blt	a5,a2,80004a74 <log_write+0x90>
    80004a0e:	0001e797          	auipc	a5,0x1e
    80004a12:	dc67a783          	lw	a5,-570(a5) # 800227d4 <log+0x1c>
    80004a16:	37fd                	addiw	a5,a5,-1
    80004a18:	04f65e63          	bge	a2,a5,80004a74 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004a1c:	0001e797          	auipc	a5,0x1e
    80004a20:	dbc7a783          	lw	a5,-580(a5) # 800227d8 <log+0x20>
    80004a24:	06f05063          	blez	a5,80004a84 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004a28:	4781                	li	a5,0
    80004a2a:	06c05563          	blez	a2,80004a94 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004a2e:	44cc                	lw	a1,12(s1)
    80004a30:	0001e717          	auipc	a4,0x1e
    80004a34:	db870713          	addi	a4,a4,-584 # 800227e8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004a38:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004a3a:	4314                	lw	a3,0(a4)
    80004a3c:	04b68c63          	beq	a3,a1,80004a94 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004a40:	2785                	addiw	a5,a5,1
    80004a42:	0711                	addi	a4,a4,4
    80004a44:	fef61be3          	bne	a2,a5,80004a3a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004a48:	0621                	addi	a2,a2,8
    80004a4a:	060a                	slli	a2,a2,0x2
    80004a4c:	0001e797          	auipc	a5,0x1e
    80004a50:	d6c78793          	addi	a5,a5,-660 # 800227b8 <log>
    80004a54:	963e                	add	a2,a2,a5
    80004a56:	44dc                	lw	a5,12(s1)
    80004a58:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004a5a:	8526                	mv	a0,s1
    80004a5c:	fffff097          	auipc	ra,0xfffff
    80004a60:	da2080e7          	jalr	-606(ra) # 800037fe <bpin>
    log.lh.n++;
    80004a64:	0001e717          	auipc	a4,0x1e
    80004a68:	d5470713          	addi	a4,a4,-684 # 800227b8 <log>
    80004a6c:	575c                	lw	a5,44(a4)
    80004a6e:	2785                	addiw	a5,a5,1
    80004a70:	d75c                	sw	a5,44(a4)
    80004a72:	a835                	j	80004aae <log_write+0xca>
    panic("too big a transaction");
    80004a74:	00004517          	auipc	a0,0x4
    80004a78:	cfc50513          	addi	a0,a0,-772 # 80008770 <syscalls+0x220>
    80004a7c:	ffffc097          	auipc	ra,0xffffc
    80004a80:	ac8080e7          	jalr	-1336(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    80004a84:	00004517          	auipc	a0,0x4
    80004a88:	d0450513          	addi	a0,a0,-764 # 80008788 <syscalls+0x238>
    80004a8c:	ffffc097          	auipc	ra,0xffffc
    80004a90:	ab8080e7          	jalr	-1352(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    80004a94:	00878713          	addi	a4,a5,8
    80004a98:	00271693          	slli	a3,a4,0x2
    80004a9c:	0001e717          	auipc	a4,0x1e
    80004aa0:	d1c70713          	addi	a4,a4,-740 # 800227b8 <log>
    80004aa4:	9736                	add	a4,a4,a3
    80004aa6:	44d4                	lw	a3,12(s1)
    80004aa8:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004aaa:	faf608e3          	beq	a2,a5,80004a5a <log_write+0x76>
  }
  release(&log.lock);
    80004aae:	0001e517          	auipc	a0,0x1e
    80004ab2:	d0a50513          	addi	a0,a0,-758 # 800227b8 <log>
    80004ab6:	ffffc097          	auipc	ra,0xffffc
    80004aba:	1e8080e7          	jalr	488(ra) # 80000c9e <release>
}
    80004abe:	60e2                	ld	ra,24(sp)
    80004ac0:	6442                	ld	s0,16(sp)
    80004ac2:	64a2                	ld	s1,8(sp)
    80004ac4:	6902                	ld	s2,0(sp)
    80004ac6:	6105                	addi	sp,sp,32
    80004ac8:	8082                	ret

0000000080004aca <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004aca:	1101                	addi	sp,sp,-32
    80004acc:	ec06                	sd	ra,24(sp)
    80004ace:	e822                	sd	s0,16(sp)
    80004ad0:	e426                	sd	s1,8(sp)
    80004ad2:	e04a                	sd	s2,0(sp)
    80004ad4:	1000                	addi	s0,sp,32
    80004ad6:	84aa                	mv	s1,a0
    80004ad8:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004ada:	00004597          	auipc	a1,0x4
    80004ade:	cce58593          	addi	a1,a1,-818 # 800087a8 <syscalls+0x258>
    80004ae2:	0521                	addi	a0,a0,8
    80004ae4:	ffffc097          	auipc	ra,0xffffc
    80004ae8:	076080e7          	jalr	118(ra) # 80000b5a <initlock>
  lk->name = name;
    80004aec:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004af0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004af4:	0204a423          	sw	zero,40(s1)
}
    80004af8:	60e2                	ld	ra,24(sp)
    80004afa:	6442                	ld	s0,16(sp)
    80004afc:	64a2                	ld	s1,8(sp)
    80004afe:	6902                	ld	s2,0(sp)
    80004b00:	6105                	addi	sp,sp,32
    80004b02:	8082                	ret

0000000080004b04 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004b04:	1101                	addi	sp,sp,-32
    80004b06:	ec06                	sd	ra,24(sp)
    80004b08:	e822                	sd	s0,16(sp)
    80004b0a:	e426                	sd	s1,8(sp)
    80004b0c:	e04a                	sd	s2,0(sp)
    80004b0e:	1000                	addi	s0,sp,32
    80004b10:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b12:	00850913          	addi	s2,a0,8
    80004b16:	854a                	mv	a0,s2
    80004b18:	ffffc097          	auipc	ra,0xffffc
    80004b1c:	0d2080e7          	jalr	210(ra) # 80000bea <acquire>
  while (lk->locked) {
    80004b20:	409c                	lw	a5,0(s1)
    80004b22:	cb89                	beqz	a5,80004b34 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004b24:	85ca                	mv	a1,s2
    80004b26:	8526                	mv	a0,s1
    80004b28:	ffffe097          	auipc	ra,0xffffe
    80004b2c:	8d0080e7          	jalr	-1840(ra) # 800023f8 <sleep>
  while (lk->locked) {
    80004b30:	409c                	lw	a5,0(s1)
    80004b32:	fbed                	bnez	a5,80004b24 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004b34:	4785                	li	a5,1
    80004b36:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004b38:	ffffd097          	auipc	ra,0xffffd
    80004b3c:	07c080e7          	jalr	124(ra) # 80001bb4 <myproc>
    80004b40:	591c                	lw	a5,48(a0)
    80004b42:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004b44:	854a                	mv	a0,s2
    80004b46:	ffffc097          	auipc	ra,0xffffc
    80004b4a:	158080e7          	jalr	344(ra) # 80000c9e <release>
}
    80004b4e:	60e2                	ld	ra,24(sp)
    80004b50:	6442                	ld	s0,16(sp)
    80004b52:	64a2                	ld	s1,8(sp)
    80004b54:	6902                	ld	s2,0(sp)
    80004b56:	6105                	addi	sp,sp,32
    80004b58:	8082                	ret

0000000080004b5a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004b5a:	1101                	addi	sp,sp,-32
    80004b5c:	ec06                	sd	ra,24(sp)
    80004b5e:	e822                	sd	s0,16(sp)
    80004b60:	e426                	sd	s1,8(sp)
    80004b62:	e04a                	sd	s2,0(sp)
    80004b64:	1000                	addi	s0,sp,32
    80004b66:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b68:	00850913          	addi	s2,a0,8
    80004b6c:	854a                	mv	a0,s2
    80004b6e:	ffffc097          	auipc	ra,0xffffc
    80004b72:	07c080e7          	jalr	124(ra) # 80000bea <acquire>
  lk->locked = 0;
    80004b76:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b7a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004b7e:	8526                	mv	a0,s1
    80004b80:	ffffe097          	auipc	ra,0xffffe
    80004b84:	a20080e7          	jalr	-1504(ra) # 800025a0 <wakeup>
  release(&lk->lk);
    80004b88:	854a                	mv	a0,s2
    80004b8a:	ffffc097          	auipc	ra,0xffffc
    80004b8e:	114080e7          	jalr	276(ra) # 80000c9e <release>
}
    80004b92:	60e2                	ld	ra,24(sp)
    80004b94:	6442                	ld	s0,16(sp)
    80004b96:	64a2                	ld	s1,8(sp)
    80004b98:	6902                	ld	s2,0(sp)
    80004b9a:	6105                	addi	sp,sp,32
    80004b9c:	8082                	ret

0000000080004b9e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004b9e:	7179                	addi	sp,sp,-48
    80004ba0:	f406                	sd	ra,40(sp)
    80004ba2:	f022                	sd	s0,32(sp)
    80004ba4:	ec26                	sd	s1,24(sp)
    80004ba6:	e84a                	sd	s2,16(sp)
    80004ba8:	e44e                	sd	s3,8(sp)
    80004baa:	1800                	addi	s0,sp,48
    80004bac:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004bae:	00850913          	addi	s2,a0,8
    80004bb2:	854a                	mv	a0,s2
    80004bb4:	ffffc097          	auipc	ra,0xffffc
    80004bb8:	036080e7          	jalr	54(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004bbc:	409c                	lw	a5,0(s1)
    80004bbe:	ef99                	bnez	a5,80004bdc <holdingsleep+0x3e>
    80004bc0:	4481                	li	s1,0
  release(&lk->lk);
    80004bc2:	854a                	mv	a0,s2
    80004bc4:	ffffc097          	auipc	ra,0xffffc
    80004bc8:	0da080e7          	jalr	218(ra) # 80000c9e <release>
  return r;
}
    80004bcc:	8526                	mv	a0,s1
    80004bce:	70a2                	ld	ra,40(sp)
    80004bd0:	7402                	ld	s0,32(sp)
    80004bd2:	64e2                	ld	s1,24(sp)
    80004bd4:	6942                	ld	s2,16(sp)
    80004bd6:	69a2                	ld	s3,8(sp)
    80004bd8:	6145                	addi	sp,sp,48
    80004bda:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004bdc:	0284a983          	lw	s3,40(s1)
    80004be0:	ffffd097          	auipc	ra,0xffffd
    80004be4:	fd4080e7          	jalr	-44(ra) # 80001bb4 <myproc>
    80004be8:	5904                	lw	s1,48(a0)
    80004bea:	413484b3          	sub	s1,s1,s3
    80004bee:	0014b493          	seqz	s1,s1
    80004bf2:	bfc1                	j	80004bc2 <holdingsleep+0x24>

0000000080004bf4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004bf4:	1141                	addi	sp,sp,-16
    80004bf6:	e406                	sd	ra,8(sp)
    80004bf8:	e022                	sd	s0,0(sp)
    80004bfa:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004bfc:	00004597          	auipc	a1,0x4
    80004c00:	bbc58593          	addi	a1,a1,-1092 # 800087b8 <syscalls+0x268>
    80004c04:	0001e517          	auipc	a0,0x1e
    80004c08:	cfc50513          	addi	a0,a0,-772 # 80022900 <ftable>
    80004c0c:	ffffc097          	auipc	ra,0xffffc
    80004c10:	f4e080e7          	jalr	-178(ra) # 80000b5a <initlock>
}
    80004c14:	60a2                	ld	ra,8(sp)
    80004c16:	6402                	ld	s0,0(sp)
    80004c18:	0141                	addi	sp,sp,16
    80004c1a:	8082                	ret

0000000080004c1c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004c1c:	1101                	addi	sp,sp,-32
    80004c1e:	ec06                	sd	ra,24(sp)
    80004c20:	e822                	sd	s0,16(sp)
    80004c22:	e426                	sd	s1,8(sp)
    80004c24:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004c26:	0001e517          	auipc	a0,0x1e
    80004c2a:	cda50513          	addi	a0,a0,-806 # 80022900 <ftable>
    80004c2e:	ffffc097          	auipc	ra,0xffffc
    80004c32:	fbc080e7          	jalr	-68(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c36:	0001e497          	auipc	s1,0x1e
    80004c3a:	ce248493          	addi	s1,s1,-798 # 80022918 <ftable+0x18>
    80004c3e:	0001f717          	auipc	a4,0x1f
    80004c42:	c7a70713          	addi	a4,a4,-902 # 800238b8 <disk>
    if(f->ref == 0){
    80004c46:	40dc                	lw	a5,4(s1)
    80004c48:	cf99                	beqz	a5,80004c66 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c4a:	02848493          	addi	s1,s1,40
    80004c4e:	fee49ce3          	bne	s1,a4,80004c46 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004c52:	0001e517          	auipc	a0,0x1e
    80004c56:	cae50513          	addi	a0,a0,-850 # 80022900 <ftable>
    80004c5a:	ffffc097          	auipc	ra,0xffffc
    80004c5e:	044080e7          	jalr	68(ra) # 80000c9e <release>
  return 0;
    80004c62:	4481                	li	s1,0
    80004c64:	a819                	j	80004c7a <filealloc+0x5e>
      f->ref = 1;
    80004c66:	4785                	li	a5,1
    80004c68:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004c6a:	0001e517          	auipc	a0,0x1e
    80004c6e:	c9650513          	addi	a0,a0,-874 # 80022900 <ftable>
    80004c72:	ffffc097          	auipc	ra,0xffffc
    80004c76:	02c080e7          	jalr	44(ra) # 80000c9e <release>
}
    80004c7a:	8526                	mv	a0,s1
    80004c7c:	60e2                	ld	ra,24(sp)
    80004c7e:	6442                	ld	s0,16(sp)
    80004c80:	64a2                	ld	s1,8(sp)
    80004c82:	6105                	addi	sp,sp,32
    80004c84:	8082                	ret

0000000080004c86 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004c86:	1101                	addi	sp,sp,-32
    80004c88:	ec06                	sd	ra,24(sp)
    80004c8a:	e822                	sd	s0,16(sp)
    80004c8c:	e426                	sd	s1,8(sp)
    80004c8e:	1000                	addi	s0,sp,32
    80004c90:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004c92:	0001e517          	auipc	a0,0x1e
    80004c96:	c6e50513          	addi	a0,a0,-914 # 80022900 <ftable>
    80004c9a:	ffffc097          	auipc	ra,0xffffc
    80004c9e:	f50080e7          	jalr	-176(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004ca2:	40dc                	lw	a5,4(s1)
    80004ca4:	02f05263          	blez	a5,80004cc8 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004ca8:	2785                	addiw	a5,a5,1
    80004caa:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004cac:	0001e517          	auipc	a0,0x1e
    80004cb0:	c5450513          	addi	a0,a0,-940 # 80022900 <ftable>
    80004cb4:	ffffc097          	auipc	ra,0xffffc
    80004cb8:	fea080e7          	jalr	-22(ra) # 80000c9e <release>
  return f;
}
    80004cbc:	8526                	mv	a0,s1
    80004cbe:	60e2                	ld	ra,24(sp)
    80004cc0:	6442                	ld	s0,16(sp)
    80004cc2:	64a2                	ld	s1,8(sp)
    80004cc4:	6105                	addi	sp,sp,32
    80004cc6:	8082                	ret
    panic("filedup");
    80004cc8:	00004517          	auipc	a0,0x4
    80004ccc:	af850513          	addi	a0,a0,-1288 # 800087c0 <syscalls+0x270>
    80004cd0:	ffffc097          	auipc	ra,0xffffc
    80004cd4:	874080e7          	jalr	-1932(ra) # 80000544 <panic>

0000000080004cd8 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004cd8:	7139                	addi	sp,sp,-64
    80004cda:	fc06                	sd	ra,56(sp)
    80004cdc:	f822                	sd	s0,48(sp)
    80004cde:	f426                	sd	s1,40(sp)
    80004ce0:	f04a                	sd	s2,32(sp)
    80004ce2:	ec4e                	sd	s3,24(sp)
    80004ce4:	e852                	sd	s4,16(sp)
    80004ce6:	e456                	sd	s5,8(sp)
    80004ce8:	0080                	addi	s0,sp,64
    80004cea:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004cec:	0001e517          	auipc	a0,0x1e
    80004cf0:	c1450513          	addi	a0,a0,-1004 # 80022900 <ftable>
    80004cf4:	ffffc097          	auipc	ra,0xffffc
    80004cf8:	ef6080e7          	jalr	-266(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004cfc:	40dc                	lw	a5,4(s1)
    80004cfe:	06f05163          	blez	a5,80004d60 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004d02:	37fd                	addiw	a5,a5,-1
    80004d04:	0007871b          	sext.w	a4,a5
    80004d08:	c0dc                	sw	a5,4(s1)
    80004d0a:	06e04363          	bgtz	a4,80004d70 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004d0e:	0004a903          	lw	s2,0(s1)
    80004d12:	0094ca83          	lbu	s5,9(s1)
    80004d16:	0104ba03          	ld	s4,16(s1)
    80004d1a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004d1e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004d22:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004d26:	0001e517          	auipc	a0,0x1e
    80004d2a:	bda50513          	addi	a0,a0,-1062 # 80022900 <ftable>
    80004d2e:	ffffc097          	auipc	ra,0xffffc
    80004d32:	f70080e7          	jalr	-144(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    80004d36:	4785                	li	a5,1
    80004d38:	04f90d63          	beq	s2,a5,80004d92 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004d3c:	3979                	addiw	s2,s2,-2
    80004d3e:	4785                	li	a5,1
    80004d40:	0527e063          	bltu	a5,s2,80004d80 <fileclose+0xa8>
    begin_op();
    80004d44:	00000097          	auipc	ra,0x0
    80004d48:	ac8080e7          	jalr	-1336(ra) # 8000480c <begin_op>
    iput(ff.ip);
    80004d4c:	854e                	mv	a0,s3
    80004d4e:	fffff097          	auipc	ra,0xfffff
    80004d52:	2b6080e7          	jalr	694(ra) # 80004004 <iput>
    end_op();
    80004d56:	00000097          	auipc	ra,0x0
    80004d5a:	b36080e7          	jalr	-1226(ra) # 8000488c <end_op>
    80004d5e:	a00d                	j	80004d80 <fileclose+0xa8>
    panic("fileclose");
    80004d60:	00004517          	auipc	a0,0x4
    80004d64:	a6850513          	addi	a0,a0,-1432 # 800087c8 <syscalls+0x278>
    80004d68:	ffffb097          	auipc	ra,0xffffb
    80004d6c:	7dc080e7          	jalr	2012(ra) # 80000544 <panic>
    release(&ftable.lock);
    80004d70:	0001e517          	auipc	a0,0x1e
    80004d74:	b9050513          	addi	a0,a0,-1136 # 80022900 <ftable>
    80004d78:	ffffc097          	auipc	ra,0xffffc
    80004d7c:	f26080e7          	jalr	-218(ra) # 80000c9e <release>
  }
}
    80004d80:	70e2                	ld	ra,56(sp)
    80004d82:	7442                	ld	s0,48(sp)
    80004d84:	74a2                	ld	s1,40(sp)
    80004d86:	7902                	ld	s2,32(sp)
    80004d88:	69e2                	ld	s3,24(sp)
    80004d8a:	6a42                	ld	s4,16(sp)
    80004d8c:	6aa2                	ld	s5,8(sp)
    80004d8e:	6121                	addi	sp,sp,64
    80004d90:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004d92:	85d6                	mv	a1,s5
    80004d94:	8552                	mv	a0,s4
    80004d96:	00000097          	auipc	ra,0x0
    80004d9a:	34c080e7          	jalr	844(ra) # 800050e2 <pipeclose>
    80004d9e:	b7cd                	j	80004d80 <fileclose+0xa8>

0000000080004da0 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004da0:	715d                	addi	sp,sp,-80
    80004da2:	e486                	sd	ra,72(sp)
    80004da4:	e0a2                	sd	s0,64(sp)
    80004da6:	fc26                	sd	s1,56(sp)
    80004da8:	f84a                	sd	s2,48(sp)
    80004daa:	f44e                	sd	s3,40(sp)
    80004dac:	0880                	addi	s0,sp,80
    80004dae:	84aa                	mv	s1,a0
    80004db0:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004db2:	ffffd097          	auipc	ra,0xffffd
    80004db6:	e02080e7          	jalr	-510(ra) # 80001bb4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004dba:	409c                	lw	a5,0(s1)
    80004dbc:	37f9                	addiw	a5,a5,-2
    80004dbe:	4705                	li	a4,1
    80004dc0:	04f76763          	bltu	a4,a5,80004e0e <filestat+0x6e>
    80004dc4:	892a                	mv	s2,a0
    ilock(f->ip);
    80004dc6:	6c88                	ld	a0,24(s1)
    80004dc8:	fffff097          	auipc	ra,0xfffff
    80004dcc:	082080e7          	jalr	130(ra) # 80003e4a <ilock>
    stati(f->ip, &st);
    80004dd0:	fb840593          	addi	a1,s0,-72
    80004dd4:	6c88                	ld	a0,24(s1)
    80004dd6:	fffff097          	auipc	ra,0xfffff
    80004dda:	2fe080e7          	jalr	766(ra) # 800040d4 <stati>
    iunlock(f->ip);
    80004dde:	6c88                	ld	a0,24(s1)
    80004de0:	fffff097          	auipc	ra,0xfffff
    80004de4:	12c080e7          	jalr	300(ra) # 80003f0c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004de8:	46e1                	li	a3,24
    80004dea:	fb840613          	addi	a2,s0,-72
    80004dee:	85ce                	mv	a1,s3
    80004df0:	05093503          	ld	a0,80(s2)
    80004df4:	ffffd097          	auipc	ra,0xffffd
    80004df8:	890080e7          	jalr	-1904(ra) # 80001684 <copyout>
    80004dfc:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004e00:	60a6                	ld	ra,72(sp)
    80004e02:	6406                	ld	s0,64(sp)
    80004e04:	74e2                	ld	s1,56(sp)
    80004e06:	7942                	ld	s2,48(sp)
    80004e08:	79a2                	ld	s3,40(sp)
    80004e0a:	6161                	addi	sp,sp,80
    80004e0c:	8082                	ret
  return -1;
    80004e0e:	557d                	li	a0,-1
    80004e10:	bfc5                	j	80004e00 <filestat+0x60>

0000000080004e12 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004e12:	7179                	addi	sp,sp,-48
    80004e14:	f406                	sd	ra,40(sp)
    80004e16:	f022                	sd	s0,32(sp)
    80004e18:	ec26                	sd	s1,24(sp)
    80004e1a:	e84a                	sd	s2,16(sp)
    80004e1c:	e44e                	sd	s3,8(sp)
    80004e1e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004e20:	00854783          	lbu	a5,8(a0)
    80004e24:	c3d5                	beqz	a5,80004ec8 <fileread+0xb6>
    80004e26:	84aa                	mv	s1,a0
    80004e28:	89ae                	mv	s3,a1
    80004e2a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e2c:	411c                	lw	a5,0(a0)
    80004e2e:	4705                	li	a4,1
    80004e30:	04e78963          	beq	a5,a4,80004e82 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e34:	470d                	li	a4,3
    80004e36:	04e78d63          	beq	a5,a4,80004e90 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e3a:	4709                	li	a4,2
    80004e3c:	06e79e63          	bne	a5,a4,80004eb8 <fileread+0xa6>
    ilock(f->ip);
    80004e40:	6d08                	ld	a0,24(a0)
    80004e42:	fffff097          	auipc	ra,0xfffff
    80004e46:	008080e7          	jalr	8(ra) # 80003e4a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004e4a:	874a                	mv	a4,s2
    80004e4c:	5094                	lw	a3,32(s1)
    80004e4e:	864e                	mv	a2,s3
    80004e50:	4585                	li	a1,1
    80004e52:	6c88                	ld	a0,24(s1)
    80004e54:	fffff097          	auipc	ra,0xfffff
    80004e58:	2aa080e7          	jalr	682(ra) # 800040fe <readi>
    80004e5c:	892a                	mv	s2,a0
    80004e5e:	00a05563          	blez	a0,80004e68 <fileread+0x56>
      f->off += r;
    80004e62:	509c                	lw	a5,32(s1)
    80004e64:	9fa9                	addw	a5,a5,a0
    80004e66:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004e68:	6c88                	ld	a0,24(s1)
    80004e6a:	fffff097          	auipc	ra,0xfffff
    80004e6e:	0a2080e7          	jalr	162(ra) # 80003f0c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004e72:	854a                	mv	a0,s2
    80004e74:	70a2                	ld	ra,40(sp)
    80004e76:	7402                	ld	s0,32(sp)
    80004e78:	64e2                	ld	s1,24(sp)
    80004e7a:	6942                	ld	s2,16(sp)
    80004e7c:	69a2                	ld	s3,8(sp)
    80004e7e:	6145                	addi	sp,sp,48
    80004e80:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004e82:	6908                	ld	a0,16(a0)
    80004e84:	00000097          	auipc	ra,0x0
    80004e88:	3ce080e7          	jalr	974(ra) # 80005252 <piperead>
    80004e8c:	892a                	mv	s2,a0
    80004e8e:	b7d5                	j	80004e72 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004e90:	02451783          	lh	a5,36(a0)
    80004e94:	03079693          	slli	a3,a5,0x30
    80004e98:	92c1                	srli	a3,a3,0x30
    80004e9a:	4725                	li	a4,9
    80004e9c:	02d76863          	bltu	a4,a3,80004ecc <fileread+0xba>
    80004ea0:	0792                	slli	a5,a5,0x4
    80004ea2:	0001e717          	auipc	a4,0x1e
    80004ea6:	9be70713          	addi	a4,a4,-1602 # 80022860 <devsw>
    80004eaa:	97ba                	add	a5,a5,a4
    80004eac:	639c                	ld	a5,0(a5)
    80004eae:	c38d                	beqz	a5,80004ed0 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004eb0:	4505                	li	a0,1
    80004eb2:	9782                	jalr	a5
    80004eb4:	892a                	mv	s2,a0
    80004eb6:	bf75                	j	80004e72 <fileread+0x60>
    panic("fileread");
    80004eb8:	00004517          	auipc	a0,0x4
    80004ebc:	92050513          	addi	a0,a0,-1760 # 800087d8 <syscalls+0x288>
    80004ec0:	ffffb097          	auipc	ra,0xffffb
    80004ec4:	684080e7          	jalr	1668(ra) # 80000544 <panic>
    return -1;
    80004ec8:	597d                	li	s2,-1
    80004eca:	b765                	j	80004e72 <fileread+0x60>
      return -1;
    80004ecc:	597d                	li	s2,-1
    80004ece:	b755                	j	80004e72 <fileread+0x60>
    80004ed0:	597d                	li	s2,-1
    80004ed2:	b745                	j	80004e72 <fileread+0x60>

0000000080004ed4 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004ed4:	715d                	addi	sp,sp,-80
    80004ed6:	e486                	sd	ra,72(sp)
    80004ed8:	e0a2                	sd	s0,64(sp)
    80004eda:	fc26                	sd	s1,56(sp)
    80004edc:	f84a                	sd	s2,48(sp)
    80004ede:	f44e                	sd	s3,40(sp)
    80004ee0:	f052                	sd	s4,32(sp)
    80004ee2:	ec56                	sd	s5,24(sp)
    80004ee4:	e85a                	sd	s6,16(sp)
    80004ee6:	e45e                	sd	s7,8(sp)
    80004ee8:	e062                	sd	s8,0(sp)
    80004eea:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004eec:	00954783          	lbu	a5,9(a0)
    80004ef0:	10078663          	beqz	a5,80004ffc <filewrite+0x128>
    80004ef4:	892a                	mv	s2,a0
    80004ef6:	8aae                	mv	s5,a1
    80004ef8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004efa:	411c                	lw	a5,0(a0)
    80004efc:	4705                	li	a4,1
    80004efe:	02e78263          	beq	a5,a4,80004f22 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004f02:	470d                	li	a4,3
    80004f04:	02e78663          	beq	a5,a4,80004f30 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004f08:	4709                	li	a4,2
    80004f0a:	0ee79163          	bne	a5,a4,80004fec <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004f0e:	0ac05d63          	blez	a2,80004fc8 <filewrite+0xf4>
    int i = 0;
    80004f12:	4981                	li	s3,0
    80004f14:	6b05                	lui	s6,0x1
    80004f16:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004f1a:	6b85                	lui	s7,0x1
    80004f1c:	c00b8b9b          	addiw	s7,s7,-1024
    80004f20:	a861                	j	80004fb8 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004f22:	6908                	ld	a0,16(a0)
    80004f24:	00000097          	auipc	ra,0x0
    80004f28:	22e080e7          	jalr	558(ra) # 80005152 <pipewrite>
    80004f2c:	8a2a                	mv	s4,a0
    80004f2e:	a045                	j	80004fce <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004f30:	02451783          	lh	a5,36(a0)
    80004f34:	03079693          	slli	a3,a5,0x30
    80004f38:	92c1                	srli	a3,a3,0x30
    80004f3a:	4725                	li	a4,9
    80004f3c:	0cd76263          	bltu	a4,a3,80005000 <filewrite+0x12c>
    80004f40:	0792                	slli	a5,a5,0x4
    80004f42:	0001e717          	auipc	a4,0x1e
    80004f46:	91e70713          	addi	a4,a4,-1762 # 80022860 <devsw>
    80004f4a:	97ba                	add	a5,a5,a4
    80004f4c:	679c                	ld	a5,8(a5)
    80004f4e:	cbdd                	beqz	a5,80005004 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004f50:	4505                	li	a0,1
    80004f52:	9782                	jalr	a5
    80004f54:	8a2a                	mv	s4,a0
    80004f56:	a8a5                	j	80004fce <filewrite+0xfa>
    80004f58:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004f5c:	00000097          	auipc	ra,0x0
    80004f60:	8b0080e7          	jalr	-1872(ra) # 8000480c <begin_op>
      ilock(f->ip);
    80004f64:	01893503          	ld	a0,24(s2)
    80004f68:	fffff097          	auipc	ra,0xfffff
    80004f6c:	ee2080e7          	jalr	-286(ra) # 80003e4a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004f70:	8762                	mv	a4,s8
    80004f72:	02092683          	lw	a3,32(s2)
    80004f76:	01598633          	add	a2,s3,s5
    80004f7a:	4585                	li	a1,1
    80004f7c:	01893503          	ld	a0,24(s2)
    80004f80:	fffff097          	auipc	ra,0xfffff
    80004f84:	276080e7          	jalr	630(ra) # 800041f6 <writei>
    80004f88:	84aa                	mv	s1,a0
    80004f8a:	00a05763          	blez	a0,80004f98 <filewrite+0xc4>
        f->off += r;
    80004f8e:	02092783          	lw	a5,32(s2)
    80004f92:	9fa9                	addw	a5,a5,a0
    80004f94:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004f98:	01893503          	ld	a0,24(s2)
    80004f9c:	fffff097          	auipc	ra,0xfffff
    80004fa0:	f70080e7          	jalr	-144(ra) # 80003f0c <iunlock>
      end_op();
    80004fa4:	00000097          	auipc	ra,0x0
    80004fa8:	8e8080e7          	jalr	-1816(ra) # 8000488c <end_op>

      if(r != n1){
    80004fac:	009c1f63          	bne	s8,s1,80004fca <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004fb0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004fb4:	0149db63          	bge	s3,s4,80004fca <filewrite+0xf6>
      int n1 = n - i;
    80004fb8:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004fbc:	84be                	mv	s1,a5
    80004fbe:	2781                	sext.w	a5,a5
    80004fc0:	f8fb5ce3          	bge	s6,a5,80004f58 <filewrite+0x84>
    80004fc4:	84de                	mv	s1,s7
    80004fc6:	bf49                	j	80004f58 <filewrite+0x84>
    int i = 0;
    80004fc8:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004fca:	013a1f63          	bne	s4,s3,80004fe8 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004fce:	8552                	mv	a0,s4
    80004fd0:	60a6                	ld	ra,72(sp)
    80004fd2:	6406                	ld	s0,64(sp)
    80004fd4:	74e2                	ld	s1,56(sp)
    80004fd6:	7942                	ld	s2,48(sp)
    80004fd8:	79a2                	ld	s3,40(sp)
    80004fda:	7a02                	ld	s4,32(sp)
    80004fdc:	6ae2                	ld	s5,24(sp)
    80004fde:	6b42                	ld	s6,16(sp)
    80004fe0:	6ba2                	ld	s7,8(sp)
    80004fe2:	6c02                	ld	s8,0(sp)
    80004fe4:	6161                	addi	sp,sp,80
    80004fe6:	8082                	ret
    ret = (i == n ? n : -1);
    80004fe8:	5a7d                	li	s4,-1
    80004fea:	b7d5                	j	80004fce <filewrite+0xfa>
    panic("filewrite");
    80004fec:	00003517          	auipc	a0,0x3
    80004ff0:	7fc50513          	addi	a0,a0,2044 # 800087e8 <syscalls+0x298>
    80004ff4:	ffffb097          	auipc	ra,0xffffb
    80004ff8:	550080e7          	jalr	1360(ra) # 80000544 <panic>
    return -1;
    80004ffc:	5a7d                	li	s4,-1
    80004ffe:	bfc1                	j	80004fce <filewrite+0xfa>
      return -1;
    80005000:	5a7d                	li	s4,-1
    80005002:	b7f1                	j	80004fce <filewrite+0xfa>
    80005004:	5a7d                	li	s4,-1
    80005006:	b7e1                	j	80004fce <filewrite+0xfa>

0000000080005008 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005008:	7179                	addi	sp,sp,-48
    8000500a:	f406                	sd	ra,40(sp)
    8000500c:	f022                	sd	s0,32(sp)
    8000500e:	ec26                	sd	s1,24(sp)
    80005010:	e84a                	sd	s2,16(sp)
    80005012:	e44e                	sd	s3,8(sp)
    80005014:	e052                	sd	s4,0(sp)
    80005016:	1800                	addi	s0,sp,48
    80005018:	84aa                	mv	s1,a0
    8000501a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000501c:	0005b023          	sd	zero,0(a1)
    80005020:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005024:	00000097          	auipc	ra,0x0
    80005028:	bf8080e7          	jalr	-1032(ra) # 80004c1c <filealloc>
    8000502c:	e088                	sd	a0,0(s1)
    8000502e:	c551                	beqz	a0,800050ba <pipealloc+0xb2>
    80005030:	00000097          	auipc	ra,0x0
    80005034:	bec080e7          	jalr	-1044(ra) # 80004c1c <filealloc>
    80005038:	00aa3023          	sd	a0,0(s4)
    8000503c:	c92d                	beqz	a0,800050ae <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000503e:	ffffc097          	auipc	ra,0xffffc
    80005042:	abc080e7          	jalr	-1348(ra) # 80000afa <kalloc>
    80005046:	892a                	mv	s2,a0
    80005048:	c125                	beqz	a0,800050a8 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000504a:	4985                	li	s3,1
    8000504c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005050:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005054:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005058:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000505c:	00003597          	auipc	a1,0x3
    80005060:	42c58593          	addi	a1,a1,1068 # 80008488 <states.1800+0x1a0>
    80005064:	ffffc097          	auipc	ra,0xffffc
    80005068:	af6080e7          	jalr	-1290(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    8000506c:	609c                	ld	a5,0(s1)
    8000506e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005072:	609c                	ld	a5,0(s1)
    80005074:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005078:	609c                	ld	a5,0(s1)
    8000507a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000507e:	609c                	ld	a5,0(s1)
    80005080:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005084:	000a3783          	ld	a5,0(s4)
    80005088:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000508c:	000a3783          	ld	a5,0(s4)
    80005090:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005094:	000a3783          	ld	a5,0(s4)
    80005098:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000509c:	000a3783          	ld	a5,0(s4)
    800050a0:	0127b823          	sd	s2,16(a5)
  return 0;
    800050a4:	4501                	li	a0,0
    800050a6:	a025                	j	800050ce <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800050a8:	6088                	ld	a0,0(s1)
    800050aa:	e501                	bnez	a0,800050b2 <pipealloc+0xaa>
    800050ac:	a039                	j	800050ba <pipealloc+0xb2>
    800050ae:	6088                	ld	a0,0(s1)
    800050b0:	c51d                	beqz	a0,800050de <pipealloc+0xd6>
    fileclose(*f0);
    800050b2:	00000097          	auipc	ra,0x0
    800050b6:	c26080e7          	jalr	-986(ra) # 80004cd8 <fileclose>
  if(*f1)
    800050ba:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800050be:	557d                	li	a0,-1
  if(*f1)
    800050c0:	c799                	beqz	a5,800050ce <pipealloc+0xc6>
    fileclose(*f1);
    800050c2:	853e                	mv	a0,a5
    800050c4:	00000097          	auipc	ra,0x0
    800050c8:	c14080e7          	jalr	-1004(ra) # 80004cd8 <fileclose>
  return -1;
    800050cc:	557d                	li	a0,-1
}
    800050ce:	70a2                	ld	ra,40(sp)
    800050d0:	7402                	ld	s0,32(sp)
    800050d2:	64e2                	ld	s1,24(sp)
    800050d4:	6942                	ld	s2,16(sp)
    800050d6:	69a2                	ld	s3,8(sp)
    800050d8:	6a02                	ld	s4,0(sp)
    800050da:	6145                	addi	sp,sp,48
    800050dc:	8082                	ret
  return -1;
    800050de:	557d                	li	a0,-1
    800050e0:	b7fd                	j	800050ce <pipealloc+0xc6>

00000000800050e2 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800050e2:	1101                	addi	sp,sp,-32
    800050e4:	ec06                	sd	ra,24(sp)
    800050e6:	e822                	sd	s0,16(sp)
    800050e8:	e426                	sd	s1,8(sp)
    800050ea:	e04a                	sd	s2,0(sp)
    800050ec:	1000                	addi	s0,sp,32
    800050ee:	84aa                	mv	s1,a0
    800050f0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800050f2:	ffffc097          	auipc	ra,0xffffc
    800050f6:	af8080e7          	jalr	-1288(ra) # 80000bea <acquire>
  if(writable){
    800050fa:	02090d63          	beqz	s2,80005134 <pipeclose+0x52>
    pi->writeopen = 0;
    800050fe:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005102:	21848513          	addi	a0,s1,536
    80005106:	ffffd097          	auipc	ra,0xffffd
    8000510a:	49a080e7          	jalr	1178(ra) # 800025a0 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000510e:	2204b783          	ld	a5,544(s1)
    80005112:	eb95                	bnez	a5,80005146 <pipeclose+0x64>
    release(&pi->lock);
    80005114:	8526                	mv	a0,s1
    80005116:	ffffc097          	auipc	ra,0xffffc
    8000511a:	b88080e7          	jalr	-1144(ra) # 80000c9e <release>
    kfree((char*)pi);
    8000511e:	8526                	mv	a0,s1
    80005120:	ffffc097          	auipc	ra,0xffffc
    80005124:	8de080e7          	jalr	-1826(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80005128:	60e2                	ld	ra,24(sp)
    8000512a:	6442                	ld	s0,16(sp)
    8000512c:	64a2                	ld	s1,8(sp)
    8000512e:	6902                	ld	s2,0(sp)
    80005130:	6105                	addi	sp,sp,32
    80005132:	8082                	ret
    pi->readopen = 0;
    80005134:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005138:	21c48513          	addi	a0,s1,540
    8000513c:	ffffd097          	auipc	ra,0xffffd
    80005140:	464080e7          	jalr	1124(ra) # 800025a0 <wakeup>
    80005144:	b7e9                	j	8000510e <pipeclose+0x2c>
    release(&pi->lock);
    80005146:	8526                	mv	a0,s1
    80005148:	ffffc097          	auipc	ra,0xffffc
    8000514c:	b56080e7          	jalr	-1194(ra) # 80000c9e <release>
}
    80005150:	bfe1                	j	80005128 <pipeclose+0x46>

0000000080005152 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005152:	7159                	addi	sp,sp,-112
    80005154:	f486                	sd	ra,104(sp)
    80005156:	f0a2                	sd	s0,96(sp)
    80005158:	eca6                	sd	s1,88(sp)
    8000515a:	e8ca                	sd	s2,80(sp)
    8000515c:	e4ce                	sd	s3,72(sp)
    8000515e:	e0d2                	sd	s4,64(sp)
    80005160:	fc56                	sd	s5,56(sp)
    80005162:	f85a                	sd	s6,48(sp)
    80005164:	f45e                	sd	s7,40(sp)
    80005166:	f062                	sd	s8,32(sp)
    80005168:	ec66                	sd	s9,24(sp)
    8000516a:	1880                	addi	s0,sp,112
    8000516c:	84aa                	mv	s1,a0
    8000516e:	8aae                	mv	s5,a1
    80005170:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005172:	ffffd097          	auipc	ra,0xffffd
    80005176:	a42080e7          	jalr	-1470(ra) # 80001bb4 <myproc>
    8000517a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000517c:	8526                	mv	a0,s1
    8000517e:	ffffc097          	auipc	ra,0xffffc
    80005182:	a6c080e7          	jalr	-1428(ra) # 80000bea <acquire>
  while(i < n){
    80005186:	0d405463          	blez	s4,8000524e <pipewrite+0xfc>
    8000518a:	8ba6                	mv	s7,s1
  int i = 0;
    8000518c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000518e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005190:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005194:	21c48c13          	addi	s8,s1,540
    80005198:	a08d                	j	800051fa <pipewrite+0xa8>
      release(&pi->lock);
    8000519a:	8526                	mv	a0,s1
    8000519c:	ffffc097          	auipc	ra,0xffffc
    800051a0:	b02080e7          	jalr	-1278(ra) # 80000c9e <release>
      return -1;
    800051a4:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800051a6:	854a                	mv	a0,s2
    800051a8:	70a6                	ld	ra,104(sp)
    800051aa:	7406                	ld	s0,96(sp)
    800051ac:	64e6                	ld	s1,88(sp)
    800051ae:	6946                	ld	s2,80(sp)
    800051b0:	69a6                	ld	s3,72(sp)
    800051b2:	6a06                	ld	s4,64(sp)
    800051b4:	7ae2                	ld	s5,56(sp)
    800051b6:	7b42                	ld	s6,48(sp)
    800051b8:	7ba2                	ld	s7,40(sp)
    800051ba:	7c02                	ld	s8,32(sp)
    800051bc:	6ce2                	ld	s9,24(sp)
    800051be:	6165                	addi	sp,sp,112
    800051c0:	8082                	ret
      wakeup(&pi->nread);
    800051c2:	8566                	mv	a0,s9
    800051c4:	ffffd097          	auipc	ra,0xffffd
    800051c8:	3dc080e7          	jalr	988(ra) # 800025a0 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800051cc:	85de                	mv	a1,s7
    800051ce:	8562                	mv	a0,s8
    800051d0:	ffffd097          	auipc	ra,0xffffd
    800051d4:	228080e7          	jalr	552(ra) # 800023f8 <sleep>
    800051d8:	a839                	j	800051f6 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800051da:	21c4a783          	lw	a5,540(s1)
    800051de:	0017871b          	addiw	a4,a5,1
    800051e2:	20e4ae23          	sw	a4,540(s1)
    800051e6:	1ff7f793          	andi	a5,a5,511
    800051ea:	97a6                	add	a5,a5,s1
    800051ec:	f9f44703          	lbu	a4,-97(s0)
    800051f0:	00e78c23          	sb	a4,24(a5)
      i++;
    800051f4:	2905                	addiw	s2,s2,1
  while(i < n){
    800051f6:	05495063          	bge	s2,s4,80005236 <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    800051fa:	2204a783          	lw	a5,544(s1)
    800051fe:	dfd1                	beqz	a5,8000519a <pipewrite+0x48>
    80005200:	854e                	mv	a0,s3
    80005202:	ffffd097          	auipc	ra,0xffffd
    80005206:	5ee080e7          	jalr	1518(ra) # 800027f0 <killed>
    8000520a:	f941                	bnez	a0,8000519a <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000520c:	2184a783          	lw	a5,536(s1)
    80005210:	21c4a703          	lw	a4,540(s1)
    80005214:	2007879b          	addiw	a5,a5,512
    80005218:	faf705e3          	beq	a4,a5,800051c2 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000521c:	4685                	li	a3,1
    8000521e:	01590633          	add	a2,s2,s5
    80005222:	f9f40593          	addi	a1,s0,-97
    80005226:	0509b503          	ld	a0,80(s3)
    8000522a:	ffffc097          	auipc	ra,0xffffc
    8000522e:	4e6080e7          	jalr	1254(ra) # 80001710 <copyin>
    80005232:	fb6514e3          	bne	a0,s6,800051da <pipewrite+0x88>
  wakeup(&pi->nread);
    80005236:	21848513          	addi	a0,s1,536
    8000523a:	ffffd097          	auipc	ra,0xffffd
    8000523e:	366080e7          	jalr	870(ra) # 800025a0 <wakeup>
  release(&pi->lock);
    80005242:	8526                	mv	a0,s1
    80005244:	ffffc097          	auipc	ra,0xffffc
    80005248:	a5a080e7          	jalr	-1446(ra) # 80000c9e <release>
  return i;
    8000524c:	bfa9                	j	800051a6 <pipewrite+0x54>
  int i = 0;
    8000524e:	4901                	li	s2,0
    80005250:	b7dd                	j	80005236 <pipewrite+0xe4>

0000000080005252 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005252:	715d                	addi	sp,sp,-80
    80005254:	e486                	sd	ra,72(sp)
    80005256:	e0a2                	sd	s0,64(sp)
    80005258:	fc26                	sd	s1,56(sp)
    8000525a:	f84a                	sd	s2,48(sp)
    8000525c:	f44e                	sd	s3,40(sp)
    8000525e:	f052                	sd	s4,32(sp)
    80005260:	ec56                	sd	s5,24(sp)
    80005262:	e85a                	sd	s6,16(sp)
    80005264:	0880                	addi	s0,sp,80
    80005266:	84aa                	mv	s1,a0
    80005268:	892e                	mv	s2,a1
    8000526a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000526c:	ffffd097          	auipc	ra,0xffffd
    80005270:	948080e7          	jalr	-1720(ra) # 80001bb4 <myproc>
    80005274:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005276:	8b26                	mv	s6,s1
    80005278:	8526                	mv	a0,s1
    8000527a:	ffffc097          	auipc	ra,0xffffc
    8000527e:	970080e7          	jalr	-1680(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005282:	2184a703          	lw	a4,536(s1)
    80005286:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000528a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000528e:	02f71763          	bne	a4,a5,800052bc <piperead+0x6a>
    80005292:	2244a783          	lw	a5,548(s1)
    80005296:	c39d                	beqz	a5,800052bc <piperead+0x6a>
    if(killed(pr)){
    80005298:	8552                	mv	a0,s4
    8000529a:	ffffd097          	auipc	ra,0xffffd
    8000529e:	556080e7          	jalr	1366(ra) # 800027f0 <killed>
    800052a2:	e941                	bnez	a0,80005332 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800052a4:	85da                	mv	a1,s6
    800052a6:	854e                	mv	a0,s3
    800052a8:	ffffd097          	auipc	ra,0xffffd
    800052ac:	150080e7          	jalr	336(ra) # 800023f8 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800052b0:	2184a703          	lw	a4,536(s1)
    800052b4:	21c4a783          	lw	a5,540(s1)
    800052b8:	fcf70de3          	beq	a4,a5,80005292 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052bc:	09505263          	blez	s5,80005340 <piperead+0xee>
    800052c0:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800052c2:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800052c4:	2184a783          	lw	a5,536(s1)
    800052c8:	21c4a703          	lw	a4,540(s1)
    800052cc:	02f70d63          	beq	a4,a5,80005306 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800052d0:	0017871b          	addiw	a4,a5,1
    800052d4:	20e4ac23          	sw	a4,536(s1)
    800052d8:	1ff7f793          	andi	a5,a5,511
    800052dc:	97a6                	add	a5,a5,s1
    800052de:	0187c783          	lbu	a5,24(a5)
    800052e2:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800052e6:	4685                	li	a3,1
    800052e8:	fbf40613          	addi	a2,s0,-65
    800052ec:	85ca                	mv	a1,s2
    800052ee:	050a3503          	ld	a0,80(s4)
    800052f2:	ffffc097          	auipc	ra,0xffffc
    800052f6:	392080e7          	jalr	914(ra) # 80001684 <copyout>
    800052fa:	01650663          	beq	a0,s6,80005306 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052fe:	2985                	addiw	s3,s3,1
    80005300:	0905                	addi	s2,s2,1
    80005302:	fd3a91e3          	bne	s5,s3,800052c4 <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005306:	21c48513          	addi	a0,s1,540
    8000530a:	ffffd097          	auipc	ra,0xffffd
    8000530e:	296080e7          	jalr	662(ra) # 800025a0 <wakeup>
  release(&pi->lock);
    80005312:	8526                	mv	a0,s1
    80005314:	ffffc097          	auipc	ra,0xffffc
    80005318:	98a080e7          	jalr	-1654(ra) # 80000c9e <release>
  return i;
}
    8000531c:	854e                	mv	a0,s3
    8000531e:	60a6                	ld	ra,72(sp)
    80005320:	6406                	ld	s0,64(sp)
    80005322:	74e2                	ld	s1,56(sp)
    80005324:	7942                	ld	s2,48(sp)
    80005326:	79a2                	ld	s3,40(sp)
    80005328:	7a02                	ld	s4,32(sp)
    8000532a:	6ae2                	ld	s5,24(sp)
    8000532c:	6b42                	ld	s6,16(sp)
    8000532e:	6161                	addi	sp,sp,80
    80005330:	8082                	ret
      release(&pi->lock);
    80005332:	8526                	mv	a0,s1
    80005334:	ffffc097          	auipc	ra,0xffffc
    80005338:	96a080e7          	jalr	-1686(ra) # 80000c9e <release>
      return -1;
    8000533c:	59fd                	li	s3,-1
    8000533e:	bff9                	j	8000531c <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005340:	4981                	li	s3,0
    80005342:	b7d1                	j	80005306 <piperead+0xb4>

0000000080005344 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005344:	1141                	addi	sp,sp,-16
    80005346:	e422                	sd	s0,8(sp)
    80005348:	0800                	addi	s0,sp,16
    8000534a:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    8000534c:	8905                	andi	a0,a0,1
    8000534e:	c111                	beqz	a0,80005352 <flags2perm+0xe>
      perm = PTE_X;
    80005350:	4521                	li	a0,8
    if(flags & 0x2)
    80005352:	8b89                	andi	a5,a5,2
    80005354:	c399                	beqz	a5,8000535a <flags2perm+0x16>
      perm |= PTE_W;
    80005356:	00456513          	ori	a0,a0,4
    return perm;
}
    8000535a:	6422                	ld	s0,8(sp)
    8000535c:	0141                	addi	sp,sp,16
    8000535e:	8082                	ret

0000000080005360 <exec>:

int
exec(char *path, char **argv)
{
    80005360:	df010113          	addi	sp,sp,-528
    80005364:	20113423          	sd	ra,520(sp)
    80005368:	20813023          	sd	s0,512(sp)
    8000536c:	ffa6                	sd	s1,504(sp)
    8000536e:	fbca                	sd	s2,496(sp)
    80005370:	f7ce                	sd	s3,488(sp)
    80005372:	f3d2                	sd	s4,480(sp)
    80005374:	efd6                	sd	s5,472(sp)
    80005376:	ebda                	sd	s6,464(sp)
    80005378:	e7de                	sd	s7,456(sp)
    8000537a:	e3e2                	sd	s8,448(sp)
    8000537c:	ff66                	sd	s9,440(sp)
    8000537e:	fb6a                	sd	s10,432(sp)
    80005380:	f76e                	sd	s11,424(sp)
    80005382:	0c00                	addi	s0,sp,528
    80005384:	84aa                	mv	s1,a0
    80005386:	dea43c23          	sd	a0,-520(s0)
    8000538a:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000538e:	ffffd097          	auipc	ra,0xffffd
    80005392:	826080e7          	jalr	-2010(ra) # 80001bb4 <myproc>
    80005396:	892a                	mv	s2,a0

  begin_op();
    80005398:	fffff097          	auipc	ra,0xfffff
    8000539c:	474080e7          	jalr	1140(ra) # 8000480c <begin_op>

  if((ip = namei(path)) == 0){
    800053a0:	8526                	mv	a0,s1
    800053a2:	fffff097          	auipc	ra,0xfffff
    800053a6:	24e080e7          	jalr	590(ra) # 800045f0 <namei>
    800053aa:	c92d                	beqz	a0,8000541c <exec+0xbc>
    800053ac:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800053ae:	fffff097          	auipc	ra,0xfffff
    800053b2:	a9c080e7          	jalr	-1380(ra) # 80003e4a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800053b6:	04000713          	li	a4,64
    800053ba:	4681                	li	a3,0
    800053bc:	e5040613          	addi	a2,s0,-432
    800053c0:	4581                	li	a1,0
    800053c2:	8526                	mv	a0,s1
    800053c4:	fffff097          	auipc	ra,0xfffff
    800053c8:	d3a080e7          	jalr	-710(ra) # 800040fe <readi>
    800053cc:	04000793          	li	a5,64
    800053d0:	00f51a63          	bne	a0,a5,800053e4 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800053d4:	e5042703          	lw	a4,-432(s0)
    800053d8:	464c47b7          	lui	a5,0x464c4
    800053dc:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800053e0:	04f70463          	beq	a4,a5,80005428 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800053e4:	8526                	mv	a0,s1
    800053e6:	fffff097          	auipc	ra,0xfffff
    800053ea:	cc6080e7          	jalr	-826(ra) # 800040ac <iunlockput>
    end_op();
    800053ee:	fffff097          	auipc	ra,0xfffff
    800053f2:	49e080e7          	jalr	1182(ra) # 8000488c <end_op>
  }
  return -1;
    800053f6:	557d                	li	a0,-1
}
    800053f8:	20813083          	ld	ra,520(sp)
    800053fc:	20013403          	ld	s0,512(sp)
    80005400:	74fe                	ld	s1,504(sp)
    80005402:	795e                	ld	s2,496(sp)
    80005404:	79be                	ld	s3,488(sp)
    80005406:	7a1e                	ld	s4,480(sp)
    80005408:	6afe                	ld	s5,472(sp)
    8000540a:	6b5e                	ld	s6,464(sp)
    8000540c:	6bbe                	ld	s7,456(sp)
    8000540e:	6c1e                	ld	s8,448(sp)
    80005410:	7cfa                	ld	s9,440(sp)
    80005412:	7d5a                	ld	s10,432(sp)
    80005414:	7dba                	ld	s11,424(sp)
    80005416:	21010113          	addi	sp,sp,528
    8000541a:	8082                	ret
    end_op();
    8000541c:	fffff097          	auipc	ra,0xfffff
    80005420:	470080e7          	jalr	1136(ra) # 8000488c <end_op>
    return -1;
    80005424:	557d                	li	a0,-1
    80005426:	bfc9                	j	800053f8 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005428:	854a                	mv	a0,s2
    8000542a:	ffffd097          	auipc	ra,0xffffd
    8000542e:	84e080e7          	jalr	-1970(ra) # 80001c78 <proc_pagetable>
    80005432:	8baa                	mv	s7,a0
    80005434:	d945                	beqz	a0,800053e4 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005436:	e7042983          	lw	s3,-400(s0)
    8000543a:	e8845783          	lhu	a5,-376(s0)
    8000543e:	c7ad                	beqz	a5,800054a8 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005440:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005442:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80005444:	6c85                	lui	s9,0x1
    80005446:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000544a:	def43823          	sd	a5,-528(s0)
    8000544e:	ac0d                	j	80005680 <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005450:	00003517          	auipc	a0,0x3
    80005454:	3a850513          	addi	a0,a0,936 # 800087f8 <syscalls+0x2a8>
    80005458:	ffffb097          	auipc	ra,0xffffb
    8000545c:	0ec080e7          	jalr	236(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005460:	8756                	mv	a4,s5
    80005462:	012d86bb          	addw	a3,s11,s2
    80005466:	4581                	li	a1,0
    80005468:	8526                	mv	a0,s1
    8000546a:	fffff097          	auipc	ra,0xfffff
    8000546e:	c94080e7          	jalr	-876(ra) # 800040fe <readi>
    80005472:	2501                	sext.w	a0,a0
    80005474:	1aaa9a63          	bne	s5,a0,80005628 <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    80005478:	6785                	lui	a5,0x1
    8000547a:	0127893b          	addw	s2,a5,s2
    8000547e:	77fd                	lui	a5,0xfffff
    80005480:	01478a3b          	addw	s4,a5,s4
    80005484:	1f897563          	bgeu	s2,s8,8000566e <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    80005488:	02091593          	slli	a1,s2,0x20
    8000548c:	9181                	srli	a1,a1,0x20
    8000548e:	95ea                	add	a1,a1,s10
    80005490:	855e                	mv	a0,s7
    80005492:	ffffc097          	auipc	ra,0xffffc
    80005496:	be6080e7          	jalr	-1050(ra) # 80001078 <walkaddr>
    8000549a:	862a                	mv	a2,a0
    if(pa == 0)
    8000549c:	d955                	beqz	a0,80005450 <exec+0xf0>
      n = PGSIZE;
    8000549e:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800054a0:	fd9a70e3          	bgeu	s4,s9,80005460 <exec+0x100>
      n = sz - i;
    800054a4:	8ad2                	mv	s5,s4
    800054a6:	bf6d                	j	80005460 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800054a8:	4a01                	li	s4,0
  iunlockput(ip);
    800054aa:	8526                	mv	a0,s1
    800054ac:	fffff097          	auipc	ra,0xfffff
    800054b0:	c00080e7          	jalr	-1024(ra) # 800040ac <iunlockput>
  end_op();
    800054b4:	fffff097          	auipc	ra,0xfffff
    800054b8:	3d8080e7          	jalr	984(ra) # 8000488c <end_op>
  p = myproc();
    800054bc:	ffffc097          	auipc	ra,0xffffc
    800054c0:	6f8080e7          	jalr	1784(ra) # 80001bb4 <myproc>
    800054c4:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800054c6:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800054ca:	6785                	lui	a5,0x1
    800054cc:	17fd                	addi	a5,a5,-1
    800054ce:	9a3e                	add	s4,s4,a5
    800054d0:	757d                	lui	a0,0xfffff
    800054d2:	00aa77b3          	and	a5,s4,a0
    800054d6:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800054da:	4691                	li	a3,4
    800054dc:	6609                	lui	a2,0x2
    800054de:	963e                	add	a2,a2,a5
    800054e0:	85be                	mv	a1,a5
    800054e2:	855e                	mv	a0,s7
    800054e4:	ffffc097          	auipc	ra,0xffffc
    800054e8:	f48080e7          	jalr	-184(ra) # 8000142c <uvmalloc>
    800054ec:	8b2a                	mv	s6,a0
  ip = 0;
    800054ee:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800054f0:	12050c63          	beqz	a0,80005628 <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    800054f4:	75f9                	lui	a1,0xffffe
    800054f6:	95aa                	add	a1,a1,a0
    800054f8:	855e                	mv	a0,s7
    800054fa:	ffffc097          	auipc	ra,0xffffc
    800054fe:	158080e7          	jalr	344(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    80005502:	7c7d                	lui	s8,0xfffff
    80005504:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005506:	e0043783          	ld	a5,-512(s0)
    8000550a:	6388                	ld	a0,0(a5)
    8000550c:	c535                	beqz	a0,80005578 <exec+0x218>
    8000550e:	e9040993          	addi	s3,s0,-368
    80005512:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005516:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005518:	ffffc097          	auipc	ra,0xffffc
    8000551c:	952080e7          	jalr	-1710(ra) # 80000e6a <strlen>
    80005520:	2505                	addiw	a0,a0,1
    80005522:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005526:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000552a:	13896663          	bltu	s2,s8,80005656 <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000552e:	e0043d83          	ld	s11,-512(s0)
    80005532:	000dba03          	ld	s4,0(s11)
    80005536:	8552                	mv	a0,s4
    80005538:	ffffc097          	auipc	ra,0xffffc
    8000553c:	932080e7          	jalr	-1742(ra) # 80000e6a <strlen>
    80005540:	0015069b          	addiw	a3,a0,1
    80005544:	8652                	mv	a2,s4
    80005546:	85ca                	mv	a1,s2
    80005548:	855e                	mv	a0,s7
    8000554a:	ffffc097          	auipc	ra,0xffffc
    8000554e:	13a080e7          	jalr	314(ra) # 80001684 <copyout>
    80005552:	10054663          	bltz	a0,8000565e <exec+0x2fe>
    ustack[argc] = sp;
    80005556:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000555a:	0485                	addi	s1,s1,1
    8000555c:	008d8793          	addi	a5,s11,8
    80005560:	e0f43023          	sd	a5,-512(s0)
    80005564:	008db503          	ld	a0,8(s11)
    80005568:	c911                	beqz	a0,8000557c <exec+0x21c>
    if(argc >= MAXARG)
    8000556a:	09a1                	addi	s3,s3,8
    8000556c:	fb3c96e3          	bne	s9,s3,80005518 <exec+0x1b8>
  sz = sz1;
    80005570:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005574:	4481                	li	s1,0
    80005576:	a84d                	j	80005628 <exec+0x2c8>
  sp = sz;
    80005578:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000557a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000557c:	00349793          	slli	a5,s1,0x3
    80005580:	f9040713          	addi	a4,s0,-112
    80005584:	97ba                	add	a5,a5,a4
    80005586:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000558a:	00148693          	addi	a3,s1,1
    8000558e:	068e                	slli	a3,a3,0x3
    80005590:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005594:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005598:	01897663          	bgeu	s2,s8,800055a4 <exec+0x244>
  sz = sz1;
    8000559c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055a0:	4481                	li	s1,0
    800055a2:	a059                	j	80005628 <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800055a4:	e9040613          	addi	a2,s0,-368
    800055a8:	85ca                	mv	a1,s2
    800055aa:	855e                	mv	a0,s7
    800055ac:	ffffc097          	auipc	ra,0xffffc
    800055b0:	0d8080e7          	jalr	216(ra) # 80001684 <copyout>
    800055b4:	0a054963          	bltz	a0,80005666 <exec+0x306>
  p->trapframe->a1 = sp;
    800055b8:	058ab783          	ld	a5,88(s5)
    800055bc:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800055c0:	df843783          	ld	a5,-520(s0)
    800055c4:	0007c703          	lbu	a4,0(a5)
    800055c8:	cf11                	beqz	a4,800055e4 <exec+0x284>
    800055ca:	0785                	addi	a5,a5,1
    if(*s == '/')
    800055cc:	02f00693          	li	a3,47
    800055d0:	a039                	j	800055de <exec+0x27e>
      last = s+1;
    800055d2:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800055d6:	0785                	addi	a5,a5,1
    800055d8:	fff7c703          	lbu	a4,-1(a5)
    800055dc:	c701                	beqz	a4,800055e4 <exec+0x284>
    if(*s == '/')
    800055de:	fed71ce3          	bne	a4,a3,800055d6 <exec+0x276>
    800055e2:	bfc5                	j	800055d2 <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    800055e4:	4641                	li	a2,16
    800055e6:	df843583          	ld	a1,-520(s0)
    800055ea:	158a8513          	addi	a0,s5,344
    800055ee:	ffffc097          	auipc	ra,0xffffc
    800055f2:	84a080e7          	jalr	-1974(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    800055f6:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800055fa:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    800055fe:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005602:	058ab783          	ld	a5,88(s5)
    80005606:	e6843703          	ld	a4,-408(s0)
    8000560a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000560c:	058ab783          	ld	a5,88(s5)
    80005610:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005614:	85ea                	mv	a1,s10
    80005616:	ffffc097          	auipc	ra,0xffffc
    8000561a:	6fe080e7          	jalr	1790(ra) # 80001d14 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000561e:	0004851b          	sext.w	a0,s1
    80005622:	bbd9                	j	800053f8 <exec+0x98>
    80005624:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005628:	e0843583          	ld	a1,-504(s0)
    8000562c:	855e                	mv	a0,s7
    8000562e:	ffffc097          	auipc	ra,0xffffc
    80005632:	6e6080e7          	jalr	1766(ra) # 80001d14 <proc_freepagetable>
  if(ip){
    80005636:	da0497e3          	bnez	s1,800053e4 <exec+0x84>
  return -1;
    8000563a:	557d                	li	a0,-1
    8000563c:	bb75                	j	800053f8 <exec+0x98>
    8000563e:	e1443423          	sd	s4,-504(s0)
    80005642:	b7dd                	j	80005628 <exec+0x2c8>
    80005644:	e1443423          	sd	s4,-504(s0)
    80005648:	b7c5                	j	80005628 <exec+0x2c8>
    8000564a:	e1443423          	sd	s4,-504(s0)
    8000564e:	bfe9                	j	80005628 <exec+0x2c8>
    80005650:	e1443423          	sd	s4,-504(s0)
    80005654:	bfd1                	j	80005628 <exec+0x2c8>
  sz = sz1;
    80005656:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000565a:	4481                	li	s1,0
    8000565c:	b7f1                	j	80005628 <exec+0x2c8>
  sz = sz1;
    8000565e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005662:	4481                	li	s1,0
    80005664:	b7d1                	j	80005628 <exec+0x2c8>
  sz = sz1;
    80005666:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000566a:	4481                	li	s1,0
    8000566c:	bf75                	j	80005628 <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000566e:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005672:	2b05                	addiw	s6,s6,1
    80005674:	0389899b          	addiw	s3,s3,56
    80005678:	e8845783          	lhu	a5,-376(s0)
    8000567c:	e2fb57e3          	bge	s6,a5,800054aa <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005680:	2981                	sext.w	s3,s3
    80005682:	03800713          	li	a4,56
    80005686:	86ce                	mv	a3,s3
    80005688:	e1840613          	addi	a2,s0,-488
    8000568c:	4581                	li	a1,0
    8000568e:	8526                	mv	a0,s1
    80005690:	fffff097          	auipc	ra,0xfffff
    80005694:	a6e080e7          	jalr	-1426(ra) # 800040fe <readi>
    80005698:	03800793          	li	a5,56
    8000569c:	f8f514e3          	bne	a0,a5,80005624 <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    800056a0:	e1842783          	lw	a5,-488(s0)
    800056a4:	4705                	li	a4,1
    800056a6:	fce796e3          	bne	a5,a4,80005672 <exec+0x312>
    if(ph.memsz < ph.filesz)
    800056aa:	e4043903          	ld	s2,-448(s0)
    800056ae:	e3843783          	ld	a5,-456(s0)
    800056b2:	f8f966e3          	bltu	s2,a5,8000563e <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800056b6:	e2843783          	ld	a5,-472(s0)
    800056ba:	993e                	add	s2,s2,a5
    800056bc:	f8f964e3          	bltu	s2,a5,80005644 <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    800056c0:	df043703          	ld	a4,-528(s0)
    800056c4:	8ff9                	and	a5,a5,a4
    800056c6:	f3d1                	bnez	a5,8000564a <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800056c8:	e1c42503          	lw	a0,-484(s0)
    800056cc:	00000097          	auipc	ra,0x0
    800056d0:	c78080e7          	jalr	-904(ra) # 80005344 <flags2perm>
    800056d4:	86aa                	mv	a3,a0
    800056d6:	864a                	mv	a2,s2
    800056d8:	85d2                	mv	a1,s4
    800056da:	855e                	mv	a0,s7
    800056dc:	ffffc097          	auipc	ra,0xffffc
    800056e0:	d50080e7          	jalr	-688(ra) # 8000142c <uvmalloc>
    800056e4:	e0a43423          	sd	a0,-504(s0)
    800056e8:	d525                	beqz	a0,80005650 <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800056ea:	e2843d03          	ld	s10,-472(s0)
    800056ee:	e2042d83          	lw	s11,-480(s0)
    800056f2:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800056f6:	f60c0ce3          	beqz	s8,8000566e <exec+0x30e>
    800056fa:	8a62                	mv	s4,s8
    800056fc:	4901                	li	s2,0
    800056fe:	b369                	j	80005488 <exec+0x128>

0000000080005700 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005700:	7179                	addi	sp,sp,-48
    80005702:	f406                	sd	ra,40(sp)
    80005704:	f022                	sd	s0,32(sp)
    80005706:	ec26                	sd	s1,24(sp)
    80005708:	e84a                	sd	s2,16(sp)
    8000570a:	1800                	addi	s0,sp,48
    8000570c:	892e                	mv	s2,a1
    8000570e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005710:	fdc40593          	addi	a1,s0,-36
    80005714:	ffffe097          	auipc	ra,0xffffe
    80005718:	9fc080e7          	jalr	-1540(ra) # 80003110 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000571c:	fdc42703          	lw	a4,-36(s0)
    80005720:	47bd                	li	a5,15
    80005722:	02e7eb63          	bltu	a5,a4,80005758 <argfd+0x58>
    80005726:	ffffc097          	auipc	ra,0xffffc
    8000572a:	48e080e7          	jalr	1166(ra) # 80001bb4 <myproc>
    8000572e:	fdc42703          	lw	a4,-36(s0)
    80005732:	01a70793          	addi	a5,a4,26
    80005736:	078e                	slli	a5,a5,0x3
    80005738:	953e                	add	a0,a0,a5
    8000573a:	611c                	ld	a5,0(a0)
    8000573c:	c385                	beqz	a5,8000575c <argfd+0x5c>
    return -1;
  if(pfd)
    8000573e:	00090463          	beqz	s2,80005746 <argfd+0x46>
    *pfd = fd;
    80005742:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005746:	4501                	li	a0,0
  if(pf)
    80005748:	c091                	beqz	s1,8000574c <argfd+0x4c>
    *pf = f;
    8000574a:	e09c                	sd	a5,0(s1)
}
    8000574c:	70a2                	ld	ra,40(sp)
    8000574e:	7402                	ld	s0,32(sp)
    80005750:	64e2                	ld	s1,24(sp)
    80005752:	6942                	ld	s2,16(sp)
    80005754:	6145                	addi	sp,sp,48
    80005756:	8082                	ret
    return -1;
    80005758:	557d                	li	a0,-1
    8000575a:	bfcd                	j	8000574c <argfd+0x4c>
    8000575c:	557d                	li	a0,-1
    8000575e:	b7fd                	j	8000574c <argfd+0x4c>

0000000080005760 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005760:	1101                	addi	sp,sp,-32
    80005762:	ec06                	sd	ra,24(sp)
    80005764:	e822                	sd	s0,16(sp)
    80005766:	e426                	sd	s1,8(sp)
    80005768:	1000                	addi	s0,sp,32
    8000576a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000576c:	ffffc097          	auipc	ra,0xffffc
    80005770:	448080e7          	jalr	1096(ra) # 80001bb4 <myproc>
    80005774:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005776:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffda358>
    8000577a:	4501                	li	a0,0
    8000577c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000577e:	6398                	ld	a4,0(a5)
    80005780:	cb19                	beqz	a4,80005796 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005782:	2505                	addiw	a0,a0,1
    80005784:	07a1                	addi	a5,a5,8
    80005786:	fed51ce3          	bne	a0,a3,8000577e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000578a:	557d                	li	a0,-1
}
    8000578c:	60e2                	ld	ra,24(sp)
    8000578e:	6442                	ld	s0,16(sp)
    80005790:	64a2                	ld	s1,8(sp)
    80005792:	6105                	addi	sp,sp,32
    80005794:	8082                	ret
      p->ofile[fd] = f;
    80005796:	01a50793          	addi	a5,a0,26
    8000579a:	078e                	slli	a5,a5,0x3
    8000579c:	963e                	add	a2,a2,a5
    8000579e:	e204                	sd	s1,0(a2)
      return fd;
    800057a0:	b7f5                	j	8000578c <fdalloc+0x2c>

00000000800057a2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800057a2:	715d                	addi	sp,sp,-80
    800057a4:	e486                	sd	ra,72(sp)
    800057a6:	e0a2                	sd	s0,64(sp)
    800057a8:	fc26                	sd	s1,56(sp)
    800057aa:	f84a                	sd	s2,48(sp)
    800057ac:	f44e                	sd	s3,40(sp)
    800057ae:	f052                	sd	s4,32(sp)
    800057b0:	ec56                	sd	s5,24(sp)
    800057b2:	e85a                	sd	s6,16(sp)
    800057b4:	0880                	addi	s0,sp,80
    800057b6:	8b2e                	mv	s6,a1
    800057b8:	89b2                	mv	s3,a2
    800057ba:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800057bc:	fb040593          	addi	a1,s0,-80
    800057c0:	fffff097          	auipc	ra,0xfffff
    800057c4:	e4e080e7          	jalr	-434(ra) # 8000460e <nameiparent>
    800057c8:	84aa                	mv	s1,a0
    800057ca:	16050063          	beqz	a0,8000592a <create+0x188>
    return 0;

  ilock(dp);
    800057ce:	ffffe097          	auipc	ra,0xffffe
    800057d2:	67c080e7          	jalr	1660(ra) # 80003e4a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800057d6:	4601                	li	a2,0
    800057d8:	fb040593          	addi	a1,s0,-80
    800057dc:	8526                	mv	a0,s1
    800057de:	fffff097          	auipc	ra,0xfffff
    800057e2:	b50080e7          	jalr	-1200(ra) # 8000432e <dirlookup>
    800057e6:	8aaa                	mv	s5,a0
    800057e8:	c931                	beqz	a0,8000583c <create+0x9a>
    iunlockput(dp);
    800057ea:	8526                	mv	a0,s1
    800057ec:	fffff097          	auipc	ra,0xfffff
    800057f0:	8c0080e7          	jalr	-1856(ra) # 800040ac <iunlockput>
    ilock(ip);
    800057f4:	8556                	mv	a0,s5
    800057f6:	ffffe097          	auipc	ra,0xffffe
    800057fa:	654080e7          	jalr	1620(ra) # 80003e4a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800057fe:	000b059b          	sext.w	a1,s6
    80005802:	4789                	li	a5,2
    80005804:	02f59563          	bne	a1,a5,8000582e <create+0x8c>
    80005808:	044ad783          	lhu	a5,68(s5)
    8000580c:	37f9                	addiw	a5,a5,-2
    8000580e:	17c2                	slli	a5,a5,0x30
    80005810:	93c1                	srli	a5,a5,0x30
    80005812:	4705                	li	a4,1
    80005814:	00f76d63          	bltu	a4,a5,8000582e <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005818:	8556                	mv	a0,s5
    8000581a:	60a6                	ld	ra,72(sp)
    8000581c:	6406                	ld	s0,64(sp)
    8000581e:	74e2                	ld	s1,56(sp)
    80005820:	7942                	ld	s2,48(sp)
    80005822:	79a2                	ld	s3,40(sp)
    80005824:	7a02                	ld	s4,32(sp)
    80005826:	6ae2                	ld	s5,24(sp)
    80005828:	6b42                	ld	s6,16(sp)
    8000582a:	6161                	addi	sp,sp,80
    8000582c:	8082                	ret
    iunlockput(ip);
    8000582e:	8556                	mv	a0,s5
    80005830:	fffff097          	auipc	ra,0xfffff
    80005834:	87c080e7          	jalr	-1924(ra) # 800040ac <iunlockput>
    return 0;
    80005838:	4a81                	li	s5,0
    8000583a:	bff9                	j	80005818 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000583c:	85da                	mv	a1,s6
    8000583e:	4088                	lw	a0,0(s1)
    80005840:	ffffe097          	auipc	ra,0xffffe
    80005844:	46e080e7          	jalr	1134(ra) # 80003cae <ialloc>
    80005848:	8a2a                	mv	s4,a0
    8000584a:	c921                	beqz	a0,8000589a <create+0xf8>
  ilock(ip);
    8000584c:	ffffe097          	auipc	ra,0xffffe
    80005850:	5fe080e7          	jalr	1534(ra) # 80003e4a <ilock>
  ip->major = major;
    80005854:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005858:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000585c:	4785                	li	a5,1
    8000585e:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    80005862:	8552                	mv	a0,s4
    80005864:	ffffe097          	auipc	ra,0xffffe
    80005868:	51c080e7          	jalr	1308(ra) # 80003d80 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000586c:	000b059b          	sext.w	a1,s6
    80005870:	4785                	li	a5,1
    80005872:	02f58b63          	beq	a1,a5,800058a8 <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    80005876:	004a2603          	lw	a2,4(s4)
    8000587a:	fb040593          	addi	a1,s0,-80
    8000587e:	8526                	mv	a0,s1
    80005880:	fffff097          	auipc	ra,0xfffff
    80005884:	cbe080e7          	jalr	-834(ra) # 8000453e <dirlink>
    80005888:	06054f63          	bltz	a0,80005906 <create+0x164>
  iunlockput(dp);
    8000588c:	8526                	mv	a0,s1
    8000588e:	fffff097          	auipc	ra,0xfffff
    80005892:	81e080e7          	jalr	-2018(ra) # 800040ac <iunlockput>
  return ip;
    80005896:	8ad2                	mv	s5,s4
    80005898:	b741                	j	80005818 <create+0x76>
    iunlockput(dp);
    8000589a:	8526                	mv	a0,s1
    8000589c:	fffff097          	auipc	ra,0xfffff
    800058a0:	810080e7          	jalr	-2032(ra) # 800040ac <iunlockput>
    return 0;
    800058a4:	8ad2                	mv	s5,s4
    800058a6:	bf8d                	j	80005818 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800058a8:	004a2603          	lw	a2,4(s4)
    800058ac:	00003597          	auipc	a1,0x3
    800058b0:	f6c58593          	addi	a1,a1,-148 # 80008818 <syscalls+0x2c8>
    800058b4:	8552                	mv	a0,s4
    800058b6:	fffff097          	auipc	ra,0xfffff
    800058ba:	c88080e7          	jalr	-888(ra) # 8000453e <dirlink>
    800058be:	04054463          	bltz	a0,80005906 <create+0x164>
    800058c2:	40d0                	lw	a2,4(s1)
    800058c4:	00003597          	auipc	a1,0x3
    800058c8:	f5c58593          	addi	a1,a1,-164 # 80008820 <syscalls+0x2d0>
    800058cc:	8552                	mv	a0,s4
    800058ce:	fffff097          	auipc	ra,0xfffff
    800058d2:	c70080e7          	jalr	-912(ra) # 8000453e <dirlink>
    800058d6:	02054863          	bltz	a0,80005906 <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    800058da:	004a2603          	lw	a2,4(s4)
    800058de:	fb040593          	addi	a1,s0,-80
    800058e2:	8526                	mv	a0,s1
    800058e4:	fffff097          	auipc	ra,0xfffff
    800058e8:	c5a080e7          	jalr	-934(ra) # 8000453e <dirlink>
    800058ec:	00054d63          	bltz	a0,80005906 <create+0x164>
    dp->nlink++;  // for ".."
    800058f0:	04a4d783          	lhu	a5,74(s1)
    800058f4:	2785                	addiw	a5,a5,1
    800058f6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800058fa:	8526                	mv	a0,s1
    800058fc:	ffffe097          	auipc	ra,0xffffe
    80005900:	484080e7          	jalr	1156(ra) # 80003d80 <iupdate>
    80005904:	b761                	j	8000588c <create+0xea>
  ip->nlink = 0;
    80005906:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000590a:	8552                	mv	a0,s4
    8000590c:	ffffe097          	auipc	ra,0xffffe
    80005910:	474080e7          	jalr	1140(ra) # 80003d80 <iupdate>
  iunlockput(ip);
    80005914:	8552                	mv	a0,s4
    80005916:	ffffe097          	auipc	ra,0xffffe
    8000591a:	796080e7          	jalr	1942(ra) # 800040ac <iunlockput>
  iunlockput(dp);
    8000591e:	8526                	mv	a0,s1
    80005920:	ffffe097          	auipc	ra,0xffffe
    80005924:	78c080e7          	jalr	1932(ra) # 800040ac <iunlockput>
  return 0;
    80005928:	bdc5                	j	80005818 <create+0x76>
    return 0;
    8000592a:	8aaa                	mv	s5,a0
    8000592c:	b5f5                	j	80005818 <create+0x76>

000000008000592e <sys_dup>:
{
    8000592e:	7179                	addi	sp,sp,-48
    80005930:	f406                	sd	ra,40(sp)
    80005932:	f022                	sd	s0,32(sp)
    80005934:	ec26                	sd	s1,24(sp)
    80005936:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005938:	fd840613          	addi	a2,s0,-40
    8000593c:	4581                	li	a1,0
    8000593e:	4501                	li	a0,0
    80005940:	00000097          	auipc	ra,0x0
    80005944:	dc0080e7          	jalr	-576(ra) # 80005700 <argfd>
    return -1;
    80005948:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000594a:	02054363          	bltz	a0,80005970 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000594e:	fd843503          	ld	a0,-40(s0)
    80005952:	00000097          	auipc	ra,0x0
    80005956:	e0e080e7          	jalr	-498(ra) # 80005760 <fdalloc>
    8000595a:	84aa                	mv	s1,a0
    return -1;
    8000595c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000595e:	00054963          	bltz	a0,80005970 <sys_dup+0x42>
  filedup(f);
    80005962:	fd843503          	ld	a0,-40(s0)
    80005966:	fffff097          	auipc	ra,0xfffff
    8000596a:	320080e7          	jalr	800(ra) # 80004c86 <filedup>
  return fd;
    8000596e:	87a6                	mv	a5,s1
}
    80005970:	853e                	mv	a0,a5
    80005972:	70a2                	ld	ra,40(sp)
    80005974:	7402                	ld	s0,32(sp)
    80005976:	64e2                	ld	s1,24(sp)
    80005978:	6145                	addi	sp,sp,48
    8000597a:	8082                	ret

000000008000597c <sys_read>:
{
    8000597c:	7179                	addi	sp,sp,-48
    8000597e:	f406                	sd	ra,40(sp)
    80005980:	f022                	sd	s0,32(sp)
    80005982:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005984:	fd840593          	addi	a1,s0,-40
    80005988:	4505                	li	a0,1
    8000598a:	ffffd097          	auipc	ra,0xffffd
    8000598e:	7a6080e7          	jalr	1958(ra) # 80003130 <argaddr>
  argint(2, &n);
    80005992:	fe440593          	addi	a1,s0,-28
    80005996:	4509                	li	a0,2
    80005998:	ffffd097          	auipc	ra,0xffffd
    8000599c:	778080e7          	jalr	1912(ra) # 80003110 <argint>
  if(argfd(0, 0, &f) < 0)
    800059a0:	fe840613          	addi	a2,s0,-24
    800059a4:	4581                	li	a1,0
    800059a6:	4501                	li	a0,0
    800059a8:	00000097          	auipc	ra,0x0
    800059ac:	d58080e7          	jalr	-680(ra) # 80005700 <argfd>
    800059b0:	87aa                	mv	a5,a0
    return -1;
    800059b2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800059b4:	0007cc63          	bltz	a5,800059cc <sys_read+0x50>
  return fileread(f, p, n);
    800059b8:	fe442603          	lw	a2,-28(s0)
    800059bc:	fd843583          	ld	a1,-40(s0)
    800059c0:	fe843503          	ld	a0,-24(s0)
    800059c4:	fffff097          	auipc	ra,0xfffff
    800059c8:	44e080e7          	jalr	1102(ra) # 80004e12 <fileread>
}
    800059cc:	70a2                	ld	ra,40(sp)
    800059ce:	7402                	ld	s0,32(sp)
    800059d0:	6145                	addi	sp,sp,48
    800059d2:	8082                	ret

00000000800059d4 <sys_write>:
{
    800059d4:	7179                	addi	sp,sp,-48
    800059d6:	f406                	sd	ra,40(sp)
    800059d8:	f022                	sd	s0,32(sp)
    800059da:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800059dc:	fd840593          	addi	a1,s0,-40
    800059e0:	4505                	li	a0,1
    800059e2:	ffffd097          	auipc	ra,0xffffd
    800059e6:	74e080e7          	jalr	1870(ra) # 80003130 <argaddr>
  argint(2, &n);
    800059ea:	fe440593          	addi	a1,s0,-28
    800059ee:	4509                	li	a0,2
    800059f0:	ffffd097          	auipc	ra,0xffffd
    800059f4:	720080e7          	jalr	1824(ra) # 80003110 <argint>
  if(argfd(0, 0, &f) < 0)
    800059f8:	fe840613          	addi	a2,s0,-24
    800059fc:	4581                	li	a1,0
    800059fe:	4501                	li	a0,0
    80005a00:	00000097          	auipc	ra,0x0
    80005a04:	d00080e7          	jalr	-768(ra) # 80005700 <argfd>
    80005a08:	87aa                	mv	a5,a0
    return -1;
    80005a0a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005a0c:	0007cc63          	bltz	a5,80005a24 <sys_write+0x50>
  return filewrite(f, p, n);
    80005a10:	fe442603          	lw	a2,-28(s0)
    80005a14:	fd843583          	ld	a1,-40(s0)
    80005a18:	fe843503          	ld	a0,-24(s0)
    80005a1c:	fffff097          	auipc	ra,0xfffff
    80005a20:	4b8080e7          	jalr	1208(ra) # 80004ed4 <filewrite>
}
    80005a24:	70a2                	ld	ra,40(sp)
    80005a26:	7402                	ld	s0,32(sp)
    80005a28:	6145                	addi	sp,sp,48
    80005a2a:	8082                	ret

0000000080005a2c <sys_close>:
{
    80005a2c:	1101                	addi	sp,sp,-32
    80005a2e:	ec06                	sd	ra,24(sp)
    80005a30:	e822                	sd	s0,16(sp)
    80005a32:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005a34:	fe040613          	addi	a2,s0,-32
    80005a38:	fec40593          	addi	a1,s0,-20
    80005a3c:	4501                	li	a0,0
    80005a3e:	00000097          	auipc	ra,0x0
    80005a42:	cc2080e7          	jalr	-830(ra) # 80005700 <argfd>
    return -1;
    80005a46:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005a48:	02054463          	bltz	a0,80005a70 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005a4c:	ffffc097          	auipc	ra,0xffffc
    80005a50:	168080e7          	jalr	360(ra) # 80001bb4 <myproc>
    80005a54:	fec42783          	lw	a5,-20(s0)
    80005a58:	07e9                	addi	a5,a5,26
    80005a5a:	078e                	slli	a5,a5,0x3
    80005a5c:	97aa                	add	a5,a5,a0
    80005a5e:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005a62:	fe043503          	ld	a0,-32(s0)
    80005a66:	fffff097          	auipc	ra,0xfffff
    80005a6a:	272080e7          	jalr	626(ra) # 80004cd8 <fileclose>
  return 0;
    80005a6e:	4781                	li	a5,0
}
    80005a70:	853e                	mv	a0,a5
    80005a72:	60e2                	ld	ra,24(sp)
    80005a74:	6442                	ld	s0,16(sp)
    80005a76:	6105                	addi	sp,sp,32
    80005a78:	8082                	ret

0000000080005a7a <sys_fstat>:
{
    80005a7a:	1101                	addi	sp,sp,-32
    80005a7c:	ec06                	sd	ra,24(sp)
    80005a7e:	e822                	sd	s0,16(sp)
    80005a80:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005a82:	fe040593          	addi	a1,s0,-32
    80005a86:	4505                	li	a0,1
    80005a88:	ffffd097          	auipc	ra,0xffffd
    80005a8c:	6a8080e7          	jalr	1704(ra) # 80003130 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005a90:	fe840613          	addi	a2,s0,-24
    80005a94:	4581                	li	a1,0
    80005a96:	4501                	li	a0,0
    80005a98:	00000097          	auipc	ra,0x0
    80005a9c:	c68080e7          	jalr	-920(ra) # 80005700 <argfd>
    80005aa0:	87aa                	mv	a5,a0
    return -1;
    80005aa2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005aa4:	0007ca63          	bltz	a5,80005ab8 <sys_fstat+0x3e>
  return filestat(f, st);
    80005aa8:	fe043583          	ld	a1,-32(s0)
    80005aac:	fe843503          	ld	a0,-24(s0)
    80005ab0:	fffff097          	auipc	ra,0xfffff
    80005ab4:	2f0080e7          	jalr	752(ra) # 80004da0 <filestat>
}
    80005ab8:	60e2                	ld	ra,24(sp)
    80005aba:	6442                	ld	s0,16(sp)
    80005abc:	6105                	addi	sp,sp,32
    80005abe:	8082                	ret

0000000080005ac0 <sys_link>:
{
    80005ac0:	7169                	addi	sp,sp,-304
    80005ac2:	f606                	sd	ra,296(sp)
    80005ac4:	f222                	sd	s0,288(sp)
    80005ac6:	ee26                	sd	s1,280(sp)
    80005ac8:	ea4a                	sd	s2,272(sp)
    80005aca:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005acc:	08000613          	li	a2,128
    80005ad0:	ed040593          	addi	a1,s0,-304
    80005ad4:	4501                	li	a0,0
    80005ad6:	ffffd097          	auipc	ra,0xffffd
    80005ada:	67a080e7          	jalr	1658(ra) # 80003150 <argstr>
    return -1;
    80005ade:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ae0:	10054e63          	bltz	a0,80005bfc <sys_link+0x13c>
    80005ae4:	08000613          	li	a2,128
    80005ae8:	f5040593          	addi	a1,s0,-176
    80005aec:	4505                	li	a0,1
    80005aee:	ffffd097          	auipc	ra,0xffffd
    80005af2:	662080e7          	jalr	1634(ra) # 80003150 <argstr>
    return -1;
    80005af6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005af8:	10054263          	bltz	a0,80005bfc <sys_link+0x13c>
  begin_op();
    80005afc:	fffff097          	auipc	ra,0xfffff
    80005b00:	d10080e7          	jalr	-752(ra) # 8000480c <begin_op>
  if((ip = namei(old)) == 0){
    80005b04:	ed040513          	addi	a0,s0,-304
    80005b08:	fffff097          	auipc	ra,0xfffff
    80005b0c:	ae8080e7          	jalr	-1304(ra) # 800045f0 <namei>
    80005b10:	84aa                	mv	s1,a0
    80005b12:	c551                	beqz	a0,80005b9e <sys_link+0xde>
  ilock(ip);
    80005b14:	ffffe097          	auipc	ra,0xffffe
    80005b18:	336080e7          	jalr	822(ra) # 80003e4a <ilock>
  if(ip->type == T_DIR){
    80005b1c:	04449703          	lh	a4,68(s1)
    80005b20:	4785                	li	a5,1
    80005b22:	08f70463          	beq	a4,a5,80005baa <sys_link+0xea>
  ip->nlink++;
    80005b26:	04a4d783          	lhu	a5,74(s1)
    80005b2a:	2785                	addiw	a5,a5,1
    80005b2c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b30:	8526                	mv	a0,s1
    80005b32:	ffffe097          	auipc	ra,0xffffe
    80005b36:	24e080e7          	jalr	590(ra) # 80003d80 <iupdate>
  iunlock(ip);
    80005b3a:	8526                	mv	a0,s1
    80005b3c:	ffffe097          	auipc	ra,0xffffe
    80005b40:	3d0080e7          	jalr	976(ra) # 80003f0c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005b44:	fd040593          	addi	a1,s0,-48
    80005b48:	f5040513          	addi	a0,s0,-176
    80005b4c:	fffff097          	auipc	ra,0xfffff
    80005b50:	ac2080e7          	jalr	-1342(ra) # 8000460e <nameiparent>
    80005b54:	892a                	mv	s2,a0
    80005b56:	c935                	beqz	a0,80005bca <sys_link+0x10a>
  ilock(dp);
    80005b58:	ffffe097          	auipc	ra,0xffffe
    80005b5c:	2f2080e7          	jalr	754(ra) # 80003e4a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005b60:	00092703          	lw	a4,0(s2)
    80005b64:	409c                	lw	a5,0(s1)
    80005b66:	04f71d63          	bne	a4,a5,80005bc0 <sys_link+0x100>
    80005b6a:	40d0                	lw	a2,4(s1)
    80005b6c:	fd040593          	addi	a1,s0,-48
    80005b70:	854a                	mv	a0,s2
    80005b72:	fffff097          	auipc	ra,0xfffff
    80005b76:	9cc080e7          	jalr	-1588(ra) # 8000453e <dirlink>
    80005b7a:	04054363          	bltz	a0,80005bc0 <sys_link+0x100>
  iunlockput(dp);
    80005b7e:	854a                	mv	a0,s2
    80005b80:	ffffe097          	auipc	ra,0xffffe
    80005b84:	52c080e7          	jalr	1324(ra) # 800040ac <iunlockput>
  iput(ip);
    80005b88:	8526                	mv	a0,s1
    80005b8a:	ffffe097          	auipc	ra,0xffffe
    80005b8e:	47a080e7          	jalr	1146(ra) # 80004004 <iput>
  end_op();
    80005b92:	fffff097          	auipc	ra,0xfffff
    80005b96:	cfa080e7          	jalr	-774(ra) # 8000488c <end_op>
  return 0;
    80005b9a:	4781                	li	a5,0
    80005b9c:	a085                	j	80005bfc <sys_link+0x13c>
    end_op();
    80005b9e:	fffff097          	auipc	ra,0xfffff
    80005ba2:	cee080e7          	jalr	-786(ra) # 8000488c <end_op>
    return -1;
    80005ba6:	57fd                	li	a5,-1
    80005ba8:	a891                	j	80005bfc <sys_link+0x13c>
    iunlockput(ip);
    80005baa:	8526                	mv	a0,s1
    80005bac:	ffffe097          	auipc	ra,0xffffe
    80005bb0:	500080e7          	jalr	1280(ra) # 800040ac <iunlockput>
    end_op();
    80005bb4:	fffff097          	auipc	ra,0xfffff
    80005bb8:	cd8080e7          	jalr	-808(ra) # 8000488c <end_op>
    return -1;
    80005bbc:	57fd                	li	a5,-1
    80005bbe:	a83d                	j	80005bfc <sys_link+0x13c>
    iunlockput(dp);
    80005bc0:	854a                	mv	a0,s2
    80005bc2:	ffffe097          	auipc	ra,0xffffe
    80005bc6:	4ea080e7          	jalr	1258(ra) # 800040ac <iunlockput>
  ilock(ip);
    80005bca:	8526                	mv	a0,s1
    80005bcc:	ffffe097          	auipc	ra,0xffffe
    80005bd0:	27e080e7          	jalr	638(ra) # 80003e4a <ilock>
  ip->nlink--;
    80005bd4:	04a4d783          	lhu	a5,74(s1)
    80005bd8:	37fd                	addiw	a5,a5,-1
    80005bda:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005bde:	8526                	mv	a0,s1
    80005be0:	ffffe097          	auipc	ra,0xffffe
    80005be4:	1a0080e7          	jalr	416(ra) # 80003d80 <iupdate>
  iunlockput(ip);
    80005be8:	8526                	mv	a0,s1
    80005bea:	ffffe097          	auipc	ra,0xffffe
    80005bee:	4c2080e7          	jalr	1218(ra) # 800040ac <iunlockput>
  end_op();
    80005bf2:	fffff097          	auipc	ra,0xfffff
    80005bf6:	c9a080e7          	jalr	-870(ra) # 8000488c <end_op>
  return -1;
    80005bfa:	57fd                	li	a5,-1
}
    80005bfc:	853e                	mv	a0,a5
    80005bfe:	70b2                	ld	ra,296(sp)
    80005c00:	7412                	ld	s0,288(sp)
    80005c02:	64f2                	ld	s1,280(sp)
    80005c04:	6952                	ld	s2,272(sp)
    80005c06:	6155                	addi	sp,sp,304
    80005c08:	8082                	ret

0000000080005c0a <sys_unlink>:
{
    80005c0a:	7151                	addi	sp,sp,-240
    80005c0c:	f586                	sd	ra,232(sp)
    80005c0e:	f1a2                	sd	s0,224(sp)
    80005c10:	eda6                	sd	s1,216(sp)
    80005c12:	e9ca                	sd	s2,208(sp)
    80005c14:	e5ce                	sd	s3,200(sp)
    80005c16:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005c18:	08000613          	li	a2,128
    80005c1c:	f3040593          	addi	a1,s0,-208
    80005c20:	4501                	li	a0,0
    80005c22:	ffffd097          	auipc	ra,0xffffd
    80005c26:	52e080e7          	jalr	1326(ra) # 80003150 <argstr>
    80005c2a:	18054163          	bltz	a0,80005dac <sys_unlink+0x1a2>
  begin_op();
    80005c2e:	fffff097          	auipc	ra,0xfffff
    80005c32:	bde080e7          	jalr	-1058(ra) # 8000480c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005c36:	fb040593          	addi	a1,s0,-80
    80005c3a:	f3040513          	addi	a0,s0,-208
    80005c3e:	fffff097          	auipc	ra,0xfffff
    80005c42:	9d0080e7          	jalr	-1584(ra) # 8000460e <nameiparent>
    80005c46:	84aa                	mv	s1,a0
    80005c48:	c979                	beqz	a0,80005d1e <sys_unlink+0x114>
  ilock(dp);
    80005c4a:	ffffe097          	auipc	ra,0xffffe
    80005c4e:	200080e7          	jalr	512(ra) # 80003e4a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005c52:	00003597          	auipc	a1,0x3
    80005c56:	bc658593          	addi	a1,a1,-1082 # 80008818 <syscalls+0x2c8>
    80005c5a:	fb040513          	addi	a0,s0,-80
    80005c5e:	ffffe097          	auipc	ra,0xffffe
    80005c62:	6b6080e7          	jalr	1718(ra) # 80004314 <namecmp>
    80005c66:	14050a63          	beqz	a0,80005dba <sys_unlink+0x1b0>
    80005c6a:	00003597          	auipc	a1,0x3
    80005c6e:	bb658593          	addi	a1,a1,-1098 # 80008820 <syscalls+0x2d0>
    80005c72:	fb040513          	addi	a0,s0,-80
    80005c76:	ffffe097          	auipc	ra,0xffffe
    80005c7a:	69e080e7          	jalr	1694(ra) # 80004314 <namecmp>
    80005c7e:	12050e63          	beqz	a0,80005dba <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005c82:	f2c40613          	addi	a2,s0,-212
    80005c86:	fb040593          	addi	a1,s0,-80
    80005c8a:	8526                	mv	a0,s1
    80005c8c:	ffffe097          	auipc	ra,0xffffe
    80005c90:	6a2080e7          	jalr	1698(ra) # 8000432e <dirlookup>
    80005c94:	892a                	mv	s2,a0
    80005c96:	12050263          	beqz	a0,80005dba <sys_unlink+0x1b0>
  ilock(ip);
    80005c9a:	ffffe097          	auipc	ra,0xffffe
    80005c9e:	1b0080e7          	jalr	432(ra) # 80003e4a <ilock>
  if(ip->nlink < 1)
    80005ca2:	04a91783          	lh	a5,74(s2)
    80005ca6:	08f05263          	blez	a5,80005d2a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005caa:	04491703          	lh	a4,68(s2)
    80005cae:	4785                	li	a5,1
    80005cb0:	08f70563          	beq	a4,a5,80005d3a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005cb4:	4641                	li	a2,16
    80005cb6:	4581                	li	a1,0
    80005cb8:	fc040513          	addi	a0,s0,-64
    80005cbc:	ffffb097          	auipc	ra,0xffffb
    80005cc0:	02a080e7          	jalr	42(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005cc4:	4741                	li	a4,16
    80005cc6:	f2c42683          	lw	a3,-212(s0)
    80005cca:	fc040613          	addi	a2,s0,-64
    80005cce:	4581                	li	a1,0
    80005cd0:	8526                	mv	a0,s1
    80005cd2:	ffffe097          	auipc	ra,0xffffe
    80005cd6:	524080e7          	jalr	1316(ra) # 800041f6 <writei>
    80005cda:	47c1                	li	a5,16
    80005cdc:	0af51563          	bne	a0,a5,80005d86 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005ce0:	04491703          	lh	a4,68(s2)
    80005ce4:	4785                	li	a5,1
    80005ce6:	0af70863          	beq	a4,a5,80005d96 <sys_unlink+0x18c>
  iunlockput(dp);
    80005cea:	8526                	mv	a0,s1
    80005cec:	ffffe097          	auipc	ra,0xffffe
    80005cf0:	3c0080e7          	jalr	960(ra) # 800040ac <iunlockput>
  ip->nlink--;
    80005cf4:	04a95783          	lhu	a5,74(s2)
    80005cf8:	37fd                	addiw	a5,a5,-1
    80005cfa:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005cfe:	854a                	mv	a0,s2
    80005d00:	ffffe097          	auipc	ra,0xffffe
    80005d04:	080080e7          	jalr	128(ra) # 80003d80 <iupdate>
  iunlockput(ip);
    80005d08:	854a                	mv	a0,s2
    80005d0a:	ffffe097          	auipc	ra,0xffffe
    80005d0e:	3a2080e7          	jalr	930(ra) # 800040ac <iunlockput>
  end_op();
    80005d12:	fffff097          	auipc	ra,0xfffff
    80005d16:	b7a080e7          	jalr	-1158(ra) # 8000488c <end_op>
  return 0;
    80005d1a:	4501                	li	a0,0
    80005d1c:	a84d                	j	80005dce <sys_unlink+0x1c4>
    end_op();
    80005d1e:	fffff097          	auipc	ra,0xfffff
    80005d22:	b6e080e7          	jalr	-1170(ra) # 8000488c <end_op>
    return -1;
    80005d26:	557d                	li	a0,-1
    80005d28:	a05d                	j	80005dce <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005d2a:	00003517          	auipc	a0,0x3
    80005d2e:	afe50513          	addi	a0,a0,-1282 # 80008828 <syscalls+0x2d8>
    80005d32:	ffffb097          	auipc	ra,0xffffb
    80005d36:	812080e7          	jalr	-2030(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d3a:	04c92703          	lw	a4,76(s2)
    80005d3e:	02000793          	li	a5,32
    80005d42:	f6e7f9e3          	bgeu	a5,a4,80005cb4 <sys_unlink+0xaa>
    80005d46:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d4a:	4741                	li	a4,16
    80005d4c:	86ce                	mv	a3,s3
    80005d4e:	f1840613          	addi	a2,s0,-232
    80005d52:	4581                	li	a1,0
    80005d54:	854a                	mv	a0,s2
    80005d56:	ffffe097          	auipc	ra,0xffffe
    80005d5a:	3a8080e7          	jalr	936(ra) # 800040fe <readi>
    80005d5e:	47c1                	li	a5,16
    80005d60:	00f51b63          	bne	a0,a5,80005d76 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005d64:	f1845783          	lhu	a5,-232(s0)
    80005d68:	e7a1                	bnez	a5,80005db0 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d6a:	29c1                	addiw	s3,s3,16
    80005d6c:	04c92783          	lw	a5,76(s2)
    80005d70:	fcf9ede3          	bltu	s3,a5,80005d4a <sys_unlink+0x140>
    80005d74:	b781                	j	80005cb4 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005d76:	00003517          	auipc	a0,0x3
    80005d7a:	aca50513          	addi	a0,a0,-1334 # 80008840 <syscalls+0x2f0>
    80005d7e:	ffffa097          	auipc	ra,0xffffa
    80005d82:	7c6080e7          	jalr	1990(ra) # 80000544 <panic>
    panic("unlink: writei");
    80005d86:	00003517          	auipc	a0,0x3
    80005d8a:	ad250513          	addi	a0,a0,-1326 # 80008858 <syscalls+0x308>
    80005d8e:	ffffa097          	auipc	ra,0xffffa
    80005d92:	7b6080e7          	jalr	1974(ra) # 80000544 <panic>
    dp->nlink--;
    80005d96:	04a4d783          	lhu	a5,74(s1)
    80005d9a:	37fd                	addiw	a5,a5,-1
    80005d9c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005da0:	8526                	mv	a0,s1
    80005da2:	ffffe097          	auipc	ra,0xffffe
    80005da6:	fde080e7          	jalr	-34(ra) # 80003d80 <iupdate>
    80005daa:	b781                	j	80005cea <sys_unlink+0xe0>
    return -1;
    80005dac:	557d                	li	a0,-1
    80005dae:	a005                	j	80005dce <sys_unlink+0x1c4>
    iunlockput(ip);
    80005db0:	854a                	mv	a0,s2
    80005db2:	ffffe097          	auipc	ra,0xffffe
    80005db6:	2fa080e7          	jalr	762(ra) # 800040ac <iunlockput>
  iunlockput(dp);
    80005dba:	8526                	mv	a0,s1
    80005dbc:	ffffe097          	auipc	ra,0xffffe
    80005dc0:	2f0080e7          	jalr	752(ra) # 800040ac <iunlockput>
  end_op();
    80005dc4:	fffff097          	auipc	ra,0xfffff
    80005dc8:	ac8080e7          	jalr	-1336(ra) # 8000488c <end_op>
  return -1;
    80005dcc:	557d                	li	a0,-1
}
    80005dce:	70ae                	ld	ra,232(sp)
    80005dd0:	740e                	ld	s0,224(sp)
    80005dd2:	64ee                	ld	s1,216(sp)
    80005dd4:	694e                	ld	s2,208(sp)
    80005dd6:	69ae                	ld	s3,200(sp)
    80005dd8:	616d                	addi	sp,sp,240
    80005dda:	8082                	ret

0000000080005ddc <sys_open>:

uint64
sys_open(void)
{
    80005ddc:	7131                	addi	sp,sp,-192
    80005dde:	fd06                	sd	ra,184(sp)
    80005de0:	f922                	sd	s0,176(sp)
    80005de2:	f526                	sd	s1,168(sp)
    80005de4:	f14a                	sd	s2,160(sp)
    80005de6:	ed4e                	sd	s3,152(sp)
    80005de8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005dea:	f4c40593          	addi	a1,s0,-180
    80005dee:	4505                	li	a0,1
    80005df0:	ffffd097          	auipc	ra,0xffffd
    80005df4:	320080e7          	jalr	800(ra) # 80003110 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005df8:	08000613          	li	a2,128
    80005dfc:	f5040593          	addi	a1,s0,-176
    80005e00:	4501                	li	a0,0
    80005e02:	ffffd097          	auipc	ra,0xffffd
    80005e06:	34e080e7          	jalr	846(ra) # 80003150 <argstr>
    80005e0a:	87aa                	mv	a5,a0
    return -1;
    80005e0c:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005e0e:	0a07c963          	bltz	a5,80005ec0 <sys_open+0xe4>

  begin_op();
    80005e12:	fffff097          	auipc	ra,0xfffff
    80005e16:	9fa080e7          	jalr	-1542(ra) # 8000480c <begin_op>

  if(omode & O_CREATE){
    80005e1a:	f4c42783          	lw	a5,-180(s0)
    80005e1e:	2007f793          	andi	a5,a5,512
    80005e22:	cfc5                	beqz	a5,80005eda <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005e24:	4681                	li	a3,0
    80005e26:	4601                	li	a2,0
    80005e28:	4589                	li	a1,2
    80005e2a:	f5040513          	addi	a0,s0,-176
    80005e2e:	00000097          	auipc	ra,0x0
    80005e32:	974080e7          	jalr	-1676(ra) # 800057a2 <create>
    80005e36:	84aa                	mv	s1,a0
    if(ip == 0){
    80005e38:	c959                	beqz	a0,80005ece <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005e3a:	04449703          	lh	a4,68(s1)
    80005e3e:	478d                	li	a5,3
    80005e40:	00f71763          	bne	a4,a5,80005e4e <sys_open+0x72>
    80005e44:	0464d703          	lhu	a4,70(s1)
    80005e48:	47a5                	li	a5,9
    80005e4a:	0ce7ed63          	bltu	a5,a4,80005f24 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005e4e:	fffff097          	auipc	ra,0xfffff
    80005e52:	dce080e7          	jalr	-562(ra) # 80004c1c <filealloc>
    80005e56:	89aa                	mv	s3,a0
    80005e58:	10050363          	beqz	a0,80005f5e <sys_open+0x182>
    80005e5c:	00000097          	auipc	ra,0x0
    80005e60:	904080e7          	jalr	-1788(ra) # 80005760 <fdalloc>
    80005e64:	892a                	mv	s2,a0
    80005e66:	0e054763          	bltz	a0,80005f54 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005e6a:	04449703          	lh	a4,68(s1)
    80005e6e:	478d                	li	a5,3
    80005e70:	0cf70563          	beq	a4,a5,80005f3a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005e74:	4789                	li	a5,2
    80005e76:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005e7a:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005e7e:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005e82:	f4c42783          	lw	a5,-180(s0)
    80005e86:	0017c713          	xori	a4,a5,1
    80005e8a:	8b05                	andi	a4,a4,1
    80005e8c:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005e90:	0037f713          	andi	a4,a5,3
    80005e94:	00e03733          	snez	a4,a4
    80005e98:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005e9c:	4007f793          	andi	a5,a5,1024
    80005ea0:	c791                	beqz	a5,80005eac <sys_open+0xd0>
    80005ea2:	04449703          	lh	a4,68(s1)
    80005ea6:	4789                	li	a5,2
    80005ea8:	0af70063          	beq	a4,a5,80005f48 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005eac:	8526                	mv	a0,s1
    80005eae:	ffffe097          	auipc	ra,0xffffe
    80005eb2:	05e080e7          	jalr	94(ra) # 80003f0c <iunlock>
  end_op();
    80005eb6:	fffff097          	auipc	ra,0xfffff
    80005eba:	9d6080e7          	jalr	-1578(ra) # 8000488c <end_op>

  return fd;
    80005ebe:	854a                	mv	a0,s2
}
    80005ec0:	70ea                	ld	ra,184(sp)
    80005ec2:	744a                	ld	s0,176(sp)
    80005ec4:	74aa                	ld	s1,168(sp)
    80005ec6:	790a                	ld	s2,160(sp)
    80005ec8:	69ea                	ld	s3,152(sp)
    80005eca:	6129                	addi	sp,sp,192
    80005ecc:	8082                	ret
      end_op();
    80005ece:	fffff097          	auipc	ra,0xfffff
    80005ed2:	9be080e7          	jalr	-1602(ra) # 8000488c <end_op>
      return -1;
    80005ed6:	557d                	li	a0,-1
    80005ed8:	b7e5                	j	80005ec0 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005eda:	f5040513          	addi	a0,s0,-176
    80005ede:	ffffe097          	auipc	ra,0xffffe
    80005ee2:	712080e7          	jalr	1810(ra) # 800045f0 <namei>
    80005ee6:	84aa                	mv	s1,a0
    80005ee8:	c905                	beqz	a0,80005f18 <sys_open+0x13c>
    ilock(ip);
    80005eea:	ffffe097          	auipc	ra,0xffffe
    80005eee:	f60080e7          	jalr	-160(ra) # 80003e4a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005ef2:	04449703          	lh	a4,68(s1)
    80005ef6:	4785                	li	a5,1
    80005ef8:	f4f711e3          	bne	a4,a5,80005e3a <sys_open+0x5e>
    80005efc:	f4c42783          	lw	a5,-180(s0)
    80005f00:	d7b9                	beqz	a5,80005e4e <sys_open+0x72>
      iunlockput(ip);
    80005f02:	8526                	mv	a0,s1
    80005f04:	ffffe097          	auipc	ra,0xffffe
    80005f08:	1a8080e7          	jalr	424(ra) # 800040ac <iunlockput>
      end_op();
    80005f0c:	fffff097          	auipc	ra,0xfffff
    80005f10:	980080e7          	jalr	-1664(ra) # 8000488c <end_op>
      return -1;
    80005f14:	557d                	li	a0,-1
    80005f16:	b76d                	j	80005ec0 <sys_open+0xe4>
      end_op();
    80005f18:	fffff097          	auipc	ra,0xfffff
    80005f1c:	974080e7          	jalr	-1676(ra) # 8000488c <end_op>
      return -1;
    80005f20:	557d                	li	a0,-1
    80005f22:	bf79                	j	80005ec0 <sys_open+0xe4>
    iunlockput(ip);
    80005f24:	8526                	mv	a0,s1
    80005f26:	ffffe097          	auipc	ra,0xffffe
    80005f2a:	186080e7          	jalr	390(ra) # 800040ac <iunlockput>
    end_op();
    80005f2e:	fffff097          	auipc	ra,0xfffff
    80005f32:	95e080e7          	jalr	-1698(ra) # 8000488c <end_op>
    return -1;
    80005f36:	557d                	li	a0,-1
    80005f38:	b761                	j	80005ec0 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005f3a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005f3e:	04649783          	lh	a5,70(s1)
    80005f42:	02f99223          	sh	a5,36(s3)
    80005f46:	bf25                	j	80005e7e <sys_open+0xa2>
    itrunc(ip);
    80005f48:	8526                	mv	a0,s1
    80005f4a:	ffffe097          	auipc	ra,0xffffe
    80005f4e:	00e080e7          	jalr	14(ra) # 80003f58 <itrunc>
    80005f52:	bfa9                	j	80005eac <sys_open+0xd0>
      fileclose(f);
    80005f54:	854e                	mv	a0,s3
    80005f56:	fffff097          	auipc	ra,0xfffff
    80005f5a:	d82080e7          	jalr	-638(ra) # 80004cd8 <fileclose>
    iunlockput(ip);
    80005f5e:	8526                	mv	a0,s1
    80005f60:	ffffe097          	auipc	ra,0xffffe
    80005f64:	14c080e7          	jalr	332(ra) # 800040ac <iunlockput>
    end_op();
    80005f68:	fffff097          	auipc	ra,0xfffff
    80005f6c:	924080e7          	jalr	-1756(ra) # 8000488c <end_op>
    return -1;
    80005f70:	557d                	li	a0,-1
    80005f72:	b7b9                	j	80005ec0 <sys_open+0xe4>

0000000080005f74 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005f74:	7175                	addi	sp,sp,-144
    80005f76:	e506                	sd	ra,136(sp)
    80005f78:	e122                	sd	s0,128(sp)
    80005f7a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005f7c:	fffff097          	auipc	ra,0xfffff
    80005f80:	890080e7          	jalr	-1904(ra) # 8000480c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005f84:	08000613          	li	a2,128
    80005f88:	f7040593          	addi	a1,s0,-144
    80005f8c:	4501                	li	a0,0
    80005f8e:	ffffd097          	auipc	ra,0xffffd
    80005f92:	1c2080e7          	jalr	450(ra) # 80003150 <argstr>
    80005f96:	02054963          	bltz	a0,80005fc8 <sys_mkdir+0x54>
    80005f9a:	4681                	li	a3,0
    80005f9c:	4601                	li	a2,0
    80005f9e:	4585                	li	a1,1
    80005fa0:	f7040513          	addi	a0,s0,-144
    80005fa4:	fffff097          	auipc	ra,0xfffff
    80005fa8:	7fe080e7          	jalr	2046(ra) # 800057a2 <create>
    80005fac:	cd11                	beqz	a0,80005fc8 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005fae:	ffffe097          	auipc	ra,0xffffe
    80005fb2:	0fe080e7          	jalr	254(ra) # 800040ac <iunlockput>
  end_op();
    80005fb6:	fffff097          	auipc	ra,0xfffff
    80005fba:	8d6080e7          	jalr	-1834(ra) # 8000488c <end_op>
  return 0;
    80005fbe:	4501                	li	a0,0
}
    80005fc0:	60aa                	ld	ra,136(sp)
    80005fc2:	640a                	ld	s0,128(sp)
    80005fc4:	6149                	addi	sp,sp,144
    80005fc6:	8082                	ret
    end_op();
    80005fc8:	fffff097          	auipc	ra,0xfffff
    80005fcc:	8c4080e7          	jalr	-1852(ra) # 8000488c <end_op>
    return -1;
    80005fd0:	557d                	li	a0,-1
    80005fd2:	b7fd                	j	80005fc0 <sys_mkdir+0x4c>

0000000080005fd4 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005fd4:	7135                	addi	sp,sp,-160
    80005fd6:	ed06                	sd	ra,152(sp)
    80005fd8:	e922                	sd	s0,144(sp)
    80005fda:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005fdc:	fffff097          	auipc	ra,0xfffff
    80005fe0:	830080e7          	jalr	-2000(ra) # 8000480c <begin_op>
  argint(1, &major);
    80005fe4:	f6c40593          	addi	a1,s0,-148
    80005fe8:	4505                	li	a0,1
    80005fea:	ffffd097          	auipc	ra,0xffffd
    80005fee:	126080e7          	jalr	294(ra) # 80003110 <argint>
  argint(2, &minor);
    80005ff2:	f6840593          	addi	a1,s0,-152
    80005ff6:	4509                	li	a0,2
    80005ff8:	ffffd097          	auipc	ra,0xffffd
    80005ffc:	118080e7          	jalr	280(ra) # 80003110 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006000:	08000613          	li	a2,128
    80006004:	f7040593          	addi	a1,s0,-144
    80006008:	4501                	li	a0,0
    8000600a:	ffffd097          	auipc	ra,0xffffd
    8000600e:	146080e7          	jalr	326(ra) # 80003150 <argstr>
    80006012:	02054b63          	bltz	a0,80006048 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006016:	f6841683          	lh	a3,-152(s0)
    8000601a:	f6c41603          	lh	a2,-148(s0)
    8000601e:	458d                	li	a1,3
    80006020:	f7040513          	addi	a0,s0,-144
    80006024:	fffff097          	auipc	ra,0xfffff
    80006028:	77e080e7          	jalr	1918(ra) # 800057a2 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000602c:	cd11                	beqz	a0,80006048 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000602e:	ffffe097          	auipc	ra,0xffffe
    80006032:	07e080e7          	jalr	126(ra) # 800040ac <iunlockput>
  end_op();
    80006036:	fffff097          	auipc	ra,0xfffff
    8000603a:	856080e7          	jalr	-1962(ra) # 8000488c <end_op>
  return 0;
    8000603e:	4501                	li	a0,0
}
    80006040:	60ea                	ld	ra,152(sp)
    80006042:	644a                	ld	s0,144(sp)
    80006044:	610d                	addi	sp,sp,160
    80006046:	8082                	ret
    end_op();
    80006048:	fffff097          	auipc	ra,0xfffff
    8000604c:	844080e7          	jalr	-1980(ra) # 8000488c <end_op>
    return -1;
    80006050:	557d                	li	a0,-1
    80006052:	b7fd                	j	80006040 <sys_mknod+0x6c>

0000000080006054 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006054:	7135                	addi	sp,sp,-160
    80006056:	ed06                	sd	ra,152(sp)
    80006058:	e922                	sd	s0,144(sp)
    8000605a:	e526                	sd	s1,136(sp)
    8000605c:	e14a                	sd	s2,128(sp)
    8000605e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006060:	ffffc097          	auipc	ra,0xffffc
    80006064:	b54080e7          	jalr	-1196(ra) # 80001bb4 <myproc>
    80006068:	892a                	mv	s2,a0
  
  begin_op();
    8000606a:	ffffe097          	auipc	ra,0xffffe
    8000606e:	7a2080e7          	jalr	1954(ra) # 8000480c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006072:	08000613          	li	a2,128
    80006076:	f6040593          	addi	a1,s0,-160
    8000607a:	4501                	li	a0,0
    8000607c:	ffffd097          	auipc	ra,0xffffd
    80006080:	0d4080e7          	jalr	212(ra) # 80003150 <argstr>
    80006084:	04054b63          	bltz	a0,800060da <sys_chdir+0x86>
    80006088:	f6040513          	addi	a0,s0,-160
    8000608c:	ffffe097          	auipc	ra,0xffffe
    80006090:	564080e7          	jalr	1380(ra) # 800045f0 <namei>
    80006094:	84aa                	mv	s1,a0
    80006096:	c131                	beqz	a0,800060da <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006098:	ffffe097          	auipc	ra,0xffffe
    8000609c:	db2080e7          	jalr	-590(ra) # 80003e4a <ilock>
  if(ip->type != T_DIR){
    800060a0:	04449703          	lh	a4,68(s1)
    800060a4:	4785                	li	a5,1
    800060a6:	04f71063          	bne	a4,a5,800060e6 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800060aa:	8526                	mv	a0,s1
    800060ac:	ffffe097          	auipc	ra,0xffffe
    800060b0:	e60080e7          	jalr	-416(ra) # 80003f0c <iunlock>
  iput(p->cwd);
    800060b4:	15093503          	ld	a0,336(s2)
    800060b8:	ffffe097          	auipc	ra,0xffffe
    800060bc:	f4c080e7          	jalr	-180(ra) # 80004004 <iput>
  end_op();
    800060c0:	ffffe097          	auipc	ra,0xffffe
    800060c4:	7cc080e7          	jalr	1996(ra) # 8000488c <end_op>
  p->cwd = ip;
    800060c8:	14993823          	sd	s1,336(s2)
  return 0;
    800060cc:	4501                	li	a0,0
}
    800060ce:	60ea                	ld	ra,152(sp)
    800060d0:	644a                	ld	s0,144(sp)
    800060d2:	64aa                	ld	s1,136(sp)
    800060d4:	690a                	ld	s2,128(sp)
    800060d6:	610d                	addi	sp,sp,160
    800060d8:	8082                	ret
    end_op();
    800060da:	ffffe097          	auipc	ra,0xffffe
    800060de:	7b2080e7          	jalr	1970(ra) # 8000488c <end_op>
    return -1;
    800060e2:	557d                	li	a0,-1
    800060e4:	b7ed                	j	800060ce <sys_chdir+0x7a>
    iunlockput(ip);
    800060e6:	8526                	mv	a0,s1
    800060e8:	ffffe097          	auipc	ra,0xffffe
    800060ec:	fc4080e7          	jalr	-60(ra) # 800040ac <iunlockput>
    end_op();
    800060f0:	ffffe097          	auipc	ra,0xffffe
    800060f4:	79c080e7          	jalr	1948(ra) # 8000488c <end_op>
    return -1;
    800060f8:	557d                	li	a0,-1
    800060fa:	bfd1                	j	800060ce <sys_chdir+0x7a>

00000000800060fc <sys_exec>:

uint64
sys_exec(void)
{
    800060fc:	7145                	addi	sp,sp,-464
    800060fe:	e786                	sd	ra,456(sp)
    80006100:	e3a2                	sd	s0,448(sp)
    80006102:	ff26                	sd	s1,440(sp)
    80006104:	fb4a                	sd	s2,432(sp)
    80006106:	f74e                	sd	s3,424(sp)
    80006108:	f352                	sd	s4,416(sp)
    8000610a:	ef56                	sd	s5,408(sp)
    8000610c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    8000610e:	e3840593          	addi	a1,s0,-456
    80006112:	4505                	li	a0,1
    80006114:	ffffd097          	auipc	ra,0xffffd
    80006118:	01c080e7          	jalr	28(ra) # 80003130 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    8000611c:	08000613          	li	a2,128
    80006120:	f4040593          	addi	a1,s0,-192
    80006124:	4501                	li	a0,0
    80006126:	ffffd097          	auipc	ra,0xffffd
    8000612a:	02a080e7          	jalr	42(ra) # 80003150 <argstr>
    8000612e:	87aa                	mv	a5,a0
    return -1;
    80006130:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80006132:	0c07c263          	bltz	a5,800061f6 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006136:	10000613          	li	a2,256
    8000613a:	4581                	li	a1,0
    8000613c:	e4040513          	addi	a0,s0,-448
    80006140:	ffffb097          	auipc	ra,0xffffb
    80006144:	ba6080e7          	jalr	-1114(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006148:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000614c:	89a6                	mv	s3,s1
    8000614e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006150:	02000a13          	li	s4,32
    80006154:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006158:	00391513          	slli	a0,s2,0x3
    8000615c:	e3040593          	addi	a1,s0,-464
    80006160:	e3843783          	ld	a5,-456(s0)
    80006164:	953e                	add	a0,a0,a5
    80006166:	ffffd097          	auipc	ra,0xffffd
    8000616a:	f0c080e7          	jalr	-244(ra) # 80003072 <fetchaddr>
    8000616e:	02054a63          	bltz	a0,800061a2 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80006172:	e3043783          	ld	a5,-464(s0)
    80006176:	c3b9                	beqz	a5,800061bc <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006178:	ffffb097          	auipc	ra,0xffffb
    8000617c:	982080e7          	jalr	-1662(ra) # 80000afa <kalloc>
    80006180:	85aa                	mv	a1,a0
    80006182:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006186:	cd11                	beqz	a0,800061a2 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006188:	6605                	lui	a2,0x1
    8000618a:	e3043503          	ld	a0,-464(s0)
    8000618e:	ffffd097          	auipc	ra,0xffffd
    80006192:	f36080e7          	jalr	-202(ra) # 800030c4 <fetchstr>
    80006196:	00054663          	bltz	a0,800061a2 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    8000619a:	0905                	addi	s2,s2,1
    8000619c:	09a1                	addi	s3,s3,8
    8000619e:	fb491be3          	bne	s2,s4,80006154 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061a2:	10048913          	addi	s2,s1,256
    800061a6:	6088                	ld	a0,0(s1)
    800061a8:	c531                	beqz	a0,800061f4 <sys_exec+0xf8>
    kfree(argv[i]);
    800061aa:	ffffb097          	auipc	ra,0xffffb
    800061ae:	854080e7          	jalr	-1964(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061b2:	04a1                	addi	s1,s1,8
    800061b4:	ff2499e3          	bne	s1,s2,800061a6 <sys_exec+0xaa>
  return -1;
    800061b8:	557d                	li	a0,-1
    800061ba:	a835                	j	800061f6 <sys_exec+0xfa>
      argv[i] = 0;
    800061bc:	0a8e                	slli	s5,s5,0x3
    800061be:	fc040793          	addi	a5,s0,-64
    800061c2:	9abe                	add	s5,s5,a5
    800061c4:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800061c8:	e4040593          	addi	a1,s0,-448
    800061cc:	f4040513          	addi	a0,s0,-192
    800061d0:	fffff097          	auipc	ra,0xfffff
    800061d4:	190080e7          	jalr	400(ra) # 80005360 <exec>
    800061d8:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061da:	10048993          	addi	s3,s1,256
    800061de:	6088                	ld	a0,0(s1)
    800061e0:	c901                	beqz	a0,800061f0 <sys_exec+0xf4>
    kfree(argv[i]);
    800061e2:	ffffb097          	auipc	ra,0xffffb
    800061e6:	81c080e7          	jalr	-2020(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061ea:	04a1                	addi	s1,s1,8
    800061ec:	ff3499e3          	bne	s1,s3,800061de <sys_exec+0xe2>
  return ret;
    800061f0:	854a                	mv	a0,s2
    800061f2:	a011                	j	800061f6 <sys_exec+0xfa>
  return -1;
    800061f4:	557d                	li	a0,-1
}
    800061f6:	60be                	ld	ra,456(sp)
    800061f8:	641e                	ld	s0,448(sp)
    800061fa:	74fa                	ld	s1,440(sp)
    800061fc:	795a                	ld	s2,432(sp)
    800061fe:	79ba                	ld	s3,424(sp)
    80006200:	7a1a                	ld	s4,416(sp)
    80006202:	6afa                	ld	s5,408(sp)
    80006204:	6179                	addi	sp,sp,464
    80006206:	8082                	ret

0000000080006208 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006208:	7139                	addi	sp,sp,-64
    8000620a:	fc06                	sd	ra,56(sp)
    8000620c:	f822                	sd	s0,48(sp)
    8000620e:	f426                	sd	s1,40(sp)
    80006210:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006212:	ffffc097          	auipc	ra,0xffffc
    80006216:	9a2080e7          	jalr	-1630(ra) # 80001bb4 <myproc>
    8000621a:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    8000621c:	fd840593          	addi	a1,s0,-40
    80006220:	4501                	li	a0,0
    80006222:	ffffd097          	auipc	ra,0xffffd
    80006226:	f0e080e7          	jalr	-242(ra) # 80003130 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    8000622a:	fc840593          	addi	a1,s0,-56
    8000622e:	fd040513          	addi	a0,s0,-48
    80006232:	fffff097          	auipc	ra,0xfffff
    80006236:	dd6080e7          	jalr	-554(ra) # 80005008 <pipealloc>
    return -1;
    8000623a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000623c:	0c054463          	bltz	a0,80006304 <sys_pipe+0xfc>
  fd0 = -1;
    80006240:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006244:	fd043503          	ld	a0,-48(s0)
    80006248:	fffff097          	auipc	ra,0xfffff
    8000624c:	518080e7          	jalr	1304(ra) # 80005760 <fdalloc>
    80006250:	fca42223          	sw	a0,-60(s0)
    80006254:	08054b63          	bltz	a0,800062ea <sys_pipe+0xe2>
    80006258:	fc843503          	ld	a0,-56(s0)
    8000625c:	fffff097          	auipc	ra,0xfffff
    80006260:	504080e7          	jalr	1284(ra) # 80005760 <fdalloc>
    80006264:	fca42023          	sw	a0,-64(s0)
    80006268:	06054863          	bltz	a0,800062d8 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000626c:	4691                	li	a3,4
    8000626e:	fc440613          	addi	a2,s0,-60
    80006272:	fd843583          	ld	a1,-40(s0)
    80006276:	68a8                	ld	a0,80(s1)
    80006278:	ffffb097          	auipc	ra,0xffffb
    8000627c:	40c080e7          	jalr	1036(ra) # 80001684 <copyout>
    80006280:	02054063          	bltz	a0,800062a0 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006284:	4691                	li	a3,4
    80006286:	fc040613          	addi	a2,s0,-64
    8000628a:	fd843583          	ld	a1,-40(s0)
    8000628e:	0591                	addi	a1,a1,4
    80006290:	68a8                	ld	a0,80(s1)
    80006292:	ffffb097          	auipc	ra,0xffffb
    80006296:	3f2080e7          	jalr	1010(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000629a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000629c:	06055463          	bgez	a0,80006304 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    800062a0:	fc442783          	lw	a5,-60(s0)
    800062a4:	07e9                	addi	a5,a5,26
    800062a6:	078e                	slli	a5,a5,0x3
    800062a8:	97a6                	add	a5,a5,s1
    800062aa:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800062ae:	fc042503          	lw	a0,-64(s0)
    800062b2:	0569                	addi	a0,a0,26
    800062b4:	050e                	slli	a0,a0,0x3
    800062b6:	94aa                	add	s1,s1,a0
    800062b8:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800062bc:	fd043503          	ld	a0,-48(s0)
    800062c0:	fffff097          	auipc	ra,0xfffff
    800062c4:	a18080e7          	jalr	-1512(ra) # 80004cd8 <fileclose>
    fileclose(wf);
    800062c8:	fc843503          	ld	a0,-56(s0)
    800062cc:	fffff097          	auipc	ra,0xfffff
    800062d0:	a0c080e7          	jalr	-1524(ra) # 80004cd8 <fileclose>
    return -1;
    800062d4:	57fd                	li	a5,-1
    800062d6:	a03d                	j	80006304 <sys_pipe+0xfc>
    if(fd0 >= 0)
    800062d8:	fc442783          	lw	a5,-60(s0)
    800062dc:	0007c763          	bltz	a5,800062ea <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    800062e0:	07e9                	addi	a5,a5,26
    800062e2:	078e                	slli	a5,a5,0x3
    800062e4:	94be                	add	s1,s1,a5
    800062e6:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800062ea:	fd043503          	ld	a0,-48(s0)
    800062ee:	fffff097          	auipc	ra,0xfffff
    800062f2:	9ea080e7          	jalr	-1558(ra) # 80004cd8 <fileclose>
    fileclose(wf);
    800062f6:	fc843503          	ld	a0,-56(s0)
    800062fa:	fffff097          	auipc	ra,0xfffff
    800062fe:	9de080e7          	jalr	-1570(ra) # 80004cd8 <fileclose>
    return -1;
    80006302:	57fd                	li	a5,-1
}
    80006304:	853e                	mv	a0,a5
    80006306:	70e2                	ld	ra,56(sp)
    80006308:	7442                	ld	s0,48(sp)
    8000630a:	74a2                	ld	s1,40(sp)
    8000630c:	6121                	addi	sp,sp,64
    8000630e:	8082                	ret

0000000080006310 <kernelvec>:
    80006310:	7111                	addi	sp,sp,-256
    80006312:	e006                	sd	ra,0(sp)
    80006314:	e40a                	sd	sp,8(sp)
    80006316:	e80e                	sd	gp,16(sp)
    80006318:	ec12                	sd	tp,24(sp)
    8000631a:	f016                	sd	t0,32(sp)
    8000631c:	f41a                	sd	t1,40(sp)
    8000631e:	f81e                	sd	t2,48(sp)
    80006320:	fc22                	sd	s0,56(sp)
    80006322:	e0a6                	sd	s1,64(sp)
    80006324:	e4aa                	sd	a0,72(sp)
    80006326:	e8ae                	sd	a1,80(sp)
    80006328:	ecb2                	sd	a2,88(sp)
    8000632a:	f0b6                	sd	a3,96(sp)
    8000632c:	f4ba                	sd	a4,104(sp)
    8000632e:	f8be                	sd	a5,112(sp)
    80006330:	fcc2                	sd	a6,120(sp)
    80006332:	e146                	sd	a7,128(sp)
    80006334:	e54a                	sd	s2,136(sp)
    80006336:	e94e                	sd	s3,144(sp)
    80006338:	ed52                	sd	s4,152(sp)
    8000633a:	f156                	sd	s5,160(sp)
    8000633c:	f55a                	sd	s6,168(sp)
    8000633e:	f95e                	sd	s7,176(sp)
    80006340:	fd62                	sd	s8,184(sp)
    80006342:	e1e6                	sd	s9,192(sp)
    80006344:	e5ea                	sd	s10,200(sp)
    80006346:	e9ee                	sd	s11,208(sp)
    80006348:	edf2                	sd	t3,216(sp)
    8000634a:	f1f6                	sd	t4,224(sp)
    8000634c:	f5fa                	sd	t5,232(sp)
    8000634e:	f9fe                	sd	t6,240(sp)
    80006350:	b85fc0ef          	jal	ra,80002ed4 <kerneltrap>
    80006354:	6082                	ld	ra,0(sp)
    80006356:	6122                	ld	sp,8(sp)
    80006358:	61c2                	ld	gp,16(sp)
    8000635a:	7282                	ld	t0,32(sp)
    8000635c:	7322                	ld	t1,40(sp)
    8000635e:	73c2                	ld	t2,48(sp)
    80006360:	7462                	ld	s0,56(sp)
    80006362:	6486                	ld	s1,64(sp)
    80006364:	6526                	ld	a0,72(sp)
    80006366:	65c6                	ld	a1,80(sp)
    80006368:	6666                	ld	a2,88(sp)
    8000636a:	7686                	ld	a3,96(sp)
    8000636c:	7726                	ld	a4,104(sp)
    8000636e:	77c6                	ld	a5,112(sp)
    80006370:	7866                	ld	a6,120(sp)
    80006372:	688a                	ld	a7,128(sp)
    80006374:	692a                	ld	s2,136(sp)
    80006376:	69ca                	ld	s3,144(sp)
    80006378:	6a6a                	ld	s4,152(sp)
    8000637a:	7a8a                	ld	s5,160(sp)
    8000637c:	7b2a                	ld	s6,168(sp)
    8000637e:	7bca                	ld	s7,176(sp)
    80006380:	7c6a                	ld	s8,184(sp)
    80006382:	6c8e                	ld	s9,192(sp)
    80006384:	6d2e                	ld	s10,200(sp)
    80006386:	6dce                	ld	s11,208(sp)
    80006388:	6e6e                	ld	t3,216(sp)
    8000638a:	7e8e                	ld	t4,224(sp)
    8000638c:	7f2e                	ld	t5,232(sp)
    8000638e:	7fce                	ld	t6,240(sp)
    80006390:	6111                	addi	sp,sp,256
    80006392:	10200073          	sret
    80006396:	00000013          	nop
    8000639a:	00000013          	nop
    8000639e:	0001                	nop

00000000800063a0 <timervec>:
    800063a0:	34051573          	csrrw	a0,mscratch,a0
    800063a4:	e10c                	sd	a1,0(a0)
    800063a6:	e510                	sd	a2,8(a0)
    800063a8:	e914                	sd	a3,16(a0)
    800063aa:	6d0c                	ld	a1,24(a0)
    800063ac:	7110                	ld	a2,32(a0)
    800063ae:	6194                	ld	a3,0(a1)
    800063b0:	96b2                	add	a3,a3,a2
    800063b2:	e194                	sd	a3,0(a1)
    800063b4:	4589                	li	a1,2
    800063b6:	14459073          	csrw	sip,a1
    800063ba:	6914                	ld	a3,16(a0)
    800063bc:	6510                	ld	a2,8(a0)
    800063be:	610c                	ld	a1,0(a0)
    800063c0:	34051573          	csrrw	a0,mscratch,a0
    800063c4:	30200073          	mret
	...

00000000800063ca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800063ca:	1141                	addi	sp,sp,-16
    800063cc:	e422                	sd	s0,8(sp)
    800063ce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800063d0:	0c0007b7          	lui	a5,0xc000
    800063d4:	4705                	li	a4,1
    800063d6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800063d8:	c3d8                	sw	a4,4(a5)
}
    800063da:	6422                	ld	s0,8(sp)
    800063dc:	0141                	addi	sp,sp,16
    800063de:	8082                	ret

00000000800063e0 <plicinithart>:

void
plicinithart(void)
{
    800063e0:	1141                	addi	sp,sp,-16
    800063e2:	e406                	sd	ra,8(sp)
    800063e4:	e022                	sd	s0,0(sp)
    800063e6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800063e8:	ffffb097          	auipc	ra,0xffffb
    800063ec:	7a0080e7          	jalr	1952(ra) # 80001b88 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800063f0:	0085171b          	slliw	a4,a0,0x8
    800063f4:	0c0027b7          	lui	a5,0xc002
    800063f8:	97ba                	add	a5,a5,a4
    800063fa:	40200713          	li	a4,1026
    800063fe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006402:	00d5151b          	slliw	a0,a0,0xd
    80006406:	0c2017b7          	lui	a5,0xc201
    8000640a:	953e                	add	a0,a0,a5
    8000640c:	00052023          	sw	zero,0(a0)
}
    80006410:	60a2                	ld	ra,8(sp)
    80006412:	6402                	ld	s0,0(sp)
    80006414:	0141                	addi	sp,sp,16
    80006416:	8082                	ret

0000000080006418 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006418:	1141                	addi	sp,sp,-16
    8000641a:	e406                	sd	ra,8(sp)
    8000641c:	e022                	sd	s0,0(sp)
    8000641e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006420:	ffffb097          	auipc	ra,0xffffb
    80006424:	768080e7          	jalr	1896(ra) # 80001b88 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006428:	00d5179b          	slliw	a5,a0,0xd
    8000642c:	0c201537          	lui	a0,0xc201
    80006430:	953e                	add	a0,a0,a5
  return irq;
}
    80006432:	4148                	lw	a0,4(a0)
    80006434:	60a2                	ld	ra,8(sp)
    80006436:	6402                	ld	s0,0(sp)
    80006438:	0141                	addi	sp,sp,16
    8000643a:	8082                	ret

000000008000643c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000643c:	1101                	addi	sp,sp,-32
    8000643e:	ec06                	sd	ra,24(sp)
    80006440:	e822                	sd	s0,16(sp)
    80006442:	e426                	sd	s1,8(sp)
    80006444:	1000                	addi	s0,sp,32
    80006446:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006448:	ffffb097          	auipc	ra,0xffffb
    8000644c:	740080e7          	jalr	1856(ra) # 80001b88 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006450:	00d5151b          	slliw	a0,a0,0xd
    80006454:	0c2017b7          	lui	a5,0xc201
    80006458:	97aa                	add	a5,a5,a0
    8000645a:	c3c4                	sw	s1,4(a5)
}
    8000645c:	60e2                	ld	ra,24(sp)
    8000645e:	6442                	ld	s0,16(sp)
    80006460:	64a2                	ld	s1,8(sp)
    80006462:	6105                	addi	sp,sp,32
    80006464:	8082                	ret

0000000080006466 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006466:	1141                	addi	sp,sp,-16
    80006468:	e406                	sd	ra,8(sp)
    8000646a:	e022                	sd	s0,0(sp)
    8000646c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000646e:	479d                	li	a5,7
    80006470:	04a7cc63          	blt	a5,a0,800064c8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006474:	0001d797          	auipc	a5,0x1d
    80006478:	44478793          	addi	a5,a5,1092 # 800238b8 <disk>
    8000647c:	97aa                	add	a5,a5,a0
    8000647e:	0187c783          	lbu	a5,24(a5)
    80006482:	ebb9                	bnez	a5,800064d8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006484:	00451613          	slli	a2,a0,0x4
    80006488:	0001d797          	auipc	a5,0x1d
    8000648c:	43078793          	addi	a5,a5,1072 # 800238b8 <disk>
    80006490:	6394                	ld	a3,0(a5)
    80006492:	96b2                	add	a3,a3,a2
    80006494:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006498:	6398                	ld	a4,0(a5)
    8000649a:	9732                	add	a4,a4,a2
    8000649c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800064a0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800064a4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800064a8:	953e                	add	a0,a0,a5
    800064aa:	4785                	li	a5,1
    800064ac:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    800064b0:	0001d517          	auipc	a0,0x1d
    800064b4:	42050513          	addi	a0,a0,1056 # 800238d0 <disk+0x18>
    800064b8:	ffffc097          	auipc	ra,0xffffc
    800064bc:	0e8080e7          	jalr	232(ra) # 800025a0 <wakeup>
}
    800064c0:	60a2                	ld	ra,8(sp)
    800064c2:	6402                	ld	s0,0(sp)
    800064c4:	0141                	addi	sp,sp,16
    800064c6:	8082                	ret
    panic("free_desc 1");
    800064c8:	00002517          	auipc	a0,0x2
    800064cc:	3a050513          	addi	a0,a0,928 # 80008868 <syscalls+0x318>
    800064d0:	ffffa097          	auipc	ra,0xffffa
    800064d4:	074080e7          	jalr	116(ra) # 80000544 <panic>
    panic("free_desc 2");
    800064d8:	00002517          	auipc	a0,0x2
    800064dc:	3a050513          	addi	a0,a0,928 # 80008878 <syscalls+0x328>
    800064e0:	ffffa097          	auipc	ra,0xffffa
    800064e4:	064080e7          	jalr	100(ra) # 80000544 <panic>

00000000800064e8 <virtio_disk_init>:
{
    800064e8:	1101                	addi	sp,sp,-32
    800064ea:	ec06                	sd	ra,24(sp)
    800064ec:	e822                	sd	s0,16(sp)
    800064ee:	e426                	sd	s1,8(sp)
    800064f0:	e04a                	sd	s2,0(sp)
    800064f2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800064f4:	00002597          	auipc	a1,0x2
    800064f8:	39458593          	addi	a1,a1,916 # 80008888 <syscalls+0x338>
    800064fc:	0001d517          	auipc	a0,0x1d
    80006500:	4e450513          	addi	a0,a0,1252 # 800239e0 <disk+0x128>
    80006504:	ffffa097          	auipc	ra,0xffffa
    80006508:	656080e7          	jalr	1622(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000650c:	100017b7          	lui	a5,0x10001
    80006510:	4398                	lw	a4,0(a5)
    80006512:	2701                	sext.w	a4,a4
    80006514:	747277b7          	lui	a5,0x74727
    80006518:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000651c:	14f71e63          	bne	a4,a5,80006678 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006520:	100017b7          	lui	a5,0x10001
    80006524:	43dc                	lw	a5,4(a5)
    80006526:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006528:	4709                	li	a4,2
    8000652a:	14e79763          	bne	a5,a4,80006678 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000652e:	100017b7          	lui	a5,0x10001
    80006532:	479c                	lw	a5,8(a5)
    80006534:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006536:	14e79163          	bne	a5,a4,80006678 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000653a:	100017b7          	lui	a5,0x10001
    8000653e:	47d8                	lw	a4,12(a5)
    80006540:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006542:	554d47b7          	lui	a5,0x554d4
    80006546:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000654a:	12f71763          	bne	a4,a5,80006678 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000654e:	100017b7          	lui	a5,0x10001
    80006552:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006556:	4705                	li	a4,1
    80006558:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000655a:	470d                	li	a4,3
    8000655c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000655e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006560:	c7ffe737          	lui	a4,0xc7ffe
    80006564:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd99e7>
    80006568:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000656a:	2701                	sext.w	a4,a4
    8000656c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000656e:	472d                	li	a4,11
    80006570:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006572:	0707a903          	lw	s2,112(a5)
    80006576:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006578:	00897793          	andi	a5,s2,8
    8000657c:	10078663          	beqz	a5,80006688 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006580:	100017b7          	lui	a5,0x10001
    80006584:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006588:	43fc                	lw	a5,68(a5)
    8000658a:	2781                	sext.w	a5,a5
    8000658c:	10079663          	bnez	a5,80006698 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006590:	100017b7          	lui	a5,0x10001
    80006594:	5bdc                	lw	a5,52(a5)
    80006596:	2781                	sext.w	a5,a5
  if(max == 0)
    80006598:	10078863          	beqz	a5,800066a8 <virtio_disk_init+0x1c0>
  if(max < NUM)
    8000659c:	471d                	li	a4,7
    8000659e:	10f77d63          	bgeu	a4,a5,800066b8 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    800065a2:	ffffa097          	auipc	ra,0xffffa
    800065a6:	558080e7          	jalr	1368(ra) # 80000afa <kalloc>
    800065aa:	0001d497          	auipc	s1,0x1d
    800065ae:	30e48493          	addi	s1,s1,782 # 800238b8 <disk>
    800065b2:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800065b4:	ffffa097          	auipc	ra,0xffffa
    800065b8:	546080e7          	jalr	1350(ra) # 80000afa <kalloc>
    800065bc:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800065be:	ffffa097          	auipc	ra,0xffffa
    800065c2:	53c080e7          	jalr	1340(ra) # 80000afa <kalloc>
    800065c6:	87aa                	mv	a5,a0
    800065c8:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800065ca:	6088                	ld	a0,0(s1)
    800065cc:	cd75                	beqz	a0,800066c8 <virtio_disk_init+0x1e0>
    800065ce:	0001d717          	auipc	a4,0x1d
    800065d2:	2f273703          	ld	a4,754(a4) # 800238c0 <disk+0x8>
    800065d6:	cb6d                	beqz	a4,800066c8 <virtio_disk_init+0x1e0>
    800065d8:	cbe5                	beqz	a5,800066c8 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    800065da:	6605                	lui	a2,0x1
    800065dc:	4581                	li	a1,0
    800065de:	ffffa097          	auipc	ra,0xffffa
    800065e2:	708080e7          	jalr	1800(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    800065e6:	0001d497          	auipc	s1,0x1d
    800065ea:	2d248493          	addi	s1,s1,722 # 800238b8 <disk>
    800065ee:	6605                	lui	a2,0x1
    800065f0:	4581                	li	a1,0
    800065f2:	6488                	ld	a0,8(s1)
    800065f4:	ffffa097          	auipc	ra,0xffffa
    800065f8:	6f2080e7          	jalr	1778(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    800065fc:	6605                	lui	a2,0x1
    800065fe:	4581                	li	a1,0
    80006600:	6888                	ld	a0,16(s1)
    80006602:	ffffa097          	auipc	ra,0xffffa
    80006606:	6e4080e7          	jalr	1764(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000660a:	100017b7          	lui	a5,0x10001
    8000660e:	4721                	li	a4,8
    80006610:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006612:	4098                	lw	a4,0(s1)
    80006614:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006618:	40d8                	lw	a4,4(s1)
    8000661a:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000661e:	6498                	ld	a4,8(s1)
    80006620:	0007069b          	sext.w	a3,a4
    80006624:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006628:	9701                	srai	a4,a4,0x20
    8000662a:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000662e:	6898                	ld	a4,16(s1)
    80006630:	0007069b          	sext.w	a3,a4
    80006634:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006638:	9701                	srai	a4,a4,0x20
    8000663a:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000663e:	4685                	li	a3,1
    80006640:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80006642:	4705                	li	a4,1
    80006644:	00d48c23          	sb	a3,24(s1)
    80006648:	00e48ca3          	sb	a4,25(s1)
    8000664c:	00e48d23          	sb	a4,26(s1)
    80006650:	00e48da3          	sb	a4,27(s1)
    80006654:	00e48e23          	sb	a4,28(s1)
    80006658:	00e48ea3          	sb	a4,29(s1)
    8000665c:	00e48f23          	sb	a4,30(s1)
    80006660:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006664:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006668:	0727a823          	sw	s2,112(a5)
}
    8000666c:	60e2                	ld	ra,24(sp)
    8000666e:	6442                	ld	s0,16(sp)
    80006670:	64a2                	ld	s1,8(sp)
    80006672:	6902                	ld	s2,0(sp)
    80006674:	6105                	addi	sp,sp,32
    80006676:	8082                	ret
    panic("could not find virtio disk");
    80006678:	00002517          	auipc	a0,0x2
    8000667c:	22050513          	addi	a0,a0,544 # 80008898 <syscalls+0x348>
    80006680:	ffffa097          	auipc	ra,0xffffa
    80006684:	ec4080e7          	jalr	-316(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006688:	00002517          	auipc	a0,0x2
    8000668c:	23050513          	addi	a0,a0,560 # 800088b8 <syscalls+0x368>
    80006690:	ffffa097          	auipc	ra,0xffffa
    80006694:	eb4080e7          	jalr	-332(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80006698:	00002517          	auipc	a0,0x2
    8000669c:	24050513          	addi	a0,a0,576 # 800088d8 <syscalls+0x388>
    800066a0:	ffffa097          	auipc	ra,0xffffa
    800066a4:	ea4080e7          	jalr	-348(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    800066a8:	00002517          	auipc	a0,0x2
    800066ac:	25050513          	addi	a0,a0,592 # 800088f8 <syscalls+0x3a8>
    800066b0:	ffffa097          	auipc	ra,0xffffa
    800066b4:	e94080e7          	jalr	-364(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    800066b8:	00002517          	auipc	a0,0x2
    800066bc:	26050513          	addi	a0,a0,608 # 80008918 <syscalls+0x3c8>
    800066c0:	ffffa097          	auipc	ra,0xffffa
    800066c4:	e84080e7          	jalr	-380(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    800066c8:	00002517          	auipc	a0,0x2
    800066cc:	27050513          	addi	a0,a0,624 # 80008938 <syscalls+0x3e8>
    800066d0:	ffffa097          	auipc	ra,0xffffa
    800066d4:	e74080e7          	jalr	-396(ra) # 80000544 <panic>

00000000800066d8 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800066d8:	7159                	addi	sp,sp,-112
    800066da:	f486                	sd	ra,104(sp)
    800066dc:	f0a2                	sd	s0,96(sp)
    800066de:	eca6                	sd	s1,88(sp)
    800066e0:	e8ca                	sd	s2,80(sp)
    800066e2:	e4ce                	sd	s3,72(sp)
    800066e4:	e0d2                	sd	s4,64(sp)
    800066e6:	fc56                	sd	s5,56(sp)
    800066e8:	f85a                	sd	s6,48(sp)
    800066ea:	f45e                	sd	s7,40(sp)
    800066ec:	f062                	sd	s8,32(sp)
    800066ee:	ec66                	sd	s9,24(sp)
    800066f0:	e86a                	sd	s10,16(sp)
    800066f2:	1880                	addi	s0,sp,112
    800066f4:	892a                	mv	s2,a0
    800066f6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800066f8:	00c52c83          	lw	s9,12(a0)
    800066fc:	001c9c9b          	slliw	s9,s9,0x1
    80006700:	1c82                	slli	s9,s9,0x20
    80006702:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006706:	0001d517          	auipc	a0,0x1d
    8000670a:	2da50513          	addi	a0,a0,730 # 800239e0 <disk+0x128>
    8000670e:	ffffa097          	auipc	ra,0xffffa
    80006712:	4dc080e7          	jalr	1244(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    80006716:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006718:	4ba1                	li	s7,8
      disk.free[i] = 0;
    8000671a:	0001db17          	auipc	s6,0x1d
    8000671e:	19eb0b13          	addi	s6,s6,414 # 800238b8 <disk>
  for(int i = 0; i < 3; i++){
    80006722:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006724:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006726:	0001dc17          	auipc	s8,0x1d
    8000672a:	2bac0c13          	addi	s8,s8,698 # 800239e0 <disk+0x128>
    8000672e:	a8b5                	j	800067aa <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    80006730:	00fb06b3          	add	a3,s6,a5
    80006734:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006738:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000673a:	0207c563          	bltz	a5,80006764 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000673e:	2485                	addiw	s1,s1,1
    80006740:	0711                	addi	a4,a4,4
    80006742:	1f548a63          	beq	s1,s5,80006936 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    80006746:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006748:	0001d697          	auipc	a3,0x1d
    8000674c:	17068693          	addi	a3,a3,368 # 800238b8 <disk>
    80006750:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006752:	0186c583          	lbu	a1,24(a3)
    80006756:	fde9                	bnez	a1,80006730 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006758:	2785                	addiw	a5,a5,1
    8000675a:	0685                	addi	a3,a3,1
    8000675c:	ff779be3          	bne	a5,s7,80006752 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006760:	57fd                	li	a5,-1
    80006762:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006764:	02905a63          	blez	s1,80006798 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006768:	f9042503          	lw	a0,-112(s0)
    8000676c:	00000097          	auipc	ra,0x0
    80006770:	cfa080e7          	jalr	-774(ra) # 80006466 <free_desc>
      for(int j = 0; j < i; j++)
    80006774:	4785                	li	a5,1
    80006776:	0297d163          	bge	a5,s1,80006798 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000677a:	f9442503          	lw	a0,-108(s0)
    8000677e:	00000097          	auipc	ra,0x0
    80006782:	ce8080e7          	jalr	-792(ra) # 80006466 <free_desc>
      for(int j = 0; j < i; j++)
    80006786:	4789                	li	a5,2
    80006788:	0097d863          	bge	a5,s1,80006798 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000678c:	f9842503          	lw	a0,-104(s0)
    80006790:	00000097          	auipc	ra,0x0
    80006794:	cd6080e7          	jalr	-810(ra) # 80006466 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006798:	85e2                	mv	a1,s8
    8000679a:	0001d517          	auipc	a0,0x1d
    8000679e:	13650513          	addi	a0,a0,310 # 800238d0 <disk+0x18>
    800067a2:	ffffc097          	auipc	ra,0xffffc
    800067a6:	c56080e7          	jalr	-938(ra) # 800023f8 <sleep>
  for(int i = 0; i < 3; i++){
    800067aa:	f9040713          	addi	a4,s0,-112
    800067ae:	84ce                	mv	s1,s3
    800067b0:	bf59                	j	80006746 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800067b2:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    800067b6:	00479693          	slli	a3,a5,0x4
    800067ba:	0001d797          	auipc	a5,0x1d
    800067be:	0fe78793          	addi	a5,a5,254 # 800238b8 <disk>
    800067c2:	97b6                	add	a5,a5,a3
    800067c4:	4685                	li	a3,1
    800067c6:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800067c8:	0001d597          	auipc	a1,0x1d
    800067cc:	0f058593          	addi	a1,a1,240 # 800238b8 <disk>
    800067d0:	00a60793          	addi	a5,a2,10
    800067d4:	0792                	slli	a5,a5,0x4
    800067d6:	97ae                	add	a5,a5,a1
    800067d8:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    800067dc:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800067e0:	f6070693          	addi	a3,a4,-160
    800067e4:	619c                	ld	a5,0(a1)
    800067e6:	97b6                	add	a5,a5,a3
    800067e8:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800067ea:	6188                	ld	a0,0(a1)
    800067ec:	96aa                	add	a3,a3,a0
    800067ee:	47c1                	li	a5,16
    800067f0:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800067f2:	4785                	li	a5,1
    800067f4:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    800067f8:	f9442783          	lw	a5,-108(s0)
    800067fc:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006800:	0792                	slli	a5,a5,0x4
    80006802:	953e                	add	a0,a0,a5
    80006804:	05890693          	addi	a3,s2,88
    80006808:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000680a:	6188                	ld	a0,0(a1)
    8000680c:	97aa                	add	a5,a5,a0
    8000680e:	40000693          	li	a3,1024
    80006812:	c794                	sw	a3,8(a5)
  if(write)
    80006814:	100d0d63          	beqz	s10,8000692e <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006818:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000681c:	00c7d683          	lhu	a3,12(a5)
    80006820:	0016e693          	ori	a3,a3,1
    80006824:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    80006828:	f9842583          	lw	a1,-104(s0)
    8000682c:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006830:	0001d697          	auipc	a3,0x1d
    80006834:	08868693          	addi	a3,a3,136 # 800238b8 <disk>
    80006838:	00260793          	addi	a5,a2,2
    8000683c:	0792                	slli	a5,a5,0x4
    8000683e:	97b6                	add	a5,a5,a3
    80006840:	587d                	li	a6,-1
    80006842:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006846:	0592                	slli	a1,a1,0x4
    80006848:	952e                	add	a0,a0,a1
    8000684a:	f9070713          	addi	a4,a4,-112
    8000684e:	9736                	add	a4,a4,a3
    80006850:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    80006852:	6298                	ld	a4,0(a3)
    80006854:	972e                	add	a4,a4,a1
    80006856:	4585                	li	a1,1
    80006858:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000685a:	4509                	li	a0,2
    8000685c:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    80006860:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006864:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006868:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    8000686c:	6698                	ld	a4,8(a3)
    8000686e:	00275783          	lhu	a5,2(a4)
    80006872:	8b9d                	andi	a5,a5,7
    80006874:	0786                	slli	a5,a5,0x1
    80006876:	97ba                	add	a5,a5,a4
    80006878:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    8000687c:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006880:	6698                	ld	a4,8(a3)
    80006882:	00275783          	lhu	a5,2(a4)
    80006886:	2785                	addiw	a5,a5,1
    80006888:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    8000688c:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006890:	100017b7          	lui	a5,0x10001
    80006894:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006898:	00492703          	lw	a4,4(s2)
    8000689c:	4785                	li	a5,1
    8000689e:	02f71163          	bne	a4,a5,800068c0 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    800068a2:	0001d997          	auipc	s3,0x1d
    800068a6:	13e98993          	addi	s3,s3,318 # 800239e0 <disk+0x128>
  while(b->disk == 1) {
    800068aa:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800068ac:	85ce                	mv	a1,s3
    800068ae:	854a                	mv	a0,s2
    800068b0:	ffffc097          	auipc	ra,0xffffc
    800068b4:	b48080e7          	jalr	-1208(ra) # 800023f8 <sleep>
  while(b->disk == 1) {
    800068b8:	00492783          	lw	a5,4(s2)
    800068bc:	fe9788e3          	beq	a5,s1,800068ac <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    800068c0:	f9042903          	lw	s2,-112(s0)
    800068c4:	00290793          	addi	a5,s2,2
    800068c8:	00479713          	slli	a4,a5,0x4
    800068cc:	0001d797          	auipc	a5,0x1d
    800068d0:	fec78793          	addi	a5,a5,-20 # 800238b8 <disk>
    800068d4:	97ba                	add	a5,a5,a4
    800068d6:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800068da:	0001d997          	auipc	s3,0x1d
    800068de:	fde98993          	addi	s3,s3,-34 # 800238b8 <disk>
    800068e2:	00491713          	slli	a4,s2,0x4
    800068e6:	0009b783          	ld	a5,0(s3)
    800068ea:	97ba                	add	a5,a5,a4
    800068ec:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800068f0:	854a                	mv	a0,s2
    800068f2:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800068f6:	00000097          	auipc	ra,0x0
    800068fa:	b70080e7          	jalr	-1168(ra) # 80006466 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800068fe:	8885                	andi	s1,s1,1
    80006900:	f0ed                	bnez	s1,800068e2 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006902:	0001d517          	auipc	a0,0x1d
    80006906:	0de50513          	addi	a0,a0,222 # 800239e0 <disk+0x128>
    8000690a:	ffffa097          	auipc	ra,0xffffa
    8000690e:	394080e7          	jalr	916(ra) # 80000c9e <release>
}
    80006912:	70a6                	ld	ra,104(sp)
    80006914:	7406                	ld	s0,96(sp)
    80006916:	64e6                	ld	s1,88(sp)
    80006918:	6946                	ld	s2,80(sp)
    8000691a:	69a6                	ld	s3,72(sp)
    8000691c:	6a06                	ld	s4,64(sp)
    8000691e:	7ae2                	ld	s5,56(sp)
    80006920:	7b42                	ld	s6,48(sp)
    80006922:	7ba2                	ld	s7,40(sp)
    80006924:	7c02                	ld	s8,32(sp)
    80006926:	6ce2                	ld	s9,24(sp)
    80006928:	6d42                	ld	s10,16(sp)
    8000692a:	6165                	addi	sp,sp,112
    8000692c:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000692e:	4689                	li	a3,2
    80006930:	00d79623          	sh	a3,12(a5)
    80006934:	b5e5                	j	8000681c <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006936:	f9042603          	lw	a2,-112(s0)
    8000693a:	00a60713          	addi	a4,a2,10
    8000693e:	0712                	slli	a4,a4,0x4
    80006940:	0001d517          	auipc	a0,0x1d
    80006944:	f8050513          	addi	a0,a0,-128 # 800238c0 <disk+0x8>
    80006948:	953a                	add	a0,a0,a4
  if(write)
    8000694a:	e60d14e3          	bnez	s10,800067b2 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    8000694e:	00a60793          	addi	a5,a2,10
    80006952:	00479693          	slli	a3,a5,0x4
    80006956:	0001d797          	auipc	a5,0x1d
    8000695a:	f6278793          	addi	a5,a5,-158 # 800238b8 <disk>
    8000695e:	97b6                	add	a5,a5,a3
    80006960:	0007a423          	sw	zero,8(a5)
    80006964:	b595                	j	800067c8 <virtio_disk_rw+0xf0>

0000000080006966 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006966:	1101                	addi	sp,sp,-32
    80006968:	ec06                	sd	ra,24(sp)
    8000696a:	e822                	sd	s0,16(sp)
    8000696c:	e426                	sd	s1,8(sp)
    8000696e:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006970:	0001d497          	auipc	s1,0x1d
    80006974:	f4848493          	addi	s1,s1,-184 # 800238b8 <disk>
    80006978:	0001d517          	auipc	a0,0x1d
    8000697c:	06850513          	addi	a0,a0,104 # 800239e0 <disk+0x128>
    80006980:	ffffa097          	auipc	ra,0xffffa
    80006984:	26a080e7          	jalr	618(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006988:	10001737          	lui	a4,0x10001
    8000698c:	533c                	lw	a5,96(a4)
    8000698e:	8b8d                	andi	a5,a5,3
    80006990:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006992:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006996:	689c                	ld	a5,16(s1)
    80006998:	0204d703          	lhu	a4,32(s1)
    8000699c:	0027d783          	lhu	a5,2(a5)
    800069a0:	04f70863          	beq	a4,a5,800069f0 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800069a4:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800069a8:	6898                	ld	a4,16(s1)
    800069aa:	0204d783          	lhu	a5,32(s1)
    800069ae:	8b9d                	andi	a5,a5,7
    800069b0:	078e                	slli	a5,a5,0x3
    800069b2:	97ba                	add	a5,a5,a4
    800069b4:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800069b6:	00278713          	addi	a4,a5,2
    800069ba:	0712                	slli	a4,a4,0x4
    800069bc:	9726                	add	a4,a4,s1
    800069be:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800069c2:	e721                	bnez	a4,80006a0a <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800069c4:	0789                	addi	a5,a5,2
    800069c6:	0792                	slli	a5,a5,0x4
    800069c8:	97a6                	add	a5,a5,s1
    800069ca:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800069cc:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800069d0:	ffffc097          	auipc	ra,0xffffc
    800069d4:	bd0080e7          	jalr	-1072(ra) # 800025a0 <wakeup>

    disk.used_idx += 1;
    800069d8:	0204d783          	lhu	a5,32(s1)
    800069dc:	2785                	addiw	a5,a5,1
    800069de:	17c2                	slli	a5,a5,0x30
    800069e0:	93c1                	srli	a5,a5,0x30
    800069e2:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800069e6:	6898                	ld	a4,16(s1)
    800069e8:	00275703          	lhu	a4,2(a4)
    800069ec:	faf71ce3          	bne	a4,a5,800069a4 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800069f0:	0001d517          	auipc	a0,0x1d
    800069f4:	ff050513          	addi	a0,a0,-16 # 800239e0 <disk+0x128>
    800069f8:	ffffa097          	auipc	ra,0xffffa
    800069fc:	2a6080e7          	jalr	678(ra) # 80000c9e <release>
}
    80006a00:	60e2                	ld	ra,24(sp)
    80006a02:	6442                	ld	s0,16(sp)
    80006a04:	64a2                	ld	s1,8(sp)
    80006a06:	6105                	addi	sp,sp,32
    80006a08:	8082                	ret
      panic("virtio_disk_intr status");
    80006a0a:	00002517          	auipc	a0,0x2
    80006a0e:	f4650513          	addi	a0,a0,-186 # 80008950 <syscalls+0x400>
    80006a12:	ffffa097          	auipc	ra,0xffffa
    80006a16:	b32080e7          	jalr	-1230(ra) # 80000544 <panic>

0000000080006a1a <sgenrand>:
static int mti=N+1; /* mti==N+1 means mt[N] is not initialized */

/* initializing the array with a NONZERO seed */
void
sgenrand(unsigned long seed)
{
    80006a1a:	1141                	addi	sp,sp,-16
    80006a1c:	e422                	sd	s0,8(sp)
    80006a1e:	0800                	addi	s0,sp,16
    /* setting initial seeds to mt[N] using         */
    /* the generator Line 25 of Table 1 in          */
    /* [KNUTH 1981, The Art of Computer Programming */
    /*    Vol. 2 (2nd Ed.), pp102]                  */
    mt[0]= seed & 0xffffffff;
    80006a20:	0001d717          	auipc	a4,0x1d
    80006a24:	fd870713          	addi	a4,a4,-40 # 800239f8 <mt>
    80006a28:	1502                	slli	a0,a0,0x20
    80006a2a:	9101                	srli	a0,a0,0x20
    80006a2c:	e308                	sd	a0,0(a4)
    for (mti=1; mti<N; mti++)
    80006a2e:	0001e597          	auipc	a1,0x1e
    80006a32:	34258593          	addi	a1,a1,834 # 80024d70 <mt+0x1378>
        mt[mti] = (69069 * mt[mti-1]) & 0xffffffff;
    80006a36:	6645                	lui	a2,0x11
    80006a38:	dcd60613          	addi	a2,a2,-563 # 10dcd <_entry-0x7ffef233>
    80006a3c:	56fd                	li	a3,-1
    80006a3e:	9281                	srli	a3,a3,0x20
    80006a40:	631c                	ld	a5,0(a4)
    80006a42:	02c787b3          	mul	a5,a5,a2
    80006a46:	8ff5                	and	a5,a5,a3
    80006a48:	e71c                	sd	a5,8(a4)
    for (mti=1; mti<N; mti++)
    80006a4a:	0721                	addi	a4,a4,8
    80006a4c:	feb71ae3          	bne	a4,a1,80006a40 <sgenrand+0x26>
    80006a50:	27000793          	li	a5,624
    80006a54:	00002717          	auipc	a4,0x2
    80006a58:	f2f72a23          	sw	a5,-204(a4) # 80008988 <mti>
}
    80006a5c:	6422                	ld	s0,8(sp)
    80006a5e:	0141                	addi	sp,sp,16
    80006a60:	8082                	ret

0000000080006a62 <genrand>:

long /* for integer generation */
genrand()
{
    80006a62:	1141                	addi	sp,sp,-16
    80006a64:	e406                	sd	ra,8(sp)
    80006a66:	e022                	sd	s0,0(sp)
    80006a68:	0800                	addi	s0,sp,16
    unsigned long y;
    static unsigned long mag01[2]={0x0, MATRIX_A};
    /* mag01[x] = x * MATRIX_A  for x=0,1 */

    if (mti >= N) { /* generate N words at one time */
    80006a6a:	00002797          	auipc	a5,0x2
    80006a6e:	f1e7a783          	lw	a5,-226(a5) # 80008988 <mti>
    80006a72:	26f00713          	li	a4,623
    80006a76:	0ef75963          	bge	a4,a5,80006b68 <genrand+0x106>
        int kk;

        if (mti == N+1)   /* if sgenrand() has not been called, */
    80006a7a:	27100713          	li	a4,625
    80006a7e:	12e78f63          	beq	a5,a4,80006bbc <genrand+0x15a>
            sgenrand(4357); /* a default initial seed is used   */

        for (kk=0;kk<N-M;kk++) {
    80006a82:	0001d817          	auipc	a6,0x1d
    80006a86:	f7680813          	addi	a6,a6,-138 # 800239f8 <mt>
    80006a8a:	0001de17          	auipc	t3,0x1d
    80006a8e:	686e0e13          	addi	t3,t3,1670 # 80024110 <mt+0x718>
{
    80006a92:	8742                	mv	a4,a6
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    80006a94:	4885                	li	a7,1
    80006a96:	08fe                	slli	a7,a7,0x1f
    80006a98:	80000537          	lui	a0,0x80000
    80006a9c:	fff54513          	not	a0,a0
            mt[kk] = mt[kk+M] ^ (y >> 1) ^ mag01[y & 0x1];
    80006aa0:	6585                	lui	a1,0x1
    80006aa2:	c6858593          	addi	a1,a1,-920 # c68 <_entry-0x7ffff398>
    80006aa6:	00002317          	auipc	t1,0x2
    80006aaa:	ec230313          	addi	t1,t1,-318 # 80008968 <mag01.985>
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    80006aae:	631c                	ld	a5,0(a4)
    80006ab0:	0117f7b3          	and	a5,a5,a7
    80006ab4:	6714                	ld	a3,8(a4)
    80006ab6:	8ee9                	and	a3,a3,a0
    80006ab8:	8fd5                	or	a5,a5,a3
            mt[kk] = mt[kk+M] ^ (y >> 1) ^ mag01[y & 0x1];
    80006aba:	00b70633          	add	a2,a4,a1
    80006abe:	0017d693          	srli	a3,a5,0x1
    80006ac2:	6210                	ld	a2,0(a2)
    80006ac4:	8eb1                	xor	a3,a3,a2
    80006ac6:	8b85                	andi	a5,a5,1
    80006ac8:	078e                	slli	a5,a5,0x3
    80006aca:	979a                	add	a5,a5,t1
    80006acc:	639c                	ld	a5,0(a5)
    80006ace:	8fb5                	xor	a5,a5,a3
    80006ad0:	e31c                	sd	a5,0(a4)
        for (kk=0;kk<N-M;kk++) {
    80006ad2:	0721                	addi	a4,a4,8
    80006ad4:	fdc71de3          	bne	a4,t3,80006aae <genrand+0x4c>
        }
        for (;kk<N-1;kk++) {
    80006ad8:	6605                	lui	a2,0x1
    80006ada:	c6060613          	addi	a2,a2,-928 # c60 <_entry-0x7ffff3a0>
    80006ade:	9642                	add	a2,a2,a6
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    80006ae0:	4505                	li	a0,1
    80006ae2:	057e                	slli	a0,a0,0x1f
    80006ae4:	800005b7          	lui	a1,0x80000
    80006ae8:	fff5c593          	not	a1,a1
            mt[kk] = mt[kk+(M-N)] ^ (y >> 1) ^ mag01[y & 0x1];
    80006aec:	00002897          	auipc	a7,0x2
    80006af0:	e7c88893          	addi	a7,a7,-388 # 80008968 <mag01.985>
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    80006af4:	71883783          	ld	a5,1816(a6)
    80006af8:	8fe9                	and	a5,a5,a0
    80006afa:	72083703          	ld	a4,1824(a6)
    80006afe:	8f6d                	and	a4,a4,a1
    80006b00:	8fd9                	or	a5,a5,a4
            mt[kk] = mt[kk+(M-N)] ^ (y >> 1) ^ mag01[y & 0x1];
    80006b02:	0017d713          	srli	a4,a5,0x1
    80006b06:	00083683          	ld	a3,0(a6)
    80006b0a:	8f35                	xor	a4,a4,a3
    80006b0c:	8b85                	andi	a5,a5,1
    80006b0e:	078e                	slli	a5,a5,0x3
    80006b10:	97c6                	add	a5,a5,a7
    80006b12:	639c                	ld	a5,0(a5)
    80006b14:	8fb9                	xor	a5,a5,a4
    80006b16:	70f83c23          	sd	a5,1816(a6)
        for (;kk<N-1;kk++) {
    80006b1a:	0821                	addi	a6,a6,8
    80006b1c:	fcc81ce3          	bne	a6,a2,80006af4 <genrand+0x92>
        }
        y = (mt[N-1]&UPPER_MASK)|(mt[0]&LOWER_MASK);
    80006b20:	0001e697          	auipc	a3,0x1e
    80006b24:	ed868693          	addi	a3,a3,-296 # 800249f8 <mt+0x1000>
    80006b28:	3786b783          	ld	a5,888(a3)
    80006b2c:	4705                	li	a4,1
    80006b2e:	077e                	slli	a4,a4,0x1f
    80006b30:	8ff9                	and	a5,a5,a4
    80006b32:	0001d717          	auipc	a4,0x1d
    80006b36:	ec673703          	ld	a4,-314(a4) # 800239f8 <mt>
    80006b3a:	1706                	slli	a4,a4,0x21
    80006b3c:	9305                	srli	a4,a4,0x21
    80006b3e:	8fd9                	or	a5,a5,a4
        mt[N-1] = mt[M-1] ^ (y >> 1) ^ mag01[y & 0x1];
    80006b40:	0017d713          	srli	a4,a5,0x1
    80006b44:	c606b603          	ld	a2,-928(a3)
    80006b48:	8f31                	xor	a4,a4,a2
    80006b4a:	8b85                	andi	a5,a5,1
    80006b4c:	078e                	slli	a5,a5,0x3
    80006b4e:	00002617          	auipc	a2,0x2
    80006b52:	e1a60613          	addi	a2,a2,-486 # 80008968 <mag01.985>
    80006b56:	97b2                	add	a5,a5,a2
    80006b58:	639c                	ld	a5,0(a5)
    80006b5a:	8fb9                	xor	a5,a5,a4
    80006b5c:	36f6bc23          	sd	a5,888(a3)

        mti = 0;
    80006b60:	00002797          	auipc	a5,0x2
    80006b64:	e207a423          	sw	zero,-472(a5) # 80008988 <mti>
    }
  
    y = mt[mti++];
    80006b68:	00002717          	auipc	a4,0x2
    80006b6c:	e2070713          	addi	a4,a4,-480 # 80008988 <mti>
    80006b70:	431c                	lw	a5,0(a4)
    80006b72:	0017869b          	addiw	a3,a5,1
    80006b76:	c314                	sw	a3,0(a4)
    80006b78:	078e                	slli	a5,a5,0x3
    80006b7a:	0001d717          	auipc	a4,0x1d
    80006b7e:	e7e70713          	addi	a4,a4,-386 # 800239f8 <mt>
    80006b82:	97ba                	add	a5,a5,a4
    80006b84:	6398                	ld	a4,0(a5)
    y ^= TEMPERING_SHIFT_U(y);
    80006b86:	00b75793          	srli	a5,a4,0xb
    80006b8a:	8f3d                	xor	a4,a4,a5
    y ^= TEMPERING_SHIFT_S(y) & TEMPERING_MASK_B;
    80006b8c:	013a67b7          	lui	a5,0x13a6
    80006b90:	8ad78793          	addi	a5,a5,-1875 # 13a58ad <_entry-0x7ec5a753>
    80006b94:	8ff9                	and	a5,a5,a4
    80006b96:	079e                	slli	a5,a5,0x7
    80006b98:	8fb9                	xor	a5,a5,a4
    y ^= TEMPERING_SHIFT_T(y) & TEMPERING_MASK_C;
    80006b9a:	00f79713          	slli	a4,a5,0xf
    80006b9e:	077e36b7          	lui	a3,0x77e3
    80006ba2:	0696                	slli	a3,a3,0x5
    80006ba4:	8f75                	and	a4,a4,a3
    80006ba6:	8fb9                	xor	a5,a5,a4
    y ^= TEMPERING_SHIFT_L(y);
    80006ba8:	0127d513          	srli	a0,a5,0x12
    80006bac:	8fa9                	xor	a5,a5,a0

    // Strip off uppermost bit because we want a long,
    // not an unsigned long
    return y & RAND_MAX;
    80006bae:	02179513          	slli	a0,a5,0x21
}
    80006bb2:	9105                	srli	a0,a0,0x21
    80006bb4:	60a2                	ld	ra,8(sp)
    80006bb6:	6402                	ld	s0,0(sp)
    80006bb8:	0141                	addi	sp,sp,16
    80006bba:	8082                	ret
            sgenrand(4357); /* a default initial seed is used   */
    80006bbc:	6505                	lui	a0,0x1
    80006bbe:	10550513          	addi	a0,a0,261 # 1105 <_entry-0x7fffeefb>
    80006bc2:	00000097          	auipc	ra,0x0
    80006bc6:	e58080e7          	jalr	-424(ra) # 80006a1a <sgenrand>
    80006bca:	bd65                	j	80006a82 <genrand+0x20>

0000000080006bcc <random_at_most>:

// Assumes 0 <= max <= RAND_MAX
// Returns in the half-open interval [0, max]
long random_at_most(long max) {
    80006bcc:	1101                	addi	sp,sp,-32
    80006bce:	ec06                	sd	ra,24(sp)
    80006bd0:	e822                	sd	s0,16(sp)
    80006bd2:	e426                	sd	s1,8(sp)
    80006bd4:	e04a                	sd	s2,0(sp)
    80006bd6:	1000                	addi	s0,sp,32
  unsigned long
    // max <= RAND_MAX < ULONG_MAX, so this is okay.
    num_bins = (unsigned long) max + 1,
    80006bd8:	0505                	addi	a0,a0,1
    num_rand = (unsigned long) RAND_MAX + 1,
    bin_size = num_rand / num_bins,
    80006bda:	4485                	li	s1,1
    80006bdc:	04fe                	slli	s1,s1,0x1f
    80006bde:	02a4d933          	divu	s2,s1,a0
    defect   = num_rand % num_bins;
    80006be2:	02a4f533          	remu	a0,s1,a0
  long x;
  do {
   x = genrand();
  }
  // This is carefully written not to overflow
  while (num_rand - defect <= (unsigned long)x);
    80006be6:	4485                	li	s1,1
    80006be8:	04fe                	slli	s1,s1,0x1f
    80006bea:	8c89                	sub	s1,s1,a0
   x = genrand();
    80006bec:	00000097          	auipc	ra,0x0
    80006bf0:	e76080e7          	jalr	-394(ra) # 80006a62 <genrand>
  while (num_rand - defect <= (unsigned long)x);
    80006bf4:	fe957ce3          	bgeu	a0,s1,80006bec <random_at_most+0x20>

  // Truncated division is intentional
  return x/bin_size;
    80006bf8:	03255533          	divu	a0,a0,s2
    80006bfc:	60e2                	ld	ra,24(sp)
    80006bfe:	6442                	ld	s0,16(sp)
    80006c00:	64a2                	ld	s1,8(sp)
    80006c02:	6902                	ld	s2,0(sp)
    80006c04:	6105                	addi	sp,sp,32
    80006c06:	8082                	ret
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
