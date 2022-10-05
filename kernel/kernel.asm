
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
    80000f76:	f96080e7          	jalr	-106(ra) # 80002f08 <binit>
    iinit();         // inode table
    80000f7a:	00002097          	auipc	ra,0x2
    80000f7e:	63a080e7          	jalr	1594(ra) # 800035b4 <iinit>
    fileinit();      // file table
    80000f82:	00003097          	auipc	ra,0x3
    80000f86:	5d8080e7          	jalr	1496(ra) # 8000455a <fileinit>
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
    80001a3e:	afa080e7          	jalr	-1286(ra) # 80003534 <fsinit>
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
    80001d00:	25a080e7          	jalr	602(ra) # 80003f56 <namei>
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
    80001e26:	7ca080e7          	jalr	1994(ra) # 800045ec <filedup>
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
    80001e48:	92e080e7          	jalr	-1746(ra) # 80003772 <idup>
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
    800021ea:	458080e7          	jalr	1112(ra) # 8000463e <fileclose>
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
    80002202:	f74080e7          	jalr	-140(ra) # 80004172 <begin_op>
  iput(p->cwd);
    80002206:	1509b503          	ld	a0,336(s3)
    8000220a:	00001097          	auipc	ra,0x1
    8000220e:	760080e7          	jalr	1888(ra) # 8000396a <iput>
  end_op();
    80002212:	00002097          	auipc	ra,0x2
    80002216:	fe0080e7          	jalr	-32(ra) # 800041f2 <end_op>
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
    80002844:	cd69                	beqz	a0,8000291e <usertrap+0x122>
    if(which_dev == 2 && myproc()->interval) {
    80002846:	4789                	li	a5,2
    80002848:	06f50663          	beq	a0,a5,800028b4 <usertrap+0xb8>
  if(killed(p))
    8000284c:	8526                	mv	a0,s1
    8000284e:	00000097          	auipc	ra,0x0
    80002852:	acc080e7          	jalr	-1332(ra) # 8000231a <killed>
    80002856:	10051163          	bnez	a0,80002958 <usertrap+0x15c>
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
    800028a0:	320080e7          	jalr	800(ra) # 80002bbc <syscall>
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
    800028cc:	cd51                	beqz	a0,80002968 <usertrap+0x16c>
    exit(-1);
    800028ce:	557d                	li	a0,-1
    800028d0:	00000097          	auipc	ra,0x0
    800028d4:	8d6080e7          	jalr	-1834(ra) # 800021a6 <exit>
  if(which_dev == 2)
    800028d8:	a841                	j	80002968 <usertrap+0x16c>
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
        struct trapframe *tf = kalloc();
    800028fa:	ffffe097          	auipc	ra,0xffffe
    800028fe:	200080e7          	jalr	512(ra) # 80000afa <kalloc>
    80002902:	892a                	mv	s2,a0
        memmove(tf, p->trapframe, PGSIZE);
    80002904:	6605                	lui	a2,0x1
    80002906:	6cac                	ld	a1,88(s1)
    80002908:	ffffe097          	auipc	ra,0xffffe
    8000290c:	43e080e7          	jalr	1086(ra) # 80000d46 <memmove>
        p->sigalarm_tf = tf;
    80002910:	1924b023          	sd	s2,384(s1)
        p->trapframe->epc = p->sig_handler;
    80002914:	6cbc                	ld	a5,88(s1)
    80002916:	1784b703          	ld	a4,376(s1)
    8000291a:	ef98                	sd	a4,24(a5)
    8000291c:	b75d                	j	800028c2 <usertrap+0xc6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000291e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002922:	5890                	lw	a2,48(s1)
    80002924:	00006517          	auipc	a0,0x6
    80002928:	a1c50513          	addi	a0,a0,-1508 # 80008340 <states.1727+0x78>
    8000292c:	ffffe097          	auipc	ra,0xffffe
    80002930:	c62080e7          	jalr	-926(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002934:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002938:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000293c:	00006517          	auipc	a0,0x6
    80002940:	a3450513          	addi	a0,a0,-1484 # 80008370 <states.1727+0xa8>
    80002944:	ffffe097          	auipc	ra,0xffffe
    80002948:	c4a080e7          	jalr	-950(ra) # 8000058e <printf>
    setkilled(p);
    8000294c:	8526                	mv	a0,s1
    8000294e:	00000097          	auipc	ra,0x0
    80002952:	9a0080e7          	jalr	-1632(ra) # 800022ee <setkilled>
    80002956:	bddd                	j	8000284c <usertrap+0x50>
    exit(-1);
    80002958:	557d                	li	a0,-1
    8000295a:	00000097          	auipc	ra,0x0
    8000295e:	84c080e7          	jalr	-1972(ra) # 800021a6 <exit>
  if(which_dev == 2)
    80002962:	4789                	li	a5,2
    80002964:	eef91be3          	bne	s2,a5,8000285a <usertrap+0x5e>
    yield();
    80002968:	fffff097          	auipc	ra,0xfffff
    8000296c:	6ce080e7          	jalr	1742(ra) # 80002036 <yield>
    80002970:	b5ed                	j	8000285a <usertrap+0x5e>

0000000080002972 <kerneltrap>:
{
    80002972:	7179                	addi	sp,sp,-48
    80002974:	f406                	sd	ra,40(sp)
    80002976:	f022                	sd	s0,32(sp)
    80002978:	ec26                	sd	s1,24(sp)
    8000297a:	e84a                	sd	s2,16(sp)
    8000297c:	e44e                	sd	s3,8(sp)
    8000297e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002980:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002984:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002988:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000298c:	1004f793          	andi	a5,s1,256
    80002990:	cb85                	beqz	a5,800029c0 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002992:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002996:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002998:	ef85                	bnez	a5,800029d0 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000299a:	00000097          	auipc	ra,0x0
    8000299e:	dc0080e7          	jalr	-576(ra) # 8000275a <devintr>
    800029a2:	cd1d                	beqz	a0,800029e0 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029a4:	4789                	li	a5,2
    800029a6:	06f50a63          	beq	a0,a5,80002a1a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029aa:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029ae:	10049073          	csrw	sstatus,s1
}
    800029b2:	70a2                	ld	ra,40(sp)
    800029b4:	7402                	ld	s0,32(sp)
    800029b6:	64e2                	ld	s1,24(sp)
    800029b8:	6942                	ld	s2,16(sp)
    800029ba:	69a2                	ld	s3,8(sp)
    800029bc:	6145                	addi	sp,sp,48
    800029be:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029c0:	00006517          	auipc	a0,0x6
    800029c4:	9d050513          	addi	a0,a0,-1584 # 80008390 <states.1727+0xc8>
    800029c8:	ffffe097          	auipc	ra,0xffffe
    800029cc:	b7c080e7          	jalr	-1156(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    800029d0:	00006517          	auipc	a0,0x6
    800029d4:	9e850513          	addi	a0,a0,-1560 # 800083b8 <states.1727+0xf0>
    800029d8:	ffffe097          	auipc	ra,0xffffe
    800029dc:	b6c080e7          	jalr	-1172(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    800029e0:	85ce                	mv	a1,s3
    800029e2:	00006517          	auipc	a0,0x6
    800029e6:	9f650513          	addi	a0,a0,-1546 # 800083d8 <states.1727+0x110>
    800029ea:	ffffe097          	auipc	ra,0xffffe
    800029ee:	ba4080e7          	jalr	-1116(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029f2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029f6:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029fa:	00006517          	auipc	a0,0x6
    800029fe:	9ee50513          	addi	a0,a0,-1554 # 800083e8 <states.1727+0x120>
    80002a02:	ffffe097          	auipc	ra,0xffffe
    80002a06:	b8c080e7          	jalr	-1140(ra) # 8000058e <printf>
    panic("kerneltrap");
    80002a0a:	00006517          	auipc	a0,0x6
    80002a0e:	9f650513          	addi	a0,a0,-1546 # 80008400 <states.1727+0x138>
    80002a12:	ffffe097          	auipc	ra,0xffffe
    80002a16:	b32080e7          	jalr	-1230(ra) # 80000544 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a1a:	fffff097          	auipc	ra,0xfffff
    80002a1e:	fac080e7          	jalr	-84(ra) # 800019c6 <myproc>
    80002a22:	d541                	beqz	a0,800029aa <kerneltrap+0x38>
    80002a24:	fffff097          	auipc	ra,0xfffff
    80002a28:	fa2080e7          	jalr	-94(ra) # 800019c6 <myproc>
    80002a2c:	4d18                	lw	a4,24(a0)
    80002a2e:	4791                	li	a5,4
    80002a30:	f6f71de3          	bne	a4,a5,800029aa <kerneltrap+0x38>
    yield();
    80002a34:	fffff097          	auipc	ra,0xfffff
    80002a38:	602080e7          	jalr	1538(ra) # 80002036 <yield>
    80002a3c:	b7bd                	j	800029aa <kerneltrap+0x38>

0000000080002a3e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a3e:	1101                	addi	sp,sp,-32
    80002a40:	ec06                	sd	ra,24(sp)
    80002a42:	e822                	sd	s0,16(sp)
    80002a44:	e426                	sd	s1,8(sp)
    80002a46:	1000                	addi	s0,sp,32
    80002a48:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a4a:	fffff097          	auipc	ra,0xfffff
    80002a4e:	f7c080e7          	jalr	-132(ra) # 800019c6 <myproc>
  switch (n) {
    80002a52:	4795                	li	a5,5
    80002a54:	0497e163          	bltu	a5,s1,80002a96 <argraw+0x58>
    80002a58:	048a                	slli	s1,s1,0x2
    80002a5a:	00006717          	auipc	a4,0x6
    80002a5e:	abe70713          	addi	a4,a4,-1346 # 80008518 <states.1727+0x250>
    80002a62:	94ba                	add	s1,s1,a4
    80002a64:	409c                	lw	a5,0(s1)
    80002a66:	97ba                	add	a5,a5,a4
    80002a68:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a6a:	6d3c                	ld	a5,88(a0)
    80002a6c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a6e:	60e2                	ld	ra,24(sp)
    80002a70:	6442                	ld	s0,16(sp)
    80002a72:	64a2                	ld	s1,8(sp)
    80002a74:	6105                	addi	sp,sp,32
    80002a76:	8082                	ret
    return p->trapframe->a1;
    80002a78:	6d3c                	ld	a5,88(a0)
    80002a7a:	7fa8                	ld	a0,120(a5)
    80002a7c:	bfcd                	j	80002a6e <argraw+0x30>
    return p->trapframe->a2;
    80002a7e:	6d3c                	ld	a5,88(a0)
    80002a80:	63c8                	ld	a0,128(a5)
    80002a82:	b7f5                	j	80002a6e <argraw+0x30>
    return p->trapframe->a3;
    80002a84:	6d3c                	ld	a5,88(a0)
    80002a86:	67c8                	ld	a0,136(a5)
    80002a88:	b7dd                	j	80002a6e <argraw+0x30>
    return p->trapframe->a4;
    80002a8a:	6d3c                	ld	a5,88(a0)
    80002a8c:	6bc8                	ld	a0,144(a5)
    80002a8e:	b7c5                	j	80002a6e <argraw+0x30>
    return p->trapframe->a5;
    80002a90:	6d3c                	ld	a5,88(a0)
    80002a92:	6fc8                	ld	a0,152(a5)
    80002a94:	bfe9                	j	80002a6e <argraw+0x30>
  panic("argraw");
    80002a96:	00006517          	auipc	a0,0x6
    80002a9a:	97a50513          	addi	a0,a0,-1670 # 80008410 <states.1727+0x148>
    80002a9e:	ffffe097          	auipc	ra,0xffffe
    80002aa2:	aa6080e7          	jalr	-1370(ra) # 80000544 <panic>

0000000080002aa6 <fetchaddr>:
{
    80002aa6:	1101                	addi	sp,sp,-32
    80002aa8:	ec06                	sd	ra,24(sp)
    80002aaa:	e822                	sd	s0,16(sp)
    80002aac:	e426                	sd	s1,8(sp)
    80002aae:	e04a                	sd	s2,0(sp)
    80002ab0:	1000                	addi	s0,sp,32
    80002ab2:	84aa                	mv	s1,a0
    80002ab4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ab6:	fffff097          	auipc	ra,0xfffff
    80002aba:	f10080e7          	jalr	-240(ra) # 800019c6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002abe:	653c                	ld	a5,72(a0)
    80002ac0:	02f4f863          	bgeu	s1,a5,80002af0 <fetchaddr+0x4a>
    80002ac4:	00848713          	addi	a4,s1,8
    80002ac8:	02e7e663          	bltu	a5,a4,80002af4 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002acc:	46a1                	li	a3,8
    80002ace:	8626                	mv	a2,s1
    80002ad0:	85ca                	mv	a1,s2
    80002ad2:	6928                	ld	a0,80(a0)
    80002ad4:	fffff097          	auipc	ra,0xfffff
    80002ad8:	c3c080e7          	jalr	-964(ra) # 80001710 <copyin>
    80002adc:	00a03533          	snez	a0,a0
    80002ae0:	40a00533          	neg	a0,a0
}
    80002ae4:	60e2                	ld	ra,24(sp)
    80002ae6:	6442                	ld	s0,16(sp)
    80002ae8:	64a2                	ld	s1,8(sp)
    80002aea:	6902                	ld	s2,0(sp)
    80002aec:	6105                	addi	sp,sp,32
    80002aee:	8082                	ret
    return -1;
    80002af0:	557d                	li	a0,-1
    80002af2:	bfcd                	j	80002ae4 <fetchaddr+0x3e>
    80002af4:	557d                	li	a0,-1
    80002af6:	b7fd                	j	80002ae4 <fetchaddr+0x3e>

0000000080002af8 <fetchstr>:
{
    80002af8:	7179                	addi	sp,sp,-48
    80002afa:	f406                	sd	ra,40(sp)
    80002afc:	f022                	sd	s0,32(sp)
    80002afe:	ec26                	sd	s1,24(sp)
    80002b00:	e84a                	sd	s2,16(sp)
    80002b02:	e44e                	sd	s3,8(sp)
    80002b04:	1800                	addi	s0,sp,48
    80002b06:	892a                	mv	s2,a0
    80002b08:	84ae                	mv	s1,a1
    80002b0a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b0c:	fffff097          	auipc	ra,0xfffff
    80002b10:	eba080e7          	jalr	-326(ra) # 800019c6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002b14:	86ce                	mv	a3,s3
    80002b16:	864a                	mv	a2,s2
    80002b18:	85a6                	mv	a1,s1
    80002b1a:	6928                	ld	a0,80(a0)
    80002b1c:	fffff097          	auipc	ra,0xfffff
    80002b20:	c80080e7          	jalr	-896(ra) # 8000179c <copyinstr>
    80002b24:	00054e63          	bltz	a0,80002b40 <fetchstr+0x48>
  return strlen(buf);
    80002b28:	8526                	mv	a0,s1
    80002b2a:	ffffe097          	auipc	ra,0xffffe
    80002b2e:	340080e7          	jalr	832(ra) # 80000e6a <strlen>
}
    80002b32:	70a2                	ld	ra,40(sp)
    80002b34:	7402                	ld	s0,32(sp)
    80002b36:	64e2                	ld	s1,24(sp)
    80002b38:	6942                	ld	s2,16(sp)
    80002b3a:	69a2                	ld	s3,8(sp)
    80002b3c:	6145                	addi	sp,sp,48
    80002b3e:	8082                	ret
    return -1;
    80002b40:	557d                	li	a0,-1
    80002b42:	bfc5                	j	80002b32 <fetchstr+0x3a>

0000000080002b44 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002b44:	1101                	addi	sp,sp,-32
    80002b46:	ec06                	sd	ra,24(sp)
    80002b48:	e822                	sd	s0,16(sp)
    80002b4a:	e426                	sd	s1,8(sp)
    80002b4c:	1000                	addi	s0,sp,32
    80002b4e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b50:	00000097          	auipc	ra,0x0
    80002b54:	eee080e7          	jalr	-274(ra) # 80002a3e <argraw>
    80002b58:	c088                	sw	a0,0(s1)
}
    80002b5a:	60e2                	ld	ra,24(sp)
    80002b5c:	6442                	ld	s0,16(sp)
    80002b5e:	64a2                	ld	s1,8(sp)
    80002b60:	6105                	addi	sp,sp,32
    80002b62:	8082                	ret

0000000080002b64 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002b64:	1101                	addi	sp,sp,-32
    80002b66:	ec06                	sd	ra,24(sp)
    80002b68:	e822                	sd	s0,16(sp)
    80002b6a:	e426                	sd	s1,8(sp)
    80002b6c:	1000                	addi	s0,sp,32
    80002b6e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b70:	00000097          	auipc	ra,0x0
    80002b74:	ece080e7          	jalr	-306(ra) # 80002a3e <argraw>
    80002b78:	e088                	sd	a0,0(s1)
}
    80002b7a:	60e2                	ld	ra,24(sp)
    80002b7c:	6442                	ld	s0,16(sp)
    80002b7e:	64a2                	ld	s1,8(sp)
    80002b80:	6105                	addi	sp,sp,32
    80002b82:	8082                	ret

0000000080002b84 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b84:	7179                	addi	sp,sp,-48
    80002b86:	f406                	sd	ra,40(sp)
    80002b88:	f022                	sd	s0,32(sp)
    80002b8a:	ec26                	sd	s1,24(sp)
    80002b8c:	e84a                	sd	s2,16(sp)
    80002b8e:	1800                	addi	s0,sp,48
    80002b90:	84ae                	mv	s1,a1
    80002b92:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002b94:	fd840593          	addi	a1,s0,-40
    80002b98:	00000097          	auipc	ra,0x0
    80002b9c:	fcc080e7          	jalr	-52(ra) # 80002b64 <argaddr>
  return fetchstr(addr, buf, max);
    80002ba0:	864a                	mv	a2,s2
    80002ba2:	85a6                	mv	a1,s1
    80002ba4:	fd843503          	ld	a0,-40(s0)
    80002ba8:	00000097          	auipc	ra,0x0
    80002bac:	f50080e7          	jalr	-176(ra) # 80002af8 <fetchstr>
}
    80002bb0:	70a2                	ld	ra,40(sp)
    80002bb2:	7402                	ld	s0,32(sp)
    80002bb4:	64e2                	ld	s1,24(sp)
    80002bb6:	6942                	ld	s2,16(sp)
    80002bb8:	6145                	addi	sp,sp,48
    80002bba:	8082                	ret

0000000080002bbc <syscall>:
[SYS_sigreturn] "sigreturn ",
};

void
syscall(void)
{
    80002bbc:	7179                	addi	sp,sp,-48
    80002bbe:	f406                	sd	ra,40(sp)
    80002bc0:	f022                	sd	s0,32(sp)
    80002bc2:	ec26                	sd	s1,24(sp)
    80002bc4:	e84a                	sd	s2,16(sp)
    80002bc6:	e44e                	sd	s3,8(sp)
    80002bc8:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80002bca:	fffff097          	auipc	ra,0xfffff
    80002bce:	dfc080e7          	jalr	-516(ra) # 800019c6 <myproc>
    80002bd2:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002bd4:	05853903          	ld	s2,88(a0)
    80002bd8:	0a893783          	ld	a5,168(s2)
    80002bdc:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002be0:	37fd                	addiw	a5,a5,-1
    80002be2:	4761                	li	a4,24
    80002be4:	04f76763          	bltu	a4,a5,80002c32 <syscall+0x76>
    80002be8:	00399713          	slli	a4,s3,0x3
    80002bec:	00006797          	auipc	a5,0x6
    80002bf0:	94478793          	addi	a5,a5,-1724 # 80008530 <syscalls>
    80002bf4:	97ba                	add	a5,a5,a4
    80002bf6:	639c                	ld	a5,0(a5)
    80002bf8:	cf8d                	beqz	a5,80002c32 <syscall+0x76>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002bfa:	9782                	jalr	a5
    80002bfc:	06a93823          	sd	a0,112(s2)

    // Check for trace_flag to be on
    if(p->trace_flag >> num) {  // check for '=='
    80002c00:	1684a783          	lw	a5,360(s1)
    80002c04:	4137d7bb          	sraw	a5,a5,s3
    80002c08:	c7a1                	beqz	a5,80002c50 <syscall+0x94>
      printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0);
    80002c0a:	6cb8                	ld	a4,88(s1)
    80002c0c:	098e                	slli	s3,s3,0x3
    80002c0e:	00006797          	auipc	a5,0x6
    80002c12:	d7a78793          	addi	a5,a5,-646 # 80008988 <syscall_names>
    80002c16:	99be                	add	s3,s3,a5
    80002c18:	7b34                	ld	a3,112(a4)
    80002c1a:	0009b603          	ld	a2,0(s3)
    80002c1e:	588c                	lw	a1,48(s1)
    80002c20:	00005517          	auipc	a0,0x5
    80002c24:	7f850513          	addi	a0,a0,2040 # 80008418 <states.1727+0x150>
    80002c28:	ffffe097          	auipc	ra,0xffffe
    80002c2c:	966080e7          	jalr	-1690(ra) # 8000058e <printf>
    80002c30:	a005                	j	80002c50 <syscall+0x94>
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c32:	86ce                	mv	a3,s3
    80002c34:	15848613          	addi	a2,s1,344
    80002c38:	588c                	lw	a1,48(s1)
    80002c3a:	00005517          	auipc	a0,0x5
    80002c3e:	7f650513          	addi	a0,a0,2038 # 80008430 <states.1727+0x168>
    80002c42:	ffffe097          	auipc	ra,0xffffe
    80002c46:	94c080e7          	jalr	-1716(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c4a:	6cbc                	ld	a5,88(s1)
    80002c4c:	577d                	li	a4,-1
    80002c4e:	fbb8                	sd	a4,112(a5)
  }
}
    80002c50:	70a2                	ld	ra,40(sp)
    80002c52:	7402                	ld	s0,32(sp)
    80002c54:	64e2                	ld	s1,24(sp)
    80002c56:	6942                	ld	s2,16(sp)
    80002c58:	69a2                	ld	s3,8(sp)
    80002c5a:	6145                	addi	sp,sp,48
    80002c5c:	8082                	ret

0000000080002c5e <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c5e:	1101                	addi	sp,sp,-32
    80002c60:	ec06                	sd	ra,24(sp)
    80002c62:	e822                	sd	s0,16(sp)
    80002c64:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002c66:	fec40593          	addi	a1,s0,-20
    80002c6a:	4501                	li	a0,0
    80002c6c:	00000097          	auipc	ra,0x0
    80002c70:	ed8080e7          	jalr	-296(ra) # 80002b44 <argint>
  exit(n);
    80002c74:	fec42503          	lw	a0,-20(s0)
    80002c78:	fffff097          	auipc	ra,0xfffff
    80002c7c:	52e080e7          	jalr	1326(ra) # 800021a6 <exit>
  return 0;  // not reached
}
    80002c80:	4501                	li	a0,0
    80002c82:	60e2                	ld	ra,24(sp)
    80002c84:	6442                	ld	s0,16(sp)
    80002c86:	6105                	addi	sp,sp,32
    80002c88:	8082                	ret

0000000080002c8a <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c8a:	1141                	addi	sp,sp,-16
    80002c8c:	e406                	sd	ra,8(sp)
    80002c8e:	e022                	sd	s0,0(sp)
    80002c90:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c92:	fffff097          	auipc	ra,0xfffff
    80002c96:	d34080e7          	jalr	-716(ra) # 800019c6 <myproc>
}
    80002c9a:	5908                	lw	a0,48(a0)
    80002c9c:	60a2                	ld	ra,8(sp)
    80002c9e:	6402                	ld	s0,0(sp)
    80002ca0:	0141                	addi	sp,sp,16
    80002ca2:	8082                	ret

0000000080002ca4 <sys_fork>:

uint64
sys_fork(void)
{
    80002ca4:	1141                	addi	sp,sp,-16
    80002ca6:	e406                	sd	ra,8(sp)
    80002ca8:	e022                	sd	s0,0(sp)
    80002caa:	0800                	addi	s0,sp,16
  return fork();
    80002cac:	fffff097          	auipc	ra,0xfffff
    80002cb0:	0d0080e7          	jalr	208(ra) # 80001d7c <fork>
}
    80002cb4:	60a2                	ld	ra,8(sp)
    80002cb6:	6402                	ld	s0,0(sp)
    80002cb8:	0141                	addi	sp,sp,16
    80002cba:	8082                	ret

0000000080002cbc <sys_wait>:

uint64
sys_wait(void)
{
    80002cbc:	1101                	addi	sp,sp,-32
    80002cbe:	ec06                	sd	ra,24(sp)
    80002cc0:	e822                	sd	s0,16(sp)
    80002cc2:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002cc4:	fe840593          	addi	a1,s0,-24
    80002cc8:	4501                	li	a0,0
    80002cca:	00000097          	auipc	ra,0x0
    80002cce:	e9a080e7          	jalr	-358(ra) # 80002b64 <argaddr>
  return wait(p);
    80002cd2:	fe843503          	ld	a0,-24(s0)
    80002cd6:	fffff097          	auipc	ra,0xfffff
    80002cda:	676080e7          	jalr	1654(ra) # 8000234c <wait>
}
    80002cde:	60e2                	ld	ra,24(sp)
    80002ce0:	6442                	ld	s0,16(sp)
    80002ce2:	6105                	addi	sp,sp,32
    80002ce4:	8082                	ret

0000000080002ce6 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002ce6:	7179                	addi	sp,sp,-48
    80002ce8:	f406                	sd	ra,40(sp)
    80002cea:	f022                	sd	s0,32(sp)
    80002cec:	ec26                	sd	s1,24(sp)
    80002cee:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002cf0:	fdc40593          	addi	a1,s0,-36
    80002cf4:	4501                	li	a0,0
    80002cf6:	00000097          	auipc	ra,0x0
    80002cfa:	e4e080e7          	jalr	-434(ra) # 80002b44 <argint>
  addr = myproc()->sz;
    80002cfe:	fffff097          	auipc	ra,0xfffff
    80002d02:	cc8080e7          	jalr	-824(ra) # 800019c6 <myproc>
    80002d06:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002d08:	fdc42503          	lw	a0,-36(s0)
    80002d0c:	fffff097          	auipc	ra,0xfffff
    80002d10:	014080e7          	jalr	20(ra) # 80001d20 <growproc>
    80002d14:	00054863          	bltz	a0,80002d24 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002d18:	8526                	mv	a0,s1
    80002d1a:	70a2                	ld	ra,40(sp)
    80002d1c:	7402                	ld	s0,32(sp)
    80002d1e:	64e2                	ld	s1,24(sp)
    80002d20:	6145                	addi	sp,sp,48
    80002d22:	8082                	ret
    return -1;
    80002d24:	54fd                	li	s1,-1
    80002d26:	bfcd                	j	80002d18 <sys_sbrk+0x32>

