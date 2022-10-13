
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	b4013103          	ld	sp,-1216(sp) # 80009b40 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000056:	b4e70713          	addi	a4,a4,-1202 # 80009ba0 <timer_scratch>
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
    80000068:	77c78793          	addi	a5,a5,1916 # 800067e0 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87f7>
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
    80000130:	8ce080e7          	jalr	-1842(ra) # 800029fa <either_copyin>
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
    80000190:	b5450513          	addi	a0,a0,-1196 # 80011ce0 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a56080e7          	jalr	-1450(ra) # 80000bea <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00012497          	auipc	s1,0x12
    800001a0:	b4448493          	addi	s1,s1,-1212 # 80011ce0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00012917          	auipc	s2,0x12
    800001aa:	bd290913          	addi	s2,s2,-1070 # 80011d78 <cons+0x98>
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
    800001d0:	678080e7          	jalr	1656(ra) # 80002844 <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	26a080e7          	jalr	618(ra) # 80002444 <sleep>
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
    8000021a:	78e080e7          	jalr	1934(ra) # 800029a4 <either_copyout>
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
    8000022e:	ab650513          	addi	a0,a0,-1354 # 80011ce0 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a6c080e7          	jalr	-1428(ra) # 80000c9e <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00012517          	auipc	a0,0x12
    80000244:	aa050513          	addi	a0,a0,-1376 # 80011ce0 <cons>
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
    8000027c:	b0f72023          	sw	a5,-1280(a4) # 80011d78 <cons+0x98>
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
    800002d6:	a0e50513          	addi	a0,a0,-1522 # 80011ce0 <cons>
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
    800002fc:	758080e7          	jalr	1880(ra) # 80002a50 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00012517          	auipc	a0,0x12
    80000304:	9e050513          	addi	a0,a0,-1568 # 80011ce0 <cons>
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
    80000328:	9bc70713          	addi	a4,a4,-1604 # 80011ce0 <cons>
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
    80000352:	99278793          	addi	a5,a5,-1646 # 80011ce0 <cons>
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
    80000380:	9fc7a783          	lw	a5,-1540(a5) # 80011d78 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00012717          	auipc	a4,0x12
    80000394:	95070713          	addi	a4,a4,-1712 # 80011ce0 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00012497          	auipc	s1,0x12
    800003a4:	94048493          	addi	s1,s1,-1728 # 80011ce0 <cons>
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
    800003e0:	90470713          	addi	a4,a4,-1788 # 80011ce0 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00012717          	auipc	a4,0x12
    800003f6:	98f72723          	sw	a5,-1650(a4) # 80011d80 <cons+0xa0>
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
    8000041c:	8c878793          	addi	a5,a5,-1848 # 80011ce0 <cons>
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
    80000440:	94c7a023          	sw	a2,-1728(a5) # 80011d7c <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00012517          	auipc	a0,0x12
    80000448:	93450513          	addi	a0,a0,-1740 # 80011d78 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	1a8080e7          	jalr	424(ra) # 800025f4 <wakeup>
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
    8000046a:	87a50513          	addi	a0,a0,-1926 # 80011ce0 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	6ec080e7          	jalr	1772(ra) # 80000b5a <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00023797          	auipc	a5,0x23
    80000482:	67278793          	addi	a5,a5,1650 # 80023af0 <devsw>
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
    80000554:	8407a823          	sw	zero,-1968(a5) # 80011da0 <pr+0x18>
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
    80000588:	5cf72e23          	sw	a5,1500(a4) # 80009b60 <panicked>
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
    800005c4:	7e0dad83          	lw	s11,2016(s11) # 80011da0 <pr+0x18>
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
    80000602:	78a50513          	addi	a0,a0,1930 # 80011d88 <pr>
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
    80000766:	62650513          	addi	a0,a0,1574 # 80011d88 <pr>
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
    80000782:	60a48493          	addi	s1,s1,1546 # 80011d88 <pr>
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
    800007e2:	5ca50513          	addi	a0,a0,1482 # 80011da8 <uart_tx_lock>
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
    8000080e:	3567a783          	lw	a5,854(a5) # 80009b60 <panicked>
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
    8000084a:	32273703          	ld	a4,802(a4) # 80009b68 <uart_tx_r>
    8000084e:	00009797          	auipc	a5,0x9
    80000852:	3227b783          	ld	a5,802(a5) # 80009b70 <uart_tx_w>
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
    80000874:	538a0a13          	addi	s4,s4,1336 # 80011da8 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00009497          	auipc	s1,0x9
    8000087c:	2f048493          	addi	s1,s1,752 # 80009b68 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00009997          	auipc	s3,0x9
    80000884:	2f098993          	addi	s3,s3,752 # 80009b70 <uart_tx_w>
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
    800008aa:	d4e080e7          	jalr	-690(ra) # 800025f4 <wakeup>
    
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
    800008e6:	4c650513          	addi	a0,a0,1222 # 80011da8 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	300080e7          	jalr	768(ra) # 80000bea <acquire>
  if(panicked){
    800008f2:	00009797          	auipc	a5,0x9
    800008f6:	26e7a783          	lw	a5,622(a5) # 80009b60 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00009797          	auipc	a5,0x9
    80000900:	2747b783          	ld	a5,628(a5) # 80009b70 <uart_tx_w>
    80000904:	00009717          	auipc	a4,0x9
    80000908:	26473703          	ld	a4,612(a4) # 80009b68 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	498a0a13          	addi	s4,s4,1176 # 80011da8 <uart_tx_lock>
    80000918:	00009497          	auipc	s1,0x9
    8000091c:	25048493          	addi	s1,s1,592 # 80009b68 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00009917          	auipc	s2,0x9
    80000924:	25090913          	addi	s2,s2,592 # 80009b70 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00002097          	auipc	ra,0x2
    80000934:	b14080e7          	jalr	-1260(ra) # 80002444 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00011497          	auipc	s1,0x11
    8000094a:	46248493          	addi	s1,s1,1122 # 80011da8 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00009717          	auipc	a4,0x9
    8000095e:	20f73b23          	sd	a5,534(a4) # 80009b70 <uart_tx_w>
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
    800009d4:	3d848493          	addi	s1,s1,984 # 80011da8 <uart_tx_lock>
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
    80000a12:	00025797          	auipc	a5,0x25
    80000a16:	5f678793          	addi	a5,a5,1526 # 80026008 <end>
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
    80000a36:	3ae90913          	addi	s2,s2,942 # 80011de0 <kmem>
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
    80000ad2:	31250513          	addi	a0,a0,786 # 80011de0 <kmem>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	084080e7          	jalr	132(ra) # 80000b5a <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ade:	45c5                	li	a1,17
    80000ae0:	05ee                	slli	a1,a1,0x1b
    80000ae2:	00025517          	auipc	a0,0x25
    80000ae6:	52650513          	addi	a0,a0,1318 # 80026008 <end>
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
    80000b08:	2dc48493          	addi	s1,s1,732 # 80011de0 <kmem>
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
    80000b20:	2c450513          	addi	a0,a0,708 # 80011de0 <kmem>
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
    80000b4c:	29850513          	addi	a0,a0,664 # 80011de0 <kmem>
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
    80000ea8:	cd470713          	addi	a4,a4,-812 # 80009b78 <started>
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
    80000ede:	cb6080e7          	jalr	-842(ra) # 80002b90 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00006097          	auipc	ra,0x6
    80000ee6:	93e080e7          	jalr	-1730(ra) # 80006820 <plicinithart>
  }

  scheduler();        
    80000eea:	00001097          	auipc	ra,0x1
    80000eee:	21a080e7          	jalr	538(ra) # 80002104 <scheduler>
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
    80000f56:	c16080e7          	jalr	-1002(ra) # 80002b68 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00002097          	auipc	ra,0x2
    80000f5e:	c36080e7          	jalr	-970(ra) # 80002b90 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00006097          	auipc	ra,0x6
    80000f66:	8a8080e7          	jalr	-1880(ra) # 8000680a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00006097          	auipc	ra,0x6
    80000f6e:	8b6080e7          	jalr	-1866(ra) # 80006820 <plicinithart>
    binit();         // buffer cache
    80000f72:	00003097          	auipc	ra,0x3
    80000f76:	a6a080e7          	jalr	-1430(ra) # 800039dc <binit>
    iinit();         // inode table
    80000f7a:	00003097          	auipc	ra,0x3
    80000f7e:	10e080e7          	jalr	270(ra) # 80004088 <iinit>
    fileinit();      // file table
    80000f82:	00004097          	auipc	ra,0x4
    80000f86:	0ac080e7          	jalr	172(ra) # 8000502e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00006097          	auipc	ra,0x6
    80000f8e:	99e080e7          	jalr	-1634(ra) # 80006928 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	f50080e7          	jalr	-176(ra) # 80001ee2 <userinit>
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    started = 1;
    80000f9e:	4785                	li	a5,1
    80000fa0:	00009717          	auipc	a4,0x9
    80000fa4:	bcf72c23          	sw	a5,-1064(a4) # 80009b78 <started>
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
    80000fb8:	bcc7b783          	ld	a5,-1076(a5) # 80009b80 <kernel_pagetable>
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
    80001274:	90a7b823          	sd	a0,-1776(a5) # 80009b80 <kernel_pagetable>
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
    80001850:	19852703          	lw	a4,408(a0)
  //printf("%d %d\n",queues[idx].back, queues[idx].length);
  if (queues[idx].length == NPROC)
    80001854:	21800793          	li	a5,536
    80001858:	02f706b3          	mul	a3,a4,a5
    8000185c:	00011797          	auipc	a5,0x11
    80001860:	9d478793          	addi	a5,a5,-1580 # 80012230 <queues>
    80001864:	97b6                	add	a5,a5,a3
    80001866:	4790                	lw	a2,8(a5)
    80001868:	04000793          	li	a5,64
    8000186c:	06f60a63          	beq	a2,a5,800018e0 <enqueue+0x90>
    panic("Full queue");

  queues[idx].procs[queues[idx].back] = process;
    80001870:	00011597          	auipc	a1,0x11
    80001874:	9c058593          	addi	a1,a1,-1600 # 80012230 <queues>
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
    800018b2:	98278793          	addi	a5,a5,-1662 # 80012230 <queues>
    800018b6:	97ae                	add	a5,a5,a1
    800018b8:	c3d4                	sw	a3,4(a5)
  queues[idx].length++;
    800018ba:	21800793          	li	a5,536
    800018be:	02f70733          	mul	a4,a4,a5
    800018c2:	00011797          	auipc	a5,0x11
    800018c6:	96e78793          	addi	a5,a5,-1682 # 80012230 <queues>
    800018ca:	973e                	add	a4,a4,a5
    800018cc:	2605                	addiw	a2,a2,1
    800018ce:	c710                	sw	a2,8(a4)
  process->curr_rtime = 0;
    800018d0:	1a052023          	sw	zero,416(a0)
  process->curr_wtime = 0;
    800018d4:	1a052223          	sw	zero,420(a0)
  process->in_queue = 1;
    800018d8:	4785                	li	a5,1
    800018da:	18f52e23          	sw	a5,412(a0)
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
    80001904:	93078793          	addi	a5,a5,-1744 # 80012230 <queues>
    80001908:	97b6                	add	a5,a5,a3
    8000190a:	0007a223          	sw	zero,4(a5)
    8000190e:	b775                	j	800018ba <enqueue+0x6a>

0000000080001910 <dequeue>:
  //printf("size: %d\n",q->size);
}

void dequeue(struct proc *process)
{
  int idx = process->priority;
    80001910:	19852783          	lw	a5,408(a0)
  if (queues[idx].length == 0)
    80001914:	21800713          	li	a4,536
    80001918:	02e786b3          	mul	a3,a5,a4
    8000191c:	00011717          	auipc	a4,0x11
    80001920:	91470713          	addi	a4,a4,-1772 # 80012230 <queues>
    80001924:	9736                	add	a4,a4,a3
    80001926:	4718                	lw	a4,8(a4)
    80001928:	cb31                	beqz	a4,8000197c <dequeue+0x6c>
    panic("Empty queue");
  
  queues[idx].front++;
    8000192a:	21800693          	li	a3,536
    8000192e:	02d78633          	mul	a2,a5,a3
    80001932:	00011697          	auipc	a3,0x11
    80001936:	8fe68693          	addi	a3,a3,-1794 # 80012230 <queues>
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
    80001958:	8dc60613          	addi	a2,a2,-1828 # 80012230 <queues>
    8000195c:	962e                	add	a2,a2,a1
    8000195e:	c214                	sw	a3,0(a2)
  queues[idx].length--;
    80001960:	21800693          	li	a3,536
    80001964:	02d787b3          	mul	a5,a5,a3
    80001968:	00011697          	auipc	a3,0x11
    8000196c:	8c868693          	addi	a3,a3,-1848 # 80012230 <queues>
    80001970:	97b6                	add	a5,a5,a3
    80001972:	377d                	addiw	a4,a4,-1
    80001974:	c798                	sw	a4,8(a5)
  process->in_queue = 0;
    80001976:	18052e23          	sw	zero,412(a0)
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
    800019a0:	89468693          	addi	a3,a3,-1900 # 80012230 <queues>
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
    800019b2:	19852883          	lw	a7,408(a0)
  int curr = queues[idx].front;
    800019b6:	21800793          	li	a5,536
    800019ba:	02f88733          	mul	a4,a7,a5
    800019be:	00011797          	auipc	a5,0x11
    800019c2:	87278793          	addi	a5,a5,-1934 # 80012230 <queues>
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
    800019d8:	85c58593          	addi	a1,a1,-1956 # 80012230 <queues>
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
    80001a18:	81c78793          	addi	a5,a5,-2020 # 80012230 <queues>
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
    80001a3c:	00010797          	auipc	a5,0x10
    80001a40:	7f478793          	addi	a5,a5,2036 # 80012230 <queues>
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
    80001a6a:	24248493          	addi	s1,s1,578 # 80012ca8 <proc>
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
    80001a84:	e28a0a13          	addi	s4,s4,-472 # 800198a8 <tickslock>
    char *pa = kalloc();
    80001a88:	fffff097          	auipc	ra,0xfffff
    80001a8c:	072080e7          	jalr	114(ra) # 80000afa <kalloc>
    80001a90:	862a                	mv	a2,a0
    if(pa == 0)
    80001a92:	c131                	beqz	a0,80001ad6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001a94:	416485b3          	sub	a1,s1,s6
    80001a98:	8591                	srai	a1,a1,0x4
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
    80001aba:	1b048493          	addi	s1,s1,432
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
    80001b06:	2fe50513          	addi	a0,a0,766 # 80011e00 <pid_lock>
    80001b0a:	fffff097          	auipc	ra,0xfffff
    80001b0e:	050080e7          	jalr	80(ra) # 80000b5a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001b12:	00007597          	auipc	a1,0x7
    80001b16:	6f658593          	addi	a1,a1,1782 # 80009208 <digits+0x1c8>
    80001b1a:	00010517          	auipc	a0,0x10
    80001b1e:	2fe50513          	addi	a0,a0,766 # 80011e18 <wait_lock>
    80001b22:	fffff097          	auipc	ra,0xfffff
    80001b26:	038080e7          	jalr	56(ra) # 80000b5a <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b2a:	00011497          	auipc	s1,0x11
    80001b2e:	17e48493          	addi	s1,s1,382 # 80012ca8 <proc>
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
    80001b50:	d5c98993          	addi	s3,s3,-676 # 800198a8 <tickslock>
      initlock(&p->lock, "proc");
    80001b54:	85da                	mv	a1,s6
    80001b56:	8526                	mv	a0,s1
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	002080e7          	jalr	2(ra) # 80000b5a <initlock>
      p->state = UNUSED;
    80001b60:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001b64:	415487b3          	sub	a5,s1,s5
    80001b68:	8791                	srai	a5,a5,0x4
    80001b6a:	000a3703          	ld	a4,0(s4)
    80001b6e:	02e787b3          	mul	a5,a5,a4
    80001b72:	2785                	addiw	a5,a5,1
    80001b74:	00d7979b          	slliw	a5,a5,0xd
    80001b78:	40f907b3          	sub	a5,s2,a5
    80001b7c:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b7e:	1b048493          	addi	s1,s1,432
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
    80001bba:	27a50513          	addi	a0,a0,634 # 80011e30 <cpus>
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
    80001be2:	22270713          	addi	a4,a4,546 # 80011e00 <pid_lock>
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
    80001c1a:	dea7a783          	lw	a5,-534(a5) # 80009a00 <first.1757>
    80001c1e:	eb89                	bnez	a5,80001c30 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001c20:	00001097          	auipc	ra,0x1
    80001c24:	f88080e7          	jalr	-120(ra) # 80002ba8 <usertrapret>
}
    80001c28:	60a2                	ld	ra,8(sp)
    80001c2a:	6402                	ld	s0,0(sp)
    80001c2c:	0141                	addi	sp,sp,16
    80001c2e:	8082                	ret
    first = 0;
    80001c30:	00008797          	auipc	a5,0x8
    80001c34:	dc07a823          	sw	zero,-560(a5) # 80009a00 <first.1757>
    fsinit(ROOTDEV);
    80001c38:	4505                	li	a0,1
    80001c3a:	00002097          	auipc	ra,0x2
    80001c3e:	3ce080e7          	jalr	974(ra) # 80004008 <fsinit>
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
    80001c54:	1b090913          	addi	s2,s2,432 # 80011e00 <pid_lock>
    80001c58:	854a                	mv	a0,s2
    80001c5a:	fffff097          	auipc	ra,0xfffff
    80001c5e:	f90080e7          	jalr	-112(ra) # 80000bea <acquire>
  pid = nextpid;
    80001c62:	00008797          	auipc	a5,0x8
    80001c66:	da278793          	addi	a5,a5,-606 # 80009a04 <nextpid>
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
    80001dec:	ec048493          	addi	s1,s1,-320 # 80012ca8 <proc>
    80001df0:	00018917          	auipc	s2,0x18
    80001df4:	ab890913          	addi	s2,s2,-1352 # 800198a8 <tickslock>
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
    80001e10:	1b048493          	addi	s1,s1,432
    80001e14:	ff2492e3          	bne	s1,s2,80001df8 <allocproc+0x1c>
  return 0;
    80001e18:	4481                	li	s1,0
    80001e1a:	a069                	j	80001ea4 <allocproc+0xc8>
  p->pid = allocpid();
    80001e1c:	00000097          	auipc	ra,0x0
    80001e20:	e28080e7          	jalr	-472(ra) # 80001c44 <allocpid>
    80001e24:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001e26:	4785                	li	a5,1
    80001e28:	cc9c                	sw	a5,24(s1)
  p->tick_creation_time = ticks;
    80001e2a:	00008717          	auipc	a4,0x8
    80001e2e:	d6672703          	lw	a4,-666(a4) # 80009b90 <ticks>
    80001e32:	18e4a823          	sw	a4,400(s1)
  p->tickets = 1;
    80001e36:	18f4aa23          	sw	a5,404(s1)
  p->priority = 0;
    80001e3a:	1804ac23          	sw	zero,408(s1)
  p->in_queue = 0;
    80001e3e:	1804ae23          	sw	zero,412(s1)
  p->curr_rtime = 0;
    80001e42:	1a04a023          	sw	zero,416(s1)
  p->curr_wtime = 0;
    80001e46:	1a04a223          	sw	zero,420(s1)
  p->itime = 0;
    80001e4a:	1a04a423          	sw	zero,424(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001e4e:	fffff097          	auipc	ra,0xfffff
    80001e52:	cac080e7          	jalr	-852(ra) # 80000afa <kalloc>
    80001e56:	892a                	mv	s2,a0
    80001e58:	eca8                	sd	a0,88(s1)
    80001e5a:	cd21                	beqz	a0,80001eb2 <allocproc+0xd6>
  p->pagetable = proc_pagetable(p);
    80001e5c:	8526                	mv	a0,s1
    80001e5e:	00000097          	auipc	ra,0x0
    80001e62:	e2c080e7          	jalr	-468(ra) # 80001c8a <proc_pagetable>
    80001e66:	892a                	mv	s2,a0
    80001e68:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001e6a:	c125                	beqz	a0,80001eca <allocproc+0xee>
  memset(&p->context, 0, sizeof(p->context));
    80001e6c:	07000613          	li	a2,112
    80001e70:	4581                	li	a1,0
    80001e72:	06048513          	addi	a0,s1,96
    80001e76:	fffff097          	auipc	ra,0xfffff
    80001e7a:	e70080e7          	jalr	-400(ra) # 80000ce6 <memset>
  p->context.ra = (uint64)forkret;
    80001e7e:	00000797          	auipc	a5,0x0
    80001e82:	d8078793          	addi	a5,a5,-640 # 80001bfe <forkret>
    80001e86:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e88:	60bc                	ld	a5,64(s1)
    80001e8a:	6705                	lui	a4,0x1
    80001e8c:	97ba                	add	a5,a5,a4
    80001e8e:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001e90:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001e94:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001e98:	00008797          	auipc	a5,0x8
    80001e9c:	cf87a783          	lw	a5,-776(a5) # 80009b90 <ticks>
    80001ea0:	16f4a623          	sw	a5,364(s1)
}
    80001ea4:	8526                	mv	a0,s1
    80001ea6:	60e2                	ld	ra,24(sp)
    80001ea8:	6442                	ld	s0,16(sp)
    80001eaa:	64a2                	ld	s1,8(sp)
    80001eac:	6902                	ld	s2,0(sp)
    80001eae:	6105                	addi	sp,sp,32
    80001eb0:	8082                	ret
    freeproc(p);
    80001eb2:	8526                	mv	a0,s1
    80001eb4:	00000097          	auipc	ra,0x0
    80001eb8:	ec4080e7          	jalr	-316(ra) # 80001d78 <freeproc>
    release(&p->lock);
    80001ebc:	8526                	mv	a0,s1
    80001ebe:	fffff097          	auipc	ra,0xfffff
    80001ec2:	de0080e7          	jalr	-544(ra) # 80000c9e <release>
    return 0;
    80001ec6:	84ca                	mv	s1,s2
    80001ec8:	bff1                	j	80001ea4 <allocproc+0xc8>
    freeproc(p);
    80001eca:	8526                	mv	a0,s1
    80001ecc:	00000097          	auipc	ra,0x0
    80001ed0:	eac080e7          	jalr	-340(ra) # 80001d78 <freeproc>
    release(&p->lock);
    80001ed4:	8526                	mv	a0,s1
    80001ed6:	fffff097          	auipc	ra,0xfffff
    80001eda:	dc8080e7          	jalr	-568(ra) # 80000c9e <release>
    return 0;
    80001ede:	84ca                	mv	s1,s2
    80001ee0:	b7d1                	j	80001ea4 <allocproc+0xc8>

0000000080001ee2 <userinit>:
{
    80001ee2:	1101                	addi	sp,sp,-32
    80001ee4:	ec06                	sd	ra,24(sp)
    80001ee6:	e822                	sd	s0,16(sp)
    80001ee8:	e426                	sd	s1,8(sp)
    80001eea:	1000                	addi	s0,sp,32
  p = allocproc();
    80001eec:	00000097          	auipc	ra,0x0
    80001ef0:	ef0080e7          	jalr	-272(ra) # 80001ddc <allocproc>
    80001ef4:	84aa                	mv	s1,a0
  initproc = p;
    80001ef6:	00008797          	auipc	a5,0x8
    80001efa:	c8a7b923          	sd	a0,-878(a5) # 80009b88 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001efe:	03400613          	li	a2,52
    80001f02:	00008597          	auipc	a1,0x8
    80001f06:	b0e58593          	addi	a1,a1,-1266 # 80009a10 <initcode>
    80001f0a:	6928                	ld	a0,80(a0)
    80001f0c:	fffff097          	auipc	ra,0xfffff
    80001f10:	466080e7          	jalr	1126(ra) # 80001372 <uvmfirst>
  p->sz = PGSIZE;
    80001f14:	6785                	lui	a5,0x1
    80001f16:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001f18:	6cb8                	ld	a4,88(s1)
    80001f1a:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001f1e:	6cb8                	ld	a4,88(s1)
    80001f20:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f22:	4641                	li	a2,16
    80001f24:	00007597          	auipc	a1,0x7
    80001f28:	2fc58593          	addi	a1,a1,764 # 80009220 <digits+0x1e0>
    80001f2c:	15848513          	addi	a0,s1,344
    80001f30:	fffff097          	auipc	ra,0xfffff
    80001f34:	f08080e7          	jalr	-248(ra) # 80000e38 <safestrcpy>
  p->cwd = namei("/");
    80001f38:	00007517          	auipc	a0,0x7
    80001f3c:	2f850513          	addi	a0,a0,760 # 80009230 <digits+0x1f0>
    80001f40:	00003097          	auipc	ra,0x3
    80001f44:	aea080e7          	jalr	-1302(ra) # 80004a2a <namei>
    80001f48:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001f4c:	478d                	li	a5,3
    80001f4e:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001f50:	8526                	mv	a0,s1
    80001f52:	fffff097          	auipc	ra,0xfffff
    80001f56:	d4c080e7          	jalr	-692(ra) # 80000c9e <release>
}
    80001f5a:	60e2                	ld	ra,24(sp)
    80001f5c:	6442                	ld	s0,16(sp)
    80001f5e:	64a2                	ld	s1,8(sp)
    80001f60:	6105                	addi	sp,sp,32
    80001f62:	8082                	ret

0000000080001f64 <growproc>:
{
    80001f64:	1101                	addi	sp,sp,-32
    80001f66:	ec06                	sd	ra,24(sp)
    80001f68:	e822                	sd	s0,16(sp)
    80001f6a:	e426                	sd	s1,8(sp)
    80001f6c:	e04a                	sd	s2,0(sp)
    80001f6e:	1000                	addi	s0,sp,32
    80001f70:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001f72:	00000097          	auipc	ra,0x0
    80001f76:	c54080e7          	jalr	-940(ra) # 80001bc6 <myproc>
    80001f7a:	84aa                	mv	s1,a0
  sz = p->sz;
    80001f7c:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001f7e:	01204c63          	bgtz	s2,80001f96 <growproc+0x32>
  } else if(n < 0){
    80001f82:	02094663          	bltz	s2,80001fae <growproc+0x4a>
  p->sz = sz;
    80001f86:	e4ac                	sd	a1,72(s1)
  return 0;
    80001f88:	4501                	li	a0,0
}
    80001f8a:	60e2                	ld	ra,24(sp)
    80001f8c:	6442                	ld	s0,16(sp)
    80001f8e:	64a2                	ld	s1,8(sp)
    80001f90:	6902                	ld	s2,0(sp)
    80001f92:	6105                	addi	sp,sp,32
    80001f94:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001f96:	4691                	li	a3,4
    80001f98:	00b90633          	add	a2,s2,a1
    80001f9c:	6928                	ld	a0,80(a0)
    80001f9e:	fffff097          	auipc	ra,0xfffff
    80001fa2:	48e080e7          	jalr	1166(ra) # 8000142c <uvmalloc>
    80001fa6:	85aa                	mv	a1,a0
    80001fa8:	fd79                	bnez	a0,80001f86 <growproc+0x22>
      return -1;
    80001faa:	557d                	li	a0,-1
    80001fac:	bff9                	j	80001f8a <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001fae:	00b90633          	add	a2,s2,a1
    80001fb2:	6928                	ld	a0,80(a0)
    80001fb4:	fffff097          	auipc	ra,0xfffff
    80001fb8:	430080e7          	jalr	1072(ra) # 800013e4 <uvmdealloc>
    80001fbc:	85aa                	mv	a1,a0
    80001fbe:	b7e1                	j	80001f86 <growproc+0x22>

0000000080001fc0 <fork>:
{
    80001fc0:	7179                	addi	sp,sp,-48
    80001fc2:	f406                	sd	ra,40(sp)
    80001fc4:	f022                	sd	s0,32(sp)
    80001fc6:	ec26                	sd	s1,24(sp)
    80001fc8:	e84a                	sd	s2,16(sp)
    80001fca:	e44e                	sd	s3,8(sp)
    80001fcc:	e052                	sd	s4,0(sp)
    80001fce:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fd0:	00000097          	auipc	ra,0x0
    80001fd4:	bf6080e7          	jalr	-1034(ra) # 80001bc6 <myproc>
    80001fd8:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001fda:	00000097          	auipc	ra,0x0
    80001fde:	e02080e7          	jalr	-510(ra) # 80001ddc <allocproc>
    80001fe2:	10050f63          	beqz	a0,80002100 <fork+0x140>
    80001fe6:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001fe8:	04893603          	ld	a2,72(s2)
    80001fec:	692c                	ld	a1,80(a0)
    80001fee:	05093503          	ld	a0,80(s2)
    80001ff2:	fffff097          	auipc	ra,0xfffff
    80001ff6:	58e080e7          	jalr	1422(ra) # 80001580 <uvmcopy>
    80001ffa:	04054a63          	bltz	a0,8000204e <fork+0x8e>
  np->sz = p->sz;
    80001ffe:	04893783          	ld	a5,72(s2)
    80002002:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80002006:	05893683          	ld	a3,88(s2)
    8000200a:	87b6                	mv	a5,a3
    8000200c:	0589b703          	ld	a4,88(s3)
    80002010:	12068693          	addi	a3,a3,288
    80002014:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002018:	6788                	ld	a0,8(a5)
    8000201a:	6b8c                	ld	a1,16(a5)
    8000201c:	6f90                	ld	a2,24(a5)
    8000201e:	01073023          	sd	a6,0(a4)
    80002022:	e708                	sd	a0,8(a4)
    80002024:	eb0c                	sd	a1,16(a4)
    80002026:	ef10                	sd	a2,24(a4)
    80002028:	02078793          	addi	a5,a5,32
    8000202c:	02070713          	addi	a4,a4,32
    80002030:	fed792e3          	bne	a5,a3,80002014 <fork+0x54>
  np->trace_flag = p->trace_flag;
    80002034:	17492783          	lw	a5,372(s2)
    80002038:	16f9aa23          	sw	a5,372(s3)
  np->trapframe->a0 = 0;
    8000203c:	0589b783          	ld	a5,88(s3)
    80002040:	0607b823          	sd	zero,112(a5)
    80002044:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80002048:	15000a13          	li	s4,336
    8000204c:	a03d                	j	8000207a <fork+0xba>
    freeproc(np);
    8000204e:	854e                	mv	a0,s3
    80002050:	00000097          	auipc	ra,0x0
    80002054:	d28080e7          	jalr	-728(ra) # 80001d78 <freeproc>
    release(&np->lock);
    80002058:	854e                	mv	a0,s3
    8000205a:	fffff097          	auipc	ra,0xfffff
    8000205e:	c44080e7          	jalr	-956(ra) # 80000c9e <release>
    return -1;
    80002062:	5a7d                	li	s4,-1
    80002064:	a069                	j	800020ee <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    80002066:	00003097          	auipc	ra,0x3
    8000206a:	05a080e7          	jalr	90(ra) # 800050c0 <filedup>
    8000206e:	009987b3          	add	a5,s3,s1
    80002072:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002074:	04a1                	addi	s1,s1,8
    80002076:	01448763          	beq	s1,s4,80002084 <fork+0xc4>
    if(p->ofile[i])
    8000207a:	009907b3          	add	a5,s2,s1
    8000207e:	6388                	ld	a0,0(a5)
    80002080:	f17d                	bnez	a0,80002066 <fork+0xa6>
    80002082:	bfcd                	j	80002074 <fork+0xb4>
  np->cwd = idup(p->cwd);
    80002084:	15093503          	ld	a0,336(s2)
    80002088:	00002097          	auipc	ra,0x2
    8000208c:	1be080e7          	jalr	446(ra) # 80004246 <idup>
    80002090:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002094:	4641                	li	a2,16
    80002096:	15890593          	addi	a1,s2,344
    8000209a:	15898513          	addi	a0,s3,344
    8000209e:	fffff097          	auipc	ra,0xfffff
    800020a2:	d9a080e7          	jalr	-614(ra) # 80000e38 <safestrcpy>
  pid = np->pid;
    800020a6:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    800020aa:	854e                	mv	a0,s3
    800020ac:	fffff097          	auipc	ra,0xfffff
    800020b0:	bf2080e7          	jalr	-1038(ra) # 80000c9e <release>
  acquire(&wait_lock);
    800020b4:	00010497          	auipc	s1,0x10
    800020b8:	d6448493          	addi	s1,s1,-668 # 80011e18 <wait_lock>
    800020bc:	8526                	mv	a0,s1
    800020be:	fffff097          	auipc	ra,0xfffff
    800020c2:	b2c080e7          	jalr	-1236(ra) # 80000bea <acquire>
  np->parent = p;
    800020c6:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    800020ca:	8526                	mv	a0,s1
    800020cc:	fffff097          	auipc	ra,0xfffff
    800020d0:	bd2080e7          	jalr	-1070(ra) # 80000c9e <release>
  acquire(&np->lock);
    800020d4:	854e                	mv	a0,s3
    800020d6:	fffff097          	auipc	ra,0xfffff
    800020da:	b14080e7          	jalr	-1260(ra) # 80000bea <acquire>
  np->state = RUNNABLE;
    800020de:	478d                	li	a5,3
    800020e0:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    800020e4:	854e                	mv	a0,s3
    800020e6:	fffff097          	auipc	ra,0xfffff
    800020ea:	bb8080e7          	jalr	-1096(ra) # 80000c9e <release>
}
    800020ee:	8552                	mv	a0,s4
    800020f0:	70a2                	ld	ra,40(sp)
    800020f2:	7402                	ld	s0,32(sp)
    800020f4:	64e2                	ld	s1,24(sp)
    800020f6:	6942                	ld	s2,16(sp)
    800020f8:	69a2                	ld	s3,8(sp)
    800020fa:	6a02                	ld	s4,0(sp)
    800020fc:	6145                	addi	sp,sp,48
    800020fe:	8082                	ret
    return -1;
    80002100:	5a7d                	li	s4,-1
    80002102:	b7f5                	j	800020ee <fork+0x12e>

0000000080002104 <scheduler>:
{
    80002104:	7175                	addi	sp,sp,-144
    80002106:	e506                	sd	ra,136(sp)
    80002108:	e122                	sd	s0,128(sp)
    8000210a:	fca6                	sd	s1,120(sp)
    8000210c:	f8ca                	sd	s2,112(sp)
    8000210e:	f4ce                	sd	s3,104(sp)
    80002110:	f0d2                	sd	s4,96(sp)
    80002112:	ecd6                	sd	s5,88(sp)
    80002114:	e8da                	sd	s6,80(sp)
    80002116:	e4de                	sd	s7,72(sp)
    80002118:	e0e2                	sd	s8,64(sp)
    8000211a:	fc66                	sd	s9,56(sp)
    8000211c:	f86a                	sd	s10,48(sp)
    8000211e:	f46e                	sd	s11,40(sp)
    80002120:	0900                	addi	s0,sp,144
    80002122:	8792                	mv	a5,tp
  int id = r_tp();
    80002124:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002126:	00779693          	slli	a3,a5,0x7
    8000212a:	00010717          	auipc	a4,0x10
    8000212e:	cd670713          	addi	a4,a4,-810 # 80011e00 <pid_lock>
    80002132:	9736                	add	a4,a4,a3
    80002134:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &proc_to_run->context);
    80002138:	00010717          	auipc	a4,0x10
    8000213c:	d0070713          	addi	a4,a4,-768 # 80011e38 <cpus+0x8>
    80002140:	9736                	add	a4,a4,a3
    80002142:	f8e43023          	sd	a4,-128(s0)
      for (p = proc; p < &proc[NPROC]; p++)
    80002146:	00017a97          	auipc	s5,0x17
    8000214a:	762a8a93          	addi	s5,s5,1890 # 800198a8 <tickslock>
          p = queues[i].procs[queues[i].front];
    8000214e:	00010c17          	auipc	s8,0x10
    80002152:	0e2c0c13          	addi	s8,s8,226 # 80012230 <queues>
        for(int j = 0; j < queues[i].length; j++)
    80002156:	f8043423          	sd	zero,-120(s0)
        c->proc = proc_to_run;
    8000215a:	00010717          	auipc	a4,0x10
    8000215e:	ca670713          	addi	a4,a4,-858 # 80011e00 <pid_lock>
    80002162:	00d707b3          	add	a5,a4,a3
    80002166:	f6f43c23          	sd	a5,-136(s0)
    8000216a:	a051                	j	800021ee <scheduler+0xea>
          enqueue(p);
    8000216c:	8526                	mv	a0,s1
    8000216e:	fffff097          	auipc	ra,0xfffff
    80002172:	6e2080e7          	jalr	1762(ra) # 80001850 <enqueue>
        release(&p->lock);
    80002176:	8526                	mv	a0,s1
    80002178:	fffff097          	auipc	ra,0xfffff
    8000217c:	b26080e7          	jalr	-1242(ra) # 80000c9e <release>
      for (p = proc; p < &proc[NPROC]; p++)
    80002180:	1b048493          	addi	s1,s1,432
    80002184:	01548e63          	beq	s1,s5,800021a0 <scheduler+0x9c>
        acquire(&p->lock);
    80002188:	8526                	mv	a0,s1
    8000218a:	fffff097          	auipc	ra,0xfffff
    8000218e:	a60080e7          	jalr	-1440(ra) # 80000bea <acquire>
        if (p->state == RUNNABLE && p->in_queue == 0)
    80002192:	4c9c                	lw	a5,24(s1)
    80002194:	ff3791e3          	bne	a5,s3,80002176 <scheduler+0x72>
    80002198:	19c4a783          	lw	a5,412(s1)
    8000219c:	ffe9                	bnez	a5,80002176 <scheduler+0x72>
    8000219e:	b7f9                	j	8000216c <scheduler+0x68>
    800021a0:	00010d17          	auipc	s10,0x10
    800021a4:	098d0d13          	addi	s10,s10,152 # 80012238 <queues+0x8>
      for (int i = 0; i < 5; i++)
    800021a8:	4c81                	li	s9,0
    800021aa:	a0a5                	j	80002212 <scheduler+0x10e>
            p->itime = ticks;
    800021ac:	00008917          	auipc	s2,0x8
    800021b0:	9e490913          	addi	s2,s2,-1564 # 80009b90 <ticks>
    800021b4:	00092783          	lw	a5,0(s2)
    800021b8:	1af4a423          	sw	a5,424(s1)
        proc_to_run->state = RUNNING;
    800021bc:	4791                	li	a5,4
    800021be:	cc9c                	sw	a5,24(s1)
        c->proc = proc_to_run;
    800021c0:	f7843983          	ld	s3,-136(s0)
    800021c4:	0299b823          	sd	s1,48(s3)
        swtch(&c->context, &proc_to_run->context);
    800021c8:	06048593          	addi	a1,s1,96
    800021cc:	f8043503          	ld	a0,-128(s0)
    800021d0:	00001097          	auipc	ra,0x1
    800021d4:	92e080e7          	jalr	-1746(ra) # 80002afe <swtch>
        c->proc = 0;
    800021d8:	0209b823          	sd	zero,48(s3)
        proc_to_run->itime = ticks;
    800021dc:	00092783          	lw	a5,0(s2)
    800021e0:	1af4a423          	sw	a5,424(s1)
        release(&proc_to_run->lock);
    800021e4:	8526                	mv	a0,s1
    800021e6:	fffff097          	auipc	ra,0xfffff
    800021ea:	ab8080e7          	jalr	-1352(ra) # 80000c9e <release>
        if (p->state == RUNNABLE && p->in_queue == 0)
    800021ee:	498d                	li	s3,3
      for (int i = 0; i < 5; i++)
    800021f0:	4d95                	li	s11,5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021f2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021f6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800021fa:	10079073          	csrw	sstatus,a5
      for (p = proc; p < &proc[NPROC]; p++)
    800021fe:	00011497          	auipc	s1,0x11
    80002202:	aaa48493          	addi	s1,s1,-1366 # 80012ca8 <proc>
    80002206:	b749                	j	80002188 <scheduler+0x84>
      for (int i = 0; i < 5; i++)
    80002208:	2c85                	addiw	s9,s9,1
    8000220a:	218d0d13          	addi	s10,s10,536
    8000220e:	ffbc82e3          	beq	s9,s11,800021f2 <scheduler+0xee>
        for(int j = 0; j < queues[i].length; j++)
    80002212:	8a6a                	mv	s4,s10
    80002214:	000d2783          	lw	a5,0(s10)
    80002218:	f8843903          	ld	s2,-120(s0)
    8000221c:	fef056e3          	blez	a5,80002208 <scheduler+0x104>
          p = queues[i].procs[queues[i].front];
    80002220:	004c9b13          	slli	s6,s9,0x4
    80002224:	9b66                	add	s6,s6,s9
    80002226:	0b0a                	slli	s6,s6,0x2
    80002228:	419b0b33          	sub	s6,s6,s9
    8000222c:	ff8a2783          	lw	a5,-8(s4)
    80002230:	97da                	add	a5,a5,s6
    80002232:	0789                	addi	a5,a5,2
    80002234:	078e                	slli	a5,a5,0x3
    80002236:	97e2                	add	a5,a5,s8
    80002238:	6384                	ld	s1,0(a5)
          acquire(&p->lock);
    8000223a:	8526                	mv	a0,s1
    8000223c:	fffff097          	auipc	ra,0xfffff
    80002240:	9ae080e7          	jalr	-1618(ra) # 80000bea <acquire>
          dequeue(p);  // clear out all the processes as it goes through all the levels
    80002244:	8526                	mv	a0,s1
    80002246:	fffff097          	auipc	ra,0xfffff
    8000224a:	6ca080e7          	jalr	1738(ra) # 80001910 <dequeue>
          p->in_queue = 0;
    8000224e:	1804ae23          	sw	zero,412(s1)
          if (p->state == RUNNABLE)
    80002252:	4c9c                	lw	a5,24(s1)
    80002254:	f5378ce3          	beq	a5,s3,800021ac <scheduler+0xa8>
          release(&p->lock);
    80002258:	8526                	mv	a0,s1
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	a44080e7          	jalr	-1468(ra) # 80000c9e <release>
        for(int j = 0; j < queues[i].length; j++)
    80002262:	2905                	addiw	s2,s2,1
    80002264:	000a2783          	lw	a5,0(s4)
    80002268:	fcf942e3          	blt	s2,a5,8000222c <scheduler+0x128>
    8000226c:	bf71                	j	80002208 <scheduler+0x104>

000000008000226e <sched>:
{
    8000226e:	7179                	addi	sp,sp,-48
    80002270:	f406                	sd	ra,40(sp)
    80002272:	f022                	sd	s0,32(sp)
    80002274:	ec26                	sd	s1,24(sp)
    80002276:	e84a                	sd	s2,16(sp)
    80002278:	e44e                	sd	s3,8(sp)
    8000227a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000227c:	00000097          	auipc	ra,0x0
    80002280:	94a080e7          	jalr	-1718(ra) # 80001bc6 <myproc>
    80002284:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002286:	fffff097          	auipc	ra,0xfffff
    8000228a:	8ea080e7          	jalr	-1814(ra) # 80000b70 <holding>
    8000228e:	c93d                	beqz	a0,80002304 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002290:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002292:	2781                	sext.w	a5,a5
    80002294:	079e                	slli	a5,a5,0x7
    80002296:	00010717          	auipc	a4,0x10
    8000229a:	b6a70713          	addi	a4,a4,-1174 # 80011e00 <pid_lock>
    8000229e:	97ba                	add	a5,a5,a4
    800022a0:	0a87a703          	lw	a4,168(a5)
    800022a4:	4785                	li	a5,1
    800022a6:	06f71763          	bne	a4,a5,80002314 <sched+0xa6>
  if(p->state == RUNNING)
    800022aa:	4c98                	lw	a4,24(s1)
    800022ac:	4791                	li	a5,4
    800022ae:	06f70b63          	beq	a4,a5,80002324 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022b2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800022b6:	8b89                	andi	a5,a5,2
  if(intr_get())
    800022b8:	efb5                	bnez	a5,80002334 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022ba:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800022bc:	00010917          	auipc	s2,0x10
    800022c0:	b4490913          	addi	s2,s2,-1212 # 80011e00 <pid_lock>
    800022c4:	2781                	sext.w	a5,a5
    800022c6:	079e                	slli	a5,a5,0x7
    800022c8:	97ca                	add	a5,a5,s2
    800022ca:	0ac7a983          	lw	s3,172(a5)
    800022ce:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800022d0:	2781                	sext.w	a5,a5
    800022d2:	079e                	slli	a5,a5,0x7
    800022d4:	00010597          	auipc	a1,0x10
    800022d8:	b6458593          	addi	a1,a1,-1180 # 80011e38 <cpus+0x8>
    800022dc:	95be                	add	a1,a1,a5
    800022de:	06048513          	addi	a0,s1,96
    800022e2:	00001097          	auipc	ra,0x1
    800022e6:	81c080e7          	jalr	-2020(ra) # 80002afe <swtch>
    800022ea:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800022ec:	2781                	sext.w	a5,a5
    800022ee:	079e                	slli	a5,a5,0x7
    800022f0:	97ca                	add	a5,a5,s2
    800022f2:	0b37a623          	sw	s3,172(a5)
}
    800022f6:	70a2                	ld	ra,40(sp)
    800022f8:	7402                	ld	s0,32(sp)
    800022fa:	64e2                	ld	s1,24(sp)
    800022fc:	6942                	ld	s2,16(sp)
    800022fe:	69a2                	ld	s3,8(sp)
    80002300:	6145                	addi	sp,sp,48
    80002302:	8082                	ret
    panic("sched p->lock");
    80002304:	00007517          	auipc	a0,0x7
    80002308:	f3450513          	addi	a0,a0,-204 # 80009238 <digits+0x1f8>
    8000230c:	ffffe097          	auipc	ra,0xffffe
    80002310:	238080e7          	jalr	568(ra) # 80000544 <panic>
    panic("sched locks");
    80002314:	00007517          	auipc	a0,0x7
    80002318:	f3450513          	addi	a0,a0,-204 # 80009248 <digits+0x208>
    8000231c:	ffffe097          	auipc	ra,0xffffe
    80002320:	228080e7          	jalr	552(ra) # 80000544 <panic>
    panic("sched running");
    80002324:	00007517          	auipc	a0,0x7
    80002328:	f3450513          	addi	a0,a0,-204 # 80009258 <digits+0x218>
    8000232c:	ffffe097          	auipc	ra,0xffffe
    80002330:	218080e7          	jalr	536(ra) # 80000544 <panic>
    panic("sched interruptible");
    80002334:	00007517          	auipc	a0,0x7
    80002338:	f3450513          	addi	a0,a0,-204 # 80009268 <digits+0x228>
    8000233c:	ffffe097          	auipc	ra,0xffffe
    80002340:	208080e7          	jalr	520(ra) # 80000544 <panic>

0000000080002344 <yield>:
{
    80002344:	1101                	addi	sp,sp,-32
    80002346:	ec06                	sd	ra,24(sp)
    80002348:	e822                	sd	s0,16(sp)
    8000234a:	e426                	sd	s1,8(sp)
    8000234c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000234e:	00000097          	auipc	ra,0x0
    80002352:	878080e7          	jalr	-1928(ra) # 80001bc6 <myproc>
    80002356:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	892080e7          	jalr	-1902(ra) # 80000bea <acquire>
  p->state = RUNNABLE;
    80002360:	478d                	li	a5,3
    80002362:	cc9c                	sw	a5,24(s1)
  sched();
    80002364:	00000097          	auipc	ra,0x0
    80002368:	f0a080e7          	jalr	-246(ra) # 8000226e <sched>
  release(&p->lock);
    8000236c:	8526                	mv	a0,s1
    8000236e:	fffff097          	auipc	ra,0xfffff
    80002372:	930080e7          	jalr	-1744(ra) # 80000c9e <release>
}
    80002376:	60e2                	ld	ra,24(sp)
    80002378:	6442                	ld	s0,16(sp)
    8000237a:	64a2                	ld	s1,8(sp)
    8000237c:	6105                	addi	sp,sp,32
    8000237e:	8082                	ret

0000000080002380 <update_time>:
{
    80002380:	7139                	addi	sp,sp,-64
    80002382:	fc06                	sd	ra,56(sp)
    80002384:	f822                	sd	s0,48(sp)
    80002386:	f426                	sd	s1,40(sp)
    80002388:	f04a                	sd	s2,32(sp)
    8000238a:	ec4e                	sd	s3,24(sp)
    8000238c:	e852                	sd	s4,16(sp)
    8000238e:	e456                	sd	s5,8(sp)
    80002390:	e05a                	sd	s6,0(sp)
    80002392:	0080                	addi	s0,sp,64
  for(p = proc; p < &proc[NPROC]; p++){
    80002394:	00011497          	auipc	s1,0x11
    80002398:	91448493          	addi	s1,s1,-1772 # 80012ca8 <proc>
    if(p->state == RUNNING) {
    8000239c:	4991                	li	s3,4
    else if(p->state == RUNNABLE) {
    8000239e:	4a0d                	li	s4,3
    if(ticks - p->itime >= 32 && p->state == RUNNABLE) {
    800023a0:	00007b17          	auipc	s6,0x7
    800023a4:	7f0b0b13          	addi	s6,s6,2032 # 80009b90 <ticks>
    800023a8:	4afd                	li	s5,31
  for(p = proc; p < &proc[NPROC]; p++){
    800023aa:	00017917          	auipc	s2,0x17
    800023ae:	4fe90913          	addi	s2,s2,1278 # 800198a8 <tickslock>
    800023b2:	a025                	j	800023da <update_time+0x5a>
      p->curr_rtime++;
    800023b4:	1a04a783          	lw	a5,416(s1)
    800023b8:	2785                	addiw	a5,a5,1
    800023ba:	1af4a023          	sw	a5,416(s1)
      p->rtime++;
    800023be:	1684a783          	lw	a5,360(s1)
    800023c2:	2785                	addiw	a5,a5,1
    800023c4:	16f4a423          	sw	a5,360(s1)
    release(&p->lock);
    800023c8:	8526                	mv	a0,s1
    800023ca:	fffff097          	auipc	ra,0xfffff
    800023ce:	8d4080e7          	jalr	-1836(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023d2:	1b048493          	addi	s1,s1,432
    800023d6:	05248d63          	beq	s1,s2,80002430 <update_time+0xb0>
    acquire(&p->lock);
    800023da:	8526                	mv	a0,s1
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	80e080e7          	jalr	-2034(ra) # 80000bea <acquire>
    if(p->state == RUNNING) {
    800023e4:	4c9c                	lw	a5,24(s1)
    800023e6:	fd3787e3          	beq	a5,s3,800023b4 <update_time+0x34>
    else if(p->state == RUNNABLE) {
    800023ea:	fd479fe3          	bne	a5,s4,800023c8 <update_time+0x48>
      p->curr_wtime++;
    800023ee:	1a44a783          	lw	a5,420(s1)
    800023f2:	2785                	addiw	a5,a5,1
    800023f4:	1af4a223          	sw	a5,420(s1)
    if(ticks - p->itime >= 32 && p->state == RUNNABLE) {
    800023f8:	000b2703          	lw	a4,0(s6)
    800023fc:	1a84a783          	lw	a5,424(s1)
    80002400:	40f707bb          	subw	a5,a4,a5
    80002404:	fcfaf2e3          	bgeu	s5,a5,800023c8 <update_time+0x48>
      if(p->in_queue != 0) {
    80002408:	19c4a783          	lw	a5,412(s1)
    8000240c:	eb81                	bnez	a5,8000241c <update_time+0x9c>
      if(p->priority != 0) {
    8000240e:	1984a783          	lw	a5,408(s1)
    80002412:	dbdd                	beqz	a5,800023c8 <update_time+0x48>
        p->priority--;
    80002414:	37fd                	addiw	a5,a5,-1
    80002416:	18f4ac23          	sw	a5,408(s1)
    8000241a:	b77d                	j	800023c8 <update_time+0x48>
        p->itime = ticks;
    8000241c:	1ae4a423          	sw	a4,424(s1)
        delqueue(p);
    80002420:	8526                	mv	a0,s1
    80002422:	fffff097          	auipc	ra,0xfffff
    80002426:	58a080e7          	jalr	1418(ra) # 800019ac <delqueue>
        p->in_queue = 0;
    8000242a:	1804ae23          	sw	zero,412(s1)
    8000242e:	b7c5                	j	8000240e <update_time+0x8e>
}
    80002430:	70e2                	ld	ra,56(sp)
    80002432:	7442                	ld	s0,48(sp)
    80002434:	74a2                	ld	s1,40(sp)
    80002436:	7902                	ld	s2,32(sp)
    80002438:	69e2                	ld	s3,24(sp)
    8000243a:	6a42                	ld	s4,16(sp)
    8000243c:	6aa2                	ld	s5,8(sp)
    8000243e:	6b02                	ld	s6,0(sp)
    80002440:	6121                	addi	sp,sp,64
    80002442:	8082                	ret

0000000080002444 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002444:	7179                	addi	sp,sp,-48
    80002446:	f406                	sd	ra,40(sp)
    80002448:	f022                	sd	s0,32(sp)
    8000244a:	ec26                	sd	s1,24(sp)
    8000244c:	e84a                	sd	s2,16(sp)
    8000244e:	e44e                	sd	s3,8(sp)
    80002450:	1800                	addi	s0,sp,48
    80002452:	89aa                	mv	s3,a0
    80002454:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002456:	fffff097          	auipc	ra,0xfffff
    8000245a:	770080e7          	jalr	1904(ra) # 80001bc6 <myproc>
    8000245e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002460:	ffffe097          	auipc	ra,0xffffe
    80002464:	78a080e7          	jalr	1930(ra) # 80000bea <acquire>
  release(lk);
    80002468:	854a                	mv	a0,s2
    8000246a:	fffff097          	auipc	ra,0xfffff
    8000246e:	834080e7          	jalr	-1996(ra) # 80000c9e <release>

  // Go to sleep.
  p->chan = chan;
    80002472:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002476:	4789                	li	a5,2
    80002478:	cc9c                	sw	a5,24(s1)

  sched();
    8000247a:	00000097          	auipc	ra,0x0
    8000247e:	df4080e7          	jalr	-524(ra) # 8000226e <sched>

  // Tidy up.
  p->chan = 0;
    80002482:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002486:	8526                	mv	a0,s1
    80002488:	fffff097          	auipc	ra,0xfffff
    8000248c:	816080e7          	jalr	-2026(ra) # 80000c9e <release>
  acquire(lk);
    80002490:	854a                	mv	a0,s2
    80002492:	ffffe097          	auipc	ra,0xffffe
    80002496:	758080e7          	jalr	1880(ra) # 80000bea <acquire>
}
    8000249a:	70a2                	ld	ra,40(sp)
    8000249c:	7402                	ld	s0,32(sp)
    8000249e:	64e2                	ld	s1,24(sp)
    800024a0:	6942                	ld	s2,16(sp)
    800024a2:	69a2                	ld	s3,8(sp)
    800024a4:	6145                	addi	sp,sp,48
    800024a6:	8082                	ret

00000000800024a8 <waitx>:
{
    800024a8:	711d                	addi	sp,sp,-96
    800024aa:	ec86                	sd	ra,88(sp)
    800024ac:	e8a2                	sd	s0,80(sp)
    800024ae:	e4a6                	sd	s1,72(sp)
    800024b0:	e0ca                	sd	s2,64(sp)
    800024b2:	fc4e                	sd	s3,56(sp)
    800024b4:	f852                	sd	s4,48(sp)
    800024b6:	f456                	sd	s5,40(sp)
    800024b8:	f05a                	sd	s6,32(sp)
    800024ba:	ec5e                	sd	s7,24(sp)
    800024bc:	e862                	sd	s8,16(sp)
    800024be:	e466                	sd	s9,8(sp)
    800024c0:	e06a                	sd	s10,0(sp)
    800024c2:	1080                	addi	s0,sp,96
    800024c4:	8b2a                	mv	s6,a0
    800024c6:	8bae                	mv	s7,a1
    800024c8:	8c32                	mv	s8,a2
  struct proc *p = myproc();
    800024ca:	fffff097          	auipc	ra,0xfffff
    800024ce:	6fc080e7          	jalr	1788(ra) # 80001bc6 <myproc>
    800024d2:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800024d4:	00010517          	auipc	a0,0x10
    800024d8:	94450513          	addi	a0,a0,-1724 # 80011e18 <wait_lock>
    800024dc:	ffffe097          	auipc	ra,0xffffe
    800024e0:	70e080e7          	jalr	1806(ra) # 80000bea <acquire>
    havekids = 0;
    800024e4:	4c81                	li	s9,0
        if(np->state == ZOMBIE){
    800024e6:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800024e8:	00017997          	auipc	s3,0x17
    800024ec:	3c098993          	addi	s3,s3,960 # 800198a8 <tickslock>
        havekids = 1;
    800024f0:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024f2:	00010d17          	auipc	s10,0x10
    800024f6:	926d0d13          	addi	s10,s10,-1754 # 80011e18 <wait_lock>
    havekids = 0;
    800024fa:	8766                	mv	a4,s9
    for(np = proc; np < &proc[NPROC]; np++){
    800024fc:	00010497          	auipc	s1,0x10
    80002500:	7ac48493          	addi	s1,s1,1964 # 80012ca8 <proc>
    80002504:	a059                	j	8000258a <waitx+0xe2>
          pid = np->pid;
    80002506:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    8000250a:	1684a703          	lw	a4,360(s1)
    8000250e:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002512:	16c4a783          	lw	a5,364(s1)
    80002516:	9f3d                	addw	a4,a4,a5
    80002518:	1704a783          	lw	a5,368(s1)
    8000251c:	9f99                	subw	a5,a5,a4
    8000251e:	00fba023          	sw	a5,0(s7) # fffffffffffff000 <end+0xffffffff7ffd8ff8>
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002522:	000b0e63          	beqz	s6,8000253e <waitx+0x96>
    80002526:	4691                	li	a3,4
    80002528:	02c48613          	addi	a2,s1,44
    8000252c:	85da                	mv	a1,s6
    8000252e:	05093503          	ld	a0,80(s2)
    80002532:	fffff097          	auipc	ra,0xfffff
    80002536:	152080e7          	jalr	338(ra) # 80001684 <copyout>
    8000253a:	02054563          	bltz	a0,80002564 <waitx+0xbc>
          freeproc(np);
    8000253e:	8526                	mv	a0,s1
    80002540:	00000097          	auipc	ra,0x0
    80002544:	838080e7          	jalr	-1992(ra) # 80001d78 <freeproc>
          release(&np->lock);
    80002548:	8526                	mv	a0,s1
    8000254a:	ffffe097          	auipc	ra,0xffffe
    8000254e:	754080e7          	jalr	1876(ra) # 80000c9e <release>
          release(&wait_lock);
    80002552:	00010517          	auipc	a0,0x10
    80002556:	8c650513          	addi	a0,a0,-1850 # 80011e18 <wait_lock>
    8000255a:	ffffe097          	auipc	ra,0xffffe
    8000255e:	744080e7          	jalr	1860(ra) # 80000c9e <release>
          return pid;
    80002562:	a09d                	j	800025c8 <waitx+0x120>
            release(&np->lock);
    80002564:	8526                	mv	a0,s1
    80002566:	ffffe097          	auipc	ra,0xffffe
    8000256a:	738080e7          	jalr	1848(ra) # 80000c9e <release>
            release(&wait_lock);
    8000256e:	00010517          	auipc	a0,0x10
    80002572:	8aa50513          	addi	a0,a0,-1878 # 80011e18 <wait_lock>
    80002576:	ffffe097          	auipc	ra,0xffffe
    8000257a:	728080e7          	jalr	1832(ra) # 80000c9e <release>
            return -1;
    8000257e:	59fd                	li	s3,-1
    80002580:	a0a1                	j	800025c8 <waitx+0x120>
    for(np = proc; np < &proc[NPROC]; np++){
    80002582:	1b048493          	addi	s1,s1,432
    80002586:	03348463          	beq	s1,s3,800025ae <waitx+0x106>
      if(np->parent == p){
    8000258a:	7c9c                	ld	a5,56(s1)
    8000258c:	ff279be3          	bne	a5,s2,80002582 <waitx+0xda>
        acquire(&np->lock);
    80002590:	8526                	mv	a0,s1
    80002592:	ffffe097          	auipc	ra,0xffffe
    80002596:	658080e7          	jalr	1624(ra) # 80000bea <acquire>
        if(np->state == ZOMBIE){
    8000259a:	4c9c                	lw	a5,24(s1)
    8000259c:	f74785e3          	beq	a5,s4,80002506 <waitx+0x5e>
        release(&np->lock);
    800025a0:	8526                	mv	a0,s1
    800025a2:	ffffe097          	auipc	ra,0xffffe
    800025a6:	6fc080e7          	jalr	1788(ra) # 80000c9e <release>
        havekids = 1;
    800025aa:	8756                	mv	a4,s5
    800025ac:	bfd9                	j	80002582 <waitx+0xda>
    if(!havekids || p->killed){
    800025ae:	c701                	beqz	a4,800025b6 <waitx+0x10e>
    800025b0:	02892783          	lw	a5,40(s2)
    800025b4:	cb8d                	beqz	a5,800025e6 <waitx+0x13e>
      release(&wait_lock);
    800025b6:	00010517          	auipc	a0,0x10
    800025ba:	86250513          	addi	a0,a0,-1950 # 80011e18 <wait_lock>
    800025be:	ffffe097          	auipc	ra,0xffffe
    800025c2:	6e0080e7          	jalr	1760(ra) # 80000c9e <release>
      return -1;
    800025c6:	59fd                	li	s3,-1
}
    800025c8:	854e                	mv	a0,s3
    800025ca:	60e6                	ld	ra,88(sp)
    800025cc:	6446                	ld	s0,80(sp)
    800025ce:	64a6                	ld	s1,72(sp)
    800025d0:	6906                	ld	s2,64(sp)
    800025d2:	79e2                	ld	s3,56(sp)
    800025d4:	7a42                	ld	s4,48(sp)
    800025d6:	7aa2                	ld	s5,40(sp)
    800025d8:	7b02                	ld	s6,32(sp)
    800025da:	6be2                	ld	s7,24(sp)
    800025dc:	6c42                	ld	s8,16(sp)
    800025de:	6ca2                	ld	s9,8(sp)
    800025e0:	6d02                	ld	s10,0(sp)
    800025e2:	6125                	addi	sp,sp,96
    800025e4:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800025e6:	85ea                	mv	a1,s10
    800025e8:	854a                	mv	a0,s2
    800025ea:	00000097          	auipc	ra,0x0
    800025ee:	e5a080e7          	jalr	-422(ra) # 80002444 <sleep>
    havekids = 0;
    800025f2:	b721                	j	800024fa <waitx+0x52>

00000000800025f4 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800025f4:	7139                	addi	sp,sp,-64
    800025f6:	fc06                	sd	ra,56(sp)
    800025f8:	f822                	sd	s0,48(sp)
    800025fa:	f426                	sd	s1,40(sp)
    800025fc:	f04a                	sd	s2,32(sp)
    800025fe:	ec4e                	sd	s3,24(sp)
    80002600:	e852                	sd	s4,16(sp)
    80002602:	e456                	sd	s5,8(sp)
    80002604:	0080                	addi	s0,sp,64
    80002606:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002608:	00010497          	auipc	s1,0x10
    8000260c:	6a048493          	addi	s1,s1,1696 # 80012ca8 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002610:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002612:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002614:	00017917          	auipc	s2,0x17
    80002618:	29490913          	addi	s2,s2,660 # 800198a8 <tickslock>
    8000261c:	a821                	j	80002634 <wakeup+0x40>
        p->state = RUNNABLE;
    8000261e:	0154ac23          	sw	s5,24(s1)
        // #ifdef MLFQ
		    //   enqueue(p);
	      // #endif
      }
      release(&p->lock);
    80002622:	8526                	mv	a0,s1
    80002624:	ffffe097          	auipc	ra,0xffffe
    80002628:	67a080e7          	jalr	1658(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000262c:	1b048493          	addi	s1,s1,432
    80002630:	03248463          	beq	s1,s2,80002658 <wakeup+0x64>
    if(p != myproc()){
    80002634:	fffff097          	auipc	ra,0xfffff
    80002638:	592080e7          	jalr	1426(ra) # 80001bc6 <myproc>
    8000263c:	fea488e3          	beq	s1,a0,8000262c <wakeup+0x38>
      acquire(&p->lock);
    80002640:	8526                	mv	a0,s1
    80002642:	ffffe097          	auipc	ra,0xffffe
    80002646:	5a8080e7          	jalr	1448(ra) # 80000bea <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000264a:	4c9c                	lw	a5,24(s1)
    8000264c:	fd379be3          	bne	a5,s3,80002622 <wakeup+0x2e>
    80002650:	709c                	ld	a5,32(s1)
    80002652:	fd4798e3          	bne	a5,s4,80002622 <wakeup+0x2e>
    80002656:	b7e1                	j	8000261e <wakeup+0x2a>
    }
  }
}
    80002658:	70e2                	ld	ra,56(sp)
    8000265a:	7442                	ld	s0,48(sp)
    8000265c:	74a2                	ld	s1,40(sp)
    8000265e:	7902                	ld	s2,32(sp)
    80002660:	69e2                	ld	s3,24(sp)
    80002662:	6a42                	ld	s4,16(sp)
    80002664:	6aa2                	ld	s5,8(sp)
    80002666:	6121                	addi	sp,sp,64
    80002668:	8082                	ret

000000008000266a <reparent>:
{
    8000266a:	7179                	addi	sp,sp,-48
    8000266c:	f406                	sd	ra,40(sp)
    8000266e:	f022                	sd	s0,32(sp)
    80002670:	ec26                	sd	s1,24(sp)
    80002672:	e84a                	sd	s2,16(sp)
    80002674:	e44e                	sd	s3,8(sp)
    80002676:	e052                	sd	s4,0(sp)
    80002678:	1800                	addi	s0,sp,48
    8000267a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000267c:	00010497          	auipc	s1,0x10
    80002680:	62c48493          	addi	s1,s1,1580 # 80012ca8 <proc>
      pp->parent = initproc;
    80002684:	00007a17          	auipc	s4,0x7
    80002688:	504a0a13          	addi	s4,s4,1284 # 80009b88 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000268c:	00017997          	auipc	s3,0x17
    80002690:	21c98993          	addi	s3,s3,540 # 800198a8 <tickslock>
    80002694:	a029                	j	8000269e <reparent+0x34>
    80002696:	1b048493          	addi	s1,s1,432
    8000269a:	01348d63          	beq	s1,s3,800026b4 <reparent+0x4a>
    if(pp->parent == p){
    8000269e:	7c9c                	ld	a5,56(s1)
    800026a0:	ff279be3          	bne	a5,s2,80002696 <reparent+0x2c>
      pp->parent = initproc;
    800026a4:	000a3503          	ld	a0,0(s4)
    800026a8:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800026aa:	00000097          	auipc	ra,0x0
    800026ae:	f4a080e7          	jalr	-182(ra) # 800025f4 <wakeup>
    800026b2:	b7d5                	j	80002696 <reparent+0x2c>
}
    800026b4:	70a2                	ld	ra,40(sp)
    800026b6:	7402                	ld	s0,32(sp)
    800026b8:	64e2                	ld	s1,24(sp)
    800026ba:	6942                	ld	s2,16(sp)
    800026bc:	69a2                	ld	s3,8(sp)
    800026be:	6a02                	ld	s4,0(sp)
    800026c0:	6145                	addi	sp,sp,48
    800026c2:	8082                	ret

00000000800026c4 <exit>:
{
    800026c4:	7179                	addi	sp,sp,-48
    800026c6:	f406                	sd	ra,40(sp)
    800026c8:	f022                	sd	s0,32(sp)
    800026ca:	ec26                	sd	s1,24(sp)
    800026cc:	e84a                	sd	s2,16(sp)
    800026ce:	e44e                	sd	s3,8(sp)
    800026d0:	e052                	sd	s4,0(sp)
    800026d2:	1800                	addi	s0,sp,48
    800026d4:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800026d6:	fffff097          	auipc	ra,0xfffff
    800026da:	4f0080e7          	jalr	1264(ra) # 80001bc6 <myproc>
    800026de:	89aa                	mv	s3,a0
  if(p == initproc)
    800026e0:	00007797          	auipc	a5,0x7
    800026e4:	4a87b783          	ld	a5,1192(a5) # 80009b88 <initproc>
    800026e8:	0d050493          	addi	s1,a0,208
    800026ec:	15050913          	addi	s2,a0,336
    800026f0:	02a79363          	bne	a5,a0,80002716 <exit+0x52>
    panic("init exiting");
    800026f4:	00007517          	auipc	a0,0x7
    800026f8:	b8c50513          	addi	a0,a0,-1140 # 80009280 <digits+0x240>
    800026fc:	ffffe097          	auipc	ra,0xffffe
    80002700:	e48080e7          	jalr	-440(ra) # 80000544 <panic>
      fileclose(f);
    80002704:	00003097          	auipc	ra,0x3
    80002708:	a0e080e7          	jalr	-1522(ra) # 80005112 <fileclose>
      p->ofile[fd] = 0;
    8000270c:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002710:	04a1                	addi	s1,s1,8
    80002712:	01248563          	beq	s1,s2,8000271c <exit+0x58>
    if(p->ofile[fd]){
    80002716:	6088                	ld	a0,0(s1)
    80002718:	f575                	bnez	a0,80002704 <exit+0x40>
    8000271a:	bfdd                	j	80002710 <exit+0x4c>
  begin_op();
    8000271c:	00002097          	auipc	ra,0x2
    80002720:	52a080e7          	jalr	1322(ra) # 80004c46 <begin_op>
  iput(p->cwd);
    80002724:	1509b503          	ld	a0,336(s3)
    80002728:	00002097          	auipc	ra,0x2
    8000272c:	d16080e7          	jalr	-746(ra) # 8000443e <iput>
  end_op();
    80002730:	00002097          	auipc	ra,0x2
    80002734:	596080e7          	jalr	1430(ra) # 80004cc6 <end_op>
  p->cwd = 0;
    80002738:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000273c:	0000f497          	auipc	s1,0xf
    80002740:	6dc48493          	addi	s1,s1,1756 # 80011e18 <wait_lock>
    80002744:	8526                	mv	a0,s1
    80002746:	ffffe097          	auipc	ra,0xffffe
    8000274a:	4a4080e7          	jalr	1188(ra) # 80000bea <acquire>
  reparent(p);
    8000274e:	854e                	mv	a0,s3
    80002750:	00000097          	auipc	ra,0x0
    80002754:	f1a080e7          	jalr	-230(ra) # 8000266a <reparent>
  wakeup(p->parent);
    80002758:	0389b503          	ld	a0,56(s3)
    8000275c:	00000097          	auipc	ra,0x0
    80002760:	e98080e7          	jalr	-360(ra) # 800025f4 <wakeup>
  acquire(&p->lock);
    80002764:	854e                	mv	a0,s3
    80002766:	ffffe097          	auipc	ra,0xffffe
    8000276a:	484080e7          	jalr	1156(ra) # 80000bea <acquire>
  p->xstate = status;
    8000276e:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002772:	4795                	li	a5,5
    80002774:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002778:	00007797          	auipc	a5,0x7
    8000277c:	4187a783          	lw	a5,1048(a5) # 80009b90 <ticks>
    80002780:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    80002784:	8526                	mv	a0,s1
    80002786:	ffffe097          	auipc	ra,0xffffe
    8000278a:	518080e7          	jalr	1304(ra) # 80000c9e <release>
  sched();
    8000278e:	00000097          	auipc	ra,0x0
    80002792:	ae0080e7          	jalr	-1312(ra) # 8000226e <sched>
  panic("zombie exit");
    80002796:	00007517          	auipc	a0,0x7
    8000279a:	afa50513          	addi	a0,a0,-1286 # 80009290 <digits+0x250>
    8000279e:	ffffe097          	auipc	ra,0xffffe
    800027a2:	da6080e7          	jalr	-602(ra) # 80000544 <panic>

00000000800027a6 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800027a6:	7179                	addi	sp,sp,-48
    800027a8:	f406                	sd	ra,40(sp)
    800027aa:	f022                	sd	s0,32(sp)
    800027ac:	ec26                	sd	s1,24(sp)
    800027ae:	e84a                	sd	s2,16(sp)
    800027b0:	e44e                	sd	s3,8(sp)
    800027b2:	1800                	addi	s0,sp,48
    800027b4:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800027b6:	00010497          	auipc	s1,0x10
    800027ba:	4f248493          	addi	s1,s1,1266 # 80012ca8 <proc>
    800027be:	00017997          	auipc	s3,0x17
    800027c2:	0ea98993          	addi	s3,s3,234 # 800198a8 <tickslock>
    acquire(&p->lock);
    800027c6:	8526                	mv	a0,s1
    800027c8:	ffffe097          	auipc	ra,0xffffe
    800027cc:	422080e7          	jalr	1058(ra) # 80000bea <acquire>
    if(p->pid == pid){
    800027d0:	589c                	lw	a5,48(s1)
    800027d2:	01278d63          	beq	a5,s2,800027ec <kill+0x46>
	      // #endif
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800027d6:	8526                	mv	a0,s1
    800027d8:	ffffe097          	auipc	ra,0xffffe
    800027dc:	4c6080e7          	jalr	1222(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800027e0:	1b048493          	addi	s1,s1,432
    800027e4:	ff3491e3          	bne	s1,s3,800027c6 <kill+0x20>
  }
  return -1;
    800027e8:	557d                	li	a0,-1
    800027ea:	a829                	j	80002804 <kill+0x5e>
      p->killed = 1;
    800027ec:	4785                	li	a5,1
    800027ee:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800027f0:	4c98                	lw	a4,24(s1)
    800027f2:	4789                	li	a5,2
    800027f4:	00f70f63          	beq	a4,a5,80002812 <kill+0x6c>
      release(&p->lock);
    800027f8:	8526                	mv	a0,s1
    800027fa:	ffffe097          	auipc	ra,0xffffe
    800027fe:	4a4080e7          	jalr	1188(ra) # 80000c9e <release>
      return 0;
    80002802:	4501                	li	a0,0
}
    80002804:	70a2                	ld	ra,40(sp)
    80002806:	7402                	ld	s0,32(sp)
    80002808:	64e2                	ld	s1,24(sp)
    8000280a:	6942                	ld	s2,16(sp)
    8000280c:	69a2                	ld	s3,8(sp)
    8000280e:	6145                	addi	sp,sp,48
    80002810:	8082                	ret
        p->state = RUNNABLE;
    80002812:	478d                	li	a5,3
    80002814:	cc9c                	sw	a5,24(s1)
    80002816:	b7cd                	j	800027f8 <kill+0x52>

0000000080002818 <setkilled>:

void
setkilled(struct proc *p)
{
    80002818:	1101                	addi	sp,sp,-32
    8000281a:	ec06                	sd	ra,24(sp)
    8000281c:	e822                	sd	s0,16(sp)
    8000281e:	e426                	sd	s1,8(sp)
    80002820:	1000                	addi	s0,sp,32
    80002822:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002824:	ffffe097          	auipc	ra,0xffffe
    80002828:	3c6080e7          	jalr	966(ra) # 80000bea <acquire>
  p->killed = 1;
    8000282c:	4785                	li	a5,1
    8000282e:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002830:	8526                	mv	a0,s1
    80002832:	ffffe097          	auipc	ra,0xffffe
    80002836:	46c080e7          	jalr	1132(ra) # 80000c9e <release>
}
    8000283a:	60e2                	ld	ra,24(sp)
    8000283c:	6442                	ld	s0,16(sp)
    8000283e:	64a2                	ld	s1,8(sp)
    80002840:	6105                	addi	sp,sp,32
    80002842:	8082                	ret

0000000080002844 <killed>:

int
killed(struct proc *p)
{
    80002844:	1101                	addi	sp,sp,-32
    80002846:	ec06                	sd	ra,24(sp)
    80002848:	e822                	sd	s0,16(sp)
    8000284a:	e426                	sd	s1,8(sp)
    8000284c:	e04a                	sd	s2,0(sp)
    8000284e:	1000                	addi	s0,sp,32
    80002850:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002852:	ffffe097          	auipc	ra,0xffffe
    80002856:	398080e7          	jalr	920(ra) # 80000bea <acquire>
  k = p->killed;
    8000285a:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000285e:	8526                	mv	a0,s1
    80002860:	ffffe097          	auipc	ra,0xffffe
    80002864:	43e080e7          	jalr	1086(ra) # 80000c9e <release>
  return k;
}
    80002868:	854a                	mv	a0,s2
    8000286a:	60e2                	ld	ra,24(sp)
    8000286c:	6442                	ld	s0,16(sp)
    8000286e:	64a2                	ld	s1,8(sp)
    80002870:	6902                	ld	s2,0(sp)
    80002872:	6105                	addi	sp,sp,32
    80002874:	8082                	ret

0000000080002876 <wait>:
{
    80002876:	715d                	addi	sp,sp,-80
    80002878:	e486                	sd	ra,72(sp)
    8000287a:	e0a2                	sd	s0,64(sp)
    8000287c:	fc26                	sd	s1,56(sp)
    8000287e:	f84a                	sd	s2,48(sp)
    80002880:	f44e                	sd	s3,40(sp)
    80002882:	f052                	sd	s4,32(sp)
    80002884:	ec56                	sd	s5,24(sp)
    80002886:	e85a                	sd	s6,16(sp)
    80002888:	e45e                	sd	s7,8(sp)
    8000288a:	e062                	sd	s8,0(sp)
    8000288c:	0880                	addi	s0,sp,80
    8000288e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002890:	fffff097          	auipc	ra,0xfffff
    80002894:	336080e7          	jalr	822(ra) # 80001bc6 <myproc>
    80002898:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000289a:	0000f517          	auipc	a0,0xf
    8000289e:	57e50513          	addi	a0,a0,1406 # 80011e18 <wait_lock>
    800028a2:	ffffe097          	auipc	ra,0xffffe
    800028a6:	348080e7          	jalr	840(ra) # 80000bea <acquire>
    havekids = 0;
    800028aa:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    800028ac:	4a15                	li	s4,5
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800028ae:	00017997          	auipc	s3,0x17
    800028b2:	ffa98993          	addi	s3,s3,-6 # 800198a8 <tickslock>
        havekids = 1;
    800028b6:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800028b8:	0000fc17          	auipc	s8,0xf
    800028bc:	560c0c13          	addi	s8,s8,1376 # 80011e18 <wait_lock>
    havekids = 0;
    800028c0:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800028c2:	00010497          	auipc	s1,0x10
    800028c6:	3e648493          	addi	s1,s1,998 # 80012ca8 <proc>
    800028ca:	a0bd                	j	80002938 <wait+0xc2>
          pid = pp->pid;
    800028cc:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800028d0:	000b0e63          	beqz	s6,800028ec <wait+0x76>
    800028d4:	4691                	li	a3,4
    800028d6:	02c48613          	addi	a2,s1,44
    800028da:	85da                	mv	a1,s6
    800028dc:	05093503          	ld	a0,80(s2)
    800028e0:	fffff097          	auipc	ra,0xfffff
    800028e4:	da4080e7          	jalr	-604(ra) # 80001684 <copyout>
    800028e8:	02054563          	bltz	a0,80002912 <wait+0x9c>
          freeproc(pp);
    800028ec:	8526                	mv	a0,s1
    800028ee:	fffff097          	auipc	ra,0xfffff
    800028f2:	48a080e7          	jalr	1162(ra) # 80001d78 <freeproc>
          release(&pp->lock);
    800028f6:	8526                	mv	a0,s1
    800028f8:	ffffe097          	auipc	ra,0xffffe
    800028fc:	3a6080e7          	jalr	934(ra) # 80000c9e <release>
          release(&wait_lock);
    80002900:	0000f517          	auipc	a0,0xf
    80002904:	51850513          	addi	a0,a0,1304 # 80011e18 <wait_lock>
    80002908:	ffffe097          	auipc	ra,0xffffe
    8000290c:	396080e7          	jalr	918(ra) # 80000c9e <release>
          return pid;
    80002910:	a0b5                	j	8000297c <wait+0x106>
            release(&pp->lock);
    80002912:	8526                	mv	a0,s1
    80002914:	ffffe097          	auipc	ra,0xffffe
    80002918:	38a080e7          	jalr	906(ra) # 80000c9e <release>
            release(&wait_lock);
    8000291c:	0000f517          	auipc	a0,0xf
    80002920:	4fc50513          	addi	a0,a0,1276 # 80011e18 <wait_lock>
    80002924:	ffffe097          	auipc	ra,0xffffe
    80002928:	37a080e7          	jalr	890(ra) # 80000c9e <release>
            return -1;
    8000292c:	59fd                	li	s3,-1
    8000292e:	a0b9                	j	8000297c <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002930:	1b048493          	addi	s1,s1,432
    80002934:	03348463          	beq	s1,s3,8000295c <wait+0xe6>
      if(pp->parent == p){
    80002938:	7c9c                	ld	a5,56(s1)
    8000293a:	ff279be3          	bne	a5,s2,80002930 <wait+0xba>
        acquire(&pp->lock);
    8000293e:	8526                	mv	a0,s1
    80002940:	ffffe097          	auipc	ra,0xffffe
    80002944:	2aa080e7          	jalr	682(ra) # 80000bea <acquire>
        if(pp->state == ZOMBIE){
    80002948:	4c9c                	lw	a5,24(s1)
    8000294a:	f94781e3          	beq	a5,s4,800028cc <wait+0x56>
        release(&pp->lock);
    8000294e:	8526                	mv	a0,s1
    80002950:	ffffe097          	auipc	ra,0xffffe
    80002954:	34e080e7          	jalr	846(ra) # 80000c9e <release>
        havekids = 1;
    80002958:	8756                	mv	a4,s5
    8000295a:	bfd9                	j	80002930 <wait+0xba>
    if(!havekids || killed(p)){
    8000295c:	c719                	beqz	a4,8000296a <wait+0xf4>
    8000295e:	854a                	mv	a0,s2
    80002960:	00000097          	auipc	ra,0x0
    80002964:	ee4080e7          	jalr	-284(ra) # 80002844 <killed>
    80002968:	c51d                	beqz	a0,80002996 <wait+0x120>
      release(&wait_lock);
    8000296a:	0000f517          	auipc	a0,0xf
    8000296e:	4ae50513          	addi	a0,a0,1198 # 80011e18 <wait_lock>
    80002972:	ffffe097          	auipc	ra,0xffffe
    80002976:	32c080e7          	jalr	812(ra) # 80000c9e <release>
      return -1;
    8000297a:	59fd                	li	s3,-1
}
    8000297c:	854e                	mv	a0,s3
    8000297e:	60a6                	ld	ra,72(sp)
    80002980:	6406                	ld	s0,64(sp)
    80002982:	74e2                	ld	s1,56(sp)
    80002984:	7942                	ld	s2,48(sp)
    80002986:	79a2                	ld	s3,40(sp)
    80002988:	7a02                	ld	s4,32(sp)
    8000298a:	6ae2                	ld	s5,24(sp)
    8000298c:	6b42                	ld	s6,16(sp)
    8000298e:	6ba2                	ld	s7,8(sp)
    80002990:	6c02                	ld	s8,0(sp)
    80002992:	6161                	addi	sp,sp,80
    80002994:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002996:	85e2                	mv	a1,s8
    80002998:	854a                	mv	a0,s2
    8000299a:	00000097          	auipc	ra,0x0
    8000299e:	aaa080e7          	jalr	-1366(ra) # 80002444 <sleep>
    havekids = 0;
    800029a2:	bf39                	j	800028c0 <wait+0x4a>

00000000800029a4 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800029a4:	7179                	addi	sp,sp,-48
    800029a6:	f406                	sd	ra,40(sp)
    800029a8:	f022                	sd	s0,32(sp)
    800029aa:	ec26                	sd	s1,24(sp)
    800029ac:	e84a                	sd	s2,16(sp)
    800029ae:	e44e                	sd	s3,8(sp)
    800029b0:	e052                	sd	s4,0(sp)
    800029b2:	1800                	addi	s0,sp,48
    800029b4:	84aa                	mv	s1,a0
    800029b6:	892e                	mv	s2,a1
    800029b8:	89b2                	mv	s3,a2
    800029ba:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800029bc:	fffff097          	auipc	ra,0xfffff
    800029c0:	20a080e7          	jalr	522(ra) # 80001bc6 <myproc>
  if(user_dst){
    800029c4:	c08d                	beqz	s1,800029e6 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800029c6:	86d2                	mv	a3,s4
    800029c8:	864e                	mv	a2,s3
    800029ca:	85ca                	mv	a1,s2
    800029cc:	6928                	ld	a0,80(a0)
    800029ce:	fffff097          	auipc	ra,0xfffff
    800029d2:	cb6080e7          	jalr	-842(ra) # 80001684 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800029d6:	70a2                	ld	ra,40(sp)
    800029d8:	7402                	ld	s0,32(sp)
    800029da:	64e2                	ld	s1,24(sp)
    800029dc:	6942                	ld	s2,16(sp)
    800029de:	69a2                	ld	s3,8(sp)
    800029e0:	6a02                	ld	s4,0(sp)
    800029e2:	6145                	addi	sp,sp,48
    800029e4:	8082                	ret
    memmove((char *)dst, src, len);
    800029e6:	000a061b          	sext.w	a2,s4
    800029ea:	85ce                	mv	a1,s3
    800029ec:	854a                	mv	a0,s2
    800029ee:	ffffe097          	auipc	ra,0xffffe
    800029f2:	358080e7          	jalr	856(ra) # 80000d46 <memmove>
    return 0;
    800029f6:	8526                	mv	a0,s1
    800029f8:	bff9                	j	800029d6 <either_copyout+0x32>

00000000800029fa <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800029fa:	7179                	addi	sp,sp,-48
    800029fc:	f406                	sd	ra,40(sp)
    800029fe:	f022                	sd	s0,32(sp)
    80002a00:	ec26                	sd	s1,24(sp)
    80002a02:	e84a                	sd	s2,16(sp)
    80002a04:	e44e                	sd	s3,8(sp)
    80002a06:	e052                	sd	s4,0(sp)
    80002a08:	1800                	addi	s0,sp,48
    80002a0a:	892a                	mv	s2,a0
    80002a0c:	84ae                	mv	s1,a1
    80002a0e:	89b2                	mv	s3,a2
    80002a10:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a12:	fffff097          	auipc	ra,0xfffff
    80002a16:	1b4080e7          	jalr	436(ra) # 80001bc6 <myproc>
  if(user_src){
    80002a1a:	c08d                	beqz	s1,80002a3c <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002a1c:	86d2                	mv	a3,s4
    80002a1e:	864e                	mv	a2,s3
    80002a20:	85ca                	mv	a1,s2
    80002a22:	6928                	ld	a0,80(a0)
    80002a24:	fffff097          	auipc	ra,0xfffff
    80002a28:	cec080e7          	jalr	-788(ra) # 80001710 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002a2c:	70a2                	ld	ra,40(sp)
    80002a2e:	7402                	ld	s0,32(sp)
    80002a30:	64e2                	ld	s1,24(sp)
    80002a32:	6942                	ld	s2,16(sp)
    80002a34:	69a2                	ld	s3,8(sp)
    80002a36:	6a02                	ld	s4,0(sp)
    80002a38:	6145                	addi	sp,sp,48
    80002a3a:	8082                	ret
    memmove(dst, (char*)src, len);
    80002a3c:	000a061b          	sext.w	a2,s4
    80002a40:	85ce                	mv	a1,s3
    80002a42:	854a                	mv	a0,s2
    80002a44:	ffffe097          	auipc	ra,0xffffe
    80002a48:	302080e7          	jalr	770(ra) # 80000d46 <memmove>
    return 0;
    80002a4c:	8526                	mv	a0,s1
    80002a4e:	bff9                	j	80002a2c <either_copyin+0x32>

0000000080002a50 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002a50:	715d                	addi	sp,sp,-80
    80002a52:	e486                	sd	ra,72(sp)
    80002a54:	e0a2                	sd	s0,64(sp)
    80002a56:	fc26                	sd	s1,56(sp)
    80002a58:	f84a                	sd	s2,48(sp)
    80002a5a:	f44e                	sd	s3,40(sp)
    80002a5c:	f052                	sd	s4,32(sp)
    80002a5e:	ec56                	sd	s5,24(sp)
    80002a60:	e85a                	sd	s6,16(sp)
    80002a62:	e45e                	sd	s7,8(sp)
    80002a64:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002a66:	00006517          	auipc	a0,0x6
    80002a6a:	66250513          	addi	a0,a0,1634 # 800090c8 <digits+0x88>
    80002a6e:	ffffe097          	auipc	ra,0xffffe
    80002a72:	b20080e7          	jalr	-1248(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a76:	00010497          	auipc	s1,0x10
    80002a7a:	38a48493          	addi	s1,s1,906 # 80012e00 <proc+0x158>
    80002a7e:	00017917          	auipc	s2,0x17
    80002a82:	f8290913          	addi	s2,s2,-126 # 80019a00 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a86:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002a88:	00007997          	auipc	s3,0x7
    80002a8c:	81898993          	addi	s3,s3,-2024 # 800092a0 <digits+0x260>
    printf("%d %s %s", p->pid, state, p->name);
    80002a90:	00007a97          	auipc	s5,0x7
    80002a94:	818a8a93          	addi	s5,s5,-2024 # 800092a8 <digits+0x268>
    printf("\n");
    80002a98:	00006a17          	auipc	s4,0x6
    80002a9c:	630a0a13          	addi	s4,s4,1584 # 800090c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002aa0:	00007b97          	auipc	s7,0x7
    80002aa4:	848b8b93          	addi	s7,s7,-1976 # 800092e8 <states.1801>
    80002aa8:	a00d                	j	80002aca <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002aaa:	ed86a583          	lw	a1,-296(a3)
    80002aae:	8556                	mv	a0,s5
    80002ab0:	ffffe097          	auipc	ra,0xffffe
    80002ab4:	ade080e7          	jalr	-1314(ra) # 8000058e <printf>
    printf("\n");
    80002ab8:	8552                	mv	a0,s4
    80002aba:	ffffe097          	auipc	ra,0xffffe
    80002abe:	ad4080e7          	jalr	-1324(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002ac2:	1b048493          	addi	s1,s1,432
    80002ac6:	03248163          	beq	s1,s2,80002ae8 <procdump+0x98>
    if(p->state == UNUSED)
    80002aca:	86a6                	mv	a3,s1
    80002acc:	ec04a783          	lw	a5,-320(s1)
    80002ad0:	dbed                	beqz	a5,80002ac2 <procdump+0x72>
      state = "???";
    80002ad2:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ad4:	fcfb6be3          	bltu	s6,a5,80002aaa <procdump+0x5a>
    80002ad8:	1782                	slli	a5,a5,0x20
    80002ada:	9381                	srli	a5,a5,0x20
    80002adc:	078e                	slli	a5,a5,0x3
    80002ade:	97de                	add	a5,a5,s7
    80002ae0:	6390                	ld	a2,0(a5)
    80002ae2:	f661                	bnez	a2,80002aaa <procdump+0x5a>
      state = "???";
    80002ae4:	864e                	mv	a2,s3
    80002ae6:	b7d1                	j	80002aaa <procdump+0x5a>
  }
}
    80002ae8:	60a6                	ld	ra,72(sp)
    80002aea:	6406                	ld	s0,64(sp)
    80002aec:	74e2                	ld	s1,56(sp)
    80002aee:	7942                	ld	s2,48(sp)
    80002af0:	79a2                	ld	s3,40(sp)
    80002af2:	7a02                	ld	s4,32(sp)
    80002af4:	6ae2                	ld	s5,24(sp)
    80002af6:	6b42                	ld	s6,16(sp)
    80002af8:	6ba2                	ld	s7,8(sp)
    80002afa:	6161                	addi	sp,sp,80
    80002afc:	8082                	ret

0000000080002afe <swtch>:
    80002afe:	00153023          	sd	ra,0(a0)
    80002b02:	00253423          	sd	sp,8(a0)
    80002b06:	e900                	sd	s0,16(a0)
    80002b08:	ed04                	sd	s1,24(a0)
    80002b0a:	03253023          	sd	s2,32(a0)
    80002b0e:	03353423          	sd	s3,40(a0)
    80002b12:	03453823          	sd	s4,48(a0)
    80002b16:	03553c23          	sd	s5,56(a0)
    80002b1a:	05653023          	sd	s6,64(a0)
    80002b1e:	05753423          	sd	s7,72(a0)
    80002b22:	05853823          	sd	s8,80(a0)
    80002b26:	05953c23          	sd	s9,88(a0)
    80002b2a:	07a53023          	sd	s10,96(a0)
    80002b2e:	07b53423          	sd	s11,104(a0)
    80002b32:	0005b083          	ld	ra,0(a1)
    80002b36:	0085b103          	ld	sp,8(a1)
    80002b3a:	6980                	ld	s0,16(a1)
    80002b3c:	6d84                	ld	s1,24(a1)
    80002b3e:	0205b903          	ld	s2,32(a1)
    80002b42:	0285b983          	ld	s3,40(a1)
    80002b46:	0305ba03          	ld	s4,48(a1)
    80002b4a:	0385ba83          	ld	s5,56(a1)
    80002b4e:	0405bb03          	ld	s6,64(a1)
    80002b52:	0485bb83          	ld	s7,72(a1)
    80002b56:	0505bc03          	ld	s8,80(a1)
    80002b5a:	0585bc83          	ld	s9,88(a1)
    80002b5e:	0605bd03          	ld	s10,96(a1)
    80002b62:	0685bd83          	ld	s11,104(a1)
    80002b66:	8082                	ret

0000000080002b68 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002b68:	1141                	addi	sp,sp,-16
    80002b6a:	e406                	sd	ra,8(sp)
    80002b6c:	e022                	sd	s0,0(sp)
    80002b6e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002b70:	00006597          	auipc	a1,0x6
    80002b74:	7a858593          	addi	a1,a1,1960 # 80009318 <states.1801+0x30>
    80002b78:	00017517          	auipc	a0,0x17
    80002b7c:	d3050513          	addi	a0,a0,-720 # 800198a8 <tickslock>
    80002b80:	ffffe097          	auipc	ra,0xffffe
    80002b84:	fda080e7          	jalr	-38(ra) # 80000b5a <initlock>
}
    80002b88:	60a2                	ld	ra,8(sp)
    80002b8a:	6402                	ld	s0,0(sp)
    80002b8c:	0141                	addi	sp,sp,16
    80002b8e:	8082                	ret

0000000080002b90 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002b90:	1141                	addi	sp,sp,-16
    80002b92:	e422                	sd	s0,8(sp)
    80002b94:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b96:	00004797          	auipc	a5,0x4
    80002b9a:	bba78793          	addi	a5,a5,-1094 # 80006750 <kernelvec>
    80002b9e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002ba2:	6422                	ld	s0,8(sp)
    80002ba4:	0141                	addi	sp,sp,16
    80002ba6:	8082                	ret

0000000080002ba8 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002ba8:	1141                	addi	sp,sp,-16
    80002baa:	e406                	sd	ra,8(sp)
    80002bac:	e022                	sd	s0,0(sp)
    80002bae:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002bb0:	fffff097          	auipc	ra,0xfffff
    80002bb4:	016080e7          	jalr	22(ra) # 80001bc6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bb8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002bbc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bbe:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002bc2:	00005617          	auipc	a2,0x5
    80002bc6:	43e60613          	addi	a2,a2,1086 # 80008000 <_trampoline>
    80002bca:	00005697          	auipc	a3,0x5
    80002bce:	43668693          	addi	a3,a3,1078 # 80008000 <_trampoline>
    80002bd2:	8e91                	sub	a3,a3,a2
    80002bd4:	040007b7          	lui	a5,0x4000
    80002bd8:	17fd                	addi	a5,a5,-1
    80002bda:	07b2                	slli	a5,a5,0xc
    80002bdc:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bde:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002be2:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002be4:	180026f3          	csrr	a3,satp
    80002be8:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002bea:	6d38                	ld	a4,88(a0)
    80002bec:	6134                	ld	a3,64(a0)
    80002bee:	6585                	lui	a1,0x1
    80002bf0:	96ae                	add	a3,a3,a1
    80002bf2:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002bf4:	6d38                	ld	a4,88(a0)
    80002bf6:	00000697          	auipc	a3,0x0
    80002bfa:	13e68693          	addi	a3,a3,318 # 80002d34 <usertrap>
    80002bfe:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002c00:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c02:	8692                	mv	a3,tp
    80002c04:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c06:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c0a:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c0e:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c12:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002c16:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c18:	6f18                	ld	a4,24(a4)
    80002c1a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002c1e:	6928                	ld	a0,80(a0)
    80002c20:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002c22:	00005717          	auipc	a4,0x5
    80002c26:	47a70713          	addi	a4,a4,1146 # 8000809c <userret>
    80002c2a:	8f11                	sub	a4,a4,a2
    80002c2c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002c2e:	577d                	li	a4,-1
    80002c30:	177e                	slli	a4,a4,0x3f
    80002c32:	8d59                	or	a0,a0,a4
    80002c34:	9782                	jalr	a5
}
    80002c36:	60a2                	ld	ra,8(sp)
    80002c38:	6402                	ld	s0,0(sp)
    80002c3a:	0141                	addi	sp,sp,16
    80002c3c:	8082                	ret

0000000080002c3e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002c3e:	1101                	addi	sp,sp,-32
    80002c40:	ec06                	sd	ra,24(sp)
    80002c42:	e822                	sd	s0,16(sp)
    80002c44:	e426                	sd	s1,8(sp)
    80002c46:	e04a                	sd	s2,0(sp)
    80002c48:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002c4a:	00017917          	auipc	s2,0x17
    80002c4e:	c5e90913          	addi	s2,s2,-930 # 800198a8 <tickslock>
    80002c52:	854a                	mv	a0,s2
    80002c54:	ffffe097          	auipc	ra,0xffffe
    80002c58:	f96080e7          	jalr	-106(ra) # 80000bea <acquire>
  ticks++;
    80002c5c:	00007497          	auipc	s1,0x7
    80002c60:	f3448493          	addi	s1,s1,-204 # 80009b90 <ticks>
    80002c64:	409c                	lw	a5,0(s1)
    80002c66:	2785                	addiw	a5,a5,1
    80002c68:	c09c                	sw	a5,0(s1)
  update_time();
    80002c6a:	fffff097          	auipc	ra,0xfffff
    80002c6e:	716080e7          	jalr	1814(ra) # 80002380 <update_time>
  wakeup(&ticks);
    80002c72:	8526                	mv	a0,s1
    80002c74:	00000097          	auipc	ra,0x0
    80002c78:	980080e7          	jalr	-1664(ra) # 800025f4 <wakeup>
  release(&tickslock);
    80002c7c:	854a                	mv	a0,s2
    80002c7e:	ffffe097          	auipc	ra,0xffffe
    80002c82:	020080e7          	jalr	32(ra) # 80000c9e <release>
}
    80002c86:	60e2                	ld	ra,24(sp)
    80002c88:	6442                	ld	s0,16(sp)
    80002c8a:	64a2                	ld	s1,8(sp)
    80002c8c:	6902                	ld	s2,0(sp)
    80002c8e:	6105                	addi	sp,sp,32
    80002c90:	8082                	ret

0000000080002c92 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002c92:	1101                	addi	sp,sp,-32
    80002c94:	ec06                	sd	ra,24(sp)
    80002c96:	e822                	sd	s0,16(sp)
    80002c98:	e426                	sd	s1,8(sp)
    80002c9a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c9c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002ca0:	00074d63          	bltz	a4,80002cba <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002ca4:	57fd                	li	a5,-1
    80002ca6:	17fe                	slli	a5,a5,0x3f
    80002ca8:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002caa:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002cac:	06f70363          	beq	a4,a5,80002d12 <devintr+0x80>
  }
}
    80002cb0:	60e2                	ld	ra,24(sp)
    80002cb2:	6442                	ld	s0,16(sp)
    80002cb4:	64a2                	ld	s1,8(sp)
    80002cb6:	6105                	addi	sp,sp,32
    80002cb8:	8082                	ret
     (scause & 0xff) == 9){
    80002cba:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002cbe:	46a5                	li	a3,9
    80002cc0:	fed792e3          	bne	a5,a3,80002ca4 <devintr+0x12>
    int irq = plic_claim();
    80002cc4:	00004097          	auipc	ra,0x4
    80002cc8:	b94080e7          	jalr	-1132(ra) # 80006858 <plic_claim>
    80002ccc:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002cce:	47a9                	li	a5,10
    80002cd0:	02f50763          	beq	a0,a5,80002cfe <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002cd4:	4785                	li	a5,1
    80002cd6:	02f50963          	beq	a0,a5,80002d08 <devintr+0x76>
    return 1;
    80002cda:	4505                	li	a0,1
    } else if(irq){
    80002cdc:	d8f1                	beqz	s1,80002cb0 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002cde:	85a6                	mv	a1,s1
    80002ce0:	00006517          	auipc	a0,0x6
    80002ce4:	64050513          	addi	a0,a0,1600 # 80009320 <states.1801+0x38>
    80002ce8:	ffffe097          	auipc	ra,0xffffe
    80002cec:	8a6080e7          	jalr	-1882(ra) # 8000058e <printf>
      plic_complete(irq);
    80002cf0:	8526                	mv	a0,s1
    80002cf2:	00004097          	auipc	ra,0x4
    80002cf6:	b8a080e7          	jalr	-1142(ra) # 8000687c <plic_complete>
    return 1;
    80002cfa:	4505                	li	a0,1
    80002cfc:	bf55                	j	80002cb0 <devintr+0x1e>
      uartintr();
    80002cfe:	ffffe097          	auipc	ra,0xffffe
    80002d02:	cb0080e7          	jalr	-848(ra) # 800009ae <uartintr>
    80002d06:	b7ed                	j	80002cf0 <devintr+0x5e>
      virtio_disk_intr();
    80002d08:	00004097          	auipc	ra,0x4
    80002d0c:	09e080e7          	jalr	158(ra) # 80006da6 <virtio_disk_intr>
    80002d10:	b7c5                	j	80002cf0 <devintr+0x5e>
    if(cpuid() == 0){
    80002d12:	fffff097          	auipc	ra,0xfffff
    80002d16:	e88080e7          	jalr	-376(ra) # 80001b9a <cpuid>
    80002d1a:	c901                	beqz	a0,80002d2a <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002d1c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002d20:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002d22:	14479073          	csrw	sip,a5
    return 2;
    80002d26:	4509                	li	a0,2
    80002d28:	b761                	j	80002cb0 <devintr+0x1e>
      clockintr();
    80002d2a:	00000097          	auipc	ra,0x0
    80002d2e:	f14080e7          	jalr	-236(ra) # 80002c3e <clockintr>
    80002d32:	b7ed                	j	80002d1c <devintr+0x8a>

0000000080002d34 <usertrap>:
{
    80002d34:	7179                	addi	sp,sp,-48
    80002d36:	f406                	sd	ra,40(sp)
    80002d38:	f022                	sd	s0,32(sp)
    80002d3a:	ec26                	sd	s1,24(sp)
    80002d3c:	e84a                	sd	s2,16(sp)
    80002d3e:	e44e                	sd	s3,8(sp)
    80002d40:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d42:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002d46:	1007f793          	andi	a5,a5,256
    80002d4a:	e3a5                	bnez	a5,80002daa <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d4c:	00004797          	auipc	a5,0x4
    80002d50:	a0478793          	addi	a5,a5,-1532 # 80006750 <kernelvec>
    80002d54:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002d58:	fffff097          	auipc	ra,0xfffff
    80002d5c:	e6e080e7          	jalr	-402(ra) # 80001bc6 <myproc>
    80002d60:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002d62:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d64:	14102773          	csrr	a4,sepc
    80002d68:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d6a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002d6e:	47a1                	li	a5,8
    80002d70:	04f70563          	beq	a4,a5,80002dba <usertrap+0x86>
  } else if((which_dev = devintr()) != 0){
    80002d74:	00000097          	auipc	ra,0x0
    80002d78:	f1e080e7          	jalr	-226(ra) # 80002c92 <devintr>
    80002d7c:	892a                	mv	s2,a0
    80002d7e:	cd69                	beqz	a0,80002e58 <usertrap+0x124>
    if(which_dev == 2 && myproc()->interval) {
    80002d80:	4789                	li	a5,2
    80002d82:	06f50763          	beq	a0,a5,80002df0 <usertrap+0xbc>
  if(killed(p))
    80002d86:	8526                	mv	a0,s1
    80002d88:	00000097          	auipc	ra,0x0
    80002d8c:	abc080e7          	jalr	-1348(ra) # 80002844 <killed>
    80002d90:	10051163          	bnez	a0,80002e92 <usertrap+0x15e>
  usertrapret();
    80002d94:	00000097          	auipc	ra,0x0
    80002d98:	e14080e7          	jalr	-492(ra) # 80002ba8 <usertrapret>
}
    80002d9c:	70a2                	ld	ra,40(sp)
    80002d9e:	7402                	ld	s0,32(sp)
    80002da0:	64e2                	ld	s1,24(sp)
    80002da2:	6942                	ld	s2,16(sp)
    80002da4:	69a2                	ld	s3,8(sp)
    80002da6:	6145                	addi	sp,sp,48
    80002da8:	8082                	ret
    panic("usertrap: not from user mode");
    80002daa:	00006517          	auipc	a0,0x6
    80002dae:	59650513          	addi	a0,a0,1430 # 80009340 <states.1801+0x58>
    80002db2:	ffffd097          	auipc	ra,0xffffd
    80002db6:	792080e7          	jalr	1938(ra) # 80000544 <panic>
    if(killed(p))
    80002dba:	00000097          	auipc	ra,0x0
    80002dbe:	a8a080e7          	jalr	-1398(ra) # 80002844 <killed>
    80002dc2:	e10d                	bnez	a0,80002de4 <usertrap+0xb0>
    p->trapframe->epc += 4;
    80002dc4:	6cb8                	ld	a4,88(s1)
    80002dc6:	6f1c                	ld	a5,24(a4)
    80002dc8:	0791                	addi	a5,a5,4
    80002dca:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002dcc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002dd0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002dd4:	10079073          	csrw	sstatus,a5
    syscall();
    80002dd8:	00000097          	auipc	ra,0x0
    80002ddc:	404080e7          	jalr	1028(ra) # 800031dc <syscall>
  int which_dev = 0;
    80002de0:	4901                	li	s2,0
    80002de2:	b755                	j	80002d86 <usertrap+0x52>
      exit(-1);
    80002de4:	557d                	li	a0,-1
    80002de6:	00000097          	auipc	ra,0x0
    80002dea:	8de080e7          	jalr	-1826(ra) # 800026c4 <exit>
    80002dee:	bfd9                	j	80002dc4 <usertrap+0x90>
    if(which_dev == 2 && myproc()->interval) {
    80002df0:	fffff097          	auipc	ra,0xfffff
    80002df4:	dd6080e7          	jalr	-554(ra) # 80001bc6 <myproc>
    80002df8:	17852783          	lw	a5,376(a0)
    80002dfc:	ef89                	bnez	a5,80002e16 <usertrap+0xe2>
  if(killed(p))
    80002dfe:	8526                	mv	a0,s1
    80002e00:	00000097          	auipc	ra,0x0
    80002e04:	a44080e7          	jalr	-1468(ra) # 80002844 <killed>
    80002e08:	cd49                	beqz	a0,80002ea2 <usertrap+0x16e>
    exit(-1);
    80002e0a:	557d                	li	a0,-1
    80002e0c:	00000097          	auipc	ra,0x0
    80002e10:	8b8080e7          	jalr	-1864(ra) # 800026c4 <exit>
    if(which_dev == 2 && myproc()->state == RUNNING && myproc() != 0) {
    80002e14:	a079                	j	80002ea2 <usertrap+0x16e>
      myproc()->ticks_left--;
    80002e16:	fffff097          	auipc	ra,0xfffff
    80002e1a:	db0080e7          	jalr	-592(ra) # 80001bc6 <myproc>
    80002e1e:	17c52783          	lw	a5,380(a0)
    80002e22:	37fd                	addiw	a5,a5,-1
    80002e24:	16f52e23          	sw	a5,380(a0)
      if(myproc()->ticks_left == 0) {
    80002e28:	fffff097          	auipc	ra,0xfffff
    80002e2c:	d9e080e7          	jalr	-610(ra) # 80001bc6 <myproc>
    80002e30:	17c52783          	lw	a5,380(a0)
    80002e34:	f7e9                	bnez	a5,80002dfe <usertrap+0xca>
        p->sigalarm_tf = kalloc();
    80002e36:	ffffe097          	auipc	ra,0xffffe
    80002e3a:	cc4080e7          	jalr	-828(ra) # 80000afa <kalloc>
    80002e3e:	18a4b423          	sd	a0,392(s1)
        memmove(p->sigalarm_tf, p->trapframe, PGSIZE);
    80002e42:	6605                	lui	a2,0x1
    80002e44:	6cac                	ld	a1,88(s1)
    80002e46:	ffffe097          	auipc	ra,0xffffe
    80002e4a:	f00080e7          	jalr	-256(ra) # 80000d46 <memmove>
        p->trapframe->epc = p->sig_handler;
    80002e4e:	6cbc                	ld	a5,88(s1)
    80002e50:	1804b703          	ld	a4,384(s1)
    80002e54:	ef98                	sd	a4,24(a5)
    80002e56:	b765                	j	80002dfe <usertrap+0xca>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e58:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002e5c:	5890                	lw	a2,48(s1)
    80002e5e:	00006517          	auipc	a0,0x6
    80002e62:	50250513          	addi	a0,a0,1282 # 80009360 <states.1801+0x78>
    80002e66:	ffffd097          	auipc	ra,0xffffd
    80002e6a:	728080e7          	jalr	1832(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e6e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e72:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e76:	00006517          	auipc	a0,0x6
    80002e7a:	51a50513          	addi	a0,a0,1306 # 80009390 <states.1801+0xa8>
    80002e7e:	ffffd097          	auipc	ra,0xffffd
    80002e82:	710080e7          	jalr	1808(ra) # 8000058e <printf>
    setkilled(p);
    80002e86:	8526                	mv	a0,s1
    80002e88:	00000097          	auipc	ra,0x0
    80002e8c:	990080e7          	jalr	-1648(ra) # 80002818 <setkilled>
    80002e90:	bddd                	j	80002d86 <usertrap+0x52>
    exit(-1);
    80002e92:	557d                	li	a0,-1
    80002e94:	00000097          	auipc	ra,0x0
    80002e98:	830080e7          	jalr	-2000(ra) # 800026c4 <exit>
    if(which_dev == 2 && myproc()->state == RUNNING && myproc() != 0) {
    80002e9c:	4789                	li	a5,2
    80002e9e:	eef91be3          	bne	s2,a5,80002d94 <usertrap+0x60>
    80002ea2:	fffff097          	auipc	ra,0xfffff
    80002ea6:	d24080e7          	jalr	-732(ra) # 80001bc6 <myproc>
    80002eaa:	4d18                	lw	a4,24(a0)
    80002eac:	4791                	li	a5,4
    80002eae:	eef713e3          	bne	a4,a5,80002d94 <usertrap+0x60>
    80002eb2:	fffff097          	auipc	ra,0xfffff
    80002eb6:	d14080e7          	jalr	-748(ra) # 80001bc6 <myproc>
    80002eba:	ec050de3          	beqz	a0,80002d94 <usertrap+0x60>
      if(p->curr_rtime >= priority_levels[p->priority]) {
    80002ebe:	1984a703          	lw	a4,408(s1)
    80002ec2:	00271693          	slli	a3,a4,0x2
    80002ec6:	00007797          	auipc	a5,0x7
    80002eca:	b8278793          	addi	a5,a5,-1150 # 80009a48 <priority_levels>
    80002ece:	97b6                	add	a5,a5,a3
    80002ed0:	1a04a683          	lw	a3,416(s1)
    80002ed4:	439c                	lw	a5,0(a5)
    80002ed6:	00f6da63          	bge	a3,a5,80002eea <usertrap+0x1b6>
        for(int i = 0; i < p->priority; i++) {
    80002eda:	0000f997          	auipc	s3,0xf
    80002ede:	35e98993          	addi	s3,s3,862 # 80012238 <queues+0x8>
    80002ee2:	4901                	li	s2,0
    80002ee4:	02e04963          	bgtz	a4,80002f16 <usertrap+0x1e2>
    80002ee8:	b575                	j	80002d94 <usertrap+0x60>
        if(p->priority != 4) {
    80002eea:	4791                	li	a5,4
    80002eec:	00f70563          	beq	a4,a5,80002ef6 <usertrap+0x1c2>
          p->priority++;
    80002ef0:	2705                	addiw	a4,a4,1
    80002ef2:	18e4ac23          	sw	a4,408(s1)
        p->curr_rtime = 0;
    80002ef6:	1a04a023          	sw	zero,416(s1)
        p->curr_wtime = 0;
    80002efa:	1a04a223          	sw	zero,420(s1)
        yield();
    80002efe:	fffff097          	auipc	ra,0xfffff
    80002f02:	446080e7          	jalr	1094(ra) # 80002344 <yield>
    80002f06:	b579                	j	80002d94 <usertrap+0x60>
        for(int i = 0; i < p->priority; i++) {
    80002f08:	2905                	addiw	s2,s2,1
    80002f0a:	21898993          	addi	s3,s3,536
    80002f0e:	1984a783          	lw	a5,408(s1)
    80002f12:	e8f951e3          	bge	s2,a5,80002d94 <usertrap+0x60>
          if(queues[i].length > 0) {
    80002f16:	0009a783          	lw	a5,0(s3)
    80002f1a:	fef057e3          	blez	a5,80002f08 <usertrap+0x1d4>
            yield();
    80002f1e:	fffff097          	auipc	ra,0xfffff
    80002f22:	426080e7          	jalr	1062(ra) # 80002344 <yield>
    80002f26:	b7cd                	j	80002f08 <usertrap+0x1d4>

0000000080002f28 <kerneltrap>:
{
    80002f28:	7139                	addi	sp,sp,-64
    80002f2a:	fc06                	sd	ra,56(sp)
    80002f2c:	f822                	sd	s0,48(sp)
    80002f2e:	f426                	sd	s1,40(sp)
    80002f30:	f04a                	sd	s2,32(sp)
    80002f32:	ec4e                	sd	s3,24(sp)
    80002f34:	e852                	sd	s4,16(sp)
    80002f36:	e456                	sd	s5,8(sp)
    80002f38:	0080                	addi	s0,sp,64
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f3a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f3e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f42:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002f46:	1004f793          	andi	a5,s1,256
    80002f4a:	cb95                	beqz	a5,80002f7e <kerneltrap+0x56>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f4c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002f50:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002f52:	ef95                	bnez	a5,80002f8e <kerneltrap+0x66>
  if((which_dev = devintr()) == 0){
    80002f54:	00000097          	auipc	ra,0x0
    80002f58:	d3e080e7          	jalr	-706(ra) # 80002c92 <devintr>
    80002f5c:	c129                	beqz	a0,80002f9e <kerneltrap+0x76>
    if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING) {
    80002f5e:	4789                	li	a5,2
    80002f60:	06f50c63          	beq	a0,a5,80002fd8 <kerneltrap+0xb0>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f64:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f68:	10049073          	csrw	sstatus,s1
}
    80002f6c:	70e2                	ld	ra,56(sp)
    80002f6e:	7442                	ld	s0,48(sp)
    80002f70:	74a2                	ld	s1,40(sp)
    80002f72:	7902                	ld	s2,32(sp)
    80002f74:	69e2                	ld	s3,24(sp)
    80002f76:	6a42                	ld	s4,16(sp)
    80002f78:	6aa2                	ld	s5,8(sp)
    80002f7a:	6121                	addi	sp,sp,64
    80002f7c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002f7e:	00006517          	auipc	a0,0x6
    80002f82:	43250513          	addi	a0,a0,1074 # 800093b0 <states.1801+0xc8>
    80002f86:	ffffd097          	auipc	ra,0xffffd
    80002f8a:	5be080e7          	jalr	1470(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    80002f8e:	00006517          	auipc	a0,0x6
    80002f92:	44a50513          	addi	a0,a0,1098 # 800093d8 <states.1801+0xf0>
    80002f96:	ffffd097          	auipc	ra,0xffffd
    80002f9a:	5ae080e7          	jalr	1454(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    80002f9e:	85ce                	mv	a1,s3
    80002fa0:	00006517          	auipc	a0,0x6
    80002fa4:	45850513          	addi	a0,a0,1112 # 800093f8 <states.1801+0x110>
    80002fa8:	ffffd097          	auipc	ra,0xffffd
    80002fac:	5e6080e7          	jalr	1510(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fb0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002fb4:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002fb8:	00006517          	auipc	a0,0x6
    80002fbc:	45050513          	addi	a0,a0,1104 # 80009408 <states.1801+0x120>
    80002fc0:	ffffd097          	auipc	ra,0xffffd
    80002fc4:	5ce080e7          	jalr	1486(ra) # 8000058e <printf>
    panic("kerneltrap");
    80002fc8:	00006517          	auipc	a0,0x6
    80002fcc:	45850513          	addi	a0,a0,1112 # 80009420 <states.1801+0x138>
    80002fd0:	ffffd097          	auipc	ra,0xffffd
    80002fd4:	574080e7          	jalr	1396(ra) # 80000544 <panic>
    if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING) {
    80002fd8:	fffff097          	auipc	ra,0xfffff
    80002fdc:	bee080e7          	jalr	-1042(ra) # 80001bc6 <myproc>
    80002fe0:	d151                	beqz	a0,80002f64 <kerneltrap+0x3c>
    80002fe2:	fffff097          	auipc	ra,0xfffff
    80002fe6:	be4080e7          	jalr	-1052(ra) # 80001bc6 <myproc>
    80002fea:	4d18                	lw	a4,24(a0)
    80002fec:	4791                	li	a5,4
    80002fee:	f6f71be3          	bne	a4,a5,80002f64 <kerneltrap+0x3c>
      struct proc* p = myproc();
    80002ff2:	fffff097          	auipc	ra,0xfffff
    80002ff6:	bd4080e7          	jalr	-1068(ra) # 80001bc6 <myproc>
    80002ffa:	8aaa                	mv	s5,a0
      if(p->curr_rtime >= priority_levels[p->priority]) {
    80002ffc:	19852703          	lw	a4,408(a0)
    80003000:	00271693          	slli	a3,a4,0x2
    80003004:	00007797          	auipc	a5,0x7
    80003008:	a4478793          	addi	a5,a5,-1468 # 80009a48 <priority_levels>
    8000300c:	97b6                	add	a5,a5,a3
    8000300e:	1a052683          	lw	a3,416(a0)
    80003012:	439c                	lw	a5,0(a5)
    80003014:	00f6da63          	bge	a3,a5,80003028 <kerneltrap+0x100>
        for(int i = 0; i < p->priority; i++) {
    80003018:	0000fa17          	auipc	s4,0xf
    8000301c:	220a0a13          	addi	s4,s4,544 # 80012238 <queues+0x8>
    80003020:	4981                	li	s3,0
    80003022:	02e04563          	bgtz	a4,8000304c <kerneltrap+0x124>
    80003026:	bf3d                	j	80002f64 <kerneltrap+0x3c>
        if(p->priority != 4) {
    80003028:	4791                	li	a5,4
    8000302a:	00f70563          	beq	a4,a5,80003034 <kerneltrap+0x10c>
          p->priority++;
    8000302e:	2705                	addiw	a4,a4,1
    80003030:	18e52c23          	sw	a4,408(a0)
        yield();
    80003034:	fffff097          	auipc	ra,0xfffff
    80003038:	310080e7          	jalr	784(ra) # 80002344 <yield>
    8000303c:	b725                	j	80002f64 <kerneltrap+0x3c>
        for(int i = 0; i < p->priority; i++) {
    8000303e:	2985                	addiw	s3,s3,1
    80003040:	218a0a13          	addi	s4,s4,536
    80003044:	198aa783          	lw	a5,408(s5)
    80003048:	f0f9dee3          	bge	s3,a5,80002f64 <kerneltrap+0x3c>
          if(queues[i].length > 0) {
    8000304c:	000a2783          	lw	a5,0(s4)
    80003050:	fef057e3          	blez	a5,8000303e <kerneltrap+0x116>
            yield();
    80003054:	fffff097          	auipc	ra,0xfffff
    80003058:	2f0080e7          	jalr	752(ra) # 80002344 <yield>
    8000305c:	b7cd                	j	8000303e <kerneltrap+0x116>

000000008000305e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000305e:	1101                	addi	sp,sp,-32
    80003060:	ec06                	sd	ra,24(sp)
    80003062:	e822                	sd	s0,16(sp)
    80003064:	e426                	sd	s1,8(sp)
    80003066:	1000                	addi	s0,sp,32
    80003068:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000306a:	fffff097          	auipc	ra,0xfffff
    8000306e:	b5c080e7          	jalr	-1188(ra) # 80001bc6 <myproc>
  switch (n) {
    80003072:	4795                	li	a5,5
    80003074:	0497e163          	bltu	a5,s1,800030b6 <argraw+0x58>
    80003078:	048a                	slli	s1,s1,0x2
    8000307a:	00006717          	auipc	a4,0x6
    8000307e:	54670713          	addi	a4,a4,1350 # 800095c0 <states.1801+0x2d8>
    80003082:	94ba                	add	s1,s1,a4
    80003084:	409c                	lw	a5,0(s1)
    80003086:	97ba                	add	a5,a5,a4
    80003088:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    8000308a:	6d3c                	ld	a5,88(a0)
    8000308c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000308e:	60e2                	ld	ra,24(sp)
    80003090:	6442                	ld	s0,16(sp)
    80003092:	64a2                	ld	s1,8(sp)
    80003094:	6105                	addi	sp,sp,32
    80003096:	8082                	ret
    return p->trapframe->a1;
    80003098:	6d3c                	ld	a5,88(a0)
    8000309a:	7fa8                	ld	a0,120(a5)
    8000309c:	bfcd                	j	8000308e <argraw+0x30>
    return p->trapframe->a2;
    8000309e:	6d3c                	ld	a5,88(a0)
    800030a0:	63c8                	ld	a0,128(a5)
    800030a2:	b7f5                	j	8000308e <argraw+0x30>
    return p->trapframe->a3;
    800030a4:	6d3c                	ld	a5,88(a0)
    800030a6:	67c8                	ld	a0,136(a5)
    800030a8:	b7dd                	j	8000308e <argraw+0x30>
    return p->trapframe->a4;
    800030aa:	6d3c                	ld	a5,88(a0)
    800030ac:	6bc8                	ld	a0,144(a5)
    800030ae:	b7c5                	j	8000308e <argraw+0x30>
    return p->trapframe->a5;
    800030b0:	6d3c                	ld	a5,88(a0)
    800030b2:	6fc8                	ld	a0,152(a5)
    800030b4:	bfe9                	j	8000308e <argraw+0x30>
  panic("argraw");
    800030b6:	00006517          	auipc	a0,0x6
    800030ba:	37a50513          	addi	a0,a0,890 # 80009430 <states.1801+0x148>
    800030be:	ffffd097          	auipc	ra,0xffffd
    800030c2:	486080e7          	jalr	1158(ra) # 80000544 <panic>

00000000800030c6 <fetchaddr>:
{
    800030c6:	1101                	addi	sp,sp,-32
    800030c8:	ec06                	sd	ra,24(sp)
    800030ca:	e822                	sd	s0,16(sp)
    800030cc:	e426                	sd	s1,8(sp)
    800030ce:	e04a                	sd	s2,0(sp)
    800030d0:	1000                	addi	s0,sp,32
    800030d2:	84aa                	mv	s1,a0
    800030d4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800030d6:	fffff097          	auipc	ra,0xfffff
    800030da:	af0080e7          	jalr	-1296(ra) # 80001bc6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    800030de:	653c                	ld	a5,72(a0)
    800030e0:	02f4f863          	bgeu	s1,a5,80003110 <fetchaddr+0x4a>
    800030e4:	00848713          	addi	a4,s1,8
    800030e8:	02e7e663          	bltu	a5,a4,80003114 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800030ec:	46a1                	li	a3,8
    800030ee:	8626                	mv	a2,s1
    800030f0:	85ca                	mv	a1,s2
    800030f2:	6928                	ld	a0,80(a0)
    800030f4:	ffffe097          	auipc	ra,0xffffe
    800030f8:	61c080e7          	jalr	1564(ra) # 80001710 <copyin>
    800030fc:	00a03533          	snez	a0,a0
    80003100:	40a00533          	neg	a0,a0
}
    80003104:	60e2                	ld	ra,24(sp)
    80003106:	6442                	ld	s0,16(sp)
    80003108:	64a2                	ld	s1,8(sp)
    8000310a:	6902                	ld	s2,0(sp)
    8000310c:	6105                	addi	sp,sp,32
    8000310e:	8082                	ret
    return -1;
    80003110:	557d                	li	a0,-1
    80003112:	bfcd                	j	80003104 <fetchaddr+0x3e>
    80003114:	557d                	li	a0,-1
    80003116:	b7fd                	j	80003104 <fetchaddr+0x3e>

0000000080003118 <fetchstr>:
{
    80003118:	7179                	addi	sp,sp,-48
    8000311a:	f406                	sd	ra,40(sp)
    8000311c:	f022                	sd	s0,32(sp)
    8000311e:	ec26                	sd	s1,24(sp)
    80003120:	e84a                	sd	s2,16(sp)
    80003122:	e44e                	sd	s3,8(sp)
    80003124:	1800                	addi	s0,sp,48
    80003126:	892a                	mv	s2,a0
    80003128:	84ae                	mv	s1,a1
    8000312a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000312c:	fffff097          	auipc	ra,0xfffff
    80003130:	a9a080e7          	jalr	-1382(ra) # 80001bc6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80003134:	86ce                	mv	a3,s3
    80003136:	864a                	mv	a2,s2
    80003138:	85a6                	mv	a1,s1
    8000313a:	6928                	ld	a0,80(a0)
    8000313c:	ffffe097          	auipc	ra,0xffffe
    80003140:	660080e7          	jalr	1632(ra) # 8000179c <copyinstr>
    80003144:	00054e63          	bltz	a0,80003160 <fetchstr+0x48>
  return strlen(buf);
    80003148:	8526                	mv	a0,s1
    8000314a:	ffffe097          	auipc	ra,0xffffe
    8000314e:	d20080e7          	jalr	-736(ra) # 80000e6a <strlen>
}
    80003152:	70a2                	ld	ra,40(sp)
    80003154:	7402                	ld	s0,32(sp)
    80003156:	64e2                	ld	s1,24(sp)
    80003158:	6942                	ld	s2,16(sp)
    8000315a:	69a2                	ld	s3,8(sp)
    8000315c:	6145                	addi	sp,sp,48
    8000315e:	8082                	ret
    return -1;
    80003160:	557d                	li	a0,-1
    80003162:	bfc5                	j	80003152 <fetchstr+0x3a>

0000000080003164 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80003164:	1101                	addi	sp,sp,-32
    80003166:	ec06                	sd	ra,24(sp)
    80003168:	e822                	sd	s0,16(sp)
    8000316a:	e426                	sd	s1,8(sp)
    8000316c:	1000                	addi	s0,sp,32
    8000316e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003170:	00000097          	auipc	ra,0x0
    80003174:	eee080e7          	jalr	-274(ra) # 8000305e <argraw>
    80003178:	c088                	sw	a0,0(s1)
}
    8000317a:	60e2                	ld	ra,24(sp)
    8000317c:	6442                	ld	s0,16(sp)
    8000317e:	64a2                	ld	s1,8(sp)
    80003180:	6105                	addi	sp,sp,32
    80003182:	8082                	ret

0000000080003184 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80003184:	1101                	addi	sp,sp,-32
    80003186:	ec06                	sd	ra,24(sp)
    80003188:	e822                	sd	s0,16(sp)
    8000318a:	e426                	sd	s1,8(sp)
    8000318c:	1000                	addi	s0,sp,32
    8000318e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003190:	00000097          	auipc	ra,0x0
    80003194:	ece080e7          	jalr	-306(ra) # 8000305e <argraw>
    80003198:	e088                	sd	a0,0(s1)
}
    8000319a:	60e2                	ld	ra,24(sp)
    8000319c:	6442                	ld	s0,16(sp)
    8000319e:	64a2                	ld	s1,8(sp)
    800031a0:	6105                	addi	sp,sp,32
    800031a2:	8082                	ret

00000000800031a4 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800031a4:	7179                	addi	sp,sp,-48
    800031a6:	f406                	sd	ra,40(sp)
    800031a8:	f022                	sd	s0,32(sp)
    800031aa:	ec26                	sd	s1,24(sp)
    800031ac:	e84a                	sd	s2,16(sp)
    800031ae:	1800                	addi	s0,sp,48
    800031b0:	84ae                	mv	s1,a1
    800031b2:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800031b4:	fd840593          	addi	a1,s0,-40
    800031b8:	00000097          	auipc	ra,0x0
    800031bc:	fcc080e7          	jalr	-52(ra) # 80003184 <argaddr>
  return fetchstr(addr, buf, max);
    800031c0:	864a                	mv	a2,s2
    800031c2:	85a6                	mv	a1,s1
    800031c4:	fd843503          	ld	a0,-40(s0)
    800031c8:	00000097          	auipc	ra,0x0
    800031cc:	f50080e7          	jalr	-176(ra) # 80003118 <fetchstr>
}
    800031d0:	70a2                	ld	ra,40(sp)
    800031d2:	7402                	ld	s0,32(sp)
    800031d4:	64e2                	ld	s1,24(sp)
    800031d6:	6942                	ld	s2,16(sp)
    800031d8:	6145                	addi	sp,sp,48
    800031da:	8082                	ret

00000000800031dc <syscall>:
[SYS_waitx]      "sys_waitx",
};

void
syscall(void)
{
    800031dc:	7179                	addi	sp,sp,-48
    800031de:	f406                	sd	ra,40(sp)
    800031e0:	f022                	sd	s0,32(sp)
    800031e2:	ec26                	sd	s1,24(sp)
    800031e4:	e84a                	sd	s2,16(sp)
    800031e6:	e44e                	sd	s3,8(sp)
    800031e8:	e052                	sd	s4,0(sp)
    800031ea:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    800031ec:	fffff097          	auipc	ra,0xfffff
    800031f0:	9da080e7          	jalr	-1574(ra) # 80001bc6 <myproc>
    800031f4:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800031f6:	05853903          	ld	s2,88(a0)
    800031fa:	0a893783          	ld	a5,168(s2)
    800031fe:	0007899b          	sext.w	s3,a5
  unsigned int tmp = p->trapframe->a0;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003202:	37fd                	addiw	a5,a5,-1
    80003204:	4765                	li	a4,25
    80003206:	42f76863          	bltu	a4,a5,80003636 <syscall+0x45a>
    8000320a:	00399713          	slli	a4,s3,0x3
    8000320e:	00006797          	auipc	a5,0x6
    80003212:	3ca78793          	addi	a5,a5,970 # 800095d8 <syscalls>
    80003216:	97ba                	add	a5,a5,a4
    80003218:	639c                	ld	a5,0(a5)
    8000321a:	40078e63          	beqz	a5,80003636 <syscall+0x45a>
  unsigned int tmp = p->trapframe->a0;
    8000321e:	07093a03          	ld	s4,112(s2)
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80003222:	9782                	jalr	a5
    80003224:	06a93823          	sd	a0,112(s2)

    // Check for trace_flag to be on
    if(p->trace_flag >> num) {  // check for '=='
    80003228:	1744a783          	lw	a5,372(s1)
    8000322c:	4137d7bb          	sraw	a5,a5,s3
    80003230:	42078263          	beqz	a5,80003654 <syscall+0x478>
      if(num == 1)      printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0);   //fork  
    80003234:	4785                	li	a5,1
    80003236:	0cf98263          	beq	s3,a5,800032fa <syscall+0x11e>
  unsigned int tmp = p->trapframe->a0;
    8000323a:	000a069b          	sext.w	a3,s4
      else if(num == 2) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // exit
    8000323e:	4789                	li	a5,2
    80003240:	0cf98d63          	beq	s3,a5,8000331a <syscall+0x13e>
      else if(num == 3) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // wait
    80003244:	478d                	li	a5,3
    80003246:	0ef98a63          	beq	s3,a5,8000333a <syscall+0x15e>
      else if(num == 4) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // pipe
    8000324a:	4791                	li	a5,4
    8000324c:	10f98763          	beq	s3,a5,8000335a <syscall+0x17e>
      else if(num == 5) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp,  p->trapframe->a1,  p->trapframe->a2, p->trapframe->a0);  // read
    80003250:	4795                	li	a5,5
    80003252:	12f98463          	beq	s3,a5,8000337a <syscall+0x19e>
      else if(num == 6) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // kill
    80003256:	4799                	li	a5,6
    80003258:	14f98463          	beq	s3,a5,800033a0 <syscall+0x1c4>
      else if(num == 7) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp,  p->trapframe->a1, p->trapframe->a0);   // exec
    8000325c:	479d                	li	a5,7
    8000325e:	16f98163          	beq	s3,a5,800033c0 <syscall+0x1e4>
      else if(num == 8) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp,  p->trapframe->a1, p->trapframe->a0);  // fstat
    80003262:	47a1                	li	a5,8
    80003264:	16f98f63          	beq	s3,a5,800033e2 <syscall+0x206>
      else if(num == 9) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // chdir
    80003268:	47a5                	li	a5,9
    8000326a:	18f98d63          	beq	s3,a5,80003404 <syscall+0x228>
      else if(num == 10) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // dup
    8000326e:	47a9                	li	a5,10
    80003270:	1af98a63          	beq	s3,a5,80003424 <syscall+0x248>
      else if(num == 11) printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0);  // getpid
    80003274:	47ad                	li	a5,11
    80003276:	1cf98763          	beq	s3,a5,80003444 <syscall+0x268>
      else if(num == 12) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // sbrk
    8000327a:	47b1                	li	a5,12
    8000327c:	1ef98463          	beq	s3,a5,80003464 <syscall+0x288>
      else if(num == 13) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // sleep
    80003280:	47b5                	li	a5,13
    80003282:	20f98163          	beq	s3,a5,80003484 <syscall+0x2a8>
      else if(num == 14) printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0); // uptime
    80003286:	47b9                	li	a5,14
    80003288:	20f98e63          	beq	s3,a5,800034a4 <syscall+0x2c8>
      else if(num == 15) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a0); // open
    8000328c:	47bd                	li	a5,15
    8000328e:	22f98b63          	beq	s3,a5,800034c4 <syscall+0x2e8>
      else if(num == 16) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a3, p->trapframe->a0); // write
    80003292:	47c1                	li	a5,16
    80003294:	24f98963          	beq	s3,a5,800034e6 <syscall+0x30a>
      else if(num == 17) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a3, p->trapframe->a0); // mknod
    80003298:	47c5                	li	a5,17
    8000329a:	26f98963          	beq	s3,a5,8000350c <syscall+0x330>
      else if(num == 18) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // unlink
    8000329e:	47c9                	li	a5,18
    800032a0:	28f98963          	beq	s3,a5,80003532 <syscall+0x356>
      else if(num == 19) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a0); // link
    800032a4:	47cd                	li	a5,19
    800032a6:	2af98663          	beq	s3,a5,80003552 <syscall+0x376>
      else if(num == 20) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // mkdir
    800032aa:	47d1                	li	a5,20
    800032ac:	2cf98463          	beq	s3,a5,80003574 <syscall+0x398>
      else if(num == 21) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // close
    800032b0:	47d5                	li	a5,21
    800032b2:	2ef98163          	beq	s3,a5,80003594 <syscall+0x3b8>
      else if(num == 22) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], (unsigned)tmp, p->trapframe->a0); // trace
    800032b6:	47d9                	li	a5,22
    800032b8:	2ef98e63          	beq	s3,a5,800035b4 <syscall+0x3d8>
      else if(num == 23) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a0); // sigalarm
    800032bc:	47dd                	li	a5,23
    800032be:	30f98b63          	beq	s3,a5,800035d4 <syscall+0x3f8>
      else if(num == 24) printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0); // sigreturn
    800032c2:	47e1                	li	a5,24
    800032c4:	32f98963          	beq	s3,a5,800035f6 <syscall+0x41a>
      else if(num == 25) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // settickets
    800032c8:	47e5                	li	a5,25
    800032ca:	34f98663          	beq	s3,a5,80003616 <syscall+0x43a>
      else if(num == 26) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a1, p->trapframe->a2, p->trapframe->a0); // waitx
    800032ce:	47e9                	li	a5,26
    800032d0:	38f99263          	bne	s3,a5,80003654 <syscall+0x478>
    800032d4:	6cb8                	ld	a4,88(s1)
    800032d6:	07073803          	ld	a6,112(a4)
    800032da:	635c                	ld	a5,128(a4)
    800032dc:	7f38                	ld	a4,120(a4)
    800032de:	00007617          	auipc	a2,0x7
    800032e2:	85263603          	ld	a2,-1966(a2) # 80009b30 <syscall_names+0xd0>
    800032e6:	588c                	lw	a1,48(s1)
    800032e8:	00006517          	auipc	a0,0x6
    800032ec:	18850513          	addi	a0,a0,392 # 80009470 <states.1801+0x188>
    800032f0:	ffffd097          	auipc	ra,0xffffd
    800032f4:	29e080e7          	jalr	670(ra) # 8000058e <printf>
    800032f8:	aeb1                	j	80003654 <syscall+0x478>
      if(num == 1)      printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0);   //fork  
    800032fa:	6cbc                	ld	a5,88(s1)
    800032fc:	7bb4                	ld	a3,112(a5)
    800032fe:	00006617          	auipc	a2,0x6
    80003302:	76a63603          	ld	a2,1898(a2) # 80009a68 <syscall_names+0x8>
    80003306:	588c                	lw	a1,48(s1)
    80003308:	00006517          	auipc	a0,0x6
    8000330c:	13050513          	addi	a0,a0,304 # 80009438 <states.1801+0x150>
    80003310:	ffffd097          	auipc	ra,0xffffd
    80003314:	27e080e7          	jalr	638(ra) # 8000058e <printf>
    80003318:	ae35                	j	80003654 <syscall+0x478>
      else if(num == 2) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // exit
    8000331a:	6cbc                	ld	a5,88(s1)
    8000331c:	7bb8                	ld	a4,112(a5)
    8000331e:	00006617          	auipc	a2,0x6
    80003322:	75263603          	ld	a2,1874(a2) # 80009a70 <syscall_names+0x10>
    80003326:	588c                	lw	a1,48(s1)
    80003328:	00006517          	auipc	a0,0x6
    8000332c:	12850513          	addi	a0,a0,296 # 80009450 <states.1801+0x168>
    80003330:	ffffd097          	auipc	ra,0xffffd
    80003334:	25e080e7          	jalr	606(ra) # 8000058e <printf>
    80003338:	ae31                	j	80003654 <syscall+0x478>
      else if(num == 3) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // wait
    8000333a:	6cbc                	ld	a5,88(s1)
    8000333c:	7bb8                	ld	a4,112(a5)
    8000333e:	00006617          	auipc	a2,0x6
    80003342:	73a63603          	ld	a2,1850(a2) # 80009a78 <syscall_names+0x18>
    80003346:	588c                	lw	a1,48(s1)
    80003348:	00006517          	auipc	a0,0x6
    8000334c:	10850513          	addi	a0,a0,264 # 80009450 <states.1801+0x168>
    80003350:	ffffd097          	auipc	ra,0xffffd
    80003354:	23e080e7          	jalr	574(ra) # 8000058e <printf>
    80003358:	acf5                	j	80003654 <syscall+0x478>
      else if(num == 4) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // pipe
    8000335a:	6cbc                	ld	a5,88(s1)
    8000335c:	7bb8                	ld	a4,112(a5)
    8000335e:	00006617          	auipc	a2,0x6
    80003362:	72263603          	ld	a2,1826(a2) # 80009a80 <syscall_names+0x20>
    80003366:	588c                	lw	a1,48(s1)
    80003368:	00006517          	auipc	a0,0x6
    8000336c:	0e850513          	addi	a0,a0,232 # 80009450 <states.1801+0x168>
    80003370:	ffffd097          	auipc	ra,0xffffd
    80003374:	21e080e7          	jalr	542(ra) # 8000058e <printf>
    80003378:	acf1                	j	80003654 <syscall+0x478>
      else if(num == 5) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp,  p->trapframe->a1,  p->trapframe->a2, p->trapframe->a0);  // read
    8000337a:	6cb8                	ld	a4,88(s1)
    8000337c:	07073803          	ld	a6,112(a4)
    80003380:	635c                	ld	a5,128(a4)
    80003382:	7f38                	ld	a4,120(a4)
    80003384:	00006617          	auipc	a2,0x6
    80003388:	70463603          	ld	a2,1796(a2) # 80009a88 <syscall_names+0x28>
    8000338c:	588c                	lw	a1,48(s1)
    8000338e:	00006517          	auipc	a0,0x6
    80003392:	0e250513          	addi	a0,a0,226 # 80009470 <states.1801+0x188>
    80003396:	ffffd097          	auipc	ra,0xffffd
    8000339a:	1f8080e7          	jalr	504(ra) # 8000058e <printf>
    8000339e:	ac5d                	j	80003654 <syscall+0x478>
      else if(num == 6) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // kill
    800033a0:	6cbc                	ld	a5,88(s1)
    800033a2:	7bb8                	ld	a4,112(a5)
    800033a4:	00006617          	auipc	a2,0x6
    800033a8:	6ec63603          	ld	a2,1772(a2) # 80009a90 <syscall_names+0x30>
    800033ac:	588c                	lw	a1,48(s1)
    800033ae:	00006517          	auipc	a0,0x6
    800033b2:	0a250513          	addi	a0,a0,162 # 80009450 <states.1801+0x168>
    800033b6:	ffffd097          	auipc	ra,0xffffd
    800033ba:	1d8080e7          	jalr	472(ra) # 8000058e <printf>
    800033be:	ac59                	j	80003654 <syscall+0x478>
      else if(num == 7) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp,  p->trapframe->a1, p->trapframe->a0);   // exec
    800033c0:	6cb8                	ld	a4,88(s1)
    800033c2:	7b3c                	ld	a5,112(a4)
    800033c4:	7f38                	ld	a4,120(a4)
    800033c6:	00006617          	auipc	a2,0x6
    800033ca:	6d263603          	ld	a2,1746(a2) # 80009a98 <syscall_names+0x38>
    800033ce:	588c                	lw	a1,48(s1)
    800033d0:	00006517          	auipc	a0,0x6
    800033d4:	0c850513          	addi	a0,a0,200 # 80009498 <states.1801+0x1b0>
    800033d8:	ffffd097          	auipc	ra,0xffffd
    800033dc:	1b6080e7          	jalr	438(ra) # 8000058e <printf>
    800033e0:	ac95                	j	80003654 <syscall+0x478>
      else if(num == 8) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp,  p->trapframe->a1, p->trapframe->a0);  // fstat
    800033e2:	6cb8                	ld	a4,88(s1)
    800033e4:	7b3c                	ld	a5,112(a4)
    800033e6:	7f38                	ld	a4,120(a4)
    800033e8:	00006617          	auipc	a2,0x6
    800033ec:	6b863603          	ld	a2,1720(a2) # 80009aa0 <syscall_names+0x40>
    800033f0:	588c                	lw	a1,48(s1)
    800033f2:	00006517          	auipc	a0,0x6
    800033f6:	0a650513          	addi	a0,a0,166 # 80009498 <states.1801+0x1b0>
    800033fa:	ffffd097          	auipc	ra,0xffffd
    800033fe:	194080e7          	jalr	404(ra) # 8000058e <printf>
    80003402:	ac89                	j	80003654 <syscall+0x478>
      else if(num == 9) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // chdir
    80003404:	6cbc                	ld	a5,88(s1)
    80003406:	7bb8                	ld	a4,112(a5)
    80003408:	00006617          	auipc	a2,0x6
    8000340c:	6a063603          	ld	a2,1696(a2) # 80009aa8 <syscall_names+0x48>
    80003410:	588c                	lw	a1,48(s1)
    80003412:	00006517          	auipc	a0,0x6
    80003416:	03e50513          	addi	a0,a0,62 # 80009450 <states.1801+0x168>
    8000341a:	ffffd097          	auipc	ra,0xffffd
    8000341e:	174080e7          	jalr	372(ra) # 8000058e <printf>
    80003422:	ac0d                	j	80003654 <syscall+0x478>
      else if(num == 10) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // dup
    80003424:	6cbc                	ld	a5,88(s1)
    80003426:	7bb8                	ld	a4,112(a5)
    80003428:	00006617          	auipc	a2,0x6
    8000342c:	68863603          	ld	a2,1672(a2) # 80009ab0 <syscall_names+0x50>
    80003430:	588c                	lw	a1,48(s1)
    80003432:	00006517          	auipc	a0,0x6
    80003436:	01e50513          	addi	a0,a0,30 # 80009450 <states.1801+0x168>
    8000343a:	ffffd097          	auipc	ra,0xffffd
    8000343e:	154080e7          	jalr	340(ra) # 8000058e <printf>
    80003442:	ac09                	j	80003654 <syscall+0x478>
      else if(num == 11) printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0);  // getpid
    80003444:	6cbc                	ld	a5,88(s1)
    80003446:	7bb4                	ld	a3,112(a5)
    80003448:	00006617          	auipc	a2,0x6
    8000344c:	67063603          	ld	a2,1648(a2) # 80009ab8 <syscall_names+0x58>
    80003450:	588c                	lw	a1,48(s1)
    80003452:	00006517          	auipc	a0,0x6
    80003456:	fe650513          	addi	a0,a0,-26 # 80009438 <states.1801+0x150>
    8000345a:	ffffd097          	auipc	ra,0xffffd
    8000345e:	134080e7          	jalr	308(ra) # 8000058e <printf>
    80003462:	aacd                	j	80003654 <syscall+0x478>
      else if(num == 12) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // sbrk
    80003464:	6cbc                	ld	a5,88(s1)
    80003466:	7bb8                	ld	a4,112(a5)
    80003468:	00006617          	auipc	a2,0x6
    8000346c:	65863603          	ld	a2,1624(a2) # 80009ac0 <syscall_names+0x60>
    80003470:	588c                	lw	a1,48(s1)
    80003472:	00006517          	auipc	a0,0x6
    80003476:	fde50513          	addi	a0,a0,-34 # 80009450 <states.1801+0x168>
    8000347a:	ffffd097          	auipc	ra,0xffffd
    8000347e:	114080e7          	jalr	276(ra) # 8000058e <printf>
    80003482:	aac9                	j	80003654 <syscall+0x478>
      else if(num == 13) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // sleep
    80003484:	6cbc                	ld	a5,88(s1)
    80003486:	7bb8                	ld	a4,112(a5)
    80003488:	00006617          	auipc	a2,0x6
    8000348c:	64063603          	ld	a2,1600(a2) # 80009ac8 <syscall_names+0x68>
    80003490:	588c                	lw	a1,48(s1)
    80003492:	00006517          	auipc	a0,0x6
    80003496:	fbe50513          	addi	a0,a0,-66 # 80009450 <states.1801+0x168>
    8000349a:	ffffd097          	auipc	ra,0xffffd
    8000349e:	0f4080e7          	jalr	244(ra) # 8000058e <printf>
    800034a2:	aa4d                	j	80003654 <syscall+0x478>
      else if(num == 14) printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0); // uptime
    800034a4:	6cbc                	ld	a5,88(s1)
    800034a6:	7bb4                	ld	a3,112(a5)
    800034a8:	00006617          	auipc	a2,0x6
    800034ac:	62863603          	ld	a2,1576(a2) # 80009ad0 <syscall_names+0x70>
    800034b0:	588c                	lw	a1,48(s1)
    800034b2:	00006517          	auipc	a0,0x6
    800034b6:	f8650513          	addi	a0,a0,-122 # 80009438 <states.1801+0x150>
    800034ba:	ffffd097          	auipc	ra,0xffffd
    800034be:	0d4080e7          	jalr	212(ra) # 8000058e <printf>
    800034c2:	aa49                	j	80003654 <syscall+0x478>
      else if(num == 15) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a0); // open
    800034c4:	6cb8                	ld	a4,88(s1)
    800034c6:	7b3c                	ld	a5,112(a4)
    800034c8:	6358                	ld	a4,128(a4)
    800034ca:	00006617          	auipc	a2,0x6
    800034ce:	60e63603          	ld	a2,1550(a2) # 80009ad8 <syscall_names+0x78>
    800034d2:	588c                	lw	a1,48(s1)
    800034d4:	00006517          	auipc	a0,0x6
    800034d8:	fc450513          	addi	a0,a0,-60 # 80009498 <states.1801+0x1b0>
    800034dc:	ffffd097          	auipc	ra,0xffffd
    800034e0:	0b2080e7          	jalr	178(ra) # 8000058e <printf>
    800034e4:	aa85                	j	80003654 <syscall+0x478>
      else if(num == 16) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a3, p->trapframe->a0); // write
    800034e6:	6cb8                	ld	a4,88(s1)
    800034e8:	07073803          	ld	a6,112(a4)
    800034ec:	675c                	ld	a5,136(a4)
    800034ee:	6358                	ld	a4,128(a4)
    800034f0:	00006617          	auipc	a2,0x6
    800034f4:	5f063603          	ld	a2,1520(a2) # 80009ae0 <syscall_names+0x80>
    800034f8:	588c                	lw	a1,48(s1)
    800034fa:	00006517          	auipc	a0,0x6
    800034fe:	f7650513          	addi	a0,a0,-138 # 80009470 <states.1801+0x188>
    80003502:	ffffd097          	auipc	ra,0xffffd
    80003506:	08c080e7          	jalr	140(ra) # 8000058e <printf>
    8000350a:	a2a9                	j	80003654 <syscall+0x478>
      else if(num == 17) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a3, p->trapframe->a0); // mknod
    8000350c:	6cb8                	ld	a4,88(s1)
    8000350e:	07073803          	ld	a6,112(a4)
    80003512:	675c                	ld	a5,136(a4)
    80003514:	6358                	ld	a4,128(a4)
    80003516:	00006617          	auipc	a2,0x6
    8000351a:	5d263603          	ld	a2,1490(a2) # 80009ae8 <syscall_names+0x88>
    8000351e:	588c                	lw	a1,48(s1)
    80003520:	00006517          	auipc	a0,0x6
    80003524:	f5050513          	addi	a0,a0,-176 # 80009470 <states.1801+0x188>
    80003528:	ffffd097          	auipc	ra,0xffffd
    8000352c:	066080e7          	jalr	102(ra) # 8000058e <printf>
    80003530:	a215                	j	80003654 <syscall+0x478>
      else if(num == 18) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // unlink
    80003532:	6cbc                	ld	a5,88(s1)
    80003534:	7bb8                	ld	a4,112(a5)
    80003536:	00006617          	auipc	a2,0x6
    8000353a:	5ba63603          	ld	a2,1466(a2) # 80009af0 <syscall_names+0x90>
    8000353e:	588c                	lw	a1,48(s1)
    80003540:	00006517          	auipc	a0,0x6
    80003544:	f1050513          	addi	a0,a0,-240 # 80009450 <states.1801+0x168>
    80003548:	ffffd097          	auipc	ra,0xffffd
    8000354c:	046080e7          	jalr	70(ra) # 8000058e <printf>
    80003550:	a211                	j	80003654 <syscall+0x478>
      else if(num == 19) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a0); // link
    80003552:	6cb8                	ld	a4,88(s1)
    80003554:	7b3c                	ld	a5,112(a4)
    80003556:	6358                	ld	a4,128(a4)
    80003558:	00006617          	auipc	a2,0x6
    8000355c:	5a063603          	ld	a2,1440(a2) # 80009af8 <syscall_names+0x98>
    80003560:	588c                	lw	a1,48(s1)
    80003562:	00006517          	auipc	a0,0x6
    80003566:	f3650513          	addi	a0,a0,-202 # 80009498 <states.1801+0x1b0>
    8000356a:	ffffd097          	auipc	ra,0xffffd
    8000356e:	024080e7          	jalr	36(ra) # 8000058e <printf>
    80003572:	a0cd                	j	80003654 <syscall+0x478>
      else if(num == 20) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // mkdir
    80003574:	6cbc                	ld	a5,88(s1)
    80003576:	7bb8                	ld	a4,112(a5)
    80003578:	00006617          	auipc	a2,0x6
    8000357c:	58863603          	ld	a2,1416(a2) # 80009b00 <syscall_names+0xa0>
    80003580:	588c                	lw	a1,48(s1)
    80003582:	00006517          	auipc	a0,0x6
    80003586:	ece50513          	addi	a0,a0,-306 # 80009450 <states.1801+0x168>
    8000358a:	ffffd097          	auipc	ra,0xffffd
    8000358e:	004080e7          	jalr	4(ra) # 8000058e <printf>
    80003592:	a0c9                	j	80003654 <syscall+0x478>
      else if(num == 21) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // close
    80003594:	6cbc                	ld	a5,88(s1)
    80003596:	7bb8                	ld	a4,112(a5)
    80003598:	00006617          	auipc	a2,0x6
    8000359c:	57063603          	ld	a2,1392(a2) # 80009b08 <syscall_names+0xa8>
    800035a0:	588c                	lw	a1,48(s1)
    800035a2:	00006517          	auipc	a0,0x6
    800035a6:	eae50513          	addi	a0,a0,-338 # 80009450 <states.1801+0x168>
    800035aa:	ffffd097          	auipc	ra,0xffffd
    800035ae:	fe4080e7          	jalr	-28(ra) # 8000058e <printf>
    800035b2:	a04d                	j	80003654 <syscall+0x478>
      else if(num == 22) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], (unsigned)tmp, p->trapframe->a0); // trace
    800035b4:	6cbc                	ld	a5,88(s1)
    800035b6:	7bb8                	ld	a4,112(a5)
    800035b8:	00006617          	auipc	a2,0x6
    800035bc:	55863603          	ld	a2,1368(a2) # 80009b10 <syscall_names+0xb0>
    800035c0:	588c                	lw	a1,48(s1)
    800035c2:	00006517          	auipc	a0,0x6
    800035c6:	e8e50513          	addi	a0,a0,-370 # 80009450 <states.1801+0x168>
    800035ca:	ffffd097          	auipc	ra,0xffffd
    800035ce:	fc4080e7          	jalr	-60(ra) # 8000058e <printf>
    800035d2:	a049                	j	80003654 <syscall+0x478>
      else if(num == 23) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a0); // sigalarm
    800035d4:	6cb8                	ld	a4,88(s1)
    800035d6:	7b3c                	ld	a5,112(a4)
    800035d8:	6358                	ld	a4,128(a4)
    800035da:	00006617          	auipc	a2,0x6
    800035de:	53e63603          	ld	a2,1342(a2) # 80009b18 <syscall_names+0xb8>
    800035e2:	588c                	lw	a1,48(s1)
    800035e4:	00006517          	auipc	a0,0x6
    800035e8:	eb450513          	addi	a0,a0,-332 # 80009498 <states.1801+0x1b0>
    800035ec:	ffffd097          	auipc	ra,0xffffd
    800035f0:	fa2080e7          	jalr	-94(ra) # 8000058e <printf>
    800035f4:	a085                	j	80003654 <syscall+0x478>
      else if(num == 24) printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0); // sigreturn
    800035f6:	6cbc                	ld	a5,88(s1)
    800035f8:	7bb4                	ld	a3,112(a5)
    800035fa:	00006617          	auipc	a2,0x6
    800035fe:	52663603          	ld	a2,1318(a2) # 80009b20 <syscall_names+0xc0>
    80003602:	588c                	lw	a1,48(s1)
    80003604:	00006517          	auipc	a0,0x6
    80003608:	e3450513          	addi	a0,a0,-460 # 80009438 <states.1801+0x150>
    8000360c:	ffffd097          	auipc	ra,0xffffd
    80003610:	f82080e7          	jalr	-126(ra) # 8000058e <printf>
    80003614:	a081                	j	80003654 <syscall+0x478>
      else if(num == 25) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // settickets
    80003616:	6cbc                	ld	a5,88(s1)
    80003618:	7bb8                	ld	a4,112(a5)
    8000361a:	00006617          	auipc	a2,0x6
    8000361e:	50e63603          	ld	a2,1294(a2) # 80009b28 <syscall_names+0xc8>
    80003622:	588c                	lw	a1,48(s1)
    80003624:	00006517          	auipc	a0,0x6
    80003628:	e2c50513          	addi	a0,a0,-468 # 80009450 <states.1801+0x168>
    8000362c:	ffffd097          	auipc	ra,0xffffd
    80003630:	f62080e7          	jalr	-158(ra) # 8000058e <printf>
    80003634:	a005                	j	80003654 <syscall+0x478>
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    80003636:	86ce                	mv	a3,s3
    80003638:	15848613          	addi	a2,s1,344
    8000363c:	588c                	lw	a1,48(s1)
    8000363e:	00006517          	auipc	a0,0x6
    80003642:	e7a50513          	addi	a0,a0,-390 # 800094b8 <states.1801+0x1d0>
    80003646:	ffffd097          	auipc	ra,0xffffd
    8000364a:	f48080e7          	jalr	-184(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000364e:	6cbc                	ld	a5,88(s1)
    80003650:	577d                	li	a4,-1
    80003652:	fbb8                	sd	a4,112(a5)
  }
}
    80003654:	70a2                	ld	ra,40(sp)
    80003656:	7402                	ld	s0,32(sp)
    80003658:	64e2                	ld	s1,24(sp)
    8000365a:	6942                	ld	s2,16(sp)
    8000365c:	69a2                	ld	s3,8(sp)
    8000365e:	6a02                	ld	s4,0(sp)
    80003660:	6145                	addi	sp,sp,48
    80003662:	8082                	ret

0000000080003664 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003664:	1101                	addi	sp,sp,-32
    80003666:	ec06                	sd	ra,24(sp)
    80003668:	e822                	sd	s0,16(sp)
    8000366a:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    8000366c:	fec40593          	addi	a1,s0,-20
    80003670:	4501                	li	a0,0
    80003672:	00000097          	auipc	ra,0x0
    80003676:	af2080e7          	jalr	-1294(ra) # 80003164 <argint>
  exit(n);
    8000367a:	fec42503          	lw	a0,-20(s0)
    8000367e:	fffff097          	auipc	ra,0xfffff
    80003682:	046080e7          	jalr	70(ra) # 800026c4 <exit>
  return 0;  // not reached
}
    80003686:	4501                	li	a0,0
    80003688:	60e2                	ld	ra,24(sp)
    8000368a:	6442                	ld	s0,16(sp)
    8000368c:	6105                	addi	sp,sp,32
    8000368e:	8082                	ret

0000000080003690 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003690:	1141                	addi	sp,sp,-16
    80003692:	e406                	sd	ra,8(sp)
    80003694:	e022                	sd	s0,0(sp)
    80003696:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003698:	ffffe097          	auipc	ra,0xffffe
    8000369c:	52e080e7          	jalr	1326(ra) # 80001bc6 <myproc>
}
    800036a0:	5908                	lw	a0,48(a0)
    800036a2:	60a2                	ld	ra,8(sp)
    800036a4:	6402                	ld	s0,0(sp)
    800036a6:	0141                	addi	sp,sp,16
    800036a8:	8082                	ret

00000000800036aa <sys_fork>:

uint64
sys_fork(void)
{
    800036aa:	1141                	addi	sp,sp,-16
    800036ac:	e406                	sd	ra,8(sp)
    800036ae:	e022                	sd	s0,0(sp)
    800036b0:	0800                	addi	s0,sp,16
  return fork();
    800036b2:	fffff097          	auipc	ra,0xfffff
    800036b6:	90e080e7          	jalr	-1778(ra) # 80001fc0 <fork>
}
    800036ba:	60a2                	ld	ra,8(sp)
    800036bc:	6402                	ld	s0,0(sp)
    800036be:	0141                	addi	sp,sp,16
    800036c0:	8082                	ret

00000000800036c2 <sys_wait>:

uint64
sys_wait(void)
{
    800036c2:	1101                	addi	sp,sp,-32
    800036c4:	ec06                	sd	ra,24(sp)
    800036c6:	e822                	sd	s0,16(sp)
    800036c8:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    800036ca:	fe840593          	addi	a1,s0,-24
    800036ce:	4501                	li	a0,0
    800036d0:	00000097          	auipc	ra,0x0
    800036d4:	ab4080e7          	jalr	-1356(ra) # 80003184 <argaddr>
  return wait(p);
    800036d8:	fe843503          	ld	a0,-24(s0)
    800036dc:	fffff097          	auipc	ra,0xfffff
    800036e0:	19a080e7          	jalr	410(ra) # 80002876 <wait>
}
    800036e4:	60e2                	ld	ra,24(sp)
    800036e6:	6442                	ld	s0,16(sp)
    800036e8:	6105                	addi	sp,sp,32
    800036ea:	8082                	ret

00000000800036ec <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800036ec:	7179                	addi	sp,sp,-48
    800036ee:	f406                	sd	ra,40(sp)
    800036f0:	f022                	sd	s0,32(sp)
    800036f2:	ec26                	sd	s1,24(sp)
    800036f4:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    800036f6:	fdc40593          	addi	a1,s0,-36
    800036fa:	4501                	li	a0,0
    800036fc:	00000097          	auipc	ra,0x0
    80003700:	a68080e7          	jalr	-1432(ra) # 80003164 <argint>
  addr = myproc()->sz;
    80003704:	ffffe097          	auipc	ra,0xffffe
    80003708:	4c2080e7          	jalr	1218(ra) # 80001bc6 <myproc>
    8000370c:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    8000370e:	fdc42503          	lw	a0,-36(s0)
    80003712:	fffff097          	auipc	ra,0xfffff
    80003716:	852080e7          	jalr	-1966(ra) # 80001f64 <growproc>
    8000371a:	00054863          	bltz	a0,8000372a <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    8000371e:	8526                	mv	a0,s1
    80003720:	70a2                	ld	ra,40(sp)
    80003722:	7402                	ld	s0,32(sp)
    80003724:	64e2                	ld	s1,24(sp)
    80003726:	6145                	addi	sp,sp,48
    80003728:	8082                	ret
    return -1;
    8000372a:	54fd                	li	s1,-1
    8000372c:	bfcd                	j	8000371e <sys_sbrk+0x32>

000000008000372e <sys_sleep>:

uint64
sys_sleep(void)
{
    8000372e:	7139                	addi	sp,sp,-64
    80003730:	fc06                	sd	ra,56(sp)
    80003732:	f822                	sd	s0,48(sp)
    80003734:	f426                	sd	s1,40(sp)
    80003736:	f04a                	sd	s2,32(sp)
    80003738:	ec4e                	sd	s3,24(sp)
    8000373a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    8000373c:	fcc40593          	addi	a1,s0,-52
    80003740:	4501                	li	a0,0
    80003742:	00000097          	auipc	ra,0x0
    80003746:	a22080e7          	jalr	-1502(ra) # 80003164 <argint>
  acquire(&tickslock);
    8000374a:	00016517          	auipc	a0,0x16
    8000374e:	15e50513          	addi	a0,a0,350 # 800198a8 <tickslock>
    80003752:	ffffd097          	auipc	ra,0xffffd
    80003756:	498080e7          	jalr	1176(ra) # 80000bea <acquire>
  ticks0 = ticks;
    8000375a:	00006917          	auipc	s2,0x6
    8000375e:	43692903          	lw	s2,1078(s2) # 80009b90 <ticks>
  while(ticks - ticks0 < n){
    80003762:	fcc42783          	lw	a5,-52(s0)
    80003766:	cf9d                	beqz	a5,800037a4 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003768:	00016997          	auipc	s3,0x16
    8000376c:	14098993          	addi	s3,s3,320 # 800198a8 <tickslock>
    80003770:	00006497          	auipc	s1,0x6
    80003774:	42048493          	addi	s1,s1,1056 # 80009b90 <ticks>
    if(killed(myproc())){
    80003778:	ffffe097          	auipc	ra,0xffffe
    8000377c:	44e080e7          	jalr	1102(ra) # 80001bc6 <myproc>
    80003780:	fffff097          	auipc	ra,0xfffff
    80003784:	0c4080e7          	jalr	196(ra) # 80002844 <killed>
    80003788:	ed15                	bnez	a0,800037c4 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    8000378a:	85ce                	mv	a1,s3
    8000378c:	8526                	mv	a0,s1
    8000378e:	fffff097          	auipc	ra,0xfffff
    80003792:	cb6080e7          	jalr	-842(ra) # 80002444 <sleep>
  while(ticks - ticks0 < n){
    80003796:	409c                	lw	a5,0(s1)
    80003798:	412787bb          	subw	a5,a5,s2
    8000379c:	fcc42703          	lw	a4,-52(s0)
    800037a0:	fce7ece3          	bltu	a5,a4,80003778 <sys_sleep+0x4a>
  }
  release(&tickslock);
    800037a4:	00016517          	auipc	a0,0x16
    800037a8:	10450513          	addi	a0,a0,260 # 800198a8 <tickslock>
    800037ac:	ffffd097          	auipc	ra,0xffffd
    800037b0:	4f2080e7          	jalr	1266(ra) # 80000c9e <release>
  return 0;
    800037b4:	4501                	li	a0,0
}
    800037b6:	70e2                	ld	ra,56(sp)
    800037b8:	7442                	ld	s0,48(sp)
    800037ba:	74a2                	ld	s1,40(sp)
    800037bc:	7902                	ld	s2,32(sp)
    800037be:	69e2                	ld	s3,24(sp)
    800037c0:	6121                	addi	sp,sp,64
    800037c2:	8082                	ret
      release(&tickslock);
    800037c4:	00016517          	auipc	a0,0x16
    800037c8:	0e450513          	addi	a0,a0,228 # 800198a8 <tickslock>
    800037cc:	ffffd097          	auipc	ra,0xffffd
    800037d0:	4d2080e7          	jalr	1234(ra) # 80000c9e <release>
      return -1;
    800037d4:	557d                	li	a0,-1
    800037d6:	b7c5                	j	800037b6 <sys_sleep+0x88>

00000000800037d8 <sys_kill>:

uint64
sys_kill(void)
{
    800037d8:	1101                	addi	sp,sp,-32
    800037da:	ec06                	sd	ra,24(sp)
    800037dc:	e822                	sd	s0,16(sp)
    800037de:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    800037e0:	fec40593          	addi	a1,s0,-20
    800037e4:	4501                	li	a0,0
    800037e6:	00000097          	auipc	ra,0x0
    800037ea:	97e080e7          	jalr	-1666(ra) # 80003164 <argint>
  return kill(pid);
    800037ee:	fec42503          	lw	a0,-20(s0)
    800037f2:	fffff097          	auipc	ra,0xfffff
    800037f6:	fb4080e7          	jalr	-76(ra) # 800027a6 <kill>
}
    800037fa:	60e2                	ld	ra,24(sp)
    800037fc:	6442                	ld	s0,16(sp)
    800037fe:	6105                	addi	sp,sp,32
    80003800:	8082                	ret

0000000080003802 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003802:	1101                	addi	sp,sp,-32
    80003804:	ec06                	sd	ra,24(sp)
    80003806:	e822                	sd	s0,16(sp)
    80003808:	e426                	sd	s1,8(sp)
    8000380a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000380c:	00016517          	auipc	a0,0x16
    80003810:	09c50513          	addi	a0,a0,156 # 800198a8 <tickslock>
    80003814:	ffffd097          	auipc	ra,0xffffd
    80003818:	3d6080e7          	jalr	982(ra) # 80000bea <acquire>
  xticks = ticks;
    8000381c:	00006497          	auipc	s1,0x6
    80003820:	3744a483          	lw	s1,884(s1) # 80009b90 <ticks>
  release(&tickslock);
    80003824:	00016517          	auipc	a0,0x16
    80003828:	08450513          	addi	a0,a0,132 # 800198a8 <tickslock>
    8000382c:	ffffd097          	auipc	ra,0xffffd
    80003830:	472080e7          	jalr	1138(ra) # 80000c9e <release>
  return xticks;
}
    80003834:	02049513          	slli	a0,s1,0x20
    80003838:	9101                	srli	a0,a0,0x20
    8000383a:	60e2                	ld	ra,24(sp)
    8000383c:	6442                	ld	s0,16(sp)
    8000383e:	64a2                	ld	s1,8(sp)
    80003840:	6105                	addi	sp,sp,32
    80003842:	8082                	ret

0000000080003844 <sys_trace>:

// sets the trace_flag to the first argument (a0)
uint64
sys_trace(void)
{
    80003844:	1141                	addi	sp,sp,-16
    80003846:	e406                	sd	ra,8(sp)
    80003848:	e022                	sd	s0,0(sp)
    8000384a:	0800                	addi	s0,sp,16
  argint(0, &myproc()->trace_flag); //arg(a0, trace_flag) // returns void
    8000384c:	ffffe097          	auipc	ra,0xffffe
    80003850:	37a080e7          	jalr	890(ra) # 80001bc6 <myproc>
    80003854:	17450593          	addi	a1,a0,372
    80003858:	4501                	li	a0,0
    8000385a:	00000097          	auipc	ra,0x0
    8000385e:	90a080e7          	jalr	-1782(ra) # 80003164 <argint>
  return 0;
}
    80003862:	4501                	li	a0,0
    80003864:	60a2                	ld	ra,8(sp)
    80003866:	6402                	ld	s0,0(sp)
    80003868:	0141                	addi	sp,sp,16
    8000386a:	8082                	ret

000000008000386c <sys_sigalarm>:

// sets the 
uint64
sys_sigalarm(void)
{
    8000386c:	1101                	addi	sp,sp,-32
    8000386e:	ec06                	sd	ra,24(sp)
    80003870:	e822                	sd	s0,16(sp)
    80003872:	e426                	sd	s1,8(sp)
    80003874:	1000                	addi	s0,sp,32
  // sets the interval and handler after every tick
  argint(0, &myproc()->interval);
    80003876:	ffffe097          	auipc	ra,0xffffe
    8000387a:	350080e7          	jalr	848(ra) # 80001bc6 <myproc>
    8000387e:	17850593          	addi	a1,a0,376
    80003882:	4501                	li	a0,0
    80003884:	00000097          	auipc	ra,0x0
    80003888:	8e0080e7          	jalr	-1824(ra) # 80003164 <argint>
  argaddr(1, &myproc()->sig_handler);
    8000388c:	ffffe097          	auipc	ra,0xffffe
    80003890:	33a080e7          	jalr	826(ra) # 80001bc6 <myproc>
    80003894:	18050593          	addi	a1,a0,384
    80003898:	4505                	li	a0,1
    8000389a:	00000097          	auipc	ra,0x0
    8000389e:	8ea080e7          	jalr	-1814(ra) # 80003184 <argaddr>
  
  // sets ticks_passed as the interval
  myproc()->ticks_left = myproc()->interval;
    800038a2:	ffffe097          	auipc	ra,0xffffe
    800038a6:	324080e7          	jalr	804(ra) # 80001bc6 <myproc>
    800038aa:	84aa                	mv	s1,a0
    800038ac:	ffffe097          	auipc	ra,0xffffe
    800038b0:	31a080e7          	jalr	794(ra) # 80001bc6 <myproc>
    800038b4:	1784a783          	lw	a5,376(s1)
    800038b8:	16f52e23          	sw	a5,380(a0)
  return 0;
}
    800038bc:	4501                	li	a0,0
    800038be:	60e2                	ld	ra,24(sp)
    800038c0:	6442                	ld	s0,16(sp)
    800038c2:	64a2                	ld	s1,8(sp)
    800038c4:	6105                	addi	sp,sp,32
    800038c6:	8082                	ret

00000000800038c8 <sys_sigreturn>:

uint64 
sys_sigreturn(void)
{
    800038c8:	1101                	addi	sp,sp,-32
    800038ca:	ec06                	sd	ra,24(sp)
    800038cc:	e822                	sd	s0,16(sp)
    800038ce:	e426                	sd	s1,8(sp)
    800038d0:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800038d2:	ffffe097          	auipc	ra,0xffffe
    800038d6:	2f4080e7          	jalr	756(ra) # 80001bc6 <myproc>
    800038da:	84aa                	mv	s1,a0
  memmove(p->trapframe, p->sigalarm_tf, PGSIZE);
    800038dc:	6605                	lui	a2,0x1
    800038de:	18853583          	ld	a1,392(a0)
    800038e2:	6d28                	ld	a0,88(a0)
    800038e4:	ffffd097          	auipc	ra,0xffffd
    800038e8:	462080e7          	jalr	1122(ra) # 80000d46 <memmove>
  kfree(p->sigalarm_tf);
    800038ec:	1884b503          	ld	a0,392(s1)
    800038f0:	ffffd097          	auipc	ra,0xffffd
    800038f4:	10e080e7          	jalr	270(ra) # 800009fe <kfree>
  p->ticks_left = p->interval;
    800038f8:	1784a783          	lw	a5,376(s1)
    800038fc:	16f4ae23          	sw	a5,380(s1)
  return p->trapframe->a0;
    80003900:	6cbc                	ld	a5,88(s1)
}
    80003902:	7ba8                	ld	a0,112(a5)
    80003904:	60e2                	ld	ra,24(sp)
    80003906:	6442                	ld	s0,16(sp)
    80003908:	64a2                	ld	s1,8(sp)
    8000390a:	6105                	addi	sp,sp,32
    8000390c:	8082                	ret

000000008000390e <sys_settickets>:

uint64 
sys_settickets(void)
{
    8000390e:	1141                	addi	sp,sp,-16
    80003910:	e406                	sd	ra,8(sp)
    80003912:	e022                	sd	s0,0(sp)
    80003914:	0800                	addi	s0,sp,16
  argint(0, &myproc()->tickets);
    80003916:	ffffe097          	auipc	ra,0xffffe
    8000391a:	2b0080e7          	jalr	688(ra) # 80001bc6 <myproc>
    8000391e:	19450593          	addi	a1,a0,404
    80003922:	4501                	li	a0,0
    80003924:	00000097          	auipc	ra,0x0
    80003928:	840080e7          	jalr	-1984(ra) # 80003164 <argint>
  return myproc()->tickets;
    8000392c:	ffffe097          	auipc	ra,0xffffe
    80003930:	29a080e7          	jalr	666(ra) # 80001bc6 <myproc>
}
    80003934:	19452503          	lw	a0,404(a0)
    80003938:	60a2                	ld	ra,8(sp)
    8000393a:	6402                	ld	s0,0(sp)
    8000393c:	0141                	addi	sp,sp,16
    8000393e:	8082                	ret

0000000080003940 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003940:	7139                	addi	sp,sp,-64
    80003942:	fc06                	sd	ra,56(sp)
    80003944:	f822                	sd	s0,48(sp)
    80003946:	f426                	sd	s1,40(sp)
    80003948:	f04a                	sd	s2,32(sp)
    8000394a:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    8000394c:	fd840593          	addi	a1,s0,-40
    80003950:	4501                	li	a0,0
    80003952:	00000097          	auipc	ra,0x0
    80003956:	832080e7          	jalr	-1998(ra) # 80003184 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    8000395a:	fd040593          	addi	a1,s0,-48
    8000395e:	4505                	li	a0,1
    80003960:	00000097          	auipc	ra,0x0
    80003964:	824080e7          	jalr	-2012(ra) # 80003184 <argaddr>
  argaddr(2, &addr2);
    80003968:	fc840593          	addi	a1,s0,-56
    8000396c:	4509                	li	a0,2
    8000396e:	00000097          	auipc	ra,0x0
    80003972:	816080e7          	jalr	-2026(ra) # 80003184 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003976:	fc040613          	addi	a2,s0,-64
    8000397a:	fc440593          	addi	a1,s0,-60
    8000397e:	fd843503          	ld	a0,-40(s0)
    80003982:	fffff097          	auipc	ra,0xfffff
    80003986:	b26080e7          	jalr	-1242(ra) # 800024a8 <waitx>
    8000398a:	892a                	mv	s2,a0
  struct proc* p = myproc();
    8000398c:	ffffe097          	auipc	ra,0xffffe
    80003990:	23a080e7          	jalr	570(ra) # 80001bc6 <myproc>
    80003994:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80003996:	4691                	li	a3,4
    80003998:	fc440613          	addi	a2,s0,-60
    8000399c:	fd043583          	ld	a1,-48(s0)
    800039a0:	6928                	ld	a0,80(a0)
    800039a2:	ffffe097          	auipc	ra,0xffffe
    800039a6:	ce2080e7          	jalr	-798(ra) # 80001684 <copyout>
    return -1;
    800039aa:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    800039ac:	00054f63          	bltz	a0,800039ca <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    800039b0:	4691                	li	a3,4
    800039b2:	fc040613          	addi	a2,s0,-64
    800039b6:	fc843583          	ld	a1,-56(s0)
    800039ba:	68a8                	ld	a0,80(s1)
    800039bc:	ffffe097          	auipc	ra,0xffffe
    800039c0:	cc8080e7          	jalr	-824(ra) # 80001684 <copyout>
    800039c4:	00054a63          	bltz	a0,800039d8 <sys_waitx+0x98>
    return -1;
  return ret;
    800039c8:	87ca                	mv	a5,s2
}
    800039ca:	853e                	mv	a0,a5
    800039cc:	70e2                	ld	ra,56(sp)
    800039ce:	7442                	ld	s0,48(sp)
    800039d0:	74a2                	ld	s1,40(sp)
    800039d2:	7902                	ld	s2,32(sp)
    800039d4:	6121                	addi	sp,sp,64
    800039d6:	8082                	ret
    return -1;
    800039d8:	57fd                	li	a5,-1
    800039da:	bfc5                	j	800039ca <sys_waitx+0x8a>

00000000800039dc <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800039dc:	7179                	addi	sp,sp,-48
    800039de:	f406                	sd	ra,40(sp)
    800039e0:	f022                	sd	s0,32(sp)
    800039e2:	ec26                	sd	s1,24(sp)
    800039e4:	e84a                	sd	s2,16(sp)
    800039e6:	e44e                	sd	s3,8(sp)
    800039e8:	e052                	sd	s4,0(sp)
    800039ea:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800039ec:	00006597          	auipc	a1,0x6
    800039f0:	cc458593          	addi	a1,a1,-828 # 800096b0 <syscalls+0xd8>
    800039f4:	00016517          	auipc	a0,0x16
    800039f8:	ecc50513          	addi	a0,a0,-308 # 800198c0 <bcache>
    800039fc:	ffffd097          	auipc	ra,0xffffd
    80003a00:	15e080e7          	jalr	350(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003a04:	0001e797          	auipc	a5,0x1e
    80003a08:	ebc78793          	addi	a5,a5,-324 # 800218c0 <bcache+0x8000>
    80003a0c:	0001e717          	auipc	a4,0x1e
    80003a10:	11c70713          	addi	a4,a4,284 # 80021b28 <bcache+0x8268>
    80003a14:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003a18:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003a1c:	00016497          	auipc	s1,0x16
    80003a20:	ebc48493          	addi	s1,s1,-324 # 800198d8 <bcache+0x18>
    b->next = bcache.head.next;
    80003a24:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003a26:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003a28:	00006a17          	auipc	s4,0x6
    80003a2c:	c90a0a13          	addi	s4,s4,-880 # 800096b8 <syscalls+0xe0>
    b->next = bcache.head.next;
    80003a30:	2b893783          	ld	a5,696(s2)
    80003a34:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003a36:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003a3a:	85d2                	mv	a1,s4
    80003a3c:	01048513          	addi	a0,s1,16
    80003a40:	00001097          	auipc	ra,0x1
    80003a44:	4c4080e7          	jalr	1220(ra) # 80004f04 <initsleeplock>
    bcache.head.next->prev = b;
    80003a48:	2b893783          	ld	a5,696(s2)
    80003a4c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003a4e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003a52:	45848493          	addi	s1,s1,1112
    80003a56:	fd349de3          	bne	s1,s3,80003a30 <binit+0x54>
  }
}
    80003a5a:	70a2                	ld	ra,40(sp)
    80003a5c:	7402                	ld	s0,32(sp)
    80003a5e:	64e2                	ld	s1,24(sp)
    80003a60:	6942                	ld	s2,16(sp)
    80003a62:	69a2                	ld	s3,8(sp)
    80003a64:	6a02                	ld	s4,0(sp)
    80003a66:	6145                	addi	sp,sp,48
    80003a68:	8082                	ret

0000000080003a6a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003a6a:	7179                	addi	sp,sp,-48
    80003a6c:	f406                	sd	ra,40(sp)
    80003a6e:	f022                	sd	s0,32(sp)
    80003a70:	ec26                	sd	s1,24(sp)
    80003a72:	e84a                	sd	s2,16(sp)
    80003a74:	e44e                	sd	s3,8(sp)
    80003a76:	1800                	addi	s0,sp,48
    80003a78:	89aa                	mv	s3,a0
    80003a7a:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003a7c:	00016517          	auipc	a0,0x16
    80003a80:	e4450513          	addi	a0,a0,-444 # 800198c0 <bcache>
    80003a84:	ffffd097          	auipc	ra,0xffffd
    80003a88:	166080e7          	jalr	358(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003a8c:	0001e497          	auipc	s1,0x1e
    80003a90:	0ec4b483          	ld	s1,236(s1) # 80021b78 <bcache+0x82b8>
    80003a94:	0001e797          	auipc	a5,0x1e
    80003a98:	09478793          	addi	a5,a5,148 # 80021b28 <bcache+0x8268>
    80003a9c:	02f48f63          	beq	s1,a5,80003ada <bread+0x70>
    80003aa0:	873e                	mv	a4,a5
    80003aa2:	a021                	j	80003aaa <bread+0x40>
    80003aa4:	68a4                	ld	s1,80(s1)
    80003aa6:	02e48a63          	beq	s1,a4,80003ada <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003aaa:	449c                	lw	a5,8(s1)
    80003aac:	ff379ce3          	bne	a5,s3,80003aa4 <bread+0x3a>
    80003ab0:	44dc                	lw	a5,12(s1)
    80003ab2:	ff2799e3          	bne	a5,s2,80003aa4 <bread+0x3a>
      b->refcnt++;
    80003ab6:	40bc                	lw	a5,64(s1)
    80003ab8:	2785                	addiw	a5,a5,1
    80003aba:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003abc:	00016517          	auipc	a0,0x16
    80003ac0:	e0450513          	addi	a0,a0,-508 # 800198c0 <bcache>
    80003ac4:	ffffd097          	auipc	ra,0xffffd
    80003ac8:	1da080e7          	jalr	474(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80003acc:	01048513          	addi	a0,s1,16
    80003ad0:	00001097          	auipc	ra,0x1
    80003ad4:	46e080e7          	jalr	1134(ra) # 80004f3e <acquiresleep>
      return b;
    80003ad8:	a8b9                	j	80003b36 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003ada:	0001e497          	auipc	s1,0x1e
    80003ade:	0964b483          	ld	s1,150(s1) # 80021b70 <bcache+0x82b0>
    80003ae2:	0001e797          	auipc	a5,0x1e
    80003ae6:	04678793          	addi	a5,a5,70 # 80021b28 <bcache+0x8268>
    80003aea:	00f48863          	beq	s1,a5,80003afa <bread+0x90>
    80003aee:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003af0:	40bc                	lw	a5,64(s1)
    80003af2:	cf81                	beqz	a5,80003b0a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003af4:	64a4                	ld	s1,72(s1)
    80003af6:	fee49de3          	bne	s1,a4,80003af0 <bread+0x86>
  panic("bget: no buffers");
    80003afa:	00006517          	auipc	a0,0x6
    80003afe:	bc650513          	addi	a0,a0,-1082 # 800096c0 <syscalls+0xe8>
    80003b02:	ffffd097          	auipc	ra,0xffffd
    80003b06:	a42080e7          	jalr	-1470(ra) # 80000544 <panic>
      b->dev = dev;
    80003b0a:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003b0e:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003b12:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003b16:	4785                	li	a5,1
    80003b18:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003b1a:	00016517          	auipc	a0,0x16
    80003b1e:	da650513          	addi	a0,a0,-602 # 800198c0 <bcache>
    80003b22:	ffffd097          	auipc	ra,0xffffd
    80003b26:	17c080e7          	jalr	380(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80003b2a:	01048513          	addi	a0,s1,16
    80003b2e:	00001097          	auipc	ra,0x1
    80003b32:	410080e7          	jalr	1040(ra) # 80004f3e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003b36:	409c                	lw	a5,0(s1)
    80003b38:	cb89                	beqz	a5,80003b4a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003b3a:	8526                	mv	a0,s1
    80003b3c:	70a2                	ld	ra,40(sp)
    80003b3e:	7402                	ld	s0,32(sp)
    80003b40:	64e2                	ld	s1,24(sp)
    80003b42:	6942                	ld	s2,16(sp)
    80003b44:	69a2                	ld	s3,8(sp)
    80003b46:	6145                	addi	sp,sp,48
    80003b48:	8082                	ret
    virtio_disk_rw(b, 0);
    80003b4a:	4581                	li	a1,0
    80003b4c:	8526                	mv	a0,s1
    80003b4e:	00003097          	auipc	ra,0x3
    80003b52:	fca080e7          	jalr	-54(ra) # 80006b18 <virtio_disk_rw>
    b->valid = 1;
    80003b56:	4785                	li	a5,1
    80003b58:	c09c                	sw	a5,0(s1)
  return b;
    80003b5a:	b7c5                	j	80003b3a <bread+0xd0>

0000000080003b5c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003b5c:	1101                	addi	sp,sp,-32
    80003b5e:	ec06                	sd	ra,24(sp)
    80003b60:	e822                	sd	s0,16(sp)
    80003b62:	e426                	sd	s1,8(sp)
    80003b64:	1000                	addi	s0,sp,32
    80003b66:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003b68:	0541                	addi	a0,a0,16
    80003b6a:	00001097          	auipc	ra,0x1
    80003b6e:	46e080e7          	jalr	1134(ra) # 80004fd8 <holdingsleep>
    80003b72:	cd01                	beqz	a0,80003b8a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003b74:	4585                	li	a1,1
    80003b76:	8526                	mv	a0,s1
    80003b78:	00003097          	auipc	ra,0x3
    80003b7c:	fa0080e7          	jalr	-96(ra) # 80006b18 <virtio_disk_rw>
}
    80003b80:	60e2                	ld	ra,24(sp)
    80003b82:	6442                	ld	s0,16(sp)
    80003b84:	64a2                	ld	s1,8(sp)
    80003b86:	6105                	addi	sp,sp,32
    80003b88:	8082                	ret
    panic("bwrite");
    80003b8a:	00006517          	auipc	a0,0x6
    80003b8e:	b4e50513          	addi	a0,a0,-1202 # 800096d8 <syscalls+0x100>
    80003b92:	ffffd097          	auipc	ra,0xffffd
    80003b96:	9b2080e7          	jalr	-1614(ra) # 80000544 <panic>

0000000080003b9a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003b9a:	1101                	addi	sp,sp,-32
    80003b9c:	ec06                	sd	ra,24(sp)
    80003b9e:	e822                	sd	s0,16(sp)
    80003ba0:	e426                	sd	s1,8(sp)
    80003ba2:	e04a                	sd	s2,0(sp)
    80003ba4:	1000                	addi	s0,sp,32
    80003ba6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003ba8:	01050913          	addi	s2,a0,16
    80003bac:	854a                	mv	a0,s2
    80003bae:	00001097          	auipc	ra,0x1
    80003bb2:	42a080e7          	jalr	1066(ra) # 80004fd8 <holdingsleep>
    80003bb6:	c92d                	beqz	a0,80003c28 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003bb8:	854a                	mv	a0,s2
    80003bba:	00001097          	auipc	ra,0x1
    80003bbe:	3da080e7          	jalr	986(ra) # 80004f94 <releasesleep>

  acquire(&bcache.lock);
    80003bc2:	00016517          	auipc	a0,0x16
    80003bc6:	cfe50513          	addi	a0,a0,-770 # 800198c0 <bcache>
    80003bca:	ffffd097          	auipc	ra,0xffffd
    80003bce:	020080e7          	jalr	32(ra) # 80000bea <acquire>
  b->refcnt--;
    80003bd2:	40bc                	lw	a5,64(s1)
    80003bd4:	37fd                	addiw	a5,a5,-1
    80003bd6:	0007871b          	sext.w	a4,a5
    80003bda:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003bdc:	eb05                	bnez	a4,80003c0c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003bde:	68bc                	ld	a5,80(s1)
    80003be0:	64b8                	ld	a4,72(s1)
    80003be2:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003be4:	64bc                	ld	a5,72(s1)
    80003be6:	68b8                	ld	a4,80(s1)
    80003be8:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003bea:	0001e797          	auipc	a5,0x1e
    80003bee:	cd678793          	addi	a5,a5,-810 # 800218c0 <bcache+0x8000>
    80003bf2:	2b87b703          	ld	a4,696(a5)
    80003bf6:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003bf8:	0001e717          	auipc	a4,0x1e
    80003bfc:	f3070713          	addi	a4,a4,-208 # 80021b28 <bcache+0x8268>
    80003c00:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003c02:	2b87b703          	ld	a4,696(a5)
    80003c06:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003c08:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003c0c:	00016517          	auipc	a0,0x16
    80003c10:	cb450513          	addi	a0,a0,-844 # 800198c0 <bcache>
    80003c14:	ffffd097          	auipc	ra,0xffffd
    80003c18:	08a080e7          	jalr	138(ra) # 80000c9e <release>
}
    80003c1c:	60e2                	ld	ra,24(sp)
    80003c1e:	6442                	ld	s0,16(sp)
    80003c20:	64a2                	ld	s1,8(sp)
    80003c22:	6902                	ld	s2,0(sp)
    80003c24:	6105                	addi	sp,sp,32
    80003c26:	8082                	ret
    panic("brelse");
    80003c28:	00006517          	auipc	a0,0x6
    80003c2c:	ab850513          	addi	a0,a0,-1352 # 800096e0 <syscalls+0x108>
    80003c30:	ffffd097          	auipc	ra,0xffffd
    80003c34:	914080e7          	jalr	-1772(ra) # 80000544 <panic>

0000000080003c38 <bpin>:

void
bpin(struct buf *b) {
    80003c38:	1101                	addi	sp,sp,-32
    80003c3a:	ec06                	sd	ra,24(sp)
    80003c3c:	e822                	sd	s0,16(sp)
    80003c3e:	e426                	sd	s1,8(sp)
    80003c40:	1000                	addi	s0,sp,32
    80003c42:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003c44:	00016517          	auipc	a0,0x16
    80003c48:	c7c50513          	addi	a0,a0,-900 # 800198c0 <bcache>
    80003c4c:	ffffd097          	auipc	ra,0xffffd
    80003c50:	f9e080e7          	jalr	-98(ra) # 80000bea <acquire>
  b->refcnt++;
    80003c54:	40bc                	lw	a5,64(s1)
    80003c56:	2785                	addiw	a5,a5,1
    80003c58:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003c5a:	00016517          	auipc	a0,0x16
    80003c5e:	c6650513          	addi	a0,a0,-922 # 800198c0 <bcache>
    80003c62:	ffffd097          	auipc	ra,0xffffd
    80003c66:	03c080e7          	jalr	60(ra) # 80000c9e <release>
}
    80003c6a:	60e2                	ld	ra,24(sp)
    80003c6c:	6442                	ld	s0,16(sp)
    80003c6e:	64a2                	ld	s1,8(sp)
    80003c70:	6105                	addi	sp,sp,32
    80003c72:	8082                	ret

0000000080003c74 <bunpin>:

void
bunpin(struct buf *b) {
    80003c74:	1101                	addi	sp,sp,-32
    80003c76:	ec06                	sd	ra,24(sp)
    80003c78:	e822                	sd	s0,16(sp)
    80003c7a:	e426                	sd	s1,8(sp)
    80003c7c:	1000                	addi	s0,sp,32
    80003c7e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003c80:	00016517          	auipc	a0,0x16
    80003c84:	c4050513          	addi	a0,a0,-960 # 800198c0 <bcache>
    80003c88:	ffffd097          	auipc	ra,0xffffd
    80003c8c:	f62080e7          	jalr	-158(ra) # 80000bea <acquire>
  b->refcnt--;
    80003c90:	40bc                	lw	a5,64(s1)
    80003c92:	37fd                	addiw	a5,a5,-1
    80003c94:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003c96:	00016517          	auipc	a0,0x16
    80003c9a:	c2a50513          	addi	a0,a0,-982 # 800198c0 <bcache>
    80003c9e:	ffffd097          	auipc	ra,0xffffd
    80003ca2:	000080e7          	jalr	ra # 80000c9e <release>
}
    80003ca6:	60e2                	ld	ra,24(sp)
    80003ca8:	6442                	ld	s0,16(sp)
    80003caa:	64a2                	ld	s1,8(sp)
    80003cac:	6105                	addi	sp,sp,32
    80003cae:	8082                	ret

0000000080003cb0 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003cb0:	1101                	addi	sp,sp,-32
    80003cb2:	ec06                	sd	ra,24(sp)
    80003cb4:	e822                	sd	s0,16(sp)
    80003cb6:	e426                	sd	s1,8(sp)
    80003cb8:	e04a                	sd	s2,0(sp)
    80003cba:	1000                	addi	s0,sp,32
    80003cbc:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003cbe:	00d5d59b          	srliw	a1,a1,0xd
    80003cc2:	0001e797          	auipc	a5,0x1e
    80003cc6:	2da7a783          	lw	a5,730(a5) # 80021f9c <sb+0x1c>
    80003cca:	9dbd                	addw	a1,a1,a5
    80003ccc:	00000097          	auipc	ra,0x0
    80003cd0:	d9e080e7          	jalr	-610(ra) # 80003a6a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003cd4:	0074f713          	andi	a4,s1,7
    80003cd8:	4785                	li	a5,1
    80003cda:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003cde:	14ce                	slli	s1,s1,0x33
    80003ce0:	90d9                	srli	s1,s1,0x36
    80003ce2:	00950733          	add	a4,a0,s1
    80003ce6:	05874703          	lbu	a4,88(a4)
    80003cea:	00e7f6b3          	and	a3,a5,a4
    80003cee:	c69d                	beqz	a3,80003d1c <bfree+0x6c>
    80003cf0:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003cf2:	94aa                	add	s1,s1,a0
    80003cf4:	fff7c793          	not	a5,a5
    80003cf8:	8ff9                	and	a5,a5,a4
    80003cfa:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003cfe:	00001097          	auipc	ra,0x1
    80003d02:	120080e7          	jalr	288(ra) # 80004e1e <log_write>
  brelse(bp);
    80003d06:	854a                	mv	a0,s2
    80003d08:	00000097          	auipc	ra,0x0
    80003d0c:	e92080e7          	jalr	-366(ra) # 80003b9a <brelse>
}
    80003d10:	60e2                	ld	ra,24(sp)
    80003d12:	6442                	ld	s0,16(sp)
    80003d14:	64a2                	ld	s1,8(sp)
    80003d16:	6902                	ld	s2,0(sp)
    80003d18:	6105                	addi	sp,sp,32
    80003d1a:	8082                	ret
    panic("freeing free block");
    80003d1c:	00006517          	auipc	a0,0x6
    80003d20:	9cc50513          	addi	a0,a0,-1588 # 800096e8 <syscalls+0x110>
    80003d24:	ffffd097          	auipc	ra,0xffffd
    80003d28:	820080e7          	jalr	-2016(ra) # 80000544 <panic>

0000000080003d2c <balloc>:
{
    80003d2c:	711d                	addi	sp,sp,-96
    80003d2e:	ec86                	sd	ra,88(sp)
    80003d30:	e8a2                	sd	s0,80(sp)
    80003d32:	e4a6                	sd	s1,72(sp)
    80003d34:	e0ca                	sd	s2,64(sp)
    80003d36:	fc4e                	sd	s3,56(sp)
    80003d38:	f852                	sd	s4,48(sp)
    80003d3a:	f456                	sd	s5,40(sp)
    80003d3c:	f05a                	sd	s6,32(sp)
    80003d3e:	ec5e                	sd	s7,24(sp)
    80003d40:	e862                	sd	s8,16(sp)
    80003d42:	e466                	sd	s9,8(sp)
    80003d44:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003d46:	0001e797          	auipc	a5,0x1e
    80003d4a:	23e7a783          	lw	a5,574(a5) # 80021f84 <sb+0x4>
    80003d4e:	10078163          	beqz	a5,80003e50 <balloc+0x124>
    80003d52:	8baa                	mv	s7,a0
    80003d54:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003d56:	0001eb17          	auipc	s6,0x1e
    80003d5a:	22ab0b13          	addi	s6,s6,554 # 80021f80 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003d5e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003d60:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003d62:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003d64:	6c89                	lui	s9,0x2
    80003d66:	a061                	j	80003dee <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003d68:	974a                	add	a4,a4,s2
    80003d6a:	8fd5                	or	a5,a5,a3
    80003d6c:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003d70:	854a                	mv	a0,s2
    80003d72:	00001097          	auipc	ra,0x1
    80003d76:	0ac080e7          	jalr	172(ra) # 80004e1e <log_write>
        brelse(bp);
    80003d7a:	854a                	mv	a0,s2
    80003d7c:	00000097          	auipc	ra,0x0
    80003d80:	e1e080e7          	jalr	-482(ra) # 80003b9a <brelse>
  bp = bread(dev, bno);
    80003d84:	85a6                	mv	a1,s1
    80003d86:	855e                	mv	a0,s7
    80003d88:	00000097          	auipc	ra,0x0
    80003d8c:	ce2080e7          	jalr	-798(ra) # 80003a6a <bread>
    80003d90:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003d92:	40000613          	li	a2,1024
    80003d96:	4581                	li	a1,0
    80003d98:	05850513          	addi	a0,a0,88
    80003d9c:	ffffd097          	auipc	ra,0xffffd
    80003da0:	f4a080e7          	jalr	-182(ra) # 80000ce6 <memset>
  log_write(bp);
    80003da4:	854a                	mv	a0,s2
    80003da6:	00001097          	auipc	ra,0x1
    80003daa:	078080e7          	jalr	120(ra) # 80004e1e <log_write>
  brelse(bp);
    80003dae:	854a                	mv	a0,s2
    80003db0:	00000097          	auipc	ra,0x0
    80003db4:	dea080e7          	jalr	-534(ra) # 80003b9a <brelse>
}
    80003db8:	8526                	mv	a0,s1
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
    brelse(bp);
    80003dd4:	854a                	mv	a0,s2
    80003dd6:	00000097          	auipc	ra,0x0
    80003dda:	dc4080e7          	jalr	-572(ra) # 80003b9a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003dde:	015c87bb          	addw	a5,s9,s5
    80003de2:	00078a9b          	sext.w	s5,a5
    80003de6:	004b2703          	lw	a4,4(s6)
    80003dea:	06eaf363          	bgeu	s5,a4,80003e50 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003dee:	41fad79b          	sraiw	a5,s5,0x1f
    80003df2:	0137d79b          	srliw	a5,a5,0x13
    80003df6:	015787bb          	addw	a5,a5,s5
    80003dfa:	40d7d79b          	sraiw	a5,a5,0xd
    80003dfe:	01cb2583          	lw	a1,28(s6)
    80003e02:	9dbd                	addw	a1,a1,a5
    80003e04:	855e                	mv	a0,s7
    80003e06:	00000097          	auipc	ra,0x0
    80003e0a:	c64080e7          	jalr	-924(ra) # 80003a6a <bread>
    80003e0e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e10:	004b2503          	lw	a0,4(s6)
    80003e14:	000a849b          	sext.w	s1,s5
    80003e18:	8662                	mv	a2,s8
    80003e1a:	faa4fde3          	bgeu	s1,a0,80003dd4 <balloc+0xa8>
      m = 1 << (bi % 8);
    80003e1e:	41f6579b          	sraiw	a5,a2,0x1f
    80003e22:	01d7d69b          	srliw	a3,a5,0x1d
    80003e26:	00c6873b          	addw	a4,a3,a2
    80003e2a:	00777793          	andi	a5,a4,7
    80003e2e:	9f95                	subw	a5,a5,a3
    80003e30:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003e34:	4037571b          	sraiw	a4,a4,0x3
    80003e38:	00e906b3          	add	a3,s2,a4
    80003e3c:	0586c683          	lbu	a3,88(a3)
    80003e40:	00d7f5b3          	and	a1,a5,a3
    80003e44:	d195                	beqz	a1,80003d68 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e46:	2605                	addiw	a2,a2,1
    80003e48:	2485                	addiw	s1,s1,1
    80003e4a:	fd4618e3          	bne	a2,s4,80003e1a <balloc+0xee>
    80003e4e:	b759                	j	80003dd4 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003e50:	00006517          	auipc	a0,0x6
    80003e54:	8b050513          	addi	a0,a0,-1872 # 80009700 <syscalls+0x128>
    80003e58:	ffffc097          	auipc	ra,0xffffc
    80003e5c:	736080e7          	jalr	1846(ra) # 8000058e <printf>
  return 0;
    80003e60:	4481                	li	s1,0
    80003e62:	bf99                	j	80003db8 <balloc+0x8c>

0000000080003e64 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003e64:	7179                	addi	sp,sp,-48
    80003e66:	f406                	sd	ra,40(sp)
    80003e68:	f022                	sd	s0,32(sp)
    80003e6a:	ec26                	sd	s1,24(sp)
    80003e6c:	e84a                	sd	s2,16(sp)
    80003e6e:	e44e                	sd	s3,8(sp)
    80003e70:	e052                	sd	s4,0(sp)
    80003e72:	1800                	addi	s0,sp,48
    80003e74:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003e76:	47ad                	li	a5,11
    80003e78:	02b7e763          	bltu	a5,a1,80003ea6 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003e7c:	02059493          	slli	s1,a1,0x20
    80003e80:	9081                	srli	s1,s1,0x20
    80003e82:	048a                	slli	s1,s1,0x2
    80003e84:	94aa                	add	s1,s1,a0
    80003e86:	0504a903          	lw	s2,80(s1)
    80003e8a:	06091e63          	bnez	s2,80003f06 <bmap+0xa2>
      addr = balloc(ip->dev);
    80003e8e:	4108                	lw	a0,0(a0)
    80003e90:	00000097          	auipc	ra,0x0
    80003e94:	e9c080e7          	jalr	-356(ra) # 80003d2c <balloc>
    80003e98:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003e9c:	06090563          	beqz	s2,80003f06 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003ea0:	0524a823          	sw	s2,80(s1)
    80003ea4:	a08d                	j	80003f06 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003ea6:	ff45849b          	addiw	s1,a1,-12
    80003eaa:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003eae:	0ff00793          	li	a5,255
    80003eb2:	08e7e563          	bltu	a5,a4,80003f3c <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003eb6:	08052903          	lw	s2,128(a0)
    80003eba:	00091d63          	bnez	s2,80003ed4 <bmap+0x70>
      addr = balloc(ip->dev);
    80003ebe:	4108                	lw	a0,0(a0)
    80003ec0:	00000097          	auipc	ra,0x0
    80003ec4:	e6c080e7          	jalr	-404(ra) # 80003d2c <balloc>
    80003ec8:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003ecc:	02090d63          	beqz	s2,80003f06 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003ed0:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003ed4:	85ca                	mv	a1,s2
    80003ed6:	0009a503          	lw	a0,0(s3)
    80003eda:	00000097          	auipc	ra,0x0
    80003ede:	b90080e7          	jalr	-1136(ra) # 80003a6a <bread>
    80003ee2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003ee4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003ee8:	02049593          	slli	a1,s1,0x20
    80003eec:	9181                	srli	a1,a1,0x20
    80003eee:	058a                	slli	a1,a1,0x2
    80003ef0:	00b784b3          	add	s1,a5,a1
    80003ef4:	0004a903          	lw	s2,0(s1)
    80003ef8:	02090063          	beqz	s2,80003f18 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003efc:	8552                	mv	a0,s4
    80003efe:	00000097          	auipc	ra,0x0
    80003f02:	c9c080e7          	jalr	-868(ra) # 80003b9a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003f06:	854a                	mv	a0,s2
    80003f08:	70a2                	ld	ra,40(sp)
    80003f0a:	7402                	ld	s0,32(sp)
    80003f0c:	64e2                	ld	s1,24(sp)
    80003f0e:	6942                	ld	s2,16(sp)
    80003f10:	69a2                	ld	s3,8(sp)
    80003f12:	6a02                	ld	s4,0(sp)
    80003f14:	6145                	addi	sp,sp,48
    80003f16:	8082                	ret
      addr = balloc(ip->dev);
    80003f18:	0009a503          	lw	a0,0(s3)
    80003f1c:	00000097          	auipc	ra,0x0
    80003f20:	e10080e7          	jalr	-496(ra) # 80003d2c <balloc>
    80003f24:	0005091b          	sext.w	s2,a0
      if(addr){
    80003f28:	fc090ae3          	beqz	s2,80003efc <bmap+0x98>
        a[bn] = addr;
    80003f2c:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003f30:	8552                	mv	a0,s4
    80003f32:	00001097          	auipc	ra,0x1
    80003f36:	eec080e7          	jalr	-276(ra) # 80004e1e <log_write>
    80003f3a:	b7c9                	j	80003efc <bmap+0x98>
  panic("bmap: out of range");
    80003f3c:	00005517          	auipc	a0,0x5
    80003f40:	7dc50513          	addi	a0,a0,2012 # 80009718 <syscalls+0x140>
    80003f44:	ffffc097          	auipc	ra,0xffffc
    80003f48:	600080e7          	jalr	1536(ra) # 80000544 <panic>

0000000080003f4c <iget>:
{
    80003f4c:	7179                	addi	sp,sp,-48
    80003f4e:	f406                	sd	ra,40(sp)
    80003f50:	f022                	sd	s0,32(sp)
    80003f52:	ec26                	sd	s1,24(sp)
    80003f54:	e84a                	sd	s2,16(sp)
    80003f56:	e44e                	sd	s3,8(sp)
    80003f58:	e052                	sd	s4,0(sp)
    80003f5a:	1800                	addi	s0,sp,48
    80003f5c:	89aa                	mv	s3,a0
    80003f5e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003f60:	0001e517          	auipc	a0,0x1e
    80003f64:	04050513          	addi	a0,a0,64 # 80021fa0 <itable>
    80003f68:	ffffd097          	auipc	ra,0xffffd
    80003f6c:	c82080e7          	jalr	-894(ra) # 80000bea <acquire>
  empty = 0;
    80003f70:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003f72:	0001e497          	auipc	s1,0x1e
    80003f76:	04648493          	addi	s1,s1,70 # 80021fb8 <itable+0x18>
    80003f7a:	00020697          	auipc	a3,0x20
    80003f7e:	ace68693          	addi	a3,a3,-1330 # 80023a48 <log>
    80003f82:	a039                	j	80003f90 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003f84:	02090b63          	beqz	s2,80003fba <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003f88:	08848493          	addi	s1,s1,136
    80003f8c:	02d48a63          	beq	s1,a3,80003fc0 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003f90:	449c                	lw	a5,8(s1)
    80003f92:	fef059e3          	blez	a5,80003f84 <iget+0x38>
    80003f96:	4098                	lw	a4,0(s1)
    80003f98:	ff3716e3          	bne	a4,s3,80003f84 <iget+0x38>
    80003f9c:	40d8                	lw	a4,4(s1)
    80003f9e:	ff4713e3          	bne	a4,s4,80003f84 <iget+0x38>
      ip->ref++;
    80003fa2:	2785                	addiw	a5,a5,1
    80003fa4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003fa6:	0001e517          	auipc	a0,0x1e
    80003faa:	ffa50513          	addi	a0,a0,-6 # 80021fa0 <itable>
    80003fae:	ffffd097          	auipc	ra,0xffffd
    80003fb2:	cf0080e7          	jalr	-784(ra) # 80000c9e <release>
      return ip;
    80003fb6:	8926                	mv	s2,s1
    80003fb8:	a03d                	j	80003fe6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003fba:	f7f9                	bnez	a5,80003f88 <iget+0x3c>
    80003fbc:	8926                	mv	s2,s1
    80003fbe:	b7e9                	j	80003f88 <iget+0x3c>
  if(empty == 0)
    80003fc0:	02090c63          	beqz	s2,80003ff8 <iget+0xac>
  ip->dev = dev;
    80003fc4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003fc8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003fcc:	4785                	li	a5,1
    80003fce:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003fd2:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003fd6:	0001e517          	auipc	a0,0x1e
    80003fda:	fca50513          	addi	a0,a0,-54 # 80021fa0 <itable>
    80003fde:	ffffd097          	auipc	ra,0xffffd
    80003fe2:	cc0080e7          	jalr	-832(ra) # 80000c9e <release>
}
    80003fe6:	854a                	mv	a0,s2
    80003fe8:	70a2                	ld	ra,40(sp)
    80003fea:	7402                	ld	s0,32(sp)
    80003fec:	64e2                	ld	s1,24(sp)
    80003fee:	6942                	ld	s2,16(sp)
    80003ff0:	69a2                	ld	s3,8(sp)
    80003ff2:	6a02                	ld	s4,0(sp)
    80003ff4:	6145                	addi	sp,sp,48
    80003ff6:	8082                	ret
    panic("iget: no inodes");
    80003ff8:	00005517          	auipc	a0,0x5
    80003ffc:	73850513          	addi	a0,a0,1848 # 80009730 <syscalls+0x158>
    80004000:	ffffc097          	auipc	ra,0xffffc
    80004004:	544080e7          	jalr	1348(ra) # 80000544 <panic>

0000000080004008 <fsinit>:
fsinit(int dev) {
    80004008:	7179                	addi	sp,sp,-48
    8000400a:	f406                	sd	ra,40(sp)
    8000400c:	f022                	sd	s0,32(sp)
    8000400e:	ec26                	sd	s1,24(sp)
    80004010:	e84a                	sd	s2,16(sp)
    80004012:	e44e                	sd	s3,8(sp)
    80004014:	1800                	addi	s0,sp,48
    80004016:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80004018:	4585                	li	a1,1
    8000401a:	00000097          	auipc	ra,0x0
    8000401e:	a50080e7          	jalr	-1456(ra) # 80003a6a <bread>
    80004022:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80004024:	0001e997          	auipc	s3,0x1e
    80004028:	f5c98993          	addi	s3,s3,-164 # 80021f80 <sb>
    8000402c:	02000613          	li	a2,32
    80004030:	05850593          	addi	a1,a0,88
    80004034:	854e                	mv	a0,s3
    80004036:	ffffd097          	auipc	ra,0xffffd
    8000403a:	d10080e7          	jalr	-752(ra) # 80000d46 <memmove>
  brelse(bp);
    8000403e:	8526                	mv	a0,s1
    80004040:	00000097          	auipc	ra,0x0
    80004044:	b5a080e7          	jalr	-1190(ra) # 80003b9a <brelse>
  if(sb.magic != FSMAGIC)
    80004048:	0009a703          	lw	a4,0(s3)
    8000404c:	102037b7          	lui	a5,0x10203
    80004050:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80004054:	02f71263          	bne	a4,a5,80004078 <fsinit+0x70>
  initlog(dev, &sb);
    80004058:	0001e597          	auipc	a1,0x1e
    8000405c:	f2858593          	addi	a1,a1,-216 # 80021f80 <sb>
    80004060:	854a                	mv	a0,s2
    80004062:	00001097          	auipc	ra,0x1
    80004066:	b40080e7          	jalr	-1216(ra) # 80004ba2 <initlog>
}
    8000406a:	70a2                	ld	ra,40(sp)
    8000406c:	7402                	ld	s0,32(sp)
    8000406e:	64e2                	ld	s1,24(sp)
    80004070:	6942                	ld	s2,16(sp)
    80004072:	69a2                	ld	s3,8(sp)
    80004074:	6145                	addi	sp,sp,48
    80004076:	8082                	ret
    panic("invalid file system");
    80004078:	00005517          	auipc	a0,0x5
    8000407c:	6c850513          	addi	a0,a0,1736 # 80009740 <syscalls+0x168>
    80004080:	ffffc097          	auipc	ra,0xffffc
    80004084:	4c4080e7          	jalr	1220(ra) # 80000544 <panic>

0000000080004088 <iinit>:
{
    80004088:	7179                	addi	sp,sp,-48
    8000408a:	f406                	sd	ra,40(sp)
    8000408c:	f022                	sd	s0,32(sp)
    8000408e:	ec26                	sd	s1,24(sp)
    80004090:	e84a                	sd	s2,16(sp)
    80004092:	e44e                	sd	s3,8(sp)
    80004094:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80004096:	00005597          	auipc	a1,0x5
    8000409a:	6c258593          	addi	a1,a1,1730 # 80009758 <syscalls+0x180>
    8000409e:	0001e517          	auipc	a0,0x1e
    800040a2:	f0250513          	addi	a0,a0,-254 # 80021fa0 <itable>
    800040a6:	ffffd097          	auipc	ra,0xffffd
    800040aa:	ab4080e7          	jalr	-1356(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    800040ae:	0001e497          	auipc	s1,0x1e
    800040b2:	f1a48493          	addi	s1,s1,-230 # 80021fc8 <itable+0x28>
    800040b6:	00020997          	auipc	s3,0x20
    800040ba:	9a298993          	addi	s3,s3,-1630 # 80023a58 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800040be:	00005917          	auipc	s2,0x5
    800040c2:	6a290913          	addi	s2,s2,1698 # 80009760 <syscalls+0x188>
    800040c6:	85ca                	mv	a1,s2
    800040c8:	8526                	mv	a0,s1
    800040ca:	00001097          	auipc	ra,0x1
    800040ce:	e3a080e7          	jalr	-454(ra) # 80004f04 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800040d2:	08848493          	addi	s1,s1,136
    800040d6:	ff3498e3          	bne	s1,s3,800040c6 <iinit+0x3e>
}
    800040da:	70a2                	ld	ra,40(sp)
    800040dc:	7402                	ld	s0,32(sp)
    800040de:	64e2                	ld	s1,24(sp)
    800040e0:	6942                	ld	s2,16(sp)
    800040e2:	69a2                	ld	s3,8(sp)
    800040e4:	6145                	addi	sp,sp,48
    800040e6:	8082                	ret

00000000800040e8 <ialloc>:
{
    800040e8:	715d                	addi	sp,sp,-80
    800040ea:	e486                	sd	ra,72(sp)
    800040ec:	e0a2                	sd	s0,64(sp)
    800040ee:	fc26                	sd	s1,56(sp)
    800040f0:	f84a                	sd	s2,48(sp)
    800040f2:	f44e                	sd	s3,40(sp)
    800040f4:	f052                	sd	s4,32(sp)
    800040f6:	ec56                	sd	s5,24(sp)
    800040f8:	e85a                	sd	s6,16(sp)
    800040fa:	e45e                	sd	s7,8(sp)
    800040fc:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800040fe:	0001e717          	auipc	a4,0x1e
    80004102:	e8e72703          	lw	a4,-370(a4) # 80021f8c <sb+0xc>
    80004106:	4785                	li	a5,1
    80004108:	04e7fa63          	bgeu	a5,a4,8000415c <ialloc+0x74>
    8000410c:	8aaa                	mv	s5,a0
    8000410e:	8bae                	mv	s7,a1
    80004110:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80004112:	0001ea17          	auipc	s4,0x1e
    80004116:	e6ea0a13          	addi	s4,s4,-402 # 80021f80 <sb>
    8000411a:	00048b1b          	sext.w	s6,s1
    8000411e:	0044d593          	srli	a1,s1,0x4
    80004122:	018a2783          	lw	a5,24(s4)
    80004126:	9dbd                	addw	a1,a1,a5
    80004128:	8556                	mv	a0,s5
    8000412a:	00000097          	auipc	ra,0x0
    8000412e:	940080e7          	jalr	-1728(ra) # 80003a6a <bread>
    80004132:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80004134:	05850993          	addi	s3,a0,88
    80004138:	00f4f793          	andi	a5,s1,15
    8000413c:	079a                	slli	a5,a5,0x6
    8000413e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80004140:	00099783          	lh	a5,0(s3)
    80004144:	c3a1                	beqz	a5,80004184 <ialloc+0x9c>
    brelse(bp);
    80004146:	00000097          	auipc	ra,0x0
    8000414a:	a54080e7          	jalr	-1452(ra) # 80003b9a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000414e:	0485                	addi	s1,s1,1
    80004150:	00ca2703          	lw	a4,12(s4)
    80004154:	0004879b          	sext.w	a5,s1
    80004158:	fce7e1e3          	bltu	a5,a4,8000411a <ialloc+0x32>
  printf("ialloc: no inodes\n");
    8000415c:	00005517          	auipc	a0,0x5
    80004160:	60c50513          	addi	a0,a0,1548 # 80009768 <syscalls+0x190>
    80004164:	ffffc097          	auipc	ra,0xffffc
    80004168:	42a080e7          	jalr	1066(ra) # 8000058e <printf>
  return 0;
    8000416c:	4501                	li	a0,0
}
    8000416e:	60a6                	ld	ra,72(sp)
    80004170:	6406                	ld	s0,64(sp)
    80004172:	74e2                	ld	s1,56(sp)
    80004174:	7942                	ld	s2,48(sp)
    80004176:	79a2                	ld	s3,40(sp)
    80004178:	7a02                	ld	s4,32(sp)
    8000417a:	6ae2                	ld	s5,24(sp)
    8000417c:	6b42                	ld	s6,16(sp)
    8000417e:	6ba2                	ld	s7,8(sp)
    80004180:	6161                	addi	sp,sp,80
    80004182:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80004184:	04000613          	li	a2,64
    80004188:	4581                	li	a1,0
    8000418a:	854e                	mv	a0,s3
    8000418c:	ffffd097          	auipc	ra,0xffffd
    80004190:	b5a080e7          	jalr	-1190(ra) # 80000ce6 <memset>
      dip->type = type;
    80004194:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80004198:	854a                	mv	a0,s2
    8000419a:	00001097          	auipc	ra,0x1
    8000419e:	c84080e7          	jalr	-892(ra) # 80004e1e <log_write>
      brelse(bp);
    800041a2:	854a                	mv	a0,s2
    800041a4:	00000097          	auipc	ra,0x0
    800041a8:	9f6080e7          	jalr	-1546(ra) # 80003b9a <brelse>
      return iget(dev, inum);
    800041ac:	85da                	mv	a1,s6
    800041ae:	8556                	mv	a0,s5
    800041b0:	00000097          	auipc	ra,0x0
    800041b4:	d9c080e7          	jalr	-612(ra) # 80003f4c <iget>
    800041b8:	bf5d                	j	8000416e <ialloc+0x86>

00000000800041ba <iupdate>:
{
    800041ba:	1101                	addi	sp,sp,-32
    800041bc:	ec06                	sd	ra,24(sp)
    800041be:	e822                	sd	s0,16(sp)
    800041c0:	e426                	sd	s1,8(sp)
    800041c2:	e04a                	sd	s2,0(sp)
    800041c4:	1000                	addi	s0,sp,32
    800041c6:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800041c8:	415c                	lw	a5,4(a0)
    800041ca:	0047d79b          	srliw	a5,a5,0x4
    800041ce:	0001e597          	auipc	a1,0x1e
    800041d2:	dca5a583          	lw	a1,-566(a1) # 80021f98 <sb+0x18>
    800041d6:	9dbd                	addw	a1,a1,a5
    800041d8:	4108                	lw	a0,0(a0)
    800041da:	00000097          	auipc	ra,0x0
    800041de:	890080e7          	jalr	-1904(ra) # 80003a6a <bread>
    800041e2:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800041e4:	05850793          	addi	a5,a0,88
    800041e8:	40c8                	lw	a0,4(s1)
    800041ea:	893d                	andi	a0,a0,15
    800041ec:	051a                	slli	a0,a0,0x6
    800041ee:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800041f0:	04449703          	lh	a4,68(s1)
    800041f4:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800041f8:	04649703          	lh	a4,70(s1)
    800041fc:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80004200:	04849703          	lh	a4,72(s1)
    80004204:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80004208:	04a49703          	lh	a4,74(s1)
    8000420c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80004210:	44f8                	lw	a4,76(s1)
    80004212:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80004214:	03400613          	li	a2,52
    80004218:	05048593          	addi	a1,s1,80
    8000421c:	0531                	addi	a0,a0,12
    8000421e:	ffffd097          	auipc	ra,0xffffd
    80004222:	b28080e7          	jalr	-1240(ra) # 80000d46 <memmove>
  log_write(bp);
    80004226:	854a                	mv	a0,s2
    80004228:	00001097          	auipc	ra,0x1
    8000422c:	bf6080e7          	jalr	-1034(ra) # 80004e1e <log_write>
  brelse(bp);
    80004230:	854a                	mv	a0,s2
    80004232:	00000097          	auipc	ra,0x0
    80004236:	968080e7          	jalr	-1688(ra) # 80003b9a <brelse>
}
    8000423a:	60e2                	ld	ra,24(sp)
    8000423c:	6442                	ld	s0,16(sp)
    8000423e:	64a2                	ld	s1,8(sp)
    80004240:	6902                	ld	s2,0(sp)
    80004242:	6105                	addi	sp,sp,32
    80004244:	8082                	ret

0000000080004246 <idup>:
{
    80004246:	1101                	addi	sp,sp,-32
    80004248:	ec06                	sd	ra,24(sp)
    8000424a:	e822                	sd	s0,16(sp)
    8000424c:	e426                	sd	s1,8(sp)
    8000424e:	1000                	addi	s0,sp,32
    80004250:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004252:	0001e517          	auipc	a0,0x1e
    80004256:	d4e50513          	addi	a0,a0,-690 # 80021fa0 <itable>
    8000425a:	ffffd097          	auipc	ra,0xffffd
    8000425e:	990080e7          	jalr	-1648(ra) # 80000bea <acquire>
  ip->ref++;
    80004262:	449c                	lw	a5,8(s1)
    80004264:	2785                	addiw	a5,a5,1
    80004266:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004268:	0001e517          	auipc	a0,0x1e
    8000426c:	d3850513          	addi	a0,a0,-712 # 80021fa0 <itable>
    80004270:	ffffd097          	auipc	ra,0xffffd
    80004274:	a2e080e7          	jalr	-1490(ra) # 80000c9e <release>
}
    80004278:	8526                	mv	a0,s1
    8000427a:	60e2                	ld	ra,24(sp)
    8000427c:	6442                	ld	s0,16(sp)
    8000427e:	64a2                	ld	s1,8(sp)
    80004280:	6105                	addi	sp,sp,32
    80004282:	8082                	ret

0000000080004284 <ilock>:
{
    80004284:	1101                	addi	sp,sp,-32
    80004286:	ec06                	sd	ra,24(sp)
    80004288:	e822                	sd	s0,16(sp)
    8000428a:	e426                	sd	s1,8(sp)
    8000428c:	e04a                	sd	s2,0(sp)
    8000428e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80004290:	c115                	beqz	a0,800042b4 <ilock+0x30>
    80004292:	84aa                	mv	s1,a0
    80004294:	451c                	lw	a5,8(a0)
    80004296:	00f05f63          	blez	a5,800042b4 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000429a:	0541                	addi	a0,a0,16
    8000429c:	00001097          	auipc	ra,0x1
    800042a0:	ca2080e7          	jalr	-862(ra) # 80004f3e <acquiresleep>
  if(ip->valid == 0){
    800042a4:	40bc                	lw	a5,64(s1)
    800042a6:	cf99                	beqz	a5,800042c4 <ilock+0x40>
}
    800042a8:	60e2                	ld	ra,24(sp)
    800042aa:	6442                	ld	s0,16(sp)
    800042ac:	64a2                	ld	s1,8(sp)
    800042ae:	6902                	ld	s2,0(sp)
    800042b0:	6105                	addi	sp,sp,32
    800042b2:	8082                	ret
    panic("ilock");
    800042b4:	00005517          	auipc	a0,0x5
    800042b8:	4cc50513          	addi	a0,a0,1228 # 80009780 <syscalls+0x1a8>
    800042bc:	ffffc097          	auipc	ra,0xffffc
    800042c0:	288080e7          	jalr	648(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800042c4:	40dc                	lw	a5,4(s1)
    800042c6:	0047d79b          	srliw	a5,a5,0x4
    800042ca:	0001e597          	auipc	a1,0x1e
    800042ce:	cce5a583          	lw	a1,-818(a1) # 80021f98 <sb+0x18>
    800042d2:	9dbd                	addw	a1,a1,a5
    800042d4:	4088                	lw	a0,0(s1)
    800042d6:	fffff097          	auipc	ra,0xfffff
    800042da:	794080e7          	jalr	1940(ra) # 80003a6a <bread>
    800042de:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800042e0:	05850593          	addi	a1,a0,88
    800042e4:	40dc                	lw	a5,4(s1)
    800042e6:	8bbd                	andi	a5,a5,15
    800042e8:	079a                	slli	a5,a5,0x6
    800042ea:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800042ec:	00059783          	lh	a5,0(a1)
    800042f0:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800042f4:	00259783          	lh	a5,2(a1)
    800042f8:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800042fc:	00459783          	lh	a5,4(a1)
    80004300:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80004304:	00659783          	lh	a5,6(a1)
    80004308:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000430c:	459c                	lw	a5,8(a1)
    8000430e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80004310:	03400613          	li	a2,52
    80004314:	05b1                	addi	a1,a1,12
    80004316:	05048513          	addi	a0,s1,80
    8000431a:	ffffd097          	auipc	ra,0xffffd
    8000431e:	a2c080e7          	jalr	-1492(ra) # 80000d46 <memmove>
    brelse(bp);
    80004322:	854a                	mv	a0,s2
    80004324:	00000097          	auipc	ra,0x0
    80004328:	876080e7          	jalr	-1930(ra) # 80003b9a <brelse>
    ip->valid = 1;
    8000432c:	4785                	li	a5,1
    8000432e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004330:	04449783          	lh	a5,68(s1)
    80004334:	fbb5                	bnez	a5,800042a8 <ilock+0x24>
      panic("ilock: no type");
    80004336:	00005517          	auipc	a0,0x5
    8000433a:	45250513          	addi	a0,a0,1106 # 80009788 <syscalls+0x1b0>
    8000433e:	ffffc097          	auipc	ra,0xffffc
    80004342:	206080e7          	jalr	518(ra) # 80000544 <panic>

0000000080004346 <iunlock>:
{
    80004346:	1101                	addi	sp,sp,-32
    80004348:	ec06                	sd	ra,24(sp)
    8000434a:	e822                	sd	s0,16(sp)
    8000434c:	e426                	sd	s1,8(sp)
    8000434e:	e04a                	sd	s2,0(sp)
    80004350:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004352:	c905                	beqz	a0,80004382 <iunlock+0x3c>
    80004354:	84aa                	mv	s1,a0
    80004356:	01050913          	addi	s2,a0,16
    8000435a:	854a                	mv	a0,s2
    8000435c:	00001097          	auipc	ra,0x1
    80004360:	c7c080e7          	jalr	-900(ra) # 80004fd8 <holdingsleep>
    80004364:	cd19                	beqz	a0,80004382 <iunlock+0x3c>
    80004366:	449c                	lw	a5,8(s1)
    80004368:	00f05d63          	blez	a5,80004382 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000436c:	854a                	mv	a0,s2
    8000436e:	00001097          	auipc	ra,0x1
    80004372:	c26080e7          	jalr	-986(ra) # 80004f94 <releasesleep>
}
    80004376:	60e2                	ld	ra,24(sp)
    80004378:	6442                	ld	s0,16(sp)
    8000437a:	64a2                	ld	s1,8(sp)
    8000437c:	6902                	ld	s2,0(sp)
    8000437e:	6105                	addi	sp,sp,32
    80004380:	8082                	ret
    panic("iunlock");
    80004382:	00005517          	auipc	a0,0x5
    80004386:	41650513          	addi	a0,a0,1046 # 80009798 <syscalls+0x1c0>
    8000438a:	ffffc097          	auipc	ra,0xffffc
    8000438e:	1ba080e7          	jalr	442(ra) # 80000544 <panic>

0000000080004392 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004392:	7179                	addi	sp,sp,-48
    80004394:	f406                	sd	ra,40(sp)
    80004396:	f022                	sd	s0,32(sp)
    80004398:	ec26                	sd	s1,24(sp)
    8000439a:	e84a                	sd	s2,16(sp)
    8000439c:	e44e                	sd	s3,8(sp)
    8000439e:	e052                	sd	s4,0(sp)
    800043a0:	1800                	addi	s0,sp,48
    800043a2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800043a4:	05050493          	addi	s1,a0,80
    800043a8:	08050913          	addi	s2,a0,128
    800043ac:	a021                	j	800043b4 <itrunc+0x22>
    800043ae:	0491                	addi	s1,s1,4
    800043b0:	01248d63          	beq	s1,s2,800043ca <itrunc+0x38>
    if(ip->addrs[i]){
    800043b4:	408c                	lw	a1,0(s1)
    800043b6:	dde5                	beqz	a1,800043ae <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800043b8:	0009a503          	lw	a0,0(s3)
    800043bc:	00000097          	auipc	ra,0x0
    800043c0:	8f4080e7          	jalr	-1804(ra) # 80003cb0 <bfree>
      ip->addrs[i] = 0;
    800043c4:	0004a023          	sw	zero,0(s1)
    800043c8:	b7dd                	j	800043ae <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800043ca:	0809a583          	lw	a1,128(s3)
    800043ce:	e185                	bnez	a1,800043ee <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800043d0:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800043d4:	854e                	mv	a0,s3
    800043d6:	00000097          	auipc	ra,0x0
    800043da:	de4080e7          	jalr	-540(ra) # 800041ba <iupdate>
}
    800043de:	70a2                	ld	ra,40(sp)
    800043e0:	7402                	ld	s0,32(sp)
    800043e2:	64e2                	ld	s1,24(sp)
    800043e4:	6942                	ld	s2,16(sp)
    800043e6:	69a2                	ld	s3,8(sp)
    800043e8:	6a02                	ld	s4,0(sp)
    800043ea:	6145                	addi	sp,sp,48
    800043ec:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800043ee:	0009a503          	lw	a0,0(s3)
    800043f2:	fffff097          	auipc	ra,0xfffff
    800043f6:	678080e7          	jalr	1656(ra) # 80003a6a <bread>
    800043fa:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800043fc:	05850493          	addi	s1,a0,88
    80004400:	45850913          	addi	s2,a0,1112
    80004404:	a811                	j	80004418 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80004406:	0009a503          	lw	a0,0(s3)
    8000440a:	00000097          	auipc	ra,0x0
    8000440e:	8a6080e7          	jalr	-1882(ra) # 80003cb0 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80004412:	0491                	addi	s1,s1,4
    80004414:	01248563          	beq	s1,s2,8000441e <itrunc+0x8c>
      if(a[j])
    80004418:	408c                	lw	a1,0(s1)
    8000441a:	dde5                	beqz	a1,80004412 <itrunc+0x80>
    8000441c:	b7ed                	j	80004406 <itrunc+0x74>
    brelse(bp);
    8000441e:	8552                	mv	a0,s4
    80004420:	fffff097          	auipc	ra,0xfffff
    80004424:	77a080e7          	jalr	1914(ra) # 80003b9a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004428:	0809a583          	lw	a1,128(s3)
    8000442c:	0009a503          	lw	a0,0(s3)
    80004430:	00000097          	auipc	ra,0x0
    80004434:	880080e7          	jalr	-1920(ra) # 80003cb0 <bfree>
    ip->addrs[NDIRECT] = 0;
    80004438:	0809a023          	sw	zero,128(s3)
    8000443c:	bf51                	j	800043d0 <itrunc+0x3e>

000000008000443e <iput>:
{
    8000443e:	1101                	addi	sp,sp,-32
    80004440:	ec06                	sd	ra,24(sp)
    80004442:	e822                	sd	s0,16(sp)
    80004444:	e426                	sd	s1,8(sp)
    80004446:	e04a                	sd	s2,0(sp)
    80004448:	1000                	addi	s0,sp,32
    8000444a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000444c:	0001e517          	auipc	a0,0x1e
    80004450:	b5450513          	addi	a0,a0,-1196 # 80021fa0 <itable>
    80004454:	ffffc097          	auipc	ra,0xffffc
    80004458:	796080e7          	jalr	1942(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000445c:	4498                	lw	a4,8(s1)
    8000445e:	4785                	li	a5,1
    80004460:	02f70363          	beq	a4,a5,80004486 <iput+0x48>
  ip->ref--;
    80004464:	449c                	lw	a5,8(s1)
    80004466:	37fd                	addiw	a5,a5,-1
    80004468:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000446a:	0001e517          	auipc	a0,0x1e
    8000446e:	b3650513          	addi	a0,a0,-1226 # 80021fa0 <itable>
    80004472:	ffffd097          	auipc	ra,0xffffd
    80004476:	82c080e7          	jalr	-2004(ra) # 80000c9e <release>
}
    8000447a:	60e2                	ld	ra,24(sp)
    8000447c:	6442                	ld	s0,16(sp)
    8000447e:	64a2                	ld	s1,8(sp)
    80004480:	6902                	ld	s2,0(sp)
    80004482:	6105                	addi	sp,sp,32
    80004484:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004486:	40bc                	lw	a5,64(s1)
    80004488:	dff1                	beqz	a5,80004464 <iput+0x26>
    8000448a:	04a49783          	lh	a5,74(s1)
    8000448e:	fbf9                	bnez	a5,80004464 <iput+0x26>
    acquiresleep(&ip->lock);
    80004490:	01048913          	addi	s2,s1,16
    80004494:	854a                	mv	a0,s2
    80004496:	00001097          	auipc	ra,0x1
    8000449a:	aa8080e7          	jalr	-1368(ra) # 80004f3e <acquiresleep>
    release(&itable.lock);
    8000449e:	0001e517          	auipc	a0,0x1e
    800044a2:	b0250513          	addi	a0,a0,-1278 # 80021fa0 <itable>
    800044a6:	ffffc097          	auipc	ra,0xffffc
    800044aa:	7f8080e7          	jalr	2040(ra) # 80000c9e <release>
    itrunc(ip);
    800044ae:	8526                	mv	a0,s1
    800044b0:	00000097          	auipc	ra,0x0
    800044b4:	ee2080e7          	jalr	-286(ra) # 80004392 <itrunc>
    ip->type = 0;
    800044b8:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800044bc:	8526                	mv	a0,s1
    800044be:	00000097          	auipc	ra,0x0
    800044c2:	cfc080e7          	jalr	-772(ra) # 800041ba <iupdate>
    ip->valid = 0;
    800044c6:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800044ca:	854a                	mv	a0,s2
    800044cc:	00001097          	auipc	ra,0x1
    800044d0:	ac8080e7          	jalr	-1336(ra) # 80004f94 <releasesleep>
    acquire(&itable.lock);
    800044d4:	0001e517          	auipc	a0,0x1e
    800044d8:	acc50513          	addi	a0,a0,-1332 # 80021fa0 <itable>
    800044dc:	ffffc097          	auipc	ra,0xffffc
    800044e0:	70e080e7          	jalr	1806(ra) # 80000bea <acquire>
    800044e4:	b741                	j	80004464 <iput+0x26>

00000000800044e6 <iunlockput>:
{
    800044e6:	1101                	addi	sp,sp,-32
    800044e8:	ec06                	sd	ra,24(sp)
    800044ea:	e822                	sd	s0,16(sp)
    800044ec:	e426                	sd	s1,8(sp)
    800044ee:	1000                	addi	s0,sp,32
    800044f0:	84aa                	mv	s1,a0
  iunlock(ip);
    800044f2:	00000097          	auipc	ra,0x0
    800044f6:	e54080e7          	jalr	-428(ra) # 80004346 <iunlock>
  iput(ip);
    800044fa:	8526                	mv	a0,s1
    800044fc:	00000097          	auipc	ra,0x0
    80004500:	f42080e7          	jalr	-190(ra) # 8000443e <iput>
}
    80004504:	60e2                	ld	ra,24(sp)
    80004506:	6442                	ld	s0,16(sp)
    80004508:	64a2                	ld	s1,8(sp)
    8000450a:	6105                	addi	sp,sp,32
    8000450c:	8082                	ret

000000008000450e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000450e:	1141                	addi	sp,sp,-16
    80004510:	e422                	sd	s0,8(sp)
    80004512:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004514:	411c                	lw	a5,0(a0)
    80004516:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004518:	415c                	lw	a5,4(a0)
    8000451a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000451c:	04451783          	lh	a5,68(a0)
    80004520:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004524:	04a51783          	lh	a5,74(a0)
    80004528:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000452c:	04c56783          	lwu	a5,76(a0)
    80004530:	e99c                	sd	a5,16(a1)
}
    80004532:	6422                	ld	s0,8(sp)
    80004534:	0141                	addi	sp,sp,16
    80004536:	8082                	ret

0000000080004538 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004538:	457c                	lw	a5,76(a0)
    8000453a:	0ed7e963          	bltu	a5,a3,8000462c <readi+0xf4>
{
    8000453e:	7159                	addi	sp,sp,-112
    80004540:	f486                	sd	ra,104(sp)
    80004542:	f0a2                	sd	s0,96(sp)
    80004544:	eca6                	sd	s1,88(sp)
    80004546:	e8ca                	sd	s2,80(sp)
    80004548:	e4ce                	sd	s3,72(sp)
    8000454a:	e0d2                	sd	s4,64(sp)
    8000454c:	fc56                	sd	s5,56(sp)
    8000454e:	f85a                	sd	s6,48(sp)
    80004550:	f45e                	sd	s7,40(sp)
    80004552:	f062                	sd	s8,32(sp)
    80004554:	ec66                	sd	s9,24(sp)
    80004556:	e86a                	sd	s10,16(sp)
    80004558:	e46e                	sd	s11,8(sp)
    8000455a:	1880                	addi	s0,sp,112
    8000455c:	8b2a                	mv	s6,a0
    8000455e:	8bae                	mv	s7,a1
    80004560:	8a32                	mv	s4,a2
    80004562:	84b6                	mv	s1,a3
    80004564:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80004566:	9f35                	addw	a4,a4,a3
    return 0;
    80004568:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000456a:	0ad76063          	bltu	a4,a3,8000460a <readi+0xd2>
  if(off + n > ip->size)
    8000456e:	00e7f463          	bgeu	a5,a4,80004576 <readi+0x3e>
    n = ip->size - off;
    80004572:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004576:	0a0a8963          	beqz	s5,80004628 <readi+0xf0>
    8000457a:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000457c:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004580:	5c7d                	li	s8,-1
    80004582:	a82d                	j	800045bc <readi+0x84>
    80004584:	020d1d93          	slli	s11,s10,0x20
    80004588:	020ddd93          	srli	s11,s11,0x20
    8000458c:	05890613          	addi	a2,s2,88
    80004590:	86ee                	mv	a3,s11
    80004592:	963a                	add	a2,a2,a4
    80004594:	85d2                	mv	a1,s4
    80004596:	855e                	mv	a0,s7
    80004598:	ffffe097          	auipc	ra,0xffffe
    8000459c:	40c080e7          	jalr	1036(ra) # 800029a4 <either_copyout>
    800045a0:	05850d63          	beq	a0,s8,800045fa <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800045a4:	854a                	mv	a0,s2
    800045a6:	fffff097          	auipc	ra,0xfffff
    800045aa:	5f4080e7          	jalr	1524(ra) # 80003b9a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800045ae:	013d09bb          	addw	s3,s10,s3
    800045b2:	009d04bb          	addw	s1,s10,s1
    800045b6:	9a6e                	add	s4,s4,s11
    800045b8:	0559f763          	bgeu	s3,s5,80004606 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    800045bc:	00a4d59b          	srliw	a1,s1,0xa
    800045c0:	855a                	mv	a0,s6
    800045c2:	00000097          	auipc	ra,0x0
    800045c6:	8a2080e7          	jalr	-1886(ra) # 80003e64 <bmap>
    800045ca:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800045ce:	cd85                	beqz	a1,80004606 <readi+0xce>
    bp = bread(ip->dev, addr);
    800045d0:	000b2503          	lw	a0,0(s6)
    800045d4:	fffff097          	auipc	ra,0xfffff
    800045d8:	496080e7          	jalr	1174(ra) # 80003a6a <bread>
    800045dc:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800045de:	3ff4f713          	andi	a4,s1,1023
    800045e2:	40ec87bb          	subw	a5,s9,a4
    800045e6:	413a86bb          	subw	a3,s5,s3
    800045ea:	8d3e                	mv	s10,a5
    800045ec:	2781                	sext.w	a5,a5
    800045ee:	0006861b          	sext.w	a2,a3
    800045f2:	f8f679e3          	bgeu	a2,a5,80004584 <readi+0x4c>
    800045f6:	8d36                	mv	s10,a3
    800045f8:	b771                	j	80004584 <readi+0x4c>
      brelse(bp);
    800045fa:	854a                	mv	a0,s2
    800045fc:	fffff097          	auipc	ra,0xfffff
    80004600:	59e080e7          	jalr	1438(ra) # 80003b9a <brelse>
      tot = -1;
    80004604:	59fd                	li	s3,-1
  }
  return tot;
    80004606:	0009851b          	sext.w	a0,s3
}
    8000460a:	70a6                	ld	ra,104(sp)
    8000460c:	7406                	ld	s0,96(sp)
    8000460e:	64e6                	ld	s1,88(sp)
    80004610:	6946                	ld	s2,80(sp)
    80004612:	69a6                	ld	s3,72(sp)
    80004614:	6a06                	ld	s4,64(sp)
    80004616:	7ae2                	ld	s5,56(sp)
    80004618:	7b42                	ld	s6,48(sp)
    8000461a:	7ba2                	ld	s7,40(sp)
    8000461c:	7c02                	ld	s8,32(sp)
    8000461e:	6ce2                	ld	s9,24(sp)
    80004620:	6d42                	ld	s10,16(sp)
    80004622:	6da2                	ld	s11,8(sp)
    80004624:	6165                	addi	sp,sp,112
    80004626:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004628:	89d6                	mv	s3,s5
    8000462a:	bff1                	j	80004606 <readi+0xce>
    return 0;
    8000462c:	4501                	li	a0,0
}
    8000462e:	8082                	ret

0000000080004630 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004630:	457c                	lw	a5,76(a0)
    80004632:	10d7e863          	bltu	a5,a3,80004742 <writei+0x112>
{
    80004636:	7159                	addi	sp,sp,-112
    80004638:	f486                	sd	ra,104(sp)
    8000463a:	f0a2                	sd	s0,96(sp)
    8000463c:	eca6                	sd	s1,88(sp)
    8000463e:	e8ca                	sd	s2,80(sp)
    80004640:	e4ce                	sd	s3,72(sp)
    80004642:	e0d2                	sd	s4,64(sp)
    80004644:	fc56                	sd	s5,56(sp)
    80004646:	f85a                	sd	s6,48(sp)
    80004648:	f45e                	sd	s7,40(sp)
    8000464a:	f062                	sd	s8,32(sp)
    8000464c:	ec66                	sd	s9,24(sp)
    8000464e:	e86a                	sd	s10,16(sp)
    80004650:	e46e                	sd	s11,8(sp)
    80004652:	1880                	addi	s0,sp,112
    80004654:	8aaa                	mv	s5,a0
    80004656:	8bae                	mv	s7,a1
    80004658:	8a32                	mv	s4,a2
    8000465a:	8936                	mv	s2,a3
    8000465c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000465e:	00e687bb          	addw	a5,a3,a4
    80004662:	0ed7e263          	bltu	a5,a3,80004746 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004666:	00043737          	lui	a4,0x43
    8000466a:	0ef76063          	bltu	a4,a5,8000474a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000466e:	0c0b0863          	beqz	s6,8000473e <writei+0x10e>
    80004672:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004674:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004678:	5c7d                	li	s8,-1
    8000467a:	a091                	j	800046be <writei+0x8e>
    8000467c:	020d1d93          	slli	s11,s10,0x20
    80004680:	020ddd93          	srli	s11,s11,0x20
    80004684:	05848513          	addi	a0,s1,88
    80004688:	86ee                	mv	a3,s11
    8000468a:	8652                	mv	a2,s4
    8000468c:	85de                	mv	a1,s7
    8000468e:	953a                	add	a0,a0,a4
    80004690:	ffffe097          	auipc	ra,0xffffe
    80004694:	36a080e7          	jalr	874(ra) # 800029fa <either_copyin>
    80004698:	07850263          	beq	a0,s8,800046fc <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000469c:	8526                	mv	a0,s1
    8000469e:	00000097          	auipc	ra,0x0
    800046a2:	780080e7          	jalr	1920(ra) # 80004e1e <log_write>
    brelse(bp);
    800046a6:	8526                	mv	a0,s1
    800046a8:	fffff097          	auipc	ra,0xfffff
    800046ac:	4f2080e7          	jalr	1266(ra) # 80003b9a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800046b0:	013d09bb          	addw	s3,s10,s3
    800046b4:	012d093b          	addw	s2,s10,s2
    800046b8:	9a6e                	add	s4,s4,s11
    800046ba:	0569f663          	bgeu	s3,s6,80004706 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    800046be:	00a9559b          	srliw	a1,s2,0xa
    800046c2:	8556                	mv	a0,s5
    800046c4:	fffff097          	auipc	ra,0xfffff
    800046c8:	7a0080e7          	jalr	1952(ra) # 80003e64 <bmap>
    800046cc:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800046d0:	c99d                	beqz	a1,80004706 <writei+0xd6>
    bp = bread(ip->dev, addr);
    800046d2:	000aa503          	lw	a0,0(s5)
    800046d6:	fffff097          	auipc	ra,0xfffff
    800046da:	394080e7          	jalr	916(ra) # 80003a6a <bread>
    800046de:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800046e0:	3ff97713          	andi	a4,s2,1023
    800046e4:	40ec87bb          	subw	a5,s9,a4
    800046e8:	413b06bb          	subw	a3,s6,s3
    800046ec:	8d3e                	mv	s10,a5
    800046ee:	2781                	sext.w	a5,a5
    800046f0:	0006861b          	sext.w	a2,a3
    800046f4:	f8f674e3          	bgeu	a2,a5,8000467c <writei+0x4c>
    800046f8:	8d36                	mv	s10,a3
    800046fa:	b749                	j	8000467c <writei+0x4c>
      brelse(bp);
    800046fc:	8526                	mv	a0,s1
    800046fe:	fffff097          	auipc	ra,0xfffff
    80004702:	49c080e7          	jalr	1180(ra) # 80003b9a <brelse>
  }

  if(off > ip->size)
    80004706:	04caa783          	lw	a5,76(s5)
    8000470a:	0127f463          	bgeu	a5,s2,80004712 <writei+0xe2>
    ip->size = off;
    8000470e:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004712:	8556                	mv	a0,s5
    80004714:	00000097          	auipc	ra,0x0
    80004718:	aa6080e7          	jalr	-1370(ra) # 800041ba <iupdate>

  return tot;
    8000471c:	0009851b          	sext.w	a0,s3
}
    80004720:	70a6                	ld	ra,104(sp)
    80004722:	7406                	ld	s0,96(sp)
    80004724:	64e6                	ld	s1,88(sp)
    80004726:	6946                	ld	s2,80(sp)
    80004728:	69a6                	ld	s3,72(sp)
    8000472a:	6a06                	ld	s4,64(sp)
    8000472c:	7ae2                	ld	s5,56(sp)
    8000472e:	7b42                	ld	s6,48(sp)
    80004730:	7ba2                	ld	s7,40(sp)
    80004732:	7c02                	ld	s8,32(sp)
    80004734:	6ce2                	ld	s9,24(sp)
    80004736:	6d42                	ld	s10,16(sp)
    80004738:	6da2                	ld	s11,8(sp)
    8000473a:	6165                	addi	sp,sp,112
    8000473c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000473e:	89da                	mv	s3,s6
    80004740:	bfc9                	j	80004712 <writei+0xe2>
    return -1;
    80004742:	557d                	li	a0,-1
}
    80004744:	8082                	ret
    return -1;
    80004746:	557d                	li	a0,-1
    80004748:	bfe1                	j	80004720 <writei+0xf0>
    return -1;
    8000474a:	557d                	li	a0,-1
    8000474c:	bfd1                	j	80004720 <writei+0xf0>

000000008000474e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000474e:	1141                	addi	sp,sp,-16
    80004750:	e406                	sd	ra,8(sp)
    80004752:	e022                	sd	s0,0(sp)
    80004754:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004756:	4639                	li	a2,14
    80004758:	ffffc097          	auipc	ra,0xffffc
    8000475c:	666080e7          	jalr	1638(ra) # 80000dbe <strncmp>
}
    80004760:	60a2                	ld	ra,8(sp)
    80004762:	6402                	ld	s0,0(sp)
    80004764:	0141                	addi	sp,sp,16
    80004766:	8082                	ret

0000000080004768 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004768:	7139                	addi	sp,sp,-64
    8000476a:	fc06                	sd	ra,56(sp)
    8000476c:	f822                	sd	s0,48(sp)
    8000476e:	f426                	sd	s1,40(sp)
    80004770:	f04a                	sd	s2,32(sp)
    80004772:	ec4e                	sd	s3,24(sp)
    80004774:	e852                	sd	s4,16(sp)
    80004776:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004778:	04451703          	lh	a4,68(a0)
    8000477c:	4785                	li	a5,1
    8000477e:	00f71a63          	bne	a4,a5,80004792 <dirlookup+0x2a>
    80004782:	892a                	mv	s2,a0
    80004784:	89ae                	mv	s3,a1
    80004786:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004788:	457c                	lw	a5,76(a0)
    8000478a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000478c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000478e:	e79d                	bnez	a5,800047bc <dirlookup+0x54>
    80004790:	a8a5                	j	80004808 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004792:	00005517          	auipc	a0,0x5
    80004796:	00e50513          	addi	a0,a0,14 # 800097a0 <syscalls+0x1c8>
    8000479a:	ffffc097          	auipc	ra,0xffffc
    8000479e:	daa080e7          	jalr	-598(ra) # 80000544 <panic>
      panic("dirlookup read");
    800047a2:	00005517          	auipc	a0,0x5
    800047a6:	01650513          	addi	a0,a0,22 # 800097b8 <syscalls+0x1e0>
    800047aa:	ffffc097          	auipc	ra,0xffffc
    800047ae:	d9a080e7          	jalr	-614(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800047b2:	24c1                	addiw	s1,s1,16
    800047b4:	04c92783          	lw	a5,76(s2)
    800047b8:	04f4f763          	bgeu	s1,a5,80004806 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800047bc:	4741                	li	a4,16
    800047be:	86a6                	mv	a3,s1
    800047c0:	fc040613          	addi	a2,s0,-64
    800047c4:	4581                	li	a1,0
    800047c6:	854a                	mv	a0,s2
    800047c8:	00000097          	auipc	ra,0x0
    800047cc:	d70080e7          	jalr	-656(ra) # 80004538 <readi>
    800047d0:	47c1                	li	a5,16
    800047d2:	fcf518e3          	bne	a0,a5,800047a2 <dirlookup+0x3a>
    if(de.inum == 0)
    800047d6:	fc045783          	lhu	a5,-64(s0)
    800047da:	dfe1                	beqz	a5,800047b2 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800047dc:	fc240593          	addi	a1,s0,-62
    800047e0:	854e                	mv	a0,s3
    800047e2:	00000097          	auipc	ra,0x0
    800047e6:	f6c080e7          	jalr	-148(ra) # 8000474e <namecmp>
    800047ea:	f561                	bnez	a0,800047b2 <dirlookup+0x4a>
      if(poff)
    800047ec:	000a0463          	beqz	s4,800047f4 <dirlookup+0x8c>
        *poff = off;
    800047f0:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800047f4:	fc045583          	lhu	a1,-64(s0)
    800047f8:	00092503          	lw	a0,0(s2)
    800047fc:	fffff097          	auipc	ra,0xfffff
    80004800:	750080e7          	jalr	1872(ra) # 80003f4c <iget>
    80004804:	a011                	j	80004808 <dirlookup+0xa0>
  return 0;
    80004806:	4501                	li	a0,0
}
    80004808:	70e2                	ld	ra,56(sp)
    8000480a:	7442                	ld	s0,48(sp)
    8000480c:	74a2                	ld	s1,40(sp)
    8000480e:	7902                	ld	s2,32(sp)
    80004810:	69e2                	ld	s3,24(sp)
    80004812:	6a42                	ld	s4,16(sp)
    80004814:	6121                	addi	sp,sp,64
    80004816:	8082                	ret

0000000080004818 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004818:	711d                	addi	sp,sp,-96
    8000481a:	ec86                	sd	ra,88(sp)
    8000481c:	e8a2                	sd	s0,80(sp)
    8000481e:	e4a6                	sd	s1,72(sp)
    80004820:	e0ca                	sd	s2,64(sp)
    80004822:	fc4e                	sd	s3,56(sp)
    80004824:	f852                	sd	s4,48(sp)
    80004826:	f456                	sd	s5,40(sp)
    80004828:	f05a                	sd	s6,32(sp)
    8000482a:	ec5e                	sd	s7,24(sp)
    8000482c:	e862                	sd	s8,16(sp)
    8000482e:	e466                	sd	s9,8(sp)
    80004830:	1080                	addi	s0,sp,96
    80004832:	84aa                	mv	s1,a0
    80004834:	8b2e                	mv	s6,a1
    80004836:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004838:	00054703          	lbu	a4,0(a0)
    8000483c:	02f00793          	li	a5,47
    80004840:	02f70363          	beq	a4,a5,80004866 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004844:	ffffd097          	auipc	ra,0xffffd
    80004848:	382080e7          	jalr	898(ra) # 80001bc6 <myproc>
    8000484c:	15053503          	ld	a0,336(a0)
    80004850:	00000097          	auipc	ra,0x0
    80004854:	9f6080e7          	jalr	-1546(ra) # 80004246 <idup>
    80004858:	89aa                	mv	s3,a0
  while(*path == '/')
    8000485a:	02f00913          	li	s2,47
  len = path - s;
    8000485e:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004860:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004862:	4c05                	li	s8,1
    80004864:	a865                	j	8000491c <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004866:	4585                	li	a1,1
    80004868:	4505                	li	a0,1
    8000486a:	fffff097          	auipc	ra,0xfffff
    8000486e:	6e2080e7          	jalr	1762(ra) # 80003f4c <iget>
    80004872:	89aa                	mv	s3,a0
    80004874:	b7dd                	j	8000485a <namex+0x42>
      iunlockput(ip);
    80004876:	854e                	mv	a0,s3
    80004878:	00000097          	auipc	ra,0x0
    8000487c:	c6e080e7          	jalr	-914(ra) # 800044e6 <iunlockput>
      return 0;
    80004880:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004882:	854e                	mv	a0,s3
    80004884:	60e6                	ld	ra,88(sp)
    80004886:	6446                	ld	s0,80(sp)
    80004888:	64a6                	ld	s1,72(sp)
    8000488a:	6906                	ld	s2,64(sp)
    8000488c:	79e2                	ld	s3,56(sp)
    8000488e:	7a42                	ld	s4,48(sp)
    80004890:	7aa2                	ld	s5,40(sp)
    80004892:	7b02                	ld	s6,32(sp)
    80004894:	6be2                	ld	s7,24(sp)
    80004896:	6c42                	ld	s8,16(sp)
    80004898:	6ca2                	ld	s9,8(sp)
    8000489a:	6125                	addi	sp,sp,96
    8000489c:	8082                	ret
      iunlock(ip);
    8000489e:	854e                	mv	a0,s3
    800048a0:	00000097          	auipc	ra,0x0
    800048a4:	aa6080e7          	jalr	-1370(ra) # 80004346 <iunlock>
      return ip;
    800048a8:	bfe9                	j	80004882 <namex+0x6a>
      iunlockput(ip);
    800048aa:	854e                	mv	a0,s3
    800048ac:	00000097          	auipc	ra,0x0
    800048b0:	c3a080e7          	jalr	-966(ra) # 800044e6 <iunlockput>
      return 0;
    800048b4:	89d2                	mv	s3,s4
    800048b6:	b7f1                	j	80004882 <namex+0x6a>
  len = path - s;
    800048b8:	40b48633          	sub	a2,s1,a1
    800048bc:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800048c0:	094cd463          	bge	s9,s4,80004948 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800048c4:	4639                	li	a2,14
    800048c6:	8556                	mv	a0,s5
    800048c8:	ffffc097          	auipc	ra,0xffffc
    800048cc:	47e080e7          	jalr	1150(ra) # 80000d46 <memmove>
  while(*path == '/')
    800048d0:	0004c783          	lbu	a5,0(s1)
    800048d4:	01279763          	bne	a5,s2,800048e2 <namex+0xca>
    path++;
    800048d8:	0485                	addi	s1,s1,1
  while(*path == '/')
    800048da:	0004c783          	lbu	a5,0(s1)
    800048de:	ff278de3          	beq	a5,s2,800048d8 <namex+0xc0>
    ilock(ip);
    800048e2:	854e                	mv	a0,s3
    800048e4:	00000097          	auipc	ra,0x0
    800048e8:	9a0080e7          	jalr	-1632(ra) # 80004284 <ilock>
    if(ip->type != T_DIR){
    800048ec:	04499783          	lh	a5,68(s3)
    800048f0:	f98793e3          	bne	a5,s8,80004876 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800048f4:	000b0563          	beqz	s6,800048fe <namex+0xe6>
    800048f8:	0004c783          	lbu	a5,0(s1)
    800048fc:	d3cd                	beqz	a5,8000489e <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800048fe:	865e                	mv	a2,s7
    80004900:	85d6                	mv	a1,s5
    80004902:	854e                	mv	a0,s3
    80004904:	00000097          	auipc	ra,0x0
    80004908:	e64080e7          	jalr	-412(ra) # 80004768 <dirlookup>
    8000490c:	8a2a                	mv	s4,a0
    8000490e:	dd51                	beqz	a0,800048aa <namex+0x92>
    iunlockput(ip);
    80004910:	854e                	mv	a0,s3
    80004912:	00000097          	auipc	ra,0x0
    80004916:	bd4080e7          	jalr	-1068(ra) # 800044e6 <iunlockput>
    ip = next;
    8000491a:	89d2                	mv	s3,s4
  while(*path == '/')
    8000491c:	0004c783          	lbu	a5,0(s1)
    80004920:	05279763          	bne	a5,s2,8000496e <namex+0x156>
    path++;
    80004924:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004926:	0004c783          	lbu	a5,0(s1)
    8000492a:	ff278de3          	beq	a5,s2,80004924 <namex+0x10c>
  if(*path == 0)
    8000492e:	c79d                	beqz	a5,8000495c <namex+0x144>
    path++;
    80004930:	85a6                	mv	a1,s1
  len = path - s;
    80004932:	8a5e                	mv	s4,s7
    80004934:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004936:	01278963          	beq	a5,s2,80004948 <namex+0x130>
    8000493a:	dfbd                	beqz	a5,800048b8 <namex+0xa0>
    path++;
    8000493c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000493e:	0004c783          	lbu	a5,0(s1)
    80004942:	ff279ce3          	bne	a5,s2,8000493a <namex+0x122>
    80004946:	bf8d                	j	800048b8 <namex+0xa0>
    memmove(name, s, len);
    80004948:	2601                	sext.w	a2,a2
    8000494a:	8556                	mv	a0,s5
    8000494c:	ffffc097          	auipc	ra,0xffffc
    80004950:	3fa080e7          	jalr	1018(ra) # 80000d46 <memmove>
    name[len] = 0;
    80004954:	9a56                	add	s4,s4,s5
    80004956:	000a0023          	sb	zero,0(s4)
    8000495a:	bf9d                	j	800048d0 <namex+0xb8>
  if(nameiparent){
    8000495c:	f20b03e3          	beqz	s6,80004882 <namex+0x6a>
    iput(ip);
    80004960:	854e                	mv	a0,s3
    80004962:	00000097          	auipc	ra,0x0
    80004966:	adc080e7          	jalr	-1316(ra) # 8000443e <iput>
    return 0;
    8000496a:	4981                	li	s3,0
    8000496c:	bf19                	j	80004882 <namex+0x6a>
  if(*path == 0)
    8000496e:	d7fd                	beqz	a5,8000495c <namex+0x144>
  while(*path != '/' && *path != 0)
    80004970:	0004c783          	lbu	a5,0(s1)
    80004974:	85a6                	mv	a1,s1
    80004976:	b7d1                	j	8000493a <namex+0x122>

0000000080004978 <dirlink>:
{
    80004978:	7139                	addi	sp,sp,-64
    8000497a:	fc06                	sd	ra,56(sp)
    8000497c:	f822                	sd	s0,48(sp)
    8000497e:	f426                	sd	s1,40(sp)
    80004980:	f04a                	sd	s2,32(sp)
    80004982:	ec4e                	sd	s3,24(sp)
    80004984:	e852                	sd	s4,16(sp)
    80004986:	0080                	addi	s0,sp,64
    80004988:	892a                	mv	s2,a0
    8000498a:	8a2e                	mv	s4,a1
    8000498c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000498e:	4601                	li	a2,0
    80004990:	00000097          	auipc	ra,0x0
    80004994:	dd8080e7          	jalr	-552(ra) # 80004768 <dirlookup>
    80004998:	e93d                	bnez	a0,80004a0e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000499a:	04c92483          	lw	s1,76(s2)
    8000499e:	c49d                	beqz	s1,800049cc <dirlink+0x54>
    800049a0:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800049a2:	4741                	li	a4,16
    800049a4:	86a6                	mv	a3,s1
    800049a6:	fc040613          	addi	a2,s0,-64
    800049aa:	4581                	li	a1,0
    800049ac:	854a                	mv	a0,s2
    800049ae:	00000097          	auipc	ra,0x0
    800049b2:	b8a080e7          	jalr	-1142(ra) # 80004538 <readi>
    800049b6:	47c1                	li	a5,16
    800049b8:	06f51163          	bne	a0,a5,80004a1a <dirlink+0xa2>
    if(de.inum == 0)
    800049bc:	fc045783          	lhu	a5,-64(s0)
    800049c0:	c791                	beqz	a5,800049cc <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800049c2:	24c1                	addiw	s1,s1,16
    800049c4:	04c92783          	lw	a5,76(s2)
    800049c8:	fcf4ede3          	bltu	s1,a5,800049a2 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800049cc:	4639                	li	a2,14
    800049ce:	85d2                	mv	a1,s4
    800049d0:	fc240513          	addi	a0,s0,-62
    800049d4:	ffffc097          	auipc	ra,0xffffc
    800049d8:	426080e7          	jalr	1062(ra) # 80000dfa <strncpy>
  de.inum = inum;
    800049dc:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800049e0:	4741                	li	a4,16
    800049e2:	86a6                	mv	a3,s1
    800049e4:	fc040613          	addi	a2,s0,-64
    800049e8:	4581                	li	a1,0
    800049ea:	854a                	mv	a0,s2
    800049ec:	00000097          	auipc	ra,0x0
    800049f0:	c44080e7          	jalr	-956(ra) # 80004630 <writei>
    800049f4:	1541                	addi	a0,a0,-16
    800049f6:	00a03533          	snez	a0,a0
    800049fa:	40a00533          	neg	a0,a0
}
    800049fe:	70e2                	ld	ra,56(sp)
    80004a00:	7442                	ld	s0,48(sp)
    80004a02:	74a2                	ld	s1,40(sp)
    80004a04:	7902                	ld	s2,32(sp)
    80004a06:	69e2                	ld	s3,24(sp)
    80004a08:	6a42                	ld	s4,16(sp)
    80004a0a:	6121                	addi	sp,sp,64
    80004a0c:	8082                	ret
    iput(ip);
    80004a0e:	00000097          	auipc	ra,0x0
    80004a12:	a30080e7          	jalr	-1488(ra) # 8000443e <iput>
    return -1;
    80004a16:	557d                	li	a0,-1
    80004a18:	b7dd                	j	800049fe <dirlink+0x86>
      panic("dirlink read");
    80004a1a:	00005517          	auipc	a0,0x5
    80004a1e:	dae50513          	addi	a0,a0,-594 # 800097c8 <syscalls+0x1f0>
    80004a22:	ffffc097          	auipc	ra,0xffffc
    80004a26:	b22080e7          	jalr	-1246(ra) # 80000544 <panic>

0000000080004a2a <namei>:

struct inode*
namei(char *path)
{
    80004a2a:	1101                	addi	sp,sp,-32
    80004a2c:	ec06                	sd	ra,24(sp)
    80004a2e:	e822                	sd	s0,16(sp)
    80004a30:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004a32:	fe040613          	addi	a2,s0,-32
    80004a36:	4581                	li	a1,0
    80004a38:	00000097          	auipc	ra,0x0
    80004a3c:	de0080e7          	jalr	-544(ra) # 80004818 <namex>
}
    80004a40:	60e2                	ld	ra,24(sp)
    80004a42:	6442                	ld	s0,16(sp)
    80004a44:	6105                	addi	sp,sp,32
    80004a46:	8082                	ret

0000000080004a48 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004a48:	1141                	addi	sp,sp,-16
    80004a4a:	e406                	sd	ra,8(sp)
    80004a4c:	e022                	sd	s0,0(sp)
    80004a4e:	0800                	addi	s0,sp,16
    80004a50:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004a52:	4585                	li	a1,1
    80004a54:	00000097          	auipc	ra,0x0
    80004a58:	dc4080e7          	jalr	-572(ra) # 80004818 <namex>
}
    80004a5c:	60a2                	ld	ra,8(sp)
    80004a5e:	6402                	ld	s0,0(sp)
    80004a60:	0141                	addi	sp,sp,16
    80004a62:	8082                	ret

0000000080004a64 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004a64:	1101                	addi	sp,sp,-32
    80004a66:	ec06                	sd	ra,24(sp)
    80004a68:	e822                	sd	s0,16(sp)
    80004a6a:	e426                	sd	s1,8(sp)
    80004a6c:	e04a                	sd	s2,0(sp)
    80004a6e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004a70:	0001f917          	auipc	s2,0x1f
    80004a74:	fd890913          	addi	s2,s2,-40 # 80023a48 <log>
    80004a78:	01892583          	lw	a1,24(s2)
    80004a7c:	02892503          	lw	a0,40(s2)
    80004a80:	fffff097          	auipc	ra,0xfffff
    80004a84:	fea080e7          	jalr	-22(ra) # 80003a6a <bread>
    80004a88:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004a8a:	02c92683          	lw	a3,44(s2)
    80004a8e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004a90:	02d05763          	blez	a3,80004abe <write_head+0x5a>
    80004a94:	0001f797          	auipc	a5,0x1f
    80004a98:	fe478793          	addi	a5,a5,-28 # 80023a78 <log+0x30>
    80004a9c:	05c50713          	addi	a4,a0,92
    80004aa0:	36fd                	addiw	a3,a3,-1
    80004aa2:	1682                	slli	a3,a3,0x20
    80004aa4:	9281                	srli	a3,a3,0x20
    80004aa6:	068a                	slli	a3,a3,0x2
    80004aa8:	0001f617          	auipc	a2,0x1f
    80004aac:	fd460613          	addi	a2,a2,-44 # 80023a7c <log+0x34>
    80004ab0:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004ab2:	4390                	lw	a2,0(a5)
    80004ab4:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004ab6:	0791                	addi	a5,a5,4
    80004ab8:	0711                	addi	a4,a4,4
    80004aba:	fed79ce3          	bne	a5,a3,80004ab2 <write_head+0x4e>
  }
  bwrite(buf);
    80004abe:	8526                	mv	a0,s1
    80004ac0:	fffff097          	auipc	ra,0xfffff
    80004ac4:	09c080e7          	jalr	156(ra) # 80003b5c <bwrite>
  brelse(buf);
    80004ac8:	8526                	mv	a0,s1
    80004aca:	fffff097          	auipc	ra,0xfffff
    80004ace:	0d0080e7          	jalr	208(ra) # 80003b9a <brelse>
}
    80004ad2:	60e2                	ld	ra,24(sp)
    80004ad4:	6442                	ld	s0,16(sp)
    80004ad6:	64a2                	ld	s1,8(sp)
    80004ad8:	6902                	ld	s2,0(sp)
    80004ada:	6105                	addi	sp,sp,32
    80004adc:	8082                	ret

0000000080004ade <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004ade:	0001f797          	auipc	a5,0x1f
    80004ae2:	f967a783          	lw	a5,-106(a5) # 80023a74 <log+0x2c>
    80004ae6:	0af05d63          	blez	a5,80004ba0 <install_trans+0xc2>
{
    80004aea:	7139                	addi	sp,sp,-64
    80004aec:	fc06                	sd	ra,56(sp)
    80004aee:	f822                	sd	s0,48(sp)
    80004af0:	f426                	sd	s1,40(sp)
    80004af2:	f04a                	sd	s2,32(sp)
    80004af4:	ec4e                	sd	s3,24(sp)
    80004af6:	e852                	sd	s4,16(sp)
    80004af8:	e456                	sd	s5,8(sp)
    80004afa:	e05a                	sd	s6,0(sp)
    80004afc:	0080                	addi	s0,sp,64
    80004afe:	8b2a                	mv	s6,a0
    80004b00:	0001fa97          	auipc	s5,0x1f
    80004b04:	f78a8a93          	addi	s5,s5,-136 # 80023a78 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b08:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004b0a:	0001f997          	auipc	s3,0x1f
    80004b0e:	f3e98993          	addi	s3,s3,-194 # 80023a48 <log>
    80004b12:	a035                	j	80004b3e <install_trans+0x60>
      bunpin(dbuf);
    80004b14:	8526                	mv	a0,s1
    80004b16:	fffff097          	auipc	ra,0xfffff
    80004b1a:	15e080e7          	jalr	350(ra) # 80003c74 <bunpin>
    brelse(lbuf);
    80004b1e:	854a                	mv	a0,s2
    80004b20:	fffff097          	auipc	ra,0xfffff
    80004b24:	07a080e7          	jalr	122(ra) # 80003b9a <brelse>
    brelse(dbuf);
    80004b28:	8526                	mv	a0,s1
    80004b2a:	fffff097          	auipc	ra,0xfffff
    80004b2e:	070080e7          	jalr	112(ra) # 80003b9a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b32:	2a05                	addiw	s4,s4,1
    80004b34:	0a91                	addi	s5,s5,4
    80004b36:	02c9a783          	lw	a5,44(s3)
    80004b3a:	04fa5963          	bge	s4,a5,80004b8c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004b3e:	0189a583          	lw	a1,24(s3)
    80004b42:	014585bb          	addw	a1,a1,s4
    80004b46:	2585                	addiw	a1,a1,1
    80004b48:	0289a503          	lw	a0,40(s3)
    80004b4c:	fffff097          	auipc	ra,0xfffff
    80004b50:	f1e080e7          	jalr	-226(ra) # 80003a6a <bread>
    80004b54:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004b56:	000aa583          	lw	a1,0(s5)
    80004b5a:	0289a503          	lw	a0,40(s3)
    80004b5e:	fffff097          	auipc	ra,0xfffff
    80004b62:	f0c080e7          	jalr	-244(ra) # 80003a6a <bread>
    80004b66:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004b68:	40000613          	li	a2,1024
    80004b6c:	05890593          	addi	a1,s2,88
    80004b70:	05850513          	addi	a0,a0,88
    80004b74:	ffffc097          	auipc	ra,0xffffc
    80004b78:	1d2080e7          	jalr	466(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004b7c:	8526                	mv	a0,s1
    80004b7e:	fffff097          	auipc	ra,0xfffff
    80004b82:	fde080e7          	jalr	-34(ra) # 80003b5c <bwrite>
    if(recovering == 0)
    80004b86:	f80b1ce3          	bnez	s6,80004b1e <install_trans+0x40>
    80004b8a:	b769                	j	80004b14 <install_trans+0x36>
}
    80004b8c:	70e2                	ld	ra,56(sp)
    80004b8e:	7442                	ld	s0,48(sp)
    80004b90:	74a2                	ld	s1,40(sp)
    80004b92:	7902                	ld	s2,32(sp)
    80004b94:	69e2                	ld	s3,24(sp)
    80004b96:	6a42                	ld	s4,16(sp)
    80004b98:	6aa2                	ld	s5,8(sp)
    80004b9a:	6b02                	ld	s6,0(sp)
    80004b9c:	6121                	addi	sp,sp,64
    80004b9e:	8082                	ret
    80004ba0:	8082                	ret

0000000080004ba2 <initlog>:
{
    80004ba2:	7179                	addi	sp,sp,-48
    80004ba4:	f406                	sd	ra,40(sp)
    80004ba6:	f022                	sd	s0,32(sp)
    80004ba8:	ec26                	sd	s1,24(sp)
    80004baa:	e84a                	sd	s2,16(sp)
    80004bac:	e44e                	sd	s3,8(sp)
    80004bae:	1800                	addi	s0,sp,48
    80004bb0:	892a                	mv	s2,a0
    80004bb2:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004bb4:	0001f497          	auipc	s1,0x1f
    80004bb8:	e9448493          	addi	s1,s1,-364 # 80023a48 <log>
    80004bbc:	00005597          	auipc	a1,0x5
    80004bc0:	c1c58593          	addi	a1,a1,-996 # 800097d8 <syscalls+0x200>
    80004bc4:	8526                	mv	a0,s1
    80004bc6:	ffffc097          	auipc	ra,0xffffc
    80004bca:	f94080e7          	jalr	-108(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    80004bce:	0149a583          	lw	a1,20(s3)
    80004bd2:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004bd4:	0109a783          	lw	a5,16(s3)
    80004bd8:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004bda:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004bde:	854a                	mv	a0,s2
    80004be0:	fffff097          	auipc	ra,0xfffff
    80004be4:	e8a080e7          	jalr	-374(ra) # 80003a6a <bread>
  log.lh.n = lh->n;
    80004be8:	4d3c                	lw	a5,88(a0)
    80004bea:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004bec:	02f05563          	blez	a5,80004c16 <initlog+0x74>
    80004bf0:	05c50713          	addi	a4,a0,92
    80004bf4:	0001f697          	auipc	a3,0x1f
    80004bf8:	e8468693          	addi	a3,a3,-380 # 80023a78 <log+0x30>
    80004bfc:	37fd                	addiw	a5,a5,-1
    80004bfe:	1782                	slli	a5,a5,0x20
    80004c00:	9381                	srli	a5,a5,0x20
    80004c02:	078a                	slli	a5,a5,0x2
    80004c04:	06050613          	addi	a2,a0,96
    80004c08:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004c0a:	4310                	lw	a2,0(a4)
    80004c0c:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004c0e:	0711                	addi	a4,a4,4
    80004c10:	0691                	addi	a3,a3,4
    80004c12:	fef71ce3          	bne	a4,a5,80004c0a <initlog+0x68>
  brelse(buf);
    80004c16:	fffff097          	auipc	ra,0xfffff
    80004c1a:	f84080e7          	jalr	-124(ra) # 80003b9a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004c1e:	4505                	li	a0,1
    80004c20:	00000097          	auipc	ra,0x0
    80004c24:	ebe080e7          	jalr	-322(ra) # 80004ade <install_trans>
  log.lh.n = 0;
    80004c28:	0001f797          	auipc	a5,0x1f
    80004c2c:	e407a623          	sw	zero,-436(a5) # 80023a74 <log+0x2c>
  write_head(); // clear the log
    80004c30:	00000097          	auipc	ra,0x0
    80004c34:	e34080e7          	jalr	-460(ra) # 80004a64 <write_head>
}
    80004c38:	70a2                	ld	ra,40(sp)
    80004c3a:	7402                	ld	s0,32(sp)
    80004c3c:	64e2                	ld	s1,24(sp)
    80004c3e:	6942                	ld	s2,16(sp)
    80004c40:	69a2                	ld	s3,8(sp)
    80004c42:	6145                	addi	sp,sp,48
    80004c44:	8082                	ret

0000000080004c46 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004c46:	1101                	addi	sp,sp,-32
    80004c48:	ec06                	sd	ra,24(sp)
    80004c4a:	e822                	sd	s0,16(sp)
    80004c4c:	e426                	sd	s1,8(sp)
    80004c4e:	e04a                	sd	s2,0(sp)
    80004c50:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004c52:	0001f517          	auipc	a0,0x1f
    80004c56:	df650513          	addi	a0,a0,-522 # 80023a48 <log>
    80004c5a:	ffffc097          	auipc	ra,0xffffc
    80004c5e:	f90080e7          	jalr	-112(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    80004c62:	0001f497          	auipc	s1,0x1f
    80004c66:	de648493          	addi	s1,s1,-538 # 80023a48 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004c6a:	4979                	li	s2,30
    80004c6c:	a039                	j	80004c7a <begin_op+0x34>
      sleep(&log, &log.lock);
    80004c6e:	85a6                	mv	a1,s1
    80004c70:	8526                	mv	a0,s1
    80004c72:	ffffd097          	auipc	ra,0xffffd
    80004c76:	7d2080e7          	jalr	2002(ra) # 80002444 <sleep>
    if(log.committing){
    80004c7a:	50dc                	lw	a5,36(s1)
    80004c7c:	fbed                	bnez	a5,80004c6e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004c7e:	509c                	lw	a5,32(s1)
    80004c80:	0017871b          	addiw	a4,a5,1
    80004c84:	0007069b          	sext.w	a3,a4
    80004c88:	0027179b          	slliw	a5,a4,0x2
    80004c8c:	9fb9                	addw	a5,a5,a4
    80004c8e:	0017979b          	slliw	a5,a5,0x1
    80004c92:	54d8                	lw	a4,44(s1)
    80004c94:	9fb9                	addw	a5,a5,a4
    80004c96:	00f95963          	bge	s2,a5,80004ca8 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004c9a:	85a6                	mv	a1,s1
    80004c9c:	8526                	mv	a0,s1
    80004c9e:	ffffd097          	auipc	ra,0xffffd
    80004ca2:	7a6080e7          	jalr	1958(ra) # 80002444 <sleep>
    80004ca6:	bfd1                	j	80004c7a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004ca8:	0001f517          	auipc	a0,0x1f
    80004cac:	da050513          	addi	a0,a0,-608 # 80023a48 <log>
    80004cb0:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004cb2:	ffffc097          	auipc	ra,0xffffc
    80004cb6:	fec080e7          	jalr	-20(ra) # 80000c9e <release>
      break;
    }
  }
}
    80004cba:	60e2                	ld	ra,24(sp)
    80004cbc:	6442                	ld	s0,16(sp)
    80004cbe:	64a2                	ld	s1,8(sp)
    80004cc0:	6902                	ld	s2,0(sp)
    80004cc2:	6105                	addi	sp,sp,32
    80004cc4:	8082                	ret

0000000080004cc6 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004cc6:	7139                	addi	sp,sp,-64
    80004cc8:	fc06                	sd	ra,56(sp)
    80004cca:	f822                	sd	s0,48(sp)
    80004ccc:	f426                	sd	s1,40(sp)
    80004cce:	f04a                	sd	s2,32(sp)
    80004cd0:	ec4e                	sd	s3,24(sp)
    80004cd2:	e852                	sd	s4,16(sp)
    80004cd4:	e456                	sd	s5,8(sp)
    80004cd6:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004cd8:	0001f497          	auipc	s1,0x1f
    80004cdc:	d7048493          	addi	s1,s1,-656 # 80023a48 <log>
    80004ce0:	8526                	mv	a0,s1
    80004ce2:	ffffc097          	auipc	ra,0xffffc
    80004ce6:	f08080e7          	jalr	-248(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    80004cea:	509c                	lw	a5,32(s1)
    80004cec:	37fd                	addiw	a5,a5,-1
    80004cee:	0007891b          	sext.w	s2,a5
    80004cf2:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004cf4:	50dc                	lw	a5,36(s1)
    80004cf6:	efb9                	bnez	a5,80004d54 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004cf8:	06091663          	bnez	s2,80004d64 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004cfc:	0001f497          	auipc	s1,0x1f
    80004d00:	d4c48493          	addi	s1,s1,-692 # 80023a48 <log>
    80004d04:	4785                	li	a5,1
    80004d06:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004d08:	8526                	mv	a0,s1
    80004d0a:	ffffc097          	auipc	ra,0xffffc
    80004d0e:	f94080e7          	jalr	-108(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004d12:	54dc                	lw	a5,44(s1)
    80004d14:	06f04763          	bgtz	a5,80004d82 <end_op+0xbc>
    acquire(&log.lock);
    80004d18:	0001f497          	auipc	s1,0x1f
    80004d1c:	d3048493          	addi	s1,s1,-720 # 80023a48 <log>
    80004d20:	8526                	mv	a0,s1
    80004d22:	ffffc097          	auipc	ra,0xffffc
    80004d26:	ec8080e7          	jalr	-312(ra) # 80000bea <acquire>
    log.committing = 0;
    80004d2a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004d2e:	8526                	mv	a0,s1
    80004d30:	ffffe097          	auipc	ra,0xffffe
    80004d34:	8c4080e7          	jalr	-1852(ra) # 800025f4 <wakeup>
    release(&log.lock);
    80004d38:	8526                	mv	a0,s1
    80004d3a:	ffffc097          	auipc	ra,0xffffc
    80004d3e:	f64080e7          	jalr	-156(ra) # 80000c9e <release>
}
    80004d42:	70e2                	ld	ra,56(sp)
    80004d44:	7442                	ld	s0,48(sp)
    80004d46:	74a2                	ld	s1,40(sp)
    80004d48:	7902                	ld	s2,32(sp)
    80004d4a:	69e2                	ld	s3,24(sp)
    80004d4c:	6a42                	ld	s4,16(sp)
    80004d4e:	6aa2                	ld	s5,8(sp)
    80004d50:	6121                	addi	sp,sp,64
    80004d52:	8082                	ret
    panic("log.committing");
    80004d54:	00005517          	auipc	a0,0x5
    80004d58:	a8c50513          	addi	a0,a0,-1396 # 800097e0 <syscalls+0x208>
    80004d5c:	ffffb097          	auipc	ra,0xffffb
    80004d60:	7e8080e7          	jalr	2024(ra) # 80000544 <panic>
    wakeup(&log);
    80004d64:	0001f497          	auipc	s1,0x1f
    80004d68:	ce448493          	addi	s1,s1,-796 # 80023a48 <log>
    80004d6c:	8526                	mv	a0,s1
    80004d6e:	ffffe097          	auipc	ra,0xffffe
    80004d72:	886080e7          	jalr	-1914(ra) # 800025f4 <wakeup>
  release(&log.lock);
    80004d76:	8526                	mv	a0,s1
    80004d78:	ffffc097          	auipc	ra,0xffffc
    80004d7c:	f26080e7          	jalr	-218(ra) # 80000c9e <release>
  if(do_commit){
    80004d80:	b7c9                	j	80004d42 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004d82:	0001fa97          	auipc	s5,0x1f
    80004d86:	cf6a8a93          	addi	s5,s5,-778 # 80023a78 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004d8a:	0001fa17          	auipc	s4,0x1f
    80004d8e:	cbea0a13          	addi	s4,s4,-834 # 80023a48 <log>
    80004d92:	018a2583          	lw	a1,24(s4)
    80004d96:	012585bb          	addw	a1,a1,s2
    80004d9a:	2585                	addiw	a1,a1,1
    80004d9c:	028a2503          	lw	a0,40(s4)
    80004da0:	fffff097          	auipc	ra,0xfffff
    80004da4:	cca080e7          	jalr	-822(ra) # 80003a6a <bread>
    80004da8:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004daa:	000aa583          	lw	a1,0(s5)
    80004dae:	028a2503          	lw	a0,40(s4)
    80004db2:	fffff097          	auipc	ra,0xfffff
    80004db6:	cb8080e7          	jalr	-840(ra) # 80003a6a <bread>
    80004dba:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004dbc:	40000613          	li	a2,1024
    80004dc0:	05850593          	addi	a1,a0,88
    80004dc4:	05848513          	addi	a0,s1,88
    80004dc8:	ffffc097          	auipc	ra,0xffffc
    80004dcc:	f7e080e7          	jalr	-130(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    80004dd0:	8526                	mv	a0,s1
    80004dd2:	fffff097          	auipc	ra,0xfffff
    80004dd6:	d8a080e7          	jalr	-630(ra) # 80003b5c <bwrite>
    brelse(from);
    80004dda:	854e                	mv	a0,s3
    80004ddc:	fffff097          	auipc	ra,0xfffff
    80004de0:	dbe080e7          	jalr	-578(ra) # 80003b9a <brelse>
    brelse(to);
    80004de4:	8526                	mv	a0,s1
    80004de6:	fffff097          	auipc	ra,0xfffff
    80004dea:	db4080e7          	jalr	-588(ra) # 80003b9a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004dee:	2905                	addiw	s2,s2,1
    80004df0:	0a91                	addi	s5,s5,4
    80004df2:	02ca2783          	lw	a5,44(s4)
    80004df6:	f8f94ee3          	blt	s2,a5,80004d92 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004dfa:	00000097          	auipc	ra,0x0
    80004dfe:	c6a080e7          	jalr	-918(ra) # 80004a64 <write_head>
    install_trans(0); // Now install writes to home locations
    80004e02:	4501                	li	a0,0
    80004e04:	00000097          	auipc	ra,0x0
    80004e08:	cda080e7          	jalr	-806(ra) # 80004ade <install_trans>
    log.lh.n = 0;
    80004e0c:	0001f797          	auipc	a5,0x1f
    80004e10:	c607a423          	sw	zero,-920(a5) # 80023a74 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004e14:	00000097          	auipc	ra,0x0
    80004e18:	c50080e7          	jalr	-944(ra) # 80004a64 <write_head>
    80004e1c:	bdf5                	j	80004d18 <end_op+0x52>

0000000080004e1e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004e1e:	1101                	addi	sp,sp,-32
    80004e20:	ec06                	sd	ra,24(sp)
    80004e22:	e822                	sd	s0,16(sp)
    80004e24:	e426                	sd	s1,8(sp)
    80004e26:	e04a                	sd	s2,0(sp)
    80004e28:	1000                	addi	s0,sp,32
    80004e2a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004e2c:	0001f917          	auipc	s2,0x1f
    80004e30:	c1c90913          	addi	s2,s2,-996 # 80023a48 <log>
    80004e34:	854a                	mv	a0,s2
    80004e36:	ffffc097          	auipc	ra,0xffffc
    80004e3a:	db4080e7          	jalr	-588(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004e3e:	02c92603          	lw	a2,44(s2)
    80004e42:	47f5                	li	a5,29
    80004e44:	06c7c563          	blt	a5,a2,80004eae <log_write+0x90>
    80004e48:	0001f797          	auipc	a5,0x1f
    80004e4c:	c1c7a783          	lw	a5,-996(a5) # 80023a64 <log+0x1c>
    80004e50:	37fd                	addiw	a5,a5,-1
    80004e52:	04f65e63          	bge	a2,a5,80004eae <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004e56:	0001f797          	auipc	a5,0x1f
    80004e5a:	c127a783          	lw	a5,-1006(a5) # 80023a68 <log+0x20>
    80004e5e:	06f05063          	blez	a5,80004ebe <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004e62:	4781                	li	a5,0
    80004e64:	06c05563          	blez	a2,80004ece <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004e68:	44cc                	lw	a1,12(s1)
    80004e6a:	0001f717          	auipc	a4,0x1f
    80004e6e:	c0e70713          	addi	a4,a4,-1010 # 80023a78 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004e72:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004e74:	4314                	lw	a3,0(a4)
    80004e76:	04b68c63          	beq	a3,a1,80004ece <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004e7a:	2785                	addiw	a5,a5,1
    80004e7c:	0711                	addi	a4,a4,4
    80004e7e:	fef61be3          	bne	a2,a5,80004e74 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004e82:	0621                	addi	a2,a2,8
    80004e84:	060a                	slli	a2,a2,0x2
    80004e86:	0001f797          	auipc	a5,0x1f
    80004e8a:	bc278793          	addi	a5,a5,-1086 # 80023a48 <log>
    80004e8e:	963e                	add	a2,a2,a5
    80004e90:	44dc                	lw	a5,12(s1)
    80004e92:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004e94:	8526                	mv	a0,s1
    80004e96:	fffff097          	auipc	ra,0xfffff
    80004e9a:	da2080e7          	jalr	-606(ra) # 80003c38 <bpin>
    log.lh.n++;
    80004e9e:	0001f717          	auipc	a4,0x1f
    80004ea2:	baa70713          	addi	a4,a4,-1110 # 80023a48 <log>
    80004ea6:	575c                	lw	a5,44(a4)
    80004ea8:	2785                	addiw	a5,a5,1
    80004eaa:	d75c                	sw	a5,44(a4)
    80004eac:	a835                	j	80004ee8 <log_write+0xca>
    panic("too big a transaction");
    80004eae:	00005517          	auipc	a0,0x5
    80004eb2:	94250513          	addi	a0,a0,-1726 # 800097f0 <syscalls+0x218>
    80004eb6:	ffffb097          	auipc	ra,0xffffb
    80004eba:	68e080e7          	jalr	1678(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    80004ebe:	00005517          	auipc	a0,0x5
    80004ec2:	94a50513          	addi	a0,a0,-1718 # 80009808 <syscalls+0x230>
    80004ec6:	ffffb097          	auipc	ra,0xffffb
    80004eca:	67e080e7          	jalr	1662(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    80004ece:	00878713          	addi	a4,a5,8
    80004ed2:	00271693          	slli	a3,a4,0x2
    80004ed6:	0001f717          	auipc	a4,0x1f
    80004eda:	b7270713          	addi	a4,a4,-1166 # 80023a48 <log>
    80004ede:	9736                	add	a4,a4,a3
    80004ee0:	44d4                	lw	a3,12(s1)
    80004ee2:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004ee4:	faf608e3          	beq	a2,a5,80004e94 <log_write+0x76>
  }
  release(&log.lock);
    80004ee8:	0001f517          	auipc	a0,0x1f
    80004eec:	b6050513          	addi	a0,a0,-1184 # 80023a48 <log>
    80004ef0:	ffffc097          	auipc	ra,0xffffc
    80004ef4:	dae080e7          	jalr	-594(ra) # 80000c9e <release>
}
    80004ef8:	60e2                	ld	ra,24(sp)
    80004efa:	6442                	ld	s0,16(sp)
    80004efc:	64a2                	ld	s1,8(sp)
    80004efe:	6902                	ld	s2,0(sp)
    80004f00:	6105                	addi	sp,sp,32
    80004f02:	8082                	ret

0000000080004f04 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004f04:	1101                	addi	sp,sp,-32
    80004f06:	ec06                	sd	ra,24(sp)
    80004f08:	e822                	sd	s0,16(sp)
    80004f0a:	e426                	sd	s1,8(sp)
    80004f0c:	e04a                	sd	s2,0(sp)
    80004f0e:	1000                	addi	s0,sp,32
    80004f10:	84aa                	mv	s1,a0
    80004f12:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004f14:	00005597          	auipc	a1,0x5
    80004f18:	91458593          	addi	a1,a1,-1772 # 80009828 <syscalls+0x250>
    80004f1c:	0521                	addi	a0,a0,8
    80004f1e:	ffffc097          	auipc	ra,0xffffc
    80004f22:	c3c080e7          	jalr	-964(ra) # 80000b5a <initlock>
  lk->name = name;
    80004f26:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004f2a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004f2e:	0204a423          	sw	zero,40(s1)
}
    80004f32:	60e2                	ld	ra,24(sp)
    80004f34:	6442                	ld	s0,16(sp)
    80004f36:	64a2                	ld	s1,8(sp)
    80004f38:	6902                	ld	s2,0(sp)
    80004f3a:	6105                	addi	sp,sp,32
    80004f3c:	8082                	ret

0000000080004f3e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004f3e:	1101                	addi	sp,sp,-32
    80004f40:	ec06                	sd	ra,24(sp)
    80004f42:	e822                	sd	s0,16(sp)
    80004f44:	e426                	sd	s1,8(sp)
    80004f46:	e04a                	sd	s2,0(sp)
    80004f48:	1000                	addi	s0,sp,32
    80004f4a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004f4c:	00850913          	addi	s2,a0,8
    80004f50:	854a                	mv	a0,s2
    80004f52:	ffffc097          	auipc	ra,0xffffc
    80004f56:	c98080e7          	jalr	-872(ra) # 80000bea <acquire>
  while (lk->locked) {
    80004f5a:	409c                	lw	a5,0(s1)
    80004f5c:	cb89                	beqz	a5,80004f6e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004f5e:	85ca                	mv	a1,s2
    80004f60:	8526                	mv	a0,s1
    80004f62:	ffffd097          	auipc	ra,0xffffd
    80004f66:	4e2080e7          	jalr	1250(ra) # 80002444 <sleep>
  while (lk->locked) {
    80004f6a:	409c                	lw	a5,0(s1)
    80004f6c:	fbed                	bnez	a5,80004f5e <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004f6e:	4785                	li	a5,1
    80004f70:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004f72:	ffffd097          	auipc	ra,0xffffd
    80004f76:	c54080e7          	jalr	-940(ra) # 80001bc6 <myproc>
    80004f7a:	591c                	lw	a5,48(a0)
    80004f7c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004f7e:	854a                	mv	a0,s2
    80004f80:	ffffc097          	auipc	ra,0xffffc
    80004f84:	d1e080e7          	jalr	-738(ra) # 80000c9e <release>
}
    80004f88:	60e2                	ld	ra,24(sp)
    80004f8a:	6442                	ld	s0,16(sp)
    80004f8c:	64a2                	ld	s1,8(sp)
    80004f8e:	6902                	ld	s2,0(sp)
    80004f90:	6105                	addi	sp,sp,32
    80004f92:	8082                	ret

0000000080004f94 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004f94:	1101                	addi	sp,sp,-32
    80004f96:	ec06                	sd	ra,24(sp)
    80004f98:	e822                	sd	s0,16(sp)
    80004f9a:	e426                	sd	s1,8(sp)
    80004f9c:	e04a                	sd	s2,0(sp)
    80004f9e:	1000                	addi	s0,sp,32
    80004fa0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004fa2:	00850913          	addi	s2,a0,8
    80004fa6:	854a                	mv	a0,s2
    80004fa8:	ffffc097          	auipc	ra,0xffffc
    80004fac:	c42080e7          	jalr	-958(ra) # 80000bea <acquire>
  lk->locked = 0;
    80004fb0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004fb4:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004fb8:	8526                	mv	a0,s1
    80004fba:	ffffd097          	auipc	ra,0xffffd
    80004fbe:	63a080e7          	jalr	1594(ra) # 800025f4 <wakeup>
  release(&lk->lk);
    80004fc2:	854a                	mv	a0,s2
    80004fc4:	ffffc097          	auipc	ra,0xffffc
    80004fc8:	cda080e7          	jalr	-806(ra) # 80000c9e <release>
}
    80004fcc:	60e2                	ld	ra,24(sp)
    80004fce:	6442                	ld	s0,16(sp)
    80004fd0:	64a2                	ld	s1,8(sp)
    80004fd2:	6902                	ld	s2,0(sp)
    80004fd4:	6105                	addi	sp,sp,32
    80004fd6:	8082                	ret

0000000080004fd8 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004fd8:	7179                	addi	sp,sp,-48
    80004fda:	f406                	sd	ra,40(sp)
    80004fdc:	f022                	sd	s0,32(sp)
    80004fde:	ec26                	sd	s1,24(sp)
    80004fe0:	e84a                	sd	s2,16(sp)
    80004fe2:	e44e                	sd	s3,8(sp)
    80004fe4:	1800                	addi	s0,sp,48
    80004fe6:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004fe8:	00850913          	addi	s2,a0,8
    80004fec:	854a                	mv	a0,s2
    80004fee:	ffffc097          	auipc	ra,0xffffc
    80004ff2:	bfc080e7          	jalr	-1028(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004ff6:	409c                	lw	a5,0(s1)
    80004ff8:	ef99                	bnez	a5,80005016 <holdingsleep+0x3e>
    80004ffa:	4481                	li	s1,0
  release(&lk->lk);
    80004ffc:	854a                	mv	a0,s2
    80004ffe:	ffffc097          	auipc	ra,0xffffc
    80005002:	ca0080e7          	jalr	-864(ra) # 80000c9e <release>
  return r;
}
    80005006:	8526                	mv	a0,s1
    80005008:	70a2                	ld	ra,40(sp)
    8000500a:	7402                	ld	s0,32(sp)
    8000500c:	64e2                	ld	s1,24(sp)
    8000500e:	6942                	ld	s2,16(sp)
    80005010:	69a2                	ld	s3,8(sp)
    80005012:	6145                	addi	sp,sp,48
    80005014:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80005016:	0284a983          	lw	s3,40(s1)
    8000501a:	ffffd097          	auipc	ra,0xffffd
    8000501e:	bac080e7          	jalr	-1108(ra) # 80001bc6 <myproc>
    80005022:	5904                	lw	s1,48(a0)
    80005024:	413484b3          	sub	s1,s1,s3
    80005028:	0014b493          	seqz	s1,s1
    8000502c:	bfc1                	j	80004ffc <holdingsleep+0x24>

000000008000502e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000502e:	1141                	addi	sp,sp,-16
    80005030:	e406                	sd	ra,8(sp)
    80005032:	e022                	sd	s0,0(sp)
    80005034:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80005036:	00005597          	auipc	a1,0x5
    8000503a:	80258593          	addi	a1,a1,-2046 # 80009838 <syscalls+0x260>
    8000503e:	0001f517          	auipc	a0,0x1f
    80005042:	b5250513          	addi	a0,a0,-1198 # 80023b90 <ftable>
    80005046:	ffffc097          	auipc	ra,0xffffc
    8000504a:	b14080e7          	jalr	-1260(ra) # 80000b5a <initlock>
}
    8000504e:	60a2                	ld	ra,8(sp)
    80005050:	6402                	ld	s0,0(sp)
    80005052:	0141                	addi	sp,sp,16
    80005054:	8082                	ret

0000000080005056 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80005056:	1101                	addi	sp,sp,-32
    80005058:	ec06                	sd	ra,24(sp)
    8000505a:	e822                	sd	s0,16(sp)
    8000505c:	e426                	sd	s1,8(sp)
    8000505e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80005060:	0001f517          	auipc	a0,0x1f
    80005064:	b3050513          	addi	a0,a0,-1232 # 80023b90 <ftable>
    80005068:	ffffc097          	auipc	ra,0xffffc
    8000506c:	b82080e7          	jalr	-1150(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005070:	0001f497          	auipc	s1,0x1f
    80005074:	b3848493          	addi	s1,s1,-1224 # 80023ba8 <ftable+0x18>
    80005078:	00020717          	auipc	a4,0x20
    8000507c:	ad070713          	addi	a4,a4,-1328 # 80024b48 <disk>
    if(f->ref == 0){
    80005080:	40dc                	lw	a5,4(s1)
    80005082:	cf99                	beqz	a5,800050a0 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005084:	02848493          	addi	s1,s1,40
    80005088:	fee49ce3          	bne	s1,a4,80005080 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000508c:	0001f517          	auipc	a0,0x1f
    80005090:	b0450513          	addi	a0,a0,-1276 # 80023b90 <ftable>
    80005094:	ffffc097          	auipc	ra,0xffffc
    80005098:	c0a080e7          	jalr	-1014(ra) # 80000c9e <release>
  return 0;
    8000509c:	4481                	li	s1,0
    8000509e:	a819                	j	800050b4 <filealloc+0x5e>
      f->ref = 1;
    800050a0:	4785                	li	a5,1
    800050a2:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800050a4:	0001f517          	auipc	a0,0x1f
    800050a8:	aec50513          	addi	a0,a0,-1300 # 80023b90 <ftable>
    800050ac:	ffffc097          	auipc	ra,0xffffc
    800050b0:	bf2080e7          	jalr	-1038(ra) # 80000c9e <release>
}
    800050b4:	8526                	mv	a0,s1
    800050b6:	60e2                	ld	ra,24(sp)
    800050b8:	6442                	ld	s0,16(sp)
    800050ba:	64a2                	ld	s1,8(sp)
    800050bc:	6105                	addi	sp,sp,32
    800050be:	8082                	ret

00000000800050c0 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800050c0:	1101                	addi	sp,sp,-32
    800050c2:	ec06                	sd	ra,24(sp)
    800050c4:	e822                	sd	s0,16(sp)
    800050c6:	e426                	sd	s1,8(sp)
    800050c8:	1000                	addi	s0,sp,32
    800050ca:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800050cc:	0001f517          	auipc	a0,0x1f
    800050d0:	ac450513          	addi	a0,a0,-1340 # 80023b90 <ftable>
    800050d4:	ffffc097          	auipc	ra,0xffffc
    800050d8:	b16080e7          	jalr	-1258(ra) # 80000bea <acquire>
  if(f->ref < 1)
    800050dc:	40dc                	lw	a5,4(s1)
    800050de:	02f05263          	blez	a5,80005102 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800050e2:	2785                	addiw	a5,a5,1
    800050e4:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800050e6:	0001f517          	auipc	a0,0x1f
    800050ea:	aaa50513          	addi	a0,a0,-1366 # 80023b90 <ftable>
    800050ee:	ffffc097          	auipc	ra,0xffffc
    800050f2:	bb0080e7          	jalr	-1104(ra) # 80000c9e <release>
  return f;
}
    800050f6:	8526                	mv	a0,s1
    800050f8:	60e2                	ld	ra,24(sp)
    800050fa:	6442                	ld	s0,16(sp)
    800050fc:	64a2                	ld	s1,8(sp)
    800050fe:	6105                	addi	sp,sp,32
    80005100:	8082                	ret
    panic("filedup");
    80005102:	00004517          	auipc	a0,0x4
    80005106:	73e50513          	addi	a0,a0,1854 # 80009840 <syscalls+0x268>
    8000510a:	ffffb097          	auipc	ra,0xffffb
    8000510e:	43a080e7          	jalr	1082(ra) # 80000544 <panic>

0000000080005112 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80005112:	7139                	addi	sp,sp,-64
    80005114:	fc06                	sd	ra,56(sp)
    80005116:	f822                	sd	s0,48(sp)
    80005118:	f426                	sd	s1,40(sp)
    8000511a:	f04a                	sd	s2,32(sp)
    8000511c:	ec4e                	sd	s3,24(sp)
    8000511e:	e852                	sd	s4,16(sp)
    80005120:	e456                	sd	s5,8(sp)
    80005122:	0080                	addi	s0,sp,64
    80005124:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80005126:	0001f517          	auipc	a0,0x1f
    8000512a:	a6a50513          	addi	a0,a0,-1430 # 80023b90 <ftable>
    8000512e:	ffffc097          	auipc	ra,0xffffc
    80005132:	abc080e7          	jalr	-1348(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80005136:	40dc                	lw	a5,4(s1)
    80005138:	06f05163          	blez	a5,8000519a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000513c:	37fd                	addiw	a5,a5,-1
    8000513e:	0007871b          	sext.w	a4,a5
    80005142:	c0dc                	sw	a5,4(s1)
    80005144:	06e04363          	bgtz	a4,800051aa <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80005148:	0004a903          	lw	s2,0(s1)
    8000514c:	0094ca83          	lbu	s5,9(s1)
    80005150:	0104ba03          	ld	s4,16(s1)
    80005154:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80005158:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000515c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80005160:	0001f517          	auipc	a0,0x1f
    80005164:	a3050513          	addi	a0,a0,-1488 # 80023b90 <ftable>
    80005168:	ffffc097          	auipc	ra,0xffffc
    8000516c:	b36080e7          	jalr	-1226(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    80005170:	4785                	li	a5,1
    80005172:	04f90d63          	beq	s2,a5,800051cc <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80005176:	3979                	addiw	s2,s2,-2
    80005178:	4785                	li	a5,1
    8000517a:	0527e063          	bltu	a5,s2,800051ba <fileclose+0xa8>
    begin_op();
    8000517e:	00000097          	auipc	ra,0x0
    80005182:	ac8080e7          	jalr	-1336(ra) # 80004c46 <begin_op>
    iput(ff.ip);
    80005186:	854e                	mv	a0,s3
    80005188:	fffff097          	auipc	ra,0xfffff
    8000518c:	2b6080e7          	jalr	694(ra) # 8000443e <iput>
    end_op();
    80005190:	00000097          	auipc	ra,0x0
    80005194:	b36080e7          	jalr	-1226(ra) # 80004cc6 <end_op>
    80005198:	a00d                	j	800051ba <fileclose+0xa8>
    panic("fileclose");
    8000519a:	00004517          	auipc	a0,0x4
    8000519e:	6ae50513          	addi	a0,a0,1710 # 80009848 <syscalls+0x270>
    800051a2:	ffffb097          	auipc	ra,0xffffb
    800051a6:	3a2080e7          	jalr	930(ra) # 80000544 <panic>
    release(&ftable.lock);
    800051aa:	0001f517          	auipc	a0,0x1f
    800051ae:	9e650513          	addi	a0,a0,-1562 # 80023b90 <ftable>
    800051b2:	ffffc097          	auipc	ra,0xffffc
    800051b6:	aec080e7          	jalr	-1300(ra) # 80000c9e <release>
  }
}
    800051ba:	70e2                	ld	ra,56(sp)
    800051bc:	7442                	ld	s0,48(sp)
    800051be:	74a2                	ld	s1,40(sp)
    800051c0:	7902                	ld	s2,32(sp)
    800051c2:	69e2                	ld	s3,24(sp)
    800051c4:	6a42                	ld	s4,16(sp)
    800051c6:	6aa2                	ld	s5,8(sp)
    800051c8:	6121                	addi	sp,sp,64
    800051ca:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800051cc:	85d6                	mv	a1,s5
    800051ce:	8552                	mv	a0,s4
    800051d0:	00000097          	auipc	ra,0x0
    800051d4:	34c080e7          	jalr	844(ra) # 8000551c <pipeclose>
    800051d8:	b7cd                	j	800051ba <fileclose+0xa8>

00000000800051da <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800051da:	715d                	addi	sp,sp,-80
    800051dc:	e486                	sd	ra,72(sp)
    800051de:	e0a2                	sd	s0,64(sp)
    800051e0:	fc26                	sd	s1,56(sp)
    800051e2:	f84a                	sd	s2,48(sp)
    800051e4:	f44e                	sd	s3,40(sp)
    800051e6:	0880                	addi	s0,sp,80
    800051e8:	84aa                	mv	s1,a0
    800051ea:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800051ec:	ffffd097          	auipc	ra,0xffffd
    800051f0:	9da080e7          	jalr	-1574(ra) # 80001bc6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800051f4:	409c                	lw	a5,0(s1)
    800051f6:	37f9                	addiw	a5,a5,-2
    800051f8:	4705                	li	a4,1
    800051fa:	04f76763          	bltu	a4,a5,80005248 <filestat+0x6e>
    800051fe:	892a                	mv	s2,a0
    ilock(f->ip);
    80005200:	6c88                	ld	a0,24(s1)
    80005202:	fffff097          	auipc	ra,0xfffff
    80005206:	082080e7          	jalr	130(ra) # 80004284 <ilock>
    stati(f->ip, &st);
    8000520a:	fb840593          	addi	a1,s0,-72
    8000520e:	6c88                	ld	a0,24(s1)
    80005210:	fffff097          	auipc	ra,0xfffff
    80005214:	2fe080e7          	jalr	766(ra) # 8000450e <stati>
    iunlock(f->ip);
    80005218:	6c88                	ld	a0,24(s1)
    8000521a:	fffff097          	auipc	ra,0xfffff
    8000521e:	12c080e7          	jalr	300(ra) # 80004346 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80005222:	46e1                	li	a3,24
    80005224:	fb840613          	addi	a2,s0,-72
    80005228:	85ce                	mv	a1,s3
    8000522a:	05093503          	ld	a0,80(s2)
    8000522e:	ffffc097          	auipc	ra,0xffffc
    80005232:	456080e7          	jalr	1110(ra) # 80001684 <copyout>
    80005236:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000523a:	60a6                	ld	ra,72(sp)
    8000523c:	6406                	ld	s0,64(sp)
    8000523e:	74e2                	ld	s1,56(sp)
    80005240:	7942                	ld	s2,48(sp)
    80005242:	79a2                	ld	s3,40(sp)
    80005244:	6161                	addi	sp,sp,80
    80005246:	8082                	ret
  return -1;
    80005248:	557d                	li	a0,-1
    8000524a:	bfc5                	j	8000523a <filestat+0x60>

000000008000524c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000524c:	7179                	addi	sp,sp,-48
    8000524e:	f406                	sd	ra,40(sp)
    80005250:	f022                	sd	s0,32(sp)
    80005252:	ec26                	sd	s1,24(sp)
    80005254:	e84a                	sd	s2,16(sp)
    80005256:	e44e                	sd	s3,8(sp)
    80005258:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000525a:	00854783          	lbu	a5,8(a0)
    8000525e:	c3d5                	beqz	a5,80005302 <fileread+0xb6>
    80005260:	84aa                	mv	s1,a0
    80005262:	89ae                	mv	s3,a1
    80005264:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80005266:	411c                	lw	a5,0(a0)
    80005268:	4705                	li	a4,1
    8000526a:	04e78963          	beq	a5,a4,800052bc <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000526e:	470d                	li	a4,3
    80005270:	04e78d63          	beq	a5,a4,800052ca <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005274:	4709                	li	a4,2
    80005276:	06e79e63          	bne	a5,a4,800052f2 <fileread+0xa6>
    ilock(f->ip);
    8000527a:	6d08                	ld	a0,24(a0)
    8000527c:	fffff097          	auipc	ra,0xfffff
    80005280:	008080e7          	jalr	8(ra) # 80004284 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80005284:	874a                	mv	a4,s2
    80005286:	5094                	lw	a3,32(s1)
    80005288:	864e                	mv	a2,s3
    8000528a:	4585                	li	a1,1
    8000528c:	6c88                	ld	a0,24(s1)
    8000528e:	fffff097          	auipc	ra,0xfffff
    80005292:	2aa080e7          	jalr	682(ra) # 80004538 <readi>
    80005296:	892a                	mv	s2,a0
    80005298:	00a05563          	blez	a0,800052a2 <fileread+0x56>
      f->off += r;
    8000529c:	509c                	lw	a5,32(s1)
    8000529e:	9fa9                	addw	a5,a5,a0
    800052a0:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800052a2:	6c88                	ld	a0,24(s1)
    800052a4:	fffff097          	auipc	ra,0xfffff
    800052a8:	0a2080e7          	jalr	162(ra) # 80004346 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800052ac:	854a                	mv	a0,s2
    800052ae:	70a2                	ld	ra,40(sp)
    800052b0:	7402                	ld	s0,32(sp)
    800052b2:	64e2                	ld	s1,24(sp)
    800052b4:	6942                	ld	s2,16(sp)
    800052b6:	69a2                	ld	s3,8(sp)
    800052b8:	6145                	addi	sp,sp,48
    800052ba:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800052bc:	6908                	ld	a0,16(a0)
    800052be:	00000097          	auipc	ra,0x0
    800052c2:	3ce080e7          	jalr	974(ra) # 8000568c <piperead>
    800052c6:	892a                	mv	s2,a0
    800052c8:	b7d5                	j	800052ac <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800052ca:	02451783          	lh	a5,36(a0)
    800052ce:	03079693          	slli	a3,a5,0x30
    800052d2:	92c1                	srli	a3,a3,0x30
    800052d4:	4725                	li	a4,9
    800052d6:	02d76863          	bltu	a4,a3,80005306 <fileread+0xba>
    800052da:	0792                	slli	a5,a5,0x4
    800052dc:	0001f717          	auipc	a4,0x1f
    800052e0:	81470713          	addi	a4,a4,-2028 # 80023af0 <devsw>
    800052e4:	97ba                	add	a5,a5,a4
    800052e6:	639c                	ld	a5,0(a5)
    800052e8:	c38d                	beqz	a5,8000530a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800052ea:	4505                	li	a0,1
    800052ec:	9782                	jalr	a5
    800052ee:	892a                	mv	s2,a0
    800052f0:	bf75                	j	800052ac <fileread+0x60>
    panic("fileread");
    800052f2:	00004517          	auipc	a0,0x4
    800052f6:	56650513          	addi	a0,a0,1382 # 80009858 <syscalls+0x280>
    800052fa:	ffffb097          	auipc	ra,0xffffb
    800052fe:	24a080e7          	jalr	586(ra) # 80000544 <panic>
    return -1;
    80005302:	597d                	li	s2,-1
    80005304:	b765                	j	800052ac <fileread+0x60>
      return -1;
    80005306:	597d                	li	s2,-1
    80005308:	b755                	j	800052ac <fileread+0x60>
    8000530a:	597d                	li	s2,-1
    8000530c:	b745                	j	800052ac <fileread+0x60>

000000008000530e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000530e:	715d                	addi	sp,sp,-80
    80005310:	e486                	sd	ra,72(sp)
    80005312:	e0a2                	sd	s0,64(sp)
    80005314:	fc26                	sd	s1,56(sp)
    80005316:	f84a                	sd	s2,48(sp)
    80005318:	f44e                	sd	s3,40(sp)
    8000531a:	f052                	sd	s4,32(sp)
    8000531c:	ec56                	sd	s5,24(sp)
    8000531e:	e85a                	sd	s6,16(sp)
    80005320:	e45e                	sd	s7,8(sp)
    80005322:	e062                	sd	s8,0(sp)
    80005324:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005326:	00954783          	lbu	a5,9(a0)
    8000532a:	10078663          	beqz	a5,80005436 <filewrite+0x128>
    8000532e:	892a                	mv	s2,a0
    80005330:	8aae                	mv	s5,a1
    80005332:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005334:	411c                	lw	a5,0(a0)
    80005336:	4705                	li	a4,1
    80005338:	02e78263          	beq	a5,a4,8000535c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000533c:	470d                	li	a4,3
    8000533e:	02e78663          	beq	a5,a4,8000536a <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005342:	4709                	li	a4,2
    80005344:	0ee79163          	bne	a5,a4,80005426 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005348:	0ac05d63          	blez	a2,80005402 <filewrite+0xf4>
    int i = 0;
    8000534c:	4981                	li	s3,0
    8000534e:	6b05                	lui	s6,0x1
    80005350:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005354:	6b85                	lui	s7,0x1
    80005356:	c00b8b9b          	addiw	s7,s7,-1024
    8000535a:	a861                	j	800053f2 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000535c:	6908                	ld	a0,16(a0)
    8000535e:	00000097          	auipc	ra,0x0
    80005362:	22e080e7          	jalr	558(ra) # 8000558c <pipewrite>
    80005366:	8a2a                	mv	s4,a0
    80005368:	a045                	j	80005408 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000536a:	02451783          	lh	a5,36(a0)
    8000536e:	03079693          	slli	a3,a5,0x30
    80005372:	92c1                	srli	a3,a3,0x30
    80005374:	4725                	li	a4,9
    80005376:	0cd76263          	bltu	a4,a3,8000543a <filewrite+0x12c>
    8000537a:	0792                	slli	a5,a5,0x4
    8000537c:	0001e717          	auipc	a4,0x1e
    80005380:	77470713          	addi	a4,a4,1908 # 80023af0 <devsw>
    80005384:	97ba                	add	a5,a5,a4
    80005386:	679c                	ld	a5,8(a5)
    80005388:	cbdd                	beqz	a5,8000543e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000538a:	4505                	li	a0,1
    8000538c:	9782                	jalr	a5
    8000538e:	8a2a                	mv	s4,a0
    80005390:	a8a5                	j	80005408 <filewrite+0xfa>
    80005392:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005396:	00000097          	auipc	ra,0x0
    8000539a:	8b0080e7          	jalr	-1872(ra) # 80004c46 <begin_op>
      ilock(f->ip);
    8000539e:	01893503          	ld	a0,24(s2)
    800053a2:	fffff097          	auipc	ra,0xfffff
    800053a6:	ee2080e7          	jalr	-286(ra) # 80004284 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800053aa:	8762                	mv	a4,s8
    800053ac:	02092683          	lw	a3,32(s2)
    800053b0:	01598633          	add	a2,s3,s5
    800053b4:	4585                	li	a1,1
    800053b6:	01893503          	ld	a0,24(s2)
    800053ba:	fffff097          	auipc	ra,0xfffff
    800053be:	276080e7          	jalr	630(ra) # 80004630 <writei>
    800053c2:	84aa                	mv	s1,a0
    800053c4:	00a05763          	blez	a0,800053d2 <filewrite+0xc4>
        f->off += r;
    800053c8:	02092783          	lw	a5,32(s2)
    800053cc:	9fa9                	addw	a5,a5,a0
    800053ce:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800053d2:	01893503          	ld	a0,24(s2)
    800053d6:	fffff097          	auipc	ra,0xfffff
    800053da:	f70080e7          	jalr	-144(ra) # 80004346 <iunlock>
      end_op();
    800053de:	00000097          	auipc	ra,0x0
    800053e2:	8e8080e7          	jalr	-1816(ra) # 80004cc6 <end_op>

      if(r != n1){
    800053e6:	009c1f63          	bne	s8,s1,80005404 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800053ea:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800053ee:	0149db63          	bge	s3,s4,80005404 <filewrite+0xf6>
      int n1 = n - i;
    800053f2:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800053f6:	84be                	mv	s1,a5
    800053f8:	2781                	sext.w	a5,a5
    800053fa:	f8fb5ce3          	bge	s6,a5,80005392 <filewrite+0x84>
    800053fe:	84de                	mv	s1,s7
    80005400:	bf49                	j	80005392 <filewrite+0x84>
    int i = 0;
    80005402:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005404:	013a1f63          	bne	s4,s3,80005422 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005408:	8552                	mv	a0,s4
    8000540a:	60a6                	ld	ra,72(sp)
    8000540c:	6406                	ld	s0,64(sp)
    8000540e:	74e2                	ld	s1,56(sp)
    80005410:	7942                	ld	s2,48(sp)
    80005412:	79a2                	ld	s3,40(sp)
    80005414:	7a02                	ld	s4,32(sp)
    80005416:	6ae2                	ld	s5,24(sp)
    80005418:	6b42                	ld	s6,16(sp)
    8000541a:	6ba2                	ld	s7,8(sp)
    8000541c:	6c02                	ld	s8,0(sp)
    8000541e:	6161                	addi	sp,sp,80
    80005420:	8082                	ret
    ret = (i == n ? n : -1);
    80005422:	5a7d                	li	s4,-1
    80005424:	b7d5                	j	80005408 <filewrite+0xfa>
    panic("filewrite");
    80005426:	00004517          	auipc	a0,0x4
    8000542a:	44250513          	addi	a0,a0,1090 # 80009868 <syscalls+0x290>
    8000542e:	ffffb097          	auipc	ra,0xffffb
    80005432:	116080e7          	jalr	278(ra) # 80000544 <panic>
    return -1;
    80005436:	5a7d                	li	s4,-1
    80005438:	bfc1                	j	80005408 <filewrite+0xfa>
      return -1;
    8000543a:	5a7d                	li	s4,-1
    8000543c:	b7f1                	j	80005408 <filewrite+0xfa>
    8000543e:	5a7d                	li	s4,-1
    80005440:	b7e1                	j	80005408 <filewrite+0xfa>

0000000080005442 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005442:	7179                	addi	sp,sp,-48
    80005444:	f406                	sd	ra,40(sp)
    80005446:	f022                	sd	s0,32(sp)
    80005448:	ec26                	sd	s1,24(sp)
    8000544a:	e84a                	sd	s2,16(sp)
    8000544c:	e44e                	sd	s3,8(sp)
    8000544e:	e052                	sd	s4,0(sp)
    80005450:	1800                	addi	s0,sp,48
    80005452:	84aa                	mv	s1,a0
    80005454:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005456:	0005b023          	sd	zero,0(a1)
    8000545a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000545e:	00000097          	auipc	ra,0x0
    80005462:	bf8080e7          	jalr	-1032(ra) # 80005056 <filealloc>
    80005466:	e088                	sd	a0,0(s1)
    80005468:	c551                	beqz	a0,800054f4 <pipealloc+0xb2>
    8000546a:	00000097          	auipc	ra,0x0
    8000546e:	bec080e7          	jalr	-1044(ra) # 80005056 <filealloc>
    80005472:	00aa3023          	sd	a0,0(s4)
    80005476:	c92d                	beqz	a0,800054e8 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005478:	ffffb097          	auipc	ra,0xffffb
    8000547c:	682080e7          	jalr	1666(ra) # 80000afa <kalloc>
    80005480:	892a                	mv	s2,a0
    80005482:	c125                	beqz	a0,800054e2 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005484:	4985                	li	s3,1
    80005486:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000548a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000548e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005492:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005496:	00004597          	auipc	a1,0x4
    8000549a:	05a58593          	addi	a1,a1,90 # 800094f0 <states.1801+0x208>
    8000549e:	ffffb097          	auipc	ra,0xffffb
    800054a2:	6bc080e7          	jalr	1724(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    800054a6:	609c                	ld	a5,0(s1)
    800054a8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800054ac:	609c                	ld	a5,0(s1)
    800054ae:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800054b2:	609c                	ld	a5,0(s1)
    800054b4:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800054b8:	609c                	ld	a5,0(s1)
    800054ba:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800054be:	000a3783          	ld	a5,0(s4)
    800054c2:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800054c6:	000a3783          	ld	a5,0(s4)
    800054ca:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800054ce:	000a3783          	ld	a5,0(s4)
    800054d2:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800054d6:	000a3783          	ld	a5,0(s4)
    800054da:	0127b823          	sd	s2,16(a5)
  return 0;
    800054de:	4501                	li	a0,0
    800054e0:	a025                	j	80005508 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800054e2:	6088                	ld	a0,0(s1)
    800054e4:	e501                	bnez	a0,800054ec <pipealloc+0xaa>
    800054e6:	a039                	j	800054f4 <pipealloc+0xb2>
    800054e8:	6088                	ld	a0,0(s1)
    800054ea:	c51d                	beqz	a0,80005518 <pipealloc+0xd6>
    fileclose(*f0);
    800054ec:	00000097          	auipc	ra,0x0
    800054f0:	c26080e7          	jalr	-986(ra) # 80005112 <fileclose>
  if(*f1)
    800054f4:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800054f8:	557d                	li	a0,-1
  if(*f1)
    800054fa:	c799                	beqz	a5,80005508 <pipealloc+0xc6>
    fileclose(*f1);
    800054fc:	853e                	mv	a0,a5
    800054fe:	00000097          	auipc	ra,0x0
    80005502:	c14080e7          	jalr	-1004(ra) # 80005112 <fileclose>
  return -1;
    80005506:	557d                	li	a0,-1
}
    80005508:	70a2                	ld	ra,40(sp)
    8000550a:	7402                	ld	s0,32(sp)
    8000550c:	64e2                	ld	s1,24(sp)
    8000550e:	6942                	ld	s2,16(sp)
    80005510:	69a2                	ld	s3,8(sp)
    80005512:	6a02                	ld	s4,0(sp)
    80005514:	6145                	addi	sp,sp,48
    80005516:	8082                	ret
  return -1;
    80005518:	557d                	li	a0,-1
    8000551a:	b7fd                	j	80005508 <pipealloc+0xc6>

000000008000551c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000551c:	1101                	addi	sp,sp,-32
    8000551e:	ec06                	sd	ra,24(sp)
    80005520:	e822                	sd	s0,16(sp)
    80005522:	e426                	sd	s1,8(sp)
    80005524:	e04a                	sd	s2,0(sp)
    80005526:	1000                	addi	s0,sp,32
    80005528:	84aa                	mv	s1,a0
    8000552a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000552c:	ffffb097          	auipc	ra,0xffffb
    80005530:	6be080e7          	jalr	1726(ra) # 80000bea <acquire>
  if(writable){
    80005534:	02090d63          	beqz	s2,8000556e <pipeclose+0x52>
    pi->writeopen = 0;
    80005538:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000553c:	21848513          	addi	a0,s1,536
    80005540:	ffffd097          	auipc	ra,0xffffd
    80005544:	0b4080e7          	jalr	180(ra) # 800025f4 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005548:	2204b783          	ld	a5,544(s1)
    8000554c:	eb95                	bnez	a5,80005580 <pipeclose+0x64>
    release(&pi->lock);
    8000554e:	8526                	mv	a0,s1
    80005550:	ffffb097          	auipc	ra,0xffffb
    80005554:	74e080e7          	jalr	1870(ra) # 80000c9e <release>
    kfree((char*)pi);
    80005558:	8526                	mv	a0,s1
    8000555a:	ffffb097          	auipc	ra,0xffffb
    8000555e:	4a4080e7          	jalr	1188(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80005562:	60e2                	ld	ra,24(sp)
    80005564:	6442                	ld	s0,16(sp)
    80005566:	64a2                	ld	s1,8(sp)
    80005568:	6902                	ld	s2,0(sp)
    8000556a:	6105                	addi	sp,sp,32
    8000556c:	8082                	ret
    pi->readopen = 0;
    8000556e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005572:	21c48513          	addi	a0,s1,540
    80005576:	ffffd097          	auipc	ra,0xffffd
    8000557a:	07e080e7          	jalr	126(ra) # 800025f4 <wakeup>
    8000557e:	b7e9                	j	80005548 <pipeclose+0x2c>
    release(&pi->lock);
    80005580:	8526                	mv	a0,s1
    80005582:	ffffb097          	auipc	ra,0xffffb
    80005586:	71c080e7          	jalr	1820(ra) # 80000c9e <release>
}
    8000558a:	bfe1                	j	80005562 <pipeclose+0x46>

000000008000558c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000558c:	7159                	addi	sp,sp,-112
    8000558e:	f486                	sd	ra,104(sp)
    80005590:	f0a2                	sd	s0,96(sp)
    80005592:	eca6                	sd	s1,88(sp)
    80005594:	e8ca                	sd	s2,80(sp)
    80005596:	e4ce                	sd	s3,72(sp)
    80005598:	e0d2                	sd	s4,64(sp)
    8000559a:	fc56                	sd	s5,56(sp)
    8000559c:	f85a                	sd	s6,48(sp)
    8000559e:	f45e                	sd	s7,40(sp)
    800055a0:	f062                	sd	s8,32(sp)
    800055a2:	ec66                	sd	s9,24(sp)
    800055a4:	1880                	addi	s0,sp,112
    800055a6:	84aa                	mv	s1,a0
    800055a8:	8aae                	mv	s5,a1
    800055aa:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800055ac:	ffffc097          	auipc	ra,0xffffc
    800055b0:	61a080e7          	jalr	1562(ra) # 80001bc6 <myproc>
    800055b4:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800055b6:	8526                	mv	a0,s1
    800055b8:	ffffb097          	auipc	ra,0xffffb
    800055bc:	632080e7          	jalr	1586(ra) # 80000bea <acquire>
  while(i < n){
    800055c0:	0d405463          	blez	s4,80005688 <pipewrite+0xfc>
    800055c4:	8ba6                	mv	s7,s1
  int i = 0;
    800055c6:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800055c8:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800055ca:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800055ce:	21c48c13          	addi	s8,s1,540
    800055d2:	a08d                	j	80005634 <pipewrite+0xa8>
      release(&pi->lock);
    800055d4:	8526                	mv	a0,s1
    800055d6:	ffffb097          	auipc	ra,0xffffb
    800055da:	6c8080e7          	jalr	1736(ra) # 80000c9e <release>
      return -1;
    800055de:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800055e0:	854a                	mv	a0,s2
    800055e2:	70a6                	ld	ra,104(sp)
    800055e4:	7406                	ld	s0,96(sp)
    800055e6:	64e6                	ld	s1,88(sp)
    800055e8:	6946                	ld	s2,80(sp)
    800055ea:	69a6                	ld	s3,72(sp)
    800055ec:	6a06                	ld	s4,64(sp)
    800055ee:	7ae2                	ld	s5,56(sp)
    800055f0:	7b42                	ld	s6,48(sp)
    800055f2:	7ba2                	ld	s7,40(sp)
    800055f4:	7c02                	ld	s8,32(sp)
    800055f6:	6ce2                	ld	s9,24(sp)
    800055f8:	6165                	addi	sp,sp,112
    800055fa:	8082                	ret
      wakeup(&pi->nread);
    800055fc:	8566                	mv	a0,s9
    800055fe:	ffffd097          	auipc	ra,0xffffd
    80005602:	ff6080e7          	jalr	-10(ra) # 800025f4 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005606:	85de                	mv	a1,s7
    80005608:	8562                	mv	a0,s8
    8000560a:	ffffd097          	auipc	ra,0xffffd
    8000560e:	e3a080e7          	jalr	-454(ra) # 80002444 <sleep>
    80005612:	a839                	j	80005630 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005614:	21c4a783          	lw	a5,540(s1)
    80005618:	0017871b          	addiw	a4,a5,1
    8000561c:	20e4ae23          	sw	a4,540(s1)
    80005620:	1ff7f793          	andi	a5,a5,511
    80005624:	97a6                	add	a5,a5,s1
    80005626:	f9f44703          	lbu	a4,-97(s0)
    8000562a:	00e78c23          	sb	a4,24(a5)
      i++;
    8000562e:	2905                	addiw	s2,s2,1
  while(i < n){
    80005630:	05495063          	bge	s2,s4,80005670 <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80005634:	2204a783          	lw	a5,544(s1)
    80005638:	dfd1                	beqz	a5,800055d4 <pipewrite+0x48>
    8000563a:	854e                	mv	a0,s3
    8000563c:	ffffd097          	auipc	ra,0xffffd
    80005640:	208080e7          	jalr	520(ra) # 80002844 <killed>
    80005644:	f941                	bnez	a0,800055d4 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005646:	2184a783          	lw	a5,536(s1)
    8000564a:	21c4a703          	lw	a4,540(s1)
    8000564e:	2007879b          	addiw	a5,a5,512
    80005652:	faf705e3          	beq	a4,a5,800055fc <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005656:	4685                	li	a3,1
    80005658:	01590633          	add	a2,s2,s5
    8000565c:	f9f40593          	addi	a1,s0,-97
    80005660:	0509b503          	ld	a0,80(s3)
    80005664:	ffffc097          	auipc	ra,0xffffc
    80005668:	0ac080e7          	jalr	172(ra) # 80001710 <copyin>
    8000566c:	fb6514e3          	bne	a0,s6,80005614 <pipewrite+0x88>
  wakeup(&pi->nread);
    80005670:	21848513          	addi	a0,s1,536
    80005674:	ffffd097          	auipc	ra,0xffffd
    80005678:	f80080e7          	jalr	-128(ra) # 800025f4 <wakeup>
  release(&pi->lock);
    8000567c:	8526                	mv	a0,s1
    8000567e:	ffffb097          	auipc	ra,0xffffb
    80005682:	620080e7          	jalr	1568(ra) # 80000c9e <release>
  return i;
    80005686:	bfa9                	j	800055e0 <pipewrite+0x54>
  int i = 0;
    80005688:	4901                	li	s2,0
    8000568a:	b7dd                	j	80005670 <pipewrite+0xe4>

000000008000568c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000568c:	715d                	addi	sp,sp,-80
    8000568e:	e486                	sd	ra,72(sp)
    80005690:	e0a2                	sd	s0,64(sp)
    80005692:	fc26                	sd	s1,56(sp)
    80005694:	f84a                	sd	s2,48(sp)
    80005696:	f44e                	sd	s3,40(sp)
    80005698:	f052                	sd	s4,32(sp)
    8000569a:	ec56                	sd	s5,24(sp)
    8000569c:	e85a                	sd	s6,16(sp)
    8000569e:	0880                	addi	s0,sp,80
    800056a0:	84aa                	mv	s1,a0
    800056a2:	892e                	mv	s2,a1
    800056a4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800056a6:	ffffc097          	auipc	ra,0xffffc
    800056aa:	520080e7          	jalr	1312(ra) # 80001bc6 <myproc>
    800056ae:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800056b0:	8b26                	mv	s6,s1
    800056b2:	8526                	mv	a0,s1
    800056b4:	ffffb097          	auipc	ra,0xffffb
    800056b8:	536080e7          	jalr	1334(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800056bc:	2184a703          	lw	a4,536(s1)
    800056c0:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800056c4:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800056c8:	02f71763          	bne	a4,a5,800056f6 <piperead+0x6a>
    800056cc:	2244a783          	lw	a5,548(s1)
    800056d0:	c39d                	beqz	a5,800056f6 <piperead+0x6a>
    if(killed(pr)){
    800056d2:	8552                	mv	a0,s4
    800056d4:	ffffd097          	auipc	ra,0xffffd
    800056d8:	170080e7          	jalr	368(ra) # 80002844 <killed>
    800056dc:	e941                	bnez	a0,8000576c <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800056de:	85da                	mv	a1,s6
    800056e0:	854e                	mv	a0,s3
    800056e2:	ffffd097          	auipc	ra,0xffffd
    800056e6:	d62080e7          	jalr	-670(ra) # 80002444 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800056ea:	2184a703          	lw	a4,536(s1)
    800056ee:	21c4a783          	lw	a5,540(s1)
    800056f2:	fcf70de3          	beq	a4,a5,800056cc <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800056f6:	09505263          	blez	s5,8000577a <piperead+0xee>
    800056fa:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800056fc:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800056fe:	2184a783          	lw	a5,536(s1)
    80005702:	21c4a703          	lw	a4,540(s1)
    80005706:	02f70d63          	beq	a4,a5,80005740 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000570a:	0017871b          	addiw	a4,a5,1
    8000570e:	20e4ac23          	sw	a4,536(s1)
    80005712:	1ff7f793          	andi	a5,a5,511
    80005716:	97a6                	add	a5,a5,s1
    80005718:	0187c783          	lbu	a5,24(a5)
    8000571c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005720:	4685                	li	a3,1
    80005722:	fbf40613          	addi	a2,s0,-65
    80005726:	85ca                	mv	a1,s2
    80005728:	050a3503          	ld	a0,80(s4)
    8000572c:	ffffc097          	auipc	ra,0xffffc
    80005730:	f58080e7          	jalr	-168(ra) # 80001684 <copyout>
    80005734:	01650663          	beq	a0,s6,80005740 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005738:	2985                	addiw	s3,s3,1
    8000573a:	0905                	addi	s2,s2,1
    8000573c:	fd3a91e3          	bne	s5,s3,800056fe <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005740:	21c48513          	addi	a0,s1,540
    80005744:	ffffd097          	auipc	ra,0xffffd
    80005748:	eb0080e7          	jalr	-336(ra) # 800025f4 <wakeup>
  release(&pi->lock);
    8000574c:	8526                	mv	a0,s1
    8000574e:	ffffb097          	auipc	ra,0xffffb
    80005752:	550080e7          	jalr	1360(ra) # 80000c9e <release>
  return i;
}
    80005756:	854e                	mv	a0,s3
    80005758:	60a6                	ld	ra,72(sp)
    8000575a:	6406                	ld	s0,64(sp)
    8000575c:	74e2                	ld	s1,56(sp)
    8000575e:	7942                	ld	s2,48(sp)
    80005760:	79a2                	ld	s3,40(sp)
    80005762:	7a02                	ld	s4,32(sp)
    80005764:	6ae2                	ld	s5,24(sp)
    80005766:	6b42                	ld	s6,16(sp)
    80005768:	6161                	addi	sp,sp,80
    8000576a:	8082                	ret
      release(&pi->lock);
    8000576c:	8526                	mv	a0,s1
    8000576e:	ffffb097          	auipc	ra,0xffffb
    80005772:	530080e7          	jalr	1328(ra) # 80000c9e <release>
      return -1;
    80005776:	59fd                	li	s3,-1
    80005778:	bff9                	j	80005756 <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000577a:	4981                	li	s3,0
    8000577c:	b7d1                	j	80005740 <piperead+0xb4>

000000008000577e <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    8000577e:	1141                	addi	sp,sp,-16
    80005780:	e422                	sd	s0,8(sp)
    80005782:	0800                	addi	s0,sp,16
    80005784:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005786:	8905                	andi	a0,a0,1
    80005788:	c111                	beqz	a0,8000578c <flags2perm+0xe>
      perm = PTE_X;
    8000578a:	4521                	li	a0,8
    if(flags & 0x2)
    8000578c:	8b89                	andi	a5,a5,2
    8000578e:	c399                	beqz	a5,80005794 <flags2perm+0x16>
      perm |= PTE_W;
    80005790:	00456513          	ori	a0,a0,4
    return perm;
}
    80005794:	6422                	ld	s0,8(sp)
    80005796:	0141                	addi	sp,sp,16
    80005798:	8082                	ret

000000008000579a <exec>:

int
exec(char *path, char **argv)
{
    8000579a:	df010113          	addi	sp,sp,-528
    8000579e:	20113423          	sd	ra,520(sp)
    800057a2:	20813023          	sd	s0,512(sp)
    800057a6:	ffa6                	sd	s1,504(sp)
    800057a8:	fbca                	sd	s2,496(sp)
    800057aa:	f7ce                	sd	s3,488(sp)
    800057ac:	f3d2                	sd	s4,480(sp)
    800057ae:	efd6                	sd	s5,472(sp)
    800057b0:	ebda                	sd	s6,464(sp)
    800057b2:	e7de                	sd	s7,456(sp)
    800057b4:	e3e2                	sd	s8,448(sp)
    800057b6:	ff66                	sd	s9,440(sp)
    800057b8:	fb6a                	sd	s10,432(sp)
    800057ba:	f76e                	sd	s11,424(sp)
    800057bc:	0c00                	addi	s0,sp,528
    800057be:	84aa                	mv	s1,a0
    800057c0:	dea43c23          	sd	a0,-520(s0)
    800057c4:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800057c8:	ffffc097          	auipc	ra,0xffffc
    800057cc:	3fe080e7          	jalr	1022(ra) # 80001bc6 <myproc>
    800057d0:	892a                	mv	s2,a0

  begin_op();
    800057d2:	fffff097          	auipc	ra,0xfffff
    800057d6:	474080e7          	jalr	1140(ra) # 80004c46 <begin_op>

  if((ip = namei(path)) == 0){
    800057da:	8526                	mv	a0,s1
    800057dc:	fffff097          	auipc	ra,0xfffff
    800057e0:	24e080e7          	jalr	590(ra) # 80004a2a <namei>
    800057e4:	c92d                	beqz	a0,80005856 <exec+0xbc>
    800057e6:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800057e8:	fffff097          	auipc	ra,0xfffff
    800057ec:	a9c080e7          	jalr	-1380(ra) # 80004284 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800057f0:	04000713          	li	a4,64
    800057f4:	4681                	li	a3,0
    800057f6:	e5040613          	addi	a2,s0,-432
    800057fa:	4581                	li	a1,0
    800057fc:	8526                	mv	a0,s1
    800057fe:	fffff097          	auipc	ra,0xfffff
    80005802:	d3a080e7          	jalr	-710(ra) # 80004538 <readi>
    80005806:	04000793          	li	a5,64
    8000580a:	00f51a63          	bne	a0,a5,8000581e <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    8000580e:	e5042703          	lw	a4,-432(s0)
    80005812:	464c47b7          	lui	a5,0x464c4
    80005816:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000581a:	04f70463          	beq	a4,a5,80005862 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000581e:	8526                	mv	a0,s1
    80005820:	fffff097          	auipc	ra,0xfffff
    80005824:	cc6080e7          	jalr	-826(ra) # 800044e6 <iunlockput>
    end_op();
    80005828:	fffff097          	auipc	ra,0xfffff
    8000582c:	49e080e7          	jalr	1182(ra) # 80004cc6 <end_op>
  }
  return -1;
    80005830:	557d                	li	a0,-1
}
    80005832:	20813083          	ld	ra,520(sp)
    80005836:	20013403          	ld	s0,512(sp)
    8000583a:	74fe                	ld	s1,504(sp)
    8000583c:	795e                	ld	s2,496(sp)
    8000583e:	79be                	ld	s3,488(sp)
    80005840:	7a1e                	ld	s4,480(sp)
    80005842:	6afe                	ld	s5,472(sp)
    80005844:	6b5e                	ld	s6,464(sp)
    80005846:	6bbe                	ld	s7,456(sp)
    80005848:	6c1e                	ld	s8,448(sp)
    8000584a:	7cfa                	ld	s9,440(sp)
    8000584c:	7d5a                	ld	s10,432(sp)
    8000584e:	7dba                	ld	s11,424(sp)
    80005850:	21010113          	addi	sp,sp,528
    80005854:	8082                	ret
    end_op();
    80005856:	fffff097          	auipc	ra,0xfffff
    8000585a:	470080e7          	jalr	1136(ra) # 80004cc6 <end_op>
    return -1;
    8000585e:	557d                	li	a0,-1
    80005860:	bfc9                	j	80005832 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005862:	854a                	mv	a0,s2
    80005864:	ffffc097          	auipc	ra,0xffffc
    80005868:	426080e7          	jalr	1062(ra) # 80001c8a <proc_pagetable>
    8000586c:	8baa                	mv	s7,a0
    8000586e:	d945                	beqz	a0,8000581e <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005870:	e7042983          	lw	s3,-400(s0)
    80005874:	e8845783          	lhu	a5,-376(s0)
    80005878:	c7ad                	beqz	a5,800058e2 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000587a:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000587c:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    8000587e:	6c85                	lui	s9,0x1
    80005880:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005884:	def43823          	sd	a5,-528(s0)
    80005888:	ac0d                	j	80005aba <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000588a:	00004517          	auipc	a0,0x4
    8000588e:	fee50513          	addi	a0,a0,-18 # 80009878 <syscalls+0x2a0>
    80005892:	ffffb097          	auipc	ra,0xffffb
    80005896:	cb2080e7          	jalr	-846(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000589a:	8756                	mv	a4,s5
    8000589c:	012d86bb          	addw	a3,s11,s2
    800058a0:	4581                	li	a1,0
    800058a2:	8526                	mv	a0,s1
    800058a4:	fffff097          	auipc	ra,0xfffff
    800058a8:	c94080e7          	jalr	-876(ra) # 80004538 <readi>
    800058ac:	2501                	sext.w	a0,a0
    800058ae:	1aaa9a63          	bne	s5,a0,80005a62 <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    800058b2:	6785                	lui	a5,0x1
    800058b4:	0127893b          	addw	s2,a5,s2
    800058b8:	77fd                	lui	a5,0xfffff
    800058ba:	01478a3b          	addw	s4,a5,s4
    800058be:	1f897563          	bgeu	s2,s8,80005aa8 <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    800058c2:	02091593          	slli	a1,s2,0x20
    800058c6:	9181                	srli	a1,a1,0x20
    800058c8:	95ea                	add	a1,a1,s10
    800058ca:	855e                	mv	a0,s7
    800058cc:	ffffb097          	auipc	ra,0xffffb
    800058d0:	7ac080e7          	jalr	1964(ra) # 80001078 <walkaddr>
    800058d4:	862a                	mv	a2,a0
    if(pa == 0)
    800058d6:	d955                	beqz	a0,8000588a <exec+0xf0>
      n = PGSIZE;
    800058d8:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800058da:	fd9a70e3          	bgeu	s4,s9,8000589a <exec+0x100>
      n = sz - i;
    800058de:	8ad2                	mv	s5,s4
    800058e0:	bf6d                	j	8000589a <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800058e2:	4a01                	li	s4,0
  iunlockput(ip);
    800058e4:	8526                	mv	a0,s1
    800058e6:	fffff097          	auipc	ra,0xfffff
    800058ea:	c00080e7          	jalr	-1024(ra) # 800044e6 <iunlockput>
  end_op();
    800058ee:	fffff097          	auipc	ra,0xfffff
    800058f2:	3d8080e7          	jalr	984(ra) # 80004cc6 <end_op>
  p = myproc();
    800058f6:	ffffc097          	auipc	ra,0xffffc
    800058fa:	2d0080e7          	jalr	720(ra) # 80001bc6 <myproc>
    800058fe:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005900:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005904:	6785                	lui	a5,0x1
    80005906:	17fd                	addi	a5,a5,-1
    80005908:	9a3e                	add	s4,s4,a5
    8000590a:	757d                	lui	a0,0xfffff
    8000590c:	00aa77b3          	and	a5,s4,a0
    80005910:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005914:	4691                	li	a3,4
    80005916:	6609                	lui	a2,0x2
    80005918:	963e                	add	a2,a2,a5
    8000591a:	85be                	mv	a1,a5
    8000591c:	855e                	mv	a0,s7
    8000591e:	ffffc097          	auipc	ra,0xffffc
    80005922:	b0e080e7          	jalr	-1266(ra) # 8000142c <uvmalloc>
    80005926:	8b2a                	mv	s6,a0
  ip = 0;
    80005928:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000592a:	12050c63          	beqz	a0,80005a62 <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000592e:	75f9                	lui	a1,0xffffe
    80005930:	95aa                	add	a1,a1,a0
    80005932:	855e                	mv	a0,s7
    80005934:	ffffc097          	auipc	ra,0xffffc
    80005938:	d1e080e7          	jalr	-738(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    8000593c:	7c7d                	lui	s8,0xfffff
    8000593e:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005940:	e0043783          	ld	a5,-512(s0)
    80005944:	6388                	ld	a0,0(a5)
    80005946:	c535                	beqz	a0,800059b2 <exec+0x218>
    80005948:	e9040993          	addi	s3,s0,-368
    8000594c:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005950:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005952:	ffffb097          	auipc	ra,0xffffb
    80005956:	518080e7          	jalr	1304(ra) # 80000e6a <strlen>
    8000595a:	2505                	addiw	a0,a0,1
    8000595c:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005960:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005964:	13896663          	bltu	s2,s8,80005a90 <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005968:	e0043d83          	ld	s11,-512(s0)
    8000596c:	000dba03          	ld	s4,0(s11)
    80005970:	8552                	mv	a0,s4
    80005972:	ffffb097          	auipc	ra,0xffffb
    80005976:	4f8080e7          	jalr	1272(ra) # 80000e6a <strlen>
    8000597a:	0015069b          	addiw	a3,a0,1
    8000597e:	8652                	mv	a2,s4
    80005980:	85ca                	mv	a1,s2
    80005982:	855e                	mv	a0,s7
    80005984:	ffffc097          	auipc	ra,0xffffc
    80005988:	d00080e7          	jalr	-768(ra) # 80001684 <copyout>
    8000598c:	10054663          	bltz	a0,80005a98 <exec+0x2fe>
    ustack[argc] = sp;
    80005990:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005994:	0485                	addi	s1,s1,1
    80005996:	008d8793          	addi	a5,s11,8
    8000599a:	e0f43023          	sd	a5,-512(s0)
    8000599e:	008db503          	ld	a0,8(s11)
    800059a2:	c911                	beqz	a0,800059b6 <exec+0x21c>
    if(argc >= MAXARG)
    800059a4:	09a1                	addi	s3,s3,8
    800059a6:	fb3c96e3          	bne	s9,s3,80005952 <exec+0x1b8>
  sz = sz1;
    800059aa:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800059ae:	4481                	li	s1,0
    800059b0:	a84d                	j	80005a62 <exec+0x2c8>
  sp = sz;
    800059b2:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800059b4:	4481                	li	s1,0
  ustack[argc] = 0;
    800059b6:	00349793          	slli	a5,s1,0x3
    800059ba:	f9040713          	addi	a4,s0,-112
    800059be:	97ba                	add	a5,a5,a4
    800059c0:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800059c4:	00148693          	addi	a3,s1,1
    800059c8:	068e                	slli	a3,a3,0x3
    800059ca:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800059ce:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800059d2:	01897663          	bgeu	s2,s8,800059de <exec+0x244>
  sz = sz1;
    800059d6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800059da:	4481                	li	s1,0
    800059dc:	a059                	j	80005a62 <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800059de:	e9040613          	addi	a2,s0,-368
    800059e2:	85ca                	mv	a1,s2
    800059e4:	855e                	mv	a0,s7
    800059e6:	ffffc097          	auipc	ra,0xffffc
    800059ea:	c9e080e7          	jalr	-866(ra) # 80001684 <copyout>
    800059ee:	0a054963          	bltz	a0,80005aa0 <exec+0x306>
  p->trapframe->a1 = sp;
    800059f2:	058ab783          	ld	a5,88(s5)
    800059f6:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800059fa:	df843783          	ld	a5,-520(s0)
    800059fe:	0007c703          	lbu	a4,0(a5)
    80005a02:	cf11                	beqz	a4,80005a1e <exec+0x284>
    80005a04:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005a06:	02f00693          	li	a3,47
    80005a0a:	a039                	j	80005a18 <exec+0x27e>
      last = s+1;
    80005a0c:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005a10:	0785                	addi	a5,a5,1
    80005a12:	fff7c703          	lbu	a4,-1(a5)
    80005a16:	c701                	beqz	a4,80005a1e <exec+0x284>
    if(*s == '/')
    80005a18:	fed71ce3          	bne	a4,a3,80005a10 <exec+0x276>
    80005a1c:	bfc5                	j	80005a0c <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80005a1e:	4641                	li	a2,16
    80005a20:	df843583          	ld	a1,-520(s0)
    80005a24:	158a8513          	addi	a0,s5,344
    80005a28:	ffffb097          	auipc	ra,0xffffb
    80005a2c:	410080e7          	jalr	1040(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    80005a30:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005a34:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005a38:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005a3c:	058ab783          	ld	a5,88(s5)
    80005a40:	e6843703          	ld	a4,-408(s0)
    80005a44:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005a46:	058ab783          	ld	a5,88(s5)
    80005a4a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005a4e:	85ea                	mv	a1,s10
    80005a50:	ffffc097          	auipc	ra,0xffffc
    80005a54:	2d6080e7          	jalr	726(ra) # 80001d26 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005a58:	0004851b          	sext.w	a0,s1
    80005a5c:	bbd9                	j	80005832 <exec+0x98>
    80005a5e:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005a62:	e0843583          	ld	a1,-504(s0)
    80005a66:	855e                	mv	a0,s7
    80005a68:	ffffc097          	auipc	ra,0xffffc
    80005a6c:	2be080e7          	jalr	702(ra) # 80001d26 <proc_freepagetable>
  if(ip){
    80005a70:	da0497e3          	bnez	s1,8000581e <exec+0x84>
  return -1;
    80005a74:	557d                	li	a0,-1
    80005a76:	bb75                	j	80005832 <exec+0x98>
    80005a78:	e1443423          	sd	s4,-504(s0)
    80005a7c:	b7dd                	j	80005a62 <exec+0x2c8>
    80005a7e:	e1443423          	sd	s4,-504(s0)
    80005a82:	b7c5                	j	80005a62 <exec+0x2c8>
    80005a84:	e1443423          	sd	s4,-504(s0)
    80005a88:	bfe9                	j	80005a62 <exec+0x2c8>
    80005a8a:	e1443423          	sd	s4,-504(s0)
    80005a8e:	bfd1                	j	80005a62 <exec+0x2c8>
  sz = sz1;
    80005a90:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005a94:	4481                	li	s1,0
    80005a96:	b7f1                	j	80005a62 <exec+0x2c8>
  sz = sz1;
    80005a98:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005a9c:	4481                	li	s1,0
    80005a9e:	b7d1                	j	80005a62 <exec+0x2c8>
  sz = sz1;
    80005aa0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005aa4:	4481                	li	s1,0
    80005aa6:	bf75                	j	80005a62 <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005aa8:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005aac:	2b05                	addiw	s6,s6,1
    80005aae:	0389899b          	addiw	s3,s3,56
    80005ab2:	e8845783          	lhu	a5,-376(s0)
    80005ab6:	e2fb57e3          	bge	s6,a5,800058e4 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005aba:	2981                	sext.w	s3,s3
    80005abc:	03800713          	li	a4,56
    80005ac0:	86ce                	mv	a3,s3
    80005ac2:	e1840613          	addi	a2,s0,-488
    80005ac6:	4581                	li	a1,0
    80005ac8:	8526                	mv	a0,s1
    80005aca:	fffff097          	auipc	ra,0xfffff
    80005ace:	a6e080e7          	jalr	-1426(ra) # 80004538 <readi>
    80005ad2:	03800793          	li	a5,56
    80005ad6:	f8f514e3          	bne	a0,a5,80005a5e <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    80005ada:	e1842783          	lw	a5,-488(s0)
    80005ade:	4705                	li	a4,1
    80005ae0:	fce796e3          	bne	a5,a4,80005aac <exec+0x312>
    if(ph.memsz < ph.filesz)
    80005ae4:	e4043903          	ld	s2,-448(s0)
    80005ae8:	e3843783          	ld	a5,-456(s0)
    80005aec:	f8f966e3          	bltu	s2,a5,80005a78 <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005af0:	e2843783          	ld	a5,-472(s0)
    80005af4:	993e                	add	s2,s2,a5
    80005af6:	f8f964e3          	bltu	s2,a5,80005a7e <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    80005afa:	df043703          	ld	a4,-528(s0)
    80005afe:	8ff9                	and	a5,a5,a4
    80005b00:	f3d1                	bnez	a5,80005a84 <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005b02:	e1c42503          	lw	a0,-484(s0)
    80005b06:	00000097          	auipc	ra,0x0
    80005b0a:	c78080e7          	jalr	-904(ra) # 8000577e <flags2perm>
    80005b0e:	86aa                	mv	a3,a0
    80005b10:	864a                	mv	a2,s2
    80005b12:	85d2                	mv	a1,s4
    80005b14:	855e                	mv	a0,s7
    80005b16:	ffffc097          	auipc	ra,0xffffc
    80005b1a:	916080e7          	jalr	-1770(ra) # 8000142c <uvmalloc>
    80005b1e:	e0a43423          	sd	a0,-504(s0)
    80005b22:	d525                	beqz	a0,80005a8a <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005b24:	e2843d03          	ld	s10,-472(s0)
    80005b28:	e2042d83          	lw	s11,-480(s0)
    80005b2c:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005b30:	f60c0ce3          	beqz	s8,80005aa8 <exec+0x30e>
    80005b34:	8a62                	mv	s4,s8
    80005b36:	4901                	li	s2,0
    80005b38:	b369                	j	800058c2 <exec+0x128>

0000000080005b3a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005b3a:	7179                	addi	sp,sp,-48
    80005b3c:	f406                	sd	ra,40(sp)
    80005b3e:	f022                	sd	s0,32(sp)
    80005b40:	ec26                	sd	s1,24(sp)
    80005b42:	e84a                	sd	s2,16(sp)
    80005b44:	1800                	addi	s0,sp,48
    80005b46:	892e                	mv	s2,a1
    80005b48:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005b4a:	fdc40593          	addi	a1,s0,-36
    80005b4e:	ffffd097          	auipc	ra,0xffffd
    80005b52:	616080e7          	jalr	1558(ra) # 80003164 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005b56:	fdc42703          	lw	a4,-36(s0)
    80005b5a:	47bd                	li	a5,15
    80005b5c:	02e7eb63          	bltu	a5,a4,80005b92 <argfd+0x58>
    80005b60:	ffffc097          	auipc	ra,0xffffc
    80005b64:	066080e7          	jalr	102(ra) # 80001bc6 <myproc>
    80005b68:	fdc42703          	lw	a4,-36(s0)
    80005b6c:	01a70793          	addi	a5,a4,26
    80005b70:	078e                	slli	a5,a5,0x3
    80005b72:	953e                	add	a0,a0,a5
    80005b74:	611c                	ld	a5,0(a0)
    80005b76:	c385                	beqz	a5,80005b96 <argfd+0x5c>
    return -1;
  if(pfd)
    80005b78:	00090463          	beqz	s2,80005b80 <argfd+0x46>
    *pfd = fd;
    80005b7c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005b80:	4501                	li	a0,0
  if(pf)
    80005b82:	c091                	beqz	s1,80005b86 <argfd+0x4c>
    *pf = f;
    80005b84:	e09c                	sd	a5,0(s1)
}
    80005b86:	70a2                	ld	ra,40(sp)
    80005b88:	7402                	ld	s0,32(sp)
    80005b8a:	64e2                	ld	s1,24(sp)
    80005b8c:	6942                	ld	s2,16(sp)
    80005b8e:	6145                	addi	sp,sp,48
    80005b90:	8082                	ret
    return -1;
    80005b92:	557d                	li	a0,-1
    80005b94:	bfcd                	j	80005b86 <argfd+0x4c>
    80005b96:	557d                	li	a0,-1
    80005b98:	b7fd                	j	80005b86 <argfd+0x4c>

0000000080005b9a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005b9a:	1101                	addi	sp,sp,-32
    80005b9c:	ec06                	sd	ra,24(sp)
    80005b9e:	e822                	sd	s0,16(sp)
    80005ba0:	e426                	sd	s1,8(sp)
    80005ba2:	1000                	addi	s0,sp,32
    80005ba4:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005ba6:	ffffc097          	auipc	ra,0xffffc
    80005baa:	020080e7          	jalr	32(ra) # 80001bc6 <myproc>
    80005bae:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005bb0:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90c8>
    80005bb4:	4501                	li	a0,0
    80005bb6:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005bb8:	6398                	ld	a4,0(a5)
    80005bba:	cb19                	beqz	a4,80005bd0 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005bbc:	2505                	addiw	a0,a0,1
    80005bbe:	07a1                	addi	a5,a5,8
    80005bc0:	fed51ce3          	bne	a0,a3,80005bb8 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005bc4:	557d                	li	a0,-1
}
    80005bc6:	60e2                	ld	ra,24(sp)
    80005bc8:	6442                	ld	s0,16(sp)
    80005bca:	64a2                	ld	s1,8(sp)
    80005bcc:	6105                	addi	sp,sp,32
    80005bce:	8082                	ret
      p->ofile[fd] = f;
    80005bd0:	01a50793          	addi	a5,a0,26
    80005bd4:	078e                	slli	a5,a5,0x3
    80005bd6:	963e                	add	a2,a2,a5
    80005bd8:	e204                	sd	s1,0(a2)
      return fd;
    80005bda:	b7f5                	j	80005bc6 <fdalloc+0x2c>

0000000080005bdc <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005bdc:	715d                	addi	sp,sp,-80
    80005bde:	e486                	sd	ra,72(sp)
    80005be0:	e0a2                	sd	s0,64(sp)
    80005be2:	fc26                	sd	s1,56(sp)
    80005be4:	f84a                	sd	s2,48(sp)
    80005be6:	f44e                	sd	s3,40(sp)
    80005be8:	f052                	sd	s4,32(sp)
    80005bea:	ec56                	sd	s5,24(sp)
    80005bec:	e85a                	sd	s6,16(sp)
    80005bee:	0880                	addi	s0,sp,80
    80005bf0:	8b2e                	mv	s6,a1
    80005bf2:	89b2                	mv	s3,a2
    80005bf4:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005bf6:	fb040593          	addi	a1,s0,-80
    80005bfa:	fffff097          	auipc	ra,0xfffff
    80005bfe:	e4e080e7          	jalr	-434(ra) # 80004a48 <nameiparent>
    80005c02:	84aa                	mv	s1,a0
    80005c04:	16050063          	beqz	a0,80005d64 <create+0x188>
    return 0;

  ilock(dp);
    80005c08:	ffffe097          	auipc	ra,0xffffe
    80005c0c:	67c080e7          	jalr	1660(ra) # 80004284 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005c10:	4601                	li	a2,0
    80005c12:	fb040593          	addi	a1,s0,-80
    80005c16:	8526                	mv	a0,s1
    80005c18:	fffff097          	auipc	ra,0xfffff
    80005c1c:	b50080e7          	jalr	-1200(ra) # 80004768 <dirlookup>
    80005c20:	8aaa                	mv	s5,a0
    80005c22:	c931                	beqz	a0,80005c76 <create+0x9a>
    iunlockput(dp);
    80005c24:	8526                	mv	a0,s1
    80005c26:	fffff097          	auipc	ra,0xfffff
    80005c2a:	8c0080e7          	jalr	-1856(ra) # 800044e6 <iunlockput>
    ilock(ip);
    80005c2e:	8556                	mv	a0,s5
    80005c30:	ffffe097          	auipc	ra,0xffffe
    80005c34:	654080e7          	jalr	1620(ra) # 80004284 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005c38:	000b059b          	sext.w	a1,s6
    80005c3c:	4789                	li	a5,2
    80005c3e:	02f59563          	bne	a1,a5,80005c68 <create+0x8c>
    80005c42:	044ad783          	lhu	a5,68(s5)
    80005c46:	37f9                	addiw	a5,a5,-2
    80005c48:	17c2                	slli	a5,a5,0x30
    80005c4a:	93c1                	srli	a5,a5,0x30
    80005c4c:	4705                	li	a4,1
    80005c4e:	00f76d63          	bltu	a4,a5,80005c68 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005c52:	8556                	mv	a0,s5
    80005c54:	60a6                	ld	ra,72(sp)
    80005c56:	6406                	ld	s0,64(sp)
    80005c58:	74e2                	ld	s1,56(sp)
    80005c5a:	7942                	ld	s2,48(sp)
    80005c5c:	79a2                	ld	s3,40(sp)
    80005c5e:	7a02                	ld	s4,32(sp)
    80005c60:	6ae2                	ld	s5,24(sp)
    80005c62:	6b42                	ld	s6,16(sp)
    80005c64:	6161                	addi	sp,sp,80
    80005c66:	8082                	ret
    iunlockput(ip);
    80005c68:	8556                	mv	a0,s5
    80005c6a:	fffff097          	auipc	ra,0xfffff
    80005c6e:	87c080e7          	jalr	-1924(ra) # 800044e6 <iunlockput>
    return 0;
    80005c72:	4a81                	li	s5,0
    80005c74:	bff9                	j	80005c52 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005c76:	85da                	mv	a1,s6
    80005c78:	4088                	lw	a0,0(s1)
    80005c7a:	ffffe097          	auipc	ra,0xffffe
    80005c7e:	46e080e7          	jalr	1134(ra) # 800040e8 <ialloc>
    80005c82:	8a2a                	mv	s4,a0
    80005c84:	c921                	beqz	a0,80005cd4 <create+0xf8>
  ilock(ip);
    80005c86:	ffffe097          	auipc	ra,0xffffe
    80005c8a:	5fe080e7          	jalr	1534(ra) # 80004284 <ilock>
  ip->major = major;
    80005c8e:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005c92:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005c96:	4785                	li	a5,1
    80005c98:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    80005c9c:	8552                	mv	a0,s4
    80005c9e:	ffffe097          	auipc	ra,0xffffe
    80005ca2:	51c080e7          	jalr	1308(ra) # 800041ba <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005ca6:	000b059b          	sext.w	a1,s6
    80005caa:	4785                	li	a5,1
    80005cac:	02f58b63          	beq	a1,a5,80005ce2 <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    80005cb0:	004a2603          	lw	a2,4(s4)
    80005cb4:	fb040593          	addi	a1,s0,-80
    80005cb8:	8526                	mv	a0,s1
    80005cba:	fffff097          	auipc	ra,0xfffff
    80005cbe:	cbe080e7          	jalr	-834(ra) # 80004978 <dirlink>
    80005cc2:	06054f63          	bltz	a0,80005d40 <create+0x164>
  iunlockput(dp);
    80005cc6:	8526                	mv	a0,s1
    80005cc8:	fffff097          	auipc	ra,0xfffff
    80005ccc:	81e080e7          	jalr	-2018(ra) # 800044e6 <iunlockput>
  return ip;
    80005cd0:	8ad2                	mv	s5,s4
    80005cd2:	b741                	j	80005c52 <create+0x76>
    iunlockput(dp);
    80005cd4:	8526                	mv	a0,s1
    80005cd6:	fffff097          	auipc	ra,0xfffff
    80005cda:	810080e7          	jalr	-2032(ra) # 800044e6 <iunlockput>
    return 0;
    80005cde:	8ad2                	mv	s5,s4
    80005ce0:	bf8d                	j	80005c52 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005ce2:	004a2603          	lw	a2,4(s4)
    80005ce6:	00004597          	auipc	a1,0x4
    80005cea:	bb258593          	addi	a1,a1,-1102 # 80009898 <syscalls+0x2c0>
    80005cee:	8552                	mv	a0,s4
    80005cf0:	fffff097          	auipc	ra,0xfffff
    80005cf4:	c88080e7          	jalr	-888(ra) # 80004978 <dirlink>
    80005cf8:	04054463          	bltz	a0,80005d40 <create+0x164>
    80005cfc:	40d0                	lw	a2,4(s1)
    80005cfe:	00004597          	auipc	a1,0x4
    80005d02:	ba258593          	addi	a1,a1,-1118 # 800098a0 <syscalls+0x2c8>
    80005d06:	8552                	mv	a0,s4
    80005d08:	fffff097          	auipc	ra,0xfffff
    80005d0c:	c70080e7          	jalr	-912(ra) # 80004978 <dirlink>
    80005d10:	02054863          	bltz	a0,80005d40 <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    80005d14:	004a2603          	lw	a2,4(s4)
    80005d18:	fb040593          	addi	a1,s0,-80
    80005d1c:	8526                	mv	a0,s1
    80005d1e:	fffff097          	auipc	ra,0xfffff
    80005d22:	c5a080e7          	jalr	-934(ra) # 80004978 <dirlink>
    80005d26:	00054d63          	bltz	a0,80005d40 <create+0x164>
    dp->nlink++;  // for ".."
    80005d2a:	04a4d783          	lhu	a5,74(s1)
    80005d2e:	2785                	addiw	a5,a5,1
    80005d30:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005d34:	8526                	mv	a0,s1
    80005d36:	ffffe097          	auipc	ra,0xffffe
    80005d3a:	484080e7          	jalr	1156(ra) # 800041ba <iupdate>
    80005d3e:	b761                	j	80005cc6 <create+0xea>
  ip->nlink = 0;
    80005d40:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005d44:	8552                	mv	a0,s4
    80005d46:	ffffe097          	auipc	ra,0xffffe
    80005d4a:	474080e7          	jalr	1140(ra) # 800041ba <iupdate>
  iunlockput(ip);
    80005d4e:	8552                	mv	a0,s4
    80005d50:	ffffe097          	auipc	ra,0xffffe
    80005d54:	796080e7          	jalr	1942(ra) # 800044e6 <iunlockput>
  iunlockput(dp);
    80005d58:	8526                	mv	a0,s1
    80005d5a:	ffffe097          	auipc	ra,0xffffe
    80005d5e:	78c080e7          	jalr	1932(ra) # 800044e6 <iunlockput>
  return 0;
    80005d62:	bdc5                	j	80005c52 <create+0x76>
    return 0;
    80005d64:	8aaa                	mv	s5,a0
    80005d66:	b5f5                	j	80005c52 <create+0x76>

0000000080005d68 <sys_dup>:
{
    80005d68:	7179                	addi	sp,sp,-48
    80005d6a:	f406                	sd	ra,40(sp)
    80005d6c:	f022                	sd	s0,32(sp)
    80005d6e:	ec26                	sd	s1,24(sp)
    80005d70:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005d72:	fd840613          	addi	a2,s0,-40
    80005d76:	4581                	li	a1,0
    80005d78:	4501                	li	a0,0
    80005d7a:	00000097          	auipc	ra,0x0
    80005d7e:	dc0080e7          	jalr	-576(ra) # 80005b3a <argfd>
    return -1;
    80005d82:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005d84:	02054363          	bltz	a0,80005daa <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005d88:	fd843503          	ld	a0,-40(s0)
    80005d8c:	00000097          	auipc	ra,0x0
    80005d90:	e0e080e7          	jalr	-498(ra) # 80005b9a <fdalloc>
    80005d94:	84aa                	mv	s1,a0
    return -1;
    80005d96:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005d98:	00054963          	bltz	a0,80005daa <sys_dup+0x42>
  filedup(f);
    80005d9c:	fd843503          	ld	a0,-40(s0)
    80005da0:	fffff097          	auipc	ra,0xfffff
    80005da4:	320080e7          	jalr	800(ra) # 800050c0 <filedup>
  return fd;
    80005da8:	87a6                	mv	a5,s1
}
    80005daa:	853e                	mv	a0,a5
    80005dac:	70a2                	ld	ra,40(sp)
    80005dae:	7402                	ld	s0,32(sp)
    80005db0:	64e2                	ld	s1,24(sp)
    80005db2:	6145                	addi	sp,sp,48
    80005db4:	8082                	ret

0000000080005db6 <sys_read>:
{
    80005db6:	7179                	addi	sp,sp,-48
    80005db8:	f406                	sd	ra,40(sp)
    80005dba:	f022                	sd	s0,32(sp)
    80005dbc:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005dbe:	fd840593          	addi	a1,s0,-40
    80005dc2:	4505                	li	a0,1
    80005dc4:	ffffd097          	auipc	ra,0xffffd
    80005dc8:	3c0080e7          	jalr	960(ra) # 80003184 <argaddr>
  argint(2, &n);
    80005dcc:	fe440593          	addi	a1,s0,-28
    80005dd0:	4509                	li	a0,2
    80005dd2:	ffffd097          	auipc	ra,0xffffd
    80005dd6:	392080e7          	jalr	914(ra) # 80003164 <argint>
  if(argfd(0, 0, &f) < 0)
    80005dda:	fe840613          	addi	a2,s0,-24
    80005dde:	4581                	li	a1,0
    80005de0:	4501                	li	a0,0
    80005de2:	00000097          	auipc	ra,0x0
    80005de6:	d58080e7          	jalr	-680(ra) # 80005b3a <argfd>
    80005dea:	87aa                	mv	a5,a0
    return -1;
    80005dec:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005dee:	0007cc63          	bltz	a5,80005e06 <sys_read+0x50>
  return fileread(f, p, n);
    80005df2:	fe442603          	lw	a2,-28(s0)
    80005df6:	fd843583          	ld	a1,-40(s0)
    80005dfa:	fe843503          	ld	a0,-24(s0)
    80005dfe:	fffff097          	auipc	ra,0xfffff
    80005e02:	44e080e7          	jalr	1102(ra) # 8000524c <fileread>
}
    80005e06:	70a2                	ld	ra,40(sp)
    80005e08:	7402                	ld	s0,32(sp)
    80005e0a:	6145                	addi	sp,sp,48
    80005e0c:	8082                	ret

0000000080005e0e <sys_write>:
{
    80005e0e:	7179                	addi	sp,sp,-48
    80005e10:	f406                	sd	ra,40(sp)
    80005e12:	f022                	sd	s0,32(sp)
    80005e14:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005e16:	fd840593          	addi	a1,s0,-40
    80005e1a:	4505                	li	a0,1
    80005e1c:	ffffd097          	auipc	ra,0xffffd
    80005e20:	368080e7          	jalr	872(ra) # 80003184 <argaddr>
  argint(2, &n);
    80005e24:	fe440593          	addi	a1,s0,-28
    80005e28:	4509                	li	a0,2
    80005e2a:	ffffd097          	auipc	ra,0xffffd
    80005e2e:	33a080e7          	jalr	826(ra) # 80003164 <argint>
  if(argfd(0, 0, &f) < 0)
    80005e32:	fe840613          	addi	a2,s0,-24
    80005e36:	4581                	li	a1,0
    80005e38:	4501                	li	a0,0
    80005e3a:	00000097          	auipc	ra,0x0
    80005e3e:	d00080e7          	jalr	-768(ra) # 80005b3a <argfd>
    80005e42:	87aa                	mv	a5,a0
    return -1;
    80005e44:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005e46:	0007cc63          	bltz	a5,80005e5e <sys_write+0x50>
  return filewrite(f, p, n);
    80005e4a:	fe442603          	lw	a2,-28(s0)
    80005e4e:	fd843583          	ld	a1,-40(s0)
    80005e52:	fe843503          	ld	a0,-24(s0)
    80005e56:	fffff097          	auipc	ra,0xfffff
    80005e5a:	4b8080e7          	jalr	1208(ra) # 8000530e <filewrite>
}
    80005e5e:	70a2                	ld	ra,40(sp)
    80005e60:	7402                	ld	s0,32(sp)
    80005e62:	6145                	addi	sp,sp,48
    80005e64:	8082                	ret

0000000080005e66 <sys_close>:
{
    80005e66:	1101                	addi	sp,sp,-32
    80005e68:	ec06                	sd	ra,24(sp)
    80005e6a:	e822                	sd	s0,16(sp)
    80005e6c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005e6e:	fe040613          	addi	a2,s0,-32
    80005e72:	fec40593          	addi	a1,s0,-20
    80005e76:	4501                	li	a0,0
    80005e78:	00000097          	auipc	ra,0x0
    80005e7c:	cc2080e7          	jalr	-830(ra) # 80005b3a <argfd>
    return -1;
    80005e80:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005e82:	02054463          	bltz	a0,80005eaa <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005e86:	ffffc097          	auipc	ra,0xffffc
    80005e8a:	d40080e7          	jalr	-704(ra) # 80001bc6 <myproc>
    80005e8e:	fec42783          	lw	a5,-20(s0)
    80005e92:	07e9                	addi	a5,a5,26
    80005e94:	078e                	slli	a5,a5,0x3
    80005e96:	97aa                	add	a5,a5,a0
    80005e98:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005e9c:	fe043503          	ld	a0,-32(s0)
    80005ea0:	fffff097          	auipc	ra,0xfffff
    80005ea4:	272080e7          	jalr	626(ra) # 80005112 <fileclose>
  return 0;
    80005ea8:	4781                	li	a5,0
}
    80005eaa:	853e                	mv	a0,a5
    80005eac:	60e2                	ld	ra,24(sp)
    80005eae:	6442                	ld	s0,16(sp)
    80005eb0:	6105                	addi	sp,sp,32
    80005eb2:	8082                	ret

0000000080005eb4 <sys_fstat>:
{
    80005eb4:	1101                	addi	sp,sp,-32
    80005eb6:	ec06                	sd	ra,24(sp)
    80005eb8:	e822                	sd	s0,16(sp)
    80005eba:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005ebc:	fe040593          	addi	a1,s0,-32
    80005ec0:	4505                	li	a0,1
    80005ec2:	ffffd097          	auipc	ra,0xffffd
    80005ec6:	2c2080e7          	jalr	706(ra) # 80003184 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005eca:	fe840613          	addi	a2,s0,-24
    80005ece:	4581                	li	a1,0
    80005ed0:	4501                	li	a0,0
    80005ed2:	00000097          	auipc	ra,0x0
    80005ed6:	c68080e7          	jalr	-920(ra) # 80005b3a <argfd>
    80005eda:	87aa                	mv	a5,a0
    return -1;
    80005edc:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005ede:	0007ca63          	bltz	a5,80005ef2 <sys_fstat+0x3e>
  return filestat(f, st);
    80005ee2:	fe043583          	ld	a1,-32(s0)
    80005ee6:	fe843503          	ld	a0,-24(s0)
    80005eea:	fffff097          	auipc	ra,0xfffff
    80005eee:	2f0080e7          	jalr	752(ra) # 800051da <filestat>
}
    80005ef2:	60e2                	ld	ra,24(sp)
    80005ef4:	6442                	ld	s0,16(sp)
    80005ef6:	6105                	addi	sp,sp,32
    80005ef8:	8082                	ret

0000000080005efa <sys_link>:
{
    80005efa:	7169                	addi	sp,sp,-304
    80005efc:	f606                	sd	ra,296(sp)
    80005efe:	f222                	sd	s0,288(sp)
    80005f00:	ee26                	sd	s1,280(sp)
    80005f02:	ea4a                	sd	s2,272(sp)
    80005f04:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005f06:	08000613          	li	a2,128
    80005f0a:	ed040593          	addi	a1,s0,-304
    80005f0e:	4501                	li	a0,0
    80005f10:	ffffd097          	auipc	ra,0xffffd
    80005f14:	294080e7          	jalr	660(ra) # 800031a4 <argstr>
    return -1;
    80005f18:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005f1a:	10054e63          	bltz	a0,80006036 <sys_link+0x13c>
    80005f1e:	08000613          	li	a2,128
    80005f22:	f5040593          	addi	a1,s0,-176
    80005f26:	4505                	li	a0,1
    80005f28:	ffffd097          	auipc	ra,0xffffd
    80005f2c:	27c080e7          	jalr	636(ra) # 800031a4 <argstr>
    return -1;
    80005f30:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005f32:	10054263          	bltz	a0,80006036 <sys_link+0x13c>
  begin_op();
    80005f36:	fffff097          	auipc	ra,0xfffff
    80005f3a:	d10080e7          	jalr	-752(ra) # 80004c46 <begin_op>
  if((ip = namei(old)) == 0){
    80005f3e:	ed040513          	addi	a0,s0,-304
    80005f42:	fffff097          	auipc	ra,0xfffff
    80005f46:	ae8080e7          	jalr	-1304(ra) # 80004a2a <namei>
    80005f4a:	84aa                	mv	s1,a0
    80005f4c:	c551                	beqz	a0,80005fd8 <sys_link+0xde>
  ilock(ip);
    80005f4e:	ffffe097          	auipc	ra,0xffffe
    80005f52:	336080e7          	jalr	822(ra) # 80004284 <ilock>
  if(ip->type == T_DIR){
    80005f56:	04449703          	lh	a4,68(s1)
    80005f5a:	4785                	li	a5,1
    80005f5c:	08f70463          	beq	a4,a5,80005fe4 <sys_link+0xea>
  ip->nlink++;
    80005f60:	04a4d783          	lhu	a5,74(s1)
    80005f64:	2785                	addiw	a5,a5,1
    80005f66:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005f6a:	8526                	mv	a0,s1
    80005f6c:	ffffe097          	auipc	ra,0xffffe
    80005f70:	24e080e7          	jalr	590(ra) # 800041ba <iupdate>
  iunlock(ip);
    80005f74:	8526                	mv	a0,s1
    80005f76:	ffffe097          	auipc	ra,0xffffe
    80005f7a:	3d0080e7          	jalr	976(ra) # 80004346 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005f7e:	fd040593          	addi	a1,s0,-48
    80005f82:	f5040513          	addi	a0,s0,-176
    80005f86:	fffff097          	auipc	ra,0xfffff
    80005f8a:	ac2080e7          	jalr	-1342(ra) # 80004a48 <nameiparent>
    80005f8e:	892a                	mv	s2,a0
    80005f90:	c935                	beqz	a0,80006004 <sys_link+0x10a>
  ilock(dp);
    80005f92:	ffffe097          	auipc	ra,0xffffe
    80005f96:	2f2080e7          	jalr	754(ra) # 80004284 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005f9a:	00092703          	lw	a4,0(s2)
    80005f9e:	409c                	lw	a5,0(s1)
    80005fa0:	04f71d63          	bne	a4,a5,80005ffa <sys_link+0x100>
    80005fa4:	40d0                	lw	a2,4(s1)
    80005fa6:	fd040593          	addi	a1,s0,-48
    80005faa:	854a                	mv	a0,s2
    80005fac:	fffff097          	auipc	ra,0xfffff
    80005fb0:	9cc080e7          	jalr	-1588(ra) # 80004978 <dirlink>
    80005fb4:	04054363          	bltz	a0,80005ffa <sys_link+0x100>
  iunlockput(dp);
    80005fb8:	854a                	mv	a0,s2
    80005fba:	ffffe097          	auipc	ra,0xffffe
    80005fbe:	52c080e7          	jalr	1324(ra) # 800044e6 <iunlockput>
  iput(ip);
    80005fc2:	8526                	mv	a0,s1
    80005fc4:	ffffe097          	auipc	ra,0xffffe
    80005fc8:	47a080e7          	jalr	1146(ra) # 8000443e <iput>
  end_op();
    80005fcc:	fffff097          	auipc	ra,0xfffff
    80005fd0:	cfa080e7          	jalr	-774(ra) # 80004cc6 <end_op>
  return 0;
    80005fd4:	4781                	li	a5,0
    80005fd6:	a085                	j	80006036 <sys_link+0x13c>
    end_op();
    80005fd8:	fffff097          	auipc	ra,0xfffff
    80005fdc:	cee080e7          	jalr	-786(ra) # 80004cc6 <end_op>
    return -1;
    80005fe0:	57fd                	li	a5,-1
    80005fe2:	a891                	j	80006036 <sys_link+0x13c>
    iunlockput(ip);
    80005fe4:	8526                	mv	a0,s1
    80005fe6:	ffffe097          	auipc	ra,0xffffe
    80005fea:	500080e7          	jalr	1280(ra) # 800044e6 <iunlockput>
    end_op();
    80005fee:	fffff097          	auipc	ra,0xfffff
    80005ff2:	cd8080e7          	jalr	-808(ra) # 80004cc6 <end_op>
    return -1;
    80005ff6:	57fd                	li	a5,-1
    80005ff8:	a83d                	j	80006036 <sys_link+0x13c>
    iunlockput(dp);
    80005ffa:	854a                	mv	a0,s2
    80005ffc:	ffffe097          	auipc	ra,0xffffe
    80006000:	4ea080e7          	jalr	1258(ra) # 800044e6 <iunlockput>
  ilock(ip);
    80006004:	8526                	mv	a0,s1
    80006006:	ffffe097          	auipc	ra,0xffffe
    8000600a:	27e080e7          	jalr	638(ra) # 80004284 <ilock>
  ip->nlink--;
    8000600e:	04a4d783          	lhu	a5,74(s1)
    80006012:	37fd                	addiw	a5,a5,-1
    80006014:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006018:	8526                	mv	a0,s1
    8000601a:	ffffe097          	auipc	ra,0xffffe
    8000601e:	1a0080e7          	jalr	416(ra) # 800041ba <iupdate>
  iunlockput(ip);
    80006022:	8526                	mv	a0,s1
    80006024:	ffffe097          	auipc	ra,0xffffe
    80006028:	4c2080e7          	jalr	1218(ra) # 800044e6 <iunlockput>
  end_op();
    8000602c:	fffff097          	auipc	ra,0xfffff
    80006030:	c9a080e7          	jalr	-870(ra) # 80004cc6 <end_op>
  return -1;
    80006034:	57fd                	li	a5,-1
}
    80006036:	853e                	mv	a0,a5
    80006038:	70b2                	ld	ra,296(sp)
    8000603a:	7412                	ld	s0,288(sp)
    8000603c:	64f2                	ld	s1,280(sp)
    8000603e:	6952                	ld	s2,272(sp)
    80006040:	6155                	addi	sp,sp,304
    80006042:	8082                	ret

0000000080006044 <sys_unlink>:
{
    80006044:	7151                	addi	sp,sp,-240
    80006046:	f586                	sd	ra,232(sp)
    80006048:	f1a2                	sd	s0,224(sp)
    8000604a:	eda6                	sd	s1,216(sp)
    8000604c:	e9ca                	sd	s2,208(sp)
    8000604e:	e5ce                	sd	s3,200(sp)
    80006050:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80006052:	08000613          	li	a2,128
    80006056:	f3040593          	addi	a1,s0,-208
    8000605a:	4501                	li	a0,0
    8000605c:	ffffd097          	auipc	ra,0xffffd
    80006060:	148080e7          	jalr	328(ra) # 800031a4 <argstr>
    80006064:	18054163          	bltz	a0,800061e6 <sys_unlink+0x1a2>
  begin_op();
    80006068:	fffff097          	auipc	ra,0xfffff
    8000606c:	bde080e7          	jalr	-1058(ra) # 80004c46 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80006070:	fb040593          	addi	a1,s0,-80
    80006074:	f3040513          	addi	a0,s0,-208
    80006078:	fffff097          	auipc	ra,0xfffff
    8000607c:	9d0080e7          	jalr	-1584(ra) # 80004a48 <nameiparent>
    80006080:	84aa                	mv	s1,a0
    80006082:	c979                	beqz	a0,80006158 <sys_unlink+0x114>
  ilock(dp);
    80006084:	ffffe097          	auipc	ra,0xffffe
    80006088:	200080e7          	jalr	512(ra) # 80004284 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000608c:	00004597          	auipc	a1,0x4
    80006090:	80c58593          	addi	a1,a1,-2036 # 80009898 <syscalls+0x2c0>
    80006094:	fb040513          	addi	a0,s0,-80
    80006098:	ffffe097          	auipc	ra,0xffffe
    8000609c:	6b6080e7          	jalr	1718(ra) # 8000474e <namecmp>
    800060a0:	14050a63          	beqz	a0,800061f4 <sys_unlink+0x1b0>
    800060a4:	00003597          	auipc	a1,0x3
    800060a8:	7fc58593          	addi	a1,a1,2044 # 800098a0 <syscalls+0x2c8>
    800060ac:	fb040513          	addi	a0,s0,-80
    800060b0:	ffffe097          	auipc	ra,0xffffe
    800060b4:	69e080e7          	jalr	1694(ra) # 8000474e <namecmp>
    800060b8:	12050e63          	beqz	a0,800061f4 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800060bc:	f2c40613          	addi	a2,s0,-212
    800060c0:	fb040593          	addi	a1,s0,-80
    800060c4:	8526                	mv	a0,s1
    800060c6:	ffffe097          	auipc	ra,0xffffe
    800060ca:	6a2080e7          	jalr	1698(ra) # 80004768 <dirlookup>
    800060ce:	892a                	mv	s2,a0
    800060d0:	12050263          	beqz	a0,800061f4 <sys_unlink+0x1b0>
  ilock(ip);
    800060d4:	ffffe097          	auipc	ra,0xffffe
    800060d8:	1b0080e7          	jalr	432(ra) # 80004284 <ilock>
  if(ip->nlink < 1)
    800060dc:	04a91783          	lh	a5,74(s2)
    800060e0:	08f05263          	blez	a5,80006164 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800060e4:	04491703          	lh	a4,68(s2)
    800060e8:	4785                	li	a5,1
    800060ea:	08f70563          	beq	a4,a5,80006174 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800060ee:	4641                	li	a2,16
    800060f0:	4581                	li	a1,0
    800060f2:	fc040513          	addi	a0,s0,-64
    800060f6:	ffffb097          	auipc	ra,0xffffb
    800060fa:	bf0080e7          	jalr	-1040(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800060fe:	4741                	li	a4,16
    80006100:	f2c42683          	lw	a3,-212(s0)
    80006104:	fc040613          	addi	a2,s0,-64
    80006108:	4581                	li	a1,0
    8000610a:	8526                	mv	a0,s1
    8000610c:	ffffe097          	auipc	ra,0xffffe
    80006110:	524080e7          	jalr	1316(ra) # 80004630 <writei>
    80006114:	47c1                	li	a5,16
    80006116:	0af51563          	bne	a0,a5,800061c0 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000611a:	04491703          	lh	a4,68(s2)
    8000611e:	4785                	li	a5,1
    80006120:	0af70863          	beq	a4,a5,800061d0 <sys_unlink+0x18c>
  iunlockput(dp);
    80006124:	8526                	mv	a0,s1
    80006126:	ffffe097          	auipc	ra,0xffffe
    8000612a:	3c0080e7          	jalr	960(ra) # 800044e6 <iunlockput>
  ip->nlink--;
    8000612e:	04a95783          	lhu	a5,74(s2)
    80006132:	37fd                	addiw	a5,a5,-1
    80006134:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80006138:	854a                	mv	a0,s2
    8000613a:	ffffe097          	auipc	ra,0xffffe
    8000613e:	080080e7          	jalr	128(ra) # 800041ba <iupdate>
  iunlockput(ip);
    80006142:	854a                	mv	a0,s2
    80006144:	ffffe097          	auipc	ra,0xffffe
    80006148:	3a2080e7          	jalr	930(ra) # 800044e6 <iunlockput>
  end_op();
    8000614c:	fffff097          	auipc	ra,0xfffff
    80006150:	b7a080e7          	jalr	-1158(ra) # 80004cc6 <end_op>
  return 0;
    80006154:	4501                	li	a0,0
    80006156:	a84d                	j	80006208 <sys_unlink+0x1c4>
    end_op();
    80006158:	fffff097          	auipc	ra,0xfffff
    8000615c:	b6e080e7          	jalr	-1170(ra) # 80004cc6 <end_op>
    return -1;
    80006160:	557d                	li	a0,-1
    80006162:	a05d                	j	80006208 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80006164:	00003517          	auipc	a0,0x3
    80006168:	74450513          	addi	a0,a0,1860 # 800098a8 <syscalls+0x2d0>
    8000616c:	ffffa097          	auipc	ra,0xffffa
    80006170:	3d8080e7          	jalr	984(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006174:	04c92703          	lw	a4,76(s2)
    80006178:	02000793          	li	a5,32
    8000617c:	f6e7f9e3          	bgeu	a5,a4,800060ee <sys_unlink+0xaa>
    80006180:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006184:	4741                	li	a4,16
    80006186:	86ce                	mv	a3,s3
    80006188:	f1840613          	addi	a2,s0,-232
    8000618c:	4581                	li	a1,0
    8000618e:	854a                	mv	a0,s2
    80006190:	ffffe097          	auipc	ra,0xffffe
    80006194:	3a8080e7          	jalr	936(ra) # 80004538 <readi>
    80006198:	47c1                	li	a5,16
    8000619a:	00f51b63          	bne	a0,a5,800061b0 <sys_unlink+0x16c>
    if(de.inum != 0)
    8000619e:	f1845783          	lhu	a5,-232(s0)
    800061a2:	e7a1                	bnez	a5,800061ea <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800061a4:	29c1                	addiw	s3,s3,16
    800061a6:	04c92783          	lw	a5,76(s2)
    800061aa:	fcf9ede3          	bltu	s3,a5,80006184 <sys_unlink+0x140>
    800061ae:	b781                	j	800060ee <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800061b0:	00003517          	auipc	a0,0x3
    800061b4:	71050513          	addi	a0,a0,1808 # 800098c0 <syscalls+0x2e8>
    800061b8:	ffffa097          	auipc	ra,0xffffa
    800061bc:	38c080e7          	jalr	908(ra) # 80000544 <panic>
    panic("unlink: writei");
    800061c0:	00003517          	auipc	a0,0x3
    800061c4:	71850513          	addi	a0,a0,1816 # 800098d8 <syscalls+0x300>
    800061c8:	ffffa097          	auipc	ra,0xffffa
    800061cc:	37c080e7          	jalr	892(ra) # 80000544 <panic>
    dp->nlink--;
    800061d0:	04a4d783          	lhu	a5,74(s1)
    800061d4:	37fd                	addiw	a5,a5,-1
    800061d6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800061da:	8526                	mv	a0,s1
    800061dc:	ffffe097          	auipc	ra,0xffffe
    800061e0:	fde080e7          	jalr	-34(ra) # 800041ba <iupdate>
    800061e4:	b781                	j	80006124 <sys_unlink+0xe0>
    return -1;
    800061e6:	557d                	li	a0,-1
    800061e8:	a005                	j	80006208 <sys_unlink+0x1c4>
    iunlockput(ip);
    800061ea:	854a                	mv	a0,s2
    800061ec:	ffffe097          	auipc	ra,0xffffe
    800061f0:	2fa080e7          	jalr	762(ra) # 800044e6 <iunlockput>
  iunlockput(dp);
    800061f4:	8526                	mv	a0,s1
    800061f6:	ffffe097          	auipc	ra,0xffffe
    800061fa:	2f0080e7          	jalr	752(ra) # 800044e6 <iunlockput>
  end_op();
    800061fe:	fffff097          	auipc	ra,0xfffff
    80006202:	ac8080e7          	jalr	-1336(ra) # 80004cc6 <end_op>
  return -1;
    80006206:	557d                	li	a0,-1
}
    80006208:	70ae                	ld	ra,232(sp)
    8000620a:	740e                	ld	s0,224(sp)
    8000620c:	64ee                	ld	s1,216(sp)
    8000620e:	694e                	ld	s2,208(sp)
    80006210:	69ae                	ld	s3,200(sp)
    80006212:	616d                	addi	sp,sp,240
    80006214:	8082                	ret

0000000080006216 <sys_open>:

uint64
sys_open(void)
{
    80006216:	7131                	addi	sp,sp,-192
    80006218:	fd06                	sd	ra,184(sp)
    8000621a:	f922                	sd	s0,176(sp)
    8000621c:	f526                	sd	s1,168(sp)
    8000621e:	f14a                	sd	s2,160(sp)
    80006220:	ed4e                	sd	s3,152(sp)
    80006222:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80006224:	f4c40593          	addi	a1,s0,-180
    80006228:	4505                	li	a0,1
    8000622a:	ffffd097          	auipc	ra,0xffffd
    8000622e:	f3a080e7          	jalr	-198(ra) # 80003164 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80006232:	08000613          	li	a2,128
    80006236:	f5040593          	addi	a1,s0,-176
    8000623a:	4501                	li	a0,0
    8000623c:	ffffd097          	auipc	ra,0xffffd
    80006240:	f68080e7          	jalr	-152(ra) # 800031a4 <argstr>
    80006244:	87aa                	mv	a5,a0
    return -1;
    80006246:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80006248:	0a07c963          	bltz	a5,800062fa <sys_open+0xe4>

  begin_op();
    8000624c:	fffff097          	auipc	ra,0xfffff
    80006250:	9fa080e7          	jalr	-1542(ra) # 80004c46 <begin_op>

  if(omode & O_CREATE){
    80006254:	f4c42783          	lw	a5,-180(s0)
    80006258:	2007f793          	andi	a5,a5,512
    8000625c:	cfc5                	beqz	a5,80006314 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000625e:	4681                	li	a3,0
    80006260:	4601                	li	a2,0
    80006262:	4589                	li	a1,2
    80006264:	f5040513          	addi	a0,s0,-176
    80006268:	00000097          	auipc	ra,0x0
    8000626c:	974080e7          	jalr	-1676(ra) # 80005bdc <create>
    80006270:	84aa                	mv	s1,a0
    if(ip == 0){
    80006272:	c959                	beqz	a0,80006308 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006274:	04449703          	lh	a4,68(s1)
    80006278:	478d                	li	a5,3
    8000627a:	00f71763          	bne	a4,a5,80006288 <sys_open+0x72>
    8000627e:	0464d703          	lhu	a4,70(s1)
    80006282:	47a5                	li	a5,9
    80006284:	0ce7ed63          	bltu	a5,a4,8000635e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006288:	fffff097          	auipc	ra,0xfffff
    8000628c:	dce080e7          	jalr	-562(ra) # 80005056 <filealloc>
    80006290:	89aa                	mv	s3,a0
    80006292:	10050363          	beqz	a0,80006398 <sys_open+0x182>
    80006296:	00000097          	auipc	ra,0x0
    8000629a:	904080e7          	jalr	-1788(ra) # 80005b9a <fdalloc>
    8000629e:	892a                	mv	s2,a0
    800062a0:	0e054763          	bltz	a0,8000638e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800062a4:	04449703          	lh	a4,68(s1)
    800062a8:	478d                	li	a5,3
    800062aa:	0cf70563          	beq	a4,a5,80006374 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800062ae:	4789                	li	a5,2
    800062b0:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800062b4:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800062b8:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800062bc:	f4c42783          	lw	a5,-180(s0)
    800062c0:	0017c713          	xori	a4,a5,1
    800062c4:	8b05                	andi	a4,a4,1
    800062c6:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800062ca:	0037f713          	andi	a4,a5,3
    800062ce:	00e03733          	snez	a4,a4
    800062d2:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800062d6:	4007f793          	andi	a5,a5,1024
    800062da:	c791                	beqz	a5,800062e6 <sys_open+0xd0>
    800062dc:	04449703          	lh	a4,68(s1)
    800062e0:	4789                	li	a5,2
    800062e2:	0af70063          	beq	a4,a5,80006382 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800062e6:	8526                	mv	a0,s1
    800062e8:	ffffe097          	auipc	ra,0xffffe
    800062ec:	05e080e7          	jalr	94(ra) # 80004346 <iunlock>
  end_op();
    800062f0:	fffff097          	auipc	ra,0xfffff
    800062f4:	9d6080e7          	jalr	-1578(ra) # 80004cc6 <end_op>

  return fd;
    800062f8:	854a                	mv	a0,s2
}
    800062fa:	70ea                	ld	ra,184(sp)
    800062fc:	744a                	ld	s0,176(sp)
    800062fe:	74aa                	ld	s1,168(sp)
    80006300:	790a                	ld	s2,160(sp)
    80006302:	69ea                	ld	s3,152(sp)
    80006304:	6129                	addi	sp,sp,192
    80006306:	8082                	ret
      end_op();
    80006308:	fffff097          	auipc	ra,0xfffff
    8000630c:	9be080e7          	jalr	-1602(ra) # 80004cc6 <end_op>
      return -1;
    80006310:	557d                	li	a0,-1
    80006312:	b7e5                	j	800062fa <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80006314:	f5040513          	addi	a0,s0,-176
    80006318:	ffffe097          	auipc	ra,0xffffe
    8000631c:	712080e7          	jalr	1810(ra) # 80004a2a <namei>
    80006320:	84aa                	mv	s1,a0
    80006322:	c905                	beqz	a0,80006352 <sys_open+0x13c>
    ilock(ip);
    80006324:	ffffe097          	auipc	ra,0xffffe
    80006328:	f60080e7          	jalr	-160(ra) # 80004284 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000632c:	04449703          	lh	a4,68(s1)
    80006330:	4785                	li	a5,1
    80006332:	f4f711e3          	bne	a4,a5,80006274 <sys_open+0x5e>
    80006336:	f4c42783          	lw	a5,-180(s0)
    8000633a:	d7b9                	beqz	a5,80006288 <sys_open+0x72>
      iunlockput(ip);
    8000633c:	8526                	mv	a0,s1
    8000633e:	ffffe097          	auipc	ra,0xffffe
    80006342:	1a8080e7          	jalr	424(ra) # 800044e6 <iunlockput>
      end_op();
    80006346:	fffff097          	auipc	ra,0xfffff
    8000634a:	980080e7          	jalr	-1664(ra) # 80004cc6 <end_op>
      return -1;
    8000634e:	557d                	li	a0,-1
    80006350:	b76d                	j	800062fa <sys_open+0xe4>
      end_op();
    80006352:	fffff097          	auipc	ra,0xfffff
    80006356:	974080e7          	jalr	-1676(ra) # 80004cc6 <end_op>
      return -1;
    8000635a:	557d                	li	a0,-1
    8000635c:	bf79                	j	800062fa <sys_open+0xe4>
    iunlockput(ip);
    8000635e:	8526                	mv	a0,s1
    80006360:	ffffe097          	auipc	ra,0xffffe
    80006364:	186080e7          	jalr	390(ra) # 800044e6 <iunlockput>
    end_op();
    80006368:	fffff097          	auipc	ra,0xfffff
    8000636c:	95e080e7          	jalr	-1698(ra) # 80004cc6 <end_op>
    return -1;
    80006370:	557d                	li	a0,-1
    80006372:	b761                	j	800062fa <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006374:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006378:	04649783          	lh	a5,70(s1)
    8000637c:	02f99223          	sh	a5,36(s3)
    80006380:	bf25                	j	800062b8 <sys_open+0xa2>
    itrunc(ip);
    80006382:	8526                	mv	a0,s1
    80006384:	ffffe097          	auipc	ra,0xffffe
    80006388:	00e080e7          	jalr	14(ra) # 80004392 <itrunc>
    8000638c:	bfa9                	j	800062e6 <sys_open+0xd0>
      fileclose(f);
    8000638e:	854e                	mv	a0,s3
    80006390:	fffff097          	auipc	ra,0xfffff
    80006394:	d82080e7          	jalr	-638(ra) # 80005112 <fileclose>
    iunlockput(ip);
    80006398:	8526                	mv	a0,s1
    8000639a:	ffffe097          	auipc	ra,0xffffe
    8000639e:	14c080e7          	jalr	332(ra) # 800044e6 <iunlockput>
    end_op();
    800063a2:	fffff097          	auipc	ra,0xfffff
    800063a6:	924080e7          	jalr	-1756(ra) # 80004cc6 <end_op>
    return -1;
    800063aa:	557d                	li	a0,-1
    800063ac:	b7b9                	j	800062fa <sys_open+0xe4>

00000000800063ae <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800063ae:	7175                	addi	sp,sp,-144
    800063b0:	e506                	sd	ra,136(sp)
    800063b2:	e122                	sd	s0,128(sp)
    800063b4:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800063b6:	fffff097          	auipc	ra,0xfffff
    800063ba:	890080e7          	jalr	-1904(ra) # 80004c46 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800063be:	08000613          	li	a2,128
    800063c2:	f7040593          	addi	a1,s0,-144
    800063c6:	4501                	li	a0,0
    800063c8:	ffffd097          	auipc	ra,0xffffd
    800063cc:	ddc080e7          	jalr	-548(ra) # 800031a4 <argstr>
    800063d0:	02054963          	bltz	a0,80006402 <sys_mkdir+0x54>
    800063d4:	4681                	li	a3,0
    800063d6:	4601                	li	a2,0
    800063d8:	4585                	li	a1,1
    800063da:	f7040513          	addi	a0,s0,-144
    800063de:	fffff097          	auipc	ra,0xfffff
    800063e2:	7fe080e7          	jalr	2046(ra) # 80005bdc <create>
    800063e6:	cd11                	beqz	a0,80006402 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800063e8:	ffffe097          	auipc	ra,0xffffe
    800063ec:	0fe080e7          	jalr	254(ra) # 800044e6 <iunlockput>
  end_op();
    800063f0:	fffff097          	auipc	ra,0xfffff
    800063f4:	8d6080e7          	jalr	-1834(ra) # 80004cc6 <end_op>
  return 0;
    800063f8:	4501                	li	a0,0
}
    800063fa:	60aa                	ld	ra,136(sp)
    800063fc:	640a                	ld	s0,128(sp)
    800063fe:	6149                	addi	sp,sp,144
    80006400:	8082                	ret
    end_op();
    80006402:	fffff097          	auipc	ra,0xfffff
    80006406:	8c4080e7          	jalr	-1852(ra) # 80004cc6 <end_op>
    return -1;
    8000640a:	557d                	li	a0,-1
    8000640c:	b7fd                	j	800063fa <sys_mkdir+0x4c>

000000008000640e <sys_mknod>:

uint64
sys_mknod(void)
{
    8000640e:	7135                	addi	sp,sp,-160
    80006410:	ed06                	sd	ra,152(sp)
    80006412:	e922                	sd	s0,144(sp)
    80006414:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006416:	fffff097          	auipc	ra,0xfffff
    8000641a:	830080e7          	jalr	-2000(ra) # 80004c46 <begin_op>
  argint(1, &major);
    8000641e:	f6c40593          	addi	a1,s0,-148
    80006422:	4505                	li	a0,1
    80006424:	ffffd097          	auipc	ra,0xffffd
    80006428:	d40080e7          	jalr	-704(ra) # 80003164 <argint>
  argint(2, &minor);
    8000642c:	f6840593          	addi	a1,s0,-152
    80006430:	4509                	li	a0,2
    80006432:	ffffd097          	auipc	ra,0xffffd
    80006436:	d32080e7          	jalr	-718(ra) # 80003164 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000643a:	08000613          	li	a2,128
    8000643e:	f7040593          	addi	a1,s0,-144
    80006442:	4501                	li	a0,0
    80006444:	ffffd097          	auipc	ra,0xffffd
    80006448:	d60080e7          	jalr	-672(ra) # 800031a4 <argstr>
    8000644c:	02054b63          	bltz	a0,80006482 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006450:	f6841683          	lh	a3,-152(s0)
    80006454:	f6c41603          	lh	a2,-148(s0)
    80006458:	458d                	li	a1,3
    8000645a:	f7040513          	addi	a0,s0,-144
    8000645e:	fffff097          	auipc	ra,0xfffff
    80006462:	77e080e7          	jalr	1918(ra) # 80005bdc <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006466:	cd11                	beqz	a0,80006482 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006468:	ffffe097          	auipc	ra,0xffffe
    8000646c:	07e080e7          	jalr	126(ra) # 800044e6 <iunlockput>
  end_op();
    80006470:	fffff097          	auipc	ra,0xfffff
    80006474:	856080e7          	jalr	-1962(ra) # 80004cc6 <end_op>
  return 0;
    80006478:	4501                	li	a0,0
}
    8000647a:	60ea                	ld	ra,152(sp)
    8000647c:	644a                	ld	s0,144(sp)
    8000647e:	610d                	addi	sp,sp,160
    80006480:	8082                	ret
    end_op();
    80006482:	fffff097          	auipc	ra,0xfffff
    80006486:	844080e7          	jalr	-1980(ra) # 80004cc6 <end_op>
    return -1;
    8000648a:	557d                	li	a0,-1
    8000648c:	b7fd                	j	8000647a <sys_mknod+0x6c>

000000008000648e <sys_chdir>:

uint64
sys_chdir(void)
{
    8000648e:	7135                	addi	sp,sp,-160
    80006490:	ed06                	sd	ra,152(sp)
    80006492:	e922                	sd	s0,144(sp)
    80006494:	e526                	sd	s1,136(sp)
    80006496:	e14a                	sd	s2,128(sp)
    80006498:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000649a:	ffffb097          	auipc	ra,0xffffb
    8000649e:	72c080e7          	jalr	1836(ra) # 80001bc6 <myproc>
    800064a2:	892a                	mv	s2,a0
  
  begin_op();
    800064a4:	ffffe097          	auipc	ra,0xffffe
    800064a8:	7a2080e7          	jalr	1954(ra) # 80004c46 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800064ac:	08000613          	li	a2,128
    800064b0:	f6040593          	addi	a1,s0,-160
    800064b4:	4501                	li	a0,0
    800064b6:	ffffd097          	auipc	ra,0xffffd
    800064ba:	cee080e7          	jalr	-786(ra) # 800031a4 <argstr>
    800064be:	04054b63          	bltz	a0,80006514 <sys_chdir+0x86>
    800064c2:	f6040513          	addi	a0,s0,-160
    800064c6:	ffffe097          	auipc	ra,0xffffe
    800064ca:	564080e7          	jalr	1380(ra) # 80004a2a <namei>
    800064ce:	84aa                	mv	s1,a0
    800064d0:	c131                	beqz	a0,80006514 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800064d2:	ffffe097          	auipc	ra,0xffffe
    800064d6:	db2080e7          	jalr	-590(ra) # 80004284 <ilock>
  if(ip->type != T_DIR){
    800064da:	04449703          	lh	a4,68(s1)
    800064de:	4785                	li	a5,1
    800064e0:	04f71063          	bne	a4,a5,80006520 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800064e4:	8526                	mv	a0,s1
    800064e6:	ffffe097          	auipc	ra,0xffffe
    800064ea:	e60080e7          	jalr	-416(ra) # 80004346 <iunlock>
  iput(p->cwd);
    800064ee:	15093503          	ld	a0,336(s2)
    800064f2:	ffffe097          	auipc	ra,0xffffe
    800064f6:	f4c080e7          	jalr	-180(ra) # 8000443e <iput>
  end_op();
    800064fa:	ffffe097          	auipc	ra,0xffffe
    800064fe:	7cc080e7          	jalr	1996(ra) # 80004cc6 <end_op>
  p->cwd = ip;
    80006502:	14993823          	sd	s1,336(s2)
  return 0;
    80006506:	4501                	li	a0,0
}
    80006508:	60ea                	ld	ra,152(sp)
    8000650a:	644a                	ld	s0,144(sp)
    8000650c:	64aa                	ld	s1,136(sp)
    8000650e:	690a                	ld	s2,128(sp)
    80006510:	610d                	addi	sp,sp,160
    80006512:	8082                	ret
    end_op();
    80006514:	ffffe097          	auipc	ra,0xffffe
    80006518:	7b2080e7          	jalr	1970(ra) # 80004cc6 <end_op>
    return -1;
    8000651c:	557d                	li	a0,-1
    8000651e:	b7ed                	j	80006508 <sys_chdir+0x7a>
    iunlockput(ip);
    80006520:	8526                	mv	a0,s1
    80006522:	ffffe097          	auipc	ra,0xffffe
    80006526:	fc4080e7          	jalr	-60(ra) # 800044e6 <iunlockput>
    end_op();
    8000652a:	ffffe097          	auipc	ra,0xffffe
    8000652e:	79c080e7          	jalr	1948(ra) # 80004cc6 <end_op>
    return -1;
    80006532:	557d                	li	a0,-1
    80006534:	bfd1                	j	80006508 <sys_chdir+0x7a>

0000000080006536 <sys_exec>:

uint64
sys_exec(void)
{
    80006536:	7145                	addi	sp,sp,-464
    80006538:	e786                	sd	ra,456(sp)
    8000653a:	e3a2                	sd	s0,448(sp)
    8000653c:	ff26                	sd	s1,440(sp)
    8000653e:	fb4a                	sd	s2,432(sp)
    80006540:	f74e                	sd	s3,424(sp)
    80006542:	f352                	sd	s4,416(sp)
    80006544:	ef56                	sd	s5,408(sp)
    80006546:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80006548:	e3840593          	addi	a1,s0,-456
    8000654c:	4505                	li	a0,1
    8000654e:	ffffd097          	auipc	ra,0xffffd
    80006552:	c36080e7          	jalr	-970(ra) # 80003184 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80006556:	08000613          	li	a2,128
    8000655a:	f4040593          	addi	a1,s0,-192
    8000655e:	4501                	li	a0,0
    80006560:	ffffd097          	auipc	ra,0xffffd
    80006564:	c44080e7          	jalr	-956(ra) # 800031a4 <argstr>
    80006568:	87aa                	mv	a5,a0
    return -1;
    8000656a:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    8000656c:	0c07c263          	bltz	a5,80006630 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006570:	10000613          	li	a2,256
    80006574:	4581                	li	a1,0
    80006576:	e4040513          	addi	a0,s0,-448
    8000657a:	ffffa097          	auipc	ra,0xffffa
    8000657e:	76c080e7          	jalr	1900(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006582:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006586:	89a6                	mv	s3,s1
    80006588:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000658a:	02000a13          	li	s4,32
    8000658e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006592:	00391513          	slli	a0,s2,0x3
    80006596:	e3040593          	addi	a1,s0,-464
    8000659a:	e3843783          	ld	a5,-456(s0)
    8000659e:	953e                	add	a0,a0,a5
    800065a0:	ffffd097          	auipc	ra,0xffffd
    800065a4:	b26080e7          	jalr	-1242(ra) # 800030c6 <fetchaddr>
    800065a8:	02054a63          	bltz	a0,800065dc <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    800065ac:	e3043783          	ld	a5,-464(s0)
    800065b0:	c3b9                	beqz	a5,800065f6 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800065b2:	ffffa097          	auipc	ra,0xffffa
    800065b6:	548080e7          	jalr	1352(ra) # 80000afa <kalloc>
    800065ba:	85aa                	mv	a1,a0
    800065bc:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800065c0:	cd11                	beqz	a0,800065dc <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800065c2:	6605                	lui	a2,0x1
    800065c4:	e3043503          	ld	a0,-464(s0)
    800065c8:	ffffd097          	auipc	ra,0xffffd
    800065cc:	b50080e7          	jalr	-1200(ra) # 80003118 <fetchstr>
    800065d0:	00054663          	bltz	a0,800065dc <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    800065d4:	0905                	addi	s2,s2,1
    800065d6:	09a1                	addi	s3,s3,8
    800065d8:	fb491be3          	bne	s2,s4,8000658e <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800065dc:	10048913          	addi	s2,s1,256
    800065e0:	6088                	ld	a0,0(s1)
    800065e2:	c531                	beqz	a0,8000662e <sys_exec+0xf8>
    kfree(argv[i]);
    800065e4:	ffffa097          	auipc	ra,0xffffa
    800065e8:	41a080e7          	jalr	1050(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800065ec:	04a1                	addi	s1,s1,8
    800065ee:	ff2499e3          	bne	s1,s2,800065e0 <sys_exec+0xaa>
  return -1;
    800065f2:	557d                	li	a0,-1
    800065f4:	a835                	j	80006630 <sys_exec+0xfa>
      argv[i] = 0;
    800065f6:	0a8e                	slli	s5,s5,0x3
    800065f8:	fc040793          	addi	a5,s0,-64
    800065fc:	9abe                	add	s5,s5,a5
    800065fe:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006602:	e4040593          	addi	a1,s0,-448
    80006606:	f4040513          	addi	a0,s0,-192
    8000660a:	fffff097          	auipc	ra,0xfffff
    8000660e:	190080e7          	jalr	400(ra) # 8000579a <exec>
    80006612:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006614:	10048993          	addi	s3,s1,256
    80006618:	6088                	ld	a0,0(s1)
    8000661a:	c901                	beqz	a0,8000662a <sys_exec+0xf4>
    kfree(argv[i]);
    8000661c:	ffffa097          	auipc	ra,0xffffa
    80006620:	3e2080e7          	jalr	994(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006624:	04a1                	addi	s1,s1,8
    80006626:	ff3499e3          	bne	s1,s3,80006618 <sys_exec+0xe2>
  return ret;
    8000662a:	854a                	mv	a0,s2
    8000662c:	a011                	j	80006630 <sys_exec+0xfa>
  return -1;
    8000662e:	557d                	li	a0,-1
}
    80006630:	60be                	ld	ra,456(sp)
    80006632:	641e                	ld	s0,448(sp)
    80006634:	74fa                	ld	s1,440(sp)
    80006636:	795a                	ld	s2,432(sp)
    80006638:	79ba                	ld	s3,424(sp)
    8000663a:	7a1a                	ld	s4,416(sp)
    8000663c:	6afa                	ld	s5,408(sp)
    8000663e:	6179                	addi	sp,sp,464
    80006640:	8082                	ret

0000000080006642 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006642:	7139                	addi	sp,sp,-64
    80006644:	fc06                	sd	ra,56(sp)
    80006646:	f822                	sd	s0,48(sp)
    80006648:	f426                	sd	s1,40(sp)
    8000664a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000664c:	ffffb097          	auipc	ra,0xffffb
    80006650:	57a080e7          	jalr	1402(ra) # 80001bc6 <myproc>
    80006654:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006656:	fd840593          	addi	a1,s0,-40
    8000665a:	4501                	li	a0,0
    8000665c:	ffffd097          	auipc	ra,0xffffd
    80006660:	b28080e7          	jalr	-1240(ra) # 80003184 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006664:	fc840593          	addi	a1,s0,-56
    80006668:	fd040513          	addi	a0,s0,-48
    8000666c:	fffff097          	auipc	ra,0xfffff
    80006670:	dd6080e7          	jalr	-554(ra) # 80005442 <pipealloc>
    return -1;
    80006674:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006676:	0c054463          	bltz	a0,8000673e <sys_pipe+0xfc>
  fd0 = -1;
    8000667a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000667e:	fd043503          	ld	a0,-48(s0)
    80006682:	fffff097          	auipc	ra,0xfffff
    80006686:	518080e7          	jalr	1304(ra) # 80005b9a <fdalloc>
    8000668a:	fca42223          	sw	a0,-60(s0)
    8000668e:	08054b63          	bltz	a0,80006724 <sys_pipe+0xe2>
    80006692:	fc843503          	ld	a0,-56(s0)
    80006696:	fffff097          	auipc	ra,0xfffff
    8000669a:	504080e7          	jalr	1284(ra) # 80005b9a <fdalloc>
    8000669e:	fca42023          	sw	a0,-64(s0)
    800066a2:	06054863          	bltz	a0,80006712 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800066a6:	4691                	li	a3,4
    800066a8:	fc440613          	addi	a2,s0,-60
    800066ac:	fd843583          	ld	a1,-40(s0)
    800066b0:	68a8                	ld	a0,80(s1)
    800066b2:	ffffb097          	auipc	ra,0xffffb
    800066b6:	fd2080e7          	jalr	-46(ra) # 80001684 <copyout>
    800066ba:	02054063          	bltz	a0,800066da <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800066be:	4691                	li	a3,4
    800066c0:	fc040613          	addi	a2,s0,-64
    800066c4:	fd843583          	ld	a1,-40(s0)
    800066c8:	0591                	addi	a1,a1,4
    800066ca:	68a8                	ld	a0,80(s1)
    800066cc:	ffffb097          	auipc	ra,0xffffb
    800066d0:	fb8080e7          	jalr	-72(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800066d4:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800066d6:	06055463          	bgez	a0,8000673e <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    800066da:	fc442783          	lw	a5,-60(s0)
    800066de:	07e9                	addi	a5,a5,26
    800066e0:	078e                	slli	a5,a5,0x3
    800066e2:	97a6                	add	a5,a5,s1
    800066e4:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800066e8:	fc042503          	lw	a0,-64(s0)
    800066ec:	0569                	addi	a0,a0,26
    800066ee:	050e                	slli	a0,a0,0x3
    800066f0:	94aa                	add	s1,s1,a0
    800066f2:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800066f6:	fd043503          	ld	a0,-48(s0)
    800066fa:	fffff097          	auipc	ra,0xfffff
    800066fe:	a18080e7          	jalr	-1512(ra) # 80005112 <fileclose>
    fileclose(wf);
    80006702:	fc843503          	ld	a0,-56(s0)
    80006706:	fffff097          	auipc	ra,0xfffff
    8000670a:	a0c080e7          	jalr	-1524(ra) # 80005112 <fileclose>
    return -1;
    8000670e:	57fd                	li	a5,-1
    80006710:	a03d                	j	8000673e <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006712:	fc442783          	lw	a5,-60(s0)
    80006716:	0007c763          	bltz	a5,80006724 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    8000671a:	07e9                	addi	a5,a5,26
    8000671c:	078e                	slli	a5,a5,0x3
    8000671e:	94be                	add	s1,s1,a5
    80006720:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006724:	fd043503          	ld	a0,-48(s0)
    80006728:	fffff097          	auipc	ra,0xfffff
    8000672c:	9ea080e7          	jalr	-1558(ra) # 80005112 <fileclose>
    fileclose(wf);
    80006730:	fc843503          	ld	a0,-56(s0)
    80006734:	fffff097          	auipc	ra,0xfffff
    80006738:	9de080e7          	jalr	-1570(ra) # 80005112 <fileclose>
    return -1;
    8000673c:	57fd                	li	a5,-1
}
    8000673e:	853e                	mv	a0,a5
    80006740:	70e2                	ld	ra,56(sp)
    80006742:	7442                	ld	s0,48(sp)
    80006744:	74a2                	ld	s1,40(sp)
    80006746:	6121                	addi	sp,sp,64
    80006748:	8082                	ret
    8000674a:	0000                	unimp
    8000674c:	0000                	unimp
	...

0000000080006750 <kernelvec>:
    80006750:	7111                	addi	sp,sp,-256
    80006752:	e006                	sd	ra,0(sp)
    80006754:	e40a                	sd	sp,8(sp)
    80006756:	e80e                	sd	gp,16(sp)
    80006758:	ec12                	sd	tp,24(sp)
    8000675a:	f016                	sd	t0,32(sp)
    8000675c:	f41a                	sd	t1,40(sp)
    8000675e:	f81e                	sd	t2,48(sp)
    80006760:	fc22                	sd	s0,56(sp)
    80006762:	e0a6                	sd	s1,64(sp)
    80006764:	e4aa                	sd	a0,72(sp)
    80006766:	e8ae                	sd	a1,80(sp)
    80006768:	ecb2                	sd	a2,88(sp)
    8000676a:	f0b6                	sd	a3,96(sp)
    8000676c:	f4ba                	sd	a4,104(sp)
    8000676e:	f8be                	sd	a5,112(sp)
    80006770:	fcc2                	sd	a6,120(sp)
    80006772:	e146                	sd	a7,128(sp)
    80006774:	e54a                	sd	s2,136(sp)
    80006776:	e94e                	sd	s3,144(sp)
    80006778:	ed52                	sd	s4,152(sp)
    8000677a:	f156                	sd	s5,160(sp)
    8000677c:	f55a                	sd	s6,168(sp)
    8000677e:	f95e                	sd	s7,176(sp)
    80006780:	fd62                	sd	s8,184(sp)
    80006782:	e1e6                	sd	s9,192(sp)
    80006784:	e5ea                	sd	s10,200(sp)
    80006786:	e9ee                	sd	s11,208(sp)
    80006788:	edf2                	sd	t3,216(sp)
    8000678a:	f1f6                	sd	t4,224(sp)
    8000678c:	f5fa                	sd	t5,232(sp)
    8000678e:	f9fe                	sd	t6,240(sp)
    80006790:	f98fc0ef          	jal	ra,80002f28 <kerneltrap>
    80006794:	6082                	ld	ra,0(sp)
    80006796:	6122                	ld	sp,8(sp)
    80006798:	61c2                	ld	gp,16(sp)
    8000679a:	7282                	ld	t0,32(sp)
    8000679c:	7322                	ld	t1,40(sp)
    8000679e:	73c2                	ld	t2,48(sp)
    800067a0:	7462                	ld	s0,56(sp)
    800067a2:	6486                	ld	s1,64(sp)
    800067a4:	6526                	ld	a0,72(sp)
    800067a6:	65c6                	ld	a1,80(sp)
    800067a8:	6666                	ld	a2,88(sp)
    800067aa:	7686                	ld	a3,96(sp)
    800067ac:	7726                	ld	a4,104(sp)
    800067ae:	77c6                	ld	a5,112(sp)
    800067b0:	7866                	ld	a6,120(sp)
    800067b2:	688a                	ld	a7,128(sp)
    800067b4:	692a                	ld	s2,136(sp)
    800067b6:	69ca                	ld	s3,144(sp)
    800067b8:	6a6a                	ld	s4,152(sp)
    800067ba:	7a8a                	ld	s5,160(sp)
    800067bc:	7b2a                	ld	s6,168(sp)
    800067be:	7bca                	ld	s7,176(sp)
    800067c0:	7c6a                	ld	s8,184(sp)
    800067c2:	6c8e                	ld	s9,192(sp)
    800067c4:	6d2e                	ld	s10,200(sp)
    800067c6:	6dce                	ld	s11,208(sp)
    800067c8:	6e6e                	ld	t3,216(sp)
    800067ca:	7e8e                	ld	t4,224(sp)
    800067cc:	7f2e                	ld	t5,232(sp)
    800067ce:	7fce                	ld	t6,240(sp)
    800067d0:	6111                	addi	sp,sp,256
    800067d2:	10200073          	sret
    800067d6:	00000013          	nop
    800067da:	00000013          	nop
    800067de:	0001                	nop

00000000800067e0 <timervec>:
    800067e0:	34051573          	csrrw	a0,mscratch,a0
    800067e4:	e10c                	sd	a1,0(a0)
    800067e6:	e510                	sd	a2,8(a0)
    800067e8:	e914                	sd	a3,16(a0)
    800067ea:	6d0c                	ld	a1,24(a0)
    800067ec:	7110                	ld	a2,32(a0)
    800067ee:	6194                	ld	a3,0(a1)
    800067f0:	96b2                	add	a3,a3,a2
    800067f2:	e194                	sd	a3,0(a1)
    800067f4:	4589                	li	a1,2
    800067f6:	14459073          	csrw	sip,a1
    800067fa:	6914                	ld	a3,16(a0)
    800067fc:	6510                	ld	a2,8(a0)
    800067fe:	610c                	ld	a1,0(a0)
    80006800:	34051573          	csrrw	a0,mscratch,a0
    80006804:	30200073          	mret
	...

000000008000680a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000680a:	1141                	addi	sp,sp,-16
    8000680c:	e422                	sd	s0,8(sp)
    8000680e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006810:	0c0007b7          	lui	a5,0xc000
    80006814:	4705                	li	a4,1
    80006816:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006818:	c3d8                	sw	a4,4(a5)
}
    8000681a:	6422                	ld	s0,8(sp)
    8000681c:	0141                	addi	sp,sp,16
    8000681e:	8082                	ret

0000000080006820 <plicinithart>:

void
plicinithart(void)
{
    80006820:	1141                	addi	sp,sp,-16
    80006822:	e406                	sd	ra,8(sp)
    80006824:	e022                	sd	s0,0(sp)
    80006826:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006828:	ffffb097          	auipc	ra,0xffffb
    8000682c:	372080e7          	jalr	882(ra) # 80001b9a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006830:	0085171b          	slliw	a4,a0,0x8
    80006834:	0c0027b7          	lui	a5,0xc002
    80006838:	97ba                	add	a5,a5,a4
    8000683a:	40200713          	li	a4,1026
    8000683e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006842:	00d5151b          	slliw	a0,a0,0xd
    80006846:	0c2017b7          	lui	a5,0xc201
    8000684a:	953e                	add	a0,a0,a5
    8000684c:	00052023          	sw	zero,0(a0)
}
    80006850:	60a2                	ld	ra,8(sp)
    80006852:	6402                	ld	s0,0(sp)
    80006854:	0141                	addi	sp,sp,16
    80006856:	8082                	ret

0000000080006858 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006858:	1141                	addi	sp,sp,-16
    8000685a:	e406                	sd	ra,8(sp)
    8000685c:	e022                	sd	s0,0(sp)
    8000685e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006860:	ffffb097          	auipc	ra,0xffffb
    80006864:	33a080e7          	jalr	826(ra) # 80001b9a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006868:	00d5179b          	slliw	a5,a0,0xd
    8000686c:	0c201537          	lui	a0,0xc201
    80006870:	953e                	add	a0,a0,a5
  return irq;
}
    80006872:	4148                	lw	a0,4(a0)
    80006874:	60a2                	ld	ra,8(sp)
    80006876:	6402                	ld	s0,0(sp)
    80006878:	0141                	addi	sp,sp,16
    8000687a:	8082                	ret

000000008000687c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000687c:	1101                	addi	sp,sp,-32
    8000687e:	ec06                	sd	ra,24(sp)
    80006880:	e822                	sd	s0,16(sp)
    80006882:	e426                	sd	s1,8(sp)
    80006884:	1000                	addi	s0,sp,32
    80006886:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006888:	ffffb097          	auipc	ra,0xffffb
    8000688c:	312080e7          	jalr	786(ra) # 80001b9a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006890:	00d5151b          	slliw	a0,a0,0xd
    80006894:	0c2017b7          	lui	a5,0xc201
    80006898:	97aa                	add	a5,a5,a0
    8000689a:	c3c4                	sw	s1,4(a5)
}
    8000689c:	60e2                	ld	ra,24(sp)
    8000689e:	6442                	ld	s0,16(sp)
    800068a0:	64a2                	ld	s1,8(sp)
    800068a2:	6105                	addi	sp,sp,32
    800068a4:	8082                	ret

00000000800068a6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800068a6:	1141                	addi	sp,sp,-16
    800068a8:	e406                	sd	ra,8(sp)
    800068aa:	e022                	sd	s0,0(sp)
    800068ac:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800068ae:	479d                	li	a5,7
    800068b0:	04a7cc63          	blt	a5,a0,80006908 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800068b4:	0001e797          	auipc	a5,0x1e
    800068b8:	29478793          	addi	a5,a5,660 # 80024b48 <disk>
    800068bc:	97aa                	add	a5,a5,a0
    800068be:	0187c783          	lbu	a5,24(a5)
    800068c2:	ebb9                	bnez	a5,80006918 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800068c4:	00451613          	slli	a2,a0,0x4
    800068c8:	0001e797          	auipc	a5,0x1e
    800068cc:	28078793          	addi	a5,a5,640 # 80024b48 <disk>
    800068d0:	6394                	ld	a3,0(a5)
    800068d2:	96b2                	add	a3,a3,a2
    800068d4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800068d8:	6398                	ld	a4,0(a5)
    800068da:	9732                	add	a4,a4,a2
    800068dc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800068e0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800068e4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800068e8:	953e                	add	a0,a0,a5
    800068ea:	4785                	li	a5,1
    800068ec:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    800068f0:	0001e517          	auipc	a0,0x1e
    800068f4:	27050513          	addi	a0,a0,624 # 80024b60 <disk+0x18>
    800068f8:	ffffc097          	auipc	ra,0xffffc
    800068fc:	cfc080e7          	jalr	-772(ra) # 800025f4 <wakeup>
}
    80006900:	60a2                	ld	ra,8(sp)
    80006902:	6402                	ld	s0,0(sp)
    80006904:	0141                	addi	sp,sp,16
    80006906:	8082                	ret
    panic("free_desc 1");
    80006908:	00003517          	auipc	a0,0x3
    8000690c:	fe050513          	addi	a0,a0,-32 # 800098e8 <syscalls+0x310>
    80006910:	ffffa097          	auipc	ra,0xffffa
    80006914:	c34080e7          	jalr	-972(ra) # 80000544 <panic>
    panic("free_desc 2");
    80006918:	00003517          	auipc	a0,0x3
    8000691c:	fe050513          	addi	a0,a0,-32 # 800098f8 <syscalls+0x320>
    80006920:	ffffa097          	auipc	ra,0xffffa
    80006924:	c24080e7          	jalr	-988(ra) # 80000544 <panic>

0000000080006928 <virtio_disk_init>:
{
    80006928:	1101                	addi	sp,sp,-32
    8000692a:	ec06                	sd	ra,24(sp)
    8000692c:	e822                	sd	s0,16(sp)
    8000692e:	e426                	sd	s1,8(sp)
    80006930:	e04a                	sd	s2,0(sp)
    80006932:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006934:	00003597          	auipc	a1,0x3
    80006938:	fd458593          	addi	a1,a1,-44 # 80009908 <syscalls+0x330>
    8000693c:	0001e517          	auipc	a0,0x1e
    80006940:	33450513          	addi	a0,a0,820 # 80024c70 <disk+0x128>
    80006944:	ffffa097          	auipc	ra,0xffffa
    80006948:	216080e7          	jalr	534(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000694c:	100017b7          	lui	a5,0x10001
    80006950:	4398                	lw	a4,0(a5)
    80006952:	2701                	sext.w	a4,a4
    80006954:	747277b7          	lui	a5,0x74727
    80006958:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000695c:	14f71e63          	bne	a4,a5,80006ab8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006960:	100017b7          	lui	a5,0x10001
    80006964:	43dc                	lw	a5,4(a5)
    80006966:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006968:	4709                	li	a4,2
    8000696a:	14e79763          	bne	a5,a4,80006ab8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000696e:	100017b7          	lui	a5,0x10001
    80006972:	479c                	lw	a5,8(a5)
    80006974:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006976:	14e79163          	bne	a5,a4,80006ab8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000697a:	100017b7          	lui	a5,0x10001
    8000697e:	47d8                	lw	a4,12(a5)
    80006980:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006982:	554d47b7          	lui	a5,0x554d4
    80006986:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000698a:	12f71763          	bne	a4,a5,80006ab8 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000698e:	100017b7          	lui	a5,0x10001
    80006992:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006996:	4705                	li	a4,1
    80006998:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000699a:	470d                	li	a4,3
    8000699c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000699e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800069a0:	c7ffe737          	lui	a4,0xc7ffe
    800069a4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd8757>
    800069a8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800069aa:	2701                	sext.w	a4,a4
    800069ac:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800069ae:	472d                	li	a4,11
    800069b0:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800069b2:	0707a903          	lw	s2,112(a5)
    800069b6:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800069b8:	00897793          	andi	a5,s2,8
    800069bc:	10078663          	beqz	a5,80006ac8 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800069c0:	100017b7          	lui	a5,0x10001
    800069c4:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800069c8:	43fc                	lw	a5,68(a5)
    800069ca:	2781                	sext.w	a5,a5
    800069cc:	10079663          	bnez	a5,80006ad8 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800069d0:	100017b7          	lui	a5,0x10001
    800069d4:	5bdc                	lw	a5,52(a5)
    800069d6:	2781                	sext.w	a5,a5
  if(max == 0)
    800069d8:	10078863          	beqz	a5,80006ae8 <virtio_disk_init+0x1c0>
  if(max < NUM)
    800069dc:	471d                	li	a4,7
    800069de:	10f77d63          	bgeu	a4,a5,80006af8 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    800069e2:	ffffa097          	auipc	ra,0xffffa
    800069e6:	118080e7          	jalr	280(ra) # 80000afa <kalloc>
    800069ea:	0001e497          	auipc	s1,0x1e
    800069ee:	15e48493          	addi	s1,s1,350 # 80024b48 <disk>
    800069f2:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800069f4:	ffffa097          	auipc	ra,0xffffa
    800069f8:	106080e7          	jalr	262(ra) # 80000afa <kalloc>
    800069fc:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800069fe:	ffffa097          	auipc	ra,0xffffa
    80006a02:	0fc080e7          	jalr	252(ra) # 80000afa <kalloc>
    80006a06:	87aa                	mv	a5,a0
    80006a08:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006a0a:	6088                	ld	a0,0(s1)
    80006a0c:	cd75                	beqz	a0,80006b08 <virtio_disk_init+0x1e0>
    80006a0e:	0001e717          	auipc	a4,0x1e
    80006a12:	14273703          	ld	a4,322(a4) # 80024b50 <disk+0x8>
    80006a16:	cb6d                	beqz	a4,80006b08 <virtio_disk_init+0x1e0>
    80006a18:	cbe5                	beqz	a5,80006b08 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    80006a1a:	6605                	lui	a2,0x1
    80006a1c:	4581                	li	a1,0
    80006a1e:	ffffa097          	auipc	ra,0xffffa
    80006a22:	2c8080e7          	jalr	712(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006a26:	0001e497          	auipc	s1,0x1e
    80006a2a:	12248493          	addi	s1,s1,290 # 80024b48 <disk>
    80006a2e:	6605                	lui	a2,0x1
    80006a30:	4581                	li	a1,0
    80006a32:	6488                	ld	a0,8(s1)
    80006a34:	ffffa097          	auipc	ra,0xffffa
    80006a38:	2b2080e7          	jalr	690(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    80006a3c:	6605                	lui	a2,0x1
    80006a3e:	4581                	li	a1,0
    80006a40:	6888                	ld	a0,16(s1)
    80006a42:	ffffa097          	auipc	ra,0xffffa
    80006a46:	2a4080e7          	jalr	676(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006a4a:	100017b7          	lui	a5,0x10001
    80006a4e:	4721                	li	a4,8
    80006a50:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006a52:	4098                	lw	a4,0(s1)
    80006a54:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006a58:	40d8                	lw	a4,4(s1)
    80006a5a:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80006a5e:	6498                	ld	a4,8(s1)
    80006a60:	0007069b          	sext.w	a3,a4
    80006a64:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006a68:	9701                	srai	a4,a4,0x20
    80006a6a:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80006a6e:	6898                	ld	a4,16(s1)
    80006a70:	0007069b          	sext.w	a3,a4
    80006a74:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006a78:	9701                	srai	a4,a4,0x20
    80006a7a:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80006a7e:	4685                	li	a3,1
    80006a80:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80006a82:	4705                	li	a4,1
    80006a84:	00d48c23          	sb	a3,24(s1)
    80006a88:	00e48ca3          	sb	a4,25(s1)
    80006a8c:	00e48d23          	sb	a4,26(s1)
    80006a90:	00e48da3          	sb	a4,27(s1)
    80006a94:	00e48e23          	sb	a4,28(s1)
    80006a98:	00e48ea3          	sb	a4,29(s1)
    80006a9c:	00e48f23          	sb	a4,30(s1)
    80006aa0:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006aa4:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006aa8:	0727a823          	sw	s2,112(a5)
}
    80006aac:	60e2                	ld	ra,24(sp)
    80006aae:	6442                	ld	s0,16(sp)
    80006ab0:	64a2                	ld	s1,8(sp)
    80006ab2:	6902                	ld	s2,0(sp)
    80006ab4:	6105                	addi	sp,sp,32
    80006ab6:	8082                	ret
    panic("could not find virtio disk");
    80006ab8:	00003517          	auipc	a0,0x3
    80006abc:	e6050513          	addi	a0,a0,-416 # 80009918 <syscalls+0x340>
    80006ac0:	ffffa097          	auipc	ra,0xffffa
    80006ac4:	a84080e7          	jalr	-1404(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006ac8:	00003517          	auipc	a0,0x3
    80006acc:	e7050513          	addi	a0,a0,-400 # 80009938 <syscalls+0x360>
    80006ad0:	ffffa097          	auipc	ra,0xffffa
    80006ad4:	a74080e7          	jalr	-1420(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80006ad8:	00003517          	auipc	a0,0x3
    80006adc:	e8050513          	addi	a0,a0,-384 # 80009958 <syscalls+0x380>
    80006ae0:	ffffa097          	auipc	ra,0xffffa
    80006ae4:	a64080e7          	jalr	-1436(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80006ae8:	00003517          	auipc	a0,0x3
    80006aec:	e9050513          	addi	a0,a0,-368 # 80009978 <syscalls+0x3a0>
    80006af0:	ffffa097          	auipc	ra,0xffffa
    80006af4:	a54080e7          	jalr	-1452(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    80006af8:	00003517          	auipc	a0,0x3
    80006afc:	ea050513          	addi	a0,a0,-352 # 80009998 <syscalls+0x3c0>
    80006b00:	ffffa097          	auipc	ra,0xffffa
    80006b04:	a44080e7          	jalr	-1468(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    80006b08:	00003517          	auipc	a0,0x3
    80006b0c:	eb050513          	addi	a0,a0,-336 # 800099b8 <syscalls+0x3e0>
    80006b10:	ffffa097          	auipc	ra,0xffffa
    80006b14:	a34080e7          	jalr	-1484(ra) # 80000544 <panic>

0000000080006b18 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006b18:	7159                	addi	sp,sp,-112
    80006b1a:	f486                	sd	ra,104(sp)
    80006b1c:	f0a2                	sd	s0,96(sp)
    80006b1e:	eca6                	sd	s1,88(sp)
    80006b20:	e8ca                	sd	s2,80(sp)
    80006b22:	e4ce                	sd	s3,72(sp)
    80006b24:	e0d2                	sd	s4,64(sp)
    80006b26:	fc56                	sd	s5,56(sp)
    80006b28:	f85a                	sd	s6,48(sp)
    80006b2a:	f45e                	sd	s7,40(sp)
    80006b2c:	f062                	sd	s8,32(sp)
    80006b2e:	ec66                	sd	s9,24(sp)
    80006b30:	e86a                	sd	s10,16(sp)
    80006b32:	1880                	addi	s0,sp,112
    80006b34:	892a                	mv	s2,a0
    80006b36:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006b38:	00c52c83          	lw	s9,12(a0)
    80006b3c:	001c9c9b          	slliw	s9,s9,0x1
    80006b40:	1c82                	slli	s9,s9,0x20
    80006b42:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006b46:	0001e517          	auipc	a0,0x1e
    80006b4a:	12a50513          	addi	a0,a0,298 # 80024c70 <disk+0x128>
    80006b4e:	ffffa097          	auipc	ra,0xffffa
    80006b52:	09c080e7          	jalr	156(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    80006b56:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006b58:	4ba1                	li	s7,8
      disk.free[i] = 0;
    80006b5a:	0001eb17          	auipc	s6,0x1e
    80006b5e:	feeb0b13          	addi	s6,s6,-18 # 80024b48 <disk>
  for(int i = 0; i < 3; i++){
    80006b62:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006b64:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006b66:	0001ec17          	auipc	s8,0x1e
    80006b6a:	10ac0c13          	addi	s8,s8,266 # 80024c70 <disk+0x128>
    80006b6e:	a8b5                	j	80006bea <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    80006b70:	00fb06b3          	add	a3,s6,a5
    80006b74:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006b78:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006b7a:	0207c563          	bltz	a5,80006ba4 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006b7e:	2485                	addiw	s1,s1,1
    80006b80:	0711                	addi	a4,a4,4
    80006b82:	1f548a63          	beq	s1,s5,80006d76 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    80006b86:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006b88:	0001e697          	auipc	a3,0x1e
    80006b8c:	fc068693          	addi	a3,a3,-64 # 80024b48 <disk>
    80006b90:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006b92:	0186c583          	lbu	a1,24(a3)
    80006b96:	fde9                	bnez	a1,80006b70 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006b98:	2785                	addiw	a5,a5,1
    80006b9a:	0685                	addi	a3,a3,1
    80006b9c:	ff779be3          	bne	a5,s7,80006b92 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006ba0:	57fd                	li	a5,-1
    80006ba2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006ba4:	02905a63          	blez	s1,80006bd8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006ba8:	f9042503          	lw	a0,-112(s0)
    80006bac:	00000097          	auipc	ra,0x0
    80006bb0:	cfa080e7          	jalr	-774(ra) # 800068a6 <free_desc>
      for(int j = 0; j < i; j++)
    80006bb4:	4785                	li	a5,1
    80006bb6:	0297d163          	bge	a5,s1,80006bd8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006bba:	f9442503          	lw	a0,-108(s0)
    80006bbe:	00000097          	auipc	ra,0x0
    80006bc2:	ce8080e7          	jalr	-792(ra) # 800068a6 <free_desc>
      for(int j = 0; j < i; j++)
    80006bc6:	4789                	li	a5,2
    80006bc8:	0097d863          	bge	a5,s1,80006bd8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006bcc:	f9842503          	lw	a0,-104(s0)
    80006bd0:	00000097          	auipc	ra,0x0
    80006bd4:	cd6080e7          	jalr	-810(ra) # 800068a6 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006bd8:	85e2                	mv	a1,s8
    80006bda:	0001e517          	auipc	a0,0x1e
    80006bde:	f8650513          	addi	a0,a0,-122 # 80024b60 <disk+0x18>
    80006be2:	ffffc097          	auipc	ra,0xffffc
    80006be6:	862080e7          	jalr	-1950(ra) # 80002444 <sleep>
  for(int i = 0; i < 3; i++){
    80006bea:	f9040713          	addi	a4,s0,-112
    80006bee:	84ce                	mv	s1,s3
    80006bf0:	bf59                	j	80006b86 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006bf2:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    80006bf6:	00479693          	slli	a3,a5,0x4
    80006bfa:	0001e797          	auipc	a5,0x1e
    80006bfe:	f4e78793          	addi	a5,a5,-178 # 80024b48 <disk>
    80006c02:	97b6                	add	a5,a5,a3
    80006c04:	4685                	li	a3,1
    80006c06:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006c08:	0001e597          	auipc	a1,0x1e
    80006c0c:	f4058593          	addi	a1,a1,-192 # 80024b48 <disk>
    80006c10:	00a60793          	addi	a5,a2,10
    80006c14:	0792                	slli	a5,a5,0x4
    80006c16:	97ae                	add	a5,a5,a1
    80006c18:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    80006c1c:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006c20:	f6070693          	addi	a3,a4,-160
    80006c24:	619c                	ld	a5,0(a1)
    80006c26:	97b6                	add	a5,a5,a3
    80006c28:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006c2a:	6188                	ld	a0,0(a1)
    80006c2c:	96aa                	add	a3,a3,a0
    80006c2e:	47c1                	li	a5,16
    80006c30:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006c32:	4785                	li	a5,1
    80006c34:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006c38:	f9442783          	lw	a5,-108(s0)
    80006c3c:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006c40:	0792                	slli	a5,a5,0x4
    80006c42:	953e                	add	a0,a0,a5
    80006c44:	05890693          	addi	a3,s2,88
    80006c48:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    80006c4a:	6188                	ld	a0,0(a1)
    80006c4c:	97aa                	add	a5,a5,a0
    80006c4e:	40000693          	li	a3,1024
    80006c52:	c794                	sw	a3,8(a5)
  if(write)
    80006c54:	100d0d63          	beqz	s10,80006d6e <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006c58:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006c5c:	00c7d683          	lhu	a3,12(a5)
    80006c60:	0016e693          	ori	a3,a3,1
    80006c64:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    80006c68:	f9842583          	lw	a1,-104(s0)
    80006c6c:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006c70:	0001e697          	auipc	a3,0x1e
    80006c74:	ed868693          	addi	a3,a3,-296 # 80024b48 <disk>
    80006c78:	00260793          	addi	a5,a2,2
    80006c7c:	0792                	slli	a5,a5,0x4
    80006c7e:	97b6                	add	a5,a5,a3
    80006c80:	587d                	li	a6,-1
    80006c82:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006c86:	0592                	slli	a1,a1,0x4
    80006c88:	952e                	add	a0,a0,a1
    80006c8a:	f9070713          	addi	a4,a4,-112
    80006c8e:	9736                	add	a4,a4,a3
    80006c90:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    80006c92:	6298                	ld	a4,0(a3)
    80006c94:	972e                	add	a4,a4,a1
    80006c96:	4585                	li	a1,1
    80006c98:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006c9a:	4509                	li	a0,2
    80006c9c:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    80006ca0:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006ca4:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006ca8:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006cac:	6698                	ld	a4,8(a3)
    80006cae:	00275783          	lhu	a5,2(a4)
    80006cb2:	8b9d                	andi	a5,a5,7
    80006cb4:	0786                	slli	a5,a5,0x1
    80006cb6:	97ba                	add	a5,a5,a4
    80006cb8:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    80006cbc:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006cc0:	6698                	ld	a4,8(a3)
    80006cc2:	00275783          	lhu	a5,2(a4)
    80006cc6:	2785                	addiw	a5,a5,1
    80006cc8:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006ccc:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006cd0:	100017b7          	lui	a5,0x10001
    80006cd4:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006cd8:	00492703          	lw	a4,4(s2)
    80006cdc:	4785                	li	a5,1
    80006cde:	02f71163          	bne	a4,a5,80006d00 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    80006ce2:	0001e997          	auipc	s3,0x1e
    80006ce6:	f8e98993          	addi	s3,s3,-114 # 80024c70 <disk+0x128>
  while(b->disk == 1) {
    80006cea:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006cec:	85ce                	mv	a1,s3
    80006cee:	854a                	mv	a0,s2
    80006cf0:	ffffb097          	auipc	ra,0xffffb
    80006cf4:	754080e7          	jalr	1876(ra) # 80002444 <sleep>
  while(b->disk == 1) {
    80006cf8:	00492783          	lw	a5,4(s2)
    80006cfc:	fe9788e3          	beq	a5,s1,80006cec <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    80006d00:	f9042903          	lw	s2,-112(s0)
    80006d04:	00290793          	addi	a5,s2,2
    80006d08:	00479713          	slli	a4,a5,0x4
    80006d0c:	0001e797          	auipc	a5,0x1e
    80006d10:	e3c78793          	addi	a5,a5,-452 # 80024b48 <disk>
    80006d14:	97ba                	add	a5,a5,a4
    80006d16:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006d1a:	0001e997          	auipc	s3,0x1e
    80006d1e:	e2e98993          	addi	s3,s3,-466 # 80024b48 <disk>
    80006d22:	00491713          	slli	a4,s2,0x4
    80006d26:	0009b783          	ld	a5,0(s3)
    80006d2a:	97ba                	add	a5,a5,a4
    80006d2c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006d30:	854a                	mv	a0,s2
    80006d32:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006d36:	00000097          	auipc	ra,0x0
    80006d3a:	b70080e7          	jalr	-1168(ra) # 800068a6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006d3e:	8885                	andi	s1,s1,1
    80006d40:	f0ed                	bnez	s1,80006d22 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006d42:	0001e517          	auipc	a0,0x1e
    80006d46:	f2e50513          	addi	a0,a0,-210 # 80024c70 <disk+0x128>
    80006d4a:	ffffa097          	auipc	ra,0xffffa
    80006d4e:	f54080e7          	jalr	-172(ra) # 80000c9e <release>
}
    80006d52:	70a6                	ld	ra,104(sp)
    80006d54:	7406                	ld	s0,96(sp)
    80006d56:	64e6                	ld	s1,88(sp)
    80006d58:	6946                	ld	s2,80(sp)
    80006d5a:	69a6                	ld	s3,72(sp)
    80006d5c:	6a06                	ld	s4,64(sp)
    80006d5e:	7ae2                	ld	s5,56(sp)
    80006d60:	7b42                	ld	s6,48(sp)
    80006d62:	7ba2                	ld	s7,40(sp)
    80006d64:	7c02                	ld	s8,32(sp)
    80006d66:	6ce2                	ld	s9,24(sp)
    80006d68:	6d42                	ld	s10,16(sp)
    80006d6a:	6165                	addi	sp,sp,112
    80006d6c:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006d6e:	4689                	li	a3,2
    80006d70:	00d79623          	sh	a3,12(a5)
    80006d74:	b5e5                	j	80006c5c <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006d76:	f9042603          	lw	a2,-112(s0)
    80006d7a:	00a60713          	addi	a4,a2,10
    80006d7e:	0712                	slli	a4,a4,0x4
    80006d80:	0001e517          	auipc	a0,0x1e
    80006d84:	dd050513          	addi	a0,a0,-560 # 80024b50 <disk+0x8>
    80006d88:	953a                	add	a0,a0,a4
  if(write)
    80006d8a:	e60d14e3          	bnez	s10,80006bf2 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006d8e:	00a60793          	addi	a5,a2,10
    80006d92:	00479693          	slli	a3,a5,0x4
    80006d96:	0001e797          	auipc	a5,0x1e
    80006d9a:	db278793          	addi	a5,a5,-590 # 80024b48 <disk>
    80006d9e:	97b6                	add	a5,a5,a3
    80006da0:	0007a423          	sw	zero,8(a5)
    80006da4:	b595                	j	80006c08 <virtio_disk_rw+0xf0>

0000000080006da6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006da6:	1101                	addi	sp,sp,-32
    80006da8:	ec06                	sd	ra,24(sp)
    80006daa:	e822                	sd	s0,16(sp)
    80006dac:	e426                	sd	s1,8(sp)
    80006dae:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006db0:	0001e497          	auipc	s1,0x1e
    80006db4:	d9848493          	addi	s1,s1,-616 # 80024b48 <disk>
    80006db8:	0001e517          	auipc	a0,0x1e
    80006dbc:	eb850513          	addi	a0,a0,-328 # 80024c70 <disk+0x128>
    80006dc0:	ffffa097          	auipc	ra,0xffffa
    80006dc4:	e2a080e7          	jalr	-470(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006dc8:	10001737          	lui	a4,0x10001
    80006dcc:	533c                	lw	a5,96(a4)
    80006dce:	8b8d                	andi	a5,a5,3
    80006dd0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006dd2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006dd6:	689c                	ld	a5,16(s1)
    80006dd8:	0204d703          	lhu	a4,32(s1)
    80006ddc:	0027d783          	lhu	a5,2(a5)
    80006de0:	04f70863          	beq	a4,a5,80006e30 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006de4:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006de8:	6898                	ld	a4,16(s1)
    80006dea:	0204d783          	lhu	a5,32(s1)
    80006dee:	8b9d                	andi	a5,a5,7
    80006df0:	078e                	slli	a5,a5,0x3
    80006df2:	97ba                	add	a5,a5,a4
    80006df4:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006df6:	00278713          	addi	a4,a5,2
    80006dfa:	0712                	slli	a4,a4,0x4
    80006dfc:	9726                	add	a4,a4,s1
    80006dfe:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006e02:	e721                	bnez	a4,80006e4a <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006e04:	0789                	addi	a5,a5,2
    80006e06:	0792                	slli	a5,a5,0x4
    80006e08:	97a6                	add	a5,a5,s1
    80006e0a:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006e0c:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006e10:	ffffb097          	auipc	ra,0xffffb
    80006e14:	7e4080e7          	jalr	2020(ra) # 800025f4 <wakeup>

    disk.used_idx += 1;
    80006e18:	0204d783          	lhu	a5,32(s1)
    80006e1c:	2785                	addiw	a5,a5,1
    80006e1e:	17c2                	slli	a5,a5,0x30
    80006e20:	93c1                	srli	a5,a5,0x30
    80006e22:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006e26:	6898                	ld	a4,16(s1)
    80006e28:	00275703          	lhu	a4,2(a4)
    80006e2c:	faf71ce3          	bne	a4,a5,80006de4 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006e30:	0001e517          	auipc	a0,0x1e
    80006e34:	e4050513          	addi	a0,a0,-448 # 80024c70 <disk+0x128>
    80006e38:	ffffa097          	auipc	ra,0xffffa
    80006e3c:	e66080e7          	jalr	-410(ra) # 80000c9e <release>
}
    80006e40:	60e2                	ld	ra,24(sp)
    80006e42:	6442                	ld	s0,16(sp)
    80006e44:	64a2                	ld	s1,8(sp)
    80006e46:	6105                	addi	sp,sp,32
    80006e48:	8082                	ret
      panic("virtio_disk_intr status");
    80006e4a:	00003517          	auipc	a0,0x3
    80006e4e:	b8650513          	addi	a0,a0,-1146 # 800099d0 <syscalls+0x3f8>
    80006e52:	ffff9097          	auipc	ra,0xffff9
    80006e56:	6f2080e7          	jalr	1778(ra) # 80000544 <panic>

0000000080006e5a <sgenrand>:
static int mti=N+1; /* mti==N+1 means mt[N] is not initialized */

/* initializing the array with a NONZERO seed */
void
sgenrand(unsigned long seed)
{
    80006e5a:	1141                	addi	sp,sp,-16
    80006e5c:	e422                	sd	s0,8(sp)
    80006e5e:	0800                	addi	s0,sp,16
    /* setting initial seeds to mt[N] using         */
    /* the generator Line 25 of Table 1 in          */
    /* [KNUTH 1981, The Art of Computer Programming */
    /*    Vol. 2 (2nd Ed.), pp102]                  */
    mt[0]= seed & 0xffffffff;
    80006e60:	0001e717          	auipc	a4,0x1e
    80006e64:	e2870713          	addi	a4,a4,-472 # 80024c88 <mt>
    80006e68:	1502                	slli	a0,a0,0x20
    80006e6a:	9101                	srli	a0,a0,0x20
    80006e6c:	e308                	sd	a0,0(a4)
    for (mti=1; mti<N; mti++)
    80006e6e:	0001f597          	auipc	a1,0x1f
    80006e72:	19258593          	addi	a1,a1,402 # 80026000 <mt+0x1378>
        mt[mti] = (69069 * mt[mti-1]) & 0xffffffff;
    80006e76:	6645                	lui	a2,0x11
    80006e78:	dcd60613          	addi	a2,a2,-563 # 10dcd <_entry-0x7ffef233>
    80006e7c:	56fd                	li	a3,-1
    80006e7e:	9281                	srli	a3,a3,0x20
    80006e80:	631c                	ld	a5,0(a4)
    80006e82:	02c787b3          	mul	a5,a5,a2
    80006e86:	8ff5                	and	a5,a5,a3
    80006e88:	e71c                	sd	a5,8(a4)
    for (mti=1; mti<N; mti++)
    80006e8a:	0721                	addi	a4,a4,8
    80006e8c:	feb71ae3          	bne	a4,a1,80006e80 <sgenrand+0x26>
    80006e90:	27000793          	li	a5,624
    80006e94:	00003717          	auipc	a4,0x3
    80006e98:	b6f72a23          	sw	a5,-1164(a4) # 80009a08 <mti>
}
    80006e9c:	6422                	ld	s0,8(sp)
    80006e9e:	0141                	addi	sp,sp,16
    80006ea0:	8082                	ret

0000000080006ea2 <genrand>:

long /* for integer generation */
genrand()
{
    80006ea2:	1141                	addi	sp,sp,-16
    80006ea4:	e406                	sd	ra,8(sp)
    80006ea6:	e022                	sd	s0,0(sp)
    80006ea8:	0800                	addi	s0,sp,16
    unsigned long y;
    static unsigned long mag01[2]={0x0, MATRIX_A};
    /* mag01[x] = x * MATRIX_A  for x=0,1 */

    if (mti >= N) { /* generate N words at one time */
    80006eaa:	00003797          	auipc	a5,0x3
    80006eae:	b5e7a783          	lw	a5,-1186(a5) # 80009a08 <mti>
    80006eb2:	26f00713          	li	a4,623
    80006eb6:	0ef75963          	bge	a4,a5,80006fa8 <genrand+0x106>
        int kk;

        if (mti == N+1)   /* if sgenrand() has not been called, */
    80006eba:	27100713          	li	a4,625
    80006ebe:	12e78f63          	beq	a5,a4,80006ffc <genrand+0x15a>
            sgenrand(4357); /* a default initial seed is used   */

        for (kk=0;kk<N-M;kk++) {
    80006ec2:	0001e817          	auipc	a6,0x1e
    80006ec6:	dc680813          	addi	a6,a6,-570 # 80024c88 <mt>
    80006eca:	0001ee17          	auipc	t3,0x1e
    80006ece:	4d6e0e13          	addi	t3,t3,1238 # 800253a0 <mt+0x718>
{
    80006ed2:	8742                	mv	a4,a6
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    80006ed4:	4885                	li	a7,1
    80006ed6:	08fe                	slli	a7,a7,0x1f
    80006ed8:	80000537          	lui	a0,0x80000
    80006edc:	fff54513          	not	a0,a0
            mt[kk] = mt[kk+M] ^ (y >> 1) ^ mag01[y & 0x1];
    80006ee0:	6585                	lui	a1,0x1
    80006ee2:	c6858593          	addi	a1,a1,-920 # c68 <_entry-0x7ffff398>
    80006ee6:	00003317          	auipc	t1,0x3
    80006eea:	b0230313          	addi	t1,t1,-1278 # 800099e8 <mag01.985>
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    80006eee:	631c                	ld	a5,0(a4)
    80006ef0:	0117f7b3          	and	a5,a5,a7
    80006ef4:	6714                	ld	a3,8(a4)
    80006ef6:	8ee9                	and	a3,a3,a0
    80006ef8:	8fd5                	or	a5,a5,a3
            mt[kk] = mt[kk+M] ^ (y >> 1) ^ mag01[y & 0x1];
    80006efa:	00b70633          	add	a2,a4,a1
    80006efe:	0017d693          	srli	a3,a5,0x1
    80006f02:	6210                	ld	a2,0(a2)
    80006f04:	8eb1                	xor	a3,a3,a2
    80006f06:	8b85                	andi	a5,a5,1
    80006f08:	078e                	slli	a5,a5,0x3
    80006f0a:	979a                	add	a5,a5,t1
    80006f0c:	639c                	ld	a5,0(a5)
    80006f0e:	8fb5                	xor	a5,a5,a3
    80006f10:	e31c                	sd	a5,0(a4)
        for (kk=0;kk<N-M;kk++) {
    80006f12:	0721                	addi	a4,a4,8
    80006f14:	fdc71de3          	bne	a4,t3,80006eee <genrand+0x4c>
        }
        for (;kk<N-1;kk++) {
    80006f18:	6605                	lui	a2,0x1
    80006f1a:	c6060613          	addi	a2,a2,-928 # c60 <_entry-0x7ffff3a0>
    80006f1e:	9642                	add	a2,a2,a6
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    80006f20:	4505                	li	a0,1
    80006f22:	057e                	slli	a0,a0,0x1f
    80006f24:	800005b7          	lui	a1,0x80000
    80006f28:	fff5c593          	not	a1,a1
            mt[kk] = mt[kk+(M-N)] ^ (y >> 1) ^ mag01[y & 0x1];
    80006f2c:	00003897          	auipc	a7,0x3
    80006f30:	abc88893          	addi	a7,a7,-1348 # 800099e8 <mag01.985>
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    80006f34:	71883783          	ld	a5,1816(a6)
    80006f38:	8fe9                	and	a5,a5,a0
    80006f3a:	72083703          	ld	a4,1824(a6)
    80006f3e:	8f6d                	and	a4,a4,a1
    80006f40:	8fd9                	or	a5,a5,a4
            mt[kk] = mt[kk+(M-N)] ^ (y >> 1) ^ mag01[y & 0x1];
    80006f42:	0017d713          	srli	a4,a5,0x1
    80006f46:	00083683          	ld	a3,0(a6)
    80006f4a:	8f35                	xor	a4,a4,a3
    80006f4c:	8b85                	andi	a5,a5,1
    80006f4e:	078e                	slli	a5,a5,0x3
    80006f50:	97c6                	add	a5,a5,a7
    80006f52:	639c                	ld	a5,0(a5)
    80006f54:	8fb9                	xor	a5,a5,a4
    80006f56:	70f83c23          	sd	a5,1816(a6)
        for (;kk<N-1;kk++) {
    80006f5a:	0821                	addi	a6,a6,8
    80006f5c:	fcc81ce3          	bne	a6,a2,80006f34 <genrand+0x92>
        }
        y = (mt[N-1]&UPPER_MASK)|(mt[0]&LOWER_MASK);
    80006f60:	0001f697          	auipc	a3,0x1f
    80006f64:	d2868693          	addi	a3,a3,-728 # 80025c88 <mt+0x1000>
    80006f68:	3786b783          	ld	a5,888(a3)
    80006f6c:	4705                	li	a4,1
    80006f6e:	077e                	slli	a4,a4,0x1f
    80006f70:	8ff9                	and	a5,a5,a4
    80006f72:	0001e717          	auipc	a4,0x1e
    80006f76:	d1673703          	ld	a4,-746(a4) # 80024c88 <mt>
    80006f7a:	1706                	slli	a4,a4,0x21
    80006f7c:	9305                	srli	a4,a4,0x21
    80006f7e:	8fd9                	or	a5,a5,a4
        mt[N-1] = mt[M-1] ^ (y >> 1) ^ mag01[y & 0x1];
    80006f80:	0017d713          	srli	a4,a5,0x1
    80006f84:	c606b603          	ld	a2,-928(a3)
    80006f88:	8f31                	xor	a4,a4,a2
    80006f8a:	8b85                	andi	a5,a5,1
    80006f8c:	078e                	slli	a5,a5,0x3
    80006f8e:	00003617          	auipc	a2,0x3
    80006f92:	a5a60613          	addi	a2,a2,-1446 # 800099e8 <mag01.985>
    80006f96:	97b2                	add	a5,a5,a2
    80006f98:	639c                	ld	a5,0(a5)
    80006f9a:	8fb9                	xor	a5,a5,a4
    80006f9c:	36f6bc23          	sd	a5,888(a3)

        mti = 0;
    80006fa0:	00003797          	auipc	a5,0x3
    80006fa4:	a607a423          	sw	zero,-1432(a5) # 80009a08 <mti>
    }
  
    y = mt[mti++];
    80006fa8:	00003717          	auipc	a4,0x3
    80006fac:	a6070713          	addi	a4,a4,-1440 # 80009a08 <mti>
    80006fb0:	431c                	lw	a5,0(a4)
    80006fb2:	0017869b          	addiw	a3,a5,1
    80006fb6:	c314                	sw	a3,0(a4)
    80006fb8:	078e                	slli	a5,a5,0x3
    80006fba:	0001e717          	auipc	a4,0x1e
    80006fbe:	cce70713          	addi	a4,a4,-818 # 80024c88 <mt>
    80006fc2:	97ba                	add	a5,a5,a4
    80006fc4:	6398                	ld	a4,0(a5)
    y ^= TEMPERING_SHIFT_U(y);
    80006fc6:	00b75793          	srli	a5,a4,0xb
    80006fca:	8f3d                	xor	a4,a4,a5
    y ^= TEMPERING_SHIFT_S(y) & TEMPERING_MASK_B;
    80006fcc:	013a67b7          	lui	a5,0x13a6
    80006fd0:	8ad78793          	addi	a5,a5,-1875 # 13a58ad <_entry-0x7ec5a753>
    80006fd4:	8ff9                	and	a5,a5,a4
    80006fd6:	079e                	slli	a5,a5,0x7
    80006fd8:	8fb9                	xor	a5,a5,a4
    y ^= TEMPERING_SHIFT_T(y) & TEMPERING_MASK_C;
    80006fda:	00f79713          	slli	a4,a5,0xf
    80006fde:	077e36b7          	lui	a3,0x77e3
    80006fe2:	0696                	slli	a3,a3,0x5
    80006fe4:	8f75                	and	a4,a4,a3
    80006fe6:	8fb9                	xor	a5,a5,a4
    y ^= TEMPERING_SHIFT_L(y);
    80006fe8:	0127d513          	srli	a0,a5,0x12
    80006fec:	8fa9                	xor	a5,a5,a0

    // Strip off uppermost bit because we want a long,
    // not an unsigned long
    return y & RAND_MAX;
    80006fee:	02179513          	slli	a0,a5,0x21
}
    80006ff2:	9105                	srli	a0,a0,0x21
    80006ff4:	60a2                	ld	ra,8(sp)
    80006ff6:	6402                	ld	s0,0(sp)
    80006ff8:	0141                	addi	sp,sp,16
    80006ffa:	8082                	ret
            sgenrand(4357); /* a default initial seed is used   */
    80006ffc:	6505                	lui	a0,0x1
    80006ffe:	10550513          	addi	a0,a0,261 # 1105 <_entry-0x7fffeefb>
    80007002:	00000097          	auipc	ra,0x0
    80007006:	e58080e7          	jalr	-424(ra) # 80006e5a <sgenrand>
    8000700a:	bd65                	j	80006ec2 <genrand+0x20>

000000008000700c <random>:

// Assumes 0 <= max <= RAND_MAX
// Returns in the half-open interval [0, max]
long random(long max) {
    8000700c:	1101                	addi	sp,sp,-32
    8000700e:	ec06                	sd	ra,24(sp)
    80007010:	e822                	sd	s0,16(sp)
    80007012:	e426                	sd	s1,8(sp)
    80007014:	1000                	addi	s0,sp,32
    80007016:	84aa                	mv	s1,a0
    unsigned long random = (unsigned long)((long)genrand() % (max + 1)); 
    80007018:	00000097          	auipc	ra,0x0
    8000701c:	e8a080e7          	jalr	-374(ra) # 80006ea2 <genrand>
    80007020:	0485                	addi	s1,s1,1
    return random;
    80007022:	02956533          	rem	a0,a0,s1
    80007026:	60e2                	ld	ra,24(sp)
    80007028:	6442                	ld	s0,16(sp)
    8000702a:	64a2                	ld	s1,8(sp)
    8000702c:	6105                	addi	sp,sp,32
    8000702e:	8082                	ret
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
