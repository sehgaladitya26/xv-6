
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a6013103          	ld	sp,-1440(sp) # 80008a60 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000056:	a6e70713          	addi	a4,a4,-1426 # 80008ac0 <timer_scratch>
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
    80000068:	cac78793          	addi	a5,a5,-852 # 80005d10 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdbecf>
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
    80000130:	3b0080e7          	jalr	944(ra) # 800024dc <either_copyin>
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
    80000190:	a7450513          	addi	a0,a0,-1420 # 80010c00 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a56080e7          	jalr	-1450(ra) # 80000bea <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	a6448493          	addi	s1,s1,-1436 # 80010c00 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	af290913          	addi	s2,s2,-1294 # 80010c98 <cons+0x98>
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
    800001d0:	15a080e7          	jalr	346(ra) # 80002326 <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	ea4080e7          	jalr	-348(ra) # 8000207e <sleep>
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
    8000021a:	270080e7          	jalr	624(ra) # 80002486 <either_copyout>
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
    8000022e:	9d650513          	addi	a0,a0,-1578 # 80010c00 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a6c080e7          	jalr	-1428(ra) # 80000c9e <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	9c050513          	addi	a0,a0,-1600 # 80010c00 <cons>
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
    8000027c:	a2f72023          	sw	a5,-1504(a4) # 80010c98 <cons+0x98>
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
    800002d6:	92e50513          	addi	a0,a0,-1746 # 80010c00 <cons>
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
    800002fc:	23a080e7          	jalr	570(ra) # 80002532 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00011517          	auipc	a0,0x11
    80000304:	90050513          	addi	a0,a0,-1792 # 80010c00 <cons>
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
    80000328:	8dc70713          	addi	a4,a4,-1828 # 80010c00 <cons>
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
    80000352:	8b278793          	addi	a5,a5,-1870 # 80010c00 <cons>
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
    80000380:	91c7a783          	lw	a5,-1764(a5) # 80010c98 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00011717          	auipc	a4,0x11
    80000394:	87070713          	addi	a4,a4,-1936 # 80010c00 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00011497          	auipc	s1,0x11
    800003a4:	86048493          	addi	s1,s1,-1952 # 80010c00 <cons>
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
    800003e0:	82470713          	addi	a4,a4,-2012 # 80010c00 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00011717          	auipc	a4,0x11
    800003f6:	8af72723          	sw	a5,-1874(a4) # 80010ca0 <cons+0xa0>
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
    8000041c:	7e878793          	addi	a5,a5,2024 # 80010c00 <cons>
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
    80000440:	86c7a023          	sw	a2,-1952(a5) # 80010c9c <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00011517          	auipc	a0,0x11
    80000448:	85450513          	addi	a0,a0,-1964 # 80010c98 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	c96080e7          	jalr	-874(ra) # 800020e2 <wakeup>
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
    8000046a:	79a50513          	addi	a0,a0,1946 # 80010c00 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	6ec080e7          	jalr	1772(ra) # 80000b5a <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00021797          	auipc	a5,0x21
    80000482:	31a78793          	addi	a5,a5,794 # 80021798 <devsw>
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
    80000554:	7607a823          	sw	zero,1904(a5) # 80010cc0 <pr+0x18>
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
    80000588:	4ef72e23          	sw	a5,1276(a4) # 80008a80 <panicked>
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
    800005c4:	700dad83          	lw	s11,1792(s11) # 80010cc0 <pr+0x18>
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
    80000602:	6aa50513          	addi	a0,a0,1706 # 80010ca8 <pr>
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
    80000766:	54650513          	addi	a0,a0,1350 # 80010ca8 <pr>
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
    80000782:	52a48493          	addi	s1,s1,1322 # 80010ca8 <pr>
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
    800007e2:	4ea50513          	addi	a0,a0,1258 # 80010cc8 <uart_tx_lock>
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
    8000080e:	2767a783          	lw	a5,630(a5) # 80008a80 <panicked>
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
    8000084a:	24273703          	ld	a4,578(a4) # 80008a88 <uart_tx_r>
    8000084e:	00008797          	auipc	a5,0x8
    80000852:	2427b783          	ld	a5,578(a5) # 80008a90 <uart_tx_w>
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
    80000874:	458a0a13          	addi	s4,s4,1112 # 80010cc8 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	21048493          	addi	s1,s1,528 # 80008a88 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	21098993          	addi	s3,s3,528 # 80008a90 <uart_tx_w>
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
    800008aa:	83c080e7          	jalr	-1988(ra) # 800020e2 <wakeup>
    
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
    800008e6:	3e650513          	addi	a0,a0,998 # 80010cc8 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	300080e7          	jalr	768(ra) # 80000bea <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	18e7a783          	lw	a5,398(a5) # 80008a80 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008797          	auipc	a5,0x8
    80000900:	1947b783          	ld	a5,404(a5) # 80008a90 <uart_tx_w>
    80000904:	00008717          	auipc	a4,0x8
    80000908:	18473703          	ld	a4,388(a4) # 80008a88 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010a17          	auipc	s4,0x10
    80000914:	3b8a0a13          	addi	s4,s4,952 # 80010cc8 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	17048493          	addi	s1,s1,368 # 80008a88 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	17090913          	addi	s2,s2,368 # 80008a90 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00001097          	auipc	ra,0x1
    80000934:	74e080e7          	jalr	1870(ra) # 8000207e <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	38248493          	addi	s1,s1,898 # 80010cc8 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00008717          	auipc	a4,0x8
    8000095e:	12f73b23          	sd	a5,310(a4) # 80008a90 <uart_tx_w>
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
    800009d4:	2f848493          	addi	s1,s1,760 # 80010cc8 <uart_tx_lock>
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
    80000a12:	00022797          	auipc	a5,0x22
    80000a16:	f1e78793          	addi	a5,a5,-226 # 80022930 <end>
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
    80000a36:	2ce90913          	addi	s2,s2,718 # 80010d00 <kmem>
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
    80000ad2:	23250513          	addi	a0,a0,562 # 80010d00 <kmem>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	084080e7          	jalr	132(ra) # 80000b5a <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ade:	45c5                	li	a1,17
    80000ae0:	05ee                	slli	a1,a1,0x1b
    80000ae2:	00022517          	auipc	a0,0x22
    80000ae6:	e4e50513          	addi	a0,a0,-434 # 80022930 <end>
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
    80000b08:	1fc48493          	addi	s1,s1,508 # 80010d00 <kmem>
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
    80000b20:	1e450513          	addi	a0,a0,484 # 80010d00 <kmem>
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
    80000b4c:	1b850513          	addi	a0,a0,440 # 80010d00 <kmem>
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
    80000ea8:	bf470713          	addi	a4,a4,-1036 # 80008a98 <started>
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
    80000ede:	798080e7          	jalr	1944(ra) # 80002672 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00005097          	auipc	ra,0x5
    80000ee6:	e6e080e7          	jalr	-402(ra) # 80005d50 <plicinithart>
  }

  scheduler();        
    80000eea:	00001097          	auipc	ra,0x1
    80000eee:	fe2080e7          	jalr	-30(ra) # 80001ecc <scheduler>
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
    80000f56:	6f8080e7          	jalr	1784(ra) # 8000264a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00001097          	auipc	ra,0x1
    80000f5e:	718080e7          	jalr	1816(ra) # 80002672 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	dd8080e7          	jalr	-552(ra) # 80005d3a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00005097          	auipc	ra,0x5
    80000f6e:	de6080e7          	jalr	-538(ra) # 80005d50 <plicinithart>
    binit();         // buffer cache
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	fa0080e7          	jalr	-96(ra) # 80002f12 <binit>
    iinit();         // inode table
    80000f7a:	00002097          	auipc	ra,0x2
    80000f7e:	644080e7          	jalr	1604(ra) # 800035be <iinit>
    fileinit();      // file table
    80000f82:	00003097          	auipc	ra,0x3
    80000f86:	5e2080e7          	jalr	1506(ra) # 80004564 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	ece080e7          	jalr	-306(ra) # 80005e58 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	d18080e7          	jalr	-744(ra) # 80001caa <userinit>
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    started = 1;
    80000f9e:	4785                	li	a5,1
    80000fa0:	00008717          	auipc	a4,0x8
    80000fa4:	aef72c23          	sw	a5,-1288(a4) # 80008a98 <started>
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
    80000fb8:	aec7b783          	ld	a5,-1300(a5) # 80008aa0 <kernel_pagetable>
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
    80001274:	82a7b823          	sd	a0,-2000(a5) # 80008aa0 <kernel_pagetable>
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
    8000186a:	8ea48493          	addi	s1,s1,-1814 # 80011150 <proc>
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
    80001884:	cd0a0a13          	addi	s4,s4,-816 # 80017550 <tickslock>
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
    80001906:	41e50513          	addi	a0,a0,1054 # 80010d20 <pid_lock>
    8000190a:	fffff097          	auipc	ra,0xfffff
    8000190e:	250080e7          	jalr	592(ra) # 80000b5a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001912:	00007597          	auipc	a1,0x7
    80001916:	8d658593          	addi	a1,a1,-1834 # 800081e8 <digits+0x1a8>
    8000191a:	0000f517          	auipc	a0,0xf
    8000191e:	41e50513          	addi	a0,a0,1054 # 80010d38 <wait_lock>
    80001922:	fffff097          	auipc	ra,0xfffff
    80001926:	238080e7          	jalr	568(ra) # 80000b5a <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000192a:	00010497          	auipc	s1,0x10
    8000192e:	82648493          	addi	s1,s1,-2010 # 80011150 <proc>
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
    80001950:	c0498993          	addi	s3,s3,-1020 # 80017550 <tickslock>
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
    800019ba:	39a50513          	addi	a0,a0,922 # 80010d50 <cpus>
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
    800019e2:	34270713          	addi	a4,a4,834 # 80010d20 <pid_lock>
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
    80001a1a:	f2a7a783          	lw	a5,-214(a5) # 80008940 <first.1684>
    80001a1e:	eb89                	bnez	a5,80001a30 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a20:	00001097          	auipc	ra,0x1
    80001a24:	c6a080e7          	jalr	-918(ra) # 8000268a <usertrapret>
}
    80001a28:	60a2                	ld	ra,8(sp)
    80001a2a:	6402                	ld	s0,0(sp)
    80001a2c:	0141                	addi	sp,sp,16
    80001a2e:	8082                	ret
    first = 0;
    80001a30:	00007797          	auipc	a5,0x7
    80001a34:	f007a823          	sw	zero,-240(a5) # 80008940 <first.1684>
    fsinit(ROOTDEV);
    80001a38:	4505                	li	a0,1
    80001a3a:	00002097          	auipc	ra,0x2
    80001a3e:	b04080e7          	jalr	-1276(ra) # 8000353e <fsinit>
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
    80001a54:	2d090913          	addi	s2,s2,720 # 80010d20 <pid_lock>
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	190080e7          	jalr	400(ra) # 80000bea <acquire>
  pid = nextpid;
    80001a62:	00007797          	auipc	a5,0x7
    80001a66:	ee278793          	addi	a5,a5,-286 # 80008944 <nextpid>
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
    80001be0:	57448493          	addi	s1,s1,1396 # 80011150 <proc>
    80001be4:	00016917          	auipc	s2,0x16
    80001be8:	96c90913          	addi	s2,s2,-1684 # 80017550 <tickslock>
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
    80001c0e:	a8b9                	j	80001c6c <allocproc+0x9c>
  p->pid = allocpid();
    80001c10:	00000097          	auipc	ra,0x0
    80001c14:	e34080e7          	jalr	-460(ra) # 80001a44 <allocpid>
    80001c18:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c1a:	4785                	li	a5,1
    80001c1c:	cc9c                	sw	a5,24(s1)
  p->tick_creation_time = ticks;
    80001c1e:	00007797          	auipc	a5,0x7
    80001c22:	e927a783          	lw	a5,-366(a5) # 80008ab0 <ticks>
    80001c26:	18f4a423          	sw	a5,392(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c2a:	fffff097          	auipc	ra,0xfffff
    80001c2e:	ed0080e7          	jalr	-304(ra) # 80000afa <kalloc>
    80001c32:	892a                	mv	s2,a0
    80001c34:	eca8                	sd	a0,88(s1)
    80001c36:	c131                	beqz	a0,80001c7a <allocproc+0xaa>
  p->pagetable = proc_pagetable(p);
    80001c38:	8526                	mv	a0,s1
    80001c3a:	00000097          	auipc	ra,0x0
    80001c3e:	e50080e7          	jalr	-432(ra) # 80001a8a <proc_pagetable>
    80001c42:	892a                	mv	s2,a0
    80001c44:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c46:	c531                	beqz	a0,80001c92 <allocproc+0xc2>
  memset(&p->context, 0, sizeof(p->context));
    80001c48:	07000613          	li	a2,112
    80001c4c:	4581                	li	a1,0
    80001c4e:	06048513          	addi	a0,s1,96
    80001c52:	fffff097          	auipc	ra,0xfffff
    80001c56:	094080e7          	jalr	148(ra) # 80000ce6 <memset>
  p->context.ra = (uint64)forkret;
    80001c5a:	00000797          	auipc	a5,0x0
    80001c5e:	da478793          	addi	a5,a5,-604 # 800019fe <forkret>
    80001c62:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c64:	60bc                	ld	a5,64(s1)
    80001c66:	6705                	lui	a4,0x1
    80001c68:	97ba                	add	a5,a5,a4
    80001c6a:	f4bc                	sd	a5,104(s1)
}
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	60e2                	ld	ra,24(sp)
    80001c70:	6442                	ld	s0,16(sp)
    80001c72:	64a2                	ld	s1,8(sp)
    80001c74:	6902                	ld	s2,0(sp)
    80001c76:	6105                	addi	sp,sp,32
    80001c78:	8082                	ret
    freeproc(p);
    80001c7a:	8526                	mv	a0,s1
    80001c7c:	00000097          	auipc	ra,0x0
    80001c80:	efc080e7          	jalr	-260(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001c84:	8526                	mv	a0,s1
    80001c86:	fffff097          	auipc	ra,0xfffff
    80001c8a:	018080e7          	jalr	24(ra) # 80000c9e <release>
    return 0;
    80001c8e:	84ca                	mv	s1,s2
    80001c90:	bff1                	j	80001c6c <allocproc+0x9c>
    freeproc(p);
    80001c92:	8526                	mv	a0,s1
    80001c94:	00000097          	auipc	ra,0x0
    80001c98:	ee4080e7          	jalr	-284(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001c9c:	8526                	mv	a0,s1
    80001c9e:	fffff097          	auipc	ra,0xfffff
    80001ca2:	000080e7          	jalr	ra # 80000c9e <release>
    return 0;
    80001ca6:	84ca                	mv	s1,s2
    80001ca8:	b7d1                	j	80001c6c <allocproc+0x9c>

0000000080001caa <userinit>:
{
    80001caa:	1101                	addi	sp,sp,-32
    80001cac:	ec06                	sd	ra,24(sp)
    80001cae:	e822                	sd	s0,16(sp)
    80001cb0:	e426                	sd	s1,8(sp)
    80001cb2:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cb4:	00000097          	auipc	ra,0x0
    80001cb8:	f1c080e7          	jalr	-228(ra) # 80001bd0 <allocproc>
    80001cbc:	84aa                	mv	s1,a0
  initproc = p;
    80001cbe:	00007797          	auipc	a5,0x7
    80001cc2:	dea7b523          	sd	a0,-534(a5) # 80008aa8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cc6:	03400613          	li	a2,52
    80001cca:	00007597          	auipc	a1,0x7
    80001cce:	c8658593          	addi	a1,a1,-890 # 80008950 <initcode>
    80001cd2:	6928                	ld	a0,80(a0)
    80001cd4:	fffff097          	auipc	ra,0xfffff
    80001cd8:	69e080e7          	jalr	1694(ra) # 80001372 <uvmfirst>
  p->sz = PGSIZE;
    80001cdc:	6785                	lui	a5,0x1
    80001cde:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001ce0:	6cb8                	ld	a4,88(s1)
    80001ce2:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001ce6:	6cb8                	ld	a4,88(s1)
    80001ce8:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cea:	4641                	li	a2,16
    80001cec:	00006597          	auipc	a1,0x6
    80001cf0:	51458593          	addi	a1,a1,1300 # 80008200 <digits+0x1c0>
    80001cf4:	15848513          	addi	a0,s1,344
    80001cf8:	fffff097          	auipc	ra,0xfffff
    80001cfc:	140080e7          	jalr	320(ra) # 80000e38 <safestrcpy>
  p->cwd = namei("/");
    80001d00:	00006517          	auipc	a0,0x6
    80001d04:	51050513          	addi	a0,a0,1296 # 80008210 <digits+0x1d0>
    80001d08:	00002097          	auipc	ra,0x2
    80001d0c:	258080e7          	jalr	600(ra) # 80003f60 <namei>
    80001d10:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d14:	478d                	li	a5,3
    80001d16:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d18:	8526                	mv	a0,s1
    80001d1a:	fffff097          	auipc	ra,0xfffff
    80001d1e:	f84080e7          	jalr	-124(ra) # 80000c9e <release>
}
    80001d22:	60e2                	ld	ra,24(sp)
    80001d24:	6442                	ld	s0,16(sp)
    80001d26:	64a2                	ld	s1,8(sp)
    80001d28:	6105                	addi	sp,sp,32
    80001d2a:	8082                	ret

0000000080001d2c <growproc>:
{
    80001d2c:	1101                	addi	sp,sp,-32
    80001d2e:	ec06                	sd	ra,24(sp)
    80001d30:	e822                	sd	s0,16(sp)
    80001d32:	e426                	sd	s1,8(sp)
    80001d34:	e04a                	sd	s2,0(sp)
    80001d36:	1000                	addi	s0,sp,32
    80001d38:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d3a:	00000097          	auipc	ra,0x0
    80001d3e:	c8c080e7          	jalr	-884(ra) # 800019c6 <myproc>
    80001d42:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d44:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d46:	01204c63          	bgtz	s2,80001d5e <growproc+0x32>
  } else if(n < 0){
    80001d4a:	02094663          	bltz	s2,80001d76 <growproc+0x4a>
  p->sz = sz;
    80001d4e:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d50:	4501                	li	a0,0
}
    80001d52:	60e2                	ld	ra,24(sp)
    80001d54:	6442                	ld	s0,16(sp)
    80001d56:	64a2                	ld	s1,8(sp)
    80001d58:	6902                	ld	s2,0(sp)
    80001d5a:	6105                	addi	sp,sp,32
    80001d5c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d5e:	4691                	li	a3,4
    80001d60:	00b90633          	add	a2,s2,a1
    80001d64:	6928                	ld	a0,80(a0)
    80001d66:	fffff097          	auipc	ra,0xfffff
    80001d6a:	6c6080e7          	jalr	1734(ra) # 8000142c <uvmalloc>
    80001d6e:	85aa                	mv	a1,a0
    80001d70:	fd79                	bnez	a0,80001d4e <growproc+0x22>
      return -1;
    80001d72:	557d                	li	a0,-1
    80001d74:	bff9                	j	80001d52 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d76:	00b90633          	add	a2,s2,a1
    80001d7a:	6928                	ld	a0,80(a0)
    80001d7c:	fffff097          	auipc	ra,0xfffff
    80001d80:	668080e7          	jalr	1640(ra) # 800013e4 <uvmdealloc>
    80001d84:	85aa                	mv	a1,a0
    80001d86:	b7e1                	j	80001d4e <growproc+0x22>

0000000080001d88 <fork>:
{
    80001d88:	7179                	addi	sp,sp,-48
    80001d8a:	f406                	sd	ra,40(sp)
    80001d8c:	f022                	sd	s0,32(sp)
    80001d8e:	ec26                	sd	s1,24(sp)
    80001d90:	e84a                	sd	s2,16(sp)
    80001d92:	e44e                	sd	s3,8(sp)
    80001d94:	e052                	sd	s4,0(sp)
    80001d96:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001d98:	00000097          	auipc	ra,0x0
    80001d9c:	c2e080e7          	jalr	-978(ra) # 800019c6 <myproc>
    80001da0:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001da2:	00000097          	auipc	ra,0x0
    80001da6:	e2e080e7          	jalr	-466(ra) # 80001bd0 <allocproc>
    80001daa:	10050f63          	beqz	a0,80001ec8 <fork+0x140>
    80001dae:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001db0:	04893603          	ld	a2,72(s2)
    80001db4:	692c                	ld	a1,80(a0)
    80001db6:	05093503          	ld	a0,80(s2)
    80001dba:	fffff097          	auipc	ra,0xfffff
    80001dbe:	7c6080e7          	jalr	1990(ra) # 80001580 <uvmcopy>
    80001dc2:	04054a63          	bltz	a0,80001e16 <fork+0x8e>
  np->sz = p->sz;
    80001dc6:	04893783          	ld	a5,72(s2)
    80001dca:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dce:	05893683          	ld	a3,88(s2)
    80001dd2:	87b6                	mv	a5,a3
    80001dd4:	0589b703          	ld	a4,88(s3)
    80001dd8:	12068693          	addi	a3,a3,288
    80001ddc:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001de0:	6788                	ld	a0,8(a5)
    80001de2:	6b8c                	ld	a1,16(a5)
    80001de4:	6f90                	ld	a2,24(a5)
    80001de6:	01073023          	sd	a6,0(a4)
    80001dea:	e708                	sd	a0,8(a4)
    80001dec:	eb0c                	sd	a1,16(a4)
    80001dee:	ef10                	sd	a2,24(a4)
    80001df0:	02078793          	addi	a5,a5,32
    80001df4:	02070713          	addi	a4,a4,32
    80001df8:	fed792e3          	bne	a5,a3,80001ddc <fork+0x54>
  np->trace_flag = p->trace_flag;
    80001dfc:	16892783          	lw	a5,360(s2)
    80001e00:	16f9a423          	sw	a5,360(s3)
  np->trapframe->a0 = 0;
    80001e04:	0589b783          	ld	a5,88(s3)
    80001e08:	0607b823          	sd	zero,112(a5)
    80001e0c:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e10:	15000a13          	li	s4,336
    80001e14:	a03d                	j	80001e42 <fork+0xba>
    freeproc(np);
    80001e16:	854e                	mv	a0,s3
    80001e18:	00000097          	auipc	ra,0x0
    80001e1c:	d60080e7          	jalr	-672(ra) # 80001b78 <freeproc>
    release(&np->lock);
    80001e20:	854e                	mv	a0,s3
    80001e22:	fffff097          	auipc	ra,0xfffff
    80001e26:	e7c080e7          	jalr	-388(ra) # 80000c9e <release>
    return -1;
    80001e2a:	5a7d                	li	s4,-1
    80001e2c:	a069                	j	80001eb6 <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e2e:	00002097          	auipc	ra,0x2
    80001e32:	7c8080e7          	jalr	1992(ra) # 800045f6 <filedup>
    80001e36:	009987b3          	add	a5,s3,s1
    80001e3a:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e3c:	04a1                	addi	s1,s1,8
    80001e3e:	01448763          	beq	s1,s4,80001e4c <fork+0xc4>
    if(p->ofile[i])
    80001e42:	009907b3          	add	a5,s2,s1
    80001e46:	6388                	ld	a0,0(a5)
    80001e48:	f17d                	bnez	a0,80001e2e <fork+0xa6>
    80001e4a:	bfcd                	j	80001e3c <fork+0xb4>
  np->cwd = idup(p->cwd);
    80001e4c:	15093503          	ld	a0,336(s2)
    80001e50:	00002097          	auipc	ra,0x2
    80001e54:	92c080e7          	jalr	-1748(ra) # 8000377c <idup>
    80001e58:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e5c:	4641                	li	a2,16
    80001e5e:	15890593          	addi	a1,s2,344
    80001e62:	15898513          	addi	a0,s3,344
    80001e66:	fffff097          	auipc	ra,0xfffff
    80001e6a:	fd2080e7          	jalr	-46(ra) # 80000e38 <safestrcpy>
  pid = np->pid;
    80001e6e:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e72:	854e                	mv	a0,s3
    80001e74:	fffff097          	auipc	ra,0xfffff
    80001e78:	e2a080e7          	jalr	-470(ra) # 80000c9e <release>
  acquire(&wait_lock);
    80001e7c:	0000f497          	auipc	s1,0xf
    80001e80:	ebc48493          	addi	s1,s1,-324 # 80010d38 <wait_lock>
    80001e84:	8526                	mv	a0,s1
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	d64080e7          	jalr	-668(ra) # 80000bea <acquire>
  np->parent = p;
    80001e8e:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001e92:	8526                	mv	a0,s1
    80001e94:	fffff097          	auipc	ra,0xfffff
    80001e98:	e0a080e7          	jalr	-502(ra) # 80000c9e <release>
  acquire(&np->lock);
    80001e9c:	854e                	mv	a0,s3
    80001e9e:	fffff097          	auipc	ra,0xfffff
    80001ea2:	d4c080e7          	jalr	-692(ra) # 80000bea <acquire>
  np->state = RUNNABLE;
    80001ea6:	478d                	li	a5,3
    80001ea8:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001eac:	854e                	mv	a0,s3
    80001eae:	fffff097          	auipc	ra,0xfffff
    80001eb2:	df0080e7          	jalr	-528(ra) # 80000c9e <release>
}
    80001eb6:	8552                	mv	a0,s4
    80001eb8:	70a2                	ld	ra,40(sp)
    80001eba:	7402                	ld	s0,32(sp)
    80001ebc:	64e2                	ld	s1,24(sp)
    80001ebe:	6942                	ld	s2,16(sp)
    80001ec0:	69a2                	ld	s3,8(sp)
    80001ec2:	6a02                	ld	s4,0(sp)
    80001ec4:	6145                	addi	sp,sp,48
    80001ec6:	8082                	ret
    return -1;
    80001ec8:	5a7d                	li	s4,-1
    80001eca:	b7f5                	j	80001eb6 <fork+0x12e>

0000000080001ecc <scheduler>:
{
    80001ecc:	7139                	addi	sp,sp,-64
    80001ece:	fc06                	sd	ra,56(sp)
    80001ed0:	f822                	sd	s0,48(sp)
    80001ed2:	f426                	sd	s1,40(sp)
    80001ed4:	f04a                	sd	s2,32(sp)
    80001ed6:	ec4e                	sd	s3,24(sp)
    80001ed8:	e852                	sd	s4,16(sp)
    80001eda:	e456                	sd	s5,8(sp)
    80001edc:	e05a                	sd	s6,0(sp)
    80001ede:	0080                	addi	s0,sp,64
    80001ee0:	8792                	mv	a5,tp
  int id = r_tp();
    80001ee2:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ee4:	00779a93          	slli	s5,a5,0x7
    80001ee8:	0000f717          	auipc	a4,0xf
    80001eec:	e3870713          	addi	a4,a4,-456 # 80010d20 <pid_lock>
    80001ef0:	9756                	add	a4,a4,s5
    80001ef2:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ef6:	0000f717          	auipc	a4,0xf
    80001efa:	e6270713          	addi	a4,a4,-414 # 80010d58 <cpus+0x8>
    80001efe:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f00:	498d                	li	s3,3
        p->state = RUNNING;
    80001f02:	4b11                	li	s6,4
        c->proc = p;
    80001f04:	079e                	slli	a5,a5,0x7
    80001f06:	0000fa17          	auipc	s4,0xf
    80001f0a:	e1aa0a13          	addi	s4,s4,-486 # 80010d20 <pid_lock>
    80001f0e:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f10:	00015917          	auipc	s2,0x15
    80001f14:	64090913          	addi	s2,s2,1600 # 80017550 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f18:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f1c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f20:	10079073          	csrw	sstatus,a5
    80001f24:	0000f497          	auipc	s1,0xf
    80001f28:	22c48493          	addi	s1,s1,556 # 80011150 <proc>
    80001f2c:	a03d                	j	80001f5a <scheduler+0x8e>
        p->state = RUNNING;
    80001f2e:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f32:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f36:	06048593          	addi	a1,s1,96
    80001f3a:	8556                	mv	a0,s5
    80001f3c:	00000097          	auipc	ra,0x0
    80001f40:	6a4080e7          	jalr	1700(ra) # 800025e0 <swtch>
        c->proc = 0;
    80001f44:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80001f48:	8526                	mv	a0,s1
    80001f4a:	fffff097          	auipc	ra,0xfffff
    80001f4e:	d54080e7          	jalr	-684(ra) # 80000c9e <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f52:	19048493          	addi	s1,s1,400
    80001f56:	fd2481e3          	beq	s1,s2,80001f18 <scheduler+0x4c>
      acquire(&p->lock);
    80001f5a:	8526                	mv	a0,s1
    80001f5c:	fffff097          	auipc	ra,0xfffff
    80001f60:	c8e080e7          	jalr	-882(ra) # 80000bea <acquire>
      if(p->state == RUNNABLE) {
    80001f64:	4c9c                	lw	a5,24(s1)
    80001f66:	ff3791e3          	bne	a5,s3,80001f48 <scheduler+0x7c>
    80001f6a:	b7d1                	j	80001f2e <scheduler+0x62>

0000000080001f6c <sched>:
{
    80001f6c:	7179                	addi	sp,sp,-48
    80001f6e:	f406                	sd	ra,40(sp)
    80001f70:	f022                	sd	s0,32(sp)
    80001f72:	ec26                	sd	s1,24(sp)
    80001f74:	e84a                	sd	s2,16(sp)
    80001f76:	e44e                	sd	s3,8(sp)
    80001f78:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f7a:	00000097          	auipc	ra,0x0
    80001f7e:	a4c080e7          	jalr	-1460(ra) # 800019c6 <myproc>
    80001f82:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f84:	fffff097          	auipc	ra,0xfffff
    80001f88:	bec080e7          	jalr	-1044(ra) # 80000b70 <holding>
    80001f8c:	c93d                	beqz	a0,80002002 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f8e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f90:	2781                	sext.w	a5,a5
    80001f92:	079e                	slli	a5,a5,0x7
    80001f94:	0000f717          	auipc	a4,0xf
    80001f98:	d8c70713          	addi	a4,a4,-628 # 80010d20 <pid_lock>
    80001f9c:	97ba                	add	a5,a5,a4
    80001f9e:	0a87a703          	lw	a4,168(a5)
    80001fa2:	4785                	li	a5,1
    80001fa4:	06f71763          	bne	a4,a5,80002012 <sched+0xa6>
  if(p->state == RUNNING)
    80001fa8:	4c98                	lw	a4,24(s1)
    80001faa:	4791                	li	a5,4
    80001fac:	06f70b63          	beq	a4,a5,80002022 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fb0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fb4:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fb6:	efb5                	bnez	a5,80002032 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fb8:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fba:	0000f917          	auipc	s2,0xf
    80001fbe:	d6690913          	addi	s2,s2,-666 # 80010d20 <pid_lock>
    80001fc2:	2781                	sext.w	a5,a5
    80001fc4:	079e                	slli	a5,a5,0x7
    80001fc6:	97ca                	add	a5,a5,s2
    80001fc8:	0ac7a983          	lw	s3,172(a5)
    80001fcc:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fce:	2781                	sext.w	a5,a5
    80001fd0:	079e                	slli	a5,a5,0x7
    80001fd2:	0000f597          	auipc	a1,0xf
    80001fd6:	d8658593          	addi	a1,a1,-634 # 80010d58 <cpus+0x8>
    80001fda:	95be                	add	a1,a1,a5
    80001fdc:	06048513          	addi	a0,s1,96
    80001fe0:	00000097          	auipc	ra,0x0
    80001fe4:	600080e7          	jalr	1536(ra) # 800025e0 <swtch>
    80001fe8:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fea:	2781                	sext.w	a5,a5
    80001fec:	079e                	slli	a5,a5,0x7
    80001fee:	97ca                	add	a5,a5,s2
    80001ff0:	0b37a623          	sw	s3,172(a5)
}
    80001ff4:	70a2                	ld	ra,40(sp)
    80001ff6:	7402                	ld	s0,32(sp)
    80001ff8:	64e2                	ld	s1,24(sp)
    80001ffa:	6942                	ld	s2,16(sp)
    80001ffc:	69a2                	ld	s3,8(sp)
    80001ffe:	6145                	addi	sp,sp,48
    80002000:	8082                	ret
    panic("sched p->lock");
    80002002:	00006517          	auipc	a0,0x6
    80002006:	21650513          	addi	a0,a0,534 # 80008218 <digits+0x1d8>
    8000200a:	ffffe097          	auipc	ra,0xffffe
    8000200e:	53a080e7          	jalr	1338(ra) # 80000544 <panic>
    panic("sched locks");
    80002012:	00006517          	auipc	a0,0x6
    80002016:	21650513          	addi	a0,a0,534 # 80008228 <digits+0x1e8>
    8000201a:	ffffe097          	auipc	ra,0xffffe
    8000201e:	52a080e7          	jalr	1322(ra) # 80000544 <panic>
    panic("sched running");
    80002022:	00006517          	auipc	a0,0x6
    80002026:	21650513          	addi	a0,a0,534 # 80008238 <digits+0x1f8>
    8000202a:	ffffe097          	auipc	ra,0xffffe
    8000202e:	51a080e7          	jalr	1306(ra) # 80000544 <panic>
    panic("sched interruptible");
    80002032:	00006517          	auipc	a0,0x6
    80002036:	21650513          	addi	a0,a0,534 # 80008248 <digits+0x208>
    8000203a:	ffffe097          	auipc	ra,0xffffe
    8000203e:	50a080e7          	jalr	1290(ra) # 80000544 <panic>

0000000080002042 <yield>:
{
    80002042:	1101                	addi	sp,sp,-32
    80002044:	ec06                	sd	ra,24(sp)
    80002046:	e822                	sd	s0,16(sp)
    80002048:	e426                	sd	s1,8(sp)
    8000204a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000204c:	00000097          	auipc	ra,0x0
    80002050:	97a080e7          	jalr	-1670(ra) # 800019c6 <myproc>
    80002054:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002056:	fffff097          	auipc	ra,0xfffff
    8000205a:	b94080e7          	jalr	-1132(ra) # 80000bea <acquire>
  p->state = RUNNABLE;
    8000205e:	478d                	li	a5,3
    80002060:	cc9c                	sw	a5,24(s1)
  sched();
    80002062:	00000097          	auipc	ra,0x0
    80002066:	f0a080e7          	jalr	-246(ra) # 80001f6c <sched>
  release(&p->lock);
    8000206a:	8526                	mv	a0,s1
    8000206c:	fffff097          	auipc	ra,0xfffff
    80002070:	c32080e7          	jalr	-974(ra) # 80000c9e <release>
}
    80002074:	60e2                	ld	ra,24(sp)
    80002076:	6442                	ld	s0,16(sp)
    80002078:	64a2                	ld	s1,8(sp)
    8000207a:	6105                	addi	sp,sp,32
    8000207c:	8082                	ret

000000008000207e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000207e:	7179                	addi	sp,sp,-48
    80002080:	f406                	sd	ra,40(sp)
    80002082:	f022                	sd	s0,32(sp)
    80002084:	ec26                	sd	s1,24(sp)
    80002086:	e84a                	sd	s2,16(sp)
    80002088:	e44e                	sd	s3,8(sp)
    8000208a:	1800                	addi	s0,sp,48
    8000208c:	89aa                	mv	s3,a0
    8000208e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002090:	00000097          	auipc	ra,0x0
    80002094:	936080e7          	jalr	-1738(ra) # 800019c6 <myproc>
    80002098:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000209a:	fffff097          	auipc	ra,0xfffff
    8000209e:	b50080e7          	jalr	-1200(ra) # 80000bea <acquire>
  release(lk);
    800020a2:	854a                	mv	a0,s2
    800020a4:	fffff097          	auipc	ra,0xfffff
    800020a8:	bfa080e7          	jalr	-1030(ra) # 80000c9e <release>

  // Go to sleep.
  p->chan = chan;
    800020ac:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020b0:	4789                	li	a5,2
    800020b2:	cc9c                	sw	a5,24(s1)

  sched();
    800020b4:	00000097          	auipc	ra,0x0
    800020b8:	eb8080e7          	jalr	-328(ra) # 80001f6c <sched>

  // Tidy up.
  p->chan = 0;
    800020bc:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020c0:	8526                	mv	a0,s1
    800020c2:	fffff097          	auipc	ra,0xfffff
    800020c6:	bdc080e7          	jalr	-1060(ra) # 80000c9e <release>
  acquire(lk);
    800020ca:	854a                	mv	a0,s2
    800020cc:	fffff097          	auipc	ra,0xfffff
    800020d0:	b1e080e7          	jalr	-1250(ra) # 80000bea <acquire>
}
    800020d4:	70a2                	ld	ra,40(sp)
    800020d6:	7402                	ld	s0,32(sp)
    800020d8:	64e2                	ld	s1,24(sp)
    800020da:	6942                	ld	s2,16(sp)
    800020dc:	69a2                	ld	s3,8(sp)
    800020de:	6145                	addi	sp,sp,48
    800020e0:	8082                	ret

00000000800020e2 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800020e2:	7139                	addi	sp,sp,-64
    800020e4:	fc06                	sd	ra,56(sp)
    800020e6:	f822                	sd	s0,48(sp)
    800020e8:	f426                	sd	s1,40(sp)
    800020ea:	f04a                	sd	s2,32(sp)
    800020ec:	ec4e                	sd	s3,24(sp)
    800020ee:	e852                	sd	s4,16(sp)
    800020f0:	e456                	sd	s5,8(sp)
    800020f2:	0080                	addi	s0,sp,64
    800020f4:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800020f6:	0000f497          	auipc	s1,0xf
    800020fa:	05a48493          	addi	s1,s1,90 # 80011150 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800020fe:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002100:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002102:	00015917          	auipc	s2,0x15
    80002106:	44e90913          	addi	s2,s2,1102 # 80017550 <tickslock>
    8000210a:	a821                	j	80002122 <wakeup+0x40>
        p->state = RUNNABLE;
    8000210c:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002110:	8526                	mv	a0,s1
    80002112:	fffff097          	auipc	ra,0xfffff
    80002116:	b8c080e7          	jalr	-1140(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000211a:	19048493          	addi	s1,s1,400
    8000211e:	03248463          	beq	s1,s2,80002146 <wakeup+0x64>
    if(p != myproc()){
    80002122:	00000097          	auipc	ra,0x0
    80002126:	8a4080e7          	jalr	-1884(ra) # 800019c6 <myproc>
    8000212a:	fea488e3          	beq	s1,a0,8000211a <wakeup+0x38>
      acquire(&p->lock);
    8000212e:	8526                	mv	a0,s1
    80002130:	fffff097          	auipc	ra,0xfffff
    80002134:	aba080e7          	jalr	-1350(ra) # 80000bea <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002138:	4c9c                	lw	a5,24(s1)
    8000213a:	fd379be3          	bne	a5,s3,80002110 <wakeup+0x2e>
    8000213e:	709c                	ld	a5,32(s1)
    80002140:	fd4798e3          	bne	a5,s4,80002110 <wakeup+0x2e>
    80002144:	b7e1                	j	8000210c <wakeup+0x2a>
    }
  }
}
    80002146:	70e2                	ld	ra,56(sp)
    80002148:	7442                	ld	s0,48(sp)
    8000214a:	74a2                	ld	s1,40(sp)
    8000214c:	7902                	ld	s2,32(sp)
    8000214e:	69e2                	ld	s3,24(sp)
    80002150:	6a42                	ld	s4,16(sp)
    80002152:	6aa2                	ld	s5,8(sp)
    80002154:	6121                	addi	sp,sp,64
    80002156:	8082                	ret

0000000080002158 <reparent>:
{
    80002158:	7179                	addi	sp,sp,-48
    8000215a:	f406                	sd	ra,40(sp)
    8000215c:	f022                	sd	s0,32(sp)
    8000215e:	ec26                	sd	s1,24(sp)
    80002160:	e84a                	sd	s2,16(sp)
    80002162:	e44e                	sd	s3,8(sp)
    80002164:	e052                	sd	s4,0(sp)
    80002166:	1800                	addi	s0,sp,48
    80002168:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000216a:	0000f497          	auipc	s1,0xf
    8000216e:	fe648493          	addi	s1,s1,-26 # 80011150 <proc>
      pp->parent = initproc;
    80002172:	00007a17          	auipc	s4,0x7
    80002176:	936a0a13          	addi	s4,s4,-1738 # 80008aa8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000217a:	00015997          	auipc	s3,0x15
    8000217e:	3d698993          	addi	s3,s3,982 # 80017550 <tickslock>
    80002182:	a029                	j	8000218c <reparent+0x34>
    80002184:	19048493          	addi	s1,s1,400
    80002188:	01348d63          	beq	s1,s3,800021a2 <reparent+0x4a>
    if(pp->parent == p){
    8000218c:	7c9c                	ld	a5,56(s1)
    8000218e:	ff279be3          	bne	a5,s2,80002184 <reparent+0x2c>
      pp->parent = initproc;
    80002192:	000a3503          	ld	a0,0(s4)
    80002196:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002198:	00000097          	auipc	ra,0x0
    8000219c:	f4a080e7          	jalr	-182(ra) # 800020e2 <wakeup>
    800021a0:	b7d5                	j	80002184 <reparent+0x2c>
}
    800021a2:	70a2                	ld	ra,40(sp)
    800021a4:	7402                	ld	s0,32(sp)
    800021a6:	64e2                	ld	s1,24(sp)
    800021a8:	6942                	ld	s2,16(sp)
    800021aa:	69a2                	ld	s3,8(sp)
    800021ac:	6a02                	ld	s4,0(sp)
    800021ae:	6145                	addi	sp,sp,48
    800021b0:	8082                	ret

00000000800021b2 <exit>:
{
    800021b2:	7179                	addi	sp,sp,-48
    800021b4:	f406                	sd	ra,40(sp)
    800021b6:	f022                	sd	s0,32(sp)
    800021b8:	ec26                	sd	s1,24(sp)
    800021ba:	e84a                	sd	s2,16(sp)
    800021bc:	e44e                	sd	s3,8(sp)
    800021be:	e052                	sd	s4,0(sp)
    800021c0:	1800                	addi	s0,sp,48
    800021c2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021c4:	00000097          	auipc	ra,0x0
    800021c8:	802080e7          	jalr	-2046(ra) # 800019c6 <myproc>
    800021cc:	89aa                	mv	s3,a0
  if(p == initproc)
    800021ce:	00007797          	auipc	a5,0x7
    800021d2:	8da7b783          	ld	a5,-1830(a5) # 80008aa8 <initproc>
    800021d6:	0d050493          	addi	s1,a0,208
    800021da:	15050913          	addi	s2,a0,336
    800021de:	02a79363          	bne	a5,a0,80002204 <exit+0x52>
    panic("init exiting");
    800021e2:	00006517          	auipc	a0,0x6
    800021e6:	07e50513          	addi	a0,a0,126 # 80008260 <digits+0x220>
    800021ea:	ffffe097          	auipc	ra,0xffffe
    800021ee:	35a080e7          	jalr	858(ra) # 80000544 <panic>
      fileclose(f);
    800021f2:	00002097          	auipc	ra,0x2
    800021f6:	456080e7          	jalr	1110(ra) # 80004648 <fileclose>
      p->ofile[fd] = 0;
    800021fa:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021fe:	04a1                	addi	s1,s1,8
    80002200:	01248563          	beq	s1,s2,8000220a <exit+0x58>
    if(p->ofile[fd]){
    80002204:	6088                	ld	a0,0(s1)
    80002206:	f575                	bnez	a0,800021f2 <exit+0x40>
    80002208:	bfdd                	j	800021fe <exit+0x4c>
  begin_op();
    8000220a:	00002097          	auipc	ra,0x2
    8000220e:	f72080e7          	jalr	-142(ra) # 8000417c <begin_op>
  iput(p->cwd);
    80002212:	1509b503          	ld	a0,336(s3)
    80002216:	00001097          	auipc	ra,0x1
    8000221a:	75e080e7          	jalr	1886(ra) # 80003974 <iput>
  end_op();
    8000221e:	00002097          	auipc	ra,0x2
    80002222:	fde080e7          	jalr	-34(ra) # 800041fc <end_op>
  p->cwd = 0;
    80002226:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000222a:	0000f497          	auipc	s1,0xf
    8000222e:	b0e48493          	addi	s1,s1,-1266 # 80010d38 <wait_lock>
    80002232:	8526                	mv	a0,s1
    80002234:	fffff097          	auipc	ra,0xfffff
    80002238:	9b6080e7          	jalr	-1610(ra) # 80000bea <acquire>
  reparent(p);
    8000223c:	854e                	mv	a0,s3
    8000223e:	00000097          	auipc	ra,0x0
    80002242:	f1a080e7          	jalr	-230(ra) # 80002158 <reparent>
  wakeup(p->parent);
    80002246:	0389b503          	ld	a0,56(s3)
    8000224a:	00000097          	auipc	ra,0x0
    8000224e:	e98080e7          	jalr	-360(ra) # 800020e2 <wakeup>
  acquire(&p->lock);
    80002252:	854e                	mv	a0,s3
    80002254:	fffff097          	auipc	ra,0xfffff
    80002258:	996080e7          	jalr	-1642(ra) # 80000bea <acquire>
  p->xstate = status;
    8000225c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002260:	4795                	li	a5,5
    80002262:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002266:	8526                	mv	a0,s1
    80002268:	fffff097          	auipc	ra,0xfffff
    8000226c:	a36080e7          	jalr	-1482(ra) # 80000c9e <release>
  sched();
    80002270:	00000097          	auipc	ra,0x0
    80002274:	cfc080e7          	jalr	-772(ra) # 80001f6c <sched>
  panic("zombie exit");
    80002278:	00006517          	auipc	a0,0x6
    8000227c:	ff850513          	addi	a0,a0,-8 # 80008270 <digits+0x230>
    80002280:	ffffe097          	auipc	ra,0xffffe
    80002284:	2c4080e7          	jalr	708(ra) # 80000544 <panic>

0000000080002288 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002288:	7179                	addi	sp,sp,-48
    8000228a:	f406                	sd	ra,40(sp)
    8000228c:	f022                	sd	s0,32(sp)
    8000228e:	ec26                	sd	s1,24(sp)
    80002290:	e84a                	sd	s2,16(sp)
    80002292:	e44e                	sd	s3,8(sp)
    80002294:	1800                	addi	s0,sp,48
    80002296:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002298:	0000f497          	auipc	s1,0xf
    8000229c:	eb848493          	addi	s1,s1,-328 # 80011150 <proc>
    800022a0:	00015997          	auipc	s3,0x15
    800022a4:	2b098993          	addi	s3,s3,688 # 80017550 <tickslock>
    acquire(&p->lock);
    800022a8:	8526                	mv	a0,s1
    800022aa:	fffff097          	auipc	ra,0xfffff
    800022ae:	940080e7          	jalr	-1728(ra) # 80000bea <acquire>
    if(p->pid == pid){
    800022b2:	589c                	lw	a5,48(s1)
    800022b4:	01278d63          	beq	a5,s2,800022ce <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022b8:	8526                	mv	a0,s1
    800022ba:	fffff097          	auipc	ra,0xfffff
    800022be:	9e4080e7          	jalr	-1564(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800022c2:	19048493          	addi	s1,s1,400
    800022c6:	ff3491e3          	bne	s1,s3,800022a8 <kill+0x20>
  }
  return -1;
    800022ca:	557d                	li	a0,-1
    800022cc:	a829                	j	800022e6 <kill+0x5e>
      p->killed = 1;
    800022ce:	4785                	li	a5,1
    800022d0:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022d2:	4c98                	lw	a4,24(s1)
    800022d4:	4789                	li	a5,2
    800022d6:	00f70f63          	beq	a4,a5,800022f4 <kill+0x6c>
      release(&p->lock);
    800022da:	8526                	mv	a0,s1
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	9c2080e7          	jalr	-1598(ra) # 80000c9e <release>
      return 0;
    800022e4:	4501                	li	a0,0
}
    800022e6:	70a2                	ld	ra,40(sp)
    800022e8:	7402                	ld	s0,32(sp)
    800022ea:	64e2                	ld	s1,24(sp)
    800022ec:	6942                	ld	s2,16(sp)
    800022ee:	69a2                	ld	s3,8(sp)
    800022f0:	6145                	addi	sp,sp,48
    800022f2:	8082                	ret
        p->state = RUNNABLE;
    800022f4:	478d                	li	a5,3
    800022f6:	cc9c                	sw	a5,24(s1)
    800022f8:	b7cd                	j	800022da <kill+0x52>

00000000800022fa <setkilled>:

void
setkilled(struct proc *p)
{
    800022fa:	1101                	addi	sp,sp,-32
    800022fc:	ec06                	sd	ra,24(sp)
    800022fe:	e822                	sd	s0,16(sp)
    80002300:	e426                	sd	s1,8(sp)
    80002302:	1000                	addi	s0,sp,32
    80002304:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002306:	fffff097          	auipc	ra,0xfffff
    8000230a:	8e4080e7          	jalr	-1820(ra) # 80000bea <acquire>
  p->killed = 1;
    8000230e:	4785                	li	a5,1
    80002310:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002312:	8526                	mv	a0,s1
    80002314:	fffff097          	auipc	ra,0xfffff
    80002318:	98a080e7          	jalr	-1654(ra) # 80000c9e <release>
}
    8000231c:	60e2                	ld	ra,24(sp)
    8000231e:	6442                	ld	s0,16(sp)
    80002320:	64a2                	ld	s1,8(sp)
    80002322:	6105                	addi	sp,sp,32
    80002324:	8082                	ret

0000000080002326 <killed>:

int
killed(struct proc *p)
{
    80002326:	1101                	addi	sp,sp,-32
    80002328:	ec06                	sd	ra,24(sp)
    8000232a:	e822                	sd	s0,16(sp)
    8000232c:	e426                	sd	s1,8(sp)
    8000232e:	e04a                	sd	s2,0(sp)
    80002330:	1000                	addi	s0,sp,32
    80002332:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002334:	fffff097          	auipc	ra,0xfffff
    80002338:	8b6080e7          	jalr	-1866(ra) # 80000bea <acquire>
  k = p->killed;
    8000233c:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002340:	8526                	mv	a0,s1
    80002342:	fffff097          	auipc	ra,0xfffff
    80002346:	95c080e7          	jalr	-1700(ra) # 80000c9e <release>
  return k;
}
    8000234a:	854a                	mv	a0,s2
    8000234c:	60e2                	ld	ra,24(sp)
    8000234e:	6442                	ld	s0,16(sp)
    80002350:	64a2                	ld	s1,8(sp)
    80002352:	6902                	ld	s2,0(sp)
    80002354:	6105                	addi	sp,sp,32
    80002356:	8082                	ret

0000000080002358 <wait>:
{
    80002358:	715d                	addi	sp,sp,-80
    8000235a:	e486                	sd	ra,72(sp)
    8000235c:	e0a2                	sd	s0,64(sp)
    8000235e:	fc26                	sd	s1,56(sp)
    80002360:	f84a                	sd	s2,48(sp)
    80002362:	f44e                	sd	s3,40(sp)
    80002364:	f052                	sd	s4,32(sp)
    80002366:	ec56                	sd	s5,24(sp)
    80002368:	e85a                	sd	s6,16(sp)
    8000236a:	e45e                	sd	s7,8(sp)
    8000236c:	e062                	sd	s8,0(sp)
    8000236e:	0880                	addi	s0,sp,80
    80002370:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002372:	fffff097          	auipc	ra,0xfffff
    80002376:	654080e7          	jalr	1620(ra) # 800019c6 <myproc>
    8000237a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000237c:	0000f517          	auipc	a0,0xf
    80002380:	9bc50513          	addi	a0,a0,-1604 # 80010d38 <wait_lock>
    80002384:	fffff097          	auipc	ra,0xfffff
    80002388:	866080e7          	jalr	-1946(ra) # 80000bea <acquire>
    havekids = 0;
    8000238c:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000238e:	4a15                	li	s4,5
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002390:	00015997          	auipc	s3,0x15
    80002394:	1c098993          	addi	s3,s3,448 # 80017550 <tickslock>
        havekids = 1;
    80002398:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000239a:	0000fc17          	auipc	s8,0xf
    8000239e:	99ec0c13          	addi	s8,s8,-1634 # 80010d38 <wait_lock>
    havekids = 0;
    800023a2:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023a4:	0000f497          	auipc	s1,0xf
    800023a8:	dac48493          	addi	s1,s1,-596 # 80011150 <proc>
    800023ac:	a0bd                	j	8000241a <wait+0xc2>
          pid = pp->pid;
    800023ae:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800023b2:	000b0e63          	beqz	s6,800023ce <wait+0x76>
    800023b6:	4691                	li	a3,4
    800023b8:	02c48613          	addi	a2,s1,44
    800023bc:	85da                	mv	a1,s6
    800023be:	05093503          	ld	a0,80(s2)
    800023c2:	fffff097          	auipc	ra,0xfffff
    800023c6:	2c2080e7          	jalr	706(ra) # 80001684 <copyout>
    800023ca:	02054563          	bltz	a0,800023f4 <wait+0x9c>
          freeproc(pp);
    800023ce:	8526                	mv	a0,s1
    800023d0:	fffff097          	auipc	ra,0xfffff
    800023d4:	7a8080e7          	jalr	1960(ra) # 80001b78 <freeproc>
          release(&pp->lock);
    800023d8:	8526                	mv	a0,s1
    800023da:	fffff097          	auipc	ra,0xfffff
    800023de:	8c4080e7          	jalr	-1852(ra) # 80000c9e <release>
          release(&wait_lock);
    800023e2:	0000f517          	auipc	a0,0xf
    800023e6:	95650513          	addi	a0,a0,-1706 # 80010d38 <wait_lock>
    800023ea:	fffff097          	auipc	ra,0xfffff
    800023ee:	8b4080e7          	jalr	-1868(ra) # 80000c9e <release>
          return pid;
    800023f2:	a0b5                	j	8000245e <wait+0x106>
            release(&pp->lock);
    800023f4:	8526                	mv	a0,s1
    800023f6:	fffff097          	auipc	ra,0xfffff
    800023fa:	8a8080e7          	jalr	-1880(ra) # 80000c9e <release>
            release(&wait_lock);
    800023fe:	0000f517          	auipc	a0,0xf
    80002402:	93a50513          	addi	a0,a0,-1734 # 80010d38 <wait_lock>
    80002406:	fffff097          	auipc	ra,0xfffff
    8000240a:	898080e7          	jalr	-1896(ra) # 80000c9e <release>
            return -1;
    8000240e:	59fd                	li	s3,-1
    80002410:	a0b9                	j	8000245e <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002412:	19048493          	addi	s1,s1,400
    80002416:	03348463          	beq	s1,s3,8000243e <wait+0xe6>
      if(pp->parent == p){
    8000241a:	7c9c                	ld	a5,56(s1)
    8000241c:	ff279be3          	bne	a5,s2,80002412 <wait+0xba>
        acquire(&pp->lock);
    80002420:	8526                	mv	a0,s1
    80002422:	ffffe097          	auipc	ra,0xffffe
    80002426:	7c8080e7          	jalr	1992(ra) # 80000bea <acquire>
        if(pp->state == ZOMBIE){
    8000242a:	4c9c                	lw	a5,24(s1)
    8000242c:	f94781e3          	beq	a5,s4,800023ae <wait+0x56>
        release(&pp->lock);
    80002430:	8526                	mv	a0,s1
    80002432:	fffff097          	auipc	ra,0xfffff
    80002436:	86c080e7          	jalr	-1940(ra) # 80000c9e <release>
        havekids = 1;
    8000243a:	8756                	mv	a4,s5
    8000243c:	bfd9                	j	80002412 <wait+0xba>
    if(!havekids || killed(p)){
    8000243e:	c719                	beqz	a4,8000244c <wait+0xf4>
    80002440:	854a                	mv	a0,s2
    80002442:	00000097          	auipc	ra,0x0
    80002446:	ee4080e7          	jalr	-284(ra) # 80002326 <killed>
    8000244a:	c51d                	beqz	a0,80002478 <wait+0x120>
      release(&wait_lock);
    8000244c:	0000f517          	auipc	a0,0xf
    80002450:	8ec50513          	addi	a0,a0,-1812 # 80010d38 <wait_lock>
    80002454:	fffff097          	auipc	ra,0xfffff
    80002458:	84a080e7          	jalr	-1974(ra) # 80000c9e <release>
      return -1;
    8000245c:	59fd                	li	s3,-1
}
    8000245e:	854e                	mv	a0,s3
    80002460:	60a6                	ld	ra,72(sp)
    80002462:	6406                	ld	s0,64(sp)
    80002464:	74e2                	ld	s1,56(sp)
    80002466:	7942                	ld	s2,48(sp)
    80002468:	79a2                	ld	s3,40(sp)
    8000246a:	7a02                	ld	s4,32(sp)
    8000246c:	6ae2                	ld	s5,24(sp)
    8000246e:	6b42                	ld	s6,16(sp)
    80002470:	6ba2                	ld	s7,8(sp)
    80002472:	6c02                	ld	s8,0(sp)
    80002474:	6161                	addi	sp,sp,80
    80002476:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002478:	85e2                	mv	a1,s8
    8000247a:	854a                	mv	a0,s2
    8000247c:	00000097          	auipc	ra,0x0
    80002480:	c02080e7          	jalr	-1022(ra) # 8000207e <sleep>
    havekids = 0;
    80002484:	bf39                	j	800023a2 <wait+0x4a>

0000000080002486 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002486:	7179                	addi	sp,sp,-48
    80002488:	f406                	sd	ra,40(sp)
    8000248a:	f022                	sd	s0,32(sp)
    8000248c:	ec26                	sd	s1,24(sp)
    8000248e:	e84a                	sd	s2,16(sp)
    80002490:	e44e                	sd	s3,8(sp)
    80002492:	e052                	sd	s4,0(sp)
    80002494:	1800                	addi	s0,sp,48
    80002496:	84aa                	mv	s1,a0
    80002498:	892e                	mv	s2,a1
    8000249a:	89b2                	mv	s3,a2
    8000249c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000249e:	fffff097          	auipc	ra,0xfffff
    800024a2:	528080e7          	jalr	1320(ra) # 800019c6 <myproc>
  if(user_dst){
    800024a6:	c08d                	beqz	s1,800024c8 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024a8:	86d2                	mv	a3,s4
    800024aa:	864e                	mv	a2,s3
    800024ac:	85ca                	mv	a1,s2
    800024ae:	6928                	ld	a0,80(a0)
    800024b0:	fffff097          	auipc	ra,0xfffff
    800024b4:	1d4080e7          	jalr	468(ra) # 80001684 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024b8:	70a2                	ld	ra,40(sp)
    800024ba:	7402                	ld	s0,32(sp)
    800024bc:	64e2                	ld	s1,24(sp)
    800024be:	6942                	ld	s2,16(sp)
    800024c0:	69a2                	ld	s3,8(sp)
    800024c2:	6a02                	ld	s4,0(sp)
    800024c4:	6145                	addi	sp,sp,48
    800024c6:	8082                	ret
    memmove((char *)dst, src, len);
    800024c8:	000a061b          	sext.w	a2,s4
    800024cc:	85ce                	mv	a1,s3
    800024ce:	854a                	mv	a0,s2
    800024d0:	fffff097          	auipc	ra,0xfffff
    800024d4:	876080e7          	jalr	-1930(ra) # 80000d46 <memmove>
    return 0;
    800024d8:	8526                	mv	a0,s1
    800024da:	bff9                	j	800024b8 <either_copyout+0x32>

00000000800024dc <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024dc:	7179                	addi	sp,sp,-48
    800024de:	f406                	sd	ra,40(sp)
    800024e0:	f022                	sd	s0,32(sp)
    800024e2:	ec26                	sd	s1,24(sp)
    800024e4:	e84a                	sd	s2,16(sp)
    800024e6:	e44e                	sd	s3,8(sp)
    800024e8:	e052                	sd	s4,0(sp)
    800024ea:	1800                	addi	s0,sp,48
    800024ec:	892a                	mv	s2,a0
    800024ee:	84ae                	mv	s1,a1
    800024f0:	89b2                	mv	s3,a2
    800024f2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024f4:	fffff097          	auipc	ra,0xfffff
    800024f8:	4d2080e7          	jalr	1234(ra) # 800019c6 <myproc>
  if(user_src){
    800024fc:	c08d                	beqz	s1,8000251e <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024fe:	86d2                	mv	a3,s4
    80002500:	864e                	mv	a2,s3
    80002502:	85ca                	mv	a1,s2
    80002504:	6928                	ld	a0,80(a0)
    80002506:	fffff097          	auipc	ra,0xfffff
    8000250a:	20a080e7          	jalr	522(ra) # 80001710 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000250e:	70a2                	ld	ra,40(sp)
    80002510:	7402                	ld	s0,32(sp)
    80002512:	64e2                	ld	s1,24(sp)
    80002514:	6942                	ld	s2,16(sp)
    80002516:	69a2                	ld	s3,8(sp)
    80002518:	6a02                	ld	s4,0(sp)
    8000251a:	6145                	addi	sp,sp,48
    8000251c:	8082                	ret
    memmove(dst, (char*)src, len);
    8000251e:	000a061b          	sext.w	a2,s4
    80002522:	85ce                	mv	a1,s3
    80002524:	854a                	mv	a0,s2
    80002526:	fffff097          	auipc	ra,0xfffff
    8000252a:	820080e7          	jalr	-2016(ra) # 80000d46 <memmove>
    return 0;
    8000252e:	8526                	mv	a0,s1
    80002530:	bff9                	j	8000250e <either_copyin+0x32>

0000000080002532 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002532:	715d                	addi	sp,sp,-80
    80002534:	e486                	sd	ra,72(sp)
    80002536:	e0a2                	sd	s0,64(sp)
    80002538:	fc26                	sd	s1,56(sp)
    8000253a:	f84a                	sd	s2,48(sp)
    8000253c:	f44e                	sd	s3,40(sp)
    8000253e:	f052                	sd	s4,32(sp)
    80002540:	ec56                	sd	s5,24(sp)
    80002542:	e85a                	sd	s6,16(sp)
    80002544:	e45e                	sd	s7,8(sp)
    80002546:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002548:	00006517          	auipc	a0,0x6
    8000254c:	b8050513          	addi	a0,a0,-1152 # 800080c8 <digits+0x88>
    80002550:	ffffe097          	auipc	ra,0xffffe
    80002554:	03e080e7          	jalr	62(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002558:	0000f497          	auipc	s1,0xf
    8000255c:	d5048493          	addi	s1,s1,-688 # 800112a8 <proc+0x158>
    80002560:	00015917          	auipc	s2,0x15
    80002564:	14890913          	addi	s2,s2,328 # 800176a8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002568:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000256a:	00006997          	auipc	s3,0x6
    8000256e:	d1698993          	addi	s3,s3,-746 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002572:	00006a97          	auipc	s5,0x6
    80002576:	d16a8a93          	addi	s5,s5,-746 # 80008288 <digits+0x248>
    printf("\n");
    8000257a:	00006a17          	auipc	s4,0x6
    8000257e:	b4ea0a13          	addi	s4,s4,-1202 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002582:	00006b97          	auipc	s7,0x6
    80002586:	d46b8b93          	addi	s7,s7,-698 # 800082c8 <states.1728>
    8000258a:	a00d                	j	800025ac <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000258c:	ed86a583          	lw	a1,-296(a3)
    80002590:	8556                	mv	a0,s5
    80002592:	ffffe097          	auipc	ra,0xffffe
    80002596:	ffc080e7          	jalr	-4(ra) # 8000058e <printf>
    printf("\n");
    8000259a:	8552                	mv	a0,s4
    8000259c:	ffffe097          	auipc	ra,0xffffe
    800025a0:	ff2080e7          	jalr	-14(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025a4:	19048493          	addi	s1,s1,400
    800025a8:	03248163          	beq	s1,s2,800025ca <procdump+0x98>
    if(p->state == UNUSED)
    800025ac:	86a6                	mv	a3,s1
    800025ae:	ec04a783          	lw	a5,-320(s1)
    800025b2:	dbed                	beqz	a5,800025a4 <procdump+0x72>
      state = "???";
    800025b4:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025b6:	fcfb6be3          	bltu	s6,a5,8000258c <procdump+0x5a>
    800025ba:	1782                	slli	a5,a5,0x20
    800025bc:	9381                	srli	a5,a5,0x20
    800025be:	078e                	slli	a5,a5,0x3
    800025c0:	97de                	add	a5,a5,s7
    800025c2:	6390                	ld	a2,0(a5)
    800025c4:	f661                	bnez	a2,8000258c <procdump+0x5a>
      state = "???";
    800025c6:	864e                	mv	a2,s3
    800025c8:	b7d1                	j	8000258c <procdump+0x5a>
  }
}
    800025ca:	60a6                	ld	ra,72(sp)
    800025cc:	6406                	ld	s0,64(sp)
    800025ce:	74e2                	ld	s1,56(sp)
    800025d0:	7942                	ld	s2,48(sp)
    800025d2:	79a2                	ld	s3,40(sp)
    800025d4:	7a02                	ld	s4,32(sp)
    800025d6:	6ae2                	ld	s5,24(sp)
    800025d8:	6b42                	ld	s6,16(sp)
    800025da:	6ba2                	ld	s7,8(sp)
    800025dc:	6161                	addi	sp,sp,80
    800025de:	8082                	ret

00000000800025e0 <swtch>:
    800025e0:	00153023          	sd	ra,0(a0)
    800025e4:	00253423          	sd	sp,8(a0)
    800025e8:	e900                	sd	s0,16(a0)
    800025ea:	ed04                	sd	s1,24(a0)
    800025ec:	03253023          	sd	s2,32(a0)
    800025f0:	03353423          	sd	s3,40(a0)
    800025f4:	03453823          	sd	s4,48(a0)
    800025f8:	03553c23          	sd	s5,56(a0)
    800025fc:	05653023          	sd	s6,64(a0)
    80002600:	05753423          	sd	s7,72(a0)
    80002604:	05853823          	sd	s8,80(a0)
    80002608:	05953c23          	sd	s9,88(a0)
    8000260c:	07a53023          	sd	s10,96(a0)
    80002610:	07b53423          	sd	s11,104(a0)
    80002614:	0005b083          	ld	ra,0(a1)
    80002618:	0085b103          	ld	sp,8(a1)
    8000261c:	6980                	ld	s0,16(a1)
    8000261e:	6d84                	ld	s1,24(a1)
    80002620:	0205b903          	ld	s2,32(a1)
    80002624:	0285b983          	ld	s3,40(a1)
    80002628:	0305ba03          	ld	s4,48(a1)
    8000262c:	0385ba83          	ld	s5,56(a1)
    80002630:	0405bb03          	ld	s6,64(a1)
    80002634:	0485bb83          	ld	s7,72(a1)
    80002638:	0505bc03          	ld	s8,80(a1)
    8000263c:	0585bc83          	ld	s9,88(a1)
    80002640:	0605bd03          	ld	s10,96(a1)
    80002644:	0685bd83          	ld	s11,104(a1)
    80002648:	8082                	ret

000000008000264a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000264a:	1141                	addi	sp,sp,-16
    8000264c:	e406                	sd	ra,8(sp)
    8000264e:	e022                	sd	s0,0(sp)
    80002650:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002652:	00006597          	auipc	a1,0x6
    80002656:	ca658593          	addi	a1,a1,-858 # 800082f8 <states.1728+0x30>
    8000265a:	00015517          	auipc	a0,0x15
    8000265e:	ef650513          	addi	a0,a0,-266 # 80017550 <tickslock>
    80002662:	ffffe097          	auipc	ra,0xffffe
    80002666:	4f8080e7          	jalr	1272(ra) # 80000b5a <initlock>
}
    8000266a:	60a2                	ld	ra,8(sp)
    8000266c:	6402                	ld	s0,0(sp)
    8000266e:	0141                	addi	sp,sp,16
    80002670:	8082                	ret

0000000080002672 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002672:	1141                	addi	sp,sp,-16
    80002674:	e422                	sd	s0,8(sp)
    80002676:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002678:	00003797          	auipc	a5,0x3
    8000267c:	60878793          	addi	a5,a5,1544 # 80005c80 <kernelvec>
    80002680:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002684:	6422                	ld	s0,8(sp)
    80002686:	0141                	addi	sp,sp,16
    80002688:	8082                	ret

000000008000268a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000268a:	1141                	addi	sp,sp,-16
    8000268c:	e406                	sd	ra,8(sp)
    8000268e:	e022                	sd	s0,0(sp)
    80002690:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002692:	fffff097          	auipc	ra,0xfffff
    80002696:	334080e7          	jalr	820(ra) # 800019c6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000269a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000269e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026a0:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800026a4:	00005617          	auipc	a2,0x5
    800026a8:	95c60613          	addi	a2,a2,-1700 # 80007000 <_trampoline>
    800026ac:	00005697          	auipc	a3,0x5
    800026b0:	95468693          	addi	a3,a3,-1708 # 80007000 <_trampoline>
    800026b4:	8e91                	sub	a3,a3,a2
    800026b6:	040007b7          	lui	a5,0x4000
    800026ba:	17fd                	addi	a5,a5,-1
    800026bc:	07b2                	slli	a5,a5,0xc
    800026be:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026c0:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026c4:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026c6:	180026f3          	csrr	a3,satp
    800026ca:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026cc:	6d38                	ld	a4,88(a0)
    800026ce:	6134                	ld	a3,64(a0)
    800026d0:	6585                	lui	a1,0x1
    800026d2:	96ae                	add	a3,a3,a1
    800026d4:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026d6:	6d38                	ld	a4,88(a0)
    800026d8:	00000697          	auipc	a3,0x0
    800026dc:	13068693          	addi	a3,a3,304 # 80002808 <usertrap>
    800026e0:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026e2:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026e4:	8692                	mv	a3,tp
    800026e6:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026e8:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026ec:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026f0:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026f4:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026f8:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026fa:	6f18                	ld	a4,24(a4)
    800026fc:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002700:	6928                	ld	a0,80(a0)
    80002702:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002704:	00005717          	auipc	a4,0x5
    80002708:	99870713          	addi	a4,a4,-1640 # 8000709c <userret>
    8000270c:	8f11                	sub	a4,a4,a2
    8000270e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002710:	577d                	li	a4,-1
    80002712:	177e                	slli	a4,a4,0x3f
    80002714:	8d59                	or	a0,a0,a4
    80002716:	9782                	jalr	a5
}
    80002718:	60a2                	ld	ra,8(sp)
    8000271a:	6402                	ld	s0,0(sp)
    8000271c:	0141                	addi	sp,sp,16
    8000271e:	8082                	ret

0000000080002720 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002720:	1101                	addi	sp,sp,-32
    80002722:	ec06                	sd	ra,24(sp)
    80002724:	e822                	sd	s0,16(sp)
    80002726:	e426                	sd	s1,8(sp)
    80002728:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000272a:	00015497          	auipc	s1,0x15
    8000272e:	e2648493          	addi	s1,s1,-474 # 80017550 <tickslock>
    80002732:	8526                	mv	a0,s1
    80002734:	ffffe097          	auipc	ra,0xffffe
    80002738:	4b6080e7          	jalr	1206(ra) # 80000bea <acquire>
  ticks++;
    8000273c:	00006517          	auipc	a0,0x6
    80002740:	37450513          	addi	a0,a0,884 # 80008ab0 <ticks>
    80002744:	411c                	lw	a5,0(a0)
    80002746:	2785                	addiw	a5,a5,1
    80002748:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000274a:	00000097          	auipc	ra,0x0
    8000274e:	998080e7          	jalr	-1640(ra) # 800020e2 <wakeup>
  release(&tickslock);
    80002752:	8526                	mv	a0,s1
    80002754:	ffffe097          	auipc	ra,0xffffe
    80002758:	54a080e7          	jalr	1354(ra) # 80000c9e <release>
}
    8000275c:	60e2                	ld	ra,24(sp)
    8000275e:	6442                	ld	s0,16(sp)
    80002760:	64a2                	ld	s1,8(sp)
    80002762:	6105                	addi	sp,sp,32
    80002764:	8082                	ret

0000000080002766 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002766:	1101                	addi	sp,sp,-32
    80002768:	ec06                	sd	ra,24(sp)
    8000276a:	e822                	sd	s0,16(sp)
    8000276c:	e426                	sd	s1,8(sp)
    8000276e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002770:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002774:	00074d63          	bltz	a4,8000278e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002778:	57fd                	li	a5,-1
    8000277a:	17fe                	slli	a5,a5,0x3f
    8000277c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000277e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002780:	06f70363          	beq	a4,a5,800027e6 <devintr+0x80>
  }
}
    80002784:	60e2                	ld	ra,24(sp)
    80002786:	6442                	ld	s0,16(sp)
    80002788:	64a2                	ld	s1,8(sp)
    8000278a:	6105                	addi	sp,sp,32
    8000278c:	8082                	ret
     (scause & 0xff) == 9){
    8000278e:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002792:	46a5                	li	a3,9
    80002794:	fed792e3          	bne	a5,a3,80002778 <devintr+0x12>
    int irq = plic_claim();
    80002798:	00003097          	auipc	ra,0x3
    8000279c:	5f0080e7          	jalr	1520(ra) # 80005d88 <plic_claim>
    800027a0:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027a2:	47a9                	li	a5,10
    800027a4:	02f50763          	beq	a0,a5,800027d2 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027a8:	4785                	li	a5,1
    800027aa:	02f50963          	beq	a0,a5,800027dc <devintr+0x76>
    return 1;
    800027ae:	4505                	li	a0,1
    } else if(irq){
    800027b0:	d8f1                	beqz	s1,80002784 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027b2:	85a6                	mv	a1,s1
    800027b4:	00006517          	auipc	a0,0x6
    800027b8:	b4c50513          	addi	a0,a0,-1204 # 80008300 <states.1728+0x38>
    800027bc:	ffffe097          	auipc	ra,0xffffe
    800027c0:	dd2080e7          	jalr	-558(ra) # 8000058e <printf>
      plic_complete(irq);
    800027c4:	8526                	mv	a0,s1
    800027c6:	00003097          	auipc	ra,0x3
    800027ca:	5e6080e7          	jalr	1510(ra) # 80005dac <plic_complete>
    return 1;
    800027ce:	4505                	li	a0,1
    800027d0:	bf55                	j	80002784 <devintr+0x1e>
      uartintr();
    800027d2:	ffffe097          	auipc	ra,0xffffe
    800027d6:	1dc080e7          	jalr	476(ra) # 800009ae <uartintr>
    800027da:	b7ed                	j	800027c4 <devintr+0x5e>
      virtio_disk_intr();
    800027dc:	00004097          	auipc	ra,0x4
    800027e0:	afa080e7          	jalr	-1286(ra) # 800062d6 <virtio_disk_intr>
    800027e4:	b7c5                	j	800027c4 <devintr+0x5e>
    if(cpuid() == 0){
    800027e6:	fffff097          	auipc	ra,0xfffff
    800027ea:	1b4080e7          	jalr	436(ra) # 8000199a <cpuid>
    800027ee:	c901                	beqz	a0,800027fe <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027f0:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027f4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027f6:	14479073          	csrw	sip,a5
    return 2;
    800027fa:	4509                	li	a0,2
    800027fc:	b761                	j	80002784 <devintr+0x1e>
      clockintr();
    800027fe:	00000097          	auipc	ra,0x0
    80002802:	f22080e7          	jalr	-222(ra) # 80002720 <clockintr>
    80002806:	b7ed                	j	800027f0 <devintr+0x8a>

0000000080002808 <usertrap>:
{
    80002808:	1101                	addi	sp,sp,-32
    8000280a:	ec06                	sd	ra,24(sp)
    8000280c:	e822                	sd	s0,16(sp)
    8000280e:	e426                	sd	s1,8(sp)
    80002810:	e04a                	sd	s2,0(sp)
    80002812:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002814:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002818:	1007f793          	andi	a5,a5,256
    8000281c:	efb9                	bnez	a5,8000287a <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000281e:	00003797          	auipc	a5,0x3
    80002822:	46278793          	addi	a5,a5,1122 # 80005c80 <kernelvec>
    80002826:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000282a:	fffff097          	auipc	ra,0xfffff
    8000282e:	19c080e7          	jalr	412(ra) # 800019c6 <myproc>
    80002832:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002834:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002836:	14102773          	csrr	a4,sepc
    8000283a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000283c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002840:	47a1                	li	a5,8
    80002842:	04f70463          	beq	a4,a5,8000288a <usertrap+0x82>
  } else if((which_dev = devintr()) != 0){
    80002846:	00000097          	auipc	ra,0x0
    8000284a:	f20080e7          	jalr	-224(ra) # 80002766 <devintr>
    8000284e:	892a                	mv	s2,a0
    80002850:	cd61                	beqz	a0,80002928 <usertrap+0x120>
    if(which_dev == 2 && myproc()->interval) {
    80002852:	4789                	li	a5,2
    80002854:	06f50663          	beq	a0,a5,800028c0 <usertrap+0xb8>
  if(killed(p))
    80002858:	8526                	mv	a0,s1
    8000285a:	00000097          	auipc	ra,0x0
    8000285e:	acc080e7          	jalr	-1332(ra) # 80002326 <killed>
    80002862:	10051063          	bnez	a0,80002962 <usertrap+0x15a>
  usertrapret();
    80002866:	00000097          	auipc	ra,0x0
    8000286a:	e24080e7          	jalr	-476(ra) # 8000268a <usertrapret>
}
    8000286e:	60e2                	ld	ra,24(sp)
    80002870:	6442                	ld	s0,16(sp)
    80002872:	64a2                	ld	s1,8(sp)
    80002874:	6902                	ld	s2,0(sp)
    80002876:	6105                	addi	sp,sp,32
    80002878:	8082                	ret
    panic("usertrap: not from user mode");
    8000287a:	00006517          	auipc	a0,0x6
    8000287e:	aa650513          	addi	a0,a0,-1370 # 80008320 <states.1728+0x58>
    80002882:	ffffe097          	auipc	ra,0xffffe
    80002886:	cc2080e7          	jalr	-830(ra) # 80000544 <panic>
    if(killed(p))
    8000288a:	00000097          	auipc	ra,0x0
    8000288e:	a9c080e7          	jalr	-1380(ra) # 80002326 <killed>
    80002892:	e10d                	bnez	a0,800028b4 <usertrap+0xac>
    p->trapframe->epc += 4;
    80002894:	6cb8                	ld	a4,88(s1)
    80002896:	6f1c                	ld	a5,24(a4)
    80002898:	0791                	addi	a5,a5,4
    8000289a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000289c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028a0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028a4:	10079073          	csrw	sstatus,a5
    syscall();
    800028a8:	00000097          	auipc	ra,0x0
    800028ac:	31e080e7          	jalr	798(ra) # 80002bc6 <syscall>
  int which_dev = 0;
    800028b0:	4901                	li	s2,0
    800028b2:	b75d                	j	80002858 <usertrap+0x50>
      exit(-1);
    800028b4:	557d                	li	a0,-1
    800028b6:	00000097          	auipc	ra,0x0
    800028ba:	8fc080e7          	jalr	-1796(ra) # 800021b2 <exit>
    800028be:	bfd9                	j	80002894 <usertrap+0x8c>
    if(which_dev == 2 && myproc()->interval) {
    800028c0:	fffff097          	auipc	ra,0xfffff
    800028c4:	106080e7          	jalr	262(ra) # 800019c6 <myproc>
    800028c8:	16c52783          	lw	a5,364(a0)
    800028cc:	ef89                	bnez	a5,800028e6 <usertrap+0xde>
  if(killed(p))
    800028ce:	8526                	mv	a0,s1
    800028d0:	00000097          	auipc	ra,0x0
    800028d4:	a56080e7          	jalr	-1450(ra) # 80002326 <killed>
    800028d8:	cd49                	beqz	a0,80002972 <usertrap+0x16a>
    exit(-1);
    800028da:	557d                	li	a0,-1
    800028dc:	00000097          	auipc	ra,0x0
    800028e0:	8d6080e7          	jalr	-1834(ra) # 800021b2 <exit>
    if(which_dev == 2)
    800028e4:	a079                	j	80002972 <usertrap+0x16a>
      myproc()->ticks_left--;
    800028e6:	fffff097          	auipc	ra,0xfffff
    800028ea:	0e0080e7          	jalr	224(ra) # 800019c6 <myproc>
    800028ee:	17052783          	lw	a5,368(a0)
    800028f2:	37fd                	addiw	a5,a5,-1
    800028f4:	16f52823          	sw	a5,368(a0)
      if(myproc()->ticks_left == 0) {
    800028f8:	fffff097          	auipc	ra,0xfffff
    800028fc:	0ce080e7          	jalr	206(ra) # 800019c6 <myproc>
    80002900:	17052783          	lw	a5,368(a0)
    80002904:	f7e9                	bnez	a5,800028ce <usertrap+0xc6>
        p->sigalarm_tf = kalloc();
    80002906:	ffffe097          	auipc	ra,0xffffe
    8000290a:	1f4080e7          	jalr	500(ra) # 80000afa <kalloc>
    8000290e:	18a4b023          	sd	a0,384(s1)
        memmove(p->sigalarm_tf, p->trapframe, PGSIZE);
    80002912:	6605                	lui	a2,0x1
    80002914:	6cac                	ld	a1,88(s1)
    80002916:	ffffe097          	auipc	ra,0xffffe
    8000291a:	430080e7          	jalr	1072(ra) # 80000d46 <memmove>
        p->trapframe->epc = p->sig_handler;
    8000291e:	6cbc                	ld	a5,88(s1)
    80002920:	1784b703          	ld	a4,376(s1)
    80002924:	ef98                	sd	a4,24(a5)
    80002926:	b765                	j	800028ce <usertrap+0xc6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002928:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000292c:	5890                	lw	a2,48(s1)
    8000292e:	00006517          	auipc	a0,0x6
    80002932:	a1250513          	addi	a0,a0,-1518 # 80008340 <states.1728+0x78>
    80002936:	ffffe097          	auipc	ra,0xffffe
    8000293a:	c58080e7          	jalr	-936(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000293e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002942:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002946:	00006517          	auipc	a0,0x6
    8000294a:	a2a50513          	addi	a0,a0,-1494 # 80008370 <states.1728+0xa8>
    8000294e:	ffffe097          	auipc	ra,0xffffe
    80002952:	c40080e7          	jalr	-960(ra) # 8000058e <printf>
    setkilled(p);
    80002956:	8526                	mv	a0,s1
    80002958:	00000097          	auipc	ra,0x0
    8000295c:	9a2080e7          	jalr	-1630(ra) # 800022fa <setkilled>
    80002960:	bde5                	j	80002858 <usertrap+0x50>
    exit(-1);
    80002962:	557d                	li	a0,-1
    80002964:	00000097          	auipc	ra,0x0
    80002968:	84e080e7          	jalr	-1970(ra) # 800021b2 <exit>
    if(which_dev == 2)
    8000296c:	4789                	li	a5,2
    8000296e:	eef91ce3          	bne	s2,a5,80002866 <usertrap+0x5e>
      yield();
    80002972:	fffff097          	auipc	ra,0xfffff
    80002976:	6d0080e7          	jalr	1744(ra) # 80002042 <yield>
    8000297a:	b5f5                	j	80002866 <usertrap+0x5e>

000000008000297c <kerneltrap>:
{
    8000297c:	7179                	addi	sp,sp,-48
    8000297e:	f406                	sd	ra,40(sp)
    80002980:	f022                	sd	s0,32(sp)
    80002982:	ec26                	sd	s1,24(sp)
    80002984:	e84a                	sd	s2,16(sp)
    80002986:	e44e                	sd	s3,8(sp)
    80002988:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000298a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000298e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002992:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002996:	1004f793          	andi	a5,s1,256
    8000299a:	cb85                	beqz	a5,800029ca <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000299c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029a0:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029a2:	ef85                	bnez	a5,800029da <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029a4:	00000097          	auipc	ra,0x0
    800029a8:	dc2080e7          	jalr	-574(ra) # 80002766 <devintr>
    800029ac:	cd1d                	beqz	a0,800029ea <kerneltrap+0x6e>
    if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029ae:	4789                	li	a5,2
    800029b0:	06f50a63          	beq	a0,a5,80002a24 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029b4:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029b8:	10049073          	csrw	sstatus,s1
}
    800029bc:	70a2                	ld	ra,40(sp)
    800029be:	7402                	ld	s0,32(sp)
    800029c0:	64e2                	ld	s1,24(sp)
    800029c2:	6942                	ld	s2,16(sp)
    800029c4:	69a2                	ld	s3,8(sp)
    800029c6:	6145                	addi	sp,sp,48
    800029c8:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029ca:	00006517          	auipc	a0,0x6
    800029ce:	9c650513          	addi	a0,a0,-1594 # 80008390 <states.1728+0xc8>
    800029d2:	ffffe097          	auipc	ra,0xffffe
    800029d6:	b72080e7          	jalr	-1166(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    800029da:	00006517          	auipc	a0,0x6
    800029de:	9de50513          	addi	a0,a0,-1570 # 800083b8 <states.1728+0xf0>
    800029e2:	ffffe097          	auipc	ra,0xffffe
    800029e6:	b62080e7          	jalr	-1182(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    800029ea:	85ce                	mv	a1,s3
    800029ec:	00006517          	auipc	a0,0x6
    800029f0:	9ec50513          	addi	a0,a0,-1556 # 800083d8 <states.1728+0x110>
    800029f4:	ffffe097          	auipc	ra,0xffffe
    800029f8:	b9a080e7          	jalr	-1126(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029fc:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a00:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a04:	00006517          	auipc	a0,0x6
    80002a08:	9e450513          	addi	a0,a0,-1564 # 800083e8 <states.1728+0x120>
    80002a0c:	ffffe097          	auipc	ra,0xffffe
    80002a10:	b82080e7          	jalr	-1150(ra) # 8000058e <printf>
    panic("kerneltrap");
    80002a14:	00006517          	auipc	a0,0x6
    80002a18:	9ec50513          	addi	a0,a0,-1556 # 80008400 <states.1728+0x138>
    80002a1c:	ffffe097          	auipc	ra,0xffffe
    80002a20:	b28080e7          	jalr	-1240(ra) # 80000544 <panic>
    if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a24:	fffff097          	auipc	ra,0xfffff
    80002a28:	fa2080e7          	jalr	-94(ra) # 800019c6 <myproc>
    80002a2c:	d541                	beqz	a0,800029b4 <kerneltrap+0x38>
    80002a2e:	fffff097          	auipc	ra,0xfffff
    80002a32:	f98080e7          	jalr	-104(ra) # 800019c6 <myproc>
    80002a36:	4d18                	lw	a4,24(a0)
    80002a38:	4791                	li	a5,4
    80002a3a:	f6f71de3          	bne	a4,a5,800029b4 <kerneltrap+0x38>
      yield();
    80002a3e:	fffff097          	auipc	ra,0xfffff
    80002a42:	604080e7          	jalr	1540(ra) # 80002042 <yield>
    80002a46:	b7bd                	j	800029b4 <kerneltrap+0x38>

0000000080002a48 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a48:	1101                	addi	sp,sp,-32
    80002a4a:	ec06                	sd	ra,24(sp)
    80002a4c:	e822                	sd	s0,16(sp)
    80002a4e:	e426                	sd	s1,8(sp)
    80002a50:	1000                	addi	s0,sp,32
    80002a52:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a54:	fffff097          	auipc	ra,0xfffff
    80002a58:	f72080e7          	jalr	-142(ra) # 800019c6 <myproc>
  switch (n) {
    80002a5c:	4795                	li	a5,5
    80002a5e:	0497e163          	bltu	a5,s1,80002aa0 <argraw+0x58>
    80002a62:	048a                	slli	s1,s1,0x2
    80002a64:	00006717          	auipc	a4,0x6
    80002a68:	ab470713          	addi	a4,a4,-1356 # 80008518 <states.1728+0x250>
    80002a6c:	94ba                	add	s1,s1,a4
    80002a6e:	409c                	lw	a5,0(s1)
    80002a70:	97ba                	add	a5,a5,a4
    80002a72:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a74:	6d3c                	ld	a5,88(a0)
    80002a76:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a78:	60e2                	ld	ra,24(sp)
    80002a7a:	6442                	ld	s0,16(sp)
    80002a7c:	64a2                	ld	s1,8(sp)
    80002a7e:	6105                	addi	sp,sp,32
    80002a80:	8082                	ret
    return p->trapframe->a1;
    80002a82:	6d3c                	ld	a5,88(a0)
    80002a84:	7fa8                	ld	a0,120(a5)
    80002a86:	bfcd                	j	80002a78 <argraw+0x30>
    return p->trapframe->a2;
    80002a88:	6d3c                	ld	a5,88(a0)
    80002a8a:	63c8                	ld	a0,128(a5)
    80002a8c:	b7f5                	j	80002a78 <argraw+0x30>
    return p->trapframe->a3;
    80002a8e:	6d3c                	ld	a5,88(a0)
    80002a90:	67c8                	ld	a0,136(a5)
    80002a92:	b7dd                	j	80002a78 <argraw+0x30>
    return p->trapframe->a4;
    80002a94:	6d3c                	ld	a5,88(a0)
    80002a96:	6bc8                	ld	a0,144(a5)
    80002a98:	b7c5                	j	80002a78 <argraw+0x30>
    return p->trapframe->a5;
    80002a9a:	6d3c                	ld	a5,88(a0)
    80002a9c:	6fc8                	ld	a0,152(a5)
    80002a9e:	bfe9                	j	80002a78 <argraw+0x30>
  panic("argraw");
    80002aa0:	00006517          	auipc	a0,0x6
    80002aa4:	97050513          	addi	a0,a0,-1680 # 80008410 <states.1728+0x148>
    80002aa8:	ffffe097          	auipc	ra,0xffffe
    80002aac:	a9c080e7          	jalr	-1380(ra) # 80000544 <panic>

0000000080002ab0 <fetchaddr>:
{
    80002ab0:	1101                	addi	sp,sp,-32
    80002ab2:	ec06                	sd	ra,24(sp)
    80002ab4:	e822                	sd	s0,16(sp)
    80002ab6:	e426                	sd	s1,8(sp)
    80002ab8:	e04a                	sd	s2,0(sp)
    80002aba:	1000                	addi	s0,sp,32
    80002abc:	84aa                	mv	s1,a0
    80002abe:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ac0:	fffff097          	auipc	ra,0xfffff
    80002ac4:	f06080e7          	jalr	-250(ra) # 800019c6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002ac8:	653c                	ld	a5,72(a0)
    80002aca:	02f4f863          	bgeu	s1,a5,80002afa <fetchaddr+0x4a>
    80002ace:	00848713          	addi	a4,s1,8
    80002ad2:	02e7e663          	bltu	a5,a4,80002afe <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ad6:	46a1                	li	a3,8
    80002ad8:	8626                	mv	a2,s1
    80002ada:	85ca                	mv	a1,s2
    80002adc:	6928                	ld	a0,80(a0)
    80002ade:	fffff097          	auipc	ra,0xfffff
    80002ae2:	c32080e7          	jalr	-974(ra) # 80001710 <copyin>
    80002ae6:	00a03533          	snez	a0,a0
    80002aea:	40a00533          	neg	a0,a0
}
    80002aee:	60e2                	ld	ra,24(sp)
    80002af0:	6442                	ld	s0,16(sp)
    80002af2:	64a2                	ld	s1,8(sp)
    80002af4:	6902                	ld	s2,0(sp)
    80002af6:	6105                	addi	sp,sp,32
    80002af8:	8082                	ret
    return -1;
    80002afa:	557d                	li	a0,-1
    80002afc:	bfcd                	j	80002aee <fetchaddr+0x3e>
    80002afe:	557d                	li	a0,-1
    80002b00:	b7fd                	j	80002aee <fetchaddr+0x3e>

0000000080002b02 <fetchstr>:
{
    80002b02:	7179                	addi	sp,sp,-48
    80002b04:	f406                	sd	ra,40(sp)
    80002b06:	f022                	sd	s0,32(sp)
    80002b08:	ec26                	sd	s1,24(sp)
    80002b0a:	e84a                	sd	s2,16(sp)
    80002b0c:	e44e                	sd	s3,8(sp)
    80002b0e:	1800                	addi	s0,sp,48
    80002b10:	892a                	mv	s2,a0
    80002b12:	84ae                	mv	s1,a1
    80002b14:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b16:	fffff097          	auipc	ra,0xfffff
    80002b1a:	eb0080e7          	jalr	-336(ra) # 800019c6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002b1e:	86ce                	mv	a3,s3
    80002b20:	864a                	mv	a2,s2
    80002b22:	85a6                	mv	a1,s1
    80002b24:	6928                	ld	a0,80(a0)
    80002b26:	fffff097          	auipc	ra,0xfffff
    80002b2a:	c76080e7          	jalr	-906(ra) # 8000179c <copyinstr>
    80002b2e:	00054e63          	bltz	a0,80002b4a <fetchstr+0x48>
  return strlen(buf);
    80002b32:	8526                	mv	a0,s1
    80002b34:	ffffe097          	auipc	ra,0xffffe
    80002b38:	336080e7          	jalr	822(ra) # 80000e6a <strlen>
}
    80002b3c:	70a2                	ld	ra,40(sp)
    80002b3e:	7402                	ld	s0,32(sp)
    80002b40:	64e2                	ld	s1,24(sp)
    80002b42:	6942                	ld	s2,16(sp)
    80002b44:	69a2                	ld	s3,8(sp)
    80002b46:	6145                	addi	sp,sp,48
    80002b48:	8082                	ret
    return -1;
    80002b4a:	557d                	li	a0,-1
    80002b4c:	bfc5                	j	80002b3c <fetchstr+0x3a>

0000000080002b4e <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002b4e:	1101                	addi	sp,sp,-32
    80002b50:	ec06                	sd	ra,24(sp)
    80002b52:	e822                	sd	s0,16(sp)
    80002b54:	e426                	sd	s1,8(sp)
    80002b56:	1000                	addi	s0,sp,32
    80002b58:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b5a:	00000097          	auipc	ra,0x0
    80002b5e:	eee080e7          	jalr	-274(ra) # 80002a48 <argraw>
    80002b62:	c088                	sw	a0,0(s1)
}
    80002b64:	60e2                	ld	ra,24(sp)
    80002b66:	6442                	ld	s0,16(sp)
    80002b68:	64a2                	ld	s1,8(sp)
    80002b6a:	6105                	addi	sp,sp,32
    80002b6c:	8082                	ret

0000000080002b6e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002b6e:	1101                	addi	sp,sp,-32
    80002b70:	ec06                	sd	ra,24(sp)
    80002b72:	e822                	sd	s0,16(sp)
    80002b74:	e426                	sd	s1,8(sp)
    80002b76:	1000                	addi	s0,sp,32
    80002b78:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b7a:	00000097          	auipc	ra,0x0
    80002b7e:	ece080e7          	jalr	-306(ra) # 80002a48 <argraw>
    80002b82:	e088                	sd	a0,0(s1)
}
    80002b84:	60e2                	ld	ra,24(sp)
    80002b86:	6442                	ld	s0,16(sp)
    80002b88:	64a2                	ld	s1,8(sp)
    80002b8a:	6105                	addi	sp,sp,32
    80002b8c:	8082                	ret

0000000080002b8e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b8e:	7179                	addi	sp,sp,-48
    80002b90:	f406                	sd	ra,40(sp)
    80002b92:	f022                	sd	s0,32(sp)
    80002b94:	ec26                	sd	s1,24(sp)
    80002b96:	e84a                	sd	s2,16(sp)
    80002b98:	1800                	addi	s0,sp,48
    80002b9a:	84ae                	mv	s1,a1
    80002b9c:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002b9e:	fd840593          	addi	a1,s0,-40
    80002ba2:	00000097          	auipc	ra,0x0
    80002ba6:	fcc080e7          	jalr	-52(ra) # 80002b6e <argaddr>
  return fetchstr(addr, buf, max);
    80002baa:	864a                	mv	a2,s2
    80002bac:	85a6                	mv	a1,s1
    80002bae:	fd843503          	ld	a0,-40(s0)
    80002bb2:	00000097          	auipc	ra,0x0
    80002bb6:	f50080e7          	jalr	-176(ra) # 80002b02 <fetchstr>
}
    80002bba:	70a2                	ld	ra,40(sp)
    80002bbc:	7402                	ld	s0,32(sp)
    80002bbe:	64e2                	ld	s1,24(sp)
    80002bc0:	6942                	ld	s2,16(sp)
    80002bc2:	6145                	addi	sp,sp,48
    80002bc4:	8082                	ret

0000000080002bc6 <syscall>:
[SYS_sigreturn] "sigreturn ",
};

void
syscall(void)
{
    80002bc6:	7179                	addi	sp,sp,-48
    80002bc8:	f406                	sd	ra,40(sp)
    80002bca:	f022                	sd	s0,32(sp)
    80002bcc:	ec26                	sd	s1,24(sp)
    80002bce:	e84a                	sd	s2,16(sp)
    80002bd0:	e44e                	sd	s3,8(sp)
    80002bd2:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80002bd4:	fffff097          	auipc	ra,0xfffff
    80002bd8:	df2080e7          	jalr	-526(ra) # 800019c6 <myproc>
    80002bdc:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002bde:	05853903          	ld	s2,88(a0)
    80002be2:	0a893783          	ld	a5,168(s2)
    80002be6:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002bea:	37fd                	addiw	a5,a5,-1
    80002bec:	4761                	li	a4,24
    80002bee:	04f76763          	bltu	a4,a5,80002c3c <syscall+0x76>
    80002bf2:	00399713          	slli	a4,s3,0x3
    80002bf6:	00006797          	auipc	a5,0x6
    80002bfa:	93a78793          	addi	a5,a5,-1734 # 80008530 <syscalls>
    80002bfe:	97ba                	add	a5,a5,a4
    80002c00:	639c                	ld	a5,0(a5)
    80002c02:	cf8d                	beqz	a5,80002c3c <syscall+0x76>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002c04:	9782                	jalr	a5
    80002c06:	06a93823          	sd	a0,112(s2)

    // Check for trace_flag to be on
    if(p->trace_flag >> num) {  // check for '=='
    80002c0a:	1684a783          	lw	a5,360(s1)
    80002c0e:	4137d7bb          	sraw	a5,a5,s3
    80002c12:	c7a1                	beqz	a5,80002c5a <syscall+0x94>
      printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0);
    80002c14:	6cb8                	ld	a4,88(s1)
    80002c16:	098e                	slli	s3,s3,0x3
    80002c18:	00006797          	auipc	a5,0x6
    80002c1c:	d7078793          	addi	a5,a5,-656 # 80008988 <syscall_names>
    80002c20:	99be                	add	s3,s3,a5
    80002c22:	7b34                	ld	a3,112(a4)
    80002c24:	0009b603          	ld	a2,0(s3)
    80002c28:	588c                	lw	a1,48(s1)
    80002c2a:	00005517          	auipc	a0,0x5
    80002c2e:	7ee50513          	addi	a0,a0,2030 # 80008418 <states.1728+0x150>
    80002c32:	ffffe097          	auipc	ra,0xffffe
    80002c36:	95c080e7          	jalr	-1700(ra) # 8000058e <printf>
    80002c3a:	a005                	j	80002c5a <syscall+0x94>
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c3c:	86ce                	mv	a3,s3
    80002c3e:	15848613          	addi	a2,s1,344
    80002c42:	588c                	lw	a1,48(s1)
    80002c44:	00005517          	auipc	a0,0x5
    80002c48:	7ec50513          	addi	a0,a0,2028 # 80008430 <states.1728+0x168>
    80002c4c:	ffffe097          	auipc	ra,0xffffe
    80002c50:	942080e7          	jalr	-1726(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c54:	6cbc                	ld	a5,88(s1)
    80002c56:	577d                	li	a4,-1
    80002c58:	fbb8                	sd	a4,112(a5)
  }
}
    80002c5a:	70a2                	ld	ra,40(sp)
    80002c5c:	7402                	ld	s0,32(sp)
    80002c5e:	64e2                	ld	s1,24(sp)
    80002c60:	6942                	ld	s2,16(sp)
    80002c62:	69a2                	ld	s3,8(sp)
    80002c64:	6145                	addi	sp,sp,48
    80002c66:	8082                	ret

0000000080002c68 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c68:	1101                	addi	sp,sp,-32
    80002c6a:	ec06                	sd	ra,24(sp)
    80002c6c:	e822                	sd	s0,16(sp)
    80002c6e:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002c70:	fec40593          	addi	a1,s0,-20
    80002c74:	4501                	li	a0,0
    80002c76:	00000097          	auipc	ra,0x0
    80002c7a:	ed8080e7          	jalr	-296(ra) # 80002b4e <argint>
  exit(n);
    80002c7e:	fec42503          	lw	a0,-20(s0)
    80002c82:	fffff097          	auipc	ra,0xfffff
    80002c86:	530080e7          	jalr	1328(ra) # 800021b2 <exit>
  return 0;  // not reached
}
    80002c8a:	4501                	li	a0,0
    80002c8c:	60e2                	ld	ra,24(sp)
    80002c8e:	6442                	ld	s0,16(sp)
    80002c90:	6105                	addi	sp,sp,32
    80002c92:	8082                	ret

0000000080002c94 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c94:	1141                	addi	sp,sp,-16
    80002c96:	e406                	sd	ra,8(sp)
    80002c98:	e022                	sd	s0,0(sp)
    80002c9a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c9c:	fffff097          	auipc	ra,0xfffff
    80002ca0:	d2a080e7          	jalr	-726(ra) # 800019c6 <myproc>
}
    80002ca4:	5908                	lw	a0,48(a0)
    80002ca6:	60a2                	ld	ra,8(sp)
    80002ca8:	6402                	ld	s0,0(sp)
    80002caa:	0141                	addi	sp,sp,16
    80002cac:	8082                	ret

0000000080002cae <sys_fork>:

uint64
sys_fork(void)
{
    80002cae:	1141                	addi	sp,sp,-16
    80002cb0:	e406                	sd	ra,8(sp)
    80002cb2:	e022                	sd	s0,0(sp)
    80002cb4:	0800                	addi	s0,sp,16
  return fork();
    80002cb6:	fffff097          	auipc	ra,0xfffff
    80002cba:	0d2080e7          	jalr	210(ra) # 80001d88 <fork>
}
    80002cbe:	60a2                	ld	ra,8(sp)
    80002cc0:	6402                	ld	s0,0(sp)
    80002cc2:	0141                	addi	sp,sp,16
    80002cc4:	8082                	ret

0000000080002cc6 <sys_wait>:

uint64
sys_wait(void)
{
    80002cc6:	1101                	addi	sp,sp,-32
    80002cc8:	ec06                	sd	ra,24(sp)
    80002cca:	e822                	sd	s0,16(sp)
    80002ccc:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002cce:	fe840593          	addi	a1,s0,-24
    80002cd2:	4501                	li	a0,0
    80002cd4:	00000097          	auipc	ra,0x0
    80002cd8:	e9a080e7          	jalr	-358(ra) # 80002b6e <argaddr>
  return wait(p);
    80002cdc:	fe843503          	ld	a0,-24(s0)
    80002ce0:	fffff097          	auipc	ra,0xfffff
    80002ce4:	678080e7          	jalr	1656(ra) # 80002358 <wait>
}
    80002ce8:	60e2                	ld	ra,24(sp)
    80002cea:	6442                	ld	s0,16(sp)
    80002cec:	6105                	addi	sp,sp,32
    80002cee:	8082                	ret

0000000080002cf0 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002cf0:	7179                	addi	sp,sp,-48
    80002cf2:	f406                	sd	ra,40(sp)
    80002cf4:	f022                	sd	s0,32(sp)
    80002cf6:	ec26                	sd	s1,24(sp)
    80002cf8:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002cfa:	fdc40593          	addi	a1,s0,-36
    80002cfe:	4501                	li	a0,0
    80002d00:	00000097          	auipc	ra,0x0
    80002d04:	e4e080e7          	jalr	-434(ra) # 80002b4e <argint>
  addr = myproc()->sz;
    80002d08:	fffff097          	auipc	ra,0xfffff
    80002d0c:	cbe080e7          	jalr	-834(ra) # 800019c6 <myproc>
    80002d10:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002d12:	fdc42503          	lw	a0,-36(s0)
    80002d16:	fffff097          	auipc	ra,0xfffff
    80002d1a:	016080e7          	jalr	22(ra) # 80001d2c <growproc>
    80002d1e:	00054863          	bltz	a0,80002d2e <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002d22:	8526                	mv	a0,s1
    80002d24:	70a2                	ld	ra,40(sp)
    80002d26:	7402                	ld	s0,32(sp)
    80002d28:	64e2                	ld	s1,24(sp)
    80002d2a:	6145                	addi	sp,sp,48
    80002d2c:	8082                	ret
    return -1;
    80002d2e:	54fd                	li	s1,-1
    80002d30:	bfcd                	j	80002d22 <sys_sbrk+0x32>

0000000080002d32 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d32:	7139                	addi	sp,sp,-64
    80002d34:	fc06                	sd	ra,56(sp)
    80002d36:	f822                	sd	s0,48(sp)
    80002d38:	f426                	sd	s1,40(sp)
    80002d3a:	f04a                	sd	s2,32(sp)
    80002d3c:	ec4e                	sd	s3,24(sp)
    80002d3e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002d40:	fcc40593          	addi	a1,s0,-52
    80002d44:	4501                	li	a0,0
    80002d46:	00000097          	auipc	ra,0x0
    80002d4a:	e08080e7          	jalr	-504(ra) # 80002b4e <argint>
  acquire(&tickslock);
    80002d4e:	00015517          	auipc	a0,0x15
    80002d52:	80250513          	addi	a0,a0,-2046 # 80017550 <tickslock>
    80002d56:	ffffe097          	auipc	ra,0xffffe
    80002d5a:	e94080e7          	jalr	-364(ra) # 80000bea <acquire>
  ticks0 = ticks;
    80002d5e:	00006917          	auipc	s2,0x6
    80002d62:	d5292903          	lw	s2,-686(s2) # 80008ab0 <ticks>
  while(ticks - ticks0 < n){
    80002d66:	fcc42783          	lw	a5,-52(s0)
    80002d6a:	cf9d                	beqz	a5,80002da8 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d6c:	00014997          	auipc	s3,0x14
    80002d70:	7e498993          	addi	s3,s3,2020 # 80017550 <tickslock>
    80002d74:	00006497          	auipc	s1,0x6
    80002d78:	d3c48493          	addi	s1,s1,-708 # 80008ab0 <ticks>
    if(killed(myproc())){
    80002d7c:	fffff097          	auipc	ra,0xfffff
    80002d80:	c4a080e7          	jalr	-950(ra) # 800019c6 <myproc>
    80002d84:	fffff097          	auipc	ra,0xfffff
    80002d88:	5a2080e7          	jalr	1442(ra) # 80002326 <killed>
    80002d8c:	ed15                	bnez	a0,80002dc8 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002d8e:	85ce                	mv	a1,s3
    80002d90:	8526                	mv	a0,s1
    80002d92:	fffff097          	auipc	ra,0xfffff
    80002d96:	2ec080e7          	jalr	748(ra) # 8000207e <sleep>
  while(ticks - ticks0 < n){
    80002d9a:	409c                	lw	a5,0(s1)
    80002d9c:	412787bb          	subw	a5,a5,s2
    80002da0:	fcc42703          	lw	a4,-52(s0)
    80002da4:	fce7ece3          	bltu	a5,a4,80002d7c <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002da8:	00014517          	auipc	a0,0x14
    80002dac:	7a850513          	addi	a0,a0,1960 # 80017550 <tickslock>
    80002db0:	ffffe097          	auipc	ra,0xffffe
    80002db4:	eee080e7          	jalr	-274(ra) # 80000c9e <release>
  return 0;
    80002db8:	4501                	li	a0,0
}
    80002dba:	70e2                	ld	ra,56(sp)
    80002dbc:	7442                	ld	s0,48(sp)
    80002dbe:	74a2                	ld	s1,40(sp)
    80002dc0:	7902                	ld	s2,32(sp)
    80002dc2:	69e2                	ld	s3,24(sp)
    80002dc4:	6121                	addi	sp,sp,64
    80002dc6:	8082                	ret
      release(&tickslock);
    80002dc8:	00014517          	auipc	a0,0x14
    80002dcc:	78850513          	addi	a0,a0,1928 # 80017550 <tickslock>
    80002dd0:	ffffe097          	auipc	ra,0xffffe
    80002dd4:	ece080e7          	jalr	-306(ra) # 80000c9e <release>
      return -1;
    80002dd8:	557d                	li	a0,-1
    80002dda:	b7c5                	j	80002dba <sys_sleep+0x88>

0000000080002ddc <sys_kill>:

uint64
sys_kill(void)
{
    80002ddc:	1101                	addi	sp,sp,-32
    80002dde:	ec06                	sd	ra,24(sp)
    80002de0:	e822                	sd	s0,16(sp)
    80002de2:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002de4:	fec40593          	addi	a1,s0,-20
    80002de8:	4501                	li	a0,0
    80002dea:	00000097          	auipc	ra,0x0
    80002dee:	d64080e7          	jalr	-668(ra) # 80002b4e <argint>
  return kill(pid);
    80002df2:	fec42503          	lw	a0,-20(s0)
    80002df6:	fffff097          	auipc	ra,0xfffff
    80002dfa:	492080e7          	jalr	1170(ra) # 80002288 <kill>
}
    80002dfe:	60e2                	ld	ra,24(sp)
    80002e00:	6442                	ld	s0,16(sp)
    80002e02:	6105                	addi	sp,sp,32
    80002e04:	8082                	ret

0000000080002e06 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e06:	1101                	addi	sp,sp,-32
    80002e08:	ec06                	sd	ra,24(sp)
    80002e0a:	e822                	sd	s0,16(sp)
    80002e0c:	e426                	sd	s1,8(sp)
    80002e0e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e10:	00014517          	auipc	a0,0x14
    80002e14:	74050513          	addi	a0,a0,1856 # 80017550 <tickslock>
    80002e18:	ffffe097          	auipc	ra,0xffffe
    80002e1c:	dd2080e7          	jalr	-558(ra) # 80000bea <acquire>
  xticks = ticks;
    80002e20:	00006497          	auipc	s1,0x6
    80002e24:	c904a483          	lw	s1,-880(s1) # 80008ab0 <ticks>
  release(&tickslock);
    80002e28:	00014517          	auipc	a0,0x14
    80002e2c:	72850513          	addi	a0,a0,1832 # 80017550 <tickslock>
    80002e30:	ffffe097          	auipc	ra,0xffffe
    80002e34:	e6e080e7          	jalr	-402(ra) # 80000c9e <release>
  return xticks;
}
    80002e38:	02049513          	slli	a0,s1,0x20
    80002e3c:	9101                	srli	a0,a0,0x20
    80002e3e:	60e2                	ld	ra,24(sp)
    80002e40:	6442                	ld	s0,16(sp)
    80002e42:	64a2                	ld	s1,8(sp)
    80002e44:	6105                	addi	sp,sp,32
    80002e46:	8082                	ret

0000000080002e48 <sys_trace>:

// sets the trace_flag to the first argument (a0)
uint64
sys_trace(void)
{
    80002e48:	1141                	addi	sp,sp,-16
    80002e4a:	e406                	sd	ra,8(sp)
    80002e4c:	e022                	sd	s0,0(sp)
    80002e4e:	0800                	addi	s0,sp,16
  argint(0, &myproc()->trace_flag); //arg(a0, trace_flag) // returns void
    80002e50:	fffff097          	auipc	ra,0xfffff
    80002e54:	b76080e7          	jalr	-1162(ra) # 800019c6 <myproc>
    80002e58:	16850593          	addi	a1,a0,360
    80002e5c:	4501                	li	a0,0
    80002e5e:	00000097          	auipc	ra,0x0
    80002e62:	cf0080e7          	jalr	-784(ra) # 80002b4e <argint>
  return 0;
}
    80002e66:	4501                	li	a0,0
    80002e68:	60a2                	ld	ra,8(sp)
    80002e6a:	6402                	ld	s0,0(sp)
    80002e6c:	0141                	addi	sp,sp,16
    80002e6e:	8082                	ret

0000000080002e70 <sys_sigalarm>:

// sets the 
uint64
sys_sigalarm(void)
{
    80002e70:	1101                	addi	sp,sp,-32
    80002e72:	ec06                	sd	ra,24(sp)
    80002e74:	e822                	sd	s0,16(sp)
    80002e76:	e426                	sd	s1,8(sp)
    80002e78:	1000                	addi	s0,sp,32
  // sets the interval and handler after every tick
  argint(0, &myproc()->interval);
    80002e7a:	fffff097          	auipc	ra,0xfffff
    80002e7e:	b4c080e7          	jalr	-1204(ra) # 800019c6 <myproc>
    80002e82:	16c50593          	addi	a1,a0,364
    80002e86:	4501                	li	a0,0
    80002e88:	00000097          	auipc	ra,0x0
    80002e8c:	cc6080e7          	jalr	-826(ra) # 80002b4e <argint>
  argaddr(1, &myproc()->sig_handler);
    80002e90:	fffff097          	auipc	ra,0xfffff
    80002e94:	b36080e7          	jalr	-1226(ra) # 800019c6 <myproc>
    80002e98:	17850593          	addi	a1,a0,376
    80002e9c:	4505                	li	a0,1
    80002e9e:	00000097          	auipc	ra,0x0
    80002ea2:	cd0080e7          	jalr	-816(ra) # 80002b6e <argaddr>
  
  // sets ticks_passed as the interval
  myproc()->ticks_left = myproc()->interval;
    80002ea6:	fffff097          	auipc	ra,0xfffff
    80002eaa:	b20080e7          	jalr	-1248(ra) # 800019c6 <myproc>
    80002eae:	84aa                	mv	s1,a0
    80002eb0:	fffff097          	auipc	ra,0xfffff
    80002eb4:	b16080e7          	jalr	-1258(ra) # 800019c6 <myproc>
    80002eb8:	16c4a783          	lw	a5,364(s1)
    80002ebc:	16f52823          	sw	a5,368(a0)
  return 0;
}
    80002ec0:	4501                	li	a0,0
    80002ec2:	60e2                	ld	ra,24(sp)
    80002ec4:	6442                	ld	s0,16(sp)
    80002ec6:	64a2                	ld	s1,8(sp)
    80002ec8:	6105                	addi	sp,sp,32
    80002eca:	8082                	ret

0000000080002ecc <sys_sigreturn>:

uint64 
sys_sigreturn(void)
{
    80002ecc:	1101                	addi	sp,sp,-32
    80002ece:	ec06                	sd	ra,24(sp)
    80002ed0:	e822                	sd	s0,16(sp)
    80002ed2:	e426                	sd	s1,8(sp)
    80002ed4:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002ed6:	fffff097          	auipc	ra,0xfffff
    80002eda:	af0080e7          	jalr	-1296(ra) # 800019c6 <myproc>
    80002ede:	84aa                	mv	s1,a0
  memmove(p->trapframe, p->sigalarm_tf, PGSIZE);
    80002ee0:	6605                	lui	a2,0x1
    80002ee2:	18053583          	ld	a1,384(a0)
    80002ee6:	6d28                	ld	a0,88(a0)
    80002ee8:	ffffe097          	auipc	ra,0xffffe
    80002eec:	e5e080e7          	jalr	-418(ra) # 80000d46 <memmove>
  kfree(p->sigalarm_tf);
    80002ef0:	1804b503          	ld	a0,384(s1)
    80002ef4:	ffffe097          	auipc	ra,0xffffe
    80002ef8:	b0a080e7          	jalr	-1270(ra) # 800009fe <kfree>
  p->ticks_left = p->interval;
    80002efc:	16c4a783          	lw	a5,364(s1)
    80002f00:	16f4a823          	sw	a5,368(s1)
  return p->trapframe->a0;
    80002f04:	6cbc                	ld	a5,88(s1)
    80002f06:	7ba8                	ld	a0,112(a5)
    80002f08:	60e2                	ld	ra,24(sp)
    80002f0a:	6442                	ld	s0,16(sp)
    80002f0c:	64a2                	ld	s1,8(sp)
    80002f0e:	6105                	addi	sp,sp,32
    80002f10:	8082                	ret

0000000080002f12 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f12:	7179                	addi	sp,sp,-48
    80002f14:	f406                	sd	ra,40(sp)
    80002f16:	f022                	sd	s0,32(sp)
    80002f18:	ec26                	sd	s1,24(sp)
    80002f1a:	e84a                	sd	s2,16(sp)
    80002f1c:	e44e                	sd	s3,8(sp)
    80002f1e:	e052                	sd	s4,0(sp)
    80002f20:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f22:	00005597          	auipc	a1,0x5
    80002f26:	6de58593          	addi	a1,a1,1758 # 80008600 <syscalls+0xd0>
    80002f2a:	00014517          	auipc	a0,0x14
    80002f2e:	63e50513          	addi	a0,a0,1598 # 80017568 <bcache>
    80002f32:	ffffe097          	auipc	ra,0xffffe
    80002f36:	c28080e7          	jalr	-984(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f3a:	0001c797          	auipc	a5,0x1c
    80002f3e:	62e78793          	addi	a5,a5,1582 # 8001f568 <bcache+0x8000>
    80002f42:	0001d717          	auipc	a4,0x1d
    80002f46:	88e70713          	addi	a4,a4,-1906 # 8001f7d0 <bcache+0x8268>
    80002f4a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f4e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f52:	00014497          	auipc	s1,0x14
    80002f56:	62e48493          	addi	s1,s1,1582 # 80017580 <bcache+0x18>
    b->next = bcache.head.next;
    80002f5a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f5c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f5e:	00005a17          	auipc	s4,0x5
    80002f62:	6aaa0a13          	addi	s4,s4,1706 # 80008608 <syscalls+0xd8>
    b->next = bcache.head.next;
    80002f66:	2b893783          	ld	a5,696(s2)
    80002f6a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f6c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f70:	85d2                	mv	a1,s4
    80002f72:	01048513          	addi	a0,s1,16
    80002f76:	00001097          	auipc	ra,0x1
    80002f7a:	4c4080e7          	jalr	1220(ra) # 8000443a <initsleeplock>
    bcache.head.next->prev = b;
    80002f7e:	2b893783          	ld	a5,696(s2)
    80002f82:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f84:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f88:	45848493          	addi	s1,s1,1112
    80002f8c:	fd349de3          	bne	s1,s3,80002f66 <binit+0x54>
  }
}
    80002f90:	70a2                	ld	ra,40(sp)
    80002f92:	7402                	ld	s0,32(sp)
    80002f94:	64e2                	ld	s1,24(sp)
    80002f96:	6942                	ld	s2,16(sp)
    80002f98:	69a2                	ld	s3,8(sp)
    80002f9a:	6a02                	ld	s4,0(sp)
    80002f9c:	6145                	addi	sp,sp,48
    80002f9e:	8082                	ret

0000000080002fa0 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002fa0:	7179                	addi	sp,sp,-48
    80002fa2:	f406                	sd	ra,40(sp)
    80002fa4:	f022                	sd	s0,32(sp)
    80002fa6:	ec26                	sd	s1,24(sp)
    80002fa8:	e84a                	sd	s2,16(sp)
    80002faa:	e44e                	sd	s3,8(sp)
    80002fac:	1800                	addi	s0,sp,48
    80002fae:	89aa                	mv	s3,a0
    80002fb0:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002fb2:	00014517          	auipc	a0,0x14
    80002fb6:	5b650513          	addi	a0,a0,1462 # 80017568 <bcache>
    80002fba:	ffffe097          	auipc	ra,0xffffe
    80002fbe:	c30080e7          	jalr	-976(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fc2:	0001d497          	auipc	s1,0x1d
    80002fc6:	85e4b483          	ld	s1,-1954(s1) # 8001f820 <bcache+0x82b8>
    80002fca:	0001d797          	auipc	a5,0x1d
    80002fce:	80678793          	addi	a5,a5,-2042 # 8001f7d0 <bcache+0x8268>
    80002fd2:	02f48f63          	beq	s1,a5,80003010 <bread+0x70>
    80002fd6:	873e                	mv	a4,a5
    80002fd8:	a021                	j	80002fe0 <bread+0x40>
    80002fda:	68a4                	ld	s1,80(s1)
    80002fdc:	02e48a63          	beq	s1,a4,80003010 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002fe0:	449c                	lw	a5,8(s1)
    80002fe2:	ff379ce3          	bne	a5,s3,80002fda <bread+0x3a>
    80002fe6:	44dc                	lw	a5,12(s1)
    80002fe8:	ff2799e3          	bne	a5,s2,80002fda <bread+0x3a>
      b->refcnt++;
    80002fec:	40bc                	lw	a5,64(s1)
    80002fee:	2785                	addiw	a5,a5,1
    80002ff0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ff2:	00014517          	auipc	a0,0x14
    80002ff6:	57650513          	addi	a0,a0,1398 # 80017568 <bcache>
    80002ffa:	ffffe097          	auipc	ra,0xffffe
    80002ffe:	ca4080e7          	jalr	-860(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80003002:	01048513          	addi	a0,s1,16
    80003006:	00001097          	auipc	ra,0x1
    8000300a:	46e080e7          	jalr	1134(ra) # 80004474 <acquiresleep>
      return b;
    8000300e:	a8b9                	j	8000306c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003010:	0001d497          	auipc	s1,0x1d
    80003014:	8084b483          	ld	s1,-2040(s1) # 8001f818 <bcache+0x82b0>
    80003018:	0001c797          	auipc	a5,0x1c
    8000301c:	7b878793          	addi	a5,a5,1976 # 8001f7d0 <bcache+0x8268>
    80003020:	00f48863          	beq	s1,a5,80003030 <bread+0x90>
    80003024:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003026:	40bc                	lw	a5,64(s1)
    80003028:	cf81                	beqz	a5,80003040 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000302a:	64a4                	ld	s1,72(s1)
    8000302c:	fee49de3          	bne	s1,a4,80003026 <bread+0x86>
  panic("bget: no buffers");
    80003030:	00005517          	auipc	a0,0x5
    80003034:	5e050513          	addi	a0,a0,1504 # 80008610 <syscalls+0xe0>
    80003038:	ffffd097          	auipc	ra,0xffffd
    8000303c:	50c080e7          	jalr	1292(ra) # 80000544 <panic>
      b->dev = dev;
    80003040:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003044:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003048:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000304c:	4785                	li	a5,1
    8000304e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003050:	00014517          	auipc	a0,0x14
    80003054:	51850513          	addi	a0,a0,1304 # 80017568 <bcache>
    80003058:	ffffe097          	auipc	ra,0xffffe
    8000305c:	c46080e7          	jalr	-954(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80003060:	01048513          	addi	a0,s1,16
    80003064:	00001097          	auipc	ra,0x1
    80003068:	410080e7          	jalr	1040(ra) # 80004474 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000306c:	409c                	lw	a5,0(s1)
    8000306e:	cb89                	beqz	a5,80003080 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003070:	8526                	mv	a0,s1
    80003072:	70a2                	ld	ra,40(sp)
    80003074:	7402                	ld	s0,32(sp)
    80003076:	64e2                	ld	s1,24(sp)
    80003078:	6942                	ld	s2,16(sp)
    8000307a:	69a2                	ld	s3,8(sp)
    8000307c:	6145                	addi	sp,sp,48
    8000307e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003080:	4581                	li	a1,0
    80003082:	8526                	mv	a0,s1
    80003084:	00003097          	auipc	ra,0x3
    80003088:	fc4080e7          	jalr	-60(ra) # 80006048 <virtio_disk_rw>
    b->valid = 1;
    8000308c:	4785                	li	a5,1
    8000308e:	c09c                	sw	a5,0(s1)
  return b;
    80003090:	b7c5                	j	80003070 <bread+0xd0>

0000000080003092 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003092:	1101                	addi	sp,sp,-32
    80003094:	ec06                	sd	ra,24(sp)
    80003096:	e822                	sd	s0,16(sp)
    80003098:	e426                	sd	s1,8(sp)
    8000309a:	1000                	addi	s0,sp,32
    8000309c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000309e:	0541                	addi	a0,a0,16
    800030a0:	00001097          	auipc	ra,0x1
    800030a4:	46e080e7          	jalr	1134(ra) # 8000450e <holdingsleep>
    800030a8:	cd01                	beqz	a0,800030c0 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030aa:	4585                	li	a1,1
    800030ac:	8526                	mv	a0,s1
    800030ae:	00003097          	auipc	ra,0x3
    800030b2:	f9a080e7          	jalr	-102(ra) # 80006048 <virtio_disk_rw>
}
    800030b6:	60e2                	ld	ra,24(sp)
    800030b8:	6442                	ld	s0,16(sp)
    800030ba:	64a2                	ld	s1,8(sp)
    800030bc:	6105                	addi	sp,sp,32
    800030be:	8082                	ret
    panic("bwrite");
    800030c0:	00005517          	auipc	a0,0x5
    800030c4:	56850513          	addi	a0,a0,1384 # 80008628 <syscalls+0xf8>
    800030c8:	ffffd097          	auipc	ra,0xffffd
    800030cc:	47c080e7          	jalr	1148(ra) # 80000544 <panic>

00000000800030d0 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030d0:	1101                	addi	sp,sp,-32
    800030d2:	ec06                	sd	ra,24(sp)
    800030d4:	e822                	sd	s0,16(sp)
    800030d6:	e426                	sd	s1,8(sp)
    800030d8:	e04a                	sd	s2,0(sp)
    800030da:	1000                	addi	s0,sp,32
    800030dc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030de:	01050913          	addi	s2,a0,16
    800030e2:	854a                	mv	a0,s2
    800030e4:	00001097          	auipc	ra,0x1
    800030e8:	42a080e7          	jalr	1066(ra) # 8000450e <holdingsleep>
    800030ec:	c92d                	beqz	a0,8000315e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030ee:	854a                	mv	a0,s2
    800030f0:	00001097          	auipc	ra,0x1
    800030f4:	3da080e7          	jalr	986(ra) # 800044ca <releasesleep>

  acquire(&bcache.lock);
    800030f8:	00014517          	auipc	a0,0x14
    800030fc:	47050513          	addi	a0,a0,1136 # 80017568 <bcache>
    80003100:	ffffe097          	auipc	ra,0xffffe
    80003104:	aea080e7          	jalr	-1302(ra) # 80000bea <acquire>
  b->refcnt--;
    80003108:	40bc                	lw	a5,64(s1)
    8000310a:	37fd                	addiw	a5,a5,-1
    8000310c:	0007871b          	sext.w	a4,a5
    80003110:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003112:	eb05                	bnez	a4,80003142 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003114:	68bc                	ld	a5,80(s1)
    80003116:	64b8                	ld	a4,72(s1)
    80003118:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000311a:	64bc                	ld	a5,72(s1)
    8000311c:	68b8                	ld	a4,80(s1)
    8000311e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003120:	0001c797          	auipc	a5,0x1c
    80003124:	44878793          	addi	a5,a5,1096 # 8001f568 <bcache+0x8000>
    80003128:	2b87b703          	ld	a4,696(a5)
    8000312c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000312e:	0001c717          	auipc	a4,0x1c
    80003132:	6a270713          	addi	a4,a4,1698 # 8001f7d0 <bcache+0x8268>
    80003136:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003138:	2b87b703          	ld	a4,696(a5)
    8000313c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000313e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003142:	00014517          	auipc	a0,0x14
    80003146:	42650513          	addi	a0,a0,1062 # 80017568 <bcache>
    8000314a:	ffffe097          	auipc	ra,0xffffe
    8000314e:	b54080e7          	jalr	-1196(ra) # 80000c9e <release>
}
    80003152:	60e2                	ld	ra,24(sp)
    80003154:	6442                	ld	s0,16(sp)
    80003156:	64a2                	ld	s1,8(sp)
    80003158:	6902                	ld	s2,0(sp)
    8000315a:	6105                	addi	sp,sp,32
    8000315c:	8082                	ret
    panic("brelse");
    8000315e:	00005517          	auipc	a0,0x5
    80003162:	4d250513          	addi	a0,a0,1234 # 80008630 <syscalls+0x100>
    80003166:	ffffd097          	auipc	ra,0xffffd
    8000316a:	3de080e7          	jalr	990(ra) # 80000544 <panic>

000000008000316e <bpin>:

void
bpin(struct buf *b) {
    8000316e:	1101                	addi	sp,sp,-32
    80003170:	ec06                	sd	ra,24(sp)
    80003172:	e822                	sd	s0,16(sp)
    80003174:	e426                	sd	s1,8(sp)
    80003176:	1000                	addi	s0,sp,32
    80003178:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000317a:	00014517          	auipc	a0,0x14
    8000317e:	3ee50513          	addi	a0,a0,1006 # 80017568 <bcache>
    80003182:	ffffe097          	auipc	ra,0xffffe
    80003186:	a68080e7          	jalr	-1432(ra) # 80000bea <acquire>
  b->refcnt++;
    8000318a:	40bc                	lw	a5,64(s1)
    8000318c:	2785                	addiw	a5,a5,1
    8000318e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003190:	00014517          	auipc	a0,0x14
    80003194:	3d850513          	addi	a0,a0,984 # 80017568 <bcache>
    80003198:	ffffe097          	auipc	ra,0xffffe
    8000319c:	b06080e7          	jalr	-1274(ra) # 80000c9e <release>
}
    800031a0:	60e2                	ld	ra,24(sp)
    800031a2:	6442                	ld	s0,16(sp)
    800031a4:	64a2                	ld	s1,8(sp)
    800031a6:	6105                	addi	sp,sp,32
    800031a8:	8082                	ret

00000000800031aa <bunpin>:

void
bunpin(struct buf *b) {
    800031aa:	1101                	addi	sp,sp,-32
    800031ac:	ec06                	sd	ra,24(sp)
    800031ae:	e822                	sd	s0,16(sp)
    800031b0:	e426                	sd	s1,8(sp)
    800031b2:	1000                	addi	s0,sp,32
    800031b4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031b6:	00014517          	auipc	a0,0x14
    800031ba:	3b250513          	addi	a0,a0,946 # 80017568 <bcache>
    800031be:	ffffe097          	auipc	ra,0xffffe
    800031c2:	a2c080e7          	jalr	-1492(ra) # 80000bea <acquire>
  b->refcnt--;
    800031c6:	40bc                	lw	a5,64(s1)
    800031c8:	37fd                	addiw	a5,a5,-1
    800031ca:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031cc:	00014517          	auipc	a0,0x14
    800031d0:	39c50513          	addi	a0,a0,924 # 80017568 <bcache>
    800031d4:	ffffe097          	auipc	ra,0xffffe
    800031d8:	aca080e7          	jalr	-1334(ra) # 80000c9e <release>
}
    800031dc:	60e2                	ld	ra,24(sp)
    800031de:	6442                	ld	s0,16(sp)
    800031e0:	64a2                	ld	s1,8(sp)
    800031e2:	6105                	addi	sp,sp,32
    800031e4:	8082                	ret

00000000800031e6 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031e6:	1101                	addi	sp,sp,-32
    800031e8:	ec06                	sd	ra,24(sp)
    800031ea:	e822                	sd	s0,16(sp)
    800031ec:	e426                	sd	s1,8(sp)
    800031ee:	e04a                	sd	s2,0(sp)
    800031f0:	1000                	addi	s0,sp,32
    800031f2:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031f4:	00d5d59b          	srliw	a1,a1,0xd
    800031f8:	0001d797          	auipc	a5,0x1d
    800031fc:	a4c7a783          	lw	a5,-1460(a5) # 8001fc44 <sb+0x1c>
    80003200:	9dbd                	addw	a1,a1,a5
    80003202:	00000097          	auipc	ra,0x0
    80003206:	d9e080e7          	jalr	-610(ra) # 80002fa0 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000320a:	0074f713          	andi	a4,s1,7
    8000320e:	4785                	li	a5,1
    80003210:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003214:	14ce                	slli	s1,s1,0x33
    80003216:	90d9                	srli	s1,s1,0x36
    80003218:	00950733          	add	a4,a0,s1
    8000321c:	05874703          	lbu	a4,88(a4)
    80003220:	00e7f6b3          	and	a3,a5,a4
    80003224:	c69d                	beqz	a3,80003252 <bfree+0x6c>
    80003226:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003228:	94aa                	add	s1,s1,a0
    8000322a:	fff7c793          	not	a5,a5
    8000322e:	8ff9                	and	a5,a5,a4
    80003230:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003234:	00001097          	auipc	ra,0x1
    80003238:	120080e7          	jalr	288(ra) # 80004354 <log_write>
  brelse(bp);
    8000323c:	854a                	mv	a0,s2
    8000323e:	00000097          	auipc	ra,0x0
    80003242:	e92080e7          	jalr	-366(ra) # 800030d0 <brelse>
}
    80003246:	60e2                	ld	ra,24(sp)
    80003248:	6442                	ld	s0,16(sp)
    8000324a:	64a2                	ld	s1,8(sp)
    8000324c:	6902                	ld	s2,0(sp)
    8000324e:	6105                	addi	sp,sp,32
    80003250:	8082                	ret
    panic("freeing free block");
    80003252:	00005517          	auipc	a0,0x5
    80003256:	3e650513          	addi	a0,a0,998 # 80008638 <syscalls+0x108>
    8000325a:	ffffd097          	auipc	ra,0xffffd
    8000325e:	2ea080e7          	jalr	746(ra) # 80000544 <panic>

0000000080003262 <balloc>:
{
    80003262:	711d                	addi	sp,sp,-96
    80003264:	ec86                	sd	ra,88(sp)
    80003266:	e8a2                	sd	s0,80(sp)
    80003268:	e4a6                	sd	s1,72(sp)
    8000326a:	e0ca                	sd	s2,64(sp)
    8000326c:	fc4e                	sd	s3,56(sp)
    8000326e:	f852                	sd	s4,48(sp)
    80003270:	f456                	sd	s5,40(sp)
    80003272:	f05a                	sd	s6,32(sp)
    80003274:	ec5e                	sd	s7,24(sp)
    80003276:	e862                	sd	s8,16(sp)
    80003278:	e466                	sd	s9,8(sp)
    8000327a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000327c:	0001d797          	auipc	a5,0x1d
    80003280:	9b07a783          	lw	a5,-1616(a5) # 8001fc2c <sb+0x4>
    80003284:	10078163          	beqz	a5,80003386 <balloc+0x124>
    80003288:	8baa                	mv	s7,a0
    8000328a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000328c:	0001db17          	auipc	s6,0x1d
    80003290:	99cb0b13          	addi	s6,s6,-1636 # 8001fc28 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003294:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003296:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003298:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000329a:	6c89                	lui	s9,0x2
    8000329c:	a061                	j	80003324 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000329e:	974a                	add	a4,a4,s2
    800032a0:	8fd5                	or	a5,a5,a3
    800032a2:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800032a6:	854a                	mv	a0,s2
    800032a8:	00001097          	auipc	ra,0x1
    800032ac:	0ac080e7          	jalr	172(ra) # 80004354 <log_write>
        brelse(bp);
    800032b0:	854a                	mv	a0,s2
    800032b2:	00000097          	auipc	ra,0x0
    800032b6:	e1e080e7          	jalr	-482(ra) # 800030d0 <brelse>
  bp = bread(dev, bno);
    800032ba:	85a6                	mv	a1,s1
    800032bc:	855e                	mv	a0,s7
    800032be:	00000097          	auipc	ra,0x0
    800032c2:	ce2080e7          	jalr	-798(ra) # 80002fa0 <bread>
    800032c6:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032c8:	40000613          	li	a2,1024
    800032cc:	4581                	li	a1,0
    800032ce:	05850513          	addi	a0,a0,88
    800032d2:	ffffe097          	auipc	ra,0xffffe
    800032d6:	a14080e7          	jalr	-1516(ra) # 80000ce6 <memset>
  log_write(bp);
    800032da:	854a                	mv	a0,s2
    800032dc:	00001097          	auipc	ra,0x1
    800032e0:	078080e7          	jalr	120(ra) # 80004354 <log_write>
  brelse(bp);
    800032e4:	854a                	mv	a0,s2
    800032e6:	00000097          	auipc	ra,0x0
    800032ea:	dea080e7          	jalr	-534(ra) # 800030d0 <brelse>
}
    800032ee:	8526                	mv	a0,s1
    800032f0:	60e6                	ld	ra,88(sp)
    800032f2:	6446                	ld	s0,80(sp)
    800032f4:	64a6                	ld	s1,72(sp)
    800032f6:	6906                	ld	s2,64(sp)
    800032f8:	79e2                	ld	s3,56(sp)
    800032fa:	7a42                	ld	s4,48(sp)
    800032fc:	7aa2                	ld	s5,40(sp)
    800032fe:	7b02                	ld	s6,32(sp)
    80003300:	6be2                	ld	s7,24(sp)
    80003302:	6c42                	ld	s8,16(sp)
    80003304:	6ca2                	ld	s9,8(sp)
    80003306:	6125                	addi	sp,sp,96
    80003308:	8082                	ret
    brelse(bp);
    8000330a:	854a                	mv	a0,s2
    8000330c:	00000097          	auipc	ra,0x0
    80003310:	dc4080e7          	jalr	-572(ra) # 800030d0 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003314:	015c87bb          	addw	a5,s9,s5
    80003318:	00078a9b          	sext.w	s5,a5
    8000331c:	004b2703          	lw	a4,4(s6)
    80003320:	06eaf363          	bgeu	s5,a4,80003386 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003324:	41fad79b          	sraiw	a5,s5,0x1f
    80003328:	0137d79b          	srliw	a5,a5,0x13
    8000332c:	015787bb          	addw	a5,a5,s5
    80003330:	40d7d79b          	sraiw	a5,a5,0xd
    80003334:	01cb2583          	lw	a1,28(s6)
    80003338:	9dbd                	addw	a1,a1,a5
    8000333a:	855e                	mv	a0,s7
    8000333c:	00000097          	auipc	ra,0x0
    80003340:	c64080e7          	jalr	-924(ra) # 80002fa0 <bread>
    80003344:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003346:	004b2503          	lw	a0,4(s6)
    8000334a:	000a849b          	sext.w	s1,s5
    8000334e:	8662                	mv	a2,s8
    80003350:	faa4fde3          	bgeu	s1,a0,8000330a <balloc+0xa8>
      m = 1 << (bi % 8);
    80003354:	41f6579b          	sraiw	a5,a2,0x1f
    80003358:	01d7d69b          	srliw	a3,a5,0x1d
    8000335c:	00c6873b          	addw	a4,a3,a2
    80003360:	00777793          	andi	a5,a4,7
    80003364:	9f95                	subw	a5,a5,a3
    80003366:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000336a:	4037571b          	sraiw	a4,a4,0x3
    8000336e:	00e906b3          	add	a3,s2,a4
    80003372:	0586c683          	lbu	a3,88(a3)
    80003376:	00d7f5b3          	and	a1,a5,a3
    8000337a:	d195                	beqz	a1,8000329e <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000337c:	2605                	addiw	a2,a2,1
    8000337e:	2485                	addiw	s1,s1,1
    80003380:	fd4618e3          	bne	a2,s4,80003350 <balloc+0xee>
    80003384:	b759                	j	8000330a <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003386:	00005517          	auipc	a0,0x5
    8000338a:	2ca50513          	addi	a0,a0,714 # 80008650 <syscalls+0x120>
    8000338e:	ffffd097          	auipc	ra,0xffffd
    80003392:	200080e7          	jalr	512(ra) # 8000058e <printf>
  return 0;
    80003396:	4481                	li	s1,0
    80003398:	bf99                	j	800032ee <balloc+0x8c>

000000008000339a <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000339a:	7179                	addi	sp,sp,-48
    8000339c:	f406                	sd	ra,40(sp)
    8000339e:	f022                	sd	s0,32(sp)
    800033a0:	ec26                	sd	s1,24(sp)
    800033a2:	e84a                	sd	s2,16(sp)
    800033a4:	e44e                	sd	s3,8(sp)
    800033a6:	e052                	sd	s4,0(sp)
    800033a8:	1800                	addi	s0,sp,48
    800033aa:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033ac:	47ad                	li	a5,11
    800033ae:	02b7e763          	bltu	a5,a1,800033dc <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800033b2:	02059493          	slli	s1,a1,0x20
    800033b6:	9081                	srli	s1,s1,0x20
    800033b8:	048a                	slli	s1,s1,0x2
    800033ba:	94aa                	add	s1,s1,a0
    800033bc:	0504a903          	lw	s2,80(s1)
    800033c0:	06091e63          	bnez	s2,8000343c <bmap+0xa2>
      addr = balloc(ip->dev);
    800033c4:	4108                	lw	a0,0(a0)
    800033c6:	00000097          	auipc	ra,0x0
    800033ca:	e9c080e7          	jalr	-356(ra) # 80003262 <balloc>
    800033ce:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033d2:	06090563          	beqz	s2,8000343c <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    800033d6:	0524a823          	sw	s2,80(s1)
    800033da:	a08d                	j	8000343c <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800033dc:	ff45849b          	addiw	s1,a1,-12
    800033e0:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033e4:	0ff00793          	li	a5,255
    800033e8:	08e7e563          	bltu	a5,a4,80003472 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800033ec:	08052903          	lw	s2,128(a0)
    800033f0:	00091d63          	bnez	s2,8000340a <bmap+0x70>
      addr = balloc(ip->dev);
    800033f4:	4108                	lw	a0,0(a0)
    800033f6:	00000097          	auipc	ra,0x0
    800033fa:	e6c080e7          	jalr	-404(ra) # 80003262 <balloc>
    800033fe:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003402:	02090d63          	beqz	s2,8000343c <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003406:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000340a:	85ca                	mv	a1,s2
    8000340c:	0009a503          	lw	a0,0(s3)
    80003410:	00000097          	auipc	ra,0x0
    80003414:	b90080e7          	jalr	-1136(ra) # 80002fa0 <bread>
    80003418:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000341a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000341e:	02049593          	slli	a1,s1,0x20
    80003422:	9181                	srli	a1,a1,0x20
    80003424:	058a                	slli	a1,a1,0x2
    80003426:	00b784b3          	add	s1,a5,a1
    8000342a:	0004a903          	lw	s2,0(s1)
    8000342e:	02090063          	beqz	s2,8000344e <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003432:	8552                	mv	a0,s4
    80003434:	00000097          	auipc	ra,0x0
    80003438:	c9c080e7          	jalr	-868(ra) # 800030d0 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000343c:	854a                	mv	a0,s2
    8000343e:	70a2                	ld	ra,40(sp)
    80003440:	7402                	ld	s0,32(sp)
    80003442:	64e2                	ld	s1,24(sp)
    80003444:	6942                	ld	s2,16(sp)
    80003446:	69a2                	ld	s3,8(sp)
    80003448:	6a02                	ld	s4,0(sp)
    8000344a:	6145                	addi	sp,sp,48
    8000344c:	8082                	ret
      addr = balloc(ip->dev);
    8000344e:	0009a503          	lw	a0,0(s3)
    80003452:	00000097          	auipc	ra,0x0
    80003456:	e10080e7          	jalr	-496(ra) # 80003262 <balloc>
    8000345a:	0005091b          	sext.w	s2,a0
      if(addr){
    8000345e:	fc090ae3          	beqz	s2,80003432 <bmap+0x98>
        a[bn] = addr;
    80003462:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003466:	8552                	mv	a0,s4
    80003468:	00001097          	auipc	ra,0x1
    8000346c:	eec080e7          	jalr	-276(ra) # 80004354 <log_write>
    80003470:	b7c9                	j	80003432 <bmap+0x98>
  panic("bmap: out of range");
    80003472:	00005517          	auipc	a0,0x5
    80003476:	1f650513          	addi	a0,a0,502 # 80008668 <syscalls+0x138>
    8000347a:	ffffd097          	auipc	ra,0xffffd
    8000347e:	0ca080e7          	jalr	202(ra) # 80000544 <panic>

0000000080003482 <iget>:
{
    80003482:	7179                	addi	sp,sp,-48
    80003484:	f406                	sd	ra,40(sp)
    80003486:	f022                	sd	s0,32(sp)
    80003488:	ec26                	sd	s1,24(sp)
    8000348a:	e84a                	sd	s2,16(sp)
    8000348c:	e44e                	sd	s3,8(sp)
    8000348e:	e052                	sd	s4,0(sp)
    80003490:	1800                	addi	s0,sp,48
    80003492:	89aa                	mv	s3,a0
    80003494:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003496:	0001c517          	auipc	a0,0x1c
    8000349a:	7b250513          	addi	a0,a0,1970 # 8001fc48 <itable>
    8000349e:	ffffd097          	auipc	ra,0xffffd
    800034a2:	74c080e7          	jalr	1868(ra) # 80000bea <acquire>
  empty = 0;
    800034a6:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034a8:	0001c497          	auipc	s1,0x1c
    800034ac:	7b848493          	addi	s1,s1,1976 # 8001fc60 <itable+0x18>
    800034b0:	0001e697          	auipc	a3,0x1e
    800034b4:	24068693          	addi	a3,a3,576 # 800216f0 <log>
    800034b8:	a039                	j	800034c6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034ba:	02090b63          	beqz	s2,800034f0 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034be:	08848493          	addi	s1,s1,136
    800034c2:	02d48a63          	beq	s1,a3,800034f6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034c6:	449c                	lw	a5,8(s1)
    800034c8:	fef059e3          	blez	a5,800034ba <iget+0x38>
    800034cc:	4098                	lw	a4,0(s1)
    800034ce:	ff3716e3          	bne	a4,s3,800034ba <iget+0x38>
    800034d2:	40d8                	lw	a4,4(s1)
    800034d4:	ff4713e3          	bne	a4,s4,800034ba <iget+0x38>
      ip->ref++;
    800034d8:	2785                	addiw	a5,a5,1
    800034da:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800034dc:	0001c517          	auipc	a0,0x1c
    800034e0:	76c50513          	addi	a0,a0,1900 # 8001fc48 <itable>
    800034e4:	ffffd097          	auipc	ra,0xffffd
    800034e8:	7ba080e7          	jalr	1978(ra) # 80000c9e <release>
      return ip;
    800034ec:	8926                	mv	s2,s1
    800034ee:	a03d                	j	8000351c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034f0:	f7f9                	bnez	a5,800034be <iget+0x3c>
    800034f2:	8926                	mv	s2,s1
    800034f4:	b7e9                	j	800034be <iget+0x3c>
  if(empty == 0)
    800034f6:	02090c63          	beqz	s2,8000352e <iget+0xac>
  ip->dev = dev;
    800034fa:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034fe:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003502:	4785                	li	a5,1
    80003504:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003508:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000350c:	0001c517          	auipc	a0,0x1c
    80003510:	73c50513          	addi	a0,a0,1852 # 8001fc48 <itable>
    80003514:	ffffd097          	auipc	ra,0xffffd
    80003518:	78a080e7          	jalr	1930(ra) # 80000c9e <release>
}
    8000351c:	854a                	mv	a0,s2
    8000351e:	70a2                	ld	ra,40(sp)
    80003520:	7402                	ld	s0,32(sp)
    80003522:	64e2                	ld	s1,24(sp)
    80003524:	6942                	ld	s2,16(sp)
    80003526:	69a2                	ld	s3,8(sp)
    80003528:	6a02                	ld	s4,0(sp)
    8000352a:	6145                	addi	sp,sp,48
    8000352c:	8082                	ret
    panic("iget: no inodes");
    8000352e:	00005517          	auipc	a0,0x5
    80003532:	15250513          	addi	a0,a0,338 # 80008680 <syscalls+0x150>
    80003536:	ffffd097          	auipc	ra,0xffffd
    8000353a:	00e080e7          	jalr	14(ra) # 80000544 <panic>

000000008000353e <fsinit>:
fsinit(int dev) {
    8000353e:	7179                	addi	sp,sp,-48
    80003540:	f406                	sd	ra,40(sp)
    80003542:	f022                	sd	s0,32(sp)
    80003544:	ec26                	sd	s1,24(sp)
    80003546:	e84a                	sd	s2,16(sp)
    80003548:	e44e                	sd	s3,8(sp)
    8000354a:	1800                	addi	s0,sp,48
    8000354c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000354e:	4585                	li	a1,1
    80003550:	00000097          	auipc	ra,0x0
    80003554:	a50080e7          	jalr	-1456(ra) # 80002fa0 <bread>
    80003558:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000355a:	0001c997          	auipc	s3,0x1c
    8000355e:	6ce98993          	addi	s3,s3,1742 # 8001fc28 <sb>
    80003562:	02000613          	li	a2,32
    80003566:	05850593          	addi	a1,a0,88
    8000356a:	854e                	mv	a0,s3
    8000356c:	ffffd097          	auipc	ra,0xffffd
    80003570:	7da080e7          	jalr	2010(ra) # 80000d46 <memmove>
  brelse(bp);
    80003574:	8526                	mv	a0,s1
    80003576:	00000097          	auipc	ra,0x0
    8000357a:	b5a080e7          	jalr	-1190(ra) # 800030d0 <brelse>
  if(sb.magic != FSMAGIC)
    8000357e:	0009a703          	lw	a4,0(s3)
    80003582:	102037b7          	lui	a5,0x10203
    80003586:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000358a:	02f71263          	bne	a4,a5,800035ae <fsinit+0x70>
  initlog(dev, &sb);
    8000358e:	0001c597          	auipc	a1,0x1c
    80003592:	69a58593          	addi	a1,a1,1690 # 8001fc28 <sb>
    80003596:	854a                	mv	a0,s2
    80003598:	00001097          	auipc	ra,0x1
    8000359c:	b40080e7          	jalr	-1216(ra) # 800040d8 <initlog>
}
    800035a0:	70a2                	ld	ra,40(sp)
    800035a2:	7402                	ld	s0,32(sp)
    800035a4:	64e2                	ld	s1,24(sp)
    800035a6:	6942                	ld	s2,16(sp)
    800035a8:	69a2                	ld	s3,8(sp)
    800035aa:	6145                	addi	sp,sp,48
    800035ac:	8082                	ret
    panic("invalid file system");
    800035ae:	00005517          	auipc	a0,0x5
    800035b2:	0e250513          	addi	a0,a0,226 # 80008690 <syscalls+0x160>
    800035b6:	ffffd097          	auipc	ra,0xffffd
    800035ba:	f8e080e7          	jalr	-114(ra) # 80000544 <panic>

00000000800035be <iinit>:
{
    800035be:	7179                	addi	sp,sp,-48
    800035c0:	f406                	sd	ra,40(sp)
    800035c2:	f022                	sd	s0,32(sp)
    800035c4:	ec26                	sd	s1,24(sp)
    800035c6:	e84a                	sd	s2,16(sp)
    800035c8:	e44e                	sd	s3,8(sp)
    800035ca:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800035cc:	00005597          	auipc	a1,0x5
    800035d0:	0dc58593          	addi	a1,a1,220 # 800086a8 <syscalls+0x178>
    800035d4:	0001c517          	auipc	a0,0x1c
    800035d8:	67450513          	addi	a0,a0,1652 # 8001fc48 <itable>
    800035dc:	ffffd097          	auipc	ra,0xffffd
    800035e0:	57e080e7          	jalr	1406(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    800035e4:	0001c497          	auipc	s1,0x1c
    800035e8:	68c48493          	addi	s1,s1,1676 # 8001fc70 <itable+0x28>
    800035ec:	0001e997          	auipc	s3,0x1e
    800035f0:	11498993          	addi	s3,s3,276 # 80021700 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800035f4:	00005917          	auipc	s2,0x5
    800035f8:	0bc90913          	addi	s2,s2,188 # 800086b0 <syscalls+0x180>
    800035fc:	85ca                	mv	a1,s2
    800035fe:	8526                	mv	a0,s1
    80003600:	00001097          	auipc	ra,0x1
    80003604:	e3a080e7          	jalr	-454(ra) # 8000443a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003608:	08848493          	addi	s1,s1,136
    8000360c:	ff3498e3          	bne	s1,s3,800035fc <iinit+0x3e>
}
    80003610:	70a2                	ld	ra,40(sp)
    80003612:	7402                	ld	s0,32(sp)
    80003614:	64e2                	ld	s1,24(sp)
    80003616:	6942                	ld	s2,16(sp)
    80003618:	69a2                	ld	s3,8(sp)
    8000361a:	6145                	addi	sp,sp,48
    8000361c:	8082                	ret

000000008000361e <ialloc>:
{
    8000361e:	715d                	addi	sp,sp,-80
    80003620:	e486                	sd	ra,72(sp)
    80003622:	e0a2                	sd	s0,64(sp)
    80003624:	fc26                	sd	s1,56(sp)
    80003626:	f84a                	sd	s2,48(sp)
    80003628:	f44e                	sd	s3,40(sp)
    8000362a:	f052                	sd	s4,32(sp)
    8000362c:	ec56                	sd	s5,24(sp)
    8000362e:	e85a                	sd	s6,16(sp)
    80003630:	e45e                	sd	s7,8(sp)
    80003632:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003634:	0001c717          	auipc	a4,0x1c
    80003638:	60072703          	lw	a4,1536(a4) # 8001fc34 <sb+0xc>
    8000363c:	4785                	li	a5,1
    8000363e:	04e7fa63          	bgeu	a5,a4,80003692 <ialloc+0x74>
    80003642:	8aaa                	mv	s5,a0
    80003644:	8bae                	mv	s7,a1
    80003646:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003648:	0001ca17          	auipc	s4,0x1c
    8000364c:	5e0a0a13          	addi	s4,s4,1504 # 8001fc28 <sb>
    80003650:	00048b1b          	sext.w	s6,s1
    80003654:	0044d593          	srli	a1,s1,0x4
    80003658:	018a2783          	lw	a5,24(s4)
    8000365c:	9dbd                	addw	a1,a1,a5
    8000365e:	8556                	mv	a0,s5
    80003660:	00000097          	auipc	ra,0x0
    80003664:	940080e7          	jalr	-1728(ra) # 80002fa0 <bread>
    80003668:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000366a:	05850993          	addi	s3,a0,88
    8000366e:	00f4f793          	andi	a5,s1,15
    80003672:	079a                	slli	a5,a5,0x6
    80003674:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003676:	00099783          	lh	a5,0(s3)
    8000367a:	c3a1                	beqz	a5,800036ba <ialloc+0x9c>
    brelse(bp);
    8000367c:	00000097          	auipc	ra,0x0
    80003680:	a54080e7          	jalr	-1452(ra) # 800030d0 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003684:	0485                	addi	s1,s1,1
    80003686:	00ca2703          	lw	a4,12(s4)
    8000368a:	0004879b          	sext.w	a5,s1
    8000368e:	fce7e1e3          	bltu	a5,a4,80003650 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003692:	00005517          	auipc	a0,0x5
    80003696:	02650513          	addi	a0,a0,38 # 800086b8 <syscalls+0x188>
    8000369a:	ffffd097          	auipc	ra,0xffffd
    8000369e:	ef4080e7          	jalr	-268(ra) # 8000058e <printf>
  return 0;
    800036a2:	4501                	li	a0,0
}
    800036a4:	60a6                	ld	ra,72(sp)
    800036a6:	6406                	ld	s0,64(sp)
    800036a8:	74e2                	ld	s1,56(sp)
    800036aa:	7942                	ld	s2,48(sp)
    800036ac:	79a2                	ld	s3,40(sp)
    800036ae:	7a02                	ld	s4,32(sp)
    800036b0:	6ae2                	ld	s5,24(sp)
    800036b2:	6b42                	ld	s6,16(sp)
    800036b4:	6ba2                	ld	s7,8(sp)
    800036b6:	6161                	addi	sp,sp,80
    800036b8:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800036ba:	04000613          	li	a2,64
    800036be:	4581                	li	a1,0
    800036c0:	854e                	mv	a0,s3
    800036c2:	ffffd097          	auipc	ra,0xffffd
    800036c6:	624080e7          	jalr	1572(ra) # 80000ce6 <memset>
      dip->type = type;
    800036ca:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036ce:	854a                	mv	a0,s2
    800036d0:	00001097          	auipc	ra,0x1
    800036d4:	c84080e7          	jalr	-892(ra) # 80004354 <log_write>
      brelse(bp);
    800036d8:	854a                	mv	a0,s2
    800036da:	00000097          	auipc	ra,0x0
    800036de:	9f6080e7          	jalr	-1546(ra) # 800030d0 <brelse>
      return iget(dev, inum);
    800036e2:	85da                	mv	a1,s6
    800036e4:	8556                	mv	a0,s5
    800036e6:	00000097          	auipc	ra,0x0
    800036ea:	d9c080e7          	jalr	-612(ra) # 80003482 <iget>
    800036ee:	bf5d                	j	800036a4 <ialloc+0x86>

00000000800036f0 <iupdate>:
{
    800036f0:	1101                	addi	sp,sp,-32
    800036f2:	ec06                	sd	ra,24(sp)
    800036f4:	e822                	sd	s0,16(sp)
    800036f6:	e426                	sd	s1,8(sp)
    800036f8:	e04a                	sd	s2,0(sp)
    800036fa:	1000                	addi	s0,sp,32
    800036fc:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036fe:	415c                	lw	a5,4(a0)
    80003700:	0047d79b          	srliw	a5,a5,0x4
    80003704:	0001c597          	auipc	a1,0x1c
    80003708:	53c5a583          	lw	a1,1340(a1) # 8001fc40 <sb+0x18>
    8000370c:	9dbd                	addw	a1,a1,a5
    8000370e:	4108                	lw	a0,0(a0)
    80003710:	00000097          	auipc	ra,0x0
    80003714:	890080e7          	jalr	-1904(ra) # 80002fa0 <bread>
    80003718:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000371a:	05850793          	addi	a5,a0,88
    8000371e:	40c8                	lw	a0,4(s1)
    80003720:	893d                	andi	a0,a0,15
    80003722:	051a                	slli	a0,a0,0x6
    80003724:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003726:	04449703          	lh	a4,68(s1)
    8000372a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000372e:	04649703          	lh	a4,70(s1)
    80003732:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003736:	04849703          	lh	a4,72(s1)
    8000373a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000373e:	04a49703          	lh	a4,74(s1)
    80003742:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003746:	44f8                	lw	a4,76(s1)
    80003748:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000374a:	03400613          	li	a2,52
    8000374e:	05048593          	addi	a1,s1,80
    80003752:	0531                	addi	a0,a0,12
    80003754:	ffffd097          	auipc	ra,0xffffd
    80003758:	5f2080e7          	jalr	1522(ra) # 80000d46 <memmove>
  log_write(bp);
    8000375c:	854a                	mv	a0,s2
    8000375e:	00001097          	auipc	ra,0x1
    80003762:	bf6080e7          	jalr	-1034(ra) # 80004354 <log_write>
  brelse(bp);
    80003766:	854a                	mv	a0,s2
    80003768:	00000097          	auipc	ra,0x0
    8000376c:	968080e7          	jalr	-1688(ra) # 800030d0 <brelse>
}
    80003770:	60e2                	ld	ra,24(sp)
    80003772:	6442                	ld	s0,16(sp)
    80003774:	64a2                	ld	s1,8(sp)
    80003776:	6902                	ld	s2,0(sp)
    80003778:	6105                	addi	sp,sp,32
    8000377a:	8082                	ret

000000008000377c <idup>:
{
    8000377c:	1101                	addi	sp,sp,-32
    8000377e:	ec06                	sd	ra,24(sp)
    80003780:	e822                	sd	s0,16(sp)
    80003782:	e426                	sd	s1,8(sp)
    80003784:	1000                	addi	s0,sp,32
    80003786:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003788:	0001c517          	auipc	a0,0x1c
    8000378c:	4c050513          	addi	a0,a0,1216 # 8001fc48 <itable>
    80003790:	ffffd097          	auipc	ra,0xffffd
    80003794:	45a080e7          	jalr	1114(ra) # 80000bea <acquire>
  ip->ref++;
    80003798:	449c                	lw	a5,8(s1)
    8000379a:	2785                	addiw	a5,a5,1
    8000379c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000379e:	0001c517          	auipc	a0,0x1c
    800037a2:	4aa50513          	addi	a0,a0,1194 # 8001fc48 <itable>
    800037a6:	ffffd097          	auipc	ra,0xffffd
    800037aa:	4f8080e7          	jalr	1272(ra) # 80000c9e <release>
}
    800037ae:	8526                	mv	a0,s1
    800037b0:	60e2                	ld	ra,24(sp)
    800037b2:	6442                	ld	s0,16(sp)
    800037b4:	64a2                	ld	s1,8(sp)
    800037b6:	6105                	addi	sp,sp,32
    800037b8:	8082                	ret

00000000800037ba <ilock>:
{
    800037ba:	1101                	addi	sp,sp,-32
    800037bc:	ec06                	sd	ra,24(sp)
    800037be:	e822                	sd	s0,16(sp)
    800037c0:	e426                	sd	s1,8(sp)
    800037c2:	e04a                	sd	s2,0(sp)
    800037c4:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037c6:	c115                	beqz	a0,800037ea <ilock+0x30>
    800037c8:	84aa                	mv	s1,a0
    800037ca:	451c                	lw	a5,8(a0)
    800037cc:	00f05f63          	blez	a5,800037ea <ilock+0x30>
  acquiresleep(&ip->lock);
    800037d0:	0541                	addi	a0,a0,16
    800037d2:	00001097          	auipc	ra,0x1
    800037d6:	ca2080e7          	jalr	-862(ra) # 80004474 <acquiresleep>
  if(ip->valid == 0){
    800037da:	40bc                	lw	a5,64(s1)
    800037dc:	cf99                	beqz	a5,800037fa <ilock+0x40>
}
    800037de:	60e2                	ld	ra,24(sp)
    800037e0:	6442                	ld	s0,16(sp)
    800037e2:	64a2                	ld	s1,8(sp)
    800037e4:	6902                	ld	s2,0(sp)
    800037e6:	6105                	addi	sp,sp,32
    800037e8:	8082                	ret
    panic("ilock");
    800037ea:	00005517          	auipc	a0,0x5
    800037ee:	ee650513          	addi	a0,a0,-282 # 800086d0 <syscalls+0x1a0>
    800037f2:	ffffd097          	auipc	ra,0xffffd
    800037f6:	d52080e7          	jalr	-686(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037fa:	40dc                	lw	a5,4(s1)
    800037fc:	0047d79b          	srliw	a5,a5,0x4
    80003800:	0001c597          	auipc	a1,0x1c
    80003804:	4405a583          	lw	a1,1088(a1) # 8001fc40 <sb+0x18>
    80003808:	9dbd                	addw	a1,a1,a5
    8000380a:	4088                	lw	a0,0(s1)
    8000380c:	fffff097          	auipc	ra,0xfffff
    80003810:	794080e7          	jalr	1940(ra) # 80002fa0 <bread>
    80003814:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003816:	05850593          	addi	a1,a0,88
    8000381a:	40dc                	lw	a5,4(s1)
    8000381c:	8bbd                	andi	a5,a5,15
    8000381e:	079a                	slli	a5,a5,0x6
    80003820:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003822:	00059783          	lh	a5,0(a1)
    80003826:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000382a:	00259783          	lh	a5,2(a1)
    8000382e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003832:	00459783          	lh	a5,4(a1)
    80003836:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000383a:	00659783          	lh	a5,6(a1)
    8000383e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003842:	459c                	lw	a5,8(a1)
    80003844:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003846:	03400613          	li	a2,52
    8000384a:	05b1                	addi	a1,a1,12
    8000384c:	05048513          	addi	a0,s1,80
    80003850:	ffffd097          	auipc	ra,0xffffd
    80003854:	4f6080e7          	jalr	1270(ra) # 80000d46 <memmove>
    brelse(bp);
    80003858:	854a                	mv	a0,s2
    8000385a:	00000097          	auipc	ra,0x0
    8000385e:	876080e7          	jalr	-1930(ra) # 800030d0 <brelse>
    ip->valid = 1;
    80003862:	4785                	li	a5,1
    80003864:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003866:	04449783          	lh	a5,68(s1)
    8000386a:	fbb5                	bnez	a5,800037de <ilock+0x24>
      panic("ilock: no type");
    8000386c:	00005517          	auipc	a0,0x5
    80003870:	e6c50513          	addi	a0,a0,-404 # 800086d8 <syscalls+0x1a8>
    80003874:	ffffd097          	auipc	ra,0xffffd
    80003878:	cd0080e7          	jalr	-816(ra) # 80000544 <panic>

000000008000387c <iunlock>:
{
    8000387c:	1101                	addi	sp,sp,-32
    8000387e:	ec06                	sd	ra,24(sp)
    80003880:	e822                	sd	s0,16(sp)
    80003882:	e426                	sd	s1,8(sp)
    80003884:	e04a                	sd	s2,0(sp)
    80003886:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003888:	c905                	beqz	a0,800038b8 <iunlock+0x3c>
    8000388a:	84aa                	mv	s1,a0
    8000388c:	01050913          	addi	s2,a0,16
    80003890:	854a                	mv	a0,s2
    80003892:	00001097          	auipc	ra,0x1
    80003896:	c7c080e7          	jalr	-900(ra) # 8000450e <holdingsleep>
    8000389a:	cd19                	beqz	a0,800038b8 <iunlock+0x3c>
    8000389c:	449c                	lw	a5,8(s1)
    8000389e:	00f05d63          	blez	a5,800038b8 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800038a2:	854a                	mv	a0,s2
    800038a4:	00001097          	auipc	ra,0x1
    800038a8:	c26080e7          	jalr	-986(ra) # 800044ca <releasesleep>
}
    800038ac:	60e2                	ld	ra,24(sp)
    800038ae:	6442                	ld	s0,16(sp)
    800038b0:	64a2                	ld	s1,8(sp)
    800038b2:	6902                	ld	s2,0(sp)
    800038b4:	6105                	addi	sp,sp,32
    800038b6:	8082                	ret
    panic("iunlock");
    800038b8:	00005517          	auipc	a0,0x5
    800038bc:	e3050513          	addi	a0,a0,-464 # 800086e8 <syscalls+0x1b8>
    800038c0:	ffffd097          	auipc	ra,0xffffd
    800038c4:	c84080e7          	jalr	-892(ra) # 80000544 <panic>

00000000800038c8 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038c8:	7179                	addi	sp,sp,-48
    800038ca:	f406                	sd	ra,40(sp)
    800038cc:	f022                	sd	s0,32(sp)
    800038ce:	ec26                	sd	s1,24(sp)
    800038d0:	e84a                	sd	s2,16(sp)
    800038d2:	e44e                	sd	s3,8(sp)
    800038d4:	e052                	sd	s4,0(sp)
    800038d6:	1800                	addi	s0,sp,48
    800038d8:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038da:	05050493          	addi	s1,a0,80
    800038de:	08050913          	addi	s2,a0,128
    800038e2:	a021                	j	800038ea <itrunc+0x22>
    800038e4:	0491                	addi	s1,s1,4
    800038e6:	01248d63          	beq	s1,s2,80003900 <itrunc+0x38>
    if(ip->addrs[i]){
    800038ea:	408c                	lw	a1,0(s1)
    800038ec:	dde5                	beqz	a1,800038e4 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038ee:	0009a503          	lw	a0,0(s3)
    800038f2:	00000097          	auipc	ra,0x0
    800038f6:	8f4080e7          	jalr	-1804(ra) # 800031e6 <bfree>
      ip->addrs[i] = 0;
    800038fa:	0004a023          	sw	zero,0(s1)
    800038fe:	b7dd                	j	800038e4 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003900:	0809a583          	lw	a1,128(s3)
    80003904:	e185                	bnez	a1,80003924 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003906:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000390a:	854e                	mv	a0,s3
    8000390c:	00000097          	auipc	ra,0x0
    80003910:	de4080e7          	jalr	-540(ra) # 800036f0 <iupdate>
}
    80003914:	70a2                	ld	ra,40(sp)
    80003916:	7402                	ld	s0,32(sp)
    80003918:	64e2                	ld	s1,24(sp)
    8000391a:	6942                	ld	s2,16(sp)
    8000391c:	69a2                	ld	s3,8(sp)
    8000391e:	6a02                	ld	s4,0(sp)
    80003920:	6145                	addi	sp,sp,48
    80003922:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003924:	0009a503          	lw	a0,0(s3)
    80003928:	fffff097          	auipc	ra,0xfffff
    8000392c:	678080e7          	jalr	1656(ra) # 80002fa0 <bread>
    80003930:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003932:	05850493          	addi	s1,a0,88
    80003936:	45850913          	addi	s2,a0,1112
    8000393a:	a811                	j	8000394e <itrunc+0x86>
        bfree(ip->dev, a[j]);
    8000393c:	0009a503          	lw	a0,0(s3)
    80003940:	00000097          	auipc	ra,0x0
    80003944:	8a6080e7          	jalr	-1882(ra) # 800031e6 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003948:	0491                	addi	s1,s1,4
    8000394a:	01248563          	beq	s1,s2,80003954 <itrunc+0x8c>
      if(a[j])
    8000394e:	408c                	lw	a1,0(s1)
    80003950:	dde5                	beqz	a1,80003948 <itrunc+0x80>
    80003952:	b7ed                	j	8000393c <itrunc+0x74>
    brelse(bp);
    80003954:	8552                	mv	a0,s4
    80003956:	fffff097          	auipc	ra,0xfffff
    8000395a:	77a080e7          	jalr	1914(ra) # 800030d0 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000395e:	0809a583          	lw	a1,128(s3)
    80003962:	0009a503          	lw	a0,0(s3)
    80003966:	00000097          	auipc	ra,0x0
    8000396a:	880080e7          	jalr	-1920(ra) # 800031e6 <bfree>
    ip->addrs[NDIRECT] = 0;
    8000396e:	0809a023          	sw	zero,128(s3)
    80003972:	bf51                	j	80003906 <itrunc+0x3e>

0000000080003974 <iput>:
{
    80003974:	1101                	addi	sp,sp,-32
    80003976:	ec06                	sd	ra,24(sp)
    80003978:	e822                	sd	s0,16(sp)
    8000397a:	e426                	sd	s1,8(sp)
    8000397c:	e04a                	sd	s2,0(sp)
    8000397e:	1000                	addi	s0,sp,32
    80003980:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003982:	0001c517          	auipc	a0,0x1c
    80003986:	2c650513          	addi	a0,a0,710 # 8001fc48 <itable>
    8000398a:	ffffd097          	auipc	ra,0xffffd
    8000398e:	260080e7          	jalr	608(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003992:	4498                	lw	a4,8(s1)
    80003994:	4785                	li	a5,1
    80003996:	02f70363          	beq	a4,a5,800039bc <iput+0x48>
  ip->ref--;
    8000399a:	449c                	lw	a5,8(s1)
    8000399c:	37fd                	addiw	a5,a5,-1
    8000399e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039a0:	0001c517          	auipc	a0,0x1c
    800039a4:	2a850513          	addi	a0,a0,680 # 8001fc48 <itable>
    800039a8:	ffffd097          	auipc	ra,0xffffd
    800039ac:	2f6080e7          	jalr	758(ra) # 80000c9e <release>
}
    800039b0:	60e2                	ld	ra,24(sp)
    800039b2:	6442                	ld	s0,16(sp)
    800039b4:	64a2                	ld	s1,8(sp)
    800039b6:	6902                	ld	s2,0(sp)
    800039b8:	6105                	addi	sp,sp,32
    800039ba:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039bc:	40bc                	lw	a5,64(s1)
    800039be:	dff1                	beqz	a5,8000399a <iput+0x26>
    800039c0:	04a49783          	lh	a5,74(s1)
    800039c4:	fbf9                	bnez	a5,8000399a <iput+0x26>
    acquiresleep(&ip->lock);
    800039c6:	01048913          	addi	s2,s1,16
    800039ca:	854a                	mv	a0,s2
    800039cc:	00001097          	auipc	ra,0x1
    800039d0:	aa8080e7          	jalr	-1368(ra) # 80004474 <acquiresleep>
    release(&itable.lock);
    800039d4:	0001c517          	auipc	a0,0x1c
    800039d8:	27450513          	addi	a0,a0,628 # 8001fc48 <itable>
    800039dc:	ffffd097          	auipc	ra,0xffffd
    800039e0:	2c2080e7          	jalr	706(ra) # 80000c9e <release>
    itrunc(ip);
    800039e4:	8526                	mv	a0,s1
    800039e6:	00000097          	auipc	ra,0x0
    800039ea:	ee2080e7          	jalr	-286(ra) # 800038c8 <itrunc>
    ip->type = 0;
    800039ee:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039f2:	8526                	mv	a0,s1
    800039f4:	00000097          	auipc	ra,0x0
    800039f8:	cfc080e7          	jalr	-772(ra) # 800036f0 <iupdate>
    ip->valid = 0;
    800039fc:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a00:	854a                	mv	a0,s2
    80003a02:	00001097          	auipc	ra,0x1
    80003a06:	ac8080e7          	jalr	-1336(ra) # 800044ca <releasesleep>
    acquire(&itable.lock);
    80003a0a:	0001c517          	auipc	a0,0x1c
    80003a0e:	23e50513          	addi	a0,a0,574 # 8001fc48 <itable>
    80003a12:	ffffd097          	auipc	ra,0xffffd
    80003a16:	1d8080e7          	jalr	472(ra) # 80000bea <acquire>
    80003a1a:	b741                	j	8000399a <iput+0x26>

0000000080003a1c <iunlockput>:
{
    80003a1c:	1101                	addi	sp,sp,-32
    80003a1e:	ec06                	sd	ra,24(sp)
    80003a20:	e822                	sd	s0,16(sp)
    80003a22:	e426                	sd	s1,8(sp)
    80003a24:	1000                	addi	s0,sp,32
    80003a26:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a28:	00000097          	auipc	ra,0x0
    80003a2c:	e54080e7          	jalr	-428(ra) # 8000387c <iunlock>
  iput(ip);
    80003a30:	8526                	mv	a0,s1
    80003a32:	00000097          	auipc	ra,0x0
    80003a36:	f42080e7          	jalr	-190(ra) # 80003974 <iput>
}
    80003a3a:	60e2                	ld	ra,24(sp)
    80003a3c:	6442                	ld	s0,16(sp)
    80003a3e:	64a2                	ld	s1,8(sp)
    80003a40:	6105                	addi	sp,sp,32
    80003a42:	8082                	ret

0000000080003a44 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a44:	1141                	addi	sp,sp,-16
    80003a46:	e422                	sd	s0,8(sp)
    80003a48:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a4a:	411c                	lw	a5,0(a0)
    80003a4c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a4e:	415c                	lw	a5,4(a0)
    80003a50:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a52:	04451783          	lh	a5,68(a0)
    80003a56:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a5a:	04a51783          	lh	a5,74(a0)
    80003a5e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a62:	04c56783          	lwu	a5,76(a0)
    80003a66:	e99c                	sd	a5,16(a1)
}
    80003a68:	6422                	ld	s0,8(sp)
    80003a6a:	0141                	addi	sp,sp,16
    80003a6c:	8082                	ret

0000000080003a6e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a6e:	457c                	lw	a5,76(a0)
    80003a70:	0ed7e963          	bltu	a5,a3,80003b62 <readi+0xf4>
{
    80003a74:	7159                	addi	sp,sp,-112
    80003a76:	f486                	sd	ra,104(sp)
    80003a78:	f0a2                	sd	s0,96(sp)
    80003a7a:	eca6                	sd	s1,88(sp)
    80003a7c:	e8ca                	sd	s2,80(sp)
    80003a7e:	e4ce                	sd	s3,72(sp)
    80003a80:	e0d2                	sd	s4,64(sp)
    80003a82:	fc56                	sd	s5,56(sp)
    80003a84:	f85a                	sd	s6,48(sp)
    80003a86:	f45e                	sd	s7,40(sp)
    80003a88:	f062                	sd	s8,32(sp)
    80003a8a:	ec66                	sd	s9,24(sp)
    80003a8c:	e86a                	sd	s10,16(sp)
    80003a8e:	e46e                	sd	s11,8(sp)
    80003a90:	1880                	addi	s0,sp,112
    80003a92:	8b2a                	mv	s6,a0
    80003a94:	8bae                	mv	s7,a1
    80003a96:	8a32                	mv	s4,a2
    80003a98:	84b6                	mv	s1,a3
    80003a9a:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003a9c:	9f35                	addw	a4,a4,a3
    return 0;
    80003a9e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003aa0:	0ad76063          	bltu	a4,a3,80003b40 <readi+0xd2>
  if(off + n > ip->size)
    80003aa4:	00e7f463          	bgeu	a5,a4,80003aac <readi+0x3e>
    n = ip->size - off;
    80003aa8:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003aac:	0a0a8963          	beqz	s5,80003b5e <readi+0xf0>
    80003ab0:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ab2:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ab6:	5c7d                	li	s8,-1
    80003ab8:	a82d                	j	80003af2 <readi+0x84>
    80003aba:	020d1d93          	slli	s11,s10,0x20
    80003abe:	020ddd93          	srli	s11,s11,0x20
    80003ac2:	05890613          	addi	a2,s2,88
    80003ac6:	86ee                	mv	a3,s11
    80003ac8:	963a                	add	a2,a2,a4
    80003aca:	85d2                	mv	a1,s4
    80003acc:	855e                	mv	a0,s7
    80003ace:	fffff097          	auipc	ra,0xfffff
    80003ad2:	9b8080e7          	jalr	-1608(ra) # 80002486 <either_copyout>
    80003ad6:	05850d63          	beq	a0,s8,80003b30 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ada:	854a                	mv	a0,s2
    80003adc:	fffff097          	auipc	ra,0xfffff
    80003ae0:	5f4080e7          	jalr	1524(ra) # 800030d0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ae4:	013d09bb          	addw	s3,s10,s3
    80003ae8:	009d04bb          	addw	s1,s10,s1
    80003aec:	9a6e                	add	s4,s4,s11
    80003aee:	0559f763          	bgeu	s3,s5,80003b3c <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003af2:	00a4d59b          	srliw	a1,s1,0xa
    80003af6:	855a                	mv	a0,s6
    80003af8:	00000097          	auipc	ra,0x0
    80003afc:	8a2080e7          	jalr	-1886(ra) # 8000339a <bmap>
    80003b00:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b04:	cd85                	beqz	a1,80003b3c <readi+0xce>
    bp = bread(ip->dev, addr);
    80003b06:	000b2503          	lw	a0,0(s6)
    80003b0a:	fffff097          	auipc	ra,0xfffff
    80003b0e:	496080e7          	jalr	1174(ra) # 80002fa0 <bread>
    80003b12:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b14:	3ff4f713          	andi	a4,s1,1023
    80003b18:	40ec87bb          	subw	a5,s9,a4
    80003b1c:	413a86bb          	subw	a3,s5,s3
    80003b20:	8d3e                	mv	s10,a5
    80003b22:	2781                	sext.w	a5,a5
    80003b24:	0006861b          	sext.w	a2,a3
    80003b28:	f8f679e3          	bgeu	a2,a5,80003aba <readi+0x4c>
    80003b2c:	8d36                	mv	s10,a3
    80003b2e:	b771                	j	80003aba <readi+0x4c>
      brelse(bp);
    80003b30:	854a                	mv	a0,s2
    80003b32:	fffff097          	auipc	ra,0xfffff
    80003b36:	59e080e7          	jalr	1438(ra) # 800030d0 <brelse>
      tot = -1;
    80003b3a:	59fd                	li	s3,-1
  }
  return tot;
    80003b3c:	0009851b          	sext.w	a0,s3
}
    80003b40:	70a6                	ld	ra,104(sp)
    80003b42:	7406                	ld	s0,96(sp)
    80003b44:	64e6                	ld	s1,88(sp)
    80003b46:	6946                	ld	s2,80(sp)
    80003b48:	69a6                	ld	s3,72(sp)
    80003b4a:	6a06                	ld	s4,64(sp)
    80003b4c:	7ae2                	ld	s5,56(sp)
    80003b4e:	7b42                	ld	s6,48(sp)
    80003b50:	7ba2                	ld	s7,40(sp)
    80003b52:	7c02                	ld	s8,32(sp)
    80003b54:	6ce2                	ld	s9,24(sp)
    80003b56:	6d42                	ld	s10,16(sp)
    80003b58:	6da2                	ld	s11,8(sp)
    80003b5a:	6165                	addi	sp,sp,112
    80003b5c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b5e:	89d6                	mv	s3,s5
    80003b60:	bff1                	j	80003b3c <readi+0xce>
    return 0;
    80003b62:	4501                	li	a0,0
}
    80003b64:	8082                	ret

0000000080003b66 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b66:	457c                	lw	a5,76(a0)
    80003b68:	10d7e863          	bltu	a5,a3,80003c78 <writei+0x112>
{
    80003b6c:	7159                	addi	sp,sp,-112
    80003b6e:	f486                	sd	ra,104(sp)
    80003b70:	f0a2                	sd	s0,96(sp)
    80003b72:	eca6                	sd	s1,88(sp)
    80003b74:	e8ca                	sd	s2,80(sp)
    80003b76:	e4ce                	sd	s3,72(sp)
    80003b78:	e0d2                	sd	s4,64(sp)
    80003b7a:	fc56                	sd	s5,56(sp)
    80003b7c:	f85a                	sd	s6,48(sp)
    80003b7e:	f45e                	sd	s7,40(sp)
    80003b80:	f062                	sd	s8,32(sp)
    80003b82:	ec66                	sd	s9,24(sp)
    80003b84:	e86a                	sd	s10,16(sp)
    80003b86:	e46e                	sd	s11,8(sp)
    80003b88:	1880                	addi	s0,sp,112
    80003b8a:	8aaa                	mv	s5,a0
    80003b8c:	8bae                	mv	s7,a1
    80003b8e:	8a32                	mv	s4,a2
    80003b90:	8936                	mv	s2,a3
    80003b92:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b94:	00e687bb          	addw	a5,a3,a4
    80003b98:	0ed7e263          	bltu	a5,a3,80003c7c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b9c:	00043737          	lui	a4,0x43
    80003ba0:	0ef76063          	bltu	a4,a5,80003c80 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ba4:	0c0b0863          	beqz	s6,80003c74 <writei+0x10e>
    80003ba8:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003baa:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003bae:	5c7d                	li	s8,-1
    80003bb0:	a091                	j	80003bf4 <writei+0x8e>
    80003bb2:	020d1d93          	slli	s11,s10,0x20
    80003bb6:	020ddd93          	srli	s11,s11,0x20
    80003bba:	05848513          	addi	a0,s1,88
    80003bbe:	86ee                	mv	a3,s11
    80003bc0:	8652                	mv	a2,s4
    80003bc2:	85de                	mv	a1,s7
    80003bc4:	953a                	add	a0,a0,a4
    80003bc6:	fffff097          	auipc	ra,0xfffff
    80003bca:	916080e7          	jalr	-1770(ra) # 800024dc <either_copyin>
    80003bce:	07850263          	beq	a0,s8,80003c32 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003bd2:	8526                	mv	a0,s1
    80003bd4:	00000097          	auipc	ra,0x0
    80003bd8:	780080e7          	jalr	1920(ra) # 80004354 <log_write>
    brelse(bp);
    80003bdc:	8526                	mv	a0,s1
    80003bde:	fffff097          	auipc	ra,0xfffff
    80003be2:	4f2080e7          	jalr	1266(ra) # 800030d0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003be6:	013d09bb          	addw	s3,s10,s3
    80003bea:	012d093b          	addw	s2,s10,s2
    80003bee:	9a6e                	add	s4,s4,s11
    80003bf0:	0569f663          	bgeu	s3,s6,80003c3c <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003bf4:	00a9559b          	srliw	a1,s2,0xa
    80003bf8:	8556                	mv	a0,s5
    80003bfa:	fffff097          	auipc	ra,0xfffff
    80003bfe:	7a0080e7          	jalr	1952(ra) # 8000339a <bmap>
    80003c02:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c06:	c99d                	beqz	a1,80003c3c <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003c08:	000aa503          	lw	a0,0(s5)
    80003c0c:	fffff097          	auipc	ra,0xfffff
    80003c10:	394080e7          	jalr	916(ra) # 80002fa0 <bread>
    80003c14:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c16:	3ff97713          	andi	a4,s2,1023
    80003c1a:	40ec87bb          	subw	a5,s9,a4
    80003c1e:	413b06bb          	subw	a3,s6,s3
    80003c22:	8d3e                	mv	s10,a5
    80003c24:	2781                	sext.w	a5,a5
    80003c26:	0006861b          	sext.w	a2,a3
    80003c2a:	f8f674e3          	bgeu	a2,a5,80003bb2 <writei+0x4c>
    80003c2e:	8d36                	mv	s10,a3
    80003c30:	b749                	j	80003bb2 <writei+0x4c>
      brelse(bp);
    80003c32:	8526                	mv	a0,s1
    80003c34:	fffff097          	auipc	ra,0xfffff
    80003c38:	49c080e7          	jalr	1180(ra) # 800030d0 <brelse>
  }

  if(off > ip->size)
    80003c3c:	04caa783          	lw	a5,76(s5)
    80003c40:	0127f463          	bgeu	a5,s2,80003c48 <writei+0xe2>
    ip->size = off;
    80003c44:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c48:	8556                	mv	a0,s5
    80003c4a:	00000097          	auipc	ra,0x0
    80003c4e:	aa6080e7          	jalr	-1370(ra) # 800036f0 <iupdate>

  return tot;
    80003c52:	0009851b          	sext.w	a0,s3
}
    80003c56:	70a6                	ld	ra,104(sp)
    80003c58:	7406                	ld	s0,96(sp)
    80003c5a:	64e6                	ld	s1,88(sp)
    80003c5c:	6946                	ld	s2,80(sp)
    80003c5e:	69a6                	ld	s3,72(sp)
    80003c60:	6a06                	ld	s4,64(sp)
    80003c62:	7ae2                	ld	s5,56(sp)
    80003c64:	7b42                	ld	s6,48(sp)
    80003c66:	7ba2                	ld	s7,40(sp)
    80003c68:	7c02                	ld	s8,32(sp)
    80003c6a:	6ce2                	ld	s9,24(sp)
    80003c6c:	6d42                	ld	s10,16(sp)
    80003c6e:	6da2                	ld	s11,8(sp)
    80003c70:	6165                	addi	sp,sp,112
    80003c72:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c74:	89da                	mv	s3,s6
    80003c76:	bfc9                	j	80003c48 <writei+0xe2>
    return -1;
    80003c78:	557d                	li	a0,-1
}
    80003c7a:	8082                	ret
    return -1;
    80003c7c:	557d                	li	a0,-1
    80003c7e:	bfe1                	j	80003c56 <writei+0xf0>
    return -1;
    80003c80:	557d                	li	a0,-1
    80003c82:	bfd1                	j	80003c56 <writei+0xf0>

0000000080003c84 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c84:	1141                	addi	sp,sp,-16
    80003c86:	e406                	sd	ra,8(sp)
    80003c88:	e022                	sd	s0,0(sp)
    80003c8a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c8c:	4639                	li	a2,14
    80003c8e:	ffffd097          	auipc	ra,0xffffd
    80003c92:	130080e7          	jalr	304(ra) # 80000dbe <strncmp>
}
    80003c96:	60a2                	ld	ra,8(sp)
    80003c98:	6402                	ld	s0,0(sp)
    80003c9a:	0141                	addi	sp,sp,16
    80003c9c:	8082                	ret

0000000080003c9e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c9e:	7139                	addi	sp,sp,-64
    80003ca0:	fc06                	sd	ra,56(sp)
    80003ca2:	f822                	sd	s0,48(sp)
    80003ca4:	f426                	sd	s1,40(sp)
    80003ca6:	f04a                	sd	s2,32(sp)
    80003ca8:	ec4e                	sd	s3,24(sp)
    80003caa:	e852                	sd	s4,16(sp)
    80003cac:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003cae:	04451703          	lh	a4,68(a0)
    80003cb2:	4785                	li	a5,1
    80003cb4:	00f71a63          	bne	a4,a5,80003cc8 <dirlookup+0x2a>
    80003cb8:	892a                	mv	s2,a0
    80003cba:	89ae                	mv	s3,a1
    80003cbc:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cbe:	457c                	lw	a5,76(a0)
    80003cc0:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003cc2:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cc4:	e79d                	bnez	a5,80003cf2 <dirlookup+0x54>
    80003cc6:	a8a5                	j	80003d3e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003cc8:	00005517          	auipc	a0,0x5
    80003ccc:	a2850513          	addi	a0,a0,-1496 # 800086f0 <syscalls+0x1c0>
    80003cd0:	ffffd097          	auipc	ra,0xffffd
    80003cd4:	874080e7          	jalr	-1932(ra) # 80000544 <panic>
      panic("dirlookup read");
    80003cd8:	00005517          	auipc	a0,0x5
    80003cdc:	a3050513          	addi	a0,a0,-1488 # 80008708 <syscalls+0x1d8>
    80003ce0:	ffffd097          	auipc	ra,0xffffd
    80003ce4:	864080e7          	jalr	-1948(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ce8:	24c1                	addiw	s1,s1,16
    80003cea:	04c92783          	lw	a5,76(s2)
    80003cee:	04f4f763          	bgeu	s1,a5,80003d3c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cf2:	4741                	li	a4,16
    80003cf4:	86a6                	mv	a3,s1
    80003cf6:	fc040613          	addi	a2,s0,-64
    80003cfa:	4581                	li	a1,0
    80003cfc:	854a                	mv	a0,s2
    80003cfe:	00000097          	auipc	ra,0x0
    80003d02:	d70080e7          	jalr	-656(ra) # 80003a6e <readi>
    80003d06:	47c1                	li	a5,16
    80003d08:	fcf518e3          	bne	a0,a5,80003cd8 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d0c:	fc045783          	lhu	a5,-64(s0)
    80003d10:	dfe1                	beqz	a5,80003ce8 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d12:	fc240593          	addi	a1,s0,-62
    80003d16:	854e                	mv	a0,s3
    80003d18:	00000097          	auipc	ra,0x0
    80003d1c:	f6c080e7          	jalr	-148(ra) # 80003c84 <namecmp>
    80003d20:	f561                	bnez	a0,80003ce8 <dirlookup+0x4a>
      if(poff)
    80003d22:	000a0463          	beqz	s4,80003d2a <dirlookup+0x8c>
        *poff = off;
    80003d26:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d2a:	fc045583          	lhu	a1,-64(s0)
    80003d2e:	00092503          	lw	a0,0(s2)
    80003d32:	fffff097          	auipc	ra,0xfffff
    80003d36:	750080e7          	jalr	1872(ra) # 80003482 <iget>
    80003d3a:	a011                	j	80003d3e <dirlookup+0xa0>
  return 0;
    80003d3c:	4501                	li	a0,0
}
    80003d3e:	70e2                	ld	ra,56(sp)
    80003d40:	7442                	ld	s0,48(sp)
    80003d42:	74a2                	ld	s1,40(sp)
    80003d44:	7902                	ld	s2,32(sp)
    80003d46:	69e2                	ld	s3,24(sp)
    80003d48:	6a42                	ld	s4,16(sp)
    80003d4a:	6121                	addi	sp,sp,64
    80003d4c:	8082                	ret

0000000080003d4e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d4e:	711d                	addi	sp,sp,-96
    80003d50:	ec86                	sd	ra,88(sp)
    80003d52:	e8a2                	sd	s0,80(sp)
    80003d54:	e4a6                	sd	s1,72(sp)
    80003d56:	e0ca                	sd	s2,64(sp)
    80003d58:	fc4e                	sd	s3,56(sp)
    80003d5a:	f852                	sd	s4,48(sp)
    80003d5c:	f456                	sd	s5,40(sp)
    80003d5e:	f05a                	sd	s6,32(sp)
    80003d60:	ec5e                	sd	s7,24(sp)
    80003d62:	e862                	sd	s8,16(sp)
    80003d64:	e466                	sd	s9,8(sp)
    80003d66:	1080                	addi	s0,sp,96
    80003d68:	84aa                	mv	s1,a0
    80003d6a:	8b2e                	mv	s6,a1
    80003d6c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d6e:	00054703          	lbu	a4,0(a0)
    80003d72:	02f00793          	li	a5,47
    80003d76:	02f70363          	beq	a4,a5,80003d9c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d7a:	ffffe097          	auipc	ra,0xffffe
    80003d7e:	c4c080e7          	jalr	-948(ra) # 800019c6 <myproc>
    80003d82:	15053503          	ld	a0,336(a0)
    80003d86:	00000097          	auipc	ra,0x0
    80003d8a:	9f6080e7          	jalr	-1546(ra) # 8000377c <idup>
    80003d8e:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d90:	02f00913          	li	s2,47
  len = path - s;
    80003d94:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d96:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d98:	4c05                	li	s8,1
    80003d9a:	a865                	j	80003e52 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d9c:	4585                	li	a1,1
    80003d9e:	4505                	li	a0,1
    80003da0:	fffff097          	auipc	ra,0xfffff
    80003da4:	6e2080e7          	jalr	1762(ra) # 80003482 <iget>
    80003da8:	89aa                	mv	s3,a0
    80003daa:	b7dd                	j	80003d90 <namex+0x42>
      iunlockput(ip);
    80003dac:	854e                	mv	a0,s3
    80003dae:	00000097          	auipc	ra,0x0
    80003db2:	c6e080e7          	jalr	-914(ra) # 80003a1c <iunlockput>
      return 0;
    80003db6:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003db8:	854e                	mv	a0,s3
    80003dba:	60e6                	ld	ra,88(sp)
    80003dbc:	6446                	ld	s0,80(sp)
    80003dbe:	64a6                	ld	s1,72(sp)
    80003dc0:	6906                	ld	s2,64(sp)
    80003dc2:	79e2                	ld	s3,56(sp)
    80003dc4:	7a42                	ld	s4,48(sp)
    80003dc6:	7aa2                	ld	s5,40(sp)
    80003dc8:	7b02                	ld	s6,32(sp)
    80003dca:	6be2                	ld	s7,24(sp)
    80003dcc:	6c42                	ld	s8,16(sp)
    80003dce:	6ca2                	ld	s9,8(sp)
    80003dd0:	6125                	addi	sp,sp,96
    80003dd2:	8082                	ret
      iunlock(ip);
    80003dd4:	854e                	mv	a0,s3
    80003dd6:	00000097          	auipc	ra,0x0
    80003dda:	aa6080e7          	jalr	-1370(ra) # 8000387c <iunlock>
      return ip;
    80003dde:	bfe9                	j	80003db8 <namex+0x6a>
      iunlockput(ip);
    80003de0:	854e                	mv	a0,s3
    80003de2:	00000097          	auipc	ra,0x0
    80003de6:	c3a080e7          	jalr	-966(ra) # 80003a1c <iunlockput>
      return 0;
    80003dea:	89d2                	mv	s3,s4
    80003dec:	b7f1                	j	80003db8 <namex+0x6a>
  len = path - s;
    80003dee:	40b48633          	sub	a2,s1,a1
    80003df2:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003df6:	094cd463          	bge	s9,s4,80003e7e <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003dfa:	4639                	li	a2,14
    80003dfc:	8556                	mv	a0,s5
    80003dfe:	ffffd097          	auipc	ra,0xffffd
    80003e02:	f48080e7          	jalr	-184(ra) # 80000d46 <memmove>
  while(*path == '/')
    80003e06:	0004c783          	lbu	a5,0(s1)
    80003e0a:	01279763          	bne	a5,s2,80003e18 <namex+0xca>
    path++;
    80003e0e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e10:	0004c783          	lbu	a5,0(s1)
    80003e14:	ff278de3          	beq	a5,s2,80003e0e <namex+0xc0>
    ilock(ip);
    80003e18:	854e                	mv	a0,s3
    80003e1a:	00000097          	auipc	ra,0x0
    80003e1e:	9a0080e7          	jalr	-1632(ra) # 800037ba <ilock>
    if(ip->type != T_DIR){
    80003e22:	04499783          	lh	a5,68(s3)
    80003e26:	f98793e3          	bne	a5,s8,80003dac <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e2a:	000b0563          	beqz	s6,80003e34 <namex+0xe6>
    80003e2e:	0004c783          	lbu	a5,0(s1)
    80003e32:	d3cd                	beqz	a5,80003dd4 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e34:	865e                	mv	a2,s7
    80003e36:	85d6                	mv	a1,s5
    80003e38:	854e                	mv	a0,s3
    80003e3a:	00000097          	auipc	ra,0x0
    80003e3e:	e64080e7          	jalr	-412(ra) # 80003c9e <dirlookup>
    80003e42:	8a2a                	mv	s4,a0
    80003e44:	dd51                	beqz	a0,80003de0 <namex+0x92>
    iunlockput(ip);
    80003e46:	854e                	mv	a0,s3
    80003e48:	00000097          	auipc	ra,0x0
    80003e4c:	bd4080e7          	jalr	-1068(ra) # 80003a1c <iunlockput>
    ip = next;
    80003e50:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e52:	0004c783          	lbu	a5,0(s1)
    80003e56:	05279763          	bne	a5,s2,80003ea4 <namex+0x156>
    path++;
    80003e5a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e5c:	0004c783          	lbu	a5,0(s1)
    80003e60:	ff278de3          	beq	a5,s2,80003e5a <namex+0x10c>
  if(*path == 0)
    80003e64:	c79d                	beqz	a5,80003e92 <namex+0x144>
    path++;
    80003e66:	85a6                	mv	a1,s1
  len = path - s;
    80003e68:	8a5e                	mv	s4,s7
    80003e6a:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e6c:	01278963          	beq	a5,s2,80003e7e <namex+0x130>
    80003e70:	dfbd                	beqz	a5,80003dee <namex+0xa0>
    path++;
    80003e72:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e74:	0004c783          	lbu	a5,0(s1)
    80003e78:	ff279ce3          	bne	a5,s2,80003e70 <namex+0x122>
    80003e7c:	bf8d                	j	80003dee <namex+0xa0>
    memmove(name, s, len);
    80003e7e:	2601                	sext.w	a2,a2
    80003e80:	8556                	mv	a0,s5
    80003e82:	ffffd097          	auipc	ra,0xffffd
    80003e86:	ec4080e7          	jalr	-316(ra) # 80000d46 <memmove>
    name[len] = 0;
    80003e8a:	9a56                	add	s4,s4,s5
    80003e8c:	000a0023          	sb	zero,0(s4)
    80003e90:	bf9d                	j	80003e06 <namex+0xb8>
  if(nameiparent){
    80003e92:	f20b03e3          	beqz	s6,80003db8 <namex+0x6a>
    iput(ip);
    80003e96:	854e                	mv	a0,s3
    80003e98:	00000097          	auipc	ra,0x0
    80003e9c:	adc080e7          	jalr	-1316(ra) # 80003974 <iput>
    return 0;
    80003ea0:	4981                	li	s3,0
    80003ea2:	bf19                	j	80003db8 <namex+0x6a>
  if(*path == 0)
    80003ea4:	d7fd                	beqz	a5,80003e92 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003ea6:	0004c783          	lbu	a5,0(s1)
    80003eaa:	85a6                	mv	a1,s1
    80003eac:	b7d1                	j	80003e70 <namex+0x122>

0000000080003eae <dirlink>:
{
    80003eae:	7139                	addi	sp,sp,-64
    80003eb0:	fc06                	sd	ra,56(sp)
    80003eb2:	f822                	sd	s0,48(sp)
    80003eb4:	f426                	sd	s1,40(sp)
    80003eb6:	f04a                	sd	s2,32(sp)
    80003eb8:	ec4e                	sd	s3,24(sp)
    80003eba:	e852                	sd	s4,16(sp)
    80003ebc:	0080                	addi	s0,sp,64
    80003ebe:	892a                	mv	s2,a0
    80003ec0:	8a2e                	mv	s4,a1
    80003ec2:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ec4:	4601                	li	a2,0
    80003ec6:	00000097          	auipc	ra,0x0
    80003eca:	dd8080e7          	jalr	-552(ra) # 80003c9e <dirlookup>
    80003ece:	e93d                	bnez	a0,80003f44 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ed0:	04c92483          	lw	s1,76(s2)
    80003ed4:	c49d                	beqz	s1,80003f02 <dirlink+0x54>
    80003ed6:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ed8:	4741                	li	a4,16
    80003eda:	86a6                	mv	a3,s1
    80003edc:	fc040613          	addi	a2,s0,-64
    80003ee0:	4581                	li	a1,0
    80003ee2:	854a                	mv	a0,s2
    80003ee4:	00000097          	auipc	ra,0x0
    80003ee8:	b8a080e7          	jalr	-1142(ra) # 80003a6e <readi>
    80003eec:	47c1                	li	a5,16
    80003eee:	06f51163          	bne	a0,a5,80003f50 <dirlink+0xa2>
    if(de.inum == 0)
    80003ef2:	fc045783          	lhu	a5,-64(s0)
    80003ef6:	c791                	beqz	a5,80003f02 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ef8:	24c1                	addiw	s1,s1,16
    80003efa:	04c92783          	lw	a5,76(s2)
    80003efe:	fcf4ede3          	bltu	s1,a5,80003ed8 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f02:	4639                	li	a2,14
    80003f04:	85d2                	mv	a1,s4
    80003f06:	fc240513          	addi	a0,s0,-62
    80003f0a:	ffffd097          	auipc	ra,0xffffd
    80003f0e:	ef0080e7          	jalr	-272(ra) # 80000dfa <strncpy>
  de.inum = inum;
    80003f12:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f16:	4741                	li	a4,16
    80003f18:	86a6                	mv	a3,s1
    80003f1a:	fc040613          	addi	a2,s0,-64
    80003f1e:	4581                	li	a1,0
    80003f20:	854a                	mv	a0,s2
    80003f22:	00000097          	auipc	ra,0x0
    80003f26:	c44080e7          	jalr	-956(ra) # 80003b66 <writei>
    80003f2a:	1541                	addi	a0,a0,-16
    80003f2c:	00a03533          	snez	a0,a0
    80003f30:	40a00533          	neg	a0,a0
}
    80003f34:	70e2                	ld	ra,56(sp)
    80003f36:	7442                	ld	s0,48(sp)
    80003f38:	74a2                	ld	s1,40(sp)
    80003f3a:	7902                	ld	s2,32(sp)
    80003f3c:	69e2                	ld	s3,24(sp)
    80003f3e:	6a42                	ld	s4,16(sp)
    80003f40:	6121                	addi	sp,sp,64
    80003f42:	8082                	ret
    iput(ip);
    80003f44:	00000097          	auipc	ra,0x0
    80003f48:	a30080e7          	jalr	-1488(ra) # 80003974 <iput>
    return -1;
    80003f4c:	557d                	li	a0,-1
    80003f4e:	b7dd                	j	80003f34 <dirlink+0x86>
      panic("dirlink read");
    80003f50:	00004517          	auipc	a0,0x4
    80003f54:	7c850513          	addi	a0,a0,1992 # 80008718 <syscalls+0x1e8>
    80003f58:	ffffc097          	auipc	ra,0xffffc
    80003f5c:	5ec080e7          	jalr	1516(ra) # 80000544 <panic>

0000000080003f60 <namei>:

struct inode*
namei(char *path)
{
    80003f60:	1101                	addi	sp,sp,-32
    80003f62:	ec06                	sd	ra,24(sp)
    80003f64:	e822                	sd	s0,16(sp)
    80003f66:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f68:	fe040613          	addi	a2,s0,-32
    80003f6c:	4581                	li	a1,0
    80003f6e:	00000097          	auipc	ra,0x0
    80003f72:	de0080e7          	jalr	-544(ra) # 80003d4e <namex>
}
    80003f76:	60e2                	ld	ra,24(sp)
    80003f78:	6442                	ld	s0,16(sp)
    80003f7a:	6105                	addi	sp,sp,32
    80003f7c:	8082                	ret

0000000080003f7e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f7e:	1141                	addi	sp,sp,-16
    80003f80:	e406                	sd	ra,8(sp)
    80003f82:	e022                	sd	s0,0(sp)
    80003f84:	0800                	addi	s0,sp,16
    80003f86:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f88:	4585                	li	a1,1
    80003f8a:	00000097          	auipc	ra,0x0
    80003f8e:	dc4080e7          	jalr	-572(ra) # 80003d4e <namex>
}
    80003f92:	60a2                	ld	ra,8(sp)
    80003f94:	6402                	ld	s0,0(sp)
    80003f96:	0141                	addi	sp,sp,16
    80003f98:	8082                	ret

0000000080003f9a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f9a:	1101                	addi	sp,sp,-32
    80003f9c:	ec06                	sd	ra,24(sp)
    80003f9e:	e822                	sd	s0,16(sp)
    80003fa0:	e426                	sd	s1,8(sp)
    80003fa2:	e04a                	sd	s2,0(sp)
    80003fa4:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003fa6:	0001d917          	auipc	s2,0x1d
    80003faa:	74a90913          	addi	s2,s2,1866 # 800216f0 <log>
    80003fae:	01892583          	lw	a1,24(s2)
    80003fb2:	02892503          	lw	a0,40(s2)
    80003fb6:	fffff097          	auipc	ra,0xfffff
    80003fba:	fea080e7          	jalr	-22(ra) # 80002fa0 <bread>
    80003fbe:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fc0:	02c92683          	lw	a3,44(s2)
    80003fc4:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fc6:	02d05763          	blez	a3,80003ff4 <write_head+0x5a>
    80003fca:	0001d797          	auipc	a5,0x1d
    80003fce:	75678793          	addi	a5,a5,1878 # 80021720 <log+0x30>
    80003fd2:	05c50713          	addi	a4,a0,92
    80003fd6:	36fd                	addiw	a3,a3,-1
    80003fd8:	1682                	slli	a3,a3,0x20
    80003fda:	9281                	srli	a3,a3,0x20
    80003fdc:	068a                	slli	a3,a3,0x2
    80003fde:	0001d617          	auipc	a2,0x1d
    80003fe2:	74660613          	addi	a2,a2,1862 # 80021724 <log+0x34>
    80003fe6:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003fe8:	4390                	lw	a2,0(a5)
    80003fea:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fec:	0791                	addi	a5,a5,4
    80003fee:	0711                	addi	a4,a4,4
    80003ff0:	fed79ce3          	bne	a5,a3,80003fe8 <write_head+0x4e>
  }
  bwrite(buf);
    80003ff4:	8526                	mv	a0,s1
    80003ff6:	fffff097          	auipc	ra,0xfffff
    80003ffa:	09c080e7          	jalr	156(ra) # 80003092 <bwrite>
  brelse(buf);
    80003ffe:	8526                	mv	a0,s1
    80004000:	fffff097          	auipc	ra,0xfffff
    80004004:	0d0080e7          	jalr	208(ra) # 800030d0 <brelse>
}
    80004008:	60e2                	ld	ra,24(sp)
    8000400a:	6442                	ld	s0,16(sp)
    8000400c:	64a2                	ld	s1,8(sp)
    8000400e:	6902                	ld	s2,0(sp)
    80004010:	6105                	addi	sp,sp,32
    80004012:	8082                	ret

0000000080004014 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004014:	0001d797          	auipc	a5,0x1d
    80004018:	7087a783          	lw	a5,1800(a5) # 8002171c <log+0x2c>
    8000401c:	0af05d63          	blez	a5,800040d6 <install_trans+0xc2>
{
    80004020:	7139                	addi	sp,sp,-64
    80004022:	fc06                	sd	ra,56(sp)
    80004024:	f822                	sd	s0,48(sp)
    80004026:	f426                	sd	s1,40(sp)
    80004028:	f04a                	sd	s2,32(sp)
    8000402a:	ec4e                	sd	s3,24(sp)
    8000402c:	e852                	sd	s4,16(sp)
    8000402e:	e456                	sd	s5,8(sp)
    80004030:	e05a                	sd	s6,0(sp)
    80004032:	0080                	addi	s0,sp,64
    80004034:	8b2a                	mv	s6,a0
    80004036:	0001da97          	auipc	s5,0x1d
    8000403a:	6eaa8a93          	addi	s5,s5,1770 # 80021720 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000403e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004040:	0001d997          	auipc	s3,0x1d
    80004044:	6b098993          	addi	s3,s3,1712 # 800216f0 <log>
    80004048:	a035                	j	80004074 <install_trans+0x60>
      bunpin(dbuf);
    8000404a:	8526                	mv	a0,s1
    8000404c:	fffff097          	auipc	ra,0xfffff
    80004050:	15e080e7          	jalr	350(ra) # 800031aa <bunpin>
    brelse(lbuf);
    80004054:	854a                	mv	a0,s2
    80004056:	fffff097          	auipc	ra,0xfffff
    8000405a:	07a080e7          	jalr	122(ra) # 800030d0 <brelse>
    brelse(dbuf);
    8000405e:	8526                	mv	a0,s1
    80004060:	fffff097          	auipc	ra,0xfffff
    80004064:	070080e7          	jalr	112(ra) # 800030d0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004068:	2a05                	addiw	s4,s4,1
    8000406a:	0a91                	addi	s5,s5,4
    8000406c:	02c9a783          	lw	a5,44(s3)
    80004070:	04fa5963          	bge	s4,a5,800040c2 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004074:	0189a583          	lw	a1,24(s3)
    80004078:	014585bb          	addw	a1,a1,s4
    8000407c:	2585                	addiw	a1,a1,1
    8000407e:	0289a503          	lw	a0,40(s3)
    80004082:	fffff097          	auipc	ra,0xfffff
    80004086:	f1e080e7          	jalr	-226(ra) # 80002fa0 <bread>
    8000408a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000408c:	000aa583          	lw	a1,0(s5)
    80004090:	0289a503          	lw	a0,40(s3)
    80004094:	fffff097          	auipc	ra,0xfffff
    80004098:	f0c080e7          	jalr	-244(ra) # 80002fa0 <bread>
    8000409c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000409e:	40000613          	li	a2,1024
    800040a2:	05890593          	addi	a1,s2,88
    800040a6:	05850513          	addi	a0,a0,88
    800040aa:	ffffd097          	auipc	ra,0xffffd
    800040ae:	c9c080e7          	jalr	-868(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    800040b2:	8526                	mv	a0,s1
    800040b4:	fffff097          	auipc	ra,0xfffff
    800040b8:	fde080e7          	jalr	-34(ra) # 80003092 <bwrite>
    if(recovering == 0)
    800040bc:	f80b1ce3          	bnez	s6,80004054 <install_trans+0x40>
    800040c0:	b769                	j	8000404a <install_trans+0x36>
}
    800040c2:	70e2                	ld	ra,56(sp)
    800040c4:	7442                	ld	s0,48(sp)
    800040c6:	74a2                	ld	s1,40(sp)
    800040c8:	7902                	ld	s2,32(sp)
    800040ca:	69e2                	ld	s3,24(sp)
    800040cc:	6a42                	ld	s4,16(sp)
    800040ce:	6aa2                	ld	s5,8(sp)
    800040d0:	6b02                	ld	s6,0(sp)
    800040d2:	6121                	addi	sp,sp,64
    800040d4:	8082                	ret
    800040d6:	8082                	ret

00000000800040d8 <initlog>:
{
    800040d8:	7179                	addi	sp,sp,-48
    800040da:	f406                	sd	ra,40(sp)
    800040dc:	f022                	sd	s0,32(sp)
    800040de:	ec26                	sd	s1,24(sp)
    800040e0:	e84a                	sd	s2,16(sp)
    800040e2:	e44e                	sd	s3,8(sp)
    800040e4:	1800                	addi	s0,sp,48
    800040e6:	892a                	mv	s2,a0
    800040e8:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040ea:	0001d497          	auipc	s1,0x1d
    800040ee:	60648493          	addi	s1,s1,1542 # 800216f0 <log>
    800040f2:	00004597          	auipc	a1,0x4
    800040f6:	63658593          	addi	a1,a1,1590 # 80008728 <syscalls+0x1f8>
    800040fa:	8526                	mv	a0,s1
    800040fc:	ffffd097          	auipc	ra,0xffffd
    80004100:	a5e080e7          	jalr	-1442(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    80004104:	0149a583          	lw	a1,20(s3)
    80004108:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000410a:	0109a783          	lw	a5,16(s3)
    8000410e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004110:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004114:	854a                	mv	a0,s2
    80004116:	fffff097          	auipc	ra,0xfffff
    8000411a:	e8a080e7          	jalr	-374(ra) # 80002fa0 <bread>
  log.lh.n = lh->n;
    8000411e:	4d3c                	lw	a5,88(a0)
    80004120:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004122:	02f05563          	blez	a5,8000414c <initlog+0x74>
    80004126:	05c50713          	addi	a4,a0,92
    8000412a:	0001d697          	auipc	a3,0x1d
    8000412e:	5f668693          	addi	a3,a3,1526 # 80021720 <log+0x30>
    80004132:	37fd                	addiw	a5,a5,-1
    80004134:	1782                	slli	a5,a5,0x20
    80004136:	9381                	srli	a5,a5,0x20
    80004138:	078a                	slli	a5,a5,0x2
    8000413a:	06050613          	addi	a2,a0,96
    8000413e:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004140:	4310                	lw	a2,0(a4)
    80004142:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004144:	0711                	addi	a4,a4,4
    80004146:	0691                	addi	a3,a3,4
    80004148:	fef71ce3          	bne	a4,a5,80004140 <initlog+0x68>
  brelse(buf);
    8000414c:	fffff097          	auipc	ra,0xfffff
    80004150:	f84080e7          	jalr	-124(ra) # 800030d0 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004154:	4505                	li	a0,1
    80004156:	00000097          	auipc	ra,0x0
    8000415a:	ebe080e7          	jalr	-322(ra) # 80004014 <install_trans>
  log.lh.n = 0;
    8000415e:	0001d797          	auipc	a5,0x1d
    80004162:	5a07af23          	sw	zero,1470(a5) # 8002171c <log+0x2c>
  write_head(); // clear the log
    80004166:	00000097          	auipc	ra,0x0
    8000416a:	e34080e7          	jalr	-460(ra) # 80003f9a <write_head>
}
    8000416e:	70a2                	ld	ra,40(sp)
    80004170:	7402                	ld	s0,32(sp)
    80004172:	64e2                	ld	s1,24(sp)
    80004174:	6942                	ld	s2,16(sp)
    80004176:	69a2                	ld	s3,8(sp)
    80004178:	6145                	addi	sp,sp,48
    8000417a:	8082                	ret

000000008000417c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000417c:	1101                	addi	sp,sp,-32
    8000417e:	ec06                	sd	ra,24(sp)
    80004180:	e822                	sd	s0,16(sp)
    80004182:	e426                	sd	s1,8(sp)
    80004184:	e04a                	sd	s2,0(sp)
    80004186:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004188:	0001d517          	auipc	a0,0x1d
    8000418c:	56850513          	addi	a0,a0,1384 # 800216f0 <log>
    80004190:	ffffd097          	auipc	ra,0xffffd
    80004194:	a5a080e7          	jalr	-1446(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    80004198:	0001d497          	auipc	s1,0x1d
    8000419c:	55848493          	addi	s1,s1,1368 # 800216f0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041a0:	4979                	li	s2,30
    800041a2:	a039                	j	800041b0 <begin_op+0x34>
      sleep(&log, &log.lock);
    800041a4:	85a6                	mv	a1,s1
    800041a6:	8526                	mv	a0,s1
    800041a8:	ffffe097          	auipc	ra,0xffffe
    800041ac:	ed6080e7          	jalr	-298(ra) # 8000207e <sleep>
    if(log.committing){
    800041b0:	50dc                	lw	a5,36(s1)
    800041b2:	fbed                	bnez	a5,800041a4 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041b4:	509c                	lw	a5,32(s1)
    800041b6:	0017871b          	addiw	a4,a5,1
    800041ba:	0007069b          	sext.w	a3,a4
    800041be:	0027179b          	slliw	a5,a4,0x2
    800041c2:	9fb9                	addw	a5,a5,a4
    800041c4:	0017979b          	slliw	a5,a5,0x1
    800041c8:	54d8                	lw	a4,44(s1)
    800041ca:	9fb9                	addw	a5,a5,a4
    800041cc:	00f95963          	bge	s2,a5,800041de <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041d0:	85a6                	mv	a1,s1
    800041d2:	8526                	mv	a0,s1
    800041d4:	ffffe097          	auipc	ra,0xffffe
    800041d8:	eaa080e7          	jalr	-342(ra) # 8000207e <sleep>
    800041dc:	bfd1                	j	800041b0 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041de:	0001d517          	auipc	a0,0x1d
    800041e2:	51250513          	addi	a0,a0,1298 # 800216f0 <log>
    800041e6:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041e8:	ffffd097          	auipc	ra,0xffffd
    800041ec:	ab6080e7          	jalr	-1354(ra) # 80000c9e <release>
      break;
    }
  }
}
    800041f0:	60e2                	ld	ra,24(sp)
    800041f2:	6442                	ld	s0,16(sp)
    800041f4:	64a2                	ld	s1,8(sp)
    800041f6:	6902                	ld	s2,0(sp)
    800041f8:	6105                	addi	sp,sp,32
    800041fa:	8082                	ret

00000000800041fc <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041fc:	7139                	addi	sp,sp,-64
    800041fe:	fc06                	sd	ra,56(sp)
    80004200:	f822                	sd	s0,48(sp)
    80004202:	f426                	sd	s1,40(sp)
    80004204:	f04a                	sd	s2,32(sp)
    80004206:	ec4e                	sd	s3,24(sp)
    80004208:	e852                	sd	s4,16(sp)
    8000420a:	e456                	sd	s5,8(sp)
    8000420c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000420e:	0001d497          	auipc	s1,0x1d
    80004212:	4e248493          	addi	s1,s1,1250 # 800216f0 <log>
    80004216:	8526                	mv	a0,s1
    80004218:	ffffd097          	auipc	ra,0xffffd
    8000421c:	9d2080e7          	jalr	-1582(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    80004220:	509c                	lw	a5,32(s1)
    80004222:	37fd                	addiw	a5,a5,-1
    80004224:	0007891b          	sext.w	s2,a5
    80004228:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000422a:	50dc                	lw	a5,36(s1)
    8000422c:	efb9                	bnez	a5,8000428a <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000422e:	06091663          	bnez	s2,8000429a <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004232:	0001d497          	auipc	s1,0x1d
    80004236:	4be48493          	addi	s1,s1,1214 # 800216f0 <log>
    8000423a:	4785                	li	a5,1
    8000423c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000423e:	8526                	mv	a0,s1
    80004240:	ffffd097          	auipc	ra,0xffffd
    80004244:	a5e080e7          	jalr	-1442(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004248:	54dc                	lw	a5,44(s1)
    8000424a:	06f04763          	bgtz	a5,800042b8 <end_op+0xbc>
    acquire(&log.lock);
    8000424e:	0001d497          	auipc	s1,0x1d
    80004252:	4a248493          	addi	s1,s1,1186 # 800216f0 <log>
    80004256:	8526                	mv	a0,s1
    80004258:	ffffd097          	auipc	ra,0xffffd
    8000425c:	992080e7          	jalr	-1646(ra) # 80000bea <acquire>
    log.committing = 0;
    80004260:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004264:	8526                	mv	a0,s1
    80004266:	ffffe097          	auipc	ra,0xffffe
    8000426a:	e7c080e7          	jalr	-388(ra) # 800020e2 <wakeup>
    release(&log.lock);
    8000426e:	8526                	mv	a0,s1
    80004270:	ffffd097          	auipc	ra,0xffffd
    80004274:	a2e080e7          	jalr	-1490(ra) # 80000c9e <release>
}
    80004278:	70e2                	ld	ra,56(sp)
    8000427a:	7442                	ld	s0,48(sp)
    8000427c:	74a2                	ld	s1,40(sp)
    8000427e:	7902                	ld	s2,32(sp)
    80004280:	69e2                	ld	s3,24(sp)
    80004282:	6a42                	ld	s4,16(sp)
    80004284:	6aa2                	ld	s5,8(sp)
    80004286:	6121                	addi	sp,sp,64
    80004288:	8082                	ret
    panic("log.committing");
    8000428a:	00004517          	auipc	a0,0x4
    8000428e:	4a650513          	addi	a0,a0,1190 # 80008730 <syscalls+0x200>
    80004292:	ffffc097          	auipc	ra,0xffffc
    80004296:	2b2080e7          	jalr	690(ra) # 80000544 <panic>
    wakeup(&log);
    8000429a:	0001d497          	auipc	s1,0x1d
    8000429e:	45648493          	addi	s1,s1,1110 # 800216f0 <log>
    800042a2:	8526                	mv	a0,s1
    800042a4:	ffffe097          	auipc	ra,0xffffe
    800042a8:	e3e080e7          	jalr	-450(ra) # 800020e2 <wakeup>
  release(&log.lock);
    800042ac:	8526                	mv	a0,s1
    800042ae:	ffffd097          	auipc	ra,0xffffd
    800042b2:	9f0080e7          	jalr	-1552(ra) # 80000c9e <release>
  if(do_commit){
    800042b6:	b7c9                	j	80004278 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042b8:	0001da97          	auipc	s5,0x1d
    800042bc:	468a8a93          	addi	s5,s5,1128 # 80021720 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042c0:	0001da17          	auipc	s4,0x1d
    800042c4:	430a0a13          	addi	s4,s4,1072 # 800216f0 <log>
    800042c8:	018a2583          	lw	a1,24(s4)
    800042cc:	012585bb          	addw	a1,a1,s2
    800042d0:	2585                	addiw	a1,a1,1
    800042d2:	028a2503          	lw	a0,40(s4)
    800042d6:	fffff097          	auipc	ra,0xfffff
    800042da:	cca080e7          	jalr	-822(ra) # 80002fa0 <bread>
    800042de:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042e0:	000aa583          	lw	a1,0(s5)
    800042e4:	028a2503          	lw	a0,40(s4)
    800042e8:	fffff097          	auipc	ra,0xfffff
    800042ec:	cb8080e7          	jalr	-840(ra) # 80002fa0 <bread>
    800042f0:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042f2:	40000613          	li	a2,1024
    800042f6:	05850593          	addi	a1,a0,88
    800042fa:	05848513          	addi	a0,s1,88
    800042fe:	ffffd097          	auipc	ra,0xffffd
    80004302:	a48080e7          	jalr	-1464(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    80004306:	8526                	mv	a0,s1
    80004308:	fffff097          	auipc	ra,0xfffff
    8000430c:	d8a080e7          	jalr	-630(ra) # 80003092 <bwrite>
    brelse(from);
    80004310:	854e                	mv	a0,s3
    80004312:	fffff097          	auipc	ra,0xfffff
    80004316:	dbe080e7          	jalr	-578(ra) # 800030d0 <brelse>
    brelse(to);
    8000431a:	8526                	mv	a0,s1
    8000431c:	fffff097          	auipc	ra,0xfffff
    80004320:	db4080e7          	jalr	-588(ra) # 800030d0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004324:	2905                	addiw	s2,s2,1
    80004326:	0a91                	addi	s5,s5,4
    80004328:	02ca2783          	lw	a5,44(s4)
    8000432c:	f8f94ee3          	blt	s2,a5,800042c8 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004330:	00000097          	auipc	ra,0x0
    80004334:	c6a080e7          	jalr	-918(ra) # 80003f9a <write_head>
    install_trans(0); // Now install writes to home locations
    80004338:	4501                	li	a0,0
    8000433a:	00000097          	auipc	ra,0x0
    8000433e:	cda080e7          	jalr	-806(ra) # 80004014 <install_trans>
    log.lh.n = 0;
    80004342:	0001d797          	auipc	a5,0x1d
    80004346:	3c07ad23          	sw	zero,986(a5) # 8002171c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000434a:	00000097          	auipc	ra,0x0
    8000434e:	c50080e7          	jalr	-944(ra) # 80003f9a <write_head>
    80004352:	bdf5                	j	8000424e <end_op+0x52>

0000000080004354 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004354:	1101                	addi	sp,sp,-32
    80004356:	ec06                	sd	ra,24(sp)
    80004358:	e822                	sd	s0,16(sp)
    8000435a:	e426                	sd	s1,8(sp)
    8000435c:	e04a                	sd	s2,0(sp)
    8000435e:	1000                	addi	s0,sp,32
    80004360:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004362:	0001d917          	auipc	s2,0x1d
    80004366:	38e90913          	addi	s2,s2,910 # 800216f0 <log>
    8000436a:	854a                	mv	a0,s2
    8000436c:	ffffd097          	auipc	ra,0xffffd
    80004370:	87e080e7          	jalr	-1922(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004374:	02c92603          	lw	a2,44(s2)
    80004378:	47f5                	li	a5,29
    8000437a:	06c7c563          	blt	a5,a2,800043e4 <log_write+0x90>
    8000437e:	0001d797          	auipc	a5,0x1d
    80004382:	38e7a783          	lw	a5,910(a5) # 8002170c <log+0x1c>
    80004386:	37fd                	addiw	a5,a5,-1
    80004388:	04f65e63          	bge	a2,a5,800043e4 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000438c:	0001d797          	auipc	a5,0x1d
    80004390:	3847a783          	lw	a5,900(a5) # 80021710 <log+0x20>
    80004394:	06f05063          	blez	a5,800043f4 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004398:	4781                	li	a5,0
    8000439a:	06c05563          	blez	a2,80004404 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000439e:	44cc                	lw	a1,12(s1)
    800043a0:	0001d717          	auipc	a4,0x1d
    800043a4:	38070713          	addi	a4,a4,896 # 80021720 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043a8:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043aa:	4314                	lw	a3,0(a4)
    800043ac:	04b68c63          	beq	a3,a1,80004404 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800043b0:	2785                	addiw	a5,a5,1
    800043b2:	0711                	addi	a4,a4,4
    800043b4:	fef61be3          	bne	a2,a5,800043aa <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043b8:	0621                	addi	a2,a2,8
    800043ba:	060a                	slli	a2,a2,0x2
    800043bc:	0001d797          	auipc	a5,0x1d
    800043c0:	33478793          	addi	a5,a5,820 # 800216f0 <log>
    800043c4:	963e                	add	a2,a2,a5
    800043c6:	44dc                	lw	a5,12(s1)
    800043c8:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043ca:	8526                	mv	a0,s1
    800043cc:	fffff097          	auipc	ra,0xfffff
    800043d0:	da2080e7          	jalr	-606(ra) # 8000316e <bpin>
    log.lh.n++;
    800043d4:	0001d717          	auipc	a4,0x1d
    800043d8:	31c70713          	addi	a4,a4,796 # 800216f0 <log>
    800043dc:	575c                	lw	a5,44(a4)
    800043de:	2785                	addiw	a5,a5,1
    800043e0:	d75c                	sw	a5,44(a4)
    800043e2:	a835                	j	8000441e <log_write+0xca>
    panic("too big a transaction");
    800043e4:	00004517          	auipc	a0,0x4
    800043e8:	35c50513          	addi	a0,a0,860 # 80008740 <syscalls+0x210>
    800043ec:	ffffc097          	auipc	ra,0xffffc
    800043f0:	158080e7          	jalr	344(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    800043f4:	00004517          	auipc	a0,0x4
    800043f8:	36450513          	addi	a0,a0,868 # 80008758 <syscalls+0x228>
    800043fc:	ffffc097          	auipc	ra,0xffffc
    80004400:	148080e7          	jalr	328(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    80004404:	00878713          	addi	a4,a5,8
    80004408:	00271693          	slli	a3,a4,0x2
    8000440c:	0001d717          	auipc	a4,0x1d
    80004410:	2e470713          	addi	a4,a4,740 # 800216f0 <log>
    80004414:	9736                	add	a4,a4,a3
    80004416:	44d4                	lw	a3,12(s1)
    80004418:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000441a:	faf608e3          	beq	a2,a5,800043ca <log_write+0x76>
  }
  release(&log.lock);
    8000441e:	0001d517          	auipc	a0,0x1d
    80004422:	2d250513          	addi	a0,a0,722 # 800216f0 <log>
    80004426:	ffffd097          	auipc	ra,0xffffd
    8000442a:	878080e7          	jalr	-1928(ra) # 80000c9e <release>
}
    8000442e:	60e2                	ld	ra,24(sp)
    80004430:	6442                	ld	s0,16(sp)
    80004432:	64a2                	ld	s1,8(sp)
    80004434:	6902                	ld	s2,0(sp)
    80004436:	6105                	addi	sp,sp,32
    80004438:	8082                	ret

000000008000443a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000443a:	1101                	addi	sp,sp,-32
    8000443c:	ec06                	sd	ra,24(sp)
    8000443e:	e822                	sd	s0,16(sp)
    80004440:	e426                	sd	s1,8(sp)
    80004442:	e04a                	sd	s2,0(sp)
    80004444:	1000                	addi	s0,sp,32
    80004446:	84aa                	mv	s1,a0
    80004448:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000444a:	00004597          	auipc	a1,0x4
    8000444e:	32e58593          	addi	a1,a1,814 # 80008778 <syscalls+0x248>
    80004452:	0521                	addi	a0,a0,8
    80004454:	ffffc097          	auipc	ra,0xffffc
    80004458:	706080e7          	jalr	1798(ra) # 80000b5a <initlock>
  lk->name = name;
    8000445c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004460:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004464:	0204a423          	sw	zero,40(s1)
}
    80004468:	60e2                	ld	ra,24(sp)
    8000446a:	6442                	ld	s0,16(sp)
    8000446c:	64a2                	ld	s1,8(sp)
    8000446e:	6902                	ld	s2,0(sp)
    80004470:	6105                	addi	sp,sp,32
    80004472:	8082                	ret

0000000080004474 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004474:	1101                	addi	sp,sp,-32
    80004476:	ec06                	sd	ra,24(sp)
    80004478:	e822                	sd	s0,16(sp)
    8000447a:	e426                	sd	s1,8(sp)
    8000447c:	e04a                	sd	s2,0(sp)
    8000447e:	1000                	addi	s0,sp,32
    80004480:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004482:	00850913          	addi	s2,a0,8
    80004486:	854a                	mv	a0,s2
    80004488:	ffffc097          	auipc	ra,0xffffc
    8000448c:	762080e7          	jalr	1890(ra) # 80000bea <acquire>
  while (lk->locked) {
    80004490:	409c                	lw	a5,0(s1)
    80004492:	cb89                	beqz	a5,800044a4 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004494:	85ca                	mv	a1,s2
    80004496:	8526                	mv	a0,s1
    80004498:	ffffe097          	auipc	ra,0xffffe
    8000449c:	be6080e7          	jalr	-1050(ra) # 8000207e <sleep>
  while (lk->locked) {
    800044a0:	409c                	lw	a5,0(s1)
    800044a2:	fbed                	bnez	a5,80004494 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044a4:	4785                	li	a5,1
    800044a6:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044a8:	ffffd097          	auipc	ra,0xffffd
    800044ac:	51e080e7          	jalr	1310(ra) # 800019c6 <myproc>
    800044b0:	591c                	lw	a5,48(a0)
    800044b2:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044b4:	854a                	mv	a0,s2
    800044b6:	ffffc097          	auipc	ra,0xffffc
    800044ba:	7e8080e7          	jalr	2024(ra) # 80000c9e <release>
}
    800044be:	60e2                	ld	ra,24(sp)
    800044c0:	6442                	ld	s0,16(sp)
    800044c2:	64a2                	ld	s1,8(sp)
    800044c4:	6902                	ld	s2,0(sp)
    800044c6:	6105                	addi	sp,sp,32
    800044c8:	8082                	ret

00000000800044ca <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044ca:	1101                	addi	sp,sp,-32
    800044cc:	ec06                	sd	ra,24(sp)
    800044ce:	e822                	sd	s0,16(sp)
    800044d0:	e426                	sd	s1,8(sp)
    800044d2:	e04a                	sd	s2,0(sp)
    800044d4:	1000                	addi	s0,sp,32
    800044d6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044d8:	00850913          	addi	s2,a0,8
    800044dc:	854a                	mv	a0,s2
    800044de:	ffffc097          	auipc	ra,0xffffc
    800044e2:	70c080e7          	jalr	1804(ra) # 80000bea <acquire>
  lk->locked = 0;
    800044e6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044ea:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044ee:	8526                	mv	a0,s1
    800044f0:	ffffe097          	auipc	ra,0xffffe
    800044f4:	bf2080e7          	jalr	-1038(ra) # 800020e2 <wakeup>
  release(&lk->lk);
    800044f8:	854a                	mv	a0,s2
    800044fa:	ffffc097          	auipc	ra,0xffffc
    800044fe:	7a4080e7          	jalr	1956(ra) # 80000c9e <release>
}
    80004502:	60e2                	ld	ra,24(sp)
    80004504:	6442                	ld	s0,16(sp)
    80004506:	64a2                	ld	s1,8(sp)
    80004508:	6902                	ld	s2,0(sp)
    8000450a:	6105                	addi	sp,sp,32
    8000450c:	8082                	ret

000000008000450e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000450e:	7179                	addi	sp,sp,-48
    80004510:	f406                	sd	ra,40(sp)
    80004512:	f022                	sd	s0,32(sp)
    80004514:	ec26                	sd	s1,24(sp)
    80004516:	e84a                	sd	s2,16(sp)
    80004518:	e44e                	sd	s3,8(sp)
    8000451a:	1800                	addi	s0,sp,48
    8000451c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000451e:	00850913          	addi	s2,a0,8
    80004522:	854a                	mv	a0,s2
    80004524:	ffffc097          	auipc	ra,0xffffc
    80004528:	6c6080e7          	jalr	1734(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000452c:	409c                	lw	a5,0(s1)
    8000452e:	ef99                	bnez	a5,8000454c <holdingsleep+0x3e>
    80004530:	4481                	li	s1,0
  release(&lk->lk);
    80004532:	854a                	mv	a0,s2
    80004534:	ffffc097          	auipc	ra,0xffffc
    80004538:	76a080e7          	jalr	1898(ra) # 80000c9e <release>
  return r;
}
    8000453c:	8526                	mv	a0,s1
    8000453e:	70a2                	ld	ra,40(sp)
    80004540:	7402                	ld	s0,32(sp)
    80004542:	64e2                	ld	s1,24(sp)
    80004544:	6942                	ld	s2,16(sp)
    80004546:	69a2                	ld	s3,8(sp)
    80004548:	6145                	addi	sp,sp,48
    8000454a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000454c:	0284a983          	lw	s3,40(s1)
    80004550:	ffffd097          	auipc	ra,0xffffd
    80004554:	476080e7          	jalr	1142(ra) # 800019c6 <myproc>
    80004558:	5904                	lw	s1,48(a0)
    8000455a:	413484b3          	sub	s1,s1,s3
    8000455e:	0014b493          	seqz	s1,s1
    80004562:	bfc1                	j	80004532 <holdingsleep+0x24>

0000000080004564 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004564:	1141                	addi	sp,sp,-16
    80004566:	e406                	sd	ra,8(sp)
    80004568:	e022                	sd	s0,0(sp)
    8000456a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000456c:	00004597          	auipc	a1,0x4
    80004570:	21c58593          	addi	a1,a1,540 # 80008788 <syscalls+0x258>
    80004574:	0001d517          	auipc	a0,0x1d
    80004578:	2c450513          	addi	a0,a0,708 # 80021838 <ftable>
    8000457c:	ffffc097          	auipc	ra,0xffffc
    80004580:	5de080e7          	jalr	1502(ra) # 80000b5a <initlock>
}
    80004584:	60a2                	ld	ra,8(sp)
    80004586:	6402                	ld	s0,0(sp)
    80004588:	0141                	addi	sp,sp,16
    8000458a:	8082                	ret

000000008000458c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000458c:	1101                	addi	sp,sp,-32
    8000458e:	ec06                	sd	ra,24(sp)
    80004590:	e822                	sd	s0,16(sp)
    80004592:	e426                	sd	s1,8(sp)
    80004594:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004596:	0001d517          	auipc	a0,0x1d
    8000459a:	2a250513          	addi	a0,a0,674 # 80021838 <ftable>
    8000459e:	ffffc097          	auipc	ra,0xffffc
    800045a2:	64c080e7          	jalr	1612(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045a6:	0001d497          	auipc	s1,0x1d
    800045aa:	2aa48493          	addi	s1,s1,682 # 80021850 <ftable+0x18>
    800045ae:	0001e717          	auipc	a4,0x1e
    800045b2:	24270713          	addi	a4,a4,578 # 800227f0 <disk>
    if(f->ref == 0){
    800045b6:	40dc                	lw	a5,4(s1)
    800045b8:	cf99                	beqz	a5,800045d6 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045ba:	02848493          	addi	s1,s1,40
    800045be:	fee49ce3          	bne	s1,a4,800045b6 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045c2:	0001d517          	auipc	a0,0x1d
    800045c6:	27650513          	addi	a0,a0,630 # 80021838 <ftable>
    800045ca:	ffffc097          	auipc	ra,0xffffc
    800045ce:	6d4080e7          	jalr	1748(ra) # 80000c9e <release>
  return 0;
    800045d2:	4481                	li	s1,0
    800045d4:	a819                	j	800045ea <filealloc+0x5e>
      f->ref = 1;
    800045d6:	4785                	li	a5,1
    800045d8:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045da:	0001d517          	auipc	a0,0x1d
    800045de:	25e50513          	addi	a0,a0,606 # 80021838 <ftable>
    800045e2:	ffffc097          	auipc	ra,0xffffc
    800045e6:	6bc080e7          	jalr	1724(ra) # 80000c9e <release>
}
    800045ea:	8526                	mv	a0,s1
    800045ec:	60e2                	ld	ra,24(sp)
    800045ee:	6442                	ld	s0,16(sp)
    800045f0:	64a2                	ld	s1,8(sp)
    800045f2:	6105                	addi	sp,sp,32
    800045f4:	8082                	ret

00000000800045f6 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045f6:	1101                	addi	sp,sp,-32
    800045f8:	ec06                	sd	ra,24(sp)
    800045fa:	e822                	sd	s0,16(sp)
    800045fc:	e426                	sd	s1,8(sp)
    800045fe:	1000                	addi	s0,sp,32
    80004600:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004602:	0001d517          	auipc	a0,0x1d
    80004606:	23650513          	addi	a0,a0,566 # 80021838 <ftable>
    8000460a:	ffffc097          	auipc	ra,0xffffc
    8000460e:	5e0080e7          	jalr	1504(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004612:	40dc                	lw	a5,4(s1)
    80004614:	02f05263          	blez	a5,80004638 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004618:	2785                	addiw	a5,a5,1
    8000461a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000461c:	0001d517          	auipc	a0,0x1d
    80004620:	21c50513          	addi	a0,a0,540 # 80021838 <ftable>
    80004624:	ffffc097          	auipc	ra,0xffffc
    80004628:	67a080e7          	jalr	1658(ra) # 80000c9e <release>
  return f;
}
    8000462c:	8526                	mv	a0,s1
    8000462e:	60e2                	ld	ra,24(sp)
    80004630:	6442                	ld	s0,16(sp)
    80004632:	64a2                	ld	s1,8(sp)
    80004634:	6105                	addi	sp,sp,32
    80004636:	8082                	ret
    panic("filedup");
    80004638:	00004517          	auipc	a0,0x4
    8000463c:	15850513          	addi	a0,a0,344 # 80008790 <syscalls+0x260>
    80004640:	ffffc097          	auipc	ra,0xffffc
    80004644:	f04080e7          	jalr	-252(ra) # 80000544 <panic>

0000000080004648 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004648:	7139                	addi	sp,sp,-64
    8000464a:	fc06                	sd	ra,56(sp)
    8000464c:	f822                	sd	s0,48(sp)
    8000464e:	f426                	sd	s1,40(sp)
    80004650:	f04a                	sd	s2,32(sp)
    80004652:	ec4e                	sd	s3,24(sp)
    80004654:	e852                	sd	s4,16(sp)
    80004656:	e456                	sd	s5,8(sp)
    80004658:	0080                	addi	s0,sp,64
    8000465a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000465c:	0001d517          	auipc	a0,0x1d
    80004660:	1dc50513          	addi	a0,a0,476 # 80021838 <ftable>
    80004664:	ffffc097          	auipc	ra,0xffffc
    80004668:	586080e7          	jalr	1414(ra) # 80000bea <acquire>
  if(f->ref < 1)
    8000466c:	40dc                	lw	a5,4(s1)
    8000466e:	06f05163          	blez	a5,800046d0 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004672:	37fd                	addiw	a5,a5,-1
    80004674:	0007871b          	sext.w	a4,a5
    80004678:	c0dc                	sw	a5,4(s1)
    8000467a:	06e04363          	bgtz	a4,800046e0 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000467e:	0004a903          	lw	s2,0(s1)
    80004682:	0094ca83          	lbu	s5,9(s1)
    80004686:	0104ba03          	ld	s4,16(s1)
    8000468a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000468e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004692:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004696:	0001d517          	auipc	a0,0x1d
    8000469a:	1a250513          	addi	a0,a0,418 # 80021838 <ftable>
    8000469e:	ffffc097          	auipc	ra,0xffffc
    800046a2:	600080e7          	jalr	1536(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    800046a6:	4785                	li	a5,1
    800046a8:	04f90d63          	beq	s2,a5,80004702 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046ac:	3979                	addiw	s2,s2,-2
    800046ae:	4785                	li	a5,1
    800046b0:	0527e063          	bltu	a5,s2,800046f0 <fileclose+0xa8>
    begin_op();
    800046b4:	00000097          	auipc	ra,0x0
    800046b8:	ac8080e7          	jalr	-1336(ra) # 8000417c <begin_op>
    iput(ff.ip);
    800046bc:	854e                	mv	a0,s3
    800046be:	fffff097          	auipc	ra,0xfffff
    800046c2:	2b6080e7          	jalr	694(ra) # 80003974 <iput>
    end_op();
    800046c6:	00000097          	auipc	ra,0x0
    800046ca:	b36080e7          	jalr	-1226(ra) # 800041fc <end_op>
    800046ce:	a00d                	j	800046f0 <fileclose+0xa8>
    panic("fileclose");
    800046d0:	00004517          	auipc	a0,0x4
    800046d4:	0c850513          	addi	a0,a0,200 # 80008798 <syscalls+0x268>
    800046d8:	ffffc097          	auipc	ra,0xffffc
    800046dc:	e6c080e7          	jalr	-404(ra) # 80000544 <panic>
    release(&ftable.lock);
    800046e0:	0001d517          	auipc	a0,0x1d
    800046e4:	15850513          	addi	a0,a0,344 # 80021838 <ftable>
    800046e8:	ffffc097          	auipc	ra,0xffffc
    800046ec:	5b6080e7          	jalr	1462(ra) # 80000c9e <release>
  }
}
    800046f0:	70e2                	ld	ra,56(sp)
    800046f2:	7442                	ld	s0,48(sp)
    800046f4:	74a2                	ld	s1,40(sp)
    800046f6:	7902                	ld	s2,32(sp)
    800046f8:	69e2                	ld	s3,24(sp)
    800046fa:	6a42                	ld	s4,16(sp)
    800046fc:	6aa2                	ld	s5,8(sp)
    800046fe:	6121                	addi	sp,sp,64
    80004700:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004702:	85d6                	mv	a1,s5
    80004704:	8552                	mv	a0,s4
    80004706:	00000097          	auipc	ra,0x0
    8000470a:	34c080e7          	jalr	844(ra) # 80004a52 <pipeclose>
    8000470e:	b7cd                	j	800046f0 <fileclose+0xa8>

0000000080004710 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004710:	715d                	addi	sp,sp,-80
    80004712:	e486                	sd	ra,72(sp)
    80004714:	e0a2                	sd	s0,64(sp)
    80004716:	fc26                	sd	s1,56(sp)
    80004718:	f84a                	sd	s2,48(sp)
    8000471a:	f44e                	sd	s3,40(sp)
    8000471c:	0880                	addi	s0,sp,80
    8000471e:	84aa                	mv	s1,a0
    80004720:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004722:	ffffd097          	auipc	ra,0xffffd
    80004726:	2a4080e7          	jalr	676(ra) # 800019c6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000472a:	409c                	lw	a5,0(s1)
    8000472c:	37f9                	addiw	a5,a5,-2
    8000472e:	4705                	li	a4,1
    80004730:	04f76763          	bltu	a4,a5,8000477e <filestat+0x6e>
    80004734:	892a                	mv	s2,a0
    ilock(f->ip);
    80004736:	6c88                	ld	a0,24(s1)
    80004738:	fffff097          	auipc	ra,0xfffff
    8000473c:	082080e7          	jalr	130(ra) # 800037ba <ilock>
    stati(f->ip, &st);
    80004740:	fb840593          	addi	a1,s0,-72
    80004744:	6c88                	ld	a0,24(s1)
    80004746:	fffff097          	auipc	ra,0xfffff
    8000474a:	2fe080e7          	jalr	766(ra) # 80003a44 <stati>
    iunlock(f->ip);
    8000474e:	6c88                	ld	a0,24(s1)
    80004750:	fffff097          	auipc	ra,0xfffff
    80004754:	12c080e7          	jalr	300(ra) # 8000387c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004758:	46e1                	li	a3,24
    8000475a:	fb840613          	addi	a2,s0,-72
    8000475e:	85ce                	mv	a1,s3
    80004760:	05093503          	ld	a0,80(s2)
    80004764:	ffffd097          	auipc	ra,0xffffd
    80004768:	f20080e7          	jalr	-224(ra) # 80001684 <copyout>
    8000476c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004770:	60a6                	ld	ra,72(sp)
    80004772:	6406                	ld	s0,64(sp)
    80004774:	74e2                	ld	s1,56(sp)
    80004776:	7942                	ld	s2,48(sp)
    80004778:	79a2                	ld	s3,40(sp)
    8000477a:	6161                	addi	sp,sp,80
    8000477c:	8082                	ret
  return -1;
    8000477e:	557d                	li	a0,-1
    80004780:	bfc5                	j	80004770 <filestat+0x60>

0000000080004782 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004782:	7179                	addi	sp,sp,-48
    80004784:	f406                	sd	ra,40(sp)
    80004786:	f022                	sd	s0,32(sp)
    80004788:	ec26                	sd	s1,24(sp)
    8000478a:	e84a                	sd	s2,16(sp)
    8000478c:	e44e                	sd	s3,8(sp)
    8000478e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004790:	00854783          	lbu	a5,8(a0)
    80004794:	c3d5                	beqz	a5,80004838 <fileread+0xb6>
    80004796:	84aa                	mv	s1,a0
    80004798:	89ae                	mv	s3,a1
    8000479a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000479c:	411c                	lw	a5,0(a0)
    8000479e:	4705                	li	a4,1
    800047a0:	04e78963          	beq	a5,a4,800047f2 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047a4:	470d                	li	a4,3
    800047a6:	04e78d63          	beq	a5,a4,80004800 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047aa:	4709                	li	a4,2
    800047ac:	06e79e63          	bne	a5,a4,80004828 <fileread+0xa6>
    ilock(f->ip);
    800047b0:	6d08                	ld	a0,24(a0)
    800047b2:	fffff097          	auipc	ra,0xfffff
    800047b6:	008080e7          	jalr	8(ra) # 800037ba <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047ba:	874a                	mv	a4,s2
    800047bc:	5094                	lw	a3,32(s1)
    800047be:	864e                	mv	a2,s3
    800047c0:	4585                	li	a1,1
    800047c2:	6c88                	ld	a0,24(s1)
    800047c4:	fffff097          	auipc	ra,0xfffff
    800047c8:	2aa080e7          	jalr	682(ra) # 80003a6e <readi>
    800047cc:	892a                	mv	s2,a0
    800047ce:	00a05563          	blez	a0,800047d8 <fileread+0x56>
      f->off += r;
    800047d2:	509c                	lw	a5,32(s1)
    800047d4:	9fa9                	addw	a5,a5,a0
    800047d6:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047d8:	6c88                	ld	a0,24(s1)
    800047da:	fffff097          	auipc	ra,0xfffff
    800047de:	0a2080e7          	jalr	162(ra) # 8000387c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047e2:	854a                	mv	a0,s2
    800047e4:	70a2                	ld	ra,40(sp)
    800047e6:	7402                	ld	s0,32(sp)
    800047e8:	64e2                	ld	s1,24(sp)
    800047ea:	6942                	ld	s2,16(sp)
    800047ec:	69a2                	ld	s3,8(sp)
    800047ee:	6145                	addi	sp,sp,48
    800047f0:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047f2:	6908                	ld	a0,16(a0)
    800047f4:	00000097          	auipc	ra,0x0
    800047f8:	3ce080e7          	jalr	974(ra) # 80004bc2 <piperead>
    800047fc:	892a                	mv	s2,a0
    800047fe:	b7d5                	j	800047e2 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004800:	02451783          	lh	a5,36(a0)
    80004804:	03079693          	slli	a3,a5,0x30
    80004808:	92c1                	srli	a3,a3,0x30
    8000480a:	4725                	li	a4,9
    8000480c:	02d76863          	bltu	a4,a3,8000483c <fileread+0xba>
    80004810:	0792                	slli	a5,a5,0x4
    80004812:	0001d717          	auipc	a4,0x1d
    80004816:	f8670713          	addi	a4,a4,-122 # 80021798 <devsw>
    8000481a:	97ba                	add	a5,a5,a4
    8000481c:	639c                	ld	a5,0(a5)
    8000481e:	c38d                	beqz	a5,80004840 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004820:	4505                	li	a0,1
    80004822:	9782                	jalr	a5
    80004824:	892a                	mv	s2,a0
    80004826:	bf75                	j	800047e2 <fileread+0x60>
    panic("fileread");
    80004828:	00004517          	auipc	a0,0x4
    8000482c:	f8050513          	addi	a0,a0,-128 # 800087a8 <syscalls+0x278>
    80004830:	ffffc097          	auipc	ra,0xffffc
    80004834:	d14080e7          	jalr	-748(ra) # 80000544 <panic>
    return -1;
    80004838:	597d                	li	s2,-1
    8000483a:	b765                	j	800047e2 <fileread+0x60>
      return -1;
    8000483c:	597d                	li	s2,-1
    8000483e:	b755                	j	800047e2 <fileread+0x60>
    80004840:	597d                	li	s2,-1
    80004842:	b745                	j	800047e2 <fileread+0x60>

0000000080004844 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004844:	715d                	addi	sp,sp,-80
    80004846:	e486                	sd	ra,72(sp)
    80004848:	e0a2                	sd	s0,64(sp)
    8000484a:	fc26                	sd	s1,56(sp)
    8000484c:	f84a                	sd	s2,48(sp)
    8000484e:	f44e                	sd	s3,40(sp)
    80004850:	f052                	sd	s4,32(sp)
    80004852:	ec56                	sd	s5,24(sp)
    80004854:	e85a                	sd	s6,16(sp)
    80004856:	e45e                	sd	s7,8(sp)
    80004858:	e062                	sd	s8,0(sp)
    8000485a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000485c:	00954783          	lbu	a5,9(a0)
    80004860:	10078663          	beqz	a5,8000496c <filewrite+0x128>
    80004864:	892a                	mv	s2,a0
    80004866:	8aae                	mv	s5,a1
    80004868:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000486a:	411c                	lw	a5,0(a0)
    8000486c:	4705                	li	a4,1
    8000486e:	02e78263          	beq	a5,a4,80004892 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004872:	470d                	li	a4,3
    80004874:	02e78663          	beq	a5,a4,800048a0 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004878:	4709                	li	a4,2
    8000487a:	0ee79163          	bne	a5,a4,8000495c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000487e:	0ac05d63          	blez	a2,80004938 <filewrite+0xf4>
    int i = 0;
    80004882:	4981                	li	s3,0
    80004884:	6b05                	lui	s6,0x1
    80004886:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000488a:	6b85                	lui	s7,0x1
    8000488c:	c00b8b9b          	addiw	s7,s7,-1024
    80004890:	a861                	j	80004928 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004892:	6908                	ld	a0,16(a0)
    80004894:	00000097          	auipc	ra,0x0
    80004898:	22e080e7          	jalr	558(ra) # 80004ac2 <pipewrite>
    8000489c:	8a2a                	mv	s4,a0
    8000489e:	a045                	j	8000493e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048a0:	02451783          	lh	a5,36(a0)
    800048a4:	03079693          	slli	a3,a5,0x30
    800048a8:	92c1                	srli	a3,a3,0x30
    800048aa:	4725                	li	a4,9
    800048ac:	0cd76263          	bltu	a4,a3,80004970 <filewrite+0x12c>
    800048b0:	0792                	slli	a5,a5,0x4
    800048b2:	0001d717          	auipc	a4,0x1d
    800048b6:	ee670713          	addi	a4,a4,-282 # 80021798 <devsw>
    800048ba:	97ba                	add	a5,a5,a4
    800048bc:	679c                	ld	a5,8(a5)
    800048be:	cbdd                	beqz	a5,80004974 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800048c0:	4505                	li	a0,1
    800048c2:	9782                	jalr	a5
    800048c4:	8a2a                	mv	s4,a0
    800048c6:	a8a5                	j	8000493e <filewrite+0xfa>
    800048c8:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048cc:	00000097          	auipc	ra,0x0
    800048d0:	8b0080e7          	jalr	-1872(ra) # 8000417c <begin_op>
      ilock(f->ip);
    800048d4:	01893503          	ld	a0,24(s2)
    800048d8:	fffff097          	auipc	ra,0xfffff
    800048dc:	ee2080e7          	jalr	-286(ra) # 800037ba <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048e0:	8762                	mv	a4,s8
    800048e2:	02092683          	lw	a3,32(s2)
    800048e6:	01598633          	add	a2,s3,s5
    800048ea:	4585                	li	a1,1
    800048ec:	01893503          	ld	a0,24(s2)
    800048f0:	fffff097          	auipc	ra,0xfffff
    800048f4:	276080e7          	jalr	630(ra) # 80003b66 <writei>
    800048f8:	84aa                	mv	s1,a0
    800048fa:	00a05763          	blez	a0,80004908 <filewrite+0xc4>
        f->off += r;
    800048fe:	02092783          	lw	a5,32(s2)
    80004902:	9fa9                	addw	a5,a5,a0
    80004904:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004908:	01893503          	ld	a0,24(s2)
    8000490c:	fffff097          	auipc	ra,0xfffff
    80004910:	f70080e7          	jalr	-144(ra) # 8000387c <iunlock>
      end_op();
    80004914:	00000097          	auipc	ra,0x0
    80004918:	8e8080e7          	jalr	-1816(ra) # 800041fc <end_op>

      if(r != n1){
    8000491c:	009c1f63          	bne	s8,s1,8000493a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004920:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004924:	0149db63          	bge	s3,s4,8000493a <filewrite+0xf6>
      int n1 = n - i;
    80004928:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000492c:	84be                	mv	s1,a5
    8000492e:	2781                	sext.w	a5,a5
    80004930:	f8fb5ce3          	bge	s6,a5,800048c8 <filewrite+0x84>
    80004934:	84de                	mv	s1,s7
    80004936:	bf49                	j	800048c8 <filewrite+0x84>
    int i = 0;
    80004938:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000493a:	013a1f63          	bne	s4,s3,80004958 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000493e:	8552                	mv	a0,s4
    80004940:	60a6                	ld	ra,72(sp)
    80004942:	6406                	ld	s0,64(sp)
    80004944:	74e2                	ld	s1,56(sp)
    80004946:	7942                	ld	s2,48(sp)
    80004948:	79a2                	ld	s3,40(sp)
    8000494a:	7a02                	ld	s4,32(sp)
    8000494c:	6ae2                	ld	s5,24(sp)
    8000494e:	6b42                	ld	s6,16(sp)
    80004950:	6ba2                	ld	s7,8(sp)
    80004952:	6c02                	ld	s8,0(sp)
    80004954:	6161                	addi	sp,sp,80
    80004956:	8082                	ret
    ret = (i == n ? n : -1);
    80004958:	5a7d                	li	s4,-1
    8000495a:	b7d5                	j	8000493e <filewrite+0xfa>
    panic("filewrite");
    8000495c:	00004517          	auipc	a0,0x4
    80004960:	e5c50513          	addi	a0,a0,-420 # 800087b8 <syscalls+0x288>
    80004964:	ffffc097          	auipc	ra,0xffffc
    80004968:	be0080e7          	jalr	-1056(ra) # 80000544 <panic>
    return -1;
    8000496c:	5a7d                	li	s4,-1
    8000496e:	bfc1                	j	8000493e <filewrite+0xfa>
      return -1;
    80004970:	5a7d                	li	s4,-1
    80004972:	b7f1                	j	8000493e <filewrite+0xfa>
    80004974:	5a7d                	li	s4,-1
    80004976:	b7e1                	j	8000493e <filewrite+0xfa>

0000000080004978 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004978:	7179                	addi	sp,sp,-48
    8000497a:	f406                	sd	ra,40(sp)
    8000497c:	f022                	sd	s0,32(sp)
    8000497e:	ec26                	sd	s1,24(sp)
    80004980:	e84a                	sd	s2,16(sp)
    80004982:	e44e                	sd	s3,8(sp)
    80004984:	e052                	sd	s4,0(sp)
    80004986:	1800                	addi	s0,sp,48
    80004988:	84aa                	mv	s1,a0
    8000498a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000498c:	0005b023          	sd	zero,0(a1)
    80004990:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004994:	00000097          	auipc	ra,0x0
    80004998:	bf8080e7          	jalr	-1032(ra) # 8000458c <filealloc>
    8000499c:	e088                	sd	a0,0(s1)
    8000499e:	c551                	beqz	a0,80004a2a <pipealloc+0xb2>
    800049a0:	00000097          	auipc	ra,0x0
    800049a4:	bec080e7          	jalr	-1044(ra) # 8000458c <filealloc>
    800049a8:	00aa3023          	sd	a0,0(s4)
    800049ac:	c92d                	beqz	a0,80004a1e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049ae:	ffffc097          	auipc	ra,0xffffc
    800049b2:	14c080e7          	jalr	332(ra) # 80000afa <kalloc>
    800049b6:	892a                	mv	s2,a0
    800049b8:	c125                	beqz	a0,80004a18 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049ba:	4985                	li	s3,1
    800049bc:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049c0:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049c4:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049c8:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049cc:	00004597          	auipc	a1,0x4
    800049d0:	a9c58593          	addi	a1,a1,-1380 # 80008468 <states.1728+0x1a0>
    800049d4:	ffffc097          	auipc	ra,0xffffc
    800049d8:	186080e7          	jalr	390(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    800049dc:	609c                	ld	a5,0(s1)
    800049de:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049e2:	609c                	ld	a5,0(s1)
    800049e4:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049e8:	609c                	ld	a5,0(s1)
    800049ea:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049ee:	609c                	ld	a5,0(s1)
    800049f0:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049f4:	000a3783          	ld	a5,0(s4)
    800049f8:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049fc:	000a3783          	ld	a5,0(s4)
    80004a00:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a04:	000a3783          	ld	a5,0(s4)
    80004a08:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a0c:	000a3783          	ld	a5,0(s4)
    80004a10:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a14:	4501                	li	a0,0
    80004a16:	a025                	j	80004a3e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a18:	6088                	ld	a0,0(s1)
    80004a1a:	e501                	bnez	a0,80004a22 <pipealloc+0xaa>
    80004a1c:	a039                	j	80004a2a <pipealloc+0xb2>
    80004a1e:	6088                	ld	a0,0(s1)
    80004a20:	c51d                	beqz	a0,80004a4e <pipealloc+0xd6>
    fileclose(*f0);
    80004a22:	00000097          	auipc	ra,0x0
    80004a26:	c26080e7          	jalr	-986(ra) # 80004648 <fileclose>
  if(*f1)
    80004a2a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a2e:	557d                	li	a0,-1
  if(*f1)
    80004a30:	c799                	beqz	a5,80004a3e <pipealloc+0xc6>
    fileclose(*f1);
    80004a32:	853e                	mv	a0,a5
    80004a34:	00000097          	auipc	ra,0x0
    80004a38:	c14080e7          	jalr	-1004(ra) # 80004648 <fileclose>
  return -1;
    80004a3c:	557d                	li	a0,-1
}
    80004a3e:	70a2                	ld	ra,40(sp)
    80004a40:	7402                	ld	s0,32(sp)
    80004a42:	64e2                	ld	s1,24(sp)
    80004a44:	6942                	ld	s2,16(sp)
    80004a46:	69a2                	ld	s3,8(sp)
    80004a48:	6a02                	ld	s4,0(sp)
    80004a4a:	6145                	addi	sp,sp,48
    80004a4c:	8082                	ret
  return -1;
    80004a4e:	557d                	li	a0,-1
    80004a50:	b7fd                	j	80004a3e <pipealloc+0xc6>

0000000080004a52 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a52:	1101                	addi	sp,sp,-32
    80004a54:	ec06                	sd	ra,24(sp)
    80004a56:	e822                	sd	s0,16(sp)
    80004a58:	e426                	sd	s1,8(sp)
    80004a5a:	e04a                	sd	s2,0(sp)
    80004a5c:	1000                	addi	s0,sp,32
    80004a5e:	84aa                	mv	s1,a0
    80004a60:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a62:	ffffc097          	auipc	ra,0xffffc
    80004a66:	188080e7          	jalr	392(ra) # 80000bea <acquire>
  if(writable){
    80004a6a:	02090d63          	beqz	s2,80004aa4 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a6e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a72:	21848513          	addi	a0,s1,536
    80004a76:	ffffd097          	auipc	ra,0xffffd
    80004a7a:	66c080e7          	jalr	1644(ra) # 800020e2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a7e:	2204b783          	ld	a5,544(s1)
    80004a82:	eb95                	bnez	a5,80004ab6 <pipeclose+0x64>
    release(&pi->lock);
    80004a84:	8526                	mv	a0,s1
    80004a86:	ffffc097          	auipc	ra,0xffffc
    80004a8a:	218080e7          	jalr	536(ra) # 80000c9e <release>
    kfree((char*)pi);
    80004a8e:	8526                	mv	a0,s1
    80004a90:	ffffc097          	auipc	ra,0xffffc
    80004a94:	f6e080e7          	jalr	-146(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80004a98:	60e2                	ld	ra,24(sp)
    80004a9a:	6442                	ld	s0,16(sp)
    80004a9c:	64a2                	ld	s1,8(sp)
    80004a9e:	6902                	ld	s2,0(sp)
    80004aa0:	6105                	addi	sp,sp,32
    80004aa2:	8082                	ret
    pi->readopen = 0;
    80004aa4:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004aa8:	21c48513          	addi	a0,s1,540
    80004aac:	ffffd097          	auipc	ra,0xffffd
    80004ab0:	636080e7          	jalr	1590(ra) # 800020e2 <wakeup>
    80004ab4:	b7e9                	j	80004a7e <pipeclose+0x2c>
    release(&pi->lock);
    80004ab6:	8526                	mv	a0,s1
    80004ab8:	ffffc097          	auipc	ra,0xffffc
    80004abc:	1e6080e7          	jalr	486(ra) # 80000c9e <release>
}
    80004ac0:	bfe1                	j	80004a98 <pipeclose+0x46>

0000000080004ac2 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ac2:	7159                	addi	sp,sp,-112
    80004ac4:	f486                	sd	ra,104(sp)
    80004ac6:	f0a2                	sd	s0,96(sp)
    80004ac8:	eca6                	sd	s1,88(sp)
    80004aca:	e8ca                	sd	s2,80(sp)
    80004acc:	e4ce                	sd	s3,72(sp)
    80004ace:	e0d2                	sd	s4,64(sp)
    80004ad0:	fc56                	sd	s5,56(sp)
    80004ad2:	f85a                	sd	s6,48(sp)
    80004ad4:	f45e                	sd	s7,40(sp)
    80004ad6:	f062                	sd	s8,32(sp)
    80004ad8:	ec66                	sd	s9,24(sp)
    80004ada:	1880                	addi	s0,sp,112
    80004adc:	84aa                	mv	s1,a0
    80004ade:	8aae                	mv	s5,a1
    80004ae0:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ae2:	ffffd097          	auipc	ra,0xffffd
    80004ae6:	ee4080e7          	jalr	-284(ra) # 800019c6 <myproc>
    80004aea:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004aec:	8526                	mv	a0,s1
    80004aee:	ffffc097          	auipc	ra,0xffffc
    80004af2:	0fc080e7          	jalr	252(ra) # 80000bea <acquire>
  while(i < n){
    80004af6:	0d405463          	blez	s4,80004bbe <pipewrite+0xfc>
    80004afa:	8ba6                	mv	s7,s1
  int i = 0;
    80004afc:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004afe:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b00:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b04:	21c48c13          	addi	s8,s1,540
    80004b08:	a08d                	j	80004b6a <pipewrite+0xa8>
      release(&pi->lock);
    80004b0a:	8526                	mv	a0,s1
    80004b0c:	ffffc097          	auipc	ra,0xffffc
    80004b10:	192080e7          	jalr	402(ra) # 80000c9e <release>
      return -1;
    80004b14:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b16:	854a                	mv	a0,s2
    80004b18:	70a6                	ld	ra,104(sp)
    80004b1a:	7406                	ld	s0,96(sp)
    80004b1c:	64e6                	ld	s1,88(sp)
    80004b1e:	6946                	ld	s2,80(sp)
    80004b20:	69a6                	ld	s3,72(sp)
    80004b22:	6a06                	ld	s4,64(sp)
    80004b24:	7ae2                	ld	s5,56(sp)
    80004b26:	7b42                	ld	s6,48(sp)
    80004b28:	7ba2                	ld	s7,40(sp)
    80004b2a:	7c02                	ld	s8,32(sp)
    80004b2c:	6ce2                	ld	s9,24(sp)
    80004b2e:	6165                	addi	sp,sp,112
    80004b30:	8082                	ret
      wakeup(&pi->nread);
    80004b32:	8566                	mv	a0,s9
    80004b34:	ffffd097          	auipc	ra,0xffffd
    80004b38:	5ae080e7          	jalr	1454(ra) # 800020e2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b3c:	85de                	mv	a1,s7
    80004b3e:	8562                	mv	a0,s8
    80004b40:	ffffd097          	auipc	ra,0xffffd
    80004b44:	53e080e7          	jalr	1342(ra) # 8000207e <sleep>
    80004b48:	a839                	j	80004b66 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b4a:	21c4a783          	lw	a5,540(s1)
    80004b4e:	0017871b          	addiw	a4,a5,1
    80004b52:	20e4ae23          	sw	a4,540(s1)
    80004b56:	1ff7f793          	andi	a5,a5,511
    80004b5a:	97a6                	add	a5,a5,s1
    80004b5c:	f9f44703          	lbu	a4,-97(s0)
    80004b60:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b64:	2905                	addiw	s2,s2,1
  while(i < n){
    80004b66:	05495063          	bge	s2,s4,80004ba6 <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80004b6a:	2204a783          	lw	a5,544(s1)
    80004b6e:	dfd1                	beqz	a5,80004b0a <pipewrite+0x48>
    80004b70:	854e                	mv	a0,s3
    80004b72:	ffffd097          	auipc	ra,0xffffd
    80004b76:	7b4080e7          	jalr	1972(ra) # 80002326 <killed>
    80004b7a:	f941                	bnez	a0,80004b0a <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b7c:	2184a783          	lw	a5,536(s1)
    80004b80:	21c4a703          	lw	a4,540(s1)
    80004b84:	2007879b          	addiw	a5,a5,512
    80004b88:	faf705e3          	beq	a4,a5,80004b32 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b8c:	4685                	li	a3,1
    80004b8e:	01590633          	add	a2,s2,s5
    80004b92:	f9f40593          	addi	a1,s0,-97
    80004b96:	0509b503          	ld	a0,80(s3)
    80004b9a:	ffffd097          	auipc	ra,0xffffd
    80004b9e:	b76080e7          	jalr	-1162(ra) # 80001710 <copyin>
    80004ba2:	fb6514e3          	bne	a0,s6,80004b4a <pipewrite+0x88>
  wakeup(&pi->nread);
    80004ba6:	21848513          	addi	a0,s1,536
    80004baa:	ffffd097          	auipc	ra,0xffffd
    80004bae:	538080e7          	jalr	1336(ra) # 800020e2 <wakeup>
  release(&pi->lock);
    80004bb2:	8526                	mv	a0,s1
    80004bb4:	ffffc097          	auipc	ra,0xffffc
    80004bb8:	0ea080e7          	jalr	234(ra) # 80000c9e <release>
  return i;
    80004bbc:	bfa9                	j	80004b16 <pipewrite+0x54>
  int i = 0;
    80004bbe:	4901                	li	s2,0
    80004bc0:	b7dd                	j	80004ba6 <pipewrite+0xe4>

0000000080004bc2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bc2:	715d                	addi	sp,sp,-80
    80004bc4:	e486                	sd	ra,72(sp)
    80004bc6:	e0a2                	sd	s0,64(sp)
    80004bc8:	fc26                	sd	s1,56(sp)
    80004bca:	f84a                	sd	s2,48(sp)
    80004bcc:	f44e                	sd	s3,40(sp)
    80004bce:	f052                	sd	s4,32(sp)
    80004bd0:	ec56                	sd	s5,24(sp)
    80004bd2:	e85a                	sd	s6,16(sp)
    80004bd4:	0880                	addi	s0,sp,80
    80004bd6:	84aa                	mv	s1,a0
    80004bd8:	892e                	mv	s2,a1
    80004bda:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bdc:	ffffd097          	auipc	ra,0xffffd
    80004be0:	dea080e7          	jalr	-534(ra) # 800019c6 <myproc>
    80004be4:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004be6:	8b26                	mv	s6,s1
    80004be8:	8526                	mv	a0,s1
    80004bea:	ffffc097          	auipc	ra,0xffffc
    80004bee:	000080e7          	jalr	ra # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bf2:	2184a703          	lw	a4,536(s1)
    80004bf6:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bfa:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bfe:	02f71763          	bne	a4,a5,80004c2c <piperead+0x6a>
    80004c02:	2244a783          	lw	a5,548(s1)
    80004c06:	c39d                	beqz	a5,80004c2c <piperead+0x6a>
    if(killed(pr)){
    80004c08:	8552                	mv	a0,s4
    80004c0a:	ffffd097          	auipc	ra,0xffffd
    80004c0e:	71c080e7          	jalr	1820(ra) # 80002326 <killed>
    80004c12:	e941                	bnez	a0,80004ca2 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c14:	85da                	mv	a1,s6
    80004c16:	854e                	mv	a0,s3
    80004c18:	ffffd097          	auipc	ra,0xffffd
    80004c1c:	466080e7          	jalr	1126(ra) # 8000207e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c20:	2184a703          	lw	a4,536(s1)
    80004c24:	21c4a783          	lw	a5,540(s1)
    80004c28:	fcf70de3          	beq	a4,a5,80004c02 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c2c:	09505263          	blez	s5,80004cb0 <piperead+0xee>
    80004c30:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c32:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c34:	2184a783          	lw	a5,536(s1)
    80004c38:	21c4a703          	lw	a4,540(s1)
    80004c3c:	02f70d63          	beq	a4,a5,80004c76 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c40:	0017871b          	addiw	a4,a5,1
    80004c44:	20e4ac23          	sw	a4,536(s1)
    80004c48:	1ff7f793          	andi	a5,a5,511
    80004c4c:	97a6                	add	a5,a5,s1
    80004c4e:	0187c783          	lbu	a5,24(a5)
    80004c52:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c56:	4685                	li	a3,1
    80004c58:	fbf40613          	addi	a2,s0,-65
    80004c5c:	85ca                	mv	a1,s2
    80004c5e:	050a3503          	ld	a0,80(s4)
    80004c62:	ffffd097          	auipc	ra,0xffffd
    80004c66:	a22080e7          	jalr	-1502(ra) # 80001684 <copyout>
    80004c6a:	01650663          	beq	a0,s6,80004c76 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c6e:	2985                	addiw	s3,s3,1
    80004c70:	0905                	addi	s2,s2,1
    80004c72:	fd3a91e3          	bne	s5,s3,80004c34 <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c76:	21c48513          	addi	a0,s1,540
    80004c7a:	ffffd097          	auipc	ra,0xffffd
    80004c7e:	468080e7          	jalr	1128(ra) # 800020e2 <wakeup>
  release(&pi->lock);
    80004c82:	8526                	mv	a0,s1
    80004c84:	ffffc097          	auipc	ra,0xffffc
    80004c88:	01a080e7          	jalr	26(ra) # 80000c9e <release>
  return i;
}
    80004c8c:	854e                	mv	a0,s3
    80004c8e:	60a6                	ld	ra,72(sp)
    80004c90:	6406                	ld	s0,64(sp)
    80004c92:	74e2                	ld	s1,56(sp)
    80004c94:	7942                	ld	s2,48(sp)
    80004c96:	79a2                	ld	s3,40(sp)
    80004c98:	7a02                	ld	s4,32(sp)
    80004c9a:	6ae2                	ld	s5,24(sp)
    80004c9c:	6b42                	ld	s6,16(sp)
    80004c9e:	6161                	addi	sp,sp,80
    80004ca0:	8082                	ret
      release(&pi->lock);
    80004ca2:	8526                	mv	a0,s1
    80004ca4:	ffffc097          	auipc	ra,0xffffc
    80004ca8:	ffa080e7          	jalr	-6(ra) # 80000c9e <release>
      return -1;
    80004cac:	59fd                	li	s3,-1
    80004cae:	bff9                	j	80004c8c <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cb0:	4981                	li	s3,0
    80004cb2:	b7d1                	j	80004c76 <piperead+0xb4>

0000000080004cb4 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004cb4:	1141                	addi	sp,sp,-16
    80004cb6:	e422                	sd	s0,8(sp)
    80004cb8:	0800                	addi	s0,sp,16
    80004cba:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004cbc:	8905                	andi	a0,a0,1
    80004cbe:	c111                	beqz	a0,80004cc2 <flags2perm+0xe>
      perm = PTE_X;
    80004cc0:	4521                	li	a0,8
    if(flags & 0x2)
    80004cc2:	8b89                	andi	a5,a5,2
    80004cc4:	c399                	beqz	a5,80004cca <flags2perm+0x16>
      perm |= PTE_W;
    80004cc6:	00456513          	ori	a0,a0,4
    return perm;
}
    80004cca:	6422                	ld	s0,8(sp)
    80004ccc:	0141                	addi	sp,sp,16
    80004cce:	8082                	ret

0000000080004cd0 <exec>:

int
exec(char *path, char **argv)
{
    80004cd0:	df010113          	addi	sp,sp,-528
    80004cd4:	20113423          	sd	ra,520(sp)
    80004cd8:	20813023          	sd	s0,512(sp)
    80004cdc:	ffa6                	sd	s1,504(sp)
    80004cde:	fbca                	sd	s2,496(sp)
    80004ce0:	f7ce                	sd	s3,488(sp)
    80004ce2:	f3d2                	sd	s4,480(sp)
    80004ce4:	efd6                	sd	s5,472(sp)
    80004ce6:	ebda                	sd	s6,464(sp)
    80004ce8:	e7de                	sd	s7,456(sp)
    80004cea:	e3e2                	sd	s8,448(sp)
    80004cec:	ff66                	sd	s9,440(sp)
    80004cee:	fb6a                	sd	s10,432(sp)
    80004cf0:	f76e                	sd	s11,424(sp)
    80004cf2:	0c00                	addi	s0,sp,528
    80004cf4:	84aa                	mv	s1,a0
    80004cf6:	dea43c23          	sd	a0,-520(s0)
    80004cfa:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cfe:	ffffd097          	auipc	ra,0xffffd
    80004d02:	cc8080e7          	jalr	-824(ra) # 800019c6 <myproc>
    80004d06:	892a                	mv	s2,a0

  begin_op();
    80004d08:	fffff097          	auipc	ra,0xfffff
    80004d0c:	474080e7          	jalr	1140(ra) # 8000417c <begin_op>

  if((ip = namei(path)) == 0){
    80004d10:	8526                	mv	a0,s1
    80004d12:	fffff097          	auipc	ra,0xfffff
    80004d16:	24e080e7          	jalr	590(ra) # 80003f60 <namei>
    80004d1a:	c92d                	beqz	a0,80004d8c <exec+0xbc>
    80004d1c:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d1e:	fffff097          	auipc	ra,0xfffff
    80004d22:	a9c080e7          	jalr	-1380(ra) # 800037ba <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d26:	04000713          	li	a4,64
    80004d2a:	4681                	li	a3,0
    80004d2c:	e5040613          	addi	a2,s0,-432
    80004d30:	4581                	li	a1,0
    80004d32:	8526                	mv	a0,s1
    80004d34:	fffff097          	auipc	ra,0xfffff
    80004d38:	d3a080e7          	jalr	-710(ra) # 80003a6e <readi>
    80004d3c:	04000793          	li	a5,64
    80004d40:	00f51a63          	bne	a0,a5,80004d54 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004d44:	e5042703          	lw	a4,-432(s0)
    80004d48:	464c47b7          	lui	a5,0x464c4
    80004d4c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d50:	04f70463          	beq	a4,a5,80004d98 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d54:	8526                	mv	a0,s1
    80004d56:	fffff097          	auipc	ra,0xfffff
    80004d5a:	cc6080e7          	jalr	-826(ra) # 80003a1c <iunlockput>
    end_op();
    80004d5e:	fffff097          	auipc	ra,0xfffff
    80004d62:	49e080e7          	jalr	1182(ra) # 800041fc <end_op>
  }
  return -1;
    80004d66:	557d                	li	a0,-1
}
    80004d68:	20813083          	ld	ra,520(sp)
    80004d6c:	20013403          	ld	s0,512(sp)
    80004d70:	74fe                	ld	s1,504(sp)
    80004d72:	795e                	ld	s2,496(sp)
    80004d74:	79be                	ld	s3,488(sp)
    80004d76:	7a1e                	ld	s4,480(sp)
    80004d78:	6afe                	ld	s5,472(sp)
    80004d7a:	6b5e                	ld	s6,464(sp)
    80004d7c:	6bbe                	ld	s7,456(sp)
    80004d7e:	6c1e                	ld	s8,448(sp)
    80004d80:	7cfa                	ld	s9,440(sp)
    80004d82:	7d5a                	ld	s10,432(sp)
    80004d84:	7dba                	ld	s11,424(sp)
    80004d86:	21010113          	addi	sp,sp,528
    80004d8a:	8082                	ret
    end_op();
    80004d8c:	fffff097          	auipc	ra,0xfffff
    80004d90:	470080e7          	jalr	1136(ra) # 800041fc <end_op>
    return -1;
    80004d94:	557d                	li	a0,-1
    80004d96:	bfc9                	j	80004d68 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d98:	854a                	mv	a0,s2
    80004d9a:	ffffd097          	auipc	ra,0xffffd
    80004d9e:	cf0080e7          	jalr	-784(ra) # 80001a8a <proc_pagetable>
    80004da2:	8baa                	mv	s7,a0
    80004da4:	d945                	beqz	a0,80004d54 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004da6:	e7042983          	lw	s3,-400(s0)
    80004daa:	e8845783          	lhu	a5,-376(s0)
    80004dae:	c7ad                	beqz	a5,80004e18 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004db0:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004db2:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004db4:	6c85                	lui	s9,0x1
    80004db6:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004dba:	def43823          	sd	a5,-528(s0)
    80004dbe:	ac0d                	j	80004ff0 <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004dc0:	00004517          	auipc	a0,0x4
    80004dc4:	a0850513          	addi	a0,a0,-1528 # 800087c8 <syscalls+0x298>
    80004dc8:	ffffb097          	auipc	ra,0xffffb
    80004dcc:	77c080e7          	jalr	1916(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004dd0:	8756                	mv	a4,s5
    80004dd2:	012d86bb          	addw	a3,s11,s2
    80004dd6:	4581                	li	a1,0
    80004dd8:	8526                	mv	a0,s1
    80004dda:	fffff097          	auipc	ra,0xfffff
    80004dde:	c94080e7          	jalr	-876(ra) # 80003a6e <readi>
    80004de2:	2501                	sext.w	a0,a0
    80004de4:	1aaa9a63          	bne	s5,a0,80004f98 <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    80004de8:	6785                	lui	a5,0x1
    80004dea:	0127893b          	addw	s2,a5,s2
    80004dee:	77fd                	lui	a5,0xfffff
    80004df0:	01478a3b          	addw	s4,a5,s4
    80004df4:	1f897563          	bgeu	s2,s8,80004fde <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    80004df8:	02091593          	slli	a1,s2,0x20
    80004dfc:	9181                	srli	a1,a1,0x20
    80004dfe:	95ea                	add	a1,a1,s10
    80004e00:	855e                	mv	a0,s7
    80004e02:	ffffc097          	auipc	ra,0xffffc
    80004e06:	276080e7          	jalr	630(ra) # 80001078 <walkaddr>
    80004e0a:	862a                	mv	a2,a0
    if(pa == 0)
    80004e0c:	d955                	beqz	a0,80004dc0 <exec+0xf0>
      n = PGSIZE;
    80004e0e:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004e10:	fd9a70e3          	bgeu	s4,s9,80004dd0 <exec+0x100>
      n = sz - i;
    80004e14:	8ad2                	mv	s5,s4
    80004e16:	bf6d                	j	80004dd0 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e18:	4a01                	li	s4,0
  iunlockput(ip);
    80004e1a:	8526                	mv	a0,s1
    80004e1c:	fffff097          	auipc	ra,0xfffff
    80004e20:	c00080e7          	jalr	-1024(ra) # 80003a1c <iunlockput>
  end_op();
    80004e24:	fffff097          	auipc	ra,0xfffff
    80004e28:	3d8080e7          	jalr	984(ra) # 800041fc <end_op>
  p = myproc();
    80004e2c:	ffffd097          	auipc	ra,0xffffd
    80004e30:	b9a080e7          	jalr	-1126(ra) # 800019c6 <myproc>
    80004e34:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e36:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e3a:	6785                	lui	a5,0x1
    80004e3c:	17fd                	addi	a5,a5,-1
    80004e3e:	9a3e                	add	s4,s4,a5
    80004e40:	757d                	lui	a0,0xfffff
    80004e42:	00aa77b3          	and	a5,s4,a0
    80004e46:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e4a:	4691                	li	a3,4
    80004e4c:	6609                	lui	a2,0x2
    80004e4e:	963e                	add	a2,a2,a5
    80004e50:	85be                	mv	a1,a5
    80004e52:	855e                	mv	a0,s7
    80004e54:	ffffc097          	auipc	ra,0xffffc
    80004e58:	5d8080e7          	jalr	1496(ra) # 8000142c <uvmalloc>
    80004e5c:	8b2a                	mv	s6,a0
  ip = 0;
    80004e5e:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e60:	12050c63          	beqz	a0,80004f98 <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e64:	75f9                	lui	a1,0xffffe
    80004e66:	95aa                	add	a1,a1,a0
    80004e68:	855e                	mv	a0,s7
    80004e6a:	ffffc097          	auipc	ra,0xffffc
    80004e6e:	7e8080e7          	jalr	2024(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e72:	7c7d                	lui	s8,0xfffff
    80004e74:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e76:	e0043783          	ld	a5,-512(s0)
    80004e7a:	6388                	ld	a0,0(a5)
    80004e7c:	c535                	beqz	a0,80004ee8 <exec+0x218>
    80004e7e:	e9040993          	addi	s3,s0,-368
    80004e82:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e86:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e88:	ffffc097          	auipc	ra,0xffffc
    80004e8c:	fe2080e7          	jalr	-30(ra) # 80000e6a <strlen>
    80004e90:	2505                	addiw	a0,a0,1
    80004e92:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e96:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e9a:	13896663          	bltu	s2,s8,80004fc6 <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e9e:	e0043d83          	ld	s11,-512(s0)
    80004ea2:	000dba03          	ld	s4,0(s11)
    80004ea6:	8552                	mv	a0,s4
    80004ea8:	ffffc097          	auipc	ra,0xffffc
    80004eac:	fc2080e7          	jalr	-62(ra) # 80000e6a <strlen>
    80004eb0:	0015069b          	addiw	a3,a0,1
    80004eb4:	8652                	mv	a2,s4
    80004eb6:	85ca                	mv	a1,s2
    80004eb8:	855e                	mv	a0,s7
    80004eba:	ffffc097          	auipc	ra,0xffffc
    80004ebe:	7ca080e7          	jalr	1994(ra) # 80001684 <copyout>
    80004ec2:	10054663          	bltz	a0,80004fce <exec+0x2fe>
    ustack[argc] = sp;
    80004ec6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004eca:	0485                	addi	s1,s1,1
    80004ecc:	008d8793          	addi	a5,s11,8
    80004ed0:	e0f43023          	sd	a5,-512(s0)
    80004ed4:	008db503          	ld	a0,8(s11)
    80004ed8:	c911                	beqz	a0,80004eec <exec+0x21c>
    if(argc >= MAXARG)
    80004eda:	09a1                	addi	s3,s3,8
    80004edc:	fb3c96e3          	bne	s9,s3,80004e88 <exec+0x1b8>
  sz = sz1;
    80004ee0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ee4:	4481                	li	s1,0
    80004ee6:	a84d                	j	80004f98 <exec+0x2c8>
  sp = sz;
    80004ee8:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004eea:	4481                	li	s1,0
  ustack[argc] = 0;
    80004eec:	00349793          	slli	a5,s1,0x3
    80004ef0:	f9040713          	addi	a4,s0,-112
    80004ef4:	97ba                	add	a5,a5,a4
    80004ef6:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004efa:	00148693          	addi	a3,s1,1
    80004efe:	068e                	slli	a3,a3,0x3
    80004f00:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f04:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f08:	01897663          	bgeu	s2,s8,80004f14 <exec+0x244>
  sz = sz1;
    80004f0c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f10:	4481                	li	s1,0
    80004f12:	a059                	j	80004f98 <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f14:	e9040613          	addi	a2,s0,-368
    80004f18:	85ca                	mv	a1,s2
    80004f1a:	855e                	mv	a0,s7
    80004f1c:	ffffc097          	auipc	ra,0xffffc
    80004f20:	768080e7          	jalr	1896(ra) # 80001684 <copyout>
    80004f24:	0a054963          	bltz	a0,80004fd6 <exec+0x306>
  p->trapframe->a1 = sp;
    80004f28:	058ab783          	ld	a5,88(s5)
    80004f2c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f30:	df843783          	ld	a5,-520(s0)
    80004f34:	0007c703          	lbu	a4,0(a5)
    80004f38:	cf11                	beqz	a4,80004f54 <exec+0x284>
    80004f3a:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f3c:	02f00693          	li	a3,47
    80004f40:	a039                	j	80004f4e <exec+0x27e>
      last = s+1;
    80004f42:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004f46:	0785                	addi	a5,a5,1
    80004f48:	fff7c703          	lbu	a4,-1(a5)
    80004f4c:	c701                	beqz	a4,80004f54 <exec+0x284>
    if(*s == '/')
    80004f4e:	fed71ce3          	bne	a4,a3,80004f46 <exec+0x276>
    80004f52:	bfc5                	j	80004f42 <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f54:	4641                	li	a2,16
    80004f56:	df843583          	ld	a1,-520(s0)
    80004f5a:	158a8513          	addi	a0,s5,344
    80004f5e:	ffffc097          	auipc	ra,0xffffc
    80004f62:	eda080e7          	jalr	-294(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f66:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f6a:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f6e:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f72:	058ab783          	ld	a5,88(s5)
    80004f76:	e6843703          	ld	a4,-408(s0)
    80004f7a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f7c:	058ab783          	ld	a5,88(s5)
    80004f80:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f84:	85ea                	mv	a1,s10
    80004f86:	ffffd097          	auipc	ra,0xffffd
    80004f8a:	ba0080e7          	jalr	-1120(ra) # 80001b26 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f8e:	0004851b          	sext.w	a0,s1
    80004f92:	bbd9                	j	80004d68 <exec+0x98>
    80004f94:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f98:	e0843583          	ld	a1,-504(s0)
    80004f9c:	855e                	mv	a0,s7
    80004f9e:	ffffd097          	auipc	ra,0xffffd
    80004fa2:	b88080e7          	jalr	-1144(ra) # 80001b26 <proc_freepagetable>
  if(ip){
    80004fa6:	da0497e3          	bnez	s1,80004d54 <exec+0x84>
  return -1;
    80004faa:	557d                	li	a0,-1
    80004fac:	bb75                	j	80004d68 <exec+0x98>
    80004fae:	e1443423          	sd	s4,-504(s0)
    80004fb2:	b7dd                	j	80004f98 <exec+0x2c8>
    80004fb4:	e1443423          	sd	s4,-504(s0)
    80004fb8:	b7c5                	j	80004f98 <exec+0x2c8>
    80004fba:	e1443423          	sd	s4,-504(s0)
    80004fbe:	bfe9                	j	80004f98 <exec+0x2c8>
    80004fc0:	e1443423          	sd	s4,-504(s0)
    80004fc4:	bfd1                	j	80004f98 <exec+0x2c8>
  sz = sz1;
    80004fc6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fca:	4481                	li	s1,0
    80004fcc:	b7f1                	j	80004f98 <exec+0x2c8>
  sz = sz1;
    80004fce:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fd2:	4481                	li	s1,0
    80004fd4:	b7d1                	j	80004f98 <exec+0x2c8>
  sz = sz1;
    80004fd6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fda:	4481                	li	s1,0
    80004fdc:	bf75                	j	80004f98 <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004fde:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fe2:	2b05                	addiw	s6,s6,1
    80004fe4:	0389899b          	addiw	s3,s3,56
    80004fe8:	e8845783          	lhu	a5,-376(s0)
    80004fec:	e2fb57e3          	bge	s6,a5,80004e1a <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004ff0:	2981                	sext.w	s3,s3
    80004ff2:	03800713          	li	a4,56
    80004ff6:	86ce                	mv	a3,s3
    80004ff8:	e1840613          	addi	a2,s0,-488
    80004ffc:	4581                	li	a1,0
    80004ffe:	8526                	mv	a0,s1
    80005000:	fffff097          	auipc	ra,0xfffff
    80005004:	a6e080e7          	jalr	-1426(ra) # 80003a6e <readi>
    80005008:	03800793          	li	a5,56
    8000500c:	f8f514e3          	bne	a0,a5,80004f94 <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    80005010:	e1842783          	lw	a5,-488(s0)
    80005014:	4705                	li	a4,1
    80005016:	fce796e3          	bne	a5,a4,80004fe2 <exec+0x312>
    if(ph.memsz < ph.filesz)
    8000501a:	e4043903          	ld	s2,-448(s0)
    8000501e:	e3843783          	ld	a5,-456(s0)
    80005022:	f8f966e3          	bltu	s2,a5,80004fae <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005026:	e2843783          	ld	a5,-472(s0)
    8000502a:	993e                	add	s2,s2,a5
    8000502c:	f8f964e3          	bltu	s2,a5,80004fb4 <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    80005030:	df043703          	ld	a4,-528(s0)
    80005034:	8ff9                	and	a5,a5,a4
    80005036:	f3d1                	bnez	a5,80004fba <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005038:	e1c42503          	lw	a0,-484(s0)
    8000503c:	00000097          	auipc	ra,0x0
    80005040:	c78080e7          	jalr	-904(ra) # 80004cb4 <flags2perm>
    80005044:	86aa                	mv	a3,a0
    80005046:	864a                	mv	a2,s2
    80005048:	85d2                	mv	a1,s4
    8000504a:	855e                	mv	a0,s7
    8000504c:	ffffc097          	auipc	ra,0xffffc
    80005050:	3e0080e7          	jalr	992(ra) # 8000142c <uvmalloc>
    80005054:	e0a43423          	sd	a0,-504(s0)
    80005058:	d525                	beqz	a0,80004fc0 <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000505a:	e2843d03          	ld	s10,-472(s0)
    8000505e:	e2042d83          	lw	s11,-480(s0)
    80005062:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005066:	f60c0ce3          	beqz	s8,80004fde <exec+0x30e>
    8000506a:	8a62                	mv	s4,s8
    8000506c:	4901                	li	s2,0
    8000506e:	b369                	j	80004df8 <exec+0x128>

0000000080005070 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005070:	7179                	addi	sp,sp,-48
    80005072:	f406                	sd	ra,40(sp)
    80005074:	f022                	sd	s0,32(sp)
    80005076:	ec26                	sd	s1,24(sp)
    80005078:	e84a                	sd	s2,16(sp)
    8000507a:	1800                	addi	s0,sp,48
    8000507c:	892e                	mv	s2,a1
    8000507e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005080:	fdc40593          	addi	a1,s0,-36
    80005084:	ffffe097          	auipc	ra,0xffffe
    80005088:	aca080e7          	jalr	-1334(ra) # 80002b4e <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000508c:	fdc42703          	lw	a4,-36(s0)
    80005090:	47bd                	li	a5,15
    80005092:	02e7eb63          	bltu	a5,a4,800050c8 <argfd+0x58>
    80005096:	ffffd097          	auipc	ra,0xffffd
    8000509a:	930080e7          	jalr	-1744(ra) # 800019c6 <myproc>
    8000509e:	fdc42703          	lw	a4,-36(s0)
    800050a2:	01a70793          	addi	a5,a4,26
    800050a6:	078e                	slli	a5,a5,0x3
    800050a8:	953e                	add	a0,a0,a5
    800050aa:	611c                	ld	a5,0(a0)
    800050ac:	c385                	beqz	a5,800050cc <argfd+0x5c>
    return -1;
  if(pfd)
    800050ae:	00090463          	beqz	s2,800050b6 <argfd+0x46>
    *pfd = fd;
    800050b2:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050b6:	4501                	li	a0,0
  if(pf)
    800050b8:	c091                	beqz	s1,800050bc <argfd+0x4c>
    *pf = f;
    800050ba:	e09c                	sd	a5,0(s1)
}
    800050bc:	70a2                	ld	ra,40(sp)
    800050be:	7402                	ld	s0,32(sp)
    800050c0:	64e2                	ld	s1,24(sp)
    800050c2:	6942                	ld	s2,16(sp)
    800050c4:	6145                	addi	sp,sp,48
    800050c6:	8082                	ret
    return -1;
    800050c8:	557d                	li	a0,-1
    800050ca:	bfcd                	j	800050bc <argfd+0x4c>
    800050cc:	557d                	li	a0,-1
    800050ce:	b7fd                	j	800050bc <argfd+0x4c>

00000000800050d0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050d0:	1101                	addi	sp,sp,-32
    800050d2:	ec06                	sd	ra,24(sp)
    800050d4:	e822                	sd	s0,16(sp)
    800050d6:	e426                	sd	s1,8(sp)
    800050d8:	1000                	addi	s0,sp,32
    800050da:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050dc:	ffffd097          	auipc	ra,0xffffd
    800050e0:	8ea080e7          	jalr	-1814(ra) # 800019c6 <myproc>
    800050e4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050e6:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffdc7a0>
    800050ea:	4501                	li	a0,0
    800050ec:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050ee:	6398                	ld	a4,0(a5)
    800050f0:	cb19                	beqz	a4,80005106 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050f2:	2505                	addiw	a0,a0,1
    800050f4:	07a1                	addi	a5,a5,8
    800050f6:	fed51ce3          	bne	a0,a3,800050ee <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050fa:	557d                	li	a0,-1
}
    800050fc:	60e2                	ld	ra,24(sp)
    800050fe:	6442                	ld	s0,16(sp)
    80005100:	64a2                	ld	s1,8(sp)
    80005102:	6105                	addi	sp,sp,32
    80005104:	8082                	ret
      p->ofile[fd] = f;
    80005106:	01a50793          	addi	a5,a0,26
    8000510a:	078e                	slli	a5,a5,0x3
    8000510c:	963e                	add	a2,a2,a5
    8000510e:	e204                	sd	s1,0(a2)
      return fd;
    80005110:	b7f5                	j	800050fc <fdalloc+0x2c>

0000000080005112 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005112:	715d                	addi	sp,sp,-80
    80005114:	e486                	sd	ra,72(sp)
    80005116:	e0a2                	sd	s0,64(sp)
    80005118:	fc26                	sd	s1,56(sp)
    8000511a:	f84a                	sd	s2,48(sp)
    8000511c:	f44e                	sd	s3,40(sp)
    8000511e:	f052                	sd	s4,32(sp)
    80005120:	ec56                	sd	s5,24(sp)
    80005122:	e85a                	sd	s6,16(sp)
    80005124:	0880                	addi	s0,sp,80
    80005126:	8b2e                	mv	s6,a1
    80005128:	89b2                	mv	s3,a2
    8000512a:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000512c:	fb040593          	addi	a1,s0,-80
    80005130:	fffff097          	auipc	ra,0xfffff
    80005134:	e4e080e7          	jalr	-434(ra) # 80003f7e <nameiparent>
    80005138:	84aa                	mv	s1,a0
    8000513a:	16050063          	beqz	a0,8000529a <create+0x188>
    return 0;

  ilock(dp);
    8000513e:	ffffe097          	auipc	ra,0xffffe
    80005142:	67c080e7          	jalr	1660(ra) # 800037ba <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005146:	4601                	li	a2,0
    80005148:	fb040593          	addi	a1,s0,-80
    8000514c:	8526                	mv	a0,s1
    8000514e:	fffff097          	auipc	ra,0xfffff
    80005152:	b50080e7          	jalr	-1200(ra) # 80003c9e <dirlookup>
    80005156:	8aaa                	mv	s5,a0
    80005158:	c931                	beqz	a0,800051ac <create+0x9a>
    iunlockput(dp);
    8000515a:	8526                	mv	a0,s1
    8000515c:	fffff097          	auipc	ra,0xfffff
    80005160:	8c0080e7          	jalr	-1856(ra) # 80003a1c <iunlockput>
    ilock(ip);
    80005164:	8556                	mv	a0,s5
    80005166:	ffffe097          	auipc	ra,0xffffe
    8000516a:	654080e7          	jalr	1620(ra) # 800037ba <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000516e:	000b059b          	sext.w	a1,s6
    80005172:	4789                	li	a5,2
    80005174:	02f59563          	bne	a1,a5,8000519e <create+0x8c>
    80005178:	044ad783          	lhu	a5,68(s5)
    8000517c:	37f9                	addiw	a5,a5,-2
    8000517e:	17c2                	slli	a5,a5,0x30
    80005180:	93c1                	srli	a5,a5,0x30
    80005182:	4705                	li	a4,1
    80005184:	00f76d63          	bltu	a4,a5,8000519e <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005188:	8556                	mv	a0,s5
    8000518a:	60a6                	ld	ra,72(sp)
    8000518c:	6406                	ld	s0,64(sp)
    8000518e:	74e2                	ld	s1,56(sp)
    80005190:	7942                	ld	s2,48(sp)
    80005192:	79a2                	ld	s3,40(sp)
    80005194:	7a02                	ld	s4,32(sp)
    80005196:	6ae2                	ld	s5,24(sp)
    80005198:	6b42                	ld	s6,16(sp)
    8000519a:	6161                	addi	sp,sp,80
    8000519c:	8082                	ret
    iunlockput(ip);
    8000519e:	8556                	mv	a0,s5
    800051a0:	fffff097          	auipc	ra,0xfffff
    800051a4:	87c080e7          	jalr	-1924(ra) # 80003a1c <iunlockput>
    return 0;
    800051a8:	4a81                	li	s5,0
    800051aa:	bff9                	j	80005188 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800051ac:	85da                	mv	a1,s6
    800051ae:	4088                	lw	a0,0(s1)
    800051b0:	ffffe097          	auipc	ra,0xffffe
    800051b4:	46e080e7          	jalr	1134(ra) # 8000361e <ialloc>
    800051b8:	8a2a                	mv	s4,a0
    800051ba:	c921                	beqz	a0,8000520a <create+0xf8>
  ilock(ip);
    800051bc:	ffffe097          	auipc	ra,0xffffe
    800051c0:	5fe080e7          	jalr	1534(ra) # 800037ba <ilock>
  ip->major = major;
    800051c4:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800051c8:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800051cc:	4785                	li	a5,1
    800051ce:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    800051d2:	8552                	mv	a0,s4
    800051d4:	ffffe097          	auipc	ra,0xffffe
    800051d8:	51c080e7          	jalr	1308(ra) # 800036f0 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051dc:	000b059b          	sext.w	a1,s6
    800051e0:	4785                	li	a5,1
    800051e2:	02f58b63          	beq	a1,a5,80005218 <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    800051e6:	004a2603          	lw	a2,4(s4)
    800051ea:	fb040593          	addi	a1,s0,-80
    800051ee:	8526                	mv	a0,s1
    800051f0:	fffff097          	auipc	ra,0xfffff
    800051f4:	cbe080e7          	jalr	-834(ra) # 80003eae <dirlink>
    800051f8:	06054f63          	bltz	a0,80005276 <create+0x164>
  iunlockput(dp);
    800051fc:	8526                	mv	a0,s1
    800051fe:	fffff097          	auipc	ra,0xfffff
    80005202:	81e080e7          	jalr	-2018(ra) # 80003a1c <iunlockput>
  return ip;
    80005206:	8ad2                	mv	s5,s4
    80005208:	b741                	j	80005188 <create+0x76>
    iunlockput(dp);
    8000520a:	8526                	mv	a0,s1
    8000520c:	fffff097          	auipc	ra,0xfffff
    80005210:	810080e7          	jalr	-2032(ra) # 80003a1c <iunlockput>
    return 0;
    80005214:	8ad2                	mv	s5,s4
    80005216:	bf8d                	j	80005188 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005218:	004a2603          	lw	a2,4(s4)
    8000521c:	00003597          	auipc	a1,0x3
    80005220:	5cc58593          	addi	a1,a1,1484 # 800087e8 <syscalls+0x2b8>
    80005224:	8552                	mv	a0,s4
    80005226:	fffff097          	auipc	ra,0xfffff
    8000522a:	c88080e7          	jalr	-888(ra) # 80003eae <dirlink>
    8000522e:	04054463          	bltz	a0,80005276 <create+0x164>
    80005232:	40d0                	lw	a2,4(s1)
    80005234:	00003597          	auipc	a1,0x3
    80005238:	5bc58593          	addi	a1,a1,1468 # 800087f0 <syscalls+0x2c0>
    8000523c:	8552                	mv	a0,s4
    8000523e:	fffff097          	auipc	ra,0xfffff
    80005242:	c70080e7          	jalr	-912(ra) # 80003eae <dirlink>
    80005246:	02054863          	bltz	a0,80005276 <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    8000524a:	004a2603          	lw	a2,4(s4)
    8000524e:	fb040593          	addi	a1,s0,-80
    80005252:	8526                	mv	a0,s1
    80005254:	fffff097          	auipc	ra,0xfffff
    80005258:	c5a080e7          	jalr	-934(ra) # 80003eae <dirlink>
    8000525c:	00054d63          	bltz	a0,80005276 <create+0x164>
    dp->nlink++;  // for ".."
    80005260:	04a4d783          	lhu	a5,74(s1)
    80005264:	2785                	addiw	a5,a5,1
    80005266:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000526a:	8526                	mv	a0,s1
    8000526c:	ffffe097          	auipc	ra,0xffffe
    80005270:	484080e7          	jalr	1156(ra) # 800036f0 <iupdate>
    80005274:	b761                	j	800051fc <create+0xea>
  ip->nlink = 0;
    80005276:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000527a:	8552                	mv	a0,s4
    8000527c:	ffffe097          	auipc	ra,0xffffe
    80005280:	474080e7          	jalr	1140(ra) # 800036f0 <iupdate>
  iunlockput(ip);
    80005284:	8552                	mv	a0,s4
    80005286:	ffffe097          	auipc	ra,0xffffe
    8000528a:	796080e7          	jalr	1942(ra) # 80003a1c <iunlockput>
  iunlockput(dp);
    8000528e:	8526                	mv	a0,s1
    80005290:	ffffe097          	auipc	ra,0xffffe
    80005294:	78c080e7          	jalr	1932(ra) # 80003a1c <iunlockput>
  return 0;
    80005298:	bdc5                	j	80005188 <create+0x76>
    return 0;
    8000529a:	8aaa                	mv	s5,a0
    8000529c:	b5f5                	j	80005188 <create+0x76>

000000008000529e <sys_dup>:
{
    8000529e:	7179                	addi	sp,sp,-48
    800052a0:	f406                	sd	ra,40(sp)
    800052a2:	f022                	sd	s0,32(sp)
    800052a4:	ec26                	sd	s1,24(sp)
    800052a6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052a8:	fd840613          	addi	a2,s0,-40
    800052ac:	4581                	li	a1,0
    800052ae:	4501                	li	a0,0
    800052b0:	00000097          	auipc	ra,0x0
    800052b4:	dc0080e7          	jalr	-576(ra) # 80005070 <argfd>
    return -1;
    800052b8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052ba:	02054363          	bltz	a0,800052e0 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800052be:	fd843503          	ld	a0,-40(s0)
    800052c2:	00000097          	auipc	ra,0x0
    800052c6:	e0e080e7          	jalr	-498(ra) # 800050d0 <fdalloc>
    800052ca:	84aa                	mv	s1,a0
    return -1;
    800052cc:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052ce:	00054963          	bltz	a0,800052e0 <sys_dup+0x42>
  filedup(f);
    800052d2:	fd843503          	ld	a0,-40(s0)
    800052d6:	fffff097          	auipc	ra,0xfffff
    800052da:	320080e7          	jalr	800(ra) # 800045f6 <filedup>
  return fd;
    800052de:	87a6                	mv	a5,s1
}
    800052e0:	853e                	mv	a0,a5
    800052e2:	70a2                	ld	ra,40(sp)
    800052e4:	7402                	ld	s0,32(sp)
    800052e6:	64e2                	ld	s1,24(sp)
    800052e8:	6145                	addi	sp,sp,48
    800052ea:	8082                	ret

00000000800052ec <sys_read>:
{
    800052ec:	7179                	addi	sp,sp,-48
    800052ee:	f406                	sd	ra,40(sp)
    800052f0:	f022                	sd	s0,32(sp)
    800052f2:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800052f4:	fd840593          	addi	a1,s0,-40
    800052f8:	4505                	li	a0,1
    800052fa:	ffffe097          	auipc	ra,0xffffe
    800052fe:	874080e7          	jalr	-1932(ra) # 80002b6e <argaddr>
  argint(2, &n);
    80005302:	fe440593          	addi	a1,s0,-28
    80005306:	4509                	li	a0,2
    80005308:	ffffe097          	auipc	ra,0xffffe
    8000530c:	846080e7          	jalr	-1978(ra) # 80002b4e <argint>
  if(argfd(0, 0, &f) < 0)
    80005310:	fe840613          	addi	a2,s0,-24
    80005314:	4581                	li	a1,0
    80005316:	4501                	li	a0,0
    80005318:	00000097          	auipc	ra,0x0
    8000531c:	d58080e7          	jalr	-680(ra) # 80005070 <argfd>
    80005320:	87aa                	mv	a5,a0
    return -1;
    80005322:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005324:	0007cc63          	bltz	a5,8000533c <sys_read+0x50>
  return fileread(f, p, n);
    80005328:	fe442603          	lw	a2,-28(s0)
    8000532c:	fd843583          	ld	a1,-40(s0)
    80005330:	fe843503          	ld	a0,-24(s0)
    80005334:	fffff097          	auipc	ra,0xfffff
    80005338:	44e080e7          	jalr	1102(ra) # 80004782 <fileread>
}
    8000533c:	70a2                	ld	ra,40(sp)
    8000533e:	7402                	ld	s0,32(sp)
    80005340:	6145                	addi	sp,sp,48
    80005342:	8082                	ret

0000000080005344 <sys_write>:
{
    80005344:	7179                	addi	sp,sp,-48
    80005346:	f406                	sd	ra,40(sp)
    80005348:	f022                	sd	s0,32(sp)
    8000534a:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000534c:	fd840593          	addi	a1,s0,-40
    80005350:	4505                	li	a0,1
    80005352:	ffffe097          	auipc	ra,0xffffe
    80005356:	81c080e7          	jalr	-2020(ra) # 80002b6e <argaddr>
  argint(2, &n);
    8000535a:	fe440593          	addi	a1,s0,-28
    8000535e:	4509                	li	a0,2
    80005360:	ffffd097          	auipc	ra,0xffffd
    80005364:	7ee080e7          	jalr	2030(ra) # 80002b4e <argint>
  if(argfd(0, 0, &f) < 0)
    80005368:	fe840613          	addi	a2,s0,-24
    8000536c:	4581                	li	a1,0
    8000536e:	4501                	li	a0,0
    80005370:	00000097          	auipc	ra,0x0
    80005374:	d00080e7          	jalr	-768(ra) # 80005070 <argfd>
    80005378:	87aa                	mv	a5,a0
    return -1;
    8000537a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000537c:	0007cc63          	bltz	a5,80005394 <sys_write+0x50>
  return filewrite(f, p, n);
    80005380:	fe442603          	lw	a2,-28(s0)
    80005384:	fd843583          	ld	a1,-40(s0)
    80005388:	fe843503          	ld	a0,-24(s0)
    8000538c:	fffff097          	auipc	ra,0xfffff
    80005390:	4b8080e7          	jalr	1208(ra) # 80004844 <filewrite>
}
    80005394:	70a2                	ld	ra,40(sp)
    80005396:	7402                	ld	s0,32(sp)
    80005398:	6145                	addi	sp,sp,48
    8000539a:	8082                	ret

000000008000539c <sys_close>:
{
    8000539c:	1101                	addi	sp,sp,-32
    8000539e:	ec06                	sd	ra,24(sp)
    800053a0:	e822                	sd	s0,16(sp)
    800053a2:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053a4:	fe040613          	addi	a2,s0,-32
    800053a8:	fec40593          	addi	a1,s0,-20
    800053ac:	4501                	li	a0,0
    800053ae:	00000097          	auipc	ra,0x0
    800053b2:	cc2080e7          	jalr	-830(ra) # 80005070 <argfd>
    return -1;
    800053b6:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053b8:	02054463          	bltz	a0,800053e0 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053bc:	ffffc097          	auipc	ra,0xffffc
    800053c0:	60a080e7          	jalr	1546(ra) # 800019c6 <myproc>
    800053c4:	fec42783          	lw	a5,-20(s0)
    800053c8:	07e9                	addi	a5,a5,26
    800053ca:	078e                	slli	a5,a5,0x3
    800053cc:	97aa                	add	a5,a5,a0
    800053ce:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800053d2:	fe043503          	ld	a0,-32(s0)
    800053d6:	fffff097          	auipc	ra,0xfffff
    800053da:	272080e7          	jalr	626(ra) # 80004648 <fileclose>
  return 0;
    800053de:	4781                	li	a5,0
}
    800053e0:	853e                	mv	a0,a5
    800053e2:	60e2                	ld	ra,24(sp)
    800053e4:	6442                	ld	s0,16(sp)
    800053e6:	6105                	addi	sp,sp,32
    800053e8:	8082                	ret

00000000800053ea <sys_fstat>:
{
    800053ea:	1101                	addi	sp,sp,-32
    800053ec:	ec06                	sd	ra,24(sp)
    800053ee:	e822                	sd	s0,16(sp)
    800053f0:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800053f2:	fe040593          	addi	a1,s0,-32
    800053f6:	4505                	li	a0,1
    800053f8:	ffffd097          	auipc	ra,0xffffd
    800053fc:	776080e7          	jalr	1910(ra) # 80002b6e <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005400:	fe840613          	addi	a2,s0,-24
    80005404:	4581                	li	a1,0
    80005406:	4501                	li	a0,0
    80005408:	00000097          	auipc	ra,0x0
    8000540c:	c68080e7          	jalr	-920(ra) # 80005070 <argfd>
    80005410:	87aa                	mv	a5,a0
    return -1;
    80005412:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005414:	0007ca63          	bltz	a5,80005428 <sys_fstat+0x3e>
  return filestat(f, st);
    80005418:	fe043583          	ld	a1,-32(s0)
    8000541c:	fe843503          	ld	a0,-24(s0)
    80005420:	fffff097          	auipc	ra,0xfffff
    80005424:	2f0080e7          	jalr	752(ra) # 80004710 <filestat>
}
    80005428:	60e2                	ld	ra,24(sp)
    8000542a:	6442                	ld	s0,16(sp)
    8000542c:	6105                	addi	sp,sp,32
    8000542e:	8082                	ret

0000000080005430 <sys_link>:
{
    80005430:	7169                	addi	sp,sp,-304
    80005432:	f606                	sd	ra,296(sp)
    80005434:	f222                	sd	s0,288(sp)
    80005436:	ee26                	sd	s1,280(sp)
    80005438:	ea4a                	sd	s2,272(sp)
    8000543a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000543c:	08000613          	li	a2,128
    80005440:	ed040593          	addi	a1,s0,-304
    80005444:	4501                	li	a0,0
    80005446:	ffffd097          	auipc	ra,0xffffd
    8000544a:	748080e7          	jalr	1864(ra) # 80002b8e <argstr>
    return -1;
    8000544e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005450:	10054e63          	bltz	a0,8000556c <sys_link+0x13c>
    80005454:	08000613          	li	a2,128
    80005458:	f5040593          	addi	a1,s0,-176
    8000545c:	4505                	li	a0,1
    8000545e:	ffffd097          	auipc	ra,0xffffd
    80005462:	730080e7          	jalr	1840(ra) # 80002b8e <argstr>
    return -1;
    80005466:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005468:	10054263          	bltz	a0,8000556c <sys_link+0x13c>
  begin_op();
    8000546c:	fffff097          	auipc	ra,0xfffff
    80005470:	d10080e7          	jalr	-752(ra) # 8000417c <begin_op>
  if((ip = namei(old)) == 0){
    80005474:	ed040513          	addi	a0,s0,-304
    80005478:	fffff097          	auipc	ra,0xfffff
    8000547c:	ae8080e7          	jalr	-1304(ra) # 80003f60 <namei>
    80005480:	84aa                	mv	s1,a0
    80005482:	c551                	beqz	a0,8000550e <sys_link+0xde>
  ilock(ip);
    80005484:	ffffe097          	auipc	ra,0xffffe
    80005488:	336080e7          	jalr	822(ra) # 800037ba <ilock>
  if(ip->type == T_DIR){
    8000548c:	04449703          	lh	a4,68(s1)
    80005490:	4785                	li	a5,1
    80005492:	08f70463          	beq	a4,a5,8000551a <sys_link+0xea>
  ip->nlink++;
    80005496:	04a4d783          	lhu	a5,74(s1)
    8000549a:	2785                	addiw	a5,a5,1
    8000549c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054a0:	8526                	mv	a0,s1
    800054a2:	ffffe097          	auipc	ra,0xffffe
    800054a6:	24e080e7          	jalr	590(ra) # 800036f0 <iupdate>
  iunlock(ip);
    800054aa:	8526                	mv	a0,s1
    800054ac:	ffffe097          	auipc	ra,0xffffe
    800054b0:	3d0080e7          	jalr	976(ra) # 8000387c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054b4:	fd040593          	addi	a1,s0,-48
    800054b8:	f5040513          	addi	a0,s0,-176
    800054bc:	fffff097          	auipc	ra,0xfffff
    800054c0:	ac2080e7          	jalr	-1342(ra) # 80003f7e <nameiparent>
    800054c4:	892a                	mv	s2,a0
    800054c6:	c935                	beqz	a0,8000553a <sys_link+0x10a>
  ilock(dp);
    800054c8:	ffffe097          	auipc	ra,0xffffe
    800054cc:	2f2080e7          	jalr	754(ra) # 800037ba <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054d0:	00092703          	lw	a4,0(s2)
    800054d4:	409c                	lw	a5,0(s1)
    800054d6:	04f71d63          	bne	a4,a5,80005530 <sys_link+0x100>
    800054da:	40d0                	lw	a2,4(s1)
    800054dc:	fd040593          	addi	a1,s0,-48
    800054e0:	854a                	mv	a0,s2
    800054e2:	fffff097          	auipc	ra,0xfffff
    800054e6:	9cc080e7          	jalr	-1588(ra) # 80003eae <dirlink>
    800054ea:	04054363          	bltz	a0,80005530 <sys_link+0x100>
  iunlockput(dp);
    800054ee:	854a                	mv	a0,s2
    800054f0:	ffffe097          	auipc	ra,0xffffe
    800054f4:	52c080e7          	jalr	1324(ra) # 80003a1c <iunlockput>
  iput(ip);
    800054f8:	8526                	mv	a0,s1
    800054fa:	ffffe097          	auipc	ra,0xffffe
    800054fe:	47a080e7          	jalr	1146(ra) # 80003974 <iput>
  end_op();
    80005502:	fffff097          	auipc	ra,0xfffff
    80005506:	cfa080e7          	jalr	-774(ra) # 800041fc <end_op>
  return 0;
    8000550a:	4781                	li	a5,0
    8000550c:	a085                	j	8000556c <sys_link+0x13c>
    end_op();
    8000550e:	fffff097          	auipc	ra,0xfffff
    80005512:	cee080e7          	jalr	-786(ra) # 800041fc <end_op>
    return -1;
    80005516:	57fd                	li	a5,-1
    80005518:	a891                	j	8000556c <sys_link+0x13c>
    iunlockput(ip);
    8000551a:	8526                	mv	a0,s1
    8000551c:	ffffe097          	auipc	ra,0xffffe
    80005520:	500080e7          	jalr	1280(ra) # 80003a1c <iunlockput>
    end_op();
    80005524:	fffff097          	auipc	ra,0xfffff
    80005528:	cd8080e7          	jalr	-808(ra) # 800041fc <end_op>
    return -1;
    8000552c:	57fd                	li	a5,-1
    8000552e:	a83d                	j	8000556c <sys_link+0x13c>
    iunlockput(dp);
    80005530:	854a                	mv	a0,s2
    80005532:	ffffe097          	auipc	ra,0xffffe
    80005536:	4ea080e7          	jalr	1258(ra) # 80003a1c <iunlockput>
  ilock(ip);
    8000553a:	8526                	mv	a0,s1
    8000553c:	ffffe097          	auipc	ra,0xffffe
    80005540:	27e080e7          	jalr	638(ra) # 800037ba <ilock>
  ip->nlink--;
    80005544:	04a4d783          	lhu	a5,74(s1)
    80005548:	37fd                	addiw	a5,a5,-1
    8000554a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000554e:	8526                	mv	a0,s1
    80005550:	ffffe097          	auipc	ra,0xffffe
    80005554:	1a0080e7          	jalr	416(ra) # 800036f0 <iupdate>
  iunlockput(ip);
    80005558:	8526                	mv	a0,s1
    8000555a:	ffffe097          	auipc	ra,0xffffe
    8000555e:	4c2080e7          	jalr	1218(ra) # 80003a1c <iunlockput>
  end_op();
    80005562:	fffff097          	auipc	ra,0xfffff
    80005566:	c9a080e7          	jalr	-870(ra) # 800041fc <end_op>
  return -1;
    8000556a:	57fd                	li	a5,-1
}
    8000556c:	853e                	mv	a0,a5
    8000556e:	70b2                	ld	ra,296(sp)
    80005570:	7412                	ld	s0,288(sp)
    80005572:	64f2                	ld	s1,280(sp)
    80005574:	6952                	ld	s2,272(sp)
    80005576:	6155                	addi	sp,sp,304
    80005578:	8082                	ret

000000008000557a <sys_unlink>:
{
    8000557a:	7151                	addi	sp,sp,-240
    8000557c:	f586                	sd	ra,232(sp)
    8000557e:	f1a2                	sd	s0,224(sp)
    80005580:	eda6                	sd	s1,216(sp)
    80005582:	e9ca                	sd	s2,208(sp)
    80005584:	e5ce                	sd	s3,200(sp)
    80005586:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005588:	08000613          	li	a2,128
    8000558c:	f3040593          	addi	a1,s0,-208
    80005590:	4501                	li	a0,0
    80005592:	ffffd097          	auipc	ra,0xffffd
    80005596:	5fc080e7          	jalr	1532(ra) # 80002b8e <argstr>
    8000559a:	18054163          	bltz	a0,8000571c <sys_unlink+0x1a2>
  begin_op();
    8000559e:	fffff097          	auipc	ra,0xfffff
    800055a2:	bde080e7          	jalr	-1058(ra) # 8000417c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055a6:	fb040593          	addi	a1,s0,-80
    800055aa:	f3040513          	addi	a0,s0,-208
    800055ae:	fffff097          	auipc	ra,0xfffff
    800055b2:	9d0080e7          	jalr	-1584(ra) # 80003f7e <nameiparent>
    800055b6:	84aa                	mv	s1,a0
    800055b8:	c979                	beqz	a0,8000568e <sys_unlink+0x114>
  ilock(dp);
    800055ba:	ffffe097          	auipc	ra,0xffffe
    800055be:	200080e7          	jalr	512(ra) # 800037ba <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055c2:	00003597          	auipc	a1,0x3
    800055c6:	22658593          	addi	a1,a1,550 # 800087e8 <syscalls+0x2b8>
    800055ca:	fb040513          	addi	a0,s0,-80
    800055ce:	ffffe097          	auipc	ra,0xffffe
    800055d2:	6b6080e7          	jalr	1718(ra) # 80003c84 <namecmp>
    800055d6:	14050a63          	beqz	a0,8000572a <sys_unlink+0x1b0>
    800055da:	00003597          	auipc	a1,0x3
    800055de:	21658593          	addi	a1,a1,534 # 800087f0 <syscalls+0x2c0>
    800055e2:	fb040513          	addi	a0,s0,-80
    800055e6:	ffffe097          	auipc	ra,0xffffe
    800055ea:	69e080e7          	jalr	1694(ra) # 80003c84 <namecmp>
    800055ee:	12050e63          	beqz	a0,8000572a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055f2:	f2c40613          	addi	a2,s0,-212
    800055f6:	fb040593          	addi	a1,s0,-80
    800055fa:	8526                	mv	a0,s1
    800055fc:	ffffe097          	auipc	ra,0xffffe
    80005600:	6a2080e7          	jalr	1698(ra) # 80003c9e <dirlookup>
    80005604:	892a                	mv	s2,a0
    80005606:	12050263          	beqz	a0,8000572a <sys_unlink+0x1b0>
  ilock(ip);
    8000560a:	ffffe097          	auipc	ra,0xffffe
    8000560e:	1b0080e7          	jalr	432(ra) # 800037ba <ilock>
  if(ip->nlink < 1)
    80005612:	04a91783          	lh	a5,74(s2)
    80005616:	08f05263          	blez	a5,8000569a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000561a:	04491703          	lh	a4,68(s2)
    8000561e:	4785                	li	a5,1
    80005620:	08f70563          	beq	a4,a5,800056aa <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005624:	4641                	li	a2,16
    80005626:	4581                	li	a1,0
    80005628:	fc040513          	addi	a0,s0,-64
    8000562c:	ffffb097          	auipc	ra,0xffffb
    80005630:	6ba080e7          	jalr	1722(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005634:	4741                	li	a4,16
    80005636:	f2c42683          	lw	a3,-212(s0)
    8000563a:	fc040613          	addi	a2,s0,-64
    8000563e:	4581                	li	a1,0
    80005640:	8526                	mv	a0,s1
    80005642:	ffffe097          	auipc	ra,0xffffe
    80005646:	524080e7          	jalr	1316(ra) # 80003b66 <writei>
    8000564a:	47c1                	li	a5,16
    8000564c:	0af51563          	bne	a0,a5,800056f6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005650:	04491703          	lh	a4,68(s2)
    80005654:	4785                	li	a5,1
    80005656:	0af70863          	beq	a4,a5,80005706 <sys_unlink+0x18c>
  iunlockput(dp);
    8000565a:	8526                	mv	a0,s1
    8000565c:	ffffe097          	auipc	ra,0xffffe
    80005660:	3c0080e7          	jalr	960(ra) # 80003a1c <iunlockput>
  ip->nlink--;
    80005664:	04a95783          	lhu	a5,74(s2)
    80005668:	37fd                	addiw	a5,a5,-1
    8000566a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000566e:	854a                	mv	a0,s2
    80005670:	ffffe097          	auipc	ra,0xffffe
    80005674:	080080e7          	jalr	128(ra) # 800036f0 <iupdate>
  iunlockput(ip);
    80005678:	854a                	mv	a0,s2
    8000567a:	ffffe097          	auipc	ra,0xffffe
    8000567e:	3a2080e7          	jalr	930(ra) # 80003a1c <iunlockput>
  end_op();
    80005682:	fffff097          	auipc	ra,0xfffff
    80005686:	b7a080e7          	jalr	-1158(ra) # 800041fc <end_op>
  return 0;
    8000568a:	4501                	li	a0,0
    8000568c:	a84d                	j	8000573e <sys_unlink+0x1c4>
    end_op();
    8000568e:	fffff097          	auipc	ra,0xfffff
    80005692:	b6e080e7          	jalr	-1170(ra) # 800041fc <end_op>
    return -1;
    80005696:	557d                	li	a0,-1
    80005698:	a05d                	j	8000573e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000569a:	00003517          	auipc	a0,0x3
    8000569e:	15e50513          	addi	a0,a0,350 # 800087f8 <syscalls+0x2c8>
    800056a2:	ffffb097          	auipc	ra,0xffffb
    800056a6:	ea2080e7          	jalr	-350(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056aa:	04c92703          	lw	a4,76(s2)
    800056ae:	02000793          	li	a5,32
    800056b2:	f6e7f9e3          	bgeu	a5,a4,80005624 <sys_unlink+0xaa>
    800056b6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056ba:	4741                	li	a4,16
    800056bc:	86ce                	mv	a3,s3
    800056be:	f1840613          	addi	a2,s0,-232
    800056c2:	4581                	li	a1,0
    800056c4:	854a                	mv	a0,s2
    800056c6:	ffffe097          	auipc	ra,0xffffe
    800056ca:	3a8080e7          	jalr	936(ra) # 80003a6e <readi>
    800056ce:	47c1                	li	a5,16
    800056d0:	00f51b63          	bne	a0,a5,800056e6 <sys_unlink+0x16c>
    if(de.inum != 0)
    800056d4:	f1845783          	lhu	a5,-232(s0)
    800056d8:	e7a1                	bnez	a5,80005720 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056da:	29c1                	addiw	s3,s3,16
    800056dc:	04c92783          	lw	a5,76(s2)
    800056e0:	fcf9ede3          	bltu	s3,a5,800056ba <sys_unlink+0x140>
    800056e4:	b781                	j	80005624 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056e6:	00003517          	auipc	a0,0x3
    800056ea:	12a50513          	addi	a0,a0,298 # 80008810 <syscalls+0x2e0>
    800056ee:	ffffb097          	auipc	ra,0xffffb
    800056f2:	e56080e7          	jalr	-426(ra) # 80000544 <panic>
    panic("unlink: writei");
    800056f6:	00003517          	auipc	a0,0x3
    800056fa:	13250513          	addi	a0,a0,306 # 80008828 <syscalls+0x2f8>
    800056fe:	ffffb097          	auipc	ra,0xffffb
    80005702:	e46080e7          	jalr	-442(ra) # 80000544 <panic>
    dp->nlink--;
    80005706:	04a4d783          	lhu	a5,74(s1)
    8000570a:	37fd                	addiw	a5,a5,-1
    8000570c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005710:	8526                	mv	a0,s1
    80005712:	ffffe097          	auipc	ra,0xffffe
    80005716:	fde080e7          	jalr	-34(ra) # 800036f0 <iupdate>
    8000571a:	b781                	j	8000565a <sys_unlink+0xe0>
    return -1;
    8000571c:	557d                	li	a0,-1
    8000571e:	a005                	j	8000573e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005720:	854a                	mv	a0,s2
    80005722:	ffffe097          	auipc	ra,0xffffe
    80005726:	2fa080e7          	jalr	762(ra) # 80003a1c <iunlockput>
  iunlockput(dp);
    8000572a:	8526                	mv	a0,s1
    8000572c:	ffffe097          	auipc	ra,0xffffe
    80005730:	2f0080e7          	jalr	752(ra) # 80003a1c <iunlockput>
  end_op();
    80005734:	fffff097          	auipc	ra,0xfffff
    80005738:	ac8080e7          	jalr	-1336(ra) # 800041fc <end_op>
  return -1;
    8000573c:	557d                	li	a0,-1
}
    8000573e:	70ae                	ld	ra,232(sp)
    80005740:	740e                	ld	s0,224(sp)
    80005742:	64ee                	ld	s1,216(sp)
    80005744:	694e                	ld	s2,208(sp)
    80005746:	69ae                	ld	s3,200(sp)
    80005748:	616d                	addi	sp,sp,240
    8000574a:	8082                	ret

000000008000574c <sys_open>:

uint64
sys_open(void)
{
    8000574c:	7131                	addi	sp,sp,-192
    8000574e:	fd06                	sd	ra,184(sp)
    80005750:	f922                	sd	s0,176(sp)
    80005752:	f526                	sd	s1,168(sp)
    80005754:	f14a                	sd	s2,160(sp)
    80005756:	ed4e                	sd	s3,152(sp)
    80005758:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000575a:	f4c40593          	addi	a1,s0,-180
    8000575e:	4505                	li	a0,1
    80005760:	ffffd097          	auipc	ra,0xffffd
    80005764:	3ee080e7          	jalr	1006(ra) # 80002b4e <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005768:	08000613          	li	a2,128
    8000576c:	f5040593          	addi	a1,s0,-176
    80005770:	4501                	li	a0,0
    80005772:	ffffd097          	auipc	ra,0xffffd
    80005776:	41c080e7          	jalr	1052(ra) # 80002b8e <argstr>
    8000577a:	87aa                	mv	a5,a0
    return -1;
    8000577c:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000577e:	0a07c963          	bltz	a5,80005830 <sys_open+0xe4>

  begin_op();
    80005782:	fffff097          	auipc	ra,0xfffff
    80005786:	9fa080e7          	jalr	-1542(ra) # 8000417c <begin_op>

  if(omode & O_CREATE){
    8000578a:	f4c42783          	lw	a5,-180(s0)
    8000578e:	2007f793          	andi	a5,a5,512
    80005792:	cfc5                	beqz	a5,8000584a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005794:	4681                	li	a3,0
    80005796:	4601                	li	a2,0
    80005798:	4589                	li	a1,2
    8000579a:	f5040513          	addi	a0,s0,-176
    8000579e:	00000097          	auipc	ra,0x0
    800057a2:	974080e7          	jalr	-1676(ra) # 80005112 <create>
    800057a6:	84aa                	mv	s1,a0
    if(ip == 0){
    800057a8:	c959                	beqz	a0,8000583e <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057aa:	04449703          	lh	a4,68(s1)
    800057ae:	478d                	li	a5,3
    800057b0:	00f71763          	bne	a4,a5,800057be <sys_open+0x72>
    800057b4:	0464d703          	lhu	a4,70(s1)
    800057b8:	47a5                	li	a5,9
    800057ba:	0ce7ed63          	bltu	a5,a4,80005894 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057be:	fffff097          	auipc	ra,0xfffff
    800057c2:	dce080e7          	jalr	-562(ra) # 8000458c <filealloc>
    800057c6:	89aa                	mv	s3,a0
    800057c8:	10050363          	beqz	a0,800058ce <sys_open+0x182>
    800057cc:	00000097          	auipc	ra,0x0
    800057d0:	904080e7          	jalr	-1788(ra) # 800050d0 <fdalloc>
    800057d4:	892a                	mv	s2,a0
    800057d6:	0e054763          	bltz	a0,800058c4 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057da:	04449703          	lh	a4,68(s1)
    800057de:	478d                	li	a5,3
    800057e0:	0cf70563          	beq	a4,a5,800058aa <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057e4:	4789                	li	a5,2
    800057e6:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057ea:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057ee:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057f2:	f4c42783          	lw	a5,-180(s0)
    800057f6:	0017c713          	xori	a4,a5,1
    800057fa:	8b05                	andi	a4,a4,1
    800057fc:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005800:	0037f713          	andi	a4,a5,3
    80005804:	00e03733          	snez	a4,a4
    80005808:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000580c:	4007f793          	andi	a5,a5,1024
    80005810:	c791                	beqz	a5,8000581c <sys_open+0xd0>
    80005812:	04449703          	lh	a4,68(s1)
    80005816:	4789                	li	a5,2
    80005818:	0af70063          	beq	a4,a5,800058b8 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000581c:	8526                	mv	a0,s1
    8000581e:	ffffe097          	auipc	ra,0xffffe
    80005822:	05e080e7          	jalr	94(ra) # 8000387c <iunlock>
  end_op();
    80005826:	fffff097          	auipc	ra,0xfffff
    8000582a:	9d6080e7          	jalr	-1578(ra) # 800041fc <end_op>

  return fd;
    8000582e:	854a                	mv	a0,s2
}
    80005830:	70ea                	ld	ra,184(sp)
    80005832:	744a                	ld	s0,176(sp)
    80005834:	74aa                	ld	s1,168(sp)
    80005836:	790a                	ld	s2,160(sp)
    80005838:	69ea                	ld	s3,152(sp)
    8000583a:	6129                	addi	sp,sp,192
    8000583c:	8082                	ret
      end_op();
    8000583e:	fffff097          	auipc	ra,0xfffff
    80005842:	9be080e7          	jalr	-1602(ra) # 800041fc <end_op>
      return -1;
    80005846:	557d                	li	a0,-1
    80005848:	b7e5                	j	80005830 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000584a:	f5040513          	addi	a0,s0,-176
    8000584e:	ffffe097          	auipc	ra,0xffffe
    80005852:	712080e7          	jalr	1810(ra) # 80003f60 <namei>
    80005856:	84aa                	mv	s1,a0
    80005858:	c905                	beqz	a0,80005888 <sys_open+0x13c>
    ilock(ip);
    8000585a:	ffffe097          	auipc	ra,0xffffe
    8000585e:	f60080e7          	jalr	-160(ra) # 800037ba <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005862:	04449703          	lh	a4,68(s1)
    80005866:	4785                	li	a5,1
    80005868:	f4f711e3          	bne	a4,a5,800057aa <sys_open+0x5e>
    8000586c:	f4c42783          	lw	a5,-180(s0)
    80005870:	d7b9                	beqz	a5,800057be <sys_open+0x72>
      iunlockput(ip);
    80005872:	8526                	mv	a0,s1
    80005874:	ffffe097          	auipc	ra,0xffffe
    80005878:	1a8080e7          	jalr	424(ra) # 80003a1c <iunlockput>
      end_op();
    8000587c:	fffff097          	auipc	ra,0xfffff
    80005880:	980080e7          	jalr	-1664(ra) # 800041fc <end_op>
      return -1;
    80005884:	557d                	li	a0,-1
    80005886:	b76d                	j	80005830 <sys_open+0xe4>
      end_op();
    80005888:	fffff097          	auipc	ra,0xfffff
    8000588c:	974080e7          	jalr	-1676(ra) # 800041fc <end_op>
      return -1;
    80005890:	557d                	li	a0,-1
    80005892:	bf79                	j	80005830 <sys_open+0xe4>
    iunlockput(ip);
    80005894:	8526                	mv	a0,s1
    80005896:	ffffe097          	auipc	ra,0xffffe
    8000589a:	186080e7          	jalr	390(ra) # 80003a1c <iunlockput>
    end_op();
    8000589e:	fffff097          	auipc	ra,0xfffff
    800058a2:	95e080e7          	jalr	-1698(ra) # 800041fc <end_op>
    return -1;
    800058a6:	557d                	li	a0,-1
    800058a8:	b761                	j	80005830 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800058aa:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058ae:	04649783          	lh	a5,70(s1)
    800058b2:	02f99223          	sh	a5,36(s3)
    800058b6:	bf25                	j	800057ee <sys_open+0xa2>
    itrunc(ip);
    800058b8:	8526                	mv	a0,s1
    800058ba:	ffffe097          	auipc	ra,0xffffe
    800058be:	00e080e7          	jalr	14(ra) # 800038c8 <itrunc>
    800058c2:	bfa9                	j	8000581c <sys_open+0xd0>
      fileclose(f);
    800058c4:	854e                	mv	a0,s3
    800058c6:	fffff097          	auipc	ra,0xfffff
    800058ca:	d82080e7          	jalr	-638(ra) # 80004648 <fileclose>
    iunlockput(ip);
    800058ce:	8526                	mv	a0,s1
    800058d0:	ffffe097          	auipc	ra,0xffffe
    800058d4:	14c080e7          	jalr	332(ra) # 80003a1c <iunlockput>
    end_op();
    800058d8:	fffff097          	auipc	ra,0xfffff
    800058dc:	924080e7          	jalr	-1756(ra) # 800041fc <end_op>
    return -1;
    800058e0:	557d                	li	a0,-1
    800058e2:	b7b9                	j	80005830 <sys_open+0xe4>

00000000800058e4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058e4:	7175                	addi	sp,sp,-144
    800058e6:	e506                	sd	ra,136(sp)
    800058e8:	e122                	sd	s0,128(sp)
    800058ea:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058ec:	fffff097          	auipc	ra,0xfffff
    800058f0:	890080e7          	jalr	-1904(ra) # 8000417c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058f4:	08000613          	li	a2,128
    800058f8:	f7040593          	addi	a1,s0,-144
    800058fc:	4501                	li	a0,0
    800058fe:	ffffd097          	auipc	ra,0xffffd
    80005902:	290080e7          	jalr	656(ra) # 80002b8e <argstr>
    80005906:	02054963          	bltz	a0,80005938 <sys_mkdir+0x54>
    8000590a:	4681                	li	a3,0
    8000590c:	4601                	li	a2,0
    8000590e:	4585                	li	a1,1
    80005910:	f7040513          	addi	a0,s0,-144
    80005914:	fffff097          	auipc	ra,0xfffff
    80005918:	7fe080e7          	jalr	2046(ra) # 80005112 <create>
    8000591c:	cd11                	beqz	a0,80005938 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000591e:	ffffe097          	auipc	ra,0xffffe
    80005922:	0fe080e7          	jalr	254(ra) # 80003a1c <iunlockput>
  end_op();
    80005926:	fffff097          	auipc	ra,0xfffff
    8000592a:	8d6080e7          	jalr	-1834(ra) # 800041fc <end_op>
  return 0;
    8000592e:	4501                	li	a0,0
}
    80005930:	60aa                	ld	ra,136(sp)
    80005932:	640a                	ld	s0,128(sp)
    80005934:	6149                	addi	sp,sp,144
    80005936:	8082                	ret
    end_op();
    80005938:	fffff097          	auipc	ra,0xfffff
    8000593c:	8c4080e7          	jalr	-1852(ra) # 800041fc <end_op>
    return -1;
    80005940:	557d                	li	a0,-1
    80005942:	b7fd                	j	80005930 <sys_mkdir+0x4c>

0000000080005944 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005944:	7135                	addi	sp,sp,-160
    80005946:	ed06                	sd	ra,152(sp)
    80005948:	e922                	sd	s0,144(sp)
    8000594a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000594c:	fffff097          	auipc	ra,0xfffff
    80005950:	830080e7          	jalr	-2000(ra) # 8000417c <begin_op>
  argint(1, &major);
    80005954:	f6c40593          	addi	a1,s0,-148
    80005958:	4505                	li	a0,1
    8000595a:	ffffd097          	auipc	ra,0xffffd
    8000595e:	1f4080e7          	jalr	500(ra) # 80002b4e <argint>
  argint(2, &minor);
    80005962:	f6840593          	addi	a1,s0,-152
    80005966:	4509                	li	a0,2
    80005968:	ffffd097          	auipc	ra,0xffffd
    8000596c:	1e6080e7          	jalr	486(ra) # 80002b4e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005970:	08000613          	li	a2,128
    80005974:	f7040593          	addi	a1,s0,-144
    80005978:	4501                	li	a0,0
    8000597a:	ffffd097          	auipc	ra,0xffffd
    8000597e:	214080e7          	jalr	532(ra) # 80002b8e <argstr>
    80005982:	02054b63          	bltz	a0,800059b8 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005986:	f6841683          	lh	a3,-152(s0)
    8000598a:	f6c41603          	lh	a2,-148(s0)
    8000598e:	458d                	li	a1,3
    80005990:	f7040513          	addi	a0,s0,-144
    80005994:	fffff097          	auipc	ra,0xfffff
    80005998:	77e080e7          	jalr	1918(ra) # 80005112 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000599c:	cd11                	beqz	a0,800059b8 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000599e:	ffffe097          	auipc	ra,0xffffe
    800059a2:	07e080e7          	jalr	126(ra) # 80003a1c <iunlockput>
  end_op();
    800059a6:	fffff097          	auipc	ra,0xfffff
    800059aa:	856080e7          	jalr	-1962(ra) # 800041fc <end_op>
  return 0;
    800059ae:	4501                	li	a0,0
}
    800059b0:	60ea                	ld	ra,152(sp)
    800059b2:	644a                	ld	s0,144(sp)
    800059b4:	610d                	addi	sp,sp,160
    800059b6:	8082                	ret
    end_op();
    800059b8:	fffff097          	auipc	ra,0xfffff
    800059bc:	844080e7          	jalr	-1980(ra) # 800041fc <end_op>
    return -1;
    800059c0:	557d                	li	a0,-1
    800059c2:	b7fd                	j	800059b0 <sys_mknod+0x6c>

00000000800059c4 <sys_chdir>:

uint64
sys_chdir(void)
{
    800059c4:	7135                	addi	sp,sp,-160
    800059c6:	ed06                	sd	ra,152(sp)
    800059c8:	e922                	sd	s0,144(sp)
    800059ca:	e526                	sd	s1,136(sp)
    800059cc:	e14a                	sd	s2,128(sp)
    800059ce:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059d0:	ffffc097          	auipc	ra,0xffffc
    800059d4:	ff6080e7          	jalr	-10(ra) # 800019c6 <myproc>
    800059d8:	892a                	mv	s2,a0
  
  begin_op();
    800059da:	ffffe097          	auipc	ra,0xffffe
    800059de:	7a2080e7          	jalr	1954(ra) # 8000417c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059e2:	08000613          	li	a2,128
    800059e6:	f6040593          	addi	a1,s0,-160
    800059ea:	4501                	li	a0,0
    800059ec:	ffffd097          	auipc	ra,0xffffd
    800059f0:	1a2080e7          	jalr	418(ra) # 80002b8e <argstr>
    800059f4:	04054b63          	bltz	a0,80005a4a <sys_chdir+0x86>
    800059f8:	f6040513          	addi	a0,s0,-160
    800059fc:	ffffe097          	auipc	ra,0xffffe
    80005a00:	564080e7          	jalr	1380(ra) # 80003f60 <namei>
    80005a04:	84aa                	mv	s1,a0
    80005a06:	c131                	beqz	a0,80005a4a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a08:	ffffe097          	auipc	ra,0xffffe
    80005a0c:	db2080e7          	jalr	-590(ra) # 800037ba <ilock>
  if(ip->type != T_DIR){
    80005a10:	04449703          	lh	a4,68(s1)
    80005a14:	4785                	li	a5,1
    80005a16:	04f71063          	bne	a4,a5,80005a56 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a1a:	8526                	mv	a0,s1
    80005a1c:	ffffe097          	auipc	ra,0xffffe
    80005a20:	e60080e7          	jalr	-416(ra) # 8000387c <iunlock>
  iput(p->cwd);
    80005a24:	15093503          	ld	a0,336(s2)
    80005a28:	ffffe097          	auipc	ra,0xffffe
    80005a2c:	f4c080e7          	jalr	-180(ra) # 80003974 <iput>
  end_op();
    80005a30:	ffffe097          	auipc	ra,0xffffe
    80005a34:	7cc080e7          	jalr	1996(ra) # 800041fc <end_op>
  p->cwd = ip;
    80005a38:	14993823          	sd	s1,336(s2)
  return 0;
    80005a3c:	4501                	li	a0,0
}
    80005a3e:	60ea                	ld	ra,152(sp)
    80005a40:	644a                	ld	s0,144(sp)
    80005a42:	64aa                	ld	s1,136(sp)
    80005a44:	690a                	ld	s2,128(sp)
    80005a46:	610d                	addi	sp,sp,160
    80005a48:	8082                	ret
    end_op();
    80005a4a:	ffffe097          	auipc	ra,0xffffe
    80005a4e:	7b2080e7          	jalr	1970(ra) # 800041fc <end_op>
    return -1;
    80005a52:	557d                	li	a0,-1
    80005a54:	b7ed                	j	80005a3e <sys_chdir+0x7a>
    iunlockput(ip);
    80005a56:	8526                	mv	a0,s1
    80005a58:	ffffe097          	auipc	ra,0xffffe
    80005a5c:	fc4080e7          	jalr	-60(ra) # 80003a1c <iunlockput>
    end_op();
    80005a60:	ffffe097          	auipc	ra,0xffffe
    80005a64:	79c080e7          	jalr	1948(ra) # 800041fc <end_op>
    return -1;
    80005a68:	557d                	li	a0,-1
    80005a6a:	bfd1                	j	80005a3e <sys_chdir+0x7a>

0000000080005a6c <sys_exec>:

uint64
sys_exec(void)
{
    80005a6c:	7145                	addi	sp,sp,-464
    80005a6e:	e786                	sd	ra,456(sp)
    80005a70:	e3a2                	sd	s0,448(sp)
    80005a72:	ff26                	sd	s1,440(sp)
    80005a74:	fb4a                	sd	s2,432(sp)
    80005a76:	f74e                	sd	s3,424(sp)
    80005a78:	f352                	sd	s4,416(sp)
    80005a7a:	ef56                	sd	s5,408(sp)
    80005a7c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005a7e:	e3840593          	addi	a1,s0,-456
    80005a82:	4505                	li	a0,1
    80005a84:	ffffd097          	auipc	ra,0xffffd
    80005a88:	0ea080e7          	jalr	234(ra) # 80002b6e <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005a8c:	08000613          	li	a2,128
    80005a90:	f4040593          	addi	a1,s0,-192
    80005a94:	4501                	li	a0,0
    80005a96:	ffffd097          	auipc	ra,0xffffd
    80005a9a:	0f8080e7          	jalr	248(ra) # 80002b8e <argstr>
    80005a9e:	87aa                	mv	a5,a0
    return -1;
    80005aa0:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005aa2:	0c07c263          	bltz	a5,80005b66 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005aa6:	10000613          	li	a2,256
    80005aaa:	4581                	li	a1,0
    80005aac:	e4040513          	addi	a0,s0,-448
    80005ab0:	ffffb097          	auipc	ra,0xffffb
    80005ab4:	236080e7          	jalr	566(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ab8:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005abc:	89a6                	mv	s3,s1
    80005abe:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ac0:	02000a13          	li	s4,32
    80005ac4:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ac8:	00391513          	slli	a0,s2,0x3
    80005acc:	e3040593          	addi	a1,s0,-464
    80005ad0:	e3843783          	ld	a5,-456(s0)
    80005ad4:	953e                	add	a0,a0,a5
    80005ad6:	ffffd097          	auipc	ra,0xffffd
    80005ada:	fda080e7          	jalr	-38(ra) # 80002ab0 <fetchaddr>
    80005ade:	02054a63          	bltz	a0,80005b12 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005ae2:	e3043783          	ld	a5,-464(s0)
    80005ae6:	c3b9                	beqz	a5,80005b2c <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ae8:	ffffb097          	auipc	ra,0xffffb
    80005aec:	012080e7          	jalr	18(ra) # 80000afa <kalloc>
    80005af0:	85aa                	mv	a1,a0
    80005af2:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005af6:	cd11                	beqz	a0,80005b12 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005af8:	6605                	lui	a2,0x1
    80005afa:	e3043503          	ld	a0,-464(s0)
    80005afe:	ffffd097          	auipc	ra,0xffffd
    80005b02:	004080e7          	jalr	4(ra) # 80002b02 <fetchstr>
    80005b06:	00054663          	bltz	a0,80005b12 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005b0a:	0905                	addi	s2,s2,1
    80005b0c:	09a1                	addi	s3,s3,8
    80005b0e:	fb491be3          	bne	s2,s4,80005ac4 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b12:	10048913          	addi	s2,s1,256
    80005b16:	6088                	ld	a0,0(s1)
    80005b18:	c531                	beqz	a0,80005b64 <sys_exec+0xf8>
    kfree(argv[i]);
    80005b1a:	ffffb097          	auipc	ra,0xffffb
    80005b1e:	ee4080e7          	jalr	-284(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b22:	04a1                	addi	s1,s1,8
    80005b24:	ff2499e3          	bne	s1,s2,80005b16 <sys_exec+0xaa>
  return -1;
    80005b28:	557d                	li	a0,-1
    80005b2a:	a835                	j	80005b66 <sys_exec+0xfa>
      argv[i] = 0;
    80005b2c:	0a8e                	slli	s5,s5,0x3
    80005b2e:	fc040793          	addi	a5,s0,-64
    80005b32:	9abe                	add	s5,s5,a5
    80005b34:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b38:	e4040593          	addi	a1,s0,-448
    80005b3c:	f4040513          	addi	a0,s0,-192
    80005b40:	fffff097          	auipc	ra,0xfffff
    80005b44:	190080e7          	jalr	400(ra) # 80004cd0 <exec>
    80005b48:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b4a:	10048993          	addi	s3,s1,256
    80005b4e:	6088                	ld	a0,0(s1)
    80005b50:	c901                	beqz	a0,80005b60 <sys_exec+0xf4>
    kfree(argv[i]);
    80005b52:	ffffb097          	auipc	ra,0xffffb
    80005b56:	eac080e7          	jalr	-340(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b5a:	04a1                	addi	s1,s1,8
    80005b5c:	ff3499e3          	bne	s1,s3,80005b4e <sys_exec+0xe2>
  return ret;
    80005b60:	854a                	mv	a0,s2
    80005b62:	a011                	j	80005b66 <sys_exec+0xfa>
  return -1;
    80005b64:	557d                	li	a0,-1
}
    80005b66:	60be                	ld	ra,456(sp)
    80005b68:	641e                	ld	s0,448(sp)
    80005b6a:	74fa                	ld	s1,440(sp)
    80005b6c:	795a                	ld	s2,432(sp)
    80005b6e:	79ba                	ld	s3,424(sp)
    80005b70:	7a1a                	ld	s4,416(sp)
    80005b72:	6afa                	ld	s5,408(sp)
    80005b74:	6179                	addi	sp,sp,464
    80005b76:	8082                	ret

0000000080005b78 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b78:	7139                	addi	sp,sp,-64
    80005b7a:	fc06                	sd	ra,56(sp)
    80005b7c:	f822                	sd	s0,48(sp)
    80005b7e:	f426                	sd	s1,40(sp)
    80005b80:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b82:	ffffc097          	auipc	ra,0xffffc
    80005b86:	e44080e7          	jalr	-444(ra) # 800019c6 <myproc>
    80005b8a:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005b8c:	fd840593          	addi	a1,s0,-40
    80005b90:	4501                	li	a0,0
    80005b92:	ffffd097          	auipc	ra,0xffffd
    80005b96:	fdc080e7          	jalr	-36(ra) # 80002b6e <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005b9a:	fc840593          	addi	a1,s0,-56
    80005b9e:	fd040513          	addi	a0,s0,-48
    80005ba2:	fffff097          	auipc	ra,0xfffff
    80005ba6:	dd6080e7          	jalr	-554(ra) # 80004978 <pipealloc>
    return -1;
    80005baa:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005bac:	0c054463          	bltz	a0,80005c74 <sys_pipe+0xfc>
  fd0 = -1;
    80005bb0:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005bb4:	fd043503          	ld	a0,-48(s0)
    80005bb8:	fffff097          	auipc	ra,0xfffff
    80005bbc:	518080e7          	jalr	1304(ra) # 800050d0 <fdalloc>
    80005bc0:	fca42223          	sw	a0,-60(s0)
    80005bc4:	08054b63          	bltz	a0,80005c5a <sys_pipe+0xe2>
    80005bc8:	fc843503          	ld	a0,-56(s0)
    80005bcc:	fffff097          	auipc	ra,0xfffff
    80005bd0:	504080e7          	jalr	1284(ra) # 800050d0 <fdalloc>
    80005bd4:	fca42023          	sw	a0,-64(s0)
    80005bd8:	06054863          	bltz	a0,80005c48 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bdc:	4691                	li	a3,4
    80005bde:	fc440613          	addi	a2,s0,-60
    80005be2:	fd843583          	ld	a1,-40(s0)
    80005be6:	68a8                	ld	a0,80(s1)
    80005be8:	ffffc097          	auipc	ra,0xffffc
    80005bec:	a9c080e7          	jalr	-1380(ra) # 80001684 <copyout>
    80005bf0:	02054063          	bltz	a0,80005c10 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bf4:	4691                	li	a3,4
    80005bf6:	fc040613          	addi	a2,s0,-64
    80005bfa:	fd843583          	ld	a1,-40(s0)
    80005bfe:	0591                	addi	a1,a1,4
    80005c00:	68a8                	ld	a0,80(s1)
    80005c02:	ffffc097          	auipc	ra,0xffffc
    80005c06:	a82080e7          	jalr	-1406(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c0a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c0c:	06055463          	bgez	a0,80005c74 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005c10:	fc442783          	lw	a5,-60(s0)
    80005c14:	07e9                	addi	a5,a5,26
    80005c16:	078e                	slli	a5,a5,0x3
    80005c18:	97a6                	add	a5,a5,s1
    80005c1a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c1e:	fc042503          	lw	a0,-64(s0)
    80005c22:	0569                	addi	a0,a0,26
    80005c24:	050e                	slli	a0,a0,0x3
    80005c26:	94aa                	add	s1,s1,a0
    80005c28:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c2c:	fd043503          	ld	a0,-48(s0)
    80005c30:	fffff097          	auipc	ra,0xfffff
    80005c34:	a18080e7          	jalr	-1512(ra) # 80004648 <fileclose>
    fileclose(wf);
    80005c38:	fc843503          	ld	a0,-56(s0)
    80005c3c:	fffff097          	auipc	ra,0xfffff
    80005c40:	a0c080e7          	jalr	-1524(ra) # 80004648 <fileclose>
    return -1;
    80005c44:	57fd                	li	a5,-1
    80005c46:	a03d                	j	80005c74 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005c48:	fc442783          	lw	a5,-60(s0)
    80005c4c:	0007c763          	bltz	a5,80005c5a <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005c50:	07e9                	addi	a5,a5,26
    80005c52:	078e                	slli	a5,a5,0x3
    80005c54:	94be                	add	s1,s1,a5
    80005c56:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c5a:	fd043503          	ld	a0,-48(s0)
    80005c5e:	fffff097          	auipc	ra,0xfffff
    80005c62:	9ea080e7          	jalr	-1558(ra) # 80004648 <fileclose>
    fileclose(wf);
    80005c66:	fc843503          	ld	a0,-56(s0)
    80005c6a:	fffff097          	auipc	ra,0xfffff
    80005c6e:	9de080e7          	jalr	-1570(ra) # 80004648 <fileclose>
    return -1;
    80005c72:	57fd                	li	a5,-1
}
    80005c74:	853e                	mv	a0,a5
    80005c76:	70e2                	ld	ra,56(sp)
    80005c78:	7442                	ld	s0,48(sp)
    80005c7a:	74a2                	ld	s1,40(sp)
    80005c7c:	6121                	addi	sp,sp,64
    80005c7e:	8082                	ret

0000000080005c80 <kernelvec>:
    80005c80:	7111                	addi	sp,sp,-256
    80005c82:	e006                	sd	ra,0(sp)
    80005c84:	e40a                	sd	sp,8(sp)
    80005c86:	e80e                	sd	gp,16(sp)
    80005c88:	ec12                	sd	tp,24(sp)
    80005c8a:	f016                	sd	t0,32(sp)
    80005c8c:	f41a                	sd	t1,40(sp)
    80005c8e:	f81e                	sd	t2,48(sp)
    80005c90:	fc22                	sd	s0,56(sp)
    80005c92:	e0a6                	sd	s1,64(sp)
    80005c94:	e4aa                	sd	a0,72(sp)
    80005c96:	e8ae                	sd	a1,80(sp)
    80005c98:	ecb2                	sd	a2,88(sp)
    80005c9a:	f0b6                	sd	a3,96(sp)
    80005c9c:	f4ba                	sd	a4,104(sp)
    80005c9e:	f8be                	sd	a5,112(sp)
    80005ca0:	fcc2                	sd	a6,120(sp)
    80005ca2:	e146                	sd	a7,128(sp)
    80005ca4:	e54a                	sd	s2,136(sp)
    80005ca6:	e94e                	sd	s3,144(sp)
    80005ca8:	ed52                	sd	s4,152(sp)
    80005caa:	f156                	sd	s5,160(sp)
    80005cac:	f55a                	sd	s6,168(sp)
    80005cae:	f95e                	sd	s7,176(sp)
    80005cb0:	fd62                	sd	s8,184(sp)
    80005cb2:	e1e6                	sd	s9,192(sp)
    80005cb4:	e5ea                	sd	s10,200(sp)
    80005cb6:	e9ee                	sd	s11,208(sp)
    80005cb8:	edf2                	sd	t3,216(sp)
    80005cba:	f1f6                	sd	t4,224(sp)
    80005cbc:	f5fa                	sd	t5,232(sp)
    80005cbe:	f9fe                	sd	t6,240(sp)
    80005cc0:	cbdfc0ef          	jal	ra,8000297c <kerneltrap>
    80005cc4:	6082                	ld	ra,0(sp)
    80005cc6:	6122                	ld	sp,8(sp)
    80005cc8:	61c2                	ld	gp,16(sp)
    80005cca:	7282                	ld	t0,32(sp)
    80005ccc:	7322                	ld	t1,40(sp)
    80005cce:	73c2                	ld	t2,48(sp)
    80005cd0:	7462                	ld	s0,56(sp)
    80005cd2:	6486                	ld	s1,64(sp)
    80005cd4:	6526                	ld	a0,72(sp)
    80005cd6:	65c6                	ld	a1,80(sp)
    80005cd8:	6666                	ld	a2,88(sp)
    80005cda:	7686                	ld	a3,96(sp)
    80005cdc:	7726                	ld	a4,104(sp)
    80005cde:	77c6                	ld	a5,112(sp)
    80005ce0:	7866                	ld	a6,120(sp)
    80005ce2:	688a                	ld	a7,128(sp)
    80005ce4:	692a                	ld	s2,136(sp)
    80005ce6:	69ca                	ld	s3,144(sp)
    80005ce8:	6a6a                	ld	s4,152(sp)
    80005cea:	7a8a                	ld	s5,160(sp)
    80005cec:	7b2a                	ld	s6,168(sp)
    80005cee:	7bca                	ld	s7,176(sp)
    80005cf0:	7c6a                	ld	s8,184(sp)
    80005cf2:	6c8e                	ld	s9,192(sp)
    80005cf4:	6d2e                	ld	s10,200(sp)
    80005cf6:	6dce                	ld	s11,208(sp)
    80005cf8:	6e6e                	ld	t3,216(sp)
    80005cfa:	7e8e                	ld	t4,224(sp)
    80005cfc:	7f2e                	ld	t5,232(sp)
    80005cfe:	7fce                	ld	t6,240(sp)
    80005d00:	6111                	addi	sp,sp,256
    80005d02:	10200073          	sret
    80005d06:	00000013          	nop
    80005d0a:	00000013          	nop
    80005d0e:	0001                	nop

0000000080005d10 <timervec>:
    80005d10:	34051573          	csrrw	a0,mscratch,a0
    80005d14:	e10c                	sd	a1,0(a0)
    80005d16:	e510                	sd	a2,8(a0)
    80005d18:	e914                	sd	a3,16(a0)
    80005d1a:	6d0c                	ld	a1,24(a0)
    80005d1c:	7110                	ld	a2,32(a0)
    80005d1e:	6194                	ld	a3,0(a1)
    80005d20:	96b2                	add	a3,a3,a2
    80005d22:	e194                	sd	a3,0(a1)
    80005d24:	4589                	li	a1,2
    80005d26:	14459073          	csrw	sip,a1
    80005d2a:	6914                	ld	a3,16(a0)
    80005d2c:	6510                	ld	a2,8(a0)
    80005d2e:	610c                	ld	a1,0(a0)
    80005d30:	34051573          	csrrw	a0,mscratch,a0
    80005d34:	30200073          	mret
	...

0000000080005d3a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d3a:	1141                	addi	sp,sp,-16
    80005d3c:	e422                	sd	s0,8(sp)
    80005d3e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d40:	0c0007b7          	lui	a5,0xc000
    80005d44:	4705                	li	a4,1
    80005d46:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d48:	c3d8                	sw	a4,4(a5)
}
    80005d4a:	6422                	ld	s0,8(sp)
    80005d4c:	0141                	addi	sp,sp,16
    80005d4e:	8082                	ret

0000000080005d50 <plicinithart>:

void
plicinithart(void)
{
    80005d50:	1141                	addi	sp,sp,-16
    80005d52:	e406                	sd	ra,8(sp)
    80005d54:	e022                	sd	s0,0(sp)
    80005d56:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d58:	ffffc097          	auipc	ra,0xffffc
    80005d5c:	c42080e7          	jalr	-958(ra) # 8000199a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d60:	0085171b          	slliw	a4,a0,0x8
    80005d64:	0c0027b7          	lui	a5,0xc002
    80005d68:	97ba                	add	a5,a5,a4
    80005d6a:	40200713          	li	a4,1026
    80005d6e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d72:	00d5151b          	slliw	a0,a0,0xd
    80005d76:	0c2017b7          	lui	a5,0xc201
    80005d7a:	953e                	add	a0,a0,a5
    80005d7c:	00052023          	sw	zero,0(a0)
}
    80005d80:	60a2                	ld	ra,8(sp)
    80005d82:	6402                	ld	s0,0(sp)
    80005d84:	0141                	addi	sp,sp,16
    80005d86:	8082                	ret

0000000080005d88 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d88:	1141                	addi	sp,sp,-16
    80005d8a:	e406                	sd	ra,8(sp)
    80005d8c:	e022                	sd	s0,0(sp)
    80005d8e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d90:	ffffc097          	auipc	ra,0xffffc
    80005d94:	c0a080e7          	jalr	-1014(ra) # 8000199a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d98:	00d5179b          	slliw	a5,a0,0xd
    80005d9c:	0c201537          	lui	a0,0xc201
    80005da0:	953e                	add	a0,a0,a5
  return irq;
}
    80005da2:	4148                	lw	a0,4(a0)
    80005da4:	60a2                	ld	ra,8(sp)
    80005da6:	6402                	ld	s0,0(sp)
    80005da8:	0141                	addi	sp,sp,16
    80005daa:	8082                	ret

0000000080005dac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005dac:	1101                	addi	sp,sp,-32
    80005dae:	ec06                	sd	ra,24(sp)
    80005db0:	e822                	sd	s0,16(sp)
    80005db2:	e426                	sd	s1,8(sp)
    80005db4:	1000                	addi	s0,sp,32
    80005db6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005db8:	ffffc097          	auipc	ra,0xffffc
    80005dbc:	be2080e7          	jalr	-1054(ra) # 8000199a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005dc0:	00d5151b          	slliw	a0,a0,0xd
    80005dc4:	0c2017b7          	lui	a5,0xc201
    80005dc8:	97aa                	add	a5,a5,a0
    80005dca:	c3c4                	sw	s1,4(a5)
}
    80005dcc:	60e2                	ld	ra,24(sp)
    80005dce:	6442                	ld	s0,16(sp)
    80005dd0:	64a2                	ld	s1,8(sp)
    80005dd2:	6105                	addi	sp,sp,32
    80005dd4:	8082                	ret

0000000080005dd6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005dd6:	1141                	addi	sp,sp,-16
    80005dd8:	e406                	sd	ra,8(sp)
    80005dda:	e022                	sd	s0,0(sp)
    80005ddc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dde:	479d                	li	a5,7
    80005de0:	04a7cc63          	blt	a5,a0,80005e38 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005de4:	0001d797          	auipc	a5,0x1d
    80005de8:	a0c78793          	addi	a5,a5,-1524 # 800227f0 <disk>
    80005dec:	97aa                	add	a5,a5,a0
    80005dee:	0187c783          	lbu	a5,24(a5)
    80005df2:	ebb9                	bnez	a5,80005e48 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005df4:	00451613          	slli	a2,a0,0x4
    80005df8:	0001d797          	auipc	a5,0x1d
    80005dfc:	9f878793          	addi	a5,a5,-1544 # 800227f0 <disk>
    80005e00:	6394                	ld	a3,0(a5)
    80005e02:	96b2                	add	a3,a3,a2
    80005e04:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005e08:	6398                	ld	a4,0(a5)
    80005e0a:	9732                	add	a4,a4,a2
    80005e0c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005e10:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005e14:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005e18:	953e                	add	a0,a0,a5
    80005e1a:	4785                	li	a5,1
    80005e1c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005e20:	0001d517          	auipc	a0,0x1d
    80005e24:	9e850513          	addi	a0,a0,-1560 # 80022808 <disk+0x18>
    80005e28:	ffffc097          	auipc	ra,0xffffc
    80005e2c:	2ba080e7          	jalr	698(ra) # 800020e2 <wakeup>
}
    80005e30:	60a2                	ld	ra,8(sp)
    80005e32:	6402                	ld	s0,0(sp)
    80005e34:	0141                	addi	sp,sp,16
    80005e36:	8082                	ret
    panic("free_desc 1");
    80005e38:	00003517          	auipc	a0,0x3
    80005e3c:	a0050513          	addi	a0,a0,-1536 # 80008838 <syscalls+0x308>
    80005e40:	ffffa097          	auipc	ra,0xffffa
    80005e44:	704080e7          	jalr	1796(ra) # 80000544 <panic>
    panic("free_desc 2");
    80005e48:	00003517          	auipc	a0,0x3
    80005e4c:	a0050513          	addi	a0,a0,-1536 # 80008848 <syscalls+0x318>
    80005e50:	ffffa097          	auipc	ra,0xffffa
    80005e54:	6f4080e7          	jalr	1780(ra) # 80000544 <panic>

0000000080005e58 <virtio_disk_init>:
{
    80005e58:	1101                	addi	sp,sp,-32
    80005e5a:	ec06                	sd	ra,24(sp)
    80005e5c:	e822                	sd	s0,16(sp)
    80005e5e:	e426                	sd	s1,8(sp)
    80005e60:	e04a                	sd	s2,0(sp)
    80005e62:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e64:	00003597          	auipc	a1,0x3
    80005e68:	9f458593          	addi	a1,a1,-1548 # 80008858 <syscalls+0x328>
    80005e6c:	0001d517          	auipc	a0,0x1d
    80005e70:	aac50513          	addi	a0,a0,-1364 # 80022918 <disk+0x128>
    80005e74:	ffffb097          	auipc	ra,0xffffb
    80005e78:	ce6080e7          	jalr	-794(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e7c:	100017b7          	lui	a5,0x10001
    80005e80:	4398                	lw	a4,0(a5)
    80005e82:	2701                	sext.w	a4,a4
    80005e84:	747277b7          	lui	a5,0x74727
    80005e88:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e8c:	14f71e63          	bne	a4,a5,80005fe8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e90:	100017b7          	lui	a5,0x10001
    80005e94:	43dc                	lw	a5,4(a5)
    80005e96:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e98:	4709                	li	a4,2
    80005e9a:	14e79763          	bne	a5,a4,80005fe8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e9e:	100017b7          	lui	a5,0x10001
    80005ea2:	479c                	lw	a5,8(a5)
    80005ea4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005ea6:	14e79163          	bne	a5,a4,80005fe8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005eaa:	100017b7          	lui	a5,0x10001
    80005eae:	47d8                	lw	a4,12(a5)
    80005eb0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005eb2:	554d47b7          	lui	a5,0x554d4
    80005eb6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005eba:	12f71763          	bne	a4,a5,80005fe8 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ebe:	100017b7          	lui	a5,0x10001
    80005ec2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ec6:	4705                	li	a4,1
    80005ec8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eca:	470d                	li	a4,3
    80005ecc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005ece:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005ed0:	c7ffe737          	lui	a4,0xc7ffe
    80005ed4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdbe2f>
    80005ed8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005eda:	2701                	sext.w	a4,a4
    80005edc:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ede:	472d                	li	a4,11
    80005ee0:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005ee2:	0707a903          	lw	s2,112(a5)
    80005ee6:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005ee8:	00897793          	andi	a5,s2,8
    80005eec:	10078663          	beqz	a5,80005ff8 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005ef0:	100017b7          	lui	a5,0x10001
    80005ef4:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005ef8:	43fc                	lw	a5,68(a5)
    80005efa:	2781                	sext.w	a5,a5
    80005efc:	10079663          	bnez	a5,80006008 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f00:	100017b7          	lui	a5,0x10001
    80005f04:	5bdc                	lw	a5,52(a5)
    80005f06:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f08:	10078863          	beqz	a5,80006018 <virtio_disk_init+0x1c0>
  if(max < NUM)
    80005f0c:	471d                	li	a4,7
    80005f0e:	10f77d63          	bgeu	a4,a5,80006028 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80005f12:	ffffb097          	auipc	ra,0xffffb
    80005f16:	be8080e7          	jalr	-1048(ra) # 80000afa <kalloc>
    80005f1a:	0001d497          	auipc	s1,0x1d
    80005f1e:	8d648493          	addi	s1,s1,-1834 # 800227f0 <disk>
    80005f22:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005f24:	ffffb097          	auipc	ra,0xffffb
    80005f28:	bd6080e7          	jalr	-1066(ra) # 80000afa <kalloc>
    80005f2c:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005f2e:	ffffb097          	auipc	ra,0xffffb
    80005f32:	bcc080e7          	jalr	-1076(ra) # 80000afa <kalloc>
    80005f36:	87aa                	mv	a5,a0
    80005f38:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005f3a:	6088                	ld	a0,0(s1)
    80005f3c:	cd75                	beqz	a0,80006038 <virtio_disk_init+0x1e0>
    80005f3e:	0001d717          	auipc	a4,0x1d
    80005f42:	8ba73703          	ld	a4,-1862(a4) # 800227f8 <disk+0x8>
    80005f46:	cb6d                	beqz	a4,80006038 <virtio_disk_init+0x1e0>
    80005f48:	cbe5                	beqz	a5,80006038 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    80005f4a:	6605                	lui	a2,0x1
    80005f4c:	4581                	li	a1,0
    80005f4e:	ffffb097          	auipc	ra,0xffffb
    80005f52:	d98080e7          	jalr	-616(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005f56:	0001d497          	auipc	s1,0x1d
    80005f5a:	89a48493          	addi	s1,s1,-1894 # 800227f0 <disk>
    80005f5e:	6605                	lui	a2,0x1
    80005f60:	4581                	li	a1,0
    80005f62:	6488                	ld	a0,8(s1)
    80005f64:	ffffb097          	auipc	ra,0xffffb
    80005f68:	d82080e7          	jalr	-638(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    80005f6c:	6605                	lui	a2,0x1
    80005f6e:	4581                	li	a1,0
    80005f70:	6888                	ld	a0,16(s1)
    80005f72:	ffffb097          	auipc	ra,0xffffb
    80005f76:	d74080e7          	jalr	-652(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f7a:	100017b7          	lui	a5,0x10001
    80005f7e:	4721                	li	a4,8
    80005f80:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005f82:	4098                	lw	a4,0(s1)
    80005f84:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005f88:	40d8                	lw	a4,4(s1)
    80005f8a:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005f8e:	6498                	ld	a4,8(s1)
    80005f90:	0007069b          	sext.w	a3,a4
    80005f94:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005f98:	9701                	srai	a4,a4,0x20
    80005f9a:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005f9e:	6898                	ld	a4,16(s1)
    80005fa0:	0007069b          	sext.w	a3,a4
    80005fa4:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005fa8:	9701                	srai	a4,a4,0x20
    80005faa:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005fae:	4685                	li	a3,1
    80005fb0:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80005fb2:	4705                	li	a4,1
    80005fb4:	00d48c23          	sb	a3,24(s1)
    80005fb8:	00e48ca3          	sb	a4,25(s1)
    80005fbc:	00e48d23          	sb	a4,26(s1)
    80005fc0:	00e48da3          	sb	a4,27(s1)
    80005fc4:	00e48e23          	sb	a4,28(s1)
    80005fc8:	00e48ea3          	sb	a4,29(s1)
    80005fcc:	00e48f23          	sb	a4,30(s1)
    80005fd0:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005fd4:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fd8:	0727a823          	sw	s2,112(a5)
}
    80005fdc:	60e2                	ld	ra,24(sp)
    80005fde:	6442                	ld	s0,16(sp)
    80005fe0:	64a2                	ld	s1,8(sp)
    80005fe2:	6902                	ld	s2,0(sp)
    80005fe4:	6105                	addi	sp,sp,32
    80005fe6:	8082                	ret
    panic("could not find virtio disk");
    80005fe8:	00003517          	auipc	a0,0x3
    80005fec:	88050513          	addi	a0,a0,-1920 # 80008868 <syscalls+0x338>
    80005ff0:	ffffa097          	auipc	ra,0xffffa
    80005ff4:	554080e7          	jalr	1364(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80005ff8:	00003517          	auipc	a0,0x3
    80005ffc:	89050513          	addi	a0,a0,-1904 # 80008888 <syscalls+0x358>
    80006000:	ffffa097          	auipc	ra,0xffffa
    80006004:	544080e7          	jalr	1348(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80006008:	00003517          	auipc	a0,0x3
    8000600c:	8a050513          	addi	a0,a0,-1888 # 800088a8 <syscalls+0x378>
    80006010:	ffffa097          	auipc	ra,0xffffa
    80006014:	534080e7          	jalr	1332(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80006018:	00003517          	auipc	a0,0x3
    8000601c:	8b050513          	addi	a0,a0,-1872 # 800088c8 <syscalls+0x398>
    80006020:	ffffa097          	auipc	ra,0xffffa
    80006024:	524080e7          	jalr	1316(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    80006028:	00003517          	auipc	a0,0x3
    8000602c:	8c050513          	addi	a0,a0,-1856 # 800088e8 <syscalls+0x3b8>
    80006030:	ffffa097          	auipc	ra,0xffffa
    80006034:	514080e7          	jalr	1300(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    80006038:	00003517          	auipc	a0,0x3
    8000603c:	8d050513          	addi	a0,a0,-1840 # 80008908 <syscalls+0x3d8>
    80006040:	ffffa097          	auipc	ra,0xffffa
    80006044:	504080e7          	jalr	1284(ra) # 80000544 <panic>

0000000080006048 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006048:	7159                	addi	sp,sp,-112
    8000604a:	f486                	sd	ra,104(sp)
    8000604c:	f0a2                	sd	s0,96(sp)
    8000604e:	eca6                	sd	s1,88(sp)
    80006050:	e8ca                	sd	s2,80(sp)
    80006052:	e4ce                	sd	s3,72(sp)
    80006054:	e0d2                	sd	s4,64(sp)
    80006056:	fc56                	sd	s5,56(sp)
    80006058:	f85a                	sd	s6,48(sp)
    8000605a:	f45e                	sd	s7,40(sp)
    8000605c:	f062                	sd	s8,32(sp)
    8000605e:	ec66                	sd	s9,24(sp)
    80006060:	e86a                	sd	s10,16(sp)
    80006062:	1880                	addi	s0,sp,112
    80006064:	892a                	mv	s2,a0
    80006066:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006068:	00c52c83          	lw	s9,12(a0)
    8000606c:	001c9c9b          	slliw	s9,s9,0x1
    80006070:	1c82                	slli	s9,s9,0x20
    80006072:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006076:	0001d517          	auipc	a0,0x1d
    8000607a:	8a250513          	addi	a0,a0,-1886 # 80022918 <disk+0x128>
    8000607e:	ffffb097          	auipc	ra,0xffffb
    80006082:	b6c080e7          	jalr	-1172(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    80006086:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006088:	4ba1                	li	s7,8
      disk.free[i] = 0;
    8000608a:	0001cb17          	auipc	s6,0x1c
    8000608e:	766b0b13          	addi	s6,s6,1894 # 800227f0 <disk>
  for(int i = 0; i < 3; i++){
    80006092:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006094:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006096:	0001dc17          	auipc	s8,0x1d
    8000609a:	882c0c13          	addi	s8,s8,-1918 # 80022918 <disk+0x128>
    8000609e:	a8b5                	j	8000611a <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    800060a0:	00fb06b3          	add	a3,s6,a5
    800060a4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800060a8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800060aa:	0207c563          	bltz	a5,800060d4 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800060ae:	2485                	addiw	s1,s1,1
    800060b0:	0711                	addi	a4,a4,4
    800060b2:	1f548a63          	beq	s1,s5,800062a6 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    800060b6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800060b8:	0001c697          	auipc	a3,0x1c
    800060bc:	73868693          	addi	a3,a3,1848 # 800227f0 <disk>
    800060c0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800060c2:	0186c583          	lbu	a1,24(a3)
    800060c6:	fde9                	bnez	a1,800060a0 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800060c8:	2785                	addiw	a5,a5,1
    800060ca:	0685                	addi	a3,a3,1
    800060cc:	ff779be3          	bne	a5,s7,800060c2 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800060d0:	57fd                	li	a5,-1
    800060d2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800060d4:	02905a63          	blez	s1,80006108 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800060d8:	f9042503          	lw	a0,-112(s0)
    800060dc:	00000097          	auipc	ra,0x0
    800060e0:	cfa080e7          	jalr	-774(ra) # 80005dd6 <free_desc>
      for(int j = 0; j < i; j++)
    800060e4:	4785                	li	a5,1
    800060e6:	0297d163          	bge	a5,s1,80006108 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800060ea:	f9442503          	lw	a0,-108(s0)
    800060ee:	00000097          	auipc	ra,0x0
    800060f2:	ce8080e7          	jalr	-792(ra) # 80005dd6 <free_desc>
      for(int j = 0; j < i; j++)
    800060f6:	4789                	li	a5,2
    800060f8:	0097d863          	bge	a5,s1,80006108 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800060fc:	f9842503          	lw	a0,-104(s0)
    80006100:	00000097          	auipc	ra,0x0
    80006104:	cd6080e7          	jalr	-810(ra) # 80005dd6 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006108:	85e2                	mv	a1,s8
    8000610a:	0001c517          	auipc	a0,0x1c
    8000610e:	6fe50513          	addi	a0,a0,1790 # 80022808 <disk+0x18>
    80006112:	ffffc097          	auipc	ra,0xffffc
    80006116:	f6c080e7          	jalr	-148(ra) # 8000207e <sleep>
  for(int i = 0; i < 3; i++){
    8000611a:	f9040713          	addi	a4,s0,-112
    8000611e:	84ce                	mv	s1,s3
    80006120:	bf59                	j	800060b6 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006122:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    80006126:	00479693          	slli	a3,a5,0x4
    8000612a:	0001c797          	auipc	a5,0x1c
    8000612e:	6c678793          	addi	a5,a5,1734 # 800227f0 <disk>
    80006132:	97b6                	add	a5,a5,a3
    80006134:	4685                	li	a3,1
    80006136:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006138:	0001c597          	auipc	a1,0x1c
    8000613c:	6b858593          	addi	a1,a1,1720 # 800227f0 <disk>
    80006140:	00a60793          	addi	a5,a2,10
    80006144:	0792                	slli	a5,a5,0x4
    80006146:	97ae                	add	a5,a5,a1
    80006148:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    8000614c:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006150:	f6070693          	addi	a3,a4,-160
    80006154:	619c                	ld	a5,0(a1)
    80006156:	97b6                	add	a5,a5,a3
    80006158:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000615a:	6188                	ld	a0,0(a1)
    8000615c:	96aa                	add	a3,a3,a0
    8000615e:	47c1                	li	a5,16
    80006160:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006162:	4785                	li	a5,1
    80006164:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006168:	f9442783          	lw	a5,-108(s0)
    8000616c:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006170:	0792                	slli	a5,a5,0x4
    80006172:	953e                	add	a0,a0,a5
    80006174:	05890693          	addi	a3,s2,88
    80006178:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000617a:	6188                	ld	a0,0(a1)
    8000617c:	97aa                	add	a5,a5,a0
    8000617e:	40000693          	li	a3,1024
    80006182:	c794                	sw	a3,8(a5)
  if(write)
    80006184:	100d0d63          	beqz	s10,8000629e <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006188:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000618c:	00c7d683          	lhu	a3,12(a5)
    80006190:	0016e693          	ori	a3,a3,1
    80006194:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    80006198:	f9842583          	lw	a1,-104(s0)
    8000619c:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800061a0:	0001c697          	auipc	a3,0x1c
    800061a4:	65068693          	addi	a3,a3,1616 # 800227f0 <disk>
    800061a8:	00260793          	addi	a5,a2,2
    800061ac:	0792                	slli	a5,a5,0x4
    800061ae:	97b6                	add	a5,a5,a3
    800061b0:	587d                	li	a6,-1
    800061b2:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800061b6:	0592                	slli	a1,a1,0x4
    800061b8:	952e                	add	a0,a0,a1
    800061ba:	f9070713          	addi	a4,a4,-112
    800061be:	9736                	add	a4,a4,a3
    800061c0:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    800061c2:	6298                	ld	a4,0(a3)
    800061c4:	972e                	add	a4,a4,a1
    800061c6:	4585                	li	a1,1
    800061c8:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061ca:	4509                	li	a0,2
    800061cc:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    800061d0:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800061d4:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    800061d8:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800061dc:	6698                	ld	a4,8(a3)
    800061de:	00275783          	lhu	a5,2(a4)
    800061e2:	8b9d                	andi	a5,a5,7
    800061e4:	0786                	slli	a5,a5,0x1
    800061e6:	97ba                	add	a5,a5,a4
    800061e8:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    800061ec:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800061f0:	6698                	ld	a4,8(a3)
    800061f2:	00275783          	lhu	a5,2(a4)
    800061f6:	2785                	addiw	a5,a5,1
    800061f8:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800061fc:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006200:	100017b7          	lui	a5,0x10001
    80006204:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006208:	00492703          	lw	a4,4(s2)
    8000620c:	4785                	li	a5,1
    8000620e:	02f71163          	bne	a4,a5,80006230 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    80006212:	0001c997          	auipc	s3,0x1c
    80006216:	70698993          	addi	s3,s3,1798 # 80022918 <disk+0x128>
  while(b->disk == 1) {
    8000621a:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000621c:	85ce                	mv	a1,s3
    8000621e:	854a                	mv	a0,s2
    80006220:	ffffc097          	auipc	ra,0xffffc
    80006224:	e5e080e7          	jalr	-418(ra) # 8000207e <sleep>
  while(b->disk == 1) {
    80006228:	00492783          	lw	a5,4(s2)
    8000622c:	fe9788e3          	beq	a5,s1,8000621c <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    80006230:	f9042903          	lw	s2,-112(s0)
    80006234:	00290793          	addi	a5,s2,2
    80006238:	00479713          	slli	a4,a5,0x4
    8000623c:	0001c797          	auipc	a5,0x1c
    80006240:	5b478793          	addi	a5,a5,1460 # 800227f0 <disk>
    80006244:	97ba                	add	a5,a5,a4
    80006246:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000624a:	0001c997          	auipc	s3,0x1c
    8000624e:	5a698993          	addi	s3,s3,1446 # 800227f0 <disk>
    80006252:	00491713          	slli	a4,s2,0x4
    80006256:	0009b783          	ld	a5,0(s3)
    8000625a:	97ba                	add	a5,a5,a4
    8000625c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006260:	854a                	mv	a0,s2
    80006262:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006266:	00000097          	auipc	ra,0x0
    8000626a:	b70080e7          	jalr	-1168(ra) # 80005dd6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000626e:	8885                	andi	s1,s1,1
    80006270:	f0ed                	bnez	s1,80006252 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006272:	0001c517          	auipc	a0,0x1c
    80006276:	6a650513          	addi	a0,a0,1702 # 80022918 <disk+0x128>
    8000627a:	ffffb097          	auipc	ra,0xffffb
    8000627e:	a24080e7          	jalr	-1500(ra) # 80000c9e <release>
}
    80006282:	70a6                	ld	ra,104(sp)
    80006284:	7406                	ld	s0,96(sp)
    80006286:	64e6                	ld	s1,88(sp)
    80006288:	6946                	ld	s2,80(sp)
    8000628a:	69a6                	ld	s3,72(sp)
    8000628c:	6a06                	ld	s4,64(sp)
    8000628e:	7ae2                	ld	s5,56(sp)
    80006290:	7b42                	ld	s6,48(sp)
    80006292:	7ba2                	ld	s7,40(sp)
    80006294:	7c02                	ld	s8,32(sp)
    80006296:	6ce2                	ld	s9,24(sp)
    80006298:	6d42                	ld	s10,16(sp)
    8000629a:	6165                	addi	sp,sp,112
    8000629c:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000629e:	4689                	li	a3,2
    800062a0:	00d79623          	sh	a3,12(a5)
    800062a4:	b5e5                	j	8000618c <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062a6:	f9042603          	lw	a2,-112(s0)
    800062aa:	00a60713          	addi	a4,a2,10
    800062ae:	0712                	slli	a4,a4,0x4
    800062b0:	0001c517          	auipc	a0,0x1c
    800062b4:	54850513          	addi	a0,a0,1352 # 800227f8 <disk+0x8>
    800062b8:	953a                	add	a0,a0,a4
  if(write)
    800062ba:	e60d14e3          	bnez	s10,80006122 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800062be:	00a60793          	addi	a5,a2,10
    800062c2:	00479693          	slli	a3,a5,0x4
    800062c6:	0001c797          	auipc	a5,0x1c
    800062ca:	52a78793          	addi	a5,a5,1322 # 800227f0 <disk>
    800062ce:	97b6                	add	a5,a5,a3
    800062d0:	0007a423          	sw	zero,8(a5)
    800062d4:	b595                	j	80006138 <virtio_disk_rw+0xf0>

00000000800062d6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800062d6:	1101                	addi	sp,sp,-32
    800062d8:	ec06                	sd	ra,24(sp)
    800062da:	e822                	sd	s0,16(sp)
    800062dc:	e426                	sd	s1,8(sp)
    800062de:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800062e0:	0001c497          	auipc	s1,0x1c
    800062e4:	51048493          	addi	s1,s1,1296 # 800227f0 <disk>
    800062e8:	0001c517          	auipc	a0,0x1c
    800062ec:	63050513          	addi	a0,a0,1584 # 80022918 <disk+0x128>
    800062f0:	ffffb097          	auipc	ra,0xffffb
    800062f4:	8fa080e7          	jalr	-1798(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800062f8:	10001737          	lui	a4,0x10001
    800062fc:	533c                	lw	a5,96(a4)
    800062fe:	8b8d                	andi	a5,a5,3
    80006300:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006302:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006306:	689c                	ld	a5,16(s1)
    80006308:	0204d703          	lhu	a4,32(s1)
    8000630c:	0027d783          	lhu	a5,2(a5)
    80006310:	04f70863          	beq	a4,a5,80006360 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006314:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006318:	6898                	ld	a4,16(s1)
    8000631a:	0204d783          	lhu	a5,32(s1)
    8000631e:	8b9d                	andi	a5,a5,7
    80006320:	078e                	slli	a5,a5,0x3
    80006322:	97ba                	add	a5,a5,a4
    80006324:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006326:	00278713          	addi	a4,a5,2
    8000632a:	0712                	slli	a4,a4,0x4
    8000632c:	9726                	add	a4,a4,s1
    8000632e:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006332:	e721                	bnez	a4,8000637a <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006334:	0789                	addi	a5,a5,2
    80006336:	0792                	slli	a5,a5,0x4
    80006338:	97a6                	add	a5,a5,s1
    8000633a:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000633c:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006340:	ffffc097          	auipc	ra,0xffffc
    80006344:	da2080e7          	jalr	-606(ra) # 800020e2 <wakeup>

    disk.used_idx += 1;
    80006348:	0204d783          	lhu	a5,32(s1)
    8000634c:	2785                	addiw	a5,a5,1
    8000634e:	17c2                	slli	a5,a5,0x30
    80006350:	93c1                	srli	a5,a5,0x30
    80006352:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006356:	6898                	ld	a4,16(s1)
    80006358:	00275703          	lhu	a4,2(a4)
    8000635c:	faf71ce3          	bne	a4,a5,80006314 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006360:	0001c517          	auipc	a0,0x1c
    80006364:	5b850513          	addi	a0,a0,1464 # 80022918 <disk+0x128>
    80006368:	ffffb097          	auipc	ra,0xffffb
    8000636c:	936080e7          	jalr	-1738(ra) # 80000c9e <release>
}
    80006370:	60e2                	ld	ra,24(sp)
    80006372:	6442                	ld	s0,16(sp)
    80006374:	64a2                	ld	s1,8(sp)
    80006376:	6105                	addi	sp,sp,32
    80006378:	8082                	ret
      panic("virtio_disk_intr status");
    8000637a:	00002517          	auipc	a0,0x2
    8000637e:	5a650513          	addi	a0,a0,1446 # 80008920 <syscalls+0x3f0>
    80006382:	ffffa097          	auipc	ra,0xffffa
    80006386:	1c2080e7          	jalr	450(ra) # 80000544 <panic>
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
