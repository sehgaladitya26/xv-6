
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
    80000068:	ccc78793          	addi	a5,a5,-820 # 80005d30 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc0cf>
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
    80000130:	3a4080e7          	jalr	932(ra) # 800024d0 <either_copyin>
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
    800001d0:	14e080e7          	jalr	334(ra) # 8000231a <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	e98080e7          	jalr	-360(ra) # 80002072 <sleep>
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
    8000021a:	264080e7          	jalr	612(ra) # 8000247a <either_copyout>
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
    800002fc:	22e080e7          	jalr	558(ra) # 80002526 <procdump>
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
    80000450:	c8a080e7          	jalr	-886(ra) # 800020d6 <wakeup>
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
    80000482:	11a78793          	addi	a5,a5,282 # 80021598 <devsw>
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
    800008aa:	830080e7          	jalr	-2000(ra) # 800020d6 <wakeup>
    
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
    80000934:	742080e7          	jalr	1858(ra) # 80002072 <sleep>
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
    80000a16:	d1e78793          	addi	a5,a5,-738 # 80022730 <end>
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
    80000ae6:	c4e50513          	addi	a0,a0,-946 # 80022730 <end>
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
    80000ede:	78c080e7          	jalr	1932(ra) # 80002666 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00005097          	auipc	ra,0x5
    80000ee6:	e8e080e7          	jalr	-370(ra) # 80005d70 <plicinithart>
  }

  scheduler();        
    80000eea:	00001097          	auipc	ra,0x1
    80000eee:	fd6080e7          	jalr	-42(ra) # 80001ec0 <scheduler>
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
    80000f56:	6ec080e7          	jalr	1772(ra) # 8000263e <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00001097          	auipc	ra,0x1
    80000f5e:	70c080e7          	jalr	1804(ra) # 80002666 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	df8080e7          	jalr	-520(ra) # 80005d5a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00005097          	auipc	ra,0x5
    80000f6e:	e06080e7          	jalr	-506(ra) # 80005d70 <plicinithart>
    binit();         // buffer cache
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	fb2080e7          	jalr	-78(ra) # 80002f24 <binit>
    iinit();         // inode table
    80000f7a:	00002097          	auipc	ra,0x2
    80000f7e:	656080e7          	jalr	1622(ra) # 800035d0 <iinit>
    fileinit();      // file table
    80000f82:	00003097          	auipc	ra,0x3
    80000f86:	5f4080e7          	jalr	1524(ra) # 80004576 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	eee080e7          	jalr	-274(ra) # 80005e78 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	d0c080e7          	jalr	-756(ra) # 80001c9e <userinit>
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
    80001884:	ad0a0a13          	addi	s4,s4,-1328 # 80017350 <tickslock>
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
    800018ba:	18848493          	addi	s1,s1,392
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
    80001950:	a0498993          	addi	s3,s3,-1532 # 80017350 <tickslock>
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
    8000197e:	18848493          	addi	s1,s1,392
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
    80001a1a:	f2a7a783          	lw	a5,-214(a5) # 80008940 <first.1683>
    80001a1e:	eb89                	bnez	a5,80001a30 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a20:	00001097          	auipc	ra,0x1
    80001a24:	c5e080e7          	jalr	-930(ra) # 8000267e <usertrapret>
}
    80001a28:	60a2                	ld	ra,8(sp)
    80001a2a:	6402                	ld	s0,0(sp)
    80001a2c:	0141                	addi	sp,sp,16
    80001a2e:	8082                	ret
    first = 0;
    80001a30:	00007797          	auipc	a5,0x7
    80001a34:	f007a823          	sw	zero,-240(a5) # 80008940 <first.1683>
    fsinit(ROOTDEV);
    80001a38:	4505                	li	a0,1
    80001a3a:	00002097          	auipc	ra,0x2
    80001a3e:	b16080e7          	jalr	-1258(ra) # 80003550 <fsinit>
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
    80001be4:	00015917          	auipc	s2,0x15
    80001be8:	76c90913          	addi	s2,s2,1900 # 80017350 <tickslock>
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
    80001c04:	18848493          	addi	s1,s1,392
    80001c08:	ff2492e3          	bne	s1,s2,80001bec <allocproc+0x1c>
  return 0;
    80001c0c:	4481                	li	s1,0
    80001c0e:	a889                	j	80001c60 <allocproc+0x90>
  p->pid = allocpid();
    80001c10:	00000097          	auipc	ra,0x0
    80001c14:	e34080e7          	jalr	-460(ra) # 80001a44 <allocpid>
    80001c18:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c1a:	4785                	li	a5,1
    80001c1c:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c1e:	fffff097          	auipc	ra,0xfffff
    80001c22:	edc080e7          	jalr	-292(ra) # 80000afa <kalloc>
    80001c26:	892a                	mv	s2,a0
    80001c28:	eca8                	sd	a0,88(s1)
    80001c2a:	c131                	beqz	a0,80001c6e <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c2c:	8526                	mv	a0,s1
    80001c2e:	00000097          	auipc	ra,0x0
    80001c32:	e5c080e7          	jalr	-420(ra) # 80001a8a <proc_pagetable>
    80001c36:	892a                	mv	s2,a0
    80001c38:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c3a:	c531                	beqz	a0,80001c86 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c3c:	07000613          	li	a2,112
    80001c40:	4581                	li	a1,0
    80001c42:	06048513          	addi	a0,s1,96
    80001c46:	fffff097          	auipc	ra,0xfffff
    80001c4a:	0a0080e7          	jalr	160(ra) # 80000ce6 <memset>
  p->context.ra = (uint64)forkret;
    80001c4e:	00000797          	auipc	a5,0x0
    80001c52:	db078793          	addi	a5,a5,-592 # 800019fe <forkret>
    80001c56:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c58:	60bc                	ld	a5,64(s1)
    80001c5a:	6705                	lui	a4,0x1
    80001c5c:	97ba                	add	a5,a5,a4
    80001c5e:	f4bc                	sd	a5,104(s1)
}
    80001c60:	8526                	mv	a0,s1
    80001c62:	60e2                	ld	ra,24(sp)
    80001c64:	6442                	ld	s0,16(sp)
    80001c66:	64a2                	ld	s1,8(sp)
    80001c68:	6902                	ld	s2,0(sp)
    80001c6a:	6105                	addi	sp,sp,32
    80001c6c:	8082                	ret
    freeproc(p);
    80001c6e:	8526                	mv	a0,s1
    80001c70:	00000097          	auipc	ra,0x0
    80001c74:	f08080e7          	jalr	-248(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001c78:	8526                	mv	a0,s1
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	024080e7          	jalr	36(ra) # 80000c9e <release>
    return 0;
    80001c82:	84ca                	mv	s1,s2
    80001c84:	bff1                	j	80001c60 <allocproc+0x90>
    freeproc(p);
    80001c86:	8526                	mv	a0,s1
    80001c88:	00000097          	auipc	ra,0x0
    80001c8c:	ef0080e7          	jalr	-272(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001c90:	8526                	mv	a0,s1
    80001c92:	fffff097          	auipc	ra,0xfffff
    80001c96:	00c080e7          	jalr	12(ra) # 80000c9e <release>
    return 0;
    80001c9a:	84ca                	mv	s1,s2
    80001c9c:	b7d1                	j	80001c60 <allocproc+0x90>

0000000080001c9e <userinit>:
{
    80001c9e:	1101                	addi	sp,sp,-32
    80001ca0:	ec06                	sd	ra,24(sp)
    80001ca2:	e822                	sd	s0,16(sp)
    80001ca4:	e426                	sd	s1,8(sp)
    80001ca6:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ca8:	00000097          	auipc	ra,0x0
    80001cac:	f28080e7          	jalr	-216(ra) # 80001bd0 <allocproc>
    80001cb0:	84aa                	mv	s1,a0
  initproc = p;
    80001cb2:	00007797          	auipc	a5,0x7
    80001cb6:	dea7bb23          	sd	a0,-522(a5) # 80008aa8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cba:	03400613          	li	a2,52
    80001cbe:	00007597          	auipc	a1,0x7
    80001cc2:	c9258593          	addi	a1,a1,-878 # 80008950 <initcode>
    80001cc6:	6928                	ld	a0,80(a0)
    80001cc8:	fffff097          	auipc	ra,0xfffff
    80001ccc:	6aa080e7          	jalr	1706(ra) # 80001372 <uvmfirst>
  p->sz = PGSIZE;
    80001cd0:	6785                	lui	a5,0x1
    80001cd2:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cd4:	6cb8                	ld	a4,88(s1)
    80001cd6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cda:	6cb8                	ld	a4,88(s1)
    80001cdc:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cde:	4641                	li	a2,16
    80001ce0:	00006597          	auipc	a1,0x6
    80001ce4:	52058593          	addi	a1,a1,1312 # 80008200 <digits+0x1c0>
    80001ce8:	15848513          	addi	a0,s1,344
    80001cec:	fffff097          	auipc	ra,0xfffff
    80001cf0:	14c080e7          	jalr	332(ra) # 80000e38 <safestrcpy>
  p->cwd = namei("/");
    80001cf4:	00006517          	auipc	a0,0x6
    80001cf8:	51c50513          	addi	a0,a0,1308 # 80008210 <digits+0x1d0>
    80001cfc:	00002097          	auipc	ra,0x2
    80001d00:	276080e7          	jalr	630(ra) # 80003f72 <namei>
    80001d04:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d08:	478d                	li	a5,3
    80001d0a:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d0c:	8526                	mv	a0,s1
    80001d0e:	fffff097          	auipc	ra,0xfffff
    80001d12:	f90080e7          	jalr	-112(ra) # 80000c9e <release>
}
    80001d16:	60e2                	ld	ra,24(sp)
    80001d18:	6442                	ld	s0,16(sp)
    80001d1a:	64a2                	ld	s1,8(sp)
    80001d1c:	6105                	addi	sp,sp,32
    80001d1e:	8082                	ret

0000000080001d20 <growproc>:
{
    80001d20:	1101                	addi	sp,sp,-32
    80001d22:	ec06                	sd	ra,24(sp)
    80001d24:	e822                	sd	s0,16(sp)
    80001d26:	e426                	sd	s1,8(sp)
    80001d28:	e04a                	sd	s2,0(sp)
    80001d2a:	1000                	addi	s0,sp,32
    80001d2c:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d2e:	00000097          	auipc	ra,0x0
    80001d32:	c98080e7          	jalr	-872(ra) # 800019c6 <myproc>
    80001d36:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d38:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d3a:	01204c63          	bgtz	s2,80001d52 <growproc+0x32>
  } else if(n < 0){
    80001d3e:	02094663          	bltz	s2,80001d6a <growproc+0x4a>
  p->sz = sz;
    80001d42:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d44:	4501                	li	a0,0
}
    80001d46:	60e2                	ld	ra,24(sp)
    80001d48:	6442                	ld	s0,16(sp)
    80001d4a:	64a2                	ld	s1,8(sp)
    80001d4c:	6902                	ld	s2,0(sp)
    80001d4e:	6105                	addi	sp,sp,32
    80001d50:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d52:	4691                	li	a3,4
    80001d54:	00b90633          	add	a2,s2,a1
    80001d58:	6928                	ld	a0,80(a0)
    80001d5a:	fffff097          	auipc	ra,0xfffff
    80001d5e:	6d2080e7          	jalr	1746(ra) # 8000142c <uvmalloc>
    80001d62:	85aa                	mv	a1,a0
    80001d64:	fd79                	bnez	a0,80001d42 <growproc+0x22>
      return -1;
    80001d66:	557d                	li	a0,-1
    80001d68:	bff9                	j	80001d46 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d6a:	00b90633          	add	a2,s2,a1
    80001d6e:	6928                	ld	a0,80(a0)
    80001d70:	fffff097          	auipc	ra,0xfffff
    80001d74:	674080e7          	jalr	1652(ra) # 800013e4 <uvmdealloc>
    80001d78:	85aa                	mv	a1,a0
    80001d7a:	b7e1                	j	80001d42 <growproc+0x22>

0000000080001d7c <fork>:
{
    80001d7c:	7179                	addi	sp,sp,-48
    80001d7e:	f406                	sd	ra,40(sp)
    80001d80:	f022                	sd	s0,32(sp)
    80001d82:	ec26                	sd	s1,24(sp)
    80001d84:	e84a                	sd	s2,16(sp)
    80001d86:	e44e                	sd	s3,8(sp)
    80001d88:	e052                	sd	s4,0(sp)
    80001d8a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001d8c:	00000097          	auipc	ra,0x0
    80001d90:	c3a080e7          	jalr	-966(ra) # 800019c6 <myproc>
    80001d94:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001d96:	00000097          	auipc	ra,0x0
    80001d9a:	e3a080e7          	jalr	-454(ra) # 80001bd0 <allocproc>
    80001d9e:	10050f63          	beqz	a0,80001ebc <fork+0x140>
    80001da2:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001da4:	04893603          	ld	a2,72(s2)
    80001da8:	692c                	ld	a1,80(a0)
    80001daa:	05093503          	ld	a0,80(s2)
    80001dae:	fffff097          	auipc	ra,0xfffff
    80001db2:	7d2080e7          	jalr	2002(ra) # 80001580 <uvmcopy>
    80001db6:	04054a63          	bltz	a0,80001e0a <fork+0x8e>
  np->sz = p->sz;
    80001dba:	04893783          	ld	a5,72(s2)
    80001dbe:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dc2:	05893683          	ld	a3,88(s2)
    80001dc6:	87b6                	mv	a5,a3
    80001dc8:	0589b703          	ld	a4,88(s3)
    80001dcc:	12068693          	addi	a3,a3,288
    80001dd0:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dd4:	6788                	ld	a0,8(a5)
    80001dd6:	6b8c                	ld	a1,16(a5)
    80001dd8:	6f90                	ld	a2,24(a5)
    80001dda:	01073023          	sd	a6,0(a4)
    80001dde:	e708                	sd	a0,8(a4)
    80001de0:	eb0c                	sd	a1,16(a4)
    80001de2:	ef10                	sd	a2,24(a4)
    80001de4:	02078793          	addi	a5,a5,32
    80001de8:	02070713          	addi	a4,a4,32
    80001dec:	fed792e3          	bne	a5,a3,80001dd0 <fork+0x54>
  np->trace_flag = p->trace_flag;
    80001df0:	16892783          	lw	a5,360(s2)
    80001df4:	16f9a423          	sw	a5,360(s3)
  np->trapframe->a0 = 0;
    80001df8:	0589b783          	ld	a5,88(s3)
    80001dfc:	0607b823          	sd	zero,112(a5)
    80001e00:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e04:	15000a13          	li	s4,336
    80001e08:	a03d                	j	80001e36 <fork+0xba>
    freeproc(np);
    80001e0a:	854e                	mv	a0,s3
    80001e0c:	00000097          	auipc	ra,0x0
    80001e10:	d6c080e7          	jalr	-660(ra) # 80001b78 <freeproc>
    release(&np->lock);
    80001e14:	854e                	mv	a0,s3
    80001e16:	fffff097          	auipc	ra,0xfffff
    80001e1a:	e88080e7          	jalr	-376(ra) # 80000c9e <release>
    return -1;
    80001e1e:	5a7d                	li	s4,-1
    80001e20:	a069                	j	80001eaa <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e22:	00002097          	auipc	ra,0x2
    80001e26:	7e6080e7          	jalr	2022(ra) # 80004608 <filedup>
    80001e2a:	009987b3          	add	a5,s3,s1
    80001e2e:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e30:	04a1                	addi	s1,s1,8
    80001e32:	01448763          	beq	s1,s4,80001e40 <fork+0xc4>
    if(p->ofile[i])
    80001e36:	009907b3          	add	a5,s2,s1
    80001e3a:	6388                	ld	a0,0(a5)
    80001e3c:	f17d                	bnez	a0,80001e22 <fork+0xa6>
    80001e3e:	bfcd                	j	80001e30 <fork+0xb4>
  np->cwd = idup(p->cwd);
    80001e40:	15093503          	ld	a0,336(s2)
    80001e44:	00002097          	auipc	ra,0x2
    80001e48:	94a080e7          	jalr	-1718(ra) # 8000378e <idup>
    80001e4c:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e50:	4641                	li	a2,16
    80001e52:	15890593          	addi	a1,s2,344
    80001e56:	15898513          	addi	a0,s3,344
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	fde080e7          	jalr	-34(ra) # 80000e38 <safestrcpy>
  pid = np->pid;
    80001e62:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e66:	854e                	mv	a0,s3
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	e36080e7          	jalr	-458(ra) # 80000c9e <release>
  acquire(&wait_lock);
    80001e70:	0000f497          	auipc	s1,0xf
    80001e74:	ec848493          	addi	s1,s1,-312 # 80010d38 <wait_lock>
    80001e78:	8526                	mv	a0,s1
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	d70080e7          	jalr	-656(ra) # 80000bea <acquire>
  np->parent = p;
    80001e82:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001e86:	8526                	mv	a0,s1
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	e16080e7          	jalr	-490(ra) # 80000c9e <release>
  acquire(&np->lock);
    80001e90:	854e                	mv	a0,s3
    80001e92:	fffff097          	auipc	ra,0xfffff
    80001e96:	d58080e7          	jalr	-680(ra) # 80000bea <acquire>
  np->state = RUNNABLE;
    80001e9a:	478d                	li	a5,3
    80001e9c:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ea0:	854e                	mv	a0,s3
    80001ea2:	fffff097          	auipc	ra,0xfffff
    80001ea6:	dfc080e7          	jalr	-516(ra) # 80000c9e <release>
}
    80001eaa:	8552                	mv	a0,s4
    80001eac:	70a2                	ld	ra,40(sp)
    80001eae:	7402                	ld	s0,32(sp)
    80001eb0:	64e2                	ld	s1,24(sp)
    80001eb2:	6942                	ld	s2,16(sp)
    80001eb4:	69a2                	ld	s3,8(sp)
    80001eb6:	6a02                	ld	s4,0(sp)
    80001eb8:	6145                	addi	sp,sp,48
    80001eba:	8082                	ret
    return -1;
    80001ebc:	5a7d                	li	s4,-1
    80001ebe:	b7f5                	j	80001eaa <fork+0x12e>

0000000080001ec0 <scheduler>:
{
    80001ec0:	7139                	addi	sp,sp,-64
    80001ec2:	fc06                	sd	ra,56(sp)
    80001ec4:	f822                	sd	s0,48(sp)
    80001ec6:	f426                	sd	s1,40(sp)
    80001ec8:	f04a                	sd	s2,32(sp)
    80001eca:	ec4e                	sd	s3,24(sp)
    80001ecc:	e852                	sd	s4,16(sp)
    80001ece:	e456                	sd	s5,8(sp)
    80001ed0:	e05a                	sd	s6,0(sp)
    80001ed2:	0080                	addi	s0,sp,64
    80001ed4:	8792                	mv	a5,tp
  int id = r_tp();
    80001ed6:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ed8:	00779a93          	slli	s5,a5,0x7
    80001edc:	0000f717          	auipc	a4,0xf
    80001ee0:	e4470713          	addi	a4,a4,-444 # 80010d20 <pid_lock>
    80001ee4:	9756                	add	a4,a4,s5
    80001ee6:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001eea:	0000f717          	auipc	a4,0xf
    80001eee:	e6e70713          	addi	a4,a4,-402 # 80010d58 <cpus+0x8>
    80001ef2:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ef4:	498d                	li	s3,3
        p->state = RUNNING;
    80001ef6:	4b11                	li	s6,4
        c->proc = p;
    80001ef8:	079e                	slli	a5,a5,0x7
    80001efa:	0000fa17          	auipc	s4,0xf
    80001efe:	e26a0a13          	addi	s4,s4,-474 # 80010d20 <pid_lock>
    80001f02:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f04:	00015917          	auipc	s2,0x15
    80001f08:	44c90913          	addi	s2,s2,1100 # 80017350 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f0c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f10:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f14:	10079073          	csrw	sstatus,a5
    80001f18:	0000f497          	auipc	s1,0xf
    80001f1c:	23848493          	addi	s1,s1,568 # 80011150 <proc>
    80001f20:	a03d                	j	80001f4e <scheduler+0x8e>
        p->state = RUNNING;
    80001f22:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f26:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f2a:	06048593          	addi	a1,s1,96
    80001f2e:	8556                	mv	a0,s5
    80001f30:	00000097          	auipc	ra,0x0
    80001f34:	6a4080e7          	jalr	1700(ra) # 800025d4 <swtch>
        c->proc = 0;
    80001f38:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80001f3c:	8526                	mv	a0,s1
    80001f3e:	fffff097          	auipc	ra,0xfffff
    80001f42:	d60080e7          	jalr	-672(ra) # 80000c9e <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f46:	18848493          	addi	s1,s1,392
    80001f4a:	fd2481e3          	beq	s1,s2,80001f0c <scheduler+0x4c>
      acquire(&p->lock);
    80001f4e:	8526                	mv	a0,s1
    80001f50:	fffff097          	auipc	ra,0xfffff
    80001f54:	c9a080e7          	jalr	-870(ra) # 80000bea <acquire>
      if(p->state == RUNNABLE) {
    80001f58:	4c9c                	lw	a5,24(s1)
    80001f5a:	ff3791e3          	bne	a5,s3,80001f3c <scheduler+0x7c>
    80001f5e:	b7d1                	j	80001f22 <scheduler+0x62>

0000000080001f60 <sched>:
{
    80001f60:	7179                	addi	sp,sp,-48
    80001f62:	f406                	sd	ra,40(sp)
    80001f64:	f022                	sd	s0,32(sp)
    80001f66:	ec26                	sd	s1,24(sp)
    80001f68:	e84a                	sd	s2,16(sp)
    80001f6a:	e44e                	sd	s3,8(sp)
    80001f6c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f6e:	00000097          	auipc	ra,0x0
    80001f72:	a58080e7          	jalr	-1448(ra) # 800019c6 <myproc>
    80001f76:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f78:	fffff097          	auipc	ra,0xfffff
    80001f7c:	bf8080e7          	jalr	-1032(ra) # 80000b70 <holding>
    80001f80:	c93d                	beqz	a0,80001ff6 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f82:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f84:	2781                	sext.w	a5,a5
    80001f86:	079e                	slli	a5,a5,0x7
    80001f88:	0000f717          	auipc	a4,0xf
    80001f8c:	d9870713          	addi	a4,a4,-616 # 80010d20 <pid_lock>
    80001f90:	97ba                	add	a5,a5,a4
    80001f92:	0a87a703          	lw	a4,168(a5)
    80001f96:	4785                	li	a5,1
    80001f98:	06f71763          	bne	a4,a5,80002006 <sched+0xa6>
  if(p->state == RUNNING)
    80001f9c:	4c98                	lw	a4,24(s1)
    80001f9e:	4791                	li	a5,4
    80001fa0:	06f70b63          	beq	a4,a5,80002016 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fa4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fa8:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001faa:	efb5                	bnez	a5,80002026 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fac:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fae:	0000f917          	auipc	s2,0xf
    80001fb2:	d7290913          	addi	s2,s2,-654 # 80010d20 <pid_lock>
    80001fb6:	2781                	sext.w	a5,a5
    80001fb8:	079e                	slli	a5,a5,0x7
    80001fba:	97ca                	add	a5,a5,s2
    80001fbc:	0ac7a983          	lw	s3,172(a5)
    80001fc0:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fc2:	2781                	sext.w	a5,a5
    80001fc4:	079e                	slli	a5,a5,0x7
    80001fc6:	0000f597          	auipc	a1,0xf
    80001fca:	d9258593          	addi	a1,a1,-622 # 80010d58 <cpus+0x8>
    80001fce:	95be                	add	a1,a1,a5
    80001fd0:	06048513          	addi	a0,s1,96
    80001fd4:	00000097          	auipc	ra,0x0
    80001fd8:	600080e7          	jalr	1536(ra) # 800025d4 <swtch>
    80001fdc:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fde:	2781                	sext.w	a5,a5
    80001fe0:	079e                	slli	a5,a5,0x7
    80001fe2:	97ca                	add	a5,a5,s2
    80001fe4:	0b37a623          	sw	s3,172(a5)
}
    80001fe8:	70a2                	ld	ra,40(sp)
    80001fea:	7402                	ld	s0,32(sp)
    80001fec:	64e2                	ld	s1,24(sp)
    80001fee:	6942                	ld	s2,16(sp)
    80001ff0:	69a2                	ld	s3,8(sp)
    80001ff2:	6145                	addi	sp,sp,48
    80001ff4:	8082                	ret
    panic("sched p->lock");
    80001ff6:	00006517          	auipc	a0,0x6
    80001ffa:	22250513          	addi	a0,a0,546 # 80008218 <digits+0x1d8>
    80001ffe:	ffffe097          	auipc	ra,0xffffe
    80002002:	546080e7          	jalr	1350(ra) # 80000544 <panic>
    panic("sched locks");
    80002006:	00006517          	auipc	a0,0x6
    8000200a:	22250513          	addi	a0,a0,546 # 80008228 <digits+0x1e8>
    8000200e:	ffffe097          	auipc	ra,0xffffe
    80002012:	536080e7          	jalr	1334(ra) # 80000544 <panic>
    panic("sched running");
    80002016:	00006517          	auipc	a0,0x6
    8000201a:	22250513          	addi	a0,a0,546 # 80008238 <digits+0x1f8>
    8000201e:	ffffe097          	auipc	ra,0xffffe
    80002022:	526080e7          	jalr	1318(ra) # 80000544 <panic>
    panic("sched interruptible");
    80002026:	00006517          	auipc	a0,0x6
    8000202a:	22250513          	addi	a0,a0,546 # 80008248 <digits+0x208>
    8000202e:	ffffe097          	auipc	ra,0xffffe
    80002032:	516080e7          	jalr	1302(ra) # 80000544 <panic>

0000000080002036 <yield>:
{
    80002036:	1101                	addi	sp,sp,-32
    80002038:	ec06                	sd	ra,24(sp)
    8000203a:	e822                	sd	s0,16(sp)
    8000203c:	e426                	sd	s1,8(sp)
    8000203e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002040:	00000097          	auipc	ra,0x0
    80002044:	986080e7          	jalr	-1658(ra) # 800019c6 <myproc>
    80002048:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000204a:	fffff097          	auipc	ra,0xfffff
    8000204e:	ba0080e7          	jalr	-1120(ra) # 80000bea <acquire>
  p->state = RUNNABLE;
    80002052:	478d                	li	a5,3
    80002054:	cc9c                	sw	a5,24(s1)
  sched();
    80002056:	00000097          	auipc	ra,0x0
    8000205a:	f0a080e7          	jalr	-246(ra) # 80001f60 <sched>
  release(&p->lock);
    8000205e:	8526                	mv	a0,s1
    80002060:	fffff097          	auipc	ra,0xfffff
    80002064:	c3e080e7          	jalr	-962(ra) # 80000c9e <release>
}
    80002068:	60e2                	ld	ra,24(sp)
    8000206a:	6442                	ld	s0,16(sp)
    8000206c:	64a2                	ld	s1,8(sp)
    8000206e:	6105                	addi	sp,sp,32
    80002070:	8082                	ret

0000000080002072 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002072:	7179                	addi	sp,sp,-48
    80002074:	f406                	sd	ra,40(sp)
    80002076:	f022                	sd	s0,32(sp)
    80002078:	ec26                	sd	s1,24(sp)
    8000207a:	e84a                	sd	s2,16(sp)
    8000207c:	e44e                	sd	s3,8(sp)
    8000207e:	1800                	addi	s0,sp,48
    80002080:	89aa                	mv	s3,a0
    80002082:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002084:	00000097          	auipc	ra,0x0
    80002088:	942080e7          	jalr	-1726(ra) # 800019c6 <myproc>
    8000208c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000208e:	fffff097          	auipc	ra,0xfffff
    80002092:	b5c080e7          	jalr	-1188(ra) # 80000bea <acquire>
  release(lk);
    80002096:	854a                	mv	a0,s2
    80002098:	fffff097          	auipc	ra,0xfffff
    8000209c:	c06080e7          	jalr	-1018(ra) # 80000c9e <release>

  // Go to sleep.
  p->chan = chan;
    800020a0:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020a4:	4789                	li	a5,2
    800020a6:	cc9c                	sw	a5,24(s1)

  sched();
    800020a8:	00000097          	auipc	ra,0x0
    800020ac:	eb8080e7          	jalr	-328(ra) # 80001f60 <sched>

  // Tidy up.
  p->chan = 0;
    800020b0:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020b4:	8526                	mv	a0,s1
    800020b6:	fffff097          	auipc	ra,0xfffff
    800020ba:	be8080e7          	jalr	-1048(ra) # 80000c9e <release>
  acquire(lk);
    800020be:	854a                	mv	a0,s2
    800020c0:	fffff097          	auipc	ra,0xfffff
    800020c4:	b2a080e7          	jalr	-1238(ra) # 80000bea <acquire>
}
    800020c8:	70a2                	ld	ra,40(sp)
    800020ca:	7402                	ld	s0,32(sp)
    800020cc:	64e2                	ld	s1,24(sp)
    800020ce:	6942                	ld	s2,16(sp)
    800020d0:	69a2                	ld	s3,8(sp)
    800020d2:	6145                	addi	sp,sp,48
    800020d4:	8082                	ret

00000000800020d6 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800020d6:	7139                	addi	sp,sp,-64
    800020d8:	fc06                	sd	ra,56(sp)
    800020da:	f822                	sd	s0,48(sp)
    800020dc:	f426                	sd	s1,40(sp)
    800020de:	f04a                	sd	s2,32(sp)
    800020e0:	ec4e                	sd	s3,24(sp)
    800020e2:	e852                	sd	s4,16(sp)
    800020e4:	e456                	sd	s5,8(sp)
    800020e6:	0080                	addi	s0,sp,64
    800020e8:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800020ea:	0000f497          	auipc	s1,0xf
    800020ee:	06648493          	addi	s1,s1,102 # 80011150 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800020f2:	4989                	li	s3,2
        p->state = RUNNABLE;
    800020f4:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800020f6:	00015917          	auipc	s2,0x15
    800020fa:	25a90913          	addi	s2,s2,602 # 80017350 <tickslock>
    800020fe:	a821                	j	80002116 <wakeup+0x40>
        p->state = RUNNABLE;
    80002100:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002104:	8526                	mv	a0,s1
    80002106:	fffff097          	auipc	ra,0xfffff
    8000210a:	b98080e7          	jalr	-1128(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000210e:	18848493          	addi	s1,s1,392
    80002112:	03248463          	beq	s1,s2,8000213a <wakeup+0x64>
    if(p != myproc()){
    80002116:	00000097          	auipc	ra,0x0
    8000211a:	8b0080e7          	jalr	-1872(ra) # 800019c6 <myproc>
    8000211e:	fea488e3          	beq	s1,a0,8000210e <wakeup+0x38>
      acquire(&p->lock);
    80002122:	8526                	mv	a0,s1
    80002124:	fffff097          	auipc	ra,0xfffff
    80002128:	ac6080e7          	jalr	-1338(ra) # 80000bea <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000212c:	4c9c                	lw	a5,24(s1)
    8000212e:	fd379be3          	bne	a5,s3,80002104 <wakeup+0x2e>
    80002132:	709c                	ld	a5,32(s1)
    80002134:	fd4798e3          	bne	a5,s4,80002104 <wakeup+0x2e>
    80002138:	b7e1                	j	80002100 <wakeup+0x2a>
    }
  }
}
    8000213a:	70e2                	ld	ra,56(sp)
    8000213c:	7442                	ld	s0,48(sp)
    8000213e:	74a2                	ld	s1,40(sp)
    80002140:	7902                	ld	s2,32(sp)
    80002142:	69e2                	ld	s3,24(sp)
    80002144:	6a42                	ld	s4,16(sp)
    80002146:	6aa2                	ld	s5,8(sp)
    80002148:	6121                	addi	sp,sp,64
    8000214a:	8082                	ret

000000008000214c <reparent>:
{
    8000214c:	7179                	addi	sp,sp,-48
    8000214e:	f406                	sd	ra,40(sp)
    80002150:	f022                	sd	s0,32(sp)
    80002152:	ec26                	sd	s1,24(sp)
    80002154:	e84a                	sd	s2,16(sp)
    80002156:	e44e                	sd	s3,8(sp)
    80002158:	e052                	sd	s4,0(sp)
    8000215a:	1800                	addi	s0,sp,48
    8000215c:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000215e:	0000f497          	auipc	s1,0xf
    80002162:	ff248493          	addi	s1,s1,-14 # 80011150 <proc>
      pp->parent = initproc;
    80002166:	00007a17          	auipc	s4,0x7
    8000216a:	942a0a13          	addi	s4,s4,-1726 # 80008aa8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000216e:	00015997          	auipc	s3,0x15
    80002172:	1e298993          	addi	s3,s3,482 # 80017350 <tickslock>
    80002176:	a029                	j	80002180 <reparent+0x34>
    80002178:	18848493          	addi	s1,s1,392
    8000217c:	01348d63          	beq	s1,s3,80002196 <reparent+0x4a>
    if(pp->parent == p){
    80002180:	7c9c                	ld	a5,56(s1)
    80002182:	ff279be3          	bne	a5,s2,80002178 <reparent+0x2c>
      pp->parent = initproc;
    80002186:	000a3503          	ld	a0,0(s4)
    8000218a:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000218c:	00000097          	auipc	ra,0x0
    80002190:	f4a080e7          	jalr	-182(ra) # 800020d6 <wakeup>
    80002194:	b7d5                	j	80002178 <reparent+0x2c>
}
    80002196:	70a2                	ld	ra,40(sp)
    80002198:	7402                	ld	s0,32(sp)
    8000219a:	64e2                	ld	s1,24(sp)
    8000219c:	6942                	ld	s2,16(sp)
    8000219e:	69a2                	ld	s3,8(sp)
    800021a0:	6a02                	ld	s4,0(sp)
    800021a2:	6145                	addi	sp,sp,48
    800021a4:	8082                	ret

00000000800021a6 <exit>:
{
    800021a6:	7179                	addi	sp,sp,-48
    800021a8:	f406                	sd	ra,40(sp)
    800021aa:	f022                	sd	s0,32(sp)
    800021ac:	ec26                	sd	s1,24(sp)
    800021ae:	e84a                	sd	s2,16(sp)
    800021b0:	e44e                	sd	s3,8(sp)
    800021b2:	e052                	sd	s4,0(sp)
    800021b4:	1800                	addi	s0,sp,48
    800021b6:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021b8:	00000097          	auipc	ra,0x0
    800021bc:	80e080e7          	jalr	-2034(ra) # 800019c6 <myproc>
    800021c0:	89aa                	mv	s3,a0
  if(p == initproc)
    800021c2:	00007797          	auipc	a5,0x7
    800021c6:	8e67b783          	ld	a5,-1818(a5) # 80008aa8 <initproc>
    800021ca:	0d050493          	addi	s1,a0,208
    800021ce:	15050913          	addi	s2,a0,336
    800021d2:	02a79363          	bne	a5,a0,800021f8 <exit+0x52>
    panic("init exiting");
    800021d6:	00006517          	auipc	a0,0x6
    800021da:	08a50513          	addi	a0,a0,138 # 80008260 <digits+0x220>
    800021de:	ffffe097          	auipc	ra,0xffffe
    800021e2:	366080e7          	jalr	870(ra) # 80000544 <panic>
      fileclose(f);
    800021e6:	00002097          	auipc	ra,0x2
    800021ea:	474080e7          	jalr	1140(ra) # 8000465a <fileclose>
      p->ofile[fd] = 0;
    800021ee:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021f2:	04a1                	addi	s1,s1,8
    800021f4:	01248563          	beq	s1,s2,800021fe <exit+0x58>
    if(p->ofile[fd]){
    800021f8:	6088                	ld	a0,0(s1)
    800021fa:	f575                	bnez	a0,800021e6 <exit+0x40>
    800021fc:	bfdd                	j	800021f2 <exit+0x4c>
  begin_op();
    800021fe:	00002097          	auipc	ra,0x2
    80002202:	f90080e7          	jalr	-112(ra) # 8000418e <begin_op>
  iput(p->cwd);
    80002206:	1509b503          	ld	a0,336(s3)
    8000220a:	00001097          	auipc	ra,0x1
    8000220e:	77c080e7          	jalr	1916(ra) # 80003986 <iput>
  end_op();
    80002212:	00002097          	auipc	ra,0x2
    80002216:	ffc080e7          	jalr	-4(ra) # 8000420e <end_op>
  p->cwd = 0;
    8000221a:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000221e:	0000f497          	auipc	s1,0xf
    80002222:	b1a48493          	addi	s1,s1,-1254 # 80010d38 <wait_lock>
    80002226:	8526                	mv	a0,s1
    80002228:	fffff097          	auipc	ra,0xfffff
    8000222c:	9c2080e7          	jalr	-1598(ra) # 80000bea <acquire>
  reparent(p);
    80002230:	854e                	mv	a0,s3
    80002232:	00000097          	auipc	ra,0x0
    80002236:	f1a080e7          	jalr	-230(ra) # 8000214c <reparent>
  wakeup(p->parent);
    8000223a:	0389b503          	ld	a0,56(s3)
    8000223e:	00000097          	auipc	ra,0x0
    80002242:	e98080e7          	jalr	-360(ra) # 800020d6 <wakeup>
  acquire(&p->lock);
    80002246:	854e                	mv	a0,s3
    80002248:	fffff097          	auipc	ra,0xfffff
    8000224c:	9a2080e7          	jalr	-1630(ra) # 80000bea <acquire>
  p->xstate = status;
    80002250:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002254:	4795                	li	a5,5
    80002256:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000225a:	8526                	mv	a0,s1
    8000225c:	fffff097          	auipc	ra,0xfffff
    80002260:	a42080e7          	jalr	-1470(ra) # 80000c9e <release>
  sched();
    80002264:	00000097          	auipc	ra,0x0
    80002268:	cfc080e7          	jalr	-772(ra) # 80001f60 <sched>
  panic("zombie exit");
    8000226c:	00006517          	auipc	a0,0x6
    80002270:	00450513          	addi	a0,a0,4 # 80008270 <digits+0x230>
    80002274:	ffffe097          	auipc	ra,0xffffe
    80002278:	2d0080e7          	jalr	720(ra) # 80000544 <panic>

000000008000227c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000227c:	7179                	addi	sp,sp,-48
    8000227e:	f406                	sd	ra,40(sp)
    80002280:	f022                	sd	s0,32(sp)
    80002282:	ec26                	sd	s1,24(sp)
    80002284:	e84a                	sd	s2,16(sp)
    80002286:	e44e                	sd	s3,8(sp)
    80002288:	1800                	addi	s0,sp,48
    8000228a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000228c:	0000f497          	auipc	s1,0xf
    80002290:	ec448493          	addi	s1,s1,-316 # 80011150 <proc>
    80002294:	00015997          	auipc	s3,0x15
    80002298:	0bc98993          	addi	s3,s3,188 # 80017350 <tickslock>
    acquire(&p->lock);
    8000229c:	8526                	mv	a0,s1
    8000229e:	fffff097          	auipc	ra,0xfffff
    800022a2:	94c080e7          	jalr	-1716(ra) # 80000bea <acquire>
    if(p->pid == pid){
    800022a6:	589c                	lw	a5,48(s1)
    800022a8:	01278d63          	beq	a5,s2,800022c2 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022ac:	8526                	mv	a0,s1
    800022ae:	fffff097          	auipc	ra,0xfffff
    800022b2:	9f0080e7          	jalr	-1552(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800022b6:	18848493          	addi	s1,s1,392
    800022ba:	ff3491e3          	bne	s1,s3,8000229c <kill+0x20>
  }
  return -1;
    800022be:	557d                	li	a0,-1
    800022c0:	a829                	j	800022da <kill+0x5e>
      p->killed = 1;
    800022c2:	4785                	li	a5,1
    800022c4:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022c6:	4c98                	lw	a4,24(s1)
    800022c8:	4789                	li	a5,2
    800022ca:	00f70f63          	beq	a4,a5,800022e8 <kill+0x6c>
      release(&p->lock);
    800022ce:	8526                	mv	a0,s1
    800022d0:	fffff097          	auipc	ra,0xfffff
    800022d4:	9ce080e7          	jalr	-1586(ra) # 80000c9e <release>
      return 0;
    800022d8:	4501                	li	a0,0
}
    800022da:	70a2                	ld	ra,40(sp)
    800022dc:	7402                	ld	s0,32(sp)
    800022de:	64e2                	ld	s1,24(sp)
    800022e0:	6942                	ld	s2,16(sp)
    800022e2:	69a2                	ld	s3,8(sp)
    800022e4:	6145                	addi	sp,sp,48
    800022e6:	8082                	ret
        p->state = RUNNABLE;
    800022e8:	478d                	li	a5,3
    800022ea:	cc9c                	sw	a5,24(s1)
    800022ec:	b7cd                	j	800022ce <kill+0x52>

00000000800022ee <setkilled>:

void
setkilled(struct proc *p)
{
    800022ee:	1101                	addi	sp,sp,-32
    800022f0:	ec06                	sd	ra,24(sp)
    800022f2:	e822                	sd	s0,16(sp)
    800022f4:	e426                	sd	s1,8(sp)
    800022f6:	1000                	addi	s0,sp,32
    800022f8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022fa:	fffff097          	auipc	ra,0xfffff
    800022fe:	8f0080e7          	jalr	-1808(ra) # 80000bea <acquire>
  p->killed = 1;
    80002302:	4785                	li	a5,1
    80002304:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002306:	8526                	mv	a0,s1
    80002308:	fffff097          	auipc	ra,0xfffff
    8000230c:	996080e7          	jalr	-1642(ra) # 80000c9e <release>
}
    80002310:	60e2                	ld	ra,24(sp)
    80002312:	6442                	ld	s0,16(sp)
    80002314:	64a2                	ld	s1,8(sp)
    80002316:	6105                	addi	sp,sp,32
    80002318:	8082                	ret

000000008000231a <killed>:

int
killed(struct proc *p)
{
    8000231a:	1101                	addi	sp,sp,-32
    8000231c:	ec06                	sd	ra,24(sp)
    8000231e:	e822                	sd	s0,16(sp)
    80002320:	e426                	sd	s1,8(sp)
    80002322:	e04a                	sd	s2,0(sp)
    80002324:	1000                	addi	s0,sp,32
    80002326:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002328:	fffff097          	auipc	ra,0xfffff
    8000232c:	8c2080e7          	jalr	-1854(ra) # 80000bea <acquire>
  k = p->killed;
    80002330:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002334:	8526                	mv	a0,s1
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	968080e7          	jalr	-1688(ra) # 80000c9e <release>
  return k;
}
    8000233e:	854a                	mv	a0,s2
    80002340:	60e2                	ld	ra,24(sp)
    80002342:	6442                	ld	s0,16(sp)
    80002344:	64a2                	ld	s1,8(sp)
    80002346:	6902                	ld	s2,0(sp)
    80002348:	6105                	addi	sp,sp,32
    8000234a:	8082                	ret

000000008000234c <wait>:
{
    8000234c:	715d                	addi	sp,sp,-80
    8000234e:	e486                	sd	ra,72(sp)
    80002350:	e0a2                	sd	s0,64(sp)
    80002352:	fc26                	sd	s1,56(sp)
    80002354:	f84a                	sd	s2,48(sp)
    80002356:	f44e                	sd	s3,40(sp)
    80002358:	f052                	sd	s4,32(sp)
    8000235a:	ec56                	sd	s5,24(sp)
    8000235c:	e85a                	sd	s6,16(sp)
    8000235e:	e45e                	sd	s7,8(sp)
    80002360:	e062                	sd	s8,0(sp)
    80002362:	0880                	addi	s0,sp,80
    80002364:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002366:	fffff097          	auipc	ra,0xfffff
    8000236a:	660080e7          	jalr	1632(ra) # 800019c6 <myproc>
    8000236e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002370:	0000f517          	auipc	a0,0xf
    80002374:	9c850513          	addi	a0,a0,-1592 # 80010d38 <wait_lock>
    80002378:	fffff097          	auipc	ra,0xfffff
    8000237c:	872080e7          	jalr	-1934(ra) # 80000bea <acquire>
    havekids = 0;
    80002380:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002382:	4a15                	li	s4,5
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002384:	00015997          	auipc	s3,0x15
    80002388:	fcc98993          	addi	s3,s3,-52 # 80017350 <tickslock>
        havekids = 1;
    8000238c:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000238e:	0000fc17          	auipc	s8,0xf
    80002392:	9aac0c13          	addi	s8,s8,-1622 # 80010d38 <wait_lock>
    havekids = 0;
    80002396:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002398:	0000f497          	auipc	s1,0xf
    8000239c:	db848493          	addi	s1,s1,-584 # 80011150 <proc>
    800023a0:	a0bd                	j	8000240e <wait+0xc2>
          pid = pp->pid;
    800023a2:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800023a6:	000b0e63          	beqz	s6,800023c2 <wait+0x76>
    800023aa:	4691                	li	a3,4
    800023ac:	02c48613          	addi	a2,s1,44
    800023b0:	85da                	mv	a1,s6
    800023b2:	05093503          	ld	a0,80(s2)
    800023b6:	fffff097          	auipc	ra,0xfffff
    800023ba:	2ce080e7          	jalr	718(ra) # 80001684 <copyout>
    800023be:	02054563          	bltz	a0,800023e8 <wait+0x9c>
          freeproc(pp);
    800023c2:	8526                	mv	a0,s1
    800023c4:	fffff097          	auipc	ra,0xfffff
    800023c8:	7b4080e7          	jalr	1972(ra) # 80001b78 <freeproc>
          release(&pp->lock);
    800023cc:	8526                	mv	a0,s1
    800023ce:	fffff097          	auipc	ra,0xfffff
    800023d2:	8d0080e7          	jalr	-1840(ra) # 80000c9e <release>
          release(&wait_lock);
    800023d6:	0000f517          	auipc	a0,0xf
    800023da:	96250513          	addi	a0,a0,-1694 # 80010d38 <wait_lock>
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	8c0080e7          	jalr	-1856(ra) # 80000c9e <release>
          return pid;
    800023e6:	a0b5                	j	80002452 <wait+0x106>
            release(&pp->lock);
    800023e8:	8526                	mv	a0,s1
    800023ea:	fffff097          	auipc	ra,0xfffff
    800023ee:	8b4080e7          	jalr	-1868(ra) # 80000c9e <release>
            release(&wait_lock);
    800023f2:	0000f517          	auipc	a0,0xf
    800023f6:	94650513          	addi	a0,a0,-1722 # 80010d38 <wait_lock>
    800023fa:	fffff097          	auipc	ra,0xfffff
    800023fe:	8a4080e7          	jalr	-1884(ra) # 80000c9e <release>
            return -1;
    80002402:	59fd                	li	s3,-1
    80002404:	a0b9                	j	80002452 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002406:	18848493          	addi	s1,s1,392
    8000240a:	03348463          	beq	s1,s3,80002432 <wait+0xe6>
      if(pp->parent == p){
    8000240e:	7c9c                	ld	a5,56(s1)
    80002410:	ff279be3          	bne	a5,s2,80002406 <wait+0xba>
        acquire(&pp->lock);
    80002414:	8526                	mv	a0,s1
    80002416:	ffffe097          	auipc	ra,0xffffe
    8000241a:	7d4080e7          	jalr	2004(ra) # 80000bea <acquire>
        if(pp->state == ZOMBIE){
    8000241e:	4c9c                	lw	a5,24(s1)
    80002420:	f94781e3          	beq	a5,s4,800023a2 <wait+0x56>
        release(&pp->lock);
    80002424:	8526                	mv	a0,s1
    80002426:	fffff097          	auipc	ra,0xfffff
    8000242a:	878080e7          	jalr	-1928(ra) # 80000c9e <release>
        havekids = 1;
    8000242e:	8756                	mv	a4,s5
    80002430:	bfd9                	j	80002406 <wait+0xba>
    if(!havekids || killed(p)){
    80002432:	c719                	beqz	a4,80002440 <wait+0xf4>
    80002434:	854a                	mv	a0,s2
    80002436:	00000097          	auipc	ra,0x0
    8000243a:	ee4080e7          	jalr	-284(ra) # 8000231a <killed>
    8000243e:	c51d                	beqz	a0,8000246c <wait+0x120>
      release(&wait_lock);
    80002440:	0000f517          	auipc	a0,0xf
    80002444:	8f850513          	addi	a0,a0,-1800 # 80010d38 <wait_lock>
    80002448:	fffff097          	auipc	ra,0xfffff
    8000244c:	856080e7          	jalr	-1962(ra) # 80000c9e <release>
      return -1;
    80002450:	59fd                	li	s3,-1
}
    80002452:	854e                	mv	a0,s3
    80002454:	60a6                	ld	ra,72(sp)
    80002456:	6406                	ld	s0,64(sp)
    80002458:	74e2                	ld	s1,56(sp)
    8000245a:	7942                	ld	s2,48(sp)
    8000245c:	79a2                	ld	s3,40(sp)
    8000245e:	7a02                	ld	s4,32(sp)
    80002460:	6ae2                	ld	s5,24(sp)
    80002462:	6b42                	ld	s6,16(sp)
    80002464:	6ba2                	ld	s7,8(sp)
    80002466:	6c02                	ld	s8,0(sp)
    80002468:	6161                	addi	sp,sp,80
    8000246a:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000246c:	85e2                	mv	a1,s8
    8000246e:	854a                	mv	a0,s2
    80002470:	00000097          	auipc	ra,0x0
    80002474:	c02080e7          	jalr	-1022(ra) # 80002072 <sleep>
    havekids = 0;
    80002478:	bf39                	j	80002396 <wait+0x4a>

000000008000247a <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000247a:	7179                	addi	sp,sp,-48
    8000247c:	f406                	sd	ra,40(sp)
    8000247e:	f022                	sd	s0,32(sp)
    80002480:	ec26                	sd	s1,24(sp)
    80002482:	e84a                	sd	s2,16(sp)
    80002484:	e44e                	sd	s3,8(sp)
    80002486:	e052                	sd	s4,0(sp)
    80002488:	1800                	addi	s0,sp,48
    8000248a:	84aa                	mv	s1,a0
    8000248c:	892e                	mv	s2,a1
    8000248e:	89b2                	mv	s3,a2
    80002490:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002492:	fffff097          	auipc	ra,0xfffff
    80002496:	534080e7          	jalr	1332(ra) # 800019c6 <myproc>
  if(user_dst){
    8000249a:	c08d                	beqz	s1,800024bc <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000249c:	86d2                	mv	a3,s4
    8000249e:	864e                	mv	a2,s3
    800024a0:	85ca                	mv	a1,s2
    800024a2:	6928                	ld	a0,80(a0)
    800024a4:	fffff097          	auipc	ra,0xfffff
    800024a8:	1e0080e7          	jalr	480(ra) # 80001684 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024ac:	70a2                	ld	ra,40(sp)
    800024ae:	7402                	ld	s0,32(sp)
    800024b0:	64e2                	ld	s1,24(sp)
    800024b2:	6942                	ld	s2,16(sp)
    800024b4:	69a2                	ld	s3,8(sp)
    800024b6:	6a02                	ld	s4,0(sp)
    800024b8:	6145                	addi	sp,sp,48
    800024ba:	8082                	ret
    memmove((char *)dst, src, len);
    800024bc:	000a061b          	sext.w	a2,s4
    800024c0:	85ce                	mv	a1,s3
    800024c2:	854a                	mv	a0,s2
    800024c4:	fffff097          	auipc	ra,0xfffff
    800024c8:	882080e7          	jalr	-1918(ra) # 80000d46 <memmove>
    return 0;
    800024cc:	8526                	mv	a0,s1
    800024ce:	bff9                	j	800024ac <either_copyout+0x32>

00000000800024d0 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024d0:	7179                	addi	sp,sp,-48
    800024d2:	f406                	sd	ra,40(sp)
    800024d4:	f022                	sd	s0,32(sp)
    800024d6:	ec26                	sd	s1,24(sp)
    800024d8:	e84a                	sd	s2,16(sp)
    800024da:	e44e                	sd	s3,8(sp)
    800024dc:	e052                	sd	s4,0(sp)
    800024de:	1800                	addi	s0,sp,48
    800024e0:	892a                	mv	s2,a0
    800024e2:	84ae                	mv	s1,a1
    800024e4:	89b2                	mv	s3,a2
    800024e6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024e8:	fffff097          	auipc	ra,0xfffff
    800024ec:	4de080e7          	jalr	1246(ra) # 800019c6 <myproc>
  if(user_src){
    800024f0:	c08d                	beqz	s1,80002512 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024f2:	86d2                	mv	a3,s4
    800024f4:	864e                	mv	a2,s3
    800024f6:	85ca                	mv	a1,s2
    800024f8:	6928                	ld	a0,80(a0)
    800024fa:	fffff097          	auipc	ra,0xfffff
    800024fe:	216080e7          	jalr	534(ra) # 80001710 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002502:	70a2                	ld	ra,40(sp)
    80002504:	7402                	ld	s0,32(sp)
    80002506:	64e2                	ld	s1,24(sp)
    80002508:	6942                	ld	s2,16(sp)
    8000250a:	69a2                	ld	s3,8(sp)
    8000250c:	6a02                	ld	s4,0(sp)
    8000250e:	6145                	addi	sp,sp,48
    80002510:	8082                	ret
    memmove(dst, (char*)src, len);
    80002512:	000a061b          	sext.w	a2,s4
    80002516:	85ce                	mv	a1,s3
    80002518:	854a                	mv	a0,s2
    8000251a:	fffff097          	auipc	ra,0xfffff
    8000251e:	82c080e7          	jalr	-2004(ra) # 80000d46 <memmove>
    return 0;
    80002522:	8526                	mv	a0,s1
    80002524:	bff9                	j	80002502 <either_copyin+0x32>

0000000080002526 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002526:	715d                	addi	sp,sp,-80
    80002528:	e486                	sd	ra,72(sp)
    8000252a:	e0a2                	sd	s0,64(sp)
    8000252c:	fc26                	sd	s1,56(sp)
    8000252e:	f84a                	sd	s2,48(sp)
    80002530:	f44e                	sd	s3,40(sp)
    80002532:	f052                	sd	s4,32(sp)
    80002534:	ec56                	sd	s5,24(sp)
    80002536:	e85a                	sd	s6,16(sp)
    80002538:	e45e                	sd	s7,8(sp)
    8000253a:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000253c:	00006517          	auipc	a0,0x6
    80002540:	b8c50513          	addi	a0,a0,-1140 # 800080c8 <digits+0x88>
    80002544:	ffffe097          	auipc	ra,0xffffe
    80002548:	04a080e7          	jalr	74(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000254c:	0000f497          	auipc	s1,0xf
    80002550:	d5c48493          	addi	s1,s1,-676 # 800112a8 <proc+0x158>
    80002554:	00015917          	auipc	s2,0x15
    80002558:	f5490913          	addi	s2,s2,-172 # 800174a8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000255c:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000255e:	00006997          	auipc	s3,0x6
    80002562:	d2298993          	addi	s3,s3,-734 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002566:	00006a97          	auipc	s5,0x6
    8000256a:	d22a8a93          	addi	s5,s5,-734 # 80008288 <digits+0x248>
    printf("\n");
    8000256e:	00006a17          	auipc	s4,0x6
    80002572:	b5aa0a13          	addi	s4,s4,-1190 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002576:	00006b97          	auipc	s7,0x6
    8000257a:	d52b8b93          	addi	s7,s7,-686 # 800082c8 <states.1727>
    8000257e:	a00d                	j	800025a0 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002580:	ed86a583          	lw	a1,-296(a3)
    80002584:	8556                	mv	a0,s5
    80002586:	ffffe097          	auipc	ra,0xffffe
    8000258a:	008080e7          	jalr	8(ra) # 8000058e <printf>
    printf("\n");
    8000258e:	8552                	mv	a0,s4
    80002590:	ffffe097          	auipc	ra,0xffffe
    80002594:	ffe080e7          	jalr	-2(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002598:	18848493          	addi	s1,s1,392
    8000259c:	03248163          	beq	s1,s2,800025be <procdump+0x98>
    if(p->state == UNUSED)
    800025a0:	86a6                	mv	a3,s1
    800025a2:	ec04a783          	lw	a5,-320(s1)
    800025a6:	dbed                	beqz	a5,80002598 <procdump+0x72>
      state = "???";
    800025a8:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025aa:	fcfb6be3          	bltu	s6,a5,80002580 <procdump+0x5a>
    800025ae:	1782                	slli	a5,a5,0x20
    800025b0:	9381                	srli	a5,a5,0x20
    800025b2:	078e                	slli	a5,a5,0x3
    800025b4:	97de                	add	a5,a5,s7
    800025b6:	6390                	ld	a2,0(a5)
    800025b8:	f661                	bnez	a2,80002580 <procdump+0x5a>
      state = "???";
    800025ba:	864e                	mv	a2,s3
    800025bc:	b7d1                	j	80002580 <procdump+0x5a>
  }
}
    800025be:	60a6                	ld	ra,72(sp)
    800025c0:	6406                	ld	s0,64(sp)
    800025c2:	74e2                	ld	s1,56(sp)
    800025c4:	7942                	ld	s2,48(sp)
    800025c6:	79a2                	ld	s3,40(sp)
    800025c8:	7a02                	ld	s4,32(sp)
    800025ca:	6ae2                	ld	s5,24(sp)
    800025cc:	6b42                	ld	s6,16(sp)
    800025ce:	6ba2                	ld	s7,8(sp)
    800025d0:	6161                	addi	sp,sp,80
    800025d2:	8082                	ret

00000000800025d4 <swtch>:
    800025d4:	00153023          	sd	ra,0(a0)
    800025d8:	00253423          	sd	sp,8(a0)
    800025dc:	e900                	sd	s0,16(a0)
    800025de:	ed04                	sd	s1,24(a0)
    800025e0:	03253023          	sd	s2,32(a0)
    800025e4:	03353423          	sd	s3,40(a0)
    800025e8:	03453823          	sd	s4,48(a0)
    800025ec:	03553c23          	sd	s5,56(a0)
    800025f0:	05653023          	sd	s6,64(a0)
    800025f4:	05753423          	sd	s7,72(a0)
    800025f8:	05853823          	sd	s8,80(a0)
    800025fc:	05953c23          	sd	s9,88(a0)
    80002600:	07a53023          	sd	s10,96(a0)
    80002604:	07b53423          	sd	s11,104(a0)
    80002608:	0005b083          	ld	ra,0(a1)
    8000260c:	0085b103          	ld	sp,8(a1)
    80002610:	6980                	ld	s0,16(a1)
    80002612:	6d84                	ld	s1,24(a1)
    80002614:	0205b903          	ld	s2,32(a1)
    80002618:	0285b983          	ld	s3,40(a1)
    8000261c:	0305ba03          	ld	s4,48(a1)
    80002620:	0385ba83          	ld	s5,56(a1)
    80002624:	0405bb03          	ld	s6,64(a1)
    80002628:	0485bb83          	ld	s7,72(a1)
    8000262c:	0505bc03          	ld	s8,80(a1)
    80002630:	0585bc83          	ld	s9,88(a1)
    80002634:	0605bd03          	ld	s10,96(a1)
    80002638:	0685bd83          	ld	s11,104(a1)
    8000263c:	8082                	ret

000000008000263e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000263e:	1141                	addi	sp,sp,-16
    80002640:	e406                	sd	ra,8(sp)
    80002642:	e022                	sd	s0,0(sp)
    80002644:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002646:	00006597          	auipc	a1,0x6
    8000264a:	cb258593          	addi	a1,a1,-846 # 800082f8 <states.1727+0x30>
    8000264e:	00015517          	auipc	a0,0x15
    80002652:	d0250513          	addi	a0,a0,-766 # 80017350 <tickslock>
    80002656:	ffffe097          	auipc	ra,0xffffe
    8000265a:	504080e7          	jalr	1284(ra) # 80000b5a <initlock>
}
    8000265e:	60a2                	ld	ra,8(sp)
    80002660:	6402                	ld	s0,0(sp)
    80002662:	0141                	addi	sp,sp,16
    80002664:	8082                	ret

0000000080002666 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002666:	1141                	addi	sp,sp,-16
    80002668:	e422                	sd	s0,8(sp)
    8000266a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000266c:	00003797          	auipc	a5,0x3
    80002670:	63478793          	addi	a5,a5,1588 # 80005ca0 <kernelvec>
    80002674:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002678:	6422                	ld	s0,8(sp)
    8000267a:	0141                	addi	sp,sp,16
    8000267c:	8082                	ret

000000008000267e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000267e:	1141                	addi	sp,sp,-16
    80002680:	e406                	sd	ra,8(sp)
    80002682:	e022                	sd	s0,0(sp)
    80002684:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002686:	fffff097          	auipc	ra,0xfffff
    8000268a:	340080e7          	jalr	832(ra) # 800019c6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000268e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002692:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002694:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002698:	00005617          	auipc	a2,0x5
    8000269c:	96860613          	addi	a2,a2,-1688 # 80007000 <_trampoline>
    800026a0:	00005697          	auipc	a3,0x5
    800026a4:	96068693          	addi	a3,a3,-1696 # 80007000 <_trampoline>
    800026a8:	8e91                	sub	a3,a3,a2
    800026aa:	040007b7          	lui	a5,0x4000
    800026ae:	17fd                	addi	a5,a5,-1
    800026b0:	07b2                	slli	a5,a5,0xc
    800026b2:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026b4:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026b8:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026ba:	180026f3          	csrr	a3,satp
    800026be:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026c0:	6d38                	ld	a4,88(a0)
    800026c2:	6134                	ld	a3,64(a0)
    800026c4:	6585                	lui	a1,0x1
    800026c6:	96ae                	add	a3,a3,a1
    800026c8:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026ca:	6d38                	ld	a4,88(a0)
    800026cc:	00000697          	auipc	a3,0x0
    800026d0:	13068693          	addi	a3,a3,304 # 800027fc <usertrap>
    800026d4:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026d6:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026d8:	8692                	mv	a3,tp
    800026da:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026dc:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026e0:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026e4:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026e8:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026ec:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026ee:	6f18                	ld	a4,24(a4)
    800026f0:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026f4:	6928                	ld	a0,80(a0)
    800026f6:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800026f8:	00005717          	auipc	a4,0x5
    800026fc:	9a470713          	addi	a4,a4,-1628 # 8000709c <userret>
    80002700:	8f11                	sub	a4,a4,a2
    80002702:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002704:	577d                	li	a4,-1
    80002706:	177e                	slli	a4,a4,0x3f
    80002708:	8d59                	or	a0,a0,a4
    8000270a:	9782                	jalr	a5
}
    8000270c:	60a2                	ld	ra,8(sp)
    8000270e:	6402                	ld	s0,0(sp)
    80002710:	0141                	addi	sp,sp,16
    80002712:	8082                	ret

0000000080002714 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002714:	1101                	addi	sp,sp,-32
    80002716:	ec06                	sd	ra,24(sp)
    80002718:	e822                	sd	s0,16(sp)
    8000271a:	e426                	sd	s1,8(sp)
    8000271c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000271e:	00015497          	auipc	s1,0x15
    80002722:	c3248493          	addi	s1,s1,-974 # 80017350 <tickslock>
    80002726:	8526                	mv	a0,s1
    80002728:	ffffe097          	auipc	ra,0xffffe
    8000272c:	4c2080e7          	jalr	1218(ra) # 80000bea <acquire>
  ticks++;
    80002730:	00006517          	auipc	a0,0x6
    80002734:	38050513          	addi	a0,a0,896 # 80008ab0 <ticks>
    80002738:	411c                	lw	a5,0(a0)
    8000273a:	2785                	addiw	a5,a5,1
    8000273c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000273e:	00000097          	auipc	ra,0x0
    80002742:	998080e7          	jalr	-1640(ra) # 800020d6 <wakeup>
  release(&tickslock);
    80002746:	8526                	mv	a0,s1
    80002748:	ffffe097          	auipc	ra,0xffffe
    8000274c:	556080e7          	jalr	1366(ra) # 80000c9e <release>
}
    80002750:	60e2                	ld	ra,24(sp)
    80002752:	6442                	ld	s0,16(sp)
    80002754:	64a2                	ld	s1,8(sp)
    80002756:	6105                	addi	sp,sp,32
    80002758:	8082                	ret

000000008000275a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000275a:	1101                	addi	sp,sp,-32
    8000275c:	ec06                	sd	ra,24(sp)
    8000275e:	e822                	sd	s0,16(sp)
    80002760:	e426                	sd	s1,8(sp)
    80002762:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002764:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002768:	00074d63          	bltz	a4,80002782 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000276c:	57fd                	li	a5,-1
    8000276e:	17fe                	slli	a5,a5,0x3f
    80002770:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002772:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002774:	06f70363          	beq	a4,a5,800027da <devintr+0x80>
  }
}
    80002778:	60e2                	ld	ra,24(sp)
    8000277a:	6442                	ld	s0,16(sp)
    8000277c:	64a2                	ld	s1,8(sp)
    8000277e:	6105                	addi	sp,sp,32
    80002780:	8082                	ret
     (scause & 0xff) == 9){
    80002782:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002786:	46a5                	li	a3,9
    80002788:	fed792e3          	bne	a5,a3,8000276c <devintr+0x12>
    int irq = plic_claim();
    8000278c:	00003097          	auipc	ra,0x3
    80002790:	61c080e7          	jalr	1564(ra) # 80005da8 <plic_claim>
    80002794:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002796:	47a9                	li	a5,10
    80002798:	02f50763          	beq	a0,a5,800027c6 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000279c:	4785                	li	a5,1
    8000279e:	02f50963          	beq	a0,a5,800027d0 <devintr+0x76>
    return 1;
    800027a2:	4505                	li	a0,1
    } else if(irq){
    800027a4:	d8f1                	beqz	s1,80002778 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027a6:	85a6                	mv	a1,s1
    800027a8:	00006517          	auipc	a0,0x6
    800027ac:	b5850513          	addi	a0,a0,-1192 # 80008300 <states.1727+0x38>
    800027b0:	ffffe097          	auipc	ra,0xffffe
    800027b4:	dde080e7          	jalr	-546(ra) # 8000058e <printf>
      plic_complete(irq);
    800027b8:	8526                	mv	a0,s1
    800027ba:	00003097          	auipc	ra,0x3
    800027be:	612080e7          	jalr	1554(ra) # 80005dcc <plic_complete>
    return 1;
    800027c2:	4505                	li	a0,1
    800027c4:	bf55                	j	80002778 <devintr+0x1e>
      uartintr();
    800027c6:	ffffe097          	auipc	ra,0xffffe
    800027ca:	1e8080e7          	jalr	488(ra) # 800009ae <uartintr>
    800027ce:	b7ed                	j	800027b8 <devintr+0x5e>
      virtio_disk_intr();
    800027d0:	00004097          	auipc	ra,0x4
    800027d4:	b26080e7          	jalr	-1242(ra) # 800062f6 <virtio_disk_intr>
    800027d8:	b7c5                	j	800027b8 <devintr+0x5e>
    if(cpuid() == 0){
    800027da:	fffff097          	auipc	ra,0xfffff
    800027de:	1c0080e7          	jalr	448(ra) # 8000199a <cpuid>
    800027e2:	c901                	beqz	a0,800027f2 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027e4:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027e8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027ea:	14479073          	csrw	sip,a5
    return 2;
    800027ee:	4509                	li	a0,2
    800027f0:	b761                	j	80002778 <devintr+0x1e>
      clockintr();
    800027f2:	00000097          	auipc	ra,0x0
    800027f6:	f22080e7          	jalr	-222(ra) # 80002714 <clockintr>
    800027fa:	b7ed                	j	800027e4 <devintr+0x8a>

00000000800027fc <usertrap>:
{
    800027fc:	1101                	addi	sp,sp,-32
    800027fe:	ec06                	sd	ra,24(sp)
    80002800:	e822                	sd	s0,16(sp)
    80002802:	e426                	sd	s1,8(sp)
    80002804:	e04a                	sd	s2,0(sp)
    80002806:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002808:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000280c:	1007f793          	andi	a5,a5,256
    80002810:	efb9                	bnez	a5,8000286e <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002812:	00003797          	auipc	a5,0x3
    80002816:	48e78793          	addi	a5,a5,1166 # 80005ca0 <kernelvec>
    8000281a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000281e:	fffff097          	auipc	ra,0xfffff
    80002822:	1a8080e7          	jalr	424(ra) # 800019c6 <myproc>
    80002826:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002828:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000282a:	14102773          	csrr	a4,sepc
    8000282e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002830:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002834:	47a1                	li	a5,8
    80002836:	04f70463          	beq	a4,a5,8000287e <usertrap+0x82>
  } else if((which_dev = devintr()) != 0){
    8000283a:	00000097          	auipc	ra,0x0
    8000283e:	f20080e7          	jalr	-224(ra) # 8000275a <devintr>
    80002842:	892a                	mv	s2,a0
    80002844:	c97d                	beqz	a0,8000293a <usertrap+0x13e>
    if(which_dev == 2 && myproc()->interval) {
    80002846:	4789                	li	a5,2
    80002848:	06f50663          	beq	a0,a5,800028b4 <usertrap+0xb8>
  if(killed(p))
    8000284c:	8526                	mv	a0,s1
    8000284e:	00000097          	auipc	ra,0x0
    80002852:	acc080e7          	jalr	-1332(ra) # 8000231a <killed>
    80002856:	10051f63          	bnez	a0,80002974 <usertrap+0x178>
  usertrapret();
    8000285a:	00000097          	auipc	ra,0x0
    8000285e:	e24080e7          	jalr	-476(ra) # 8000267e <usertrapret>
}
    80002862:	60e2                	ld	ra,24(sp)
    80002864:	6442                	ld	s0,16(sp)
    80002866:	64a2                	ld	s1,8(sp)
    80002868:	6902                	ld	s2,0(sp)
    8000286a:	6105                	addi	sp,sp,32
    8000286c:	8082                	ret
    panic("usertrap: not from user mode");
    8000286e:	00006517          	auipc	a0,0x6
    80002872:	ab250513          	addi	a0,a0,-1358 # 80008320 <states.1727+0x58>
    80002876:	ffffe097          	auipc	ra,0xffffe
    8000287a:	cce080e7          	jalr	-818(ra) # 80000544 <panic>
    if(killed(p))
    8000287e:	00000097          	auipc	ra,0x0
    80002882:	a9c080e7          	jalr	-1380(ra) # 8000231a <killed>
    80002886:	e10d                	bnez	a0,800028a8 <usertrap+0xac>
    p->trapframe->epc += 4;
    80002888:	6cb8                	ld	a4,88(s1)
    8000288a:	6f1c                	ld	a5,24(a4)
    8000288c:	0791                	addi	a5,a5,4
    8000288e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002890:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002894:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002898:	10079073          	csrw	sstatus,a5
    syscall();
    8000289c:	00000097          	auipc	ra,0x0
    800028a0:	33c080e7          	jalr	828(ra) # 80002bd8 <syscall>
  int which_dev = 0;
    800028a4:	4901                	li	s2,0
    800028a6:	b75d                	j	8000284c <usertrap+0x50>
      exit(-1);
    800028a8:	557d                	li	a0,-1
    800028aa:	00000097          	auipc	ra,0x0
    800028ae:	8fc080e7          	jalr	-1796(ra) # 800021a6 <exit>
    800028b2:	bfd9                	j	80002888 <usertrap+0x8c>
    if(which_dev == 2 && myproc()->interval) {
    800028b4:	fffff097          	auipc	ra,0xfffff
    800028b8:	112080e7          	jalr	274(ra) # 800019c6 <myproc>
    800028bc:	16c52783          	lw	a5,364(a0)
    800028c0:	ef89                	bnez	a5,800028da <usertrap+0xde>
  if(killed(p))
    800028c2:	8526                	mv	a0,s1
    800028c4:	00000097          	auipc	ra,0x0
    800028c8:	a56080e7          	jalr	-1450(ra) # 8000231a <killed>
    800028cc:	cd45                	beqz	a0,80002984 <usertrap+0x188>
    exit(-1);
    800028ce:	557d                	li	a0,-1
    800028d0:	00000097          	auipc	ra,0x0
    800028d4:	8d6080e7          	jalr	-1834(ra) # 800021a6 <exit>
  if(which_dev == 2)
    800028d8:	a075                	j	80002984 <usertrap+0x188>
      myproc()->ticks_passed--;
    800028da:	fffff097          	auipc	ra,0xfffff
    800028de:	0ec080e7          	jalr	236(ra) # 800019c6 <myproc>
    800028e2:	17052783          	lw	a5,368(a0)
    800028e6:	37fd                	addiw	a5,a5,-1
    800028e8:	16f52823          	sw	a5,368(a0)
      printf("%d\n",myproc()->interval);
    800028ec:	fffff097          	auipc	ra,0xfffff
    800028f0:	0da080e7          	jalr	218(ra) # 800019c6 <myproc>
    800028f4:	16c52583          	lw	a1,364(a0)
    800028f8:	00006517          	auipc	a0,0x6
    800028fc:	b5050513          	addi	a0,a0,-1200 # 80008448 <states.1727+0x180>
    80002900:	ffffe097          	auipc	ra,0xffffe
    80002904:	c8e080e7          	jalr	-882(ra) # 8000058e <printf>
      if(myproc()->ticks_passed == 0) {
    80002908:	fffff097          	auipc	ra,0xfffff
    8000290c:	0be080e7          	jalr	190(ra) # 800019c6 <myproc>
    80002910:	17052783          	lw	a5,368(a0)
    80002914:	f7dd                	bnez	a5,800028c2 <usertrap+0xc6>
        struct trapframe *tf = kalloc();
    80002916:	ffffe097          	auipc	ra,0xffffe
    8000291a:	1e4080e7          	jalr	484(ra) # 80000afa <kalloc>
    8000291e:	892a                	mv	s2,a0
        memmove(tf, p->trapframe, PGSIZE);
    80002920:	6605                	lui	a2,0x1
    80002922:	6cac                	ld	a1,88(s1)
    80002924:	ffffe097          	auipc	ra,0xffffe
    80002928:	422080e7          	jalr	1058(ra) # 80000d46 <memmove>
        p->sigalarm_tf = tf;
    8000292c:	1924b023          	sd	s2,384(s1)
        p->trapframe->epc = p->handler;
    80002930:	6cbc                	ld	a5,88(s1)
    80002932:	1784b703          	ld	a4,376(s1)
    80002936:	ef98                	sd	a4,24(a5)
    80002938:	b769                	j	800028c2 <usertrap+0xc6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000293a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000293e:	5890                	lw	a2,48(s1)
    80002940:	00006517          	auipc	a0,0x6
    80002944:	a0050513          	addi	a0,a0,-1536 # 80008340 <states.1727+0x78>
    80002948:	ffffe097          	auipc	ra,0xffffe
    8000294c:	c46080e7          	jalr	-954(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002950:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002954:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002958:	00006517          	auipc	a0,0x6
    8000295c:	a1850513          	addi	a0,a0,-1512 # 80008370 <states.1727+0xa8>
    80002960:	ffffe097          	auipc	ra,0xffffe
    80002964:	c2e080e7          	jalr	-978(ra) # 8000058e <printf>
    setkilled(p);
    80002968:	8526                	mv	a0,s1
    8000296a:	00000097          	auipc	ra,0x0
    8000296e:	984080e7          	jalr	-1660(ra) # 800022ee <setkilled>
    80002972:	bde9                	j	8000284c <usertrap+0x50>
    exit(-1);
    80002974:	557d                	li	a0,-1
    80002976:	00000097          	auipc	ra,0x0
    8000297a:	830080e7          	jalr	-2000(ra) # 800021a6 <exit>
  if(which_dev == 2)
    8000297e:	4789                	li	a5,2
    80002980:	ecf91de3          	bne	s2,a5,8000285a <usertrap+0x5e>
    yield();
    80002984:	fffff097          	auipc	ra,0xfffff
    80002988:	6b2080e7          	jalr	1714(ra) # 80002036 <yield>
    8000298c:	b5f9                	j	8000285a <usertrap+0x5e>

000000008000298e <kerneltrap>:
{
    8000298e:	7179                	addi	sp,sp,-48
    80002990:	f406                	sd	ra,40(sp)
    80002992:	f022                	sd	s0,32(sp)
    80002994:	ec26                	sd	s1,24(sp)
    80002996:	e84a                	sd	s2,16(sp)
    80002998:	e44e                	sd	s3,8(sp)
    8000299a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000299c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029a0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029a4:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029a8:	1004f793          	andi	a5,s1,256
    800029ac:	cb85                	beqz	a5,800029dc <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ae:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029b2:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029b4:	ef85                	bnez	a5,800029ec <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029b6:	00000097          	auipc	ra,0x0
    800029ba:	da4080e7          	jalr	-604(ra) # 8000275a <devintr>
    800029be:	cd1d                	beqz	a0,800029fc <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029c0:	4789                	li	a5,2
    800029c2:	06f50a63          	beq	a0,a5,80002a36 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029c6:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029ca:	10049073          	csrw	sstatus,s1
}
    800029ce:	70a2                	ld	ra,40(sp)
    800029d0:	7402                	ld	s0,32(sp)
    800029d2:	64e2                	ld	s1,24(sp)
    800029d4:	6942                	ld	s2,16(sp)
    800029d6:	69a2                	ld	s3,8(sp)
    800029d8:	6145                	addi	sp,sp,48
    800029da:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029dc:	00006517          	auipc	a0,0x6
    800029e0:	9b450513          	addi	a0,a0,-1612 # 80008390 <states.1727+0xc8>
    800029e4:	ffffe097          	auipc	ra,0xffffe
    800029e8:	b60080e7          	jalr	-1184(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    800029ec:	00006517          	auipc	a0,0x6
    800029f0:	9cc50513          	addi	a0,a0,-1588 # 800083b8 <states.1727+0xf0>
    800029f4:	ffffe097          	auipc	ra,0xffffe
    800029f8:	b50080e7          	jalr	-1200(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    800029fc:	85ce                	mv	a1,s3
    800029fe:	00006517          	auipc	a0,0x6
    80002a02:	9da50513          	addi	a0,a0,-1574 # 800083d8 <states.1727+0x110>
    80002a06:	ffffe097          	auipc	ra,0xffffe
    80002a0a:	b88080e7          	jalr	-1144(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a0e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a12:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a16:	00006517          	auipc	a0,0x6
    80002a1a:	9d250513          	addi	a0,a0,-1582 # 800083e8 <states.1727+0x120>
    80002a1e:	ffffe097          	auipc	ra,0xffffe
    80002a22:	b70080e7          	jalr	-1168(ra) # 8000058e <printf>
    panic("kerneltrap");
    80002a26:	00006517          	auipc	a0,0x6
    80002a2a:	9da50513          	addi	a0,a0,-1574 # 80008400 <states.1727+0x138>
    80002a2e:	ffffe097          	auipc	ra,0xffffe
    80002a32:	b16080e7          	jalr	-1258(ra) # 80000544 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a36:	fffff097          	auipc	ra,0xfffff
    80002a3a:	f90080e7          	jalr	-112(ra) # 800019c6 <myproc>
    80002a3e:	d541                	beqz	a0,800029c6 <kerneltrap+0x38>
    80002a40:	fffff097          	auipc	ra,0xfffff
    80002a44:	f86080e7          	jalr	-122(ra) # 800019c6 <myproc>
    80002a48:	4d18                	lw	a4,24(a0)
    80002a4a:	4791                	li	a5,4
    80002a4c:	f6f71de3          	bne	a4,a5,800029c6 <kerneltrap+0x38>
    yield();
    80002a50:	fffff097          	auipc	ra,0xfffff
    80002a54:	5e6080e7          	jalr	1510(ra) # 80002036 <yield>
    80002a58:	b7bd                	j	800029c6 <kerneltrap+0x38>

0000000080002a5a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a5a:	1101                	addi	sp,sp,-32
    80002a5c:	ec06                	sd	ra,24(sp)
    80002a5e:	e822                	sd	s0,16(sp)
    80002a60:	e426                	sd	s1,8(sp)
    80002a62:	1000                	addi	s0,sp,32
    80002a64:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a66:	fffff097          	auipc	ra,0xfffff
    80002a6a:	f60080e7          	jalr	-160(ra) # 800019c6 <myproc>
  switch (n) {
    80002a6e:	4795                	li	a5,5
    80002a70:	0497e163          	bltu	a5,s1,80002ab2 <argraw+0x58>
    80002a74:	048a                	slli	s1,s1,0x2
    80002a76:	00006717          	auipc	a4,0x6
    80002a7a:	aa270713          	addi	a4,a4,-1374 # 80008518 <states.1727+0x250>
    80002a7e:	94ba                	add	s1,s1,a4
    80002a80:	409c                	lw	a5,0(s1)
    80002a82:	97ba                	add	a5,a5,a4
    80002a84:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a86:	6d3c                	ld	a5,88(a0)
    80002a88:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a8a:	60e2                	ld	ra,24(sp)
    80002a8c:	6442                	ld	s0,16(sp)
    80002a8e:	64a2                	ld	s1,8(sp)
    80002a90:	6105                	addi	sp,sp,32
    80002a92:	8082                	ret
    return p->trapframe->a1;
    80002a94:	6d3c                	ld	a5,88(a0)
    80002a96:	7fa8                	ld	a0,120(a5)
    80002a98:	bfcd                	j	80002a8a <argraw+0x30>
    return p->trapframe->a2;
    80002a9a:	6d3c                	ld	a5,88(a0)
    80002a9c:	63c8                	ld	a0,128(a5)
    80002a9e:	b7f5                	j	80002a8a <argraw+0x30>
    return p->trapframe->a3;
    80002aa0:	6d3c                	ld	a5,88(a0)
    80002aa2:	67c8                	ld	a0,136(a5)
    80002aa4:	b7dd                	j	80002a8a <argraw+0x30>
    return p->trapframe->a4;
    80002aa6:	6d3c                	ld	a5,88(a0)
    80002aa8:	6bc8                	ld	a0,144(a5)
    80002aaa:	b7c5                	j	80002a8a <argraw+0x30>
    return p->trapframe->a5;
    80002aac:	6d3c                	ld	a5,88(a0)
    80002aae:	6fc8                	ld	a0,152(a5)
    80002ab0:	bfe9                	j	80002a8a <argraw+0x30>
  panic("argraw");
    80002ab2:	00006517          	auipc	a0,0x6
    80002ab6:	95e50513          	addi	a0,a0,-1698 # 80008410 <states.1727+0x148>
    80002aba:	ffffe097          	auipc	ra,0xffffe
    80002abe:	a8a080e7          	jalr	-1398(ra) # 80000544 <panic>

0000000080002ac2 <fetchaddr>:
{
    80002ac2:	1101                	addi	sp,sp,-32
    80002ac4:	ec06                	sd	ra,24(sp)
    80002ac6:	e822                	sd	s0,16(sp)
    80002ac8:	e426                	sd	s1,8(sp)
    80002aca:	e04a                	sd	s2,0(sp)
    80002acc:	1000                	addi	s0,sp,32
    80002ace:	84aa                	mv	s1,a0
    80002ad0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ad2:	fffff097          	auipc	ra,0xfffff
    80002ad6:	ef4080e7          	jalr	-268(ra) # 800019c6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002ada:	653c                	ld	a5,72(a0)
    80002adc:	02f4f863          	bgeu	s1,a5,80002b0c <fetchaddr+0x4a>
    80002ae0:	00848713          	addi	a4,s1,8
    80002ae4:	02e7e663          	bltu	a5,a4,80002b10 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ae8:	46a1                	li	a3,8
    80002aea:	8626                	mv	a2,s1
    80002aec:	85ca                	mv	a1,s2
    80002aee:	6928                	ld	a0,80(a0)
    80002af0:	fffff097          	auipc	ra,0xfffff
    80002af4:	c20080e7          	jalr	-992(ra) # 80001710 <copyin>
    80002af8:	00a03533          	snez	a0,a0
    80002afc:	40a00533          	neg	a0,a0
}
    80002b00:	60e2                	ld	ra,24(sp)
    80002b02:	6442                	ld	s0,16(sp)
    80002b04:	64a2                	ld	s1,8(sp)
    80002b06:	6902                	ld	s2,0(sp)
    80002b08:	6105                	addi	sp,sp,32
    80002b0a:	8082                	ret
    return -1;
    80002b0c:	557d                	li	a0,-1
    80002b0e:	bfcd                	j	80002b00 <fetchaddr+0x3e>
    80002b10:	557d                	li	a0,-1
    80002b12:	b7fd                	j	80002b00 <fetchaddr+0x3e>

0000000080002b14 <fetchstr>:
{
    80002b14:	7179                	addi	sp,sp,-48
    80002b16:	f406                	sd	ra,40(sp)
    80002b18:	f022                	sd	s0,32(sp)
    80002b1a:	ec26                	sd	s1,24(sp)
    80002b1c:	e84a                	sd	s2,16(sp)
    80002b1e:	e44e                	sd	s3,8(sp)
    80002b20:	1800                	addi	s0,sp,48
    80002b22:	892a                	mv	s2,a0
    80002b24:	84ae                	mv	s1,a1
    80002b26:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b28:	fffff097          	auipc	ra,0xfffff
    80002b2c:	e9e080e7          	jalr	-354(ra) # 800019c6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002b30:	86ce                	mv	a3,s3
    80002b32:	864a                	mv	a2,s2
    80002b34:	85a6                	mv	a1,s1
    80002b36:	6928                	ld	a0,80(a0)
    80002b38:	fffff097          	auipc	ra,0xfffff
    80002b3c:	c64080e7          	jalr	-924(ra) # 8000179c <copyinstr>
    80002b40:	00054e63          	bltz	a0,80002b5c <fetchstr+0x48>
  return strlen(buf);
    80002b44:	8526                	mv	a0,s1
    80002b46:	ffffe097          	auipc	ra,0xffffe
    80002b4a:	324080e7          	jalr	804(ra) # 80000e6a <strlen>
}
    80002b4e:	70a2                	ld	ra,40(sp)
    80002b50:	7402                	ld	s0,32(sp)
    80002b52:	64e2                	ld	s1,24(sp)
    80002b54:	6942                	ld	s2,16(sp)
    80002b56:	69a2                	ld	s3,8(sp)
    80002b58:	6145                	addi	sp,sp,48
    80002b5a:	8082                	ret
    return -1;
    80002b5c:	557d                	li	a0,-1
    80002b5e:	bfc5                	j	80002b4e <fetchstr+0x3a>

0000000080002b60 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002b60:	1101                	addi	sp,sp,-32
    80002b62:	ec06                	sd	ra,24(sp)
    80002b64:	e822                	sd	s0,16(sp)
    80002b66:	e426                	sd	s1,8(sp)
    80002b68:	1000                	addi	s0,sp,32
    80002b6a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b6c:	00000097          	auipc	ra,0x0
    80002b70:	eee080e7          	jalr	-274(ra) # 80002a5a <argraw>
    80002b74:	c088                	sw	a0,0(s1)
}
    80002b76:	60e2                	ld	ra,24(sp)
    80002b78:	6442                	ld	s0,16(sp)
    80002b7a:	64a2                	ld	s1,8(sp)
    80002b7c:	6105                	addi	sp,sp,32
    80002b7e:	8082                	ret

0000000080002b80 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002b80:	1101                	addi	sp,sp,-32
    80002b82:	ec06                	sd	ra,24(sp)
    80002b84:	e822                	sd	s0,16(sp)
    80002b86:	e426                	sd	s1,8(sp)
    80002b88:	1000                	addi	s0,sp,32
    80002b8a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b8c:	00000097          	auipc	ra,0x0
    80002b90:	ece080e7          	jalr	-306(ra) # 80002a5a <argraw>
    80002b94:	e088                	sd	a0,0(s1)
}
    80002b96:	60e2                	ld	ra,24(sp)
    80002b98:	6442                	ld	s0,16(sp)
    80002b9a:	64a2                	ld	s1,8(sp)
    80002b9c:	6105                	addi	sp,sp,32
    80002b9e:	8082                	ret

0000000080002ba0 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ba0:	7179                	addi	sp,sp,-48
    80002ba2:	f406                	sd	ra,40(sp)
    80002ba4:	f022                	sd	s0,32(sp)
    80002ba6:	ec26                	sd	s1,24(sp)
    80002ba8:	e84a                	sd	s2,16(sp)
    80002baa:	1800                	addi	s0,sp,48
    80002bac:	84ae                	mv	s1,a1
    80002bae:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002bb0:	fd840593          	addi	a1,s0,-40
    80002bb4:	00000097          	auipc	ra,0x0
    80002bb8:	fcc080e7          	jalr	-52(ra) # 80002b80 <argaddr>
  return fetchstr(addr, buf, max);
    80002bbc:	864a                	mv	a2,s2
    80002bbe:	85a6                	mv	a1,s1
    80002bc0:	fd843503          	ld	a0,-40(s0)
    80002bc4:	00000097          	auipc	ra,0x0
    80002bc8:	f50080e7          	jalr	-176(ra) # 80002b14 <fetchstr>
}
    80002bcc:	70a2                	ld	ra,40(sp)
    80002bce:	7402                	ld	s0,32(sp)
    80002bd0:	64e2                	ld	s1,24(sp)
    80002bd2:	6942                	ld	s2,16(sp)
    80002bd4:	6145                	addi	sp,sp,48
    80002bd6:	8082                	ret

0000000080002bd8 <syscall>:
[SYS_sigreturn] "sigreturn ",
};

void
syscall(void)
{
    80002bd8:	7179                	addi	sp,sp,-48
    80002bda:	f406                	sd	ra,40(sp)
    80002bdc:	f022                	sd	s0,32(sp)
    80002bde:	ec26                	sd	s1,24(sp)
    80002be0:	e84a                	sd	s2,16(sp)
    80002be2:	e44e                	sd	s3,8(sp)
    80002be4:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80002be6:	fffff097          	auipc	ra,0xfffff
    80002bea:	de0080e7          	jalr	-544(ra) # 800019c6 <myproc>
    80002bee:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002bf0:	05853903          	ld	s2,88(a0)
    80002bf4:	0a893783          	ld	a5,168(s2)
    80002bf8:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002bfc:	37fd                	addiw	a5,a5,-1
    80002bfe:	4761                	li	a4,24
    80002c00:	04f76763          	bltu	a4,a5,80002c4e <syscall+0x76>
    80002c04:	00399713          	slli	a4,s3,0x3
    80002c08:	00006797          	auipc	a5,0x6
    80002c0c:	92878793          	addi	a5,a5,-1752 # 80008530 <syscalls>
    80002c10:	97ba                	add	a5,a5,a4
    80002c12:	639c                	ld	a5,0(a5)
    80002c14:	cf8d                	beqz	a5,80002c4e <syscall+0x76>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002c16:	9782                	jalr	a5
    80002c18:	06a93823          	sd	a0,112(s2)

    // Check for trace_flag to be on
    if(p->trace_flag >> num) {  // check for '=='
    80002c1c:	1684a783          	lw	a5,360(s1)
    80002c20:	4137d7bb          	sraw	a5,a5,s3
    80002c24:	c7a1                	beqz	a5,80002c6c <syscall+0x94>
      printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0);
    80002c26:	6cb8                	ld	a4,88(s1)
    80002c28:	098e                	slli	s3,s3,0x3
    80002c2a:	00006797          	auipc	a5,0x6
    80002c2e:	d5e78793          	addi	a5,a5,-674 # 80008988 <syscall_names>
    80002c32:	99be                	add	s3,s3,a5
    80002c34:	7b34                	ld	a3,112(a4)
    80002c36:	0009b603          	ld	a2,0(s3)
    80002c3a:	588c                	lw	a1,48(s1)
    80002c3c:	00005517          	auipc	a0,0x5
    80002c40:	7dc50513          	addi	a0,a0,2012 # 80008418 <states.1727+0x150>
    80002c44:	ffffe097          	auipc	ra,0xffffe
    80002c48:	94a080e7          	jalr	-1718(ra) # 8000058e <printf>
    80002c4c:	a005                	j	80002c6c <syscall+0x94>
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c4e:	86ce                	mv	a3,s3
    80002c50:	15848613          	addi	a2,s1,344
    80002c54:	588c                	lw	a1,48(s1)
    80002c56:	00005517          	auipc	a0,0x5
    80002c5a:	7da50513          	addi	a0,a0,2010 # 80008430 <states.1727+0x168>
    80002c5e:	ffffe097          	auipc	ra,0xffffe
    80002c62:	930080e7          	jalr	-1744(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c66:	6cbc                	ld	a5,88(s1)
    80002c68:	577d                	li	a4,-1
    80002c6a:	fbb8                	sd	a4,112(a5)
  }
}
    80002c6c:	70a2                	ld	ra,40(sp)
    80002c6e:	7402                	ld	s0,32(sp)
    80002c70:	64e2                	ld	s1,24(sp)
    80002c72:	6942                	ld	s2,16(sp)
    80002c74:	69a2                	ld	s3,8(sp)
    80002c76:	6145                	addi	sp,sp,48
    80002c78:	8082                	ret

0000000080002c7a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c7a:	1101                	addi	sp,sp,-32
    80002c7c:	ec06                	sd	ra,24(sp)
    80002c7e:	e822                	sd	s0,16(sp)
    80002c80:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002c82:	fec40593          	addi	a1,s0,-20
    80002c86:	4501                	li	a0,0
    80002c88:	00000097          	auipc	ra,0x0
    80002c8c:	ed8080e7          	jalr	-296(ra) # 80002b60 <argint>
  exit(n);
    80002c90:	fec42503          	lw	a0,-20(s0)
    80002c94:	fffff097          	auipc	ra,0xfffff
    80002c98:	512080e7          	jalr	1298(ra) # 800021a6 <exit>
  return 0;  // not reached
}
    80002c9c:	4501                	li	a0,0
    80002c9e:	60e2                	ld	ra,24(sp)
    80002ca0:	6442                	ld	s0,16(sp)
    80002ca2:	6105                	addi	sp,sp,32
    80002ca4:	8082                	ret

0000000080002ca6 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002ca6:	1141                	addi	sp,sp,-16
    80002ca8:	e406                	sd	ra,8(sp)
    80002caa:	e022                	sd	s0,0(sp)
    80002cac:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002cae:	fffff097          	auipc	ra,0xfffff
    80002cb2:	d18080e7          	jalr	-744(ra) # 800019c6 <myproc>
}
    80002cb6:	5908                	lw	a0,48(a0)
    80002cb8:	60a2                	ld	ra,8(sp)
    80002cba:	6402                	ld	s0,0(sp)
    80002cbc:	0141                	addi	sp,sp,16
    80002cbe:	8082                	ret

0000000080002cc0 <sys_fork>:

uint64
sys_fork(void)
{
    80002cc0:	1141                	addi	sp,sp,-16
    80002cc2:	e406                	sd	ra,8(sp)
    80002cc4:	e022                	sd	s0,0(sp)
    80002cc6:	0800                	addi	s0,sp,16
  return fork();
    80002cc8:	fffff097          	auipc	ra,0xfffff
    80002ccc:	0b4080e7          	jalr	180(ra) # 80001d7c <fork>
}
    80002cd0:	60a2                	ld	ra,8(sp)
    80002cd2:	6402                	ld	s0,0(sp)
    80002cd4:	0141                	addi	sp,sp,16
    80002cd6:	8082                	ret

0000000080002cd8 <sys_wait>:

uint64
sys_wait(void)
{
    80002cd8:	1101                	addi	sp,sp,-32
    80002cda:	ec06                	sd	ra,24(sp)
    80002cdc:	e822                	sd	s0,16(sp)
    80002cde:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002ce0:	fe840593          	addi	a1,s0,-24
    80002ce4:	4501                	li	a0,0
    80002ce6:	00000097          	auipc	ra,0x0
    80002cea:	e9a080e7          	jalr	-358(ra) # 80002b80 <argaddr>
  return wait(p);
    80002cee:	fe843503          	ld	a0,-24(s0)
    80002cf2:	fffff097          	auipc	ra,0xfffff
    80002cf6:	65a080e7          	jalr	1626(ra) # 8000234c <wait>
}
    80002cfa:	60e2                	ld	ra,24(sp)
    80002cfc:	6442                	ld	s0,16(sp)
    80002cfe:	6105                	addi	sp,sp,32
    80002d00:	8082                	ret

0000000080002d02 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d02:	7179                	addi	sp,sp,-48
    80002d04:	f406                	sd	ra,40(sp)
    80002d06:	f022                	sd	s0,32(sp)
    80002d08:	ec26                	sd	s1,24(sp)
    80002d0a:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002d0c:	fdc40593          	addi	a1,s0,-36
    80002d10:	4501                	li	a0,0
    80002d12:	00000097          	auipc	ra,0x0
    80002d16:	e4e080e7          	jalr	-434(ra) # 80002b60 <argint>
  addr = myproc()->sz;
    80002d1a:	fffff097          	auipc	ra,0xfffff
    80002d1e:	cac080e7          	jalr	-852(ra) # 800019c6 <myproc>
    80002d22:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002d24:	fdc42503          	lw	a0,-36(s0)
    80002d28:	fffff097          	auipc	ra,0xfffff
    80002d2c:	ff8080e7          	jalr	-8(ra) # 80001d20 <growproc>
    80002d30:	00054863          	bltz	a0,80002d40 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002d34:	8526                	mv	a0,s1
    80002d36:	70a2                	ld	ra,40(sp)
    80002d38:	7402                	ld	s0,32(sp)
    80002d3a:	64e2                	ld	s1,24(sp)
    80002d3c:	6145                	addi	sp,sp,48
    80002d3e:	8082                	ret
    return -1;
    80002d40:	54fd                	li	s1,-1
    80002d42:	bfcd                	j	80002d34 <sys_sbrk+0x32>

0000000080002d44 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d44:	7139                	addi	sp,sp,-64
    80002d46:	fc06                	sd	ra,56(sp)
    80002d48:	f822                	sd	s0,48(sp)
    80002d4a:	f426                	sd	s1,40(sp)
    80002d4c:	f04a                	sd	s2,32(sp)
    80002d4e:	ec4e                	sd	s3,24(sp)
    80002d50:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002d52:	fcc40593          	addi	a1,s0,-52
    80002d56:	4501                	li	a0,0
    80002d58:	00000097          	auipc	ra,0x0
    80002d5c:	e08080e7          	jalr	-504(ra) # 80002b60 <argint>
  acquire(&tickslock);
    80002d60:	00014517          	auipc	a0,0x14
    80002d64:	5f050513          	addi	a0,a0,1520 # 80017350 <tickslock>
    80002d68:	ffffe097          	auipc	ra,0xffffe
    80002d6c:	e82080e7          	jalr	-382(ra) # 80000bea <acquire>
  ticks0 = ticks;
    80002d70:	00006917          	auipc	s2,0x6
    80002d74:	d4092903          	lw	s2,-704(s2) # 80008ab0 <ticks>
  while(ticks - ticks0 < n){
    80002d78:	fcc42783          	lw	a5,-52(s0)
    80002d7c:	cf9d                	beqz	a5,80002dba <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d7e:	00014997          	auipc	s3,0x14
    80002d82:	5d298993          	addi	s3,s3,1490 # 80017350 <tickslock>
    80002d86:	00006497          	auipc	s1,0x6
    80002d8a:	d2a48493          	addi	s1,s1,-726 # 80008ab0 <ticks>
    if(killed(myproc())){
    80002d8e:	fffff097          	auipc	ra,0xfffff
    80002d92:	c38080e7          	jalr	-968(ra) # 800019c6 <myproc>
    80002d96:	fffff097          	auipc	ra,0xfffff
    80002d9a:	584080e7          	jalr	1412(ra) # 8000231a <killed>
    80002d9e:	ed15                	bnez	a0,80002dda <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002da0:	85ce                	mv	a1,s3
    80002da2:	8526                	mv	a0,s1
    80002da4:	fffff097          	auipc	ra,0xfffff
    80002da8:	2ce080e7          	jalr	718(ra) # 80002072 <sleep>
  while(ticks - ticks0 < n){
    80002dac:	409c                	lw	a5,0(s1)
    80002dae:	412787bb          	subw	a5,a5,s2
    80002db2:	fcc42703          	lw	a4,-52(s0)
    80002db6:	fce7ece3          	bltu	a5,a4,80002d8e <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002dba:	00014517          	auipc	a0,0x14
    80002dbe:	59650513          	addi	a0,a0,1430 # 80017350 <tickslock>
    80002dc2:	ffffe097          	auipc	ra,0xffffe
    80002dc6:	edc080e7          	jalr	-292(ra) # 80000c9e <release>
  return 0;
    80002dca:	4501                	li	a0,0
}
    80002dcc:	70e2                	ld	ra,56(sp)
    80002dce:	7442                	ld	s0,48(sp)
    80002dd0:	74a2                	ld	s1,40(sp)
    80002dd2:	7902                	ld	s2,32(sp)
    80002dd4:	69e2                	ld	s3,24(sp)
    80002dd6:	6121                	addi	sp,sp,64
    80002dd8:	8082                	ret
      release(&tickslock);
    80002dda:	00014517          	auipc	a0,0x14
    80002dde:	57650513          	addi	a0,a0,1398 # 80017350 <tickslock>
    80002de2:	ffffe097          	auipc	ra,0xffffe
    80002de6:	ebc080e7          	jalr	-324(ra) # 80000c9e <release>
      return -1;
    80002dea:	557d                	li	a0,-1
    80002dec:	b7c5                	j	80002dcc <sys_sleep+0x88>

0000000080002dee <sys_kill>:

uint64
sys_kill(void)
{
    80002dee:	1101                	addi	sp,sp,-32
    80002df0:	ec06                	sd	ra,24(sp)
    80002df2:	e822                	sd	s0,16(sp)
    80002df4:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002df6:	fec40593          	addi	a1,s0,-20
    80002dfa:	4501                	li	a0,0
    80002dfc:	00000097          	auipc	ra,0x0
    80002e00:	d64080e7          	jalr	-668(ra) # 80002b60 <argint>
  return kill(pid);
    80002e04:	fec42503          	lw	a0,-20(s0)
    80002e08:	fffff097          	auipc	ra,0xfffff
    80002e0c:	474080e7          	jalr	1140(ra) # 8000227c <kill>
}
    80002e10:	60e2                	ld	ra,24(sp)
    80002e12:	6442                	ld	s0,16(sp)
    80002e14:	6105                	addi	sp,sp,32
    80002e16:	8082                	ret

0000000080002e18 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e18:	1101                	addi	sp,sp,-32
    80002e1a:	ec06                	sd	ra,24(sp)
    80002e1c:	e822                	sd	s0,16(sp)
    80002e1e:	e426                	sd	s1,8(sp)
    80002e20:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e22:	00014517          	auipc	a0,0x14
    80002e26:	52e50513          	addi	a0,a0,1326 # 80017350 <tickslock>
    80002e2a:	ffffe097          	auipc	ra,0xffffe
    80002e2e:	dc0080e7          	jalr	-576(ra) # 80000bea <acquire>
  xticks = ticks;
    80002e32:	00006497          	auipc	s1,0x6
    80002e36:	c7e4a483          	lw	s1,-898(s1) # 80008ab0 <ticks>
  release(&tickslock);
    80002e3a:	00014517          	auipc	a0,0x14
    80002e3e:	51650513          	addi	a0,a0,1302 # 80017350 <tickslock>
    80002e42:	ffffe097          	auipc	ra,0xffffe
    80002e46:	e5c080e7          	jalr	-420(ra) # 80000c9e <release>
  return xticks;
}
    80002e4a:	02049513          	slli	a0,s1,0x20
    80002e4e:	9101                	srli	a0,a0,0x20
    80002e50:	60e2                	ld	ra,24(sp)
    80002e52:	6442                	ld	s0,16(sp)
    80002e54:	64a2                	ld	s1,8(sp)
    80002e56:	6105                	addi	sp,sp,32
    80002e58:	8082                	ret

0000000080002e5a <sys_trace>:

// sets the trace_flag to the first argument (a0)
uint64
sys_trace(void)
{
    80002e5a:	1141                	addi	sp,sp,-16
    80002e5c:	e406                	sd	ra,8(sp)
    80002e5e:	e022                	sd	s0,0(sp)
    80002e60:	0800                	addi	s0,sp,16
  argint(0, &myproc()->trace_flag); //arg(a0, trace_flag) // returns void
    80002e62:	fffff097          	auipc	ra,0xfffff
    80002e66:	b64080e7          	jalr	-1180(ra) # 800019c6 <myproc>
    80002e6a:	16850593          	addi	a1,a0,360
    80002e6e:	4501                	li	a0,0
    80002e70:	00000097          	auipc	ra,0x0
    80002e74:	cf0080e7          	jalr	-784(ra) # 80002b60 <argint>
  return 0;
}
    80002e78:	4501                	li	a0,0
    80002e7a:	60a2                	ld	ra,8(sp)
    80002e7c:	6402                	ld	s0,0(sp)
    80002e7e:	0141                	addi	sp,sp,16
    80002e80:	8082                	ret

0000000080002e82 <sys_sigalarm>:

// sets the 
uint64
sys_sigalarm(void)
{
    80002e82:	1101                	addi	sp,sp,-32
    80002e84:	ec06                	sd	ra,24(sp)
    80002e86:	e822                	sd	s0,16(sp)
    80002e88:	e426                	sd	s1,8(sp)
    80002e8a:	1000                	addi	s0,sp,32
  // sets the interval and handler after every tick
  argint(0, &myproc()->interval);
    80002e8c:	fffff097          	auipc	ra,0xfffff
    80002e90:	b3a080e7          	jalr	-1222(ra) # 800019c6 <myproc>
    80002e94:	16c50593          	addi	a1,a0,364
    80002e98:	4501                	li	a0,0
    80002e9a:	00000097          	auipc	ra,0x0
    80002e9e:	cc6080e7          	jalr	-826(ra) # 80002b60 <argint>
  argaddr(1, &myproc()->handler);
    80002ea2:	fffff097          	auipc	ra,0xfffff
    80002ea6:	b24080e7          	jalr	-1244(ra) # 800019c6 <myproc>
    80002eaa:	17850593          	addi	a1,a0,376
    80002eae:	4505                	li	a0,1
    80002eb0:	00000097          	auipc	ra,0x0
    80002eb4:	cd0080e7          	jalr	-816(ra) # 80002b80 <argaddr>
  
  // sets ticks_passed as the interval
  myproc()->ticks_passed = myproc()->interval;
    80002eb8:	fffff097          	auipc	ra,0xfffff
    80002ebc:	b0e080e7          	jalr	-1266(ra) # 800019c6 <myproc>
    80002ec0:	84aa                	mv	s1,a0
    80002ec2:	fffff097          	auipc	ra,0xfffff
    80002ec6:	b04080e7          	jalr	-1276(ra) # 800019c6 <myproc>
    80002eca:	16c4a783          	lw	a5,364(s1)
    80002ece:	16f52823          	sw	a5,368(a0)
  return 0;
}
    80002ed2:	4501                	li	a0,0
    80002ed4:	60e2                	ld	ra,24(sp)
    80002ed6:	6442                	ld	s0,16(sp)
    80002ed8:	64a2                	ld	s1,8(sp)
    80002eda:	6105                	addi	sp,sp,32
    80002edc:	8082                	ret

0000000080002ede <sys_sigreturn>:

uint64 
sys_sigreturn(void)
{
    80002ede:	1101                	addi	sp,sp,-32
    80002ee0:	ec06                	sd	ra,24(sp)
    80002ee2:	e822                	sd	s0,16(sp)
    80002ee4:	e426                	sd	s1,8(sp)
    80002ee6:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002ee8:	fffff097          	auipc	ra,0xfffff
    80002eec:	ade080e7          	jalr	-1314(ra) # 800019c6 <myproc>
    80002ef0:	84aa                	mv	s1,a0
  memmove(p->trapframe, p->sigalarm_tf, PGSIZE);
    80002ef2:	6605                	lui	a2,0x1
    80002ef4:	18053583          	ld	a1,384(a0)
    80002ef8:	6d28                	ld	a0,88(a0)
    80002efa:	ffffe097          	auipc	ra,0xffffe
    80002efe:	e4c080e7          	jalr	-436(ra) # 80000d46 <memmove>
  kfree(p->sigalarm_tf);
    80002f02:	1804b503          	ld	a0,384(s1)
    80002f06:	ffffe097          	auipc	ra,0xffffe
    80002f0a:	af8080e7          	jalr	-1288(ra) # 800009fe <kfree>
  p->ticks_passed = p->interval;
    80002f0e:	16c4a783          	lw	a5,364(s1)
    80002f12:	16f4a823          	sw	a5,368(s1)
  return p->trapframe->a0;
    80002f16:	6cbc                	ld	a5,88(s1)
    80002f18:	7ba8                	ld	a0,112(a5)
    80002f1a:	60e2                	ld	ra,24(sp)
    80002f1c:	6442                	ld	s0,16(sp)
    80002f1e:	64a2                	ld	s1,8(sp)
    80002f20:	6105                	addi	sp,sp,32
    80002f22:	8082                	ret

0000000080002f24 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f24:	7179                	addi	sp,sp,-48
    80002f26:	f406                	sd	ra,40(sp)
    80002f28:	f022                	sd	s0,32(sp)
    80002f2a:	ec26                	sd	s1,24(sp)
    80002f2c:	e84a                	sd	s2,16(sp)
    80002f2e:	e44e                	sd	s3,8(sp)
    80002f30:	e052                	sd	s4,0(sp)
    80002f32:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f34:	00005597          	auipc	a1,0x5
    80002f38:	6cc58593          	addi	a1,a1,1740 # 80008600 <syscalls+0xd0>
    80002f3c:	00014517          	auipc	a0,0x14
    80002f40:	42c50513          	addi	a0,a0,1068 # 80017368 <bcache>
    80002f44:	ffffe097          	auipc	ra,0xffffe
    80002f48:	c16080e7          	jalr	-1002(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f4c:	0001c797          	auipc	a5,0x1c
    80002f50:	41c78793          	addi	a5,a5,1052 # 8001f368 <bcache+0x8000>
    80002f54:	0001c717          	auipc	a4,0x1c
    80002f58:	67c70713          	addi	a4,a4,1660 # 8001f5d0 <bcache+0x8268>
    80002f5c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f60:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f64:	00014497          	auipc	s1,0x14
    80002f68:	41c48493          	addi	s1,s1,1052 # 80017380 <bcache+0x18>
    b->next = bcache.head.next;
    80002f6c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f6e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f70:	00005a17          	auipc	s4,0x5
    80002f74:	698a0a13          	addi	s4,s4,1688 # 80008608 <syscalls+0xd8>
    b->next = bcache.head.next;
    80002f78:	2b893783          	ld	a5,696(s2)
    80002f7c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f7e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f82:	85d2                	mv	a1,s4
    80002f84:	01048513          	addi	a0,s1,16
    80002f88:	00001097          	auipc	ra,0x1
    80002f8c:	4c4080e7          	jalr	1220(ra) # 8000444c <initsleeplock>
    bcache.head.next->prev = b;
    80002f90:	2b893783          	ld	a5,696(s2)
    80002f94:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f96:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f9a:	45848493          	addi	s1,s1,1112
    80002f9e:	fd349de3          	bne	s1,s3,80002f78 <binit+0x54>
  }
}
    80002fa2:	70a2                	ld	ra,40(sp)
    80002fa4:	7402                	ld	s0,32(sp)
    80002fa6:	64e2                	ld	s1,24(sp)
    80002fa8:	6942                	ld	s2,16(sp)
    80002faa:	69a2                	ld	s3,8(sp)
    80002fac:	6a02                	ld	s4,0(sp)
    80002fae:	6145                	addi	sp,sp,48
    80002fb0:	8082                	ret

0000000080002fb2 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002fb2:	7179                	addi	sp,sp,-48
    80002fb4:	f406                	sd	ra,40(sp)
    80002fb6:	f022                	sd	s0,32(sp)
    80002fb8:	ec26                	sd	s1,24(sp)
    80002fba:	e84a                	sd	s2,16(sp)
    80002fbc:	e44e                	sd	s3,8(sp)
    80002fbe:	1800                	addi	s0,sp,48
    80002fc0:	89aa                	mv	s3,a0
    80002fc2:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002fc4:	00014517          	auipc	a0,0x14
    80002fc8:	3a450513          	addi	a0,a0,932 # 80017368 <bcache>
    80002fcc:	ffffe097          	auipc	ra,0xffffe
    80002fd0:	c1e080e7          	jalr	-994(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fd4:	0001c497          	auipc	s1,0x1c
    80002fd8:	64c4b483          	ld	s1,1612(s1) # 8001f620 <bcache+0x82b8>
    80002fdc:	0001c797          	auipc	a5,0x1c
    80002fe0:	5f478793          	addi	a5,a5,1524 # 8001f5d0 <bcache+0x8268>
    80002fe4:	02f48f63          	beq	s1,a5,80003022 <bread+0x70>
    80002fe8:	873e                	mv	a4,a5
    80002fea:	a021                	j	80002ff2 <bread+0x40>
    80002fec:	68a4                	ld	s1,80(s1)
    80002fee:	02e48a63          	beq	s1,a4,80003022 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002ff2:	449c                	lw	a5,8(s1)
    80002ff4:	ff379ce3          	bne	a5,s3,80002fec <bread+0x3a>
    80002ff8:	44dc                	lw	a5,12(s1)
    80002ffa:	ff2799e3          	bne	a5,s2,80002fec <bread+0x3a>
      b->refcnt++;
    80002ffe:	40bc                	lw	a5,64(s1)
    80003000:	2785                	addiw	a5,a5,1
    80003002:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003004:	00014517          	auipc	a0,0x14
    80003008:	36450513          	addi	a0,a0,868 # 80017368 <bcache>
    8000300c:	ffffe097          	auipc	ra,0xffffe
    80003010:	c92080e7          	jalr	-878(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80003014:	01048513          	addi	a0,s1,16
    80003018:	00001097          	auipc	ra,0x1
    8000301c:	46e080e7          	jalr	1134(ra) # 80004486 <acquiresleep>
      return b;
    80003020:	a8b9                	j	8000307e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003022:	0001c497          	auipc	s1,0x1c
    80003026:	5f64b483          	ld	s1,1526(s1) # 8001f618 <bcache+0x82b0>
    8000302a:	0001c797          	auipc	a5,0x1c
    8000302e:	5a678793          	addi	a5,a5,1446 # 8001f5d0 <bcache+0x8268>
    80003032:	00f48863          	beq	s1,a5,80003042 <bread+0x90>
    80003036:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003038:	40bc                	lw	a5,64(s1)
    8000303a:	cf81                	beqz	a5,80003052 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000303c:	64a4                	ld	s1,72(s1)
    8000303e:	fee49de3          	bne	s1,a4,80003038 <bread+0x86>
  panic("bget: no buffers");
    80003042:	00005517          	auipc	a0,0x5
    80003046:	5ce50513          	addi	a0,a0,1486 # 80008610 <syscalls+0xe0>
    8000304a:	ffffd097          	auipc	ra,0xffffd
    8000304e:	4fa080e7          	jalr	1274(ra) # 80000544 <panic>
      b->dev = dev;
    80003052:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003056:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000305a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000305e:	4785                	li	a5,1
    80003060:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003062:	00014517          	auipc	a0,0x14
    80003066:	30650513          	addi	a0,a0,774 # 80017368 <bcache>
    8000306a:	ffffe097          	auipc	ra,0xffffe
    8000306e:	c34080e7          	jalr	-972(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80003072:	01048513          	addi	a0,s1,16
    80003076:	00001097          	auipc	ra,0x1
    8000307a:	410080e7          	jalr	1040(ra) # 80004486 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000307e:	409c                	lw	a5,0(s1)
    80003080:	cb89                	beqz	a5,80003092 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003082:	8526                	mv	a0,s1
    80003084:	70a2                	ld	ra,40(sp)
    80003086:	7402                	ld	s0,32(sp)
    80003088:	64e2                	ld	s1,24(sp)
    8000308a:	6942                	ld	s2,16(sp)
    8000308c:	69a2                	ld	s3,8(sp)
    8000308e:	6145                	addi	sp,sp,48
    80003090:	8082                	ret
    virtio_disk_rw(b, 0);
    80003092:	4581                	li	a1,0
    80003094:	8526                	mv	a0,s1
    80003096:	00003097          	auipc	ra,0x3
    8000309a:	fd2080e7          	jalr	-46(ra) # 80006068 <virtio_disk_rw>
    b->valid = 1;
    8000309e:	4785                	li	a5,1
    800030a0:	c09c                	sw	a5,0(s1)
  return b;
    800030a2:	b7c5                	j	80003082 <bread+0xd0>

00000000800030a4 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800030a4:	1101                	addi	sp,sp,-32
    800030a6:	ec06                	sd	ra,24(sp)
    800030a8:	e822                	sd	s0,16(sp)
    800030aa:	e426                	sd	s1,8(sp)
    800030ac:	1000                	addi	s0,sp,32
    800030ae:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030b0:	0541                	addi	a0,a0,16
    800030b2:	00001097          	auipc	ra,0x1
    800030b6:	46e080e7          	jalr	1134(ra) # 80004520 <holdingsleep>
    800030ba:	cd01                	beqz	a0,800030d2 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030bc:	4585                	li	a1,1
    800030be:	8526                	mv	a0,s1
    800030c0:	00003097          	auipc	ra,0x3
    800030c4:	fa8080e7          	jalr	-88(ra) # 80006068 <virtio_disk_rw>
}
    800030c8:	60e2                	ld	ra,24(sp)
    800030ca:	6442                	ld	s0,16(sp)
    800030cc:	64a2                	ld	s1,8(sp)
    800030ce:	6105                	addi	sp,sp,32
    800030d0:	8082                	ret
    panic("bwrite");
    800030d2:	00005517          	auipc	a0,0x5
    800030d6:	55650513          	addi	a0,a0,1366 # 80008628 <syscalls+0xf8>
    800030da:	ffffd097          	auipc	ra,0xffffd
    800030de:	46a080e7          	jalr	1130(ra) # 80000544 <panic>

00000000800030e2 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030e2:	1101                	addi	sp,sp,-32
    800030e4:	ec06                	sd	ra,24(sp)
    800030e6:	e822                	sd	s0,16(sp)
    800030e8:	e426                	sd	s1,8(sp)
    800030ea:	e04a                	sd	s2,0(sp)
    800030ec:	1000                	addi	s0,sp,32
    800030ee:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030f0:	01050913          	addi	s2,a0,16
    800030f4:	854a                	mv	a0,s2
    800030f6:	00001097          	auipc	ra,0x1
    800030fa:	42a080e7          	jalr	1066(ra) # 80004520 <holdingsleep>
    800030fe:	c92d                	beqz	a0,80003170 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003100:	854a                	mv	a0,s2
    80003102:	00001097          	auipc	ra,0x1
    80003106:	3da080e7          	jalr	986(ra) # 800044dc <releasesleep>

  acquire(&bcache.lock);
    8000310a:	00014517          	auipc	a0,0x14
    8000310e:	25e50513          	addi	a0,a0,606 # 80017368 <bcache>
    80003112:	ffffe097          	auipc	ra,0xffffe
    80003116:	ad8080e7          	jalr	-1320(ra) # 80000bea <acquire>
  b->refcnt--;
    8000311a:	40bc                	lw	a5,64(s1)
    8000311c:	37fd                	addiw	a5,a5,-1
    8000311e:	0007871b          	sext.w	a4,a5
    80003122:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003124:	eb05                	bnez	a4,80003154 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003126:	68bc                	ld	a5,80(s1)
    80003128:	64b8                	ld	a4,72(s1)
    8000312a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000312c:	64bc                	ld	a5,72(s1)
    8000312e:	68b8                	ld	a4,80(s1)
    80003130:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003132:	0001c797          	auipc	a5,0x1c
    80003136:	23678793          	addi	a5,a5,566 # 8001f368 <bcache+0x8000>
    8000313a:	2b87b703          	ld	a4,696(a5)
    8000313e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003140:	0001c717          	auipc	a4,0x1c
    80003144:	49070713          	addi	a4,a4,1168 # 8001f5d0 <bcache+0x8268>
    80003148:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000314a:	2b87b703          	ld	a4,696(a5)
    8000314e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003150:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003154:	00014517          	auipc	a0,0x14
    80003158:	21450513          	addi	a0,a0,532 # 80017368 <bcache>
    8000315c:	ffffe097          	auipc	ra,0xffffe
    80003160:	b42080e7          	jalr	-1214(ra) # 80000c9e <release>
}
    80003164:	60e2                	ld	ra,24(sp)
    80003166:	6442                	ld	s0,16(sp)
    80003168:	64a2                	ld	s1,8(sp)
    8000316a:	6902                	ld	s2,0(sp)
    8000316c:	6105                	addi	sp,sp,32
    8000316e:	8082                	ret
    panic("brelse");
    80003170:	00005517          	auipc	a0,0x5
    80003174:	4c050513          	addi	a0,a0,1216 # 80008630 <syscalls+0x100>
    80003178:	ffffd097          	auipc	ra,0xffffd
    8000317c:	3cc080e7          	jalr	972(ra) # 80000544 <panic>

0000000080003180 <bpin>:

void
bpin(struct buf *b) {
    80003180:	1101                	addi	sp,sp,-32
    80003182:	ec06                	sd	ra,24(sp)
    80003184:	e822                	sd	s0,16(sp)
    80003186:	e426                	sd	s1,8(sp)
    80003188:	1000                	addi	s0,sp,32
    8000318a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000318c:	00014517          	auipc	a0,0x14
    80003190:	1dc50513          	addi	a0,a0,476 # 80017368 <bcache>
    80003194:	ffffe097          	auipc	ra,0xffffe
    80003198:	a56080e7          	jalr	-1450(ra) # 80000bea <acquire>
  b->refcnt++;
    8000319c:	40bc                	lw	a5,64(s1)
    8000319e:	2785                	addiw	a5,a5,1
    800031a0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031a2:	00014517          	auipc	a0,0x14
    800031a6:	1c650513          	addi	a0,a0,454 # 80017368 <bcache>
    800031aa:	ffffe097          	auipc	ra,0xffffe
    800031ae:	af4080e7          	jalr	-1292(ra) # 80000c9e <release>
}
    800031b2:	60e2                	ld	ra,24(sp)
    800031b4:	6442                	ld	s0,16(sp)
    800031b6:	64a2                	ld	s1,8(sp)
    800031b8:	6105                	addi	sp,sp,32
    800031ba:	8082                	ret

00000000800031bc <bunpin>:

void
bunpin(struct buf *b) {
    800031bc:	1101                	addi	sp,sp,-32
    800031be:	ec06                	sd	ra,24(sp)
    800031c0:	e822                	sd	s0,16(sp)
    800031c2:	e426                	sd	s1,8(sp)
    800031c4:	1000                	addi	s0,sp,32
    800031c6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031c8:	00014517          	auipc	a0,0x14
    800031cc:	1a050513          	addi	a0,a0,416 # 80017368 <bcache>
    800031d0:	ffffe097          	auipc	ra,0xffffe
    800031d4:	a1a080e7          	jalr	-1510(ra) # 80000bea <acquire>
  b->refcnt--;
    800031d8:	40bc                	lw	a5,64(s1)
    800031da:	37fd                	addiw	a5,a5,-1
    800031dc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031de:	00014517          	auipc	a0,0x14
    800031e2:	18a50513          	addi	a0,a0,394 # 80017368 <bcache>
    800031e6:	ffffe097          	auipc	ra,0xffffe
    800031ea:	ab8080e7          	jalr	-1352(ra) # 80000c9e <release>
}
    800031ee:	60e2                	ld	ra,24(sp)
    800031f0:	6442                	ld	s0,16(sp)
    800031f2:	64a2                	ld	s1,8(sp)
    800031f4:	6105                	addi	sp,sp,32
    800031f6:	8082                	ret

00000000800031f8 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031f8:	1101                	addi	sp,sp,-32
    800031fa:	ec06                	sd	ra,24(sp)
    800031fc:	e822                	sd	s0,16(sp)
    800031fe:	e426                	sd	s1,8(sp)
    80003200:	e04a                	sd	s2,0(sp)
    80003202:	1000                	addi	s0,sp,32
    80003204:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003206:	00d5d59b          	srliw	a1,a1,0xd
    8000320a:	0001d797          	auipc	a5,0x1d
    8000320e:	83a7a783          	lw	a5,-1990(a5) # 8001fa44 <sb+0x1c>
    80003212:	9dbd                	addw	a1,a1,a5
    80003214:	00000097          	auipc	ra,0x0
    80003218:	d9e080e7          	jalr	-610(ra) # 80002fb2 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000321c:	0074f713          	andi	a4,s1,7
    80003220:	4785                	li	a5,1
    80003222:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003226:	14ce                	slli	s1,s1,0x33
    80003228:	90d9                	srli	s1,s1,0x36
    8000322a:	00950733          	add	a4,a0,s1
    8000322e:	05874703          	lbu	a4,88(a4)
    80003232:	00e7f6b3          	and	a3,a5,a4
    80003236:	c69d                	beqz	a3,80003264 <bfree+0x6c>
    80003238:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000323a:	94aa                	add	s1,s1,a0
    8000323c:	fff7c793          	not	a5,a5
    80003240:	8ff9                	and	a5,a5,a4
    80003242:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003246:	00001097          	auipc	ra,0x1
    8000324a:	120080e7          	jalr	288(ra) # 80004366 <log_write>
  brelse(bp);
    8000324e:	854a                	mv	a0,s2
    80003250:	00000097          	auipc	ra,0x0
    80003254:	e92080e7          	jalr	-366(ra) # 800030e2 <brelse>
}
    80003258:	60e2                	ld	ra,24(sp)
    8000325a:	6442                	ld	s0,16(sp)
    8000325c:	64a2                	ld	s1,8(sp)
    8000325e:	6902                	ld	s2,0(sp)
    80003260:	6105                	addi	sp,sp,32
    80003262:	8082                	ret
    panic("freeing free block");
    80003264:	00005517          	auipc	a0,0x5
    80003268:	3d450513          	addi	a0,a0,980 # 80008638 <syscalls+0x108>
    8000326c:	ffffd097          	auipc	ra,0xffffd
    80003270:	2d8080e7          	jalr	728(ra) # 80000544 <panic>

0000000080003274 <balloc>:
{
    80003274:	711d                	addi	sp,sp,-96
    80003276:	ec86                	sd	ra,88(sp)
    80003278:	e8a2                	sd	s0,80(sp)
    8000327a:	e4a6                	sd	s1,72(sp)
    8000327c:	e0ca                	sd	s2,64(sp)
    8000327e:	fc4e                	sd	s3,56(sp)
    80003280:	f852                	sd	s4,48(sp)
    80003282:	f456                	sd	s5,40(sp)
    80003284:	f05a                	sd	s6,32(sp)
    80003286:	ec5e                	sd	s7,24(sp)
    80003288:	e862                	sd	s8,16(sp)
    8000328a:	e466                	sd	s9,8(sp)
    8000328c:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000328e:	0001c797          	auipc	a5,0x1c
    80003292:	79e7a783          	lw	a5,1950(a5) # 8001fa2c <sb+0x4>
    80003296:	10078163          	beqz	a5,80003398 <balloc+0x124>
    8000329a:	8baa                	mv	s7,a0
    8000329c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000329e:	0001cb17          	auipc	s6,0x1c
    800032a2:	78ab0b13          	addi	s6,s6,1930 # 8001fa28 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032a6:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800032a8:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032aa:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800032ac:	6c89                	lui	s9,0x2
    800032ae:	a061                	j	80003336 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032b0:	974a                	add	a4,a4,s2
    800032b2:	8fd5                	or	a5,a5,a3
    800032b4:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800032b8:	854a                	mv	a0,s2
    800032ba:	00001097          	auipc	ra,0x1
    800032be:	0ac080e7          	jalr	172(ra) # 80004366 <log_write>
        brelse(bp);
    800032c2:	854a                	mv	a0,s2
    800032c4:	00000097          	auipc	ra,0x0
    800032c8:	e1e080e7          	jalr	-482(ra) # 800030e2 <brelse>
  bp = bread(dev, bno);
    800032cc:	85a6                	mv	a1,s1
    800032ce:	855e                	mv	a0,s7
    800032d0:	00000097          	auipc	ra,0x0
    800032d4:	ce2080e7          	jalr	-798(ra) # 80002fb2 <bread>
    800032d8:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032da:	40000613          	li	a2,1024
    800032de:	4581                	li	a1,0
    800032e0:	05850513          	addi	a0,a0,88
    800032e4:	ffffe097          	auipc	ra,0xffffe
    800032e8:	a02080e7          	jalr	-1534(ra) # 80000ce6 <memset>
  log_write(bp);
    800032ec:	854a                	mv	a0,s2
    800032ee:	00001097          	auipc	ra,0x1
    800032f2:	078080e7          	jalr	120(ra) # 80004366 <log_write>
  brelse(bp);
    800032f6:	854a                	mv	a0,s2
    800032f8:	00000097          	auipc	ra,0x0
    800032fc:	dea080e7          	jalr	-534(ra) # 800030e2 <brelse>
}
    80003300:	8526                	mv	a0,s1
    80003302:	60e6                	ld	ra,88(sp)
    80003304:	6446                	ld	s0,80(sp)
    80003306:	64a6                	ld	s1,72(sp)
    80003308:	6906                	ld	s2,64(sp)
    8000330a:	79e2                	ld	s3,56(sp)
    8000330c:	7a42                	ld	s4,48(sp)
    8000330e:	7aa2                	ld	s5,40(sp)
    80003310:	7b02                	ld	s6,32(sp)
    80003312:	6be2                	ld	s7,24(sp)
    80003314:	6c42                	ld	s8,16(sp)
    80003316:	6ca2                	ld	s9,8(sp)
    80003318:	6125                	addi	sp,sp,96
    8000331a:	8082                	ret
    brelse(bp);
    8000331c:	854a                	mv	a0,s2
    8000331e:	00000097          	auipc	ra,0x0
    80003322:	dc4080e7          	jalr	-572(ra) # 800030e2 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003326:	015c87bb          	addw	a5,s9,s5
    8000332a:	00078a9b          	sext.w	s5,a5
    8000332e:	004b2703          	lw	a4,4(s6)
    80003332:	06eaf363          	bgeu	s5,a4,80003398 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003336:	41fad79b          	sraiw	a5,s5,0x1f
    8000333a:	0137d79b          	srliw	a5,a5,0x13
    8000333e:	015787bb          	addw	a5,a5,s5
    80003342:	40d7d79b          	sraiw	a5,a5,0xd
    80003346:	01cb2583          	lw	a1,28(s6)
    8000334a:	9dbd                	addw	a1,a1,a5
    8000334c:	855e                	mv	a0,s7
    8000334e:	00000097          	auipc	ra,0x0
    80003352:	c64080e7          	jalr	-924(ra) # 80002fb2 <bread>
    80003356:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003358:	004b2503          	lw	a0,4(s6)
    8000335c:	000a849b          	sext.w	s1,s5
    80003360:	8662                	mv	a2,s8
    80003362:	faa4fde3          	bgeu	s1,a0,8000331c <balloc+0xa8>
      m = 1 << (bi % 8);
    80003366:	41f6579b          	sraiw	a5,a2,0x1f
    8000336a:	01d7d69b          	srliw	a3,a5,0x1d
    8000336e:	00c6873b          	addw	a4,a3,a2
    80003372:	00777793          	andi	a5,a4,7
    80003376:	9f95                	subw	a5,a5,a3
    80003378:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000337c:	4037571b          	sraiw	a4,a4,0x3
    80003380:	00e906b3          	add	a3,s2,a4
    80003384:	0586c683          	lbu	a3,88(a3)
    80003388:	00d7f5b3          	and	a1,a5,a3
    8000338c:	d195                	beqz	a1,800032b0 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000338e:	2605                	addiw	a2,a2,1
    80003390:	2485                	addiw	s1,s1,1
    80003392:	fd4618e3          	bne	a2,s4,80003362 <balloc+0xee>
    80003396:	b759                	j	8000331c <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003398:	00005517          	auipc	a0,0x5
    8000339c:	2b850513          	addi	a0,a0,696 # 80008650 <syscalls+0x120>
    800033a0:	ffffd097          	auipc	ra,0xffffd
    800033a4:	1ee080e7          	jalr	494(ra) # 8000058e <printf>
  return 0;
    800033a8:	4481                	li	s1,0
    800033aa:	bf99                	j	80003300 <balloc+0x8c>

00000000800033ac <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800033ac:	7179                	addi	sp,sp,-48
    800033ae:	f406                	sd	ra,40(sp)
    800033b0:	f022                	sd	s0,32(sp)
    800033b2:	ec26                	sd	s1,24(sp)
    800033b4:	e84a                	sd	s2,16(sp)
    800033b6:	e44e                	sd	s3,8(sp)
    800033b8:	e052                	sd	s4,0(sp)
    800033ba:	1800                	addi	s0,sp,48
    800033bc:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033be:	47ad                	li	a5,11
    800033c0:	02b7e763          	bltu	a5,a1,800033ee <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800033c4:	02059493          	slli	s1,a1,0x20
    800033c8:	9081                	srli	s1,s1,0x20
    800033ca:	048a                	slli	s1,s1,0x2
    800033cc:	94aa                	add	s1,s1,a0
    800033ce:	0504a903          	lw	s2,80(s1)
    800033d2:	06091e63          	bnez	s2,8000344e <bmap+0xa2>
      addr = balloc(ip->dev);
    800033d6:	4108                	lw	a0,0(a0)
    800033d8:	00000097          	auipc	ra,0x0
    800033dc:	e9c080e7          	jalr	-356(ra) # 80003274 <balloc>
    800033e0:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033e4:	06090563          	beqz	s2,8000344e <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    800033e8:	0524a823          	sw	s2,80(s1)
    800033ec:	a08d                	j	8000344e <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800033ee:	ff45849b          	addiw	s1,a1,-12
    800033f2:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033f6:	0ff00793          	li	a5,255
    800033fa:	08e7e563          	bltu	a5,a4,80003484 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800033fe:	08052903          	lw	s2,128(a0)
    80003402:	00091d63          	bnez	s2,8000341c <bmap+0x70>
      addr = balloc(ip->dev);
    80003406:	4108                	lw	a0,0(a0)
    80003408:	00000097          	auipc	ra,0x0
    8000340c:	e6c080e7          	jalr	-404(ra) # 80003274 <balloc>
    80003410:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003414:	02090d63          	beqz	s2,8000344e <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003418:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000341c:	85ca                	mv	a1,s2
    8000341e:	0009a503          	lw	a0,0(s3)
    80003422:	00000097          	auipc	ra,0x0
    80003426:	b90080e7          	jalr	-1136(ra) # 80002fb2 <bread>
    8000342a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000342c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003430:	02049593          	slli	a1,s1,0x20
    80003434:	9181                	srli	a1,a1,0x20
    80003436:	058a                	slli	a1,a1,0x2
    80003438:	00b784b3          	add	s1,a5,a1
    8000343c:	0004a903          	lw	s2,0(s1)
    80003440:	02090063          	beqz	s2,80003460 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003444:	8552                	mv	a0,s4
    80003446:	00000097          	auipc	ra,0x0
    8000344a:	c9c080e7          	jalr	-868(ra) # 800030e2 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000344e:	854a                	mv	a0,s2
    80003450:	70a2                	ld	ra,40(sp)
    80003452:	7402                	ld	s0,32(sp)
    80003454:	64e2                	ld	s1,24(sp)
    80003456:	6942                	ld	s2,16(sp)
    80003458:	69a2                	ld	s3,8(sp)
    8000345a:	6a02                	ld	s4,0(sp)
    8000345c:	6145                	addi	sp,sp,48
    8000345e:	8082                	ret
      addr = balloc(ip->dev);
    80003460:	0009a503          	lw	a0,0(s3)
    80003464:	00000097          	auipc	ra,0x0
    80003468:	e10080e7          	jalr	-496(ra) # 80003274 <balloc>
    8000346c:	0005091b          	sext.w	s2,a0
      if(addr){
    80003470:	fc090ae3          	beqz	s2,80003444 <bmap+0x98>
        a[bn] = addr;
    80003474:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003478:	8552                	mv	a0,s4
    8000347a:	00001097          	auipc	ra,0x1
    8000347e:	eec080e7          	jalr	-276(ra) # 80004366 <log_write>
    80003482:	b7c9                	j	80003444 <bmap+0x98>
  panic("bmap: out of range");
    80003484:	00005517          	auipc	a0,0x5
    80003488:	1e450513          	addi	a0,a0,484 # 80008668 <syscalls+0x138>
    8000348c:	ffffd097          	auipc	ra,0xffffd
    80003490:	0b8080e7          	jalr	184(ra) # 80000544 <panic>

0000000080003494 <iget>:
{
    80003494:	7179                	addi	sp,sp,-48
    80003496:	f406                	sd	ra,40(sp)
    80003498:	f022                	sd	s0,32(sp)
    8000349a:	ec26                	sd	s1,24(sp)
    8000349c:	e84a                	sd	s2,16(sp)
    8000349e:	e44e                	sd	s3,8(sp)
    800034a0:	e052                	sd	s4,0(sp)
    800034a2:	1800                	addi	s0,sp,48
    800034a4:	89aa                	mv	s3,a0
    800034a6:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800034a8:	0001c517          	auipc	a0,0x1c
    800034ac:	5a050513          	addi	a0,a0,1440 # 8001fa48 <itable>
    800034b0:	ffffd097          	auipc	ra,0xffffd
    800034b4:	73a080e7          	jalr	1850(ra) # 80000bea <acquire>
  empty = 0;
    800034b8:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034ba:	0001c497          	auipc	s1,0x1c
    800034be:	5a648493          	addi	s1,s1,1446 # 8001fa60 <itable+0x18>
    800034c2:	0001e697          	auipc	a3,0x1e
    800034c6:	02e68693          	addi	a3,a3,46 # 800214f0 <log>
    800034ca:	a039                	j	800034d8 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034cc:	02090b63          	beqz	s2,80003502 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034d0:	08848493          	addi	s1,s1,136
    800034d4:	02d48a63          	beq	s1,a3,80003508 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034d8:	449c                	lw	a5,8(s1)
    800034da:	fef059e3          	blez	a5,800034cc <iget+0x38>
    800034de:	4098                	lw	a4,0(s1)
    800034e0:	ff3716e3          	bne	a4,s3,800034cc <iget+0x38>
    800034e4:	40d8                	lw	a4,4(s1)
    800034e6:	ff4713e3          	bne	a4,s4,800034cc <iget+0x38>
      ip->ref++;
    800034ea:	2785                	addiw	a5,a5,1
    800034ec:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800034ee:	0001c517          	auipc	a0,0x1c
    800034f2:	55a50513          	addi	a0,a0,1370 # 8001fa48 <itable>
    800034f6:	ffffd097          	auipc	ra,0xffffd
    800034fa:	7a8080e7          	jalr	1960(ra) # 80000c9e <release>
      return ip;
    800034fe:	8926                	mv	s2,s1
    80003500:	a03d                	j	8000352e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003502:	f7f9                	bnez	a5,800034d0 <iget+0x3c>
    80003504:	8926                	mv	s2,s1
    80003506:	b7e9                	j	800034d0 <iget+0x3c>
  if(empty == 0)
    80003508:	02090c63          	beqz	s2,80003540 <iget+0xac>
  ip->dev = dev;
    8000350c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003510:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003514:	4785                	li	a5,1
    80003516:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000351a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000351e:	0001c517          	auipc	a0,0x1c
    80003522:	52a50513          	addi	a0,a0,1322 # 8001fa48 <itable>
    80003526:	ffffd097          	auipc	ra,0xffffd
    8000352a:	778080e7          	jalr	1912(ra) # 80000c9e <release>
}
    8000352e:	854a                	mv	a0,s2
    80003530:	70a2                	ld	ra,40(sp)
    80003532:	7402                	ld	s0,32(sp)
    80003534:	64e2                	ld	s1,24(sp)
    80003536:	6942                	ld	s2,16(sp)
    80003538:	69a2                	ld	s3,8(sp)
    8000353a:	6a02                	ld	s4,0(sp)
    8000353c:	6145                	addi	sp,sp,48
    8000353e:	8082                	ret
    panic("iget: no inodes");
    80003540:	00005517          	auipc	a0,0x5
    80003544:	14050513          	addi	a0,a0,320 # 80008680 <syscalls+0x150>
    80003548:	ffffd097          	auipc	ra,0xffffd
    8000354c:	ffc080e7          	jalr	-4(ra) # 80000544 <panic>

0000000080003550 <fsinit>:
fsinit(int dev) {
    80003550:	7179                	addi	sp,sp,-48
    80003552:	f406                	sd	ra,40(sp)
    80003554:	f022                	sd	s0,32(sp)
    80003556:	ec26                	sd	s1,24(sp)
    80003558:	e84a                	sd	s2,16(sp)
    8000355a:	e44e                	sd	s3,8(sp)
    8000355c:	1800                	addi	s0,sp,48
    8000355e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003560:	4585                	li	a1,1
    80003562:	00000097          	auipc	ra,0x0
    80003566:	a50080e7          	jalr	-1456(ra) # 80002fb2 <bread>
    8000356a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000356c:	0001c997          	auipc	s3,0x1c
    80003570:	4bc98993          	addi	s3,s3,1212 # 8001fa28 <sb>
    80003574:	02000613          	li	a2,32
    80003578:	05850593          	addi	a1,a0,88
    8000357c:	854e                	mv	a0,s3
    8000357e:	ffffd097          	auipc	ra,0xffffd
    80003582:	7c8080e7          	jalr	1992(ra) # 80000d46 <memmove>
  brelse(bp);
    80003586:	8526                	mv	a0,s1
    80003588:	00000097          	auipc	ra,0x0
    8000358c:	b5a080e7          	jalr	-1190(ra) # 800030e2 <brelse>
  if(sb.magic != FSMAGIC)
    80003590:	0009a703          	lw	a4,0(s3)
    80003594:	102037b7          	lui	a5,0x10203
    80003598:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000359c:	02f71263          	bne	a4,a5,800035c0 <fsinit+0x70>
  initlog(dev, &sb);
    800035a0:	0001c597          	auipc	a1,0x1c
    800035a4:	48858593          	addi	a1,a1,1160 # 8001fa28 <sb>
    800035a8:	854a                	mv	a0,s2
    800035aa:	00001097          	auipc	ra,0x1
    800035ae:	b40080e7          	jalr	-1216(ra) # 800040ea <initlog>
}
    800035b2:	70a2                	ld	ra,40(sp)
    800035b4:	7402                	ld	s0,32(sp)
    800035b6:	64e2                	ld	s1,24(sp)
    800035b8:	6942                	ld	s2,16(sp)
    800035ba:	69a2                	ld	s3,8(sp)
    800035bc:	6145                	addi	sp,sp,48
    800035be:	8082                	ret
    panic("invalid file system");
    800035c0:	00005517          	auipc	a0,0x5
    800035c4:	0d050513          	addi	a0,a0,208 # 80008690 <syscalls+0x160>
    800035c8:	ffffd097          	auipc	ra,0xffffd
    800035cc:	f7c080e7          	jalr	-132(ra) # 80000544 <panic>

00000000800035d0 <iinit>:
{
    800035d0:	7179                	addi	sp,sp,-48
    800035d2:	f406                	sd	ra,40(sp)
    800035d4:	f022                	sd	s0,32(sp)
    800035d6:	ec26                	sd	s1,24(sp)
    800035d8:	e84a                	sd	s2,16(sp)
    800035da:	e44e                	sd	s3,8(sp)
    800035dc:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800035de:	00005597          	auipc	a1,0x5
    800035e2:	0ca58593          	addi	a1,a1,202 # 800086a8 <syscalls+0x178>
    800035e6:	0001c517          	auipc	a0,0x1c
    800035ea:	46250513          	addi	a0,a0,1122 # 8001fa48 <itable>
    800035ee:	ffffd097          	auipc	ra,0xffffd
    800035f2:	56c080e7          	jalr	1388(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    800035f6:	0001c497          	auipc	s1,0x1c
    800035fa:	47a48493          	addi	s1,s1,1146 # 8001fa70 <itable+0x28>
    800035fe:	0001e997          	auipc	s3,0x1e
    80003602:	f0298993          	addi	s3,s3,-254 # 80021500 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003606:	00005917          	auipc	s2,0x5
    8000360a:	0aa90913          	addi	s2,s2,170 # 800086b0 <syscalls+0x180>
    8000360e:	85ca                	mv	a1,s2
    80003610:	8526                	mv	a0,s1
    80003612:	00001097          	auipc	ra,0x1
    80003616:	e3a080e7          	jalr	-454(ra) # 8000444c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000361a:	08848493          	addi	s1,s1,136
    8000361e:	ff3498e3          	bne	s1,s3,8000360e <iinit+0x3e>
}
    80003622:	70a2                	ld	ra,40(sp)
    80003624:	7402                	ld	s0,32(sp)
    80003626:	64e2                	ld	s1,24(sp)
    80003628:	6942                	ld	s2,16(sp)
    8000362a:	69a2                	ld	s3,8(sp)
    8000362c:	6145                	addi	sp,sp,48
    8000362e:	8082                	ret

0000000080003630 <ialloc>:
{
    80003630:	715d                	addi	sp,sp,-80
    80003632:	e486                	sd	ra,72(sp)
    80003634:	e0a2                	sd	s0,64(sp)
    80003636:	fc26                	sd	s1,56(sp)
    80003638:	f84a                	sd	s2,48(sp)
    8000363a:	f44e                	sd	s3,40(sp)
    8000363c:	f052                	sd	s4,32(sp)
    8000363e:	ec56                	sd	s5,24(sp)
    80003640:	e85a                	sd	s6,16(sp)
    80003642:	e45e                	sd	s7,8(sp)
    80003644:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003646:	0001c717          	auipc	a4,0x1c
    8000364a:	3ee72703          	lw	a4,1006(a4) # 8001fa34 <sb+0xc>
    8000364e:	4785                	li	a5,1
    80003650:	04e7fa63          	bgeu	a5,a4,800036a4 <ialloc+0x74>
    80003654:	8aaa                	mv	s5,a0
    80003656:	8bae                	mv	s7,a1
    80003658:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000365a:	0001ca17          	auipc	s4,0x1c
    8000365e:	3cea0a13          	addi	s4,s4,974 # 8001fa28 <sb>
    80003662:	00048b1b          	sext.w	s6,s1
    80003666:	0044d593          	srli	a1,s1,0x4
    8000366a:	018a2783          	lw	a5,24(s4)
    8000366e:	9dbd                	addw	a1,a1,a5
    80003670:	8556                	mv	a0,s5
    80003672:	00000097          	auipc	ra,0x0
    80003676:	940080e7          	jalr	-1728(ra) # 80002fb2 <bread>
    8000367a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000367c:	05850993          	addi	s3,a0,88
    80003680:	00f4f793          	andi	a5,s1,15
    80003684:	079a                	slli	a5,a5,0x6
    80003686:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003688:	00099783          	lh	a5,0(s3)
    8000368c:	c3a1                	beqz	a5,800036cc <ialloc+0x9c>
    brelse(bp);
    8000368e:	00000097          	auipc	ra,0x0
    80003692:	a54080e7          	jalr	-1452(ra) # 800030e2 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003696:	0485                	addi	s1,s1,1
    80003698:	00ca2703          	lw	a4,12(s4)
    8000369c:	0004879b          	sext.w	a5,s1
    800036a0:	fce7e1e3          	bltu	a5,a4,80003662 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800036a4:	00005517          	auipc	a0,0x5
    800036a8:	01450513          	addi	a0,a0,20 # 800086b8 <syscalls+0x188>
    800036ac:	ffffd097          	auipc	ra,0xffffd
    800036b0:	ee2080e7          	jalr	-286(ra) # 8000058e <printf>
  return 0;
    800036b4:	4501                	li	a0,0
}
    800036b6:	60a6                	ld	ra,72(sp)
    800036b8:	6406                	ld	s0,64(sp)
    800036ba:	74e2                	ld	s1,56(sp)
    800036bc:	7942                	ld	s2,48(sp)
    800036be:	79a2                	ld	s3,40(sp)
    800036c0:	7a02                	ld	s4,32(sp)
    800036c2:	6ae2                	ld	s5,24(sp)
    800036c4:	6b42                	ld	s6,16(sp)
    800036c6:	6ba2                	ld	s7,8(sp)
    800036c8:	6161                	addi	sp,sp,80
    800036ca:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800036cc:	04000613          	li	a2,64
    800036d0:	4581                	li	a1,0
    800036d2:	854e                	mv	a0,s3
    800036d4:	ffffd097          	auipc	ra,0xffffd
    800036d8:	612080e7          	jalr	1554(ra) # 80000ce6 <memset>
      dip->type = type;
    800036dc:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036e0:	854a                	mv	a0,s2
    800036e2:	00001097          	auipc	ra,0x1
    800036e6:	c84080e7          	jalr	-892(ra) # 80004366 <log_write>
      brelse(bp);
    800036ea:	854a                	mv	a0,s2
    800036ec:	00000097          	auipc	ra,0x0
    800036f0:	9f6080e7          	jalr	-1546(ra) # 800030e2 <brelse>
      return iget(dev, inum);
    800036f4:	85da                	mv	a1,s6
    800036f6:	8556                	mv	a0,s5
    800036f8:	00000097          	auipc	ra,0x0
    800036fc:	d9c080e7          	jalr	-612(ra) # 80003494 <iget>
    80003700:	bf5d                	j	800036b6 <ialloc+0x86>

0000000080003702 <iupdate>:
{
    80003702:	1101                	addi	sp,sp,-32
    80003704:	ec06                	sd	ra,24(sp)
    80003706:	e822                	sd	s0,16(sp)
    80003708:	e426                	sd	s1,8(sp)
    8000370a:	e04a                	sd	s2,0(sp)
    8000370c:	1000                	addi	s0,sp,32
    8000370e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003710:	415c                	lw	a5,4(a0)
    80003712:	0047d79b          	srliw	a5,a5,0x4
    80003716:	0001c597          	auipc	a1,0x1c
    8000371a:	32a5a583          	lw	a1,810(a1) # 8001fa40 <sb+0x18>
    8000371e:	9dbd                	addw	a1,a1,a5
    80003720:	4108                	lw	a0,0(a0)
    80003722:	00000097          	auipc	ra,0x0
    80003726:	890080e7          	jalr	-1904(ra) # 80002fb2 <bread>
    8000372a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000372c:	05850793          	addi	a5,a0,88
    80003730:	40c8                	lw	a0,4(s1)
    80003732:	893d                	andi	a0,a0,15
    80003734:	051a                	slli	a0,a0,0x6
    80003736:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003738:	04449703          	lh	a4,68(s1)
    8000373c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003740:	04649703          	lh	a4,70(s1)
    80003744:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003748:	04849703          	lh	a4,72(s1)
    8000374c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003750:	04a49703          	lh	a4,74(s1)
    80003754:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003758:	44f8                	lw	a4,76(s1)
    8000375a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000375c:	03400613          	li	a2,52
    80003760:	05048593          	addi	a1,s1,80
    80003764:	0531                	addi	a0,a0,12
    80003766:	ffffd097          	auipc	ra,0xffffd
    8000376a:	5e0080e7          	jalr	1504(ra) # 80000d46 <memmove>
  log_write(bp);
    8000376e:	854a                	mv	a0,s2
    80003770:	00001097          	auipc	ra,0x1
    80003774:	bf6080e7          	jalr	-1034(ra) # 80004366 <log_write>
  brelse(bp);
    80003778:	854a                	mv	a0,s2
    8000377a:	00000097          	auipc	ra,0x0
    8000377e:	968080e7          	jalr	-1688(ra) # 800030e2 <brelse>
}
    80003782:	60e2                	ld	ra,24(sp)
    80003784:	6442                	ld	s0,16(sp)
    80003786:	64a2                	ld	s1,8(sp)
    80003788:	6902                	ld	s2,0(sp)
    8000378a:	6105                	addi	sp,sp,32
    8000378c:	8082                	ret

000000008000378e <idup>:
{
    8000378e:	1101                	addi	sp,sp,-32
    80003790:	ec06                	sd	ra,24(sp)
    80003792:	e822                	sd	s0,16(sp)
    80003794:	e426                	sd	s1,8(sp)
    80003796:	1000                	addi	s0,sp,32
    80003798:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000379a:	0001c517          	auipc	a0,0x1c
    8000379e:	2ae50513          	addi	a0,a0,686 # 8001fa48 <itable>
    800037a2:	ffffd097          	auipc	ra,0xffffd
    800037a6:	448080e7          	jalr	1096(ra) # 80000bea <acquire>
  ip->ref++;
    800037aa:	449c                	lw	a5,8(s1)
    800037ac:	2785                	addiw	a5,a5,1
    800037ae:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800037b0:	0001c517          	auipc	a0,0x1c
    800037b4:	29850513          	addi	a0,a0,664 # 8001fa48 <itable>
    800037b8:	ffffd097          	auipc	ra,0xffffd
    800037bc:	4e6080e7          	jalr	1254(ra) # 80000c9e <release>
}
    800037c0:	8526                	mv	a0,s1
    800037c2:	60e2                	ld	ra,24(sp)
    800037c4:	6442                	ld	s0,16(sp)
    800037c6:	64a2                	ld	s1,8(sp)
    800037c8:	6105                	addi	sp,sp,32
    800037ca:	8082                	ret

00000000800037cc <ilock>:
{
    800037cc:	1101                	addi	sp,sp,-32
    800037ce:	ec06                	sd	ra,24(sp)
    800037d0:	e822                	sd	s0,16(sp)
    800037d2:	e426                	sd	s1,8(sp)
    800037d4:	e04a                	sd	s2,0(sp)
    800037d6:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037d8:	c115                	beqz	a0,800037fc <ilock+0x30>
    800037da:	84aa                	mv	s1,a0
    800037dc:	451c                	lw	a5,8(a0)
    800037de:	00f05f63          	blez	a5,800037fc <ilock+0x30>
  acquiresleep(&ip->lock);
    800037e2:	0541                	addi	a0,a0,16
    800037e4:	00001097          	auipc	ra,0x1
    800037e8:	ca2080e7          	jalr	-862(ra) # 80004486 <acquiresleep>
  if(ip->valid == 0){
    800037ec:	40bc                	lw	a5,64(s1)
    800037ee:	cf99                	beqz	a5,8000380c <ilock+0x40>
}
    800037f0:	60e2                	ld	ra,24(sp)
    800037f2:	6442                	ld	s0,16(sp)
    800037f4:	64a2                	ld	s1,8(sp)
    800037f6:	6902                	ld	s2,0(sp)
    800037f8:	6105                	addi	sp,sp,32
    800037fa:	8082                	ret
    panic("ilock");
    800037fc:	00005517          	auipc	a0,0x5
    80003800:	ed450513          	addi	a0,a0,-300 # 800086d0 <syscalls+0x1a0>
    80003804:	ffffd097          	auipc	ra,0xffffd
    80003808:	d40080e7          	jalr	-704(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000380c:	40dc                	lw	a5,4(s1)
    8000380e:	0047d79b          	srliw	a5,a5,0x4
    80003812:	0001c597          	auipc	a1,0x1c
    80003816:	22e5a583          	lw	a1,558(a1) # 8001fa40 <sb+0x18>
    8000381a:	9dbd                	addw	a1,a1,a5
    8000381c:	4088                	lw	a0,0(s1)
    8000381e:	fffff097          	auipc	ra,0xfffff
    80003822:	794080e7          	jalr	1940(ra) # 80002fb2 <bread>
    80003826:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003828:	05850593          	addi	a1,a0,88
    8000382c:	40dc                	lw	a5,4(s1)
    8000382e:	8bbd                	andi	a5,a5,15
    80003830:	079a                	slli	a5,a5,0x6
    80003832:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003834:	00059783          	lh	a5,0(a1)
    80003838:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000383c:	00259783          	lh	a5,2(a1)
    80003840:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003844:	00459783          	lh	a5,4(a1)
    80003848:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000384c:	00659783          	lh	a5,6(a1)
    80003850:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003854:	459c                	lw	a5,8(a1)
    80003856:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003858:	03400613          	li	a2,52
    8000385c:	05b1                	addi	a1,a1,12
    8000385e:	05048513          	addi	a0,s1,80
    80003862:	ffffd097          	auipc	ra,0xffffd
    80003866:	4e4080e7          	jalr	1252(ra) # 80000d46 <memmove>
    brelse(bp);
    8000386a:	854a                	mv	a0,s2
    8000386c:	00000097          	auipc	ra,0x0
    80003870:	876080e7          	jalr	-1930(ra) # 800030e2 <brelse>
    ip->valid = 1;
    80003874:	4785                	li	a5,1
    80003876:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003878:	04449783          	lh	a5,68(s1)
    8000387c:	fbb5                	bnez	a5,800037f0 <ilock+0x24>
      panic("ilock: no type");
    8000387e:	00005517          	auipc	a0,0x5
    80003882:	e5a50513          	addi	a0,a0,-422 # 800086d8 <syscalls+0x1a8>
    80003886:	ffffd097          	auipc	ra,0xffffd
    8000388a:	cbe080e7          	jalr	-834(ra) # 80000544 <panic>

000000008000388e <iunlock>:
{
    8000388e:	1101                	addi	sp,sp,-32
    80003890:	ec06                	sd	ra,24(sp)
    80003892:	e822                	sd	s0,16(sp)
    80003894:	e426                	sd	s1,8(sp)
    80003896:	e04a                	sd	s2,0(sp)
    80003898:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000389a:	c905                	beqz	a0,800038ca <iunlock+0x3c>
    8000389c:	84aa                	mv	s1,a0
    8000389e:	01050913          	addi	s2,a0,16
    800038a2:	854a                	mv	a0,s2
    800038a4:	00001097          	auipc	ra,0x1
    800038a8:	c7c080e7          	jalr	-900(ra) # 80004520 <holdingsleep>
    800038ac:	cd19                	beqz	a0,800038ca <iunlock+0x3c>
    800038ae:	449c                	lw	a5,8(s1)
    800038b0:	00f05d63          	blez	a5,800038ca <iunlock+0x3c>
  releasesleep(&ip->lock);
    800038b4:	854a                	mv	a0,s2
    800038b6:	00001097          	auipc	ra,0x1
    800038ba:	c26080e7          	jalr	-986(ra) # 800044dc <releasesleep>
}
    800038be:	60e2                	ld	ra,24(sp)
    800038c0:	6442                	ld	s0,16(sp)
    800038c2:	64a2                	ld	s1,8(sp)
    800038c4:	6902                	ld	s2,0(sp)
    800038c6:	6105                	addi	sp,sp,32
    800038c8:	8082                	ret
    panic("iunlock");
    800038ca:	00005517          	auipc	a0,0x5
    800038ce:	e1e50513          	addi	a0,a0,-482 # 800086e8 <syscalls+0x1b8>
    800038d2:	ffffd097          	auipc	ra,0xffffd
    800038d6:	c72080e7          	jalr	-910(ra) # 80000544 <panic>

00000000800038da <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038da:	7179                	addi	sp,sp,-48
    800038dc:	f406                	sd	ra,40(sp)
    800038de:	f022                	sd	s0,32(sp)
    800038e0:	ec26                	sd	s1,24(sp)
    800038e2:	e84a                	sd	s2,16(sp)
    800038e4:	e44e                	sd	s3,8(sp)
    800038e6:	e052                	sd	s4,0(sp)
    800038e8:	1800                	addi	s0,sp,48
    800038ea:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038ec:	05050493          	addi	s1,a0,80
    800038f0:	08050913          	addi	s2,a0,128
    800038f4:	a021                	j	800038fc <itrunc+0x22>
    800038f6:	0491                	addi	s1,s1,4
    800038f8:	01248d63          	beq	s1,s2,80003912 <itrunc+0x38>
    if(ip->addrs[i]){
    800038fc:	408c                	lw	a1,0(s1)
    800038fe:	dde5                	beqz	a1,800038f6 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003900:	0009a503          	lw	a0,0(s3)
    80003904:	00000097          	auipc	ra,0x0
    80003908:	8f4080e7          	jalr	-1804(ra) # 800031f8 <bfree>
      ip->addrs[i] = 0;
    8000390c:	0004a023          	sw	zero,0(s1)
    80003910:	b7dd                	j	800038f6 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003912:	0809a583          	lw	a1,128(s3)
    80003916:	e185                	bnez	a1,80003936 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003918:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000391c:	854e                	mv	a0,s3
    8000391e:	00000097          	auipc	ra,0x0
    80003922:	de4080e7          	jalr	-540(ra) # 80003702 <iupdate>
}
    80003926:	70a2                	ld	ra,40(sp)
    80003928:	7402                	ld	s0,32(sp)
    8000392a:	64e2                	ld	s1,24(sp)
    8000392c:	6942                	ld	s2,16(sp)
    8000392e:	69a2                	ld	s3,8(sp)
    80003930:	6a02                	ld	s4,0(sp)
    80003932:	6145                	addi	sp,sp,48
    80003934:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003936:	0009a503          	lw	a0,0(s3)
    8000393a:	fffff097          	auipc	ra,0xfffff
    8000393e:	678080e7          	jalr	1656(ra) # 80002fb2 <bread>
    80003942:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003944:	05850493          	addi	s1,a0,88
    80003948:	45850913          	addi	s2,a0,1112
    8000394c:	a811                	j	80003960 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    8000394e:	0009a503          	lw	a0,0(s3)
    80003952:	00000097          	auipc	ra,0x0
    80003956:	8a6080e7          	jalr	-1882(ra) # 800031f8 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000395a:	0491                	addi	s1,s1,4
    8000395c:	01248563          	beq	s1,s2,80003966 <itrunc+0x8c>
      if(a[j])
    80003960:	408c                	lw	a1,0(s1)
    80003962:	dde5                	beqz	a1,8000395a <itrunc+0x80>
    80003964:	b7ed                	j	8000394e <itrunc+0x74>
    brelse(bp);
    80003966:	8552                	mv	a0,s4
    80003968:	fffff097          	auipc	ra,0xfffff
    8000396c:	77a080e7          	jalr	1914(ra) # 800030e2 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003970:	0809a583          	lw	a1,128(s3)
    80003974:	0009a503          	lw	a0,0(s3)
    80003978:	00000097          	auipc	ra,0x0
    8000397c:	880080e7          	jalr	-1920(ra) # 800031f8 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003980:	0809a023          	sw	zero,128(s3)
    80003984:	bf51                	j	80003918 <itrunc+0x3e>

0000000080003986 <iput>:
{
    80003986:	1101                	addi	sp,sp,-32
    80003988:	ec06                	sd	ra,24(sp)
    8000398a:	e822                	sd	s0,16(sp)
    8000398c:	e426                	sd	s1,8(sp)
    8000398e:	e04a                	sd	s2,0(sp)
    80003990:	1000                	addi	s0,sp,32
    80003992:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003994:	0001c517          	auipc	a0,0x1c
    80003998:	0b450513          	addi	a0,a0,180 # 8001fa48 <itable>
    8000399c:	ffffd097          	auipc	ra,0xffffd
    800039a0:	24e080e7          	jalr	590(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039a4:	4498                	lw	a4,8(s1)
    800039a6:	4785                	li	a5,1
    800039a8:	02f70363          	beq	a4,a5,800039ce <iput+0x48>
  ip->ref--;
    800039ac:	449c                	lw	a5,8(s1)
    800039ae:	37fd                	addiw	a5,a5,-1
    800039b0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039b2:	0001c517          	auipc	a0,0x1c
    800039b6:	09650513          	addi	a0,a0,150 # 8001fa48 <itable>
    800039ba:	ffffd097          	auipc	ra,0xffffd
    800039be:	2e4080e7          	jalr	740(ra) # 80000c9e <release>
}
    800039c2:	60e2                	ld	ra,24(sp)
    800039c4:	6442                	ld	s0,16(sp)
    800039c6:	64a2                	ld	s1,8(sp)
    800039c8:	6902                	ld	s2,0(sp)
    800039ca:	6105                	addi	sp,sp,32
    800039cc:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039ce:	40bc                	lw	a5,64(s1)
    800039d0:	dff1                	beqz	a5,800039ac <iput+0x26>
    800039d2:	04a49783          	lh	a5,74(s1)
    800039d6:	fbf9                	bnez	a5,800039ac <iput+0x26>
    acquiresleep(&ip->lock);
    800039d8:	01048913          	addi	s2,s1,16
    800039dc:	854a                	mv	a0,s2
    800039de:	00001097          	auipc	ra,0x1
    800039e2:	aa8080e7          	jalr	-1368(ra) # 80004486 <acquiresleep>
    release(&itable.lock);
    800039e6:	0001c517          	auipc	a0,0x1c
    800039ea:	06250513          	addi	a0,a0,98 # 8001fa48 <itable>
    800039ee:	ffffd097          	auipc	ra,0xffffd
    800039f2:	2b0080e7          	jalr	688(ra) # 80000c9e <release>
    itrunc(ip);
    800039f6:	8526                	mv	a0,s1
    800039f8:	00000097          	auipc	ra,0x0
    800039fc:	ee2080e7          	jalr	-286(ra) # 800038da <itrunc>
    ip->type = 0;
    80003a00:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a04:	8526                	mv	a0,s1
    80003a06:	00000097          	auipc	ra,0x0
    80003a0a:	cfc080e7          	jalr	-772(ra) # 80003702 <iupdate>
    ip->valid = 0;
    80003a0e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a12:	854a                	mv	a0,s2
    80003a14:	00001097          	auipc	ra,0x1
    80003a18:	ac8080e7          	jalr	-1336(ra) # 800044dc <releasesleep>
    acquire(&itable.lock);
    80003a1c:	0001c517          	auipc	a0,0x1c
    80003a20:	02c50513          	addi	a0,a0,44 # 8001fa48 <itable>
    80003a24:	ffffd097          	auipc	ra,0xffffd
    80003a28:	1c6080e7          	jalr	454(ra) # 80000bea <acquire>
    80003a2c:	b741                	j	800039ac <iput+0x26>

0000000080003a2e <iunlockput>:
{
    80003a2e:	1101                	addi	sp,sp,-32
    80003a30:	ec06                	sd	ra,24(sp)
    80003a32:	e822                	sd	s0,16(sp)
    80003a34:	e426                	sd	s1,8(sp)
    80003a36:	1000                	addi	s0,sp,32
    80003a38:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a3a:	00000097          	auipc	ra,0x0
    80003a3e:	e54080e7          	jalr	-428(ra) # 8000388e <iunlock>
  iput(ip);
    80003a42:	8526                	mv	a0,s1
    80003a44:	00000097          	auipc	ra,0x0
    80003a48:	f42080e7          	jalr	-190(ra) # 80003986 <iput>
}
    80003a4c:	60e2                	ld	ra,24(sp)
    80003a4e:	6442                	ld	s0,16(sp)
    80003a50:	64a2                	ld	s1,8(sp)
    80003a52:	6105                	addi	sp,sp,32
    80003a54:	8082                	ret

0000000080003a56 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a56:	1141                	addi	sp,sp,-16
    80003a58:	e422                	sd	s0,8(sp)
    80003a5a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a5c:	411c                	lw	a5,0(a0)
    80003a5e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a60:	415c                	lw	a5,4(a0)
    80003a62:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a64:	04451783          	lh	a5,68(a0)
    80003a68:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a6c:	04a51783          	lh	a5,74(a0)
    80003a70:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a74:	04c56783          	lwu	a5,76(a0)
    80003a78:	e99c                	sd	a5,16(a1)
}
    80003a7a:	6422                	ld	s0,8(sp)
    80003a7c:	0141                	addi	sp,sp,16
    80003a7e:	8082                	ret

0000000080003a80 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a80:	457c                	lw	a5,76(a0)
    80003a82:	0ed7e963          	bltu	a5,a3,80003b74 <readi+0xf4>
{
    80003a86:	7159                	addi	sp,sp,-112
    80003a88:	f486                	sd	ra,104(sp)
    80003a8a:	f0a2                	sd	s0,96(sp)
    80003a8c:	eca6                	sd	s1,88(sp)
    80003a8e:	e8ca                	sd	s2,80(sp)
    80003a90:	e4ce                	sd	s3,72(sp)
    80003a92:	e0d2                	sd	s4,64(sp)
    80003a94:	fc56                	sd	s5,56(sp)
    80003a96:	f85a                	sd	s6,48(sp)
    80003a98:	f45e                	sd	s7,40(sp)
    80003a9a:	f062                	sd	s8,32(sp)
    80003a9c:	ec66                	sd	s9,24(sp)
    80003a9e:	e86a                	sd	s10,16(sp)
    80003aa0:	e46e                	sd	s11,8(sp)
    80003aa2:	1880                	addi	s0,sp,112
    80003aa4:	8b2a                	mv	s6,a0
    80003aa6:	8bae                	mv	s7,a1
    80003aa8:	8a32                	mv	s4,a2
    80003aaa:	84b6                	mv	s1,a3
    80003aac:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003aae:	9f35                	addw	a4,a4,a3
    return 0;
    80003ab0:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ab2:	0ad76063          	bltu	a4,a3,80003b52 <readi+0xd2>
  if(off + n > ip->size)
    80003ab6:	00e7f463          	bgeu	a5,a4,80003abe <readi+0x3e>
    n = ip->size - off;
    80003aba:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003abe:	0a0a8963          	beqz	s5,80003b70 <readi+0xf0>
    80003ac2:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ac4:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ac8:	5c7d                	li	s8,-1
    80003aca:	a82d                	j	80003b04 <readi+0x84>
    80003acc:	020d1d93          	slli	s11,s10,0x20
    80003ad0:	020ddd93          	srli	s11,s11,0x20
    80003ad4:	05890613          	addi	a2,s2,88
    80003ad8:	86ee                	mv	a3,s11
    80003ada:	963a                	add	a2,a2,a4
    80003adc:	85d2                	mv	a1,s4
    80003ade:	855e                	mv	a0,s7
    80003ae0:	fffff097          	auipc	ra,0xfffff
    80003ae4:	99a080e7          	jalr	-1638(ra) # 8000247a <either_copyout>
    80003ae8:	05850d63          	beq	a0,s8,80003b42 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003aec:	854a                	mv	a0,s2
    80003aee:	fffff097          	auipc	ra,0xfffff
    80003af2:	5f4080e7          	jalr	1524(ra) # 800030e2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003af6:	013d09bb          	addw	s3,s10,s3
    80003afa:	009d04bb          	addw	s1,s10,s1
    80003afe:	9a6e                	add	s4,s4,s11
    80003b00:	0559f763          	bgeu	s3,s5,80003b4e <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003b04:	00a4d59b          	srliw	a1,s1,0xa
    80003b08:	855a                	mv	a0,s6
    80003b0a:	00000097          	auipc	ra,0x0
    80003b0e:	8a2080e7          	jalr	-1886(ra) # 800033ac <bmap>
    80003b12:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b16:	cd85                	beqz	a1,80003b4e <readi+0xce>
    bp = bread(ip->dev, addr);
    80003b18:	000b2503          	lw	a0,0(s6)
    80003b1c:	fffff097          	auipc	ra,0xfffff
    80003b20:	496080e7          	jalr	1174(ra) # 80002fb2 <bread>
    80003b24:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b26:	3ff4f713          	andi	a4,s1,1023
    80003b2a:	40ec87bb          	subw	a5,s9,a4
    80003b2e:	413a86bb          	subw	a3,s5,s3
    80003b32:	8d3e                	mv	s10,a5
    80003b34:	2781                	sext.w	a5,a5
    80003b36:	0006861b          	sext.w	a2,a3
    80003b3a:	f8f679e3          	bgeu	a2,a5,80003acc <readi+0x4c>
    80003b3e:	8d36                	mv	s10,a3
    80003b40:	b771                	j	80003acc <readi+0x4c>
      brelse(bp);
    80003b42:	854a                	mv	a0,s2
    80003b44:	fffff097          	auipc	ra,0xfffff
    80003b48:	59e080e7          	jalr	1438(ra) # 800030e2 <brelse>
      tot = -1;
    80003b4c:	59fd                	li	s3,-1
  }
  return tot;
    80003b4e:	0009851b          	sext.w	a0,s3
}
    80003b52:	70a6                	ld	ra,104(sp)
    80003b54:	7406                	ld	s0,96(sp)
    80003b56:	64e6                	ld	s1,88(sp)
    80003b58:	6946                	ld	s2,80(sp)
    80003b5a:	69a6                	ld	s3,72(sp)
    80003b5c:	6a06                	ld	s4,64(sp)
    80003b5e:	7ae2                	ld	s5,56(sp)
    80003b60:	7b42                	ld	s6,48(sp)
    80003b62:	7ba2                	ld	s7,40(sp)
    80003b64:	7c02                	ld	s8,32(sp)
    80003b66:	6ce2                	ld	s9,24(sp)
    80003b68:	6d42                	ld	s10,16(sp)
    80003b6a:	6da2                	ld	s11,8(sp)
    80003b6c:	6165                	addi	sp,sp,112
    80003b6e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b70:	89d6                	mv	s3,s5
    80003b72:	bff1                	j	80003b4e <readi+0xce>
    return 0;
    80003b74:	4501                	li	a0,0
}
    80003b76:	8082                	ret

0000000080003b78 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b78:	457c                	lw	a5,76(a0)
    80003b7a:	10d7e863          	bltu	a5,a3,80003c8a <writei+0x112>
{
    80003b7e:	7159                	addi	sp,sp,-112
    80003b80:	f486                	sd	ra,104(sp)
    80003b82:	f0a2                	sd	s0,96(sp)
    80003b84:	eca6                	sd	s1,88(sp)
    80003b86:	e8ca                	sd	s2,80(sp)
    80003b88:	e4ce                	sd	s3,72(sp)
    80003b8a:	e0d2                	sd	s4,64(sp)
    80003b8c:	fc56                	sd	s5,56(sp)
    80003b8e:	f85a                	sd	s6,48(sp)
    80003b90:	f45e                	sd	s7,40(sp)
    80003b92:	f062                	sd	s8,32(sp)
    80003b94:	ec66                	sd	s9,24(sp)
    80003b96:	e86a                	sd	s10,16(sp)
    80003b98:	e46e                	sd	s11,8(sp)
    80003b9a:	1880                	addi	s0,sp,112
    80003b9c:	8aaa                	mv	s5,a0
    80003b9e:	8bae                	mv	s7,a1
    80003ba0:	8a32                	mv	s4,a2
    80003ba2:	8936                	mv	s2,a3
    80003ba4:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ba6:	00e687bb          	addw	a5,a3,a4
    80003baa:	0ed7e263          	bltu	a5,a3,80003c8e <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003bae:	00043737          	lui	a4,0x43
    80003bb2:	0ef76063          	bltu	a4,a5,80003c92 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bb6:	0c0b0863          	beqz	s6,80003c86 <writei+0x10e>
    80003bba:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bbc:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003bc0:	5c7d                	li	s8,-1
    80003bc2:	a091                	j	80003c06 <writei+0x8e>
    80003bc4:	020d1d93          	slli	s11,s10,0x20
    80003bc8:	020ddd93          	srli	s11,s11,0x20
    80003bcc:	05848513          	addi	a0,s1,88
    80003bd0:	86ee                	mv	a3,s11
    80003bd2:	8652                	mv	a2,s4
    80003bd4:	85de                	mv	a1,s7
    80003bd6:	953a                	add	a0,a0,a4
    80003bd8:	fffff097          	auipc	ra,0xfffff
    80003bdc:	8f8080e7          	jalr	-1800(ra) # 800024d0 <either_copyin>
    80003be0:	07850263          	beq	a0,s8,80003c44 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003be4:	8526                	mv	a0,s1
    80003be6:	00000097          	auipc	ra,0x0
    80003bea:	780080e7          	jalr	1920(ra) # 80004366 <log_write>
    brelse(bp);
    80003bee:	8526                	mv	a0,s1
    80003bf0:	fffff097          	auipc	ra,0xfffff
    80003bf4:	4f2080e7          	jalr	1266(ra) # 800030e2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bf8:	013d09bb          	addw	s3,s10,s3
    80003bfc:	012d093b          	addw	s2,s10,s2
    80003c00:	9a6e                	add	s4,s4,s11
    80003c02:	0569f663          	bgeu	s3,s6,80003c4e <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003c06:	00a9559b          	srliw	a1,s2,0xa
    80003c0a:	8556                	mv	a0,s5
    80003c0c:	fffff097          	auipc	ra,0xfffff
    80003c10:	7a0080e7          	jalr	1952(ra) # 800033ac <bmap>
    80003c14:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c18:	c99d                	beqz	a1,80003c4e <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003c1a:	000aa503          	lw	a0,0(s5)
    80003c1e:	fffff097          	auipc	ra,0xfffff
    80003c22:	394080e7          	jalr	916(ra) # 80002fb2 <bread>
    80003c26:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c28:	3ff97713          	andi	a4,s2,1023
    80003c2c:	40ec87bb          	subw	a5,s9,a4
    80003c30:	413b06bb          	subw	a3,s6,s3
    80003c34:	8d3e                	mv	s10,a5
    80003c36:	2781                	sext.w	a5,a5
    80003c38:	0006861b          	sext.w	a2,a3
    80003c3c:	f8f674e3          	bgeu	a2,a5,80003bc4 <writei+0x4c>
    80003c40:	8d36                	mv	s10,a3
    80003c42:	b749                	j	80003bc4 <writei+0x4c>
      brelse(bp);
    80003c44:	8526                	mv	a0,s1
    80003c46:	fffff097          	auipc	ra,0xfffff
    80003c4a:	49c080e7          	jalr	1180(ra) # 800030e2 <brelse>
  }

  if(off > ip->size)
    80003c4e:	04caa783          	lw	a5,76(s5)
    80003c52:	0127f463          	bgeu	a5,s2,80003c5a <writei+0xe2>
    ip->size = off;
    80003c56:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c5a:	8556                	mv	a0,s5
    80003c5c:	00000097          	auipc	ra,0x0
    80003c60:	aa6080e7          	jalr	-1370(ra) # 80003702 <iupdate>

  return tot;
    80003c64:	0009851b          	sext.w	a0,s3
}
    80003c68:	70a6                	ld	ra,104(sp)
    80003c6a:	7406                	ld	s0,96(sp)
    80003c6c:	64e6                	ld	s1,88(sp)
    80003c6e:	6946                	ld	s2,80(sp)
    80003c70:	69a6                	ld	s3,72(sp)
    80003c72:	6a06                	ld	s4,64(sp)
    80003c74:	7ae2                	ld	s5,56(sp)
    80003c76:	7b42                	ld	s6,48(sp)
    80003c78:	7ba2                	ld	s7,40(sp)
    80003c7a:	7c02                	ld	s8,32(sp)
    80003c7c:	6ce2                	ld	s9,24(sp)
    80003c7e:	6d42                	ld	s10,16(sp)
    80003c80:	6da2                	ld	s11,8(sp)
    80003c82:	6165                	addi	sp,sp,112
    80003c84:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c86:	89da                	mv	s3,s6
    80003c88:	bfc9                	j	80003c5a <writei+0xe2>
    return -1;
    80003c8a:	557d                	li	a0,-1
}
    80003c8c:	8082                	ret
    return -1;
    80003c8e:	557d                	li	a0,-1
    80003c90:	bfe1                	j	80003c68 <writei+0xf0>
    return -1;
    80003c92:	557d                	li	a0,-1
    80003c94:	bfd1                	j	80003c68 <writei+0xf0>

0000000080003c96 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c96:	1141                	addi	sp,sp,-16
    80003c98:	e406                	sd	ra,8(sp)
    80003c9a:	e022                	sd	s0,0(sp)
    80003c9c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c9e:	4639                	li	a2,14
    80003ca0:	ffffd097          	auipc	ra,0xffffd
    80003ca4:	11e080e7          	jalr	286(ra) # 80000dbe <strncmp>
}
    80003ca8:	60a2                	ld	ra,8(sp)
    80003caa:	6402                	ld	s0,0(sp)
    80003cac:	0141                	addi	sp,sp,16
    80003cae:	8082                	ret

0000000080003cb0 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003cb0:	7139                	addi	sp,sp,-64
    80003cb2:	fc06                	sd	ra,56(sp)
    80003cb4:	f822                	sd	s0,48(sp)
    80003cb6:	f426                	sd	s1,40(sp)
    80003cb8:	f04a                	sd	s2,32(sp)
    80003cba:	ec4e                	sd	s3,24(sp)
    80003cbc:	e852                	sd	s4,16(sp)
    80003cbe:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003cc0:	04451703          	lh	a4,68(a0)
    80003cc4:	4785                	li	a5,1
    80003cc6:	00f71a63          	bne	a4,a5,80003cda <dirlookup+0x2a>
    80003cca:	892a                	mv	s2,a0
    80003ccc:	89ae                	mv	s3,a1
    80003cce:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cd0:	457c                	lw	a5,76(a0)
    80003cd2:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003cd4:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cd6:	e79d                	bnez	a5,80003d04 <dirlookup+0x54>
    80003cd8:	a8a5                	j	80003d50 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003cda:	00005517          	auipc	a0,0x5
    80003cde:	a1650513          	addi	a0,a0,-1514 # 800086f0 <syscalls+0x1c0>
    80003ce2:	ffffd097          	auipc	ra,0xffffd
    80003ce6:	862080e7          	jalr	-1950(ra) # 80000544 <panic>
      panic("dirlookup read");
    80003cea:	00005517          	auipc	a0,0x5
    80003cee:	a1e50513          	addi	a0,a0,-1506 # 80008708 <syscalls+0x1d8>
    80003cf2:	ffffd097          	auipc	ra,0xffffd
    80003cf6:	852080e7          	jalr	-1966(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cfa:	24c1                	addiw	s1,s1,16
    80003cfc:	04c92783          	lw	a5,76(s2)
    80003d00:	04f4f763          	bgeu	s1,a5,80003d4e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d04:	4741                	li	a4,16
    80003d06:	86a6                	mv	a3,s1
    80003d08:	fc040613          	addi	a2,s0,-64
    80003d0c:	4581                	li	a1,0
    80003d0e:	854a                	mv	a0,s2
    80003d10:	00000097          	auipc	ra,0x0
    80003d14:	d70080e7          	jalr	-656(ra) # 80003a80 <readi>
    80003d18:	47c1                	li	a5,16
    80003d1a:	fcf518e3          	bne	a0,a5,80003cea <dirlookup+0x3a>
    if(de.inum == 0)
    80003d1e:	fc045783          	lhu	a5,-64(s0)
    80003d22:	dfe1                	beqz	a5,80003cfa <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d24:	fc240593          	addi	a1,s0,-62
    80003d28:	854e                	mv	a0,s3
    80003d2a:	00000097          	auipc	ra,0x0
    80003d2e:	f6c080e7          	jalr	-148(ra) # 80003c96 <namecmp>
    80003d32:	f561                	bnez	a0,80003cfa <dirlookup+0x4a>
      if(poff)
    80003d34:	000a0463          	beqz	s4,80003d3c <dirlookup+0x8c>
        *poff = off;
    80003d38:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d3c:	fc045583          	lhu	a1,-64(s0)
    80003d40:	00092503          	lw	a0,0(s2)
    80003d44:	fffff097          	auipc	ra,0xfffff
    80003d48:	750080e7          	jalr	1872(ra) # 80003494 <iget>
    80003d4c:	a011                	j	80003d50 <dirlookup+0xa0>
  return 0;
    80003d4e:	4501                	li	a0,0
}
    80003d50:	70e2                	ld	ra,56(sp)
    80003d52:	7442                	ld	s0,48(sp)
    80003d54:	74a2                	ld	s1,40(sp)
    80003d56:	7902                	ld	s2,32(sp)
    80003d58:	69e2                	ld	s3,24(sp)
    80003d5a:	6a42                	ld	s4,16(sp)
    80003d5c:	6121                	addi	sp,sp,64
    80003d5e:	8082                	ret

0000000080003d60 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d60:	711d                	addi	sp,sp,-96
    80003d62:	ec86                	sd	ra,88(sp)
    80003d64:	e8a2                	sd	s0,80(sp)
    80003d66:	e4a6                	sd	s1,72(sp)
    80003d68:	e0ca                	sd	s2,64(sp)
    80003d6a:	fc4e                	sd	s3,56(sp)
    80003d6c:	f852                	sd	s4,48(sp)
    80003d6e:	f456                	sd	s5,40(sp)
    80003d70:	f05a                	sd	s6,32(sp)
    80003d72:	ec5e                	sd	s7,24(sp)
    80003d74:	e862                	sd	s8,16(sp)
    80003d76:	e466                	sd	s9,8(sp)
    80003d78:	1080                	addi	s0,sp,96
    80003d7a:	84aa                	mv	s1,a0
    80003d7c:	8b2e                	mv	s6,a1
    80003d7e:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d80:	00054703          	lbu	a4,0(a0)
    80003d84:	02f00793          	li	a5,47
    80003d88:	02f70363          	beq	a4,a5,80003dae <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d8c:	ffffe097          	auipc	ra,0xffffe
    80003d90:	c3a080e7          	jalr	-966(ra) # 800019c6 <myproc>
    80003d94:	15053503          	ld	a0,336(a0)
    80003d98:	00000097          	auipc	ra,0x0
    80003d9c:	9f6080e7          	jalr	-1546(ra) # 8000378e <idup>
    80003da0:	89aa                	mv	s3,a0
  while(*path == '/')
    80003da2:	02f00913          	li	s2,47
  len = path - s;
    80003da6:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003da8:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003daa:	4c05                	li	s8,1
    80003dac:	a865                	j	80003e64 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003dae:	4585                	li	a1,1
    80003db0:	4505                	li	a0,1
    80003db2:	fffff097          	auipc	ra,0xfffff
    80003db6:	6e2080e7          	jalr	1762(ra) # 80003494 <iget>
    80003dba:	89aa                	mv	s3,a0
    80003dbc:	b7dd                	j	80003da2 <namex+0x42>
      iunlockput(ip);
    80003dbe:	854e                	mv	a0,s3
    80003dc0:	00000097          	auipc	ra,0x0
    80003dc4:	c6e080e7          	jalr	-914(ra) # 80003a2e <iunlockput>
      return 0;
    80003dc8:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003dca:	854e                	mv	a0,s3
    80003dcc:	60e6                	ld	ra,88(sp)
    80003dce:	6446                	ld	s0,80(sp)
    80003dd0:	64a6                	ld	s1,72(sp)
    80003dd2:	6906                	ld	s2,64(sp)
    80003dd4:	79e2                	ld	s3,56(sp)
    80003dd6:	7a42                	ld	s4,48(sp)
    80003dd8:	7aa2                	ld	s5,40(sp)
    80003dda:	7b02                	ld	s6,32(sp)
    80003ddc:	6be2                	ld	s7,24(sp)
    80003dde:	6c42                	ld	s8,16(sp)
    80003de0:	6ca2                	ld	s9,8(sp)
    80003de2:	6125                	addi	sp,sp,96
    80003de4:	8082                	ret
      iunlock(ip);
    80003de6:	854e                	mv	a0,s3
    80003de8:	00000097          	auipc	ra,0x0
    80003dec:	aa6080e7          	jalr	-1370(ra) # 8000388e <iunlock>
      return ip;
    80003df0:	bfe9                	j	80003dca <namex+0x6a>
      iunlockput(ip);
    80003df2:	854e                	mv	a0,s3
    80003df4:	00000097          	auipc	ra,0x0
    80003df8:	c3a080e7          	jalr	-966(ra) # 80003a2e <iunlockput>
      return 0;
    80003dfc:	89d2                	mv	s3,s4
    80003dfe:	b7f1                	j	80003dca <namex+0x6a>
  len = path - s;
    80003e00:	40b48633          	sub	a2,s1,a1
    80003e04:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003e08:	094cd463          	bge	s9,s4,80003e90 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e0c:	4639                	li	a2,14
    80003e0e:	8556                	mv	a0,s5
    80003e10:	ffffd097          	auipc	ra,0xffffd
    80003e14:	f36080e7          	jalr	-202(ra) # 80000d46 <memmove>
  while(*path == '/')
    80003e18:	0004c783          	lbu	a5,0(s1)
    80003e1c:	01279763          	bne	a5,s2,80003e2a <namex+0xca>
    path++;
    80003e20:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e22:	0004c783          	lbu	a5,0(s1)
    80003e26:	ff278de3          	beq	a5,s2,80003e20 <namex+0xc0>
    ilock(ip);
    80003e2a:	854e                	mv	a0,s3
    80003e2c:	00000097          	auipc	ra,0x0
    80003e30:	9a0080e7          	jalr	-1632(ra) # 800037cc <ilock>
    if(ip->type != T_DIR){
    80003e34:	04499783          	lh	a5,68(s3)
    80003e38:	f98793e3          	bne	a5,s8,80003dbe <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e3c:	000b0563          	beqz	s6,80003e46 <namex+0xe6>
    80003e40:	0004c783          	lbu	a5,0(s1)
    80003e44:	d3cd                	beqz	a5,80003de6 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e46:	865e                	mv	a2,s7
    80003e48:	85d6                	mv	a1,s5
    80003e4a:	854e                	mv	a0,s3
    80003e4c:	00000097          	auipc	ra,0x0
    80003e50:	e64080e7          	jalr	-412(ra) # 80003cb0 <dirlookup>
    80003e54:	8a2a                	mv	s4,a0
    80003e56:	dd51                	beqz	a0,80003df2 <namex+0x92>
    iunlockput(ip);
    80003e58:	854e                	mv	a0,s3
    80003e5a:	00000097          	auipc	ra,0x0
    80003e5e:	bd4080e7          	jalr	-1068(ra) # 80003a2e <iunlockput>
    ip = next;
    80003e62:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e64:	0004c783          	lbu	a5,0(s1)
    80003e68:	05279763          	bne	a5,s2,80003eb6 <namex+0x156>
    path++;
    80003e6c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e6e:	0004c783          	lbu	a5,0(s1)
    80003e72:	ff278de3          	beq	a5,s2,80003e6c <namex+0x10c>
  if(*path == 0)
    80003e76:	c79d                	beqz	a5,80003ea4 <namex+0x144>
    path++;
    80003e78:	85a6                	mv	a1,s1
  len = path - s;
    80003e7a:	8a5e                	mv	s4,s7
    80003e7c:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e7e:	01278963          	beq	a5,s2,80003e90 <namex+0x130>
    80003e82:	dfbd                	beqz	a5,80003e00 <namex+0xa0>
    path++;
    80003e84:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e86:	0004c783          	lbu	a5,0(s1)
    80003e8a:	ff279ce3          	bne	a5,s2,80003e82 <namex+0x122>
    80003e8e:	bf8d                	j	80003e00 <namex+0xa0>
    memmove(name, s, len);
    80003e90:	2601                	sext.w	a2,a2
    80003e92:	8556                	mv	a0,s5
    80003e94:	ffffd097          	auipc	ra,0xffffd
    80003e98:	eb2080e7          	jalr	-334(ra) # 80000d46 <memmove>
    name[len] = 0;
    80003e9c:	9a56                	add	s4,s4,s5
    80003e9e:	000a0023          	sb	zero,0(s4)
    80003ea2:	bf9d                	j	80003e18 <namex+0xb8>
  if(nameiparent){
    80003ea4:	f20b03e3          	beqz	s6,80003dca <namex+0x6a>
    iput(ip);
    80003ea8:	854e                	mv	a0,s3
    80003eaa:	00000097          	auipc	ra,0x0
    80003eae:	adc080e7          	jalr	-1316(ra) # 80003986 <iput>
    return 0;
    80003eb2:	4981                	li	s3,0
    80003eb4:	bf19                	j	80003dca <namex+0x6a>
  if(*path == 0)
    80003eb6:	d7fd                	beqz	a5,80003ea4 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003eb8:	0004c783          	lbu	a5,0(s1)
    80003ebc:	85a6                	mv	a1,s1
    80003ebe:	b7d1                	j	80003e82 <namex+0x122>

0000000080003ec0 <dirlink>:
{
    80003ec0:	7139                	addi	sp,sp,-64
    80003ec2:	fc06                	sd	ra,56(sp)
    80003ec4:	f822                	sd	s0,48(sp)
    80003ec6:	f426                	sd	s1,40(sp)
    80003ec8:	f04a                	sd	s2,32(sp)
    80003eca:	ec4e                	sd	s3,24(sp)
    80003ecc:	e852                	sd	s4,16(sp)
    80003ece:	0080                	addi	s0,sp,64
    80003ed0:	892a                	mv	s2,a0
    80003ed2:	8a2e                	mv	s4,a1
    80003ed4:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ed6:	4601                	li	a2,0
    80003ed8:	00000097          	auipc	ra,0x0
    80003edc:	dd8080e7          	jalr	-552(ra) # 80003cb0 <dirlookup>
    80003ee0:	e93d                	bnez	a0,80003f56 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ee2:	04c92483          	lw	s1,76(s2)
    80003ee6:	c49d                	beqz	s1,80003f14 <dirlink+0x54>
    80003ee8:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eea:	4741                	li	a4,16
    80003eec:	86a6                	mv	a3,s1
    80003eee:	fc040613          	addi	a2,s0,-64
    80003ef2:	4581                	li	a1,0
    80003ef4:	854a                	mv	a0,s2
    80003ef6:	00000097          	auipc	ra,0x0
    80003efa:	b8a080e7          	jalr	-1142(ra) # 80003a80 <readi>
    80003efe:	47c1                	li	a5,16
    80003f00:	06f51163          	bne	a0,a5,80003f62 <dirlink+0xa2>
    if(de.inum == 0)
    80003f04:	fc045783          	lhu	a5,-64(s0)
    80003f08:	c791                	beqz	a5,80003f14 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f0a:	24c1                	addiw	s1,s1,16
    80003f0c:	04c92783          	lw	a5,76(s2)
    80003f10:	fcf4ede3          	bltu	s1,a5,80003eea <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f14:	4639                	li	a2,14
    80003f16:	85d2                	mv	a1,s4
    80003f18:	fc240513          	addi	a0,s0,-62
    80003f1c:	ffffd097          	auipc	ra,0xffffd
    80003f20:	ede080e7          	jalr	-290(ra) # 80000dfa <strncpy>
  de.inum = inum;
    80003f24:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f28:	4741                	li	a4,16
    80003f2a:	86a6                	mv	a3,s1
    80003f2c:	fc040613          	addi	a2,s0,-64
    80003f30:	4581                	li	a1,0
    80003f32:	854a                	mv	a0,s2
    80003f34:	00000097          	auipc	ra,0x0
    80003f38:	c44080e7          	jalr	-956(ra) # 80003b78 <writei>
    80003f3c:	1541                	addi	a0,a0,-16
    80003f3e:	00a03533          	snez	a0,a0
    80003f42:	40a00533          	neg	a0,a0
}
    80003f46:	70e2                	ld	ra,56(sp)
    80003f48:	7442                	ld	s0,48(sp)
    80003f4a:	74a2                	ld	s1,40(sp)
    80003f4c:	7902                	ld	s2,32(sp)
    80003f4e:	69e2                	ld	s3,24(sp)
    80003f50:	6a42                	ld	s4,16(sp)
    80003f52:	6121                	addi	sp,sp,64
    80003f54:	8082                	ret
    iput(ip);
    80003f56:	00000097          	auipc	ra,0x0
    80003f5a:	a30080e7          	jalr	-1488(ra) # 80003986 <iput>
    return -1;
    80003f5e:	557d                	li	a0,-1
    80003f60:	b7dd                	j	80003f46 <dirlink+0x86>
      panic("dirlink read");
    80003f62:	00004517          	auipc	a0,0x4
    80003f66:	7b650513          	addi	a0,a0,1974 # 80008718 <syscalls+0x1e8>
    80003f6a:	ffffc097          	auipc	ra,0xffffc
    80003f6e:	5da080e7          	jalr	1498(ra) # 80000544 <panic>

0000000080003f72 <namei>:

struct inode*
namei(char *path)
{
    80003f72:	1101                	addi	sp,sp,-32
    80003f74:	ec06                	sd	ra,24(sp)
    80003f76:	e822                	sd	s0,16(sp)
    80003f78:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f7a:	fe040613          	addi	a2,s0,-32
    80003f7e:	4581                	li	a1,0
    80003f80:	00000097          	auipc	ra,0x0
    80003f84:	de0080e7          	jalr	-544(ra) # 80003d60 <namex>
}
    80003f88:	60e2                	ld	ra,24(sp)
    80003f8a:	6442                	ld	s0,16(sp)
    80003f8c:	6105                	addi	sp,sp,32
    80003f8e:	8082                	ret

0000000080003f90 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f90:	1141                	addi	sp,sp,-16
    80003f92:	e406                	sd	ra,8(sp)
    80003f94:	e022                	sd	s0,0(sp)
    80003f96:	0800                	addi	s0,sp,16
    80003f98:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f9a:	4585                	li	a1,1
    80003f9c:	00000097          	auipc	ra,0x0
    80003fa0:	dc4080e7          	jalr	-572(ra) # 80003d60 <namex>
}
    80003fa4:	60a2                	ld	ra,8(sp)
    80003fa6:	6402                	ld	s0,0(sp)
    80003fa8:	0141                	addi	sp,sp,16
    80003faa:	8082                	ret

0000000080003fac <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003fac:	1101                	addi	sp,sp,-32
    80003fae:	ec06                	sd	ra,24(sp)
    80003fb0:	e822                	sd	s0,16(sp)
    80003fb2:	e426                	sd	s1,8(sp)
    80003fb4:	e04a                	sd	s2,0(sp)
    80003fb6:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003fb8:	0001d917          	auipc	s2,0x1d
    80003fbc:	53890913          	addi	s2,s2,1336 # 800214f0 <log>
    80003fc0:	01892583          	lw	a1,24(s2)
    80003fc4:	02892503          	lw	a0,40(s2)
    80003fc8:	fffff097          	auipc	ra,0xfffff
    80003fcc:	fea080e7          	jalr	-22(ra) # 80002fb2 <bread>
    80003fd0:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fd2:	02c92683          	lw	a3,44(s2)
    80003fd6:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fd8:	02d05763          	blez	a3,80004006 <write_head+0x5a>
    80003fdc:	0001d797          	auipc	a5,0x1d
    80003fe0:	54478793          	addi	a5,a5,1348 # 80021520 <log+0x30>
    80003fe4:	05c50713          	addi	a4,a0,92
    80003fe8:	36fd                	addiw	a3,a3,-1
    80003fea:	1682                	slli	a3,a3,0x20
    80003fec:	9281                	srli	a3,a3,0x20
    80003fee:	068a                	slli	a3,a3,0x2
    80003ff0:	0001d617          	auipc	a2,0x1d
    80003ff4:	53460613          	addi	a2,a2,1332 # 80021524 <log+0x34>
    80003ff8:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003ffa:	4390                	lw	a2,0(a5)
    80003ffc:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003ffe:	0791                	addi	a5,a5,4
    80004000:	0711                	addi	a4,a4,4
    80004002:	fed79ce3          	bne	a5,a3,80003ffa <write_head+0x4e>
  }
  bwrite(buf);
    80004006:	8526                	mv	a0,s1
    80004008:	fffff097          	auipc	ra,0xfffff
    8000400c:	09c080e7          	jalr	156(ra) # 800030a4 <bwrite>
  brelse(buf);
    80004010:	8526                	mv	a0,s1
    80004012:	fffff097          	auipc	ra,0xfffff
    80004016:	0d0080e7          	jalr	208(ra) # 800030e2 <brelse>
}
    8000401a:	60e2                	ld	ra,24(sp)
    8000401c:	6442                	ld	s0,16(sp)
    8000401e:	64a2                	ld	s1,8(sp)
    80004020:	6902                	ld	s2,0(sp)
    80004022:	6105                	addi	sp,sp,32
    80004024:	8082                	ret

0000000080004026 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004026:	0001d797          	auipc	a5,0x1d
    8000402a:	4f67a783          	lw	a5,1270(a5) # 8002151c <log+0x2c>
    8000402e:	0af05d63          	blez	a5,800040e8 <install_trans+0xc2>
{
    80004032:	7139                	addi	sp,sp,-64
    80004034:	fc06                	sd	ra,56(sp)
    80004036:	f822                	sd	s0,48(sp)
    80004038:	f426                	sd	s1,40(sp)
    8000403a:	f04a                	sd	s2,32(sp)
    8000403c:	ec4e                	sd	s3,24(sp)
    8000403e:	e852                	sd	s4,16(sp)
    80004040:	e456                	sd	s5,8(sp)
    80004042:	e05a                	sd	s6,0(sp)
    80004044:	0080                	addi	s0,sp,64
    80004046:	8b2a                	mv	s6,a0
    80004048:	0001da97          	auipc	s5,0x1d
    8000404c:	4d8a8a93          	addi	s5,s5,1240 # 80021520 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004050:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004052:	0001d997          	auipc	s3,0x1d
    80004056:	49e98993          	addi	s3,s3,1182 # 800214f0 <log>
    8000405a:	a035                	j	80004086 <install_trans+0x60>
      bunpin(dbuf);
    8000405c:	8526                	mv	a0,s1
    8000405e:	fffff097          	auipc	ra,0xfffff
    80004062:	15e080e7          	jalr	350(ra) # 800031bc <bunpin>
    brelse(lbuf);
    80004066:	854a                	mv	a0,s2
    80004068:	fffff097          	auipc	ra,0xfffff
    8000406c:	07a080e7          	jalr	122(ra) # 800030e2 <brelse>
    brelse(dbuf);
    80004070:	8526                	mv	a0,s1
    80004072:	fffff097          	auipc	ra,0xfffff
    80004076:	070080e7          	jalr	112(ra) # 800030e2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000407a:	2a05                	addiw	s4,s4,1
    8000407c:	0a91                	addi	s5,s5,4
    8000407e:	02c9a783          	lw	a5,44(s3)
    80004082:	04fa5963          	bge	s4,a5,800040d4 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004086:	0189a583          	lw	a1,24(s3)
    8000408a:	014585bb          	addw	a1,a1,s4
    8000408e:	2585                	addiw	a1,a1,1
    80004090:	0289a503          	lw	a0,40(s3)
    80004094:	fffff097          	auipc	ra,0xfffff
    80004098:	f1e080e7          	jalr	-226(ra) # 80002fb2 <bread>
    8000409c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000409e:	000aa583          	lw	a1,0(s5)
    800040a2:	0289a503          	lw	a0,40(s3)
    800040a6:	fffff097          	auipc	ra,0xfffff
    800040aa:	f0c080e7          	jalr	-244(ra) # 80002fb2 <bread>
    800040ae:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040b0:	40000613          	li	a2,1024
    800040b4:	05890593          	addi	a1,s2,88
    800040b8:	05850513          	addi	a0,a0,88
    800040bc:	ffffd097          	auipc	ra,0xffffd
    800040c0:	c8a080e7          	jalr	-886(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    800040c4:	8526                	mv	a0,s1
    800040c6:	fffff097          	auipc	ra,0xfffff
    800040ca:	fde080e7          	jalr	-34(ra) # 800030a4 <bwrite>
    if(recovering == 0)
    800040ce:	f80b1ce3          	bnez	s6,80004066 <install_trans+0x40>
    800040d2:	b769                	j	8000405c <install_trans+0x36>
}
    800040d4:	70e2                	ld	ra,56(sp)
    800040d6:	7442                	ld	s0,48(sp)
    800040d8:	74a2                	ld	s1,40(sp)
    800040da:	7902                	ld	s2,32(sp)
    800040dc:	69e2                	ld	s3,24(sp)
    800040de:	6a42                	ld	s4,16(sp)
    800040e0:	6aa2                	ld	s5,8(sp)
    800040e2:	6b02                	ld	s6,0(sp)
    800040e4:	6121                	addi	sp,sp,64
    800040e6:	8082                	ret
    800040e8:	8082                	ret

00000000800040ea <initlog>:
{
    800040ea:	7179                	addi	sp,sp,-48
    800040ec:	f406                	sd	ra,40(sp)
    800040ee:	f022                	sd	s0,32(sp)
    800040f0:	ec26                	sd	s1,24(sp)
    800040f2:	e84a                	sd	s2,16(sp)
    800040f4:	e44e                	sd	s3,8(sp)
    800040f6:	1800                	addi	s0,sp,48
    800040f8:	892a                	mv	s2,a0
    800040fa:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040fc:	0001d497          	auipc	s1,0x1d
    80004100:	3f448493          	addi	s1,s1,1012 # 800214f0 <log>
    80004104:	00004597          	auipc	a1,0x4
    80004108:	62458593          	addi	a1,a1,1572 # 80008728 <syscalls+0x1f8>
    8000410c:	8526                	mv	a0,s1
    8000410e:	ffffd097          	auipc	ra,0xffffd
    80004112:	a4c080e7          	jalr	-1460(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    80004116:	0149a583          	lw	a1,20(s3)
    8000411a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000411c:	0109a783          	lw	a5,16(s3)
    80004120:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004122:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004126:	854a                	mv	a0,s2
    80004128:	fffff097          	auipc	ra,0xfffff
    8000412c:	e8a080e7          	jalr	-374(ra) # 80002fb2 <bread>
  log.lh.n = lh->n;
    80004130:	4d3c                	lw	a5,88(a0)
    80004132:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004134:	02f05563          	blez	a5,8000415e <initlog+0x74>
    80004138:	05c50713          	addi	a4,a0,92
    8000413c:	0001d697          	auipc	a3,0x1d
    80004140:	3e468693          	addi	a3,a3,996 # 80021520 <log+0x30>
    80004144:	37fd                	addiw	a5,a5,-1
    80004146:	1782                	slli	a5,a5,0x20
    80004148:	9381                	srli	a5,a5,0x20
    8000414a:	078a                	slli	a5,a5,0x2
    8000414c:	06050613          	addi	a2,a0,96
    80004150:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004152:	4310                	lw	a2,0(a4)
    80004154:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004156:	0711                	addi	a4,a4,4
    80004158:	0691                	addi	a3,a3,4
    8000415a:	fef71ce3          	bne	a4,a5,80004152 <initlog+0x68>
  brelse(buf);
    8000415e:	fffff097          	auipc	ra,0xfffff
    80004162:	f84080e7          	jalr	-124(ra) # 800030e2 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004166:	4505                	li	a0,1
    80004168:	00000097          	auipc	ra,0x0
    8000416c:	ebe080e7          	jalr	-322(ra) # 80004026 <install_trans>
  log.lh.n = 0;
    80004170:	0001d797          	auipc	a5,0x1d
    80004174:	3a07a623          	sw	zero,940(a5) # 8002151c <log+0x2c>
  write_head(); // clear the log
    80004178:	00000097          	auipc	ra,0x0
    8000417c:	e34080e7          	jalr	-460(ra) # 80003fac <write_head>
}
    80004180:	70a2                	ld	ra,40(sp)
    80004182:	7402                	ld	s0,32(sp)
    80004184:	64e2                	ld	s1,24(sp)
    80004186:	6942                	ld	s2,16(sp)
    80004188:	69a2                	ld	s3,8(sp)
    8000418a:	6145                	addi	sp,sp,48
    8000418c:	8082                	ret

000000008000418e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000418e:	1101                	addi	sp,sp,-32
    80004190:	ec06                	sd	ra,24(sp)
    80004192:	e822                	sd	s0,16(sp)
    80004194:	e426                	sd	s1,8(sp)
    80004196:	e04a                	sd	s2,0(sp)
    80004198:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000419a:	0001d517          	auipc	a0,0x1d
    8000419e:	35650513          	addi	a0,a0,854 # 800214f0 <log>
    800041a2:	ffffd097          	auipc	ra,0xffffd
    800041a6:	a48080e7          	jalr	-1464(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    800041aa:	0001d497          	auipc	s1,0x1d
    800041ae:	34648493          	addi	s1,s1,838 # 800214f0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041b2:	4979                	li	s2,30
    800041b4:	a039                	j	800041c2 <begin_op+0x34>
      sleep(&log, &log.lock);
    800041b6:	85a6                	mv	a1,s1
    800041b8:	8526                	mv	a0,s1
    800041ba:	ffffe097          	auipc	ra,0xffffe
    800041be:	eb8080e7          	jalr	-328(ra) # 80002072 <sleep>
    if(log.committing){
    800041c2:	50dc                	lw	a5,36(s1)
    800041c4:	fbed                	bnez	a5,800041b6 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041c6:	509c                	lw	a5,32(s1)
    800041c8:	0017871b          	addiw	a4,a5,1
    800041cc:	0007069b          	sext.w	a3,a4
    800041d0:	0027179b          	slliw	a5,a4,0x2
    800041d4:	9fb9                	addw	a5,a5,a4
    800041d6:	0017979b          	slliw	a5,a5,0x1
    800041da:	54d8                	lw	a4,44(s1)
    800041dc:	9fb9                	addw	a5,a5,a4
    800041de:	00f95963          	bge	s2,a5,800041f0 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041e2:	85a6                	mv	a1,s1
    800041e4:	8526                	mv	a0,s1
    800041e6:	ffffe097          	auipc	ra,0xffffe
    800041ea:	e8c080e7          	jalr	-372(ra) # 80002072 <sleep>
    800041ee:	bfd1                	j	800041c2 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041f0:	0001d517          	auipc	a0,0x1d
    800041f4:	30050513          	addi	a0,a0,768 # 800214f0 <log>
    800041f8:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041fa:	ffffd097          	auipc	ra,0xffffd
    800041fe:	aa4080e7          	jalr	-1372(ra) # 80000c9e <release>
      break;
    }
  }
}
    80004202:	60e2                	ld	ra,24(sp)
    80004204:	6442                	ld	s0,16(sp)
    80004206:	64a2                	ld	s1,8(sp)
    80004208:	6902                	ld	s2,0(sp)
    8000420a:	6105                	addi	sp,sp,32
    8000420c:	8082                	ret

000000008000420e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000420e:	7139                	addi	sp,sp,-64
    80004210:	fc06                	sd	ra,56(sp)
    80004212:	f822                	sd	s0,48(sp)
    80004214:	f426                	sd	s1,40(sp)
    80004216:	f04a                	sd	s2,32(sp)
    80004218:	ec4e                	sd	s3,24(sp)
    8000421a:	e852                	sd	s4,16(sp)
    8000421c:	e456                	sd	s5,8(sp)
    8000421e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004220:	0001d497          	auipc	s1,0x1d
    80004224:	2d048493          	addi	s1,s1,720 # 800214f0 <log>
    80004228:	8526                	mv	a0,s1
    8000422a:	ffffd097          	auipc	ra,0xffffd
    8000422e:	9c0080e7          	jalr	-1600(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    80004232:	509c                	lw	a5,32(s1)
    80004234:	37fd                	addiw	a5,a5,-1
    80004236:	0007891b          	sext.w	s2,a5
    8000423a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000423c:	50dc                	lw	a5,36(s1)
    8000423e:	efb9                	bnez	a5,8000429c <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004240:	06091663          	bnez	s2,800042ac <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004244:	0001d497          	auipc	s1,0x1d
    80004248:	2ac48493          	addi	s1,s1,684 # 800214f0 <log>
    8000424c:	4785                	li	a5,1
    8000424e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004250:	8526                	mv	a0,s1
    80004252:	ffffd097          	auipc	ra,0xffffd
    80004256:	a4c080e7          	jalr	-1460(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000425a:	54dc                	lw	a5,44(s1)
    8000425c:	06f04763          	bgtz	a5,800042ca <end_op+0xbc>
    acquire(&log.lock);
    80004260:	0001d497          	auipc	s1,0x1d
    80004264:	29048493          	addi	s1,s1,656 # 800214f0 <log>
    80004268:	8526                	mv	a0,s1
    8000426a:	ffffd097          	auipc	ra,0xffffd
    8000426e:	980080e7          	jalr	-1664(ra) # 80000bea <acquire>
    log.committing = 0;
    80004272:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004276:	8526                	mv	a0,s1
    80004278:	ffffe097          	auipc	ra,0xffffe
    8000427c:	e5e080e7          	jalr	-418(ra) # 800020d6 <wakeup>
    release(&log.lock);
    80004280:	8526                	mv	a0,s1
    80004282:	ffffd097          	auipc	ra,0xffffd
    80004286:	a1c080e7          	jalr	-1508(ra) # 80000c9e <release>
}
    8000428a:	70e2                	ld	ra,56(sp)
    8000428c:	7442                	ld	s0,48(sp)
    8000428e:	74a2                	ld	s1,40(sp)
    80004290:	7902                	ld	s2,32(sp)
    80004292:	69e2                	ld	s3,24(sp)
    80004294:	6a42                	ld	s4,16(sp)
    80004296:	6aa2                	ld	s5,8(sp)
    80004298:	6121                	addi	sp,sp,64
    8000429a:	8082                	ret
    panic("log.committing");
    8000429c:	00004517          	auipc	a0,0x4
    800042a0:	49450513          	addi	a0,a0,1172 # 80008730 <syscalls+0x200>
    800042a4:	ffffc097          	auipc	ra,0xffffc
    800042a8:	2a0080e7          	jalr	672(ra) # 80000544 <panic>
    wakeup(&log);
    800042ac:	0001d497          	auipc	s1,0x1d
    800042b0:	24448493          	addi	s1,s1,580 # 800214f0 <log>
    800042b4:	8526                	mv	a0,s1
    800042b6:	ffffe097          	auipc	ra,0xffffe
    800042ba:	e20080e7          	jalr	-480(ra) # 800020d6 <wakeup>
  release(&log.lock);
    800042be:	8526                	mv	a0,s1
    800042c0:	ffffd097          	auipc	ra,0xffffd
    800042c4:	9de080e7          	jalr	-1570(ra) # 80000c9e <release>
  if(do_commit){
    800042c8:	b7c9                	j	8000428a <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042ca:	0001da97          	auipc	s5,0x1d
    800042ce:	256a8a93          	addi	s5,s5,598 # 80021520 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042d2:	0001da17          	auipc	s4,0x1d
    800042d6:	21ea0a13          	addi	s4,s4,542 # 800214f0 <log>
    800042da:	018a2583          	lw	a1,24(s4)
    800042de:	012585bb          	addw	a1,a1,s2
    800042e2:	2585                	addiw	a1,a1,1
    800042e4:	028a2503          	lw	a0,40(s4)
    800042e8:	fffff097          	auipc	ra,0xfffff
    800042ec:	cca080e7          	jalr	-822(ra) # 80002fb2 <bread>
    800042f0:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042f2:	000aa583          	lw	a1,0(s5)
    800042f6:	028a2503          	lw	a0,40(s4)
    800042fa:	fffff097          	auipc	ra,0xfffff
    800042fe:	cb8080e7          	jalr	-840(ra) # 80002fb2 <bread>
    80004302:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004304:	40000613          	li	a2,1024
    80004308:	05850593          	addi	a1,a0,88
    8000430c:	05848513          	addi	a0,s1,88
    80004310:	ffffd097          	auipc	ra,0xffffd
    80004314:	a36080e7          	jalr	-1482(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    80004318:	8526                	mv	a0,s1
    8000431a:	fffff097          	auipc	ra,0xfffff
    8000431e:	d8a080e7          	jalr	-630(ra) # 800030a4 <bwrite>
    brelse(from);
    80004322:	854e                	mv	a0,s3
    80004324:	fffff097          	auipc	ra,0xfffff
    80004328:	dbe080e7          	jalr	-578(ra) # 800030e2 <brelse>
    brelse(to);
    8000432c:	8526                	mv	a0,s1
    8000432e:	fffff097          	auipc	ra,0xfffff
    80004332:	db4080e7          	jalr	-588(ra) # 800030e2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004336:	2905                	addiw	s2,s2,1
    80004338:	0a91                	addi	s5,s5,4
    8000433a:	02ca2783          	lw	a5,44(s4)
    8000433e:	f8f94ee3          	blt	s2,a5,800042da <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004342:	00000097          	auipc	ra,0x0
    80004346:	c6a080e7          	jalr	-918(ra) # 80003fac <write_head>
    install_trans(0); // Now install writes to home locations
    8000434a:	4501                	li	a0,0
    8000434c:	00000097          	auipc	ra,0x0
    80004350:	cda080e7          	jalr	-806(ra) # 80004026 <install_trans>
    log.lh.n = 0;
    80004354:	0001d797          	auipc	a5,0x1d
    80004358:	1c07a423          	sw	zero,456(a5) # 8002151c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000435c:	00000097          	auipc	ra,0x0
    80004360:	c50080e7          	jalr	-944(ra) # 80003fac <write_head>
    80004364:	bdf5                	j	80004260 <end_op+0x52>

0000000080004366 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004366:	1101                	addi	sp,sp,-32
    80004368:	ec06                	sd	ra,24(sp)
    8000436a:	e822                	sd	s0,16(sp)
    8000436c:	e426                	sd	s1,8(sp)
    8000436e:	e04a                	sd	s2,0(sp)
    80004370:	1000                	addi	s0,sp,32
    80004372:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004374:	0001d917          	auipc	s2,0x1d
    80004378:	17c90913          	addi	s2,s2,380 # 800214f0 <log>
    8000437c:	854a                	mv	a0,s2
    8000437e:	ffffd097          	auipc	ra,0xffffd
    80004382:	86c080e7          	jalr	-1940(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004386:	02c92603          	lw	a2,44(s2)
    8000438a:	47f5                	li	a5,29
    8000438c:	06c7c563          	blt	a5,a2,800043f6 <log_write+0x90>
    80004390:	0001d797          	auipc	a5,0x1d
    80004394:	17c7a783          	lw	a5,380(a5) # 8002150c <log+0x1c>
    80004398:	37fd                	addiw	a5,a5,-1
    8000439a:	04f65e63          	bge	a2,a5,800043f6 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000439e:	0001d797          	auipc	a5,0x1d
    800043a2:	1727a783          	lw	a5,370(a5) # 80021510 <log+0x20>
    800043a6:	06f05063          	blez	a5,80004406 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800043aa:	4781                	li	a5,0
    800043ac:	06c05563          	blez	a2,80004416 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043b0:	44cc                	lw	a1,12(s1)
    800043b2:	0001d717          	auipc	a4,0x1d
    800043b6:	16e70713          	addi	a4,a4,366 # 80021520 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043ba:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043bc:	4314                	lw	a3,0(a4)
    800043be:	04b68c63          	beq	a3,a1,80004416 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800043c2:	2785                	addiw	a5,a5,1
    800043c4:	0711                	addi	a4,a4,4
    800043c6:	fef61be3          	bne	a2,a5,800043bc <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043ca:	0621                	addi	a2,a2,8
    800043cc:	060a                	slli	a2,a2,0x2
    800043ce:	0001d797          	auipc	a5,0x1d
    800043d2:	12278793          	addi	a5,a5,290 # 800214f0 <log>
    800043d6:	963e                	add	a2,a2,a5
    800043d8:	44dc                	lw	a5,12(s1)
    800043da:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043dc:	8526                	mv	a0,s1
    800043de:	fffff097          	auipc	ra,0xfffff
    800043e2:	da2080e7          	jalr	-606(ra) # 80003180 <bpin>
    log.lh.n++;
    800043e6:	0001d717          	auipc	a4,0x1d
    800043ea:	10a70713          	addi	a4,a4,266 # 800214f0 <log>
    800043ee:	575c                	lw	a5,44(a4)
    800043f0:	2785                	addiw	a5,a5,1
    800043f2:	d75c                	sw	a5,44(a4)
    800043f4:	a835                	j	80004430 <log_write+0xca>
    panic("too big a transaction");
    800043f6:	00004517          	auipc	a0,0x4
    800043fa:	34a50513          	addi	a0,a0,842 # 80008740 <syscalls+0x210>
    800043fe:	ffffc097          	auipc	ra,0xffffc
    80004402:	146080e7          	jalr	326(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    80004406:	00004517          	auipc	a0,0x4
    8000440a:	35250513          	addi	a0,a0,850 # 80008758 <syscalls+0x228>
    8000440e:	ffffc097          	auipc	ra,0xffffc
    80004412:	136080e7          	jalr	310(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    80004416:	00878713          	addi	a4,a5,8
    8000441a:	00271693          	slli	a3,a4,0x2
    8000441e:	0001d717          	auipc	a4,0x1d
    80004422:	0d270713          	addi	a4,a4,210 # 800214f0 <log>
    80004426:	9736                	add	a4,a4,a3
    80004428:	44d4                	lw	a3,12(s1)
    8000442a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000442c:	faf608e3          	beq	a2,a5,800043dc <log_write+0x76>
  }
  release(&log.lock);
    80004430:	0001d517          	auipc	a0,0x1d
    80004434:	0c050513          	addi	a0,a0,192 # 800214f0 <log>
    80004438:	ffffd097          	auipc	ra,0xffffd
    8000443c:	866080e7          	jalr	-1946(ra) # 80000c9e <release>
}
    80004440:	60e2                	ld	ra,24(sp)
    80004442:	6442                	ld	s0,16(sp)
    80004444:	64a2                	ld	s1,8(sp)
    80004446:	6902                	ld	s2,0(sp)
    80004448:	6105                	addi	sp,sp,32
    8000444a:	8082                	ret

000000008000444c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000444c:	1101                	addi	sp,sp,-32
    8000444e:	ec06                	sd	ra,24(sp)
    80004450:	e822                	sd	s0,16(sp)
    80004452:	e426                	sd	s1,8(sp)
    80004454:	e04a                	sd	s2,0(sp)
    80004456:	1000                	addi	s0,sp,32
    80004458:	84aa                	mv	s1,a0
    8000445a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000445c:	00004597          	auipc	a1,0x4
    80004460:	31c58593          	addi	a1,a1,796 # 80008778 <syscalls+0x248>
    80004464:	0521                	addi	a0,a0,8
    80004466:	ffffc097          	auipc	ra,0xffffc
    8000446a:	6f4080e7          	jalr	1780(ra) # 80000b5a <initlock>
  lk->name = name;
    8000446e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004472:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004476:	0204a423          	sw	zero,40(s1)
}
    8000447a:	60e2                	ld	ra,24(sp)
    8000447c:	6442                	ld	s0,16(sp)
    8000447e:	64a2                	ld	s1,8(sp)
    80004480:	6902                	ld	s2,0(sp)
    80004482:	6105                	addi	sp,sp,32
    80004484:	8082                	ret

0000000080004486 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004486:	1101                	addi	sp,sp,-32
    80004488:	ec06                	sd	ra,24(sp)
    8000448a:	e822                	sd	s0,16(sp)
    8000448c:	e426                	sd	s1,8(sp)
    8000448e:	e04a                	sd	s2,0(sp)
    80004490:	1000                	addi	s0,sp,32
    80004492:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004494:	00850913          	addi	s2,a0,8
    80004498:	854a                	mv	a0,s2
    8000449a:	ffffc097          	auipc	ra,0xffffc
    8000449e:	750080e7          	jalr	1872(ra) # 80000bea <acquire>
  while (lk->locked) {
    800044a2:	409c                	lw	a5,0(s1)
    800044a4:	cb89                	beqz	a5,800044b6 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800044a6:	85ca                	mv	a1,s2
    800044a8:	8526                	mv	a0,s1
    800044aa:	ffffe097          	auipc	ra,0xffffe
    800044ae:	bc8080e7          	jalr	-1080(ra) # 80002072 <sleep>
  while (lk->locked) {
    800044b2:	409c                	lw	a5,0(s1)
    800044b4:	fbed                	bnez	a5,800044a6 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044b6:	4785                	li	a5,1
    800044b8:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044ba:	ffffd097          	auipc	ra,0xffffd
    800044be:	50c080e7          	jalr	1292(ra) # 800019c6 <myproc>
    800044c2:	591c                	lw	a5,48(a0)
    800044c4:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044c6:	854a                	mv	a0,s2
    800044c8:	ffffc097          	auipc	ra,0xffffc
    800044cc:	7d6080e7          	jalr	2006(ra) # 80000c9e <release>
}
    800044d0:	60e2                	ld	ra,24(sp)
    800044d2:	6442                	ld	s0,16(sp)
    800044d4:	64a2                	ld	s1,8(sp)
    800044d6:	6902                	ld	s2,0(sp)
    800044d8:	6105                	addi	sp,sp,32
    800044da:	8082                	ret

00000000800044dc <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044dc:	1101                	addi	sp,sp,-32
    800044de:	ec06                	sd	ra,24(sp)
    800044e0:	e822                	sd	s0,16(sp)
    800044e2:	e426                	sd	s1,8(sp)
    800044e4:	e04a                	sd	s2,0(sp)
    800044e6:	1000                	addi	s0,sp,32
    800044e8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044ea:	00850913          	addi	s2,a0,8
    800044ee:	854a                	mv	a0,s2
    800044f0:	ffffc097          	auipc	ra,0xffffc
    800044f4:	6fa080e7          	jalr	1786(ra) # 80000bea <acquire>
  lk->locked = 0;
    800044f8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044fc:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004500:	8526                	mv	a0,s1
    80004502:	ffffe097          	auipc	ra,0xffffe
    80004506:	bd4080e7          	jalr	-1068(ra) # 800020d6 <wakeup>
  release(&lk->lk);
    8000450a:	854a                	mv	a0,s2
    8000450c:	ffffc097          	auipc	ra,0xffffc
    80004510:	792080e7          	jalr	1938(ra) # 80000c9e <release>
}
    80004514:	60e2                	ld	ra,24(sp)
    80004516:	6442                	ld	s0,16(sp)
    80004518:	64a2                	ld	s1,8(sp)
    8000451a:	6902                	ld	s2,0(sp)
    8000451c:	6105                	addi	sp,sp,32
    8000451e:	8082                	ret

0000000080004520 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004520:	7179                	addi	sp,sp,-48
    80004522:	f406                	sd	ra,40(sp)
    80004524:	f022                	sd	s0,32(sp)
    80004526:	ec26                	sd	s1,24(sp)
    80004528:	e84a                	sd	s2,16(sp)
    8000452a:	e44e                	sd	s3,8(sp)
    8000452c:	1800                	addi	s0,sp,48
    8000452e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004530:	00850913          	addi	s2,a0,8
    80004534:	854a                	mv	a0,s2
    80004536:	ffffc097          	auipc	ra,0xffffc
    8000453a:	6b4080e7          	jalr	1716(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000453e:	409c                	lw	a5,0(s1)
    80004540:	ef99                	bnez	a5,8000455e <holdingsleep+0x3e>
    80004542:	4481                	li	s1,0
  release(&lk->lk);
    80004544:	854a                	mv	a0,s2
    80004546:	ffffc097          	auipc	ra,0xffffc
    8000454a:	758080e7          	jalr	1880(ra) # 80000c9e <release>
  return r;
}
    8000454e:	8526                	mv	a0,s1
    80004550:	70a2                	ld	ra,40(sp)
    80004552:	7402                	ld	s0,32(sp)
    80004554:	64e2                	ld	s1,24(sp)
    80004556:	6942                	ld	s2,16(sp)
    80004558:	69a2                	ld	s3,8(sp)
    8000455a:	6145                	addi	sp,sp,48
    8000455c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000455e:	0284a983          	lw	s3,40(s1)
    80004562:	ffffd097          	auipc	ra,0xffffd
    80004566:	464080e7          	jalr	1124(ra) # 800019c6 <myproc>
    8000456a:	5904                	lw	s1,48(a0)
    8000456c:	413484b3          	sub	s1,s1,s3
    80004570:	0014b493          	seqz	s1,s1
    80004574:	bfc1                	j	80004544 <holdingsleep+0x24>

0000000080004576 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004576:	1141                	addi	sp,sp,-16
    80004578:	e406                	sd	ra,8(sp)
    8000457a:	e022                	sd	s0,0(sp)
    8000457c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000457e:	00004597          	auipc	a1,0x4
    80004582:	20a58593          	addi	a1,a1,522 # 80008788 <syscalls+0x258>
    80004586:	0001d517          	auipc	a0,0x1d
    8000458a:	0b250513          	addi	a0,a0,178 # 80021638 <ftable>
    8000458e:	ffffc097          	auipc	ra,0xffffc
    80004592:	5cc080e7          	jalr	1484(ra) # 80000b5a <initlock>
}
    80004596:	60a2                	ld	ra,8(sp)
    80004598:	6402                	ld	s0,0(sp)
    8000459a:	0141                	addi	sp,sp,16
    8000459c:	8082                	ret

000000008000459e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000459e:	1101                	addi	sp,sp,-32
    800045a0:	ec06                	sd	ra,24(sp)
    800045a2:	e822                	sd	s0,16(sp)
    800045a4:	e426                	sd	s1,8(sp)
    800045a6:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800045a8:	0001d517          	auipc	a0,0x1d
    800045ac:	09050513          	addi	a0,a0,144 # 80021638 <ftable>
    800045b0:	ffffc097          	auipc	ra,0xffffc
    800045b4:	63a080e7          	jalr	1594(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045b8:	0001d497          	auipc	s1,0x1d
    800045bc:	09848493          	addi	s1,s1,152 # 80021650 <ftable+0x18>
    800045c0:	0001e717          	auipc	a4,0x1e
    800045c4:	03070713          	addi	a4,a4,48 # 800225f0 <disk>
    if(f->ref == 0){
    800045c8:	40dc                	lw	a5,4(s1)
    800045ca:	cf99                	beqz	a5,800045e8 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045cc:	02848493          	addi	s1,s1,40
    800045d0:	fee49ce3          	bne	s1,a4,800045c8 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045d4:	0001d517          	auipc	a0,0x1d
    800045d8:	06450513          	addi	a0,a0,100 # 80021638 <ftable>
    800045dc:	ffffc097          	auipc	ra,0xffffc
    800045e0:	6c2080e7          	jalr	1730(ra) # 80000c9e <release>
  return 0;
    800045e4:	4481                	li	s1,0
    800045e6:	a819                	j	800045fc <filealloc+0x5e>
      f->ref = 1;
    800045e8:	4785                	li	a5,1
    800045ea:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045ec:	0001d517          	auipc	a0,0x1d
    800045f0:	04c50513          	addi	a0,a0,76 # 80021638 <ftable>
    800045f4:	ffffc097          	auipc	ra,0xffffc
    800045f8:	6aa080e7          	jalr	1706(ra) # 80000c9e <release>
}
    800045fc:	8526                	mv	a0,s1
    800045fe:	60e2                	ld	ra,24(sp)
    80004600:	6442                	ld	s0,16(sp)
    80004602:	64a2                	ld	s1,8(sp)
    80004604:	6105                	addi	sp,sp,32
    80004606:	8082                	ret

0000000080004608 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004608:	1101                	addi	sp,sp,-32
    8000460a:	ec06                	sd	ra,24(sp)
    8000460c:	e822                	sd	s0,16(sp)
    8000460e:	e426                	sd	s1,8(sp)
    80004610:	1000                	addi	s0,sp,32
    80004612:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004614:	0001d517          	auipc	a0,0x1d
    80004618:	02450513          	addi	a0,a0,36 # 80021638 <ftable>
    8000461c:	ffffc097          	auipc	ra,0xffffc
    80004620:	5ce080e7          	jalr	1486(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004624:	40dc                	lw	a5,4(s1)
    80004626:	02f05263          	blez	a5,8000464a <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000462a:	2785                	addiw	a5,a5,1
    8000462c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000462e:	0001d517          	auipc	a0,0x1d
    80004632:	00a50513          	addi	a0,a0,10 # 80021638 <ftable>
    80004636:	ffffc097          	auipc	ra,0xffffc
    8000463a:	668080e7          	jalr	1640(ra) # 80000c9e <release>
  return f;
}
    8000463e:	8526                	mv	a0,s1
    80004640:	60e2                	ld	ra,24(sp)
    80004642:	6442                	ld	s0,16(sp)
    80004644:	64a2                	ld	s1,8(sp)
    80004646:	6105                	addi	sp,sp,32
    80004648:	8082                	ret
    panic("filedup");
    8000464a:	00004517          	auipc	a0,0x4
    8000464e:	14650513          	addi	a0,a0,326 # 80008790 <syscalls+0x260>
    80004652:	ffffc097          	auipc	ra,0xffffc
    80004656:	ef2080e7          	jalr	-270(ra) # 80000544 <panic>

000000008000465a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000465a:	7139                	addi	sp,sp,-64
    8000465c:	fc06                	sd	ra,56(sp)
    8000465e:	f822                	sd	s0,48(sp)
    80004660:	f426                	sd	s1,40(sp)
    80004662:	f04a                	sd	s2,32(sp)
    80004664:	ec4e                	sd	s3,24(sp)
    80004666:	e852                	sd	s4,16(sp)
    80004668:	e456                	sd	s5,8(sp)
    8000466a:	0080                	addi	s0,sp,64
    8000466c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000466e:	0001d517          	auipc	a0,0x1d
    80004672:	fca50513          	addi	a0,a0,-54 # 80021638 <ftable>
    80004676:	ffffc097          	auipc	ra,0xffffc
    8000467a:	574080e7          	jalr	1396(ra) # 80000bea <acquire>
  if(f->ref < 1)
    8000467e:	40dc                	lw	a5,4(s1)
    80004680:	06f05163          	blez	a5,800046e2 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004684:	37fd                	addiw	a5,a5,-1
    80004686:	0007871b          	sext.w	a4,a5
    8000468a:	c0dc                	sw	a5,4(s1)
    8000468c:	06e04363          	bgtz	a4,800046f2 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004690:	0004a903          	lw	s2,0(s1)
    80004694:	0094ca83          	lbu	s5,9(s1)
    80004698:	0104ba03          	ld	s4,16(s1)
    8000469c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800046a0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800046a4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800046a8:	0001d517          	auipc	a0,0x1d
    800046ac:	f9050513          	addi	a0,a0,-112 # 80021638 <ftable>
    800046b0:	ffffc097          	auipc	ra,0xffffc
    800046b4:	5ee080e7          	jalr	1518(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    800046b8:	4785                	li	a5,1
    800046ba:	04f90d63          	beq	s2,a5,80004714 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046be:	3979                	addiw	s2,s2,-2
    800046c0:	4785                	li	a5,1
    800046c2:	0527e063          	bltu	a5,s2,80004702 <fileclose+0xa8>
    begin_op();
    800046c6:	00000097          	auipc	ra,0x0
    800046ca:	ac8080e7          	jalr	-1336(ra) # 8000418e <begin_op>
    iput(ff.ip);
    800046ce:	854e                	mv	a0,s3
    800046d0:	fffff097          	auipc	ra,0xfffff
    800046d4:	2b6080e7          	jalr	694(ra) # 80003986 <iput>
    end_op();
    800046d8:	00000097          	auipc	ra,0x0
    800046dc:	b36080e7          	jalr	-1226(ra) # 8000420e <end_op>
    800046e0:	a00d                	j	80004702 <fileclose+0xa8>
    panic("fileclose");
    800046e2:	00004517          	auipc	a0,0x4
    800046e6:	0b650513          	addi	a0,a0,182 # 80008798 <syscalls+0x268>
    800046ea:	ffffc097          	auipc	ra,0xffffc
    800046ee:	e5a080e7          	jalr	-422(ra) # 80000544 <panic>
    release(&ftable.lock);
    800046f2:	0001d517          	auipc	a0,0x1d
    800046f6:	f4650513          	addi	a0,a0,-186 # 80021638 <ftable>
    800046fa:	ffffc097          	auipc	ra,0xffffc
    800046fe:	5a4080e7          	jalr	1444(ra) # 80000c9e <release>
  }
}
    80004702:	70e2                	ld	ra,56(sp)
    80004704:	7442                	ld	s0,48(sp)
    80004706:	74a2                	ld	s1,40(sp)
    80004708:	7902                	ld	s2,32(sp)
    8000470a:	69e2                	ld	s3,24(sp)
    8000470c:	6a42                	ld	s4,16(sp)
    8000470e:	6aa2                	ld	s5,8(sp)
    80004710:	6121                	addi	sp,sp,64
    80004712:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004714:	85d6                	mv	a1,s5
    80004716:	8552                	mv	a0,s4
    80004718:	00000097          	auipc	ra,0x0
    8000471c:	34c080e7          	jalr	844(ra) # 80004a64 <pipeclose>
    80004720:	b7cd                	j	80004702 <fileclose+0xa8>

0000000080004722 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004722:	715d                	addi	sp,sp,-80
    80004724:	e486                	sd	ra,72(sp)
    80004726:	e0a2                	sd	s0,64(sp)
    80004728:	fc26                	sd	s1,56(sp)
    8000472a:	f84a                	sd	s2,48(sp)
    8000472c:	f44e                	sd	s3,40(sp)
    8000472e:	0880                	addi	s0,sp,80
    80004730:	84aa                	mv	s1,a0
    80004732:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004734:	ffffd097          	auipc	ra,0xffffd
    80004738:	292080e7          	jalr	658(ra) # 800019c6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000473c:	409c                	lw	a5,0(s1)
    8000473e:	37f9                	addiw	a5,a5,-2
    80004740:	4705                	li	a4,1
    80004742:	04f76763          	bltu	a4,a5,80004790 <filestat+0x6e>
    80004746:	892a                	mv	s2,a0
    ilock(f->ip);
    80004748:	6c88                	ld	a0,24(s1)
    8000474a:	fffff097          	auipc	ra,0xfffff
    8000474e:	082080e7          	jalr	130(ra) # 800037cc <ilock>
    stati(f->ip, &st);
    80004752:	fb840593          	addi	a1,s0,-72
    80004756:	6c88                	ld	a0,24(s1)
    80004758:	fffff097          	auipc	ra,0xfffff
    8000475c:	2fe080e7          	jalr	766(ra) # 80003a56 <stati>
    iunlock(f->ip);
    80004760:	6c88                	ld	a0,24(s1)
    80004762:	fffff097          	auipc	ra,0xfffff
    80004766:	12c080e7          	jalr	300(ra) # 8000388e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000476a:	46e1                	li	a3,24
    8000476c:	fb840613          	addi	a2,s0,-72
    80004770:	85ce                	mv	a1,s3
    80004772:	05093503          	ld	a0,80(s2)
    80004776:	ffffd097          	auipc	ra,0xffffd
    8000477a:	f0e080e7          	jalr	-242(ra) # 80001684 <copyout>
    8000477e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004782:	60a6                	ld	ra,72(sp)
    80004784:	6406                	ld	s0,64(sp)
    80004786:	74e2                	ld	s1,56(sp)
    80004788:	7942                	ld	s2,48(sp)
    8000478a:	79a2                	ld	s3,40(sp)
    8000478c:	6161                	addi	sp,sp,80
    8000478e:	8082                	ret
  return -1;
    80004790:	557d                	li	a0,-1
    80004792:	bfc5                	j	80004782 <filestat+0x60>

0000000080004794 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004794:	7179                	addi	sp,sp,-48
    80004796:	f406                	sd	ra,40(sp)
    80004798:	f022                	sd	s0,32(sp)
    8000479a:	ec26                	sd	s1,24(sp)
    8000479c:	e84a                	sd	s2,16(sp)
    8000479e:	e44e                	sd	s3,8(sp)
    800047a0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800047a2:	00854783          	lbu	a5,8(a0)
    800047a6:	c3d5                	beqz	a5,8000484a <fileread+0xb6>
    800047a8:	84aa                	mv	s1,a0
    800047aa:	89ae                	mv	s3,a1
    800047ac:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800047ae:	411c                	lw	a5,0(a0)
    800047b0:	4705                	li	a4,1
    800047b2:	04e78963          	beq	a5,a4,80004804 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047b6:	470d                	li	a4,3
    800047b8:	04e78d63          	beq	a5,a4,80004812 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047bc:	4709                	li	a4,2
    800047be:	06e79e63          	bne	a5,a4,8000483a <fileread+0xa6>
    ilock(f->ip);
    800047c2:	6d08                	ld	a0,24(a0)
    800047c4:	fffff097          	auipc	ra,0xfffff
    800047c8:	008080e7          	jalr	8(ra) # 800037cc <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047cc:	874a                	mv	a4,s2
    800047ce:	5094                	lw	a3,32(s1)
    800047d0:	864e                	mv	a2,s3
    800047d2:	4585                	li	a1,1
    800047d4:	6c88                	ld	a0,24(s1)
    800047d6:	fffff097          	auipc	ra,0xfffff
    800047da:	2aa080e7          	jalr	682(ra) # 80003a80 <readi>
    800047de:	892a                	mv	s2,a0
    800047e0:	00a05563          	blez	a0,800047ea <fileread+0x56>
      f->off += r;
    800047e4:	509c                	lw	a5,32(s1)
    800047e6:	9fa9                	addw	a5,a5,a0
    800047e8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047ea:	6c88                	ld	a0,24(s1)
    800047ec:	fffff097          	auipc	ra,0xfffff
    800047f0:	0a2080e7          	jalr	162(ra) # 8000388e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047f4:	854a                	mv	a0,s2
    800047f6:	70a2                	ld	ra,40(sp)
    800047f8:	7402                	ld	s0,32(sp)
    800047fa:	64e2                	ld	s1,24(sp)
    800047fc:	6942                	ld	s2,16(sp)
    800047fe:	69a2                	ld	s3,8(sp)
    80004800:	6145                	addi	sp,sp,48
    80004802:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004804:	6908                	ld	a0,16(a0)
    80004806:	00000097          	auipc	ra,0x0
    8000480a:	3ce080e7          	jalr	974(ra) # 80004bd4 <piperead>
    8000480e:	892a                	mv	s2,a0
    80004810:	b7d5                	j	800047f4 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004812:	02451783          	lh	a5,36(a0)
    80004816:	03079693          	slli	a3,a5,0x30
    8000481a:	92c1                	srli	a3,a3,0x30
    8000481c:	4725                	li	a4,9
    8000481e:	02d76863          	bltu	a4,a3,8000484e <fileread+0xba>
    80004822:	0792                	slli	a5,a5,0x4
    80004824:	0001d717          	auipc	a4,0x1d
    80004828:	d7470713          	addi	a4,a4,-652 # 80021598 <devsw>
    8000482c:	97ba                	add	a5,a5,a4
    8000482e:	639c                	ld	a5,0(a5)
    80004830:	c38d                	beqz	a5,80004852 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004832:	4505                	li	a0,1
    80004834:	9782                	jalr	a5
    80004836:	892a                	mv	s2,a0
    80004838:	bf75                	j	800047f4 <fileread+0x60>
    panic("fileread");
    8000483a:	00004517          	auipc	a0,0x4
    8000483e:	f6e50513          	addi	a0,a0,-146 # 800087a8 <syscalls+0x278>
    80004842:	ffffc097          	auipc	ra,0xffffc
    80004846:	d02080e7          	jalr	-766(ra) # 80000544 <panic>
    return -1;
    8000484a:	597d                	li	s2,-1
    8000484c:	b765                	j	800047f4 <fileread+0x60>
      return -1;
    8000484e:	597d                	li	s2,-1
    80004850:	b755                	j	800047f4 <fileread+0x60>
    80004852:	597d                	li	s2,-1
    80004854:	b745                	j	800047f4 <fileread+0x60>

0000000080004856 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004856:	715d                	addi	sp,sp,-80
    80004858:	e486                	sd	ra,72(sp)
    8000485a:	e0a2                	sd	s0,64(sp)
    8000485c:	fc26                	sd	s1,56(sp)
    8000485e:	f84a                	sd	s2,48(sp)
    80004860:	f44e                	sd	s3,40(sp)
    80004862:	f052                	sd	s4,32(sp)
    80004864:	ec56                	sd	s5,24(sp)
    80004866:	e85a                	sd	s6,16(sp)
    80004868:	e45e                	sd	s7,8(sp)
    8000486a:	e062                	sd	s8,0(sp)
    8000486c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000486e:	00954783          	lbu	a5,9(a0)
    80004872:	10078663          	beqz	a5,8000497e <filewrite+0x128>
    80004876:	892a                	mv	s2,a0
    80004878:	8aae                	mv	s5,a1
    8000487a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000487c:	411c                	lw	a5,0(a0)
    8000487e:	4705                	li	a4,1
    80004880:	02e78263          	beq	a5,a4,800048a4 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004884:	470d                	li	a4,3
    80004886:	02e78663          	beq	a5,a4,800048b2 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000488a:	4709                	li	a4,2
    8000488c:	0ee79163          	bne	a5,a4,8000496e <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004890:	0ac05d63          	blez	a2,8000494a <filewrite+0xf4>
    int i = 0;
    80004894:	4981                	li	s3,0
    80004896:	6b05                	lui	s6,0x1
    80004898:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000489c:	6b85                	lui	s7,0x1
    8000489e:	c00b8b9b          	addiw	s7,s7,-1024
    800048a2:	a861                	j	8000493a <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800048a4:	6908                	ld	a0,16(a0)
    800048a6:	00000097          	auipc	ra,0x0
    800048aa:	22e080e7          	jalr	558(ra) # 80004ad4 <pipewrite>
    800048ae:	8a2a                	mv	s4,a0
    800048b0:	a045                	j	80004950 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048b2:	02451783          	lh	a5,36(a0)
    800048b6:	03079693          	slli	a3,a5,0x30
    800048ba:	92c1                	srli	a3,a3,0x30
    800048bc:	4725                	li	a4,9
    800048be:	0cd76263          	bltu	a4,a3,80004982 <filewrite+0x12c>
    800048c2:	0792                	slli	a5,a5,0x4
    800048c4:	0001d717          	auipc	a4,0x1d
    800048c8:	cd470713          	addi	a4,a4,-812 # 80021598 <devsw>
    800048cc:	97ba                	add	a5,a5,a4
    800048ce:	679c                	ld	a5,8(a5)
    800048d0:	cbdd                	beqz	a5,80004986 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800048d2:	4505                	li	a0,1
    800048d4:	9782                	jalr	a5
    800048d6:	8a2a                	mv	s4,a0
    800048d8:	a8a5                	j	80004950 <filewrite+0xfa>
    800048da:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048de:	00000097          	auipc	ra,0x0
    800048e2:	8b0080e7          	jalr	-1872(ra) # 8000418e <begin_op>
      ilock(f->ip);
    800048e6:	01893503          	ld	a0,24(s2)
    800048ea:	fffff097          	auipc	ra,0xfffff
    800048ee:	ee2080e7          	jalr	-286(ra) # 800037cc <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048f2:	8762                	mv	a4,s8
    800048f4:	02092683          	lw	a3,32(s2)
    800048f8:	01598633          	add	a2,s3,s5
    800048fc:	4585                	li	a1,1
    800048fe:	01893503          	ld	a0,24(s2)
    80004902:	fffff097          	auipc	ra,0xfffff
    80004906:	276080e7          	jalr	630(ra) # 80003b78 <writei>
    8000490a:	84aa                	mv	s1,a0
    8000490c:	00a05763          	blez	a0,8000491a <filewrite+0xc4>
        f->off += r;
    80004910:	02092783          	lw	a5,32(s2)
    80004914:	9fa9                	addw	a5,a5,a0
    80004916:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000491a:	01893503          	ld	a0,24(s2)
    8000491e:	fffff097          	auipc	ra,0xfffff
    80004922:	f70080e7          	jalr	-144(ra) # 8000388e <iunlock>
      end_op();
    80004926:	00000097          	auipc	ra,0x0
    8000492a:	8e8080e7          	jalr	-1816(ra) # 8000420e <end_op>

      if(r != n1){
    8000492e:	009c1f63          	bne	s8,s1,8000494c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004932:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004936:	0149db63          	bge	s3,s4,8000494c <filewrite+0xf6>
      int n1 = n - i;
    8000493a:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000493e:	84be                	mv	s1,a5
    80004940:	2781                	sext.w	a5,a5
    80004942:	f8fb5ce3          	bge	s6,a5,800048da <filewrite+0x84>
    80004946:	84de                	mv	s1,s7
    80004948:	bf49                	j	800048da <filewrite+0x84>
    int i = 0;
    8000494a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000494c:	013a1f63          	bne	s4,s3,8000496a <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004950:	8552                	mv	a0,s4
    80004952:	60a6                	ld	ra,72(sp)
    80004954:	6406                	ld	s0,64(sp)
    80004956:	74e2                	ld	s1,56(sp)
    80004958:	7942                	ld	s2,48(sp)
    8000495a:	79a2                	ld	s3,40(sp)
    8000495c:	7a02                	ld	s4,32(sp)
    8000495e:	6ae2                	ld	s5,24(sp)
    80004960:	6b42                	ld	s6,16(sp)
    80004962:	6ba2                	ld	s7,8(sp)
    80004964:	6c02                	ld	s8,0(sp)
    80004966:	6161                	addi	sp,sp,80
    80004968:	8082                	ret
    ret = (i == n ? n : -1);
    8000496a:	5a7d                	li	s4,-1
    8000496c:	b7d5                	j	80004950 <filewrite+0xfa>
    panic("filewrite");
    8000496e:	00004517          	auipc	a0,0x4
    80004972:	e4a50513          	addi	a0,a0,-438 # 800087b8 <syscalls+0x288>
    80004976:	ffffc097          	auipc	ra,0xffffc
    8000497a:	bce080e7          	jalr	-1074(ra) # 80000544 <panic>
    return -1;
    8000497e:	5a7d                	li	s4,-1
    80004980:	bfc1                	j	80004950 <filewrite+0xfa>
      return -1;
    80004982:	5a7d                	li	s4,-1
    80004984:	b7f1                	j	80004950 <filewrite+0xfa>
    80004986:	5a7d                	li	s4,-1
    80004988:	b7e1                	j	80004950 <filewrite+0xfa>

000000008000498a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000498a:	7179                	addi	sp,sp,-48
    8000498c:	f406                	sd	ra,40(sp)
    8000498e:	f022                	sd	s0,32(sp)
    80004990:	ec26                	sd	s1,24(sp)
    80004992:	e84a                	sd	s2,16(sp)
    80004994:	e44e                	sd	s3,8(sp)
    80004996:	e052                	sd	s4,0(sp)
    80004998:	1800                	addi	s0,sp,48
    8000499a:	84aa                	mv	s1,a0
    8000499c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000499e:	0005b023          	sd	zero,0(a1)
    800049a2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049a6:	00000097          	auipc	ra,0x0
    800049aa:	bf8080e7          	jalr	-1032(ra) # 8000459e <filealloc>
    800049ae:	e088                	sd	a0,0(s1)
    800049b0:	c551                	beqz	a0,80004a3c <pipealloc+0xb2>
    800049b2:	00000097          	auipc	ra,0x0
    800049b6:	bec080e7          	jalr	-1044(ra) # 8000459e <filealloc>
    800049ba:	00aa3023          	sd	a0,0(s4)
    800049be:	c92d                	beqz	a0,80004a30 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049c0:	ffffc097          	auipc	ra,0xffffc
    800049c4:	13a080e7          	jalr	314(ra) # 80000afa <kalloc>
    800049c8:	892a                	mv	s2,a0
    800049ca:	c125                	beqz	a0,80004a2a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049cc:	4985                	li	s3,1
    800049ce:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049d2:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049d6:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049da:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049de:	00004597          	auipc	a1,0x4
    800049e2:	a8a58593          	addi	a1,a1,-1398 # 80008468 <states.1727+0x1a0>
    800049e6:	ffffc097          	auipc	ra,0xffffc
    800049ea:	174080e7          	jalr	372(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    800049ee:	609c                	ld	a5,0(s1)
    800049f0:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049f4:	609c                	ld	a5,0(s1)
    800049f6:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049fa:	609c                	ld	a5,0(s1)
    800049fc:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a00:	609c                	ld	a5,0(s1)
    80004a02:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a06:	000a3783          	ld	a5,0(s4)
    80004a0a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a0e:	000a3783          	ld	a5,0(s4)
    80004a12:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a16:	000a3783          	ld	a5,0(s4)
    80004a1a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a1e:	000a3783          	ld	a5,0(s4)
    80004a22:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a26:	4501                	li	a0,0
    80004a28:	a025                	j	80004a50 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a2a:	6088                	ld	a0,0(s1)
    80004a2c:	e501                	bnez	a0,80004a34 <pipealloc+0xaa>
    80004a2e:	a039                	j	80004a3c <pipealloc+0xb2>
    80004a30:	6088                	ld	a0,0(s1)
    80004a32:	c51d                	beqz	a0,80004a60 <pipealloc+0xd6>
    fileclose(*f0);
    80004a34:	00000097          	auipc	ra,0x0
    80004a38:	c26080e7          	jalr	-986(ra) # 8000465a <fileclose>
  if(*f1)
    80004a3c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a40:	557d                	li	a0,-1
  if(*f1)
    80004a42:	c799                	beqz	a5,80004a50 <pipealloc+0xc6>
    fileclose(*f1);
    80004a44:	853e                	mv	a0,a5
    80004a46:	00000097          	auipc	ra,0x0
    80004a4a:	c14080e7          	jalr	-1004(ra) # 8000465a <fileclose>
  return -1;
    80004a4e:	557d                	li	a0,-1
}
    80004a50:	70a2                	ld	ra,40(sp)
    80004a52:	7402                	ld	s0,32(sp)
    80004a54:	64e2                	ld	s1,24(sp)
    80004a56:	6942                	ld	s2,16(sp)
    80004a58:	69a2                	ld	s3,8(sp)
    80004a5a:	6a02                	ld	s4,0(sp)
    80004a5c:	6145                	addi	sp,sp,48
    80004a5e:	8082                	ret
  return -1;
    80004a60:	557d                	li	a0,-1
    80004a62:	b7fd                	j	80004a50 <pipealloc+0xc6>

0000000080004a64 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a64:	1101                	addi	sp,sp,-32
    80004a66:	ec06                	sd	ra,24(sp)
    80004a68:	e822                	sd	s0,16(sp)
    80004a6a:	e426                	sd	s1,8(sp)
    80004a6c:	e04a                	sd	s2,0(sp)
    80004a6e:	1000                	addi	s0,sp,32
    80004a70:	84aa                	mv	s1,a0
    80004a72:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a74:	ffffc097          	auipc	ra,0xffffc
    80004a78:	176080e7          	jalr	374(ra) # 80000bea <acquire>
  if(writable){
    80004a7c:	02090d63          	beqz	s2,80004ab6 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a80:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a84:	21848513          	addi	a0,s1,536
    80004a88:	ffffd097          	auipc	ra,0xffffd
    80004a8c:	64e080e7          	jalr	1614(ra) # 800020d6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a90:	2204b783          	ld	a5,544(s1)
    80004a94:	eb95                	bnez	a5,80004ac8 <pipeclose+0x64>
    release(&pi->lock);
    80004a96:	8526                	mv	a0,s1
    80004a98:	ffffc097          	auipc	ra,0xffffc
    80004a9c:	206080e7          	jalr	518(ra) # 80000c9e <release>
    kfree((char*)pi);
    80004aa0:	8526                	mv	a0,s1
    80004aa2:	ffffc097          	auipc	ra,0xffffc
    80004aa6:	f5c080e7          	jalr	-164(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80004aaa:	60e2                	ld	ra,24(sp)
    80004aac:	6442                	ld	s0,16(sp)
    80004aae:	64a2                	ld	s1,8(sp)
    80004ab0:	6902                	ld	s2,0(sp)
    80004ab2:	6105                	addi	sp,sp,32
    80004ab4:	8082                	ret
    pi->readopen = 0;
    80004ab6:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004aba:	21c48513          	addi	a0,s1,540
    80004abe:	ffffd097          	auipc	ra,0xffffd
    80004ac2:	618080e7          	jalr	1560(ra) # 800020d6 <wakeup>
    80004ac6:	b7e9                	j	80004a90 <pipeclose+0x2c>
    release(&pi->lock);
    80004ac8:	8526                	mv	a0,s1
    80004aca:	ffffc097          	auipc	ra,0xffffc
    80004ace:	1d4080e7          	jalr	468(ra) # 80000c9e <release>
}
    80004ad2:	bfe1                	j	80004aaa <pipeclose+0x46>

0000000080004ad4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ad4:	7159                	addi	sp,sp,-112
    80004ad6:	f486                	sd	ra,104(sp)
    80004ad8:	f0a2                	sd	s0,96(sp)
    80004ada:	eca6                	sd	s1,88(sp)
    80004adc:	e8ca                	sd	s2,80(sp)
    80004ade:	e4ce                	sd	s3,72(sp)
    80004ae0:	e0d2                	sd	s4,64(sp)
    80004ae2:	fc56                	sd	s5,56(sp)
    80004ae4:	f85a                	sd	s6,48(sp)
    80004ae6:	f45e                	sd	s7,40(sp)
    80004ae8:	f062                	sd	s8,32(sp)
    80004aea:	ec66                	sd	s9,24(sp)
    80004aec:	1880                	addi	s0,sp,112
    80004aee:	84aa                	mv	s1,a0
    80004af0:	8aae                	mv	s5,a1
    80004af2:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004af4:	ffffd097          	auipc	ra,0xffffd
    80004af8:	ed2080e7          	jalr	-302(ra) # 800019c6 <myproc>
    80004afc:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004afe:	8526                	mv	a0,s1
    80004b00:	ffffc097          	auipc	ra,0xffffc
    80004b04:	0ea080e7          	jalr	234(ra) # 80000bea <acquire>
  while(i < n){
    80004b08:	0d405463          	blez	s4,80004bd0 <pipewrite+0xfc>
    80004b0c:	8ba6                	mv	s7,s1
  int i = 0;
    80004b0e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b10:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b12:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b16:	21c48c13          	addi	s8,s1,540
    80004b1a:	a08d                	j	80004b7c <pipewrite+0xa8>
      release(&pi->lock);
    80004b1c:	8526                	mv	a0,s1
    80004b1e:	ffffc097          	auipc	ra,0xffffc
    80004b22:	180080e7          	jalr	384(ra) # 80000c9e <release>
      return -1;
    80004b26:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b28:	854a                	mv	a0,s2
    80004b2a:	70a6                	ld	ra,104(sp)
    80004b2c:	7406                	ld	s0,96(sp)
    80004b2e:	64e6                	ld	s1,88(sp)
    80004b30:	6946                	ld	s2,80(sp)
    80004b32:	69a6                	ld	s3,72(sp)
    80004b34:	6a06                	ld	s4,64(sp)
    80004b36:	7ae2                	ld	s5,56(sp)
    80004b38:	7b42                	ld	s6,48(sp)
    80004b3a:	7ba2                	ld	s7,40(sp)
    80004b3c:	7c02                	ld	s8,32(sp)
    80004b3e:	6ce2                	ld	s9,24(sp)
    80004b40:	6165                	addi	sp,sp,112
    80004b42:	8082                	ret
      wakeup(&pi->nread);
    80004b44:	8566                	mv	a0,s9
    80004b46:	ffffd097          	auipc	ra,0xffffd
    80004b4a:	590080e7          	jalr	1424(ra) # 800020d6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b4e:	85de                	mv	a1,s7
    80004b50:	8562                	mv	a0,s8
    80004b52:	ffffd097          	auipc	ra,0xffffd
    80004b56:	520080e7          	jalr	1312(ra) # 80002072 <sleep>
    80004b5a:	a839                	j	80004b78 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b5c:	21c4a783          	lw	a5,540(s1)
    80004b60:	0017871b          	addiw	a4,a5,1
    80004b64:	20e4ae23          	sw	a4,540(s1)
    80004b68:	1ff7f793          	andi	a5,a5,511
    80004b6c:	97a6                	add	a5,a5,s1
    80004b6e:	f9f44703          	lbu	a4,-97(s0)
    80004b72:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b76:	2905                	addiw	s2,s2,1
  while(i < n){
    80004b78:	05495063          	bge	s2,s4,80004bb8 <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80004b7c:	2204a783          	lw	a5,544(s1)
    80004b80:	dfd1                	beqz	a5,80004b1c <pipewrite+0x48>
    80004b82:	854e                	mv	a0,s3
    80004b84:	ffffd097          	auipc	ra,0xffffd
    80004b88:	796080e7          	jalr	1942(ra) # 8000231a <killed>
    80004b8c:	f941                	bnez	a0,80004b1c <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b8e:	2184a783          	lw	a5,536(s1)
    80004b92:	21c4a703          	lw	a4,540(s1)
    80004b96:	2007879b          	addiw	a5,a5,512
    80004b9a:	faf705e3          	beq	a4,a5,80004b44 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b9e:	4685                	li	a3,1
    80004ba0:	01590633          	add	a2,s2,s5
    80004ba4:	f9f40593          	addi	a1,s0,-97
    80004ba8:	0509b503          	ld	a0,80(s3)
    80004bac:	ffffd097          	auipc	ra,0xffffd
    80004bb0:	b64080e7          	jalr	-1180(ra) # 80001710 <copyin>
    80004bb4:	fb6514e3          	bne	a0,s6,80004b5c <pipewrite+0x88>
  wakeup(&pi->nread);
    80004bb8:	21848513          	addi	a0,s1,536
    80004bbc:	ffffd097          	auipc	ra,0xffffd
    80004bc0:	51a080e7          	jalr	1306(ra) # 800020d6 <wakeup>
  release(&pi->lock);
    80004bc4:	8526                	mv	a0,s1
    80004bc6:	ffffc097          	auipc	ra,0xffffc
    80004bca:	0d8080e7          	jalr	216(ra) # 80000c9e <release>
  return i;
    80004bce:	bfa9                	j	80004b28 <pipewrite+0x54>
  int i = 0;
    80004bd0:	4901                	li	s2,0
    80004bd2:	b7dd                	j	80004bb8 <pipewrite+0xe4>

0000000080004bd4 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bd4:	715d                	addi	sp,sp,-80
    80004bd6:	e486                	sd	ra,72(sp)
    80004bd8:	e0a2                	sd	s0,64(sp)
    80004bda:	fc26                	sd	s1,56(sp)
    80004bdc:	f84a                	sd	s2,48(sp)
    80004bde:	f44e                	sd	s3,40(sp)
    80004be0:	f052                	sd	s4,32(sp)
    80004be2:	ec56                	sd	s5,24(sp)
    80004be4:	e85a                	sd	s6,16(sp)
    80004be6:	0880                	addi	s0,sp,80
    80004be8:	84aa                	mv	s1,a0
    80004bea:	892e                	mv	s2,a1
    80004bec:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bee:	ffffd097          	auipc	ra,0xffffd
    80004bf2:	dd8080e7          	jalr	-552(ra) # 800019c6 <myproc>
    80004bf6:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bf8:	8b26                	mv	s6,s1
    80004bfa:	8526                	mv	a0,s1
    80004bfc:	ffffc097          	auipc	ra,0xffffc
    80004c00:	fee080e7          	jalr	-18(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c04:	2184a703          	lw	a4,536(s1)
    80004c08:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c0c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c10:	02f71763          	bne	a4,a5,80004c3e <piperead+0x6a>
    80004c14:	2244a783          	lw	a5,548(s1)
    80004c18:	c39d                	beqz	a5,80004c3e <piperead+0x6a>
    if(killed(pr)){
    80004c1a:	8552                	mv	a0,s4
    80004c1c:	ffffd097          	auipc	ra,0xffffd
    80004c20:	6fe080e7          	jalr	1790(ra) # 8000231a <killed>
    80004c24:	e941                	bnez	a0,80004cb4 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c26:	85da                	mv	a1,s6
    80004c28:	854e                	mv	a0,s3
    80004c2a:	ffffd097          	auipc	ra,0xffffd
    80004c2e:	448080e7          	jalr	1096(ra) # 80002072 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c32:	2184a703          	lw	a4,536(s1)
    80004c36:	21c4a783          	lw	a5,540(s1)
    80004c3a:	fcf70de3          	beq	a4,a5,80004c14 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c3e:	09505263          	blez	s5,80004cc2 <piperead+0xee>
    80004c42:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c44:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c46:	2184a783          	lw	a5,536(s1)
    80004c4a:	21c4a703          	lw	a4,540(s1)
    80004c4e:	02f70d63          	beq	a4,a5,80004c88 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c52:	0017871b          	addiw	a4,a5,1
    80004c56:	20e4ac23          	sw	a4,536(s1)
    80004c5a:	1ff7f793          	andi	a5,a5,511
    80004c5e:	97a6                	add	a5,a5,s1
    80004c60:	0187c783          	lbu	a5,24(a5)
    80004c64:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c68:	4685                	li	a3,1
    80004c6a:	fbf40613          	addi	a2,s0,-65
    80004c6e:	85ca                	mv	a1,s2
    80004c70:	050a3503          	ld	a0,80(s4)
    80004c74:	ffffd097          	auipc	ra,0xffffd
    80004c78:	a10080e7          	jalr	-1520(ra) # 80001684 <copyout>
    80004c7c:	01650663          	beq	a0,s6,80004c88 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c80:	2985                	addiw	s3,s3,1
    80004c82:	0905                	addi	s2,s2,1
    80004c84:	fd3a91e3          	bne	s5,s3,80004c46 <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c88:	21c48513          	addi	a0,s1,540
    80004c8c:	ffffd097          	auipc	ra,0xffffd
    80004c90:	44a080e7          	jalr	1098(ra) # 800020d6 <wakeup>
  release(&pi->lock);
    80004c94:	8526                	mv	a0,s1
    80004c96:	ffffc097          	auipc	ra,0xffffc
    80004c9a:	008080e7          	jalr	8(ra) # 80000c9e <release>
  return i;
}
    80004c9e:	854e                	mv	a0,s3
    80004ca0:	60a6                	ld	ra,72(sp)
    80004ca2:	6406                	ld	s0,64(sp)
    80004ca4:	74e2                	ld	s1,56(sp)
    80004ca6:	7942                	ld	s2,48(sp)
    80004ca8:	79a2                	ld	s3,40(sp)
    80004caa:	7a02                	ld	s4,32(sp)
    80004cac:	6ae2                	ld	s5,24(sp)
    80004cae:	6b42                	ld	s6,16(sp)
    80004cb0:	6161                	addi	sp,sp,80
    80004cb2:	8082                	ret
      release(&pi->lock);
    80004cb4:	8526                	mv	a0,s1
    80004cb6:	ffffc097          	auipc	ra,0xffffc
    80004cba:	fe8080e7          	jalr	-24(ra) # 80000c9e <release>
      return -1;
    80004cbe:	59fd                	li	s3,-1
    80004cc0:	bff9                	j	80004c9e <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cc2:	4981                	li	s3,0
    80004cc4:	b7d1                	j	80004c88 <piperead+0xb4>

0000000080004cc6 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004cc6:	1141                	addi	sp,sp,-16
    80004cc8:	e422                	sd	s0,8(sp)
    80004cca:	0800                	addi	s0,sp,16
    80004ccc:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004cce:	8905                	andi	a0,a0,1
    80004cd0:	c111                	beqz	a0,80004cd4 <flags2perm+0xe>
      perm = PTE_X;
    80004cd2:	4521                	li	a0,8
    if(flags & 0x2)
    80004cd4:	8b89                	andi	a5,a5,2
    80004cd6:	c399                	beqz	a5,80004cdc <flags2perm+0x16>
      perm |= PTE_W;
    80004cd8:	00456513          	ori	a0,a0,4
    return perm;
}
    80004cdc:	6422                	ld	s0,8(sp)
    80004cde:	0141                	addi	sp,sp,16
    80004ce0:	8082                	ret

0000000080004ce2 <exec>:

int
exec(char *path, char **argv)
{
    80004ce2:	df010113          	addi	sp,sp,-528
    80004ce6:	20113423          	sd	ra,520(sp)
    80004cea:	20813023          	sd	s0,512(sp)
    80004cee:	ffa6                	sd	s1,504(sp)
    80004cf0:	fbca                	sd	s2,496(sp)
    80004cf2:	f7ce                	sd	s3,488(sp)
    80004cf4:	f3d2                	sd	s4,480(sp)
    80004cf6:	efd6                	sd	s5,472(sp)
    80004cf8:	ebda                	sd	s6,464(sp)
    80004cfa:	e7de                	sd	s7,456(sp)
    80004cfc:	e3e2                	sd	s8,448(sp)
    80004cfe:	ff66                	sd	s9,440(sp)
    80004d00:	fb6a                	sd	s10,432(sp)
    80004d02:	f76e                	sd	s11,424(sp)
    80004d04:	0c00                	addi	s0,sp,528
    80004d06:	84aa                	mv	s1,a0
    80004d08:	dea43c23          	sd	a0,-520(s0)
    80004d0c:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d10:	ffffd097          	auipc	ra,0xffffd
    80004d14:	cb6080e7          	jalr	-842(ra) # 800019c6 <myproc>
    80004d18:	892a                	mv	s2,a0

  begin_op();
    80004d1a:	fffff097          	auipc	ra,0xfffff
    80004d1e:	474080e7          	jalr	1140(ra) # 8000418e <begin_op>

  if((ip = namei(path)) == 0){
    80004d22:	8526                	mv	a0,s1
    80004d24:	fffff097          	auipc	ra,0xfffff
    80004d28:	24e080e7          	jalr	590(ra) # 80003f72 <namei>
    80004d2c:	c92d                	beqz	a0,80004d9e <exec+0xbc>
    80004d2e:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d30:	fffff097          	auipc	ra,0xfffff
    80004d34:	a9c080e7          	jalr	-1380(ra) # 800037cc <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d38:	04000713          	li	a4,64
    80004d3c:	4681                	li	a3,0
    80004d3e:	e5040613          	addi	a2,s0,-432
    80004d42:	4581                	li	a1,0
    80004d44:	8526                	mv	a0,s1
    80004d46:	fffff097          	auipc	ra,0xfffff
    80004d4a:	d3a080e7          	jalr	-710(ra) # 80003a80 <readi>
    80004d4e:	04000793          	li	a5,64
    80004d52:	00f51a63          	bne	a0,a5,80004d66 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004d56:	e5042703          	lw	a4,-432(s0)
    80004d5a:	464c47b7          	lui	a5,0x464c4
    80004d5e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d62:	04f70463          	beq	a4,a5,80004daa <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d66:	8526                	mv	a0,s1
    80004d68:	fffff097          	auipc	ra,0xfffff
    80004d6c:	cc6080e7          	jalr	-826(ra) # 80003a2e <iunlockput>
    end_op();
    80004d70:	fffff097          	auipc	ra,0xfffff
    80004d74:	49e080e7          	jalr	1182(ra) # 8000420e <end_op>
  }
  return -1;
    80004d78:	557d                	li	a0,-1
}
    80004d7a:	20813083          	ld	ra,520(sp)
    80004d7e:	20013403          	ld	s0,512(sp)
    80004d82:	74fe                	ld	s1,504(sp)
    80004d84:	795e                	ld	s2,496(sp)
    80004d86:	79be                	ld	s3,488(sp)
    80004d88:	7a1e                	ld	s4,480(sp)
    80004d8a:	6afe                	ld	s5,472(sp)
    80004d8c:	6b5e                	ld	s6,464(sp)
    80004d8e:	6bbe                	ld	s7,456(sp)
    80004d90:	6c1e                	ld	s8,448(sp)
    80004d92:	7cfa                	ld	s9,440(sp)
    80004d94:	7d5a                	ld	s10,432(sp)
    80004d96:	7dba                	ld	s11,424(sp)
    80004d98:	21010113          	addi	sp,sp,528
    80004d9c:	8082                	ret
    end_op();
    80004d9e:	fffff097          	auipc	ra,0xfffff
    80004da2:	470080e7          	jalr	1136(ra) # 8000420e <end_op>
    return -1;
    80004da6:	557d                	li	a0,-1
    80004da8:	bfc9                	j	80004d7a <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004daa:	854a                	mv	a0,s2
    80004dac:	ffffd097          	auipc	ra,0xffffd
    80004db0:	cde080e7          	jalr	-802(ra) # 80001a8a <proc_pagetable>
    80004db4:	8baa                	mv	s7,a0
    80004db6:	d945                	beqz	a0,80004d66 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004db8:	e7042983          	lw	s3,-400(s0)
    80004dbc:	e8845783          	lhu	a5,-376(s0)
    80004dc0:	c7ad                	beqz	a5,80004e2a <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004dc2:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dc4:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004dc6:	6c85                	lui	s9,0x1
    80004dc8:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004dcc:	def43823          	sd	a5,-528(s0)
    80004dd0:	ac0d                	j	80005002 <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004dd2:	00004517          	auipc	a0,0x4
    80004dd6:	9f650513          	addi	a0,a0,-1546 # 800087c8 <syscalls+0x298>
    80004dda:	ffffb097          	auipc	ra,0xffffb
    80004dde:	76a080e7          	jalr	1898(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004de2:	8756                	mv	a4,s5
    80004de4:	012d86bb          	addw	a3,s11,s2
    80004de8:	4581                	li	a1,0
    80004dea:	8526                	mv	a0,s1
    80004dec:	fffff097          	auipc	ra,0xfffff
    80004df0:	c94080e7          	jalr	-876(ra) # 80003a80 <readi>
    80004df4:	2501                	sext.w	a0,a0
    80004df6:	1aaa9a63          	bne	s5,a0,80004faa <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    80004dfa:	6785                	lui	a5,0x1
    80004dfc:	0127893b          	addw	s2,a5,s2
    80004e00:	77fd                	lui	a5,0xfffff
    80004e02:	01478a3b          	addw	s4,a5,s4
    80004e06:	1f897563          	bgeu	s2,s8,80004ff0 <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    80004e0a:	02091593          	slli	a1,s2,0x20
    80004e0e:	9181                	srli	a1,a1,0x20
    80004e10:	95ea                	add	a1,a1,s10
    80004e12:	855e                	mv	a0,s7
    80004e14:	ffffc097          	auipc	ra,0xffffc
    80004e18:	264080e7          	jalr	612(ra) # 80001078 <walkaddr>
    80004e1c:	862a                	mv	a2,a0
    if(pa == 0)
    80004e1e:	d955                	beqz	a0,80004dd2 <exec+0xf0>
      n = PGSIZE;
    80004e20:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004e22:	fd9a70e3          	bgeu	s4,s9,80004de2 <exec+0x100>
      n = sz - i;
    80004e26:	8ad2                	mv	s5,s4
    80004e28:	bf6d                	j	80004de2 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e2a:	4a01                	li	s4,0
  iunlockput(ip);
    80004e2c:	8526                	mv	a0,s1
    80004e2e:	fffff097          	auipc	ra,0xfffff
    80004e32:	c00080e7          	jalr	-1024(ra) # 80003a2e <iunlockput>
  end_op();
    80004e36:	fffff097          	auipc	ra,0xfffff
    80004e3a:	3d8080e7          	jalr	984(ra) # 8000420e <end_op>
  p = myproc();
    80004e3e:	ffffd097          	auipc	ra,0xffffd
    80004e42:	b88080e7          	jalr	-1144(ra) # 800019c6 <myproc>
    80004e46:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e48:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e4c:	6785                	lui	a5,0x1
    80004e4e:	17fd                	addi	a5,a5,-1
    80004e50:	9a3e                	add	s4,s4,a5
    80004e52:	757d                	lui	a0,0xfffff
    80004e54:	00aa77b3          	and	a5,s4,a0
    80004e58:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e5c:	4691                	li	a3,4
    80004e5e:	6609                	lui	a2,0x2
    80004e60:	963e                	add	a2,a2,a5
    80004e62:	85be                	mv	a1,a5
    80004e64:	855e                	mv	a0,s7
    80004e66:	ffffc097          	auipc	ra,0xffffc
    80004e6a:	5c6080e7          	jalr	1478(ra) # 8000142c <uvmalloc>
    80004e6e:	8b2a                	mv	s6,a0
  ip = 0;
    80004e70:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e72:	12050c63          	beqz	a0,80004faa <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e76:	75f9                	lui	a1,0xffffe
    80004e78:	95aa                	add	a1,a1,a0
    80004e7a:	855e                	mv	a0,s7
    80004e7c:	ffffc097          	auipc	ra,0xffffc
    80004e80:	7d6080e7          	jalr	2006(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e84:	7c7d                	lui	s8,0xfffff
    80004e86:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e88:	e0043783          	ld	a5,-512(s0)
    80004e8c:	6388                	ld	a0,0(a5)
    80004e8e:	c535                	beqz	a0,80004efa <exec+0x218>
    80004e90:	e9040993          	addi	s3,s0,-368
    80004e94:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e98:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e9a:	ffffc097          	auipc	ra,0xffffc
    80004e9e:	fd0080e7          	jalr	-48(ra) # 80000e6a <strlen>
    80004ea2:	2505                	addiw	a0,a0,1
    80004ea4:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004ea8:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004eac:	13896663          	bltu	s2,s8,80004fd8 <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004eb0:	e0043d83          	ld	s11,-512(s0)
    80004eb4:	000dba03          	ld	s4,0(s11)
    80004eb8:	8552                	mv	a0,s4
    80004eba:	ffffc097          	auipc	ra,0xffffc
    80004ebe:	fb0080e7          	jalr	-80(ra) # 80000e6a <strlen>
    80004ec2:	0015069b          	addiw	a3,a0,1
    80004ec6:	8652                	mv	a2,s4
    80004ec8:	85ca                	mv	a1,s2
    80004eca:	855e                	mv	a0,s7
    80004ecc:	ffffc097          	auipc	ra,0xffffc
    80004ed0:	7b8080e7          	jalr	1976(ra) # 80001684 <copyout>
    80004ed4:	10054663          	bltz	a0,80004fe0 <exec+0x2fe>
    ustack[argc] = sp;
    80004ed8:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004edc:	0485                	addi	s1,s1,1
    80004ede:	008d8793          	addi	a5,s11,8
    80004ee2:	e0f43023          	sd	a5,-512(s0)
    80004ee6:	008db503          	ld	a0,8(s11)
    80004eea:	c911                	beqz	a0,80004efe <exec+0x21c>
    if(argc >= MAXARG)
    80004eec:	09a1                	addi	s3,s3,8
    80004eee:	fb3c96e3          	bne	s9,s3,80004e9a <exec+0x1b8>
  sz = sz1;
    80004ef2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ef6:	4481                	li	s1,0
    80004ef8:	a84d                	j	80004faa <exec+0x2c8>
  sp = sz;
    80004efa:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004efc:	4481                	li	s1,0
  ustack[argc] = 0;
    80004efe:	00349793          	slli	a5,s1,0x3
    80004f02:	f9040713          	addi	a4,s0,-112
    80004f06:	97ba                	add	a5,a5,a4
    80004f08:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004f0c:	00148693          	addi	a3,s1,1
    80004f10:	068e                	slli	a3,a3,0x3
    80004f12:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f16:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f1a:	01897663          	bgeu	s2,s8,80004f26 <exec+0x244>
  sz = sz1;
    80004f1e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f22:	4481                	li	s1,0
    80004f24:	a059                	j	80004faa <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f26:	e9040613          	addi	a2,s0,-368
    80004f2a:	85ca                	mv	a1,s2
    80004f2c:	855e                	mv	a0,s7
    80004f2e:	ffffc097          	auipc	ra,0xffffc
    80004f32:	756080e7          	jalr	1878(ra) # 80001684 <copyout>
    80004f36:	0a054963          	bltz	a0,80004fe8 <exec+0x306>
  p->trapframe->a1 = sp;
    80004f3a:	058ab783          	ld	a5,88(s5)
    80004f3e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f42:	df843783          	ld	a5,-520(s0)
    80004f46:	0007c703          	lbu	a4,0(a5)
    80004f4a:	cf11                	beqz	a4,80004f66 <exec+0x284>
    80004f4c:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f4e:	02f00693          	li	a3,47
    80004f52:	a039                	j	80004f60 <exec+0x27e>
      last = s+1;
    80004f54:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004f58:	0785                	addi	a5,a5,1
    80004f5a:	fff7c703          	lbu	a4,-1(a5)
    80004f5e:	c701                	beqz	a4,80004f66 <exec+0x284>
    if(*s == '/')
    80004f60:	fed71ce3          	bne	a4,a3,80004f58 <exec+0x276>
    80004f64:	bfc5                	j	80004f54 <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f66:	4641                	li	a2,16
    80004f68:	df843583          	ld	a1,-520(s0)
    80004f6c:	158a8513          	addi	a0,s5,344
    80004f70:	ffffc097          	auipc	ra,0xffffc
    80004f74:	ec8080e7          	jalr	-312(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f78:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f7c:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f80:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f84:	058ab783          	ld	a5,88(s5)
    80004f88:	e6843703          	ld	a4,-408(s0)
    80004f8c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f8e:	058ab783          	ld	a5,88(s5)
    80004f92:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f96:	85ea                	mv	a1,s10
    80004f98:	ffffd097          	auipc	ra,0xffffd
    80004f9c:	b8e080e7          	jalr	-1138(ra) # 80001b26 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004fa0:	0004851b          	sext.w	a0,s1
    80004fa4:	bbd9                	j	80004d7a <exec+0x98>
    80004fa6:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004faa:	e0843583          	ld	a1,-504(s0)
    80004fae:	855e                	mv	a0,s7
    80004fb0:	ffffd097          	auipc	ra,0xffffd
    80004fb4:	b76080e7          	jalr	-1162(ra) # 80001b26 <proc_freepagetable>
  if(ip){
    80004fb8:	da0497e3          	bnez	s1,80004d66 <exec+0x84>
  return -1;
    80004fbc:	557d                	li	a0,-1
    80004fbe:	bb75                	j	80004d7a <exec+0x98>
    80004fc0:	e1443423          	sd	s4,-504(s0)
    80004fc4:	b7dd                	j	80004faa <exec+0x2c8>
    80004fc6:	e1443423          	sd	s4,-504(s0)
    80004fca:	b7c5                	j	80004faa <exec+0x2c8>
    80004fcc:	e1443423          	sd	s4,-504(s0)
    80004fd0:	bfe9                	j	80004faa <exec+0x2c8>
    80004fd2:	e1443423          	sd	s4,-504(s0)
    80004fd6:	bfd1                	j	80004faa <exec+0x2c8>
  sz = sz1;
    80004fd8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fdc:	4481                	li	s1,0
    80004fde:	b7f1                	j	80004faa <exec+0x2c8>
  sz = sz1;
    80004fe0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fe4:	4481                	li	s1,0
    80004fe6:	b7d1                	j	80004faa <exec+0x2c8>
  sz = sz1;
    80004fe8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fec:	4481                	li	s1,0
    80004fee:	bf75                	j	80004faa <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004ff0:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ff4:	2b05                	addiw	s6,s6,1
    80004ff6:	0389899b          	addiw	s3,s3,56
    80004ffa:	e8845783          	lhu	a5,-376(s0)
    80004ffe:	e2fb57e3          	bge	s6,a5,80004e2c <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005002:	2981                	sext.w	s3,s3
    80005004:	03800713          	li	a4,56
    80005008:	86ce                	mv	a3,s3
    8000500a:	e1840613          	addi	a2,s0,-488
    8000500e:	4581                	li	a1,0
    80005010:	8526                	mv	a0,s1
    80005012:	fffff097          	auipc	ra,0xfffff
    80005016:	a6e080e7          	jalr	-1426(ra) # 80003a80 <readi>
    8000501a:	03800793          	li	a5,56
    8000501e:	f8f514e3          	bne	a0,a5,80004fa6 <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    80005022:	e1842783          	lw	a5,-488(s0)
    80005026:	4705                	li	a4,1
    80005028:	fce796e3          	bne	a5,a4,80004ff4 <exec+0x312>
    if(ph.memsz < ph.filesz)
    8000502c:	e4043903          	ld	s2,-448(s0)
    80005030:	e3843783          	ld	a5,-456(s0)
    80005034:	f8f966e3          	bltu	s2,a5,80004fc0 <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005038:	e2843783          	ld	a5,-472(s0)
    8000503c:	993e                	add	s2,s2,a5
    8000503e:	f8f964e3          	bltu	s2,a5,80004fc6 <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    80005042:	df043703          	ld	a4,-528(s0)
    80005046:	8ff9                	and	a5,a5,a4
    80005048:	f3d1                	bnez	a5,80004fcc <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000504a:	e1c42503          	lw	a0,-484(s0)
    8000504e:	00000097          	auipc	ra,0x0
    80005052:	c78080e7          	jalr	-904(ra) # 80004cc6 <flags2perm>
    80005056:	86aa                	mv	a3,a0
    80005058:	864a                	mv	a2,s2
    8000505a:	85d2                	mv	a1,s4
    8000505c:	855e                	mv	a0,s7
    8000505e:	ffffc097          	auipc	ra,0xffffc
    80005062:	3ce080e7          	jalr	974(ra) # 8000142c <uvmalloc>
    80005066:	e0a43423          	sd	a0,-504(s0)
    8000506a:	d525                	beqz	a0,80004fd2 <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000506c:	e2843d03          	ld	s10,-472(s0)
    80005070:	e2042d83          	lw	s11,-480(s0)
    80005074:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005078:	f60c0ce3          	beqz	s8,80004ff0 <exec+0x30e>
    8000507c:	8a62                	mv	s4,s8
    8000507e:	4901                	li	s2,0
    80005080:	b369                	j	80004e0a <exec+0x128>

0000000080005082 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005082:	7179                	addi	sp,sp,-48
    80005084:	f406                	sd	ra,40(sp)
    80005086:	f022                	sd	s0,32(sp)
    80005088:	ec26                	sd	s1,24(sp)
    8000508a:	e84a                	sd	s2,16(sp)
    8000508c:	1800                	addi	s0,sp,48
    8000508e:	892e                	mv	s2,a1
    80005090:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005092:	fdc40593          	addi	a1,s0,-36
    80005096:	ffffe097          	auipc	ra,0xffffe
    8000509a:	aca080e7          	jalr	-1334(ra) # 80002b60 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000509e:	fdc42703          	lw	a4,-36(s0)
    800050a2:	47bd                	li	a5,15
    800050a4:	02e7eb63          	bltu	a5,a4,800050da <argfd+0x58>
    800050a8:	ffffd097          	auipc	ra,0xffffd
    800050ac:	91e080e7          	jalr	-1762(ra) # 800019c6 <myproc>
    800050b0:	fdc42703          	lw	a4,-36(s0)
    800050b4:	01a70793          	addi	a5,a4,26
    800050b8:	078e                	slli	a5,a5,0x3
    800050ba:	953e                	add	a0,a0,a5
    800050bc:	611c                	ld	a5,0(a0)
    800050be:	c385                	beqz	a5,800050de <argfd+0x5c>
    return -1;
  if(pfd)
    800050c0:	00090463          	beqz	s2,800050c8 <argfd+0x46>
    *pfd = fd;
    800050c4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050c8:	4501                	li	a0,0
  if(pf)
    800050ca:	c091                	beqz	s1,800050ce <argfd+0x4c>
    *pf = f;
    800050cc:	e09c                	sd	a5,0(s1)
}
    800050ce:	70a2                	ld	ra,40(sp)
    800050d0:	7402                	ld	s0,32(sp)
    800050d2:	64e2                	ld	s1,24(sp)
    800050d4:	6942                	ld	s2,16(sp)
    800050d6:	6145                	addi	sp,sp,48
    800050d8:	8082                	ret
    return -1;
    800050da:	557d                	li	a0,-1
    800050dc:	bfcd                	j	800050ce <argfd+0x4c>
    800050de:	557d                	li	a0,-1
    800050e0:	b7fd                	j	800050ce <argfd+0x4c>

00000000800050e2 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050e2:	1101                	addi	sp,sp,-32
    800050e4:	ec06                	sd	ra,24(sp)
    800050e6:	e822                	sd	s0,16(sp)
    800050e8:	e426                	sd	s1,8(sp)
    800050ea:	1000                	addi	s0,sp,32
    800050ec:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050ee:	ffffd097          	auipc	ra,0xffffd
    800050f2:	8d8080e7          	jalr	-1832(ra) # 800019c6 <myproc>
    800050f6:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050f8:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffdc9a0>
    800050fc:	4501                	li	a0,0
    800050fe:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005100:	6398                	ld	a4,0(a5)
    80005102:	cb19                	beqz	a4,80005118 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005104:	2505                	addiw	a0,a0,1
    80005106:	07a1                	addi	a5,a5,8
    80005108:	fed51ce3          	bne	a0,a3,80005100 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000510c:	557d                	li	a0,-1
}
    8000510e:	60e2                	ld	ra,24(sp)
    80005110:	6442                	ld	s0,16(sp)
    80005112:	64a2                	ld	s1,8(sp)
    80005114:	6105                	addi	sp,sp,32
    80005116:	8082                	ret
      p->ofile[fd] = f;
    80005118:	01a50793          	addi	a5,a0,26
    8000511c:	078e                	slli	a5,a5,0x3
    8000511e:	963e                	add	a2,a2,a5
    80005120:	e204                	sd	s1,0(a2)
      return fd;
    80005122:	b7f5                	j	8000510e <fdalloc+0x2c>

0000000080005124 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005124:	715d                	addi	sp,sp,-80
    80005126:	e486                	sd	ra,72(sp)
    80005128:	e0a2                	sd	s0,64(sp)
    8000512a:	fc26                	sd	s1,56(sp)
    8000512c:	f84a                	sd	s2,48(sp)
    8000512e:	f44e                	sd	s3,40(sp)
    80005130:	f052                	sd	s4,32(sp)
    80005132:	ec56                	sd	s5,24(sp)
    80005134:	e85a                	sd	s6,16(sp)
    80005136:	0880                	addi	s0,sp,80
    80005138:	8b2e                	mv	s6,a1
    8000513a:	89b2                	mv	s3,a2
    8000513c:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000513e:	fb040593          	addi	a1,s0,-80
    80005142:	fffff097          	auipc	ra,0xfffff
    80005146:	e4e080e7          	jalr	-434(ra) # 80003f90 <nameiparent>
    8000514a:	84aa                	mv	s1,a0
    8000514c:	16050063          	beqz	a0,800052ac <create+0x188>
    return 0;

  ilock(dp);
    80005150:	ffffe097          	auipc	ra,0xffffe
    80005154:	67c080e7          	jalr	1660(ra) # 800037cc <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005158:	4601                	li	a2,0
    8000515a:	fb040593          	addi	a1,s0,-80
    8000515e:	8526                	mv	a0,s1
    80005160:	fffff097          	auipc	ra,0xfffff
    80005164:	b50080e7          	jalr	-1200(ra) # 80003cb0 <dirlookup>
    80005168:	8aaa                	mv	s5,a0
    8000516a:	c931                	beqz	a0,800051be <create+0x9a>
    iunlockput(dp);
    8000516c:	8526                	mv	a0,s1
    8000516e:	fffff097          	auipc	ra,0xfffff
    80005172:	8c0080e7          	jalr	-1856(ra) # 80003a2e <iunlockput>
    ilock(ip);
    80005176:	8556                	mv	a0,s5
    80005178:	ffffe097          	auipc	ra,0xffffe
    8000517c:	654080e7          	jalr	1620(ra) # 800037cc <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005180:	000b059b          	sext.w	a1,s6
    80005184:	4789                	li	a5,2
    80005186:	02f59563          	bne	a1,a5,800051b0 <create+0x8c>
    8000518a:	044ad783          	lhu	a5,68(s5)
    8000518e:	37f9                	addiw	a5,a5,-2
    80005190:	17c2                	slli	a5,a5,0x30
    80005192:	93c1                	srli	a5,a5,0x30
    80005194:	4705                	li	a4,1
    80005196:	00f76d63          	bltu	a4,a5,800051b0 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000519a:	8556                	mv	a0,s5
    8000519c:	60a6                	ld	ra,72(sp)
    8000519e:	6406                	ld	s0,64(sp)
    800051a0:	74e2                	ld	s1,56(sp)
    800051a2:	7942                	ld	s2,48(sp)
    800051a4:	79a2                	ld	s3,40(sp)
    800051a6:	7a02                	ld	s4,32(sp)
    800051a8:	6ae2                	ld	s5,24(sp)
    800051aa:	6b42                	ld	s6,16(sp)
    800051ac:	6161                	addi	sp,sp,80
    800051ae:	8082                	ret
    iunlockput(ip);
    800051b0:	8556                	mv	a0,s5
    800051b2:	fffff097          	auipc	ra,0xfffff
    800051b6:	87c080e7          	jalr	-1924(ra) # 80003a2e <iunlockput>
    return 0;
    800051ba:	4a81                	li	s5,0
    800051bc:	bff9                	j	8000519a <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800051be:	85da                	mv	a1,s6
    800051c0:	4088                	lw	a0,0(s1)
    800051c2:	ffffe097          	auipc	ra,0xffffe
    800051c6:	46e080e7          	jalr	1134(ra) # 80003630 <ialloc>
    800051ca:	8a2a                	mv	s4,a0
    800051cc:	c921                	beqz	a0,8000521c <create+0xf8>
  ilock(ip);
    800051ce:	ffffe097          	auipc	ra,0xffffe
    800051d2:	5fe080e7          	jalr	1534(ra) # 800037cc <ilock>
  ip->major = major;
    800051d6:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800051da:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800051de:	4785                	li	a5,1
    800051e0:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    800051e4:	8552                	mv	a0,s4
    800051e6:	ffffe097          	auipc	ra,0xffffe
    800051ea:	51c080e7          	jalr	1308(ra) # 80003702 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051ee:	000b059b          	sext.w	a1,s6
    800051f2:	4785                	li	a5,1
    800051f4:	02f58b63          	beq	a1,a5,8000522a <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    800051f8:	004a2603          	lw	a2,4(s4)
    800051fc:	fb040593          	addi	a1,s0,-80
    80005200:	8526                	mv	a0,s1
    80005202:	fffff097          	auipc	ra,0xfffff
    80005206:	cbe080e7          	jalr	-834(ra) # 80003ec0 <dirlink>
    8000520a:	06054f63          	bltz	a0,80005288 <create+0x164>
  iunlockput(dp);
    8000520e:	8526                	mv	a0,s1
    80005210:	fffff097          	auipc	ra,0xfffff
    80005214:	81e080e7          	jalr	-2018(ra) # 80003a2e <iunlockput>
  return ip;
    80005218:	8ad2                	mv	s5,s4
    8000521a:	b741                	j	8000519a <create+0x76>
    iunlockput(dp);
    8000521c:	8526                	mv	a0,s1
    8000521e:	fffff097          	auipc	ra,0xfffff
    80005222:	810080e7          	jalr	-2032(ra) # 80003a2e <iunlockput>
    return 0;
    80005226:	8ad2                	mv	s5,s4
    80005228:	bf8d                	j	8000519a <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000522a:	004a2603          	lw	a2,4(s4)
    8000522e:	00003597          	auipc	a1,0x3
    80005232:	5ba58593          	addi	a1,a1,1466 # 800087e8 <syscalls+0x2b8>
    80005236:	8552                	mv	a0,s4
    80005238:	fffff097          	auipc	ra,0xfffff
    8000523c:	c88080e7          	jalr	-888(ra) # 80003ec0 <dirlink>
    80005240:	04054463          	bltz	a0,80005288 <create+0x164>
    80005244:	40d0                	lw	a2,4(s1)
    80005246:	00003597          	auipc	a1,0x3
    8000524a:	5aa58593          	addi	a1,a1,1450 # 800087f0 <syscalls+0x2c0>
    8000524e:	8552                	mv	a0,s4
    80005250:	fffff097          	auipc	ra,0xfffff
    80005254:	c70080e7          	jalr	-912(ra) # 80003ec0 <dirlink>
    80005258:	02054863          	bltz	a0,80005288 <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    8000525c:	004a2603          	lw	a2,4(s4)
    80005260:	fb040593          	addi	a1,s0,-80
    80005264:	8526                	mv	a0,s1
    80005266:	fffff097          	auipc	ra,0xfffff
    8000526a:	c5a080e7          	jalr	-934(ra) # 80003ec0 <dirlink>
    8000526e:	00054d63          	bltz	a0,80005288 <create+0x164>
    dp->nlink++;  // for ".."
    80005272:	04a4d783          	lhu	a5,74(s1)
    80005276:	2785                	addiw	a5,a5,1
    80005278:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000527c:	8526                	mv	a0,s1
    8000527e:	ffffe097          	auipc	ra,0xffffe
    80005282:	484080e7          	jalr	1156(ra) # 80003702 <iupdate>
    80005286:	b761                	j	8000520e <create+0xea>
  ip->nlink = 0;
    80005288:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000528c:	8552                	mv	a0,s4
    8000528e:	ffffe097          	auipc	ra,0xffffe
    80005292:	474080e7          	jalr	1140(ra) # 80003702 <iupdate>
  iunlockput(ip);
    80005296:	8552                	mv	a0,s4
    80005298:	ffffe097          	auipc	ra,0xffffe
    8000529c:	796080e7          	jalr	1942(ra) # 80003a2e <iunlockput>
  iunlockput(dp);
    800052a0:	8526                	mv	a0,s1
    800052a2:	ffffe097          	auipc	ra,0xffffe
    800052a6:	78c080e7          	jalr	1932(ra) # 80003a2e <iunlockput>
  return 0;
    800052aa:	bdc5                	j	8000519a <create+0x76>
    return 0;
    800052ac:	8aaa                	mv	s5,a0
    800052ae:	b5f5                	j	8000519a <create+0x76>

00000000800052b0 <sys_dup>:
{
    800052b0:	7179                	addi	sp,sp,-48
    800052b2:	f406                	sd	ra,40(sp)
    800052b4:	f022                	sd	s0,32(sp)
    800052b6:	ec26                	sd	s1,24(sp)
    800052b8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052ba:	fd840613          	addi	a2,s0,-40
    800052be:	4581                	li	a1,0
    800052c0:	4501                	li	a0,0
    800052c2:	00000097          	auipc	ra,0x0
    800052c6:	dc0080e7          	jalr	-576(ra) # 80005082 <argfd>
    return -1;
    800052ca:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052cc:	02054363          	bltz	a0,800052f2 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800052d0:	fd843503          	ld	a0,-40(s0)
    800052d4:	00000097          	auipc	ra,0x0
    800052d8:	e0e080e7          	jalr	-498(ra) # 800050e2 <fdalloc>
    800052dc:	84aa                	mv	s1,a0
    return -1;
    800052de:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052e0:	00054963          	bltz	a0,800052f2 <sys_dup+0x42>
  filedup(f);
    800052e4:	fd843503          	ld	a0,-40(s0)
    800052e8:	fffff097          	auipc	ra,0xfffff
    800052ec:	320080e7          	jalr	800(ra) # 80004608 <filedup>
  return fd;
    800052f0:	87a6                	mv	a5,s1
}
    800052f2:	853e                	mv	a0,a5
    800052f4:	70a2                	ld	ra,40(sp)
    800052f6:	7402                	ld	s0,32(sp)
    800052f8:	64e2                	ld	s1,24(sp)
    800052fa:	6145                	addi	sp,sp,48
    800052fc:	8082                	ret

00000000800052fe <sys_read>:
{
    800052fe:	7179                	addi	sp,sp,-48
    80005300:	f406                	sd	ra,40(sp)
    80005302:	f022                	sd	s0,32(sp)
    80005304:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005306:	fd840593          	addi	a1,s0,-40
    8000530a:	4505                	li	a0,1
    8000530c:	ffffe097          	auipc	ra,0xffffe
    80005310:	874080e7          	jalr	-1932(ra) # 80002b80 <argaddr>
  argint(2, &n);
    80005314:	fe440593          	addi	a1,s0,-28
    80005318:	4509                	li	a0,2
    8000531a:	ffffe097          	auipc	ra,0xffffe
    8000531e:	846080e7          	jalr	-1978(ra) # 80002b60 <argint>
  if(argfd(0, 0, &f) < 0)
    80005322:	fe840613          	addi	a2,s0,-24
    80005326:	4581                	li	a1,0
    80005328:	4501                	li	a0,0
    8000532a:	00000097          	auipc	ra,0x0
    8000532e:	d58080e7          	jalr	-680(ra) # 80005082 <argfd>
    80005332:	87aa                	mv	a5,a0
    return -1;
    80005334:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005336:	0007cc63          	bltz	a5,8000534e <sys_read+0x50>
  return fileread(f, p, n);
    8000533a:	fe442603          	lw	a2,-28(s0)
    8000533e:	fd843583          	ld	a1,-40(s0)
    80005342:	fe843503          	ld	a0,-24(s0)
    80005346:	fffff097          	auipc	ra,0xfffff
    8000534a:	44e080e7          	jalr	1102(ra) # 80004794 <fileread>
}
    8000534e:	70a2                	ld	ra,40(sp)
    80005350:	7402                	ld	s0,32(sp)
    80005352:	6145                	addi	sp,sp,48
    80005354:	8082                	ret

0000000080005356 <sys_write>:
{
    80005356:	7179                	addi	sp,sp,-48
    80005358:	f406                	sd	ra,40(sp)
    8000535a:	f022                	sd	s0,32(sp)
    8000535c:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000535e:	fd840593          	addi	a1,s0,-40
    80005362:	4505                	li	a0,1
    80005364:	ffffe097          	auipc	ra,0xffffe
    80005368:	81c080e7          	jalr	-2020(ra) # 80002b80 <argaddr>
  argint(2, &n);
    8000536c:	fe440593          	addi	a1,s0,-28
    80005370:	4509                	li	a0,2
    80005372:	ffffd097          	auipc	ra,0xffffd
    80005376:	7ee080e7          	jalr	2030(ra) # 80002b60 <argint>
  if(argfd(0, 0, &f) < 0)
    8000537a:	fe840613          	addi	a2,s0,-24
    8000537e:	4581                	li	a1,0
    80005380:	4501                	li	a0,0
    80005382:	00000097          	auipc	ra,0x0
    80005386:	d00080e7          	jalr	-768(ra) # 80005082 <argfd>
    8000538a:	87aa                	mv	a5,a0
    return -1;
    8000538c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000538e:	0007cc63          	bltz	a5,800053a6 <sys_write+0x50>
  return filewrite(f, p, n);
    80005392:	fe442603          	lw	a2,-28(s0)
    80005396:	fd843583          	ld	a1,-40(s0)
    8000539a:	fe843503          	ld	a0,-24(s0)
    8000539e:	fffff097          	auipc	ra,0xfffff
    800053a2:	4b8080e7          	jalr	1208(ra) # 80004856 <filewrite>
}
    800053a6:	70a2                	ld	ra,40(sp)
    800053a8:	7402                	ld	s0,32(sp)
    800053aa:	6145                	addi	sp,sp,48
    800053ac:	8082                	ret

00000000800053ae <sys_close>:
{
    800053ae:	1101                	addi	sp,sp,-32
    800053b0:	ec06                	sd	ra,24(sp)
    800053b2:	e822                	sd	s0,16(sp)
    800053b4:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053b6:	fe040613          	addi	a2,s0,-32
    800053ba:	fec40593          	addi	a1,s0,-20
    800053be:	4501                	li	a0,0
    800053c0:	00000097          	auipc	ra,0x0
    800053c4:	cc2080e7          	jalr	-830(ra) # 80005082 <argfd>
    return -1;
    800053c8:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053ca:	02054463          	bltz	a0,800053f2 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053ce:	ffffc097          	auipc	ra,0xffffc
    800053d2:	5f8080e7          	jalr	1528(ra) # 800019c6 <myproc>
    800053d6:	fec42783          	lw	a5,-20(s0)
    800053da:	07e9                	addi	a5,a5,26
    800053dc:	078e                	slli	a5,a5,0x3
    800053de:	97aa                	add	a5,a5,a0
    800053e0:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800053e4:	fe043503          	ld	a0,-32(s0)
    800053e8:	fffff097          	auipc	ra,0xfffff
    800053ec:	272080e7          	jalr	626(ra) # 8000465a <fileclose>
  return 0;
    800053f0:	4781                	li	a5,0
}
    800053f2:	853e                	mv	a0,a5
    800053f4:	60e2                	ld	ra,24(sp)
    800053f6:	6442                	ld	s0,16(sp)
    800053f8:	6105                	addi	sp,sp,32
    800053fa:	8082                	ret

00000000800053fc <sys_fstat>:
{
    800053fc:	1101                	addi	sp,sp,-32
    800053fe:	ec06                	sd	ra,24(sp)
    80005400:	e822                	sd	s0,16(sp)
    80005402:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005404:	fe040593          	addi	a1,s0,-32
    80005408:	4505                	li	a0,1
    8000540a:	ffffd097          	auipc	ra,0xffffd
    8000540e:	776080e7          	jalr	1910(ra) # 80002b80 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005412:	fe840613          	addi	a2,s0,-24
    80005416:	4581                	li	a1,0
    80005418:	4501                	li	a0,0
    8000541a:	00000097          	auipc	ra,0x0
    8000541e:	c68080e7          	jalr	-920(ra) # 80005082 <argfd>
    80005422:	87aa                	mv	a5,a0
    return -1;
    80005424:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005426:	0007ca63          	bltz	a5,8000543a <sys_fstat+0x3e>
  return filestat(f, st);
    8000542a:	fe043583          	ld	a1,-32(s0)
    8000542e:	fe843503          	ld	a0,-24(s0)
    80005432:	fffff097          	auipc	ra,0xfffff
    80005436:	2f0080e7          	jalr	752(ra) # 80004722 <filestat>
}
    8000543a:	60e2                	ld	ra,24(sp)
    8000543c:	6442                	ld	s0,16(sp)
    8000543e:	6105                	addi	sp,sp,32
    80005440:	8082                	ret

0000000080005442 <sys_link>:
{
    80005442:	7169                	addi	sp,sp,-304
    80005444:	f606                	sd	ra,296(sp)
    80005446:	f222                	sd	s0,288(sp)
    80005448:	ee26                	sd	s1,280(sp)
    8000544a:	ea4a                	sd	s2,272(sp)
    8000544c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000544e:	08000613          	li	a2,128
    80005452:	ed040593          	addi	a1,s0,-304
    80005456:	4501                	li	a0,0
    80005458:	ffffd097          	auipc	ra,0xffffd
    8000545c:	748080e7          	jalr	1864(ra) # 80002ba0 <argstr>
    return -1;
    80005460:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005462:	10054e63          	bltz	a0,8000557e <sys_link+0x13c>
    80005466:	08000613          	li	a2,128
    8000546a:	f5040593          	addi	a1,s0,-176
    8000546e:	4505                	li	a0,1
    80005470:	ffffd097          	auipc	ra,0xffffd
    80005474:	730080e7          	jalr	1840(ra) # 80002ba0 <argstr>
    return -1;
    80005478:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000547a:	10054263          	bltz	a0,8000557e <sys_link+0x13c>
  begin_op();
    8000547e:	fffff097          	auipc	ra,0xfffff
    80005482:	d10080e7          	jalr	-752(ra) # 8000418e <begin_op>
  if((ip = namei(old)) == 0){
    80005486:	ed040513          	addi	a0,s0,-304
    8000548a:	fffff097          	auipc	ra,0xfffff
    8000548e:	ae8080e7          	jalr	-1304(ra) # 80003f72 <namei>
    80005492:	84aa                	mv	s1,a0
    80005494:	c551                	beqz	a0,80005520 <sys_link+0xde>
  ilock(ip);
    80005496:	ffffe097          	auipc	ra,0xffffe
    8000549a:	336080e7          	jalr	822(ra) # 800037cc <ilock>
  if(ip->type == T_DIR){
    8000549e:	04449703          	lh	a4,68(s1)
    800054a2:	4785                	li	a5,1
    800054a4:	08f70463          	beq	a4,a5,8000552c <sys_link+0xea>
  ip->nlink++;
    800054a8:	04a4d783          	lhu	a5,74(s1)
    800054ac:	2785                	addiw	a5,a5,1
    800054ae:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054b2:	8526                	mv	a0,s1
    800054b4:	ffffe097          	auipc	ra,0xffffe
    800054b8:	24e080e7          	jalr	590(ra) # 80003702 <iupdate>
  iunlock(ip);
    800054bc:	8526                	mv	a0,s1
    800054be:	ffffe097          	auipc	ra,0xffffe
    800054c2:	3d0080e7          	jalr	976(ra) # 8000388e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054c6:	fd040593          	addi	a1,s0,-48
    800054ca:	f5040513          	addi	a0,s0,-176
    800054ce:	fffff097          	auipc	ra,0xfffff
    800054d2:	ac2080e7          	jalr	-1342(ra) # 80003f90 <nameiparent>
    800054d6:	892a                	mv	s2,a0
    800054d8:	c935                	beqz	a0,8000554c <sys_link+0x10a>
  ilock(dp);
    800054da:	ffffe097          	auipc	ra,0xffffe
    800054de:	2f2080e7          	jalr	754(ra) # 800037cc <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054e2:	00092703          	lw	a4,0(s2)
    800054e6:	409c                	lw	a5,0(s1)
    800054e8:	04f71d63          	bne	a4,a5,80005542 <sys_link+0x100>
    800054ec:	40d0                	lw	a2,4(s1)
    800054ee:	fd040593          	addi	a1,s0,-48
    800054f2:	854a                	mv	a0,s2
    800054f4:	fffff097          	auipc	ra,0xfffff
    800054f8:	9cc080e7          	jalr	-1588(ra) # 80003ec0 <dirlink>
    800054fc:	04054363          	bltz	a0,80005542 <sys_link+0x100>
  iunlockput(dp);
    80005500:	854a                	mv	a0,s2
    80005502:	ffffe097          	auipc	ra,0xffffe
    80005506:	52c080e7          	jalr	1324(ra) # 80003a2e <iunlockput>
  iput(ip);
    8000550a:	8526                	mv	a0,s1
    8000550c:	ffffe097          	auipc	ra,0xffffe
    80005510:	47a080e7          	jalr	1146(ra) # 80003986 <iput>
  end_op();
    80005514:	fffff097          	auipc	ra,0xfffff
    80005518:	cfa080e7          	jalr	-774(ra) # 8000420e <end_op>
  return 0;
    8000551c:	4781                	li	a5,0
    8000551e:	a085                	j	8000557e <sys_link+0x13c>
    end_op();
    80005520:	fffff097          	auipc	ra,0xfffff
    80005524:	cee080e7          	jalr	-786(ra) # 8000420e <end_op>
    return -1;
    80005528:	57fd                	li	a5,-1
    8000552a:	a891                	j	8000557e <sys_link+0x13c>
    iunlockput(ip);
    8000552c:	8526                	mv	a0,s1
    8000552e:	ffffe097          	auipc	ra,0xffffe
    80005532:	500080e7          	jalr	1280(ra) # 80003a2e <iunlockput>
    end_op();
    80005536:	fffff097          	auipc	ra,0xfffff
    8000553a:	cd8080e7          	jalr	-808(ra) # 8000420e <end_op>
    return -1;
    8000553e:	57fd                	li	a5,-1
    80005540:	a83d                	j	8000557e <sys_link+0x13c>
    iunlockput(dp);
    80005542:	854a                	mv	a0,s2
    80005544:	ffffe097          	auipc	ra,0xffffe
    80005548:	4ea080e7          	jalr	1258(ra) # 80003a2e <iunlockput>
  ilock(ip);
    8000554c:	8526                	mv	a0,s1
    8000554e:	ffffe097          	auipc	ra,0xffffe
    80005552:	27e080e7          	jalr	638(ra) # 800037cc <ilock>
  ip->nlink--;
    80005556:	04a4d783          	lhu	a5,74(s1)
    8000555a:	37fd                	addiw	a5,a5,-1
    8000555c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005560:	8526                	mv	a0,s1
    80005562:	ffffe097          	auipc	ra,0xffffe
    80005566:	1a0080e7          	jalr	416(ra) # 80003702 <iupdate>
  iunlockput(ip);
    8000556a:	8526                	mv	a0,s1
    8000556c:	ffffe097          	auipc	ra,0xffffe
    80005570:	4c2080e7          	jalr	1218(ra) # 80003a2e <iunlockput>
  end_op();
    80005574:	fffff097          	auipc	ra,0xfffff
    80005578:	c9a080e7          	jalr	-870(ra) # 8000420e <end_op>
  return -1;
    8000557c:	57fd                	li	a5,-1
}
    8000557e:	853e                	mv	a0,a5
    80005580:	70b2                	ld	ra,296(sp)
    80005582:	7412                	ld	s0,288(sp)
    80005584:	64f2                	ld	s1,280(sp)
    80005586:	6952                	ld	s2,272(sp)
    80005588:	6155                	addi	sp,sp,304
    8000558a:	8082                	ret

000000008000558c <sys_unlink>:
{
    8000558c:	7151                	addi	sp,sp,-240
    8000558e:	f586                	sd	ra,232(sp)
    80005590:	f1a2                	sd	s0,224(sp)
    80005592:	eda6                	sd	s1,216(sp)
    80005594:	e9ca                	sd	s2,208(sp)
    80005596:	e5ce                	sd	s3,200(sp)
    80005598:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000559a:	08000613          	li	a2,128
    8000559e:	f3040593          	addi	a1,s0,-208
    800055a2:	4501                	li	a0,0
    800055a4:	ffffd097          	auipc	ra,0xffffd
    800055a8:	5fc080e7          	jalr	1532(ra) # 80002ba0 <argstr>
    800055ac:	18054163          	bltz	a0,8000572e <sys_unlink+0x1a2>
  begin_op();
    800055b0:	fffff097          	auipc	ra,0xfffff
    800055b4:	bde080e7          	jalr	-1058(ra) # 8000418e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055b8:	fb040593          	addi	a1,s0,-80
    800055bc:	f3040513          	addi	a0,s0,-208
    800055c0:	fffff097          	auipc	ra,0xfffff
    800055c4:	9d0080e7          	jalr	-1584(ra) # 80003f90 <nameiparent>
    800055c8:	84aa                	mv	s1,a0
    800055ca:	c979                	beqz	a0,800056a0 <sys_unlink+0x114>
  ilock(dp);
    800055cc:	ffffe097          	auipc	ra,0xffffe
    800055d0:	200080e7          	jalr	512(ra) # 800037cc <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055d4:	00003597          	auipc	a1,0x3
    800055d8:	21458593          	addi	a1,a1,532 # 800087e8 <syscalls+0x2b8>
    800055dc:	fb040513          	addi	a0,s0,-80
    800055e0:	ffffe097          	auipc	ra,0xffffe
    800055e4:	6b6080e7          	jalr	1718(ra) # 80003c96 <namecmp>
    800055e8:	14050a63          	beqz	a0,8000573c <sys_unlink+0x1b0>
    800055ec:	00003597          	auipc	a1,0x3
    800055f0:	20458593          	addi	a1,a1,516 # 800087f0 <syscalls+0x2c0>
    800055f4:	fb040513          	addi	a0,s0,-80
    800055f8:	ffffe097          	auipc	ra,0xffffe
    800055fc:	69e080e7          	jalr	1694(ra) # 80003c96 <namecmp>
    80005600:	12050e63          	beqz	a0,8000573c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005604:	f2c40613          	addi	a2,s0,-212
    80005608:	fb040593          	addi	a1,s0,-80
    8000560c:	8526                	mv	a0,s1
    8000560e:	ffffe097          	auipc	ra,0xffffe
    80005612:	6a2080e7          	jalr	1698(ra) # 80003cb0 <dirlookup>
    80005616:	892a                	mv	s2,a0
    80005618:	12050263          	beqz	a0,8000573c <sys_unlink+0x1b0>
  ilock(ip);
    8000561c:	ffffe097          	auipc	ra,0xffffe
    80005620:	1b0080e7          	jalr	432(ra) # 800037cc <ilock>
  if(ip->nlink < 1)
    80005624:	04a91783          	lh	a5,74(s2)
    80005628:	08f05263          	blez	a5,800056ac <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000562c:	04491703          	lh	a4,68(s2)
    80005630:	4785                	li	a5,1
    80005632:	08f70563          	beq	a4,a5,800056bc <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005636:	4641                	li	a2,16
    80005638:	4581                	li	a1,0
    8000563a:	fc040513          	addi	a0,s0,-64
    8000563e:	ffffb097          	auipc	ra,0xffffb
    80005642:	6a8080e7          	jalr	1704(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005646:	4741                	li	a4,16
    80005648:	f2c42683          	lw	a3,-212(s0)
    8000564c:	fc040613          	addi	a2,s0,-64
    80005650:	4581                	li	a1,0
    80005652:	8526                	mv	a0,s1
    80005654:	ffffe097          	auipc	ra,0xffffe
    80005658:	524080e7          	jalr	1316(ra) # 80003b78 <writei>
    8000565c:	47c1                	li	a5,16
    8000565e:	0af51563          	bne	a0,a5,80005708 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005662:	04491703          	lh	a4,68(s2)
    80005666:	4785                	li	a5,1
    80005668:	0af70863          	beq	a4,a5,80005718 <sys_unlink+0x18c>
  iunlockput(dp);
    8000566c:	8526                	mv	a0,s1
    8000566e:	ffffe097          	auipc	ra,0xffffe
    80005672:	3c0080e7          	jalr	960(ra) # 80003a2e <iunlockput>
  ip->nlink--;
    80005676:	04a95783          	lhu	a5,74(s2)
    8000567a:	37fd                	addiw	a5,a5,-1
    8000567c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005680:	854a                	mv	a0,s2
    80005682:	ffffe097          	auipc	ra,0xffffe
    80005686:	080080e7          	jalr	128(ra) # 80003702 <iupdate>
  iunlockput(ip);
    8000568a:	854a                	mv	a0,s2
    8000568c:	ffffe097          	auipc	ra,0xffffe
    80005690:	3a2080e7          	jalr	930(ra) # 80003a2e <iunlockput>
  end_op();
    80005694:	fffff097          	auipc	ra,0xfffff
    80005698:	b7a080e7          	jalr	-1158(ra) # 8000420e <end_op>
  return 0;
    8000569c:	4501                	li	a0,0
    8000569e:	a84d                	j	80005750 <sys_unlink+0x1c4>
    end_op();
    800056a0:	fffff097          	auipc	ra,0xfffff
    800056a4:	b6e080e7          	jalr	-1170(ra) # 8000420e <end_op>
    return -1;
    800056a8:	557d                	li	a0,-1
    800056aa:	a05d                	j	80005750 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056ac:	00003517          	auipc	a0,0x3
    800056b0:	14c50513          	addi	a0,a0,332 # 800087f8 <syscalls+0x2c8>
    800056b4:	ffffb097          	auipc	ra,0xffffb
    800056b8:	e90080e7          	jalr	-368(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056bc:	04c92703          	lw	a4,76(s2)
    800056c0:	02000793          	li	a5,32
    800056c4:	f6e7f9e3          	bgeu	a5,a4,80005636 <sys_unlink+0xaa>
    800056c8:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056cc:	4741                	li	a4,16
    800056ce:	86ce                	mv	a3,s3
    800056d0:	f1840613          	addi	a2,s0,-232
    800056d4:	4581                	li	a1,0
    800056d6:	854a                	mv	a0,s2
    800056d8:	ffffe097          	auipc	ra,0xffffe
    800056dc:	3a8080e7          	jalr	936(ra) # 80003a80 <readi>
    800056e0:	47c1                	li	a5,16
    800056e2:	00f51b63          	bne	a0,a5,800056f8 <sys_unlink+0x16c>
    if(de.inum != 0)
    800056e6:	f1845783          	lhu	a5,-232(s0)
    800056ea:	e7a1                	bnez	a5,80005732 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056ec:	29c1                	addiw	s3,s3,16
    800056ee:	04c92783          	lw	a5,76(s2)
    800056f2:	fcf9ede3          	bltu	s3,a5,800056cc <sys_unlink+0x140>
    800056f6:	b781                	j	80005636 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056f8:	00003517          	auipc	a0,0x3
    800056fc:	11850513          	addi	a0,a0,280 # 80008810 <syscalls+0x2e0>
    80005700:	ffffb097          	auipc	ra,0xffffb
    80005704:	e44080e7          	jalr	-444(ra) # 80000544 <panic>
    panic("unlink: writei");
    80005708:	00003517          	auipc	a0,0x3
    8000570c:	12050513          	addi	a0,a0,288 # 80008828 <syscalls+0x2f8>
    80005710:	ffffb097          	auipc	ra,0xffffb
    80005714:	e34080e7          	jalr	-460(ra) # 80000544 <panic>
    dp->nlink--;
    80005718:	04a4d783          	lhu	a5,74(s1)
    8000571c:	37fd                	addiw	a5,a5,-1
    8000571e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005722:	8526                	mv	a0,s1
    80005724:	ffffe097          	auipc	ra,0xffffe
    80005728:	fde080e7          	jalr	-34(ra) # 80003702 <iupdate>
    8000572c:	b781                	j	8000566c <sys_unlink+0xe0>
    return -1;
    8000572e:	557d                	li	a0,-1
    80005730:	a005                	j	80005750 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005732:	854a                	mv	a0,s2
    80005734:	ffffe097          	auipc	ra,0xffffe
    80005738:	2fa080e7          	jalr	762(ra) # 80003a2e <iunlockput>
  iunlockput(dp);
    8000573c:	8526                	mv	a0,s1
    8000573e:	ffffe097          	auipc	ra,0xffffe
    80005742:	2f0080e7          	jalr	752(ra) # 80003a2e <iunlockput>
  end_op();
    80005746:	fffff097          	auipc	ra,0xfffff
    8000574a:	ac8080e7          	jalr	-1336(ra) # 8000420e <end_op>
  return -1;
    8000574e:	557d                	li	a0,-1
}
    80005750:	70ae                	ld	ra,232(sp)
    80005752:	740e                	ld	s0,224(sp)
    80005754:	64ee                	ld	s1,216(sp)
    80005756:	694e                	ld	s2,208(sp)
    80005758:	69ae                	ld	s3,200(sp)
    8000575a:	616d                	addi	sp,sp,240
    8000575c:	8082                	ret

000000008000575e <sys_open>:

uint64
sys_open(void)
{
    8000575e:	7131                	addi	sp,sp,-192
    80005760:	fd06                	sd	ra,184(sp)
    80005762:	f922                	sd	s0,176(sp)
    80005764:	f526                	sd	s1,168(sp)
    80005766:	f14a                	sd	s2,160(sp)
    80005768:	ed4e                	sd	s3,152(sp)
    8000576a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000576c:	f4c40593          	addi	a1,s0,-180
    80005770:	4505                	li	a0,1
    80005772:	ffffd097          	auipc	ra,0xffffd
    80005776:	3ee080e7          	jalr	1006(ra) # 80002b60 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000577a:	08000613          	li	a2,128
    8000577e:	f5040593          	addi	a1,s0,-176
    80005782:	4501                	li	a0,0
    80005784:	ffffd097          	auipc	ra,0xffffd
    80005788:	41c080e7          	jalr	1052(ra) # 80002ba0 <argstr>
    8000578c:	87aa                	mv	a5,a0
    return -1;
    8000578e:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005790:	0a07c963          	bltz	a5,80005842 <sys_open+0xe4>

  begin_op();
    80005794:	fffff097          	auipc	ra,0xfffff
    80005798:	9fa080e7          	jalr	-1542(ra) # 8000418e <begin_op>

  if(omode & O_CREATE){
    8000579c:	f4c42783          	lw	a5,-180(s0)
    800057a0:	2007f793          	andi	a5,a5,512
    800057a4:	cfc5                	beqz	a5,8000585c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800057a6:	4681                	li	a3,0
    800057a8:	4601                	li	a2,0
    800057aa:	4589                	li	a1,2
    800057ac:	f5040513          	addi	a0,s0,-176
    800057b0:	00000097          	auipc	ra,0x0
    800057b4:	974080e7          	jalr	-1676(ra) # 80005124 <create>
    800057b8:	84aa                	mv	s1,a0
    if(ip == 0){
    800057ba:	c959                	beqz	a0,80005850 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057bc:	04449703          	lh	a4,68(s1)
    800057c0:	478d                	li	a5,3
    800057c2:	00f71763          	bne	a4,a5,800057d0 <sys_open+0x72>
    800057c6:	0464d703          	lhu	a4,70(s1)
    800057ca:	47a5                	li	a5,9
    800057cc:	0ce7ed63          	bltu	a5,a4,800058a6 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057d0:	fffff097          	auipc	ra,0xfffff
    800057d4:	dce080e7          	jalr	-562(ra) # 8000459e <filealloc>
    800057d8:	89aa                	mv	s3,a0
    800057da:	10050363          	beqz	a0,800058e0 <sys_open+0x182>
    800057de:	00000097          	auipc	ra,0x0
    800057e2:	904080e7          	jalr	-1788(ra) # 800050e2 <fdalloc>
    800057e6:	892a                	mv	s2,a0
    800057e8:	0e054763          	bltz	a0,800058d6 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057ec:	04449703          	lh	a4,68(s1)
    800057f0:	478d                	li	a5,3
    800057f2:	0cf70563          	beq	a4,a5,800058bc <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057f6:	4789                	li	a5,2
    800057f8:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057fc:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005800:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005804:	f4c42783          	lw	a5,-180(s0)
    80005808:	0017c713          	xori	a4,a5,1
    8000580c:	8b05                	andi	a4,a4,1
    8000580e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005812:	0037f713          	andi	a4,a5,3
    80005816:	00e03733          	snez	a4,a4
    8000581a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000581e:	4007f793          	andi	a5,a5,1024
    80005822:	c791                	beqz	a5,8000582e <sys_open+0xd0>
    80005824:	04449703          	lh	a4,68(s1)
    80005828:	4789                	li	a5,2
    8000582a:	0af70063          	beq	a4,a5,800058ca <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000582e:	8526                	mv	a0,s1
    80005830:	ffffe097          	auipc	ra,0xffffe
    80005834:	05e080e7          	jalr	94(ra) # 8000388e <iunlock>
  end_op();
    80005838:	fffff097          	auipc	ra,0xfffff
    8000583c:	9d6080e7          	jalr	-1578(ra) # 8000420e <end_op>

  return fd;
    80005840:	854a                	mv	a0,s2
}
    80005842:	70ea                	ld	ra,184(sp)
    80005844:	744a                	ld	s0,176(sp)
    80005846:	74aa                	ld	s1,168(sp)
    80005848:	790a                	ld	s2,160(sp)
    8000584a:	69ea                	ld	s3,152(sp)
    8000584c:	6129                	addi	sp,sp,192
    8000584e:	8082                	ret
      end_op();
    80005850:	fffff097          	auipc	ra,0xfffff
    80005854:	9be080e7          	jalr	-1602(ra) # 8000420e <end_op>
      return -1;
    80005858:	557d                	li	a0,-1
    8000585a:	b7e5                	j	80005842 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000585c:	f5040513          	addi	a0,s0,-176
    80005860:	ffffe097          	auipc	ra,0xffffe
    80005864:	712080e7          	jalr	1810(ra) # 80003f72 <namei>
    80005868:	84aa                	mv	s1,a0
    8000586a:	c905                	beqz	a0,8000589a <sys_open+0x13c>
    ilock(ip);
    8000586c:	ffffe097          	auipc	ra,0xffffe
    80005870:	f60080e7          	jalr	-160(ra) # 800037cc <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005874:	04449703          	lh	a4,68(s1)
    80005878:	4785                	li	a5,1
    8000587a:	f4f711e3          	bne	a4,a5,800057bc <sys_open+0x5e>
    8000587e:	f4c42783          	lw	a5,-180(s0)
    80005882:	d7b9                	beqz	a5,800057d0 <sys_open+0x72>
      iunlockput(ip);
    80005884:	8526                	mv	a0,s1
    80005886:	ffffe097          	auipc	ra,0xffffe
    8000588a:	1a8080e7          	jalr	424(ra) # 80003a2e <iunlockput>
      end_op();
    8000588e:	fffff097          	auipc	ra,0xfffff
    80005892:	980080e7          	jalr	-1664(ra) # 8000420e <end_op>
      return -1;
    80005896:	557d                	li	a0,-1
    80005898:	b76d                	j	80005842 <sys_open+0xe4>
      end_op();
    8000589a:	fffff097          	auipc	ra,0xfffff
    8000589e:	974080e7          	jalr	-1676(ra) # 8000420e <end_op>
      return -1;
    800058a2:	557d                	li	a0,-1
    800058a4:	bf79                	j	80005842 <sys_open+0xe4>
    iunlockput(ip);
    800058a6:	8526                	mv	a0,s1
    800058a8:	ffffe097          	auipc	ra,0xffffe
    800058ac:	186080e7          	jalr	390(ra) # 80003a2e <iunlockput>
    end_op();
    800058b0:	fffff097          	auipc	ra,0xfffff
    800058b4:	95e080e7          	jalr	-1698(ra) # 8000420e <end_op>
    return -1;
    800058b8:	557d                	li	a0,-1
    800058ba:	b761                	j	80005842 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800058bc:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058c0:	04649783          	lh	a5,70(s1)
    800058c4:	02f99223          	sh	a5,36(s3)
    800058c8:	bf25                	j	80005800 <sys_open+0xa2>
    itrunc(ip);
    800058ca:	8526                	mv	a0,s1
    800058cc:	ffffe097          	auipc	ra,0xffffe
    800058d0:	00e080e7          	jalr	14(ra) # 800038da <itrunc>
    800058d4:	bfa9                	j	8000582e <sys_open+0xd0>
      fileclose(f);
    800058d6:	854e                	mv	a0,s3
    800058d8:	fffff097          	auipc	ra,0xfffff
    800058dc:	d82080e7          	jalr	-638(ra) # 8000465a <fileclose>
    iunlockput(ip);
    800058e0:	8526                	mv	a0,s1
    800058e2:	ffffe097          	auipc	ra,0xffffe
    800058e6:	14c080e7          	jalr	332(ra) # 80003a2e <iunlockput>
    end_op();
    800058ea:	fffff097          	auipc	ra,0xfffff
    800058ee:	924080e7          	jalr	-1756(ra) # 8000420e <end_op>
    return -1;
    800058f2:	557d                	li	a0,-1
    800058f4:	b7b9                	j	80005842 <sys_open+0xe4>

00000000800058f6 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058f6:	7175                	addi	sp,sp,-144
    800058f8:	e506                	sd	ra,136(sp)
    800058fa:	e122                	sd	s0,128(sp)
    800058fc:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058fe:	fffff097          	auipc	ra,0xfffff
    80005902:	890080e7          	jalr	-1904(ra) # 8000418e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005906:	08000613          	li	a2,128
    8000590a:	f7040593          	addi	a1,s0,-144
    8000590e:	4501                	li	a0,0
    80005910:	ffffd097          	auipc	ra,0xffffd
    80005914:	290080e7          	jalr	656(ra) # 80002ba0 <argstr>
    80005918:	02054963          	bltz	a0,8000594a <sys_mkdir+0x54>
    8000591c:	4681                	li	a3,0
    8000591e:	4601                	li	a2,0
    80005920:	4585                	li	a1,1
    80005922:	f7040513          	addi	a0,s0,-144
    80005926:	fffff097          	auipc	ra,0xfffff
    8000592a:	7fe080e7          	jalr	2046(ra) # 80005124 <create>
    8000592e:	cd11                	beqz	a0,8000594a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005930:	ffffe097          	auipc	ra,0xffffe
    80005934:	0fe080e7          	jalr	254(ra) # 80003a2e <iunlockput>
  end_op();
    80005938:	fffff097          	auipc	ra,0xfffff
    8000593c:	8d6080e7          	jalr	-1834(ra) # 8000420e <end_op>
  return 0;
    80005940:	4501                	li	a0,0
}
    80005942:	60aa                	ld	ra,136(sp)
    80005944:	640a                	ld	s0,128(sp)
    80005946:	6149                	addi	sp,sp,144
    80005948:	8082                	ret
    end_op();
    8000594a:	fffff097          	auipc	ra,0xfffff
    8000594e:	8c4080e7          	jalr	-1852(ra) # 8000420e <end_op>
    return -1;
    80005952:	557d                	li	a0,-1
    80005954:	b7fd                	j	80005942 <sys_mkdir+0x4c>

0000000080005956 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005956:	7135                	addi	sp,sp,-160
    80005958:	ed06                	sd	ra,152(sp)
    8000595a:	e922                	sd	s0,144(sp)
    8000595c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000595e:	fffff097          	auipc	ra,0xfffff
    80005962:	830080e7          	jalr	-2000(ra) # 8000418e <begin_op>
  argint(1, &major);
    80005966:	f6c40593          	addi	a1,s0,-148
    8000596a:	4505                	li	a0,1
    8000596c:	ffffd097          	auipc	ra,0xffffd
    80005970:	1f4080e7          	jalr	500(ra) # 80002b60 <argint>
  argint(2, &minor);
    80005974:	f6840593          	addi	a1,s0,-152
    80005978:	4509                	li	a0,2
    8000597a:	ffffd097          	auipc	ra,0xffffd
    8000597e:	1e6080e7          	jalr	486(ra) # 80002b60 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005982:	08000613          	li	a2,128
    80005986:	f7040593          	addi	a1,s0,-144
    8000598a:	4501                	li	a0,0
    8000598c:	ffffd097          	auipc	ra,0xffffd
    80005990:	214080e7          	jalr	532(ra) # 80002ba0 <argstr>
    80005994:	02054b63          	bltz	a0,800059ca <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005998:	f6841683          	lh	a3,-152(s0)
    8000599c:	f6c41603          	lh	a2,-148(s0)
    800059a0:	458d                	li	a1,3
    800059a2:	f7040513          	addi	a0,s0,-144
    800059a6:	fffff097          	auipc	ra,0xfffff
    800059aa:	77e080e7          	jalr	1918(ra) # 80005124 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059ae:	cd11                	beqz	a0,800059ca <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059b0:	ffffe097          	auipc	ra,0xffffe
    800059b4:	07e080e7          	jalr	126(ra) # 80003a2e <iunlockput>
  end_op();
    800059b8:	fffff097          	auipc	ra,0xfffff
    800059bc:	856080e7          	jalr	-1962(ra) # 8000420e <end_op>
  return 0;
    800059c0:	4501                	li	a0,0
}
    800059c2:	60ea                	ld	ra,152(sp)
    800059c4:	644a                	ld	s0,144(sp)
    800059c6:	610d                	addi	sp,sp,160
    800059c8:	8082                	ret
    end_op();
    800059ca:	fffff097          	auipc	ra,0xfffff
    800059ce:	844080e7          	jalr	-1980(ra) # 8000420e <end_op>
    return -1;
    800059d2:	557d                	li	a0,-1
    800059d4:	b7fd                	j	800059c2 <sys_mknod+0x6c>

00000000800059d6 <sys_chdir>:

uint64
sys_chdir(void)
{
    800059d6:	7135                	addi	sp,sp,-160
    800059d8:	ed06                	sd	ra,152(sp)
    800059da:	e922                	sd	s0,144(sp)
    800059dc:	e526                	sd	s1,136(sp)
    800059de:	e14a                	sd	s2,128(sp)
    800059e0:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059e2:	ffffc097          	auipc	ra,0xffffc
    800059e6:	fe4080e7          	jalr	-28(ra) # 800019c6 <myproc>
    800059ea:	892a                	mv	s2,a0
  
  begin_op();
    800059ec:	ffffe097          	auipc	ra,0xffffe
    800059f0:	7a2080e7          	jalr	1954(ra) # 8000418e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059f4:	08000613          	li	a2,128
    800059f8:	f6040593          	addi	a1,s0,-160
    800059fc:	4501                	li	a0,0
    800059fe:	ffffd097          	auipc	ra,0xffffd
    80005a02:	1a2080e7          	jalr	418(ra) # 80002ba0 <argstr>
    80005a06:	04054b63          	bltz	a0,80005a5c <sys_chdir+0x86>
    80005a0a:	f6040513          	addi	a0,s0,-160
    80005a0e:	ffffe097          	auipc	ra,0xffffe
    80005a12:	564080e7          	jalr	1380(ra) # 80003f72 <namei>
    80005a16:	84aa                	mv	s1,a0
    80005a18:	c131                	beqz	a0,80005a5c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a1a:	ffffe097          	auipc	ra,0xffffe
    80005a1e:	db2080e7          	jalr	-590(ra) # 800037cc <ilock>
  if(ip->type != T_DIR){
    80005a22:	04449703          	lh	a4,68(s1)
    80005a26:	4785                	li	a5,1
    80005a28:	04f71063          	bne	a4,a5,80005a68 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a2c:	8526                	mv	a0,s1
    80005a2e:	ffffe097          	auipc	ra,0xffffe
    80005a32:	e60080e7          	jalr	-416(ra) # 8000388e <iunlock>
  iput(p->cwd);
    80005a36:	15093503          	ld	a0,336(s2)
    80005a3a:	ffffe097          	auipc	ra,0xffffe
    80005a3e:	f4c080e7          	jalr	-180(ra) # 80003986 <iput>
  end_op();
    80005a42:	ffffe097          	auipc	ra,0xffffe
    80005a46:	7cc080e7          	jalr	1996(ra) # 8000420e <end_op>
  p->cwd = ip;
    80005a4a:	14993823          	sd	s1,336(s2)
  return 0;
    80005a4e:	4501                	li	a0,0
}
    80005a50:	60ea                	ld	ra,152(sp)
    80005a52:	644a                	ld	s0,144(sp)
    80005a54:	64aa                	ld	s1,136(sp)
    80005a56:	690a                	ld	s2,128(sp)
    80005a58:	610d                	addi	sp,sp,160
    80005a5a:	8082                	ret
    end_op();
    80005a5c:	ffffe097          	auipc	ra,0xffffe
    80005a60:	7b2080e7          	jalr	1970(ra) # 8000420e <end_op>
    return -1;
    80005a64:	557d                	li	a0,-1
    80005a66:	b7ed                	j	80005a50 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a68:	8526                	mv	a0,s1
    80005a6a:	ffffe097          	auipc	ra,0xffffe
    80005a6e:	fc4080e7          	jalr	-60(ra) # 80003a2e <iunlockput>
    end_op();
    80005a72:	ffffe097          	auipc	ra,0xffffe
    80005a76:	79c080e7          	jalr	1948(ra) # 8000420e <end_op>
    return -1;
    80005a7a:	557d                	li	a0,-1
    80005a7c:	bfd1                	j	80005a50 <sys_chdir+0x7a>

0000000080005a7e <sys_exec>:

uint64
sys_exec(void)
{
    80005a7e:	7145                	addi	sp,sp,-464
    80005a80:	e786                	sd	ra,456(sp)
    80005a82:	e3a2                	sd	s0,448(sp)
    80005a84:	ff26                	sd	s1,440(sp)
    80005a86:	fb4a                	sd	s2,432(sp)
    80005a88:	f74e                	sd	s3,424(sp)
    80005a8a:	f352                	sd	s4,416(sp)
    80005a8c:	ef56                	sd	s5,408(sp)
    80005a8e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005a90:	e3840593          	addi	a1,s0,-456
    80005a94:	4505                	li	a0,1
    80005a96:	ffffd097          	auipc	ra,0xffffd
    80005a9a:	0ea080e7          	jalr	234(ra) # 80002b80 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005a9e:	08000613          	li	a2,128
    80005aa2:	f4040593          	addi	a1,s0,-192
    80005aa6:	4501                	li	a0,0
    80005aa8:	ffffd097          	auipc	ra,0xffffd
    80005aac:	0f8080e7          	jalr	248(ra) # 80002ba0 <argstr>
    80005ab0:	87aa                	mv	a5,a0
    return -1;
    80005ab2:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005ab4:	0c07c263          	bltz	a5,80005b78 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ab8:	10000613          	li	a2,256
    80005abc:	4581                	li	a1,0
    80005abe:	e4040513          	addi	a0,s0,-448
    80005ac2:	ffffb097          	auipc	ra,0xffffb
    80005ac6:	224080e7          	jalr	548(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005aca:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ace:	89a6                	mv	s3,s1
    80005ad0:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ad2:	02000a13          	li	s4,32
    80005ad6:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ada:	00391513          	slli	a0,s2,0x3
    80005ade:	e3040593          	addi	a1,s0,-464
    80005ae2:	e3843783          	ld	a5,-456(s0)
    80005ae6:	953e                	add	a0,a0,a5
    80005ae8:	ffffd097          	auipc	ra,0xffffd
    80005aec:	fda080e7          	jalr	-38(ra) # 80002ac2 <fetchaddr>
    80005af0:	02054a63          	bltz	a0,80005b24 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005af4:	e3043783          	ld	a5,-464(s0)
    80005af8:	c3b9                	beqz	a5,80005b3e <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005afa:	ffffb097          	auipc	ra,0xffffb
    80005afe:	000080e7          	jalr	ra # 80000afa <kalloc>
    80005b02:	85aa                	mv	a1,a0
    80005b04:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b08:	cd11                	beqz	a0,80005b24 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b0a:	6605                	lui	a2,0x1
    80005b0c:	e3043503          	ld	a0,-464(s0)
    80005b10:	ffffd097          	auipc	ra,0xffffd
    80005b14:	004080e7          	jalr	4(ra) # 80002b14 <fetchstr>
    80005b18:	00054663          	bltz	a0,80005b24 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005b1c:	0905                	addi	s2,s2,1
    80005b1e:	09a1                	addi	s3,s3,8
    80005b20:	fb491be3          	bne	s2,s4,80005ad6 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b24:	10048913          	addi	s2,s1,256
    80005b28:	6088                	ld	a0,0(s1)
    80005b2a:	c531                	beqz	a0,80005b76 <sys_exec+0xf8>
    kfree(argv[i]);
    80005b2c:	ffffb097          	auipc	ra,0xffffb
    80005b30:	ed2080e7          	jalr	-302(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b34:	04a1                	addi	s1,s1,8
    80005b36:	ff2499e3          	bne	s1,s2,80005b28 <sys_exec+0xaa>
  return -1;
    80005b3a:	557d                	li	a0,-1
    80005b3c:	a835                	j	80005b78 <sys_exec+0xfa>
      argv[i] = 0;
    80005b3e:	0a8e                	slli	s5,s5,0x3
    80005b40:	fc040793          	addi	a5,s0,-64
    80005b44:	9abe                	add	s5,s5,a5
    80005b46:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b4a:	e4040593          	addi	a1,s0,-448
    80005b4e:	f4040513          	addi	a0,s0,-192
    80005b52:	fffff097          	auipc	ra,0xfffff
    80005b56:	190080e7          	jalr	400(ra) # 80004ce2 <exec>
    80005b5a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b5c:	10048993          	addi	s3,s1,256
    80005b60:	6088                	ld	a0,0(s1)
    80005b62:	c901                	beqz	a0,80005b72 <sys_exec+0xf4>
    kfree(argv[i]);
    80005b64:	ffffb097          	auipc	ra,0xffffb
    80005b68:	e9a080e7          	jalr	-358(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b6c:	04a1                	addi	s1,s1,8
    80005b6e:	ff3499e3          	bne	s1,s3,80005b60 <sys_exec+0xe2>
  return ret;
    80005b72:	854a                	mv	a0,s2
    80005b74:	a011                	j	80005b78 <sys_exec+0xfa>
  return -1;
    80005b76:	557d                	li	a0,-1
}
    80005b78:	60be                	ld	ra,456(sp)
    80005b7a:	641e                	ld	s0,448(sp)
    80005b7c:	74fa                	ld	s1,440(sp)
    80005b7e:	795a                	ld	s2,432(sp)
    80005b80:	79ba                	ld	s3,424(sp)
    80005b82:	7a1a                	ld	s4,416(sp)
    80005b84:	6afa                	ld	s5,408(sp)
    80005b86:	6179                	addi	sp,sp,464
    80005b88:	8082                	ret

0000000080005b8a <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b8a:	7139                	addi	sp,sp,-64
    80005b8c:	fc06                	sd	ra,56(sp)
    80005b8e:	f822                	sd	s0,48(sp)
    80005b90:	f426                	sd	s1,40(sp)
    80005b92:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b94:	ffffc097          	auipc	ra,0xffffc
    80005b98:	e32080e7          	jalr	-462(ra) # 800019c6 <myproc>
    80005b9c:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005b9e:	fd840593          	addi	a1,s0,-40
    80005ba2:	4501                	li	a0,0
    80005ba4:	ffffd097          	auipc	ra,0xffffd
    80005ba8:	fdc080e7          	jalr	-36(ra) # 80002b80 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005bac:	fc840593          	addi	a1,s0,-56
    80005bb0:	fd040513          	addi	a0,s0,-48
    80005bb4:	fffff097          	auipc	ra,0xfffff
    80005bb8:	dd6080e7          	jalr	-554(ra) # 8000498a <pipealloc>
    return -1;
    80005bbc:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005bbe:	0c054463          	bltz	a0,80005c86 <sys_pipe+0xfc>
  fd0 = -1;
    80005bc2:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005bc6:	fd043503          	ld	a0,-48(s0)
    80005bca:	fffff097          	auipc	ra,0xfffff
    80005bce:	518080e7          	jalr	1304(ra) # 800050e2 <fdalloc>
    80005bd2:	fca42223          	sw	a0,-60(s0)
    80005bd6:	08054b63          	bltz	a0,80005c6c <sys_pipe+0xe2>
    80005bda:	fc843503          	ld	a0,-56(s0)
    80005bde:	fffff097          	auipc	ra,0xfffff
    80005be2:	504080e7          	jalr	1284(ra) # 800050e2 <fdalloc>
    80005be6:	fca42023          	sw	a0,-64(s0)
    80005bea:	06054863          	bltz	a0,80005c5a <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bee:	4691                	li	a3,4
    80005bf0:	fc440613          	addi	a2,s0,-60
    80005bf4:	fd843583          	ld	a1,-40(s0)
    80005bf8:	68a8                	ld	a0,80(s1)
    80005bfa:	ffffc097          	auipc	ra,0xffffc
    80005bfe:	a8a080e7          	jalr	-1398(ra) # 80001684 <copyout>
    80005c02:	02054063          	bltz	a0,80005c22 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c06:	4691                	li	a3,4
    80005c08:	fc040613          	addi	a2,s0,-64
    80005c0c:	fd843583          	ld	a1,-40(s0)
    80005c10:	0591                	addi	a1,a1,4
    80005c12:	68a8                	ld	a0,80(s1)
    80005c14:	ffffc097          	auipc	ra,0xffffc
    80005c18:	a70080e7          	jalr	-1424(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c1c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c1e:	06055463          	bgez	a0,80005c86 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005c22:	fc442783          	lw	a5,-60(s0)
    80005c26:	07e9                	addi	a5,a5,26
    80005c28:	078e                	slli	a5,a5,0x3
    80005c2a:	97a6                	add	a5,a5,s1
    80005c2c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c30:	fc042503          	lw	a0,-64(s0)
    80005c34:	0569                	addi	a0,a0,26
    80005c36:	050e                	slli	a0,a0,0x3
    80005c38:	94aa                	add	s1,s1,a0
    80005c3a:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c3e:	fd043503          	ld	a0,-48(s0)
    80005c42:	fffff097          	auipc	ra,0xfffff
    80005c46:	a18080e7          	jalr	-1512(ra) # 8000465a <fileclose>
    fileclose(wf);
    80005c4a:	fc843503          	ld	a0,-56(s0)
    80005c4e:	fffff097          	auipc	ra,0xfffff
    80005c52:	a0c080e7          	jalr	-1524(ra) # 8000465a <fileclose>
    return -1;
    80005c56:	57fd                	li	a5,-1
    80005c58:	a03d                	j	80005c86 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005c5a:	fc442783          	lw	a5,-60(s0)
    80005c5e:	0007c763          	bltz	a5,80005c6c <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005c62:	07e9                	addi	a5,a5,26
    80005c64:	078e                	slli	a5,a5,0x3
    80005c66:	94be                	add	s1,s1,a5
    80005c68:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c6c:	fd043503          	ld	a0,-48(s0)
    80005c70:	fffff097          	auipc	ra,0xfffff
    80005c74:	9ea080e7          	jalr	-1558(ra) # 8000465a <fileclose>
    fileclose(wf);
    80005c78:	fc843503          	ld	a0,-56(s0)
    80005c7c:	fffff097          	auipc	ra,0xfffff
    80005c80:	9de080e7          	jalr	-1570(ra) # 8000465a <fileclose>
    return -1;
    80005c84:	57fd                	li	a5,-1
}
    80005c86:	853e                	mv	a0,a5
    80005c88:	70e2                	ld	ra,56(sp)
    80005c8a:	7442                	ld	s0,48(sp)
    80005c8c:	74a2                	ld	s1,40(sp)
    80005c8e:	6121                	addi	sp,sp,64
    80005c90:	8082                	ret
	...

0000000080005ca0 <kernelvec>:
    80005ca0:	7111                	addi	sp,sp,-256
    80005ca2:	e006                	sd	ra,0(sp)
    80005ca4:	e40a                	sd	sp,8(sp)
    80005ca6:	e80e                	sd	gp,16(sp)
    80005ca8:	ec12                	sd	tp,24(sp)
    80005caa:	f016                	sd	t0,32(sp)
    80005cac:	f41a                	sd	t1,40(sp)
    80005cae:	f81e                	sd	t2,48(sp)
    80005cb0:	fc22                	sd	s0,56(sp)
    80005cb2:	e0a6                	sd	s1,64(sp)
    80005cb4:	e4aa                	sd	a0,72(sp)
    80005cb6:	e8ae                	sd	a1,80(sp)
    80005cb8:	ecb2                	sd	a2,88(sp)
    80005cba:	f0b6                	sd	a3,96(sp)
    80005cbc:	f4ba                	sd	a4,104(sp)
    80005cbe:	f8be                	sd	a5,112(sp)
    80005cc0:	fcc2                	sd	a6,120(sp)
    80005cc2:	e146                	sd	a7,128(sp)
    80005cc4:	e54a                	sd	s2,136(sp)
    80005cc6:	e94e                	sd	s3,144(sp)
    80005cc8:	ed52                	sd	s4,152(sp)
    80005cca:	f156                	sd	s5,160(sp)
    80005ccc:	f55a                	sd	s6,168(sp)
    80005cce:	f95e                	sd	s7,176(sp)
    80005cd0:	fd62                	sd	s8,184(sp)
    80005cd2:	e1e6                	sd	s9,192(sp)
    80005cd4:	e5ea                	sd	s10,200(sp)
    80005cd6:	e9ee                	sd	s11,208(sp)
    80005cd8:	edf2                	sd	t3,216(sp)
    80005cda:	f1f6                	sd	t4,224(sp)
    80005cdc:	f5fa                	sd	t5,232(sp)
    80005cde:	f9fe                	sd	t6,240(sp)
    80005ce0:	caffc0ef          	jal	ra,8000298e <kerneltrap>
    80005ce4:	6082                	ld	ra,0(sp)
    80005ce6:	6122                	ld	sp,8(sp)
    80005ce8:	61c2                	ld	gp,16(sp)
    80005cea:	7282                	ld	t0,32(sp)
    80005cec:	7322                	ld	t1,40(sp)
    80005cee:	73c2                	ld	t2,48(sp)
    80005cf0:	7462                	ld	s0,56(sp)
    80005cf2:	6486                	ld	s1,64(sp)
    80005cf4:	6526                	ld	a0,72(sp)
    80005cf6:	65c6                	ld	a1,80(sp)
    80005cf8:	6666                	ld	a2,88(sp)
    80005cfa:	7686                	ld	a3,96(sp)
    80005cfc:	7726                	ld	a4,104(sp)
    80005cfe:	77c6                	ld	a5,112(sp)
    80005d00:	7866                	ld	a6,120(sp)
    80005d02:	688a                	ld	a7,128(sp)
    80005d04:	692a                	ld	s2,136(sp)
    80005d06:	69ca                	ld	s3,144(sp)
    80005d08:	6a6a                	ld	s4,152(sp)
    80005d0a:	7a8a                	ld	s5,160(sp)
    80005d0c:	7b2a                	ld	s6,168(sp)
    80005d0e:	7bca                	ld	s7,176(sp)
    80005d10:	7c6a                	ld	s8,184(sp)
    80005d12:	6c8e                	ld	s9,192(sp)
    80005d14:	6d2e                	ld	s10,200(sp)
    80005d16:	6dce                	ld	s11,208(sp)
    80005d18:	6e6e                	ld	t3,216(sp)
    80005d1a:	7e8e                	ld	t4,224(sp)
    80005d1c:	7f2e                	ld	t5,232(sp)
    80005d1e:	7fce                	ld	t6,240(sp)
    80005d20:	6111                	addi	sp,sp,256
    80005d22:	10200073          	sret
    80005d26:	00000013          	nop
    80005d2a:	00000013          	nop
    80005d2e:	0001                	nop

0000000080005d30 <timervec>:
    80005d30:	34051573          	csrrw	a0,mscratch,a0
    80005d34:	e10c                	sd	a1,0(a0)
    80005d36:	e510                	sd	a2,8(a0)
    80005d38:	e914                	sd	a3,16(a0)
    80005d3a:	6d0c                	ld	a1,24(a0)
    80005d3c:	7110                	ld	a2,32(a0)
    80005d3e:	6194                	ld	a3,0(a1)
    80005d40:	96b2                	add	a3,a3,a2
    80005d42:	e194                	sd	a3,0(a1)
    80005d44:	4589                	li	a1,2
    80005d46:	14459073          	csrw	sip,a1
    80005d4a:	6914                	ld	a3,16(a0)
    80005d4c:	6510                	ld	a2,8(a0)
    80005d4e:	610c                	ld	a1,0(a0)
    80005d50:	34051573          	csrrw	a0,mscratch,a0
    80005d54:	30200073          	mret
	...

0000000080005d5a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d5a:	1141                	addi	sp,sp,-16
    80005d5c:	e422                	sd	s0,8(sp)
    80005d5e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d60:	0c0007b7          	lui	a5,0xc000
    80005d64:	4705                	li	a4,1
    80005d66:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d68:	c3d8                	sw	a4,4(a5)
}
    80005d6a:	6422                	ld	s0,8(sp)
    80005d6c:	0141                	addi	sp,sp,16
    80005d6e:	8082                	ret

0000000080005d70 <plicinithart>:

void
plicinithart(void)
{
    80005d70:	1141                	addi	sp,sp,-16
    80005d72:	e406                	sd	ra,8(sp)
    80005d74:	e022                	sd	s0,0(sp)
    80005d76:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d78:	ffffc097          	auipc	ra,0xffffc
    80005d7c:	c22080e7          	jalr	-990(ra) # 8000199a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d80:	0085171b          	slliw	a4,a0,0x8
    80005d84:	0c0027b7          	lui	a5,0xc002
    80005d88:	97ba                	add	a5,a5,a4
    80005d8a:	40200713          	li	a4,1026
    80005d8e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d92:	00d5151b          	slliw	a0,a0,0xd
    80005d96:	0c2017b7          	lui	a5,0xc201
    80005d9a:	953e                	add	a0,a0,a5
    80005d9c:	00052023          	sw	zero,0(a0)
}
    80005da0:	60a2                	ld	ra,8(sp)
    80005da2:	6402                	ld	s0,0(sp)
    80005da4:	0141                	addi	sp,sp,16
    80005da6:	8082                	ret

0000000080005da8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005da8:	1141                	addi	sp,sp,-16
    80005daa:	e406                	sd	ra,8(sp)
    80005dac:	e022                	sd	s0,0(sp)
    80005dae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005db0:	ffffc097          	auipc	ra,0xffffc
    80005db4:	bea080e7          	jalr	-1046(ra) # 8000199a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005db8:	00d5179b          	slliw	a5,a0,0xd
    80005dbc:	0c201537          	lui	a0,0xc201
    80005dc0:	953e                	add	a0,a0,a5
  return irq;
}
    80005dc2:	4148                	lw	a0,4(a0)
    80005dc4:	60a2                	ld	ra,8(sp)
    80005dc6:	6402                	ld	s0,0(sp)
    80005dc8:	0141                	addi	sp,sp,16
    80005dca:	8082                	ret

0000000080005dcc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005dcc:	1101                	addi	sp,sp,-32
    80005dce:	ec06                	sd	ra,24(sp)
    80005dd0:	e822                	sd	s0,16(sp)
    80005dd2:	e426                	sd	s1,8(sp)
    80005dd4:	1000                	addi	s0,sp,32
    80005dd6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005dd8:	ffffc097          	auipc	ra,0xffffc
    80005ddc:	bc2080e7          	jalr	-1086(ra) # 8000199a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005de0:	00d5151b          	slliw	a0,a0,0xd
    80005de4:	0c2017b7          	lui	a5,0xc201
    80005de8:	97aa                	add	a5,a5,a0
    80005dea:	c3c4                	sw	s1,4(a5)
}
    80005dec:	60e2                	ld	ra,24(sp)
    80005dee:	6442                	ld	s0,16(sp)
    80005df0:	64a2                	ld	s1,8(sp)
    80005df2:	6105                	addi	sp,sp,32
    80005df4:	8082                	ret

0000000080005df6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005df6:	1141                	addi	sp,sp,-16
    80005df8:	e406                	sd	ra,8(sp)
    80005dfa:	e022                	sd	s0,0(sp)
    80005dfc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dfe:	479d                	li	a5,7
    80005e00:	04a7cc63          	blt	a5,a0,80005e58 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005e04:	0001c797          	auipc	a5,0x1c
    80005e08:	7ec78793          	addi	a5,a5,2028 # 800225f0 <disk>
    80005e0c:	97aa                	add	a5,a5,a0
    80005e0e:	0187c783          	lbu	a5,24(a5)
    80005e12:	ebb9                	bnez	a5,80005e68 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e14:	00451613          	slli	a2,a0,0x4
    80005e18:	0001c797          	auipc	a5,0x1c
    80005e1c:	7d878793          	addi	a5,a5,2008 # 800225f0 <disk>
    80005e20:	6394                	ld	a3,0(a5)
    80005e22:	96b2                	add	a3,a3,a2
    80005e24:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005e28:	6398                	ld	a4,0(a5)
    80005e2a:	9732                	add	a4,a4,a2
    80005e2c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005e30:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005e34:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005e38:	953e                	add	a0,a0,a5
    80005e3a:	4785                	li	a5,1
    80005e3c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005e40:	0001c517          	auipc	a0,0x1c
    80005e44:	7c850513          	addi	a0,a0,1992 # 80022608 <disk+0x18>
    80005e48:	ffffc097          	auipc	ra,0xffffc
    80005e4c:	28e080e7          	jalr	654(ra) # 800020d6 <wakeup>
}
    80005e50:	60a2                	ld	ra,8(sp)
    80005e52:	6402                	ld	s0,0(sp)
    80005e54:	0141                	addi	sp,sp,16
    80005e56:	8082                	ret
    panic("free_desc 1");
    80005e58:	00003517          	auipc	a0,0x3
    80005e5c:	9e050513          	addi	a0,a0,-1568 # 80008838 <syscalls+0x308>
    80005e60:	ffffa097          	auipc	ra,0xffffa
    80005e64:	6e4080e7          	jalr	1764(ra) # 80000544 <panic>
    panic("free_desc 2");
    80005e68:	00003517          	auipc	a0,0x3
    80005e6c:	9e050513          	addi	a0,a0,-1568 # 80008848 <syscalls+0x318>
    80005e70:	ffffa097          	auipc	ra,0xffffa
    80005e74:	6d4080e7          	jalr	1748(ra) # 80000544 <panic>

0000000080005e78 <virtio_disk_init>:
{
    80005e78:	1101                	addi	sp,sp,-32
    80005e7a:	ec06                	sd	ra,24(sp)
    80005e7c:	e822                	sd	s0,16(sp)
    80005e7e:	e426                	sd	s1,8(sp)
    80005e80:	e04a                	sd	s2,0(sp)
    80005e82:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e84:	00003597          	auipc	a1,0x3
    80005e88:	9d458593          	addi	a1,a1,-1580 # 80008858 <syscalls+0x328>
    80005e8c:	0001d517          	auipc	a0,0x1d
    80005e90:	88c50513          	addi	a0,a0,-1908 # 80022718 <disk+0x128>
    80005e94:	ffffb097          	auipc	ra,0xffffb
    80005e98:	cc6080e7          	jalr	-826(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e9c:	100017b7          	lui	a5,0x10001
    80005ea0:	4398                	lw	a4,0(a5)
    80005ea2:	2701                	sext.w	a4,a4
    80005ea4:	747277b7          	lui	a5,0x74727
    80005ea8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005eac:	14f71e63          	bne	a4,a5,80006008 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005eb0:	100017b7          	lui	a5,0x10001
    80005eb4:	43dc                	lw	a5,4(a5)
    80005eb6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005eb8:	4709                	li	a4,2
    80005eba:	14e79763          	bne	a5,a4,80006008 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ebe:	100017b7          	lui	a5,0x10001
    80005ec2:	479c                	lw	a5,8(a5)
    80005ec4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005ec6:	14e79163          	bne	a5,a4,80006008 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005eca:	100017b7          	lui	a5,0x10001
    80005ece:	47d8                	lw	a4,12(a5)
    80005ed0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ed2:	554d47b7          	lui	a5,0x554d4
    80005ed6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005eda:	12f71763          	bne	a4,a5,80006008 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ede:	100017b7          	lui	a5,0x10001
    80005ee2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ee6:	4705                	li	a4,1
    80005ee8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eea:	470d                	li	a4,3
    80005eec:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005eee:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005ef0:	c7ffe737          	lui	a4,0xc7ffe
    80005ef4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc02f>
    80005ef8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005efa:	2701                	sext.w	a4,a4
    80005efc:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005efe:	472d                	li	a4,11
    80005f00:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005f02:	0707a903          	lw	s2,112(a5)
    80005f06:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005f08:	00897793          	andi	a5,s2,8
    80005f0c:	10078663          	beqz	a5,80006018 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f10:	100017b7          	lui	a5,0x10001
    80005f14:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005f18:	43fc                	lw	a5,68(a5)
    80005f1a:	2781                	sext.w	a5,a5
    80005f1c:	10079663          	bnez	a5,80006028 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f20:	100017b7          	lui	a5,0x10001
    80005f24:	5bdc                	lw	a5,52(a5)
    80005f26:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f28:	10078863          	beqz	a5,80006038 <virtio_disk_init+0x1c0>
  if(max < NUM)
    80005f2c:	471d                	li	a4,7
    80005f2e:	10f77d63          	bgeu	a4,a5,80006048 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80005f32:	ffffb097          	auipc	ra,0xffffb
    80005f36:	bc8080e7          	jalr	-1080(ra) # 80000afa <kalloc>
    80005f3a:	0001c497          	auipc	s1,0x1c
    80005f3e:	6b648493          	addi	s1,s1,1718 # 800225f0 <disk>
    80005f42:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005f44:	ffffb097          	auipc	ra,0xffffb
    80005f48:	bb6080e7          	jalr	-1098(ra) # 80000afa <kalloc>
    80005f4c:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005f4e:	ffffb097          	auipc	ra,0xffffb
    80005f52:	bac080e7          	jalr	-1108(ra) # 80000afa <kalloc>
    80005f56:	87aa                	mv	a5,a0
    80005f58:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005f5a:	6088                	ld	a0,0(s1)
    80005f5c:	cd75                	beqz	a0,80006058 <virtio_disk_init+0x1e0>
    80005f5e:	0001c717          	auipc	a4,0x1c
    80005f62:	69a73703          	ld	a4,1690(a4) # 800225f8 <disk+0x8>
    80005f66:	cb6d                	beqz	a4,80006058 <virtio_disk_init+0x1e0>
    80005f68:	cbe5                	beqz	a5,80006058 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    80005f6a:	6605                	lui	a2,0x1
    80005f6c:	4581                	li	a1,0
    80005f6e:	ffffb097          	auipc	ra,0xffffb
    80005f72:	d78080e7          	jalr	-648(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005f76:	0001c497          	auipc	s1,0x1c
    80005f7a:	67a48493          	addi	s1,s1,1658 # 800225f0 <disk>
    80005f7e:	6605                	lui	a2,0x1
    80005f80:	4581                	li	a1,0
    80005f82:	6488                	ld	a0,8(s1)
    80005f84:	ffffb097          	auipc	ra,0xffffb
    80005f88:	d62080e7          	jalr	-670(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    80005f8c:	6605                	lui	a2,0x1
    80005f8e:	4581                	li	a1,0
    80005f90:	6888                	ld	a0,16(s1)
    80005f92:	ffffb097          	auipc	ra,0xffffb
    80005f96:	d54080e7          	jalr	-684(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f9a:	100017b7          	lui	a5,0x10001
    80005f9e:	4721                	li	a4,8
    80005fa0:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005fa2:	4098                	lw	a4,0(s1)
    80005fa4:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005fa8:	40d8                	lw	a4,4(s1)
    80005faa:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005fae:	6498                	ld	a4,8(s1)
    80005fb0:	0007069b          	sext.w	a3,a4
    80005fb4:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005fb8:	9701                	srai	a4,a4,0x20
    80005fba:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005fbe:	6898                	ld	a4,16(s1)
    80005fc0:	0007069b          	sext.w	a3,a4
    80005fc4:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005fc8:	9701                	srai	a4,a4,0x20
    80005fca:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005fce:	4685                	li	a3,1
    80005fd0:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80005fd2:	4705                	li	a4,1
    80005fd4:	00d48c23          	sb	a3,24(s1)
    80005fd8:	00e48ca3          	sb	a4,25(s1)
    80005fdc:	00e48d23          	sb	a4,26(s1)
    80005fe0:	00e48da3          	sb	a4,27(s1)
    80005fe4:	00e48e23          	sb	a4,28(s1)
    80005fe8:	00e48ea3          	sb	a4,29(s1)
    80005fec:	00e48f23          	sb	a4,30(s1)
    80005ff0:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005ff4:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ff8:	0727a823          	sw	s2,112(a5)
}
    80005ffc:	60e2                	ld	ra,24(sp)
    80005ffe:	6442                	ld	s0,16(sp)
    80006000:	64a2                	ld	s1,8(sp)
    80006002:	6902                	ld	s2,0(sp)
    80006004:	6105                	addi	sp,sp,32
    80006006:	8082                	ret
    panic("could not find virtio disk");
    80006008:	00003517          	auipc	a0,0x3
    8000600c:	86050513          	addi	a0,a0,-1952 # 80008868 <syscalls+0x338>
    80006010:	ffffa097          	auipc	ra,0xffffa
    80006014:	534080e7          	jalr	1332(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006018:	00003517          	auipc	a0,0x3
    8000601c:	87050513          	addi	a0,a0,-1936 # 80008888 <syscalls+0x358>
    80006020:	ffffa097          	auipc	ra,0xffffa
    80006024:	524080e7          	jalr	1316(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80006028:	00003517          	auipc	a0,0x3
    8000602c:	88050513          	addi	a0,a0,-1920 # 800088a8 <syscalls+0x378>
    80006030:	ffffa097          	auipc	ra,0xffffa
    80006034:	514080e7          	jalr	1300(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80006038:	00003517          	auipc	a0,0x3
    8000603c:	89050513          	addi	a0,a0,-1904 # 800088c8 <syscalls+0x398>
    80006040:	ffffa097          	auipc	ra,0xffffa
    80006044:	504080e7          	jalr	1284(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    80006048:	00003517          	auipc	a0,0x3
    8000604c:	8a050513          	addi	a0,a0,-1888 # 800088e8 <syscalls+0x3b8>
    80006050:	ffffa097          	auipc	ra,0xffffa
    80006054:	4f4080e7          	jalr	1268(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    80006058:	00003517          	auipc	a0,0x3
    8000605c:	8b050513          	addi	a0,a0,-1872 # 80008908 <syscalls+0x3d8>
    80006060:	ffffa097          	auipc	ra,0xffffa
    80006064:	4e4080e7          	jalr	1252(ra) # 80000544 <panic>

0000000080006068 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006068:	7159                	addi	sp,sp,-112
    8000606a:	f486                	sd	ra,104(sp)
    8000606c:	f0a2                	sd	s0,96(sp)
    8000606e:	eca6                	sd	s1,88(sp)
    80006070:	e8ca                	sd	s2,80(sp)
    80006072:	e4ce                	sd	s3,72(sp)
    80006074:	e0d2                	sd	s4,64(sp)
    80006076:	fc56                	sd	s5,56(sp)
    80006078:	f85a                	sd	s6,48(sp)
    8000607a:	f45e                	sd	s7,40(sp)
    8000607c:	f062                	sd	s8,32(sp)
    8000607e:	ec66                	sd	s9,24(sp)
    80006080:	e86a                	sd	s10,16(sp)
    80006082:	1880                	addi	s0,sp,112
    80006084:	892a                	mv	s2,a0
    80006086:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006088:	00c52c83          	lw	s9,12(a0)
    8000608c:	001c9c9b          	slliw	s9,s9,0x1
    80006090:	1c82                	slli	s9,s9,0x20
    80006092:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006096:	0001c517          	auipc	a0,0x1c
    8000609a:	68250513          	addi	a0,a0,1666 # 80022718 <disk+0x128>
    8000609e:	ffffb097          	auipc	ra,0xffffb
    800060a2:	b4c080e7          	jalr	-1204(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    800060a6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800060a8:	4ba1                	li	s7,8
      disk.free[i] = 0;
    800060aa:	0001cb17          	auipc	s6,0x1c
    800060ae:	546b0b13          	addi	s6,s6,1350 # 800225f0 <disk>
  for(int i = 0; i < 3; i++){
    800060b2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800060b4:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060b6:	0001cc17          	auipc	s8,0x1c
    800060ba:	662c0c13          	addi	s8,s8,1634 # 80022718 <disk+0x128>
    800060be:	a8b5                	j	8000613a <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    800060c0:	00fb06b3          	add	a3,s6,a5
    800060c4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800060c8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800060ca:	0207c563          	bltz	a5,800060f4 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800060ce:	2485                	addiw	s1,s1,1
    800060d0:	0711                	addi	a4,a4,4
    800060d2:	1f548a63          	beq	s1,s5,800062c6 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    800060d6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800060d8:	0001c697          	auipc	a3,0x1c
    800060dc:	51868693          	addi	a3,a3,1304 # 800225f0 <disk>
    800060e0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800060e2:	0186c583          	lbu	a1,24(a3)
    800060e6:	fde9                	bnez	a1,800060c0 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800060e8:	2785                	addiw	a5,a5,1
    800060ea:	0685                	addi	a3,a3,1
    800060ec:	ff779be3          	bne	a5,s7,800060e2 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800060f0:	57fd                	li	a5,-1
    800060f2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800060f4:	02905a63          	blez	s1,80006128 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800060f8:	f9042503          	lw	a0,-112(s0)
    800060fc:	00000097          	auipc	ra,0x0
    80006100:	cfa080e7          	jalr	-774(ra) # 80005df6 <free_desc>
      for(int j = 0; j < i; j++)
    80006104:	4785                	li	a5,1
    80006106:	0297d163          	bge	a5,s1,80006128 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000610a:	f9442503          	lw	a0,-108(s0)
    8000610e:	00000097          	auipc	ra,0x0
    80006112:	ce8080e7          	jalr	-792(ra) # 80005df6 <free_desc>
      for(int j = 0; j < i; j++)
    80006116:	4789                	li	a5,2
    80006118:	0097d863          	bge	a5,s1,80006128 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000611c:	f9842503          	lw	a0,-104(s0)
    80006120:	00000097          	auipc	ra,0x0
    80006124:	cd6080e7          	jalr	-810(ra) # 80005df6 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006128:	85e2                	mv	a1,s8
    8000612a:	0001c517          	auipc	a0,0x1c
    8000612e:	4de50513          	addi	a0,a0,1246 # 80022608 <disk+0x18>
    80006132:	ffffc097          	auipc	ra,0xffffc
    80006136:	f40080e7          	jalr	-192(ra) # 80002072 <sleep>
  for(int i = 0; i < 3; i++){
    8000613a:	f9040713          	addi	a4,s0,-112
    8000613e:	84ce                	mv	s1,s3
    80006140:	bf59                	j	800060d6 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006142:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    80006146:	00479693          	slli	a3,a5,0x4
    8000614a:	0001c797          	auipc	a5,0x1c
    8000614e:	4a678793          	addi	a5,a5,1190 # 800225f0 <disk>
    80006152:	97b6                	add	a5,a5,a3
    80006154:	4685                	li	a3,1
    80006156:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006158:	0001c597          	auipc	a1,0x1c
    8000615c:	49858593          	addi	a1,a1,1176 # 800225f0 <disk>
    80006160:	00a60793          	addi	a5,a2,10
    80006164:	0792                	slli	a5,a5,0x4
    80006166:	97ae                	add	a5,a5,a1
    80006168:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    8000616c:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006170:	f6070693          	addi	a3,a4,-160
    80006174:	619c                	ld	a5,0(a1)
    80006176:	97b6                	add	a5,a5,a3
    80006178:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000617a:	6188                	ld	a0,0(a1)
    8000617c:	96aa                	add	a3,a3,a0
    8000617e:	47c1                	li	a5,16
    80006180:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006182:	4785                	li	a5,1
    80006184:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006188:	f9442783          	lw	a5,-108(s0)
    8000618c:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006190:	0792                	slli	a5,a5,0x4
    80006192:	953e                	add	a0,a0,a5
    80006194:	05890693          	addi	a3,s2,88
    80006198:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000619a:	6188                	ld	a0,0(a1)
    8000619c:	97aa                	add	a5,a5,a0
    8000619e:	40000693          	li	a3,1024
    800061a2:	c794                	sw	a3,8(a5)
  if(write)
    800061a4:	100d0d63          	beqz	s10,800062be <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800061a8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800061ac:	00c7d683          	lhu	a3,12(a5)
    800061b0:	0016e693          	ori	a3,a3,1
    800061b4:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    800061b8:	f9842583          	lw	a1,-104(s0)
    800061bc:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800061c0:	0001c697          	auipc	a3,0x1c
    800061c4:	43068693          	addi	a3,a3,1072 # 800225f0 <disk>
    800061c8:	00260793          	addi	a5,a2,2
    800061cc:	0792                	slli	a5,a5,0x4
    800061ce:	97b6                	add	a5,a5,a3
    800061d0:	587d                	li	a6,-1
    800061d2:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800061d6:	0592                	slli	a1,a1,0x4
    800061d8:	952e                	add	a0,a0,a1
    800061da:	f9070713          	addi	a4,a4,-112
    800061de:	9736                	add	a4,a4,a3
    800061e0:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    800061e2:	6298                	ld	a4,0(a3)
    800061e4:	972e                	add	a4,a4,a1
    800061e6:	4585                	li	a1,1
    800061e8:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061ea:	4509                	li	a0,2
    800061ec:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    800061f0:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800061f4:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    800061f8:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800061fc:	6698                	ld	a4,8(a3)
    800061fe:	00275783          	lhu	a5,2(a4)
    80006202:	8b9d                	andi	a5,a5,7
    80006204:	0786                	slli	a5,a5,0x1
    80006206:	97ba                	add	a5,a5,a4
    80006208:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    8000620c:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006210:	6698                	ld	a4,8(a3)
    80006212:	00275783          	lhu	a5,2(a4)
    80006216:	2785                	addiw	a5,a5,1
    80006218:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    8000621c:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006220:	100017b7          	lui	a5,0x10001
    80006224:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006228:	00492703          	lw	a4,4(s2)
    8000622c:	4785                	li	a5,1
    8000622e:	02f71163          	bne	a4,a5,80006250 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    80006232:	0001c997          	auipc	s3,0x1c
    80006236:	4e698993          	addi	s3,s3,1254 # 80022718 <disk+0x128>
  while(b->disk == 1) {
    8000623a:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000623c:	85ce                	mv	a1,s3
    8000623e:	854a                	mv	a0,s2
    80006240:	ffffc097          	auipc	ra,0xffffc
    80006244:	e32080e7          	jalr	-462(ra) # 80002072 <sleep>
  while(b->disk == 1) {
    80006248:	00492783          	lw	a5,4(s2)
    8000624c:	fe9788e3          	beq	a5,s1,8000623c <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    80006250:	f9042903          	lw	s2,-112(s0)
    80006254:	00290793          	addi	a5,s2,2
    80006258:	00479713          	slli	a4,a5,0x4
    8000625c:	0001c797          	auipc	a5,0x1c
    80006260:	39478793          	addi	a5,a5,916 # 800225f0 <disk>
    80006264:	97ba                	add	a5,a5,a4
    80006266:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000626a:	0001c997          	auipc	s3,0x1c
    8000626e:	38698993          	addi	s3,s3,902 # 800225f0 <disk>
    80006272:	00491713          	slli	a4,s2,0x4
    80006276:	0009b783          	ld	a5,0(s3)
    8000627a:	97ba                	add	a5,a5,a4
    8000627c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006280:	854a                	mv	a0,s2
    80006282:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006286:	00000097          	auipc	ra,0x0
    8000628a:	b70080e7          	jalr	-1168(ra) # 80005df6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000628e:	8885                	andi	s1,s1,1
    80006290:	f0ed                	bnez	s1,80006272 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006292:	0001c517          	auipc	a0,0x1c
    80006296:	48650513          	addi	a0,a0,1158 # 80022718 <disk+0x128>
    8000629a:	ffffb097          	auipc	ra,0xffffb
    8000629e:	a04080e7          	jalr	-1532(ra) # 80000c9e <release>
}
    800062a2:	70a6                	ld	ra,104(sp)
    800062a4:	7406                	ld	s0,96(sp)
    800062a6:	64e6                	ld	s1,88(sp)
    800062a8:	6946                	ld	s2,80(sp)
    800062aa:	69a6                	ld	s3,72(sp)
    800062ac:	6a06                	ld	s4,64(sp)
    800062ae:	7ae2                	ld	s5,56(sp)
    800062b0:	7b42                	ld	s6,48(sp)
    800062b2:	7ba2                	ld	s7,40(sp)
    800062b4:	7c02                	ld	s8,32(sp)
    800062b6:	6ce2                	ld	s9,24(sp)
    800062b8:	6d42                	ld	s10,16(sp)
    800062ba:	6165                	addi	sp,sp,112
    800062bc:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800062be:	4689                	li	a3,2
    800062c0:	00d79623          	sh	a3,12(a5)
    800062c4:	b5e5                	j	800061ac <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062c6:	f9042603          	lw	a2,-112(s0)
    800062ca:	00a60713          	addi	a4,a2,10
    800062ce:	0712                	slli	a4,a4,0x4
    800062d0:	0001c517          	auipc	a0,0x1c
    800062d4:	32850513          	addi	a0,a0,808 # 800225f8 <disk+0x8>
    800062d8:	953a                	add	a0,a0,a4
  if(write)
    800062da:	e60d14e3          	bnez	s10,80006142 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800062de:	00a60793          	addi	a5,a2,10
    800062e2:	00479693          	slli	a3,a5,0x4
    800062e6:	0001c797          	auipc	a5,0x1c
    800062ea:	30a78793          	addi	a5,a5,778 # 800225f0 <disk>
    800062ee:	97b6                	add	a5,a5,a3
    800062f0:	0007a423          	sw	zero,8(a5)
    800062f4:	b595                	j	80006158 <virtio_disk_rw+0xf0>

00000000800062f6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800062f6:	1101                	addi	sp,sp,-32
    800062f8:	ec06                	sd	ra,24(sp)
    800062fa:	e822                	sd	s0,16(sp)
    800062fc:	e426                	sd	s1,8(sp)
    800062fe:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006300:	0001c497          	auipc	s1,0x1c
    80006304:	2f048493          	addi	s1,s1,752 # 800225f0 <disk>
    80006308:	0001c517          	auipc	a0,0x1c
    8000630c:	41050513          	addi	a0,a0,1040 # 80022718 <disk+0x128>
    80006310:	ffffb097          	auipc	ra,0xffffb
    80006314:	8da080e7          	jalr	-1830(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006318:	10001737          	lui	a4,0x10001
    8000631c:	533c                	lw	a5,96(a4)
    8000631e:	8b8d                	andi	a5,a5,3
    80006320:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006322:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006326:	689c                	ld	a5,16(s1)
    80006328:	0204d703          	lhu	a4,32(s1)
    8000632c:	0027d783          	lhu	a5,2(a5)
    80006330:	04f70863          	beq	a4,a5,80006380 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006334:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006338:	6898                	ld	a4,16(s1)
    8000633a:	0204d783          	lhu	a5,32(s1)
    8000633e:	8b9d                	andi	a5,a5,7
    80006340:	078e                	slli	a5,a5,0x3
    80006342:	97ba                	add	a5,a5,a4
    80006344:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006346:	00278713          	addi	a4,a5,2
    8000634a:	0712                	slli	a4,a4,0x4
    8000634c:	9726                	add	a4,a4,s1
    8000634e:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006352:	e721                	bnez	a4,8000639a <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006354:	0789                	addi	a5,a5,2
    80006356:	0792                	slli	a5,a5,0x4
    80006358:	97a6                	add	a5,a5,s1
    8000635a:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000635c:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006360:	ffffc097          	auipc	ra,0xffffc
    80006364:	d76080e7          	jalr	-650(ra) # 800020d6 <wakeup>

    disk.used_idx += 1;
    80006368:	0204d783          	lhu	a5,32(s1)
    8000636c:	2785                	addiw	a5,a5,1
    8000636e:	17c2                	slli	a5,a5,0x30
    80006370:	93c1                	srli	a5,a5,0x30
    80006372:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006376:	6898                	ld	a4,16(s1)
    80006378:	00275703          	lhu	a4,2(a4)
    8000637c:	faf71ce3          	bne	a4,a5,80006334 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006380:	0001c517          	auipc	a0,0x1c
    80006384:	39850513          	addi	a0,a0,920 # 80022718 <disk+0x128>
    80006388:	ffffb097          	auipc	ra,0xffffb
    8000638c:	916080e7          	jalr	-1770(ra) # 80000c9e <release>
}
    80006390:	60e2                	ld	ra,24(sp)
    80006392:	6442                	ld	s0,16(sp)
    80006394:	64a2                	ld	s1,8(sp)
    80006396:	6105                	addi	sp,sp,32
    80006398:	8082                	ret
      panic("virtio_disk_intr status");
    8000639a:	00002517          	auipc	a0,0x2
    8000639e:	58650513          	addi	a0,a0,1414 # 80008920 <syscalls+0x3f0>
    800063a2:	ffffa097          	auipc	ra,0xffffa
    800063a6:	1a2080e7          	jalr	418(ra) # 80000544 <panic>
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
