
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	b2013103          	ld	sp,-1248(sp) # 80008b20 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000056:	b2e70713          	addi	a4,a4,-1234 # 80008b80 <timer_scratch>
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
    80000068:	41c78793          	addi	a5,a5,1052 # 80006480 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd9c8f>
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
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	60a080e7          	jalr	1546(ra) # 80002736 <either_copyin>
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
    80000190:	b3450513          	addi	a0,a0,-1228 # 80010cc0 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a56080e7          	jalr	-1450(ra) # 80000bea <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	b2448493          	addi	s1,s1,-1244 # 80010cc0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	bb290913          	addi	s2,s2,-1102 # 80010d58 <cons+0x98>
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
    800001c8:	802080e7          	jalr	-2046(ra) # 800019c6 <myproc>
    800001cc:	00002097          	auipc	ra,0x2
    800001d0:	3b4080e7          	jalr	948(ra) # 80002580 <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	fa6080e7          	jalr	-90(ra) # 80002180 <sleep>
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
    8000021a:	4ca080e7          	jalr	1226(ra) # 800026e0 <either_copyout>
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
    8000022e:	a9650513          	addi	a0,a0,-1386 # 80010cc0 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a6c080e7          	jalr	-1428(ra) # 80000c9e <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	a8050513          	addi	a0,a0,-1408 # 80010cc0 <cons>
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
    8000027c:	aef72023          	sw	a5,-1312(a4) # 80010d58 <cons+0x98>
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
    800002d6:	9ee50513          	addi	a0,a0,-1554 # 80010cc0 <cons>
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
    800002fc:	494080e7          	jalr	1172(ra) # 8000278c <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00011517          	auipc	a0,0x11
    80000304:	9c050513          	addi	a0,a0,-1600 # 80010cc0 <cons>
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
    80000328:	99c70713          	addi	a4,a4,-1636 # 80010cc0 <cons>
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
    80000352:	97278793          	addi	a5,a5,-1678 # 80010cc0 <cons>
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
    80000380:	9dc7a783          	lw	a5,-1572(a5) # 80010d58 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00011717          	auipc	a4,0x11
    80000394:	93070713          	addi	a4,a4,-1744 # 80010cc0 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00011497          	auipc	s1,0x11
    800003a4:	92048493          	addi	s1,s1,-1760 # 80010cc0 <cons>
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
    800003e0:	8e470713          	addi	a4,a4,-1820 # 80010cc0 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00011717          	auipc	a4,0x11
    800003f6:	96f72723          	sw	a5,-1682(a4) # 80010d60 <cons+0xa0>
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
    8000041c:	8a878793          	addi	a5,a5,-1880 # 80010cc0 <cons>
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
    80000440:	92c7a023          	sw	a2,-1760(a5) # 80010d5c <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00011517          	auipc	a0,0x11
    80000448:	91450513          	addi	a0,a0,-1772 # 80010d58 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	ee4080e7          	jalr	-284(ra) # 80002330 <wakeup>
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
    80000466:	00011517          	auipc	a0,0x11
    8000046a:	85a50513          	addi	a0,a0,-1958 # 80010cc0 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	6ec080e7          	jalr	1772(ra) # 80000b5a <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00022797          	auipc	a5,0x22
    80000482:	1da78793          	addi	a5,a5,474 # 80022658 <devsw>
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
    80000550:	00011797          	auipc	a5,0x11
    80000554:	8207a823          	sw	zero,-2000(a5) # 80010d80 <pr+0x18>
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
    80000588:	5af72e23          	sw	a5,1468(a4) # 80008b40 <panicked>
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
    800005c4:	7c0dad83          	lw	s11,1984(s11) # 80010d80 <pr+0x18>
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
    80000602:	76a50513          	addi	a0,a0,1898 # 80010d68 <pr>
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
    80000766:	60650513          	addi	a0,a0,1542 # 80010d68 <pr>
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
    80000782:	5ea48493          	addi	s1,s1,1514 # 80010d68 <pr>
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
    800007e2:	5aa50513          	addi	a0,a0,1450 # 80010d88 <uart_tx_lock>
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
    8000080e:	3367a783          	lw	a5,822(a5) # 80008b40 <panicked>
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
    8000084a:	30273703          	ld	a4,770(a4) # 80008b48 <uart_tx_r>
    8000084e:	00008797          	auipc	a5,0x8
    80000852:	3027b783          	ld	a5,770(a5) # 80008b50 <uart_tx_w>
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
    80000874:	518a0a13          	addi	s4,s4,1304 # 80010d88 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	2d048493          	addi	s1,s1,720 # 80008b48 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	2d098993          	addi	s3,s3,720 # 80008b50 <uart_tx_w>
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
    800008aa:	a8a080e7          	jalr	-1398(ra) # 80002330 <wakeup>
    
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
    800008e6:	4a650513          	addi	a0,a0,1190 # 80010d88 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	300080e7          	jalr	768(ra) # 80000bea <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	24e7a783          	lw	a5,590(a5) # 80008b40 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008797          	auipc	a5,0x8
    80000900:	2547b783          	ld	a5,596(a5) # 80008b50 <uart_tx_w>
    80000904:	00008717          	auipc	a4,0x8
    80000908:	24473703          	ld	a4,580(a4) # 80008b48 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010a17          	auipc	s4,0x10
    80000914:	478a0a13          	addi	s4,s4,1144 # 80010d88 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	23048493          	addi	s1,s1,560 # 80008b48 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	23090913          	addi	s2,s2,560 # 80008b50 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00002097          	auipc	ra,0x2
    80000934:	850080e7          	jalr	-1968(ra) # 80002180 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	44248493          	addi	s1,s1,1090 # 80010d88 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00008717          	auipc	a4,0x8
    8000095e:	1ef73b23          	sd	a5,502(a4) # 80008b50 <uart_tx_w>
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
    800009d4:	3b848493          	addi	s1,s1,952 # 80010d88 <uart_tx_lock>
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
    80000a16:	15e78793          	addi	a5,a5,350 # 80024b70 <end>
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
    80000a36:	38e90913          	addi	s2,s2,910 # 80010dc0 <kmem>
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
    80000ad2:	2f250513          	addi	a0,a0,754 # 80010dc0 <kmem>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	084080e7          	jalr	132(ra) # 80000b5a <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ade:	45c5                	li	a1,17
    80000ae0:	05ee                	slli	a1,a1,0x1b
    80000ae2:	00024517          	auipc	a0,0x24
    80000ae6:	08e50513          	addi	a0,a0,142 # 80024b70 <end>
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
    80000b08:	2bc48493          	addi	s1,s1,700 # 80010dc0 <kmem>
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
    80000b20:	2a450513          	addi	a0,a0,676 # 80010dc0 <kmem>
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
    80000b4c:	27850513          	addi	a0,a0,632 # 80010dc0 <kmem>
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
    80000b88:	e26080e7          	jalr	-474(ra) # 800019aa <mycpu>
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
    80000bba:	df4080e7          	jalr	-524(ra) # 800019aa <mycpu>
    80000bbe:	5d3c                	lw	a5,120(a0)
    80000bc0:	cf89                	beqz	a5,80000bda <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bc2:	00001097          	auipc	ra,0x1
    80000bc6:	de8080e7          	jalr	-536(ra) # 800019aa <mycpu>
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
    80000bde:	dd0080e7          	jalr	-560(ra) # 800019aa <mycpu>
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
    80000c1e:	d90080e7          	jalr	-624(ra) # 800019aa <mycpu>
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
    80000c4a:	d64080e7          	jalr	-668(ra) # 800019aa <mycpu>
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
    80000ea0:	afe080e7          	jalr	-1282(ra) # 8000199a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ea4:	00008717          	auipc	a4,0x8
    80000ea8:	cb470713          	addi	a4,a4,-844 # 80008b58 <started>
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
    80000ebc:	ae2080e7          	jalr	-1310(ra) # 8000199a <cpuid>
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
    80000ede:	a60080e7          	jalr	-1440(ra) # 8000293a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00005097          	auipc	ra,0x5
    80000ee6:	5de080e7          	jalr	1502(ra) # 800064c0 <plicinithart>
  }

  scheduler();        
    80000eea:	00001097          	auipc	ra,0x1
    80000eee:	02c080e7          	jalr	44(ra) # 80001f16 <scheduler>
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
    80000f4e:	99c080e7          	jalr	-1636(ra) # 800018e6 <procinit>
    trapinit();      // trap vectors
    80000f52:	00002097          	auipc	ra,0x2
    80000f56:	9c0080e7          	jalr	-1600(ra) # 80002912 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00002097          	auipc	ra,0x2
    80000f5e:	9e0080e7          	jalr	-1568(ra) # 8000293a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	548080e7          	jalr	1352(ra) # 800064aa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00005097          	auipc	ra,0x5
    80000f6e:	556080e7          	jalr	1366(ra) # 800064c0 <plicinithart>
    binit();         // buffer cache
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	70c080e7          	jalr	1804(ra) # 8000367e <binit>
    iinit();         // inode table
    80000f7a:	00003097          	auipc	ra,0x3
    80000f7e:	db0080e7          	jalr	-592(ra) # 80003d2a <iinit>
    fileinit();      // file table
    80000f82:	00004097          	auipc	ra,0x4
    80000f86:	d4e080e7          	jalr	-690(ra) # 80004cd0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	63e080e7          	jalr	1598(ra) # 800065c8 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	d62080e7          	jalr	-670(ra) # 80001cf4 <userinit>
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    started = 1;
    80000f9e:	4785                	li	a5,1
    80000fa0:	00008717          	auipc	a4,0x8
    80000fa4:	baf72c23          	sw	a5,-1096(a4) # 80008b58 <started>
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
    80000fb8:	bac7b783          	ld	a5,-1108(a5) # 80008b60 <kernel_pagetable>
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
    8000124e:	606080e7          	jalr	1542(ra) # 80001850 <proc_mapstacks>
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
    80001274:	8ea7b823          	sd	a0,-1808(a5) # 80008b60 <kernel_pagetable>
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

0000000080001850 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001850:	7139                	addi	sp,sp,-64
    80001852:	fc06                	sd	ra,56(sp)
    80001854:	f822                	sd	s0,48(sp)
    80001856:	f426                	sd	s1,40(sp)
    80001858:	f04a                	sd	s2,32(sp)
    8000185a:	ec4e                	sd	s3,24(sp)
    8000185c:	e852                	sd	s4,16(sp)
    8000185e:	e456                	sd	s5,8(sp)
    80001860:	e05a                	sd	s6,0(sp)
    80001862:	0080                	addi	s0,sp,64
    80001864:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001866:	00010497          	auipc	s1,0x10
    8000186a:	9aa48493          	addi	s1,s1,-1622 # 80011210 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000186e:	8b26                	mv	s6,s1
    80001870:	00006a97          	auipc	s5,0x6
    80001874:	790a8a93          	addi	s5,s5,1936 # 80008000 <etext>
    80001878:	04000937          	lui	s2,0x4000
    8000187c:	197d                	addi	s2,s2,-1
    8000187e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001880:	00017a17          	auipc	s4,0x17
    80001884:	b90a0a13          	addi	s4,s4,-1136 # 80018410 <tickslock>
    char *pa = kalloc();
    80001888:	fffff097          	auipc	ra,0xfffff
    8000188c:	272080e7          	jalr	626(ra) # 80000afa <kalloc>
    80001890:	862a                	mv	a2,a0
    if(pa == 0)
    80001892:	c131                	beqz	a0,800018d6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001894:	416485b3          	sub	a1,s1,s6
    80001898:	858d                	srai	a1,a1,0x3
    8000189a:	000ab783          	ld	a5,0(s5)
    8000189e:	02f585b3          	mul	a1,a1,a5
    800018a2:	2585                	addiw	a1,a1,1
    800018a4:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018a8:	4719                	li	a4,6
    800018aa:	6685                	lui	a3,0x1
    800018ac:	40b905b3          	sub	a1,s2,a1
    800018b0:	854e                	mv	a0,s3
    800018b2:	00000097          	auipc	ra,0x0
    800018b6:	8a8080e7          	jalr	-1880(ra) # 8000115a <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018ba:	1c848493          	addi	s1,s1,456
    800018be:	fd4495e3          	bne	s1,s4,80001888 <proc_mapstacks+0x38>
  }
}
    800018c2:	70e2                	ld	ra,56(sp)
    800018c4:	7442                	ld	s0,48(sp)
    800018c6:	74a2                	ld	s1,40(sp)
    800018c8:	7902                	ld	s2,32(sp)
    800018ca:	69e2                	ld	s3,24(sp)
    800018cc:	6a42                	ld	s4,16(sp)
    800018ce:	6aa2                	ld	s5,8(sp)
    800018d0:	6b02                	ld	s6,0(sp)
    800018d2:	6121                	addi	sp,sp,64
    800018d4:	8082                	ret
      panic("kalloc");
    800018d6:	00007517          	auipc	a0,0x7
    800018da:	90250513          	addi	a0,a0,-1790 # 800081d8 <digits+0x198>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	c66080e7          	jalr	-922(ra) # 80000544 <panic>

00000000800018e6 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018e6:	7139                	addi	sp,sp,-64
    800018e8:	fc06                	sd	ra,56(sp)
    800018ea:	f822                	sd	s0,48(sp)
    800018ec:	f426                	sd	s1,40(sp)
    800018ee:	f04a                	sd	s2,32(sp)
    800018f0:	ec4e                	sd	s3,24(sp)
    800018f2:	e852                	sd	s4,16(sp)
    800018f4:	e456                	sd	s5,8(sp)
    800018f6:	e05a                	sd	s6,0(sp)
    800018f8:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018fa:	00007597          	auipc	a1,0x7
    800018fe:	8e658593          	addi	a1,a1,-1818 # 800081e0 <digits+0x1a0>
    80001902:	0000f517          	auipc	a0,0xf
    80001906:	4de50513          	addi	a0,a0,1246 # 80010de0 <pid_lock>
    8000190a:	fffff097          	auipc	ra,0xfffff
    8000190e:	250080e7          	jalr	592(ra) # 80000b5a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001912:	00007597          	auipc	a1,0x7
    80001916:	8d658593          	addi	a1,a1,-1834 # 800081e8 <digits+0x1a8>
    8000191a:	0000f517          	auipc	a0,0xf
    8000191e:	4de50513          	addi	a0,a0,1246 # 80010df8 <wait_lock>
    80001922:	fffff097          	auipc	ra,0xfffff
    80001926:	238080e7          	jalr	568(ra) # 80000b5a <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000192a:	00010497          	auipc	s1,0x10
    8000192e:	8e648493          	addi	s1,s1,-1818 # 80011210 <proc>
      initlock(&p->lock, "proc");
    80001932:	00007b17          	auipc	s6,0x7
    80001936:	8c6b0b13          	addi	s6,s6,-1850 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    8000193a:	8aa6                	mv	s5,s1
    8000193c:	00006a17          	auipc	s4,0x6
    80001940:	6c4a0a13          	addi	s4,s4,1732 # 80008000 <etext>
    80001944:	04000937          	lui	s2,0x4000
    80001948:	197d                	addi	s2,s2,-1
    8000194a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194c:	00017997          	auipc	s3,0x17
    80001950:	ac498993          	addi	s3,s3,-1340 # 80018410 <tickslock>
      initlock(&p->lock, "proc");
    80001954:	85da                	mv	a1,s6
    80001956:	8526                	mv	a0,s1
    80001958:	fffff097          	auipc	ra,0xfffff
    8000195c:	202080e7          	jalr	514(ra) # 80000b5a <initlock>
      p->state = UNUSED;
    80001960:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001964:	415487b3          	sub	a5,s1,s5
    80001968:	878d                	srai	a5,a5,0x3
    8000196a:	000a3703          	ld	a4,0(s4)
    8000196e:	02e787b3          	mul	a5,a5,a4
    80001972:	2785                	addiw	a5,a5,1
    80001974:	00d7979b          	slliw	a5,a5,0xd
    80001978:	40f907b3          	sub	a5,s2,a5
    8000197c:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000197e:	1c848493          	addi	s1,s1,456
    80001982:	fd3499e3          	bne	s1,s3,80001954 <procinit+0x6e>
  }
}
    80001986:	70e2                	ld	ra,56(sp)
    80001988:	7442                	ld	s0,48(sp)
    8000198a:	74a2                	ld	s1,40(sp)
    8000198c:	7902                	ld	s2,32(sp)
    8000198e:	69e2                	ld	s3,24(sp)
    80001990:	6a42                	ld	s4,16(sp)
    80001992:	6aa2                	ld	s5,8(sp)
    80001994:	6b02                	ld	s6,0(sp)
    80001996:	6121                	addi	sp,sp,64
    80001998:	8082                	ret

000000008000199a <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000199a:	1141                	addi	sp,sp,-16
    8000199c:	e422                	sd	s0,8(sp)
    8000199e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019a0:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019a2:	2501                	sext.w	a0,a0
    800019a4:	6422                	ld	s0,8(sp)
    800019a6:	0141                	addi	sp,sp,16
    800019a8:	8082                	ret

00000000800019aa <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800019aa:	1141                	addi	sp,sp,-16
    800019ac:	e422                	sd	s0,8(sp)
    800019ae:	0800                	addi	s0,sp,16
    800019b0:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019b2:	2781                	sext.w	a5,a5
    800019b4:	079e                	slli	a5,a5,0x7
  return c;
}
    800019b6:	0000f517          	auipc	a0,0xf
    800019ba:	45a50513          	addi	a0,a0,1114 # 80010e10 <cpus>
    800019be:	953e                	add	a0,a0,a5
    800019c0:	6422                	ld	s0,8(sp)
    800019c2:	0141                	addi	sp,sp,16
    800019c4:	8082                	ret

00000000800019c6 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019c6:	1101                	addi	sp,sp,-32
    800019c8:	ec06                	sd	ra,24(sp)
    800019ca:	e822                	sd	s0,16(sp)
    800019cc:	e426                	sd	s1,8(sp)
    800019ce:	1000                	addi	s0,sp,32
  push_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	1ce080e7          	jalr	462(ra) # 80000b9e <push_off>
    800019d8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019da:	2781                	sext.w	a5,a5
    800019dc:	079e                	slli	a5,a5,0x7
    800019de:	0000f717          	auipc	a4,0xf
    800019e2:	40270713          	addi	a4,a4,1026 # 80010de0 <pid_lock>
    800019e6:	97ba                	add	a5,a5,a4
    800019e8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019ea:	fffff097          	auipc	ra,0xfffff
    800019ee:	254080e7          	jalr	596(ra) # 80000c3e <pop_off>
  return p;
}
    800019f2:	8526                	mv	a0,s1
    800019f4:	60e2                	ld	ra,24(sp)
    800019f6:	6442                	ld	s0,16(sp)
    800019f8:	64a2                	ld	s1,8(sp)
    800019fa:	6105                	addi	sp,sp,32
    800019fc:	8082                	ret

00000000800019fe <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019fe:	1141                	addi	sp,sp,-16
    80001a00:	e406                	sd	ra,8(sp)
    80001a02:	e022                	sd	s0,0(sp)
    80001a04:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a06:	00000097          	auipc	ra,0x0
    80001a0a:	fc0080e7          	jalr	-64(ra) # 800019c6 <myproc>
    80001a0e:	fffff097          	auipc	ra,0xfffff
    80001a12:	290080e7          	jalr	656(ra) # 80000c9e <release>

  if (first) {
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	fda7a783          	lw	a5,-38(a5) # 800089f0 <first.1736>
    80001a1e:	eb89                	bnez	a5,80001a30 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a20:	00001097          	auipc	ra,0x1
    80001a24:	f32080e7          	jalr	-206(ra) # 80002952 <usertrapret>
}
    80001a28:	60a2                	ld	ra,8(sp)
    80001a2a:	6402                	ld	s0,0(sp)
    80001a2c:	0141                	addi	sp,sp,16
    80001a2e:	8082                	ret
    first = 0;
    80001a30:	00007797          	auipc	a5,0x7
    80001a34:	fc07a023          	sw	zero,-64(a5) # 800089f0 <first.1736>
    fsinit(ROOTDEV);
    80001a38:	4505                	li	a0,1
    80001a3a:	00002097          	auipc	ra,0x2
    80001a3e:	270080e7          	jalr	624(ra) # 80003caa <fsinit>
    80001a42:	bff9                	j	80001a20 <forkret+0x22>

0000000080001a44 <allocpid>:
{
    80001a44:	1101                	addi	sp,sp,-32
    80001a46:	ec06                	sd	ra,24(sp)
    80001a48:	e822                	sd	s0,16(sp)
    80001a4a:	e426                	sd	s1,8(sp)
    80001a4c:	e04a                	sd	s2,0(sp)
    80001a4e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a50:	0000f917          	auipc	s2,0xf
    80001a54:	39090913          	addi	s2,s2,912 # 80010de0 <pid_lock>
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	190080e7          	jalr	400(ra) # 80000bea <acquire>
  pid = nextpid;
    80001a62:	00007797          	auipc	a5,0x7
    80001a66:	f9278793          	addi	a5,a5,-110 # 800089f4 <nextpid>
    80001a6a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a6c:	0014871b          	addiw	a4,s1,1
    80001a70:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a72:	854a                	mv	a0,s2
    80001a74:	fffff097          	auipc	ra,0xfffff
    80001a78:	22a080e7          	jalr	554(ra) # 80000c9e <release>
}
    80001a7c:	8526                	mv	a0,s1
    80001a7e:	60e2                	ld	ra,24(sp)
    80001a80:	6442                	ld	s0,16(sp)
    80001a82:	64a2                	ld	s1,8(sp)
    80001a84:	6902                	ld	s2,0(sp)
    80001a86:	6105                	addi	sp,sp,32
    80001a88:	8082                	ret

0000000080001a8a <proc_pagetable>:
{
    80001a8a:	1101                	addi	sp,sp,-32
    80001a8c:	ec06                	sd	ra,24(sp)
    80001a8e:	e822                	sd	s0,16(sp)
    80001a90:	e426                	sd	s1,8(sp)
    80001a92:	e04a                	sd	s2,0(sp)
    80001a94:	1000                	addi	s0,sp,32
    80001a96:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a98:	00000097          	auipc	ra,0x0
    80001a9c:	8ac080e7          	jalr	-1876(ra) # 80001344 <uvmcreate>
    80001aa0:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001aa2:	c121                	beqz	a0,80001ae2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aa4:	4729                	li	a4,10
    80001aa6:	00005697          	auipc	a3,0x5
    80001aaa:	55a68693          	addi	a3,a3,1370 # 80007000 <_trampoline>
    80001aae:	6605                	lui	a2,0x1
    80001ab0:	040005b7          	lui	a1,0x4000
    80001ab4:	15fd                	addi	a1,a1,-1
    80001ab6:	05b2                	slli	a1,a1,0xc
    80001ab8:	fffff097          	auipc	ra,0xfffff
    80001abc:	602080e7          	jalr	1538(ra) # 800010ba <mappages>
    80001ac0:	02054863          	bltz	a0,80001af0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ac4:	4719                	li	a4,6
    80001ac6:	05893683          	ld	a3,88(s2)
    80001aca:	6605                	lui	a2,0x1
    80001acc:	020005b7          	lui	a1,0x2000
    80001ad0:	15fd                	addi	a1,a1,-1
    80001ad2:	05b6                	slli	a1,a1,0xd
    80001ad4:	8526                	mv	a0,s1
    80001ad6:	fffff097          	auipc	ra,0xfffff
    80001ada:	5e4080e7          	jalr	1508(ra) # 800010ba <mappages>
    80001ade:	02054163          	bltz	a0,80001b00 <proc_pagetable+0x76>
}
    80001ae2:	8526                	mv	a0,s1
    80001ae4:	60e2                	ld	ra,24(sp)
    80001ae6:	6442                	ld	s0,16(sp)
    80001ae8:	64a2                	ld	s1,8(sp)
    80001aea:	6902                	ld	s2,0(sp)
    80001aec:	6105                	addi	sp,sp,32
    80001aee:	8082                	ret
    uvmfree(pagetable, 0);
    80001af0:	4581                	li	a1,0
    80001af2:	8526                	mv	a0,s1
    80001af4:	00000097          	auipc	ra,0x0
    80001af8:	a54080e7          	jalr	-1452(ra) # 80001548 <uvmfree>
    return 0;
    80001afc:	4481                	li	s1,0
    80001afe:	b7d5                	j	80001ae2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b00:	4681                	li	a3,0
    80001b02:	4605                	li	a2,1
    80001b04:	040005b7          	lui	a1,0x4000
    80001b08:	15fd                	addi	a1,a1,-1
    80001b0a:	05b2                	slli	a1,a1,0xc
    80001b0c:	8526                	mv	a0,s1
    80001b0e:	fffff097          	auipc	ra,0xfffff
    80001b12:	772080e7          	jalr	1906(ra) # 80001280 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b16:	4581                	li	a1,0
    80001b18:	8526                	mv	a0,s1
    80001b1a:	00000097          	auipc	ra,0x0
    80001b1e:	a2e080e7          	jalr	-1490(ra) # 80001548 <uvmfree>
    return 0;
    80001b22:	4481                	li	s1,0
    80001b24:	bf7d                	j	80001ae2 <proc_pagetable+0x58>

0000000080001b26 <proc_freepagetable>:
{
    80001b26:	1101                	addi	sp,sp,-32
    80001b28:	ec06                	sd	ra,24(sp)
    80001b2a:	e822                	sd	s0,16(sp)
    80001b2c:	e426                	sd	s1,8(sp)
    80001b2e:	e04a                	sd	s2,0(sp)
    80001b30:	1000                	addi	s0,sp,32
    80001b32:	84aa                	mv	s1,a0
    80001b34:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b36:	4681                	li	a3,0
    80001b38:	4605                	li	a2,1
    80001b3a:	040005b7          	lui	a1,0x4000
    80001b3e:	15fd                	addi	a1,a1,-1
    80001b40:	05b2                	slli	a1,a1,0xc
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	73e080e7          	jalr	1854(ra) # 80001280 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b4a:	4681                	li	a3,0
    80001b4c:	4605                	li	a2,1
    80001b4e:	020005b7          	lui	a1,0x2000
    80001b52:	15fd                	addi	a1,a1,-1
    80001b54:	05b6                	slli	a1,a1,0xd
    80001b56:	8526                	mv	a0,s1
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	728080e7          	jalr	1832(ra) # 80001280 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b60:	85ca                	mv	a1,s2
    80001b62:	8526                	mv	a0,s1
    80001b64:	00000097          	auipc	ra,0x0
    80001b68:	9e4080e7          	jalr	-1564(ra) # 80001548 <uvmfree>
}
    80001b6c:	60e2                	ld	ra,24(sp)
    80001b6e:	6442                	ld	s0,16(sp)
    80001b70:	64a2                	ld	s1,8(sp)
    80001b72:	6902                	ld	s2,0(sp)
    80001b74:	6105                	addi	sp,sp,32
    80001b76:	8082                	ret

0000000080001b78 <freeproc>:
{
    80001b78:	1101                	addi	sp,sp,-32
    80001b7a:	ec06                	sd	ra,24(sp)
    80001b7c:	e822                	sd	s0,16(sp)
    80001b7e:	e426                	sd	s1,8(sp)
    80001b80:	1000                	addi	s0,sp,32
    80001b82:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b84:	6d28                	ld	a0,88(a0)
    80001b86:	c509                	beqz	a0,80001b90 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b88:	fffff097          	auipc	ra,0xfffff
    80001b8c:	e76080e7          	jalr	-394(ra) # 800009fe <kfree>
  p->trapframe = 0;
    80001b90:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b94:	68a8                	ld	a0,80(s1)
    80001b96:	c511                	beqz	a0,80001ba2 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b98:	64ac                	ld	a1,72(s1)
    80001b9a:	00000097          	auipc	ra,0x0
    80001b9e:	f8c080e7          	jalr	-116(ra) # 80001b26 <proc_freepagetable>
  p->pagetable = 0;
    80001ba2:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001ba6:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001baa:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bae:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bb2:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bb6:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bba:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bbe:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bc2:	0004ac23          	sw	zero,24(s1)
  p->etime = 0;
    80001bc6:	1604a823          	sw	zero,368(s1)
  p->rtime = 0;
    80001bca:	1604a423          	sw	zero,360(s1)
  p->ctime = 0;
    80001bce:	1604a623          	sw	zero,364(s1)
}
    80001bd2:	60e2                	ld	ra,24(sp)
    80001bd4:	6442                	ld	s0,16(sp)
    80001bd6:	64a2                	ld	s1,8(sp)
    80001bd8:	6105                	addi	sp,sp,32
    80001bda:	8082                	ret

0000000080001bdc <allocproc>:
{
    80001bdc:	1101                	addi	sp,sp,-32
    80001bde:	ec06                	sd	ra,24(sp)
    80001be0:	e822                	sd	s0,16(sp)
    80001be2:	e426                	sd	s1,8(sp)
    80001be4:	e04a                	sd	s2,0(sp)
    80001be6:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001be8:	0000f497          	auipc	s1,0xf
    80001bec:	62848493          	addi	s1,s1,1576 # 80011210 <proc>
    80001bf0:	00017917          	auipc	s2,0x17
    80001bf4:	82090913          	addi	s2,s2,-2016 # 80018410 <tickslock>
    acquire(&p->lock);
    80001bf8:	8526                	mv	a0,s1
    80001bfa:	fffff097          	auipc	ra,0xfffff
    80001bfe:	ff0080e7          	jalr	-16(ra) # 80000bea <acquire>
    if(p->state == UNUSED) {
    80001c02:	4c9c                	lw	a5,24(s1)
    80001c04:	cf81                	beqz	a5,80001c1c <allocproc+0x40>
      release(&p->lock);
    80001c06:	8526                	mv	a0,s1
    80001c08:	fffff097          	auipc	ra,0xfffff
    80001c0c:	096080e7          	jalr	150(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c10:	1c848493          	addi	s1,s1,456
    80001c14:	ff2492e3          	bne	s1,s2,80001bf8 <allocproc+0x1c>
  return 0;
    80001c18:	4481                	li	s1,0
    80001c1a:	a871                	j	80001cb6 <allocproc+0xda>
  p->pid = allocpid();
    80001c1c:	00000097          	auipc	ra,0x0
    80001c20:	e28080e7          	jalr	-472(ra) # 80001a44 <allocpid>
    80001c24:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c26:	4685                	li	a3,1
    80001c28:	cc94                	sw	a3,24(s1)
  p->tick_creation_time = ticks;
    80001c2a:	00007797          	auipc	a5,0x7
    80001c2e:	f467a783          	lw	a5,-186(a5) # 80008b70 <ticks>
    80001c32:	0007871b          	sext.w	a4,a5
    80001c36:	18e4a823          	sw	a4,400(s1)
  p->tickets = 1;
    80001c3a:	18d4aa23          	sw	a3,404(s1)
  p->priority_pbs = 60;
    80001c3e:	03c00693          	li	a3,60
    80001c42:	1ad4a023          	sw	a3,416(s1)
  p->niceness_var = 5;
    80001c46:	4695                	li	a3,5
    80001c48:	1ad4a223          	sw	a3,420(s1)
  p->start_time_pbs = ticks;
    80001c4c:	18e4ac23          	sw	a4,408(s1)
  p->number_times = 0;
    80001c50:	1804ae23          	sw	zero,412(s1)
  p->last_run_time = 0;
    80001c54:	1a04a623          	sw	zero,428(s1)
  p->last_sleep_time = 0;
    80001c58:	1a04a423          	sw	zero,424(s1)
  p->priority = 0;
    80001c5c:	1a04aa23          	sw	zero,436(s1)
  p->in_queue = 0;
    80001c60:	1a04ac23          	sw	zero,440(s1)
  p->curr_rtime = 0;
    80001c64:	1a04ae23          	sw	zero,444(s1)
  p->curr_wtime = 0;
    80001c68:	1c04a023          	sw	zero,448(s1)
  p->rtime = 0;
    80001c6c:	1604a423          	sw	zero,360(s1)
  p->ctime = ticks;
    80001c70:	16f4a623          	sw	a5,364(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	e86080e7          	jalr	-378(ra) # 80000afa <kalloc>
    80001c7c:	892a                	mv	s2,a0
    80001c7e:	eca8                	sd	a0,88(s1)
    80001c80:	c131                	beqz	a0,80001cc4 <allocproc+0xe8>
  p->pagetable = proc_pagetable(p);
    80001c82:	8526                	mv	a0,s1
    80001c84:	00000097          	auipc	ra,0x0
    80001c88:	e06080e7          	jalr	-506(ra) # 80001a8a <proc_pagetable>
    80001c8c:	892a                	mv	s2,a0
    80001c8e:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c90:	c531                	beqz	a0,80001cdc <allocproc+0x100>
  memset(&p->context, 0, sizeof(p->context));
    80001c92:	07000613          	li	a2,112
    80001c96:	4581                	li	a1,0
    80001c98:	06048513          	addi	a0,s1,96
    80001c9c:	fffff097          	auipc	ra,0xfffff
    80001ca0:	04a080e7          	jalr	74(ra) # 80000ce6 <memset>
  p->context.ra = (uint64)forkret;
    80001ca4:	00000797          	auipc	a5,0x0
    80001ca8:	d5a78793          	addi	a5,a5,-678 # 800019fe <forkret>
    80001cac:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cae:	60bc                	ld	a5,64(s1)
    80001cb0:	6705                	lui	a4,0x1
    80001cb2:	97ba                	add	a5,a5,a4
    80001cb4:	f4bc                	sd	a5,104(s1)
}
    80001cb6:	8526                	mv	a0,s1
    80001cb8:	60e2                	ld	ra,24(sp)
    80001cba:	6442                	ld	s0,16(sp)
    80001cbc:	64a2                	ld	s1,8(sp)
    80001cbe:	6902                	ld	s2,0(sp)
    80001cc0:	6105                	addi	sp,sp,32
    80001cc2:	8082                	ret
    freeproc(p);
    80001cc4:	8526                	mv	a0,s1
    80001cc6:	00000097          	auipc	ra,0x0
    80001cca:	eb2080e7          	jalr	-334(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001cce:	8526                	mv	a0,s1
    80001cd0:	fffff097          	auipc	ra,0xfffff
    80001cd4:	fce080e7          	jalr	-50(ra) # 80000c9e <release>
    return 0;
    80001cd8:	84ca                	mv	s1,s2
    80001cda:	bff1                	j	80001cb6 <allocproc+0xda>
    freeproc(p);
    80001cdc:	8526                	mv	a0,s1
    80001cde:	00000097          	auipc	ra,0x0
    80001ce2:	e9a080e7          	jalr	-358(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001ce6:	8526                	mv	a0,s1
    80001ce8:	fffff097          	auipc	ra,0xfffff
    80001cec:	fb6080e7          	jalr	-74(ra) # 80000c9e <release>
    return 0;
    80001cf0:	84ca                	mv	s1,s2
    80001cf2:	b7d1                	j	80001cb6 <allocproc+0xda>

0000000080001cf4 <userinit>:
{
    80001cf4:	1101                	addi	sp,sp,-32
    80001cf6:	ec06                	sd	ra,24(sp)
    80001cf8:	e822                	sd	s0,16(sp)
    80001cfa:	e426                	sd	s1,8(sp)
    80001cfc:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cfe:	00000097          	auipc	ra,0x0
    80001d02:	ede080e7          	jalr	-290(ra) # 80001bdc <allocproc>
    80001d06:	84aa                	mv	s1,a0
  initproc = p;
    80001d08:	00007797          	auipc	a5,0x7
    80001d0c:	e6a7b023          	sd	a0,-416(a5) # 80008b68 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001d10:	03400613          	li	a2,52
    80001d14:	00007597          	auipc	a1,0x7
    80001d18:	cec58593          	addi	a1,a1,-788 # 80008a00 <initcode>
    80001d1c:	6928                	ld	a0,80(a0)
    80001d1e:	fffff097          	auipc	ra,0xfffff
    80001d22:	654080e7          	jalr	1620(ra) # 80001372 <uvmfirst>
  p->sz = PGSIZE;
    80001d26:	6785                	lui	a5,0x1
    80001d28:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d2a:	6cb8                	ld	a4,88(s1)
    80001d2c:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d30:	6cb8                	ld	a4,88(s1)
    80001d32:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d34:	4641                	li	a2,16
    80001d36:	00006597          	auipc	a1,0x6
    80001d3a:	4ca58593          	addi	a1,a1,1226 # 80008200 <digits+0x1c0>
    80001d3e:	15848513          	addi	a0,s1,344
    80001d42:	fffff097          	auipc	ra,0xfffff
    80001d46:	0f6080e7          	jalr	246(ra) # 80000e38 <safestrcpy>
  p->cwd = namei("/");
    80001d4a:	00006517          	auipc	a0,0x6
    80001d4e:	4c650513          	addi	a0,a0,1222 # 80008210 <digits+0x1d0>
    80001d52:	00003097          	auipc	ra,0x3
    80001d56:	97a080e7          	jalr	-1670(ra) # 800046cc <namei>
    80001d5a:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d5e:	478d                	li	a5,3
    80001d60:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d62:	8526                	mv	a0,s1
    80001d64:	fffff097          	auipc	ra,0xfffff
    80001d68:	f3a080e7          	jalr	-198(ra) # 80000c9e <release>
}
    80001d6c:	60e2                	ld	ra,24(sp)
    80001d6e:	6442                	ld	s0,16(sp)
    80001d70:	64a2                	ld	s1,8(sp)
    80001d72:	6105                	addi	sp,sp,32
    80001d74:	8082                	ret

0000000080001d76 <growproc>:
{
    80001d76:	1101                	addi	sp,sp,-32
    80001d78:	ec06                	sd	ra,24(sp)
    80001d7a:	e822                	sd	s0,16(sp)
    80001d7c:	e426                	sd	s1,8(sp)
    80001d7e:	e04a                	sd	s2,0(sp)
    80001d80:	1000                	addi	s0,sp,32
    80001d82:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d84:	00000097          	auipc	ra,0x0
    80001d88:	c42080e7          	jalr	-958(ra) # 800019c6 <myproc>
    80001d8c:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d8e:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d90:	01204c63          	bgtz	s2,80001da8 <growproc+0x32>
  } else if(n < 0){
    80001d94:	02094663          	bltz	s2,80001dc0 <growproc+0x4a>
  p->sz = sz;
    80001d98:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d9a:	4501                	li	a0,0
}
    80001d9c:	60e2                	ld	ra,24(sp)
    80001d9e:	6442                	ld	s0,16(sp)
    80001da0:	64a2                	ld	s1,8(sp)
    80001da2:	6902                	ld	s2,0(sp)
    80001da4:	6105                	addi	sp,sp,32
    80001da6:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001da8:	4691                	li	a3,4
    80001daa:	00b90633          	add	a2,s2,a1
    80001dae:	6928                	ld	a0,80(a0)
    80001db0:	fffff097          	auipc	ra,0xfffff
    80001db4:	67c080e7          	jalr	1660(ra) # 8000142c <uvmalloc>
    80001db8:	85aa                	mv	a1,a0
    80001dba:	fd79                	bnez	a0,80001d98 <growproc+0x22>
      return -1;
    80001dbc:	557d                	li	a0,-1
    80001dbe:	bff9                	j	80001d9c <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dc0:	00b90633          	add	a2,s2,a1
    80001dc4:	6928                	ld	a0,80(a0)
    80001dc6:	fffff097          	auipc	ra,0xfffff
    80001dca:	61e080e7          	jalr	1566(ra) # 800013e4 <uvmdealloc>
    80001dce:	85aa                	mv	a1,a0
    80001dd0:	b7e1                	j	80001d98 <growproc+0x22>

0000000080001dd2 <fork>:
{
    80001dd2:	7179                	addi	sp,sp,-48
    80001dd4:	f406                	sd	ra,40(sp)
    80001dd6:	f022                	sd	s0,32(sp)
    80001dd8:	ec26                	sd	s1,24(sp)
    80001dda:	e84a                	sd	s2,16(sp)
    80001ddc:	e44e                	sd	s3,8(sp)
    80001dde:	e052                	sd	s4,0(sp)
    80001de0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001de2:	00000097          	auipc	ra,0x0
    80001de6:	be4080e7          	jalr	-1052(ra) # 800019c6 <myproc>
    80001dea:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001dec:	00000097          	auipc	ra,0x0
    80001df0:	df0080e7          	jalr	-528(ra) # 80001bdc <allocproc>
    80001df4:	10050f63          	beqz	a0,80001f12 <fork+0x140>
    80001df8:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dfa:	04893603          	ld	a2,72(s2)
    80001dfe:	692c                	ld	a1,80(a0)
    80001e00:	05093503          	ld	a0,80(s2)
    80001e04:	fffff097          	auipc	ra,0xfffff
    80001e08:	77c080e7          	jalr	1916(ra) # 80001580 <uvmcopy>
    80001e0c:	04054a63          	bltz	a0,80001e60 <fork+0x8e>
  np->sz = p->sz;
    80001e10:	04893783          	ld	a5,72(s2)
    80001e14:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e18:	05893683          	ld	a3,88(s2)
    80001e1c:	87b6                	mv	a5,a3
    80001e1e:	0589b703          	ld	a4,88(s3)
    80001e22:	12068693          	addi	a3,a3,288
    80001e26:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e2a:	6788                	ld	a0,8(a5)
    80001e2c:	6b8c                	ld	a1,16(a5)
    80001e2e:	6f90                	ld	a2,24(a5)
    80001e30:	01073023          	sd	a6,0(a4)
    80001e34:	e708                	sd	a0,8(a4)
    80001e36:	eb0c                	sd	a1,16(a4)
    80001e38:	ef10                	sd	a2,24(a4)
    80001e3a:	02078793          	addi	a5,a5,32
    80001e3e:	02070713          	addi	a4,a4,32
    80001e42:	fed792e3          	bne	a5,a3,80001e26 <fork+0x54>
  np->trace_flag = p->trace_flag;
    80001e46:	17492783          	lw	a5,372(s2)
    80001e4a:	16f9aa23          	sw	a5,372(s3)
  np->trapframe->a0 = 0;
    80001e4e:	0589b783          	ld	a5,88(s3)
    80001e52:	0607b823          	sd	zero,112(a5)
    80001e56:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e5a:	15000a13          	li	s4,336
    80001e5e:	a03d                	j	80001e8c <fork+0xba>
    freeproc(np);
    80001e60:	854e                	mv	a0,s3
    80001e62:	00000097          	auipc	ra,0x0
    80001e66:	d16080e7          	jalr	-746(ra) # 80001b78 <freeproc>
    release(&np->lock);
    80001e6a:	854e                	mv	a0,s3
    80001e6c:	fffff097          	auipc	ra,0xfffff
    80001e70:	e32080e7          	jalr	-462(ra) # 80000c9e <release>
    return -1;
    80001e74:	5a7d                	li	s4,-1
    80001e76:	a069                	j	80001f00 <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e78:	00003097          	auipc	ra,0x3
    80001e7c:	eea080e7          	jalr	-278(ra) # 80004d62 <filedup>
    80001e80:	009987b3          	add	a5,s3,s1
    80001e84:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e86:	04a1                	addi	s1,s1,8
    80001e88:	01448763          	beq	s1,s4,80001e96 <fork+0xc4>
    if(p->ofile[i])
    80001e8c:	009907b3          	add	a5,s2,s1
    80001e90:	6388                	ld	a0,0(a5)
    80001e92:	f17d                	bnez	a0,80001e78 <fork+0xa6>
    80001e94:	bfcd                	j	80001e86 <fork+0xb4>
  np->cwd = idup(p->cwd);
    80001e96:	15093503          	ld	a0,336(s2)
    80001e9a:	00002097          	auipc	ra,0x2
    80001e9e:	04e080e7          	jalr	78(ra) # 80003ee8 <idup>
    80001ea2:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ea6:	4641                	li	a2,16
    80001ea8:	15890593          	addi	a1,s2,344
    80001eac:	15898513          	addi	a0,s3,344
    80001eb0:	fffff097          	auipc	ra,0xfffff
    80001eb4:	f88080e7          	jalr	-120(ra) # 80000e38 <safestrcpy>
  pid = np->pid;
    80001eb8:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001ebc:	854e                	mv	a0,s3
    80001ebe:	fffff097          	auipc	ra,0xfffff
    80001ec2:	de0080e7          	jalr	-544(ra) # 80000c9e <release>
  acquire(&wait_lock);
    80001ec6:	0000f497          	auipc	s1,0xf
    80001eca:	f3248493          	addi	s1,s1,-206 # 80010df8 <wait_lock>
    80001ece:	8526                	mv	a0,s1
    80001ed0:	fffff097          	auipc	ra,0xfffff
    80001ed4:	d1a080e7          	jalr	-742(ra) # 80000bea <acquire>
  np->parent = p;
    80001ed8:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001edc:	8526                	mv	a0,s1
    80001ede:	fffff097          	auipc	ra,0xfffff
    80001ee2:	dc0080e7          	jalr	-576(ra) # 80000c9e <release>
  acquire(&np->lock);
    80001ee6:	854e                	mv	a0,s3
    80001ee8:	fffff097          	auipc	ra,0xfffff
    80001eec:	d02080e7          	jalr	-766(ra) # 80000bea <acquire>
  np->state = RUNNABLE;
    80001ef0:	478d                	li	a5,3
    80001ef2:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ef6:	854e                	mv	a0,s3
    80001ef8:	fffff097          	auipc	ra,0xfffff
    80001efc:	da6080e7          	jalr	-602(ra) # 80000c9e <release>
}
    80001f00:	8552                	mv	a0,s4
    80001f02:	70a2                	ld	ra,40(sp)
    80001f04:	7402                	ld	s0,32(sp)
    80001f06:	64e2                	ld	s1,24(sp)
    80001f08:	6942                	ld	s2,16(sp)
    80001f0a:	69a2                	ld	s3,8(sp)
    80001f0c:	6a02                	ld	s4,0(sp)
    80001f0e:	6145                	addi	sp,sp,48
    80001f10:	8082                	ret
    return -1;
    80001f12:	5a7d                	li	s4,-1
    80001f14:	b7f5                	j	80001f00 <fork+0x12e>

0000000080001f16 <scheduler>:
{
    80001f16:	711d                	addi	sp,sp,-96
    80001f18:	ec86                	sd	ra,88(sp)
    80001f1a:	e8a2                	sd	s0,80(sp)
    80001f1c:	e4a6                	sd	s1,72(sp)
    80001f1e:	e0ca                	sd	s2,64(sp)
    80001f20:	fc4e                	sd	s3,56(sp)
    80001f22:	f852                	sd	s4,48(sp)
    80001f24:	f456                	sd	s5,40(sp)
    80001f26:	f05a                	sd	s6,32(sp)
    80001f28:	ec5e                	sd	s7,24(sp)
    80001f2a:	e862                	sd	s8,16(sp)
    80001f2c:	e466                	sd	s9,8(sp)
    80001f2e:	1080                	addi	s0,sp,96
    80001f30:	8792                	mv	a5,tp
  int id = r_tp();
    80001f32:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f34:	00779c13          	slli	s8,a5,0x7
    80001f38:	0000f717          	auipc	a4,0xf
    80001f3c:	ea870713          	addi	a4,a4,-344 # 80010de0 <pid_lock>
    80001f40:	9762                	add	a4,a4,s8
    80001f42:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &proc_to_run->context);
    80001f46:	0000f717          	auipc	a4,0xf
    80001f4a:	ed270713          	addi	a4,a4,-302 # 80010e18 <cpus+0x8>
    80001f4e:	9c3a                	add	s8,s8,a4
        if (p->state != RUNNABLE)
    80001f50:	4a8d                	li	s5,3
      for(p = proc; p < &proc[NPROC]; p++)
    80001f52:	00016a17          	auipc	s4,0x16
    80001f56:	4bea0a13          	addi	s4,s4,1214 # 80018410 <tickslock>
      struct proc* proc_to_run = 0;
    80001f5a:	4b81                	li	s7,0
        proc_to_run->state = RUNNING;
    80001f5c:	4c91                	li	s9,4
        c->proc = proc_to_run;
    80001f5e:	079e                	slli	a5,a5,0x7
    80001f60:	0000fb17          	auipc	s6,0xf
    80001f64:	e80b0b13          	addi	s6,s6,-384 # 80010de0 <pid_lock>
    80001f68:	9b3e                	add	s6,s6,a5
    80001f6a:	a835                	j	80001fa6 <scheduler+0x90>
          release(&p->lock);
    80001f6c:	8526                	mv	a0,s1
    80001f6e:	fffff097          	auipc	ra,0xfffff
    80001f72:	d30080e7          	jalr	-720(ra) # 80000c9e <release>
      for(p = proc; p < &proc[NPROC]; p++)
    80001f76:	1c848793          	addi	a5,s1,456
    80001f7a:	0547ec63          	bltu	a5,s4,80001fd2 <scheduler+0xbc>
      if(proc_to_run != 0)
    80001f7e:	02098463          	beqz	s3,80001fa6 <scheduler+0x90>
        proc_to_run->state = RUNNING;
    80001f82:	0199ac23          	sw	s9,24(s3)
        c->proc = proc_to_run;
    80001f86:	033b3823          	sd	s3,48(s6)
        swtch(&c->context, &proc_to_run->context);
    80001f8a:	06098593          	addi	a1,s3,96
    80001f8e:	8562                	mv	a0,s8
    80001f90:	00001097          	auipc	ra,0x1
    80001f94:	918080e7          	jalr	-1768(ra) # 800028a8 <swtch>
        c->proc = 0;
    80001f98:	020b3823          	sd	zero,48(s6)
        release(&proc_to_run->lock);
    80001f9c:	854e                	mv	a0,s3
    80001f9e:	fffff097          	auipc	ra,0xfffff
    80001fa2:	d00080e7          	jalr	-768(ra) # 80000c9e <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fa6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001faa:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fae:	10079073          	csrw	sstatus,a5
      for(p = proc; p < &proc[NPROC]; p++)
    80001fb2:	0000f497          	auipc	s1,0xf
    80001fb6:	25e48493          	addi	s1,s1,606 # 80011210 <proc>
      struct proc* proc_to_run = 0;
    80001fba:	89de                	mv	s3,s7
    80001fbc:	a829                	j	80001fd6 <scheduler+0xc0>
          release(&proc_to_run->lock);
    80001fbe:	854e                	mv	a0,s3
    80001fc0:	fffff097          	auipc	ra,0xfffff
    80001fc4:	cde080e7          	jalr	-802(ra) # 80000c9e <release>
          continue;
    80001fc8:	89a6                	mv	s3,s1
      for(p = proc; p < &proc[NPROC]; p++)
    80001fca:	1c848793          	addi	a5,s1,456
    80001fce:	fb47fae3          	bgeu	a5,s4,80001f82 <scheduler+0x6c>
    80001fd2:	1c848493          	addi	s1,s1,456
        acquire(&p->lock);
    80001fd6:	8526                	mv	a0,s1
    80001fd8:	fffff097          	auipc	ra,0xfffff
    80001fdc:	c12080e7          	jalr	-1006(ra) # 80000bea <acquire>
        if (p->state != RUNNABLE)
    80001fe0:	4c9c                	lw	a5,24(s1)
    80001fe2:	f95795e3          	bne	a5,s5,80001f6c <scheduler+0x56>
        if (proc_to_run == 0)
    80001fe6:	00098e63          	beqz	s3,80002002 <scheduler+0xec>
        else if (proc_to_run->tick_creation_time > p->tick_creation_time)
    80001fea:	1909a703          	lw	a4,400(s3)
    80001fee:	1904a783          	lw	a5,400(s1)
    80001ff2:	fce7c6e3          	blt	a5,a4,80001fbe <scheduler+0xa8>
        release(&p->lock);
    80001ff6:	8526                	mv	a0,s1
    80001ff8:	fffff097          	auipc	ra,0xfffff
    80001ffc:	ca6080e7          	jalr	-858(ra) # 80000c9e <release>
    80002000:	b7e9                	j	80001fca <scheduler+0xb4>
    80002002:	89a6                	mv	s3,s1
    80002004:	b7d9                	j	80001fca <scheduler+0xb4>

0000000080002006 <sched>:
{
    80002006:	7179                	addi	sp,sp,-48
    80002008:	f406                	sd	ra,40(sp)
    8000200a:	f022                	sd	s0,32(sp)
    8000200c:	ec26                	sd	s1,24(sp)
    8000200e:	e84a                	sd	s2,16(sp)
    80002010:	e44e                	sd	s3,8(sp)
    80002012:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002014:	00000097          	auipc	ra,0x0
    80002018:	9b2080e7          	jalr	-1614(ra) # 800019c6 <myproc>
    8000201c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000201e:	fffff097          	auipc	ra,0xfffff
    80002022:	b52080e7          	jalr	-1198(ra) # 80000b70 <holding>
    80002026:	c93d                	beqz	a0,8000209c <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002028:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000202a:	2781                	sext.w	a5,a5
    8000202c:	079e                	slli	a5,a5,0x7
    8000202e:	0000f717          	auipc	a4,0xf
    80002032:	db270713          	addi	a4,a4,-590 # 80010de0 <pid_lock>
    80002036:	97ba                	add	a5,a5,a4
    80002038:	0a87a703          	lw	a4,168(a5)
    8000203c:	4785                	li	a5,1
    8000203e:	06f71763          	bne	a4,a5,800020ac <sched+0xa6>
  if(p->state == RUNNING)
    80002042:	4c98                	lw	a4,24(s1)
    80002044:	4791                	li	a5,4
    80002046:	06f70b63          	beq	a4,a5,800020bc <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000204a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000204e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002050:	efb5                	bnez	a5,800020cc <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002052:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002054:	0000f917          	auipc	s2,0xf
    80002058:	d8c90913          	addi	s2,s2,-628 # 80010de0 <pid_lock>
    8000205c:	2781                	sext.w	a5,a5
    8000205e:	079e                	slli	a5,a5,0x7
    80002060:	97ca                	add	a5,a5,s2
    80002062:	0ac7a983          	lw	s3,172(a5)
    80002066:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002068:	2781                	sext.w	a5,a5
    8000206a:	079e                	slli	a5,a5,0x7
    8000206c:	0000f597          	auipc	a1,0xf
    80002070:	dac58593          	addi	a1,a1,-596 # 80010e18 <cpus+0x8>
    80002074:	95be                	add	a1,a1,a5
    80002076:	06048513          	addi	a0,s1,96
    8000207a:	00001097          	auipc	ra,0x1
    8000207e:	82e080e7          	jalr	-2002(ra) # 800028a8 <swtch>
    80002082:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002084:	2781                	sext.w	a5,a5
    80002086:	079e                	slli	a5,a5,0x7
    80002088:	97ca                	add	a5,a5,s2
    8000208a:	0b37a623          	sw	s3,172(a5)
}
    8000208e:	70a2                	ld	ra,40(sp)
    80002090:	7402                	ld	s0,32(sp)
    80002092:	64e2                	ld	s1,24(sp)
    80002094:	6942                	ld	s2,16(sp)
    80002096:	69a2                	ld	s3,8(sp)
    80002098:	6145                	addi	sp,sp,48
    8000209a:	8082                	ret
    panic("sched p->lock");
    8000209c:	00006517          	auipc	a0,0x6
    800020a0:	17c50513          	addi	a0,a0,380 # 80008218 <digits+0x1d8>
    800020a4:	ffffe097          	auipc	ra,0xffffe
    800020a8:	4a0080e7          	jalr	1184(ra) # 80000544 <panic>
    panic("sched locks");
    800020ac:	00006517          	auipc	a0,0x6
    800020b0:	17c50513          	addi	a0,a0,380 # 80008228 <digits+0x1e8>
    800020b4:	ffffe097          	auipc	ra,0xffffe
    800020b8:	490080e7          	jalr	1168(ra) # 80000544 <panic>
    panic("sched running");
    800020bc:	00006517          	auipc	a0,0x6
    800020c0:	17c50513          	addi	a0,a0,380 # 80008238 <digits+0x1f8>
    800020c4:	ffffe097          	auipc	ra,0xffffe
    800020c8:	480080e7          	jalr	1152(ra) # 80000544 <panic>
    panic("sched interruptible");
    800020cc:	00006517          	auipc	a0,0x6
    800020d0:	17c50513          	addi	a0,a0,380 # 80008248 <digits+0x208>
    800020d4:	ffffe097          	auipc	ra,0xffffe
    800020d8:	470080e7          	jalr	1136(ra) # 80000544 <panic>

00000000800020dc <yield>:
{
    800020dc:	1101                	addi	sp,sp,-32
    800020de:	ec06                	sd	ra,24(sp)
    800020e0:	e822                	sd	s0,16(sp)
    800020e2:	e426                	sd	s1,8(sp)
    800020e4:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020e6:	00000097          	auipc	ra,0x0
    800020ea:	8e0080e7          	jalr	-1824(ra) # 800019c6 <myproc>
    800020ee:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020f0:	fffff097          	auipc	ra,0xfffff
    800020f4:	afa080e7          	jalr	-1286(ra) # 80000bea <acquire>
  p->state = RUNNABLE;
    800020f8:	478d                	li	a5,3
    800020fa:	cc9c                	sw	a5,24(s1)
  sched();
    800020fc:	00000097          	auipc	ra,0x0
    80002100:	f0a080e7          	jalr	-246(ra) # 80002006 <sched>
  release(&p->lock);
    80002104:	8526                	mv	a0,s1
    80002106:	fffff097          	auipc	ra,0xfffff
    8000210a:	b98080e7          	jalr	-1128(ra) # 80000c9e <release>
}
    8000210e:	60e2                	ld	ra,24(sp)
    80002110:	6442                	ld	s0,16(sp)
    80002112:	64a2                	ld	s1,8(sp)
    80002114:	6105                	addi	sp,sp,32
    80002116:	8082                	ret

0000000080002118 <update_time>:
{
    80002118:	7179                	addi	sp,sp,-48
    8000211a:	f406                	sd	ra,40(sp)
    8000211c:	f022                	sd	s0,32(sp)
    8000211e:	ec26                	sd	s1,24(sp)
    80002120:	e84a                	sd	s2,16(sp)
    80002122:	e44e                	sd	s3,8(sp)
    80002124:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++){
    80002126:	0000f497          	auipc	s1,0xf
    8000212a:	0ea48493          	addi	s1,s1,234 # 80011210 <proc>
    if(p->state == RUNNING) {
    8000212e:	4991                	li	s3,4
  for(p = proc; p < &proc[NPROC]; p++){
    80002130:	00016917          	auipc	s2,0x16
    80002134:	2e090913          	addi	s2,s2,736 # 80018410 <tickslock>
    80002138:	a811                	j	8000214c <update_time+0x34>
    release(&p->lock);
    8000213a:	8526                	mv	a0,s1
    8000213c:	fffff097          	auipc	ra,0xfffff
    80002140:	b62080e7          	jalr	-1182(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002144:	1c848493          	addi	s1,s1,456
    80002148:	03248563          	beq	s1,s2,80002172 <update_time+0x5a>
    acquire(&p->lock);
    8000214c:	8526                	mv	a0,s1
    8000214e:	fffff097          	auipc	ra,0xfffff
    80002152:	a9c080e7          	jalr	-1380(ra) # 80000bea <acquire>
    if(p->state == RUNNING) {
    80002156:	4c9c                	lw	a5,24(s1)
    80002158:	ff3791e3          	bne	a5,s3,8000213a <update_time+0x22>
      p->curr_rtime++;
    8000215c:	1bc4a783          	lw	a5,444(s1)
    80002160:	2785                	addiw	a5,a5,1
    80002162:	1af4ae23          	sw	a5,444(s1)
      p->rtime++;
    80002166:	1684a783          	lw	a5,360(s1)
    8000216a:	2785                	addiw	a5,a5,1
    8000216c:	16f4a423          	sw	a5,360(s1)
    80002170:	b7e9                	j	8000213a <update_time+0x22>
}
    80002172:	70a2                	ld	ra,40(sp)
    80002174:	7402                	ld	s0,32(sp)
    80002176:	64e2                	ld	s1,24(sp)
    80002178:	6942                	ld	s2,16(sp)
    8000217a:	69a2                	ld	s3,8(sp)
    8000217c:	6145                	addi	sp,sp,48
    8000217e:	8082                	ret

0000000080002180 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002180:	7179                	addi	sp,sp,-48
    80002182:	f406                	sd	ra,40(sp)
    80002184:	f022                	sd	s0,32(sp)
    80002186:	ec26                	sd	s1,24(sp)
    80002188:	e84a                	sd	s2,16(sp)
    8000218a:	e44e                	sd	s3,8(sp)
    8000218c:	1800                	addi	s0,sp,48
    8000218e:	89aa                	mv	s3,a0
    80002190:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002192:	00000097          	auipc	ra,0x0
    80002196:	834080e7          	jalr	-1996(ra) # 800019c6 <myproc>
    8000219a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000219c:	fffff097          	auipc	ra,0xfffff
    800021a0:	a4e080e7          	jalr	-1458(ra) # 80000bea <acquire>
  release(lk);
    800021a4:	854a                	mv	a0,s2
    800021a6:	fffff097          	auipc	ra,0xfffff
    800021aa:	af8080e7          	jalr	-1288(ra) # 80000c9e <release>

  // Go to sleep.
  p->chan = chan;
    800021ae:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800021b2:	4789                	li	a5,2
    800021b4:	cc9c                	sw	a5,24(s1)

  sched();
    800021b6:	00000097          	auipc	ra,0x0
    800021ba:	e50080e7          	jalr	-432(ra) # 80002006 <sched>

  // Tidy up.
  p->chan = 0;
    800021be:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800021c2:	8526                	mv	a0,s1
    800021c4:	fffff097          	auipc	ra,0xfffff
    800021c8:	ada080e7          	jalr	-1318(ra) # 80000c9e <release>
  acquire(lk);
    800021cc:	854a                	mv	a0,s2
    800021ce:	fffff097          	auipc	ra,0xfffff
    800021d2:	a1c080e7          	jalr	-1508(ra) # 80000bea <acquire>
}
    800021d6:	70a2                	ld	ra,40(sp)
    800021d8:	7402                	ld	s0,32(sp)
    800021da:	64e2                	ld	s1,24(sp)
    800021dc:	6942                	ld	s2,16(sp)
    800021de:	69a2                	ld	s3,8(sp)
    800021e0:	6145                	addi	sp,sp,48
    800021e2:	8082                	ret

00000000800021e4 <waitx>:
{
    800021e4:	711d                	addi	sp,sp,-96
    800021e6:	ec86                	sd	ra,88(sp)
    800021e8:	e8a2                	sd	s0,80(sp)
    800021ea:	e4a6                	sd	s1,72(sp)
    800021ec:	e0ca                	sd	s2,64(sp)
    800021ee:	fc4e                	sd	s3,56(sp)
    800021f0:	f852                	sd	s4,48(sp)
    800021f2:	f456                	sd	s5,40(sp)
    800021f4:	f05a                	sd	s6,32(sp)
    800021f6:	ec5e                	sd	s7,24(sp)
    800021f8:	e862                	sd	s8,16(sp)
    800021fa:	e466                	sd	s9,8(sp)
    800021fc:	e06a                	sd	s10,0(sp)
    800021fe:	1080                	addi	s0,sp,96
    80002200:	8b2a                	mv	s6,a0
    80002202:	8bae                	mv	s7,a1
    80002204:	8c32                	mv	s8,a2
  struct proc *p = myproc();
    80002206:	fffff097          	auipc	ra,0xfffff
    8000220a:	7c0080e7          	jalr	1984(ra) # 800019c6 <myproc>
    8000220e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002210:	0000f517          	auipc	a0,0xf
    80002214:	be850513          	addi	a0,a0,-1048 # 80010df8 <wait_lock>
    80002218:	fffff097          	auipc	ra,0xfffff
    8000221c:	9d2080e7          	jalr	-1582(ra) # 80000bea <acquire>
    havekids = 0;
    80002220:	4c81                	li	s9,0
        if(np->state == ZOMBIE){
    80002222:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002224:	00016997          	auipc	s3,0x16
    80002228:	1ec98993          	addi	s3,s3,492 # 80018410 <tickslock>
        havekids = 1;
    8000222c:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000222e:	0000fd17          	auipc	s10,0xf
    80002232:	bcad0d13          	addi	s10,s10,-1078 # 80010df8 <wait_lock>
    havekids = 0;
    80002236:	8766                	mv	a4,s9
    for(np = proc; np < &proc[NPROC]; np++){
    80002238:	0000f497          	auipc	s1,0xf
    8000223c:	fd848493          	addi	s1,s1,-40 # 80011210 <proc>
    80002240:	a059                	j	800022c6 <waitx+0xe2>
          pid = np->pid;
    80002242:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002246:	1684a703          	lw	a4,360(s1)
    8000224a:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    8000224e:	16c4a783          	lw	a5,364(s1)
    80002252:	9f3d                	addw	a4,a4,a5
    80002254:	1704a783          	lw	a5,368(s1)
    80002258:	9f99                	subw	a5,a5,a4
    8000225a:	00fba023          	sw	a5,0(s7) # fffffffffffff000 <end+0xffffffff7ffda490>
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000225e:	000b0e63          	beqz	s6,8000227a <waitx+0x96>
    80002262:	4691                	li	a3,4
    80002264:	02c48613          	addi	a2,s1,44
    80002268:	85da                	mv	a1,s6
    8000226a:	05093503          	ld	a0,80(s2)
    8000226e:	fffff097          	auipc	ra,0xfffff
    80002272:	416080e7          	jalr	1046(ra) # 80001684 <copyout>
    80002276:	02054563          	bltz	a0,800022a0 <waitx+0xbc>
          freeproc(np);
    8000227a:	8526                	mv	a0,s1
    8000227c:	00000097          	auipc	ra,0x0
    80002280:	8fc080e7          	jalr	-1796(ra) # 80001b78 <freeproc>
          release(&np->lock);
    80002284:	8526                	mv	a0,s1
    80002286:	fffff097          	auipc	ra,0xfffff
    8000228a:	a18080e7          	jalr	-1512(ra) # 80000c9e <release>
          release(&wait_lock);
    8000228e:	0000f517          	auipc	a0,0xf
    80002292:	b6a50513          	addi	a0,a0,-1174 # 80010df8 <wait_lock>
    80002296:	fffff097          	auipc	ra,0xfffff
    8000229a:	a08080e7          	jalr	-1528(ra) # 80000c9e <release>
          return pid;
    8000229e:	a09d                	j	80002304 <waitx+0x120>
            release(&np->lock);
    800022a0:	8526                	mv	a0,s1
    800022a2:	fffff097          	auipc	ra,0xfffff
    800022a6:	9fc080e7          	jalr	-1540(ra) # 80000c9e <release>
            release(&wait_lock);
    800022aa:	0000f517          	auipc	a0,0xf
    800022ae:	b4e50513          	addi	a0,a0,-1202 # 80010df8 <wait_lock>
    800022b2:	fffff097          	auipc	ra,0xfffff
    800022b6:	9ec080e7          	jalr	-1556(ra) # 80000c9e <release>
            return -1;
    800022ba:	59fd                	li	s3,-1
    800022bc:	a0a1                	j	80002304 <waitx+0x120>
    for(np = proc; np < &proc[NPROC]; np++){
    800022be:	1c848493          	addi	s1,s1,456
    800022c2:	03348463          	beq	s1,s3,800022ea <waitx+0x106>
      if(np->parent == p){
    800022c6:	7c9c                	ld	a5,56(s1)
    800022c8:	ff279be3          	bne	a5,s2,800022be <waitx+0xda>
        acquire(&np->lock);
    800022cc:	8526                	mv	a0,s1
    800022ce:	fffff097          	auipc	ra,0xfffff
    800022d2:	91c080e7          	jalr	-1764(ra) # 80000bea <acquire>
        if(np->state == ZOMBIE){
    800022d6:	4c9c                	lw	a5,24(s1)
    800022d8:	f74785e3          	beq	a5,s4,80002242 <waitx+0x5e>
        release(&np->lock);
    800022dc:	8526                	mv	a0,s1
    800022de:	fffff097          	auipc	ra,0xfffff
    800022e2:	9c0080e7          	jalr	-1600(ra) # 80000c9e <release>
        havekids = 1;
    800022e6:	8756                	mv	a4,s5
    800022e8:	bfd9                	j	800022be <waitx+0xda>
    if(!havekids || p->killed){
    800022ea:	c701                	beqz	a4,800022f2 <waitx+0x10e>
    800022ec:	02892783          	lw	a5,40(s2)
    800022f0:	cb8d                	beqz	a5,80002322 <waitx+0x13e>
      release(&wait_lock);
    800022f2:	0000f517          	auipc	a0,0xf
    800022f6:	b0650513          	addi	a0,a0,-1274 # 80010df8 <wait_lock>
    800022fa:	fffff097          	auipc	ra,0xfffff
    800022fe:	9a4080e7          	jalr	-1628(ra) # 80000c9e <release>
      return -1;
    80002302:	59fd                	li	s3,-1
}
    80002304:	854e                	mv	a0,s3
    80002306:	60e6                	ld	ra,88(sp)
    80002308:	6446                	ld	s0,80(sp)
    8000230a:	64a6                	ld	s1,72(sp)
    8000230c:	6906                	ld	s2,64(sp)
    8000230e:	79e2                	ld	s3,56(sp)
    80002310:	7a42                	ld	s4,48(sp)
    80002312:	7aa2                	ld	s5,40(sp)
    80002314:	7b02                	ld	s6,32(sp)
    80002316:	6be2                	ld	s7,24(sp)
    80002318:	6c42                	ld	s8,16(sp)
    8000231a:	6ca2                	ld	s9,8(sp)
    8000231c:	6d02                	ld	s10,0(sp)
    8000231e:	6125                	addi	sp,sp,96
    80002320:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002322:	85ea                	mv	a1,s10
    80002324:	854a                	mv	a0,s2
    80002326:	00000097          	auipc	ra,0x0
    8000232a:	e5a080e7          	jalr	-422(ra) # 80002180 <sleep>
    havekids = 0;
    8000232e:	b721                	j	80002236 <waitx+0x52>

0000000080002330 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002330:	7139                	addi	sp,sp,-64
    80002332:	fc06                	sd	ra,56(sp)
    80002334:	f822                	sd	s0,48(sp)
    80002336:	f426                	sd	s1,40(sp)
    80002338:	f04a                	sd	s2,32(sp)
    8000233a:	ec4e                	sd	s3,24(sp)
    8000233c:	e852                	sd	s4,16(sp)
    8000233e:	e456                	sd	s5,8(sp)
    80002340:	0080                	addi	s0,sp,64
    80002342:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002344:	0000f497          	auipc	s1,0xf
    80002348:	ecc48493          	addi	s1,s1,-308 # 80011210 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000234c:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000234e:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002350:	00016917          	auipc	s2,0x16
    80002354:	0c090913          	addi	s2,s2,192 # 80018410 <tickslock>
    80002358:	a821                	j	80002370 <wakeup+0x40>
        p->state = RUNNABLE;
    8000235a:	0154ac23          	sw	s5,24(s1)
        // #ifdef MLFQ
		    //   enqueue(p);
	      // #endif
      }
      release(&p->lock);
    8000235e:	8526                	mv	a0,s1
    80002360:	fffff097          	auipc	ra,0xfffff
    80002364:	93e080e7          	jalr	-1730(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002368:	1c848493          	addi	s1,s1,456
    8000236c:	03248463          	beq	s1,s2,80002394 <wakeup+0x64>
    if(p != myproc()){
    80002370:	fffff097          	auipc	ra,0xfffff
    80002374:	656080e7          	jalr	1622(ra) # 800019c6 <myproc>
    80002378:	fea488e3          	beq	s1,a0,80002368 <wakeup+0x38>
      acquire(&p->lock);
    8000237c:	8526                	mv	a0,s1
    8000237e:	fffff097          	auipc	ra,0xfffff
    80002382:	86c080e7          	jalr	-1940(ra) # 80000bea <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002386:	4c9c                	lw	a5,24(s1)
    80002388:	fd379be3          	bne	a5,s3,8000235e <wakeup+0x2e>
    8000238c:	709c                	ld	a5,32(s1)
    8000238e:	fd4798e3          	bne	a5,s4,8000235e <wakeup+0x2e>
    80002392:	b7e1                	j	8000235a <wakeup+0x2a>
    }
  }
}
    80002394:	70e2                	ld	ra,56(sp)
    80002396:	7442                	ld	s0,48(sp)
    80002398:	74a2                	ld	s1,40(sp)
    8000239a:	7902                	ld	s2,32(sp)
    8000239c:	69e2                	ld	s3,24(sp)
    8000239e:	6a42                	ld	s4,16(sp)
    800023a0:	6aa2                	ld	s5,8(sp)
    800023a2:	6121                	addi	sp,sp,64
    800023a4:	8082                	ret

00000000800023a6 <reparent>:
{
    800023a6:	7179                	addi	sp,sp,-48
    800023a8:	f406                	sd	ra,40(sp)
    800023aa:	f022                	sd	s0,32(sp)
    800023ac:	ec26                	sd	s1,24(sp)
    800023ae:	e84a                	sd	s2,16(sp)
    800023b0:	e44e                	sd	s3,8(sp)
    800023b2:	e052                	sd	s4,0(sp)
    800023b4:	1800                	addi	s0,sp,48
    800023b6:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800023b8:	0000f497          	auipc	s1,0xf
    800023bc:	e5848493          	addi	s1,s1,-424 # 80011210 <proc>
      pp->parent = initproc;
    800023c0:	00006a17          	auipc	s4,0x6
    800023c4:	7a8a0a13          	addi	s4,s4,1960 # 80008b68 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800023c8:	00016997          	auipc	s3,0x16
    800023cc:	04898993          	addi	s3,s3,72 # 80018410 <tickslock>
    800023d0:	a029                	j	800023da <reparent+0x34>
    800023d2:	1c848493          	addi	s1,s1,456
    800023d6:	01348d63          	beq	s1,s3,800023f0 <reparent+0x4a>
    if(pp->parent == p){
    800023da:	7c9c                	ld	a5,56(s1)
    800023dc:	ff279be3          	bne	a5,s2,800023d2 <reparent+0x2c>
      pp->parent = initproc;
    800023e0:	000a3503          	ld	a0,0(s4)
    800023e4:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800023e6:	00000097          	auipc	ra,0x0
    800023ea:	f4a080e7          	jalr	-182(ra) # 80002330 <wakeup>
    800023ee:	b7d5                	j	800023d2 <reparent+0x2c>
}
    800023f0:	70a2                	ld	ra,40(sp)
    800023f2:	7402                	ld	s0,32(sp)
    800023f4:	64e2                	ld	s1,24(sp)
    800023f6:	6942                	ld	s2,16(sp)
    800023f8:	69a2                	ld	s3,8(sp)
    800023fa:	6a02                	ld	s4,0(sp)
    800023fc:	6145                	addi	sp,sp,48
    800023fe:	8082                	ret

0000000080002400 <exit>:
{
    80002400:	7179                	addi	sp,sp,-48
    80002402:	f406                	sd	ra,40(sp)
    80002404:	f022                	sd	s0,32(sp)
    80002406:	ec26                	sd	s1,24(sp)
    80002408:	e84a                	sd	s2,16(sp)
    8000240a:	e44e                	sd	s3,8(sp)
    8000240c:	e052                	sd	s4,0(sp)
    8000240e:	1800                	addi	s0,sp,48
    80002410:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002412:	fffff097          	auipc	ra,0xfffff
    80002416:	5b4080e7          	jalr	1460(ra) # 800019c6 <myproc>
    8000241a:	89aa                	mv	s3,a0
  if(p == initproc)
    8000241c:	00006797          	auipc	a5,0x6
    80002420:	74c7b783          	ld	a5,1868(a5) # 80008b68 <initproc>
    80002424:	0d050493          	addi	s1,a0,208
    80002428:	15050913          	addi	s2,a0,336
    8000242c:	02a79363          	bne	a5,a0,80002452 <exit+0x52>
    panic("init exiting");
    80002430:	00006517          	auipc	a0,0x6
    80002434:	e3050513          	addi	a0,a0,-464 # 80008260 <digits+0x220>
    80002438:	ffffe097          	auipc	ra,0xffffe
    8000243c:	10c080e7          	jalr	268(ra) # 80000544 <panic>
      fileclose(f);
    80002440:	00003097          	auipc	ra,0x3
    80002444:	974080e7          	jalr	-1676(ra) # 80004db4 <fileclose>
      p->ofile[fd] = 0;
    80002448:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000244c:	04a1                	addi	s1,s1,8
    8000244e:	01248563          	beq	s1,s2,80002458 <exit+0x58>
    if(p->ofile[fd]){
    80002452:	6088                	ld	a0,0(s1)
    80002454:	f575                	bnez	a0,80002440 <exit+0x40>
    80002456:	bfdd                	j	8000244c <exit+0x4c>
  begin_op();
    80002458:	00002097          	auipc	ra,0x2
    8000245c:	490080e7          	jalr	1168(ra) # 800048e8 <begin_op>
  iput(p->cwd);
    80002460:	1509b503          	ld	a0,336(s3)
    80002464:	00002097          	auipc	ra,0x2
    80002468:	c7c080e7          	jalr	-900(ra) # 800040e0 <iput>
  end_op();
    8000246c:	00002097          	auipc	ra,0x2
    80002470:	4fc080e7          	jalr	1276(ra) # 80004968 <end_op>
  p->cwd = 0;
    80002474:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002478:	0000f497          	auipc	s1,0xf
    8000247c:	98048493          	addi	s1,s1,-1664 # 80010df8 <wait_lock>
    80002480:	8526                	mv	a0,s1
    80002482:	ffffe097          	auipc	ra,0xffffe
    80002486:	768080e7          	jalr	1896(ra) # 80000bea <acquire>
  reparent(p);
    8000248a:	854e                	mv	a0,s3
    8000248c:	00000097          	auipc	ra,0x0
    80002490:	f1a080e7          	jalr	-230(ra) # 800023a6 <reparent>
  wakeup(p->parent);
    80002494:	0389b503          	ld	a0,56(s3)
    80002498:	00000097          	auipc	ra,0x0
    8000249c:	e98080e7          	jalr	-360(ra) # 80002330 <wakeup>
  acquire(&p->lock);
    800024a0:	854e                	mv	a0,s3
    800024a2:	ffffe097          	auipc	ra,0xffffe
    800024a6:	748080e7          	jalr	1864(ra) # 80000bea <acquire>
  p->xstate = status;
    800024aa:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800024ae:	4795                	li	a5,5
    800024b0:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800024b4:	00006797          	auipc	a5,0x6
    800024b8:	6bc7a783          	lw	a5,1724(a5) # 80008b70 <ticks>
    800024bc:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    800024c0:	8526                	mv	a0,s1
    800024c2:	ffffe097          	auipc	ra,0xffffe
    800024c6:	7dc080e7          	jalr	2012(ra) # 80000c9e <release>
  sched();
    800024ca:	00000097          	auipc	ra,0x0
    800024ce:	b3c080e7          	jalr	-1220(ra) # 80002006 <sched>
  panic("zombie exit");
    800024d2:	00006517          	auipc	a0,0x6
    800024d6:	d9e50513          	addi	a0,a0,-610 # 80008270 <digits+0x230>
    800024da:	ffffe097          	auipc	ra,0xffffe
    800024de:	06a080e7          	jalr	106(ra) # 80000544 <panic>

00000000800024e2 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800024e2:	7179                	addi	sp,sp,-48
    800024e4:	f406                	sd	ra,40(sp)
    800024e6:	f022                	sd	s0,32(sp)
    800024e8:	ec26                	sd	s1,24(sp)
    800024ea:	e84a                	sd	s2,16(sp)
    800024ec:	e44e                	sd	s3,8(sp)
    800024ee:	1800                	addi	s0,sp,48
    800024f0:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800024f2:	0000f497          	auipc	s1,0xf
    800024f6:	d1e48493          	addi	s1,s1,-738 # 80011210 <proc>
    800024fa:	00016997          	auipc	s3,0x16
    800024fe:	f1698993          	addi	s3,s3,-234 # 80018410 <tickslock>
    acquire(&p->lock);
    80002502:	8526                	mv	a0,s1
    80002504:	ffffe097          	auipc	ra,0xffffe
    80002508:	6e6080e7          	jalr	1766(ra) # 80000bea <acquire>
    if(p->pid == pid){
    8000250c:	589c                	lw	a5,48(s1)
    8000250e:	01278d63          	beq	a5,s2,80002528 <kill+0x46>
	      // #endif
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002512:	8526                	mv	a0,s1
    80002514:	ffffe097          	auipc	ra,0xffffe
    80002518:	78a080e7          	jalr	1930(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000251c:	1c848493          	addi	s1,s1,456
    80002520:	ff3491e3          	bne	s1,s3,80002502 <kill+0x20>
  }
  return -1;
    80002524:	557d                	li	a0,-1
    80002526:	a829                	j	80002540 <kill+0x5e>
      p->killed = 1;
    80002528:	4785                	li	a5,1
    8000252a:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000252c:	4c98                	lw	a4,24(s1)
    8000252e:	4789                	li	a5,2
    80002530:	00f70f63          	beq	a4,a5,8000254e <kill+0x6c>
      release(&p->lock);
    80002534:	8526                	mv	a0,s1
    80002536:	ffffe097          	auipc	ra,0xffffe
    8000253a:	768080e7          	jalr	1896(ra) # 80000c9e <release>
      return 0;
    8000253e:	4501                	li	a0,0
}
    80002540:	70a2                	ld	ra,40(sp)
    80002542:	7402                	ld	s0,32(sp)
    80002544:	64e2                	ld	s1,24(sp)
    80002546:	6942                	ld	s2,16(sp)
    80002548:	69a2                	ld	s3,8(sp)
    8000254a:	6145                	addi	sp,sp,48
    8000254c:	8082                	ret
        p->state = RUNNABLE;
    8000254e:	478d                	li	a5,3
    80002550:	cc9c                	sw	a5,24(s1)
    80002552:	b7cd                	j	80002534 <kill+0x52>

0000000080002554 <setkilled>:

void
setkilled(struct proc *p)
{
    80002554:	1101                	addi	sp,sp,-32
    80002556:	ec06                	sd	ra,24(sp)
    80002558:	e822                	sd	s0,16(sp)
    8000255a:	e426                	sd	s1,8(sp)
    8000255c:	1000                	addi	s0,sp,32
    8000255e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002560:	ffffe097          	auipc	ra,0xffffe
    80002564:	68a080e7          	jalr	1674(ra) # 80000bea <acquire>
  p->killed = 1;
    80002568:	4785                	li	a5,1
    8000256a:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000256c:	8526                	mv	a0,s1
    8000256e:	ffffe097          	auipc	ra,0xffffe
    80002572:	730080e7          	jalr	1840(ra) # 80000c9e <release>
}
    80002576:	60e2                	ld	ra,24(sp)
    80002578:	6442                	ld	s0,16(sp)
    8000257a:	64a2                	ld	s1,8(sp)
    8000257c:	6105                	addi	sp,sp,32
    8000257e:	8082                	ret

0000000080002580 <killed>:

int
killed(struct proc *p)
{
    80002580:	1101                	addi	sp,sp,-32
    80002582:	ec06                	sd	ra,24(sp)
    80002584:	e822                	sd	s0,16(sp)
    80002586:	e426                	sd	s1,8(sp)
    80002588:	e04a                	sd	s2,0(sp)
    8000258a:	1000                	addi	s0,sp,32
    8000258c:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    8000258e:	ffffe097          	auipc	ra,0xffffe
    80002592:	65c080e7          	jalr	1628(ra) # 80000bea <acquire>
  k = p->killed;
    80002596:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000259a:	8526                	mv	a0,s1
    8000259c:	ffffe097          	auipc	ra,0xffffe
    800025a0:	702080e7          	jalr	1794(ra) # 80000c9e <release>
  return k;
}
    800025a4:	854a                	mv	a0,s2
    800025a6:	60e2                	ld	ra,24(sp)
    800025a8:	6442                	ld	s0,16(sp)
    800025aa:	64a2                	ld	s1,8(sp)
    800025ac:	6902                	ld	s2,0(sp)
    800025ae:	6105                	addi	sp,sp,32
    800025b0:	8082                	ret

00000000800025b2 <wait>:
{
    800025b2:	715d                	addi	sp,sp,-80
    800025b4:	e486                	sd	ra,72(sp)
    800025b6:	e0a2                	sd	s0,64(sp)
    800025b8:	fc26                	sd	s1,56(sp)
    800025ba:	f84a                	sd	s2,48(sp)
    800025bc:	f44e                	sd	s3,40(sp)
    800025be:	f052                	sd	s4,32(sp)
    800025c0:	ec56                	sd	s5,24(sp)
    800025c2:	e85a                	sd	s6,16(sp)
    800025c4:	e45e                	sd	s7,8(sp)
    800025c6:	e062                	sd	s8,0(sp)
    800025c8:	0880                	addi	s0,sp,80
    800025ca:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800025cc:	fffff097          	auipc	ra,0xfffff
    800025d0:	3fa080e7          	jalr	1018(ra) # 800019c6 <myproc>
    800025d4:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800025d6:	0000f517          	auipc	a0,0xf
    800025da:	82250513          	addi	a0,a0,-2014 # 80010df8 <wait_lock>
    800025de:	ffffe097          	auipc	ra,0xffffe
    800025e2:	60c080e7          	jalr	1548(ra) # 80000bea <acquire>
    havekids = 0;
    800025e6:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    800025e8:	4a15                	li	s4,5
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800025ea:	00016997          	auipc	s3,0x16
    800025ee:	e2698993          	addi	s3,s3,-474 # 80018410 <tickslock>
        havekids = 1;
    800025f2:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800025f4:	0000fc17          	auipc	s8,0xf
    800025f8:	804c0c13          	addi	s8,s8,-2044 # 80010df8 <wait_lock>
    havekids = 0;
    800025fc:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800025fe:	0000f497          	auipc	s1,0xf
    80002602:	c1248493          	addi	s1,s1,-1006 # 80011210 <proc>
    80002606:	a0bd                	j	80002674 <wait+0xc2>
          pid = pp->pid;
    80002608:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000260c:	000b0e63          	beqz	s6,80002628 <wait+0x76>
    80002610:	4691                	li	a3,4
    80002612:	02c48613          	addi	a2,s1,44
    80002616:	85da                	mv	a1,s6
    80002618:	05093503          	ld	a0,80(s2)
    8000261c:	fffff097          	auipc	ra,0xfffff
    80002620:	068080e7          	jalr	104(ra) # 80001684 <copyout>
    80002624:	02054563          	bltz	a0,8000264e <wait+0x9c>
          freeproc(pp);
    80002628:	8526                	mv	a0,s1
    8000262a:	fffff097          	auipc	ra,0xfffff
    8000262e:	54e080e7          	jalr	1358(ra) # 80001b78 <freeproc>
          release(&pp->lock);
    80002632:	8526                	mv	a0,s1
    80002634:	ffffe097          	auipc	ra,0xffffe
    80002638:	66a080e7          	jalr	1642(ra) # 80000c9e <release>
          release(&wait_lock);
    8000263c:	0000e517          	auipc	a0,0xe
    80002640:	7bc50513          	addi	a0,a0,1980 # 80010df8 <wait_lock>
    80002644:	ffffe097          	auipc	ra,0xffffe
    80002648:	65a080e7          	jalr	1626(ra) # 80000c9e <release>
          return pid;
    8000264c:	a0b5                	j	800026b8 <wait+0x106>
            release(&pp->lock);
    8000264e:	8526                	mv	a0,s1
    80002650:	ffffe097          	auipc	ra,0xffffe
    80002654:	64e080e7          	jalr	1614(ra) # 80000c9e <release>
            release(&wait_lock);
    80002658:	0000e517          	auipc	a0,0xe
    8000265c:	7a050513          	addi	a0,a0,1952 # 80010df8 <wait_lock>
    80002660:	ffffe097          	auipc	ra,0xffffe
    80002664:	63e080e7          	jalr	1598(ra) # 80000c9e <release>
            return -1;
    80002668:	59fd                	li	s3,-1
    8000266a:	a0b9                	j	800026b8 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000266c:	1c848493          	addi	s1,s1,456
    80002670:	03348463          	beq	s1,s3,80002698 <wait+0xe6>
      if(pp->parent == p){
    80002674:	7c9c                	ld	a5,56(s1)
    80002676:	ff279be3          	bne	a5,s2,8000266c <wait+0xba>
        acquire(&pp->lock);
    8000267a:	8526                	mv	a0,s1
    8000267c:	ffffe097          	auipc	ra,0xffffe
    80002680:	56e080e7          	jalr	1390(ra) # 80000bea <acquire>
        if(pp->state == ZOMBIE){
    80002684:	4c9c                	lw	a5,24(s1)
    80002686:	f94781e3          	beq	a5,s4,80002608 <wait+0x56>
        release(&pp->lock);
    8000268a:	8526                	mv	a0,s1
    8000268c:	ffffe097          	auipc	ra,0xffffe
    80002690:	612080e7          	jalr	1554(ra) # 80000c9e <release>
        havekids = 1;
    80002694:	8756                	mv	a4,s5
    80002696:	bfd9                	j	8000266c <wait+0xba>
    if(!havekids || killed(p)){
    80002698:	c719                	beqz	a4,800026a6 <wait+0xf4>
    8000269a:	854a                	mv	a0,s2
    8000269c:	00000097          	auipc	ra,0x0
    800026a0:	ee4080e7          	jalr	-284(ra) # 80002580 <killed>
    800026a4:	c51d                	beqz	a0,800026d2 <wait+0x120>
      release(&wait_lock);
    800026a6:	0000e517          	auipc	a0,0xe
    800026aa:	75250513          	addi	a0,a0,1874 # 80010df8 <wait_lock>
    800026ae:	ffffe097          	auipc	ra,0xffffe
    800026b2:	5f0080e7          	jalr	1520(ra) # 80000c9e <release>
      return -1;
    800026b6:	59fd                	li	s3,-1
}
    800026b8:	854e                	mv	a0,s3
    800026ba:	60a6                	ld	ra,72(sp)
    800026bc:	6406                	ld	s0,64(sp)
    800026be:	74e2                	ld	s1,56(sp)
    800026c0:	7942                	ld	s2,48(sp)
    800026c2:	79a2                	ld	s3,40(sp)
    800026c4:	7a02                	ld	s4,32(sp)
    800026c6:	6ae2                	ld	s5,24(sp)
    800026c8:	6b42                	ld	s6,16(sp)
    800026ca:	6ba2                	ld	s7,8(sp)
    800026cc:	6c02                	ld	s8,0(sp)
    800026ce:	6161                	addi	sp,sp,80
    800026d0:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800026d2:	85e2                	mv	a1,s8
    800026d4:	854a                	mv	a0,s2
    800026d6:	00000097          	auipc	ra,0x0
    800026da:	aaa080e7          	jalr	-1366(ra) # 80002180 <sleep>
    havekids = 0;
    800026de:	bf39                	j	800025fc <wait+0x4a>

00000000800026e0 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800026e0:	7179                	addi	sp,sp,-48
    800026e2:	f406                	sd	ra,40(sp)
    800026e4:	f022                	sd	s0,32(sp)
    800026e6:	ec26                	sd	s1,24(sp)
    800026e8:	e84a                	sd	s2,16(sp)
    800026ea:	e44e                	sd	s3,8(sp)
    800026ec:	e052                	sd	s4,0(sp)
    800026ee:	1800                	addi	s0,sp,48
    800026f0:	84aa                	mv	s1,a0
    800026f2:	892e                	mv	s2,a1
    800026f4:	89b2                	mv	s3,a2
    800026f6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026f8:	fffff097          	auipc	ra,0xfffff
    800026fc:	2ce080e7          	jalr	718(ra) # 800019c6 <myproc>
  if(user_dst){
    80002700:	c08d                	beqz	s1,80002722 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002702:	86d2                	mv	a3,s4
    80002704:	864e                	mv	a2,s3
    80002706:	85ca                	mv	a1,s2
    80002708:	6928                	ld	a0,80(a0)
    8000270a:	fffff097          	auipc	ra,0xfffff
    8000270e:	f7a080e7          	jalr	-134(ra) # 80001684 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002712:	70a2                	ld	ra,40(sp)
    80002714:	7402                	ld	s0,32(sp)
    80002716:	64e2                	ld	s1,24(sp)
    80002718:	6942                	ld	s2,16(sp)
    8000271a:	69a2                	ld	s3,8(sp)
    8000271c:	6a02                	ld	s4,0(sp)
    8000271e:	6145                	addi	sp,sp,48
    80002720:	8082                	ret
    memmove((char *)dst, src, len);
    80002722:	000a061b          	sext.w	a2,s4
    80002726:	85ce                	mv	a1,s3
    80002728:	854a                	mv	a0,s2
    8000272a:	ffffe097          	auipc	ra,0xffffe
    8000272e:	61c080e7          	jalr	1564(ra) # 80000d46 <memmove>
    return 0;
    80002732:	8526                	mv	a0,s1
    80002734:	bff9                	j	80002712 <either_copyout+0x32>

0000000080002736 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002736:	7179                	addi	sp,sp,-48
    80002738:	f406                	sd	ra,40(sp)
    8000273a:	f022                	sd	s0,32(sp)
    8000273c:	ec26                	sd	s1,24(sp)
    8000273e:	e84a                	sd	s2,16(sp)
    80002740:	e44e                	sd	s3,8(sp)
    80002742:	e052                	sd	s4,0(sp)
    80002744:	1800                	addi	s0,sp,48
    80002746:	892a                	mv	s2,a0
    80002748:	84ae                	mv	s1,a1
    8000274a:	89b2                	mv	s3,a2
    8000274c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000274e:	fffff097          	auipc	ra,0xfffff
    80002752:	278080e7          	jalr	632(ra) # 800019c6 <myproc>
  if(user_src){
    80002756:	c08d                	beqz	s1,80002778 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002758:	86d2                	mv	a3,s4
    8000275a:	864e                	mv	a2,s3
    8000275c:	85ca                	mv	a1,s2
    8000275e:	6928                	ld	a0,80(a0)
    80002760:	fffff097          	auipc	ra,0xfffff
    80002764:	fb0080e7          	jalr	-80(ra) # 80001710 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002768:	70a2                	ld	ra,40(sp)
    8000276a:	7402                	ld	s0,32(sp)
    8000276c:	64e2                	ld	s1,24(sp)
    8000276e:	6942                	ld	s2,16(sp)
    80002770:	69a2                	ld	s3,8(sp)
    80002772:	6a02                	ld	s4,0(sp)
    80002774:	6145                	addi	sp,sp,48
    80002776:	8082                	ret
    memmove(dst, (char*)src, len);
    80002778:	000a061b          	sext.w	a2,s4
    8000277c:	85ce                	mv	a1,s3
    8000277e:	854a                	mv	a0,s2
    80002780:	ffffe097          	auipc	ra,0xffffe
    80002784:	5c6080e7          	jalr	1478(ra) # 80000d46 <memmove>
    return 0;
    80002788:	8526                	mv	a0,s1
    8000278a:	bff9                	j	80002768 <either_copyin+0x32>

000000008000278c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000278c:	715d                	addi	sp,sp,-80
    8000278e:	e486                	sd	ra,72(sp)
    80002790:	e0a2                	sd	s0,64(sp)
    80002792:	fc26                	sd	s1,56(sp)
    80002794:	f84a                	sd	s2,48(sp)
    80002796:	f44e                	sd	s3,40(sp)
    80002798:	f052                	sd	s4,32(sp)
    8000279a:	ec56                	sd	s5,24(sp)
    8000279c:	e85a                	sd	s6,16(sp)
    8000279e:	e45e                	sd	s7,8(sp)
    800027a0:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800027a2:	00006517          	auipc	a0,0x6
    800027a6:	92650513          	addi	a0,a0,-1754 # 800080c8 <digits+0x88>
    800027aa:	ffffe097          	auipc	ra,0xffffe
    800027ae:	de4080e7          	jalr	-540(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800027b2:	0000f497          	auipc	s1,0xf
    800027b6:	bb648493          	addi	s1,s1,-1098 # 80011368 <proc+0x158>
    800027ba:	00016917          	auipc	s2,0x16
    800027be:	dae90913          	addi	s2,s2,-594 # 80018568 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027c2:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800027c4:	00006997          	auipc	s3,0x6
    800027c8:	abc98993          	addi	s3,s3,-1348 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800027cc:	00006a97          	auipc	s5,0x6
    800027d0:	abca8a93          	addi	s5,s5,-1348 # 80008288 <digits+0x248>
    printf("\n");
    800027d4:	00006a17          	auipc	s4,0x6
    800027d8:	8f4a0a13          	addi	s4,s4,-1804 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027dc:	00006b97          	auipc	s7,0x6
    800027e0:	aecb8b93          	addi	s7,s7,-1300 # 800082c8 <states.1780>
    800027e4:	a00d                	j	80002806 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800027e6:	ed86a583          	lw	a1,-296(a3)
    800027ea:	8556                	mv	a0,s5
    800027ec:	ffffe097          	auipc	ra,0xffffe
    800027f0:	da2080e7          	jalr	-606(ra) # 8000058e <printf>
    printf("\n");
    800027f4:	8552                	mv	a0,s4
    800027f6:	ffffe097          	auipc	ra,0xffffe
    800027fa:	d98080e7          	jalr	-616(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800027fe:	1c848493          	addi	s1,s1,456
    80002802:	03248163          	beq	s1,s2,80002824 <procdump+0x98>
    if(p->state == UNUSED)
    80002806:	86a6                	mv	a3,s1
    80002808:	ec04a783          	lw	a5,-320(s1)
    8000280c:	dbed                	beqz	a5,800027fe <procdump+0x72>
      state = "???";
    8000280e:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002810:	fcfb6be3          	bltu	s6,a5,800027e6 <procdump+0x5a>
    80002814:	1782                	slli	a5,a5,0x20
    80002816:	9381                	srli	a5,a5,0x20
    80002818:	078e                	slli	a5,a5,0x3
    8000281a:	97de                	add	a5,a5,s7
    8000281c:	6390                	ld	a2,0(a5)
    8000281e:	f661                	bnez	a2,800027e6 <procdump+0x5a>
      state = "???";
    80002820:	864e                	mv	a2,s3
    80002822:	b7d1                	j	800027e6 <procdump+0x5a>
  }
}
    80002824:	60a6                	ld	ra,72(sp)
    80002826:	6406                	ld	s0,64(sp)
    80002828:	74e2                	ld	s1,56(sp)
    8000282a:	7942                	ld	s2,48(sp)
    8000282c:	79a2                	ld	s3,40(sp)
    8000282e:	7a02                	ld	s4,32(sp)
    80002830:	6ae2                	ld	s5,24(sp)
    80002832:	6b42                	ld	s6,16(sp)
    80002834:	6ba2                	ld	s7,8(sp)
    80002836:	6161                	addi	sp,sp,80
    80002838:	8082                	ret

000000008000283a <setpriority>:

int setpriority(int new_priority, int proc_pid)
{
    8000283a:	7179                	addi	sp,sp,-48
    8000283c:	f406                	sd	ra,40(sp)
    8000283e:	f022                	sd	s0,32(sp)
    80002840:	ec26                	sd	s1,24(sp)
    80002842:	e84a                	sd	s2,16(sp)
    80002844:	e44e                	sd	s3,8(sp)
    80002846:	e052                	sd	s4,0(sp)
    80002848:	1800                	addi	s0,sp,48
    8000284a:	8a2a                	mv	s4,a0
    8000284c:	892e                	mv	s2,a1
  struct proc* p;
  int old_priority;
  int found_proc = 0;
  for(p = proc; p < &proc[NPROC]; p++)
    8000284e:	0000f497          	auipc	s1,0xf
    80002852:	9c248493          	addi	s1,s1,-1598 # 80011210 <proc>
    80002856:	00016997          	auipc	s3,0x16
    8000285a:	bba98993          	addi	s3,s3,-1094 # 80018410 <tickslock>
  {
    acquire(&p->lock);
    8000285e:	8526                	mv	a0,s1
    80002860:	ffffe097          	auipc	ra,0xffffe
    80002864:	38a080e7          	jalr	906(ra) # 80000bea <acquire>
    if (p->pid == proc_pid)
    80002868:	589c                	lw	a5,48(s1)
    8000286a:	01278d63          	beq	a5,s2,80002884 <setpriority+0x4a>
      p->priority_pbs = new_priority;
      release(&p->lock);
      found_proc = 1;
      break;
    }
    release(&p->lock);
    8000286e:	8526                	mv	a0,s1
    80002870:	ffffe097          	auipc	ra,0xffffe
    80002874:	42e080e7          	jalr	1070(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++)
    80002878:	1c848493          	addi	s1,s1,456
    8000287c:	ff3491e3          	bne	s1,s3,8000285e <setpriority+0x24>
  {
    return old_priority;
  }
  else
  {
    return -1;
    80002880:	597d                	li	s2,-1
    80002882:	a811                	j	80002896 <setpriority+0x5c>
      old_priority = p->priority_pbs;
    80002884:	1a04a903          	lw	s2,416(s1)
      p->priority_pbs = new_priority;
    80002888:	1b44a023          	sw	s4,416(s1)
      release(&p->lock);
    8000288c:	8526                	mv	a0,s1
    8000288e:	ffffe097          	auipc	ra,0xffffe
    80002892:	410080e7          	jalr	1040(ra) # 80000c9e <release>
  }
    80002896:	854a                	mv	a0,s2
    80002898:	70a2                	ld	ra,40(sp)
    8000289a:	7402                	ld	s0,32(sp)
    8000289c:	64e2                	ld	s1,24(sp)
    8000289e:	6942                	ld	s2,16(sp)
    800028a0:	69a2                	ld	s3,8(sp)
    800028a2:	6a02                	ld	s4,0(sp)
    800028a4:	6145                	addi	sp,sp,48
    800028a6:	8082                	ret

00000000800028a8 <swtch>:
    800028a8:	00153023          	sd	ra,0(a0)
    800028ac:	00253423          	sd	sp,8(a0)
    800028b0:	e900                	sd	s0,16(a0)
    800028b2:	ed04                	sd	s1,24(a0)
    800028b4:	03253023          	sd	s2,32(a0)
    800028b8:	03353423          	sd	s3,40(a0)
    800028bc:	03453823          	sd	s4,48(a0)
    800028c0:	03553c23          	sd	s5,56(a0)
    800028c4:	05653023          	sd	s6,64(a0)
    800028c8:	05753423          	sd	s7,72(a0)
    800028cc:	05853823          	sd	s8,80(a0)
    800028d0:	05953c23          	sd	s9,88(a0)
    800028d4:	07a53023          	sd	s10,96(a0)
    800028d8:	07b53423          	sd	s11,104(a0)
    800028dc:	0005b083          	ld	ra,0(a1)
    800028e0:	0085b103          	ld	sp,8(a1)
    800028e4:	6980                	ld	s0,16(a1)
    800028e6:	6d84                	ld	s1,24(a1)
    800028e8:	0205b903          	ld	s2,32(a1)
    800028ec:	0285b983          	ld	s3,40(a1)
    800028f0:	0305ba03          	ld	s4,48(a1)
    800028f4:	0385ba83          	ld	s5,56(a1)
    800028f8:	0405bb03          	ld	s6,64(a1)
    800028fc:	0485bb83          	ld	s7,72(a1)
    80002900:	0505bc03          	ld	s8,80(a1)
    80002904:	0585bc83          	ld	s9,88(a1)
    80002908:	0605bd03          	ld	s10,96(a1)
    8000290c:	0685bd83          	ld	s11,104(a1)
    80002910:	8082                	ret

0000000080002912 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002912:	1141                	addi	sp,sp,-16
    80002914:	e406                	sd	ra,8(sp)
    80002916:	e022                	sd	s0,0(sp)
    80002918:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000291a:	00006597          	auipc	a1,0x6
    8000291e:	9de58593          	addi	a1,a1,-1570 # 800082f8 <states.1780+0x30>
    80002922:	00016517          	auipc	a0,0x16
    80002926:	aee50513          	addi	a0,a0,-1298 # 80018410 <tickslock>
    8000292a:	ffffe097          	auipc	ra,0xffffe
    8000292e:	230080e7          	jalr	560(ra) # 80000b5a <initlock>
}
    80002932:	60a2                	ld	ra,8(sp)
    80002934:	6402                	ld	s0,0(sp)
    80002936:	0141                	addi	sp,sp,16
    80002938:	8082                	ret

000000008000293a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000293a:	1141                	addi	sp,sp,-16
    8000293c:	e422                	sd	s0,8(sp)
    8000293e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002940:	00004797          	auipc	a5,0x4
    80002944:	ab078793          	addi	a5,a5,-1360 # 800063f0 <kernelvec>
    80002948:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000294c:	6422                	ld	s0,8(sp)
    8000294e:	0141                	addi	sp,sp,16
    80002950:	8082                	ret

0000000080002952 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002952:	1141                	addi	sp,sp,-16
    80002954:	e406                	sd	ra,8(sp)
    80002956:	e022                	sd	s0,0(sp)
    80002958:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000295a:	fffff097          	auipc	ra,0xfffff
    8000295e:	06c080e7          	jalr	108(ra) # 800019c6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002962:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002966:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002968:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000296c:	00004617          	auipc	a2,0x4
    80002970:	69460613          	addi	a2,a2,1684 # 80007000 <_trampoline>
    80002974:	00004697          	auipc	a3,0x4
    80002978:	68c68693          	addi	a3,a3,1676 # 80007000 <_trampoline>
    8000297c:	8e91                	sub	a3,a3,a2
    8000297e:	040007b7          	lui	a5,0x4000
    80002982:	17fd                	addi	a5,a5,-1
    80002984:	07b2                	slli	a5,a5,0xc
    80002986:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002988:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000298c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000298e:	180026f3          	csrr	a3,satp
    80002992:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002994:	6d38                	ld	a4,88(a0)
    80002996:	6134                	ld	a3,64(a0)
    80002998:	6585                	lui	a1,0x1
    8000299a:	96ae                	add	a3,a3,a1
    8000299c:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000299e:	6d38                	ld	a4,88(a0)
    800029a0:	00000697          	auipc	a3,0x0
    800029a4:	13e68693          	addi	a3,a3,318 # 80002ade <usertrap>
    800029a8:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029aa:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029ac:	8692                	mv	a3,tp
    800029ae:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029b0:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029b4:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029b8:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029bc:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029c0:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029c2:	6f18                	ld	a4,24(a4)
    800029c4:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029c8:	6928                	ld	a0,80(a0)
    800029ca:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800029cc:	00004717          	auipc	a4,0x4
    800029d0:	6d070713          	addi	a4,a4,1744 # 8000709c <userret>
    800029d4:	8f11                	sub	a4,a4,a2
    800029d6:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800029d8:	577d                	li	a4,-1
    800029da:	177e                	slli	a4,a4,0x3f
    800029dc:	8d59                	or	a0,a0,a4
    800029de:	9782                	jalr	a5
}
    800029e0:	60a2                	ld	ra,8(sp)
    800029e2:	6402                	ld	s0,0(sp)
    800029e4:	0141                	addi	sp,sp,16
    800029e6:	8082                	ret

00000000800029e8 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800029e8:	1101                	addi	sp,sp,-32
    800029ea:	ec06                	sd	ra,24(sp)
    800029ec:	e822                	sd	s0,16(sp)
    800029ee:	e426                	sd	s1,8(sp)
    800029f0:	e04a                	sd	s2,0(sp)
    800029f2:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800029f4:	00016917          	auipc	s2,0x16
    800029f8:	a1c90913          	addi	s2,s2,-1508 # 80018410 <tickslock>
    800029fc:	854a                	mv	a0,s2
    800029fe:	ffffe097          	auipc	ra,0xffffe
    80002a02:	1ec080e7          	jalr	492(ra) # 80000bea <acquire>
  ticks++;
    80002a06:	00006497          	auipc	s1,0x6
    80002a0a:	16a48493          	addi	s1,s1,362 # 80008b70 <ticks>
    80002a0e:	409c                	lw	a5,0(s1)
    80002a10:	2785                	addiw	a5,a5,1
    80002a12:	c09c                	sw	a5,0(s1)
  update_time();
    80002a14:	fffff097          	auipc	ra,0xfffff
    80002a18:	704080e7          	jalr	1796(ra) # 80002118 <update_time>
  wakeup(&ticks);
    80002a1c:	8526                	mv	a0,s1
    80002a1e:	00000097          	auipc	ra,0x0
    80002a22:	912080e7          	jalr	-1774(ra) # 80002330 <wakeup>
  release(&tickslock);
    80002a26:	854a                	mv	a0,s2
    80002a28:	ffffe097          	auipc	ra,0xffffe
    80002a2c:	276080e7          	jalr	630(ra) # 80000c9e <release>
}
    80002a30:	60e2                	ld	ra,24(sp)
    80002a32:	6442                	ld	s0,16(sp)
    80002a34:	64a2                	ld	s1,8(sp)
    80002a36:	6902                	ld	s2,0(sp)
    80002a38:	6105                	addi	sp,sp,32
    80002a3a:	8082                	ret

0000000080002a3c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a3c:	1101                	addi	sp,sp,-32
    80002a3e:	ec06                	sd	ra,24(sp)
    80002a40:	e822                	sd	s0,16(sp)
    80002a42:	e426                	sd	s1,8(sp)
    80002a44:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a46:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a4a:	00074d63          	bltz	a4,80002a64 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a4e:	57fd                	li	a5,-1
    80002a50:	17fe                	slli	a5,a5,0x3f
    80002a52:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a54:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a56:	06f70363          	beq	a4,a5,80002abc <devintr+0x80>
  }
}
    80002a5a:	60e2                	ld	ra,24(sp)
    80002a5c:	6442                	ld	s0,16(sp)
    80002a5e:	64a2                	ld	s1,8(sp)
    80002a60:	6105                	addi	sp,sp,32
    80002a62:	8082                	ret
     (scause & 0xff) == 9){
    80002a64:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002a68:	46a5                	li	a3,9
    80002a6a:	fed792e3          	bne	a5,a3,80002a4e <devintr+0x12>
    int irq = plic_claim();
    80002a6e:	00004097          	auipc	ra,0x4
    80002a72:	a8a080e7          	jalr	-1398(ra) # 800064f8 <plic_claim>
    80002a76:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a78:	47a9                	li	a5,10
    80002a7a:	02f50763          	beq	a0,a5,80002aa8 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a7e:	4785                	li	a5,1
    80002a80:	02f50963          	beq	a0,a5,80002ab2 <devintr+0x76>
    return 1;
    80002a84:	4505                	li	a0,1
    } else if(irq){
    80002a86:	d8f1                	beqz	s1,80002a5a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a88:	85a6                	mv	a1,s1
    80002a8a:	00006517          	auipc	a0,0x6
    80002a8e:	87650513          	addi	a0,a0,-1930 # 80008300 <states.1780+0x38>
    80002a92:	ffffe097          	auipc	ra,0xffffe
    80002a96:	afc080e7          	jalr	-1284(ra) # 8000058e <printf>
      plic_complete(irq);
    80002a9a:	8526                	mv	a0,s1
    80002a9c:	00004097          	auipc	ra,0x4
    80002aa0:	a80080e7          	jalr	-1408(ra) # 8000651c <plic_complete>
    return 1;
    80002aa4:	4505                	li	a0,1
    80002aa6:	bf55                	j	80002a5a <devintr+0x1e>
      uartintr();
    80002aa8:	ffffe097          	auipc	ra,0xffffe
    80002aac:	f06080e7          	jalr	-250(ra) # 800009ae <uartintr>
    80002ab0:	b7ed                	j	80002a9a <devintr+0x5e>
      virtio_disk_intr();
    80002ab2:	00004097          	auipc	ra,0x4
    80002ab6:	f94080e7          	jalr	-108(ra) # 80006a46 <virtio_disk_intr>
    80002aba:	b7c5                	j	80002a9a <devintr+0x5e>
    if(cpuid() == 0){
    80002abc:	fffff097          	auipc	ra,0xfffff
    80002ac0:	ede080e7          	jalr	-290(ra) # 8000199a <cpuid>
    80002ac4:	c901                	beqz	a0,80002ad4 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002ac6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002aca:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002acc:	14479073          	csrw	sip,a5
    return 2;
    80002ad0:	4509                	li	a0,2
    80002ad2:	b761                	j	80002a5a <devintr+0x1e>
      clockintr();
    80002ad4:	00000097          	auipc	ra,0x0
    80002ad8:	f14080e7          	jalr	-236(ra) # 800029e8 <clockintr>
    80002adc:	b7ed                	j	80002ac6 <devintr+0x8a>

0000000080002ade <usertrap>:
{
    80002ade:	1101                	addi	sp,sp,-32
    80002ae0:	ec06                	sd	ra,24(sp)
    80002ae2:	e822                	sd	s0,16(sp)
    80002ae4:	e426                	sd	s1,8(sp)
    80002ae6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ae8:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002aec:	1007f793          	andi	a5,a5,256
    80002af0:	efa1                	bnez	a5,80002b48 <usertrap+0x6a>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002af2:	00004797          	auipc	a5,0x4
    80002af6:	8fe78793          	addi	a5,a5,-1794 # 800063f0 <kernelvec>
    80002afa:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002afe:	fffff097          	auipc	ra,0xfffff
    80002b02:	ec8080e7          	jalr	-312(ra) # 800019c6 <myproc>
    80002b06:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b08:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b0a:	14102773          	csrr	a4,sepc
    80002b0e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b10:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b14:	47a1                	li	a5,8
    80002b16:	04f70163          	beq	a4,a5,80002b58 <usertrap+0x7a>
  } else if((which_dev = devintr()) != 0){
    80002b1a:	00000097          	auipc	ra,0x0
    80002b1e:	f22080e7          	jalr	-222(ra) # 80002a3c <devintr>
    80002b22:	cd4d                	beqz	a0,80002bdc <usertrap+0xfe>
    if(which_dev == 2 && myproc()->interval) {
    80002b24:	4789                	li	a5,2
    80002b26:	06f50363          	beq	a0,a5,80002b8c <usertrap+0xae>
  if(killed(p))
    80002b2a:	8526                	mv	a0,s1
    80002b2c:	00000097          	auipc	ra,0x0
    80002b30:	a54080e7          	jalr	-1452(ra) # 80002580 <killed>
    80002b34:	e16d                	bnez	a0,80002c16 <usertrap+0x138>
  usertrapret();
    80002b36:	00000097          	auipc	ra,0x0
    80002b3a:	e1c080e7          	jalr	-484(ra) # 80002952 <usertrapret>
}
    80002b3e:	60e2                	ld	ra,24(sp)
    80002b40:	6442                	ld	s0,16(sp)
    80002b42:	64a2                	ld	s1,8(sp)
    80002b44:	6105                	addi	sp,sp,32
    80002b46:	8082                	ret
    panic("usertrap: not from user mode");
    80002b48:	00005517          	auipc	a0,0x5
    80002b4c:	7d850513          	addi	a0,a0,2008 # 80008320 <states.1780+0x58>
    80002b50:	ffffe097          	auipc	ra,0xffffe
    80002b54:	9f4080e7          	jalr	-1548(ra) # 80000544 <panic>
    if(killed(p))
    80002b58:	00000097          	auipc	ra,0x0
    80002b5c:	a28080e7          	jalr	-1496(ra) # 80002580 <killed>
    80002b60:	e105                	bnez	a0,80002b80 <usertrap+0xa2>
    p->trapframe->epc += 4;
    80002b62:	6cb8                	ld	a4,88(s1)
    80002b64:	6f1c                	ld	a5,24(a4)
    80002b66:	0791                	addi	a5,a5,4
    80002b68:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b6a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b6e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b72:	10079073          	csrw	sstatus,a5
    syscall();
    80002b76:	00000097          	auipc	ra,0x0
    80002b7a:	2cc080e7          	jalr	716(ra) # 80002e42 <syscall>
    80002b7e:	b775                	j	80002b2a <usertrap+0x4c>
      exit(-1);
    80002b80:	557d                	li	a0,-1
    80002b82:	00000097          	auipc	ra,0x0
    80002b86:	87e080e7          	jalr	-1922(ra) # 80002400 <exit>
    80002b8a:	bfe1                	j	80002b62 <usertrap+0x84>
    if(which_dev == 2 && myproc()->interval) {
    80002b8c:	fffff097          	auipc	ra,0xfffff
    80002b90:	e3a080e7          	jalr	-454(ra) # 800019c6 <myproc>
    80002b94:	17852783          	lw	a5,376(a0)
    80002b98:	dbc9                	beqz	a5,80002b2a <usertrap+0x4c>
      myproc()->ticks_left--;
    80002b9a:	fffff097          	auipc	ra,0xfffff
    80002b9e:	e2c080e7          	jalr	-468(ra) # 800019c6 <myproc>
    80002ba2:	17c52783          	lw	a5,380(a0)
    80002ba6:	37fd                	addiw	a5,a5,-1
    80002ba8:	16f52e23          	sw	a5,380(a0)
      if(myproc()->ticks_left == 0) {
    80002bac:	fffff097          	auipc	ra,0xfffff
    80002bb0:	e1a080e7          	jalr	-486(ra) # 800019c6 <myproc>
    80002bb4:	17c52783          	lw	a5,380(a0)
    80002bb8:	fbad                	bnez	a5,80002b2a <usertrap+0x4c>
        p->sigalarm_tf = kalloc();
    80002bba:	ffffe097          	auipc	ra,0xffffe
    80002bbe:	f40080e7          	jalr	-192(ra) # 80000afa <kalloc>
    80002bc2:	18a4b423          	sd	a0,392(s1)
        memmove(p->sigalarm_tf, p->trapframe, PGSIZE);
    80002bc6:	6605                	lui	a2,0x1
    80002bc8:	6cac                	ld	a1,88(s1)
    80002bca:	ffffe097          	auipc	ra,0xffffe
    80002bce:	17c080e7          	jalr	380(ra) # 80000d46 <memmove>
        p->trapframe->epc = p->sig_handler;
    80002bd2:	6cbc                	ld	a5,88(s1)
    80002bd4:	1804b703          	ld	a4,384(s1)
    80002bd8:	ef98                	sd	a4,24(a5)
    80002bda:	bf81                	j	80002b2a <usertrap+0x4c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bdc:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002be0:	5890                	lw	a2,48(s1)
    80002be2:	00005517          	auipc	a0,0x5
    80002be6:	75e50513          	addi	a0,a0,1886 # 80008340 <states.1780+0x78>
    80002bea:	ffffe097          	auipc	ra,0xffffe
    80002bee:	9a4080e7          	jalr	-1628(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bf2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bf6:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bfa:	00005517          	auipc	a0,0x5
    80002bfe:	77650513          	addi	a0,a0,1910 # 80008370 <states.1780+0xa8>
    80002c02:	ffffe097          	auipc	ra,0xffffe
    80002c06:	98c080e7          	jalr	-1652(ra) # 8000058e <printf>
    setkilled(p);
    80002c0a:	8526                	mv	a0,s1
    80002c0c:	00000097          	auipc	ra,0x0
    80002c10:	948080e7          	jalr	-1720(ra) # 80002554 <setkilled>
    80002c14:	bf19                	j	80002b2a <usertrap+0x4c>
    exit(-1);
    80002c16:	557d                	li	a0,-1
    80002c18:	fffff097          	auipc	ra,0xfffff
    80002c1c:	7e8080e7          	jalr	2024(ra) # 80002400 <exit>
    80002c20:	bf19                	j	80002b36 <usertrap+0x58>

0000000080002c22 <kerneltrap>:
{
    80002c22:	7179                	addi	sp,sp,-48
    80002c24:	f406                	sd	ra,40(sp)
    80002c26:	f022                	sd	s0,32(sp)
    80002c28:	ec26                	sd	s1,24(sp)
    80002c2a:	e84a                	sd	s2,16(sp)
    80002c2c:	e44e                	sd	s3,8(sp)
    80002c2e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c30:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c34:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c38:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c3c:	1004f793          	andi	a5,s1,256
    80002c40:	c78d                	beqz	a5,80002c6a <kerneltrap+0x48>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c42:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c46:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c48:	eb8d                	bnez	a5,80002c7a <kerneltrap+0x58>
  if((which_dev = devintr()) == 0){
    80002c4a:	00000097          	auipc	ra,0x0
    80002c4e:	df2080e7          	jalr	-526(ra) # 80002a3c <devintr>
    80002c52:	cd05                	beqz	a0,80002c8a <kerneltrap+0x68>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c54:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c58:	10049073          	csrw	sstatus,s1
}
    80002c5c:	70a2                	ld	ra,40(sp)
    80002c5e:	7402                	ld	s0,32(sp)
    80002c60:	64e2                	ld	s1,24(sp)
    80002c62:	6942                	ld	s2,16(sp)
    80002c64:	69a2                	ld	s3,8(sp)
    80002c66:	6145                	addi	sp,sp,48
    80002c68:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c6a:	00005517          	auipc	a0,0x5
    80002c6e:	72650513          	addi	a0,a0,1830 # 80008390 <states.1780+0xc8>
    80002c72:	ffffe097          	auipc	ra,0xffffe
    80002c76:	8d2080e7          	jalr	-1838(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    80002c7a:	00005517          	auipc	a0,0x5
    80002c7e:	73e50513          	addi	a0,a0,1854 # 800083b8 <states.1780+0xf0>
    80002c82:	ffffe097          	auipc	ra,0xffffe
    80002c86:	8c2080e7          	jalr	-1854(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    80002c8a:	85ce                	mv	a1,s3
    80002c8c:	00005517          	auipc	a0,0x5
    80002c90:	74c50513          	addi	a0,a0,1868 # 800083d8 <states.1780+0x110>
    80002c94:	ffffe097          	auipc	ra,0xffffe
    80002c98:	8fa080e7          	jalr	-1798(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c9c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ca0:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ca4:	00005517          	auipc	a0,0x5
    80002ca8:	74450513          	addi	a0,a0,1860 # 800083e8 <states.1780+0x120>
    80002cac:	ffffe097          	auipc	ra,0xffffe
    80002cb0:	8e2080e7          	jalr	-1822(ra) # 8000058e <printf>
    panic("kerneltrap");
    80002cb4:	00005517          	auipc	a0,0x5
    80002cb8:	74c50513          	addi	a0,a0,1868 # 80008400 <states.1780+0x138>
    80002cbc:	ffffe097          	auipc	ra,0xffffe
    80002cc0:	888080e7          	jalr	-1912(ra) # 80000544 <panic>

0000000080002cc4 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002cc4:	1101                	addi	sp,sp,-32
    80002cc6:	ec06                	sd	ra,24(sp)
    80002cc8:	e822                	sd	s0,16(sp)
    80002cca:	e426                	sd	s1,8(sp)
    80002ccc:	1000                	addi	s0,sp,32
    80002cce:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002cd0:	fffff097          	auipc	ra,0xfffff
    80002cd4:	cf6080e7          	jalr	-778(ra) # 800019c6 <myproc>
  switch (n) {
    80002cd8:	4795                	li	a5,5
    80002cda:	0497e163          	bltu	a5,s1,80002d1c <argraw+0x58>
    80002cde:	048a                	slli	s1,s1,0x2
    80002ce0:	00006717          	auipc	a4,0x6
    80002ce4:	8d070713          	addi	a4,a4,-1840 # 800085b0 <states.1780+0x2e8>
    80002ce8:	94ba                	add	s1,s1,a4
    80002cea:	409c                	lw	a5,0(s1)
    80002cec:	97ba                	add	a5,a5,a4
    80002cee:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002cf0:	6d3c                	ld	a5,88(a0)
    80002cf2:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002cf4:	60e2                	ld	ra,24(sp)
    80002cf6:	6442                	ld	s0,16(sp)
    80002cf8:	64a2                	ld	s1,8(sp)
    80002cfa:	6105                	addi	sp,sp,32
    80002cfc:	8082                	ret
    return p->trapframe->a1;
    80002cfe:	6d3c                	ld	a5,88(a0)
    80002d00:	7fa8                	ld	a0,120(a5)
    80002d02:	bfcd                	j	80002cf4 <argraw+0x30>
    return p->trapframe->a2;
    80002d04:	6d3c                	ld	a5,88(a0)
    80002d06:	63c8                	ld	a0,128(a5)
    80002d08:	b7f5                	j	80002cf4 <argraw+0x30>
    return p->trapframe->a3;
    80002d0a:	6d3c                	ld	a5,88(a0)
    80002d0c:	67c8                	ld	a0,136(a5)
    80002d0e:	b7dd                	j	80002cf4 <argraw+0x30>
    return p->trapframe->a4;
    80002d10:	6d3c                	ld	a5,88(a0)
    80002d12:	6bc8                	ld	a0,144(a5)
    80002d14:	b7c5                	j	80002cf4 <argraw+0x30>
    return p->trapframe->a5;
    80002d16:	6d3c                	ld	a5,88(a0)
    80002d18:	6fc8                	ld	a0,152(a5)
    80002d1a:	bfe9                	j	80002cf4 <argraw+0x30>
  panic("argraw");
    80002d1c:	00005517          	auipc	a0,0x5
    80002d20:	6f450513          	addi	a0,a0,1780 # 80008410 <states.1780+0x148>
    80002d24:	ffffe097          	auipc	ra,0xffffe
    80002d28:	820080e7          	jalr	-2016(ra) # 80000544 <panic>

0000000080002d2c <fetchaddr>:
{
    80002d2c:	1101                	addi	sp,sp,-32
    80002d2e:	ec06                	sd	ra,24(sp)
    80002d30:	e822                	sd	s0,16(sp)
    80002d32:	e426                	sd	s1,8(sp)
    80002d34:	e04a                	sd	s2,0(sp)
    80002d36:	1000                	addi	s0,sp,32
    80002d38:	84aa                	mv	s1,a0
    80002d3a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d3c:	fffff097          	auipc	ra,0xfffff
    80002d40:	c8a080e7          	jalr	-886(ra) # 800019c6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002d44:	653c                	ld	a5,72(a0)
    80002d46:	02f4f863          	bgeu	s1,a5,80002d76 <fetchaddr+0x4a>
    80002d4a:	00848713          	addi	a4,s1,8
    80002d4e:	02e7e663          	bltu	a5,a4,80002d7a <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d52:	46a1                	li	a3,8
    80002d54:	8626                	mv	a2,s1
    80002d56:	85ca                	mv	a1,s2
    80002d58:	6928                	ld	a0,80(a0)
    80002d5a:	fffff097          	auipc	ra,0xfffff
    80002d5e:	9b6080e7          	jalr	-1610(ra) # 80001710 <copyin>
    80002d62:	00a03533          	snez	a0,a0
    80002d66:	40a00533          	neg	a0,a0
}
    80002d6a:	60e2                	ld	ra,24(sp)
    80002d6c:	6442                	ld	s0,16(sp)
    80002d6e:	64a2                	ld	s1,8(sp)
    80002d70:	6902                	ld	s2,0(sp)
    80002d72:	6105                	addi	sp,sp,32
    80002d74:	8082                	ret
    return -1;
    80002d76:	557d                	li	a0,-1
    80002d78:	bfcd                	j	80002d6a <fetchaddr+0x3e>
    80002d7a:	557d                	li	a0,-1
    80002d7c:	b7fd                	j	80002d6a <fetchaddr+0x3e>

0000000080002d7e <fetchstr>:
{
    80002d7e:	7179                	addi	sp,sp,-48
    80002d80:	f406                	sd	ra,40(sp)
    80002d82:	f022                	sd	s0,32(sp)
    80002d84:	ec26                	sd	s1,24(sp)
    80002d86:	e84a                	sd	s2,16(sp)
    80002d88:	e44e                	sd	s3,8(sp)
    80002d8a:	1800                	addi	s0,sp,48
    80002d8c:	892a                	mv	s2,a0
    80002d8e:	84ae                	mv	s1,a1
    80002d90:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d92:	fffff097          	auipc	ra,0xfffff
    80002d96:	c34080e7          	jalr	-972(ra) # 800019c6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002d9a:	86ce                	mv	a3,s3
    80002d9c:	864a                	mv	a2,s2
    80002d9e:	85a6                	mv	a1,s1
    80002da0:	6928                	ld	a0,80(a0)
    80002da2:	fffff097          	auipc	ra,0xfffff
    80002da6:	9fa080e7          	jalr	-1542(ra) # 8000179c <copyinstr>
    80002daa:	00054e63          	bltz	a0,80002dc6 <fetchstr+0x48>
  return strlen(buf);
    80002dae:	8526                	mv	a0,s1
    80002db0:	ffffe097          	auipc	ra,0xffffe
    80002db4:	0ba080e7          	jalr	186(ra) # 80000e6a <strlen>
}
    80002db8:	70a2                	ld	ra,40(sp)
    80002dba:	7402                	ld	s0,32(sp)
    80002dbc:	64e2                	ld	s1,24(sp)
    80002dbe:	6942                	ld	s2,16(sp)
    80002dc0:	69a2                	ld	s3,8(sp)
    80002dc2:	6145                	addi	sp,sp,48
    80002dc4:	8082                	ret
    return -1;
    80002dc6:	557d                	li	a0,-1
    80002dc8:	bfc5                	j	80002db8 <fetchstr+0x3a>

0000000080002dca <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002dca:	1101                	addi	sp,sp,-32
    80002dcc:	ec06                	sd	ra,24(sp)
    80002dce:	e822                	sd	s0,16(sp)
    80002dd0:	e426                	sd	s1,8(sp)
    80002dd2:	1000                	addi	s0,sp,32
    80002dd4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dd6:	00000097          	auipc	ra,0x0
    80002dda:	eee080e7          	jalr	-274(ra) # 80002cc4 <argraw>
    80002dde:	c088                	sw	a0,0(s1)
}
    80002de0:	60e2                	ld	ra,24(sp)
    80002de2:	6442                	ld	s0,16(sp)
    80002de4:	64a2                	ld	s1,8(sp)
    80002de6:	6105                	addi	sp,sp,32
    80002de8:	8082                	ret

0000000080002dea <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002dea:	1101                	addi	sp,sp,-32
    80002dec:	ec06                	sd	ra,24(sp)
    80002dee:	e822                	sd	s0,16(sp)
    80002df0:	e426                	sd	s1,8(sp)
    80002df2:	1000                	addi	s0,sp,32
    80002df4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002df6:	00000097          	auipc	ra,0x0
    80002dfa:	ece080e7          	jalr	-306(ra) # 80002cc4 <argraw>
    80002dfe:	e088                	sd	a0,0(s1)
}
    80002e00:	60e2                	ld	ra,24(sp)
    80002e02:	6442                	ld	s0,16(sp)
    80002e04:	64a2                	ld	s1,8(sp)
    80002e06:	6105                	addi	sp,sp,32
    80002e08:	8082                	ret

0000000080002e0a <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e0a:	7179                	addi	sp,sp,-48
    80002e0c:	f406                	sd	ra,40(sp)
    80002e0e:	f022                	sd	s0,32(sp)
    80002e10:	ec26                	sd	s1,24(sp)
    80002e12:	e84a                	sd	s2,16(sp)
    80002e14:	1800                	addi	s0,sp,48
    80002e16:	84ae                	mv	s1,a1
    80002e18:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002e1a:	fd840593          	addi	a1,s0,-40
    80002e1e:	00000097          	auipc	ra,0x0
    80002e22:	fcc080e7          	jalr	-52(ra) # 80002dea <argaddr>
  return fetchstr(addr, buf, max);
    80002e26:	864a                	mv	a2,s2
    80002e28:	85a6                	mv	a1,s1
    80002e2a:	fd843503          	ld	a0,-40(s0)
    80002e2e:	00000097          	auipc	ra,0x0
    80002e32:	f50080e7          	jalr	-176(ra) # 80002d7e <fetchstr>
}
    80002e36:	70a2                	ld	ra,40(sp)
    80002e38:	7402                	ld	s0,32(sp)
    80002e3a:	64e2                	ld	s1,24(sp)
    80002e3c:	6942                	ld	s2,16(sp)
    80002e3e:	6145                	addi	sp,sp,48
    80002e40:	8082                	ret

0000000080002e42 <syscall>:
[SYS_setpriority] "sys_setpriority",
};

void
syscall(void)
{
    80002e42:	7179                	addi	sp,sp,-48
    80002e44:	f406                	sd	ra,40(sp)
    80002e46:	f022                	sd	s0,32(sp)
    80002e48:	ec26                	sd	s1,24(sp)
    80002e4a:	e84a                	sd	s2,16(sp)
    80002e4c:	e44e                	sd	s3,8(sp)
    80002e4e:	e052                	sd	s4,0(sp)
    80002e50:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80002e52:	fffff097          	auipc	ra,0xfffff
    80002e56:	b74080e7          	jalr	-1164(ra) # 800019c6 <myproc>
    80002e5a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e5c:	05853903          	ld	s2,88(a0)
    80002e60:	0a893783          	ld	a5,168(s2)
    80002e64:	0007899b          	sext.w	s3,a5
  unsigned int tmp = p->trapframe->a0;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e68:	37fd                	addiw	a5,a5,-1
    80002e6a:	4769                	li	a4,26
    80002e6c:	42f76863          	bltu	a4,a5,8000329c <syscall+0x45a>
    80002e70:	00399713          	slli	a4,s3,0x3
    80002e74:	00005797          	auipc	a5,0x5
    80002e78:	75478793          	addi	a5,a5,1876 # 800085c8 <syscalls>
    80002e7c:	97ba                	add	a5,a5,a4
    80002e7e:	639c                	ld	a5,0(a5)
    80002e80:	40078e63          	beqz	a5,8000329c <syscall+0x45a>
  unsigned int tmp = p->trapframe->a0;
    80002e84:	07093a03          	ld	s4,112(s2)
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002e88:	9782                	jalr	a5
    80002e8a:	06a93823          	sd	a0,112(s2)

    // Check for trace_flag to be on
    if(p->trace_flag >> num) {  // check for '=='
    80002e8e:	1744a783          	lw	a5,372(s1)
    80002e92:	4137d7bb          	sraw	a5,a5,s3
    80002e96:	42078263          	beqz	a5,800032ba <syscall+0x478>
      if(num == 1)      printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0);   //fork  
    80002e9a:	4785                	li	a5,1
    80002e9c:	0cf98263          	beq	s3,a5,80002f60 <syscall+0x11e>
  unsigned int tmp = p->trapframe->a0;
    80002ea0:	000a069b          	sext.w	a3,s4
      else if(num == 2) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // exit
    80002ea4:	4789                	li	a5,2
    80002ea6:	0cf98d63          	beq	s3,a5,80002f80 <syscall+0x13e>
      else if(num == 3) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // wait
    80002eaa:	478d                	li	a5,3
    80002eac:	0ef98a63          	beq	s3,a5,80002fa0 <syscall+0x15e>
      else if(num == 4) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // pipe
    80002eb0:	4791                	li	a5,4
    80002eb2:	10f98763          	beq	s3,a5,80002fc0 <syscall+0x17e>
      else if(num == 5) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp,  p->trapframe->a1,  p->trapframe->a2, p->trapframe->a0);  // read
    80002eb6:	4795                	li	a5,5
    80002eb8:	12f98463          	beq	s3,a5,80002fe0 <syscall+0x19e>
      else if(num == 6) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // kill
    80002ebc:	4799                	li	a5,6
    80002ebe:	14f98463          	beq	s3,a5,80003006 <syscall+0x1c4>
      else if(num == 7) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp,  p->trapframe->a1, p->trapframe->a0);   // exec
    80002ec2:	479d                	li	a5,7
    80002ec4:	16f98163          	beq	s3,a5,80003026 <syscall+0x1e4>
      else if(num == 8) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp,  p->trapframe->a1, p->trapframe->a0);  // fstat
    80002ec8:	47a1                	li	a5,8
    80002eca:	16f98f63          	beq	s3,a5,80003048 <syscall+0x206>
      else if(num == 9) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // chdir
    80002ece:	47a5                	li	a5,9
    80002ed0:	18f98d63          	beq	s3,a5,8000306a <syscall+0x228>
      else if(num == 10) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // dup
    80002ed4:	47a9                	li	a5,10
    80002ed6:	1af98a63          	beq	s3,a5,8000308a <syscall+0x248>
      else if(num == 11) printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0);  // getpid
    80002eda:	47ad                	li	a5,11
    80002edc:	1cf98763          	beq	s3,a5,800030aa <syscall+0x268>
      else if(num == 12) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // sbrk
    80002ee0:	47b1                	li	a5,12
    80002ee2:	1ef98463          	beq	s3,a5,800030ca <syscall+0x288>
      else if(num == 13) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // sleep
    80002ee6:	47b5                	li	a5,13
    80002ee8:	20f98163          	beq	s3,a5,800030ea <syscall+0x2a8>
      else if(num == 14) printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0); // uptime
    80002eec:	47b9                	li	a5,14
    80002eee:	20f98e63          	beq	s3,a5,8000310a <syscall+0x2c8>
      else if(num == 15) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a0); // open
    80002ef2:	47bd                	li	a5,15
    80002ef4:	22f98b63          	beq	s3,a5,8000312a <syscall+0x2e8>
      else if(num == 16) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a3, p->trapframe->a0); // write
    80002ef8:	47c1                	li	a5,16
    80002efa:	24f98963          	beq	s3,a5,8000314c <syscall+0x30a>
      else if(num == 17) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a3, p->trapframe->a0); // mknod
    80002efe:	47c5                	li	a5,17
    80002f00:	26f98963          	beq	s3,a5,80003172 <syscall+0x330>
      else if(num == 18) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // unlink
    80002f04:	47c9                	li	a5,18
    80002f06:	28f98963          	beq	s3,a5,80003198 <syscall+0x356>
      else if(num == 19) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a0); // link
    80002f0a:	47cd                	li	a5,19
    80002f0c:	2af98663          	beq	s3,a5,800031b8 <syscall+0x376>
      else if(num == 20) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // mkdir
    80002f10:	47d1                	li	a5,20
    80002f12:	2cf98463          	beq	s3,a5,800031da <syscall+0x398>
      else if(num == 21) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // close
    80002f16:	47d5                	li	a5,21
    80002f18:	2ef98163          	beq	s3,a5,800031fa <syscall+0x3b8>
      else if(num == 22) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // trace
    80002f1c:	47d9                	li	a5,22
    80002f1e:	2ef98e63          	beq	s3,a5,8000321a <syscall+0x3d8>
      else if(num == 23) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a0); // sigalarm
    80002f22:	47dd                	li	a5,23
    80002f24:	30f98b63          	beq	s3,a5,8000323a <syscall+0x3f8>
      else if(num == 24) printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0); // sigreturn
    80002f28:	47e1                	li	a5,24
    80002f2a:	32f98963          	beq	s3,a5,8000325c <syscall+0x41a>
      else if(num == 25) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // settickets
    80002f2e:	47e5                	li	a5,25
    80002f30:	34f98663          	beq	s3,a5,8000327c <syscall+0x43a>
      else if(num == 26) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a1, p->trapframe->a2, p->trapframe->a0); // waitx
    80002f34:	47e9                	li	a5,26
    80002f36:	38f99263          	bne	s3,a5,800032ba <syscall+0x478>
    80002f3a:	6cb8                	ld	a4,88(s1)
    80002f3c:	07073803          	ld	a6,112(a4)
    80002f40:	635c                	ld	a5,128(a4)
    80002f42:	7f38                	ld	a4,120(a4)
    80002f44:	00006617          	auipc	a2,0x6
    80002f48:	bc463603          	ld	a2,-1084(a2) # 80008b08 <syscall_names+0xd0>
    80002f4c:	588c                	lw	a1,48(s1)
    80002f4e:	00005517          	auipc	a0,0x5
    80002f52:	50250513          	addi	a0,a0,1282 # 80008450 <states.1780+0x188>
    80002f56:	ffffd097          	auipc	ra,0xffffd
    80002f5a:	638080e7          	jalr	1592(ra) # 8000058e <printf>
    80002f5e:	aeb1                	j	800032ba <syscall+0x478>
      if(num == 1)      printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0);   //fork  
    80002f60:	6cbc                	ld	a5,88(s1)
    80002f62:	7bb4                	ld	a3,112(a5)
    80002f64:	00006617          	auipc	a2,0x6
    80002f68:	adc63603          	ld	a2,-1316(a2) # 80008a40 <syscall_names+0x8>
    80002f6c:	588c                	lw	a1,48(s1)
    80002f6e:	00005517          	auipc	a0,0x5
    80002f72:	4aa50513          	addi	a0,a0,1194 # 80008418 <states.1780+0x150>
    80002f76:	ffffd097          	auipc	ra,0xffffd
    80002f7a:	618080e7          	jalr	1560(ra) # 8000058e <printf>
    80002f7e:	ae35                	j	800032ba <syscall+0x478>
      else if(num == 2) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // exit
    80002f80:	6cbc                	ld	a5,88(s1)
    80002f82:	7bb8                	ld	a4,112(a5)
    80002f84:	00006617          	auipc	a2,0x6
    80002f88:	ac463603          	ld	a2,-1340(a2) # 80008a48 <syscall_names+0x10>
    80002f8c:	588c                	lw	a1,48(s1)
    80002f8e:	00005517          	auipc	a0,0x5
    80002f92:	4a250513          	addi	a0,a0,1186 # 80008430 <states.1780+0x168>
    80002f96:	ffffd097          	auipc	ra,0xffffd
    80002f9a:	5f8080e7          	jalr	1528(ra) # 8000058e <printf>
    80002f9e:	ae31                	j	800032ba <syscall+0x478>
      else if(num == 3) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // wait
    80002fa0:	6cbc                	ld	a5,88(s1)
    80002fa2:	7bb8                	ld	a4,112(a5)
    80002fa4:	00006617          	auipc	a2,0x6
    80002fa8:	aac63603          	ld	a2,-1364(a2) # 80008a50 <syscall_names+0x18>
    80002fac:	588c                	lw	a1,48(s1)
    80002fae:	00005517          	auipc	a0,0x5
    80002fb2:	48250513          	addi	a0,a0,1154 # 80008430 <states.1780+0x168>
    80002fb6:	ffffd097          	auipc	ra,0xffffd
    80002fba:	5d8080e7          	jalr	1496(ra) # 8000058e <printf>
    80002fbe:	acf5                	j	800032ba <syscall+0x478>
      else if(num == 4) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // pipe
    80002fc0:	6cbc                	ld	a5,88(s1)
    80002fc2:	7bb8                	ld	a4,112(a5)
    80002fc4:	00006617          	auipc	a2,0x6
    80002fc8:	a9463603          	ld	a2,-1388(a2) # 80008a58 <syscall_names+0x20>
    80002fcc:	588c                	lw	a1,48(s1)
    80002fce:	00005517          	auipc	a0,0x5
    80002fd2:	46250513          	addi	a0,a0,1122 # 80008430 <states.1780+0x168>
    80002fd6:	ffffd097          	auipc	ra,0xffffd
    80002fda:	5b8080e7          	jalr	1464(ra) # 8000058e <printf>
    80002fde:	acf1                	j	800032ba <syscall+0x478>
      else if(num == 5) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp,  p->trapframe->a1,  p->trapframe->a2, p->trapframe->a0);  // read
    80002fe0:	6cb8                	ld	a4,88(s1)
    80002fe2:	07073803          	ld	a6,112(a4)
    80002fe6:	635c                	ld	a5,128(a4)
    80002fe8:	7f38                	ld	a4,120(a4)
    80002fea:	00006617          	auipc	a2,0x6
    80002fee:	a7663603          	ld	a2,-1418(a2) # 80008a60 <syscall_names+0x28>
    80002ff2:	588c                	lw	a1,48(s1)
    80002ff4:	00005517          	auipc	a0,0x5
    80002ff8:	45c50513          	addi	a0,a0,1116 # 80008450 <states.1780+0x188>
    80002ffc:	ffffd097          	auipc	ra,0xffffd
    80003000:	592080e7          	jalr	1426(ra) # 8000058e <printf>
    80003004:	ac5d                	j	800032ba <syscall+0x478>
      else if(num == 6) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // kill
    80003006:	6cbc                	ld	a5,88(s1)
    80003008:	7bb8                	ld	a4,112(a5)
    8000300a:	00006617          	auipc	a2,0x6
    8000300e:	a5e63603          	ld	a2,-1442(a2) # 80008a68 <syscall_names+0x30>
    80003012:	588c                	lw	a1,48(s1)
    80003014:	00005517          	auipc	a0,0x5
    80003018:	41c50513          	addi	a0,a0,1052 # 80008430 <states.1780+0x168>
    8000301c:	ffffd097          	auipc	ra,0xffffd
    80003020:	572080e7          	jalr	1394(ra) # 8000058e <printf>
    80003024:	ac59                	j	800032ba <syscall+0x478>
      else if(num == 7) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp,  p->trapframe->a1, p->trapframe->a0);   // exec
    80003026:	6cb8                	ld	a4,88(s1)
    80003028:	7b3c                	ld	a5,112(a4)
    8000302a:	7f38                	ld	a4,120(a4)
    8000302c:	00006617          	auipc	a2,0x6
    80003030:	a4463603          	ld	a2,-1468(a2) # 80008a70 <syscall_names+0x38>
    80003034:	588c                	lw	a1,48(s1)
    80003036:	00005517          	auipc	a0,0x5
    8000303a:	44250513          	addi	a0,a0,1090 # 80008478 <states.1780+0x1b0>
    8000303e:	ffffd097          	auipc	ra,0xffffd
    80003042:	550080e7          	jalr	1360(ra) # 8000058e <printf>
    80003046:	ac95                	j	800032ba <syscall+0x478>
      else if(num == 8) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp,  p->trapframe->a1, p->trapframe->a0);  // fstat
    80003048:	6cb8                	ld	a4,88(s1)
    8000304a:	7b3c                	ld	a5,112(a4)
    8000304c:	7f38                	ld	a4,120(a4)
    8000304e:	00006617          	auipc	a2,0x6
    80003052:	a2a63603          	ld	a2,-1494(a2) # 80008a78 <syscall_names+0x40>
    80003056:	588c                	lw	a1,48(s1)
    80003058:	00005517          	auipc	a0,0x5
    8000305c:	42050513          	addi	a0,a0,1056 # 80008478 <states.1780+0x1b0>
    80003060:	ffffd097          	auipc	ra,0xffffd
    80003064:	52e080e7          	jalr	1326(ra) # 8000058e <printf>
    80003068:	ac89                	j	800032ba <syscall+0x478>
      else if(num == 9) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // chdir
    8000306a:	6cbc                	ld	a5,88(s1)
    8000306c:	7bb8                	ld	a4,112(a5)
    8000306e:	00006617          	auipc	a2,0x6
    80003072:	a1263603          	ld	a2,-1518(a2) # 80008a80 <syscall_names+0x48>
    80003076:	588c                	lw	a1,48(s1)
    80003078:	00005517          	auipc	a0,0x5
    8000307c:	3b850513          	addi	a0,a0,952 # 80008430 <states.1780+0x168>
    80003080:	ffffd097          	auipc	ra,0xffffd
    80003084:	50e080e7          	jalr	1294(ra) # 8000058e <printf>
    80003088:	ac0d                	j	800032ba <syscall+0x478>
      else if(num == 10) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // dup
    8000308a:	6cbc                	ld	a5,88(s1)
    8000308c:	7bb8                	ld	a4,112(a5)
    8000308e:	00006617          	auipc	a2,0x6
    80003092:	9fa63603          	ld	a2,-1542(a2) # 80008a88 <syscall_names+0x50>
    80003096:	588c                	lw	a1,48(s1)
    80003098:	00005517          	auipc	a0,0x5
    8000309c:	39850513          	addi	a0,a0,920 # 80008430 <states.1780+0x168>
    800030a0:	ffffd097          	auipc	ra,0xffffd
    800030a4:	4ee080e7          	jalr	1262(ra) # 8000058e <printf>
    800030a8:	ac09                	j	800032ba <syscall+0x478>
      else if(num == 11) printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0);  // getpid
    800030aa:	6cbc                	ld	a5,88(s1)
    800030ac:	7bb4                	ld	a3,112(a5)
    800030ae:	00006617          	auipc	a2,0x6
    800030b2:	9e263603          	ld	a2,-1566(a2) # 80008a90 <syscall_names+0x58>
    800030b6:	588c                	lw	a1,48(s1)
    800030b8:	00005517          	auipc	a0,0x5
    800030bc:	36050513          	addi	a0,a0,864 # 80008418 <states.1780+0x150>
    800030c0:	ffffd097          	auipc	ra,0xffffd
    800030c4:	4ce080e7          	jalr	1230(ra) # 8000058e <printf>
    800030c8:	aacd                	j	800032ba <syscall+0x478>
      else if(num == 12) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // sbrk
    800030ca:	6cbc                	ld	a5,88(s1)
    800030cc:	7bb8                	ld	a4,112(a5)
    800030ce:	00006617          	auipc	a2,0x6
    800030d2:	9ca63603          	ld	a2,-1590(a2) # 80008a98 <syscall_names+0x60>
    800030d6:	588c                	lw	a1,48(s1)
    800030d8:	00005517          	auipc	a0,0x5
    800030dc:	35850513          	addi	a0,a0,856 # 80008430 <states.1780+0x168>
    800030e0:	ffffd097          	auipc	ra,0xffffd
    800030e4:	4ae080e7          	jalr	1198(ra) # 8000058e <printf>
    800030e8:	aac9                	j	800032ba <syscall+0x478>
      else if(num == 13) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // sleep
    800030ea:	6cbc                	ld	a5,88(s1)
    800030ec:	7bb8                	ld	a4,112(a5)
    800030ee:	00006617          	auipc	a2,0x6
    800030f2:	9b263603          	ld	a2,-1614(a2) # 80008aa0 <syscall_names+0x68>
    800030f6:	588c                	lw	a1,48(s1)
    800030f8:	00005517          	auipc	a0,0x5
    800030fc:	33850513          	addi	a0,a0,824 # 80008430 <states.1780+0x168>
    80003100:	ffffd097          	auipc	ra,0xffffd
    80003104:	48e080e7          	jalr	1166(ra) # 8000058e <printf>
    80003108:	aa4d                	j	800032ba <syscall+0x478>
      else if(num == 14) printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0); // uptime
    8000310a:	6cbc                	ld	a5,88(s1)
    8000310c:	7bb4                	ld	a3,112(a5)
    8000310e:	00006617          	auipc	a2,0x6
    80003112:	99a63603          	ld	a2,-1638(a2) # 80008aa8 <syscall_names+0x70>
    80003116:	588c                	lw	a1,48(s1)
    80003118:	00005517          	auipc	a0,0x5
    8000311c:	30050513          	addi	a0,a0,768 # 80008418 <states.1780+0x150>
    80003120:	ffffd097          	auipc	ra,0xffffd
    80003124:	46e080e7          	jalr	1134(ra) # 8000058e <printf>
    80003128:	aa49                	j	800032ba <syscall+0x478>
      else if(num == 15) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a0); // open
    8000312a:	6cb8                	ld	a4,88(s1)
    8000312c:	7b3c                	ld	a5,112(a4)
    8000312e:	6358                	ld	a4,128(a4)
    80003130:	00006617          	auipc	a2,0x6
    80003134:	98063603          	ld	a2,-1664(a2) # 80008ab0 <syscall_names+0x78>
    80003138:	588c                	lw	a1,48(s1)
    8000313a:	00005517          	auipc	a0,0x5
    8000313e:	33e50513          	addi	a0,a0,830 # 80008478 <states.1780+0x1b0>
    80003142:	ffffd097          	auipc	ra,0xffffd
    80003146:	44c080e7          	jalr	1100(ra) # 8000058e <printf>
    8000314a:	aa85                	j	800032ba <syscall+0x478>
      else if(num == 16) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a3, p->trapframe->a0); // write
    8000314c:	6cb8                	ld	a4,88(s1)
    8000314e:	07073803          	ld	a6,112(a4)
    80003152:	675c                	ld	a5,136(a4)
    80003154:	6358                	ld	a4,128(a4)
    80003156:	00006617          	auipc	a2,0x6
    8000315a:	96263603          	ld	a2,-1694(a2) # 80008ab8 <syscall_names+0x80>
    8000315e:	588c                	lw	a1,48(s1)
    80003160:	00005517          	auipc	a0,0x5
    80003164:	2f050513          	addi	a0,a0,752 # 80008450 <states.1780+0x188>
    80003168:	ffffd097          	auipc	ra,0xffffd
    8000316c:	426080e7          	jalr	1062(ra) # 8000058e <printf>
    80003170:	a2a9                	j	800032ba <syscall+0x478>
      else if(num == 17) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a3, p->trapframe->a0); // mknod
    80003172:	6cb8                	ld	a4,88(s1)
    80003174:	07073803          	ld	a6,112(a4)
    80003178:	675c                	ld	a5,136(a4)
    8000317a:	6358                	ld	a4,128(a4)
    8000317c:	00006617          	auipc	a2,0x6
    80003180:	94463603          	ld	a2,-1724(a2) # 80008ac0 <syscall_names+0x88>
    80003184:	588c                	lw	a1,48(s1)
    80003186:	00005517          	auipc	a0,0x5
    8000318a:	2ca50513          	addi	a0,a0,714 # 80008450 <states.1780+0x188>
    8000318e:	ffffd097          	auipc	ra,0xffffd
    80003192:	400080e7          	jalr	1024(ra) # 8000058e <printf>
    80003196:	a215                	j	800032ba <syscall+0x478>
      else if(num == 18) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // unlink
    80003198:	6cbc                	ld	a5,88(s1)
    8000319a:	7bb8                	ld	a4,112(a5)
    8000319c:	00006617          	auipc	a2,0x6
    800031a0:	92c63603          	ld	a2,-1748(a2) # 80008ac8 <syscall_names+0x90>
    800031a4:	588c                	lw	a1,48(s1)
    800031a6:	00005517          	auipc	a0,0x5
    800031aa:	28a50513          	addi	a0,a0,650 # 80008430 <states.1780+0x168>
    800031ae:	ffffd097          	auipc	ra,0xffffd
    800031b2:	3e0080e7          	jalr	992(ra) # 8000058e <printf>
    800031b6:	a211                	j	800032ba <syscall+0x478>
      else if(num == 19) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a0); // link
    800031b8:	6cb8                	ld	a4,88(s1)
    800031ba:	7b3c                	ld	a5,112(a4)
    800031bc:	6358                	ld	a4,128(a4)
    800031be:	00006617          	auipc	a2,0x6
    800031c2:	91263603          	ld	a2,-1774(a2) # 80008ad0 <syscall_names+0x98>
    800031c6:	588c                	lw	a1,48(s1)
    800031c8:	00005517          	auipc	a0,0x5
    800031cc:	2b050513          	addi	a0,a0,688 # 80008478 <states.1780+0x1b0>
    800031d0:	ffffd097          	auipc	ra,0xffffd
    800031d4:	3be080e7          	jalr	958(ra) # 8000058e <printf>
    800031d8:	a0cd                	j	800032ba <syscall+0x478>
      else if(num == 20) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // mkdir
    800031da:	6cbc                	ld	a5,88(s1)
    800031dc:	7bb8                	ld	a4,112(a5)
    800031de:	00006617          	auipc	a2,0x6
    800031e2:	8fa63603          	ld	a2,-1798(a2) # 80008ad8 <syscall_names+0xa0>
    800031e6:	588c                	lw	a1,48(s1)
    800031e8:	00005517          	auipc	a0,0x5
    800031ec:	24850513          	addi	a0,a0,584 # 80008430 <states.1780+0x168>
    800031f0:	ffffd097          	auipc	ra,0xffffd
    800031f4:	39e080e7          	jalr	926(ra) # 8000058e <printf>
    800031f8:	a0c9                	j	800032ba <syscall+0x478>
      else if(num == 21) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // close
    800031fa:	6cbc                	ld	a5,88(s1)
    800031fc:	7bb8                	ld	a4,112(a5)
    800031fe:	00006617          	auipc	a2,0x6
    80003202:	8e263603          	ld	a2,-1822(a2) # 80008ae0 <syscall_names+0xa8>
    80003206:	588c                	lw	a1,48(s1)
    80003208:	00005517          	auipc	a0,0x5
    8000320c:	22850513          	addi	a0,a0,552 # 80008430 <states.1780+0x168>
    80003210:	ffffd097          	auipc	ra,0xffffd
    80003214:	37e080e7          	jalr	894(ra) # 8000058e <printf>
    80003218:	a04d                	j	800032ba <syscall+0x478>
      else if(num == 22) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // trace
    8000321a:	6cbc                	ld	a5,88(s1)
    8000321c:	7bb8                	ld	a4,112(a5)
    8000321e:	00006617          	auipc	a2,0x6
    80003222:	8ca63603          	ld	a2,-1846(a2) # 80008ae8 <syscall_names+0xb0>
    80003226:	588c                	lw	a1,48(s1)
    80003228:	00005517          	auipc	a0,0x5
    8000322c:	20850513          	addi	a0,a0,520 # 80008430 <states.1780+0x168>
    80003230:	ffffd097          	auipc	ra,0xffffd
    80003234:	35e080e7          	jalr	862(ra) # 8000058e <printf>
    80003238:	a049                	j	800032ba <syscall+0x478>
      else if(num == 23) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a0); // sigalarm
    8000323a:	6cb8                	ld	a4,88(s1)
    8000323c:	7b3c                	ld	a5,112(a4)
    8000323e:	6358                	ld	a4,128(a4)
    80003240:	00006617          	auipc	a2,0x6
    80003244:	8b063603          	ld	a2,-1872(a2) # 80008af0 <syscall_names+0xb8>
    80003248:	588c                	lw	a1,48(s1)
    8000324a:	00005517          	auipc	a0,0x5
    8000324e:	22e50513          	addi	a0,a0,558 # 80008478 <states.1780+0x1b0>
    80003252:	ffffd097          	auipc	ra,0xffffd
    80003256:	33c080e7          	jalr	828(ra) # 8000058e <printf>
    8000325a:	a085                	j	800032ba <syscall+0x478>
      else if(num == 24) printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0); // sigreturn
    8000325c:	6cbc                	ld	a5,88(s1)
    8000325e:	7bb4                	ld	a3,112(a5)
    80003260:	00006617          	auipc	a2,0x6
    80003264:	89863603          	ld	a2,-1896(a2) # 80008af8 <syscall_names+0xc0>
    80003268:	588c                	lw	a1,48(s1)
    8000326a:	00005517          	auipc	a0,0x5
    8000326e:	1ae50513          	addi	a0,a0,430 # 80008418 <states.1780+0x150>
    80003272:	ffffd097          	auipc	ra,0xffffd
    80003276:	31c080e7          	jalr	796(ra) # 8000058e <printf>
    8000327a:	a081                	j	800032ba <syscall+0x478>
      else if(num == 25) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // settickets
    8000327c:	6cbc                	ld	a5,88(s1)
    8000327e:	7bb8                	ld	a4,112(a5)
    80003280:	00006617          	auipc	a2,0x6
    80003284:	88063603          	ld	a2,-1920(a2) # 80008b00 <syscall_names+0xc8>
    80003288:	588c                	lw	a1,48(s1)
    8000328a:	00005517          	auipc	a0,0x5
    8000328e:	1a650513          	addi	a0,a0,422 # 80008430 <states.1780+0x168>
    80003292:	ffffd097          	auipc	ra,0xffffd
    80003296:	2fc080e7          	jalr	764(ra) # 8000058e <printf>
    8000329a:	a005                	j	800032ba <syscall+0x478>
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    8000329c:	86ce                	mv	a3,s3
    8000329e:	15848613          	addi	a2,s1,344
    800032a2:	588c                	lw	a1,48(s1)
    800032a4:	00005517          	auipc	a0,0x5
    800032a8:	1f450513          	addi	a0,a0,500 # 80008498 <states.1780+0x1d0>
    800032ac:	ffffd097          	auipc	ra,0xffffd
    800032b0:	2e2080e7          	jalr	738(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800032b4:	6cbc                	ld	a5,88(s1)
    800032b6:	577d                	li	a4,-1
    800032b8:	fbb8                	sd	a4,112(a5)
  }
}
    800032ba:	70a2                	ld	ra,40(sp)
    800032bc:	7402                	ld	s0,32(sp)
    800032be:	64e2                	ld	s1,24(sp)
    800032c0:	6942                	ld	s2,16(sp)
    800032c2:	69a2                	ld	s3,8(sp)
    800032c4:	6a02                	ld	s4,0(sp)
    800032c6:	6145                	addi	sp,sp,48
    800032c8:	8082                	ret

00000000800032ca <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800032ca:	1101                	addi	sp,sp,-32
    800032cc:	ec06                	sd	ra,24(sp)
    800032ce:	e822                	sd	s0,16(sp)
    800032d0:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    800032d2:	fec40593          	addi	a1,s0,-20
    800032d6:	4501                	li	a0,0
    800032d8:	00000097          	auipc	ra,0x0
    800032dc:	af2080e7          	jalr	-1294(ra) # 80002dca <argint>
  exit(n);
    800032e0:	fec42503          	lw	a0,-20(s0)
    800032e4:	fffff097          	auipc	ra,0xfffff
    800032e8:	11c080e7          	jalr	284(ra) # 80002400 <exit>
  return 0;  // not reached
}
    800032ec:	4501                	li	a0,0
    800032ee:	60e2                	ld	ra,24(sp)
    800032f0:	6442                	ld	s0,16(sp)
    800032f2:	6105                	addi	sp,sp,32
    800032f4:	8082                	ret

00000000800032f6 <sys_getpid>:

uint64
sys_getpid(void)
{
    800032f6:	1141                	addi	sp,sp,-16
    800032f8:	e406                	sd	ra,8(sp)
    800032fa:	e022                	sd	s0,0(sp)
    800032fc:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800032fe:	ffffe097          	auipc	ra,0xffffe
    80003302:	6c8080e7          	jalr	1736(ra) # 800019c6 <myproc>
}
    80003306:	5908                	lw	a0,48(a0)
    80003308:	60a2                	ld	ra,8(sp)
    8000330a:	6402                	ld	s0,0(sp)
    8000330c:	0141                	addi	sp,sp,16
    8000330e:	8082                	ret

0000000080003310 <sys_fork>:

uint64
sys_fork(void)
{
    80003310:	1141                	addi	sp,sp,-16
    80003312:	e406                	sd	ra,8(sp)
    80003314:	e022                	sd	s0,0(sp)
    80003316:	0800                	addi	s0,sp,16
  return fork();
    80003318:	fffff097          	auipc	ra,0xfffff
    8000331c:	aba080e7          	jalr	-1350(ra) # 80001dd2 <fork>
}
    80003320:	60a2                	ld	ra,8(sp)
    80003322:	6402                	ld	s0,0(sp)
    80003324:	0141                	addi	sp,sp,16
    80003326:	8082                	ret

0000000080003328 <sys_wait>:

uint64
sys_wait(void)
{
    80003328:	1101                	addi	sp,sp,-32
    8000332a:	ec06                	sd	ra,24(sp)
    8000332c:	e822                	sd	s0,16(sp)
    8000332e:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003330:	fe840593          	addi	a1,s0,-24
    80003334:	4501                	li	a0,0
    80003336:	00000097          	auipc	ra,0x0
    8000333a:	ab4080e7          	jalr	-1356(ra) # 80002dea <argaddr>
  return wait(p);
    8000333e:	fe843503          	ld	a0,-24(s0)
    80003342:	fffff097          	auipc	ra,0xfffff
    80003346:	270080e7          	jalr	624(ra) # 800025b2 <wait>
}
    8000334a:	60e2                	ld	ra,24(sp)
    8000334c:	6442                	ld	s0,16(sp)
    8000334e:	6105                	addi	sp,sp,32
    80003350:	8082                	ret

0000000080003352 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003352:	7179                	addi	sp,sp,-48
    80003354:	f406                	sd	ra,40(sp)
    80003356:	f022                	sd	s0,32(sp)
    80003358:	ec26                	sd	s1,24(sp)
    8000335a:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    8000335c:	fdc40593          	addi	a1,s0,-36
    80003360:	4501                	li	a0,0
    80003362:	00000097          	auipc	ra,0x0
    80003366:	a68080e7          	jalr	-1432(ra) # 80002dca <argint>
  addr = myproc()->sz;
    8000336a:	ffffe097          	auipc	ra,0xffffe
    8000336e:	65c080e7          	jalr	1628(ra) # 800019c6 <myproc>
    80003372:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80003374:	fdc42503          	lw	a0,-36(s0)
    80003378:	fffff097          	auipc	ra,0xfffff
    8000337c:	9fe080e7          	jalr	-1538(ra) # 80001d76 <growproc>
    80003380:	00054863          	bltz	a0,80003390 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80003384:	8526                	mv	a0,s1
    80003386:	70a2                	ld	ra,40(sp)
    80003388:	7402                	ld	s0,32(sp)
    8000338a:	64e2                	ld	s1,24(sp)
    8000338c:	6145                	addi	sp,sp,48
    8000338e:	8082                	ret
    return -1;
    80003390:	54fd                	li	s1,-1
    80003392:	bfcd                	j	80003384 <sys_sbrk+0x32>

0000000080003394 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003394:	7139                	addi	sp,sp,-64
    80003396:	fc06                	sd	ra,56(sp)
    80003398:	f822                	sd	s0,48(sp)
    8000339a:	f426                	sd	s1,40(sp)
    8000339c:	f04a                	sd	s2,32(sp)
    8000339e:	ec4e                	sd	s3,24(sp)
    800033a0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800033a2:	fcc40593          	addi	a1,s0,-52
    800033a6:	4501                	li	a0,0
    800033a8:	00000097          	auipc	ra,0x0
    800033ac:	a22080e7          	jalr	-1502(ra) # 80002dca <argint>
  acquire(&tickslock);
    800033b0:	00015517          	auipc	a0,0x15
    800033b4:	06050513          	addi	a0,a0,96 # 80018410 <tickslock>
    800033b8:	ffffe097          	auipc	ra,0xffffe
    800033bc:	832080e7          	jalr	-1998(ra) # 80000bea <acquire>
  ticks0 = ticks;
    800033c0:	00005917          	auipc	s2,0x5
    800033c4:	7b092903          	lw	s2,1968(s2) # 80008b70 <ticks>
  while(ticks - ticks0 < n){
    800033c8:	fcc42783          	lw	a5,-52(s0)
    800033cc:	cf9d                	beqz	a5,8000340a <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800033ce:	00015997          	auipc	s3,0x15
    800033d2:	04298993          	addi	s3,s3,66 # 80018410 <tickslock>
    800033d6:	00005497          	auipc	s1,0x5
    800033da:	79a48493          	addi	s1,s1,1946 # 80008b70 <ticks>
    if(killed(myproc())){
    800033de:	ffffe097          	auipc	ra,0xffffe
    800033e2:	5e8080e7          	jalr	1512(ra) # 800019c6 <myproc>
    800033e6:	fffff097          	auipc	ra,0xfffff
    800033ea:	19a080e7          	jalr	410(ra) # 80002580 <killed>
    800033ee:	ed15                	bnez	a0,8000342a <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    800033f0:	85ce                	mv	a1,s3
    800033f2:	8526                	mv	a0,s1
    800033f4:	fffff097          	auipc	ra,0xfffff
    800033f8:	d8c080e7          	jalr	-628(ra) # 80002180 <sleep>
  while(ticks - ticks0 < n){
    800033fc:	409c                	lw	a5,0(s1)
    800033fe:	412787bb          	subw	a5,a5,s2
    80003402:	fcc42703          	lw	a4,-52(s0)
    80003406:	fce7ece3          	bltu	a5,a4,800033de <sys_sleep+0x4a>
  }
  release(&tickslock);
    8000340a:	00015517          	auipc	a0,0x15
    8000340e:	00650513          	addi	a0,a0,6 # 80018410 <tickslock>
    80003412:	ffffe097          	auipc	ra,0xffffe
    80003416:	88c080e7          	jalr	-1908(ra) # 80000c9e <release>
  return 0;
    8000341a:	4501                	li	a0,0
}
    8000341c:	70e2                	ld	ra,56(sp)
    8000341e:	7442                	ld	s0,48(sp)
    80003420:	74a2                	ld	s1,40(sp)
    80003422:	7902                	ld	s2,32(sp)
    80003424:	69e2                	ld	s3,24(sp)
    80003426:	6121                	addi	sp,sp,64
    80003428:	8082                	ret
      release(&tickslock);
    8000342a:	00015517          	auipc	a0,0x15
    8000342e:	fe650513          	addi	a0,a0,-26 # 80018410 <tickslock>
    80003432:	ffffe097          	auipc	ra,0xffffe
    80003436:	86c080e7          	jalr	-1940(ra) # 80000c9e <release>
      return -1;
    8000343a:	557d                	li	a0,-1
    8000343c:	b7c5                	j	8000341c <sys_sleep+0x88>

000000008000343e <sys_kill>:

uint64
sys_kill(void)
{
    8000343e:	1101                	addi	sp,sp,-32
    80003440:	ec06                	sd	ra,24(sp)
    80003442:	e822                	sd	s0,16(sp)
    80003444:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003446:	fec40593          	addi	a1,s0,-20
    8000344a:	4501                	li	a0,0
    8000344c:	00000097          	auipc	ra,0x0
    80003450:	97e080e7          	jalr	-1666(ra) # 80002dca <argint>
  return kill(pid);
    80003454:	fec42503          	lw	a0,-20(s0)
    80003458:	fffff097          	auipc	ra,0xfffff
    8000345c:	08a080e7          	jalr	138(ra) # 800024e2 <kill>
}
    80003460:	60e2                	ld	ra,24(sp)
    80003462:	6442                	ld	s0,16(sp)
    80003464:	6105                	addi	sp,sp,32
    80003466:	8082                	ret

0000000080003468 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003468:	1101                	addi	sp,sp,-32
    8000346a:	ec06                	sd	ra,24(sp)
    8000346c:	e822                	sd	s0,16(sp)
    8000346e:	e426                	sd	s1,8(sp)
    80003470:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003472:	00015517          	auipc	a0,0x15
    80003476:	f9e50513          	addi	a0,a0,-98 # 80018410 <tickslock>
    8000347a:	ffffd097          	auipc	ra,0xffffd
    8000347e:	770080e7          	jalr	1904(ra) # 80000bea <acquire>
  xticks = ticks;
    80003482:	00005497          	auipc	s1,0x5
    80003486:	6ee4a483          	lw	s1,1774(s1) # 80008b70 <ticks>
  release(&tickslock);
    8000348a:	00015517          	auipc	a0,0x15
    8000348e:	f8650513          	addi	a0,a0,-122 # 80018410 <tickslock>
    80003492:	ffffe097          	auipc	ra,0xffffe
    80003496:	80c080e7          	jalr	-2036(ra) # 80000c9e <release>
  return xticks;
}
    8000349a:	02049513          	slli	a0,s1,0x20
    8000349e:	9101                	srli	a0,a0,0x20
    800034a0:	60e2                	ld	ra,24(sp)
    800034a2:	6442                	ld	s0,16(sp)
    800034a4:	64a2                	ld	s1,8(sp)
    800034a6:	6105                	addi	sp,sp,32
    800034a8:	8082                	ret

00000000800034aa <sys_trace>:

// sets the trace_flag to the first argument (a0)
uint64
sys_trace(void)
{
    800034aa:	1141                	addi	sp,sp,-16
    800034ac:	e406                	sd	ra,8(sp)
    800034ae:	e022                	sd	s0,0(sp)
    800034b0:	0800                	addi	s0,sp,16
  argint(0, &myproc()->trace_flag); //arg(a0, trace_flag) // returns void
    800034b2:	ffffe097          	auipc	ra,0xffffe
    800034b6:	514080e7          	jalr	1300(ra) # 800019c6 <myproc>
    800034ba:	17450593          	addi	a1,a0,372
    800034be:	4501                	li	a0,0
    800034c0:	00000097          	auipc	ra,0x0
    800034c4:	90a080e7          	jalr	-1782(ra) # 80002dca <argint>
  return 0;
}
    800034c8:	4501                	li	a0,0
    800034ca:	60a2                	ld	ra,8(sp)
    800034cc:	6402                	ld	s0,0(sp)
    800034ce:	0141                	addi	sp,sp,16
    800034d0:	8082                	ret

00000000800034d2 <sys_sigalarm>:

// sets the 
uint64
sys_sigalarm(void)
{
    800034d2:	1101                	addi	sp,sp,-32
    800034d4:	ec06                	sd	ra,24(sp)
    800034d6:	e822                	sd	s0,16(sp)
    800034d8:	e426                	sd	s1,8(sp)
    800034da:	1000                	addi	s0,sp,32
  // sets the interval and handler after every tick
  argint(0, &myproc()->interval);
    800034dc:	ffffe097          	auipc	ra,0xffffe
    800034e0:	4ea080e7          	jalr	1258(ra) # 800019c6 <myproc>
    800034e4:	17850593          	addi	a1,a0,376
    800034e8:	4501                	li	a0,0
    800034ea:	00000097          	auipc	ra,0x0
    800034ee:	8e0080e7          	jalr	-1824(ra) # 80002dca <argint>
  argaddr(1, &myproc()->sig_handler);
    800034f2:	ffffe097          	auipc	ra,0xffffe
    800034f6:	4d4080e7          	jalr	1236(ra) # 800019c6 <myproc>
    800034fa:	18050593          	addi	a1,a0,384
    800034fe:	4505                	li	a0,1
    80003500:	00000097          	auipc	ra,0x0
    80003504:	8ea080e7          	jalr	-1814(ra) # 80002dea <argaddr>
  
  // sets ticks_passed as the interval
  myproc()->ticks_left = myproc()->interval;
    80003508:	ffffe097          	auipc	ra,0xffffe
    8000350c:	4be080e7          	jalr	1214(ra) # 800019c6 <myproc>
    80003510:	84aa                	mv	s1,a0
    80003512:	ffffe097          	auipc	ra,0xffffe
    80003516:	4b4080e7          	jalr	1204(ra) # 800019c6 <myproc>
    8000351a:	1784a783          	lw	a5,376(s1)
    8000351e:	16f52e23          	sw	a5,380(a0)
  return 0;
}
    80003522:	4501                	li	a0,0
    80003524:	60e2                	ld	ra,24(sp)
    80003526:	6442                	ld	s0,16(sp)
    80003528:	64a2                	ld	s1,8(sp)
    8000352a:	6105                	addi	sp,sp,32
    8000352c:	8082                	ret

000000008000352e <sys_sigreturn>:

uint64 
sys_sigreturn(void)
{
    8000352e:	1101                	addi	sp,sp,-32
    80003530:	ec06                	sd	ra,24(sp)
    80003532:	e822                	sd	s0,16(sp)
    80003534:	e426                	sd	s1,8(sp)
    80003536:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80003538:	ffffe097          	auipc	ra,0xffffe
    8000353c:	48e080e7          	jalr	1166(ra) # 800019c6 <myproc>
    80003540:	84aa                	mv	s1,a0
  memmove(p->trapframe, p->sigalarm_tf, PGSIZE);
    80003542:	6605                	lui	a2,0x1
    80003544:	18853583          	ld	a1,392(a0)
    80003548:	6d28                	ld	a0,88(a0)
    8000354a:	ffffd097          	auipc	ra,0xffffd
    8000354e:	7fc080e7          	jalr	2044(ra) # 80000d46 <memmove>
  kfree(p->sigalarm_tf);
    80003552:	1884b503          	ld	a0,392(s1)
    80003556:	ffffd097          	auipc	ra,0xffffd
    8000355a:	4a8080e7          	jalr	1192(ra) # 800009fe <kfree>
  p->ticks_left = p->interval;
    8000355e:	1784a783          	lw	a5,376(s1)
    80003562:	16f4ae23          	sw	a5,380(s1)
  return p->trapframe->a0;
    80003566:	6cbc                	ld	a5,88(s1)
}
    80003568:	7ba8                	ld	a0,112(a5)
    8000356a:	60e2                	ld	ra,24(sp)
    8000356c:	6442                	ld	s0,16(sp)
    8000356e:	64a2                	ld	s1,8(sp)
    80003570:	6105                	addi	sp,sp,32
    80003572:	8082                	ret

0000000080003574 <sys_settickets>:

uint64 
sys_settickets(void)
{
    80003574:	1141                	addi	sp,sp,-16
    80003576:	e406                	sd	ra,8(sp)
    80003578:	e022                	sd	s0,0(sp)
    8000357a:	0800                	addi	s0,sp,16
  argint(0, &myproc()->tickets);
    8000357c:	ffffe097          	auipc	ra,0xffffe
    80003580:	44a080e7          	jalr	1098(ra) # 800019c6 <myproc>
    80003584:	19450593          	addi	a1,a0,404
    80003588:	4501                	li	a0,0
    8000358a:	00000097          	auipc	ra,0x0
    8000358e:	840080e7          	jalr	-1984(ra) # 80002dca <argint>
  return myproc()->tickets;
    80003592:	ffffe097          	auipc	ra,0xffffe
    80003596:	434080e7          	jalr	1076(ra) # 800019c6 <myproc>
}
    8000359a:	19452503          	lw	a0,404(a0)
    8000359e:	60a2                	ld	ra,8(sp)
    800035a0:	6402                	ld	s0,0(sp)
    800035a2:	0141                	addi	sp,sp,16
    800035a4:	8082                	ret

00000000800035a6 <sys_waitx>:

uint64
sys_waitx(void)
{
    800035a6:	7139                	addi	sp,sp,-64
    800035a8:	fc06                	sd	ra,56(sp)
    800035aa:	f822                	sd	s0,48(sp)
    800035ac:	f426                	sd	s1,40(sp)
    800035ae:	f04a                	sd	s2,32(sp)
    800035b0:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800035b2:	fd840593          	addi	a1,s0,-40
    800035b6:	4501                	li	a0,0
    800035b8:	00000097          	auipc	ra,0x0
    800035bc:	832080e7          	jalr	-1998(ra) # 80002dea <argaddr>
  argaddr(1, &addr1); // user virtual memory
    800035c0:	fd040593          	addi	a1,s0,-48
    800035c4:	4505                	li	a0,1
    800035c6:	00000097          	auipc	ra,0x0
    800035ca:	824080e7          	jalr	-2012(ra) # 80002dea <argaddr>
  argaddr(2, &addr2);
    800035ce:	fc840593          	addi	a1,s0,-56
    800035d2:	4509                	li	a0,2
    800035d4:	00000097          	auipc	ra,0x0
    800035d8:	816080e7          	jalr	-2026(ra) # 80002dea <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    800035dc:	fc040613          	addi	a2,s0,-64
    800035e0:	fc440593          	addi	a1,s0,-60
    800035e4:	fd843503          	ld	a0,-40(s0)
    800035e8:	fffff097          	auipc	ra,0xfffff
    800035ec:	bfc080e7          	jalr	-1028(ra) # 800021e4 <waitx>
    800035f0:	892a                	mv	s2,a0
  struct proc* p = myproc();
    800035f2:	ffffe097          	auipc	ra,0xffffe
    800035f6:	3d4080e7          	jalr	980(ra) # 800019c6 <myproc>
    800035fa:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    800035fc:	4691                	li	a3,4
    800035fe:	fc440613          	addi	a2,s0,-60
    80003602:	fd043583          	ld	a1,-48(s0)
    80003606:	6928                	ld	a0,80(a0)
    80003608:	ffffe097          	auipc	ra,0xffffe
    8000360c:	07c080e7          	jalr	124(ra) # 80001684 <copyout>
    return -1;
    80003610:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80003612:	00054f63          	bltz	a0,80003630 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    80003616:	4691                	li	a3,4
    80003618:	fc040613          	addi	a2,s0,-64
    8000361c:	fc843583          	ld	a1,-56(s0)
    80003620:	68a8                	ld	a0,80(s1)
    80003622:	ffffe097          	auipc	ra,0xffffe
    80003626:	062080e7          	jalr	98(ra) # 80001684 <copyout>
    8000362a:	00054a63          	bltz	a0,8000363e <sys_waitx+0x98>
    return -1;
  return ret;
    8000362e:	87ca                	mv	a5,s2
}
    80003630:	853e                	mv	a0,a5
    80003632:	70e2                	ld	ra,56(sp)
    80003634:	7442                	ld	s0,48(sp)
    80003636:	74a2                	ld	s1,40(sp)
    80003638:	7902                	ld	s2,32(sp)
    8000363a:	6121                	addi	sp,sp,64
    8000363c:	8082                	ret
    return -1;
    8000363e:	57fd                	li	a5,-1
    80003640:	bfc5                	j	80003630 <sys_waitx+0x8a>

0000000080003642 <sys_setpriority>:

uint64
sys_setpriority(void)
{
    80003642:	1101                	addi	sp,sp,-32
    80003644:	ec06                	sd	ra,24(sp)
    80003646:	e822                	sd	s0,16(sp)
    80003648:	1000                	addi	s0,sp,32
  int new_priority, proc_pid;

  argint(0, &new_priority);
    8000364a:	fec40593          	addi	a1,s0,-20
    8000364e:	4501                	li	a0,0
    80003650:	fffff097          	auipc	ra,0xfffff
    80003654:	77a080e7          	jalr	1914(ra) # 80002dca <argint>
  argint(1, &proc_pid);
    80003658:	fe840593          	addi	a1,s0,-24
    8000365c:	4505                	li	a0,1
    8000365e:	fffff097          	auipc	ra,0xfffff
    80003662:	76c080e7          	jalr	1900(ra) # 80002dca <argint>
  return setpriority(new_priority, proc_pid);
    80003666:	fe842583          	lw	a1,-24(s0)
    8000366a:	fec42503          	lw	a0,-20(s0)
    8000366e:	fffff097          	auipc	ra,0xfffff
    80003672:	1cc080e7          	jalr	460(ra) # 8000283a <setpriority>
}
    80003676:	60e2                	ld	ra,24(sp)
    80003678:	6442                	ld	s0,16(sp)
    8000367a:	6105                	addi	sp,sp,32
    8000367c:	8082                	ret

000000008000367e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000367e:	7179                	addi	sp,sp,-48
    80003680:	f406                	sd	ra,40(sp)
    80003682:	f022                	sd	s0,32(sp)
    80003684:	ec26                	sd	s1,24(sp)
    80003686:	e84a                	sd	s2,16(sp)
    80003688:	e44e                	sd	s3,8(sp)
    8000368a:	e052                	sd	s4,0(sp)
    8000368c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000368e:	00005597          	auipc	a1,0x5
    80003692:	01a58593          	addi	a1,a1,26 # 800086a8 <syscalls+0xe0>
    80003696:	00015517          	auipc	a0,0x15
    8000369a:	d9250513          	addi	a0,a0,-622 # 80018428 <bcache>
    8000369e:	ffffd097          	auipc	ra,0xffffd
    800036a2:	4bc080e7          	jalr	1212(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800036a6:	0001d797          	auipc	a5,0x1d
    800036aa:	d8278793          	addi	a5,a5,-638 # 80020428 <bcache+0x8000>
    800036ae:	0001d717          	auipc	a4,0x1d
    800036b2:	fe270713          	addi	a4,a4,-30 # 80020690 <bcache+0x8268>
    800036b6:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800036ba:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800036be:	00015497          	auipc	s1,0x15
    800036c2:	d8248493          	addi	s1,s1,-638 # 80018440 <bcache+0x18>
    b->next = bcache.head.next;
    800036c6:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800036c8:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800036ca:	00005a17          	auipc	s4,0x5
    800036ce:	fe6a0a13          	addi	s4,s4,-26 # 800086b0 <syscalls+0xe8>
    b->next = bcache.head.next;
    800036d2:	2b893783          	ld	a5,696(s2)
    800036d6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800036d8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800036dc:	85d2                	mv	a1,s4
    800036de:	01048513          	addi	a0,s1,16
    800036e2:	00001097          	auipc	ra,0x1
    800036e6:	4c4080e7          	jalr	1220(ra) # 80004ba6 <initsleeplock>
    bcache.head.next->prev = b;
    800036ea:	2b893783          	ld	a5,696(s2)
    800036ee:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800036f0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800036f4:	45848493          	addi	s1,s1,1112
    800036f8:	fd349de3          	bne	s1,s3,800036d2 <binit+0x54>
  }
}
    800036fc:	70a2                	ld	ra,40(sp)
    800036fe:	7402                	ld	s0,32(sp)
    80003700:	64e2                	ld	s1,24(sp)
    80003702:	6942                	ld	s2,16(sp)
    80003704:	69a2                	ld	s3,8(sp)
    80003706:	6a02                	ld	s4,0(sp)
    80003708:	6145                	addi	sp,sp,48
    8000370a:	8082                	ret

000000008000370c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000370c:	7179                	addi	sp,sp,-48
    8000370e:	f406                	sd	ra,40(sp)
    80003710:	f022                	sd	s0,32(sp)
    80003712:	ec26                	sd	s1,24(sp)
    80003714:	e84a                	sd	s2,16(sp)
    80003716:	e44e                	sd	s3,8(sp)
    80003718:	1800                	addi	s0,sp,48
    8000371a:	89aa                	mv	s3,a0
    8000371c:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000371e:	00015517          	auipc	a0,0x15
    80003722:	d0a50513          	addi	a0,a0,-758 # 80018428 <bcache>
    80003726:	ffffd097          	auipc	ra,0xffffd
    8000372a:	4c4080e7          	jalr	1220(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000372e:	0001d497          	auipc	s1,0x1d
    80003732:	fb24b483          	ld	s1,-78(s1) # 800206e0 <bcache+0x82b8>
    80003736:	0001d797          	auipc	a5,0x1d
    8000373a:	f5a78793          	addi	a5,a5,-166 # 80020690 <bcache+0x8268>
    8000373e:	02f48f63          	beq	s1,a5,8000377c <bread+0x70>
    80003742:	873e                	mv	a4,a5
    80003744:	a021                	j	8000374c <bread+0x40>
    80003746:	68a4                	ld	s1,80(s1)
    80003748:	02e48a63          	beq	s1,a4,8000377c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000374c:	449c                	lw	a5,8(s1)
    8000374e:	ff379ce3          	bne	a5,s3,80003746 <bread+0x3a>
    80003752:	44dc                	lw	a5,12(s1)
    80003754:	ff2799e3          	bne	a5,s2,80003746 <bread+0x3a>
      b->refcnt++;
    80003758:	40bc                	lw	a5,64(s1)
    8000375a:	2785                	addiw	a5,a5,1
    8000375c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000375e:	00015517          	auipc	a0,0x15
    80003762:	cca50513          	addi	a0,a0,-822 # 80018428 <bcache>
    80003766:	ffffd097          	auipc	ra,0xffffd
    8000376a:	538080e7          	jalr	1336(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    8000376e:	01048513          	addi	a0,s1,16
    80003772:	00001097          	auipc	ra,0x1
    80003776:	46e080e7          	jalr	1134(ra) # 80004be0 <acquiresleep>
      return b;
    8000377a:	a8b9                	j	800037d8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000377c:	0001d497          	auipc	s1,0x1d
    80003780:	f5c4b483          	ld	s1,-164(s1) # 800206d8 <bcache+0x82b0>
    80003784:	0001d797          	auipc	a5,0x1d
    80003788:	f0c78793          	addi	a5,a5,-244 # 80020690 <bcache+0x8268>
    8000378c:	00f48863          	beq	s1,a5,8000379c <bread+0x90>
    80003790:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003792:	40bc                	lw	a5,64(s1)
    80003794:	cf81                	beqz	a5,800037ac <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003796:	64a4                	ld	s1,72(s1)
    80003798:	fee49de3          	bne	s1,a4,80003792 <bread+0x86>
  panic("bget: no buffers");
    8000379c:	00005517          	auipc	a0,0x5
    800037a0:	f1c50513          	addi	a0,a0,-228 # 800086b8 <syscalls+0xf0>
    800037a4:	ffffd097          	auipc	ra,0xffffd
    800037a8:	da0080e7          	jalr	-608(ra) # 80000544 <panic>
      b->dev = dev;
    800037ac:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800037b0:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800037b4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800037b8:	4785                	li	a5,1
    800037ba:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800037bc:	00015517          	auipc	a0,0x15
    800037c0:	c6c50513          	addi	a0,a0,-916 # 80018428 <bcache>
    800037c4:	ffffd097          	auipc	ra,0xffffd
    800037c8:	4da080e7          	jalr	1242(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    800037cc:	01048513          	addi	a0,s1,16
    800037d0:	00001097          	auipc	ra,0x1
    800037d4:	410080e7          	jalr	1040(ra) # 80004be0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800037d8:	409c                	lw	a5,0(s1)
    800037da:	cb89                	beqz	a5,800037ec <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800037dc:	8526                	mv	a0,s1
    800037de:	70a2                	ld	ra,40(sp)
    800037e0:	7402                	ld	s0,32(sp)
    800037e2:	64e2                	ld	s1,24(sp)
    800037e4:	6942                	ld	s2,16(sp)
    800037e6:	69a2                	ld	s3,8(sp)
    800037e8:	6145                	addi	sp,sp,48
    800037ea:	8082                	ret
    virtio_disk_rw(b, 0);
    800037ec:	4581                	li	a1,0
    800037ee:	8526                	mv	a0,s1
    800037f0:	00003097          	auipc	ra,0x3
    800037f4:	fc8080e7          	jalr	-56(ra) # 800067b8 <virtio_disk_rw>
    b->valid = 1;
    800037f8:	4785                	li	a5,1
    800037fa:	c09c                	sw	a5,0(s1)
  return b;
    800037fc:	b7c5                	j	800037dc <bread+0xd0>

00000000800037fe <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800037fe:	1101                	addi	sp,sp,-32
    80003800:	ec06                	sd	ra,24(sp)
    80003802:	e822                	sd	s0,16(sp)
    80003804:	e426                	sd	s1,8(sp)
    80003806:	1000                	addi	s0,sp,32
    80003808:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000380a:	0541                	addi	a0,a0,16
    8000380c:	00001097          	auipc	ra,0x1
    80003810:	46e080e7          	jalr	1134(ra) # 80004c7a <holdingsleep>
    80003814:	cd01                	beqz	a0,8000382c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003816:	4585                	li	a1,1
    80003818:	8526                	mv	a0,s1
    8000381a:	00003097          	auipc	ra,0x3
    8000381e:	f9e080e7          	jalr	-98(ra) # 800067b8 <virtio_disk_rw>
}
    80003822:	60e2                	ld	ra,24(sp)
    80003824:	6442                	ld	s0,16(sp)
    80003826:	64a2                	ld	s1,8(sp)
    80003828:	6105                	addi	sp,sp,32
    8000382a:	8082                	ret
    panic("bwrite");
    8000382c:	00005517          	auipc	a0,0x5
    80003830:	ea450513          	addi	a0,a0,-348 # 800086d0 <syscalls+0x108>
    80003834:	ffffd097          	auipc	ra,0xffffd
    80003838:	d10080e7          	jalr	-752(ra) # 80000544 <panic>

000000008000383c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000383c:	1101                	addi	sp,sp,-32
    8000383e:	ec06                	sd	ra,24(sp)
    80003840:	e822                	sd	s0,16(sp)
    80003842:	e426                	sd	s1,8(sp)
    80003844:	e04a                	sd	s2,0(sp)
    80003846:	1000                	addi	s0,sp,32
    80003848:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000384a:	01050913          	addi	s2,a0,16
    8000384e:	854a                	mv	a0,s2
    80003850:	00001097          	auipc	ra,0x1
    80003854:	42a080e7          	jalr	1066(ra) # 80004c7a <holdingsleep>
    80003858:	c92d                	beqz	a0,800038ca <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000385a:	854a                	mv	a0,s2
    8000385c:	00001097          	auipc	ra,0x1
    80003860:	3da080e7          	jalr	986(ra) # 80004c36 <releasesleep>

  acquire(&bcache.lock);
    80003864:	00015517          	auipc	a0,0x15
    80003868:	bc450513          	addi	a0,a0,-1084 # 80018428 <bcache>
    8000386c:	ffffd097          	auipc	ra,0xffffd
    80003870:	37e080e7          	jalr	894(ra) # 80000bea <acquire>
  b->refcnt--;
    80003874:	40bc                	lw	a5,64(s1)
    80003876:	37fd                	addiw	a5,a5,-1
    80003878:	0007871b          	sext.w	a4,a5
    8000387c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000387e:	eb05                	bnez	a4,800038ae <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003880:	68bc                	ld	a5,80(s1)
    80003882:	64b8                	ld	a4,72(s1)
    80003884:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003886:	64bc                	ld	a5,72(s1)
    80003888:	68b8                	ld	a4,80(s1)
    8000388a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000388c:	0001d797          	auipc	a5,0x1d
    80003890:	b9c78793          	addi	a5,a5,-1124 # 80020428 <bcache+0x8000>
    80003894:	2b87b703          	ld	a4,696(a5)
    80003898:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000389a:	0001d717          	auipc	a4,0x1d
    8000389e:	df670713          	addi	a4,a4,-522 # 80020690 <bcache+0x8268>
    800038a2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800038a4:	2b87b703          	ld	a4,696(a5)
    800038a8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800038aa:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800038ae:	00015517          	auipc	a0,0x15
    800038b2:	b7a50513          	addi	a0,a0,-1158 # 80018428 <bcache>
    800038b6:	ffffd097          	auipc	ra,0xffffd
    800038ba:	3e8080e7          	jalr	1000(ra) # 80000c9e <release>
}
    800038be:	60e2                	ld	ra,24(sp)
    800038c0:	6442                	ld	s0,16(sp)
    800038c2:	64a2                	ld	s1,8(sp)
    800038c4:	6902                	ld	s2,0(sp)
    800038c6:	6105                	addi	sp,sp,32
    800038c8:	8082                	ret
    panic("brelse");
    800038ca:	00005517          	auipc	a0,0x5
    800038ce:	e0e50513          	addi	a0,a0,-498 # 800086d8 <syscalls+0x110>
    800038d2:	ffffd097          	auipc	ra,0xffffd
    800038d6:	c72080e7          	jalr	-910(ra) # 80000544 <panic>

00000000800038da <bpin>:

void
bpin(struct buf *b) {
    800038da:	1101                	addi	sp,sp,-32
    800038dc:	ec06                	sd	ra,24(sp)
    800038de:	e822                	sd	s0,16(sp)
    800038e0:	e426                	sd	s1,8(sp)
    800038e2:	1000                	addi	s0,sp,32
    800038e4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800038e6:	00015517          	auipc	a0,0x15
    800038ea:	b4250513          	addi	a0,a0,-1214 # 80018428 <bcache>
    800038ee:	ffffd097          	auipc	ra,0xffffd
    800038f2:	2fc080e7          	jalr	764(ra) # 80000bea <acquire>
  b->refcnt++;
    800038f6:	40bc                	lw	a5,64(s1)
    800038f8:	2785                	addiw	a5,a5,1
    800038fa:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800038fc:	00015517          	auipc	a0,0x15
    80003900:	b2c50513          	addi	a0,a0,-1236 # 80018428 <bcache>
    80003904:	ffffd097          	auipc	ra,0xffffd
    80003908:	39a080e7          	jalr	922(ra) # 80000c9e <release>
}
    8000390c:	60e2                	ld	ra,24(sp)
    8000390e:	6442                	ld	s0,16(sp)
    80003910:	64a2                	ld	s1,8(sp)
    80003912:	6105                	addi	sp,sp,32
    80003914:	8082                	ret

0000000080003916 <bunpin>:

void
bunpin(struct buf *b) {
    80003916:	1101                	addi	sp,sp,-32
    80003918:	ec06                	sd	ra,24(sp)
    8000391a:	e822                	sd	s0,16(sp)
    8000391c:	e426                	sd	s1,8(sp)
    8000391e:	1000                	addi	s0,sp,32
    80003920:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003922:	00015517          	auipc	a0,0x15
    80003926:	b0650513          	addi	a0,a0,-1274 # 80018428 <bcache>
    8000392a:	ffffd097          	auipc	ra,0xffffd
    8000392e:	2c0080e7          	jalr	704(ra) # 80000bea <acquire>
  b->refcnt--;
    80003932:	40bc                	lw	a5,64(s1)
    80003934:	37fd                	addiw	a5,a5,-1
    80003936:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003938:	00015517          	auipc	a0,0x15
    8000393c:	af050513          	addi	a0,a0,-1296 # 80018428 <bcache>
    80003940:	ffffd097          	auipc	ra,0xffffd
    80003944:	35e080e7          	jalr	862(ra) # 80000c9e <release>
}
    80003948:	60e2                	ld	ra,24(sp)
    8000394a:	6442                	ld	s0,16(sp)
    8000394c:	64a2                	ld	s1,8(sp)
    8000394e:	6105                	addi	sp,sp,32
    80003950:	8082                	ret

0000000080003952 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003952:	1101                	addi	sp,sp,-32
    80003954:	ec06                	sd	ra,24(sp)
    80003956:	e822                	sd	s0,16(sp)
    80003958:	e426                	sd	s1,8(sp)
    8000395a:	e04a                	sd	s2,0(sp)
    8000395c:	1000                	addi	s0,sp,32
    8000395e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003960:	00d5d59b          	srliw	a1,a1,0xd
    80003964:	0001d797          	auipc	a5,0x1d
    80003968:	1a07a783          	lw	a5,416(a5) # 80020b04 <sb+0x1c>
    8000396c:	9dbd                	addw	a1,a1,a5
    8000396e:	00000097          	auipc	ra,0x0
    80003972:	d9e080e7          	jalr	-610(ra) # 8000370c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003976:	0074f713          	andi	a4,s1,7
    8000397a:	4785                	li	a5,1
    8000397c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003980:	14ce                	slli	s1,s1,0x33
    80003982:	90d9                	srli	s1,s1,0x36
    80003984:	00950733          	add	a4,a0,s1
    80003988:	05874703          	lbu	a4,88(a4)
    8000398c:	00e7f6b3          	and	a3,a5,a4
    80003990:	c69d                	beqz	a3,800039be <bfree+0x6c>
    80003992:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003994:	94aa                	add	s1,s1,a0
    80003996:	fff7c793          	not	a5,a5
    8000399a:	8ff9                	and	a5,a5,a4
    8000399c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800039a0:	00001097          	auipc	ra,0x1
    800039a4:	120080e7          	jalr	288(ra) # 80004ac0 <log_write>
  brelse(bp);
    800039a8:	854a                	mv	a0,s2
    800039aa:	00000097          	auipc	ra,0x0
    800039ae:	e92080e7          	jalr	-366(ra) # 8000383c <brelse>
}
    800039b2:	60e2                	ld	ra,24(sp)
    800039b4:	6442                	ld	s0,16(sp)
    800039b6:	64a2                	ld	s1,8(sp)
    800039b8:	6902                	ld	s2,0(sp)
    800039ba:	6105                	addi	sp,sp,32
    800039bc:	8082                	ret
    panic("freeing free block");
    800039be:	00005517          	auipc	a0,0x5
    800039c2:	d2250513          	addi	a0,a0,-734 # 800086e0 <syscalls+0x118>
    800039c6:	ffffd097          	auipc	ra,0xffffd
    800039ca:	b7e080e7          	jalr	-1154(ra) # 80000544 <panic>

00000000800039ce <balloc>:
{
    800039ce:	711d                	addi	sp,sp,-96
    800039d0:	ec86                	sd	ra,88(sp)
    800039d2:	e8a2                	sd	s0,80(sp)
    800039d4:	e4a6                	sd	s1,72(sp)
    800039d6:	e0ca                	sd	s2,64(sp)
    800039d8:	fc4e                	sd	s3,56(sp)
    800039da:	f852                	sd	s4,48(sp)
    800039dc:	f456                	sd	s5,40(sp)
    800039de:	f05a                	sd	s6,32(sp)
    800039e0:	ec5e                	sd	s7,24(sp)
    800039e2:	e862                	sd	s8,16(sp)
    800039e4:	e466                	sd	s9,8(sp)
    800039e6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800039e8:	0001d797          	auipc	a5,0x1d
    800039ec:	1047a783          	lw	a5,260(a5) # 80020aec <sb+0x4>
    800039f0:	10078163          	beqz	a5,80003af2 <balloc+0x124>
    800039f4:	8baa                	mv	s7,a0
    800039f6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800039f8:	0001db17          	auipc	s6,0x1d
    800039fc:	0f0b0b13          	addi	s6,s6,240 # 80020ae8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a00:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003a02:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a04:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003a06:	6c89                	lui	s9,0x2
    80003a08:	a061                	j	80003a90 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003a0a:	974a                	add	a4,a4,s2
    80003a0c:	8fd5                	or	a5,a5,a3
    80003a0e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003a12:	854a                	mv	a0,s2
    80003a14:	00001097          	auipc	ra,0x1
    80003a18:	0ac080e7          	jalr	172(ra) # 80004ac0 <log_write>
        brelse(bp);
    80003a1c:	854a                	mv	a0,s2
    80003a1e:	00000097          	auipc	ra,0x0
    80003a22:	e1e080e7          	jalr	-482(ra) # 8000383c <brelse>
  bp = bread(dev, bno);
    80003a26:	85a6                	mv	a1,s1
    80003a28:	855e                	mv	a0,s7
    80003a2a:	00000097          	auipc	ra,0x0
    80003a2e:	ce2080e7          	jalr	-798(ra) # 8000370c <bread>
    80003a32:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003a34:	40000613          	li	a2,1024
    80003a38:	4581                	li	a1,0
    80003a3a:	05850513          	addi	a0,a0,88
    80003a3e:	ffffd097          	auipc	ra,0xffffd
    80003a42:	2a8080e7          	jalr	680(ra) # 80000ce6 <memset>
  log_write(bp);
    80003a46:	854a                	mv	a0,s2
    80003a48:	00001097          	auipc	ra,0x1
    80003a4c:	078080e7          	jalr	120(ra) # 80004ac0 <log_write>
  brelse(bp);
    80003a50:	854a                	mv	a0,s2
    80003a52:	00000097          	auipc	ra,0x0
    80003a56:	dea080e7          	jalr	-534(ra) # 8000383c <brelse>
}
    80003a5a:	8526                	mv	a0,s1
    80003a5c:	60e6                	ld	ra,88(sp)
    80003a5e:	6446                	ld	s0,80(sp)
    80003a60:	64a6                	ld	s1,72(sp)
    80003a62:	6906                	ld	s2,64(sp)
    80003a64:	79e2                	ld	s3,56(sp)
    80003a66:	7a42                	ld	s4,48(sp)
    80003a68:	7aa2                	ld	s5,40(sp)
    80003a6a:	7b02                	ld	s6,32(sp)
    80003a6c:	6be2                	ld	s7,24(sp)
    80003a6e:	6c42                	ld	s8,16(sp)
    80003a70:	6ca2                	ld	s9,8(sp)
    80003a72:	6125                	addi	sp,sp,96
    80003a74:	8082                	ret
    brelse(bp);
    80003a76:	854a                	mv	a0,s2
    80003a78:	00000097          	auipc	ra,0x0
    80003a7c:	dc4080e7          	jalr	-572(ra) # 8000383c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003a80:	015c87bb          	addw	a5,s9,s5
    80003a84:	00078a9b          	sext.w	s5,a5
    80003a88:	004b2703          	lw	a4,4(s6)
    80003a8c:	06eaf363          	bgeu	s5,a4,80003af2 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003a90:	41fad79b          	sraiw	a5,s5,0x1f
    80003a94:	0137d79b          	srliw	a5,a5,0x13
    80003a98:	015787bb          	addw	a5,a5,s5
    80003a9c:	40d7d79b          	sraiw	a5,a5,0xd
    80003aa0:	01cb2583          	lw	a1,28(s6)
    80003aa4:	9dbd                	addw	a1,a1,a5
    80003aa6:	855e                	mv	a0,s7
    80003aa8:	00000097          	auipc	ra,0x0
    80003aac:	c64080e7          	jalr	-924(ra) # 8000370c <bread>
    80003ab0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003ab2:	004b2503          	lw	a0,4(s6)
    80003ab6:	000a849b          	sext.w	s1,s5
    80003aba:	8662                	mv	a2,s8
    80003abc:	faa4fde3          	bgeu	s1,a0,80003a76 <balloc+0xa8>
      m = 1 << (bi % 8);
    80003ac0:	41f6579b          	sraiw	a5,a2,0x1f
    80003ac4:	01d7d69b          	srliw	a3,a5,0x1d
    80003ac8:	00c6873b          	addw	a4,a3,a2
    80003acc:	00777793          	andi	a5,a4,7
    80003ad0:	9f95                	subw	a5,a5,a3
    80003ad2:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003ad6:	4037571b          	sraiw	a4,a4,0x3
    80003ada:	00e906b3          	add	a3,s2,a4
    80003ade:	0586c683          	lbu	a3,88(a3)
    80003ae2:	00d7f5b3          	and	a1,a5,a3
    80003ae6:	d195                	beqz	a1,80003a0a <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003ae8:	2605                	addiw	a2,a2,1
    80003aea:	2485                	addiw	s1,s1,1
    80003aec:	fd4618e3          	bne	a2,s4,80003abc <balloc+0xee>
    80003af0:	b759                	j	80003a76 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003af2:	00005517          	auipc	a0,0x5
    80003af6:	c0650513          	addi	a0,a0,-1018 # 800086f8 <syscalls+0x130>
    80003afa:	ffffd097          	auipc	ra,0xffffd
    80003afe:	a94080e7          	jalr	-1388(ra) # 8000058e <printf>
  return 0;
    80003b02:	4481                	li	s1,0
    80003b04:	bf99                	j	80003a5a <balloc+0x8c>

0000000080003b06 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003b06:	7179                	addi	sp,sp,-48
    80003b08:	f406                	sd	ra,40(sp)
    80003b0a:	f022                	sd	s0,32(sp)
    80003b0c:	ec26                	sd	s1,24(sp)
    80003b0e:	e84a                	sd	s2,16(sp)
    80003b10:	e44e                	sd	s3,8(sp)
    80003b12:	e052                	sd	s4,0(sp)
    80003b14:	1800                	addi	s0,sp,48
    80003b16:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003b18:	47ad                	li	a5,11
    80003b1a:	02b7e763          	bltu	a5,a1,80003b48 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003b1e:	02059493          	slli	s1,a1,0x20
    80003b22:	9081                	srli	s1,s1,0x20
    80003b24:	048a                	slli	s1,s1,0x2
    80003b26:	94aa                	add	s1,s1,a0
    80003b28:	0504a903          	lw	s2,80(s1)
    80003b2c:	06091e63          	bnez	s2,80003ba8 <bmap+0xa2>
      addr = balloc(ip->dev);
    80003b30:	4108                	lw	a0,0(a0)
    80003b32:	00000097          	auipc	ra,0x0
    80003b36:	e9c080e7          	jalr	-356(ra) # 800039ce <balloc>
    80003b3a:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003b3e:	06090563          	beqz	s2,80003ba8 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003b42:	0524a823          	sw	s2,80(s1)
    80003b46:	a08d                	j	80003ba8 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003b48:	ff45849b          	addiw	s1,a1,-12
    80003b4c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003b50:	0ff00793          	li	a5,255
    80003b54:	08e7e563          	bltu	a5,a4,80003bde <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003b58:	08052903          	lw	s2,128(a0)
    80003b5c:	00091d63          	bnez	s2,80003b76 <bmap+0x70>
      addr = balloc(ip->dev);
    80003b60:	4108                	lw	a0,0(a0)
    80003b62:	00000097          	auipc	ra,0x0
    80003b66:	e6c080e7          	jalr	-404(ra) # 800039ce <balloc>
    80003b6a:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003b6e:	02090d63          	beqz	s2,80003ba8 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003b72:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003b76:	85ca                	mv	a1,s2
    80003b78:	0009a503          	lw	a0,0(s3)
    80003b7c:	00000097          	auipc	ra,0x0
    80003b80:	b90080e7          	jalr	-1136(ra) # 8000370c <bread>
    80003b84:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003b86:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003b8a:	02049593          	slli	a1,s1,0x20
    80003b8e:	9181                	srli	a1,a1,0x20
    80003b90:	058a                	slli	a1,a1,0x2
    80003b92:	00b784b3          	add	s1,a5,a1
    80003b96:	0004a903          	lw	s2,0(s1)
    80003b9a:	02090063          	beqz	s2,80003bba <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003b9e:	8552                	mv	a0,s4
    80003ba0:	00000097          	auipc	ra,0x0
    80003ba4:	c9c080e7          	jalr	-868(ra) # 8000383c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003ba8:	854a                	mv	a0,s2
    80003baa:	70a2                	ld	ra,40(sp)
    80003bac:	7402                	ld	s0,32(sp)
    80003bae:	64e2                	ld	s1,24(sp)
    80003bb0:	6942                	ld	s2,16(sp)
    80003bb2:	69a2                	ld	s3,8(sp)
    80003bb4:	6a02                	ld	s4,0(sp)
    80003bb6:	6145                	addi	sp,sp,48
    80003bb8:	8082                	ret
      addr = balloc(ip->dev);
    80003bba:	0009a503          	lw	a0,0(s3)
    80003bbe:	00000097          	auipc	ra,0x0
    80003bc2:	e10080e7          	jalr	-496(ra) # 800039ce <balloc>
    80003bc6:	0005091b          	sext.w	s2,a0
      if(addr){
    80003bca:	fc090ae3          	beqz	s2,80003b9e <bmap+0x98>
        a[bn] = addr;
    80003bce:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003bd2:	8552                	mv	a0,s4
    80003bd4:	00001097          	auipc	ra,0x1
    80003bd8:	eec080e7          	jalr	-276(ra) # 80004ac0 <log_write>
    80003bdc:	b7c9                	j	80003b9e <bmap+0x98>
  panic("bmap: out of range");
    80003bde:	00005517          	auipc	a0,0x5
    80003be2:	b3250513          	addi	a0,a0,-1230 # 80008710 <syscalls+0x148>
    80003be6:	ffffd097          	auipc	ra,0xffffd
    80003bea:	95e080e7          	jalr	-1698(ra) # 80000544 <panic>

0000000080003bee <iget>:
{
    80003bee:	7179                	addi	sp,sp,-48
    80003bf0:	f406                	sd	ra,40(sp)
    80003bf2:	f022                	sd	s0,32(sp)
    80003bf4:	ec26                	sd	s1,24(sp)
    80003bf6:	e84a                	sd	s2,16(sp)
    80003bf8:	e44e                	sd	s3,8(sp)
    80003bfa:	e052                	sd	s4,0(sp)
    80003bfc:	1800                	addi	s0,sp,48
    80003bfe:	89aa                	mv	s3,a0
    80003c00:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003c02:	0001d517          	auipc	a0,0x1d
    80003c06:	f0650513          	addi	a0,a0,-250 # 80020b08 <itable>
    80003c0a:	ffffd097          	auipc	ra,0xffffd
    80003c0e:	fe0080e7          	jalr	-32(ra) # 80000bea <acquire>
  empty = 0;
    80003c12:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003c14:	0001d497          	auipc	s1,0x1d
    80003c18:	f0c48493          	addi	s1,s1,-244 # 80020b20 <itable+0x18>
    80003c1c:	0001f697          	auipc	a3,0x1f
    80003c20:	99468693          	addi	a3,a3,-1644 # 800225b0 <log>
    80003c24:	a039                	j	80003c32 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003c26:	02090b63          	beqz	s2,80003c5c <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003c2a:	08848493          	addi	s1,s1,136
    80003c2e:	02d48a63          	beq	s1,a3,80003c62 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003c32:	449c                	lw	a5,8(s1)
    80003c34:	fef059e3          	blez	a5,80003c26 <iget+0x38>
    80003c38:	4098                	lw	a4,0(s1)
    80003c3a:	ff3716e3          	bne	a4,s3,80003c26 <iget+0x38>
    80003c3e:	40d8                	lw	a4,4(s1)
    80003c40:	ff4713e3          	bne	a4,s4,80003c26 <iget+0x38>
      ip->ref++;
    80003c44:	2785                	addiw	a5,a5,1
    80003c46:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003c48:	0001d517          	auipc	a0,0x1d
    80003c4c:	ec050513          	addi	a0,a0,-320 # 80020b08 <itable>
    80003c50:	ffffd097          	auipc	ra,0xffffd
    80003c54:	04e080e7          	jalr	78(ra) # 80000c9e <release>
      return ip;
    80003c58:	8926                	mv	s2,s1
    80003c5a:	a03d                	j	80003c88 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003c5c:	f7f9                	bnez	a5,80003c2a <iget+0x3c>
    80003c5e:	8926                	mv	s2,s1
    80003c60:	b7e9                	j	80003c2a <iget+0x3c>
  if(empty == 0)
    80003c62:	02090c63          	beqz	s2,80003c9a <iget+0xac>
  ip->dev = dev;
    80003c66:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003c6a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003c6e:	4785                	li	a5,1
    80003c70:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003c74:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003c78:	0001d517          	auipc	a0,0x1d
    80003c7c:	e9050513          	addi	a0,a0,-368 # 80020b08 <itable>
    80003c80:	ffffd097          	auipc	ra,0xffffd
    80003c84:	01e080e7          	jalr	30(ra) # 80000c9e <release>
}
    80003c88:	854a                	mv	a0,s2
    80003c8a:	70a2                	ld	ra,40(sp)
    80003c8c:	7402                	ld	s0,32(sp)
    80003c8e:	64e2                	ld	s1,24(sp)
    80003c90:	6942                	ld	s2,16(sp)
    80003c92:	69a2                	ld	s3,8(sp)
    80003c94:	6a02                	ld	s4,0(sp)
    80003c96:	6145                	addi	sp,sp,48
    80003c98:	8082                	ret
    panic("iget: no inodes");
    80003c9a:	00005517          	auipc	a0,0x5
    80003c9e:	a8e50513          	addi	a0,a0,-1394 # 80008728 <syscalls+0x160>
    80003ca2:	ffffd097          	auipc	ra,0xffffd
    80003ca6:	8a2080e7          	jalr	-1886(ra) # 80000544 <panic>

0000000080003caa <fsinit>:
fsinit(int dev) {
    80003caa:	7179                	addi	sp,sp,-48
    80003cac:	f406                	sd	ra,40(sp)
    80003cae:	f022                	sd	s0,32(sp)
    80003cb0:	ec26                	sd	s1,24(sp)
    80003cb2:	e84a                	sd	s2,16(sp)
    80003cb4:	e44e                	sd	s3,8(sp)
    80003cb6:	1800                	addi	s0,sp,48
    80003cb8:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003cba:	4585                	li	a1,1
    80003cbc:	00000097          	auipc	ra,0x0
    80003cc0:	a50080e7          	jalr	-1456(ra) # 8000370c <bread>
    80003cc4:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003cc6:	0001d997          	auipc	s3,0x1d
    80003cca:	e2298993          	addi	s3,s3,-478 # 80020ae8 <sb>
    80003cce:	02000613          	li	a2,32
    80003cd2:	05850593          	addi	a1,a0,88
    80003cd6:	854e                	mv	a0,s3
    80003cd8:	ffffd097          	auipc	ra,0xffffd
    80003cdc:	06e080e7          	jalr	110(ra) # 80000d46 <memmove>
  brelse(bp);
    80003ce0:	8526                	mv	a0,s1
    80003ce2:	00000097          	auipc	ra,0x0
    80003ce6:	b5a080e7          	jalr	-1190(ra) # 8000383c <brelse>
  if(sb.magic != FSMAGIC)
    80003cea:	0009a703          	lw	a4,0(s3)
    80003cee:	102037b7          	lui	a5,0x10203
    80003cf2:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003cf6:	02f71263          	bne	a4,a5,80003d1a <fsinit+0x70>
  initlog(dev, &sb);
    80003cfa:	0001d597          	auipc	a1,0x1d
    80003cfe:	dee58593          	addi	a1,a1,-530 # 80020ae8 <sb>
    80003d02:	854a                	mv	a0,s2
    80003d04:	00001097          	auipc	ra,0x1
    80003d08:	b40080e7          	jalr	-1216(ra) # 80004844 <initlog>
}
    80003d0c:	70a2                	ld	ra,40(sp)
    80003d0e:	7402                	ld	s0,32(sp)
    80003d10:	64e2                	ld	s1,24(sp)
    80003d12:	6942                	ld	s2,16(sp)
    80003d14:	69a2                	ld	s3,8(sp)
    80003d16:	6145                	addi	sp,sp,48
    80003d18:	8082                	ret
    panic("invalid file system");
    80003d1a:	00005517          	auipc	a0,0x5
    80003d1e:	a1e50513          	addi	a0,a0,-1506 # 80008738 <syscalls+0x170>
    80003d22:	ffffd097          	auipc	ra,0xffffd
    80003d26:	822080e7          	jalr	-2014(ra) # 80000544 <panic>

0000000080003d2a <iinit>:
{
    80003d2a:	7179                	addi	sp,sp,-48
    80003d2c:	f406                	sd	ra,40(sp)
    80003d2e:	f022                	sd	s0,32(sp)
    80003d30:	ec26                	sd	s1,24(sp)
    80003d32:	e84a                	sd	s2,16(sp)
    80003d34:	e44e                	sd	s3,8(sp)
    80003d36:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003d38:	00005597          	auipc	a1,0x5
    80003d3c:	a1858593          	addi	a1,a1,-1512 # 80008750 <syscalls+0x188>
    80003d40:	0001d517          	auipc	a0,0x1d
    80003d44:	dc850513          	addi	a0,a0,-568 # 80020b08 <itable>
    80003d48:	ffffd097          	auipc	ra,0xffffd
    80003d4c:	e12080e7          	jalr	-494(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    80003d50:	0001d497          	auipc	s1,0x1d
    80003d54:	de048493          	addi	s1,s1,-544 # 80020b30 <itable+0x28>
    80003d58:	0001f997          	auipc	s3,0x1f
    80003d5c:	86898993          	addi	s3,s3,-1944 # 800225c0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003d60:	00005917          	auipc	s2,0x5
    80003d64:	9f890913          	addi	s2,s2,-1544 # 80008758 <syscalls+0x190>
    80003d68:	85ca                	mv	a1,s2
    80003d6a:	8526                	mv	a0,s1
    80003d6c:	00001097          	auipc	ra,0x1
    80003d70:	e3a080e7          	jalr	-454(ra) # 80004ba6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003d74:	08848493          	addi	s1,s1,136
    80003d78:	ff3498e3          	bne	s1,s3,80003d68 <iinit+0x3e>
}
    80003d7c:	70a2                	ld	ra,40(sp)
    80003d7e:	7402                	ld	s0,32(sp)
    80003d80:	64e2                	ld	s1,24(sp)
    80003d82:	6942                	ld	s2,16(sp)
    80003d84:	69a2                	ld	s3,8(sp)
    80003d86:	6145                	addi	sp,sp,48
    80003d88:	8082                	ret

0000000080003d8a <ialloc>:
{
    80003d8a:	715d                	addi	sp,sp,-80
    80003d8c:	e486                	sd	ra,72(sp)
    80003d8e:	e0a2                	sd	s0,64(sp)
    80003d90:	fc26                	sd	s1,56(sp)
    80003d92:	f84a                	sd	s2,48(sp)
    80003d94:	f44e                	sd	s3,40(sp)
    80003d96:	f052                	sd	s4,32(sp)
    80003d98:	ec56                	sd	s5,24(sp)
    80003d9a:	e85a                	sd	s6,16(sp)
    80003d9c:	e45e                	sd	s7,8(sp)
    80003d9e:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003da0:	0001d717          	auipc	a4,0x1d
    80003da4:	d5472703          	lw	a4,-684(a4) # 80020af4 <sb+0xc>
    80003da8:	4785                	li	a5,1
    80003daa:	04e7fa63          	bgeu	a5,a4,80003dfe <ialloc+0x74>
    80003dae:	8aaa                	mv	s5,a0
    80003db0:	8bae                	mv	s7,a1
    80003db2:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003db4:	0001da17          	auipc	s4,0x1d
    80003db8:	d34a0a13          	addi	s4,s4,-716 # 80020ae8 <sb>
    80003dbc:	00048b1b          	sext.w	s6,s1
    80003dc0:	0044d593          	srli	a1,s1,0x4
    80003dc4:	018a2783          	lw	a5,24(s4)
    80003dc8:	9dbd                	addw	a1,a1,a5
    80003dca:	8556                	mv	a0,s5
    80003dcc:	00000097          	auipc	ra,0x0
    80003dd0:	940080e7          	jalr	-1728(ra) # 8000370c <bread>
    80003dd4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003dd6:	05850993          	addi	s3,a0,88
    80003dda:	00f4f793          	andi	a5,s1,15
    80003dde:	079a                	slli	a5,a5,0x6
    80003de0:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003de2:	00099783          	lh	a5,0(s3)
    80003de6:	c3a1                	beqz	a5,80003e26 <ialloc+0x9c>
    brelse(bp);
    80003de8:	00000097          	auipc	ra,0x0
    80003dec:	a54080e7          	jalr	-1452(ra) # 8000383c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003df0:	0485                	addi	s1,s1,1
    80003df2:	00ca2703          	lw	a4,12(s4)
    80003df6:	0004879b          	sext.w	a5,s1
    80003dfa:	fce7e1e3          	bltu	a5,a4,80003dbc <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003dfe:	00005517          	auipc	a0,0x5
    80003e02:	96250513          	addi	a0,a0,-1694 # 80008760 <syscalls+0x198>
    80003e06:	ffffc097          	auipc	ra,0xffffc
    80003e0a:	788080e7          	jalr	1928(ra) # 8000058e <printf>
  return 0;
    80003e0e:	4501                	li	a0,0
}
    80003e10:	60a6                	ld	ra,72(sp)
    80003e12:	6406                	ld	s0,64(sp)
    80003e14:	74e2                	ld	s1,56(sp)
    80003e16:	7942                	ld	s2,48(sp)
    80003e18:	79a2                	ld	s3,40(sp)
    80003e1a:	7a02                	ld	s4,32(sp)
    80003e1c:	6ae2                	ld	s5,24(sp)
    80003e1e:	6b42                	ld	s6,16(sp)
    80003e20:	6ba2                	ld	s7,8(sp)
    80003e22:	6161                	addi	sp,sp,80
    80003e24:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003e26:	04000613          	li	a2,64
    80003e2a:	4581                	li	a1,0
    80003e2c:	854e                	mv	a0,s3
    80003e2e:	ffffd097          	auipc	ra,0xffffd
    80003e32:	eb8080e7          	jalr	-328(ra) # 80000ce6 <memset>
      dip->type = type;
    80003e36:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003e3a:	854a                	mv	a0,s2
    80003e3c:	00001097          	auipc	ra,0x1
    80003e40:	c84080e7          	jalr	-892(ra) # 80004ac0 <log_write>
      brelse(bp);
    80003e44:	854a                	mv	a0,s2
    80003e46:	00000097          	auipc	ra,0x0
    80003e4a:	9f6080e7          	jalr	-1546(ra) # 8000383c <brelse>
      return iget(dev, inum);
    80003e4e:	85da                	mv	a1,s6
    80003e50:	8556                	mv	a0,s5
    80003e52:	00000097          	auipc	ra,0x0
    80003e56:	d9c080e7          	jalr	-612(ra) # 80003bee <iget>
    80003e5a:	bf5d                	j	80003e10 <ialloc+0x86>

0000000080003e5c <iupdate>:
{
    80003e5c:	1101                	addi	sp,sp,-32
    80003e5e:	ec06                	sd	ra,24(sp)
    80003e60:	e822                	sd	s0,16(sp)
    80003e62:	e426                	sd	s1,8(sp)
    80003e64:	e04a                	sd	s2,0(sp)
    80003e66:	1000                	addi	s0,sp,32
    80003e68:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e6a:	415c                	lw	a5,4(a0)
    80003e6c:	0047d79b          	srliw	a5,a5,0x4
    80003e70:	0001d597          	auipc	a1,0x1d
    80003e74:	c905a583          	lw	a1,-880(a1) # 80020b00 <sb+0x18>
    80003e78:	9dbd                	addw	a1,a1,a5
    80003e7a:	4108                	lw	a0,0(a0)
    80003e7c:	00000097          	auipc	ra,0x0
    80003e80:	890080e7          	jalr	-1904(ra) # 8000370c <bread>
    80003e84:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e86:	05850793          	addi	a5,a0,88
    80003e8a:	40c8                	lw	a0,4(s1)
    80003e8c:	893d                	andi	a0,a0,15
    80003e8e:	051a                	slli	a0,a0,0x6
    80003e90:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003e92:	04449703          	lh	a4,68(s1)
    80003e96:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003e9a:	04649703          	lh	a4,70(s1)
    80003e9e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003ea2:	04849703          	lh	a4,72(s1)
    80003ea6:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003eaa:	04a49703          	lh	a4,74(s1)
    80003eae:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003eb2:	44f8                	lw	a4,76(s1)
    80003eb4:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003eb6:	03400613          	li	a2,52
    80003eba:	05048593          	addi	a1,s1,80
    80003ebe:	0531                	addi	a0,a0,12
    80003ec0:	ffffd097          	auipc	ra,0xffffd
    80003ec4:	e86080e7          	jalr	-378(ra) # 80000d46 <memmove>
  log_write(bp);
    80003ec8:	854a                	mv	a0,s2
    80003eca:	00001097          	auipc	ra,0x1
    80003ece:	bf6080e7          	jalr	-1034(ra) # 80004ac0 <log_write>
  brelse(bp);
    80003ed2:	854a                	mv	a0,s2
    80003ed4:	00000097          	auipc	ra,0x0
    80003ed8:	968080e7          	jalr	-1688(ra) # 8000383c <brelse>
}
    80003edc:	60e2                	ld	ra,24(sp)
    80003ede:	6442                	ld	s0,16(sp)
    80003ee0:	64a2                	ld	s1,8(sp)
    80003ee2:	6902                	ld	s2,0(sp)
    80003ee4:	6105                	addi	sp,sp,32
    80003ee6:	8082                	ret

0000000080003ee8 <idup>:
{
    80003ee8:	1101                	addi	sp,sp,-32
    80003eea:	ec06                	sd	ra,24(sp)
    80003eec:	e822                	sd	s0,16(sp)
    80003eee:	e426                	sd	s1,8(sp)
    80003ef0:	1000                	addi	s0,sp,32
    80003ef2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ef4:	0001d517          	auipc	a0,0x1d
    80003ef8:	c1450513          	addi	a0,a0,-1004 # 80020b08 <itable>
    80003efc:	ffffd097          	auipc	ra,0xffffd
    80003f00:	cee080e7          	jalr	-786(ra) # 80000bea <acquire>
  ip->ref++;
    80003f04:	449c                	lw	a5,8(s1)
    80003f06:	2785                	addiw	a5,a5,1
    80003f08:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003f0a:	0001d517          	auipc	a0,0x1d
    80003f0e:	bfe50513          	addi	a0,a0,-1026 # 80020b08 <itable>
    80003f12:	ffffd097          	auipc	ra,0xffffd
    80003f16:	d8c080e7          	jalr	-628(ra) # 80000c9e <release>
}
    80003f1a:	8526                	mv	a0,s1
    80003f1c:	60e2                	ld	ra,24(sp)
    80003f1e:	6442                	ld	s0,16(sp)
    80003f20:	64a2                	ld	s1,8(sp)
    80003f22:	6105                	addi	sp,sp,32
    80003f24:	8082                	ret

0000000080003f26 <ilock>:
{
    80003f26:	1101                	addi	sp,sp,-32
    80003f28:	ec06                	sd	ra,24(sp)
    80003f2a:	e822                	sd	s0,16(sp)
    80003f2c:	e426                	sd	s1,8(sp)
    80003f2e:	e04a                	sd	s2,0(sp)
    80003f30:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003f32:	c115                	beqz	a0,80003f56 <ilock+0x30>
    80003f34:	84aa                	mv	s1,a0
    80003f36:	451c                	lw	a5,8(a0)
    80003f38:	00f05f63          	blez	a5,80003f56 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003f3c:	0541                	addi	a0,a0,16
    80003f3e:	00001097          	auipc	ra,0x1
    80003f42:	ca2080e7          	jalr	-862(ra) # 80004be0 <acquiresleep>
  if(ip->valid == 0){
    80003f46:	40bc                	lw	a5,64(s1)
    80003f48:	cf99                	beqz	a5,80003f66 <ilock+0x40>
}
    80003f4a:	60e2                	ld	ra,24(sp)
    80003f4c:	6442                	ld	s0,16(sp)
    80003f4e:	64a2                	ld	s1,8(sp)
    80003f50:	6902                	ld	s2,0(sp)
    80003f52:	6105                	addi	sp,sp,32
    80003f54:	8082                	ret
    panic("ilock");
    80003f56:	00005517          	auipc	a0,0x5
    80003f5a:	82250513          	addi	a0,a0,-2014 # 80008778 <syscalls+0x1b0>
    80003f5e:	ffffc097          	auipc	ra,0xffffc
    80003f62:	5e6080e7          	jalr	1510(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003f66:	40dc                	lw	a5,4(s1)
    80003f68:	0047d79b          	srliw	a5,a5,0x4
    80003f6c:	0001d597          	auipc	a1,0x1d
    80003f70:	b945a583          	lw	a1,-1132(a1) # 80020b00 <sb+0x18>
    80003f74:	9dbd                	addw	a1,a1,a5
    80003f76:	4088                	lw	a0,0(s1)
    80003f78:	fffff097          	auipc	ra,0xfffff
    80003f7c:	794080e7          	jalr	1940(ra) # 8000370c <bread>
    80003f80:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003f82:	05850593          	addi	a1,a0,88
    80003f86:	40dc                	lw	a5,4(s1)
    80003f88:	8bbd                	andi	a5,a5,15
    80003f8a:	079a                	slli	a5,a5,0x6
    80003f8c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003f8e:	00059783          	lh	a5,0(a1)
    80003f92:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003f96:	00259783          	lh	a5,2(a1)
    80003f9a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003f9e:	00459783          	lh	a5,4(a1)
    80003fa2:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003fa6:	00659783          	lh	a5,6(a1)
    80003faa:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003fae:	459c                	lw	a5,8(a1)
    80003fb0:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003fb2:	03400613          	li	a2,52
    80003fb6:	05b1                	addi	a1,a1,12
    80003fb8:	05048513          	addi	a0,s1,80
    80003fbc:	ffffd097          	auipc	ra,0xffffd
    80003fc0:	d8a080e7          	jalr	-630(ra) # 80000d46 <memmove>
    brelse(bp);
    80003fc4:	854a                	mv	a0,s2
    80003fc6:	00000097          	auipc	ra,0x0
    80003fca:	876080e7          	jalr	-1930(ra) # 8000383c <brelse>
    ip->valid = 1;
    80003fce:	4785                	li	a5,1
    80003fd0:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003fd2:	04449783          	lh	a5,68(s1)
    80003fd6:	fbb5                	bnez	a5,80003f4a <ilock+0x24>
      panic("ilock: no type");
    80003fd8:	00004517          	auipc	a0,0x4
    80003fdc:	7a850513          	addi	a0,a0,1960 # 80008780 <syscalls+0x1b8>
    80003fe0:	ffffc097          	auipc	ra,0xffffc
    80003fe4:	564080e7          	jalr	1380(ra) # 80000544 <panic>

0000000080003fe8 <iunlock>:
{
    80003fe8:	1101                	addi	sp,sp,-32
    80003fea:	ec06                	sd	ra,24(sp)
    80003fec:	e822                	sd	s0,16(sp)
    80003fee:	e426                	sd	s1,8(sp)
    80003ff0:	e04a                	sd	s2,0(sp)
    80003ff2:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003ff4:	c905                	beqz	a0,80004024 <iunlock+0x3c>
    80003ff6:	84aa                	mv	s1,a0
    80003ff8:	01050913          	addi	s2,a0,16
    80003ffc:	854a                	mv	a0,s2
    80003ffe:	00001097          	auipc	ra,0x1
    80004002:	c7c080e7          	jalr	-900(ra) # 80004c7a <holdingsleep>
    80004006:	cd19                	beqz	a0,80004024 <iunlock+0x3c>
    80004008:	449c                	lw	a5,8(s1)
    8000400a:	00f05d63          	blez	a5,80004024 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000400e:	854a                	mv	a0,s2
    80004010:	00001097          	auipc	ra,0x1
    80004014:	c26080e7          	jalr	-986(ra) # 80004c36 <releasesleep>
}
    80004018:	60e2                	ld	ra,24(sp)
    8000401a:	6442                	ld	s0,16(sp)
    8000401c:	64a2                	ld	s1,8(sp)
    8000401e:	6902                	ld	s2,0(sp)
    80004020:	6105                	addi	sp,sp,32
    80004022:	8082                	ret
    panic("iunlock");
    80004024:	00004517          	auipc	a0,0x4
    80004028:	76c50513          	addi	a0,a0,1900 # 80008790 <syscalls+0x1c8>
    8000402c:	ffffc097          	auipc	ra,0xffffc
    80004030:	518080e7          	jalr	1304(ra) # 80000544 <panic>

0000000080004034 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004034:	7179                	addi	sp,sp,-48
    80004036:	f406                	sd	ra,40(sp)
    80004038:	f022                	sd	s0,32(sp)
    8000403a:	ec26                	sd	s1,24(sp)
    8000403c:	e84a                	sd	s2,16(sp)
    8000403e:	e44e                	sd	s3,8(sp)
    80004040:	e052                	sd	s4,0(sp)
    80004042:	1800                	addi	s0,sp,48
    80004044:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004046:	05050493          	addi	s1,a0,80
    8000404a:	08050913          	addi	s2,a0,128
    8000404e:	a021                	j	80004056 <itrunc+0x22>
    80004050:	0491                	addi	s1,s1,4
    80004052:	01248d63          	beq	s1,s2,8000406c <itrunc+0x38>
    if(ip->addrs[i]){
    80004056:	408c                	lw	a1,0(s1)
    80004058:	dde5                	beqz	a1,80004050 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000405a:	0009a503          	lw	a0,0(s3)
    8000405e:	00000097          	auipc	ra,0x0
    80004062:	8f4080e7          	jalr	-1804(ra) # 80003952 <bfree>
      ip->addrs[i] = 0;
    80004066:	0004a023          	sw	zero,0(s1)
    8000406a:	b7dd                	j	80004050 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000406c:	0809a583          	lw	a1,128(s3)
    80004070:	e185                	bnez	a1,80004090 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004072:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004076:	854e                	mv	a0,s3
    80004078:	00000097          	auipc	ra,0x0
    8000407c:	de4080e7          	jalr	-540(ra) # 80003e5c <iupdate>
}
    80004080:	70a2                	ld	ra,40(sp)
    80004082:	7402                	ld	s0,32(sp)
    80004084:	64e2                	ld	s1,24(sp)
    80004086:	6942                	ld	s2,16(sp)
    80004088:	69a2                	ld	s3,8(sp)
    8000408a:	6a02                	ld	s4,0(sp)
    8000408c:	6145                	addi	sp,sp,48
    8000408e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004090:	0009a503          	lw	a0,0(s3)
    80004094:	fffff097          	auipc	ra,0xfffff
    80004098:	678080e7          	jalr	1656(ra) # 8000370c <bread>
    8000409c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000409e:	05850493          	addi	s1,a0,88
    800040a2:	45850913          	addi	s2,a0,1112
    800040a6:	a811                	j	800040ba <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800040a8:	0009a503          	lw	a0,0(s3)
    800040ac:	00000097          	auipc	ra,0x0
    800040b0:	8a6080e7          	jalr	-1882(ra) # 80003952 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800040b4:	0491                	addi	s1,s1,4
    800040b6:	01248563          	beq	s1,s2,800040c0 <itrunc+0x8c>
      if(a[j])
    800040ba:	408c                	lw	a1,0(s1)
    800040bc:	dde5                	beqz	a1,800040b4 <itrunc+0x80>
    800040be:	b7ed                	j	800040a8 <itrunc+0x74>
    brelse(bp);
    800040c0:	8552                	mv	a0,s4
    800040c2:	fffff097          	auipc	ra,0xfffff
    800040c6:	77a080e7          	jalr	1914(ra) # 8000383c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800040ca:	0809a583          	lw	a1,128(s3)
    800040ce:	0009a503          	lw	a0,0(s3)
    800040d2:	00000097          	auipc	ra,0x0
    800040d6:	880080e7          	jalr	-1920(ra) # 80003952 <bfree>
    ip->addrs[NDIRECT] = 0;
    800040da:	0809a023          	sw	zero,128(s3)
    800040de:	bf51                	j	80004072 <itrunc+0x3e>

00000000800040e0 <iput>:
{
    800040e0:	1101                	addi	sp,sp,-32
    800040e2:	ec06                	sd	ra,24(sp)
    800040e4:	e822                	sd	s0,16(sp)
    800040e6:	e426                	sd	s1,8(sp)
    800040e8:	e04a                	sd	s2,0(sp)
    800040ea:	1000                	addi	s0,sp,32
    800040ec:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800040ee:	0001d517          	auipc	a0,0x1d
    800040f2:	a1a50513          	addi	a0,a0,-1510 # 80020b08 <itable>
    800040f6:	ffffd097          	auipc	ra,0xffffd
    800040fa:	af4080e7          	jalr	-1292(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800040fe:	4498                	lw	a4,8(s1)
    80004100:	4785                	li	a5,1
    80004102:	02f70363          	beq	a4,a5,80004128 <iput+0x48>
  ip->ref--;
    80004106:	449c                	lw	a5,8(s1)
    80004108:	37fd                	addiw	a5,a5,-1
    8000410a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000410c:	0001d517          	auipc	a0,0x1d
    80004110:	9fc50513          	addi	a0,a0,-1540 # 80020b08 <itable>
    80004114:	ffffd097          	auipc	ra,0xffffd
    80004118:	b8a080e7          	jalr	-1142(ra) # 80000c9e <release>
}
    8000411c:	60e2                	ld	ra,24(sp)
    8000411e:	6442                	ld	s0,16(sp)
    80004120:	64a2                	ld	s1,8(sp)
    80004122:	6902                	ld	s2,0(sp)
    80004124:	6105                	addi	sp,sp,32
    80004126:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004128:	40bc                	lw	a5,64(s1)
    8000412a:	dff1                	beqz	a5,80004106 <iput+0x26>
    8000412c:	04a49783          	lh	a5,74(s1)
    80004130:	fbf9                	bnez	a5,80004106 <iput+0x26>
    acquiresleep(&ip->lock);
    80004132:	01048913          	addi	s2,s1,16
    80004136:	854a                	mv	a0,s2
    80004138:	00001097          	auipc	ra,0x1
    8000413c:	aa8080e7          	jalr	-1368(ra) # 80004be0 <acquiresleep>
    release(&itable.lock);
    80004140:	0001d517          	auipc	a0,0x1d
    80004144:	9c850513          	addi	a0,a0,-1592 # 80020b08 <itable>
    80004148:	ffffd097          	auipc	ra,0xffffd
    8000414c:	b56080e7          	jalr	-1194(ra) # 80000c9e <release>
    itrunc(ip);
    80004150:	8526                	mv	a0,s1
    80004152:	00000097          	auipc	ra,0x0
    80004156:	ee2080e7          	jalr	-286(ra) # 80004034 <itrunc>
    ip->type = 0;
    8000415a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000415e:	8526                	mv	a0,s1
    80004160:	00000097          	auipc	ra,0x0
    80004164:	cfc080e7          	jalr	-772(ra) # 80003e5c <iupdate>
    ip->valid = 0;
    80004168:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000416c:	854a                	mv	a0,s2
    8000416e:	00001097          	auipc	ra,0x1
    80004172:	ac8080e7          	jalr	-1336(ra) # 80004c36 <releasesleep>
    acquire(&itable.lock);
    80004176:	0001d517          	auipc	a0,0x1d
    8000417a:	99250513          	addi	a0,a0,-1646 # 80020b08 <itable>
    8000417e:	ffffd097          	auipc	ra,0xffffd
    80004182:	a6c080e7          	jalr	-1428(ra) # 80000bea <acquire>
    80004186:	b741                	j	80004106 <iput+0x26>

0000000080004188 <iunlockput>:
{
    80004188:	1101                	addi	sp,sp,-32
    8000418a:	ec06                	sd	ra,24(sp)
    8000418c:	e822                	sd	s0,16(sp)
    8000418e:	e426                	sd	s1,8(sp)
    80004190:	1000                	addi	s0,sp,32
    80004192:	84aa                	mv	s1,a0
  iunlock(ip);
    80004194:	00000097          	auipc	ra,0x0
    80004198:	e54080e7          	jalr	-428(ra) # 80003fe8 <iunlock>
  iput(ip);
    8000419c:	8526                	mv	a0,s1
    8000419e:	00000097          	auipc	ra,0x0
    800041a2:	f42080e7          	jalr	-190(ra) # 800040e0 <iput>
}
    800041a6:	60e2                	ld	ra,24(sp)
    800041a8:	6442                	ld	s0,16(sp)
    800041aa:	64a2                	ld	s1,8(sp)
    800041ac:	6105                	addi	sp,sp,32
    800041ae:	8082                	ret

00000000800041b0 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800041b0:	1141                	addi	sp,sp,-16
    800041b2:	e422                	sd	s0,8(sp)
    800041b4:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800041b6:	411c                	lw	a5,0(a0)
    800041b8:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800041ba:	415c                	lw	a5,4(a0)
    800041bc:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800041be:	04451783          	lh	a5,68(a0)
    800041c2:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800041c6:	04a51783          	lh	a5,74(a0)
    800041ca:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800041ce:	04c56783          	lwu	a5,76(a0)
    800041d2:	e99c                	sd	a5,16(a1)
}
    800041d4:	6422                	ld	s0,8(sp)
    800041d6:	0141                	addi	sp,sp,16
    800041d8:	8082                	ret

00000000800041da <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800041da:	457c                	lw	a5,76(a0)
    800041dc:	0ed7e963          	bltu	a5,a3,800042ce <readi+0xf4>
{
    800041e0:	7159                	addi	sp,sp,-112
    800041e2:	f486                	sd	ra,104(sp)
    800041e4:	f0a2                	sd	s0,96(sp)
    800041e6:	eca6                	sd	s1,88(sp)
    800041e8:	e8ca                	sd	s2,80(sp)
    800041ea:	e4ce                	sd	s3,72(sp)
    800041ec:	e0d2                	sd	s4,64(sp)
    800041ee:	fc56                	sd	s5,56(sp)
    800041f0:	f85a                	sd	s6,48(sp)
    800041f2:	f45e                	sd	s7,40(sp)
    800041f4:	f062                	sd	s8,32(sp)
    800041f6:	ec66                	sd	s9,24(sp)
    800041f8:	e86a                	sd	s10,16(sp)
    800041fa:	e46e                	sd	s11,8(sp)
    800041fc:	1880                	addi	s0,sp,112
    800041fe:	8b2a                	mv	s6,a0
    80004200:	8bae                	mv	s7,a1
    80004202:	8a32                	mv	s4,a2
    80004204:	84b6                	mv	s1,a3
    80004206:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80004208:	9f35                	addw	a4,a4,a3
    return 0;
    8000420a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000420c:	0ad76063          	bltu	a4,a3,800042ac <readi+0xd2>
  if(off + n > ip->size)
    80004210:	00e7f463          	bgeu	a5,a4,80004218 <readi+0x3e>
    n = ip->size - off;
    80004214:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004218:	0a0a8963          	beqz	s5,800042ca <readi+0xf0>
    8000421c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000421e:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004222:	5c7d                	li	s8,-1
    80004224:	a82d                	j	8000425e <readi+0x84>
    80004226:	020d1d93          	slli	s11,s10,0x20
    8000422a:	020ddd93          	srli	s11,s11,0x20
    8000422e:	05890613          	addi	a2,s2,88
    80004232:	86ee                	mv	a3,s11
    80004234:	963a                	add	a2,a2,a4
    80004236:	85d2                	mv	a1,s4
    80004238:	855e                	mv	a0,s7
    8000423a:	ffffe097          	auipc	ra,0xffffe
    8000423e:	4a6080e7          	jalr	1190(ra) # 800026e0 <either_copyout>
    80004242:	05850d63          	beq	a0,s8,8000429c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004246:	854a                	mv	a0,s2
    80004248:	fffff097          	auipc	ra,0xfffff
    8000424c:	5f4080e7          	jalr	1524(ra) # 8000383c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004250:	013d09bb          	addw	s3,s10,s3
    80004254:	009d04bb          	addw	s1,s10,s1
    80004258:	9a6e                	add	s4,s4,s11
    8000425a:	0559f763          	bgeu	s3,s5,800042a8 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    8000425e:	00a4d59b          	srliw	a1,s1,0xa
    80004262:	855a                	mv	a0,s6
    80004264:	00000097          	auipc	ra,0x0
    80004268:	8a2080e7          	jalr	-1886(ra) # 80003b06 <bmap>
    8000426c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004270:	cd85                	beqz	a1,800042a8 <readi+0xce>
    bp = bread(ip->dev, addr);
    80004272:	000b2503          	lw	a0,0(s6)
    80004276:	fffff097          	auipc	ra,0xfffff
    8000427a:	496080e7          	jalr	1174(ra) # 8000370c <bread>
    8000427e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004280:	3ff4f713          	andi	a4,s1,1023
    80004284:	40ec87bb          	subw	a5,s9,a4
    80004288:	413a86bb          	subw	a3,s5,s3
    8000428c:	8d3e                	mv	s10,a5
    8000428e:	2781                	sext.w	a5,a5
    80004290:	0006861b          	sext.w	a2,a3
    80004294:	f8f679e3          	bgeu	a2,a5,80004226 <readi+0x4c>
    80004298:	8d36                	mv	s10,a3
    8000429a:	b771                	j	80004226 <readi+0x4c>
      brelse(bp);
    8000429c:	854a                	mv	a0,s2
    8000429e:	fffff097          	auipc	ra,0xfffff
    800042a2:	59e080e7          	jalr	1438(ra) # 8000383c <brelse>
      tot = -1;
    800042a6:	59fd                	li	s3,-1
  }
  return tot;
    800042a8:	0009851b          	sext.w	a0,s3
}
    800042ac:	70a6                	ld	ra,104(sp)
    800042ae:	7406                	ld	s0,96(sp)
    800042b0:	64e6                	ld	s1,88(sp)
    800042b2:	6946                	ld	s2,80(sp)
    800042b4:	69a6                	ld	s3,72(sp)
    800042b6:	6a06                	ld	s4,64(sp)
    800042b8:	7ae2                	ld	s5,56(sp)
    800042ba:	7b42                	ld	s6,48(sp)
    800042bc:	7ba2                	ld	s7,40(sp)
    800042be:	7c02                	ld	s8,32(sp)
    800042c0:	6ce2                	ld	s9,24(sp)
    800042c2:	6d42                	ld	s10,16(sp)
    800042c4:	6da2                	ld	s11,8(sp)
    800042c6:	6165                	addi	sp,sp,112
    800042c8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800042ca:	89d6                	mv	s3,s5
    800042cc:	bff1                	j	800042a8 <readi+0xce>
    return 0;
    800042ce:	4501                	li	a0,0
}
    800042d0:	8082                	ret

00000000800042d2 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800042d2:	457c                	lw	a5,76(a0)
    800042d4:	10d7e863          	bltu	a5,a3,800043e4 <writei+0x112>
{
    800042d8:	7159                	addi	sp,sp,-112
    800042da:	f486                	sd	ra,104(sp)
    800042dc:	f0a2                	sd	s0,96(sp)
    800042de:	eca6                	sd	s1,88(sp)
    800042e0:	e8ca                	sd	s2,80(sp)
    800042e2:	e4ce                	sd	s3,72(sp)
    800042e4:	e0d2                	sd	s4,64(sp)
    800042e6:	fc56                	sd	s5,56(sp)
    800042e8:	f85a                	sd	s6,48(sp)
    800042ea:	f45e                	sd	s7,40(sp)
    800042ec:	f062                	sd	s8,32(sp)
    800042ee:	ec66                	sd	s9,24(sp)
    800042f0:	e86a                	sd	s10,16(sp)
    800042f2:	e46e                	sd	s11,8(sp)
    800042f4:	1880                	addi	s0,sp,112
    800042f6:	8aaa                	mv	s5,a0
    800042f8:	8bae                	mv	s7,a1
    800042fa:	8a32                	mv	s4,a2
    800042fc:	8936                	mv	s2,a3
    800042fe:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004300:	00e687bb          	addw	a5,a3,a4
    80004304:	0ed7e263          	bltu	a5,a3,800043e8 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004308:	00043737          	lui	a4,0x43
    8000430c:	0ef76063          	bltu	a4,a5,800043ec <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004310:	0c0b0863          	beqz	s6,800043e0 <writei+0x10e>
    80004314:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004316:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000431a:	5c7d                	li	s8,-1
    8000431c:	a091                	j	80004360 <writei+0x8e>
    8000431e:	020d1d93          	slli	s11,s10,0x20
    80004322:	020ddd93          	srli	s11,s11,0x20
    80004326:	05848513          	addi	a0,s1,88
    8000432a:	86ee                	mv	a3,s11
    8000432c:	8652                	mv	a2,s4
    8000432e:	85de                	mv	a1,s7
    80004330:	953a                	add	a0,a0,a4
    80004332:	ffffe097          	auipc	ra,0xffffe
    80004336:	404080e7          	jalr	1028(ra) # 80002736 <either_copyin>
    8000433a:	07850263          	beq	a0,s8,8000439e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000433e:	8526                	mv	a0,s1
    80004340:	00000097          	auipc	ra,0x0
    80004344:	780080e7          	jalr	1920(ra) # 80004ac0 <log_write>
    brelse(bp);
    80004348:	8526                	mv	a0,s1
    8000434a:	fffff097          	auipc	ra,0xfffff
    8000434e:	4f2080e7          	jalr	1266(ra) # 8000383c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004352:	013d09bb          	addw	s3,s10,s3
    80004356:	012d093b          	addw	s2,s10,s2
    8000435a:	9a6e                	add	s4,s4,s11
    8000435c:	0569f663          	bgeu	s3,s6,800043a8 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004360:	00a9559b          	srliw	a1,s2,0xa
    80004364:	8556                	mv	a0,s5
    80004366:	fffff097          	auipc	ra,0xfffff
    8000436a:	7a0080e7          	jalr	1952(ra) # 80003b06 <bmap>
    8000436e:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004372:	c99d                	beqz	a1,800043a8 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004374:	000aa503          	lw	a0,0(s5)
    80004378:	fffff097          	auipc	ra,0xfffff
    8000437c:	394080e7          	jalr	916(ra) # 8000370c <bread>
    80004380:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004382:	3ff97713          	andi	a4,s2,1023
    80004386:	40ec87bb          	subw	a5,s9,a4
    8000438a:	413b06bb          	subw	a3,s6,s3
    8000438e:	8d3e                	mv	s10,a5
    80004390:	2781                	sext.w	a5,a5
    80004392:	0006861b          	sext.w	a2,a3
    80004396:	f8f674e3          	bgeu	a2,a5,8000431e <writei+0x4c>
    8000439a:	8d36                	mv	s10,a3
    8000439c:	b749                	j	8000431e <writei+0x4c>
      brelse(bp);
    8000439e:	8526                	mv	a0,s1
    800043a0:	fffff097          	auipc	ra,0xfffff
    800043a4:	49c080e7          	jalr	1180(ra) # 8000383c <brelse>
  }

  if(off > ip->size)
    800043a8:	04caa783          	lw	a5,76(s5)
    800043ac:	0127f463          	bgeu	a5,s2,800043b4 <writei+0xe2>
    ip->size = off;
    800043b0:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800043b4:	8556                	mv	a0,s5
    800043b6:	00000097          	auipc	ra,0x0
    800043ba:	aa6080e7          	jalr	-1370(ra) # 80003e5c <iupdate>

  return tot;
    800043be:	0009851b          	sext.w	a0,s3
}
    800043c2:	70a6                	ld	ra,104(sp)
    800043c4:	7406                	ld	s0,96(sp)
    800043c6:	64e6                	ld	s1,88(sp)
    800043c8:	6946                	ld	s2,80(sp)
    800043ca:	69a6                	ld	s3,72(sp)
    800043cc:	6a06                	ld	s4,64(sp)
    800043ce:	7ae2                	ld	s5,56(sp)
    800043d0:	7b42                	ld	s6,48(sp)
    800043d2:	7ba2                	ld	s7,40(sp)
    800043d4:	7c02                	ld	s8,32(sp)
    800043d6:	6ce2                	ld	s9,24(sp)
    800043d8:	6d42                	ld	s10,16(sp)
    800043da:	6da2                	ld	s11,8(sp)
    800043dc:	6165                	addi	sp,sp,112
    800043de:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800043e0:	89da                	mv	s3,s6
    800043e2:	bfc9                	j	800043b4 <writei+0xe2>
    return -1;
    800043e4:	557d                	li	a0,-1
}
    800043e6:	8082                	ret
    return -1;
    800043e8:	557d                	li	a0,-1
    800043ea:	bfe1                	j	800043c2 <writei+0xf0>
    return -1;
    800043ec:	557d                	li	a0,-1
    800043ee:	bfd1                	j	800043c2 <writei+0xf0>

00000000800043f0 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800043f0:	1141                	addi	sp,sp,-16
    800043f2:	e406                	sd	ra,8(sp)
    800043f4:	e022                	sd	s0,0(sp)
    800043f6:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800043f8:	4639                	li	a2,14
    800043fa:	ffffd097          	auipc	ra,0xffffd
    800043fe:	9c4080e7          	jalr	-1596(ra) # 80000dbe <strncmp>
}
    80004402:	60a2                	ld	ra,8(sp)
    80004404:	6402                	ld	s0,0(sp)
    80004406:	0141                	addi	sp,sp,16
    80004408:	8082                	ret

000000008000440a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000440a:	7139                	addi	sp,sp,-64
    8000440c:	fc06                	sd	ra,56(sp)
    8000440e:	f822                	sd	s0,48(sp)
    80004410:	f426                	sd	s1,40(sp)
    80004412:	f04a                	sd	s2,32(sp)
    80004414:	ec4e                	sd	s3,24(sp)
    80004416:	e852                	sd	s4,16(sp)
    80004418:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000441a:	04451703          	lh	a4,68(a0)
    8000441e:	4785                	li	a5,1
    80004420:	00f71a63          	bne	a4,a5,80004434 <dirlookup+0x2a>
    80004424:	892a                	mv	s2,a0
    80004426:	89ae                	mv	s3,a1
    80004428:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000442a:	457c                	lw	a5,76(a0)
    8000442c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000442e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004430:	e79d                	bnez	a5,8000445e <dirlookup+0x54>
    80004432:	a8a5                	j	800044aa <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004434:	00004517          	auipc	a0,0x4
    80004438:	36450513          	addi	a0,a0,868 # 80008798 <syscalls+0x1d0>
    8000443c:	ffffc097          	auipc	ra,0xffffc
    80004440:	108080e7          	jalr	264(ra) # 80000544 <panic>
      panic("dirlookup read");
    80004444:	00004517          	auipc	a0,0x4
    80004448:	36c50513          	addi	a0,a0,876 # 800087b0 <syscalls+0x1e8>
    8000444c:	ffffc097          	auipc	ra,0xffffc
    80004450:	0f8080e7          	jalr	248(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004454:	24c1                	addiw	s1,s1,16
    80004456:	04c92783          	lw	a5,76(s2)
    8000445a:	04f4f763          	bgeu	s1,a5,800044a8 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000445e:	4741                	li	a4,16
    80004460:	86a6                	mv	a3,s1
    80004462:	fc040613          	addi	a2,s0,-64
    80004466:	4581                	li	a1,0
    80004468:	854a                	mv	a0,s2
    8000446a:	00000097          	auipc	ra,0x0
    8000446e:	d70080e7          	jalr	-656(ra) # 800041da <readi>
    80004472:	47c1                	li	a5,16
    80004474:	fcf518e3          	bne	a0,a5,80004444 <dirlookup+0x3a>
    if(de.inum == 0)
    80004478:	fc045783          	lhu	a5,-64(s0)
    8000447c:	dfe1                	beqz	a5,80004454 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000447e:	fc240593          	addi	a1,s0,-62
    80004482:	854e                	mv	a0,s3
    80004484:	00000097          	auipc	ra,0x0
    80004488:	f6c080e7          	jalr	-148(ra) # 800043f0 <namecmp>
    8000448c:	f561                	bnez	a0,80004454 <dirlookup+0x4a>
      if(poff)
    8000448e:	000a0463          	beqz	s4,80004496 <dirlookup+0x8c>
        *poff = off;
    80004492:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004496:	fc045583          	lhu	a1,-64(s0)
    8000449a:	00092503          	lw	a0,0(s2)
    8000449e:	fffff097          	auipc	ra,0xfffff
    800044a2:	750080e7          	jalr	1872(ra) # 80003bee <iget>
    800044a6:	a011                	j	800044aa <dirlookup+0xa0>
  return 0;
    800044a8:	4501                	li	a0,0
}
    800044aa:	70e2                	ld	ra,56(sp)
    800044ac:	7442                	ld	s0,48(sp)
    800044ae:	74a2                	ld	s1,40(sp)
    800044b0:	7902                	ld	s2,32(sp)
    800044b2:	69e2                	ld	s3,24(sp)
    800044b4:	6a42                	ld	s4,16(sp)
    800044b6:	6121                	addi	sp,sp,64
    800044b8:	8082                	ret

00000000800044ba <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800044ba:	711d                	addi	sp,sp,-96
    800044bc:	ec86                	sd	ra,88(sp)
    800044be:	e8a2                	sd	s0,80(sp)
    800044c0:	e4a6                	sd	s1,72(sp)
    800044c2:	e0ca                	sd	s2,64(sp)
    800044c4:	fc4e                	sd	s3,56(sp)
    800044c6:	f852                	sd	s4,48(sp)
    800044c8:	f456                	sd	s5,40(sp)
    800044ca:	f05a                	sd	s6,32(sp)
    800044cc:	ec5e                	sd	s7,24(sp)
    800044ce:	e862                	sd	s8,16(sp)
    800044d0:	e466                	sd	s9,8(sp)
    800044d2:	1080                	addi	s0,sp,96
    800044d4:	84aa                	mv	s1,a0
    800044d6:	8b2e                	mv	s6,a1
    800044d8:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800044da:	00054703          	lbu	a4,0(a0)
    800044de:	02f00793          	li	a5,47
    800044e2:	02f70363          	beq	a4,a5,80004508 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800044e6:	ffffd097          	auipc	ra,0xffffd
    800044ea:	4e0080e7          	jalr	1248(ra) # 800019c6 <myproc>
    800044ee:	15053503          	ld	a0,336(a0)
    800044f2:	00000097          	auipc	ra,0x0
    800044f6:	9f6080e7          	jalr	-1546(ra) # 80003ee8 <idup>
    800044fa:	89aa                	mv	s3,a0
  while(*path == '/')
    800044fc:	02f00913          	li	s2,47
  len = path - s;
    80004500:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004502:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004504:	4c05                	li	s8,1
    80004506:	a865                	j	800045be <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004508:	4585                	li	a1,1
    8000450a:	4505                	li	a0,1
    8000450c:	fffff097          	auipc	ra,0xfffff
    80004510:	6e2080e7          	jalr	1762(ra) # 80003bee <iget>
    80004514:	89aa                	mv	s3,a0
    80004516:	b7dd                	j	800044fc <namex+0x42>
      iunlockput(ip);
    80004518:	854e                	mv	a0,s3
    8000451a:	00000097          	auipc	ra,0x0
    8000451e:	c6e080e7          	jalr	-914(ra) # 80004188 <iunlockput>
      return 0;
    80004522:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004524:	854e                	mv	a0,s3
    80004526:	60e6                	ld	ra,88(sp)
    80004528:	6446                	ld	s0,80(sp)
    8000452a:	64a6                	ld	s1,72(sp)
    8000452c:	6906                	ld	s2,64(sp)
    8000452e:	79e2                	ld	s3,56(sp)
    80004530:	7a42                	ld	s4,48(sp)
    80004532:	7aa2                	ld	s5,40(sp)
    80004534:	7b02                	ld	s6,32(sp)
    80004536:	6be2                	ld	s7,24(sp)
    80004538:	6c42                	ld	s8,16(sp)
    8000453a:	6ca2                	ld	s9,8(sp)
    8000453c:	6125                	addi	sp,sp,96
    8000453e:	8082                	ret
      iunlock(ip);
    80004540:	854e                	mv	a0,s3
    80004542:	00000097          	auipc	ra,0x0
    80004546:	aa6080e7          	jalr	-1370(ra) # 80003fe8 <iunlock>
      return ip;
    8000454a:	bfe9                	j	80004524 <namex+0x6a>
      iunlockput(ip);
    8000454c:	854e                	mv	a0,s3
    8000454e:	00000097          	auipc	ra,0x0
    80004552:	c3a080e7          	jalr	-966(ra) # 80004188 <iunlockput>
      return 0;
    80004556:	89d2                	mv	s3,s4
    80004558:	b7f1                	j	80004524 <namex+0x6a>
  len = path - s;
    8000455a:	40b48633          	sub	a2,s1,a1
    8000455e:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004562:	094cd463          	bge	s9,s4,800045ea <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004566:	4639                	li	a2,14
    80004568:	8556                	mv	a0,s5
    8000456a:	ffffc097          	auipc	ra,0xffffc
    8000456e:	7dc080e7          	jalr	2012(ra) # 80000d46 <memmove>
  while(*path == '/')
    80004572:	0004c783          	lbu	a5,0(s1)
    80004576:	01279763          	bne	a5,s2,80004584 <namex+0xca>
    path++;
    8000457a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000457c:	0004c783          	lbu	a5,0(s1)
    80004580:	ff278de3          	beq	a5,s2,8000457a <namex+0xc0>
    ilock(ip);
    80004584:	854e                	mv	a0,s3
    80004586:	00000097          	auipc	ra,0x0
    8000458a:	9a0080e7          	jalr	-1632(ra) # 80003f26 <ilock>
    if(ip->type != T_DIR){
    8000458e:	04499783          	lh	a5,68(s3)
    80004592:	f98793e3          	bne	a5,s8,80004518 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004596:	000b0563          	beqz	s6,800045a0 <namex+0xe6>
    8000459a:	0004c783          	lbu	a5,0(s1)
    8000459e:	d3cd                	beqz	a5,80004540 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800045a0:	865e                	mv	a2,s7
    800045a2:	85d6                	mv	a1,s5
    800045a4:	854e                	mv	a0,s3
    800045a6:	00000097          	auipc	ra,0x0
    800045aa:	e64080e7          	jalr	-412(ra) # 8000440a <dirlookup>
    800045ae:	8a2a                	mv	s4,a0
    800045b0:	dd51                	beqz	a0,8000454c <namex+0x92>
    iunlockput(ip);
    800045b2:	854e                	mv	a0,s3
    800045b4:	00000097          	auipc	ra,0x0
    800045b8:	bd4080e7          	jalr	-1068(ra) # 80004188 <iunlockput>
    ip = next;
    800045bc:	89d2                	mv	s3,s4
  while(*path == '/')
    800045be:	0004c783          	lbu	a5,0(s1)
    800045c2:	05279763          	bne	a5,s2,80004610 <namex+0x156>
    path++;
    800045c6:	0485                	addi	s1,s1,1
  while(*path == '/')
    800045c8:	0004c783          	lbu	a5,0(s1)
    800045cc:	ff278de3          	beq	a5,s2,800045c6 <namex+0x10c>
  if(*path == 0)
    800045d0:	c79d                	beqz	a5,800045fe <namex+0x144>
    path++;
    800045d2:	85a6                	mv	a1,s1
  len = path - s;
    800045d4:	8a5e                	mv	s4,s7
    800045d6:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800045d8:	01278963          	beq	a5,s2,800045ea <namex+0x130>
    800045dc:	dfbd                	beqz	a5,8000455a <namex+0xa0>
    path++;
    800045de:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800045e0:	0004c783          	lbu	a5,0(s1)
    800045e4:	ff279ce3          	bne	a5,s2,800045dc <namex+0x122>
    800045e8:	bf8d                	j	8000455a <namex+0xa0>
    memmove(name, s, len);
    800045ea:	2601                	sext.w	a2,a2
    800045ec:	8556                	mv	a0,s5
    800045ee:	ffffc097          	auipc	ra,0xffffc
    800045f2:	758080e7          	jalr	1880(ra) # 80000d46 <memmove>
    name[len] = 0;
    800045f6:	9a56                	add	s4,s4,s5
    800045f8:	000a0023          	sb	zero,0(s4)
    800045fc:	bf9d                	j	80004572 <namex+0xb8>
  if(nameiparent){
    800045fe:	f20b03e3          	beqz	s6,80004524 <namex+0x6a>
    iput(ip);
    80004602:	854e                	mv	a0,s3
    80004604:	00000097          	auipc	ra,0x0
    80004608:	adc080e7          	jalr	-1316(ra) # 800040e0 <iput>
    return 0;
    8000460c:	4981                	li	s3,0
    8000460e:	bf19                	j	80004524 <namex+0x6a>
  if(*path == 0)
    80004610:	d7fd                	beqz	a5,800045fe <namex+0x144>
  while(*path != '/' && *path != 0)
    80004612:	0004c783          	lbu	a5,0(s1)
    80004616:	85a6                	mv	a1,s1
    80004618:	b7d1                	j	800045dc <namex+0x122>

000000008000461a <dirlink>:
{
    8000461a:	7139                	addi	sp,sp,-64
    8000461c:	fc06                	sd	ra,56(sp)
    8000461e:	f822                	sd	s0,48(sp)
    80004620:	f426                	sd	s1,40(sp)
    80004622:	f04a                	sd	s2,32(sp)
    80004624:	ec4e                	sd	s3,24(sp)
    80004626:	e852                	sd	s4,16(sp)
    80004628:	0080                	addi	s0,sp,64
    8000462a:	892a                	mv	s2,a0
    8000462c:	8a2e                	mv	s4,a1
    8000462e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004630:	4601                	li	a2,0
    80004632:	00000097          	auipc	ra,0x0
    80004636:	dd8080e7          	jalr	-552(ra) # 8000440a <dirlookup>
    8000463a:	e93d                	bnez	a0,800046b0 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000463c:	04c92483          	lw	s1,76(s2)
    80004640:	c49d                	beqz	s1,8000466e <dirlink+0x54>
    80004642:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004644:	4741                	li	a4,16
    80004646:	86a6                	mv	a3,s1
    80004648:	fc040613          	addi	a2,s0,-64
    8000464c:	4581                	li	a1,0
    8000464e:	854a                	mv	a0,s2
    80004650:	00000097          	auipc	ra,0x0
    80004654:	b8a080e7          	jalr	-1142(ra) # 800041da <readi>
    80004658:	47c1                	li	a5,16
    8000465a:	06f51163          	bne	a0,a5,800046bc <dirlink+0xa2>
    if(de.inum == 0)
    8000465e:	fc045783          	lhu	a5,-64(s0)
    80004662:	c791                	beqz	a5,8000466e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004664:	24c1                	addiw	s1,s1,16
    80004666:	04c92783          	lw	a5,76(s2)
    8000466a:	fcf4ede3          	bltu	s1,a5,80004644 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000466e:	4639                	li	a2,14
    80004670:	85d2                	mv	a1,s4
    80004672:	fc240513          	addi	a0,s0,-62
    80004676:	ffffc097          	auipc	ra,0xffffc
    8000467a:	784080e7          	jalr	1924(ra) # 80000dfa <strncpy>
  de.inum = inum;
    8000467e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004682:	4741                	li	a4,16
    80004684:	86a6                	mv	a3,s1
    80004686:	fc040613          	addi	a2,s0,-64
    8000468a:	4581                	li	a1,0
    8000468c:	854a                	mv	a0,s2
    8000468e:	00000097          	auipc	ra,0x0
    80004692:	c44080e7          	jalr	-956(ra) # 800042d2 <writei>
    80004696:	1541                	addi	a0,a0,-16
    80004698:	00a03533          	snez	a0,a0
    8000469c:	40a00533          	neg	a0,a0
}
    800046a0:	70e2                	ld	ra,56(sp)
    800046a2:	7442                	ld	s0,48(sp)
    800046a4:	74a2                	ld	s1,40(sp)
    800046a6:	7902                	ld	s2,32(sp)
    800046a8:	69e2                	ld	s3,24(sp)
    800046aa:	6a42                	ld	s4,16(sp)
    800046ac:	6121                	addi	sp,sp,64
    800046ae:	8082                	ret
    iput(ip);
    800046b0:	00000097          	auipc	ra,0x0
    800046b4:	a30080e7          	jalr	-1488(ra) # 800040e0 <iput>
    return -1;
    800046b8:	557d                	li	a0,-1
    800046ba:	b7dd                	j	800046a0 <dirlink+0x86>
      panic("dirlink read");
    800046bc:	00004517          	auipc	a0,0x4
    800046c0:	10450513          	addi	a0,a0,260 # 800087c0 <syscalls+0x1f8>
    800046c4:	ffffc097          	auipc	ra,0xffffc
    800046c8:	e80080e7          	jalr	-384(ra) # 80000544 <panic>

00000000800046cc <namei>:

struct inode*
namei(char *path)
{
    800046cc:	1101                	addi	sp,sp,-32
    800046ce:	ec06                	sd	ra,24(sp)
    800046d0:	e822                	sd	s0,16(sp)
    800046d2:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800046d4:	fe040613          	addi	a2,s0,-32
    800046d8:	4581                	li	a1,0
    800046da:	00000097          	auipc	ra,0x0
    800046de:	de0080e7          	jalr	-544(ra) # 800044ba <namex>
}
    800046e2:	60e2                	ld	ra,24(sp)
    800046e4:	6442                	ld	s0,16(sp)
    800046e6:	6105                	addi	sp,sp,32
    800046e8:	8082                	ret

00000000800046ea <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800046ea:	1141                	addi	sp,sp,-16
    800046ec:	e406                	sd	ra,8(sp)
    800046ee:	e022                	sd	s0,0(sp)
    800046f0:	0800                	addi	s0,sp,16
    800046f2:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800046f4:	4585                	li	a1,1
    800046f6:	00000097          	auipc	ra,0x0
    800046fa:	dc4080e7          	jalr	-572(ra) # 800044ba <namex>
}
    800046fe:	60a2                	ld	ra,8(sp)
    80004700:	6402                	ld	s0,0(sp)
    80004702:	0141                	addi	sp,sp,16
    80004704:	8082                	ret

0000000080004706 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004706:	1101                	addi	sp,sp,-32
    80004708:	ec06                	sd	ra,24(sp)
    8000470a:	e822                	sd	s0,16(sp)
    8000470c:	e426                	sd	s1,8(sp)
    8000470e:	e04a                	sd	s2,0(sp)
    80004710:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004712:	0001e917          	auipc	s2,0x1e
    80004716:	e9e90913          	addi	s2,s2,-354 # 800225b0 <log>
    8000471a:	01892583          	lw	a1,24(s2)
    8000471e:	02892503          	lw	a0,40(s2)
    80004722:	fffff097          	auipc	ra,0xfffff
    80004726:	fea080e7          	jalr	-22(ra) # 8000370c <bread>
    8000472a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000472c:	02c92683          	lw	a3,44(s2)
    80004730:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004732:	02d05763          	blez	a3,80004760 <write_head+0x5a>
    80004736:	0001e797          	auipc	a5,0x1e
    8000473a:	eaa78793          	addi	a5,a5,-342 # 800225e0 <log+0x30>
    8000473e:	05c50713          	addi	a4,a0,92
    80004742:	36fd                	addiw	a3,a3,-1
    80004744:	1682                	slli	a3,a3,0x20
    80004746:	9281                	srli	a3,a3,0x20
    80004748:	068a                	slli	a3,a3,0x2
    8000474a:	0001e617          	auipc	a2,0x1e
    8000474e:	e9a60613          	addi	a2,a2,-358 # 800225e4 <log+0x34>
    80004752:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004754:	4390                	lw	a2,0(a5)
    80004756:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004758:	0791                	addi	a5,a5,4
    8000475a:	0711                	addi	a4,a4,4
    8000475c:	fed79ce3          	bne	a5,a3,80004754 <write_head+0x4e>
  }
  bwrite(buf);
    80004760:	8526                	mv	a0,s1
    80004762:	fffff097          	auipc	ra,0xfffff
    80004766:	09c080e7          	jalr	156(ra) # 800037fe <bwrite>
  brelse(buf);
    8000476a:	8526                	mv	a0,s1
    8000476c:	fffff097          	auipc	ra,0xfffff
    80004770:	0d0080e7          	jalr	208(ra) # 8000383c <brelse>
}
    80004774:	60e2                	ld	ra,24(sp)
    80004776:	6442                	ld	s0,16(sp)
    80004778:	64a2                	ld	s1,8(sp)
    8000477a:	6902                	ld	s2,0(sp)
    8000477c:	6105                	addi	sp,sp,32
    8000477e:	8082                	ret

0000000080004780 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004780:	0001e797          	auipc	a5,0x1e
    80004784:	e5c7a783          	lw	a5,-420(a5) # 800225dc <log+0x2c>
    80004788:	0af05d63          	blez	a5,80004842 <install_trans+0xc2>
{
    8000478c:	7139                	addi	sp,sp,-64
    8000478e:	fc06                	sd	ra,56(sp)
    80004790:	f822                	sd	s0,48(sp)
    80004792:	f426                	sd	s1,40(sp)
    80004794:	f04a                	sd	s2,32(sp)
    80004796:	ec4e                	sd	s3,24(sp)
    80004798:	e852                	sd	s4,16(sp)
    8000479a:	e456                	sd	s5,8(sp)
    8000479c:	e05a                	sd	s6,0(sp)
    8000479e:	0080                	addi	s0,sp,64
    800047a0:	8b2a                	mv	s6,a0
    800047a2:	0001ea97          	auipc	s5,0x1e
    800047a6:	e3ea8a93          	addi	s5,s5,-450 # 800225e0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047aa:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800047ac:	0001e997          	auipc	s3,0x1e
    800047b0:	e0498993          	addi	s3,s3,-508 # 800225b0 <log>
    800047b4:	a035                	j	800047e0 <install_trans+0x60>
      bunpin(dbuf);
    800047b6:	8526                	mv	a0,s1
    800047b8:	fffff097          	auipc	ra,0xfffff
    800047bc:	15e080e7          	jalr	350(ra) # 80003916 <bunpin>
    brelse(lbuf);
    800047c0:	854a                	mv	a0,s2
    800047c2:	fffff097          	auipc	ra,0xfffff
    800047c6:	07a080e7          	jalr	122(ra) # 8000383c <brelse>
    brelse(dbuf);
    800047ca:	8526                	mv	a0,s1
    800047cc:	fffff097          	auipc	ra,0xfffff
    800047d0:	070080e7          	jalr	112(ra) # 8000383c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047d4:	2a05                	addiw	s4,s4,1
    800047d6:	0a91                	addi	s5,s5,4
    800047d8:	02c9a783          	lw	a5,44(s3)
    800047dc:	04fa5963          	bge	s4,a5,8000482e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800047e0:	0189a583          	lw	a1,24(s3)
    800047e4:	014585bb          	addw	a1,a1,s4
    800047e8:	2585                	addiw	a1,a1,1
    800047ea:	0289a503          	lw	a0,40(s3)
    800047ee:	fffff097          	auipc	ra,0xfffff
    800047f2:	f1e080e7          	jalr	-226(ra) # 8000370c <bread>
    800047f6:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800047f8:	000aa583          	lw	a1,0(s5)
    800047fc:	0289a503          	lw	a0,40(s3)
    80004800:	fffff097          	auipc	ra,0xfffff
    80004804:	f0c080e7          	jalr	-244(ra) # 8000370c <bread>
    80004808:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000480a:	40000613          	li	a2,1024
    8000480e:	05890593          	addi	a1,s2,88
    80004812:	05850513          	addi	a0,a0,88
    80004816:	ffffc097          	auipc	ra,0xffffc
    8000481a:	530080e7          	jalr	1328(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000481e:	8526                	mv	a0,s1
    80004820:	fffff097          	auipc	ra,0xfffff
    80004824:	fde080e7          	jalr	-34(ra) # 800037fe <bwrite>
    if(recovering == 0)
    80004828:	f80b1ce3          	bnez	s6,800047c0 <install_trans+0x40>
    8000482c:	b769                	j	800047b6 <install_trans+0x36>
}
    8000482e:	70e2                	ld	ra,56(sp)
    80004830:	7442                	ld	s0,48(sp)
    80004832:	74a2                	ld	s1,40(sp)
    80004834:	7902                	ld	s2,32(sp)
    80004836:	69e2                	ld	s3,24(sp)
    80004838:	6a42                	ld	s4,16(sp)
    8000483a:	6aa2                	ld	s5,8(sp)
    8000483c:	6b02                	ld	s6,0(sp)
    8000483e:	6121                	addi	sp,sp,64
    80004840:	8082                	ret
    80004842:	8082                	ret

0000000080004844 <initlog>:
{
    80004844:	7179                	addi	sp,sp,-48
    80004846:	f406                	sd	ra,40(sp)
    80004848:	f022                	sd	s0,32(sp)
    8000484a:	ec26                	sd	s1,24(sp)
    8000484c:	e84a                	sd	s2,16(sp)
    8000484e:	e44e                	sd	s3,8(sp)
    80004850:	1800                	addi	s0,sp,48
    80004852:	892a                	mv	s2,a0
    80004854:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004856:	0001e497          	auipc	s1,0x1e
    8000485a:	d5a48493          	addi	s1,s1,-678 # 800225b0 <log>
    8000485e:	00004597          	auipc	a1,0x4
    80004862:	f7258593          	addi	a1,a1,-142 # 800087d0 <syscalls+0x208>
    80004866:	8526                	mv	a0,s1
    80004868:	ffffc097          	auipc	ra,0xffffc
    8000486c:	2f2080e7          	jalr	754(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    80004870:	0149a583          	lw	a1,20(s3)
    80004874:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004876:	0109a783          	lw	a5,16(s3)
    8000487a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000487c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004880:	854a                	mv	a0,s2
    80004882:	fffff097          	auipc	ra,0xfffff
    80004886:	e8a080e7          	jalr	-374(ra) # 8000370c <bread>
  log.lh.n = lh->n;
    8000488a:	4d3c                	lw	a5,88(a0)
    8000488c:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000488e:	02f05563          	blez	a5,800048b8 <initlog+0x74>
    80004892:	05c50713          	addi	a4,a0,92
    80004896:	0001e697          	auipc	a3,0x1e
    8000489a:	d4a68693          	addi	a3,a3,-694 # 800225e0 <log+0x30>
    8000489e:	37fd                	addiw	a5,a5,-1
    800048a0:	1782                	slli	a5,a5,0x20
    800048a2:	9381                	srli	a5,a5,0x20
    800048a4:	078a                	slli	a5,a5,0x2
    800048a6:	06050613          	addi	a2,a0,96
    800048aa:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800048ac:	4310                	lw	a2,0(a4)
    800048ae:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800048b0:	0711                	addi	a4,a4,4
    800048b2:	0691                	addi	a3,a3,4
    800048b4:	fef71ce3          	bne	a4,a5,800048ac <initlog+0x68>
  brelse(buf);
    800048b8:	fffff097          	auipc	ra,0xfffff
    800048bc:	f84080e7          	jalr	-124(ra) # 8000383c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800048c0:	4505                	li	a0,1
    800048c2:	00000097          	auipc	ra,0x0
    800048c6:	ebe080e7          	jalr	-322(ra) # 80004780 <install_trans>
  log.lh.n = 0;
    800048ca:	0001e797          	auipc	a5,0x1e
    800048ce:	d007a923          	sw	zero,-750(a5) # 800225dc <log+0x2c>
  write_head(); // clear the log
    800048d2:	00000097          	auipc	ra,0x0
    800048d6:	e34080e7          	jalr	-460(ra) # 80004706 <write_head>
}
    800048da:	70a2                	ld	ra,40(sp)
    800048dc:	7402                	ld	s0,32(sp)
    800048de:	64e2                	ld	s1,24(sp)
    800048e0:	6942                	ld	s2,16(sp)
    800048e2:	69a2                	ld	s3,8(sp)
    800048e4:	6145                	addi	sp,sp,48
    800048e6:	8082                	ret

00000000800048e8 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800048e8:	1101                	addi	sp,sp,-32
    800048ea:	ec06                	sd	ra,24(sp)
    800048ec:	e822                	sd	s0,16(sp)
    800048ee:	e426                	sd	s1,8(sp)
    800048f0:	e04a                	sd	s2,0(sp)
    800048f2:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800048f4:	0001e517          	auipc	a0,0x1e
    800048f8:	cbc50513          	addi	a0,a0,-836 # 800225b0 <log>
    800048fc:	ffffc097          	auipc	ra,0xffffc
    80004900:	2ee080e7          	jalr	750(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    80004904:	0001e497          	auipc	s1,0x1e
    80004908:	cac48493          	addi	s1,s1,-852 # 800225b0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000490c:	4979                	li	s2,30
    8000490e:	a039                	j	8000491c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004910:	85a6                	mv	a1,s1
    80004912:	8526                	mv	a0,s1
    80004914:	ffffe097          	auipc	ra,0xffffe
    80004918:	86c080e7          	jalr	-1940(ra) # 80002180 <sleep>
    if(log.committing){
    8000491c:	50dc                	lw	a5,36(s1)
    8000491e:	fbed                	bnez	a5,80004910 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004920:	509c                	lw	a5,32(s1)
    80004922:	0017871b          	addiw	a4,a5,1
    80004926:	0007069b          	sext.w	a3,a4
    8000492a:	0027179b          	slliw	a5,a4,0x2
    8000492e:	9fb9                	addw	a5,a5,a4
    80004930:	0017979b          	slliw	a5,a5,0x1
    80004934:	54d8                	lw	a4,44(s1)
    80004936:	9fb9                	addw	a5,a5,a4
    80004938:	00f95963          	bge	s2,a5,8000494a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000493c:	85a6                	mv	a1,s1
    8000493e:	8526                	mv	a0,s1
    80004940:	ffffe097          	auipc	ra,0xffffe
    80004944:	840080e7          	jalr	-1984(ra) # 80002180 <sleep>
    80004948:	bfd1                	j	8000491c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000494a:	0001e517          	auipc	a0,0x1e
    8000494e:	c6650513          	addi	a0,a0,-922 # 800225b0 <log>
    80004952:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004954:	ffffc097          	auipc	ra,0xffffc
    80004958:	34a080e7          	jalr	842(ra) # 80000c9e <release>
      break;
    }
  }
}
    8000495c:	60e2                	ld	ra,24(sp)
    8000495e:	6442                	ld	s0,16(sp)
    80004960:	64a2                	ld	s1,8(sp)
    80004962:	6902                	ld	s2,0(sp)
    80004964:	6105                	addi	sp,sp,32
    80004966:	8082                	ret

0000000080004968 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004968:	7139                	addi	sp,sp,-64
    8000496a:	fc06                	sd	ra,56(sp)
    8000496c:	f822                	sd	s0,48(sp)
    8000496e:	f426                	sd	s1,40(sp)
    80004970:	f04a                	sd	s2,32(sp)
    80004972:	ec4e                	sd	s3,24(sp)
    80004974:	e852                	sd	s4,16(sp)
    80004976:	e456                	sd	s5,8(sp)
    80004978:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000497a:	0001e497          	auipc	s1,0x1e
    8000497e:	c3648493          	addi	s1,s1,-970 # 800225b0 <log>
    80004982:	8526                	mv	a0,s1
    80004984:	ffffc097          	auipc	ra,0xffffc
    80004988:	266080e7          	jalr	614(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    8000498c:	509c                	lw	a5,32(s1)
    8000498e:	37fd                	addiw	a5,a5,-1
    80004990:	0007891b          	sext.w	s2,a5
    80004994:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004996:	50dc                	lw	a5,36(s1)
    80004998:	efb9                	bnez	a5,800049f6 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000499a:	06091663          	bnez	s2,80004a06 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000499e:	0001e497          	auipc	s1,0x1e
    800049a2:	c1248493          	addi	s1,s1,-1006 # 800225b0 <log>
    800049a6:	4785                	li	a5,1
    800049a8:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800049aa:	8526                	mv	a0,s1
    800049ac:	ffffc097          	auipc	ra,0xffffc
    800049b0:	2f2080e7          	jalr	754(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800049b4:	54dc                	lw	a5,44(s1)
    800049b6:	06f04763          	bgtz	a5,80004a24 <end_op+0xbc>
    acquire(&log.lock);
    800049ba:	0001e497          	auipc	s1,0x1e
    800049be:	bf648493          	addi	s1,s1,-1034 # 800225b0 <log>
    800049c2:	8526                	mv	a0,s1
    800049c4:	ffffc097          	auipc	ra,0xffffc
    800049c8:	226080e7          	jalr	550(ra) # 80000bea <acquire>
    log.committing = 0;
    800049cc:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800049d0:	8526                	mv	a0,s1
    800049d2:	ffffe097          	auipc	ra,0xffffe
    800049d6:	95e080e7          	jalr	-1698(ra) # 80002330 <wakeup>
    release(&log.lock);
    800049da:	8526                	mv	a0,s1
    800049dc:	ffffc097          	auipc	ra,0xffffc
    800049e0:	2c2080e7          	jalr	706(ra) # 80000c9e <release>
}
    800049e4:	70e2                	ld	ra,56(sp)
    800049e6:	7442                	ld	s0,48(sp)
    800049e8:	74a2                	ld	s1,40(sp)
    800049ea:	7902                	ld	s2,32(sp)
    800049ec:	69e2                	ld	s3,24(sp)
    800049ee:	6a42                	ld	s4,16(sp)
    800049f0:	6aa2                	ld	s5,8(sp)
    800049f2:	6121                	addi	sp,sp,64
    800049f4:	8082                	ret
    panic("log.committing");
    800049f6:	00004517          	auipc	a0,0x4
    800049fa:	de250513          	addi	a0,a0,-542 # 800087d8 <syscalls+0x210>
    800049fe:	ffffc097          	auipc	ra,0xffffc
    80004a02:	b46080e7          	jalr	-1210(ra) # 80000544 <panic>
    wakeup(&log);
    80004a06:	0001e497          	auipc	s1,0x1e
    80004a0a:	baa48493          	addi	s1,s1,-1110 # 800225b0 <log>
    80004a0e:	8526                	mv	a0,s1
    80004a10:	ffffe097          	auipc	ra,0xffffe
    80004a14:	920080e7          	jalr	-1760(ra) # 80002330 <wakeup>
  release(&log.lock);
    80004a18:	8526                	mv	a0,s1
    80004a1a:	ffffc097          	auipc	ra,0xffffc
    80004a1e:	284080e7          	jalr	644(ra) # 80000c9e <release>
  if(do_commit){
    80004a22:	b7c9                	j	800049e4 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a24:	0001ea97          	auipc	s5,0x1e
    80004a28:	bbca8a93          	addi	s5,s5,-1092 # 800225e0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004a2c:	0001ea17          	auipc	s4,0x1e
    80004a30:	b84a0a13          	addi	s4,s4,-1148 # 800225b0 <log>
    80004a34:	018a2583          	lw	a1,24(s4)
    80004a38:	012585bb          	addw	a1,a1,s2
    80004a3c:	2585                	addiw	a1,a1,1
    80004a3e:	028a2503          	lw	a0,40(s4)
    80004a42:	fffff097          	auipc	ra,0xfffff
    80004a46:	cca080e7          	jalr	-822(ra) # 8000370c <bread>
    80004a4a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004a4c:	000aa583          	lw	a1,0(s5)
    80004a50:	028a2503          	lw	a0,40(s4)
    80004a54:	fffff097          	auipc	ra,0xfffff
    80004a58:	cb8080e7          	jalr	-840(ra) # 8000370c <bread>
    80004a5c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004a5e:	40000613          	li	a2,1024
    80004a62:	05850593          	addi	a1,a0,88
    80004a66:	05848513          	addi	a0,s1,88
    80004a6a:	ffffc097          	auipc	ra,0xffffc
    80004a6e:	2dc080e7          	jalr	732(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    80004a72:	8526                	mv	a0,s1
    80004a74:	fffff097          	auipc	ra,0xfffff
    80004a78:	d8a080e7          	jalr	-630(ra) # 800037fe <bwrite>
    brelse(from);
    80004a7c:	854e                	mv	a0,s3
    80004a7e:	fffff097          	auipc	ra,0xfffff
    80004a82:	dbe080e7          	jalr	-578(ra) # 8000383c <brelse>
    brelse(to);
    80004a86:	8526                	mv	a0,s1
    80004a88:	fffff097          	auipc	ra,0xfffff
    80004a8c:	db4080e7          	jalr	-588(ra) # 8000383c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a90:	2905                	addiw	s2,s2,1
    80004a92:	0a91                	addi	s5,s5,4
    80004a94:	02ca2783          	lw	a5,44(s4)
    80004a98:	f8f94ee3          	blt	s2,a5,80004a34 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004a9c:	00000097          	auipc	ra,0x0
    80004aa0:	c6a080e7          	jalr	-918(ra) # 80004706 <write_head>
    install_trans(0); // Now install writes to home locations
    80004aa4:	4501                	li	a0,0
    80004aa6:	00000097          	auipc	ra,0x0
    80004aaa:	cda080e7          	jalr	-806(ra) # 80004780 <install_trans>
    log.lh.n = 0;
    80004aae:	0001e797          	auipc	a5,0x1e
    80004ab2:	b207a723          	sw	zero,-1234(a5) # 800225dc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004ab6:	00000097          	auipc	ra,0x0
    80004aba:	c50080e7          	jalr	-944(ra) # 80004706 <write_head>
    80004abe:	bdf5                	j	800049ba <end_op+0x52>

0000000080004ac0 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004ac0:	1101                	addi	sp,sp,-32
    80004ac2:	ec06                	sd	ra,24(sp)
    80004ac4:	e822                	sd	s0,16(sp)
    80004ac6:	e426                	sd	s1,8(sp)
    80004ac8:	e04a                	sd	s2,0(sp)
    80004aca:	1000                	addi	s0,sp,32
    80004acc:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004ace:	0001e917          	auipc	s2,0x1e
    80004ad2:	ae290913          	addi	s2,s2,-1310 # 800225b0 <log>
    80004ad6:	854a                	mv	a0,s2
    80004ad8:	ffffc097          	auipc	ra,0xffffc
    80004adc:	112080e7          	jalr	274(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004ae0:	02c92603          	lw	a2,44(s2)
    80004ae4:	47f5                	li	a5,29
    80004ae6:	06c7c563          	blt	a5,a2,80004b50 <log_write+0x90>
    80004aea:	0001e797          	auipc	a5,0x1e
    80004aee:	ae27a783          	lw	a5,-1310(a5) # 800225cc <log+0x1c>
    80004af2:	37fd                	addiw	a5,a5,-1
    80004af4:	04f65e63          	bge	a2,a5,80004b50 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004af8:	0001e797          	auipc	a5,0x1e
    80004afc:	ad87a783          	lw	a5,-1320(a5) # 800225d0 <log+0x20>
    80004b00:	06f05063          	blez	a5,80004b60 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004b04:	4781                	li	a5,0
    80004b06:	06c05563          	blez	a2,80004b70 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004b0a:	44cc                	lw	a1,12(s1)
    80004b0c:	0001e717          	auipc	a4,0x1e
    80004b10:	ad470713          	addi	a4,a4,-1324 # 800225e0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004b14:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004b16:	4314                	lw	a3,0(a4)
    80004b18:	04b68c63          	beq	a3,a1,80004b70 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004b1c:	2785                	addiw	a5,a5,1
    80004b1e:	0711                	addi	a4,a4,4
    80004b20:	fef61be3          	bne	a2,a5,80004b16 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004b24:	0621                	addi	a2,a2,8
    80004b26:	060a                	slli	a2,a2,0x2
    80004b28:	0001e797          	auipc	a5,0x1e
    80004b2c:	a8878793          	addi	a5,a5,-1400 # 800225b0 <log>
    80004b30:	963e                	add	a2,a2,a5
    80004b32:	44dc                	lw	a5,12(s1)
    80004b34:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004b36:	8526                	mv	a0,s1
    80004b38:	fffff097          	auipc	ra,0xfffff
    80004b3c:	da2080e7          	jalr	-606(ra) # 800038da <bpin>
    log.lh.n++;
    80004b40:	0001e717          	auipc	a4,0x1e
    80004b44:	a7070713          	addi	a4,a4,-1424 # 800225b0 <log>
    80004b48:	575c                	lw	a5,44(a4)
    80004b4a:	2785                	addiw	a5,a5,1
    80004b4c:	d75c                	sw	a5,44(a4)
    80004b4e:	a835                	j	80004b8a <log_write+0xca>
    panic("too big a transaction");
    80004b50:	00004517          	auipc	a0,0x4
    80004b54:	c9850513          	addi	a0,a0,-872 # 800087e8 <syscalls+0x220>
    80004b58:	ffffc097          	auipc	ra,0xffffc
    80004b5c:	9ec080e7          	jalr	-1556(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    80004b60:	00004517          	auipc	a0,0x4
    80004b64:	ca050513          	addi	a0,a0,-864 # 80008800 <syscalls+0x238>
    80004b68:	ffffc097          	auipc	ra,0xffffc
    80004b6c:	9dc080e7          	jalr	-1572(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    80004b70:	00878713          	addi	a4,a5,8
    80004b74:	00271693          	slli	a3,a4,0x2
    80004b78:	0001e717          	auipc	a4,0x1e
    80004b7c:	a3870713          	addi	a4,a4,-1480 # 800225b0 <log>
    80004b80:	9736                	add	a4,a4,a3
    80004b82:	44d4                	lw	a3,12(s1)
    80004b84:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004b86:	faf608e3          	beq	a2,a5,80004b36 <log_write+0x76>
  }
  release(&log.lock);
    80004b8a:	0001e517          	auipc	a0,0x1e
    80004b8e:	a2650513          	addi	a0,a0,-1498 # 800225b0 <log>
    80004b92:	ffffc097          	auipc	ra,0xffffc
    80004b96:	10c080e7          	jalr	268(ra) # 80000c9e <release>
}
    80004b9a:	60e2                	ld	ra,24(sp)
    80004b9c:	6442                	ld	s0,16(sp)
    80004b9e:	64a2                	ld	s1,8(sp)
    80004ba0:	6902                	ld	s2,0(sp)
    80004ba2:	6105                	addi	sp,sp,32
    80004ba4:	8082                	ret

0000000080004ba6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004ba6:	1101                	addi	sp,sp,-32
    80004ba8:	ec06                	sd	ra,24(sp)
    80004baa:	e822                	sd	s0,16(sp)
    80004bac:	e426                	sd	s1,8(sp)
    80004bae:	e04a                	sd	s2,0(sp)
    80004bb0:	1000                	addi	s0,sp,32
    80004bb2:	84aa                	mv	s1,a0
    80004bb4:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004bb6:	00004597          	auipc	a1,0x4
    80004bba:	c6a58593          	addi	a1,a1,-918 # 80008820 <syscalls+0x258>
    80004bbe:	0521                	addi	a0,a0,8
    80004bc0:	ffffc097          	auipc	ra,0xffffc
    80004bc4:	f9a080e7          	jalr	-102(ra) # 80000b5a <initlock>
  lk->name = name;
    80004bc8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004bcc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004bd0:	0204a423          	sw	zero,40(s1)
}
    80004bd4:	60e2                	ld	ra,24(sp)
    80004bd6:	6442                	ld	s0,16(sp)
    80004bd8:	64a2                	ld	s1,8(sp)
    80004bda:	6902                	ld	s2,0(sp)
    80004bdc:	6105                	addi	sp,sp,32
    80004bde:	8082                	ret

0000000080004be0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004be0:	1101                	addi	sp,sp,-32
    80004be2:	ec06                	sd	ra,24(sp)
    80004be4:	e822                	sd	s0,16(sp)
    80004be6:	e426                	sd	s1,8(sp)
    80004be8:	e04a                	sd	s2,0(sp)
    80004bea:	1000                	addi	s0,sp,32
    80004bec:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004bee:	00850913          	addi	s2,a0,8
    80004bf2:	854a                	mv	a0,s2
    80004bf4:	ffffc097          	auipc	ra,0xffffc
    80004bf8:	ff6080e7          	jalr	-10(ra) # 80000bea <acquire>
  while (lk->locked) {
    80004bfc:	409c                	lw	a5,0(s1)
    80004bfe:	cb89                	beqz	a5,80004c10 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004c00:	85ca                	mv	a1,s2
    80004c02:	8526                	mv	a0,s1
    80004c04:	ffffd097          	auipc	ra,0xffffd
    80004c08:	57c080e7          	jalr	1404(ra) # 80002180 <sleep>
  while (lk->locked) {
    80004c0c:	409c                	lw	a5,0(s1)
    80004c0e:	fbed                	bnez	a5,80004c00 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004c10:	4785                	li	a5,1
    80004c12:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004c14:	ffffd097          	auipc	ra,0xffffd
    80004c18:	db2080e7          	jalr	-590(ra) # 800019c6 <myproc>
    80004c1c:	591c                	lw	a5,48(a0)
    80004c1e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004c20:	854a                	mv	a0,s2
    80004c22:	ffffc097          	auipc	ra,0xffffc
    80004c26:	07c080e7          	jalr	124(ra) # 80000c9e <release>
}
    80004c2a:	60e2                	ld	ra,24(sp)
    80004c2c:	6442                	ld	s0,16(sp)
    80004c2e:	64a2                	ld	s1,8(sp)
    80004c30:	6902                	ld	s2,0(sp)
    80004c32:	6105                	addi	sp,sp,32
    80004c34:	8082                	ret

0000000080004c36 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004c36:	1101                	addi	sp,sp,-32
    80004c38:	ec06                	sd	ra,24(sp)
    80004c3a:	e822                	sd	s0,16(sp)
    80004c3c:	e426                	sd	s1,8(sp)
    80004c3e:	e04a                	sd	s2,0(sp)
    80004c40:	1000                	addi	s0,sp,32
    80004c42:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004c44:	00850913          	addi	s2,a0,8
    80004c48:	854a                	mv	a0,s2
    80004c4a:	ffffc097          	auipc	ra,0xffffc
    80004c4e:	fa0080e7          	jalr	-96(ra) # 80000bea <acquire>
  lk->locked = 0;
    80004c52:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004c56:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004c5a:	8526                	mv	a0,s1
    80004c5c:	ffffd097          	auipc	ra,0xffffd
    80004c60:	6d4080e7          	jalr	1748(ra) # 80002330 <wakeup>
  release(&lk->lk);
    80004c64:	854a                	mv	a0,s2
    80004c66:	ffffc097          	auipc	ra,0xffffc
    80004c6a:	038080e7          	jalr	56(ra) # 80000c9e <release>
}
    80004c6e:	60e2                	ld	ra,24(sp)
    80004c70:	6442                	ld	s0,16(sp)
    80004c72:	64a2                	ld	s1,8(sp)
    80004c74:	6902                	ld	s2,0(sp)
    80004c76:	6105                	addi	sp,sp,32
    80004c78:	8082                	ret

0000000080004c7a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004c7a:	7179                	addi	sp,sp,-48
    80004c7c:	f406                	sd	ra,40(sp)
    80004c7e:	f022                	sd	s0,32(sp)
    80004c80:	ec26                	sd	s1,24(sp)
    80004c82:	e84a                	sd	s2,16(sp)
    80004c84:	e44e                	sd	s3,8(sp)
    80004c86:	1800                	addi	s0,sp,48
    80004c88:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004c8a:	00850913          	addi	s2,a0,8
    80004c8e:	854a                	mv	a0,s2
    80004c90:	ffffc097          	auipc	ra,0xffffc
    80004c94:	f5a080e7          	jalr	-166(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c98:	409c                	lw	a5,0(s1)
    80004c9a:	ef99                	bnez	a5,80004cb8 <holdingsleep+0x3e>
    80004c9c:	4481                	li	s1,0
  release(&lk->lk);
    80004c9e:	854a                	mv	a0,s2
    80004ca0:	ffffc097          	auipc	ra,0xffffc
    80004ca4:	ffe080e7          	jalr	-2(ra) # 80000c9e <release>
  return r;
}
    80004ca8:	8526                	mv	a0,s1
    80004caa:	70a2                	ld	ra,40(sp)
    80004cac:	7402                	ld	s0,32(sp)
    80004cae:	64e2                	ld	s1,24(sp)
    80004cb0:	6942                	ld	s2,16(sp)
    80004cb2:	69a2                	ld	s3,8(sp)
    80004cb4:	6145                	addi	sp,sp,48
    80004cb6:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004cb8:	0284a983          	lw	s3,40(s1)
    80004cbc:	ffffd097          	auipc	ra,0xffffd
    80004cc0:	d0a080e7          	jalr	-758(ra) # 800019c6 <myproc>
    80004cc4:	5904                	lw	s1,48(a0)
    80004cc6:	413484b3          	sub	s1,s1,s3
    80004cca:	0014b493          	seqz	s1,s1
    80004cce:	bfc1                	j	80004c9e <holdingsleep+0x24>

0000000080004cd0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004cd0:	1141                	addi	sp,sp,-16
    80004cd2:	e406                	sd	ra,8(sp)
    80004cd4:	e022                	sd	s0,0(sp)
    80004cd6:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004cd8:	00004597          	auipc	a1,0x4
    80004cdc:	b5858593          	addi	a1,a1,-1192 # 80008830 <syscalls+0x268>
    80004ce0:	0001e517          	auipc	a0,0x1e
    80004ce4:	a1850513          	addi	a0,a0,-1512 # 800226f8 <ftable>
    80004ce8:	ffffc097          	auipc	ra,0xffffc
    80004cec:	e72080e7          	jalr	-398(ra) # 80000b5a <initlock>
}
    80004cf0:	60a2                	ld	ra,8(sp)
    80004cf2:	6402                	ld	s0,0(sp)
    80004cf4:	0141                	addi	sp,sp,16
    80004cf6:	8082                	ret

0000000080004cf8 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004cf8:	1101                	addi	sp,sp,-32
    80004cfa:	ec06                	sd	ra,24(sp)
    80004cfc:	e822                	sd	s0,16(sp)
    80004cfe:	e426                	sd	s1,8(sp)
    80004d00:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004d02:	0001e517          	auipc	a0,0x1e
    80004d06:	9f650513          	addi	a0,a0,-1546 # 800226f8 <ftable>
    80004d0a:	ffffc097          	auipc	ra,0xffffc
    80004d0e:	ee0080e7          	jalr	-288(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004d12:	0001e497          	auipc	s1,0x1e
    80004d16:	9fe48493          	addi	s1,s1,-1538 # 80022710 <ftable+0x18>
    80004d1a:	0001f717          	auipc	a4,0x1f
    80004d1e:	99670713          	addi	a4,a4,-1642 # 800236b0 <disk>
    if(f->ref == 0){
    80004d22:	40dc                	lw	a5,4(s1)
    80004d24:	cf99                	beqz	a5,80004d42 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004d26:	02848493          	addi	s1,s1,40
    80004d2a:	fee49ce3          	bne	s1,a4,80004d22 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004d2e:	0001e517          	auipc	a0,0x1e
    80004d32:	9ca50513          	addi	a0,a0,-1590 # 800226f8 <ftable>
    80004d36:	ffffc097          	auipc	ra,0xffffc
    80004d3a:	f68080e7          	jalr	-152(ra) # 80000c9e <release>
  return 0;
    80004d3e:	4481                	li	s1,0
    80004d40:	a819                	j	80004d56 <filealloc+0x5e>
      f->ref = 1;
    80004d42:	4785                	li	a5,1
    80004d44:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004d46:	0001e517          	auipc	a0,0x1e
    80004d4a:	9b250513          	addi	a0,a0,-1614 # 800226f8 <ftable>
    80004d4e:	ffffc097          	auipc	ra,0xffffc
    80004d52:	f50080e7          	jalr	-176(ra) # 80000c9e <release>
}
    80004d56:	8526                	mv	a0,s1
    80004d58:	60e2                	ld	ra,24(sp)
    80004d5a:	6442                	ld	s0,16(sp)
    80004d5c:	64a2                	ld	s1,8(sp)
    80004d5e:	6105                	addi	sp,sp,32
    80004d60:	8082                	ret

0000000080004d62 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004d62:	1101                	addi	sp,sp,-32
    80004d64:	ec06                	sd	ra,24(sp)
    80004d66:	e822                	sd	s0,16(sp)
    80004d68:	e426                	sd	s1,8(sp)
    80004d6a:	1000                	addi	s0,sp,32
    80004d6c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004d6e:	0001e517          	auipc	a0,0x1e
    80004d72:	98a50513          	addi	a0,a0,-1654 # 800226f8 <ftable>
    80004d76:	ffffc097          	auipc	ra,0xffffc
    80004d7a:	e74080e7          	jalr	-396(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004d7e:	40dc                	lw	a5,4(s1)
    80004d80:	02f05263          	blez	a5,80004da4 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004d84:	2785                	addiw	a5,a5,1
    80004d86:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004d88:	0001e517          	auipc	a0,0x1e
    80004d8c:	97050513          	addi	a0,a0,-1680 # 800226f8 <ftable>
    80004d90:	ffffc097          	auipc	ra,0xffffc
    80004d94:	f0e080e7          	jalr	-242(ra) # 80000c9e <release>
  return f;
}
    80004d98:	8526                	mv	a0,s1
    80004d9a:	60e2                	ld	ra,24(sp)
    80004d9c:	6442                	ld	s0,16(sp)
    80004d9e:	64a2                	ld	s1,8(sp)
    80004da0:	6105                	addi	sp,sp,32
    80004da2:	8082                	ret
    panic("filedup");
    80004da4:	00004517          	auipc	a0,0x4
    80004da8:	a9450513          	addi	a0,a0,-1388 # 80008838 <syscalls+0x270>
    80004dac:	ffffb097          	auipc	ra,0xffffb
    80004db0:	798080e7          	jalr	1944(ra) # 80000544 <panic>

0000000080004db4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004db4:	7139                	addi	sp,sp,-64
    80004db6:	fc06                	sd	ra,56(sp)
    80004db8:	f822                	sd	s0,48(sp)
    80004dba:	f426                	sd	s1,40(sp)
    80004dbc:	f04a                	sd	s2,32(sp)
    80004dbe:	ec4e                	sd	s3,24(sp)
    80004dc0:	e852                	sd	s4,16(sp)
    80004dc2:	e456                	sd	s5,8(sp)
    80004dc4:	0080                	addi	s0,sp,64
    80004dc6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004dc8:	0001e517          	auipc	a0,0x1e
    80004dcc:	93050513          	addi	a0,a0,-1744 # 800226f8 <ftable>
    80004dd0:	ffffc097          	auipc	ra,0xffffc
    80004dd4:	e1a080e7          	jalr	-486(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004dd8:	40dc                	lw	a5,4(s1)
    80004dda:	06f05163          	blez	a5,80004e3c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004dde:	37fd                	addiw	a5,a5,-1
    80004de0:	0007871b          	sext.w	a4,a5
    80004de4:	c0dc                	sw	a5,4(s1)
    80004de6:	06e04363          	bgtz	a4,80004e4c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004dea:	0004a903          	lw	s2,0(s1)
    80004dee:	0094ca83          	lbu	s5,9(s1)
    80004df2:	0104ba03          	ld	s4,16(s1)
    80004df6:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004dfa:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004dfe:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004e02:	0001e517          	auipc	a0,0x1e
    80004e06:	8f650513          	addi	a0,a0,-1802 # 800226f8 <ftable>
    80004e0a:	ffffc097          	auipc	ra,0xffffc
    80004e0e:	e94080e7          	jalr	-364(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    80004e12:	4785                	li	a5,1
    80004e14:	04f90d63          	beq	s2,a5,80004e6e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004e18:	3979                	addiw	s2,s2,-2
    80004e1a:	4785                	li	a5,1
    80004e1c:	0527e063          	bltu	a5,s2,80004e5c <fileclose+0xa8>
    begin_op();
    80004e20:	00000097          	auipc	ra,0x0
    80004e24:	ac8080e7          	jalr	-1336(ra) # 800048e8 <begin_op>
    iput(ff.ip);
    80004e28:	854e                	mv	a0,s3
    80004e2a:	fffff097          	auipc	ra,0xfffff
    80004e2e:	2b6080e7          	jalr	694(ra) # 800040e0 <iput>
    end_op();
    80004e32:	00000097          	auipc	ra,0x0
    80004e36:	b36080e7          	jalr	-1226(ra) # 80004968 <end_op>
    80004e3a:	a00d                	j	80004e5c <fileclose+0xa8>
    panic("fileclose");
    80004e3c:	00004517          	auipc	a0,0x4
    80004e40:	a0450513          	addi	a0,a0,-1532 # 80008840 <syscalls+0x278>
    80004e44:	ffffb097          	auipc	ra,0xffffb
    80004e48:	700080e7          	jalr	1792(ra) # 80000544 <panic>
    release(&ftable.lock);
    80004e4c:	0001e517          	auipc	a0,0x1e
    80004e50:	8ac50513          	addi	a0,a0,-1876 # 800226f8 <ftable>
    80004e54:	ffffc097          	auipc	ra,0xffffc
    80004e58:	e4a080e7          	jalr	-438(ra) # 80000c9e <release>
  }
}
    80004e5c:	70e2                	ld	ra,56(sp)
    80004e5e:	7442                	ld	s0,48(sp)
    80004e60:	74a2                	ld	s1,40(sp)
    80004e62:	7902                	ld	s2,32(sp)
    80004e64:	69e2                	ld	s3,24(sp)
    80004e66:	6a42                	ld	s4,16(sp)
    80004e68:	6aa2                	ld	s5,8(sp)
    80004e6a:	6121                	addi	sp,sp,64
    80004e6c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004e6e:	85d6                	mv	a1,s5
    80004e70:	8552                	mv	a0,s4
    80004e72:	00000097          	auipc	ra,0x0
    80004e76:	34c080e7          	jalr	844(ra) # 800051be <pipeclose>
    80004e7a:	b7cd                	j	80004e5c <fileclose+0xa8>

0000000080004e7c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004e7c:	715d                	addi	sp,sp,-80
    80004e7e:	e486                	sd	ra,72(sp)
    80004e80:	e0a2                	sd	s0,64(sp)
    80004e82:	fc26                	sd	s1,56(sp)
    80004e84:	f84a                	sd	s2,48(sp)
    80004e86:	f44e                	sd	s3,40(sp)
    80004e88:	0880                	addi	s0,sp,80
    80004e8a:	84aa                	mv	s1,a0
    80004e8c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004e8e:	ffffd097          	auipc	ra,0xffffd
    80004e92:	b38080e7          	jalr	-1224(ra) # 800019c6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004e96:	409c                	lw	a5,0(s1)
    80004e98:	37f9                	addiw	a5,a5,-2
    80004e9a:	4705                	li	a4,1
    80004e9c:	04f76763          	bltu	a4,a5,80004eea <filestat+0x6e>
    80004ea0:	892a                	mv	s2,a0
    ilock(f->ip);
    80004ea2:	6c88                	ld	a0,24(s1)
    80004ea4:	fffff097          	auipc	ra,0xfffff
    80004ea8:	082080e7          	jalr	130(ra) # 80003f26 <ilock>
    stati(f->ip, &st);
    80004eac:	fb840593          	addi	a1,s0,-72
    80004eb0:	6c88                	ld	a0,24(s1)
    80004eb2:	fffff097          	auipc	ra,0xfffff
    80004eb6:	2fe080e7          	jalr	766(ra) # 800041b0 <stati>
    iunlock(f->ip);
    80004eba:	6c88                	ld	a0,24(s1)
    80004ebc:	fffff097          	auipc	ra,0xfffff
    80004ec0:	12c080e7          	jalr	300(ra) # 80003fe8 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004ec4:	46e1                	li	a3,24
    80004ec6:	fb840613          	addi	a2,s0,-72
    80004eca:	85ce                	mv	a1,s3
    80004ecc:	05093503          	ld	a0,80(s2)
    80004ed0:	ffffc097          	auipc	ra,0xffffc
    80004ed4:	7b4080e7          	jalr	1972(ra) # 80001684 <copyout>
    80004ed8:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004edc:	60a6                	ld	ra,72(sp)
    80004ede:	6406                	ld	s0,64(sp)
    80004ee0:	74e2                	ld	s1,56(sp)
    80004ee2:	7942                	ld	s2,48(sp)
    80004ee4:	79a2                	ld	s3,40(sp)
    80004ee6:	6161                	addi	sp,sp,80
    80004ee8:	8082                	ret
  return -1;
    80004eea:	557d                	li	a0,-1
    80004eec:	bfc5                	j	80004edc <filestat+0x60>

0000000080004eee <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004eee:	7179                	addi	sp,sp,-48
    80004ef0:	f406                	sd	ra,40(sp)
    80004ef2:	f022                	sd	s0,32(sp)
    80004ef4:	ec26                	sd	s1,24(sp)
    80004ef6:	e84a                	sd	s2,16(sp)
    80004ef8:	e44e                	sd	s3,8(sp)
    80004efa:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004efc:	00854783          	lbu	a5,8(a0)
    80004f00:	c3d5                	beqz	a5,80004fa4 <fileread+0xb6>
    80004f02:	84aa                	mv	s1,a0
    80004f04:	89ae                	mv	s3,a1
    80004f06:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004f08:	411c                	lw	a5,0(a0)
    80004f0a:	4705                	li	a4,1
    80004f0c:	04e78963          	beq	a5,a4,80004f5e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004f10:	470d                	li	a4,3
    80004f12:	04e78d63          	beq	a5,a4,80004f6c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004f16:	4709                	li	a4,2
    80004f18:	06e79e63          	bne	a5,a4,80004f94 <fileread+0xa6>
    ilock(f->ip);
    80004f1c:	6d08                	ld	a0,24(a0)
    80004f1e:	fffff097          	auipc	ra,0xfffff
    80004f22:	008080e7          	jalr	8(ra) # 80003f26 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004f26:	874a                	mv	a4,s2
    80004f28:	5094                	lw	a3,32(s1)
    80004f2a:	864e                	mv	a2,s3
    80004f2c:	4585                	li	a1,1
    80004f2e:	6c88                	ld	a0,24(s1)
    80004f30:	fffff097          	auipc	ra,0xfffff
    80004f34:	2aa080e7          	jalr	682(ra) # 800041da <readi>
    80004f38:	892a                	mv	s2,a0
    80004f3a:	00a05563          	blez	a0,80004f44 <fileread+0x56>
      f->off += r;
    80004f3e:	509c                	lw	a5,32(s1)
    80004f40:	9fa9                	addw	a5,a5,a0
    80004f42:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004f44:	6c88                	ld	a0,24(s1)
    80004f46:	fffff097          	auipc	ra,0xfffff
    80004f4a:	0a2080e7          	jalr	162(ra) # 80003fe8 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004f4e:	854a                	mv	a0,s2
    80004f50:	70a2                	ld	ra,40(sp)
    80004f52:	7402                	ld	s0,32(sp)
    80004f54:	64e2                	ld	s1,24(sp)
    80004f56:	6942                	ld	s2,16(sp)
    80004f58:	69a2                	ld	s3,8(sp)
    80004f5a:	6145                	addi	sp,sp,48
    80004f5c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004f5e:	6908                	ld	a0,16(a0)
    80004f60:	00000097          	auipc	ra,0x0
    80004f64:	3ce080e7          	jalr	974(ra) # 8000532e <piperead>
    80004f68:	892a                	mv	s2,a0
    80004f6a:	b7d5                	j	80004f4e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004f6c:	02451783          	lh	a5,36(a0)
    80004f70:	03079693          	slli	a3,a5,0x30
    80004f74:	92c1                	srli	a3,a3,0x30
    80004f76:	4725                	li	a4,9
    80004f78:	02d76863          	bltu	a4,a3,80004fa8 <fileread+0xba>
    80004f7c:	0792                	slli	a5,a5,0x4
    80004f7e:	0001d717          	auipc	a4,0x1d
    80004f82:	6da70713          	addi	a4,a4,1754 # 80022658 <devsw>
    80004f86:	97ba                	add	a5,a5,a4
    80004f88:	639c                	ld	a5,0(a5)
    80004f8a:	c38d                	beqz	a5,80004fac <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004f8c:	4505                	li	a0,1
    80004f8e:	9782                	jalr	a5
    80004f90:	892a                	mv	s2,a0
    80004f92:	bf75                	j	80004f4e <fileread+0x60>
    panic("fileread");
    80004f94:	00004517          	auipc	a0,0x4
    80004f98:	8bc50513          	addi	a0,a0,-1860 # 80008850 <syscalls+0x288>
    80004f9c:	ffffb097          	auipc	ra,0xffffb
    80004fa0:	5a8080e7          	jalr	1448(ra) # 80000544 <panic>
    return -1;
    80004fa4:	597d                	li	s2,-1
    80004fa6:	b765                	j	80004f4e <fileread+0x60>
      return -1;
    80004fa8:	597d                	li	s2,-1
    80004faa:	b755                	j	80004f4e <fileread+0x60>
    80004fac:	597d                	li	s2,-1
    80004fae:	b745                	j	80004f4e <fileread+0x60>

0000000080004fb0 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004fb0:	715d                	addi	sp,sp,-80
    80004fb2:	e486                	sd	ra,72(sp)
    80004fb4:	e0a2                	sd	s0,64(sp)
    80004fb6:	fc26                	sd	s1,56(sp)
    80004fb8:	f84a                	sd	s2,48(sp)
    80004fba:	f44e                	sd	s3,40(sp)
    80004fbc:	f052                	sd	s4,32(sp)
    80004fbe:	ec56                	sd	s5,24(sp)
    80004fc0:	e85a                	sd	s6,16(sp)
    80004fc2:	e45e                	sd	s7,8(sp)
    80004fc4:	e062                	sd	s8,0(sp)
    80004fc6:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004fc8:	00954783          	lbu	a5,9(a0)
    80004fcc:	10078663          	beqz	a5,800050d8 <filewrite+0x128>
    80004fd0:	892a                	mv	s2,a0
    80004fd2:	8aae                	mv	s5,a1
    80004fd4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004fd6:	411c                	lw	a5,0(a0)
    80004fd8:	4705                	li	a4,1
    80004fda:	02e78263          	beq	a5,a4,80004ffe <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004fde:	470d                	li	a4,3
    80004fe0:	02e78663          	beq	a5,a4,8000500c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004fe4:	4709                	li	a4,2
    80004fe6:	0ee79163          	bne	a5,a4,800050c8 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004fea:	0ac05d63          	blez	a2,800050a4 <filewrite+0xf4>
    int i = 0;
    80004fee:	4981                	li	s3,0
    80004ff0:	6b05                	lui	s6,0x1
    80004ff2:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004ff6:	6b85                	lui	s7,0x1
    80004ff8:	c00b8b9b          	addiw	s7,s7,-1024
    80004ffc:	a861                	j	80005094 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004ffe:	6908                	ld	a0,16(a0)
    80005000:	00000097          	auipc	ra,0x0
    80005004:	22e080e7          	jalr	558(ra) # 8000522e <pipewrite>
    80005008:	8a2a                	mv	s4,a0
    8000500a:	a045                	j	800050aa <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000500c:	02451783          	lh	a5,36(a0)
    80005010:	03079693          	slli	a3,a5,0x30
    80005014:	92c1                	srli	a3,a3,0x30
    80005016:	4725                	li	a4,9
    80005018:	0cd76263          	bltu	a4,a3,800050dc <filewrite+0x12c>
    8000501c:	0792                	slli	a5,a5,0x4
    8000501e:	0001d717          	auipc	a4,0x1d
    80005022:	63a70713          	addi	a4,a4,1594 # 80022658 <devsw>
    80005026:	97ba                	add	a5,a5,a4
    80005028:	679c                	ld	a5,8(a5)
    8000502a:	cbdd                	beqz	a5,800050e0 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000502c:	4505                	li	a0,1
    8000502e:	9782                	jalr	a5
    80005030:	8a2a                	mv	s4,a0
    80005032:	a8a5                	j	800050aa <filewrite+0xfa>
    80005034:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005038:	00000097          	auipc	ra,0x0
    8000503c:	8b0080e7          	jalr	-1872(ra) # 800048e8 <begin_op>
      ilock(f->ip);
    80005040:	01893503          	ld	a0,24(s2)
    80005044:	fffff097          	auipc	ra,0xfffff
    80005048:	ee2080e7          	jalr	-286(ra) # 80003f26 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000504c:	8762                	mv	a4,s8
    8000504e:	02092683          	lw	a3,32(s2)
    80005052:	01598633          	add	a2,s3,s5
    80005056:	4585                	li	a1,1
    80005058:	01893503          	ld	a0,24(s2)
    8000505c:	fffff097          	auipc	ra,0xfffff
    80005060:	276080e7          	jalr	630(ra) # 800042d2 <writei>
    80005064:	84aa                	mv	s1,a0
    80005066:	00a05763          	blez	a0,80005074 <filewrite+0xc4>
        f->off += r;
    8000506a:	02092783          	lw	a5,32(s2)
    8000506e:	9fa9                	addw	a5,a5,a0
    80005070:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005074:	01893503          	ld	a0,24(s2)
    80005078:	fffff097          	auipc	ra,0xfffff
    8000507c:	f70080e7          	jalr	-144(ra) # 80003fe8 <iunlock>
      end_op();
    80005080:	00000097          	auipc	ra,0x0
    80005084:	8e8080e7          	jalr	-1816(ra) # 80004968 <end_op>

      if(r != n1){
    80005088:	009c1f63          	bne	s8,s1,800050a6 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000508c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005090:	0149db63          	bge	s3,s4,800050a6 <filewrite+0xf6>
      int n1 = n - i;
    80005094:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005098:	84be                	mv	s1,a5
    8000509a:	2781                	sext.w	a5,a5
    8000509c:	f8fb5ce3          	bge	s6,a5,80005034 <filewrite+0x84>
    800050a0:	84de                	mv	s1,s7
    800050a2:	bf49                	j	80005034 <filewrite+0x84>
    int i = 0;
    800050a4:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800050a6:	013a1f63          	bne	s4,s3,800050c4 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800050aa:	8552                	mv	a0,s4
    800050ac:	60a6                	ld	ra,72(sp)
    800050ae:	6406                	ld	s0,64(sp)
    800050b0:	74e2                	ld	s1,56(sp)
    800050b2:	7942                	ld	s2,48(sp)
    800050b4:	79a2                	ld	s3,40(sp)
    800050b6:	7a02                	ld	s4,32(sp)
    800050b8:	6ae2                	ld	s5,24(sp)
    800050ba:	6b42                	ld	s6,16(sp)
    800050bc:	6ba2                	ld	s7,8(sp)
    800050be:	6c02                	ld	s8,0(sp)
    800050c0:	6161                	addi	sp,sp,80
    800050c2:	8082                	ret
    ret = (i == n ? n : -1);
    800050c4:	5a7d                	li	s4,-1
    800050c6:	b7d5                	j	800050aa <filewrite+0xfa>
    panic("filewrite");
    800050c8:	00003517          	auipc	a0,0x3
    800050cc:	79850513          	addi	a0,a0,1944 # 80008860 <syscalls+0x298>
    800050d0:	ffffb097          	auipc	ra,0xffffb
    800050d4:	474080e7          	jalr	1140(ra) # 80000544 <panic>
    return -1;
    800050d8:	5a7d                	li	s4,-1
    800050da:	bfc1                	j	800050aa <filewrite+0xfa>
      return -1;
    800050dc:	5a7d                	li	s4,-1
    800050de:	b7f1                	j	800050aa <filewrite+0xfa>
    800050e0:	5a7d                	li	s4,-1
    800050e2:	b7e1                	j	800050aa <filewrite+0xfa>

00000000800050e4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800050e4:	7179                	addi	sp,sp,-48
    800050e6:	f406                	sd	ra,40(sp)
    800050e8:	f022                	sd	s0,32(sp)
    800050ea:	ec26                	sd	s1,24(sp)
    800050ec:	e84a                	sd	s2,16(sp)
    800050ee:	e44e                	sd	s3,8(sp)
    800050f0:	e052                	sd	s4,0(sp)
    800050f2:	1800                	addi	s0,sp,48
    800050f4:	84aa                	mv	s1,a0
    800050f6:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800050f8:	0005b023          	sd	zero,0(a1)
    800050fc:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005100:	00000097          	auipc	ra,0x0
    80005104:	bf8080e7          	jalr	-1032(ra) # 80004cf8 <filealloc>
    80005108:	e088                	sd	a0,0(s1)
    8000510a:	c551                	beqz	a0,80005196 <pipealloc+0xb2>
    8000510c:	00000097          	auipc	ra,0x0
    80005110:	bec080e7          	jalr	-1044(ra) # 80004cf8 <filealloc>
    80005114:	00aa3023          	sd	a0,0(s4)
    80005118:	c92d                	beqz	a0,8000518a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000511a:	ffffc097          	auipc	ra,0xffffc
    8000511e:	9e0080e7          	jalr	-1568(ra) # 80000afa <kalloc>
    80005122:	892a                	mv	s2,a0
    80005124:	c125                	beqz	a0,80005184 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005126:	4985                	li	s3,1
    80005128:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000512c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005130:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005134:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005138:	00003597          	auipc	a1,0x3
    8000513c:	39858593          	addi	a1,a1,920 # 800084d0 <states.1780+0x208>
    80005140:	ffffc097          	auipc	ra,0xffffc
    80005144:	a1a080e7          	jalr	-1510(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    80005148:	609c                	ld	a5,0(s1)
    8000514a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000514e:	609c                	ld	a5,0(s1)
    80005150:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005154:	609c                	ld	a5,0(s1)
    80005156:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000515a:	609c                	ld	a5,0(s1)
    8000515c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005160:	000a3783          	ld	a5,0(s4)
    80005164:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005168:	000a3783          	ld	a5,0(s4)
    8000516c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005170:	000a3783          	ld	a5,0(s4)
    80005174:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005178:	000a3783          	ld	a5,0(s4)
    8000517c:	0127b823          	sd	s2,16(a5)
  return 0;
    80005180:	4501                	li	a0,0
    80005182:	a025                	j	800051aa <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005184:	6088                	ld	a0,0(s1)
    80005186:	e501                	bnez	a0,8000518e <pipealloc+0xaa>
    80005188:	a039                	j	80005196 <pipealloc+0xb2>
    8000518a:	6088                	ld	a0,0(s1)
    8000518c:	c51d                	beqz	a0,800051ba <pipealloc+0xd6>
    fileclose(*f0);
    8000518e:	00000097          	auipc	ra,0x0
    80005192:	c26080e7          	jalr	-986(ra) # 80004db4 <fileclose>
  if(*f1)
    80005196:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000519a:	557d                	li	a0,-1
  if(*f1)
    8000519c:	c799                	beqz	a5,800051aa <pipealloc+0xc6>
    fileclose(*f1);
    8000519e:	853e                	mv	a0,a5
    800051a0:	00000097          	auipc	ra,0x0
    800051a4:	c14080e7          	jalr	-1004(ra) # 80004db4 <fileclose>
  return -1;
    800051a8:	557d                	li	a0,-1
}
    800051aa:	70a2                	ld	ra,40(sp)
    800051ac:	7402                	ld	s0,32(sp)
    800051ae:	64e2                	ld	s1,24(sp)
    800051b0:	6942                	ld	s2,16(sp)
    800051b2:	69a2                	ld	s3,8(sp)
    800051b4:	6a02                	ld	s4,0(sp)
    800051b6:	6145                	addi	sp,sp,48
    800051b8:	8082                	ret
  return -1;
    800051ba:	557d                	li	a0,-1
    800051bc:	b7fd                	j	800051aa <pipealloc+0xc6>

00000000800051be <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800051be:	1101                	addi	sp,sp,-32
    800051c0:	ec06                	sd	ra,24(sp)
    800051c2:	e822                	sd	s0,16(sp)
    800051c4:	e426                	sd	s1,8(sp)
    800051c6:	e04a                	sd	s2,0(sp)
    800051c8:	1000                	addi	s0,sp,32
    800051ca:	84aa                	mv	s1,a0
    800051cc:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800051ce:	ffffc097          	auipc	ra,0xffffc
    800051d2:	a1c080e7          	jalr	-1508(ra) # 80000bea <acquire>
  if(writable){
    800051d6:	02090d63          	beqz	s2,80005210 <pipeclose+0x52>
    pi->writeopen = 0;
    800051da:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800051de:	21848513          	addi	a0,s1,536
    800051e2:	ffffd097          	auipc	ra,0xffffd
    800051e6:	14e080e7          	jalr	334(ra) # 80002330 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800051ea:	2204b783          	ld	a5,544(s1)
    800051ee:	eb95                	bnez	a5,80005222 <pipeclose+0x64>
    release(&pi->lock);
    800051f0:	8526                	mv	a0,s1
    800051f2:	ffffc097          	auipc	ra,0xffffc
    800051f6:	aac080e7          	jalr	-1364(ra) # 80000c9e <release>
    kfree((char*)pi);
    800051fa:	8526                	mv	a0,s1
    800051fc:	ffffc097          	auipc	ra,0xffffc
    80005200:	802080e7          	jalr	-2046(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80005204:	60e2                	ld	ra,24(sp)
    80005206:	6442                	ld	s0,16(sp)
    80005208:	64a2                	ld	s1,8(sp)
    8000520a:	6902                	ld	s2,0(sp)
    8000520c:	6105                	addi	sp,sp,32
    8000520e:	8082                	ret
    pi->readopen = 0;
    80005210:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005214:	21c48513          	addi	a0,s1,540
    80005218:	ffffd097          	auipc	ra,0xffffd
    8000521c:	118080e7          	jalr	280(ra) # 80002330 <wakeup>
    80005220:	b7e9                	j	800051ea <pipeclose+0x2c>
    release(&pi->lock);
    80005222:	8526                	mv	a0,s1
    80005224:	ffffc097          	auipc	ra,0xffffc
    80005228:	a7a080e7          	jalr	-1414(ra) # 80000c9e <release>
}
    8000522c:	bfe1                	j	80005204 <pipeclose+0x46>

000000008000522e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000522e:	7159                	addi	sp,sp,-112
    80005230:	f486                	sd	ra,104(sp)
    80005232:	f0a2                	sd	s0,96(sp)
    80005234:	eca6                	sd	s1,88(sp)
    80005236:	e8ca                	sd	s2,80(sp)
    80005238:	e4ce                	sd	s3,72(sp)
    8000523a:	e0d2                	sd	s4,64(sp)
    8000523c:	fc56                	sd	s5,56(sp)
    8000523e:	f85a                	sd	s6,48(sp)
    80005240:	f45e                	sd	s7,40(sp)
    80005242:	f062                	sd	s8,32(sp)
    80005244:	ec66                	sd	s9,24(sp)
    80005246:	1880                	addi	s0,sp,112
    80005248:	84aa                	mv	s1,a0
    8000524a:	8aae                	mv	s5,a1
    8000524c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000524e:	ffffc097          	auipc	ra,0xffffc
    80005252:	778080e7          	jalr	1912(ra) # 800019c6 <myproc>
    80005256:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005258:	8526                	mv	a0,s1
    8000525a:	ffffc097          	auipc	ra,0xffffc
    8000525e:	990080e7          	jalr	-1648(ra) # 80000bea <acquire>
  while(i < n){
    80005262:	0d405463          	blez	s4,8000532a <pipewrite+0xfc>
    80005266:	8ba6                	mv	s7,s1
  int i = 0;
    80005268:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000526a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000526c:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005270:	21c48c13          	addi	s8,s1,540
    80005274:	a08d                	j	800052d6 <pipewrite+0xa8>
      release(&pi->lock);
    80005276:	8526                	mv	a0,s1
    80005278:	ffffc097          	auipc	ra,0xffffc
    8000527c:	a26080e7          	jalr	-1498(ra) # 80000c9e <release>
      return -1;
    80005280:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005282:	854a                	mv	a0,s2
    80005284:	70a6                	ld	ra,104(sp)
    80005286:	7406                	ld	s0,96(sp)
    80005288:	64e6                	ld	s1,88(sp)
    8000528a:	6946                	ld	s2,80(sp)
    8000528c:	69a6                	ld	s3,72(sp)
    8000528e:	6a06                	ld	s4,64(sp)
    80005290:	7ae2                	ld	s5,56(sp)
    80005292:	7b42                	ld	s6,48(sp)
    80005294:	7ba2                	ld	s7,40(sp)
    80005296:	7c02                	ld	s8,32(sp)
    80005298:	6ce2                	ld	s9,24(sp)
    8000529a:	6165                	addi	sp,sp,112
    8000529c:	8082                	ret
      wakeup(&pi->nread);
    8000529e:	8566                	mv	a0,s9
    800052a0:	ffffd097          	auipc	ra,0xffffd
    800052a4:	090080e7          	jalr	144(ra) # 80002330 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800052a8:	85de                	mv	a1,s7
    800052aa:	8562                	mv	a0,s8
    800052ac:	ffffd097          	auipc	ra,0xffffd
    800052b0:	ed4080e7          	jalr	-300(ra) # 80002180 <sleep>
    800052b4:	a839                	j	800052d2 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800052b6:	21c4a783          	lw	a5,540(s1)
    800052ba:	0017871b          	addiw	a4,a5,1
    800052be:	20e4ae23          	sw	a4,540(s1)
    800052c2:	1ff7f793          	andi	a5,a5,511
    800052c6:	97a6                	add	a5,a5,s1
    800052c8:	f9f44703          	lbu	a4,-97(s0)
    800052cc:	00e78c23          	sb	a4,24(a5)
      i++;
    800052d0:	2905                	addiw	s2,s2,1
  while(i < n){
    800052d2:	05495063          	bge	s2,s4,80005312 <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    800052d6:	2204a783          	lw	a5,544(s1)
    800052da:	dfd1                	beqz	a5,80005276 <pipewrite+0x48>
    800052dc:	854e                	mv	a0,s3
    800052de:	ffffd097          	auipc	ra,0xffffd
    800052e2:	2a2080e7          	jalr	674(ra) # 80002580 <killed>
    800052e6:	f941                	bnez	a0,80005276 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800052e8:	2184a783          	lw	a5,536(s1)
    800052ec:	21c4a703          	lw	a4,540(s1)
    800052f0:	2007879b          	addiw	a5,a5,512
    800052f4:	faf705e3          	beq	a4,a5,8000529e <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800052f8:	4685                	li	a3,1
    800052fa:	01590633          	add	a2,s2,s5
    800052fe:	f9f40593          	addi	a1,s0,-97
    80005302:	0509b503          	ld	a0,80(s3)
    80005306:	ffffc097          	auipc	ra,0xffffc
    8000530a:	40a080e7          	jalr	1034(ra) # 80001710 <copyin>
    8000530e:	fb6514e3          	bne	a0,s6,800052b6 <pipewrite+0x88>
  wakeup(&pi->nread);
    80005312:	21848513          	addi	a0,s1,536
    80005316:	ffffd097          	auipc	ra,0xffffd
    8000531a:	01a080e7          	jalr	26(ra) # 80002330 <wakeup>
  release(&pi->lock);
    8000531e:	8526                	mv	a0,s1
    80005320:	ffffc097          	auipc	ra,0xffffc
    80005324:	97e080e7          	jalr	-1666(ra) # 80000c9e <release>
  return i;
    80005328:	bfa9                	j	80005282 <pipewrite+0x54>
  int i = 0;
    8000532a:	4901                	li	s2,0
    8000532c:	b7dd                	j	80005312 <pipewrite+0xe4>

000000008000532e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000532e:	715d                	addi	sp,sp,-80
    80005330:	e486                	sd	ra,72(sp)
    80005332:	e0a2                	sd	s0,64(sp)
    80005334:	fc26                	sd	s1,56(sp)
    80005336:	f84a                	sd	s2,48(sp)
    80005338:	f44e                	sd	s3,40(sp)
    8000533a:	f052                	sd	s4,32(sp)
    8000533c:	ec56                	sd	s5,24(sp)
    8000533e:	e85a                	sd	s6,16(sp)
    80005340:	0880                	addi	s0,sp,80
    80005342:	84aa                	mv	s1,a0
    80005344:	892e                	mv	s2,a1
    80005346:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005348:	ffffc097          	auipc	ra,0xffffc
    8000534c:	67e080e7          	jalr	1662(ra) # 800019c6 <myproc>
    80005350:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005352:	8b26                	mv	s6,s1
    80005354:	8526                	mv	a0,s1
    80005356:	ffffc097          	auipc	ra,0xffffc
    8000535a:	894080e7          	jalr	-1900(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000535e:	2184a703          	lw	a4,536(s1)
    80005362:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005366:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000536a:	02f71763          	bne	a4,a5,80005398 <piperead+0x6a>
    8000536e:	2244a783          	lw	a5,548(s1)
    80005372:	c39d                	beqz	a5,80005398 <piperead+0x6a>
    if(killed(pr)){
    80005374:	8552                	mv	a0,s4
    80005376:	ffffd097          	auipc	ra,0xffffd
    8000537a:	20a080e7          	jalr	522(ra) # 80002580 <killed>
    8000537e:	e941                	bnez	a0,8000540e <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005380:	85da                	mv	a1,s6
    80005382:	854e                	mv	a0,s3
    80005384:	ffffd097          	auipc	ra,0xffffd
    80005388:	dfc080e7          	jalr	-516(ra) # 80002180 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000538c:	2184a703          	lw	a4,536(s1)
    80005390:	21c4a783          	lw	a5,540(s1)
    80005394:	fcf70de3          	beq	a4,a5,8000536e <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005398:	09505263          	blez	s5,8000541c <piperead+0xee>
    8000539c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000539e:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800053a0:	2184a783          	lw	a5,536(s1)
    800053a4:	21c4a703          	lw	a4,540(s1)
    800053a8:	02f70d63          	beq	a4,a5,800053e2 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800053ac:	0017871b          	addiw	a4,a5,1
    800053b0:	20e4ac23          	sw	a4,536(s1)
    800053b4:	1ff7f793          	andi	a5,a5,511
    800053b8:	97a6                	add	a5,a5,s1
    800053ba:	0187c783          	lbu	a5,24(a5)
    800053be:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800053c2:	4685                	li	a3,1
    800053c4:	fbf40613          	addi	a2,s0,-65
    800053c8:	85ca                	mv	a1,s2
    800053ca:	050a3503          	ld	a0,80(s4)
    800053ce:	ffffc097          	auipc	ra,0xffffc
    800053d2:	2b6080e7          	jalr	694(ra) # 80001684 <copyout>
    800053d6:	01650663          	beq	a0,s6,800053e2 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800053da:	2985                	addiw	s3,s3,1
    800053dc:	0905                	addi	s2,s2,1
    800053de:	fd3a91e3          	bne	s5,s3,800053a0 <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800053e2:	21c48513          	addi	a0,s1,540
    800053e6:	ffffd097          	auipc	ra,0xffffd
    800053ea:	f4a080e7          	jalr	-182(ra) # 80002330 <wakeup>
  release(&pi->lock);
    800053ee:	8526                	mv	a0,s1
    800053f0:	ffffc097          	auipc	ra,0xffffc
    800053f4:	8ae080e7          	jalr	-1874(ra) # 80000c9e <release>
  return i;
}
    800053f8:	854e                	mv	a0,s3
    800053fa:	60a6                	ld	ra,72(sp)
    800053fc:	6406                	ld	s0,64(sp)
    800053fe:	74e2                	ld	s1,56(sp)
    80005400:	7942                	ld	s2,48(sp)
    80005402:	79a2                	ld	s3,40(sp)
    80005404:	7a02                	ld	s4,32(sp)
    80005406:	6ae2                	ld	s5,24(sp)
    80005408:	6b42                	ld	s6,16(sp)
    8000540a:	6161                	addi	sp,sp,80
    8000540c:	8082                	ret
      release(&pi->lock);
    8000540e:	8526                	mv	a0,s1
    80005410:	ffffc097          	auipc	ra,0xffffc
    80005414:	88e080e7          	jalr	-1906(ra) # 80000c9e <release>
      return -1;
    80005418:	59fd                	li	s3,-1
    8000541a:	bff9                	j	800053f8 <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000541c:	4981                	li	s3,0
    8000541e:	b7d1                	j	800053e2 <piperead+0xb4>

0000000080005420 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005420:	1141                	addi	sp,sp,-16
    80005422:	e422                	sd	s0,8(sp)
    80005424:	0800                	addi	s0,sp,16
    80005426:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005428:	8905                	andi	a0,a0,1
    8000542a:	c111                	beqz	a0,8000542e <flags2perm+0xe>
      perm = PTE_X;
    8000542c:	4521                	li	a0,8
    if(flags & 0x2)
    8000542e:	8b89                	andi	a5,a5,2
    80005430:	c399                	beqz	a5,80005436 <flags2perm+0x16>
      perm |= PTE_W;
    80005432:	00456513          	ori	a0,a0,4
    return perm;
}
    80005436:	6422                	ld	s0,8(sp)
    80005438:	0141                	addi	sp,sp,16
    8000543a:	8082                	ret

000000008000543c <exec>:

int
exec(char *path, char **argv)
{
    8000543c:	df010113          	addi	sp,sp,-528
    80005440:	20113423          	sd	ra,520(sp)
    80005444:	20813023          	sd	s0,512(sp)
    80005448:	ffa6                	sd	s1,504(sp)
    8000544a:	fbca                	sd	s2,496(sp)
    8000544c:	f7ce                	sd	s3,488(sp)
    8000544e:	f3d2                	sd	s4,480(sp)
    80005450:	efd6                	sd	s5,472(sp)
    80005452:	ebda                	sd	s6,464(sp)
    80005454:	e7de                	sd	s7,456(sp)
    80005456:	e3e2                	sd	s8,448(sp)
    80005458:	ff66                	sd	s9,440(sp)
    8000545a:	fb6a                	sd	s10,432(sp)
    8000545c:	f76e                	sd	s11,424(sp)
    8000545e:	0c00                	addi	s0,sp,528
    80005460:	84aa                	mv	s1,a0
    80005462:	dea43c23          	sd	a0,-520(s0)
    80005466:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000546a:	ffffc097          	auipc	ra,0xffffc
    8000546e:	55c080e7          	jalr	1372(ra) # 800019c6 <myproc>
    80005472:	892a                	mv	s2,a0

  begin_op();
    80005474:	fffff097          	auipc	ra,0xfffff
    80005478:	474080e7          	jalr	1140(ra) # 800048e8 <begin_op>

  if((ip = namei(path)) == 0){
    8000547c:	8526                	mv	a0,s1
    8000547e:	fffff097          	auipc	ra,0xfffff
    80005482:	24e080e7          	jalr	590(ra) # 800046cc <namei>
    80005486:	c92d                	beqz	a0,800054f8 <exec+0xbc>
    80005488:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000548a:	fffff097          	auipc	ra,0xfffff
    8000548e:	a9c080e7          	jalr	-1380(ra) # 80003f26 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005492:	04000713          	li	a4,64
    80005496:	4681                	li	a3,0
    80005498:	e5040613          	addi	a2,s0,-432
    8000549c:	4581                	li	a1,0
    8000549e:	8526                	mv	a0,s1
    800054a0:	fffff097          	auipc	ra,0xfffff
    800054a4:	d3a080e7          	jalr	-710(ra) # 800041da <readi>
    800054a8:	04000793          	li	a5,64
    800054ac:	00f51a63          	bne	a0,a5,800054c0 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800054b0:	e5042703          	lw	a4,-432(s0)
    800054b4:	464c47b7          	lui	a5,0x464c4
    800054b8:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800054bc:	04f70463          	beq	a4,a5,80005504 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800054c0:	8526                	mv	a0,s1
    800054c2:	fffff097          	auipc	ra,0xfffff
    800054c6:	cc6080e7          	jalr	-826(ra) # 80004188 <iunlockput>
    end_op();
    800054ca:	fffff097          	auipc	ra,0xfffff
    800054ce:	49e080e7          	jalr	1182(ra) # 80004968 <end_op>
  }
  return -1;
    800054d2:	557d                	li	a0,-1
}
    800054d4:	20813083          	ld	ra,520(sp)
    800054d8:	20013403          	ld	s0,512(sp)
    800054dc:	74fe                	ld	s1,504(sp)
    800054de:	795e                	ld	s2,496(sp)
    800054e0:	79be                	ld	s3,488(sp)
    800054e2:	7a1e                	ld	s4,480(sp)
    800054e4:	6afe                	ld	s5,472(sp)
    800054e6:	6b5e                	ld	s6,464(sp)
    800054e8:	6bbe                	ld	s7,456(sp)
    800054ea:	6c1e                	ld	s8,448(sp)
    800054ec:	7cfa                	ld	s9,440(sp)
    800054ee:	7d5a                	ld	s10,432(sp)
    800054f0:	7dba                	ld	s11,424(sp)
    800054f2:	21010113          	addi	sp,sp,528
    800054f6:	8082                	ret
    end_op();
    800054f8:	fffff097          	auipc	ra,0xfffff
    800054fc:	470080e7          	jalr	1136(ra) # 80004968 <end_op>
    return -1;
    80005500:	557d                	li	a0,-1
    80005502:	bfc9                	j	800054d4 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005504:	854a                	mv	a0,s2
    80005506:	ffffc097          	auipc	ra,0xffffc
    8000550a:	584080e7          	jalr	1412(ra) # 80001a8a <proc_pagetable>
    8000550e:	8baa                	mv	s7,a0
    80005510:	d945                	beqz	a0,800054c0 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005512:	e7042983          	lw	s3,-400(s0)
    80005516:	e8845783          	lhu	a5,-376(s0)
    8000551a:	c7ad                	beqz	a5,80005584 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000551c:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000551e:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80005520:	6c85                	lui	s9,0x1
    80005522:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005526:	def43823          	sd	a5,-528(s0)
    8000552a:	ac0d                	j	8000575c <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000552c:	00003517          	auipc	a0,0x3
    80005530:	34450513          	addi	a0,a0,836 # 80008870 <syscalls+0x2a8>
    80005534:	ffffb097          	auipc	ra,0xffffb
    80005538:	010080e7          	jalr	16(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000553c:	8756                	mv	a4,s5
    8000553e:	012d86bb          	addw	a3,s11,s2
    80005542:	4581                	li	a1,0
    80005544:	8526                	mv	a0,s1
    80005546:	fffff097          	auipc	ra,0xfffff
    8000554a:	c94080e7          	jalr	-876(ra) # 800041da <readi>
    8000554e:	2501                	sext.w	a0,a0
    80005550:	1aaa9a63          	bne	s5,a0,80005704 <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    80005554:	6785                	lui	a5,0x1
    80005556:	0127893b          	addw	s2,a5,s2
    8000555a:	77fd                	lui	a5,0xfffff
    8000555c:	01478a3b          	addw	s4,a5,s4
    80005560:	1f897563          	bgeu	s2,s8,8000574a <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    80005564:	02091593          	slli	a1,s2,0x20
    80005568:	9181                	srli	a1,a1,0x20
    8000556a:	95ea                	add	a1,a1,s10
    8000556c:	855e                	mv	a0,s7
    8000556e:	ffffc097          	auipc	ra,0xffffc
    80005572:	b0a080e7          	jalr	-1270(ra) # 80001078 <walkaddr>
    80005576:	862a                	mv	a2,a0
    if(pa == 0)
    80005578:	d955                	beqz	a0,8000552c <exec+0xf0>
      n = PGSIZE;
    8000557a:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    8000557c:	fd9a70e3          	bgeu	s4,s9,8000553c <exec+0x100>
      n = sz - i;
    80005580:	8ad2                	mv	s5,s4
    80005582:	bf6d                	j	8000553c <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005584:	4a01                	li	s4,0
  iunlockput(ip);
    80005586:	8526                	mv	a0,s1
    80005588:	fffff097          	auipc	ra,0xfffff
    8000558c:	c00080e7          	jalr	-1024(ra) # 80004188 <iunlockput>
  end_op();
    80005590:	fffff097          	auipc	ra,0xfffff
    80005594:	3d8080e7          	jalr	984(ra) # 80004968 <end_op>
  p = myproc();
    80005598:	ffffc097          	auipc	ra,0xffffc
    8000559c:	42e080e7          	jalr	1070(ra) # 800019c6 <myproc>
    800055a0:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800055a2:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800055a6:	6785                	lui	a5,0x1
    800055a8:	17fd                	addi	a5,a5,-1
    800055aa:	9a3e                	add	s4,s4,a5
    800055ac:	757d                	lui	a0,0xfffff
    800055ae:	00aa77b3          	and	a5,s4,a0
    800055b2:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800055b6:	4691                	li	a3,4
    800055b8:	6609                	lui	a2,0x2
    800055ba:	963e                	add	a2,a2,a5
    800055bc:	85be                	mv	a1,a5
    800055be:	855e                	mv	a0,s7
    800055c0:	ffffc097          	auipc	ra,0xffffc
    800055c4:	e6c080e7          	jalr	-404(ra) # 8000142c <uvmalloc>
    800055c8:	8b2a                	mv	s6,a0
  ip = 0;
    800055ca:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800055cc:	12050c63          	beqz	a0,80005704 <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    800055d0:	75f9                	lui	a1,0xffffe
    800055d2:	95aa                	add	a1,a1,a0
    800055d4:	855e                	mv	a0,s7
    800055d6:	ffffc097          	auipc	ra,0xffffc
    800055da:	07c080e7          	jalr	124(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    800055de:	7c7d                	lui	s8,0xfffff
    800055e0:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800055e2:	e0043783          	ld	a5,-512(s0)
    800055e6:	6388                	ld	a0,0(a5)
    800055e8:	c535                	beqz	a0,80005654 <exec+0x218>
    800055ea:	e9040993          	addi	s3,s0,-368
    800055ee:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800055f2:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800055f4:	ffffc097          	auipc	ra,0xffffc
    800055f8:	876080e7          	jalr	-1930(ra) # 80000e6a <strlen>
    800055fc:	2505                	addiw	a0,a0,1
    800055fe:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005602:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005606:	13896663          	bltu	s2,s8,80005732 <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000560a:	e0043d83          	ld	s11,-512(s0)
    8000560e:	000dba03          	ld	s4,0(s11)
    80005612:	8552                	mv	a0,s4
    80005614:	ffffc097          	auipc	ra,0xffffc
    80005618:	856080e7          	jalr	-1962(ra) # 80000e6a <strlen>
    8000561c:	0015069b          	addiw	a3,a0,1
    80005620:	8652                	mv	a2,s4
    80005622:	85ca                	mv	a1,s2
    80005624:	855e                	mv	a0,s7
    80005626:	ffffc097          	auipc	ra,0xffffc
    8000562a:	05e080e7          	jalr	94(ra) # 80001684 <copyout>
    8000562e:	10054663          	bltz	a0,8000573a <exec+0x2fe>
    ustack[argc] = sp;
    80005632:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005636:	0485                	addi	s1,s1,1
    80005638:	008d8793          	addi	a5,s11,8
    8000563c:	e0f43023          	sd	a5,-512(s0)
    80005640:	008db503          	ld	a0,8(s11)
    80005644:	c911                	beqz	a0,80005658 <exec+0x21c>
    if(argc >= MAXARG)
    80005646:	09a1                	addi	s3,s3,8
    80005648:	fb3c96e3          	bne	s9,s3,800055f4 <exec+0x1b8>
  sz = sz1;
    8000564c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005650:	4481                	li	s1,0
    80005652:	a84d                	j	80005704 <exec+0x2c8>
  sp = sz;
    80005654:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005656:	4481                	li	s1,0
  ustack[argc] = 0;
    80005658:	00349793          	slli	a5,s1,0x3
    8000565c:	f9040713          	addi	a4,s0,-112
    80005660:	97ba                	add	a5,a5,a4
    80005662:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005666:	00148693          	addi	a3,s1,1
    8000566a:	068e                	slli	a3,a3,0x3
    8000566c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005670:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005674:	01897663          	bgeu	s2,s8,80005680 <exec+0x244>
  sz = sz1;
    80005678:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000567c:	4481                	li	s1,0
    8000567e:	a059                	j	80005704 <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005680:	e9040613          	addi	a2,s0,-368
    80005684:	85ca                	mv	a1,s2
    80005686:	855e                	mv	a0,s7
    80005688:	ffffc097          	auipc	ra,0xffffc
    8000568c:	ffc080e7          	jalr	-4(ra) # 80001684 <copyout>
    80005690:	0a054963          	bltz	a0,80005742 <exec+0x306>
  p->trapframe->a1 = sp;
    80005694:	058ab783          	ld	a5,88(s5)
    80005698:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000569c:	df843783          	ld	a5,-520(s0)
    800056a0:	0007c703          	lbu	a4,0(a5)
    800056a4:	cf11                	beqz	a4,800056c0 <exec+0x284>
    800056a6:	0785                	addi	a5,a5,1
    if(*s == '/')
    800056a8:	02f00693          	li	a3,47
    800056ac:	a039                	j	800056ba <exec+0x27e>
      last = s+1;
    800056ae:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800056b2:	0785                	addi	a5,a5,1
    800056b4:	fff7c703          	lbu	a4,-1(a5)
    800056b8:	c701                	beqz	a4,800056c0 <exec+0x284>
    if(*s == '/')
    800056ba:	fed71ce3          	bne	a4,a3,800056b2 <exec+0x276>
    800056be:	bfc5                	j	800056ae <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    800056c0:	4641                	li	a2,16
    800056c2:	df843583          	ld	a1,-520(s0)
    800056c6:	158a8513          	addi	a0,s5,344
    800056ca:	ffffb097          	auipc	ra,0xffffb
    800056ce:	76e080e7          	jalr	1902(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    800056d2:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800056d6:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    800056da:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800056de:	058ab783          	ld	a5,88(s5)
    800056e2:	e6843703          	ld	a4,-408(s0)
    800056e6:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800056e8:	058ab783          	ld	a5,88(s5)
    800056ec:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800056f0:	85ea                	mv	a1,s10
    800056f2:	ffffc097          	auipc	ra,0xffffc
    800056f6:	434080e7          	jalr	1076(ra) # 80001b26 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800056fa:	0004851b          	sext.w	a0,s1
    800056fe:	bbd9                	j	800054d4 <exec+0x98>
    80005700:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005704:	e0843583          	ld	a1,-504(s0)
    80005708:	855e                	mv	a0,s7
    8000570a:	ffffc097          	auipc	ra,0xffffc
    8000570e:	41c080e7          	jalr	1052(ra) # 80001b26 <proc_freepagetable>
  if(ip){
    80005712:	da0497e3          	bnez	s1,800054c0 <exec+0x84>
  return -1;
    80005716:	557d                	li	a0,-1
    80005718:	bb75                	j	800054d4 <exec+0x98>
    8000571a:	e1443423          	sd	s4,-504(s0)
    8000571e:	b7dd                	j	80005704 <exec+0x2c8>
    80005720:	e1443423          	sd	s4,-504(s0)
    80005724:	b7c5                	j	80005704 <exec+0x2c8>
    80005726:	e1443423          	sd	s4,-504(s0)
    8000572a:	bfe9                	j	80005704 <exec+0x2c8>
    8000572c:	e1443423          	sd	s4,-504(s0)
    80005730:	bfd1                	j	80005704 <exec+0x2c8>
  sz = sz1;
    80005732:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005736:	4481                	li	s1,0
    80005738:	b7f1                	j	80005704 <exec+0x2c8>
  sz = sz1;
    8000573a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000573e:	4481                	li	s1,0
    80005740:	b7d1                	j	80005704 <exec+0x2c8>
  sz = sz1;
    80005742:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005746:	4481                	li	s1,0
    80005748:	bf75                	j	80005704 <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000574a:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000574e:	2b05                	addiw	s6,s6,1
    80005750:	0389899b          	addiw	s3,s3,56
    80005754:	e8845783          	lhu	a5,-376(s0)
    80005758:	e2fb57e3          	bge	s6,a5,80005586 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000575c:	2981                	sext.w	s3,s3
    8000575e:	03800713          	li	a4,56
    80005762:	86ce                	mv	a3,s3
    80005764:	e1840613          	addi	a2,s0,-488
    80005768:	4581                	li	a1,0
    8000576a:	8526                	mv	a0,s1
    8000576c:	fffff097          	auipc	ra,0xfffff
    80005770:	a6e080e7          	jalr	-1426(ra) # 800041da <readi>
    80005774:	03800793          	li	a5,56
    80005778:	f8f514e3          	bne	a0,a5,80005700 <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    8000577c:	e1842783          	lw	a5,-488(s0)
    80005780:	4705                	li	a4,1
    80005782:	fce796e3          	bne	a5,a4,8000574e <exec+0x312>
    if(ph.memsz < ph.filesz)
    80005786:	e4043903          	ld	s2,-448(s0)
    8000578a:	e3843783          	ld	a5,-456(s0)
    8000578e:	f8f966e3          	bltu	s2,a5,8000571a <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005792:	e2843783          	ld	a5,-472(s0)
    80005796:	993e                	add	s2,s2,a5
    80005798:	f8f964e3          	bltu	s2,a5,80005720 <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    8000579c:	df043703          	ld	a4,-528(s0)
    800057a0:	8ff9                	and	a5,a5,a4
    800057a2:	f3d1                	bnez	a5,80005726 <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800057a4:	e1c42503          	lw	a0,-484(s0)
    800057a8:	00000097          	auipc	ra,0x0
    800057ac:	c78080e7          	jalr	-904(ra) # 80005420 <flags2perm>
    800057b0:	86aa                	mv	a3,a0
    800057b2:	864a                	mv	a2,s2
    800057b4:	85d2                	mv	a1,s4
    800057b6:	855e                	mv	a0,s7
    800057b8:	ffffc097          	auipc	ra,0xffffc
    800057bc:	c74080e7          	jalr	-908(ra) # 8000142c <uvmalloc>
    800057c0:	e0a43423          	sd	a0,-504(s0)
    800057c4:	d525                	beqz	a0,8000572c <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800057c6:	e2843d03          	ld	s10,-472(s0)
    800057ca:	e2042d83          	lw	s11,-480(s0)
    800057ce:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800057d2:	f60c0ce3          	beqz	s8,8000574a <exec+0x30e>
    800057d6:	8a62                	mv	s4,s8
    800057d8:	4901                	li	s2,0
    800057da:	b369                	j	80005564 <exec+0x128>

00000000800057dc <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800057dc:	7179                	addi	sp,sp,-48
    800057de:	f406                	sd	ra,40(sp)
    800057e0:	f022                	sd	s0,32(sp)
    800057e2:	ec26                	sd	s1,24(sp)
    800057e4:	e84a                	sd	s2,16(sp)
    800057e6:	1800                	addi	s0,sp,48
    800057e8:	892e                	mv	s2,a1
    800057ea:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800057ec:	fdc40593          	addi	a1,s0,-36
    800057f0:	ffffd097          	auipc	ra,0xffffd
    800057f4:	5da080e7          	jalr	1498(ra) # 80002dca <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800057f8:	fdc42703          	lw	a4,-36(s0)
    800057fc:	47bd                	li	a5,15
    800057fe:	02e7eb63          	bltu	a5,a4,80005834 <argfd+0x58>
    80005802:	ffffc097          	auipc	ra,0xffffc
    80005806:	1c4080e7          	jalr	452(ra) # 800019c6 <myproc>
    8000580a:	fdc42703          	lw	a4,-36(s0)
    8000580e:	01a70793          	addi	a5,a4,26
    80005812:	078e                	slli	a5,a5,0x3
    80005814:	953e                	add	a0,a0,a5
    80005816:	611c                	ld	a5,0(a0)
    80005818:	c385                	beqz	a5,80005838 <argfd+0x5c>
    return -1;
  if(pfd)
    8000581a:	00090463          	beqz	s2,80005822 <argfd+0x46>
    *pfd = fd;
    8000581e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005822:	4501                	li	a0,0
  if(pf)
    80005824:	c091                	beqz	s1,80005828 <argfd+0x4c>
    *pf = f;
    80005826:	e09c                	sd	a5,0(s1)
}
    80005828:	70a2                	ld	ra,40(sp)
    8000582a:	7402                	ld	s0,32(sp)
    8000582c:	64e2                	ld	s1,24(sp)
    8000582e:	6942                	ld	s2,16(sp)
    80005830:	6145                	addi	sp,sp,48
    80005832:	8082                	ret
    return -1;
    80005834:	557d                	li	a0,-1
    80005836:	bfcd                	j	80005828 <argfd+0x4c>
    80005838:	557d                	li	a0,-1
    8000583a:	b7fd                	j	80005828 <argfd+0x4c>

000000008000583c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000583c:	1101                	addi	sp,sp,-32
    8000583e:	ec06                	sd	ra,24(sp)
    80005840:	e822                	sd	s0,16(sp)
    80005842:	e426                	sd	s1,8(sp)
    80005844:	1000                	addi	s0,sp,32
    80005846:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005848:	ffffc097          	auipc	ra,0xffffc
    8000584c:	17e080e7          	jalr	382(ra) # 800019c6 <myproc>
    80005850:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005852:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffda560>
    80005856:	4501                	li	a0,0
    80005858:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000585a:	6398                	ld	a4,0(a5)
    8000585c:	cb19                	beqz	a4,80005872 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000585e:	2505                	addiw	a0,a0,1
    80005860:	07a1                	addi	a5,a5,8
    80005862:	fed51ce3          	bne	a0,a3,8000585a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005866:	557d                	li	a0,-1
}
    80005868:	60e2                	ld	ra,24(sp)
    8000586a:	6442                	ld	s0,16(sp)
    8000586c:	64a2                	ld	s1,8(sp)
    8000586e:	6105                	addi	sp,sp,32
    80005870:	8082                	ret
      p->ofile[fd] = f;
    80005872:	01a50793          	addi	a5,a0,26
    80005876:	078e                	slli	a5,a5,0x3
    80005878:	963e                	add	a2,a2,a5
    8000587a:	e204                	sd	s1,0(a2)
      return fd;
    8000587c:	b7f5                	j	80005868 <fdalloc+0x2c>

000000008000587e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000587e:	715d                	addi	sp,sp,-80
    80005880:	e486                	sd	ra,72(sp)
    80005882:	e0a2                	sd	s0,64(sp)
    80005884:	fc26                	sd	s1,56(sp)
    80005886:	f84a                	sd	s2,48(sp)
    80005888:	f44e                	sd	s3,40(sp)
    8000588a:	f052                	sd	s4,32(sp)
    8000588c:	ec56                	sd	s5,24(sp)
    8000588e:	e85a                	sd	s6,16(sp)
    80005890:	0880                	addi	s0,sp,80
    80005892:	8b2e                	mv	s6,a1
    80005894:	89b2                	mv	s3,a2
    80005896:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005898:	fb040593          	addi	a1,s0,-80
    8000589c:	fffff097          	auipc	ra,0xfffff
    800058a0:	e4e080e7          	jalr	-434(ra) # 800046ea <nameiparent>
    800058a4:	84aa                	mv	s1,a0
    800058a6:	16050063          	beqz	a0,80005a06 <create+0x188>
    return 0;

  ilock(dp);
    800058aa:	ffffe097          	auipc	ra,0xffffe
    800058ae:	67c080e7          	jalr	1660(ra) # 80003f26 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800058b2:	4601                	li	a2,0
    800058b4:	fb040593          	addi	a1,s0,-80
    800058b8:	8526                	mv	a0,s1
    800058ba:	fffff097          	auipc	ra,0xfffff
    800058be:	b50080e7          	jalr	-1200(ra) # 8000440a <dirlookup>
    800058c2:	8aaa                	mv	s5,a0
    800058c4:	c931                	beqz	a0,80005918 <create+0x9a>
    iunlockput(dp);
    800058c6:	8526                	mv	a0,s1
    800058c8:	fffff097          	auipc	ra,0xfffff
    800058cc:	8c0080e7          	jalr	-1856(ra) # 80004188 <iunlockput>
    ilock(ip);
    800058d0:	8556                	mv	a0,s5
    800058d2:	ffffe097          	auipc	ra,0xffffe
    800058d6:	654080e7          	jalr	1620(ra) # 80003f26 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800058da:	000b059b          	sext.w	a1,s6
    800058de:	4789                	li	a5,2
    800058e0:	02f59563          	bne	a1,a5,8000590a <create+0x8c>
    800058e4:	044ad783          	lhu	a5,68(s5)
    800058e8:	37f9                	addiw	a5,a5,-2
    800058ea:	17c2                	slli	a5,a5,0x30
    800058ec:	93c1                	srli	a5,a5,0x30
    800058ee:	4705                	li	a4,1
    800058f0:	00f76d63          	bltu	a4,a5,8000590a <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800058f4:	8556                	mv	a0,s5
    800058f6:	60a6                	ld	ra,72(sp)
    800058f8:	6406                	ld	s0,64(sp)
    800058fa:	74e2                	ld	s1,56(sp)
    800058fc:	7942                	ld	s2,48(sp)
    800058fe:	79a2                	ld	s3,40(sp)
    80005900:	7a02                	ld	s4,32(sp)
    80005902:	6ae2                	ld	s5,24(sp)
    80005904:	6b42                	ld	s6,16(sp)
    80005906:	6161                	addi	sp,sp,80
    80005908:	8082                	ret
    iunlockput(ip);
    8000590a:	8556                	mv	a0,s5
    8000590c:	fffff097          	auipc	ra,0xfffff
    80005910:	87c080e7          	jalr	-1924(ra) # 80004188 <iunlockput>
    return 0;
    80005914:	4a81                	li	s5,0
    80005916:	bff9                	j	800058f4 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005918:	85da                	mv	a1,s6
    8000591a:	4088                	lw	a0,0(s1)
    8000591c:	ffffe097          	auipc	ra,0xffffe
    80005920:	46e080e7          	jalr	1134(ra) # 80003d8a <ialloc>
    80005924:	8a2a                	mv	s4,a0
    80005926:	c921                	beqz	a0,80005976 <create+0xf8>
  ilock(ip);
    80005928:	ffffe097          	auipc	ra,0xffffe
    8000592c:	5fe080e7          	jalr	1534(ra) # 80003f26 <ilock>
  ip->major = major;
    80005930:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005934:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005938:	4785                	li	a5,1
    8000593a:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    8000593e:	8552                	mv	a0,s4
    80005940:	ffffe097          	auipc	ra,0xffffe
    80005944:	51c080e7          	jalr	1308(ra) # 80003e5c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005948:	000b059b          	sext.w	a1,s6
    8000594c:	4785                	li	a5,1
    8000594e:	02f58b63          	beq	a1,a5,80005984 <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    80005952:	004a2603          	lw	a2,4(s4)
    80005956:	fb040593          	addi	a1,s0,-80
    8000595a:	8526                	mv	a0,s1
    8000595c:	fffff097          	auipc	ra,0xfffff
    80005960:	cbe080e7          	jalr	-834(ra) # 8000461a <dirlink>
    80005964:	06054f63          	bltz	a0,800059e2 <create+0x164>
  iunlockput(dp);
    80005968:	8526                	mv	a0,s1
    8000596a:	fffff097          	auipc	ra,0xfffff
    8000596e:	81e080e7          	jalr	-2018(ra) # 80004188 <iunlockput>
  return ip;
    80005972:	8ad2                	mv	s5,s4
    80005974:	b741                	j	800058f4 <create+0x76>
    iunlockput(dp);
    80005976:	8526                	mv	a0,s1
    80005978:	fffff097          	auipc	ra,0xfffff
    8000597c:	810080e7          	jalr	-2032(ra) # 80004188 <iunlockput>
    return 0;
    80005980:	8ad2                	mv	s5,s4
    80005982:	bf8d                	j	800058f4 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005984:	004a2603          	lw	a2,4(s4)
    80005988:	00003597          	auipc	a1,0x3
    8000598c:	f0858593          	addi	a1,a1,-248 # 80008890 <syscalls+0x2c8>
    80005990:	8552                	mv	a0,s4
    80005992:	fffff097          	auipc	ra,0xfffff
    80005996:	c88080e7          	jalr	-888(ra) # 8000461a <dirlink>
    8000599a:	04054463          	bltz	a0,800059e2 <create+0x164>
    8000599e:	40d0                	lw	a2,4(s1)
    800059a0:	00003597          	auipc	a1,0x3
    800059a4:	ef858593          	addi	a1,a1,-264 # 80008898 <syscalls+0x2d0>
    800059a8:	8552                	mv	a0,s4
    800059aa:	fffff097          	auipc	ra,0xfffff
    800059ae:	c70080e7          	jalr	-912(ra) # 8000461a <dirlink>
    800059b2:	02054863          	bltz	a0,800059e2 <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    800059b6:	004a2603          	lw	a2,4(s4)
    800059ba:	fb040593          	addi	a1,s0,-80
    800059be:	8526                	mv	a0,s1
    800059c0:	fffff097          	auipc	ra,0xfffff
    800059c4:	c5a080e7          	jalr	-934(ra) # 8000461a <dirlink>
    800059c8:	00054d63          	bltz	a0,800059e2 <create+0x164>
    dp->nlink++;  // for ".."
    800059cc:	04a4d783          	lhu	a5,74(s1)
    800059d0:	2785                	addiw	a5,a5,1
    800059d2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800059d6:	8526                	mv	a0,s1
    800059d8:	ffffe097          	auipc	ra,0xffffe
    800059dc:	484080e7          	jalr	1156(ra) # 80003e5c <iupdate>
    800059e0:	b761                	j	80005968 <create+0xea>
  ip->nlink = 0;
    800059e2:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800059e6:	8552                	mv	a0,s4
    800059e8:	ffffe097          	auipc	ra,0xffffe
    800059ec:	474080e7          	jalr	1140(ra) # 80003e5c <iupdate>
  iunlockput(ip);
    800059f0:	8552                	mv	a0,s4
    800059f2:	ffffe097          	auipc	ra,0xffffe
    800059f6:	796080e7          	jalr	1942(ra) # 80004188 <iunlockput>
  iunlockput(dp);
    800059fa:	8526                	mv	a0,s1
    800059fc:	ffffe097          	auipc	ra,0xffffe
    80005a00:	78c080e7          	jalr	1932(ra) # 80004188 <iunlockput>
  return 0;
    80005a04:	bdc5                	j	800058f4 <create+0x76>
    return 0;
    80005a06:	8aaa                	mv	s5,a0
    80005a08:	b5f5                	j	800058f4 <create+0x76>

0000000080005a0a <sys_dup>:
{
    80005a0a:	7179                	addi	sp,sp,-48
    80005a0c:	f406                	sd	ra,40(sp)
    80005a0e:	f022                	sd	s0,32(sp)
    80005a10:	ec26                	sd	s1,24(sp)
    80005a12:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005a14:	fd840613          	addi	a2,s0,-40
    80005a18:	4581                	li	a1,0
    80005a1a:	4501                	li	a0,0
    80005a1c:	00000097          	auipc	ra,0x0
    80005a20:	dc0080e7          	jalr	-576(ra) # 800057dc <argfd>
    return -1;
    80005a24:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005a26:	02054363          	bltz	a0,80005a4c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005a2a:	fd843503          	ld	a0,-40(s0)
    80005a2e:	00000097          	auipc	ra,0x0
    80005a32:	e0e080e7          	jalr	-498(ra) # 8000583c <fdalloc>
    80005a36:	84aa                	mv	s1,a0
    return -1;
    80005a38:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005a3a:	00054963          	bltz	a0,80005a4c <sys_dup+0x42>
  filedup(f);
    80005a3e:	fd843503          	ld	a0,-40(s0)
    80005a42:	fffff097          	auipc	ra,0xfffff
    80005a46:	320080e7          	jalr	800(ra) # 80004d62 <filedup>
  return fd;
    80005a4a:	87a6                	mv	a5,s1
}
    80005a4c:	853e                	mv	a0,a5
    80005a4e:	70a2                	ld	ra,40(sp)
    80005a50:	7402                	ld	s0,32(sp)
    80005a52:	64e2                	ld	s1,24(sp)
    80005a54:	6145                	addi	sp,sp,48
    80005a56:	8082                	ret

0000000080005a58 <sys_read>:
{
    80005a58:	7179                	addi	sp,sp,-48
    80005a5a:	f406                	sd	ra,40(sp)
    80005a5c:	f022                	sd	s0,32(sp)
    80005a5e:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005a60:	fd840593          	addi	a1,s0,-40
    80005a64:	4505                	li	a0,1
    80005a66:	ffffd097          	auipc	ra,0xffffd
    80005a6a:	384080e7          	jalr	900(ra) # 80002dea <argaddr>
  argint(2, &n);
    80005a6e:	fe440593          	addi	a1,s0,-28
    80005a72:	4509                	li	a0,2
    80005a74:	ffffd097          	auipc	ra,0xffffd
    80005a78:	356080e7          	jalr	854(ra) # 80002dca <argint>
  if(argfd(0, 0, &f) < 0)
    80005a7c:	fe840613          	addi	a2,s0,-24
    80005a80:	4581                	li	a1,0
    80005a82:	4501                	li	a0,0
    80005a84:	00000097          	auipc	ra,0x0
    80005a88:	d58080e7          	jalr	-680(ra) # 800057dc <argfd>
    80005a8c:	87aa                	mv	a5,a0
    return -1;
    80005a8e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005a90:	0007cc63          	bltz	a5,80005aa8 <sys_read+0x50>
  return fileread(f, p, n);
    80005a94:	fe442603          	lw	a2,-28(s0)
    80005a98:	fd843583          	ld	a1,-40(s0)
    80005a9c:	fe843503          	ld	a0,-24(s0)
    80005aa0:	fffff097          	auipc	ra,0xfffff
    80005aa4:	44e080e7          	jalr	1102(ra) # 80004eee <fileread>
}
    80005aa8:	70a2                	ld	ra,40(sp)
    80005aaa:	7402                	ld	s0,32(sp)
    80005aac:	6145                	addi	sp,sp,48
    80005aae:	8082                	ret

0000000080005ab0 <sys_write>:
{
    80005ab0:	7179                	addi	sp,sp,-48
    80005ab2:	f406                	sd	ra,40(sp)
    80005ab4:	f022                	sd	s0,32(sp)
    80005ab6:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005ab8:	fd840593          	addi	a1,s0,-40
    80005abc:	4505                	li	a0,1
    80005abe:	ffffd097          	auipc	ra,0xffffd
    80005ac2:	32c080e7          	jalr	812(ra) # 80002dea <argaddr>
  argint(2, &n);
    80005ac6:	fe440593          	addi	a1,s0,-28
    80005aca:	4509                	li	a0,2
    80005acc:	ffffd097          	auipc	ra,0xffffd
    80005ad0:	2fe080e7          	jalr	766(ra) # 80002dca <argint>
  if(argfd(0, 0, &f) < 0)
    80005ad4:	fe840613          	addi	a2,s0,-24
    80005ad8:	4581                	li	a1,0
    80005ada:	4501                	li	a0,0
    80005adc:	00000097          	auipc	ra,0x0
    80005ae0:	d00080e7          	jalr	-768(ra) # 800057dc <argfd>
    80005ae4:	87aa                	mv	a5,a0
    return -1;
    80005ae6:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005ae8:	0007cc63          	bltz	a5,80005b00 <sys_write+0x50>
  return filewrite(f, p, n);
    80005aec:	fe442603          	lw	a2,-28(s0)
    80005af0:	fd843583          	ld	a1,-40(s0)
    80005af4:	fe843503          	ld	a0,-24(s0)
    80005af8:	fffff097          	auipc	ra,0xfffff
    80005afc:	4b8080e7          	jalr	1208(ra) # 80004fb0 <filewrite>
}
    80005b00:	70a2                	ld	ra,40(sp)
    80005b02:	7402                	ld	s0,32(sp)
    80005b04:	6145                	addi	sp,sp,48
    80005b06:	8082                	ret

0000000080005b08 <sys_close>:
{
    80005b08:	1101                	addi	sp,sp,-32
    80005b0a:	ec06                	sd	ra,24(sp)
    80005b0c:	e822                	sd	s0,16(sp)
    80005b0e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005b10:	fe040613          	addi	a2,s0,-32
    80005b14:	fec40593          	addi	a1,s0,-20
    80005b18:	4501                	li	a0,0
    80005b1a:	00000097          	auipc	ra,0x0
    80005b1e:	cc2080e7          	jalr	-830(ra) # 800057dc <argfd>
    return -1;
    80005b22:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005b24:	02054463          	bltz	a0,80005b4c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005b28:	ffffc097          	auipc	ra,0xffffc
    80005b2c:	e9e080e7          	jalr	-354(ra) # 800019c6 <myproc>
    80005b30:	fec42783          	lw	a5,-20(s0)
    80005b34:	07e9                	addi	a5,a5,26
    80005b36:	078e                	slli	a5,a5,0x3
    80005b38:	97aa                	add	a5,a5,a0
    80005b3a:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005b3e:	fe043503          	ld	a0,-32(s0)
    80005b42:	fffff097          	auipc	ra,0xfffff
    80005b46:	272080e7          	jalr	626(ra) # 80004db4 <fileclose>
  return 0;
    80005b4a:	4781                	li	a5,0
}
    80005b4c:	853e                	mv	a0,a5
    80005b4e:	60e2                	ld	ra,24(sp)
    80005b50:	6442                	ld	s0,16(sp)
    80005b52:	6105                	addi	sp,sp,32
    80005b54:	8082                	ret

0000000080005b56 <sys_fstat>:
{
    80005b56:	1101                	addi	sp,sp,-32
    80005b58:	ec06                	sd	ra,24(sp)
    80005b5a:	e822                	sd	s0,16(sp)
    80005b5c:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005b5e:	fe040593          	addi	a1,s0,-32
    80005b62:	4505                	li	a0,1
    80005b64:	ffffd097          	auipc	ra,0xffffd
    80005b68:	286080e7          	jalr	646(ra) # 80002dea <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005b6c:	fe840613          	addi	a2,s0,-24
    80005b70:	4581                	li	a1,0
    80005b72:	4501                	li	a0,0
    80005b74:	00000097          	auipc	ra,0x0
    80005b78:	c68080e7          	jalr	-920(ra) # 800057dc <argfd>
    80005b7c:	87aa                	mv	a5,a0
    return -1;
    80005b7e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005b80:	0007ca63          	bltz	a5,80005b94 <sys_fstat+0x3e>
  return filestat(f, st);
    80005b84:	fe043583          	ld	a1,-32(s0)
    80005b88:	fe843503          	ld	a0,-24(s0)
    80005b8c:	fffff097          	auipc	ra,0xfffff
    80005b90:	2f0080e7          	jalr	752(ra) # 80004e7c <filestat>
}
    80005b94:	60e2                	ld	ra,24(sp)
    80005b96:	6442                	ld	s0,16(sp)
    80005b98:	6105                	addi	sp,sp,32
    80005b9a:	8082                	ret

0000000080005b9c <sys_link>:
{
    80005b9c:	7169                	addi	sp,sp,-304
    80005b9e:	f606                	sd	ra,296(sp)
    80005ba0:	f222                	sd	s0,288(sp)
    80005ba2:	ee26                	sd	s1,280(sp)
    80005ba4:	ea4a                	sd	s2,272(sp)
    80005ba6:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ba8:	08000613          	li	a2,128
    80005bac:	ed040593          	addi	a1,s0,-304
    80005bb0:	4501                	li	a0,0
    80005bb2:	ffffd097          	auipc	ra,0xffffd
    80005bb6:	258080e7          	jalr	600(ra) # 80002e0a <argstr>
    return -1;
    80005bba:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005bbc:	10054e63          	bltz	a0,80005cd8 <sys_link+0x13c>
    80005bc0:	08000613          	li	a2,128
    80005bc4:	f5040593          	addi	a1,s0,-176
    80005bc8:	4505                	li	a0,1
    80005bca:	ffffd097          	auipc	ra,0xffffd
    80005bce:	240080e7          	jalr	576(ra) # 80002e0a <argstr>
    return -1;
    80005bd2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005bd4:	10054263          	bltz	a0,80005cd8 <sys_link+0x13c>
  begin_op();
    80005bd8:	fffff097          	auipc	ra,0xfffff
    80005bdc:	d10080e7          	jalr	-752(ra) # 800048e8 <begin_op>
  if((ip = namei(old)) == 0){
    80005be0:	ed040513          	addi	a0,s0,-304
    80005be4:	fffff097          	auipc	ra,0xfffff
    80005be8:	ae8080e7          	jalr	-1304(ra) # 800046cc <namei>
    80005bec:	84aa                	mv	s1,a0
    80005bee:	c551                	beqz	a0,80005c7a <sys_link+0xde>
  ilock(ip);
    80005bf0:	ffffe097          	auipc	ra,0xffffe
    80005bf4:	336080e7          	jalr	822(ra) # 80003f26 <ilock>
  if(ip->type == T_DIR){
    80005bf8:	04449703          	lh	a4,68(s1)
    80005bfc:	4785                	li	a5,1
    80005bfe:	08f70463          	beq	a4,a5,80005c86 <sys_link+0xea>
  ip->nlink++;
    80005c02:	04a4d783          	lhu	a5,74(s1)
    80005c06:	2785                	addiw	a5,a5,1
    80005c08:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005c0c:	8526                	mv	a0,s1
    80005c0e:	ffffe097          	auipc	ra,0xffffe
    80005c12:	24e080e7          	jalr	590(ra) # 80003e5c <iupdate>
  iunlock(ip);
    80005c16:	8526                	mv	a0,s1
    80005c18:	ffffe097          	auipc	ra,0xffffe
    80005c1c:	3d0080e7          	jalr	976(ra) # 80003fe8 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005c20:	fd040593          	addi	a1,s0,-48
    80005c24:	f5040513          	addi	a0,s0,-176
    80005c28:	fffff097          	auipc	ra,0xfffff
    80005c2c:	ac2080e7          	jalr	-1342(ra) # 800046ea <nameiparent>
    80005c30:	892a                	mv	s2,a0
    80005c32:	c935                	beqz	a0,80005ca6 <sys_link+0x10a>
  ilock(dp);
    80005c34:	ffffe097          	auipc	ra,0xffffe
    80005c38:	2f2080e7          	jalr	754(ra) # 80003f26 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005c3c:	00092703          	lw	a4,0(s2)
    80005c40:	409c                	lw	a5,0(s1)
    80005c42:	04f71d63          	bne	a4,a5,80005c9c <sys_link+0x100>
    80005c46:	40d0                	lw	a2,4(s1)
    80005c48:	fd040593          	addi	a1,s0,-48
    80005c4c:	854a                	mv	a0,s2
    80005c4e:	fffff097          	auipc	ra,0xfffff
    80005c52:	9cc080e7          	jalr	-1588(ra) # 8000461a <dirlink>
    80005c56:	04054363          	bltz	a0,80005c9c <sys_link+0x100>
  iunlockput(dp);
    80005c5a:	854a                	mv	a0,s2
    80005c5c:	ffffe097          	auipc	ra,0xffffe
    80005c60:	52c080e7          	jalr	1324(ra) # 80004188 <iunlockput>
  iput(ip);
    80005c64:	8526                	mv	a0,s1
    80005c66:	ffffe097          	auipc	ra,0xffffe
    80005c6a:	47a080e7          	jalr	1146(ra) # 800040e0 <iput>
  end_op();
    80005c6e:	fffff097          	auipc	ra,0xfffff
    80005c72:	cfa080e7          	jalr	-774(ra) # 80004968 <end_op>
  return 0;
    80005c76:	4781                	li	a5,0
    80005c78:	a085                	j	80005cd8 <sys_link+0x13c>
    end_op();
    80005c7a:	fffff097          	auipc	ra,0xfffff
    80005c7e:	cee080e7          	jalr	-786(ra) # 80004968 <end_op>
    return -1;
    80005c82:	57fd                	li	a5,-1
    80005c84:	a891                	j	80005cd8 <sys_link+0x13c>
    iunlockput(ip);
    80005c86:	8526                	mv	a0,s1
    80005c88:	ffffe097          	auipc	ra,0xffffe
    80005c8c:	500080e7          	jalr	1280(ra) # 80004188 <iunlockput>
    end_op();
    80005c90:	fffff097          	auipc	ra,0xfffff
    80005c94:	cd8080e7          	jalr	-808(ra) # 80004968 <end_op>
    return -1;
    80005c98:	57fd                	li	a5,-1
    80005c9a:	a83d                	j	80005cd8 <sys_link+0x13c>
    iunlockput(dp);
    80005c9c:	854a                	mv	a0,s2
    80005c9e:	ffffe097          	auipc	ra,0xffffe
    80005ca2:	4ea080e7          	jalr	1258(ra) # 80004188 <iunlockput>
  ilock(ip);
    80005ca6:	8526                	mv	a0,s1
    80005ca8:	ffffe097          	auipc	ra,0xffffe
    80005cac:	27e080e7          	jalr	638(ra) # 80003f26 <ilock>
  ip->nlink--;
    80005cb0:	04a4d783          	lhu	a5,74(s1)
    80005cb4:	37fd                	addiw	a5,a5,-1
    80005cb6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005cba:	8526                	mv	a0,s1
    80005cbc:	ffffe097          	auipc	ra,0xffffe
    80005cc0:	1a0080e7          	jalr	416(ra) # 80003e5c <iupdate>
  iunlockput(ip);
    80005cc4:	8526                	mv	a0,s1
    80005cc6:	ffffe097          	auipc	ra,0xffffe
    80005cca:	4c2080e7          	jalr	1218(ra) # 80004188 <iunlockput>
  end_op();
    80005cce:	fffff097          	auipc	ra,0xfffff
    80005cd2:	c9a080e7          	jalr	-870(ra) # 80004968 <end_op>
  return -1;
    80005cd6:	57fd                	li	a5,-1
}
    80005cd8:	853e                	mv	a0,a5
    80005cda:	70b2                	ld	ra,296(sp)
    80005cdc:	7412                	ld	s0,288(sp)
    80005cde:	64f2                	ld	s1,280(sp)
    80005ce0:	6952                	ld	s2,272(sp)
    80005ce2:	6155                	addi	sp,sp,304
    80005ce4:	8082                	ret

0000000080005ce6 <sys_unlink>:
{
    80005ce6:	7151                	addi	sp,sp,-240
    80005ce8:	f586                	sd	ra,232(sp)
    80005cea:	f1a2                	sd	s0,224(sp)
    80005cec:	eda6                	sd	s1,216(sp)
    80005cee:	e9ca                	sd	s2,208(sp)
    80005cf0:	e5ce                	sd	s3,200(sp)
    80005cf2:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005cf4:	08000613          	li	a2,128
    80005cf8:	f3040593          	addi	a1,s0,-208
    80005cfc:	4501                	li	a0,0
    80005cfe:	ffffd097          	auipc	ra,0xffffd
    80005d02:	10c080e7          	jalr	268(ra) # 80002e0a <argstr>
    80005d06:	18054163          	bltz	a0,80005e88 <sys_unlink+0x1a2>
  begin_op();
    80005d0a:	fffff097          	auipc	ra,0xfffff
    80005d0e:	bde080e7          	jalr	-1058(ra) # 800048e8 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005d12:	fb040593          	addi	a1,s0,-80
    80005d16:	f3040513          	addi	a0,s0,-208
    80005d1a:	fffff097          	auipc	ra,0xfffff
    80005d1e:	9d0080e7          	jalr	-1584(ra) # 800046ea <nameiparent>
    80005d22:	84aa                	mv	s1,a0
    80005d24:	c979                	beqz	a0,80005dfa <sys_unlink+0x114>
  ilock(dp);
    80005d26:	ffffe097          	auipc	ra,0xffffe
    80005d2a:	200080e7          	jalr	512(ra) # 80003f26 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005d2e:	00003597          	auipc	a1,0x3
    80005d32:	b6258593          	addi	a1,a1,-1182 # 80008890 <syscalls+0x2c8>
    80005d36:	fb040513          	addi	a0,s0,-80
    80005d3a:	ffffe097          	auipc	ra,0xffffe
    80005d3e:	6b6080e7          	jalr	1718(ra) # 800043f0 <namecmp>
    80005d42:	14050a63          	beqz	a0,80005e96 <sys_unlink+0x1b0>
    80005d46:	00003597          	auipc	a1,0x3
    80005d4a:	b5258593          	addi	a1,a1,-1198 # 80008898 <syscalls+0x2d0>
    80005d4e:	fb040513          	addi	a0,s0,-80
    80005d52:	ffffe097          	auipc	ra,0xffffe
    80005d56:	69e080e7          	jalr	1694(ra) # 800043f0 <namecmp>
    80005d5a:	12050e63          	beqz	a0,80005e96 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005d5e:	f2c40613          	addi	a2,s0,-212
    80005d62:	fb040593          	addi	a1,s0,-80
    80005d66:	8526                	mv	a0,s1
    80005d68:	ffffe097          	auipc	ra,0xffffe
    80005d6c:	6a2080e7          	jalr	1698(ra) # 8000440a <dirlookup>
    80005d70:	892a                	mv	s2,a0
    80005d72:	12050263          	beqz	a0,80005e96 <sys_unlink+0x1b0>
  ilock(ip);
    80005d76:	ffffe097          	auipc	ra,0xffffe
    80005d7a:	1b0080e7          	jalr	432(ra) # 80003f26 <ilock>
  if(ip->nlink < 1)
    80005d7e:	04a91783          	lh	a5,74(s2)
    80005d82:	08f05263          	blez	a5,80005e06 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005d86:	04491703          	lh	a4,68(s2)
    80005d8a:	4785                	li	a5,1
    80005d8c:	08f70563          	beq	a4,a5,80005e16 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005d90:	4641                	li	a2,16
    80005d92:	4581                	li	a1,0
    80005d94:	fc040513          	addi	a0,s0,-64
    80005d98:	ffffb097          	auipc	ra,0xffffb
    80005d9c:	f4e080e7          	jalr	-178(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005da0:	4741                	li	a4,16
    80005da2:	f2c42683          	lw	a3,-212(s0)
    80005da6:	fc040613          	addi	a2,s0,-64
    80005daa:	4581                	li	a1,0
    80005dac:	8526                	mv	a0,s1
    80005dae:	ffffe097          	auipc	ra,0xffffe
    80005db2:	524080e7          	jalr	1316(ra) # 800042d2 <writei>
    80005db6:	47c1                	li	a5,16
    80005db8:	0af51563          	bne	a0,a5,80005e62 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005dbc:	04491703          	lh	a4,68(s2)
    80005dc0:	4785                	li	a5,1
    80005dc2:	0af70863          	beq	a4,a5,80005e72 <sys_unlink+0x18c>
  iunlockput(dp);
    80005dc6:	8526                	mv	a0,s1
    80005dc8:	ffffe097          	auipc	ra,0xffffe
    80005dcc:	3c0080e7          	jalr	960(ra) # 80004188 <iunlockput>
  ip->nlink--;
    80005dd0:	04a95783          	lhu	a5,74(s2)
    80005dd4:	37fd                	addiw	a5,a5,-1
    80005dd6:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005dda:	854a                	mv	a0,s2
    80005ddc:	ffffe097          	auipc	ra,0xffffe
    80005de0:	080080e7          	jalr	128(ra) # 80003e5c <iupdate>
  iunlockput(ip);
    80005de4:	854a                	mv	a0,s2
    80005de6:	ffffe097          	auipc	ra,0xffffe
    80005dea:	3a2080e7          	jalr	930(ra) # 80004188 <iunlockput>
  end_op();
    80005dee:	fffff097          	auipc	ra,0xfffff
    80005df2:	b7a080e7          	jalr	-1158(ra) # 80004968 <end_op>
  return 0;
    80005df6:	4501                	li	a0,0
    80005df8:	a84d                	j	80005eaa <sys_unlink+0x1c4>
    end_op();
    80005dfa:	fffff097          	auipc	ra,0xfffff
    80005dfe:	b6e080e7          	jalr	-1170(ra) # 80004968 <end_op>
    return -1;
    80005e02:	557d                	li	a0,-1
    80005e04:	a05d                	j	80005eaa <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005e06:	00003517          	auipc	a0,0x3
    80005e0a:	a9a50513          	addi	a0,a0,-1382 # 800088a0 <syscalls+0x2d8>
    80005e0e:	ffffa097          	auipc	ra,0xffffa
    80005e12:	736080e7          	jalr	1846(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e16:	04c92703          	lw	a4,76(s2)
    80005e1a:	02000793          	li	a5,32
    80005e1e:	f6e7f9e3          	bgeu	a5,a4,80005d90 <sys_unlink+0xaa>
    80005e22:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005e26:	4741                	li	a4,16
    80005e28:	86ce                	mv	a3,s3
    80005e2a:	f1840613          	addi	a2,s0,-232
    80005e2e:	4581                	li	a1,0
    80005e30:	854a                	mv	a0,s2
    80005e32:	ffffe097          	auipc	ra,0xffffe
    80005e36:	3a8080e7          	jalr	936(ra) # 800041da <readi>
    80005e3a:	47c1                	li	a5,16
    80005e3c:	00f51b63          	bne	a0,a5,80005e52 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005e40:	f1845783          	lhu	a5,-232(s0)
    80005e44:	e7a1                	bnez	a5,80005e8c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e46:	29c1                	addiw	s3,s3,16
    80005e48:	04c92783          	lw	a5,76(s2)
    80005e4c:	fcf9ede3          	bltu	s3,a5,80005e26 <sys_unlink+0x140>
    80005e50:	b781                	j	80005d90 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005e52:	00003517          	auipc	a0,0x3
    80005e56:	a6650513          	addi	a0,a0,-1434 # 800088b8 <syscalls+0x2f0>
    80005e5a:	ffffa097          	auipc	ra,0xffffa
    80005e5e:	6ea080e7          	jalr	1770(ra) # 80000544 <panic>
    panic("unlink: writei");
    80005e62:	00003517          	auipc	a0,0x3
    80005e66:	a6e50513          	addi	a0,a0,-1426 # 800088d0 <syscalls+0x308>
    80005e6a:	ffffa097          	auipc	ra,0xffffa
    80005e6e:	6da080e7          	jalr	1754(ra) # 80000544 <panic>
    dp->nlink--;
    80005e72:	04a4d783          	lhu	a5,74(s1)
    80005e76:	37fd                	addiw	a5,a5,-1
    80005e78:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005e7c:	8526                	mv	a0,s1
    80005e7e:	ffffe097          	auipc	ra,0xffffe
    80005e82:	fde080e7          	jalr	-34(ra) # 80003e5c <iupdate>
    80005e86:	b781                	j	80005dc6 <sys_unlink+0xe0>
    return -1;
    80005e88:	557d                	li	a0,-1
    80005e8a:	a005                	j	80005eaa <sys_unlink+0x1c4>
    iunlockput(ip);
    80005e8c:	854a                	mv	a0,s2
    80005e8e:	ffffe097          	auipc	ra,0xffffe
    80005e92:	2fa080e7          	jalr	762(ra) # 80004188 <iunlockput>
  iunlockput(dp);
    80005e96:	8526                	mv	a0,s1
    80005e98:	ffffe097          	auipc	ra,0xffffe
    80005e9c:	2f0080e7          	jalr	752(ra) # 80004188 <iunlockput>
  end_op();
    80005ea0:	fffff097          	auipc	ra,0xfffff
    80005ea4:	ac8080e7          	jalr	-1336(ra) # 80004968 <end_op>
  return -1;
    80005ea8:	557d                	li	a0,-1
}
    80005eaa:	70ae                	ld	ra,232(sp)
    80005eac:	740e                	ld	s0,224(sp)
    80005eae:	64ee                	ld	s1,216(sp)
    80005eb0:	694e                	ld	s2,208(sp)
    80005eb2:	69ae                	ld	s3,200(sp)
    80005eb4:	616d                	addi	sp,sp,240
    80005eb6:	8082                	ret

0000000080005eb8 <sys_open>:

uint64
sys_open(void)
{
    80005eb8:	7131                	addi	sp,sp,-192
    80005eba:	fd06                	sd	ra,184(sp)
    80005ebc:	f922                	sd	s0,176(sp)
    80005ebe:	f526                	sd	s1,168(sp)
    80005ec0:	f14a                	sd	s2,160(sp)
    80005ec2:	ed4e                	sd	s3,152(sp)
    80005ec4:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005ec6:	f4c40593          	addi	a1,s0,-180
    80005eca:	4505                	li	a0,1
    80005ecc:	ffffd097          	auipc	ra,0xffffd
    80005ed0:	efe080e7          	jalr	-258(ra) # 80002dca <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005ed4:	08000613          	li	a2,128
    80005ed8:	f5040593          	addi	a1,s0,-176
    80005edc:	4501                	li	a0,0
    80005ede:	ffffd097          	auipc	ra,0xffffd
    80005ee2:	f2c080e7          	jalr	-212(ra) # 80002e0a <argstr>
    80005ee6:	87aa                	mv	a5,a0
    return -1;
    80005ee8:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005eea:	0a07c963          	bltz	a5,80005f9c <sys_open+0xe4>

  begin_op();
    80005eee:	fffff097          	auipc	ra,0xfffff
    80005ef2:	9fa080e7          	jalr	-1542(ra) # 800048e8 <begin_op>

  if(omode & O_CREATE){
    80005ef6:	f4c42783          	lw	a5,-180(s0)
    80005efa:	2007f793          	andi	a5,a5,512
    80005efe:	cfc5                	beqz	a5,80005fb6 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005f00:	4681                	li	a3,0
    80005f02:	4601                	li	a2,0
    80005f04:	4589                	li	a1,2
    80005f06:	f5040513          	addi	a0,s0,-176
    80005f0a:	00000097          	auipc	ra,0x0
    80005f0e:	974080e7          	jalr	-1676(ra) # 8000587e <create>
    80005f12:	84aa                	mv	s1,a0
    if(ip == 0){
    80005f14:	c959                	beqz	a0,80005faa <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005f16:	04449703          	lh	a4,68(s1)
    80005f1a:	478d                	li	a5,3
    80005f1c:	00f71763          	bne	a4,a5,80005f2a <sys_open+0x72>
    80005f20:	0464d703          	lhu	a4,70(s1)
    80005f24:	47a5                	li	a5,9
    80005f26:	0ce7ed63          	bltu	a5,a4,80006000 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005f2a:	fffff097          	auipc	ra,0xfffff
    80005f2e:	dce080e7          	jalr	-562(ra) # 80004cf8 <filealloc>
    80005f32:	89aa                	mv	s3,a0
    80005f34:	10050363          	beqz	a0,8000603a <sys_open+0x182>
    80005f38:	00000097          	auipc	ra,0x0
    80005f3c:	904080e7          	jalr	-1788(ra) # 8000583c <fdalloc>
    80005f40:	892a                	mv	s2,a0
    80005f42:	0e054763          	bltz	a0,80006030 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005f46:	04449703          	lh	a4,68(s1)
    80005f4a:	478d                	li	a5,3
    80005f4c:	0cf70563          	beq	a4,a5,80006016 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005f50:	4789                	li	a5,2
    80005f52:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005f56:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005f5a:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005f5e:	f4c42783          	lw	a5,-180(s0)
    80005f62:	0017c713          	xori	a4,a5,1
    80005f66:	8b05                	andi	a4,a4,1
    80005f68:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005f6c:	0037f713          	andi	a4,a5,3
    80005f70:	00e03733          	snez	a4,a4
    80005f74:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005f78:	4007f793          	andi	a5,a5,1024
    80005f7c:	c791                	beqz	a5,80005f88 <sys_open+0xd0>
    80005f7e:	04449703          	lh	a4,68(s1)
    80005f82:	4789                	li	a5,2
    80005f84:	0af70063          	beq	a4,a5,80006024 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005f88:	8526                	mv	a0,s1
    80005f8a:	ffffe097          	auipc	ra,0xffffe
    80005f8e:	05e080e7          	jalr	94(ra) # 80003fe8 <iunlock>
  end_op();
    80005f92:	fffff097          	auipc	ra,0xfffff
    80005f96:	9d6080e7          	jalr	-1578(ra) # 80004968 <end_op>

  return fd;
    80005f9a:	854a                	mv	a0,s2
}
    80005f9c:	70ea                	ld	ra,184(sp)
    80005f9e:	744a                	ld	s0,176(sp)
    80005fa0:	74aa                	ld	s1,168(sp)
    80005fa2:	790a                	ld	s2,160(sp)
    80005fa4:	69ea                	ld	s3,152(sp)
    80005fa6:	6129                	addi	sp,sp,192
    80005fa8:	8082                	ret
      end_op();
    80005faa:	fffff097          	auipc	ra,0xfffff
    80005fae:	9be080e7          	jalr	-1602(ra) # 80004968 <end_op>
      return -1;
    80005fb2:	557d                	li	a0,-1
    80005fb4:	b7e5                	j	80005f9c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005fb6:	f5040513          	addi	a0,s0,-176
    80005fba:	ffffe097          	auipc	ra,0xffffe
    80005fbe:	712080e7          	jalr	1810(ra) # 800046cc <namei>
    80005fc2:	84aa                	mv	s1,a0
    80005fc4:	c905                	beqz	a0,80005ff4 <sys_open+0x13c>
    ilock(ip);
    80005fc6:	ffffe097          	auipc	ra,0xffffe
    80005fca:	f60080e7          	jalr	-160(ra) # 80003f26 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005fce:	04449703          	lh	a4,68(s1)
    80005fd2:	4785                	li	a5,1
    80005fd4:	f4f711e3          	bne	a4,a5,80005f16 <sys_open+0x5e>
    80005fd8:	f4c42783          	lw	a5,-180(s0)
    80005fdc:	d7b9                	beqz	a5,80005f2a <sys_open+0x72>
      iunlockput(ip);
    80005fde:	8526                	mv	a0,s1
    80005fe0:	ffffe097          	auipc	ra,0xffffe
    80005fe4:	1a8080e7          	jalr	424(ra) # 80004188 <iunlockput>
      end_op();
    80005fe8:	fffff097          	auipc	ra,0xfffff
    80005fec:	980080e7          	jalr	-1664(ra) # 80004968 <end_op>
      return -1;
    80005ff0:	557d                	li	a0,-1
    80005ff2:	b76d                	j	80005f9c <sys_open+0xe4>
      end_op();
    80005ff4:	fffff097          	auipc	ra,0xfffff
    80005ff8:	974080e7          	jalr	-1676(ra) # 80004968 <end_op>
      return -1;
    80005ffc:	557d                	li	a0,-1
    80005ffe:	bf79                	j	80005f9c <sys_open+0xe4>
    iunlockput(ip);
    80006000:	8526                	mv	a0,s1
    80006002:	ffffe097          	auipc	ra,0xffffe
    80006006:	186080e7          	jalr	390(ra) # 80004188 <iunlockput>
    end_op();
    8000600a:	fffff097          	auipc	ra,0xfffff
    8000600e:	95e080e7          	jalr	-1698(ra) # 80004968 <end_op>
    return -1;
    80006012:	557d                	li	a0,-1
    80006014:	b761                	j	80005f9c <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006016:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000601a:	04649783          	lh	a5,70(s1)
    8000601e:	02f99223          	sh	a5,36(s3)
    80006022:	bf25                	j	80005f5a <sys_open+0xa2>
    itrunc(ip);
    80006024:	8526                	mv	a0,s1
    80006026:	ffffe097          	auipc	ra,0xffffe
    8000602a:	00e080e7          	jalr	14(ra) # 80004034 <itrunc>
    8000602e:	bfa9                	j	80005f88 <sys_open+0xd0>
      fileclose(f);
    80006030:	854e                	mv	a0,s3
    80006032:	fffff097          	auipc	ra,0xfffff
    80006036:	d82080e7          	jalr	-638(ra) # 80004db4 <fileclose>
    iunlockput(ip);
    8000603a:	8526                	mv	a0,s1
    8000603c:	ffffe097          	auipc	ra,0xffffe
    80006040:	14c080e7          	jalr	332(ra) # 80004188 <iunlockput>
    end_op();
    80006044:	fffff097          	auipc	ra,0xfffff
    80006048:	924080e7          	jalr	-1756(ra) # 80004968 <end_op>
    return -1;
    8000604c:	557d                	li	a0,-1
    8000604e:	b7b9                	j	80005f9c <sys_open+0xe4>

0000000080006050 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006050:	7175                	addi	sp,sp,-144
    80006052:	e506                	sd	ra,136(sp)
    80006054:	e122                	sd	s0,128(sp)
    80006056:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006058:	fffff097          	auipc	ra,0xfffff
    8000605c:	890080e7          	jalr	-1904(ra) # 800048e8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006060:	08000613          	li	a2,128
    80006064:	f7040593          	addi	a1,s0,-144
    80006068:	4501                	li	a0,0
    8000606a:	ffffd097          	auipc	ra,0xffffd
    8000606e:	da0080e7          	jalr	-608(ra) # 80002e0a <argstr>
    80006072:	02054963          	bltz	a0,800060a4 <sys_mkdir+0x54>
    80006076:	4681                	li	a3,0
    80006078:	4601                	li	a2,0
    8000607a:	4585                	li	a1,1
    8000607c:	f7040513          	addi	a0,s0,-144
    80006080:	fffff097          	auipc	ra,0xfffff
    80006084:	7fe080e7          	jalr	2046(ra) # 8000587e <create>
    80006088:	cd11                	beqz	a0,800060a4 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000608a:	ffffe097          	auipc	ra,0xffffe
    8000608e:	0fe080e7          	jalr	254(ra) # 80004188 <iunlockput>
  end_op();
    80006092:	fffff097          	auipc	ra,0xfffff
    80006096:	8d6080e7          	jalr	-1834(ra) # 80004968 <end_op>
  return 0;
    8000609a:	4501                	li	a0,0
}
    8000609c:	60aa                	ld	ra,136(sp)
    8000609e:	640a                	ld	s0,128(sp)
    800060a0:	6149                	addi	sp,sp,144
    800060a2:	8082                	ret
    end_op();
    800060a4:	fffff097          	auipc	ra,0xfffff
    800060a8:	8c4080e7          	jalr	-1852(ra) # 80004968 <end_op>
    return -1;
    800060ac:	557d                	li	a0,-1
    800060ae:	b7fd                	j	8000609c <sys_mkdir+0x4c>

00000000800060b0 <sys_mknod>:

uint64
sys_mknod(void)
{
    800060b0:	7135                	addi	sp,sp,-160
    800060b2:	ed06                	sd	ra,152(sp)
    800060b4:	e922                	sd	s0,144(sp)
    800060b6:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800060b8:	fffff097          	auipc	ra,0xfffff
    800060bc:	830080e7          	jalr	-2000(ra) # 800048e8 <begin_op>
  argint(1, &major);
    800060c0:	f6c40593          	addi	a1,s0,-148
    800060c4:	4505                	li	a0,1
    800060c6:	ffffd097          	auipc	ra,0xffffd
    800060ca:	d04080e7          	jalr	-764(ra) # 80002dca <argint>
  argint(2, &minor);
    800060ce:	f6840593          	addi	a1,s0,-152
    800060d2:	4509                	li	a0,2
    800060d4:	ffffd097          	auipc	ra,0xffffd
    800060d8:	cf6080e7          	jalr	-778(ra) # 80002dca <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800060dc:	08000613          	li	a2,128
    800060e0:	f7040593          	addi	a1,s0,-144
    800060e4:	4501                	li	a0,0
    800060e6:	ffffd097          	auipc	ra,0xffffd
    800060ea:	d24080e7          	jalr	-732(ra) # 80002e0a <argstr>
    800060ee:	02054b63          	bltz	a0,80006124 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800060f2:	f6841683          	lh	a3,-152(s0)
    800060f6:	f6c41603          	lh	a2,-148(s0)
    800060fa:	458d                	li	a1,3
    800060fc:	f7040513          	addi	a0,s0,-144
    80006100:	fffff097          	auipc	ra,0xfffff
    80006104:	77e080e7          	jalr	1918(ra) # 8000587e <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006108:	cd11                	beqz	a0,80006124 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000610a:	ffffe097          	auipc	ra,0xffffe
    8000610e:	07e080e7          	jalr	126(ra) # 80004188 <iunlockput>
  end_op();
    80006112:	fffff097          	auipc	ra,0xfffff
    80006116:	856080e7          	jalr	-1962(ra) # 80004968 <end_op>
  return 0;
    8000611a:	4501                	li	a0,0
}
    8000611c:	60ea                	ld	ra,152(sp)
    8000611e:	644a                	ld	s0,144(sp)
    80006120:	610d                	addi	sp,sp,160
    80006122:	8082                	ret
    end_op();
    80006124:	fffff097          	auipc	ra,0xfffff
    80006128:	844080e7          	jalr	-1980(ra) # 80004968 <end_op>
    return -1;
    8000612c:	557d                	li	a0,-1
    8000612e:	b7fd                	j	8000611c <sys_mknod+0x6c>

0000000080006130 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006130:	7135                	addi	sp,sp,-160
    80006132:	ed06                	sd	ra,152(sp)
    80006134:	e922                	sd	s0,144(sp)
    80006136:	e526                	sd	s1,136(sp)
    80006138:	e14a                	sd	s2,128(sp)
    8000613a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000613c:	ffffc097          	auipc	ra,0xffffc
    80006140:	88a080e7          	jalr	-1910(ra) # 800019c6 <myproc>
    80006144:	892a                	mv	s2,a0
  
  begin_op();
    80006146:	ffffe097          	auipc	ra,0xffffe
    8000614a:	7a2080e7          	jalr	1954(ra) # 800048e8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000614e:	08000613          	li	a2,128
    80006152:	f6040593          	addi	a1,s0,-160
    80006156:	4501                	li	a0,0
    80006158:	ffffd097          	auipc	ra,0xffffd
    8000615c:	cb2080e7          	jalr	-846(ra) # 80002e0a <argstr>
    80006160:	04054b63          	bltz	a0,800061b6 <sys_chdir+0x86>
    80006164:	f6040513          	addi	a0,s0,-160
    80006168:	ffffe097          	auipc	ra,0xffffe
    8000616c:	564080e7          	jalr	1380(ra) # 800046cc <namei>
    80006170:	84aa                	mv	s1,a0
    80006172:	c131                	beqz	a0,800061b6 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006174:	ffffe097          	auipc	ra,0xffffe
    80006178:	db2080e7          	jalr	-590(ra) # 80003f26 <ilock>
  if(ip->type != T_DIR){
    8000617c:	04449703          	lh	a4,68(s1)
    80006180:	4785                	li	a5,1
    80006182:	04f71063          	bne	a4,a5,800061c2 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006186:	8526                	mv	a0,s1
    80006188:	ffffe097          	auipc	ra,0xffffe
    8000618c:	e60080e7          	jalr	-416(ra) # 80003fe8 <iunlock>
  iput(p->cwd);
    80006190:	15093503          	ld	a0,336(s2)
    80006194:	ffffe097          	auipc	ra,0xffffe
    80006198:	f4c080e7          	jalr	-180(ra) # 800040e0 <iput>
  end_op();
    8000619c:	ffffe097          	auipc	ra,0xffffe
    800061a0:	7cc080e7          	jalr	1996(ra) # 80004968 <end_op>
  p->cwd = ip;
    800061a4:	14993823          	sd	s1,336(s2)
  return 0;
    800061a8:	4501                	li	a0,0
}
    800061aa:	60ea                	ld	ra,152(sp)
    800061ac:	644a                	ld	s0,144(sp)
    800061ae:	64aa                	ld	s1,136(sp)
    800061b0:	690a                	ld	s2,128(sp)
    800061b2:	610d                	addi	sp,sp,160
    800061b4:	8082                	ret
    end_op();
    800061b6:	ffffe097          	auipc	ra,0xffffe
    800061ba:	7b2080e7          	jalr	1970(ra) # 80004968 <end_op>
    return -1;
    800061be:	557d                	li	a0,-1
    800061c0:	b7ed                	j	800061aa <sys_chdir+0x7a>
    iunlockput(ip);
    800061c2:	8526                	mv	a0,s1
    800061c4:	ffffe097          	auipc	ra,0xffffe
    800061c8:	fc4080e7          	jalr	-60(ra) # 80004188 <iunlockput>
    end_op();
    800061cc:	ffffe097          	auipc	ra,0xffffe
    800061d0:	79c080e7          	jalr	1948(ra) # 80004968 <end_op>
    return -1;
    800061d4:	557d                	li	a0,-1
    800061d6:	bfd1                	j	800061aa <sys_chdir+0x7a>

00000000800061d8 <sys_exec>:

uint64
sys_exec(void)
{
    800061d8:	7145                	addi	sp,sp,-464
    800061da:	e786                	sd	ra,456(sp)
    800061dc:	e3a2                	sd	s0,448(sp)
    800061de:	ff26                	sd	s1,440(sp)
    800061e0:	fb4a                	sd	s2,432(sp)
    800061e2:	f74e                	sd	s3,424(sp)
    800061e4:	f352                	sd	s4,416(sp)
    800061e6:	ef56                	sd	s5,408(sp)
    800061e8:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    800061ea:	e3840593          	addi	a1,s0,-456
    800061ee:	4505                	li	a0,1
    800061f0:	ffffd097          	auipc	ra,0xffffd
    800061f4:	bfa080e7          	jalr	-1030(ra) # 80002dea <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800061f8:	08000613          	li	a2,128
    800061fc:	f4040593          	addi	a1,s0,-192
    80006200:	4501                	li	a0,0
    80006202:	ffffd097          	auipc	ra,0xffffd
    80006206:	c08080e7          	jalr	-1016(ra) # 80002e0a <argstr>
    8000620a:	87aa                	mv	a5,a0
    return -1;
    8000620c:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    8000620e:	0c07c263          	bltz	a5,800062d2 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006212:	10000613          	li	a2,256
    80006216:	4581                	li	a1,0
    80006218:	e4040513          	addi	a0,s0,-448
    8000621c:	ffffb097          	auipc	ra,0xffffb
    80006220:	aca080e7          	jalr	-1334(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006224:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006228:	89a6                	mv	s3,s1
    8000622a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000622c:	02000a13          	li	s4,32
    80006230:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006234:	00391513          	slli	a0,s2,0x3
    80006238:	e3040593          	addi	a1,s0,-464
    8000623c:	e3843783          	ld	a5,-456(s0)
    80006240:	953e                	add	a0,a0,a5
    80006242:	ffffd097          	auipc	ra,0xffffd
    80006246:	aea080e7          	jalr	-1302(ra) # 80002d2c <fetchaddr>
    8000624a:	02054a63          	bltz	a0,8000627e <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    8000624e:	e3043783          	ld	a5,-464(s0)
    80006252:	c3b9                	beqz	a5,80006298 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006254:	ffffb097          	auipc	ra,0xffffb
    80006258:	8a6080e7          	jalr	-1882(ra) # 80000afa <kalloc>
    8000625c:	85aa                	mv	a1,a0
    8000625e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006262:	cd11                	beqz	a0,8000627e <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006264:	6605                	lui	a2,0x1
    80006266:	e3043503          	ld	a0,-464(s0)
    8000626a:	ffffd097          	auipc	ra,0xffffd
    8000626e:	b14080e7          	jalr	-1260(ra) # 80002d7e <fetchstr>
    80006272:	00054663          	bltz	a0,8000627e <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80006276:	0905                	addi	s2,s2,1
    80006278:	09a1                	addi	s3,s3,8
    8000627a:	fb491be3          	bne	s2,s4,80006230 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000627e:	10048913          	addi	s2,s1,256
    80006282:	6088                	ld	a0,0(s1)
    80006284:	c531                	beqz	a0,800062d0 <sys_exec+0xf8>
    kfree(argv[i]);
    80006286:	ffffa097          	auipc	ra,0xffffa
    8000628a:	778080e7          	jalr	1912(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000628e:	04a1                	addi	s1,s1,8
    80006290:	ff2499e3          	bne	s1,s2,80006282 <sys_exec+0xaa>
  return -1;
    80006294:	557d                	li	a0,-1
    80006296:	a835                	j	800062d2 <sys_exec+0xfa>
      argv[i] = 0;
    80006298:	0a8e                	slli	s5,s5,0x3
    8000629a:	fc040793          	addi	a5,s0,-64
    8000629e:	9abe                	add	s5,s5,a5
    800062a0:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800062a4:	e4040593          	addi	a1,s0,-448
    800062a8:	f4040513          	addi	a0,s0,-192
    800062ac:	fffff097          	auipc	ra,0xfffff
    800062b0:	190080e7          	jalr	400(ra) # 8000543c <exec>
    800062b4:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800062b6:	10048993          	addi	s3,s1,256
    800062ba:	6088                	ld	a0,0(s1)
    800062bc:	c901                	beqz	a0,800062cc <sys_exec+0xf4>
    kfree(argv[i]);
    800062be:	ffffa097          	auipc	ra,0xffffa
    800062c2:	740080e7          	jalr	1856(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800062c6:	04a1                	addi	s1,s1,8
    800062c8:	ff3499e3          	bne	s1,s3,800062ba <sys_exec+0xe2>
  return ret;
    800062cc:	854a                	mv	a0,s2
    800062ce:	a011                	j	800062d2 <sys_exec+0xfa>
  return -1;
    800062d0:	557d                	li	a0,-1
}
    800062d2:	60be                	ld	ra,456(sp)
    800062d4:	641e                	ld	s0,448(sp)
    800062d6:	74fa                	ld	s1,440(sp)
    800062d8:	795a                	ld	s2,432(sp)
    800062da:	79ba                	ld	s3,424(sp)
    800062dc:	7a1a                	ld	s4,416(sp)
    800062de:	6afa                	ld	s5,408(sp)
    800062e0:	6179                	addi	sp,sp,464
    800062e2:	8082                	ret

00000000800062e4 <sys_pipe>:

uint64
sys_pipe(void)
{
    800062e4:	7139                	addi	sp,sp,-64
    800062e6:	fc06                	sd	ra,56(sp)
    800062e8:	f822                	sd	s0,48(sp)
    800062ea:	f426                	sd	s1,40(sp)
    800062ec:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800062ee:	ffffb097          	auipc	ra,0xffffb
    800062f2:	6d8080e7          	jalr	1752(ra) # 800019c6 <myproc>
    800062f6:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800062f8:	fd840593          	addi	a1,s0,-40
    800062fc:	4501                	li	a0,0
    800062fe:	ffffd097          	auipc	ra,0xffffd
    80006302:	aec080e7          	jalr	-1300(ra) # 80002dea <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006306:	fc840593          	addi	a1,s0,-56
    8000630a:	fd040513          	addi	a0,s0,-48
    8000630e:	fffff097          	auipc	ra,0xfffff
    80006312:	dd6080e7          	jalr	-554(ra) # 800050e4 <pipealloc>
    return -1;
    80006316:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006318:	0c054463          	bltz	a0,800063e0 <sys_pipe+0xfc>
  fd0 = -1;
    8000631c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006320:	fd043503          	ld	a0,-48(s0)
    80006324:	fffff097          	auipc	ra,0xfffff
    80006328:	518080e7          	jalr	1304(ra) # 8000583c <fdalloc>
    8000632c:	fca42223          	sw	a0,-60(s0)
    80006330:	08054b63          	bltz	a0,800063c6 <sys_pipe+0xe2>
    80006334:	fc843503          	ld	a0,-56(s0)
    80006338:	fffff097          	auipc	ra,0xfffff
    8000633c:	504080e7          	jalr	1284(ra) # 8000583c <fdalloc>
    80006340:	fca42023          	sw	a0,-64(s0)
    80006344:	06054863          	bltz	a0,800063b4 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006348:	4691                	li	a3,4
    8000634a:	fc440613          	addi	a2,s0,-60
    8000634e:	fd843583          	ld	a1,-40(s0)
    80006352:	68a8                	ld	a0,80(s1)
    80006354:	ffffb097          	auipc	ra,0xffffb
    80006358:	330080e7          	jalr	816(ra) # 80001684 <copyout>
    8000635c:	02054063          	bltz	a0,8000637c <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006360:	4691                	li	a3,4
    80006362:	fc040613          	addi	a2,s0,-64
    80006366:	fd843583          	ld	a1,-40(s0)
    8000636a:	0591                	addi	a1,a1,4
    8000636c:	68a8                	ld	a0,80(s1)
    8000636e:	ffffb097          	auipc	ra,0xffffb
    80006372:	316080e7          	jalr	790(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006376:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006378:	06055463          	bgez	a0,800063e0 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    8000637c:	fc442783          	lw	a5,-60(s0)
    80006380:	07e9                	addi	a5,a5,26
    80006382:	078e                	slli	a5,a5,0x3
    80006384:	97a6                	add	a5,a5,s1
    80006386:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000638a:	fc042503          	lw	a0,-64(s0)
    8000638e:	0569                	addi	a0,a0,26
    80006390:	050e                	slli	a0,a0,0x3
    80006392:	94aa                	add	s1,s1,a0
    80006394:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006398:	fd043503          	ld	a0,-48(s0)
    8000639c:	fffff097          	auipc	ra,0xfffff
    800063a0:	a18080e7          	jalr	-1512(ra) # 80004db4 <fileclose>
    fileclose(wf);
    800063a4:	fc843503          	ld	a0,-56(s0)
    800063a8:	fffff097          	auipc	ra,0xfffff
    800063ac:	a0c080e7          	jalr	-1524(ra) # 80004db4 <fileclose>
    return -1;
    800063b0:	57fd                	li	a5,-1
    800063b2:	a03d                	j	800063e0 <sys_pipe+0xfc>
    if(fd0 >= 0)
    800063b4:	fc442783          	lw	a5,-60(s0)
    800063b8:	0007c763          	bltz	a5,800063c6 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    800063bc:	07e9                	addi	a5,a5,26
    800063be:	078e                	slli	a5,a5,0x3
    800063c0:	94be                	add	s1,s1,a5
    800063c2:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800063c6:	fd043503          	ld	a0,-48(s0)
    800063ca:	fffff097          	auipc	ra,0xfffff
    800063ce:	9ea080e7          	jalr	-1558(ra) # 80004db4 <fileclose>
    fileclose(wf);
    800063d2:	fc843503          	ld	a0,-56(s0)
    800063d6:	fffff097          	auipc	ra,0xfffff
    800063da:	9de080e7          	jalr	-1570(ra) # 80004db4 <fileclose>
    return -1;
    800063de:	57fd                	li	a5,-1
}
    800063e0:	853e                	mv	a0,a5
    800063e2:	70e2                	ld	ra,56(sp)
    800063e4:	7442                	ld	s0,48(sp)
    800063e6:	74a2                	ld	s1,40(sp)
    800063e8:	6121                	addi	sp,sp,64
    800063ea:	8082                	ret
    800063ec:	0000                	unimp
	...

00000000800063f0 <kernelvec>:
    800063f0:	7111                	addi	sp,sp,-256
    800063f2:	e006                	sd	ra,0(sp)
    800063f4:	e40a                	sd	sp,8(sp)
    800063f6:	e80e                	sd	gp,16(sp)
    800063f8:	ec12                	sd	tp,24(sp)
    800063fa:	f016                	sd	t0,32(sp)
    800063fc:	f41a                	sd	t1,40(sp)
    800063fe:	f81e                	sd	t2,48(sp)
    80006400:	fc22                	sd	s0,56(sp)
    80006402:	e0a6                	sd	s1,64(sp)
    80006404:	e4aa                	sd	a0,72(sp)
    80006406:	e8ae                	sd	a1,80(sp)
    80006408:	ecb2                	sd	a2,88(sp)
    8000640a:	f0b6                	sd	a3,96(sp)
    8000640c:	f4ba                	sd	a4,104(sp)
    8000640e:	f8be                	sd	a5,112(sp)
    80006410:	fcc2                	sd	a6,120(sp)
    80006412:	e146                	sd	a7,128(sp)
    80006414:	e54a                	sd	s2,136(sp)
    80006416:	e94e                	sd	s3,144(sp)
    80006418:	ed52                	sd	s4,152(sp)
    8000641a:	f156                	sd	s5,160(sp)
    8000641c:	f55a                	sd	s6,168(sp)
    8000641e:	f95e                	sd	s7,176(sp)
    80006420:	fd62                	sd	s8,184(sp)
    80006422:	e1e6                	sd	s9,192(sp)
    80006424:	e5ea                	sd	s10,200(sp)
    80006426:	e9ee                	sd	s11,208(sp)
    80006428:	edf2                	sd	t3,216(sp)
    8000642a:	f1f6                	sd	t4,224(sp)
    8000642c:	f5fa                	sd	t5,232(sp)
    8000642e:	f9fe                	sd	t6,240(sp)
    80006430:	ff2fc0ef          	jal	ra,80002c22 <kerneltrap>
    80006434:	6082                	ld	ra,0(sp)
    80006436:	6122                	ld	sp,8(sp)
    80006438:	61c2                	ld	gp,16(sp)
    8000643a:	7282                	ld	t0,32(sp)
    8000643c:	7322                	ld	t1,40(sp)
    8000643e:	73c2                	ld	t2,48(sp)
    80006440:	7462                	ld	s0,56(sp)
    80006442:	6486                	ld	s1,64(sp)
    80006444:	6526                	ld	a0,72(sp)
    80006446:	65c6                	ld	a1,80(sp)
    80006448:	6666                	ld	a2,88(sp)
    8000644a:	7686                	ld	a3,96(sp)
    8000644c:	7726                	ld	a4,104(sp)
    8000644e:	77c6                	ld	a5,112(sp)
    80006450:	7866                	ld	a6,120(sp)
    80006452:	688a                	ld	a7,128(sp)
    80006454:	692a                	ld	s2,136(sp)
    80006456:	69ca                	ld	s3,144(sp)
    80006458:	6a6a                	ld	s4,152(sp)
    8000645a:	7a8a                	ld	s5,160(sp)
    8000645c:	7b2a                	ld	s6,168(sp)
    8000645e:	7bca                	ld	s7,176(sp)
    80006460:	7c6a                	ld	s8,184(sp)
    80006462:	6c8e                	ld	s9,192(sp)
    80006464:	6d2e                	ld	s10,200(sp)
    80006466:	6dce                	ld	s11,208(sp)
    80006468:	6e6e                	ld	t3,216(sp)
    8000646a:	7e8e                	ld	t4,224(sp)
    8000646c:	7f2e                	ld	t5,232(sp)
    8000646e:	7fce                	ld	t6,240(sp)
    80006470:	6111                	addi	sp,sp,256
    80006472:	10200073          	sret
    80006476:	00000013          	nop
    8000647a:	00000013          	nop
    8000647e:	0001                	nop

0000000080006480 <timervec>:
    80006480:	34051573          	csrrw	a0,mscratch,a0
    80006484:	e10c                	sd	a1,0(a0)
    80006486:	e510                	sd	a2,8(a0)
    80006488:	e914                	sd	a3,16(a0)
    8000648a:	6d0c                	ld	a1,24(a0)
    8000648c:	7110                	ld	a2,32(a0)
    8000648e:	6194                	ld	a3,0(a1)
    80006490:	96b2                	add	a3,a3,a2
    80006492:	e194                	sd	a3,0(a1)
    80006494:	4589                	li	a1,2
    80006496:	14459073          	csrw	sip,a1
    8000649a:	6914                	ld	a3,16(a0)
    8000649c:	6510                	ld	a2,8(a0)
    8000649e:	610c                	ld	a1,0(a0)
    800064a0:	34051573          	csrrw	a0,mscratch,a0
    800064a4:	30200073          	mret
	...

00000000800064aa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800064aa:	1141                	addi	sp,sp,-16
    800064ac:	e422                	sd	s0,8(sp)
    800064ae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800064b0:	0c0007b7          	lui	a5,0xc000
    800064b4:	4705                	li	a4,1
    800064b6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800064b8:	c3d8                	sw	a4,4(a5)
}
    800064ba:	6422                	ld	s0,8(sp)
    800064bc:	0141                	addi	sp,sp,16
    800064be:	8082                	ret

00000000800064c0 <plicinithart>:

void
plicinithart(void)
{
    800064c0:	1141                	addi	sp,sp,-16
    800064c2:	e406                	sd	ra,8(sp)
    800064c4:	e022                	sd	s0,0(sp)
    800064c6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800064c8:	ffffb097          	auipc	ra,0xffffb
    800064cc:	4d2080e7          	jalr	1234(ra) # 8000199a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800064d0:	0085171b          	slliw	a4,a0,0x8
    800064d4:	0c0027b7          	lui	a5,0xc002
    800064d8:	97ba                	add	a5,a5,a4
    800064da:	40200713          	li	a4,1026
    800064de:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800064e2:	00d5151b          	slliw	a0,a0,0xd
    800064e6:	0c2017b7          	lui	a5,0xc201
    800064ea:	953e                	add	a0,a0,a5
    800064ec:	00052023          	sw	zero,0(a0)
}
    800064f0:	60a2                	ld	ra,8(sp)
    800064f2:	6402                	ld	s0,0(sp)
    800064f4:	0141                	addi	sp,sp,16
    800064f6:	8082                	ret

00000000800064f8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800064f8:	1141                	addi	sp,sp,-16
    800064fa:	e406                	sd	ra,8(sp)
    800064fc:	e022                	sd	s0,0(sp)
    800064fe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006500:	ffffb097          	auipc	ra,0xffffb
    80006504:	49a080e7          	jalr	1178(ra) # 8000199a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006508:	00d5179b          	slliw	a5,a0,0xd
    8000650c:	0c201537          	lui	a0,0xc201
    80006510:	953e                	add	a0,a0,a5
  return irq;
}
    80006512:	4148                	lw	a0,4(a0)
    80006514:	60a2                	ld	ra,8(sp)
    80006516:	6402                	ld	s0,0(sp)
    80006518:	0141                	addi	sp,sp,16
    8000651a:	8082                	ret

000000008000651c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000651c:	1101                	addi	sp,sp,-32
    8000651e:	ec06                	sd	ra,24(sp)
    80006520:	e822                	sd	s0,16(sp)
    80006522:	e426                	sd	s1,8(sp)
    80006524:	1000                	addi	s0,sp,32
    80006526:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006528:	ffffb097          	auipc	ra,0xffffb
    8000652c:	472080e7          	jalr	1138(ra) # 8000199a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006530:	00d5151b          	slliw	a0,a0,0xd
    80006534:	0c2017b7          	lui	a5,0xc201
    80006538:	97aa                	add	a5,a5,a0
    8000653a:	c3c4                	sw	s1,4(a5)
}
    8000653c:	60e2                	ld	ra,24(sp)
    8000653e:	6442                	ld	s0,16(sp)
    80006540:	64a2                	ld	s1,8(sp)
    80006542:	6105                	addi	sp,sp,32
    80006544:	8082                	ret

0000000080006546 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006546:	1141                	addi	sp,sp,-16
    80006548:	e406                	sd	ra,8(sp)
    8000654a:	e022                	sd	s0,0(sp)
    8000654c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000654e:	479d                	li	a5,7
    80006550:	04a7cc63          	blt	a5,a0,800065a8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006554:	0001d797          	auipc	a5,0x1d
    80006558:	15c78793          	addi	a5,a5,348 # 800236b0 <disk>
    8000655c:	97aa                	add	a5,a5,a0
    8000655e:	0187c783          	lbu	a5,24(a5)
    80006562:	ebb9                	bnez	a5,800065b8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006564:	00451613          	slli	a2,a0,0x4
    80006568:	0001d797          	auipc	a5,0x1d
    8000656c:	14878793          	addi	a5,a5,328 # 800236b0 <disk>
    80006570:	6394                	ld	a3,0(a5)
    80006572:	96b2                	add	a3,a3,a2
    80006574:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006578:	6398                	ld	a4,0(a5)
    8000657a:	9732                	add	a4,a4,a2
    8000657c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006580:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006584:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006588:	953e                	add	a0,a0,a5
    8000658a:	4785                	li	a5,1
    8000658c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80006590:	0001d517          	auipc	a0,0x1d
    80006594:	13850513          	addi	a0,a0,312 # 800236c8 <disk+0x18>
    80006598:	ffffc097          	auipc	ra,0xffffc
    8000659c:	d98080e7          	jalr	-616(ra) # 80002330 <wakeup>
}
    800065a0:	60a2                	ld	ra,8(sp)
    800065a2:	6402                	ld	s0,0(sp)
    800065a4:	0141                	addi	sp,sp,16
    800065a6:	8082                	ret
    panic("free_desc 1");
    800065a8:	00002517          	auipc	a0,0x2
    800065ac:	33850513          	addi	a0,a0,824 # 800088e0 <syscalls+0x318>
    800065b0:	ffffa097          	auipc	ra,0xffffa
    800065b4:	f94080e7          	jalr	-108(ra) # 80000544 <panic>
    panic("free_desc 2");
    800065b8:	00002517          	auipc	a0,0x2
    800065bc:	33850513          	addi	a0,a0,824 # 800088f0 <syscalls+0x328>
    800065c0:	ffffa097          	auipc	ra,0xffffa
    800065c4:	f84080e7          	jalr	-124(ra) # 80000544 <panic>

00000000800065c8 <virtio_disk_init>:
{
    800065c8:	1101                	addi	sp,sp,-32
    800065ca:	ec06                	sd	ra,24(sp)
    800065cc:	e822                	sd	s0,16(sp)
    800065ce:	e426                	sd	s1,8(sp)
    800065d0:	e04a                	sd	s2,0(sp)
    800065d2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800065d4:	00002597          	auipc	a1,0x2
    800065d8:	32c58593          	addi	a1,a1,812 # 80008900 <syscalls+0x338>
    800065dc:	0001d517          	auipc	a0,0x1d
    800065e0:	1fc50513          	addi	a0,a0,508 # 800237d8 <disk+0x128>
    800065e4:	ffffa097          	auipc	ra,0xffffa
    800065e8:	576080e7          	jalr	1398(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800065ec:	100017b7          	lui	a5,0x10001
    800065f0:	4398                	lw	a4,0(a5)
    800065f2:	2701                	sext.w	a4,a4
    800065f4:	747277b7          	lui	a5,0x74727
    800065f8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800065fc:	14f71e63          	bne	a4,a5,80006758 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006600:	100017b7          	lui	a5,0x10001
    80006604:	43dc                	lw	a5,4(a5)
    80006606:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006608:	4709                	li	a4,2
    8000660a:	14e79763          	bne	a5,a4,80006758 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000660e:	100017b7          	lui	a5,0x10001
    80006612:	479c                	lw	a5,8(a5)
    80006614:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006616:	14e79163          	bne	a5,a4,80006758 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000661a:	100017b7          	lui	a5,0x10001
    8000661e:	47d8                	lw	a4,12(a5)
    80006620:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006622:	554d47b7          	lui	a5,0x554d4
    80006626:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000662a:	12f71763          	bne	a4,a5,80006758 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000662e:	100017b7          	lui	a5,0x10001
    80006632:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006636:	4705                	li	a4,1
    80006638:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000663a:	470d                	li	a4,3
    8000663c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000663e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006640:	c7ffe737          	lui	a4,0xc7ffe
    80006644:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd9bef>
    80006648:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000664a:	2701                	sext.w	a4,a4
    8000664c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000664e:	472d                	li	a4,11
    80006650:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006652:	0707a903          	lw	s2,112(a5)
    80006656:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006658:	00897793          	andi	a5,s2,8
    8000665c:	10078663          	beqz	a5,80006768 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006660:	100017b7          	lui	a5,0x10001
    80006664:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006668:	43fc                	lw	a5,68(a5)
    8000666a:	2781                	sext.w	a5,a5
    8000666c:	10079663          	bnez	a5,80006778 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006670:	100017b7          	lui	a5,0x10001
    80006674:	5bdc                	lw	a5,52(a5)
    80006676:	2781                	sext.w	a5,a5
  if(max == 0)
    80006678:	10078863          	beqz	a5,80006788 <virtio_disk_init+0x1c0>
  if(max < NUM)
    8000667c:	471d                	li	a4,7
    8000667e:	10f77d63          	bgeu	a4,a5,80006798 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80006682:	ffffa097          	auipc	ra,0xffffa
    80006686:	478080e7          	jalr	1144(ra) # 80000afa <kalloc>
    8000668a:	0001d497          	auipc	s1,0x1d
    8000668e:	02648493          	addi	s1,s1,38 # 800236b0 <disk>
    80006692:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006694:	ffffa097          	auipc	ra,0xffffa
    80006698:	466080e7          	jalr	1126(ra) # 80000afa <kalloc>
    8000669c:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000669e:	ffffa097          	auipc	ra,0xffffa
    800066a2:	45c080e7          	jalr	1116(ra) # 80000afa <kalloc>
    800066a6:	87aa                	mv	a5,a0
    800066a8:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800066aa:	6088                	ld	a0,0(s1)
    800066ac:	cd75                	beqz	a0,800067a8 <virtio_disk_init+0x1e0>
    800066ae:	0001d717          	auipc	a4,0x1d
    800066b2:	00a73703          	ld	a4,10(a4) # 800236b8 <disk+0x8>
    800066b6:	cb6d                	beqz	a4,800067a8 <virtio_disk_init+0x1e0>
    800066b8:	cbe5                	beqz	a5,800067a8 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    800066ba:	6605                	lui	a2,0x1
    800066bc:	4581                	li	a1,0
    800066be:	ffffa097          	auipc	ra,0xffffa
    800066c2:	628080e7          	jalr	1576(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    800066c6:	0001d497          	auipc	s1,0x1d
    800066ca:	fea48493          	addi	s1,s1,-22 # 800236b0 <disk>
    800066ce:	6605                	lui	a2,0x1
    800066d0:	4581                	li	a1,0
    800066d2:	6488                	ld	a0,8(s1)
    800066d4:	ffffa097          	auipc	ra,0xffffa
    800066d8:	612080e7          	jalr	1554(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    800066dc:	6605                	lui	a2,0x1
    800066de:	4581                	li	a1,0
    800066e0:	6888                	ld	a0,16(s1)
    800066e2:	ffffa097          	auipc	ra,0xffffa
    800066e6:	604080e7          	jalr	1540(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800066ea:	100017b7          	lui	a5,0x10001
    800066ee:	4721                	li	a4,8
    800066f0:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800066f2:	4098                	lw	a4,0(s1)
    800066f4:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800066f8:	40d8                	lw	a4,4(s1)
    800066fa:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800066fe:	6498                	ld	a4,8(s1)
    80006700:	0007069b          	sext.w	a3,a4
    80006704:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006708:	9701                	srai	a4,a4,0x20
    8000670a:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000670e:	6898                	ld	a4,16(s1)
    80006710:	0007069b          	sext.w	a3,a4
    80006714:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006718:	9701                	srai	a4,a4,0x20
    8000671a:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000671e:	4685                	li	a3,1
    80006720:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80006722:	4705                	li	a4,1
    80006724:	00d48c23          	sb	a3,24(s1)
    80006728:	00e48ca3          	sb	a4,25(s1)
    8000672c:	00e48d23          	sb	a4,26(s1)
    80006730:	00e48da3          	sb	a4,27(s1)
    80006734:	00e48e23          	sb	a4,28(s1)
    80006738:	00e48ea3          	sb	a4,29(s1)
    8000673c:	00e48f23          	sb	a4,30(s1)
    80006740:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006744:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006748:	0727a823          	sw	s2,112(a5)
}
    8000674c:	60e2                	ld	ra,24(sp)
    8000674e:	6442                	ld	s0,16(sp)
    80006750:	64a2                	ld	s1,8(sp)
    80006752:	6902                	ld	s2,0(sp)
    80006754:	6105                	addi	sp,sp,32
    80006756:	8082                	ret
    panic("could not find virtio disk");
    80006758:	00002517          	auipc	a0,0x2
    8000675c:	1b850513          	addi	a0,a0,440 # 80008910 <syscalls+0x348>
    80006760:	ffffa097          	auipc	ra,0xffffa
    80006764:	de4080e7          	jalr	-540(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006768:	00002517          	auipc	a0,0x2
    8000676c:	1c850513          	addi	a0,a0,456 # 80008930 <syscalls+0x368>
    80006770:	ffffa097          	auipc	ra,0xffffa
    80006774:	dd4080e7          	jalr	-556(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80006778:	00002517          	auipc	a0,0x2
    8000677c:	1d850513          	addi	a0,a0,472 # 80008950 <syscalls+0x388>
    80006780:	ffffa097          	auipc	ra,0xffffa
    80006784:	dc4080e7          	jalr	-572(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80006788:	00002517          	auipc	a0,0x2
    8000678c:	1e850513          	addi	a0,a0,488 # 80008970 <syscalls+0x3a8>
    80006790:	ffffa097          	auipc	ra,0xffffa
    80006794:	db4080e7          	jalr	-588(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    80006798:	00002517          	auipc	a0,0x2
    8000679c:	1f850513          	addi	a0,a0,504 # 80008990 <syscalls+0x3c8>
    800067a0:	ffffa097          	auipc	ra,0xffffa
    800067a4:	da4080e7          	jalr	-604(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    800067a8:	00002517          	auipc	a0,0x2
    800067ac:	20850513          	addi	a0,a0,520 # 800089b0 <syscalls+0x3e8>
    800067b0:	ffffa097          	auipc	ra,0xffffa
    800067b4:	d94080e7          	jalr	-620(ra) # 80000544 <panic>

00000000800067b8 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800067b8:	7159                	addi	sp,sp,-112
    800067ba:	f486                	sd	ra,104(sp)
    800067bc:	f0a2                	sd	s0,96(sp)
    800067be:	eca6                	sd	s1,88(sp)
    800067c0:	e8ca                	sd	s2,80(sp)
    800067c2:	e4ce                	sd	s3,72(sp)
    800067c4:	e0d2                	sd	s4,64(sp)
    800067c6:	fc56                	sd	s5,56(sp)
    800067c8:	f85a                	sd	s6,48(sp)
    800067ca:	f45e                	sd	s7,40(sp)
    800067cc:	f062                	sd	s8,32(sp)
    800067ce:	ec66                	sd	s9,24(sp)
    800067d0:	e86a                	sd	s10,16(sp)
    800067d2:	1880                	addi	s0,sp,112
    800067d4:	892a                	mv	s2,a0
    800067d6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800067d8:	00c52c83          	lw	s9,12(a0)
    800067dc:	001c9c9b          	slliw	s9,s9,0x1
    800067e0:	1c82                	slli	s9,s9,0x20
    800067e2:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800067e6:	0001d517          	auipc	a0,0x1d
    800067ea:	ff250513          	addi	a0,a0,-14 # 800237d8 <disk+0x128>
    800067ee:	ffffa097          	auipc	ra,0xffffa
    800067f2:	3fc080e7          	jalr	1020(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    800067f6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800067f8:	4ba1                	li	s7,8
      disk.free[i] = 0;
    800067fa:	0001db17          	auipc	s6,0x1d
    800067fe:	eb6b0b13          	addi	s6,s6,-330 # 800236b0 <disk>
  for(int i = 0; i < 3; i++){
    80006802:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006804:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006806:	0001dc17          	auipc	s8,0x1d
    8000680a:	fd2c0c13          	addi	s8,s8,-46 # 800237d8 <disk+0x128>
    8000680e:	a8b5                	j	8000688a <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    80006810:	00fb06b3          	add	a3,s6,a5
    80006814:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006818:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000681a:	0207c563          	bltz	a5,80006844 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000681e:	2485                	addiw	s1,s1,1
    80006820:	0711                	addi	a4,a4,4
    80006822:	1f548a63          	beq	s1,s5,80006a16 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    80006826:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006828:	0001d697          	auipc	a3,0x1d
    8000682c:	e8868693          	addi	a3,a3,-376 # 800236b0 <disk>
    80006830:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006832:	0186c583          	lbu	a1,24(a3)
    80006836:	fde9                	bnez	a1,80006810 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006838:	2785                	addiw	a5,a5,1
    8000683a:	0685                	addi	a3,a3,1
    8000683c:	ff779be3          	bne	a5,s7,80006832 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006840:	57fd                	li	a5,-1
    80006842:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006844:	02905a63          	blez	s1,80006878 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006848:	f9042503          	lw	a0,-112(s0)
    8000684c:	00000097          	auipc	ra,0x0
    80006850:	cfa080e7          	jalr	-774(ra) # 80006546 <free_desc>
      for(int j = 0; j < i; j++)
    80006854:	4785                	li	a5,1
    80006856:	0297d163          	bge	a5,s1,80006878 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000685a:	f9442503          	lw	a0,-108(s0)
    8000685e:	00000097          	auipc	ra,0x0
    80006862:	ce8080e7          	jalr	-792(ra) # 80006546 <free_desc>
      for(int j = 0; j < i; j++)
    80006866:	4789                	li	a5,2
    80006868:	0097d863          	bge	a5,s1,80006878 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000686c:	f9842503          	lw	a0,-104(s0)
    80006870:	00000097          	auipc	ra,0x0
    80006874:	cd6080e7          	jalr	-810(ra) # 80006546 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006878:	85e2                	mv	a1,s8
    8000687a:	0001d517          	auipc	a0,0x1d
    8000687e:	e4e50513          	addi	a0,a0,-434 # 800236c8 <disk+0x18>
    80006882:	ffffc097          	auipc	ra,0xffffc
    80006886:	8fe080e7          	jalr	-1794(ra) # 80002180 <sleep>
  for(int i = 0; i < 3; i++){
    8000688a:	f9040713          	addi	a4,s0,-112
    8000688e:	84ce                	mv	s1,s3
    80006890:	bf59                	j	80006826 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006892:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    80006896:	00479693          	slli	a3,a5,0x4
    8000689a:	0001d797          	auipc	a5,0x1d
    8000689e:	e1678793          	addi	a5,a5,-490 # 800236b0 <disk>
    800068a2:	97b6                	add	a5,a5,a3
    800068a4:	4685                	li	a3,1
    800068a6:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800068a8:	0001d597          	auipc	a1,0x1d
    800068ac:	e0858593          	addi	a1,a1,-504 # 800236b0 <disk>
    800068b0:	00a60793          	addi	a5,a2,10
    800068b4:	0792                	slli	a5,a5,0x4
    800068b6:	97ae                	add	a5,a5,a1
    800068b8:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    800068bc:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800068c0:	f6070693          	addi	a3,a4,-160
    800068c4:	619c                	ld	a5,0(a1)
    800068c6:	97b6                	add	a5,a5,a3
    800068c8:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800068ca:	6188                	ld	a0,0(a1)
    800068cc:	96aa                	add	a3,a3,a0
    800068ce:	47c1                	li	a5,16
    800068d0:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800068d2:	4785                	li	a5,1
    800068d4:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    800068d8:	f9442783          	lw	a5,-108(s0)
    800068dc:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800068e0:	0792                	slli	a5,a5,0x4
    800068e2:	953e                	add	a0,a0,a5
    800068e4:	05890693          	addi	a3,s2,88
    800068e8:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    800068ea:	6188                	ld	a0,0(a1)
    800068ec:	97aa                	add	a5,a5,a0
    800068ee:	40000693          	li	a3,1024
    800068f2:	c794                	sw	a3,8(a5)
  if(write)
    800068f4:	100d0d63          	beqz	s10,80006a0e <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800068f8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800068fc:	00c7d683          	lhu	a3,12(a5)
    80006900:	0016e693          	ori	a3,a3,1
    80006904:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    80006908:	f9842583          	lw	a1,-104(s0)
    8000690c:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006910:	0001d697          	auipc	a3,0x1d
    80006914:	da068693          	addi	a3,a3,-608 # 800236b0 <disk>
    80006918:	00260793          	addi	a5,a2,2
    8000691c:	0792                	slli	a5,a5,0x4
    8000691e:	97b6                	add	a5,a5,a3
    80006920:	587d                	li	a6,-1
    80006922:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006926:	0592                	slli	a1,a1,0x4
    80006928:	952e                	add	a0,a0,a1
    8000692a:	f9070713          	addi	a4,a4,-112
    8000692e:	9736                	add	a4,a4,a3
    80006930:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    80006932:	6298                	ld	a4,0(a3)
    80006934:	972e                	add	a4,a4,a1
    80006936:	4585                	li	a1,1
    80006938:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000693a:	4509                	li	a0,2
    8000693c:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    80006940:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006944:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006948:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    8000694c:	6698                	ld	a4,8(a3)
    8000694e:	00275783          	lhu	a5,2(a4)
    80006952:	8b9d                	andi	a5,a5,7
    80006954:	0786                	slli	a5,a5,0x1
    80006956:	97ba                	add	a5,a5,a4
    80006958:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    8000695c:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006960:	6698                	ld	a4,8(a3)
    80006962:	00275783          	lhu	a5,2(a4)
    80006966:	2785                	addiw	a5,a5,1
    80006968:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    8000696c:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006970:	100017b7          	lui	a5,0x10001
    80006974:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006978:	00492703          	lw	a4,4(s2)
    8000697c:	4785                	li	a5,1
    8000697e:	02f71163          	bne	a4,a5,800069a0 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    80006982:	0001d997          	auipc	s3,0x1d
    80006986:	e5698993          	addi	s3,s3,-426 # 800237d8 <disk+0x128>
  while(b->disk == 1) {
    8000698a:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000698c:	85ce                	mv	a1,s3
    8000698e:	854a                	mv	a0,s2
    80006990:	ffffb097          	auipc	ra,0xffffb
    80006994:	7f0080e7          	jalr	2032(ra) # 80002180 <sleep>
  while(b->disk == 1) {
    80006998:	00492783          	lw	a5,4(s2)
    8000699c:	fe9788e3          	beq	a5,s1,8000698c <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    800069a0:	f9042903          	lw	s2,-112(s0)
    800069a4:	00290793          	addi	a5,s2,2
    800069a8:	00479713          	slli	a4,a5,0x4
    800069ac:	0001d797          	auipc	a5,0x1d
    800069b0:	d0478793          	addi	a5,a5,-764 # 800236b0 <disk>
    800069b4:	97ba                	add	a5,a5,a4
    800069b6:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800069ba:	0001d997          	auipc	s3,0x1d
    800069be:	cf698993          	addi	s3,s3,-778 # 800236b0 <disk>
    800069c2:	00491713          	slli	a4,s2,0x4
    800069c6:	0009b783          	ld	a5,0(s3)
    800069ca:	97ba                	add	a5,a5,a4
    800069cc:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800069d0:	854a                	mv	a0,s2
    800069d2:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800069d6:	00000097          	auipc	ra,0x0
    800069da:	b70080e7          	jalr	-1168(ra) # 80006546 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800069de:	8885                	andi	s1,s1,1
    800069e0:	f0ed                	bnez	s1,800069c2 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800069e2:	0001d517          	auipc	a0,0x1d
    800069e6:	df650513          	addi	a0,a0,-522 # 800237d8 <disk+0x128>
    800069ea:	ffffa097          	auipc	ra,0xffffa
    800069ee:	2b4080e7          	jalr	692(ra) # 80000c9e <release>
}
    800069f2:	70a6                	ld	ra,104(sp)
    800069f4:	7406                	ld	s0,96(sp)
    800069f6:	64e6                	ld	s1,88(sp)
    800069f8:	6946                	ld	s2,80(sp)
    800069fa:	69a6                	ld	s3,72(sp)
    800069fc:	6a06                	ld	s4,64(sp)
    800069fe:	7ae2                	ld	s5,56(sp)
    80006a00:	7b42                	ld	s6,48(sp)
    80006a02:	7ba2                	ld	s7,40(sp)
    80006a04:	7c02                	ld	s8,32(sp)
    80006a06:	6ce2                	ld	s9,24(sp)
    80006a08:	6d42                	ld	s10,16(sp)
    80006a0a:	6165                	addi	sp,sp,112
    80006a0c:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006a0e:	4689                	li	a3,2
    80006a10:	00d79623          	sh	a3,12(a5)
    80006a14:	b5e5                	j	800068fc <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006a16:	f9042603          	lw	a2,-112(s0)
    80006a1a:	00a60713          	addi	a4,a2,10
    80006a1e:	0712                	slli	a4,a4,0x4
    80006a20:	0001d517          	auipc	a0,0x1d
    80006a24:	c9850513          	addi	a0,a0,-872 # 800236b8 <disk+0x8>
    80006a28:	953a                	add	a0,a0,a4
  if(write)
    80006a2a:	e60d14e3          	bnez	s10,80006892 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006a2e:	00a60793          	addi	a5,a2,10
    80006a32:	00479693          	slli	a3,a5,0x4
    80006a36:	0001d797          	auipc	a5,0x1d
    80006a3a:	c7a78793          	addi	a5,a5,-902 # 800236b0 <disk>
    80006a3e:	97b6                	add	a5,a5,a3
    80006a40:	0007a423          	sw	zero,8(a5)
    80006a44:	b595                	j	800068a8 <virtio_disk_rw+0xf0>

0000000080006a46 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006a46:	1101                	addi	sp,sp,-32
    80006a48:	ec06                	sd	ra,24(sp)
    80006a4a:	e822                	sd	s0,16(sp)
    80006a4c:	e426                	sd	s1,8(sp)
    80006a4e:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006a50:	0001d497          	auipc	s1,0x1d
    80006a54:	c6048493          	addi	s1,s1,-928 # 800236b0 <disk>
    80006a58:	0001d517          	auipc	a0,0x1d
    80006a5c:	d8050513          	addi	a0,a0,-640 # 800237d8 <disk+0x128>
    80006a60:	ffffa097          	auipc	ra,0xffffa
    80006a64:	18a080e7          	jalr	394(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006a68:	10001737          	lui	a4,0x10001
    80006a6c:	533c                	lw	a5,96(a4)
    80006a6e:	8b8d                	andi	a5,a5,3
    80006a70:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006a72:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006a76:	689c                	ld	a5,16(s1)
    80006a78:	0204d703          	lhu	a4,32(s1)
    80006a7c:	0027d783          	lhu	a5,2(a5)
    80006a80:	04f70863          	beq	a4,a5,80006ad0 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006a84:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006a88:	6898                	ld	a4,16(s1)
    80006a8a:	0204d783          	lhu	a5,32(s1)
    80006a8e:	8b9d                	andi	a5,a5,7
    80006a90:	078e                	slli	a5,a5,0x3
    80006a92:	97ba                	add	a5,a5,a4
    80006a94:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006a96:	00278713          	addi	a4,a5,2
    80006a9a:	0712                	slli	a4,a4,0x4
    80006a9c:	9726                	add	a4,a4,s1
    80006a9e:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006aa2:	e721                	bnez	a4,80006aea <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006aa4:	0789                	addi	a5,a5,2
    80006aa6:	0792                	slli	a5,a5,0x4
    80006aa8:	97a6                	add	a5,a5,s1
    80006aaa:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006aac:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006ab0:	ffffc097          	auipc	ra,0xffffc
    80006ab4:	880080e7          	jalr	-1920(ra) # 80002330 <wakeup>

    disk.used_idx += 1;
    80006ab8:	0204d783          	lhu	a5,32(s1)
    80006abc:	2785                	addiw	a5,a5,1
    80006abe:	17c2                	slli	a5,a5,0x30
    80006ac0:	93c1                	srli	a5,a5,0x30
    80006ac2:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006ac6:	6898                	ld	a4,16(s1)
    80006ac8:	00275703          	lhu	a4,2(a4)
    80006acc:	faf71ce3          	bne	a4,a5,80006a84 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006ad0:	0001d517          	auipc	a0,0x1d
    80006ad4:	d0850513          	addi	a0,a0,-760 # 800237d8 <disk+0x128>
    80006ad8:	ffffa097          	auipc	ra,0xffffa
    80006adc:	1c6080e7          	jalr	454(ra) # 80000c9e <release>
}
    80006ae0:	60e2                	ld	ra,24(sp)
    80006ae2:	6442                	ld	s0,16(sp)
    80006ae4:	64a2                	ld	s1,8(sp)
    80006ae6:	6105                	addi	sp,sp,32
    80006ae8:	8082                	ret
      panic("virtio_disk_intr status");
    80006aea:	00002517          	auipc	a0,0x2
    80006aee:	ede50513          	addi	a0,a0,-290 # 800089c8 <syscalls+0x400>
    80006af2:	ffffa097          	auipc	ra,0xffffa
    80006af6:	a52080e7          	jalr	-1454(ra) # 80000544 <panic>

0000000080006afa <sgenrand>:
static int mti=N+1; /* mti==N+1 means mt[N] is not initialized */

/* initializing the array with a NONZERO seed */
void
sgenrand(unsigned long seed)
{
    80006afa:	1141                	addi	sp,sp,-16
    80006afc:	e422                	sd	s0,8(sp)
    80006afe:	0800                	addi	s0,sp,16
    /* setting initial seeds to mt[N] using         */
    /* the generator Line 25 of Table 1 in          */
    /* [KNUTH 1981, The Art of Computer Programming */
    /*    Vol. 2 (2nd Ed.), pp102]                  */
    mt[0]= seed & 0xffffffff;
    80006b00:	0001d717          	auipc	a4,0x1d
    80006b04:	cf070713          	addi	a4,a4,-784 # 800237f0 <mt>
    80006b08:	1502                	slli	a0,a0,0x20
    80006b0a:	9101                	srli	a0,a0,0x20
    80006b0c:	e308                	sd	a0,0(a4)
    for (mti=1; mti<N; mti++)
    80006b0e:	0001e597          	auipc	a1,0x1e
    80006b12:	05a58593          	addi	a1,a1,90 # 80024b68 <mt+0x1378>
        mt[mti] = (69069 * mt[mti-1]) & 0xffffffff;
    80006b16:	6645                	lui	a2,0x11
    80006b18:	dcd60613          	addi	a2,a2,-563 # 10dcd <_entry-0x7ffef233>
    80006b1c:	56fd                	li	a3,-1
    80006b1e:	9281                	srli	a3,a3,0x20
    80006b20:	631c                	ld	a5,0(a4)
    80006b22:	02c787b3          	mul	a5,a5,a2
    80006b26:	8ff5                	and	a5,a5,a3
    80006b28:	e71c                	sd	a5,8(a4)
    for (mti=1; mti<N; mti++)
    80006b2a:	0721                	addi	a4,a4,8
    80006b2c:	feb71ae3          	bne	a4,a1,80006b20 <sgenrand+0x26>
    80006b30:	27000793          	li	a5,624
    80006b34:	00002717          	auipc	a4,0x2
    80006b38:	ecf72223          	sw	a5,-316(a4) # 800089f8 <mti>
}
    80006b3c:	6422                	ld	s0,8(sp)
    80006b3e:	0141                	addi	sp,sp,16
    80006b40:	8082                	ret

0000000080006b42 <genrand>:

long /* for integer generation */
genrand()
{
    80006b42:	1141                	addi	sp,sp,-16
    80006b44:	e406                	sd	ra,8(sp)
    80006b46:	e022                	sd	s0,0(sp)
    80006b48:	0800                	addi	s0,sp,16
    unsigned long y;
    static unsigned long mag01[2]={0x0, MATRIX_A};
    /* mag01[x] = x * MATRIX_A  for x=0,1 */

    if (mti >= N) { /* generate N words at one time */
    80006b4a:	00002797          	auipc	a5,0x2
    80006b4e:	eae7a783          	lw	a5,-338(a5) # 800089f8 <mti>
    80006b52:	26f00713          	li	a4,623
    80006b56:	0ef75963          	bge	a4,a5,80006c48 <genrand+0x106>
        int kk;

        if (mti == N+1)   /* if sgenrand() has not been called, */
    80006b5a:	27100713          	li	a4,625
    80006b5e:	12e78f63          	beq	a5,a4,80006c9c <genrand+0x15a>
            sgenrand(4357); /* a default initial seed is used   */

        for (kk=0;kk<N-M;kk++) {
    80006b62:	0001d817          	auipc	a6,0x1d
    80006b66:	c8e80813          	addi	a6,a6,-882 # 800237f0 <mt>
    80006b6a:	0001de17          	auipc	t3,0x1d
    80006b6e:	39ee0e13          	addi	t3,t3,926 # 80023f08 <mt+0x718>
{
    80006b72:	8742                	mv	a4,a6
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    80006b74:	4885                	li	a7,1
    80006b76:	08fe                	slli	a7,a7,0x1f
    80006b78:	80000537          	lui	a0,0x80000
    80006b7c:	fff54513          	not	a0,a0
            mt[kk] = mt[kk+M] ^ (y >> 1) ^ mag01[y & 0x1];
    80006b80:	6585                	lui	a1,0x1
    80006b82:	c6858593          	addi	a1,a1,-920 # c68 <_entry-0x7ffff398>
    80006b86:	00002317          	auipc	t1,0x2
    80006b8a:	e5a30313          	addi	t1,t1,-422 # 800089e0 <mag01.985>
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    80006b8e:	631c                	ld	a5,0(a4)
    80006b90:	0117f7b3          	and	a5,a5,a7
    80006b94:	6714                	ld	a3,8(a4)
    80006b96:	8ee9                	and	a3,a3,a0
    80006b98:	8fd5                	or	a5,a5,a3
            mt[kk] = mt[kk+M] ^ (y >> 1) ^ mag01[y & 0x1];
    80006b9a:	00b70633          	add	a2,a4,a1
    80006b9e:	0017d693          	srli	a3,a5,0x1
    80006ba2:	6210                	ld	a2,0(a2)
    80006ba4:	8eb1                	xor	a3,a3,a2
    80006ba6:	8b85                	andi	a5,a5,1
    80006ba8:	078e                	slli	a5,a5,0x3
    80006baa:	979a                	add	a5,a5,t1
    80006bac:	639c                	ld	a5,0(a5)
    80006bae:	8fb5                	xor	a5,a5,a3
    80006bb0:	e31c                	sd	a5,0(a4)
        for (kk=0;kk<N-M;kk++) {
    80006bb2:	0721                	addi	a4,a4,8
    80006bb4:	fdc71de3          	bne	a4,t3,80006b8e <genrand+0x4c>
        }
        for (;kk<N-1;kk++) {
    80006bb8:	6605                	lui	a2,0x1
    80006bba:	c6060613          	addi	a2,a2,-928 # c60 <_entry-0x7ffff3a0>
    80006bbe:	9642                	add	a2,a2,a6
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    80006bc0:	4505                	li	a0,1
    80006bc2:	057e                	slli	a0,a0,0x1f
    80006bc4:	800005b7          	lui	a1,0x80000
    80006bc8:	fff5c593          	not	a1,a1
            mt[kk] = mt[kk+(M-N)] ^ (y >> 1) ^ mag01[y & 0x1];
    80006bcc:	00002897          	auipc	a7,0x2
    80006bd0:	e1488893          	addi	a7,a7,-492 # 800089e0 <mag01.985>
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    80006bd4:	71883783          	ld	a5,1816(a6)
    80006bd8:	8fe9                	and	a5,a5,a0
    80006bda:	72083703          	ld	a4,1824(a6)
    80006bde:	8f6d                	and	a4,a4,a1
    80006be0:	8fd9                	or	a5,a5,a4
            mt[kk] = mt[kk+(M-N)] ^ (y >> 1) ^ mag01[y & 0x1];
    80006be2:	0017d713          	srli	a4,a5,0x1
    80006be6:	00083683          	ld	a3,0(a6)
    80006bea:	8f35                	xor	a4,a4,a3
    80006bec:	8b85                	andi	a5,a5,1
    80006bee:	078e                	slli	a5,a5,0x3
    80006bf0:	97c6                	add	a5,a5,a7
    80006bf2:	639c                	ld	a5,0(a5)
    80006bf4:	8fb9                	xor	a5,a5,a4
    80006bf6:	70f83c23          	sd	a5,1816(a6)
        for (;kk<N-1;kk++) {
    80006bfa:	0821                	addi	a6,a6,8
    80006bfc:	fcc81ce3          	bne	a6,a2,80006bd4 <genrand+0x92>
        }
        y = (mt[N-1]&UPPER_MASK)|(mt[0]&LOWER_MASK);
    80006c00:	0001e697          	auipc	a3,0x1e
    80006c04:	bf068693          	addi	a3,a3,-1040 # 800247f0 <mt+0x1000>
    80006c08:	3786b783          	ld	a5,888(a3)
    80006c0c:	4705                	li	a4,1
    80006c0e:	077e                	slli	a4,a4,0x1f
    80006c10:	8ff9                	and	a5,a5,a4
    80006c12:	0001d717          	auipc	a4,0x1d
    80006c16:	bde73703          	ld	a4,-1058(a4) # 800237f0 <mt>
    80006c1a:	1706                	slli	a4,a4,0x21
    80006c1c:	9305                	srli	a4,a4,0x21
    80006c1e:	8fd9                	or	a5,a5,a4
        mt[N-1] = mt[M-1] ^ (y >> 1) ^ mag01[y & 0x1];
    80006c20:	0017d713          	srli	a4,a5,0x1
    80006c24:	c606b603          	ld	a2,-928(a3)
    80006c28:	8f31                	xor	a4,a4,a2
    80006c2a:	8b85                	andi	a5,a5,1
    80006c2c:	078e                	slli	a5,a5,0x3
    80006c2e:	00002617          	auipc	a2,0x2
    80006c32:	db260613          	addi	a2,a2,-590 # 800089e0 <mag01.985>
    80006c36:	97b2                	add	a5,a5,a2
    80006c38:	639c                	ld	a5,0(a5)
    80006c3a:	8fb9                	xor	a5,a5,a4
    80006c3c:	36f6bc23          	sd	a5,888(a3)

        mti = 0;
    80006c40:	00002797          	auipc	a5,0x2
    80006c44:	da07ac23          	sw	zero,-584(a5) # 800089f8 <mti>
    }
  
    y = mt[mti++];
    80006c48:	00002717          	auipc	a4,0x2
    80006c4c:	db070713          	addi	a4,a4,-592 # 800089f8 <mti>
    80006c50:	431c                	lw	a5,0(a4)
    80006c52:	0017869b          	addiw	a3,a5,1
    80006c56:	c314                	sw	a3,0(a4)
    80006c58:	078e                	slli	a5,a5,0x3
    80006c5a:	0001d717          	auipc	a4,0x1d
    80006c5e:	b9670713          	addi	a4,a4,-1130 # 800237f0 <mt>
    80006c62:	97ba                	add	a5,a5,a4
    80006c64:	6398                	ld	a4,0(a5)
    y ^= TEMPERING_SHIFT_U(y);
    80006c66:	00b75793          	srli	a5,a4,0xb
    80006c6a:	8f3d                	xor	a4,a4,a5
    y ^= TEMPERING_SHIFT_S(y) & TEMPERING_MASK_B;
    80006c6c:	013a67b7          	lui	a5,0x13a6
    80006c70:	8ad78793          	addi	a5,a5,-1875 # 13a58ad <_entry-0x7ec5a753>
    80006c74:	8ff9                	and	a5,a5,a4
    80006c76:	079e                	slli	a5,a5,0x7
    80006c78:	8fb9                	xor	a5,a5,a4
    y ^= TEMPERING_SHIFT_T(y) & TEMPERING_MASK_C;
    80006c7a:	00f79713          	slli	a4,a5,0xf
    80006c7e:	077e36b7          	lui	a3,0x77e3
    80006c82:	0696                	slli	a3,a3,0x5
    80006c84:	8f75                	and	a4,a4,a3
    80006c86:	8fb9                	xor	a5,a5,a4
    y ^= TEMPERING_SHIFT_L(y);
    80006c88:	0127d513          	srli	a0,a5,0x12
    80006c8c:	8fa9                	xor	a5,a5,a0

    // Strip off uppermost bit because we want a long,
    // not an unsigned long
    return y & RAND_MAX;
    80006c8e:	02179513          	slli	a0,a5,0x21
}
    80006c92:	9105                	srli	a0,a0,0x21
    80006c94:	60a2                	ld	ra,8(sp)
    80006c96:	6402                	ld	s0,0(sp)
    80006c98:	0141                	addi	sp,sp,16
    80006c9a:	8082                	ret
            sgenrand(4357); /* a default initial seed is used   */
    80006c9c:	6505                	lui	a0,0x1
    80006c9e:	10550513          	addi	a0,a0,261 # 1105 <_entry-0x7fffeefb>
    80006ca2:	00000097          	auipc	ra,0x0
    80006ca6:	e58080e7          	jalr	-424(ra) # 80006afa <sgenrand>
    80006caa:	bd65                	j	80006b62 <genrand+0x20>

0000000080006cac <random>:

// Assumes 0 <= max <= RAND_MAX
// Returns in the half-open interval [0, max]
long random(long max) {
    80006cac:	1101                	addi	sp,sp,-32
    80006cae:	ec06                	sd	ra,24(sp)
    80006cb0:	e822                	sd	s0,16(sp)
    80006cb2:	e426                	sd	s1,8(sp)
    80006cb4:	1000                	addi	s0,sp,32
    80006cb6:	84aa                	mv	s1,a0
    unsigned long random = (unsigned long)((long)genrand() % (max + 1)); 
    80006cb8:	00000097          	auipc	ra,0x0
    80006cbc:	e8a080e7          	jalr	-374(ra) # 80006b42 <genrand>
    80006cc0:	0485                	addi	s1,s1,1
    return random;
    80006cc2:	02956533          	rem	a0,a0,s1
    80006cc6:	60e2                	ld	ra,24(sp)
    80006cc8:	6442                	ld	s0,16(sp)
    80006cca:	64a2                	ld	s1,8(sp)
    80006ccc:	6105                	addi	sp,sp,32
    80006cce:	8082                	ret
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