0000000080002d28 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d28:	7139                	addi	sp,sp,-64
    80002d2a:	fc06                	sd	ra,56(sp)
    80002d2c:	f822                	sd	s0,48(sp)
    80002d2e:	f426                	sd	s1,40(sp)
    80002d30:	f04a                	sd	s2,32(sp)
    80002d32:	ec4e                	sd	s3,24(sp)
    80002d34:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002d36:	fcc40593          	addi	a1,s0,-52
    80002d3a:	4501                	li	a0,0
    80002d3c:	00000097          	auipc	ra,0x0
    80002d40:	e08080e7          	jalr	-504(ra) # 80002b44 <argint>
  acquire(&tickslock);
    80002d44:	00014517          	auipc	a0,0x14
    80002d48:	60c50513          	addi	a0,a0,1548 # 80017350 <tickslock>
    80002d4c:	ffffe097          	auipc	ra,0xffffe
    80002d50:	e9e080e7          	jalr	-354(ra) # 80000bea <acquire>
  ticks0 = ticks;
    80002d54:	00006917          	auipc	s2,0x6
    80002d58:	d5c92903          	lw	s2,-676(s2) # 80008ab0 <ticks>
  while(ticks - ticks0 < n){
    80002d5c:	fcc42783          	lw	a5,-52(s0)
    80002d60:	cf9d                	beqz	a5,80002d9e <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d62:	00014997          	auipc	s3,0x14
    80002d66:	5ee98993          	addi	s3,s3,1518 # 80017350 <tickslock>
    80002d6a:	00006497          	auipc	s1,0x6
    80002d6e:	d4648493          	addi	s1,s1,-698 # 80008ab0 <ticks>
    if(killed(myproc())){
    80002d72:	fffff097          	auipc	ra,0xfffff
    80002d76:	c54080e7          	jalr	-940(ra) # 800019c6 <myproc>
    80002d7a:	fffff097          	auipc	ra,0xfffff
    80002d7e:	5a0080e7          	jalr	1440(ra) # 8000231a <killed>
    80002d82:	ed15                	bnez	a0,80002dbe <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002d84:	85ce                	mv	a1,s3
    80002d86:	8526                	mv	a0,s1
    80002d88:	fffff097          	auipc	ra,0xfffff
    80002d8c:	2ea080e7          	jalr	746(ra) # 80002072 <sleep>
  while(ticks - ticks0 < n){
    80002d90:	409c                	lw	a5,0(s1)
    80002d92:	412787bb          	subw	a5,a5,s2
    80002d96:	fcc42703          	lw	a4,-52(s0)
    80002d9a:	fce7ece3          	bltu	a5,a4,80002d72 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002d9e:	00014517          	auipc	a0,0x14
    80002da2:	5b250513          	addi	a0,a0,1458 # 80017350 <tickslock>
    80002da6:	ffffe097          	auipc	ra,0xffffe
    80002daa:	ef8080e7          	jalr	-264(ra) # 80000c9e <release>
  return 0;
    80002dae:	4501                	li	a0,0
}
    80002db0:	70e2                	ld	ra,56(sp)
    80002db2:	7442                	ld	s0,48(sp)
    80002db4:	74a2                	ld	s1,40(sp)
    80002db6:	7902                	ld	s2,32(sp)
    80002db8:	69e2                	ld	s3,24(sp)
    80002dba:	6121                	addi	sp,sp,64
    80002dbc:	8082                	ret
      release(&tickslock);
    80002dbe:	00014517          	auipc	a0,0x14
    80002dc2:	59250513          	addi	a0,a0,1426 # 80017350 <tickslock>
    80002dc6:	ffffe097          	auipc	ra,0xffffe
    80002dca:	ed8080e7          	jalr	-296(ra) # 80000c9e <release>
      return -1;
    80002dce:	557d                	li	a0,-1
    80002dd0:	b7c5                	j	80002db0 <sys_sleep+0x88>

0000000080002dd2 <sys_kill>:

uint64
sys_kill(void)
{
    80002dd2:	1101                	addi	sp,sp,-32
    80002dd4:	ec06                	sd	ra,24(sp)
    80002dd6:	e822                	sd	s0,16(sp)
    80002dd8:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002dda:	fec40593          	addi	a1,s0,-20
    80002dde:	4501                	li	a0,0
    80002de0:	00000097          	auipc	ra,0x0
    80002de4:	d64080e7          	jalr	-668(ra) # 80002b44 <argint>
  return kill(pid);
    80002de8:	fec42503          	lw	a0,-20(s0)
    80002dec:	fffff097          	auipc	ra,0xfffff
    80002df0:	490080e7          	jalr	1168(ra) # 8000227c <kill>
}
    80002df4:	60e2                	ld	ra,24(sp)
    80002df6:	6442                	ld	s0,16(sp)
    80002df8:	6105                	addi	sp,sp,32
    80002dfa:	8082                	ret

0000000080002dfc <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002dfc:	1101                	addi	sp,sp,-32
    80002dfe:	ec06                	sd	ra,24(sp)
    80002e00:	e822                	sd	s0,16(sp)
    80002e02:	e426                	sd	s1,8(sp)
    80002e04:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e06:	00014517          	auipc	a0,0x14
    80002e0a:	54a50513          	addi	a0,a0,1354 # 80017350 <tickslock>
    80002e0e:	ffffe097          	auipc	ra,0xffffe
    80002e12:	ddc080e7          	jalr	-548(ra) # 80000bea <acquire>
  xticks = ticks;
    80002e16:	00006497          	auipc	s1,0x6
    80002e1a:	c9a4a483          	lw	s1,-870(s1) # 80008ab0 <ticks>
  release(&tickslock);
    80002e1e:	00014517          	auipc	a0,0x14
    80002e22:	53250513          	addi	a0,a0,1330 # 80017350 <tickslock>
    80002e26:	ffffe097          	auipc	ra,0xffffe
    80002e2a:	e78080e7          	jalr	-392(ra) # 80000c9e <release>
  return xticks;
}
    80002e2e:	02049513          	slli	a0,s1,0x20
    80002e32:	9101                	srli	a0,a0,0x20
    80002e34:	60e2                	ld	ra,24(sp)
    80002e36:	6442                	ld	s0,16(sp)
    80002e38:	64a2                	ld	s1,8(sp)
    80002e3a:	6105                	addi	sp,sp,32
    80002e3c:	8082                	ret

0000000080002e3e <sys_trace>:

// sets the trace_flag to the first argument (a0)
uint64
sys_trace(void)
{
    80002e3e:	1141                	addi	sp,sp,-16
    80002e40:	e406                	sd	ra,8(sp)
    80002e42:	e022                	sd	s0,0(sp)
    80002e44:	0800                	addi	s0,sp,16
  argint(0, &myproc()->trace_flag); //arg(a0, trace_flag) // returns void
    80002e46:	fffff097          	auipc	ra,0xfffff
    80002e4a:	b80080e7          	jalr	-1152(ra) # 800019c6 <myproc>
    80002e4e:	16850593          	addi	a1,a0,360
    80002e52:	4501                	li	a0,0
    80002e54:	00000097          	auipc	ra,0x0
    80002e58:	cf0080e7          	jalr	-784(ra) # 80002b44 <argint>
  return 0;
}
    80002e5c:	4501                	li	a0,0
    80002e5e:	60a2                	ld	ra,8(sp)
    80002e60:	6402                	ld	s0,0(sp)
    80002e62:	0141                	addi	sp,sp,16
    80002e64:	8082                	ret

0000000080002e66 <sys_sigalarm>:

// sets the 
uint64
sys_sigalarm(void)
{
    80002e66:	1101                	addi	sp,sp,-32
    80002e68:	ec06                	sd	ra,24(sp)
    80002e6a:	e822                	sd	s0,16(sp)
    80002e6c:	e426                	sd	s1,8(sp)
    80002e6e:	1000                	addi	s0,sp,32
  // sets the interval and handler after every tick
  argint(0, &myproc()->interval);
    80002e70:	fffff097          	auipc	ra,0xfffff
    80002e74:	b56080e7          	jalr	-1194(ra) # 800019c6 <myproc>
    80002e78:	16c50593          	addi	a1,a0,364
    80002e7c:	4501                	li	a0,0
    80002e7e:	00000097          	auipc	ra,0x0
    80002e82:	cc6080e7          	jalr	-826(ra) # 80002b44 <argint>
  argaddr(1, &myproc()->sig_handler);
    80002e86:	fffff097          	auipc	ra,0xfffff
    80002e8a:	b40080e7          	jalr	-1216(ra) # 800019c6 <myproc>
    80002e8e:	17850593          	addi	a1,a0,376
    80002e92:	4505                	li	a0,1
    80002e94:	00000097          	auipc	ra,0x0
    80002e98:	cd0080e7          	jalr	-816(ra) # 80002b64 <argaddr>
  
  // sets ticks_passed as the interval
  myproc()->ticks_left = myproc()->interval;
    80002e9c:	fffff097          	auipc	ra,0xfffff
    80002ea0:	b2a080e7          	jalr	-1238(ra) # 800019c6 <myproc>
    80002ea4:	84aa                	mv	s1,a0
    80002ea6:	fffff097          	auipc	ra,0xfffff
    80002eaa:	b20080e7          	jalr	-1248(ra) # 800019c6 <myproc>
    80002eae:	16c4a783          	lw	a5,364(s1)
    80002eb2:	16f52823          	sw	a5,368(a0)
  return 0;
}
    80002eb6:	4501                	li	a0,0
    80002eb8:	60e2                	ld	ra,24(sp)
    80002eba:	6442                	ld	s0,16(sp)
    80002ebc:	64a2                	ld	s1,8(sp)
    80002ebe:	6105                	addi	sp,sp,32
    80002ec0:	8082                	ret

0000000080002ec2 <sys_sigreturn>:

uint64 
sys_sigreturn(void)
{
    80002ec2:	1101                	addi	sp,sp,-32
    80002ec4:	ec06                	sd	ra,24(sp)
    80002ec6:	e822                	sd	s0,16(sp)
    80002ec8:	e426                	sd	s1,8(sp)
    80002eca:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002ecc:	fffff097          	auipc	ra,0xfffff
    80002ed0:	afa080e7          	jalr	-1286(ra) # 800019c6 <myproc>
    80002ed4:	84aa                	mv	s1,a0
  memmove(p->trapframe, p->sigalarm_tf, PGSIZE);
    80002ed6:	6605                	lui	a2,0x1
    80002ed8:	18053583          	ld	a1,384(a0)
    80002edc:	6d28                	ld	a0,88(a0)
    80002ede:	ffffe097          	auipc	ra,0xffffe
    80002ee2:	e68080e7          	jalr	-408(ra) # 80000d46 <memmove>
  kfree(p->sigalarm_tf);
    80002ee6:	1804b503          	ld	a0,384(s1)
    80002eea:	ffffe097          	auipc	ra,0xffffe
    80002eee:	b14080e7          	jalr	-1260(ra) # 800009fe <kfree>
  p->ticks_left = p->interval;
    80002ef2:	16c4a783          	lw	a5,364(s1)
    80002ef6:	16f4a823          	sw	a5,368(s1)
  return p->trapframe->a0;
    80002efa:	6cbc                	ld	a5,88(s1)
    80002efc:	7ba8                	ld	a0,112(a5)
    80002efe:	60e2                	ld	ra,24(sp)
    80002f00:	6442                	ld	s0,16(sp)
    80002f02:	64a2                	ld	s1,8(sp)
    80002f04:	6105                	addi	sp,sp,32
    80002f06:	8082                	ret

0000000080002f08 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f08:	7179                	addi	sp,sp,-48
    80002f0a:	f406                	sd	ra,40(sp)
    80002f0c:	f022                	sd	s0,32(sp)
    80002f0e:	ec26                	sd	s1,24(sp)
    80002f10:	e84a                	sd	s2,16(sp)
    80002f12:	e44e                	sd	s3,8(sp)
    80002f14:	e052                	sd	s4,0(sp)
    80002f16:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f18:	00005597          	auipc	a1,0x5
    80002f1c:	6e858593          	addi	a1,a1,1768 # 80008600 <syscalls+0xd0>
    80002f20:	00014517          	auipc	a0,0x14
    80002f24:	44850513          	addi	a0,a0,1096 # 80017368 <bcache>
    80002f28:	ffffe097          	auipc	ra,0xffffe
    80002f2c:	c32080e7          	jalr	-974(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f30:	0001c797          	auipc	a5,0x1c
    80002f34:	43878793          	addi	a5,a5,1080 # 8001f368 <bcache+0x8000>
    80002f38:	0001c717          	auipc	a4,0x1c
    80002f3c:	69870713          	addi	a4,a4,1688 # 8001f5d0 <bcache+0x8268>
    80002f40:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f44:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f48:	00014497          	auipc	s1,0x14
    80002f4c:	43848493          	addi	s1,s1,1080 # 80017380 <bcache+0x18>
    b->next = bcache.head.next;
    80002f50:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f52:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f54:	00005a17          	auipc	s4,0x5
    80002f58:	6b4a0a13          	addi	s4,s4,1716 # 80008608 <syscalls+0xd8>
    b->next = bcache.head.next;
    80002f5c:	2b893783          	ld	a5,696(s2)
    80002f60:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f62:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f66:	85d2                	mv	a1,s4
    80002f68:	01048513          	addi	a0,s1,16
    80002f6c:	00001097          	auipc	ra,0x1
    80002f70:	4c4080e7          	jalr	1220(ra) # 80004430 <initsleeplock>
    bcache.head.next->prev = b;
    80002f74:	2b893783          	ld	a5,696(s2)
    80002f78:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f7a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f7e:	45848493          	addi	s1,s1,1112
    80002f82:	fd349de3          	bne	s1,s3,80002f5c <binit+0x54>
  }
}
    80002f86:	70a2                	ld	ra,40(sp)
    80002f88:	7402                	ld	s0,32(sp)
    80002f8a:	64e2                	ld	s1,24(sp)
    80002f8c:	6942                	ld	s2,16(sp)
    80002f8e:	69a2                	ld	s3,8(sp)
    80002f90:	6a02                	ld	s4,0(sp)
    80002f92:	6145                	addi	sp,sp,48
    80002f94:	8082                	ret

0000000080002f96 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f96:	7179                	addi	sp,sp,-48
    80002f98:	f406                	sd	ra,40(sp)
    80002f9a:	f022                	sd	s0,32(sp)
    80002f9c:	ec26                	sd	s1,24(sp)
    80002f9e:	e84a                	sd	s2,16(sp)
    80002fa0:	e44e                	sd	s3,8(sp)
    80002fa2:	1800                	addi	s0,sp,48
    80002fa4:	89aa                	mv	s3,a0
    80002fa6:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002fa8:	00014517          	auipc	a0,0x14
    80002fac:	3c050513          	addi	a0,a0,960 # 80017368 <bcache>
    80002fb0:	ffffe097          	auipc	ra,0xffffe
    80002fb4:	c3a080e7          	jalr	-966(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fb8:	0001c497          	auipc	s1,0x1c
    80002fbc:	6684b483          	ld	s1,1640(s1) # 8001f620 <bcache+0x82b8>
    80002fc0:	0001c797          	auipc	a5,0x1c
    80002fc4:	61078793          	addi	a5,a5,1552 # 8001f5d0 <bcache+0x8268>
    80002fc8:	02f48f63          	beq	s1,a5,80003006 <bread+0x70>
    80002fcc:	873e                	mv	a4,a5
    80002fce:	a021                	j	80002fd6 <bread+0x40>
    80002fd0:	68a4                	ld	s1,80(s1)
    80002fd2:	02e48a63          	beq	s1,a4,80003006 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002fd6:	449c                	lw	a5,8(s1)
    80002fd8:	ff379ce3          	bne	a5,s3,80002fd0 <bread+0x3a>
    80002fdc:	44dc                	lw	a5,12(s1)
    80002fde:	ff2799e3          	bne	a5,s2,80002fd0 <bread+0x3a>
      b->refcnt++;
    80002fe2:	40bc                	lw	a5,64(s1)
    80002fe4:	2785                	addiw	a5,a5,1
    80002fe6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fe8:	00014517          	auipc	a0,0x14
    80002fec:	38050513          	addi	a0,a0,896 # 80017368 <bcache>
    80002ff0:	ffffe097          	auipc	ra,0xffffe
    80002ff4:	cae080e7          	jalr	-850(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80002ff8:	01048513          	addi	a0,s1,16
    80002ffc:	00001097          	auipc	ra,0x1
    80003000:	46e080e7          	jalr	1134(ra) # 8000446a <acquiresleep>
      return b;
    80003004:	a8b9                	j	80003062 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003006:	0001c497          	auipc	s1,0x1c
    8000300a:	6124b483          	ld	s1,1554(s1) # 8001f618 <bcache+0x82b0>
    8000300e:	0001c797          	auipc	a5,0x1c
    80003012:	5c278793          	addi	a5,a5,1474 # 8001f5d0 <bcache+0x8268>
    80003016:	00f48863          	beq	s1,a5,80003026 <bread+0x90>
    8000301a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000301c:	40bc                	lw	a5,64(s1)
    8000301e:	cf81                	beqz	a5,80003036 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003020:	64a4                	ld	s1,72(s1)
    80003022:	fee49de3          	bne	s1,a4,8000301c <bread+0x86>
  panic("bget: no buffers");
    80003026:	00005517          	auipc	a0,0x5
    8000302a:	5ea50513          	addi	a0,a0,1514 # 80008610 <syscalls+0xe0>
    8000302e:	ffffd097          	auipc	ra,0xffffd
    80003032:	516080e7          	jalr	1302(ra) # 80000544 <panic>
      b->dev = dev;
    80003036:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000303a:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000303e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003042:	4785                	li	a5,1
    80003044:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003046:	00014517          	auipc	a0,0x14
    8000304a:	32250513          	addi	a0,a0,802 # 80017368 <bcache>
    8000304e:	ffffe097          	auipc	ra,0xffffe
    80003052:	c50080e7          	jalr	-944(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80003056:	01048513          	addi	a0,s1,16
    8000305a:	00001097          	auipc	ra,0x1
    8000305e:	410080e7          	jalr	1040(ra) # 8000446a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003062:	409c                	lw	a5,0(s1)
    80003064:	cb89                	beqz	a5,80003076 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003066:	8526                	mv	a0,s1
    80003068:	70a2                	ld	ra,40(sp)
    8000306a:	7402                	ld	s0,32(sp)
    8000306c:	64e2                	ld	s1,24(sp)
    8000306e:	6942                	ld	s2,16(sp)
    80003070:	69a2                	ld	s3,8(sp)
    80003072:	6145                	addi	sp,sp,48
    80003074:	8082                	ret
    virtio_disk_rw(b, 0);
    80003076:	4581                	li	a1,0
    80003078:	8526                	mv	a0,s1
    8000307a:	00003097          	auipc	ra,0x3
    8000307e:	fce080e7          	jalr	-50(ra) # 80006048 <virtio_disk_rw>
    b->valid = 1;
    80003082:	4785                	li	a5,1
    80003084:	c09c                	sw	a5,0(s1)
  return b;
    80003086:	b7c5                	j	80003066 <bread+0xd0>

0000000080003088 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003088:	1101                	addi	sp,sp,-32
    8000308a:	ec06                	sd	ra,24(sp)
    8000308c:	e822                	sd	s0,16(sp)
    8000308e:	e426                	sd	s1,8(sp)
    80003090:	1000                	addi	s0,sp,32
    80003092:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003094:	0541                	addi	a0,a0,16
    80003096:	00001097          	auipc	ra,0x1
    8000309a:	46e080e7          	jalr	1134(ra) # 80004504 <holdingsleep>
    8000309e:	cd01                	beqz	a0,800030b6 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030a0:	4585                	li	a1,1
    800030a2:	8526                	mv	a0,s1
    800030a4:	00003097          	auipc	ra,0x3
    800030a8:	fa4080e7          	jalr	-92(ra) # 80006048 <virtio_disk_rw>
}
    800030ac:	60e2                	ld	ra,24(sp)
    800030ae:	6442                	ld	s0,16(sp)
    800030b0:	64a2                	ld	s1,8(sp)
    800030b2:	6105                	addi	sp,sp,32
    800030b4:	8082                	ret
    panic("bwrite");
    800030b6:	00005517          	auipc	a0,0x5
    800030ba:	57250513          	addi	a0,a0,1394 # 80008628 <syscalls+0xf8>
    800030be:	ffffd097          	auipc	ra,0xffffd
    800030c2:	486080e7          	jalr	1158(ra) # 80000544 <panic>

00000000800030c6 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030c6:	1101                	addi	sp,sp,-32
    800030c8:	ec06                	sd	ra,24(sp)
    800030ca:	e822                	sd	s0,16(sp)
    800030cc:	e426                	sd	s1,8(sp)
    800030ce:	e04a                	sd	s2,0(sp)
    800030d0:	1000                	addi	s0,sp,32
    800030d2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030d4:	01050913          	addi	s2,a0,16
    800030d8:	854a                	mv	a0,s2
    800030da:	00001097          	auipc	ra,0x1
    800030de:	42a080e7          	jalr	1066(ra) # 80004504 <holdingsleep>
    800030e2:	c92d                	beqz	a0,80003154 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030e4:	854a                	mv	a0,s2
    800030e6:	00001097          	auipc	ra,0x1
    800030ea:	3da080e7          	jalr	986(ra) # 800044c0 <releasesleep>

  acquire(&bcache.lock);
    800030ee:	00014517          	auipc	a0,0x14
    800030f2:	27a50513          	addi	a0,a0,634 # 80017368 <bcache>
    800030f6:	ffffe097          	auipc	ra,0xffffe
    800030fa:	af4080e7          	jalr	-1292(ra) # 80000bea <acquire>
  b->refcnt--;
    800030fe:	40bc                	lw	a5,64(s1)
    80003100:	37fd                	addiw	a5,a5,-1
    80003102:	0007871b          	sext.w	a4,a5
    80003106:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003108:	eb05                	bnez	a4,80003138 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000310a:	68bc                	ld	a5,80(s1)
    8000310c:	64b8                	ld	a4,72(s1)
    8000310e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003110:	64bc                	ld	a5,72(s1)
    80003112:	68b8                	ld	a4,80(s1)
    80003114:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003116:	0001c797          	auipc	a5,0x1c
    8000311a:	25278793          	addi	a5,a5,594 # 8001f368 <bcache+0x8000>
    8000311e:	2b87b703          	ld	a4,696(a5)
    80003122:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003124:	0001c717          	auipc	a4,0x1c
    80003128:	4ac70713          	addi	a4,a4,1196 # 8001f5d0 <bcache+0x8268>
    8000312c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000312e:	2b87b703          	ld	a4,696(a5)
    80003132:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003134:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003138:	00014517          	auipc	a0,0x14
    8000313c:	23050513          	addi	a0,a0,560 # 80017368 <bcache>
    80003140:	ffffe097          	auipc	ra,0xffffe
    80003144:	b5e080e7          	jalr	-1186(ra) # 80000c9e <release>
}
    80003148:	60e2                	ld	ra,24(sp)
    8000314a:	6442                	ld	s0,16(sp)
    8000314c:	64a2                	ld	s1,8(sp)
    8000314e:	6902                	ld	s2,0(sp)
    80003150:	6105                	addi	sp,sp,32
    80003152:	8082                	ret
    panic("brelse");
    80003154:	00005517          	auipc	a0,0x5
    80003158:	4dc50513          	addi	a0,a0,1244 # 80008630 <syscalls+0x100>
    8000315c:	ffffd097          	auipc	ra,0xffffd
    80003160:	3e8080e7          	jalr	1000(ra) # 80000544 <panic>

0000000080003164 <bpin>:

void
bpin(struct buf *b) {
    80003164:	1101                	addi	sp,sp,-32
    80003166:	ec06                	sd	ra,24(sp)
    80003168:	e822                	sd	s0,16(sp)
    8000316a:	e426                	sd	s1,8(sp)
    8000316c:	1000                	addi	s0,sp,32
    8000316e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003170:	00014517          	auipc	a0,0x14
    80003174:	1f850513          	addi	a0,a0,504 # 80017368 <bcache>
    80003178:	ffffe097          	auipc	ra,0xffffe
    8000317c:	a72080e7          	jalr	-1422(ra) # 80000bea <acquire>
  b->refcnt++;
    80003180:	40bc                	lw	a5,64(s1)
    80003182:	2785                	addiw	a5,a5,1
    80003184:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003186:	00014517          	auipc	a0,0x14
    8000318a:	1e250513          	addi	a0,a0,482 # 80017368 <bcache>
    8000318e:	ffffe097          	auipc	ra,0xffffe
    80003192:	b10080e7          	jalr	-1264(ra) # 80000c9e <release>
}
    80003196:	60e2                	ld	ra,24(sp)
    80003198:	6442                	ld	s0,16(sp)
    8000319a:	64a2                	ld	s1,8(sp)
    8000319c:	6105                	addi	sp,sp,32
    8000319e:	8082                	ret

00000000800031a0 <bunpin>:

void
bunpin(struct buf *b) {
    800031a0:	1101                	addi	sp,sp,-32
    800031a2:	ec06                	sd	ra,24(sp)
    800031a4:	e822                	sd	s0,16(sp)
    800031a6:	e426                	sd	s1,8(sp)
    800031a8:	1000                	addi	s0,sp,32
    800031aa:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031ac:	00014517          	auipc	a0,0x14
    800031b0:	1bc50513          	addi	a0,a0,444 # 80017368 <bcache>
    800031b4:	ffffe097          	auipc	ra,0xffffe
    800031b8:	a36080e7          	jalr	-1482(ra) # 80000bea <acquire>
  b->refcnt--;
    800031bc:	40bc                	lw	a5,64(s1)
    800031be:	37fd                	addiw	a5,a5,-1
    800031c0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031c2:	00014517          	auipc	a0,0x14
    800031c6:	1a650513          	addi	a0,a0,422 # 80017368 <bcache>
    800031ca:	ffffe097          	auipc	ra,0xffffe
    800031ce:	ad4080e7          	jalr	-1324(ra) # 80000c9e <release>
}
    800031d2:	60e2                	ld	ra,24(sp)
    800031d4:	6442                	ld	s0,16(sp)
    800031d6:	64a2                	ld	s1,8(sp)
    800031d8:	6105                	addi	sp,sp,32
    800031da:	8082                	ret

00000000800031dc <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031dc:	1101                	addi	sp,sp,-32
    800031de:	ec06                	sd	ra,24(sp)
    800031e0:	e822                	sd	s0,16(sp)
    800031e2:	e426                	sd	s1,8(sp)
    800031e4:	e04a                	sd	s2,0(sp)
    800031e6:	1000                	addi	s0,sp,32
    800031e8:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031ea:	00d5d59b          	srliw	a1,a1,0xd
    800031ee:	0001d797          	auipc	a5,0x1d
    800031f2:	8567a783          	lw	a5,-1962(a5) # 8001fa44 <sb+0x1c>
    800031f6:	9dbd                	addw	a1,a1,a5
    800031f8:	00000097          	auipc	ra,0x0
    800031fc:	d9e080e7          	jalr	-610(ra) # 80002f96 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003200:	0074f713          	andi	a4,s1,7
    80003204:	4785                	li	a5,1
    80003206:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000320a:	14ce                	slli	s1,s1,0x33
    8000320c:	90d9                	srli	s1,s1,0x36
    8000320e:	00950733          	add	a4,a0,s1
    80003212:	05874703          	lbu	a4,88(a4)
    80003216:	00e7f6b3          	and	a3,a5,a4
    8000321a:	c69d                	beqz	a3,80003248 <bfree+0x6c>
    8000321c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000321e:	94aa                	add	s1,s1,a0
    80003220:	fff7c793          	not	a5,a5
    80003224:	8ff9                	and	a5,a5,a4
    80003226:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000322a:	00001097          	auipc	ra,0x1
    8000322e:	120080e7          	jalr	288(ra) # 8000434a <log_write>
  brelse(bp);
    80003232:	854a                	mv	a0,s2
    80003234:	00000097          	auipc	ra,0x0
    80003238:	e92080e7          	jalr	-366(ra) # 800030c6 <brelse>
}
    8000323c:	60e2                	ld	ra,24(sp)
    8000323e:	6442                	ld	s0,16(sp)
    80003240:	64a2                	ld	s1,8(sp)
    80003242:	6902                	ld	s2,0(sp)
    80003244:	6105                	addi	sp,sp,32
    80003246:	8082                	ret
    panic("freeing free block");
    80003248:	00005517          	auipc	a0,0x5
    8000324c:	3f050513          	addi	a0,a0,1008 # 80008638 <syscalls+0x108>
    80003250:	ffffd097          	auipc	ra,0xffffd
    80003254:	2f4080e7          	jalr	756(ra) # 80000544 <panic>

0000000080003258 <balloc>:
{
    80003258:	711d                	addi	sp,sp,-96
    8000325a:	ec86                	sd	ra,88(sp)
    8000325c:	e8a2                	sd	s0,80(sp)
    8000325e:	e4a6                	sd	s1,72(sp)
    80003260:	e0ca                	sd	s2,64(sp)
    80003262:	fc4e                	sd	s3,56(sp)
    80003264:	f852                	sd	s4,48(sp)
    80003266:	f456                	sd	s5,40(sp)
    80003268:	f05a                	sd	s6,32(sp)
    8000326a:	ec5e                	sd	s7,24(sp)
    8000326c:	e862                	sd	s8,16(sp)
    8000326e:	e466                	sd	s9,8(sp)
    80003270:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003272:	0001c797          	auipc	a5,0x1c
    80003276:	7ba7a783          	lw	a5,1978(a5) # 8001fa2c <sb+0x4>
    8000327a:	10078163          	beqz	a5,8000337c <balloc+0x124>
    8000327e:	8baa                	mv	s7,a0
    80003280:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003282:	0001cb17          	auipc	s6,0x1c
    80003286:	7a6b0b13          	addi	s6,s6,1958 # 8001fa28 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000328a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000328c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000328e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003290:	6c89                	lui	s9,0x2
    80003292:	a061                	j	8000331a <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003294:	974a                	add	a4,a4,s2
    80003296:	8fd5                	or	a5,a5,a3
    80003298:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000329c:	854a                	mv	a0,s2
    8000329e:	00001097          	auipc	ra,0x1
    800032a2:	0ac080e7          	jalr	172(ra) # 8000434a <log_write>
        brelse(bp);
    800032a6:	854a                	mv	a0,s2
    800032a8:	00000097          	auipc	ra,0x0
    800032ac:	e1e080e7          	jalr	-482(ra) # 800030c6 <brelse>
  bp = bread(dev, bno);
    800032b0:	85a6                	mv	a1,s1
    800032b2:	855e                	mv	a0,s7
    800032b4:	00000097          	auipc	ra,0x0
    800032b8:	ce2080e7          	jalr	-798(ra) # 80002f96 <bread>
    800032bc:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032be:	40000613          	li	a2,1024
    800032c2:	4581                	li	a1,0
    800032c4:	05850513          	addi	a0,a0,88
    800032c8:	ffffe097          	auipc	ra,0xffffe
    800032cc:	a1e080e7          	jalr	-1506(ra) # 80000ce6 <memset>
  log_write(bp);
    800032d0:	854a                	mv	a0,s2
    800032d2:	00001097          	auipc	ra,0x1
    800032d6:	078080e7          	jalr	120(ra) # 8000434a <log_write>
  brelse(bp);
    800032da:	854a                	mv	a0,s2
    800032dc:	00000097          	auipc	ra,0x0
    800032e0:	dea080e7          	jalr	-534(ra) # 800030c6 <brelse>
}
    800032e4:	8526                	mv	a0,s1
    800032e6:	60e6                	ld	ra,88(sp)
    800032e8:	6446                	ld	s0,80(sp)
    800032ea:	64a6                	ld	s1,72(sp)
    800032ec:	6906                	ld	s2,64(sp)
    800032ee:	79e2                	ld	s3,56(sp)
    800032f0:	7a42                	ld	s4,48(sp)
    800032f2:	7aa2                	ld	s5,40(sp)
    800032f4:	7b02                	ld	s6,32(sp)
    800032f6:	6be2                	ld	s7,24(sp)
    800032f8:	6c42                	ld	s8,16(sp)
    800032fa:	6ca2                	ld	s9,8(sp)
    800032fc:	6125                	addi	sp,sp,96
    800032fe:	8082                	ret
    brelse(bp);
    80003300:	854a                	mv	a0,s2
    80003302:	00000097          	auipc	ra,0x0
    80003306:	dc4080e7          	jalr	-572(ra) # 800030c6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000330a:	015c87bb          	addw	a5,s9,s5
    8000330e:	00078a9b          	sext.w	s5,a5
    80003312:	004b2703          	lw	a4,4(s6)
    80003316:	06eaf363          	bgeu	s5,a4,8000337c <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    8000331a:	41fad79b          	sraiw	a5,s5,0x1f
    8000331e:	0137d79b          	srliw	a5,a5,0x13
    80003322:	015787bb          	addw	a5,a5,s5
    80003326:	40d7d79b          	sraiw	a5,a5,0xd
    8000332a:	01cb2583          	lw	a1,28(s6)
    8000332e:	9dbd                	addw	a1,a1,a5
    80003330:	855e                	mv	a0,s7
    80003332:	00000097          	auipc	ra,0x0
    80003336:	c64080e7          	jalr	-924(ra) # 80002f96 <bread>
    8000333a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000333c:	004b2503          	lw	a0,4(s6)
    80003340:	000a849b          	sext.w	s1,s5
    80003344:	8662                	mv	a2,s8
    80003346:	faa4fde3          	bgeu	s1,a0,80003300 <balloc+0xa8>
      m = 1 << (bi % 8);
    8000334a:	41f6579b          	sraiw	a5,a2,0x1f
    8000334e:	01d7d69b          	srliw	a3,a5,0x1d
    80003352:	00c6873b          	addw	a4,a3,a2
    80003356:	00777793          	andi	a5,a4,7
    8000335a:	9f95                	subw	a5,a5,a3
    8000335c:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003360:	4037571b          	sraiw	a4,a4,0x3
    80003364:	00e906b3          	add	a3,s2,a4
    80003368:	0586c683          	lbu	a3,88(a3)
    8000336c:	00d7f5b3          	and	a1,a5,a3
    80003370:	d195                	beqz	a1,80003294 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003372:	2605                	addiw	a2,a2,1
    80003374:	2485                	addiw	s1,s1,1
    80003376:	fd4618e3          	bne	a2,s4,80003346 <balloc+0xee>
    8000337a:	b759                	j	80003300 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    8000337c:	00005517          	auipc	a0,0x5
    80003380:	2d450513          	addi	a0,a0,724 # 80008650 <syscalls+0x120>
    80003384:	ffffd097          	auipc	ra,0xffffd
    80003388:	20a080e7          	jalr	522(ra) # 8000058e <printf>
  return 0;
    8000338c:	4481                	li	s1,0
    8000338e:	bf99                	j	800032e4 <balloc+0x8c>

0000000080003390 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003390:	7179                	addi	sp,sp,-48
    80003392:	f406                	sd	ra,40(sp)
    80003394:	f022                	sd	s0,32(sp)
    80003396:	ec26                	sd	s1,24(sp)
    80003398:	e84a                	sd	s2,16(sp)
    8000339a:	e44e                	sd	s3,8(sp)
    8000339c:	e052                	sd	s4,0(sp)
    8000339e:	1800                	addi	s0,sp,48
    800033a0:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033a2:	47ad                	li	a5,11
    800033a4:	02b7e763          	bltu	a5,a1,800033d2 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800033a8:	02059493          	slli	s1,a1,0x20
    800033ac:	9081                	srli	s1,s1,0x20
    800033ae:	048a                	slli	s1,s1,0x2
    800033b0:	94aa                	add	s1,s1,a0
    800033b2:	0504a903          	lw	s2,80(s1)
    800033b6:	06091e63          	bnez	s2,80003432 <bmap+0xa2>
      addr = balloc(ip->dev);
    800033ba:	4108                	lw	a0,0(a0)
    800033bc:	00000097          	auipc	ra,0x0
    800033c0:	e9c080e7          	jalr	-356(ra) # 80003258 <balloc>
    800033c4:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033c8:	06090563          	beqz	s2,80003432 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    800033cc:	0524a823          	sw	s2,80(s1)
    800033d0:	a08d                	j	80003432 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800033d2:	ff45849b          	addiw	s1,a1,-12
    800033d6:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033da:	0ff00793          	li	a5,255
    800033de:	08e7e563          	bltu	a5,a4,80003468 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800033e2:	08052903          	lw	s2,128(a0)
    800033e6:	00091d63          	bnez	s2,80003400 <bmap+0x70>
      addr = balloc(ip->dev);
    800033ea:	4108                	lw	a0,0(a0)
    800033ec:	00000097          	auipc	ra,0x0
    800033f0:	e6c080e7          	jalr	-404(ra) # 80003258 <balloc>
    800033f4:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033f8:	02090d63          	beqz	s2,80003432 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800033fc:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003400:	85ca                	mv	a1,s2
    80003402:	0009a503          	lw	a0,0(s3)
    80003406:	00000097          	auipc	ra,0x0
    8000340a:	b90080e7          	jalr	-1136(ra) # 80002f96 <bread>
    8000340e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003410:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003414:	02049593          	slli	a1,s1,0x20
    80003418:	9181                	srli	a1,a1,0x20
    8000341a:	058a                	slli	a1,a1,0x2
    8000341c:	00b784b3          	add	s1,a5,a1
    80003420:	0004a903          	lw	s2,0(s1)
    80003424:	02090063          	beqz	s2,80003444 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003428:	8552                	mv	a0,s4
    8000342a:	00000097          	auipc	ra,0x0
    8000342e:	c9c080e7          	jalr	-868(ra) # 800030c6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003432:	854a                	mv	a0,s2
    80003434:	70a2                	ld	ra,40(sp)
    80003436:	7402                	ld	s0,32(sp)
    80003438:	64e2                	ld	s1,24(sp)
    8000343a:	6942                	ld	s2,16(sp)
    8000343c:	69a2                	ld	s3,8(sp)
    8000343e:	6a02                	ld	s4,0(sp)
    80003440:	6145                	addi	sp,sp,48
    80003442:	8082                	ret
      addr = balloc(ip->dev);
    80003444:	0009a503          	lw	a0,0(s3)
    80003448:	00000097          	auipc	ra,0x0
    8000344c:	e10080e7          	jalr	-496(ra) # 80003258 <balloc>
    80003450:	0005091b          	sext.w	s2,a0
      if(addr){
    80003454:	fc090ae3          	beqz	s2,80003428 <bmap+0x98>
        a[bn] = addr;
    80003458:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000345c:	8552                	mv	a0,s4
    8000345e:	00001097          	auipc	ra,0x1
    80003462:	eec080e7          	jalr	-276(ra) # 8000434a <log_write>
    80003466:	b7c9                	j	80003428 <bmap+0x98>
  panic("bmap: out of range");
    80003468:	00005517          	auipc	a0,0x5
    8000346c:	20050513          	addi	a0,a0,512 # 80008668 <syscalls+0x138>
    80003470:	ffffd097          	auipc	ra,0xffffd
    80003474:	0d4080e7          	jalr	212(ra) # 80000544 <panic>

0000000080003478 <iget>:
{
    80003478:	7179                	addi	sp,sp,-48
    8000347a:	f406                	sd	ra,40(sp)
    8000347c:	f022                	sd	s0,32(sp)
    8000347e:	ec26                	sd	s1,24(sp)
    80003480:	e84a                	sd	s2,16(sp)
    80003482:	e44e                	sd	s3,8(sp)
    80003484:	e052                	sd	s4,0(sp)
    80003486:	1800                	addi	s0,sp,48
    80003488:	89aa                	mv	s3,a0
    8000348a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000348c:	0001c517          	auipc	a0,0x1c
    80003490:	5bc50513          	addi	a0,a0,1468 # 8001fa48 <itable>
    80003494:	ffffd097          	auipc	ra,0xffffd
    80003498:	756080e7          	jalr	1878(ra) # 80000bea <acquire>
  empty = 0;
    8000349c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000349e:	0001c497          	auipc	s1,0x1c
    800034a2:	5c248493          	addi	s1,s1,1474 # 8001fa60 <itable+0x18>
    800034a6:	0001e697          	auipc	a3,0x1e
    800034aa:	04a68693          	addi	a3,a3,74 # 800214f0 <log>
    800034ae:	a039                	j	800034bc <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034b0:	02090b63          	beqz	s2,800034e6 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034b4:	08848493          	addi	s1,s1,136
    800034b8:	02d48a63          	beq	s1,a3,800034ec <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034bc:	449c                	lw	a5,8(s1)
    800034be:	fef059e3          	blez	a5,800034b0 <iget+0x38>
    800034c2:	4098                	lw	a4,0(s1)
    800034c4:	ff3716e3          	bne	a4,s3,800034b0 <iget+0x38>
    800034c8:	40d8                	lw	a4,4(s1)
    800034ca:	ff4713e3          	bne	a4,s4,800034b0 <iget+0x38>
      ip->ref++;
    800034ce:	2785                	addiw	a5,a5,1
    800034d0:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800034d2:	0001c517          	auipc	a0,0x1c
    800034d6:	57650513          	addi	a0,a0,1398 # 8001fa48 <itable>
    800034da:	ffffd097          	auipc	ra,0xffffd
    800034de:	7c4080e7          	jalr	1988(ra) # 80000c9e <release>
      return ip;
    800034e2:	8926                	mv	s2,s1
    800034e4:	a03d                	j	80003512 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034e6:	f7f9                	bnez	a5,800034b4 <iget+0x3c>
    800034e8:	8926                	mv	s2,s1
    800034ea:	b7e9                	j	800034b4 <iget+0x3c>
  if(empty == 0)
    800034ec:	02090c63          	beqz	s2,80003524 <iget+0xac>
  ip->dev = dev;
    800034f0:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034f4:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034f8:	4785                	li	a5,1
    800034fa:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034fe:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003502:	0001c517          	auipc	a0,0x1c
    80003506:	54650513          	addi	a0,a0,1350 # 8001fa48 <itable>
    8000350a:	ffffd097          	auipc	ra,0xffffd
    8000350e:	794080e7          	jalr	1940(ra) # 80000c9e <release>
}
    80003512:	854a                	mv	a0,s2
    80003514:	70a2                	ld	ra,40(sp)
    80003516:	7402                	ld	s0,32(sp)
    80003518:	64e2                	ld	s1,24(sp)
    8000351a:	6942                	ld	s2,16(sp)
    8000351c:	69a2                	ld	s3,8(sp)
    8000351e:	6a02                	ld	s4,0(sp)
    80003520:	6145                	addi	sp,sp,48
    80003522:	8082                	ret
    panic("iget: no inodes");
    80003524:	00005517          	auipc	a0,0x5
    80003528:	15c50513          	addi	a0,a0,348 # 80008680 <syscalls+0x150>
    8000352c:	ffffd097          	auipc	ra,0xffffd
    80003530:	018080e7          	jalr	24(ra) # 80000544 <panic>

0000000080003534 <fsinit>:
fsinit(int dev) {
    80003534:	7179                	addi	sp,sp,-48
    80003536:	f406                	sd	ra,40(sp)
    80003538:	f022                	sd	s0,32(sp)
    8000353a:	ec26                	sd	s1,24(sp)
    8000353c:	e84a                	sd	s2,16(sp)
    8000353e:	e44e                	sd	s3,8(sp)
    80003540:	1800                	addi	s0,sp,48
    80003542:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003544:	4585                	li	a1,1
    80003546:	00000097          	auipc	ra,0x0
    8000354a:	a50080e7          	jalr	-1456(ra) # 80002f96 <bread>
    8000354e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003550:	0001c997          	auipc	s3,0x1c
    80003554:	4d898993          	addi	s3,s3,1240 # 8001fa28 <sb>
    80003558:	02000613          	li	a2,32
    8000355c:	05850593          	addi	a1,a0,88
    80003560:	854e                	mv	a0,s3
    80003562:	ffffd097          	auipc	ra,0xffffd
    80003566:	7e4080e7          	jalr	2020(ra) # 80000d46 <memmove>
  brelse(bp);
    8000356a:	8526                	mv	a0,s1
    8000356c:	00000097          	auipc	ra,0x0
    80003570:	b5a080e7          	jalr	-1190(ra) # 800030c6 <brelse>
  if(sb.magic != FSMAGIC)
    80003574:	0009a703          	lw	a4,0(s3)
    80003578:	102037b7          	lui	a5,0x10203
    8000357c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003580:	02f71263          	bne	a4,a5,800035a4 <fsinit+0x70>
  initlog(dev, &sb);
    80003584:	0001c597          	auipc	a1,0x1c
    80003588:	4a458593          	addi	a1,a1,1188 # 8001fa28 <sb>
    8000358c:	854a                	mv	a0,s2
    8000358e:	00001097          	auipc	ra,0x1
    80003592:	b40080e7          	jalr	-1216(ra) # 800040ce <initlog>
}
    80003596:	70a2                	ld	ra,40(sp)
    80003598:	7402                	ld	s0,32(sp)
    8000359a:	64e2                	ld	s1,24(sp)
    8000359c:	6942                	ld	s2,16(sp)
    8000359e:	69a2                	ld	s3,8(sp)
    800035a0:	6145                	addi	sp,sp,48
    800035a2:	8082                	ret
    panic("invalid file system");
    800035a4:	00005517          	auipc	a0,0x5
    800035a8:	0ec50513          	addi	a0,a0,236 # 80008690 <syscalls+0x160>
    800035ac:	ffffd097          	auipc	ra,0xffffd
    800035b0:	f98080e7          	jalr	-104(ra) # 80000544 <panic>

00000000800035b4 <iinit>:
{
    800035b4:	7179                	addi	sp,sp,-48
    800035b6:	f406                	sd	ra,40(sp)
    800035b8:	f022                	sd	s0,32(sp)
    800035ba:	ec26                	sd	s1,24(sp)
    800035bc:	e84a                	sd	s2,16(sp)
    800035be:	e44e                	sd	s3,8(sp)
    800035c0:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800035c2:	00005597          	auipc	a1,0x5
    800035c6:	0e658593          	addi	a1,a1,230 # 800086a8 <syscalls+0x178>
    800035ca:	0001c517          	auipc	a0,0x1c
    800035ce:	47e50513          	addi	a0,a0,1150 # 8001fa48 <itable>
    800035d2:	ffffd097          	auipc	ra,0xffffd
    800035d6:	588080e7          	jalr	1416(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    800035da:	0001c497          	auipc	s1,0x1c
    800035de:	49648493          	addi	s1,s1,1174 # 8001fa70 <itable+0x28>
    800035e2:	0001e997          	auipc	s3,0x1e
    800035e6:	f1e98993          	addi	s3,s3,-226 # 80021500 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800035ea:	00005917          	auipc	s2,0x5
    800035ee:	0c690913          	addi	s2,s2,198 # 800086b0 <syscalls+0x180>
    800035f2:	85ca                	mv	a1,s2
    800035f4:	8526                	mv	a0,s1
    800035f6:	00001097          	auipc	ra,0x1
    800035fa:	e3a080e7          	jalr	-454(ra) # 80004430 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035fe:	08848493          	addi	s1,s1,136
    80003602:	ff3498e3          	bne	s1,s3,800035f2 <iinit+0x3e>
}
    80003606:	70a2                	ld	ra,40(sp)
    80003608:	7402                	ld	s0,32(sp)
    8000360a:	64e2                	ld	s1,24(sp)
    8000360c:	6942                	ld	s2,16(sp)
    8000360e:	69a2                	ld	s3,8(sp)
    80003610:	6145                	addi	sp,sp,48
    80003612:	8082                	ret

0000000080003614 <ialloc>:
{
    80003614:	715d                	addi	sp,sp,-80
    80003616:	e486                	sd	ra,72(sp)
    80003618:	e0a2                	sd	s0,64(sp)
    8000361a:	fc26                	sd	s1,56(sp)
    8000361c:	f84a                	sd	s2,48(sp)
    8000361e:	f44e                	sd	s3,40(sp)
    80003620:	f052                	sd	s4,32(sp)
    80003622:	ec56                	sd	s5,24(sp)
    80003624:	e85a                	sd	s6,16(sp)
    80003626:	e45e                	sd	s7,8(sp)
    80003628:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000362a:	0001c717          	auipc	a4,0x1c
    8000362e:	40a72703          	lw	a4,1034(a4) # 8001fa34 <sb+0xc>
    80003632:	4785                	li	a5,1
    80003634:	04e7fa63          	bgeu	a5,a4,80003688 <ialloc+0x74>
    80003638:	8aaa                	mv	s5,a0
    8000363a:	8bae                	mv	s7,a1
    8000363c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000363e:	0001ca17          	auipc	s4,0x1c
    80003642:	3eaa0a13          	addi	s4,s4,1002 # 8001fa28 <sb>
    80003646:	00048b1b          	sext.w	s6,s1
    8000364a:	0044d593          	srli	a1,s1,0x4
    8000364e:	018a2783          	lw	a5,24(s4)
    80003652:	9dbd                	addw	a1,a1,a5
    80003654:	8556                	mv	a0,s5
    80003656:	00000097          	auipc	ra,0x0
    8000365a:	940080e7          	jalr	-1728(ra) # 80002f96 <bread>
    8000365e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003660:	05850993          	addi	s3,a0,88
    80003664:	00f4f793          	andi	a5,s1,15
    80003668:	079a                	slli	a5,a5,0x6
    8000366a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000366c:	00099783          	lh	a5,0(s3)
    80003670:	c3a1                	beqz	a5,800036b0 <ialloc+0x9c>
    brelse(bp);
    80003672:	00000097          	auipc	ra,0x0
    80003676:	a54080e7          	jalr	-1452(ra) # 800030c6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000367a:	0485                	addi	s1,s1,1
    8000367c:	00ca2703          	lw	a4,12(s4)
    80003680:	0004879b          	sext.w	a5,s1
    80003684:	fce7e1e3          	bltu	a5,a4,80003646 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003688:	00005517          	auipc	a0,0x5
    8000368c:	03050513          	addi	a0,a0,48 # 800086b8 <syscalls+0x188>
    80003690:	ffffd097          	auipc	ra,0xffffd
    80003694:	efe080e7          	jalr	-258(ra) # 8000058e <printf>
  return 0;
    80003698:	4501                	li	a0,0
}
    8000369a:	60a6                	ld	ra,72(sp)
    8000369c:	6406                	ld	s0,64(sp)
    8000369e:	74e2                	ld	s1,56(sp)
    800036a0:	7942                	ld	s2,48(sp)
    800036a2:	79a2                	ld	s3,40(sp)
    800036a4:	7a02                	ld	s4,32(sp)
    800036a6:	6ae2                	ld	s5,24(sp)
    800036a8:	6b42                	ld	s6,16(sp)
    800036aa:	6ba2                	ld	s7,8(sp)
    800036ac:	6161                	addi	sp,sp,80
    800036ae:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800036b0:	04000613          	li	a2,64
    800036b4:	4581                	li	a1,0
    800036b6:	854e                	mv	a0,s3
    800036b8:	ffffd097          	auipc	ra,0xffffd
    800036bc:	62e080e7          	jalr	1582(ra) # 80000ce6 <memset>
      dip->type = type;
    800036c0:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036c4:	854a                	mv	a0,s2
    800036c6:	00001097          	auipc	ra,0x1
    800036ca:	c84080e7          	jalr	-892(ra) # 8000434a <log_write>
      brelse(bp);
    800036ce:	854a                	mv	a0,s2
    800036d0:	00000097          	auipc	ra,0x0
    800036d4:	9f6080e7          	jalr	-1546(ra) # 800030c6 <brelse>
      return iget(dev, inum);
    800036d8:	85da                	mv	a1,s6
    800036da:	8556                	mv	a0,s5
    800036dc:	00000097          	auipc	ra,0x0
    800036e0:	d9c080e7          	jalr	-612(ra) # 80003478 <iget>
    800036e4:	bf5d                	j	8000369a <ialloc+0x86>

00000000800036e6 <iupdate>:
{
    800036e6:	1101                	addi	sp,sp,-32
    800036e8:	ec06                	sd	ra,24(sp)
    800036ea:	e822                	sd	s0,16(sp)
    800036ec:	e426                	sd	s1,8(sp)
    800036ee:	e04a                	sd	s2,0(sp)
    800036f0:	1000                	addi	s0,sp,32
    800036f2:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036f4:	415c                	lw	a5,4(a0)
    800036f6:	0047d79b          	srliw	a5,a5,0x4
    800036fa:	0001c597          	auipc	a1,0x1c
    800036fe:	3465a583          	lw	a1,838(a1) # 8001fa40 <sb+0x18>
    80003702:	9dbd                	addw	a1,a1,a5
    80003704:	4108                	lw	a0,0(a0)
    80003706:	00000097          	auipc	ra,0x0
    8000370a:	890080e7          	jalr	-1904(ra) # 80002f96 <bread>
    8000370e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003710:	05850793          	addi	a5,a0,88
    80003714:	40c8                	lw	a0,4(s1)
    80003716:	893d                	andi	a0,a0,15
    80003718:	051a                	slli	a0,a0,0x6
    8000371a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000371c:	04449703          	lh	a4,68(s1)
    80003720:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003724:	04649703          	lh	a4,70(s1)
    80003728:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000372c:	04849703          	lh	a4,72(s1)
    80003730:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003734:	04a49703          	lh	a4,74(s1)
    80003738:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000373c:	44f8                	lw	a4,76(s1)
    8000373e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003740:	03400613          	li	a2,52
    80003744:	05048593          	addi	a1,s1,80
    80003748:	0531                	addi	a0,a0,12
    8000374a:	ffffd097          	auipc	ra,0xffffd
    8000374e:	5fc080e7          	jalr	1532(ra) # 80000d46 <memmove>
  log_write(bp);
    80003752:	854a                	mv	a0,s2
    80003754:	00001097          	auipc	ra,0x1
    80003758:	bf6080e7          	jalr	-1034(ra) # 8000434a <log_write>
  brelse(bp);
    8000375c:	854a                	mv	a0,s2
    8000375e:	00000097          	auipc	ra,0x0
    80003762:	968080e7          	jalr	-1688(ra) # 800030c6 <brelse>
}
    80003766:	60e2                	ld	ra,24(sp)
    80003768:	6442                	ld	s0,16(sp)
    8000376a:	64a2                	ld	s1,8(sp)
    8000376c:	6902                	ld	s2,0(sp)
    8000376e:	6105                	addi	sp,sp,32
    80003770:	8082                	ret

0000000080003772 <idup>:
{
    80003772:	1101                	addi	sp,sp,-32
    80003774:	ec06                	sd	ra,24(sp)
    80003776:	e822                	sd	s0,16(sp)
    80003778:	e426                	sd	s1,8(sp)
    8000377a:	1000                	addi	s0,sp,32
    8000377c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000377e:	0001c517          	auipc	a0,0x1c
    80003782:	2ca50513          	addi	a0,a0,714 # 8001fa48 <itable>
    80003786:	ffffd097          	auipc	ra,0xffffd
    8000378a:	464080e7          	jalr	1124(ra) # 80000bea <acquire>
  ip->ref++;
    8000378e:	449c                	lw	a5,8(s1)
    80003790:	2785                	addiw	a5,a5,1
    80003792:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003794:	0001c517          	auipc	a0,0x1c
    80003798:	2b450513          	addi	a0,a0,692 # 8001fa48 <itable>
    8000379c:	ffffd097          	auipc	ra,0xffffd
    800037a0:	502080e7          	jalr	1282(ra) # 80000c9e <release>
}
    800037a4:	8526                	mv	a0,s1
    800037a6:	60e2                	ld	ra,24(sp)
    800037a8:	6442                	ld	s0,16(sp)
    800037aa:	64a2                	ld	s1,8(sp)
    800037ac:	6105                	addi	sp,sp,32
    800037ae:	8082                	ret

00000000800037b0 <ilock>:
{
    800037b0:	1101                	addi	sp,sp,-32
    800037b2:	ec06                	sd	ra,24(sp)
    800037b4:	e822                	sd	s0,16(sp)
    800037b6:	e426                	sd	s1,8(sp)
    800037b8:	e04a                	sd	s2,0(sp)
    800037ba:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037bc:	c115                	beqz	a0,800037e0 <ilock+0x30>
    800037be:	84aa                	mv	s1,a0
    800037c0:	451c                	lw	a5,8(a0)
    800037c2:	00f05f63          	blez	a5,800037e0 <ilock+0x30>
  acquiresleep(&ip->lock);
    800037c6:	0541                	addi	a0,a0,16
    800037c8:	00001097          	auipc	ra,0x1
    800037cc:	ca2080e7          	jalr	-862(ra) # 8000446a <acquiresleep>
  if(ip->valid == 0){
    800037d0:	40bc                	lw	a5,64(s1)
    800037d2:	cf99                	beqz	a5,800037f0 <ilock+0x40>
}
    800037d4:	60e2                	ld	ra,24(sp)
    800037d6:	6442                	ld	s0,16(sp)
    800037d8:	64a2                	ld	s1,8(sp)
    800037da:	6902                	ld	s2,0(sp)
    800037dc:	6105                	addi	sp,sp,32
    800037de:	8082                	ret
    panic("ilock");
    800037e0:	00005517          	auipc	a0,0x5
    800037e4:	ef050513          	addi	a0,a0,-272 # 800086d0 <syscalls+0x1a0>
    800037e8:	ffffd097          	auipc	ra,0xffffd
    800037ec:	d5c080e7          	jalr	-676(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037f0:	40dc                	lw	a5,4(s1)
    800037f2:	0047d79b          	srliw	a5,a5,0x4
    800037f6:	0001c597          	auipc	a1,0x1c
    800037fa:	24a5a583          	lw	a1,586(a1) # 8001fa40 <sb+0x18>
    800037fe:	9dbd                	addw	a1,a1,a5
    80003800:	4088                	lw	a0,0(s1)
    80003802:	fffff097          	auipc	ra,0xfffff
    80003806:	794080e7          	jalr	1940(ra) # 80002f96 <bread>
    8000380a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000380c:	05850593          	addi	a1,a0,88
    80003810:	40dc                	lw	a5,4(s1)
    80003812:	8bbd                	andi	a5,a5,15
    80003814:	079a                	slli	a5,a5,0x6
    80003816:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003818:	00059783          	lh	a5,0(a1)
    8000381c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003820:	00259783          	lh	a5,2(a1)
    80003824:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003828:	00459783          	lh	a5,4(a1)
    8000382c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003830:	00659783          	lh	a5,6(a1)
    80003834:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003838:	459c                	lw	a5,8(a1)
    8000383a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000383c:	03400613          	li	a2,52
    80003840:	05b1                	addi	a1,a1,12
    80003842:	05048513          	addi	a0,s1,80
    80003846:	ffffd097          	auipc	ra,0xffffd
    8000384a:	500080e7          	jalr	1280(ra) # 80000d46 <memmove>
    brelse(bp);
    8000384e:	854a                	mv	a0,s2
    80003850:	00000097          	auipc	ra,0x0
    80003854:	876080e7          	jalr	-1930(ra) # 800030c6 <brelse>
    ip->valid = 1;
    80003858:	4785                	li	a5,1
    8000385a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000385c:	04449783          	lh	a5,68(s1)
    80003860:	fbb5                	bnez	a5,800037d4 <ilock+0x24>
      panic("ilock: no type");
    80003862:	00005517          	auipc	a0,0x5
    80003866:	e7650513          	addi	a0,a0,-394 # 800086d8 <syscalls+0x1a8>
    8000386a:	ffffd097          	auipc	ra,0xffffd
    8000386e:	cda080e7          	jalr	-806(ra) # 80000544 <panic>

0000000080003872 <iunlock>:
{
    80003872:	1101                	addi	sp,sp,-32
    80003874:	ec06                	sd	ra,24(sp)
    80003876:	e822                	sd	s0,16(sp)
    80003878:	e426                	sd	s1,8(sp)
    8000387a:	e04a                	sd	s2,0(sp)
    8000387c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000387e:	c905                	beqz	a0,800038ae <iunlock+0x3c>
    80003880:	84aa                	mv	s1,a0
    80003882:	01050913          	addi	s2,a0,16
    80003886:	854a                	mv	a0,s2
    80003888:	00001097          	auipc	ra,0x1
    8000388c:	c7c080e7          	jalr	-900(ra) # 80004504 <holdingsleep>
    80003890:	cd19                	beqz	a0,800038ae <iunlock+0x3c>
    80003892:	449c                	lw	a5,8(s1)
    80003894:	00f05d63          	blez	a5,800038ae <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003898:	854a                	mv	a0,s2
    8000389a:	00001097          	auipc	ra,0x1
    8000389e:	c26080e7          	jalr	-986(ra) # 800044c0 <releasesleep>
}
    800038a2:	60e2                	ld	ra,24(sp)
    800038a4:	6442                	ld	s0,16(sp)
    800038a6:	64a2                	ld	s1,8(sp)
    800038a8:	6902                	ld	s2,0(sp)
    800038aa:	6105                	addi	sp,sp,32
    800038ac:	8082                	ret
    panic("iunlock");
    800038ae:	00005517          	auipc	a0,0x5
    800038b2:	e3a50513          	addi	a0,a0,-454 # 800086e8 <syscalls+0x1b8>
    800038b6:	ffffd097          	auipc	ra,0xffffd
    800038ba:	c8e080e7          	jalr	-882(ra) # 80000544 <panic>

00000000800038be <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038be:	7179                	addi	sp,sp,-48
    800038c0:	f406                	sd	ra,40(sp)
    800038c2:	f022                	sd	s0,32(sp)
    800038c4:	ec26                	sd	s1,24(sp)
    800038c6:	e84a                	sd	s2,16(sp)
    800038c8:	e44e                	sd	s3,8(sp)
    800038ca:	e052                	sd	s4,0(sp)
    800038cc:	1800                	addi	s0,sp,48
    800038ce:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038d0:	05050493          	addi	s1,a0,80
    800038d4:	08050913          	addi	s2,a0,128
    800038d8:	a021                	j	800038e0 <itrunc+0x22>
    800038da:	0491                	addi	s1,s1,4
    800038dc:	01248d63          	beq	s1,s2,800038f6 <itrunc+0x38>
    if(ip->addrs[i]){
    800038e0:	408c                	lw	a1,0(s1)
    800038e2:	dde5                	beqz	a1,800038da <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038e4:	0009a503          	lw	a0,0(s3)
    800038e8:	00000097          	auipc	ra,0x0
    800038ec:	8f4080e7          	jalr	-1804(ra) # 800031dc <bfree>
      ip->addrs[i] = 0;
    800038f0:	0004a023          	sw	zero,0(s1)
    800038f4:	b7dd                	j	800038da <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038f6:	0809a583          	lw	a1,128(s3)
    800038fa:	e185                	bnez	a1,8000391a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038fc:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003900:	854e                	mv	a0,s3
    80003902:	00000097          	auipc	ra,0x0
    80003906:	de4080e7          	jalr	-540(ra) # 800036e6 <iupdate>
}
    8000390a:	70a2                	ld	ra,40(sp)
    8000390c:	7402                	ld	s0,32(sp)
    8000390e:	64e2                	ld	s1,24(sp)
    80003910:	6942                	ld	s2,16(sp)
    80003912:	69a2                	ld	s3,8(sp)
    80003914:	6a02                	ld	s4,0(sp)
    80003916:	6145                	addi	sp,sp,48
    80003918:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000391a:	0009a503          	lw	a0,0(s3)
    8000391e:	fffff097          	auipc	ra,0xfffff
    80003922:	678080e7          	jalr	1656(ra) # 80002f96 <bread>
    80003926:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003928:	05850493          	addi	s1,a0,88
    8000392c:	45850913          	addi	s2,a0,1112
    80003930:	a811                	j	80003944 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003932:	0009a503          	lw	a0,0(s3)
    80003936:	00000097          	auipc	ra,0x0
    8000393a:	8a6080e7          	jalr	-1882(ra) # 800031dc <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000393e:	0491                	addi	s1,s1,4
    80003940:	01248563          	beq	s1,s2,8000394a <itrunc+0x8c>
      if(a[j])
    80003944:	408c                	lw	a1,0(s1)
    80003946:	dde5                	beqz	a1,8000393e <itrunc+0x80>
    80003948:	b7ed                	j	80003932 <itrunc+0x74>
    brelse(bp);
    8000394a:	8552                	mv	a0,s4
    8000394c:	fffff097          	auipc	ra,0xfffff
    80003950:	77a080e7          	jalr	1914(ra) # 800030c6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003954:	0809a583          	lw	a1,128(s3)
    80003958:	0009a503          	lw	a0,0(s3)
    8000395c:	00000097          	auipc	ra,0x0
    80003960:	880080e7          	jalr	-1920(ra) # 800031dc <bfree>
    ip->addrs[NDIRECT] = 0;
    80003964:	0809a023          	sw	zero,128(s3)
    80003968:	bf51                	j	800038fc <itrunc+0x3e>

000000008000396a <iput>:
{
    8000396a:	1101                	addi	sp,sp,-32
    8000396c:	ec06                	sd	ra,24(sp)
    8000396e:	e822                	sd	s0,16(sp)
    80003970:	e426                	sd	s1,8(sp)
    80003972:	e04a                	sd	s2,0(sp)
    80003974:	1000                	addi	s0,sp,32
    80003976:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003978:	0001c517          	auipc	a0,0x1c
    8000397c:	0d050513          	addi	a0,a0,208 # 8001fa48 <itable>
    80003980:	ffffd097          	auipc	ra,0xffffd
    80003984:	26a080e7          	jalr	618(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003988:	4498                	lw	a4,8(s1)
    8000398a:	4785                	li	a5,1
    8000398c:	02f70363          	beq	a4,a5,800039b2 <iput+0x48>
  ip->ref--;
    80003990:	449c                	lw	a5,8(s1)
    80003992:	37fd                	addiw	a5,a5,-1
    80003994:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003996:	0001c517          	auipc	a0,0x1c
    8000399a:	0b250513          	addi	a0,a0,178 # 8001fa48 <itable>
    8000399e:	ffffd097          	auipc	ra,0xffffd
    800039a2:	300080e7          	jalr	768(ra) # 80000c9e <release>
}
    800039a6:	60e2                	ld	ra,24(sp)
    800039a8:	6442                	ld	s0,16(sp)
    800039aa:	64a2                	ld	s1,8(sp)
    800039ac:	6902                	ld	s2,0(sp)
    800039ae:	6105                	addi	sp,sp,32
    800039b0:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039b2:	40bc                	lw	a5,64(s1)
    800039b4:	dff1                	beqz	a5,80003990 <iput+0x26>
    800039b6:	04a49783          	lh	a5,74(s1)
    800039ba:	fbf9                	bnez	a5,80003990 <iput+0x26>
    acquiresleep(&ip->lock);
    800039bc:	01048913          	addi	s2,s1,16
    800039c0:	854a                	mv	a0,s2
    800039c2:	00001097          	auipc	ra,0x1
    800039c6:	aa8080e7          	jalr	-1368(ra) # 8000446a <acquiresleep>
    release(&itable.lock);
    800039ca:	0001c517          	auipc	a0,0x1c
    800039ce:	07e50513          	addi	a0,a0,126 # 8001fa48 <itable>
    800039d2:	ffffd097          	auipc	ra,0xffffd
    800039d6:	2cc080e7          	jalr	716(ra) # 80000c9e <release>
    itrunc(ip);
    800039da:	8526                	mv	a0,s1
    800039dc:	00000097          	auipc	ra,0x0
    800039e0:	ee2080e7          	jalr	-286(ra) # 800038be <itrunc>
    ip->type = 0;
    800039e4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039e8:	8526                	mv	a0,s1
    800039ea:	00000097          	auipc	ra,0x0
    800039ee:	cfc080e7          	jalr	-772(ra) # 800036e6 <iupdate>
    ip->valid = 0;
    800039f2:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039f6:	854a                	mv	a0,s2
    800039f8:	00001097          	auipc	ra,0x1
    800039fc:	ac8080e7          	jalr	-1336(ra) # 800044c0 <releasesleep>
    acquire(&itable.lock);
    80003a00:	0001c517          	auipc	a0,0x1c
    80003a04:	04850513          	addi	a0,a0,72 # 8001fa48 <itable>
    80003a08:	ffffd097          	auipc	ra,0xffffd
    80003a0c:	1e2080e7          	jalr	482(ra) # 80000bea <acquire>
    80003a10:	b741                	j	80003990 <iput+0x26>

0000000080003a12 <iunlockput>:
{
    80003a12:	1101                	addi	sp,sp,-32
    80003a14:	ec06                	sd	ra,24(sp)
    80003a16:	e822                	sd	s0,16(sp)
    80003a18:	e426                	sd	s1,8(sp)
    80003a1a:	1000                	addi	s0,sp,32
    80003a1c:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a1e:	00000097          	auipc	ra,0x0
    80003a22:	e54080e7          	jalr	-428(ra) # 80003872 <iunlock>
  iput(ip);
    80003a26:	8526                	mv	a0,s1
    80003a28:	00000097          	auipc	ra,0x0
    80003a2c:	f42080e7          	jalr	-190(ra) # 8000396a <iput>
}
    80003a30:	60e2                	ld	ra,24(sp)
    80003a32:	6442                	ld	s0,16(sp)
    80003a34:	64a2                	ld	s1,8(sp)
    80003a36:	6105                	addi	sp,sp,32
    80003a38:	8082                	ret

0000000080003a3a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a3a:	1141                	addi	sp,sp,-16
    80003a3c:	e422                	sd	s0,8(sp)
    80003a3e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a40:	411c                	lw	a5,0(a0)
    80003a42:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a44:	415c                	lw	a5,4(a0)
    80003a46:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a48:	04451783          	lh	a5,68(a0)
    80003a4c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a50:	04a51783          	lh	a5,74(a0)
    80003a54:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a58:	04c56783          	lwu	a5,76(a0)
    80003a5c:	e99c                	sd	a5,16(a1)
}
    80003a5e:	6422                	ld	s0,8(sp)
    80003a60:	0141                	addi	sp,sp,16
    80003a62:	8082                	ret

0000000080003a64 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a64:	457c                	lw	a5,76(a0)
    80003a66:	0ed7e963          	bltu	a5,a3,80003b58 <readi+0xf4>
{
    80003a6a:	7159                	addi	sp,sp,-112
    80003a6c:	f486                	sd	ra,104(sp)
    80003a6e:	f0a2                	sd	s0,96(sp)
    80003a70:	eca6                	sd	s1,88(sp)
    80003a72:	e8ca                	sd	s2,80(sp)
    80003a74:	e4ce                	sd	s3,72(sp)
    80003a76:	e0d2                	sd	s4,64(sp)
    80003a78:	fc56                	sd	s5,56(sp)
    80003a7a:	f85a                	sd	s6,48(sp)
    80003a7c:	f45e                	sd	s7,40(sp)
    80003a7e:	f062                	sd	s8,32(sp)
    80003a80:	ec66                	sd	s9,24(sp)
    80003a82:	e86a                	sd	s10,16(sp)
    80003a84:	e46e                	sd	s11,8(sp)
    80003a86:	1880                	addi	s0,sp,112
    80003a88:	8b2a                	mv	s6,a0
    80003a8a:	8bae                	mv	s7,a1
    80003a8c:	8a32                	mv	s4,a2
    80003a8e:	84b6                	mv	s1,a3
    80003a90:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003a92:	9f35                	addw	a4,a4,a3
    return 0;
    80003a94:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a96:	0ad76063          	bltu	a4,a3,80003b36 <readi+0xd2>
  if(off + n > ip->size)
    80003a9a:	00e7f463          	bgeu	a5,a4,80003aa2 <readi+0x3e>
    n = ip->size - off;
    80003a9e:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003aa2:	0a0a8963          	beqz	s5,80003b54 <readi+0xf0>
    80003aa6:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aa8:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003aac:	5c7d                	li	s8,-1
    80003aae:	a82d                	j	80003ae8 <readi+0x84>
    80003ab0:	020d1d93          	slli	s11,s10,0x20
    80003ab4:	020ddd93          	srli	s11,s11,0x20
    80003ab8:	05890613          	addi	a2,s2,88
    80003abc:	86ee                	mv	a3,s11
    80003abe:	963a                	add	a2,a2,a4
    80003ac0:	85d2                	mv	a1,s4
    80003ac2:	855e                	mv	a0,s7
    80003ac4:	fffff097          	auipc	ra,0xfffff
    80003ac8:	9b6080e7          	jalr	-1610(ra) # 8000247a <either_copyout>
    80003acc:	05850d63          	beq	a0,s8,80003b26 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ad0:	854a                	mv	a0,s2
    80003ad2:	fffff097          	auipc	ra,0xfffff
    80003ad6:	5f4080e7          	jalr	1524(ra) # 800030c6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ada:	013d09bb          	addw	s3,s10,s3
    80003ade:	009d04bb          	addw	s1,s10,s1
    80003ae2:	9a6e                	add	s4,s4,s11
    80003ae4:	0559f763          	bgeu	s3,s5,80003b32 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003ae8:	00a4d59b          	srliw	a1,s1,0xa
    80003aec:	855a                	mv	a0,s6
    80003aee:	00000097          	auipc	ra,0x0
    80003af2:	8a2080e7          	jalr	-1886(ra) # 80003390 <bmap>
    80003af6:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003afa:	cd85                	beqz	a1,80003b32 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003afc:	000b2503          	lw	a0,0(s6)
    80003b00:	fffff097          	auipc	ra,0xfffff
    80003b04:	496080e7          	jalr	1174(ra) # 80002f96 <bread>
    80003b08:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b0a:	3ff4f713          	andi	a4,s1,1023
    80003b0e:	40ec87bb          	subw	a5,s9,a4
    80003b12:	413a86bb          	subw	a3,s5,s3
    80003b16:	8d3e                	mv	s10,a5
    80003b18:	2781                	sext.w	a5,a5
    80003b1a:	0006861b          	sext.w	a2,a3
    80003b1e:	f8f679e3          	bgeu	a2,a5,80003ab0 <readi+0x4c>
    80003b22:	8d36                	mv	s10,a3
    80003b24:	b771                	j	80003ab0 <readi+0x4c>
      brelse(bp);
    80003b26:	854a                	mv	a0,s2
    80003b28:	fffff097          	auipc	ra,0xfffff
    80003b2c:	59e080e7          	jalr	1438(ra) # 800030c6 <brelse>
      tot = -1;
    80003b30:	59fd                	li	s3,-1
  }
  return tot;
    80003b32:	0009851b          	sext.w	a0,s3
}
    80003b36:	70a6                	ld	ra,104(sp)
    80003b38:	7406                	ld	s0,96(sp)
    80003b3a:	64e6                	ld	s1,88(sp)
    80003b3c:	6946                	ld	s2,80(sp)
    80003b3e:	69a6                	ld	s3,72(sp)
    80003b40:	6a06                	ld	s4,64(sp)
    80003b42:	7ae2                	ld	s5,56(sp)
    80003b44:	7b42                	ld	s6,48(sp)
    80003b46:	7ba2                	ld	s7,40(sp)
    80003b48:	7c02                	ld	s8,32(sp)
    80003b4a:	6ce2                	ld	s9,24(sp)
    80003b4c:	6d42                	ld	s10,16(sp)
    80003b4e:	6da2                	ld	s11,8(sp)
    80003b50:	6165                	addi	sp,sp,112
    80003b52:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b54:	89d6                	mv	s3,s5
    80003b56:	bff1                	j	80003b32 <readi+0xce>
    return 0;
    80003b58:	4501                	li	a0,0
}
    80003b5a:	8082                	ret

0000000080003b5c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b5c:	457c                	lw	a5,76(a0)
    80003b5e:	10d7e863          	bltu	a5,a3,80003c6e <writei+0x112>
{
    80003b62:	7159                	addi	sp,sp,-112
    80003b64:	f486                	sd	ra,104(sp)
    80003b66:	f0a2                	sd	s0,96(sp)
    80003b68:	eca6                	sd	s1,88(sp)
    80003b6a:	e8ca                	sd	s2,80(sp)
    80003b6c:	e4ce                	sd	s3,72(sp)
    80003b6e:	e0d2                	sd	s4,64(sp)
    80003b70:	fc56                	sd	s5,56(sp)
    80003b72:	f85a                	sd	s6,48(sp)
    80003b74:	f45e                	sd	s7,40(sp)
    80003b76:	f062                	sd	s8,32(sp)
    80003b78:	ec66                	sd	s9,24(sp)
    80003b7a:	e86a                	sd	s10,16(sp)
    80003b7c:	e46e                	sd	s11,8(sp)
    80003b7e:	1880                	addi	s0,sp,112
    80003b80:	8aaa                	mv	s5,a0
    80003b82:	8bae                	mv	s7,a1
    80003b84:	8a32                	mv	s4,a2
    80003b86:	8936                	mv	s2,a3
    80003b88:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b8a:	00e687bb          	addw	a5,a3,a4
    80003b8e:	0ed7e263          	bltu	a5,a3,80003c72 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b92:	00043737          	lui	a4,0x43
    80003b96:	0ef76063          	bltu	a4,a5,80003c76 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b9a:	0c0b0863          	beqz	s6,80003c6a <writei+0x10e>
    80003b9e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ba0:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003ba4:	5c7d                	li	s8,-1
    80003ba6:	a091                	j	80003bea <writei+0x8e>
    80003ba8:	020d1d93          	slli	s11,s10,0x20
    80003bac:	020ddd93          	srli	s11,s11,0x20
    80003bb0:	05848513          	addi	a0,s1,88
    80003bb4:	86ee                	mv	a3,s11
    80003bb6:	8652                	mv	a2,s4
    80003bb8:	85de                	mv	a1,s7
    80003bba:	953a                	add	a0,a0,a4
    80003bbc:	fffff097          	auipc	ra,0xfffff
    80003bc0:	914080e7          	jalr	-1772(ra) # 800024d0 <either_copyin>
    80003bc4:	07850263          	beq	a0,s8,80003c28 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003bc8:	8526                	mv	a0,s1
    80003bca:	00000097          	auipc	ra,0x0
    80003bce:	780080e7          	jalr	1920(ra) # 8000434a <log_write>
    brelse(bp);
    80003bd2:	8526                	mv	a0,s1
    80003bd4:	fffff097          	auipc	ra,0xfffff
    80003bd8:	4f2080e7          	jalr	1266(ra) # 800030c6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bdc:	013d09bb          	addw	s3,s10,s3
    80003be0:	012d093b          	addw	s2,s10,s2
    80003be4:	9a6e                	add	s4,s4,s11
    80003be6:	0569f663          	bgeu	s3,s6,80003c32 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003bea:	00a9559b          	srliw	a1,s2,0xa
    80003bee:	8556                	mv	a0,s5
    80003bf0:	fffff097          	auipc	ra,0xfffff
    80003bf4:	7a0080e7          	jalr	1952(ra) # 80003390 <bmap>
    80003bf8:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003bfc:	c99d                	beqz	a1,80003c32 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003bfe:	000aa503          	lw	a0,0(s5)
    80003c02:	fffff097          	auipc	ra,0xfffff
    80003c06:	394080e7          	jalr	916(ra) # 80002f96 <bread>
    80003c0a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c0c:	3ff97713          	andi	a4,s2,1023
    80003c10:	40ec87bb          	subw	a5,s9,a4
    80003c14:	413b06bb          	subw	a3,s6,s3
    80003c18:	8d3e                	mv	s10,a5
    80003c1a:	2781                	sext.w	a5,a5
    80003c1c:	0006861b          	sext.w	a2,a3
    80003c20:	f8f674e3          	bgeu	a2,a5,80003ba8 <writei+0x4c>
    80003c24:	8d36                	mv	s10,a3
    80003c26:	b749                	j	80003ba8 <writei+0x4c>
      brelse(bp);
    80003c28:	8526                	mv	a0,s1
    80003c2a:	fffff097          	auipc	ra,0xfffff
    80003c2e:	49c080e7          	jalr	1180(ra) # 800030c6 <brelse>
  }

  if(off > ip->size)
    80003c32:	04caa783          	lw	a5,76(s5)
    80003c36:	0127f463          	bgeu	a5,s2,80003c3e <writei+0xe2>
    ip->size = off;
    80003c3a:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c3e:	8556                	mv	a0,s5
    80003c40:	00000097          	auipc	ra,0x0
    80003c44:	aa6080e7          	jalr	-1370(ra) # 800036e6 <iupdate>

  return tot;
    80003c48:	0009851b          	sext.w	a0,s3
}
    80003c4c:	70a6                	ld	ra,104(sp)
    80003c4e:	7406                	ld	s0,96(sp)
    80003c50:	64e6                	ld	s1,88(sp)
    80003c52:	6946                	ld	s2,80(sp)
    80003c54:	69a6                	ld	s3,72(sp)
    80003c56:	6a06                	ld	s4,64(sp)
    80003c58:	7ae2                	ld	s5,56(sp)
    80003c5a:	7b42                	ld	s6,48(sp)
    80003c5c:	7ba2                	ld	s7,40(sp)
    80003c5e:	7c02                	ld	s8,32(sp)
    80003c60:	6ce2                	ld	s9,24(sp)
    80003c62:	6d42                	ld	s10,16(sp)
    80003c64:	6da2                	ld	s11,8(sp)
    80003c66:	6165                	addi	sp,sp,112
    80003c68:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c6a:	89da                	mv	s3,s6
    80003c6c:	bfc9                	j	80003c3e <writei+0xe2>
    return -1;
    80003c6e:	557d                	li	a0,-1
}
    80003c70:	8082                	ret
    return -1;
    80003c72:	557d                	li	a0,-1
    80003c74:	bfe1                	j	80003c4c <writei+0xf0>
    return -1;
    80003c76:	557d                	li	a0,-1
    80003c78:	bfd1                	j	80003c4c <writei+0xf0>

0000000080003c7a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c7a:	1141                	addi	sp,sp,-16
    80003c7c:	e406                	sd	ra,8(sp)
    80003c7e:	e022                	sd	s0,0(sp)
    80003c80:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c82:	4639                	li	a2,14
    80003c84:	ffffd097          	auipc	ra,0xffffd
    80003c88:	13a080e7          	jalr	314(ra) # 80000dbe <strncmp>
}
    80003c8c:	60a2                	ld	ra,8(sp)
    80003c8e:	6402                	ld	s0,0(sp)
    80003c90:	0141                	addi	sp,sp,16
    80003c92:	8082                	ret

