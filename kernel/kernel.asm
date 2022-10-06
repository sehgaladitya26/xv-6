
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
    80000ee6:	e6e080e7          	jalr	-402(ra) # 80005d50 <plicinithart>
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
    80000f66:	dd8080e7          	jalr	-552(ra) # 80005d3a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00005097          	auipc	ra,0x5
    80000f6e:	de6080e7          	jalr	-538(ra) # 80005d50 <plicinithart>
    binit();         // buffer cache
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	f94080e7          	jalr	-108(ra) # 80002f06 <binit>
    iinit();         // inode table
    80000f7a:	00002097          	auipc	ra,0x2
    80000f7e:	638080e7          	jalr	1592(ra) # 800035b2 <iinit>
    fileinit();      // file table
    80000f82:	00003097          	auipc	ra,0x3
    80000f86:	5d6080e7          	jalr	1494(ra) # 80004558 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	ece080e7          	jalr	-306(ra) # 80005e58 <virtio_disk_init>
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
    80001a3e:	af8080e7          	jalr	-1288(ra) # 80003532 <fsinit>
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
    80001d00:	258080e7          	jalr	600(ra) # 80003f54 <namei>
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
    80001e26:	7c8080e7          	jalr	1992(ra) # 800045ea <filedup>
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
    80001e48:	92c080e7          	jalr	-1748(ra) # 80003770 <idup>
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
    800021ea:	456080e7          	jalr	1110(ra) # 8000463c <fileclose>
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
    80002202:	f72080e7          	jalr	-142(ra) # 80004170 <begin_op>
  iput(p->cwd);
    80002206:	1509b503          	ld	a0,336(s3)
    8000220a:	00001097          	auipc	ra,0x1
    8000220e:	75e080e7          	jalr	1886(ra) # 80003968 <iput>
  end_op();
    80002212:	00002097          	auipc	ra,0x2
    80002216:	fde080e7          	jalr	-34(ra) # 800041f0 <end_op>
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
    80002670:	61478793          	addi	a5,a5,1556 # 80005c80 <kernelvec>
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
    80002790:	5fc080e7          	jalr	1532(ra) # 80005d88 <plic_claim>
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
    800027be:	5f2080e7          	jalr	1522(ra) # 80005dac <plic_complete>
    return 1;
    800027c2:	4505                	li	a0,1
    800027c4:	bf55                	j	80002778 <devintr+0x1e>
      uartintr();
    800027c6:	ffffe097          	auipc	ra,0xffffe
    800027ca:	1e8080e7          	jalr	488(ra) # 800009ae <uartintr>
    800027ce:	b7ed                	j	800027b8 <devintr+0x5e>
      virtio_disk_intr();
    800027d0:	00004097          	auipc	ra,0x4
    800027d4:	b06080e7          	jalr	-1274(ra) # 800062d6 <virtio_disk_intr>
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
    80002816:	46e78793          	addi	a5,a5,1134 # 80005c80 <kernelvec>
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
    80002844:	cd61                	beqz	a0,8000291c <usertrap+0x120>
    if(which_dev == 2 && myproc()->interval) {
    80002846:	4789                	li	a5,2
    80002848:	06f50663          	beq	a0,a5,800028b4 <usertrap+0xb8>
  if(killed(p))
    8000284c:	8526                	mv	a0,s1
    8000284e:	00000097          	auipc	ra,0x0
    80002852:	acc080e7          	jalr	-1332(ra) # 8000231a <killed>
    80002856:	10051063          	bnez	a0,80002956 <usertrap+0x15a>
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
    800028a0:	31e080e7          	jalr	798(ra) # 80002bba <syscall>
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
    800028cc:	cd49                	beqz	a0,80002966 <usertrap+0x16a>
    exit(-1);
    800028ce:	557d                	li	a0,-1
    800028d0:	00000097          	auipc	ra,0x0
    800028d4:	8d6080e7          	jalr	-1834(ra) # 800021a6 <exit>
  if(which_dev == 2)
    800028d8:	a079                	j	80002966 <usertrap+0x16a>
      myproc()->ticks_left--;
    800028da:	fffff097          	auipc	ra,0xfffff
    800028de:	0ec080e7          	jalr	236(ra) # 800019c6 <myproc>
    800028e2:	17052783          	lw	a5,368(a0)
    800028e6:	37fd                	addiw	a5,a5,-1
    800028e8:	16f52823          	sw	a5,368(a0)
      if(myproc()->ticks_left == 0) {
    800028ec:	fffff097          	auipc	ra,0xfffff
    800028f0:	0da080e7          	jalr	218(ra) # 800019c6 <myproc>
    800028f4:	17052783          	lw	a5,368(a0)
    800028f8:	f7e9                	bnez	a5,800028c2 <usertrap+0xc6>
        p->sigalarm_tf = kalloc();
    800028fa:	ffffe097          	auipc	ra,0xffffe
    800028fe:	200080e7          	jalr	512(ra) # 80000afa <kalloc>
    80002902:	18a4b023          	sd	a0,384(s1)
        memmove(p->sigalarm_tf, p->trapframe, PGSIZE);
    80002906:	6605                	lui	a2,0x1
    80002908:	6cac                	ld	a1,88(s1)
    8000290a:	ffffe097          	auipc	ra,0xffffe
    8000290e:	43c080e7          	jalr	1084(ra) # 80000d46 <memmove>
        p->trapframe->epc = p->sig_handler;
    80002912:	6cbc                	ld	a5,88(s1)
    80002914:	1784b703          	ld	a4,376(s1)
    80002918:	ef98                	sd	a4,24(a5)
    8000291a:	b765                	j	800028c2 <usertrap+0xc6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000291c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002920:	5890                	lw	a2,48(s1)
    80002922:	00006517          	auipc	a0,0x6
    80002926:	a1e50513          	addi	a0,a0,-1506 # 80008340 <states.1727+0x78>
    8000292a:	ffffe097          	auipc	ra,0xffffe
    8000292e:	c64080e7          	jalr	-924(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002932:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002936:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000293a:	00006517          	auipc	a0,0x6
    8000293e:	a3650513          	addi	a0,a0,-1482 # 80008370 <states.1727+0xa8>
    80002942:	ffffe097          	auipc	ra,0xffffe
    80002946:	c4c080e7          	jalr	-948(ra) # 8000058e <printf>
    setkilled(p);
    8000294a:	8526                	mv	a0,s1
    8000294c:	00000097          	auipc	ra,0x0
    80002950:	9a2080e7          	jalr	-1630(ra) # 800022ee <setkilled>
    80002954:	bde5                	j	8000284c <usertrap+0x50>
    exit(-1);
    80002956:	557d                	li	a0,-1
    80002958:	00000097          	auipc	ra,0x0
    8000295c:	84e080e7          	jalr	-1970(ra) # 800021a6 <exit>
  if(which_dev == 2)
    80002960:	4789                	li	a5,2
    80002962:	eef91ce3          	bne	s2,a5,8000285a <usertrap+0x5e>
    yield();
    80002966:	fffff097          	auipc	ra,0xfffff
    8000296a:	6d0080e7          	jalr	1744(ra) # 80002036 <yield>
    8000296e:	b5f5                	j	8000285a <usertrap+0x5e>

0000000080002970 <kerneltrap>:
{
    80002970:	7179                	addi	sp,sp,-48
    80002972:	f406                	sd	ra,40(sp)
    80002974:	f022                	sd	s0,32(sp)
    80002976:	ec26                	sd	s1,24(sp)
    80002978:	e84a                	sd	s2,16(sp)
    8000297a:	e44e                	sd	s3,8(sp)
    8000297c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000297e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002982:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002986:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000298a:	1004f793          	andi	a5,s1,256
    8000298e:	cb85                	beqz	a5,800029be <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002990:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002994:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002996:	ef85                	bnez	a5,800029ce <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002998:	00000097          	auipc	ra,0x0
    8000299c:	dc2080e7          	jalr	-574(ra) # 8000275a <devintr>
    800029a0:	cd1d                	beqz	a0,800029de <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029a2:	4789                	li	a5,2
    800029a4:	06f50a63          	beq	a0,a5,80002a18 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029a8:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029ac:	10049073          	csrw	sstatus,s1
}
    800029b0:	70a2                	ld	ra,40(sp)
    800029b2:	7402                	ld	s0,32(sp)
    800029b4:	64e2                	ld	s1,24(sp)
    800029b6:	6942                	ld	s2,16(sp)
    800029b8:	69a2                	ld	s3,8(sp)
    800029ba:	6145                	addi	sp,sp,48
    800029bc:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029be:	00006517          	auipc	a0,0x6
    800029c2:	9d250513          	addi	a0,a0,-1582 # 80008390 <states.1727+0xc8>
    800029c6:	ffffe097          	auipc	ra,0xffffe
    800029ca:	b7e080e7          	jalr	-1154(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    800029ce:	00006517          	auipc	a0,0x6
    800029d2:	9ea50513          	addi	a0,a0,-1558 # 800083b8 <states.1727+0xf0>
    800029d6:	ffffe097          	auipc	ra,0xffffe
    800029da:	b6e080e7          	jalr	-1170(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    800029de:	85ce                	mv	a1,s3
    800029e0:	00006517          	auipc	a0,0x6
    800029e4:	9f850513          	addi	a0,a0,-1544 # 800083d8 <states.1727+0x110>
    800029e8:	ffffe097          	auipc	ra,0xffffe
    800029ec:	ba6080e7          	jalr	-1114(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029f0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029f4:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029f8:	00006517          	auipc	a0,0x6
    800029fc:	9f050513          	addi	a0,a0,-1552 # 800083e8 <states.1727+0x120>
    80002a00:	ffffe097          	auipc	ra,0xffffe
    80002a04:	b8e080e7          	jalr	-1138(ra) # 8000058e <printf>
    panic("kerneltrap");
    80002a08:	00006517          	auipc	a0,0x6
    80002a0c:	9f850513          	addi	a0,a0,-1544 # 80008400 <states.1727+0x138>
    80002a10:	ffffe097          	auipc	ra,0xffffe
    80002a14:	b34080e7          	jalr	-1228(ra) # 80000544 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a18:	fffff097          	auipc	ra,0xfffff
    80002a1c:	fae080e7          	jalr	-82(ra) # 800019c6 <myproc>
    80002a20:	d541                	beqz	a0,800029a8 <kerneltrap+0x38>
    80002a22:	fffff097          	auipc	ra,0xfffff
    80002a26:	fa4080e7          	jalr	-92(ra) # 800019c6 <myproc>
    80002a2a:	4d18                	lw	a4,24(a0)
    80002a2c:	4791                	li	a5,4
    80002a2e:	f6f71de3          	bne	a4,a5,800029a8 <kerneltrap+0x38>
    yield();
    80002a32:	fffff097          	auipc	ra,0xfffff
    80002a36:	604080e7          	jalr	1540(ra) # 80002036 <yield>
    80002a3a:	b7bd                	j	800029a8 <kerneltrap+0x38>

0000000080002a3c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a3c:	1101                	addi	sp,sp,-32
    80002a3e:	ec06                	sd	ra,24(sp)
    80002a40:	e822                	sd	s0,16(sp)
    80002a42:	e426                	sd	s1,8(sp)
    80002a44:	1000                	addi	s0,sp,32
    80002a46:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a48:	fffff097          	auipc	ra,0xfffff
    80002a4c:	f7e080e7          	jalr	-130(ra) # 800019c6 <myproc>
  switch (n) {
    80002a50:	4795                	li	a5,5
    80002a52:	0497e163          	bltu	a5,s1,80002a94 <argraw+0x58>
    80002a56:	048a                	slli	s1,s1,0x2
    80002a58:	00006717          	auipc	a4,0x6
    80002a5c:	ac070713          	addi	a4,a4,-1344 # 80008518 <states.1727+0x250>
    80002a60:	94ba                	add	s1,s1,a4
    80002a62:	409c                	lw	a5,0(s1)
    80002a64:	97ba                	add	a5,a5,a4
    80002a66:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a68:	6d3c                	ld	a5,88(a0)
    80002a6a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a6c:	60e2                	ld	ra,24(sp)
    80002a6e:	6442                	ld	s0,16(sp)
    80002a70:	64a2                	ld	s1,8(sp)
    80002a72:	6105                	addi	sp,sp,32
    80002a74:	8082                	ret
    return p->trapframe->a1;
    80002a76:	6d3c                	ld	a5,88(a0)
    80002a78:	7fa8                	ld	a0,120(a5)
    80002a7a:	bfcd                	j	80002a6c <argraw+0x30>
    return p->trapframe->a2;
    80002a7c:	6d3c                	ld	a5,88(a0)
    80002a7e:	63c8                	ld	a0,128(a5)
    80002a80:	b7f5                	j	80002a6c <argraw+0x30>
    return p->trapframe->a3;
    80002a82:	6d3c                	ld	a5,88(a0)
    80002a84:	67c8                	ld	a0,136(a5)
    80002a86:	b7dd                	j	80002a6c <argraw+0x30>
    return p->trapframe->a4;
    80002a88:	6d3c                	ld	a5,88(a0)
    80002a8a:	6bc8                	ld	a0,144(a5)
    80002a8c:	b7c5                	j	80002a6c <argraw+0x30>
    return p->trapframe->a5;
    80002a8e:	6d3c                	ld	a5,88(a0)
    80002a90:	6fc8                	ld	a0,152(a5)
    80002a92:	bfe9                	j	80002a6c <argraw+0x30>
  panic("argraw");
    80002a94:	00006517          	auipc	a0,0x6
    80002a98:	97c50513          	addi	a0,a0,-1668 # 80008410 <states.1727+0x148>
    80002a9c:	ffffe097          	auipc	ra,0xffffe
    80002aa0:	aa8080e7          	jalr	-1368(ra) # 80000544 <panic>

0000000080002aa4 <fetchaddr>:
{
    80002aa4:	1101                	addi	sp,sp,-32
    80002aa6:	ec06                	sd	ra,24(sp)
    80002aa8:	e822                	sd	s0,16(sp)
    80002aaa:	e426                	sd	s1,8(sp)
    80002aac:	e04a                	sd	s2,0(sp)
    80002aae:	1000                	addi	s0,sp,32
    80002ab0:	84aa                	mv	s1,a0
    80002ab2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ab4:	fffff097          	auipc	ra,0xfffff
    80002ab8:	f12080e7          	jalr	-238(ra) # 800019c6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002abc:	653c                	ld	a5,72(a0)
    80002abe:	02f4f863          	bgeu	s1,a5,80002aee <fetchaddr+0x4a>
    80002ac2:	00848713          	addi	a4,s1,8
    80002ac6:	02e7e663          	bltu	a5,a4,80002af2 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002aca:	46a1                	li	a3,8
    80002acc:	8626                	mv	a2,s1
    80002ace:	85ca                	mv	a1,s2
    80002ad0:	6928                	ld	a0,80(a0)
    80002ad2:	fffff097          	auipc	ra,0xfffff
    80002ad6:	c3e080e7          	jalr	-962(ra) # 80001710 <copyin>
    80002ada:	00a03533          	snez	a0,a0
    80002ade:	40a00533          	neg	a0,a0
}
    80002ae2:	60e2                	ld	ra,24(sp)
    80002ae4:	6442                	ld	s0,16(sp)
    80002ae6:	64a2                	ld	s1,8(sp)
    80002ae8:	6902                	ld	s2,0(sp)
    80002aea:	6105                	addi	sp,sp,32
    80002aec:	8082                	ret
    return -1;
    80002aee:	557d                	li	a0,-1
    80002af0:	bfcd                	j	80002ae2 <fetchaddr+0x3e>
    80002af2:	557d                	li	a0,-1
    80002af4:	b7fd                	j	80002ae2 <fetchaddr+0x3e>

0000000080002af6 <fetchstr>:
{
    80002af6:	7179                	addi	sp,sp,-48
    80002af8:	f406                	sd	ra,40(sp)
    80002afa:	f022                	sd	s0,32(sp)
    80002afc:	ec26                	sd	s1,24(sp)
    80002afe:	e84a                	sd	s2,16(sp)
    80002b00:	e44e                	sd	s3,8(sp)
    80002b02:	1800                	addi	s0,sp,48
    80002b04:	892a                	mv	s2,a0
    80002b06:	84ae                	mv	s1,a1
    80002b08:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b0a:	fffff097          	auipc	ra,0xfffff
    80002b0e:	ebc080e7          	jalr	-324(ra) # 800019c6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002b12:	86ce                	mv	a3,s3
    80002b14:	864a                	mv	a2,s2
    80002b16:	85a6                	mv	a1,s1
    80002b18:	6928                	ld	a0,80(a0)
    80002b1a:	fffff097          	auipc	ra,0xfffff
    80002b1e:	c82080e7          	jalr	-894(ra) # 8000179c <copyinstr>
    80002b22:	00054e63          	bltz	a0,80002b3e <fetchstr+0x48>
  return strlen(buf);
    80002b26:	8526                	mv	a0,s1
    80002b28:	ffffe097          	auipc	ra,0xffffe
    80002b2c:	342080e7          	jalr	834(ra) # 80000e6a <strlen>
}
    80002b30:	70a2                	ld	ra,40(sp)
    80002b32:	7402                	ld	s0,32(sp)
    80002b34:	64e2                	ld	s1,24(sp)
    80002b36:	6942                	ld	s2,16(sp)
    80002b38:	69a2                	ld	s3,8(sp)
    80002b3a:	6145                	addi	sp,sp,48
    80002b3c:	8082                	ret
    return -1;
    80002b3e:	557d                	li	a0,-1
    80002b40:	bfc5                	j	80002b30 <fetchstr+0x3a>

0000000080002b42 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002b42:	1101                	addi	sp,sp,-32
    80002b44:	ec06                	sd	ra,24(sp)
    80002b46:	e822                	sd	s0,16(sp)
    80002b48:	e426                	sd	s1,8(sp)
    80002b4a:	1000                	addi	s0,sp,32
    80002b4c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b4e:	00000097          	auipc	ra,0x0
    80002b52:	eee080e7          	jalr	-274(ra) # 80002a3c <argraw>
    80002b56:	c088                	sw	a0,0(s1)
}
    80002b58:	60e2                	ld	ra,24(sp)
    80002b5a:	6442                	ld	s0,16(sp)
    80002b5c:	64a2                	ld	s1,8(sp)
    80002b5e:	6105                	addi	sp,sp,32
    80002b60:	8082                	ret

0000000080002b62 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002b62:	1101                	addi	sp,sp,-32
    80002b64:	ec06                	sd	ra,24(sp)
    80002b66:	e822                	sd	s0,16(sp)
    80002b68:	e426                	sd	s1,8(sp)
    80002b6a:	1000                	addi	s0,sp,32
    80002b6c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b6e:	00000097          	auipc	ra,0x0
    80002b72:	ece080e7          	jalr	-306(ra) # 80002a3c <argraw>
    80002b76:	e088                	sd	a0,0(s1)
}
    80002b78:	60e2                	ld	ra,24(sp)
    80002b7a:	6442                	ld	s0,16(sp)
    80002b7c:	64a2                	ld	s1,8(sp)
    80002b7e:	6105                	addi	sp,sp,32
    80002b80:	8082                	ret

0000000080002b82 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b82:	7179                	addi	sp,sp,-48
    80002b84:	f406                	sd	ra,40(sp)
    80002b86:	f022                	sd	s0,32(sp)
    80002b88:	ec26                	sd	s1,24(sp)
    80002b8a:	e84a                	sd	s2,16(sp)
    80002b8c:	1800                	addi	s0,sp,48
    80002b8e:	84ae                	mv	s1,a1
    80002b90:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002b92:	fd840593          	addi	a1,s0,-40
    80002b96:	00000097          	auipc	ra,0x0
    80002b9a:	fcc080e7          	jalr	-52(ra) # 80002b62 <argaddr>
  return fetchstr(addr, buf, max);
    80002b9e:	864a                	mv	a2,s2
    80002ba0:	85a6                	mv	a1,s1
    80002ba2:	fd843503          	ld	a0,-40(s0)
    80002ba6:	00000097          	auipc	ra,0x0
    80002baa:	f50080e7          	jalr	-176(ra) # 80002af6 <fetchstr>
}
    80002bae:	70a2                	ld	ra,40(sp)
    80002bb0:	7402                	ld	s0,32(sp)
    80002bb2:	64e2                	ld	s1,24(sp)
    80002bb4:	6942                	ld	s2,16(sp)
    80002bb6:	6145                	addi	sp,sp,48
    80002bb8:	8082                	ret

0000000080002bba <syscall>:
[SYS_sigreturn] "sigreturn ",
};

void
syscall(void)
{
    80002bba:	7179                	addi	sp,sp,-48
    80002bbc:	f406                	sd	ra,40(sp)
    80002bbe:	f022                	sd	s0,32(sp)
    80002bc0:	ec26                	sd	s1,24(sp)
    80002bc2:	e84a                	sd	s2,16(sp)
    80002bc4:	e44e                	sd	s3,8(sp)
    80002bc6:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80002bc8:	fffff097          	auipc	ra,0xfffff
    80002bcc:	dfe080e7          	jalr	-514(ra) # 800019c6 <myproc>
    80002bd0:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002bd2:	05853903          	ld	s2,88(a0)
    80002bd6:	0a893783          	ld	a5,168(s2)
    80002bda:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002bde:	37fd                	addiw	a5,a5,-1
    80002be0:	4761                	li	a4,24
    80002be2:	04f76763          	bltu	a4,a5,80002c30 <syscall+0x76>
    80002be6:	00399713          	slli	a4,s3,0x3
    80002bea:	00006797          	auipc	a5,0x6
    80002bee:	94678793          	addi	a5,a5,-1722 # 80008530 <syscalls>
    80002bf2:	97ba                	add	a5,a5,a4
    80002bf4:	639c                	ld	a5,0(a5)
    80002bf6:	cf8d                	beqz	a5,80002c30 <syscall+0x76>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002bf8:	9782                	jalr	a5
    80002bfa:	06a93823          	sd	a0,112(s2)

    // Check for trace_flag to be on
    if(p->trace_flag >> num) {  // check for '=='
    80002bfe:	1684a783          	lw	a5,360(s1)
    80002c02:	4137d7bb          	sraw	a5,a5,s3
    80002c06:	c7a1                	beqz	a5,80002c4e <syscall+0x94>
      printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0);
    80002c08:	6cb8                	ld	a4,88(s1)
    80002c0a:	098e                	slli	s3,s3,0x3
    80002c0c:	00006797          	auipc	a5,0x6
    80002c10:	d7c78793          	addi	a5,a5,-644 # 80008988 <syscall_names>
    80002c14:	99be                	add	s3,s3,a5
    80002c16:	7b34                	ld	a3,112(a4)
    80002c18:	0009b603          	ld	a2,0(s3)
    80002c1c:	588c                	lw	a1,48(s1)
    80002c1e:	00005517          	auipc	a0,0x5
    80002c22:	7fa50513          	addi	a0,a0,2042 # 80008418 <states.1727+0x150>
    80002c26:	ffffe097          	auipc	ra,0xffffe
    80002c2a:	968080e7          	jalr	-1688(ra) # 8000058e <printf>
    80002c2e:	a005                	j	80002c4e <syscall+0x94>
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c30:	86ce                	mv	a3,s3
    80002c32:	15848613          	addi	a2,s1,344
    80002c36:	588c                	lw	a1,48(s1)
    80002c38:	00005517          	auipc	a0,0x5
    80002c3c:	7f850513          	addi	a0,a0,2040 # 80008430 <states.1727+0x168>
    80002c40:	ffffe097          	auipc	ra,0xffffe
    80002c44:	94e080e7          	jalr	-1714(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c48:	6cbc                	ld	a5,88(s1)
    80002c4a:	577d                	li	a4,-1
    80002c4c:	fbb8                	sd	a4,112(a5)
  }
}
    80002c4e:	70a2                	ld	ra,40(sp)
    80002c50:	7402                	ld	s0,32(sp)
    80002c52:	64e2                	ld	s1,24(sp)
    80002c54:	6942                	ld	s2,16(sp)
    80002c56:	69a2                	ld	s3,8(sp)
    80002c58:	6145                	addi	sp,sp,48
    80002c5a:	8082                	ret

0000000080002c5c <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c5c:	1101                	addi	sp,sp,-32
    80002c5e:	ec06                	sd	ra,24(sp)
    80002c60:	e822                	sd	s0,16(sp)
    80002c62:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002c64:	fec40593          	addi	a1,s0,-20
    80002c68:	4501                	li	a0,0
    80002c6a:	00000097          	auipc	ra,0x0
    80002c6e:	ed8080e7          	jalr	-296(ra) # 80002b42 <argint>
  exit(n);
    80002c72:	fec42503          	lw	a0,-20(s0)
    80002c76:	fffff097          	auipc	ra,0xfffff
    80002c7a:	530080e7          	jalr	1328(ra) # 800021a6 <exit>
  return 0;  // not reached
}
    80002c7e:	4501                	li	a0,0
    80002c80:	60e2                	ld	ra,24(sp)
    80002c82:	6442                	ld	s0,16(sp)
    80002c84:	6105                	addi	sp,sp,32
    80002c86:	8082                	ret

0000000080002c88 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c88:	1141                	addi	sp,sp,-16
    80002c8a:	e406                	sd	ra,8(sp)
    80002c8c:	e022                	sd	s0,0(sp)
    80002c8e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c90:	fffff097          	auipc	ra,0xfffff
    80002c94:	d36080e7          	jalr	-714(ra) # 800019c6 <myproc>
}
    80002c98:	5908                	lw	a0,48(a0)
    80002c9a:	60a2                	ld	ra,8(sp)
    80002c9c:	6402                	ld	s0,0(sp)
    80002c9e:	0141                	addi	sp,sp,16
    80002ca0:	8082                	ret

0000000080002ca2 <sys_fork>:

uint64
sys_fork(void)
{
    80002ca2:	1141                	addi	sp,sp,-16
    80002ca4:	e406                	sd	ra,8(sp)
    80002ca6:	e022                	sd	s0,0(sp)
    80002ca8:	0800                	addi	s0,sp,16
  return fork();
    80002caa:	fffff097          	auipc	ra,0xfffff
    80002cae:	0d2080e7          	jalr	210(ra) # 80001d7c <fork>
}
    80002cb2:	60a2                	ld	ra,8(sp)
    80002cb4:	6402                	ld	s0,0(sp)
    80002cb6:	0141                	addi	sp,sp,16
    80002cb8:	8082                	ret

0000000080002cba <sys_wait>:

uint64
sys_wait(void)
{
    80002cba:	1101                	addi	sp,sp,-32
    80002cbc:	ec06                	sd	ra,24(sp)
    80002cbe:	e822                	sd	s0,16(sp)
    80002cc0:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002cc2:	fe840593          	addi	a1,s0,-24
    80002cc6:	4501                	li	a0,0
    80002cc8:	00000097          	auipc	ra,0x0
    80002ccc:	e9a080e7          	jalr	-358(ra) # 80002b62 <argaddr>
  return wait(p);
    80002cd0:	fe843503          	ld	a0,-24(s0)
    80002cd4:	fffff097          	auipc	ra,0xfffff
    80002cd8:	678080e7          	jalr	1656(ra) # 8000234c <wait>
}
    80002cdc:	60e2                	ld	ra,24(sp)
    80002cde:	6442                	ld	s0,16(sp)
    80002ce0:	6105                	addi	sp,sp,32
    80002ce2:	8082                	ret

0000000080002ce4 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002ce4:	7179                	addi	sp,sp,-48
    80002ce6:	f406                	sd	ra,40(sp)
    80002ce8:	f022                	sd	s0,32(sp)
    80002cea:	ec26                	sd	s1,24(sp)
    80002cec:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002cee:	fdc40593          	addi	a1,s0,-36
    80002cf2:	4501                	li	a0,0
    80002cf4:	00000097          	auipc	ra,0x0
    80002cf8:	e4e080e7          	jalr	-434(ra) # 80002b42 <argint>
  addr = myproc()->sz;
    80002cfc:	fffff097          	auipc	ra,0xfffff
    80002d00:	cca080e7          	jalr	-822(ra) # 800019c6 <myproc>
    80002d04:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002d06:	fdc42503          	lw	a0,-36(s0)
    80002d0a:	fffff097          	auipc	ra,0xfffff
    80002d0e:	016080e7          	jalr	22(ra) # 80001d20 <growproc>
    80002d12:	00054863          	bltz	a0,80002d22 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002d16:	8526                	mv	a0,s1
    80002d18:	70a2                	ld	ra,40(sp)
    80002d1a:	7402                	ld	s0,32(sp)
    80002d1c:	64e2                	ld	s1,24(sp)
    80002d1e:	6145                	addi	sp,sp,48
    80002d20:	8082                	ret
    return -1;
    80002d22:	54fd                	li	s1,-1
    80002d24:	bfcd                	j	80002d16 <sys_sbrk+0x32>

0000000080002d26 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d26:	7139                	addi	sp,sp,-64
    80002d28:	fc06                	sd	ra,56(sp)
    80002d2a:	f822                	sd	s0,48(sp)
    80002d2c:	f426                	sd	s1,40(sp)
    80002d2e:	f04a                	sd	s2,32(sp)
    80002d30:	ec4e                	sd	s3,24(sp)
    80002d32:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002d34:	fcc40593          	addi	a1,s0,-52
    80002d38:	4501                	li	a0,0
    80002d3a:	00000097          	auipc	ra,0x0
    80002d3e:	e08080e7          	jalr	-504(ra) # 80002b42 <argint>
  acquire(&tickslock);
    80002d42:	00014517          	auipc	a0,0x14
    80002d46:	60e50513          	addi	a0,a0,1550 # 80017350 <tickslock>
    80002d4a:	ffffe097          	auipc	ra,0xffffe
    80002d4e:	ea0080e7          	jalr	-352(ra) # 80000bea <acquire>
  ticks0 = ticks;
    80002d52:	00006917          	auipc	s2,0x6
    80002d56:	d5e92903          	lw	s2,-674(s2) # 80008ab0 <ticks>
  while(ticks - ticks0 < n){
    80002d5a:	fcc42783          	lw	a5,-52(s0)
    80002d5e:	cf9d                	beqz	a5,80002d9c <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d60:	00014997          	auipc	s3,0x14
    80002d64:	5f098993          	addi	s3,s3,1520 # 80017350 <tickslock>
    80002d68:	00006497          	auipc	s1,0x6
    80002d6c:	d4848493          	addi	s1,s1,-696 # 80008ab0 <ticks>
    if(killed(myproc())){
    80002d70:	fffff097          	auipc	ra,0xfffff
    80002d74:	c56080e7          	jalr	-938(ra) # 800019c6 <myproc>
    80002d78:	fffff097          	auipc	ra,0xfffff
    80002d7c:	5a2080e7          	jalr	1442(ra) # 8000231a <killed>
    80002d80:	ed15                	bnez	a0,80002dbc <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002d82:	85ce                	mv	a1,s3
    80002d84:	8526                	mv	a0,s1
    80002d86:	fffff097          	auipc	ra,0xfffff
    80002d8a:	2ec080e7          	jalr	748(ra) # 80002072 <sleep>
  while(ticks - ticks0 < n){
    80002d8e:	409c                	lw	a5,0(s1)
    80002d90:	412787bb          	subw	a5,a5,s2
    80002d94:	fcc42703          	lw	a4,-52(s0)
    80002d98:	fce7ece3          	bltu	a5,a4,80002d70 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002d9c:	00014517          	auipc	a0,0x14
    80002da0:	5b450513          	addi	a0,a0,1460 # 80017350 <tickslock>
    80002da4:	ffffe097          	auipc	ra,0xffffe
    80002da8:	efa080e7          	jalr	-262(ra) # 80000c9e <release>
  return 0;
    80002dac:	4501                	li	a0,0
}
    80002dae:	70e2                	ld	ra,56(sp)
    80002db0:	7442                	ld	s0,48(sp)
    80002db2:	74a2                	ld	s1,40(sp)
    80002db4:	7902                	ld	s2,32(sp)
    80002db6:	69e2                	ld	s3,24(sp)
    80002db8:	6121                	addi	sp,sp,64
    80002dba:	8082                	ret
      release(&tickslock);
    80002dbc:	00014517          	auipc	a0,0x14
    80002dc0:	59450513          	addi	a0,a0,1428 # 80017350 <tickslock>
    80002dc4:	ffffe097          	auipc	ra,0xffffe
    80002dc8:	eda080e7          	jalr	-294(ra) # 80000c9e <release>
      return -1;
    80002dcc:	557d                	li	a0,-1
    80002dce:	b7c5                	j	80002dae <sys_sleep+0x88>

0000000080002dd0 <sys_kill>:

uint64
sys_kill(void)
{
    80002dd0:	1101                	addi	sp,sp,-32
    80002dd2:	ec06                	sd	ra,24(sp)
    80002dd4:	e822                	sd	s0,16(sp)
    80002dd6:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002dd8:	fec40593          	addi	a1,s0,-20
    80002ddc:	4501                	li	a0,0
    80002dde:	00000097          	auipc	ra,0x0
    80002de2:	d64080e7          	jalr	-668(ra) # 80002b42 <argint>
  return kill(pid);
    80002de6:	fec42503          	lw	a0,-20(s0)
    80002dea:	fffff097          	auipc	ra,0xfffff
    80002dee:	492080e7          	jalr	1170(ra) # 8000227c <kill>
}
    80002df2:	60e2                	ld	ra,24(sp)
    80002df4:	6442                	ld	s0,16(sp)
    80002df6:	6105                	addi	sp,sp,32
    80002df8:	8082                	ret

0000000080002dfa <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002dfa:	1101                	addi	sp,sp,-32
    80002dfc:	ec06                	sd	ra,24(sp)
    80002dfe:	e822                	sd	s0,16(sp)
    80002e00:	e426                	sd	s1,8(sp)
    80002e02:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e04:	00014517          	auipc	a0,0x14
    80002e08:	54c50513          	addi	a0,a0,1356 # 80017350 <tickslock>
    80002e0c:	ffffe097          	auipc	ra,0xffffe
    80002e10:	dde080e7          	jalr	-546(ra) # 80000bea <acquire>
  xticks = ticks;
    80002e14:	00006497          	auipc	s1,0x6
    80002e18:	c9c4a483          	lw	s1,-868(s1) # 80008ab0 <ticks>
  release(&tickslock);
    80002e1c:	00014517          	auipc	a0,0x14
    80002e20:	53450513          	addi	a0,a0,1332 # 80017350 <tickslock>
    80002e24:	ffffe097          	auipc	ra,0xffffe
    80002e28:	e7a080e7          	jalr	-390(ra) # 80000c9e <release>
  return xticks;
}
    80002e2c:	02049513          	slli	a0,s1,0x20
    80002e30:	9101                	srli	a0,a0,0x20
    80002e32:	60e2                	ld	ra,24(sp)
    80002e34:	6442                	ld	s0,16(sp)
    80002e36:	64a2                	ld	s1,8(sp)
    80002e38:	6105                	addi	sp,sp,32
    80002e3a:	8082                	ret

0000000080002e3c <sys_trace>:

// sets the trace_flag to the first argument (a0)
uint64
sys_trace(void)
{
    80002e3c:	1141                	addi	sp,sp,-16
    80002e3e:	e406                	sd	ra,8(sp)
    80002e40:	e022                	sd	s0,0(sp)
    80002e42:	0800                	addi	s0,sp,16
  argint(0, &myproc()->trace_flag); //arg(a0, trace_flag) // returns void
    80002e44:	fffff097          	auipc	ra,0xfffff
    80002e48:	b82080e7          	jalr	-1150(ra) # 800019c6 <myproc>
    80002e4c:	16850593          	addi	a1,a0,360
    80002e50:	4501                	li	a0,0
    80002e52:	00000097          	auipc	ra,0x0
    80002e56:	cf0080e7          	jalr	-784(ra) # 80002b42 <argint>
  return 0;
}
    80002e5a:	4501                	li	a0,0
    80002e5c:	60a2                	ld	ra,8(sp)
    80002e5e:	6402                	ld	s0,0(sp)
    80002e60:	0141                	addi	sp,sp,16
    80002e62:	8082                	ret

0000000080002e64 <sys_sigalarm>:

// sets the 
uint64
sys_sigalarm(void)
{
    80002e64:	1101                	addi	sp,sp,-32
    80002e66:	ec06                	sd	ra,24(sp)
    80002e68:	e822                	sd	s0,16(sp)
    80002e6a:	e426                	sd	s1,8(sp)
    80002e6c:	1000                	addi	s0,sp,32
  // sets the interval and handler after every tick
  argint(0, &myproc()->interval);
    80002e6e:	fffff097          	auipc	ra,0xfffff
    80002e72:	b58080e7          	jalr	-1192(ra) # 800019c6 <myproc>
    80002e76:	16c50593          	addi	a1,a0,364
    80002e7a:	4501                	li	a0,0
    80002e7c:	00000097          	auipc	ra,0x0
    80002e80:	cc6080e7          	jalr	-826(ra) # 80002b42 <argint>
  argaddr(1, &myproc()->sig_handler);
    80002e84:	fffff097          	auipc	ra,0xfffff
    80002e88:	b42080e7          	jalr	-1214(ra) # 800019c6 <myproc>
    80002e8c:	17850593          	addi	a1,a0,376
    80002e90:	4505                	li	a0,1
    80002e92:	00000097          	auipc	ra,0x0
    80002e96:	cd0080e7          	jalr	-816(ra) # 80002b62 <argaddr>
  
  // sets ticks_passed as the interval
  myproc()->ticks_left = myproc()->interval;
    80002e9a:	fffff097          	auipc	ra,0xfffff
    80002e9e:	b2c080e7          	jalr	-1236(ra) # 800019c6 <myproc>
    80002ea2:	84aa                	mv	s1,a0
    80002ea4:	fffff097          	auipc	ra,0xfffff
    80002ea8:	b22080e7          	jalr	-1246(ra) # 800019c6 <myproc>
    80002eac:	16c4a783          	lw	a5,364(s1)
    80002eb0:	16f52823          	sw	a5,368(a0)
  return 0;
}
    80002eb4:	4501                	li	a0,0
    80002eb6:	60e2                	ld	ra,24(sp)
    80002eb8:	6442                	ld	s0,16(sp)
    80002eba:	64a2                	ld	s1,8(sp)
    80002ebc:	6105                	addi	sp,sp,32
    80002ebe:	8082                	ret

0000000080002ec0 <sys_sigreturn>:

uint64 
sys_sigreturn(void)
{
    80002ec0:	1101                	addi	sp,sp,-32
    80002ec2:	ec06                	sd	ra,24(sp)
    80002ec4:	e822                	sd	s0,16(sp)
    80002ec6:	e426                	sd	s1,8(sp)
    80002ec8:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002eca:	fffff097          	auipc	ra,0xfffff
    80002ece:	afc080e7          	jalr	-1284(ra) # 800019c6 <myproc>
    80002ed2:	84aa                	mv	s1,a0
  memmove(p->trapframe, p->sigalarm_tf, PGSIZE);
    80002ed4:	6605                	lui	a2,0x1
    80002ed6:	18053583          	ld	a1,384(a0)
    80002eda:	6d28                	ld	a0,88(a0)
    80002edc:	ffffe097          	auipc	ra,0xffffe
    80002ee0:	e6a080e7          	jalr	-406(ra) # 80000d46 <memmove>
  kfree(p->sigalarm_tf);
    80002ee4:	1804b503          	ld	a0,384(s1)
    80002ee8:	ffffe097          	auipc	ra,0xffffe
    80002eec:	b16080e7          	jalr	-1258(ra) # 800009fe <kfree>
  p->ticks_left = p->interval;
    80002ef0:	16c4a783          	lw	a5,364(s1)
    80002ef4:	16f4a823          	sw	a5,368(s1)
  return p->trapframe->a0;
    80002ef8:	6cbc                	ld	a5,88(s1)
    80002efa:	7ba8                	ld	a0,112(a5)
    80002efc:	60e2                	ld	ra,24(sp)
    80002efe:	6442                	ld	s0,16(sp)
    80002f00:	64a2                	ld	s1,8(sp)
    80002f02:	6105                	addi	sp,sp,32
    80002f04:	8082                	ret

0000000080002f06 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f06:	7179                	addi	sp,sp,-48
    80002f08:	f406                	sd	ra,40(sp)
    80002f0a:	f022                	sd	s0,32(sp)
    80002f0c:	ec26                	sd	s1,24(sp)
    80002f0e:	e84a                	sd	s2,16(sp)
    80002f10:	e44e                	sd	s3,8(sp)
    80002f12:	e052                	sd	s4,0(sp)
    80002f14:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f16:	00005597          	auipc	a1,0x5
    80002f1a:	6ea58593          	addi	a1,a1,1770 # 80008600 <syscalls+0xd0>
    80002f1e:	00014517          	auipc	a0,0x14
    80002f22:	44a50513          	addi	a0,a0,1098 # 80017368 <bcache>
    80002f26:	ffffe097          	auipc	ra,0xffffe
    80002f2a:	c34080e7          	jalr	-972(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f2e:	0001c797          	auipc	a5,0x1c
    80002f32:	43a78793          	addi	a5,a5,1082 # 8001f368 <bcache+0x8000>
    80002f36:	0001c717          	auipc	a4,0x1c
    80002f3a:	69a70713          	addi	a4,a4,1690 # 8001f5d0 <bcache+0x8268>
    80002f3e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f42:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f46:	00014497          	auipc	s1,0x14
    80002f4a:	43a48493          	addi	s1,s1,1082 # 80017380 <bcache+0x18>
    b->next = bcache.head.next;
    80002f4e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f50:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f52:	00005a17          	auipc	s4,0x5
    80002f56:	6b6a0a13          	addi	s4,s4,1718 # 80008608 <syscalls+0xd8>
    b->next = bcache.head.next;
    80002f5a:	2b893783          	ld	a5,696(s2)
    80002f5e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f60:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f64:	85d2                	mv	a1,s4
    80002f66:	01048513          	addi	a0,s1,16
    80002f6a:	00001097          	auipc	ra,0x1
    80002f6e:	4c4080e7          	jalr	1220(ra) # 8000442e <initsleeplock>
    bcache.head.next->prev = b;
    80002f72:	2b893783          	ld	a5,696(s2)
    80002f76:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f78:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f7c:	45848493          	addi	s1,s1,1112
    80002f80:	fd349de3          	bne	s1,s3,80002f5a <binit+0x54>
  }
}
    80002f84:	70a2                	ld	ra,40(sp)
    80002f86:	7402                	ld	s0,32(sp)
    80002f88:	64e2                	ld	s1,24(sp)
    80002f8a:	6942                	ld	s2,16(sp)
    80002f8c:	69a2                	ld	s3,8(sp)
    80002f8e:	6a02                	ld	s4,0(sp)
    80002f90:	6145                	addi	sp,sp,48
    80002f92:	8082                	ret

0000000080002f94 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f94:	7179                	addi	sp,sp,-48
    80002f96:	f406                	sd	ra,40(sp)
    80002f98:	f022                	sd	s0,32(sp)
    80002f9a:	ec26                	sd	s1,24(sp)
    80002f9c:	e84a                	sd	s2,16(sp)
    80002f9e:	e44e                	sd	s3,8(sp)
    80002fa0:	1800                	addi	s0,sp,48
    80002fa2:	89aa                	mv	s3,a0
    80002fa4:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002fa6:	00014517          	auipc	a0,0x14
    80002faa:	3c250513          	addi	a0,a0,962 # 80017368 <bcache>
    80002fae:	ffffe097          	auipc	ra,0xffffe
    80002fb2:	c3c080e7          	jalr	-964(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fb6:	0001c497          	auipc	s1,0x1c
    80002fba:	66a4b483          	ld	s1,1642(s1) # 8001f620 <bcache+0x82b8>
    80002fbe:	0001c797          	auipc	a5,0x1c
    80002fc2:	61278793          	addi	a5,a5,1554 # 8001f5d0 <bcache+0x8268>
    80002fc6:	02f48f63          	beq	s1,a5,80003004 <bread+0x70>
    80002fca:	873e                	mv	a4,a5
    80002fcc:	a021                	j	80002fd4 <bread+0x40>
    80002fce:	68a4                	ld	s1,80(s1)
    80002fd0:	02e48a63          	beq	s1,a4,80003004 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002fd4:	449c                	lw	a5,8(s1)
    80002fd6:	ff379ce3          	bne	a5,s3,80002fce <bread+0x3a>
    80002fda:	44dc                	lw	a5,12(s1)
    80002fdc:	ff2799e3          	bne	a5,s2,80002fce <bread+0x3a>
      b->refcnt++;
    80002fe0:	40bc                	lw	a5,64(s1)
    80002fe2:	2785                	addiw	a5,a5,1
    80002fe4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fe6:	00014517          	auipc	a0,0x14
    80002fea:	38250513          	addi	a0,a0,898 # 80017368 <bcache>
    80002fee:	ffffe097          	auipc	ra,0xffffe
    80002ff2:	cb0080e7          	jalr	-848(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80002ff6:	01048513          	addi	a0,s1,16
    80002ffa:	00001097          	auipc	ra,0x1
    80002ffe:	46e080e7          	jalr	1134(ra) # 80004468 <acquiresleep>
      return b;
    80003002:	a8b9                	j	80003060 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003004:	0001c497          	auipc	s1,0x1c
    80003008:	6144b483          	ld	s1,1556(s1) # 8001f618 <bcache+0x82b0>
    8000300c:	0001c797          	auipc	a5,0x1c
    80003010:	5c478793          	addi	a5,a5,1476 # 8001f5d0 <bcache+0x8268>
    80003014:	00f48863          	beq	s1,a5,80003024 <bread+0x90>
    80003018:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000301a:	40bc                	lw	a5,64(s1)
    8000301c:	cf81                	beqz	a5,80003034 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000301e:	64a4                	ld	s1,72(s1)
    80003020:	fee49de3          	bne	s1,a4,8000301a <bread+0x86>
  panic("bget: no buffers");
    80003024:	00005517          	auipc	a0,0x5
    80003028:	5ec50513          	addi	a0,a0,1516 # 80008610 <syscalls+0xe0>
    8000302c:	ffffd097          	auipc	ra,0xffffd
    80003030:	518080e7          	jalr	1304(ra) # 80000544 <panic>
      b->dev = dev;
    80003034:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003038:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000303c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003040:	4785                	li	a5,1
    80003042:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003044:	00014517          	auipc	a0,0x14
    80003048:	32450513          	addi	a0,a0,804 # 80017368 <bcache>
    8000304c:	ffffe097          	auipc	ra,0xffffe
    80003050:	c52080e7          	jalr	-942(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80003054:	01048513          	addi	a0,s1,16
    80003058:	00001097          	auipc	ra,0x1
    8000305c:	410080e7          	jalr	1040(ra) # 80004468 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003060:	409c                	lw	a5,0(s1)
    80003062:	cb89                	beqz	a5,80003074 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003064:	8526                	mv	a0,s1
    80003066:	70a2                	ld	ra,40(sp)
    80003068:	7402                	ld	s0,32(sp)
    8000306a:	64e2                	ld	s1,24(sp)
    8000306c:	6942                	ld	s2,16(sp)
    8000306e:	69a2                	ld	s3,8(sp)
    80003070:	6145                	addi	sp,sp,48
    80003072:	8082                	ret
    virtio_disk_rw(b, 0);
    80003074:	4581                	li	a1,0
    80003076:	8526                	mv	a0,s1
    80003078:	00003097          	auipc	ra,0x3
    8000307c:	fd0080e7          	jalr	-48(ra) # 80006048 <virtio_disk_rw>
    b->valid = 1;
    80003080:	4785                	li	a5,1
    80003082:	c09c                	sw	a5,0(s1)
  return b;
    80003084:	b7c5                	j	80003064 <bread+0xd0>

0000000080003086 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003086:	1101                	addi	sp,sp,-32
    80003088:	ec06                	sd	ra,24(sp)
    8000308a:	e822                	sd	s0,16(sp)
    8000308c:	e426                	sd	s1,8(sp)
    8000308e:	1000                	addi	s0,sp,32
    80003090:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003092:	0541                	addi	a0,a0,16
    80003094:	00001097          	auipc	ra,0x1
    80003098:	46e080e7          	jalr	1134(ra) # 80004502 <holdingsleep>
    8000309c:	cd01                	beqz	a0,800030b4 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000309e:	4585                	li	a1,1
    800030a0:	8526                	mv	a0,s1
    800030a2:	00003097          	auipc	ra,0x3
    800030a6:	fa6080e7          	jalr	-90(ra) # 80006048 <virtio_disk_rw>
}
    800030aa:	60e2                	ld	ra,24(sp)
    800030ac:	6442                	ld	s0,16(sp)
    800030ae:	64a2                	ld	s1,8(sp)
    800030b0:	6105                	addi	sp,sp,32
    800030b2:	8082                	ret
    panic("bwrite");
    800030b4:	00005517          	auipc	a0,0x5
    800030b8:	57450513          	addi	a0,a0,1396 # 80008628 <syscalls+0xf8>
    800030bc:	ffffd097          	auipc	ra,0xffffd
    800030c0:	488080e7          	jalr	1160(ra) # 80000544 <panic>

00000000800030c4 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030c4:	1101                	addi	sp,sp,-32
    800030c6:	ec06                	sd	ra,24(sp)
    800030c8:	e822                	sd	s0,16(sp)
    800030ca:	e426                	sd	s1,8(sp)
    800030cc:	e04a                	sd	s2,0(sp)
    800030ce:	1000                	addi	s0,sp,32
    800030d0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030d2:	01050913          	addi	s2,a0,16
    800030d6:	854a                	mv	a0,s2
    800030d8:	00001097          	auipc	ra,0x1
    800030dc:	42a080e7          	jalr	1066(ra) # 80004502 <holdingsleep>
    800030e0:	c92d                	beqz	a0,80003152 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030e2:	854a                	mv	a0,s2
    800030e4:	00001097          	auipc	ra,0x1
    800030e8:	3da080e7          	jalr	986(ra) # 800044be <releasesleep>

  acquire(&bcache.lock);
    800030ec:	00014517          	auipc	a0,0x14
    800030f0:	27c50513          	addi	a0,a0,636 # 80017368 <bcache>
    800030f4:	ffffe097          	auipc	ra,0xffffe
    800030f8:	af6080e7          	jalr	-1290(ra) # 80000bea <acquire>
  b->refcnt--;
    800030fc:	40bc                	lw	a5,64(s1)
    800030fe:	37fd                	addiw	a5,a5,-1
    80003100:	0007871b          	sext.w	a4,a5
    80003104:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003106:	eb05                	bnez	a4,80003136 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003108:	68bc                	ld	a5,80(s1)
    8000310a:	64b8                	ld	a4,72(s1)
    8000310c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000310e:	64bc                	ld	a5,72(s1)
    80003110:	68b8                	ld	a4,80(s1)
    80003112:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003114:	0001c797          	auipc	a5,0x1c
    80003118:	25478793          	addi	a5,a5,596 # 8001f368 <bcache+0x8000>
    8000311c:	2b87b703          	ld	a4,696(a5)
    80003120:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003122:	0001c717          	auipc	a4,0x1c
    80003126:	4ae70713          	addi	a4,a4,1198 # 8001f5d0 <bcache+0x8268>
    8000312a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000312c:	2b87b703          	ld	a4,696(a5)
    80003130:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003132:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003136:	00014517          	auipc	a0,0x14
    8000313a:	23250513          	addi	a0,a0,562 # 80017368 <bcache>
    8000313e:	ffffe097          	auipc	ra,0xffffe
    80003142:	b60080e7          	jalr	-1184(ra) # 80000c9e <release>
}
    80003146:	60e2                	ld	ra,24(sp)
    80003148:	6442                	ld	s0,16(sp)
    8000314a:	64a2                	ld	s1,8(sp)
    8000314c:	6902                	ld	s2,0(sp)
    8000314e:	6105                	addi	sp,sp,32
    80003150:	8082                	ret
    panic("brelse");
    80003152:	00005517          	auipc	a0,0x5
    80003156:	4de50513          	addi	a0,a0,1246 # 80008630 <syscalls+0x100>
    8000315a:	ffffd097          	auipc	ra,0xffffd
    8000315e:	3ea080e7          	jalr	1002(ra) # 80000544 <panic>

0000000080003162 <bpin>:

void
bpin(struct buf *b) {
    80003162:	1101                	addi	sp,sp,-32
    80003164:	ec06                	sd	ra,24(sp)
    80003166:	e822                	sd	s0,16(sp)
    80003168:	e426                	sd	s1,8(sp)
    8000316a:	1000                	addi	s0,sp,32
    8000316c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000316e:	00014517          	auipc	a0,0x14
    80003172:	1fa50513          	addi	a0,a0,506 # 80017368 <bcache>
    80003176:	ffffe097          	auipc	ra,0xffffe
    8000317a:	a74080e7          	jalr	-1420(ra) # 80000bea <acquire>
  b->refcnt++;
    8000317e:	40bc                	lw	a5,64(s1)
    80003180:	2785                	addiw	a5,a5,1
    80003182:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003184:	00014517          	auipc	a0,0x14
    80003188:	1e450513          	addi	a0,a0,484 # 80017368 <bcache>
    8000318c:	ffffe097          	auipc	ra,0xffffe
    80003190:	b12080e7          	jalr	-1262(ra) # 80000c9e <release>
}
    80003194:	60e2                	ld	ra,24(sp)
    80003196:	6442                	ld	s0,16(sp)
    80003198:	64a2                	ld	s1,8(sp)
    8000319a:	6105                	addi	sp,sp,32
    8000319c:	8082                	ret

000000008000319e <bunpin>:

void
bunpin(struct buf *b) {
    8000319e:	1101                	addi	sp,sp,-32
    800031a0:	ec06                	sd	ra,24(sp)
    800031a2:	e822                	sd	s0,16(sp)
    800031a4:	e426                	sd	s1,8(sp)
    800031a6:	1000                	addi	s0,sp,32
    800031a8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031aa:	00014517          	auipc	a0,0x14
    800031ae:	1be50513          	addi	a0,a0,446 # 80017368 <bcache>
    800031b2:	ffffe097          	auipc	ra,0xffffe
    800031b6:	a38080e7          	jalr	-1480(ra) # 80000bea <acquire>
  b->refcnt--;
    800031ba:	40bc                	lw	a5,64(s1)
    800031bc:	37fd                	addiw	a5,a5,-1
    800031be:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031c0:	00014517          	auipc	a0,0x14
    800031c4:	1a850513          	addi	a0,a0,424 # 80017368 <bcache>
    800031c8:	ffffe097          	auipc	ra,0xffffe
    800031cc:	ad6080e7          	jalr	-1322(ra) # 80000c9e <release>
}
    800031d0:	60e2                	ld	ra,24(sp)
    800031d2:	6442                	ld	s0,16(sp)
    800031d4:	64a2                	ld	s1,8(sp)
    800031d6:	6105                	addi	sp,sp,32
    800031d8:	8082                	ret

00000000800031da <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031da:	1101                	addi	sp,sp,-32
    800031dc:	ec06                	sd	ra,24(sp)
    800031de:	e822                	sd	s0,16(sp)
    800031e0:	e426                	sd	s1,8(sp)
    800031e2:	e04a                	sd	s2,0(sp)
    800031e4:	1000                	addi	s0,sp,32
    800031e6:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031e8:	00d5d59b          	srliw	a1,a1,0xd
    800031ec:	0001d797          	auipc	a5,0x1d
    800031f0:	8587a783          	lw	a5,-1960(a5) # 8001fa44 <sb+0x1c>
    800031f4:	9dbd                	addw	a1,a1,a5
    800031f6:	00000097          	auipc	ra,0x0
    800031fa:	d9e080e7          	jalr	-610(ra) # 80002f94 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031fe:	0074f713          	andi	a4,s1,7
    80003202:	4785                	li	a5,1
    80003204:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003208:	14ce                	slli	s1,s1,0x33
    8000320a:	90d9                	srli	s1,s1,0x36
    8000320c:	00950733          	add	a4,a0,s1
    80003210:	05874703          	lbu	a4,88(a4)
    80003214:	00e7f6b3          	and	a3,a5,a4
    80003218:	c69d                	beqz	a3,80003246 <bfree+0x6c>
    8000321a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000321c:	94aa                	add	s1,s1,a0
    8000321e:	fff7c793          	not	a5,a5
    80003222:	8ff9                	and	a5,a5,a4
    80003224:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003228:	00001097          	auipc	ra,0x1
    8000322c:	120080e7          	jalr	288(ra) # 80004348 <log_write>
  brelse(bp);
    80003230:	854a                	mv	a0,s2
    80003232:	00000097          	auipc	ra,0x0
    80003236:	e92080e7          	jalr	-366(ra) # 800030c4 <brelse>
}
    8000323a:	60e2                	ld	ra,24(sp)
    8000323c:	6442                	ld	s0,16(sp)
    8000323e:	64a2                	ld	s1,8(sp)
    80003240:	6902                	ld	s2,0(sp)
    80003242:	6105                	addi	sp,sp,32
    80003244:	8082                	ret
    panic("freeing free block");
    80003246:	00005517          	auipc	a0,0x5
    8000324a:	3f250513          	addi	a0,a0,1010 # 80008638 <syscalls+0x108>
    8000324e:	ffffd097          	auipc	ra,0xffffd
    80003252:	2f6080e7          	jalr	758(ra) # 80000544 <panic>

0000000080003256 <balloc>:
{
    80003256:	711d                	addi	sp,sp,-96
    80003258:	ec86                	sd	ra,88(sp)
    8000325a:	e8a2                	sd	s0,80(sp)
    8000325c:	e4a6                	sd	s1,72(sp)
    8000325e:	e0ca                	sd	s2,64(sp)
    80003260:	fc4e                	sd	s3,56(sp)
    80003262:	f852                	sd	s4,48(sp)
    80003264:	f456                	sd	s5,40(sp)
    80003266:	f05a                	sd	s6,32(sp)
    80003268:	ec5e                	sd	s7,24(sp)
    8000326a:	e862                	sd	s8,16(sp)
    8000326c:	e466                	sd	s9,8(sp)
    8000326e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003270:	0001c797          	auipc	a5,0x1c
    80003274:	7bc7a783          	lw	a5,1980(a5) # 8001fa2c <sb+0x4>
    80003278:	10078163          	beqz	a5,8000337a <balloc+0x124>
    8000327c:	8baa                	mv	s7,a0
    8000327e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003280:	0001cb17          	auipc	s6,0x1c
    80003284:	7a8b0b13          	addi	s6,s6,1960 # 8001fa28 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003288:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000328a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000328c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000328e:	6c89                	lui	s9,0x2
    80003290:	a061                	j	80003318 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003292:	974a                	add	a4,a4,s2
    80003294:	8fd5                	or	a5,a5,a3
    80003296:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000329a:	854a                	mv	a0,s2
    8000329c:	00001097          	auipc	ra,0x1
    800032a0:	0ac080e7          	jalr	172(ra) # 80004348 <log_write>
        brelse(bp);
    800032a4:	854a                	mv	a0,s2
    800032a6:	00000097          	auipc	ra,0x0
    800032aa:	e1e080e7          	jalr	-482(ra) # 800030c4 <brelse>
  bp = bread(dev, bno);
    800032ae:	85a6                	mv	a1,s1
    800032b0:	855e                	mv	a0,s7
    800032b2:	00000097          	auipc	ra,0x0
    800032b6:	ce2080e7          	jalr	-798(ra) # 80002f94 <bread>
    800032ba:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032bc:	40000613          	li	a2,1024
    800032c0:	4581                	li	a1,0
    800032c2:	05850513          	addi	a0,a0,88
    800032c6:	ffffe097          	auipc	ra,0xffffe
    800032ca:	a20080e7          	jalr	-1504(ra) # 80000ce6 <memset>
  log_write(bp);
    800032ce:	854a                	mv	a0,s2
    800032d0:	00001097          	auipc	ra,0x1
    800032d4:	078080e7          	jalr	120(ra) # 80004348 <log_write>
  brelse(bp);
    800032d8:	854a                	mv	a0,s2
    800032da:	00000097          	auipc	ra,0x0
    800032de:	dea080e7          	jalr	-534(ra) # 800030c4 <brelse>
}
    800032e2:	8526                	mv	a0,s1
    800032e4:	60e6                	ld	ra,88(sp)
    800032e6:	6446                	ld	s0,80(sp)
    800032e8:	64a6                	ld	s1,72(sp)
    800032ea:	6906                	ld	s2,64(sp)
    800032ec:	79e2                	ld	s3,56(sp)
    800032ee:	7a42                	ld	s4,48(sp)
    800032f0:	7aa2                	ld	s5,40(sp)
    800032f2:	7b02                	ld	s6,32(sp)
    800032f4:	6be2                	ld	s7,24(sp)
    800032f6:	6c42                	ld	s8,16(sp)
    800032f8:	6ca2                	ld	s9,8(sp)
    800032fa:	6125                	addi	sp,sp,96
    800032fc:	8082                	ret
    brelse(bp);
    800032fe:	854a                	mv	a0,s2
    80003300:	00000097          	auipc	ra,0x0
    80003304:	dc4080e7          	jalr	-572(ra) # 800030c4 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003308:	015c87bb          	addw	a5,s9,s5
    8000330c:	00078a9b          	sext.w	s5,a5
    80003310:	004b2703          	lw	a4,4(s6)
    80003314:	06eaf363          	bgeu	s5,a4,8000337a <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003318:	41fad79b          	sraiw	a5,s5,0x1f
    8000331c:	0137d79b          	srliw	a5,a5,0x13
    80003320:	015787bb          	addw	a5,a5,s5
    80003324:	40d7d79b          	sraiw	a5,a5,0xd
    80003328:	01cb2583          	lw	a1,28(s6)
    8000332c:	9dbd                	addw	a1,a1,a5
    8000332e:	855e                	mv	a0,s7
    80003330:	00000097          	auipc	ra,0x0
    80003334:	c64080e7          	jalr	-924(ra) # 80002f94 <bread>
    80003338:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000333a:	004b2503          	lw	a0,4(s6)
    8000333e:	000a849b          	sext.w	s1,s5
    80003342:	8662                	mv	a2,s8
    80003344:	faa4fde3          	bgeu	s1,a0,800032fe <balloc+0xa8>
      m = 1 << (bi % 8);
    80003348:	41f6579b          	sraiw	a5,a2,0x1f
    8000334c:	01d7d69b          	srliw	a3,a5,0x1d
    80003350:	00c6873b          	addw	a4,a3,a2
    80003354:	00777793          	andi	a5,a4,7
    80003358:	9f95                	subw	a5,a5,a3
    8000335a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000335e:	4037571b          	sraiw	a4,a4,0x3
    80003362:	00e906b3          	add	a3,s2,a4
    80003366:	0586c683          	lbu	a3,88(a3)
    8000336a:	00d7f5b3          	and	a1,a5,a3
    8000336e:	d195                	beqz	a1,80003292 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003370:	2605                	addiw	a2,a2,1
    80003372:	2485                	addiw	s1,s1,1
    80003374:	fd4618e3          	bne	a2,s4,80003344 <balloc+0xee>
    80003378:	b759                	j	800032fe <balloc+0xa8>
  printf("balloc: out of blocks\n");
    8000337a:	00005517          	auipc	a0,0x5
    8000337e:	2d650513          	addi	a0,a0,726 # 80008650 <syscalls+0x120>
    80003382:	ffffd097          	auipc	ra,0xffffd
    80003386:	20c080e7          	jalr	524(ra) # 8000058e <printf>
  return 0;
    8000338a:	4481                	li	s1,0
    8000338c:	bf99                	j	800032e2 <balloc+0x8c>

000000008000338e <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000338e:	7179                	addi	sp,sp,-48
    80003390:	f406                	sd	ra,40(sp)
    80003392:	f022                	sd	s0,32(sp)
    80003394:	ec26                	sd	s1,24(sp)
    80003396:	e84a                	sd	s2,16(sp)
    80003398:	e44e                	sd	s3,8(sp)
    8000339a:	e052                	sd	s4,0(sp)
    8000339c:	1800                	addi	s0,sp,48
    8000339e:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033a0:	47ad                	li	a5,11
    800033a2:	02b7e763          	bltu	a5,a1,800033d0 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800033a6:	02059493          	slli	s1,a1,0x20
    800033aa:	9081                	srli	s1,s1,0x20
    800033ac:	048a                	slli	s1,s1,0x2
    800033ae:	94aa                	add	s1,s1,a0
    800033b0:	0504a903          	lw	s2,80(s1)
    800033b4:	06091e63          	bnez	s2,80003430 <bmap+0xa2>
      addr = balloc(ip->dev);
    800033b8:	4108                	lw	a0,0(a0)
    800033ba:	00000097          	auipc	ra,0x0
    800033be:	e9c080e7          	jalr	-356(ra) # 80003256 <balloc>
    800033c2:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033c6:	06090563          	beqz	s2,80003430 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    800033ca:	0524a823          	sw	s2,80(s1)
    800033ce:	a08d                	j	80003430 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800033d0:	ff45849b          	addiw	s1,a1,-12
    800033d4:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033d8:	0ff00793          	li	a5,255
    800033dc:	08e7e563          	bltu	a5,a4,80003466 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800033e0:	08052903          	lw	s2,128(a0)
    800033e4:	00091d63          	bnez	s2,800033fe <bmap+0x70>
      addr = balloc(ip->dev);
    800033e8:	4108                	lw	a0,0(a0)
    800033ea:	00000097          	auipc	ra,0x0
    800033ee:	e6c080e7          	jalr	-404(ra) # 80003256 <balloc>
    800033f2:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033f6:	02090d63          	beqz	s2,80003430 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800033fa:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800033fe:	85ca                	mv	a1,s2
    80003400:	0009a503          	lw	a0,0(s3)
    80003404:	00000097          	auipc	ra,0x0
    80003408:	b90080e7          	jalr	-1136(ra) # 80002f94 <bread>
    8000340c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000340e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003412:	02049593          	slli	a1,s1,0x20
    80003416:	9181                	srli	a1,a1,0x20
    80003418:	058a                	slli	a1,a1,0x2
    8000341a:	00b784b3          	add	s1,a5,a1
    8000341e:	0004a903          	lw	s2,0(s1)
    80003422:	02090063          	beqz	s2,80003442 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003426:	8552                	mv	a0,s4
    80003428:	00000097          	auipc	ra,0x0
    8000342c:	c9c080e7          	jalr	-868(ra) # 800030c4 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003430:	854a                	mv	a0,s2
    80003432:	70a2                	ld	ra,40(sp)
    80003434:	7402                	ld	s0,32(sp)
    80003436:	64e2                	ld	s1,24(sp)
    80003438:	6942                	ld	s2,16(sp)
    8000343a:	69a2                	ld	s3,8(sp)
    8000343c:	6a02                	ld	s4,0(sp)
    8000343e:	6145                	addi	sp,sp,48
    80003440:	8082                	ret
      addr = balloc(ip->dev);
    80003442:	0009a503          	lw	a0,0(s3)
    80003446:	00000097          	auipc	ra,0x0
    8000344a:	e10080e7          	jalr	-496(ra) # 80003256 <balloc>
    8000344e:	0005091b          	sext.w	s2,a0
      if(addr){
    80003452:	fc090ae3          	beqz	s2,80003426 <bmap+0x98>
        a[bn] = addr;
    80003456:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000345a:	8552                	mv	a0,s4
    8000345c:	00001097          	auipc	ra,0x1
    80003460:	eec080e7          	jalr	-276(ra) # 80004348 <log_write>
    80003464:	b7c9                	j	80003426 <bmap+0x98>
  panic("bmap: out of range");
    80003466:	00005517          	auipc	a0,0x5
    8000346a:	20250513          	addi	a0,a0,514 # 80008668 <syscalls+0x138>
    8000346e:	ffffd097          	auipc	ra,0xffffd
    80003472:	0d6080e7          	jalr	214(ra) # 80000544 <panic>

0000000080003476 <iget>:
{
    80003476:	7179                	addi	sp,sp,-48
    80003478:	f406                	sd	ra,40(sp)
    8000347a:	f022                	sd	s0,32(sp)
    8000347c:	ec26                	sd	s1,24(sp)
    8000347e:	e84a                	sd	s2,16(sp)
    80003480:	e44e                	sd	s3,8(sp)
    80003482:	e052                	sd	s4,0(sp)
    80003484:	1800                	addi	s0,sp,48
    80003486:	89aa                	mv	s3,a0
    80003488:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000348a:	0001c517          	auipc	a0,0x1c
    8000348e:	5be50513          	addi	a0,a0,1470 # 8001fa48 <itable>
    80003492:	ffffd097          	auipc	ra,0xffffd
    80003496:	758080e7          	jalr	1880(ra) # 80000bea <acquire>
  empty = 0;
    8000349a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000349c:	0001c497          	auipc	s1,0x1c
    800034a0:	5c448493          	addi	s1,s1,1476 # 8001fa60 <itable+0x18>
    800034a4:	0001e697          	auipc	a3,0x1e
    800034a8:	04c68693          	addi	a3,a3,76 # 800214f0 <log>
    800034ac:	a039                	j	800034ba <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034ae:	02090b63          	beqz	s2,800034e4 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034b2:	08848493          	addi	s1,s1,136
    800034b6:	02d48a63          	beq	s1,a3,800034ea <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034ba:	449c                	lw	a5,8(s1)
    800034bc:	fef059e3          	blez	a5,800034ae <iget+0x38>
    800034c0:	4098                	lw	a4,0(s1)
    800034c2:	ff3716e3          	bne	a4,s3,800034ae <iget+0x38>
    800034c6:	40d8                	lw	a4,4(s1)
    800034c8:	ff4713e3          	bne	a4,s4,800034ae <iget+0x38>
      ip->ref++;
    800034cc:	2785                	addiw	a5,a5,1
    800034ce:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800034d0:	0001c517          	auipc	a0,0x1c
    800034d4:	57850513          	addi	a0,a0,1400 # 8001fa48 <itable>
    800034d8:	ffffd097          	auipc	ra,0xffffd
    800034dc:	7c6080e7          	jalr	1990(ra) # 80000c9e <release>
      return ip;
    800034e0:	8926                	mv	s2,s1
    800034e2:	a03d                	j	80003510 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034e4:	f7f9                	bnez	a5,800034b2 <iget+0x3c>
    800034e6:	8926                	mv	s2,s1
    800034e8:	b7e9                	j	800034b2 <iget+0x3c>
  if(empty == 0)
    800034ea:	02090c63          	beqz	s2,80003522 <iget+0xac>
  ip->dev = dev;
    800034ee:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034f2:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034f6:	4785                	li	a5,1
    800034f8:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034fc:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003500:	0001c517          	auipc	a0,0x1c
    80003504:	54850513          	addi	a0,a0,1352 # 8001fa48 <itable>
    80003508:	ffffd097          	auipc	ra,0xffffd
    8000350c:	796080e7          	jalr	1942(ra) # 80000c9e <release>
}
    80003510:	854a                	mv	a0,s2
    80003512:	70a2                	ld	ra,40(sp)
    80003514:	7402                	ld	s0,32(sp)
    80003516:	64e2                	ld	s1,24(sp)
    80003518:	6942                	ld	s2,16(sp)
    8000351a:	69a2                	ld	s3,8(sp)
    8000351c:	6a02                	ld	s4,0(sp)
    8000351e:	6145                	addi	sp,sp,48
    80003520:	8082                	ret
    panic("iget: no inodes");
    80003522:	00005517          	auipc	a0,0x5
    80003526:	15e50513          	addi	a0,a0,350 # 80008680 <syscalls+0x150>
    8000352a:	ffffd097          	auipc	ra,0xffffd
    8000352e:	01a080e7          	jalr	26(ra) # 80000544 <panic>

0000000080003532 <fsinit>:
fsinit(int dev) {
    80003532:	7179                	addi	sp,sp,-48
    80003534:	f406                	sd	ra,40(sp)
    80003536:	f022                	sd	s0,32(sp)
    80003538:	ec26                	sd	s1,24(sp)
    8000353a:	e84a                	sd	s2,16(sp)
    8000353c:	e44e                	sd	s3,8(sp)
    8000353e:	1800                	addi	s0,sp,48
    80003540:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003542:	4585                	li	a1,1
    80003544:	00000097          	auipc	ra,0x0
    80003548:	a50080e7          	jalr	-1456(ra) # 80002f94 <bread>
    8000354c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000354e:	0001c997          	auipc	s3,0x1c
    80003552:	4da98993          	addi	s3,s3,1242 # 8001fa28 <sb>
    80003556:	02000613          	li	a2,32
    8000355a:	05850593          	addi	a1,a0,88
    8000355e:	854e                	mv	a0,s3
    80003560:	ffffd097          	auipc	ra,0xffffd
    80003564:	7e6080e7          	jalr	2022(ra) # 80000d46 <memmove>
  brelse(bp);
    80003568:	8526                	mv	a0,s1
    8000356a:	00000097          	auipc	ra,0x0
    8000356e:	b5a080e7          	jalr	-1190(ra) # 800030c4 <brelse>
  if(sb.magic != FSMAGIC)
    80003572:	0009a703          	lw	a4,0(s3)
    80003576:	102037b7          	lui	a5,0x10203
    8000357a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000357e:	02f71263          	bne	a4,a5,800035a2 <fsinit+0x70>
  initlog(dev, &sb);
    80003582:	0001c597          	auipc	a1,0x1c
    80003586:	4a658593          	addi	a1,a1,1190 # 8001fa28 <sb>
    8000358a:	854a                	mv	a0,s2
    8000358c:	00001097          	auipc	ra,0x1
    80003590:	b40080e7          	jalr	-1216(ra) # 800040cc <initlog>
}
    80003594:	70a2                	ld	ra,40(sp)
    80003596:	7402                	ld	s0,32(sp)
    80003598:	64e2                	ld	s1,24(sp)
    8000359a:	6942                	ld	s2,16(sp)
    8000359c:	69a2                	ld	s3,8(sp)
    8000359e:	6145                	addi	sp,sp,48
    800035a0:	8082                	ret
    panic("invalid file system");
    800035a2:	00005517          	auipc	a0,0x5
    800035a6:	0ee50513          	addi	a0,a0,238 # 80008690 <syscalls+0x160>
    800035aa:	ffffd097          	auipc	ra,0xffffd
    800035ae:	f9a080e7          	jalr	-102(ra) # 80000544 <panic>

00000000800035b2 <iinit>:
{
    800035b2:	7179                	addi	sp,sp,-48
    800035b4:	f406                	sd	ra,40(sp)
    800035b6:	f022                	sd	s0,32(sp)
    800035b8:	ec26                	sd	s1,24(sp)
    800035ba:	e84a                	sd	s2,16(sp)
    800035bc:	e44e                	sd	s3,8(sp)
    800035be:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800035c0:	00005597          	auipc	a1,0x5
    800035c4:	0e858593          	addi	a1,a1,232 # 800086a8 <syscalls+0x178>
    800035c8:	0001c517          	auipc	a0,0x1c
    800035cc:	48050513          	addi	a0,a0,1152 # 8001fa48 <itable>
    800035d0:	ffffd097          	auipc	ra,0xffffd
    800035d4:	58a080e7          	jalr	1418(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    800035d8:	0001c497          	auipc	s1,0x1c
    800035dc:	49848493          	addi	s1,s1,1176 # 8001fa70 <itable+0x28>
    800035e0:	0001e997          	auipc	s3,0x1e
    800035e4:	f2098993          	addi	s3,s3,-224 # 80021500 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800035e8:	00005917          	auipc	s2,0x5
    800035ec:	0c890913          	addi	s2,s2,200 # 800086b0 <syscalls+0x180>
    800035f0:	85ca                	mv	a1,s2
    800035f2:	8526                	mv	a0,s1
    800035f4:	00001097          	auipc	ra,0x1
    800035f8:	e3a080e7          	jalr	-454(ra) # 8000442e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035fc:	08848493          	addi	s1,s1,136
    80003600:	ff3498e3          	bne	s1,s3,800035f0 <iinit+0x3e>
}
    80003604:	70a2                	ld	ra,40(sp)
    80003606:	7402                	ld	s0,32(sp)
    80003608:	64e2                	ld	s1,24(sp)
    8000360a:	6942                	ld	s2,16(sp)
    8000360c:	69a2                	ld	s3,8(sp)
    8000360e:	6145                	addi	sp,sp,48
    80003610:	8082                	ret

0000000080003612 <ialloc>:
{
    80003612:	715d                	addi	sp,sp,-80
    80003614:	e486                	sd	ra,72(sp)
    80003616:	e0a2                	sd	s0,64(sp)
    80003618:	fc26                	sd	s1,56(sp)
    8000361a:	f84a                	sd	s2,48(sp)
    8000361c:	f44e                	sd	s3,40(sp)
    8000361e:	f052                	sd	s4,32(sp)
    80003620:	ec56                	sd	s5,24(sp)
    80003622:	e85a                	sd	s6,16(sp)
    80003624:	e45e                	sd	s7,8(sp)
    80003626:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003628:	0001c717          	auipc	a4,0x1c
    8000362c:	40c72703          	lw	a4,1036(a4) # 8001fa34 <sb+0xc>
    80003630:	4785                	li	a5,1
    80003632:	04e7fa63          	bgeu	a5,a4,80003686 <ialloc+0x74>
    80003636:	8aaa                	mv	s5,a0
    80003638:	8bae                	mv	s7,a1
    8000363a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000363c:	0001ca17          	auipc	s4,0x1c
    80003640:	3eca0a13          	addi	s4,s4,1004 # 8001fa28 <sb>
    80003644:	00048b1b          	sext.w	s6,s1
    80003648:	0044d593          	srli	a1,s1,0x4
    8000364c:	018a2783          	lw	a5,24(s4)
    80003650:	9dbd                	addw	a1,a1,a5
    80003652:	8556                	mv	a0,s5
    80003654:	00000097          	auipc	ra,0x0
    80003658:	940080e7          	jalr	-1728(ra) # 80002f94 <bread>
    8000365c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000365e:	05850993          	addi	s3,a0,88
    80003662:	00f4f793          	andi	a5,s1,15
    80003666:	079a                	slli	a5,a5,0x6
    80003668:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000366a:	00099783          	lh	a5,0(s3)
    8000366e:	c3a1                	beqz	a5,800036ae <ialloc+0x9c>
    brelse(bp);
    80003670:	00000097          	auipc	ra,0x0
    80003674:	a54080e7          	jalr	-1452(ra) # 800030c4 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003678:	0485                	addi	s1,s1,1
    8000367a:	00ca2703          	lw	a4,12(s4)
    8000367e:	0004879b          	sext.w	a5,s1
    80003682:	fce7e1e3          	bltu	a5,a4,80003644 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003686:	00005517          	auipc	a0,0x5
    8000368a:	03250513          	addi	a0,a0,50 # 800086b8 <syscalls+0x188>
    8000368e:	ffffd097          	auipc	ra,0xffffd
    80003692:	f00080e7          	jalr	-256(ra) # 8000058e <printf>
  return 0;
    80003696:	4501                	li	a0,0
}
    80003698:	60a6                	ld	ra,72(sp)
    8000369a:	6406                	ld	s0,64(sp)
    8000369c:	74e2                	ld	s1,56(sp)
    8000369e:	7942                	ld	s2,48(sp)
    800036a0:	79a2                	ld	s3,40(sp)
    800036a2:	7a02                	ld	s4,32(sp)
    800036a4:	6ae2                	ld	s5,24(sp)
    800036a6:	6b42                	ld	s6,16(sp)
    800036a8:	6ba2                	ld	s7,8(sp)
    800036aa:	6161                	addi	sp,sp,80
    800036ac:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800036ae:	04000613          	li	a2,64
    800036b2:	4581                	li	a1,0
    800036b4:	854e                	mv	a0,s3
    800036b6:	ffffd097          	auipc	ra,0xffffd
    800036ba:	630080e7          	jalr	1584(ra) # 80000ce6 <memset>
      dip->type = type;
    800036be:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036c2:	854a                	mv	a0,s2
    800036c4:	00001097          	auipc	ra,0x1
    800036c8:	c84080e7          	jalr	-892(ra) # 80004348 <log_write>
      brelse(bp);
    800036cc:	854a                	mv	a0,s2
    800036ce:	00000097          	auipc	ra,0x0
    800036d2:	9f6080e7          	jalr	-1546(ra) # 800030c4 <brelse>
      return iget(dev, inum);
    800036d6:	85da                	mv	a1,s6
    800036d8:	8556                	mv	a0,s5
    800036da:	00000097          	auipc	ra,0x0
    800036de:	d9c080e7          	jalr	-612(ra) # 80003476 <iget>
    800036e2:	bf5d                	j	80003698 <ialloc+0x86>

00000000800036e4 <iupdate>:
{
    800036e4:	1101                	addi	sp,sp,-32
    800036e6:	ec06                	sd	ra,24(sp)
    800036e8:	e822                	sd	s0,16(sp)
    800036ea:	e426                	sd	s1,8(sp)
    800036ec:	e04a                	sd	s2,0(sp)
    800036ee:	1000                	addi	s0,sp,32
    800036f0:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036f2:	415c                	lw	a5,4(a0)
    800036f4:	0047d79b          	srliw	a5,a5,0x4
    800036f8:	0001c597          	auipc	a1,0x1c
    800036fc:	3485a583          	lw	a1,840(a1) # 8001fa40 <sb+0x18>
    80003700:	9dbd                	addw	a1,a1,a5
    80003702:	4108                	lw	a0,0(a0)
    80003704:	00000097          	auipc	ra,0x0
    80003708:	890080e7          	jalr	-1904(ra) # 80002f94 <bread>
    8000370c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000370e:	05850793          	addi	a5,a0,88
    80003712:	40c8                	lw	a0,4(s1)
    80003714:	893d                	andi	a0,a0,15
    80003716:	051a                	slli	a0,a0,0x6
    80003718:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000371a:	04449703          	lh	a4,68(s1)
    8000371e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003722:	04649703          	lh	a4,70(s1)
    80003726:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000372a:	04849703          	lh	a4,72(s1)
    8000372e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003732:	04a49703          	lh	a4,74(s1)
    80003736:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000373a:	44f8                	lw	a4,76(s1)
    8000373c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000373e:	03400613          	li	a2,52
    80003742:	05048593          	addi	a1,s1,80
    80003746:	0531                	addi	a0,a0,12
    80003748:	ffffd097          	auipc	ra,0xffffd
    8000374c:	5fe080e7          	jalr	1534(ra) # 80000d46 <memmove>
  log_write(bp);
    80003750:	854a                	mv	a0,s2
    80003752:	00001097          	auipc	ra,0x1
    80003756:	bf6080e7          	jalr	-1034(ra) # 80004348 <log_write>
  brelse(bp);
    8000375a:	854a                	mv	a0,s2
    8000375c:	00000097          	auipc	ra,0x0
    80003760:	968080e7          	jalr	-1688(ra) # 800030c4 <brelse>
}
    80003764:	60e2                	ld	ra,24(sp)
    80003766:	6442                	ld	s0,16(sp)
    80003768:	64a2                	ld	s1,8(sp)
    8000376a:	6902                	ld	s2,0(sp)
    8000376c:	6105                	addi	sp,sp,32
    8000376e:	8082                	ret

0000000080003770 <idup>:
{
    80003770:	1101                	addi	sp,sp,-32
    80003772:	ec06                	sd	ra,24(sp)
    80003774:	e822                	sd	s0,16(sp)
    80003776:	e426                	sd	s1,8(sp)
    80003778:	1000                	addi	s0,sp,32
    8000377a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000377c:	0001c517          	auipc	a0,0x1c
    80003780:	2cc50513          	addi	a0,a0,716 # 8001fa48 <itable>
    80003784:	ffffd097          	auipc	ra,0xffffd
    80003788:	466080e7          	jalr	1126(ra) # 80000bea <acquire>
  ip->ref++;
    8000378c:	449c                	lw	a5,8(s1)
    8000378e:	2785                	addiw	a5,a5,1
    80003790:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003792:	0001c517          	auipc	a0,0x1c
    80003796:	2b650513          	addi	a0,a0,694 # 8001fa48 <itable>
    8000379a:	ffffd097          	auipc	ra,0xffffd
    8000379e:	504080e7          	jalr	1284(ra) # 80000c9e <release>
}
    800037a2:	8526                	mv	a0,s1
    800037a4:	60e2                	ld	ra,24(sp)
    800037a6:	6442                	ld	s0,16(sp)
    800037a8:	64a2                	ld	s1,8(sp)
    800037aa:	6105                	addi	sp,sp,32
    800037ac:	8082                	ret

00000000800037ae <ilock>:
{
    800037ae:	1101                	addi	sp,sp,-32
    800037b0:	ec06                	sd	ra,24(sp)
    800037b2:	e822                	sd	s0,16(sp)
    800037b4:	e426                	sd	s1,8(sp)
    800037b6:	e04a                	sd	s2,0(sp)
    800037b8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037ba:	c115                	beqz	a0,800037de <ilock+0x30>
    800037bc:	84aa                	mv	s1,a0
    800037be:	451c                	lw	a5,8(a0)
    800037c0:	00f05f63          	blez	a5,800037de <ilock+0x30>
  acquiresleep(&ip->lock);
    800037c4:	0541                	addi	a0,a0,16
    800037c6:	00001097          	auipc	ra,0x1
    800037ca:	ca2080e7          	jalr	-862(ra) # 80004468 <acquiresleep>
  if(ip->valid == 0){
    800037ce:	40bc                	lw	a5,64(s1)
    800037d0:	cf99                	beqz	a5,800037ee <ilock+0x40>
}
    800037d2:	60e2                	ld	ra,24(sp)
    800037d4:	6442                	ld	s0,16(sp)
    800037d6:	64a2                	ld	s1,8(sp)
    800037d8:	6902                	ld	s2,0(sp)
    800037da:	6105                	addi	sp,sp,32
    800037dc:	8082                	ret
    panic("ilock");
    800037de:	00005517          	auipc	a0,0x5
    800037e2:	ef250513          	addi	a0,a0,-270 # 800086d0 <syscalls+0x1a0>
    800037e6:	ffffd097          	auipc	ra,0xffffd
    800037ea:	d5e080e7          	jalr	-674(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037ee:	40dc                	lw	a5,4(s1)
    800037f0:	0047d79b          	srliw	a5,a5,0x4
    800037f4:	0001c597          	auipc	a1,0x1c
    800037f8:	24c5a583          	lw	a1,588(a1) # 8001fa40 <sb+0x18>
    800037fc:	9dbd                	addw	a1,a1,a5
    800037fe:	4088                	lw	a0,0(s1)
    80003800:	fffff097          	auipc	ra,0xfffff
    80003804:	794080e7          	jalr	1940(ra) # 80002f94 <bread>
    80003808:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000380a:	05850593          	addi	a1,a0,88
    8000380e:	40dc                	lw	a5,4(s1)
    80003810:	8bbd                	andi	a5,a5,15
    80003812:	079a                	slli	a5,a5,0x6
    80003814:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003816:	00059783          	lh	a5,0(a1)
    8000381a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000381e:	00259783          	lh	a5,2(a1)
    80003822:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003826:	00459783          	lh	a5,4(a1)
    8000382a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000382e:	00659783          	lh	a5,6(a1)
    80003832:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003836:	459c                	lw	a5,8(a1)
    80003838:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000383a:	03400613          	li	a2,52
    8000383e:	05b1                	addi	a1,a1,12
    80003840:	05048513          	addi	a0,s1,80
    80003844:	ffffd097          	auipc	ra,0xffffd
    80003848:	502080e7          	jalr	1282(ra) # 80000d46 <memmove>
    brelse(bp);
    8000384c:	854a                	mv	a0,s2
    8000384e:	00000097          	auipc	ra,0x0
    80003852:	876080e7          	jalr	-1930(ra) # 800030c4 <brelse>
    ip->valid = 1;
    80003856:	4785                	li	a5,1
    80003858:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000385a:	04449783          	lh	a5,68(s1)
    8000385e:	fbb5                	bnez	a5,800037d2 <ilock+0x24>
      panic("ilock: no type");
    80003860:	00005517          	auipc	a0,0x5
    80003864:	e7850513          	addi	a0,a0,-392 # 800086d8 <syscalls+0x1a8>
    80003868:	ffffd097          	auipc	ra,0xffffd
    8000386c:	cdc080e7          	jalr	-804(ra) # 80000544 <panic>

0000000080003870 <iunlock>:
{
    80003870:	1101                	addi	sp,sp,-32
    80003872:	ec06                	sd	ra,24(sp)
    80003874:	e822                	sd	s0,16(sp)
    80003876:	e426                	sd	s1,8(sp)
    80003878:	e04a                	sd	s2,0(sp)
    8000387a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000387c:	c905                	beqz	a0,800038ac <iunlock+0x3c>
    8000387e:	84aa                	mv	s1,a0
    80003880:	01050913          	addi	s2,a0,16
    80003884:	854a                	mv	a0,s2
    80003886:	00001097          	auipc	ra,0x1
    8000388a:	c7c080e7          	jalr	-900(ra) # 80004502 <holdingsleep>
    8000388e:	cd19                	beqz	a0,800038ac <iunlock+0x3c>
    80003890:	449c                	lw	a5,8(s1)
    80003892:	00f05d63          	blez	a5,800038ac <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003896:	854a                	mv	a0,s2
    80003898:	00001097          	auipc	ra,0x1
    8000389c:	c26080e7          	jalr	-986(ra) # 800044be <releasesleep>
}
    800038a0:	60e2                	ld	ra,24(sp)
    800038a2:	6442                	ld	s0,16(sp)
    800038a4:	64a2                	ld	s1,8(sp)
    800038a6:	6902                	ld	s2,0(sp)
    800038a8:	6105                	addi	sp,sp,32
    800038aa:	8082                	ret
    panic("iunlock");
    800038ac:	00005517          	auipc	a0,0x5
    800038b0:	e3c50513          	addi	a0,a0,-452 # 800086e8 <syscalls+0x1b8>
    800038b4:	ffffd097          	auipc	ra,0xffffd
    800038b8:	c90080e7          	jalr	-880(ra) # 80000544 <panic>

00000000800038bc <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038bc:	7179                	addi	sp,sp,-48
    800038be:	f406                	sd	ra,40(sp)
    800038c0:	f022                	sd	s0,32(sp)
    800038c2:	ec26                	sd	s1,24(sp)
    800038c4:	e84a                	sd	s2,16(sp)
    800038c6:	e44e                	sd	s3,8(sp)
    800038c8:	e052                	sd	s4,0(sp)
    800038ca:	1800                	addi	s0,sp,48
    800038cc:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038ce:	05050493          	addi	s1,a0,80
    800038d2:	08050913          	addi	s2,a0,128
    800038d6:	a021                	j	800038de <itrunc+0x22>
    800038d8:	0491                	addi	s1,s1,4
    800038da:	01248d63          	beq	s1,s2,800038f4 <itrunc+0x38>
    if(ip->addrs[i]){
    800038de:	408c                	lw	a1,0(s1)
    800038e0:	dde5                	beqz	a1,800038d8 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038e2:	0009a503          	lw	a0,0(s3)
    800038e6:	00000097          	auipc	ra,0x0
    800038ea:	8f4080e7          	jalr	-1804(ra) # 800031da <bfree>
      ip->addrs[i] = 0;
    800038ee:	0004a023          	sw	zero,0(s1)
    800038f2:	b7dd                	j	800038d8 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038f4:	0809a583          	lw	a1,128(s3)
    800038f8:	e185                	bnez	a1,80003918 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038fa:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038fe:	854e                	mv	a0,s3
    80003900:	00000097          	auipc	ra,0x0
    80003904:	de4080e7          	jalr	-540(ra) # 800036e4 <iupdate>
}
    80003908:	70a2                	ld	ra,40(sp)
    8000390a:	7402                	ld	s0,32(sp)
    8000390c:	64e2                	ld	s1,24(sp)
    8000390e:	6942                	ld	s2,16(sp)
    80003910:	69a2                	ld	s3,8(sp)
    80003912:	6a02                	ld	s4,0(sp)
    80003914:	6145                	addi	sp,sp,48
    80003916:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003918:	0009a503          	lw	a0,0(s3)
    8000391c:	fffff097          	auipc	ra,0xfffff
    80003920:	678080e7          	jalr	1656(ra) # 80002f94 <bread>
    80003924:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003926:	05850493          	addi	s1,a0,88
    8000392a:	45850913          	addi	s2,a0,1112
    8000392e:	a811                	j	80003942 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003930:	0009a503          	lw	a0,0(s3)
    80003934:	00000097          	auipc	ra,0x0
    80003938:	8a6080e7          	jalr	-1882(ra) # 800031da <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000393c:	0491                	addi	s1,s1,4
    8000393e:	01248563          	beq	s1,s2,80003948 <itrunc+0x8c>
      if(a[j])
    80003942:	408c                	lw	a1,0(s1)
    80003944:	dde5                	beqz	a1,8000393c <itrunc+0x80>
    80003946:	b7ed                	j	80003930 <itrunc+0x74>
    brelse(bp);
    80003948:	8552                	mv	a0,s4
    8000394a:	fffff097          	auipc	ra,0xfffff
    8000394e:	77a080e7          	jalr	1914(ra) # 800030c4 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003952:	0809a583          	lw	a1,128(s3)
    80003956:	0009a503          	lw	a0,0(s3)
    8000395a:	00000097          	auipc	ra,0x0
    8000395e:	880080e7          	jalr	-1920(ra) # 800031da <bfree>
    ip->addrs[NDIRECT] = 0;
    80003962:	0809a023          	sw	zero,128(s3)
    80003966:	bf51                	j	800038fa <itrunc+0x3e>

0000000080003968 <iput>:
{
    80003968:	1101                	addi	sp,sp,-32
    8000396a:	ec06                	sd	ra,24(sp)
    8000396c:	e822                	sd	s0,16(sp)
    8000396e:	e426                	sd	s1,8(sp)
    80003970:	e04a                	sd	s2,0(sp)
    80003972:	1000                	addi	s0,sp,32
    80003974:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003976:	0001c517          	auipc	a0,0x1c
    8000397a:	0d250513          	addi	a0,a0,210 # 8001fa48 <itable>
    8000397e:	ffffd097          	auipc	ra,0xffffd
    80003982:	26c080e7          	jalr	620(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003986:	4498                	lw	a4,8(s1)
    80003988:	4785                	li	a5,1
    8000398a:	02f70363          	beq	a4,a5,800039b0 <iput+0x48>
  ip->ref--;
    8000398e:	449c                	lw	a5,8(s1)
    80003990:	37fd                	addiw	a5,a5,-1
    80003992:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003994:	0001c517          	auipc	a0,0x1c
    80003998:	0b450513          	addi	a0,a0,180 # 8001fa48 <itable>
    8000399c:	ffffd097          	auipc	ra,0xffffd
    800039a0:	302080e7          	jalr	770(ra) # 80000c9e <release>
}
    800039a4:	60e2                	ld	ra,24(sp)
    800039a6:	6442                	ld	s0,16(sp)
    800039a8:	64a2                	ld	s1,8(sp)
    800039aa:	6902                	ld	s2,0(sp)
    800039ac:	6105                	addi	sp,sp,32
    800039ae:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039b0:	40bc                	lw	a5,64(s1)
    800039b2:	dff1                	beqz	a5,8000398e <iput+0x26>
    800039b4:	04a49783          	lh	a5,74(s1)
    800039b8:	fbf9                	bnez	a5,8000398e <iput+0x26>
    acquiresleep(&ip->lock);
    800039ba:	01048913          	addi	s2,s1,16
    800039be:	854a                	mv	a0,s2
    800039c0:	00001097          	auipc	ra,0x1
    800039c4:	aa8080e7          	jalr	-1368(ra) # 80004468 <acquiresleep>
    release(&itable.lock);
    800039c8:	0001c517          	auipc	a0,0x1c
    800039cc:	08050513          	addi	a0,a0,128 # 8001fa48 <itable>
    800039d0:	ffffd097          	auipc	ra,0xffffd
    800039d4:	2ce080e7          	jalr	718(ra) # 80000c9e <release>
    itrunc(ip);
    800039d8:	8526                	mv	a0,s1
    800039da:	00000097          	auipc	ra,0x0
    800039de:	ee2080e7          	jalr	-286(ra) # 800038bc <itrunc>
    ip->type = 0;
    800039e2:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039e6:	8526                	mv	a0,s1
    800039e8:	00000097          	auipc	ra,0x0
    800039ec:	cfc080e7          	jalr	-772(ra) # 800036e4 <iupdate>
    ip->valid = 0;
    800039f0:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039f4:	854a                	mv	a0,s2
    800039f6:	00001097          	auipc	ra,0x1
    800039fa:	ac8080e7          	jalr	-1336(ra) # 800044be <releasesleep>
    acquire(&itable.lock);
    800039fe:	0001c517          	auipc	a0,0x1c
    80003a02:	04a50513          	addi	a0,a0,74 # 8001fa48 <itable>
    80003a06:	ffffd097          	auipc	ra,0xffffd
    80003a0a:	1e4080e7          	jalr	484(ra) # 80000bea <acquire>
    80003a0e:	b741                	j	8000398e <iput+0x26>

0000000080003a10 <iunlockput>:
{
    80003a10:	1101                	addi	sp,sp,-32
    80003a12:	ec06                	sd	ra,24(sp)
    80003a14:	e822                	sd	s0,16(sp)
    80003a16:	e426                	sd	s1,8(sp)
    80003a18:	1000                	addi	s0,sp,32
    80003a1a:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a1c:	00000097          	auipc	ra,0x0
    80003a20:	e54080e7          	jalr	-428(ra) # 80003870 <iunlock>
  iput(ip);
    80003a24:	8526                	mv	a0,s1
    80003a26:	00000097          	auipc	ra,0x0
    80003a2a:	f42080e7          	jalr	-190(ra) # 80003968 <iput>
}
    80003a2e:	60e2                	ld	ra,24(sp)
    80003a30:	6442                	ld	s0,16(sp)
    80003a32:	64a2                	ld	s1,8(sp)
    80003a34:	6105                	addi	sp,sp,32
    80003a36:	8082                	ret

0000000080003a38 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a38:	1141                	addi	sp,sp,-16
    80003a3a:	e422                	sd	s0,8(sp)
    80003a3c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a3e:	411c                	lw	a5,0(a0)
    80003a40:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a42:	415c                	lw	a5,4(a0)
    80003a44:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a46:	04451783          	lh	a5,68(a0)
    80003a4a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a4e:	04a51783          	lh	a5,74(a0)
    80003a52:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a56:	04c56783          	lwu	a5,76(a0)
    80003a5a:	e99c                	sd	a5,16(a1)
}
    80003a5c:	6422                	ld	s0,8(sp)
    80003a5e:	0141                	addi	sp,sp,16
    80003a60:	8082                	ret

0000000080003a62 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a62:	457c                	lw	a5,76(a0)
    80003a64:	0ed7e963          	bltu	a5,a3,80003b56 <readi+0xf4>
{
    80003a68:	7159                	addi	sp,sp,-112
    80003a6a:	f486                	sd	ra,104(sp)
    80003a6c:	f0a2                	sd	s0,96(sp)
    80003a6e:	eca6                	sd	s1,88(sp)
    80003a70:	e8ca                	sd	s2,80(sp)
    80003a72:	e4ce                	sd	s3,72(sp)
    80003a74:	e0d2                	sd	s4,64(sp)
    80003a76:	fc56                	sd	s5,56(sp)
    80003a78:	f85a                	sd	s6,48(sp)
    80003a7a:	f45e                	sd	s7,40(sp)
    80003a7c:	f062                	sd	s8,32(sp)
    80003a7e:	ec66                	sd	s9,24(sp)
    80003a80:	e86a                	sd	s10,16(sp)
    80003a82:	e46e                	sd	s11,8(sp)
    80003a84:	1880                	addi	s0,sp,112
    80003a86:	8b2a                	mv	s6,a0
    80003a88:	8bae                	mv	s7,a1
    80003a8a:	8a32                	mv	s4,a2
    80003a8c:	84b6                	mv	s1,a3
    80003a8e:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003a90:	9f35                	addw	a4,a4,a3
    return 0;
    80003a92:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a94:	0ad76063          	bltu	a4,a3,80003b34 <readi+0xd2>
  if(off + n > ip->size)
    80003a98:	00e7f463          	bgeu	a5,a4,80003aa0 <readi+0x3e>
    n = ip->size - off;
    80003a9c:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003aa0:	0a0a8963          	beqz	s5,80003b52 <readi+0xf0>
    80003aa4:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aa6:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003aaa:	5c7d                	li	s8,-1
    80003aac:	a82d                	j	80003ae6 <readi+0x84>
    80003aae:	020d1d93          	slli	s11,s10,0x20
    80003ab2:	020ddd93          	srli	s11,s11,0x20
    80003ab6:	05890613          	addi	a2,s2,88
    80003aba:	86ee                	mv	a3,s11
    80003abc:	963a                	add	a2,a2,a4
    80003abe:	85d2                	mv	a1,s4
    80003ac0:	855e                	mv	a0,s7
    80003ac2:	fffff097          	auipc	ra,0xfffff
    80003ac6:	9b8080e7          	jalr	-1608(ra) # 8000247a <either_copyout>
    80003aca:	05850d63          	beq	a0,s8,80003b24 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ace:	854a                	mv	a0,s2
    80003ad0:	fffff097          	auipc	ra,0xfffff
    80003ad4:	5f4080e7          	jalr	1524(ra) # 800030c4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ad8:	013d09bb          	addw	s3,s10,s3
    80003adc:	009d04bb          	addw	s1,s10,s1
    80003ae0:	9a6e                	add	s4,s4,s11
    80003ae2:	0559f763          	bgeu	s3,s5,80003b30 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003ae6:	00a4d59b          	srliw	a1,s1,0xa
    80003aea:	855a                	mv	a0,s6
    80003aec:	00000097          	auipc	ra,0x0
    80003af0:	8a2080e7          	jalr	-1886(ra) # 8000338e <bmap>
    80003af4:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003af8:	cd85                	beqz	a1,80003b30 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003afa:	000b2503          	lw	a0,0(s6)
    80003afe:	fffff097          	auipc	ra,0xfffff
    80003b02:	496080e7          	jalr	1174(ra) # 80002f94 <bread>
    80003b06:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b08:	3ff4f713          	andi	a4,s1,1023
    80003b0c:	40ec87bb          	subw	a5,s9,a4
    80003b10:	413a86bb          	subw	a3,s5,s3
    80003b14:	8d3e                	mv	s10,a5
    80003b16:	2781                	sext.w	a5,a5
    80003b18:	0006861b          	sext.w	a2,a3
    80003b1c:	f8f679e3          	bgeu	a2,a5,80003aae <readi+0x4c>
    80003b20:	8d36                	mv	s10,a3
    80003b22:	b771                	j	80003aae <readi+0x4c>
      brelse(bp);
    80003b24:	854a                	mv	a0,s2
    80003b26:	fffff097          	auipc	ra,0xfffff
    80003b2a:	59e080e7          	jalr	1438(ra) # 800030c4 <brelse>
      tot = -1;
    80003b2e:	59fd                	li	s3,-1
  }
  return tot;
    80003b30:	0009851b          	sext.w	a0,s3
}
    80003b34:	70a6                	ld	ra,104(sp)
    80003b36:	7406                	ld	s0,96(sp)
    80003b38:	64e6                	ld	s1,88(sp)
    80003b3a:	6946                	ld	s2,80(sp)
    80003b3c:	69a6                	ld	s3,72(sp)
    80003b3e:	6a06                	ld	s4,64(sp)
    80003b40:	7ae2                	ld	s5,56(sp)
    80003b42:	7b42                	ld	s6,48(sp)
    80003b44:	7ba2                	ld	s7,40(sp)
    80003b46:	7c02                	ld	s8,32(sp)
    80003b48:	6ce2                	ld	s9,24(sp)
    80003b4a:	6d42                	ld	s10,16(sp)
    80003b4c:	6da2                	ld	s11,8(sp)
    80003b4e:	6165                	addi	sp,sp,112
    80003b50:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b52:	89d6                	mv	s3,s5
    80003b54:	bff1                	j	80003b30 <readi+0xce>
    return 0;
    80003b56:	4501                	li	a0,0
}
    80003b58:	8082                	ret

0000000080003b5a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b5a:	457c                	lw	a5,76(a0)
    80003b5c:	10d7e863          	bltu	a5,a3,80003c6c <writei+0x112>
{
    80003b60:	7159                	addi	sp,sp,-112
    80003b62:	f486                	sd	ra,104(sp)
    80003b64:	f0a2                	sd	s0,96(sp)
    80003b66:	eca6                	sd	s1,88(sp)
    80003b68:	e8ca                	sd	s2,80(sp)
    80003b6a:	e4ce                	sd	s3,72(sp)
    80003b6c:	e0d2                	sd	s4,64(sp)
    80003b6e:	fc56                	sd	s5,56(sp)
    80003b70:	f85a                	sd	s6,48(sp)
    80003b72:	f45e                	sd	s7,40(sp)
    80003b74:	f062                	sd	s8,32(sp)
    80003b76:	ec66                	sd	s9,24(sp)
    80003b78:	e86a                	sd	s10,16(sp)
    80003b7a:	e46e                	sd	s11,8(sp)
    80003b7c:	1880                	addi	s0,sp,112
    80003b7e:	8aaa                	mv	s5,a0
    80003b80:	8bae                	mv	s7,a1
    80003b82:	8a32                	mv	s4,a2
    80003b84:	8936                	mv	s2,a3
    80003b86:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b88:	00e687bb          	addw	a5,a3,a4
    80003b8c:	0ed7e263          	bltu	a5,a3,80003c70 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b90:	00043737          	lui	a4,0x43
    80003b94:	0ef76063          	bltu	a4,a5,80003c74 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b98:	0c0b0863          	beqz	s6,80003c68 <writei+0x10e>
    80003b9c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b9e:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003ba2:	5c7d                	li	s8,-1
    80003ba4:	a091                	j	80003be8 <writei+0x8e>
    80003ba6:	020d1d93          	slli	s11,s10,0x20
    80003baa:	020ddd93          	srli	s11,s11,0x20
    80003bae:	05848513          	addi	a0,s1,88
    80003bb2:	86ee                	mv	a3,s11
    80003bb4:	8652                	mv	a2,s4
    80003bb6:	85de                	mv	a1,s7
    80003bb8:	953a                	add	a0,a0,a4
    80003bba:	fffff097          	auipc	ra,0xfffff
    80003bbe:	916080e7          	jalr	-1770(ra) # 800024d0 <either_copyin>
    80003bc2:	07850263          	beq	a0,s8,80003c26 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003bc6:	8526                	mv	a0,s1
    80003bc8:	00000097          	auipc	ra,0x0
    80003bcc:	780080e7          	jalr	1920(ra) # 80004348 <log_write>
    brelse(bp);
    80003bd0:	8526                	mv	a0,s1
    80003bd2:	fffff097          	auipc	ra,0xfffff
    80003bd6:	4f2080e7          	jalr	1266(ra) # 800030c4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bda:	013d09bb          	addw	s3,s10,s3
    80003bde:	012d093b          	addw	s2,s10,s2
    80003be2:	9a6e                	add	s4,s4,s11
    80003be4:	0569f663          	bgeu	s3,s6,80003c30 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003be8:	00a9559b          	srliw	a1,s2,0xa
    80003bec:	8556                	mv	a0,s5
    80003bee:	fffff097          	auipc	ra,0xfffff
    80003bf2:	7a0080e7          	jalr	1952(ra) # 8000338e <bmap>
    80003bf6:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003bfa:	c99d                	beqz	a1,80003c30 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003bfc:	000aa503          	lw	a0,0(s5)
    80003c00:	fffff097          	auipc	ra,0xfffff
    80003c04:	394080e7          	jalr	916(ra) # 80002f94 <bread>
    80003c08:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c0a:	3ff97713          	andi	a4,s2,1023
    80003c0e:	40ec87bb          	subw	a5,s9,a4
    80003c12:	413b06bb          	subw	a3,s6,s3
    80003c16:	8d3e                	mv	s10,a5
    80003c18:	2781                	sext.w	a5,a5
    80003c1a:	0006861b          	sext.w	a2,a3
    80003c1e:	f8f674e3          	bgeu	a2,a5,80003ba6 <writei+0x4c>
    80003c22:	8d36                	mv	s10,a3
    80003c24:	b749                	j	80003ba6 <writei+0x4c>
      brelse(bp);
    80003c26:	8526                	mv	a0,s1
    80003c28:	fffff097          	auipc	ra,0xfffff
    80003c2c:	49c080e7          	jalr	1180(ra) # 800030c4 <brelse>
  }

  if(off > ip->size)
    80003c30:	04caa783          	lw	a5,76(s5)
    80003c34:	0127f463          	bgeu	a5,s2,80003c3c <writei+0xe2>
    ip->size = off;
    80003c38:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c3c:	8556                	mv	a0,s5
    80003c3e:	00000097          	auipc	ra,0x0
    80003c42:	aa6080e7          	jalr	-1370(ra) # 800036e4 <iupdate>

  return tot;
    80003c46:	0009851b          	sext.w	a0,s3
}
    80003c4a:	70a6                	ld	ra,104(sp)
    80003c4c:	7406                	ld	s0,96(sp)
    80003c4e:	64e6                	ld	s1,88(sp)
    80003c50:	6946                	ld	s2,80(sp)
    80003c52:	69a6                	ld	s3,72(sp)
    80003c54:	6a06                	ld	s4,64(sp)
    80003c56:	7ae2                	ld	s5,56(sp)
    80003c58:	7b42                	ld	s6,48(sp)
    80003c5a:	7ba2                	ld	s7,40(sp)
    80003c5c:	7c02                	ld	s8,32(sp)
    80003c5e:	6ce2                	ld	s9,24(sp)
    80003c60:	6d42                	ld	s10,16(sp)
    80003c62:	6da2                	ld	s11,8(sp)
    80003c64:	6165                	addi	sp,sp,112
    80003c66:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c68:	89da                	mv	s3,s6
    80003c6a:	bfc9                	j	80003c3c <writei+0xe2>
    return -1;
    80003c6c:	557d                	li	a0,-1
}
    80003c6e:	8082                	ret
    return -1;
    80003c70:	557d                	li	a0,-1
    80003c72:	bfe1                	j	80003c4a <writei+0xf0>
    return -1;
    80003c74:	557d                	li	a0,-1
    80003c76:	bfd1                	j	80003c4a <writei+0xf0>

0000000080003c78 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c78:	1141                	addi	sp,sp,-16
    80003c7a:	e406                	sd	ra,8(sp)
    80003c7c:	e022                	sd	s0,0(sp)
    80003c7e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c80:	4639                	li	a2,14
    80003c82:	ffffd097          	auipc	ra,0xffffd
    80003c86:	13c080e7          	jalr	316(ra) # 80000dbe <strncmp>
}
    80003c8a:	60a2                	ld	ra,8(sp)
    80003c8c:	6402                	ld	s0,0(sp)
    80003c8e:	0141                	addi	sp,sp,16
    80003c90:	8082                	ret

0000000080003c92 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c92:	7139                	addi	sp,sp,-64
    80003c94:	fc06                	sd	ra,56(sp)
    80003c96:	f822                	sd	s0,48(sp)
    80003c98:	f426                	sd	s1,40(sp)
    80003c9a:	f04a                	sd	s2,32(sp)
    80003c9c:	ec4e                	sd	s3,24(sp)
    80003c9e:	e852                	sd	s4,16(sp)
    80003ca0:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ca2:	04451703          	lh	a4,68(a0)
    80003ca6:	4785                	li	a5,1
    80003ca8:	00f71a63          	bne	a4,a5,80003cbc <dirlookup+0x2a>
    80003cac:	892a                	mv	s2,a0
    80003cae:	89ae                	mv	s3,a1
    80003cb0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cb2:	457c                	lw	a5,76(a0)
    80003cb4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003cb6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cb8:	e79d                	bnez	a5,80003ce6 <dirlookup+0x54>
    80003cba:	a8a5                	j	80003d32 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003cbc:	00005517          	auipc	a0,0x5
    80003cc0:	a3450513          	addi	a0,a0,-1484 # 800086f0 <syscalls+0x1c0>
    80003cc4:	ffffd097          	auipc	ra,0xffffd
    80003cc8:	880080e7          	jalr	-1920(ra) # 80000544 <panic>
      panic("dirlookup read");
    80003ccc:	00005517          	auipc	a0,0x5
    80003cd0:	a3c50513          	addi	a0,a0,-1476 # 80008708 <syscalls+0x1d8>
    80003cd4:	ffffd097          	auipc	ra,0xffffd
    80003cd8:	870080e7          	jalr	-1936(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cdc:	24c1                	addiw	s1,s1,16
    80003cde:	04c92783          	lw	a5,76(s2)
    80003ce2:	04f4f763          	bgeu	s1,a5,80003d30 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ce6:	4741                	li	a4,16
    80003ce8:	86a6                	mv	a3,s1
    80003cea:	fc040613          	addi	a2,s0,-64
    80003cee:	4581                	li	a1,0
    80003cf0:	854a                	mv	a0,s2
    80003cf2:	00000097          	auipc	ra,0x0
    80003cf6:	d70080e7          	jalr	-656(ra) # 80003a62 <readi>
    80003cfa:	47c1                	li	a5,16
    80003cfc:	fcf518e3          	bne	a0,a5,80003ccc <dirlookup+0x3a>
    if(de.inum == 0)
    80003d00:	fc045783          	lhu	a5,-64(s0)
    80003d04:	dfe1                	beqz	a5,80003cdc <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d06:	fc240593          	addi	a1,s0,-62
    80003d0a:	854e                	mv	a0,s3
    80003d0c:	00000097          	auipc	ra,0x0
    80003d10:	f6c080e7          	jalr	-148(ra) # 80003c78 <namecmp>
    80003d14:	f561                	bnez	a0,80003cdc <dirlookup+0x4a>
      if(poff)
    80003d16:	000a0463          	beqz	s4,80003d1e <dirlookup+0x8c>
        *poff = off;
    80003d1a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d1e:	fc045583          	lhu	a1,-64(s0)
    80003d22:	00092503          	lw	a0,0(s2)
    80003d26:	fffff097          	auipc	ra,0xfffff
    80003d2a:	750080e7          	jalr	1872(ra) # 80003476 <iget>
    80003d2e:	a011                	j	80003d32 <dirlookup+0xa0>
  return 0;
    80003d30:	4501                	li	a0,0
}
    80003d32:	70e2                	ld	ra,56(sp)
    80003d34:	7442                	ld	s0,48(sp)
    80003d36:	74a2                	ld	s1,40(sp)
    80003d38:	7902                	ld	s2,32(sp)
    80003d3a:	69e2                	ld	s3,24(sp)
    80003d3c:	6a42                	ld	s4,16(sp)
    80003d3e:	6121                	addi	sp,sp,64
    80003d40:	8082                	ret

0000000080003d42 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d42:	711d                	addi	sp,sp,-96
    80003d44:	ec86                	sd	ra,88(sp)
    80003d46:	e8a2                	sd	s0,80(sp)
    80003d48:	e4a6                	sd	s1,72(sp)
    80003d4a:	e0ca                	sd	s2,64(sp)
    80003d4c:	fc4e                	sd	s3,56(sp)
    80003d4e:	f852                	sd	s4,48(sp)
    80003d50:	f456                	sd	s5,40(sp)
    80003d52:	f05a                	sd	s6,32(sp)
    80003d54:	ec5e                	sd	s7,24(sp)
    80003d56:	e862                	sd	s8,16(sp)
    80003d58:	e466                	sd	s9,8(sp)
    80003d5a:	1080                	addi	s0,sp,96
    80003d5c:	84aa                	mv	s1,a0
    80003d5e:	8b2e                	mv	s6,a1
    80003d60:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d62:	00054703          	lbu	a4,0(a0)
    80003d66:	02f00793          	li	a5,47
    80003d6a:	02f70363          	beq	a4,a5,80003d90 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d6e:	ffffe097          	auipc	ra,0xffffe
    80003d72:	c58080e7          	jalr	-936(ra) # 800019c6 <myproc>
    80003d76:	15053503          	ld	a0,336(a0)
    80003d7a:	00000097          	auipc	ra,0x0
    80003d7e:	9f6080e7          	jalr	-1546(ra) # 80003770 <idup>
    80003d82:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d84:	02f00913          	li	s2,47
  len = path - s;
    80003d88:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d8a:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d8c:	4c05                	li	s8,1
    80003d8e:	a865                	j	80003e46 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d90:	4585                	li	a1,1
    80003d92:	4505                	li	a0,1
    80003d94:	fffff097          	auipc	ra,0xfffff
    80003d98:	6e2080e7          	jalr	1762(ra) # 80003476 <iget>
    80003d9c:	89aa                	mv	s3,a0
    80003d9e:	b7dd                	j	80003d84 <namex+0x42>
      iunlockput(ip);
    80003da0:	854e                	mv	a0,s3
    80003da2:	00000097          	auipc	ra,0x0
    80003da6:	c6e080e7          	jalr	-914(ra) # 80003a10 <iunlockput>
      return 0;
    80003daa:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003dac:	854e                	mv	a0,s3
    80003dae:	60e6                	ld	ra,88(sp)
    80003db0:	6446                	ld	s0,80(sp)
    80003db2:	64a6                	ld	s1,72(sp)
    80003db4:	6906                	ld	s2,64(sp)
    80003db6:	79e2                	ld	s3,56(sp)
    80003db8:	7a42                	ld	s4,48(sp)
    80003dba:	7aa2                	ld	s5,40(sp)
    80003dbc:	7b02                	ld	s6,32(sp)
    80003dbe:	6be2                	ld	s7,24(sp)
    80003dc0:	6c42                	ld	s8,16(sp)
    80003dc2:	6ca2                	ld	s9,8(sp)
    80003dc4:	6125                	addi	sp,sp,96
    80003dc6:	8082                	ret
      iunlock(ip);
    80003dc8:	854e                	mv	a0,s3
    80003dca:	00000097          	auipc	ra,0x0
    80003dce:	aa6080e7          	jalr	-1370(ra) # 80003870 <iunlock>
      return ip;
    80003dd2:	bfe9                	j	80003dac <namex+0x6a>
      iunlockput(ip);
    80003dd4:	854e                	mv	a0,s3
    80003dd6:	00000097          	auipc	ra,0x0
    80003dda:	c3a080e7          	jalr	-966(ra) # 80003a10 <iunlockput>
      return 0;
    80003dde:	89d2                	mv	s3,s4
    80003de0:	b7f1                	j	80003dac <namex+0x6a>
  len = path - s;
    80003de2:	40b48633          	sub	a2,s1,a1
    80003de6:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003dea:	094cd463          	bge	s9,s4,80003e72 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003dee:	4639                	li	a2,14
    80003df0:	8556                	mv	a0,s5
    80003df2:	ffffd097          	auipc	ra,0xffffd
    80003df6:	f54080e7          	jalr	-172(ra) # 80000d46 <memmove>
  while(*path == '/')
    80003dfa:	0004c783          	lbu	a5,0(s1)
    80003dfe:	01279763          	bne	a5,s2,80003e0c <namex+0xca>
    path++;
    80003e02:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e04:	0004c783          	lbu	a5,0(s1)
    80003e08:	ff278de3          	beq	a5,s2,80003e02 <namex+0xc0>
    ilock(ip);
    80003e0c:	854e                	mv	a0,s3
    80003e0e:	00000097          	auipc	ra,0x0
    80003e12:	9a0080e7          	jalr	-1632(ra) # 800037ae <ilock>
    if(ip->type != T_DIR){
    80003e16:	04499783          	lh	a5,68(s3)
    80003e1a:	f98793e3          	bne	a5,s8,80003da0 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e1e:	000b0563          	beqz	s6,80003e28 <namex+0xe6>
    80003e22:	0004c783          	lbu	a5,0(s1)
    80003e26:	d3cd                	beqz	a5,80003dc8 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e28:	865e                	mv	a2,s7
    80003e2a:	85d6                	mv	a1,s5
    80003e2c:	854e                	mv	a0,s3
    80003e2e:	00000097          	auipc	ra,0x0
    80003e32:	e64080e7          	jalr	-412(ra) # 80003c92 <dirlookup>
    80003e36:	8a2a                	mv	s4,a0
    80003e38:	dd51                	beqz	a0,80003dd4 <namex+0x92>
    iunlockput(ip);
    80003e3a:	854e                	mv	a0,s3
    80003e3c:	00000097          	auipc	ra,0x0
    80003e40:	bd4080e7          	jalr	-1068(ra) # 80003a10 <iunlockput>
    ip = next;
    80003e44:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e46:	0004c783          	lbu	a5,0(s1)
    80003e4a:	05279763          	bne	a5,s2,80003e98 <namex+0x156>
    path++;
    80003e4e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e50:	0004c783          	lbu	a5,0(s1)
    80003e54:	ff278de3          	beq	a5,s2,80003e4e <namex+0x10c>
  if(*path == 0)
    80003e58:	c79d                	beqz	a5,80003e86 <namex+0x144>
    path++;
    80003e5a:	85a6                	mv	a1,s1
  len = path - s;
    80003e5c:	8a5e                	mv	s4,s7
    80003e5e:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e60:	01278963          	beq	a5,s2,80003e72 <namex+0x130>
    80003e64:	dfbd                	beqz	a5,80003de2 <namex+0xa0>
    path++;
    80003e66:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e68:	0004c783          	lbu	a5,0(s1)
    80003e6c:	ff279ce3          	bne	a5,s2,80003e64 <namex+0x122>
    80003e70:	bf8d                	j	80003de2 <namex+0xa0>
    memmove(name, s, len);
    80003e72:	2601                	sext.w	a2,a2
    80003e74:	8556                	mv	a0,s5
    80003e76:	ffffd097          	auipc	ra,0xffffd
    80003e7a:	ed0080e7          	jalr	-304(ra) # 80000d46 <memmove>
    name[len] = 0;
    80003e7e:	9a56                	add	s4,s4,s5
    80003e80:	000a0023          	sb	zero,0(s4)
    80003e84:	bf9d                	j	80003dfa <namex+0xb8>
  if(nameiparent){
    80003e86:	f20b03e3          	beqz	s6,80003dac <namex+0x6a>
    iput(ip);
    80003e8a:	854e                	mv	a0,s3
    80003e8c:	00000097          	auipc	ra,0x0
    80003e90:	adc080e7          	jalr	-1316(ra) # 80003968 <iput>
    return 0;
    80003e94:	4981                	li	s3,0
    80003e96:	bf19                	j	80003dac <namex+0x6a>
  if(*path == 0)
    80003e98:	d7fd                	beqz	a5,80003e86 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e9a:	0004c783          	lbu	a5,0(s1)
    80003e9e:	85a6                	mv	a1,s1
    80003ea0:	b7d1                	j	80003e64 <namex+0x122>

0000000080003ea2 <dirlink>:
{
    80003ea2:	7139                	addi	sp,sp,-64
    80003ea4:	fc06                	sd	ra,56(sp)
    80003ea6:	f822                	sd	s0,48(sp)
    80003ea8:	f426                	sd	s1,40(sp)
    80003eaa:	f04a                	sd	s2,32(sp)
    80003eac:	ec4e                	sd	s3,24(sp)
    80003eae:	e852                	sd	s4,16(sp)
    80003eb0:	0080                	addi	s0,sp,64
    80003eb2:	892a                	mv	s2,a0
    80003eb4:	8a2e                	mv	s4,a1
    80003eb6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003eb8:	4601                	li	a2,0
    80003eba:	00000097          	auipc	ra,0x0
    80003ebe:	dd8080e7          	jalr	-552(ra) # 80003c92 <dirlookup>
    80003ec2:	e93d                	bnez	a0,80003f38 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ec4:	04c92483          	lw	s1,76(s2)
    80003ec8:	c49d                	beqz	s1,80003ef6 <dirlink+0x54>
    80003eca:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ecc:	4741                	li	a4,16
    80003ece:	86a6                	mv	a3,s1
    80003ed0:	fc040613          	addi	a2,s0,-64
    80003ed4:	4581                	li	a1,0
    80003ed6:	854a                	mv	a0,s2
    80003ed8:	00000097          	auipc	ra,0x0
    80003edc:	b8a080e7          	jalr	-1142(ra) # 80003a62 <readi>
    80003ee0:	47c1                	li	a5,16
    80003ee2:	06f51163          	bne	a0,a5,80003f44 <dirlink+0xa2>
    if(de.inum == 0)
    80003ee6:	fc045783          	lhu	a5,-64(s0)
    80003eea:	c791                	beqz	a5,80003ef6 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eec:	24c1                	addiw	s1,s1,16
    80003eee:	04c92783          	lw	a5,76(s2)
    80003ef2:	fcf4ede3          	bltu	s1,a5,80003ecc <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003ef6:	4639                	li	a2,14
    80003ef8:	85d2                	mv	a1,s4
    80003efa:	fc240513          	addi	a0,s0,-62
    80003efe:	ffffd097          	auipc	ra,0xffffd
    80003f02:	efc080e7          	jalr	-260(ra) # 80000dfa <strncpy>
  de.inum = inum;
    80003f06:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f0a:	4741                	li	a4,16
    80003f0c:	86a6                	mv	a3,s1
    80003f0e:	fc040613          	addi	a2,s0,-64
    80003f12:	4581                	li	a1,0
    80003f14:	854a                	mv	a0,s2
    80003f16:	00000097          	auipc	ra,0x0
    80003f1a:	c44080e7          	jalr	-956(ra) # 80003b5a <writei>
    80003f1e:	1541                	addi	a0,a0,-16
    80003f20:	00a03533          	snez	a0,a0
    80003f24:	40a00533          	neg	a0,a0
}
    80003f28:	70e2                	ld	ra,56(sp)
    80003f2a:	7442                	ld	s0,48(sp)
    80003f2c:	74a2                	ld	s1,40(sp)
    80003f2e:	7902                	ld	s2,32(sp)
    80003f30:	69e2                	ld	s3,24(sp)
    80003f32:	6a42                	ld	s4,16(sp)
    80003f34:	6121                	addi	sp,sp,64
    80003f36:	8082                	ret
    iput(ip);
    80003f38:	00000097          	auipc	ra,0x0
    80003f3c:	a30080e7          	jalr	-1488(ra) # 80003968 <iput>
    return -1;
    80003f40:	557d                	li	a0,-1
    80003f42:	b7dd                	j	80003f28 <dirlink+0x86>
      panic("dirlink read");
    80003f44:	00004517          	auipc	a0,0x4
    80003f48:	7d450513          	addi	a0,a0,2004 # 80008718 <syscalls+0x1e8>
    80003f4c:	ffffc097          	auipc	ra,0xffffc
    80003f50:	5f8080e7          	jalr	1528(ra) # 80000544 <panic>

0000000080003f54 <namei>:

struct inode*
namei(char *path)
{
    80003f54:	1101                	addi	sp,sp,-32
    80003f56:	ec06                	sd	ra,24(sp)
    80003f58:	e822                	sd	s0,16(sp)
    80003f5a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f5c:	fe040613          	addi	a2,s0,-32
    80003f60:	4581                	li	a1,0
    80003f62:	00000097          	auipc	ra,0x0
    80003f66:	de0080e7          	jalr	-544(ra) # 80003d42 <namex>
}
    80003f6a:	60e2                	ld	ra,24(sp)
    80003f6c:	6442                	ld	s0,16(sp)
    80003f6e:	6105                	addi	sp,sp,32
    80003f70:	8082                	ret

0000000080003f72 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f72:	1141                	addi	sp,sp,-16
    80003f74:	e406                	sd	ra,8(sp)
    80003f76:	e022                	sd	s0,0(sp)
    80003f78:	0800                	addi	s0,sp,16
    80003f7a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f7c:	4585                	li	a1,1
    80003f7e:	00000097          	auipc	ra,0x0
    80003f82:	dc4080e7          	jalr	-572(ra) # 80003d42 <namex>
}
    80003f86:	60a2                	ld	ra,8(sp)
    80003f88:	6402                	ld	s0,0(sp)
    80003f8a:	0141                	addi	sp,sp,16
    80003f8c:	8082                	ret

0000000080003f8e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f8e:	1101                	addi	sp,sp,-32
    80003f90:	ec06                	sd	ra,24(sp)
    80003f92:	e822                	sd	s0,16(sp)
    80003f94:	e426                	sd	s1,8(sp)
    80003f96:	e04a                	sd	s2,0(sp)
    80003f98:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f9a:	0001d917          	auipc	s2,0x1d
    80003f9e:	55690913          	addi	s2,s2,1366 # 800214f0 <log>
    80003fa2:	01892583          	lw	a1,24(s2)
    80003fa6:	02892503          	lw	a0,40(s2)
    80003faa:	fffff097          	auipc	ra,0xfffff
    80003fae:	fea080e7          	jalr	-22(ra) # 80002f94 <bread>
    80003fb2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fb4:	02c92683          	lw	a3,44(s2)
    80003fb8:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fba:	02d05763          	blez	a3,80003fe8 <write_head+0x5a>
    80003fbe:	0001d797          	auipc	a5,0x1d
    80003fc2:	56278793          	addi	a5,a5,1378 # 80021520 <log+0x30>
    80003fc6:	05c50713          	addi	a4,a0,92
    80003fca:	36fd                	addiw	a3,a3,-1
    80003fcc:	1682                	slli	a3,a3,0x20
    80003fce:	9281                	srli	a3,a3,0x20
    80003fd0:	068a                	slli	a3,a3,0x2
    80003fd2:	0001d617          	auipc	a2,0x1d
    80003fd6:	55260613          	addi	a2,a2,1362 # 80021524 <log+0x34>
    80003fda:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003fdc:	4390                	lw	a2,0(a5)
    80003fde:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fe0:	0791                	addi	a5,a5,4
    80003fe2:	0711                	addi	a4,a4,4
    80003fe4:	fed79ce3          	bne	a5,a3,80003fdc <write_head+0x4e>
  }
  bwrite(buf);
    80003fe8:	8526                	mv	a0,s1
    80003fea:	fffff097          	auipc	ra,0xfffff
    80003fee:	09c080e7          	jalr	156(ra) # 80003086 <bwrite>
  brelse(buf);
    80003ff2:	8526                	mv	a0,s1
    80003ff4:	fffff097          	auipc	ra,0xfffff
    80003ff8:	0d0080e7          	jalr	208(ra) # 800030c4 <brelse>
}
    80003ffc:	60e2                	ld	ra,24(sp)
    80003ffe:	6442                	ld	s0,16(sp)
    80004000:	64a2                	ld	s1,8(sp)
    80004002:	6902                	ld	s2,0(sp)
    80004004:	6105                	addi	sp,sp,32
    80004006:	8082                	ret

