
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a7013103          	ld	sp,-1424(sp) # 80008a70 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000056:	a7e70713          	addi	a4,a4,-1410 # 80008ad0 <timer_scratch>
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
    80000068:	d2c78793          	addi	a5,a5,-724 # 80005d90 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdab3f>
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
    80000130:	3fe080e7          	jalr	1022(ra) # 8000252a <either_copyin>
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
    80000190:	a8450513          	addi	a0,a0,-1404 # 80010c10 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a56080e7          	jalr	-1450(ra) # 80000bea <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	a7448493          	addi	s1,s1,-1420 # 80010c10 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	b0290913          	addi	s2,s2,-1278 # 80010ca8 <cons+0x98>
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
    800001d0:	1a8080e7          	jalr	424(ra) # 80002374 <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	ef2080e7          	jalr	-270(ra) # 800020cc <sleep>
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
    8000021a:	2be080e7          	jalr	702(ra) # 800024d4 <either_copyout>
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
    8000022e:	9e650513          	addi	a0,a0,-1562 # 80010c10 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a6c080e7          	jalr	-1428(ra) # 80000c9e <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	9d050513          	addi	a0,a0,-1584 # 80010c10 <cons>
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
    8000027c:	a2f72823          	sw	a5,-1488(a4) # 80010ca8 <cons+0x98>
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
    800002d6:	93e50513          	addi	a0,a0,-1730 # 80010c10 <cons>
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
    800002fc:	288080e7          	jalr	648(ra) # 80002580 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00011517          	auipc	a0,0x11
    80000304:	91050513          	addi	a0,a0,-1776 # 80010c10 <cons>
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
    80000328:	8ec70713          	addi	a4,a4,-1812 # 80010c10 <cons>
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
    80000352:	8c278793          	addi	a5,a5,-1854 # 80010c10 <cons>
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
    80000380:	92c7a783          	lw	a5,-1748(a5) # 80010ca8 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00011717          	auipc	a4,0x11
    80000394:	88070713          	addi	a4,a4,-1920 # 80010c10 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00011497          	auipc	s1,0x11
    800003a4:	87048493          	addi	s1,s1,-1936 # 80010c10 <cons>
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
    800003e0:	83470713          	addi	a4,a4,-1996 # 80010c10 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00011717          	auipc	a4,0x11
    800003f6:	8af72f23          	sw	a5,-1858(a4) # 80010cb0 <cons+0xa0>
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
    80000418:	00010797          	auipc	a5,0x10
    8000041c:	7f878793          	addi	a5,a5,2040 # 80010c10 <cons>
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
    80000440:	86c7a823          	sw	a2,-1936(a5) # 80010cac <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00011517          	auipc	a0,0x11
    80000448:	86450513          	addi	a0,a0,-1948 # 80010ca8 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	ce4080e7          	jalr	-796(ra) # 80002130 <wakeup>
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
    8000046a:	7aa50513          	addi	a0,a0,1962 # 80010c10 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	6ec080e7          	jalr	1772(ra) # 80000b5a <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00021797          	auipc	a5,0x21
    80000482:	32a78793          	addi	a5,a5,810 # 800217a8 <devsw>
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
    80000554:	7807a023          	sw	zero,1920(a5) # 80010cd0 <pr+0x18>
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
    80000588:	50f72623          	sw	a5,1292(a4) # 80008a90 <panicked>
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
    800005c4:	710dad83          	lw	s11,1808(s11) # 80010cd0 <pr+0x18>
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
    80000602:	6ba50513          	addi	a0,a0,1722 # 80010cb8 <pr>
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
    80000766:	55650513          	addi	a0,a0,1366 # 80010cb8 <pr>
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
    80000782:	53a48493          	addi	s1,s1,1338 # 80010cb8 <pr>
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
    800007e2:	4fa50513          	addi	a0,a0,1274 # 80010cd8 <uart_tx_lock>
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
    8000080e:	2867a783          	lw	a5,646(a5) # 80008a90 <panicked>
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
    8000084a:	25273703          	ld	a4,594(a4) # 80008a98 <uart_tx_r>
    8000084e:	00008797          	auipc	a5,0x8
    80000852:	2527b783          	ld	a5,594(a5) # 80008aa0 <uart_tx_w>
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
    80000874:	468a0a13          	addi	s4,s4,1128 # 80010cd8 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	22048493          	addi	s1,s1,544 # 80008a98 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	22098993          	addi	s3,s3,544 # 80008aa0 <uart_tx_w>
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
    800008aa:	88a080e7          	jalr	-1910(ra) # 80002130 <wakeup>
    
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
    800008e6:	3f650513          	addi	a0,a0,1014 # 80010cd8 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	300080e7          	jalr	768(ra) # 80000bea <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	19e7a783          	lw	a5,414(a5) # 80008a90 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008797          	auipc	a5,0x8
    80000900:	1a47b783          	ld	a5,420(a5) # 80008aa0 <uart_tx_w>
    80000904:	00008717          	auipc	a4,0x8
    80000908:	19473703          	ld	a4,404(a4) # 80008a98 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010a17          	auipc	s4,0x10
    80000914:	3c8a0a13          	addi	s4,s4,968 # 80010cd8 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	18048493          	addi	s1,s1,384 # 80008a98 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	18090913          	addi	s2,s2,384 # 80008aa0 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00001097          	auipc	ra,0x1
    80000934:	79c080e7          	jalr	1948(ra) # 800020cc <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	39248493          	addi	s1,s1,914 # 80010cd8 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00008717          	auipc	a4,0x8
    8000095e:	14f73323          	sd	a5,326(a4) # 80008aa0 <uart_tx_w>
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
    800009d4:	30848493          	addi	s1,s1,776 # 80010cd8 <uart_tx_lock>
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
    80000a12:	00023797          	auipc	a5,0x23
    80000a16:	2ae78793          	addi	a5,a5,686 # 80023cc0 <end>
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
    80000a36:	2de90913          	addi	s2,s2,734 # 80010d10 <kmem>
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
    80000ad2:	24250513          	addi	a0,a0,578 # 80010d10 <kmem>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	084080e7          	jalr	132(ra) # 80000b5a <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ade:	45c5                	li	a1,17
    80000ae0:	05ee                	slli	a1,a1,0x1b
    80000ae2:	00023517          	auipc	a0,0x23
    80000ae6:	1de50513          	addi	a0,a0,478 # 80023cc0 <end>
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
    80000b08:	20c48493          	addi	s1,s1,524 # 80010d10 <kmem>
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
    80000b20:	1f450513          	addi	a0,a0,500 # 80010d10 <kmem>
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
    80000b4c:	1c850513          	addi	a0,a0,456 # 80010d10 <kmem>
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
    80000ea8:	c0470713          	addi	a4,a4,-1020 # 80008aa8 <started>
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
    80000eda:	00001097          	auipc	ra,0x1
    80000ede:	7e6080e7          	jalr	2022(ra) # 800026c0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00005097          	auipc	ra,0x5
    80000ee6:	eee080e7          	jalr	-274(ra) # 80005dd0 <plicinithart>
  }

  scheduler();        
    80000eea:	00001097          	auipc	ra,0x1
    80000eee:	fe8080e7          	jalr	-24(ra) # 80001ed2 <scheduler>
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
    80000f52:	00001097          	auipc	ra,0x1
    80000f56:	746080e7          	jalr	1862(ra) # 80002698 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00001097          	auipc	ra,0x1
    80000f5e:	766080e7          	jalr	1894(ra) # 800026c0 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	e58080e7          	jalr	-424(ra) # 80005dba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00005097          	auipc	ra,0x5
    80000f6e:	e66080e7          	jalr	-410(ra) # 80005dd0 <plicinithart>
    binit();         // buffer cache
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	020080e7          	jalr	32(ra) # 80002f92 <binit>
    iinit();         // inode table
    80000f7a:	00002097          	auipc	ra,0x2
    80000f7e:	6c4080e7          	jalr	1732(ra) # 8000363e <iinit>
    fileinit();      // file table
    80000f82:	00003097          	auipc	ra,0x3
    80000f86:	662080e7          	jalr	1634(ra) # 800045e4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	f4e080e7          	jalr	-178(ra) # 80005ed8 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	d1e080e7          	jalr	-738(ra) # 80001cb0 <userinit>
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    started = 1;
    80000f9e:	4785                	li	a5,1
    80000fa0:	00008717          	auipc	a4,0x8
    80000fa4:	b0f72423          	sw	a5,-1272(a4) # 80008aa8 <started>
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
    80000fb8:	afc7b783          	ld	a5,-1284(a5) # 80008ab0 <kernel_pagetable>
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
    80001274:	84a7b023          	sd	a0,-1984(a5) # 80008ab0 <kernel_pagetable>
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
    8000186a:	8fa48493          	addi	s1,s1,-1798 # 80011160 <proc>
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
    80001880:	00016a17          	auipc	s4,0x16
    80001884:	ce0a0a13          	addi	s4,s4,-800 # 80017560 <tickslock>
    char *pa = kalloc();
    80001888:	fffff097          	auipc	ra,0xfffff
    8000188c:	272080e7          	jalr	626(ra) # 80000afa <kalloc>
    80001890:	862a                	mv	a2,a0
    if(pa == 0)
    80001892:	c131                	beqz	a0,800018d6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001894:	416485b3          	sub	a1,s1,s6
    80001898:	8591                	srai	a1,a1,0x4
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
    800018ba:	19048493          	addi	s1,s1,400
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
    80001906:	42e50513          	addi	a0,a0,1070 # 80010d30 <pid_lock>
    8000190a:	fffff097          	auipc	ra,0xfffff
    8000190e:	250080e7          	jalr	592(ra) # 80000b5a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001912:	00007597          	auipc	a1,0x7
    80001916:	8d658593          	addi	a1,a1,-1834 # 800081e8 <digits+0x1a8>
    8000191a:	0000f517          	auipc	a0,0xf
    8000191e:	42e50513          	addi	a0,a0,1070 # 80010d48 <wait_lock>
    80001922:	fffff097          	auipc	ra,0xfffff
    80001926:	238080e7          	jalr	568(ra) # 80000b5a <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000192a:	00010497          	auipc	s1,0x10
    8000192e:	83648493          	addi	s1,s1,-1994 # 80011160 <proc>
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
    8000194c:	00016997          	auipc	s3,0x16
    80001950:	c1498993          	addi	s3,s3,-1004 # 80017560 <tickslock>
      initlock(&p->lock, "proc");
    80001954:	85da                	mv	a1,s6
    80001956:	8526                	mv	a0,s1
    80001958:	fffff097          	auipc	ra,0xfffff
    8000195c:	202080e7          	jalr	514(ra) # 80000b5a <initlock>
      p->state = UNUSED;
    80001960:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001964:	415487b3          	sub	a5,s1,s5
    80001968:	8791                	srai	a5,a5,0x4
    8000196a:	000a3703          	ld	a4,0(s4)
    8000196e:	02e787b3          	mul	a5,a5,a4
    80001972:	2785                	addiw	a5,a5,1
    80001974:	00d7979b          	slliw	a5,a5,0xd
    80001978:	40f907b3          	sub	a5,s2,a5
    8000197c:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000197e:	19048493          	addi	s1,s1,400
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
    800019ba:	3aa50513          	addi	a0,a0,938 # 80010d60 <cpus>
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
    800019e2:	35270713          	addi	a4,a4,850 # 80010d30 <pid_lock>
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
    80001a1a:	f3a7a783          	lw	a5,-198(a5) # 80008950 <first.1697>
    80001a1e:	eb89                	bnez	a5,80001a30 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a20:	00001097          	auipc	ra,0x1
    80001a24:	cb8080e7          	jalr	-840(ra) # 800026d8 <usertrapret>
}
    80001a28:	60a2                	ld	ra,8(sp)
    80001a2a:	6402                	ld	s0,0(sp)
    80001a2c:	0141                	addi	sp,sp,16
    80001a2e:	8082                	ret
    first = 0;
    80001a30:	00007797          	auipc	a5,0x7
    80001a34:	f207a023          	sw	zero,-224(a5) # 80008950 <first.1697>
    fsinit(ROOTDEV);
    80001a38:	4505                	li	a0,1
    80001a3a:	00002097          	auipc	ra,0x2
    80001a3e:	b84080e7          	jalr	-1148(ra) # 800035be <fsinit>
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
    80001a54:	2e090913          	addi	s2,s2,736 # 80010d30 <pid_lock>
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	190080e7          	jalr	400(ra) # 80000bea <acquire>
  pid = nextpid;
    80001a62:	00007797          	auipc	a5,0x7
    80001a66:	ef278793          	addi	a5,a5,-270 # 80008954 <nextpid>
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
}
    80001bc6:	60e2                	ld	ra,24(sp)
    80001bc8:	6442                	ld	s0,16(sp)
    80001bca:	64a2                	ld	s1,8(sp)
    80001bcc:	6105                	addi	sp,sp,32
    80001bce:	8082                	ret

0000000080001bd0 <allocproc>:
{
    80001bd0:	1101                	addi	sp,sp,-32
    80001bd2:	ec06                	sd	ra,24(sp)
    80001bd4:	e822                	sd	s0,16(sp)
    80001bd6:	e426                	sd	s1,8(sp)
    80001bd8:	e04a                	sd	s2,0(sp)
    80001bda:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bdc:	0000f497          	auipc	s1,0xf
    80001be0:	58448493          	addi	s1,s1,1412 # 80011160 <proc>
    80001be4:	00016917          	auipc	s2,0x16
    80001be8:	97c90913          	addi	s2,s2,-1668 # 80017560 <tickslock>
    acquire(&p->lock);
    80001bec:	8526                	mv	a0,s1
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	ffc080e7          	jalr	-4(ra) # 80000bea <acquire>
    if(p->state == UNUSED) {
    80001bf6:	4c9c                	lw	a5,24(s1)
    80001bf8:	cf81                	beqz	a5,80001c10 <allocproc+0x40>
      release(&p->lock);
    80001bfa:	8526                	mv	a0,s1
    80001bfc:	fffff097          	auipc	ra,0xfffff
    80001c00:	0a2080e7          	jalr	162(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c04:	19048493          	addi	s1,s1,400
    80001c08:	ff2492e3          	bne	s1,s2,80001bec <allocproc+0x1c>
  return 0;
    80001c0c:	4481                	li	s1,0
    80001c0e:	a095                	j	80001c72 <allocproc+0xa2>
  p->pid = allocpid();
    80001c10:	00000097          	auipc	ra,0x0
    80001c14:	e34080e7          	jalr	-460(ra) # 80001a44 <allocpid>
    80001c18:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c1a:	4785                	li	a5,1
    80001c1c:	cc9c                	sw	a5,24(s1)
  p->tick_creation_time = ticks;
    80001c1e:	00007797          	auipc	a5,0x7
    80001c22:	ea27a783          	lw	a5,-350(a5) # 80008ac0 <ticks>
    80001c26:	18f4a423          	sw	a5,392(s1)
  p->tickets = 10;
    80001c2a:	47a9                	li	a5,10
    80001c2c:	18f4a623          	sw	a5,396(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c30:	fffff097          	auipc	ra,0xfffff
    80001c34:	eca080e7          	jalr	-310(ra) # 80000afa <kalloc>
    80001c38:	892a                	mv	s2,a0
    80001c3a:	eca8                	sd	a0,88(s1)
    80001c3c:	c131                	beqz	a0,80001c80 <allocproc+0xb0>
  p->pagetable = proc_pagetable(p);
    80001c3e:	8526                	mv	a0,s1
    80001c40:	00000097          	auipc	ra,0x0
    80001c44:	e4a080e7          	jalr	-438(ra) # 80001a8a <proc_pagetable>
    80001c48:	892a                	mv	s2,a0
    80001c4a:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c4c:	c531                	beqz	a0,80001c98 <allocproc+0xc8>
  memset(&p->context, 0, sizeof(p->context));
    80001c4e:	07000613          	li	a2,112
    80001c52:	4581                	li	a1,0
    80001c54:	06048513          	addi	a0,s1,96
    80001c58:	fffff097          	auipc	ra,0xfffff
    80001c5c:	08e080e7          	jalr	142(ra) # 80000ce6 <memset>
  p->context.ra = (uint64)forkret;
    80001c60:	00000797          	auipc	a5,0x0
    80001c64:	d9e78793          	addi	a5,a5,-610 # 800019fe <forkret>
    80001c68:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c6a:	60bc                	ld	a5,64(s1)
    80001c6c:	6705                	lui	a4,0x1
    80001c6e:	97ba                	add	a5,a5,a4
    80001c70:	f4bc                	sd	a5,104(s1)
}
    80001c72:	8526                	mv	a0,s1
    80001c74:	60e2                	ld	ra,24(sp)
    80001c76:	6442                	ld	s0,16(sp)
    80001c78:	64a2                	ld	s1,8(sp)
    80001c7a:	6902                	ld	s2,0(sp)
    80001c7c:	6105                	addi	sp,sp,32
    80001c7e:	8082                	ret
    freeproc(p);
    80001c80:	8526                	mv	a0,s1
    80001c82:	00000097          	auipc	ra,0x0
    80001c86:	ef6080e7          	jalr	-266(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001c8a:	8526                	mv	a0,s1
    80001c8c:	fffff097          	auipc	ra,0xfffff
    80001c90:	012080e7          	jalr	18(ra) # 80000c9e <release>
    return 0;
    80001c94:	84ca                	mv	s1,s2
    80001c96:	bff1                	j	80001c72 <allocproc+0xa2>
    freeproc(p);
    80001c98:	8526                	mv	a0,s1
    80001c9a:	00000097          	auipc	ra,0x0
    80001c9e:	ede080e7          	jalr	-290(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001ca2:	8526                	mv	a0,s1
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	ffa080e7          	jalr	-6(ra) # 80000c9e <release>
    return 0;
    80001cac:	84ca                	mv	s1,s2
    80001cae:	b7d1                	j	80001c72 <allocproc+0xa2>

0000000080001cb0 <userinit>:
{
    80001cb0:	1101                	addi	sp,sp,-32
    80001cb2:	ec06                	sd	ra,24(sp)
    80001cb4:	e822                	sd	s0,16(sp)
    80001cb6:	e426                	sd	s1,8(sp)
    80001cb8:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cba:	00000097          	auipc	ra,0x0
    80001cbe:	f16080e7          	jalr	-234(ra) # 80001bd0 <allocproc>
    80001cc2:	84aa                	mv	s1,a0
  initproc = p;
    80001cc4:	00007797          	auipc	a5,0x7
    80001cc8:	dea7ba23          	sd	a0,-524(a5) # 80008ab8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ccc:	03400613          	li	a2,52
    80001cd0:	00007597          	auipc	a1,0x7
    80001cd4:	c9058593          	addi	a1,a1,-880 # 80008960 <initcode>
    80001cd8:	6928                	ld	a0,80(a0)
    80001cda:	fffff097          	auipc	ra,0xfffff
    80001cde:	698080e7          	jalr	1688(ra) # 80001372 <uvmfirst>
  p->sz = PGSIZE;
    80001ce2:	6785                	lui	a5,0x1
    80001ce4:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001ce6:	6cb8                	ld	a4,88(s1)
    80001ce8:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cec:	6cb8                	ld	a4,88(s1)
    80001cee:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cf0:	4641                	li	a2,16
    80001cf2:	00006597          	auipc	a1,0x6
    80001cf6:	50e58593          	addi	a1,a1,1294 # 80008200 <digits+0x1c0>
    80001cfa:	15848513          	addi	a0,s1,344
    80001cfe:	fffff097          	auipc	ra,0xfffff
    80001d02:	13a080e7          	jalr	314(ra) # 80000e38 <safestrcpy>
  p->cwd = namei("/");
    80001d06:	00006517          	auipc	a0,0x6
    80001d0a:	50a50513          	addi	a0,a0,1290 # 80008210 <digits+0x1d0>
    80001d0e:	00002097          	auipc	ra,0x2
    80001d12:	2d2080e7          	jalr	722(ra) # 80003fe0 <namei>
    80001d16:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d1a:	478d                	li	a5,3
    80001d1c:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d1e:	8526                	mv	a0,s1
    80001d20:	fffff097          	auipc	ra,0xfffff
    80001d24:	f7e080e7          	jalr	-130(ra) # 80000c9e <release>
}
    80001d28:	60e2                	ld	ra,24(sp)
    80001d2a:	6442                	ld	s0,16(sp)
    80001d2c:	64a2                	ld	s1,8(sp)
    80001d2e:	6105                	addi	sp,sp,32
    80001d30:	8082                	ret

0000000080001d32 <growproc>:
{
    80001d32:	1101                	addi	sp,sp,-32
    80001d34:	ec06                	sd	ra,24(sp)
    80001d36:	e822                	sd	s0,16(sp)
    80001d38:	e426                	sd	s1,8(sp)
    80001d3a:	e04a                	sd	s2,0(sp)
    80001d3c:	1000                	addi	s0,sp,32
    80001d3e:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d40:	00000097          	auipc	ra,0x0
    80001d44:	c86080e7          	jalr	-890(ra) # 800019c6 <myproc>
    80001d48:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d4a:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d4c:	01204c63          	bgtz	s2,80001d64 <growproc+0x32>
  } else if(n < 0){
    80001d50:	02094663          	bltz	s2,80001d7c <growproc+0x4a>
  p->sz = sz;
    80001d54:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d56:	4501                	li	a0,0
}
    80001d58:	60e2                	ld	ra,24(sp)
    80001d5a:	6442                	ld	s0,16(sp)
    80001d5c:	64a2                	ld	s1,8(sp)
    80001d5e:	6902                	ld	s2,0(sp)
    80001d60:	6105                	addi	sp,sp,32
    80001d62:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d64:	4691                	li	a3,4
    80001d66:	00b90633          	add	a2,s2,a1
    80001d6a:	6928                	ld	a0,80(a0)
    80001d6c:	fffff097          	auipc	ra,0xfffff
    80001d70:	6c0080e7          	jalr	1728(ra) # 8000142c <uvmalloc>
    80001d74:	85aa                	mv	a1,a0
    80001d76:	fd79                	bnez	a0,80001d54 <growproc+0x22>
      return -1;
    80001d78:	557d                	li	a0,-1
    80001d7a:	bff9                	j	80001d58 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d7c:	00b90633          	add	a2,s2,a1
    80001d80:	6928                	ld	a0,80(a0)
    80001d82:	fffff097          	auipc	ra,0xfffff
    80001d86:	662080e7          	jalr	1634(ra) # 800013e4 <uvmdealloc>
    80001d8a:	85aa                	mv	a1,a0
    80001d8c:	b7e1                	j	80001d54 <growproc+0x22>

0000000080001d8e <fork>:
{
    80001d8e:	7179                	addi	sp,sp,-48
    80001d90:	f406                	sd	ra,40(sp)
    80001d92:	f022                	sd	s0,32(sp)
    80001d94:	ec26                	sd	s1,24(sp)
    80001d96:	e84a                	sd	s2,16(sp)
    80001d98:	e44e                	sd	s3,8(sp)
    80001d9a:	e052                	sd	s4,0(sp)
    80001d9c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001d9e:	00000097          	auipc	ra,0x0
    80001da2:	c28080e7          	jalr	-984(ra) # 800019c6 <myproc>
    80001da6:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001da8:	00000097          	auipc	ra,0x0
    80001dac:	e28080e7          	jalr	-472(ra) # 80001bd0 <allocproc>
    80001db0:	10050f63          	beqz	a0,80001ece <fork+0x140>
    80001db4:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001db6:	04893603          	ld	a2,72(s2)
    80001dba:	692c                	ld	a1,80(a0)
    80001dbc:	05093503          	ld	a0,80(s2)
    80001dc0:	fffff097          	auipc	ra,0xfffff
    80001dc4:	7c0080e7          	jalr	1984(ra) # 80001580 <uvmcopy>
    80001dc8:	04054a63          	bltz	a0,80001e1c <fork+0x8e>
  np->sz = p->sz;
    80001dcc:	04893783          	ld	a5,72(s2)
    80001dd0:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dd4:	05893683          	ld	a3,88(s2)
    80001dd8:	87b6                	mv	a5,a3
    80001dda:	0589b703          	ld	a4,88(s3)
    80001dde:	12068693          	addi	a3,a3,288
    80001de2:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001de6:	6788                	ld	a0,8(a5)
    80001de8:	6b8c                	ld	a1,16(a5)
    80001dea:	6f90                	ld	a2,24(a5)
    80001dec:	01073023          	sd	a6,0(a4)
    80001df0:	e708                	sd	a0,8(a4)
    80001df2:	eb0c                	sd	a1,16(a4)
    80001df4:	ef10                	sd	a2,24(a4)
    80001df6:	02078793          	addi	a5,a5,32
    80001dfa:	02070713          	addi	a4,a4,32
    80001dfe:	fed792e3          	bne	a5,a3,80001de2 <fork+0x54>
  np->trace_flag = p->trace_flag;
    80001e02:	16892783          	lw	a5,360(s2)
    80001e06:	16f9a423          	sw	a5,360(s3)
  np->trapframe->a0 = 0;
    80001e0a:	0589b783          	ld	a5,88(s3)
    80001e0e:	0607b823          	sd	zero,112(a5)
    80001e12:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e16:	15000a13          	li	s4,336
    80001e1a:	a03d                	j	80001e48 <fork+0xba>
    freeproc(np);
    80001e1c:	854e                	mv	a0,s3
    80001e1e:	00000097          	auipc	ra,0x0
    80001e22:	d5a080e7          	jalr	-678(ra) # 80001b78 <freeproc>
    release(&np->lock);
    80001e26:	854e                	mv	a0,s3
    80001e28:	fffff097          	auipc	ra,0xfffff
    80001e2c:	e76080e7          	jalr	-394(ra) # 80000c9e <release>
    return -1;
    80001e30:	5a7d                	li	s4,-1
    80001e32:	a069                	j	80001ebc <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e34:	00003097          	auipc	ra,0x3
    80001e38:	842080e7          	jalr	-1982(ra) # 80004676 <filedup>
    80001e3c:	009987b3          	add	a5,s3,s1
    80001e40:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e42:	04a1                	addi	s1,s1,8
    80001e44:	01448763          	beq	s1,s4,80001e52 <fork+0xc4>
    if(p->ofile[i])
    80001e48:	009907b3          	add	a5,s2,s1
    80001e4c:	6388                	ld	a0,0(a5)
    80001e4e:	f17d                	bnez	a0,80001e34 <fork+0xa6>
    80001e50:	bfcd                	j	80001e42 <fork+0xb4>
  np->cwd = idup(p->cwd);
    80001e52:	15093503          	ld	a0,336(s2)
    80001e56:	00002097          	auipc	ra,0x2
    80001e5a:	9a6080e7          	jalr	-1626(ra) # 800037fc <idup>
    80001e5e:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e62:	4641                	li	a2,16
    80001e64:	15890593          	addi	a1,s2,344
    80001e68:	15898513          	addi	a0,s3,344
    80001e6c:	fffff097          	auipc	ra,0xfffff
    80001e70:	fcc080e7          	jalr	-52(ra) # 80000e38 <safestrcpy>
  pid = np->pid;
    80001e74:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e78:	854e                	mv	a0,s3
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	e24080e7          	jalr	-476(ra) # 80000c9e <release>
  acquire(&wait_lock);
    80001e82:	0000f497          	auipc	s1,0xf
    80001e86:	ec648493          	addi	s1,s1,-314 # 80010d48 <wait_lock>
    80001e8a:	8526                	mv	a0,s1
    80001e8c:	fffff097          	auipc	ra,0xfffff
    80001e90:	d5e080e7          	jalr	-674(ra) # 80000bea <acquire>
  np->parent = p;
    80001e94:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001e98:	8526                	mv	a0,s1
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	e04080e7          	jalr	-508(ra) # 80000c9e <release>
  acquire(&np->lock);
    80001ea2:	854e                	mv	a0,s3
    80001ea4:	fffff097          	auipc	ra,0xfffff
    80001ea8:	d46080e7          	jalr	-698(ra) # 80000bea <acquire>
  np->state = RUNNABLE;
    80001eac:	478d                	li	a5,3
    80001eae:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001eb2:	854e                	mv	a0,s3
    80001eb4:	fffff097          	auipc	ra,0xfffff
    80001eb8:	dea080e7          	jalr	-534(ra) # 80000c9e <release>
}
    80001ebc:	8552                	mv	a0,s4
    80001ebe:	70a2                	ld	ra,40(sp)
    80001ec0:	7402                	ld	s0,32(sp)
    80001ec2:	64e2                	ld	s1,24(sp)
    80001ec4:	6942                	ld	s2,16(sp)
    80001ec6:	69a2                	ld	s3,8(sp)
    80001ec8:	6a02                	ld	s4,0(sp)
    80001eca:	6145                	addi	sp,sp,48
    80001ecc:	8082                	ret
    return -1;
    80001ece:	5a7d                	li	s4,-1
    80001ed0:	b7f5                	j	80001ebc <fork+0x12e>

0000000080001ed2 <scheduler>:
{
    80001ed2:	715d                	addi	sp,sp,-80
    80001ed4:	e486                	sd	ra,72(sp)
    80001ed6:	e0a2                	sd	s0,64(sp)
    80001ed8:	fc26                	sd	s1,56(sp)
    80001eda:	f84a                	sd	s2,48(sp)
    80001edc:	f44e                	sd	s3,40(sp)
    80001ede:	f052                	sd	s4,32(sp)
    80001ee0:	ec56                	sd	s5,24(sp)
    80001ee2:	e85a                	sd	s6,16(sp)
    80001ee4:	e45e                	sd	s7,8(sp)
    80001ee6:	e062                	sd	s8,0(sp)
    80001ee8:	0880                	addi	s0,sp,80
    80001eea:	8792                	mv	a5,tp
  int id = r_tp();
    80001eec:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001eee:	00779b13          	slli	s6,a5,0x7
    80001ef2:	0000f717          	auipc	a4,0xf
    80001ef6:	e3e70713          	addi	a4,a4,-450 # 80010d30 <pid_lock>
    80001efa:	975a                	add	a4,a4,s6
    80001efc:	02073823          	sd	zero,48(a4)
            swtch(&c->context, &p->context);
    80001f00:	0000f717          	auipc	a4,0xf
    80001f04:	e6870713          	addi	a4,a4,-408 # 80010d68 <cpus+0x8>
    80001f08:	9b3a                	add	s6,s6,a4
        if(p-> state == RUNNABLE)
    80001f0a:	490d                	li	s2,3
      for(p = proc; p < &proc[NPROC]; p++) {
    80001f0c:	00015997          	auipc	s3,0x15
    80001f10:	65498993          	addi	s3,s3,1620 # 80017560 <tickslock>
      int max_tickets = 0;
    80001f14:	4a01                	li	s4,0
            c->proc = p;
    80001f16:	079e                	slli	a5,a5,0x7
    80001f18:	0000fa97          	auipc	s5,0xf
    80001f1c:	e18a8a93          	addi	s5,s5,-488 # 80010d30 <pid_lock>
    80001f20:	9abe                	add	s5,s5,a5
    80001f22:	a041                	j	80001fa2 <scheduler+0xd0>
      for(p = proc; p < &proc[NPROC]; p++) {
    80001f24:	19078793          	addi	a5,a5,400
    80001f28:	01378963          	beq	a5,s3,80001f3a <scheduler+0x68>
        if(p-> state == RUNNABLE)
    80001f2c:	4f98                	lw	a4,24(a5)
    80001f2e:	ff271be3          	bne	a4,s2,80001f24 <scheduler+0x52>
          max_tickets += p->tickets;
    80001f32:	18c7a703          	lw	a4,396(a5)
    80001f36:	9d39                	addw	a0,a0,a4
    80001f38:	b7f5                	j	80001f24 <scheduler+0x52>
      rand_num = random_at_most(max_tickets);
    80001f3a:	00004097          	auipc	ra,0x4
    80001f3e:	682080e7          	jalr	1666(ra) # 800065bc <random_at_most>
    80001f42:	8c2a                	mv	s8,a0
      int counter = 0;
    80001f44:	8bd2                	mv	s7,s4
      for(p = proc; p < &proc[NPROC]; p++) {
    80001f46:	0000f497          	auipc	s1,0xf
    80001f4a:	21a48493          	addi	s1,s1,538 # 80011160 <proc>
    80001f4e:	a811                	j	80001f62 <scheduler+0x90>
        release(&p->lock);
    80001f50:	8526                	mv	a0,s1
    80001f52:	fffff097          	auipc	ra,0xfffff
    80001f56:	d4c080e7          	jalr	-692(ra) # 80000c9e <release>
      for(p = proc; p < &proc[NPROC]; p++) {
    80001f5a:	19048493          	addi	s1,s1,400
    80001f5e:	05348263          	beq	s1,s3,80001fa2 <scheduler+0xd0>
        acquire(&p->lock);
    80001f62:	8526                	mv	a0,s1
    80001f64:	fffff097          	auipc	ra,0xfffff
    80001f68:	c86080e7          	jalr	-890(ra) # 80000bea <acquire>
        if(p->state == RUNNABLE) {
    80001f6c:	4c9c                	lw	a5,24(s1)
    80001f6e:	ff2791e3          	bne	a5,s2,80001f50 <scheduler+0x7e>
          counter += p->tickets;
    80001f72:	18c4a783          	lw	a5,396(s1)
    80001f76:	01778bbb          	addw	s7,a5,s7
          if(counter >= rand_num){
    80001f7a:	fd8bcbe3          	blt	s7,s8,80001f50 <scheduler+0x7e>
            p->state = RUNNING;
    80001f7e:	4791                	li	a5,4
    80001f80:	cc9c                	sw	a5,24(s1)
            c->proc = p;
    80001f82:	029ab823          	sd	s1,48(s5)
            swtch(&c->context, &p->context);
    80001f86:	06048593          	addi	a1,s1,96
    80001f8a:	855a                	mv	a0,s6
    80001f8c:	00000097          	auipc	ra,0x0
    80001f90:	6a2080e7          	jalr	1698(ra) # 8000262e <swtch>
            c->proc = 0;
    80001f94:	020ab823          	sd	zero,48(s5)
            release(&p->lock);
    80001f98:	8526                	mv	a0,s1
    80001f9a:	fffff097          	auipc	ra,0xfffff
    80001f9e:	d04080e7          	jalr	-764(ra) # 80000c9e <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fa2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fa6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001faa:	10079073          	csrw	sstatus,a5
      int max_tickets = 0;
    80001fae:	8552                	mv	a0,s4
      for(p = proc; p < &proc[NPROC]; p++) {
    80001fb0:	0000f797          	auipc	a5,0xf
    80001fb4:	1b078793          	addi	a5,a5,432 # 80011160 <proc>
    80001fb8:	bf95                	j	80001f2c <scheduler+0x5a>

0000000080001fba <sched>:
{
    80001fba:	7179                	addi	sp,sp,-48
    80001fbc:	f406                	sd	ra,40(sp)
    80001fbe:	f022                	sd	s0,32(sp)
    80001fc0:	ec26                	sd	s1,24(sp)
    80001fc2:	e84a                	sd	s2,16(sp)
    80001fc4:	e44e                	sd	s3,8(sp)
    80001fc6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fc8:	00000097          	auipc	ra,0x0
    80001fcc:	9fe080e7          	jalr	-1538(ra) # 800019c6 <myproc>
    80001fd0:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fd2:	fffff097          	auipc	ra,0xfffff
    80001fd6:	b9e080e7          	jalr	-1122(ra) # 80000b70 <holding>
    80001fda:	c93d                	beqz	a0,80002050 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fdc:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fde:	2781                	sext.w	a5,a5
    80001fe0:	079e                	slli	a5,a5,0x7
    80001fe2:	0000f717          	auipc	a4,0xf
    80001fe6:	d4e70713          	addi	a4,a4,-690 # 80010d30 <pid_lock>
    80001fea:	97ba                	add	a5,a5,a4
    80001fec:	0a87a703          	lw	a4,168(a5)
    80001ff0:	4785                	li	a5,1
    80001ff2:	06f71763          	bne	a4,a5,80002060 <sched+0xa6>
  if(p->state == RUNNING)
    80001ff6:	4c98                	lw	a4,24(s1)
    80001ff8:	4791                	li	a5,4
    80001ffa:	06f70b63          	beq	a4,a5,80002070 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ffe:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002002:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002004:	efb5                	bnez	a5,80002080 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002006:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002008:	0000f917          	auipc	s2,0xf
    8000200c:	d2890913          	addi	s2,s2,-728 # 80010d30 <pid_lock>
    80002010:	2781                	sext.w	a5,a5
    80002012:	079e                	slli	a5,a5,0x7
    80002014:	97ca                	add	a5,a5,s2
    80002016:	0ac7a983          	lw	s3,172(a5)
    8000201a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000201c:	2781                	sext.w	a5,a5
    8000201e:	079e                	slli	a5,a5,0x7
    80002020:	0000f597          	auipc	a1,0xf
    80002024:	d4858593          	addi	a1,a1,-696 # 80010d68 <cpus+0x8>
    80002028:	95be                	add	a1,a1,a5
    8000202a:	06048513          	addi	a0,s1,96
    8000202e:	00000097          	auipc	ra,0x0
    80002032:	600080e7          	jalr	1536(ra) # 8000262e <swtch>
    80002036:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002038:	2781                	sext.w	a5,a5
    8000203a:	079e                	slli	a5,a5,0x7
    8000203c:	97ca                	add	a5,a5,s2
    8000203e:	0b37a623          	sw	s3,172(a5)
}
    80002042:	70a2                	ld	ra,40(sp)
    80002044:	7402                	ld	s0,32(sp)
    80002046:	64e2                	ld	s1,24(sp)
    80002048:	6942                	ld	s2,16(sp)
    8000204a:	69a2                	ld	s3,8(sp)
    8000204c:	6145                	addi	sp,sp,48
    8000204e:	8082                	ret
    panic("sched p->lock");
    80002050:	00006517          	auipc	a0,0x6
    80002054:	1c850513          	addi	a0,a0,456 # 80008218 <digits+0x1d8>
    80002058:	ffffe097          	auipc	ra,0xffffe
    8000205c:	4ec080e7          	jalr	1260(ra) # 80000544 <panic>
    panic("sched locks");
    80002060:	00006517          	auipc	a0,0x6
    80002064:	1c850513          	addi	a0,a0,456 # 80008228 <digits+0x1e8>
    80002068:	ffffe097          	auipc	ra,0xffffe
    8000206c:	4dc080e7          	jalr	1244(ra) # 80000544 <panic>
    panic("sched running");
    80002070:	00006517          	auipc	a0,0x6
    80002074:	1c850513          	addi	a0,a0,456 # 80008238 <digits+0x1f8>
    80002078:	ffffe097          	auipc	ra,0xffffe
    8000207c:	4cc080e7          	jalr	1228(ra) # 80000544 <panic>
    panic("sched interruptible");
    80002080:	00006517          	auipc	a0,0x6
    80002084:	1c850513          	addi	a0,a0,456 # 80008248 <digits+0x208>
    80002088:	ffffe097          	auipc	ra,0xffffe
    8000208c:	4bc080e7          	jalr	1212(ra) # 80000544 <panic>

0000000080002090 <yield>:
{
    80002090:	1101                	addi	sp,sp,-32
    80002092:	ec06                	sd	ra,24(sp)
    80002094:	e822                	sd	s0,16(sp)
    80002096:	e426                	sd	s1,8(sp)
    80002098:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000209a:	00000097          	auipc	ra,0x0
    8000209e:	92c080e7          	jalr	-1748(ra) # 800019c6 <myproc>
    800020a2:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020a4:	fffff097          	auipc	ra,0xfffff
    800020a8:	b46080e7          	jalr	-1210(ra) # 80000bea <acquire>
  p->state = RUNNABLE;
    800020ac:	478d                	li	a5,3
    800020ae:	cc9c                	sw	a5,24(s1)
  sched();
    800020b0:	00000097          	auipc	ra,0x0
    800020b4:	f0a080e7          	jalr	-246(ra) # 80001fba <sched>
  release(&p->lock);
    800020b8:	8526                	mv	a0,s1
    800020ba:	fffff097          	auipc	ra,0xfffff
    800020be:	be4080e7          	jalr	-1052(ra) # 80000c9e <release>
}
    800020c2:	60e2                	ld	ra,24(sp)
    800020c4:	6442                	ld	s0,16(sp)
    800020c6:	64a2                	ld	s1,8(sp)
    800020c8:	6105                	addi	sp,sp,32
    800020ca:	8082                	ret

00000000800020cc <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020cc:	7179                	addi	sp,sp,-48
    800020ce:	f406                	sd	ra,40(sp)
    800020d0:	f022                	sd	s0,32(sp)
    800020d2:	ec26                	sd	s1,24(sp)
    800020d4:	e84a                	sd	s2,16(sp)
    800020d6:	e44e                	sd	s3,8(sp)
    800020d8:	1800                	addi	s0,sp,48
    800020da:	89aa                	mv	s3,a0
    800020dc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020de:	00000097          	auipc	ra,0x0
    800020e2:	8e8080e7          	jalr	-1816(ra) # 800019c6 <myproc>
    800020e6:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800020e8:	fffff097          	auipc	ra,0xfffff
    800020ec:	b02080e7          	jalr	-1278(ra) # 80000bea <acquire>
  release(lk);
    800020f0:	854a                	mv	a0,s2
    800020f2:	fffff097          	auipc	ra,0xfffff
    800020f6:	bac080e7          	jalr	-1108(ra) # 80000c9e <release>

  // Go to sleep.
  p->chan = chan;
    800020fa:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020fe:	4789                	li	a5,2
    80002100:	cc9c                	sw	a5,24(s1)

  sched();
    80002102:	00000097          	auipc	ra,0x0
    80002106:	eb8080e7          	jalr	-328(ra) # 80001fba <sched>

  // Tidy up.
  p->chan = 0;
    8000210a:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000210e:	8526                	mv	a0,s1
    80002110:	fffff097          	auipc	ra,0xfffff
    80002114:	b8e080e7          	jalr	-1138(ra) # 80000c9e <release>
  acquire(lk);
    80002118:	854a                	mv	a0,s2
    8000211a:	fffff097          	auipc	ra,0xfffff
    8000211e:	ad0080e7          	jalr	-1328(ra) # 80000bea <acquire>
}
    80002122:	70a2                	ld	ra,40(sp)
    80002124:	7402                	ld	s0,32(sp)
    80002126:	64e2                	ld	s1,24(sp)
    80002128:	6942                	ld	s2,16(sp)
    8000212a:	69a2                	ld	s3,8(sp)
    8000212c:	6145                	addi	sp,sp,48
    8000212e:	8082                	ret

0000000080002130 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002130:	7139                	addi	sp,sp,-64
    80002132:	fc06                	sd	ra,56(sp)
    80002134:	f822                	sd	s0,48(sp)
    80002136:	f426                	sd	s1,40(sp)
    80002138:	f04a                	sd	s2,32(sp)
    8000213a:	ec4e                	sd	s3,24(sp)
    8000213c:	e852                	sd	s4,16(sp)
    8000213e:	e456                	sd	s5,8(sp)
    80002140:	0080                	addi	s0,sp,64
    80002142:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002144:	0000f497          	auipc	s1,0xf
    80002148:	01c48493          	addi	s1,s1,28 # 80011160 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000214c:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000214e:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002150:	00015917          	auipc	s2,0x15
    80002154:	41090913          	addi	s2,s2,1040 # 80017560 <tickslock>
    80002158:	a821                	j	80002170 <wakeup+0x40>
        p->state = RUNNABLE;
    8000215a:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    8000215e:	8526                	mv	a0,s1
    80002160:	fffff097          	auipc	ra,0xfffff
    80002164:	b3e080e7          	jalr	-1218(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002168:	19048493          	addi	s1,s1,400
    8000216c:	03248463          	beq	s1,s2,80002194 <wakeup+0x64>
    if(p != myproc()){
    80002170:	00000097          	auipc	ra,0x0
    80002174:	856080e7          	jalr	-1962(ra) # 800019c6 <myproc>
    80002178:	fea488e3          	beq	s1,a0,80002168 <wakeup+0x38>
      acquire(&p->lock);
    8000217c:	8526                	mv	a0,s1
    8000217e:	fffff097          	auipc	ra,0xfffff
    80002182:	a6c080e7          	jalr	-1428(ra) # 80000bea <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002186:	4c9c                	lw	a5,24(s1)
    80002188:	fd379be3          	bne	a5,s3,8000215e <wakeup+0x2e>
    8000218c:	709c                	ld	a5,32(s1)
    8000218e:	fd4798e3          	bne	a5,s4,8000215e <wakeup+0x2e>
    80002192:	b7e1                	j	8000215a <wakeup+0x2a>
    }
  }
}
    80002194:	70e2                	ld	ra,56(sp)
    80002196:	7442                	ld	s0,48(sp)
    80002198:	74a2                	ld	s1,40(sp)
    8000219a:	7902                	ld	s2,32(sp)
    8000219c:	69e2                	ld	s3,24(sp)
    8000219e:	6a42                	ld	s4,16(sp)
    800021a0:	6aa2                	ld	s5,8(sp)
    800021a2:	6121                	addi	sp,sp,64
    800021a4:	8082                	ret

00000000800021a6 <reparent>:
{
    800021a6:	7179                	addi	sp,sp,-48
    800021a8:	f406                	sd	ra,40(sp)
    800021aa:	f022                	sd	s0,32(sp)
    800021ac:	ec26                	sd	s1,24(sp)
    800021ae:	e84a                	sd	s2,16(sp)
    800021b0:	e44e                	sd	s3,8(sp)
    800021b2:	e052                	sd	s4,0(sp)
    800021b4:	1800                	addi	s0,sp,48
    800021b6:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021b8:	0000f497          	auipc	s1,0xf
    800021bc:	fa848493          	addi	s1,s1,-88 # 80011160 <proc>
      pp->parent = initproc;
    800021c0:	00007a17          	auipc	s4,0x7
    800021c4:	8f8a0a13          	addi	s4,s4,-1800 # 80008ab8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021c8:	00015997          	auipc	s3,0x15
    800021cc:	39898993          	addi	s3,s3,920 # 80017560 <tickslock>
    800021d0:	a029                	j	800021da <reparent+0x34>
    800021d2:	19048493          	addi	s1,s1,400
    800021d6:	01348d63          	beq	s1,s3,800021f0 <reparent+0x4a>
    if(pp->parent == p){
    800021da:	7c9c                	ld	a5,56(s1)
    800021dc:	ff279be3          	bne	a5,s2,800021d2 <reparent+0x2c>
      pp->parent = initproc;
    800021e0:	000a3503          	ld	a0,0(s4)
    800021e4:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800021e6:	00000097          	auipc	ra,0x0
    800021ea:	f4a080e7          	jalr	-182(ra) # 80002130 <wakeup>
    800021ee:	b7d5                	j	800021d2 <reparent+0x2c>
}
    800021f0:	70a2                	ld	ra,40(sp)
    800021f2:	7402                	ld	s0,32(sp)
    800021f4:	64e2                	ld	s1,24(sp)
    800021f6:	6942                	ld	s2,16(sp)
    800021f8:	69a2                	ld	s3,8(sp)
    800021fa:	6a02                	ld	s4,0(sp)
    800021fc:	6145                	addi	sp,sp,48
    800021fe:	8082                	ret

0000000080002200 <exit>:
{
    80002200:	7179                	addi	sp,sp,-48
    80002202:	f406                	sd	ra,40(sp)
    80002204:	f022                	sd	s0,32(sp)
    80002206:	ec26                	sd	s1,24(sp)
    80002208:	e84a                	sd	s2,16(sp)
    8000220a:	e44e                	sd	s3,8(sp)
    8000220c:	e052                	sd	s4,0(sp)
    8000220e:	1800                	addi	s0,sp,48
    80002210:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002212:	fffff097          	auipc	ra,0xfffff
    80002216:	7b4080e7          	jalr	1972(ra) # 800019c6 <myproc>
    8000221a:	89aa                	mv	s3,a0
  if(p == initproc)
    8000221c:	00007797          	auipc	a5,0x7
    80002220:	89c7b783          	ld	a5,-1892(a5) # 80008ab8 <initproc>
    80002224:	0d050493          	addi	s1,a0,208
    80002228:	15050913          	addi	s2,a0,336
    8000222c:	02a79363          	bne	a5,a0,80002252 <exit+0x52>
    panic("init exiting");
    80002230:	00006517          	auipc	a0,0x6
    80002234:	03050513          	addi	a0,a0,48 # 80008260 <digits+0x220>
    80002238:	ffffe097          	auipc	ra,0xffffe
    8000223c:	30c080e7          	jalr	780(ra) # 80000544 <panic>
      fileclose(f);
    80002240:	00002097          	auipc	ra,0x2
    80002244:	488080e7          	jalr	1160(ra) # 800046c8 <fileclose>
      p->ofile[fd] = 0;
    80002248:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000224c:	04a1                	addi	s1,s1,8
    8000224e:	01248563          	beq	s1,s2,80002258 <exit+0x58>
    if(p->ofile[fd]){
    80002252:	6088                	ld	a0,0(s1)
    80002254:	f575                	bnez	a0,80002240 <exit+0x40>
    80002256:	bfdd                	j	8000224c <exit+0x4c>
  begin_op();
    80002258:	00002097          	auipc	ra,0x2
    8000225c:	fa4080e7          	jalr	-92(ra) # 800041fc <begin_op>
  iput(p->cwd);
    80002260:	1509b503          	ld	a0,336(s3)
    80002264:	00001097          	auipc	ra,0x1
    80002268:	790080e7          	jalr	1936(ra) # 800039f4 <iput>
  end_op();
    8000226c:	00002097          	auipc	ra,0x2
    80002270:	010080e7          	jalr	16(ra) # 8000427c <end_op>
  p->cwd = 0;
    80002274:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002278:	0000f497          	auipc	s1,0xf
    8000227c:	ad048493          	addi	s1,s1,-1328 # 80010d48 <wait_lock>
    80002280:	8526                	mv	a0,s1
    80002282:	fffff097          	auipc	ra,0xfffff
    80002286:	968080e7          	jalr	-1688(ra) # 80000bea <acquire>
  reparent(p);
    8000228a:	854e                	mv	a0,s3
    8000228c:	00000097          	auipc	ra,0x0
    80002290:	f1a080e7          	jalr	-230(ra) # 800021a6 <reparent>
  wakeup(p->parent);
    80002294:	0389b503          	ld	a0,56(s3)
    80002298:	00000097          	auipc	ra,0x0
    8000229c:	e98080e7          	jalr	-360(ra) # 80002130 <wakeup>
  acquire(&p->lock);
    800022a0:	854e                	mv	a0,s3
    800022a2:	fffff097          	auipc	ra,0xfffff
    800022a6:	948080e7          	jalr	-1720(ra) # 80000bea <acquire>
  p->xstate = status;
    800022aa:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800022ae:	4795                	li	a5,5
    800022b0:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800022b4:	8526                	mv	a0,s1
    800022b6:	fffff097          	auipc	ra,0xfffff
    800022ba:	9e8080e7          	jalr	-1560(ra) # 80000c9e <release>
  sched();
    800022be:	00000097          	auipc	ra,0x0
    800022c2:	cfc080e7          	jalr	-772(ra) # 80001fba <sched>
  panic("zombie exit");
    800022c6:	00006517          	auipc	a0,0x6
    800022ca:	faa50513          	addi	a0,a0,-86 # 80008270 <digits+0x230>
    800022ce:	ffffe097          	auipc	ra,0xffffe
    800022d2:	276080e7          	jalr	630(ra) # 80000544 <panic>

00000000800022d6 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800022d6:	7179                	addi	sp,sp,-48
    800022d8:	f406                	sd	ra,40(sp)
    800022da:	f022                	sd	s0,32(sp)
    800022dc:	ec26                	sd	s1,24(sp)
    800022de:	e84a                	sd	s2,16(sp)
    800022e0:	e44e                	sd	s3,8(sp)
    800022e2:	1800                	addi	s0,sp,48
    800022e4:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800022e6:	0000f497          	auipc	s1,0xf
    800022ea:	e7a48493          	addi	s1,s1,-390 # 80011160 <proc>
    800022ee:	00015997          	auipc	s3,0x15
    800022f2:	27298993          	addi	s3,s3,626 # 80017560 <tickslock>
    acquire(&p->lock);
    800022f6:	8526                	mv	a0,s1
    800022f8:	fffff097          	auipc	ra,0xfffff
    800022fc:	8f2080e7          	jalr	-1806(ra) # 80000bea <acquire>
    if(p->pid == pid){
    80002300:	589c                	lw	a5,48(s1)
    80002302:	01278d63          	beq	a5,s2,8000231c <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002306:	8526                	mv	a0,s1
    80002308:	fffff097          	auipc	ra,0xfffff
    8000230c:	996080e7          	jalr	-1642(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002310:	19048493          	addi	s1,s1,400
    80002314:	ff3491e3          	bne	s1,s3,800022f6 <kill+0x20>
  }
  return -1;
    80002318:	557d                	li	a0,-1
    8000231a:	a829                	j	80002334 <kill+0x5e>
      p->killed = 1;
    8000231c:	4785                	li	a5,1
    8000231e:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002320:	4c98                	lw	a4,24(s1)
    80002322:	4789                	li	a5,2
    80002324:	00f70f63          	beq	a4,a5,80002342 <kill+0x6c>
      release(&p->lock);
    80002328:	8526                	mv	a0,s1
    8000232a:	fffff097          	auipc	ra,0xfffff
    8000232e:	974080e7          	jalr	-1676(ra) # 80000c9e <release>
      return 0;
    80002332:	4501                	li	a0,0
}
    80002334:	70a2                	ld	ra,40(sp)
    80002336:	7402                	ld	s0,32(sp)
    80002338:	64e2                	ld	s1,24(sp)
    8000233a:	6942                	ld	s2,16(sp)
    8000233c:	69a2                	ld	s3,8(sp)
    8000233e:	6145                	addi	sp,sp,48
    80002340:	8082                	ret
        p->state = RUNNABLE;
    80002342:	478d                	li	a5,3
    80002344:	cc9c                	sw	a5,24(s1)
    80002346:	b7cd                	j	80002328 <kill+0x52>

0000000080002348 <setkilled>:

void
setkilled(struct proc *p)
{
    80002348:	1101                	addi	sp,sp,-32
    8000234a:	ec06                	sd	ra,24(sp)
    8000234c:	e822                	sd	s0,16(sp)
    8000234e:	e426                	sd	s1,8(sp)
    80002350:	1000                	addi	s0,sp,32
    80002352:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002354:	fffff097          	auipc	ra,0xfffff
    80002358:	896080e7          	jalr	-1898(ra) # 80000bea <acquire>
  p->killed = 1;
    8000235c:	4785                	li	a5,1
    8000235e:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002360:	8526                	mv	a0,s1
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	93c080e7          	jalr	-1732(ra) # 80000c9e <release>
}
    8000236a:	60e2                	ld	ra,24(sp)
    8000236c:	6442                	ld	s0,16(sp)
    8000236e:	64a2                	ld	s1,8(sp)
    80002370:	6105                	addi	sp,sp,32
    80002372:	8082                	ret

0000000080002374 <killed>:

int
killed(struct proc *p)
{
    80002374:	1101                	addi	sp,sp,-32
    80002376:	ec06                	sd	ra,24(sp)
    80002378:	e822                	sd	s0,16(sp)
    8000237a:	e426                	sd	s1,8(sp)
    8000237c:	e04a                	sd	s2,0(sp)
    8000237e:	1000                	addi	s0,sp,32
    80002380:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002382:	fffff097          	auipc	ra,0xfffff
    80002386:	868080e7          	jalr	-1944(ra) # 80000bea <acquire>
  k = p->killed;
    8000238a:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000238e:	8526                	mv	a0,s1
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	90e080e7          	jalr	-1778(ra) # 80000c9e <release>
  return k;
}
    80002398:	854a                	mv	a0,s2
    8000239a:	60e2                	ld	ra,24(sp)
    8000239c:	6442                	ld	s0,16(sp)
    8000239e:	64a2                	ld	s1,8(sp)
    800023a0:	6902                	ld	s2,0(sp)
    800023a2:	6105                	addi	sp,sp,32
    800023a4:	8082                	ret

00000000800023a6 <wait>:
{
    800023a6:	715d                	addi	sp,sp,-80
    800023a8:	e486                	sd	ra,72(sp)
    800023aa:	e0a2                	sd	s0,64(sp)
    800023ac:	fc26                	sd	s1,56(sp)
    800023ae:	f84a                	sd	s2,48(sp)
    800023b0:	f44e                	sd	s3,40(sp)
    800023b2:	f052                	sd	s4,32(sp)
    800023b4:	ec56                	sd	s5,24(sp)
    800023b6:	e85a                	sd	s6,16(sp)
    800023b8:	e45e                	sd	s7,8(sp)
    800023ba:	e062                	sd	s8,0(sp)
    800023bc:	0880                	addi	s0,sp,80
    800023be:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	606080e7          	jalr	1542(ra) # 800019c6 <myproc>
    800023c8:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023ca:	0000f517          	auipc	a0,0xf
    800023ce:	97e50513          	addi	a0,a0,-1666 # 80010d48 <wait_lock>
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	818080e7          	jalr	-2024(ra) # 80000bea <acquire>
    havekids = 0;
    800023da:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    800023dc:	4a15                	li	s4,5
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023de:	00015997          	auipc	s3,0x15
    800023e2:	18298993          	addi	s3,s3,386 # 80017560 <tickslock>
        havekids = 1;
    800023e6:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023e8:	0000fc17          	auipc	s8,0xf
    800023ec:	960c0c13          	addi	s8,s8,-1696 # 80010d48 <wait_lock>
    havekids = 0;
    800023f0:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023f2:	0000f497          	auipc	s1,0xf
    800023f6:	d6e48493          	addi	s1,s1,-658 # 80011160 <proc>
    800023fa:	a0bd                	j	80002468 <wait+0xc2>
          pid = pp->pid;
    800023fc:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002400:	000b0e63          	beqz	s6,8000241c <wait+0x76>
    80002404:	4691                	li	a3,4
    80002406:	02c48613          	addi	a2,s1,44
    8000240a:	85da                	mv	a1,s6
    8000240c:	05093503          	ld	a0,80(s2)
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	274080e7          	jalr	628(ra) # 80001684 <copyout>
    80002418:	02054563          	bltz	a0,80002442 <wait+0x9c>
          freeproc(pp);
    8000241c:	8526                	mv	a0,s1
    8000241e:	fffff097          	auipc	ra,0xfffff
    80002422:	75a080e7          	jalr	1882(ra) # 80001b78 <freeproc>
          release(&pp->lock);
    80002426:	8526                	mv	a0,s1
    80002428:	fffff097          	auipc	ra,0xfffff
    8000242c:	876080e7          	jalr	-1930(ra) # 80000c9e <release>
          release(&wait_lock);
    80002430:	0000f517          	auipc	a0,0xf
    80002434:	91850513          	addi	a0,a0,-1768 # 80010d48 <wait_lock>
    80002438:	fffff097          	auipc	ra,0xfffff
    8000243c:	866080e7          	jalr	-1946(ra) # 80000c9e <release>
          return pid;
    80002440:	a0b5                	j	800024ac <wait+0x106>
            release(&pp->lock);
    80002442:	8526                	mv	a0,s1
    80002444:	fffff097          	auipc	ra,0xfffff
    80002448:	85a080e7          	jalr	-1958(ra) # 80000c9e <release>
            release(&wait_lock);
    8000244c:	0000f517          	auipc	a0,0xf
    80002450:	8fc50513          	addi	a0,a0,-1796 # 80010d48 <wait_lock>
    80002454:	fffff097          	auipc	ra,0xfffff
    80002458:	84a080e7          	jalr	-1974(ra) # 80000c9e <release>
            return -1;
    8000245c:	59fd                	li	s3,-1
    8000245e:	a0b9                	j	800024ac <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002460:	19048493          	addi	s1,s1,400
    80002464:	03348463          	beq	s1,s3,8000248c <wait+0xe6>
      if(pp->parent == p){
    80002468:	7c9c                	ld	a5,56(s1)
    8000246a:	ff279be3          	bne	a5,s2,80002460 <wait+0xba>
        acquire(&pp->lock);
    8000246e:	8526                	mv	a0,s1
    80002470:	ffffe097          	auipc	ra,0xffffe
    80002474:	77a080e7          	jalr	1914(ra) # 80000bea <acquire>
        if(pp->state == ZOMBIE){
    80002478:	4c9c                	lw	a5,24(s1)
    8000247a:	f94781e3          	beq	a5,s4,800023fc <wait+0x56>
        release(&pp->lock);
    8000247e:	8526                	mv	a0,s1
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	81e080e7          	jalr	-2018(ra) # 80000c9e <release>
        havekids = 1;
    80002488:	8756                	mv	a4,s5
    8000248a:	bfd9                	j	80002460 <wait+0xba>
    if(!havekids || killed(p)){
    8000248c:	c719                	beqz	a4,8000249a <wait+0xf4>
    8000248e:	854a                	mv	a0,s2
    80002490:	00000097          	auipc	ra,0x0
    80002494:	ee4080e7          	jalr	-284(ra) # 80002374 <killed>
    80002498:	c51d                	beqz	a0,800024c6 <wait+0x120>
      release(&wait_lock);
    8000249a:	0000f517          	auipc	a0,0xf
    8000249e:	8ae50513          	addi	a0,a0,-1874 # 80010d48 <wait_lock>
    800024a2:	ffffe097          	auipc	ra,0xffffe
    800024a6:	7fc080e7          	jalr	2044(ra) # 80000c9e <release>
      return -1;
    800024aa:	59fd                	li	s3,-1
}
    800024ac:	854e                	mv	a0,s3
    800024ae:	60a6                	ld	ra,72(sp)
    800024b0:	6406                	ld	s0,64(sp)
    800024b2:	74e2                	ld	s1,56(sp)
    800024b4:	7942                	ld	s2,48(sp)
    800024b6:	79a2                	ld	s3,40(sp)
    800024b8:	7a02                	ld	s4,32(sp)
    800024ba:	6ae2                	ld	s5,24(sp)
    800024bc:	6b42                	ld	s6,16(sp)
    800024be:	6ba2                	ld	s7,8(sp)
    800024c0:	6c02                	ld	s8,0(sp)
    800024c2:	6161                	addi	sp,sp,80
    800024c4:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024c6:	85e2                	mv	a1,s8
    800024c8:	854a                	mv	a0,s2
    800024ca:	00000097          	auipc	ra,0x0
    800024ce:	c02080e7          	jalr	-1022(ra) # 800020cc <sleep>
    havekids = 0;
    800024d2:	bf39                	j	800023f0 <wait+0x4a>

00000000800024d4 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024d4:	7179                	addi	sp,sp,-48
    800024d6:	f406                	sd	ra,40(sp)
    800024d8:	f022                	sd	s0,32(sp)
    800024da:	ec26                	sd	s1,24(sp)
    800024dc:	e84a                	sd	s2,16(sp)
    800024de:	e44e                	sd	s3,8(sp)
    800024e0:	e052                	sd	s4,0(sp)
    800024e2:	1800                	addi	s0,sp,48
    800024e4:	84aa                	mv	s1,a0
    800024e6:	892e                	mv	s2,a1
    800024e8:	89b2                	mv	s3,a2
    800024ea:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024ec:	fffff097          	auipc	ra,0xfffff
    800024f0:	4da080e7          	jalr	1242(ra) # 800019c6 <myproc>
  if(user_dst){
    800024f4:	c08d                	beqz	s1,80002516 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024f6:	86d2                	mv	a3,s4
    800024f8:	864e                	mv	a2,s3
    800024fa:	85ca                	mv	a1,s2
    800024fc:	6928                	ld	a0,80(a0)
    800024fe:	fffff097          	auipc	ra,0xfffff
    80002502:	186080e7          	jalr	390(ra) # 80001684 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002506:	70a2                	ld	ra,40(sp)
    80002508:	7402                	ld	s0,32(sp)
    8000250a:	64e2                	ld	s1,24(sp)
    8000250c:	6942                	ld	s2,16(sp)
    8000250e:	69a2                	ld	s3,8(sp)
    80002510:	6a02                	ld	s4,0(sp)
    80002512:	6145                	addi	sp,sp,48
    80002514:	8082                	ret
    memmove((char *)dst, src, len);
    80002516:	000a061b          	sext.w	a2,s4
    8000251a:	85ce                	mv	a1,s3
    8000251c:	854a                	mv	a0,s2
    8000251e:	fffff097          	auipc	ra,0xfffff
    80002522:	828080e7          	jalr	-2008(ra) # 80000d46 <memmove>
    return 0;
    80002526:	8526                	mv	a0,s1
    80002528:	bff9                	j	80002506 <either_copyout+0x32>

000000008000252a <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000252a:	7179                	addi	sp,sp,-48
    8000252c:	f406                	sd	ra,40(sp)
    8000252e:	f022                	sd	s0,32(sp)
    80002530:	ec26                	sd	s1,24(sp)
    80002532:	e84a                	sd	s2,16(sp)
    80002534:	e44e                	sd	s3,8(sp)
    80002536:	e052                	sd	s4,0(sp)
    80002538:	1800                	addi	s0,sp,48
    8000253a:	892a                	mv	s2,a0
    8000253c:	84ae                	mv	s1,a1
    8000253e:	89b2                	mv	s3,a2
    80002540:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002542:	fffff097          	auipc	ra,0xfffff
    80002546:	484080e7          	jalr	1156(ra) # 800019c6 <myproc>
  if(user_src){
    8000254a:	c08d                	beqz	s1,8000256c <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000254c:	86d2                	mv	a3,s4
    8000254e:	864e                	mv	a2,s3
    80002550:	85ca                	mv	a1,s2
    80002552:	6928                	ld	a0,80(a0)
    80002554:	fffff097          	auipc	ra,0xfffff
    80002558:	1bc080e7          	jalr	444(ra) # 80001710 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000255c:	70a2                	ld	ra,40(sp)
    8000255e:	7402                	ld	s0,32(sp)
    80002560:	64e2                	ld	s1,24(sp)
    80002562:	6942                	ld	s2,16(sp)
    80002564:	69a2                	ld	s3,8(sp)
    80002566:	6a02                	ld	s4,0(sp)
    80002568:	6145                	addi	sp,sp,48
    8000256a:	8082                	ret
    memmove(dst, (char*)src, len);
    8000256c:	000a061b          	sext.w	a2,s4
    80002570:	85ce                	mv	a1,s3
    80002572:	854a                	mv	a0,s2
    80002574:	ffffe097          	auipc	ra,0xffffe
    80002578:	7d2080e7          	jalr	2002(ra) # 80000d46 <memmove>
    return 0;
    8000257c:	8526                	mv	a0,s1
    8000257e:	bff9                	j	8000255c <either_copyin+0x32>

0000000080002580 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002580:	715d                	addi	sp,sp,-80
    80002582:	e486                	sd	ra,72(sp)
    80002584:	e0a2                	sd	s0,64(sp)
    80002586:	fc26                	sd	s1,56(sp)
    80002588:	f84a                	sd	s2,48(sp)
    8000258a:	f44e                	sd	s3,40(sp)
    8000258c:	f052                	sd	s4,32(sp)
    8000258e:	ec56                	sd	s5,24(sp)
    80002590:	e85a                	sd	s6,16(sp)
    80002592:	e45e                	sd	s7,8(sp)
    80002594:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002596:	00006517          	auipc	a0,0x6
    8000259a:	b3250513          	addi	a0,a0,-1230 # 800080c8 <digits+0x88>
    8000259e:	ffffe097          	auipc	ra,0xffffe
    800025a2:	ff0080e7          	jalr	-16(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025a6:	0000f497          	auipc	s1,0xf
    800025aa:	d1248493          	addi	s1,s1,-750 # 800112b8 <proc+0x158>
    800025ae:	00015917          	auipc	s2,0x15
    800025b2:	10a90913          	addi	s2,s2,266 # 800176b8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025b6:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025b8:	00006997          	auipc	s3,0x6
    800025bc:	cc898993          	addi	s3,s3,-824 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800025c0:	00006a97          	auipc	s5,0x6
    800025c4:	cc8a8a93          	addi	s5,s5,-824 # 80008288 <digits+0x248>
    printf("\n");
    800025c8:	00006a17          	auipc	s4,0x6
    800025cc:	b00a0a13          	addi	s4,s4,-1280 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025d0:	00006b97          	auipc	s7,0x6
    800025d4:	cf8b8b93          	addi	s7,s7,-776 # 800082c8 <states.1741>
    800025d8:	a00d                	j	800025fa <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025da:	ed86a583          	lw	a1,-296(a3)
    800025de:	8556                	mv	a0,s5
    800025e0:	ffffe097          	auipc	ra,0xffffe
    800025e4:	fae080e7          	jalr	-82(ra) # 8000058e <printf>
    printf("\n");
    800025e8:	8552                	mv	a0,s4
    800025ea:	ffffe097          	auipc	ra,0xffffe
    800025ee:	fa4080e7          	jalr	-92(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025f2:	19048493          	addi	s1,s1,400
    800025f6:	03248163          	beq	s1,s2,80002618 <procdump+0x98>
    if(p->state == UNUSED)
    800025fa:	86a6                	mv	a3,s1
    800025fc:	ec04a783          	lw	a5,-320(s1)
    80002600:	dbed                	beqz	a5,800025f2 <procdump+0x72>
      state = "???";
    80002602:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002604:	fcfb6be3          	bltu	s6,a5,800025da <procdump+0x5a>
    80002608:	1782                	slli	a5,a5,0x20
    8000260a:	9381                	srli	a5,a5,0x20
    8000260c:	078e                	slli	a5,a5,0x3
    8000260e:	97de                	add	a5,a5,s7
    80002610:	6390                	ld	a2,0(a5)
    80002612:	f661                	bnez	a2,800025da <procdump+0x5a>
      state = "???";
    80002614:	864e                	mv	a2,s3
    80002616:	b7d1                	j	800025da <procdump+0x5a>
  }
}
    80002618:	60a6                	ld	ra,72(sp)
    8000261a:	6406                	ld	s0,64(sp)
    8000261c:	74e2                	ld	s1,56(sp)
    8000261e:	7942                	ld	s2,48(sp)
    80002620:	79a2                	ld	s3,40(sp)
    80002622:	7a02                	ld	s4,32(sp)
    80002624:	6ae2                	ld	s5,24(sp)
    80002626:	6b42                	ld	s6,16(sp)
    80002628:	6ba2                	ld	s7,8(sp)
    8000262a:	6161                	addi	sp,sp,80
    8000262c:	8082                	ret

000000008000262e <swtch>:
    8000262e:	00153023          	sd	ra,0(a0)
    80002632:	00253423          	sd	sp,8(a0)
    80002636:	e900                	sd	s0,16(a0)
    80002638:	ed04                	sd	s1,24(a0)
    8000263a:	03253023          	sd	s2,32(a0)
    8000263e:	03353423          	sd	s3,40(a0)
    80002642:	03453823          	sd	s4,48(a0)
    80002646:	03553c23          	sd	s5,56(a0)
    8000264a:	05653023          	sd	s6,64(a0)
    8000264e:	05753423          	sd	s7,72(a0)
    80002652:	05853823          	sd	s8,80(a0)
    80002656:	05953c23          	sd	s9,88(a0)
    8000265a:	07a53023          	sd	s10,96(a0)
    8000265e:	07b53423          	sd	s11,104(a0)
    80002662:	0005b083          	ld	ra,0(a1)
    80002666:	0085b103          	ld	sp,8(a1)
    8000266a:	6980                	ld	s0,16(a1)
    8000266c:	6d84                	ld	s1,24(a1)
    8000266e:	0205b903          	ld	s2,32(a1)
    80002672:	0285b983          	ld	s3,40(a1)
    80002676:	0305ba03          	ld	s4,48(a1)
    8000267a:	0385ba83          	ld	s5,56(a1)
    8000267e:	0405bb03          	ld	s6,64(a1)
    80002682:	0485bb83          	ld	s7,72(a1)
    80002686:	0505bc03          	ld	s8,80(a1)
    8000268a:	0585bc83          	ld	s9,88(a1)
    8000268e:	0605bd03          	ld	s10,96(a1)
    80002692:	0685bd83          	ld	s11,104(a1)
    80002696:	8082                	ret

0000000080002698 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002698:	1141                	addi	sp,sp,-16
    8000269a:	e406                	sd	ra,8(sp)
    8000269c:	e022                	sd	s0,0(sp)
    8000269e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026a0:	00006597          	auipc	a1,0x6
    800026a4:	c5858593          	addi	a1,a1,-936 # 800082f8 <states.1741+0x30>
    800026a8:	00015517          	auipc	a0,0x15
    800026ac:	eb850513          	addi	a0,a0,-328 # 80017560 <tickslock>
    800026b0:	ffffe097          	auipc	ra,0xffffe
    800026b4:	4aa080e7          	jalr	1194(ra) # 80000b5a <initlock>
}
    800026b8:	60a2                	ld	ra,8(sp)
    800026ba:	6402                	ld	s0,0(sp)
    800026bc:	0141                	addi	sp,sp,16
    800026be:	8082                	ret

00000000800026c0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026c0:	1141                	addi	sp,sp,-16
    800026c2:	e422                	sd	s0,8(sp)
    800026c4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026c6:	00003797          	auipc	a5,0x3
    800026ca:	63a78793          	addi	a5,a5,1594 # 80005d00 <kernelvec>
    800026ce:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026d2:	6422                	ld	s0,8(sp)
    800026d4:	0141                	addi	sp,sp,16
    800026d6:	8082                	ret

00000000800026d8 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026d8:	1141                	addi	sp,sp,-16
    800026da:	e406                	sd	ra,8(sp)
    800026dc:	e022                	sd	s0,0(sp)
    800026de:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026e0:	fffff097          	auipc	ra,0xfffff
    800026e4:	2e6080e7          	jalr	742(ra) # 800019c6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026e8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026ec:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026ee:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800026f2:	00005617          	auipc	a2,0x5
    800026f6:	90e60613          	addi	a2,a2,-1778 # 80007000 <_trampoline>
    800026fa:	00005697          	auipc	a3,0x5
    800026fe:	90668693          	addi	a3,a3,-1786 # 80007000 <_trampoline>
    80002702:	8e91                	sub	a3,a3,a2
    80002704:	040007b7          	lui	a5,0x4000
    80002708:	17fd                	addi	a5,a5,-1
    8000270a:	07b2                	slli	a5,a5,0xc
    8000270c:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000270e:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002712:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002714:	180026f3          	csrr	a3,satp
    80002718:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000271a:	6d38                	ld	a4,88(a0)
    8000271c:	6134                	ld	a3,64(a0)
    8000271e:	6585                	lui	a1,0x1
    80002720:	96ae                	add	a3,a3,a1
    80002722:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002724:	6d38                	ld	a4,88(a0)
    80002726:	00000697          	auipc	a3,0x0
    8000272a:	13068693          	addi	a3,a3,304 # 80002856 <usertrap>
    8000272e:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002730:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002732:	8692                	mv	a3,tp
    80002734:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002736:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000273a:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000273e:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002742:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002746:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002748:	6f18                	ld	a4,24(a4)
    8000274a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000274e:	6928                	ld	a0,80(a0)
    80002750:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002752:	00005717          	auipc	a4,0x5
    80002756:	94a70713          	addi	a4,a4,-1718 # 8000709c <userret>
    8000275a:	8f11                	sub	a4,a4,a2
    8000275c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    8000275e:	577d                	li	a4,-1
    80002760:	177e                	slli	a4,a4,0x3f
    80002762:	8d59                	or	a0,a0,a4
    80002764:	9782                	jalr	a5
}
    80002766:	60a2                	ld	ra,8(sp)
    80002768:	6402                	ld	s0,0(sp)
    8000276a:	0141                	addi	sp,sp,16
    8000276c:	8082                	ret

000000008000276e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000276e:	1101                	addi	sp,sp,-32
    80002770:	ec06                	sd	ra,24(sp)
    80002772:	e822                	sd	s0,16(sp)
    80002774:	e426                	sd	s1,8(sp)
    80002776:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002778:	00015497          	auipc	s1,0x15
    8000277c:	de848493          	addi	s1,s1,-536 # 80017560 <tickslock>
    80002780:	8526                	mv	a0,s1
    80002782:	ffffe097          	auipc	ra,0xffffe
    80002786:	468080e7          	jalr	1128(ra) # 80000bea <acquire>
  ticks++;
    8000278a:	00006517          	auipc	a0,0x6
    8000278e:	33650513          	addi	a0,a0,822 # 80008ac0 <ticks>
    80002792:	411c                	lw	a5,0(a0)
    80002794:	2785                	addiw	a5,a5,1
    80002796:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002798:	00000097          	auipc	ra,0x0
    8000279c:	998080e7          	jalr	-1640(ra) # 80002130 <wakeup>
  release(&tickslock);
    800027a0:	8526                	mv	a0,s1
    800027a2:	ffffe097          	auipc	ra,0xffffe
    800027a6:	4fc080e7          	jalr	1276(ra) # 80000c9e <release>
}
    800027aa:	60e2                	ld	ra,24(sp)
    800027ac:	6442                	ld	s0,16(sp)
    800027ae:	64a2                	ld	s1,8(sp)
    800027b0:	6105                	addi	sp,sp,32
    800027b2:	8082                	ret

00000000800027b4 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027b4:	1101                	addi	sp,sp,-32
    800027b6:	ec06                	sd	ra,24(sp)
    800027b8:	e822                	sd	s0,16(sp)
    800027ba:	e426                	sd	s1,8(sp)
    800027bc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027be:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027c2:	00074d63          	bltz	a4,800027dc <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027c6:	57fd                	li	a5,-1
    800027c8:	17fe                	slli	a5,a5,0x3f
    800027ca:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027cc:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027ce:	06f70363          	beq	a4,a5,80002834 <devintr+0x80>
  }
}
    800027d2:	60e2                	ld	ra,24(sp)
    800027d4:	6442                	ld	s0,16(sp)
    800027d6:	64a2                	ld	s1,8(sp)
    800027d8:	6105                	addi	sp,sp,32
    800027da:	8082                	ret
     (scause & 0xff) == 9){
    800027dc:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800027e0:	46a5                	li	a3,9
    800027e2:	fed792e3          	bne	a5,a3,800027c6 <devintr+0x12>
    int irq = plic_claim();
    800027e6:	00003097          	auipc	ra,0x3
    800027ea:	622080e7          	jalr	1570(ra) # 80005e08 <plic_claim>
    800027ee:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027f0:	47a9                	li	a5,10
    800027f2:	02f50763          	beq	a0,a5,80002820 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027f6:	4785                	li	a5,1
    800027f8:	02f50963          	beq	a0,a5,8000282a <devintr+0x76>
    return 1;
    800027fc:	4505                	li	a0,1
    } else if(irq){
    800027fe:	d8f1                	beqz	s1,800027d2 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002800:	85a6                	mv	a1,s1
    80002802:	00006517          	auipc	a0,0x6
    80002806:	afe50513          	addi	a0,a0,-1282 # 80008300 <states.1741+0x38>
    8000280a:	ffffe097          	auipc	ra,0xffffe
    8000280e:	d84080e7          	jalr	-636(ra) # 8000058e <printf>
      plic_complete(irq);
    80002812:	8526                	mv	a0,s1
    80002814:	00003097          	auipc	ra,0x3
    80002818:	618080e7          	jalr	1560(ra) # 80005e2c <plic_complete>
    return 1;
    8000281c:	4505                	li	a0,1
    8000281e:	bf55                	j	800027d2 <devintr+0x1e>
      uartintr();
    80002820:	ffffe097          	auipc	ra,0xffffe
    80002824:	18e080e7          	jalr	398(ra) # 800009ae <uartintr>
    80002828:	b7ed                	j	80002812 <devintr+0x5e>
      virtio_disk_intr();
    8000282a:	00004097          	auipc	ra,0x4
    8000282e:	b2c080e7          	jalr	-1236(ra) # 80006356 <virtio_disk_intr>
    80002832:	b7c5                	j	80002812 <devintr+0x5e>
    if(cpuid() == 0){
    80002834:	fffff097          	auipc	ra,0xfffff
    80002838:	166080e7          	jalr	358(ra) # 8000199a <cpuid>
    8000283c:	c901                	beqz	a0,8000284c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000283e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002842:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002844:	14479073          	csrw	sip,a5
    return 2;
    80002848:	4509                	li	a0,2
    8000284a:	b761                	j	800027d2 <devintr+0x1e>
      clockintr();
    8000284c:	00000097          	auipc	ra,0x0
    80002850:	f22080e7          	jalr	-222(ra) # 8000276e <clockintr>
    80002854:	b7ed                	j	8000283e <devintr+0x8a>

0000000080002856 <usertrap>:
{
    80002856:	1101                	addi	sp,sp,-32
    80002858:	ec06                	sd	ra,24(sp)
    8000285a:	e822                	sd	s0,16(sp)
    8000285c:	e426                	sd	s1,8(sp)
    8000285e:	e04a                	sd	s2,0(sp)
    80002860:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002862:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002866:	1007f793          	andi	a5,a5,256
    8000286a:	efb9                	bnez	a5,800028c8 <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000286c:	00003797          	auipc	a5,0x3
    80002870:	49478793          	addi	a5,a5,1172 # 80005d00 <kernelvec>
    80002874:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002878:	fffff097          	auipc	ra,0xfffff
    8000287c:	14e080e7          	jalr	334(ra) # 800019c6 <myproc>
    80002880:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002882:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002884:	14102773          	csrr	a4,sepc
    80002888:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000288a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000288e:	47a1                	li	a5,8
    80002890:	04f70463          	beq	a4,a5,800028d8 <usertrap+0x82>
  } else if((which_dev = devintr()) != 0){
    80002894:	00000097          	auipc	ra,0x0
    80002898:	f20080e7          	jalr	-224(ra) # 800027b4 <devintr>
    8000289c:	892a                	mv	s2,a0
    8000289e:	cd61                	beqz	a0,80002976 <usertrap+0x120>
    if(which_dev == 2 && myproc()->interval) {
    800028a0:	4789                	li	a5,2
    800028a2:	06f50663          	beq	a0,a5,8000290e <usertrap+0xb8>
  if(killed(p))
    800028a6:	8526                	mv	a0,s1
    800028a8:	00000097          	auipc	ra,0x0
    800028ac:	acc080e7          	jalr	-1332(ra) # 80002374 <killed>
    800028b0:	10051063          	bnez	a0,800029b0 <usertrap+0x15a>
  usertrapret();
    800028b4:	00000097          	auipc	ra,0x0
    800028b8:	e24080e7          	jalr	-476(ra) # 800026d8 <usertrapret>
}
    800028bc:	60e2                	ld	ra,24(sp)
    800028be:	6442                	ld	s0,16(sp)
    800028c0:	64a2                	ld	s1,8(sp)
    800028c2:	6902                	ld	s2,0(sp)
    800028c4:	6105                	addi	sp,sp,32
    800028c6:	8082                	ret
    panic("usertrap: not from user mode");
    800028c8:	00006517          	auipc	a0,0x6
    800028cc:	a5850513          	addi	a0,a0,-1448 # 80008320 <states.1741+0x58>
    800028d0:	ffffe097          	auipc	ra,0xffffe
    800028d4:	c74080e7          	jalr	-908(ra) # 80000544 <panic>
    if(killed(p))
    800028d8:	00000097          	auipc	ra,0x0
    800028dc:	a9c080e7          	jalr	-1380(ra) # 80002374 <killed>
    800028e0:	e10d                	bnez	a0,80002902 <usertrap+0xac>
    p->trapframe->epc += 4;
    800028e2:	6cb8                	ld	a4,88(s1)
    800028e4:	6f1c                	ld	a5,24(a4)
    800028e6:	0791                	addi	a5,a5,4
    800028e8:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ea:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028ee:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028f2:	10079073          	csrw	sstatus,a5
    syscall();
    800028f6:	00000097          	auipc	ra,0x0
    800028fa:	31e080e7          	jalr	798(ra) # 80002c14 <syscall>
  int which_dev = 0;
    800028fe:	4901                	li	s2,0
    80002900:	b75d                	j	800028a6 <usertrap+0x50>
      exit(-1);
    80002902:	557d                	li	a0,-1
    80002904:	00000097          	auipc	ra,0x0
    80002908:	8fc080e7          	jalr	-1796(ra) # 80002200 <exit>
    8000290c:	bfd9                	j	800028e2 <usertrap+0x8c>
    if(which_dev == 2 && myproc()->interval) {
    8000290e:	fffff097          	auipc	ra,0xfffff
    80002912:	0b8080e7          	jalr	184(ra) # 800019c6 <myproc>
    80002916:	16c52783          	lw	a5,364(a0)
    8000291a:	ef89                	bnez	a5,80002934 <usertrap+0xde>
  if(killed(p))
    8000291c:	8526                	mv	a0,s1
    8000291e:	00000097          	auipc	ra,0x0
    80002922:	a56080e7          	jalr	-1450(ra) # 80002374 <killed>
    80002926:	cd49                	beqz	a0,800029c0 <usertrap+0x16a>
    exit(-1);
    80002928:	557d                	li	a0,-1
    8000292a:	00000097          	auipc	ra,0x0
    8000292e:	8d6080e7          	jalr	-1834(ra) # 80002200 <exit>
    if(which_dev == 2)
    80002932:	a079                	j	800029c0 <usertrap+0x16a>
      myproc()->ticks_left--;
    80002934:	fffff097          	auipc	ra,0xfffff
    80002938:	092080e7          	jalr	146(ra) # 800019c6 <myproc>
    8000293c:	17052783          	lw	a5,368(a0)
    80002940:	37fd                	addiw	a5,a5,-1
    80002942:	16f52823          	sw	a5,368(a0)
      if(myproc()->ticks_left == 0) {
    80002946:	fffff097          	auipc	ra,0xfffff
    8000294a:	080080e7          	jalr	128(ra) # 800019c6 <myproc>
    8000294e:	17052783          	lw	a5,368(a0)
    80002952:	f7e9                	bnez	a5,8000291c <usertrap+0xc6>
        p->sigalarm_tf = kalloc();
    80002954:	ffffe097          	auipc	ra,0xffffe
    80002958:	1a6080e7          	jalr	422(ra) # 80000afa <kalloc>
    8000295c:	18a4b023          	sd	a0,384(s1)
        memmove(p->sigalarm_tf, p->trapframe, PGSIZE);
    80002960:	6605                	lui	a2,0x1
    80002962:	6cac                	ld	a1,88(s1)
    80002964:	ffffe097          	auipc	ra,0xffffe
    80002968:	3e2080e7          	jalr	994(ra) # 80000d46 <memmove>
        p->trapframe->epc = p->sig_handler;
    8000296c:	6cbc                	ld	a5,88(s1)
    8000296e:	1784b703          	ld	a4,376(s1)
    80002972:	ef98                	sd	a4,24(a5)
    80002974:	b765                	j	8000291c <usertrap+0xc6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002976:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000297a:	5890                	lw	a2,48(s1)
    8000297c:	00006517          	auipc	a0,0x6
    80002980:	9c450513          	addi	a0,a0,-1596 # 80008340 <states.1741+0x78>
    80002984:	ffffe097          	auipc	ra,0xffffe
    80002988:	c0a080e7          	jalr	-1014(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000298c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002990:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002994:	00006517          	auipc	a0,0x6
    80002998:	9dc50513          	addi	a0,a0,-1572 # 80008370 <states.1741+0xa8>
    8000299c:	ffffe097          	auipc	ra,0xffffe
    800029a0:	bf2080e7          	jalr	-1038(ra) # 8000058e <printf>
    setkilled(p);
    800029a4:	8526                	mv	a0,s1
    800029a6:	00000097          	auipc	ra,0x0
    800029aa:	9a2080e7          	jalr	-1630(ra) # 80002348 <setkilled>
    800029ae:	bde5                	j	800028a6 <usertrap+0x50>
    exit(-1);
    800029b0:	557d                	li	a0,-1
    800029b2:	00000097          	auipc	ra,0x0
    800029b6:	84e080e7          	jalr	-1970(ra) # 80002200 <exit>
    if(which_dev == 2)
    800029ba:	4789                	li	a5,2
    800029bc:	eef91ce3          	bne	s2,a5,800028b4 <usertrap+0x5e>
      yield();
    800029c0:	fffff097          	auipc	ra,0xfffff
    800029c4:	6d0080e7          	jalr	1744(ra) # 80002090 <yield>
    800029c8:	b5f5                	j	800028b4 <usertrap+0x5e>

00000000800029ca <kerneltrap>:
{
    800029ca:	7179                	addi	sp,sp,-48
    800029cc:	f406                	sd	ra,40(sp)
    800029ce:	f022                	sd	s0,32(sp)
    800029d0:	ec26                	sd	s1,24(sp)
    800029d2:	e84a                	sd	s2,16(sp)
    800029d4:	e44e                	sd	s3,8(sp)
    800029d6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029d8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029dc:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029e0:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029e4:	1004f793          	andi	a5,s1,256
    800029e8:	cb85                	beqz	a5,80002a18 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ea:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029ee:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029f0:	ef85                	bnez	a5,80002a28 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029f2:	00000097          	auipc	ra,0x0
    800029f6:	dc2080e7          	jalr	-574(ra) # 800027b4 <devintr>
    800029fa:	cd1d                	beqz	a0,80002a38 <kerneltrap+0x6e>
    if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029fc:	4789                	li	a5,2
    800029fe:	06f50a63          	beq	a0,a5,80002a72 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a02:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a06:	10049073          	csrw	sstatus,s1
}
    80002a0a:	70a2                	ld	ra,40(sp)
    80002a0c:	7402                	ld	s0,32(sp)
    80002a0e:	64e2                	ld	s1,24(sp)
    80002a10:	6942                	ld	s2,16(sp)
    80002a12:	69a2                	ld	s3,8(sp)
    80002a14:	6145                	addi	sp,sp,48
    80002a16:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a18:	00006517          	auipc	a0,0x6
    80002a1c:	97850513          	addi	a0,a0,-1672 # 80008390 <states.1741+0xc8>
    80002a20:	ffffe097          	auipc	ra,0xffffe
    80002a24:	b24080e7          	jalr	-1244(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a28:	00006517          	auipc	a0,0x6
    80002a2c:	99050513          	addi	a0,a0,-1648 # 800083b8 <states.1741+0xf0>
    80002a30:	ffffe097          	auipc	ra,0xffffe
    80002a34:	b14080e7          	jalr	-1260(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    80002a38:	85ce                	mv	a1,s3
    80002a3a:	00006517          	auipc	a0,0x6
    80002a3e:	99e50513          	addi	a0,a0,-1634 # 800083d8 <states.1741+0x110>
    80002a42:	ffffe097          	auipc	ra,0xffffe
    80002a46:	b4c080e7          	jalr	-1204(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a4a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a4e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a52:	00006517          	auipc	a0,0x6
    80002a56:	99650513          	addi	a0,a0,-1642 # 800083e8 <states.1741+0x120>
    80002a5a:	ffffe097          	auipc	ra,0xffffe
    80002a5e:	b34080e7          	jalr	-1228(ra) # 8000058e <printf>
    panic("kerneltrap");
    80002a62:	00006517          	auipc	a0,0x6
    80002a66:	99e50513          	addi	a0,a0,-1634 # 80008400 <states.1741+0x138>
    80002a6a:	ffffe097          	auipc	ra,0xffffe
    80002a6e:	ada080e7          	jalr	-1318(ra) # 80000544 <panic>
    if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a72:	fffff097          	auipc	ra,0xfffff
    80002a76:	f54080e7          	jalr	-172(ra) # 800019c6 <myproc>
    80002a7a:	d541                	beqz	a0,80002a02 <kerneltrap+0x38>
    80002a7c:	fffff097          	auipc	ra,0xfffff
    80002a80:	f4a080e7          	jalr	-182(ra) # 800019c6 <myproc>
    80002a84:	4d18                	lw	a4,24(a0)
    80002a86:	4791                	li	a5,4
    80002a88:	f6f71de3          	bne	a4,a5,80002a02 <kerneltrap+0x38>
      yield();
    80002a8c:	fffff097          	auipc	ra,0xfffff
    80002a90:	604080e7          	jalr	1540(ra) # 80002090 <yield>
    80002a94:	b7bd                	j	80002a02 <kerneltrap+0x38>

0000000080002a96 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a96:	1101                	addi	sp,sp,-32
    80002a98:	ec06                	sd	ra,24(sp)
    80002a9a:	e822                	sd	s0,16(sp)
    80002a9c:	e426                	sd	s1,8(sp)
    80002a9e:	1000                	addi	s0,sp,32
    80002aa0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002aa2:	fffff097          	auipc	ra,0xfffff
    80002aa6:	f24080e7          	jalr	-220(ra) # 800019c6 <myproc>
  switch (n) {
    80002aaa:	4795                	li	a5,5
    80002aac:	0497e163          	bltu	a5,s1,80002aee <argraw+0x58>
    80002ab0:	048a                	slli	s1,s1,0x2
    80002ab2:	00006717          	auipc	a4,0x6
    80002ab6:	a6670713          	addi	a4,a4,-1434 # 80008518 <states.1741+0x250>
    80002aba:	94ba                	add	s1,s1,a4
    80002abc:	409c                	lw	a5,0(s1)
    80002abe:	97ba                	add	a5,a5,a4
    80002ac0:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002ac2:	6d3c                	ld	a5,88(a0)
    80002ac4:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ac6:	60e2                	ld	ra,24(sp)
    80002ac8:	6442                	ld	s0,16(sp)
    80002aca:	64a2                	ld	s1,8(sp)
    80002acc:	6105                	addi	sp,sp,32
    80002ace:	8082                	ret
    return p->trapframe->a1;
    80002ad0:	6d3c                	ld	a5,88(a0)
    80002ad2:	7fa8                	ld	a0,120(a5)
    80002ad4:	bfcd                	j	80002ac6 <argraw+0x30>
    return p->trapframe->a2;
    80002ad6:	6d3c                	ld	a5,88(a0)
    80002ad8:	63c8                	ld	a0,128(a5)
    80002ada:	b7f5                	j	80002ac6 <argraw+0x30>
    return p->trapframe->a3;
    80002adc:	6d3c                	ld	a5,88(a0)
    80002ade:	67c8                	ld	a0,136(a5)
    80002ae0:	b7dd                	j	80002ac6 <argraw+0x30>
    return p->trapframe->a4;
    80002ae2:	6d3c                	ld	a5,88(a0)
    80002ae4:	6bc8                	ld	a0,144(a5)
    80002ae6:	b7c5                	j	80002ac6 <argraw+0x30>
    return p->trapframe->a5;
    80002ae8:	6d3c                	ld	a5,88(a0)
    80002aea:	6fc8                	ld	a0,152(a5)
    80002aec:	bfe9                	j	80002ac6 <argraw+0x30>
  panic("argraw");
    80002aee:	00006517          	auipc	a0,0x6
    80002af2:	92250513          	addi	a0,a0,-1758 # 80008410 <states.1741+0x148>
    80002af6:	ffffe097          	auipc	ra,0xffffe
    80002afa:	a4e080e7          	jalr	-1458(ra) # 80000544 <panic>

0000000080002afe <fetchaddr>:
{
    80002afe:	1101                	addi	sp,sp,-32
    80002b00:	ec06                	sd	ra,24(sp)
    80002b02:	e822                	sd	s0,16(sp)
    80002b04:	e426                	sd	s1,8(sp)
    80002b06:	e04a                	sd	s2,0(sp)
    80002b08:	1000                	addi	s0,sp,32
    80002b0a:	84aa                	mv	s1,a0
    80002b0c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b0e:	fffff097          	auipc	ra,0xfffff
    80002b12:	eb8080e7          	jalr	-328(ra) # 800019c6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002b16:	653c                	ld	a5,72(a0)
    80002b18:	02f4f863          	bgeu	s1,a5,80002b48 <fetchaddr+0x4a>
    80002b1c:	00848713          	addi	a4,s1,8
    80002b20:	02e7e663          	bltu	a5,a4,80002b4c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b24:	46a1                	li	a3,8
    80002b26:	8626                	mv	a2,s1
    80002b28:	85ca                	mv	a1,s2
    80002b2a:	6928                	ld	a0,80(a0)
    80002b2c:	fffff097          	auipc	ra,0xfffff
    80002b30:	be4080e7          	jalr	-1052(ra) # 80001710 <copyin>
    80002b34:	00a03533          	snez	a0,a0
    80002b38:	40a00533          	neg	a0,a0
}
    80002b3c:	60e2                	ld	ra,24(sp)
    80002b3e:	6442                	ld	s0,16(sp)
    80002b40:	64a2                	ld	s1,8(sp)
    80002b42:	6902                	ld	s2,0(sp)
    80002b44:	6105                	addi	sp,sp,32
    80002b46:	8082                	ret
    return -1;
    80002b48:	557d                	li	a0,-1
    80002b4a:	bfcd                	j	80002b3c <fetchaddr+0x3e>
    80002b4c:	557d                	li	a0,-1
    80002b4e:	b7fd                	j	80002b3c <fetchaddr+0x3e>

0000000080002b50 <fetchstr>:
{
    80002b50:	7179                	addi	sp,sp,-48
    80002b52:	f406                	sd	ra,40(sp)
    80002b54:	f022                	sd	s0,32(sp)
    80002b56:	ec26                	sd	s1,24(sp)
    80002b58:	e84a                	sd	s2,16(sp)
    80002b5a:	e44e                	sd	s3,8(sp)
    80002b5c:	1800                	addi	s0,sp,48
    80002b5e:	892a                	mv	s2,a0
    80002b60:	84ae                	mv	s1,a1
    80002b62:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b64:	fffff097          	auipc	ra,0xfffff
    80002b68:	e62080e7          	jalr	-414(ra) # 800019c6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002b6c:	86ce                	mv	a3,s3
    80002b6e:	864a                	mv	a2,s2
    80002b70:	85a6                	mv	a1,s1
    80002b72:	6928                	ld	a0,80(a0)
    80002b74:	fffff097          	auipc	ra,0xfffff
    80002b78:	c28080e7          	jalr	-984(ra) # 8000179c <copyinstr>
    80002b7c:	00054e63          	bltz	a0,80002b98 <fetchstr+0x48>
  return strlen(buf);
    80002b80:	8526                	mv	a0,s1
    80002b82:	ffffe097          	auipc	ra,0xffffe
    80002b86:	2e8080e7          	jalr	744(ra) # 80000e6a <strlen>
}
    80002b8a:	70a2                	ld	ra,40(sp)
    80002b8c:	7402                	ld	s0,32(sp)
    80002b8e:	64e2                	ld	s1,24(sp)
    80002b90:	6942                	ld	s2,16(sp)
    80002b92:	69a2                	ld	s3,8(sp)
    80002b94:	6145                	addi	sp,sp,48
    80002b96:	8082                	ret
    return -1;
    80002b98:	557d                	li	a0,-1
    80002b9a:	bfc5                	j	80002b8a <fetchstr+0x3a>

0000000080002b9c <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002b9c:	1101                	addi	sp,sp,-32
    80002b9e:	ec06                	sd	ra,24(sp)
    80002ba0:	e822                	sd	s0,16(sp)
    80002ba2:	e426                	sd	s1,8(sp)
    80002ba4:	1000                	addi	s0,sp,32
    80002ba6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ba8:	00000097          	auipc	ra,0x0
    80002bac:	eee080e7          	jalr	-274(ra) # 80002a96 <argraw>
    80002bb0:	c088                	sw	a0,0(s1)
}
    80002bb2:	60e2                	ld	ra,24(sp)
    80002bb4:	6442                	ld	s0,16(sp)
    80002bb6:	64a2                	ld	s1,8(sp)
    80002bb8:	6105                	addi	sp,sp,32
    80002bba:	8082                	ret

0000000080002bbc <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002bbc:	1101                	addi	sp,sp,-32
    80002bbe:	ec06                	sd	ra,24(sp)
    80002bc0:	e822                	sd	s0,16(sp)
    80002bc2:	e426                	sd	s1,8(sp)
    80002bc4:	1000                	addi	s0,sp,32
    80002bc6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bc8:	00000097          	auipc	ra,0x0
    80002bcc:	ece080e7          	jalr	-306(ra) # 80002a96 <argraw>
    80002bd0:	e088                	sd	a0,0(s1)
}
    80002bd2:	60e2                	ld	ra,24(sp)
    80002bd4:	6442                	ld	s0,16(sp)
    80002bd6:	64a2                	ld	s1,8(sp)
    80002bd8:	6105                	addi	sp,sp,32
    80002bda:	8082                	ret

0000000080002bdc <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bdc:	7179                	addi	sp,sp,-48
    80002bde:	f406                	sd	ra,40(sp)
    80002be0:	f022                	sd	s0,32(sp)
    80002be2:	ec26                	sd	s1,24(sp)
    80002be4:	e84a                	sd	s2,16(sp)
    80002be6:	1800                	addi	s0,sp,48
    80002be8:	84ae                	mv	s1,a1
    80002bea:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002bec:	fd840593          	addi	a1,s0,-40
    80002bf0:	00000097          	auipc	ra,0x0
    80002bf4:	fcc080e7          	jalr	-52(ra) # 80002bbc <argaddr>
  return fetchstr(addr, buf, max);
    80002bf8:	864a                	mv	a2,s2
    80002bfa:	85a6                	mv	a1,s1
    80002bfc:	fd843503          	ld	a0,-40(s0)
    80002c00:	00000097          	auipc	ra,0x0
    80002c04:	f50080e7          	jalr	-176(ra) # 80002b50 <fetchstr>
}
    80002c08:	70a2                	ld	ra,40(sp)
    80002c0a:	7402                	ld	s0,32(sp)
    80002c0c:	64e2                	ld	s1,24(sp)
    80002c0e:	6942                	ld	s2,16(sp)
    80002c10:	6145                	addi	sp,sp,48
    80002c12:	8082                	ret

0000000080002c14 <syscall>:
[SYS_sigreturn] "sigreturn ",
};

void
syscall(void)
{
    80002c14:	7179                	addi	sp,sp,-48
    80002c16:	f406                	sd	ra,40(sp)
    80002c18:	f022                	sd	s0,32(sp)
    80002c1a:	ec26                	sd	s1,24(sp)
    80002c1c:	e84a                	sd	s2,16(sp)
    80002c1e:	e44e                	sd	s3,8(sp)
    80002c20:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80002c22:	fffff097          	auipc	ra,0xfffff
    80002c26:	da4080e7          	jalr	-604(ra) # 800019c6 <myproc>
    80002c2a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c2c:	05853903          	ld	s2,88(a0)
    80002c30:	0a893783          	ld	a5,168(s2)
    80002c34:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c38:	37fd                	addiw	a5,a5,-1
    80002c3a:	4765                	li	a4,25
    80002c3c:	04f76763          	bltu	a4,a5,80002c8a <syscall+0x76>
    80002c40:	00399713          	slli	a4,s3,0x3
    80002c44:	00006797          	auipc	a5,0x6
    80002c48:	8ec78793          	addi	a5,a5,-1812 # 80008530 <syscalls>
    80002c4c:	97ba                	add	a5,a5,a4
    80002c4e:	639c                	ld	a5,0(a5)
    80002c50:	cf8d                	beqz	a5,80002c8a <syscall+0x76>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002c52:	9782                	jalr	a5
    80002c54:	06a93823          	sd	a0,112(s2)

    // Check for trace_flag to be on
    if(p->trace_flag >> num) {  // check for '=='
    80002c58:	1684a783          	lw	a5,360(s1)
    80002c5c:	4137d7bb          	sraw	a5,a5,s3
    80002c60:	c7a1                	beqz	a5,80002ca8 <syscall+0x94>
      printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0);
    80002c62:	6cb8                	ld	a4,88(s1)
    80002c64:	098e                	slli	s3,s3,0x3
    80002c66:	00006797          	auipc	a5,0x6
    80002c6a:	d3278793          	addi	a5,a5,-718 # 80008998 <syscall_names>
    80002c6e:	99be                	add	s3,s3,a5
    80002c70:	7b34                	ld	a3,112(a4)
    80002c72:	0009b603          	ld	a2,0(s3)
    80002c76:	588c                	lw	a1,48(s1)
    80002c78:	00005517          	auipc	a0,0x5
    80002c7c:	7a050513          	addi	a0,a0,1952 # 80008418 <states.1741+0x150>
    80002c80:	ffffe097          	auipc	ra,0xffffe
    80002c84:	90e080e7          	jalr	-1778(ra) # 8000058e <printf>
    80002c88:	a005                	j	80002ca8 <syscall+0x94>
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c8a:	86ce                	mv	a3,s3
    80002c8c:	15848613          	addi	a2,s1,344
    80002c90:	588c                	lw	a1,48(s1)
    80002c92:	00005517          	auipc	a0,0x5
    80002c96:	79e50513          	addi	a0,a0,1950 # 80008430 <states.1741+0x168>
    80002c9a:	ffffe097          	auipc	ra,0xffffe
    80002c9e:	8f4080e7          	jalr	-1804(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ca2:	6cbc                	ld	a5,88(s1)
    80002ca4:	577d                	li	a4,-1
    80002ca6:	fbb8                	sd	a4,112(a5)
  }
}
    80002ca8:	70a2                	ld	ra,40(sp)
    80002caa:	7402                	ld	s0,32(sp)
    80002cac:	64e2                	ld	s1,24(sp)
    80002cae:	6942                	ld	s2,16(sp)
    80002cb0:	69a2                	ld	s3,8(sp)
    80002cb2:	6145                	addi	sp,sp,48
    80002cb4:	8082                	ret

0000000080002cb6 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002cb6:	1101                	addi	sp,sp,-32
    80002cb8:	ec06                	sd	ra,24(sp)
    80002cba:	e822                	sd	s0,16(sp)
    80002cbc:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002cbe:	fec40593          	addi	a1,s0,-20
    80002cc2:	4501                	li	a0,0
    80002cc4:	00000097          	auipc	ra,0x0
    80002cc8:	ed8080e7          	jalr	-296(ra) # 80002b9c <argint>
  exit(n);
    80002ccc:	fec42503          	lw	a0,-20(s0)
    80002cd0:	fffff097          	auipc	ra,0xfffff
    80002cd4:	530080e7          	jalr	1328(ra) # 80002200 <exit>
  return 0;  // not reached
}
    80002cd8:	4501                	li	a0,0
    80002cda:	60e2                	ld	ra,24(sp)
    80002cdc:	6442                	ld	s0,16(sp)
    80002cde:	6105                	addi	sp,sp,32
    80002ce0:	8082                	ret

0000000080002ce2 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002ce2:	1141                	addi	sp,sp,-16
    80002ce4:	e406                	sd	ra,8(sp)
    80002ce6:	e022                	sd	s0,0(sp)
    80002ce8:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002cea:	fffff097          	auipc	ra,0xfffff
    80002cee:	cdc080e7          	jalr	-804(ra) # 800019c6 <myproc>
}
    80002cf2:	5908                	lw	a0,48(a0)
    80002cf4:	60a2                	ld	ra,8(sp)
    80002cf6:	6402                	ld	s0,0(sp)
    80002cf8:	0141                	addi	sp,sp,16
    80002cfa:	8082                	ret

0000000080002cfc <sys_fork>:

uint64
sys_fork(void)
{
    80002cfc:	1141                	addi	sp,sp,-16
    80002cfe:	e406                	sd	ra,8(sp)
    80002d00:	e022                	sd	s0,0(sp)
    80002d02:	0800                	addi	s0,sp,16
  return fork();
    80002d04:	fffff097          	auipc	ra,0xfffff
    80002d08:	08a080e7          	jalr	138(ra) # 80001d8e <fork>
}
    80002d0c:	60a2                	ld	ra,8(sp)
    80002d0e:	6402                	ld	s0,0(sp)
    80002d10:	0141                	addi	sp,sp,16
    80002d12:	8082                	ret

0000000080002d14 <sys_wait>:

uint64
sys_wait(void)
{
    80002d14:	1101                	addi	sp,sp,-32
    80002d16:	ec06                	sd	ra,24(sp)
    80002d18:	e822                	sd	s0,16(sp)
    80002d1a:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002d1c:	fe840593          	addi	a1,s0,-24
    80002d20:	4501                	li	a0,0
    80002d22:	00000097          	auipc	ra,0x0
    80002d26:	e9a080e7          	jalr	-358(ra) # 80002bbc <argaddr>
  return wait(p);
    80002d2a:	fe843503          	ld	a0,-24(s0)
    80002d2e:	fffff097          	auipc	ra,0xfffff
    80002d32:	678080e7          	jalr	1656(ra) # 800023a6 <wait>
}
    80002d36:	60e2                	ld	ra,24(sp)
    80002d38:	6442                	ld	s0,16(sp)
    80002d3a:	6105                	addi	sp,sp,32
    80002d3c:	8082                	ret

0000000080002d3e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d3e:	7179                	addi	sp,sp,-48
    80002d40:	f406                	sd	ra,40(sp)
    80002d42:	f022                	sd	s0,32(sp)
    80002d44:	ec26                	sd	s1,24(sp)
    80002d46:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002d48:	fdc40593          	addi	a1,s0,-36
    80002d4c:	4501                	li	a0,0
    80002d4e:	00000097          	auipc	ra,0x0
    80002d52:	e4e080e7          	jalr	-434(ra) # 80002b9c <argint>
  addr = myproc()->sz;
    80002d56:	fffff097          	auipc	ra,0xfffff
    80002d5a:	c70080e7          	jalr	-912(ra) # 800019c6 <myproc>
    80002d5e:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002d60:	fdc42503          	lw	a0,-36(s0)
    80002d64:	fffff097          	auipc	ra,0xfffff
    80002d68:	fce080e7          	jalr	-50(ra) # 80001d32 <growproc>
    80002d6c:	00054863          	bltz	a0,80002d7c <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002d70:	8526                	mv	a0,s1
    80002d72:	70a2                	ld	ra,40(sp)
    80002d74:	7402                	ld	s0,32(sp)
    80002d76:	64e2                	ld	s1,24(sp)
    80002d78:	6145                	addi	sp,sp,48
    80002d7a:	8082                	ret
    return -1;
    80002d7c:	54fd                	li	s1,-1
    80002d7e:	bfcd                	j	80002d70 <sys_sbrk+0x32>

0000000080002d80 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d80:	7139                	addi	sp,sp,-64
    80002d82:	fc06                	sd	ra,56(sp)
    80002d84:	f822                	sd	s0,48(sp)
    80002d86:	f426                	sd	s1,40(sp)
    80002d88:	f04a                	sd	s2,32(sp)
    80002d8a:	ec4e                	sd	s3,24(sp)
    80002d8c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002d8e:	fcc40593          	addi	a1,s0,-52
    80002d92:	4501                	li	a0,0
    80002d94:	00000097          	auipc	ra,0x0
    80002d98:	e08080e7          	jalr	-504(ra) # 80002b9c <argint>
  acquire(&tickslock);
    80002d9c:	00014517          	auipc	a0,0x14
    80002da0:	7c450513          	addi	a0,a0,1988 # 80017560 <tickslock>
    80002da4:	ffffe097          	auipc	ra,0xffffe
    80002da8:	e46080e7          	jalr	-442(ra) # 80000bea <acquire>
  ticks0 = ticks;
    80002dac:	00006917          	auipc	s2,0x6
    80002db0:	d1492903          	lw	s2,-748(s2) # 80008ac0 <ticks>
  while(ticks - ticks0 < n){
    80002db4:	fcc42783          	lw	a5,-52(s0)
    80002db8:	cf9d                	beqz	a5,80002df6 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002dba:	00014997          	auipc	s3,0x14
    80002dbe:	7a698993          	addi	s3,s3,1958 # 80017560 <tickslock>
    80002dc2:	00006497          	auipc	s1,0x6
    80002dc6:	cfe48493          	addi	s1,s1,-770 # 80008ac0 <ticks>
    if(killed(myproc())){
    80002dca:	fffff097          	auipc	ra,0xfffff
    80002dce:	bfc080e7          	jalr	-1028(ra) # 800019c6 <myproc>
    80002dd2:	fffff097          	auipc	ra,0xfffff
    80002dd6:	5a2080e7          	jalr	1442(ra) # 80002374 <killed>
    80002dda:	ed15                	bnez	a0,80002e16 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002ddc:	85ce                	mv	a1,s3
    80002dde:	8526                	mv	a0,s1
    80002de0:	fffff097          	auipc	ra,0xfffff
    80002de4:	2ec080e7          	jalr	748(ra) # 800020cc <sleep>
  while(ticks - ticks0 < n){
    80002de8:	409c                	lw	a5,0(s1)
    80002dea:	412787bb          	subw	a5,a5,s2
    80002dee:	fcc42703          	lw	a4,-52(s0)
    80002df2:	fce7ece3          	bltu	a5,a4,80002dca <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002df6:	00014517          	auipc	a0,0x14
    80002dfa:	76a50513          	addi	a0,a0,1898 # 80017560 <tickslock>
    80002dfe:	ffffe097          	auipc	ra,0xffffe
    80002e02:	ea0080e7          	jalr	-352(ra) # 80000c9e <release>
  return 0;
    80002e06:	4501                	li	a0,0
}
    80002e08:	70e2                	ld	ra,56(sp)
    80002e0a:	7442                	ld	s0,48(sp)
    80002e0c:	74a2                	ld	s1,40(sp)
    80002e0e:	7902                	ld	s2,32(sp)
    80002e10:	69e2                	ld	s3,24(sp)
    80002e12:	6121                	addi	sp,sp,64
    80002e14:	8082                	ret
      release(&tickslock);
    80002e16:	00014517          	auipc	a0,0x14
    80002e1a:	74a50513          	addi	a0,a0,1866 # 80017560 <tickslock>
    80002e1e:	ffffe097          	auipc	ra,0xffffe
    80002e22:	e80080e7          	jalr	-384(ra) # 80000c9e <release>
      return -1;
    80002e26:	557d                	li	a0,-1
    80002e28:	b7c5                	j	80002e08 <sys_sleep+0x88>

0000000080002e2a <sys_kill>:

uint64
sys_kill(void)
{
    80002e2a:	1101                	addi	sp,sp,-32
    80002e2c:	ec06                	sd	ra,24(sp)
    80002e2e:	e822                	sd	s0,16(sp)
    80002e30:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002e32:	fec40593          	addi	a1,s0,-20
    80002e36:	4501                	li	a0,0
    80002e38:	00000097          	auipc	ra,0x0
    80002e3c:	d64080e7          	jalr	-668(ra) # 80002b9c <argint>
  return kill(pid);
    80002e40:	fec42503          	lw	a0,-20(s0)
    80002e44:	fffff097          	auipc	ra,0xfffff
    80002e48:	492080e7          	jalr	1170(ra) # 800022d6 <kill>
}
    80002e4c:	60e2                	ld	ra,24(sp)
    80002e4e:	6442                	ld	s0,16(sp)
    80002e50:	6105                	addi	sp,sp,32
    80002e52:	8082                	ret

0000000080002e54 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e54:	1101                	addi	sp,sp,-32
    80002e56:	ec06                	sd	ra,24(sp)
    80002e58:	e822                	sd	s0,16(sp)
    80002e5a:	e426                	sd	s1,8(sp)
    80002e5c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e5e:	00014517          	auipc	a0,0x14
    80002e62:	70250513          	addi	a0,a0,1794 # 80017560 <tickslock>
    80002e66:	ffffe097          	auipc	ra,0xffffe
    80002e6a:	d84080e7          	jalr	-636(ra) # 80000bea <acquire>
  xticks = ticks;
    80002e6e:	00006497          	auipc	s1,0x6
    80002e72:	c524a483          	lw	s1,-942(s1) # 80008ac0 <ticks>
  release(&tickslock);
    80002e76:	00014517          	auipc	a0,0x14
    80002e7a:	6ea50513          	addi	a0,a0,1770 # 80017560 <tickslock>
    80002e7e:	ffffe097          	auipc	ra,0xffffe
    80002e82:	e20080e7          	jalr	-480(ra) # 80000c9e <release>
  return xticks;
}
    80002e86:	02049513          	slli	a0,s1,0x20
    80002e8a:	9101                	srli	a0,a0,0x20
    80002e8c:	60e2                	ld	ra,24(sp)
    80002e8e:	6442                	ld	s0,16(sp)
    80002e90:	64a2                	ld	s1,8(sp)
    80002e92:	6105                	addi	sp,sp,32
    80002e94:	8082                	ret

0000000080002e96 <sys_trace>:

// sets the trace_flag to the first argument (a0)
uint64
sys_trace(void)
{
    80002e96:	1141                	addi	sp,sp,-16
    80002e98:	e406                	sd	ra,8(sp)
    80002e9a:	e022                	sd	s0,0(sp)
    80002e9c:	0800                	addi	s0,sp,16
  argint(0, &myproc()->trace_flag); //arg(a0, trace_flag) // returns void
    80002e9e:	fffff097          	auipc	ra,0xfffff
    80002ea2:	b28080e7          	jalr	-1240(ra) # 800019c6 <myproc>
    80002ea6:	16850593          	addi	a1,a0,360
    80002eaa:	4501                	li	a0,0
    80002eac:	00000097          	auipc	ra,0x0
    80002eb0:	cf0080e7          	jalr	-784(ra) # 80002b9c <argint>
  return 0;
}
    80002eb4:	4501                	li	a0,0
    80002eb6:	60a2                	ld	ra,8(sp)
    80002eb8:	6402                	ld	s0,0(sp)
    80002eba:	0141                	addi	sp,sp,16
    80002ebc:	8082                	ret

0000000080002ebe <sys_sigalarm>:

// sets the 
uint64
sys_sigalarm(void)
{
    80002ebe:	1101                	addi	sp,sp,-32
    80002ec0:	ec06                	sd	ra,24(sp)
    80002ec2:	e822                	sd	s0,16(sp)
    80002ec4:	e426                	sd	s1,8(sp)
    80002ec6:	1000                	addi	s0,sp,32
  // sets the interval and handler after every tick
  argint(0, &myproc()->interval);
    80002ec8:	fffff097          	auipc	ra,0xfffff
    80002ecc:	afe080e7          	jalr	-1282(ra) # 800019c6 <myproc>
    80002ed0:	16c50593          	addi	a1,a0,364
    80002ed4:	4501                	li	a0,0
    80002ed6:	00000097          	auipc	ra,0x0
    80002eda:	cc6080e7          	jalr	-826(ra) # 80002b9c <argint>
  argaddr(1, &myproc()->sig_handler);
    80002ede:	fffff097          	auipc	ra,0xfffff
    80002ee2:	ae8080e7          	jalr	-1304(ra) # 800019c6 <myproc>
    80002ee6:	17850593          	addi	a1,a0,376
    80002eea:	4505                	li	a0,1
    80002eec:	00000097          	auipc	ra,0x0
    80002ef0:	cd0080e7          	jalr	-816(ra) # 80002bbc <argaddr>
  
  // sets ticks_passed as the interval
  myproc()->ticks_left = myproc()->interval;
    80002ef4:	fffff097          	auipc	ra,0xfffff
    80002ef8:	ad2080e7          	jalr	-1326(ra) # 800019c6 <myproc>
    80002efc:	84aa                	mv	s1,a0
    80002efe:	fffff097          	auipc	ra,0xfffff
    80002f02:	ac8080e7          	jalr	-1336(ra) # 800019c6 <myproc>
    80002f06:	16c4a783          	lw	a5,364(s1)
    80002f0a:	16f52823          	sw	a5,368(a0)
  return 0;
}
    80002f0e:	4501                	li	a0,0
    80002f10:	60e2                	ld	ra,24(sp)
    80002f12:	6442                	ld	s0,16(sp)
    80002f14:	64a2                	ld	s1,8(sp)
    80002f16:	6105                	addi	sp,sp,32
    80002f18:	8082                	ret

0000000080002f1a <sys_sigreturn>:

uint64 
sys_sigreturn(void)
{
    80002f1a:	1101                	addi	sp,sp,-32
    80002f1c:	ec06                	sd	ra,24(sp)
    80002f1e:	e822                	sd	s0,16(sp)
    80002f20:	e426                	sd	s1,8(sp)
    80002f22:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002f24:	fffff097          	auipc	ra,0xfffff
    80002f28:	aa2080e7          	jalr	-1374(ra) # 800019c6 <myproc>
    80002f2c:	84aa                	mv	s1,a0
  memmove(p->trapframe, p->sigalarm_tf, PGSIZE);
    80002f2e:	6605                	lui	a2,0x1
    80002f30:	18053583          	ld	a1,384(a0)
    80002f34:	6d28                	ld	a0,88(a0)
    80002f36:	ffffe097          	auipc	ra,0xffffe
    80002f3a:	e10080e7          	jalr	-496(ra) # 80000d46 <memmove>
  kfree(p->sigalarm_tf);
    80002f3e:	1804b503          	ld	a0,384(s1)
    80002f42:	ffffe097          	auipc	ra,0xffffe
    80002f46:	abc080e7          	jalr	-1348(ra) # 800009fe <kfree>
  p->ticks_left = p->interval;
    80002f4a:	16c4a783          	lw	a5,364(s1)
    80002f4e:	16f4a823          	sw	a5,368(s1)
  return p->trapframe->a0;
    80002f52:	6cbc                	ld	a5,88(s1)
}
    80002f54:	7ba8                	ld	a0,112(a5)
    80002f56:	60e2                	ld	ra,24(sp)
    80002f58:	6442                	ld	s0,16(sp)
    80002f5a:	64a2                	ld	s1,8(sp)
    80002f5c:	6105                	addi	sp,sp,32
    80002f5e:	8082                	ret

0000000080002f60 <sys_settickets>:

uint64 
sys_settickets(void)
{
    80002f60:	1141                	addi	sp,sp,-16
    80002f62:	e406                	sd	ra,8(sp)
    80002f64:	e022                	sd	s0,0(sp)
    80002f66:	0800                	addi	s0,sp,16
  argint(0, &myproc()->tickets);
    80002f68:	fffff097          	auipc	ra,0xfffff
    80002f6c:	a5e080e7          	jalr	-1442(ra) # 800019c6 <myproc>
    80002f70:	18c50593          	addi	a1,a0,396
    80002f74:	4501                	li	a0,0
    80002f76:	00000097          	auipc	ra,0x0
    80002f7a:	c26080e7          	jalr	-986(ra) # 80002b9c <argint>
  return myproc()->tickets;
    80002f7e:	fffff097          	auipc	ra,0xfffff
    80002f82:	a48080e7          	jalr	-1464(ra) # 800019c6 <myproc>
    80002f86:	18c52503          	lw	a0,396(a0)
    80002f8a:	60a2                	ld	ra,8(sp)
    80002f8c:	6402                	ld	s0,0(sp)
    80002f8e:	0141                	addi	sp,sp,16
    80002f90:	8082                	ret

0000000080002f92 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f92:	7179                	addi	sp,sp,-48
    80002f94:	f406                	sd	ra,40(sp)
    80002f96:	f022                	sd	s0,32(sp)
    80002f98:	ec26                	sd	s1,24(sp)
    80002f9a:	e84a                	sd	s2,16(sp)
    80002f9c:	e44e                	sd	s3,8(sp)
    80002f9e:	e052                	sd	s4,0(sp)
    80002fa0:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002fa2:	00005597          	auipc	a1,0x5
    80002fa6:	66658593          	addi	a1,a1,1638 # 80008608 <syscalls+0xd8>
    80002faa:	00014517          	auipc	a0,0x14
    80002fae:	5ce50513          	addi	a0,a0,1486 # 80017578 <bcache>
    80002fb2:	ffffe097          	auipc	ra,0xffffe
    80002fb6:	ba8080e7          	jalr	-1112(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002fba:	0001c797          	auipc	a5,0x1c
    80002fbe:	5be78793          	addi	a5,a5,1470 # 8001f578 <bcache+0x8000>
    80002fc2:	0001d717          	auipc	a4,0x1d
    80002fc6:	81e70713          	addi	a4,a4,-2018 # 8001f7e0 <bcache+0x8268>
    80002fca:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002fce:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fd2:	00014497          	auipc	s1,0x14
    80002fd6:	5be48493          	addi	s1,s1,1470 # 80017590 <bcache+0x18>
    b->next = bcache.head.next;
    80002fda:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002fdc:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002fde:	00005a17          	auipc	s4,0x5
    80002fe2:	632a0a13          	addi	s4,s4,1586 # 80008610 <syscalls+0xe0>
    b->next = bcache.head.next;
    80002fe6:	2b893783          	ld	a5,696(s2)
    80002fea:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002fec:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002ff0:	85d2                	mv	a1,s4
    80002ff2:	01048513          	addi	a0,s1,16
    80002ff6:	00001097          	auipc	ra,0x1
    80002ffa:	4c4080e7          	jalr	1220(ra) # 800044ba <initsleeplock>
    bcache.head.next->prev = b;
    80002ffe:	2b893783          	ld	a5,696(s2)
    80003002:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003004:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003008:	45848493          	addi	s1,s1,1112
    8000300c:	fd349de3          	bne	s1,s3,80002fe6 <binit+0x54>
  }
}
    80003010:	70a2                	ld	ra,40(sp)
    80003012:	7402                	ld	s0,32(sp)
    80003014:	64e2                	ld	s1,24(sp)
    80003016:	6942                	ld	s2,16(sp)
    80003018:	69a2                	ld	s3,8(sp)
    8000301a:	6a02                	ld	s4,0(sp)
    8000301c:	6145                	addi	sp,sp,48
    8000301e:	8082                	ret

0000000080003020 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003020:	7179                	addi	sp,sp,-48
    80003022:	f406                	sd	ra,40(sp)
    80003024:	f022                	sd	s0,32(sp)
    80003026:	ec26                	sd	s1,24(sp)
    80003028:	e84a                	sd	s2,16(sp)
    8000302a:	e44e                	sd	s3,8(sp)
    8000302c:	1800                	addi	s0,sp,48
    8000302e:	89aa                	mv	s3,a0
    80003030:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003032:	00014517          	auipc	a0,0x14
    80003036:	54650513          	addi	a0,a0,1350 # 80017578 <bcache>
    8000303a:	ffffe097          	auipc	ra,0xffffe
    8000303e:	bb0080e7          	jalr	-1104(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003042:	0001c497          	auipc	s1,0x1c
    80003046:	7ee4b483          	ld	s1,2030(s1) # 8001f830 <bcache+0x82b8>
    8000304a:	0001c797          	auipc	a5,0x1c
    8000304e:	79678793          	addi	a5,a5,1942 # 8001f7e0 <bcache+0x8268>
    80003052:	02f48f63          	beq	s1,a5,80003090 <bread+0x70>
    80003056:	873e                	mv	a4,a5
    80003058:	a021                	j	80003060 <bread+0x40>
    8000305a:	68a4                	ld	s1,80(s1)
    8000305c:	02e48a63          	beq	s1,a4,80003090 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003060:	449c                	lw	a5,8(s1)
    80003062:	ff379ce3          	bne	a5,s3,8000305a <bread+0x3a>
    80003066:	44dc                	lw	a5,12(s1)
    80003068:	ff2799e3          	bne	a5,s2,8000305a <bread+0x3a>
      b->refcnt++;
    8000306c:	40bc                	lw	a5,64(s1)
    8000306e:	2785                	addiw	a5,a5,1
    80003070:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003072:	00014517          	auipc	a0,0x14
    80003076:	50650513          	addi	a0,a0,1286 # 80017578 <bcache>
    8000307a:	ffffe097          	auipc	ra,0xffffe
    8000307e:	c24080e7          	jalr	-988(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80003082:	01048513          	addi	a0,s1,16
    80003086:	00001097          	auipc	ra,0x1
    8000308a:	46e080e7          	jalr	1134(ra) # 800044f4 <acquiresleep>
      return b;
    8000308e:	a8b9                	j	800030ec <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003090:	0001c497          	auipc	s1,0x1c
    80003094:	7984b483          	ld	s1,1944(s1) # 8001f828 <bcache+0x82b0>
    80003098:	0001c797          	auipc	a5,0x1c
    8000309c:	74878793          	addi	a5,a5,1864 # 8001f7e0 <bcache+0x8268>
    800030a0:	00f48863          	beq	s1,a5,800030b0 <bread+0x90>
    800030a4:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800030a6:	40bc                	lw	a5,64(s1)
    800030a8:	cf81                	beqz	a5,800030c0 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030aa:	64a4                	ld	s1,72(s1)
    800030ac:	fee49de3          	bne	s1,a4,800030a6 <bread+0x86>
  panic("bget: no buffers");
    800030b0:	00005517          	auipc	a0,0x5
    800030b4:	56850513          	addi	a0,a0,1384 # 80008618 <syscalls+0xe8>
    800030b8:	ffffd097          	auipc	ra,0xffffd
    800030bc:	48c080e7          	jalr	1164(ra) # 80000544 <panic>
      b->dev = dev;
    800030c0:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800030c4:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800030c8:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800030cc:	4785                	li	a5,1
    800030ce:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030d0:	00014517          	auipc	a0,0x14
    800030d4:	4a850513          	addi	a0,a0,1192 # 80017578 <bcache>
    800030d8:	ffffe097          	auipc	ra,0xffffe
    800030dc:	bc6080e7          	jalr	-1082(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    800030e0:	01048513          	addi	a0,s1,16
    800030e4:	00001097          	auipc	ra,0x1
    800030e8:	410080e7          	jalr	1040(ra) # 800044f4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800030ec:	409c                	lw	a5,0(s1)
    800030ee:	cb89                	beqz	a5,80003100 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800030f0:	8526                	mv	a0,s1
    800030f2:	70a2                	ld	ra,40(sp)
    800030f4:	7402                	ld	s0,32(sp)
    800030f6:	64e2                	ld	s1,24(sp)
    800030f8:	6942                	ld	s2,16(sp)
    800030fa:	69a2                	ld	s3,8(sp)
    800030fc:	6145                	addi	sp,sp,48
    800030fe:	8082                	ret
    virtio_disk_rw(b, 0);
    80003100:	4581                	li	a1,0
    80003102:	8526                	mv	a0,s1
    80003104:	00003097          	auipc	ra,0x3
    80003108:	fc4080e7          	jalr	-60(ra) # 800060c8 <virtio_disk_rw>
    b->valid = 1;
    8000310c:	4785                	li	a5,1
    8000310e:	c09c                	sw	a5,0(s1)
  return b;
    80003110:	b7c5                	j	800030f0 <bread+0xd0>

0000000080003112 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003112:	1101                	addi	sp,sp,-32
    80003114:	ec06                	sd	ra,24(sp)
    80003116:	e822                	sd	s0,16(sp)
    80003118:	e426                	sd	s1,8(sp)
    8000311a:	1000                	addi	s0,sp,32
    8000311c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000311e:	0541                	addi	a0,a0,16
    80003120:	00001097          	auipc	ra,0x1
    80003124:	46e080e7          	jalr	1134(ra) # 8000458e <holdingsleep>
    80003128:	cd01                	beqz	a0,80003140 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000312a:	4585                	li	a1,1
    8000312c:	8526                	mv	a0,s1
    8000312e:	00003097          	auipc	ra,0x3
    80003132:	f9a080e7          	jalr	-102(ra) # 800060c8 <virtio_disk_rw>
}
    80003136:	60e2                	ld	ra,24(sp)
    80003138:	6442                	ld	s0,16(sp)
    8000313a:	64a2                	ld	s1,8(sp)
    8000313c:	6105                	addi	sp,sp,32
    8000313e:	8082                	ret
    panic("bwrite");
    80003140:	00005517          	auipc	a0,0x5
    80003144:	4f050513          	addi	a0,a0,1264 # 80008630 <syscalls+0x100>
    80003148:	ffffd097          	auipc	ra,0xffffd
    8000314c:	3fc080e7          	jalr	1020(ra) # 80000544 <panic>

0000000080003150 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003150:	1101                	addi	sp,sp,-32
    80003152:	ec06                	sd	ra,24(sp)
    80003154:	e822                	sd	s0,16(sp)
    80003156:	e426                	sd	s1,8(sp)
    80003158:	e04a                	sd	s2,0(sp)
    8000315a:	1000                	addi	s0,sp,32
    8000315c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000315e:	01050913          	addi	s2,a0,16
    80003162:	854a                	mv	a0,s2
    80003164:	00001097          	auipc	ra,0x1
    80003168:	42a080e7          	jalr	1066(ra) # 8000458e <holdingsleep>
    8000316c:	c92d                	beqz	a0,800031de <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000316e:	854a                	mv	a0,s2
    80003170:	00001097          	auipc	ra,0x1
    80003174:	3da080e7          	jalr	986(ra) # 8000454a <releasesleep>

  acquire(&bcache.lock);
    80003178:	00014517          	auipc	a0,0x14
    8000317c:	40050513          	addi	a0,a0,1024 # 80017578 <bcache>
    80003180:	ffffe097          	auipc	ra,0xffffe
    80003184:	a6a080e7          	jalr	-1430(ra) # 80000bea <acquire>
  b->refcnt--;
    80003188:	40bc                	lw	a5,64(s1)
    8000318a:	37fd                	addiw	a5,a5,-1
    8000318c:	0007871b          	sext.w	a4,a5
    80003190:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003192:	eb05                	bnez	a4,800031c2 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003194:	68bc                	ld	a5,80(s1)
    80003196:	64b8                	ld	a4,72(s1)
    80003198:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000319a:	64bc                	ld	a5,72(s1)
    8000319c:	68b8                	ld	a4,80(s1)
    8000319e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800031a0:	0001c797          	auipc	a5,0x1c
    800031a4:	3d878793          	addi	a5,a5,984 # 8001f578 <bcache+0x8000>
    800031a8:	2b87b703          	ld	a4,696(a5)
    800031ac:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800031ae:	0001c717          	auipc	a4,0x1c
    800031b2:	63270713          	addi	a4,a4,1586 # 8001f7e0 <bcache+0x8268>
    800031b6:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800031b8:	2b87b703          	ld	a4,696(a5)
    800031bc:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800031be:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800031c2:	00014517          	auipc	a0,0x14
    800031c6:	3b650513          	addi	a0,a0,950 # 80017578 <bcache>
    800031ca:	ffffe097          	auipc	ra,0xffffe
    800031ce:	ad4080e7          	jalr	-1324(ra) # 80000c9e <release>
}
    800031d2:	60e2                	ld	ra,24(sp)
    800031d4:	6442                	ld	s0,16(sp)
    800031d6:	64a2                	ld	s1,8(sp)
    800031d8:	6902                	ld	s2,0(sp)
    800031da:	6105                	addi	sp,sp,32
    800031dc:	8082                	ret
    panic("brelse");
    800031de:	00005517          	auipc	a0,0x5
    800031e2:	45a50513          	addi	a0,a0,1114 # 80008638 <syscalls+0x108>
    800031e6:	ffffd097          	auipc	ra,0xffffd
    800031ea:	35e080e7          	jalr	862(ra) # 80000544 <panic>

00000000800031ee <bpin>:

void
bpin(struct buf *b) {
    800031ee:	1101                	addi	sp,sp,-32
    800031f0:	ec06                	sd	ra,24(sp)
    800031f2:	e822                	sd	s0,16(sp)
    800031f4:	e426                	sd	s1,8(sp)
    800031f6:	1000                	addi	s0,sp,32
    800031f8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031fa:	00014517          	auipc	a0,0x14
    800031fe:	37e50513          	addi	a0,a0,894 # 80017578 <bcache>
    80003202:	ffffe097          	auipc	ra,0xffffe
    80003206:	9e8080e7          	jalr	-1560(ra) # 80000bea <acquire>
  b->refcnt++;
    8000320a:	40bc                	lw	a5,64(s1)
    8000320c:	2785                	addiw	a5,a5,1
    8000320e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003210:	00014517          	auipc	a0,0x14
    80003214:	36850513          	addi	a0,a0,872 # 80017578 <bcache>
    80003218:	ffffe097          	auipc	ra,0xffffe
    8000321c:	a86080e7          	jalr	-1402(ra) # 80000c9e <release>
}
    80003220:	60e2                	ld	ra,24(sp)
    80003222:	6442                	ld	s0,16(sp)
    80003224:	64a2                	ld	s1,8(sp)
    80003226:	6105                	addi	sp,sp,32
    80003228:	8082                	ret

000000008000322a <bunpin>:

void
bunpin(struct buf *b) {
    8000322a:	1101                	addi	sp,sp,-32
    8000322c:	ec06                	sd	ra,24(sp)
    8000322e:	e822                	sd	s0,16(sp)
    80003230:	e426                	sd	s1,8(sp)
    80003232:	1000                	addi	s0,sp,32
    80003234:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003236:	00014517          	auipc	a0,0x14
    8000323a:	34250513          	addi	a0,a0,834 # 80017578 <bcache>
    8000323e:	ffffe097          	auipc	ra,0xffffe
    80003242:	9ac080e7          	jalr	-1620(ra) # 80000bea <acquire>
  b->refcnt--;
    80003246:	40bc                	lw	a5,64(s1)
    80003248:	37fd                	addiw	a5,a5,-1
    8000324a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000324c:	00014517          	auipc	a0,0x14
    80003250:	32c50513          	addi	a0,a0,812 # 80017578 <bcache>
    80003254:	ffffe097          	auipc	ra,0xffffe
    80003258:	a4a080e7          	jalr	-1462(ra) # 80000c9e <release>
}
    8000325c:	60e2                	ld	ra,24(sp)
    8000325e:	6442                	ld	s0,16(sp)
    80003260:	64a2                	ld	s1,8(sp)
    80003262:	6105                	addi	sp,sp,32
    80003264:	8082                	ret

0000000080003266 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003266:	1101                	addi	sp,sp,-32
    80003268:	ec06                	sd	ra,24(sp)
    8000326a:	e822                	sd	s0,16(sp)
    8000326c:	e426                	sd	s1,8(sp)
    8000326e:	e04a                	sd	s2,0(sp)
    80003270:	1000                	addi	s0,sp,32
    80003272:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003274:	00d5d59b          	srliw	a1,a1,0xd
    80003278:	0001d797          	auipc	a5,0x1d
    8000327c:	9dc7a783          	lw	a5,-1572(a5) # 8001fc54 <sb+0x1c>
    80003280:	9dbd                	addw	a1,a1,a5
    80003282:	00000097          	auipc	ra,0x0
    80003286:	d9e080e7          	jalr	-610(ra) # 80003020 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000328a:	0074f713          	andi	a4,s1,7
    8000328e:	4785                	li	a5,1
    80003290:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003294:	14ce                	slli	s1,s1,0x33
    80003296:	90d9                	srli	s1,s1,0x36
    80003298:	00950733          	add	a4,a0,s1
    8000329c:	05874703          	lbu	a4,88(a4)
    800032a0:	00e7f6b3          	and	a3,a5,a4
    800032a4:	c69d                	beqz	a3,800032d2 <bfree+0x6c>
    800032a6:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800032a8:	94aa                	add	s1,s1,a0
    800032aa:	fff7c793          	not	a5,a5
    800032ae:	8ff9                	and	a5,a5,a4
    800032b0:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800032b4:	00001097          	auipc	ra,0x1
    800032b8:	120080e7          	jalr	288(ra) # 800043d4 <log_write>
  brelse(bp);
    800032bc:	854a                	mv	a0,s2
    800032be:	00000097          	auipc	ra,0x0
    800032c2:	e92080e7          	jalr	-366(ra) # 80003150 <brelse>
}
    800032c6:	60e2                	ld	ra,24(sp)
    800032c8:	6442                	ld	s0,16(sp)
    800032ca:	64a2                	ld	s1,8(sp)
    800032cc:	6902                	ld	s2,0(sp)
    800032ce:	6105                	addi	sp,sp,32
    800032d0:	8082                	ret
    panic("freeing free block");
    800032d2:	00005517          	auipc	a0,0x5
    800032d6:	36e50513          	addi	a0,a0,878 # 80008640 <syscalls+0x110>
    800032da:	ffffd097          	auipc	ra,0xffffd
    800032de:	26a080e7          	jalr	618(ra) # 80000544 <panic>

00000000800032e2 <balloc>:
{
    800032e2:	711d                	addi	sp,sp,-96
    800032e4:	ec86                	sd	ra,88(sp)
    800032e6:	e8a2                	sd	s0,80(sp)
    800032e8:	e4a6                	sd	s1,72(sp)
    800032ea:	e0ca                	sd	s2,64(sp)
    800032ec:	fc4e                	sd	s3,56(sp)
    800032ee:	f852                	sd	s4,48(sp)
    800032f0:	f456                	sd	s5,40(sp)
    800032f2:	f05a                	sd	s6,32(sp)
    800032f4:	ec5e                	sd	s7,24(sp)
    800032f6:	e862                	sd	s8,16(sp)
    800032f8:	e466                	sd	s9,8(sp)
    800032fa:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800032fc:	0001d797          	auipc	a5,0x1d
    80003300:	9407a783          	lw	a5,-1728(a5) # 8001fc3c <sb+0x4>
    80003304:	10078163          	beqz	a5,80003406 <balloc+0x124>
    80003308:	8baa                	mv	s7,a0
    8000330a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000330c:	0001db17          	auipc	s6,0x1d
    80003310:	92cb0b13          	addi	s6,s6,-1748 # 8001fc38 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003314:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003316:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003318:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000331a:	6c89                	lui	s9,0x2
    8000331c:	a061                	j	800033a4 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000331e:	974a                	add	a4,a4,s2
    80003320:	8fd5                	or	a5,a5,a3
    80003322:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003326:	854a                	mv	a0,s2
    80003328:	00001097          	auipc	ra,0x1
    8000332c:	0ac080e7          	jalr	172(ra) # 800043d4 <log_write>
        brelse(bp);
    80003330:	854a                	mv	a0,s2
    80003332:	00000097          	auipc	ra,0x0
    80003336:	e1e080e7          	jalr	-482(ra) # 80003150 <brelse>
  bp = bread(dev, bno);
    8000333a:	85a6                	mv	a1,s1
    8000333c:	855e                	mv	a0,s7
    8000333e:	00000097          	auipc	ra,0x0
    80003342:	ce2080e7          	jalr	-798(ra) # 80003020 <bread>
    80003346:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003348:	40000613          	li	a2,1024
    8000334c:	4581                	li	a1,0
    8000334e:	05850513          	addi	a0,a0,88
    80003352:	ffffe097          	auipc	ra,0xffffe
    80003356:	994080e7          	jalr	-1644(ra) # 80000ce6 <memset>
  log_write(bp);
    8000335a:	854a                	mv	a0,s2
    8000335c:	00001097          	auipc	ra,0x1
    80003360:	078080e7          	jalr	120(ra) # 800043d4 <log_write>
  brelse(bp);
    80003364:	854a                	mv	a0,s2
    80003366:	00000097          	auipc	ra,0x0
    8000336a:	dea080e7          	jalr	-534(ra) # 80003150 <brelse>
}
    8000336e:	8526                	mv	a0,s1
    80003370:	60e6                	ld	ra,88(sp)
    80003372:	6446                	ld	s0,80(sp)
    80003374:	64a6                	ld	s1,72(sp)
    80003376:	6906                	ld	s2,64(sp)
    80003378:	79e2                	ld	s3,56(sp)
    8000337a:	7a42                	ld	s4,48(sp)
    8000337c:	7aa2                	ld	s5,40(sp)
    8000337e:	7b02                	ld	s6,32(sp)
    80003380:	6be2                	ld	s7,24(sp)
    80003382:	6c42                	ld	s8,16(sp)
    80003384:	6ca2                	ld	s9,8(sp)
    80003386:	6125                	addi	sp,sp,96
    80003388:	8082                	ret
    brelse(bp);
    8000338a:	854a                	mv	a0,s2
    8000338c:	00000097          	auipc	ra,0x0
    80003390:	dc4080e7          	jalr	-572(ra) # 80003150 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003394:	015c87bb          	addw	a5,s9,s5
    80003398:	00078a9b          	sext.w	s5,a5
    8000339c:	004b2703          	lw	a4,4(s6)
    800033a0:	06eaf363          	bgeu	s5,a4,80003406 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    800033a4:	41fad79b          	sraiw	a5,s5,0x1f
    800033a8:	0137d79b          	srliw	a5,a5,0x13
    800033ac:	015787bb          	addw	a5,a5,s5
    800033b0:	40d7d79b          	sraiw	a5,a5,0xd
    800033b4:	01cb2583          	lw	a1,28(s6)
    800033b8:	9dbd                	addw	a1,a1,a5
    800033ba:	855e                	mv	a0,s7
    800033bc:	00000097          	auipc	ra,0x0
    800033c0:	c64080e7          	jalr	-924(ra) # 80003020 <bread>
    800033c4:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033c6:	004b2503          	lw	a0,4(s6)
    800033ca:	000a849b          	sext.w	s1,s5
    800033ce:	8662                	mv	a2,s8
    800033d0:	faa4fde3          	bgeu	s1,a0,8000338a <balloc+0xa8>
      m = 1 << (bi % 8);
    800033d4:	41f6579b          	sraiw	a5,a2,0x1f
    800033d8:	01d7d69b          	srliw	a3,a5,0x1d
    800033dc:	00c6873b          	addw	a4,a3,a2
    800033e0:	00777793          	andi	a5,a4,7
    800033e4:	9f95                	subw	a5,a5,a3
    800033e6:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800033ea:	4037571b          	sraiw	a4,a4,0x3
    800033ee:	00e906b3          	add	a3,s2,a4
    800033f2:	0586c683          	lbu	a3,88(a3)
    800033f6:	00d7f5b3          	and	a1,a5,a3
    800033fa:	d195                	beqz	a1,8000331e <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033fc:	2605                	addiw	a2,a2,1
    800033fe:	2485                	addiw	s1,s1,1
    80003400:	fd4618e3          	bne	a2,s4,800033d0 <balloc+0xee>
    80003404:	b759                	j	8000338a <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003406:	00005517          	auipc	a0,0x5
    8000340a:	25250513          	addi	a0,a0,594 # 80008658 <syscalls+0x128>
    8000340e:	ffffd097          	auipc	ra,0xffffd
    80003412:	180080e7          	jalr	384(ra) # 8000058e <printf>
  return 0;
    80003416:	4481                	li	s1,0
    80003418:	bf99                	j	8000336e <balloc+0x8c>

000000008000341a <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000341a:	7179                	addi	sp,sp,-48
    8000341c:	f406                	sd	ra,40(sp)
    8000341e:	f022                	sd	s0,32(sp)
    80003420:	ec26                	sd	s1,24(sp)
    80003422:	e84a                	sd	s2,16(sp)
    80003424:	e44e                	sd	s3,8(sp)
    80003426:	e052                	sd	s4,0(sp)
    80003428:	1800                	addi	s0,sp,48
    8000342a:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000342c:	47ad                	li	a5,11
    8000342e:	02b7e763          	bltu	a5,a1,8000345c <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003432:	02059493          	slli	s1,a1,0x20
    80003436:	9081                	srli	s1,s1,0x20
    80003438:	048a                	slli	s1,s1,0x2
    8000343a:	94aa                	add	s1,s1,a0
    8000343c:	0504a903          	lw	s2,80(s1)
    80003440:	06091e63          	bnez	s2,800034bc <bmap+0xa2>
      addr = balloc(ip->dev);
    80003444:	4108                	lw	a0,0(a0)
    80003446:	00000097          	auipc	ra,0x0
    8000344a:	e9c080e7          	jalr	-356(ra) # 800032e2 <balloc>
    8000344e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003452:	06090563          	beqz	s2,800034bc <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003456:	0524a823          	sw	s2,80(s1)
    8000345a:	a08d                	j	800034bc <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000345c:	ff45849b          	addiw	s1,a1,-12
    80003460:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003464:	0ff00793          	li	a5,255
    80003468:	08e7e563          	bltu	a5,a4,800034f2 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000346c:	08052903          	lw	s2,128(a0)
    80003470:	00091d63          	bnez	s2,8000348a <bmap+0x70>
      addr = balloc(ip->dev);
    80003474:	4108                	lw	a0,0(a0)
    80003476:	00000097          	auipc	ra,0x0
    8000347a:	e6c080e7          	jalr	-404(ra) # 800032e2 <balloc>
    8000347e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003482:	02090d63          	beqz	s2,800034bc <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003486:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000348a:	85ca                	mv	a1,s2
    8000348c:	0009a503          	lw	a0,0(s3)
    80003490:	00000097          	auipc	ra,0x0
    80003494:	b90080e7          	jalr	-1136(ra) # 80003020 <bread>
    80003498:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000349a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000349e:	02049593          	slli	a1,s1,0x20
    800034a2:	9181                	srli	a1,a1,0x20
    800034a4:	058a                	slli	a1,a1,0x2
    800034a6:	00b784b3          	add	s1,a5,a1
    800034aa:	0004a903          	lw	s2,0(s1)
    800034ae:	02090063          	beqz	s2,800034ce <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800034b2:	8552                	mv	a0,s4
    800034b4:	00000097          	auipc	ra,0x0
    800034b8:	c9c080e7          	jalr	-868(ra) # 80003150 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800034bc:	854a                	mv	a0,s2
    800034be:	70a2                	ld	ra,40(sp)
    800034c0:	7402                	ld	s0,32(sp)
    800034c2:	64e2                	ld	s1,24(sp)
    800034c4:	6942                	ld	s2,16(sp)
    800034c6:	69a2                	ld	s3,8(sp)
    800034c8:	6a02                	ld	s4,0(sp)
    800034ca:	6145                	addi	sp,sp,48
    800034cc:	8082                	ret
      addr = balloc(ip->dev);
    800034ce:	0009a503          	lw	a0,0(s3)
    800034d2:	00000097          	auipc	ra,0x0
    800034d6:	e10080e7          	jalr	-496(ra) # 800032e2 <balloc>
    800034da:	0005091b          	sext.w	s2,a0
      if(addr){
    800034de:	fc090ae3          	beqz	s2,800034b2 <bmap+0x98>
        a[bn] = addr;
    800034e2:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800034e6:	8552                	mv	a0,s4
    800034e8:	00001097          	auipc	ra,0x1
    800034ec:	eec080e7          	jalr	-276(ra) # 800043d4 <log_write>
    800034f0:	b7c9                	j	800034b2 <bmap+0x98>
  panic("bmap: out of range");
    800034f2:	00005517          	auipc	a0,0x5
    800034f6:	17e50513          	addi	a0,a0,382 # 80008670 <syscalls+0x140>
    800034fa:	ffffd097          	auipc	ra,0xffffd
    800034fe:	04a080e7          	jalr	74(ra) # 80000544 <panic>

0000000080003502 <iget>:
{
    80003502:	7179                	addi	sp,sp,-48
    80003504:	f406                	sd	ra,40(sp)
    80003506:	f022                	sd	s0,32(sp)
    80003508:	ec26                	sd	s1,24(sp)
    8000350a:	e84a                	sd	s2,16(sp)
    8000350c:	e44e                	sd	s3,8(sp)
    8000350e:	e052                	sd	s4,0(sp)
    80003510:	1800                	addi	s0,sp,48
    80003512:	89aa                	mv	s3,a0
    80003514:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003516:	0001c517          	auipc	a0,0x1c
    8000351a:	74250513          	addi	a0,a0,1858 # 8001fc58 <itable>
    8000351e:	ffffd097          	auipc	ra,0xffffd
    80003522:	6cc080e7          	jalr	1740(ra) # 80000bea <acquire>
  empty = 0;
    80003526:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003528:	0001c497          	auipc	s1,0x1c
    8000352c:	74848493          	addi	s1,s1,1864 # 8001fc70 <itable+0x18>
    80003530:	0001e697          	auipc	a3,0x1e
    80003534:	1d068693          	addi	a3,a3,464 # 80021700 <log>
    80003538:	a039                	j	80003546 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000353a:	02090b63          	beqz	s2,80003570 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000353e:	08848493          	addi	s1,s1,136
    80003542:	02d48a63          	beq	s1,a3,80003576 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003546:	449c                	lw	a5,8(s1)
    80003548:	fef059e3          	blez	a5,8000353a <iget+0x38>
    8000354c:	4098                	lw	a4,0(s1)
    8000354e:	ff3716e3          	bne	a4,s3,8000353a <iget+0x38>
    80003552:	40d8                	lw	a4,4(s1)
    80003554:	ff4713e3          	bne	a4,s4,8000353a <iget+0x38>
      ip->ref++;
    80003558:	2785                	addiw	a5,a5,1
    8000355a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000355c:	0001c517          	auipc	a0,0x1c
    80003560:	6fc50513          	addi	a0,a0,1788 # 8001fc58 <itable>
    80003564:	ffffd097          	auipc	ra,0xffffd
    80003568:	73a080e7          	jalr	1850(ra) # 80000c9e <release>
      return ip;
    8000356c:	8926                	mv	s2,s1
    8000356e:	a03d                	j	8000359c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003570:	f7f9                	bnez	a5,8000353e <iget+0x3c>
    80003572:	8926                	mv	s2,s1
    80003574:	b7e9                	j	8000353e <iget+0x3c>
  if(empty == 0)
    80003576:	02090c63          	beqz	s2,800035ae <iget+0xac>
  ip->dev = dev;
    8000357a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000357e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003582:	4785                	li	a5,1
    80003584:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003588:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000358c:	0001c517          	auipc	a0,0x1c
    80003590:	6cc50513          	addi	a0,a0,1740 # 8001fc58 <itable>
    80003594:	ffffd097          	auipc	ra,0xffffd
    80003598:	70a080e7          	jalr	1802(ra) # 80000c9e <release>
}
    8000359c:	854a                	mv	a0,s2
    8000359e:	70a2                	ld	ra,40(sp)
    800035a0:	7402                	ld	s0,32(sp)
    800035a2:	64e2                	ld	s1,24(sp)
    800035a4:	6942                	ld	s2,16(sp)
    800035a6:	69a2                	ld	s3,8(sp)
    800035a8:	6a02                	ld	s4,0(sp)
    800035aa:	6145                	addi	sp,sp,48
    800035ac:	8082                	ret
    panic("iget: no inodes");
    800035ae:	00005517          	auipc	a0,0x5
    800035b2:	0da50513          	addi	a0,a0,218 # 80008688 <syscalls+0x158>
    800035b6:	ffffd097          	auipc	ra,0xffffd
    800035ba:	f8e080e7          	jalr	-114(ra) # 80000544 <panic>

00000000800035be <fsinit>:
fsinit(int dev) {
    800035be:	7179                	addi	sp,sp,-48
    800035c0:	f406                	sd	ra,40(sp)
    800035c2:	f022                	sd	s0,32(sp)
    800035c4:	ec26                	sd	s1,24(sp)
    800035c6:	e84a                	sd	s2,16(sp)
    800035c8:	e44e                	sd	s3,8(sp)
    800035ca:	1800                	addi	s0,sp,48
    800035cc:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800035ce:	4585                	li	a1,1
    800035d0:	00000097          	auipc	ra,0x0
    800035d4:	a50080e7          	jalr	-1456(ra) # 80003020 <bread>
    800035d8:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800035da:	0001c997          	auipc	s3,0x1c
    800035de:	65e98993          	addi	s3,s3,1630 # 8001fc38 <sb>
    800035e2:	02000613          	li	a2,32
    800035e6:	05850593          	addi	a1,a0,88
    800035ea:	854e                	mv	a0,s3
    800035ec:	ffffd097          	auipc	ra,0xffffd
    800035f0:	75a080e7          	jalr	1882(ra) # 80000d46 <memmove>
  brelse(bp);
    800035f4:	8526                	mv	a0,s1
    800035f6:	00000097          	auipc	ra,0x0
    800035fa:	b5a080e7          	jalr	-1190(ra) # 80003150 <brelse>
  if(sb.magic != FSMAGIC)
    800035fe:	0009a703          	lw	a4,0(s3)
    80003602:	102037b7          	lui	a5,0x10203
    80003606:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000360a:	02f71263          	bne	a4,a5,8000362e <fsinit+0x70>
  initlog(dev, &sb);
    8000360e:	0001c597          	auipc	a1,0x1c
    80003612:	62a58593          	addi	a1,a1,1578 # 8001fc38 <sb>
    80003616:	854a                	mv	a0,s2
    80003618:	00001097          	auipc	ra,0x1
    8000361c:	b40080e7          	jalr	-1216(ra) # 80004158 <initlog>
}
    80003620:	70a2                	ld	ra,40(sp)
    80003622:	7402                	ld	s0,32(sp)
    80003624:	64e2                	ld	s1,24(sp)
    80003626:	6942                	ld	s2,16(sp)
    80003628:	69a2                	ld	s3,8(sp)
    8000362a:	6145                	addi	sp,sp,48
    8000362c:	8082                	ret
    panic("invalid file system");
    8000362e:	00005517          	auipc	a0,0x5
    80003632:	06a50513          	addi	a0,a0,106 # 80008698 <syscalls+0x168>
    80003636:	ffffd097          	auipc	ra,0xffffd
    8000363a:	f0e080e7          	jalr	-242(ra) # 80000544 <panic>

000000008000363e <iinit>:
{
    8000363e:	7179                	addi	sp,sp,-48
    80003640:	f406                	sd	ra,40(sp)
    80003642:	f022                	sd	s0,32(sp)
    80003644:	ec26                	sd	s1,24(sp)
    80003646:	e84a                	sd	s2,16(sp)
    80003648:	e44e                	sd	s3,8(sp)
    8000364a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000364c:	00005597          	auipc	a1,0x5
    80003650:	06458593          	addi	a1,a1,100 # 800086b0 <syscalls+0x180>
    80003654:	0001c517          	auipc	a0,0x1c
    80003658:	60450513          	addi	a0,a0,1540 # 8001fc58 <itable>
    8000365c:	ffffd097          	auipc	ra,0xffffd
    80003660:	4fe080e7          	jalr	1278(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    80003664:	0001c497          	auipc	s1,0x1c
    80003668:	61c48493          	addi	s1,s1,1564 # 8001fc80 <itable+0x28>
    8000366c:	0001e997          	auipc	s3,0x1e
    80003670:	0a498993          	addi	s3,s3,164 # 80021710 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003674:	00005917          	auipc	s2,0x5
    80003678:	04490913          	addi	s2,s2,68 # 800086b8 <syscalls+0x188>
    8000367c:	85ca                	mv	a1,s2
    8000367e:	8526                	mv	a0,s1
    80003680:	00001097          	auipc	ra,0x1
    80003684:	e3a080e7          	jalr	-454(ra) # 800044ba <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003688:	08848493          	addi	s1,s1,136
    8000368c:	ff3498e3          	bne	s1,s3,8000367c <iinit+0x3e>
}
    80003690:	70a2                	ld	ra,40(sp)
    80003692:	7402                	ld	s0,32(sp)
    80003694:	64e2                	ld	s1,24(sp)
    80003696:	6942                	ld	s2,16(sp)
    80003698:	69a2                	ld	s3,8(sp)
    8000369a:	6145                	addi	sp,sp,48
    8000369c:	8082                	ret

000000008000369e <ialloc>:
{
    8000369e:	715d                	addi	sp,sp,-80
    800036a0:	e486                	sd	ra,72(sp)
    800036a2:	e0a2                	sd	s0,64(sp)
    800036a4:	fc26                	sd	s1,56(sp)
    800036a6:	f84a                	sd	s2,48(sp)
    800036a8:	f44e                	sd	s3,40(sp)
    800036aa:	f052                	sd	s4,32(sp)
    800036ac:	ec56                	sd	s5,24(sp)
    800036ae:	e85a                	sd	s6,16(sp)
    800036b0:	e45e                	sd	s7,8(sp)
    800036b2:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800036b4:	0001c717          	auipc	a4,0x1c
    800036b8:	59072703          	lw	a4,1424(a4) # 8001fc44 <sb+0xc>
    800036bc:	4785                	li	a5,1
    800036be:	04e7fa63          	bgeu	a5,a4,80003712 <ialloc+0x74>
    800036c2:	8aaa                	mv	s5,a0
    800036c4:	8bae                	mv	s7,a1
    800036c6:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800036c8:	0001ca17          	auipc	s4,0x1c
    800036cc:	570a0a13          	addi	s4,s4,1392 # 8001fc38 <sb>
    800036d0:	00048b1b          	sext.w	s6,s1
    800036d4:	0044d593          	srli	a1,s1,0x4
    800036d8:	018a2783          	lw	a5,24(s4)
    800036dc:	9dbd                	addw	a1,a1,a5
    800036de:	8556                	mv	a0,s5
    800036e0:	00000097          	auipc	ra,0x0
    800036e4:	940080e7          	jalr	-1728(ra) # 80003020 <bread>
    800036e8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800036ea:	05850993          	addi	s3,a0,88
    800036ee:	00f4f793          	andi	a5,s1,15
    800036f2:	079a                	slli	a5,a5,0x6
    800036f4:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800036f6:	00099783          	lh	a5,0(s3)
    800036fa:	c3a1                	beqz	a5,8000373a <ialloc+0x9c>
    brelse(bp);
    800036fc:	00000097          	auipc	ra,0x0
    80003700:	a54080e7          	jalr	-1452(ra) # 80003150 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003704:	0485                	addi	s1,s1,1
    80003706:	00ca2703          	lw	a4,12(s4)
    8000370a:	0004879b          	sext.w	a5,s1
    8000370e:	fce7e1e3          	bltu	a5,a4,800036d0 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003712:	00005517          	auipc	a0,0x5
    80003716:	fae50513          	addi	a0,a0,-82 # 800086c0 <syscalls+0x190>
    8000371a:	ffffd097          	auipc	ra,0xffffd
    8000371e:	e74080e7          	jalr	-396(ra) # 8000058e <printf>
  return 0;
    80003722:	4501                	li	a0,0
}
    80003724:	60a6                	ld	ra,72(sp)
    80003726:	6406                	ld	s0,64(sp)
    80003728:	74e2                	ld	s1,56(sp)
    8000372a:	7942                	ld	s2,48(sp)
    8000372c:	79a2                	ld	s3,40(sp)
    8000372e:	7a02                	ld	s4,32(sp)
    80003730:	6ae2                	ld	s5,24(sp)
    80003732:	6b42                	ld	s6,16(sp)
    80003734:	6ba2                	ld	s7,8(sp)
    80003736:	6161                	addi	sp,sp,80
    80003738:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000373a:	04000613          	li	a2,64
    8000373e:	4581                	li	a1,0
    80003740:	854e                	mv	a0,s3
    80003742:	ffffd097          	auipc	ra,0xffffd
    80003746:	5a4080e7          	jalr	1444(ra) # 80000ce6 <memset>
      dip->type = type;
    8000374a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000374e:	854a                	mv	a0,s2
    80003750:	00001097          	auipc	ra,0x1
    80003754:	c84080e7          	jalr	-892(ra) # 800043d4 <log_write>
      brelse(bp);
    80003758:	854a                	mv	a0,s2
    8000375a:	00000097          	auipc	ra,0x0
    8000375e:	9f6080e7          	jalr	-1546(ra) # 80003150 <brelse>
      return iget(dev, inum);
    80003762:	85da                	mv	a1,s6
    80003764:	8556                	mv	a0,s5
    80003766:	00000097          	auipc	ra,0x0
    8000376a:	d9c080e7          	jalr	-612(ra) # 80003502 <iget>
    8000376e:	bf5d                	j	80003724 <ialloc+0x86>

0000000080003770 <iupdate>:
{
    80003770:	1101                	addi	sp,sp,-32
    80003772:	ec06                	sd	ra,24(sp)
    80003774:	e822                	sd	s0,16(sp)
    80003776:	e426                	sd	s1,8(sp)
    80003778:	e04a                	sd	s2,0(sp)
    8000377a:	1000                	addi	s0,sp,32
    8000377c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000377e:	415c                	lw	a5,4(a0)
    80003780:	0047d79b          	srliw	a5,a5,0x4
    80003784:	0001c597          	auipc	a1,0x1c
    80003788:	4cc5a583          	lw	a1,1228(a1) # 8001fc50 <sb+0x18>
    8000378c:	9dbd                	addw	a1,a1,a5
    8000378e:	4108                	lw	a0,0(a0)
    80003790:	00000097          	auipc	ra,0x0
    80003794:	890080e7          	jalr	-1904(ra) # 80003020 <bread>
    80003798:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000379a:	05850793          	addi	a5,a0,88
    8000379e:	40c8                	lw	a0,4(s1)
    800037a0:	893d                	andi	a0,a0,15
    800037a2:	051a                	slli	a0,a0,0x6
    800037a4:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800037a6:	04449703          	lh	a4,68(s1)
    800037aa:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800037ae:	04649703          	lh	a4,70(s1)
    800037b2:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800037b6:	04849703          	lh	a4,72(s1)
    800037ba:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800037be:	04a49703          	lh	a4,74(s1)
    800037c2:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800037c6:	44f8                	lw	a4,76(s1)
    800037c8:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800037ca:	03400613          	li	a2,52
    800037ce:	05048593          	addi	a1,s1,80
    800037d2:	0531                	addi	a0,a0,12
    800037d4:	ffffd097          	auipc	ra,0xffffd
    800037d8:	572080e7          	jalr	1394(ra) # 80000d46 <memmove>
  log_write(bp);
    800037dc:	854a                	mv	a0,s2
    800037de:	00001097          	auipc	ra,0x1
    800037e2:	bf6080e7          	jalr	-1034(ra) # 800043d4 <log_write>
  brelse(bp);
    800037e6:	854a                	mv	a0,s2
    800037e8:	00000097          	auipc	ra,0x0
    800037ec:	968080e7          	jalr	-1688(ra) # 80003150 <brelse>
}
    800037f0:	60e2                	ld	ra,24(sp)
    800037f2:	6442                	ld	s0,16(sp)
    800037f4:	64a2                	ld	s1,8(sp)
    800037f6:	6902                	ld	s2,0(sp)
    800037f8:	6105                	addi	sp,sp,32
    800037fa:	8082                	ret

00000000800037fc <idup>:
{
    800037fc:	1101                	addi	sp,sp,-32
    800037fe:	ec06                	sd	ra,24(sp)
    80003800:	e822                	sd	s0,16(sp)
    80003802:	e426                	sd	s1,8(sp)
    80003804:	1000                	addi	s0,sp,32
    80003806:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003808:	0001c517          	auipc	a0,0x1c
    8000380c:	45050513          	addi	a0,a0,1104 # 8001fc58 <itable>
    80003810:	ffffd097          	auipc	ra,0xffffd
    80003814:	3da080e7          	jalr	986(ra) # 80000bea <acquire>
  ip->ref++;
    80003818:	449c                	lw	a5,8(s1)
    8000381a:	2785                	addiw	a5,a5,1
    8000381c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000381e:	0001c517          	auipc	a0,0x1c
    80003822:	43a50513          	addi	a0,a0,1082 # 8001fc58 <itable>
    80003826:	ffffd097          	auipc	ra,0xffffd
    8000382a:	478080e7          	jalr	1144(ra) # 80000c9e <release>
}
    8000382e:	8526                	mv	a0,s1
    80003830:	60e2                	ld	ra,24(sp)
    80003832:	6442                	ld	s0,16(sp)
    80003834:	64a2                	ld	s1,8(sp)
    80003836:	6105                	addi	sp,sp,32
    80003838:	8082                	ret

000000008000383a <ilock>:
{
    8000383a:	1101                	addi	sp,sp,-32
    8000383c:	ec06                	sd	ra,24(sp)
    8000383e:	e822                	sd	s0,16(sp)
    80003840:	e426                	sd	s1,8(sp)
    80003842:	e04a                	sd	s2,0(sp)
    80003844:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003846:	c115                	beqz	a0,8000386a <ilock+0x30>
    80003848:	84aa                	mv	s1,a0
    8000384a:	451c                	lw	a5,8(a0)
    8000384c:	00f05f63          	blez	a5,8000386a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003850:	0541                	addi	a0,a0,16
    80003852:	00001097          	auipc	ra,0x1
    80003856:	ca2080e7          	jalr	-862(ra) # 800044f4 <acquiresleep>
  if(ip->valid == 0){
    8000385a:	40bc                	lw	a5,64(s1)
    8000385c:	cf99                	beqz	a5,8000387a <ilock+0x40>
}
    8000385e:	60e2                	ld	ra,24(sp)
    80003860:	6442                	ld	s0,16(sp)
    80003862:	64a2                	ld	s1,8(sp)
    80003864:	6902                	ld	s2,0(sp)
    80003866:	6105                	addi	sp,sp,32
    80003868:	8082                	ret
    panic("ilock");
    8000386a:	00005517          	auipc	a0,0x5
    8000386e:	e6e50513          	addi	a0,a0,-402 # 800086d8 <syscalls+0x1a8>
    80003872:	ffffd097          	auipc	ra,0xffffd
    80003876:	cd2080e7          	jalr	-814(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000387a:	40dc                	lw	a5,4(s1)
    8000387c:	0047d79b          	srliw	a5,a5,0x4
    80003880:	0001c597          	auipc	a1,0x1c
    80003884:	3d05a583          	lw	a1,976(a1) # 8001fc50 <sb+0x18>
    80003888:	9dbd                	addw	a1,a1,a5
    8000388a:	4088                	lw	a0,0(s1)
    8000388c:	fffff097          	auipc	ra,0xfffff
    80003890:	794080e7          	jalr	1940(ra) # 80003020 <bread>
    80003894:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003896:	05850593          	addi	a1,a0,88
    8000389a:	40dc                	lw	a5,4(s1)
    8000389c:	8bbd                	andi	a5,a5,15
    8000389e:	079a                	slli	a5,a5,0x6
    800038a0:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800038a2:	00059783          	lh	a5,0(a1)
    800038a6:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800038aa:	00259783          	lh	a5,2(a1)
    800038ae:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800038b2:	00459783          	lh	a5,4(a1)
    800038b6:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800038ba:	00659783          	lh	a5,6(a1)
    800038be:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800038c2:	459c                	lw	a5,8(a1)
    800038c4:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800038c6:	03400613          	li	a2,52
    800038ca:	05b1                	addi	a1,a1,12
    800038cc:	05048513          	addi	a0,s1,80
    800038d0:	ffffd097          	auipc	ra,0xffffd
    800038d4:	476080e7          	jalr	1142(ra) # 80000d46 <memmove>
    brelse(bp);
    800038d8:	854a                	mv	a0,s2
    800038da:	00000097          	auipc	ra,0x0
    800038de:	876080e7          	jalr	-1930(ra) # 80003150 <brelse>
    ip->valid = 1;
    800038e2:	4785                	li	a5,1
    800038e4:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800038e6:	04449783          	lh	a5,68(s1)
    800038ea:	fbb5                	bnez	a5,8000385e <ilock+0x24>
      panic("ilock: no type");
    800038ec:	00005517          	auipc	a0,0x5
    800038f0:	df450513          	addi	a0,a0,-524 # 800086e0 <syscalls+0x1b0>
    800038f4:	ffffd097          	auipc	ra,0xffffd
    800038f8:	c50080e7          	jalr	-944(ra) # 80000544 <panic>

00000000800038fc <iunlock>:
{
    800038fc:	1101                	addi	sp,sp,-32
    800038fe:	ec06                	sd	ra,24(sp)
    80003900:	e822                	sd	s0,16(sp)
    80003902:	e426                	sd	s1,8(sp)
    80003904:	e04a                	sd	s2,0(sp)
    80003906:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003908:	c905                	beqz	a0,80003938 <iunlock+0x3c>
    8000390a:	84aa                	mv	s1,a0
    8000390c:	01050913          	addi	s2,a0,16
    80003910:	854a                	mv	a0,s2
    80003912:	00001097          	auipc	ra,0x1
    80003916:	c7c080e7          	jalr	-900(ra) # 8000458e <holdingsleep>
    8000391a:	cd19                	beqz	a0,80003938 <iunlock+0x3c>
    8000391c:	449c                	lw	a5,8(s1)
    8000391e:	00f05d63          	blez	a5,80003938 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003922:	854a                	mv	a0,s2
    80003924:	00001097          	auipc	ra,0x1
    80003928:	c26080e7          	jalr	-986(ra) # 8000454a <releasesleep>
}
    8000392c:	60e2                	ld	ra,24(sp)
    8000392e:	6442                	ld	s0,16(sp)
    80003930:	64a2                	ld	s1,8(sp)
    80003932:	6902                	ld	s2,0(sp)
    80003934:	6105                	addi	sp,sp,32
    80003936:	8082                	ret
    panic("iunlock");
    80003938:	00005517          	auipc	a0,0x5
    8000393c:	db850513          	addi	a0,a0,-584 # 800086f0 <syscalls+0x1c0>
    80003940:	ffffd097          	auipc	ra,0xffffd
    80003944:	c04080e7          	jalr	-1020(ra) # 80000544 <panic>

0000000080003948 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003948:	7179                	addi	sp,sp,-48
    8000394a:	f406                	sd	ra,40(sp)
    8000394c:	f022                	sd	s0,32(sp)
    8000394e:	ec26                	sd	s1,24(sp)
    80003950:	e84a                	sd	s2,16(sp)
    80003952:	e44e                	sd	s3,8(sp)
    80003954:	e052                	sd	s4,0(sp)
    80003956:	1800                	addi	s0,sp,48
    80003958:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000395a:	05050493          	addi	s1,a0,80
    8000395e:	08050913          	addi	s2,a0,128
    80003962:	a021                	j	8000396a <itrunc+0x22>
    80003964:	0491                	addi	s1,s1,4
    80003966:	01248d63          	beq	s1,s2,80003980 <itrunc+0x38>
    if(ip->addrs[i]){
    8000396a:	408c                	lw	a1,0(s1)
    8000396c:	dde5                	beqz	a1,80003964 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000396e:	0009a503          	lw	a0,0(s3)
    80003972:	00000097          	auipc	ra,0x0
    80003976:	8f4080e7          	jalr	-1804(ra) # 80003266 <bfree>
      ip->addrs[i] = 0;
    8000397a:	0004a023          	sw	zero,0(s1)
    8000397e:	b7dd                	j	80003964 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003980:	0809a583          	lw	a1,128(s3)
    80003984:	e185                	bnez	a1,800039a4 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003986:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000398a:	854e                	mv	a0,s3
    8000398c:	00000097          	auipc	ra,0x0
    80003990:	de4080e7          	jalr	-540(ra) # 80003770 <iupdate>
}
    80003994:	70a2                	ld	ra,40(sp)
    80003996:	7402                	ld	s0,32(sp)
    80003998:	64e2                	ld	s1,24(sp)
    8000399a:	6942                	ld	s2,16(sp)
    8000399c:	69a2                	ld	s3,8(sp)
    8000399e:	6a02                	ld	s4,0(sp)
    800039a0:	6145                	addi	sp,sp,48
    800039a2:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800039a4:	0009a503          	lw	a0,0(s3)
    800039a8:	fffff097          	auipc	ra,0xfffff
    800039ac:	678080e7          	jalr	1656(ra) # 80003020 <bread>
    800039b0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800039b2:	05850493          	addi	s1,a0,88
    800039b6:	45850913          	addi	s2,a0,1112
    800039ba:	a811                	j	800039ce <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800039bc:	0009a503          	lw	a0,0(s3)
    800039c0:	00000097          	auipc	ra,0x0
    800039c4:	8a6080e7          	jalr	-1882(ra) # 80003266 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800039c8:	0491                	addi	s1,s1,4
    800039ca:	01248563          	beq	s1,s2,800039d4 <itrunc+0x8c>
      if(a[j])
    800039ce:	408c                	lw	a1,0(s1)
    800039d0:	dde5                	beqz	a1,800039c8 <itrunc+0x80>
    800039d2:	b7ed                	j	800039bc <itrunc+0x74>
    brelse(bp);
    800039d4:	8552                	mv	a0,s4
    800039d6:	fffff097          	auipc	ra,0xfffff
    800039da:	77a080e7          	jalr	1914(ra) # 80003150 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800039de:	0809a583          	lw	a1,128(s3)
    800039e2:	0009a503          	lw	a0,0(s3)
    800039e6:	00000097          	auipc	ra,0x0
    800039ea:	880080e7          	jalr	-1920(ra) # 80003266 <bfree>
    ip->addrs[NDIRECT] = 0;
    800039ee:	0809a023          	sw	zero,128(s3)
    800039f2:	bf51                	j	80003986 <itrunc+0x3e>

00000000800039f4 <iput>:
{
    800039f4:	1101                	addi	sp,sp,-32
    800039f6:	ec06                	sd	ra,24(sp)
    800039f8:	e822                	sd	s0,16(sp)
    800039fa:	e426                	sd	s1,8(sp)
    800039fc:	e04a                	sd	s2,0(sp)
    800039fe:	1000                	addi	s0,sp,32
    80003a00:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a02:	0001c517          	auipc	a0,0x1c
    80003a06:	25650513          	addi	a0,a0,598 # 8001fc58 <itable>
    80003a0a:	ffffd097          	auipc	ra,0xffffd
    80003a0e:	1e0080e7          	jalr	480(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a12:	4498                	lw	a4,8(s1)
    80003a14:	4785                	li	a5,1
    80003a16:	02f70363          	beq	a4,a5,80003a3c <iput+0x48>
  ip->ref--;
    80003a1a:	449c                	lw	a5,8(s1)
    80003a1c:	37fd                	addiw	a5,a5,-1
    80003a1e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a20:	0001c517          	auipc	a0,0x1c
    80003a24:	23850513          	addi	a0,a0,568 # 8001fc58 <itable>
    80003a28:	ffffd097          	auipc	ra,0xffffd
    80003a2c:	276080e7          	jalr	630(ra) # 80000c9e <release>
}
    80003a30:	60e2                	ld	ra,24(sp)
    80003a32:	6442                	ld	s0,16(sp)
    80003a34:	64a2                	ld	s1,8(sp)
    80003a36:	6902                	ld	s2,0(sp)
    80003a38:	6105                	addi	sp,sp,32
    80003a3a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a3c:	40bc                	lw	a5,64(s1)
    80003a3e:	dff1                	beqz	a5,80003a1a <iput+0x26>
    80003a40:	04a49783          	lh	a5,74(s1)
    80003a44:	fbf9                	bnez	a5,80003a1a <iput+0x26>
    acquiresleep(&ip->lock);
    80003a46:	01048913          	addi	s2,s1,16
    80003a4a:	854a                	mv	a0,s2
    80003a4c:	00001097          	auipc	ra,0x1
    80003a50:	aa8080e7          	jalr	-1368(ra) # 800044f4 <acquiresleep>
    release(&itable.lock);
    80003a54:	0001c517          	auipc	a0,0x1c
    80003a58:	20450513          	addi	a0,a0,516 # 8001fc58 <itable>
    80003a5c:	ffffd097          	auipc	ra,0xffffd
    80003a60:	242080e7          	jalr	578(ra) # 80000c9e <release>
    itrunc(ip);
    80003a64:	8526                	mv	a0,s1
    80003a66:	00000097          	auipc	ra,0x0
    80003a6a:	ee2080e7          	jalr	-286(ra) # 80003948 <itrunc>
    ip->type = 0;
    80003a6e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a72:	8526                	mv	a0,s1
    80003a74:	00000097          	auipc	ra,0x0
    80003a78:	cfc080e7          	jalr	-772(ra) # 80003770 <iupdate>
    ip->valid = 0;
    80003a7c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a80:	854a                	mv	a0,s2
    80003a82:	00001097          	auipc	ra,0x1
    80003a86:	ac8080e7          	jalr	-1336(ra) # 8000454a <releasesleep>
    acquire(&itable.lock);
    80003a8a:	0001c517          	auipc	a0,0x1c
    80003a8e:	1ce50513          	addi	a0,a0,462 # 8001fc58 <itable>
    80003a92:	ffffd097          	auipc	ra,0xffffd
    80003a96:	158080e7          	jalr	344(ra) # 80000bea <acquire>
    80003a9a:	b741                	j	80003a1a <iput+0x26>

0000000080003a9c <iunlockput>:
{
    80003a9c:	1101                	addi	sp,sp,-32
    80003a9e:	ec06                	sd	ra,24(sp)
    80003aa0:	e822                	sd	s0,16(sp)
    80003aa2:	e426                	sd	s1,8(sp)
    80003aa4:	1000                	addi	s0,sp,32
    80003aa6:	84aa                	mv	s1,a0
  iunlock(ip);
    80003aa8:	00000097          	auipc	ra,0x0
    80003aac:	e54080e7          	jalr	-428(ra) # 800038fc <iunlock>
  iput(ip);
    80003ab0:	8526                	mv	a0,s1
    80003ab2:	00000097          	auipc	ra,0x0
    80003ab6:	f42080e7          	jalr	-190(ra) # 800039f4 <iput>
}
    80003aba:	60e2                	ld	ra,24(sp)
    80003abc:	6442                	ld	s0,16(sp)
    80003abe:	64a2                	ld	s1,8(sp)
    80003ac0:	6105                	addi	sp,sp,32
    80003ac2:	8082                	ret

0000000080003ac4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003ac4:	1141                	addi	sp,sp,-16
    80003ac6:	e422                	sd	s0,8(sp)
    80003ac8:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003aca:	411c                	lw	a5,0(a0)
    80003acc:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ace:	415c                	lw	a5,4(a0)
    80003ad0:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ad2:	04451783          	lh	a5,68(a0)
    80003ad6:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ada:	04a51783          	lh	a5,74(a0)
    80003ade:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ae2:	04c56783          	lwu	a5,76(a0)
    80003ae6:	e99c                	sd	a5,16(a1)
}
    80003ae8:	6422                	ld	s0,8(sp)
    80003aea:	0141                	addi	sp,sp,16
    80003aec:	8082                	ret

0000000080003aee <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003aee:	457c                	lw	a5,76(a0)
    80003af0:	0ed7e963          	bltu	a5,a3,80003be2 <readi+0xf4>
{
    80003af4:	7159                	addi	sp,sp,-112
    80003af6:	f486                	sd	ra,104(sp)
    80003af8:	f0a2                	sd	s0,96(sp)
    80003afa:	eca6                	sd	s1,88(sp)
    80003afc:	e8ca                	sd	s2,80(sp)
    80003afe:	e4ce                	sd	s3,72(sp)
    80003b00:	e0d2                	sd	s4,64(sp)
    80003b02:	fc56                	sd	s5,56(sp)
    80003b04:	f85a                	sd	s6,48(sp)
    80003b06:	f45e                	sd	s7,40(sp)
    80003b08:	f062                	sd	s8,32(sp)
    80003b0a:	ec66                	sd	s9,24(sp)
    80003b0c:	e86a                	sd	s10,16(sp)
    80003b0e:	e46e                	sd	s11,8(sp)
    80003b10:	1880                	addi	s0,sp,112
    80003b12:	8b2a                	mv	s6,a0
    80003b14:	8bae                	mv	s7,a1
    80003b16:	8a32                	mv	s4,a2
    80003b18:	84b6                	mv	s1,a3
    80003b1a:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003b1c:	9f35                	addw	a4,a4,a3
    return 0;
    80003b1e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b20:	0ad76063          	bltu	a4,a3,80003bc0 <readi+0xd2>
  if(off + n > ip->size)
    80003b24:	00e7f463          	bgeu	a5,a4,80003b2c <readi+0x3e>
    n = ip->size - off;
    80003b28:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b2c:	0a0a8963          	beqz	s5,80003bde <readi+0xf0>
    80003b30:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b32:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b36:	5c7d                	li	s8,-1
    80003b38:	a82d                	j	80003b72 <readi+0x84>
    80003b3a:	020d1d93          	slli	s11,s10,0x20
    80003b3e:	020ddd93          	srli	s11,s11,0x20
    80003b42:	05890613          	addi	a2,s2,88
    80003b46:	86ee                	mv	a3,s11
    80003b48:	963a                	add	a2,a2,a4
    80003b4a:	85d2                	mv	a1,s4
    80003b4c:	855e                	mv	a0,s7
    80003b4e:	fffff097          	auipc	ra,0xfffff
    80003b52:	986080e7          	jalr	-1658(ra) # 800024d4 <either_copyout>
    80003b56:	05850d63          	beq	a0,s8,80003bb0 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b5a:	854a                	mv	a0,s2
    80003b5c:	fffff097          	auipc	ra,0xfffff
    80003b60:	5f4080e7          	jalr	1524(ra) # 80003150 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b64:	013d09bb          	addw	s3,s10,s3
    80003b68:	009d04bb          	addw	s1,s10,s1
    80003b6c:	9a6e                	add	s4,s4,s11
    80003b6e:	0559f763          	bgeu	s3,s5,80003bbc <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003b72:	00a4d59b          	srliw	a1,s1,0xa
    80003b76:	855a                	mv	a0,s6
    80003b78:	00000097          	auipc	ra,0x0
    80003b7c:	8a2080e7          	jalr	-1886(ra) # 8000341a <bmap>
    80003b80:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b84:	cd85                	beqz	a1,80003bbc <readi+0xce>
    bp = bread(ip->dev, addr);
    80003b86:	000b2503          	lw	a0,0(s6)
    80003b8a:	fffff097          	auipc	ra,0xfffff
    80003b8e:	496080e7          	jalr	1174(ra) # 80003020 <bread>
    80003b92:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b94:	3ff4f713          	andi	a4,s1,1023
    80003b98:	40ec87bb          	subw	a5,s9,a4
    80003b9c:	413a86bb          	subw	a3,s5,s3
    80003ba0:	8d3e                	mv	s10,a5
    80003ba2:	2781                	sext.w	a5,a5
    80003ba4:	0006861b          	sext.w	a2,a3
    80003ba8:	f8f679e3          	bgeu	a2,a5,80003b3a <readi+0x4c>
    80003bac:	8d36                	mv	s10,a3
    80003bae:	b771                	j	80003b3a <readi+0x4c>
      brelse(bp);
    80003bb0:	854a                	mv	a0,s2
    80003bb2:	fffff097          	auipc	ra,0xfffff
    80003bb6:	59e080e7          	jalr	1438(ra) # 80003150 <brelse>
      tot = -1;
    80003bba:	59fd                	li	s3,-1
  }
  return tot;
    80003bbc:	0009851b          	sext.w	a0,s3
}
    80003bc0:	70a6                	ld	ra,104(sp)
    80003bc2:	7406                	ld	s0,96(sp)
    80003bc4:	64e6                	ld	s1,88(sp)
    80003bc6:	6946                	ld	s2,80(sp)
    80003bc8:	69a6                	ld	s3,72(sp)
    80003bca:	6a06                	ld	s4,64(sp)
    80003bcc:	7ae2                	ld	s5,56(sp)
    80003bce:	7b42                	ld	s6,48(sp)
    80003bd0:	7ba2                	ld	s7,40(sp)
    80003bd2:	7c02                	ld	s8,32(sp)
    80003bd4:	6ce2                	ld	s9,24(sp)
    80003bd6:	6d42                	ld	s10,16(sp)
    80003bd8:	6da2                	ld	s11,8(sp)
    80003bda:	6165                	addi	sp,sp,112
    80003bdc:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bde:	89d6                	mv	s3,s5
    80003be0:	bff1                	j	80003bbc <readi+0xce>
    return 0;
    80003be2:	4501                	li	a0,0
}
    80003be4:	8082                	ret

0000000080003be6 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003be6:	457c                	lw	a5,76(a0)
    80003be8:	10d7e863          	bltu	a5,a3,80003cf8 <writei+0x112>
{
    80003bec:	7159                	addi	sp,sp,-112
    80003bee:	f486                	sd	ra,104(sp)
    80003bf0:	f0a2                	sd	s0,96(sp)
    80003bf2:	eca6                	sd	s1,88(sp)
    80003bf4:	e8ca                	sd	s2,80(sp)
    80003bf6:	e4ce                	sd	s3,72(sp)
    80003bf8:	e0d2                	sd	s4,64(sp)
    80003bfa:	fc56                	sd	s5,56(sp)
    80003bfc:	f85a                	sd	s6,48(sp)
    80003bfe:	f45e                	sd	s7,40(sp)
    80003c00:	f062                	sd	s8,32(sp)
    80003c02:	ec66                	sd	s9,24(sp)
    80003c04:	e86a                	sd	s10,16(sp)
    80003c06:	e46e                	sd	s11,8(sp)
    80003c08:	1880                	addi	s0,sp,112
    80003c0a:	8aaa                	mv	s5,a0
    80003c0c:	8bae                	mv	s7,a1
    80003c0e:	8a32                	mv	s4,a2
    80003c10:	8936                	mv	s2,a3
    80003c12:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c14:	00e687bb          	addw	a5,a3,a4
    80003c18:	0ed7e263          	bltu	a5,a3,80003cfc <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c1c:	00043737          	lui	a4,0x43
    80003c20:	0ef76063          	bltu	a4,a5,80003d00 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c24:	0c0b0863          	beqz	s6,80003cf4 <writei+0x10e>
    80003c28:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c2a:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c2e:	5c7d                	li	s8,-1
    80003c30:	a091                	j	80003c74 <writei+0x8e>
    80003c32:	020d1d93          	slli	s11,s10,0x20
    80003c36:	020ddd93          	srli	s11,s11,0x20
    80003c3a:	05848513          	addi	a0,s1,88
    80003c3e:	86ee                	mv	a3,s11
    80003c40:	8652                	mv	a2,s4
    80003c42:	85de                	mv	a1,s7
    80003c44:	953a                	add	a0,a0,a4
    80003c46:	fffff097          	auipc	ra,0xfffff
    80003c4a:	8e4080e7          	jalr	-1820(ra) # 8000252a <either_copyin>
    80003c4e:	07850263          	beq	a0,s8,80003cb2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c52:	8526                	mv	a0,s1
    80003c54:	00000097          	auipc	ra,0x0
    80003c58:	780080e7          	jalr	1920(ra) # 800043d4 <log_write>
    brelse(bp);
    80003c5c:	8526                	mv	a0,s1
    80003c5e:	fffff097          	auipc	ra,0xfffff
    80003c62:	4f2080e7          	jalr	1266(ra) # 80003150 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c66:	013d09bb          	addw	s3,s10,s3
    80003c6a:	012d093b          	addw	s2,s10,s2
    80003c6e:	9a6e                	add	s4,s4,s11
    80003c70:	0569f663          	bgeu	s3,s6,80003cbc <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003c74:	00a9559b          	srliw	a1,s2,0xa
    80003c78:	8556                	mv	a0,s5
    80003c7a:	fffff097          	auipc	ra,0xfffff
    80003c7e:	7a0080e7          	jalr	1952(ra) # 8000341a <bmap>
    80003c82:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c86:	c99d                	beqz	a1,80003cbc <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003c88:	000aa503          	lw	a0,0(s5)
    80003c8c:	fffff097          	auipc	ra,0xfffff
    80003c90:	394080e7          	jalr	916(ra) # 80003020 <bread>
    80003c94:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c96:	3ff97713          	andi	a4,s2,1023
    80003c9a:	40ec87bb          	subw	a5,s9,a4
    80003c9e:	413b06bb          	subw	a3,s6,s3
    80003ca2:	8d3e                	mv	s10,a5
    80003ca4:	2781                	sext.w	a5,a5
    80003ca6:	0006861b          	sext.w	a2,a3
    80003caa:	f8f674e3          	bgeu	a2,a5,80003c32 <writei+0x4c>
    80003cae:	8d36                	mv	s10,a3
    80003cb0:	b749                	j	80003c32 <writei+0x4c>
      brelse(bp);
    80003cb2:	8526                	mv	a0,s1
    80003cb4:	fffff097          	auipc	ra,0xfffff
    80003cb8:	49c080e7          	jalr	1180(ra) # 80003150 <brelse>
  }

  if(off > ip->size)
    80003cbc:	04caa783          	lw	a5,76(s5)
    80003cc0:	0127f463          	bgeu	a5,s2,80003cc8 <writei+0xe2>
    ip->size = off;
    80003cc4:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003cc8:	8556                	mv	a0,s5
    80003cca:	00000097          	auipc	ra,0x0
    80003cce:	aa6080e7          	jalr	-1370(ra) # 80003770 <iupdate>

  return tot;
    80003cd2:	0009851b          	sext.w	a0,s3
}
    80003cd6:	70a6                	ld	ra,104(sp)
    80003cd8:	7406                	ld	s0,96(sp)
    80003cda:	64e6                	ld	s1,88(sp)
    80003cdc:	6946                	ld	s2,80(sp)
    80003cde:	69a6                	ld	s3,72(sp)
    80003ce0:	6a06                	ld	s4,64(sp)
    80003ce2:	7ae2                	ld	s5,56(sp)
    80003ce4:	7b42                	ld	s6,48(sp)
    80003ce6:	7ba2                	ld	s7,40(sp)
    80003ce8:	7c02                	ld	s8,32(sp)
    80003cea:	6ce2                	ld	s9,24(sp)
    80003cec:	6d42                	ld	s10,16(sp)
    80003cee:	6da2                	ld	s11,8(sp)
    80003cf0:	6165                	addi	sp,sp,112
    80003cf2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cf4:	89da                	mv	s3,s6
    80003cf6:	bfc9                	j	80003cc8 <writei+0xe2>
    return -1;
    80003cf8:	557d                	li	a0,-1
}
    80003cfa:	8082                	ret
    return -1;
    80003cfc:	557d                	li	a0,-1
    80003cfe:	bfe1                	j	80003cd6 <writei+0xf0>
    return -1;
    80003d00:	557d                	li	a0,-1
    80003d02:	bfd1                	j	80003cd6 <writei+0xf0>

0000000080003d04 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d04:	1141                	addi	sp,sp,-16
    80003d06:	e406                	sd	ra,8(sp)
    80003d08:	e022                	sd	s0,0(sp)
    80003d0a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d0c:	4639                	li	a2,14
    80003d0e:	ffffd097          	auipc	ra,0xffffd
    80003d12:	0b0080e7          	jalr	176(ra) # 80000dbe <strncmp>
}
    80003d16:	60a2                	ld	ra,8(sp)
    80003d18:	6402                	ld	s0,0(sp)
    80003d1a:	0141                	addi	sp,sp,16
    80003d1c:	8082                	ret

0000000080003d1e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d1e:	7139                	addi	sp,sp,-64
    80003d20:	fc06                	sd	ra,56(sp)
    80003d22:	f822                	sd	s0,48(sp)
    80003d24:	f426                	sd	s1,40(sp)
    80003d26:	f04a                	sd	s2,32(sp)
    80003d28:	ec4e                	sd	s3,24(sp)
    80003d2a:	e852                	sd	s4,16(sp)
    80003d2c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d2e:	04451703          	lh	a4,68(a0)
    80003d32:	4785                	li	a5,1
    80003d34:	00f71a63          	bne	a4,a5,80003d48 <dirlookup+0x2a>
    80003d38:	892a                	mv	s2,a0
    80003d3a:	89ae                	mv	s3,a1
    80003d3c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d3e:	457c                	lw	a5,76(a0)
    80003d40:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d42:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d44:	e79d                	bnez	a5,80003d72 <dirlookup+0x54>
    80003d46:	a8a5                	j	80003dbe <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d48:	00005517          	auipc	a0,0x5
    80003d4c:	9b050513          	addi	a0,a0,-1616 # 800086f8 <syscalls+0x1c8>
    80003d50:	ffffc097          	auipc	ra,0xffffc
    80003d54:	7f4080e7          	jalr	2036(ra) # 80000544 <panic>
      panic("dirlookup read");
    80003d58:	00005517          	auipc	a0,0x5
    80003d5c:	9b850513          	addi	a0,a0,-1608 # 80008710 <syscalls+0x1e0>
    80003d60:	ffffc097          	auipc	ra,0xffffc
    80003d64:	7e4080e7          	jalr	2020(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d68:	24c1                	addiw	s1,s1,16
    80003d6a:	04c92783          	lw	a5,76(s2)
    80003d6e:	04f4f763          	bgeu	s1,a5,80003dbc <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d72:	4741                	li	a4,16
    80003d74:	86a6                	mv	a3,s1
    80003d76:	fc040613          	addi	a2,s0,-64
    80003d7a:	4581                	li	a1,0
    80003d7c:	854a                	mv	a0,s2
    80003d7e:	00000097          	auipc	ra,0x0
    80003d82:	d70080e7          	jalr	-656(ra) # 80003aee <readi>
    80003d86:	47c1                	li	a5,16
    80003d88:	fcf518e3          	bne	a0,a5,80003d58 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d8c:	fc045783          	lhu	a5,-64(s0)
    80003d90:	dfe1                	beqz	a5,80003d68 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d92:	fc240593          	addi	a1,s0,-62
    80003d96:	854e                	mv	a0,s3
    80003d98:	00000097          	auipc	ra,0x0
    80003d9c:	f6c080e7          	jalr	-148(ra) # 80003d04 <namecmp>
    80003da0:	f561                	bnez	a0,80003d68 <dirlookup+0x4a>
      if(poff)
    80003da2:	000a0463          	beqz	s4,80003daa <dirlookup+0x8c>
        *poff = off;
    80003da6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003daa:	fc045583          	lhu	a1,-64(s0)
    80003dae:	00092503          	lw	a0,0(s2)
    80003db2:	fffff097          	auipc	ra,0xfffff
    80003db6:	750080e7          	jalr	1872(ra) # 80003502 <iget>
    80003dba:	a011                	j	80003dbe <dirlookup+0xa0>
  return 0;
    80003dbc:	4501                	li	a0,0
}
    80003dbe:	70e2                	ld	ra,56(sp)
    80003dc0:	7442                	ld	s0,48(sp)
    80003dc2:	74a2                	ld	s1,40(sp)
    80003dc4:	7902                	ld	s2,32(sp)
    80003dc6:	69e2                	ld	s3,24(sp)
    80003dc8:	6a42                	ld	s4,16(sp)
    80003dca:	6121                	addi	sp,sp,64
    80003dcc:	8082                	ret

0000000080003dce <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003dce:	711d                	addi	sp,sp,-96
    80003dd0:	ec86                	sd	ra,88(sp)
    80003dd2:	e8a2                	sd	s0,80(sp)
    80003dd4:	e4a6                	sd	s1,72(sp)
    80003dd6:	e0ca                	sd	s2,64(sp)
    80003dd8:	fc4e                	sd	s3,56(sp)
    80003dda:	f852                	sd	s4,48(sp)
    80003ddc:	f456                	sd	s5,40(sp)
    80003dde:	f05a                	sd	s6,32(sp)
    80003de0:	ec5e                	sd	s7,24(sp)
    80003de2:	e862                	sd	s8,16(sp)
    80003de4:	e466                	sd	s9,8(sp)
    80003de6:	1080                	addi	s0,sp,96
    80003de8:	84aa                	mv	s1,a0
    80003dea:	8b2e                	mv	s6,a1
    80003dec:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003dee:	00054703          	lbu	a4,0(a0)
    80003df2:	02f00793          	li	a5,47
    80003df6:	02f70363          	beq	a4,a5,80003e1c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003dfa:	ffffe097          	auipc	ra,0xffffe
    80003dfe:	bcc080e7          	jalr	-1076(ra) # 800019c6 <myproc>
    80003e02:	15053503          	ld	a0,336(a0)
    80003e06:	00000097          	auipc	ra,0x0
    80003e0a:	9f6080e7          	jalr	-1546(ra) # 800037fc <idup>
    80003e0e:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e10:	02f00913          	li	s2,47
  len = path - s;
    80003e14:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003e16:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e18:	4c05                	li	s8,1
    80003e1a:	a865                	j	80003ed2 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e1c:	4585                	li	a1,1
    80003e1e:	4505                	li	a0,1
    80003e20:	fffff097          	auipc	ra,0xfffff
    80003e24:	6e2080e7          	jalr	1762(ra) # 80003502 <iget>
    80003e28:	89aa                	mv	s3,a0
    80003e2a:	b7dd                	j	80003e10 <namex+0x42>
      iunlockput(ip);
    80003e2c:	854e                	mv	a0,s3
    80003e2e:	00000097          	auipc	ra,0x0
    80003e32:	c6e080e7          	jalr	-914(ra) # 80003a9c <iunlockput>
      return 0;
    80003e36:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e38:	854e                	mv	a0,s3
    80003e3a:	60e6                	ld	ra,88(sp)
    80003e3c:	6446                	ld	s0,80(sp)
    80003e3e:	64a6                	ld	s1,72(sp)
    80003e40:	6906                	ld	s2,64(sp)
    80003e42:	79e2                	ld	s3,56(sp)
    80003e44:	7a42                	ld	s4,48(sp)
    80003e46:	7aa2                	ld	s5,40(sp)
    80003e48:	7b02                	ld	s6,32(sp)
    80003e4a:	6be2                	ld	s7,24(sp)
    80003e4c:	6c42                	ld	s8,16(sp)
    80003e4e:	6ca2                	ld	s9,8(sp)
    80003e50:	6125                	addi	sp,sp,96
    80003e52:	8082                	ret
      iunlock(ip);
    80003e54:	854e                	mv	a0,s3
    80003e56:	00000097          	auipc	ra,0x0
    80003e5a:	aa6080e7          	jalr	-1370(ra) # 800038fc <iunlock>
      return ip;
    80003e5e:	bfe9                	j	80003e38 <namex+0x6a>
      iunlockput(ip);
    80003e60:	854e                	mv	a0,s3
    80003e62:	00000097          	auipc	ra,0x0
    80003e66:	c3a080e7          	jalr	-966(ra) # 80003a9c <iunlockput>
      return 0;
    80003e6a:	89d2                	mv	s3,s4
    80003e6c:	b7f1                	j	80003e38 <namex+0x6a>
  len = path - s;
    80003e6e:	40b48633          	sub	a2,s1,a1
    80003e72:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003e76:	094cd463          	bge	s9,s4,80003efe <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e7a:	4639                	li	a2,14
    80003e7c:	8556                	mv	a0,s5
    80003e7e:	ffffd097          	auipc	ra,0xffffd
    80003e82:	ec8080e7          	jalr	-312(ra) # 80000d46 <memmove>
  while(*path == '/')
    80003e86:	0004c783          	lbu	a5,0(s1)
    80003e8a:	01279763          	bne	a5,s2,80003e98 <namex+0xca>
    path++;
    80003e8e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e90:	0004c783          	lbu	a5,0(s1)
    80003e94:	ff278de3          	beq	a5,s2,80003e8e <namex+0xc0>
    ilock(ip);
    80003e98:	854e                	mv	a0,s3
    80003e9a:	00000097          	auipc	ra,0x0
    80003e9e:	9a0080e7          	jalr	-1632(ra) # 8000383a <ilock>
    if(ip->type != T_DIR){
    80003ea2:	04499783          	lh	a5,68(s3)
    80003ea6:	f98793e3          	bne	a5,s8,80003e2c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003eaa:	000b0563          	beqz	s6,80003eb4 <namex+0xe6>
    80003eae:	0004c783          	lbu	a5,0(s1)
    80003eb2:	d3cd                	beqz	a5,80003e54 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003eb4:	865e                	mv	a2,s7
    80003eb6:	85d6                	mv	a1,s5
    80003eb8:	854e                	mv	a0,s3
    80003eba:	00000097          	auipc	ra,0x0
    80003ebe:	e64080e7          	jalr	-412(ra) # 80003d1e <dirlookup>
    80003ec2:	8a2a                	mv	s4,a0
    80003ec4:	dd51                	beqz	a0,80003e60 <namex+0x92>
    iunlockput(ip);
    80003ec6:	854e                	mv	a0,s3
    80003ec8:	00000097          	auipc	ra,0x0
    80003ecc:	bd4080e7          	jalr	-1068(ra) # 80003a9c <iunlockput>
    ip = next;
    80003ed0:	89d2                	mv	s3,s4
  while(*path == '/')
    80003ed2:	0004c783          	lbu	a5,0(s1)
    80003ed6:	05279763          	bne	a5,s2,80003f24 <namex+0x156>
    path++;
    80003eda:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003edc:	0004c783          	lbu	a5,0(s1)
    80003ee0:	ff278de3          	beq	a5,s2,80003eda <namex+0x10c>
  if(*path == 0)
    80003ee4:	c79d                	beqz	a5,80003f12 <namex+0x144>
    path++;
    80003ee6:	85a6                	mv	a1,s1
  len = path - s;
    80003ee8:	8a5e                	mv	s4,s7
    80003eea:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003eec:	01278963          	beq	a5,s2,80003efe <namex+0x130>
    80003ef0:	dfbd                	beqz	a5,80003e6e <namex+0xa0>
    path++;
    80003ef2:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003ef4:	0004c783          	lbu	a5,0(s1)
    80003ef8:	ff279ce3          	bne	a5,s2,80003ef0 <namex+0x122>
    80003efc:	bf8d                	j	80003e6e <namex+0xa0>
    memmove(name, s, len);
    80003efe:	2601                	sext.w	a2,a2
    80003f00:	8556                	mv	a0,s5
    80003f02:	ffffd097          	auipc	ra,0xffffd
    80003f06:	e44080e7          	jalr	-444(ra) # 80000d46 <memmove>
    name[len] = 0;
    80003f0a:	9a56                	add	s4,s4,s5
    80003f0c:	000a0023          	sb	zero,0(s4)
    80003f10:	bf9d                	j	80003e86 <namex+0xb8>
  if(nameiparent){
    80003f12:	f20b03e3          	beqz	s6,80003e38 <namex+0x6a>
    iput(ip);
    80003f16:	854e                	mv	a0,s3
    80003f18:	00000097          	auipc	ra,0x0
    80003f1c:	adc080e7          	jalr	-1316(ra) # 800039f4 <iput>
    return 0;
    80003f20:	4981                	li	s3,0
    80003f22:	bf19                	j	80003e38 <namex+0x6a>
  if(*path == 0)
    80003f24:	d7fd                	beqz	a5,80003f12 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f26:	0004c783          	lbu	a5,0(s1)
    80003f2a:	85a6                	mv	a1,s1
    80003f2c:	b7d1                	j	80003ef0 <namex+0x122>

0000000080003f2e <dirlink>:
{
    80003f2e:	7139                	addi	sp,sp,-64
    80003f30:	fc06                	sd	ra,56(sp)
    80003f32:	f822                	sd	s0,48(sp)
    80003f34:	f426                	sd	s1,40(sp)
    80003f36:	f04a                	sd	s2,32(sp)
    80003f38:	ec4e                	sd	s3,24(sp)
    80003f3a:	e852                	sd	s4,16(sp)
    80003f3c:	0080                	addi	s0,sp,64
    80003f3e:	892a                	mv	s2,a0
    80003f40:	8a2e                	mv	s4,a1
    80003f42:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f44:	4601                	li	a2,0
    80003f46:	00000097          	auipc	ra,0x0
    80003f4a:	dd8080e7          	jalr	-552(ra) # 80003d1e <dirlookup>
    80003f4e:	e93d                	bnez	a0,80003fc4 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f50:	04c92483          	lw	s1,76(s2)
    80003f54:	c49d                	beqz	s1,80003f82 <dirlink+0x54>
    80003f56:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f58:	4741                	li	a4,16
    80003f5a:	86a6                	mv	a3,s1
    80003f5c:	fc040613          	addi	a2,s0,-64
    80003f60:	4581                	li	a1,0
    80003f62:	854a                	mv	a0,s2
    80003f64:	00000097          	auipc	ra,0x0
    80003f68:	b8a080e7          	jalr	-1142(ra) # 80003aee <readi>
    80003f6c:	47c1                	li	a5,16
    80003f6e:	06f51163          	bne	a0,a5,80003fd0 <dirlink+0xa2>
    if(de.inum == 0)
    80003f72:	fc045783          	lhu	a5,-64(s0)
    80003f76:	c791                	beqz	a5,80003f82 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f78:	24c1                	addiw	s1,s1,16
    80003f7a:	04c92783          	lw	a5,76(s2)
    80003f7e:	fcf4ede3          	bltu	s1,a5,80003f58 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f82:	4639                	li	a2,14
    80003f84:	85d2                	mv	a1,s4
    80003f86:	fc240513          	addi	a0,s0,-62
    80003f8a:	ffffd097          	auipc	ra,0xffffd
    80003f8e:	e70080e7          	jalr	-400(ra) # 80000dfa <strncpy>
  de.inum = inum;
    80003f92:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f96:	4741                	li	a4,16
    80003f98:	86a6                	mv	a3,s1
    80003f9a:	fc040613          	addi	a2,s0,-64
    80003f9e:	4581                	li	a1,0
    80003fa0:	854a                	mv	a0,s2
    80003fa2:	00000097          	auipc	ra,0x0
    80003fa6:	c44080e7          	jalr	-956(ra) # 80003be6 <writei>
    80003faa:	1541                	addi	a0,a0,-16
    80003fac:	00a03533          	snez	a0,a0
    80003fb0:	40a00533          	neg	a0,a0
}
    80003fb4:	70e2                	ld	ra,56(sp)
    80003fb6:	7442                	ld	s0,48(sp)
    80003fb8:	74a2                	ld	s1,40(sp)
    80003fba:	7902                	ld	s2,32(sp)
    80003fbc:	69e2                	ld	s3,24(sp)
    80003fbe:	6a42                	ld	s4,16(sp)
    80003fc0:	6121                	addi	sp,sp,64
    80003fc2:	8082                	ret
    iput(ip);
    80003fc4:	00000097          	auipc	ra,0x0
    80003fc8:	a30080e7          	jalr	-1488(ra) # 800039f4 <iput>
    return -1;
    80003fcc:	557d                	li	a0,-1
    80003fce:	b7dd                	j	80003fb4 <dirlink+0x86>
      panic("dirlink read");
    80003fd0:	00004517          	auipc	a0,0x4
    80003fd4:	75050513          	addi	a0,a0,1872 # 80008720 <syscalls+0x1f0>
    80003fd8:	ffffc097          	auipc	ra,0xffffc
    80003fdc:	56c080e7          	jalr	1388(ra) # 80000544 <panic>

0000000080003fe0 <namei>:

struct inode*
namei(char *path)
{
    80003fe0:	1101                	addi	sp,sp,-32
    80003fe2:	ec06                	sd	ra,24(sp)
    80003fe4:	e822                	sd	s0,16(sp)
    80003fe6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003fe8:	fe040613          	addi	a2,s0,-32
    80003fec:	4581                	li	a1,0
    80003fee:	00000097          	auipc	ra,0x0
    80003ff2:	de0080e7          	jalr	-544(ra) # 80003dce <namex>
}
    80003ff6:	60e2                	ld	ra,24(sp)
    80003ff8:	6442                	ld	s0,16(sp)
    80003ffa:	6105                	addi	sp,sp,32
    80003ffc:	8082                	ret

0000000080003ffe <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003ffe:	1141                	addi	sp,sp,-16
    80004000:	e406                	sd	ra,8(sp)
    80004002:	e022                	sd	s0,0(sp)
    80004004:	0800                	addi	s0,sp,16
    80004006:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004008:	4585                	li	a1,1
    8000400a:	00000097          	auipc	ra,0x0
    8000400e:	dc4080e7          	jalr	-572(ra) # 80003dce <namex>
}
    80004012:	60a2                	ld	ra,8(sp)
    80004014:	6402                	ld	s0,0(sp)
    80004016:	0141                	addi	sp,sp,16
    80004018:	8082                	ret

000000008000401a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000401a:	1101                	addi	sp,sp,-32
    8000401c:	ec06                	sd	ra,24(sp)
    8000401e:	e822                	sd	s0,16(sp)
    80004020:	e426                	sd	s1,8(sp)
    80004022:	e04a                	sd	s2,0(sp)
    80004024:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004026:	0001d917          	auipc	s2,0x1d
    8000402a:	6da90913          	addi	s2,s2,1754 # 80021700 <log>
    8000402e:	01892583          	lw	a1,24(s2)
    80004032:	02892503          	lw	a0,40(s2)
    80004036:	fffff097          	auipc	ra,0xfffff
    8000403a:	fea080e7          	jalr	-22(ra) # 80003020 <bread>
    8000403e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004040:	02c92683          	lw	a3,44(s2)
    80004044:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004046:	02d05763          	blez	a3,80004074 <write_head+0x5a>
    8000404a:	0001d797          	auipc	a5,0x1d
    8000404e:	6e678793          	addi	a5,a5,1766 # 80021730 <log+0x30>
    80004052:	05c50713          	addi	a4,a0,92
    80004056:	36fd                	addiw	a3,a3,-1
    80004058:	1682                	slli	a3,a3,0x20
    8000405a:	9281                	srli	a3,a3,0x20
    8000405c:	068a                	slli	a3,a3,0x2
    8000405e:	0001d617          	auipc	a2,0x1d
    80004062:	6d660613          	addi	a2,a2,1750 # 80021734 <log+0x34>
    80004066:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004068:	4390                	lw	a2,0(a5)
    8000406a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000406c:	0791                	addi	a5,a5,4
    8000406e:	0711                	addi	a4,a4,4
    80004070:	fed79ce3          	bne	a5,a3,80004068 <write_head+0x4e>
  }
  bwrite(buf);
    80004074:	8526                	mv	a0,s1
    80004076:	fffff097          	auipc	ra,0xfffff
    8000407a:	09c080e7          	jalr	156(ra) # 80003112 <bwrite>
  brelse(buf);
    8000407e:	8526                	mv	a0,s1
    80004080:	fffff097          	auipc	ra,0xfffff
    80004084:	0d0080e7          	jalr	208(ra) # 80003150 <brelse>
}
    80004088:	60e2                	ld	ra,24(sp)
    8000408a:	6442                	ld	s0,16(sp)
    8000408c:	64a2                	ld	s1,8(sp)
    8000408e:	6902                	ld	s2,0(sp)
    80004090:	6105                	addi	sp,sp,32
    80004092:	8082                	ret

0000000080004094 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004094:	0001d797          	auipc	a5,0x1d
    80004098:	6987a783          	lw	a5,1688(a5) # 8002172c <log+0x2c>
    8000409c:	0af05d63          	blez	a5,80004156 <install_trans+0xc2>
{
    800040a0:	7139                	addi	sp,sp,-64
    800040a2:	fc06                	sd	ra,56(sp)
    800040a4:	f822                	sd	s0,48(sp)
    800040a6:	f426                	sd	s1,40(sp)
    800040a8:	f04a                	sd	s2,32(sp)
    800040aa:	ec4e                	sd	s3,24(sp)
    800040ac:	e852                	sd	s4,16(sp)
    800040ae:	e456                	sd	s5,8(sp)
    800040b0:	e05a                	sd	s6,0(sp)
    800040b2:	0080                	addi	s0,sp,64
    800040b4:	8b2a                	mv	s6,a0
    800040b6:	0001da97          	auipc	s5,0x1d
    800040ba:	67aa8a93          	addi	s5,s5,1658 # 80021730 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040be:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040c0:	0001d997          	auipc	s3,0x1d
    800040c4:	64098993          	addi	s3,s3,1600 # 80021700 <log>
    800040c8:	a035                	j	800040f4 <install_trans+0x60>
      bunpin(dbuf);
    800040ca:	8526                	mv	a0,s1
    800040cc:	fffff097          	auipc	ra,0xfffff
    800040d0:	15e080e7          	jalr	350(ra) # 8000322a <bunpin>
    brelse(lbuf);
    800040d4:	854a                	mv	a0,s2
    800040d6:	fffff097          	auipc	ra,0xfffff
    800040da:	07a080e7          	jalr	122(ra) # 80003150 <brelse>
    brelse(dbuf);
    800040de:	8526                	mv	a0,s1
    800040e0:	fffff097          	auipc	ra,0xfffff
    800040e4:	070080e7          	jalr	112(ra) # 80003150 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040e8:	2a05                	addiw	s4,s4,1
    800040ea:	0a91                	addi	s5,s5,4
    800040ec:	02c9a783          	lw	a5,44(s3)
    800040f0:	04fa5963          	bge	s4,a5,80004142 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040f4:	0189a583          	lw	a1,24(s3)
    800040f8:	014585bb          	addw	a1,a1,s4
    800040fc:	2585                	addiw	a1,a1,1
    800040fe:	0289a503          	lw	a0,40(s3)
    80004102:	fffff097          	auipc	ra,0xfffff
    80004106:	f1e080e7          	jalr	-226(ra) # 80003020 <bread>
    8000410a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000410c:	000aa583          	lw	a1,0(s5)
    80004110:	0289a503          	lw	a0,40(s3)
    80004114:	fffff097          	auipc	ra,0xfffff
    80004118:	f0c080e7          	jalr	-244(ra) # 80003020 <bread>
    8000411c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000411e:	40000613          	li	a2,1024
    80004122:	05890593          	addi	a1,s2,88
    80004126:	05850513          	addi	a0,a0,88
    8000412a:	ffffd097          	auipc	ra,0xffffd
    8000412e:	c1c080e7          	jalr	-996(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004132:	8526                	mv	a0,s1
    80004134:	fffff097          	auipc	ra,0xfffff
    80004138:	fde080e7          	jalr	-34(ra) # 80003112 <bwrite>
    if(recovering == 0)
    8000413c:	f80b1ce3          	bnez	s6,800040d4 <install_trans+0x40>
    80004140:	b769                	j	800040ca <install_trans+0x36>
}
    80004142:	70e2                	ld	ra,56(sp)
    80004144:	7442                	ld	s0,48(sp)
    80004146:	74a2                	ld	s1,40(sp)
    80004148:	7902                	ld	s2,32(sp)
    8000414a:	69e2                	ld	s3,24(sp)
    8000414c:	6a42                	ld	s4,16(sp)
    8000414e:	6aa2                	ld	s5,8(sp)
    80004150:	6b02                	ld	s6,0(sp)
    80004152:	6121                	addi	sp,sp,64
    80004154:	8082                	ret
    80004156:	8082                	ret

0000000080004158 <initlog>:
{
    80004158:	7179                	addi	sp,sp,-48
    8000415a:	f406                	sd	ra,40(sp)
    8000415c:	f022                	sd	s0,32(sp)
    8000415e:	ec26                	sd	s1,24(sp)
    80004160:	e84a                	sd	s2,16(sp)
    80004162:	e44e                	sd	s3,8(sp)
    80004164:	1800                	addi	s0,sp,48
    80004166:	892a                	mv	s2,a0
    80004168:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000416a:	0001d497          	auipc	s1,0x1d
    8000416e:	59648493          	addi	s1,s1,1430 # 80021700 <log>
    80004172:	00004597          	auipc	a1,0x4
    80004176:	5be58593          	addi	a1,a1,1470 # 80008730 <syscalls+0x200>
    8000417a:	8526                	mv	a0,s1
    8000417c:	ffffd097          	auipc	ra,0xffffd
    80004180:	9de080e7          	jalr	-1570(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    80004184:	0149a583          	lw	a1,20(s3)
    80004188:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000418a:	0109a783          	lw	a5,16(s3)
    8000418e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004190:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004194:	854a                	mv	a0,s2
    80004196:	fffff097          	auipc	ra,0xfffff
    8000419a:	e8a080e7          	jalr	-374(ra) # 80003020 <bread>
  log.lh.n = lh->n;
    8000419e:	4d3c                	lw	a5,88(a0)
    800041a0:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800041a2:	02f05563          	blez	a5,800041cc <initlog+0x74>
    800041a6:	05c50713          	addi	a4,a0,92
    800041aa:	0001d697          	auipc	a3,0x1d
    800041ae:	58668693          	addi	a3,a3,1414 # 80021730 <log+0x30>
    800041b2:	37fd                	addiw	a5,a5,-1
    800041b4:	1782                	slli	a5,a5,0x20
    800041b6:	9381                	srli	a5,a5,0x20
    800041b8:	078a                	slli	a5,a5,0x2
    800041ba:	06050613          	addi	a2,a0,96
    800041be:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800041c0:	4310                	lw	a2,0(a4)
    800041c2:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800041c4:	0711                	addi	a4,a4,4
    800041c6:	0691                	addi	a3,a3,4
    800041c8:	fef71ce3          	bne	a4,a5,800041c0 <initlog+0x68>
  brelse(buf);
    800041cc:	fffff097          	auipc	ra,0xfffff
    800041d0:	f84080e7          	jalr	-124(ra) # 80003150 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800041d4:	4505                	li	a0,1
    800041d6:	00000097          	auipc	ra,0x0
    800041da:	ebe080e7          	jalr	-322(ra) # 80004094 <install_trans>
  log.lh.n = 0;
    800041de:	0001d797          	auipc	a5,0x1d
    800041e2:	5407a723          	sw	zero,1358(a5) # 8002172c <log+0x2c>
  write_head(); // clear the log
    800041e6:	00000097          	auipc	ra,0x0
    800041ea:	e34080e7          	jalr	-460(ra) # 8000401a <write_head>
}
    800041ee:	70a2                	ld	ra,40(sp)
    800041f0:	7402                	ld	s0,32(sp)
    800041f2:	64e2                	ld	s1,24(sp)
    800041f4:	6942                	ld	s2,16(sp)
    800041f6:	69a2                	ld	s3,8(sp)
    800041f8:	6145                	addi	sp,sp,48
    800041fa:	8082                	ret

00000000800041fc <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800041fc:	1101                	addi	sp,sp,-32
    800041fe:	ec06                	sd	ra,24(sp)
    80004200:	e822                	sd	s0,16(sp)
    80004202:	e426                	sd	s1,8(sp)
    80004204:	e04a                	sd	s2,0(sp)
    80004206:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004208:	0001d517          	auipc	a0,0x1d
    8000420c:	4f850513          	addi	a0,a0,1272 # 80021700 <log>
    80004210:	ffffd097          	auipc	ra,0xffffd
    80004214:	9da080e7          	jalr	-1574(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    80004218:	0001d497          	auipc	s1,0x1d
    8000421c:	4e848493          	addi	s1,s1,1256 # 80021700 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004220:	4979                	li	s2,30
    80004222:	a039                	j	80004230 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004224:	85a6                	mv	a1,s1
    80004226:	8526                	mv	a0,s1
    80004228:	ffffe097          	auipc	ra,0xffffe
    8000422c:	ea4080e7          	jalr	-348(ra) # 800020cc <sleep>
    if(log.committing){
    80004230:	50dc                	lw	a5,36(s1)
    80004232:	fbed                	bnez	a5,80004224 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004234:	509c                	lw	a5,32(s1)
    80004236:	0017871b          	addiw	a4,a5,1
    8000423a:	0007069b          	sext.w	a3,a4
    8000423e:	0027179b          	slliw	a5,a4,0x2
    80004242:	9fb9                	addw	a5,a5,a4
    80004244:	0017979b          	slliw	a5,a5,0x1
    80004248:	54d8                	lw	a4,44(s1)
    8000424a:	9fb9                	addw	a5,a5,a4
    8000424c:	00f95963          	bge	s2,a5,8000425e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004250:	85a6                	mv	a1,s1
    80004252:	8526                	mv	a0,s1
    80004254:	ffffe097          	auipc	ra,0xffffe
    80004258:	e78080e7          	jalr	-392(ra) # 800020cc <sleep>
    8000425c:	bfd1                	j	80004230 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000425e:	0001d517          	auipc	a0,0x1d
    80004262:	4a250513          	addi	a0,a0,1186 # 80021700 <log>
    80004266:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004268:	ffffd097          	auipc	ra,0xffffd
    8000426c:	a36080e7          	jalr	-1482(ra) # 80000c9e <release>
      break;
    }
  }
}
    80004270:	60e2                	ld	ra,24(sp)
    80004272:	6442                	ld	s0,16(sp)
    80004274:	64a2                	ld	s1,8(sp)
    80004276:	6902                	ld	s2,0(sp)
    80004278:	6105                	addi	sp,sp,32
    8000427a:	8082                	ret

000000008000427c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000427c:	7139                	addi	sp,sp,-64
    8000427e:	fc06                	sd	ra,56(sp)
    80004280:	f822                	sd	s0,48(sp)
    80004282:	f426                	sd	s1,40(sp)
    80004284:	f04a                	sd	s2,32(sp)
    80004286:	ec4e                	sd	s3,24(sp)
    80004288:	e852                	sd	s4,16(sp)
    8000428a:	e456                	sd	s5,8(sp)
    8000428c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000428e:	0001d497          	auipc	s1,0x1d
    80004292:	47248493          	addi	s1,s1,1138 # 80021700 <log>
    80004296:	8526                	mv	a0,s1
    80004298:	ffffd097          	auipc	ra,0xffffd
    8000429c:	952080e7          	jalr	-1710(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    800042a0:	509c                	lw	a5,32(s1)
    800042a2:	37fd                	addiw	a5,a5,-1
    800042a4:	0007891b          	sext.w	s2,a5
    800042a8:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800042aa:	50dc                	lw	a5,36(s1)
    800042ac:	efb9                	bnez	a5,8000430a <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800042ae:	06091663          	bnez	s2,8000431a <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800042b2:	0001d497          	auipc	s1,0x1d
    800042b6:	44e48493          	addi	s1,s1,1102 # 80021700 <log>
    800042ba:	4785                	li	a5,1
    800042bc:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800042be:	8526                	mv	a0,s1
    800042c0:	ffffd097          	auipc	ra,0xffffd
    800042c4:	9de080e7          	jalr	-1570(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800042c8:	54dc                	lw	a5,44(s1)
    800042ca:	06f04763          	bgtz	a5,80004338 <end_op+0xbc>
    acquire(&log.lock);
    800042ce:	0001d497          	auipc	s1,0x1d
    800042d2:	43248493          	addi	s1,s1,1074 # 80021700 <log>
    800042d6:	8526                	mv	a0,s1
    800042d8:	ffffd097          	auipc	ra,0xffffd
    800042dc:	912080e7          	jalr	-1774(ra) # 80000bea <acquire>
    log.committing = 0;
    800042e0:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800042e4:	8526                	mv	a0,s1
    800042e6:	ffffe097          	auipc	ra,0xffffe
    800042ea:	e4a080e7          	jalr	-438(ra) # 80002130 <wakeup>
    release(&log.lock);
    800042ee:	8526                	mv	a0,s1
    800042f0:	ffffd097          	auipc	ra,0xffffd
    800042f4:	9ae080e7          	jalr	-1618(ra) # 80000c9e <release>
}
    800042f8:	70e2                	ld	ra,56(sp)
    800042fa:	7442                	ld	s0,48(sp)
    800042fc:	74a2                	ld	s1,40(sp)
    800042fe:	7902                	ld	s2,32(sp)
    80004300:	69e2                	ld	s3,24(sp)
    80004302:	6a42                	ld	s4,16(sp)
    80004304:	6aa2                	ld	s5,8(sp)
    80004306:	6121                	addi	sp,sp,64
    80004308:	8082                	ret
    panic("log.committing");
    8000430a:	00004517          	auipc	a0,0x4
    8000430e:	42e50513          	addi	a0,a0,1070 # 80008738 <syscalls+0x208>
    80004312:	ffffc097          	auipc	ra,0xffffc
    80004316:	232080e7          	jalr	562(ra) # 80000544 <panic>
    wakeup(&log);
    8000431a:	0001d497          	auipc	s1,0x1d
    8000431e:	3e648493          	addi	s1,s1,998 # 80021700 <log>
    80004322:	8526                	mv	a0,s1
    80004324:	ffffe097          	auipc	ra,0xffffe
    80004328:	e0c080e7          	jalr	-500(ra) # 80002130 <wakeup>
  release(&log.lock);
    8000432c:	8526                	mv	a0,s1
    8000432e:	ffffd097          	auipc	ra,0xffffd
    80004332:	970080e7          	jalr	-1680(ra) # 80000c9e <release>
  if(do_commit){
    80004336:	b7c9                	j	800042f8 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004338:	0001da97          	auipc	s5,0x1d
    8000433c:	3f8a8a93          	addi	s5,s5,1016 # 80021730 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004340:	0001da17          	auipc	s4,0x1d
    80004344:	3c0a0a13          	addi	s4,s4,960 # 80021700 <log>
    80004348:	018a2583          	lw	a1,24(s4)
    8000434c:	012585bb          	addw	a1,a1,s2
    80004350:	2585                	addiw	a1,a1,1
    80004352:	028a2503          	lw	a0,40(s4)
    80004356:	fffff097          	auipc	ra,0xfffff
    8000435a:	cca080e7          	jalr	-822(ra) # 80003020 <bread>
    8000435e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004360:	000aa583          	lw	a1,0(s5)
    80004364:	028a2503          	lw	a0,40(s4)
    80004368:	fffff097          	auipc	ra,0xfffff
    8000436c:	cb8080e7          	jalr	-840(ra) # 80003020 <bread>
    80004370:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004372:	40000613          	li	a2,1024
    80004376:	05850593          	addi	a1,a0,88
    8000437a:	05848513          	addi	a0,s1,88
    8000437e:	ffffd097          	auipc	ra,0xffffd
    80004382:	9c8080e7          	jalr	-1592(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    80004386:	8526                	mv	a0,s1
    80004388:	fffff097          	auipc	ra,0xfffff
    8000438c:	d8a080e7          	jalr	-630(ra) # 80003112 <bwrite>
    brelse(from);
    80004390:	854e                	mv	a0,s3
    80004392:	fffff097          	auipc	ra,0xfffff
    80004396:	dbe080e7          	jalr	-578(ra) # 80003150 <brelse>
    brelse(to);
    8000439a:	8526                	mv	a0,s1
    8000439c:	fffff097          	auipc	ra,0xfffff
    800043a0:	db4080e7          	jalr	-588(ra) # 80003150 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043a4:	2905                	addiw	s2,s2,1
    800043a6:	0a91                	addi	s5,s5,4
    800043a8:	02ca2783          	lw	a5,44(s4)
    800043ac:	f8f94ee3          	blt	s2,a5,80004348 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800043b0:	00000097          	auipc	ra,0x0
    800043b4:	c6a080e7          	jalr	-918(ra) # 8000401a <write_head>
    install_trans(0); // Now install writes to home locations
    800043b8:	4501                	li	a0,0
    800043ba:	00000097          	auipc	ra,0x0
    800043be:	cda080e7          	jalr	-806(ra) # 80004094 <install_trans>
    log.lh.n = 0;
    800043c2:	0001d797          	auipc	a5,0x1d
    800043c6:	3607a523          	sw	zero,874(a5) # 8002172c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800043ca:	00000097          	auipc	ra,0x0
    800043ce:	c50080e7          	jalr	-944(ra) # 8000401a <write_head>
    800043d2:	bdf5                	j	800042ce <end_op+0x52>

00000000800043d4 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800043d4:	1101                	addi	sp,sp,-32
    800043d6:	ec06                	sd	ra,24(sp)
    800043d8:	e822                	sd	s0,16(sp)
    800043da:	e426                	sd	s1,8(sp)
    800043dc:	e04a                	sd	s2,0(sp)
    800043de:	1000                	addi	s0,sp,32
    800043e0:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800043e2:	0001d917          	auipc	s2,0x1d
    800043e6:	31e90913          	addi	s2,s2,798 # 80021700 <log>
    800043ea:	854a                	mv	a0,s2
    800043ec:	ffffc097          	auipc	ra,0xffffc
    800043f0:	7fe080e7          	jalr	2046(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800043f4:	02c92603          	lw	a2,44(s2)
    800043f8:	47f5                	li	a5,29
    800043fa:	06c7c563          	blt	a5,a2,80004464 <log_write+0x90>
    800043fe:	0001d797          	auipc	a5,0x1d
    80004402:	31e7a783          	lw	a5,798(a5) # 8002171c <log+0x1c>
    80004406:	37fd                	addiw	a5,a5,-1
    80004408:	04f65e63          	bge	a2,a5,80004464 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000440c:	0001d797          	auipc	a5,0x1d
    80004410:	3147a783          	lw	a5,788(a5) # 80021720 <log+0x20>
    80004414:	06f05063          	blez	a5,80004474 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004418:	4781                	li	a5,0
    8000441a:	06c05563          	blez	a2,80004484 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000441e:	44cc                	lw	a1,12(s1)
    80004420:	0001d717          	auipc	a4,0x1d
    80004424:	31070713          	addi	a4,a4,784 # 80021730 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004428:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000442a:	4314                	lw	a3,0(a4)
    8000442c:	04b68c63          	beq	a3,a1,80004484 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004430:	2785                	addiw	a5,a5,1
    80004432:	0711                	addi	a4,a4,4
    80004434:	fef61be3          	bne	a2,a5,8000442a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004438:	0621                	addi	a2,a2,8
    8000443a:	060a                	slli	a2,a2,0x2
    8000443c:	0001d797          	auipc	a5,0x1d
    80004440:	2c478793          	addi	a5,a5,708 # 80021700 <log>
    80004444:	963e                	add	a2,a2,a5
    80004446:	44dc                	lw	a5,12(s1)
    80004448:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000444a:	8526                	mv	a0,s1
    8000444c:	fffff097          	auipc	ra,0xfffff
    80004450:	da2080e7          	jalr	-606(ra) # 800031ee <bpin>
    log.lh.n++;
    80004454:	0001d717          	auipc	a4,0x1d
    80004458:	2ac70713          	addi	a4,a4,684 # 80021700 <log>
    8000445c:	575c                	lw	a5,44(a4)
    8000445e:	2785                	addiw	a5,a5,1
    80004460:	d75c                	sw	a5,44(a4)
    80004462:	a835                	j	8000449e <log_write+0xca>
    panic("too big a transaction");
    80004464:	00004517          	auipc	a0,0x4
    80004468:	2e450513          	addi	a0,a0,740 # 80008748 <syscalls+0x218>
    8000446c:	ffffc097          	auipc	ra,0xffffc
    80004470:	0d8080e7          	jalr	216(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    80004474:	00004517          	auipc	a0,0x4
    80004478:	2ec50513          	addi	a0,a0,748 # 80008760 <syscalls+0x230>
    8000447c:	ffffc097          	auipc	ra,0xffffc
    80004480:	0c8080e7          	jalr	200(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    80004484:	00878713          	addi	a4,a5,8
    80004488:	00271693          	slli	a3,a4,0x2
    8000448c:	0001d717          	auipc	a4,0x1d
    80004490:	27470713          	addi	a4,a4,628 # 80021700 <log>
    80004494:	9736                	add	a4,a4,a3
    80004496:	44d4                	lw	a3,12(s1)
    80004498:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000449a:	faf608e3          	beq	a2,a5,8000444a <log_write+0x76>
  }
  release(&log.lock);
    8000449e:	0001d517          	auipc	a0,0x1d
    800044a2:	26250513          	addi	a0,a0,610 # 80021700 <log>
    800044a6:	ffffc097          	auipc	ra,0xffffc
    800044aa:	7f8080e7          	jalr	2040(ra) # 80000c9e <release>
}
    800044ae:	60e2                	ld	ra,24(sp)
    800044b0:	6442                	ld	s0,16(sp)
    800044b2:	64a2                	ld	s1,8(sp)
    800044b4:	6902                	ld	s2,0(sp)
    800044b6:	6105                	addi	sp,sp,32
    800044b8:	8082                	ret

00000000800044ba <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800044ba:	1101                	addi	sp,sp,-32
    800044bc:	ec06                	sd	ra,24(sp)
    800044be:	e822                	sd	s0,16(sp)
    800044c0:	e426                	sd	s1,8(sp)
    800044c2:	e04a                	sd	s2,0(sp)
    800044c4:	1000                	addi	s0,sp,32
    800044c6:	84aa                	mv	s1,a0
    800044c8:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800044ca:	00004597          	auipc	a1,0x4
    800044ce:	2b658593          	addi	a1,a1,694 # 80008780 <syscalls+0x250>
    800044d2:	0521                	addi	a0,a0,8
    800044d4:	ffffc097          	auipc	ra,0xffffc
    800044d8:	686080e7          	jalr	1670(ra) # 80000b5a <initlock>
  lk->name = name;
    800044dc:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800044e0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044e4:	0204a423          	sw	zero,40(s1)
}
    800044e8:	60e2                	ld	ra,24(sp)
    800044ea:	6442                	ld	s0,16(sp)
    800044ec:	64a2                	ld	s1,8(sp)
    800044ee:	6902                	ld	s2,0(sp)
    800044f0:	6105                	addi	sp,sp,32
    800044f2:	8082                	ret

00000000800044f4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800044f4:	1101                	addi	sp,sp,-32
    800044f6:	ec06                	sd	ra,24(sp)
    800044f8:	e822                	sd	s0,16(sp)
    800044fa:	e426                	sd	s1,8(sp)
    800044fc:	e04a                	sd	s2,0(sp)
    800044fe:	1000                	addi	s0,sp,32
    80004500:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004502:	00850913          	addi	s2,a0,8
    80004506:	854a                	mv	a0,s2
    80004508:	ffffc097          	auipc	ra,0xffffc
    8000450c:	6e2080e7          	jalr	1762(ra) # 80000bea <acquire>
  while (lk->locked) {
    80004510:	409c                	lw	a5,0(s1)
    80004512:	cb89                	beqz	a5,80004524 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004514:	85ca                	mv	a1,s2
    80004516:	8526                	mv	a0,s1
    80004518:	ffffe097          	auipc	ra,0xffffe
    8000451c:	bb4080e7          	jalr	-1100(ra) # 800020cc <sleep>
  while (lk->locked) {
    80004520:	409c                	lw	a5,0(s1)
    80004522:	fbed                	bnez	a5,80004514 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004524:	4785                	li	a5,1
    80004526:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004528:	ffffd097          	auipc	ra,0xffffd
    8000452c:	49e080e7          	jalr	1182(ra) # 800019c6 <myproc>
    80004530:	591c                	lw	a5,48(a0)
    80004532:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004534:	854a                	mv	a0,s2
    80004536:	ffffc097          	auipc	ra,0xffffc
    8000453a:	768080e7          	jalr	1896(ra) # 80000c9e <release>
}
    8000453e:	60e2                	ld	ra,24(sp)
    80004540:	6442                	ld	s0,16(sp)
    80004542:	64a2                	ld	s1,8(sp)
    80004544:	6902                	ld	s2,0(sp)
    80004546:	6105                	addi	sp,sp,32
    80004548:	8082                	ret

000000008000454a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000454a:	1101                	addi	sp,sp,-32
    8000454c:	ec06                	sd	ra,24(sp)
    8000454e:	e822                	sd	s0,16(sp)
    80004550:	e426                	sd	s1,8(sp)
    80004552:	e04a                	sd	s2,0(sp)
    80004554:	1000                	addi	s0,sp,32
    80004556:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004558:	00850913          	addi	s2,a0,8
    8000455c:	854a                	mv	a0,s2
    8000455e:	ffffc097          	auipc	ra,0xffffc
    80004562:	68c080e7          	jalr	1676(ra) # 80000bea <acquire>
  lk->locked = 0;
    80004566:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000456a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000456e:	8526                	mv	a0,s1
    80004570:	ffffe097          	auipc	ra,0xffffe
    80004574:	bc0080e7          	jalr	-1088(ra) # 80002130 <wakeup>
  release(&lk->lk);
    80004578:	854a                	mv	a0,s2
    8000457a:	ffffc097          	auipc	ra,0xffffc
    8000457e:	724080e7          	jalr	1828(ra) # 80000c9e <release>
}
    80004582:	60e2                	ld	ra,24(sp)
    80004584:	6442                	ld	s0,16(sp)
    80004586:	64a2                	ld	s1,8(sp)
    80004588:	6902                	ld	s2,0(sp)
    8000458a:	6105                	addi	sp,sp,32
    8000458c:	8082                	ret

000000008000458e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000458e:	7179                	addi	sp,sp,-48
    80004590:	f406                	sd	ra,40(sp)
    80004592:	f022                	sd	s0,32(sp)
    80004594:	ec26                	sd	s1,24(sp)
    80004596:	e84a                	sd	s2,16(sp)
    80004598:	e44e                	sd	s3,8(sp)
    8000459a:	1800                	addi	s0,sp,48
    8000459c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000459e:	00850913          	addi	s2,a0,8
    800045a2:	854a                	mv	a0,s2
    800045a4:	ffffc097          	auipc	ra,0xffffc
    800045a8:	646080e7          	jalr	1606(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800045ac:	409c                	lw	a5,0(s1)
    800045ae:	ef99                	bnez	a5,800045cc <holdingsleep+0x3e>
    800045b0:	4481                	li	s1,0
  release(&lk->lk);
    800045b2:	854a                	mv	a0,s2
    800045b4:	ffffc097          	auipc	ra,0xffffc
    800045b8:	6ea080e7          	jalr	1770(ra) # 80000c9e <release>
  return r;
}
    800045bc:	8526                	mv	a0,s1
    800045be:	70a2                	ld	ra,40(sp)
    800045c0:	7402                	ld	s0,32(sp)
    800045c2:	64e2                	ld	s1,24(sp)
    800045c4:	6942                	ld	s2,16(sp)
    800045c6:	69a2                	ld	s3,8(sp)
    800045c8:	6145                	addi	sp,sp,48
    800045ca:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800045cc:	0284a983          	lw	s3,40(s1)
    800045d0:	ffffd097          	auipc	ra,0xffffd
    800045d4:	3f6080e7          	jalr	1014(ra) # 800019c6 <myproc>
    800045d8:	5904                	lw	s1,48(a0)
    800045da:	413484b3          	sub	s1,s1,s3
    800045de:	0014b493          	seqz	s1,s1
    800045e2:	bfc1                	j	800045b2 <holdingsleep+0x24>

00000000800045e4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800045e4:	1141                	addi	sp,sp,-16
    800045e6:	e406                	sd	ra,8(sp)
    800045e8:	e022                	sd	s0,0(sp)
    800045ea:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800045ec:	00004597          	auipc	a1,0x4
    800045f0:	1a458593          	addi	a1,a1,420 # 80008790 <syscalls+0x260>
    800045f4:	0001d517          	auipc	a0,0x1d
    800045f8:	25450513          	addi	a0,a0,596 # 80021848 <ftable>
    800045fc:	ffffc097          	auipc	ra,0xffffc
    80004600:	55e080e7          	jalr	1374(ra) # 80000b5a <initlock>
}
    80004604:	60a2                	ld	ra,8(sp)
    80004606:	6402                	ld	s0,0(sp)
    80004608:	0141                	addi	sp,sp,16
    8000460a:	8082                	ret

000000008000460c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000460c:	1101                	addi	sp,sp,-32
    8000460e:	ec06                	sd	ra,24(sp)
    80004610:	e822                	sd	s0,16(sp)
    80004612:	e426                	sd	s1,8(sp)
    80004614:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004616:	0001d517          	auipc	a0,0x1d
    8000461a:	23250513          	addi	a0,a0,562 # 80021848 <ftable>
    8000461e:	ffffc097          	auipc	ra,0xffffc
    80004622:	5cc080e7          	jalr	1484(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004626:	0001d497          	auipc	s1,0x1d
    8000462a:	23a48493          	addi	s1,s1,570 # 80021860 <ftable+0x18>
    8000462e:	0001e717          	auipc	a4,0x1e
    80004632:	1d270713          	addi	a4,a4,466 # 80022800 <disk>
    if(f->ref == 0){
    80004636:	40dc                	lw	a5,4(s1)
    80004638:	cf99                	beqz	a5,80004656 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000463a:	02848493          	addi	s1,s1,40
    8000463e:	fee49ce3          	bne	s1,a4,80004636 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004642:	0001d517          	auipc	a0,0x1d
    80004646:	20650513          	addi	a0,a0,518 # 80021848 <ftable>
    8000464a:	ffffc097          	auipc	ra,0xffffc
    8000464e:	654080e7          	jalr	1620(ra) # 80000c9e <release>
  return 0;
    80004652:	4481                	li	s1,0
    80004654:	a819                	j	8000466a <filealloc+0x5e>
      f->ref = 1;
    80004656:	4785                	li	a5,1
    80004658:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000465a:	0001d517          	auipc	a0,0x1d
    8000465e:	1ee50513          	addi	a0,a0,494 # 80021848 <ftable>
    80004662:	ffffc097          	auipc	ra,0xffffc
    80004666:	63c080e7          	jalr	1596(ra) # 80000c9e <release>
}
    8000466a:	8526                	mv	a0,s1
    8000466c:	60e2                	ld	ra,24(sp)
    8000466e:	6442                	ld	s0,16(sp)
    80004670:	64a2                	ld	s1,8(sp)
    80004672:	6105                	addi	sp,sp,32
    80004674:	8082                	ret

0000000080004676 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004676:	1101                	addi	sp,sp,-32
    80004678:	ec06                	sd	ra,24(sp)
    8000467a:	e822                	sd	s0,16(sp)
    8000467c:	e426                	sd	s1,8(sp)
    8000467e:	1000                	addi	s0,sp,32
    80004680:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004682:	0001d517          	auipc	a0,0x1d
    80004686:	1c650513          	addi	a0,a0,454 # 80021848 <ftable>
    8000468a:	ffffc097          	auipc	ra,0xffffc
    8000468e:	560080e7          	jalr	1376(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004692:	40dc                	lw	a5,4(s1)
    80004694:	02f05263          	blez	a5,800046b8 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004698:	2785                	addiw	a5,a5,1
    8000469a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000469c:	0001d517          	auipc	a0,0x1d
    800046a0:	1ac50513          	addi	a0,a0,428 # 80021848 <ftable>
    800046a4:	ffffc097          	auipc	ra,0xffffc
    800046a8:	5fa080e7          	jalr	1530(ra) # 80000c9e <release>
  return f;
}
    800046ac:	8526                	mv	a0,s1
    800046ae:	60e2                	ld	ra,24(sp)
    800046b0:	6442                	ld	s0,16(sp)
    800046b2:	64a2                	ld	s1,8(sp)
    800046b4:	6105                	addi	sp,sp,32
    800046b6:	8082                	ret
    panic("filedup");
    800046b8:	00004517          	auipc	a0,0x4
    800046bc:	0e050513          	addi	a0,a0,224 # 80008798 <syscalls+0x268>
    800046c0:	ffffc097          	auipc	ra,0xffffc
    800046c4:	e84080e7          	jalr	-380(ra) # 80000544 <panic>

00000000800046c8 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046c8:	7139                	addi	sp,sp,-64
    800046ca:	fc06                	sd	ra,56(sp)
    800046cc:	f822                	sd	s0,48(sp)
    800046ce:	f426                	sd	s1,40(sp)
    800046d0:	f04a                	sd	s2,32(sp)
    800046d2:	ec4e                	sd	s3,24(sp)
    800046d4:	e852                	sd	s4,16(sp)
    800046d6:	e456                	sd	s5,8(sp)
    800046d8:	0080                	addi	s0,sp,64
    800046da:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800046dc:	0001d517          	auipc	a0,0x1d
    800046e0:	16c50513          	addi	a0,a0,364 # 80021848 <ftable>
    800046e4:	ffffc097          	auipc	ra,0xffffc
    800046e8:	506080e7          	jalr	1286(ra) # 80000bea <acquire>
  if(f->ref < 1)
    800046ec:	40dc                	lw	a5,4(s1)
    800046ee:	06f05163          	blez	a5,80004750 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800046f2:	37fd                	addiw	a5,a5,-1
    800046f4:	0007871b          	sext.w	a4,a5
    800046f8:	c0dc                	sw	a5,4(s1)
    800046fa:	06e04363          	bgtz	a4,80004760 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800046fe:	0004a903          	lw	s2,0(s1)
    80004702:	0094ca83          	lbu	s5,9(s1)
    80004706:	0104ba03          	ld	s4,16(s1)
    8000470a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000470e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004712:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004716:	0001d517          	auipc	a0,0x1d
    8000471a:	13250513          	addi	a0,a0,306 # 80021848 <ftable>
    8000471e:	ffffc097          	auipc	ra,0xffffc
    80004722:	580080e7          	jalr	1408(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    80004726:	4785                	li	a5,1
    80004728:	04f90d63          	beq	s2,a5,80004782 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000472c:	3979                	addiw	s2,s2,-2
    8000472e:	4785                	li	a5,1
    80004730:	0527e063          	bltu	a5,s2,80004770 <fileclose+0xa8>
    begin_op();
    80004734:	00000097          	auipc	ra,0x0
    80004738:	ac8080e7          	jalr	-1336(ra) # 800041fc <begin_op>
    iput(ff.ip);
    8000473c:	854e                	mv	a0,s3
    8000473e:	fffff097          	auipc	ra,0xfffff
    80004742:	2b6080e7          	jalr	694(ra) # 800039f4 <iput>
    end_op();
    80004746:	00000097          	auipc	ra,0x0
    8000474a:	b36080e7          	jalr	-1226(ra) # 8000427c <end_op>
    8000474e:	a00d                	j	80004770 <fileclose+0xa8>
    panic("fileclose");
    80004750:	00004517          	auipc	a0,0x4
    80004754:	05050513          	addi	a0,a0,80 # 800087a0 <syscalls+0x270>
    80004758:	ffffc097          	auipc	ra,0xffffc
    8000475c:	dec080e7          	jalr	-532(ra) # 80000544 <panic>
    release(&ftable.lock);
    80004760:	0001d517          	auipc	a0,0x1d
    80004764:	0e850513          	addi	a0,a0,232 # 80021848 <ftable>
    80004768:	ffffc097          	auipc	ra,0xffffc
    8000476c:	536080e7          	jalr	1334(ra) # 80000c9e <release>
  }
}
    80004770:	70e2                	ld	ra,56(sp)
    80004772:	7442                	ld	s0,48(sp)
    80004774:	74a2                	ld	s1,40(sp)
    80004776:	7902                	ld	s2,32(sp)
    80004778:	69e2                	ld	s3,24(sp)
    8000477a:	6a42                	ld	s4,16(sp)
    8000477c:	6aa2                	ld	s5,8(sp)
    8000477e:	6121                	addi	sp,sp,64
    80004780:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004782:	85d6                	mv	a1,s5
    80004784:	8552                	mv	a0,s4
    80004786:	00000097          	auipc	ra,0x0
    8000478a:	34c080e7          	jalr	844(ra) # 80004ad2 <pipeclose>
    8000478e:	b7cd                	j	80004770 <fileclose+0xa8>

0000000080004790 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004790:	715d                	addi	sp,sp,-80
    80004792:	e486                	sd	ra,72(sp)
    80004794:	e0a2                	sd	s0,64(sp)
    80004796:	fc26                	sd	s1,56(sp)
    80004798:	f84a                	sd	s2,48(sp)
    8000479a:	f44e                	sd	s3,40(sp)
    8000479c:	0880                	addi	s0,sp,80
    8000479e:	84aa                	mv	s1,a0
    800047a0:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800047a2:	ffffd097          	auipc	ra,0xffffd
    800047a6:	224080e7          	jalr	548(ra) # 800019c6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800047aa:	409c                	lw	a5,0(s1)
    800047ac:	37f9                	addiw	a5,a5,-2
    800047ae:	4705                	li	a4,1
    800047b0:	04f76763          	bltu	a4,a5,800047fe <filestat+0x6e>
    800047b4:	892a                	mv	s2,a0
    ilock(f->ip);
    800047b6:	6c88                	ld	a0,24(s1)
    800047b8:	fffff097          	auipc	ra,0xfffff
    800047bc:	082080e7          	jalr	130(ra) # 8000383a <ilock>
    stati(f->ip, &st);
    800047c0:	fb840593          	addi	a1,s0,-72
    800047c4:	6c88                	ld	a0,24(s1)
    800047c6:	fffff097          	auipc	ra,0xfffff
    800047ca:	2fe080e7          	jalr	766(ra) # 80003ac4 <stati>
    iunlock(f->ip);
    800047ce:	6c88                	ld	a0,24(s1)
    800047d0:	fffff097          	auipc	ra,0xfffff
    800047d4:	12c080e7          	jalr	300(ra) # 800038fc <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800047d8:	46e1                	li	a3,24
    800047da:	fb840613          	addi	a2,s0,-72
    800047de:	85ce                	mv	a1,s3
    800047e0:	05093503          	ld	a0,80(s2)
    800047e4:	ffffd097          	auipc	ra,0xffffd
    800047e8:	ea0080e7          	jalr	-352(ra) # 80001684 <copyout>
    800047ec:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800047f0:	60a6                	ld	ra,72(sp)
    800047f2:	6406                	ld	s0,64(sp)
    800047f4:	74e2                	ld	s1,56(sp)
    800047f6:	7942                	ld	s2,48(sp)
    800047f8:	79a2                	ld	s3,40(sp)
    800047fa:	6161                	addi	sp,sp,80
    800047fc:	8082                	ret
  return -1;
    800047fe:	557d                	li	a0,-1
    80004800:	bfc5                	j	800047f0 <filestat+0x60>

0000000080004802 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004802:	7179                	addi	sp,sp,-48
    80004804:	f406                	sd	ra,40(sp)
    80004806:	f022                	sd	s0,32(sp)
    80004808:	ec26                	sd	s1,24(sp)
    8000480a:	e84a                	sd	s2,16(sp)
    8000480c:	e44e                	sd	s3,8(sp)
    8000480e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004810:	00854783          	lbu	a5,8(a0)
    80004814:	c3d5                	beqz	a5,800048b8 <fileread+0xb6>
    80004816:	84aa                	mv	s1,a0
    80004818:	89ae                	mv	s3,a1
    8000481a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000481c:	411c                	lw	a5,0(a0)
    8000481e:	4705                	li	a4,1
    80004820:	04e78963          	beq	a5,a4,80004872 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004824:	470d                	li	a4,3
    80004826:	04e78d63          	beq	a5,a4,80004880 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000482a:	4709                	li	a4,2
    8000482c:	06e79e63          	bne	a5,a4,800048a8 <fileread+0xa6>
    ilock(f->ip);
    80004830:	6d08                	ld	a0,24(a0)
    80004832:	fffff097          	auipc	ra,0xfffff
    80004836:	008080e7          	jalr	8(ra) # 8000383a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000483a:	874a                	mv	a4,s2
    8000483c:	5094                	lw	a3,32(s1)
    8000483e:	864e                	mv	a2,s3
    80004840:	4585                	li	a1,1
    80004842:	6c88                	ld	a0,24(s1)
    80004844:	fffff097          	auipc	ra,0xfffff
    80004848:	2aa080e7          	jalr	682(ra) # 80003aee <readi>
    8000484c:	892a                	mv	s2,a0
    8000484e:	00a05563          	blez	a0,80004858 <fileread+0x56>
      f->off += r;
    80004852:	509c                	lw	a5,32(s1)
    80004854:	9fa9                	addw	a5,a5,a0
    80004856:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004858:	6c88                	ld	a0,24(s1)
    8000485a:	fffff097          	auipc	ra,0xfffff
    8000485e:	0a2080e7          	jalr	162(ra) # 800038fc <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004862:	854a                	mv	a0,s2
    80004864:	70a2                	ld	ra,40(sp)
    80004866:	7402                	ld	s0,32(sp)
    80004868:	64e2                	ld	s1,24(sp)
    8000486a:	6942                	ld	s2,16(sp)
    8000486c:	69a2                	ld	s3,8(sp)
    8000486e:	6145                	addi	sp,sp,48
    80004870:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004872:	6908                	ld	a0,16(a0)
    80004874:	00000097          	auipc	ra,0x0
    80004878:	3ce080e7          	jalr	974(ra) # 80004c42 <piperead>
    8000487c:	892a                	mv	s2,a0
    8000487e:	b7d5                	j	80004862 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004880:	02451783          	lh	a5,36(a0)
    80004884:	03079693          	slli	a3,a5,0x30
    80004888:	92c1                	srli	a3,a3,0x30
    8000488a:	4725                	li	a4,9
    8000488c:	02d76863          	bltu	a4,a3,800048bc <fileread+0xba>
    80004890:	0792                	slli	a5,a5,0x4
    80004892:	0001d717          	auipc	a4,0x1d
    80004896:	f1670713          	addi	a4,a4,-234 # 800217a8 <devsw>
    8000489a:	97ba                	add	a5,a5,a4
    8000489c:	639c                	ld	a5,0(a5)
    8000489e:	c38d                	beqz	a5,800048c0 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800048a0:	4505                	li	a0,1
    800048a2:	9782                	jalr	a5
    800048a4:	892a                	mv	s2,a0
    800048a6:	bf75                	j	80004862 <fileread+0x60>
    panic("fileread");
    800048a8:	00004517          	auipc	a0,0x4
    800048ac:	f0850513          	addi	a0,a0,-248 # 800087b0 <syscalls+0x280>
    800048b0:	ffffc097          	auipc	ra,0xffffc
    800048b4:	c94080e7          	jalr	-876(ra) # 80000544 <panic>
    return -1;
    800048b8:	597d                	li	s2,-1
    800048ba:	b765                	j	80004862 <fileread+0x60>
      return -1;
    800048bc:	597d                	li	s2,-1
    800048be:	b755                	j	80004862 <fileread+0x60>
    800048c0:	597d                	li	s2,-1
    800048c2:	b745                	j	80004862 <fileread+0x60>

00000000800048c4 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800048c4:	715d                	addi	sp,sp,-80
    800048c6:	e486                	sd	ra,72(sp)
    800048c8:	e0a2                	sd	s0,64(sp)
    800048ca:	fc26                	sd	s1,56(sp)
    800048cc:	f84a                	sd	s2,48(sp)
    800048ce:	f44e                	sd	s3,40(sp)
    800048d0:	f052                	sd	s4,32(sp)
    800048d2:	ec56                	sd	s5,24(sp)
    800048d4:	e85a                	sd	s6,16(sp)
    800048d6:	e45e                	sd	s7,8(sp)
    800048d8:	e062                	sd	s8,0(sp)
    800048da:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800048dc:	00954783          	lbu	a5,9(a0)
    800048e0:	10078663          	beqz	a5,800049ec <filewrite+0x128>
    800048e4:	892a                	mv	s2,a0
    800048e6:	8aae                	mv	s5,a1
    800048e8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800048ea:	411c                	lw	a5,0(a0)
    800048ec:	4705                	li	a4,1
    800048ee:	02e78263          	beq	a5,a4,80004912 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048f2:	470d                	li	a4,3
    800048f4:	02e78663          	beq	a5,a4,80004920 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800048f8:	4709                	li	a4,2
    800048fa:	0ee79163          	bne	a5,a4,800049dc <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800048fe:	0ac05d63          	blez	a2,800049b8 <filewrite+0xf4>
    int i = 0;
    80004902:	4981                	li	s3,0
    80004904:	6b05                	lui	s6,0x1
    80004906:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000490a:	6b85                	lui	s7,0x1
    8000490c:	c00b8b9b          	addiw	s7,s7,-1024
    80004910:	a861                	j	800049a8 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004912:	6908                	ld	a0,16(a0)
    80004914:	00000097          	auipc	ra,0x0
    80004918:	22e080e7          	jalr	558(ra) # 80004b42 <pipewrite>
    8000491c:	8a2a                	mv	s4,a0
    8000491e:	a045                	j	800049be <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004920:	02451783          	lh	a5,36(a0)
    80004924:	03079693          	slli	a3,a5,0x30
    80004928:	92c1                	srli	a3,a3,0x30
    8000492a:	4725                	li	a4,9
    8000492c:	0cd76263          	bltu	a4,a3,800049f0 <filewrite+0x12c>
    80004930:	0792                	slli	a5,a5,0x4
    80004932:	0001d717          	auipc	a4,0x1d
    80004936:	e7670713          	addi	a4,a4,-394 # 800217a8 <devsw>
    8000493a:	97ba                	add	a5,a5,a4
    8000493c:	679c                	ld	a5,8(a5)
    8000493e:	cbdd                	beqz	a5,800049f4 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004940:	4505                	li	a0,1
    80004942:	9782                	jalr	a5
    80004944:	8a2a                	mv	s4,a0
    80004946:	a8a5                	j	800049be <filewrite+0xfa>
    80004948:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000494c:	00000097          	auipc	ra,0x0
    80004950:	8b0080e7          	jalr	-1872(ra) # 800041fc <begin_op>
      ilock(f->ip);
    80004954:	01893503          	ld	a0,24(s2)
    80004958:	fffff097          	auipc	ra,0xfffff
    8000495c:	ee2080e7          	jalr	-286(ra) # 8000383a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004960:	8762                	mv	a4,s8
    80004962:	02092683          	lw	a3,32(s2)
    80004966:	01598633          	add	a2,s3,s5
    8000496a:	4585                	li	a1,1
    8000496c:	01893503          	ld	a0,24(s2)
    80004970:	fffff097          	auipc	ra,0xfffff
    80004974:	276080e7          	jalr	630(ra) # 80003be6 <writei>
    80004978:	84aa                	mv	s1,a0
    8000497a:	00a05763          	blez	a0,80004988 <filewrite+0xc4>
        f->off += r;
    8000497e:	02092783          	lw	a5,32(s2)
    80004982:	9fa9                	addw	a5,a5,a0
    80004984:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004988:	01893503          	ld	a0,24(s2)
    8000498c:	fffff097          	auipc	ra,0xfffff
    80004990:	f70080e7          	jalr	-144(ra) # 800038fc <iunlock>
      end_op();
    80004994:	00000097          	auipc	ra,0x0
    80004998:	8e8080e7          	jalr	-1816(ra) # 8000427c <end_op>

      if(r != n1){
    8000499c:	009c1f63          	bne	s8,s1,800049ba <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800049a0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800049a4:	0149db63          	bge	s3,s4,800049ba <filewrite+0xf6>
      int n1 = n - i;
    800049a8:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800049ac:	84be                	mv	s1,a5
    800049ae:	2781                	sext.w	a5,a5
    800049b0:	f8fb5ce3          	bge	s6,a5,80004948 <filewrite+0x84>
    800049b4:	84de                	mv	s1,s7
    800049b6:	bf49                	j	80004948 <filewrite+0x84>
    int i = 0;
    800049b8:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800049ba:	013a1f63          	bne	s4,s3,800049d8 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800049be:	8552                	mv	a0,s4
    800049c0:	60a6                	ld	ra,72(sp)
    800049c2:	6406                	ld	s0,64(sp)
    800049c4:	74e2                	ld	s1,56(sp)
    800049c6:	7942                	ld	s2,48(sp)
    800049c8:	79a2                	ld	s3,40(sp)
    800049ca:	7a02                	ld	s4,32(sp)
    800049cc:	6ae2                	ld	s5,24(sp)
    800049ce:	6b42                	ld	s6,16(sp)
    800049d0:	6ba2                	ld	s7,8(sp)
    800049d2:	6c02                	ld	s8,0(sp)
    800049d4:	6161                	addi	sp,sp,80
    800049d6:	8082                	ret
    ret = (i == n ? n : -1);
    800049d8:	5a7d                	li	s4,-1
    800049da:	b7d5                	j	800049be <filewrite+0xfa>
    panic("filewrite");
    800049dc:	00004517          	auipc	a0,0x4
    800049e0:	de450513          	addi	a0,a0,-540 # 800087c0 <syscalls+0x290>
    800049e4:	ffffc097          	auipc	ra,0xffffc
    800049e8:	b60080e7          	jalr	-1184(ra) # 80000544 <panic>
    return -1;
    800049ec:	5a7d                	li	s4,-1
    800049ee:	bfc1                	j	800049be <filewrite+0xfa>
      return -1;
    800049f0:	5a7d                	li	s4,-1
    800049f2:	b7f1                	j	800049be <filewrite+0xfa>
    800049f4:	5a7d                	li	s4,-1
    800049f6:	b7e1                	j	800049be <filewrite+0xfa>

00000000800049f8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800049f8:	7179                	addi	sp,sp,-48
    800049fa:	f406                	sd	ra,40(sp)
    800049fc:	f022                	sd	s0,32(sp)
    800049fe:	ec26                	sd	s1,24(sp)
    80004a00:	e84a                	sd	s2,16(sp)
    80004a02:	e44e                	sd	s3,8(sp)
    80004a04:	e052                	sd	s4,0(sp)
    80004a06:	1800                	addi	s0,sp,48
    80004a08:	84aa                	mv	s1,a0
    80004a0a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a0c:	0005b023          	sd	zero,0(a1)
    80004a10:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a14:	00000097          	auipc	ra,0x0
    80004a18:	bf8080e7          	jalr	-1032(ra) # 8000460c <filealloc>
    80004a1c:	e088                	sd	a0,0(s1)
    80004a1e:	c551                	beqz	a0,80004aaa <pipealloc+0xb2>
    80004a20:	00000097          	auipc	ra,0x0
    80004a24:	bec080e7          	jalr	-1044(ra) # 8000460c <filealloc>
    80004a28:	00aa3023          	sd	a0,0(s4)
    80004a2c:	c92d                	beqz	a0,80004a9e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a2e:	ffffc097          	auipc	ra,0xffffc
    80004a32:	0cc080e7          	jalr	204(ra) # 80000afa <kalloc>
    80004a36:	892a                	mv	s2,a0
    80004a38:	c125                	beqz	a0,80004a98 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a3a:	4985                	li	s3,1
    80004a3c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a40:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a44:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a48:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a4c:	00004597          	auipc	a1,0x4
    80004a50:	a1c58593          	addi	a1,a1,-1508 # 80008468 <states.1741+0x1a0>
    80004a54:	ffffc097          	auipc	ra,0xffffc
    80004a58:	106080e7          	jalr	262(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    80004a5c:	609c                	ld	a5,0(s1)
    80004a5e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a62:	609c                	ld	a5,0(s1)
    80004a64:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a68:	609c                	ld	a5,0(s1)
    80004a6a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a6e:	609c                	ld	a5,0(s1)
    80004a70:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a74:	000a3783          	ld	a5,0(s4)
    80004a78:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a7c:	000a3783          	ld	a5,0(s4)
    80004a80:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a84:	000a3783          	ld	a5,0(s4)
    80004a88:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a8c:	000a3783          	ld	a5,0(s4)
    80004a90:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a94:	4501                	li	a0,0
    80004a96:	a025                	j	80004abe <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a98:	6088                	ld	a0,0(s1)
    80004a9a:	e501                	bnez	a0,80004aa2 <pipealloc+0xaa>
    80004a9c:	a039                	j	80004aaa <pipealloc+0xb2>
    80004a9e:	6088                	ld	a0,0(s1)
    80004aa0:	c51d                	beqz	a0,80004ace <pipealloc+0xd6>
    fileclose(*f0);
    80004aa2:	00000097          	auipc	ra,0x0
    80004aa6:	c26080e7          	jalr	-986(ra) # 800046c8 <fileclose>
  if(*f1)
    80004aaa:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004aae:	557d                	li	a0,-1
  if(*f1)
    80004ab0:	c799                	beqz	a5,80004abe <pipealloc+0xc6>
    fileclose(*f1);
    80004ab2:	853e                	mv	a0,a5
    80004ab4:	00000097          	auipc	ra,0x0
    80004ab8:	c14080e7          	jalr	-1004(ra) # 800046c8 <fileclose>
  return -1;
    80004abc:	557d                	li	a0,-1
}
    80004abe:	70a2                	ld	ra,40(sp)
    80004ac0:	7402                	ld	s0,32(sp)
    80004ac2:	64e2                	ld	s1,24(sp)
    80004ac4:	6942                	ld	s2,16(sp)
    80004ac6:	69a2                	ld	s3,8(sp)
    80004ac8:	6a02                	ld	s4,0(sp)
    80004aca:	6145                	addi	sp,sp,48
    80004acc:	8082                	ret
  return -1;
    80004ace:	557d                	li	a0,-1
    80004ad0:	b7fd                	j	80004abe <pipealloc+0xc6>

0000000080004ad2 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ad2:	1101                	addi	sp,sp,-32
    80004ad4:	ec06                	sd	ra,24(sp)
    80004ad6:	e822                	sd	s0,16(sp)
    80004ad8:	e426                	sd	s1,8(sp)
    80004ada:	e04a                	sd	s2,0(sp)
    80004adc:	1000                	addi	s0,sp,32
    80004ade:	84aa                	mv	s1,a0
    80004ae0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004ae2:	ffffc097          	auipc	ra,0xffffc
    80004ae6:	108080e7          	jalr	264(ra) # 80000bea <acquire>
  if(writable){
    80004aea:	02090d63          	beqz	s2,80004b24 <pipeclose+0x52>
    pi->writeopen = 0;
    80004aee:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004af2:	21848513          	addi	a0,s1,536
    80004af6:	ffffd097          	auipc	ra,0xffffd
    80004afa:	63a080e7          	jalr	1594(ra) # 80002130 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004afe:	2204b783          	ld	a5,544(s1)
    80004b02:	eb95                	bnez	a5,80004b36 <pipeclose+0x64>
    release(&pi->lock);
    80004b04:	8526                	mv	a0,s1
    80004b06:	ffffc097          	auipc	ra,0xffffc
    80004b0a:	198080e7          	jalr	408(ra) # 80000c9e <release>
    kfree((char*)pi);
    80004b0e:	8526                	mv	a0,s1
    80004b10:	ffffc097          	auipc	ra,0xffffc
    80004b14:	eee080e7          	jalr	-274(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80004b18:	60e2                	ld	ra,24(sp)
    80004b1a:	6442                	ld	s0,16(sp)
    80004b1c:	64a2                	ld	s1,8(sp)
    80004b1e:	6902                	ld	s2,0(sp)
    80004b20:	6105                	addi	sp,sp,32
    80004b22:	8082                	ret
    pi->readopen = 0;
    80004b24:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b28:	21c48513          	addi	a0,s1,540
    80004b2c:	ffffd097          	auipc	ra,0xffffd
    80004b30:	604080e7          	jalr	1540(ra) # 80002130 <wakeup>
    80004b34:	b7e9                	j	80004afe <pipeclose+0x2c>
    release(&pi->lock);
    80004b36:	8526                	mv	a0,s1
    80004b38:	ffffc097          	auipc	ra,0xffffc
    80004b3c:	166080e7          	jalr	358(ra) # 80000c9e <release>
}
    80004b40:	bfe1                	j	80004b18 <pipeclose+0x46>

0000000080004b42 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b42:	7159                	addi	sp,sp,-112
    80004b44:	f486                	sd	ra,104(sp)
    80004b46:	f0a2                	sd	s0,96(sp)
    80004b48:	eca6                	sd	s1,88(sp)
    80004b4a:	e8ca                	sd	s2,80(sp)
    80004b4c:	e4ce                	sd	s3,72(sp)
    80004b4e:	e0d2                	sd	s4,64(sp)
    80004b50:	fc56                	sd	s5,56(sp)
    80004b52:	f85a                	sd	s6,48(sp)
    80004b54:	f45e                	sd	s7,40(sp)
    80004b56:	f062                	sd	s8,32(sp)
    80004b58:	ec66                	sd	s9,24(sp)
    80004b5a:	1880                	addi	s0,sp,112
    80004b5c:	84aa                	mv	s1,a0
    80004b5e:	8aae                	mv	s5,a1
    80004b60:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b62:	ffffd097          	auipc	ra,0xffffd
    80004b66:	e64080e7          	jalr	-412(ra) # 800019c6 <myproc>
    80004b6a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b6c:	8526                	mv	a0,s1
    80004b6e:	ffffc097          	auipc	ra,0xffffc
    80004b72:	07c080e7          	jalr	124(ra) # 80000bea <acquire>
  while(i < n){
    80004b76:	0d405463          	blez	s4,80004c3e <pipewrite+0xfc>
    80004b7a:	8ba6                	mv	s7,s1
  int i = 0;
    80004b7c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b7e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b80:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b84:	21c48c13          	addi	s8,s1,540
    80004b88:	a08d                	j	80004bea <pipewrite+0xa8>
      release(&pi->lock);
    80004b8a:	8526                	mv	a0,s1
    80004b8c:	ffffc097          	auipc	ra,0xffffc
    80004b90:	112080e7          	jalr	274(ra) # 80000c9e <release>
      return -1;
    80004b94:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b96:	854a                	mv	a0,s2
    80004b98:	70a6                	ld	ra,104(sp)
    80004b9a:	7406                	ld	s0,96(sp)
    80004b9c:	64e6                	ld	s1,88(sp)
    80004b9e:	6946                	ld	s2,80(sp)
    80004ba0:	69a6                	ld	s3,72(sp)
    80004ba2:	6a06                	ld	s4,64(sp)
    80004ba4:	7ae2                	ld	s5,56(sp)
    80004ba6:	7b42                	ld	s6,48(sp)
    80004ba8:	7ba2                	ld	s7,40(sp)
    80004baa:	7c02                	ld	s8,32(sp)
    80004bac:	6ce2                	ld	s9,24(sp)
    80004bae:	6165                	addi	sp,sp,112
    80004bb0:	8082                	ret
      wakeup(&pi->nread);
    80004bb2:	8566                	mv	a0,s9
    80004bb4:	ffffd097          	auipc	ra,0xffffd
    80004bb8:	57c080e7          	jalr	1404(ra) # 80002130 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004bbc:	85de                	mv	a1,s7
    80004bbe:	8562                	mv	a0,s8
    80004bc0:	ffffd097          	auipc	ra,0xffffd
    80004bc4:	50c080e7          	jalr	1292(ra) # 800020cc <sleep>
    80004bc8:	a839                	j	80004be6 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004bca:	21c4a783          	lw	a5,540(s1)
    80004bce:	0017871b          	addiw	a4,a5,1
    80004bd2:	20e4ae23          	sw	a4,540(s1)
    80004bd6:	1ff7f793          	andi	a5,a5,511
    80004bda:	97a6                	add	a5,a5,s1
    80004bdc:	f9f44703          	lbu	a4,-97(s0)
    80004be0:	00e78c23          	sb	a4,24(a5)
      i++;
    80004be4:	2905                	addiw	s2,s2,1
  while(i < n){
    80004be6:	05495063          	bge	s2,s4,80004c26 <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80004bea:	2204a783          	lw	a5,544(s1)
    80004bee:	dfd1                	beqz	a5,80004b8a <pipewrite+0x48>
    80004bf0:	854e                	mv	a0,s3
    80004bf2:	ffffd097          	auipc	ra,0xffffd
    80004bf6:	782080e7          	jalr	1922(ra) # 80002374 <killed>
    80004bfa:	f941                	bnez	a0,80004b8a <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004bfc:	2184a783          	lw	a5,536(s1)
    80004c00:	21c4a703          	lw	a4,540(s1)
    80004c04:	2007879b          	addiw	a5,a5,512
    80004c08:	faf705e3          	beq	a4,a5,80004bb2 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c0c:	4685                	li	a3,1
    80004c0e:	01590633          	add	a2,s2,s5
    80004c12:	f9f40593          	addi	a1,s0,-97
    80004c16:	0509b503          	ld	a0,80(s3)
    80004c1a:	ffffd097          	auipc	ra,0xffffd
    80004c1e:	af6080e7          	jalr	-1290(ra) # 80001710 <copyin>
    80004c22:	fb6514e3          	bne	a0,s6,80004bca <pipewrite+0x88>
  wakeup(&pi->nread);
    80004c26:	21848513          	addi	a0,s1,536
    80004c2a:	ffffd097          	auipc	ra,0xffffd
    80004c2e:	506080e7          	jalr	1286(ra) # 80002130 <wakeup>
  release(&pi->lock);
    80004c32:	8526                	mv	a0,s1
    80004c34:	ffffc097          	auipc	ra,0xffffc
    80004c38:	06a080e7          	jalr	106(ra) # 80000c9e <release>
  return i;
    80004c3c:	bfa9                	j	80004b96 <pipewrite+0x54>
  int i = 0;
    80004c3e:	4901                	li	s2,0
    80004c40:	b7dd                	j	80004c26 <pipewrite+0xe4>

0000000080004c42 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c42:	715d                	addi	sp,sp,-80
    80004c44:	e486                	sd	ra,72(sp)
    80004c46:	e0a2                	sd	s0,64(sp)
    80004c48:	fc26                	sd	s1,56(sp)
    80004c4a:	f84a                	sd	s2,48(sp)
    80004c4c:	f44e                	sd	s3,40(sp)
    80004c4e:	f052                	sd	s4,32(sp)
    80004c50:	ec56                	sd	s5,24(sp)
    80004c52:	e85a                	sd	s6,16(sp)
    80004c54:	0880                	addi	s0,sp,80
    80004c56:	84aa                	mv	s1,a0
    80004c58:	892e                	mv	s2,a1
    80004c5a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c5c:	ffffd097          	auipc	ra,0xffffd
    80004c60:	d6a080e7          	jalr	-662(ra) # 800019c6 <myproc>
    80004c64:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c66:	8b26                	mv	s6,s1
    80004c68:	8526                	mv	a0,s1
    80004c6a:	ffffc097          	auipc	ra,0xffffc
    80004c6e:	f80080e7          	jalr	-128(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c72:	2184a703          	lw	a4,536(s1)
    80004c76:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c7a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c7e:	02f71763          	bne	a4,a5,80004cac <piperead+0x6a>
    80004c82:	2244a783          	lw	a5,548(s1)
    80004c86:	c39d                	beqz	a5,80004cac <piperead+0x6a>
    if(killed(pr)){
    80004c88:	8552                	mv	a0,s4
    80004c8a:	ffffd097          	auipc	ra,0xffffd
    80004c8e:	6ea080e7          	jalr	1770(ra) # 80002374 <killed>
    80004c92:	e941                	bnez	a0,80004d22 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c94:	85da                	mv	a1,s6
    80004c96:	854e                	mv	a0,s3
    80004c98:	ffffd097          	auipc	ra,0xffffd
    80004c9c:	434080e7          	jalr	1076(ra) # 800020cc <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ca0:	2184a703          	lw	a4,536(s1)
    80004ca4:	21c4a783          	lw	a5,540(s1)
    80004ca8:	fcf70de3          	beq	a4,a5,80004c82 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cac:	09505263          	blez	s5,80004d30 <piperead+0xee>
    80004cb0:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cb2:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004cb4:	2184a783          	lw	a5,536(s1)
    80004cb8:	21c4a703          	lw	a4,540(s1)
    80004cbc:	02f70d63          	beq	a4,a5,80004cf6 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004cc0:	0017871b          	addiw	a4,a5,1
    80004cc4:	20e4ac23          	sw	a4,536(s1)
    80004cc8:	1ff7f793          	andi	a5,a5,511
    80004ccc:	97a6                	add	a5,a5,s1
    80004cce:	0187c783          	lbu	a5,24(a5)
    80004cd2:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cd6:	4685                	li	a3,1
    80004cd8:	fbf40613          	addi	a2,s0,-65
    80004cdc:	85ca                	mv	a1,s2
    80004cde:	050a3503          	ld	a0,80(s4)
    80004ce2:	ffffd097          	auipc	ra,0xffffd
    80004ce6:	9a2080e7          	jalr	-1630(ra) # 80001684 <copyout>
    80004cea:	01650663          	beq	a0,s6,80004cf6 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cee:	2985                	addiw	s3,s3,1
    80004cf0:	0905                	addi	s2,s2,1
    80004cf2:	fd3a91e3          	bne	s5,s3,80004cb4 <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004cf6:	21c48513          	addi	a0,s1,540
    80004cfa:	ffffd097          	auipc	ra,0xffffd
    80004cfe:	436080e7          	jalr	1078(ra) # 80002130 <wakeup>
  release(&pi->lock);
    80004d02:	8526                	mv	a0,s1
    80004d04:	ffffc097          	auipc	ra,0xffffc
    80004d08:	f9a080e7          	jalr	-102(ra) # 80000c9e <release>
  return i;
}
    80004d0c:	854e                	mv	a0,s3
    80004d0e:	60a6                	ld	ra,72(sp)
    80004d10:	6406                	ld	s0,64(sp)
    80004d12:	74e2                	ld	s1,56(sp)
    80004d14:	7942                	ld	s2,48(sp)
    80004d16:	79a2                	ld	s3,40(sp)
    80004d18:	7a02                	ld	s4,32(sp)
    80004d1a:	6ae2                	ld	s5,24(sp)
    80004d1c:	6b42                	ld	s6,16(sp)
    80004d1e:	6161                	addi	sp,sp,80
    80004d20:	8082                	ret
      release(&pi->lock);
    80004d22:	8526                	mv	a0,s1
    80004d24:	ffffc097          	auipc	ra,0xffffc
    80004d28:	f7a080e7          	jalr	-134(ra) # 80000c9e <release>
      return -1;
    80004d2c:	59fd                	li	s3,-1
    80004d2e:	bff9                	j	80004d0c <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d30:	4981                	li	s3,0
    80004d32:	b7d1                	j	80004cf6 <piperead+0xb4>

0000000080004d34 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004d34:	1141                	addi	sp,sp,-16
    80004d36:	e422                	sd	s0,8(sp)
    80004d38:	0800                	addi	s0,sp,16
    80004d3a:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004d3c:	8905                	andi	a0,a0,1
    80004d3e:	c111                	beqz	a0,80004d42 <flags2perm+0xe>
      perm = PTE_X;
    80004d40:	4521                	li	a0,8
    if(flags & 0x2)
    80004d42:	8b89                	andi	a5,a5,2
    80004d44:	c399                	beqz	a5,80004d4a <flags2perm+0x16>
      perm |= PTE_W;
    80004d46:	00456513          	ori	a0,a0,4
    return perm;
}
    80004d4a:	6422                	ld	s0,8(sp)
    80004d4c:	0141                	addi	sp,sp,16
    80004d4e:	8082                	ret

0000000080004d50 <exec>:

int
exec(char *path, char **argv)
{
    80004d50:	df010113          	addi	sp,sp,-528
    80004d54:	20113423          	sd	ra,520(sp)
    80004d58:	20813023          	sd	s0,512(sp)
    80004d5c:	ffa6                	sd	s1,504(sp)
    80004d5e:	fbca                	sd	s2,496(sp)
    80004d60:	f7ce                	sd	s3,488(sp)
    80004d62:	f3d2                	sd	s4,480(sp)
    80004d64:	efd6                	sd	s5,472(sp)
    80004d66:	ebda                	sd	s6,464(sp)
    80004d68:	e7de                	sd	s7,456(sp)
    80004d6a:	e3e2                	sd	s8,448(sp)
    80004d6c:	ff66                	sd	s9,440(sp)
    80004d6e:	fb6a                	sd	s10,432(sp)
    80004d70:	f76e                	sd	s11,424(sp)
    80004d72:	0c00                	addi	s0,sp,528
    80004d74:	84aa                	mv	s1,a0
    80004d76:	dea43c23          	sd	a0,-520(s0)
    80004d7a:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d7e:	ffffd097          	auipc	ra,0xffffd
    80004d82:	c48080e7          	jalr	-952(ra) # 800019c6 <myproc>
    80004d86:	892a                	mv	s2,a0

  begin_op();
    80004d88:	fffff097          	auipc	ra,0xfffff
    80004d8c:	474080e7          	jalr	1140(ra) # 800041fc <begin_op>

  if((ip = namei(path)) == 0){
    80004d90:	8526                	mv	a0,s1
    80004d92:	fffff097          	auipc	ra,0xfffff
    80004d96:	24e080e7          	jalr	590(ra) # 80003fe0 <namei>
    80004d9a:	c92d                	beqz	a0,80004e0c <exec+0xbc>
    80004d9c:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d9e:	fffff097          	auipc	ra,0xfffff
    80004da2:	a9c080e7          	jalr	-1380(ra) # 8000383a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004da6:	04000713          	li	a4,64
    80004daa:	4681                	li	a3,0
    80004dac:	e5040613          	addi	a2,s0,-432
    80004db0:	4581                	li	a1,0
    80004db2:	8526                	mv	a0,s1
    80004db4:	fffff097          	auipc	ra,0xfffff
    80004db8:	d3a080e7          	jalr	-710(ra) # 80003aee <readi>
    80004dbc:	04000793          	li	a5,64
    80004dc0:	00f51a63          	bne	a0,a5,80004dd4 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004dc4:	e5042703          	lw	a4,-432(s0)
    80004dc8:	464c47b7          	lui	a5,0x464c4
    80004dcc:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004dd0:	04f70463          	beq	a4,a5,80004e18 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004dd4:	8526                	mv	a0,s1
    80004dd6:	fffff097          	auipc	ra,0xfffff
    80004dda:	cc6080e7          	jalr	-826(ra) # 80003a9c <iunlockput>
    end_op();
    80004dde:	fffff097          	auipc	ra,0xfffff
    80004de2:	49e080e7          	jalr	1182(ra) # 8000427c <end_op>
  }
  return -1;
    80004de6:	557d                	li	a0,-1
}
    80004de8:	20813083          	ld	ra,520(sp)
    80004dec:	20013403          	ld	s0,512(sp)
    80004df0:	74fe                	ld	s1,504(sp)
    80004df2:	795e                	ld	s2,496(sp)
    80004df4:	79be                	ld	s3,488(sp)
    80004df6:	7a1e                	ld	s4,480(sp)
    80004df8:	6afe                	ld	s5,472(sp)
    80004dfa:	6b5e                	ld	s6,464(sp)
    80004dfc:	6bbe                	ld	s7,456(sp)
    80004dfe:	6c1e                	ld	s8,448(sp)
    80004e00:	7cfa                	ld	s9,440(sp)
    80004e02:	7d5a                	ld	s10,432(sp)
    80004e04:	7dba                	ld	s11,424(sp)
    80004e06:	21010113          	addi	sp,sp,528
    80004e0a:	8082                	ret
    end_op();
    80004e0c:	fffff097          	auipc	ra,0xfffff
    80004e10:	470080e7          	jalr	1136(ra) # 8000427c <end_op>
    return -1;
    80004e14:	557d                	li	a0,-1
    80004e16:	bfc9                	j	80004de8 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e18:	854a                	mv	a0,s2
    80004e1a:	ffffd097          	auipc	ra,0xffffd
    80004e1e:	c70080e7          	jalr	-912(ra) # 80001a8a <proc_pagetable>
    80004e22:	8baa                	mv	s7,a0
    80004e24:	d945                	beqz	a0,80004dd4 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e26:	e7042983          	lw	s3,-400(s0)
    80004e2a:	e8845783          	lhu	a5,-376(s0)
    80004e2e:	c7ad                	beqz	a5,80004e98 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e30:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e32:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004e34:	6c85                	lui	s9,0x1
    80004e36:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004e3a:	def43823          	sd	a5,-528(s0)
    80004e3e:	ac0d                	j	80005070 <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e40:	00004517          	auipc	a0,0x4
    80004e44:	99050513          	addi	a0,a0,-1648 # 800087d0 <syscalls+0x2a0>
    80004e48:	ffffb097          	auipc	ra,0xffffb
    80004e4c:	6fc080e7          	jalr	1788(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e50:	8756                	mv	a4,s5
    80004e52:	012d86bb          	addw	a3,s11,s2
    80004e56:	4581                	li	a1,0
    80004e58:	8526                	mv	a0,s1
    80004e5a:	fffff097          	auipc	ra,0xfffff
    80004e5e:	c94080e7          	jalr	-876(ra) # 80003aee <readi>
    80004e62:	2501                	sext.w	a0,a0
    80004e64:	1aaa9a63          	bne	s5,a0,80005018 <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    80004e68:	6785                	lui	a5,0x1
    80004e6a:	0127893b          	addw	s2,a5,s2
    80004e6e:	77fd                	lui	a5,0xfffff
    80004e70:	01478a3b          	addw	s4,a5,s4
    80004e74:	1f897563          	bgeu	s2,s8,8000505e <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    80004e78:	02091593          	slli	a1,s2,0x20
    80004e7c:	9181                	srli	a1,a1,0x20
    80004e7e:	95ea                	add	a1,a1,s10
    80004e80:	855e                	mv	a0,s7
    80004e82:	ffffc097          	auipc	ra,0xffffc
    80004e86:	1f6080e7          	jalr	502(ra) # 80001078 <walkaddr>
    80004e8a:	862a                	mv	a2,a0
    if(pa == 0)
    80004e8c:	d955                	beqz	a0,80004e40 <exec+0xf0>
      n = PGSIZE;
    80004e8e:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004e90:	fd9a70e3          	bgeu	s4,s9,80004e50 <exec+0x100>
      n = sz - i;
    80004e94:	8ad2                	mv	s5,s4
    80004e96:	bf6d                	j	80004e50 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e98:	4a01                	li	s4,0
  iunlockput(ip);
    80004e9a:	8526                	mv	a0,s1
    80004e9c:	fffff097          	auipc	ra,0xfffff
    80004ea0:	c00080e7          	jalr	-1024(ra) # 80003a9c <iunlockput>
  end_op();
    80004ea4:	fffff097          	auipc	ra,0xfffff
    80004ea8:	3d8080e7          	jalr	984(ra) # 8000427c <end_op>
  p = myproc();
    80004eac:	ffffd097          	auipc	ra,0xffffd
    80004eb0:	b1a080e7          	jalr	-1254(ra) # 800019c6 <myproc>
    80004eb4:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004eb6:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004eba:	6785                	lui	a5,0x1
    80004ebc:	17fd                	addi	a5,a5,-1
    80004ebe:	9a3e                	add	s4,s4,a5
    80004ec0:	757d                	lui	a0,0xfffff
    80004ec2:	00aa77b3          	and	a5,s4,a0
    80004ec6:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004eca:	4691                	li	a3,4
    80004ecc:	6609                	lui	a2,0x2
    80004ece:	963e                	add	a2,a2,a5
    80004ed0:	85be                	mv	a1,a5
    80004ed2:	855e                	mv	a0,s7
    80004ed4:	ffffc097          	auipc	ra,0xffffc
    80004ed8:	558080e7          	jalr	1368(ra) # 8000142c <uvmalloc>
    80004edc:	8b2a                	mv	s6,a0
  ip = 0;
    80004ede:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004ee0:	12050c63          	beqz	a0,80005018 <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004ee4:	75f9                	lui	a1,0xffffe
    80004ee6:	95aa                	add	a1,a1,a0
    80004ee8:	855e                	mv	a0,s7
    80004eea:	ffffc097          	auipc	ra,0xffffc
    80004eee:	768080e7          	jalr	1896(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    80004ef2:	7c7d                	lui	s8,0xfffff
    80004ef4:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ef6:	e0043783          	ld	a5,-512(s0)
    80004efa:	6388                	ld	a0,0(a5)
    80004efc:	c535                	beqz	a0,80004f68 <exec+0x218>
    80004efe:	e9040993          	addi	s3,s0,-368
    80004f02:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004f06:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004f08:	ffffc097          	auipc	ra,0xffffc
    80004f0c:	f62080e7          	jalr	-158(ra) # 80000e6a <strlen>
    80004f10:	2505                	addiw	a0,a0,1
    80004f12:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f16:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f1a:	13896663          	bltu	s2,s8,80005046 <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f1e:	e0043d83          	ld	s11,-512(s0)
    80004f22:	000dba03          	ld	s4,0(s11)
    80004f26:	8552                	mv	a0,s4
    80004f28:	ffffc097          	auipc	ra,0xffffc
    80004f2c:	f42080e7          	jalr	-190(ra) # 80000e6a <strlen>
    80004f30:	0015069b          	addiw	a3,a0,1
    80004f34:	8652                	mv	a2,s4
    80004f36:	85ca                	mv	a1,s2
    80004f38:	855e                	mv	a0,s7
    80004f3a:	ffffc097          	auipc	ra,0xffffc
    80004f3e:	74a080e7          	jalr	1866(ra) # 80001684 <copyout>
    80004f42:	10054663          	bltz	a0,8000504e <exec+0x2fe>
    ustack[argc] = sp;
    80004f46:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f4a:	0485                	addi	s1,s1,1
    80004f4c:	008d8793          	addi	a5,s11,8
    80004f50:	e0f43023          	sd	a5,-512(s0)
    80004f54:	008db503          	ld	a0,8(s11)
    80004f58:	c911                	beqz	a0,80004f6c <exec+0x21c>
    if(argc >= MAXARG)
    80004f5a:	09a1                	addi	s3,s3,8
    80004f5c:	fb3c96e3          	bne	s9,s3,80004f08 <exec+0x1b8>
  sz = sz1;
    80004f60:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f64:	4481                	li	s1,0
    80004f66:	a84d                	j	80005018 <exec+0x2c8>
  sp = sz;
    80004f68:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f6a:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f6c:	00349793          	slli	a5,s1,0x3
    80004f70:	f9040713          	addi	a4,s0,-112
    80004f74:	97ba                	add	a5,a5,a4
    80004f76:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004f7a:	00148693          	addi	a3,s1,1
    80004f7e:	068e                	slli	a3,a3,0x3
    80004f80:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f84:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f88:	01897663          	bgeu	s2,s8,80004f94 <exec+0x244>
  sz = sz1;
    80004f8c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f90:	4481                	li	s1,0
    80004f92:	a059                	j	80005018 <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f94:	e9040613          	addi	a2,s0,-368
    80004f98:	85ca                	mv	a1,s2
    80004f9a:	855e                	mv	a0,s7
    80004f9c:	ffffc097          	auipc	ra,0xffffc
    80004fa0:	6e8080e7          	jalr	1768(ra) # 80001684 <copyout>
    80004fa4:	0a054963          	bltz	a0,80005056 <exec+0x306>
  p->trapframe->a1 = sp;
    80004fa8:	058ab783          	ld	a5,88(s5)
    80004fac:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004fb0:	df843783          	ld	a5,-520(s0)
    80004fb4:	0007c703          	lbu	a4,0(a5)
    80004fb8:	cf11                	beqz	a4,80004fd4 <exec+0x284>
    80004fba:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004fbc:	02f00693          	li	a3,47
    80004fc0:	a039                	j	80004fce <exec+0x27e>
      last = s+1;
    80004fc2:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004fc6:	0785                	addi	a5,a5,1
    80004fc8:	fff7c703          	lbu	a4,-1(a5)
    80004fcc:	c701                	beqz	a4,80004fd4 <exec+0x284>
    if(*s == '/')
    80004fce:	fed71ce3          	bne	a4,a3,80004fc6 <exec+0x276>
    80004fd2:	bfc5                	j	80004fc2 <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80004fd4:	4641                	li	a2,16
    80004fd6:	df843583          	ld	a1,-520(s0)
    80004fda:	158a8513          	addi	a0,s5,344
    80004fde:	ffffc097          	auipc	ra,0xffffc
    80004fe2:	e5a080e7          	jalr	-422(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    80004fe6:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004fea:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004fee:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004ff2:	058ab783          	ld	a5,88(s5)
    80004ff6:	e6843703          	ld	a4,-408(s0)
    80004ffa:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004ffc:	058ab783          	ld	a5,88(s5)
    80005000:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005004:	85ea                	mv	a1,s10
    80005006:	ffffd097          	auipc	ra,0xffffd
    8000500a:	b20080e7          	jalr	-1248(ra) # 80001b26 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000500e:	0004851b          	sext.w	a0,s1
    80005012:	bbd9                	j	80004de8 <exec+0x98>
    80005014:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005018:	e0843583          	ld	a1,-504(s0)
    8000501c:	855e                	mv	a0,s7
    8000501e:	ffffd097          	auipc	ra,0xffffd
    80005022:	b08080e7          	jalr	-1272(ra) # 80001b26 <proc_freepagetable>
  if(ip){
    80005026:	da0497e3          	bnez	s1,80004dd4 <exec+0x84>
  return -1;
    8000502a:	557d                	li	a0,-1
    8000502c:	bb75                	j	80004de8 <exec+0x98>
    8000502e:	e1443423          	sd	s4,-504(s0)
    80005032:	b7dd                	j	80005018 <exec+0x2c8>
    80005034:	e1443423          	sd	s4,-504(s0)
    80005038:	b7c5                	j	80005018 <exec+0x2c8>
    8000503a:	e1443423          	sd	s4,-504(s0)
    8000503e:	bfe9                	j	80005018 <exec+0x2c8>
    80005040:	e1443423          	sd	s4,-504(s0)
    80005044:	bfd1                	j	80005018 <exec+0x2c8>
  sz = sz1;
    80005046:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000504a:	4481                	li	s1,0
    8000504c:	b7f1                	j	80005018 <exec+0x2c8>
  sz = sz1;
    8000504e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005052:	4481                	li	s1,0
    80005054:	b7d1                	j	80005018 <exec+0x2c8>
  sz = sz1;
    80005056:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000505a:	4481                	li	s1,0
    8000505c:	bf75                	j	80005018 <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000505e:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005062:	2b05                	addiw	s6,s6,1
    80005064:	0389899b          	addiw	s3,s3,56
    80005068:	e8845783          	lhu	a5,-376(s0)
    8000506c:	e2fb57e3          	bge	s6,a5,80004e9a <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005070:	2981                	sext.w	s3,s3
    80005072:	03800713          	li	a4,56
    80005076:	86ce                	mv	a3,s3
    80005078:	e1840613          	addi	a2,s0,-488
    8000507c:	4581                	li	a1,0
    8000507e:	8526                	mv	a0,s1
    80005080:	fffff097          	auipc	ra,0xfffff
    80005084:	a6e080e7          	jalr	-1426(ra) # 80003aee <readi>
    80005088:	03800793          	li	a5,56
    8000508c:	f8f514e3          	bne	a0,a5,80005014 <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    80005090:	e1842783          	lw	a5,-488(s0)
    80005094:	4705                	li	a4,1
    80005096:	fce796e3          	bne	a5,a4,80005062 <exec+0x312>
    if(ph.memsz < ph.filesz)
    8000509a:	e4043903          	ld	s2,-448(s0)
    8000509e:	e3843783          	ld	a5,-456(s0)
    800050a2:	f8f966e3          	bltu	s2,a5,8000502e <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800050a6:	e2843783          	ld	a5,-472(s0)
    800050aa:	993e                	add	s2,s2,a5
    800050ac:	f8f964e3          	bltu	s2,a5,80005034 <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    800050b0:	df043703          	ld	a4,-528(s0)
    800050b4:	8ff9                	and	a5,a5,a4
    800050b6:	f3d1                	bnez	a5,8000503a <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800050b8:	e1c42503          	lw	a0,-484(s0)
    800050bc:	00000097          	auipc	ra,0x0
    800050c0:	c78080e7          	jalr	-904(ra) # 80004d34 <flags2perm>
    800050c4:	86aa                	mv	a3,a0
    800050c6:	864a                	mv	a2,s2
    800050c8:	85d2                	mv	a1,s4
    800050ca:	855e                	mv	a0,s7
    800050cc:	ffffc097          	auipc	ra,0xffffc
    800050d0:	360080e7          	jalr	864(ra) # 8000142c <uvmalloc>
    800050d4:	e0a43423          	sd	a0,-504(s0)
    800050d8:	d525                	beqz	a0,80005040 <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800050da:	e2843d03          	ld	s10,-472(s0)
    800050de:	e2042d83          	lw	s11,-480(s0)
    800050e2:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800050e6:	f60c0ce3          	beqz	s8,8000505e <exec+0x30e>
    800050ea:	8a62                	mv	s4,s8
    800050ec:	4901                	li	s2,0
    800050ee:	b369                	j	80004e78 <exec+0x128>

00000000800050f0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800050f0:	7179                	addi	sp,sp,-48
    800050f2:	f406                	sd	ra,40(sp)
    800050f4:	f022                	sd	s0,32(sp)
    800050f6:	ec26                	sd	s1,24(sp)
    800050f8:	e84a                	sd	s2,16(sp)
    800050fa:	1800                	addi	s0,sp,48
    800050fc:	892e                	mv	s2,a1
    800050fe:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005100:	fdc40593          	addi	a1,s0,-36
    80005104:	ffffe097          	auipc	ra,0xffffe
    80005108:	a98080e7          	jalr	-1384(ra) # 80002b9c <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000510c:	fdc42703          	lw	a4,-36(s0)
    80005110:	47bd                	li	a5,15
    80005112:	02e7eb63          	bltu	a5,a4,80005148 <argfd+0x58>
    80005116:	ffffd097          	auipc	ra,0xffffd
    8000511a:	8b0080e7          	jalr	-1872(ra) # 800019c6 <myproc>
    8000511e:	fdc42703          	lw	a4,-36(s0)
    80005122:	01a70793          	addi	a5,a4,26
    80005126:	078e                	slli	a5,a5,0x3
    80005128:	953e                	add	a0,a0,a5
    8000512a:	611c                	ld	a5,0(a0)
    8000512c:	c385                	beqz	a5,8000514c <argfd+0x5c>
    return -1;
  if(pfd)
    8000512e:	00090463          	beqz	s2,80005136 <argfd+0x46>
    *pfd = fd;
    80005132:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005136:	4501                	li	a0,0
  if(pf)
    80005138:	c091                	beqz	s1,8000513c <argfd+0x4c>
    *pf = f;
    8000513a:	e09c                	sd	a5,0(s1)
}
    8000513c:	70a2                	ld	ra,40(sp)
    8000513e:	7402                	ld	s0,32(sp)
    80005140:	64e2                	ld	s1,24(sp)
    80005142:	6942                	ld	s2,16(sp)
    80005144:	6145                	addi	sp,sp,48
    80005146:	8082                	ret
    return -1;
    80005148:	557d                	li	a0,-1
    8000514a:	bfcd                	j	8000513c <argfd+0x4c>
    8000514c:	557d                	li	a0,-1
    8000514e:	b7fd                	j	8000513c <argfd+0x4c>

0000000080005150 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005150:	1101                	addi	sp,sp,-32
    80005152:	ec06                	sd	ra,24(sp)
    80005154:	e822                	sd	s0,16(sp)
    80005156:	e426                	sd	s1,8(sp)
    80005158:	1000                	addi	s0,sp,32
    8000515a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000515c:	ffffd097          	auipc	ra,0xffffd
    80005160:	86a080e7          	jalr	-1942(ra) # 800019c6 <myproc>
    80005164:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005166:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffdb410>
    8000516a:	4501                	li	a0,0
    8000516c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000516e:	6398                	ld	a4,0(a5)
    80005170:	cb19                	beqz	a4,80005186 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005172:	2505                	addiw	a0,a0,1
    80005174:	07a1                	addi	a5,a5,8
    80005176:	fed51ce3          	bne	a0,a3,8000516e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000517a:	557d                	li	a0,-1
}
    8000517c:	60e2                	ld	ra,24(sp)
    8000517e:	6442                	ld	s0,16(sp)
    80005180:	64a2                	ld	s1,8(sp)
    80005182:	6105                	addi	sp,sp,32
    80005184:	8082                	ret
      p->ofile[fd] = f;
    80005186:	01a50793          	addi	a5,a0,26
    8000518a:	078e                	slli	a5,a5,0x3
    8000518c:	963e                	add	a2,a2,a5
    8000518e:	e204                	sd	s1,0(a2)
      return fd;
    80005190:	b7f5                	j	8000517c <fdalloc+0x2c>

0000000080005192 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005192:	715d                	addi	sp,sp,-80
    80005194:	e486                	sd	ra,72(sp)
    80005196:	e0a2                	sd	s0,64(sp)
    80005198:	fc26                	sd	s1,56(sp)
    8000519a:	f84a                	sd	s2,48(sp)
    8000519c:	f44e                	sd	s3,40(sp)
    8000519e:	f052                	sd	s4,32(sp)
    800051a0:	ec56                	sd	s5,24(sp)
    800051a2:	e85a                	sd	s6,16(sp)
    800051a4:	0880                	addi	s0,sp,80
    800051a6:	8b2e                	mv	s6,a1
    800051a8:	89b2                	mv	s3,a2
    800051aa:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800051ac:	fb040593          	addi	a1,s0,-80
    800051b0:	fffff097          	auipc	ra,0xfffff
    800051b4:	e4e080e7          	jalr	-434(ra) # 80003ffe <nameiparent>
    800051b8:	84aa                	mv	s1,a0
    800051ba:	16050063          	beqz	a0,8000531a <create+0x188>
    return 0;

  ilock(dp);
    800051be:	ffffe097          	auipc	ra,0xffffe
    800051c2:	67c080e7          	jalr	1660(ra) # 8000383a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800051c6:	4601                	li	a2,0
    800051c8:	fb040593          	addi	a1,s0,-80
    800051cc:	8526                	mv	a0,s1
    800051ce:	fffff097          	auipc	ra,0xfffff
    800051d2:	b50080e7          	jalr	-1200(ra) # 80003d1e <dirlookup>
    800051d6:	8aaa                	mv	s5,a0
    800051d8:	c931                	beqz	a0,8000522c <create+0x9a>
    iunlockput(dp);
    800051da:	8526                	mv	a0,s1
    800051dc:	fffff097          	auipc	ra,0xfffff
    800051e0:	8c0080e7          	jalr	-1856(ra) # 80003a9c <iunlockput>
    ilock(ip);
    800051e4:	8556                	mv	a0,s5
    800051e6:	ffffe097          	auipc	ra,0xffffe
    800051ea:	654080e7          	jalr	1620(ra) # 8000383a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051ee:	000b059b          	sext.w	a1,s6
    800051f2:	4789                	li	a5,2
    800051f4:	02f59563          	bne	a1,a5,8000521e <create+0x8c>
    800051f8:	044ad783          	lhu	a5,68(s5)
    800051fc:	37f9                	addiw	a5,a5,-2
    800051fe:	17c2                	slli	a5,a5,0x30
    80005200:	93c1                	srli	a5,a5,0x30
    80005202:	4705                	li	a4,1
    80005204:	00f76d63          	bltu	a4,a5,8000521e <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005208:	8556                	mv	a0,s5
    8000520a:	60a6                	ld	ra,72(sp)
    8000520c:	6406                	ld	s0,64(sp)
    8000520e:	74e2                	ld	s1,56(sp)
    80005210:	7942                	ld	s2,48(sp)
    80005212:	79a2                	ld	s3,40(sp)
    80005214:	7a02                	ld	s4,32(sp)
    80005216:	6ae2                	ld	s5,24(sp)
    80005218:	6b42                	ld	s6,16(sp)
    8000521a:	6161                	addi	sp,sp,80
    8000521c:	8082                	ret
    iunlockput(ip);
    8000521e:	8556                	mv	a0,s5
    80005220:	fffff097          	auipc	ra,0xfffff
    80005224:	87c080e7          	jalr	-1924(ra) # 80003a9c <iunlockput>
    return 0;
    80005228:	4a81                	li	s5,0
    8000522a:	bff9                	j	80005208 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000522c:	85da                	mv	a1,s6
    8000522e:	4088                	lw	a0,0(s1)
    80005230:	ffffe097          	auipc	ra,0xffffe
    80005234:	46e080e7          	jalr	1134(ra) # 8000369e <ialloc>
    80005238:	8a2a                	mv	s4,a0
    8000523a:	c921                	beqz	a0,8000528a <create+0xf8>
  ilock(ip);
    8000523c:	ffffe097          	auipc	ra,0xffffe
    80005240:	5fe080e7          	jalr	1534(ra) # 8000383a <ilock>
  ip->major = major;
    80005244:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005248:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000524c:	4785                	li	a5,1
    8000524e:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    80005252:	8552                	mv	a0,s4
    80005254:	ffffe097          	auipc	ra,0xffffe
    80005258:	51c080e7          	jalr	1308(ra) # 80003770 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000525c:	000b059b          	sext.w	a1,s6
    80005260:	4785                	li	a5,1
    80005262:	02f58b63          	beq	a1,a5,80005298 <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    80005266:	004a2603          	lw	a2,4(s4)
    8000526a:	fb040593          	addi	a1,s0,-80
    8000526e:	8526                	mv	a0,s1
    80005270:	fffff097          	auipc	ra,0xfffff
    80005274:	cbe080e7          	jalr	-834(ra) # 80003f2e <dirlink>
    80005278:	06054f63          	bltz	a0,800052f6 <create+0x164>
  iunlockput(dp);
    8000527c:	8526                	mv	a0,s1
    8000527e:	fffff097          	auipc	ra,0xfffff
    80005282:	81e080e7          	jalr	-2018(ra) # 80003a9c <iunlockput>
  return ip;
    80005286:	8ad2                	mv	s5,s4
    80005288:	b741                	j	80005208 <create+0x76>
    iunlockput(dp);
    8000528a:	8526                	mv	a0,s1
    8000528c:	fffff097          	auipc	ra,0xfffff
    80005290:	810080e7          	jalr	-2032(ra) # 80003a9c <iunlockput>
    return 0;
    80005294:	8ad2                	mv	s5,s4
    80005296:	bf8d                	j	80005208 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005298:	004a2603          	lw	a2,4(s4)
    8000529c:	00003597          	auipc	a1,0x3
    800052a0:	55458593          	addi	a1,a1,1364 # 800087f0 <syscalls+0x2c0>
    800052a4:	8552                	mv	a0,s4
    800052a6:	fffff097          	auipc	ra,0xfffff
    800052aa:	c88080e7          	jalr	-888(ra) # 80003f2e <dirlink>
    800052ae:	04054463          	bltz	a0,800052f6 <create+0x164>
    800052b2:	40d0                	lw	a2,4(s1)
    800052b4:	00003597          	auipc	a1,0x3
    800052b8:	54458593          	addi	a1,a1,1348 # 800087f8 <syscalls+0x2c8>
    800052bc:	8552                	mv	a0,s4
    800052be:	fffff097          	auipc	ra,0xfffff
    800052c2:	c70080e7          	jalr	-912(ra) # 80003f2e <dirlink>
    800052c6:	02054863          	bltz	a0,800052f6 <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    800052ca:	004a2603          	lw	a2,4(s4)
    800052ce:	fb040593          	addi	a1,s0,-80
    800052d2:	8526                	mv	a0,s1
    800052d4:	fffff097          	auipc	ra,0xfffff
    800052d8:	c5a080e7          	jalr	-934(ra) # 80003f2e <dirlink>
    800052dc:	00054d63          	bltz	a0,800052f6 <create+0x164>
    dp->nlink++;  // for ".."
    800052e0:	04a4d783          	lhu	a5,74(s1)
    800052e4:	2785                	addiw	a5,a5,1
    800052e6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800052ea:	8526                	mv	a0,s1
    800052ec:	ffffe097          	auipc	ra,0xffffe
    800052f0:	484080e7          	jalr	1156(ra) # 80003770 <iupdate>
    800052f4:	b761                	j	8000527c <create+0xea>
  ip->nlink = 0;
    800052f6:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800052fa:	8552                	mv	a0,s4
    800052fc:	ffffe097          	auipc	ra,0xffffe
    80005300:	474080e7          	jalr	1140(ra) # 80003770 <iupdate>
  iunlockput(ip);
    80005304:	8552                	mv	a0,s4
    80005306:	ffffe097          	auipc	ra,0xffffe
    8000530a:	796080e7          	jalr	1942(ra) # 80003a9c <iunlockput>
  iunlockput(dp);
    8000530e:	8526                	mv	a0,s1
    80005310:	ffffe097          	auipc	ra,0xffffe
    80005314:	78c080e7          	jalr	1932(ra) # 80003a9c <iunlockput>
  return 0;
    80005318:	bdc5                	j	80005208 <create+0x76>
    return 0;
    8000531a:	8aaa                	mv	s5,a0
    8000531c:	b5f5                	j	80005208 <create+0x76>

000000008000531e <sys_dup>:
{
    8000531e:	7179                	addi	sp,sp,-48
    80005320:	f406                	sd	ra,40(sp)
    80005322:	f022                	sd	s0,32(sp)
    80005324:	ec26                	sd	s1,24(sp)
    80005326:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005328:	fd840613          	addi	a2,s0,-40
    8000532c:	4581                	li	a1,0
    8000532e:	4501                	li	a0,0
    80005330:	00000097          	auipc	ra,0x0
    80005334:	dc0080e7          	jalr	-576(ra) # 800050f0 <argfd>
    return -1;
    80005338:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000533a:	02054363          	bltz	a0,80005360 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000533e:	fd843503          	ld	a0,-40(s0)
    80005342:	00000097          	auipc	ra,0x0
    80005346:	e0e080e7          	jalr	-498(ra) # 80005150 <fdalloc>
    8000534a:	84aa                	mv	s1,a0
    return -1;
    8000534c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000534e:	00054963          	bltz	a0,80005360 <sys_dup+0x42>
  filedup(f);
    80005352:	fd843503          	ld	a0,-40(s0)
    80005356:	fffff097          	auipc	ra,0xfffff
    8000535a:	320080e7          	jalr	800(ra) # 80004676 <filedup>
  return fd;
    8000535e:	87a6                	mv	a5,s1
}
    80005360:	853e                	mv	a0,a5
    80005362:	70a2                	ld	ra,40(sp)
    80005364:	7402                	ld	s0,32(sp)
    80005366:	64e2                	ld	s1,24(sp)
    80005368:	6145                	addi	sp,sp,48
    8000536a:	8082                	ret

000000008000536c <sys_read>:
{
    8000536c:	7179                	addi	sp,sp,-48
    8000536e:	f406                	sd	ra,40(sp)
    80005370:	f022                	sd	s0,32(sp)
    80005372:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005374:	fd840593          	addi	a1,s0,-40
    80005378:	4505                	li	a0,1
    8000537a:	ffffe097          	auipc	ra,0xffffe
    8000537e:	842080e7          	jalr	-1982(ra) # 80002bbc <argaddr>
  argint(2, &n);
    80005382:	fe440593          	addi	a1,s0,-28
    80005386:	4509                	li	a0,2
    80005388:	ffffe097          	auipc	ra,0xffffe
    8000538c:	814080e7          	jalr	-2028(ra) # 80002b9c <argint>
  if(argfd(0, 0, &f) < 0)
    80005390:	fe840613          	addi	a2,s0,-24
    80005394:	4581                	li	a1,0
    80005396:	4501                	li	a0,0
    80005398:	00000097          	auipc	ra,0x0
    8000539c:	d58080e7          	jalr	-680(ra) # 800050f0 <argfd>
    800053a0:	87aa                	mv	a5,a0
    return -1;
    800053a2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800053a4:	0007cc63          	bltz	a5,800053bc <sys_read+0x50>
  return fileread(f, p, n);
    800053a8:	fe442603          	lw	a2,-28(s0)
    800053ac:	fd843583          	ld	a1,-40(s0)
    800053b0:	fe843503          	ld	a0,-24(s0)
    800053b4:	fffff097          	auipc	ra,0xfffff
    800053b8:	44e080e7          	jalr	1102(ra) # 80004802 <fileread>
}
    800053bc:	70a2                	ld	ra,40(sp)
    800053be:	7402                	ld	s0,32(sp)
    800053c0:	6145                	addi	sp,sp,48
    800053c2:	8082                	ret

00000000800053c4 <sys_write>:
{
    800053c4:	7179                	addi	sp,sp,-48
    800053c6:	f406                	sd	ra,40(sp)
    800053c8:	f022                	sd	s0,32(sp)
    800053ca:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800053cc:	fd840593          	addi	a1,s0,-40
    800053d0:	4505                	li	a0,1
    800053d2:	ffffd097          	auipc	ra,0xffffd
    800053d6:	7ea080e7          	jalr	2026(ra) # 80002bbc <argaddr>
  argint(2, &n);
    800053da:	fe440593          	addi	a1,s0,-28
    800053de:	4509                	li	a0,2
    800053e0:	ffffd097          	auipc	ra,0xffffd
    800053e4:	7bc080e7          	jalr	1980(ra) # 80002b9c <argint>
  if(argfd(0, 0, &f) < 0)
    800053e8:	fe840613          	addi	a2,s0,-24
    800053ec:	4581                	li	a1,0
    800053ee:	4501                	li	a0,0
    800053f0:	00000097          	auipc	ra,0x0
    800053f4:	d00080e7          	jalr	-768(ra) # 800050f0 <argfd>
    800053f8:	87aa                	mv	a5,a0
    return -1;
    800053fa:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800053fc:	0007cc63          	bltz	a5,80005414 <sys_write+0x50>
  return filewrite(f, p, n);
    80005400:	fe442603          	lw	a2,-28(s0)
    80005404:	fd843583          	ld	a1,-40(s0)
    80005408:	fe843503          	ld	a0,-24(s0)
    8000540c:	fffff097          	auipc	ra,0xfffff
    80005410:	4b8080e7          	jalr	1208(ra) # 800048c4 <filewrite>
}
    80005414:	70a2                	ld	ra,40(sp)
    80005416:	7402                	ld	s0,32(sp)
    80005418:	6145                	addi	sp,sp,48
    8000541a:	8082                	ret

000000008000541c <sys_close>:
{
    8000541c:	1101                	addi	sp,sp,-32
    8000541e:	ec06                	sd	ra,24(sp)
    80005420:	e822                	sd	s0,16(sp)
    80005422:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005424:	fe040613          	addi	a2,s0,-32
    80005428:	fec40593          	addi	a1,s0,-20
    8000542c:	4501                	li	a0,0
    8000542e:	00000097          	auipc	ra,0x0
    80005432:	cc2080e7          	jalr	-830(ra) # 800050f0 <argfd>
    return -1;
    80005436:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005438:	02054463          	bltz	a0,80005460 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000543c:	ffffc097          	auipc	ra,0xffffc
    80005440:	58a080e7          	jalr	1418(ra) # 800019c6 <myproc>
    80005444:	fec42783          	lw	a5,-20(s0)
    80005448:	07e9                	addi	a5,a5,26
    8000544a:	078e                	slli	a5,a5,0x3
    8000544c:	97aa                	add	a5,a5,a0
    8000544e:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005452:	fe043503          	ld	a0,-32(s0)
    80005456:	fffff097          	auipc	ra,0xfffff
    8000545a:	272080e7          	jalr	626(ra) # 800046c8 <fileclose>
  return 0;
    8000545e:	4781                	li	a5,0
}
    80005460:	853e                	mv	a0,a5
    80005462:	60e2                	ld	ra,24(sp)
    80005464:	6442                	ld	s0,16(sp)
    80005466:	6105                	addi	sp,sp,32
    80005468:	8082                	ret

000000008000546a <sys_fstat>:
{
    8000546a:	1101                	addi	sp,sp,-32
    8000546c:	ec06                	sd	ra,24(sp)
    8000546e:	e822                	sd	s0,16(sp)
    80005470:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005472:	fe040593          	addi	a1,s0,-32
    80005476:	4505                	li	a0,1
    80005478:	ffffd097          	auipc	ra,0xffffd
    8000547c:	744080e7          	jalr	1860(ra) # 80002bbc <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005480:	fe840613          	addi	a2,s0,-24
    80005484:	4581                	li	a1,0
    80005486:	4501                	li	a0,0
    80005488:	00000097          	auipc	ra,0x0
    8000548c:	c68080e7          	jalr	-920(ra) # 800050f0 <argfd>
    80005490:	87aa                	mv	a5,a0
    return -1;
    80005492:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005494:	0007ca63          	bltz	a5,800054a8 <sys_fstat+0x3e>
  return filestat(f, st);
    80005498:	fe043583          	ld	a1,-32(s0)
    8000549c:	fe843503          	ld	a0,-24(s0)
    800054a0:	fffff097          	auipc	ra,0xfffff
    800054a4:	2f0080e7          	jalr	752(ra) # 80004790 <filestat>
}
    800054a8:	60e2                	ld	ra,24(sp)
    800054aa:	6442                	ld	s0,16(sp)
    800054ac:	6105                	addi	sp,sp,32
    800054ae:	8082                	ret

00000000800054b0 <sys_link>:
{
    800054b0:	7169                	addi	sp,sp,-304
    800054b2:	f606                	sd	ra,296(sp)
    800054b4:	f222                	sd	s0,288(sp)
    800054b6:	ee26                	sd	s1,280(sp)
    800054b8:	ea4a                	sd	s2,272(sp)
    800054ba:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054bc:	08000613          	li	a2,128
    800054c0:	ed040593          	addi	a1,s0,-304
    800054c4:	4501                	li	a0,0
    800054c6:	ffffd097          	auipc	ra,0xffffd
    800054ca:	716080e7          	jalr	1814(ra) # 80002bdc <argstr>
    return -1;
    800054ce:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054d0:	10054e63          	bltz	a0,800055ec <sys_link+0x13c>
    800054d4:	08000613          	li	a2,128
    800054d8:	f5040593          	addi	a1,s0,-176
    800054dc:	4505                	li	a0,1
    800054de:	ffffd097          	auipc	ra,0xffffd
    800054e2:	6fe080e7          	jalr	1790(ra) # 80002bdc <argstr>
    return -1;
    800054e6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054e8:	10054263          	bltz	a0,800055ec <sys_link+0x13c>
  begin_op();
    800054ec:	fffff097          	auipc	ra,0xfffff
    800054f0:	d10080e7          	jalr	-752(ra) # 800041fc <begin_op>
  if((ip = namei(old)) == 0){
    800054f4:	ed040513          	addi	a0,s0,-304
    800054f8:	fffff097          	auipc	ra,0xfffff
    800054fc:	ae8080e7          	jalr	-1304(ra) # 80003fe0 <namei>
    80005500:	84aa                	mv	s1,a0
    80005502:	c551                	beqz	a0,8000558e <sys_link+0xde>
  ilock(ip);
    80005504:	ffffe097          	auipc	ra,0xffffe
    80005508:	336080e7          	jalr	822(ra) # 8000383a <ilock>
  if(ip->type == T_DIR){
    8000550c:	04449703          	lh	a4,68(s1)
    80005510:	4785                	li	a5,1
    80005512:	08f70463          	beq	a4,a5,8000559a <sys_link+0xea>
  ip->nlink++;
    80005516:	04a4d783          	lhu	a5,74(s1)
    8000551a:	2785                	addiw	a5,a5,1
    8000551c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005520:	8526                	mv	a0,s1
    80005522:	ffffe097          	auipc	ra,0xffffe
    80005526:	24e080e7          	jalr	590(ra) # 80003770 <iupdate>
  iunlock(ip);
    8000552a:	8526                	mv	a0,s1
    8000552c:	ffffe097          	auipc	ra,0xffffe
    80005530:	3d0080e7          	jalr	976(ra) # 800038fc <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005534:	fd040593          	addi	a1,s0,-48
    80005538:	f5040513          	addi	a0,s0,-176
    8000553c:	fffff097          	auipc	ra,0xfffff
    80005540:	ac2080e7          	jalr	-1342(ra) # 80003ffe <nameiparent>
    80005544:	892a                	mv	s2,a0
    80005546:	c935                	beqz	a0,800055ba <sys_link+0x10a>
  ilock(dp);
    80005548:	ffffe097          	auipc	ra,0xffffe
    8000554c:	2f2080e7          	jalr	754(ra) # 8000383a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005550:	00092703          	lw	a4,0(s2)
    80005554:	409c                	lw	a5,0(s1)
    80005556:	04f71d63          	bne	a4,a5,800055b0 <sys_link+0x100>
    8000555a:	40d0                	lw	a2,4(s1)
    8000555c:	fd040593          	addi	a1,s0,-48
    80005560:	854a                	mv	a0,s2
    80005562:	fffff097          	auipc	ra,0xfffff
    80005566:	9cc080e7          	jalr	-1588(ra) # 80003f2e <dirlink>
    8000556a:	04054363          	bltz	a0,800055b0 <sys_link+0x100>
  iunlockput(dp);
    8000556e:	854a                	mv	a0,s2
    80005570:	ffffe097          	auipc	ra,0xffffe
    80005574:	52c080e7          	jalr	1324(ra) # 80003a9c <iunlockput>
  iput(ip);
    80005578:	8526                	mv	a0,s1
    8000557a:	ffffe097          	auipc	ra,0xffffe
    8000557e:	47a080e7          	jalr	1146(ra) # 800039f4 <iput>
  end_op();
    80005582:	fffff097          	auipc	ra,0xfffff
    80005586:	cfa080e7          	jalr	-774(ra) # 8000427c <end_op>
  return 0;
    8000558a:	4781                	li	a5,0
    8000558c:	a085                	j	800055ec <sys_link+0x13c>
    end_op();
    8000558e:	fffff097          	auipc	ra,0xfffff
    80005592:	cee080e7          	jalr	-786(ra) # 8000427c <end_op>
    return -1;
    80005596:	57fd                	li	a5,-1
    80005598:	a891                	j	800055ec <sys_link+0x13c>
    iunlockput(ip);
    8000559a:	8526                	mv	a0,s1
    8000559c:	ffffe097          	auipc	ra,0xffffe
    800055a0:	500080e7          	jalr	1280(ra) # 80003a9c <iunlockput>
    end_op();
    800055a4:	fffff097          	auipc	ra,0xfffff
    800055a8:	cd8080e7          	jalr	-808(ra) # 8000427c <end_op>
    return -1;
    800055ac:	57fd                	li	a5,-1
    800055ae:	a83d                	j	800055ec <sys_link+0x13c>
    iunlockput(dp);
    800055b0:	854a                	mv	a0,s2
    800055b2:	ffffe097          	auipc	ra,0xffffe
    800055b6:	4ea080e7          	jalr	1258(ra) # 80003a9c <iunlockput>
  ilock(ip);
    800055ba:	8526                	mv	a0,s1
    800055bc:	ffffe097          	auipc	ra,0xffffe
    800055c0:	27e080e7          	jalr	638(ra) # 8000383a <ilock>
  ip->nlink--;
    800055c4:	04a4d783          	lhu	a5,74(s1)
    800055c8:	37fd                	addiw	a5,a5,-1
    800055ca:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055ce:	8526                	mv	a0,s1
    800055d0:	ffffe097          	auipc	ra,0xffffe
    800055d4:	1a0080e7          	jalr	416(ra) # 80003770 <iupdate>
  iunlockput(ip);
    800055d8:	8526                	mv	a0,s1
    800055da:	ffffe097          	auipc	ra,0xffffe
    800055de:	4c2080e7          	jalr	1218(ra) # 80003a9c <iunlockput>
  end_op();
    800055e2:	fffff097          	auipc	ra,0xfffff
    800055e6:	c9a080e7          	jalr	-870(ra) # 8000427c <end_op>
  return -1;
    800055ea:	57fd                	li	a5,-1
}
    800055ec:	853e                	mv	a0,a5
    800055ee:	70b2                	ld	ra,296(sp)
    800055f0:	7412                	ld	s0,288(sp)
    800055f2:	64f2                	ld	s1,280(sp)
    800055f4:	6952                	ld	s2,272(sp)
    800055f6:	6155                	addi	sp,sp,304
    800055f8:	8082                	ret

00000000800055fa <sys_unlink>:
{
    800055fa:	7151                	addi	sp,sp,-240
    800055fc:	f586                	sd	ra,232(sp)
    800055fe:	f1a2                	sd	s0,224(sp)
    80005600:	eda6                	sd	s1,216(sp)
    80005602:	e9ca                	sd	s2,208(sp)
    80005604:	e5ce                	sd	s3,200(sp)
    80005606:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005608:	08000613          	li	a2,128
    8000560c:	f3040593          	addi	a1,s0,-208
    80005610:	4501                	li	a0,0
    80005612:	ffffd097          	auipc	ra,0xffffd
    80005616:	5ca080e7          	jalr	1482(ra) # 80002bdc <argstr>
    8000561a:	18054163          	bltz	a0,8000579c <sys_unlink+0x1a2>
  begin_op();
    8000561e:	fffff097          	auipc	ra,0xfffff
    80005622:	bde080e7          	jalr	-1058(ra) # 800041fc <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005626:	fb040593          	addi	a1,s0,-80
    8000562a:	f3040513          	addi	a0,s0,-208
    8000562e:	fffff097          	auipc	ra,0xfffff
    80005632:	9d0080e7          	jalr	-1584(ra) # 80003ffe <nameiparent>
    80005636:	84aa                	mv	s1,a0
    80005638:	c979                	beqz	a0,8000570e <sys_unlink+0x114>
  ilock(dp);
    8000563a:	ffffe097          	auipc	ra,0xffffe
    8000563e:	200080e7          	jalr	512(ra) # 8000383a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005642:	00003597          	auipc	a1,0x3
    80005646:	1ae58593          	addi	a1,a1,430 # 800087f0 <syscalls+0x2c0>
    8000564a:	fb040513          	addi	a0,s0,-80
    8000564e:	ffffe097          	auipc	ra,0xffffe
    80005652:	6b6080e7          	jalr	1718(ra) # 80003d04 <namecmp>
    80005656:	14050a63          	beqz	a0,800057aa <sys_unlink+0x1b0>
    8000565a:	00003597          	auipc	a1,0x3
    8000565e:	19e58593          	addi	a1,a1,414 # 800087f8 <syscalls+0x2c8>
    80005662:	fb040513          	addi	a0,s0,-80
    80005666:	ffffe097          	auipc	ra,0xffffe
    8000566a:	69e080e7          	jalr	1694(ra) # 80003d04 <namecmp>
    8000566e:	12050e63          	beqz	a0,800057aa <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005672:	f2c40613          	addi	a2,s0,-212
    80005676:	fb040593          	addi	a1,s0,-80
    8000567a:	8526                	mv	a0,s1
    8000567c:	ffffe097          	auipc	ra,0xffffe
    80005680:	6a2080e7          	jalr	1698(ra) # 80003d1e <dirlookup>
    80005684:	892a                	mv	s2,a0
    80005686:	12050263          	beqz	a0,800057aa <sys_unlink+0x1b0>
  ilock(ip);
    8000568a:	ffffe097          	auipc	ra,0xffffe
    8000568e:	1b0080e7          	jalr	432(ra) # 8000383a <ilock>
  if(ip->nlink < 1)
    80005692:	04a91783          	lh	a5,74(s2)
    80005696:	08f05263          	blez	a5,8000571a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000569a:	04491703          	lh	a4,68(s2)
    8000569e:	4785                	li	a5,1
    800056a0:	08f70563          	beq	a4,a5,8000572a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800056a4:	4641                	li	a2,16
    800056a6:	4581                	li	a1,0
    800056a8:	fc040513          	addi	a0,s0,-64
    800056ac:	ffffb097          	auipc	ra,0xffffb
    800056b0:	63a080e7          	jalr	1594(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056b4:	4741                	li	a4,16
    800056b6:	f2c42683          	lw	a3,-212(s0)
    800056ba:	fc040613          	addi	a2,s0,-64
    800056be:	4581                	li	a1,0
    800056c0:	8526                	mv	a0,s1
    800056c2:	ffffe097          	auipc	ra,0xffffe
    800056c6:	524080e7          	jalr	1316(ra) # 80003be6 <writei>
    800056ca:	47c1                	li	a5,16
    800056cc:	0af51563          	bne	a0,a5,80005776 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800056d0:	04491703          	lh	a4,68(s2)
    800056d4:	4785                	li	a5,1
    800056d6:	0af70863          	beq	a4,a5,80005786 <sys_unlink+0x18c>
  iunlockput(dp);
    800056da:	8526                	mv	a0,s1
    800056dc:	ffffe097          	auipc	ra,0xffffe
    800056e0:	3c0080e7          	jalr	960(ra) # 80003a9c <iunlockput>
  ip->nlink--;
    800056e4:	04a95783          	lhu	a5,74(s2)
    800056e8:	37fd                	addiw	a5,a5,-1
    800056ea:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800056ee:	854a                	mv	a0,s2
    800056f0:	ffffe097          	auipc	ra,0xffffe
    800056f4:	080080e7          	jalr	128(ra) # 80003770 <iupdate>
  iunlockput(ip);
    800056f8:	854a                	mv	a0,s2
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	3a2080e7          	jalr	930(ra) # 80003a9c <iunlockput>
  end_op();
    80005702:	fffff097          	auipc	ra,0xfffff
    80005706:	b7a080e7          	jalr	-1158(ra) # 8000427c <end_op>
  return 0;
    8000570a:	4501                	li	a0,0
    8000570c:	a84d                	j	800057be <sys_unlink+0x1c4>
    end_op();
    8000570e:	fffff097          	auipc	ra,0xfffff
    80005712:	b6e080e7          	jalr	-1170(ra) # 8000427c <end_op>
    return -1;
    80005716:	557d                	li	a0,-1
    80005718:	a05d                	j	800057be <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000571a:	00003517          	auipc	a0,0x3
    8000571e:	0e650513          	addi	a0,a0,230 # 80008800 <syscalls+0x2d0>
    80005722:	ffffb097          	auipc	ra,0xffffb
    80005726:	e22080e7          	jalr	-478(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000572a:	04c92703          	lw	a4,76(s2)
    8000572e:	02000793          	li	a5,32
    80005732:	f6e7f9e3          	bgeu	a5,a4,800056a4 <sys_unlink+0xaa>
    80005736:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000573a:	4741                	li	a4,16
    8000573c:	86ce                	mv	a3,s3
    8000573e:	f1840613          	addi	a2,s0,-232
    80005742:	4581                	li	a1,0
    80005744:	854a                	mv	a0,s2
    80005746:	ffffe097          	auipc	ra,0xffffe
    8000574a:	3a8080e7          	jalr	936(ra) # 80003aee <readi>
    8000574e:	47c1                	li	a5,16
    80005750:	00f51b63          	bne	a0,a5,80005766 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005754:	f1845783          	lhu	a5,-232(s0)
    80005758:	e7a1                	bnez	a5,800057a0 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000575a:	29c1                	addiw	s3,s3,16
    8000575c:	04c92783          	lw	a5,76(s2)
    80005760:	fcf9ede3          	bltu	s3,a5,8000573a <sys_unlink+0x140>
    80005764:	b781                	j	800056a4 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005766:	00003517          	auipc	a0,0x3
    8000576a:	0b250513          	addi	a0,a0,178 # 80008818 <syscalls+0x2e8>
    8000576e:	ffffb097          	auipc	ra,0xffffb
    80005772:	dd6080e7          	jalr	-554(ra) # 80000544 <panic>
    panic("unlink: writei");
    80005776:	00003517          	auipc	a0,0x3
    8000577a:	0ba50513          	addi	a0,a0,186 # 80008830 <syscalls+0x300>
    8000577e:	ffffb097          	auipc	ra,0xffffb
    80005782:	dc6080e7          	jalr	-570(ra) # 80000544 <panic>
    dp->nlink--;
    80005786:	04a4d783          	lhu	a5,74(s1)
    8000578a:	37fd                	addiw	a5,a5,-1
    8000578c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005790:	8526                	mv	a0,s1
    80005792:	ffffe097          	auipc	ra,0xffffe
    80005796:	fde080e7          	jalr	-34(ra) # 80003770 <iupdate>
    8000579a:	b781                	j	800056da <sys_unlink+0xe0>
    return -1;
    8000579c:	557d                	li	a0,-1
    8000579e:	a005                	j	800057be <sys_unlink+0x1c4>
    iunlockput(ip);
    800057a0:	854a                	mv	a0,s2
    800057a2:	ffffe097          	auipc	ra,0xffffe
    800057a6:	2fa080e7          	jalr	762(ra) # 80003a9c <iunlockput>
  iunlockput(dp);
    800057aa:	8526                	mv	a0,s1
    800057ac:	ffffe097          	auipc	ra,0xffffe
    800057b0:	2f0080e7          	jalr	752(ra) # 80003a9c <iunlockput>
  end_op();
    800057b4:	fffff097          	auipc	ra,0xfffff
    800057b8:	ac8080e7          	jalr	-1336(ra) # 8000427c <end_op>
  return -1;
    800057bc:	557d                	li	a0,-1
}
    800057be:	70ae                	ld	ra,232(sp)
    800057c0:	740e                	ld	s0,224(sp)
    800057c2:	64ee                	ld	s1,216(sp)
    800057c4:	694e                	ld	s2,208(sp)
    800057c6:	69ae                	ld	s3,200(sp)
    800057c8:	616d                	addi	sp,sp,240
    800057ca:	8082                	ret

00000000800057cc <sys_open>:

uint64
sys_open(void)
{
    800057cc:	7131                	addi	sp,sp,-192
    800057ce:	fd06                	sd	ra,184(sp)
    800057d0:	f922                	sd	s0,176(sp)
    800057d2:	f526                	sd	s1,168(sp)
    800057d4:	f14a                	sd	s2,160(sp)
    800057d6:	ed4e                	sd	s3,152(sp)
    800057d8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800057da:	f4c40593          	addi	a1,s0,-180
    800057de:	4505                	li	a0,1
    800057e0:	ffffd097          	auipc	ra,0xffffd
    800057e4:	3bc080e7          	jalr	956(ra) # 80002b9c <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800057e8:	08000613          	li	a2,128
    800057ec:	f5040593          	addi	a1,s0,-176
    800057f0:	4501                	li	a0,0
    800057f2:	ffffd097          	auipc	ra,0xffffd
    800057f6:	3ea080e7          	jalr	1002(ra) # 80002bdc <argstr>
    800057fa:	87aa                	mv	a5,a0
    return -1;
    800057fc:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800057fe:	0a07c963          	bltz	a5,800058b0 <sys_open+0xe4>

  begin_op();
    80005802:	fffff097          	auipc	ra,0xfffff
    80005806:	9fa080e7          	jalr	-1542(ra) # 800041fc <begin_op>

  if(omode & O_CREATE){
    8000580a:	f4c42783          	lw	a5,-180(s0)
    8000580e:	2007f793          	andi	a5,a5,512
    80005812:	cfc5                	beqz	a5,800058ca <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005814:	4681                	li	a3,0
    80005816:	4601                	li	a2,0
    80005818:	4589                	li	a1,2
    8000581a:	f5040513          	addi	a0,s0,-176
    8000581e:	00000097          	auipc	ra,0x0
    80005822:	974080e7          	jalr	-1676(ra) # 80005192 <create>
    80005826:	84aa                	mv	s1,a0
    if(ip == 0){
    80005828:	c959                	beqz	a0,800058be <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000582a:	04449703          	lh	a4,68(s1)
    8000582e:	478d                	li	a5,3
    80005830:	00f71763          	bne	a4,a5,8000583e <sys_open+0x72>
    80005834:	0464d703          	lhu	a4,70(s1)
    80005838:	47a5                	li	a5,9
    8000583a:	0ce7ed63          	bltu	a5,a4,80005914 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000583e:	fffff097          	auipc	ra,0xfffff
    80005842:	dce080e7          	jalr	-562(ra) # 8000460c <filealloc>
    80005846:	89aa                	mv	s3,a0
    80005848:	10050363          	beqz	a0,8000594e <sys_open+0x182>
    8000584c:	00000097          	auipc	ra,0x0
    80005850:	904080e7          	jalr	-1788(ra) # 80005150 <fdalloc>
    80005854:	892a                	mv	s2,a0
    80005856:	0e054763          	bltz	a0,80005944 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000585a:	04449703          	lh	a4,68(s1)
    8000585e:	478d                	li	a5,3
    80005860:	0cf70563          	beq	a4,a5,8000592a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005864:	4789                	li	a5,2
    80005866:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000586a:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000586e:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005872:	f4c42783          	lw	a5,-180(s0)
    80005876:	0017c713          	xori	a4,a5,1
    8000587a:	8b05                	andi	a4,a4,1
    8000587c:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005880:	0037f713          	andi	a4,a5,3
    80005884:	00e03733          	snez	a4,a4
    80005888:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000588c:	4007f793          	andi	a5,a5,1024
    80005890:	c791                	beqz	a5,8000589c <sys_open+0xd0>
    80005892:	04449703          	lh	a4,68(s1)
    80005896:	4789                	li	a5,2
    80005898:	0af70063          	beq	a4,a5,80005938 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000589c:	8526                	mv	a0,s1
    8000589e:	ffffe097          	auipc	ra,0xffffe
    800058a2:	05e080e7          	jalr	94(ra) # 800038fc <iunlock>
  end_op();
    800058a6:	fffff097          	auipc	ra,0xfffff
    800058aa:	9d6080e7          	jalr	-1578(ra) # 8000427c <end_op>

  return fd;
    800058ae:	854a                	mv	a0,s2
}
    800058b0:	70ea                	ld	ra,184(sp)
    800058b2:	744a                	ld	s0,176(sp)
    800058b4:	74aa                	ld	s1,168(sp)
    800058b6:	790a                	ld	s2,160(sp)
    800058b8:	69ea                	ld	s3,152(sp)
    800058ba:	6129                	addi	sp,sp,192
    800058bc:	8082                	ret
      end_op();
    800058be:	fffff097          	auipc	ra,0xfffff
    800058c2:	9be080e7          	jalr	-1602(ra) # 8000427c <end_op>
      return -1;
    800058c6:	557d                	li	a0,-1
    800058c8:	b7e5                	j	800058b0 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800058ca:	f5040513          	addi	a0,s0,-176
    800058ce:	ffffe097          	auipc	ra,0xffffe
    800058d2:	712080e7          	jalr	1810(ra) # 80003fe0 <namei>
    800058d6:	84aa                	mv	s1,a0
    800058d8:	c905                	beqz	a0,80005908 <sys_open+0x13c>
    ilock(ip);
    800058da:	ffffe097          	auipc	ra,0xffffe
    800058de:	f60080e7          	jalr	-160(ra) # 8000383a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800058e2:	04449703          	lh	a4,68(s1)
    800058e6:	4785                	li	a5,1
    800058e8:	f4f711e3          	bne	a4,a5,8000582a <sys_open+0x5e>
    800058ec:	f4c42783          	lw	a5,-180(s0)
    800058f0:	d7b9                	beqz	a5,8000583e <sys_open+0x72>
      iunlockput(ip);
    800058f2:	8526                	mv	a0,s1
    800058f4:	ffffe097          	auipc	ra,0xffffe
    800058f8:	1a8080e7          	jalr	424(ra) # 80003a9c <iunlockput>
      end_op();
    800058fc:	fffff097          	auipc	ra,0xfffff
    80005900:	980080e7          	jalr	-1664(ra) # 8000427c <end_op>
      return -1;
    80005904:	557d                	li	a0,-1
    80005906:	b76d                	j	800058b0 <sys_open+0xe4>
      end_op();
    80005908:	fffff097          	auipc	ra,0xfffff
    8000590c:	974080e7          	jalr	-1676(ra) # 8000427c <end_op>
      return -1;
    80005910:	557d                	li	a0,-1
    80005912:	bf79                	j	800058b0 <sys_open+0xe4>
    iunlockput(ip);
    80005914:	8526                	mv	a0,s1
    80005916:	ffffe097          	auipc	ra,0xffffe
    8000591a:	186080e7          	jalr	390(ra) # 80003a9c <iunlockput>
    end_op();
    8000591e:	fffff097          	auipc	ra,0xfffff
    80005922:	95e080e7          	jalr	-1698(ra) # 8000427c <end_op>
    return -1;
    80005926:	557d                	li	a0,-1
    80005928:	b761                	j	800058b0 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000592a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000592e:	04649783          	lh	a5,70(s1)
    80005932:	02f99223          	sh	a5,36(s3)
    80005936:	bf25                	j	8000586e <sys_open+0xa2>
    itrunc(ip);
    80005938:	8526                	mv	a0,s1
    8000593a:	ffffe097          	auipc	ra,0xffffe
    8000593e:	00e080e7          	jalr	14(ra) # 80003948 <itrunc>
    80005942:	bfa9                	j	8000589c <sys_open+0xd0>
      fileclose(f);
    80005944:	854e                	mv	a0,s3
    80005946:	fffff097          	auipc	ra,0xfffff
    8000594a:	d82080e7          	jalr	-638(ra) # 800046c8 <fileclose>
    iunlockput(ip);
    8000594e:	8526                	mv	a0,s1
    80005950:	ffffe097          	auipc	ra,0xffffe
    80005954:	14c080e7          	jalr	332(ra) # 80003a9c <iunlockput>
    end_op();
    80005958:	fffff097          	auipc	ra,0xfffff
    8000595c:	924080e7          	jalr	-1756(ra) # 8000427c <end_op>
    return -1;
    80005960:	557d                	li	a0,-1
    80005962:	b7b9                	j	800058b0 <sys_open+0xe4>

0000000080005964 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005964:	7175                	addi	sp,sp,-144
    80005966:	e506                	sd	ra,136(sp)
    80005968:	e122                	sd	s0,128(sp)
    8000596a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000596c:	fffff097          	auipc	ra,0xfffff
    80005970:	890080e7          	jalr	-1904(ra) # 800041fc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005974:	08000613          	li	a2,128
    80005978:	f7040593          	addi	a1,s0,-144
    8000597c:	4501                	li	a0,0
    8000597e:	ffffd097          	auipc	ra,0xffffd
    80005982:	25e080e7          	jalr	606(ra) # 80002bdc <argstr>
    80005986:	02054963          	bltz	a0,800059b8 <sys_mkdir+0x54>
    8000598a:	4681                	li	a3,0
    8000598c:	4601                	li	a2,0
    8000598e:	4585                	li	a1,1
    80005990:	f7040513          	addi	a0,s0,-144
    80005994:	fffff097          	auipc	ra,0xfffff
    80005998:	7fe080e7          	jalr	2046(ra) # 80005192 <create>
    8000599c:	cd11                	beqz	a0,800059b8 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000599e:	ffffe097          	auipc	ra,0xffffe
    800059a2:	0fe080e7          	jalr	254(ra) # 80003a9c <iunlockput>
  end_op();
    800059a6:	fffff097          	auipc	ra,0xfffff
    800059aa:	8d6080e7          	jalr	-1834(ra) # 8000427c <end_op>
  return 0;
    800059ae:	4501                	li	a0,0
}
    800059b0:	60aa                	ld	ra,136(sp)
    800059b2:	640a                	ld	s0,128(sp)
    800059b4:	6149                	addi	sp,sp,144
    800059b6:	8082                	ret
    end_op();
    800059b8:	fffff097          	auipc	ra,0xfffff
    800059bc:	8c4080e7          	jalr	-1852(ra) # 8000427c <end_op>
    return -1;
    800059c0:	557d                	li	a0,-1
    800059c2:	b7fd                	j	800059b0 <sys_mkdir+0x4c>

00000000800059c4 <sys_mknod>:

uint64
sys_mknod(void)
{
    800059c4:	7135                	addi	sp,sp,-160
    800059c6:	ed06                	sd	ra,152(sp)
    800059c8:	e922                	sd	s0,144(sp)
    800059ca:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800059cc:	fffff097          	auipc	ra,0xfffff
    800059d0:	830080e7          	jalr	-2000(ra) # 800041fc <begin_op>
  argint(1, &major);
    800059d4:	f6c40593          	addi	a1,s0,-148
    800059d8:	4505                	li	a0,1
    800059da:	ffffd097          	auipc	ra,0xffffd
    800059de:	1c2080e7          	jalr	450(ra) # 80002b9c <argint>
  argint(2, &minor);
    800059e2:	f6840593          	addi	a1,s0,-152
    800059e6:	4509                	li	a0,2
    800059e8:	ffffd097          	auipc	ra,0xffffd
    800059ec:	1b4080e7          	jalr	436(ra) # 80002b9c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059f0:	08000613          	li	a2,128
    800059f4:	f7040593          	addi	a1,s0,-144
    800059f8:	4501                	li	a0,0
    800059fa:	ffffd097          	auipc	ra,0xffffd
    800059fe:	1e2080e7          	jalr	482(ra) # 80002bdc <argstr>
    80005a02:	02054b63          	bltz	a0,80005a38 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a06:	f6841683          	lh	a3,-152(s0)
    80005a0a:	f6c41603          	lh	a2,-148(s0)
    80005a0e:	458d                	li	a1,3
    80005a10:	f7040513          	addi	a0,s0,-144
    80005a14:	fffff097          	auipc	ra,0xfffff
    80005a18:	77e080e7          	jalr	1918(ra) # 80005192 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a1c:	cd11                	beqz	a0,80005a38 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a1e:	ffffe097          	auipc	ra,0xffffe
    80005a22:	07e080e7          	jalr	126(ra) # 80003a9c <iunlockput>
  end_op();
    80005a26:	fffff097          	auipc	ra,0xfffff
    80005a2a:	856080e7          	jalr	-1962(ra) # 8000427c <end_op>
  return 0;
    80005a2e:	4501                	li	a0,0
}
    80005a30:	60ea                	ld	ra,152(sp)
    80005a32:	644a                	ld	s0,144(sp)
    80005a34:	610d                	addi	sp,sp,160
    80005a36:	8082                	ret
    end_op();
    80005a38:	fffff097          	auipc	ra,0xfffff
    80005a3c:	844080e7          	jalr	-1980(ra) # 8000427c <end_op>
    return -1;
    80005a40:	557d                	li	a0,-1
    80005a42:	b7fd                	j	80005a30 <sys_mknod+0x6c>

0000000080005a44 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a44:	7135                	addi	sp,sp,-160
    80005a46:	ed06                	sd	ra,152(sp)
    80005a48:	e922                	sd	s0,144(sp)
    80005a4a:	e526                	sd	s1,136(sp)
    80005a4c:	e14a                	sd	s2,128(sp)
    80005a4e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a50:	ffffc097          	auipc	ra,0xffffc
    80005a54:	f76080e7          	jalr	-138(ra) # 800019c6 <myproc>
    80005a58:	892a                	mv	s2,a0
  
  begin_op();
    80005a5a:	ffffe097          	auipc	ra,0xffffe
    80005a5e:	7a2080e7          	jalr	1954(ra) # 800041fc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a62:	08000613          	li	a2,128
    80005a66:	f6040593          	addi	a1,s0,-160
    80005a6a:	4501                	li	a0,0
    80005a6c:	ffffd097          	auipc	ra,0xffffd
    80005a70:	170080e7          	jalr	368(ra) # 80002bdc <argstr>
    80005a74:	04054b63          	bltz	a0,80005aca <sys_chdir+0x86>
    80005a78:	f6040513          	addi	a0,s0,-160
    80005a7c:	ffffe097          	auipc	ra,0xffffe
    80005a80:	564080e7          	jalr	1380(ra) # 80003fe0 <namei>
    80005a84:	84aa                	mv	s1,a0
    80005a86:	c131                	beqz	a0,80005aca <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a88:	ffffe097          	auipc	ra,0xffffe
    80005a8c:	db2080e7          	jalr	-590(ra) # 8000383a <ilock>
  if(ip->type != T_DIR){
    80005a90:	04449703          	lh	a4,68(s1)
    80005a94:	4785                	li	a5,1
    80005a96:	04f71063          	bne	a4,a5,80005ad6 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a9a:	8526                	mv	a0,s1
    80005a9c:	ffffe097          	auipc	ra,0xffffe
    80005aa0:	e60080e7          	jalr	-416(ra) # 800038fc <iunlock>
  iput(p->cwd);
    80005aa4:	15093503          	ld	a0,336(s2)
    80005aa8:	ffffe097          	auipc	ra,0xffffe
    80005aac:	f4c080e7          	jalr	-180(ra) # 800039f4 <iput>
  end_op();
    80005ab0:	ffffe097          	auipc	ra,0xffffe
    80005ab4:	7cc080e7          	jalr	1996(ra) # 8000427c <end_op>
  p->cwd = ip;
    80005ab8:	14993823          	sd	s1,336(s2)
  return 0;
    80005abc:	4501                	li	a0,0
}
    80005abe:	60ea                	ld	ra,152(sp)
    80005ac0:	644a                	ld	s0,144(sp)
    80005ac2:	64aa                	ld	s1,136(sp)
    80005ac4:	690a                	ld	s2,128(sp)
    80005ac6:	610d                	addi	sp,sp,160
    80005ac8:	8082                	ret
    end_op();
    80005aca:	ffffe097          	auipc	ra,0xffffe
    80005ace:	7b2080e7          	jalr	1970(ra) # 8000427c <end_op>
    return -1;
    80005ad2:	557d                	li	a0,-1
    80005ad4:	b7ed                	j	80005abe <sys_chdir+0x7a>
    iunlockput(ip);
    80005ad6:	8526                	mv	a0,s1
    80005ad8:	ffffe097          	auipc	ra,0xffffe
    80005adc:	fc4080e7          	jalr	-60(ra) # 80003a9c <iunlockput>
    end_op();
    80005ae0:	ffffe097          	auipc	ra,0xffffe
    80005ae4:	79c080e7          	jalr	1948(ra) # 8000427c <end_op>
    return -1;
    80005ae8:	557d                	li	a0,-1
    80005aea:	bfd1                	j	80005abe <sys_chdir+0x7a>

0000000080005aec <sys_exec>:

uint64
sys_exec(void)
{
    80005aec:	7145                	addi	sp,sp,-464
    80005aee:	e786                	sd	ra,456(sp)
    80005af0:	e3a2                	sd	s0,448(sp)
    80005af2:	ff26                	sd	s1,440(sp)
    80005af4:	fb4a                	sd	s2,432(sp)
    80005af6:	f74e                	sd	s3,424(sp)
    80005af8:	f352                	sd	s4,416(sp)
    80005afa:	ef56                	sd	s5,408(sp)
    80005afc:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005afe:	e3840593          	addi	a1,s0,-456
    80005b02:	4505                	li	a0,1
    80005b04:	ffffd097          	auipc	ra,0xffffd
    80005b08:	0b8080e7          	jalr	184(ra) # 80002bbc <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005b0c:	08000613          	li	a2,128
    80005b10:	f4040593          	addi	a1,s0,-192
    80005b14:	4501                	li	a0,0
    80005b16:	ffffd097          	auipc	ra,0xffffd
    80005b1a:	0c6080e7          	jalr	198(ra) # 80002bdc <argstr>
    80005b1e:	87aa                	mv	a5,a0
    return -1;
    80005b20:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005b22:	0c07c263          	bltz	a5,80005be6 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005b26:	10000613          	li	a2,256
    80005b2a:	4581                	li	a1,0
    80005b2c:	e4040513          	addi	a0,s0,-448
    80005b30:	ffffb097          	auipc	ra,0xffffb
    80005b34:	1b6080e7          	jalr	438(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b38:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b3c:	89a6                	mv	s3,s1
    80005b3e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b40:	02000a13          	li	s4,32
    80005b44:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b48:	00391513          	slli	a0,s2,0x3
    80005b4c:	e3040593          	addi	a1,s0,-464
    80005b50:	e3843783          	ld	a5,-456(s0)
    80005b54:	953e                	add	a0,a0,a5
    80005b56:	ffffd097          	auipc	ra,0xffffd
    80005b5a:	fa8080e7          	jalr	-88(ra) # 80002afe <fetchaddr>
    80005b5e:	02054a63          	bltz	a0,80005b92 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005b62:	e3043783          	ld	a5,-464(s0)
    80005b66:	c3b9                	beqz	a5,80005bac <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b68:	ffffb097          	auipc	ra,0xffffb
    80005b6c:	f92080e7          	jalr	-110(ra) # 80000afa <kalloc>
    80005b70:	85aa                	mv	a1,a0
    80005b72:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b76:	cd11                	beqz	a0,80005b92 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b78:	6605                	lui	a2,0x1
    80005b7a:	e3043503          	ld	a0,-464(s0)
    80005b7e:	ffffd097          	auipc	ra,0xffffd
    80005b82:	fd2080e7          	jalr	-46(ra) # 80002b50 <fetchstr>
    80005b86:	00054663          	bltz	a0,80005b92 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005b8a:	0905                	addi	s2,s2,1
    80005b8c:	09a1                	addi	s3,s3,8
    80005b8e:	fb491be3          	bne	s2,s4,80005b44 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b92:	10048913          	addi	s2,s1,256
    80005b96:	6088                	ld	a0,0(s1)
    80005b98:	c531                	beqz	a0,80005be4 <sys_exec+0xf8>
    kfree(argv[i]);
    80005b9a:	ffffb097          	auipc	ra,0xffffb
    80005b9e:	e64080e7          	jalr	-412(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ba2:	04a1                	addi	s1,s1,8
    80005ba4:	ff2499e3          	bne	s1,s2,80005b96 <sys_exec+0xaa>
  return -1;
    80005ba8:	557d                	li	a0,-1
    80005baa:	a835                	j	80005be6 <sys_exec+0xfa>
      argv[i] = 0;
    80005bac:	0a8e                	slli	s5,s5,0x3
    80005bae:	fc040793          	addi	a5,s0,-64
    80005bb2:	9abe                	add	s5,s5,a5
    80005bb4:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005bb8:	e4040593          	addi	a1,s0,-448
    80005bbc:	f4040513          	addi	a0,s0,-192
    80005bc0:	fffff097          	auipc	ra,0xfffff
    80005bc4:	190080e7          	jalr	400(ra) # 80004d50 <exec>
    80005bc8:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bca:	10048993          	addi	s3,s1,256
    80005bce:	6088                	ld	a0,0(s1)
    80005bd0:	c901                	beqz	a0,80005be0 <sys_exec+0xf4>
    kfree(argv[i]);
    80005bd2:	ffffb097          	auipc	ra,0xffffb
    80005bd6:	e2c080e7          	jalr	-468(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bda:	04a1                	addi	s1,s1,8
    80005bdc:	ff3499e3          	bne	s1,s3,80005bce <sys_exec+0xe2>
  return ret;
    80005be0:	854a                	mv	a0,s2
    80005be2:	a011                	j	80005be6 <sys_exec+0xfa>
  return -1;
    80005be4:	557d                	li	a0,-1
}
    80005be6:	60be                	ld	ra,456(sp)
    80005be8:	641e                	ld	s0,448(sp)
    80005bea:	74fa                	ld	s1,440(sp)
    80005bec:	795a                	ld	s2,432(sp)
    80005bee:	79ba                	ld	s3,424(sp)
    80005bf0:	7a1a                	ld	s4,416(sp)
    80005bf2:	6afa                	ld	s5,408(sp)
    80005bf4:	6179                	addi	sp,sp,464
    80005bf6:	8082                	ret

0000000080005bf8 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005bf8:	7139                	addi	sp,sp,-64
    80005bfa:	fc06                	sd	ra,56(sp)
    80005bfc:	f822                	sd	s0,48(sp)
    80005bfe:	f426                	sd	s1,40(sp)
    80005c00:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c02:	ffffc097          	auipc	ra,0xffffc
    80005c06:	dc4080e7          	jalr	-572(ra) # 800019c6 <myproc>
    80005c0a:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005c0c:	fd840593          	addi	a1,s0,-40
    80005c10:	4501                	li	a0,0
    80005c12:	ffffd097          	auipc	ra,0xffffd
    80005c16:	faa080e7          	jalr	-86(ra) # 80002bbc <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005c1a:	fc840593          	addi	a1,s0,-56
    80005c1e:	fd040513          	addi	a0,s0,-48
    80005c22:	fffff097          	auipc	ra,0xfffff
    80005c26:	dd6080e7          	jalr	-554(ra) # 800049f8 <pipealloc>
    return -1;
    80005c2a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c2c:	0c054463          	bltz	a0,80005cf4 <sys_pipe+0xfc>
  fd0 = -1;
    80005c30:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c34:	fd043503          	ld	a0,-48(s0)
    80005c38:	fffff097          	auipc	ra,0xfffff
    80005c3c:	518080e7          	jalr	1304(ra) # 80005150 <fdalloc>
    80005c40:	fca42223          	sw	a0,-60(s0)
    80005c44:	08054b63          	bltz	a0,80005cda <sys_pipe+0xe2>
    80005c48:	fc843503          	ld	a0,-56(s0)
    80005c4c:	fffff097          	auipc	ra,0xfffff
    80005c50:	504080e7          	jalr	1284(ra) # 80005150 <fdalloc>
    80005c54:	fca42023          	sw	a0,-64(s0)
    80005c58:	06054863          	bltz	a0,80005cc8 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c5c:	4691                	li	a3,4
    80005c5e:	fc440613          	addi	a2,s0,-60
    80005c62:	fd843583          	ld	a1,-40(s0)
    80005c66:	68a8                	ld	a0,80(s1)
    80005c68:	ffffc097          	auipc	ra,0xffffc
    80005c6c:	a1c080e7          	jalr	-1508(ra) # 80001684 <copyout>
    80005c70:	02054063          	bltz	a0,80005c90 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c74:	4691                	li	a3,4
    80005c76:	fc040613          	addi	a2,s0,-64
    80005c7a:	fd843583          	ld	a1,-40(s0)
    80005c7e:	0591                	addi	a1,a1,4
    80005c80:	68a8                	ld	a0,80(s1)
    80005c82:	ffffc097          	auipc	ra,0xffffc
    80005c86:	a02080e7          	jalr	-1534(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c8a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c8c:	06055463          	bgez	a0,80005cf4 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005c90:	fc442783          	lw	a5,-60(s0)
    80005c94:	07e9                	addi	a5,a5,26
    80005c96:	078e                	slli	a5,a5,0x3
    80005c98:	97a6                	add	a5,a5,s1
    80005c9a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c9e:	fc042503          	lw	a0,-64(s0)
    80005ca2:	0569                	addi	a0,a0,26
    80005ca4:	050e                	slli	a0,a0,0x3
    80005ca6:	94aa                	add	s1,s1,a0
    80005ca8:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005cac:	fd043503          	ld	a0,-48(s0)
    80005cb0:	fffff097          	auipc	ra,0xfffff
    80005cb4:	a18080e7          	jalr	-1512(ra) # 800046c8 <fileclose>
    fileclose(wf);
    80005cb8:	fc843503          	ld	a0,-56(s0)
    80005cbc:	fffff097          	auipc	ra,0xfffff
    80005cc0:	a0c080e7          	jalr	-1524(ra) # 800046c8 <fileclose>
    return -1;
    80005cc4:	57fd                	li	a5,-1
    80005cc6:	a03d                	j	80005cf4 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005cc8:	fc442783          	lw	a5,-60(s0)
    80005ccc:	0007c763          	bltz	a5,80005cda <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005cd0:	07e9                	addi	a5,a5,26
    80005cd2:	078e                	slli	a5,a5,0x3
    80005cd4:	94be                	add	s1,s1,a5
    80005cd6:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005cda:	fd043503          	ld	a0,-48(s0)
    80005cde:	fffff097          	auipc	ra,0xfffff
    80005ce2:	9ea080e7          	jalr	-1558(ra) # 800046c8 <fileclose>
    fileclose(wf);
    80005ce6:	fc843503          	ld	a0,-56(s0)
    80005cea:	fffff097          	auipc	ra,0xfffff
    80005cee:	9de080e7          	jalr	-1570(ra) # 800046c8 <fileclose>
    return -1;
    80005cf2:	57fd                	li	a5,-1
}
    80005cf4:	853e                	mv	a0,a5
    80005cf6:	70e2                	ld	ra,56(sp)
    80005cf8:	7442                	ld	s0,48(sp)
    80005cfa:	74a2                	ld	s1,40(sp)
    80005cfc:	6121                	addi	sp,sp,64
    80005cfe:	8082                	ret

0000000080005d00 <kernelvec>:
    80005d00:	7111                	addi	sp,sp,-256
    80005d02:	e006                	sd	ra,0(sp)
    80005d04:	e40a                	sd	sp,8(sp)
    80005d06:	e80e                	sd	gp,16(sp)
    80005d08:	ec12                	sd	tp,24(sp)
    80005d0a:	f016                	sd	t0,32(sp)
    80005d0c:	f41a                	sd	t1,40(sp)
    80005d0e:	f81e                	sd	t2,48(sp)
    80005d10:	fc22                	sd	s0,56(sp)
    80005d12:	e0a6                	sd	s1,64(sp)
    80005d14:	e4aa                	sd	a0,72(sp)
    80005d16:	e8ae                	sd	a1,80(sp)
    80005d18:	ecb2                	sd	a2,88(sp)
    80005d1a:	f0b6                	sd	a3,96(sp)
    80005d1c:	f4ba                	sd	a4,104(sp)
    80005d1e:	f8be                	sd	a5,112(sp)
    80005d20:	fcc2                	sd	a6,120(sp)
    80005d22:	e146                	sd	a7,128(sp)
    80005d24:	e54a                	sd	s2,136(sp)
    80005d26:	e94e                	sd	s3,144(sp)
    80005d28:	ed52                	sd	s4,152(sp)
    80005d2a:	f156                	sd	s5,160(sp)
    80005d2c:	f55a                	sd	s6,168(sp)
    80005d2e:	f95e                	sd	s7,176(sp)
    80005d30:	fd62                	sd	s8,184(sp)
    80005d32:	e1e6                	sd	s9,192(sp)
    80005d34:	e5ea                	sd	s10,200(sp)
    80005d36:	e9ee                	sd	s11,208(sp)
    80005d38:	edf2                	sd	t3,216(sp)
    80005d3a:	f1f6                	sd	t4,224(sp)
    80005d3c:	f5fa                	sd	t5,232(sp)
    80005d3e:	f9fe                	sd	t6,240(sp)
    80005d40:	c8bfc0ef          	jal	ra,800029ca <kerneltrap>
    80005d44:	6082                	ld	ra,0(sp)
    80005d46:	6122                	ld	sp,8(sp)
    80005d48:	61c2                	ld	gp,16(sp)
    80005d4a:	7282                	ld	t0,32(sp)
    80005d4c:	7322                	ld	t1,40(sp)
    80005d4e:	73c2                	ld	t2,48(sp)
    80005d50:	7462                	ld	s0,56(sp)
    80005d52:	6486                	ld	s1,64(sp)
    80005d54:	6526                	ld	a0,72(sp)
    80005d56:	65c6                	ld	a1,80(sp)
    80005d58:	6666                	ld	a2,88(sp)
    80005d5a:	7686                	ld	a3,96(sp)
    80005d5c:	7726                	ld	a4,104(sp)
    80005d5e:	77c6                	ld	a5,112(sp)
    80005d60:	7866                	ld	a6,120(sp)
    80005d62:	688a                	ld	a7,128(sp)
    80005d64:	692a                	ld	s2,136(sp)
    80005d66:	69ca                	ld	s3,144(sp)
    80005d68:	6a6a                	ld	s4,152(sp)
    80005d6a:	7a8a                	ld	s5,160(sp)
    80005d6c:	7b2a                	ld	s6,168(sp)
    80005d6e:	7bca                	ld	s7,176(sp)
    80005d70:	7c6a                	ld	s8,184(sp)
    80005d72:	6c8e                	ld	s9,192(sp)
    80005d74:	6d2e                	ld	s10,200(sp)
    80005d76:	6dce                	ld	s11,208(sp)
    80005d78:	6e6e                	ld	t3,216(sp)
    80005d7a:	7e8e                	ld	t4,224(sp)
    80005d7c:	7f2e                	ld	t5,232(sp)
    80005d7e:	7fce                	ld	t6,240(sp)
    80005d80:	6111                	addi	sp,sp,256
    80005d82:	10200073          	sret
    80005d86:	00000013          	nop
    80005d8a:	00000013          	nop
    80005d8e:	0001                	nop

0000000080005d90 <timervec>:
    80005d90:	34051573          	csrrw	a0,mscratch,a0
    80005d94:	e10c                	sd	a1,0(a0)
    80005d96:	e510                	sd	a2,8(a0)
    80005d98:	e914                	sd	a3,16(a0)
    80005d9a:	6d0c                	ld	a1,24(a0)
    80005d9c:	7110                	ld	a2,32(a0)
    80005d9e:	6194                	ld	a3,0(a1)
    80005da0:	96b2                	add	a3,a3,a2
    80005da2:	e194                	sd	a3,0(a1)
    80005da4:	4589                	li	a1,2
    80005da6:	14459073          	csrw	sip,a1
    80005daa:	6914                	ld	a3,16(a0)
    80005dac:	6510                	ld	a2,8(a0)
    80005dae:	610c                	ld	a1,0(a0)
    80005db0:	34051573          	csrrw	a0,mscratch,a0
    80005db4:	30200073          	mret
	...

0000000080005dba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005dba:	1141                	addi	sp,sp,-16
    80005dbc:	e422                	sd	s0,8(sp)
    80005dbe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005dc0:	0c0007b7          	lui	a5,0xc000
    80005dc4:	4705                	li	a4,1
    80005dc6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005dc8:	c3d8                	sw	a4,4(a5)
}
    80005dca:	6422                	ld	s0,8(sp)
    80005dcc:	0141                	addi	sp,sp,16
    80005dce:	8082                	ret

0000000080005dd0 <plicinithart>:

void
plicinithart(void)
{
    80005dd0:	1141                	addi	sp,sp,-16
    80005dd2:	e406                	sd	ra,8(sp)
    80005dd4:	e022                	sd	s0,0(sp)
    80005dd6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005dd8:	ffffc097          	auipc	ra,0xffffc
    80005ddc:	bc2080e7          	jalr	-1086(ra) # 8000199a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005de0:	0085171b          	slliw	a4,a0,0x8
    80005de4:	0c0027b7          	lui	a5,0xc002
    80005de8:	97ba                	add	a5,a5,a4
    80005dea:	40200713          	li	a4,1026
    80005dee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005df2:	00d5151b          	slliw	a0,a0,0xd
    80005df6:	0c2017b7          	lui	a5,0xc201
    80005dfa:	953e                	add	a0,a0,a5
    80005dfc:	00052023          	sw	zero,0(a0)
}
    80005e00:	60a2                	ld	ra,8(sp)
    80005e02:	6402                	ld	s0,0(sp)
    80005e04:	0141                	addi	sp,sp,16
    80005e06:	8082                	ret

0000000080005e08 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e08:	1141                	addi	sp,sp,-16
    80005e0a:	e406                	sd	ra,8(sp)
    80005e0c:	e022                	sd	s0,0(sp)
    80005e0e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e10:	ffffc097          	auipc	ra,0xffffc
    80005e14:	b8a080e7          	jalr	-1142(ra) # 8000199a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e18:	00d5179b          	slliw	a5,a0,0xd
    80005e1c:	0c201537          	lui	a0,0xc201
    80005e20:	953e                	add	a0,a0,a5
  return irq;
}
    80005e22:	4148                	lw	a0,4(a0)
    80005e24:	60a2                	ld	ra,8(sp)
    80005e26:	6402                	ld	s0,0(sp)
    80005e28:	0141                	addi	sp,sp,16
    80005e2a:	8082                	ret

0000000080005e2c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e2c:	1101                	addi	sp,sp,-32
    80005e2e:	ec06                	sd	ra,24(sp)
    80005e30:	e822                	sd	s0,16(sp)
    80005e32:	e426                	sd	s1,8(sp)
    80005e34:	1000                	addi	s0,sp,32
    80005e36:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e38:	ffffc097          	auipc	ra,0xffffc
    80005e3c:	b62080e7          	jalr	-1182(ra) # 8000199a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e40:	00d5151b          	slliw	a0,a0,0xd
    80005e44:	0c2017b7          	lui	a5,0xc201
    80005e48:	97aa                	add	a5,a5,a0
    80005e4a:	c3c4                	sw	s1,4(a5)
}
    80005e4c:	60e2                	ld	ra,24(sp)
    80005e4e:	6442                	ld	s0,16(sp)
    80005e50:	64a2                	ld	s1,8(sp)
    80005e52:	6105                	addi	sp,sp,32
    80005e54:	8082                	ret

0000000080005e56 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e56:	1141                	addi	sp,sp,-16
    80005e58:	e406                	sd	ra,8(sp)
    80005e5a:	e022                	sd	s0,0(sp)
    80005e5c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e5e:	479d                	li	a5,7
    80005e60:	04a7cc63          	blt	a5,a0,80005eb8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005e64:	0001d797          	auipc	a5,0x1d
    80005e68:	99c78793          	addi	a5,a5,-1636 # 80022800 <disk>
    80005e6c:	97aa                	add	a5,a5,a0
    80005e6e:	0187c783          	lbu	a5,24(a5)
    80005e72:	ebb9                	bnez	a5,80005ec8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e74:	00451613          	slli	a2,a0,0x4
    80005e78:	0001d797          	auipc	a5,0x1d
    80005e7c:	98878793          	addi	a5,a5,-1656 # 80022800 <disk>
    80005e80:	6394                	ld	a3,0(a5)
    80005e82:	96b2                	add	a3,a3,a2
    80005e84:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005e88:	6398                	ld	a4,0(a5)
    80005e8a:	9732                	add	a4,a4,a2
    80005e8c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005e90:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005e94:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005e98:	953e                	add	a0,a0,a5
    80005e9a:	4785                	li	a5,1
    80005e9c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005ea0:	0001d517          	auipc	a0,0x1d
    80005ea4:	97850513          	addi	a0,a0,-1672 # 80022818 <disk+0x18>
    80005ea8:	ffffc097          	auipc	ra,0xffffc
    80005eac:	288080e7          	jalr	648(ra) # 80002130 <wakeup>
}
    80005eb0:	60a2                	ld	ra,8(sp)
    80005eb2:	6402                	ld	s0,0(sp)
    80005eb4:	0141                	addi	sp,sp,16
    80005eb6:	8082                	ret
    panic("free_desc 1");
    80005eb8:	00003517          	auipc	a0,0x3
    80005ebc:	98850513          	addi	a0,a0,-1656 # 80008840 <syscalls+0x310>
    80005ec0:	ffffa097          	auipc	ra,0xffffa
    80005ec4:	684080e7          	jalr	1668(ra) # 80000544 <panic>
    panic("free_desc 2");
    80005ec8:	00003517          	auipc	a0,0x3
    80005ecc:	98850513          	addi	a0,a0,-1656 # 80008850 <syscalls+0x320>
    80005ed0:	ffffa097          	auipc	ra,0xffffa
    80005ed4:	674080e7          	jalr	1652(ra) # 80000544 <panic>

0000000080005ed8 <virtio_disk_init>:
{
    80005ed8:	1101                	addi	sp,sp,-32
    80005eda:	ec06                	sd	ra,24(sp)
    80005edc:	e822                	sd	s0,16(sp)
    80005ede:	e426                	sd	s1,8(sp)
    80005ee0:	e04a                	sd	s2,0(sp)
    80005ee2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005ee4:	00003597          	auipc	a1,0x3
    80005ee8:	97c58593          	addi	a1,a1,-1668 # 80008860 <syscalls+0x330>
    80005eec:	0001d517          	auipc	a0,0x1d
    80005ef0:	a3c50513          	addi	a0,a0,-1476 # 80022928 <disk+0x128>
    80005ef4:	ffffb097          	auipc	ra,0xffffb
    80005ef8:	c66080e7          	jalr	-922(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005efc:	100017b7          	lui	a5,0x10001
    80005f00:	4398                	lw	a4,0(a5)
    80005f02:	2701                	sext.w	a4,a4
    80005f04:	747277b7          	lui	a5,0x74727
    80005f08:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f0c:	14f71e63          	bne	a4,a5,80006068 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005f10:	100017b7          	lui	a5,0x10001
    80005f14:	43dc                	lw	a5,4(a5)
    80005f16:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f18:	4709                	li	a4,2
    80005f1a:	14e79763          	bne	a5,a4,80006068 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f1e:	100017b7          	lui	a5,0x10001
    80005f22:	479c                	lw	a5,8(a5)
    80005f24:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005f26:	14e79163          	bne	a5,a4,80006068 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f2a:	100017b7          	lui	a5,0x10001
    80005f2e:	47d8                	lw	a4,12(a5)
    80005f30:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f32:	554d47b7          	lui	a5,0x554d4
    80005f36:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f3a:	12f71763          	bne	a4,a5,80006068 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f3e:	100017b7          	lui	a5,0x10001
    80005f42:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f46:	4705                	li	a4,1
    80005f48:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f4a:	470d                	li	a4,3
    80005f4c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f4e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f50:	c7ffe737          	lui	a4,0xc7ffe
    80005f54:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdaa9f>
    80005f58:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f5a:	2701                	sext.w	a4,a4
    80005f5c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f5e:	472d                	li	a4,11
    80005f60:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005f62:	0707a903          	lw	s2,112(a5)
    80005f66:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005f68:	00897793          	andi	a5,s2,8
    80005f6c:	10078663          	beqz	a5,80006078 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f70:	100017b7          	lui	a5,0x10001
    80005f74:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005f78:	43fc                	lw	a5,68(a5)
    80005f7a:	2781                	sext.w	a5,a5
    80005f7c:	10079663          	bnez	a5,80006088 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f80:	100017b7          	lui	a5,0x10001
    80005f84:	5bdc                	lw	a5,52(a5)
    80005f86:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f88:	10078863          	beqz	a5,80006098 <virtio_disk_init+0x1c0>
  if(max < NUM)
    80005f8c:	471d                	li	a4,7
    80005f8e:	10f77d63          	bgeu	a4,a5,800060a8 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80005f92:	ffffb097          	auipc	ra,0xffffb
    80005f96:	b68080e7          	jalr	-1176(ra) # 80000afa <kalloc>
    80005f9a:	0001d497          	auipc	s1,0x1d
    80005f9e:	86648493          	addi	s1,s1,-1946 # 80022800 <disk>
    80005fa2:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005fa4:	ffffb097          	auipc	ra,0xffffb
    80005fa8:	b56080e7          	jalr	-1194(ra) # 80000afa <kalloc>
    80005fac:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005fae:	ffffb097          	auipc	ra,0xffffb
    80005fb2:	b4c080e7          	jalr	-1204(ra) # 80000afa <kalloc>
    80005fb6:	87aa                	mv	a5,a0
    80005fb8:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005fba:	6088                	ld	a0,0(s1)
    80005fbc:	cd75                	beqz	a0,800060b8 <virtio_disk_init+0x1e0>
    80005fbe:	0001d717          	auipc	a4,0x1d
    80005fc2:	84a73703          	ld	a4,-1974(a4) # 80022808 <disk+0x8>
    80005fc6:	cb6d                	beqz	a4,800060b8 <virtio_disk_init+0x1e0>
    80005fc8:	cbe5                	beqz	a5,800060b8 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    80005fca:	6605                	lui	a2,0x1
    80005fcc:	4581                	li	a1,0
    80005fce:	ffffb097          	auipc	ra,0xffffb
    80005fd2:	d18080e7          	jalr	-744(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005fd6:	0001d497          	auipc	s1,0x1d
    80005fda:	82a48493          	addi	s1,s1,-2006 # 80022800 <disk>
    80005fde:	6605                	lui	a2,0x1
    80005fe0:	4581                	li	a1,0
    80005fe2:	6488                	ld	a0,8(s1)
    80005fe4:	ffffb097          	auipc	ra,0xffffb
    80005fe8:	d02080e7          	jalr	-766(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    80005fec:	6605                	lui	a2,0x1
    80005fee:	4581                	li	a1,0
    80005ff0:	6888                	ld	a0,16(s1)
    80005ff2:	ffffb097          	auipc	ra,0xffffb
    80005ff6:	cf4080e7          	jalr	-780(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005ffa:	100017b7          	lui	a5,0x10001
    80005ffe:	4721                	li	a4,8
    80006000:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006002:	4098                	lw	a4,0(s1)
    80006004:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006008:	40d8                	lw	a4,4(s1)
    8000600a:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000600e:	6498                	ld	a4,8(s1)
    80006010:	0007069b          	sext.w	a3,a4
    80006014:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006018:	9701                	srai	a4,a4,0x20
    8000601a:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000601e:	6898                	ld	a4,16(s1)
    80006020:	0007069b          	sext.w	a3,a4
    80006024:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006028:	9701                	srai	a4,a4,0x20
    8000602a:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000602e:	4685                	li	a3,1
    80006030:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80006032:	4705                	li	a4,1
    80006034:	00d48c23          	sb	a3,24(s1)
    80006038:	00e48ca3          	sb	a4,25(s1)
    8000603c:	00e48d23          	sb	a4,26(s1)
    80006040:	00e48da3          	sb	a4,27(s1)
    80006044:	00e48e23          	sb	a4,28(s1)
    80006048:	00e48ea3          	sb	a4,29(s1)
    8000604c:	00e48f23          	sb	a4,30(s1)
    80006050:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006054:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006058:	0727a823          	sw	s2,112(a5)
}
    8000605c:	60e2                	ld	ra,24(sp)
    8000605e:	6442                	ld	s0,16(sp)
    80006060:	64a2                	ld	s1,8(sp)
    80006062:	6902                	ld	s2,0(sp)
    80006064:	6105                	addi	sp,sp,32
    80006066:	8082                	ret
    panic("could not find virtio disk");
    80006068:	00003517          	auipc	a0,0x3
    8000606c:	80850513          	addi	a0,a0,-2040 # 80008870 <syscalls+0x340>
    80006070:	ffffa097          	auipc	ra,0xffffa
    80006074:	4d4080e7          	jalr	1236(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006078:	00003517          	auipc	a0,0x3
    8000607c:	81850513          	addi	a0,a0,-2024 # 80008890 <syscalls+0x360>
    80006080:	ffffa097          	auipc	ra,0xffffa
    80006084:	4c4080e7          	jalr	1220(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80006088:	00003517          	auipc	a0,0x3
    8000608c:	82850513          	addi	a0,a0,-2008 # 800088b0 <syscalls+0x380>
    80006090:	ffffa097          	auipc	ra,0xffffa
    80006094:	4b4080e7          	jalr	1204(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80006098:	00003517          	auipc	a0,0x3
    8000609c:	83850513          	addi	a0,a0,-1992 # 800088d0 <syscalls+0x3a0>
    800060a0:	ffffa097          	auipc	ra,0xffffa
    800060a4:	4a4080e7          	jalr	1188(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    800060a8:	00003517          	auipc	a0,0x3
    800060ac:	84850513          	addi	a0,a0,-1976 # 800088f0 <syscalls+0x3c0>
    800060b0:	ffffa097          	auipc	ra,0xffffa
    800060b4:	494080e7          	jalr	1172(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    800060b8:	00003517          	auipc	a0,0x3
    800060bc:	85850513          	addi	a0,a0,-1960 # 80008910 <syscalls+0x3e0>
    800060c0:	ffffa097          	auipc	ra,0xffffa
    800060c4:	484080e7          	jalr	1156(ra) # 80000544 <panic>

00000000800060c8 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800060c8:	7159                	addi	sp,sp,-112
    800060ca:	f486                	sd	ra,104(sp)
    800060cc:	f0a2                	sd	s0,96(sp)
    800060ce:	eca6                	sd	s1,88(sp)
    800060d0:	e8ca                	sd	s2,80(sp)
    800060d2:	e4ce                	sd	s3,72(sp)
    800060d4:	e0d2                	sd	s4,64(sp)
    800060d6:	fc56                	sd	s5,56(sp)
    800060d8:	f85a                	sd	s6,48(sp)
    800060da:	f45e                	sd	s7,40(sp)
    800060dc:	f062                	sd	s8,32(sp)
    800060de:	ec66                	sd	s9,24(sp)
    800060e0:	e86a                	sd	s10,16(sp)
    800060e2:	1880                	addi	s0,sp,112
    800060e4:	892a                	mv	s2,a0
    800060e6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800060e8:	00c52c83          	lw	s9,12(a0)
    800060ec:	001c9c9b          	slliw	s9,s9,0x1
    800060f0:	1c82                	slli	s9,s9,0x20
    800060f2:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800060f6:	0001d517          	auipc	a0,0x1d
    800060fa:	83250513          	addi	a0,a0,-1998 # 80022928 <disk+0x128>
    800060fe:	ffffb097          	auipc	ra,0xffffb
    80006102:	aec080e7          	jalr	-1300(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    80006106:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006108:	4ba1                	li	s7,8
      disk.free[i] = 0;
    8000610a:	0001cb17          	auipc	s6,0x1c
    8000610e:	6f6b0b13          	addi	s6,s6,1782 # 80022800 <disk>
  for(int i = 0; i < 3; i++){
    80006112:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006114:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006116:	0001dc17          	auipc	s8,0x1d
    8000611a:	812c0c13          	addi	s8,s8,-2030 # 80022928 <disk+0x128>
    8000611e:	a8b5                	j	8000619a <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    80006120:	00fb06b3          	add	a3,s6,a5
    80006124:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006128:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000612a:	0207c563          	bltz	a5,80006154 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000612e:	2485                	addiw	s1,s1,1
    80006130:	0711                	addi	a4,a4,4
    80006132:	1f548a63          	beq	s1,s5,80006326 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    80006136:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006138:	0001c697          	auipc	a3,0x1c
    8000613c:	6c868693          	addi	a3,a3,1736 # 80022800 <disk>
    80006140:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006142:	0186c583          	lbu	a1,24(a3)
    80006146:	fde9                	bnez	a1,80006120 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006148:	2785                	addiw	a5,a5,1
    8000614a:	0685                	addi	a3,a3,1
    8000614c:	ff779be3          	bne	a5,s7,80006142 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006150:	57fd                	li	a5,-1
    80006152:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006154:	02905a63          	blez	s1,80006188 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006158:	f9042503          	lw	a0,-112(s0)
    8000615c:	00000097          	auipc	ra,0x0
    80006160:	cfa080e7          	jalr	-774(ra) # 80005e56 <free_desc>
      for(int j = 0; j < i; j++)
    80006164:	4785                	li	a5,1
    80006166:	0297d163          	bge	a5,s1,80006188 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000616a:	f9442503          	lw	a0,-108(s0)
    8000616e:	00000097          	auipc	ra,0x0
    80006172:	ce8080e7          	jalr	-792(ra) # 80005e56 <free_desc>
      for(int j = 0; j < i; j++)
    80006176:	4789                	li	a5,2
    80006178:	0097d863          	bge	a5,s1,80006188 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000617c:	f9842503          	lw	a0,-104(s0)
    80006180:	00000097          	auipc	ra,0x0
    80006184:	cd6080e7          	jalr	-810(ra) # 80005e56 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006188:	85e2                	mv	a1,s8
    8000618a:	0001c517          	auipc	a0,0x1c
    8000618e:	68e50513          	addi	a0,a0,1678 # 80022818 <disk+0x18>
    80006192:	ffffc097          	auipc	ra,0xffffc
    80006196:	f3a080e7          	jalr	-198(ra) # 800020cc <sleep>
  for(int i = 0; i < 3; i++){
    8000619a:	f9040713          	addi	a4,s0,-112
    8000619e:	84ce                	mv	s1,s3
    800061a0:	bf59                	j	80006136 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800061a2:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    800061a6:	00479693          	slli	a3,a5,0x4
    800061aa:	0001c797          	auipc	a5,0x1c
    800061ae:	65678793          	addi	a5,a5,1622 # 80022800 <disk>
    800061b2:	97b6                	add	a5,a5,a3
    800061b4:	4685                	li	a3,1
    800061b6:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800061b8:	0001c597          	auipc	a1,0x1c
    800061bc:	64858593          	addi	a1,a1,1608 # 80022800 <disk>
    800061c0:	00a60793          	addi	a5,a2,10
    800061c4:	0792                	slli	a5,a5,0x4
    800061c6:	97ae                	add	a5,a5,a1
    800061c8:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    800061cc:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800061d0:	f6070693          	addi	a3,a4,-160
    800061d4:	619c                	ld	a5,0(a1)
    800061d6:	97b6                	add	a5,a5,a3
    800061d8:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800061da:	6188                	ld	a0,0(a1)
    800061dc:	96aa                	add	a3,a3,a0
    800061de:	47c1                	li	a5,16
    800061e0:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800061e2:	4785                	li	a5,1
    800061e4:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    800061e8:	f9442783          	lw	a5,-108(s0)
    800061ec:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800061f0:	0792                	slli	a5,a5,0x4
    800061f2:	953e                	add	a0,a0,a5
    800061f4:	05890693          	addi	a3,s2,88
    800061f8:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    800061fa:	6188                	ld	a0,0(a1)
    800061fc:	97aa                	add	a5,a5,a0
    800061fe:	40000693          	li	a3,1024
    80006202:	c794                	sw	a3,8(a5)
  if(write)
    80006204:	100d0d63          	beqz	s10,8000631e <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006208:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000620c:	00c7d683          	lhu	a3,12(a5)
    80006210:	0016e693          	ori	a3,a3,1
    80006214:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    80006218:	f9842583          	lw	a1,-104(s0)
    8000621c:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006220:	0001c697          	auipc	a3,0x1c
    80006224:	5e068693          	addi	a3,a3,1504 # 80022800 <disk>
    80006228:	00260793          	addi	a5,a2,2
    8000622c:	0792                	slli	a5,a5,0x4
    8000622e:	97b6                	add	a5,a5,a3
    80006230:	587d                	li	a6,-1
    80006232:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006236:	0592                	slli	a1,a1,0x4
    80006238:	952e                	add	a0,a0,a1
    8000623a:	f9070713          	addi	a4,a4,-112
    8000623e:	9736                	add	a4,a4,a3
    80006240:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    80006242:	6298                	ld	a4,0(a3)
    80006244:	972e                	add	a4,a4,a1
    80006246:	4585                	li	a1,1
    80006248:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000624a:	4509                	li	a0,2
    8000624c:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    80006250:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006254:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006258:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    8000625c:	6698                	ld	a4,8(a3)
    8000625e:	00275783          	lhu	a5,2(a4)
    80006262:	8b9d                	andi	a5,a5,7
    80006264:	0786                	slli	a5,a5,0x1
    80006266:	97ba                	add	a5,a5,a4
    80006268:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    8000626c:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006270:	6698                	ld	a4,8(a3)
    80006272:	00275783          	lhu	a5,2(a4)
    80006276:	2785                	addiw	a5,a5,1
    80006278:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    8000627c:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006280:	100017b7          	lui	a5,0x10001
    80006284:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006288:	00492703          	lw	a4,4(s2)
    8000628c:	4785                	li	a5,1
    8000628e:	02f71163          	bne	a4,a5,800062b0 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    80006292:	0001c997          	auipc	s3,0x1c
    80006296:	69698993          	addi	s3,s3,1686 # 80022928 <disk+0x128>
  while(b->disk == 1) {
    8000629a:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000629c:	85ce                	mv	a1,s3
    8000629e:	854a                	mv	a0,s2
    800062a0:	ffffc097          	auipc	ra,0xffffc
    800062a4:	e2c080e7          	jalr	-468(ra) # 800020cc <sleep>
  while(b->disk == 1) {
    800062a8:	00492783          	lw	a5,4(s2)
    800062ac:	fe9788e3          	beq	a5,s1,8000629c <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    800062b0:	f9042903          	lw	s2,-112(s0)
    800062b4:	00290793          	addi	a5,s2,2
    800062b8:	00479713          	slli	a4,a5,0x4
    800062bc:	0001c797          	auipc	a5,0x1c
    800062c0:	54478793          	addi	a5,a5,1348 # 80022800 <disk>
    800062c4:	97ba                	add	a5,a5,a4
    800062c6:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800062ca:	0001c997          	auipc	s3,0x1c
    800062ce:	53698993          	addi	s3,s3,1334 # 80022800 <disk>
    800062d2:	00491713          	slli	a4,s2,0x4
    800062d6:	0009b783          	ld	a5,0(s3)
    800062da:	97ba                	add	a5,a5,a4
    800062dc:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800062e0:	854a                	mv	a0,s2
    800062e2:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800062e6:	00000097          	auipc	ra,0x0
    800062ea:	b70080e7          	jalr	-1168(ra) # 80005e56 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800062ee:	8885                	andi	s1,s1,1
    800062f0:	f0ed                	bnez	s1,800062d2 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800062f2:	0001c517          	auipc	a0,0x1c
    800062f6:	63650513          	addi	a0,a0,1590 # 80022928 <disk+0x128>
    800062fa:	ffffb097          	auipc	ra,0xffffb
    800062fe:	9a4080e7          	jalr	-1628(ra) # 80000c9e <release>
}
    80006302:	70a6                	ld	ra,104(sp)
    80006304:	7406                	ld	s0,96(sp)
    80006306:	64e6                	ld	s1,88(sp)
    80006308:	6946                	ld	s2,80(sp)
    8000630a:	69a6                	ld	s3,72(sp)
    8000630c:	6a06                	ld	s4,64(sp)
    8000630e:	7ae2                	ld	s5,56(sp)
    80006310:	7b42                	ld	s6,48(sp)
    80006312:	7ba2                	ld	s7,40(sp)
    80006314:	7c02                	ld	s8,32(sp)
    80006316:	6ce2                	ld	s9,24(sp)
    80006318:	6d42                	ld	s10,16(sp)
    8000631a:	6165                	addi	sp,sp,112
    8000631c:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000631e:	4689                	li	a3,2
    80006320:	00d79623          	sh	a3,12(a5)
    80006324:	b5e5                	j	8000620c <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006326:	f9042603          	lw	a2,-112(s0)
    8000632a:	00a60713          	addi	a4,a2,10
    8000632e:	0712                	slli	a4,a4,0x4
    80006330:	0001c517          	auipc	a0,0x1c
    80006334:	4d850513          	addi	a0,a0,1240 # 80022808 <disk+0x8>
    80006338:	953a                	add	a0,a0,a4
  if(write)
    8000633a:	e60d14e3          	bnez	s10,800061a2 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    8000633e:	00a60793          	addi	a5,a2,10
    80006342:	00479693          	slli	a3,a5,0x4
    80006346:	0001c797          	auipc	a5,0x1c
    8000634a:	4ba78793          	addi	a5,a5,1210 # 80022800 <disk>
    8000634e:	97b6                	add	a5,a5,a3
    80006350:	0007a423          	sw	zero,8(a5)
    80006354:	b595                	j	800061b8 <virtio_disk_rw+0xf0>

0000000080006356 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006356:	1101                	addi	sp,sp,-32
    80006358:	ec06                	sd	ra,24(sp)
    8000635a:	e822                	sd	s0,16(sp)
    8000635c:	e426                	sd	s1,8(sp)
    8000635e:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006360:	0001c497          	auipc	s1,0x1c
    80006364:	4a048493          	addi	s1,s1,1184 # 80022800 <disk>
    80006368:	0001c517          	auipc	a0,0x1c
    8000636c:	5c050513          	addi	a0,a0,1472 # 80022928 <disk+0x128>
    80006370:	ffffb097          	auipc	ra,0xffffb
    80006374:	87a080e7          	jalr	-1926(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006378:	10001737          	lui	a4,0x10001
    8000637c:	533c                	lw	a5,96(a4)
    8000637e:	8b8d                	andi	a5,a5,3
    80006380:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006382:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006386:	689c                	ld	a5,16(s1)
    80006388:	0204d703          	lhu	a4,32(s1)
    8000638c:	0027d783          	lhu	a5,2(a5)
    80006390:	04f70863          	beq	a4,a5,800063e0 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006394:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006398:	6898                	ld	a4,16(s1)
    8000639a:	0204d783          	lhu	a5,32(s1)
    8000639e:	8b9d                	andi	a5,a5,7
    800063a0:	078e                	slli	a5,a5,0x3
    800063a2:	97ba                	add	a5,a5,a4
    800063a4:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800063a6:	00278713          	addi	a4,a5,2
    800063aa:	0712                	slli	a4,a4,0x4
    800063ac:	9726                	add	a4,a4,s1
    800063ae:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800063b2:	e721                	bnez	a4,800063fa <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800063b4:	0789                	addi	a5,a5,2
    800063b6:	0792                	slli	a5,a5,0x4
    800063b8:	97a6                	add	a5,a5,s1
    800063ba:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800063bc:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800063c0:	ffffc097          	auipc	ra,0xffffc
    800063c4:	d70080e7          	jalr	-656(ra) # 80002130 <wakeup>

    disk.used_idx += 1;
    800063c8:	0204d783          	lhu	a5,32(s1)
    800063cc:	2785                	addiw	a5,a5,1
    800063ce:	17c2                	slli	a5,a5,0x30
    800063d0:	93c1                	srli	a5,a5,0x30
    800063d2:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800063d6:	6898                	ld	a4,16(s1)
    800063d8:	00275703          	lhu	a4,2(a4)
    800063dc:	faf71ce3          	bne	a4,a5,80006394 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800063e0:	0001c517          	auipc	a0,0x1c
    800063e4:	54850513          	addi	a0,a0,1352 # 80022928 <disk+0x128>
    800063e8:	ffffb097          	auipc	ra,0xffffb
    800063ec:	8b6080e7          	jalr	-1866(ra) # 80000c9e <release>
}
    800063f0:	60e2                	ld	ra,24(sp)
    800063f2:	6442                	ld	s0,16(sp)
    800063f4:	64a2                	ld	s1,8(sp)
    800063f6:	6105                	addi	sp,sp,32
    800063f8:	8082                	ret
      panic("virtio_disk_intr status");
    800063fa:	00002517          	auipc	a0,0x2
    800063fe:	52e50513          	addi	a0,a0,1326 # 80008928 <syscalls+0x3f8>
    80006402:	ffffa097          	auipc	ra,0xffffa
    80006406:	142080e7          	jalr	322(ra) # 80000544 <panic>

000000008000640a <sgenrand>:
static int mti=N+1; /* mti==N+1 means mt[N] is not initialized */

/* initializing the array with a NONZERO seed */
void
sgenrand(unsigned long seed)
{
    8000640a:	1141                	addi	sp,sp,-16
    8000640c:	e422                	sd	s0,8(sp)
    8000640e:	0800                	addi	s0,sp,16
    /* setting initial seeds to mt[N] using         */
    /* the generator Line 25 of Table 1 in          */
    /* [KNUTH 1981, The Art of Computer Programming */
    /*    Vol. 2 (2nd Ed.), pp102]                  */
    mt[0]= seed & 0xffffffff;
    80006410:	0001c717          	auipc	a4,0x1c
    80006414:	53070713          	addi	a4,a4,1328 # 80022940 <mt>
    80006418:	1502                	slli	a0,a0,0x20
    8000641a:	9101                	srli	a0,a0,0x20
    8000641c:	e308                	sd	a0,0(a4)
    for (mti=1; mti<N; mti++)
    8000641e:	0001e597          	auipc	a1,0x1e
    80006422:	89a58593          	addi	a1,a1,-1894 # 80023cb8 <mt+0x1378>
        mt[mti] = (69069 * mt[mti-1]) & 0xffffffff;
    80006426:	6645                	lui	a2,0x11
    80006428:	dcd60613          	addi	a2,a2,-563 # 10dcd <_entry-0x7ffef233>
    8000642c:	56fd                	li	a3,-1
    8000642e:	9281                	srli	a3,a3,0x20
    80006430:	631c                	ld	a5,0(a4)
    80006432:	02c787b3          	mul	a5,a5,a2
    80006436:	8ff5                	and	a5,a5,a3
    80006438:	e71c                	sd	a5,8(a4)
    for (mti=1; mti<N; mti++)
    8000643a:	0721                	addi	a4,a4,8
    8000643c:	feb71ae3          	bne	a4,a1,80006430 <sgenrand+0x26>
    80006440:	27000793          	li	a5,624
    80006444:	00002717          	auipc	a4,0x2
    80006448:	50f72a23          	sw	a5,1300(a4) # 80008958 <mti>
}
    8000644c:	6422                	ld	s0,8(sp)
    8000644e:	0141                	addi	sp,sp,16
    80006450:	8082                	ret

0000000080006452 <genrand>:

long /* for integer generation */
genrand()
{
    80006452:	1141                	addi	sp,sp,-16
    80006454:	e406                	sd	ra,8(sp)
    80006456:	e022                	sd	s0,0(sp)
    80006458:	0800                	addi	s0,sp,16
    unsigned long y;
    static unsigned long mag01[2]={0x0, MATRIX_A};
    /* mag01[x] = x * MATRIX_A  for x=0,1 */

    if (mti >= N) { /* generate N words at one time */
    8000645a:	00002797          	auipc	a5,0x2
    8000645e:	4fe7a783          	lw	a5,1278(a5) # 80008958 <mti>
    80006462:	26f00713          	li	a4,623
    80006466:	0ef75963          	bge	a4,a5,80006558 <genrand+0x106>
        int kk;

        if (mti == N+1)   /* if sgenrand() has not been called, */
    8000646a:	27100713          	li	a4,625
    8000646e:	12e78f63          	beq	a5,a4,800065ac <genrand+0x15a>
            sgenrand(4357); /* a default initial seed is used   */

        for (kk=0;kk<N-M;kk++) {
    80006472:	0001c817          	auipc	a6,0x1c
    80006476:	4ce80813          	addi	a6,a6,1230 # 80022940 <mt>
    8000647a:	0001de17          	auipc	t3,0x1d
    8000647e:	bdee0e13          	addi	t3,t3,-1058 # 80023058 <mt+0x718>
{
    80006482:	8742                	mv	a4,a6
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    80006484:	4885                	li	a7,1
    80006486:	08fe                	slli	a7,a7,0x1f
    80006488:	80000537          	lui	a0,0x80000
    8000648c:	fff54513          	not	a0,a0
            mt[kk] = mt[kk+M] ^ (y >> 1) ^ mag01[y & 0x1];
    80006490:	6585                	lui	a1,0x1
    80006492:	c6858593          	addi	a1,a1,-920 # c68 <_entry-0x7ffff398>
    80006496:	00002317          	auipc	t1,0x2
    8000649a:	4aa30313          	addi	t1,t1,1194 # 80008940 <mag01.985>
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    8000649e:	631c                	ld	a5,0(a4)
    800064a0:	0117f7b3          	and	a5,a5,a7
    800064a4:	6714                	ld	a3,8(a4)
    800064a6:	8ee9                	and	a3,a3,a0
    800064a8:	8fd5                	or	a5,a5,a3
            mt[kk] = mt[kk+M] ^ (y >> 1) ^ mag01[y & 0x1];
    800064aa:	00b70633          	add	a2,a4,a1
    800064ae:	0017d693          	srli	a3,a5,0x1
    800064b2:	6210                	ld	a2,0(a2)
    800064b4:	8eb1                	xor	a3,a3,a2
    800064b6:	8b85                	andi	a5,a5,1
    800064b8:	078e                	slli	a5,a5,0x3
    800064ba:	979a                	add	a5,a5,t1
    800064bc:	639c                	ld	a5,0(a5)
    800064be:	8fb5                	xor	a5,a5,a3
    800064c0:	e31c                	sd	a5,0(a4)
        for (kk=0;kk<N-M;kk++) {
    800064c2:	0721                	addi	a4,a4,8
    800064c4:	fdc71de3          	bne	a4,t3,8000649e <genrand+0x4c>
        }
        for (;kk<N-1;kk++) {
    800064c8:	6605                	lui	a2,0x1
    800064ca:	c6060613          	addi	a2,a2,-928 # c60 <_entry-0x7ffff3a0>
    800064ce:	9642                	add	a2,a2,a6
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    800064d0:	4505                	li	a0,1
    800064d2:	057e                	slli	a0,a0,0x1f
    800064d4:	800005b7          	lui	a1,0x80000
    800064d8:	fff5c593          	not	a1,a1
            mt[kk] = mt[kk+(M-N)] ^ (y >> 1) ^ mag01[y & 0x1];
    800064dc:	00002897          	auipc	a7,0x2
    800064e0:	46488893          	addi	a7,a7,1124 # 80008940 <mag01.985>
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    800064e4:	71883783          	ld	a5,1816(a6)
    800064e8:	8fe9                	and	a5,a5,a0
    800064ea:	72083703          	ld	a4,1824(a6)
    800064ee:	8f6d                	and	a4,a4,a1
    800064f0:	8fd9                	or	a5,a5,a4
            mt[kk] = mt[kk+(M-N)] ^ (y >> 1) ^ mag01[y & 0x1];
    800064f2:	0017d713          	srli	a4,a5,0x1
    800064f6:	00083683          	ld	a3,0(a6)
    800064fa:	8f35                	xor	a4,a4,a3
    800064fc:	8b85                	andi	a5,a5,1
    800064fe:	078e                	slli	a5,a5,0x3
    80006500:	97c6                	add	a5,a5,a7
    80006502:	639c                	ld	a5,0(a5)
    80006504:	8fb9                	xor	a5,a5,a4
    80006506:	70f83c23          	sd	a5,1816(a6)
        for (;kk<N-1;kk++) {
    8000650a:	0821                	addi	a6,a6,8
    8000650c:	fcc81ce3          	bne	a6,a2,800064e4 <genrand+0x92>
        }
        y = (mt[N-1]&UPPER_MASK)|(mt[0]&LOWER_MASK);
    80006510:	0001d697          	auipc	a3,0x1d
    80006514:	43068693          	addi	a3,a3,1072 # 80023940 <mt+0x1000>
    80006518:	3786b783          	ld	a5,888(a3)
    8000651c:	4705                	li	a4,1
    8000651e:	077e                	slli	a4,a4,0x1f
    80006520:	8ff9                	and	a5,a5,a4
    80006522:	0001c717          	auipc	a4,0x1c
    80006526:	41e73703          	ld	a4,1054(a4) # 80022940 <mt>
    8000652a:	1706                	slli	a4,a4,0x21
    8000652c:	9305                	srli	a4,a4,0x21
    8000652e:	8fd9                	or	a5,a5,a4
        mt[N-1] = mt[M-1] ^ (y >> 1) ^ mag01[y & 0x1];
    80006530:	0017d713          	srli	a4,a5,0x1
    80006534:	c606b603          	ld	a2,-928(a3)
    80006538:	8f31                	xor	a4,a4,a2
    8000653a:	8b85                	andi	a5,a5,1
    8000653c:	078e                	slli	a5,a5,0x3
    8000653e:	00002617          	auipc	a2,0x2
    80006542:	40260613          	addi	a2,a2,1026 # 80008940 <mag01.985>
    80006546:	97b2                	add	a5,a5,a2
    80006548:	639c                	ld	a5,0(a5)
    8000654a:	8fb9                	xor	a5,a5,a4
    8000654c:	36f6bc23          	sd	a5,888(a3)

        mti = 0;
    80006550:	00002797          	auipc	a5,0x2
    80006554:	4007a423          	sw	zero,1032(a5) # 80008958 <mti>
    }
  
    y = mt[mti++];
    80006558:	00002717          	auipc	a4,0x2
    8000655c:	40070713          	addi	a4,a4,1024 # 80008958 <mti>
    80006560:	431c                	lw	a5,0(a4)
    80006562:	0017869b          	addiw	a3,a5,1
    80006566:	c314                	sw	a3,0(a4)
    80006568:	078e                	slli	a5,a5,0x3
    8000656a:	0001c717          	auipc	a4,0x1c
    8000656e:	3d670713          	addi	a4,a4,982 # 80022940 <mt>
    80006572:	97ba                	add	a5,a5,a4
    80006574:	6398                	ld	a4,0(a5)
    y ^= TEMPERING_SHIFT_U(y);
    80006576:	00b75793          	srli	a5,a4,0xb
    8000657a:	8f3d                	xor	a4,a4,a5
    y ^= TEMPERING_SHIFT_S(y) & TEMPERING_MASK_B;
    8000657c:	013a67b7          	lui	a5,0x13a6
    80006580:	8ad78793          	addi	a5,a5,-1875 # 13a58ad <_entry-0x7ec5a753>
    80006584:	8ff9                	and	a5,a5,a4
    80006586:	079e                	slli	a5,a5,0x7
    80006588:	8fb9                	xor	a5,a5,a4
    y ^= TEMPERING_SHIFT_T(y) & TEMPERING_MASK_C;
    8000658a:	00f79713          	slli	a4,a5,0xf
    8000658e:	077e36b7          	lui	a3,0x77e3
    80006592:	0696                	slli	a3,a3,0x5
    80006594:	8f75                	and	a4,a4,a3
    80006596:	8fb9                	xor	a5,a5,a4
    y ^= TEMPERING_SHIFT_L(y);
    80006598:	0127d513          	srli	a0,a5,0x12
    8000659c:	8fa9                	xor	a5,a5,a0

    // Strip off uppermost bit because we want a long,
    // not an unsigned long
    return y & RAND_MAX;
    8000659e:	02179513          	slli	a0,a5,0x21
}
    800065a2:	9105                	srli	a0,a0,0x21
    800065a4:	60a2                	ld	ra,8(sp)
    800065a6:	6402                	ld	s0,0(sp)
    800065a8:	0141                	addi	sp,sp,16
    800065aa:	8082                	ret
            sgenrand(4357); /* a default initial seed is used   */
    800065ac:	6505                	lui	a0,0x1
    800065ae:	10550513          	addi	a0,a0,261 # 1105 <_entry-0x7fffeefb>
    800065b2:	00000097          	auipc	ra,0x0
    800065b6:	e58080e7          	jalr	-424(ra) # 8000640a <sgenrand>
    800065ba:	bd65                	j	80006472 <genrand+0x20>

00000000800065bc <random_at_most>:

// Assumes 0 <= max <= RAND_MAX
// Returns in the half-open interval [0, max]
long random_at_most(long max) {
    800065bc:	1101                	addi	sp,sp,-32
    800065be:	ec06                	sd	ra,24(sp)
    800065c0:	e822                	sd	s0,16(sp)
    800065c2:	e426                	sd	s1,8(sp)
    800065c4:	e04a                	sd	s2,0(sp)
    800065c6:	1000                	addi	s0,sp,32
  unsigned long
    // max <= RAND_MAX < ULONG_MAX, so this is okay.
    num_bins = (unsigned long) max + 1,
    800065c8:	0505                	addi	a0,a0,1
    num_rand = (unsigned long) RAND_MAX + 1,
    bin_size = num_rand / num_bins,
    800065ca:	4485                	li	s1,1
    800065cc:	04fe                	slli	s1,s1,0x1f
    800065ce:	02a4d933          	divu	s2,s1,a0
    defect   = num_rand % num_bins;
    800065d2:	02a4f533          	remu	a0,s1,a0
  long x;
  do {
   x = genrand();
  }
  // This is carefully written not to overflow
  while (num_rand - defect <= (unsigned long)x);
    800065d6:	4485                	li	s1,1
    800065d8:	04fe                	slli	s1,s1,0x1f
    800065da:	8c89                	sub	s1,s1,a0
   x = genrand();
    800065dc:	00000097          	auipc	ra,0x0
    800065e0:	e76080e7          	jalr	-394(ra) # 80006452 <genrand>
  while (num_rand - defect <= (unsigned long)x);
    800065e4:	fe957ce3          	bgeu	a0,s1,800065dc <random_at_most+0x20>

  // Truncated division is intentional
  return x/bin_size;
    800065e8:	03255533          	divu	a0,a0,s2
    800065ec:	60e2                	ld	ra,24(sp)
    800065ee:	6442                	ld	s0,16(sp)
    800065f0:	64a2                	ld	s1,8(sp)
    800065f2:	6902                	ld	s2,0(sp)
    800065f4:	6105                	addi	sp,sp,32
    800065f6:	8082                	ret
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