0000000080003c94 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c94:	7139                	addi	sp,sp,-64
    80003c96:	fc06                	sd	ra,56(sp)
    80003c98:	f822                	sd	s0,48(sp)
    80003c9a:	f426                	sd	s1,40(sp)
    80003c9c:	f04a                	sd	s2,32(sp)
    80003c9e:	ec4e                	sd	s3,24(sp)
    80003ca0:	e852                	sd	s4,16(sp)
    80003ca2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ca4:	04451703          	lh	a4,68(a0)
    80003ca8:	4785                	li	a5,1
    80003caa:	00f71a63          	bne	a4,a5,80003cbe <dirlookup+0x2a>
    80003cae:	892a                	mv	s2,a0
    80003cb0:	89ae                	mv	s3,a1
    80003cb2:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cb4:	457c                	lw	a5,76(a0)
    80003cb6:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003cb8:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cba:	e79d                	bnez	a5,80003ce8 <dirlookup+0x54>
    80003cbc:	a8a5                	j	80003d34 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003cbe:	00005517          	auipc	a0,0x5
    80003cc2:	a3250513          	addi	a0,a0,-1486 # 800086f0 <syscalls+0x1c0>
    80003cc6:	ffffd097          	auipc	ra,0xffffd
    80003cca:	87e080e7          	jalr	-1922(ra) # 80000544 <panic>
      panic("dirlookup read");
    80003cce:	00005517          	auipc	a0,0x5
    80003cd2:	a3a50513          	addi	a0,a0,-1478 # 80008708 <syscalls+0x1d8>
    80003cd6:	ffffd097          	auipc	ra,0xffffd
    80003cda:	86e080e7          	jalr	-1938(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cde:	24c1                	addiw	s1,s1,16
    80003ce0:	04c92783          	lw	a5,76(s2)
    80003ce4:	04f4f763          	bgeu	s1,a5,80003d32 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ce8:	4741                	li	a4,16
    80003cea:	86a6                	mv	a3,s1
    80003cec:	fc040613          	addi	a2,s0,-64
    80003cf0:	4581                	li	a1,0
    80003cf2:	854a                	mv	a0,s2
    80003cf4:	00000097          	auipc	ra,0x0
    80003cf8:	d70080e7          	jalr	-656(ra) # 80003a64 <readi>
    80003cfc:	47c1                	li	a5,16
    80003cfe:	fcf518e3          	bne	a0,a5,80003cce <dirlookup+0x3a>
    if(de.inum == 0)
    80003d02:	fc045783          	lhu	a5,-64(s0)
    80003d06:	dfe1                	beqz	a5,80003cde <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d08:	fc240593          	addi	a1,s0,-62
    80003d0c:	854e                	mv	a0,s3
    80003d0e:	00000097          	auipc	ra,0x0
    80003d12:	f6c080e7          	jalr	-148(ra) # 80003c7a <namecmp>
    80003d16:	f561                	bnez	a0,80003cde <dirlookup+0x4a>
      if(poff)
    80003d18:	000a0463          	beqz	s4,80003d20 <dirlookup+0x8c>
        *poff = off;
    80003d1c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d20:	fc045583          	lhu	a1,-64(s0)
    80003d24:	00092503          	lw	a0,0(s2)
    80003d28:	fffff097          	auipc	ra,0xfffff
    80003d2c:	750080e7          	jalr	1872(ra) # 80003478 <iget>
    80003d30:	a011                	j	80003d34 <dirlookup+0xa0>
  return 0;
    80003d32:	4501                	li	a0,0
}
    80003d34:	70e2                	ld	ra,56(sp)
    80003d36:	7442                	ld	s0,48(sp)
    80003d38:	74a2                	ld	s1,40(sp)
    80003d3a:	7902                	ld	s2,32(sp)
    80003d3c:	69e2                	ld	s3,24(sp)
    80003d3e:	6a42                	ld	s4,16(sp)
    80003d40:	6121                	addi	sp,sp,64
    80003d42:	8082                	ret