0000000080004008 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004008:	0001d797          	auipc	a5,0x1d
    8000400c:	5147a783          	lw	a5,1300(a5) # 8002151c <log+0x2c>
    80004010:	0af05d63          	blez	a5,800040ca <install_trans+0xc2>
{
    80004014:	7139                	addi	sp,sp,-64
    80004016:	fc06                	sd	ra,56(sp)
    80004018:	f822                	sd	s0,48(sp)
    8000401a:	f426                	sd	s1,40(sp)
    8000401c:	f04a                	sd	s2,32(sp)
    8000401e:	ec4e                	sd	s3,24(sp)
    80004020:	e852                	sd	s4,16(sp)
    80004022:	e456                	sd	s5,8(sp)
    80004024:	e05a                	sd	s6,0(sp)
    80004026:	0080                	addi	s0,sp,64
    80004028:	8b2a                	mv	s6,a0
    8000402a:	0001da97          	auipc	s5,0x1d
    8000402e:	4f6a8a93          	addi	s5,s5,1270 # 80021520 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004032:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004034:	0001d997          	auipc	s3,0x1d
    80004038:	4bc98993          	addi	s3,s3,1212 # 800214f0 <log>
    8000403c:	a035                	j	80004068 <install_trans+0x60>
      bunpin(dbuf);
    8000403e:	8526                	mv	a0,s1
    80004040:	fffff097          	auipc	ra,0xfffff
    80004044:	15e080e7          	jalr	350(ra) # 8000319e <bunpin>
    brelse(lbuf);
    80004048:	854a                	mv	a0,s2
    8000404a:	fffff097          	auipc	ra,0xfffff
    8000404e:	07a080e7          	jalr	122(ra) # 800030c4 <brelse>
    brelse(dbuf);
    80004052:	8526                	mv	a0,s1
    80004054:	fffff097          	auipc	ra,0xfffff
    80004058:	070080e7          	jalr	112(ra) # 800030c4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000405c:	2a05                	addiw	s4,s4,1
    8000405e:	0a91                	addi	s5,s5,4
    80004060:	02c9a783          	lw	a5,44(s3)
    80004064:	04fa5963          	bge	s4,a5,800040b6 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004068:	0189a583          	lw	a1,24(s3)
    8000406c:	014585bb          	addw	a1,a1,s4
    80004070:	2585                	addiw	a1,a1,1
    80004072:	0289a503          	lw	a0,40(s3)
    80004076:	fffff097          	auipc	ra,0xfffff
    8000407a:	f1e080e7          	jalr	-226(ra) # 80002f94 <bread>
    8000407e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004080:	000aa583          	lw	a1,0(s5)
    80004084:	0289a503          	lw	a0,40(s3)
    80004088:	fffff097          	auipc	ra,0xfffff
    8000408c:	f0c080e7          	jalr	-244(ra) # 80002f94 <bread>
    80004090:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004092:	40000613          	li	a2,1024
    80004096:	05890593          	addi	a1,s2,88
    8000409a:	05850513          	addi	a0,a0,88
    8000409e:	ffffd097          	auipc	ra,0xffffd
    800040a2:	ca8080e7          	jalr	-856(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    800040a6:	8526                	mv	a0,s1
    800040a8:	fffff097          	auipc	ra,0xfffff
    800040ac:	fde080e7          	jalr	-34(ra) # 80003086 <bwrite>
    if(recovering == 0)
    800040b0:	f80b1ce3          	bnez	s6,80004048 <install_trans+0x40>
    800040b4:	b769                	j	8000403e <install_trans+0x36>
}
    800040b6:	70e2                	ld	ra,56(sp)
    800040b8:	7442                	ld	s0,48(sp)
    800040ba:	74a2                	ld	s1,40(sp)
    800040bc:	7902                	ld	s2,32(sp)
    800040be:	69e2                	ld	s3,24(sp)
    800040c0:	6a42                	ld	s4,16(sp)
    800040c2:	6aa2                	ld	s5,8(sp)
    800040c4:	6b02                	ld	s6,0(sp)
    800040c6:	6121                	addi	sp,sp,64
    800040c8:	8082                	ret
    800040ca:	8082                	ret

00000000800040cc <initlog>:
{
    800040cc:	7179                	addi	sp,sp,-48
    800040ce:	f406                	sd	ra,40(sp)
    800040d0:	f022                	sd	s0,32(sp)
    800040d2:	ec26                	sd	s1,24(sp)
    800040d4:	e84a                	sd	s2,16(sp)
    800040d6:	e44e                	sd	s3,8(sp)
    800040d8:	1800                	addi	s0,sp,48
    800040da:	892a                	mv	s2,a0
    800040dc:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040de:	0001d497          	auipc	s1,0x1d
    800040e2:	41248493          	addi	s1,s1,1042 # 800214f0 <log>
    800040e6:	00004597          	auipc	a1,0x4
    800040ea:	64258593          	addi	a1,a1,1602 # 80008728 <syscalls+0x1f8>
    800040ee:	8526                	mv	a0,s1
    800040f0:	ffffd097          	auipc	ra,0xffffd
    800040f4:	a6a080e7          	jalr	-1430(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    800040f8:	0149a583          	lw	a1,20(s3)
    800040fc:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040fe:	0109a783          	lw	a5,16(s3)
    80004102:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004104:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004108:	854a                	mv	a0,s2
    8000410a:	fffff097          	auipc	ra,0xfffff
    8000410e:	e8a080e7          	jalr	-374(ra) # 80002f94 <bread>
  log.lh.n = lh->n;
    80004112:	4d3c                	lw	a5,88(a0)
    80004114:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004116:	02f05563          	blez	a5,80004140 <initlog+0x74>
    8000411a:	05c50713          	addi	a4,a0,92
    8000411e:	0001d697          	auipc	a3,0x1d
    80004122:	40268693          	addi	a3,a3,1026 # 80021520 <log+0x30>
    80004126:	37fd                	addiw	a5,a5,-1
    80004128:	1782                	slli	a5,a5,0x20
    8000412a:	9381                	srli	a5,a5,0x20
    8000412c:	078a                	slli	a5,a5,0x2
    8000412e:	06050613          	addi	a2,a0,96
    80004132:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004134:	4310                	lw	a2,0(a4)
    80004136:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004138:	0711                	addi	a4,a4,4
    8000413a:	0691                	addi	a3,a3,4
    8000413c:	fef71ce3          	bne	a4,a5,80004134 <initlog+0x68>
  brelse(buf);
    80004140:	fffff097          	auipc	ra,0xfffff
    80004144:	f84080e7          	jalr	-124(ra) # 800030c4 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004148:	4505                	li	a0,1
    8000414a:	00000097          	auipc	ra,0x0
    8000414e:	ebe080e7          	jalr	-322(ra) # 80004008 <install_trans>
  log.lh.n = 0;
    80004152:	0001d797          	auipc	a5,0x1d
    80004156:	3c07a523          	sw	zero,970(a5) # 8002151c <log+0x2c>
  write_head(); // clear the log
    8000415a:	00000097          	auipc	ra,0x0
    8000415e:	e34080e7          	jalr	-460(ra) # 80003f8e <write_head>
}
    80004162:	70a2                	ld	ra,40(sp)
    80004164:	7402                	ld	s0,32(sp)
    80004166:	64e2                	ld	s1,24(sp)
    80004168:	6942                	ld	s2,16(sp)
    8000416a:	69a2                	ld	s3,8(sp)
    8000416c:	6145                	addi	sp,sp,48
    8000416e:	8082                	ret

0000000080004170 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004170:	1101                	addi	sp,sp,-32
    80004172:	ec06                	sd	ra,24(sp)
    80004174:	e822                	sd	s0,16(sp)
    80004176:	e426                	sd	s1,8(sp)
    80004178:	e04a                	sd	s2,0(sp)
    8000417a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000417c:	0001d517          	auipc	a0,0x1d
    80004180:	37450513          	addi	a0,a0,884 # 800214f0 <log>
    80004184:	ffffd097          	auipc	ra,0xffffd
    80004188:	a66080e7          	jalr	-1434(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    8000418c:	0001d497          	auipc	s1,0x1d
    80004190:	36448493          	addi	s1,s1,868 # 800214f0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004194:	4979                	li	s2,30
    80004196:	a039                	j	800041a4 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004198:	85a6                	mv	a1,s1
    8000419a:	8526                	mv	a0,s1
    8000419c:	ffffe097          	auipc	ra,0xffffe
    800041a0:	ed6080e7          	jalr	-298(ra) # 80002072 <sleep>
    if(log.committing){
    800041a4:	50dc                	lw	a5,36(s1)
    800041a6:	fbed                	bnez	a5,80004198 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041a8:	509c                	lw	a5,32(s1)
    800041aa:	0017871b          	addiw	a4,a5,1
    800041ae:	0007069b          	sext.w	a3,a4
    800041b2:	0027179b          	slliw	a5,a4,0x2
    800041b6:	9fb9                	addw	a5,a5,a4
    800041b8:	0017979b          	slliw	a5,a5,0x1
    800041bc:	54d8                	lw	a4,44(s1)
    800041be:	9fb9                	addw	a5,a5,a4
    800041c0:	00f95963          	bge	s2,a5,800041d2 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041c4:	85a6                	mv	a1,s1
    800041c6:	8526                	mv	a0,s1
    800041c8:	ffffe097          	auipc	ra,0xffffe
    800041cc:	eaa080e7          	jalr	-342(ra) # 80002072 <sleep>
    800041d0:	bfd1                	j	800041a4 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041d2:	0001d517          	auipc	a0,0x1d
    800041d6:	31e50513          	addi	a0,a0,798 # 800214f0 <log>
    800041da:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041dc:	ffffd097          	auipc	ra,0xffffd
    800041e0:	ac2080e7          	jalr	-1342(ra) # 80000c9e <release>
      break;
    }
  }
}
    800041e4:	60e2                	ld	ra,24(sp)
    800041e6:	6442                	ld	s0,16(sp)
    800041e8:	64a2                	ld	s1,8(sp)
    800041ea:	6902                	ld	s2,0(sp)
    800041ec:	6105                	addi	sp,sp,32
    800041ee:	8082                	ret

00000000800041f0 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041f0:	7139                	addi	sp,sp,-64
    800041f2:	fc06                	sd	ra,56(sp)
    800041f4:	f822                	sd	s0,48(sp)
    800041f6:	f426                	sd	s1,40(sp)
    800041f8:	f04a                	sd	s2,32(sp)
    800041fa:	ec4e                	sd	s3,24(sp)
    800041fc:	e852                	sd	s4,16(sp)
    800041fe:	e456                	sd	s5,8(sp)
    80004200:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004202:	0001d497          	auipc	s1,0x1d
    80004206:	2ee48493          	addi	s1,s1,750 # 800214f0 <log>
    8000420a:	8526                	mv	a0,s1
    8000420c:	ffffd097          	auipc	ra,0xffffd
    80004210:	9de080e7          	jalr	-1570(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    80004214:	509c                	lw	a5,32(s1)
    80004216:	37fd                	addiw	a5,a5,-1
    80004218:	0007891b          	sext.w	s2,a5
    8000421c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000421e:	50dc                	lw	a5,36(s1)
    80004220:	efb9                	bnez	a5,8000427e <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004222:	06091663          	bnez	s2,8000428e <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004226:	0001d497          	auipc	s1,0x1d
    8000422a:	2ca48493          	addi	s1,s1,714 # 800214f0 <log>
    8000422e:	4785                	li	a5,1
    80004230:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004232:	8526                	mv	a0,s1
    80004234:	ffffd097          	auipc	ra,0xffffd
    80004238:	a6a080e7          	jalr	-1430(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000423c:	54dc                	lw	a5,44(s1)
    8000423e:	06f04763          	bgtz	a5,800042ac <end_op+0xbc>
    acquire(&log.lock);
    80004242:	0001d497          	auipc	s1,0x1d
    80004246:	2ae48493          	addi	s1,s1,686 # 800214f0 <log>
    8000424a:	8526                	mv	a0,s1
    8000424c:	ffffd097          	auipc	ra,0xffffd
    80004250:	99e080e7          	jalr	-1634(ra) # 80000bea <acquire>
    log.committing = 0;
    80004254:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004258:	8526                	mv	a0,s1
    8000425a:	ffffe097          	auipc	ra,0xffffe
    8000425e:	e7c080e7          	jalr	-388(ra) # 800020d6 <wakeup>
    release(&log.lock);
    80004262:	8526                	mv	a0,s1
    80004264:	ffffd097          	auipc	ra,0xffffd
    80004268:	a3a080e7          	jalr	-1478(ra) # 80000c9e <release>
}
    8000426c:	70e2                	ld	ra,56(sp)
    8000426e:	7442                	ld	s0,48(sp)
    80004270:	74a2                	ld	s1,40(sp)
    80004272:	7902                	ld	s2,32(sp)
    80004274:	69e2                	ld	s3,24(sp)
    80004276:	6a42                	ld	s4,16(sp)
    80004278:	6aa2                	ld	s5,8(sp)
    8000427a:	6121                	addi	sp,sp,64
    8000427c:	8082                	ret
    panic("log.committing");
    8000427e:	00004517          	auipc	a0,0x4
    80004282:	4b250513          	addi	a0,a0,1202 # 80008730 <syscalls+0x200>
    80004286:	ffffc097          	auipc	ra,0xffffc
    8000428a:	2be080e7          	jalr	702(ra) # 80000544 <panic>
    wakeup(&log);
    8000428e:	0001d497          	auipc	s1,0x1d
    80004292:	26248493          	addi	s1,s1,610 # 800214f0 <log>
    80004296:	8526                	mv	a0,s1
    80004298:	ffffe097          	auipc	ra,0xffffe
    8000429c:	e3e080e7          	jalr	-450(ra) # 800020d6 <wakeup>
  release(&log.lock);
    800042a0:	8526                	mv	a0,s1
    800042a2:	ffffd097          	auipc	ra,0xffffd
    800042a6:	9fc080e7          	jalr	-1540(ra) # 80000c9e <release>
  if(do_commit){
    800042aa:	b7c9                	j	8000426c <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042ac:	0001da97          	auipc	s5,0x1d
    800042b0:	274a8a93          	addi	s5,s5,628 # 80021520 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042b4:	0001da17          	auipc	s4,0x1d
    800042b8:	23ca0a13          	addi	s4,s4,572 # 800214f0 <log>
    800042bc:	018a2583          	lw	a1,24(s4)
    800042c0:	012585bb          	addw	a1,a1,s2
    800042c4:	2585                	addiw	a1,a1,1
    800042c6:	028a2503          	lw	a0,40(s4)
    800042ca:	fffff097          	auipc	ra,0xfffff
    800042ce:	cca080e7          	jalr	-822(ra) # 80002f94 <bread>
    800042d2:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042d4:	000aa583          	lw	a1,0(s5)
    800042d8:	028a2503          	lw	a0,40(s4)
    800042dc:	fffff097          	auipc	ra,0xfffff
    800042e0:	cb8080e7          	jalr	-840(ra) # 80002f94 <bread>
    800042e4:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042e6:	40000613          	li	a2,1024
    800042ea:	05850593          	addi	a1,a0,88
    800042ee:	05848513          	addi	a0,s1,88
    800042f2:	ffffd097          	auipc	ra,0xffffd
    800042f6:	a54080e7          	jalr	-1452(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    800042fa:	8526                	mv	a0,s1
    800042fc:	fffff097          	auipc	ra,0xfffff
    80004300:	d8a080e7          	jalr	-630(ra) # 80003086 <bwrite>
    brelse(from);
    80004304:	854e                	mv	a0,s3
    80004306:	fffff097          	auipc	ra,0xfffff
    8000430a:	dbe080e7          	jalr	-578(ra) # 800030c4 <brelse>
    brelse(to);
    8000430e:	8526                	mv	a0,s1
    80004310:	fffff097          	auipc	ra,0xfffff
    80004314:	db4080e7          	jalr	-588(ra) # 800030c4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004318:	2905                	addiw	s2,s2,1
    8000431a:	0a91                	addi	s5,s5,4
    8000431c:	02ca2783          	lw	a5,44(s4)
    80004320:	f8f94ee3          	blt	s2,a5,800042bc <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004324:	00000097          	auipc	ra,0x0
    80004328:	c6a080e7          	jalr	-918(ra) # 80003f8e <write_head>
    install_trans(0); // Now install writes to home locations
    8000432c:	4501                	li	a0,0
    8000432e:	00000097          	auipc	ra,0x0
    80004332:	cda080e7          	jalr	-806(ra) # 80004008 <install_trans>
    log.lh.n = 0;
    80004336:	0001d797          	auipc	a5,0x1d
    8000433a:	1e07a323          	sw	zero,486(a5) # 8002151c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000433e:	00000097          	auipc	ra,0x0
    80004342:	c50080e7          	jalr	-944(ra) # 80003f8e <write_head>
    80004346:	bdf5                	j	80004242 <end_op+0x52>

0000000080004348 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004348:	1101                	addi	sp,sp,-32
    8000434a:	ec06                	sd	ra,24(sp)
    8000434c:	e822                	sd	s0,16(sp)
    8000434e:	e426                	sd	s1,8(sp)
    80004350:	e04a                	sd	s2,0(sp)
    80004352:	1000                	addi	s0,sp,32
    80004354:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004356:	0001d917          	auipc	s2,0x1d
    8000435a:	19a90913          	addi	s2,s2,410 # 800214f0 <log>
    8000435e:	854a                	mv	a0,s2
    80004360:	ffffd097          	auipc	ra,0xffffd
    80004364:	88a080e7          	jalr	-1910(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004368:	02c92603          	lw	a2,44(s2)
    8000436c:	47f5                	li	a5,29
    8000436e:	06c7c563          	blt	a5,a2,800043d8 <log_write+0x90>
    80004372:	0001d797          	auipc	a5,0x1d
    80004376:	19a7a783          	lw	a5,410(a5) # 8002150c <log+0x1c>
    8000437a:	37fd                	addiw	a5,a5,-1
    8000437c:	04f65e63          	bge	a2,a5,800043d8 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004380:	0001d797          	auipc	a5,0x1d
    80004384:	1907a783          	lw	a5,400(a5) # 80021510 <log+0x20>
    80004388:	06f05063          	blez	a5,800043e8 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000438c:	4781                	li	a5,0
    8000438e:	06c05563          	blez	a2,800043f8 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004392:	44cc                	lw	a1,12(s1)
    80004394:	0001d717          	auipc	a4,0x1d
    80004398:	18c70713          	addi	a4,a4,396 # 80021520 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000439c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000439e:	4314                	lw	a3,0(a4)
    800043a0:	04b68c63          	beq	a3,a1,800043f8 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800043a4:	2785                	addiw	a5,a5,1
    800043a6:	0711                	addi	a4,a4,4
    800043a8:	fef61be3          	bne	a2,a5,8000439e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043ac:	0621                	addi	a2,a2,8
    800043ae:	060a                	slli	a2,a2,0x2
    800043b0:	0001d797          	auipc	a5,0x1d
    800043b4:	14078793          	addi	a5,a5,320 # 800214f0 <log>
    800043b8:	963e                	add	a2,a2,a5
    800043ba:	44dc                	lw	a5,12(s1)
    800043bc:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043be:	8526                	mv	a0,s1
    800043c0:	fffff097          	auipc	ra,0xfffff
    800043c4:	da2080e7          	jalr	-606(ra) # 80003162 <bpin>
    log.lh.n++;
    800043c8:	0001d717          	auipc	a4,0x1d
    800043cc:	12870713          	addi	a4,a4,296 # 800214f0 <log>
    800043d0:	575c                	lw	a5,44(a4)
    800043d2:	2785                	addiw	a5,a5,1
    800043d4:	d75c                	sw	a5,44(a4)
    800043d6:	a835                	j	80004412 <log_write+0xca>
    panic("too big a transaction");
    800043d8:	00004517          	auipc	a0,0x4
    800043dc:	36850513          	addi	a0,a0,872 # 80008740 <syscalls+0x210>
    800043e0:	ffffc097          	auipc	ra,0xffffc
    800043e4:	164080e7          	jalr	356(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    800043e8:	00004517          	auipc	a0,0x4
    800043ec:	37050513          	addi	a0,a0,880 # 80008758 <syscalls+0x228>
    800043f0:	ffffc097          	auipc	ra,0xffffc
    800043f4:	154080e7          	jalr	340(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    800043f8:	00878713          	addi	a4,a5,8
    800043fc:	00271693          	slli	a3,a4,0x2
    80004400:	0001d717          	auipc	a4,0x1d
    80004404:	0f070713          	addi	a4,a4,240 # 800214f0 <log>
    80004408:	9736                	add	a4,a4,a3
    8000440a:	44d4                	lw	a3,12(s1)
    8000440c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000440e:	faf608e3          	beq	a2,a5,800043be <log_write+0x76>
  }
  release(&log.lock);
    80004412:	0001d517          	auipc	a0,0x1d
    80004416:	0de50513          	addi	a0,a0,222 # 800214f0 <log>
    8000441a:	ffffd097          	auipc	ra,0xffffd
    8000441e:	884080e7          	jalr	-1916(ra) # 80000c9e <release>
}
    80004422:	60e2                	ld	ra,24(sp)
    80004424:	6442                	ld	s0,16(sp)
    80004426:	64a2                	ld	s1,8(sp)
    80004428:	6902                	ld	s2,0(sp)
    8000442a:	6105                	addi	sp,sp,32
    8000442c:	8082                	ret

000000008000442e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000442e:	1101                	addi	sp,sp,-32
    80004430:	ec06                	sd	ra,24(sp)
    80004432:	e822                	sd	s0,16(sp)
    80004434:	e426                	sd	s1,8(sp)
    80004436:	e04a                	sd	s2,0(sp)
    80004438:	1000                	addi	s0,sp,32
    8000443a:	84aa                	mv	s1,a0
    8000443c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000443e:	00004597          	auipc	a1,0x4
    80004442:	33a58593          	addi	a1,a1,826 # 80008778 <syscalls+0x248>
    80004446:	0521                	addi	a0,a0,8
    80004448:	ffffc097          	auipc	ra,0xffffc
    8000444c:	712080e7          	jalr	1810(ra) # 80000b5a <initlock>
  lk->name = name;
    80004450:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004454:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004458:	0204a423          	sw	zero,40(s1)
}
    8000445c:	60e2                	ld	ra,24(sp)
    8000445e:	6442                	ld	s0,16(sp)
    80004460:	64a2                	ld	s1,8(sp)
    80004462:	6902                	ld	s2,0(sp)
    80004464:	6105                	addi	sp,sp,32
    80004466:	8082                	ret

0000000080004468 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004468:	1101                	addi	sp,sp,-32
    8000446a:	ec06                	sd	ra,24(sp)
    8000446c:	e822                	sd	s0,16(sp)
    8000446e:	e426                	sd	s1,8(sp)
    80004470:	e04a                	sd	s2,0(sp)
    80004472:	1000                	addi	s0,sp,32
    80004474:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004476:	00850913          	addi	s2,a0,8
    8000447a:	854a                	mv	a0,s2
    8000447c:	ffffc097          	auipc	ra,0xffffc
    80004480:	76e080e7          	jalr	1902(ra) # 80000bea <acquire>
  while (lk->locked) {
    80004484:	409c                	lw	a5,0(s1)
    80004486:	cb89                	beqz	a5,80004498 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004488:	85ca                	mv	a1,s2
    8000448a:	8526                	mv	a0,s1
    8000448c:	ffffe097          	auipc	ra,0xffffe
    80004490:	be6080e7          	jalr	-1050(ra) # 80002072 <sleep>
  while (lk->locked) {
    80004494:	409c                	lw	a5,0(s1)
    80004496:	fbed                	bnez	a5,80004488 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004498:	4785                	li	a5,1
    8000449a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000449c:	ffffd097          	auipc	ra,0xffffd
    800044a0:	52a080e7          	jalr	1322(ra) # 800019c6 <myproc>
    800044a4:	591c                	lw	a5,48(a0)
    800044a6:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044a8:	854a                	mv	a0,s2
    800044aa:	ffffc097          	auipc	ra,0xffffc
    800044ae:	7f4080e7          	jalr	2036(ra) # 80000c9e <release>
}
    800044b2:	60e2                	ld	ra,24(sp)
    800044b4:	6442                	ld	s0,16(sp)
    800044b6:	64a2                	ld	s1,8(sp)
    800044b8:	6902                	ld	s2,0(sp)
    800044ba:	6105                	addi	sp,sp,32
    800044bc:	8082                	ret

00000000800044be <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044be:	1101                	addi	sp,sp,-32
    800044c0:	ec06                	sd	ra,24(sp)
    800044c2:	e822                	sd	s0,16(sp)
    800044c4:	e426                	sd	s1,8(sp)
    800044c6:	e04a                	sd	s2,0(sp)
    800044c8:	1000                	addi	s0,sp,32
    800044ca:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044cc:	00850913          	addi	s2,a0,8
    800044d0:	854a                	mv	a0,s2
    800044d2:	ffffc097          	auipc	ra,0xffffc
    800044d6:	718080e7          	jalr	1816(ra) # 80000bea <acquire>
  lk->locked = 0;
    800044da:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044de:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044e2:	8526                	mv	a0,s1
    800044e4:	ffffe097          	auipc	ra,0xffffe
    800044e8:	bf2080e7          	jalr	-1038(ra) # 800020d6 <wakeup>
  release(&lk->lk);
    800044ec:	854a                	mv	a0,s2
    800044ee:	ffffc097          	auipc	ra,0xffffc
    800044f2:	7b0080e7          	jalr	1968(ra) # 80000c9e <release>
}
    800044f6:	60e2                	ld	ra,24(sp)
    800044f8:	6442                	ld	s0,16(sp)
    800044fa:	64a2                	ld	s1,8(sp)
    800044fc:	6902                	ld	s2,0(sp)
    800044fe:	6105                	addi	sp,sp,32
    80004500:	8082                	ret

0000000080004502 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004502:	7179                	addi	sp,sp,-48
    80004504:	f406                	sd	ra,40(sp)
    80004506:	f022                	sd	s0,32(sp)
    80004508:	ec26                	sd	s1,24(sp)
    8000450a:	e84a                	sd	s2,16(sp)
    8000450c:	e44e                	sd	s3,8(sp)
    8000450e:	1800                	addi	s0,sp,48
    80004510:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004512:	00850913          	addi	s2,a0,8
    80004516:	854a                	mv	a0,s2
    80004518:	ffffc097          	auipc	ra,0xffffc
    8000451c:	6d2080e7          	jalr	1746(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004520:	409c                	lw	a5,0(s1)
    80004522:	ef99                	bnez	a5,80004540 <holdingsleep+0x3e>
    80004524:	4481                	li	s1,0
  release(&lk->lk);
    80004526:	854a                	mv	a0,s2
    80004528:	ffffc097          	auipc	ra,0xffffc
    8000452c:	776080e7          	jalr	1910(ra) # 80000c9e <release>
  return r;
}
    80004530:	8526                	mv	a0,s1
    80004532:	70a2                	ld	ra,40(sp)
    80004534:	7402                	ld	s0,32(sp)
    80004536:	64e2                	ld	s1,24(sp)
    80004538:	6942                	ld	s2,16(sp)
    8000453a:	69a2                	ld	s3,8(sp)
    8000453c:	6145                	addi	sp,sp,48
    8000453e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004540:	0284a983          	lw	s3,40(s1)
    80004544:	ffffd097          	auipc	ra,0xffffd
    80004548:	482080e7          	jalr	1154(ra) # 800019c6 <myproc>
    8000454c:	5904                	lw	s1,48(a0)
    8000454e:	413484b3          	sub	s1,s1,s3
    80004552:	0014b493          	seqz	s1,s1
    80004556:	bfc1                	j	80004526 <holdingsleep+0x24>

0000000080004558 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004558:	1141                	addi	sp,sp,-16
    8000455a:	e406                	sd	ra,8(sp)
    8000455c:	e022                	sd	s0,0(sp)
    8000455e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004560:	00004597          	auipc	a1,0x4
    80004564:	22858593          	addi	a1,a1,552 # 80008788 <syscalls+0x258>
    80004568:	0001d517          	auipc	a0,0x1d
    8000456c:	0d050513          	addi	a0,a0,208 # 80021638 <ftable>
    80004570:	ffffc097          	auipc	ra,0xffffc
    80004574:	5ea080e7          	jalr	1514(ra) # 80000b5a <initlock>
}
    80004578:	60a2                	ld	ra,8(sp)
    8000457a:	6402                	ld	s0,0(sp)
    8000457c:	0141                	addi	sp,sp,16
    8000457e:	8082                	ret

0000000080004580 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004580:	1101                	addi	sp,sp,-32
    80004582:	ec06                	sd	ra,24(sp)
    80004584:	e822                	sd	s0,16(sp)
    80004586:	e426                	sd	s1,8(sp)
    80004588:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000458a:	0001d517          	auipc	a0,0x1d
    8000458e:	0ae50513          	addi	a0,a0,174 # 80021638 <ftable>
    80004592:	ffffc097          	auipc	ra,0xffffc
    80004596:	658080e7          	jalr	1624(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000459a:	0001d497          	auipc	s1,0x1d
    8000459e:	0b648493          	addi	s1,s1,182 # 80021650 <ftable+0x18>
    800045a2:	0001e717          	auipc	a4,0x1e
    800045a6:	04e70713          	addi	a4,a4,78 # 800225f0 <disk>
    if(f->ref == 0){
    800045aa:	40dc                	lw	a5,4(s1)
    800045ac:	cf99                	beqz	a5,800045ca <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045ae:	02848493          	addi	s1,s1,40
    800045b2:	fee49ce3          	bne	s1,a4,800045aa <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045b6:	0001d517          	auipc	a0,0x1d
    800045ba:	08250513          	addi	a0,a0,130 # 80021638 <ftable>
    800045be:	ffffc097          	auipc	ra,0xffffc
    800045c2:	6e0080e7          	jalr	1760(ra) # 80000c9e <release>
  return 0;
    800045c6:	4481                	li	s1,0
    800045c8:	a819                	j	800045de <filealloc+0x5e>
      f->ref = 1;
    800045ca:	4785                	li	a5,1
    800045cc:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045ce:	0001d517          	auipc	a0,0x1d
    800045d2:	06a50513          	addi	a0,a0,106 # 80021638 <ftable>
    800045d6:	ffffc097          	auipc	ra,0xffffc
    800045da:	6c8080e7          	jalr	1736(ra) # 80000c9e <release>
}
    800045de:	8526                	mv	a0,s1
    800045e0:	60e2                	ld	ra,24(sp)
    800045e2:	6442                	ld	s0,16(sp)
    800045e4:	64a2                	ld	s1,8(sp)
    800045e6:	6105                	addi	sp,sp,32
    800045e8:	8082                	ret

00000000800045ea <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045ea:	1101                	addi	sp,sp,-32
    800045ec:	ec06                	sd	ra,24(sp)
    800045ee:	e822                	sd	s0,16(sp)
    800045f0:	e426                	sd	s1,8(sp)
    800045f2:	1000                	addi	s0,sp,32
    800045f4:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045f6:	0001d517          	auipc	a0,0x1d
    800045fa:	04250513          	addi	a0,a0,66 # 80021638 <ftable>
    800045fe:	ffffc097          	auipc	ra,0xffffc
    80004602:	5ec080e7          	jalr	1516(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004606:	40dc                	lw	a5,4(s1)
    80004608:	02f05263          	blez	a5,8000462c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000460c:	2785                	addiw	a5,a5,1
    8000460e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004610:	0001d517          	auipc	a0,0x1d
    80004614:	02850513          	addi	a0,a0,40 # 80021638 <ftable>
    80004618:	ffffc097          	auipc	ra,0xffffc
    8000461c:	686080e7          	jalr	1670(ra) # 80000c9e <release>
  return f;
}
    80004620:	8526                	mv	a0,s1
    80004622:	60e2                	ld	ra,24(sp)
    80004624:	6442                	ld	s0,16(sp)
    80004626:	64a2                	ld	s1,8(sp)
    80004628:	6105                	addi	sp,sp,32
    8000462a:	8082                	ret
    panic("filedup");
    8000462c:	00004517          	auipc	a0,0x4
    80004630:	16450513          	addi	a0,a0,356 # 80008790 <syscalls+0x260>
    80004634:	ffffc097          	auipc	ra,0xffffc
    80004638:	f10080e7          	jalr	-240(ra) # 80000544 <panic>

000000008000463c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000463c:	7139                	addi	sp,sp,-64
    8000463e:	fc06                	sd	ra,56(sp)
    80004640:	f822                	sd	s0,48(sp)
    80004642:	f426                	sd	s1,40(sp)
    80004644:	f04a                	sd	s2,32(sp)
    80004646:	ec4e                	sd	s3,24(sp)
    80004648:	e852                	sd	s4,16(sp)
    8000464a:	e456                	sd	s5,8(sp)
    8000464c:	0080                	addi	s0,sp,64
    8000464e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004650:	0001d517          	auipc	a0,0x1d
    80004654:	fe850513          	addi	a0,a0,-24 # 80021638 <ftable>
    80004658:	ffffc097          	auipc	ra,0xffffc
    8000465c:	592080e7          	jalr	1426(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004660:	40dc                	lw	a5,4(s1)
    80004662:	06f05163          	blez	a5,800046c4 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004666:	37fd                	addiw	a5,a5,-1
    80004668:	0007871b          	sext.w	a4,a5
    8000466c:	c0dc                	sw	a5,4(s1)
    8000466e:	06e04363          	bgtz	a4,800046d4 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004672:	0004a903          	lw	s2,0(s1)
    80004676:	0094ca83          	lbu	s5,9(s1)
    8000467a:	0104ba03          	ld	s4,16(s1)
    8000467e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004682:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004686:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000468a:	0001d517          	auipc	a0,0x1d
    8000468e:	fae50513          	addi	a0,a0,-82 # 80021638 <ftable>
    80004692:	ffffc097          	auipc	ra,0xffffc
    80004696:	60c080e7          	jalr	1548(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    8000469a:	4785                	li	a5,1
    8000469c:	04f90d63          	beq	s2,a5,800046f6 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046a0:	3979                	addiw	s2,s2,-2
    800046a2:	4785                	li	a5,1
    800046a4:	0527e063          	bltu	a5,s2,800046e4 <fileclose+0xa8>
    begin_op();
    800046a8:	00000097          	auipc	ra,0x0
    800046ac:	ac8080e7          	jalr	-1336(ra) # 80004170 <begin_op>
    iput(ff.ip);
    800046b0:	854e                	mv	a0,s3
    800046b2:	fffff097          	auipc	ra,0xfffff
    800046b6:	2b6080e7          	jalr	694(ra) # 80003968 <iput>
    end_op();
    800046ba:	00000097          	auipc	ra,0x0
    800046be:	b36080e7          	jalr	-1226(ra) # 800041f0 <end_op>
    800046c2:	a00d                	j	800046e4 <fileclose+0xa8>
    panic("fileclose");
    800046c4:	00004517          	auipc	a0,0x4
    800046c8:	0d450513          	addi	a0,a0,212 # 80008798 <syscalls+0x268>
    800046cc:	ffffc097          	auipc	ra,0xffffc
    800046d0:	e78080e7          	jalr	-392(ra) # 80000544 <panic>
    release(&ftable.lock);
    800046d4:	0001d517          	auipc	a0,0x1d
    800046d8:	f6450513          	addi	a0,a0,-156 # 80021638 <ftable>
    800046dc:	ffffc097          	auipc	ra,0xffffc
    800046e0:	5c2080e7          	jalr	1474(ra) # 80000c9e <release>
  }
}
    800046e4:	70e2                	ld	ra,56(sp)
    800046e6:	7442                	ld	s0,48(sp)
    800046e8:	74a2                	ld	s1,40(sp)
    800046ea:	7902                	ld	s2,32(sp)
    800046ec:	69e2                	ld	s3,24(sp)
    800046ee:	6a42                	ld	s4,16(sp)
    800046f0:	6aa2                	ld	s5,8(sp)
    800046f2:	6121                	addi	sp,sp,64
    800046f4:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046f6:	85d6                	mv	a1,s5
    800046f8:	8552                	mv	a0,s4
    800046fa:	00000097          	auipc	ra,0x0
    800046fe:	34c080e7          	jalr	844(ra) # 80004a46 <pipeclose>
    80004702:	b7cd                	j	800046e4 <fileclose+0xa8>

0000000080004704 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004704:	715d                	addi	sp,sp,-80
    80004706:	e486                	sd	ra,72(sp)
    80004708:	e0a2                	sd	s0,64(sp)
    8000470a:	fc26                	sd	s1,56(sp)
    8000470c:	f84a                	sd	s2,48(sp)
    8000470e:	f44e                	sd	s3,40(sp)
    80004710:	0880                	addi	s0,sp,80
    80004712:	84aa                	mv	s1,a0
    80004714:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004716:	ffffd097          	auipc	ra,0xffffd
    8000471a:	2b0080e7          	jalr	688(ra) # 800019c6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000471e:	409c                	lw	a5,0(s1)
    80004720:	37f9                	addiw	a5,a5,-2
    80004722:	4705                	li	a4,1
    80004724:	04f76763          	bltu	a4,a5,80004772 <filestat+0x6e>
    80004728:	892a                	mv	s2,a0
    ilock(f->ip);
    8000472a:	6c88                	ld	a0,24(s1)
    8000472c:	fffff097          	auipc	ra,0xfffff
    80004730:	082080e7          	jalr	130(ra) # 800037ae <ilock>
    stati(f->ip, &st);
    80004734:	fb840593          	addi	a1,s0,-72
    80004738:	6c88                	ld	a0,24(s1)
    8000473a:	fffff097          	auipc	ra,0xfffff
    8000473e:	2fe080e7          	jalr	766(ra) # 80003a38 <stati>
    iunlock(f->ip);
    80004742:	6c88                	ld	a0,24(s1)
    80004744:	fffff097          	auipc	ra,0xfffff
    80004748:	12c080e7          	jalr	300(ra) # 80003870 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000474c:	46e1                	li	a3,24
    8000474e:	fb840613          	addi	a2,s0,-72
    80004752:	85ce                	mv	a1,s3
    80004754:	05093503          	ld	a0,80(s2)
    80004758:	ffffd097          	auipc	ra,0xffffd
    8000475c:	f2c080e7          	jalr	-212(ra) # 80001684 <copyout>
    80004760:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004764:	60a6                	ld	ra,72(sp)
    80004766:	6406                	ld	s0,64(sp)
    80004768:	74e2                	ld	s1,56(sp)
    8000476a:	7942                	ld	s2,48(sp)
    8000476c:	79a2                	ld	s3,40(sp)
    8000476e:	6161                	addi	sp,sp,80
    80004770:	8082                	ret
  return -1;
    80004772:	557d                	li	a0,-1
    80004774:	bfc5                	j	80004764 <filestat+0x60>

0000000080004776 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004776:	7179                	addi	sp,sp,-48
    80004778:	f406                	sd	ra,40(sp)
    8000477a:	f022                	sd	s0,32(sp)
    8000477c:	ec26                	sd	s1,24(sp)
    8000477e:	e84a                	sd	s2,16(sp)
    80004780:	e44e                	sd	s3,8(sp)
    80004782:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004784:	00854783          	lbu	a5,8(a0)
    80004788:	c3d5                	beqz	a5,8000482c <fileread+0xb6>
    8000478a:	84aa                	mv	s1,a0
    8000478c:	89ae                	mv	s3,a1
    8000478e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004790:	411c                	lw	a5,0(a0)
    80004792:	4705                	li	a4,1
    80004794:	04e78963          	beq	a5,a4,800047e6 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004798:	470d                	li	a4,3
    8000479a:	04e78d63          	beq	a5,a4,800047f4 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000479e:	4709                	li	a4,2
    800047a0:	06e79e63          	bne	a5,a4,8000481c <fileread+0xa6>
    ilock(f->ip);
    800047a4:	6d08                	ld	a0,24(a0)
    800047a6:	fffff097          	auipc	ra,0xfffff
    800047aa:	008080e7          	jalr	8(ra) # 800037ae <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047ae:	874a                	mv	a4,s2
    800047b0:	5094                	lw	a3,32(s1)
    800047b2:	864e                	mv	a2,s3
    800047b4:	4585                	li	a1,1
    800047b6:	6c88                	ld	a0,24(s1)
    800047b8:	fffff097          	auipc	ra,0xfffff
    800047bc:	2aa080e7          	jalr	682(ra) # 80003a62 <readi>
    800047c0:	892a                	mv	s2,a0
    800047c2:	00a05563          	blez	a0,800047cc <fileread+0x56>
      f->off += r;
    800047c6:	509c                	lw	a5,32(s1)
    800047c8:	9fa9                	addw	a5,a5,a0
    800047ca:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047cc:	6c88                	ld	a0,24(s1)
    800047ce:	fffff097          	auipc	ra,0xfffff
    800047d2:	0a2080e7          	jalr	162(ra) # 80003870 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047d6:	854a                	mv	a0,s2
    800047d8:	70a2                	ld	ra,40(sp)
    800047da:	7402                	ld	s0,32(sp)
    800047dc:	64e2                	ld	s1,24(sp)
    800047de:	6942                	ld	s2,16(sp)
    800047e0:	69a2                	ld	s3,8(sp)
    800047e2:	6145                	addi	sp,sp,48
    800047e4:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047e6:	6908                	ld	a0,16(a0)
    800047e8:	00000097          	auipc	ra,0x0
    800047ec:	3ce080e7          	jalr	974(ra) # 80004bb6 <piperead>
    800047f0:	892a                	mv	s2,a0
    800047f2:	b7d5                	j	800047d6 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047f4:	02451783          	lh	a5,36(a0)
    800047f8:	03079693          	slli	a3,a5,0x30
    800047fc:	92c1                	srli	a3,a3,0x30
    800047fe:	4725                	li	a4,9
    80004800:	02d76863          	bltu	a4,a3,80004830 <fileread+0xba>
    80004804:	0792                	slli	a5,a5,0x4
    80004806:	0001d717          	auipc	a4,0x1d
    8000480a:	d9270713          	addi	a4,a4,-622 # 80021598 <devsw>
    8000480e:	97ba                	add	a5,a5,a4
    80004810:	639c                	ld	a5,0(a5)
    80004812:	c38d                	beqz	a5,80004834 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004814:	4505                	li	a0,1
    80004816:	9782                	jalr	a5
    80004818:	892a                	mv	s2,a0
    8000481a:	bf75                	j	800047d6 <fileread+0x60>
    panic("fileread");
    8000481c:	00004517          	auipc	a0,0x4
    80004820:	f8c50513          	addi	a0,a0,-116 # 800087a8 <syscalls+0x278>
    80004824:	ffffc097          	auipc	ra,0xffffc
    80004828:	d20080e7          	jalr	-736(ra) # 80000544 <panic>
    return -1;
    8000482c:	597d                	li	s2,-1
    8000482e:	b765                	j	800047d6 <fileread+0x60>
      return -1;
    80004830:	597d                	li	s2,-1
    80004832:	b755                	j	800047d6 <fileread+0x60>
    80004834:	597d                	li	s2,-1
    80004836:	b745                	j	800047d6 <fileread+0x60>

0000000080004838 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004838:	715d                	addi	sp,sp,-80
    8000483a:	e486                	sd	ra,72(sp)
    8000483c:	e0a2                	sd	s0,64(sp)
    8000483e:	fc26                	sd	s1,56(sp)
    80004840:	f84a                	sd	s2,48(sp)
    80004842:	f44e                	sd	s3,40(sp)
    80004844:	f052                	sd	s4,32(sp)
    80004846:	ec56                	sd	s5,24(sp)
    80004848:	e85a                	sd	s6,16(sp)
    8000484a:	e45e                	sd	s7,8(sp)
    8000484c:	e062                	sd	s8,0(sp)
    8000484e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004850:	00954783          	lbu	a5,9(a0)
    80004854:	10078663          	beqz	a5,80004960 <filewrite+0x128>
    80004858:	892a                	mv	s2,a0
    8000485a:	8aae                	mv	s5,a1
    8000485c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000485e:	411c                	lw	a5,0(a0)
    80004860:	4705                	li	a4,1
    80004862:	02e78263          	beq	a5,a4,80004886 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004866:	470d                	li	a4,3
    80004868:	02e78663          	beq	a5,a4,80004894 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000486c:	4709                	li	a4,2
    8000486e:	0ee79163          	bne	a5,a4,80004950 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004872:	0ac05d63          	blez	a2,8000492c <filewrite+0xf4>
    int i = 0;
    80004876:	4981                	li	s3,0
    80004878:	6b05                	lui	s6,0x1
    8000487a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000487e:	6b85                	lui	s7,0x1
    80004880:	c00b8b9b          	addiw	s7,s7,-1024
    80004884:	a861                	j	8000491c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004886:	6908                	ld	a0,16(a0)
    80004888:	00000097          	auipc	ra,0x0
    8000488c:	22e080e7          	jalr	558(ra) # 80004ab6 <pipewrite>
    80004890:	8a2a                	mv	s4,a0
    80004892:	a045                	j	80004932 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004894:	02451783          	lh	a5,36(a0)
    80004898:	03079693          	slli	a3,a5,0x30
    8000489c:	92c1                	srli	a3,a3,0x30
    8000489e:	4725                	li	a4,9
    800048a0:	0cd76263          	bltu	a4,a3,80004964 <filewrite+0x12c>
    800048a4:	0792                	slli	a5,a5,0x4
    800048a6:	0001d717          	auipc	a4,0x1d
    800048aa:	cf270713          	addi	a4,a4,-782 # 80021598 <devsw>
    800048ae:	97ba                	add	a5,a5,a4
    800048b0:	679c                	ld	a5,8(a5)
    800048b2:	cbdd                	beqz	a5,80004968 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800048b4:	4505                	li	a0,1
    800048b6:	9782                	jalr	a5
    800048b8:	8a2a                	mv	s4,a0
    800048ba:	a8a5                	j	80004932 <filewrite+0xfa>
    800048bc:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048c0:	00000097          	auipc	ra,0x0
    800048c4:	8b0080e7          	jalr	-1872(ra) # 80004170 <begin_op>
      ilock(f->ip);
    800048c8:	01893503          	ld	a0,24(s2)
    800048cc:	fffff097          	auipc	ra,0xfffff
    800048d0:	ee2080e7          	jalr	-286(ra) # 800037ae <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048d4:	8762                	mv	a4,s8
    800048d6:	02092683          	lw	a3,32(s2)
    800048da:	01598633          	add	a2,s3,s5
    800048de:	4585                	li	a1,1
    800048e0:	01893503          	ld	a0,24(s2)
    800048e4:	fffff097          	auipc	ra,0xfffff
    800048e8:	276080e7          	jalr	630(ra) # 80003b5a <writei>
    800048ec:	84aa                	mv	s1,a0
    800048ee:	00a05763          	blez	a0,800048fc <filewrite+0xc4>
        f->off += r;
    800048f2:	02092783          	lw	a5,32(s2)
    800048f6:	9fa9                	addw	a5,a5,a0
    800048f8:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800048fc:	01893503          	ld	a0,24(s2)
    80004900:	fffff097          	auipc	ra,0xfffff
    80004904:	f70080e7          	jalr	-144(ra) # 80003870 <iunlock>
      end_op();
    80004908:	00000097          	auipc	ra,0x0
    8000490c:	8e8080e7          	jalr	-1816(ra) # 800041f0 <end_op>

      if(r != n1){
    80004910:	009c1f63          	bne	s8,s1,8000492e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004914:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004918:	0149db63          	bge	s3,s4,8000492e <filewrite+0xf6>
      int n1 = n - i;
    8000491c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004920:	84be                	mv	s1,a5
    80004922:	2781                	sext.w	a5,a5
    80004924:	f8fb5ce3          	bge	s6,a5,800048bc <filewrite+0x84>
    80004928:	84de                	mv	s1,s7
    8000492a:	bf49                	j	800048bc <filewrite+0x84>
    int i = 0;
    8000492c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000492e:	013a1f63          	bne	s4,s3,8000494c <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004932:	8552                	mv	a0,s4
    80004934:	60a6                	ld	ra,72(sp)
    80004936:	6406                	ld	s0,64(sp)
    80004938:	74e2                	ld	s1,56(sp)
    8000493a:	7942                	ld	s2,48(sp)
    8000493c:	79a2                	ld	s3,40(sp)
    8000493e:	7a02                	ld	s4,32(sp)
    80004940:	6ae2                	ld	s5,24(sp)
    80004942:	6b42                	ld	s6,16(sp)
    80004944:	6ba2                	ld	s7,8(sp)
    80004946:	6c02                	ld	s8,0(sp)
    80004948:	6161                	addi	sp,sp,80
    8000494a:	8082                	ret
    ret = (i == n ? n : -1);
    8000494c:	5a7d                	li	s4,-1
    8000494e:	b7d5                	j	80004932 <filewrite+0xfa>
    panic("filewrite");
    80004950:	00004517          	auipc	a0,0x4
    80004954:	e6850513          	addi	a0,a0,-408 # 800087b8 <syscalls+0x288>
    80004958:	ffffc097          	auipc	ra,0xffffc
    8000495c:	bec080e7          	jalr	-1044(ra) # 80000544 <panic>
    return -1;
    80004960:	5a7d                	li	s4,-1
    80004962:	bfc1                	j	80004932 <filewrite+0xfa>
      return -1;
    80004964:	5a7d                	li	s4,-1
    80004966:	b7f1                	j	80004932 <filewrite+0xfa>
    80004968:	5a7d                	li	s4,-1
    8000496a:	b7e1                	j	80004932 <filewrite+0xfa>

000000008000496c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000496c:	7179                	addi	sp,sp,-48
    8000496e:	f406                	sd	ra,40(sp)
    80004970:	f022                	sd	s0,32(sp)
    80004972:	ec26                	sd	s1,24(sp)
    80004974:	e84a                	sd	s2,16(sp)
    80004976:	e44e                	sd	s3,8(sp)
    80004978:	e052                	sd	s4,0(sp)
    8000497a:	1800                	addi	s0,sp,48
    8000497c:	84aa                	mv	s1,a0
    8000497e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004980:	0005b023          	sd	zero,0(a1)
    80004984:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004988:	00000097          	auipc	ra,0x0
    8000498c:	bf8080e7          	jalr	-1032(ra) # 80004580 <filealloc>
    80004990:	e088                	sd	a0,0(s1)
    80004992:	c551                	beqz	a0,80004a1e <pipealloc+0xb2>
    80004994:	00000097          	auipc	ra,0x0
    80004998:	bec080e7          	jalr	-1044(ra) # 80004580 <filealloc>
    8000499c:	00aa3023          	sd	a0,0(s4)
    800049a0:	c92d                	beqz	a0,80004a12 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049a2:	ffffc097          	auipc	ra,0xffffc
    800049a6:	158080e7          	jalr	344(ra) # 80000afa <kalloc>
    800049aa:	892a                	mv	s2,a0
    800049ac:	c125                	beqz	a0,80004a0c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049ae:	4985                	li	s3,1
    800049b0:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049b4:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049b8:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049bc:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049c0:	00004597          	auipc	a1,0x4
    800049c4:	aa858593          	addi	a1,a1,-1368 # 80008468 <states.1727+0x1a0>
    800049c8:	ffffc097          	auipc	ra,0xffffc
    800049cc:	192080e7          	jalr	402(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    800049d0:	609c                	ld	a5,0(s1)
    800049d2:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049d6:	609c                	ld	a5,0(s1)
    800049d8:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049dc:	609c                	ld	a5,0(s1)
    800049de:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049e2:	609c                	ld	a5,0(s1)
    800049e4:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049e8:	000a3783          	ld	a5,0(s4)
    800049ec:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049f0:	000a3783          	ld	a5,0(s4)
    800049f4:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049f8:	000a3783          	ld	a5,0(s4)
    800049fc:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a00:	000a3783          	ld	a5,0(s4)
    80004a04:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a08:	4501                	li	a0,0
    80004a0a:	a025                	j	80004a32 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a0c:	6088                	ld	a0,0(s1)
    80004a0e:	e501                	bnez	a0,80004a16 <pipealloc+0xaa>
    80004a10:	a039                	j	80004a1e <pipealloc+0xb2>
    80004a12:	6088                	ld	a0,0(s1)
    80004a14:	c51d                	beqz	a0,80004a42 <pipealloc+0xd6>
    fileclose(*f0);
    80004a16:	00000097          	auipc	ra,0x0
    80004a1a:	c26080e7          	jalr	-986(ra) # 8000463c <fileclose>
  if(*f1)
    80004a1e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a22:	557d                	li	a0,-1
  if(*f1)
    80004a24:	c799                	beqz	a5,80004a32 <pipealloc+0xc6>
    fileclose(*f1);
    80004a26:	853e                	mv	a0,a5
    80004a28:	00000097          	auipc	ra,0x0
    80004a2c:	c14080e7          	jalr	-1004(ra) # 8000463c <fileclose>
  return -1;
    80004a30:	557d                	li	a0,-1
}
    80004a32:	70a2                	ld	ra,40(sp)
    80004a34:	7402                	ld	s0,32(sp)
    80004a36:	64e2                	ld	s1,24(sp)
    80004a38:	6942                	ld	s2,16(sp)
    80004a3a:	69a2                	ld	s3,8(sp)
    80004a3c:	6a02                	ld	s4,0(sp)
    80004a3e:	6145                	addi	sp,sp,48
    80004a40:	8082                	ret
  return -1;
    80004a42:	557d                	li	a0,-1
    80004a44:	b7fd                	j	80004a32 <pipealloc+0xc6>

0000000080004a46 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a46:	1101                	addi	sp,sp,-32
    80004a48:	ec06                	sd	ra,24(sp)
    80004a4a:	e822                	sd	s0,16(sp)
    80004a4c:	e426                	sd	s1,8(sp)
    80004a4e:	e04a                	sd	s2,0(sp)
    80004a50:	1000                	addi	s0,sp,32
    80004a52:	84aa                	mv	s1,a0
    80004a54:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a56:	ffffc097          	auipc	ra,0xffffc
    80004a5a:	194080e7          	jalr	404(ra) # 80000bea <acquire>
  if(writable){
    80004a5e:	02090d63          	beqz	s2,80004a98 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a62:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a66:	21848513          	addi	a0,s1,536
    80004a6a:	ffffd097          	auipc	ra,0xffffd
    80004a6e:	66c080e7          	jalr	1644(ra) # 800020d6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a72:	2204b783          	ld	a5,544(s1)
    80004a76:	eb95                	bnez	a5,80004aaa <pipeclose+0x64>
    release(&pi->lock);
    80004a78:	8526                	mv	a0,s1
    80004a7a:	ffffc097          	auipc	ra,0xffffc
    80004a7e:	224080e7          	jalr	548(ra) # 80000c9e <release>
    kfree((char*)pi);
    80004a82:	8526                	mv	a0,s1
    80004a84:	ffffc097          	auipc	ra,0xffffc
    80004a88:	f7a080e7          	jalr	-134(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80004a8c:	60e2                	ld	ra,24(sp)
    80004a8e:	6442                	ld	s0,16(sp)
    80004a90:	64a2                	ld	s1,8(sp)
    80004a92:	6902                	ld	s2,0(sp)
    80004a94:	6105                	addi	sp,sp,32
    80004a96:	8082                	ret
    pi->readopen = 0;
    80004a98:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a9c:	21c48513          	addi	a0,s1,540
    80004aa0:	ffffd097          	auipc	ra,0xffffd
    80004aa4:	636080e7          	jalr	1590(ra) # 800020d6 <wakeup>
    80004aa8:	b7e9                	j	80004a72 <pipeclose+0x2c>
    release(&pi->lock);
    80004aaa:	8526                	mv	a0,s1
    80004aac:	ffffc097          	auipc	ra,0xffffc
    80004ab0:	1f2080e7          	jalr	498(ra) # 80000c9e <release>
}
    80004ab4:	bfe1                	j	80004a8c <pipeclose+0x46>

0000000080004ab6 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ab6:	7159                	addi	sp,sp,-112
    80004ab8:	f486                	sd	ra,104(sp)
    80004aba:	f0a2                	sd	s0,96(sp)
    80004abc:	eca6                	sd	s1,88(sp)
    80004abe:	e8ca                	sd	s2,80(sp)
    80004ac0:	e4ce                	sd	s3,72(sp)
    80004ac2:	e0d2                	sd	s4,64(sp)
    80004ac4:	fc56                	sd	s5,56(sp)
    80004ac6:	f85a                	sd	s6,48(sp)
    80004ac8:	f45e                	sd	s7,40(sp)
    80004aca:	f062                	sd	s8,32(sp)
    80004acc:	ec66                	sd	s9,24(sp)
    80004ace:	1880                	addi	s0,sp,112
    80004ad0:	84aa                	mv	s1,a0
    80004ad2:	8aae                	mv	s5,a1
    80004ad4:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ad6:	ffffd097          	auipc	ra,0xffffd
    80004ada:	ef0080e7          	jalr	-272(ra) # 800019c6 <myproc>
    80004ade:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ae0:	8526                	mv	a0,s1
    80004ae2:	ffffc097          	auipc	ra,0xffffc
    80004ae6:	108080e7          	jalr	264(ra) # 80000bea <acquire>
  while(i < n){
    80004aea:	0d405463          	blez	s4,80004bb2 <pipewrite+0xfc>
    80004aee:	8ba6                	mv	s7,s1
  int i = 0;
    80004af0:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004af2:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004af4:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004af8:	21c48c13          	addi	s8,s1,540
    80004afc:	a08d                	j	80004b5e <pipewrite+0xa8>
      release(&pi->lock);
    80004afe:	8526                	mv	a0,s1
    80004b00:	ffffc097          	auipc	ra,0xffffc
    80004b04:	19e080e7          	jalr	414(ra) # 80000c9e <release>
      return -1;
    80004b08:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b0a:	854a                	mv	a0,s2
    80004b0c:	70a6                	ld	ra,104(sp)
    80004b0e:	7406                	ld	s0,96(sp)
    80004b10:	64e6                	ld	s1,88(sp)
    80004b12:	6946                	ld	s2,80(sp)
    80004b14:	69a6                	ld	s3,72(sp)
    80004b16:	6a06                	ld	s4,64(sp)
    80004b18:	7ae2                	ld	s5,56(sp)
    80004b1a:	7b42                	ld	s6,48(sp)
    80004b1c:	7ba2                	ld	s7,40(sp)
    80004b1e:	7c02                	ld	s8,32(sp)
    80004b20:	6ce2                	ld	s9,24(sp)
    80004b22:	6165                	addi	sp,sp,112
    80004b24:	8082                	ret
      wakeup(&pi->nread);
    80004b26:	8566                	mv	a0,s9
    80004b28:	ffffd097          	auipc	ra,0xffffd
    80004b2c:	5ae080e7          	jalr	1454(ra) # 800020d6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b30:	85de                	mv	a1,s7
    80004b32:	8562                	mv	a0,s8
    80004b34:	ffffd097          	auipc	ra,0xffffd
    80004b38:	53e080e7          	jalr	1342(ra) # 80002072 <sleep>
    80004b3c:	a839                	j	80004b5a <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b3e:	21c4a783          	lw	a5,540(s1)
    80004b42:	0017871b          	addiw	a4,a5,1
    80004b46:	20e4ae23          	sw	a4,540(s1)
    80004b4a:	1ff7f793          	andi	a5,a5,511
    80004b4e:	97a6                	add	a5,a5,s1
    80004b50:	f9f44703          	lbu	a4,-97(s0)
    80004b54:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b58:	2905                	addiw	s2,s2,1
  while(i < n){
    80004b5a:	05495063          	bge	s2,s4,80004b9a <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80004b5e:	2204a783          	lw	a5,544(s1)
    80004b62:	dfd1                	beqz	a5,80004afe <pipewrite+0x48>
    80004b64:	854e                	mv	a0,s3
    80004b66:	ffffd097          	auipc	ra,0xffffd
    80004b6a:	7b4080e7          	jalr	1972(ra) # 8000231a <killed>
    80004b6e:	f941                	bnez	a0,80004afe <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b70:	2184a783          	lw	a5,536(s1)
    80004b74:	21c4a703          	lw	a4,540(s1)
    80004b78:	2007879b          	addiw	a5,a5,512
    80004b7c:	faf705e3          	beq	a4,a5,80004b26 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b80:	4685                	li	a3,1
    80004b82:	01590633          	add	a2,s2,s5
    80004b86:	f9f40593          	addi	a1,s0,-97
    80004b8a:	0509b503          	ld	a0,80(s3)
    80004b8e:	ffffd097          	auipc	ra,0xffffd
    80004b92:	b82080e7          	jalr	-1150(ra) # 80001710 <copyin>
    80004b96:	fb6514e3          	bne	a0,s6,80004b3e <pipewrite+0x88>
  wakeup(&pi->nread);
    80004b9a:	21848513          	addi	a0,s1,536
    80004b9e:	ffffd097          	auipc	ra,0xffffd
    80004ba2:	538080e7          	jalr	1336(ra) # 800020d6 <wakeup>
  release(&pi->lock);
    80004ba6:	8526                	mv	a0,s1
    80004ba8:	ffffc097          	auipc	ra,0xffffc
    80004bac:	0f6080e7          	jalr	246(ra) # 80000c9e <release>
  return i;
    80004bb0:	bfa9                	j	80004b0a <pipewrite+0x54>
  int i = 0;
    80004bb2:	4901                	li	s2,0
    80004bb4:	b7dd                	j	80004b9a <pipewrite+0xe4>

0000000080004bb6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bb6:	715d                	addi	sp,sp,-80
    80004bb8:	e486                	sd	ra,72(sp)
    80004bba:	e0a2                	sd	s0,64(sp)
    80004bbc:	fc26                	sd	s1,56(sp)
    80004bbe:	f84a                	sd	s2,48(sp)
    80004bc0:	f44e                	sd	s3,40(sp)
    80004bc2:	f052                	sd	s4,32(sp)
    80004bc4:	ec56                	sd	s5,24(sp)
    80004bc6:	e85a                	sd	s6,16(sp)
    80004bc8:	0880                	addi	s0,sp,80
    80004bca:	84aa                	mv	s1,a0
    80004bcc:	892e                	mv	s2,a1
    80004bce:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bd0:	ffffd097          	auipc	ra,0xffffd
    80004bd4:	df6080e7          	jalr	-522(ra) # 800019c6 <myproc>
    80004bd8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bda:	8b26                	mv	s6,s1
    80004bdc:	8526                	mv	a0,s1
    80004bde:	ffffc097          	auipc	ra,0xffffc
    80004be2:	00c080e7          	jalr	12(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004be6:	2184a703          	lw	a4,536(s1)
    80004bea:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bee:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bf2:	02f71763          	bne	a4,a5,80004c20 <piperead+0x6a>
    80004bf6:	2244a783          	lw	a5,548(s1)
    80004bfa:	c39d                	beqz	a5,80004c20 <piperead+0x6a>
    if(killed(pr)){
    80004bfc:	8552                	mv	a0,s4
    80004bfe:	ffffd097          	auipc	ra,0xffffd
    80004c02:	71c080e7          	jalr	1820(ra) # 8000231a <killed>
    80004c06:	e941                	bnez	a0,80004c96 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c08:	85da                	mv	a1,s6
    80004c0a:	854e                	mv	a0,s3
    80004c0c:	ffffd097          	auipc	ra,0xffffd
    80004c10:	466080e7          	jalr	1126(ra) # 80002072 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c14:	2184a703          	lw	a4,536(s1)
    80004c18:	21c4a783          	lw	a5,540(s1)
    80004c1c:	fcf70de3          	beq	a4,a5,80004bf6 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c20:	09505263          	blez	s5,80004ca4 <piperead+0xee>
    80004c24:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c26:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c28:	2184a783          	lw	a5,536(s1)
    80004c2c:	21c4a703          	lw	a4,540(s1)
    80004c30:	02f70d63          	beq	a4,a5,80004c6a <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c34:	0017871b          	addiw	a4,a5,1
    80004c38:	20e4ac23          	sw	a4,536(s1)
    80004c3c:	1ff7f793          	andi	a5,a5,511
    80004c40:	97a6                	add	a5,a5,s1
    80004c42:	0187c783          	lbu	a5,24(a5)
    80004c46:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c4a:	4685                	li	a3,1
    80004c4c:	fbf40613          	addi	a2,s0,-65
    80004c50:	85ca                	mv	a1,s2
    80004c52:	050a3503          	ld	a0,80(s4)
    80004c56:	ffffd097          	auipc	ra,0xffffd
    80004c5a:	a2e080e7          	jalr	-1490(ra) # 80001684 <copyout>
    80004c5e:	01650663          	beq	a0,s6,80004c6a <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c62:	2985                	addiw	s3,s3,1
    80004c64:	0905                	addi	s2,s2,1
    80004c66:	fd3a91e3          	bne	s5,s3,80004c28 <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c6a:	21c48513          	addi	a0,s1,540
    80004c6e:	ffffd097          	auipc	ra,0xffffd
    80004c72:	468080e7          	jalr	1128(ra) # 800020d6 <wakeup>
  release(&pi->lock);
    80004c76:	8526                	mv	a0,s1
    80004c78:	ffffc097          	auipc	ra,0xffffc
    80004c7c:	026080e7          	jalr	38(ra) # 80000c9e <release>
  return i;
}
    80004c80:	854e                	mv	a0,s3
    80004c82:	60a6                	ld	ra,72(sp)
    80004c84:	6406                	ld	s0,64(sp)
    80004c86:	74e2                	ld	s1,56(sp)
    80004c88:	7942                	ld	s2,48(sp)
    80004c8a:	79a2                	ld	s3,40(sp)
    80004c8c:	7a02                	ld	s4,32(sp)
    80004c8e:	6ae2                	ld	s5,24(sp)
    80004c90:	6b42                	ld	s6,16(sp)
    80004c92:	6161                	addi	sp,sp,80
    80004c94:	8082                	ret
      release(&pi->lock);
    80004c96:	8526                	mv	a0,s1
    80004c98:	ffffc097          	auipc	ra,0xffffc
    80004c9c:	006080e7          	jalr	6(ra) # 80000c9e <release>
      return -1;
    80004ca0:	59fd                	li	s3,-1
    80004ca2:	bff9                	j	80004c80 <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ca4:	4981                	li	s3,0
    80004ca6:	b7d1                	j	80004c6a <piperead+0xb4>

0000000080004ca8 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004ca8:	1141                	addi	sp,sp,-16
    80004caa:	e422                	sd	s0,8(sp)
    80004cac:	0800                	addi	s0,sp,16
    80004cae:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004cb0:	8905                	andi	a0,a0,1
    80004cb2:	c111                	beqz	a0,80004cb6 <flags2perm+0xe>
      perm = PTE_X;
    80004cb4:	4521                	li	a0,8
    if(flags & 0x2)
    80004cb6:	8b89                	andi	a5,a5,2
    80004cb8:	c399                	beqz	a5,80004cbe <flags2perm+0x16>
      perm |= PTE_W;
    80004cba:	00456513          	ori	a0,a0,4
    return perm;
}
    80004cbe:	6422                	ld	s0,8(sp)
    80004cc0:	0141                	addi	sp,sp,16
    80004cc2:	8082                	ret

0000000080004cc4 <exec>:

int
exec(char *path, char **argv)
{
    80004cc4:	df010113          	addi	sp,sp,-528
    80004cc8:	20113423          	sd	ra,520(sp)
    80004ccc:	20813023          	sd	s0,512(sp)
    80004cd0:	ffa6                	sd	s1,504(sp)
    80004cd2:	fbca                	sd	s2,496(sp)
    80004cd4:	f7ce                	sd	s3,488(sp)
    80004cd6:	f3d2                	sd	s4,480(sp)
    80004cd8:	efd6                	sd	s5,472(sp)
    80004cda:	ebda                	sd	s6,464(sp)
    80004cdc:	e7de                	sd	s7,456(sp)
    80004cde:	e3e2                	sd	s8,448(sp)
    80004ce0:	ff66                	sd	s9,440(sp)
    80004ce2:	fb6a                	sd	s10,432(sp)
    80004ce4:	f76e                	sd	s11,424(sp)
    80004ce6:	0c00                	addi	s0,sp,528
    80004ce8:	84aa                	mv	s1,a0
    80004cea:	dea43c23          	sd	a0,-520(s0)
    80004cee:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cf2:	ffffd097          	auipc	ra,0xffffd
    80004cf6:	cd4080e7          	jalr	-812(ra) # 800019c6 <myproc>
    80004cfa:	892a                	mv	s2,a0

  begin_op();
    80004cfc:	fffff097          	auipc	ra,0xfffff
    80004d00:	474080e7          	jalr	1140(ra) # 80004170 <begin_op>

  if((ip = namei(path)) == 0){
    80004d04:	8526                	mv	a0,s1
    80004d06:	fffff097          	auipc	ra,0xfffff
    80004d0a:	24e080e7          	jalr	590(ra) # 80003f54 <namei>
    80004d0e:	c92d                	beqz	a0,80004d80 <exec+0xbc>
    80004d10:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d12:	fffff097          	auipc	ra,0xfffff
    80004d16:	a9c080e7          	jalr	-1380(ra) # 800037ae <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d1a:	04000713          	li	a4,64
    80004d1e:	4681                	li	a3,0
    80004d20:	e5040613          	addi	a2,s0,-432
    80004d24:	4581                	li	a1,0
    80004d26:	8526                	mv	a0,s1
    80004d28:	fffff097          	auipc	ra,0xfffff
    80004d2c:	d3a080e7          	jalr	-710(ra) # 80003a62 <readi>
    80004d30:	04000793          	li	a5,64
    80004d34:	00f51a63          	bne	a0,a5,80004d48 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004d38:	e5042703          	lw	a4,-432(s0)
    80004d3c:	464c47b7          	lui	a5,0x464c4
    80004d40:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d44:	04f70463          	beq	a4,a5,80004d8c <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d48:	8526                	mv	a0,s1
    80004d4a:	fffff097          	auipc	ra,0xfffff
    80004d4e:	cc6080e7          	jalr	-826(ra) # 80003a10 <iunlockput>
    end_op();
    80004d52:	fffff097          	auipc	ra,0xfffff
    80004d56:	49e080e7          	jalr	1182(ra) # 800041f0 <end_op>
  }
  return -1;
    80004d5a:	557d                	li	a0,-1
}
    80004d5c:	20813083          	ld	ra,520(sp)
    80004d60:	20013403          	ld	s0,512(sp)
    80004d64:	74fe                	ld	s1,504(sp)
    80004d66:	795e                	ld	s2,496(sp)
    80004d68:	79be                	ld	s3,488(sp)
    80004d6a:	7a1e                	ld	s4,480(sp)
    80004d6c:	6afe                	ld	s5,472(sp)
    80004d6e:	6b5e                	ld	s6,464(sp)
    80004d70:	6bbe                	ld	s7,456(sp)
    80004d72:	6c1e                	ld	s8,448(sp)
    80004d74:	7cfa                	ld	s9,440(sp)
    80004d76:	7d5a                	ld	s10,432(sp)
    80004d78:	7dba                	ld	s11,424(sp)
    80004d7a:	21010113          	addi	sp,sp,528
    80004d7e:	8082                	ret
    end_op();
    80004d80:	fffff097          	auipc	ra,0xfffff
    80004d84:	470080e7          	jalr	1136(ra) # 800041f0 <end_op>
    return -1;
    80004d88:	557d                	li	a0,-1
    80004d8a:	bfc9                	j	80004d5c <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d8c:	854a                	mv	a0,s2
    80004d8e:	ffffd097          	auipc	ra,0xffffd
    80004d92:	cfc080e7          	jalr	-772(ra) # 80001a8a <proc_pagetable>
    80004d96:	8baa                	mv	s7,a0
    80004d98:	d945                	beqz	a0,80004d48 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d9a:	e7042983          	lw	s3,-400(s0)
    80004d9e:	e8845783          	lhu	a5,-376(s0)
    80004da2:	c7ad                	beqz	a5,80004e0c <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004da4:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004da6:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004da8:	6c85                	lui	s9,0x1
    80004daa:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004dae:	def43823          	sd	a5,-528(s0)
    80004db2:	ac0d                	j	80004fe4 <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004db4:	00004517          	auipc	a0,0x4
    80004db8:	a1450513          	addi	a0,a0,-1516 # 800087c8 <syscalls+0x298>
    80004dbc:	ffffb097          	auipc	ra,0xffffb
    80004dc0:	788080e7          	jalr	1928(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004dc4:	8756                	mv	a4,s5
    80004dc6:	012d86bb          	addw	a3,s11,s2
    80004dca:	4581                	li	a1,0
    80004dcc:	8526                	mv	a0,s1
    80004dce:	fffff097          	auipc	ra,0xfffff
    80004dd2:	c94080e7          	jalr	-876(ra) # 80003a62 <readi>
    80004dd6:	2501                	sext.w	a0,a0
    80004dd8:	1aaa9a63          	bne	s5,a0,80004f8c <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    80004ddc:	6785                	lui	a5,0x1
    80004dde:	0127893b          	addw	s2,a5,s2
    80004de2:	77fd                	lui	a5,0xfffff
    80004de4:	01478a3b          	addw	s4,a5,s4
    80004de8:	1f897563          	bgeu	s2,s8,80004fd2 <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    80004dec:	02091593          	slli	a1,s2,0x20
    80004df0:	9181                	srli	a1,a1,0x20
    80004df2:	95ea                	add	a1,a1,s10
    80004df4:	855e                	mv	a0,s7
    80004df6:	ffffc097          	auipc	ra,0xffffc
    80004dfa:	282080e7          	jalr	642(ra) # 80001078 <walkaddr>
    80004dfe:	862a                	mv	a2,a0
    if(pa == 0)
    80004e00:	d955                	beqz	a0,80004db4 <exec+0xf0>
      n = PGSIZE;
    80004e02:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004e04:	fd9a70e3          	bgeu	s4,s9,80004dc4 <exec+0x100>
      n = sz - i;
    80004e08:	8ad2                	mv	s5,s4
    80004e0a:	bf6d                	j	80004dc4 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e0c:	4a01                	li	s4,0
  iunlockput(ip);
    80004e0e:	8526                	mv	a0,s1
    80004e10:	fffff097          	auipc	ra,0xfffff
    80004e14:	c00080e7          	jalr	-1024(ra) # 80003a10 <iunlockput>
  end_op();
    80004e18:	fffff097          	auipc	ra,0xfffff
    80004e1c:	3d8080e7          	jalr	984(ra) # 800041f0 <end_op>
  p = myproc();
    80004e20:	ffffd097          	auipc	ra,0xffffd
    80004e24:	ba6080e7          	jalr	-1114(ra) # 800019c6 <myproc>
    80004e28:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e2a:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e2e:	6785                	lui	a5,0x1
    80004e30:	17fd                	addi	a5,a5,-1
    80004e32:	9a3e                	add	s4,s4,a5
    80004e34:	757d                	lui	a0,0xfffff
    80004e36:	00aa77b3          	and	a5,s4,a0
    80004e3a:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e3e:	4691                	li	a3,4
    80004e40:	6609                	lui	a2,0x2
    80004e42:	963e                	add	a2,a2,a5
    80004e44:	85be                	mv	a1,a5
    80004e46:	855e                	mv	a0,s7
    80004e48:	ffffc097          	auipc	ra,0xffffc
    80004e4c:	5e4080e7          	jalr	1508(ra) # 8000142c <uvmalloc>
    80004e50:	8b2a                	mv	s6,a0
  ip = 0;
    80004e52:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e54:	12050c63          	beqz	a0,80004f8c <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e58:	75f9                	lui	a1,0xffffe
    80004e5a:	95aa                	add	a1,a1,a0
    80004e5c:	855e                	mv	a0,s7
    80004e5e:	ffffc097          	auipc	ra,0xffffc
    80004e62:	7f4080e7          	jalr	2036(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e66:	7c7d                	lui	s8,0xfffff
    80004e68:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e6a:	e0043783          	ld	a5,-512(s0)
    80004e6e:	6388                	ld	a0,0(a5)
    80004e70:	c535                	beqz	a0,80004edc <exec+0x218>
    80004e72:	e9040993          	addi	s3,s0,-368
    80004e76:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e7a:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e7c:	ffffc097          	auipc	ra,0xffffc
    80004e80:	fee080e7          	jalr	-18(ra) # 80000e6a <strlen>
    80004e84:	2505                	addiw	a0,a0,1
    80004e86:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e8a:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e8e:	13896663          	bltu	s2,s8,80004fba <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e92:	e0043d83          	ld	s11,-512(s0)
    80004e96:	000dba03          	ld	s4,0(s11)
    80004e9a:	8552                	mv	a0,s4
    80004e9c:	ffffc097          	auipc	ra,0xffffc
    80004ea0:	fce080e7          	jalr	-50(ra) # 80000e6a <strlen>
    80004ea4:	0015069b          	addiw	a3,a0,1
    80004ea8:	8652                	mv	a2,s4
    80004eaa:	85ca                	mv	a1,s2
    80004eac:	855e                	mv	a0,s7
    80004eae:	ffffc097          	auipc	ra,0xffffc
    80004eb2:	7d6080e7          	jalr	2006(ra) # 80001684 <copyout>
    80004eb6:	10054663          	bltz	a0,80004fc2 <exec+0x2fe>
    ustack[argc] = sp;
    80004eba:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ebe:	0485                	addi	s1,s1,1
    80004ec0:	008d8793          	addi	a5,s11,8
    80004ec4:	e0f43023          	sd	a5,-512(s0)
    80004ec8:	008db503          	ld	a0,8(s11)
    80004ecc:	c911                	beqz	a0,80004ee0 <exec+0x21c>
    if(argc >= MAXARG)
    80004ece:	09a1                	addi	s3,s3,8
    80004ed0:	fb3c96e3          	bne	s9,s3,80004e7c <exec+0x1b8>
  sz = sz1;
    80004ed4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ed8:	4481                	li	s1,0
    80004eda:	a84d                	j	80004f8c <exec+0x2c8>
  sp = sz;
    80004edc:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ede:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ee0:	00349793          	slli	a5,s1,0x3
    80004ee4:	f9040713          	addi	a4,s0,-112
    80004ee8:	97ba                	add	a5,a5,a4
    80004eea:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004eee:	00148693          	addi	a3,s1,1
    80004ef2:	068e                	slli	a3,a3,0x3
    80004ef4:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ef8:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004efc:	01897663          	bgeu	s2,s8,80004f08 <exec+0x244>
  sz = sz1;
    80004f00:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f04:	4481                	li	s1,0
    80004f06:	a059                	j	80004f8c <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f08:	e9040613          	addi	a2,s0,-368
    80004f0c:	85ca                	mv	a1,s2
    80004f0e:	855e                	mv	a0,s7
    80004f10:	ffffc097          	auipc	ra,0xffffc
    80004f14:	774080e7          	jalr	1908(ra) # 80001684 <copyout>
    80004f18:	0a054963          	bltz	a0,80004fca <exec+0x306>
  p->trapframe->a1 = sp;
    80004f1c:	058ab783          	ld	a5,88(s5)
    80004f20:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f24:	df843783          	ld	a5,-520(s0)
    80004f28:	0007c703          	lbu	a4,0(a5)
    80004f2c:	cf11                	beqz	a4,80004f48 <exec+0x284>
    80004f2e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f30:	02f00693          	li	a3,47
    80004f34:	a039                	j	80004f42 <exec+0x27e>
      last = s+1;
    80004f36:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004f3a:	0785                	addi	a5,a5,1
    80004f3c:	fff7c703          	lbu	a4,-1(a5)
    80004f40:	c701                	beqz	a4,80004f48 <exec+0x284>
    if(*s == '/')
    80004f42:	fed71ce3          	bne	a4,a3,80004f3a <exec+0x276>
    80004f46:	bfc5                	j	80004f36 <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f48:	4641                	li	a2,16
    80004f4a:	df843583          	ld	a1,-520(s0)
    80004f4e:	158a8513          	addi	a0,s5,344
    80004f52:	ffffc097          	auipc	ra,0xffffc
    80004f56:	ee6080e7          	jalr	-282(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f5a:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f5e:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f62:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f66:	058ab783          	ld	a5,88(s5)
    80004f6a:	e6843703          	ld	a4,-408(s0)
    80004f6e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f70:	058ab783          	ld	a5,88(s5)
    80004f74:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f78:	85ea                	mv	a1,s10
    80004f7a:	ffffd097          	auipc	ra,0xffffd
    80004f7e:	bac080e7          	jalr	-1108(ra) # 80001b26 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f82:	0004851b          	sext.w	a0,s1
    80004f86:	bbd9                	j	80004d5c <exec+0x98>
    80004f88:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f8c:	e0843583          	ld	a1,-504(s0)
    80004f90:	855e                	mv	a0,s7
    80004f92:	ffffd097          	auipc	ra,0xffffd
    80004f96:	b94080e7          	jalr	-1132(ra) # 80001b26 <proc_freepagetable>
  if(ip){
    80004f9a:	da0497e3          	bnez	s1,80004d48 <exec+0x84>
  return -1;
    80004f9e:	557d                	li	a0,-1
    80004fa0:	bb75                	j	80004d5c <exec+0x98>
    80004fa2:	e1443423          	sd	s4,-504(s0)
    80004fa6:	b7dd                	j	80004f8c <exec+0x2c8>
    80004fa8:	e1443423          	sd	s4,-504(s0)
    80004fac:	b7c5                	j	80004f8c <exec+0x2c8>
    80004fae:	e1443423          	sd	s4,-504(s0)
    80004fb2:	bfe9                	j	80004f8c <exec+0x2c8>
    80004fb4:	e1443423          	sd	s4,-504(s0)
    80004fb8:	bfd1                	j	80004f8c <exec+0x2c8>
  sz = sz1;
    80004fba:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fbe:	4481                	li	s1,0
    80004fc0:	b7f1                	j	80004f8c <exec+0x2c8>
  sz = sz1;
    80004fc2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fc6:	4481                	li	s1,0
    80004fc8:	b7d1                	j	80004f8c <exec+0x2c8>
  sz = sz1;
    80004fca:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fce:	4481                	li	s1,0
    80004fd0:	bf75                	j	80004f8c <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004fd2:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fd6:	2b05                	addiw	s6,s6,1
    80004fd8:	0389899b          	addiw	s3,s3,56
    80004fdc:	e8845783          	lhu	a5,-376(s0)
    80004fe0:	e2fb57e3          	bge	s6,a5,80004e0e <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fe4:	2981                	sext.w	s3,s3
    80004fe6:	03800713          	li	a4,56
    80004fea:	86ce                	mv	a3,s3
    80004fec:	e1840613          	addi	a2,s0,-488
    80004ff0:	4581                	li	a1,0
    80004ff2:	8526                	mv	a0,s1
    80004ff4:	fffff097          	auipc	ra,0xfffff
    80004ff8:	a6e080e7          	jalr	-1426(ra) # 80003a62 <readi>
    80004ffc:	03800793          	li	a5,56
    80005000:	f8f514e3          	bne	a0,a5,80004f88 <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    80005004:	e1842783          	lw	a5,-488(s0)
    80005008:	4705                	li	a4,1
    8000500a:	fce796e3          	bne	a5,a4,80004fd6 <exec+0x312>
    if(ph.memsz < ph.filesz)
    8000500e:	e4043903          	ld	s2,-448(s0)
    80005012:	e3843783          	ld	a5,-456(s0)
    80005016:	f8f966e3          	bltu	s2,a5,80004fa2 <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000501a:	e2843783          	ld	a5,-472(s0)
    8000501e:	993e                	add	s2,s2,a5
    80005020:	f8f964e3          	bltu	s2,a5,80004fa8 <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    80005024:	df043703          	ld	a4,-528(s0)
    80005028:	8ff9                	and	a5,a5,a4
    8000502a:	f3d1                	bnez	a5,80004fae <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000502c:	e1c42503          	lw	a0,-484(s0)
    80005030:	00000097          	auipc	ra,0x0
    80005034:	c78080e7          	jalr	-904(ra) # 80004ca8 <flags2perm>
    80005038:	86aa                	mv	a3,a0
    8000503a:	864a                	mv	a2,s2
    8000503c:	85d2                	mv	a1,s4
    8000503e:	855e                	mv	a0,s7
    80005040:	ffffc097          	auipc	ra,0xffffc
    80005044:	3ec080e7          	jalr	1004(ra) # 8000142c <uvmalloc>
    80005048:	e0a43423          	sd	a0,-504(s0)
    8000504c:	d525                	beqz	a0,80004fb4 <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000504e:	e2843d03          	ld	s10,-472(s0)
    80005052:	e2042d83          	lw	s11,-480(s0)
    80005056:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000505a:	f60c0ce3          	beqz	s8,80004fd2 <exec+0x30e>
    8000505e:	8a62                	mv	s4,s8
    80005060:	4901                	li	s2,0
    80005062:	b369                	j	80004dec <exec+0x128>

0000000080005064 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005064:	7179                	addi	sp,sp,-48
    80005066:	f406                	sd	ra,40(sp)
    80005068:	f022                	sd	s0,32(sp)
    8000506a:	ec26                	sd	s1,24(sp)
    8000506c:	e84a                	sd	s2,16(sp)
    8000506e:	1800                	addi	s0,sp,48
    80005070:	892e                	mv	s2,a1
    80005072:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005074:	fdc40593          	addi	a1,s0,-36
    80005078:	ffffe097          	auipc	ra,0xffffe
    8000507c:	aca080e7          	jalr	-1334(ra) # 80002b42 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005080:	fdc42703          	lw	a4,-36(s0)
    80005084:	47bd                	li	a5,15
    80005086:	02e7eb63          	bltu	a5,a4,800050bc <argfd+0x58>
    8000508a:	ffffd097          	auipc	ra,0xffffd
    8000508e:	93c080e7          	jalr	-1732(ra) # 800019c6 <myproc>
    80005092:	fdc42703          	lw	a4,-36(s0)
    80005096:	01a70793          	addi	a5,a4,26
    8000509a:	078e                	slli	a5,a5,0x3
    8000509c:	953e                	add	a0,a0,a5
    8000509e:	611c                	ld	a5,0(a0)
    800050a0:	c385                	beqz	a5,800050c0 <argfd+0x5c>
    return -1;
  if(pfd)
    800050a2:	00090463          	beqz	s2,800050aa <argfd+0x46>
    *pfd = fd;
    800050a6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050aa:	4501                	li	a0,0
  if(pf)
    800050ac:	c091                	beqz	s1,800050b0 <argfd+0x4c>
    *pf = f;
    800050ae:	e09c                	sd	a5,0(s1)
}
    800050b0:	70a2                	ld	ra,40(sp)
    800050b2:	7402                	ld	s0,32(sp)
    800050b4:	64e2                	ld	s1,24(sp)
    800050b6:	6942                	ld	s2,16(sp)
    800050b8:	6145                	addi	sp,sp,48
    800050ba:	8082                	ret
    return -1;
    800050bc:	557d                	li	a0,-1
    800050be:	bfcd                	j	800050b0 <argfd+0x4c>
    800050c0:	557d                	li	a0,-1
    800050c2:	b7fd                	j	800050b0 <argfd+0x4c>

00000000800050c4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050c4:	1101                	addi	sp,sp,-32
    800050c6:	ec06                	sd	ra,24(sp)
    800050c8:	e822                	sd	s0,16(sp)
    800050ca:	e426                	sd	s1,8(sp)
    800050cc:	1000                	addi	s0,sp,32
    800050ce:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050d0:	ffffd097          	auipc	ra,0xffffd
    800050d4:	8f6080e7          	jalr	-1802(ra) # 800019c6 <myproc>
    800050d8:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050da:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffdc9a0>
    800050de:	4501                	li	a0,0
    800050e0:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050e2:	6398                	ld	a4,0(a5)
    800050e4:	cb19                	beqz	a4,800050fa <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050e6:	2505                	addiw	a0,a0,1
    800050e8:	07a1                	addi	a5,a5,8
    800050ea:	fed51ce3          	bne	a0,a3,800050e2 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050ee:	557d                	li	a0,-1
}
    800050f0:	60e2                	ld	ra,24(sp)
    800050f2:	6442                	ld	s0,16(sp)
    800050f4:	64a2                	ld	s1,8(sp)
    800050f6:	6105                	addi	sp,sp,32
    800050f8:	8082                	ret
      p->ofile[fd] = f;
    800050fa:	01a50793          	addi	a5,a0,26
    800050fe:	078e                	slli	a5,a5,0x3
    80005100:	963e                	add	a2,a2,a5
    80005102:	e204                	sd	s1,0(a2)
      return fd;
    80005104:	b7f5                	j	800050f0 <fdalloc+0x2c>

0000000080005106 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005106:	715d                	addi	sp,sp,-80
    80005108:	e486                	sd	ra,72(sp)
    8000510a:	e0a2                	sd	s0,64(sp)
    8000510c:	fc26                	sd	s1,56(sp)
    8000510e:	f84a                	sd	s2,48(sp)
    80005110:	f44e                	sd	s3,40(sp)
    80005112:	f052                	sd	s4,32(sp)
    80005114:	ec56                	sd	s5,24(sp)
    80005116:	e85a                	sd	s6,16(sp)
    80005118:	0880                	addi	s0,sp,80
    8000511a:	8b2e                	mv	s6,a1
    8000511c:	89b2                	mv	s3,a2
    8000511e:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005120:	fb040593          	addi	a1,s0,-80
    80005124:	fffff097          	auipc	ra,0xfffff
    80005128:	e4e080e7          	jalr	-434(ra) # 80003f72 <nameiparent>
    8000512c:	84aa                	mv	s1,a0
    8000512e:	16050063          	beqz	a0,8000528e <create+0x188>
    return 0;

  ilock(dp);
    80005132:	ffffe097          	auipc	ra,0xffffe
    80005136:	67c080e7          	jalr	1660(ra) # 800037ae <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000513a:	4601                	li	a2,0
    8000513c:	fb040593          	addi	a1,s0,-80
    80005140:	8526                	mv	a0,s1
    80005142:	fffff097          	auipc	ra,0xfffff
    80005146:	b50080e7          	jalr	-1200(ra) # 80003c92 <dirlookup>
    8000514a:	8aaa                	mv	s5,a0
    8000514c:	c931                	beqz	a0,800051a0 <create+0x9a>
    iunlockput(dp);
    8000514e:	8526                	mv	a0,s1
    80005150:	fffff097          	auipc	ra,0xfffff
    80005154:	8c0080e7          	jalr	-1856(ra) # 80003a10 <iunlockput>
    ilock(ip);
    80005158:	8556                	mv	a0,s5
    8000515a:	ffffe097          	auipc	ra,0xffffe
    8000515e:	654080e7          	jalr	1620(ra) # 800037ae <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005162:	000b059b          	sext.w	a1,s6
    80005166:	4789                	li	a5,2
    80005168:	02f59563          	bne	a1,a5,80005192 <create+0x8c>
    8000516c:	044ad783          	lhu	a5,68(s5)
    80005170:	37f9                	addiw	a5,a5,-2
    80005172:	17c2                	slli	a5,a5,0x30
    80005174:	93c1                	srli	a5,a5,0x30
    80005176:	4705                	li	a4,1
    80005178:	00f76d63          	bltu	a4,a5,80005192 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000517c:	8556                	mv	a0,s5
    8000517e:	60a6                	ld	ra,72(sp)
    80005180:	6406                	ld	s0,64(sp)
    80005182:	74e2                	ld	s1,56(sp)
    80005184:	7942                	ld	s2,48(sp)
    80005186:	79a2                	ld	s3,40(sp)
    80005188:	7a02                	ld	s4,32(sp)
    8000518a:	6ae2                	ld	s5,24(sp)
    8000518c:	6b42                	ld	s6,16(sp)
    8000518e:	6161                	addi	sp,sp,80
    80005190:	8082                	ret
    iunlockput(ip);
    80005192:	8556                	mv	a0,s5
    80005194:	fffff097          	auipc	ra,0xfffff
    80005198:	87c080e7          	jalr	-1924(ra) # 80003a10 <iunlockput>
    return 0;
    8000519c:	4a81                	li	s5,0
    8000519e:	bff9                	j	8000517c <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800051a0:	85da                	mv	a1,s6
    800051a2:	4088                	lw	a0,0(s1)
    800051a4:	ffffe097          	auipc	ra,0xffffe
    800051a8:	46e080e7          	jalr	1134(ra) # 80003612 <ialloc>
    800051ac:	8a2a                	mv	s4,a0
    800051ae:	c921                	beqz	a0,800051fe <create+0xf8>
  ilock(ip);
    800051b0:	ffffe097          	auipc	ra,0xffffe
    800051b4:	5fe080e7          	jalr	1534(ra) # 800037ae <ilock>
  ip->major = major;
    800051b8:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800051bc:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800051c0:	4785                	li	a5,1
    800051c2:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    800051c6:	8552                	mv	a0,s4
    800051c8:	ffffe097          	auipc	ra,0xffffe
    800051cc:	51c080e7          	jalr	1308(ra) # 800036e4 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051d0:	000b059b          	sext.w	a1,s6
    800051d4:	4785                	li	a5,1
    800051d6:	02f58b63          	beq	a1,a5,8000520c <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    800051da:	004a2603          	lw	a2,4(s4)
    800051de:	fb040593          	addi	a1,s0,-80
    800051e2:	8526                	mv	a0,s1
    800051e4:	fffff097          	auipc	ra,0xfffff
    800051e8:	cbe080e7          	jalr	-834(ra) # 80003ea2 <dirlink>
    800051ec:	06054f63          	bltz	a0,8000526a <create+0x164>
  iunlockput(dp);
    800051f0:	8526                	mv	a0,s1
    800051f2:	fffff097          	auipc	ra,0xfffff
    800051f6:	81e080e7          	jalr	-2018(ra) # 80003a10 <iunlockput>
  return ip;
    800051fa:	8ad2                	mv	s5,s4
    800051fc:	b741                	j	8000517c <create+0x76>
    iunlockput(dp);
    800051fe:	8526                	mv	a0,s1
    80005200:	fffff097          	auipc	ra,0xfffff
    80005204:	810080e7          	jalr	-2032(ra) # 80003a10 <iunlockput>
    return 0;
    80005208:	8ad2                	mv	s5,s4
    8000520a:	bf8d                	j	8000517c <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000520c:	004a2603          	lw	a2,4(s4)
    80005210:	00003597          	auipc	a1,0x3
    80005214:	5d858593          	addi	a1,a1,1496 # 800087e8 <syscalls+0x2b8>
    80005218:	8552                	mv	a0,s4
    8000521a:	fffff097          	auipc	ra,0xfffff
    8000521e:	c88080e7          	jalr	-888(ra) # 80003ea2 <dirlink>
    80005222:	04054463          	bltz	a0,8000526a <create+0x164>
    80005226:	40d0                	lw	a2,4(s1)
    80005228:	00003597          	auipc	a1,0x3
    8000522c:	5c858593          	addi	a1,a1,1480 # 800087f0 <syscalls+0x2c0>
    80005230:	8552                	mv	a0,s4
    80005232:	fffff097          	auipc	ra,0xfffff
    80005236:	c70080e7          	jalr	-912(ra) # 80003ea2 <dirlink>
    8000523a:	02054863          	bltz	a0,8000526a <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    8000523e:	004a2603          	lw	a2,4(s4)
    80005242:	fb040593          	addi	a1,s0,-80
    80005246:	8526                	mv	a0,s1
    80005248:	fffff097          	auipc	ra,0xfffff
    8000524c:	c5a080e7          	jalr	-934(ra) # 80003ea2 <dirlink>
    80005250:	00054d63          	bltz	a0,8000526a <create+0x164>
    dp->nlink++;  // for ".."
    80005254:	04a4d783          	lhu	a5,74(s1)
    80005258:	2785                	addiw	a5,a5,1
    8000525a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000525e:	8526                	mv	a0,s1
    80005260:	ffffe097          	auipc	ra,0xffffe
    80005264:	484080e7          	jalr	1156(ra) # 800036e4 <iupdate>
    80005268:	b761                	j	800051f0 <create+0xea>
  ip->nlink = 0;
    8000526a:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000526e:	8552                	mv	a0,s4
    80005270:	ffffe097          	auipc	ra,0xffffe
    80005274:	474080e7          	jalr	1140(ra) # 800036e4 <iupdate>
  iunlockput(ip);
    80005278:	8552                	mv	a0,s4
    8000527a:	ffffe097          	auipc	ra,0xffffe
    8000527e:	796080e7          	jalr	1942(ra) # 80003a10 <iunlockput>
  iunlockput(dp);
    80005282:	8526                	mv	a0,s1
    80005284:	ffffe097          	auipc	ra,0xffffe
    80005288:	78c080e7          	jalr	1932(ra) # 80003a10 <iunlockput>
  return 0;
    8000528c:	bdc5                	j	8000517c <create+0x76>
    return 0;
    8000528e:	8aaa                	mv	s5,a0
    80005290:	b5f5                	j	8000517c <create+0x76>

0000000080005292 <sys_dup>:
{
    80005292:	7179                	addi	sp,sp,-48
    80005294:	f406                	sd	ra,40(sp)
    80005296:	f022                	sd	s0,32(sp)
    80005298:	ec26                	sd	s1,24(sp)
    8000529a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000529c:	fd840613          	addi	a2,s0,-40
    800052a0:	4581                	li	a1,0
    800052a2:	4501                	li	a0,0
    800052a4:	00000097          	auipc	ra,0x0
    800052a8:	dc0080e7          	jalr	-576(ra) # 80005064 <argfd>
    return -1;
    800052ac:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052ae:	02054363          	bltz	a0,800052d4 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800052b2:	fd843503          	ld	a0,-40(s0)
    800052b6:	00000097          	auipc	ra,0x0
    800052ba:	e0e080e7          	jalr	-498(ra) # 800050c4 <fdalloc>
    800052be:	84aa                	mv	s1,a0
    return -1;
    800052c0:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052c2:	00054963          	bltz	a0,800052d4 <sys_dup+0x42>
  filedup(f);
    800052c6:	fd843503          	ld	a0,-40(s0)
    800052ca:	fffff097          	auipc	ra,0xfffff
    800052ce:	320080e7          	jalr	800(ra) # 800045ea <filedup>
  return fd;
    800052d2:	87a6                	mv	a5,s1
}
    800052d4:	853e                	mv	a0,a5
    800052d6:	70a2                	ld	ra,40(sp)
    800052d8:	7402                	ld	s0,32(sp)
    800052da:	64e2                	ld	s1,24(sp)
    800052dc:	6145                	addi	sp,sp,48
    800052de:	8082                	ret

00000000800052e0 <sys_read>:
{
    800052e0:	7179                	addi	sp,sp,-48
    800052e2:	f406                	sd	ra,40(sp)
    800052e4:	f022                	sd	s0,32(sp)
    800052e6:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800052e8:	fd840593          	addi	a1,s0,-40
    800052ec:	4505                	li	a0,1
    800052ee:	ffffe097          	auipc	ra,0xffffe
    800052f2:	874080e7          	jalr	-1932(ra) # 80002b62 <argaddr>
  argint(2, &n);
    800052f6:	fe440593          	addi	a1,s0,-28
    800052fa:	4509                	li	a0,2
    800052fc:	ffffe097          	auipc	ra,0xffffe
    80005300:	846080e7          	jalr	-1978(ra) # 80002b42 <argint>
  if(argfd(0, 0, &f) < 0)
    80005304:	fe840613          	addi	a2,s0,-24
    80005308:	4581                	li	a1,0
    8000530a:	4501                	li	a0,0
    8000530c:	00000097          	auipc	ra,0x0
    80005310:	d58080e7          	jalr	-680(ra) # 80005064 <argfd>
    80005314:	87aa                	mv	a5,a0
    return -1;
    80005316:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005318:	0007cc63          	bltz	a5,80005330 <sys_read+0x50>
  return fileread(f, p, n);
    8000531c:	fe442603          	lw	a2,-28(s0)
    80005320:	fd843583          	ld	a1,-40(s0)
    80005324:	fe843503          	ld	a0,-24(s0)
    80005328:	fffff097          	auipc	ra,0xfffff
    8000532c:	44e080e7          	jalr	1102(ra) # 80004776 <fileread>
}
    80005330:	70a2                	ld	ra,40(sp)
    80005332:	7402                	ld	s0,32(sp)
    80005334:	6145                	addi	sp,sp,48
    80005336:	8082                	ret

0000000080005338 <sys_write>:
{
    80005338:	7179                	addi	sp,sp,-48
    8000533a:	f406                	sd	ra,40(sp)
    8000533c:	f022                	sd	s0,32(sp)
    8000533e:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005340:	fd840593          	addi	a1,s0,-40
    80005344:	4505                	li	a0,1
    80005346:	ffffe097          	auipc	ra,0xffffe
    8000534a:	81c080e7          	jalr	-2020(ra) # 80002b62 <argaddr>
  argint(2, &n);
    8000534e:	fe440593          	addi	a1,s0,-28
    80005352:	4509                	li	a0,2
    80005354:	ffffd097          	auipc	ra,0xffffd
    80005358:	7ee080e7          	jalr	2030(ra) # 80002b42 <argint>
  if(argfd(0, 0, &f) < 0)
    8000535c:	fe840613          	addi	a2,s0,-24
    80005360:	4581                	li	a1,0
    80005362:	4501                	li	a0,0
    80005364:	00000097          	auipc	ra,0x0
    80005368:	d00080e7          	jalr	-768(ra) # 80005064 <argfd>
    8000536c:	87aa                	mv	a5,a0
    return -1;
    8000536e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005370:	0007cc63          	bltz	a5,80005388 <sys_write+0x50>
  return filewrite(f, p, n);
    80005374:	fe442603          	lw	a2,-28(s0)
    80005378:	fd843583          	ld	a1,-40(s0)
    8000537c:	fe843503          	ld	a0,-24(s0)
    80005380:	fffff097          	auipc	ra,0xfffff
    80005384:	4b8080e7          	jalr	1208(ra) # 80004838 <filewrite>
}
    80005388:	70a2                	ld	ra,40(sp)
    8000538a:	7402                	ld	s0,32(sp)
    8000538c:	6145                	addi	sp,sp,48
    8000538e:	8082                	ret

0000000080005390 <sys_close>:
{
    80005390:	1101                	addi	sp,sp,-32
    80005392:	ec06                	sd	ra,24(sp)
    80005394:	e822                	sd	s0,16(sp)
    80005396:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005398:	fe040613          	addi	a2,s0,-32
    8000539c:	fec40593          	addi	a1,s0,-20
    800053a0:	4501                	li	a0,0
    800053a2:	00000097          	auipc	ra,0x0
    800053a6:	cc2080e7          	jalr	-830(ra) # 80005064 <argfd>
    return -1;
    800053aa:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053ac:	02054463          	bltz	a0,800053d4 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053b0:	ffffc097          	auipc	ra,0xffffc
    800053b4:	616080e7          	jalr	1558(ra) # 800019c6 <myproc>
    800053b8:	fec42783          	lw	a5,-20(s0)
    800053bc:	07e9                	addi	a5,a5,26
    800053be:	078e                	slli	a5,a5,0x3
    800053c0:	97aa                	add	a5,a5,a0
    800053c2:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800053c6:	fe043503          	ld	a0,-32(s0)
    800053ca:	fffff097          	auipc	ra,0xfffff
    800053ce:	272080e7          	jalr	626(ra) # 8000463c <fileclose>
  return 0;
    800053d2:	4781                	li	a5,0
}
    800053d4:	853e                	mv	a0,a5
    800053d6:	60e2                	ld	ra,24(sp)
    800053d8:	6442                	ld	s0,16(sp)
    800053da:	6105                	addi	sp,sp,32
    800053dc:	8082                	ret

00000000800053de <sys_fstat>:
{
    800053de:	1101                	addi	sp,sp,-32
    800053e0:	ec06                	sd	ra,24(sp)
    800053e2:	e822                	sd	s0,16(sp)
    800053e4:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800053e6:	fe040593          	addi	a1,s0,-32
    800053ea:	4505                	li	a0,1
    800053ec:	ffffd097          	auipc	ra,0xffffd
    800053f0:	776080e7          	jalr	1910(ra) # 80002b62 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800053f4:	fe840613          	addi	a2,s0,-24
    800053f8:	4581                	li	a1,0
    800053fa:	4501                	li	a0,0
    800053fc:	00000097          	auipc	ra,0x0
    80005400:	c68080e7          	jalr	-920(ra) # 80005064 <argfd>
    80005404:	87aa                	mv	a5,a0
    return -1;
    80005406:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005408:	0007ca63          	bltz	a5,8000541c <sys_fstat+0x3e>
  return filestat(f, st);
    8000540c:	fe043583          	ld	a1,-32(s0)
    80005410:	fe843503          	ld	a0,-24(s0)
    80005414:	fffff097          	auipc	ra,0xfffff
    80005418:	2f0080e7          	jalr	752(ra) # 80004704 <filestat>
}
    8000541c:	60e2                	ld	ra,24(sp)
    8000541e:	6442                	ld	s0,16(sp)
    80005420:	6105                	addi	sp,sp,32
    80005422:	8082                	ret

0000000080005424 <sys_link>:
{
    80005424:	7169                	addi	sp,sp,-304
    80005426:	f606                	sd	ra,296(sp)
    80005428:	f222                	sd	s0,288(sp)
    8000542a:	ee26                	sd	s1,280(sp)
    8000542c:	ea4a                	sd	s2,272(sp)
    8000542e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005430:	08000613          	li	a2,128
    80005434:	ed040593          	addi	a1,s0,-304
    80005438:	4501                	li	a0,0
    8000543a:	ffffd097          	auipc	ra,0xffffd
    8000543e:	748080e7          	jalr	1864(ra) # 80002b82 <argstr>
    return -1;
    80005442:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005444:	10054e63          	bltz	a0,80005560 <sys_link+0x13c>
    80005448:	08000613          	li	a2,128
    8000544c:	f5040593          	addi	a1,s0,-176
    80005450:	4505                	li	a0,1
    80005452:	ffffd097          	auipc	ra,0xffffd
    80005456:	730080e7          	jalr	1840(ra) # 80002b82 <argstr>
    return -1;
    8000545a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000545c:	10054263          	bltz	a0,80005560 <sys_link+0x13c>
  begin_op();
    80005460:	fffff097          	auipc	ra,0xfffff
    80005464:	d10080e7          	jalr	-752(ra) # 80004170 <begin_op>
  if((ip = namei(old)) == 0){
    80005468:	ed040513          	addi	a0,s0,-304
    8000546c:	fffff097          	auipc	ra,0xfffff
    80005470:	ae8080e7          	jalr	-1304(ra) # 80003f54 <namei>
    80005474:	84aa                	mv	s1,a0
    80005476:	c551                	beqz	a0,80005502 <sys_link+0xde>
  ilock(ip);
    80005478:	ffffe097          	auipc	ra,0xffffe
    8000547c:	336080e7          	jalr	822(ra) # 800037ae <ilock>
  if(ip->type == T_DIR){
    80005480:	04449703          	lh	a4,68(s1)
    80005484:	4785                	li	a5,1
    80005486:	08f70463          	beq	a4,a5,8000550e <sys_link+0xea>
  ip->nlink++;
    8000548a:	04a4d783          	lhu	a5,74(s1)
    8000548e:	2785                	addiw	a5,a5,1
    80005490:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005494:	8526                	mv	a0,s1
    80005496:	ffffe097          	auipc	ra,0xffffe
    8000549a:	24e080e7          	jalr	590(ra) # 800036e4 <iupdate>
  iunlock(ip);
    8000549e:	8526                	mv	a0,s1
    800054a0:	ffffe097          	auipc	ra,0xffffe
    800054a4:	3d0080e7          	jalr	976(ra) # 80003870 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054a8:	fd040593          	addi	a1,s0,-48
    800054ac:	f5040513          	addi	a0,s0,-176
    800054b0:	fffff097          	auipc	ra,0xfffff
    800054b4:	ac2080e7          	jalr	-1342(ra) # 80003f72 <nameiparent>
    800054b8:	892a                	mv	s2,a0
    800054ba:	c935                	beqz	a0,8000552e <sys_link+0x10a>
  ilock(dp);
    800054bc:	ffffe097          	auipc	ra,0xffffe
    800054c0:	2f2080e7          	jalr	754(ra) # 800037ae <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054c4:	00092703          	lw	a4,0(s2)
    800054c8:	409c                	lw	a5,0(s1)
    800054ca:	04f71d63          	bne	a4,a5,80005524 <sys_link+0x100>
    800054ce:	40d0                	lw	a2,4(s1)
    800054d0:	fd040593          	addi	a1,s0,-48
    800054d4:	854a                	mv	a0,s2
    800054d6:	fffff097          	auipc	ra,0xfffff
    800054da:	9cc080e7          	jalr	-1588(ra) # 80003ea2 <dirlink>
    800054de:	04054363          	bltz	a0,80005524 <sys_link+0x100>
  iunlockput(dp);
    800054e2:	854a                	mv	a0,s2
    800054e4:	ffffe097          	auipc	ra,0xffffe
    800054e8:	52c080e7          	jalr	1324(ra) # 80003a10 <iunlockput>
  iput(ip);
    800054ec:	8526                	mv	a0,s1
    800054ee:	ffffe097          	auipc	ra,0xffffe
    800054f2:	47a080e7          	jalr	1146(ra) # 80003968 <iput>
  end_op();
    800054f6:	fffff097          	auipc	ra,0xfffff
    800054fa:	cfa080e7          	jalr	-774(ra) # 800041f0 <end_op>
  return 0;
    800054fe:	4781                	li	a5,0
    80005500:	a085                	j	80005560 <sys_link+0x13c>
    end_op();
    80005502:	fffff097          	auipc	ra,0xfffff
    80005506:	cee080e7          	jalr	-786(ra) # 800041f0 <end_op>
    return -1;
    8000550a:	57fd                	li	a5,-1
    8000550c:	a891                	j	80005560 <sys_link+0x13c>
    iunlockput(ip);
    8000550e:	8526                	mv	a0,s1
    80005510:	ffffe097          	auipc	ra,0xffffe
    80005514:	500080e7          	jalr	1280(ra) # 80003a10 <iunlockput>
    end_op();
    80005518:	fffff097          	auipc	ra,0xfffff
    8000551c:	cd8080e7          	jalr	-808(ra) # 800041f0 <end_op>
    return -1;
    80005520:	57fd                	li	a5,-1
    80005522:	a83d                	j	80005560 <sys_link+0x13c>
    iunlockput(dp);
    80005524:	854a                	mv	a0,s2
    80005526:	ffffe097          	auipc	ra,0xffffe
    8000552a:	4ea080e7          	jalr	1258(ra) # 80003a10 <iunlockput>
  ilock(ip);
    8000552e:	8526                	mv	a0,s1
    80005530:	ffffe097          	auipc	ra,0xffffe
    80005534:	27e080e7          	jalr	638(ra) # 800037ae <ilock>
  ip->nlink--;
    80005538:	04a4d783          	lhu	a5,74(s1)
    8000553c:	37fd                	addiw	a5,a5,-1
    8000553e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005542:	8526                	mv	a0,s1
    80005544:	ffffe097          	auipc	ra,0xffffe
    80005548:	1a0080e7          	jalr	416(ra) # 800036e4 <iupdate>
  iunlockput(ip);
    8000554c:	8526                	mv	a0,s1
    8000554e:	ffffe097          	auipc	ra,0xffffe
    80005552:	4c2080e7          	jalr	1218(ra) # 80003a10 <iunlockput>
  end_op();
    80005556:	fffff097          	auipc	ra,0xfffff
    8000555a:	c9a080e7          	jalr	-870(ra) # 800041f0 <end_op>
  return -1;
    8000555e:	57fd                	li	a5,-1
}
    80005560:	853e                	mv	a0,a5
    80005562:	70b2                	ld	ra,296(sp)
    80005564:	7412                	ld	s0,288(sp)
    80005566:	64f2                	ld	s1,280(sp)
    80005568:	6952                	ld	s2,272(sp)
    8000556a:	6155                	addi	sp,sp,304
    8000556c:	8082                	ret

000000008000556e <sys_unlink>:
{
    8000556e:	7151                	addi	sp,sp,-240
    80005570:	f586                	sd	ra,232(sp)
    80005572:	f1a2                	sd	s0,224(sp)
    80005574:	eda6                	sd	s1,216(sp)
    80005576:	e9ca                	sd	s2,208(sp)
    80005578:	e5ce                	sd	s3,200(sp)
    8000557a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000557c:	08000613          	li	a2,128
    80005580:	f3040593          	addi	a1,s0,-208
    80005584:	4501                	li	a0,0
    80005586:	ffffd097          	auipc	ra,0xffffd
    8000558a:	5fc080e7          	jalr	1532(ra) # 80002b82 <argstr>
    8000558e:	18054163          	bltz	a0,80005710 <sys_unlink+0x1a2>
  begin_op();
    80005592:	fffff097          	auipc	ra,0xfffff
    80005596:	bde080e7          	jalr	-1058(ra) # 80004170 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000559a:	fb040593          	addi	a1,s0,-80
    8000559e:	f3040513          	addi	a0,s0,-208
    800055a2:	fffff097          	auipc	ra,0xfffff
    800055a6:	9d0080e7          	jalr	-1584(ra) # 80003f72 <nameiparent>
    800055aa:	84aa                	mv	s1,a0
    800055ac:	c979                	beqz	a0,80005682 <sys_unlink+0x114>
  ilock(dp);
    800055ae:	ffffe097          	auipc	ra,0xffffe
    800055b2:	200080e7          	jalr	512(ra) # 800037ae <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055b6:	00003597          	auipc	a1,0x3
    800055ba:	23258593          	addi	a1,a1,562 # 800087e8 <syscalls+0x2b8>
    800055be:	fb040513          	addi	a0,s0,-80
    800055c2:	ffffe097          	auipc	ra,0xffffe
    800055c6:	6b6080e7          	jalr	1718(ra) # 80003c78 <namecmp>
    800055ca:	14050a63          	beqz	a0,8000571e <sys_unlink+0x1b0>
    800055ce:	00003597          	auipc	a1,0x3
    800055d2:	22258593          	addi	a1,a1,546 # 800087f0 <syscalls+0x2c0>
    800055d6:	fb040513          	addi	a0,s0,-80
    800055da:	ffffe097          	auipc	ra,0xffffe
    800055de:	69e080e7          	jalr	1694(ra) # 80003c78 <namecmp>
    800055e2:	12050e63          	beqz	a0,8000571e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055e6:	f2c40613          	addi	a2,s0,-212
    800055ea:	fb040593          	addi	a1,s0,-80
    800055ee:	8526                	mv	a0,s1
    800055f0:	ffffe097          	auipc	ra,0xffffe
    800055f4:	6a2080e7          	jalr	1698(ra) # 80003c92 <dirlookup>
    800055f8:	892a                	mv	s2,a0
    800055fa:	12050263          	beqz	a0,8000571e <sys_unlink+0x1b0>
  ilock(ip);
    800055fe:	ffffe097          	auipc	ra,0xffffe
    80005602:	1b0080e7          	jalr	432(ra) # 800037ae <ilock>
  if(ip->nlink < 1)
    80005606:	04a91783          	lh	a5,74(s2)
    8000560a:	08f05263          	blez	a5,8000568e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000560e:	04491703          	lh	a4,68(s2)
    80005612:	4785                	li	a5,1
    80005614:	08f70563          	beq	a4,a5,8000569e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005618:	4641                	li	a2,16
    8000561a:	4581                	li	a1,0
    8000561c:	fc040513          	addi	a0,s0,-64
    80005620:	ffffb097          	auipc	ra,0xffffb
    80005624:	6c6080e7          	jalr	1734(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005628:	4741                	li	a4,16
    8000562a:	f2c42683          	lw	a3,-212(s0)
    8000562e:	fc040613          	addi	a2,s0,-64
    80005632:	4581                	li	a1,0
    80005634:	8526                	mv	a0,s1
    80005636:	ffffe097          	auipc	ra,0xffffe
    8000563a:	524080e7          	jalr	1316(ra) # 80003b5a <writei>
    8000563e:	47c1                	li	a5,16
    80005640:	0af51563          	bne	a0,a5,800056ea <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005644:	04491703          	lh	a4,68(s2)
    80005648:	4785                	li	a5,1
    8000564a:	0af70863          	beq	a4,a5,800056fa <sys_unlink+0x18c>
  iunlockput(dp);
    8000564e:	8526                	mv	a0,s1
    80005650:	ffffe097          	auipc	ra,0xffffe
    80005654:	3c0080e7          	jalr	960(ra) # 80003a10 <iunlockput>
  ip->nlink--;
    80005658:	04a95783          	lhu	a5,74(s2)
    8000565c:	37fd                	addiw	a5,a5,-1
    8000565e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005662:	854a                	mv	a0,s2
    80005664:	ffffe097          	auipc	ra,0xffffe
    80005668:	080080e7          	jalr	128(ra) # 800036e4 <iupdate>
  iunlockput(ip);
    8000566c:	854a                	mv	a0,s2
    8000566e:	ffffe097          	auipc	ra,0xffffe
    80005672:	3a2080e7          	jalr	930(ra) # 80003a10 <iunlockput>
  end_op();
    80005676:	fffff097          	auipc	ra,0xfffff
    8000567a:	b7a080e7          	jalr	-1158(ra) # 800041f0 <end_op>
  return 0;
    8000567e:	4501                	li	a0,0
    80005680:	a84d                	j	80005732 <sys_unlink+0x1c4>
    end_op();
    80005682:	fffff097          	auipc	ra,0xfffff
    80005686:	b6e080e7          	jalr	-1170(ra) # 800041f0 <end_op>
    return -1;
    8000568a:	557d                	li	a0,-1
    8000568c:	a05d                	j	80005732 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000568e:	00003517          	auipc	a0,0x3
    80005692:	16a50513          	addi	a0,a0,362 # 800087f8 <syscalls+0x2c8>
    80005696:	ffffb097          	auipc	ra,0xffffb
    8000569a:	eae080e7          	jalr	-338(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000569e:	04c92703          	lw	a4,76(s2)
    800056a2:	02000793          	li	a5,32
    800056a6:	f6e7f9e3          	bgeu	a5,a4,80005618 <sys_unlink+0xaa>
    800056aa:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056ae:	4741                	li	a4,16
    800056b0:	86ce                	mv	a3,s3
    800056b2:	f1840613          	addi	a2,s0,-232
    800056b6:	4581                	li	a1,0
    800056b8:	854a                	mv	a0,s2
    800056ba:	ffffe097          	auipc	ra,0xffffe
    800056be:	3a8080e7          	jalr	936(ra) # 80003a62 <readi>
    800056c2:	47c1                	li	a5,16
    800056c4:	00f51b63          	bne	a0,a5,800056da <sys_unlink+0x16c>
    if(de.inum != 0)
    800056c8:	f1845783          	lhu	a5,-232(s0)
    800056cc:	e7a1                	bnez	a5,80005714 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056ce:	29c1                	addiw	s3,s3,16
    800056d0:	04c92783          	lw	a5,76(s2)
    800056d4:	fcf9ede3          	bltu	s3,a5,800056ae <sys_unlink+0x140>
    800056d8:	b781                	j	80005618 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056da:	00003517          	auipc	a0,0x3
    800056de:	13650513          	addi	a0,a0,310 # 80008810 <syscalls+0x2e0>
    800056e2:	ffffb097          	auipc	ra,0xffffb
    800056e6:	e62080e7          	jalr	-414(ra) # 80000544 <panic>
    panic("unlink: writei");
    800056ea:	00003517          	auipc	a0,0x3
    800056ee:	13e50513          	addi	a0,a0,318 # 80008828 <syscalls+0x2f8>
    800056f2:	ffffb097          	auipc	ra,0xffffb
    800056f6:	e52080e7          	jalr	-430(ra) # 80000544 <panic>
    dp->nlink--;
    800056fa:	04a4d783          	lhu	a5,74(s1)
    800056fe:	37fd                	addiw	a5,a5,-1
    80005700:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005704:	8526                	mv	a0,s1
    80005706:	ffffe097          	auipc	ra,0xffffe
    8000570a:	fde080e7          	jalr	-34(ra) # 800036e4 <iupdate>
    8000570e:	b781                	j	8000564e <sys_unlink+0xe0>
    return -1;
    80005710:	557d                	li	a0,-1
    80005712:	a005                	j	80005732 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005714:	854a                	mv	a0,s2
    80005716:	ffffe097          	auipc	ra,0xffffe
    8000571a:	2fa080e7          	jalr	762(ra) # 80003a10 <iunlockput>
  iunlockput(dp);
    8000571e:	8526                	mv	a0,s1
    80005720:	ffffe097          	auipc	ra,0xffffe
    80005724:	2f0080e7          	jalr	752(ra) # 80003a10 <iunlockput>
  end_op();
    80005728:	fffff097          	auipc	ra,0xfffff
    8000572c:	ac8080e7          	jalr	-1336(ra) # 800041f0 <end_op>
  return -1;
    80005730:	557d                	li	a0,-1
}
    80005732:	70ae                	ld	ra,232(sp)
    80005734:	740e                	ld	s0,224(sp)
    80005736:	64ee                	ld	s1,216(sp)
    80005738:	694e                	ld	s2,208(sp)
    8000573a:	69ae                	ld	s3,200(sp)
    8000573c:	616d                	addi	sp,sp,240
    8000573e:	8082                	ret

0000000080005740 <sys_open>:

uint64
sys_open(void)
{
    80005740:	7131                	addi	sp,sp,-192
    80005742:	fd06                	sd	ra,184(sp)
    80005744:	f922                	sd	s0,176(sp)
    80005746:	f526                	sd	s1,168(sp)
    80005748:	f14a                	sd	s2,160(sp)
    8000574a:	ed4e                	sd	s3,152(sp)
    8000574c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000574e:	f4c40593          	addi	a1,s0,-180
    80005752:	4505                	li	a0,1
    80005754:	ffffd097          	auipc	ra,0xffffd
    80005758:	3ee080e7          	jalr	1006(ra) # 80002b42 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000575c:	08000613          	li	a2,128
    80005760:	f5040593          	addi	a1,s0,-176
    80005764:	4501                	li	a0,0
    80005766:	ffffd097          	auipc	ra,0xffffd
    8000576a:	41c080e7          	jalr	1052(ra) # 80002b82 <argstr>
    8000576e:	87aa                	mv	a5,a0
    return -1;
    80005770:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005772:	0a07c963          	bltz	a5,80005824 <sys_open+0xe4>

  begin_op();
    80005776:	fffff097          	auipc	ra,0xfffff
    8000577a:	9fa080e7          	jalr	-1542(ra) # 80004170 <begin_op>

  if(omode & O_CREATE){
    8000577e:	f4c42783          	lw	a5,-180(s0)
    80005782:	2007f793          	andi	a5,a5,512
    80005786:	cfc5                	beqz	a5,8000583e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005788:	4681                	li	a3,0
    8000578a:	4601                	li	a2,0
    8000578c:	4589                	li	a1,2
    8000578e:	f5040513          	addi	a0,s0,-176
    80005792:	00000097          	auipc	ra,0x0
    80005796:	974080e7          	jalr	-1676(ra) # 80005106 <create>
    8000579a:	84aa                	mv	s1,a0
    if(ip == 0){
    8000579c:	c959                	beqz	a0,80005832 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000579e:	04449703          	lh	a4,68(s1)
    800057a2:	478d                	li	a5,3
    800057a4:	00f71763          	bne	a4,a5,800057b2 <sys_open+0x72>
    800057a8:	0464d703          	lhu	a4,70(s1)
    800057ac:	47a5                	li	a5,9
    800057ae:	0ce7ed63          	bltu	a5,a4,80005888 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057b2:	fffff097          	auipc	ra,0xfffff
    800057b6:	dce080e7          	jalr	-562(ra) # 80004580 <filealloc>
    800057ba:	89aa                	mv	s3,a0
    800057bc:	10050363          	beqz	a0,800058c2 <sys_open+0x182>
    800057c0:	00000097          	auipc	ra,0x0
    800057c4:	904080e7          	jalr	-1788(ra) # 800050c4 <fdalloc>
    800057c8:	892a                	mv	s2,a0
    800057ca:	0e054763          	bltz	a0,800058b8 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057ce:	04449703          	lh	a4,68(s1)
    800057d2:	478d                	li	a5,3
    800057d4:	0cf70563          	beq	a4,a5,8000589e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057d8:	4789                	li	a5,2
    800057da:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057de:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057e2:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057e6:	f4c42783          	lw	a5,-180(s0)
    800057ea:	0017c713          	xori	a4,a5,1
    800057ee:	8b05                	andi	a4,a4,1
    800057f0:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057f4:	0037f713          	andi	a4,a5,3
    800057f8:	00e03733          	snez	a4,a4
    800057fc:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005800:	4007f793          	andi	a5,a5,1024
    80005804:	c791                	beqz	a5,80005810 <sys_open+0xd0>
    80005806:	04449703          	lh	a4,68(s1)
    8000580a:	4789                	li	a5,2
    8000580c:	0af70063          	beq	a4,a5,800058ac <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005810:	8526                	mv	a0,s1
    80005812:	ffffe097          	auipc	ra,0xffffe
    80005816:	05e080e7          	jalr	94(ra) # 80003870 <iunlock>
  end_op();
    8000581a:	fffff097          	auipc	ra,0xfffff
    8000581e:	9d6080e7          	jalr	-1578(ra) # 800041f0 <end_op>

  return fd;
    80005822:	854a                	mv	a0,s2
}
    80005824:	70ea                	ld	ra,184(sp)
    80005826:	744a                	ld	s0,176(sp)
    80005828:	74aa                	ld	s1,168(sp)
    8000582a:	790a                	ld	s2,160(sp)
    8000582c:	69ea                	ld	s3,152(sp)
    8000582e:	6129                	addi	sp,sp,192
    80005830:	8082                	ret
      end_op();
    80005832:	fffff097          	auipc	ra,0xfffff
    80005836:	9be080e7          	jalr	-1602(ra) # 800041f0 <end_op>
      return -1;
    8000583a:	557d                	li	a0,-1
    8000583c:	b7e5                	j	80005824 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000583e:	f5040513          	addi	a0,s0,-176
    80005842:	ffffe097          	auipc	ra,0xffffe
    80005846:	712080e7          	jalr	1810(ra) # 80003f54 <namei>
    8000584a:	84aa                	mv	s1,a0
    8000584c:	c905                	beqz	a0,8000587c <sys_open+0x13c>
    ilock(ip);
    8000584e:	ffffe097          	auipc	ra,0xffffe
    80005852:	f60080e7          	jalr	-160(ra) # 800037ae <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005856:	04449703          	lh	a4,68(s1)
    8000585a:	4785                	li	a5,1
    8000585c:	f4f711e3          	bne	a4,a5,8000579e <sys_open+0x5e>
    80005860:	f4c42783          	lw	a5,-180(s0)
    80005864:	d7b9                	beqz	a5,800057b2 <sys_open+0x72>
      iunlockput(ip);
    80005866:	8526                	mv	a0,s1
    80005868:	ffffe097          	auipc	ra,0xffffe
    8000586c:	1a8080e7          	jalr	424(ra) # 80003a10 <iunlockput>
      end_op();
    80005870:	fffff097          	auipc	ra,0xfffff
    80005874:	980080e7          	jalr	-1664(ra) # 800041f0 <end_op>
      return -1;
    80005878:	557d                	li	a0,-1
    8000587a:	b76d                	j	80005824 <sys_open+0xe4>
      end_op();
    8000587c:	fffff097          	auipc	ra,0xfffff
    80005880:	974080e7          	jalr	-1676(ra) # 800041f0 <end_op>
      return -1;
    80005884:	557d                	li	a0,-1
    80005886:	bf79                	j	80005824 <sys_open+0xe4>
    iunlockput(ip);
    80005888:	8526                	mv	a0,s1
    8000588a:	ffffe097          	auipc	ra,0xffffe
    8000588e:	186080e7          	jalr	390(ra) # 80003a10 <iunlockput>
    end_op();
    80005892:	fffff097          	auipc	ra,0xfffff
    80005896:	95e080e7          	jalr	-1698(ra) # 800041f0 <end_op>
    return -1;
    8000589a:	557d                	li	a0,-1
    8000589c:	b761                	j	80005824 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000589e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058a2:	04649783          	lh	a5,70(s1)
    800058a6:	02f99223          	sh	a5,36(s3)
    800058aa:	bf25                	j	800057e2 <sys_open+0xa2>
    itrunc(ip);
    800058ac:	8526                	mv	a0,s1
    800058ae:	ffffe097          	auipc	ra,0xffffe
    800058b2:	00e080e7          	jalr	14(ra) # 800038bc <itrunc>
    800058b6:	bfa9                	j	80005810 <sys_open+0xd0>
      fileclose(f);
    800058b8:	854e                	mv	a0,s3
    800058ba:	fffff097          	auipc	ra,0xfffff
    800058be:	d82080e7          	jalr	-638(ra) # 8000463c <fileclose>
    iunlockput(ip);
    800058c2:	8526                	mv	a0,s1
    800058c4:	ffffe097          	auipc	ra,0xffffe
    800058c8:	14c080e7          	jalr	332(ra) # 80003a10 <iunlockput>
    end_op();
    800058cc:	fffff097          	auipc	ra,0xfffff
    800058d0:	924080e7          	jalr	-1756(ra) # 800041f0 <end_op>
    return -1;
    800058d4:	557d                	li	a0,-1
    800058d6:	b7b9                	j	80005824 <sys_open+0xe4>

00000000800058d8 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058d8:	7175                	addi	sp,sp,-144
    800058da:	e506                	sd	ra,136(sp)
    800058dc:	e122                	sd	s0,128(sp)
    800058de:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058e0:	fffff097          	auipc	ra,0xfffff
    800058e4:	890080e7          	jalr	-1904(ra) # 80004170 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058e8:	08000613          	li	a2,128
    800058ec:	f7040593          	addi	a1,s0,-144
    800058f0:	4501                	li	a0,0
    800058f2:	ffffd097          	auipc	ra,0xffffd
    800058f6:	290080e7          	jalr	656(ra) # 80002b82 <argstr>
    800058fa:	02054963          	bltz	a0,8000592c <sys_mkdir+0x54>
    800058fe:	4681                	li	a3,0
    80005900:	4601                	li	a2,0
    80005902:	4585                	li	a1,1
    80005904:	f7040513          	addi	a0,s0,-144
    80005908:	fffff097          	auipc	ra,0xfffff
    8000590c:	7fe080e7          	jalr	2046(ra) # 80005106 <create>
    80005910:	cd11                	beqz	a0,8000592c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005912:	ffffe097          	auipc	ra,0xffffe
    80005916:	0fe080e7          	jalr	254(ra) # 80003a10 <iunlockput>
  end_op();
    8000591a:	fffff097          	auipc	ra,0xfffff
    8000591e:	8d6080e7          	jalr	-1834(ra) # 800041f0 <end_op>
  return 0;
    80005922:	4501                	li	a0,0
}
    80005924:	60aa                	ld	ra,136(sp)
    80005926:	640a                	ld	s0,128(sp)
    80005928:	6149                	addi	sp,sp,144
    8000592a:	8082                	ret
    end_op();
    8000592c:	fffff097          	auipc	ra,0xfffff
    80005930:	8c4080e7          	jalr	-1852(ra) # 800041f0 <end_op>
    return -1;
    80005934:	557d                	li	a0,-1
    80005936:	b7fd                	j	80005924 <sys_mkdir+0x4c>

0000000080005938 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005938:	7135                	addi	sp,sp,-160
    8000593a:	ed06                	sd	ra,152(sp)
    8000593c:	e922                	sd	s0,144(sp)
    8000593e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005940:	fffff097          	auipc	ra,0xfffff
    80005944:	830080e7          	jalr	-2000(ra) # 80004170 <begin_op>
  argint(1, &major);
    80005948:	f6c40593          	addi	a1,s0,-148
    8000594c:	4505                	li	a0,1
    8000594e:	ffffd097          	auipc	ra,0xffffd
    80005952:	1f4080e7          	jalr	500(ra) # 80002b42 <argint>
  argint(2, &minor);
    80005956:	f6840593          	addi	a1,s0,-152
    8000595a:	4509                	li	a0,2
    8000595c:	ffffd097          	auipc	ra,0xffffd
    80005960:	1e6080e7          	jalr	486(ra) # 80002b42 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005964:	08000613          	li	a2,128
    80005968:	f7040593          	addi	a1,s0,-144
    8000596c:	4501                	li	a0,0
    8000596e:	ffffd097          	auipc	ra,0xffffd
    80005972:	214080e7          	jalr	532(ra) # 80002b82 <argstr>
    80005976:	02054b63          	bltz	a0,800059ac <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000597a:	f6841683          	lh	a3,-152(s0)
    8000597e:	f6c41603          	lh	a2,-148(s0)
    80005982:	458d                	li	a1,3
    80005984:	f7040513          	addi	a0,s0,-144
    80005988:	fffff097          	auipc	ra,0xfffff
    8000598c:	77e080e7          	jalr	1918(ra) # 80005106 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005990:	cd11                	beqz	a0,800059ac <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005992:	ffffe097          	auipc	ra,0xffffe
    80005996:	07e080e7          	jalr	126(ra) # 80003a10 <iunlockput>
  end_op();
    8000599a:	fffff097          	auipc	ra,0xfffff
    8000599e:	856080e7          	jalr	-1962(ra) # 800041f0 <end_op>
  return 0;
    800059a2:	4501                	li	a0,0
}
    800059a4:	60ea                	ld	ra,152(sp)
    800059a6:	644a                	ld	s0,144(sp)
    800059a8:	610d                	addi	sp,sp,160
    800059aa:	8082                	ret
    end_op();
    800059ac:	fffff097          	auipc	ra,0xfffff
    800059b0:	844080e7          	jalr	-1980(ra) # 800041f0 <end_op>
    return -1;
    800059b4:	557d                	li	a0,-1
    800059b6:	b7fd                	j	800059a4 <sys_mknod+0x6c>

00000000800059b8 <sys_chdir>:

uint64
sys_chdir(void)
{
    800059b8:	7135                	addi	sp,sp,-160
    800059ba:	ed06                	sd	ra,152(sp)
    800059bc:	e922                	sd	s0,144(sp)
    800059be:	e526                	sd	s1,136(sp)
    800059c0:	e14a                	sd	s2,128(sp)
    800059c2:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059c4:	ffffc097          	auipc	ra,0xffffc
    800059c8:	002080e7          	jalr	2(ra) # 800019c6 <myproc>
    800059cc:	892a                	mv	s2,a0
  
  begin_op();
    800059ce:	ffffe097          	auipc	ra,0xffffe
    800059d2:	7a2080e7          	jalr	1954(ra) # 80004170 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059d6:	08000613          	li	a2,128
    800059da:	f6040593          	addi	a1,s0,-160
    800059de:	4501                	li	a0,0
    800059e0:	ffffd097          	auipc	ra,0xffffd
    800059e4:	1a2080e7          	jalr	418(ra) # 80002b82 <argstr>
    800059e8:	04054b63          	bltz	a0,80005a3e <sys_chdir+0x86>
    800059ec:	f6040513          	addi	a0,s0,-160
    800059f0:	ffffe097          	auipc	ra,0xffffe
    800059f4:	564080e7          	jalr	1380(ra) # 80003f54 <namei>
    800059f8:	84aa                	mv	s1,a0
    800059fa:	c131                	beqz	a0,80005a3e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059fc:	ffffe097          	auipc	ra,0xffffe
    80005a00:	db2080e7          	jalr	-590(ra) # 800037ae <ilock>
  if(ip->type != T_DIR){
    80005a04:	04449703          	lh	a4,68(s1)
    80005a08:	4785                	li	a5,1
    80005a0a:	04f71063          	bne	a4,a5,80005a4a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a0e:	8526                	mv	a0,s1
    80005a10:	ffffe097          	auipc	ra,0xffffe
    80005a14:	e60080e7          	jalr	-416(ra) # 80003870 <iunlock>
  iput(p->cwd);
    80005a18:	15093503          	ld	a0,336(s2)
    80005a1c:	ffffe097          	auipc	ra,0xffffe
    80005a20:	f4c080e7          	jalr	-180(ra) # 80003968 <iput>
  end_op();
    80005a24:	ffffe097          	auipc	ra,0xffffe
    80005a28:	7cc080e7          	jalr	1996(ra) # 800041f0 <end_op>
  p->cwd = ip;
    80005a2c:	14993823          	sd	s1,336(s2)
  return 0;
    80005a30:	4501                	li	a0,0
}
    80005a32:	60ea                	ld	ra,152(sp)
    80005a34:	644a                	ld	s0,144(sp)
    80005a36:	64aa                	ld	s1,136(sp)
    80005a38:	690a                	ld	s2,128(sp)
    80005a3a:	610d                	addi	sp,sp,160
    80005a3c:	8082                	ret
    end_op();
    80005a3e:	ffffe097          	auipc	ra,0xffffe
    80005a42:	7b2080e7          	jalr	1970(ra) # 800041f0 <end_op>
    return -1;
    80005a46:	557d                	li	a0,-1
    80005a48:	b7ed                	j	80005a32 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a4a:	8526                	mv	a0,s1
    80005a4c:	ffffe097          	auipc	ra,0xffffe
    80005a50:	fc4080e7          	jalr	-60(ra) # 80003a10 <iunlockput>
    end_op();
    80005a54:	ffffe097          	auipc	ra,0xffffe
    80005a58:	79c080e7          	jalr	1948(ra) # 800041f0 <end_op>
    return -1;
    80005a5c:	557d                	li	a0,-1
    80005a5e:	bfd1                	j	80005a32 <sys_chdir+0x7a>

0000000080005a60 <sys_exec>:

uint64
sys_exec(void)
{
    80005a60:	7145                	addi	sp,sp,-464
    80005a62:	e786                	sd	ra,456(sp)
    80005a64:	e3a2                	sd	s0,448(sp)
    80005a66:	ff26                	sd	s1,440(sp)
    80005a68:	fb4a                	sd	s2,432(sp)
    80005a6a:	f74e                	sd	s3,424(sp)
    80005a6c:	f352                	sd	s4,416(sp)
    80005a6e:	ef56                	sd	s5,408(sp)
    80005a70:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005a72:	e3840593          	addi	a1,s0,-456
    80005a76:	4505                	li	a0,1
    80005a78:	ffffd097          	auipc	ra,0xffffd
    80005a7c:	0ea080e7          	jalr	234(ra) # 80002b62 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005a80:	08000613          	li	a2,128
    80005a84:	f4040593          	addi	a1,s0,-192
    80005a88:	4501                	li	a0,0
    80005a8a:	ffffd097          	auipc	ra,0xffffd
    80005a8e:	0f8080e7          	jalr	248(ra) # 80002b82 <argstr>
    80005a92:	87aa                	mv	a5,a0
    return -1;
    80005a94:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005a96:	0c07c263          	bltz	a5,80005b5a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a9a:	10000613          	li	a2,256
    80005a9e:	4581                	li	a1,0
    80005aa0:	e4040513          	addi	a0,s0,-448
    80005aa4:	ffffb097          	auipc	ra,0xffffb
    80005aa8:	242080e7          	jalr	578(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005aac:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ab0:	89a6                	mv	s3,s1
    80005ab2:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ab4:	02000a13          	li	s4,32
    80005ab8:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005abc:	00391513          	slli	a0,s2,0x3
    80005ac0:	e3040593          	addi	a1,s0,-464
    80005ac4:	e3843783          	ld	a5,-456(s0)
    80005ac8:	953e                	add	a0,a0,a5
    80005aca:	ffffd097          	auipc	ra,0xffffd
    80005ace:	fda080e7          	jalr	-38(ra) # 80002aa4 <fetchaddr>
    80005ad2:	02054a63          	bltz	a0,80005b06 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005ad6:	e3043783          	ld	a5,-464(s0)
    80005ada:	c3b9                	beqz	a5,80005b20 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005adc:	ffffb097          	auipc	ra,0xffffb
    80005ae0:	01e080e7          	jalr	30(ra) # 80000afa <kalloc>
    80005ae4:	85aa                	mv	a1,a0
    80005ae6:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005aea:	cd11                	beqz	a0,80005b06 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005aec:	6605                	lui	a2,0x1
    80005aee:	e3043503          	ld	a0,-464(s0)
    80005af2:	ffffd097          	auipc	ra,0xffffd
    80005af6:	004080e7          	jalr	4(ra) # 80002af6 <fetchstr>
    80005afa:	00054663          	bltz	a0,80005b06 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005afe:	0905                	addi	s2,s2,1
    80005b00:	09a1                	addi	s3,s3,8
    80005b02:	fb491be3          	bne	s2,s4,80005ab8 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b06:	10048913          	addi	s2,s1,256
    80005b0a:	6088                	ld	a0,0(s1)
    80005b0c:	c531                	beqz	a0,80005b58 <sys_exec+0xf8>
    kfree(argv[i]);
    80005b0e:	ffffb097          	auipc	ra,0xffffb
    80005b12:	ef0080e7          	jalr	-272(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b16:	04a1                	addi	s1,s1,8
    80005b18:	ff2499e3          	bne	s1,s2,80005b0a <sys_exec+0xaa>
  return -1;
    80005b1c:	557d                	li	a0,-1
    80005b1e:	a835                	j	80005b5a <sys_exec+0xfa>
      argv[i] = 0;
    80005b20:	0a8e                	slli	s5,s5,0x3
    80005b22:	fc040793          	addi	a5,s0,-64
    80005b26:	9abe                	add	s5,s5,a5
    80005b28:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b2c:	e4040593          	addi	a1,s0,-448
    80005b30:	f4040513          	addi	a0,s0,-192
    80005b34:	fffff097          	auipc	ra,0xfffff
    80005b38:	190080e7          	jalr	400(ra) # 80004cc4 <exec>
    80005b3c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b3e:	10048993          	addi	s3,s1,256
    80005b42:	6088                	ld	a0,0(s1)
    80005b44:	c901                	beqz	a0,80005b54 <sys_exec+0xf4>
    kfree(argv[i]);
    80005b46:	ffffb097          	auipc	ra,0xffffb
    80005b4a:	eb8080e7          	jalr	-328(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b4e:	04a1                	addi	s1,s1,8
    80005b50:	ff3499e3          	bne	s1,s3,80005b42 <sys_exec+0xe2>
  return ret;
    80005b54:	854a                	mv	a0,s2
    80005b56:	a011                	j	80005b5a <sys_exec+0xfa>
  return -1;
    80005b58:	557d                	li	a0,-1
}
    80005b5a:	60be                	ld	ra,456(sp)
    80005b5c:	641e                	ld	s0,448(sp)
    80005b5e:	74fa                	ld	s1,440(sp)
    80005b60:	795a                	ld	s2,432(sp)
    80005b62:	79ba                	ld	s3,424(sp)
    80005b64:	7a1a                	ld	s4,416(sp)
    80005b66:	6afa                	ld	s5,408(sp)
    80005b68:	6179                	addi	sp,sp,464
    80005b6a:	8082                	ret

0000000080005b6c <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b6c:	7139                	addi	sp,sp,-64
    80005b6e:	fc06                	sd	ra,56(sp)
    80005b70:	f822                	sd	s0,48(sp)
    80005b72:	f426                	sd	s1,40(sp)
    80005b74:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b76:	ffffc097          	auipc	ra,0xffffc
    80005b7a:	e50080e7          	jalr	-432(ra) # 800019c6 <myproc>
    80005b7e:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005b80:	fd840593          	addi	a1,s0,-40
    80005b84:	4501                	li	a0,0
    80005b86:	ffffd097          	auipc	ra,0xffffd
    80005b8a:	fdc080e7          	jalr	-36(ra) # 80002b62 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005b8e:	fc840593          	addi	a1,s0,-56
    80005b92:	fd040513          	addi	a0,s0,-48
    80005b96:	fffff097          	auipc	ra,0xfffff
    80005b9a:	dd6080e7          	jalr	-554(ra) # 8000496c <pipealloc>
    return -1;
    80005b9e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ba0:	0c054463          	bltz	a0,80005c68 <sys_pipe+0xfc>
  fd0 = -1;
    80005ba4:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ba8:	fd043503          	ld	a0,-48(s0)
    80005bac:	fffff097          	auipc	ra,0xfffff
    80005bb0:	518080e7          	jalr	1304(ra) # 800050c4 <fdalloc>
    80005bb4:	fca42223          	sw	a0,-60(s0)
    80005bb8:	08054b63          	bltz	a0,80005c4e <sys_pipe+0xe2>
    80005bbc:	fc843503          	ld	a0,-56(s0)
    80005bc0:	fffff097          	auipc	ra,0xfffff
    80005bc4:	504080e7          	jalr	1284(ra) # 800050c4 <fdalloc>
    80005bc8:	fca42023          	sw	a0,-64(s0)
    80005bcc:	06054863          	bltz	a0,80005c3c <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bd0:	4691                	li	a3,4
    80005bd2:	fc440613          	addi	a2,s0,-60
    80005bd6:	fd843583          	ld	a1,-40(s0)
    80005bda:	68a8                	ld	a0,80(s1)
    80005bdc:	ffffc097          	auipc	ra,0xffffc
    80005be0:	aa8080e7          	jalr	-1368(ra) # 80001684 <copyout>
    80005be4:	02054063          	bltz	a0,80005c04 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005be8:	4691                	li	a3,4
    80005bea:	fc040613          	addi	a2,s0,-64
    80005bee:	fd843583          	ld	a1,-40(s0)
    80005bf2:	0591                	addi	a1,a1,4
    80005bf4:	68a8                	ld	a0,80(s1)
    80005bf6:	ffffc097          	auipc	ra,0xffffc
    80005bfa:	a8e080e7          	jalr	-1394(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005bfe:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c00:	06055463          	bgez	a0,80005c68 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005c04:	fc442783          	lw	a5,-60(s0)
    80005c08:	07e9                	addi	a5,a5,26
    80005c0a:	078e                	slli	a5,a5,0x3
    80005c0c:	97a6                	add	a5,a5,s1
    80005c0e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c12:	fc042503          	lw	a0,-64(s0)
    80005c16:	0569                	addi	a0,a0,26
    80005c18:	050e                	slli	a0,a0,0x3
    80005c1a:	94aa                	add	s1,s1,a0
    80005c1c:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c20:	fd043503          	ld	a0,-48(s0)
    80005c24:	fffff097          	auipc	ra,0xfffff
    80005c28:	a18080e7          	jalr	-1512(ra) # 8000463c <fileclose>
    fileclose(wf);
    80005c2c:	fc843503          	ld	a0,-56(s0)
    80005c30:	fffff097          	auipc	ra,0xfffff
    80005c34:	a0c080e7          	jalr	-1524(ra) # 8000463c <fileclose>
    return -1;
    80005c38:	57fd                	li	a5,-1
    80005c3a:	a03d                	j	80005c68 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005c3c:	fc442783          	lw	a5,-60(s0)
    80005c40:	0007c763          	bltz	a5,80005c4e <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005c44:	07e9                	addi	a5,a5,26
    80005c46:	078e                	slli	a5,a5,0x3
    80005c48:	94be                	add	s1,s1,a5
    80005c4a:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c4e:	fd043503          	ld	a0,-48(s0)
    80005c52:	fffff097          	auipc	ra,0xfffff
    80005c56:	9ea080e7          	jalr	-1558(ra) # 8000463c <fileclose>
    fileclose(wf);
    80005c5a:	fc843503          	ld	a0,-56(s0)
    80005c5e:	fffff097          	auipc	ra,0xfffff
    80005c62:	9de080e7          	jalr	-1570(ra) # 8000463c <fileclose>
    return -1;
    80005c66:	57fd                	li	a5,-1
}
    80005c68:	853e                	mv	a0,a5
    80005c6a:	70e2                	ld	ra,56(sp)
    80005c6c:	7442                	ld	s0,48(sp)
    80005c6e:	74a2                	ld	s1,40(sp)
    80005c70:	6121                	addi	sp,sp,64
    80005c72:	8082                	ret
	...

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
    80005cc0:	cb1fc0ef          	jal	ra,80002970 <kerneltrap>
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
    80005de8:	80c78793          	addi	a5,a5,-2036 # 800225f0 <disk>
    80005dec:	97aa                	add	a5,a5,a0
    80005dee:	0187c783          	lbu	a5,24(a5)
    80005df2:	ebb9                	bnez	a5,80005e48 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005df4:	00451613          	slli	a2,a0,0x4
    80005df8:	0001c797          	auipc	a5,0x1c
    80005dfc:	7f878793          	addi	a5,a5,2040 # 800225f0 <disk>
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
    80005e20:	0001c517          	auipc	a0,0x1c
    80005e24:	7e850513          	addi	a0,a0,2024 # 80022608 <disk+0x18>
    80005e28:	ffffc097          	auipc	ra,0xffffc
    80005e2c:	2ae080e7          	jalr	686(ra) # 800020d6 <wakeup>
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
    80005e70:	8ac50513          	addi	a0,a0,-1876 # 80022718 <disk+0x128>
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
    80005ed4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc02f>
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
    80005f1a:	0001c497          	auipc	s1,0x1c
    80005f1e:	6d648493          	addi	s1,s1,1750 # 800225f0 <disk>
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
    80005f3e:	0001c717          	auipc	a4,0x1c
    80005f42:	6ba73703          	ld	a4,1722(a4) # 800225f8 <disk+0x8>
    80005f46:	cb6d                	beqz	a4,80006038 <virtio_disk_init+0x1e0>
    80005f48:	cbe5                	beqz	a5,80006038 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    80005f4a:	6605                	lui	a2,0x1
    80005f4c:	4581                	li	a1,0
    80005f4e:	ffffb097          	auipc	ra,0xffffb
    80005f52:	d98080e7          	jalr	-616(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005f56:	0001c497          	auipc	s1,0x1c
    80005f5a:	69a48493          	addi	s1,s1,1690 # 800225f0 <disk>
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
    80006076:	0001c517          	auipc	a0,0x1c
    8000607a:	6a250513          	addi	a0,a0,1698 # 80022718 <disk+0x128>
    8000607e:	ffffb097          	auipc	ra,0xffffb
    80006082:	b6c080e7          	jalr	-1172(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    80006086:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006088:	4ba1                	li	s7,8
      disk.free[i] = 0;
    8000608a:	0001cb17          	auipc	s6,0x1c
    8000608e:	566b0b13          	addi	s6,s6,1382 # 800225f0 <disk>
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
    80006096:	0001cc17          	auipc	s8,0x1c
    8000609a:	682c0c13          	addi	s8,s8,1666 # 80022718 <disk+0x128>
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
    800060bc:	53868693          	addi	a3,a3,1336 # 800225f0 <disk>
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
    8000610e:	4fe50513          	addi	a0,a0,1278 # 80022608 <disk+0x18>
    80006112:	ffffc097          	auipc	ra,0xffffc
    80006116:	f60080e7          	jalr	-160(ra) # 80002072 <sleep>
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
    8000612e:	4c678793          	addi	a5,a5,1222 # 800225f0 <disk>
    80006132:	97b6                	add	a5,a5,a3
    80006134:	4685                	li	a3,1
    80006136:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006138:	0001c597          	auipc	a1,0x1c
    8000613c:	4b858593          	addi	a1,a1,1208 # 800225f0 <disk>
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
    800061a4:	45068693          	addi	a3,a3,1104 # 800225f0 <disk>
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
    80006216:	50698993          	addi	s3,s3,1286 # 80022718 <disk+0x128>
  while(b->disk == 1) {
    8000621a:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000621c:	85ce                	mv	a1,s3
    8000621e:	854a                	mv	a0,s2
    80006220:	ffffc097          	auipc	ra,0xffffc
    80006224:	e52080e7          	jalr	-430(ra) # 80002072 <sleep>
  while(b->disk == 1) {
    80006228:	00492783          	lw	a5,4(s2)
    8000622c:	fe9788e3          	beq	a5,s1,8000621c <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    80006230:	f9042903          	lw	s2,-112(s0)
    80006234:	00290793          	addi	a5,s2,2
    80006238:	00479713          	slli	a4,a5,0x4
    8000623c:	0001c797          	auipc	a5,0x1c
    80006240:	3b478793          	addi	a5,a5,948 # 800225f0 <disk>
    80006244:	97ba                	add	a5,a5,a4
    80006246:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000624a:	0001c997          	auipc	s3,0x1c
    8000624e:	3a698993          	addi	s3,s3,934 # 800225f0 <disk>
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
    80006276:	4a650513          	addi	a0,a0,1190 # 80022718 <disk+0x128>
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
    800062b4:	34850513          	addi	a0,a0,840 # 800225f8 <disk+0x8>
    800062b8:	953a                	add	a0,a0,a4
  if(write)
    800062ba:	e60d14e3          	bnez	s10,80006122 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800062be:	00a60793          	addi	a5,a2,10
    800062c2:	00479693          	slli	a3,a5,0x4
    800062c6:	0001c797          	auipc	a5,0x1c
    800062ca:	32a78793          	addi	a5,a5,810 # 800225f0 <disk>
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
    800062e4:	31048493          	addi	s1,s1,784 # 800225f0 <disk>
    800062e8:	0001c517          	auipc	a0,0x1c
    800062ec:	43050513          	addi	a0,a0,1072 # 80022718 <disk+0x128>
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
    80006344:	d96080e7          	jalr	-618(ra) # 800020d6 <wakeup>

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
    80006364:	3b850513          	addi	a0,a0,952 # 80022718 <disk+0x128>
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
