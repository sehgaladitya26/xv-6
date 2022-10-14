
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	b9813103          	ld	sp,-1128(sp) # 80009b98 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000056:	b9e70713          	addi	a4,a4,-1122 # 80009bf0 <timer_scratch>
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
    80000064:	00007797          	auipc	a5,0x7
    80000068:	8ac78793          	addi	a5,a5,-1876 # 80006910 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd81a7>
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
    80000130:	930080e7          	jalr	-1744(ra) # 80002a5c <either_copyin>
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
    80000190:	ba450513          	addi	a0,a0,-1116 # 80011d30 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a56080e7          	jalr	-1450(ra) # 80000bea <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00012497          	auipc	s1,0x12
    800001a0:	b9448493          	addi	s1,s1,-1132 # 80011d30 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00012917          	auipc	s2,0x12
    800001aa:	c2290913          	addi	s2,s2,-990 # 80011dc8 <cons+0x98>
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
    800001c8:	a32080e7          	jalr	-1486(ra) # 80001bf6 <myproc>
    800001cc:	00002097          	auipc	ra,0x2
    800001d0:	6da080e7          	jalr	1754(ra) # 800028a6 <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	2cc080e7          	jalr	716(ra) # 800024a6 <sleep>
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
    8000021a:	7f0080e7          	jalr	2032(ra) # 80002a06 <either_copyout>
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
    8000022e:	b0650513          	addi	a0,a0,-1274 # 80011d30 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a6c080e7          	jalr	-1428(ra) # 80000c9e <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00012517          	auipc	a0,0x12
    80000244:	af050513          	addi	a0,a0,-1296 # 80011d30 <cons>
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
    8000027c:	b4f72823          	sw	a5,-1200(a4) # 80011dc8 <cons+0x98>
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
    800002d6:	a5e50513          	addi	a0,a0,-1442 # 80011d30 <cons>
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
    800002fc:	7ba080e7          	jalr	1978(ra) # 80002ab2 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00012517          	auipc	a0,0x12
    80000304:	a3050513          	addi	a0,a0,-1488 # 80011d30 <cons>
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
    80000328:	a0c70713          	addi	a4,a4,-1524 # 80011d30 <cons>
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
    80000352:	9e278793          	addi	a5,a5,-1566 # 80011d30 <cons>
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
    80000380:	a4c7a783          	lw	a5,-1460(a5) # 80011dc8 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00012717          	auipc	a4,0x12
    80000394:	9a070713          	addi	a4,a4,-1632 # 80011d30 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00012497          	auipc	s1,0x12
    800003a4:	99048493          	addi	s1,s1,-1648 # 80011d30 <cons>
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
    800003e0:	95470713          	addi	a4,a4,-1708 # 80011d30 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00012717          	auipc	a4,0x12
    800003f6:	9cf72f23          	sw	a5,-1570(a4) # 80011dd0 <cons+0xa0>
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
    8000041c:	91878793          	addi	a5,a5,-1768 # 80011d30 <cons>
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
    80000440:	98c7a823          	sw	a2,-1648(a5) # 80011dcc <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00012517          	auipc	a0,0x12
    80000448:	98450513          	addi	a0,a0,-1660 # 80011dc8 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	20a080e7          	jalr	522(ra) # 80002656 <wakeup>
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
    8000046a:	8ca50513          	addi	a0,a0,-1846 # 80011d30 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	6ec080e7          	jalr	1772(ra) # 80000b5a <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00024797          	auipc	a5,0x24
    80000482:	cc278793          	addi	a5,a5,-830 # 80024140 <devsw>
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
    80000554:	8a07a023          	sw	zero,-1888(a5) # 80011df0 <pr+0x18>
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
    80000588:	62f72623          	sw	a5,1580(a4) # 80009bb0 <panicked>
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
    800005c0:	00012d97          	auipc	s11,0x12
    800005c4:	830dad83          	lw	s11,-2000(s11) # 80011df0 <pr+0x18>
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
    80000602:	7da50513          	addi	a0,a0,2010 # 80011dd8 <pr>
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
    80000766:	67650513          	addi	a0,a0,1654 # 80011dd8 <pr>
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
    80000782:	65a48493          	addi	s1,s1,1626 # 80011dd8 <pr>
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
    800007e2:	61a50513          	addi	a0,a0,1562 # 80011df8 <uart_tx_lock>
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
    8000080e:	3a67a783          	lw	a5,934(a5) # 80009bb0 <panicked>
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
    8000084a:	37273703          	ld	a4,882(a4) # 80009bb8 <uart_tx_r>
    8000084e:	00009797          	auipc	a5,0x9
    80000852:	3727b783          	ld	a5,882(a5) # 80009bc0 <uart_tx_w>
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
    80000874:	588a0a13          	addi	s4,s4,1416 # 80011df8 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00009497          	auipc	s1,0x9
    8000087c:	34048493          	addi	s1,s1,832 # 80009bb8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00009997          	auipc	s3,0x9
    80000884:	34098993          	addi	s3,s3,832 # 80009bc0 <uart_tx_w>
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
    800008aa:	db0080e7          	jalr	-592(ra) # 80002656 <wakeup>
    
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
    800008e6:	51650513          	addi	a0,a0,1302 # 80011df8 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	300080e7          	jalr	768(ra) # 80000bea <acquire>
  if(panicked){
    800008f2:	00009797          	auipc	a5,0x9
    800008f6:	2be7a783          	lw	a5,702(a5) # 80009bb0 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00009797          	auipc	a5,0x9
    80000900:	2c47b783          	ld	a5,708(a5) # 80009bc0 <uart_tx_w>
    80000904:	00009717          	auipc	a4,0x9
    80000908:	2b473703          	ld	a4,692(a4) # 80009bb8 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	4e8a0a13          	addi	s4,s4,1256 # 80011df8 <uart_tx_lock>
    80000918:	00009497          	auipc	s1,0x9
    8000091c:	2a048493          	addi	s1,s1,672 # 80009bb8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00009917          	auipc	s2,0x9
    80000924:	2a090913          	addi	s2,s2,672 # 80009bc0 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00002097          	auipc	ra,0x2
    80000934:	b76080e7          	jalr	-1162(ra) # 800024a6 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00011497          	auipc	s1,0x11
    8000094a:	4b248493          	addi	s1,s1,1202 # 80011df8 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00009717          	auipc	a4,0x9
    8000095e:	26f73323          	sd	a5,614(a4) # 80009bc0 <uart_tx_w>
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
    800009d4:	42848493          	addi	s1,s1,1064 # 80011df8 <uart_tx_lock>
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
    80000a12:	00026797          	auipc	a5,0x26
    80000a16:	c4678793          	addi	a5,a5,-954 # 80026658 <end>
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
    80000a36:	3fe90913          	addi	s2,s2,1022 # 80011e30 <kmem>
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
    80000ad2:	36250513          	addi	a0,a0,866 # 80011e30 <kmem>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	084080e7          	jalr	132(ra) # 80000b5a <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ade:	45c5                	li	a1,17
    80000ae0:	05ee                	slli	a1,a1,0x1b
    80000ae2:	00026517          	auipc	a0,0x26
    80000ae6:	b7650513          	addi	a0,a0,-1162 # 80026658 <end>
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
    80000b08:	32c48493          	addi	s1,s1,812 # 80011e30 <kmem>
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
    80000b20:	31450513          	addi	a0,a0,788 # 80011e30 <kmem>
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
    80000b4c:	2e850513          	addi	a0,a0,744 # 80011e30 <kmem>
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
    80000b88:	056080e7          	jalr	86(ra) # 80001bda <mycpu>
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
    80000bba:	024080e7          	jalr	36(ra) # 80001bda <mycpu>
    80000bbe:	5d3c                	lw	a5,120(a0)
    80000bc0:	cf89                	beqz	a5,80000bda <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bc2:	00001097          	auipc	ra,0x1
    80000bc6:	018080e7          	jalr	24(ra) # 80001bda <mycpu>
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
    80000bde:	000080e7          	jalr	ra # 80001bda <mycpu>
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
    80000c1e:	fc0080e7          	jalr	-64(ra) # 80001bda <mycpu>
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
    80000c4a:	f94080e7          	jalr	-108(ra) # 80001bda <mycpu>
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
    80000ea0:	d2e080e7          	jalr	-722(ra) # 80001bca <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ea4:	00009717          	auipc	a4,0x9
    80000ea8:	d2470713          	addi	a4,a4,-732 # 80009bc8 <started>
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
    80000ebc:	d12080e7          	jalr	-750(ra) # 80001bca <cpuid>
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
    80000ede:	d86080e7          	jalr	-634(ra) # 80002c60 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00006097          	auipc	ra,0x6
    80000ee6:	a6e080e7          	jalr	-1426(ra) # 80006950 <plicinithart>
  }

  scheduler();        
    80000eea:	00001097          	auipc	ra,0x1
    80000eee:	264080e7          	jalr	612(ra) # 8000214e <scheduler>
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
    80000f4e:	bcc080e7          	jalr	-1076(ra) # 80001b16 <procinit>
    trapinit();      // trap vectors
    80000f52:	00002097          	auipc	ra,0x2
    80000f56:	ce6080e7          	jalr	-794(ra) # 80002c38 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00002097          	auipc	ra,0x2
    80000f5e:	d06080e7          	jalr	-762(ra) # 80002c60 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00006097          	auipc	ra,0x6
    80000f66:	9d8080e7          	jalr	-1576(ra) # 8000693a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00006097          	auipc	ra,0x6
    80000f6e:	9e6080e7          	jalr	-1562(ra) # 80006950 <plicinithart>
    binit();         // buffer cache
    80000f72:	00003097          	auipc	ra,0x3
    80000f76:	b94080e7          	jalr	-1132(ra) # 80003b06 <binit>
    iinit();         // inode table
    80000f7a:	00003097          	auipc	ra,0x3
    80000f7e:	238080e7          	jalr	568(ra) # 800041b2 <iinit>
    fileinit();      // file table
    80000f82:	00004097          	auipc	ra,0x4
    80000f86:	1d6080e7          	jalr	470(ra) # 80005158 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00006097          	auipc	ra,0x6
    80000f8e:	ace080e7          	jalr	-1330(ra) # 80006a58 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	f9a080e7          	jalr	-102(ra) # 80001f2c <userinit>
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    started = 1;
    80000f9e:	4785                	li	a5,1
    80000fa0:	00009717          	auipc	a4,0x9
    80000fa4:	c2f72423          	sw	a5,-984(a4) # 80009bc8 <started>
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
    80000fb8:	c1c7b783          	ld	a5,-996(a5) # 80009bd0 <kernel_pagetable>
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
    8000124e:	836080e7          	jalr	-1994(ra) # 80001a80 <proc_mapstacks>
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
    80001274:	96a7b023          	sd	a0,-1696(a5) # 80009bd0 <kernel_pagetable>
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
    80001850:	1b452703          	lw	a4,436(a0)
  //printf("%d %d\n",queues[idx].back, queues[idx].length);
  if (queues[idx].length == NPROC)
    80001854:	21800793          	li	a5,536
    80001858:	02f706b3          	mul	a3,a4,a5
    8000185c:	00011797          	auipc	a5,0x11
    80001860:	a2478793          	addi	a5,a5,-1500 # 80012280 <queues>
    80001864:	97b6                	add	a5,a5,a3
    80001866:	4790                	lw	a2,8(a5)
    80001868:	04000793          	li	a5,64
    8000186c:	06f60a63          	beq	a2,a5,800018e0 <enqueue+0x90>
    panic("Full queue");

  queues[idx].procs[queues[idx].back] = process;
    80001870:	00011597          	auipc	a1,0x11
    80001874:	a1058593          	addi	a1,a1,-1520 # 80012280 <queues>
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
    800018b2:	9d278793          	addi	a5,a5,-1582 # 80012280 <queues>
    800018b6:	97ae                	add	a5,a5,a1
    800018b8:	c3d4                	sw	a3,4(a5)
  queues[idx].length++;
    800018ba:	21800793          	li	a5,536
    800018be:	02f70733          	mul	a4,a4,a5
    800018c2:	00011797          	auipc	a5,0x11
    800018c6:	9be78793          	addi	a5,a5,-1602 # 80012280 <queues>
    800018ca:	973e                	add	a4,a4,a5
    800018cc:	2605                	addiw	a2,a2,1
    800018ce:	c710                	sw	a2,8(a4)
  process->curr_rtime = 0;
    800018d0:	1a052e23          	sw	zero,444(a0)
  process->curr_wtime = 0;
    800018d4:	1c052023          	sw	zero,448(a0)
  process->in_queue = 1;
    800018d8:	4785                	li	a5,1
    800018da:	1af52c23          	sw	a5,440(a0)
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
    80001904:	98078793          	addi	a5,a5,-1664 # 80012280 <queues>
    80001908:	97b6                	add	a5,a5,a3
    8000190a:	0007a223          	sw	zero,4(a5)
    8000190e:	b775                	j	800018ba <enqueue+0x6a>

0000000080001910 <dequeue>:
  //printf("size: %d\n",q->size);
}

void dequeue(struct proc *process)
{
  int idx = process->priority;
    80001910:	1b452783          	lw	a5,436(a0)
  if (queues[idx].length == 0)
    80001914:	21800713          	li	a4,536
    80001918:	02e786b3          	mul	a3,a5,a4
    8000191c:	00011717          	auipc	a4,0x11
    80001920:	96470713          	addi	a4,a4,-1692 # 80012280 <queues>
    80001924:	9736                	add	a4,a4,a3
    80001926:	4718                	lw	a4,8(a4)
    80001928:	cb31                	beqz	a4,8000197c <dequeue+0x6c>
    panic("Empty queue");
  
  queues[idx].front++;
    8000192a:	21800693          	li	a3,536
    8000192e:	02d78633          	mul	a2,a5,a3
    80001932:	00011697          	auipc	a3,0x11
    80001936:	94e68693          	addi	a3,a3,-1714 # 80012280 <queues>
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
    80001958:	92c60613          	addi	a2,a2,-1748 # 80012280 <queues>
    8000195c:	962e                	add	a2,a2,a1
    8000195e:	c214                	sw	a3,0(a2)
  queues[idx].length--;
    80001960:	21800693          	li	a3,536
    80001964:	02d787b3          	mul	a5,a5,a3
    80001968:	00011697          	auipc	a3,0x11
    8000196c:	91868693          	addi	a3,a3,-1768 # 80012280 <queues>
    80001970:	97b6                	add	a5,a5,a3
    80001972:	377d                	addiw	a4,a4,-1
    80001974:	c798                	sw	a4,8(a5)
  process->in_queue = 0;
    80001976:	1a052c23          	sw	zero,440(a0)
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
    800019a0:	8e468693          	addi	a3,a3,-1820 # 80012280 <queues>
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
    800019b2:	1b452e03          	lw	t3,436(a0)
  int curr = queues[idx].front;
    800019b6:	21800793          	li	a5,536
    800019ba:	02fe0733          	mul	a4,t3,a5
    800019be:	00011797          	auipc	a5,0x11
    800019c2:	8c278793          	addi	a5,a5,-1854 # 80012280 <queues>
    800019c6:	97ba                	add	a5,a5,a4
    800019c8:	4398                	lw	a4,0(a5)
  int init_flag = 0;
  while (curr != queues[idx].back)
    800019ca:	0047a303          	lw	t1,4(a5)
    800019ce:	06670363          	beq	a4,t1,80001a34 <delqueue+0x88>
  int init_flag = 0;
    800019d2:	4e81                	li	t4,0
  {
    if(queues[idx].procs[curr]->pid == process->pid) init_flag = 1;
    800019d4:	00011617          	auipc	a2,0x11
    800019d8:	8ac60613          	addi	a2,a2,-1876 # 80012280 <queues>
    800019dc:	004e1693          	slli	a3,t3,0x4
    800019e0:	96f2                	add	a3,a3,t3
    800019e2:	068a                	slli	a3,a3,0x2
    800019e4:	41c686b3          	sub	a3,a3,t3
    if(init_flag == 1) {
      queues[idx].procs[curr] = queues[idx].procs[(curr + 1) % (NPROC + 1)];
    800019e8:	04100813          	li	a6,65
    800019ec:	4885                	li	a7,1
    800019ee:	a035                	j	80001a1a <delqueue+0x6e>
    800019f0:	0017079b          	addiw	a5,a4,1
    800019f4:	0307e7bb          	remw	a5,a5,a6
    800019f8:	97b6                	add	a5,a5,a3
    800019fa:	0789                	addi	a5,a5,2
    800019fc:	078e                	slli	a5,a5,0x3
    800019fe:	97b2                	add	a5,a5,a2
    80001a00:	638c                	ld	a1,0(a5)
    80001a02:	00e687b3          	add	a5,a3,a4
    80001a06:	0789                	addi	a5,a5,2
    80001a08:	078e                	slli	a5,a5,0x3
    80001a0a:	97b2                	add	a5,a5,a2
    80001a0c:	e38c                	sd	a1,0(a5)
    80001a0e:	8ec6                	mv	t4,a7
    }
    curr = (curr + 1) % (NPROC + 1);
    80001a10:	2705                	addiw	a4,a4,1
    80001a12:	0307673b          	remw	a4,a4,a6
  while (curr != queues[idx].back)
    80001a16:	00670f63          	beq	a4,t1,80001a34 <delqueue+0x88>
    if(queues[idx].procs[curr]->pid == process->pid) init_flag = 1;
    80001a1a:	00e687b3          	add	a5,a3,a4
    80001a1e:	0789                	addi	a5,a5,2
    80001a20:	078e                	slli	a5,a5,0x3
    80001a22:	97b2                	add	a5,a5,a2
    80001a24:	639c                	ld	a5,0(a5)
    80001a26:	5b8c                	lw	a1,48(a5)
    80001a28:	591c                	lw	a5,48(a0)
    80001a2a:	fcf583e3          	beq	a1,a5,800019f0 <delqueue+0x44>
    if(init_flag == 1) {
    80001a2e:	ff1e91e3          	bne	t4,a7,80001a10 <delqueue+0x64>
    80001a32:	bf7d                	j	800019f0 <delqueue+0x44>
  }
  process->curr_wtime = 0;
    80001a34:	1c052023          	sw	zero,448(a0)
  queues[idx].back--;
    80001a38:	21800793          	li	a5,536
    80001a3c:	02fe0733          	mul	a4,t3,a5
    80001a40:	00011797          	auipc	a5,0x11
    80001a44:	84078793          	addi	a5,a5,-1984 # 80012280 <queues>
    80001a48:	97ba                	add	a5,a5,a4
    80001a4a:	43d8                	lw	a4,4(a5)
    80001a4c:	377d                	addiw	a4,a4,-1
    80001a4e:	c3d8                	sw	a4,4(a5)
  queues[idx].length--;
    80001a50:	4794                	lw	a3,8(a5)
    80001a52:	36fd                	addiw	a3,a3,-1
    80001a54:	c794                	sw	a3,8(a5)
  if (queues[idx].back < 0) queues[idx].back = NPROC;
    80001a56:	02071793          	slli	a5,a4,0x20
    80001a5a:	0007c563          	bltz	a5,80001a64 <delqueue+0xb8>
}
    80001a5e:	6422                	ld	s0,8(sp)
    80001a60:	0141                	addi	sp,sp,16
    80001a62:	8082                	ret
  if (queues[idx].back < 0) queues[idx].back = NPROC;
    80001a64:	21800793          	li	a5,536
    80001a68:	02fe0e33          	mul	t3,t3,a5
    80001a6c:	00011797          	auipc	a5,0x11
    80001a70:	81478793          	addi	a5,a5,-2028 # 80012280 <queues>
    80001a74:	9e3e                	add	t3,t3,a5
    80001a76:	04000793          	li	a5,64
    80001a7a:	00fe2223          	sw	a5,4(t3)
}
    80001a7e:	b7c5                	j	80001a5e <delqueue+0xb2>

0000000080001a80 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001a80:	7139                	addi	sp,sp,-64
    80001a82:	fc06                	sd	ra,56(sp)
    80001a84:	f822                	sd	s0,48(sp)
    80001a86:	f426                	sd	s1,40(sp)
    80001a88:	f04a                	sd	s2,32(sp)
    80001a8a:	ec4e                	sd	s3,24(sp)
    80001a8c:	e852                	sd	s4,16(sp)
    80001a8e:	e456                	sd	s5,8(sp)
    80001a90:	e05a                	sd	s6,0(sp)
    80001a92:	0080                	addi	s0,sp,64
    80001a94:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a96:	00011497          	auipc	s1,0x11
    80001a9a:	26248493          	addi	s1,s1,610 # 80012cf8 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001a9e:	8b26                	mv	s6,s1
    80001aa0:	00007a97          	auipc	s5,0x7
    80001aa4:	560a8a93          	addi	s5,s5,1376 # 80009000 <etext>
    80001aa8:	04000937          	lui	s2,0x4000
    80001aac:	197d                	addi	s2,s2,-1
    80001aae:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ab0:	00018a17          	auipc	s4,0x18
    80001ab4:	448a0a13          	addi	s4,s4,1096 # 80019ef8 <tickslock>
    char *pa = kalloc();
    80001ab8:	fffff097          	auipc	ra,0xfffff
    80001abc:	042080e7          	jalr	66(ra) # 80000afa <kalloc>
    80001ac0:	862a                	mv	a2,a0
    if(pa == 0)
    80001ac2:	c131                	beqz	a0,80001b06 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001ac4:	416485b3          	sub	a1,s1,s6
    80001ac8:	858d                	srai	a1,a1,0x3
    80001aca:	000ab783          	ld	a5,0(s5)
    80001ace:	02f585b3          	mul	a1,a1,a5
    80001ad2:	2585                	addiw	a1,a1,1
    80001ad4:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001ad8:	4719                	li	a4,6
    80001ada:	6685                	lui	a3,0x1
    80001adc:	40b905b3          	sub	a1,s2,a1
    80001ae0:	854e                	mv	a0,s3
    80001ae2:	fffff097          	auipc	ra,0xfffff
    80001ae6:	678080e7          	jalr	1656(ra) # 8000115a <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001aea:	1c848493          	addi	s1,s1,456
    80001aee:	fd4495e3          	bne	s1,s4,80001ab8 <proc_mapstacks+0x38>
  }
}
    80001af2:	70e2                	ld	ra,56(sp)
    80001af4:	7442                	ld	s0,48(sp)
    80001af6:	74a2                	ld	s1,40(sp)
    80001af8:	7902                	ld	s2,32(sp)
    80001afa:	69e2                	ld	s3,24(sp)
    80001afc:	6a42                	ld	s4,16(sp)
    80001afe:	6aa2                	ld	s5,8(sp)
    80001b00:	6b02                	ld	s6,0(sp)
    80001b02:	6121                	addi	sp,sp,64
    80001b04:	8082                	ret
      panic("kalloc");
    80001b06:	00007517          	auipc	a0,0x7
    80001b0a:	6f250513          	addi	a0,a0,1778 # 800091f8 <digits+0x1b8>
    80001b0e:	fffff097          	auipc	ra,0xfffff
    80001b12:	a36080e7          	jalr	-1482(ra) # 80000544 <panic>

0000000080001b16 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001b16:	7139                	addi	sp,sp,-64
    80001b18:	fc06                	sd	ra,56(sp)
    80001b1a:	f822                	sd	s0,48(sp)
    80001b1c:	f426                	sd	s1,40(sp)
    80001b1e:	f04a                	sd	s2,32(sp)
    80001b20:	ec4e                	sd	s3,24(sp)
    80001b22:	e852                	sd	s4,16(sp)
    80001b24:	e456                	sd	s5,8(sp)
    80001b26:	e05a                	sd	s6,0(sp)
    80001b28:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001b2a:	00007597          	auipc	a1,0x7
    80001b2e:	6d658593          	addi	a1,a1,1750 # 80009200 <digits+0x1c0>
    80001b32:	00010517          	auipc	a0,0x10
    80001b36:	31e50513          	addi	a0,a0,798 # 80011e50 <pid_lock>
    80001b3a:	fffff097          	auipc	ra,0xfffff
    80001b3e:	020080e7          	jalr	32(ra) # 80000b5a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001b42:	00007597          	auipc	a1,0x7
    80001b46:	6c658593          	addi	a1,a1,1734 # 80009208 <digits+0x1c8>
    80001b4a:	00010517          	auipc	a0,0x10
    80001b4e:	31e50513          	addi	a0,a0,798 # 80011e68 <wait_lock>
    80001b52:	fffff097          	auipc	ra,0xfffff
    80001b56:	008080e7          	jalr	8(ra) # 80000b5a <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b5a:	00011497          	auipc	s1,0x11
    80001b5e:	19e48493          	addi	s1,s1,414 # 80012cf8 <proc>
      initlock(&p->lock, "proc");
    80001b62:	00007b17          	auipc	s6,0x7
    80001b66:	6b6b0b13          	addi	s6,s6,1718 # 80009218 <digits+0x1d8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001b6a:	8aa6                	mv	s5,s1
    80001b6c:	00007a17          	auipc	s4,0x7
    80001b70:	494a0a13          	addi	s4,s4,1172 # 80009000 <etext>
    80001b74:	04000937          	lui	s2,0x4000
    80001b78:	197d                	addi	s2,s2,-1
    80001b7a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b7c:	00018997          	auipc	s3,0x18
    80001b80:	37c98993          	addi	s3,s3,892 # 80019ef8 <tickslock>
      initlock(&p->lock, "proc");
    80001b84:	85da                	mv	a1,s6
    80001b86:	8526                	mv	a0,s1
    80001b88:	fffff097          	auipc	ra,0xfffff
    80001b8c:	fd2080e7          	jalr	-46(ra) # 80000b5a <initlock>
      p->state = UNUSED;
    80001b90:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001b94:	415487b3          	sub	a5,s1,s5
    80001b98:	878d                	srai	a5,a5,0x3
    80001b9a:	000a3703          	ld	a4,0(s4)
    80001b9e:	02e787b3          	mul	a5,a5,a4
    80001ba2:	2785                	addiw	a5,a5,1
    80001ba4:	00d7979b          	slliw	a5,a5,0xd
    80001ba8:	40f907b3          	sub	a5,s2,a5
    80001bac:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bae:	1c848493          	addi	s1,s1,456
    80001bb2:	fd3499e3          	bne	s1,s3,80001b84 <procinit+0x6e>
  }
}
    80001bb6:	70e2                	ld	ra,56(sp)
    80001bb8:	7442                	ld	s0,48(sp)
    80001bba:	74a2                	ld	s1,40(sp)
    80001bbc:	7902                	ld	s2,32(sp)
    80001bbe:	69e2                	ld	s3,24(sp)
    80001bc0:	6a42                	ld	s4,16(sp)
    80001bc2:	6aa2                	ld	s5,8(sp)
    80001bc4:	6b02                	ld	s6,0(sp)
    80001bc6:	6121                	addi	sp,sp,64
    80001bc8:	8082                	ret

0000000080001bca <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001bca:	1141                	addi	sp,sp,-16
    80001bcc:	e422                	sd	s0,8(sp)
    80001bce:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001bd0:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001bd2:	2501                	sext.w	a0,a0
    80001bd4:	6422                	ld	s0,8(sp)
    80001bd6:	0141                	addi	sp,sp,16
    80001bd8:	8082                	ret

0000000080001bda <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001bda:	1141                	addi	sp,sp,-16
    80001bdc:	e422                	sd	s0,8(sp)
    80001bde:	0800                	addi	s0,sp,16
    80001be0:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001be2:	2781                	sext.w	a5,a5
    80001be4:	079e                	slli	a5,a5,0x7
  return c;
}
    80001be6:	00010517          	auipc	a0,0x10
    80001bea:	29a50513          	addi	a0,a0,666 # 80011e80 <cpus>
    80001bee:	953e                	add	a0,a0,a5
    80001bf0:	6422                	ld	s0,8(sp)
    80001bf2:	0141                	addi	sp,sp,16
    80001bf4:	8082                	ret

0000000080001bf6 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001bf6:	1101                	addi	sp,sp,-32
    80001bf8:	ec06                	sd	ra,24(sp)
    80001bfa:	e822                	sd	s0,16(sp)
    80001bfc:	e426                	sd	s1,8(sp)
    80001bfe:	1000                	addi	s0,sp,32
  push_off();
    80001c00:	fffff097          	auipc	ra,0xfffff
    80001c04:	f9e080e7          	jalr	-98(ra) # 80000b9e <push_off>
    80001c08:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001c0a:	2781                	sext.w	a5,a5
    80001c0c:	079e                	slli	a5,a5,0x7
    80001c0e:	00010717          	auipc	a4,0x10
    80001c12:	24270713          	addi	a4,a4,578 # 80011e50 <pid_lock>
    80001c16:	97ba                	add	a5,a5,a4
    80001c18:	7b84                	ld	s1,48(a5)
  pop_off();
    80001c1a:	fffff097          	auipc	ra,0xfffff
    80001c1e:	024080e7          	jalr	36(ra) # 80000c3e <pop_off>
  return p;
}
    80001c22:	8526                	mv	a0,s1
    80001c24:	60e2                	ld	ra,24(sp)
    80001c26:	6442                	ld	s0,16(sp)
    80001c28:	64a2                	ld	s1,8(sp)
    80001c2a:	6105                	addi	sp,sp,32
    80001c2c:	8082                	ret

0000000080001c2e <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001c2e:	1141                	addi	sp,sp,-16
    80001c30:	e406                	sd	ra,8(sp)
    80001c32:	e022                	sd	s0,0(sp)
    80001c34:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001c36:	00000097          	auipc	ra,0x0
    80001c3a:	fc0080e7          	jalr	-64(ra) # 80001bf6 <myproc>
    80001c3e:	fffff097          	auipc	ra,0xfffff
    80001c42:	060080e7          	jalr	96(ra) # 80000c9e <release>

  if (first) {
    80001c46:	00008797          	auipc	a5,0x8
    80001c4a:	e0a7a783          	lw	a5,-502(a5) # 80009a50 <first.1767>
    80001c4e:	eb89                	bnez	a5,80001c60 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001c50:	00001097          	auipc	ra,0x1
    80001c54:	028080e7          	jalr	40(ra) # 80002c78 <usertrapret>
}
    80001c58:	60a2                	ld	ra,8(sp)
    80001c5a:	6402                	ld	s0,0(sp)
    80001c5c:	0141                	addi	sp,sp,16
    80001c5e:	8082                	ret
    first = 0;
    80001c60:	00008797          	auipc	a5,0x8
    80001c64:	de07a823          	sw	zero,-528(a5) # 80009a50 <first.1767>
    fsinit(ROOTDEV);
    80001c68:	4505                	li	a0,1
    80001c6a:	00002097          	auipc	ra,0x2
    80001c6e:	4c8080e7          	jalr	1224(ra) # 80004132 <fsinit>
    80001c72:	bff9                	j	80001c50 <forkret+0x22>

0000000080001c74 <allocpid>:
{
    80001c74:	1101                	addi	sp,sp,-32
    80001c76:	ec06                	sd	ra,24(sp)
    80001c78:	e822                	sd	s0,16(sp)
    80001c7a:	e426                	sd	s1,8(sp)
    80001c7c:	e04a                	sd	s2,0(sp)
    80001c7e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001c80:	00010917          	auipc	s2,0x10
    80001c84:	1d090913          	addi	s2,s2,464 # 80011e50 <pid_lock>
    80001c88:	854a                	mv	a0,s2
    80001c8a:	fffff097          	auipc	ra,0xfffff
    80001c8e:	f60080e7          	jalr	-160(ra) # 80000bea <acquire>
  pid = nextpid;
    80001c92:	00008797          	auipc	a5,0x8
    80001c96:	dc278793          	addi	a5,a5,-574 # 80009a54 <nextpid>
    80001c9a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c9c:	0014871b          	addiw	a4,s1,1
    80001ca0:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ca2:	854a                	mv	a0,s2
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	ffa080e7          	jalr	-6(ra) # 80000c9e <release>
}
    80001cac:	8526                	mv	a0,s1
    80001cae:	60e2                	ld	ra,24(sp)
    80001cb0:	6442                	ld	s0,16(sp)
    80001cb2:	64a2                	ld	s1,8(sp)
    80001cb4:	6902                	ld	s2,0(sp)
    80001cb6:	6105                	addi	sp,sp,32
    80001cb8:	8082                	ret

0000000080001cba <proc_pagetable>:
{
    80001cba:	1101                	addi	sp,sp,-32
    80001cbc:	ec06                	sd	ra,24(sp)
    80001cbe:	e822                	sd	s0,16(sp)
    80001cc0:	e426                	sd	s1,8(sp)
    80001cc2:	e04a                	sd	s2,0(sp)
    80001cc4:	1000                	addi	s0,sp,32
    80001cc6:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001cc8:	fffff097          	auipc	ra,0xfffff
    80001ccc:	67c080e7          	jalr	1660(ra) # 80001344 <uvmcreate>
    80001cd0:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001cd2:	c121                	beqz	a0,80001d12 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001cd4:	4729                	li	a4,10
    80001cd6:	00006697          	auipc	a3,0x6
    80001cda:	32a68693          	addi	a3,a3,810 # 80008000 <_trampoline>
    80001cde:	6605                	lui	a2,0x1
    80001ce0:	040005b7          	lui	a1,0x4000
    80001ce4:	15fd                	addi	a1,a1,-1
    80001ce6:	05b2                	slli	a1,a1,0xc
    80001ce8:	fffff097          	auipc	ra,0xfffff
    80001cec:	3d2080e7          	jalr	978(ra) # 800010ba <mappages>
    80001cf0:	02054863          	bltz	a0,80001d20 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001cf4:	4719                	li	a4,6
    80001cf6:	05893683          	ld	a3,88(s2)
    80001cfa:	6605                	lui	a2,0x1
    80001cfc:	020005b7          	lui	a1,0x2000
    80001d00:	15fd                	addi	a1,a1,-1
    80001d02:	05b6                	slli	a1,a1,0xd
    80001d04:	8526                	mv	a0,s1
    80001d06:	fffff097          	auipc	ra,0xfffff
    80001d0a:	3b4080e7          	jalr	948(ra) # 800010ba <mappages>
    80001d0e:	02054163          	bltz	a0,80001d30 <proc_pagetable+0x76>
}
    80001d12:	8526                	mv	a0,s1
    80001d14:	60e2                	ld	ra,24(sp)
    80001d16:	6442                	ld	s0,16(sp)
    80001d18:	64a2                	ld	s1,8(sp)
    80001d1a:	6902                	ld	s2,0(sp)
    80001d1c:	6105                	addi	sp,sp,32
    80001d1e:	8082                	ret
    uvmfree(pagetable, 0);
    80001d20:	4581                	li	a1,0
    80001d22:	8526                	mv	a0,s1
    80001d24:	00000097          	auipc	ra,0x0
    80001d28:	824080e7          	jalr	-2012(ra) # 80001548 <uvmfree>
    return 0;
    80001d2c:	4481                	li	s1,0
    80001d2e:	b7d5                	j	80001d12 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d30:	4681                	li	a3,0
    80001d32:	4605                	li	a2,1
    80001d34:	040005b7          	lui	a1,0x4000
    80001d38:	15fd                	addi	a1,a1,-1
    80001d3a:	05b2                	slli	a1,a1,0xc
    80001d3c:	8526                	mv	a0,s1
    80001d3e:	fffff097          	auipc	ra,0xfffff
    80001d42:	542080e7          	jalr	1346(ra) # 80001280 <uvmunmap>
    uvmfree(pagetable, 0);
    80001d46:	4581                	li	a1,0
    80001d48:	8526                	mv	a0,s1
    80001d4a:	fffff097          	auipc	ra,0xfffff
    80001d4e:	7fe080e7          	jalr	2046(ra) # 80001548 <uvmfree>
    return 0;
    80001d52:	4481                	li	s1,0
    80001d54:	bf7d                	j	80001d12 <proc_pagetable+0x58>

0000000080001d56 <proc_freepagetable>:
{
    80001d56:	1101                	addi	sp,sp,-32
    80001d58:	ec06                	sd	ra,24(sp)
    80001d5a:	e822                	sd	s0,16(sp)
    80001d5c:	e426                	sd	s1,8(sp)
    80001d5e:	e04a                	sd	s2,0(sp)
    80001d60:	1000                	addi	s0,sp,32
    80001d62:	84aa                	mv	s1,a0
    80001d64:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d66:	4681                	li	a3,0
    80001d68:	4605                	li	a2,1
    80001d6a:	040005b7          	lui	a1,0x4000
    80001d6e:	15fd                	addi	a1,a1,-1
    80001d70:	05b2                	slli	a1,a1,0xc
    80001d72:	fffff097          	auipc	ra,0xfffff
    80001d76:	50e080e7          	jalr	1294(ra) # 80001280 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d7a:	4681                	li	a3,0
    80001d7c:	4605                	li	a2,1
    80001d7e:	020005b7          	lui	a1,0x2000
    80001d82:	15fd                	addi	a1,a1,-1
    80001d84:	05b6                	slli	a1,a1,0xd
    80001d86:	8526                	mv	a0,s1
    80001d88:	fffff097          	auipc	ra,0xfffff
    80001d8c:	4f8080e7          	jalr	1272(ra) # 80001280 <uvmunmap>
  uvmfree(pagetable, sz);
    80001d90:	85ca                	mv	a1,s2
    80001d92:	8526                	mv	a0,s1
    80001d94:	fffff097          	auipc	ra,0xfffff
    80001d98:	7b4080e7          	jalr	1972(ra) # 80001548 <uvmfree>
}
    80001d9c:	60e2                	ld	ra,24(sp)
    80001d9e:	6442                	ld	s0,16(sp)
    80001da0:	64a2                	ld	s1,8(sp)
    80001da2:	6902                	ld	s2,0(sp)
    80001da4:	6105                	addi	sp,sp,32
    80001da6:	8082                	ret

0000000080001da8 <freeproc>:
{
    80001da8:	1101                	addi	sp,sp,-32
    80001daa:	ec06                	sd	ra,24(sp)
    80001dac:	e822                	sd	s0,16(sp)
    80001dae:	e426                	sd	s1,8(sp)
    80001db0:	1000                	addi	s0,sp,32
    80001db2:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001db4:	6d28                	ld	a0,88(a0)
    80001db6:	c509                	beqz	a0,80001dc0 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001db8:	fffff097          	auipc	ra,0xfffff
    80001dbc:	c46080e7          	jalr	-954(ra) # 800009fe <kfree>
  p->trapframe = 0;
    80001dc0:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001dc4:	68a8                	ld	a0,80(s1)
    80001dc6:	c511                	beqz	a0,80001dd2 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001dc8:	64ac                	ld	a1,72(s1)
    80001dca:	00000097          	auipc	ra,0x0
    80001dce:	f8c080e7          	jalr	-116(ra) # 80001d56 <proc_freepagetable>
  p->pagetable = 0;
    80001dd2:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001dd6:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001dda:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001dde:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001de2:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001de6:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001dea:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001dee:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001df2:	0004ac23          	sw	zero,24(s1)
  p->etime = 0;
    80001df6:	1604a823          	sw	zero,368(s1)
  p->rtime = 0;
    80001dfa:	1604a423          	sw	zero,360(s1)
  p->ctime = 0;
    80001dfe:	1604a623          	sw	zero,364(s1)
}
    80001e02:	60e2                	ld	ra,24(sp)
    80001e04:	6442                	ld	s0,16(sp)
    80001e06:	64a2                	ld	s1,8(sp)
    80001e08:	6105                	addi	sp,sp,32
    80001e0a:	8082                	ret

0000000080001e0c <allocproc>:
{
    80001e0c:	1101                	addi	sp,sp,-32
    80001e0e:	ec06                	sd	ra,24(sp)
    80001e10:	e822                	sd	s0,16(sp)
    80001e12:	e426                	sd	s1,8(sp)
    80001e14:	e04a                	sd	s2,0(sp)
    80001e16:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e18:	00011497          	auipc	s1,0x11
    80001e1c:	ee048493          	addi	s1,s1,-288 # 80012cf8 <proc>
    80001e20:	00018917          	auipc	s2,0x18
    80001e24:	0d890913          	addi	s2,s2,216 # 80019ef8 <tickslock>
    acquire(&p->lock);
    80001e28:	8526                	mv	a0,s1
    80001e2a:	fffff097          	auipc	ra,0xfffff
    80001e2e:	dc0080e7          	jalr	-576(ra) # 80000bea <acquire>
    if(p->state == UNUSED) {
    80001e32:	4c9c                	lw	a5,24(s1)
    80001e34:	cf81                	beqz	a5,80001e4c <allocproc+0x40>
      release(&p->lock);
    80001e36:	8526                	mv	a0,s1
    80001e38:	fffff097          	auipc	ra,0xfffff
    80001e3c:	e66080e7          	jalr	-410(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e40:	1c848493          	addi	s1,s1,456
    80001e44:	ff2492e3          	bne	s1,s2,80001e28 <allocproc+0x1c>
  return 0;
    80001e48:	4481                	li	s1,0
    80001e4a:	a055                	j	80001eee <allocproc+0xe2>
  p->pid = allocpid();
    80001e4c:	00000097          	auipc	ra,0x0
    80001e50:	e28080e7          	jalr	-472(ra) # 80001c74 <allocpid>
    80001e54:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001e56:	4705                	li	a4,1
    80001e58:	cc98                	sw	a4,24(s1)
  p->tick_creation_time = ticks;
    80001e5a:	00008797          	auipc	a5,0x8
    80001e5e:	d867a783          	lw	a5,-634(a5) # 80009be0 <ticks>
    80001e62:	18f4a823          	sw	a5,400(s1)
  p->tickets = 1;
    80001e66:	18e4aa23          	sw	a4,404(s1)
  p->priority_pbs = 60;
    80001e6a:	03c00713          	li	a4,60
    80001e6e:	1ae4a023          	sw	a4,416(s1)
  p->niceness_var = 5;
    80001e72:	4715                	li	a4,5
    80001e74:	1ae4a223          	sw	a4,420(s1)
  p->start_time_pbs = ticks;
    80001e78:	18f4ac23          	sw	a5,408(s1)
  p->number_times = 0;
    80001e7c:	1804ae23          	sw	zero,412(s1)
  p->last_run_time = 0;
    80001e80:	1a04a623          	sw	zero,428(s1)
  p->last_sleep_time = 0;
    80001e84:	1a04a423          	sw	zero,424(s1)
  p->priority = 0;
    80001e88:	1a04aa23          	sw	zero,436(s1)
  p->in_queue = 0;
    80001e8c:	1a04ac23          	sw	zero,440(s1)
  p->curr_rtime = 0;
    80001e90:	1a04ae23          	sw	zero,444(s1)
  p->curr_wtime = 0;
    80001e94:	1c04a023          	sw	zero,448(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001e98:	fffff097          	auipc	ra,0xfffff
    80001e9c:	c62080e7          	jalr	-926(ra) # 80000afa <kalloc>
    80001ea0:	892a                	mv	s2,a0
    80001ea2:	eca8                	sd	a0,88(s1)
    80001ea4:	cd21                	beqz	a0,80001efc <allocproc+0xf0>
  p->pagetable = proc_pagetable(p);
    80001ea6:	8526                	mv	a0,s1
    80001ea8:	00000097          	auipc	ra,0x0
    80001eac:	e12080e7          	jalr	-494(ra) # 80001cba <proc_pagetable>
    80001eb0:	892a                	mv	s2,a0
    80001eb2:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001eb4:	c125                	beqz	a0,80001f14 <allocproc+0x108>
  memset(&p->context, 0, sizeof(p->context));
    80001eb6:	07000613          	li	a2,112
    80001eba:	4581                	li	a1,0
    80001ebc:	06048513          	addi	a0,s1,96
    80001ec0:	fffff097          	auipc	ra,0xfffff
    80001ec4:	e26080e7          	jalr	-474(ra) # 80000ce6 <memset>
  p->context.ra = (uint64)forkret;
    80001ec8:	00000797          	auipc	a5,0x0
    80001ecc:	d6678793          	addi	a5,a5,-666 # 80001c2e <forkret>
    80001ed0:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001ed2:	60bc                	ld	a5,64(s1)
    80001ed4:	6705                	lui	a4,0x1
    80001ed6:	97ba                	add	a5,a5,a4
    80001ed8:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001eda:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001ede:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001ee2:	00008797          	auipc	a5,0x8
    80001ee6:	cfe7a783          	lw	a5,-770(a5) # 80009be0 <ticks>
    80001eea:	16f4a623          	sw	a5,364(s1)
}
    80001eee:	8526                	mv	a0,s1
    80001ef0:	60e2                	ld	ra,24(sp)
    80001ef2:	6442                	ld	s0,16(sp)
    80001ef4:	64a2                	ld	s1,8(sp)
    80001ef6:	6902                	ld	s2,0(sp)
    80001ef8:	6105                	addi	sp,sp,32
    80001efa:	8082                	ret
    freeproc(p);
    80001efc:	8526                	mv	a0,s1
    80001efe:	00000097          	auipc	ra,0x0
    80001f02:	eaa080e7          	jalr	-342(ra) # 80001da8 <freeproc>
    release(&p->lock);
    80001f06:	8526                	mv	a0,s1
    80001f08:	fffff097          	auipc	ra,0xfffff
    80001f0c:	d96080e7          	jalr	-618(ra) # 80000c9e <release>
    return 0;
    80001f10:	84ca                	mv	s1,s2
    80001f12:	bff1                	j	80001eee <allocproc+0xe2>
    freeproc(p);
    80001f14:	8526                	mv	a0,s1
    80001f16:	00000097          	auipc	ra,0x0
    80001f1a:	e92080e7          	jalr	-366(ra) # 80001da8 <freeproc>
    release(&p->lock);
    80001f1e:	8526                	mv	a0,s1
    80001f20:	fffff097          	auipc	ra,0xfffff
    80001f24:	d7e080e7          	jalr	-642(ra) # 80000c9e <release>
    return 0;
    80001f28:	84ca                	mv	s1,s2
    80001f2a:	b7d1                	j	80001eee <allocproc+0xe2>

0000000080001f2c <userinit>:
{
    80001f2c:	1101                	addi	sp,sp,-32
    80001f2e:	ec06                	sd	ra,24(sp)
    80001f30:	e822                	sd	s0,16(sp)
    80001f32:	e426                	sd	s1,8(sp)
    80001f34:	1000                	addi	s0,sp,32
  p = allocproc();
    80001f36:	00000097          	auipc	ra,0x0
    80001f3a:	ed6080e7          	jalr	-298(ra) # 80001e0c <allocproc>
    80001f3e:	84aa                	mv	s1,a0
  initproc = p;
    80001f40:	00008797          	auipc	a5,0x8
    80001f44:	c8a7bc23          	sd	a0,-872(a5) # 80009bd8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001f48:	03400613          	li	a2,52
    80001f4c:	00008597          	auipc	a1,0x8
    80001f50:	b1458593          	addi	a1,a1,-1260 # 80009a60 <initcode>
    80001f54:	6928                	ld	a0,80(a0)
    80001f56:	fffff097          	auipc	ra,0xfffff
    80001f5a:	41c080e7          	jalr	1052(ra) # 80001372 <uvmfirst>
  p->sz = PGSIZE;
    80001f5e:	6785                	lui	a5,0x1
    80001f60:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001f62:	6cb8                	ld	a4,88(s1)
    80001f64:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001f68:	6cb8                	ld	a4,88(s1)
    80001f6a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f6c:	4641                	li	a2,16
    80001f6e:	00007597          	auipc	a1,0x7
    80001f72:	2b258593          	addi	a1,a1,690 # 80009220 <digits+0x1e0>
    80001f76:	15848513          	addi	a0,s1,344
    80001f7a:	fffff097          	auipc	ra,0xfffff
    80001f7e:	ebe080e7          	jalr	-322(ra) # 80000e38 <safestrcpy>
  p->cwd = namei("/");
    80001f82:	00007517          	auipc	a0,0x7
    80001f86:	2ae50513          	addi	a0,a0,686 # 80009230 <digits+0x1f0>
    80001f8a:	00003097          	auipc	ra,0x3
    80001f8e:	bca080e7          	jalr	-1078(ra) # 80004b54 <namei>
    80001f92:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001f96:	478d                	li	a5,3
    80001f98:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001f9a:	8526                	mv	a0,s1
    80001f9c:	fffff097          	auipc	ra,0xfffff
    80001fa0:	d02080e7          	jalr	-766(ra) # 80000c9e <release>
}
    80001fa4:	60e2                	ld	ra,24(sp)
    80001fa6:	6442                	ld	s0,16(sp)
    80001fa8:	64a2                	ld	s1,8(sp)
    80001faa:	6105                	addi	sp,sp,32
    80001fac:	8082                	ret

0000000080001fae <growproc>:
{
    80001fae:	1101                	addi	sp,sp,-32
    80001fb0:	ec06                	sd	ra,24(sp)
    80001fb2:	e822                	sd	s0,16(sp)
    80001fb4:	e426                	sd	s1,8(sp)
    80001fb6:	e04a                	sd	s2,0(sp)
    80001fb8:	1000                	addi	s0,sp,32
    80001fba:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001fbc:	00000097          	auipc	ra,0x0
    80001fc0:	c3a080e7          	jalr	-966(ra) # 80001bf6 <myproc>
    80001fc4:	84aa                	mv	s1,a0
  sz = p->sz;
    80001fc6:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001fc8:	01204c63          	bgtz	s2,80001fe0 <growproc+0x32>
  } else if(n < 0){
    80001fcc:	02094663          	bltz	s2,80001ff8 <growproc+0x4a>
  p->sz = sz;
    80001fd0:	e4ac                	sd	a1,72(s1)
  return 0;
    80001fd2:	4501                	li	a0,0
}
    80001fd4:	60e2                	ld	ra,24(sp)
    80001fd6:	6442                	ld	s0,16(sp)
    80001fd8:	64a2                	ld	s1,8(sp)
    80001fda:	6902                	ld	s2,0(sp)
    80001fdc:	6105                	addi	sp,sp,32
    80001fde:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001fe0:	4691                	li	a3,4
    80001fe2:	00b90633          	add	a2,s2,a1
    80001fe6:	6928                	ld	a0,80(a0)
    80001fe8:	fffff097          	auipc	ra,0xfffff
    80001fec:	444080e7          	jalr	1092(ra) # 8000142c <uvmalloc>
    80001ff0:	85aa                	mv	a1,a0
    80001ff2:	fd79                	bnez	a0,80001fd0 <growproc+0x22>
      return -1;
    80001ff4:	557d                	li	a0,-1
    80001ff6:	bff9                	j	80001fd4 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001ff8:	00b90633          	add	a2,s2,a1
    80001ffc:	6928                	ld	a0,80(a0)
    80001ffe:	fffff097          	auipc	ra,0xfffff
    80002002:	3e6080e7          	jalr	998(ra) # 800013e4 <uvmdealloc>
    80002006:	85aa                	mv	a1,a0
    80002008:	b7e1                	j	80001fd0 <growproc+0x22>

000000008000200a <fork>:
{
    8000200a:	7179                	addi	sp,sp,-48
    8000200c:	f406                	sd	ra,40(sp)
    8000200e:	f022                	sd	s0,32(sp)
    80002010:	ec26                	sd	s1,24(sp)
    80002012:	e84a                	sd	s2,16(sp)
    80002014:	e44e                	sd	s3,8(sp)
    80002016:	e052                	sd	s4,0(sp)
    80002018:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000201a:	00000097          	auipc	ra,0x0
    8000201e:	bdc080e7          	jalr	-1060(ra) # 80001bf6 <myproc>
    80002022:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80002024:	00000097          	auipc	ra,0x0
    80002028:	de8080e7          	jalr	-536(ra) # 80001e0c <allocproc>
    8000202c:	10050f63          	beqz	a0,8000214a <fork+0x140>
    80002030:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002032:	04893603          	ld	a2,72(s2)
    80002036:	692c                	ld	a1,80(a0)
    80002038:	05093503          	ld	a0,80(s2)
    8000203c:	fffff097          	auipc	ra,0xfffff
    80002040:	544080e7          	jalr	1348(ra) # 80001580 <uvmcopy>
    80002044:	04054a63          	bltz	a0,80002098 <fork+0x8e>
  np->sz = p->sz;
    80002048:	04893783          	ld	a5,72(s2)
    8000204c:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80002050:	05893683          	ld	a3,88(s2)
    80002054:	87b6                	mv	a5,a3
    80002056:	0589b703          	ld	a4,88(s3)
    8000205a:	12068693          	addi	a3,a3,288
    8000205e:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002062:	6788                	ld	a0,8(a5)
    80002064:	6b8c                	ld	a1,16(a5)
    80002066:	6f90                	ld	a2,24(a5)
    80002068:	01073023          	sd	a6,0(a4)
    8000206c:	e708                	sd	a0,8(a4)
    8000206e:	eb0c                	sd	a1,16(a4)
    80002070:	ef10                	sd	a2,24(a4)
    80002072:	02078793          	addi	a5,a5,32
    80002076:	02070713          	addi	a4,a4,32
    8000207a:	fed792e3          	bne	a5,a3,8000205e <fork+0x54>
  np->trace_flag = p->trace_flag;
    8000207e:	17492783          	lw	a5,372(s2)
    80002082:	16f9aa23          	sw	a5,372(s3)
  np->trapframe->a0 = 0;
    80002086:	0589b783          	ld	a5,88(s3)
    8000208a:	0607b823          	sd	zero,112(a5)
    8000208e:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80002092:	15000a13          	li	s4,336
    80002096:	a03d                	j	800020c4 <fork+0xba>
    freeproc(np);
    80002098:	854e                	mv	a0,s3
    8000209a:	00000097          	auipc	ra,0x0
    8000209e:	d0e080e7          	jalr	-754(ra) # 80001da8 <freeproc>
    release(&np->lock);
    800020a2:	854e                	mv	a0,s3
    800020a4:	fffff097          	auipc	ra,0xfffff
    800020a8:	bfa080e7          	jalr	-1030(ra) # 80000c9e <release>
    return -1;
    800020ac:	5a7d                	li	s4,-1
    800020ae:	a069                	j	80002138 <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    800020b0:	00003097          	auipc	ra,0x3
    800020b4:	13a080e7          	jalr	314(ra) # 800051ea <filedup>
    800020b8:	009987b3          	add	a5,s3,s1
    800020bc:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    800020be:	04a1                	addi	s1,s1,8
    800020c0:	01448763          	beq	s1,s4,800020ce <fork+0xc4>
    if(p->ofile[i])
    800020c4:	009907b3          	add	a5,s2,s1
    800020c8:	6388                	ld	a0,0(a5)
    800020ca:	f17d                	bnez	a0,800020b0 <fork+0xa6>
    800020cc:	bfcd                	j	800020be <fork+0xb4>
  np->cwd = idup(p->cwd);
    800020ce:	15093503          	ld	a0,336(s2)
    800020d2:	00002097          	auipc	ra,0x2
    800020d6:	29e080e7          	jalr	670(ra) # 80004370 <idup>
    800020da:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800020de:	4641                	li	a2,16
    800020e0:	15890593          	addi	a1,s2,344
    800020e4:	15898513          	addi	a0,s3,344
    800020e8:	fffff097          	auipc	ra,0xfffff
    800020ec:	d50080e7          	jalr	-688(ra) # 80000e38 <safestrcpy>
  pid = np->pid;
    800020f0:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    800020f4:	854e                	mv	a0,s3
    800020f6:	fffff097          	auipc	ra,0xfffff
    800020fa:	ba8080e7          	jalr	-1112(ra) # 80000c9e <release>
  acquire(&wait_lock);
    800020fe:	00010497          	auipc	s1,0x10
    80002102:	d6a48493          	addi	s1,s1,-662 # 80011e68 <wait_lock>
    80002106:	8526                	mv	a0,s1
    80002108:	fffff097          	auipc	ra,0xfffff
    8000210c:	ae2080e7          	jalr	-1310(ra) # 80000bea <acquire>
  np->parent = p;
    80002110:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80002114:	8526                	mv	a0,s1
    80002116:	fffff097          	auipc	ra,0xfffff
    8000211a:	b88080e7          	jalr	-1144(ra) # 80000c9e <release>
  acquire(&np->lock);
    8000211e:	854e                	mv	a0,s3
    80002120:	fffff097          	auipc	ra,0xfffff
    80002124:	aca080e7          	jalr	-1334(ra) # 80000bea <acquire>
  np->state = RUNNABLE;
    80002128:	478d                	li	a5,3
    8000212a:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    8000212e:	854e                	mv	a0,s3
    80002130:	fffff097          	auipc	ra,0xfffff
    80002134:	b6e080e7          	jalr	-1170(ra) # 80000c9e <release>
}
    80002138:	8552                	mv	a0,s4
    8000213a:	70a2                	ld	ra,40(sp)
    8000213c:	7402                	ld	s0,32(sp)
    8000213e:	64e2                	ld	s1,24(sp)
    80002140:	6942                	ld	s2,16(sp)
    80002142:	69a2                	ld	s3,8(sp)
    80002144:	6a02                	ld	s4,0(sp)
    80002146:	6145                	addi	sp,sp,48
    80002148:	8082                	ret
    return -1;
    8000214a:	5a7d                	li	s4,-1
    8000214c:	b7f5                	j	80002138 <fork+0x12e>

000000008000214e <scheduler>:
{
    8000214e:	7175                	addi	sp,sp,-144
    80002150:	e506                	sd	ra,136(sp)
    80002152:	e122                	sd	s0,128(sp)
    80002154:	fca6                	sd	s1,120(sp)
    80002156:	f8ca                	sd	s2,112(sp)
    80002158:	f4ce                	sd	s3,104(sp)
    8000215a:	f0d2                	sd	s4,96(sp)
    8000215c:	ecd6                	sd	s5,88(sp)
    8000215e:	e8da                	sd	s6,80(sp)
    80002160:	e4de                	sd	s7,72(sp)
    80002162:	e0e2                	sd	s8,64(sp)
    80002164:	fc66                	sd	s9,56(sp)
    80002166:	f86a                	sd	s10,48(sp)
    80002168:	f46e                	sd	s11,40(sp)
    8000216a:	0900                	addi	s0,sp,144
    8000216c:	8792                	mv	a5,tp
  int id = r_tp();
    8000216e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002170:	00779693          	slli	a3,a5,0x7
    80002174:	00010717          	auipc	a4,0x10
    80002178:	cdc70713          	addi	a4,a4,-804 # 80011e50 <pid_lock>
    8000217c:	9736                	add	a4,a4,a3
    8000217e:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &proc_to_run->context);
    80002182:	00010717          	auipc	a4,0x10
    80002186:	d0670713          	addi	a4,a4,-762 # 80011e88 <cpus+0x8>
    8000218a:	9736                	add	a4,a4,a3
    8000218c:	f8e43023          	sd	a4,-128(s0)
      for (p = proc; p < &proc[NPROC]; p++)
    80002190:	00018a97          	auipc	s5,0x18
    80002194:	d68a8a93          	addi	s5,s5,-664 # 80019ef8 <tickslock>
          p = queues[i].procs[queues[i].front];
    80002198:	00010c17          	auipc	s8,0x10
    8000219c:	0e8c0c13          	addi	s8,s8,232 # 80012280 <queues>
        for(int j = 0; j < queues[i].length; j++)
    800021a0:	f8043423          	sd	zero,-120(s0)
        c->proc = proc_to_run;
    800021a4:	00010717          	auipc	a4,0x10
    800021a8:	cac70713          	addi	a4,a4,-852 # 80011e50 <pid_lock>
    800021ac:	00d707b3          	add	a5,a4,a3
    800021b0:	f6f43c23          	sd	a5,-136(s0)
    800021b4:	a8c9                	j	80002286 <scheduler+0x138>
          enqueue(p);
    800021b6:	8526                	mv	a0,s1
    800021b8:	fffff097          	auipc	ra,0xfffff
    800021bc:	698080e7          	jalr	1688(ra) # 80001850 <enqueue>
        release(&p->lock);
    800021c0:	8526                	mv	a0,s1
    800021c2:	fffff097          	auipc	ra,0xfffff
    800021c6:	adc080e7          	jalr	-1316(ra) # 80000c9e <release>
      for (p = proc; p < &proc[NPROC]; p++)
    800021ca:	1c848493          	addi	s1,s1,456
    800021ce:	01548e63          	beq	s1,s5,800021ea <scheduler+0x9c>
        acquire(&p->lock);
    800021d2:	8526                	mv	a0,s1
    800021d4:	fffff097          	auipc	ra,0xfffff
    800021d8:	a16080e7          	jalr	-1514(ra) # 80000bea <acquire>
        if (p->state == RUNNABLE && p->in_queue == 0)
    800021dc:	4c9c                	lw	a5,24(s1)
    800021de:	ff3791e3          	bne	a5,s3,800021c0 <scheduler+0x72>
    800021e2:	1b84a783          	lw	a5,440(s1)
    800021e6:	ffe9                	bnez	a5,800021c0 <scheduler+0x72>
    800021e8:	b7f9                	j	800021b6 <scheduler+0x68>
    800021ea:	00010d17          	auipc	s10,0x10
    800021ee:	09ed0d13          	addi	s10,s10,158 # 80012288 <queues+0x8>
      for (int i = 0; i < 5; i++)
    800021f2:	4c81                	li	s9,0
    800021f4:	a031                	j	80002200 <scheduler+0xb2>
    800021f6:	2c85                	addiw	s9,s9,1
    800021f8:	218d0d13          	addi	s10,s10,536
    800021fc:	09bc8763          	beq	s9,s11,8000228a <scheduler+0x13c>
        for(int j = 0; j < queues[i].length; j++)
    80002200:	8a6a                	mv	s4,s10
    80002202:	000d2783          	lw	a5,0(s10)
    80002206:	f8843903          	ld	s2,-120(s0)
    8000220a:	fef056e3          	blez	a5,800021f6 <scheduler+0xa8>
          p = queues[i].procs[queues[i].front];
    8000220e:	004c9b13          	slli	s6,s9,0x4
    80002212:	9b66                	add	s6,s6,s9
    80002214:	0b0a                	slli	s6,s6,0x2
    80002216:	419b0b33          	sub	s6,s6,s9
    8000221a:	ff8a2783          	lw	a5,-8(s4)
    8000221e:	97da                	add	a5,a5,s6
    80002220:	0789                	addi	a5,a5,2
    80002222:	078e                	slli	a5,a5,0x3
    80002224:	97e2                	add	a5,a5,s8
    80002226:	6384                	ld	s1,0(a5)
          acquire(&p->lock);
    80002228:	8526                	mv	a0,s1
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	9c0080e7          	jalr	-1600(ra) # 80000bea <acquire>
          dequeue(p);  // clear out all the processes as it goes through all the levels
    80002232:	8526                	mv	a0,s1
    80002234:	fffff097          	auipc	ra,0xfffff
    80002238:	6dc080e7          	jalr	1756(ra) # 80001910 <dequeue>
          p->in_queue = 0;
    8000223c:	1a04ac23          	sw	zero,440(s1)
          if (p->state == RUNNABLE)
    80002240:	4c9c                	lw	a5,24(s1)
    80002242:	01378d63          	beq	a5,s3,8000225c <scheduler+0x10e>
          release(&p->lock);
    80002246:	8526                	mv	a0,s1
    80002248:	fffff097          	auipc	ra,0xfffff
    8000224c:	a56080e7          	jalr	-1450(ra) # 80000c9e <release>
        for(int j = 0; j < queues[i].length; j++)
    80002250:	2905                	addiw	s2,s2,1
    80002252:	000a2783          	lw	a5,0(s4)
    80002256:	fcf942e3          	blt	s2,a5,8000221a <scheduler+0xcc>
    8000225a:	bf71                	j	800021f6 <scheduler+0xa8>
        proc_to_run->state = RUNNING;
    8000225c:	4791                	li	a5,4
    8000225e:	cc9c                	sw	a5,24(s1)
        c->proc = proc_to_run;
    80002260:	f7843903          	ld	s2,-136(s0)
    80002264:	02993823          	sd	s1,48(s2)
        swtch(&c->context, &proc_to_run->context);
    80002268:	06048593          	addi	a1,s1,96
    8000226c:	f8043503          	ld	a0,-128(s0)
    80002270:	00001097          	auipc	ra,0x1
    80002274:	95e080e7          	jalr	-1698(ra) # 80002bce <swtch>
        c->proc = 0;
    80002278:	02093823          	sd	zero,48(s2)
        release(&proc_to_run->lock);
    8000227c:	8526                	mv	a0,s1
    8000227e:	fffff097          	auipc	ra,0xfffff
    80002282:	a20080e7          	jalr	-1504(ra) # 80000c9e <release>
        if (p->state == RUNNABLE && p->in_queue == 0)
    80002286:	498d                	li	s3,3
      for (int i = 0; i < 5; i++)
    80002288:	4d95                	li	s11,5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000228a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000228e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002292:	10079073          	csrw	sstatus,a5
      for (p = proc; p < &proc[NPROC]; p++)
    80002296:	00011497          	auipc	s1,0x11
    8000229a:	a6248493          	addi	s1,s1,-1438 # 80012cf8 <proc>
    8000229e:	bf15                	j	800021d2 <scheduler+0x84>

00000000800022a0 <sched>:
{
    800022a0:	7179                	addi	sp,sp,-48
    800022a2:	f406                	sd	ra,40(sp)
    800022a4:	f022                	sd	s0,32(sp)
    800022a6:	ec26                	sd	s1,24(sp)
    800022a8:	e84a                	sd	s2,16(sp)
    800022aa:	e44e                	sd	s3,8(sp)
    800022ac:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800022ae:	00000097          	auipc	ra,0x0
    800022b2:	948080e7          	jalr	-1720(ra) # 80001bf6 <myproc>
    800022b6:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800022b8:	fffff097          	auipc	ra,0xfffff
    800022bc:	8b8080e7          	jalr	-1864(ra) # 80000b70 <holding>
    800022c0:	c93d                	beqz	a0,80002336 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022c2:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800022c4:	2781                	sext.w	a5,a5
    800022c6:	079e                	slli	a5,a5,0x7
    800022c8:	00010717          	auipc	a4,0x10
    800022cc:	b8870713          	addi	a4,a4,-1144 # 80011e50 <pid_lock>
    800022d0:	97ba                	add	a5,a5,a4
    800022d2:	0a87a703          	lw	a4,168(a5)
    800022d6:	4785                	li	a5,1
    800022d8:	06f71763          	bne	a4,a5,80002346 <sched+0xa6>
  if(p->state == RUNNING)
    800022dc:	4c98                	lw	a4,24(s1)
    800022de:	4791                	li	a5,4
    800022e0:	06f70b63          	beq	a4,a5,80002356 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022e4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800022e8:	8b89                	andi	a5,a5,2
  if(intr_get())
    800022ea:	efb5                	bnez	a5,80002366 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022ec:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800022ee:	00010917          	auipc	s2,0x10
    800022f2:	b6290913          	addi	s2,s2,-1182 # 80011e50 <pid_lock>
    800022f6:	2781                	sext.w	a5,a5
    800022f8:	079e                	slli	a5,a5,0x7
    800022fa:	97ca                	add	a5,a5,s2
    800022fc:	0ac7a983          	lw	s3,172(a5)
    80002300:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002302:	2781                	sext.w	a5,a5
    80002304:	079e                	slli	a5,a5,0x7
    80002306:	00010597          	auipc	a1,0x10
    8000230a:	b8258593          	addi	a1,a1,-1150 # 80011e88 <cpus+0x8>
    8000230e:	95be                	add	a1,a1,a5
    80002310:	06048513          	addi	a0,s1,96
    80002314:	00001097          	auipc	ra,0x1
    80002318:	8ba080e7          	jalr	-1862(ra) # 80002bce <swtch>
    8000231c:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000231e:	2781                	sext.w	a5,a5
    80002320:	079e                	slli	a5,a5,0x7
    80002322:	97ca                	add	a5,a5,s2
    80002324:	0b37a623          	sw	s3,172(a5)
}
    80002328:	70a2                	ld	ra,40(sp)
    8000232a:	7402                	ld	s0,32(sp)
    8000232c:	64e2                	ld	s1,24(sp)
    8000232e:	6942                	ld	s2,16(sp)
    80002330:	69a2                	ld	s3,8(sp)
    80002332:	6145                	addi	sp,sp,48
    80002334:	8082                	ret
    panic("sched p->lock");
    80002336:	00007517          	auipc	a0,0x7
    8000233a:	f0250513          	addi	a0,a0,-254 # 80009238 <digits+0x1f8>
    8000233e:	ffffe097          	auipc	ra,0xffffe
    80002342:	206080e7          	jalr	518(ra) # 80000544 <panic>
    panic("sched locks");
    80002346:	00007517          	auipc	a0,0x7
    8000234a:	f0250513          	addi	a0,a0,-254 # 80009248 <digits+0x208>
    8000234e:	ffffe097          	auipc	ra,0xffffe
    80002352:	1f6080e7          	jalr	502(ra) # 80000544 <panic>
    panic("sched running");
    80002356:	00007517          	auipc	a0,0x7
    8000235a:	f0250513          	addi	a0,a0,-254 # 80009258 <digits+0x218>
    8000235e:	ffffe097          	auipc	ra,0xffffe
    80002362:	1e6080e7          	jalr	486(ra) # 80000544 <panic>
    panic("sched interruptible");
    80002366:	00007517          	auipc	a0,0x7
    8000236a:	f0250513          	addi	a0,a0,-254 # 80009268 <digits+0x228>
    8000236e:	ffffe097          	auipc	ra,0xffffe
    80002372:	1d6080e7          	jalr	470(ra) # 80000544 <panic>

0000000080002376 <yield>:
{
    80002376:	1101                	addi	sp,sp,-32
    80002378:	ec06                	sd	ra,24(sp)
    8000237a:	e822                	sd	s0,16(sp)
    8000237c:	e426                	sd	s1,8(sp)
    8000237e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002380:	00000097          	auipc	ra,0x0
    80002384:	876080e7          	jalr	-1930(ra) # 80001bf6 <myproc>
    80002388:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000238a:	fffff097          	auipc	ra,0xfffff
    8000238e:	860080e7          	jalr	-1952(ra) # 80000bea <acquire>
  p->state = RUNNABLE;
    80002392:	478d                	li	a5,3
    80002394:	cc9c                	sw	a5,24(s1)
  sched();
    80002396:	00000097          	auipc	ra,0x0
    8000239a:	f0a080e7          	jalr	-246(ra) # 800022a0 <sched>
  release(&p->lock);
    8000239e:	8526                	mv	a0,s1
    800023a0:	fffff097          	auipc	ra,0xfffff
    800023a4:	8fe080e7          	jalr	-1794(ra) # 80000c9e <release>
}
    800023a8:	60e2                	ld	ra,24(sp)
    800023aa:	6442                	ld	s0,16(sp)
    800023ac:	64a2                	ld	s1,8(sp)
    800023ae:	6105                	addi	sp,sp,32
    800023b0:	8082                	ret

00000000800023b2 <update_time>:
{
    800023b2:	715d                	addi	sp,sp,-80
    800023b4:	e486                	sd	ra,72(sp)
    800023b6:	e0a2                	sd	s0,64(sp)
    800023b8:	fc26                	sd	s1,56(sp)
    800023ba:	f84a                	sd	s2,48(sp)
    800023bc:	f44e                	sd	s3,40(sp)
    800023be:	f052                	sd	s4,32(sp)
    800023c0:	ec56                	sd	s5,24(sp)
    800023c2:	e85a                	sd	s6,16(sp)
    800023c4:	e45e                	sd	s7,8(sp)
    800023c6:	e062                	sd	s8,0(sp)
    800023c8:	0880                	addi	s0,sp,80
  for(p = proc; p < &proc[NPROC]; p++){
    800023ca:	00011497          	auipc	s1,0x11
    800023ce:	92e48493          	addi	s1,s1,-1746 # 80012cf8 <proc>
    if(p->state == RUNNING) {
    800023d2:	4991                	li	s3,4
    else if(p->state == RUNNABLE) {
    800023d4:	4a0d                	li	s4,3
    if(p->curr_wtime >= 30 && p->state == RUNNABLE) {
    800023d6:	4af5                	li	s5,29
      printf("%d %d %d %d a\n", p->priority, p->pid, p->curr_rtime, ticks);
    800023d8:	00008b97          	auipc	s7,0x8
    800023dc:	808b8b93          	addi	s7,s7,-2040 # 80009be0 <ticks>
    800023e0:	00007b17          	auipc	s6,0x7
    800023e4:	ec0b0b13          	addi	s6,s6,-320 # 800092a0 <digits+0x260>
        printf("Aging Performed on pid: %d\n", p->pid);
    800023e8:	00007c17          	auipc	s8,0x7
    800023ec:	e98c0c13          	addi	s8,s8,-360 # 80009280 <digits+0x240>
  for(p = proc; p < &proc[NPROC]; p++){
    800023f0:	00018917          	auipc	s2,0x18
    800023f4:	b0890913          	addi	s2,s2,-1272 # 80019ef8 <tickslock>
    800023f8:	a025                	j	80002420 <update_time+0x6e>
      p->curr_rtime++;
    800023fa:	1bc4a783          	lw	a5,444(s1)
    800023fe:	2785                	addiw	a5,a5,1
    80002400:	1af4ae23          	sw	a5,444(s1)
      p->rtime++;
    80002404:	1684a783          	lw	a5,360(s1)
    80002408:	2785                	addiw	a5,a5,1
    8000240a:	16f4a423          	sw	a5,360(s1)
    release(&p->lock);
    8000240e:	8526                	mv	a0,s1
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	88e080e7          	jalr	-1906(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002418:	1c848493          	addi	s1,s1,456
    8000241c:	07248963          	beq	s1,s2,8000248e <update_time+0xdc>
    acquire(&p->lock);
    80002420:	8526                	mv	a0,s1
    80002422:	ffffe097          	auipc	ra,0xffffe
    80002426:	7c8080e7          	jalr	1992(ra) # 80000bea <acquire>
    if(p->state == RUNNING) {
    8000242a:	4c9c                	lw	a5,24(s1)
    8000242c:	fd3787e3          	beq	a5,s3,800023fa <update_time+0x48>
    else if(p->state == RUNNABLE) {
    80002430:	fd479fe3          	bne	a5,s4,8000240e <update_time+0x5c>
      p->curr_wtime++;
    80002434:	1c04a783          	lw	a5,448(s1)
    80002438:	2785                	addiw	a5,a5,1
    8000243a:	0007871b          	sext.w	a4,a5
    8000243e:	1cf4a023          	sw	a5,448(s1)
    if(p->curr_wtime >= 30 && p->state == RUNNABLE) {
    80002442:	fcead6e3          	bge	s5,a4,8000240e <update_time+0x5c>
      if(p->in_queue != 0) {
    80002446:	1b84a783          	lw	a5,440(s1)
    8000244a:	e785                	bnez	a5,80002472 <update_time+0xc0>
      if(p->priority != 0) {
    8000244c:	1b44a783          	lw	a5,436(s1)
    80002450:	c781                	beqz	a5,80002458 <update_time+0xa6>
        p->priority--;
    80002452:	37fd                	addiw	a5,a5,-1
    80002454:	1af4aa23          	sw	a5,436(s1)
      printf("%d %d %d %d a\n", p->priority, p->pid, p->curr_rtime, ticks);
    80002458:	000ba703          	lw	a4,0(s7)
    8000245c:	1bc4a683          	lw	a3,444(s1)
    80002460:	5890                	lw	a2,48(s1)
    80002462:	1b44a583          	lw	a1,436(s1)
    80002466:	855a                	mv	a0,s6
    80002468:	ffffe097          	auipc	ra,0xffffe
    8000246c:	126080e7          	jalr	294(ra) # 8000058e <printf>
    80002470:	bf79                	j	8000240e <update_time+0x5c>
        printf("Aging Performed on pid: %d\n", p->pid);
    80002472:	588c                	lw	a1,48(s1)
    80002474:	8562                	mv	a0,s8
    80002476:	ffffe097          	auipc	ra,0xffffe
    8000247a:	118080e7          	jalr	280(ra) # 8000058e <printf>
        delqueue(p);
    8000247e:	8526                	mv	a0,s1
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	52c080e7          	jalr	1324(ra) # 800019ac <delqueue>
        p->in_queue = 0;
    80002488:	1a04ac23          	sw	zero,440(s1)
    8000248c:	b7c1                	j	8000244c <update_time+0x9a>
}
    8000248e:	60a6                	ld	ra,72(sp)
    80002490:	6406                	ld	s0,64(sp)
    80002492:	74e2                	ld	s1,56(sp)
    80002494:	7942                	ld	s2,48(sp)
    80002496:	79a2                	ld	s3,40(sp)
    80002498:	7a02                	ld	s4,32(sp)
    8000249a:	6ae2                	ld	s5,24(sp)
    8000249c:	6b42                	ld	s6,16(sp)
    8000249e:	6ba2                	ld	s7,8(sp)
    800024a0:	6c02                	ld	s8,0(sp)
    800024a2:	6161                	addi	sp,sp,80
    800024a4:	8082                	ret

00000000800024a6 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800024a6:	7179                	addi	sp,sp,-48
    800024a8:	f406                	sd	ra,40(sp)
    800024aa:	f022                	sd	s0,32(sp)
    800024ac:	ec26                	sd	s1,24(sp)
    800024ae:	e84a                	sd	s2,16(sp)
    800024b0:	e44e                	sd	s3,8(sp)
    800024b2:	1800                	addi	s0,sp,48
    800024b4:	89aa                	mv	s3,a0
    800024b6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800024b8:	fffff097          	auipc	ra,0xfffff
    800024bc:	73e080e7          	jalr	1854(ra) # 80001bf6 <myproc>
    800024c0:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800024c2:	ffffe097          	auipc	ra,0xffffe
    800024c6:	728080e7          	jalr	1832(ra) # 80000bea <acquire>
  release(lk);
    800024ca:	854a                	mv	a0,s2
    800024cc:	ffffe097          	auipc	ra,0xffffe
    800024d0:	7d2080e7          	jalr	2002(ra) # 80000c9e <release>

  // Go to sleep.
  p->chan = chan;
    800024d4:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800024d8:	4789                	li	a5,2
    800024da:	cc9c                	sw	a5,24(s1)

  sched();
    800024dc:	00000097          	auipc	ra,0x0
    800024e0:	dc4080e7          	jalr	-572(ra) # 800022a0 <sched>

  // Tidy up.
  p->chan = 0;
    800024e4:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800024e8:	8526                	mv	a0,s1
    800024ea:	ffffe097          	auipc	ra,0xffffe
    800024ee:	7b4080e7          	jalr	1972(ra) # 80000c9e <release>
  acquire(lk);
    800024f2:	854a                	mv	a0,s2
    800024f4:	ffffe097          	auipc	ra,0xffffe
    800024f8:	6f6080e7          	jalr	1782(ra) # 80000bea <acquire>
}
    800024fc:	70a2                	ld	ra,40(sp)
    800024fe:	7402                	ld	s0,32(sp)
    80002500:	64e2                	ld	s1,24(sp)
    80002502:	6942                	ld	s2,16(sp)
    80002504:	69a2                	ld	s3,8(sp)
    80002506:	6145                	addi	sp,sp,48
    80002508:	8082                	ret

000000008000250a <waitx>:
{
    8000250a:	711d                	addi	sp,sp,-96
    8000250c:	ec86                	sd	ra,88(sp)
    8000250e:	e8a2                	sd	s0,80(sp)
    80002510:	e4a6                	sd	s1,72(sp)
    80002512:	e0ca                	sd	s2,64(sp)
    80002514:	fc4e                	sd	s3,56(sp)
    80002516:	f852                	sd	s4,48(sp)
    80002518:	f456                	sd	s5,40(sp)
    8000251a:	f05a                	sd	s6,32(sp)
    8000251c:	ec5e                	sd	s7,24(sp)
    8000251e:	e862                	sd	s8,16(sp)
    80002520:	e466                	sd	s9,8(sp)
    80002522:	e06a                	sd	s10,0(sp)
    80002524:	1080                	addi	s0,sp,96
    80002526:	8b2a                	mv	s6,a0
    80002528:	8bae                	mv	s7,a1
    8000252a:	8c32                	mv	s8,a2
  struct proc *p = myproc();
    8000252c:	fffff097          	auipc	ra,0xfffff
    80002530:	6ca080e7          	jalr	1738(ra) # 80001bf6 <myproc>
    80002534:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002536:	00010517          	auipc	a0,0x10
    8000253a:	93250513          	addi	a0,a0,-1742 # 80011e68 <wait_lock>
    8000253e:	ffffe097          	auipc	ra,0xffffe
    80002542:	6ac080e7          	jalr	1708(ra) # 80000bea <acquire>
    havekids = 0;
    80002546:	4c81                	li	s9,0
        if(np->state == ZOMBIE){
    80002548:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000254a:	00018997          	auipc	s3,0x18
    8000254e:	9ae98993          	addi	s3,s3,-1618 # 80019ef8 <tickslock>
        havekids = 1;
    80002552:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002554:	00010d17          	auipc	s10,0x10
    80002558:	914d0d13          	addi	s10,s10,-1772 # 80011e68 <wait_lock>
    havekids = 0;
    8000255c:	8766                	mv	a4,s9
    for(np = proc; np < &proc[NPROC]; np++){
    8000255e:	00010497          	auipc	s1,0x10
    80002562:	79a48493          	addi	s1,s1,1946 # 80012cf8 <proc>
    80002566:	a059                	j	800025ec <waitx+0xe2>
          pid = np->pid;
    80002568:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    8000256c:	1684a703          	lw	a4,360(s1)
    80002570:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002574:	16c4a783          	lw	a5,364(s1)
    80002578:	9f3d                	addw	a4,a4,a5
    8000257a:	1704a783          	lw	a5,368(s1)
    8000257e:	9f99                	subw	a5,a5,a4
    80002580:	00fba023          	sw	a5,0(s7)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002584:	000b0e63          	beqz	s6,800025a0 <waitx+0x96>
    80002588:	4691                	li	a3,4
    8000258a:	02c48613          	addi	a2,s1,44
    8000258e:	85da                	mv	a1,s6
    80002590:	05093503          	ld	a0,80(s2)
    80002594:	fffff097          	auipc	ra,0xfffff
    80002598:	0f0080e7          	jalr	240(ra) # 80001684 <copyout>
    8000259c:	02054563          	bltz	a0,800025c6 <waitx+0xbc>
          freeproc(np);
    800025a0:	8526                	mv	a0,s1
    800025a2:	00000097          	auipc	ra,0x0
    800025a6:	806080e7          	jalr	-2042(ra) # 80001da8 <freeproc>
          release(&np->lock);
    800025aa:	8526                	mv	a0,s1
    800025ac:	ffffe097          	auipc	ra,0xffffe
    800025b0:	6f2080e7          	jalr	1778(ra) # 80000c9e <release>
          release(&wait_lock);
    800025b4:	00010517          	auipc	a0,0x10
    800025b8:	8b450513          	addi	a0,a0,-1868 # 80011e68 <wait_lock>
    800025bc:	ffffe097          	auipc	ra,0xffffe
    800025c0:	6e2080e7          	jalr	1762(ra) # 80000c9e <release>
          return pid;
    800025c4:	a09d                	j	8000262a <waitx+0x120>
            release(&np->lock);
    800025c6:	8526                	mv	a0,s1
    800025c8:	ffffe097          	auipc	ra,0xffffe
    800025cc:	6d6080e7          	jalr	1750(ra) # 80000c9e <release>
            release(&wait_lock);
    800025d0:	00010517          	auipc	a0,0x10
    800025d4:	89850513          	addi	a0,a0,-1896 # 80011e68 <wait_lock>
    800025d8:	ffffe097          	auipc	ra,0xffffe
    800025dc:	6c6080e7          	jalr	1734(ra) # 80000c9e <release>
            return -1;
    800025e0:	59fd                	li	s3,-1
    800025e2:	a0a1                	j	8000262a <waitx+0x120>
    for(np = proc; np < &proc[NPROC]; np++){
    800025e4:	1c848493          	addi	s1,s1,456
    800025e8:	03348463          	beq	s1,s3,80002610 <waitx+0x106>
      if(np->parent == p){
    800025ec:	7c9c                	ld	a5,56(s1)
    800025ee:	ff279be3          	bne	a5,s2,800025e4 <waitx+0xda>
        acquire(&np->lock);
    800025f2:	8526                	mv	a0,s1
    800025f4:	ffffe097          	auipc	ra,0xffffe
    800025f8:	5f6080e7          	jalr	1526(ra) # 80000bea <acquire>
        if(np->state == ZOMBIE){
    800025fc:	4c9c                	lw	a5,24(s1)
    800025fe:	f74785e3          	beq	a5,s4,80002568 <waitx+0x5e>
        release(&np->lock);
    80002602:	8526                	mv	a0,s1
    80002604:	ffffe097          	auipc	ra,0xffffe
    80002608:	69a080e7          	jalr	1690(ra) # 80000c9e <release>
        havekids = 1;
    8000260c:	8756                	mv	a4,s5
    8000260e:	bfd9                	j	800025e4 <waitx+0xda>
    if(!havekids || p->killed){
    80002610:	c701                	beqz	a4,80002618 <waitx+0x10e>
    80002612:	02892783          	lw	a5,40(s2)
    80002616:	cb8d                	beqz	a5,80002648 <waitx+0x13e>
      release(&wait_lock);
    80002618:	00010517          	auipc	a0,0x10
    8000261c:	85050513          	addi	a0,a0,-1968 # 80011e68 <wait_lock>
    80002620:	ffffe097          	auipc	ra,0xffffe
    80002624:	67e080e7          	jalr	1662(ra) # 80000c9e <release>
      return -1;
    80002628:	59fd                	li	s3,-1
}
    8000262a:	854e                	mv	a0,s3
    8000262c:	60e6                	ld	ra,88(sp)
    8000262e:	6446                	ld	s0,80(sp)
    80002630:	64a6                	ld	s1,72(sp)
    80002632:	6906                	ld	s2,64(sp)
    80002634:	79e2                	ld	s3,56(sp)
    80002636:	7a42                	ld	s4,48(sp)
    80002638:	7aa2                	ld	s5,40(sp)
    8000263a:	7b02                	ld	s6,32(sp)
    8000263c:	6be2                	ld	s7,24(sp)
    8000263e:	6c42                	ld	s8,16(sp)
    80002640:	6ca2                	ld	s9,8(sp)
    80002642:	6d02                	ld	s10,0(sp)
    80002644:	6125                	addi	sp,sp,96
    80002646:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002648:	85ea                	mv	a1,s10
    8000264a:	854a                	mv	a0,s2
    8000264c:	00000097          	auipc	ra,0x0
    80002650:	e5a080e7          	jalr	-422(ra) # 800024a6 <sleep>
    havekids = 0;
    80002654:	b721                	j	8000255c <waitx+0x52>

0000000080002656 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002656:	7139                	addi	sp,sp,-64
    80002658:	fc06                	sd	ra,56(sp)
    8000265a:	f822                	sd	s0,48(sp)
    8000265c:	f426                	sd	s1,40(sp)
    8000265e:	f04a                	sd	s2,32(sp)
    80002660:	ec4e                	sd	s3,24(sp)
    80002662:	e852                	sd	s4,16(sp)
    80002664:	e456                	sd	s5,8(sp)
    80002666:	0080                	addi	s0,sp,64
    80002668:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000266a:	00010497          	auipc	s1,0x10
    8000266e:	68e48493          	addi	s1,s1,1678 # 80012cf8 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002672:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002674:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002676:	00018917          	auipc	s2,0x18
    8000267a:	88290913          	addi	s2,s2,-1918 # 80019ef8 <tickslock>
    8000267e:	a821                	j	80002696 <wakeup+0x40>
        p->state = RUNNABLE;
    80002680:	0154ac23          	sw	s5,24(s1)
        // #ifdef MLFQ
		    //   enqueue(p);
	      // #endif
      }
      release(&p->lock);
    80002684:	8526                	mv	a0,s1
    80002686:	ffffe097          	auipc	ra,0xffffe
    8000268a:	618080e7          	jalr	1560(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000268e:	1c848493          	addi	s1,s1,456
    80002692:	03248463          	beq	s1,s2,800026ba <wakeup+0x64>
    if(p != myproc()){
    80002696:	fffff097          	auipc	ra,0xfffff
    8000269a:	560080e7          	jalr	1376(ra) # 80001bf6 <myproc>
    8000269e:	fea488e3          	beq	s1,a0,8000268e <wakeup+0x38>
      acquire(&p->lock);
    800026a2:	8526                	mv	a0,s1
    800026a4:	ffffe097          	auipc	ra,0xffffe
    800026a8:	546080e7          	jalr	1350(ra) # 80000bea <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800026ac:	4c9c                	lw	a5,24(s1)
    800026ae:	fd379be3          	bne	a5,s3,80002684 <wakeup+0x2e>
    800026b2:	709c                	ld	a5,32(s1)
    800026b4:	fd4798e3          	bne	a5,s4,80002684 <wakeup+0x2e>
    800026b8:	b7e1                	j	80002680 <wakeup+0x2a>
    }
  }
}
    800026ba:	70e2                	ld	ra,56(sp)
    800026bc:	7442                	ld	s0,48(sp)
    800026be:	74a2                	ld	s1,40(sp)
    800026c0:	7902                	ld	s2,32(sp)
    800026c2:	69e2                	ld	s3,24(sp)
    800026c4:	6a42                	ld	s4,16(sp)
    800026c6:	6aa2                	ld	s5,8(sp)
    800026c8:	6121                	addi	sp,sp,64
    800026ca:	8082                	ret

00000000800026cc <reparent>:
{
    800026cc:	7179                	addi	sp,sp,-48
    800026ce:	f406                	sd	ra,40(sp)
    800026d0:	f022                	sd	s0,32(sp)
    800026d2:	ec26                	sd	s1,24(sp)
    800026d4:	e84a                	sd	s2,16(sp)
    800026d6:	e44e                	sd	s3,8(sp)
    800026d8:	e052                	sd	s4,0(sp)
    800026da:	1800                	addi	s0,sp,48
    800026dc:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800026de:	00010497          	auipc	s1,0x10
    800026e2:	61a48493          	addi	s1,s1,1562 # 80012cf8 <proc>
      pp->parent = initproc;
    800026e6:	00007a17          	auipc	s4,0x7
    800026ea:	4f2a0a13          	addi	s4,s4,1266 # 80009bd8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800026ee:	00018997          	auipc	s3,0x18
    800026f2:	80a98993          	addi	s3,s3,-2038 # 80019ef8 <tickslock>
    800026f6:	a029                	j	80002700 <reparent+0x34>
    800026f8:	1c848493          	addi	s1,s1,456
    800026fc:	01348d63          	beq	s1,s3,80002716 <reparent+0x4a>
    if(pp->parent == p){
    80002700:	7c9c                	ld	a5,56(s1)
    80002702:	ff279be3          	bne	a5,s2,800026f8 <reparent+0x2c>
      pp->parent = initproc;
    80002706:	000a3503          	ld	a0,0(s4)
    8000270a:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000270c:	00000097          	auipc	ra,0x0
    80002710:	f4a080e7          	jalr	-182(ra) # 80002656 <wakeup>
    80002714:	b7d5                	j	800026f8 <reparent+0x2c>
}
    80002716:	70a2                	ld	ra,40(sp)
    80002718:	7402                	ld	s0,32(sp)
    8000271a:	64e2                	ld	s1,24(sp)
    8000271c:	6942                	ld	s2,16(sp)
    8000271e:	69a2                	ld	s3,8(sp)
    80002720:	6a02                	ld	s4,0(sp)
    80002722:	6145                	addi	sp,sp,48
    80002724:	8082                	ret

0000000080002726 <exit>:
{
    80002726:	7179                	addi	sp,sp,-48
    80002728:	f406                	sd	ra,40(sp)
    8000272a:	f022                	sd	s0,32(sp)
    8000272c:	ec26                	sd	s1,24(sp)
    8000272e:	e84a                	sd	s2,16(sp)
    80002730:	e44e                	sd	s3,8(sp)
    80002732:	e052                	sd	s4,0(sp)
    80002734:	1800                	addi	s0,sp,48
    80002736:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002738:	fffff097          	auipc	ra,0xfffff
    8000273c:	4be080e7          	jalr	1214(ra) # 80001bf6 <myproc>
    80002740:	89aa                	mv	s3,a0
  if(p == initproc)
    80002742:	00007797          	auipc	a5,0x7
    80002746:	4967b783          	ld	a5,1174(a5) # 80009bd8 <initproc>
    8000274a:	0d050493          	addi	s1,a0,208
    8000274e:	15050913          	addi	s2,a0,336
    80002752:	02a79363          	bne	a5,a0,80002778 <exit+0x52>
    panic("init exiting");
    80002756:	00007517          	auipc	a0,0x7
    8000275a:	b5a50513          	addi	a0,a0,-1190 # 800092b0 <digits+0x270>
    8000275e:	ffffe097          	auipc	ra,0xffffe
    80002762:	de6080e7          	jalr	-538(ra) # 80000544 <panic>
      fileclose(f);
    80002766:	00003097          	auipc	ra,0x3
    8000276a:	ad6080e7          	jalr	-1322(ra) # 8000523c <fileclose>
      p->ofile[fd] = 0;
    8000276e:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002772:	04a1                	addi	s1,s1,8
    80002774:	01248563          	beq	s1,s2,8000277e <exit+0x58>
    if(p->ofile[fd]){
    80002778:	6088                	ld	a0,0(s1)
    8000277a:	f575                	bnez	a0,80002766 <exit+0x40>
    8000277c:	bfdd                	j	80002772 <exit+0x4c>
  begin_op();
    8000277e:	00002097          	auipc	ra,0x2
    80002782:	5f2080e7          	jalr	1522(ra) # 80004d70 <begin_op>
  iput(p->cwd);
    80002786:	1509b503          	ld	a0,336(s3)
    8000278a:	00002097          	auipc	ra,0x2
    8000278e:	dde080e7          	jalr	-546(ra) # 80004568 <iput>
  end_op();
    80002792:	00002097          	auipc	ra,0x2
    80002796:	65e080e7          	jalr	1630(ra) # 80004df0 <end_op>
  p->cwd = 0;
    8000279a:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000279e:	0000f497          	auipc	s1,0xf
    800027a2:	6ca48493          	addi	s1,s1,1738 # 80011e68 <wait_lock>
    800027a6:	8526                	mv	a0,s1
    800027a8:	ffffe097          	auipc	ra,0xffffe
    800027ac:	442080e7          	jalr	1090(ra) # 80000bea <acquire>
  reparent(p);
    800027b0:	854e                	mv	a0,s3
    800027b2:	00000097          	auipc	ra,0x0
    800027b6:	f1a080e7          	jalr	-230(ra) # 800026cc <reparent>
  wakeup(p->parent);
    800027ba:	0389b503          	ld	a0,56(s3)
    800027be:	00000097          	auipc	ra,0x0
    800027c2:	e98080e7          	jalr	-360(ra) # 80002656 <wakeup>
  acquire(&p->lock);
    800027c6:	854e                	mv	a0,s3
    800027c8:	ffffe097          	auipc	ra,0xffffe
    800027cc:	422080e7          	jalr	1058(ra) # 80000bea <acquire>
  p->xstate = status;
    800027d0:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800027d4:	4795                	li	a5,5
    800027d6:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800027da:	00007797          	auipc	a5,0x7
    800027de:	4067a783          	lw	a5,1030(a5) # 80009be0 <ticks>
    800027e2:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    800027e6:	8526                	mv	a0,s1
    800027e8:	ffffe097          	auipc	ra,0xffffe
    800027ec:	4b6080e7          	jalr	1206(ra) # 80000c9e <release>
  sched();
    800027f0:	00000097          	auipc	ra,0x0
    800027f4:	ab0080e7          	jalr	-1360(ra) # 800022a0 <sched>
  panic("zombie exit");
    800027f8:	00007517          	auipc	a0,0x7
    800027fc:	ac850513          	addi	a0,a0,-1336 # 800092c0 <digits+0x280>
    80002800:	ffffe097          	auipc	ra,0xffffe
    80002804:	d44080e7          	jalr	-700(ra) # 80000544 <panic>

0000000080002808 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002808:	7179                	addi	sp,sp,-48
    8000280a:	f406                	sd	ra,40(sp)
    8000280c:	f022                	sd	s0,32(sp)
    8000280e:	ec26                	sd	s1,24(sp)
    80002810:	e84a                	sd	s2,16(sp)
    80002812:	e44e                	sd	s3,8(sp)
    80002814:	1800                	addi	s0,sp,48
    80002816:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002818:	00010497          	auipc	s1,0x10
    8000281c:	4e048493          	addi	s1,s1,1248 # 80012cf8 <proc>
    80002820:	00017997          	auipc	s3,0x17
    80002824:	6d898993          	addi	s3,s3,1752 # 80019ef8 <tickslock>
    acquire(&p->lock);
    80002828:	8526                	mv	a0,s1
    8000282a:	ffffe097          	auipc	ra,0xffffe
    8000282e:	3c0080e7          	jalr	960(ra) # 80000bea <acquire>
    if(p->pid == pid){
    80002832:	589c                	lw	a5,48(s1)
    80002834:	01278d63          	beq	a5,s2,8000284e <kill+0x46>
	      // #endif
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002838:	8526                	mv	a0,s1
    8000283a:	ffffe097          	auipc	ra,0xffffe
    8000283e:	464080e7          	jalr	1124(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002842:	1c848493          	addi	s1,s1,456
    80002846:	ff3491e3          	bne	s1,s3,80002828 <kill+0x20>
  }
  return -1;
    8000284a:	557d                	li	a0,-1
    8000284c:	a829                	j	80002866 <kill+0x5e>
      p->killed = 1;
    8000284e:	4785                	li	a5,1
    80002850:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002852:	4c98                	lw	a4,24(s1)
    80002854:	4789                	li	a5,2
    80002856:	00f70f63          	beq	a4,a5,80002874 <kill+0x6c>
      release(&p->lock);
    8000285a:	8526                	mv	a0,s1
    8000285c:	ffffe097          	auipc	ra,0xffffe
    80002860:	442080e7          	jalr	1090(ra) # 80000c9e <release>
      return 0;
    80002864:	4501                	li	a0,0
}
    80002866:	70a2                	ld	ra,40(sp)
    80002868:	7402                	ld	s0,32(sp)
    8000286a:	64e2                	ld	s1,24(sp)
    8000286c:	6942                	ld	s2,16(sp)
    8000286e:	69a2                	ld	s3,8(sp)
    80002870:	6145                	addi	sp,sp,48
    80002872:	8082                	ret
        p->state = RUNNABLE;
    80002874:	478d                	li	a5,3
    80002876:	cc9c                	sw	a5,24(s1)
    80002878:	b7cd                	j	8000285a <kill+0x52>

000000008000287a <setkilled>:

void
setkilled(struct proc *p)
{
    8000287a:	1101                	addi	sp,sp,-32
    8000287c:	ec06                	sd	ra,24(sp)
    8000287e:	e822                	sd	s0,16(sp)
    80002880:	e426                	sd	s1,8(sp)
    80002882:	1000                	addi	s0,sp,32
    80002884:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002886:	ffffe097          	auipc	ra,0xffffe
    8000288a:	364080e7          	jalr	868(ra) # 80000bea <acquire>
  p->killed = 1;
    8000288e:	4785                	li	a5,1
    80002890:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002892:	8526                	mv	a0,s1
    80002894:	ffffe097          	auipc	ra,0xffffe
    80002898:	40a080e7          	jalr	1034(ra) # 80000c9e <release>
}
    8000289c:	60e2                	ld	ra,24(sp)
    8000289e:	6442                	ld	s0,16(sp)
    800028a0:	64a2                	ld	s1,8(sp)
    800028a2:	6105                	addi	sp,sp,32
    800028a4:	8082                	ret

00000000800028a6 <killed>:

int
killed(struct proc *p)
{
    800028a6:	1101                	addi	sp,sp,-32
    800028a8:	ec06                	sd	ra,24(sp)
    800028aa:	e822                	sd	s0,16(sp)
    800028ac:	e426                	sd	s1,8(sp)
    800028ae:	e04a                	sd	s2,0(sp)
    800028b0:	1000                	addi	s0,sp,32
    800028b2:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800028b4:	ffffe097          	auipc	ra,0xffffe
    800028b8:	336080e7          	jalr	822(ra) # 80000bea <acquire>
  k = p->killed;
    800028bc:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800028c0:	8526                	mv	a0,s1
    800028c2:	ffffe097          	auipc	ra,0xffffe
    800028c6:	3dc080e7          	jalr	988(ra) # 80000c9e <release>
  return k;
}
    800028ca:	854a                	mv	a0,s2
    800028cc:	60e2                	ld	ra,24(sp)
    800028ce:	6442                	ld	s0,16(sp)
    800028d0:	64a2                	ld	s1,8(sp)
    800028d2:	6902                	ld	s2,0(sp)
    800028d4:	6105                	addi	sp,sp,32
    800028d6:	8082                	ret

00000000800028d8 <wait>:
{
    800028d8:	715d                	addi	sp,sp,-80
    800028da:	e486                	sd	ra,72(sp)
    800028dc:	e0a2                	sd	s0,64(sp)
    800028de:	fc26                	sd	s1,56(sp)
    800028e0:	f84a                	sd	s2,48(sp)
    800028e2:	f44e                	sd	s3,40(sp)
    800028e4:	f052                	sd	s4,32(sp)
    800028e6:	ec56                	sd	s5,24(sp)
    800028e8:	e85a                	sd	s6,16(sp)
    800028ea:	e45e                	sd	s7,8(sp)
    800028ec:	e062                	sd	s8,0(sp)
    800028ee:	0880                	addi	s0,sp,80
    800028f0:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800028f2:	fffff097          	auipc	ra,0xfffff
    800028f6:	304080e7          	jalr	772(ra) # 80001bf6 <myproc>
    800028fa:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800028fc:	0000f517          	auipc	a0,0xf
    80002900:	56c50513          	addi	a0,a0,1388 # 80011e68 <wait_lock>
    80002904:	ffffe097          	auipc	ra,0xffffe
    80002908:	2e6080e7          	jalr	742(ra) # 80000bea <acquire>
    havekids = 0;
    8000290c:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000290e:	4a15                	li	s4,5
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002910:	00017997          	auipc	s3,0x17
    80002914:	5e898993          	addi	s3,s3,1512 # 80019ef8 <tickslock>
        havekids = 1;
    80002918:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000291a:	0000fc17          	auipc	s8,0xf
    8000291e:	54ec0c13          	addi	s8,s8,1358 # 80011e68 <wait_lock>
    havekids = 0;
    80002922:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002924:	00010497          	auipc	s1,0x10
    80002928:	3d448493          	addi	s1,s1,980 # 80012cf8 <proc>
    8000292c:	a0bd                	j	8000299a <wait+0xc2>
          pid = pp->pid;
    8000292e:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002932:	000b0e63          	beqz	s6,8000294e <wait+0x76>
    80002936:	4691                	li	a3,4
    80002938:	02c48613          	addi	a2,s1,44
    8000293c:	85da                	mv	a1,s6
    8000293e:	05093503          	ld	a0,80(s2)
    80002942:	fffff097          	auipc	ra,0xfffff
    80002946:	d42080e7          	jalr	-702(ra) # 80001684 <copyout>
    8000294a:	02054563          	bltz	a0,80002974 <wait+0x9c>
          freeproc(pp);
    8000294e:	8526                	mv	a0,s1
    80002950:	fffff097          	auipc	ra,0xfffff
    80002954:	458080e7          	jalr	1112(ra) # 80001da8 <freeproc>
          release(&pp->lock);
    80002958:	8526                	mv	a0,s1
    8000295a:	ffffe097          	auipc	ra,0xffffe
    8000295e:	344080e7          	jalr	836(ra) # 80000c9e <release>
          release(&wait_lock);
    80002962:	0000f517          	auipc	a0,0xf
    80002966:	50650513          	addi	a0,a0,1286 # 80011e68 <wait_lock>
    8000296a:	ffffe097          	auipc	ra,0xffffe
    8000296e:	334080e7          	jalr	820(ra) # 80000c9e <release>
          return pid;
    80002972:	a0b5                	j	800029de <wait+0x106>
            release(&pp->lock);
    80002974:	8526                	mv	a0,s1
    80002976:	ffffe097          	auipc	ra,0xffffe
    8000297a:	328080e7          	jalr	808(ra) # 80000c9e <release>
            release(&wait_lock);
    8000297e:	0000f517          	auipc	a0,0xf
    80002982:	4ea50513          	addi	a0,a0,1258 # 80011e68 <wait_lock>
    80002986:	ffffe097          	auipc	ra,0xffffe
    8000298a:	318080e7          	jalr	792(ra) # 80000c9e <release>
            return -1;
    8000298e:	59fd                	li	s3,-1
    80002990:	a0b9                	j	800029de <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002992:	1c848493          	addi	s1,s1,456
    80002996:	03348463          	beq	s1,s3,800029be <wait+0xe6>
      if(pp->parent == p){
    8000299a:	7c9c                	ld	a5,56(s1)
    8000299c:	ff279be3          	bne	a5,s2,80002992 <wait+0xba>
        acquire(&pp->lock);
    800029a0:	8526                	mv	a0,s1
    800029a2:	ffffe097          	auipc	ra,0xffffe
    800029a6:	248080e7          	jalr	584(ra) # 80000bea <acquire>
        if(pp->state == ZOMBIE){
    800029aa:	4c9c                	lw	a5,24(s1)
    800029ac:	f94781e3          	beq	a5,s4,8000292e <wait+0x56>
        release(&pp->lock);
    800029b0:	8526                	mv	a0,s1
    800029b2:	ffffe097          	auipc	ra,0xffffe
    800029b6:	2ec080e7          	jalr	748(ra) # 80000c9e <release>
        havekids = 1;
    800029ba:	8756                	mv	a4,s5
    800029bc:	bfd9                	j	80002992 <wait+0xba>
    if(!havekids || killed(p)){
    800029be:	c719                	beqz	a4,800029cc <wait+0xf4>
    800029c0:	854a                	mv	a0,s2
    800029c2:	00000097          	auipc	ra,0x0
    800029c6:	ee4080e7          	jalr	-284(ra) # 800028a6 <killed>
    800029ca:	c51d                	beqz	a0,800029f8 <wait+0x120>
      release(&wait_lock);
    800029cc:	0000f517          	auipc	a0,0xf
    800029d0:	49c50513          	addi	a0,a0,1180 # 80011e68 <wait_lock>
    800029d4:	ffffe097          	auipc	ra,0xffffe
    800029d8:	2ca080e7          	jalr	714(ra) # 80000c9e <release>
      return -1;
    800029dc:	59fd                	li	s3,-1
}
    800029de:	854e                	mv	a0,s3
    800029e0:	60a6                	ld	ra,72(sp)
    800029e2:	6406                	ld	s0,64(sp)
    800029e4:	74e2                	ld	s1,56(sp)
    800029e6:	7942                	ld	s2,48(sp)
    800029e8:	79a2                	ld	s3,40(sp)
    800029ea:	7a02                	ld	s4,32(sp)
    800029ec:	6ae2                	ld	s5,24(sp)
    800029ee:	6b42                	ld	s6,16(sp)
    800029f0:	6ba2                	ld	s7,8(sp)
    800029f2:	6c02                	ld	s8,0(sp)
    800029f4:	6161                	addi	sp,sp,80
    800029f6:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800029f8:	85e2                	mv	a1,s8
    800029fa:	854a                	mv	a0,s2
    800029fc:	00000097          	auipc	ra,0x0
    80002a00:	aaa080e7          	jalr	-1366(ra) # 800024a6 <sleep>
    havekids = 0;
    80002a04:	bf39                	j	80002922 <wait+0x4a>

0000000080002a06 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002a06:	7179                	addi	sp,sp,-48
    80002a08:	f406                	sd	ra,40(sp)
    80002a0a:	f022                	sd	s0,32(sp)
    80002a0c:	ec26                	sd	s1,24(sp)
    80002a0e:	e84a                	sd	s2,16(sp)
    80002a10:	e44e                	sd	s3,8(sp)
    80002a12:	e052                	sd	s4,0(sp)
    80002a14:	1800                	addi	s0,sp,48
    80002a16:	84aa                	mv	s1,a0
    80002a18:	892e                	mv	s2,a1
    80002a1a:	89b2                	mv	s3,a2
    80002a1c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a1e:	fffff097          	auipc	ra,0xfffff
    80002a22:	1d8080e7          	jalr	472(ra) # 80001bf6 <myproc>
  if(user_dst){
    80002a26:	c08d                	beqz	s1,80002a48 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002a28:	86d2                	mv	a3,s4
    80002a2a:	864e                	mv	a2,s3
    80002a2c:	85ca                	mv	a1,s2
    80002a2e:	6928                	ld	a0,80(a0)
    80002a30:	fffff097          	auipc	ra,0xfffff
    80002a34:	c54080e7          	jalr	-940(ra) # 80001684 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002a38:	70a2                	ld	ra,40(sp)
    80002a3a:	7402                	ld	s0,32(sp)
    80002a3c:	64e2                	ld	s1,24(sp)
    80002a3e:	6942                	ld	s2,16(sp)
    80002a40:	69a2                	ld	s3,8(sp)
    80002a42:	6a02                	ld	s4,0(sp)
    80002a44:	6145                	addi	sp,sp,48
    80002a46:	8082                	ret
    memmove((char *)dst, src, len);
    80002a48:	000a061b          	sext.w	a2,s4
    80002a4c:	85ce                	mv	a1,s3
    80002a4e:	854a                	mv	a0,s2
    80002a50:	ffffe097          	auipc	ra,0xffffe
    80002a54:	2f6080e7          	jalr	758(ra) # 80000d46 <memmove>
    return 0;
    80002a58:	8526                	mv	a0,s1
    80002a5a:	bff9                	j	80002a38 <either_copyout+0x32>

0000000080002a5c <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002a5c:	7179                	addi	sp,sp,-48
    80002a5e:	f406                	sd	ra,40(sp)
    80002a60:	f022                	sd	s0,32(sp)
    80002a62:	ec26                	sd	s1,24(sp)
    80002a64:	e84a                	sd	s2,16(sp)
    80002a66:	e44e                	sd	s3,8(sp)
    80002a68:	e052                	sd	s4,0(sp)
    80002a6a:	1800                	addi	s0,sp,48
    80002a6c:	892a                	mv	s2,a0
    80002a6e:	84ae                	mv	s1,a1
    80002a70:	89b2                	mv	s3,a2
    80002a72:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a74:	fffff097          	auipc	ra,0xfffff
    80002a78:	182080e7          	jalr	386(ra) # 80001bf6 <myproc>
  if(user_src){
    80002a7c:	c08d                	beqz	s1,80002a9e <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002a7e:	86d2                	mv	a3,s4
    80002a80:	864e                	mv	a2,s3
    80002a82:	85ca                	mv	a1,s2
    80002a84:	6928                	ld	a0,80(a0)
    80002a86:	fffff097          	auipc	ra,0xfffff
    80002a8a:	c8a080e7          	jalr	-886(ra) # 80001710 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002a8e:	70a2                	ld	ra,40(sp)
    80002a90:	7402                	ld	s0,32(sp)
    80002a92:	64e2                	ld	s1,24(sp)
    80002a94:	6942                	ld	s2,16(sp)
    80002a96:	69a2                	ld	s3,8(sp)
    80002a98:	6a02                	ld	s4,0(sp)
    80002a9a:	6145                	addi	sp,sp,48
    80002a9c:	8082                	ret
    memmove(dst, (char*)src, len);
    80002a9e:	000a061b          	sext.w	a2,s4
    80002aa2:	85ce                	mv	a1,s3
    80002aa4:	854a                	mv	a0,s2
    80002aa6:	ffffe097          	auipc	ra,0xffffe
    80002aaa:	2a0080e7          	jalr	672(ra) # 80000d46 <memmove>
    return 0;
    80002aae:	8526                	mv	a0,s1
    80002ab0:	bff9                	j	80002a8e <either_copyin+0x32>

0000000080002ab2 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002ab2:	715d                	addi	sp,sp,-80
    80002ab4:	e486                	sd	ra,72(sp)
    80002ab6:	e0a2                	sd	s0,64(sp)
    80002ab8:	fc26                	sd	s1,56(sp)
    80002aba:	f84a                	sd	s2,48(sp)
    80002abc:	f44e                	sd	s3,40(sp)
    80002abe:	f052                	sd	s4,32(sp)
    80002ac0:	ec56                	sd	s5,24(sp)
    80002ac2:	e85a                	sd	s6,16(sp)
    80002ac4:	e45e                	sd	s7,8(sp)
    80002ac6:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002ac8:	00006517          	auipc	a0,0x6
    80002acc:	60050513          	addi	a0,a0,1536 # 800090c8 <digits+0x88>
    80002ad0:	ffffe097          	auipc	ra,0xffffe
    80002ad4:	abe080e7          	jalr	-1346(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002ad8:	00010497          	auipc	s1,0x10
    80002adc:	37848493          	addi	s1,s1,888 # 80012e50 <proc+0x158>
    80002ae0:	00017917          	auipc	s2,0x17
    80002ae4:	57090913          	addi	s2,s2,1392 # 8001a050 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ae8:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002aea:	00006997          	auipc	s3,0x6
    80002aee:	7e698993          	addi	s3,s3,2022 # 800092d0 <digits+0x290>
    printf("%d %s %s", p->pid, state, p->name);
    80002af2:	00006a97          	auipc	s5,0x6
    80002af6:	7e6a8a93          	addi	s5,s5,2022 # 800092d8 <digits+0x298>
    printf("\n");
    80002afa:	00006a17          	auipc	s4,0x6
    80002afe:	5cea0a13          	addi	s4,s4,1486 # 800090c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b02:	00007b97          	auipc	s7,0x7
    80002b06:	816b8b93          	addi	s7,s7,-2026 # 80009318 <states.1811>
    80002b0a:	a00d                	j	80002b2c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002b0c:	ed86a583          	lw	a1,-296(a3)
    80002b10:	8556                	mv	a0,s5
    80002b12:	ffffe097          	auipc	ra,0xffffe
    80002b16:	a7c080e7          	jalr	-1412(ra) # 8000058e <printf>
    printf("\n");
    80002b1a:	8552                	mv	a0,s4
    80002b1c:	ffffe097          	auipc	ra,0xffffe
    80002b20:	a72080e7          	jalr	-1422(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002b24:	1c848493          	addi	s1,s1,456
    80002b28:	03248163          	beq	s1,s2,80002b4a <procdump+0x98>
    if(p->state == UNUSED)
    80002b2c:	86a6                	mv	a3,s1
    80002b2e:	ec04a783          	lw	a5,-320(s1)
    80002b32:	dbed                	beqz	a5,80002b24 <procdump+0x72>
      state = "???";
    80002b34:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b36:	fcfb6be3          	bltu	s6,a5,80002b0c <procdump+0x5a>
    80002b3a:	1782                	slli	a5,a5,0x20
    80002b3c:	9381                	srli	a5,a5,0x20
    80002b3e:	078e                	slli	a5,a5,0x3
    80002b40:	97de                	add	a5,a5,s7
    80002b42:	6390                	ld	a2,0(a5)
    80002b44:	f661                	bnez	a2,80002b0c <procdump+0x5a>
      state = "???";
    80002b46:	864e                	mv	a2,s3
    80002b48:	b7d1                	j	80002b0c <procdump+0x5a>
  }
}
    80002b4a:	60a6                	ld	ra,72(sp)
    80002b4c:	6406                	ld	s0,64(sp)
    80002b4e:	74e2                	ld	s1,56(sp)
    80002b50:	7942                	ld	s2,48(sp)
    80002b52:	79a2                	ld	s3,40(sp)
    80002b54:	7a02                	ld	s4,32(sp)
    80002b56:	6ae2                	ld	s5,24(sp)
    80002b58:	6b42                	ld	s6,16(sp)
    80002b5a:	6ba2                	ld	s7,8(sp)
    80002b5c:	6161                	addi	sp,sp,80
    80002b5e:	8082                	ret

0000000080002b60 <setpriority>:

int setpriority(int new_priority, int proc_pid)
{
    80002b60:	7179                	addi	sp,sp,-48
    80002b62:	f406                	sd	ra,40(sp)
    80002b64:	f022                	sd	s0,32(sp)
    80002b66:	ec26                	sd	s1,24(sp)
    80002b68:	e84a                	sd	s2,16(sp)
    80002b6a:	e44e                	sd	s3,8(sp)
    80002b6c:	e052                	sd	s4,0(sp)
    80002b6e:	1800                	addi	s0,sp,48
    80002b70:	8a2a                	mv	s4,a0
    80002b72:	892e                	mv	s2,a1
  struct proc* p;
  int old_priority;
  int found_proc = 0;
  for(p = proc; p < &proc[NPROC]; p++)
    80002b74:	00010497          	auipc	s1,0x10
    80002b78:	18448493          	addi	s1,s1,388 # 80012cf8 <proc>
    80002b7c:	00017997          	auipc	s3,0x17
    80002b80:	37c98993          	addi	s3,s3,892 # 80019ef8 <tickslock>
  {
    acquire(&p->lock);
    80002b84:	8526                	mv	a0,s1
    80002b86:	ffffe097          	auipc	ra,0xffffe
    80002b8a:	064080e7          	jalr	100(ra) # 80000bea <acquire>
    if (p->pid == proc_pid)
    80002b8e:	589c                	lw	a5,48(s1)
    80002b90:	01278d63          	beq	a5,s2,80002baa <setpriority+0x4a>
      p->priority_pbs = new_priority;
      release(&p->lock);
      found_proc = 1;
      break;
    }
    release(&p->lock);
    80002b94:	8526                	mv	a0,s1
    80002b96:	ffffe097          	auipc	ra,0xffffe
    80002b9a:	108080e7          	jalr	264(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++)
    80002b9e:	1c848493          	addi	s1,s1,456
    80002ba2:	ff3491e3          	bne	s1,s3,80002b84 <setpriority+0x24>
  {
    return old_priority;
  }
  else
  {
    return -1;
    80002ba6:	597d                	li	s2,-1
    80002ba8:	a811                	j	80002bbc <setpriority+0x5c>
      old_priority = p->priority_pbs;
    80002baa:	1a04a903          	lw	s2,416(s1)
      p->priority_pbs = new_priority;
    80002bae:	1b44a023          	sw	s4,416(s1)
      release(&p->lock);
    80002bb2:	8526                	mv	a0,s1
    80002bb4:	ffffe097          	auipc	ra,0xffffe
    80002bb8:	0ea080e7          	jalr	234(ra) # 80000c9e <release>
  }
    80002bbc:	854a                	mv	a0,s2
    80002bbe:	70a2                	ld	ra,40(sp)
    80002bc0:	7402                	ld	s0,32(sp)
    80002bc2:	64e2                	ld	s1,24(sp)
    80002bc4:	6942                	ld	s2,16(sp)
    80002bc6:	69a2                	ld	s3,8(sp)
    80002bc8:	6a02                	ld	s4,0(sp)
    80002bca:	6145                	addi	sp,sp,48
    80002bcc:	8082                	ret

0000000080002bce <swtch>:
    80002bce:	00153023          	sd	ra,0(a0)
    80002bd2:	00253423          	sd	sp,8(a0)
    80002bd6:	e900                	sd	s0,16(a0)
    80002bd8:	ed04                	sd	s1,24(a0)
    80002bda:	03253023          	sd	s2,32(a0)
    80002bde:	03353423          	sd	s3,40(a0)
    80002be2:	03453823          	sd	s4,48(a0)
    80002be6:	03553c23          	sd	s5,56(a0)
    80002bea:	05653023          	sd	s6,64(a0)
    80002bee:	05753423          	sd	s7,72(a0)
    80002bf2:	05853823          	sd	s8,80(a0)
    80002bf6:	05953c23          	sd	s9,88(a0)
    80002bfa:	07a53023          	sd	s10,96(a0)
    80002bfe:	07b53423          	sd	s11,104(a0)
    80002c02:	0005b083          	ld	ra,0(a1)
    80002c06:	0085b103          	ld	sp,8(a1)
    80002c0a:	6980                	ld	s0,16(a1)
    80002c0c:	6d84                	ld	s1,24(a1)
    80002c0e:	0205b903          	ld	s2,32(a1)
    80002c12:	0285b983          	ld	s3,40(a1)
    80002c16:	0305ba03          	ld	s4,48(a1)
    80002c1a:	0385ba83          	ld	s5,56(a1)
    80002c1e:	0405bb03          	ld	s6,64(a1)
    80002c22:	0485bb83          	ld	s7,72(a1)
    80002c26:	0505bc03          	ld	s8,80(a1)
    80002c2a:	0585bc83          	ld	s9,88(a1)
    80002c2e:	0605bd03          	ld	s10,96(a1)
    80002c32:	0685bd83          	ld	s11,104(a1)
    80002c36:	8082                	ret

0000000080002c38 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002c38:	1141                	addi	sp,sp,-16
    80002c3a:	e406                	sd	ra,8(sp)
    80002c3c:	e022                	sd	s0,0(sp)
    80002c3e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002c40:	00006597          	auipc	a1,0x6
    80002c44:	70858593          	addi	a1,a1,1800 # 80009348 <states.1811+0x30>
    80002c48:	00017517          	auipc	a0,0x17
    80002c4c:	2b050513          	addi	a0,a0,688 # 80019ef8 <tickslock>
    80002c50:	ffffe097          	auipc	ra,0xffffe
    80002c54:	f0a080e7          	jalr	-246(ra) # 80000b5a <initlock>
}
    80002c58:	60a2                	ld	ra,8(sp)
    80002c5a:	6402                	ld	s0,0(sp)
    80002c5c:	0141                	addi	sp,sp,16
    80002c5e:	8082                	ret

0000000080002c60 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002c60:	1141                	addi	sp,sp,-16
    80002c62:	e422                	sd	s0,8(sp)
    80002c64:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c66:	00004797          	auipc	a5,0x4
    80002c6a:	c1a78793          	addi	a5,a5,-998 # 80006880 <kernelvec>
    80002c6e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002c72:	6422                	ld	s0,8(sp)
    80002c74:	0141                	addi	sp,sp,16
    80002c76:	8082                	ret

0000000080002c78 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002c78:	1141                	addi	sp,sp,-16
    80002c7a:	e406                	sd	ra,8(sp)
    80002c7c:	e022                	sd	s0,0(sp)
    80002c7e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002c80:	fffff097          	auipc	ra,0xfffff
    80002c84:	f76080e7          	jalr	-138(ra) # 80001bf6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c88:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002c8c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c8e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002c92:	00005617          	auipc	a2,0x5
    80002c96:	36e60613          	addi	a2,a2,878 # 80008000 <_trampoline>
    80002c9a:	00005697          	auipc	a3,0x5
    80002c9e:	36668693          	addi	a3,a3,870 # 80008000 <_trampoline>
    80002ca2:	8e91                	sub	a3,a3,a2
    80002ca4:	040007b7          	lui	a5,0x4000
    80002ca8:	17fd                	addi	a5,a5,-1
    80002caa:	07b2                	slli	a5,a5,0xc
    80002cac:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cae:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002cb2:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002cb4:	180026f3          	csrr	a3,satp
    80002cb8:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002cba:	6d38                	ld	a4,88(a0)
    80002cbc:	6134                	ld	a3,64(a0)
    80002cbe:	6585                	lui	a1,0x1
    80002cc0:	96ae                	add	a3,a3,a1
    80002cc2:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002cc4:	6d38                	ld	a4,88(a0)
    80002cc6:	00000697          	auipc	a3,0x0
    80002cca:	13e68693          	addi	a3,a3,318 # 80002e04 <usertrap>
    80002cce:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002cd0:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002cd2:	8692                	mv	a3,tp
    80002cd4:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cd6:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002cda:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002cde:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ce2:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002ce6:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ce8:	6f18                	ld	a4,24(a4)
    80002cea:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002cee:	6928                	ld	a0,80(a0)
    80002cf0:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002cf2:	00005717          	auipc	a4,0x5
    80002cf6:	3aa70713          	addi	a4,a4,938 # 8000809c <userret>
    80002cfa:	8f11                	sub	a4,a4,a2
    80002cfc:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002cfe:	577d                	li	a4,-1
    80002d00:	177e                	slli	a4,a4,0x3f
    80002d02:	8d59                	or	a0,a0,a4
    80002d04:	9782                	jalr	a5
}
    80002d06:	60a2                	ld	ra,8(sp)
    80002d08:	6402                	ld	s0,0(sp)
    80002d0a:	0141                	addi	sp,sp,16
    80002d0c:	8082                	ret

0000000080002d0e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002d0e:	1101                	addi	sp,sp,-32
    80002d10:	ec06                	sd	ra,24(sp)
    80002d12:	e822                	sd	s0,16(sp)
    80002d14:	e426                	sd	s1,8(sp)
    80002d16:	e04a                	sd	s2,0(sp)
    80002d18:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002d1a:	00017917          	auipc	s2,0x17
    80002d1e:	1de90913          	addi	s2,s2,478 # 80019ef8 <tickslock>
    80002d22:	854a                	mv	a0,s2
    80002d24:	ffffe097          	auipc	ra,0xffffe
    80002d28:	ec6080e7          	jalr	-314(ra) # 80000bea <acquire>
  ticks++;
    80002d2c:	00007497          	auipc	s1,0x7
    80002d30:	eb448493          	addi	s1,s1,-332 # 80009be0 <ticks>
    80002d34:	409c                	lw	a5,0(s1)
    80002d36:	2785                	addiw	a5,a5,1
    80002d38:	c09c                	sw	a5,0(s1)
  update_time();
    80002d3a:	fffff097          	auipc	ra,0xfffff
    80002d3e:	678080e7          	jalr	1656(ra) # 800023b2 <update_time>
  wakeup(&ticks);
    80002d42:	8526                	mv	a0,s1
    80002d44:	00000097          	auipc	ra,0x0
    80002d48:	912080e7          	jalr	-1774(ra) # 80002656 <wakeup>
  release(&tickslock);
    80002d4c:	854a                	mv	a0,s2
    80002d4e:	ffffe097          	auipc	ra,0xffffe
    80002d52:	f50080e7          	jalr	-176(ra) # 80000c9e <release>
}
    80002d56:	60e2                	ld	ra,24(sp)
    80002d58:	6442                	ld	s0,16(sp)
    80002d5a:	64a2                	ld	s1,8(sp)
    80002d5c:	6902                	ld	s2,0(sp)
    80002d5e:	6105                	addi	sp,sp,32
    80002d60:	8082                	ret

0000000080002d62 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002d62:	1101                	addi	sp,sp,-32
    80002d64:	ec06                	sd	ra,24(sp)
    80002d66:	e822                	sd	s0,16(sp)
    80002d68:	e426                	sd	s1,8(sp)
    80002d6a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d6c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002d70:	00074d63          	bltz	a4,80002d8a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002d74:	57fd                	li	a5,-1
    80002d76:	17fe                	slli	a5,a5,0x3f
    80002d78:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002d7a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002d7c:	06f70363          	beq	a4,a5,80002de2 <devintr+0x80>
  }
}
    80002d80:	60e2                	ld	ra,24(sp)
    80002d82:	6442                	ld	s0,16(sp)
    80002d84:	64a2                	ld	s1,8(sp)
    80002d86:	6105                	addi	sp,sp,32
    80002d88:	8082                	ret
     (scause & 0xff) == 9){
    80002d8a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002d8e:	46a5                	li	a3,9
    80002d90:	fed792e3          	bne	a5,a3,80002d74 <devintr+0x12>
    int irq = plic_claim();
    80002d94:	00004097          	auipc	ra,0x4
    80002d98:	bf4080e7          	jalr	-1036(ra) # 80006988 <plic_claim>
    80002d9c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002d9e:	47a9                	li	a5,10
    80002da0:	02f50763          	beq	a0,a5,80002dce <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002da4:	4785                	li	a5,1
    80002da6:	02f50963          	beq	a0,a5,80002dd8 <devintr+0x76>
    return 1;
    80002daa:	4505                	li	a0,1
    } else if(irq){
    80002dac:	d8f1                	beqz	s1,80002d80 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002dae:	85a6                	mv	a1,s1
    80002db0:	00006517          	auipc	a0,0x6
    80002db4:	5a050513          	addi	a0,a0,1440 # 80009350 <states.1811+0x38>
    80002db8:	ffffd097          	auipc	ra,0xffffd
    80002dbc:	7d6080e7          	jalr	2006(ra) # 8000058e <printf>
      plic_complete(irq);
    80002dc0:	8526                	mv	a0,s1
    80002dc2:	00004097          	auipc	ra,0x4
    80002dc6:	bea080e7          	jalr	-1046(ra) # 800069ac <plic_complete>
    return 1;
    80002dca:	4505                	li	a0,1
    80002dcc:	bf55                	j	80002d80 <devintr+0x1e>
      uartintr();
    80002dce:	ffffe097          	auipc	ra,0xffffe
    80002dd2:	be0080e7          	jalr	-1056(ra) # 800009ae <uartintr>
    80002dd6:	b7ed                	j	80002dc0 <devintr+0x5e>
      virtio_disk_intr();
    80002dd8:	00004097          	auipc	ra,0x4
    80002ddc:	0fe080e7          	jalr	254(ra) # 80006ed6 <virtio_disk_intr>
    80002de0:	b7c5                	j	80002dc0 <devintr+0x5e>
    if(cpuid() == 0){
    80002de2:	fffff097          	auipc	ra,0xfffff
    80002de6:	de8080e7          	jalr	-536(ra) # 80001bca <cpuid>
    80002dea:	c901                	beqz	a0,80002dfa <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002dec:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002df0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002df2:	14479073          	csrw	sip,a5
    return 2;
    80002df6:	4509                	li	a0,2
    80002df8:	b761                	j	80002d80 <devintr+0x1e>
      clockintr();
    80002dfa:	00000097          	auipc	ra,0x0
    80002dfe:	f14080e7          	jalr	-236(ra) # 80002d0e <clockintr>
    80002e02:	b7ed                	j	80002dec <devintr+0x8a>

0000000080002e04 <usertrap>:
{
    80002e04:	7179                	addi	sp,sp,-48
    80002e06:	f406                	sd	ra,40(sp)
    80002e08:	f022                	sd	s0,32(sp)
    80002e0a:	ec26                	sd	s1,24(sp)
    80002e0c:	e84a                	sd	s2,16(sp)
    80002e0e:	e44e                	sd	s3,8(sp)
    80002e10:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e12:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002e16:	1007f793          	andi	a5,a5,256
    80002e1a:	e3a5                	bnez	a5,80002e7a <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e1c:	00004797          	auipc	a5,0x4
    80002e20:	a6478793          	addi	a5,a5,-1436 # 80006880 <kernelvec>
    80002e24:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002e28:	fffff097          	auipc	ra,0xfffff
    80002e2c:	dce080e7          	jalr	-562(ra) # 80001bf6 <myproc>
    80002e30:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002e32:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e34:	14102773          	csrr	a4,sepc
    80002e38:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e3a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002e3e:	47a1                	li	a5,8
    80002e40:	04f70563          	beq	a4,a5,80002e8a <usertrap+0x86>
  } else if((which_dev = devintr()) != 0){
    80002e44:	00000097          	auipc	ra,0x0
    80002e48:	f1e080e7          	jalr	-226(ra) # 80002d62 <devintr>
    80002e4c:	892a                	mv	s2,a0
    80002e4e:	cd69                	beqz	a0,80002f28 <usertrap+0x124>
    if(which_dev == 2 && myproc()->interval) {
    80002e50:	4789                	li	a5,2
    80002e52:	06f50763          	beq	a0,a5,80002ec0 <usertrap+0xbc>
  if(killed(p))
    80002e56:	8526                	mv	a0,s1
    80002e58:	00000097          	auipc	ra,0x0
    80002e5c:	a4e080e7          	jalr	-1458(ra) # 800028a6 <killed>
    80002e60:	10051163          	bnez	a0,80002f62 <usertrap+0x15e>
  usertrapret();
    80002e64:	00000097          	auipc	ra,0x0
    80002e68:	e14080e7          	jalr	-492(ra) # 80002c78 <usertrapret>
}
    80002e6c:	70a2                	ld	ra,40(sp)
    80002e6e:	7402                	ld	s0,32(sp)
    80002e70:	64e2                	ld	s1,24(sp)
    80002e72:	6942                	ld	s2,16(sp)
    80002e74:	69a2                	ld	s3,8(sp)
    80002e76:	6145                	addi	sp,sp,48
    80002e78:	8082                	ret
    panic("usertrap: not from user mode");
    80002e7a:	00006517          	auipc	a0,0x6
    80002e7e:	4f650513          	addi	a0,a0,1270 # 80009370 <states.1811+0x58>
    80002e82:	ffffd097          	auipc	ra,0xffffd
    80002e86:	6c2080e7          	jalr	1730(ra) # 80000544 <panic>
    if(killed(p))
    80002e8a:	00000097          	auipc	ra,0x0
    80002e8e:	a1c080e7          	jalr	-1508(ra) # 800028a6 <killed>
    80002e92:	e10d                	bnez	a0,80002eb4 <usertrap+0xb0>
    p->trapframe->epc += 4;
    80002e94:	6cb8                	ld	a4,88(s1)
    80002e96:	6f1c                	ld	a5,24(a4)
    80002e98:	0791                	addi	a5,a5,4
    80002e9a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e9c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002ea0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ea4:	10079073          	csrw	sstatus,a5
    syscall();
    80002ea8:	00000097          	auipc	ra,0x0
    80002eac:	422080e7          	jalr	1058(ra) # 800032ca <syscall>
  int which_dev = 0;
    80002eb0:	4901                	li	s2,0
    80002eb2:	b755                	j	80002e56 <usertrap+0x52>
      exit(-1);
    80002eb4:	557d                	li	a0,-1
    80002eb6:	00000097          	auipc	ra,0x0
    80002eba:	870080e7          	jalr	-1936(ra) # 80002726 <exit>
    80002ebe:	bfd9                	j	80002e94 <usertrap+0x90>
    if(which_dev == 2 && myproc()->interval) {
    80002ec0:	fffff097          	auipc	ra,0xfffff
    80002ec4:	d36080e7          	jalr	-714(ra) # 80001bf6 <myproc>
    80002ec8:	17852783          	lw	a5,376(a0)
    80002ecc:	ef89                	bnez	a5,80002ee6 <usertrap+0xe2>
  if(killed(p))
    80002ece:	8526                	mv	a0,s1
    80002ed0:	00000097          	auipc	ra,0x0
    80002ed4:	9d6080e7          	jalr	-1578(ra) # 800028a6 <killed>
    80002ed8:	cd49                	beqz	a0,80002f72 <usertrap+0x16e>
    exit(-1);
    80002eda:	557d                	li	a0,-1
    80002edc:	00000097          	auipc	ra,0x0
    80002ee0:	84a080e7          	jalr	-1974(ra) # 80002726 <exit>
    if(which_dev == 2 && myproc()->state == RUNNING && myproc() != 0) {
    80002ee4:	a079                	j	80002f72 <usertrap+0x16e>
      myproc()->ticks_left--;
    80002ee6:	fffff097          	auipc	ra,0xfffff
    80002eea:	d10080e7          	jalr	-752(ra) # 80001bf6 <myproc>
    80002eee:	17c52783          	lw	a5,380(a0)
    80002ef2:	37fd                	addiw	a5,a5,-1
    80002ef4:	16f52e23          	sw	a5,380(a0)
      if(myproc()->ticks_left == 0) {
    80002ef8:	fffff097          	auipc	ra,0xfffff
    80002efc:	cfe080e7          	jalr	-770(ra) # 80001bf6 <myproc>
    80002f00:	17c52783          	lw	a5,380(a0)
    80002f04:	f7e9                	bnez	a5,80002ece <usertrap+0xca>
        p->sigalarm_tf = kalloc();
    80002f06:	ffffe097          	auipc	ra,0xffffe
    80002f0a:	bf4080e7          	jalr	-1036(ra) # 80000afa <kalloc>
    80002f0e:	18a4b423          	sd	a0,392(s1)
        memmove(p->sigalarm_tf, p->trapframe, PGSIZE);
    80002f12:	6605                	lui	a2,0x1
    80002f14:	6cac                	ld	a1,88(s1)
    80002f16:	ffffe097          	auipc	ra,0xffffe
    80002f1a:	e30080e7          	jalr	-464(ra) # 80000d46 <memmove>
        p->trapframe->epc = p->sig_handler;
    80002f1e:	6cbc                	ld	a5,88(s1)
    80002f20:	1804b703          	ld	a4,384(s1)
    80002f24:	ef98                	sd	a4,24(a5)
    80002f26:	b765                	j	80002ece <usertrap+0xca>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f28:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002f2c:	5890                	lw	a2,48(s1)
    80002f2e:	00006517          	auipc	a0,0x6
    80002f32:	46250513          	addi	a0,a0,1122 # 80009390 <states.1811+0x78>
    80002f36:	ffffd097          	auipc	ra,0xffffd
    80002f3a:	658080e7          	jalr	1624(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f3e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f42:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f46:	00006517          	auipc	a0,0x6
    80002f4a:	47a50513          	addi	a0,a0,1146 # 800093c0 <states.1811+0xa8>
    80002f4e:	ffffd097          	auipc	ra,0xffffd
    80002f52:	640080e7          	jalr	1600(ra) # 8000058e <printf>
    setkilled(p);
    80002f56:	8526                	mv	a0,s1
    80002f58:	00000097          	auipc	ra,0x0
    80002f5c:	922080e7          	jalr	-1758(ra) # 8000287a <setkilled>
    80002f60:	bddd                	j	80002e56 <usertrap+0x52>
    exit(-1);
    80002f62:	557d                	li	a0,-1
    80002f64:	fffff097          	auipc	ra,0xfffff
    80002f68:	7c2080e7          	jalr	1986(ra) # 80002726 <exit>
    if(which_dev == 2 && myproc()->state == RUNNING && myproc() != 0) {
    80002f6c:	4789                	li	a5,2
    80002f6e:	eef91be3          	bne	s2,a5,80002e64 <usertrap+0x60>
    80002f72:	fffff097          	auipc	ra,0xfffff
    80002f76:	c84080e7          	jalr	-892(ra) # 80001bf6 <myproc>
    80002f7a:	4d18                	lw	a4,24(a0)
    80002f7c:	4791                	li	a5,4
    80002f7e:	eef713e3          	bne	a4,a5,80002e64 <usertrap+0x60>
    80002f82:	fffff097          	auipc	ra,0xfffff
    80002f86:	c74080e7          	jalr	-908(ra) # 80001bf6 <myproc>
    80002f8a:	ec050de3          	beqz	a0,80002e64 <usertrap+0x60>
      if(p->curr_rtime >= priority_levels[p->priority]) {
    80002f8e:	1bc4a683          	lw	a3,444(s1)
    80002f92:	1b44a703          	lw	a4,436(s1)
    80002f96:	00271613          	slli	a2,a4,0x2
    80002f9a:	00007797          	auipc	a5,0x7
    80002f9e:	afe78793          	addi	a5,a5,-1282 # 80009a98 <priority_levels>
    80002fa2:	97b2                	add	a5,a5,a2
    80002fa4:	439c                	lw	a5,0(a5)
    80002fa6:	00f6da63          	bge	a3,a5,80002fba <usertrap+0x1b6>
        for(int i = 0; i < p->priority; i++) {
    80002faa:	0000f997          	auipc	s3,0xf
    80002fae:	2de98993          	addi	s3,s3,734 # 80012288 <queues+0x8>
    80002fb2:	4901                	li	s2,0
    80002fb4:	04e04863          	bgtz	a4,80003004 <usertrap+0x200>
    80002fb8:	b575                	j	80002e64 <usertrap+0x60>
        if(p->priority != 4) {
    80002fba:	4791                	li	a5,4
    80002fbc:	00f70563          	beq	a4,a5,80002fc6 <usertrap+0x1c2>
          p->priority++;
    80002fc0:	2705                	addiw	a4,a4,1
    80002fc2:	1ae4aa23          	sw	a4,436(s1)
        printf("%d %d %d %d\n", p->priority, p->pid, p->curr_rtime, ticks);
    80002fc6:	00007717          	auipc	a4,0x7
    80002fca:	c1a72703          	lw	a4,-998(a4) # 80009be0 <ticks>
    80002fce:	5890                	lw	a2,48(s1)
    80002fd0:	1b44a583          	lw	a1,436(s1)
    80002fd4:	00006517          	auipc	a0,0x6
    80002fd8:	40c50513          	addi	a0,a0,1036 # 800093e0 <states.1811+0xc8>
    80002fdc:	ffffd097          	auipc	ra,0xffffd
    80002fe0:	5b2080e7          	jalr	1458(ra) # 8000058e <printf>
        p->curr_rtime = 0;
    80002fe4:	1a04ae23          	sw	zero,444(s1)
        p->curr_wtime = 0;
    80002fe8:	1c04a023          	sw	zero,448(s1)
        yield();
    80002fec:	fffff097          	auipc	ra,0xfffff
    80002ff0:	38a080e7          	jalr	906(ra) # 80002376 <yield>
    80002ff4:	bd85                	j	80002e64 <usertrap+0x60>
        for(int i = 0; i < p->priority; i++) {
    80002ff6:	2905                	addiw	s2,s2,1
    80002ff8:	21898993          	addi	s3,s3,536
    80002ffc:	1b44a783          	lw	a5,436(s1)
    80003000:	e6f952e3          	bge	s2,a5,80002e64 <usertrap+0x60>
          if(queues[i].length > 0) {
    80003004:	0009a783          	lw	a5,0(s3)
    80003008:	fef057e3          	blez	a5,80002ff6 <usertrap+0x1f2>
            yield();
    8000300c:	fffff097          	auipc	ra,0xfffff
    80003010:	36a080e7          	jalr	874(ra) # 80002376 <yield>
    80003014:	b7cd                	j	80002ff6 <usertrap+0x1f2>

0000000080003016 <kerneltrap>:
{
    80003016:	7139                	addi	sp,sp,-64
    80003018:	fc06                	sd	ra,56(sp)
    8000301a:	f822                	sd	s0,48(sp)
    8000301c:	f426                	sd	s1,40(sp)
    8000301e:	f04a                	sd	s2,32(sp)
    80003020:	ec4e                	sd	s3,24(sp)
    80003022:	e852                	sd	s4,16(sp)
    80003024:	e456                	sd	s5,8(sp)
    80003026:	0080                	addi	s0,sp,64
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003028:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000302c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003030:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80003034:	1004f793          	andi	a5,s1,256
    80003038:	cb95                	beqz	a5,8000306c <kerneltrap+0x56>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000303a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000303e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80003040:	ef95                	bnez	a5,8000307c <kerneltrap+0x66>
  if((which_dev = devintr()) == 0){
    80003042:	00000097          	auipc	ra,0x0
    80003046:	d20080e7          	jalr	-736(ra) # 80002d62 <devintr>
    8000304a:	c129                	beqz	a0,8000308c <kerneltrap+0x76>
    if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING) {
    8000304c:	4789                	li	a5,2
    8000304e:	06f50c63          	beq	a0,a5,800030c6 <kerneltrap+0xb0>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003052:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003056:	10049073          	csrw	sstatus,s1
}
    8000305a:	70e2                	ld	ra,56(sp)
    8000305c:	7442                	ld	s0,48(sp)
    8000305e:	74a2                	ld	s1,40(sp)
    80003060:	7902                	ld	s2,32(sp)
    80003062:	69e2                	ld	s3,24(sp)
    80003064:	6a42                	ld	s4,16(sp)
    80003066:	6aa2                	ld	s5,8(sp)
    80003068:	6121                	addi	sp,sp,64
    8000306a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000306c:	00006517          	auipc	a0,0x6
    80003070:	38450513          	addi	a0,a0,900 # 800093f0 <states.1811+0xd8>
    80003074:	ffffd097          	auipc	ra,0xffffd
    80003078:	4d0080e7          	jalr	1232(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    8000307c:	00006517          	auipc	a0,0x6
    80003080:	39c50513          	addi	a0,a0,924 # 80009418 <states.1811+0x100>
    80003084:	ffffd097          	auipc	ra,0xffffd
    80003088:	4c0080e7          	jalr	1216(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    8000308c:	85ce                	mv	a1,s3
    8000308e:	00006517          	auipc	a0,0x6
    80003092:	3aa50513          	addi	a0,a0,938 # 80009438 <states.1811+0x120>
    80003096:	ffffd097          	auipc	ra,0xffffd
    8000309a:	4f8080e7          	jalr	1272(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000309e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800030a2:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800030a6:	00006517          	auipc	a0,0x6
    800030aa:	3a250513          	addi	a0,a0,930 # 80009448 <states.1811+0x130>
    800030ae:	ffffd097          	auipc	ra,0xffffd
    800030b2:	4e0080e7          	jalr	1248(ra) # 8000058e <printf>
    panic("kerneltrap");
    800030b6:	00006517          	auipc	a0,0x6
    800030ba:	3aa50513          	addi	a0,a0,938 # 80009460 <states.1811+0x148>
    800030be:	ffffd097          	auipc	ra,0xffffd
    800030c2:	486080e7          	jalr	1158(ra) # 80000544 <panic>
    if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING) {
    800030c6:	fffff097          	auipc	ra,0xfffff
    800030ca:	b30080e7          	jalr	-1232(ra) # 80001bf6 <myproc>
    800030ce:	d151                	beqz	a0,80003052 <kerneltrap+0x3c>
    800030d0:	fffff097          	auipc	ra,0xfffff
    800030d4:	b26080e7          	jalr	-1242(ra) # 80001bf6 <myproc>
    800030d8:	4d18                	lw	a4,24(a0)
    800030da:	4791                	li	a5,4
    800030dc:	f6f71be3          	bne	a4,a5,80003052 <kerneltrap+0x3c>
      struct proc* p = myproc();
    800030e0:	fffff097          	auipc	ra,0xfffff
    800030e4:	b16080e7          	jalr	-1258(ra) # 80001bf6 <myproc>
    800030e8:	8aaa                	mv	s5,a0
      if(p->curr_rtime >= priority_levels[p->priority]) {
    800030ea:	1b452703          	lw	a4,436(a0)
    800030ee:	00271693          	slli	a3,a4,0x2
    800030f2:	00007797          	auipc	a5,0x7
    800030f6:	9a678793          	addi	a5,a5,-1626 # 80009a98 <priority_levels>
    800030fa:	97b6                	add	a5,a5,a3
    800030fc:	1bc52683          	lw	a3,444(a0)
    80003100:	439c                	lw	a5,0(a5)
    80003102:	00f6da63          	bge	a3,a5,80003116 <kerneltrap+0x100>
        for(int i = 0; i < p->priority; i++) {
    80003106:	0000fa17          	auipc	s4,0xf
    8000310a:	182a0a13          	addi	s4,s4,386 # 80012288 <queues+0x8>
    8000310e:	4981                	li	s3,0
    80003110:	02e04563          	bgtz	a4,8000313a <kerneltrap+0x124>
    80003114:	bf3d                	j	80003052 <kerneltrap+0x3c>
        if(p->priority != 4) {
    80003116:	4791                	li	a5,4
    80003118:	00f70563          	beq	a4,a5,80003122 <kerneltrap+0x10c>
          p->priority++;
    8000311c:	2705                	addiw	a4,a4,1
    8000311e:	1ae52a23          	sw	a4,436(a0)
        yield();
    80003122:	fffff097          	auipc	ra,0xfffff
    80003126:	254080e7          	jalr	596(ra) # 80002376 <yield>
    8000312a:	b725                	j	80003052 <kerneltrap+0x3c>
        for(int i = 0; i < p->priority; i++) {
    8000312c:	2985                	addiw	s3,s3,1
    8000312e:	218a0a13          	addi	s4,s4,536
    80003132:	1b4aa783          	lw	a5,436(s5)
    80003136:	f0f9dee3          	bge	s3,a5,80003052 <kerneltrap+0x3c>
          if(queues[i].length > 0) {
    8000313a:	000a2783          	lw	a5,0(s4)
    8000313e:	fef057e3          	blez	a5,8000312c <kerneltrap+0x116>
            yield();
    80003142:	fffff097          	auipc	ra,0xfffff
    80003146:	234080e7          	jalr	564(ra) # 80002376 <yield>
    8000314a:	b7cd                	j	8000312c <kerneltrap+0x116>

000000008000314c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000314c:	1101                	addi	sp,sp,-32
    8000314e:	ec06                	sd	ra,24(sp)
    80003150:	e822                	sd	s0,16(sp)
    80003152:	e426                	sd	s1,8(sp)
    80003154:	1000                	addi	s0,sp,32
    80003156:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003158:	fffff097          	auipc	ra,0xfffff
    8000315c:	a9e080e7          	jalr	-1378(ra) # 80001bf6 <myproc>
  switch (n) {
    80003160:	4795                	li	a5,5
    80003162:	0497e163          	bltu	a5,s1,800031a4 <argraw+0x58>
    80003166:	048a                	slli	s1,s1,0x2
    80003168:	00006717          	auipc	a4,0x6
    8000316c:	4a870713          	addi	a4,a4,1192 # 80009610 <states.1811+0x2f8>
    80003170:	94ba                	add	s1,s1,a4
    80003172:	409c                	lw	a5,0(s1)
    80003174:	97ba                	add	a5,a5,a4
    80003176:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003178:	6d3c                	ld	a5,88(a0)
    8000317a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000317c:	60e2                	ld	ra,24(sp)
    8000317e:	6442                	ld	s0,16(sp)
    80003180:	64a2                	ld	s1,8(sp)
    80003182:	6105                	addi	sp,sp,32
    80003184:	8082                	ret
    return p->trapframe->a1;
    80003186:	6d3c                	ld	a5,88(a0)
    80003188:	7fa8                	ld	a0,120(a5)
    8000318a:	bfcd                	j	8000317c <argraw+0x30>
    return p->trapframe->a2;
    8000318c:	6d3c                	ld	a5,88(a0)
    8000318e:	63c8                	ld	a0,128(a5)
    80003190:	b7f5                	j	8000317c <argraw+0x30>
    return p->trapframe->a3;
    80003192:	6d3c                	ld	a5,88(a0)
    80003194:	67c8                	ld	a0,136(a5)
    80003196:	b7dd                	j	8000317c <argraw+0x30>
    return p->trapframe->a4;
    80003198:	6d3c                	ld	a5,88(a0)
    8000319a:	6bc8                	ld	a0,144(a5)
    8000319c:	b7c5                	j	8000317c <argraw+0x30>
    return p->trapframe->a5;
    8000319e:	6d3c                	ld	a5,88(a0)
    800031a0:	6fc8                	ld	a0,152(a5)
    800031a2:	bfe9                	j	8000317c <argraw+0x30>
  panic("argraw");
    800031a4:	00006517          	auipc	a0,0x6
    800031a8:	2cc50513          	addi	a0,a0,716 # 80009470 <states.1811+0x158>
    800031ac:	ffffd097          	auipc	ra,0xffffd
    800031b0:	398080e7          	jalr	920(ra) # 80000544 <panic>

00000000800031b4 <fetchaddr>:
{
    800031b4:	1101                	addi	sp,sp,-32
    800031b6:	ec06                	sd	ra,24(sp)
    800031b8:	e822                	sd	s0,16(sp)
    800031ba:	e426                	sd	s1,8(sp)
    800031bc:	e04a                	sd	s2,0(sp)
    800031be:	1000                	addi	s0,sp,32
    800031c0:	84aa                	mv	s1,a0
    800031c2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800031c4:	fffff097          	auipc	ra,0xfffff
    800031c8:	a32080e7          	jalr	-1486(ra) # 80001bf6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    800031cc:	653c                	ld	a5,72(a0)
    800031ce:	02f4f863          	bgeu	s1,a5,800031fe <fetchaddr+0x4a>
    800031d2:	00848713          	addi	a4,s1,8
    800031d6:	02e7e663          	bltu	a5,a4,80003202 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800031da:	46a1                	li	a3,8
    800031dc:	8626                	mv	a2,s1
    800031de:	85ca                	mv	a1,s2
    800031e0:	6928                	ld	a0,80(a0)
    800031e2:	ffffe097          	auipc	ra,0xffffe
    800031e6:	52e080e7          	jalr	1326(ra) # 80001710 <copyin>
    800031ea:	00a03533          	snez	a0,a0
    800031ee:	40a00533          	neg	a0,a0
}
    800031f2:	60e2                	ld	ra,24(sp)
    800031f4:	6442                	ld	s0,16(sp)
    800031f6:	64a2                	ld	s1,8(sp)
    800031f8:	6902                	ld	s2,0(sp)
    800031fa:	6105                	addi	sp,sp,32
    800031fc:	8082                	ret
    return -1;
    800031fe:	557d                	li	a0,-1
    80003200:	bfcd                	j	800031f2 <fetchaddr+0x3e>
    80003202:	557d                	li	a0,-1
    80003204:	b7fd                	j	800031f2 <fetchaddr+0x3e>

0000000080003206 <fetchstr>:
{
    80003206:	7179                	addi	sp,sp,-48
    80003208:	f406                	sd	ra,40(sp)
    8000320a:	f022                	sd	s0,32(sp)
    8000320c:	ec26                	sd	s1,24(sp)
    8000320e:	e84a                	sd	s2,16(sp)
    80003210:	e44e                	sd	s3,8(sp)
    80003212:	1800                	addi	s0,sp,48
    80003214:	892a                	mv	s2,a0
    80003216:	84ae                	mv	s1,a1
    80003218:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000321a:	fffff097          	auipc	ra,0xfffff
    8000321e:	9dc080e7          	jalr	-1572(ra) # 80001bf6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80003222:	86ce                	mv	a3,s3
    80003224:	864a                	mv	a2,s2
    80003226:	85a6                	mv	a1,s1
    80003228:	6928                	ld	a0,80(a0)
    8000322a:	ffffe097          	auipc	ra,0xffffe
    8000322e:	572080e7          	jalr	1394(ra) # 8000179c <copyinstr>
    80003232:	00054e63          	bltz	a0,8000324e <fetchstr+0x48>
  return strlen(buf);
    80003236:	8526                	mv	a0,s1
    80003238:	ffffe097          	auipc	ra,0xffffe
    8000323c:	c32080e7          	jalr	-974(ra) # 80000e6a <strlen>
}
    80003240:	70a2                	ld	ra,40(sp)
    80003242:	7402                	ld	s0,32(sp)
    80003244:	64e2                	ld	s1,24(sp)
    80003246:	6942                	ld	s2,16(sp)
    80003248:	69a2                	ld	s3,8(sp)
    8000324a:	6145                	addi	sp,sp,48
    8000324c:	8082                	ret
    return -1;
    8000324e:	557d                	li	a0,-1
    80003250:	bfc5                	j	80003240 <fetchstr+0x3a>

0000000080003252 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80003252:	1101                	addi	sp,sp,-32
    80003254:	ec06                	sd	ra,24(sp)
    80003256:	e822                	sd	s0,16(sp)
    80003258:	e426                	sd	s1,8(sp)
    8000325a:	1000                	addi	s0,sp,32
    8000325c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000325e:	00000097          	auipc	ra,0x0
    80003262:	eee080e7          	jalr	-274(ra) # 8000314c <argraw>
    80003266:	c088                	sw	a0,0(s1)
}
    80003268:	60e2                	ld	ra,24(sp)
    8000326a:	6442                	ld	s0,16(sp)
    8000326c:	64a2                	ld	s1,8(sp)
    8000326e:	6105                	addi	sp,sp,32
    80003270:	8082                	ret

0000000080003272 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80003272:	1101                	addi	sp,sp,-32
    80003274:	ec06                	sd	ra,24(sp)
    80003276:	e822                	sd	s0,16(sp)
    80003278:	e426                	sd	s1,8(sp)
    8000327a:	1000                	addi	s0,sp,32
    8000327c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000327e:	00000097          	auipc	ra,0x0
    80003282:	ece080e7          	jalr	-306(ra) # 8000314c <argraw>
    80003286:	e088                	sd	a0,0(s1)
}
    80003288:	60e2                	ld	ra,24(sp)
    8000328a:	6442                	ld	s0,16(sp)
    8000328c:	64a2                	ld	s1,8(sp)
    8000328e:	6105                	addi	sp,sp,32
    80003290:	8082                	ret

0000000080003292 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003292:	7179                	addi	sp,sp,-48
    80003294:	f406                	sd	ra,40(sp)
    80003296:	f022                	sd	s0,32(sp)
    80003298:	ec26                	sd	s1,24(sp)
    8000329a:	e84a                	sd	s2,16(sp)
    8000329c:	1800                	addi	s0,sp,48
    8000329e:	84ae                	mv	s1,a1
    800032a0:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800032a2:	fd840593          	addi	a1,s0,-40
    800032a6:	00000097          	auipc	ra,0x0
    800032aa:	fcc080e7          	jalr	-52(ra) # 80003272 <argaddr>
  return fetchstr(addr, buf, max);
    800032ae:	864a                	mv	a2,s2
    800032b0:	85a6                	mv	a1,s1
    800032b2:	fd843503          	ld	a0,-40(s0)
    800032b6:	00000097          	auipc	ra,0x0
    800032ba:	f50080e7          	jalr	-176(ra) # 80003206 <fetchstr>
}
    800032be:	70a2                	ld	ra,40(sp)
    800032c0:	7402                	ld	s0,32(sp)
    800032c2:	64e2                	ld	s1,24(sp)
    800032c4:	6942                	ld	s2,16(sp)
    800032c6:	6145                	addi	sp,sp,48
    800032c8:	8082                	ret

00000000800032ca <syscall>:
[SYS_setpriority] "sys_setpriority",
};

void
syscall(void)
{
    800032ca:	7179                	addi	sp,sp,-48
    800032cc:	f406                	sd	ra,40(sp)
    800032ce:	f022                	sd	s0,32(sp)
    800032d0:	ec26                	sd	s1,24(sp)
    800032d2:	e84a                	sd	s2,16(sp)
    800032d4:	e44e                	sd	s3,8(sp)
    800032d6:	e052                	sd	s4,0(sp)
    800032d8:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    800032da:	fffff097          	auipc	ra,0xfffff
    800032de:	91c080e7          	jalr	-1764(ra) # 80001bf6 <myproc>
    800032e2:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800032e4:	05853903          	ld	s2,88(a0)
    800032e8:	0a893783          	ld	a5,168(s2)
    800032ec:	0007899b          	sext.w	s3,a5
  unsigned int tmp = p->trapframe->a0;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800032f0:	37fd                	addiw	a5,a5,-1
    800032f2:	4769                	li	a4,26
    800032f4:	42f76863          	bltu	a4,a5,80003724 <syscall+0x45a>
    800032f8:	00399713          	slli	a4,s3,0x3
    800032fc:	00006797          	auipc	a5,0x6
    80003300:	32c78793          	addi	a5,a5,812 # 80009628 <syscalls>
    80003304:	97ba                	add	a5,a5,a4
    80003306:	639c                	ld	a5,0(a5)
    80003308:	40078e63          	beqz	a5,80003724 <syscall+0x45a>
  unsigned int tmp = p->trapframe->a0;
    8000330c:	07093a03          	ld	s4,112(s2)
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80003310:	9782                	jalr	a5
    80003312:	06a93823          	sd	a0,112(s2)

    // Check for trace_flag to be on
    if(p->trace_flag >> num) {  // check for '=='
    80003316:	1744a783          	lw	a5,372(s1)
    8000331a:	4137d7bb          	sraw	a5,a5,s3
    8000331e:	42078263          	beqz	a5,80003742 <syscall+0x478>
      if(num == 1)      printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0);   //fork  
    80003322:	4785                	li	a5,1
    80003324:	0cf98263          	beq	s3,a5,800033e8 <syscall+0x11e>
  unsigned int tmp = p->trapframe->a0;
    80003328:	000a069b          	sext.w	a3,s4
      else if(num == 2) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // exit
    8000332c:	4789                	li	a5,2
    8000332e:	0cf98d63          	beq	s3,a5,80003408 <syscall+0x13e>
      else if(num == 3) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // wait
    80003332:	478d                	li	a5,3
    80003334:	0ef98a63          	beq	s3,a5,80003428 <syscall+0x15e>
      else if(num == 4) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // pipe
    80003338:	4791                	li	a5,4
    8000333a:	10f98763          	beq	s3,a5,80003448 <syscall+0x17e>
      else if(num == 5) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp,  p->trapframe->a1,  p->trapframe->a2, p->trapframe->a0);  // read
    8000333e:	4795                	li	a5,5
    80003340:	12f98463          	beq	s3,a5,80003468 <syscall+0x19e>
      else if(num == 6) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // kill
    80003344:	4799                	li	a5,6
    80003346:	14f98463          	beq	s3,a5,8000348e <syscall+0x1c4>
      else if(num == 7) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp,  p->trapframe->a1, p->trapframe->a0);   // exec
    8000334a:	479d                	li	a5,7
    8000334c:	16f98163          	beq	s3,a5,800034ae <syscall+0x1e4>
      else if(num == 8) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp,  p->trapframe->a1, p->trapframe->a0);  // fstat
    80003350:	47a1                	li	a5,8
    80003352:	16f98f63          	beq	s3,a5,800034d0 <syscall+0x206>
      else if(num == 9) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // chdir
    80003356:	47a5                	li	a5,9
    80003358:	18f98d63          	beq	s3,a5,800034f2 <syscall+0x228>
      else if(num == 10) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // dup
    8000335c:	47a9                	li	a5,10
    8000335e:	1af98a63          	beq	s3,a5,80003512 <syscall+0x248>
      else if(num == 11) printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0);  // getpid
    80003362:	47ad                	li	a5,11
    80003364:	1cf98763          	beq	s3,a5,80003532 <syscall+0x268>
      else if(num == 12) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // sbrk
    80003368:	47b1                	li	a5,12
    8000336a:	1ef98463          	beq	s3,a5,80003552 <syscall+0x288>
      else if(num == 13) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // sleep
    8000336e:	47b5                	li	a5,13
    80003370:	20f98163          	beq	s3,a5,80003572 <syscall+0x2a8>
      else if(num == 14) printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0); // uptime
    80003374:	47b9                	li	a5,14
    80003376:	20f98e63          	beq	s3,a5,80003592 <syscall+0x2c8>
      else if(num == 15) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a0); // open
    8000337a:	47bd                	li	a5,15
    8000337c:	22f98b63          	beq	s3,a5,800035b2 <syscall+0x2e8>
      else if(num == 16) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a3, p->trapframe->a0); // write
    80003380:	47c1                	li	a5,16
    80003382:	24f98963          	beq	s3,a5,800035d4 <syscall+0x30a>
      else if(num == 17) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a3, p->trapframe->a0); // mknod
    80003386:	47c5                	li	a5,17
    80003388:	26f98963          	beq	s3,a5,800035fa <syscall+0x330>
      else if(num == 18) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // unlink
    8000338c:	47c9                	li	a5,18
    8000338e:	28f98963          	beq	s3,a5,80003620 <syscall+0x356>
      else if(num == 19) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a0); // link
    80003392:	47cd                	li	a5,19
    80003394:	2af98663          	beq	s3,a5,80003640 <syscall+0x376>
      else if(num == 20) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // mkdir
    80003398:	47d1                	li	a5,20
    8000339a:	2cf98463          	beq	s3,a5,80003662 <syscall+0x398>
      else if(num == 21) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // close
    8000339e:	47d5                	li	a5,21
    800033a0:	2ef98163          	beq	s3,a5,80003682 <syscall+0x3b8>
      else if(num == 22) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // trace
    800033a4:	47d9                	li	a5,22
    800033a6:	2ef98e63          	beq	s3,a5,800036a2 <syscall+0x3d8>
      else if(num == 23) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a0); // sigalarm
    800033aa:	47dd                	li	a5,23
    800033ac:	30f98b63          	beq	s3,a5,800036c2 <syscall+0x3f8>
      else if(num == 24) printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0); // sigreturn
    800033b0:	47e1                	li	a5,24
    800033b2:	32f98963          	beq	s3,a5,800036e4 <syscall+0x41a>
      else if(num == 25) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // settickets
    800033b6:	47e5                	li	a5,25
    800033b8:	34f98663          	beq	s3,a5,80003704 <syscall+0x43a>
      else if(num == 26) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a1, p->trapframe->a2, p->trapframe->a0); // waitx
    800033bc:	47e9                	li	a5,26
    800033be:	38f99263          	bne	s3,a5,80003742 <syscall+0x478>
    800033c2:	6cb8                	ld	a4,88(s1)
    800033c4:	07073803          	ld	a6,112(a4)
    800033c8:	635c                	ld	a5,128(a4)
    800033ca:	7f38                	ld	a4,120(a4)
    800033cc:	00006617          	auipc	a2,0x6
    800033d0:	7b463603          	ld	a2,1972(a2) # 80009b80 <syscall_names+0xd0>
    800033d4:	588c                	lw	a1,48(s1)
    800033d6:	00006517          	auipc	a0,0x6
    800033da:	0da50513          	addi	a0,a0,218 # 800094b0 <states.1811+0x198>
    800033de:	ffffd097          	auipc	ra,0xffffd
    800033e2:	1b0080e7          	jalr	432(ra) # 8000058e <printf>
    800033e6:	aeb1                	j	80003742 <syscall+0x478>
      if(num == 1)      printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0);   //fork  
    800033e8:	6cbc                	ld	a5,88(s1)
    800033ea:	7bb4                	ld	a3,112(a5)
    800033ec:	00006617          	auipc	a2,0x6
    800033f0:	6cc63603          	ld	a2,1740(a2) # 80009ab8 <syscall_names+0x8>
    800033f4:	588c                	lw	a1,48(s1)
    800033f6:	00006517          	auipc	a0,0x6
    800033fa:	08250513          	addi	a0,a0,130 # 80009478 <states.1811+0x160>
    800033fe:	ffffd097          	auipc	ra,0xffffd
    80003402:	190080e7          	jalr	400(ra) # 8000058e <printf>
    80003406:	ae35                	j	80003742 <syscall+0x478>
      else if(num == 2) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // exit
    80003408:	6cbc                	ld	a5,88(s1)
    8000340a:	7bb8                	ld	a4,112(a5)
    8000340c:	00006617          	auipc	a2,0x6
    80003410:	6b463603          	ld	a2,1716(a2) # 80009ac0 <syscall_names+0x10>
    80003414:	588c                	lw	a1,48(s1)
    80003416:	00006517          	auipc	a0,0x6
    8000341a:	07a50513          	addi	a0,a0,122 # 80009490 <states.1811+0x178>
    8000341e:	ffffd097          	auipc	ra,0xffffd
    80003422:	170080e7          	jalr	368(ra) # 8000058e <printf>
    80003426:	ae31                	j	80003742 <syscall+0x478>
      else if(num == 3) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // wait
    80003428:	6cbc                	ld	a5,88(s1)
    8000342a:	7bb8                	ld	a4,112(a5)
    8000342c:	00006617          	auipc	a2,0x6
    80003430:	69c63603          	ld	a2,1692(a2) # 80009ac8 <syscall_names+0x18>
    80003434:	588c                	lw	a1,48(s1)
    80003436:	00006517          	auipc	a0,0x6
    8000343a:	05a50513          	addi	a0,a0,90 # 80009490 <states.1811+0x178>
    8000343e:	ffffd097          	auipc	ra,0xffffd
    80003442:	150080e7          	jalr	336(ra) # 8000058e <printf>
    80003446:	acf5                	j	80003742 <syscall+0x478>
      else if(num == 4) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // pipe
    80003448:	6cbc                	ld	a5,88(s1)
    8000344a:	7bb8                	ld	a4,112(a5)
    8000344c:	00006617          	auipc	a2,0x6
    80003450:	68463603          	ld	a2,1668(a2) # 80009ad0 <syscall_names+0x20>
    80003454:	588c                	lw	a1,48(s1)
    80003456:	00006517          	auipc	a0,0x6
    8000345a:	03a50513          	addi	a0,a0,58 # 80009490 <states.1811+0x178>
    8000345e:	ffffd097          	auipc	ra,0xffffd
    80003462:	130080e7          	jalr	304(ra) # 8000058e <printf>
    80003466:	acf1                	j	80003742 <syscall+0x478>
      else if(num == 5) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp,  p->trapframe->a1,  p->trapframe->a2, p->trapframe->a0);  // read
    80003468:	6cb8                	ld	a4,88(s1)
    8000346a:	07073803          	ld	a6,112(a4)
    8000346e:	635c                	ld	a5,128(a4)
    80003470:	7f38                	ld	a4,120(a4)
    80003472:	00006617          	auipc	a2,0x6
    80003476:	66663603          	ld	a2,1638(a2) # 80009ad8 <syscall_names+0x28>
    8000347a:	588c                	lw	a1,48(s1)
    8000347c:	00006517          	auipc	a0,0x6
    80003480:	03450513          	addi	a0,a0,52 # 800094b0 <states.1811+0x198>
    80003484:	ffffd097          	auipc	ra,0xffffd
    80003488:	10a080e7          	jalr	266(ra) # 8000058e <printf>
    8000348c:	ac5d                	j	80003742 <syscall+0x478>
      else if(num == 6) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // kill
    8000348e:	6cbc                	ld	a5,88(s1)
    80003490:	7bb8                	ld	a4,112(a5)
    80003492:	00006617          	auipc	a2,0x6
    80003496:	64e63603          	ld	a2,1614(a2) # 80009ae0 <syscall_names+0x30>
    8000349a:	588c                	lw	a1,48(s1)
    8000349c:	00006517          	auipc	a0,0x6
    800034a0:	ff450513          	addi	a0,a0,-12 # 80009490 <states.1811+0x178>
    800034a4:	ffffd097          	auipc	ra,0xffffd
    800034a8:	0ea080e7          	jalr	234(ra) # 8000058e <printf>
    800034ac:	ac59                	j	80003742 <syscall+0x478>
      else if(num == 7) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp,  p->trapframe->a1, p->trapframe->a0);   // exec
    800034ae:	6cb8                	ld	a4,88(s1)
    800034b0:	7b3c                	ld	a5,112(a4)
    800034b2:	7f38                	ld	a4,120(a4)
    800034b4:	00006617          	auipc	a2,0x6
    800034b8:	63463603          	ld	a2,1588(a2) # 80009ae8 <syscall_names+0x38>
    800034bc:	588c                	lw	a1,48(s1)
    800034be:	00006517          	auipc	a0,0x6
    800034c2:	01a50513          	addi	a0,a0,26 # 800094d8 <states.1811+0x1c0>
    800034c6:	ffffd097          	auipc	ra,0xffffd
    800034ca:	0c8080e7          	jalr	200(ra) # 8000058e <printf>
    800034ce:	ac95                	j	80003742 <syscall+0x478>
      else if(num == 8) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp,  p->trapframe->a1, p->trapframe->a0);  // fstat
    800034d0:	6cb8                	ld	a4,88(s1)
    800034d2:	7b3c                	ld	a5,112(a4)
    800034d4:	7f38                	ld	a4,120(a4)
    800034d6:	00006617          	auipc	a2,0x6
    800034da:	61a63603          	ld	a2,1562(a2) # 80009af0 <syscall_names+0x40>
    800034de:	588c                	lw	a1,48(s1)
    800034e0:	00006517          	auipc	a0,0x6
    800034e4:	ff850513          	addi	a0,a0,-8 # 800094d8 <states.1811+0x1c0>
    800034e8:	ffffd097          	auipc	ra,0xffffd
    800034ec:	0a6080e7          	jalr	166(ra) # 8000058e <printf>
    800034f0:	ac89                	j	80003742 <syscall+0x478>
      else if(num == 9) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // chdir
    800034f2:	6cbc                	ld	a5,88(s1)
    800034f4:	7bb8                	ld	a4,112(a5)
    800034f6:	00006617          	auipc	a2,0x6
    800034fa:	60263603          	ld	a2,1538(a2) # 80009af8 <syscall_names+0x48>
    800034fe:	588c                	lw	a1,48(s1)
    80003500:	00006517          	auipc	a0,0x6
    80003504:	f9050513          	addi	a0,a0,-112 # 80009490 <states.1811+0x178>
    80003508:	ffffd097          	auipc	ra,0xffffd
    8000350c:	086080e7          	jalr	134(ra) # 8000058e <printf>
    80003510:	ac0d                	j	80003742 <syscall+0x478>
      else if(num == 10) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // dup
    80003512:	6cbc                	ld	a5,88(s1)
    80003514:	7bb8                	ld	a4,112(a5)
    80003516:	00006617          	auipc	a2,0x6
    8000351a:	5ea63603          	ld	a2,1514(a2) # 80009b00 <syscall_names+0x50>
    8000351e:	588c                	lw	a1,48(s1)
    80003520:	00006517          	auipc	a0,0x6
    80003524:	f7050513          	addi	a0,a0,-144 # 80009490 <states.1811+0x178>
    80003528:	ffffd097          	auipc	ra,0xffffd
    8000352c:	066080e7          	jalr	102(ra) # 8000058e <printf>
    80003530:	ac09                	j	80003742 <syscall+0x478>
      else if(num == 11) printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0);  // getpid
    80003532:	6cbc                	ld	a5,88(s1)
    80003534:	7bb4                	ld	a3,112(a5)
    80003536:	00006617          	auipc	a2,0x6
    8000353a:	5d263603          	ld	a2,1490(a2) # 80009b08 <syscall_names+0x58>
    8000353e:	588c                	lw	a1,48(s1)
    80003540:	00006517          	auipc	a0,0x6
    80003544:	f3850513          	addi	a0,a0,-200 # 80009478 <states.1811+0x160>
    80003548:	ffffd097          	auipc	ra,0xffffd
    8000354c:	046080e7          	jalr	70(ra) # 8000058e <printf>
    80003550:	aacd                	j	80003742 <syscall+0x478>
      else if(num == 12) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // sbrk
    80003552:	6cbc                	ld	a5,88(s1)
    80003554:	7bb8                	ld	a4,112(a5)
    80003556:	00006617          	auipc	a2,0x6
    8000355a:	5ba63603          	ld	a2,1466(a2) # 80009b10 <syscall_names+0x60>
    8000355e:	588c                	lw	a1,48(s1)
    80003560:	00006517          	auipc	a0,0x6
    80003564:	f3050513          	addi	a0,a0,-208 # 80009490 <states.1811+0x178>
    80003568:	ffffd097          	auipc	ra,0xffffd
    8000356c:	026080e7          	jalr	38(ra) # 8000058e <printf>
    80003570:	aac9                	j	80003742 <syscall+0x478>
      else if(num == 13) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // sleep
    80003572:	6cbc                	ld	a5,88(s1)
    80003574:	7bb8                	ld	a4,112(a5)
    80003576:	00006617          	auipc	a2,0x6
    8000357a:	5a263603          	ld	a2,1442(a2) # 80009b18 <syscall_names+0x68>
    8000357e:	588c                	lw	a1,48(s1)
    80003580:	00006517          	auipc	a0,0x6
    80003584:	f1050513          	addi	a0,a0,-240 # 80009490 <states.1811+0x178>
    80003588:	ffffd097          	auipc	ra,0xffffd
    8000358c:	006080e7          	jalr	6(ra) # 8000058e <printf>
    80003590:	aa4d                	j	80003742 <syscall+0x478>
      else if(num == 14) printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0); // uptime
    80003592:	6cbc                	ld	a5,88(s1)
    80003594:	7bb4                	ld	a3,112(a5)
    80003596:	00006617          	auipc	a2,0x6
    8000359a:	58a63603          	ld	a2,1418(a2) # 80009b20 <syscall_names+0x70>
    8000359e:	588c                	lw	a1,48(s1)
    800035a0:	00006517          	auipc	a0,0x6
    800035a4:	ed850513          	addi	a0,a0,-296 # 80009478 <states.1811+0x160>
    800035a8:	ffffd097          	auipc	ra,0xffffd
    800035ac:	fe6080e7          	jalr	-26(ra) # 8000058e <printf>
    800035b0:	aa49                	j	80003742 <syscall+0x478>
      else if(num == 15) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a0); // open
    800035b2:	6cb8                	ld	a4,88(s1)
    800035b4:	7b3c                	ld	a5,112(a4)
    800035b6:	6358                	ld	a4,128(a4)
    800035b8:	00006617          	auipc	a2,0x6
    800035bc:	57063603          	ld	a2,1392(a2) # 80009b28 <syscall_names+0x78>
    800035c0:	588c                	lw	a1,48(s1)
    800035c2:	00006517          	auipc	a0,0x6
    800035c6:	f1650513          	addi	a0,a0,-234 # 800094d8 <states.1811+0x1c0>
    800035ca:	ffffd097          	auipc	ra,0xffffd
    800035ce:	fc4080e7          	jalr	-60(ra) # 8000058e <printf>
    800035d2:	aa85                	j	80003742 <syscall+0x478>
      else if(num == 16) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a3, p->trapframe->a0); // write
    800035d4:	6cb8                	ld	a4,88(s1)
    800035d6:	07073803          	ld	a6,112(a4)
    800035da:	675c                	ld	a5,136(a4)
    800035dc:	6358                	ld	a4,128(a4)
    800035de:	00006617          	auipc	a2,0x6
    800035e2:	55263603          	ld	a2,1362(a2) # 80009b30 <syscall_names+0x80>
    800035e6:	588c                	lw	a1,48(s1)
    800035e8:	00006517          	auipc	a0,0x6
    800035ec:	ec850513          	addi	a0,a0,-312 # 800094b0 <states.1811+0x198>
    800035f0:	ffffd097          	auipc	ra,0xffffd
    800035f4:	f9e080e7          	jalr	-98(ra) # 8000058e <printf>
    800035f8:	a2a9                	j	80003742 <syscall+0x478>
      else if(num == 17) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a3, p->trapframe->a0); // mknod
    800035fa:	6cb8                	ld	a4,88(s1)
    800035fc:	07073803          	ld	a6,112(a4)
    80003600:	675c                	ld	a5,136(a4)
    80003602:	6358                	ld	a4,128(a4)
    80003604:	00006617          	auipc	a2,0x6
    80003608:	53463603          	ld	a2,1332(a2) # 80009b38 <syscall_names+0x88>
    8000360c:	588c                	lw	a1,48(s1)
    8000360e:	00006517          	auipc	a0,0x6
    80003612:	ea250513          	addi	a0,a0,-350 # 800094b0 <states.1811+0x198>
    80003616:	ffffd097          	auipc	ra,0xffffd
    8000361a:	f78080e7          	jalr	-136(ra) # 8000058e <printf>
    8000361e:	a215                	j	80003742 <syscall+0x478>
      else if(num == 18) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // unlink
    80003620:	6cbc                	ld	a5,88(s1)
    80003622:	7bb8                	ld	a4,112(a5)
    80003624:	00006617          	auipc	a2,0x6
    80003628:	51c63603          	ld	a2,1308(a2) # 80009b40 <syscall_names+0x90>
    8000362c:	588c                	lw	a1,48(s1)
    8000362e:	00006517          	auipc	a0,0x6
    80003632:	e6250513          	addi	a0,a0,-414 # 80009490 <states.1811+0x178>
    80003636:	ffffd097          	auipc	ra,0xffffd
    8000363a:	f58080e7          	jalr	-168(ra) # 8000058e <printf>
    8000363e:	a211                	j	80003742 <syscall+0x478>
      else if(num == 19) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a0); // link
    80003640:	6cb8                	ld	a4,88(s1)
    80003642:	7b3c                	ld	a5,112(a4)
    80003644:	6358                	ld	a4,128(a4)
    80003646:	00006617          	auipc	a2,0x6
    8000364a:	50263603          	ld	a2,1282(a2) # 80009b48 <syscall_names+0x98>
    8000364e:	588c                	lw	a1,48(s1)
    80003650:	00006517          	auipc	a0,0x6
    80003654:	e8850513          	addi	a0,a0,-376 # 800094d8 <states.1811+0x1c0>
    80003658:	ffffd097          	auipc	ra,0xffffd
    8000365c:	f36080e7          	jalr	-202(ra) # 8000058e <printf>
    80003660:	a0cd                	j	80003742 <syscall+0x478>
      else if(num == 20) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // mkdir
    80003662:	6cbc                	ld	a5,88(s1)
    80003664:	7bb8                	ld	a4,112(a5)
    80003666:	00006617          	auipc	a2,0x6
    8000366a:	4ea63603          	ld	a2,1258(a2) # 80009b50 <syscall_names+0xa0>
    8000366e:	588c                	lw	a1,48(s1)
    80003670:	00006517          	auipc	a0,0x6
    80003674:	e2050513          	addi	a0,a0,-480 # 80009490 <states.1811+0x178>
    80003678:	ffffd097          	auipc	ra,0xffffd
    8000367c:	f16080e7          	jalr	-234(ra) # 8000058e <printf>
    80003680:	a0c9                	j	80003742 <syscall+0x478>
      else if(num == 21) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // close
    80003682:	6cbc                	ld	a5,88(s1)
    80003684:	7bb8                	ld	a4,112(a5)
    80003686:	00006617          	auipc	a2,0x6
    8000368a:	4d263603          	ld	a2,1234(a2) # 80009b58 <syscall_names+0xa8>
    8000368e:	588c                	lw	a1,48(s1)
    80003690:	00006517          	auipc	a0,0x6
    80003694:	e0050513          	addi	a0,a0,-512 # 80009490 <states.1811+0x178>
    80003698:	ffffd097          	auipc	ra,0xffffd
    8000369c:	ef6080e7          	jalr	-266(ra) # 8000058e <printf>
    800036a0:	a04d                	j	80003742 <syscall+0x478>
      else if(num == 22) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // trace
    800036a2:	6cbc                	ld	a5,88(s1)
    800036a4:	7bb8                	ld	a4,112(a5)
    800036a6:	00006617          	auipc	a2,0x6
    800036aa:	4ba63603          	ld	a2,1210(a2) # 80009b60 <syscall_names+0xb0>
    800036ae:	588c                	lw	a1,48(s1)
    800036b0:	00006517          	auipc	a0,0x6
    800036b4:	de050513          	addi	a0,a0,-544 # 80009490 <states.1811+0x178>
    800036b8:	ffffd097          	auipc	ra,0xffffd
    800036bc:	ed6080e7          	jalr	-298(ra) # 8000058e <printf>
    800036c0:	a049                	j	80003742 <syscall+0x478>
      else if(num == 23) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a0); // sigalarm
    800036c2:	6cb8                	ld	a4,88(s1)
    800036c4:	7b3c                	ld	a5,112(a4)
    800036c6:	6358                	ld	a4,128(a4)
    800036c8:	00006617          	auipc	a2,0x6
    800036cc:	4a063603          	ld	a2,1184(a2) # 80009b68 <syscall_names+0xb8>
    800036d0:	588c                	lw	a1,48(s1)
    800036d2:	00006517          	auipc	a0,0x6
    800036d6:	e0650513          	addi	a0,a0,-506 # 800094d8 <states.1811+0x1c0>
    800036da:	ffffd097          	auipc	ra,0xffffd
    800036de:	eb4080e7          	jalr	-332(ra) # 8000058e <printf>
    800036e2:	a085                	j	80003742 <syscall+0x478>
      else if(num == 24) printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0); // sigreturn
    800036e4:	6cbc                	ld	a5,88(s1)
    800036e6:	7bb4                	ld	a3,112(a5)
    800036e8:	00006617          	auipc	a2,0x6
    800036ec:	48863603          	ld	a2,1160(a2) # 80009b70 <syscall_names+0xc0>
    800036f0:	588c                	lw	a1,48(s1)
    800036f2:	00006517          	auipc	a0,0x6
    800036f6:	d8650513          	addi	a0,a0,-634 # 80009478 <states.1811+0x160>
    800036fa:	ffffd097          	auipc	ra,0xffffd
    800036fe:	e94080e7          	jalr	-364(ra) # 8000058e <printf>
    80003702:	a081                	j	80003742 <syscall+0x478>
      else if(num == 25) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // settickets
    80003704:	6cbc                	ld	a5,88(s1)
    80003706:	7bb8                	ld	a4,112(a5)
    80003708:	00006617          	auipc	a2,0x6
    8000370c:	47063603          	ld	a2,1136(a2) # 80009b78 <syscall_names+0xc8>
    80003710:	588c                	lw	a1,48(s1)
    80003712:	00006517          	auipc	a0,0x6
    80003716:	d7e50513          	addi	a0,a0,-642 # 80009490 <states.1811+0x178>
    8000371a:	ffffd097          	auipc	ra,0xffffd
    8000371e:	e74080e7          	jalr	-396(ra) # 8000058e <printf>
    80003722:	a005                	j	80003742 <syscall+0x478>
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    80003724:	86ce                	mv	a3,s3
    80003726:	15848613          	addi	a2,s1,344
    8000372a:	588c                	lw	a1,48(s1)
    8000372c:	00006517          	auipc	a0,0x6
    80003730:	dcc50513          	addi	a0,a0,-564 # 800094f8 <states.1811+0x1e0>
    80003734:	ffffd097          	auipc	ra,0xffffd
    80003738:	e5a080e7          	jalr	-422(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000373c:	6cbc                	ld	a5,88(s1)
    8000373e:	577d                	li	a4,-1
    80003740:	fbb8                	sd	a4,112(a5)
  }
}
    80003742:	70a2                	ld	ra,40(sp)
    80003744:	7402                	ld	s0,32(sp)
    80003746:	64e2                	ld	s1,24(sp)
    80003748:	6942                	ld	s2,16(sp)
    8000374a:	69a2                	ld	s3,8(sp)
    8000374c:	6a02                	ld	s4,0(sp)
    8000374e:	6145                	addi	sp,sp,48
    80003750:	8082                	ret

0000000080003752 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003752:	1101                	addi	sp,sp,-32
    80003754:	ec06                	sd	ra,24(sp)
    80003756:	e822                	sd	s0,16(sp)
    80003758:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    8000375a:	fec40593          	addi	a1,s0,-20
    8000375e:	4501                	li	a0,0
    80003760:	00000097          	auipc	ra,0x0
    80003764:	af2080e7          	jalr	-1294(ra) # 80003252 <argint>
  exit(n);
    80003768:	fec42503          	lw	a0,-20(s0)
    8000376c:	fffff097          	auipc	ra,0xfffff
    80003770:	fba080e7          	jalr	-70(ra) # 80002726 <exit>
  return 0;  // not reached
}
    80003774:	4501                	li	a0,0
    80003776:	60e2                	ld	ra,24(sp)
    80003778:	6442                	ld	s0,16(sp)
    8000377a:	6105                	addi	sp,sp,32
    8000377c:	8082                	ret

000000008000377e <sys_getpid>:

uint64
sys_getpid(void)
{
    8000377e:	1141                	addi	sp,sp,-16
    80003780:	e406                	sd	ra,8(sp)
    80003782:	e022                	sd	s0,0(sp)
    80003784:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003786:	ffffe097          	auipc	ra,0xffffe
    8000378a:	470080e7          	jalr	1136(ra) # 80001bf6 <myproc>
}
    8000378e:	5908                	lw	a0,48(a0)
    80003790:	60a2                	ld	ra,8(sp)
    80003792:	6402                	ld	s0,0(sp)
    80003794:	0141                	addi	sp,sp,16
    80003796:	8082                	ret

0000000080003798 <sys_fork>:

uint64
sys_fork(void)
{
    80003798:	1141                	addi	sp,sp,-16
    8000379a:	e406                	sd	ra,8(sp)
    8000379c:	e022                	sd	s0,0(sp)
    8000379e:	0800                	addi	s0,sp,16
  return fork();
    800037a0:	fffff097          	auipc	ra,0xfffff
    800037a4:	86a080e7          	jalr	-1942(ra) # 8000200a <fork>
}
    800037a8:	60a2                	ld	ra,8(sp)
    800037aa:	6402                	ld	s0,0(sp)
    800037ac:	0141                	addi	sp,sp,16
    800037ae:	8082                	ret

00000000800037b0 <sys_wait>:

uint64
sys_wait(void)
{
    800037b0:	1101                	addi	sp,sp,-32
    800037b2:	ec06                	sd	ra,24(sp)
    800037b4:	e822                	sd	s0,16(sp)
    800037b6:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    800037b8:	fe840593          	addi	a1,s0,-24
    800037bc:	4501                	li	a0,0
    800037be:	00000097          	auipc	ra,0x0
    800037c2:	ab4080e7          	jalr	-1356(ra) # 80003272 <argaddr>
  return wait(p);
    800037c6:	fe843503          	ld	a0,-24(s0)
    800037ca:	fffff097          	auipc	ra,0xfffff
    800037ce:	10e080e7          	jalr	270(ra) # 800028d8 <wait>
}
    800037d2:	60e2                	ld	ra,24(sp)
    800037d4:	6442                	ld	s0,16(sp)
    800037d6:	6105                	addi	sp,sp,32
    800037d8:	8082                	ret

00000000800037da <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800037da:	7179                	addi	sp,sp,-48
    800037dc:	f406                	sd	ra,40(sp)
    800037de:	f022                	sd	s0,32(sp)
    800037e0:	ec26                	sd	s1,24(sp)
    800037e2:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    800037e4:	fdc40593          	addi	a1,s0,-36
    800037e8:	4501                	li	a0,0
    800037ea:	00000097          	auipc	ra,0x0
    800037ee:	a68080e7          	jalr	-1432(ra) # 80003252 <argint>
  addr = myproc()->sz;
    800037f2:	ffffe097          	auipc	ra,0xffffe
    800037f6:	404080e7          	jalr	1028(ra) # 80001bf6 <myproc>
    800037fa:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    800037fc:	fdc42503          	lw	a0,-36(s0)
    80003800:	ffffe097          	auipc	ra,0xffffe
    80003804:	7ae080e7          	jalr	1966(ra) # 80001fae <growproc>
    80003808:	00054863          	bltz	a0,80003818 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    8000380c:	8526                	mv	a0,s1
    8000380e:	70a2                	ld	ra,40(sp)
    80003810:	7402                	ld	s0,32(sp)
    80003812:	64e2                	ld	s1,24(sp)
    80003814:	6145                	addi	sp,sp,48
    80003816:	8082                	ret
    return -1;
    80003818:	54fd                	li	s1,-1
    8000381a:	bfcd                	j	8000380c <sys_sbrk+0x32>

000000008000381c <sys_sleep>:

uint64
sys_sleep(void)
{
    8000381c:	7139                	addi	sp,sp,-64
    8000381e:	fc06                	sd	ra,56(sp)
    80003820:	f822                	sd	s0,48(sp)
    80003822:	f426                	sd	s1,40(sp)
    80003824:	f04a                	sd	s2,32(sp)
    80003826:	ec4e                	sd	s3,24(sp)
    80003828:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    8000382a:	fcc40593          	addi	a1,s0,-52
    8000382e:	4501                	li	a0,0
    80003830:	00000097          	auipc	ra,0x0
    80003834:	a22080e7          	jalr	-1502(ra) # 80003252 <argint>
  acquire(&tickslock);
    80003838:	00016517          	auipc	a0,0x16
    8000383c:	6c050513          	addi	a0,a0,1728 # 80019ef8 <tickslock>
    80003840:	ffffd097          	auipc	ra,0xffffd
    80003844:	3aa080e7          	jalr	938(ra) # 80000bea <acquire>
  ticks0 = ticks;
    80003848:	00006917          	auipc	s2,0x6
    8000384c:	39892903          	lw	s2,920(s2) # 80009be0 <ticks>
  while(ticks - ticks0 < n){
    80003850:	fcc42783          	lw	a5,-52(s0)
    80003854:	cf9d                	beqz	a5,80003892 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003856:	00016997          	auipc	s3,0x16
    8000385a:	6a298993          	addi	s3,s3,1698 # 80019ef8 <tickslock>
    8000385e:	00006497          	auipc	s1,0x6
    80003862:	38248493          	addi	s1,s1,898 # 80009be0 <ticks>
    if(killed(myproc())){
    80003866:	ffffe097          	auipc	ra,0xffffe
    8000386a:	390080e7          	jalr	912(ra) # 80001bf6 <myproc>
    8000386e:	fffff097          	auipc	ra,0xfffff
    80003872:	038080e7          	jalr	56(ra) # 800028a6 <killed>
    80003876:	ed15                	bnez	a0,800038b2 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003878:	85ce                	mv	a1,s3
    8000387a:	8526                	mv	a0,s1
    8000387c:	fffff097          	auipc	ra,0xfffff
    80003880:	c2a080e7          	jalr	-982(ra) # 800024a6 <sleep>
  while(ticks - ticks0 < n){
    80003884:	409c                	lw	a5,0(s1)
    80003886:	412787bb          	subw	a5,a5,s2
    8000388a:	fcc42703          	lw	a4,-52(s0)
    8000388e:	fce7ece3          	bltu	a5,a4,80003866 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003892:	00016517          	auipc	a0,0x16
    80003896:	66650513          	addi	a0,a0,1638 # 80019ef8 <tickslock>
    8000389a:	ffffd097          	auipc	ra,0xffffd
    8000389e:	404080e7          	jalr	1028(ra) # 80000c9e <release>
  return 0;
    800038a2:	4501                	li	a0,0
}
    800038a4:	70e2                	ld	ra,56(sp)
    800038a6:	7442                	ld	s0,48(sp)
    800038a8:	74a2                	ld	s1,40(sp)
    800038aa:	7902                	ld	s2,32(sp)
    800038ac:	69e2                	ld	s3,24(sp)
    800038ae:	6121                	addi	sp,sp,64
    800038b0:	8082                	ret
      release(&tickslock);
    800038b2:	00016517          	auipc	a0,0x16
    800038b6:	64650513          	addi	a0,a0,1606 # 80019ef8 <tickslock>
    800038ba:	ffffd097          	auipc	ra,0xffffd
    800038be:	3e4080e7          	jalr	996(ra) # 80000c9e <release>
      return -1;
    800038c2:	557d                	li	a0,-1
    800038c4:	b7c5                	j	800038a4 <sys_sleep+0x88>

00000000800038c6 <sys_kill>:

uint64
sys_kill(void)
{
    800038c6:	1101                	addi	sp,sp,-32
    800038c8:	ec06                	sd	ra,24(sp)
    800038ca:	e822                	sd	s0,16(sp)
    800038cc:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    800038ce:	fec40593          	addi	a1,s0,-20
    800038d2:	4501                	li	a0,0
    800038d4:	00000097          	auipc	ra,0x0
    800038d8:	97e080e7          	jalr	-1666(ra) # 80003252 <argint>
  return kill(pid);
    800038dc:	fec42503          	lw	a0,-20(s0)
    800038e0:	fffff097          	auipc	ra,0xfffff
    800038e4:	f28080e7          	jalr	-216(ra) # 80002808 <kill>
}
    800038e8:	60e2                	ld	ra,24(sp)
    800038ea:	6442                	ld	s0,16(sp)
    800038ec:	6105                	addi	sp,sp,32
    800038ee:	8082                	ret

00000000800038f0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800038f0:	1101                	addi	sp,sp,-32
    800038f2:	ec06                	sd	ra,24(sp)
    800038f4:	e822                	sd	s0,16(sp)
    800038f6:	e426                	sd	s1,8(sp)
    800038f8:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800038fa:	00016517          	auipc	a0,0x16
    800038fe:	5fe50513          	addi	a0,a0,1534 # 80019ef8 <tickslock>
    80003902:	ffffd097          	auipc	ra,0xffffd
    80003906:	2e8080e7          	jalr	744(ra) # 80000bea <acquire>
  xticks = ticks;
    8000390a:	00006497          	auipc	s1,0x6
    8000390e:	2d64a483          	lw	s1,726(s1) # 80009be0 <ticks>
  release(&tickslock);
    80003912:	00016517          	auipc	a0,0x16
    80003916:	5e650513          	addi	a0,a0,1510 # 80019ef8 <tickslock>
    8000391a:	ffffd097          	auipc	ra,0xffffd
    8000391e:	384080e7          	jalr	900(ra) # 80000c9e <release>
  return xticks;
}
    80003922:	02049513          	slli	a0,s1,0x20
    80003926:	9101                	srli	a0,a0,0x20
    80003928:	60e2                	ld	ra,24(sp)
    8000392a:	6442                	ld	s0,16(sp)
    8000392c:	64a2                	ld	s1,8(sp)
    8000392e:	6105                	addi	sp,sp,32
    80003930:	8082                	ret

0000000080003932 <sys_trace>:

// sets the trace_flag to the first argument (a0)
uint64
sys_trace(void)
{
    80003932:	1141                	addi	sp,sp,-16
    80003934:	e406                	sd	ra,8(sp)
    80003936:	e022                	sd	s0,0(sp)
    80003938:	0800                	addi	s0,sp,16
  argint(0, &myproc()->trace_flag); //arg(a0, trace_flag) // returns void
    8000393a:	ffffe097          	auipc	ra,0xffffe
    8000393e:	2bc080e7          	jalr	700(ra) # 80001bf6 <myproc>
    80003942:	17450593          	addi	a1,a0,372
    80003946:	4501                	li	a0,0
    80003948:	00000097          	auipc	ra,0x0
    8000394c:	90a080e7          	jalr	-1782(ra) # 80003252 <argint>
  return 0;
}
    80003950:	4501                	li	a0,0
    80003952:	60a2                	ld	ra,8(sp)
    80003954:	6402                	ld	s0,0(sp)
    80003956:	0141                	addi	sp,sp,16
    80003958:	8082                	ret

000000008000395a <sys_sigalarm>:

// sets the 
uint64
sys_sigalarm(void)
{
    8000395a:	1101                	addi	sp,sp,-32
    8000395c:	ec06                	sd	ra,24(sp)
    8000395e:	e822                	sd	s0,16(sp)
    80003960:	e426                	sd	s1,8(sp)
    80003962:	1000                	addi	s0,sp,32
  // sets the interval and handler after every tick
  argint(0, &myproc()->interval);
    80003964:	ffffe097          	auipc	ra,0xffffe
    80003968:	292080e7          	jalr	658(ra) # 80001bf6 <myproc>
    8000396c:	17850593          	addi	a1,a0,376
    80003970:	4501                	li	a0,0
    80003972:	00000097          	auipc	ra,0x0
    80003976:	8e0080e7          	jalr	-1824(ra) # 80003252 <argint>
  argaddr(1, &myproc()->sig_handler);
    8000397a:	ffffe097          	auipc	ra,0xffffe
    8000397e:	27c080e7          	jalr	636(ra) # 80001bf6 <myproc>
    80003982:	18050593          	addi	a1,a0,384
    80003986:	4505                	li	a0,1
    80003988:	00000097          	auipc	ra,0x0
    8000398c:	8ea080e7          	jalr	-1814(ra) # 80003272 <argaddr>
  
  // sets ticks_passed as the interval
  myproc()->ticks_left = myproc()->interval;
    80003990:	ffffe097          	auipc	ra,0xffffe
    80003994:	266080e7          	jalr	614(ra) # 80001bf6 <myproc>
    80003998:	84aa                	mv	s1,a0
    8000399a:	ffffe097          	auipc	ra,0xffffe
    8000399e:	25c080e7          	jalr	604(ra) # 80001bf6 <myproc>
    800039a2:	1784a783          	lw	a5,376(s1)
    800039a6:	16f52e23          	sw	a5,380(a0)
  return 0;
}
    800039aa:	4501                	li	a0,0
    800039ac:	60e2                	ld	ra,24(sp)
    800039ae:	6442                	ld	s0,16(sp)
    800039b0:	64a2                	ld	s1,8(sp)
    800039b2:	6105                	addi	sp,sp,32
    800039b4:	8082                	ret

00000000800039b6 <sys_sigreturn>:

uint64 
sys_sigreturn(void)
{
    800039b6:	1101                	addi	sp,sp,-32
    800039b8:	ec06                	sd	ra,24(sp)
    800039ba:	e822                	sd	s0,16(sp)
    800039bc:	e426                	sd	s1,8(sp)
    800039be:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800039c0:	ffffe097          	auipc	ra,0xffffe
    800039c4:	236080e7          	jalr	566(ra) # 80001bf6 <myproc>
    800039c8:	84aa                	mv	s1,a0
  memmove(p->trapframe, p->sigalarm_tf, PGSIZE);
    800039ca:	6605                	lui	a2,0x1
    800039cc:	18853583          	ld	a1,392(a0)
    800039d0:	6d28                	ld	a0,88(a0)
    800039d2:	ffffd097          	auipc	ra,0xffffd
    800039d6:	374080e7          	jalr	884(ra) # 80000d46 <memmove>
  kfree(p->sigalarm_tf);
    800039da:	1884b503          	ld	a0,392(s1)
    800039de:	ffffd097          	auipc	ra,0xffffd
    800039e2:	020080e7          	jalr	32(ra) # 800009fe <kfree>
  p->ticks_left = p->interval;
    800039e6:	1784a783          	lw	a5,376(s1)
    800039ea:	16f4ae23          	sw	a5,380(s1)
  return p->trapframe->a0;
    800039ee:	6cbc                	ld	a5,88(s1)
}
    800039f0:	7ba8                	ld	a0,112(a5)
    800039f2:	60e2                	ld	ra,24(sp)
    800039f4:	6442                	ld	s0,16(sp)
    800039f6:	64a2                	ld	s1,8(sp)
    800039f8:	6105                	addi	sp,sp,32
    800039fa:	8082                	ret

00000000800039fc <sys_settickets>:

uint64 
sys_settickets(void)
{
    800039fc:	1141                	addi	sp,sp,-16
    800039fe:	e406                	sd	ra,8(sp)
    80003a00:	e022                	sd	s0,0(sp)
    80003a02:	0800                	addi	s0,sp,16
  argint(0, &myproc()->tickets);
    80003a04:	ffffe097          	auipc	ra,0xffffe
    80003a08:	1f2080e7          	jalr	498(ra) # 80001bf6 <myproc>
    80003a0c:	19450593          	addi	a1,a0,404
    80003a10:	4501                	li	a0,0
    80003a12:	00000097          	auipc	ra,0x0
    80003a16:	840080e7          	jalr	-1984(ra) # 80003252 <argint>
  return myproc()->tickets;
    80003a1a:	ffffe097          	auipc	ra,0xffffe
    80003a1e:	1dc080e7          	jalr	476(ra) # 80001bf6 <myproc>
}
    80003a22:	19452503          	lw	a0,404(a0)
    80003a26:	60a2                	ld	ra,8(sp)
    80003a28:	6402                	ld	s0,0(sp)
    80003a2a:	0141                	addi	sp,sp,16
    80003a2c:	8082                	ret

0000000080003a2e <sys_waitx>:

uint64
sys_waitx(void)
{
    80003a2e:	7139                	addi	sp,sp,-64
    80003a30:	fc06                	sd	ra,56(sp)
    80003a32:	f822                	sd	s0,48(sp)
    80003a34:	f426                	sd	s1,40(sp)
    80003a36:	f04a                	sd	s2,32(sp)
    80003a38:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80003a3a:	fd840593          	addi	a1,s0,-40
    80003a3e:	4501                	li	a0,0
    80003a40:	00000097          	auipc	ra,0x0
    80003a44:	832080e7          	jalr	-1998(ra) # 80003272 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80003a48:	fd040593          	addi	a1,s0,-48
    80003a4c:	4505                	li	a0,1
    80003a4e:	00000097          	auipc	ra,0x0
    80003a52:	824080e7          	jalr	-2012(ra) # 80003272 <argaddr>
  argaddr(2, &addr2);
    80003a56:	fc840593          	addi	a1,s0,-56
    80003a5a:	4509                	li	a0,2
    80003a5c:	00000097          	auipc	ra,0x0
    80003a60:	816080e7          	jalr	-2026(ra) # 80003272 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003a64:	fc040613          	addi	a2,s0,-64
    80003a68:	fc440593          	addi	a1,s0,-60
    80003a6c:	fd843503          	ld	a0,-40(s0)
    80003a70:	fffff097          	auipc	ra,0xfffff
    80003a74:	a9a080e7          	jalr	-1382(ra) # 8000250a <waitx>
    80003a78:	892a                	mv	s2,a0
  struct proc* p = myproc();
    80003a7a:	ffffe097          	auipc	ra,0xffffe
    80003a7e:	17c080e7          	jalr	380(ra) # 80001bf6 <myproc>
    80003a82:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80003a84:	4691                	li	a3,4
    80003a86:	fc440613          	addi	a2,s0,-60
    80003a8a:	fd043583          	ld	a1,-48(s0)
    80003a8e:	6928                	ld	a0,80(a0)
    80003a90:	ffffe097          	auipc	ra,0xffffe
    80003a94:	bf4080e7          	jalr	-1036(ra) # 80001684 <copyout>
    return -1;
    80003a98:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80003a9a:	00054f63          	bltz	a0,80003ab8 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    80003a9e:	4691                	li	a3,4
    80003aa0:	fc040613          	addi	a2,s0,-64
    80003aa4:	fc843583          	ld	a1,-56(s0)
    80003aa8:	68a8                	ld	a0,80(s1)
    80003aaa:	ffffe097          	auipc	ra,0xffffe
    80003aae:	bda080e7          	jalr	-1062(ra) # 80001684 <copyout>
    80003ab2:	00054a63          	bltz	a0,80003ac6 <sys_waitx+0x98>
    return -1;
  return ret;
    80003ab6:	87ca                	mv	a5,s2
}
    80003ab8:	853e                	mv	a0,a5
    80003aba:	70e2                	ld	ra,56(sp)
    80003abc:	7442                	ld	s0,48(sp)
    80003abe:	74a2                	ld	s1,40(sp)
    80003ac0:	7902                	ld	s2,32(sp)
    80003ac2:	6121                	addi	sp,sp,64
    80003ac4:	8082                	ret
    return -1;
    80003ac6:	57fd                	li	a5,-1
    80003ac8:	bfc5                	j	80003ab8 <sys_waitx+0x8a>

0000000080003aca <sys_setpriority>:

uint64
sys_setpriority(void)
{
    80003aca:	1101                	addi	sp,sp,-32
    80003acc:	ec06                	sd	ra,24(sp)
    80003ace:	e822                	sd	s0,16(sp)
    80003ad0:	1000                	addi	s0,sp,32
  int new_priority, proc_pid;

  argint(0, &new_priority);
    80003ad2:	fec40593          	addi	a1,s0,-20
    80003ad6:	4501                	li	a0,0
    80003ad8:	fffff097          	auipc	ra,0xfffff
    80003adc:	77a080e7          	jalr	1914(ra) # 80003252 <argint>
  argint(1, &proc_pid);
    80003ae0:	fe840593          	addi	a1,s0,-24
    80003ae4:	4505                	li	a0,1
    80003ae6:	fffff097          	auipc	ra,0xfffff
    80003aea:	76c080e7          	jalr	1900(ra) # 80003252 <argint>
  return setpriority(new_priority, proc_pid);
    80003aee:	fe842583          	lw	a1,-24(s0)
    80003af2:	fec42503          	lw	a0,-20(s0)
    80003af6:	fffff097          	auipc	ra,0xfffff
    80003afa:	06a080e7          	jalr	106(ra) # 80002b60 <setpriority>
}
    80003afe:	60e2                	ld	ra,24(sp)
    80003b00:	6442                	ld	s0,16(sp)
    80003b02:	6105                	addi	sp,sp,32
    80003b04:	8082                	ret

0000000080003b06 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003b06:	7179                	addi	sp,sp,-48
    80003b08:	f406                	sd	ra,40(sp)
    80003b0a:	f022                	sd	s0,32(sp)
    80003b0c:	ec26                	sd	s1,24(sp)
    80003b0e:	e84a                	sd	s2,16(sp)
    80003b10:	e44e                	sd	s3,8(sp)
    80003b12:	e052                	sd	s4,0(sp)
    80003b14:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003b16:	00006597          	auipc	a1,0x6
    80003b1a:	bf258593          	addi	a1,a1,-1038 # 80009708 <syscalls+0xe0>
    80003b1e:	00016517          	auipc	a0,0x16
    80003b22:	3f250513          	addi	a0,a0,1010 # 80019f10 <bcache>
    80003b26:	ffffd097          	auipc	ra,0xffffd
    80003b2a:	034080e7          	jalr	52(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003b2e:	0001e797          	auipc	a5,0x1e
    80003b32:	3e278793          	addi	a5,a5,994 # 80021f10 <bcache+0x8000>
    80003b36:	0001e717          	auipc	a4,0x1e
    80003b3a:	64270713          	addi	a4,a4,1602 # 80022178 <bcache+0x8268>
    80003b3e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003b42:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003b46:	00016497          	auipc	s1,0x16
    80003b4a:	3e248493          	addi	s1,s1,994 # 80019f28 <bcache+0x18>
    b->next = bcache.head.next;
    80003b4e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003b50:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003b52:	00006a17          	auipc	s4,0x6
    80003b56:	bbea0a13          	addi	s4,s4,-1090 # 80009710 <syscalls+0xe8>
    b->next = bcache.head.next;
    80003b5a:	2b893783          	ld	a5,696(s2)
    80003b5e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003b60:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003b64:	85d2                	mv	a1,s4
    80003b66:	01048513          	addi	a0,s1,16
    80003b6a:	00001097          	auipc	ra,0x1
    80003b6e:	4c4080e7          	jalr	1220(ra) # 8000502e <initsleeplock>
    bcache.head.next->prev = b;
    80003b72:	2b893783          	ld	a5,696(s2)
    80003b76:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003b78:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003b7c:	45848493          	addi	s1,s1,1112
    80003b80:	fd349de3          	bne	s1,s3,80003b5a <binit+0x54>
  }
}
    80003b84:	70a2                	ld	ra,40(sp)
    80003b86:	7402                	ld	s0,32(sp)
    80003b88:	64e2                	ld	s1,24(sp)
    80003b8a:	6942                	ld	s2,16(sp)
    80003b8c:	69a2                	ld	s3,8(sp)
    80003b8e:	6a02                	ld	s4,0(sp)
    80003b90:	6145                	addi	sp,sp,48
    80003b92:	8082                	ret

0000000080003b94 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003b94:	7179                	addi	sp,sp,-48
    80003b96:	f406                	sd	ra,40(sp)
    80003b98:	f022                	sd	s0,32(sp)
    80003b9a:	ec26                	sd	s1,24(sp)
    80003b9c:	e84a                	sd	s2,16(sp)
    80003b9e:	e44e                	sd	s3,8(sp)
    80003ba0:	1800                	addi	s0,sp,48
    80003ba2:	89aa                	mv	s3,a0
    80003ba4:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003ba6:	00016517          	auipc	a0,0x16
    80003baa:	36a50513          	addi	a0,a0,874 # 80019f10 <bcache>
    80003bae:	ffffd097          	auipc	ra,0xffffd
    80003bb2:	03c080e7          	jalr	60(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003bb6:	0001e497          	auipc	s1,0x1e
    80003bba:	6124b483          	ld	s1,1554(s1) # 800221c8 <bcache+0x82b8>
    80003bbe:	0001e797          	auipc	a5,0x1e
    80003bc2:	5ba78793          	addi	a5,a5,1466 # 80022178 <bcache+0x8268>
    80003bc6:	02f48f63          	beq	s1,a5,80003c04 <bread+0x70>
    80003bca:	873e                	mv	a4,a5
    80003bcc:	a021                	j	80003bd4 <bread+0x40>
    80003bce:	68a4                	ld	s1,80(s1)
    80003bd0:	02e48a63          	beq	s1,a4,80003c04 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003bd4:	449c                	lw	a5,8(s1)
    80003bd6:	ff379ce3          	bne	a5,s3,80003bce <bread+0x3a>
    80003bda:	44dc                	lw	a5,12(s1)
    80003bdc:	ff2799e3          	bne	a5,s2,80003bce <bread+0x3a>
      b->refcnt++;
    80003be0:	40bc                	lw	a5,64(s1)
    80003be2:	2785                	addiw	a5,a5,1
    80003be4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003be6:	00016517          	auipc	a0,0x16
    80003bea:	32a50513          	addi	a0,a0,810 # 80019f10 <bcache>
    80003bee:	ffffd097          	auipc	ra,0xffffd
    80003bf2:	0b0080e7          	jalr	176(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80003bf6:	01048513          	addi	a0,s1,16
    80003bfa:	00001097          	auipc	ra,0x1
    80003bfe:	46e080e7          	jalr	1134(ra) # 80005068 <acquiresleep>
      return b;
    80003c02:	a8b9                	j	80003c60 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003c04:	0001e497          	auipc	s1,0x1e
    80003c08:	5bc4b483          	ld	s1,1468(s1) # 800221c0 <bcache+0x82b0>
    80003c0c:	0001e797          	auipc	a5,0x1e
    80003c10:	56c78793          	addi	a5,a5,1388 # 80022178 <bcache+0x8268>
    80003c14:	00f48863          	beq	s1,a5,80003c24 <bread+0x90>
    80003c18:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003c1a:	40bc                	lw	a5,64(s1)
    80003c1c:	cf81                	beqz	a5,80003c34 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003c1e:	64a4                	ld	s1,72(s1)
    80003c20:	fee49de3          	bne	s1,a4,80003c1a <bread+0x86>
  panic("bget: no buffers");
    80003c24:	00006517          	auipc	a0,0x6
    80003c28:	af450513          	addi	a0,a0,-1292 # 80009718 <syscalls+0xf0>
    80003c2c:	ffffd097          	auipc	ra,0xffffd
    80003c30:	918080e7          	jalr	-1768(ra) # 80000544 <panic>
      b->dev = dev;
    80003c34:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003c38:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003c3c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003c40:	4785                	li	a5,1
    80003c42:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003c44:	00016517          	auipc	a0,0x16
    80003c48:	2cc50513          	addi	a0,a0,716 # 80019f10 <bcache>
    80003c4c:	ffffd097          	auipc	ra,0xffffd
    80003c50:	052080e7          	jalr	82(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80003c54:	01048513          	addi	a0,s1,16
    80003c58:	00001097          	auipc	ra,0x1
    80003c5c:	410080e7          	jalr	1040(ra) # 80005068 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003c60:	409c                	lw	a5,0(s1)
    80003c62:	cb89                	beqz	a5,80003c74 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003c64:	8526                	mv	a0,s1
    80003c66:	70a2                	ld	ra,40(sp)
    80003c68:	7402                	ld	s0,32(sp)
    80003c6a:	64e2                	ld	s1,24(sp)
    80003c6c:	6942                	ld	s2,16(sp)
    80003c6e:	69a2                	ld	s3,8(sp)
    80003c70:	6145                	addi	sp,sp,48
    80003c72:	8082                	ret
    virtio_disk_rw(b, 0);
    80003c74:	4581                	li	a1,0
    80003c76:	8526                	mv	a0,s1
    80003c78:	00003097          	auipc	ra,0x3
    80003c7c:	fd0080e7          	jalr	-48(ra) # 80006c48 <virtio_disk_rw>
    b->valid = 1;
    80003c80:	4785                	li	a5,1
    80003c82:	c09c                	sw	a5,0(s1)
  return b;
    80003c84:	b7c5                	j	80003c64 <bread+0xd0>

0000000080003c86 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003c86:	1101                	addi	sp,sp,-32
    80003c88:	ec06                	sd	ra,24(sp)
    80003c8a:	e822                	sd	s0,16(sp)
    80003c8c:	e426                	sd	s1,8(sp)
    80003c8e:	1000                	addi	s0,sp,32
    80003c90:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003c92:	0541                	addi	a0,a0,16
    80003c94:	00001097          	auipc	ra,0x1
    80003c98:	46e080e7          	jalr	1134(ra) # 80005102 <holdingsleep>
    80003c9c:	cd01                	beqz	a0,80003cb4 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003c9e:	4585                	li	a1,1
    80003ca0:	8526                	mv	a0,s1
    80003ca2:	00003097          	auipc	ra,0x3
    80003ca6:	fa6080e7          	jalr	-90(ra) # 80006c48 <virtio_disk_rw>
}
    80003caa:	60e2                	ld	ra,24(sp)
    80003cac:	6442                	ld	s0,16(sp)
    80003cae:	64a2                	ld	s1,8(sp)
    80003cb0:	6105                	addi	sp,sp,32
    80003cb2:	8082                	ret
    panic("bwrite");
    80003cb4:	00006517          	auipc	a0,0x6
    80003cb8:	a7c50513          	addi	a0,a0,-1412 # 80009730 <syscalls+0x108>
    80003cbc:	ffffd097          	auipc	ra,0xffffd
    80003cc0:	888080e7          	jalr	-1912(ra) # 80000544 <panic>

0000000080003cc4 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003cc4:	1101                	addi	sp,sp,-32
    80003cc6:	ec06                	sd	ra,24(sp)
    80003cc8:	e822                	sd	s0,16(sp)
    80003cca:	e426                	sd	s1,8(sp)
    80003ccc:	e04a                	sd	s2,0(sp)
    80003cce:	1000                	addi	s0,sp,32
    80003cd0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003cd2:	01050913          	addi	s2,a0,16
    80003cd6:	854a                	mv	a0,s2
    80003cd8:	00001097          	auipc	ra,0x1
    80003cdc:	42a080e7          	jalr	1066(ra) # 80005102 <holdingsleep>
    80003ce0:	c92d                	beqz	a0,80003d52 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003ce2:	854a                	mv	a0,s2
    80003ce4:	00001097          	auipc	ra,0x1
    80003ce8:	3da080e7          	jalr	986(ra) # 800050be <releasesleep>

  acquire(&bcache.lock);
    80003cec:	00016517          	auipc	a0,0x16
    80003cf0:	22450513          	addi	a0,a0,548 # 80019f10 <bcache>
    80003cf4:	ffffd097          	auipc	ra,0xffffd
    80003cf8:	ef6080e7          	jalr	-266(ra) # 80000bea <acquire>
  b->refcnt--;
    80003cfc:	40bc                	lw	a5,64(s1)
    80003cfe:	37fd                	addiw	a5,a5,-1
    80003d00:	0007871b          	sext.w	a4,a5
    80003d04:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003d06:	eb05                	bnez	a4,80003d36 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003d08:	68bc                	ld	a5,80(s1)
    80003d0a:	64b8                	ld	a4,72(s1)
    80003d0c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003d0e:	64bc                	ld	a5,72(s1)
    80003d10:	68b8                	ld	a4,80(s1)
    80003d12:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003d14:	0001e797          	auipc	a5,0x1e
    80003d18:	1fc78793          	addi	a5,a5,508 # 80021f10 <bcache+0x8000>
    80003d1c:	2b87b703          	ld	a4,696(a5)
    80003d20:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003d22:	0001e717          	auipc	a4,0x1e
    80003d26:	45670713          	addi	a4,a4,1110 # 80022178 <bcache+0x8268>
    80003d2a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003d2c:	2b87b703          	ld	a4,696(a5)
    80003d30:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003d32:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003d36:	00016517          	auipc	a0,0x16
    80003d3a:	1da50513          	addi	a0,a0,474 # 80019f10 <bcache>
    80003d3e:	ffffd097          	auipc	ra,0xffffd
    80003d42:	f60080e7          	jalr	-160(ra) # 80000c9e <release>
}
    80003d46:	60e2                	ld	ra,24(sp)
    80003d48:	6442                	ld	s0,16(sp)
    80003d4a:	64a2                	ld	s1,8(sp)
    80003d4c:	6902                	ld	s2,0(sp)
    80003d4e:	6105                	addi	sp,sp,32
    80003d50:	8082                	ret
    panic("brelse");
    80003d52:	00006517          	auipc	a0,0x6
    80003d56:	9e650513          	addi	a0,a0,-1562 # 80009738 <syscalls+0x110>
    80003d5a:	ffffc097          	auipc	ra,0xffffc
    80003d5e:	7ea080e7          	jalr	2026(ra) # 80000544 <panic>

0000000080003d62 <bpin>:

void
bpin(struct buf *b) {
    80003d62:	1101                	addi	sp,sp,-32
    80003d64:	ec06                	sd	ra,24(sp)
    80003d66:	e822                	sd	s0,16(sp)
    80003d68:	e426                	sd	s1,8(sp)
    80003d6a:	1000                	addi	s0,sp,32
    80003d6c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003d6e:	00016517          	auipc	a0,0x16
    80003d72:	1a250513          	addi	a0,a0,418 # 80019f10 <bcache>
    80003d76:	ffffd097          	auipc	ra,0xffffd
    80003d7a:	e74080e7          	jalr	-396(ra) # 80000bea <acquire>
  b->refcnt++;
    80003d7e:	40bc                	lw	a5,64(s1)
    80003d80:	2785                	addiw	a5,a5,1
    80003d82:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003d84:	00016517          	auipc	a0,0x16
    80003d88:	18c50513          	addi	a0,a0,396 # 80019f10 <bcache>
    80003d8c:	ffffd097          	auipc	ra,0xffffd
    80003d90:	f12080e7          	jalr	-238(ra) # 80000c9e <release>
}
    80003d94:	60e2                	ld	ra,24(sp)
    80003d96:	6442                	ld	s0,16(sp)
    80003d98:	64a2                	ld	s1,8(sp)
    80003d9a:	6105                	addi	sp,sp,32
    80003d9c:	8082                	ret

0000000080003d9e <bunpin>:

void
bunpin(struct buf *b) {
    80003d9e:	1101                	addi	sp,sp,-32
    80003da0:	ec06                	sd	ra,24(sp)
    80003da2:	e822                	sd	s0,16(sp)
    80003da4:	e426                	sd	s1,8(sp)
    80003da6:	1000                	addi	s0,sp,32
    80003da8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003daa:	00016517          	auipc	a0,0x16
    80003dae:	16650513          	addi	a0,a0,358 # 80019f10 <bcache>
    80003db2:	ffffd097          	auipc	ra,0xffffd
    80003db6:	e38080e7          	jalr	-456(ra) # 80000bea <acquire>
  b->refcnt--;
    80003dba:	40bc                	lw	a5,64(s1)
    80003dbc:	37fd                	addiw	a5,a5,-1
    80003dbe:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003dc0:	00016517          	auipc	a0,0x16
    80003dc4:	15050513          	addi	a0,a0,336 # 80019f10 <bcache>
    80003dc8:	ffffd097          	auipc	ra,0xffffd
    80003dcc:	ed6080e7          	jalr	-298(ra) # 80000c9e <release>
}
    80003dd0:	60e2                	ld	ra,24(sp)
    80003dd2:	6442                	ld	s0,16(sp)
    80003dd4:	64a2                	ld	s1,8(sp)
    80003dd6:	6105                	addi	sp,sp,32
    80003dd8:	8082                	ret

0000000080003dda <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003dda:	1101                	addi	sp,sp,-32
    80003ddc:	ec06                	sd	ra,24(sp)
    80003dde:	e822                	sd	s0,16(sp)
    80003de0:	e426                	sd	s1,8(sp)
    80003de2:	e04a                	sd	s2,0(sp)
    80003de4:	1000                	addi	s0,sp,32
    80003de6:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003de8:	00d5d59b          	srliw	a1,a1,0xd
    80003dec:	0001f797          	auipc	a5,0x1f
    80003df0:	8007a783          	lw	a5,-2048(a5) # 800225ec <sb+0x1c>
    80003df4:	9dbd                	addw	a1,a1,a5
    80003df6:	00000097          	auipc	ra,0x0
    80003dfa:	d9e080e7          	jalr	-610(ra) # 80003b94 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003dfe:	0074f713          	andi	a4,s1,7
    80003e02:	4785                	li	a5,1
    80003e04:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003e08:	14ce                	slli	s1,s1,0x33
    80003e0a:	90d9                	srli	s1,s1,0x36
    80003e0c:	00950733          	add	a4,a0,s1
    80003e10:	05874703          	lbu	a4,88(a4)
    80003e14:	00e7f6b3          	and	a3,a5,a4
    80003e18:	c69d                	beqz	a3,80003e46 <bfree+0x6c>
    80003e1a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003e1c:	94aa                	add	s1,s1,a0
    80003e1e:	fff7c793          	not	a5,a5
    80003e22:	8ff9                	and	a5,a5,a4
    80003e24:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003e28:	00001097          	auipc	ra,0x1
    80003e2c:	120080e7          	jalr	288(ra) # 80004f48 <log_write>
  brelse(bp);
    80003e30:	854a                	mv	a0,s2
    80003e32:	00000097          	auipc	ra,0x0
    80003e36:	e92080e7          	jalr	-366(ra) # 80003cc4 <brelse>
}
    80003e3a:	60e2                	ld	ra,24(sp)
    80003e3c:	6442                	ld	s0,16(sp)
    80003e3e:	64a2                	ld	s1,8(sp)
    80003e40:	6902                	ld	s2,0(sp)
    80003e42:	6105                	addi	sp,sp,32
    80003e44:	8082                	ret
    panic("freeing free block");
    80003e46:	00006517          	auipc	a0,0x6
    80003e4a:	8fa50513          	addi	a0,a0,-1798 # 80009740 <syscalls+0x118>
    80003e4e:	ffffc097          	auipc	ra,0xffffc
    80003e52:	6f6080e7          	jalr	1782(ra) # 80000544 <panic>

0000000080003e56 <balloc>:
{
    80003e56:	711d                	addi	sp,sp,-96
    80003e58:	ec86                	sd	ra,88(sp)
    80003e5a:	e8a2                	sd	s0,80(sp)
    80003e5c:	e4a6                	sd	s1,72(sp)
    80003e5e:	e0ca                	sd	s2,64(sp)
    80003e60:	fc4e                	sd	s3,56(sp)
    80003e62:	f852                	sd	s4,48(sp)
    80003e64:	f456                	sd	s5,40(sp)
    80003e66:	f05a                	sd	s6,32(sp)
    80003e68:	ec5e                	sd	s7,24(sp)
    80003e6a:	e862                	sd	s8,16(sp)
    80003e6c:	e466                	sd	s9,8(sp)
    80003e6e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003e70:	0001e797          	auipc	a5,0x1e
    80003e74:	7647a783          	lw	a5,1892(a5) # 800225d4 <sb+0x4>
    80003e78:	10078163          	beqz	a5,80003f7a <balloc+0x124>
    80003e7c:	8baa                	mv	s7,a0
    80003e7e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003e80:	0001eb17          	auipc	s6,0x1e
    80003e84:	750b0b13          	addi	s6,s6,1872 # 800225d0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e88:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003e8a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e8c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003e8e:	6c89                	lui	s9,0x2
    80003e90:	a061                	j	80003f18 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003e92:	974a                	add	a4,a4,s2
    80003e94:	8fd5                	or	a5,a5,a3
    80003e96:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003e9a:	854a                	mv	a0,s2
    80003e9c:	00001097          	auipc	ra,0x1
    80003ea0:	0ac080e7          	jalr	172(ra) # 80004f48 <log_write>
        brelse(bp);
    80003ea4:	854a                	mv	a0,s2
    80003ea6:	00000097          	auipc	ra,0x0
    80003eaa:	e1e080e7          	jalr	-482(ra) # 80003cc4 <brelse>
  bp = bread(dev, bno);
    80003eae:	85a6                	mv	a1,s1
    80003eb0:	855e                	mv	a0,s7
    80003eb2:	00000097          	auipc	ra,0x0
    80003eb6:	ce2080e7          	jalr	-798(ra) # 80003b94 <bread>
    80003eba:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003ebc:	40000613          	li	a2,1024
    80003ec0:	4581                	li	a1,0
    80003ec2:	05850513          	addi	a0,a0,88
    80003ec6:	ffffd097          	auipc	ra,0xffffd
    80003eca:	e20080e7          	jalr	-480(ra) # 80000ce6 <memset>
  log_write(bp);
    80003ece:	854a                	mv	a0,s2
    80003ed0:	00001097          	auipc	ra,0x1
    80003ed4:	078080e7          	jalr	120(ra) # 80004f48 <log_write>
  brelse(bp);
    80003ed8:	854a                	mv	a0,s2
    80003eda:	00000097          	auipc	ra,0x0
    80003ede:	dea080e7          	jalr	-534(ra) # 80003cc4 <brelse>
}
    80003ee2:	8526                	mv	a0,s1
    80003ee4:	60e6                	ld	ra,88(sp)
    80003ee6:	6446                	ld	s0,80(sp)
    80003ee8:	64a6                	ld	s1,72(sp)
    80003eea:	6906                	ld	s2,64(sp)
    80003eec:	79e2                	ld	s3,56(sp)
    80003eee:	7a42                	ld	s4,48(sp)
    80003ef0:	7aa2                	ld	s5,40(sp)
    80003ef2:	7b02                	ld	s6,32(sp)
    80003ef4:	6be2                	ld	s7,24(sp)
    80003ef6:	6c42                	ld	s8,16(sp)
    80003ef8:	6ca2                	ld	s9,8(sp)
    80003efa:	6125                	addi	sp,sp,96
    80003efc:	8082                	ret
    brelse(bp);
    80003efe:	854a                	mv	a0,s2
    80003f00:	00000097          	auipc	ra,0x0
    80003f04:	dc4080e7          	jalr	-572(ra) # 80003cc4 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003f08:	015c87bb          	addw	a5,s9,s5
    80003f0c:	00078a9b          	sext.w	s5,a5
    80003f10:	004b2703          	lw	a4,4(s6)
    80003f14:	06eaf363          	bgeu	s5,a4,80003f7a <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003f18:	41fad79b          	sraiw	a5,s5,0x1f
    80003f1c:	0137d79b          	srliw	a5,a5,0x13
    80003f20:	015787bb          	addw	a5,a5,s5
    80003f24:	40d7d79b          	sraiw	a5,a5,0xd
    80003f28:	01cb2583          	lw	a1,28(s6)
    80003f2c:	9dbd                	addw	a1,a1,a5
    80003f2e:	855e                	mv	a0,s7
    80003f30:	00000097          	auipc	ra,0x0
    80003f34:	c64080e7          	jalr	-924(ra) # 80003b94 <bread>
    80003f38:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003f3a:	004b2503          	lw	a0,4(s6)
    80003f3e:	000a849b          	sext.w	s1,s5
    80003f42:	8662                	mv	a2,s8
    80003f44:	faa4fde3          	bgeu	s1,a0,80003efe <balloc+0xa8>
      m = 1 << (bi % 8);
    80003f48:	41f6579b          	sraiw	a5,a2,0x1f
    80003f4c:	01d7d69b          	srliw	a3,a5,0x1d
    80003f50:	00c6873b          	addw	a4,a3,a2
    80003f54:	00777793          	andi	a5,a4,7
    80003f58:	9f95                	subw	a5,a5,a3
    80003f5a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003f5e:	4037571b          	sraiw	a4,a4,0x3
    80003f62:	00e906b3          	add	a3,s2,a4
    80003f66:	0586c683          	lbu	a3,88(a3)
    80003f6a:	00d7f5b3          	and	a1,a5,a3
    80003f6e:	d195                	beqz	a1,80003e92 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003f70:	2605                	addiw	a2,a2,1
    80003f72:	2485                	addiw	s1,s1,1
    80003f74:	fd4618e3          	bne	a2,s4,80003f44 <balloc+0xee>
    80003f78:	b759                	j	80003efe <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003f7a:	00005517          	auipc	a0,0x5
    80003f7e:	7de50513          	addi	a0,a0,2014 # 80009758 <syscalls+0x130>
    80003f82:	ffffc097          	auipc	ra,0xffffc
    80003f86:	60c080e7          	jalr	1548(ra) # 8000058e <printf>
  return 0;
    80003f8a:	4481                	li	s1,0
    80003f8c:	bf99                	j	80003ee2 <balloc+0x8c>

0000000080003f8e <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003f8e:	7179                	addi	sp,sp,-48
    80003f90:	f406                	sd	ra,40(sp)
    80003f92:	f022                	sd	s0,32(sp)
    80003f94:	ec26                	sd	s1,24(sp)
    80003f96:	e84a                	sd	s2,16(sp)
    80003f98:	e44e                	sd	s3,8(sp)
    80003f9a:	e052                	sd	s4,0(sp)
    80003f9c:	1800                	addi	s0,sp,48
    80003f9e:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003fa0:	47ad                	li	a5,11
    80003fa2:	02b7e763          	bltu	a5,a1,80003fd0 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003fa6:	02059493          	slli	s1,a1,0x20
    80003faa:	9081                	srli	s1,s1,0x20
    80003fac:	048a                	slli	s1,s1,0x2
    80003fae:	94aa                	add	s1,s1,a0
    80003fb0:	0504a903          	lw	s2,80(s1)
    80003fb4:	06091e63          	bnez	s2,80004030 <bmap+0xa2>
      addr = balloc(ip->dev);
    80003fb8:	4108                	lw	a0,0(a0)
    80003fba:	00000097          	auipc	ra,0x0
    80003fbe:	e9c080e7          	jalr	-356(ra) # 80003e56 <balloc>
    80003fc2:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003fc6:	06090563          	beqz	s2,80004030 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003fca:	0524a823          	sw	s2,80(s1)
    80003fce:	a08d                	j	80004030 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003fd0:	ff45849b          	addiw	s1,a1,-12
    80003fd4:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003fd8:	0ff00793          	li	a5,255
    80003fdc:	08e7e563          	bltu	a5,a4,80004066 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003fe0:	08052903          	lw	s2,128(a0)
    80003fe4:	00091d63          	bnez	s2,80003ffe <bmap+0x70>
      addr = balloc(ip->dev);
    80003fe8:	4108                	lw	a0,0(a0)
    80003fea:	00000097          	auipc	ra,0x0
    80003fee:	e6c080e7          	jalr	-404(ra) # 80003e56 <balloc>
    80003ff2:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003ff6:	02090d63          	beqz	s2,80004030 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003ffa:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003ffe:	85ca                	mv	a1,s2
    80004000:	0009a503          	lw	a0,0(s3)
    80004004:	00000097          	auipc	ra,0x0
    80004008:	b90080e7          	jalr	-1136(ra) # 80003b94 <bread>
    8000400c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000400e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80004012:	02049593          	slli	a1,s1,0x20
    80004016:	9181                	srli	a1,a1,0x20
    80004018:	058a                	slli	a1,a1,0x2
    8000401a:	00b784b3          	add	s1,a5,a1
    8000401e:	0004a903          	lw	s2,0(s1)
    80004022:	02090063          	beqz	s2,80004042 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80004026:	8552                	mv	a0,s4
    80004028:	00000097          	auipc	ra,0x0
    8000402c:	c9c080e7          	jalr	-868(ra) # 80003cc4 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80004030:	854a                	mv	a0,s2
    80004032:	70a2                	ld	ra,40(sp)
    80004034:	7402                	ld	s0,32(sp)
    80004036:	64e2                	ld	s1,24(sp)
    80004038:	6942                	ld	s2,16(sp)
    8000403a:	69a2                	ld	s3,8(sp)
    8000403c:	6a02                	ld	s4,0(sp)
    8000403e:	6145                	addi	sp,sp,48
    80004040:	8082                	ret
      addr = balloc(ip->dev);
    80004042:	0009a503          	lw	a0,0(s3)
    80004046:	00000097          	auipc	ra,0x0
    8000404a:	e10080e7          	jalr	-496(ra) # 80003e56 <balloc>
    8000404e:	0005091b          	sext.w	s2,a0
      if(addr){
    80004052:	fc090ae3          	beqz	s2,80004026 <bmap+0x98>
        a[bn] = addr;
    80004056:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000405a:	8552                	mv	a0,s4
    8000405c:	00001097          	auipc	ra,0x1
    80004060:	eec080e7          	jalr	-276(ra) # 80004f48 <log_write>
    80004064:	b7c9                	j	80004026 <bmap+0x98>
  panic("bmap: out of range");
    80004066:	00005517          	auipc	a0,0x5
    8000406a:	70a50513          	addi	a0,a0,1802 # 80009770 <syscalls+0x148>
    8000406e:	ffffc097          	auipc	ra,0xffffc
    80004072:	4d6080e7          	jalr	1238(ra) # 80000544 <panic>

0000000080004076 <iget>:
{
    80004076:	7179                	addi	sp,sp,-48
    80004078:	f406                	sd	ra,40(sp)
    8000407a:	f022                	sd	s0,32(sp)
    8000407c:	ec26                	sd	s1,24(sp)
    8000407e:	e84a                	sd	s2,16(sp)
    80004080:	e44e                	sd	s3,8(sp)
    80004082:	e052                	sd	s4,0(sp)
    80004084:	1800                	addi	s0,sp,48
    80004086:	89aa                	mv	s3,a0
    80004088:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000408a:	0001e517          	auipc	a0,0x1e
    8000408e:	56650513          	addi	a0,a0,1382 # 800225f0 <itable>
    80004092:	ffffd097          	auipc	ra,0xffffd
    80004096:	b58080e7          	jalr	-1192(ra) # 80000bea <acquire>
  empty = 0;
    8000409a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000409c:	0001e497          	auipc	s1,0x1e
    800040a0:	56c48493          	addi	s1,s1,1388 # 80022608 <itable+0x18>
    800040a4:	00020697          	auipc	a3,0x20
    800040a8:	ff468693          	addi	a3,a3,-12 # 80024098 <log>
    800040ac:	a039                	j	800040ba <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800040ae:	02090b63          	beqz	s2,800040e4 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800040b2:	08848493          	addi	s1,s1,136
    800040b6:	02d48a63          	beq	s1,a3,800040ea <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800040ba:	449c                	lw	a5,8(s1)
    800040bc:	fef059e3          	blez	a5,800040ae <iget+0x38>
    800040c0:	4098                	lw	a4,0(s1)
    800040c2:	ff3716e3          	bne	a4,s3,800040ae <iget+0x38>
    800040c6:	40d8                	lw	a4,4(s1)
    800040c8:	ff4713e3          	bne	a4,s4,800040ae <iget+0x38>
      ip->ref++;
    800040cc:	2785                	addiw	a5,a5,1
    800040ce:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800040d0:	0001e517          	auipc	a0,0x1e
    800040d4:	52050513          	addi	a0,a0,1312 # 800225f0 <itable>
    800040d8:	ffffd097          	auipc	ra,0xffffd
    800040dc:	bc6080e7          	jalr	-1082(ra) # 80000c9e <release>
      return ip;
    800040e0:	8926                	mv	s2,s1
    800040e2:	a03d                	j	80004110 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800040e4:	f7f9                	bnez	a5,800040b2 <iget+0x3c>
    800040e6:	8926                	mv	s2,s1
    800040e8:	b7e9                	j	800040b2 <iget+0x3c>
  if(empty == 0)
    800040ea:	02090c63          	beqz	s2,80004122 <iget+0xac>
  ip->dev = dev;
    800040ee:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800040f2:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800040f6:	4785                	li	a5,1
    800040f8:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800040fc:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80004100:	0001e517          	auipc	a0,0x1e
    80004104:	4f050513          	addi	a0,a0,1264 # 800225f0 <itable>
    80004108:	ffffd097          	auipc	ra,0xffffd
    8000410c:	b96080e7          	jalr	-1130(ra) # 80000c9e <release>
}
    80004110:	854a                	mv	a0,s2
    80004112:	70a2                	ld	ra,40(sp)
    80004114:	7402                	ld	s0,32(sp)
    80004116:	64e2                	ld	s1,24(sp)
    80004118:	6942                	ld	s2,16(sp)
    8000411a:	69a2                	ld	s3,8(sp)
    8000411c:	6a02                	ld	s4,0(sp)
    8000411e:	6145                	addi	sp,sp,48
    80004120:	8082                	ret
    panic("iget: no inodes");
    80004122:	00005517          	auipc	a0,0x5
    80004126:	66650513          	addi	a0,a0,1638 # 80009788 <syscalls+0x160>
    8000412a:	ffffc097          	auipc	ra,0xffffc
    8000412e:	41a080e7          	jalr	1050(ra) # 80000544 <panic>

0000000080004132 <fsinit>:
fsinit(int dev) {
    80004132:	7179                	addi	sp,sp,-48
    80004134:	f406                	sd	ra,40(sp)
    80004136:	f022                	sd	s0,32(sp)
    80004138:	ec26                	sd	s1,24(sp)
    8000413a:	e84a                	sd	s2,16(sp)
    8000413c:	e44e                	sd	s3,8(sp)
    8000413e:	1800                	addi	s0,sp,48
    80004140:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80004142:	4585                	li	a1,1
    80004144:	00000097          	auipc	ra,0x0
    80004148:	a50080e7          	jalr	-1456(ra) # 80003b94 <bread>
    8000414c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000414e:	0001e997          	auipc	s3,0x1e
    80004152:	48298993          	addi	s3,s3,1154 # 800225d0 <sb>
    80004156:	02000613          	li	a2,32
    8000415a:	05850593          	addi	a1,a0,88
    8000415e:	854e                	mv	a0,s3
    80004160:	ffffd097          	auipc	ra,0xffffd
    80004164:	be6080e7          	jalr	-1050(ra) # 80000d46 <memmove>
  brelse(bp);
    80004168:	8526                	mv	a0,s1
    8000416a:	00000097          	auipc	ra,0x0
    8000416e:	b5a080e7          	jalr	-1190(ra) # 80003cc4 <brelse>
  if(sb.magic != FSMAGIC)
    80004172:	0009a703          	lw	a4,0(s3)
    80004176:	102037b7          	lui	a5,0x10203
    8000417a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000417e:	02f71263          	bne	a4,a5,800041a2 <fsinit+0x70>
  initlog(dev, &sb);
    80004182:	0001e597          	auipc	a1,0x1e
    80004186:	44e58593          	addi	a1,a1,1102 # 800225d0 <sb>
    8000418a:	854a                	mv	a0,s2
    8000418c:	00001097          	auipc	ra,0x1
    80004190:	b40080e7          	jalr	-1216(ra) # 80004ccc <initlog>
}
    80004194:	70a2                	ld	ra,40(sp)
    80004196:	7402                	ld	s0,32(sp)
    80004198:	64e2                	ld	s1,24(sp)
    8000419a:	6942                	ld	s2,16(sp)
    8000419c:	69a2                	ld	s3,8(sp)
    8000419e:	6145                	addi	sp,sp,48
    800041a0:	8082                	ret
    panic("invalid file system");
    800041a2:	00005517          	auipc	a0,0x5
    800041a6:	5f650513          	addi	a0,a0,1526 # 80009798 <syscalls+0x170>
    800041aa:	ffffc097          	auipc	ra,0xffffc
    800041ae:	39a080e7          	jalr	922(ra) # 80000544 <panic>

00000000800041b2 <iinit>:
{
    800041b2:	7179                	addi	sp,sp,-48
    800041b4:	f406                	sd	ra,40(sp)
    800041b6:	f022                	sd	s0,32(sp)
    800041b8:	ec26                	sd	s1,24(sp)
    800041ba:	e84a                	sd	s2,16(sp)
    800041bc:	e44e                	sd	s3,8(sp)
    800041be:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800041c0:	00005597          	auipc	a1,0x5
    800041c4:	5f058593          	addi	a1,a1,1520 # 800097b0 <syscalls+0x188>
    800041c8:	0001e517          	auipc	a0,0x1e
    800041cc:	42850513          	addi	a0,a0,1064 # 800225f0 <itable>
    800041d0:	ffffd097          	auipc	ra,0xffffd
    800041d4:	98a080e7          	jalr	-1654(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    800041d8:	0001e497          	auipc	s1,0x1e
    800041dc:	44048493          	addi	s1,s1,1088 # 80022618 <itable+0x28>
    800041e0:	00020997          	auipc	s3,0x20
    800041e4:	ec898993          	addi	s3,s3,-312 # 800240a8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800041e8:	00005917          	auipc	s2,0x5
    800041ec:	5d090913          	addi	s2,s2,1488 # 800097b8 <syscalls+0x190>
    800041f0:	85ca                	mv	a1,s2
    800041f2:	8526                	mv	a0,s1
    800041f4:	00001097          	auipc	ra,0x1
    800041f8:	e3a080e7          	jalr	-454(ra) # 8000502e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800041fc:	08848493          	addi	s1,s1,136
    80004200:	ff3498e3          	bne	s1,s3,800041f0 <iinit+0x3e>
}
    80004204:	70a2                	ld	ra,40(sp)
    80004206:	7402                	ld	s0,32(sp)
    80004208:	64e2                	ld	s1,24(sp)
    8000420a:	6942                	ld	s2,16(sp)
    8000420c:	69a2                	ld	s3,8(sp)
    8000420e:	6145                	addi	sp,sp,48
    80004210:	8082                	ret

0000000080004212 <ialloc>:
{
    80004212:	715d                	addi	sp,sp,-80
    80004214:	e486                	sd	ra,72(sp)
    80004216:	e0a2                	sd	s0,64(sp)
    80004218:	fc26                	sd	s1,56(sp)
    8000421a:	f84a                	sd	s2,48(sp)
    8000421c:	f44e                	sd	s3,40(sp)
    8000421e:	f052                	sd	s4,32(sp)
    80004220:	ec56                	sd	s5,24(sp)
    80004222:	e85a                	sd	s6,16(sp)
    80004224:	e45e                	sd	s7,8(sp)
    80004226:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80004228:	0001e717          	auipc	a4,0x1e
    8000422c:	3b472703          	lw	a4,948(a4) # 800225dc <sb+0xc>
    80004230:	4785                	li	a5,1
    80004232:	04e7fa63          	bgeu	a5,a4,80004286 <ialloc+0x74>
    80004236:	8aaa                	mv	s5,a0
    80004238:	8bae                	mv	s7,a1
    8000423a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000423c:	0001ea17          	auipc	s4,0x1e
    80004240:	394a0a13          	addi	s4,s4,916 # 800225d0 <sb>
    80004244:	00048b1b          	sext.w	s6,s1
    80004248:	0044d593          	srli	a1,s1,0x4
    8000424c:	018a2783          	lw	a5,24(s4)
    80004250:	9dbd                	addw	a1,a1,a5
    80004252:	8556                	mv	a0,s5
    80004254:	00000097          	auipc	ra,0x0
    80004258:	940080e7          	jalr	-1728(ra) # 80003b94 <bread>
    8000425c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000425e:	05850993          	addi	s3,a0,88
    80004262:	00f4f793          	andi	a5,s1,15
    80004266:	079a                	slli	a5,a5,0x6
    80004268:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000426a:	00099783          	lh	a5,0(s3)
    8000426e:	c3a1                	beqz	a5,800042ae <ialloc+0x9c>
    brelse(bp);
    80004270:	00000097          	auipc	ra,0x0
    80004274:	a54080e7          	jalr	-1452(ra) # 80003cc4 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80004278:	0485                	addi	s1,s1,1
    8000427a:	00ca2703          	lw	a4,12(s4)
    8000427e:	0004879b          	sext.w	a5,s1
    80004282:	fce7e1e3          	bltu	a5,a4,80004244 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80004286:	00005517          	auipc	a0,0x5
    8000428a:	53a50513          	addi	a0,a0,1338 # 800097c0 <syscalls+0x198>
    8000428e:	ffffc097          	auipc	ra,0xffffc
    80004292:	300080e7          	jalr	768(ra) # 8000058e <printf>
  return 0;
    80004296:	4501                	li	a0,0
}
    80004298:	60a6                	ld	ra,72(sp)
    8000429a:	6406                	ld	s0,64(sp)
    8000429c:	74e2                	ld	s1,56(sp)
    8000429e:	7942                	ld	s2,48(sp)
    800042a0:	79a2                	ld	s3,40(sp)
    800042a2:	7a02                	ld	s4,32(sp)
    800042a4:	6ae2                	ld	s5,24(sp)
    800042a6:	6b42                	ld	s6,16(sp)
    800042a8:	6ba2                	ld	s7,8(sp)
    800042aa:	6161                	addi	sp,sp,80
    800042ac:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800042ae:	04000613          	li	a2,64
    800042b2:	4581                	li	a1,0
    800042b4:	854e                	mv	a0,s3
    800042b6:	ffffd097          	auipc	ra,0xffffd
    800042ba:	a30080e7          	jalr	-1488(ra) # 80000ce6 <memset>
      dip->type = type;
    800042be:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800042c2:	854a                	mv	a0,s2
    800042c4:	00001097          	auipc	ra,0x1
    800042c8:	c84080e7          	jalr	-892(ra) # 80004f48 <log_write>
      brelse(bp);
    800042cc:	854a                	mv	a0,s2
    800042ce:	00000097          	auipc	ra,0x0
    800042d2:	9f6080e7          	jalr	-1546(ra) # 80003cc4 <brelse>
      return iget(dev, inum);
    800042d6:	85da                	mv	a1,s6
    800042d8:	8556                	mv	a0,s5
    800042da:	00000097          	auipc	ra,0x0
    800042de:	d9c080e7          	jalr	-612(ra) # 80004076 <iget>
    800042e2:	bf5d                	j	80004298 <ialloc+0x86>

00000000800042e4 <iupdate>:
{
    800042e4:	1101                	addi	sp,sp,-32
    800042e6:	ec06                	sd	ra,24(sp)
    800042e8:	e822                	sd	s0,16(sp)
    800042ea:	e426                	sd	s1,8(sp)
    800042ec:	e04a                	sd	s2,0(sp)
    800042ee:	1000                	addi	s0,sp,32
    800042f0:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800042f2:	415c                	lw	a5,4(a0)
    800042f4:	0047d79b          	srliw	a5,a5,0x4
    800042f8:	0001e597          	auipc	a1,0x1e
    800042fc:	2f05a583          	lw	a1,752(a1) # 800225e8 <sb+0x18>
    80004300:	9dbd                	addw	a1,a1,a5
    80004302:	4108                	lw	a0,0(a0)
    80004304:	00000097          	auipc	ra,0x0
    80004308:	890080e7          	jalr	-1904(ra) # 80003b94 <bread>
    8000430c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000430e:	05850793          	addi	a5,a0,88
    80004312:	40c8                	lw	a0,4(s1)
    80004314:	893d                	andi	a0,a0,15
    80004316:	051a                	slli	a0,a0,0x6
    80004318:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000431a:	04449703          	lh	a4,68(s1)
    8000431e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80004322:	04649703          	lh	a4,70(s1)
    80004326:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000432a:	04849703          	lh	a4,72(s1)
    8000432e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80004332:	04a49703          	lh	a4,74(s1)
    80004336:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000433a:	44f8                	lw	a4,76(s1)
    8000433c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000433e:	03400613          	li	a2,52
    80004342:	05048593          	addi	a1,s1,80
    80004346:	0531                	addi	a0,a0,12
    80004348:	ffffd097          	auipc	ra,0xffffd
    8000434c:	9fe080e7          	jalr	-1538(ra) # 80000d46 <memmove>
  log_write(bp);
    80004350:	854a                	mv	a0,s2
    80004352:	00001097          	auipc	ra,0x1
    80004356:	bf6080e7          	jalr	-1034(ra) # 80004f48 <log_write>
  brelse(bp);
    8000435a:	854a                	mv	a0,s2
    8000435c:	00000097          	auipc	ra,0x0
    80004360:	968080e7          	jalr	-1688(ra) # 80003cc4 <brelse>
}
    80004364:	60e2                	ld	ra,24(sp)
    80004366:	6442                	ld	s0,16(sp)
    80004368:	64a2                	ld	s1,8(sp)
    8000436a:	6902                	ld	s2,0(sp)
    8000436c:	6105                	addi	sp,sp,32
    8000436e:	8082                	ret

0000000080004370 <idup>:
{
    80004370:	1101                	addi	sp,sp,-32
    80004372:	ec06                	sd	ra,24(sp)
    80004374:	e822                	sd	s0,16(sp)
    80004376:	e426                	sd	s1,8(sp)
    80004378:	1000                	addi	s0,sp,32
    8000437a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000437c:	0001e517          	auipc	a0,0x1e
    80004380:	27450513          	addi	a0,a0,628 # 800225f0 <itable>
    80004384:	ffffd097          	auipc	ra,0xffffd
    80004388:	866080e7          	jalr	-1946(ra) # 80000bea <acquire>
  ip->ref++;
    8000438c:	449c                	lw	a5,8(s1)
    8000438e:	2785                	addiw	a5,a5,1
    80004390:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004392:	0001e517          	auipc	a0,0x1e
    80004396:	25e50513          	addi	a0,a0,606 # 800225f0 <itable>
    8000439a:	ffffd097          	auipc	ra,0xffffd
    8000439e:	904080e7          	jalr	-1788(ra) # 80000c9e <release>
}
    800043a2:	8526                	mv	a0,s1
    800043a4:	60e2                	ld	ra,24(sp)
    800043a6:	6442                	ld	s0,16(sp)
    800043a8:	64a2                	ld	s1,8(sp)
    800043aa:	6105                	addi	sp,sp,32
    800043ac:	8082                	ret

00000000800043ae <ilock>:
{
    800043ae:	1101                	addi	sp,sp,-32
    800043b0:	ec06                	sd	ra,24(sp)
    800043b2:	e822                	sd	s0,16(sp)
    800043b4:	e426                	sd	s1,8(sp)
    800043b6:	e04a                	sd	s2,0(sp)
    800043b8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800043ba:	c115                	beqz	a0,800043de <ilock+0x30>
    800043bc:	84aa                	mv	s1,a0
    800043be:	451c                	lw	a5,8(a0)
    800043c0:	00f05f63          	blez	a5,800043de <ilock+0x30>
  acquiresleep(&ip->lock);
    800043c4:	0541                	addi	a0,a0,16
    800043c6:	00001097          	auipc	ra,0x1
    800043ca:	ca2080e7          	jalr	-862(ra) # 80005068 <acquiresleep>
  if(ip->valid == 0){
    800043ce:	40bc                	lw	a5,64(s1)
    800043d0:	cf99                	beqz	a5,800043ee <ilock+0x40>
}
    800043d2:	60e2                	ld	ra,24(sp)
    800043d4:	6442                	ld	s0,16(sp)
    800043d6:	64a2                	ld	s1,8(sp)
    800043d8:	6902                	ld	s2,0(sp)
    800043da:	6105                	addi	sp,sp,32
    800043dc:	8082                	ret
    panic("ilock");
    800043de:	00005517          	auipc	a0,0x5
    800043e2:	3fa50513          	addi	a0,a0,1018 # 800097d8 <syscalls+0x1b0>
    800043e6:	ffffc097          	auipc	ra,0xffffc
    800043ea:	15e080e7          	jalr	350(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800043ee:	40dc                	lw	a5,4(s1)
    800043f0:	0047d79b          	srliw	a5,a5,0x4
    800043f4:	0001e597          	auipc	a1,0x1e
    800043f8:	1f45a583          	lw	a1,500(a1) # 800225e8 <sb+0x18>
    800043fc:	9dbd                	addw	a1,a1,a5
    800043fe:	4088                	lw	a0,0(s1)
    80004400:	fffff097          	auipc	ra,0xfffff
    80004404:	794080e7          	jalr	1940(ra) # 80003b94 <bread>
    80004408:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000440a:	05850593          	addi	a1,a0,88
    8000440e:	40dc                	lw	a5,4(s1)
    80004410:	8bbd                	andi	a5,a5,15
    80004412:	079a                	slli	a5,a5,0x6
    80004414:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80004416:	00059783          	lh	a5,0(a1)
    8000441a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000441e:	00259783          	lh	a5,2(a1)
    80004422:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80004426:	00459783          	lh	a5,4(a1)
    8000442a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000442e:	00659783          	lh	a5,6(a1)
    80004432:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80004436:	459c                	lw	a5,8(a1)
    80004438:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000443a:	03400613          	li	a2,52
    8000443e:	05b1                	addi	a1,a1,12
    80004440:	05048513          	addi	a0,s1,80
    80004444:	ffffd097          	auipc	ra,0xffffd
    80004448:	902080e7          	jalr	-1790(ra) # 80000d46 <memmove>
    brelse(bp);
    8000444c:	854a                	mv	a0,s2
    8000444e:	00000097          	auipc	ra,0x0
    80004452:	876080e7          	jalr	-1930(ra) # 80003cc4 <brelse>
    ip->valid = 1;
    80004456:	4785                	li	a5,1
    80004458:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000445a:	04449783          	lh	a5,68(s1)
    8000445e:	fbb5                	bnez	a5,800043d2 <ilock+0x24>
      panic("ilock: no type");
    80004460:	00005517          	auipc	a0,0x5
    80004464:	38050513          	addi	a0,a0,896 # 800097e0 <syscalls+0x1b8>
    80004468:	ffffc097          	auipc	ra,0xffffc
    8000446c:	0dc080e7          	jalr	220(ra) # 80000544 <panic>

0000000080004470 <iunlock>:
{
    80004470:	1101                	addi	sp,sp,-32
    80004472:	ec06                	sd	ra,24(sp)
    80004474:	e822                	sd	s0,16(sp)
    80004476:	e426                	sd	s1,8(sp)
    80004478:	e04a                	sd	s2,0(sp)
    8000447a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000447c:	c905                	beqz	a0,800044ac <iunlock+0x3c>
    8000447e:	84aa                	mv	s1,a0
    80004480:	01050913          	addi	s2,a0,16
    80004484:	854a                	mv	a0,s2
    80004486:	00001097          	auipc	ra,0x1
    8000448a:	c7c080e7          	jalr	-900(ra) # 80005102 <holdingsleep>
    8000448e:	cd19                	beqz	a0,800044ac <iunlock+0x3c>
    80004490:	449c                	lw	a5,8(s1)
    80004492:	00f05d63          	blez	a5,800044ac <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004496:	854a                	mv	a0,s2
    80004498:	00001097          	auipc	ra,0x1
    8000449c:	c26080e7          	jalr	-986(ra) # 800050be <releasesleep>
}
    800044a0:	60e2                	ld	ra,24(sp)
    800044a2:	6442                	ld	s0,16(sp)
    800044a4:	64a2                	ld	s1,8(sp)
    800044a6:	6902                	ld	s2,0(sp)
    800044a8:	6105                	addi	sp,sp,32
    800044aa:	8082                	ret
    panic("iunlock");
    800044ac:	00005517          	auipc	a0,0x5
    800044b0:	34450513          	addi	a0,a0,836 # 800097f0 <syscalls+0x1c8>
    800044b4:	ffffc097          	auipc	ra,0xffffc
    800044b8:	090080e7          	jalr	144(ra) # 80000544 <panic>

00000000800044bc <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800044bc:	7179                	addi	sp,sp,-48
    800044be:	f406                	sd	ra,40(sp)
    800044c0:	f022                	sd	s0,32(sp)
    800044c2:	ec26                	sd	s1,24(sp)
    800044c4:	e84a                	sd	s2,16(sp)
    800044c6:	e44e                	sd	s3,8(sp)
    800044c8:	e052                	sd	s4,0(sp)
    800044ca:	1800                	addi	s0,sp,48
    800044cc:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800044ce:	05050493          	addi	s1,a0,80
    800044d2:	08050913          	addi	s2,a0,128
    800044d6:	a021                	j	800044de <itrunc+0x22>
    800044d8:	0491                	addi	s1,s1,4
    800044da:	01248d63          	beq	s1,s2,800044f4 <itrunc+0x38>
    if(ip->addrs[i]){
    800044de:	408c                	lw	a1,0(s1)
    800044e0:	dde5                	beqz	a1,800044d8 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800044e2:	0009a503          	lw	a0,0(s3)
    800044e6:	00000097          	auipc	ra,0x0
    800044ea:	8f4080e7          	jalr	-1804(ra) # 80003dda <bfree>
      ip->addrs[i] = 0;
    800044ee:	0004a023          	sw	zero,0(s1)
    800044f2:	b7dd                	j	800044d8 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800044f4:	0809a583          	lw	a1,128(s3)
    800044f8:	e185                	bnez	a1,80004518 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800044fa:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800044fe:	854e                	mv	a0,s3
    80004500:	00000097          	auipc	ra,0x0
    80004504:	de4080e7          	jalr	-540(ra) # 800042e4 <iupdate>
}
    80004508:	70a2                	ld	ra,40(sp)
    8000450a:	7402                	ld	s0,32(sp)
    8000450c:	64e2                	ld	s1,24(sp)
    8000450e:	6942                	ld	s2,16(sp)
    80004510:	69a2                	ld	s3,8(sp)
    80004512:	6a02                	ld	s4,0(sp)
    80004514:	6145                	addi	sp,sp,48
    80004516:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004518:	0009a503          	lw	a0,0(s3)
    8000451c:	fffff097          	auipc	ra,0xfffff
    80004520:	678080e7          	jalr	1656(ra) # 80003b94 <bread>
    80004524:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004526:	05850493          	addi	s1,a0,88
    8000452a:	45850913          	addi	s2,a0,1112
    8000452e:	a811                	j	80004542 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80004530:	0009a503          	lw	a0,0(s3)
    80004534:	00000097          	auipc	ra,0x0
    80004538:	8a6080e7          	jalr	-1882(ra) # 80003dda <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000453c:	0491                	addi	s1,s1,4
    8000453e:	01248563          	beq	s1,s2,80004548 <itrunc+0x8c>
      if(a[j])
    80004542:	408c                	lw	a1,0(s1)
    80004544:	dde5                	beqz	a1,8000453c <itrunc+0x80>
    80004546:	b7ed                	j	80004530 <itrunc+0x74>
    brelse(bp);
    80004548:	8552                	mv	a0,s4
    8000454a:	fffff097          	auipc	ra,0xfffff
    8000454e:	77a080e7          	jalr	1914(ra) # 80003cc4 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004552:	0809a583          	lw	a1,128(s3)
    80004556:	0009a503          	lw	a0,0(s3)
    8000455a:	00000097          	auipc	ra,0x0
    8000455e:	880080e7          	jalr	-1920(ra) # 80003dda <bfree>
    ip->addrs[NDIRECT] = 0;
    80004562:	0809a023          	sw	zero,128(s3)
    80004566:	bf51                	j	800044fa <itrunc+0x3e>

0000000080004568 <iput>:
{
    80004568:	1101                	addi	sp,sp,-32
    8000456a:	ec06                	sd	ra,24(sp)
    8000456c:	e822                	sd	s0,16(sp)
    8000456e:	e426                	sd	s1,8(sp)
    80004570:	e04a                	sd	s2,0(sp)
    80004572:	1000                	addi	s0,sp,32
    80004574:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004576:	0001e517          	auipc	a0,0x1e
    8000457a:	07a50513          	addi	a0,a0,122 # 800225f0 <itable>
    8000457e:	ffffc097          	auipc	ra,0xffffc
    80004582:	66c080e7          	jalr	1644(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004586:	4498                	lw	a4,8(s1)
    80004588:	4785                	li	a5,1
    8000458a:	02f70363          	beq	a4,a5,800045b0 <iput+0x48>
  ip->ref--;
    8000458e:	449c                	lw	a5,8(s1)
    80004590:	37fd                	addiw	a5,a5,-1
    80004592:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004594:	0001e517          	auipc	a0,0x1e
    80004598:	05c50513          	addi	a0,a0,92 # 800225f0 <itable>
    8000459c:	ffffc097          	auipc	ra,0xffffc
    800045a0:	702080e7          	jalr	1794(ra) # 80000c9e <release>
}
    800045a4:	60e2                	ld	ra,24(sp)
    800045a6:	6442                	ld	s0,16(sp)
    800045a8:	64a2                	ld	s1,8(sp)
    800045aa:	6902                	ld	s2,0(sp)
    800045ac:	6105                	addi	sp,sp,32
    800045ae:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800045b0:	40bc                	lw	a5,64(s1)
    800045b2:	dff1                	beqz	a5,8000458e <iput+0x26>
    800045b4:	04a49783          	lh	a5,74(s1)
    800045b8:	fbf9                	bnez	a5,8000458e <iput+0x26>
    acquiresleep(&ip->lock);
    800045ba:	01048913          	addi	s2,s1,16
    800045be:	854a                	mv	a0,s2
    800045c0:	00001097          	auipc	ra,0x1
    800045c4:	aa8080e7          	jalr	-1368(ra) # 80005068 <acquiresleep>
    release(&itable.lock);
    800045c8:	0001e517          	auipc	a0,0x1e
    800045cc:	02850513          	addi	a0,a0,40 # 800225f0 <itable>
    800045d0:	ffffc097          	auipc	ra,0xffffc
    800045d4:	6ce080e7          	jalr	1742(ra) # 80000c9e <release>
    itrunc(ip);
    800045d8:	8526                	mv	a0,s1
    800045da:	00000097          	auipc	ra,0x0
    800045de:	ee2080e7          	jalr	-286(ra) # 800044bc <itrunc>
    ip->type = 0;
    800045e2:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800045e6:	8526                	mv	a0,s1
    800045e8:	00000097          	auipc	ra,0x0
    800045ec:	cfc080e7          	jalr	-772(ra) # 800042e4 <iupdate>
    ip->valid = 0;
    800045f0:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800045f4:	854a                	mv	a0,s2
    800045f6:	00001097          	auipc	ra,0x1
    800045fa:	ac8080e7          	jalr	-1336(ra) # 800050be <releasesleep>
    acquire(&itable.lock);
    800045fe:	0001e517          	auipc	a0,0x1e
    80004602:	ff250513          	addi	a0,a0,-14 # 800225f0 <itable>
    80004606:	ffffc097          	auipc	ra,0xffffc
    8000460a:	5e4080e7          	jalr	1508(ra) # 80000bea <acquire>
    8000460e:	b741                	j	8000458e <iput+0x26>

0000000080004610 <iunlockput>:
{
    80004610:	1101                	addi	sp,sp,-32
    80004612:	ec06                	sd	ra,24(sp)
    80004614:	e822                	sd	s0,16(sp)
    80004616:	e426                	sd	s1,8(sp)
    80004618:	1000                	addi	s0,sp,32
    8000461a:	84aa                	mv	s1,a0
  iunlock(ip);
    8000461c:	00000097          	auipc	ra,0x0
    80004620:	e54080e7          	jalr	-428(ra) # 80004470 <iunlock>
  iput(ip);
    80004624:	8526                	mv	a0,s1
    80004626:	00000097          	auipc	ra,0x0
    8000462a:	f42080e7          	jalr	-190(ra) # 80004568 <iput>
}
    8000462e:	60e2                	ld	ra,24(sp)
    80004630:	6442                	ld	s0,16(sp)
    80004632:	64a2                	ld	s1,8(sp)
    80004634:	6105                	addi	sp,sp,32
    80004636:	8082                	ret

0000000080004638 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004638:	1141                	addi	sp,sp,-16
    8000463a:	e422                	sd	s0,8(sp)
    8000463c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000463e:	411c                	lw	a5,0(a0)
    80004640:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004642:	415c                	lw	a5,4(a0)
    80004644:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004646:	04451783          	lh	a5,68(a0)
    8000464a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000464e:	04a51783          	lh	a5,74(a0)
    80004652:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004656:	04c56783          	lwu	a5,76(a0)
    8000465a:	e99c                	sd	a5,16(a1)
}
    8000465c:	6422                	ld	s0,8(sp)
    8000465e:	0141                	addi	sp,sp,16
    80004660:	8082                	ret

0000000080004662 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004662:	457c                	lw	a5,76(a0)
    80004664:	0ed7e963          	bltu	a5,a3,80004756 <readi+0xf4>
{
    80004668:	7159                	addi	sp,sp,-112
    8000466a:	f486                	sd	ra,104(sp)
    8000466c:	f0a2                	sd	s0,96(sp)
    8000466e:	eca6                	sd	s1,88(sp)
    80004670:	e8ca                	sd	s2,80(sp)
    80004672:	e4ce                	sd	s3,72(sp)
    80004674:	e0d2                	sd	s4,64(sp)
    80004676:	fc56                	sd	s5,56(sp)
    80004678:	f85a                	sd	s6,48(sp)
    8000467a:	f45e                	sd	s7,40(sp)
    8000467c:	f062                	sd	s8,32(sp)
    8000467e:	ec66                	sd	s9,24(sp)
    80004680:	e86a                	sd	s10,16(sp)
    80004682:	e46e                	sd	s11,8(sp)
    80004684:	1880                	addi	s0,sp,112
    80004686:	8b2a                	mv	s6,a0
    80004688:	8bae                	mv	s7,a1
    8000468a:	8a32                	mv	s4,a2
    8000468c:	84b6                	mv	s1,a3
    8000468e:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80004690:	9f35                	addw	a4,a4,a3
    return 0;
    80004692:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004694:	0ad76063          	bltu	a4,a3,80004734 <readi+0xd2>
  if(off + n > ip->size)
    80004698:	00e7f463          	bgeu	a5,a4,800046a0 <readi+0x3e>
    n = ip->size - off;
    8000469c:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800046a0:	0a0a8963          	beqz	s5,80004752 <readi+0xf0>
    800046a4:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800046a6:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800046aa:	5c7d                	li	s8,-1
    800046ac:	a82d                	j	800046e6 <readi+0x84>
    800046ae:	020d1d93          	slli	s11,s10,0x20
    800046b2:	020ddd93          	srli	s11,s11,0x20
    800046b6:	05890613          	addi	a2,s2,88
    800046ba:	86ee                	mv	a3,s11
    800046bc:	963a                	add	a2,a2,a4
    800046be:	85d2                	mv	a1,s4
    800046c0:	855e                	mv	a0,s7
    800046c2:	ffffe097          	auipc	ra,0xffffe
    800046c6:	344080e7          	jalr	836(ra) # 80002a06 <either_copyout>
    800046ca:	05850d63          	beq	a0,s8,80004724 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800046ce:	854a                	mv	a0,s2
    800046d0:	fffff097          	auipc	ra,0xfffff
    800046d4:	5f4080e7          	jalr	1524(ra) # 80003cc4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800046d8:	013d09bb          	addw	s3,s10,s3
    800046dc:	009d04bb          	addw	s1,s10,s1
    800046e0:	9a6e                	add	s4,s4,s11
    800046e2:	0559f763          	bgeu	s3,s5,80004730 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    800046e6:	00a4d59b          	srliw	a1,s1,0xa
    800046ea:	855a                	mv	a0,s6
    800046ec:	00000097          	auipc	ra,0x0
    800046f0:	8a2080e7          	jalr	-1886(ra) # 80003f8e <bmap>
    800046f4:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800046f8:	cd85                	beqz	a1,80004730 <readi+0xce>
    bp = bread(ip->dev, addr);
    800046fa:	000b2503          	lw	a0,0(s6)
    800046fe:	fffff097          	auipc	ra,0xfffff
    80004702:	496080e7          	jalr	1174(ra) # 80003b94 <bread>
    80004706:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004708:	3ff4f713          	andi	a4,s1,1023
    8000470c:	40ec87bb          	subw	a5,s9,a4
    80004710:	413a86bb          	subw	a3,s5,s3
    80004714:	8d3e                	mv	s10,a5
    80004716:	2781                	sext.w	a5,a5
    80004718:	0006861b          	sext.w	a2,a3
    8000471c:	f8f679e3          	bgeu	a2,a5,800046ae <readi+0x4c>
    80004720:	8d36                	mv	s10,a3
    80004722:	b771                	j	800046ae <readi+0x4c>
      brelse(bp);
    80004724:	854a                	mv	a0,s2
    80004726:	fffff097          	auipc	ra,0xfffff
    8000472a:	59e080e7          	jalr	1438(ra) # 80003cc4 <brelse>
      tot = -1;
    8000472e:	59fd                	li	s3,-1
  }
  return tot;
    80004730:	0009851b          	sext.w	a0,s3
}
    80004734:	70a6                	ld	ra,104(sp)
    80004736:	7406                	ld	s0,96(sp)
    80004738:	64e6                	ld	s1,88(sp)
    8000473a:	6946                	ld	s2,80(sp)
    8000473c:	69a6                	ld	s3,72(sp)
    8000473e:	6a06                	ld	s4,64(sp)
    80004740:	7ae2                	ld	s5,56(sp)
    80004742:	7b42                	ld	s6,48(sp)
    80004744:	7ba2                	ld	s7,40(sp)
    80004746:	7c02                	ld	s8,32(sp)
    80004748:	6ce2                	ld	s9,24(sp)
    8000474a:	6d42                	ld	s10,16(sp)
    8000474c:	6da2                	ld	s11,8(sp)
    8000474e:	6165                	addi	sp,sp,112
    80004750:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004752:	89d6                	mv	s3,s5
    80004754:	bff1                	j	80004730 <readi+0xce>
    return 0;
    80004756:	4501                	li	a0,0
}
    80004758:	8082                	ret

000000008000475a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000475a:	457c                	lw	a5,76(a0)
    8000475c:	10d7e863          	bltu	a5,a3,8000486c <writei+0x112>
{
    80004760:	7159                	addi	sp,sp,-112
    80004762:	f486                	sd	ra,104(sp)
    80004764:	f0a2                	sd	s0,96(sp)
    80004766:	eca6                	sd	s1,88(sp)
    80004768:	e8ca                	sd	s2,80(sp)
    8000476a:	e4ce                	sd	s3,72(sp)
    8000476c:	e0d2                	sd	s4,64(sp)
    8000476e:	fc56                	sd	s5,56(sp)
    80004770:	f85a                	sd	s6,48(sp)
    80004772:	f45e                	sd	s7,40(sp)
    80004774:	f062                	sd	s8,32(sp)
    80004776:	ec66                	sd	s9,24(sp)
    80004778:	e86a                	sd	s10,16(sp)
    8000477a:	e46e                	sd	s11,8(sp)
    8000477c:	1880                	addi	s0,sp,112
    8000477e:	8aaa                	mv	s5,a0
    80004780:	8bae                	mv	s7,a1
    80004782:	8a32                	mv	s4,a2
    80004784:	8936                	mv	s2,a3
    80004786:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004788:	00e687bb          	addw	a5,a3,a4
    8000478c:	0ed7e263          	bltu	a5,a3,80004870 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004790:	00043737          	lui	a4,0x43
    80004794:	0ef76063          	bltu	a4,a5,80004874 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004798:	0c0b0863          	beqz	s6,80004868 <writei+0x10e>
    8000479c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000479e:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800047a2:	5c7d                	li	s8,-1
    800047a4:	a091                	j	800047e8 <writei+0x8e>
    800047a6:	020d1d93          	slli	s11,s10,0x20
    800047aa:	020ddd93          	srli	s11,s11,0x20
    800047ae:	05848513          	addi	a0,s1,88
    800047b2:	86ee                	mv	a3,s11
    800047b4:	8652                	mv	a2,s4
    800047b6:	85de                	mv	a1,s7
    800047b8:	953a                	add	a0,a0,a4
    800047ba:	ffffe097          	auipc	ra,0xffffe
    800047be:	2a2080e7          	jalr	674(ra) # 80002a5c <either_copyin>
    800047c2:	07850263          	beq	a0,s8,80004826 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800047c6:	8526                	mv	a0,s1
    800047c8:	00000097          	auipc	ra,0x0
    800047cc:	780080e7          	jalr	1920(ra) # 80004f48 <log_write>
    brelse(bp);
    800047d0:	8526                	mv	a0,s1
    800047d2:	fffff097          	auipc	ra,0xfffff
    800047d6:	4f2080e7          	jalr	1266(ra) # 80003cc4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800047da:	013d09bb          	addw	s3,s10,s3
    800047de:	012d093b          	addw	s2,s10,s2
    800047e2:	9a6e                	add	s4,s4,s11
    800047e4:	0569f663          	bgeu	s3,s6,80004830 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    800047e8:	00a9559b          	srliw	a1,s2,0xa
    800047ec:	8556                	mv	a0,s5
    800047ee:	fffff097          	auipc	ra,0xfffff
    800047f2:	7a0080e7          	jalr	1952(ra) # 80003f8e <bmap>
    800047f6:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800047fa:	c99d                	beqz	a1,80004830 <writei+0xd6>
    bp = bread(ip->dev, addr);
    800047fc:	000aa503          	lw	a0,0(s5)
    80004800:	fffff097          	auipc	ra,0xfffff
    80004804:	394080e7          	jalr	916(ra) # 80003b94 <bread>
    80004808:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000480a:	3ff97713          	andi	a4,s2,1023
    8000480e:	40ec87bb          	subw	a5,s9,a4
    80004812:	413b06bb          	subw	a3,s6,s3
    80004816:	8d3e                	mv	s10,a5
    80004818:	2781                	sext.w	a5,a5
    8000481a:	0006861b          	sext.w	a2,a3
    8000481e:	f8f674e3          	bgeu	a2,a5,800047a6 <writei+0x4c>
    80004822:	8d36                	mv	s10,a3
    80004824:	b749                	j	800047a6 <writei+0x4c>
      brelse(bp);
    80004826:	8526                	mv	a0,s1
    80004828:	fffff097          	auipc	ra,0xfffff
    8000482c:	49c080e7          	jalr	1180(ra) # 80003cc4 <brelse>
  }

  if(off > ip->size)
    80004830:	04caa783          	lw	a5,76(s5)
    80004834:	0127f463          	bgeu	a5,s2,8000483c <writei+0xe2>
    ip->size = off;
    80004838:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000483c:	8556                	mv	a0,s5
    8000483e:	00000097          	auipc	ra,0x0
    80004842:	aa6080e7          	jalr	-1370(ra) # 800042e4 <iupdate>

  return tot;
    80004846:	0009851b          	sext.w	a0,s3
}
    8000484a:	70a6                	ld	ra,104(sp)
    8000484c:	7406                	ld	s0,96(sp)
    8000484e:	64e6                	ld	s1,88(sp)
    80004850:	6946                	ld	s2,80(sp)
    80004852:	69a6                	ld	s3,72(sp)
    80004854:	6a06                	ld	s4,64(sp)
    80004856:	7ae2                	ld	s5,56(sp)
    80004858:	7b42                	ld	s6,48(sp)
    8000485a:	7ba2                	ld	s7,40(sp)
    8000485c:	7c02                	ld	s8,32(sp)
    8000485e:	6ce2                	ld	s9,24(sp)
    80004860:	6d42                	ld	s10,16(sp)
    80004862:	6da2                	ld	s11,8(sp)
    80004864:	6165                	addi	sp,sp,112
    80004866:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004868:	89da                	mv	s3,s6
    8000486a:	bfc9                	j	8000483c <writei+0xe2>
    return -1;
    8000486c:	557d                	li	a0,-1
}
    8000486e:	8082                	ret
    return -1;
    80004870:	557d                	li	a0,-1
    80004872:	bfe1                	j	8000484a <writei+0xf0>
    return -1;
    80004874:	557d                	li	a0,-1
    80004876:	bfd1                	j	8000484a <writei+0xf0>

0000000080004878 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004878:	1141                	addi	sp,sp,-16
    8000487a:	e406                	sd	ra,8(sp)
    8000487c:	e022                	sd	s0,0(sp)
    8000487e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004880:	4639                	li	a2,14
    80004882:	ffffc097          	auipc	ra,0xffffc
    80004886:	53c080e7          	jalr	1340(ra) # 80000dbe <strncmp>
}
    8000488a:	60a2                	ld	ra,8(sp)
    8000488c:	6402                	ld	s0,0(sp)
    8000488e:	0141                	addi	sp,sp,16
    80004890:	8082                	ret

0000000080004892 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004892:	7139                	addi	sp,sp,-64
    80004894:	fc06                	sd	ra,56(sp)
    80004896:	f822                	sd	s0,48(sp)
    80004898:	f426                	sd	s1,40(sp)
    8000489a:	f04a                	sd	s2,32(sp)
    8000489c:	ec4e                	sd	s3,24(sp)
    8000489e:	e852                	sd	s4,16(sp)
    800048a0:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800048a2:	04451703          	lh	a4,68(a0)
    800048a6:	4785                	li	a5,1
    800048a8:	00f71a63          	bne	a4,a5,800048bc <dirlookup+0x2a>
    800048ac:	892a                	mv	s2,a0
    800048ae:	89ae                	mv	s3,a1
    800048b0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800048b2:	457c                	lw	a5,76(a0)
    800048b4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800048b6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800048b8:	e79d                	bnez	a5,800048e6 <dirlookup+0x54>
    800048ba:	a8a5                	j	80004932 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800048bc:	00005517          	auipc	a0,0x5
    800048c0:	f3c50513          	addi	a0,a0,-196 # 800097f8 <syscalls+0x1d0>
    800048c4:	ffffc097          	auipc	ra,0xffffc
    800048c8:	c80080e7          	jalr	-896(ra) # 80000544 <panic>
      panic("dirlookup read");
    800048cc:	00005517          	auipc	a0,0x5
    800048d0:	f4450513          	addi	a0,a0,-188 # 80009810 <syscalls+0x1e8>
    800048d4:	ffffc097          	auipc	ra,0xffffc
    800048d8:	c70080e7          	jalr	-912(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800048dc:	24c1                	addiw	s1,s1,16
    800048de:	04c92783          	lw	a5,76(s2)
    800048e2:	04f4f763          	bgeu	s1,a5,80004930 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800048e6:	4741                	li	a4,16
    800048e8:	86a6                	mv	a3,s1
    800048ea:	fc040613          	addi	a2,s0,-64
    800048ee:	4581                	li	a1,0
    800048f0:	854a                	mv	a0,s2
    800048f2:	00000097          	auipc	ra,0x0
    800048f6:	d70080e7          	jalr	-656(ra) # 80004662 <readi>
    800048fa:	47c1                	li	a5,16
    800048fc:	fcf518e3          	bne	a0,a5,800048cc <dirlookup+0x3a>
    if(de.inum == 0)
    80004900:	fc045783          	lhu	a5,-64(s0)
    80004904:	dfe1                	beqz	a5,800048dc <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004906:	fc240593          	addi	a1,s0,-62
    8000490a:	854e                	mv	a0,s3
    8000490c:	00000097          	auipc	ra,0x0
    80004910:	f6c080e7          	jalr	-148(ra) # 80004878 <namecmp>
    80004914:	f561                	bnez	a0,800048dc <dirlookup+0x4a>
      if(poff)
    80004916:	000a0463          	beqz	s4,8000491e <dirlookup+0x8c>
        *poff = off;
    8000491a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000491e:	fc045583          	lhu	a1,-64(s0)
    80004922:	00092503          	lw	a0,0(s2)
    80004926:	fffff097          	auipc	ra,0xfffff
    8000492a:	750080e7          	jalr	1872(ra) # 80004076 <iget>
    8000492e:	a011                	j	80004932 <dirlookup+0xa0>
  return 0;
    80004930:	4501                	li	a0,0
}
    80004932:	70e2                	ld	ra,56(sp)
    80004934:	7442                	ld	s0,48(sp)
    80004936:	74a2                	ld	s1,40(sp)
    80004938:	7902                	ld	s2,32(sp)
    8000493a:	69e2                	ld	s3,24(sp)
    8000493c:	6a42                	ld	s4,16(sp)
    8000493e:	6121                	addi	sp,sp,64
    80004940:	8082                	ret

0000000080004942 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004942:	711d                	addi	sp,sp,-96
    80004944:	ec86                	sd	ra,88(sp)
    80004946:	e8a2                	sd	s0,80(sp)
    80004948:	e4a6                	sd	s1,72(sp)
    8000494a:	e0ca                	sd	s2,64(sp)
    8000494c:	fc4e                	sd	s3,56(sp)
    8000494e:	f852                	sd	s4,48(sp)
    80004950:	f456                	sd	s5,40(sp)
    80004952:	f05a                	sd	s6,32(sp)
    80004954:	ec5e                	sd	s7,24(sp)
    80004956:	e862                	sd	s8,16(sp)
    80004958:	e466                	sd	s9,8(sp)
    8000495a:	1080                	addi	s0,sp,96
    8000495c:	84aa                	mv	s1,a0
    8000495e:	8b2e                	mv	s6,a1
    80004960:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004962:	00054703          	lbu	a4,0(a0)
    80004966:	02f00793          	li	a5,47
    8000496a:	02f70363          	beq	a4,a5,80004990 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000496e:	ffffd097          	auipc	ra,0xffffd
    80004972:	288080e7          	jalr	648(ra) # 80001bf6 <myproc>
    80004976:	15053503          	ld	a0,336(a0)
    8000497a:	00000097          	auipc	ra,0x0
    8000497e:	9f6080e7          	jalr	-1546(ra) # 80004370 <idup>
    80004982:	89aa                	mv	s3,a0
  while(*path == '/')
    80004984:	02f00913          	li	s2,47
  len = path - s;
    80004988:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    8000498a:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000498c:	4c05                	li	s8,1
    8000498e:	a865                	j	80004a46 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004990:	4585                	li	a1,1
    80004992:	4505                	li	a0,1
    80004994:	fffff097          	auipc	ra,0xfffff
    80004998:	6e2080e7          	jalr	1762(ra) # 80004076 <iget>
    8000499c:	89aa                	mv	s3,a0
    8000499e:	b7dd                	j	80004984 <namex+0x42>
      iunlockput(ip);
    800049a0:	854e                	mv	a0,s3
    800049a2:	00000097          	auipc	ra,0x0
    800049a6:	c6e080e7          	jalr	-914(ra) # 80004610 <iunlockput>
      return 0;
    800049aa:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800049ac:	854e                	mv	a0,s3
    800049ae:	60e6                	ld	ra,88(sp)
    800049b0:	6446                	ld	s0,80(sp)
    800049b2:	64a6                	ld	s1,72(sp)
    800049b4:	6906                	ld	s2,64(sp)
    800049b6:	79e2                	ld	s3,56(sp)
    800049b8:	7a42                	ld	s4,48(sp)
    800049ba:	7aa2                	ld	s5,40(sp)
    800049bc:	7b02                	ld	s6,32(sp)
    800049be:	6be2                	ld	s7,24(sp)
    800049c0:	6c42                	ld	s8,16(sp)
    800049c2:	6ca2                	ld	s9,8(sp)
    800049c4:	6125                	addi	sp,sp,96
    800049c6:	8082                	ret
      iunlock(ip);
    800049c8:	854e                	mv	a0,s3
    800049ca:	00000097          	auipc	ra,0x0
    800049ce:	aa6080e7          	jalr	-1370(ra) # 80004470 <iunlock>
      return ip;
    800049d2:	bfe9                	j	800049ac <namex+0x6a>
      iunlockput(ip);
    800049d4:	854e                	mv	a0,s3
    800049d6:	00000097          	auipc	ra,0x0
    800049da:	c3a080e7          	jalr	-966(ra) # 80004610 <iunlockput>
      return 0;
    800049de:	89d2                	mv	s3,s4
    800049e0:	b7f1                	j	800049ac <namex+0x6a>
  len = path - s;
    800049e2:	40b48633          	sub	a2,s1,a1
    800049e6:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800049ea:	094cd463          	bge	s9,s4,80004a72 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800049ee:	4639                	li	a2,14
    800049f0:	8556                	mv	a0,s5
    800049f2:	ffffc097          	auipc	ra,0xffffc
    800049f6:	354080e7          	jalr	852(ra) # 80000d46 <memmove>
  while(*path == '/')
    800049fa:	0004c783          	lbu	a5,0(s1)
    800049fe:	01279763          	bne	a5,s2,80004a0c <namex+0xca>
    path++;
    80004a02:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004a04:	0004c783          	lbu	a5,0(s1)
    80004a08:	ff278de3          	beq	a5,s2,80004a02 <namex+0xc0>
    ilock(ip);
    80004a0c:	854e                	mv	a0,s3
    80004a0e:	00000097          	auipc	ra,0x0
    80004a12:	9a0080e7          	jalr	-1632(ra) # 800043ae <ilock>
    if(ip->type != T_DIR){
    80004a16:	04499783          	lh	a5,68(s3)
    80004a1a:	f98793e3          	bne	a5,s8,800049a0 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004a1e:	000b0563          	beqz	s6,80004a28 <namex+0xe6>
    80004a22:	0004c783          	lbu	a5,0(s1)
    80004a26:	d3cd                	beqz	a5,800049c8 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004a28:	865e                	mv	a2,s7
    80004a2a:	85d6                	mv	a1,s5
    80004a2c:	854e                	mv	a0,s3
    80004a2e:	00000097          	auipc	ra,0x0
    80004a32:	e64080e7          	jalr	-412(ra) # 80004892 <dirlookup>
    80004a36:	8a2a                	mv	s4,a0
    80004a38:	dd51                	beqz	a0,800049d4 <namex+0x92>
    iunlockput(ip);
    80004a3a:	854e                	mv	a0,s3
    80004a3c:	00000097          	auipc	ra,0x0
    80004a40:	bd4080e7          	jalr	-1068(ra) # 80004610 <iunlockput>
    ip = next;
    80004a44:	89d2                	mv	s3,s4
  while(*path == '/')
    80004a46:	0004c783          	lbu	a5,0(s1)
    80004a4a:	05279763          	bne	a5,s2,80004a98 <namex+0x156>
    path++;
    80004a4e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004a50:	0004c783          	lbu	a5,0(s1)
    80004a54:	ff278de3          	beq	a5,s2,80004a4e <namex+0x10c>
  if(*path == 0)
    80004a58:	c79d                	beqz	a5,80004a86 <namex+0x144>
    path++;
    80004a5a:	85a6                	mv	a1,s1
  len = path - s;
    80004a5c:	8a5e                	mv	s4,s7
    80004a5e:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004a60:	01278963          	beq	a5,s2,80004a72 <namex+0x130>
    80004a64:	dfbd                	beqz	a5,800049e2 <namex+0xa0>
    path++;
    80004a66:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004a68:	0004c783          	lbu	a5,0(s1)
    80004a6c:	ff279ce3          	bne	a5,s2,80004a64 <namex+0x122>
    80004a70:	bf8d                	j	800049e2 <namex+0xa0>
    memmove(name, s, len);
    80004a72:	2601                	sext.w	a2,a2
    80004a74:	8556                	mv	a0,s5
    80004a76:	ffffc097          	auipc	ra,0xffffc
    80004a7a:	2d0080e7          	jalr	720(ra) # 80000d46 <memmove>
    name[len] = 0;
    80004a7e:	9a56                	add	s4,s4,s5
    80004a80:	000a0023          	sb	zero,0(s4)
    80004a84:	bf9d                	j	800049fa <namex+0xb8>
  if(nameiparent){
    80004a86:	f20b03e3          	beqz	s6,800049ac <namex+0x6a>
    iput(ip);
    80004a8a:	854e                	mv	a0,s3
    80004a8c:	00000097          	auipc	ra,0x0
    80004a90:	adc080e7          	jalr	-1316(ra) # 80004568 <iput>
    return 0;
    80004a94:	4981                	li	s3,0
    80004a96:	bf19                	j	800049ac <namex+0x6a>
  if(*path == 0)
    80004a98:	d7fd                	beqz	a5,80004a86 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004a9a:	0004c783          	lbu	a5,0(s1)
    80004a9e:	85a6                	mv	a1,s1
    80004aa0:	b7d1                	j	80004a64 <namex+0x122>

0000000080004aa2 <dirlink>:
{
    80004aa2:	7139                	addi	sp,sp,-64
    80004aa4:	fc06                	sd	ra,56(sp)
    80004aa6:	f822                	sd	s0,48(sp)
    80004aa8:	f426                	sd	s1,40(sp)
    80004aaa:	f04a                	sd	s2,32(sp)
    80004aac:	ec4e                	sd	s3,24(sp)
    80004aae:	e852                	sd	s4,16(sp)
    80004ab0:	0080                	addi	s0,sp,64
    80004ab2:	892a                	mv	s2,a0
    80004ab4:	8a2e                	mv	s4,a1
    80004ab6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004ab8:	4601                	li	a2,0
    80004aba:	00000097          	auipc	ra,0x0
    80004abe:	dd8080e7          	jalr	-552(ra) # 80004892 <dirlookup>
    80004ac2:	e93d                	bnez	a0,80004b38 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004ac4:	04c92483          	lw	s1,76(s2)
    80004ac8:	c49d                	beqz	s1,80004af6 <dirlink+0x54>
    80004aca:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004acc:	4741                	li	a4,16
    80004ace:	86a6                	mv	a3,s1
    80004ad0:	fc040613          	addi	a2,s0,-64
    80004ad4:	4581                	li	a1,0
    80004ad6:	854a                	mv	a0,s2
    80004ad8:	00000097          	auipc	ra,0x0
    80004adc:	b8a080e7          	jalr	-1142(ra) # 80004662 <readi>
    80004ae0:	47c1                	li	a5,16
    80004ae2:	06f51163          	bne	a0,a5,80004b44 <dirlink+0xa2>
    if(de.inum == 0)
    80004ae6:	fc045783          	lhu	a5,-64(s0)
    80004aea:	c791                	beqz	a5,80004af6 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004aec:	24c1                	addiw	s1,s1,16
    80004aee:	04c92783          	lw	a5,76(s2)
    80004af2:	fcf4ede3          	bltu	s1,a5,80004acc <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004af6:	4639                	li	a2,14
    80004af8:	85d2                	mv	a1,s4
    80004afa:	fc240513          	addi	a0,s0,-62
    80004afe:	ffffc097          	auipc	ra,0xffffc
    80004b02:	2fc080e7          	jalr	764(ra) # 80000dfa <strncpy>
  de.inum = inum;
    80004b06:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004b0a:	4741                	li	a4,16
    80004b0c:	86a6                	mv	a3,s1
    80004b0e:	fc040613          	addi	a2,s0,-64
    80004b12:	4581                	li	a1,0
    80004b14:	854a                	mv	a0,s2
    80004b16:	00000097          	auipc	ra,0x0
    80004b1a:	c44080e7          	jalr	-956(ra) # 8000475a <writei>
    80004b1e:	1541                	addi	a0,a0,-16
    80004b20:	00a03533          	snez	a0,a0
    80004b24:	40a00533          	neg	a0,a0
}
    80004b28:	70e2                	ld	ra,56(sp)
    80004b2a:	7442                	ld	s0,48(sp)
    80004b2c:	74a2                	ld	s1,40(sp)
    80004b2e:	7902                	ld	s2,32(sp)
    80004b30:	69e2                	ld	s3,24(sp)
    80004b32:	6a42                	ld	s4,16(sp)
    80004b34:	6121                	addi	sp,sp,64
    80004b36:	8082                	ret
    iput(ip);
    80004b38:	00000097          	auipc	ra,0x0
    80004b3c:	a30080e7          	jalr	-1488(ra) # 80004568 <iput>
    return -1;
    80004b40:	557d                	li	a0,-1
    80004b42:	b7dd                	j	80004b28 <dirlink+0x86>
      panic("dirlink read");
    80004b44:	00005517          	auipc	a0,0x5
    80004b48:	cdc50513          	addi	a0,a0,-804 # 80009820 <syscalls+0x1f8>
    80004b4c:	ffffc097          	auipc	ra,0xffffc
    80004b50:	9f8080e7          	jalr	-1544(ra) # 80000544 <panic>

0000000080004b54 <namei>:

struct inode*
namei(char *path)
{
    80004b54:	1101                	addi	sp,sp,-32
    80004b56:	ec06                	sd	ra,24(sp)
    80004b58:	e822                	sd	s0,16(sp)
    80004b5a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004b5c:	fe040613          	addi	a2,s0,-32
    80004b60:	4581                	li	a1,0
    80004b62:	00000097          	auipc	ra,0x0
    80004b66:	de0080e7          	jalr	-544(ra) # 80004942 <namex>
}
    80004b6a:	60e2                	ld	ra,24(sp)
    80004b6c:	6442                	ld	s0,16(sp)
    80004b6e:	6105                	addi	sp,sp,32
    80004b70:	8082                	ret

0000000080004b72 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004b72:	1141                	addi	sp,sp,-16
    80004b74:	e406                	sd	ra,8(sp)
    80004b76:	e022                	sd	s0,0(sp)
    80004b78:	0800                	addi	s0,sp,16
    80004b7a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004b7c:	4585                	li	a1,1
    80004b7e:	00000097          	auipc	ra,0x0
    80004b82:	dc4080e7          	jalr	-572(ra) # 80004942 <namex>
}
    80004b86:	60a2                	ld	ra,8(sp)
    80004b88:	6402                	ld	s0,0(sp)
    80004b8a:	0141                	addi	sp,sp,16
    80004b8c:	8082                	ret

0000000080004b8e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004b8e:	1101                	addi	sp,sp,-32
    80004b90:	ec06                	sd	ra,24(sp)
    80004b92:	e822                	sd	s0,16(sp)
    80004b94:	e426                	sd	s1,8(sp)
    80004b96:	e04a                	sd	s2,0(sp)
    80004b98:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004b9a:	0001f917          	auipc	s2,0x1f
    80004b9e:	4fe90913          	addi	s2,s2,1278 # 80024098 <log>
    80004ba2:	01892583          	lw	a1,24(s2)
    80004ba6:	02892503          	lw	a0,40(s2)
    80004baa:	fffff097          	auipc	ra,0xfffff
    80004bae:	fea080e7          	jalr	-22(ra) # 80003b94 <bread>
    80004bb2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004bb4:	02c92683          	lw	a3,44(s2)
    80004bb8:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004bba:	02d05763          	blez	a3,80004be8 <write_head+0x5a>
    80004bbe:	0001f797          	auipc	a5,0x1f
    80004bc2:	50a78793          	addi	a5,a5,1290 # 800240c8 <log+0x30>
    80004bc6:	05c50713          	addi	a4,a0,92
    80004bca:	36fd                	addiw	a3,a3,-1
    80004bcc:	1682                	slli	a3,a3,0x20
    80004bce:	9281                	srli	a3,a3,0x20
    80004bd0:	068a                	slli	a3,a3,0x2
    80004bd2:	0001f617          	auipc	a2,0x1f
    80004bd6:	4fa60613          	addi	a2,a2,1274 # 800240cc <log+0x34>
    80004bda:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004bdc:	4390                	lw	a2,0(a5)
    80004bde:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004be0:	0791                	addi	a5,a5,4
    80004be2:	0711                	addi	a4,a4,4
    80004be4:	fed79ce3          	bne	a5,a3,80004bdc <write_head+0x4e>
  }
  bwrite(buf);
    80004be8:	8526                	mv	a0,s1
    80004bea:	fffff097          	auipc	ra,0xfffff
    80004bee:	09c080e7          	jalr	156(ra) # 80003c86 <bwrite>
  brelse(buf);
    80004bf2:	8526                	mv	a0,s1
    80004bf4:	fffff097          	auipc	ra,0xfffff
    80004bf8:	0d0080e7          	jalr	208(ra) # 80003cc4 <brelse>
}
    80004bfc:	60e2                	ld	ra,24(sp)
    80004bfe:	6442                	ld	s0,16(sp)
    80004c00:	64a2                	ld	s1,8(sp)
    80004c02:	6902                	ld	s2,0(sp)
    80004c04:	6105                	addi	sp,sp,32
    80004c06:	8082                	ret

0000000080004c08 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004c08:	0001f797          	auipc	a5,0x1f
    80004c0c:	4bc7a783          	lw	a5,1212(a5) # 800240c4 <log+0x2c>
    80004c10:	0af05d63          	blez	a5,80004cca <install_trans+0xc2>
{
    80004c14:	7139                	addi	sp,sp,-64
    80004c16:	fc06                	sd	ra,56(sp)
    80004c18:	f822                	sd	s0,48(sp)
    80004c1a:	f426                	sd	s1,40(sp)
    80004c1c:	f04a                	sd	s2,32(sp)
    80004c1e:	ec4e                	sd	s3,24(sp)
    80004c20:	e852                	sd	s4,16(sp)
    80004c22:	e456                	sd	s5,8(sp)
    80004c24:	e05a                	sd	s6,0(sp)
    80004c26:	0080                	addi	s0,sp,64
    80004c28:	8b2a                	mv	s6,a0
    80004c2a:	0001fa97          	auipc	s5,0x1f
    80004c2e:	49ea8a93          	addi	s5,s5,1182 # 800240c8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004c32:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004c34:	0001f997          	auipc	s3,0x1f
    80004c38:	46498993          	addi	s3,s3,1124 # 80024098 <log>
    80004c3c:	a035                	j	80004c68 <install_trans+0x60>
      bunpin(dbuf);
    80004c3e:	8526                	mv	a0,s1
    80004c40:	fffff097          	auipc	ra,0xfffff
    80004c44:	15e080e7          	jalr	350(ra) # 80003d9e <bunpin>
    brelse(lbuf);
    80004c48:	854a                	mv	a0,s2
    80004c4a:	fffff097          	auipc	ra,0xfffff
    80004c4e:	07a080e7          	jalr	122(ra) # 80003cc4 <brelse>
    brelse(dbuf);
    80004c52:	8526                	mv	a0,s1
    80004c54:	fffff097          	auipc	ra,0xfffff
    80004c58:	070080e7          	jalr	112(ra) # 80003cc4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004c5c:	2a05                	addiw	s4,s4,1
    80004c5e:	0a91                	addi	s5,s5,4
    80004c60:	02c9a783          	lw	a5,44(s3)
    80004c64:	04fa5963          	bge	s4,a5,80004cb6 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004c68:	0189a583          	lw	a1,24(s3)
    80004c6c:	014585bb          	addw	a1,a1,s4
    80004c70:	2585                	addiw	a1,a1,1
    80004c72:	0289a503          	lw	a0,40(s3)
    80004c76:	fffff097          	auipc	ra,0xfffff
    80004c7a:	f1e080e7          	jalr	-226(ra) # 80003b94 <bread>
    80004c7e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004c80:	000aa583          	lw	a1,0(s5)
    80004c84:	0289a503          	lw	a0,40(s3)
    80004c88:	fffff097          	auipc	ra,0xfffff
    80004c8c:	f0c080e7          	jalr	-244(ra) # 80003b94 <bread>
    80004c90:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004c92:	40000613          	li	a2,1024
    80004c96:	05890593          	addi	a1,s2,88
    80004c9a:	05850513          	addi	a0,a0,88
    80004c9e:	ffffc097          	auipc	ra,0xffffc
    80004ca2:	0a8080e7          	jalr	168(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004ca6:	8526                	mv	a0,s1
    80004ca8:	fffff097          	auipc	ra,0xfffff
    80004cac:	fde080e7          	jalr	-34(ra) # 80003c86 <bwrite>
    if(recovering == 0)
    80004cb0:	f80b1ce3          	bnez	s6,80004c48 <install_trans+0x40>
    80004cb4:	b769                	j	80004c3e <install_trans+0x36>
}
    80004cb6:	70e2                	ld	ra,56(sp)
    80004cb8:	7442                	ld	s0,48(sp)
    80004cba:	74a2                	ld	s1,40(sp)
    80004cbc:	7902                	ld	s2,32(sp)
    80004cbe:	69e2                	ld	s3,24(sp)
    80004cc0:	6a42                	ld	s4,16(sp)
    80004cc2:	6aa2                	ld	s5,8(sp)
    80004cc4:	6b02                	ld	s6,0(sp)
    80004cc6:	6121                	addi	sp,sp,64
    80004cc8:	8082                	ret
    80004cca:	8082                	ret

0000000080004ccc <initlog>:
{
    80004ccc:	7179                	addi	sp,sp,-48
    80004cce:	f406                	sd	ra,40(sp)
    80004cd0:	f022                	sd	s0,32(sp)
    80004cd2:	ec26                	sd	s1,24(sp)
    80004cd4:	e84a                	sd	s2,16(sp)
    80004cd6:	e44e                	sd	s3,8(sp)
    80004cd8:	1800                	addi	s0,sp,48
    80004cda:	892a                	mv	s2,a0
    80004cdc:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004cde:	0001f497          	auipc	s1,0x1f
    80004ce2:	3ba48493          	addi	s1,s1,954 # 80024098 <log>
    80004ce6:	00005597          	auipc	a1,0x5
    80004cea:	b4a58593          	addi	a1,a1,-1206 # 80009830 <syscalls+0x208>
    80004cee:	8526                	mv	a0,s1
    80004cf0:	ffffc097          	auipc	ra,0xffffc
    80004cf4:	e6a080e7          	jalr	-406(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    80004cf8:	0149a583          	lw	a1,20(s3)
    80004cfc:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004cfe:	0109a783          	lw	a5,16(s3)
    80004d02:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004d04:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004d08:	854a                	mv	a0,s2
    80004d0a:	fffff097          	auipc	ra,0xfffff
    80004d0e:	e8a080e7          	jalr	-374(ra) # 80003b94 <bread>
  log.lh.n = lh->n;
    80004d12:	4d3c                	lw	a5,88(a0)
    80004d14:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004d16:	02f05563          	blez	a5,80004d40 <initlog+0x74>
    80004d1a:	05c50713          	addi	a4,a0,92
    80004d1e:	0001f697          	auipc	a3,0x1f
    80004d22:	3aa68693          	addi	a3,a3,938 # 800240c8 <log+0x30>
    80004d26:	37fd                	addiw	a5,a5,-1
    80004d28:	1782                	slli	a5,a5,0x20
    80004d2a:	9381                	srli	a5,a5,0x20
    80004d2c:	078a                	slli	a5,a5,0x2
    80004d2e:	06050613          	addi	a2,a0,96
    80004d32:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004d34:	4310                	lw	a2,0(a4)
    80004d36:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004d38:	0711                	addi	a4,a4,4
    80004d3a:	0691                	addi	a3,a3,4
    80004d3c:	fef71ce3          	bne	a4,a5,80004d34 <initlog+0x68>
  brelse(buf);
    80004d40:	fffff097          	auipc	ra,0xfffff
    80004d44:	f84080e7          	jalr	-124(ra) # 80003cc4 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004d48:	4505                	li	a0,1
    80004d4a:	00000097          	auipc	ra,0x0
    80004d4e:	ebe080e7          	jalr	-322(ra) # 80004c08 <install_trans>
  log.lh.n = 0;
    80004d52:	0001f797          	auipc	a5,0x1f
    80004d56:	3607a923          	sw	zero,882(a5) # 800240c4 <log+0x2c>
  write_head(); // clear the log
    80004d5a:	00000097          	auipc	ra,0x0
    80004d5e:	e34080e7          	jalr	-460(ra) # 80004b8e <write_head>
}
    80004d62:	70a2                	ld	ra,40(sp)
    80004d64:	7402                	ld	s0,32(sp)
    80004d66:	64e2                	ld	s1,24(sp)
    80004d68:	6942                	ld	s2,16(sp)
    80004d6a:	69a2                	ld	s3,8(sp)
    80004d6c:	6145                	addi	sp,sp,48
    80004d6e:	8082                	ret

0000000080004d70 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004d70:	1101                	addi	sp,sp,-32
    80004d72:	ec06                	sd	ra,24(sp)
    80004d74:	e822                	sd	s0,16(sp)
    80004d76:	e426                	sd	s1,8(sp)
    80004d78:	e04a                	sd	s2,0(sp)
    80004d7a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004d7c:	0001f517          	auipc	a0,0x1f
    80004d80:	31c50513          	addi	a0,a0,796 # 80024098 <log>
    80004d84:	ffffc097          	auipc	ra,0xffffc
    80004d88:	e66080e7          	jalr	-410(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    80004d8c:	0001f497          	auipc	s1,0x1f
    80004d90:	30c48493          	addi	s1,s1,780 # 80024098 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004d94:	4979                	li	s2,30
    80004d96:	a039                	j	80004da4 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004d98:	85a6                	mv	a1,s1
    80004d9a:	8526                	mv	a0,s1
    80004d9c:	ffffd097          	auipc	ra,0xffffd
    80004da0:	70a080e7          	jalr	1802(ra) # 800024a6 <sleep>
    if(log.committing){
    80004da4:	50dc                	lw	a5,36(s1)
    80004da6:	fbed                	bnez	a5,80004d98 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004da8:	509c                	lw	a5,32(s1)
    80004daa:	0017871b          	addiw	a4,a5,1
    80004dae:	0007069b          	sext.w	a3,a4
    80004db2:	0027179b          	slliw	a5,a4,0x2
    80004db6:	9fb9                	addw	a5,a5,a4
    80004db8:	0017979b          	slliw	a5,a5,0x1
    80004dbc:	54d8                	lw	a4,44(s1)
    80004dbe:	9fb9                	addw	a5,a5,a4
    80004dc0:	00f95963          	bge	s2,a5,80004dd2 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004dc4:	85a6                	mv	a1,s1
    80004dc6:	8526                	mv	a0,s1
    80004dc8:	ffffd097          	auipc	ra,0xffffd
    80004dcc:	6de080e7          	jalr	1758(ra) # 800024a6 <sleep>
    80004dd0:	bfd1                	j	80004da4 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004dd2:	0001f517          	auipc	a0,0x1f
    80004dd6:	2c650513          	addi	a0,a0,710 # 80024098 <log>
    80004dda:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004ddc:	ffffc097          	auipc	ra,0xffffc
    80004de0:	ec2080e7          	jalr	-318(ra) # 80000c9e <release>
      break;
    }
  }
}
    80004de4:	60e2                	ld	ra,24(sp)
    80004de6:	6442                	ld	s0,16(sp)
    80004de8:	64a2                	ld	s1,8(sp)
    80004dea:	6902                	ld	s2,0(sp)
    80004dec:	6105                	addi	sp,sp,32
    80004dee:	8082                	ret

0000000080004df0 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004df0:	7139                	addi	sp,sp,-64
    80004df2:	fc06                	sd	ra,56(sp)
    80004df4:	f822                	sd	s0,48(sp)
    80004df6:	f426                	sd	s1,40(sp)
    80004df8:	f04a                	sd	s2,32(sp)
    80004dfa:	ec4e                	sd	s3,24(sp)
    80004dfc:	e852                	sd	s4,16(sp)
    80004dfe:	e456                	sd	s5,8(sp)
    80004e00:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004e02:	0001f497          	auipc	s1,0x1f
    80004e06:	29648493          	addi	s1,s1,662 # 80024098 <log>
    80004e0a:	8526                	mv	a0,s1
    80004e0c:	ffffc097          	auipc	ra,0xffffc
    80004e10:	dde080e7          	jalr	-546(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    80004e14:	509c                	lw	a5,32(s1)
    80004e16:	37fd                	addiw	a5,a5,-1
    80004e18:	0007891b          	sext.w	s2,a5
    80004e1c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004e1e:	50dc                	lw	a5,36(s1)
    80004e20:	efb9                	bnez	a5,80004e7e <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004e22:	06091663          	bnez	s2,80004e8e <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004e26:	0001f497          	auipc	s1,0x1f
    80004e2a:	27248493          	addi	s1,s1,626 # 80024098 <log>
    80004e2e:	4785                	li	a5,1
    80004e30:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004e32:	8526                	mv	a0,s1
    80004e34:	ffffc097          	auipc	ra,0xffffc
    80004e38:	e6a080e7          	jalr	-406(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004e3c:	54dc                	lw	a5,44(s1)
    80004e3e:	06f04763          	bgtz	a5,80004eac <end_op+0xbc>
    acquire(&log.lock);
    80004e42:	0001f497          	auipc	s1,0x1f
    80004e46:	25648493          	addi	s1,s1,598 # 80024098 <log>
    80004e4a:	8526                	mv	a0,s1
    80004e4c:	ffffc097          	auipc	ra,0xffffc
    80004e50:	d9e080e7          	jalr	-610(ra) # 80000bea <acquire>
    log.committing = 0;
    80004e54:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004e58:	8526                	mv	a0,s1
    80004e5a:	ffffd097          	auipc	ra,0xffffd
    80004e5e:	7fc080e7          	jalr	2044(ra) # 80002656 <wakeup>
    release(&log.lock);
    80004e62:	8526                	mv	a0,s1
    80004e64:	ffffc097          	auipc	ra,0xffffc
    80004e68:	e3a080e7          	jalr	-454(ra) # 80000c9e <release>
}
    80004e6c:	70e2                	ld	ra,56(sp)
    80004e6e:	7442                	ld	s0,48(sp)
    80004e70:	74a2                	ld	s1,40(sp)
    80004e72:	7902                	ld	s2,32(sp)
    80004e74:	69e2                	ld	s3,24(sp)
    80004e76:	6a42                	ld	s4,16(sp)
    80004e78:	6aa2                	ld	s5,8(sp)
    80004e7a:	6121                	addi	sp,sp,64
    80004e7c:	8082                	ret
    panic("log.committing");
    80004e7e:	00005517          	auipc	a0,0x5
    80004e82:	9ba50513          	addi	a0,a0,-1606 # 80009838 <syscalls+0x210>
    80004e86:	ffffb097          	auipc	ra,0xffffb
    80004e8a:	6be080e7          	jalr	1726(ra) # 80000544 <panic>
    wakeup(&log);
    80004e8e:	0001f497          	auipc	s1,0x1f
    80004e92:	20a48493          	addi	s1,s1,522 # 80024098 <log>
    80004e96:	8526                	mv	a0,s1
    80004e98:	ffffd097          	auipc	ra,0xffffd
    80004e9c:	7be080e7          	jalr	1982(ra) # 80002656 <wakeup>
  release(&log.lock);
    80004ea0:	8526                	mv	a0,s1
    80004ea2:	ffffc097          	auipc	ra,0xffffc
    80004ea6:	dfc080e7          	jalr	-516(ra) # 80000c9e <release>
  if(do_commit){
    80004eaa:	b7c9                	j	80004e6c <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004eac:	0001fa97          	auipc	s5,0x1f
    80004eb0:	21ca8a93          	addi	s5,s5,540 # 800240c8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004eb4:	0001fa17          	auipc	s4,0x1f
    80004eb8:	1e4a0a13          	addi	s4,s4,484 # 80024098 <log>
    80004ebc:	018a2583          	lw	a1,24(s4)
    80004ec0:	012585bb          	addw	a1,a1,s2
    80004ec4:	2585                	addiw	a1,a1,1
    80004ec6:	028a2503          	lw	a0,40(s4)
    80004eca:	fffff097          	auipc	ra,0xfffff
    80004ece:	cca080e7          	jalr	-822(ra) # 80003b94 <bread>
    80004ed2:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004ed4:	000aa583          	lw	a1,0(s5)
    80004ed8:	028a2503          	lw	a0,40(s4)
    80004edc:	fffff097          	auipc	ra,0xfffff
    80004ee0:	cb8080e7          	jalr	-840(ra) # 80003b94 <bread>
    80004ee4:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004ee6:	40000613          	li	a2,1024
    80004eea:	05850593          	addi	a1,a0,88
    80004eee:	05848513          	addi	a0,s1,88
    80004ef2:	ffffc097          	auipc	ra,0xffffc
    80004ef6:	e54080e7          	jalr	-428(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    80004efa:	8526                	mv	a0,s1
    80004efc:	fffff097          	auipc	ra,0xfffff
    80004f00:	d8a080e7          	jalr	-630(ra) # 80003c86 <bwrite>
    brelse(from);
    80004f04:	854e                	mv	a0,s3
    80004f06:	fffff097          	auipc	ra,0xfffff
    80004f0a:	dbe080e7          	jalr	-578(ra) # 80003cc4 <brelse>
    brelse(to);
    80004f0e:	8526                	mv	a0,s1
    80004f10:	fffff097          	auipc	ra,0xfffff
    80004f14:	db4080e7          	jalr	-588(ra) # 80003cc4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004f18:	2905                	addiw	s2,s2,1
    80004f1a:	0a91                	addi	s5,s5,4
    80004f1c:	02ca2783          	lw	a5,44(s4)
    80004f20:	f8f94ee3          	blt	s2,a5,80004ebc <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004f24:	00000097          	auipc	ra,0x0
    80004f28:	c6a080e7          	jalr	-918(ra) # 80004b8e <write_head>
    install_trans(0); // Now install writes to home locations
    80004f2c:	4501                	li	a0,0
    80004f2e:	00000097          	auipc	ra,0x0
    80004f32:	cda080e7          	jalr	-806(ra) # 80004c08 <install_trans>
    log.lh.n = 0;
    80004f36:	0001f797          	auipc	a5,0x1f
    80004f3a:	1807a723          	sw	zero,398(a5) # 800240c4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004f3e:	00000097          	auipc	ra,0x0
    80004f42:	c50080e7          	jalr	-944(ra) # 80004b8e <write_head>
    80004f46:	bdf5                	j	80004e42 <end_op+0x52>

0000000080004f48 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004f48:	1101                	addi	sp,sp,-32
    80004f4a:	ec06                	sd	ra,24(sp)
    80004f4c:	e822                	sd	s0,16(sp)
    80004f4e:	e426                	sd	s1,8(sp)
    80004f50:	e04a                	sd	s2,0(sp)
    80004f52:	1000                	addi	s0,sp,32
    80004f54:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004f56:	0001f917          	auipc	s2,0x1f
    80004f5a:	14290913          	addi	s2,s2,322 # 80024098 <log>
    80004f5e:	854a                	mv	a0,s2
    80004f60:	ffffc097          	auipc	ra,0xffffc
    80004f64:	c8a080e7          	jalr	-886(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004f68:	02c92603          	lw	a2,44(s2)
    80004f6c:	47f5                	li	a5,29
    80004f6e:	06c7c563          	blt	a5,a2,80004fd8 <log_write+0x90>
    80004f72:	0001f797          	auipc	a5,0x1f
    80004f76:	1427a783          	lw	a5,322(a5) # 800240b4 <log+0x1c>
    80004f7a:	37fd                	addiw	a5,a5,-1
    80004f7c:	04f65e63          	bge	a2,a5,80004fd8 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004f80:	0001f797          	auipc	a5,0x1f
    80004f84:	1387a783          	lw	a5,312(a5) # 800240b8 <log+0x20>
    80004f88:	06f05063          	blez	a5,80004fe8 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004f8c:	4781                	li	a5,0
    80004f8e:	06c05563          	blez	a2,80004ff8 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004f92:	44cc                	lw	a1,12(s1)
    80004f94:	0001f717          	auipc	a4,0x1f
    80004f98:	13470713          	addi	a4,a4,308 # 800240c8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004f9c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004f9e:	4314                	lw	a3,0(a4)
    80004fa0:	04b68c63          	beq	a3,a1,80004ff8 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004fa4:	2785                	addiw	a5,a5,1
    80004fa6:	0711                	addi	a4,a4,4
    80004fa8:	fef61be3          	bne	a2,a5,80004f9e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004fac:	0621                	addi	a2,a2,8
    80004fae:	060a                	slli	a2,a2,0x2
    80004fb0:	0001f797          	auipc	a5,0x1f
    80004fb4:	0e878793          	addi	a5,a5,232 # 80024098 <log>
    80004fb8:	963e                	add	a2,a2,a5
    80004fba:	44dc                	lw	a5,12(s1)
    80004fbc:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004fbe:	8526                	mv	a0,s1
    80004fc0:	fffff097          	auipc	ra,0xfffff
    80004fc4:	da2080e7          	jalr	-606(ra) # 80003d62 <bpin>
    log.lh.n++;
    80004fc8:	0001f717          	auipc	a4,0x1f
    80004fcc:	0d070713          	addi	a4,a4,208 # 80024098 <log>
    80004fd0:	575c                	lw	a5,44(a4)
    80004fd2:	2785                	addiw	a5,a5,1
    80004fd4:	d75c                	sw	a5,44(a4)
    80004fd6:	a835                	j	80005012 <log_write+0xca>
    panic("too big a transaction");
    80004fd8:	00005517          	auipc	a0,0x5
    80004fdc:	87050513          	addi	a0,a0,-1936 # 80009848 <syscalls+0x220>
    80004fe0:	ffffb097          	auipc	ra,0xffffb
    80004fe4:	564080e7          	jalr	1380(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    80004fe8:	00005517          	auipc	a0,0x5
    80004fec:	87850513          	addi	a0,a0,-1928 # 80009860 <syscalls+0x238>
    80004ff0:	ffffb097          	auipc	ra,0xffffb
    80004ff4:	554080e7          	jalr	1364(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    80004ff8:	00878713          	addi	a4,a5,8
    80004ffc:	00271693          	slli	a3,a4,0x2
    80005000:	0001f717          	auipc	a4,0x1f
    80005004:	09870713          	addi	a4,a4,152 # 80024098 <log>
    80005008:	9736                	add	a4,a4,a3
    8000500a:	44d4                	lw	a3,12(s1)
    8000500c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000500e:	faf608e3          	beq	a2,a5,80004fbe <log_write+0x76>
  }
  release(&log.lock);
    80005012:	0001f517          	auipc	a0,0x1f
    80005016:	08650513          	addi	a0,a0,134 # 80024098 <log>
    8000501a:	ffffc097          	auipc	ra,0xffffc
    8000501e:	c84080e7          	jalr	-892(ra) # 80000c9e <release>
}
    80005022:	60e2                	ld	ra,24(sp)
    80005024:	6442                	ld	s0,16(sp)
    80005026:	64a2                	ld	s1,8(sp)
    80005028:	6902                	ld	s2,0(sp)
    8000502a:	6105                	addi	sp,sp,32
    8000502c:	8082                	ret

000000008000502e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000502e:	1101                	addi	sp,sp,-32
    80005030:	ec06                	sd	ra,24(sp)
    80005032:	e822                	sd	s0,16(sp)
    80005034:	e426                	sd	s1,8(sp)
    80005036:	e04a                	sd	s2,0(sp)
    80005038:	1000                	addi	s0,sp,32
    8000503a:	84aa                	mv	s1,a0
    8000503c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000503e:	00005597          	auipc	a1,0x5
    80005042:	84258593          	addi	a1,a1,-1982 # 80009880 <syscalls+0x258>
    80005046:	0521                	addi	a0,a0,8
    80005048:	ffffc097          	auipc	ra,0xffffc
    8000504c:	b12080e7          	jalr	-1262(ra) # 80000b5a <initlock>
  lk->name = name;
    80005050:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80005054:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80005058:	0204a423          	sw	zero,40(s1)
}
    8000505c:	60e2                	ld	ra,24(sp)
    8000505e:	6442                	ld	s0,16(sp)
    80005060:	64a2                	ld	s1,8(sp)
    80005062:	6902                	ld	s2,0(sp)
    80005064:	6105                	addi	sp,sp,32
    80005066:	8082                	ret

0000000080005068 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80005068:	1101                	addi	sp,sp,-32
    8000506a:	ec06                	sd	ra,24(sp)
    8000506c:	e822                	sd	s0,16(sp)
    8000506e:	e426                	sd	s1,8(sp)
    80005070:	e04a                	sd	s2,0(sp)
    80005072:	1000                	addi	s0,sp,32
    80005074:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80005076:	00850913          	addi	s2,a0,8
    8000507a:	854a                	mv	a0,s2
    8000507c:	ffffc097          	auipc	ra,0xffffc
    80005080:	b6e080e7          	jalr	-1170(ra) # 80000bea <acquire>
  while (lk->locked) {
    80005084:	409c                	lw	a5,0(s1)
    80005086:	cb89                	beqz	a5,80005098 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80005088:	85ca                	mv	a1,s2
    8000508a:	8526                	mv	a0,s1
    8000508c:	ffffd097          	auipc	ra,0xffffd
    80005090:	41a080e7          	jalr	1050(ra) # 800024a6 <sleep>
  while (lk->locked) {
    80005094:	409c                	lw	a5,0(s1)
    80005096:	fbed                	bnez	a5,80005088 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80005098:	4785                	li	a5,1
    8000509a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000509c:	ffffd097          	auipc	ra,0xffffd
    800050a0:	b5a080e7          	jalr	-1190(ra) # 80001bf6 <myproc>
    800050a4:	591c                	lw	a5,48(a0)
    800050a6:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800050a8:	854a                	mv	a0,s2
    800050aa:	ffffc097          	auipc	ra,0xffffc
    800050ae:	bf4080e7          	jalr	-1036(ra) # 80000c9e <release>
}
    800050b2:	60e2                	ld	ra,24(sp)
    800050b4:	6442                	ld	s0,16(sp)
    800050b6:	64a2                	ld	s1,8(sp)
    800050b8:	6902                	ld	s2,0(sp)
    800050ba:	6105                	addi	sp,sp,32
    800050bc:	8082                	ret

00000000800050be <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800050be:	1101                	addi	sp,sp,-32
    800050c0:	ec06                	sd	ra,24(sp)
    800050c2:	e822                	sd	s0,16(sp)
    800050c4:	e426                	sd	s1,8(sp)
    800050c6:	e04a                	sd	s2,0(sp)
    800050c8:	1000                	addi	s0,sp,32
    800050ca:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800050cc:	00850913          	addi	s2,a0,8
    800050d0:	854a                	mv	a0,s2
    800050d2:	ffffc097          	auipc	ra,0xffffc
    800050d6:	b18080e7          	jalr	-1256(ra) # 80000bea <acquire>
  lk->locked = 0;
    800050da:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800050de:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800050e2:	8526                	mv	a0,s1
    800050e4:	ffffd097          	auipc	ra,0xffffd
    800050e8:	572080e7          	jalr	1394(ra) # 80002656 <wakeup>
  release(&lk->lk);
    800050ec:	854a                	mv	a0,s2
    800050ee:	ffffc097          	auipc	ra,0xffffc
    800050f2:	bb0080e7          	jalr	-1104(ra) # 80000c9e <release>
}
    800050f6:	60e2                	ld	ra,24(sp)
    800050f8:	6442                	ld	s0,16(sp)
    800050fa:	64a2                	ld	s1,8(sp)
    800050fc:	6902                	ld	s2,0(sp)
    800050fe:	6105                	addi	sp,sp,32
    80005100:	8082                	ret

0000000080005102 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80005102:	7179                	addi	sp,sp,-48
    80005104:	f406                	sd	ra,40(sp)
    80005106:	f022                	sd	s0,32(sp)
    80005108:	ec26                	sd	s1,24(sp)
    8000510a:	e84a                	sd	s2,16(sp)
    8000510c:	e44e                	sd	s3,8(sp)
    8000510e:	1800                	addi	s0,sp,48
    80005110:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80005112:	00850913          	addi	s2,a0,8
    80005116:	854a                	mv	a0,s2
    80005118:	ffffc097          	auipc	ra,0xffffc
    8000511c:	ad2080e7          	jalr	-1326(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80005120:	409c                	lw	a5,0(s1)
    80005122:	ef99                	bnez	a5,80005140 <holdingsleep+0x3e>
    80005124:	4481                	li	s1,0
  release(&lk->lk);
    80005126:	854a                	mv	a0,s2
    80005128:	ffffc097          	auipc	ra,0xffffc
    8000512c:	b76080e7          	jalr	-1162(ra) # 80000c9e <release>
  return r;
}
    80005130:	8526                	mv	a0,s1
    80005132:	70a2                	ld	ra,40(sp)
    80005134:	7402                	ld	s0,32(sp)
    80005136:	64e2                	ld	s1,24(sp)
    80005138:	6942                	ld	s2,16(sp)
    8000513a:	69a2                	ld	s3,8(sp)
    8000513c:	6145                	addi	sp,sp,48
    8000513e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80005140:	0284a983          	lw	s3,40(s1)
    80005144:	ffffd097          	auipc	ra,0xffffd
    80005148:	ab2080e7          	jalr	-1358(ra) # 80001bf6 <myproc>
    8000514c:	5904                	lw	s1,48(a0)
    8000514e:	413484b3          	sub	s1,s1,s3
    80005152:	0014b493          	seqz	s1,s1
    80005156:	bfc1                	j	80005126 <holdingsleep+0x24>

0000000080005158 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80005158:	1141                	addi	sp,sp,-16
    8000515a:	e406                	sd	ra,8(sp)
    8000515c:	e022                	sd	s0,0(sp)
    8000515e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80005160:	00004597          	auipc	a1,0x4
    80005164:	73058593          	addi	a1,a1,1840 # 80009890 <syscalls+0x268>
    80005168:	0001f517          	auipc	a0,0x1f
    8000516c:	07850513          	addi	a0,a0,120 # 800241e0 <ftable>
    80005170:	ffffc097          	auipc	ra,0xffffc
    80005174:	9ea080e7          	jalr	-1558(ra) # 80000b5a <initlock>
}
    80005178:	60a2                	ld	ra,8(sp)
    8000517a:	6402                	ld	s0,0(sp)
    8000517c:	0141                	addi	sp,sp,16
    8000517e:	8082                	ret

0000000080005180 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80005180:	1101                	addi	sp,sp,-32
    80005182:	ec06                	sd	ra,24(sp)
    80005184:	e822                	sd	s0,16(sp)
    80005186:	e426                	sd	s1,8(sp)
    80005188:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000518a:	0001f517          	auipc	a0,0x1f
    8000518e:	05650513          	addi	a0,a0,86 # 800241e0 <ftable>
    80005192:	ffffc097          	auipc	ra,0xffffc
    80005196:	a58080e7          	jalr	-1448(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000519a:	0001f497          	auipc	s1,0x1f
    8000519e:	05e48493          	addi	s1,s1,94 # 800241f8 <ftable+0x18>
    800051a2:	00020717          	auipc	a4,0x20
    800051a6:	ff670713          	addi	a4,a4,-10 # 80025198 <disk>
    if(f->ref == 0){
    800051aa:	40dc                	lw	a5,4(s1)
    800051ac:	cf99                	beqz	a5,800051ca <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800051ae:	02848493          	addi	s1,s1,40
    800051b2:	fee49ce3          	bne	s1,a4,800051aa <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800051b6:	0001f517          	auipc	a0,0x1f
    800051ba:	02a50513          	addi	a0,a0,42 # 800241e0 <ftable>
    800051be:	ffffc097          	auipc	ra,0xffffc
    800051c2:	ae0080e7          	jalr	-1312(ra) # 80000c9e <release>
  return 0;
    800051c6:	4481                	li	s1,0
    800051c8:	a819                	j	800051de <filealloc+0x5e>
      f->ref = 1;
    800051ca:	4785                	li	a5,1
    800051cc:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800051ce:	0001f517          	auipc	a0,0x1f
    800051d2:	01250513          	addi	a0,a0,18 # 800241e0 <ftable>
    800051d6:	ffffc097          	auipc	ra,0xffffc
    800051da:	ac8080e7          	jalr	-1336(ra) # 80000c9e <release>
}
    800051de:	8526                	mv	a0,s1
    800051e0:	60e2                	ld	ra,24(sp)
    800051e2:	6442                	ld	s0,16(sp)
    800051e4:	64a2                	ld	s1,8(sp)
    800051e6:	6105                	addi	sp,sp,32
    800051e8:	8082                	ret

00000000800051ea <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800051ea:	1101                	addi	sp,sp,-32
    800051ec:	ec06                	sd	ra,24(sp)
    800051ee:	e822                	sd	s0,16(sp)
    800051f0:	e426                	sd	s1,8(sp)
    800051f2:	1000                	addi	s0,sp,32
    800051f4:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800051f6:	0001f517          	auipc	a0,0x1f
    800051fa:	fea50513          	addi	a0,a0,-22 # 800241e0 <ftable>
    800051fe:	ffffc097          	auipc	ra,0xffffc
    80005202:	9ec080e7          	jalr	-1556(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80005206:	40dc                	lw	a5,4(s1)
    80005208:	02f05263          	blez	a5,8000522c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000520c:	2785                	addiw	a5,a5,1
    8000520e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80005210:	0001f517          	auipc	a0,0x1f
    80005214:	fd050513          	addi	a0,a0,-48 # 800241e0 <ftable>
    80005218:	ffffc097          	auipc	ra,0xffffc
    8000521c:	a86080e7          	jalr	-1402(ra) # 80000c9e <release>
  return f;
}
    80005220:	8526                	mv	a0,s1
    80005222:	60e2                	ld	ra,24(sp)
    80005224:	6442                	ld	s0,16(sp)
    80005226:	64a2                	ld	s1,8(sp)
    80005228:	6105                	addi	sp,sp,32
    8000522a:	8082                	ret
    panic("filedup");
    8000522c:	00004517          	auipc	a0,0x4
    80005230:	66c50513          	addi	a0,a0,1644 # 80009898 <syscalls+0x270>
    80005234:	ffffb097          	auipc	ra,0xffffb
    80005238:	310080e7          	jalr	784(ra) # 80000544 <panic>

000000008000523c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000523c:	7139                	addi	sp,sp,-64
    8000523e:	fc06                	sd	ra,56(sp)
    80005240:	f822                	sd	s0,48(sp)
    80005242:	f426                	sd	s1,40(sp)
    80005244:	f04a                	sd	s2,32(sp)
    80005246:	ec4e                	sd	s3,24(sp)
    80005248:	e852                	sd	s4,16(sp)
    8000524a:	e456                	sd	s5,8(sp)
    8000524c:	0080                	addi	s0,sp,64
    8000524e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80005250:	0001f517          	auipc	a0,0x1f
    80005254:	f9050513          	addi	a0,a0,-112 # 800241e0 <ftable>
    80005258:	ffffc097          	auipc	ra,0xffffc
    8000525c:	992080e7          	jalr	-1646(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80005260:	40dc                	lw	a5,4(s1)
    80005262:	06f05163          	blez	a5,800052c4 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80005266:	37fd                	addiw	a5,a5,-1
    80005268:	0007871b          	sext.w	a4,a5
    8000526c:	c0dc                	sw	a5,4(s1)
    8000526e:	06e04363          	bgtz	a4,800052d4 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80005272:	0004a903          	lw	s2,0(s1)
    80005276:	0094ca83          	lbu	s5,9(s1)
    8000527a:	0104ba03          	ld	s4,16(s1)
    8000527e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80005282:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80005286:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000528a:	0001f517          	auipc	a0,0x1f
    8000528e:	f5650513          	addi	a0,a0,-170 # 800241e0 <ftable>
    80005292:	ffffc097          	auipc	ra,0xffffc
    80005296:	a0c080e7          	jalr	-1524(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    8000529a:	4785                	li	a5,1
    8000529c:	04f90d63          	beq	s2,a5,800052f6 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800052a0:	3979                	addiw	s2,s2,-2
    800052a2:	4785                	li	a5,1
    800052a4:	0527e063          	bltu	a5,s2,800052e4 <fileclose+0xa8>
    begin_op();
    800052a8:	00000097          	auipc	ra,0x0
    800052ac:	ac8080e7          	jalr	-1336(ra) # 80004d70 <begin_op>
    iput(ff.ip);
    800052b0:	854e                	mv	a0,s3
    800052b2:	fffff097          	auipc	ra,0xfffff
    800052b6:	2b6080e7          	jalr	694(ra) # 80004568 <iput>
    end_op();
    800052ba:	00000097          	auipc	ra,0x0
    800052be:	b36080e7          	jalr	-1226(ra) # 80004df0 <end_op>
    800052c2:	a00d                	j	800052e4 <fileclose+0xa8>
    panic("fileclose");
    800052c4:	00004517          	auipc	a0,0x4
    800052c8:	5dc50513          	addi	a0,a0,1500 # 800098a0 <syscalls+0x278>
    800052cc:	ffffb097          	auipc	ra,0xffffb
    800052d0:	278080e7          	jalr	632(ra) # 80000544 <panic>
    release(&ftable.lock);
    800052d4:	0001f517          	auipc	a0,0x1f
    800052d8:	f0c50513          	addi	a0,a0,-244 # 800241e0 <ftable>
    800052dc:	ffffc097          	auipc	ra,0xffffc
    800052e0:	9c2080e7          	jalr	-1598(ra) # 80000c9e <release>
  }
}
    800052e4:	70e2                	ld	ra,56(sp)
    800052e6:	7442                	ld	s0,48(sp)
    800052e8:	74a2                	ld	s1,40(sp)
    800052ea:	7902                	ld	s2,32(sp)
    800052ec:	69e2                	ld	s3,24(sp)
    800052ee:	6a42                	ld	s4,16(sp)
    800052f0:	6aa2                	ld	s5,8(sp)
    800052f2:	6121                	addi	sp,sp,64
    800052f4:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800052f6:	85d6                	mv	a1,s5
    800052f8:	8552                	mv	a0,s4
    800052fa:	00000097          	auipc	ra,0x0
    800052fe:	34c080e7          	jalr	844(ra) # 80005646 <pipeclose>
    80005302:	b7cd                	j	800052e4 <fileclose+0xa8>

0000000080005304 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80005304:	715d                	addi	sp,sp,-80
    80005306:	e486                	sd	ra,72(sp)
    80005308:	e0a2                	sd	s0,64(sp)
    8000530a:	fc26                	sd	s1,56(sp)
    8000530c:	f84a                	sd	s2,48(sp)
    8000530e:	f44e                	sd	s3,40(sp)
    80005310:	0880                	addi	s0,sp,80
    80005312:	84aa                	mv	s1,a0
    80005314:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80005316:	ffffd097          	auipc	ra,0xffffd
    8000531a:	8e0080e7          	jalr	-1824(ra) # 80001bf6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000531e:	409c                	lw	a5,0(s1)
    80005320:	37f9                	addiw	a5,a5,-2
    80005322:	4705                	li	a4,1
    80005324:	04f76763          	bltu	a4,a5,80005372 <filestat+0x6e>
    80005328:	892a                	mv	s2,a0
    ilock(f->ip);
    8000532a:	6c88                	ld	a0,24(s1)
    8000532c:	fffff097          	auipc	ra,0xfffff
    80005330:	082080e7          	jalr	130(ra) # 800043ae <ilock>
    stati(f->ip, &st);
    80005334:	fb840593          	addi	a1,s0,-72
    80005338:	6c88                	ld	a0,24(s1)
    8000533a:	fffff097          	auipc	ra,0xfffff
    8000533e:	2fe080e7          	jalr	766(ra) # 80004638 <stati>
    iunlock(f->ip);
    80005342:	6c88                	ld	a0,24(s1)
    80005344:	fffff097          	auipc	ra,0xfffff
    80005348:	12c080e7          	jalr	300(ra) # 80004470 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000534c:	46e1                	li	a3,24
    8000534e:	fb840613          	addi	a2,s0,-72
    80005352:	85ce                	mv	a1,s3
    80005354:	05093503          	ld	a0,80(s2)
    80005358:	ffffc097          	auipc	ra,0xffffc
    8000535c:	32c080e7          	jalr	812(ra) # 80001684 <copyout>
    80005360:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80005364:	60a6                	ld	ra,72(sp)
    80005366:	6406                	ld	s0,64(sp)
    80005368:	74e2                	ld	s1,56(sp)
    8000536a:	7942                	ld	s2,48(sp)
    8000536c:	79a2                	ld	s3,40(sp)
    8000536e:	6161                	addi	sp,sp,80
    80005370:	8082                	ret
  return -1;
    80005372:	557d                	li	a0,-1
    80005374:	bfc5                	j	80005364 <filestat+0x60>

0000000080005376 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80005376:	7179                	addi	sp,sp,-48
    80005378:	f406                	sd	ra,40(sp)
    8000537a:	f022                	sd	s0,32(sp)
    8000537c:	ec26                	sd	s1,24(sp)
    8000537e:	e84a                	sd	s2,16(sp)
    80005380:	e44e                	sd	s3,8(sp)
    80005382:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005384:	00854783          	lbu	a5,8(a0)
    80005388:	c3d5                	beqz	a5,8000542c <fileread+0xb6>
    8000538a:	84aa                	mv	s1,a0
    8000538c:	89ae                	mv	s3,a1
    8000538e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80005390:	411c                	lw	a5,0(a0)
    80005392:	4705                	li	a4,1
    80005394:	04e78963          	beq	a5,a4,800053e6 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005398:	470d                	li	a4,3
    8000539a:	04e78d63          	beq	a5,a4,800053f4 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000539e:	4709                	li	a4,2
    800053a0:	06e79e63          	bne	a5,a4,8000541c <fileread+0xa6>
    ilock(f->ip);
    800053a4:	6d08                	ld	a0,24(a0)
    800053a6:	fffff097          	auipc	ra,0xfffff
    800053aa:	008080e7          	jalr	8(ra) # 800043ae <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800053ae:	874a                	mv	a4,s2
    800053b0:	5094                	lw	a3,32(s1)
    800053b2:	864e                	mv	a2,s3
    800053b4:	4585                	li	a1,1
    800053b6:	6c88                	ld	a0,24(s1)
    800053b8:	fffff097          	auipc	ra,0xfffff
    800053bc:	2aa080e7          	jalr	682(ra) # 80004662 <readi>
    800053c0:	892a                	mv	s2,a0
    800053c2:	00a05563          	blez	a0,800053cc <fileread+0x56>
      f->off += r;
    800053c6:	509c                	lw	a5,32(s1)
    800053c8:	9fa9                	addw	a5,a5,a0
    800053ca:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800053cc:	6c88                	ld	a0,24(s1)
    800053ce:	fffff097          	auipc	ra,0xfffff
    800053d2:	0a2080e7          	jalr	162(ra) # 80004470 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800053d6:	854a                	mv	a0,s2
    800053d8:	70a2                	ld	ra,40(sp)
    800053da:	7402                	ld	s0,32(sp)
    800053dc:	64e2                	ld	s1,24(sp)
    800053de:	6942                	ld	s2,16(sp)
    800053e0:	69a2                	ld	s3,8(sp)
    800053e2:	6145                	addi	sp,sp,48
    800053e4:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800053e6:	6908                	ld	a0,16(a0)
    800053e8:	00000097          	auipc	ra,0x0
    800053ec:	3ce080e7          	jalr	974(ra) # 800057b6 <piperead>
    800053f0:	892a                	mv	s2,a0
    800053f2:	b7d5                	j	800053d6 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800053f4:	02451783          	lh	a5,36(a0)
    800053f8:	03079693          	slli	a3,a5,0x30
    800053fc:	92c1                	srli	a3,a3,0x30
    800053fe:	4725                	li	a4,9
    80005400:	02d76863          	bltu	a4,a3,80005430 <fileread+0xba>
    80005404:	0792                	slli	a5,a5,0x4
    80005406:	0001f717          	auipc	a4,0x1f
    8000540a:	d3a70713          	addi	a4,a4,-710 # 80024140 <devsw>
    8000540e:	97ba                	add	a5,a5,a4
    80005410:	639c                	ld	a5,0(a5)
    80005412:	c38d                	beqz	a5,80005434 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005414:	4505                	li	a0,1
    80005416:	9782                	jalr	a5
    80005418:	892a                	mv	s2,a0
    8000541a:	bf75                	j	800053d6 <fileread+0x60>
    panic("fileread");
    8000541c:	00004517          	auipc	a0,0x4
    80005420:	49450513          	addi	a0,a0,1172 # 800098b0 <syscalls+0x288>
    80005424:	ffffb097          	auipc	ra,0xffffb
    80005428:	120080e7          	jalr	288(ra) # 80000544 <panic>
    return -1;
    8000542c:	597d                	li	s2,-1
    8000542e:	b765                	j	800053d6 <fileread+0x60>
      return -1;
    80005430:	597d                	li	s2,-1
    80005432:	b755                	j	800053d6 <fileread+0x60>
    80005434:	597d                	li	s2,-1
    80005436:	b745                	j	800053d6 <fileread+0x60>

0000000080005438 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80005438:	715d                	addi	sp,sp,-80
    8000543a:	e486                	sd	ra,72(sp)
    8000543c:	e0a2                	sd	s0,64(sp)
    8000543e:	fc26                	sd	s1,56(sp)
    80005440:	f84a                	sd	s2,48(sp)
    80005442:	f44e                	sd	s3,40(sp)
    80005444:	f052                	sd	s4,32(sp)
    80005446:	ec56                	sd	s5,24(sp)
    80005448:	e85a                	sd	s6,16(sp)
    8000544a:	e45e                	sd	s7,8(sp)
    8000544c:	e062                	sd	s8,0(sp)
    8000544e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005450:	00954783          	lbu	a5,9(a0)
    80005454:	10078663          	beqz	a5,80005560 <filewrite+0x128>
    80005458:	892a                	mv	s2,a0
    8000545a:	8aae                	mv	s5,a1
    8000545c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000545e:	411c                	lw	a5,0(a0)
    80005460:	4705                	li	a4,1
    80005462:	02e78263          	beq	a5,a4,80005486 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005466:	470d                	li	a4,3
    80005468:	02e78663          	beq	a5,a4,80005494 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000546c:	4709                	li	a4,2
    8000546e:	0ee79163          	bne	a5,a4,80005550 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005472:	0ac05d63          	blez	a2,8000552c <filewrite+0xf4>
    int i = 0;
    80005476:	4981                	li	s3,0
    80005478:	6b05                	lui	s6,0x1
    8000547a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000547e:	6b85                	lui	s7,0x1
    80005480:	c00b8b9b          	addiw	s7,s7,-1024
    80005484:	a861                	j	8000551c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005486:	6908                	ld	a0,16(a0)
    80005488:	00000097          	auipc	ra,0x0
    8000548c:	22e080e7          	jalr	558(ra) # 800056b6 <pipewrite>
    80005490:	8a2a                	mv	s4,a0
    80005492:	a045                	j	80005532 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005494:	02451783          	lh	a5,36(a0)
    80005498:	03079693          	slli	a3,a5,0x30
    8000549c:	92c1                	srli	a3,a3,0x30
    8000549e:	4725                	li	a4,9
    800054a0:	0cd76263          	bltu	a4,a3,80005564 <filewrite+0x12c>
    800054a4:	0792                	slli	a5,a5,0x4
    800054a6:	0001f717          	auipc	a4,0x1f
    800054aa:	c9a70713          	addi	a4,a4,-870 # 80024140 <devsw>
    800054ae:	97ba                	add	a5,a5,a4
    800054b0:	679c                	ld	a5,8(a5)
    800054b2:	cbdd                	beqz	a5,80005568 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800054b4:	4505                	li	a0,1
    800054b6:	9782                	jalr	a5
    800054b8:	8a2a                	mv	s4,a0
    800054ba:	a8a5                	j	80005532 <filewrite+0xfa>
    800054bc:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800054c0:	00000097          	auipc	ra,0x0
    800054c4:	8b0080e7          	jalr	-1872(ra) # 80004d70 <begin_op>
      ilock(f->ip);
    800054c8:	01893503          	ld	a0,24(s2)
    800054cc:	fffff097          	auipc	ra,0xfffff
    800054d0:	ee2080e7          	jalr	-286(ra) # 800043ae <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800054d4:	8762                	mv	a4,s8
    800054d6:	02092683          	lw	a3,32(s2)
    800054da:	01598633          	add	a2,s3,s5
    800054de:	4585                	li	a1,1
    800054e0:	01893503          	ld	a0,24(s2)
    800054e4:	fffff097          	auipc	ra,0xfffff
    800054e8:	276080e7          	jalr	630(ra) # 8000475a <writei>
    800054ec:	84aa                	mv	s1,a0
    800054ee:	00a05763          	blez	a0,800054fc <filewrite+0xc4>
        f->off += r;
    800054f2:	02092783          	lw	a5,32(s2)
    800054f6:	9fa9                	addw	a5,a5,a0
    800054f8:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800054fc:	01893503          	ld	a0,24(s2)
    80005500:	fffff097          	auipc	ra,0xfffff
    80005504:	f70080e7          	jalr	-144(ra) # 80004470 <iunlock>
      end_op();
    80005508:	00000097          	auipc	ra,0x0
    8000550c:	8e8080e7          	jalr	-1816(ra) # 80004df0 <end_op>

      if(r != n1){
    80005510:	009c1f63          	bne	s8,s1,8000552e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005514:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005518:	0149db63          	bge	s3,s4,8000552e <filewrite+0xf6>
      int n1 = n - i;
    8000551c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005520:	84be                	mv	s1,a5
    80005522:	2781                	sext.w	a5,a5
    80005524:	f8fb5ce3          	bge	s6,a5,800054bc <filewrite+0x84>
    80005528:	84de                	mv	s1,s7
    8000552a:	bf49                	j	800054bc <filewrite+0x84>
    int i = 0;
    8000552c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000552e:	013a1f63          	bne	s4,s3,8000554c <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005532:	8552                	mv	a0,s4
    80005534:	60a6                	ld	ra,72(sp)
    80005536:	6406                	ld	s0,64(sp)
    80005538:	74e2                	ld	s1,56(sp)
    8000553a:	7942                	ld	s2,48(sp)
    8000553c:	79a2                	ld	s3,40(sp)
    8000553e:	7a02                	ld	s4,32(sp)
    80005540:	6ae2                	ld	s5,24(sp)
    80005542:	6b42                	ld	s6,16(sp)
    80005544:	6ba2                	ld	s7,8(sp)
    80005546:	6c02                	ld	s8,0(sp)
    80005548:	6161                	addi	sp,sp,80
    8000554a:	8082                	ret
    ret = (i == n ? n : -1);
    8000554c:	5a7d                	li	s4,-1
    8000554e:	b7d5                	j	80005532 <filewrite+0xfa>
    panic("filewrite");
    80005550:	00004517          	auipc	a0,0x4
    80005554:	37050513          	addi	a0,a0,880 # 800098c0 <syscalls+0x298>
    80005558:	ffffb097          	auipc	ra,0xffffb
    8000555c:	fec080e7          	jalr	-20(ra) # 80000544 <panic>
    return -1;
    80005560:	5a7d                	li	s4,-1
    80005562:	bfc1                	j	80005532 <filewrite+0xfa>
      return -1;
    80005564:	5a7d                	li	s4,-1
    80005566:	b7f1                	j	80005532 <filewrite+0xfa>
    80005568:	5a7d                	li	s4,-1
    8000556a:	b7e1                	j	80005532 <filewrite+0xfa>

000000008000556c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000556c:	7179                	addi	sp,sp,-48
    8000556e:	f406                	sd	ra,40(sp)
    80005570:	f022                	sd	s0,32(sp)
    80005572:	ec26                	sd	s1,24(sp)
    80005574:	e84a                	sd	s2,16(sp)
    80005576:	e44e                	sd	s3,8(sp)
    80005578:	e052                	sd	s4,0(sp)
    8000557a:	1800                	addi	s0,sp,48
    8000557c:	84aa                	mv	s1,a0
    8000557e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005580:	0005b023          	sd	zero,0(a1)
    80005584:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005588:	00000097          	auipc	ra,0x0
    8000558c:	bf8080e7          	jalr	-1032(ra) # 80005180 <filealloc>
    80005590:	e088                	sd	a0,0(s1)
    80005592:	c551                	beqz	a0,8000561e <pipealloc+0xb2>
    80005594:	00000097          	auipc	ra,0x0
    80005598:	bec080e7          	jalr	-1044(ra) # 80005180 <filealloc>
    8000559c:	00aa3023          	sd	a0,0(s4)
    800055a0:	c92d                	beqz	a0,80005612 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800055a2:	ffffb097          	auipc	ra,0xffffb
    800055a6:	558080e7          	jalr	1368(ra) # 80000afa <kalloc>
    800055aa:	892a                	mv	s2,a0
    800055ac:	c125                	beqz	a0,8000560c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800055ae:	4985                	li	s3,1
    800055b0:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800055b4:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800055b8:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800055bc:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800055c0:	00004597          	auipc	a1,0x4
    800055c4:	f7058593          	addi	a1,a1,-144 # 80009530 <states.1811+0x218>
    800055c8:	ffffb097          	auipc	ra,0xffffb
    800055cc:	592080e7          	jalr	1426(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    800055d0:	609c                	ld	a5,0(s1)
    800055d2:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800055d6:	609c                	ld	a5,0(s1)
    800055d8:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800055dc:	609c                	ld	a5,0(s1)
    800055de:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800055e2:	609c                	ld	a5,0(s1)
    800055e4:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800055e8:	000a3783          	ld	a5,0(s4)
    800055ec:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800055f0:	000a3783          	ld	a5,0(s4)
    800055f4:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800055f8:	000a3783          	ld	a5,0(s4)
    800055fc:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005600:	000a3783          	ld	a5,0(s4)
    80005604:	0127b823          	sd	s2,16(a5)
  return 0;
    80005608:	4501                	li	a0,0
    8000560a:	a025                	j	80005632 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000560c:	6088                	ld	a0,0(s1)
    8000560e:	e501                	bnez	a0,80005616 <pipealloc+0xaa>
    80005610:	a039                	j	8000561e <pipealloc+0xb2>
    80005612:	6088                	ld	a0,0(s1)
    80005614:	c51d                	beqz	a0,80005642 <pipealloc+0xd6>
    fileclose(*f0);
    80005616:	00000097          	auipc	ra,0x0
    8000561a:	c26080e7          	jalr	-986(ra) # 8000523c <fileclose>
  if(*f1)
    8000561e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005622:	557d                	li	a0,-1
  if(*f1)
    80005624:	c799                	beqz	a5,80005632 <pipealloc+0xc6>
    fileclose(*f1);
    80005626:	853e                	mv	a0,a5
    80005628:	00000097          	auipc	ra,0x0
    8000562c:	c14080e7          	jalr	-1004(ra) # 8000523c <fileclose>
  return -1;
    80005630:	557d                	li	a0,-1
}
    80005632:	70a2                	ld	ra,40(sp)
    80005634:	7402                	ld	s0,32(sp)
    80005636:	64e2                	ld	s1,24(sp)
    80005638:	6942                	ld	s2,16(sp)
    8000563a:	69a2                	ld	s3,8(sp)
    8000563c:	6a02                	ld	s4,0(sp)
    8000563e:	6145                	addi	sp,sp,48
    80005640:	8082                	ret
  return -1;
    80005642:	557d                	li	a0,-1
    80005644:	b7fd                	j	80005632 <pipealloc+0xc6>

0000000080005646 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005646:	1101                	addi	sp,sp,-32
    80005648:	ec06                	sd	ra,24(sp)
    8000564a:	e822                	sd	s0,16(sp)
    8000564c:	e426                	sd	s1,8(sp)
    8000564e:	e04a                	sd	s2,0(sp)
    80005650:	1000                	addi	s0,sp,32
    80005652:	84aa                	mv	s1,a0
    80005654:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005656:	ffffb097          	auipc	ra,0xffffb
    8000565a:	594080e7          	jalr	1428(ra) # 80000bea <acquire>
  if(writable){
    8000565e:	02090d63          	beqz	s2,80005698 <pipeclose+0x52>
    pi->writeopen = 0;
    80005662:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005666:	21848513          	addi	a0,s1,536
    8000566a:	ffffd097          	auipc	ra,0xffffd
    8000566e:	fec080e7          	jalr	-20(ra) # 80002656 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005672:	2204b783          	ld	a5,544(s1)
    80005676:	eb95                	bnez	a5,800056aa <pipeclose+0x64>
    release(&pi->lock);
    80005678:	8526                	mv	a0,s1
    8000567a:	ffffb097          	auipc	ra,0xffffb
    8000567e:	624080e7          	jalr	1572(ra) # 80000c9e <release>
    kfree((char*)pi);
    80005682:	8526                	mv	a0,s1
    80005684:	ffffb097          	auipc	ra,0xffffb
    80005688:	37a080e7          	jalr	890(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    8000568c:	60e2                	ld	ra,24(sp)
    8000568e:	6442                	ld	s0,16(sp)
    80005690:	64a2                	ld	s1,8(sp)
    80005692:	6902                	ld	s2,0(sp)
    80005694:	6105                	addi	sp,sp,32
    80005696:	8082                	ret
    pi->readopen = 0;
    80005698:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000569c:	21c48513          	addi	a0,s1,540
    800056a0:	ffffd097          	auipc	ra,0xffffd
    800056a4:	fb6080e7          	jalr	-74(ra) # 80002656 <wakeup>
    800056a8:	b7e9                	j	80005672 <pipeclose+0x2c>
    release(&pi->lock);
    800056aa:	8526                	mv	a0,s1
    800056ac:	ffffb097          	auipc	ra,0xffffb
    800056b0:	5f2080e7          	jalr	1522(ra) # 80000c9e <release>
}
    800056b4:	bfe1                	j	8000568c <pipeclose+0x46>

00000000800056b6 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800056b6:	7159                	addi	sp,sp,-112
    800056b8:	f486                	sd	ra,104(sp)
    800056ba:	f0a2                	sd	s0,96(sp)
    800056bc:	eca6                	sd	s1,88(sp)
    800056be:	e8ca                	sd	s2,80(sp)
    800056c0:	e4ce                	sd	s3,72(sp)
    800056c2:	e0d2                	sd	s4,64(sp)
    800056c4:	fc56                	sd	s5,56(sp)
    800056c6:	f85a                	sd	s6,48(sp)
    800056c8:	f45e                	sd	s7,40(sp)
    800056ca:	f062                	sd	s8,32(sp)
    800056cc:	ec66                	sd	s9,24(sp)
    800056ce:	1880                	addi	s0,sp,112
    800056d0:	84aa                	mv	s1,a0
    800056d2:	8aae                	mv	s5,a1
    800056d4:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800056d6:	ffffc097          	auipc	ra,0xffffc
    800056da:	520080e7          	jalr	1312(ra) # 80001bf6 <myproc>
    800056de:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800056e0:	8526                	mv	a0,s1
    800056e2:	ffffb097          	auipc	ra,0xffffb
    800056e6:	508080e7          	jalr	1288(ra) # 80000bea <acquire>
  while(i < n){
    800056ea:	0d405463          	blez	s4,800057b2 <pipewrite+0xfc>
    800056ee:	8ba6                	mv	s7,s1
  int i = 0;
    800056f0:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800056f2:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800056f4:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800056f8:	21c48c13          	addi	s8,s1,540
    800056fc:	a08d                	j	8000575e <pipewrite+0xa8>
      release(&pi->lock);
    800056fe:	8526                	mv	a0,s1
    80005700:	ffffb097          	auipc	ra,0xffffb
    80005704:	59e080e7          	jalr	1438(ra) # 80000c9e <release>
      return -1;
    80005708:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000570a:	854a                	mv	a0,s2
    8000570c:	70a6                	ld	ra,104(sp)
    8000570e:	7406                	ld	s0,96(sp)
    80005710:	64e6                	ld	s1,88(sp)
    80005712:	6946                	ld	s2,80(sp)
    80005714:	69a6                	ld	s3,72(sp)
    80005716:	6a06                	ld	s4,64(sp)
    80005718:	7ae2                	ld	s5,56(sp)
    8000571a:	7b42                	ld	s6,48(sp)
    8000571c:	7ba2                	ld	s7,40(sp)
    8000571e:	7c02                	ld	s8,32(sp)
    80005720:	6ce2                	ld	s9,24(sp)
    80005722:	6165                	addi	sp,sp,112
    80005724:	8082                	ret
      wakeup(&pi->nread);
    80005726:	8566                	mv	a0,s9
    80005728:	ffffd097          	auipc	ra,0xffffd
    8000572c:	f2e080e7          	jalr	-210(ra) # 80002656 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005730:	85de                	mv	a1,s7
    80005732:	8562                	mv	a0,s8
    80005734:	ffffd097          	auipc	ra,0xffffd
    80005738:	d72080e7          	jalr	-654(ra) # 800024a6 <sleep>
    8000573c:	a839                	j	8000575a <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000573e:	21c4a783          	lw	a5,540(s1)
    80005742:	0017871b          	addiw	a4,a5,1
    80005746:	20e4ae23          	sw	a4,540(s1)
    8000574a:	1ff7f793          	andi	a5,a5,511
    8000574e:	97a6                	add	a5,a5,s1
    80005750:	f9f44703          	lbu	a4,-97(s0)
    80005754:	00e78c23          	sb	a4,24(a5)
      i++;
    80005758:	2905                	addiw	s2,s2,1
  while(i < n){
    8000575a:	05495063          	bge	s2,s4,8000579a <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    8000575e:	2204a783          	lw	a5,544(s1)
    80005762:	dfd1                	beqz	a5,800056fe <pipewrite+0x48>
    80005764:	854e                	mv	a0,s3
    80005766:	ffffd097          	auipc	ra,0xffffd
    8000576a:	140080e7          	jalr	320(ra) # 800028a6 <killed>
    8000576e:	f941                	bnez	a0,800056fe <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005770:	2184a783          	lw	a5,536(s1)
    80005774:	21c4a703          	lw	a4,540(s1)
    80005778:	2007879b          	addiw	a5,a5,512
    8000577c:	faf705e3          	beq	a4,a5,80005726 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005780:	4685                	li	a3,1
    80005782:	01590633          	add	a2,s2,s5
    80005786:	f9f40593          	addi	a1,s0,-97
    8000578a:	0509b503          	ld	a0,80(s3)
    8000578e:	ffffc097          	auipc	ra,0xffffc
    80005792:	f82080e7          	jalr	-126(ra) # 80001710 <copyin>
    80005796:	fb6514e3          	bne	a0,s6,8000573e <pipewrite+0x88>
  wakeup(&pi->nread);
    8000579a:	21848513          	addi	a0,s1,536
    8000579e:	ffffd097          	auipc	ra,0xffffd
    800057a2:	eb8080e7          	jalr	-328(ra) # 80002656 <wakeup>
  release(&pi->lock);
    800057a6:	8526                	mv	a0,s1
    800057a8:	ffffb097          	auipc	ra,0xffffb
    800057ac:	4f6080e7          	jalr	1270(ra) # 80000c9e <release>
  return i;
    800057b0:	bfa9                	j	8000570a <pipewrite+0x54>
  int i = 0;
    800057b2:	4901                	li	s2,0
    800057b4:	b7dd                	j	8000579a <pipewrite+0xe4>

00000000800057b6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800057b6:	715d                	addi	sp,sp,-80
    800057b8:	e486                	sd	ra,72(sp)
    800057ba:	e0a2                	sd	s0,64(sp)
    800057bc:	fc26                	sd	s1,56(sp)
    800057be:	f84a                	sd	s2,48(sp)
    800057c0:	f44e                	sd	s3,40(sp)
    800057c2:	f052                	sd	s4,32(sp)
    800057c4:	ec56                	sd	s5,24(sp)
    800057c6:	e85a                	sd	s6,16(sp)
    800057c8:	0880                	addi	s0,sp,80
    800057ca:	84aa                	mv	s1,a0
    800057cc:	892e                	mv	s2,a1
    800057ce:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800057d0:	ffffc097          	auipc	ra,0xffffc
    800057d4:	426080e7          	jalr	1062(ra) # 80001bf6 <myproc>
    800057d8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800057da:	8b26                	mv	s6,s1
    800057dc:	8526                	mv	a0,s1
    800057de:	ffffb097          	auipc	ra,0xffffb
    800057e2:	40c080e7          	jalr	1036(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800057e6:	2184a703          	lw	a4,536(s1)
    800057ea:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800057ee:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800057f2:	02f71763          	bne	a4,a5,80005820 <piperead+0x6a>
    800057f6:	2244a783          	lw	a5,548(s1)
    800057fa:	c39d                	beqz	a5,80005820 <piperead+0x6a>
    if(killed(pr)){
    800057fc:	8552                	mv	a0,s4
    800057fe:	ffffd097          	auipc	ra,0xffffd
    80005802:	0a8080e7          	jalr	168(ra) # 800028a6 <killed>
    80005806:	e941                	bnez	a0,80005896 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005808:	85da                	mv	a1,s6
    8000580a:	854e                	mv	a0,s3
    8000580c:	ffffd097          	auipc	ra,0xffffd
    80005810:	c9a080e7          	jalr	-870(ra) # 800024a6 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005814:	2184a703          	lw	a4,536(s1)
    80005818:	21c4a783          	lw	a5,540(s1)
    8000581c:	fcf70de3          	beq	a4,a5,800057f6 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005820:	09505263          	blez	s5,800058a4 <piperead+0xee>
    80005824:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005826:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005828:	2184a783          	lw	a5,536(s1)
    8000582c:	21c4a703          	lw	a4,540(s1)
    80005830:	02f70d63          	beq	a4,a5,8000586a <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005834:	0017871b          	addiw	a4,a5,1
    80005838:	20e4ac23          	sw	a4,536(s1)
    8000583c:	1ff7f793          	andi	a5,a5,511
    80005840:	97a6                	add	a5,a5,s1
    80005842:	0187c783          	lbu	a5,24(a5)
    80005846:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000584a:	4685                	li	a3,1
    8000584c:	fbf40613          	addi	a2,s0,-65
    80005850:	85ca                	mv	a1,s2
    80005852:	050a3503          	ld	a0,80(s4)
    80005856:	ffffc097          	auipc	ra,0xffffc
    8000585a:	e2e080e7          	jalr	-466(ra) # 80001684 <copyout>
    8000585e:	01650663          	beq	a0,s6,8000586a <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005862:	2985                	addiw	s3,s3,1
    80005864:	0905                	addi	s2,s2,1
    80005866:	fd3a91e3          	bne	s5,s3,80005828 <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000586a:	21c48513          	addi	a0,s1,540
    8000586e:	ffffd097          	auipc	ra,0xffffd
    80005872:	de8080e7          	jalr	-536(ra) # 80002656 <wakeup>
  release(&pi->lock);
    80005876:	8526                	mv	a0,s1
    80005878:	ffffb097          	auipc	ra,0xffffb
    8000587c:	426080e7          	jalr	1062(ra) # 80000c9e <release>
  return i;
}
    80005880:	854e                	mv	a0,s3
    80005882:	60a6                	ld	ra,72(sp)
    80005884:	6406                	ld	s0,64(sp)
    80005886:	74e2                	ld	s1,56(sp)
    80005888:	7942                	ld	s2,48(sp)
    8000588a:	79a2                	ld	s3,40(sp)
    8000588c:	7a02                	ld	s4,32(sp)
    8000588e:	6ae2                	ld	s5,24(sp)
    80005890:	6b42                	ld	s6,16(sp)
    80005892:	6161                	addi	sp,sp,80
    80005894:	8082                	ret
      release(&pi->lock);
    80005896:	8526                	mv	a0,s1
    80005898:	ffffb097          	auipc	ra,0xffffb
    8000589c:	406080e7          	jalr	1030(ra) # 80000c9e <release>
      return -1;
    800058a0:	59fd                	li	s3,-1
    800058a2:	bff9                	j	80005880 <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800058a4:	4981                	li	s3,0
    800058a6:	b7d1                	j	8000586a <piperead+0xb4>

00000000800058a8 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    800058a8:	1141                	addi	sp,sp,-16
    800058aa:	e422                	sd	s0,8(sp)
    800058ac:	0800                	addi	s0,sp,16
    800058ae:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800058b0:	8905                	andi	a0,a0,1
    800058b2:	c111                	beqz	a0,800058b6 <flags2perm+0xe>
      perm = PTE_X;
    800058b4:	4521                	li	a0,8
    if(flags & 0x2)
    800058b6:	8b89                	andi	a5,a5,2
    800058b8:	c399                	beqz	a5,800058be <flags2perm+0x16>
      perm |= PTE_W;
    800058ba:	00456513          	ori	a0,a0,4
    return perm;
}
    800058be:	6422                	ld	s0,8(sp)
    800058c0:	0141                	addi	sp,sp,16
    800058c2:	8082                	ret

00000000800058c4 <exec>:

int
exec(char *path, char **argv)
{
    800058c4:	df010113          	addi	sp,sp,-528
    800058c8:	20113423          	sd	ra,520(sp)
    800058cc:	20813023          	sd	s0,512(sp)
    800058d0:	ffa6                	sd	s1,504(sp)
    800058d2:	fbca                	sd	s2,496(sp)
    800058d4:	f7ce                	sd	s3,488(sp)
    800058d6:	f3d2                	sd	s4,480(sp)
    800058d8:	efd6                	sd	s5,472(sp)
    800058da:	ebda                	sd	s6,464(sp)
    800058dc:	e7de                	sd	s7,456(sp)
    800058de:	e3e2                	sd	s8,448(sp)
    800058e0:	ff66                	sd	s9,440(sp)
    800058e2:	fb6a                	sd	s10,432(sp)
    800058e4:	f76e                	sd	s11,424(sp)
    800058e6:	0c00                	addi	s0,sp,528
    800058e8:	84aa                	mv	s1,a0
    800058ea:	dea43c23          	sd	a0,-520(s0)
    800058ee:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800058f2:	ffffc097          	auipc	ra,0xffffc
    800058f6:	304080e7          	jalr	772(ra) # 80001bf6 <myproc>
    800058fa:	892a                	mv	s2,a0

  begin_op();
    800058fc:	fffff097          	auipc	ra,0xfffff
    80005900:	474080e7          	jalr	1140(ra) # 80004d70 <begin_op>

  if((ip = namei(path)) == 0){
    80005904:	8526                	mv	a0,s1
    80005906:	fffff097          	auipc	ra,0xfffff
    8000590a:	24e080e7          	jalr	590(ra) # 80004b54 <namei>
    8000590e:	c92d                	beqz	a0,80005980 <exec+0xbc>
    80005910:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005912:	fffff097          	auipc	ra,0xfffff
    80005916:	a9c080e7          	jalr	-1380(ra) # 800043ae <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000591a:	04000713          	li	a4,64
    8000591e:	4681                	li	a3,0
    80005920:	e5040613          	addi	a2,s0,-432
    80005924:	4581                	li	a1,0
    80005926:	8526                	mv	a0,s1
    80005928:	fffff097          	auipc	ra,0xfffff
    8000592c:	d3a080e7          	jalr	-710(ra) # 80004662 <readi>
    80005930:	04000793          	li	a5,64
    80005934:	00f51a63          	bne	a0,a5,80005948 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005938:	e5042703          	lw	a4,-432(s0)
    8000593c:	464c47b7          	lui	a5,0x464c4
    80005940:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005944:	04f70463          	beq	a4,a5,8000598c <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005948:	8526                	mv	a0,s1
    8000594a:	fffff097          	auipc	ra,0xfffff
    8000594e:	cc6080e7          	jalr	-826(ra) # 80004610 <iunlockput>
    end_op();
    80005952:	fffff097          	auipc	ra,0xfffff
    80005956:	49e080e7          	jalr	1182(ra) # 80004df0 <end_op>
  }
  return -1;
    8000595a:	557d                	li	a0,-1
}
    8000595c:	20813083          	ld	ra,520(sp)
    80005960:	20013403          	ld	s0,512(sp)
    80005964:	74fe                	ld	s1,504(sp)
    80005966:	795e                	ld	s2,496(sp)
    80005968:	79be                	ld	s3,488(sp)
    8000596a:	7a1e                	ld	s4,480(sp)
    8000596c:	6afe                	ld	s5,472(sp)
    8000596e:	6b5e                	ld	s6,464(sp)
    80005970:	6bbe                	ld	s7,456(sp)
    80005972:	6c1e                	ld	s8,448(sp)
    80005974:	7cfa                	ld	s9,440(sp)
    80005976:	7d5a                	ld	s10,432(sp)
    80005978:	7dba                	ld	s11,424(sp)
    8000597a:	21010113          	addi	sp,sp,528
    8000597e:	8082                	ret
    end_op();
    80005980:	fffff097          	auipc	ra,0xfffff
    80005984:	470080e7          	jalr	1136(ra) # 80004df0 <end_op>
    return -1;
    80005988:	557d                	li	a0,-1
    8000598a:	bfc9                	j	8000595c <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    8000598c:	854a                	mv	a0,s2
    8000598e:	ffffc097          	auipc	ra,0xffffc
    80005992:	32c080e7          	jalr	812(ra) # 80001cba <proc_pagetable>
    80005996:	8baa                	mv	s7,a0
    80005998:	d945                	beqz	a0,80005948 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000599a:	e7042983          	lw	s3,-400(s0)
    8000599e:	e8845783          	lhu	a5,-376(s0)
    800059a2:	c7ad                	beqz	a5,80005a0c <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800059a4:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800059a6:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    800059a8:	6c85                	lui	s9,0x1
    800059aa:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800059ae:	def43823          	sd	a5,-528(s0)
    800059b2:	ac0d                	j	80005be4 <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800059b4:	00004517          	auipc	a0,0x4
    800059b8:	f1c50513          	addi	a0,a0,-228 # 800098d0 <syscalls+0x2a8>
    800059bc:	ffffb097          	auipc	ra,0xffffb
    800059c0:	b88080e7          	jalr	-1144(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800059c4:	8756                	mv	a4,s5
    800059c6:	012d86bb          	addw	a3,s11,s2
    800059ca:	4581                	li	a1,0
    800059cc:	8526                	mv	a0,s1
    800059ce:	fffff097          	auipc	ra,0xfffff
    800059d2:	c94080e7          	jalr	-876(ra) # 80004662 <readi>
    800059d6:	2501                	sext.w	a0,a0
    800059d8:	1aaa9a63          	bne	s5,a0,80005b8c <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    800059dc:	6785                	lui	a5,0x1
    800059de:	0127893b          	addw	s2,a5,s2
    800059e2:	77fd                	lui	a5,0xfffff
    800059e4:	01478a3b          	addw	s4,a5,s4
    800059e8:	1f897563          	bgeu	s2,s8,80005bd2 <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    800059ec:	02091593          	slli	a1,s2,0x20
    800059f0:	9181                	srli	a1,a1,0x20
    800059f2:	95ea                	add	a1,a1,s10
    800059f4:	855e                	mv	a0,s7
    800059f6:	ffffb097          	auipc	ra,0xffffb
    800059fa:	682080e7          	jalr	1666(ra) # 80001078 <walkaddr>
    800059fe:	862a                	mv	a2,a0
    if(pa == 0)
    80005a00:	d955                	beqz	a0,800059b4 <exec+0xf0>
      n = PGSIZE;
    80005a02:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005a04:	fd9a70e3          	bgeu	s4,s9,800059c4 <exec+0x100>
      n = sz - i;
    80005a08:	8ad2                	mv	s5,s4
    80005a0a:	bf6d                	j	800059c4 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005a0c:	4a01                	li	s4,0
  iunlockput(ip);
    80005a0e:	8526                	mv	a0,s1
    80005a10:	fffff097          	auipc	ra,0xfffff
    80005a14:	c00080e7          	jalr	-1024(ra) # 80004610 <iunlockput>
  end_op();
    80005a18:	fffff097          	auipc	ra,0xfffff
    80005a1c:	3d8080e7          	jalr	984(ra) # 80004df0 <end_op>
  p = myproc();
    80005a20:	ffffc097          	auipc	ra,0xffffc
    80005a24:	1d6080e7          	jalr	470(ra) # 80001bf6 <myproc>
    80005a28:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005a2a:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005a2e:	6785                	lui	a5,0x1
    80005a30:	17fd                	addi	a5,a5,-1
    80005a32:	9a3e                	add	s4,s4,a5
    80005a34:	757d                	lui	a0,0xfffff
    80005a36:	00aa77b3          	and	a5,s4,a0
    80005a3a:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005a3e:	4691                	li	a3,4
    80005a40:	6609                	lui	a2,0x2
    80005a42:	963e                	add	a2,a2,a5
    80005a44:	85be                	mv	a1,a5
    80005a46:	855e                	mv	a0,s7
    80005a48:	ffffc097          	auipc	ra,0xffffc
    80005a4c:	9e4080e7          	jalr	-1564(ra) # 8000142c <uvmalloc>
    80005a50:	8b2a                	mv	s6,a0
  ip = 0;
    80005a52:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005a54:	12050c63          	beqz	a0,80005b8c <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005a58:	75f9                	lui	a1,0xffffe
    80005a5a:	95aa                	add	a1,a1,a0
    80005a5c:	855e                	mv	a0,s7
    80005a5e:	ffffc097          	auipc	ra,0xffffc
    80005a62:	bf4080e7          	jalr	-1036(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    80005a66:	7c7d                	lui	s8,0xfffff
    80005a68:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005a6a:	e0043783          	ld	a5,-512(s0)
    80005a6e:	6388                	ld	a0,0(a5)
    80005a70:	c535                	beqz	a0,80005adc <exec+0x218>
    80005a72:	e9040993          	addi	s3,s0,-368
    80005a76:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005a7a:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005a7c:	ffffb097          	auipc	ra,0xffffb
    80005a80:	3ee080e7          	jalr	1006(ra) # 80000e6a <strlen>
    80005a84:	2505                	addiw	a0,a0,1
    80005a86:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005a8a:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005a8e:	13896663          	bltu	s2,s8,80005bba <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005a92:	e0043d83          	ld	s11,-512(s0)
    80005a96:	000dba03          	ld	s4,0(s11)
    80005a9a:	8552                	mv	a0,s4
    80005a9c:	ffffb097          	auipc	ra,0xffffb
    80005aa0:	3ce080e7          	jalr	974(ra) # 80000e6a <strlen>
    80005aa4:	0015069b          	addiw	a3,a0,1
    80005aa8:	8652                	mv	a2,s4
    80005aaa:	85ca                	mv	a1,s2
    80005aac:	855e                	mv	a0,s7
    80005aae:	ffffc097          	auipc	ra,0xffffc
    80005ab2:	bd6080e7          	jalr	-1066(ra) # 80001684 <copyout>
    80005ab6:	10054663          	bltz	a0,80005bc2 <exec+0x2fe>
    ustack[argc] = sp;
    80005aba:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005abe:	0485                	addi	s1,s1,1
    80005ac0:	008d8793          	addi	a5,s11,8
    80005ac4:	e0f43023          	sd	a5,-512(s0)
    80005ac8:	008db503          	ld	a0,8(s11)
    80005acc:	c911                	beqz	a0,80005ae0 <exec+0x21c>
    if(argc >= MAXARG)
    80005ace:	09a1                	addi	s3,s3,8
    80005ad0:	fb3c96e3          	bne	s9,s3,80005a7c <exec+0x1b8>
  sz = sz1;
    80005ad4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005ad8:	4481                	li	s1,0
    80005ada:	a84d                	j	80005b8c <exec+0x2c8>
  sp = sz;
    80005adc:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005ade:	4481                	li	s1,0
  ustack[argc] = 0;
    80005ae0:	00349793          	slli	a5,s1,0x3
    80005ae4:	f9040713          	addi	a4,s0,-112
    80005ae8:	97ba                	add	a5,a5,a4
    80005aea:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005aee:	00148693          	addi	a3,s1,1
    80005af2:	068e                	slli	a3,a3,0x3
    80005af4:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005af8:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005afc:	01897663          	bgeu	s2,s8,80005b08 <exec+0x244>
  sz = sz1;
    80005b00:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005b04:	4481                	li	s1,0
    80005b06:	a059                	j	80005b8c <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005b08:	e9040613          	addi	a2,s0,-368
    80005b0c:	85ca                	mv	a1,s2
    80005b0e:	855e                	mv	a0,s7
    80005b10:	ffffc097          	auipc	ra,0xffffc
    80005b14:	b74080e7          	jalr	-1164(ra) # 80001684 <copyout>
    80005b18:	0a054963          	bltz	a0,80005bca <exec+0x306>
  p->trapframe->a1 = sp;
    80005b1c:	058ab783          	ld	a5,88(s5)
    80005b20:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005b24:	df843783          	ld	a5,-520(s0)
    80005b28:	0007c703          	lbu	a4,0(a5)
    80005b2c:	cf11                	beqz	a4,80005b48 <exec+0x284>
    80005b2e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005b30:	02f00693          	li	a3,47
    80005b34:	a039                	j	80005b42 <exec+0x27e>
      last = s+1;
    80005b36:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005b3a:	0785                	addi	a5,a5,1
    80005b3c:	fff7c703          	lbu	a4,-1(a5)
    80005b40:	c701                	beqz	a4,80005b48 <exec+0x284>
    if(*s == '/')
    80005b42:	fed71ce3          	bne	a4,a3,80005b3a <exec+0x276>
    80005b46:	bfc5                	j	80005b36 <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80005b48:	4641                	li	a2,16
    80005b4a:	df843583          	ld	a1,-520(s0)
    80005b4e:	158a8513          	addi	a0,s5,344
    80005b52:	ffffb097          	auipc	ra,0xffffb
    80005b56:	2e6080e7          	jalr	742(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    80005b5a:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005b5e:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005b62:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005b66:	058ab783          	ld	a5,88(s5)
    80005b6a:	e6843703          	ld	a4,-408(s0)
    80005b6e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005b70:	058ab783          	ld	a5,88(s5)
    80005b74:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005b78:	85ea                	mv	a1,s10
    80005b7a:	ffffc097          	auipc	ra,0xffffc
    80005b7e:	1dc080e7          	jalr	476(ra) # 80001d56 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005b82:	0004851b          	sext.w	a0,s1
    80005b86:	bbd9                	j	8000595c <exec+0x98>
    80005b88:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005b8c:	e0843583          	ld	a1,-504(s0)
    80005b90:	855e                	mv	a0,s7
    80005b92:	ffffc097          	auipc	ra,0xffffc
    80005b96:	1c4080e7          	jalr	452(ra) # 80001d56 <proc_freepagetable>
  if(ip){
    80005b9a:	da0497e3          	bnez	s1,80005948 <exec+0x84>
  return -1;
    80005b9e:	557d                	li	a0,-1
    80005ba0:	bb75                	j	8000595c <exec+0x98>
    80005ba2:	e1443423          	sd	s4,-504(s0)
    80005ba6:	b7dd                	j	80005b8c <exec+0x2c8>
    80005ba8:	e1443423          	sd	s4,-504(s0)
    80005bac:	b7c5                	j	80005b8c <exec+0x2c8>
    80005bae:	e1443423          	sd	s4,-504(s0)
    80005bb2:	bfe9                	j	80005b8c <exec+0x2c8>
    80005bb4:	e1443423          	sd	s4,-504(s0)
    80005bb8:	bfd1                	j	80005b8c <exec+0x2c8>
  sz = sz1;
    80005bba:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005bbe:	4481                	li	s1,0
    80005bc0:	b7f1                	j	80005b8c <exec+0x2c8>
  sz = sz1;
    80005bc2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005bc6:	4481                	li	s1,0
    80005bc8:	b7d1                	j	80005b8c <exec+0x2c8>
  sz = sz1;
    80005bca:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005bce:	4481                	li	s1,0
    80005bd0:	bf75                	j	80005b8c <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005bd2:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005bd6:	2b05                	addiw	s6,s6,1
    80005bd8:	0389899b          	addiw	s3,s3,56
    80005bdc:	e8845783          	lhu	a5,-376(s0)
    80005be0:	e2fb57e3          	bge	s6,a5,80005a0e <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005be4:	2981                	sext.w	s3,s3
    80005be6:	03800713          	li	a4,56
    80005bea:	86ce                	mv	a3,s3
    80005bec:	e1840613          	addi	a2,s0,-488
    80005bf0:	4581                	li	a1,0
    80005bf2:	8526                	mv	a0,s1
    80005bf4:	fffff097          	auipc	ra,0xfffff
    80005bf8:	a6e080e7          	jalr	-1426(ra) # 80004662 <readi>
    80005bfc:	03800793          	li	a5,56
    80005c00:	f8f514e3          	bne	a0,a5,80005b88 <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    80005c04:	e1842783          	lw	a5,-488(s0)
    80005c08:	4705                	li	a4,1
    80005c0a:	fce796e3          	bne	a5,a4,80005bd6 <exec+0x312>
    if(ph.memsz < ph.filesz)
    80005c0e:	e4043903          	ld	s2,-448(s0)
    80005c12:	e3843783          	ld	a5,-456(s0)
    80005c16:	f8f966e3          	bltu	s2,a5,80005ba2 <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005c1a:	e2843783          	ld	a5,-472(s0)
    80005c1e:	993e                	add	s2,s2,a5
    80005c20:	f8f964e3          	bltu	s2,a5,80005ba8 <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    80005c24:	df043703          	ld	a4,-528(s0)
    80005c28:	8ff9                	and	a5,a5,a4
    80005c2a:	f3d1                	bnez	a5,80005bae <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005c2c:	e1c42503          	lw	a0,-484(s0)
    80005c30:	00000097          	auipc	ra,0x0
    80005c34:	c78080e7          	jalr	-904(ra) # 800058a8 <flags2perm>
    80005c38:	86aa                	mv	a3,a0
    80005c3a:	864a                	mv	a2,s2
    80005c3c:	85d2                	mv	a1,s4
    80005c3e:	855e                	mv	a0,s7
    80005c40:	ffffb097          	auipc	ra,0xffffb
    80005c44:	7ec080e7          	jalr	2028(ra) # 8000142c <uvmalloc>
    80005c48:	e0a43423          	sd	a0,-504(s0)
    80005c4c:	d525                	beqz	a0,80005bb4 <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005c4e:	e2843d03          	ld	s10,-472(s0)
    80005c52:	e2042d83          	lw	s11,-480(s0)
    80005c56:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005c5a:	f60c0ce3          	beqz	s8,80005bd2 <exec+0x30e>
    80005c5e:	8a62                	mv	s4,s8
    80005c60:	4901                	li	s2,0
    80005c62:	b369                	j	800059ec <exec+0x128>

0000000080005c64 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005c64:	7179                	addi	sp,sp,-48
    80005c66:	f406                	sd	ra,40(sp)
    80005c68:	f022                	sd	s0,32(sp)
    80005c6a:	ec26                	sd	s1,24(sp)
    80005c6c:	e84a                	sd	s2,16(sp)
    80005c6e:	1800                	addi	s0,sp,48
    80005c70:	892e                	mv	s2,a1
    80005c72:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005c74:	fdc40593          	addi	a1,s0,-36
    80005c78:	ffffd097          	auipc	ra,0xffffd
    80005c7c:	5da080e7          	jalr	1498(ra) # 80003252 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005c80:	fdc42703          	lw	a4,-36(s0)
    80005c84:	47bd                	li	a5,15
    80005c86:	02e7eb63          	bltu	a5,a4,80005cbc <argfd+0x58>
    80005c8a:	ffffc097          	auipc	ra,0xffffc
    80005c8e:	f6c080e7          	jalr	-148(ra) # 80001bf6 <myproc>
    80005c92:	fdc42703          	lw	a4,-36(s0)
    80005c96:	01a70793          	addi	a5,a4,26
    80005c9a:	078e                	slli	a5,a5,0x3
    80005c9c:	953e                	add	a0,a0,a5
    80005c9e:	611c                	ld	a5,0(a0)
    80005ca0:	c385                	beqz	a5,80005cc0 <argfd+0x5c>
    return -1;
  if(pfd)
    80005ca2:	00090463          	beqz	s2,80005caa <argfd+0x46>
    *pfd = fd;
    80005ca6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005caa:	4501                	li	a0,0
  if(pf)
    80005cac:	c091                	beqz	s1,80005cb0 <argfd+0x4c>
    *pf = f;
    80005cae:	e09c                	sd	a5,0(s1)
}
    80005cb0:	70a2                	ld	ra,40(sp)
    80005cb2:	7402                	ld	s0,32(sp)
    80005cb4:	64e2                	ld	s1,24(sp)
    80005cb6:	6942                	ld	s2,16(sp)
    80005cb8:	6145                	addi	sp,sp,48
    80005cba:	8082                	ret
    return -1;
    80005cbc:	557d                	li	a0,-1
    80005cbe:	bfcd                	j	80005cb0 <argfd+0x4c>
    80005cc0:	557d                	li	a0,-1
    80005cc2:	b7fd                	j	80005cb0 <argfd+0x4c>

0000000080005cc4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005cc4:	1101                	addi	sp,sp,-32
    80005cc6:	ec06                	sd	ra,24(sp)
    80005cc8:	e822                	sd	s0,16(sp)
    80005cca:	e426                	sd	s1,8(sp)
    80005ccc:	1000                	addi	s0,sp,32
    80005cce:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005cd0:	ffffc097          	auipc	ra,0xffffc
    80005cd4:	f26080e7          	jalr	-218(ra) # 80001bf6 <myproc>
    80005cd8:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005cda:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd8a78>
    80005cde:	4501                	li	a0,0
    80005ce0:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005ce2:	6398                	ld	a4,0(a5)
    80005ce4:	cb19                	beqz	a4,80005cfa <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005ce6:	2505                	addiw	a0,a0,1
    80005ce8:	07a1                	addi	a5,a5,8
    80005cea:	fed51ce3          	bne	a0,a3,80005ce2 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005cee:	557d                	li	a0,-1
}
    80005cf0:	60e2                	ld	ra,24(sp)
    80005cf2:	6442                	ld	s0,16(sp)
    80005cf4:	64a2                	ld	s1,8(sp)
    80005cf6:	6105                	addi	sp,sp,32
    80005cf8:	8082                	ret
      p->ofile[fd] = f;
    80005cfa:	01a50793          	addi	a5,a0,26
    80005cfe:	078e                	slli	a5,a5,0x3
    80005d00:	963e                	add	a2,a2,a5
    80005d02:	e204                	sd	s1,0(a2)
      return fd;
    80005d04:	b7f5                	j	80005cf0 <fdalloc+0x2c>

0000000080005d06 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005d06:	715d                	addi	sp,sp,-80
    80005d08:	e486                	sd	ra,72(sp)
    80005d0a:	e0a2                	sd	s0,64(sp)
    80005d0c:	fc26                	sd	s1,56(sp)
    80005d0e:	f84a                	sd	s2,48(sp)
    80005d10:	f44e                	sd	s3,40(sp)
    80005d12:	f052                	sd	s4,32(sp)
    80005d14:	ec56                	sd	s5,24(sp)
    80005d16:	e85a                	sd	s6,16(sp)
    80005d18:	0880                	addi	s0,sp,80
    80005d1a:	8b2e                	mv	s6,a1
    80005d1c:	89b2                	mv	s3,a2
    80005d1e:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005d20:	fb040593          	addi	a1,s0,-80
    80005d24:	fffff097          	auipc	ra,0xfffff
    80005d28:	e4e080e7          	jalr	-434(ra) # 80004b72 <nameiparent>
    80005d2c:	84aa                	mv	s1,a0
    80005d2e:	16050063          	beqz	a0,80005e8e <create+0x188>
    return 0;

  ilock(dp);
    80005d32:	ffffe097          	auipc	ra,0xffffe
    80005d36:	67c080e7          	jalr	1660(ra) # 800043ae <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005d3a:	4601                	li	a2,0
    80005d3c:	fb040593          	addi	a1,s0,-80
    80005d40:	8526                	mv	a0,s1
    80005d42:	fffff097          	auipc	ra,0xfffff
    80005d46:	b50080e7          	jalr	-1200(ra) # 80004892 <dirlookup>
    80005d4a:	8aaa                	mv	s5,a0
    80005d4c:	c931                	beqz	a0,80005da0 <create+0x9a>
    iunlockput(dp);
    80005d4e:	8526                	mv	a0,s1
    80005d50:	fffff097          	auipc	ra,0xfffff
    80005d54:	8c0080e7          	jalr	-1856(ra) # 80004610 <iunlockput>
    ilock(ip);
    80005d58:	8556                	mv	a0,s5
    80005d5a:	ffffe097          	auipc	ra,0xffffe
    80005d5e:	654080e7          	jalr	1620(ra) # 800043ae <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005d62:	000b059b          	sext.w	a1,s6
    80005d66:	4789                	li	a5,2
    80005d68:	02f59563          	bne	a1,a5,80005d92 <create+0x8c>
    80005d6c:	044ad783          	lhu	a5,68(s5)
    80005d70:	37f9                	addiw	a5,a5,-2
    80005d72:	17c2                	slli	a5,a5,0x30
    80005d74:	93c1                	srli	a5,a5,0x30
    80005d76:	4705                	li	a4,1
    80005d78:	00f76d63          	bltu	a4,a5,80005d92 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005d7c:	8556                	mv	a0,s5
    80005d7e:	60a6                	ld	ra,72(sp)
    80005d80:	6406                	ld	s0,64(sp)
    80005d82:	74e2                	ld	s1,56(sp)
    80005d84:	7942                	ld	s2,48(sp)
    80005d86:	79a2                	ld	s3,40(sp)
    80005d88:	7a02                	ld	s4,32(sp)
    80005d8a:	6ae2                	ld	s5,24(sp)
    80005d8c:	6b42                	ld	s6,16(sp)
    80005d8e:	6161                	addi	sp,sp,80
    80005d90:	8082                	ret
    iunlockput(ip);
    80005d92:	8556                	mv	a0,s5
    80005d94:	fffff097          	auipc	ra,0xfffff
    80005d98:	87c080e7          	jalr	-1924(ra) # 80004610 <iunlockput>
    return 0;
    80005d9c:	4a81                	li	s5,0
    80005d9e:	bff9                	j	80005d7c <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005da0:	85da                	mv	a1,s6
    80005da2:	4088                	lw	a0,0(s1)
    80005da4:	ffffe097          	auipc	ra,0xffffe
    80005da8:	46e080e7          	jalr	1134(ra) # 80004212 <ialloc>
    80005dac:	8a2a                	mv	s4,a0
    80005dae:	c921                	beqz	a0,80005dfe <create+0xf8>
  ilock(ip);
    80005db0:	ffffe097          	auipc	ra,0xffffe
    80005db4:	5fe080e7          	jalr	1534(ra) # 800043ae <ilock>
  ip->major = major;
    80005db8:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005dbc:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005dc0:	4785                	li	a5,1
    80005dc2:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    80005dc6:	8552                	mv	a0,s4
    80005dc8:	ffffe097          	auipc	ra,0xffffe
    80005dcc:	51c080e7          	jalr	1308(ra) # 800042e4 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005dd0:	000b059b          	sext.w	a1,s6
    80005dd4:	4785                	li	a5,1
    80005dd6:	02f58b63          	beq	a1,a5,80005e0c <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    80005dda:	004a2603          	lw	a2,4(s4)
    80005dde:	fb040593          	addi	a1,s0,-80
    80005de2:	8526                	mv	a0,s1
    80005de4:	fffff097          	auipc	ra,0xfffff
    80005de8:	cbe080e7          	jalr	-834(ra) # 80004aa2 <dirlink>
    80005dec:	06054f63          	bltz	a0,80005e6a <create+0x164>
  iunlockput(dp);
    80005df0:	8526                	mv	a0,s1
    80005df2:	fffff097          	auipc	ra,0xfffff
    80005df6:	81e080e7          	jalr	-2018(ra) # 80004610 <iunlockput>
  return ip;
    80005dfa:	8ad2                	mv	s5,s4
    80005dfc:	b741                	j	80005d7c <create+0x76>
    iunlockput(dp);
    80005dfe:	8526                	mv	a0,s1
    80005e00:	fffff097          	auipc	ra,0xfffff
    80005e04:	810080e7          	jalr	-2032(ra) # 80004610 <iunlockput>
    return 0;
    80005e08:	8ad2                	mv	s5,s4
    80005e0a:	bf8d                	j	80005d7c <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005e0c:	004a2603          	lw	a2,4(s4)
    80005e10:	00004597          	auipc	a1,0x4
    80005e14:	ae058593          	addi	a1,a1,-1312 # 800098f0 <syscalls+0x2c8>
    80005e18:	8552                	mv	a0,s4
    80005e1a:	fffff097          	auipc	ra,0xfffff
    80005e1e:	c88080e7          	jalr	-888(ra) # 80004aa2 <dirlink>
    80005e22:	04054463          	bltz	a0,80005e6a <create+0x164>
    80005e26:	40d0                	lw	a2,4(s1)
    80005e28:	00004597          	auipc	a1,0x4
    80005e2c:	ad058593          	addi	a1,a1,-1328 # 800098f8 <syscalls+0x2d0>
    80005e30:	8552                	mv	a0,s4
    80005e32:	fffff097          	auipc	ra,0xfffff
    80005e36:	c70080e7          	jalr	-912(ra) # 80004aa2 <dirlink>
    80005e3a:	02054863          	bltz	a0,80005e6a <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    80005e3e:	004a2603          	lw	a2,4(s4)
    80005e42:	fb040593          	addi	a1,s0,-80
    80005e46:	8526                	mv	a0,s1
    80005e48:	fffff097          	auipc	ra,0xfffff
    80005e4c:	c5a080e7          	jalr	-934(ra) # 80004aa2 <dirlink>
    80005e50:	00054d63          	bltz	a0,80005e6a <create+0x164>
    dp->nlink++;  // for ".."
    80005e54:	04a4d783          	lhu	a5,74(s1)
    80005e58:	2785                	addiw	a5,a5,1
    80005e5a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005e5e:	8526                	mv	a0,s1
    80005e60:	ffffe097          	auipc	ra,0xffffe
    80005e64:	484080e7          	jalr	1156(ra) # 800042e4 <iupdate>
    80005e68:	b761                	j	80005df0 <create+0xea>
  ip->nlink = 0;
    80005e6a:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005e6e:	8552                	mv	a0,s4
    80005e70:	ffffe097          	auipc	ra,0xffffe
    80005e74:	474080e7          	jalr	1140(ra) # 800042e4 <iupdate>
  iunlockput(ip);
    80005e78:	8552                	mv	a0,s4
    80005e7a:	ffffe097          	auipc	ra,0xffffe
    80005e7e:	796080e7          	jalr	1942(ra) # 80004610 <iunlockput>
  iunlockput(dp);
    80005e82:	8526                	mv	a0,s1
    80005e84:	ffffe097          	auipc	ra,0xffffe
    80005e88:	78c080e7          	jalr	1932(ra) # 80004610 <iunlockput>
  return 0;
    80005e8c:	bdc5                	j	80005d7c <create+0x76>
    return 0;
    80005e8e:	8aaa                	mv	s5,a0
    80005e90:	b5f5                	j	80005d7c <create+0x76>

0000000080005e92 <sys_dup>:
{
    80005e92:	7179                	addi	sp,sp,-48
    80005e94:	f406                	sd	ra,40(sp)
    80005e96:	f022                	sd	s0,32(sp)
    80005e98:	ec26                	sd	s1,24(sp)
    80005e9a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005e9c:	fd840613          	addi	a2,s0,-40
    80005ea0:	4581                	li	a1,0
    80005ea2:	4501                	li	a0,0
    80005ea4:	00000097          	auipc	ra,0x0
    80005ea8:	dc0080e7          	jalr	-576(ra) # 80005c64 <argfd>
    return -1;
    80005eac:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005eae:	02054363          	bltz	a0,80005ed4 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005eb2:	fd843503          	ld	a0,-40(s0)
    80005eb6:	00000097          	auipc	ra,0x0
    80005eba:	e0e080e7          	jalr	-498(ra) # 80005cc4 <fdalloc>
    80005ebe:	84aa                	mv	s1,a0
    return -1;
    80005ec0:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005ec2:	00054963          	bltz	a0,80005ed4 <sys_dup+0x42>
  filedup(f);
    80005ec6:	fd843503          	ld	a0,-40(s0)
    80005eca:	fffff097          	auipc	ra,0xfffff
    80005ece:	320080e7          	jalr	800(ra) # 800051ea <filedup>
  return fd;
    80005ed2:	87a6                	mv	a5,s1
}
    80005ed4:	853e                	mv	a0,a5
    80005ed6:	70a2                	ld	ra,40(sp)
    80005ed8:	7402                	ld	s0,32(sp)
    80005eda:	64e2                	ld	s1,24(sp)
    80005edc:	6145                	addi	sp,sp,48
    80005ede:	8082                	ret

0000000080005ee0 <sys_read>:
{
    80005ee0:	7179                	addi	sp,sp,-48
    80005ee2:	f406                	sd	ra,40(sp)
    80005ee4:	f022                	sd	s0,32(sp)
    80005ee6:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005ee8:	fd840593          	addi	a1,s0,-40
    80005eec:	4505                	li	a0,1
    80005eee:	ffffd097          	auipc	ra,0xffffd
    80005ef2:	384080e7          	jalr	900(ra) # 80003272 <argaddr>
  argint(2, &n);
    80005ef6:	fe440593          	addi	a1,s0,-28
    80005efa:	4509                	li	a0,2
    80005efc:	ffffd097          	auipc	ra,0xffffd
    80005f00:	356080e7          	jalr	854(ra) # 80003252 <argint>
  if(argfd(0, 0, &f) < 0)
    80005f04:	fe840613          	addi	a2,s0,-24
    80005f08:	4581                	li	a1,0
    80005f0a:	4501                	li	a0,0
    80005f0c:	00000097          	auipc	ra,0x0
    80005f10:	d58080e7          	jalr	-680(ra) # 80005c64 <argfd>
    80005f14:	87aa                	mv	a5,a0
    return -1;
    80005f16:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005f18:	0007cc63          	bltz	a5,80005f30 <sys_read+0x50>
  return fileread(f, p, n);
    80005f1c:	fe442603          	lw	a2,-28(s0)
    80005f20:	fd843583          	ld	a1,-40(s0)
    80005f24:	fe843503          	ld	a0,-24(s0)
    80005f28:	fffff097          	auipc	ra,0xfffff
    80005f2c:	44e080e7          	jalr	1102(ra) # 80005376 <fileread>
}
    80005f30:	70a2                	ld	ra,40(sp)
    80005f32:	7402                	ld	s0,32(sp)
    80005f34:	6145                	addi	sp,sp,48
    80005f36:	8082                	ret

0000000080005f38 <sys_write>:
{
    80005f38:	7179                	addi	sp,sp,-48
    80005f3a:	f406                	sd	ra,40(sp)
    80005f3c:	f022                	sd	s0,32(sp)
    80005f3e:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005f40:	fd840593          	addi	a1,s0,-40
    80005f44:	4505                	li	a0,1
    80005f46:	ffffd097          	auipc	ra,0xffffd
    80005f4a:	32c080e7          	jalr	812(ra) # 80003272 <argaddr>
  argint(2, &n);
    80005f4e:	fe440593          	addi	a1,s0,-28
    80005f52:	4509                	li	a0,2
    80005f54:	ffffd097          	auipc	ra,0xffffd
    80005f58:	2fe080e7          	jalr	766(ra) # 80003252 <argint>
  if(argfd(0, 0, &f) < 0)
    80005f5c:	fe840613          	addi	a2,s0,-24
    80005f60:	4581                	li	a1,0
    80005f62:	4501                	li	a0,0
    80005f64:	00000097          	auipc	ra,0x0
    80005f68:	d00080e7          	jalr	-768(ra) # 80005c64 <argfd>
    80005f6c:	87aa                	mv	a5,a0
    return -1;
    80005f6e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005f70:	0007cc63          	bltz	a5,80005f88 <sys_write+0x50>
  return filewrite(f, p, n);
    80005f74:	fe442603          	lw	a2,-28(s0)
    80005f78:	fd843583          	ld	a1,-40(s0)
    80005f7c:	fe843503          	ld	a0,-24(s0)
    80005f80:	fffff097          	auipc	ra,0xfffff
    80005f84:	4b8080e7          	jalr	1208(ra) # 80005438 <filewrite>
}
    80005f88:	70a2                	ld	ra,40(sp)
    80005f8a:	7402                	ld	s0,32(sp)
    80005f8c:	6145                	addi	sp,sp,48
    80005f8e:	8082                	ret

0000000080005f90 <sys_close>:
{
    80005f90:	1101                	addi	sp,sp,-32
    80005f92:	ec06                	sd	ra,24(sp)
    80005f94:	e822                	sd	s0,16(sp)
    80005f96:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005f98:	fe040613          	addi	a2,s0,-32
    80005f9c:	fec40593          	addi	a1,s0,-20
    80005fa0:	4501                	li	a0,0
    80005fa2:	00000097          	auipc	ra,0x0
    80005fa6:	cc2080e7          	jalr	-830(ra) # 80005c64 <argfd>
    return -1;
    80005faa:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005fac:	02054463          	bltz	a0,80005fd4 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005fb0:	ffffc097          	auipc	ra,0xffffc
    80005fb4:	c46080e7          	jalr	-954(ra) # 80001bf6 <myproc>
    80005fb8:	fec42783          	lw	a5,-20(s0)
    80005fbc:	07e9                	addi	a5,a5,26
    80005fbe:	078e                	slli	a5,a5,0x3
    80005fc0:	97aa                	add	a5,a5,a0
    80005fc2:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005fc6:	fe043503          	ld	a0,-32(s0)
    80005fca:	fffff097          	auipc	ra,0xfffff
    80005fce:	272080e7          	jalr	626(ra) # 8000523c <fileclose>
  return 0;
    80005fd2:	4781                	li	a5,0
}
    80005fd4:	853e                	mv	a0,a5
    80005fd6:	60e2                	ld	ra,24(sp)
    80005fd8:	6442                	ld	s0,16(sp)
    80005fda:	6105                	addi	sp,sp,32
    80005fdc:	8082                	ret

0000000080005fde <sys_fstat>:
{
    80005fde:	1101                	addi	sp,sp,-32
    80005fe0:	ec06                	sd	ra,24(sp)
    80005fe2:	e822                	sd	s0,16(sp)
    80005fe4:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005fe6:	fe040593          	addi	a1,s0,-32
    80005fea:	4505                	li	a0,1
    80005fec:	ffffd097          	auipc	ra,0xffffd
    80005ff0:	286080e7          	jalr	646(ra) # 80003272 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005ff4:	fe840613          	addi	a2,s0,-24
    80005ff8:	4581                	li	a1,0
    80005ffa:	4501                	li	a0,0
    80005ffc:	00000097          	auipc	ra,0x0
    80006000:	c68080e7          	jalr	-920(ra) # 80005c64 <argfd>
    80006004:	87aa                	mv	a5,a0
    return -1;
    80006006:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80006008:	0007ca63          	bltz	a5,8000601c <sys_fstat+0x3e>
  return filestat(f, st);
    8000600c:	fe043583          	ld	a1,-32(s0)
    80006010:	fe843503          	ld	a0,-24(s0)
    80006014:	fffff097          	auipc	ra,0xfffff
    80006018:	2f0080e7          	jalr	752(ra) # 80005304 <filestat>
}
    8000601c:	60e2                	ld	ra,24(sp)
    8000601e:	6442                	ld	s0,16(sp)
    80006020:	6105                	addi	sp,sp,32
    80006022:	8082                	ret

0000000080006024 <sys_link>:
{
    80006024:	7169                	addi	sp,sp,-304
    80006026:	f606                	sd	ra,296(sp)
    80006028:	f222                	sd	s0,288(sp)
    8000602a:	ee26                	sd	s1,280(sp)
    8000602c:	ea4a                	sd	s2,272(sp)
    8000602e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006030:	08000613          	li	a2,128
    80006034:	ed040593          	addi	a1,s0,-304
    80006038:	4501                	li	a0,0
    8000603a:	ffffd097          	auipc	ra,0xffffd
    8000603e:	258080e7          	jalr	600(ra) # 80003292 <argstr>
    return -1;
    80006042:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006044:	10054e63          	bltz	a0,80006160 <sys_link+0x13c>
    80006048:	08000613          	li	a2,128
    8000604c:	f5040593          	addi	a1,s0,-176
    80006050:	4505                	li	a0,1
    80006052:	ffffd097          	auipc	ra,0xffffd
    80006056:	240080e7          	jalr	576(ra) # 80003292 <argstr>
    return -1;
    8000605a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000605c:	10054263          	bltz	a0,80006160 <sys_link+0x13c>
  begin_op();
    80006060:	fffff097          	auipc	ra,0xfffff
    80006064:	d10080e7          	jalr	-752(ra) # 80004d70 <begin_op>
  if((ip = namei(old)) == 0){
    80006068:	ed040513          	addi	a0,s0,-304
    8000606c:	fffff097          	auipc	ra,0xfffff
    80006070:	ae8080e7          	jalr	-1304(ra) # 80004b54 <namei>
    80006074:	84aa                	mv	s1,a0
    80006076:	c551                	beqz	a0,80006102 <sys_link+0xde>
  ilock(ip);
    80006078:	ffffe097          	auipc	ra,0xffffe
    8000607c:	336080e7          	jalr	822(ra) # 800043ae <ilock>
  if(ip->type == T_DIR){
    80006080:	04449703          	lh	a4,68(s1)
    80006084:	4785                	li	a5,1
    80006086:	08f70463          	beq	a4,a5,8000610e <sys_link+0xea>
  ip->nlink++;
    8000608a:	04a4d783          	lhu	a5,74(s1)
    8000608e:	2785                	addiw	a5,a5,1
    80006090:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006094:	8526                	mv	a0,s1
    80006096:	ffffe097          	auipc	ra,0xffffe
    8000609a:	24e080e7          	jalr	590(ra) # 800042e4 <iupdate>
  iunlock(ip);
    8000609e:	8526                	mv	a0,s1
    800060a0:	ffffe097          	auipc	ra,0xffffe
    800060a4:	3d0080e7          	jalr	976(ra) # 80004470 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800060a8:	fd040593          	addi	a1,s0,-48
    800060ac:	f5040513          	addi	a0,s0,-176
    800060b0:	fffff097          	auipc	ra,0xfffff
    800060b4:	ac2080e7          	jalr	-1342(ra) # 80004b72 <nameiparent>
    800060b8:	892a                	mv	s2,a0
    800060ba:	c935                	beqz	a0,8000612e <sys_link+0x10a>
  ilock(dp);
    800060bc:	ffffe097          	auipc	ra,0xffffe
    800060c0:	2f2080e7          	jalr	754(ra) # 800043ae <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800060c4:	00092703          	lw	a4,0(s2)
    800060c8:	409c                	lw	a5,0(s1)
    800060ca:	04f71d63          	bne	a4,a5,80006124 <sys_link+0x100>
    800060ce:	40d0                	lw	a2,4(s1)
    800060d0:	fd040593          	addi	a1,s0,-48
    800060d4:	854a                	mv	a0,s2
    800060d6:	fffff097          	auipc	ra,0xfffff
    800060da:	9cc080e7          	jalr	-1588(ra) # 80004aa2 <dirlink>
    800060de:	04054363          	bltz	a0,80006124 <sys_link+0x100>
  iunlockput(dp);
    800060e2:	854a                	mv	a0,s2
    800060e4:	ffffe097          	auipc	ra,0xffffe
    800060e8:	52c080e7          	jalr	1324(ra) # 80004610 <iunlockput>
  iput(ip);
    800060ec:	8526                	mv	a0,s1
    800060ee:	ffffe097          	auipc	ra,0xffffe
    800060f2:	47a080e7          	jalr	1146(ra) # 80004568 <iput>
  end_op();
    800060f6:	fffff097          	auipc	ra,0xfffff
    800060fa:	cfa080e7          	jalr	-774(ra) # 80004df0 <end_op>
  return 0;
    800060fe:	4781                	li	a5,0
    80006100:	a085                	j	80006160 <sys_link+0x13c>
    end_op();
    80006102:	fffff097          	auipc	ra,0xfffff
    80006106:	cee080e7          	jalr	-786(ra) # 80004df0 <end_op>
    return -1;
    8000610a:	57fd                	li	a5,-1
    8000610c:	a891                	j	80006160 <sys_link+0x13c>
    iunlockput(ip);
    8000610e:	8526                	mv	a0,s1
    80006110:	ffffe097          	auipc	ra,0xffffe
    80006114:	500080e7          	jalr	1280(ra) # 80004610 <iunlockput>
    end_op();
    80006118:	fffff097          	auipc	ra,0xfffff
    8000611c:	cd8080e7          	jalr	-808(ra) # 80004df0 <end_op>
    return -1;
    80006120:	57fd                	li	a5,-1
    80006122:	a83d                	j	80006160 <sys_link+0x13c>
    iunlockput(dp);
    80006124:	854a                	mv	a0,s2
    80006126:	ffffe097          	auipc	ra,0xffffe
    8000612a:	4ea080e7          	jalr	1258(ra) # 80004610 <iunlockput>
  ilock(ip);
    8000612e:	8526                	mv	a0,s1
    80006130:	ffffe097          	auipc	ra,0xffffe
    80006134:	27e080e7          	jalr	638(ra) # 800043ae <ilock>
  ip->nlink--;
    80006138:	04a4d783          	lhu	a5,74(s1)
    8000613c:	37fd                	addiw	a5,a5,-1
    8000613e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006142:	8526                	mv	a0,s1
    80006144:	ffffe097          	auipc	ra,0xffffe
    80006148:	1a0080e7          	jalr	416(ra) # 800042e4 <iupdate>
  iunlockput(ip);
    8000614c:	8526                	mv	a0,s1
    8000614e:	ffffe097          	auipc	ra,0xffffe
    80006152:	4c2080e7          	jalr	1218(ra) # 80004610 <iunlockput>
  end_op();
    80006156:	fffff097          	auipc	ra,0xfffff
    8000615a:	c9a080e7          	jalr	-870(ra) # 80004df0 <end_op>
  return -1;
    8000615e:	57fd                	li	a5,-1
}
    80006160:	853e                	mv	a0,a5
    80006162:	70b2                	ld	ra,296(sp)
    80006164:	7412                	ld	s0,288(sp)
    80006166:	64f2                	ld	s1,280(sp)
    80006168:	6952                	ld	s2,272(sp)
    8000616a:	6155                	addi	sp,sp,304
    8000616c:	8082                	ret

000000008000616e <sys_unlink>:
{
    8000616e:	7151                	addi	sp,sp,-240
    80006170:	f586                	sd	ra,232(sp)
    80006172:	f1a2                	sd	s0,224(sp)
    80006174:	eda6                	sd	s1,216(sp)
    80006176:	e9ca                	sd	s2,208(sp)
    80006178:	e5ce                	sd	s3,200(sp)
    8000617a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000617c:	08000613          	li	a2,128
    80006180:	f3040593          	addi	a1,s0,-208
    80006184:	4501                	li	a0,0
    80006186:	ffffd097          	auipc	ra,0xffffd
    8000618a:	10c080e7          	jalr	268(ra) # 80003292 <argstr>
    8000618e:	18054163          	bltz	a0,80006310 <sys_unlink+0x1a2>
  begin_op();
    80006192:	fffff097          	auipc	ra,0xfffff
    80006196:	bde080e7          	jalr	-1058(ra) # 80004d70 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000619a:	fb040593          	addi	a1,s0,-80
    8000619e:	f3040513          	addi	a0,s0,-208
    800061a2:	fffff097          	auipc	ra,0xfffff
    800061a6:	9d0080e7          	jalr	-1584(ra) # 80004b72 <nameiparent>
    800061aa:	84aa                	mv	s1,a0
    800061ac:	c979                	beqz	a0,80006282 <sys_unlink+0x114>
  ilock(dp);
    800061ae:	ffffe097          	auipc	ra,0xffffe
    800061b2:	200080e7          	jalr	512(ra) # 800043ae <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800061b6:	00003597          	auipc	a1,0x3
    800061ba:	73a58593          	addi	a1,a1,1850 # 800098f0 <syscalls+0x2c8>
    800061be:	fb040513          	addi	a0,s0,-80
    800061c2:	ffffe097          	auipc	ra,0xffffe
    800061c6:	6b6080e7          	jalr	1718(ra) # 80004878 <namecmp>
    800061ca:	14050a63          	beqz	a0,8000631e <sys_unlink+0x1b0>
    800061ce:	00003597          	auipc	a1,0x3
    800061d2:	72a58593          	addi	a1,a1,1834 # 800098f8 <syscalls+0x2d0>
    800061d6:	fb040513          	addi	a0,s0,-80
    800061da:	ffffe097          	auipc	ra,0xffffe
    800061de:	69e080e7          	jalr	1694(ra) # 80004878 <namecmp>
    800061e2:	12050e63          	beqz	a0,8000631e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800061e6:	f2c40613          	addi	a2,s0,-212
    800061ea:	fb040593          	addi	a1,s0,-80
    800061ee:	8526                	mv	a0,s1
    800061f0:	ffffe097          	auipc	ra,0xffffe
    800061f4:	6a2080e7          	jalr	1698(ra) # 80004892 <dirlookup>
    800061f8:	892a                	mv	s2,a0
    800061fa:	12050263          	beqz	a0,8000631e <sys_unlink+0x1b0>
  ilock(ip);
    800061fe:	ffffe097          	auipc	ra,0xffffe
    80006202:	1b0080e7          	jalr	432(ra) # 800043ae <ilock>
  if(ip->nlink < 1)
    80006206:	04a91783          	lh	a5,74(s2)
    8000620a:	08f05263          	blez	a5,8000628e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000620e:	04491703          	lh	a4,68(s2)
    80006212:	4785                	li	a5,1
    80006214:	08f70563          	beq	a4,a5,8000629e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80006218:	4641                	li	a2,16
    8000621a:	4581                	li	a1,0
    8000621c:	fc040513          	addi	a0,s0,-64
    80006220:	ffffb097          	auipc	ra,0xffffb
    80006224:	ac6080e7          	jalr	-1338(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006228:	4741                	li	a4,16
    8000622a:	f2c42683          	lw	a3,-212(s0)
    8000622e:	fc040613          	addi	a2,s0,-64
    80006232:	4581                	li	a1,0
    80006234:	8526                	mv	a0,s1
    80006236:	ffffe097          	auipc	ra,0xffffe
    8000623a:	524080e7          	jalr	1316(ra) # 8000475a <writei>
    8000623e:	47c1                	li	a5,16
    80006240:	0af51563          	bne	a0,a5,800062ea <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80006244:	04491703          	lh	a4,68(s2)
    80006248:	4785                	li	a5,1
    8000624a:	0af70863          	beq	a4,a5,800062fa <sys_unlink+0x18c>
  iunlockput(dp);
    8000624e:	8526                	mv	a0,s1
    80006250:	ffffe097          	auipc	ra,0xffffe
    80006254:	3c0080e7          	jalr	960(ra) # 80004610 <iunlockput>
  ip->nlink--;
    80006258:	04a95783          	lhu	a5,74(s2)
    8000625c:	37fd                	addiw	a5,a5,-1
    8000625e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80006262:	854a                	mv	a0,s2
    80006264:	ffffe097          	auipc	ra,0xffffe
    80006268:	080080e7          	jalr	128(ra) # 800042e4 <iupdate>
  iunlockput(ip);
    8000626c:	854a                	mv	a0,s2
    8000626e:	ffffe097          	auipc	ra,0xffffe
    80006272:	3a2080e7          	jalr	930(ra) # 80004610 <iunlockput>
  end_op();
    80006276:	fffff097          	auipc	ra,0xfffff
    8000627a:	b7a080e7          	jalr	-1158(ra) # 80004df0 <end_op>
  return 0;
    8000627e:	4501                	li	a0,0
    80006280:	a84d                	j	80006332 <sys_unlink+0x1c4>
    end_op();
    80006282:	fffff097          	auipc	ra,0xfffff
    80006286:	b6e080e7          	jalr	-1170(ra) # 80004df0 <end_op>
    return -1;
    8000628a:	557d                	li	a0,-1
    8000628c:	a05d                	j	80006332 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000628e:	00003517          	auipc	a0,0x3
    80006292:	67250513          	addi	a0,a0,1650 # 80009900 <syscalls+0x2d8>
    80006296:	ffffa097          	auipc	ra,0xffffa
    8000629a:	2ae080e7          	jalr	686(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000629e:	04c92703          	lw	a4,76(s2)
    800062a2:	02000793          	li	a5,32
    800062a6:	f6e7f9e3          	bgeu	a5,a4,80006218 <sys_unlink+0xaa>
    800062aa:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800062ae:	4741                	li	a4,16
    800062b0:	86ce                	mv	a3,s3
    800062b2:	f1840613          	addi	a2,s0,-232
    800062b6:	4581                	li	a1,0
    800062b8:	854a                	mv	a0,s2
    800062ba:	ffffe097          	auipc	ra,0xffffe
    800062be:	3a8080e7          	jalr	936(ra) # 80004662 <readi>
    800062c2:	47c1                	li	a5,16
    800062c4:	00f51b63          	bne	a0,a5,800062da <sys_unlink+0x16c>
    if(de.inum != 0)
    800062c8:	f1845783          	lhu	a5,-232(s0)
    800062cc:	e7a1                	bnez	a5,80006314 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800062ce:	29c1                	addiw	s3,s3,16
    800062d0:	04c92783          	lw	a5,76(s2)
    800062d4:	fcf9ede3          	bltu	s3,a5,800062ae <sys_unlink+0x140>
    800062d8:	b781                	j	80006218 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800062da:	00003517          	auipc	a0,0x3
    800062de:	63e50513          	addi	a0,a0,1598 # 80009918 <syscalls+0x2f0>
    800062e2:	ffffa097          	auipc	ra,0xffffa
    800062e6:	262080e7          	jalr	610(ra) # 80000544 <panic>
    panic("unlink: writei");
    800062ea:	00003517          	auipc	a0,0x3
    800062ee:	64650513          	addi	a0,a0,1606 # 80009930 <syscalls+0x308>
    800062f2:	ffffa097          	auipc	ra,0xffffa
    800062f6:	252080e7          	jalr	594(ra) # 80000544 <panic>
    dp->nlink--;
    800062fa:	04a4d783          	lhu	a5,74(s1)
    800062fe:	37fd                	addiw	a5,a5,-1
    80006300:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80006304:	8526                	mv	a0,s1
    80006306:	ffffe097          	auipc	ra,0xffffe
    8000630a:	fde080e7          	jalr	-34(ra) # 800042e4 <iupdate>
    8000630e:	b781                	j	8000624e <sys_unlink+0xe0>
    return -1;
    80006310:	557d                	li	a0,-1
    80006312:	a005                	j	80006332 <sys_unlink+0x1c4>
    iunlockput(ip);
    80006314:	854a                	mv	a0,s2
    80006316:	ffffe097          	auipc	ra,0xffffe
    8000631a:	2fa080e7          	jalr	762(ra) # 80004610 <iunlockput>
  iunlockput(dp);
    8000631e:	8526                	mv	a0,s1
    80006320:	ffffe097          	auipc	ra,0xffffe
    80006324:	2f0080e7          	jalr	752(ra) # 80004610 <iunlockput>
  end_op();
    80006328:	fffff097          	auipc	ra,0xfffff
    8000632c:	ac8080e7          	jalr	-1336(ra) # 80004df0 <end_op>
  return -1;
    80006330:	557d                	li	a0,-1
}
    80006332:	70ae                	ld	ra,232(sp)
    80006334:	740e                	ld	s0,224(sp)
    80006336:	64ee                	ld	s1,216(sp)
    80006338:	694e                	ld	s2,208(sp)
    8000633a:	69ae                	ld	s3,200(sp)
    8000633c:	616d                	addi	sp,sp,240
    8000633e:	8082                	ret

0000000080006340 <sys_open>:

uint64
sys_open(void)
{
    80006340:	7131                	addi	sp,sp,-192
    80006342:	fd06                	sd	ra,184(sp)
    80006344:	f922                	sd	s0,176(sp)
    80006346:	f526                	sd	s1,168(sp)
    80006348:	f14a                	sd	s2,160(sp)
    8000634a:	ed4e                	sd	s3,152(sp)
    8000634c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000634e:	f4c40593          	addi	a1,s0,-180
    80006352:	4505                	li	a0,1
    80006354:	ffffd097          	auipc	ra,0xffffd
    80006358:	efe080e7          	jalr	-258(ra) # 80003252 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000635c:	08000613          	li	a2,128
    80006360:	f5040593          	addi	a1,s0,-176
    80006364:	4501                	li	a0,0
    80006366:	ffffd097          	auipc	ra,0xffffd
    8000636a:	f2c080e7          	jalr	-212(ra) # 80003292 <argstr>
    8000636e:	87aa                	mv	a5,a0
    return -1;
    80006370:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80006372:	0a07c963          	bltz	a5,80006424 <sys_open+0xe4>

  begin_op();
    80006376:	fffff097          	auipc	ra,0xfffff
    8000637a:	9fa080e7          	jalr	-1542(ra) # 80004d70 <begin_op>

  if(omode & O_CREATE){
    8000637e:	f4c42783          	lw	a5,-180(s0)
    80006382:	2007f793          	andi	a5,a5,512
    80006386:	cfc5                	beqz	a5,8000643e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80006388:	4681                	li	a3,0
    8000638a:	4601                	li	a2,0
    8000638c:	4589                	li	a1,2
    8000638e:	f5040513          	addi	a0,s0,-176
    80006392:	00000097          	auipc	ra,0x0
    80006396:	974080e7          	jalr	-1676(ra) # 80005d06 <create>
    8000639a:	84aa                	mv	s1,a0
    if(ip == 0){
    8000639c:	c959                	beqz	a0,80006432 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000639e:	04449703          	lh	a4,68(s1)
    800063a2:	478d                	li	a5,3
    800063a4:	00f71763          	bne	a4,a5,800063b2 <sys_open+0x72>
    800063a8:	0464d703          	lhu	a4,70(s1)
    800063ac:	47a5                	li	a5,9
    800063ae:	0ce7ed63          	bltu	a5,a4,80006488 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800063b2:	fffff097          	auipc	ra,0xfffff
    800063b6:	dce080e7          	jalr	-562(ra) # 80005180 <filealloc>
    800063ba:	89aa                	mv	s3,a0
    800063bc:	10050363          	beqz	a0,800064c2 <sys_open+0x182>
    800063c0:	00000097          	auipc	ra,0x0
    800063c4:	904080e7          	jalr	-1788(ra) # 80005cc4 <fdalloc>
    800063c8:	892a                	mv	s2,a0
    800063ca:	0e054763          	bltz	a0,800064b8 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800063ce:	04449703          	lh	a4,68(s1)
    800063d2:	478d                	li	a5,3
    800063d4:	0cf70563          	beq	a4,a5,8000649e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800063d8:	4789                	li	a5,2
    800063da:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800063de:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800063e2:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800063e6:	f4c42783          	lw	a5,-180(s0)
    800063ea:	0017c713          	xori	a4,a5,1
    800063ee:	8b05                	andi	a4,a4,1
    800063f0:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800063f4:	0037f713          	andi	a4,a5,3
    800063f8:	00e03733          	snez	a4,a4
    800063fc:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006400:	4007f793          	andi	a5,a5,1024
    80006404:	c791                	beqz	a5,80006410 <sys_open+0xd0>
    80006406:	04449703          	lh	a4,68(s1)
    8000640a:	4789                	li	a5,2
    8000640c:	0af70063          	beq	a4,a5,800064ac <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006410:	8526                	mv	a0,s1
    80006412:	ffffe097          	auipc	ra,0xffffe
    80006416:	05e080e7          	jalr	94(ra) # 80004470 <iunlock>
  end_op();
    8000641a:	fffff097          	auipc	ra,0xfffff
    8000641e:	9d6080e7          	jalr	-1578(ra) # 80004df0 <end_op>

  return fd;
    80006422:	854a                	mv	a0,s2
}
    80006424:	70ea                	ld	ra,184(sp)
    80006426:	744a                	ld	s0,176(sp)
    80006428:	74aa                	ld	s1,168(sp)
    8000642a:	790a                	ld	s2,160(sp)
    8000642c:	69ea                	ld	s3,152(sp)
    8000642e:	6129                	addi	sp,sp,192
    80006430:	8082                	ret
      end_op();
    80006432:	fffff097          	auipc	ra,0xfffff
    80006436:	9be080e7          	jalr	-1602(ra) # 80004df0 <end_op>
      return -1;
    8000643a:	557d                	li	a0,-1
    8000643c:	b7e5                	j	80006424 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000643e:	f5040513          	addi	a0,s0,-176
    80006442:	ffffe097          	auipc	ra,0xffffe
    80006446:	712080e7          	jalr	1810(ra) # 80004b54 <namei>
    8000644a:	84aa                	mv	s1,a0
    8000644c:	c905                	beqz	a0,8000647c <sys_open+0x13c>
    ilock(ip);
    8000644e:	ffffe097          	auipc	ra,0xffffe
    80006452:	f60080e7          	jalr	-160(ra) # 800043ae <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006456:	04449703          	lh	a4,68(s1)
    8000645a:	4785                	li	a5,1
    8000645c:	f4f711e3          	bne	a4,a5,8000639e <sys_open+0x5e>
    80006460:	f4c42783          	lw	a5,-180(s0)
    80006464:	d7b9                	beqz	a5,800063b2 <sys_open+0x72>
      iunlockput(ip);
    80006466:	8526                	mv	a0,s1
    80006468:	ffffe097          	auipc	ra,0xffffe
    8000646c:	1a8080e7          	jalr	424(ra) # 80004610 <iunlockput>
      end_op();
    80006470:	fffff097          	auipc	ra,0xfffff
    80006474:	980080e7          	jalr	-1664(ra) # 80004df0 <end_op>
      return -1;
    80006478:	557d                	li	a0,-1
    8000647a:	b76d                	j	80006424 <sys_open+0xe4>
      end_op();
    8000647c:	fffff097          	auipc	ra,0xfffff
    80006480:	974080e7          	jalr	-1676(ra) # 80004df0 <end_op>
      return -1;
    80006484:	557d                	li	a0,-1
    80006486:	bf79                	j	80006424 <sys_open+0xe4>
    iunlockput(ip);
    80006488:	8526                	mv	a0,s1
    8000648a:	ffffe097          	auipc	ra,0xffffe
    8000648e:	186080e7          	jalr	390(ra) # 80004610 <iunlockput>
    end_op();
    80006492:	fffff097          	auipc	ra,0xfffff
    80006496:	95e080e7          	jalr	-1698(ra) # 80004df0 <end_op>
    return -1;
    8000649a:	557d                	li	a0,-1
    8000649c:	b761                	j	80006424 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000649e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800064a2:	04649783          	lh	a5,70(s1)
    800064a6:	02f99223          	sh	a5,36(s3)
    800064aa:	bf25                	j	800063e2 <sys_open+0xa2>
    itrunc(ip);
    800064ac:	8526                	mv	a0,s1
    800064ae:	ffffe097          	auipc	ra,0xffffe
    800064b2:	00e080e7          	jalr	14(ra) # 800044bc <itrunc>
    800064b6:	bfa9                	j	80006410 <sys_open+0xd0>
      fileclose(f);
    800064b8:	854e                	mv	a0,s3
    800064ba:	fffff097          	auipc	ra,0xfffff
    800064be:	d82080e7          	jalr	-638(ra) # 8000523c <fileclose>
    iunlockput(ip);
    800064c2:	8526                	mv	a0,s1
    800064c4:	ffffe097          	auipc	ra,0xffffe
    800064c8:	14c080e7          	jalr	332(ra) # 80004610 <iunlockput>
    end_op();
    800064cc:	fffff097          	auipc	ra,0xfffff
    800064d0:	924080e7          	jalr	-1756(ra) # 80004df0 <end_op>
    return -1;
    800064d4:	557d                	li	a0,-1
    800064d6:	b7b9                	j	80006424 <sys_open+0xe4>

00000000800064d8 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800064d8:	7175                	addi	sp,sp,-144
    800064da:	e506                	sd	ra,136(sp)
    800064dc:	e122                	sd	s0,128(sp)
    800064de:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800064e0:	fffff097          	auipc	ra,0xfffff
    800064e4:	890080e7          	jalr	-1904(ra) # 80004d70 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800064e8:	08000613          	li	a2,128
    800064ec:	f7040593          	addi	a1,s0,-144
    800064f0:	4501                	li	a0,0
    800064f2:	ffffd097          	auipc	ra,0xffffd
    800064f6:	da0080e7          	jalr	-608(ra) # 80003292 <argstr>
    800064fa:	02054963          	bltz	a0,8000652c <sys_mkdir+0x54>
    800064fe:	4681                	li	a3,0
    80006500:	4601                	li	a2,0
    80006502:	4585                	li	a1,1
    80006504:	f7040513          	addi	a0,s0,-144
    80006508:	fffff097          	auipc	ra,0xfffff
    8000650c:	7fe080e7          	jalr	2046(ra) # 80005d06 <create>
    80006510:	cd11                	beqz	a0,8000652c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006512:	ffffe097          	auipc	ra,0xffffe
    80006516:	0fe080e7          	jalr	254(ra) # 80004610 <iunlockput>
  end_op();
    8000651a:	fffff097          	auipc	ra,0xfffff
    8000651e:	8d6080e7          	jalr	-1834(ra) # 80004df0 <end_op>
  return 0;
    80006522:	4501                	li	a0,0
}
    80006524:	60aa                	ld	ra,136(sp)
    80006526:	640a                	ld	s0,128(sp)
    80006528:	6149                	addi	sp,sp,144
    8000652a:	8082                	ret
    end_op();
    8000652c:	fffff097          	auipc	ra,0xfffff
    80006530:	8c4080e7          	jalr	-1852(ra) # 80004df0 <end_op>
    return -1;
    80006534:	557d                	li	a0,-1
    80006536:	b7fd                	j	80006524 <sys_mkdir+0x4c>

0000000080006538 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006538:	7135                	addi	sp,sp,-160
    8000653a:	ed06                	sd	ra,152(sp)
    8000653c:	e922                	sd	s0,144(sp)
    8000653e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006540:	fffff097          	auipc	ra,0xfffff
    80006544:	830080e7          	jalr	-2000(ra) # 80004d70 <begin_op>
  argint(1, &major);
    80006548:	f6c40593          	addi	a1,s0,-148
    8000654c:	4505                	li	a0,1
    8000654e:	ffffd097          	auipc	ra,0xffffd
    80006552:	d04080e7          	jalr	-764(ra) # 80003252 <argint>
  argint(2, &minor);
    80006556:	f6840593          	addi	a1,s0,-152
    8000655a:	4509                	li	a0,2
    8000655c:	ffffd097          	auipc	ra,0xffffd
    80006560:	cf6080e7          	jalr	-778(ra) # 80003252 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006564:	08000613          	li	a2,128
    80006568:	f7040593          	addi	a1,s0,-144
    8000656c:	4501                	li	a0,0
    8000656e:	ffffd097          	auipc	ra,0xffffd
    80006572:	d24080e7          	jalr	-732(ra) # 80003292 <argstr>
    80006576:	02054b63          	bltz	a0,800065ac <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000657a:	f6841683          	lh	a3,-152(s0)
    8000657e:	f6c41603          	lh	a2,-148(s0)
    80006582:	458d                	li	a1,3
    80006584:	f7040513          	addi	a0,s0,-144
    80006588:	fffff097          	auipc	ra,0xfffff
    8000658c:	77e080e7          	jalr	1918(ra) # 80005d06 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006590:	cd11                	beqz	a0,800065ac <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006592:	ffffe097          	auipc	ra,0xffffe
    80006596:	07e080e7          	jalr	126(ra) # 80004610 <iunlockput>
  end_op();
    8000659a:	fffff097          	auipc	ra,0xfffff
    8000659e:	856080e7          	jalr	-1962(ra) # 80004df0 <end_op>
  return 0;
    800065a2:	4501                	li	a0,0
}
    800065a4:	60ea                	ld	ra,152(sp)
    800065a6:	644a                	ld	s0,144(sp)
    800065a8:	610d                	addi	sp,sp,160
    800065aa:	8082                	ret
    end_op();
    800065ac:	fffff097          	auipc	ra,0xfffff
    800065b0:	844080e7          	jalr	-1980(ra) # 80004df0 <end_op>
    return -1;
    800065b4:	557d                	li	a0,-1
    800065b6:	b7fd                	j	800065a4 <sys_mknod+0x6c>

00000000800065b8 <sys_chdir>:

uint64
sys_chdir(void)
{
    800065b8:	7135                	addi	sp,sp,-160
    800065ba:	ed06                	sd	ra,152(sp)
    800065bc:	e922                	sd	s0,144(sp)
    800065be:	e526                	sd	s1,136(sp)
    800065c0:	e14a                	sd	s2,128(sp)
    800065c2:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800065c4:	ffffb097          	auipc	ra,0xffffb
    800065c8:	632080e7          	jalr	1586(ra) # 80001bf6 <myproc>
    800065cc:	892a                	mv	s2,a0
  
  begin_op();
    800065ce:	ffffe097          	auipc	ra,0xffffe
    800065d2:	7a2080e7          	jalr	1954(ra) # 80004d70 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800065d6:	08000613          	li	a2,128
    800065da:	f6040593          	addi	a1,s0,-160
    800065de:	4501                	li	a0,0
    800065e0:	ffffd097          	auipc	ra,0xffffd
    800065e4:	cb2080e7          	jalr	-846(ra) # 80003292 <argstr>
    800065e8:	04054b63          	bltz	a0,8000663e <sys_chdir+0x86>
    800065ec:	f6040513          	addi	a0,s0,-160
    800065f0:	ffffe097          	auipc	ra,0xffffe
    800065f4:	564080e7          	jalr	1380(ra) # 80004b54 <namei>
    800065f8:	84aa                	mv	s1,a0
    800065fa:	c131                	beqz	a0,8000663e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800065fc:	ffffe097          	auipc	ra,0xffffe
    80006600:	db2080e7          	jalr	-590(ra) # 800043ae <ilock>
  if(ip->type != T_DIR){
    80006604:	04449703          	lh	a4,68(s1)
    80006608:	4785                	li	a5,1
    8000660a:	04f71063          	bne	a4,a5,8000664a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000660e:	8526                	mv	a0,s1
    80006610:	ffffe097          	auipc	ra,0xffffe
    80006614:	e60080e7          	jalr	-416(ra) # 80004470 <iunlock>
  iput(p->cwd);
    80006618:	15093503          	ld	a0,336(s2)
    8000661c:	ffffe097          	auipc	ra,0xffffe
    80006620:	f4c080e7          	jalr	-180(ra) # 80004568 <iput>
  end_op();
    80006624:	ffffe097          	auipc	ra,0xffffe
    80006628:	7cc080e7          	jalr	1996(ra) # 80004df0 <end_op>
  p->cwd = ip;
    8000662c:	14993823          	sd	s1,336(s2)
  return 0;
    80006630:	4501                	li	a0,0
}
    80006632:	60ea                	ld	ra,152(sp)
    80006634:	644a                	ld	s0,144(sp)
    80006636:	64aa                	ld	s1,136(sp)
    80006638:	690a                	ld	s2,128(sp)
    8000663a:	610d                	addi	sp,sp,160
    8000663c:	8082                	ret
    end_op();
    8000663e:	ffffe097          	auipc	ra,0xffffe
    80006642:	7b2080e7          	jalr	1970(ra) # 80004df0 <end_op>
    return -1;
    80006646:	557d                	li	a0,-1
    80006648:	b7ed                	j	80006632 <sys_chdir+0x7a>
    iunlockput(ip);
    8000664a:	8526                	mv	a0,s1
    8000664c:	ffffe097          	auipc	ra,0xffffe
    80006650:	fc4080e7          	jalr	-60(ra) # 80004610 <iunlockput>
    end_op();
    80006654:	ffffe097          	auipc	ra,0xffffe
    80006658:	79c080e7          	jalr	1948(ra) # 80004df0 <end_op>
    return -1;
    8000665c:	557d                	li	a0,-1
    8000665e:	bfd1                	j	80006632 <sys_chdir+0x7a>

0000000080006660 <sys_exec>:

uint64
sys_exec(void)
{
    80006660:	7145                	addi	sp,sp,-464
    80006662:	e786                	sd	ra,456(sp)
    80006664:	e3a2                	sd	s0,448(sp)
    80006666:	ff26                	sd	s1,440(sp)
    80006668:	fb4a                	sd	s2,432(sp)
    8000666a:	f74e                	sd	s3,424(sp)
    8000666c:	f352                	sd	s4,416(sp)
    8000666e:	ef56                	sd	s5,408(sp)
    80006670:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80006672:	e3840593          	addi	a1,s0,-456
    80006676:	4505                	li	a0,1
    80006678:	ffffd097          	auipc	ra,0xffffd
    8000667c:	bfa080e7          	jalr	-1030(ra) # 80003272 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80006680:	08000613          	li	a2,128
    80006684:	f4040593          	addi	a1,s0,-192
    80006688:	4501                	li	a0,0
    8000668a:	ffffd097          	auipc	ra,0xffffd
    8000668e:	c08080e7          	jalr	-1016(ra) # 80003292 <argstr>
    80006692:	87aa                	mv	a5,a0
    return -1;
    80006694:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80006696:	0c07c263          	bltz	a5,8000675a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    8000669a:	10000613          	li	a2,256
    8000669e:	4581                	li	a1,0
    800066a0:	e4040513          	addi	a0,s0,-448
    800066a4:	ffffa097          	auipc	ra,0xffffa
    800066a8:	642080e7          	jalr	1602(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800066ac:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800066b0:	89a6                	mv	s3,s1
    800066b2:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800066b4:	02000a13          	li	s4,32
    800066b8:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800066bc:	00391513          	slli	a0,s2,0x3
    800066c0:	e3040593          	addi	a1,s0,-464
    800066c4:	e3843783          	ld	a5,-456(s0)
    800066c8:	953e                	add	a0,a0,a5
    800066ca:	ffffd097          	auipc	ra,0xffffd
    800066ce:	aea080e7          	jalr	-1302(ra) # 800031b4 <fetchaddr>
    800066d2:	02054a63          	bltz	a0,80006706 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    800066d6:	e3043783          	ld	a5,-464(s0)
    800066da:	c3b9                	beqz	a5,80006720 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800066dc:	ffffa097          	auipc	ra,0xffffa
    800066e0:	41e080e7          	jalr	1054(ra) # 80000afa <kalloc>
    800066e4:	85aa                	mv	a1,a0
    800066e6:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800066ea:	cd11                	beqz	a0,80006706 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800066ec:	6605                	lui	a2,0x1
    800066ee:	e3043503          	ld	a0,-464(s0)
    800066f2:	ffffd097          	auipc	ra,0xffffd
    800066f6:	b14080e7          	jalr	-1260(ra) # 80003206 <fetchstr>
    800066fa:	00054663          	bltz	a0,80006706 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    800066fe:	0905                	addi	s2,s2,1
    80006700:	09a1                	addi	s3,s3,8
    80006702:	fb491be3          	bne	s2,s4,800066b8 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006706:	10048913          	addi	s2,s1,256
    8000670a:	6088                	ld	a0,0(s1)
    8000670c:	c531                	beqz	a0,80006758 <sys_exec+0xf8>
    kfree(argv[i]);
    8000670e:	ffffa097          	auipc	ra,0xffffa
    80006712:	2f0080e7          	jalr	752(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006716:	04a1                	addi	s1,s1,8
    80006718:	ff2499e3          	bne	s1,s2,8000670a <sys_exec+0xaa>
  return -1;
    8000671c:	557d                	li	a0,-1
    8000671e:	a835                	j	8000675a <sys_exec+0xfa>
      argv[i] = 0;
    80006720:	0a8e                	slli	s5,s5,0x3
    80006722:	fc040793          	addi	a5,s0,-64
    80006726:	9abe                	add	s5,s5,a5
    80006728:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000672c:	e4040593          	addi	a1,s0,-448
    80006730:	f4040513          	addi	a0,s0,-192
    80006734:	fffff097          	auipc	ra,0xfffff
    80006738:	190080e7          	jalr	400(ra) # 800058c4 <exec>
    8000673c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000673e:	10048993          	addi	s3,s1,256
    80006742:	6088                	ld	a0,0(s1)
    80006744:	c901                	beqz	a0,80006754 <sys_exec+0xf4>
    kfree(argv[i]);
    80006746:	ffffa097          	auipc	ra,0xffffa
    8000674a:	2b8080e7          	jalr	696(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000674e:	04a1                	addi	s1,s1,8
    80006750:	ff3499e3          	bne	s1,s3,80006742 <sys_exec+0xe2>
  return ret;
    80006754:	854a                	mv	a0,s2
    80006756:	a011                	j	8000675a <sys_exec+0xfa>
  return -1;
    80006758:	557d                	li	a0,-1
}
    8000675a:	60be                	ld	ra,456(sp)
    8000675c:	641e                	ld	s0,448(sp)
    8000675e:	74fa                	ld	s1,440(sp)
    80006760:	795a                	ld	s2,432(sp)
    80006762:	79ba                	ld	s3,424(sp)
    80006764:	7a1a                	ld	s4,416(sp)
    80006766:	6afa                	ld	s5,408(sp)
    80006768:	6179                	addi	sp,sp,464
    8000676a:	8082                	ret

000000008000676c <sys_pipe>:

uint64
sys_pipe(void)
{
    8000676c:	7139                	addi	sp,sp,-64
    8000676e:	fc06                	sd	ra,56(sp)
    80006770:	f822                	sd	s0,48(sp)
    80006772:	f426                	sd	s1,40(sp)
    80006774:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006776:	ffffb097          	auipc	ra,0xffffb
    8000677a:	480080e7          	jalr	1152(ra) # 80001bf6 <myproc>
    8000677e:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006780:	fd840593          	addi	a1,s0,-40
    80006784:	4501                	li	a0,0
    80006786:	ffffd097          	auipc	ra,0xffffd
    8000678a:	aec080e7          	jalr	-1300(ra) # 80003272 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    8000678e:	fc840593          	addi	a1,s0,-56
    80006792:	fd040513          	addi	a0,s0,-48
    80006796:	fffff097          	auipc	ra,0xfffff
    8000679a:	dd6080e7          	jalr	-554(ra) # 8000556c <pipealloc>
    return -1;
    8000679e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800067a0:	0c054463          	bltz	a0,80006868 <sys_pipe+0xfc>
  fd0 = -1;
    800067a4:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800067a8:	fd043503          	ld	a0,-48(s0)
    800067ac:	fffff097          	auipc	ra,0xfffff
    800067b0:	518080e7          	jalr	1304(ra) # 80005cc4 <fdalloc>
    800067b4:	fca42223          	sw	a0,-60(s0)
    800067b8:	08054b63          	bltz	a0,8000684e <sys_pipe+0xe2>
    800067bc:	fc843503          	ld	a0,-56(s0)
    800067c0:	fffff097          	auipc	ra,0xfffff
    800067c4:	504080e7          	jalr	1284(ra) # 80005cc4 <fdalloc>
    800067c8:	fca42023          	sw	a0,-64(s0)
    800067cc:	06054863          	bltz	a0,8000683c <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800067d0:	4691                	li	a3,4
    800067d2:	fc440613          	addi	a2,s0,-60
    800067d6:	fd843583          	ld	a1,-40(s0)
    800067da:	68a8                	ld	a0,80(s1)
    800067dc:	ffffb097          	auipc	ra,0xffffb
    800067e0:	ea8080e7          	jalr	-344(ra) # 80001684 <copyout>
    800067e4:	02054063          	bltz	a0,80006804 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800067e8:	4691                	li	a3,4
    800067ea:	fc040613          	addi	a2,s0,-64
    800067ee:	fd843583          	ld	a1,-40(s0)
    800067f2:	0591                	addi	a1,a1,4
    800067f4:	68a8                	ld	a0,80(s1)
    800067f6:	ffffb097          	auipc	ra,0xffffb
    800067fa:	e8e080e7          	jalr	-370(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800067fe:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006800:	06055463          	bgez	a0,80006868 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80006804:	fc442783          	lw	a5,-60(s0)
    80006808:	07e9                	addi	a5,a5,26
    8000680a:	078e                	slli	a5,a5,0x3
    8000680c:	97a6                	add	a5,a5,s1
    8000680e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006812:	fc042503          	lw	a0,-64(s0)
    80006816:	0569                	addi	a0,a0,26
    80006818:	050e                	slli	a0,a0,0x3
    8000681a:	94aa                	add	s1,s1,a0
    8000681c:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006820:	fd043503          	ld	a0,-48(s0)
    80006824:	fffff097          	auipc	ra,0xfffff
    80006828:	a18080e7          	jalr	-1512(ra) # 8000523c <fileclose>
    fileclose(wf);
    8000682c:	fc843503          	ld	a0,-56(s0)
    80006830:	fffff097          	auipc	ra,0xfffff
    80006834:	a0c080e7          	jalr	-1524(ra) # 8000523c <fileclose>
    return -1;
    80006838:	57fd                	li	a5,-1
    8000683a:	a03d                	j	80006868 <sys_pipe+0xfc>
    if(fd0 >= 0)
    8000683c:	fc442783          	lw	a5,-60(s0)
    80006840:	0007c763          	bltz	a5,8000684e <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80006844:	07e9                	addi	a5,a5,26
    80006846:	078e                	slli	a5,a5,0x3
    80006848:	94be                	add	s1,s1,a5
    8000684a:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    8000684e:	fd043503          	ld	a0,-48(s0)
    80006852:	fffff097          	auipc	ra,0xfffff
    80006856:	9ea080e7          	jalr	-1558(ra) # 8000523c <fileclose>
    fileclose(wf);
    8000685a:	fc843503          	ld	a0,-56(s0)
    8000685e:	fffff097          	auipc	ra,0xfffff
    80006862:	9de080e7          	jalr	-1570(ra) # 8000523c <fileclose>
    return -1;
    80006866:	57fd                	li	a5,-1
}
    80006868:	853e                	mv	a0,a5
    8000686a:	70e2                	ld	ra,56(sp)
    8000686c:	7442                	ld	s0,48(sp)
    8000686e:	74a2                	ld	s1,40(sp)
    80006870:	6121                	addi	sp,sp,64
    80006872:	8082                	ret
	...

0000000080006880 <kernelvec>:
    80006880:	7111                	addi	sp,sp,-256
    80006882:	e006                	sd	ra,0(sp)
    80006884:	e40a                	sd	sp,8(sp)
    80006886:	e80e                	sd	gp,16(sp)
    80006888:	ec12                	sd	tp,24(sp)
    8000688a:	f016                	sd	t0,32(sp)
    8000688c:	f41a                	sd	t1,40(sp)
    8000688e:	f81e                	sd	t2,48(sp)
    80006890:	fc22                	sd	s0,56(sp)
    80006892:	e0a6                	sd	s1,64(sp)
    80006894:	e4aa                	sd	a0,72(sp)
    80006896:	e8ae                	sd	a1,80(sp)
    80006898:	ecb2                	sd	a2,88(sp)
    8000689a:	f0b6                	sd	a3,96(sp)
    8000689c:	f4ba                	sd	a4,104(sp)
    8000689e:	f8be                	sd	a5,112(sp)
    800068a0:	fcc2                	sd	a6,120(sp)
    800068a2:	e146                	sd	a7,128(sp)
    800068a4:	e54a                	sd	s2,136(sp)
    800068a6:	e94e                	sd	s3,144(sp)
    800068a8:	ed52                	sd	s4,152(sp)
    800068aa:	f156                	sd	s5,160(sp)
    800068ac:	f55a                	sd	s6,168(sp)
    800068ae:	f95e                	sd	s7,176(sp)
    800068b0:	fd62                	sd	s8,184(sp)
    800068b2:	e1e6                	sd	s9,192(sp)
    800068b4:	e5ea                	sd	s10,200(sp)
    800068b6:	e9ee                	sd	s11,208(sp)
    800068b8:	edf2                	sd	t3,216(sp)
    800068ba:	f1f6                	sd	t4,224(sp)
    800068bc:	f5fa                	sd	t5,232(sp)
    800068be:	f9fe                	sd	t6,240(sp)
    800068c0:	f56fc0ef          	jal	ra,80003016 <kerneltrap>
    800068c4:	6082                	ld	ra,0(sp)
    800068c6:	6122                	ld	sp,8(sp)
    800068c8:	61c2                	ld	gp,16(sp)
    800068ca:	7282                	ld	t0,32(sp)
    800068cc:	7322                	ld	t1,40(sp)
    800068ce:	73c2                	ld	t2,48(sp)
    800068d0:	7462                	ld	s0,56(sp)
    800068d2:	6486                	ld	s1,64(sp)
    800068d4:	6526                	ld	a0,72(sp)
    800068d6:	65c6                	ld	a1,80(sp)
    800068d8:	6666                	ld	a2,88(sp)
    800068da:	7686                	ld	a3,96(sp)
    800068dc:	7726                	ld	a4,104(sp)
    800068de:	77c6                	ld	a5,112(sp)
    800068e0:	7866                	ld	a6,120(sp)
    800068e2:	688a                	ld	a7,128(sp)
    800068e4:	692a                	ld	s2,136(sp)
    800068e6:	69ca                	ld	s3,144(sp)
    800068e8:	6a6a                	ld	s4,152(sp)
    800068ea:	7a8a                	ld	s5,160(sp)
    800068ec:	7b2a                	ld	s6,168(sp)
    800068ee:	7bca                	ld	s7,176(sp)
    800068f0:	7c6a                	ld	s8,184(sp)
    800068f2:	6c8e                	ld	s9,192(sp)
    800068f4:	6d2e                	ld	s10,200(sp)
    800068f6:	6dce                	ld	s11,208(sp)
    800068f8:	6e6e                	ld	t3,216(sp)
    800068fa:	7e8e                	ld	t4,224(sp)
    800068fc:	7f2e                	ld	t5,232(sp)
    800068fe:	7fce                	ld	t6,240(sp)
    80006900:	6111                	addi	sp,sp,256
    80006902:	10200073          	sret
    80006906:	00000013          	nop
    8000690a:	00000013          	nop
    8000690e:	0001                	nop

0000000080006910 <timervec>:
    80006910:	34051573          	csrrw	a0,mscratch,a0
    80006914:	e10c                	sd	a1,0(a0)
    80006916:	e510                	sd	a2,8(a0)
    80006918:	e914                	sd	a3,16(a0)
    8000691a:	6d0c                	ld	a1,24(a0)
    8000691c:	7110                	ld	a2,32(a0)
    8000691e:	6194                	ld	a3,0(a1)
    80006920:	96b2                	add	a3,a3,a2
    80006922:	e194                	sd	a3,0(a1)
    80006924:	4589                	li	a1,2
    80006926:	14459073          	csrw	sip,a1
    8000692a:	6914                	ld	a3,16(a0)
    8000692c:	6510                	ld	a2,8(a0)
    8000692e:	610c                	ld	a1,0(a0)
    80006930:	34051573          	csrrw	a0,mscratch,a0
    80006934:	30200073          	mret
	...

000000008000693a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000693a:	1141                	addi	sp,sp,-16
    8000693c:	e422                	sd	s0,8(sp)
    8000693e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006940:	0c0007b7          	lui	a5,0xc000
    80006944:	4705                	li	a4,1
    80006946:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006948:	c3d8                	sw	a4,4(a5)
}
    8000694a:	6422                	ld	s0,8(sp)
    8000694c:	0141                	addi	sp,sp,16
    8000694e:	8082                	ret

0000000080006950 <plicinithart>:

void
plicinithart(void)
{
    80006950:	1141                	addi	sp,sp,-16
    80006952:	e406                	sd	ra,8(sp)
    80006954:	e022                	sd	s0,0(sp)
    80006956:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006958:	ffffb097          	auipc	ra,0xffffb
    8000695c:	272080e7          	jalr	626(ra) # 80001bca <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006960:	0085171b          	slliw	a4,a0,0x8
    80006964:	0c0027b7          	lui	a5,0xc002
    80006968:	97ba                	add	a5,a5,a4
    8000696a:	40200713          	li	a4,1026
    8000696e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006972:	00d5151b          	slliw	a0,a0,0xd
    80006976:	0c2017b7          	lui	a5,0xc201
    8000697a:	953e                	add	a0,a0,a5
    8000697c:	00052023          	sw	zero,0(a0)
}
    80006980:	60a2                	ld	ra,8(sp)
    80006982:	6402                	ld	s0,0(sp)
    80006984:	0141                	addi	sp,sp,16
    80006986:	8082                	ret

0000000080006988 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006988:	1141                	addi	sp,sp,-16
    8000698a:	e406                	sd	ra,8(sp)
    8000698c:	e022                	sd	s0,0(sp)
    8000698e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006990:	ffffb097          	auipc	ra,0xffffb
    80006994:	23a080e7          	jalr	570(ra) # 80001bca <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006998:	00d5179b          	slliw	a5,a0,0xd
    8000699c:	0c201537          	lui	a0,0xc201
    800069a0:	953e                	add	a0,a0,a5
  return irq;
}
    800069a2:	4148                	lw	a0,4(a0)
    800069a4:	60a2                	ld	ra,8(sp)
    800069a6:	6402                	ld	s0,0(sp)
    800069a8:	0141                	addi	sp,sp,16
    800069aa:	8082                	ret

00000000800069ac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800069ac:	1101                	addi	sp,sp,-32
    800069ae:	ec06                	sd	ra,24(sp)
    800069b0:	e822                	sd	s0,16(sp)
    800069b2:	e426                	sd	s1,8(sp)
    800069b4:	1000                	addi	s0,sp,32
    800069b6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800069b8:	ffffb097          	auipc	ra,0xffffb
    800069bc:	212080e7          	jalr	530(ra) # 80001bca <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800069c0:	00d5151b          	slliw	a0,a0,0xd
    800069c4:	0c2017b7          	lui	a5,0xc201
    800069c8:	97aa                	add	a5,a5,a0
    800069ca:	c3c4                	sw	s1,4(a5)
}
    800069cc:	60e2                	ld	ra,24(sp)
    800069ce:	6442                	ld	s0,16(sp)
    800069d0:	64a2                	ld	s1,8(sp)
    800069d2:	6105                	addi	sp,sp,32
    800069d4:	8082                	ret

00000000800069d6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800069d6:	1141                	addi	sp,sp,-16
    800069d8:	e406                	sd	ra,8(sp)
    800069da:	e022                	sd	s0,0(sp)
    800069dc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800069de:	479d                	li	a5,7
    800069e0:	04a7cc63          	blt	a5,a0,80006a38 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800069e4:	0001e797          	auipc	a5,0x1e
    800069e8:	7b478793          	addi	a5,a5,1972 # 80025198 <disk>
    800069ec:	97aa                	add	a5,a5,a0
    800069ee:	0187c783          	lbu	a5,24(a5)
    800069f2:	ebb9                	bnez	a5,80006a48 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800069f4:	00451613          	slli	a2,a0,0x4
    800069f8:	0001e797          	auipc	a5,0x1e
    800069fc:	7a078793          	addi	a5,a5,1952 # 80025198 <disk>
    80006a00:	6394                	ld	a3,0(a5)
    80006a02:	96b2                	add	a3,a3,a2
    80006a04:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006a08:	6398                	ld	a4,0(a5)
    80006a0a:	9732                	add	a4,a4,a2
    80006a0c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006a10:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006a14:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006a18:	953e                	add	a0,a0,a5
    80006a1a:	4785                	li	a5,1
    80006a1c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80006a20:	0001e517          	auipc	a0,0x1e
    80006a24:	79050513          	addi	a0,a0,1936 # 800251b0 <disk+0x18>
    80006a28:	ffffc097          	auipc	ra,0xffffc
    80006a2c:	c2e080e7          	jalr	-978(ra) # 80002656 <wakeup>
}
    80006a30:	60a2                	ld	ra,8(sp)
    80006a32:	6402                	ld	s0,0(sp)
    80006a34:	0141                	addi	sp,sp,16
    80006a36:	8082                	ret
    panic("free_desc 1");
    80006a38:	00003517          	auipc	a0,0x3
    80006a3c:	f0850513          	addi	a0,a0,-248 # 80009940 <syscalls+0x318>
    80006a40:	ffffa097          	auipc	ra,0xffffa
    80006a44:	b04080e7          	jalr	-1276(ra) # 80000544 <panic>
    panic("free_desc 2");
    80006a48:	00003517          	auipc	a0,0x3
    80006a4c:	f0850513          	addi	a0,a0,-248 # 80009950 <syscalls+0x328>
    80006a50:	ffffa097          	auipc	ra,0xffffa
    80006a54:	af4080e7          	jalr	-1292(ra) # 80000544 <panic>

0000000080006a58 <virtio_disk_init>:
{
    80006a58:	1101                	addi	sp,sp,-32
    80006a5a:	ec06                	sd	ra,24(sp)
    80006a5c:	e822                	sd	s0,16(sp)
    80006a5e:	e426                	sd	s1,8(sp)
    80006a60:	e04a                	sd	s2,0(sp)
    80006a62:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006a64:	00003597          	auipc	a1,0x3
    80006a68:	efc58593          	addi	a1,a1,-260 # 80009960 <syscalls+0x338>
    80006a6c:	0001f517          	auipc	a0,0x1f
    80006a70:	85450513          	addi	a0,a0,-1964 # 800252c0 <disk+0x128>
    80006a74:	ffffa097          	auipc	ra,0xffffa
    80006a78:	0e6080e7          	jalr	230(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006a7c:	100017b7          	lui	a5,0x10001
    80006a80:	4398                	lw	a4,0(a5)
    80006a82:	2701                	sext.w	a4,a4
    80006a84:	747277b7          	lui	a5,0x74727
    80006a88:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006a8c:	14f71e63          	bne	a4,a5,80006be8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006a90:	100017b7          	lui	a5,0x10001
    80006a94:	43dc                	lw	a5,4(a5)
    80006a96:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006a98:	4709                	li	a4,2
    80006a9a:	14e79763          	bne	a5,a4,80006be8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006a9e:	100017b7          	lui	a5,0x10001
    80006aa2:	479c                	lw	a5,8(a5)
    80006aa4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006aa6:	14e79163          	bne	a5,a4,80006be8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006aaa:	100017b7          	lui	a5,0x10001
    80006aae:	47d8                	lw	a4,12(a5)
    80006ab0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006ab2:	554d47b7          	lui	a5,0x554d4
    80006ab6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006aba:	12f71763          	bne	a4,a5,80006be8 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006abe:	100017b7          	lui	a5,0x10001
    80006ac2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006ac6:	4705                	li	a4,1
    80006ac8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006aca:	470d                	li	a4,3
    80006acc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006ace:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006ad0:	c7ffe737          	lui	a4,0xc7ffe
    80006ad4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd8107>
    80006ad8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006ada:	2701                	sext.w	a4,a4
    80006adc:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006ade:	472d                	li	a4,11
    80006ae0:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006ae2:	0707a903          	lw	s2,112(a5)
    80006ae6:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006ae8:	00897793          	andi	a5,s2,8
    80006aec:	10078663          	beqz	a5,80006bf8 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006af0:	100017b7          	lui	a5,0x10001
    80006af4:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006af8:	43fc                	lw	a5,68(a5)
    80006afa:	2781                	sext.w	a5,a5
    80006afc:	10079663          	bnez	a5,80006c08 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006b00:	100017b7          	lui	a5,0x10001
    80006b04:	5bdc                	lw	a5,52(a5)
    80006b06:	2781                	sext.w	a5,a5
  if(max == 0)
    80006b08:	10078863          	beqz	a5,80006c18 <virtio_disk_init+0x1c0>
  if(max < NUM)
    80006b0c:	471d                	li	a4,7
    80006b0e:	10f77d63          	bgeu	a4,a5,80006c28 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80006b12:	ffffa097          	auipc	ra,0xffffa
    80006b16:	fe8080e7          	jalr	-24(ra) # 80000afa <kalloc>
    80006b1a:	0001e497          	auipc	s1,0x1e
    80006b1e:	67e48493          	addi	s1,s1,1662 # 80025198 <disk>
    80006b22:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006b24:	ffffa097          	auipc	ra,0xffffa
    80006b28:	fd6080e7          	jalr	-42(ra) # 80000afa <kalloc>
    80006b2c:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80006b2e:	ffffa097          	auipc	ra,0xffffa
    80006b32:	fcc080e7          	jalr	-52(ra) # 80000afa <kalloc>
    80006b36:	87aa                	mv	a5,a0
    80006b38:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006b3a:	6088                	ld	a0,0(s1)
    80006b3c:	cd75                	beqz	a0,80006c38 <virtio_disk_init+0x1e0>
    80006b3e:	0001e717          	auipc	a4,0x1e
    80006b42:	66273703          	ld	a4,1634(a4) # 800251a0 <disk+0x8>
    80006b46:	cb6d                	beqz	a4,80006c38 <virtio_disk_init+0x1e0>
    80006b48:	cbe5                	beqz	a5,80006c38 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    80006b4a:	6605                	lui	a2,0x1
    80006b4c:	4581                	li	a1,0
    80006b4e:	ffffa097          	auipc	ra,0xffffa
    80006b52:	198080e7          	jalr	408(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006b56:	0001e497          	auipc	s1,0x1e
    80006b5a:	64248493          	addi	s1,s1,1602 # 80025198 <disk>
    80006b5e:	6605                	lui	a2,0x1
    80006b60:	4581                	li	a1,0
    80006b62:	6488                	ld	a0,8(s1)
    80006b64:	ffffa097          	auipc	ra,0xffffa
    80006b68:	182080e7          	jalr	386(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    80006b6c:	6605                	lui	a2,0x1
    80006b6e:	4581                	li	a1,0
    80006b70:	6888                	ld	a0,16(s1)
    80006b72:	ffffa097          	auipc	ra,0xffffa
    80006b76:	174080e7          	jalr	372(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006b7a:	100017b7          	lui	a5,0x10001
    80006b7e:	4721                	li	a4,8
    80006b80:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006b82:	4098                	lw	a4,0(s1)
    80006b84:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006b88:	40d8                	lw	a4,4(s1)
    80006b8a:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80006b8e:	6498                	ld	a4,8(s1)
    80006b90:	0007069b          	sext.w	a3,a4
    80006b94:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006b98:	9701                	srai	a4,a4,0x20
    80006b9a:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80006b9e:	6898                	ld	a4,16(s1)
    80006ba0:	0007069b          	sext.w	a3,a4
    80006ba4:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006ba8:	9701                	srai	a4,a4,0x20
    80006baa:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80006bae:	4685                	li	a3,1
    80006bb0:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80006bb2:	4705                	li	a4,1
    80006bb4:	00d48c23          	sb	a3,24(s1)
    80006bb8:	00e48ca3          	sb	a4,25(s1)
    80006bbc:	00e48d23          	sb	a4,26(s1)
    80006bc0:	00e48da3          	sb	a4,27(s1)
    80006bc4:	00e48e23          	sb	a4,28(s1)
    80006bc8:	00e48ea3          	sb	a4,29(s1)
    80006bcc:	00e48f23          	sb	a4,30(s1)
    80006bd0:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006bd4:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006bd8:	0727a823          	sw	s2,112(a5)
}
    80006bdc:	60e2                	ld	ra,24(sp)
    80006bde:	6442                	ld	s0,16(sp)
    80006be0:	64a2                	ld	s1,8(sp)
    80006be2:	6902                	ld	s2,0(sp)
    80006be4:	6105                	addi	sp,sp,32
    80006be6:	8082                	ret
    panic("could not find virtio disk");
    80006be8:	00003517          	auipc	a0,0x3
    80006bec:	d8850513          	addi	a0,a0,-632 # 80009970 <syscalls+0x348>
    80006bf0:	ffffa097          	auipc	ra,0xffffa
    80006bf4:	954080e7          	jalr	-1708(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006bf8:	00003517          	auipc	a0,0x3
    80006bfc:	d9850513          	addi	a0,a0,-616 # 80009990 <syscalls+0x368>
    80006c00:	ffffa097          	auipc	ra,0xffffa
    80006c04:	944080e7          	jalr	-1724(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80006c08:	00003517          	auipc	a0,0x3
    80006c0c:	da850513          	addi	a0,a0,-600 # 800099b0 <syscalls+0x388>
    80006c10:	ffffa097          	auipc	ra,0xffffa
    80006c14:	934080e7          	jalr	-1740(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80006c18:	00003517          	auipc	a0,0x3
    80006c1c:	db850513          	addi	a0,a0,-584 # 800099d0 <syscalls+0x3a8>
    80006c20:	ffffa097          	auipc	ra,0xffffa
    80006c24:	924080e7          	jalr	-1756(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    80006c28:	00003517          	auipc	a0,0x3
    80006c2c:	dc850513          	addi	a0,a0,-568 # 800099f0 <syscalls+0x3c8>
    80006c30:	ffffa097          	auipc	ra,0xffffa
    80006c34:	914080e7          	jalr	-1772(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    80006c38:	00003517          	auipc	a0,0x3
    80006c3c:	dd850513          	addi	a0,a0,-552 # 80009a10 <syscalls+0x3e8>
    80006c40:	ffffa097          	auipc	ra,0xffffa
    80006c44:	904080e7          	jalr	-1788(ra) # 80000544 <panic>

0000000080006c48 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006c48:	7159                	addi	sp,sp,-112
    80006c4a:	f486                	sd	ra,104(sp)
    80006c4c:	f0a2                	sd	s0,96(sp)
    80006c4e:	eca6                	sd	s1,88(sp)
    80006c50:	e8ca                	sd	s2,80(sp)
    80006c52:	e4ce                	sd	s3,72(sp)
    80006c54:	e0d2                	sd	s4,64(sp)
    80006c56:	fc56                	sd	s5,56(sp)
    80006c58:	f85a                	sd	s6,48(sp)
    80006c5a:	f45e                	sd	s7,40(sp)
    80006c5c:	f062                	sd	s8,32(sp)
    80006c5e:	ec66                	sd	s9,24(sp)
    80006c60:	e86a                	sd	s10,16(sp)
    80006c62:	1880                	addi	s0,sp,112
    80006c64:	892a                	mv	s2,a0
    80006c66:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006c68:	00c52c83          	lw	s9,12(a0)
    80006c6c:	001c9c9b          	slliw	s9,s9,0x1
    80006c70:	1c82                	slli	s9,s9,0x20
    80006c72:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006c76:	0001e517          	auipc	a0,0x1e
    80006c7a:	64a50513          	addi	a0,a0,1610 # 800252c0 <disk+0x128>
    80006c7e:	ffffa097          	auipc	ra,0xffffa
    80006c82:	f6c080e7          	jalr	-148(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    80006c86:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006c88:	4ba1                	li	s7,8
      disk.free[i] = 0;
    80006c8a:	0001eb17          	auipc	s6,0x1e
    80006c8e:	50eb0b13          	addi	s6,s6,1294 # 80025198 <disk>
  for(int i = 0; i < 3; i++){
    80006c92:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006c94:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006c96:	0001ec17          	auipc	s8,0x1e
    80006c9a:	62ac0c13          	addi	s8,s8,1578 # 800252c0 <disk+0x128>
    80006c9e:	a8b5                	j	80006d1a <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    80006ca0:	00fb06b3          	add	a3,s6,a5
    80006ca4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006ca8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006caa:	0207c563          	bltz	a5,80006cd4 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006cae:	2485                	addiw	s1,s1,1
    80006cb0:	0711                	addi	a4,a4,4
    80006cb2:	1f548a63          	beq	s1,s5,80006ea6 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    80006cb6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006cb8:	0001e697          	auipc	a3,0x1e
    80006cbc:	4e068693          	addi	a3,a3,1248 # 80025198 <disk>
    80006cc0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006cc2:	0186c583          	lbu	a1,24(a3)
    80006cc6:	fde9                	bnez	a1,80006ca0 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006cc8:	2785                	addiw	a5,a5,1
    80006cca:	0685                	addi	a3,a3,1
    80006ccc:	ff779be3          	bne	a5,s7,80006cc2 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006cd0:	57fd                	li	a5,-1
    80006cd2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006cd4:	02905a63          	blez	s1,80006d08 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006cd8:	f9042503          	lw	a0,-112(s0)
    80006cdc:	00000097          	auipc	ra,0x0
    80006ce0:	cfa080e7          	jalr	-774(ra) # 800069d6 <free_desc>
      for(int j = 0; j < i; j++)
    80006ce4:	4785                	li	a5,1
    80006ce6:	0297d163          	bge	a5,s1,80006d08 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006cea:	f9442503          	lw	a0,-108(s0)
    80006cee:	00000097          	auipc	ra,0x0
    80006cf2:	ce8080e7          	jalr	-792(ra) # 800069d6 <free_desc>
      for(int j = 0; j < i; j++)
    80006cf6:	4789                	li	a5,2
    80006cf8:	0097d863          	bge	a5,s1,80006d08 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006cfc:	f9842503          	lw	a0,-104(s0)
    80006d00:	00000097          	auipc	ra,0x0
    80006d04:	cd6080e7          	jalr	-810(ra) # 800069d6 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006d08:	85e2                	mv	a1,s8
    80006d0a:	0001e517          	auipc	a0,0x1e
    80006d0e:	4a650513          	addi	a0,a0,1190 # 800251b0 <disk+0x18>
    80006d12:	ffffb097          	auipc	ra,0xffffb
    80006d16:	794080e7          	jalr	1940(ra) # 800024a6 <sleep>
  for(int i = 0; i < 3; i++){
    80006d1a:	f9040713          	addi	a4,s0,-112
    80006d1e:	84ce                	mv	s1,s3
    80006d20:	bf59                	j	80006cb6 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006d22:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    80006d26:	00479693          	slli	a3,a5,0x4
    80006d2a:	0001e797          	auipc	a5,0x1e
    80006d2e:	46e78793          	addi	a5,a5,1134 # 80025198 <disk>
    80006d32:	97b6                	add	a5,a5,a3
    80006d34:	4685                	li	a3,1
    80006d36:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006d38:	0001e597          	auipc	a1,0x1e
    80006d3c:	46058593          	addi	a1,a1,1120 # 80025198 <disk>
    80006d40:	00a60793          	addi	a5,a2,10
    80006d44:	0792                	slli	a5,a5,0x4
    80006d46:	97ae                	add	a5,a5,a1
    80006d48:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    80006d4c:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006d50:	f6070693          	addi	a3,a4,-160
    80006d54:	619c                	ld	a5,0(a1)
    80006d56:	97b6                	add	a5,a5,a3
    80006d58:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006d5a:	6188                	ld	a0,0(a1)
    80006d5c:	96aa                	add	a3,a3,a0
    80006d5e:	47c1                	li	a5,16
    80006d60:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006d62:	4785                	li	a5,1
    80006d64:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006d68:	f9442783          	lw	a5,-108(s0)
    80006d6c:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006d70:	0792                	slli	a5,a5,0x4
    80006d72:	953e                	add	a0,a0,a5
    80006d74:	05890693          	addi	a3,s2,88
    80006d78:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    80006d7a:	6188                	ld	a0,0(a1)
    80006d7c:	97aa                	add	a5,a5,a0
    80006d7e:	40000693          	li	a3,1024
    80006d82:	c794                	sw	a3,8(a5)
  if(write)
    80006d84:	100d0d63          	beqz	s10,80006e9e <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006d88:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006d8c:	00c7d683          	lhu	a3,12(a5)
    80006d90:	0016e693          	ori	a3,a3,1
    80006d94:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    80006d98:	f9842583          	lw	a1,-104(s0)
    80006d9c:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006da0:	0001e697          	auipc	a3,0x1e
    80006da4:	3f868693          	addi	a3,a3,1016 # 80025198 <disk>
    80006da8:	00260793          	addi	a5,a2,2
    80006dac:	0792                	slli	a5,a5,0x4
    80006dae:	97b6                	add	a5,a5,a3
    80006db0:	587d                	li	a6,-1
    80006db2:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006db6:	0592                	slli	a1,a1,0x4
    80006db8:	952e                	add	a0,a0,a1
    80006dba:	f9070713          	addi	a4,a4,-112
    80006dbe:	9736                	add	a4,a4,a3
    80006dc0:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    80006dc2:	6298                	ld	a4,0(a3)
    80006dc4:	972e                	add	a4,a4,a1
    80006dc6:	4585                	li	a1,1
    80006dc8:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006dca:	4509                	li	a0,2
    80006dcc:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    80006dd0:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006dd4:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006dd8:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006ddc:	6698                	ld	a4,8(a3)
    80006dde:	00275783          	lhu	a5,2(a4)
    80006de2:	8b9d                	andi	a5,a5,7
    80006de4:	0786                	slli	a5,a5,0x1
    80006de6:	97ba                	add	a5,a5,a4
    80006de8:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    80006dec:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006df0:	6698                	ld	a4,8(a3)
    80006df2:	00275783          	lhu	a5,2(a4)
    80006df6:	2785                	addiw	a5,a5,1
    80006df8:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006dfc:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006e00:	100017b7          	lui	a5,0x10001
    80006e04:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006e08:	00492703          	lw	a4,4(s2)
    80006e0c:	4785                	li	a5,1
    80006e0e:	02f71163          	bne	a4,a5,80006e30 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    80006e12:	0001e997          	auipc	s3,0x1e
    80006e16:	4ae98993          	addi	s3,s3,1198 # 800252c0 <disk+0x128>
  while(b->disk == 1) {
    80006e1a:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006e1c:	85ce                	mv	a1,s3
    80006e1e:	854a                	mv	a0,s2
    80006e20:	ffffb097          	auipc	ra,0xffffb
    80006e24:	686080e7          	jalr	1670(ra) # 800024a6 <sleep>
  while(b->disk == 1) {
    80006e28:	00492783          	lw	a5,4(s2)
    80006e2c:	fe9788e3          	beq	a5,s1,80006e1c <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    80006e30:	f9042903          	lw	s2,-112(s0)
    80006e34:	00290793          	addi	a5,s2,2
    80006e38:	00479713          	slli	a4,a5,0x4
    80006e3c:	0001e797          	auipc	a5,0x1e
    80006e40:	35c78793          	addi	a5,a5,860 # 80025198 <disk>
    80006e44:	97ba                	add	a5,a5,a4
    80006e46:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006e4a:	0001e997          	auipc	s3,0x1e
    80006e4e:	34e98993          	addi	s3,s3,846 # 80025198 <disk>
    80006e52:	00491713          	slli	a4,s2,0x4
    80006e56:	0009b783          	ld	a5,0(s3)
    80006e5a:	97ba                	add	a5,a5,a4
    80006e5c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006e60:	854a                	mv	a0,s2
    80006e62:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006e66:	00000097          	auipc	ra,0x0
    80006e6a:	b70080e7          	jalr	-1168(ra) # 800069d6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006e6e:	8885                	andi	s1,s1,1
    80006e70:	f0ed                	bnez	s1,80006e52 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006e72:	0001e517          	auipc	a0,0x1e
    80006e76:	44e50513          	addi	a0,a0,1102 # 800252c0 <disk+0x128>
    80006e7a:	ffffa097          	auipc	ra,0xffffa
    80006e7e:	e24080e7          	jalr	-476(ra) # 80000c9e <release>
}
    80006e82:	70a6                	ld	ra,104(sp)
    80006e84:	7406                	ld	s0,96(sp)
    80006e86:	64e6                	ld	s1,88(sp)
    80006e88:	6946                	ld	s2,80(sp)
    80006e8a:	69a6                	ld	s3,72(sp)
    80006e8c:	6a06                	ld	s4,64(sp)
    80006e8e:	7ae2                	ld	s5,56(sp)
    80006e90:	7b42                	ld	s6,48(sp)
    80006e92:	7ba2                	ld	s7,40(sp)
    80006e94:	7c02                	ld	s8,32(sp)
    80006e96:	6ce2                	ld	s9,24(sp)
    80006e98:	6d42                	ld	s10,16(sp)
    80006e9a:	6165                	addi	sp,sp,112
    80006e9c:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006e9e:	4689                	li	a3,2
    80006ea0:	00d79623          	sh	a3,12(a5)
    80006ea4:	b5e5                	j	80006d8c <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006ea6:	f9042603          	lw	a2,-112(s0)
    80006eaa:	00a60713          	addi	a4,a2,10
    80006eae:	0712                	slli	a4,a4,0x4
    80006eb0:	0001e517          	auipc	a0,0x1e
    80006eb4:	2f050513          	addi	a0,a0,752 # 800251a0 <disk+0x8>
    80006eb8:	953a                	add	a0,a0,a4
  if(write)
    80006eba:	e60d14e3          	bnez	s10,80006d22 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006ebe:	00a60793          	addi	a5,a2,10
    80006ec2:	00479693          	slli	a3,a5,0x4
    80006ec6:	0001e797          	auipc	a5,0x1e
    80006eca:	2d278793          	addi	a5,a5,722 # 80025198 <disk>
    80006ece:	97b6                	add	a5,a5,a3
    80006ed0:	0007a423          	sw	zero,8(a5)
    80006ed4:	b595                	j	80006d38 <virtio_disk_rw+0xf0>

0000000080006ed6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006ed6:	1101                	addi	sp,sp,-32
    80006ed8:	ec06                	sd	ra,24(sp)
    80006eda:	e822                	sd	s0,16(sp)
    80006edc:	e426                	sd	s1,8(sp)
    80006ede:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006ee0:	0001e497          	auipc	s1,0x1e
    80006ee4:	2b848493          	addi	s1,s1,696 # 80025198 <disk>
    80006ee8:	0001e517          	auipc	a0,0x1e
    80006eec:	3d850513          	addi	a0,a0,984 # 800252c0 <disk+0x128>
    80006ef0:	ffffa097          	auipc	ra,0xffffa
    80006ef4:	cfa080e7          	jalr	-774(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006ef8:	10001737          	lui	a4,0x10001
    80006efc:	533c                	lw	a5,96(a4)
    80006efe:	8b8d                	andi	a5,a5,3
    80006f00:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006f02:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006f06:	689c                	ld	a5,16(s1)
    80006f08:	0204d703          	lhu	a4,32(s1)
    80006f0c:	0027d783          	lhu	a5,2(a5)
    80006f10:	04f70863          	beq	a4,a5,80006f60 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006f14:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006f18:	6898                	ld	a4,16(s1)
    80006f1a:	0204d783          	lhu	a5,32(s1)
    80006f1e:	8b9d                	andi	a5,a5,7
    80006f20:	078e                	slli	a5,a5,0x3
    80006f22:	97ba                	add	a5,a5,a4
    80006f24:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006f26:	00278713          	addi	a4,a5,2
    80006f2a:	0712                	slli	a4,a4,0x4
    80006f2c:	9726                	add	a4,a4,s1
    80006f2e:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006f32:	e721                	bnez	a4,80006f7a <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006f34:	0789                	addi	a5,a5,2
    80006f36:	0792                	slli	a5,a5,0x4
    80006f38:	97a6                	add	a5,a5,s1
    80006f3a:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006f3c:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006f40:	ffffb097          	auipc	ra,0xffffb
    80006f44:	716080e7          	jalr	1814(ra) # 80002656 <wakeup>

    disk.used_idx += 1;
    80006f48:	0204d783          	lhu	a5,32(s1)
    80006f4c:	2785                	addiw	a5,a5,1
    80006f4e:	17c2                	slli	a5,a5,0x30
    80006f50:	93c1                	srli	a5,a5,0x30
    80006f52:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006f56:	6898                	ld	a4,16(s1)
    80006f58:	00275703          	lhu	a4,2(a4)
    80006f5c:	faf71ce3          	bne	a4,a5,80006f14 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006f60:	0001e517          	auipc	a0,0x1e
    80006f64:	36050513          	addi	a0,a0,864 # 800252c0 <disk+0x128>
    80006f68:	ffffa097          	auipc	ra,0xffffa
    80006f6c:	d36080e7          	jalr	-714(ra) # 80000c9e <release>
}
    80006f70:	60e2                	ld	ra,24(sp)
    80006f72:	6442                	ld	s0,16(sp)
    80006f74:	64a2                	ld	s1,8(sp)
    80006f76:	6105                	addi	sp,sp,32
    80006f78:	8082                	ret
      panic("virtio_disk_intr status");
    80006f7a:	00003517          	auipc	a0,0x3
    80006f7e:	aae50513          	addi	a0,a0,-1362 # 80009a28 <syscalls+0x400>
    80006f82:	ffff9097          	auipc	ra,0xffff9
    80006f86:	5c2080e7          	jalr	1474(ra) # 80000544 <panic>

0000000080006f8a <sgenrand>:
static int mti=N+1; /* mti==N+1 means mt[N] is not initialized */

/* initializing the array with a NONZERO seed */
void
sgenrand(unsigned long seed)
{
    80006f8a:	1141                	addi	sp,sp,-16
    80006f8c:	e422                	sd	s0,8(sp)
    80006f8e:	0800                	addi	s0,sp,16
    /* setting initial seeds to mt[N] using         */
    /* the generator Line 25 of Table 1 in          */
    /* [KNUTH 1981, The Art of Computer Programming */
    /*    Vol. 2 (2nd Ed.), pp102]                  */
    mt[0]= seed & 0xffffffff;
    80006f90:	0001e717          	auipc	a4,0x1e
    80006f94:	34870713          	addi	a4,a4,840 # 800252d8 <mt>
    80006f98:	1502                	slli	a0,a0,0x20
    80006f9a:	9101                	srli	a0,a0,0x20
    80006f9c:	e308                	sd	a0,0(a4)
    for (mti=1; mti<N; mti++)
    80006f9e:	0001f597          	auipc	a1,0x1f
    80006fa2:	6b258593          	addi	a1,a1,1714 # 80026650 <mt+0x1378>
        mt[mti] = (69069 * mt[mti-1]) & 0xffffffff;
    80006fa6:	6645                	lui	a2,0x11
    80006fa8:	dcd60613          	addi	a2,a2,-563 # 10dcd <_entry-0x7ffef233>
    80006fac:	56fd                	li	a3,-1
    80006fae:	9281                	srli	a3,a3,0x20
    80006fb0:	631c                	ld	a5,0(a4)
    80006fb2:	02c787b3          	mul	a5,a5,a2
    80006fb6:	8ff5                	and	a5,a5,a3
    80006fb8:	e71c                	sd	a5,8(a4)
    for (mti=1; mti<N; mti++)
    80006fba:	0721                	addi	a4,a4,8
    80006fbc:	feb71ae3          	bne	a4,a1,80006fb0 <sgenrand+0x26>
    80006fc0:	27000793          	li	a5,624
    80006fc4:	00003717          	auipc	a4,0x3
    80006fc8:	a8f72a23          	sw	a5,-1388(a4) # 80009a58 <mti>
}
    80006fcc:	6422                	ld	s0,8(sp)
    80006fce:	0141                	addi	sp,sp,16
    80006fd0:	8082                	ret

0000000080006fd2 <genrand>:

long /* for integer generation */
genrand()
{
    80006fd2:	1141                	addi	sp,sp,-16
    80006fd4:	e406                	sd	ra,8(sp)
    80006fd6:	e022                	sd	s0,0(sp)
    80006fd8:	0800                	addi	s0,sp,16
    unsigned long y;
    static unsigned long mag01[2]={0x0, MATRIX_A};
    /* mag01[x] = x * MATRIX_A  for x=0,1 */

    if (mti >= N) { /* generate N words at one time */
    80006fda:	00003797          	auipc	a5,0x3
    80006fde:	a7e7a783          	lw	a5,-1410(a5) # 80009a58 <mti>
    80006fe2:	26f00713          	li	a4,623
    80006fe6:	0ef75963          	bge	a4,a5,800070d8 <genrand+0x106>
        int kk;

        if (mti == N+1)   /* if sgenrand() has not been called, */
    80006fea:	27100713          	li	a4,625
    80006fee:	12e78f63          	beq	a5,a4,8000712c <genrand+0x15a>
            sgenrand(4357); /* a default initial seed is used   */

        for (kk=0;kk<N-M;kk++) {
    80006ff2:	0001e817          	auipc	a6,0x1e
    80006ff6:	2e680813          	addi	a6,a6,742 # 800252d8 <mt>
    80006ffa:	0001fe17          	auipc	t3,0x1f
    80006ffe:	9f6e0e13          	addi	t3,t3,-1546 # 800259f0 <mt+0x718>
{
    80007002:	8742                	mv	a4,a6
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    80007004:	4885                	li	a7,1
    80007006:	08fe                	slli	a7,a7,0x1f
    80007008:	80000537          	lui	a0,0x80000
    8000700c:	fff54513          	not	a0,a0
            mt[kk] = mt[kk+M] ^ (y >> 1) ^ mag01[y & 0x1];
    80007010:	6585                	lui	a1,0x1
    80007012:	c6858593          	addi	a1,a1,-920 # c68 <_entry-0x7ffff398>
    80007016:	00003317          	auipc	t1,0x3
    8000701a:	a2a30313          	addi	t1,t1,-1494 # 80009a40 <mag01.985>
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    8000701e:	631c                	ld	a5,0(a4)
    80007020:	0117f7b3          	and	a5,a5,a7
    80007024:	6714                	ld	a3,8(a4)
    80007026:	8ee9                	and	a3,a3,a0
    80007028:	8fd5                	or	a5,a5,a3
            mt[kk] = mt[kk+M] ^ (y >> 1) ^ mag01[y & 0x1];
    8000702a:	00b70633          	add	a2,a4,a1
    8000702e:	0017d693          	srli	a3,a5,0x1
    80007032:	6210                	ld	a2,0(a2)
    80007034:	8eb1                	xor	a3,a3,a2
    80007036:	8b85                	andi	a5,a5,1
    80007038:	078e                	slli	a5,a5,0x3
    8000703a:	979a                	add	a5,a5,t1
    8000703c:	639c                	ld	a5,0(a5)
    8000703e:	8fb5                	xor	a5,a5,a3
    80007040:	e31c                	sd	a5,0(a4)
        for (kk=0;kk<N-M;kk++) {
    80007042:	0721                	addi	a4,a4,8
    80007044:	fdc71de3          	bne	a4,t3,8000701e <genrand+0x4c>
        }
        for (;kk<N-1;kk++) {
    80007048:	6605                	lui	a2,0x1
    8000704a:	c6060613          	addi	a2,a2,-928 # c60 <_entry-0x7ffff3a0>
    8000704e:	9642                	add	a2,a2,a6
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    80007050:	4505                	li	a0,1
    80007052:	057e                	slli	a0,a0,0x1f
    80007054:	800005b7          	lui	a1,0x80000
    80007058:	fff5c593          	not	a1,a1
            mt[kk] = mt[kk+(M-N)] ^ (y >> 1) ^ mag01[y & 0x1];
    8000705c:	00003897          	auipc	a7,0x3
    80007060:	9e488893          	addi	a7,a7,-1564 # 80009a40 <mag01.985>
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    80007064:	71883783          	ld	a5,1816(a6)
    80007068:	8fe9                	and	a5,a5,a0
    8000706a:	72083703          	ld	a4,1824(a6)
    8000706e:	8f6d                	and	a4,a4,a1
    80007070:	8fd9                	or	a5,a5,a4
            mt[kk] = mt[kk+(M-N)] ^ (y >> 1) ^ mag01[y & 0x1];
    80007072:	0017d713          	srli	a4,a5,0x1
    80007076:	00083683          	ld	a3,0(a6)
    8000707a:	8f35                	xor	a4,a4,a3
    8000707c:	8b85                	andi	a5,a5,1
    8000707e:	078e                	slli	a5,a5,0x3
    80007080:	97c6                	add	a5,a5,a7
    80007082:	639c                	ld	a5,0(a5)
    80007084:	8fb9                	xor	a5,a5,a4
    80007086:	70f83c23          	sd	a5,1816(a6)
        for (;kk<N-1;kk++) {
    8000708a:	0821                	addi	a6,a6,8
    8000708c:	fcc81ce3          	bne	a6,a2,80007064 <genrand+0x92>
        }
        y = (mt[N-1]&UPPER_MASK)|(mt[0]&LOWER_MASK);
    80007090:	0001f697          	auipc	a3,0x1f
    80007094:	24868693          	addi	a3,a3,584 # 800262d8 <mt+0x1000>
    80007098:	3786b783          	ld	a5,888(a3)
    8000709c:	4705                	li	a4,1
    8000709e:	077e                	slli	a4,a4,0x1f
    800070a0:	8ff9                	and	a5,a5,a4
    800070a2:	0001e717          	auipc	a4,0x1e
    800070a6:	23673703          	ld	a4,566(a4) # 800252d8 <mt>
    800070aa:	1706                	slli	a4,a4,0x21
    800070ac:	9305                	srli	a4,a4,0x21
    800070ae:	8fd9                	or	a5,a5,a4
        mt[N-1] = mt[M-1] ^ (y >> 1) ^ mag01[y & 0x1];
    800070b0:	0017d713          	srli	a4,a5,0x1
    800070b4:	c606b603          	ld	a2,-928(a3)
    800070b8:	8f31                	xor	a4,a4,a2
    800070ba:	8b85                	andi	a5,a5,1
    800070bc:	078e                	slli	a5,a5,0x3
    800070be:	00003617          	auipc	a2,0x3
    800070c2:	98260613          	addi	a2,a2,-1662 # 80009a40 <mag01.985>
    800070c6:	97b2                	add	a5,a5,a2
    800070c8:	639c                	ld	a5,0(a5)
    800070ca:	8fb9                	xor	a5,a5,a4
    800070cc:	36f6bc23          	sd	a5,888(a3)

        mti = 0;
    800070d0:	00003797          	auipc	a5,0x3
    800070d4:	9807a423          	sw	zero,-1656(a5) # 80009a58 <mti>
    }
  
    y = mt[mti++];
    800070d8:	00003717          	auipc	a4,0x3
    800070dc:	98070713          	addi	a4,a4,-1664 # 80009a58 <mti>
    800070e0:	431c                	lw	a5,0(a4)
    800070e2:	0017869b          	addiw	a3,a5,1
    800070e6:	c314                	sw	a3,0(a4)
    800070e8:	078e                	slli	a5,a5,0x3
    800070ea:	0001e717          	auipc	a4,0x1e
    800070ee:	1ee70713          	addi	a4,a4,494 # 800252d8 <mt>
    800070f2:	97ba                	add	a5,a5,a4
    800070f4:	6398                	ld	a4,0(a5)
    y ^= TEMPERING_SHIFT_U(y);
    800070f6:	00b75793          	srli	a5,a4,0xb
    800070fa:	8f3d                	xor	a4,a4,a5
    y ^= TEMPERING_SHIFT_S(y) & TEMPERING_MASK_B;
    800070fc:	013a67b7          	lui	a5,0x13a6
    80007100:	8ad78793          	addi	a5,a5,-1875 # 13a58ad <_entry-0x7ec5a753>
    80007104:	8ff9                	and	a5,a5,a4
    80007106:	079e                	slli	a5,a5,0x7
    80007108:	8fb9                	xor	a5,a5,a4
    y ^= TEMPERING_SHIFT_T(y) & TEMPERING_MASK_C;
    8000710a:	00f79713          	slli	a4,a5,0xf
    8000710e:	077e36b7          	lui	a3,0x77e3
    80007112:	0696                	slli	a3,a3,0x5
    80007114:	8f75                	and	a4,a4,a3
    80007116:	8fb9                	xor	a5,a5,a4
    y ^= TEMPERING_SHIFT_L(y);
    80007118:	0127d513          	srli	a0,a5,0x12
    8000711c:	8fa9                	xor	a5,a5,a0

    // Strip off uppermost bit because we want a long,
    // not an unsigned long
    return y & RAND_MAX;
    8000711e:	02179513          	slli	a0,a5,0x21
}
    80007122:	9105                	srli	a0,a0,0x21
    80007124:	60a2                	ld	ra,8(sp)
    80007126:	6402                	ld	s0,0(sp)
    80007128:	0141                	addi	sp,sp,16
    8000712a:	8082                	ret
            sgenrand(4357); /* a default initial seed is used   */
    8000712c:	6505                	lui	a0,0x1
    8000712e:	10550513          	addi	a0,a0,261 # 1105 <_entry-0x7fffeefb>
    80007132:	00000097          	auipc	ra,0x0
    80007136:	e58080e7          	jalr	-424(ra) # 80006f8a <sgenrand>
    8000713a:	bd65                	j	80006ff2 <genrand+0x20>

000000008000713c <random>:

// Assumes 0 <= max <= RAND_MAX
// Returns in the half-open interval [0, max]
long random(long max) {
    8000713c:	1101                	addi	sp,sp,-32
    8000713e:	ec06                	sd	ra,24(sp)
    80007140:	e822                	sd	s0,16(sp)
    80007142:	e426                	sd	s1,8(sp)
    80007144:	1000                	addi	s0,sp,32
    80007146:	84aa                	mv	s1,a0
    unsigned long random = (unsigned long)((long)genrand() % (max + 1)); 
    80007148:	00000097          	auipc	ra,0x0
    8000714c:	e8a080e7          	jalr	-374(ra) # 80006fd2 <genrand>
    80007150:	0485                	addi	s1,s1,1
    return random;
    80007152:	02956533          	rem	a0,a0,s1
    80007156:	60e2                	ld	ra,24(sp)
    80007158:	6442                	ld	s0,16(sp)
    8000715a:	64a2                	ld	s1,8(sp)
    8000715c:	6105                	addi	sp,sp,32
    8000715e:	8082                	ret
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