0000000080003d44 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d44:	711d                	addi	sp,sp,-96
    80003d46:	ec86                	sd	ra,88(sp)
    80003d48:	e8a2                	sd	s0,80(sp)
    80003d4a:	e4a6                	sd	s1,72(sp)
    80003d4c:	e0ca                	sd	s2,64(sp)
    80003d4e:	fc4e                	sd	s3,56(sp)
    80003d50:	f852                	sd	s4,48(sp)
    80003d52:	f456                	sd	s5,40(sp)
    80003d54:	f05a                	sd	s6,32(sp)
    80003d56:	ec5e                	sd	s7,24(sp)
    80003d58:	e862                	sd	s8,16(sp)
    80003d5a:	e466                	sd	s9,8(sp)
    80003d5c:	1080                	addi	s0,sp,96
    80003d5e:	84aa                	mv	s1,a0
    80003d60:	8b2e                	mv	s6,a1
    80003d62:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d64:	00054703          	lbu	a4,0(a0)
    80003d68:	02f00793          	li	a5,47
    80003d6c:	02f70363          	beq	a4,a5,80003d92 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d70:	ffffe097          	auipc	ra,0xffffe
    80003d74:	c56080e7          	jalr	-938(ra) # 800019c6 <myproc>
    80003d78:	15053503          	ld	a0,336(a0)
    80003d7c:	00000097          	auipc	ra,0x0
    80003d80:	9f6080e7          	jalr	-1546(ra) # 80003772 <idup>
    80003d84:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d86:	02f00913          	li	s2,47
  len = path - s;
    80003d8a:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d8c:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d8e:	4c05                	li	s8,1
    80003d90:	a865                	j	80003e48 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d92:	4585                	li	a1,1
    80003d94:	4505                	li	a0,1
    80003d96:	fffff097          	auipc	ra,0xfffff
    80003d9a:	6e2080e7          	jalr	1762(ra) # 80003478 <iget>
    80003d9e:	89aa                	mv	s3,a0
    80003da0:	b7dd                	j	80003d86 <namex+0x42>
      iunlockput(ip);
    80003da2:	854e                	mv	a0,s3
    80003da4:	00000097          	auipc	ra,0x0
    80003da8:	c6e080e7          	jalr	-914(ra) # 80003a12 <iunlockput>
      return 0;
    80003dac:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003dae:	854e                	mv	a0,s3
    80003db0:	60e6                	ld	ra,88(sp)
    80003db2:	6446                	ld	s0,80(sp)
    80003db4:	64a6                	ld	s1,72(sp)
    80003db6:	6906                	ld	s2,64(sp)
    80003db8:	79e2                	ld	s3,56(sp)
    80003dba:	7a42                	ld	s4,48(sp)
    80003dbc:	7aa2                	ld	s5,40(sp)
    80003dbe:	7b02                	ld	s6,32(sp)
    80003dc0:	6be2                	ld	s7,24(sp)
    80003dc2:	6c42                	ld	s8,16(sp)
    80003dc4:	6ca2                	ld	s9,8(sp)
    80003dc6:	6125                	addi	sp,sp,96
    80003dc8:	8082                	ret
      iunlock(ip);
    80003dca:	854e                	mv	a0,s3
    80003dcc:	00000097          	auipc	ra,0x0
    80003dd0:	aa6080e7          	jalr	-1370(ra) # 80003872 <iunlock>
      return ip;
    80003dd4:	bfe9                	j	80003dae <namex+0x6a>
      iunlockput(ip);
    80003dd6:	854e                	mv	a0,s3
    80003dd8:	00000097          	auipc	ra,0x0
    80003ddc:	c3a080e7          	jalr	-966(ra) # 80003a12 <iunlockput>
      return 0;
    80003de0:	89d2                	mv	s3,s4
    80003de2:	b7f1                	j	80003dae <namex+0x6a>
  len = path - s;
    80003de4:	40b48633          	sub	a2,s1,a1
    80003de8:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003dec:	094cd463          	bge	s9,s4,80003e74 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003df0:	4639                	li	a2,14
    80003df2:	8556                	mv	a0,s5
    80003df4:	ffffd097          	auipc	ra,0xffffd
    80003df8:	f52080e7          	jalr	-174(ra) # 80000d46 <memmove>
  while(*path == '/')
    80003dfc:	0004c783          	lbu	a5,0(s1)
    80003e00:	01279763          	bne	a5,s2,80003e0e <namex+0xca>
    path++;
    80003e04:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e06:	0004c783          	lbu	a5,0(s1)
    80003e0a:	ff278de3          	beq	a5,s2,80003e04 <namex+0xc0>
    ilock(ip);
    80003e0e:	854e                	mv	a0,s3
    80003e10:	00000097          	auipc	ra,0x0
    80003e14:	9a0080e7          	jalr	-1632(ra) # 800037b0 <ilock>
    if(ip->type != T_DIR){
    80003e18:	04499783          	lh	a5,68(s3)
    80003e1c:	f98793e3          	bne	a5,s8,80003da2 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e20:	000b0563          	beqz	s6,80003e2a <namex+0xe6>
    80003e24:	0004c783          	lbu	a5,0(s1)
    80003e28:	d3cd                	beqz	a5,80003dca <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e2a:	865e                	mv	a2,s7
    80003e2c:	85d6                	mv	a1,s5
    80003e2e:	854e                	mv	a0,s3
    80003e30:	00000097          	auipc	ra,0x0
    80003e34:	e64080e7          	jalr	-412(ra) # 80003c94 <dirlookup>
    80003e38:	8a2a                	mv	s4,a0
    80003e3a:	dd51                	beqz	a0,80003dd6 <namex+0x92>
    iunlockput(ip);
    80003e3c:	854e                	mv	a0,s3
    80003e3e:	00000097          	auipc	ra,0x0
    80003e42:	bd4080e7          	jalr	-1068(ra) # 80003a12 <iunlockput>
    ip = next;
    80003e46:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e48:	0004c783          	lbu	a5,0(s1)
    80003e4c:	05279763          	bne	a5,s2,80003e9a <namex+0x156>
    path++;
    80003e50:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e52:	0004c783          	lbu	a5,0(s1)
    80003e56:	ff278de3          	beq	a5,s2,80003e50 <namex+0x10c>
  if(*path == 0)
    80003e5a:	c79d                	beqz	a5,80003e88 <namex+0x144>
    path++;
    80003e5c:	85a6                	mv	a1,s1
  len = path - s;
    80003e5e:	8a5e                	mv	s4,s7
    80003e60:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e62:	01278963          	beq	a5,s2,80003e74 <namex+0x130>
    80003e66:	dfbd                	beqz	a5,80003de4 <namex+0xa0>
    path++;
    80003e68:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e6a:	0004c783          	lbu	a5,0(s1)
    80003e6e:	ff279ce3          	bne	a5,s2,80003e66 <namex+0x122>
    80003e72:	bf8d                	j	80003de4 <namex+0xa0>
    memmove(name, s, len);
    80003e74:	2601                	sext.w	a2,a2
    80003e76:	8556                	mv	a0,s5
    80003e78:	ffffd097          	auipc	ra,0xffffd
    80003e7c:	ece080e7          	jalr	-306(ra) # 80000d46 <memmove>
    name[len] = 0;
    80003e80:	9a56                	add	s4,s4,s5
    80003e82:	000a0023          	sb	zero,0(s4)
    80003e86:	bf9d                	j	80003dfc <namex+0xb8>
  if(nameiparent){
    80003e88:	f20b03e3          	beqz	s6,80003dae <namex+0x6a>
    iput(ip);
    80003e8c:	854e                	mv	a0,s3
    80003e8e:	00000097          	auipc	ra,0x0
    80003e92:	adc080e7          	jalr	-1316(ra) # 8000396a <iput>
    return 0;
    80003e96:	4981                	li	s3,0
    80003e98:	bf19                	j	80003dae <namex+0x6a>
  if(*path == 0)
    80003e9a:	d7fd                	beqz	a5,80003e88 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e9c:	0004c783          	lbu	a5,0(s1)
    80003ea0:	85a6                	mv	a1,s1
    80003ea2:	b7d1                	j	80003e66 <namex+0x122>

0000000080003ea4 <dirlink>:
{
    80003ea4:	7139                	addi	sp,sp,-64
    80003ea6:	fc06                	sd	ra,56(sp)
    80003ea8:	f822                	sd	s0,48(sp)
    80003eaa:	f426                	sd	s1,40(sp)
    80003eac:	f04a                	sd	s2,32(sp)
    80003eae:	ec4e                	sd	s3,24(sp)
    80003eb0:	e852                	sd	s4,16(sp)
    80003eb2:	0080                	addi	s0,sp,64
    80003eb4:	892a                	mv	s2,a0
    80003eb6:	8a2e                	mv	s4,a1
    80003eb8:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003eba:	4601                	li	a2,0
    80003ebc:	00000097          	auipc	ra,0x0
    80003ec0:	dd8080e7          	jalr	-552(ra) # 80003c94 <dirlookup>
    80003ec4:	e93d                	bnez	a0,80003f3a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ec6:	04c92483          	lw	s1,76(s2)
    80003eca:	c49d                	beqz	s1,80003ef8 <dirlink+0x54>
    80003ecc:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ece:	4741                	li	a4,16
    80003ed0:	86a6                	mv	a3,s1
    80003ed2:	fc040613          	addi	a2,s0,-64
    80003ed6:	4581                	li	a1,0
    80003ed8:	854a                	mv	a0,s2
    80003eda:	00000097          	auipc	ra,0x0
    80003ede:	b8a080e7          	jalr	-1142(ra) # 80003a64 <readi>
    80003ee2:	47c1                	li	a5,16
    80003ee4:	06f51163          	bne	a0,a5,80003f46 <dirlink+0xa2>
    if(de.inum == 0)
    80003ee8:	fc045783          	lhu	a5,-64(s0)
    80003eec:	c791                	beqz	a5,80003ef8 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eee:	24c1                	addiw	s1,s1,16
    80003ef0:	04c92783          	lw	a5,76(s2)
    80003ef4:	fcf4ede3          	bltu	s1,a5,80003ece <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003ef8:	4639                	li	a2,14
    80003efa:	85d2                	mv	a1,s4
    80003efc:	fc240513          	addi	a0,s0,-62
    80003f00:	ffffd097          	auipc	ra,0xffffd
    80003f04:	efa080e7          	jalr	-262(ra) # 80000dfa <strncpy>
  de.inum = inum;
    80003f08:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f0c:	4741                	li	a4,16
    80003f0e:	86a6                	mv	a3,s1
    80003f10:	fc040613          	addi	a2,s0,-64
    80003f14:	4581                	li	a1,0
    80003f16:	854a                	mv	a0,s2
    80003f18:	00000097          	auipc	ra,0x0
    80003f1c:	c44080e7          	jalr	-956(ra) # 80003b5c <writei>
    80003f20:	1541                	addi	a0,a0,-16
    80003f22:	00a03533          	snez	a0,a0
    80003f26:	40a00533          	neg	a0,a0
}
    80003f2a:	70e2                	ld	ra,56(sp)
    80003f2c:	7442                	ld	s0,48(sp)
    80003f2e:	74a2                	ld	s1,40(sp)
    80003f30:	7902                	ld	s2,32(sp)
    80003f32:	69e2                	ld	s3,24(sp)
    80003f34:	6a42                	ld	s4,16(sp)
    80003f36:	6121                	addi	sp,sp,64
    80003f38:	8082                	ret
    iput(ip);
    80003f3a:	00000097          	auipc	ra,0x0
    80003f3e:	a30080e7          	jalr	-1488(ra) # 8000396a <iput>
    return -1;
    80003f42:	557d                	li	a0,-1
    80003f44:	b7dd                	j	80003f2a <dirlink+0x86>
      panic("dirlink read");
    80003f46:	00004517          	auipc	a0,0x4
    80003f4a:	7d250513          	addi	a0,a0,2002 # 80008718 <syscalls+0x1e8>
    80003f4e:	ffffc097          	auipc	ra,0xffffc
    80003f52:	5f6080e7          	jalr	1526(ra) # 80000544 <panic>

0000000080003f56 <namei>:

struct inode*
namei(char *path)
{
    80003f56:	1101                	addi	sp,sp,-32
    80003f58:	ec06                	sd	ra,24(sp)
    80003f5a:	e822                	sd	s0,16(sp)
    80003f5c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f5e:	fe040613          	addi	a2,s0,-32
    80003f62:	4581                	li	a1,0
    80003f64:	00000097          	auipc	ra,0x0
    80003f68:	de0080e7          	jalr	-544(ra) # 80003d44 <namex>
}
    80003f6c:	60e2                	ld	ra,24(sp)
    80003f6e:	6442                	ld	s0,16(sp)
    80003f70:	6105                	addi	sp,sp,32
    80003f72:	8082                	ret

0000000080003f74 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f74:	1141                	addi	sp,sp,-16
    80003f76:	e406                	sd	ra,8(sp)
    80003f78:	e022                	sd	s0,0(sp)
    80003f7a:	0800                	addi	s0,sp,16
    80003f7c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f7e:	4585                	li	a1,1
    80003f80:	00000097          	auipc	ra,0x0
    80003f84:	dc4080e7          	jalr	-572(ra) # 80003d44 <namex>
}
    80003f88:	60a2                	ld	ra,8(sp)
    80003f8a:	6402                	ld	s0,0(sp)
    80003f8c:	0141                	addi	sp,sp,16
    80003f8e:	8082                	ret

0000000080003f90 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f90:	1101                	addi	sp,sp,-32
    80003f92:	ec06                	sd	ra,24(sp)
    80003f94:	e822                	sd	s0,16(sp)
    80003f96:	e426                	sd	s1,8(sp)
    80003f98:	e04a                	sd	s2,0(sp)
    80003f9a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f9c:	0001d917          	auipc	s2,0x1d
    80003fa0:	55490913          	addi	s2,s2,1364 # 800214f0 <log>
    80003fa4:	01892583          	lw	a1,24(s2)
    80003fa8:	02892503          	lw	a0,40(s2)
    80003fac:	fffff097          	auipc	ra,0xfffff
    80003fb0:	fea080e7          	jalr	-22(ra) # 80002f96 <bread>
    80003fb4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fb6:	02c92683          	lw	a3,44(s2)
    80003fba:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fbc:	02d05763          	blez	a3,80003fea <write_head+0x5a>
    80003fc0:	0001d797          	auipc	a5,0x1d
    80003fc4:	56078793          	addi	a5,a5,1376 # 80021520 <log+0x30>
    80003fc8:	05c50713          	addi	a4,a0,92
    80003fcc:	36fd                	addiw	a3,a3,-1
    80003fce:	1682                	slli	a3,a3,0x20
    80003fd0:	9281                	srli	a3,a3,0x20
    80003fd2:	068a                	slli	a3,a3,0x2
    80003fd4:	0001d617          	auipc	a2,0x1d
    80003fd8:	55060613          	addi	a2,a2,1360 # 80021524 <log+0x34>
    80003fdc:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003fde:	4390                	lw	a2,0(a5)
    80003fe0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fe2:	0791                	addi	a5,a5,4
    80003fe4:	0711                	addi	a4,a4,4
    80003fe6:	fed79ce3          	bne	a5,a3,80003fde <write_head+0x4e>
  }
  bwrite(buf);
    80003fea:	8526                	mv	a0,s1
    80003fec:	fffff097          	auipc	ra,0xfffff
    80003ff0:	09c080e7          	jalr	156(ra) # 80003088 <bwrite>
  brelse(buf);
    80003ff4:	8526                	mv	a0,s1
    80003ff6:	fffff097          	auipc	ra,0xfffff
    80003ffa:	0d0080e7          	jalr	208(ra) # 800030c6 <brelse>
}
    80003ffe:	60e2                	ld	ra,24(sp)
    80004000:	6442                	ld	s0,16(sp)
    80004002:	64a2                	ld	s1,8(sp)
    80004004:	6902                	ld	s2,0(sp)
    80004006:	6105                	addi	sp,sp,32
    80004008:	8082                	ret

000000008000400a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000400a:	0001d797          	auipc	a5,0x1d
    8000400e:	5127a783          	lw	a5,1298(a5) # 8002151c <log+0x2c>
    80004012:	0af05d63          	blez	a5,800040cc <install_trans+0xc2>
{
    80004016:	7139                	addi	sp,sp,-64
    80004018:	fc06                	sd	ra,56(sp)
    8000401a:	f822                	sd	s0,48(sp)
    8000401c:	f426                	sd	s1,40(sp)
    8000401e:	f04a                	sd	s2,32(sp)
    80004020:	ec4e                	sd	s3,24(sp)
    80004022:	e852                	sd	s4,16(sp)
    80004024:	e456                	sd	s5,8(sp)
    80004026:	e05a                	sd	s6,0(sp)
    80004028:	0080                	addi	s0,sp,64
    8000402a:	8b2a                	mv	s6,a0
    8000402c:	0001da97          	auipc	s5,0x1d
    80004030:	4f4a8a93          	addi	s5,s5,1268 # 80021520 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004034:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004036:	0001d997          	auipc	s3,0x1d
    8000403a:	4ba98993          	addi	s3,s3,1210 # 800214f0 <log>
    8000403e:	a035                	j	8000406a <install_trans+0x60>
      bunpin(dbuf);
    80004040:	8526                	mv	a0,s1
    80004042:	fffff097          	auipc	ra,0xfffff
    80004046:	15e080e7          	jalr	350(ra) # 800031a0 <bunpin>
    brelse(lbuf);
    8000404a:	854a                	mv	a0,s2
    8000404c:	fffff097          	auipc	ra,0xfffff
    80004050:	07a080e7          	jalr	122(ra) # 800030c6 <brelse>
    brelse(dbuf);
    80004054:	8526                	mv	a0,s1
    80004056:	fffff097          	auipc	ra,0xfffff
    8000405a:	070080e7          	jalr	112(ra) # 800030c6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000405e:	2a05                	addiw	s4,s4,1
    80004060:	0a91                	addi	s5,s5,4
    80004062:	02c9a783          	lw	a5,44(s3)
    80004066:	04fa5963          	bge	s4,a5,800040b8 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000406a:	0189a583          	lw	a1,24(s3)
    8000406e:	014585bb          	addw	a1,a1,s4
    80004072:	2585                	addiw	a1,a1,1
    80004074:	0289a503          	lw	a0,40(s3)
    80004078:	fffff097          	auipc	ra,0xfffff
    8000407c:	f1e080e7          	jalr	-226(ra) # 80002f96 <bread>
    80004080:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004082:	000aa583          	lw	a1,0(s5)
    80004086:	0289a503          	lw	a0,40(s3)
    8000408a:	fffff097          	auipc	ra,0xfffff
    8000408e:	f0c080e7          	jalr	-244(ra) # 80002f96 <bread>
    80004092:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004094:	40000613          	li	a2,1024
    80004098:	05890593          	addi	a1,s2,88
    8000409c:	05850513          	addi	a0,a0,88
    800040a0:	ffffd097          	auipc	ra,0xffffd
    800040a4:	ca6080e7          	jalr	-858(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    800040a8:	8526                	mv	a0,s1
    800040aa:	fffff097          	auipc	ra,0xfffff
    800040ae:	fde080e7          	jalr	-34(ra) # 80003088 <bwrite>
    if(recovering == 0)
    800040b2:	f80b1ce3          	bnez	s6,8000404a <install_trans+0x40>
    800040b6:	b769                	j	80004040 <install_trans+0x36>
}
    800040b8:	70e2                	ld	ra,56(sp)
    800040ba:	7442                	ld	s0,48(sp)
    800040bc:	74a2                	ld	s1,40(sp)
    800040be:	7902                	ld	s2,32(sp)
    800040c0:	69e2                	ld	s3,24(sp)
    800040c2:	6a42                	ld	s4,16(sp)
    800040c4:	6aa2                	ld	s5,8(sp)
    800040c6:	6b02                	ld	s6,0(sp)
    800040c8:	6121                	addi	sp,sp,64
    800040ca:	8082                	ret
    800040cc:	8082                	ret

00000000800040ce <initlog>:
{
    800040ce:	7179                	addi	sp,sp,-48
    800040d0:	f406                	sd	ra,40(sp)
    800040d2:	f022                	sd	s0,32(sp)
    800040d4:	ec26                	sd	s1,24(sp)
    800040d6:	e84a                	sd	s2,16(sp)
    800040d8:	e44e                	sd	s3,8(sp)
    800040da:	1800                	addi	s0,sp,48
    800040dc:	892a                	mv	s2,a0
    800040de:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040e0:	0001d497          	auipc	s1,0x1d
    800040e4:	41048493          	addi	s1,s1,1040 # 800214f0 <log>
    800040e8:	00004597          	auipc	a1,0x4
    800040ec:	64058593          	addi	a1,a1,1600 # 80008728 <syscalls+0x1f8>
    800040f0:	8526                	mv	a0,s1
    800040f2:	ffffd097          	auipc	ra,0xffffd
    800040f6:	a68080e7          	jalr	-1432(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    800040fa:	0149a583          	lw	a1,20(s3)
    800040fe:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004100:	0109a783          	lw	a5,16(s3)
    80004104:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004106:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000410a:	854a                	mv	a0,s2
    8000410c:	fffff097          	auipc	ra,0xfffff
    80004110:	e8a080e7          	jalr	-374(ra) # 80002f96 <bread>
  log.lh.n = lh->n;
    80004114:	4d3c                	lw	a5,88(a0)
    80004116:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004118:	02f05563          	blez	a5,80004142 <initlog+0x74>
    8000411c:	05c50713          	addi	a4,a0,92
    80004120:	0001d697          	auipc	a3,0x1d
    80004124:	40068693          	addi	a3,a3,1024 # 80021520 <log+0x30>
    80004128:	37fd                	addiw	a5,a5,-1
    8000412a:	1782                	slli	a5,a5,0x20
    8000412c:	9381                	srli	a5,a5,0x20
    8000412e:	078a                	slli	a5,a5,0x2
    80004130:	06050613          	addi	a2,a0,96
    80004134:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004136:	4310                	lw	a2,0(a4)
    80004138:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000413a:	0711                	addi	a4,a4,4
    8000413c:	0691                	addi	a3,a3,4
    8000413e:	fef71ce3          	bne	a4,a5,80004136 <initlog+0x68>
  brelse(buf);
    80004142:	fffff097          	auipc	ra,0xfffff
    80004146:	f84080e7          	jalr	-124(ra) # 800030c6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000414a:	4505                	li	a0,1
    8000414c:	00000097          	auipc	ra,0x0
    80004150:	ebe080e7          	jalr	-322(ra) # 8000400a <install_trans>
  log.lh.n = 0;
    80004154:	0001d797          	auipc	a5,0x1d
    80004158:	3c07a423          	sw	zero,968(a5) # 8002151c <log+0x2c>
  write_head(); // clear the log
    8000415c:	00000097          	auipc	ra,0x0
    80004160:	e34080e7          	jalr	-460(ra) # 80003f90 <write_head>
}
    80004164:	70a2                	ld	ra,40(sp)
    80004166:	7402                	ld	s0,32(sp)
    80004168:	64e2                	ld	s1,24(sp)
    8000416a:	6942                	ld	s2,16(sp)
    8000416c:	69a2                	ld	s3,8(sp)
    8000416e:	6145                	addi	sp,sp,48
    80004170:	8082                	ret

0000000080004172 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004172:	1101                	addi	sp,sp,-32
    80004174:	ec06                	sd	ra,24(sp)
    80004176:	e822                	sd	s0,16(sp)
    80004178:	e426                	sd	s1,8(sp)
    8000417a:	e04a                	sd	s2,0(sp)
    8000417c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000417e:	0001d517          	auipc	a0,0x1d
    80004182:	37250513          	addi	a0,a0,882 # 800214f0 <log>
    80004186:	ffffd097          	auipc	ra,0xffffd
    8000418a:	a64080e7          	jalr	-1436(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    8000418e:	0001d497          	auipc	s1,0x1d
    80004192:	36248493          	addi	s1,s1,866 # 800214f0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004196:	4979                	li	s2,30
    80004198:	a039                	j	800041a6 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000419a:	85a6                	mv	a1,s1
    8000419c:	8526                	mv	a0,s1
    8000419e:	ffffe097          	auipc	ra,0xffffe
    800041a2:	ed4080e7          	jalr	-300(ra) # 80002072 <sleep>
    if(log.committing){
    800041a6:	50dc                	lw	a5,36(s1)
    800041a8:	fbed                	bnez	a5,8000419a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041aa:	509c                	lw	a5,32(s1)
    800041ac:	0017871b          	addiw	a4,a5,1
    800041b0:	0007069b          	sext.w	a3,a4
    800041b4:	0027179b          	slliw	a5,a4,0x2
    800041b8:	9fb9                	addw	a5,a5,a4
    800041ba:	0017979b          	slliw	a5,a5,0x1
    800041be:	54d8                	lw	a4,44(s1)
    800041c0:	9fb9                	addw	a5,a5,a4
    800041c2:	00f95963          	bge	s2,a5,800041d4 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041c6:	85a6                	mv	a1,s1
    800041c8:	8526                	mv	a0,s1
    800041ca:	ffffe097          	auipc	ra,0xffffe
    800041ce:	ea8080e7          	jalr	-344(ra) # 80002072 <sleep>
    800041d2:	bfd1                	j	800041a6 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041d4:	0001d517          	auipc	a0,0x1d
    800041d8:	31c50513          	addi	a0,a0,796 # 800214f0 <log>
    800041dc:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041de:	ffffd097          	auipc	ra,0xffffd
    800041e2:	ac0080e7          	jalr	-1344(ra) # 80000c9e <release>
      break;
    }
  }
}
    800041e6:	60e2                	ld	ra,24(sp)
    800041e8:	6442                	ld	s0,16(sp)
    800041ea:	64a2                	ld	s1,8(sp)
    800041ec:	6902                	ld	s2,0(sp)
    800041ee:	6105                	addi	sp,sp,32
    800041f0:	8082                	ret

00000000800041f2 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041f2:	7139                	addi	sp,sp,-64
    800041f4:	fc06                	sd	ra,56(sp)
    800041f6:	f822                	sd	s0,48(sp)
    800041f8:	f426                	sd	s1,40(sp)
    800041fa:	f04a                	sd	s2,32(sp)
    800041fc:	ec4e                	sd	s3,24(sp)
    800041fe:	e852                	sd	s4,16(sp)
    80004200:	e456                	sd	s5,8(sp)
    80004202:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004204:	0001d497          	auipc	s1,0x1d
    80004208:	2ec48493          	addi	s1,s1,748 # 800214f0 <log>
    8000420c:	8526                	mv	a0,s1
    8000420e:	ffffd097          	auipc	ra,0xffffd
    80004212:	9dc080e7          	jalr	-1572(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    80004216:	509c                	lw	a5,32(s1)
    80004218:	37fd                	addiw	a5,a5,-1
    8000421a:	0007891b          	sext.w	s2,a5
    8000421e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004220:	50dc                	lw	a5,36(s1)
    80004222:	efb9                	bnez	a5,80004280 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004224:	06091663          	bnez	s2,80004290 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004228:	0001d497          	auipc	s1,0x1d
    8000422c:	2c848493          	addi	s1,s1,712 # 800214f0 <log>
    80004230:	4785                	li	a5,1
    80004232:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004234:	8526                	mv	a0,s1
    80004236:	ffffd097          	auipc	ra,0xffffd
    8000423a:	a68080e7          	jalr	-1432(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000423e:	54dc                	lw	a5,44(s1)
    80004240:	06f04763          	bgtz	a5,800042ae <end_op+0xbc>
    acquire(&log.lock);
    80004244:	0001d497          	auipc	s1,0x1d
    80004248:	2ac48493          	addi	s1,s1,684 # 800214f0 <log>
    8000424c:	8526                	mv	a0,s1
    8000424e:	ffffd097          	auipc	ra,0xffffd
    80004252:	99c080e7          	jalr	-1636(ra) # 80000bea <acquire>
    log.committing = 0;
    80004256:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000425a:	8526                	mv	a0,s1
    8000425c:	ffffe097          	auipc	ra,0xffffe
    80004260:	e7a080e7          	jalr	-390(ra) # 800020d6 <wakeup>
    release(&log.lock);
    80004264:	8526                	mv	a0,s1
    80004266:	ffffd097          	auipc	ra,0xffffd
    8000426a:	a38080e7          	jalr	-1480(ra) # 80000c9e <release>
}
    8000426e:	70e2                	ld	ra,56(sp)
    80004270:	7442                	ld	s0,48(sp)
    80004272:	74a2                	ld	s1,40(sp)
    80004274:	7902                	ld	s2,32(sp)
    80004276:	69e2                	ld	s3,24(sp)
    80004278:	6a42                	ld	s4,16(sp)
    8000427a:	6aa2                	ld	s5,8(sp)
    8000427c:	6121                	addi	sp,sp,64
    8000427e:	8082                	ret
    panic("log.committing");
    80004280:	00004517          	auipc	a0,0x4
    80004284:	4b050513          	addi	a0,a0,1200 # 80008730 <syscalls+0x200>
    80004288:	ffffc097          	auipc	ra,0xffffc
    8000428c:	2bc080e7          	jalr	700(ra) # 80000544 <panic>
    wakeup(&log);
    80004290:	0001d497          	auipc	s1,0x1d
    80004294:	26048493          	addi	s1,s1,608 # 800214f0 <log>
    80004298:	8526                	mv	a0,s1
    8000429a:	ffffe097          	auipc	ra,0xffffe
    8000429e:	e3c080e7          	jalr	-452(ra) # 800020d6 <wakeup>
  release(&log.lock);
    800042a2:	8526                	mv	a0,s1
    800042a4:	ffffd097          	auipc	ra,0xffffd
    800042a8:	9fa080e7          	jalr	-1542(ra) # 80000c9e <release>
  if(do_commit){
    800042ac:	b7c9                	j	8000426e <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042ae:	0001da97          	auipc	s5,0x1d
    800042b2:	272a8a93          	addi	s5,s5,626 # 80021520 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042b6:	0001da17          	auipc	s4,0x1d
    800042ba:	23aa0a13          	addi	s4,s4,570 # 800214f0 <log>
    800042be:	018a2583          	lw	a1,24(s4)
    800042c2:	012585bb          	addw	a1,a1,s2
    800042c6:	2585                	addiw	a1,a1,1
    800042c8:	028a2503          	lw	a0,40(s4)
    800042cc:	fffff097          	auipc	ra,0xfffff
    800042d0:	cca080e7          	jalr	-822(ra) # 80002f96 <bread>
    800042d4:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042d6:	000aa583          	lw	a1,0(s5)
    800042da:	028a2503          	lw	a0,40(s4)
    800042de:	fffff097          	auipc	ra,0xfffff
    800042e2:	cb8080e7          	jalr	-840(ra) # 80002f96 <bread>
    800042e6:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042e8:	40000613          	li	a2,1024
    800042ec:	05850593          	addi	a1,a0,88
    800042f0:	05848513          	addi	a0,s1,88
    800042f4:	ffffd097          	auipc	ra,0xffffd
    800042f8:	a52080e7          	jalr	-1454(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    800042fc:	8526                	mv	a0,s1
    800042fe:	fffff097          	auipc	ra,0xfffff
    80004302:	d8a080e7          	jalr	-630(ra) # 80003088 <bwrite>
    brelse(from);
    80004306:	854e                	mv	a0,s3
    80004308:	fffff097          	auipc	ra,0xfffff
    8000430c:	dbe080e7          	jalr	-578(ra) # 800030c6 <brelse>
    brelse(to);
    80004310:	8526                	mv	a0,s1
    80004312:	fffff097          	auipc	ra,0xfffff
    80004316:	db4080e7          	jalr	-588(ra) # 800030c6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000431a:	2905                	addiw	s2,s2,1
    8000431c:	0a91                	addi	s5,s5,4
    8000431e:	02ca2783          	lw	a5,44(s4)
    80004322:	f8f94ee3          	blt	s2,a5,800042be <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004326:	00000097          	auipc	ra,0x0
    8000432a:	c6a080e7          	jalr	-918(ra) # 80003f90 <write_head>
    install_trans(0); // Now install writes to home locations
    8000432e:	4501                	li	a0,0
    80004330:	00000097          	auipc	ra,0x0
    80004334:	cda080e7          	jalr	-806(ra) # 8000400a <install_trans>
    log.lh.n = 0;
    80004338:	0001d797          	auipc	a5,0x1d
    8000433c:	1e07a223          	sw	zero,484(a5) # 8002151c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004340:	00000097          	auipc	ra,0x0
    80004344:	c50080e7          	jalr	-944(ra) # 80003f90 <write_head>
    80004348:	bdf5                	j	80004244 <end_op+0x52>

000000008000434a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000434a:	1101                	addi	sp,sp,-32
    8000434c:	ec06                	sd	ra,24(sp)
    8000434e:	e822                	sd	s0,16(sp)
    80004350:	e426                	sd	s1,8(sp)
    80004352:	e04a                	sd	s2,0(sp)
    80004354:	1000                	addi	s0,sp,32
    80004356:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004358:	0001d917          	auipc	s2,0x1d
    8000435c:	19890913          	addi	s2,s2,408 # 800214f0 <log>
    80004360:	854a                	mv	a0,s2
    80004362:	ffffd097          	auipc	ra,0xffffd
    80004366:	888080e7          	jalr	-1912(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000436a:	02c92603          	lw	a2,44(s2)
    8000436e:	47f5                	li	a5,29
    80004370:	06c7c563          	blt	a5,a2,800043da <log_write+0x90>
    80004374:	0001d797          	auipc	a5,0x1d
    80004378:	1987a783          	lw	a5,408(a5) # 8002150c <log+0x1c>
    8000437c:	37fd                	addiw	a5,a5,-1
    8000437e:	04f65e63          	bge	a2,a5,800043da <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004382:	0001d797          	auipc	a5,0x1d
    80004386:	18e7a783          	lw	a5,398(a5) # 80021510 <log+0x20>
    8000438a:	06f05063          	blez	a5,800043ea <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000438e:	4781                	li	a5,0
    80004390:	06c05563          	blez	a2,800043fa <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004394:	44cc                	lw	a1,12(s1)
    80004396:	0001d717          	auipc	a4,0x1d
    8000439a:	18a70713          	addi	a4,a4,394 # 80021520 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000439e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043a0:	4314                	lw	a3,0(a4)
    800043a2:	04b68c63          	beq	a3,a1,800043fa <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800043a6:	2785                	addiw	a5,a5,1
    800043a8:	0711                	addi	a4,a4,4
    800043aa:	fef61be3          	bne	a2,a5,800043a0 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043ae:	0621                	addi	a2,a2,8
    800043b0:	060a                	slli	a2,a2,0x2
    800043b2:	0001d797          	auipc	a5,0x1d
    800043b6:	13e78793          	addi	a5,a5,318 # 800214f0 <log>
    800043ba:	963e                	add	a2,a2,a5
    800043bc:	44dc                	lw	a5,12(s1)
    800043be:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043c0:	8526                	mv	a0,s1
    800043c2:	fffff097          	auipc	ra,0xfffff
    800043c6:	da2080e7          	jalr	-606(ra) # 80003164 <bpin>
    log.lh.n++;
    800043ca:	0001d717          	auipc	a4,0x1d
    800043ce:	12670713          	addi	a4,a4,294 # 800214f0 <log>
    800043d2:	575c                	lw	a5,44(a4)
    800043d4:	2785                	addiw	a5,a5,1
    800043d6:	d75c                	sw	a5,44(a4)
    800043d8:	a835                	j	80004414 <log_write+0xca>
    panic("too big a transaction");
    800043da:	00004517          	auipc	a0,0x4
    800043de:	36650513          	addi	a0,a0,870 # 80008740 <syscalls+0x210>
    800043e2:	ffffc097          	auipc	ra,0xffffc
    800043e6:	162080e7          	jalr	354(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    800043ea:	00004517          	auipc	a0,0x4
    800043ee:	36e50513          	addi	a0,a0,878 # 80008758 <syscalls+0x228>
    800043f2:	ffffc097          	auipc	ra,0xffffc
    800043f6:	152080e7          	jalr	338(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    800043fa:	00878713          	addi	a4,a5,8
    800043fe:	00271693          	slli	a3,a4,0x2
    80004402:	0001d717          	auipc	a4,0x1d
    80004406:	0ee70713          	addi	a4,a4,238 # 800214f0 <log>
    8000440a:	9736                	add	a4,a4,a3
    8000440c:	44d4                	lw	a3,12(s1)
    8000440e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004410:	faf608e3          	beq	a2,a5,800043c0 <log_write+0x76>
  }
  release(&log.lock);
    80004414:	0001d517          	auipc	a0,0x1d
    80004418:	0dc50513          	addi	a0,a0,220 # 800214f0 <log>
    8000441c:	ffffd097          	auipc	ra,0xffffd
    80004420:	882080e7          	jalr	-1918(ra) # 80000c9e <release>
}
    80004424:	60e2                	ld	ra,24(sp)
    80004426:	6442                	ld	s0,16(sp)
    80004428:	64a2                	ld	s1,8(sp)
    8000442a:	6902                	ld	s2,0(sp)
    8000442c:	6105                	addi	sp,sp,32
    8000442e:	8082                	ret

0000000080004430 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004430:	1101                	addi	sp,sp,-32
    80004432:	ec06                	sd	ra,24(sp)
    80004434:	e822                	sd	s0,16(sp)
    80004436:	e426                	sd	s1,8(sp)
    80004438:	e04a                	sd	s2,0(sp)
    8000443a:	1000                	addi	s0,sp,32
    8000443c:	84aa                	mv	s1,a0
    8000443e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004440:	00004597          	auipc	a1,0x4
    80004444:	33858593          	addi	a1,a1,824 # 80008778 <syscalls+0x248>
    80004448:	0521                	addi	a0,a0,8
    8000444a:	ffffc097          	auipc	ra,0xffffc
    8000444e:	710080e7          	jalr	1808(ra) # 80000b5a <initlock>
  lk->name = name;
    80004452:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004456:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000445a:	0204a423          	sw	zero,40(s1)
}
    8000445e:	60e2                	ld	ra,24(sp)
    80004460:	6442                	ld	s0,16(sp)
    80004462:	64a2                	ld	s1,8(sp)
    80004464:	6902                	ld	s2,0(sp)
    80004466:	6105                	addi	sp,sp,32
    80004468:	8082                	ret

000000008000446a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000446a:	1101                	addi	sp,sp,-32
    8000446c:	ec06                	sd	ra,24(sp)
    8000446e:	e822                	sd	s0,16(sp)
    80004470:	e426                	sd	s1,8(sp)
    80004472:	e04a                	sd	s2,0(sp)
    80004474:	1000                	addi	s0,sp,32
    80004476:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004478:	00850913          	addi	s2,a0,8
    8000447c:	854a                	mv	a0,s2
    8000447e:	ffffc097          	auipc	ra,0xffffc
    80004482:	76c080e7          	jalr	1900(ra) # 80000bea <acquire>
  while (lk->locked) {
    80004486:	409c                	lw	a5,0(s1)
    80004488:	cb89                	beqz	a5,8000449a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000448a:	85ca                	mv	a1,s2
    8000448c:	8526                	mv	a0,s1
    8000448e:	ffffe097          	auipc	ra,0xffffe
    80004492:	be4080e7          	jalr	-1052(ra) # 80002072 <sleep>
  while (lk->locked) {
    80004496:	409c                	lw	a5,0(s1)
    80004498:	fbed                	bnez	a5,8000448a <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000449a:	4785                	li	a5,1
    8000449c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000449e:	ffffd097          	auipc	ra,0xffffd
    800044a2:	528080e7          	jalr	1320(ra) # 800019c6 <myproc>
    800044a6:	591c                	lw	a5,48(a0)
    800044a8:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044aa:	854a                	mv	a0,s2
    800044ac:	ffffc097          	auipc	ra,0xffffc
    800044b0:	7f2080e7          	jalr	2034(ra) # 80000c9e <release>
}
    800044b4:	60e2                	ld	ra,24(sp)
    800044b6:	6442                	ld	s0,16(sp)
    800044b8:	64a2                	ld	s1,8(sp)
    800044ba:	6902                	ld	s2,0(sp)
    800044bc:	6105                	addi	sp,sp,32
    800044be:	8082                	ret

00000000800044c0 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044c0:	1101                	addi	sp,sp,-32
    800044c2:	ec06                	sd	ra,24(sp)
    800044c4:	e822                	sd	s0,16(sp)
    800044c6:	e426                	sd	s1,8(sp)
    800044c8:	e04a                	sd	s2,0(sp)
    800044ca:	1000                	addi	s0,sp,32
    800044cc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044ce:	00850913          	addi	s2,a0,8
    800044d2:	854a                	mv	a0,s2
    800044d4:	ffffc097          	auipc	ra,0xffffc
    800044d8:	716080e7          	jalr	1814(ra) # 80000bea <acquire>
  lk->locked = 0;
    800044dc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044e0:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044e4:	8526                	mv	a0,s1
    800044e6:	ffffe097          	auipc	ra,0xffffe
    800044ea:	bf0080e7          	jalr	-1040(ra) # 800020d6 <wakeup>
  release(&lk->lk);
    800044ee:	854a                	mv	a0,s2
    800044f0:	ffffc097          	auipc	ra,0xffffc
    800044f4:	7ae080e7          	jalr	1966(ra) # 80000c9e <release>
}
    800044f8:	60e2                	ld	ra,24(sp)
    800044fa:	6442                	ld	s0,16(sp)
    800044fc:	64a2                	ld	s1,8(sp)
    800044fe:	6902                	ld	s2,0(sp)
    80004500:	6105                	addi	sp,sp,32
    80004502:	8082                	ret

0000000080004504 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004504:	7179                	addi	sp,sp,-48
    80004506:	f406                	sd	ra,40(sp)
    80004508:	f022                	sd	s0,32(sp)
    8000450a:	ec26                	sd	s1,24(sp)
    8000450c:	e84a                	sd	s2,16(sp)
    8000450e:	e44e                	sd	s3,8(sp)
    80004510:	1800                	addi	s0,sp,48
    80004512:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004514:	00850913          	addi	s2,a0,8
    80004518:	854a                	mv	a0,s2
    8000451a:	ffffc097          	auipc	ra,0xffffc
    8000451e:	6d0080e7          	jalr	1744(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004522:	409c                	lw	a5,0(s1)
    80004524:	ef99                	bnez	a5,80004542 <holdingsleep+0x3e>
    80004526:	4481                	li	s1,0
  release(&lk->lk);
    80004528:	854a                	mv	a0,s2
    8000452a:	ffffc097          	auipc	ra,0xffffc
    8000452e:	774080e7          	jalr	1908(ra) # 80000c9e <release>
  return r;
}
    80004532:	8526                	mv	a0,s1
    80004534:	70a2                	ld	ra,40(sp)
    80004536:	7402                	ld	s0,32(sp)
    80004538:	64e2                	ld	s1,24(sp)
    8000453a:	6942                	ld	s2,16(sp)
    8000453c:	69a2                	ld	s3,8(sp)
    8000453e:	6145                	addi	sp,sp,48
    80004540:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004542:	0284a983          	lw	s3,40(s1)
    80004546:	ffffd097          	auipc	ra,0xffffd
    8000454a:	480080e7          	jalr	1152(ra) # 800019c6 <myproc>
    8000454e:	5904                	lw	s1,48(a0)
    80004550:	413484b3          	sub	s1,s1,s3
    80004554:	0014b493          	seqz	s1,s1
    80004558:	bfc1                	j	80004528 <holdingsleep+0x24>

000000008000455a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000455a:	1141                	addi	sp,sp,-16
    8000455c:	e406                	sd	ra,8(sp)
    8000455e:	e022                	sd	s0,0(sp)
    80004560:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004562:	00004597          	auipc	a1,0x4
    80004566:	22658593          	addi	a1,a1,550 # 80008788 <syscalls+0x258>
    8000456a:	0001d517          	auipc	a0,0x1d
    8000456e:	0ce50513          	addi	a0,a0,206 # 80021638 <ftable>
    80004572:	ffffc097          	auipc	ra,0xffffc
    80004576:	5e8080e7          	jalr	1512(ra) # 80000b5a <initlock>
}
    8000457a:	60a2                	ld	ra,8(sp)
    8000457c:	6402                	ld	s0,0(sp)
    8000457e:	0141                	addi	sp,sp,16
    80004580:	8082                	ret

0000000080004582 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004582:	1101                	addi	sp,sp,-32
    80004584:	ec06                	sd	ra,24(sp)
    80004586:	e822                	sd	s0,16(sp)
    80004588:	e426                	sd	s1,8(sp)
    8000458a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000458c:	0001d517          	auipc	a0,0x1d
    80004590:	0ac50513          	addi	a0,a0,172 # 80021638 <ftable>
    80004594:	ffffc097          	auipc	ra,0xffffc
    80004598:	656080e7          	jalr	1622(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000459c:	0001d497          	auipc	s1,0x1d
    800045a0:	0b448493          	addi	s1,s1,180 # 80021650 <ftable+0x18>
    800045a4:	0001e717          	auipc	a4,0x1e
    800045a8:	04c70713          	addi	a4,a4,76 # 800225f0 <disk>
    if(f->ref == 0){
    800045ac:	40dc                	lw	a5,4(s1)
    800045ae:	cf99                	beqz	a5,800045cc <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045b0:	02848493          	addi	s1,s1,40
    800045b4:	fee49ce3          	bne	s1,a4,800045ac <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045b8:	0001d517          	auipc	a0,0x1d
    800045bc:	08050513          	addi	a0,a0,128 # 80021638 <ftable>
    800045c0:	ffffc097          	auipc	ra,0xffffc
    800045c4:	6de080e7          	jalr	1758(ra) # 80000c9e <release>
  return 0;
    800045c8:	4481                	li	s1,0
    800045ca:	a819                	j	800045e0 <filealloc+0x5e>
      f->ref = 1;
    800045cc:	4785                	li	a5,1
    800045ce:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045d0:	0001d517          	auipc	a0,0x1d
    800045d4:	06850513          	addi	a0,a0,104 # 80021638 <ftable>
    800045d8:	ffffc097          	auipc	ra,0xffffc
    800045dc:	6c6080e7          	jalr	1734(ra) # 80000c9e <release>
}
    800045e0:	8526                	mv	a0,s1
    800045e2:	60e2                	ld	ra,24(sp)
    800045e4:	6442                	ld	s0,16(sp)
    800045e6:	64a2                	ld	s1,8(sp)
    800045e8:	6105                	addi	sp,sp,32
    800045ea:	8082                	ret

00000000800045ec <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045ec:	1101                	addi	sp,sp,-32
    800045ee:	ec06                	sd	ra,24(sp)
    800045f0:	e822                	sd	s0,16(sp)
    800045f2:	e426                	sd	s1,8(sp)
    800045f4:	1000                	addi	s0,sp,32
    800045f6:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045f8:	0001d517          	auipc	a0,0x1d
    800045fc:	04050513          	addi	a0,a0,64 # 80021638 <ftable>
    80004600:	ffffc097          	auipc	ra,0xffffc
    80004604:	5ea080e7          	jalr	1514(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004608:	40dc                	lw	a5,4(s1)
    8000460a:	02f05263          	blez	a5,8000462e <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000460e:	2785                	addiw	a5,a5,1
    80004610:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004612:	0001d517          	auipc	a0,0x1d
    80004616:	02650513          	addi	a0,a0,38 # 80021638 <ftable>
    8000461a:	ffffc097          	auipc	ra,0xffffc
    8000461e:	684080e7          	jalr	1668(ra) # 80000c9e <release>
  return f;
}
    80004622:	8526                	mv	a0,s1
    80004624:	60e2                	ld	ra,24(sp)
    80004626:	6442                	ld	s0,16(sp)
    80004628:	64a2                	ld	s1,8(sp)
    8000462a:	6105                	addi	sp,sp,32
    8000462c:	8082                	ret
    panic("filedup");
    8000462e:	00004517          	auipc	a0,0x4
    80004632:	16250513          	addi	a0,a0,354 # 80008790 <syscalls+0x260>
    80004636:	ffffc097          	auipc	ra,0xffffc
    8000463a:	f0e080e7          	jalr	-242(ra) # 80000544 <panic>

000000008000463e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000463e:	7139                	addi	sp,sp,-64
    80004640:	fc06                	sd	ra,56(sp)
    80004642:	f822                	sd	s0,48(sp)
    80004644:	f426                	sd	s1,40(sp)
    80004646:	f04a                	sd	s2,32(sp)
    80004648:	ec4e                	sd	s3,24(sp)
    8000464a:	e852                	sd	s4,16(sp)
    8000464c:	e456                	sd	s5,8(sp)
    8000464e:	0080                	addi	s0,sp,64
    80004650:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004652:	0001d517          	auipc	a0,0x1d
    80004656:	fe650513          	addi	a0,a0,-26 # 80021638 <ftable>
    8000465a:	ffffc097          	auipc	ra,0xffffc
    8000465e:	590080e7          	jalr	1424(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004662:	40dc                	lw	a5,4(s1)
    80004664:	06f05163          	blez	a5,800046c6 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004668:	37fd                	addiw	a5,a5,-1
    8000466a:	0007871b          	sext.w	a4,a5
    8000466e:	c0dc                	sw	a5,4(s1)
    80004670:	06e04363          	bgtz	a4,800046d6 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004674:	0004a903          	lw	s2,0(s1)
    80004678:	0094ca83          	lbu	s5,9(s1)
    8000467c:	0104ba03          	ld	s4,16(s1)
    80004680:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004684:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004688:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000468c:	0001d517          	auipc	a0,0x1d
    80004690:	fac50513          	addi	a0,a0,-84 # 80021638 <ftable>
    80004694:	ffffc097          	auipc	ra,0xffffc
    80004698:	60a080e7          	jalr	1546(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    8000469c:	4785                	li	a5,1
    8000469e:	04f90d63          	beq	s2,a5,800046f8 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046a2:	3979                	addiw	s2,s2,-2
    800046a4:	4785                	li	a5,1
    800046a6:	0527e063          	bltu	a5,s2,800046e6 <fileclose+0xa8>
    begin_op();
    800046aa:	00000097          	auipc	ra,0x0
    800046ae:	ac8080e7          	jalr	-1336(ra) # 80004172 <begin_op>
    iput(ff.ip);
    800046b2:	854e                	mv	a0,s3
    800046b4:	fffff097          	auipc	ra,0xfffff
    800046b8:	2b6080e7          	jalr	694(ra) # 8000396a <iput>
    end_op();
    800046bc:	00000097          	auipc	ra,0x0
    800046c0:	b36080e7          	jalr	-1226(ra) # 800041f2 <end_op>
    800046c4:	a00d                	j	800046e6 <fileclose+0xa8>
    panic("fileclose");
    800046c6:	00004517          	auipc	a0,0x4
    800046ca:	0d250513          	addi	a0,a0,210 # 80008798 <syscalls+0x268>
    800046ce:	ffffc097          	auipc	ra,0xffffc
    800046d2:	e76080e7          	jalr	-394(ra) # 80000544 <panic>
    release(&ftable.lock);
    800046d6:	0001d517          	auipc	a0,0x1d
    800046da:	f6250513          	addi	a0,a0,-158 # 80021638 <ftable>
    800046de:	ffffc097          	auipc	ra,0xffffc
    800046e2:	5c0080e7          	jalr	1472(ra) # 80000c9e <release>
  }
}
    800046e6:	70e2                	ld	ra,56(sp)
    800046e8:	7442                	ld	s0,48(sp)
    800046ea:	74a2                	ld	s1,40(sp)
    800046ec:	7902                	ld	s2,32(sp)
    800046ee:	69e2                	ld	s3,24(sp)
    800046f0:	6a42                	ld	s4,16(sp)
    800046f2:	6aa2                	ld	s5,8(sp)
    800046f4:	6121                	addi	sp,sp,64
    800046f6:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046f8:	85d6                	mv	a1,s5
    800046fa:	8552                	mv	a0,s4
    800046fc:	00000097          	auipc	ra,0x0
    80004700:	34c080e7          	jalr	844(ra) # 80004a48 <pipeclose>
    80004704:	b7cd                	j	800046e6 <fileclose+0xa8>

0000000080004706 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004706:	715d                	addi	sp,sp,-80
    80004708:	e486                	sd	ra,72(sp)
    8000470a:	e0a2                	sd	s0,64(sp)
    8000470c:	fc26                	sd	s1,56(sp)
    8000470e:	f84a                	sd	s2,48(sp)
    80004710:	f44e                	sd	s3,40(sp)
    80004712:	0880                	addi	s0,sp,80
    80004714:	84aa                	mv	s1,a0
    80004716:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004718:	ffffd097          	auipc	ra,0xffffd
    8000471c:	2ae080e7          	jalr	686(ra) # 800019c6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004720:	409c                	lw	a5,0(s1)
    80004722:	37f9                	addiw	a5,a5,-2
    80004724:	4705                	li	a4,1
    80004726:	04f76763          	bltu	a4,a5,80004774 <filestat+0x6e>
    8000472a:	892a                	mv	s2,a0
    ilock(f->ip);
    8000472c:	6c88                	ld	a0,24(s1)
    8000472e:	fffff097          	auipc	ra,0xfffff
    80004732:	082080e7          	jalr	130(ra) # 800037b0 <ilock>
    stati(f->ip, &st);
    80004736:	fb840593          	addi	a1,s0,-72
    8000473a:	6c88                	ld	a0,24(s1)
    8000473c:	fffff097          	auipc	ra,0xfffff
    80004740:	2fe080e7          	jalr	766(ra) # 80003a3a <stati>
    iunlock(f->ip);
    80004744:	6c88                	ld	a0,24(s1)
    80004746:	fffff097          	auipc	ra,0xfffff
    8000474a:	12c080e7          	jalr	300(ra) # 80003872 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000474e:	46e1                	li	a3,24
    80004750:	fb840613          	addi	a2,s0,-72
    80004754:	85ce                	mv	a1,s3
    80004756:	05093503          	ld	a0,80(s2)
    8000475a:	ffffd097          	auipc	ra,0xffffd
    8000475e:	f2a080e7          	jalr	-214(ra) # 80001684 <copyout>
    80004762:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004766:	60a6                	ld	ra,72(sp)
    80004768:	6406                	ld	s0,64(sp)
    8000476a:	74e2                	ld	s1,56(sp)
    8000476c:	7942                	ld	s2,48(sp)
    8000476e:	79a2                	ld	s3,40(sp)
    80004770:	6161                	addi	sp,sp,80
    80004772:	8082                	ret
  return -1;
    80004774:	557d                	li	a0,-1
    80004776:	bfc5                	j	80004766 <filestat+0x60>

0000000080004778 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004778:	7179                	addi	sp,sp,-48
    8000477a:	f406                	sd	ra,40(sp)
    8000477c:	f022                	sd	s0,32(sp)
    8000477e:	ec26                	sd	s1,24(sp)
    80004780:	e84a                	sd	s2,16(sp)
    80004782:	e44e                	sd	s3,8(sp)
    80004784:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004786:	00854783          	lbu	a5,8(a0)
    8000478a:	c3d5                	beqz	a5,8000482e <fileread+0xb6>
    8000478c:	84aa                	mv	s1,a0
    8000478e:	89ae                	mv	s3,a1
    80004790:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004792:	411c                	lw	a5,0(a0)
    80004794:	4705                	li	a4,1
    80004796:	04e78963          	beq	a5,a4,800047e8 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000479a:	470d                	li	a4,3
    8000479c:	04e78d63          	beq	a5,a4,800047f6 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047a0:	4709                	li	a4,2
    800047a2:	06e79e63          	bne	a5,a4,8000481e <fileread+0xa6>
    ilock(f->ip);
    800047a6:	6d08                	ld	a0,24(a0)
    800047a8:	fffff097          	auipc	ra,0xfffff
    800047ac:	008080e7          	jalr	8(ra) # 800037b0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047b0:	874a                	mv	a4,s2
    800047b2:	5094                	lw	a3,32(s1)
    800047b4:	864e                	mv	a2,s3
    800047b6:	4585                	li	a1,1
    800047b8:	6c88                	ld	a0,24(s1)
    800047ba:	fffff097          	auipc	ra,0xfffff
    800047be:	2aa080e7          	jalr	682(ra) # 80003a64 <readi>
    800047c2:	892a                	mv	s2,a0
    800047c4:	00a05563          	blez	a0,800047ce <fileread+0x56>
      f->off += r;
    800047c8:	509c                	lw	a5,32(s1)
    800047ca:	9fa9                	addw	a5,a5,a0
    800047cc:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047ce:	6c88                	ld	a0,24(s1)
    800047d0:	fffff097          	auipc	ra,0xfffff
    800047d4:	0a2080e7          	jalr	162(ra) # 80003872 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047d8:	854a                	mv	a0,s2
    800047da:	70a2                	ld	ra,40(sp)
    800047dc:	7402                	ld	s0,32(sp)
    800047de:	64e2                	ld	s1,24(sp)
    800047e0:	6942                	ld	s2,16(sp)
    800047e2:	69a2                	ld	s3,8(sp)
    800047e4:	6145                	addi	sp,sp,48
    800047e6:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047e8:	6908                	ld	a0,16(a0)
    800047ea:	00000097          	auipc	ra,0x0
    800047ee:	3ce080e7          	jalr	974(ra) # 80004bb8 <piperead>
    800047f2:	892a                	mv	s2,a0
    800047f4:	b7d5                	j	800047d8 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047f6:	02451783          	lh	a5,36(a0)
    800047fa:	03079693          	slli	a3,a5,0x30
    800047fe:	92c1                	srli	a3,a3,0x30
    80004800:	4725                	li	a4,9
    80004802:	02d76863          	bltu	a4,a3,80004832 <fileread+0xba>
    80004806:	0792                	slli	a5,a5,0x4
    80004808:	0001d717          	auipc	a4,0x1d
    8000480c:	d9070713          	addi	a4,a4,-624 # 80021598 <devsw>
    80004810:	97ba                	add	a5,a5,a4
    80004812:	639c                	ld	a5,0(a5)
    80004814:	c38d                	beqz	a5,80004836 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004816:	4505                	li	a0,1
    80004818:	9782                	jalr	a5
    8000481a:	892a                	mv	s2,a0
    8000481c:	bf75                	j	800047d8 <fileread+0x60>
    panic("fileread");
    8000481e:	00004517          	auipc	a0,0x4
    80004822:	f8a50513          	addi	a0,a0,-118 # 800087a8 <syscalls+0x278>
    80004826:	ffffc097          	auipc	ra,0xffffc
    8000482a:	d1e080e7          	jalr	-738(ra) # 80000544 <panic>
    return -1;
    8000482e:	597d                	li	s2,-1
    80004830:	b765                	j	800047d8 <fileread+0x60>
      return -1;
    80004832:	597d                	li	s2,-1
    80004834:	b755                	j	800047d8 <fileread+0x60>
    80004836:	597d                	li	s2,-1
    80004838:	b745                	j	800047d8 <fileread+0x60>

000000008000483a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000483a:	715d                	addi	sp,sp,-80
    8000483c:	e486                	sd	ra,72(sp)
    8000483e:	e0a2                	sd	s0,64(sp)
    80004840:	fc26                	sd	s1,56(sp)
    80004842:	f84a                	sd	s2,48(sp)
    80004844:	f44e                	sd	s3,40(sp)
    80004846:	f052                	sd	s4,32(sp)
    80004848:	ec56                	sd	s5,24(sp)
    8000484a:	e85a                	sd	s6,16(sp)
    8000484c:	e45e                	sd	s7,8(sp)
    8000484e:	e062                	sd	s8,0(sp)
    80004850:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004852:	00954783          	lbu	a5,9(a0)
    80004856:	10078663          	beqz	a5,80004962 <filewrite+0x128>
    8000485a:	892a                	mv	s2,a0
    8000485c:	8aae                	mv	s5,a1
    8000485e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004860:	411c                	lw	a5,0(a0)
    80004862:	4705                	li	a4,1
    80004864:	02e78263          	beq	a5,a4,80004888 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004868:	470d                	li	a4,3
    8000486a:	02e78663          	beq	a5,a4,80004896 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000486e:	4709                	li	a4,2
    80004870:	0ee79163          	bne	a5,a4,80004952 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004874:	0ac05d63          	blez	a2,8000492e <filewrite+0xf4>
    int i = 0;
    80004878:	4981                	li	s3,0
    8000487a:	6b05                	lui	s6,0x1
    8000487c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004880:	6b85                	lui	s7,0x1
    80004882:	c00b8b9b          	addiw	s7,s7,-1024
    80004886:	a861                	j	8000491e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004888:	6908                	ld	a0,16(a0)
    8000488a:	00000097          	auipc	ra,0x0
    8000488e:	22e080e7          	jalr	558(ra) # 80004ab8 <pipewrite>
    80004892:	8a2a                	mv	s4,a0
    80004894:	a045                	j	80004934 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004896:	02451783          	lh	a5,36(a0)
    8000489a:	03079693          	slli	a3,a5,0x30
    8000489e:	92c1                	srli	a3,a3,0x30
    800048a0:	4725                	li	a4,9
    800048a2:	0cd76263          	bltu	a4,a3,80004966 <filewrite+0x12c>
    800048a6:	0792                	slli	a5,a5,0x4
    800048a8:	0001d717          	auipc	a4,0x1d
    800048ac:	cf070713          	addi	a4,a4,-784 # 80021598 <devsw>
    800048b0:	97ba                	add	a5,a5,a4
    800048b2:	679c                	ld	a5,8(a5)
    800048b4:	cbdd                	beqz	a5,8000496a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800048b6:	4505                	li	a0,1
    800048b8:	9782                	jalr	a5
    800048ba:	8a2a                	mv	s4,a0
    800048bc:	a8a5                	j	80004934 <filewrite+0xfa>
    800048be:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048c2:	00000097          	auipc	ra,0x0
    800048c6:	8b0080e7          	jalr	-1872(ra) # 80004172 <begin_op>
      ilock(f->ip);
    800048ca:	01893503          	ld	a0,24(s2)
    800048ce:	fffff097          	auipc	ra,0xfffff
    800048d2:	ee2080e7          	jalr	-286(ra) # 800037b0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048d6:	8762                	mv	a4,s8
    800048d8:	02092683          	lw	a3,32(s2)
    800048dc:	01598633          	add	a2,s3,s5
    800048e0:	4585                	li	a1,1
    800048e2:	01893503          	ld	a0,24(s2)
    800048e6:	fffff097          	auipc	ra,0xfffff
    800048ea:	276080e7          	jalr	630(ra) # 80003b5c <writei>
    800048ee:	84aa                	mv	s1,a0
    800048f0:	00a05763          	blez	a0,800048fe <filewrite+0xc4>
        f->off += r;
    800048f4:	02092783          	lw	a5,32(s2)
    800048f8:	9fa9                	addw	a5,a5,a0
    800048fa:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800048fe:	01893503          	ld	a0,24(s2)
    80004902:	fffff097          	auipc	ra,0xfffff
    80004906:	f70080e7          	jalr	-144(ra) # 80003872 <iunlock>
      end_op();
    8000490a:	00000097          	auipc	ra,0x0
    8000490e:	8e8080e7          	jalr	-1816(ra) # 800041f2 <end_op>

      if(r != n1){
    80004912:	009c1f63          	bne	s8,s1,80004930 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004916:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000491a:	0149db63          	bge	s3,s4,80004930 <filewrite+0xf6>
      int n1 = n - i;
    8000491e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004922:	84be                	mv	s1,a5
    80004924:	2781                	sext.w	a5,a5
    80004926:	f8fb5ce3          	bge	s6,a5,800048be <filewrite+0x84>
    8000492a:	84de                	mv	s1,s7
    8000492c:	bf49                	j	800048be <filewrite+0x84>
    int i = 0;
    8000492e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004930:	013a1f63          	bne	s4,s3,8000494e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004934:	8552                	mv	a0,s4
    80004936:	60a6                	ld	ra,72(sp)
    80004938:	6406                	ld	s0,64(sp)
    8000493a:	74e2                	ld	s1,56(sp)
    8000493c:	7942                	ld	s2,48(sp)
    8000493e:	79a2                	ld	s3,40(sp)
    80004940:	7a02                	ld	s4,32(sp)
    80004942:	6ae2                	ld	s5,24(sp)
    80004944:	6b42                	ld	s6,16(sp)
    80004946:	6ba2                	ld	s7,8(sp)
    80004948:	6c02                	ld	s8,0(sp)
    8000494a:	6161                	addi	sp,sp,80
    8000494c:	8082                	ret
    ret = (i == n ? n : -1);
    8000494e:	5a7d                	li	s4,-1
    80004950:	b7d5                	j	80004934 <filewrite+0xfa>
    panic("filewrite");
    80004952:	00004517          	auipc	a0,0x4
    80004956:	e6650513          	addi	a0,a0,-410 # 800087b8 <syscalls+0x288>
    8000495a:	ffffc097          	auipc	ra,0xffffc
    8000495e:	bea080e7          	jalr	-1046(ra) # 80000544 <panic>
    return -1;
    80004962:	5a7d                	li	s4,-1
    80004964:	bfc1                	j	80004934 <filewrite+0xfa>
      return -1;
    80004966:	5a7d                	li	s4,-1
    80004968:	b7f1                	j	80004934 <filewrite+0xfa>
    8000496a:	5a7d                	li	s4,-1
    8000496c:	b7e1                	j	80004934 <filewrite+0xfa>

000000008000496e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000496e:	7179                	addi	sp,sp,-48
    80004970:	f406                	sd	ra,40(sp)
    80004972:	f022                	sd	s0,32(sp)
    80004974:	ec26                	sd	s1,24(sp)
    80004976:	e84a                	sd	s2,16(sp)
    80004978:	e44e                	sd	s3,8(sp)
    8000497a:	e052                	sd	s4,0(sp)
    8000497c:	1800                	addi	s0,sp,48
    8000497e:	84aa                	mv	s1,a0
    80004980:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004982:	0005b023          	sd	zero,0(a1)
    80004986:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000498a:	00000097          	auipc	ra,0x0
    8000498e:	bf8080e7          	jalr	-1032(ra) # 80004582 <filealloc>
    80004992:	e088                	sd	a0,0(s1)
    80004994:	c551                	beqz	a0,80004a20 <pipealloc+0xb2>
    80004996:	00000097          	auipc	ra,0x0
    8000499a:	bec080e7          	jalr	-1044(ra) # 80004582 <filealloc>
    8000499e:	00aa3023          	sd	a0,0(s4)
    800049a2:	c92d                	beqz	a0,80004a14 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049a4:	ffffc097          	auipc	ra,0xffffc
    800049a8:	156080e7          	jalr	342(ra) # 80000afa <kalloc>
    800049ac:	892a                	mv	s2,a0
    800049ae:	c125                	beqz	a0,80004a0e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049b0:	4985                	li	s3,1
    800049b2:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049b6:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049ba:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049be:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049c2:	00004597          	auipc	a1,0x4
    800049c6:	aa658593          	addi	a1,a1,-1370 # 80008468 <states.1727+0x1a0>
    800049ca:	ffffc097          	auipc	ra,0xffffc
    800049ce:	190080e7          	jalr	400(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    800049d2:	609c                	ld	a5,0(s1)
    800049d4:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049d8:	609c                	ld	a5,0(s1)
    800049da:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049de:	609c                	ld	a5,0(s1)
    800049e0:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049e4:	609c                	ld	a5,0(s1)
    800049e6:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049ea:	000a3783          	ld	a5,0(s4)
    800049ee:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049f2:	000a3783          	ld	a5,0(s4)
    800049f6:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049fa:	000a3783          	ld	a5,0(s4)
    800049fe:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a02:	000a3783          	ld	a5,0(s4)
    80004a06:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a0a:	4501                	li	a0,0
    80004a0c:	a025                	j	80004a34 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a0e:	6088                	ld	a0,0(s1)
    80004a10:	e501                	bnez	a0,80004a18 <pipealloc+0xaa>
    80004a12:	a039                	j	80004a20 <pipealloc+0xb2>
    80004a14:	6088                	ld	a0,0(s1)
    80004a16:	c51d                	beqz	a0,80004a44 <pipealloc+0xd6>
    fileclose(*f0);
    80004a18:	00000097          	auipc	ra,0x0
    80004a1c:	c26080e7          	jalr	-986(ra) # 8000463e <fileclose>
  if(*f1)
    80004a20:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a24:	557d                	li	a0,-1
  if(*f1)
    80004a26:	c799                	beqz	a5,80004a34 <pipealloc+0xc6>
    fileclose(*f1);
    80004a28:	853e                	mv	a0,a5
    80004a2a:	00000097          	auipc	ra,0x0
    80004a2e:	c14080e7          	jalr	-1004(ra) # 8000463e <fileclose>
  return -1;
    80004a32:	557d                	li	a0,-1
}
    80004a34:	70a2                	ld	ra,40(sp)
    80004a36:	7402                	ld	s0,32(sp)
    80004a38:	64e2                	ld	s1,24(sp)
    80004a3a:	6942                	ld	s2,16(sp)
    80004a3c:	69a2                	ld	s3,8(sp)
    80004a3e:	6a02                	ld	s4,0(sp)
    80004a40:	6145                	addi	sp,sp,48
    80004a42:	8082                	ret
  return -1;
    80004a44:	557d                	li	a0,-1
    80004a46:	b7fd                	j	80004a34 <pipealloc+0xc6>

0000000080004a48 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a48:	1101                	addi	sp,sp,-32
    80004a4a:	ec06                	sd	ra,24(sp)
    80004a4c:	e822                	sd	s0,16(sp)
    80004a4e:	e426                	sd	s1,8(sp)
    80004a50:	e04a                	sd	s2,0(sp)
    80004a52:	1000                	addi	s0,sp,32
    80004a54:	84aa                	mv	s1,a0
    80004a56:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a58:	ffffc097          	auipc	ra,0xffffc
    80004a5c:	192080e7          	jalr	402(ra) # 80000bea <acquire>
  if(writable){
    80004a60:	02090d63          	beqz	s2,80004a9a <pipeclose+0x52>
    pi->writeopen = 0;
    80004a64:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a68:	21848513          	addi	a0,s1,536
    80004a6c:	ffffd097          	auipc	ra,0xffffd
    80004a70:	66a080e7          	jalr	1642(ra) # 800020d6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a74:	2204b783          	ld	a5,544(s1)
    80004a78:	eb95                	bnez	a5,80004aac <pipeclose+0x64>
    release(&pi->lock);
    80004a7a:	8526                	mv	a0,s1
    80004a7c:	ffffc097          	auipc	ra,0xffffc
    80004a80:	222080e7          	jalr	546(ra) # 80000c9e <release>
    kfree((char*)pi);
    80004a84:	8526                	mv	a0,s1
    80004a86:	ffffc097          	auipc	ra,0xffffc
    80004a8a:	f78080e7          	jalr	-136(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80004a8e:	60e2                	ld	ra,24(sp)
    80004a90:	6442                	ld	s0,16(sp)
    80004a92:	64a2                	ld	s1,8(sp)
    80004a94:	6902                	ld	s2,0(sp)
    80004a96:	6105                	addi	sp,sp,32
    80004a98:	8082                	ret
    pi->readopen = 0;
    80004a9a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a9e:	21c48513          	addi	a0,s1,540
    80004aa2:	ffffd097          	auipc	ra,0xffffd
    80004aa6:	634080e7          	jalr	1588(ra) # 800020d6 <wakeup>
    80004aaa:	b7e9                	j	80004a74 <pipeclose+0x2c>
    release(&pi->lock);
    80004aac:	8526                	mv	a0,s1
    80004aae:	ffffc097          	auipc	ra,0xffffc
    80004ab2:	1f0080e7          	jalr	496(ra) # 80000c9e <release>
}
    80004ab6:	bfe1                	j	80004a8e <pipeclose+0x46>

0000000080004ab8 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ab8:	7159                	addi	sp,sp,-112
    80004aba:	f486                	sd	ra,104(sp)
    80004abc:	f0a2                	sd	s0,96(sp)
    80004abe:	eca6                	sd	s1,88(sp)
    80004ac0:	e8ca                	sd	s2,80(sp)
    80004ac2:	e4ce                	sd	s3,72(sp)
    80004ac4:	e0d2                	sd	s4,64(sp)
    80004ac6:	fc56                	sd	s5,56(sp)
    80004ac8:	f85a                	sd	s6,48(sp)
    80004aca:	f45e                	sd	s7,40(sp)
    80004acc:	f062                	sd	s8,32(sp)
    80004ace:	ec66                	sd	s9,24(sp)
    80004ad0:	1880                	addi	s0,sp,112
    80004ad2:	84aa                	mv	s1,a0
    80004ad4:	8aae                	mv	s5,a1
    80004ad6:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ad8:	ffffd097          	auipc	ra,0xffffd
    80004adc:	eee080e7          	jalr	-274(ra) # 800019c6 <myproc>
    80004ae0:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ae2:	8526                	mv	a0,s1
    80004ae4:	ffffc097          	auipc	ra,0xffffc
    80004ae8:	106080e7          	jalr	262(ra) # 80000bea <acquire>
  while(i < n){
    80004aec:	0d405463          	blez	s4,80004bb4 <pipewrite+0xfc>
    80004af0:	8ba6                	mv	s7,s1
  int i = 0;
    80004af2:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004af4:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004af6:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004afa:	21c48c13          	addi	s8,s1,540
    80004afe:	a08d                	j	80004b60 <pipewrite+0xa8>
      release(&pi->lock);
    80004b00:	8526                	mv	a0,s1
    80004b02:	ffffc097          	auipc	ra,0xffffc
    80004b06:	19c080e7          	jalr	412(ra) # 80000c9e <release>
      return -1;
    80004b0a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b0c:	854a                	mv	a0,s2
    80004b0e:	70a6                	ld	ra,104(sp)
    80004b10:	7406                	ld	s0,96(sp)
    80004b12:	64e6                	ld	s1,88(sp)
    80004b14:	6946                	ld	s2,80(sp)
    80004b16:	69a6                	ld	s3,72(sp)
    80004b18:	6a06                	ld	s4,64(sp)
    80004b1a:	7ae2                	ld	s5,56(sp)
    80004b1c:	7b42                	ld	s6,48(sp)
    80004b1e:	7ba2                	ld	s7,40(sp)
    80004b20:	7c02                	ld	s8,32(sp)
    80004b22:	6ce2                	ld	s9,24(sp)
    80004b24:	6165                	addi	sp,sp,112
    80004b26:	8082                	ret
      wakeup(&pi->nread);
    80004b28:	8566                	mv	a0,s9
    80004b2a:	ffffd097          	auipc	ra,0xffffd
    80004b2e:	5ac080e7          	jalr	1452(ra) # 800020d6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b32:	85de                	mv	a1,s7
    80004b34:	8562                	mv	a0,s8
    80004b36:	ffffd097          	auipc	ra,0xffffd
    80004b3a:	53c080e7          	jalr	1340(ra) # 80002072 <sleep>
    80004b3e:	a839                	j	80004b5c <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b40:	21c4a783          	lw	a5,540(s1)
    80004b44:	0017871b          	addiw	a4,a5,1
    80004b48:	20e4ae23          	sw	a4,540(s1)
    80004b4c:	1ff7f793          	andi	a5,a5,511
    80004b50:	97a6                	add	a5,a5,s1
    80004b52:	f9f44703          	lbu	a4,-97(s0)
    80004b56:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b5a:	2905                	addiw	s2,s2,1
  while(i < n){
    80004b5c:	05495063          	bge	s2,s4,80004b9c <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80004b60:	2204a783          	lw	a5,544(s1)
    80004b64:	dfd1                	beqz	a5,80004b00 <pipewrite+0x48>
    80004b66:	854e                	mv	a0,s3
    80004b68:	ffffd097          	auipc	ra,0xffffd
    80004b6c:	7b2080e7          	jalr	1970(ra) # 8000231a <killed>
    80004b70:	f941                	bnez	a0,80004b00 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b72:	2184a783          	lw	a5,536(s1)
    80004b76:	21c4a703          	lw	a4,540(s1)
    80004b7a:	2007879b          	addiw	a5,a5,512
    80004b7e:	faf705e3          	beq	a4,a5,80004b28 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b82:	4685                	li	a3,1
    80004b84:	01590633          	add	a2,s2,s5
    80004b88:	f9f40593          	addi	a1,s0,-97
    80004b8c:	0509b503          	ld	a0,80(s3)
    80004b90:	ffffd097          	auipc	ra,0xffffd
    80004b94:	b80080e7          	jalr	-1152(ra) # 80001710 <copyin>
    80004b98:	fb6514e3          	bne	a0,s6,80004b40 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004b9c:	21848513          	addi	a0,s1,536
    80004ba0:	ffffd097          	auipc	ra,0xffffd
    80004ba4:	536080e7          	jalr	1334(ra) # 800020d6 <wakeup>
  release(&pi->lock);
    80004ba8:	8526                	mv	a0,s1
    80004baa:	ffffc097          	auipc	ra,0xffffc
    80004bae:	0f4080e7          	jalr	244(ra) # 80000c9e <release>
  return i;
    80004bb2:	bfa9                	j	80004b0c <pipewrite+0x54>
  int i = 0;
    80004bb4:	4901                	li	s2,0
    80004bb6:	b7dd                	j	80004b9c <pipewrite+0xe4>

0000000080004bb8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bb8:	715d                	addi	sp,sp,-80
    80004bba:	e486                	sd	ra,72(sp)
    80004bbc:	e0a2                	sd	s0,64(sp)
    80004bbe:	fc26                	sd	s1,56(sp)
    80004bc0:	f84a                	sd	s2,48(sp)
    80004bc2:	f44e                	sd	s3,40(sp)
    80004bc4:	f052                	sd	s4,32(sp)
    80004bc6:	ec56                	sd	s5,24(sp)
    80004bc8:	e85a                	sd	s6,16(sp)
    80004bca:	0880                	addi	s0,sp,80
    80004bcc:	84aa                	mv	s1,a0
    80004bce:	892e                	mv	s2,a1
    80004bd0:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bd2:	ffffd097          	auipc	ra,0xffffd
    80004bd6:	df4080e7          	jalr	-524(ra) # 800019c6 <myproc>
    80004bda:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bdc:	8b26                	mv	s6,s1
    80004bde:	8526                	mv	a0,s1
    80004be0:	ffffc097          	auipc	ra,0xffffc
    80004be4:	00a080e7          	jalr	10(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004be8:	2184a703          	lw	a4,536(s1)
    80004bec:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bf0:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bf4:	02f71763          	bne	a4,a5,80004c22 <piperead+0x6a>
    80004bf8:	2244a783          	lw	a5,548(s1)
    80004bfc:	c39d                	beqz	a5,80004c22 <piperead+0x6a>
    if(killed(pr)){
    80004bfe:	8552                	mv	a0,s4
    80004c00:	ffffd097          	auipc	ra,0xffffd
    80004c04:	71a080e7          	jalr	1818(ra) # 8000231a <killed>
    80004c08:	e941                	bnez	a0,80004c98 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c0a:	85da                	mv	a1,s6
    80004c0c:	854e                	mv	a0,s3
    80004c0e:	ffffd097          	auipc	ra,0xffffd
    80004c12:	464080e7          	jalr	1124(ra) # 80002072 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c16:	2184a703          	lw	a4,536(s1)
    80004c1a:	21c4a783          	lw	a5,540(s1)
    80004c1e:	fcf70de3          	beq	a4,a5,80004bf8 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c22:	09505263          	blez	s5,80004ca6 <piperead+0xee>
    80004c26:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c28:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c2a:	2184a783          	lw	a5,536(s1)
    80004c2e:	21c4a703          	lw	a4,540(s1)
    80004c32:	02f70d63          	beq	a4,a5,80004c6c <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c36:	0017871b          	addiw	a4,a5,1
    80004c3a:	20e4ac23          	sw	a4,536(s1)
    80004c3e:	1ff7f793          	andi	a5,a5,511
    80004c42:	97a6                	add	a5,a5,s1
    80004c44:	0187c783          	lbu	a5,24(a5)
    80004c48:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c4c:	4685                	li	a3,1
    80004c4e:	fbf40613          	addi	a2,s0,-65
    80004c52:	85ca                	mv	a1,s2
    80004c54:	050a3503          	ld	a0,80(s4)
    80004c58:	ffffd097          	auipc	ra,0xffffd
    80004c5c:	a2c080e7          	jalr	-1492(ra) # 80001684 <copyout>
    80004c60:	01650663          	beq	a0,s6,80004c6c <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c64:	2985                	addiw	s3,s3,1
    80004c66:	0905                	addi	s2,s2,1
    80004c68:	fd3a91e3          	bne	s5,s3,80004c2a <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c6c:	21c48513          	addi	a0,s1,540
    80004c70:	ffffd097          	auipc	ra,0xffffd
    80004c74:	466080e7          	jalr	1126(ra) # 800020d6 <wakeup>
  release(&pi->lock);
    80004c78:	8526                	mv	a0,s1
    80004c7a:	ffffc097          	auipc	ra,0xffffc
    80004c7e:	024080e7          	jalr	36(ra) # 80000c9e <release>
  return i;
}
    80004c82:	854e                	mv	a0,s3
    80004c84:	60a6                	ld	ra,72(sp)
    80004c86:	6406                	ld	s0,64(sp)
    80004c88:	74e2                	ld	s1,56(sp)
    80004c8a:	7942                	ld	s2,48(sp)
    80004c8c:	79a2                	ld	s3,40(sp)
    80004c8e:	7a02                	ld	s4,32(sp)
    80004c90:	6ae2                	ld	s5,24(sp)
    80004c92:	6b42                	ld	s6,16(sp)
    80004c94:	6161                	addi	sp,sp,80
    80004c96:	8082                	ret
      release(&pi->lock);
    80004c98:	8526                	mv	a0,s1
    80004c9a:	ffffc097          	auipc	ra,0xffffc
    80004c9e:	004080e7          	jalr	4(ra) # 80000c9e <release>
      return -1;
    80004ca2:	59fd                	li	s3,-1
    80004ca4:	bff9                	j	80004c82 <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ca6:	4981                	li	s3,0
    80004ca8:	b7d1                	j	80004c6c <piperead+0xb4>

0000000080004caa <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004caa:	1141                	addi	sp,sp,-16
    80004cac:	e422                	sd	s0,8(sp)
    80004cae:	0800                	addi	s0,sp,16
    80004cb0:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004cb2:	8905                	andi	a0,a0,1
    80004cb4:	c111                	beqz	a0,80004cb8 <flags2perm+0xe>
      perm = PTE_X;
    80004cb6:	4521                	li	a0,8
    if(flags & 0x2)
    80004cb8:	8b89                	andi	a5,a5,2
    80004cba:	c399                	beqz	a5,80004cc0 <flags2perm+0x16>
      perm |= PTE_W;
    80004cbc:	00456513          	ori	a0,a0,4
    return perm;
}
    80004cc0:	6422                	ld	s0,8(sp)
    80004cc2:	0141                	addi	sp,sp,16
    80004cc4:	8082                	ret

0000000080004cc6 <exec>:

int
exec(char *path, char **argv)
{
    80004cc6:	df010113          	addi	sp,sp,-528
    80004cca:	20113423          	sd	ra,520(sp)
    80004cce:	20813023          	sd	s0,512(sp)
    80004cd2:	ffa6                	sd	s1,504(sp)
    80004cd4:	fbca                	sd	s2,496(sp)
    80004cd6:	f7ce                	sd	s3,488(sp)
    80004cd8:	f3d2                	sd	s4,480(sp)
    80004cda:	efd6                	sd	s5,472(sp)
    80004cdc:	ebda                	sd	s6,464(sp)
    80004cde:	e7de                	sd	s7,456(sp)
    80004ce0:	e3e2                	sd	s8,448(sp)
    80004ce2:	ff66                	sd	s9,440(sp)
    80004ce4:	fb6a                	sd	s10,432(sp)
    80004ce6:	f76e                	sd	s11,424(sp)
    80004ce8:	0c00                	addi	s0,sp,528
    80004cea:	84aa                	mv	s1,a0
    80004cec:	dea43c23          	sd	a0,-520(s0)
    80004cf0:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cf4:	ffffd097          	auipc	ra,0xffffd
    80004cf8:	cd2080e7          	jalr	-814(ra) # 800019c6 <myproc>
    80004cfc:	892a                	mv	s2,a0

  begin_op();
    80004cfe:	fffff097          	auipc	ra,0xfffff
    80004d02:	474080e7          	jalr	1140(ra) # 80004172 <begin_op>

  if((ip = namei(path)) == 0){
    80004d06:	8526                	mv	a0,s1
    80004d08:	fffff097          	auipc	ra,0xfffff
    80004d0c:	24e080e7          	jalr	590(ra) # 80003f56 <namei>
    80004d10:	c92d                	beqz	a0,80004d82 <exec+0xbc>
    80004d12:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d14:	fffff097          	auipc	ra,0xfffff
    80004d18:	a9c080e7          	jalr	-1380(ra) # 800037b0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d1c:	04000713          	li	a4,64
    80004d20:	4681                	li	a3,0
    80004d22:	e5040613          	addi	a2,s0,-432
    80004d26:	4581                	li	a1,0
    80004d28:	8526                	mv	a0,s1
    80004d2a:	fffff097          	auipc	ra,0xfffff
    80004d2e:	d3a080e7          	jalr	-710(ra) # 80003a64 <readi>
    80004d32:	04000793          	li	a5,64
    80004d36:	00f51a63          	bne	a0,a5,80004d4a <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004d3a:	e5042703          	lw	a4,-432(s0)
    80004d3e:	464c47b7          	lui	a5,0x464c4
    80004d42:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d46:	04f70463          	beq	a4,a5,80004d8e <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d4a:	8526                	mv	a0,s1
    80004d4c:	fffff097          	auipc	ra,0xfffff
    80004d50:	cc6080e7          	jalr	-826(ra) # 80003a12 <iunlockput>
    end_op();
    80004d54:	fffff097          	auipc	ra,0xfffff
    80004d58:	49e080e7          	jalr	1182(ra) # 800041f2 <end_op>
  }
  return -1;
    80004d5c:	557d                	li	a0,-1
}
    80004d5e:	20813083          	ld	ra,520(sp)
    80004d62:	20013403          	ld	s0,512(sp)
    80004d66:	74fe                	ld	s1,504(sp)
    80004d68:	795e                	ld	s2,496(sp)
    80004d6a:	79be                	ld	s3,488(sp)
    80004d6c:	7a1e                	ld	s4,480(sp)
    80004d6e:	6afe                	ld	s5,472(sp)
    80004d70:	6b5e                	ld	s6,464(sp)
    80004d72:	6bbe                	ld	s7,456(sp)
    80004d74:	6c1e                	ld	s8,448(sp)
    80004d76:	7cfa                	ld	s9,440(sp)
    80004d78:	7d5a                	ld	s10,432(sp)
    80004d7a:	7dba                	ld	s11,424(sp)
    80004d7c:	21010113          	addi	sp,sp,528
    80004d80:	8082                	ret
    end_op();
    80004d82:	fffff097          	auipc	ra,0xfffff
    80004d86:	470080e7          	jalr	1136(ra) # 800041f2 <end_op>
    return -1;
    80004d8a:	557d                	li	a0,-1
    80004d8c:	bfc9                	j	80004d5e <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d8e:	854a                	mv	a0,s2
    80004d90:	ffffd097          	auipc	ra,0xffffd
    80004d94:	cfa080e7          	jalr	-774(ra) # 80001a8a <proc_pagetable>
    80004d98:	8baa                	mv	s7,a0
    80004d9a:	d945                	beqz	a0,80004d4a <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d9c:	e7042983          	lw	s3,-400(s0)
    80004da0:	e8845783          	lhu	a5,-376(s0)
    80004da4:	c7ad                	beqz	a5,80004e0e <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004da6:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004da8:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004daa:	6c85                	lui	s9,0x1
    80004dac:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004db0:	def43823          	sd	a5,-528(s0)
    80004db4:	ac0d                	j	80004fe6 <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004db6:	00004517          	auipc	a0,0x4
    80004dba:	a1250513          	addi	a0,a0,-1518 # 800087c8 <syscalls+0x298>
    80004dbe:	ffffb097          	auipc	ra,0xffffb
    80004dc2:	786080e7          	jalr	1926(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004dc6:	8756                	mv	a4,s5
    80004dc8:	012d86bb          	addw	a3,s11,s2
    80004dcc:	4581                	li	a1,0
    80004dce:	8526                	mv	a0,s1
    80004dd0:	fffff097          	auipc	ra,0xfffff
    80004dd4:	c94080e7          	jalr	-876(ra) # 80003a64 <readi>
    80004dd8:	2501                	sext.w	a0,a0
    80004dda:	1aaa9a63          	bne	s5,a0,80004f8e <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    80004dde:	6785                	lui	a5,0x1
    80004de0:	0127893b          	addw	s2,a5,s2
    80004de4:	77fd                	lui	a5,0xfffff
    80004de6:	01478a3b          	addw	s4,a5,s4
    80004dea:	1f897563          	bgeu	s2,s8,80004fd4 <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    80004dee:	02091593          	slli	a1,s2,0x20
    80004df2:	9181                	srli	a1,a1,0x20
    80004df4:	95ea                	add	a1,a1,s10
    80004df6:	855e                	mv	a0,s7
    80004df8:	ffffc097          	auipc	ra,0xffffc
    80004dfc:	280080e7          	jalr	640(ra) # 80001078 <walkaddr>
    80004e00:	862a                	mv	a2,a0
    if(pa == 0)
    80004e02:	d955                	beqz	a0,80004db6 <exec+0xf0>
      n = PGSIZE;
    80004e04:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004e06:	fd9a70e3          	bgeu	s4,s9,80004dc6 <exec+0x100>
      n = sz - i;
    80004e0a:	8ad2                	mv	s5,s4
    80004e0c:	bf6d                	j	80004dc6 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e0e:	4a01                	li	s4,0
  iunlockput(ip);
    80004e10:	8526                	mv	a0,s1
    80004e12:	fffff097          	auipc	ra,0xfffff
    80004e16:	c00080e7          	jalr	-1024(ra) # 80003a12 <iunlockput>
  end_op();
    80004e1a:	fffff097          	auipc	ra,0xfffff
    80004e1e:	3d8080e7          	jalr	984(ra) # 800041f2 <end_op>
  p = myproc();
    80004e22:	ffffd097          	auipc	ra,0xffffd
    80004e26:	ba4080e7          	jalr	-1116(ra) # 800019c6 <myproc>
    80004e2a:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e2c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e30:	6785                	lui	a5,0x1
    80004e32:	17fd                	addi	a5,a5,-1
    80004e34:	9a3e                	add	s4,s4,a5
    80004e36:	757d                	lui	a0,0xfffff
    80004e38:	00aa77b3          	and	a5,s4,a0
    80004e3c:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e40:	4691                	li	a3,4
    80004e42:	6609                	lui	a2,0x2
    80004e44:	963e                	add	a2,a2,a5
    80004e46:	85be                	mv	a1,a5
    80004e48:	855e                	mv	a0,s7
    80004e4a:	ffffc097          	auipc	ra,0xffffc
    80004e4e:	5e2080e7          	jalr	1506(ra) # 8000142c <uvmalloc>
    80004e52:	8b2a                	mv	s6,a0
  ip = 0;
    80004e54:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e56:	12050c63          	beqz	a0,80004f8e <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e5a:	75f9                	lui	a1,0xffffe
    80004e5c:	95aa                	add	a1,a1,a0
    80004e5e:	855e                	mv	a0,s7
    80004e60:	ffffc097          	auipc	ra,0xffffc
    80004e64:	7f2080e7          	jalr	2034(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e68:	7c7d                	lui	s8,0xfffff
    80004e6a:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e6c:	e0043783          	ld	a5,-512(s0)
    80004e70:	6388                	ld	a0,0(a5)
    80004e72:	c535                	beqz	a0,80004ede <exec+0x218>
    80004e74:	e9040993          	addi	s3,s0,-368
    80004e78:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e7c:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e7e:	ffffc097          	auipc	ra,0xffffc
    80004e82:	fec080e7          	jalr	-20(ra) # 80000e6a <strlen>
    80004e86:	2505                	addiw	a0,a0,1
    80004e88:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e8c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e90:	13896663          	bltu	s2,s8,80004fbc <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e94:	e0043d83          	ld	s11,-512(s0)
    80004e98:	000dba03          	ld	s4,0(s11)
    80004e9c:	8552                	mv	a0,s4
    80004e9e:	ffffc097          	auipc	ra,0xffffc
    80004ea2:	fcc080e7          	jalr	-52(ra) # 80000e6a <strlen>
    80004ea6:	0015069b          	addiw	a3,a0,1
    80004eaa:	8652                	mv	a2,s4
    80004eac:	85ca                	mv	a1,s2
    80004eae:	855e                	mv	a0,s7
    80004eb0:	ffffc097          	auipc	ra,0xffffc
    80004eb4:	7d4080e7          	jalr	2004(ra) # 80001684 <copyout>
    80004eb8:	10054663          	bltz	a0,80004fc4 <exec+0x2fe>
    ustack[argc] = sp;
    80004ebc:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ec0:	0485                	addi	s1,s1,1
    80004ec2:	008d8793          	addi	a5,s11,8
    80004ec6:	e0f43023          	sd	a5,-512(s0)
    80004eca:	008db503          	ld	a0,8(s11)
    80004ece:	c911                	beqz	a0,80004ee2 <exec+0x21c>
    if(argc >= MAXARG)
    80004ed0:	09a1                	addi	s3,s3,8
    80004ed2:	fb3c96e3          	bne	s9,s3,80004e7e <exec+0x1b8>
  sz = sz1;
    80004ed6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004eda:	4481                	li	s1,0
    80004edc:	a84d                	j	80004f8e <exec+0x2c8>
  sp = sz;
    80004ede:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ee0:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ee2:	00349793          	slli	a5,s1,0x3
    80004ee6:	f9040713          	addi	a4,s0,-112
    80004eea:	97ba                	add	a5,a5,a4
    80004eec:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004ef0:	00148693          	addi	a3,s1,1
    80004ef4:	068e                	slli	a3,a3,0x3
    80004ef6:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004efa:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004efe:	01897663          	bgeu	s2,s8,80004f0a <exec+0x244>
  sz = sz1;
    80004f02:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f06:	4481                	li	s1,0
    80004f08:	a059                	j	80004f8e <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f0a:	e9040613          	addi	a2,s0,-368
    80004f0e:	85ca                	mv	a1,s2
    80004f10:	855e                	mv	a0,s7
    80004f12:	ffffc097          	auipc	ra,0xffffc
    80004f16:	772080e7          	jalr	1906(ra) # 80001684 <copyout>
    80004f1a:	0a054963          	bltz	a0,80004fcc <exec+0x306>
  p->trapframe->a1 = sp;
    80004f1e:	058ab783          	ld	a5,88(s5)
    80004f22:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f26:	df843783          	ld	a5,-520(s0)
    80004f2a:	0007c703          	lbu	a4,0(a5)
    80004f2e:	cf11                	beqz	a4,80004f4a <exec+0x284>
    80004f30:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f32:	02f00693          	li	a3,47
    80004f36:	a039                	j	80004f44 <exec+0x27e>
      last = s+1;
    80004f38:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004f3c:	0785                	addi	a5,a5,1
    80004f3e:	fff7c703          	lbu	a4,-1(a5)
    80004f42:	c701                	beqz	a4,80004f4a <exec+0x284>
    if(*s == '/')
    80004f44:	fed71ce3          	bne	a4,a3,80004f3c <exec+0x276>
    80004f48:	bfc5                	j	80004f38 <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f4a:	4641                	li	a2,16
    80004f4c:	df843583          	ld	a1,-520(s0)
    80004f50:	158a8513          	addi	a0,s5,344
    80004f54:	ffffc097          	auipc	ra,0xffffc
    80004f58:	ee4080e7          	jalr	-284(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f5c:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f60:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f64:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f68:	058ab783          	ld	a5,88(s5)
    80004f6c:	e6843703          	ld	a4,-408(s0)
    80004f70:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f72:	058ab783          	ld	a5,88(s5)
    80004f76:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f7a:	85ea                	mv	a1,s10
    80004f7c:	ffffd097          	auipc	ra,0xffffd
    80004f80:	baa080e7          	jalr	-1110(ra) # 80001b26 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f84:	0004851b          	sext.w	a0,s1
    80004f88:	bbd9                	j	80004d5e <exec+0x98>
    80004f8a:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f8e:	e0843583          	ld	a1,-504(s0)
    80004f92:	855e                	mv	a0,s7
    80004f94:	ffffd097          	auipc	ra,0xffffd
    80004f98:	b92080e7          	jalr	-1134(ra) # 80001b26 <proc_freepagetable>
  if(ip){
    80004f9c:	da0497e3          	bnez	s1,80004d4a <exec+0x84>
  return -1;
    80004fa0:	557d                	li	a0,-1
    80004fa2:	bb75                	j	80004d5e <exec+0x98>
    80004fa4:	e1443423          	sd	s4,-504(s0)
    80004fa8:	b7dd                	j	80004f8e <exec+0x2c8>
    80004faa:	e1443423          	sd	s4,-504(s0)
    80004fae:	b7c5                	j	80004f8e <exec+0x2c8>
    80004fb0:	e1443423          	sd	s4,-504(s0)
    80004fb4:	bfe9                	j	80004f8e <exec+0x2c8>
    80004fb6:	e1443423          	sd	s4,-504(s0)
    80004fba:	bfd1                	j	80004f8e <exec+0x2c8>
  sz = sz1;
    80004fbc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fc0:	4481                	li	s1,0
    80004fc2:	b7f1                	j	80004f8e <exec+0x2c8>
  sz = sz1;
    80004fc4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fc8:	4481                	li	s1,0
    80004fca:	b7d1                	j	80004f8e <exec+0x2c8>
  sz = sz1;
    80004fcc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fd0:	4481                	li	s1,0
    80004fd2:	bf75                	j	80004f8e <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004fd4:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fd8:	2b05                	addiw	s6,s6,1
    80004fda:	0389899b          	addiw	s3,s3,56
    80004fde:	e8845783          	lhu	a5,-376(s0)
    80004fe2:	e2fb57e3          	bge	s6,a5,80004e10 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fe6:	2981                	sext.w	s3,s3
    80004fe8:	03800713          	li	a4,56
    80004fec:	86ce                	mv	a3,s3
    80004fee:	e1840613          	addi	a2,s0,-488
    80004ff2:	4581                	li	a1,0
    80004ff4:	8526                	mv	a0,s1
    80004ff6:	fffff097          	auipc	ra,0xfffff
    80004ffa:	a6e080e7          	jalr	-1426(ra) # 80003a64 <readi>
    80004ffe:	03800793          	li	a5,56
    80005002:	f8f514e3          	bne	a0,a5,80004f8a <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    80005006:	e1842783          	lw	a5,-488(s0)
    8000500a:	4705                	li	a4,1
    8000500c:	fce796e3          	bne	a5,a4,80004fd8 <exec+0x312>
    if(ph.memsz < ph.filesz)
    80005010:	e4043903          	ld	s2,-448(s0)
    80005014:	e3843783          	ld	a5,-456(s0)
    80005018:	f8f966e3          	bltu	s2,a5,80004fa4 <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000501c:	e2843783          	ld	a5,-472(s0)
    80005020:	993e                	add	s2,s2,a5
    80005022:	f8f964e3          	bltu	s2,a5,80004faa <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    80005026:	df043703          	ld	a4,-528(s0)
    8000502a:	8ff9                	and	a5,a5,a4
    8000502c:	f3d1                	bnez	a5,80004fb0 <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000502e:	e1c42503          	lw	a0,-484(s0)
    80005032:	00000097          	auipc	ra,0x0
    80005036:	c78080e7          	jalr	-904(ra) # 80004caa <flags2perm>
    8000503a:	86aa                	mv	a3,a0
    8000503c:	864a                	mv	a2,s2
    8000503e:	85d2                	mv	a1,s4
    80005040:	855e                	mv	a0,s7
    80005042:	ffffc097          	auipc	ra,0xffffc
    80005046:	3ea080e7          	jalr	1002(ra) # 8000142c <uvmalloc>
    8000504a:	e0a43423          	sd	a0,-504(s0)
    8000504e:	d525                	beqz	a0,80004fb6 <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005050:	e2843d03          	ld	s10,-472(s0)
    80005054:	e2042d83          	lw	s11,-480(s0)
    80005058:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000505c:	f60c0ce3          	beqz	s8,80004fd4 <exec+0x30e>
    80005060:	8a62                	mv	s4,s8
    80005062:	4901                	li	s2,0
    80005064:	b369                	j	80004dee <exec+0x128>

0000000080005066 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005066:	7179                	addi	sp,sp,-48
    80005068:	f406                	sd	ra,40(sp)
    8000506a:	f022                	sd	s0,32(sp)
    8000506c:	ec26                	sd	s1,24(sp)
    8000506e:	e84a                	sd	s2,16(sp)
    80005070:	1800                	addi	s0,sp,48
    80005072:	892e                	mv	s2,a1
    80005074:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005076:	fdc40593          	addi	a1,s0,-36
    8000507a:	ffffe097          	auipc	ra,0xffffe
    8000507e:	aca080e7          	jalr	-1334(ra) # 80002b44 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005082:	fdc42703          	lw	a4,-36(s0)
    80005086:	47bd                	li	a5,15
    80005088:	02e7eb63          	bltu	a5,a4,800050be <argfd+0x58>
    8000508c:	ffffd097          	auipc	ra,0xffffd
    80005090:	93a080e7          	jalr	-1734(ra) # 800019c6 <myproc>
    80005094:	fdc42703          	lw	a4,-36(s0)
    80005098:	01a70793          	addi	a5,a4,26
    8000509c:	078e                	slli	a5,a5,0x3
    8000509e:	953e                	add	a0,a0,a5
    800050a0:	611c                	ld	a5,0(a0)
    800050a2:	c385                	beqz	a5,800050c2 <argfd+0x5c>
    return -1;
  if(pfd)
    800050a4:	00090463          	beqz	s2,800050ac <argfd+0x46>
    *pfd = fd;
    800050a8:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050ac:	4501                	li	a0,0
  if(pf)
    800050ae:	c091                	beqz	s1,800050b2 <argfd+0x4c>
    *pf = f;
    800050b0:	e09c                	sd	a5,0(s1)
}
    800050b2:	70a2                	ld	ra,40(sp)
    800050b4:	7402                	ld	s0,32(sp)
    800050b6:	64e2                	ld	s1,24(sp)
    800050b8:	6942                	ld	s2,16(sp)
    800050ba:	6145                	addi	sp,sp,48
    800050bc:	8082                	ret
    return -1;
    800050be:	557d                	li	a0,-1
    800050c0:	bfcd                	j	800050b2 <argfd+0x4c>
    800050c2:	557d                	li	a0,-1
    800050c4:	b7fd                	j	800050b2 <argfd+0x4c>

00000000800050c6 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050c6:	1101                	addi	sp,sp,-32
    800050c8:	ec06                	sd	ra,24(sp)
    800050ca:	e822                	sd	s0,16(sp)
    800050cc:	e426                	sd	s1,8(sp)
    800050ce:	1000                	addi	s0,sp,32
    800050d0:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050d2:	ffffd097          	auipc	ra,0xffffd
    800050d6:	8f4080e7          	jalr	-1804(ra) # 800019c6 <myproc>
    800050da:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050dc:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffdc9a0>
    800050e0:	4501                	li	a0,0
    800050e2:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050e4:	6398                	ld	a4,0(a5)
    800050e6:	cb19                	beqz	a4,800050fc <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050e8:	2505                	addiw	a0,a0,1
    800050ea:	07a1                	addi	a5,a5,8
    800050ec:	fed51ce3          	bne	a0,a3,800050e4 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050f0:	557d                	li	a0,-1
}
    800050f2:	60e2                	ld	ra,24(sp)
    800050f4:	6442                	ld	s0,16(sp)
    800050f6:	64a2                	ld	s1,8(sp)
    800050f8:	6105                	addi	sp,sp,32
    800050fa:	8082                	ret
      p->ofile[fd] = f;
    800050fc:	01a50793          	addi	a5,a0,26
    80005100:	078e                	slli	a5,a5,0x3
    80005102:	963e                	add	a2,a2,a5
    80005104:	e204                	sd	s1,0(a2)
      return fd;
    80005106:	b7f5                	j	800050f2 <fdalloc+0x2c>

0000000080005108 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005108:	715d                	addi	sp,sp,-80
    8000510a:	e486                	sd	ra,72(sp)
    8000510c:	e0a2                	sd	s0,64(sp)
    8000510e:	fc26                	sd	s1,56(sp)
    80005110:	f84a                	sd	s2,48(sp)
    80005112:	f44e                	sd	s3,40(sp)
    80005114:	f052                	sd	s4,32(sp)
    80005116:	ec56                	sd	s5,24(sp)
    80005118:	e85a                	sd	s6,16(sp)
    8000511a:	0880                	addi	s0,sp,80
    8000511c:	8b2e                	mv	s6,a1
    8000511e:	89b2                	mv	s3,a2
    80005120:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005122:	fb040593          	addi	a1,s0,-80
    80005126:	fffff097          	auipc	ra,0xfffff
    8000512a:	e4e080e7          	jalr	-434(ra) # 80003f74 <nameiparent>
    8000512e:	84aa                	mv	s1,a0
    80005130:	16050063          	beqz	a0,80005290 <create+0x188>
    return 0;

  ilock(dp);
    80005134:	ffffe097          	auipc	ra,0xffffe
    80005138:	67c080e7          	jalr	1660(ra) # 800037b0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000513c:	4601                	li	a2,0
    8000513e:	fb040593          	addi	a1,s0,-80
    80005142:	8526                	mv	a0,s1
    80005144:	fffff097          	auipc	ra,0xfffff
    80005148:	b50080e7          	jalr	-1200(ra) # 80003c94 <dirlookup>
    8000514c:	8aaa                	mv	s5,a0
    8000514e:	c931                	beqz	a0,800051a2 <create+0x9a>
    iunlockput(dp);
    80005150:	8526                	mv	a0,s1
    80005152:	fffff097          	auipc	ra,0xfffff
    80005156:	8c0080e7          	jalr	-1856(ra) # 80003a12 <iunlockput>
    ilock(ip);
    8000515a:	8556                	mv	a0,s5
    8000515c:	ffffe097          	auipc	ra,0xffffe
    80005160:	654080e7          	jalr	1620(ra) # 800037b0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005164:	000b059b          	sext.w	a1,s6
    80005168:	4789                	li	a5,2
    8000516a:	02f59563          	bne	a1,a5,80005194 <create+0x8c>
    8000516e:	044ad783          	lhu	a5,68(s5)
    80005172:	37f9                	addiw	a5,a5,-2
    80005174:	17c2                	slli	a5,a5,0x30
    80005176:	93c1                	srli	a5,a5,0x30
    80005178:	4705                	li	a4,1
    8000517a:	00f76d63          	bltu	a4,a5,80005194 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000517e:	8556                	mv	a0,s5
    80005180:	60a6                	ld	ra,72(sp)
    80005182:	6406                	ld	s0,64(sp)
    80005184:	74e2                	ld	s1,56(sp)
    80005186:	7942                	ld	s2,48(sp)
    80005188:	79a2                	ld	s3,40(sp)
    8000518a:	7a02                	ld	s4,32(sp)
    8000518c:	6ae2                	ld	s5,24(sp)
    8000518e:	6b42                	ld	s6,16(sp)
    80005190:	6161                	addi	sp,sp,80
    80005192:	8082                	ret
    iunlockput(ip);
    80005194:	8556                	mv	a0,s5
    80005196:	fffff097          	auipc	ra,0xfffff
    8000519a:	87c080e7          	jalr	-1924(ra) # 80003a12 <iunlockput>
    return 0;
    8000519e:	4a81                	li	s5,0
    800051a0:	bff9                	j	8000517e <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800051a2:	85da                	mv	a1,s6
    800051a4:	4088                	lw	a0,0(s1)
    800051a6:	ffffe097          	auipc	ra,0xffffe
    800051aa:	46e080e7          	jalr	1134(ra) # 80003614 <ialloc>
    800051ae:	8a2a                	mv	s4,a0
    800051b0:	c921                	beqz	a0,80005200 <create+0xf8>
  ilock(ip);
    800051b2:	ffffe097          	auipc	ra,0xffffe
    800051b6:	5fe080e7          	jalr	1534(ra) # 800037b0 <ilock>
  ip->major = major;
    800051ba:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800051be:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800051c2:	4785                	li	a5,1
    800051c4:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    800051c8:	8552                	mv	a0,s4
    800051ca:	ffffe097          	auipc	ra,0xffffe
    800051ce:	51c080e7          	jalr	1308(ra) # 800036e6 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051d2:	000b059b          	sext.w	a1,s6
    800051d6:	4785                	li	a5,1
    800051d8:	02f58b63          	beq	a1,a5,8000520e <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    800051dc:	004a2603          	lw	a2,4(s4)
    800051e0:	fb040593          	addi	a1,s0,-80
    800051e4:	8526                	mv	a0,s1
    800051e6:	fffff097          	auipc	ra,0xfffff
    800051ea:	cbe080e7          	jalr	-834(ra) # 80003ea4 <dirlink>
    800051ee:	06054f63          	bltz	a0,8000526c <create+0x164>
  iunlockput(dp);
    800051f2:	8526                	mv	a0,s1
    800051f4:	fffff097          	auipc	ra,0xfffff
    800051f8:	81e080e7          	jalr	-2018(ra) # 80003a12 <iunlockput>
  return ip;
    800051fc:	8ad2                	mv	s5,s4
    800051fe:	b741                	j	8000517e <create+0x76>
    iunlockput(dp);
    80005200:	8526                	mv	a0,s1
    80005202:	fffff097          	auipc	ra,0xfffff
    80005206:	810080e7          	jalr	-2032(ra) # 80003a12 <iunlockput>
    return 0;
    8000520a:	8ad2                	mv	s5,s4
    8000520c:	bf8d                	j	8000517e <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000520e:	004a2603          	lw	a2,4(s4)
    80005212:	00003597          	auipc	a1,0x3
    80005216:	5d658593          	addi	a1,a1,1494 # 800087e8 <syscalls+0x2b8>
    8000521a:	8552                	mv	a0,s4
    8000521c:	fffff097          	auipc	ra,0xfffff
    80005220:	c88080e7          	jalr	-888(ra) # 80003ea4 <dirlink>
    80005224:	04054463          	bltz	a0,8000526c <create+0x164>
    80005228:	40d0                	lw	a2,4(s1)
    8000522a:	00003597          	auipc	a1,0x3
    8000522e:	5c658593          	addi	a1,a1,1478 # 800087f0 <syscalls+0x2c0>
    80005232:	8552                	mv	a0,s4
    80005234:	fffff097          	auipc	ra,0xfffff
    80005238:	c70080e7          	jalr	-912(ra) # 80003ea4 <dirlink>
    8000523c:	02054863          	bltz	a0,8000526c <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    80005240:	004a2603          	lw	a2,4(s4)
    80005244:	fb040593          	addi	a1,s0,-80
    80005248:	8526                	mv	a0,s1
    8000524a:	fffff097          	auipc	ra,0xfffff
    8000524e:	c5a080e7          	jalr	-934(ra) # 80003ea4 <dirlink>
    80005252:	00054d63          	bltz	a0,8000526c <create+0x164>
    dp->nlink++;  // for ".."
    80005256:	04a4d783          	lhu	a5,74(s1)
    8000525a:	2785                	addiw	a5,a5,1
    8000525c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005260:	8526                	mv	a0,s1
    80005262:	ffffe097          	auipc	ra,0xffffe
    80005266:	484080e7          	jalr	1156(ra) # 800036e6 <iupdate>
    8000526a:	b761                	j	800051f2 <create+0xea>
  ip->nlink = 0;
    8000526c:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005270:	8552                	mv	a0,s4
    80005272:	ffffe097          	auipc	ra,0xffffe
    80005276:	474080e7          	jalr	1140(ra) # 800036e6 <iupdate>
  iunlockput(ip);
    8000527a:	8552                	mv	a0,s4
    8000527c:	ffffe097          	auipc	ra,0xffffe
    80005280:	796080e7          	jalr	1942(ra) # 80003a12 <iunlockput>
  iunlockput(dp);
    80005284:	8526                	mv	a0,s1
    80005286:	ffffe097          	auipc	ra,0xffffe
    8000528a:	78c080e7          	jalr	1932(ra) # 80003a12 <iunlockput>
  return 0;
    8000528e:	bdc5                	j	8000517e <create+0x76>
    return 0;
    80005290:	8aaa                	mv	s5,a0
    80005292:	b5f5                	j	8000517e <create+0x76>

0000000080005294 <sys_dup>:
{
    80005294:	7179                	addi	sp,sp,-48
    80005296:	f406                	sd	ra,40(sp)
    80005298:	f022                	sd	s0,32(sp)
    8000529a:	ec26                	sd	s1,24(sp)
    8000529c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000529e:	fd840613          	addi	a2,s0,-40
    800052a2:	4581                	li	a1,0
    800052a4:	4501                	li	a0,0
    800052a6:	00000097          	auipc	ra,0x0
    800052aa:	dc0080e7          	jalr	-576(ra) # 80005066 <argfd>
    return -1;
    800052ae:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052b0:	02054363          	bltz	a0,800052d6 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800052b4:	fd843503          	ld	a0,-40(s0)
    800052b8:	00000097          	auipc	ra,0x0
    800052bc:	e0e080e7          	jalr	-498(ra) # 800050c6 <fdalloc>
    800052c0:	84aa                	mv	s1,a0
    return -1;
    800052c2:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052c4:	00054963          	bltz	a0,800052d6 <sys_dup+0x42>
  filedup(f);
    800052c8:	fd843503          	ld	a0,-40(s0)
    800052cc:	fffff097          	auipc	ra,0xfffff
    800052d0:	320080e7          	jalr	800(ra) # 800045ec <filedup>
  return fd;
    800052d4:	87a6                	mv	a5,s1
}
    800052d6:	853e                	mv	a0,a5
    800052d8:	70a2                	ld	ra,40(sp)
    800052da:	7402                	ld	s0,32(sp)
    800052dc:	64e2                	ld	s1,24(sp)
    800052de:	6145                	addi	sp,sp,48
    800052e0:	8082                	ret

00000000800052e2 <sys_read>:
{
    800052e2:	7179                	addi	sp,sp,-48
    800052e4:	f406                	sd	ra,40(sp)
    800052e6:	f022                	sd	s0,32(sp)
    800052e8:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800052ea:	fd840593          	addi	a1,s0,-40
    800052ee:	4505                	li	a0,1
    800052f0:	ffffe097          	auipc	ra,0xffffe
    800052f4:	874080e7          	jalr	-1932(ra) # 80002b64 <argaddr>
  argint(2, &n);
    800052f8:	fe440593          	addi	a1,s0,-28
    800052fc:	4509                	li	a0,2
    800052fe:	ffffe097          	auipc	ra,0xffffe
    80005302:	846080e7          	jalr	-1978(ra) # 80002b44 <argint>
  if(argfd(0, 0, &f) < 0)
    80005306:	fe840613          	addi	a2,s0,-24
    8000530a:	4581                	li	a1,0
    8000530c:	4501                	li	a0,0
    8000530e:	00000097          	auipc	ra,0x0
    80005312:	d58080e7          	jalr	-680(ra) # 80005066 <argfd>
    80005316:	87aa                	mv	a5,a0
    return -1;
    80005318:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000531a:	0007cc63          	bltz	a5,80005332 <sys_read+0x50>
  return fileread(f, p, n);
    8000531e:	fe442603          	lw	a2,-28(s0)
    80005322:	fd843583          	ld	a1,-40(s0)
    80005326:	fe843503          	ld	a0,-24(s0)
    8000532a:	fffff097          	auipc	ra,0xfffff
    8000532e:	44e080e7          	jalr	1102(ra) # 80004778 <fileread>
}
    80005332:	70a2                	ld	ra,40(sp)
    80005334:	7402                	ld	s0,32(sp)
    80005336:	6145                	addi	sp,sp,48
    80005338:	8082                	ret

000000008000533a <sys_write>:
{
    8000533a:	7179                	addi	sp,sp,-48
    8000533c:	f406                	sd	ra,40(sp)
    8000533e:	f022                	sd	s0,32(sp)
    80005340:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005342:	fd840593          	addi	a1,s0,-40
    80005346:	4505                	li	a0,1
    80005348:	ffffe097          	auipc	ra,0xffffe
    8000534c:	81c080e7          	jalr	-2020(ra) # 80002b64 <argaddr>
  argint(2, &n);
    80005350:	fe440593          	addi	a1,s0,-28
    80005354:	4509                	li	a0,2
    80005356:	ffffd097          	auipc	ra,0xffffd
    8000535a:	7ee080e7          	jalr	2030(ra) # 80002b44 <argint>
  if(argfd(0, 0, &f) < 0)
    8000535e:	fe840613          	addi	a2,s0,-24
    80005362:	4581                	li	a1,0
    80005364:	4501                	li	a0,0
    80005366:	00000097          	auipc	ra,0x0
    8000536a:	d00080e7          	jalr	-768(ra) # 80005066 <argfd>
    8000536e:	87aa                	mv	a5,a0
    return -1;
    80005370:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005372:	0007cc63          	bltz	a5,8000538a <sys_write+0x50>
  return filewrite(f, p, n);
    80005376:	fe442603          	lw	a2,-28(s0)
    8000537a:	fd843583          	ld	a1,-40(s0)
    8000537e:	fe843503          	ld	a0,-24(s0)
    80005382:	fffff097          	auipc	ra,0xfffff
    80005386:	4b8080e7          	jalr	1208(ra) # 8000483a <filewrite>
}
    8000538a:	70a2                	ld	ra,40(sp)
    8000538c:	7402                	ld	s0,32(sp)
    8000538e:	6145                	addi	sp,sp,48
    80005390:	8082                	ret

0000000080005392 <sys_close>:
{
    80005392:	1101                	addi	sp,sp,-32
    80005394:	ec06                	sd	ra,24(sp)
    80005396:	e822                	sd	s0,16(sp)
    80005398:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000539a:	fe040613          	addi	a2,s0,-32
    8000539e:	fec40593          	addi	a1,s0,-20
    800053a2:	4501                	li	a0,0
    800053a4:	00000097          	auipc	ra,0x0
    800053a8:	cc2080e7          	jalr	-830(ra) # 80005066 <argfd>
    return -1;
    800053ac:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053ae:	02054463          	bltz	a0,800053d6 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053b2:	ffffc097          	auipc	ra,0xffffc
    800053b6:	614080e7          	jalr	1556(ra) # 800019c6 <myproc>
    800053ba:	fec42783          	lw	a5,-20(s0)
    800053be:	07e9                	addi	a5,a5,26
    800053c0:	078e                	slli	a5,a5,0x3
    800053c2:	97aa                	add	a5,a5,a0
    800053c4:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800053c8:	fe043503          	ld	a0,-32(s0)
    800053cc:	fffff097          	auipc	ra,0xfffff
    800053d0:	272080e7          	jalr	626(ra) # 8000463e <fileclose>
  return 0;
    800053d4:	4781                	li	a5,0
}
    800053d6:	853e                	mv	a0,a5
    800053d8:	60e2                	ld	ra,24(sp)
    800053da:	6442                	ld	s0,16(sp)
    800053dc:	6105                	addi	sp,sp,32
    800053de:	8082                	ret

00000000800053e0 <sys_fstat>:
{
    800053e0:	1101                	addi	sp,sp,-32
    800053e2:	ec06                	sd	ra,24(sp)
    800053e4:	e822                	sd	s0,16(sp)
    800053e6:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800053e8:	fe040593          	addi	a1,s0,-32
    800053ec:	4505                	li	a0,1
    800053ee:	ffffd097          	auipc	ra,0xffffd
    800053f2:	776080e7          	jalr	1910(ra) # 80002b64 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800053f6:	fe840613          	addi	a2,s0,-24
    800053fa:	4581                	li	a1,0
    800053fc:	4501                	li	a0,0
    800053fe:	00000097          	auipc	ra,0x0
    80005402:	c68080e7          	jalr	-920(ra) # 80005066 <argfd>
    80005406:	87aa                	mv	a5,a0
    return -1;
    80005408:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000540a:	0007ca63          	bltz	a5,8000541e <sys_fstat+0x3e>
  return filestat(f, st);
    8000540e:	fe043583          	ld	a1,-32(s0)
    80005412:	fe843503          	ld	a0,-24(s0)
    80005416:	fffff097          	auipc	ra,0xfffff
    8000541a:	2f0080e7          	jalr	752(ra) # 80004706 <filestat>
}
    8000541e:	60e2                	ld	ra,24(sp)
    80005420:	6442                	ld	s0,16(sp)
    80005422:	6105                	addi	sp,sp,32
    80005424:	8082                	ret

0000000080005426 <sys_link>:
{
    80005426:	7169                	addi	sp,sp,-304
    80005428:	f606                	sd	ra,296(sp)
    8000542a:	f222                	sd	s0,288(sp)
    8000542c:	ee26                	sd	s1,280(sp)
    8000542e:	ea4a                	sd	s2,272(sp)
    80005430:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005432:	08000613          	li	a2,128
    80005436:	ed040593          	addi	a1,s0,-304
    8000543a:	4501                	li	a0,0
    8000543c:	ffffd097          	auipc	ra,0xffffd
    80005440:	748080e7          	jalr	1864(ra) # 80002b84 <argstr>
    return -1;
    80005444:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005446:	10054e63          	bltz	a0,80005562 <sys_link+0x13c>
    8000544a:	08000613          	li	a2,128
    8000544e:	f5040593          	addi	a1,s0,-176
    80005452:	4505                	li	a0,1
    80005454:	ffffd097          	auipc	ra,0xffffd
    80005458:	730080e7          	jalr	1840(ra) # 80002b84 <argstr>
    return -1;
    8000545c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000545e:	10054263          	bltz	a0,80005562 <sys_link+0x13c>
  begin_op();
    80005462:	fffff097          	auipc	ra,0xfffff
    80005466:	d10080e7          	jalr	-752(ra) # 80004172 <begin_op>
  if((ip = namei(old)) == 0){
    8000546a:	ed040513          	addi	a0,s0,-304
    8000546e:	fffff097          	auipc	ra,0xfffff
    80005472:	ae8080e7          	jalr	-1304(ra) # 80003f56 <namei>
    80005476:	84aa                	mv	s1,a0
    80005478:	c551                	beqz	a0,80005504 <sys_link+0xde>
  ilock(ip);
    8000547a:	ffffe097          	auipc	ra,0xffffe
    8000547e:	336080e7          	jalr	822(ra) # 800037b0 <ilock>
  if(ip->type == T_DIR){
    80005482:	04449703          	lh	a4,68(s1)
    80005486:	4785                	li	a5,1
    80005488:	08f70463          	beq	a4,a5,80005510 <sys_link+0xea>
  ip->nlink++;
    8000548c:	04a4d783          	lhu	a5,74(s1)
    80005490:	2785                	addiw	a5,a5,1
    80005492:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005496:	8526                	mv	a0,s1
    80005498:	ffffe097          	auipc	ra,0xffffe
    8000549c:	24e080e7          	jalr	590(ra) # 800036e6 <iupdate>
  iunlock(ip);
    800054a0:	8526                	mv	a0,s1
    800054a2:	ffffe097          	auipc	ra,0xffffe
    800054a6:	3d0080e7          	jalr	976(ra) # 80003872 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054aa:	fd040593          	addi	a1,s0,-48
    800054ae:	f5040513          	addi	a0,s0,-176
    800054b2:	fffff097          	auipc	ra,0xfffff
    800054b6:	ac2080e7          	jalr	-1342(ra) # 80003f74 <nameiparent>
    800054ba:	892a                	mv	s2,a0
    800054bc:	c935                	beqz	a0,80005530 <sys_link+0x10a>
  ilock(dp);
    800054be:	ffffe097          	auipc	ra,0xffffe
    800054c2:	2f2080e7          	jalr	754(ra) # 800037b0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054c6:	00092703          	lw	a4,0(s2)
    800054ca:	409c                	lw	a5,0(s1)
    800054cc:	04f71d63          	bne	a4,a5,80005526 <sys_link+0x100>
    800054d0:	40d0                	lw	a2,4(s1)
    800054d2:	fd040593          	addi	a1,s0,-48
    800054d6:	854a                	mv	a0,s2
    800054d8:	fffff097          	auipc	ra,0xfffff
    800054dc:	9cc080e7          	jalr	-1588(ra) # 80003ea4 <dirlink>
    800054e0:	04054363          	bltz	a0,80005526 <sys_link+0x100>
  iunlockput(dp);
    800054e4:	854a                	mv	a0,s2
    800054e6:	ffffe097          	auipc	ra,0xffffe
    800054ea:	52c080e7          	jalr	1324(ra) # 80003a12 <iunlockput>
  iput(ip);
    800054ee:	8526                	mv	a0,s1
    800054f0:	ffffe097          	auipc	ra,0xffffe
    800054f4:	47a080e7          	jalr	1146(ra) # 8000396a <iput>
  end_op();
    800054f8:	fffff097          	auipc	ra,0xfffff
    800054fc:	cfa080e7          	jalr	-774(ra) # 800041f2 <end_op>
  return 0;
    80005500:	4781                	li	a5,0
    80005502:	a085                	j	80005562 <sys_link+0x13c>
    end_op();
    80005504:	fffff097          	auipc	ra,0xfffff
    80005508:	cee080e7          	jalr	-786(ra) # 800041f2 <end_op>
    return -1;
    8000550c:	57fd                	li	a5,-1
    8000550e:	a891                	j	80005562 <sys_link+0x13c>
    iunlockput(ip);
    80005510:	8526                	mv	a0,s1
    80005512:	ffffe097          	auipc	ra,0xffffe
    80005516:	500080e7          	jalr	1280(ra) # 80003a12 <iunlockput>
    end_op();
    8000551a:	fffff097          	auipc	ra,0xfffff
    8000551e:	cd8080e7          	jalr	-808(ra) # 800041f2 <end_op>
    return -1;
    80005522:	57fd                	li	a5,-1
    80005524:	a83d                	j	80005562 <sys_link+0x13c>
    iunlockput(dp);
    80005526:	854a                	mv	a0,s2
    80005528:	ffffe097          	auipc	ra,0xffffe
    8000552c:	4ea080e7          	jalr	1258(ra) # 80003a12 <iunlockput>
  ilock(ip);
    80005530:	8526                	mv	a0,s1
    80005532:	ffffe097          	auipc	ra,0xffffe
    80005536:	27e080e7          	jalr	638(ra) # 800037b0 <ilock>
  ip->nlink--;
    8000553a:	04a4d783          	lhu	a5,74(s1)
    8000553e:	37fd                	addiw	a5,a5,-1
    80005540:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005544:	8526                	mv	a0,s1
    80005546:	ffffe097          	auipc	ra,0xffffe
    8000554a:	1a0080e7          	jalr	416(ra) # 800036e6 <iupdate>
  iunlockput(ip);
    8000554e:	8526                	mv	a0,s1
    80005550:	ffffe097          	auipc	ra,0xffffe
    80005554:	4c2080e7          	jalr	1218(ra) # 80003a12 <iunlockput>
  end_op();
    80005558:	fffff097          	auipc	ra,0xfffff
    8000555c:	c9a080e7          	jalr	-870(ra) # 800041f2 <end_op>
  return -1;
    80005560:	57fd                	li	a5,-1
}
    80005562:	853e                	mv	a0,a5
    80005564:	70b2                	ld	ra,296(sp)
    80005566:	7412                	ld	s0,288(sp)
    80005568:	64f2                	ld	s1,280(sp)
    8000556a:	6952                	ld	s2,272(sp)
    8000556c:	6155                	addi	sp,sp,304
    8000556e:	8082                	ret

0000000080005570 <sys_unlink>:
{
    80005570:	7151                	addi	sp,sp,-240
    80005572:	f586                	sd	ra,232(sp)
    80005574:	f1a2                	sd	s0,224(sp)
    80005576:	eda6                	sd	s1,216(sp)
    80005578:	e9ca                	sd	s2,208(sp)
    8000557a:	e5ce                	sd	s3,200(sp)
    8000557c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000557e:	08000613          	li	a2,128
    80005582:	f3040593          	addi	a1,s0,-208
    80005586:	4501                	li	a0,0
    80005588:	ffffd097          	auipc	ra,0xffffd
    8000558c:	5fc080e7          	jalr	1532(ra) # 80002b84 <argstr>
    80005590:	18054163          	bltz	a0,80005712 <sys_unlink+0x1a2>
  begin_op();
    80005594:	fffff097          	auipc	ra,0xfffff
    80005598:	bde080e7          	jalr	-1058(ra) # 80004172 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000559c:	fb040593          	addi	a1,s0,-80
    800055a0:	f3040513          	addi	a0,s0,-208
    800055a4:	fffff097          	auipc	ra,0xfffff
    800055a8:	9d0080e7          	jalr	-1584(ra) # 80003f74 <nameiparent>
    800055ac:	84aa                	mv	s1,a0
    800055ae:	c979                	beqz	a0,80005684 <sys_unlink+0x114>
  ilock(dp);
    800055b0:	ffffe097          	auipc	ra,0xffffe
    800055b4:	200080e7          	jalr	512(ra) # 800037b0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055b8:	00003597          	auipc	a1,0x3
    800055bc:	23058593          	addi	a1,a1,560 # 800087e8 <syscalls+0x2b8>
    800055c0:	fb040513          	addi	a0,s0,-80
    800055c4:	ffffe097          	auipc	ra,0xffffe
    800055c8:	6b6080e7          	jalr	1718(ra) # 80003c7a <namecmp>
    800055cc:	14050a63          	beqz	a0,80005720 <sys_unlink+0x1b0>
    800055d0:	00003597          	auipc	a1,0x3
    800055d4:	22058593          	addi	a1,a1,544 # 800087f0 <syscalls+0x2c0>
    800055d8:	fb040513          	addi	a0,s0,-80
    800055dc:	ffffe097          	auipc	ra,0xffffe
    800055e0:	69e080e7          	jalr	1694(ra) # 80003c7a <namecmp>
    800055e4:	12050e63          	beqz	a0,80005720 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055e8:	f2c40613          	addi	a2,s0,-212
    800055ec:	fb040593          	addi	a1,s0,-80
    800055f0:	8526                	mv	a0,s1
    800055f2:	ffffe097          	auipc	ra,0xffffe
    800055f6:	6a2080e7          	jalr	1698(ra) # 80003c94 <dirlookup>
    800055fa:	892a                	mv	s2,a0
    800055fc:	12050263          	beqz	a0,80005720 <sys_unlink+0x1b0>
  ilock(ip);
    80005600:	ffffe097          	auipc	ra,0xffffe
    80005604:	1b0080e7          	jalr	432(ra) # 800037b0 <ilock>
  if(ip->nlink < 1)
    80005608:	04a91783          	lh	a5,74(s2)
    8000560c:	08f05263          	blez	a5,80005690 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005610:	04491703          	lh	a4,68(s2)
    80005614:	4785                	li	a5,1
    80005616:	08f70563          	beq	a4,a5,800056a0 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000561a:	4641                	li	a2,16
    8000561c:	4581                	li	a1,0
    8000561e:	fc040513          	addi	a0,s0,-64
    80005622:	ffffb097          	auipc	ra,0xffffb
    80005626:	6c4080e7          	jalr	1732(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000562a:	4741                	li	a4,16
    8000562c:	f2c42683          	lw	a3,-212(s0)
    80005630:	fc040613          	addi	a2,s0,-64
    80005634:	4581                	li	a1,0
    80005636:	8526                	mv	a0,s1
    80005638:	ffffe097          	auipc	ra,0xffffe
    8000563c:	524080e7          	jalr	1316(ra) # 80003b5c <writei>
    80005640:	47c1                	li	a5,16
    80005642:	0af51563          	bne	a0,a5,800056ec <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005646:	04491703          	lh	a4,68(s2)
    8000564a:	4785                	li	a5,1
    8000564c:	0af70863          	beq	a4,a5,800056fc <sys_unlink+0x18c>
  iunlockput(dp);
    80005650:	8526                	mv	a0,s1
    80005652:	ffffe097          	auipc	ra,0xffffe
    80005656:	3c0080e7          	jalr	960(ra) # 80003a12 <iunlockput>
  ip->nlink--;
    8000565a:	04a95783          	lhu	a5,74(s2)
    8000565e:	37fd                	addiw	a5,a5,-1
    80005660:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005664:	854a                	mv	a0,s2
    80005666:	ffffe097          	auipc	ra,0xffffe
    8000566a:	080080e7          	jalr	128(ra) # 800036e6 <iupdate>
  iunlockput(ip);
    8000566e:	854a                	mv	a0,s2
    80005670:	ffffe097          	auipc	ra,0xffffe
    80005674:	3a2080e7          	jalr	930(ra) # 80003a12 <iunlockput>
  end_op();
    80005678:	fffff097          	auipc	ra,0xfffff
    8000567c:	b7a080e7          	jalr	-1158(ra) # 800041f2 <end_op>
  return 0;
    80005680:	4501                	li	a0,0
    80005682:	a84d                	j	80005734 <sys_unlink+0x1c4>
    end_op();
    80005684:	fffff097          	auipc	ra,0xfffff
    80005688:	b6e080e7          	jalr	-1170(ra) # 800041f2 <end_op>
    return -1;
    8000568c:	557d                	li	a0,-1
    8000568e:	a05d                	j	80005734 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005690:	00003517          	auipc	a0,0x3
    80005694:	16850513          	addi	a0,a0,360 # 800087f8 <syscalls+0x2c8>
    80005698:	ffffb097          	auipc	ra,0xffffb
    8000569c:	eac080e7          	jalr	-340(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056a0:	04c92703          	lw	a4,76(s2)
    800056a4:	02000793          	li	a5,32
    800056a8:	f6e7f9e3          	bgeu	a5,a4,8000561a <sys_unlink+0xaa>
    800056ac:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056b0:	4741                	li	a4,16
    800056b2:	86ce                	mv	a3,s3
    800056b4:	f1840613          	addi	a2,s0,-232
    800056b8:	4581                	li	a1,0
    800056ba:	854a                	mv	a0,s2
    800056bc:	ffffe097          	auipc	ra,0xffffe
    800056c0:	3a8080e7          	jalr	936(ra) # 80003a64 <readi>
    800056c4:	47c1                	li	a5,16
    800056c6:	00f51b63          	bne	a0,a5,800056dc <sys_unlink+0x16c>
    if(de.inum != 0)
    800056ca:	f1845783          	lhu	a5,-232(s0)
    800056ce:	e7a1                	bnez	a5,80005716 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056d0:	29c1                	addiw	s3,s3,16
    800056d2:	04c92783          	lw	a5,76(s2)
    800056d6:	fcf9ede3          	bltu	s3,a5,800056b0 <sys_unlink+0x140>
    800056da:	b781                	j	8000561a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056dc:	00003517          	auipc	a0,0x3
    800056e0:	13450513          	addi	a0,a0,308 # 80008810 <syscalls+0x2e0>
    800056e4:	ffffb097          	auipc	ra,0xffffb
    800056e8:	e60080e7          	jalr	-416(ra) # 80000544 <panic>
    panic("unlink: writei");
    800056ec:	00003517          	auipc	a0,0x3
    800056f0:	13c50513          	addi	a0,a0,316 # 80008828 <syscalls+0x2f8>
    800056f4:	ffffb097          	auipc	ra,0xffffb
    800056f8:	e50080e7          	jalr	-432(ra) # 80000544 <panic>
    dp->nlink--;
    800056fc:	04a4d783          	lhu	a5,74(s1)
    80005700:	37fd                	addiw	a5,a5,-1
    80005702:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005706:	8526                	mv	a0,s1
    80005708:	ffffe097          	auipc	ra,0xffffe
    8000570c:	fde080e7          	jalr	-34(ra) # 800036e6 <iupdate>
    80005710:	b781                	j	80005650 <sys_unlink+0xe0>
    return -1;
    80005712:	557d                	li	a0,-1
    80005714:	a005                	j	80005734 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005716:	854a                	mv	a0,s2
    80005718:	ffffe097          	auipc	ra,0xffffe
    8000571c:	2fa080e7          	jalr	762(ra) # 80003a12 <iunlockput>
  iunlockput(dp);
    80005720:	8526                	mv	a0,s1
    80005722:	ffffe097          	auipc	ra,0xffffe
    80005726:	2f0080e7          	jalr	752(ra) # 80003a12 <iunlockput>
  end_op();
    8000572a:	fffff097          	auipc	ra,0xfffff
    8000572e:	ac8080e7          	jalr	-1336(ra) # 800041f2 <end_op>
  return -1;
    80005732:	557d                	li	a0,-1
}
    80005734:	70ae                	ld	ra,232(sp)
    80005736:	740e                	ld	s0,224(sp)
    80005738:	64ee                	ld	s1,216(sp)
    8000573a:	694e                	ld	s2,208(sp)
    8000573c:	69ae                	ld	s3,200(sp)
    8000573e:	616d                	addi	sp,sp,240
    80005740:	8082                	ret

0000000080005742 <sys_open>:

uint64
sys_open(void)
{
    80005742:	7131                	addi	sp,sp,-192
    80005744:	fd06                	sd	ra,184(sp)
    80005746:	f922                	sd	s0,176(sp)
    80005748:	f526                	sd	s1,168(sp)
    8000574a:	f14a                	sd	s2,160(sp)
    8000574c:	ed4e                	sd	s3,152(sp)
    8000574e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005750:	f4c40593          	addi	a1,s0,-180
    80005754:	4505                	li	a0,1
    80005756:	ffffd097          	auipc	ra,0xffffd
    8000575a:	3ee080e7          	jalr	1006(ra) # 80002b44 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000575e:	08000613          	li	a2,128
    80005762:	f5040593          	addi	a1,s0,-176
    80005766:	4501                	li	a0,0
    80005768:	ffffd097          	auipc	ra,0xffffd
    8000576c:	41c080e7          	jalr	1052(ra) # 80002b84 <argstr>
    80005770:	87aa                	mv	a5,a0
    return -1;
    80005772:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005774:	0a07c963          	bltz	a5,80005826 <sys_open+0xe4>

  begin_op();
    80005778:	fffff097          	auipc	ra,0xfffff
    8000577c:	9fa080e7          	jalr	-1542(ra) # 80004172 <begin_op>

  if(omode & O_CREATE){
    80005780:	f4c42783          	lw	a5,-180(s0)
    80005784:	2007f793          	andi	a5,a5,512
    80005788:	cfc5                	beqz	a5,80005840 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000578a:	4681                	li	a3,0
    8000578c:	4601                	li	a2,0
    8000578e:	4589                	li	a1,2
    80005790:	f5040513          	addi	a0,s0,-176
    80005794:	00000097          	auipc	ra,0x0
    80005798:	974080e7          	jalr	-1676(ra) # 80005108 <create>
    8000579c:	84aa                	mv	s1,a0
    if(ip == 0){
    8000579e:	c959                	beqz	a0,80005834 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057a0:	04449703          	lh	a4,68(s1)
    800057a4:	478d                	li	a5,3
    800057a6:	00f71763          	bne	a4,a5,800057b4 <sys_open+0x72>
    800057aa:	0464d703          	lhu	a4,70(s1)
    800057ae:	47a5                	li	a5,9
    800057b0:	0ce7ed63          	bltu	a5,a4,8000588a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057b4:	fffff097          	auipc	ra,0xfffff
    800057b8:	dce080e7          	jalr	-562(ra) # 80004582 <filealloc>
    800057bc:	89aa                	mv	s3,a0
    800057be:	10050363          	beqz	a0,800058c4 <sys_open+0x182>
    800057c2:	00000097          	auipc	ra,0x0
    800057c6:	904080e7          	jalr	-1788(ra) # 800050c6 <fdalloc>
    800057ca:	892a                	mv	s2,a0
    800057cc:	0e054763          	bltz	a0,800058ba <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057d0:	04449703          	lh	a4,68(s1)
    800057d4:	478d                	li	a5,3
    800057d6:	0cf70563          	beq	a4,a5,800058a0 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057da:	4789                	li	a5,2
    800057dc:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057e0:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057e4:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057e8:	f4c42783          	lw	a5,-180(s0)
    800057ec:	0017c713          	xori	a4,a5,1
    800057f0:	8b05                	andi	a4,a4,1
    800057f2:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057f6:	0037f713          	andi	a4,a5,3
    800057fa:	00e03733          	snez	a4,a4
    800057fe:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005802:	4007f793          	andi	a5,a5,1024
    80005806:	c791                	beqz	a5,80005812 <sys_open+0xd0>
    80005808:	04449703          	lh	a4,68(s1)
    8000580c:	4789                	li	a5,2
    8000580e:	0af70063          	beq	a4,a5,800058ae <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005812:	8526                	mv	a0,s1
    80005814:	ffffe097          	auipc	ra,0xffffe
    80005818:	05e080e7          	jalr	94(ra) # 80003872 <iunlock>
  end_op();
    8000581c:	fffff097          	auipc	ra,0xfffff
    80005820:	9d6080e7          	jalr	-1578(ra) # 800041f2 <end_op>

  return fd;
    80005824:	854a                	mv	a0,s2
}
    80005826:	70ea                	ld	ra,184(sp)
    80005828:	744a                	ld	s0,176(sp)
    8000582a:	74aa                	ld	s1,168(sp)
    8000582c:	790a                	ld	s2,160(sp)
    8000582e:	69ea                	ld	s3,152(sp)
    80005830:	6129                	addi	sp,sp,192
    80005832:	8082                	ret
      end_op();
    80005834:	fffff097          	auipc	ra,0xfffff
    80005838:	9be080e7          	jalr	-1602(ra) # 800041f2 <end_op>
      return -1;
    8000583c:	557d                	li	a0,-1
    8000583e:	b7e5                	j	80005826 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005840:	f5040513          	addi	a0,s0,-176
    80005844:	ffffe097          	auipc	ra,0xffffe
    80005848:	712080e7          	jalr	1810(ra) # 80003f56 <namei>
    8000584c:	84aa                	mv	s1,a0
    8000584e:	c905                	beqz	a0,8000587e <sys_open+0x13c>
    ilock(ip);
    80005850:	ffffe097          	auipc	ra,0xffffe
    80005854:	f60080e7          	jalr	-160(ra) # 800037b0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005858:	04449703          	lh	a4,68(s1)
    8000585c:	4785                	li	a5,1
    8000585e:	f4f711e3          	bne	a4,a5,800057a0 <sys_open+0x5e>
    80005862:	f4c42783          	lw	a5,-180(s0)
    80005866:	d7b9                	beqz	a5,800057b4 <sys_open+0x72>
      iunlockput(ip);
    80005868:	8526                	mv	a0,s1
    8000586a:	ffffe097          	auipc	ra,0xffffe
    8000586e:	1a8080e7          	jalr	424(ra) # 80003a12 <iunlockput>
      end_op();
    80005872:	fffff097          	auipc	ra,0xfffff
    80005876:	980080e7          	jalr	-1664(ra) # 800041f2 <end_op>
      return -1;
    8000587a:	557d                	li	a0,-1
    8000587c:	b76d                	j	80005826 <sys_open+0xe4>
      end_op();
    8000587e:	fffff097          	auipc	ra,0xfffff
    80005882:	974080e7          	jalr	-1676(ra) # 800041f2 <end_op>
      return -1;
    80005886:	557d                	li	a0,-1
    80005888:	bf79                	j	80005826 <sys_open+0xe4>
    iunlockput(ip);
    8000588a:	8526                	mv	a0,s1
    8000588c:	ffffe097          	auipc	ra,0xffffe
    80005890:	186080e7          	jalr	390(ra) # 80003a12 <iunlockput>
    end_op();
    80005894:	fffff097          	auipc	ra,0xfffff
    80005898:	95e080e7          	jalr	-1698(ra) # 800041f2 <end_op>
    return -1;
    8000589c:	557d                	li	a0,-1
    8000589e:	b761                	j	80005826 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800058a0:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058a4:	04649783          	lh	a5,70(s1)
    800058a8:	02f99223          	sh	a5,36(s3)
    800058ac:	bf25                	j	800057e4 <sys_open+0xa2>
    itrunc(ip);
    800058ae:	8526                	mv	a0,s1
    800058b0:	ffffe097          	auipc	ra,0xffffe
    800058b4:	00e080e7          	jalr	14(ra) # 800038be <itrunc>
    800058b8:	bfa9                	j	80005812 <sys_open+0xd0>
      fileclose(f);
    800058ba:	854e                	mv	a0,s3
    800058bc:	fffff097          	auipc	ra,0xfffff
    800058c0:	d82080e7          	jalr	-638(ra) # 8000463e <fileclose>
    iunlockput(ip);
    800058c4:	8526                	mv	a0,s1
    800058c6:	ffffe097          	auipc	ra,0xffffe
    800058ca:	14c080e7          	jalr	332(ra) # 80003a12 <iunlockput>
    end_op();
    800058ce:	fffff097          	auipc	ra,0xfffff
    800058d2:	924080e7          	jalr	-1756(ra) # 800041f2 <end_op>
    return -1;
    800058d6:	557d                	li	a0,-1
    800058d8:	b7b9                	j	80005826 <sys_open+0xe4>

00000000800058da <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058da:	7175                	addi	sp,sp,-144
    800058dc:	e506                	sd	ra,136(sp)
    800058de:	e122                	sd	s0,128(sp)
    800058e0:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058e2:	fffff097          	auipc	ra,0xfffff
    800058e6:	890080e7          	jalr	-1904(ra) # 80004172 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058ea:	08000613          	li	a2,128
    800058ee:	f7040593          	addi	a1,s0,-144
    800058f2:	4501                	li	a0,0
    800058f4:	ffffd097          	auipc	ra,0xffffd
    800058f8:	290080e7          	jalr	656(ra) # 80002b84 <argstr>
    800058fc:	02054963          	bltz	a0,8000592e <sys_mkdir+0x54>
    80005900:	4681                	li	a3,0
    80005902:	4601                	li	a2,0
    80005904:	4585                	li	a1,1
    80005906:	f7040513          	addi	a0,s0,-144
    8000590a:	fffff097          	auipc	ra,0xfffff
    8000590e:	7fe080e7          	jalr	2046(ra) # 80005108 <create>
    80005912:	cd11                	beqz	a0,8000592e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005914:	ffffe097          	auipc	ra,0xffffe
    80005918:	0fe080e7          	jalr	254(ra) # 80003a12 <iunlockput>
  end_op();
    8000591c:	fffff097          	auipc	ra,0xfffff
    80005920:	8d6080e7          	jalr	-1834(ra) # 800041f2 <end_op>
  return 0;
    80005924:	4501                	li	a0,0
}
    80005926:	60aa                	ld	ra,136(sp)
    80005928:	640a                	ld	s0,128(sp)
    8000592a:	6149                	addi	sp,sp,144
    8000592c:	8082                	ret
    end_op();
    8000592e:	fffff097          	auipc	ra,0xfffff
    80005932:	8c4080e7          	jalr	-1852(ra) # 800041f2 <end_op>
    return -1;
    80005936:	557d                	li	a0,-1
    80005938:	b7fd                	j	80005926 <sys_mkdir+0x4c>

000000008000593a <sys_mknod>:

uint64
sys_mknod(void)
{
    8000593a:	7135                	addi	sp,sp,-160
    8000593c:	ed06                	sd	ra,152(sp)
    8000593e:	e922                	sd	s0,144(sp)
    80005940:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005942:	fffff097          	auipc	ra,0xfffff
    80005946:	830080e7          	jalr	-2000(ra) # 80004172 <begin_op>
  argint(1, &major);
    8000594a:	f6c40593          	addi	a1,s0,-148
    8000594e:	4505                	li	a0,1
    80005950:	ffffd097          	auipc	ra,0xffffd
    80005954:	1f4080e7          	jalr	500(ra) # 80002b44 <argint>
  argint(2, &minor);
    80005958:	f6840593          	addi	a1,s0,-152
    8000595c:	4509                	li	a0,2
    8000595e:	ffffd097          	auipc	ra,0xffffd
    80005962:	1e6080e7          	jalr	486(ra) # 80002b44 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005966:	08000613          	li	a2,128
    8000596a:	f7040593          	addi	a1,s0,-144
    8000596e:	4501                	li	a0,0
    80005970:	ffffd097          	auipc	ra,0xffffd
    80005974:	214080e7          	jalr	532(ra) # 80002b84 <argstr>
    80005978:	02054b63          	bltz	a0,800059ae <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000597c:	f6841683          	lh	a3,-152(s0)
    80005980:	f6c41603          	lh	a2,-148(s0)
    80005984:	458d                	li	a1,3
    80005986:	f7040513          	addi	a0,s0,-144
    8000598a:	fffff097          	auipc	ra,0xfffff
    8000598e:	77e080e7          	jalr	1918(ra) # 80005108 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005992:	cd11                	beqz	a0,800059ae <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005994:	ffffe097          	auipc	ra,0xffffe
    80005998:	07e080e7          	jalr	126(ra) # 80003a12 <iunlockput>
  end_op();
    8000599c:	fffff097          	auipc	ra,0xfffff
    800059a0:	856080e7          	jalr	-1962(ra) # 800041f2 <end_op>
  return 0;
    800059a4:	4501                	li	a0,0
}
    800059a6:	60ea                	ld	ra,152(sp)
    800059a8:	644a                	ld	s0,144(sp)
    800059aa:	610d                	addi	sp,sp,160
    800059ac:	8082                	ret
    end_op();
    800059ae:	fffff097          	auipc	ra,0xfffff
    800059b2:	844080e7          	jalr	-1980(ra) # 800041f2 <end_op>
    return -1;
    800059b6:	557d                	li	a0,-1
    800059b8:	b7fd                	j	800059a6 <sys_mknod+0x6c>

00000000800059ba <sys_chdir>:

uint64
sys_chdir(void)
{
    800059ba:	7135                	addi	sp,sp,-160
    800059bc:	ed06                	sd	ra,152(sp)
    800059be:	e922                	sd	s0,144(sp)
    800059c0:	e526                	sd	s1,136(sp)
    800059c2:	e14a                	sd	s2,128(sp)
    800059c4:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059c6:	ffffc097          	auipc	ra,0xffffc
    800059ca:	000080e7          	jalr	ra # 800019c6 <myproc>
    800059ce:	892a                	mv	s2,a0
  
  begin_op();
    800059d0:	ffffe097          	auipc	ra,0xffffe
    800059d4:	7a2080e7          	jalr	1954(ra) # 80004172 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059d8:	08000613          	li	a2,128
    800059dc:	f6040593          	addi	a1,s0,-160
    800059e0:	4501                	li	a0,0
    800059e2:	ffffd097          	auipc	ra,0xffffd
    800059e6:	1a2080e7          	jalr	418(ra) # 80002b84 <argstr>
    800059ea:	04054b63          	bltz	a0,80005a40 <sys_chdir+0x86>
    800059ee:	f6040513          	addi	a0,s0,-160
    800059f2:	ffffe097          	auipc	ra,0xffffe
    800059f6:	564080e7          	jalr	1380(ra) # 80003f56 <namei>
    800059fa:	84aa                	mv	s1,a0
    800059fc:	c131                	beqz	a0,80005a40 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059fe:	ffffe097          	auipc	ra,0xffffe
    80005a02:	db2080e7          	jalr	-590(ra) # 800037b0 <ilock>
  if(ip->type != T_DIR){
    80005a06:	04449703          	lh	a4,68(s1)
    80005a0a:	4785                	li	a5,1
    80005a0c:	04f71063          	bne	a4,a5,80005a4c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a10:	8526                	mv	a0,s1
    80005a12:	ffffe097          	auipc	ra,0xffffe
    80005a16:	e60080e7          	jalr	-416(ra) # 80003872 <iunlock>
  iput(p->cwd);
    80005a1a:	15093503          	ld	a0,336(s2)
    80005a1e:	ffffe097          	auipc	ra,0xffffe
    80005a22:	f4c080e7          	jalr	-180(ra) # 8000396a <iput>
  end_op();
    80005a26:	ffffe097          	auipc	ra,0xffffe
    80005a2a:	7cc080e7          	jalr	1996(ra) # 800041f2 <end_op>
  p->cwd = ip;
    80005a2e:	14993823          	sd	s1,336(s2)
  return 0;
    80005a32:	4501                	li	a0,0
}
    80005a34:	60ea                	ld	ra,152(sp)
    80005a36:	644a                	ld	s0,144(sp)
    80005a38:	64aa                	ld	s1,136(sp)
    80005a3a:	690a                	ld	s2,128(sp)
    80005a3c:	610d                	addi	sp,sp,160
    80005a3e:	8082                	ret
    end_op();
    80005a40:	ffffe097          	auipc	ra,0xffffe
    80005a44:	7b2080e7          	jalr	1970(ra) # 800041f2 <end_op>
    return -1;
    80005a48:	557d                	li	a0,-1
    80005a4a:	b7ed                	j	80005a34 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a4c:	8526                	mv	a0,s1
    80005a4e:	ffffe097          	auipc	ra,0xffffe
    80005a52:	fc4080e7          	jalr	-60(ra) # 80003a12 <iunlockput>
    end_op();
    80005a56:	ffffe097          	auipc	ra,0xffffe
    80005a5a:	79c080e7          	jalr	1948(ra) # 800041f2 <end_op>
    return -1;
    80005a5e:	557d                	li	a0,-1
    80005a60:	bfd1                	j	80005a34 <sys_chdir+0x7a>

0000000080005a62 <sys_exec>:

uint64
sys_exec(void)
{
    80005a62:	7145                	addi	sp,sp,-464
    80005a64:	e786                	sd	ra,456(sp)
    80005a66:	e3a2                	sd	s0,448(sp)
    80005a68:	ff26                	sd	s1,440(sp)
    80005a6a:	fb4a                	sd	s2,432(sp)
    80005a6c:	f74e                	sd	s3,424(sp)
    80005a6e:	f352                	sd	s4,416(sp)
    80005a70:	ef56                	sd	s5,408(sp)
    80005a72:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005a74:	e3840593          	addi	a1,s0,-456
    80005a78:	4505                	li	a0,1
    80005a7a:	ffffd097          	auipc	ra,0xffffd
    80005a7e:	0ea080e7          	jalr	234(ra) # 80002b64 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005a82:	08000613          	li	a2,128
    80005a86:	f4040593          	addi	a1,s0,-192
    80005a8a:	4501                	li	a0,0
    80005a8c:	ffffd097          	auipc	ra,0xffffd
    80005a90:	0f8080e7          	jalr	248(ra) # 80002b84 <argstr>
    80005a94:	87aa                	mv	a5,a0
    return -1;
    80005a96:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005a98:	0c07c263          	bltz	a5,80005b5c <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a9c:	10000613          	li	a2,256
    80005aa0:	4581                	li	a1,0
    80005aa2:	e4040513          	addi	a0,s0,-448
    80005aa6:	ffffb097          	auipc	ra,0xffffb
    80005aaa:	240080e7          	jalr	576(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005aae:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ab2:	89a6                	mv	s3,s1
    80005ab4:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ab6:	02000a13          	li	s4,32
    80005aba:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005abe:	00391513          	slli	a0,s2,0x3
    80005ac2:	e3040593          	addi	a1,s0,-464
    80005ac6:	e3843783          	ld	a5,-456(s0)
    80005aca:	953e                	add	a0,a0,a5
    80005acc:	ffffd097          	auipc	ra,0xffffd
    80005ad0:	fda080e7          	jalr	-38(ra) # 80002aa6 <fetchaddr>
    80005ad4:	02054a63          	bltz	a0,80005b08 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005ad8:	e3043783          	ld	a5,-464(s0)
    80005adc:	c3b9                	beqz	a5,80005b22 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ade:	ffffb097          	auipc	ra,0xffffb
    80005ae2:	01c080e7          	jalr	28(ra) # 80000afa <kalloc>
    80005ae6:	85aa                	mv	a1,a0
    80005ae8:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005aec:	cd11                	beqz	a0,80005b08 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005aee:	6605                	lui	a2,0x1
    80005af0:	e3043503          	ld	a0,-464(s0)
    80005af4:	ffffd097          	auipc	ra,0xffffd
    80005af8:	004080e7          	jalr	4(ra) # 80002af8 <fetchstr>
    80005afc:	00054663          	bltz	a0,80005b08 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005b00:	0905                	addi	s2,s2,1
    80005b02:	09a1                	addi	s3,s3,8
    80005b04:	fb491be3          	bne	s2,s4,80005aba <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b08:	10048913          	addi	s2,s1,256
    80005b0c:	6088                	ld	a0,0(s1)
    80005b0e:	c531                	beqz	a0,80005b5a <sys_exec+0xf8>
    kfree(argv[i]);
    80005b10:	ffffb097          	auipc	ra,0xffffb
    80005b14:	eee080e7          	jalr	-274(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b18:	04a1                	addi	s1,s1,8
    80005b1a:	ff2499e3          	bne	s1,s2,80005b0c <sys_exec+0xaa>
  return -1;
    80005b1e:	557d                	li	a0,-1
    80005b20:	a835                	j	80005b5c <sys_exec+0xfa>
      argv[i] = 0;
    80005b22:	0a8e                	slli	s5,s5,0x3
    80005b24:	fc040793          	addi	a5,s0,-64
    80005b28:	9abe                	add	s5,s5,a5
    80005b2a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b2e:	e4040593          	addi	a1,s0,-448
    80005b32:	f4040513          	addi	a0,s0,-192
    80005b36:	fffff097          	auipc	ra,0xfffff
    80005b3a:	190080e7          	jalr	400(ra) # 80004cc6 <exec>
    80005b3e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b40:	10048993          	addi	s3,s1,256
    80005b44:	6088                	ld	a0,0(s1)
    80005b46:	c901                	beqz	a0,80005b56 <sys_exec+0xf4>
    kfree(argv[i]);
    80005b48:	ffffb097          	auipc	ra,0xffffb
    80005b4c:	eb6080e7          	jalr	-330(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b50:	04a1                	addi	s1,s1,8
    80005b52:	ff3499e3          	bne	s1,s3,80005b44 <sys_exec+0xe2>
  return ret;
    80005b56:	854a                	mv	a0,s2
    80005b58:	a011                	j	80005b5c <sys_exec+0xfa>
  return -1;
    80005b5a:	557d                	li	a0,-1
}
    80005b5c:	60be                	ld	ra,456(sp)
    80005b5e:	641e                	ld	s0,448(sp)
    80005b60:	74fa                	ld	s1,440(sp)
    80005b62:	795a                	ld	s2,432(sp)
    80005b64:	79ba                	ld	s3,424(sp)
    80005b66:	7a1a                	ld	s4,416(sp)
    80005b68:	6afa                	ld	s5,408(sp)
    80005b6a:	6179                	addi	sp,sp,464
    80005b6c:	8082                	ret

0000000080005b6e <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b6e:	7139                	addi	sp,sp,-64
    80005b70:	fc06                	sd	ra,56(sp)
    80005b72:	f822                	sd	s0,48(sp)
    80005b74:	f426                	sd	s1,40(sp)
    80005b76:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b78:	ffffc097          	auipc	ra,0xffffc
    80005b7c:	e4e080e7          	jalr	-434(ra) # 800019c6 <myproc>
    80005b80:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005b82:	fd840593          	addi	a1,s0,-40
    80005b86:	4501                	li	a0,0
    80005b88:	ffffd097          	auipc	ra,0xffffd
    80005b8c:	fdc080e7          	jalr	-36(ra) # 80002b64 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005b90:	fc840593          	addi	a1,s0,-56
    80005b94:	fd040513          	addi	a0,s0,-48
    80005b98:	fffff097          	auipc	ra,0xfffff
    80005b9c:	dd6080e7          	jalr	-554(ra) # 8000496e <pipealloc>
    return -1;
    80005ba0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ba2:	0c054463          	bltz	a0,80005c6a <sys_pipe+0xfc>
  fd0 = -1;
    80005ba6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005baa:	fd043503          	ld	a0,-48(s0)
    80005bae:	fffff097          	auipc	ra,0xfffff
    80005bb2:	518080e7          	jalr	1304(ra) # 800050c6 <fdalloc>
    80005bb6:	fca42223          	sw	a0,-60(s0)
    80005bba:	08054b63          	bltz	a0,80005c50 <sys_pipe+0xe2>
    80005bbe:	fc843503          	ld	a0,-56(s0)
    80005bc2:	fffff097          	auipc	ra,0xfffff
    80005bc6:	504080e7          	jalr	1284(ra) # 800050c6 <fdalloc>
    80005bca:	fca42023          	sw	a0,-64(s0)
    80005bce:	06054863          	bltz	a0,80005c3e <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bd2:	4691                	li	a3,4
    80005bd4:	fc440613          	addi	a2,s0,-60
    80005bd8:	fd843583          	ld	a1,-40(s0)
    80005bdc:	68a8                	ld	a0,80(s1)
    80005bde:	ffffc097          	auipc	ra,0xffffc
    80005be2:	aa6080e7          	jalr	-1370(ra) # 80001684 <copyout>
    80005be6:	02054063          	bltz	a0,80005c06 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bea:	4691                	li	a3,4
    80005bec:	fc040613          	addi	a2,s0,-64
    80005bf0:	fd843583          	ld	a1,-40(s0)
    80005bf4:	0591                	addi	a1,a1,4
    80005bf6:	68a8                	ld	a0,80(s1)
    80005bf8:	ffffc097          	auipc	ra,0xffffc
    80005bfc:	a8c080e7          	jalr	-1396(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c00:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c02:	06055463          	bgez	a0,80005c6a <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005c06:	fc442783          	lw	a5,-60(s0)
    80005c0a:	07e9                	addi	a5,a5,26
    80005c0c:	078e                	slli	a5,a5,0x3
    80005c0e:	97a6                	add	a5,a5,s1
    80005c10:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c14:	fc042503          	lw	a0,-64(s0)
    80005c18:	0569                	addi	a0,a0,26
    80005c1a:	050e                	slli	a0,a0,0x3
    80005c1c:	94aa                	add	s1,s1,a0
    80005c1e:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c22:	fd043503          	ld	a0,-48(s0)
    80005c26:	fffff097          	auipc	ra,0xfffff
    80005c2a:	a18080e7          	jalr	-1512(ra) # 8000463e <fileclose>
    fileclose(wf);
    80005c2e:	fc843503          	ld	a0,-56(s0)
    80005c32:	fffff097          	auipc	ra,0xfffff
    80005c36:	a0c080e7          	jalr	-1524(ra) # 8000463e <fileclose>
    return -1;
    80005c3a:	57fd                	li	a5,-1
    80005c3c:	a03d                	j	80005c6a <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005c3e:	fc442783          	lw	a5,-60(s0)
    80005c42:	0007c763          	bltz	a5,80005c50 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005c46:	07e9                	addi	a5,a5,26
    80005c48:	078e                	slli	a5,a5,0x3
    80005c4a:	94be                	add	s1,s1,a5
    80005c4c:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c50:	fd043503          	ld	a0,-48(s0)
    80005c54:	fffff097          	auipc	ra,0xfffff
    80005c58:	9ea080e7          	jalr	-1558(ra) # 8000463e <fileclose>
    fileclose(wf);
    80005c5c:	fc843503          	ld	a0,-56(s0)
    80005c60:	fffff097          	auipc	ra,0xfffff
    80005c64:	9de080e7          	jalr	-1570(ra) # 8000463e <fileclose>
    return -1;
    80005c68:	57fd                	li	a5,-1
}
    80005c6a:	853e                	mv	a0,a5
    80005c6c:	70e2                	ld	ra,56(sp)
    80005c6e:	7442                	ld	s0,48(sp)
    80005c70:	74a2                	ld	s1,40(sp)
    80005c72:	6121                	addi	sp,sp,64
    80005c74:	8082                	ret
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
    80005cc0:	cb3fc0ef          	jal	ra,80002972 <kerneltrap>
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
