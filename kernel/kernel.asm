
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	b5813103          	ld	sp,-1192(sp) # 80009b58 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000056:	b5e70713          	addi	a4,a4,-1186 # 80009bb0 <timer_scratch>
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
    80000068:	85c78793          	addi	a5,a5,-1956 # 800068c0 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd81e7>
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
    80000130:	8e0080e7          	jalr	-1824(ra) # 80002a0c <either_copyin>
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
    80000190:	b6450513          	addi	a0,a0,-1180 # 80011cf0 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a56080e7          	jalr	-1450(ra) # 80000bea <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00012497          	auipc	s1,0x12
    800001a0:	b5448493          	addi	s1,s1,-1196 # 80011cf0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00012917          	auipc	s2,0x12
    800001aa:	be290913          	addi	s2,s2,-1054 # 80011d88 <cons+0x98>
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
    800001d0:	68a080e7          	jalr	1674(ra) # 80002856 <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	27c080e7          	jalr	636(ra) # 80002456 <sleep>
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
    8000021a:	7a0080e7          	jalr	1952(ra) # 800029b6 <either_copyout>
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
    8000022e:	ac650513          	addi	a0,a0,-1338 # 80011cf0 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a6c080e7          	jalr	-1428(ra) # 80000c9e <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00012517          	auipc	a0,0x12
    80000244:	ab050513          	addi	a0,a0,-1360 # 80011cf0 <cons>
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
    8000027c:	b0f72823          	sw	a5,-1264(a4) # 80011d88 <cons+0x98>
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
    800002d6:	a1e50513          	addi	a0,a0,-1506 # 80011cf0 <cons>
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
    800002fc:	76a080e7          	jalr	1898(ra) # 80002a62 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00012517          	auipc	a0,0x12
    80000304:	9f050513          	addi	a0,a0,-1552 # 80011cf0 <cons>
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
    80000328:	9cc70713          	addi	a4,a4,-1588 # 80011cf0 <cons>
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
    80000352:	9a278793          	addi	a5,a5,-1630 # 80011cf0 <cons>
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
    80000380:	a0c7a783          	lw	a5,-1524(a5) # 80011d88 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00012717          	auipc	a4,0x12
    80000394:	96070713          	addi	a4,a4,-1696 # 80011cf0 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00012497          	auipc	s1,0x12
    800003a4:	95048493          	addi	s1,s1,-1712 # 80011cf0 <cons>
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
    800003e0:	91470713          	addi	a4,a4,-1772 # 80011cf0 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00012717          	auipc	a4,0x12
    800003f6:	98f72f23          	sw	a5,-1634(a4) # 80011d90 <cons+0xa0>
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
    8000041c:	8d878793          	addi	a5,a5,-1832 # 80011cf0 <cons>
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
    80000440:	94c7a823          	sw	a2,-1712(a5) # 80011d8c <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00012517          	auipc	a0,0x12
    80000448:	94450513          	addi	a0,a0,-1724 # 80011d88 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	1ba080e7          	jalr	442(ra) # 80002606 <wakeup>
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
    8000046a:	88a50513          	addi	a0,a0,-1910 # 80011cf0 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	6ec080e7          	jalr	1772(ra) # 80000b5a <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00024797          	auipc	a5,0x24
    80000482:	c8278793          	addi	a5,a5,-894 # 80024100 <devsw>
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
    80000554:	8607a023          	sw	zero,-1952(a5) # 80011db0 <pr+0x18>
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
    80000588:	5ef72623          	sw	a5,1516(a4) # 80009b70 <panicked>
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
    800005c4:	7f0dad83          	lw	s11,2032(s11) # 80011db0 <pr+0x18>
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
    80000602:	79a50513          	addi	a0,a0,1946 # 80011d98 <pr>
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
    80000766:	63650513          	addi	a0,a0,1590 # 80011d98 <pr>
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
    80000782:	61a48493          	addi	s1,s1,1562 # 80011d98 <pr>
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
    800007e2:	5da50513          	addi	a0,a0,1498 # 80011db8 <uart_tx_lock>
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
    8000080e:	3667a783          	lw	a5,870(a5) # 80009b70 <panicked>
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
    8000084a:	33273703          	ld	a4,818(a4) # 80009b78 <uart_tx_r>
    8000084e:	00009797          	auipc	a5,0x9
    80000852:	3327b783          	ld	a5,818(a5) # 80009b80 <uart_tx_w>
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
    80000874:	548a0a13          	addi	s4,s4,1352 # 80011db8 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00009497          	auipc	s1,0x9
    8000087c:	30048493          	addi	s1,s1,768 # 80009b78 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00009997          	auipc	s3,0x9
    80000884:	30098993          	addi	s3,s3,768 # 80009b80 <uart_tx_w>
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
    800008aa:	d60080e7          	jalr	-672(ra) # 80002606 <wakeup>
    
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
    800008e6:	4d650513          	addi	a0,a0,1238 # 80011db8 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	300080e7          	jalr	768(ra) # 80000bea <acquire>
  if(panicked){
    800008f2:	00009797          	auipc	a5,0x9
    800008f6:	27e7a783          	lw	a5,638(a5) # 80009b70 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00009797          	auipc	a5,0x9
    80000900:	2847b783          	ld	a5,644(a5) # 80009b80 <uart_tx_w>
    80000904:	00009717          	auipc	a4,0x9
    80000908:	27473703          	ld	a4,628(a4) # 80009b78 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	4a8a0a13          	addi	s4,s4,1192 # 80011db8 <uart_tx_lock>
    80000918:	00009497          	auipc	s1,0x9
    8000091c:	26048493          	addi	s1,s1,608 # 80009b78 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00009917          	auipc	s2,0x9
    80000924:	26090913          	addi	s2,s2,608 # 80009b80 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00002097          	auipc	ra,0x2
    80000934:	b26080e7          	jalr	-1242(ra) # 80002456 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00011497          	auipc	s1,0x11
    8000094a:	47248493          	addi	s1,s1,1138 # 80011db8 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00009717          	auipc	a4,0x9
    8000095e:	22f73323          	sd	a5,550(a4) # 80009b80 <uart_tx_w>
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
    800009d4:	3e848493          	addi	s1,s1,1000 # 80011db8 <uart_tx_lock>
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
    80000a16:	c0678793          	addi	a5,a5,-1018 # 80026618 <end>
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
    80000a36:	3be90913          	addi	s2,s2,958 # 80011df0 <kmem>
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
    80000ad2:	32250513          	addi	a0,a0,802 # 80011df0 <kmem>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	084080e7          	jalr	132(ra) # 80000b5a <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ade:	45c5                	li	a1,17
    80000ae0:	05ee                	slli	a1,a1,0x1b
    80000ae2:	00026517          	auipc	a0,0x26
    80000ae6:	b3650513          	addi	a0,a0,-1226 # 80026618 <end>
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
    80000b08:	2ec48493          	addi	s1,s1,748 # 80011df0 <kmem>
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
    80000b20:	2d450513          	addi	a0,a0,724 # 80011df0 <kmem>
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
    80000b4c:	2a850513          	addi	a0,a0,680 # 80011df0 <kmem>
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
    80000ea8:	ce470713          	addi	a4,a4,-796 # 80009b88 <started>
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
    80000ede:	d36080e7          	jalr	-714(ra) # 80002c10 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00006097          	auipc	ra,0x6
    80000ee6:	a1e080e7          	jalr	-1506(ra) # 80006900 <plicinithart>
  }

  scheduler();        
    80000eea:	00001097          	auipc	ra,0x1
    80000eee:	25c080e7          	jalr	604(ra) # 80002146 <scheduler>
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
    80000f56:	c96080e7          	jalr	-874(ra) # 80002be8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00002097          	auipc	ra,0x2
    80000f5e:	cb6080e7          	jalr	-842(ra) # 80002c10 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00006097          	auipc	ra,0x6
    80000f66:	988080e7          	jalr	-1656(ra) # 800068ea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00006097          	auipc	ra,0x6
    80000f6e:	996080e7          	jalr	-1642(ra) # 80006900 <plicinithart>
    binit();         // buffer cache
    80000f72:	00003097          	auipc	ra,0x3
    80000f76:	b4e080e7          	jalr	-1202(ra) # 80003ac0 <binit>
    iinit();         // inode table
    80000f7a:	00003097          	auipc	ra,0x3
    80000f7e:	1f2080e7          	jalr	498(ra) # 8000416c <iinit>
    fileinit();      // file table
    80000f82:	00004097          	auipc	ra,0x4
    80000f86:	190080e7          	jalr	400(ra) # 80005112 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00006097          	auipc	ra,0x6
    80000f8e:	a7e080e7          	jalr	-1410(ra) # 80006a08 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	f92080e7          	jalr	-110(ra) # 80001f24 <userinit>
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    started = 1;
    80000f9e:	4785                	li	a5,1
    80000fa0:	00009717          	auipc	a4,0x9
    80000fa4:	bef72423          	sw	a5,-1048(a4) # 80009b88 <started>
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
    80000fb8:	bdc7b783          	ld	a5,-1060(a5) # 80009b90 <kernel_pagetable>
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
    80001274:	92a7b023          	sd	a0,-1760(a5) # 80009b90 <kernel_pagetable>
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
    80001860:	9e478793          	addi	a5,a5,-1564 # 80012240 <queues>
    80001864:	97b6                	add	a5,a5,a3
    80001866:	4790                	lw	a2,8(a5)
    80001868:	04000793          	li	a5,64
    8000186c:	06f60a63          	beq	a2,a5,800018e0 <enqueue+0x90>
    panic("Full queue");

  queues[idx].procs[queues[idx].back] = process;
    80001870:	00011597          	auipc	a1,0x11
    80001874:	9d058593          	addi	a1,a1,-1584 # 80012240 <queues>
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
    800018b2:	99278793          	addi	a5,a5,-1646 # 80012240 <queues>
    800018b6:	97ae                	add	a5,a5,a1
    800018b8:	c3d4                	sw	a3,4(a5)
  queues[idx].length++;
    800018ba:	21800793          	li	a5,536
    800018be:	02f70733          	mul	a4,a4,a5
    800018c2:	00011797          	auipc	a5,0x11
    800018c6:	97e78793          	addi	a5,a5,-1666 # 80012240 <queues>
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
    80001904:	94078793          	addi	a5,a5,-1728 # 80012240 <queues>
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
    80001920:	92470713          	addi	a4,a4,-1756 # 80012240 <queues>
    80001924:	9736                	add	a4,a4,a3
    80001926:	4718                	lw	a4,8(a4)
    80001928:	cb31                	beqz	a4,8000197c <dequeue+0x6c>
    panic("Empty queue");
  
  queues[idx].front++;
    8000192a:	21800693          	li	a3,536
    8000192e:	02d78633          	mul	a2,a5,a3
    80001932:	00011697          	auipc	a3,0x11
    80001936:	90e68693          	addi	a3,a3,-1778 # 80012240 <queues>
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
    80001958:	8ec60613          	addi	a2,a2,-1812 # 80012240 <queues>
    8000195c:	962e                	add	a2,a2,a1
    8000195e:	c214                	sw	a3,0(a2)
  queues[idx].length--;
    80001960:	21800693          	li	a3,536
    80001964:	02d787b3          	mul	a5,a5,a3
    80001968:	00011697          	auipc	a3,0x11
    8000196c:	8d868693          	addi	a3,a3,-1832 # 80012240 <queues>
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
    800019a0:	8a468693          	addi	a3,a3,-1884 # 80012240 <queues>
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
    800019c2:	88278793          	addi	a5,a5,-1918 # 80012240 <queues>
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
    800019d8:	86c60613          	addi	a2,a2,-1940 # 80012240 <queues>
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
    80001a44:	80078793          	addi	a5,a5,-2048 # 80012240 <queues>
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
    80001a6c:	00010797          	auipc	a5,0x10
    80001a70:	7d478793          	addi	a5,a5,2004 # 80012240 <queues>
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
    80001a9a:	22248493          	addi	s1,s1,546 # 80012cb8 <proc>
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
    80001ab4:	408a0a13          	addi	s4,s4,1032 # 80019eb8 <tickslock>
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
    80001b36:	2de50513          	addi	a0,a0,734 # 80011e10 <pid_lock>
    80001b3a:	fffff097          	auipc	ra,0xfffff
    80001b3e:	020080e7          	jalr	32(ra) # 80000b5a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001b42:	00007597          	auipc	a1,0x7
    80001b46:	6c658593          	addi	a1,a1,1734 # 80009208 <digits+0x1c8>
    80001b4a:	00010517          	auipc	a0,0x10
    80001b4e:	2de50513          	addi	a0,a0,734 # 80011e28 <wait_lock>
    80001b52:	fffff097          	auipc	ra,0xfffff
    80001b56:	008080e7          	jalr	8(ra) # 80000b5a <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b5a:	00011497          	auipc	s1,0x11
    80001b5e:	15e48493          	addi	s1,s1,350 # 80012cb8 <proc>
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
    80001b80:	33c98993          	addi	s3,s3,828 # 80019eb8 <tickslock>
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
    80001bea:	25a50513          	addi	a0,a0,602 # 80011e40 <cpus>
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
    80001c12:	20270713          	addi	a4,a4,514 # 80011e10 <pid_lock>
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
    80001c4a:	dca7a783          	lw	a5,-566(a5) # 80009a10 <first.1767>
    80001c4e:	eb89                	bnez	a5,80001c60 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001c50:	00001097          	auipc	ra,0x1
    80001c54:	fd8080e7          	jalr	-40(ra) # 80002c28 <usertrapret>
}
    80001c58:	60a2                	ld	ra,8(sp)
    80001c5a:	6402                	ld	s0,0(sp)
    80001c5c:	0141                	addi	sp,sp,16
    80001c5e:	8082                	ret
    first = 0;
    80001c60:	00008797          	auipc	a5,0x8
    80001c64:	da07a823          	sw	zero,-592(a5) # 80009a10 <first.1767>
    fsinit(ROOTDEV);
    80001c68:	4505                	li	a0,1
    80001c6a:	00002097          	auipc	ra,0x2
    80001c6e:	482080e7          	jalr	1154(ra) # 800040ec <fsinit>
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
    80001c84:	19090913          	addi	s2,s2,400 # 80011e10 <pid_lock>
    80001c88:	854a                	mv	a0,s2
    80001c8a:	fffff097          	auipc	ra,0xfffff
    80001c8e:	f60080e7          	jalr	-160(ra) # 80000bea <acquire>
  pid = nextpid;
    80001c92:	00008797          	auipc	a5,0x8
    80001c96:	d8278793          	addi	a5,a5,-638 # 80009a14 <nextpid>
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
    80001e1c:	ea048493          	addi	s1,s1,-352 # 80012cb8 <proc>
    80001e20:	00018917          	auipc	s2,0x18
    80001e24:	09890913          	addi	s2,s2,152 # 80019eb8 <tickslock>
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
    80001e4a:	a871                	j	80001ee6 <allocproc+0xda>
  p->pid = allocpid();
    80001e4c:	00000097          	auipc	ra,0x0
    80001e50:	e28080e7          	jalr	-472(ra) # 80001c74 <allocpid>
    80001e54:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001e56:	4685                	li	a3,1
    80001e58:	cc94                	sw	a3,24(s1)
  p->tick_creation_time = ticks;
    80001e5a:	00008797          	auipc	a5,0x8
    80001e5e:	d467a783          	lw	a5,-698(a5) # 80009ba0 <ticks>
    80001e62:	0007871b          	sext.w	a4,a5
    80001e66:	18e4a823          	sw	a4,400(s1)
  p->tickets = 1;
    80001e6a:	18d4aa23          	sw	a3,404(s1)
  p->priority_pbs = 60;
    80001e6e:	03c00693          	li	a3,60
    80001e72:	1ad4a023          	sw	a3,416(s1)
  p->niceness_var = 5;
    80001e76:	4695                	li	a3,5
    80001e78:	1ad4a223          	sw	a3,420(s1)
  p->start_time_pbs = ticks;
    80001e7c:	18e4ac23          	sw	a4,408(s1)
  p->number_times = 0;
    80001e80:	1804ae23          	sw	zero,412(s1)
  p->last_run_time = 0;
    80001e84:	1a04a623          	sw	zero,428(s1)
  p->last_sleep_time = 0;
    80001e88:	1a04a423          	sw	zero,424(s1)
  p->priority = 0;
    80001e8c:	1a04aa23          	sw	zero,436(s1)
  p->in_queue = 0;
    80001e90:	1a04ac23          	sw	zero,440(s1)
  p->curr_rtime = 0;
    80001e94:	1a04ae23          	sw	zero,444(s1)
  p->curr_wtime = 0;
    80001e98:	1c04a023          	sw	zero,448(s1)
  p->rtime = 0;
    80001e9c:	1604a423          	sw	zero,360(s1)
  p->ctime = ticks;
    80001ea0:	16f4a623          	sw	a5,364(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001ea4:	fffff097          	auipc	ra,0xfffff
    80001ea8:	c56080e7          	jalr	-938(ra) # 80000afa <kalloc>
    80001eac:	892a                	mv	s2,a0
    80001eae:	eca8                	sd	a0,88(s1)
    80001eb0:	c131                	beqz	a0,80001ef4 <allocproc+0xe8>
  p->pagetable = proc_pagetable(p);
    80001eb2:	8526                	mv	a0,s1
    80001eb4:	00000097          	auipc	ra,0x0
    80001eb8:	e06080e7          	jalr	-506(ra) # 80001cba <proc_pagetable>
    80001ebc:	892a                	mv	s2,a0
    80001ebe:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001ec0:	c531                	beqz	a0,80001f0c <allocproc+0x100>
  memset(&p->context, 0, sizeof(p->context));
    80001ec2:	07000613          	li	a2,112
    80001ec6:	4581                	li	a1,0
    80001ec8:	06048513          	addi	a0,s1,96
    80001ecc:	fffff097          	auipc	ra,0xfffff
    80001ed0:	e1a080e7          	jalr	-486(ra) # 80000ce6 <memset>
  p->context.ra = (uint64)forkret;
    80001ed4:	00000797          	auipc	a5,0x0
    80001ed8:	d5a78793          	addi	a5,a5,-678 # 80001c2e <forkret>
    80001edc:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001ede:	60bc                	ld	a5,64(s1)
    80001ee0:	6705                	lui	a4,0x1
    80001ee2:	97ba                	add	a5,a5,a4
    80001ee4:	f4bc                	sd	a5,104(s1)
}
    80001ee6:	8526                	mv	a0,s1
    80001ee8:	60e2                	ld	ra,24(sp)
    80001eea:	6442                	ld	s0,16(sp)
    80001eec:	64a2                	ld	s1,8(sp)
    80001eee:	6902                	ld	s2,0(sp)
    80001ef0:	6105                	addi	sp,sp,32
    80001ef2:	8082                	ret
    freeproc(p);
    80001ef4:	8526                	mv	a0,s1
    80001ef6:	00000097          	auipc	ra,0x0
    80001efa:	eb2080e7          	jalr	-334(ra) # 80001da8 <freeproc>
    release(&p->lock);
    80001efe:	8526                	mv	a0,s1
    80001f00:	fffff097          	auipc	ra,0xfffff
    80001f04:	d9e080e7          	jalr	-610(ra) # 80000c9e <release>
    return 0;
    80001f08:	84ca                	mv	s1,s2
    80001f0a:	bff1                	j	80001ee6 <allocproc+0xda>
    freeproc(p);
    80001f0c:	8526                	mv	a0,s1
    80001f0e:	00000097          	auipc	ra,0x0
    80001f12:	e9a080e7          	jalr	-358(ra) # 80001da8 <freeproc>
    release(&p->lock);
    80001f16:	8526                	mv	a0,s1
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	d86080e7          	jalr	-634(ra) # 80000c9e <release>
    return 0;
    80001f20:	84ca                	mv	s1,s2
    80001f22:	b7d1                	j	80001ee6 <allocproc+0xda>

0000000080001f24 <userinit>:
{
    80001f24:	1101                	addi	sp,sp,-32
    80001f26:	ec06                	sd	ra,24(sp)
    80001f28:	e822                	sd	s0,16(sp)
    80001f2a:	e426                	sd	s1,8(sp)
    80001f2c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001f2e:	00000097          	auipc	ra,0x0
    80001f32:	ede080e7          	jalr	-290(ra) # 80001e0c <allocproc>
    80001f36:	84aa                	mv	s1,a0
  initproc = p;
    80001f38:	00008797          	auipc	a5,0x8
    80001f3c:	c6a7b023          	sd	a0,-928(a5) # 80009b98 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001f40:	03400613          	li	a2,52
    80001f44:	00008597          	auipc	a1,0x8
    80001f48:	adc58593          	addi	a1,a1,-1316 # 80009a20 <initcode>
    80001f4c:	6928                	ld	a0,80(a0)
    80001f4e:	fffff097          	auipc	ra,0xfffff
    80001f52:	424080e7          	jalr	1060(ra) # 80001372 <uvmfirst>
  p->sz = PGSIZE;
    80001f56:	6785                	lui	a5,0x1
    80001f58:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001f5a:	6cb8                	ld	a4,88(s1)
    80001f5c:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001f60:	6cb8                	ld	a4,88(s1)
    80001f62:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f64:	4641                	li	a2,16
    80001f66:	00007597          	auipc	a1,0x7
    80001f6a:	2ba58593          	addi	a1,a1,698 # 80009220 <digits+0x1e0>
    80001f6e:	15848513          	addi	a0,s1,344
    80001f72:	fffff097          	auipc	ra,0xfffff
    80001f76:	ec6080e7          	jalr	-314(ra) # 80000e38 <safestrcpy>
  p->cwd = namei("/");
    80001f7a:	00007517          	auipc	a0,0x7
    80001f7e:	2b650513          	addi	a0,a0,694 # 80009230 <digits+0x1f0>
    80001f82:	00003097          	auipc	ra,0x3
    80001f86:	b8c080e7          	jalr	-1140(ra) # 80004b0e <namei>
    80001f8a:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001f8e:	478d                	li	a5,3
    80001f90:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001f92:	8526                	mv	a0,s1
    80001f94:	fffff097          	auipc	ra,0xfffff
    80001f98:	d0a080e7          	jalr	-758(ra) # 80000c9e <release>
}
    80001f9c:	60e2                	ld	ra,24(sp)
    80001f9e:	6442                	ld	s0,16(sp)
    80001fa0:	64a2                	ld	s1,8(sp)
    80001fa2:	6105                	addi	sp,sp,32
    80001fa4:	8082                	ret

0000000080001fa6 <growproc>:
{
    80001fa6:	1101                	addi	sp,sp,-32
    80001fa8:	ec06                	sd	ra,24(sp)
    80001faa:	e822                	sd	s0,16(sp)
    80001fac:	e426                	sd	s1,8(sp)
    80001fae:	e04a                	sd	s2,0(sp)
    80001fb0:	1000                	addi	s0,sp,32
    80001fb2:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001fb4:	00000097          	auipc	ra,0x0
    80001fb8:	c42080e7          	jalr	-958(ra) # 80001bf6 <myproc>
    80001fbc:	84aa                	mv	s1,a0
  sz = p->sz;
    80001fbe:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001fc0:	01204c63          	bgtz	s2,80001fd8 <growproc+0x32>
  } else if(n < 0){
    80001fc4:	02094663          	bltz	s2,80001ff0 <growproc+0x4a>
  p->sz = sz;
    80001fc8:	e4ac                	sd	a1,72(s1)
  return 0;
    80001fca:	4501                	li	a0,0
}
    80001fcc:	60e2                	ld	ra,24(sp)
    80001fce:	6442                	ld	s0,16(sp)
    80001fd0:	64a2                	ld	s1,8(sp)
    80001fd2:	6902                	ld	s2,0(sp)
    80001fd4:	6105                	addi	sp,sp,32
    80001fd6:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001fd8:	4691                	li	a3,4
    80001fda:	00b90633          	add	a2,s2,a1
    80001fde:	6928                	ld	a0,80(a0)
    80001fe0:	fffff097          	auipc	ra,0xfffff
    80001fe4:	44c080e7          	jalr	1100(ra) # 8000142c <uvmalloc>
    80001fe8:	85aa                	mv	a1,a0
    80001fea:	fd79                	bnez	a0,80001fc8 <growproc+0x22>
      return -1;
    80001fec:	557d                	li	a0,-1
    80001fee:	bff9                	j	80001fcc <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001ff0:	00b90633          	add	a2,s2,a1
    80001ff4:	6928                	ld	a0,80(a0)
    80001ff6:	fffff097          	auipc	ra,0xfffff
    80001ffa:	3ee080e7          	jalr	1006(ra) # 800013e4 <uvmdealloc>
    80001ffe:	85aa                	mv	a1,a0
    80002000:	b7e1                	j	80001fc8 <growproc+0x22>

0000000080002002 <fork>:
{
    80002002:	7179                	addi	sp,sp,-48
    80002004:	f406                	sd	ra,40(sp)
    80002006:	f022                	sd	s0,32(sp)
    80002008:	ec26                	sd	s1,24(sp)
    8000200a:	e84a                	sd	s2,16(sp)
    8000200c:	e44e                	sd	s3,8(sp)
    8000200e:	e052                	sd	s4,0(sp)
    80002010:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002012:	00000097          	auipc	ra,0x0
    80002016:	be4080e7          	jalr	-1052(ra) # 80001bf6 <myproc>
    8000201a:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    8000201c:	00000097          	auipc	ra,0x0
    80002020:	df0080e7          	jalr	-528(ra) # 80001e0c <allocproc>
    80002024:	10050f63          	beqz	a0,80002142 <fork+0x140>
    80002028:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    8000202a:	04893603          	ld	a2,72(s2)
    8000202e:	692c                	ld	a1,80(a0)
    80002030:	05093503          	ld	a0,80(s2)
    80002034:	fffff097          	auipc	ra,0xfffff
    80002038:	54c080e7          	jalr	1356(ra) # 80001580 <uvmcopy>
    8000203c:	04054a63          	bltz	a0,80002090 <fork+0x8e>
  np->sz = p->sz;
    80002040:	04893783          	ld	a5,72(s2)
    80002044:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80002048:	05893683          	ld	a3,88(s2)
    8000204c:	87b6                	mv	a5,a3
    8000204e:	0589b703          	ld	a4,88(s3)
    80002052:	12068693          	addi	a3,a3,288
    80002056:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    8000205a:	6788                	ld	a0,8(a5)
    8000205c:	6b8c                	ld	a1,16(a5)
    8000205e:	6f90                	ld	a2,24(a5)
    80002060:	01073023          	sd	a6,0(a4)
    80002064:	e708                	sd	a0,8(a4)
    80002066:	eb0c                	sd	a1,16(a4)
    80002068:	ef10                	sd	a2,24(a4)
    8000206a:	02078793          	addi	a5,a5,32
    8000206e:	02070713          	addi	a4,a4,32
    80002072:	fed792e3          	bne	a5,a3,80002056 <fork+0x54>
  np->trace_flag = p->trace_flag;
    80002076:	17492783          	lw	a5,372(s2)
    8000207a:	16f9aa23          	sw	a5,372(s3)
  np->trapframe->a0 = 0;
    8000207e:	0589b783          	ld	a5,88(s3)
    80002082:	0607b823          	sd	zero,112(a5)
    80002086:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    8000208a:	15000a13          	li	s4,336
    8000208e:	a03d                	j	800020bc <fork+0xba>
    freeproc(np);
    80002090:	854e                	mv	a0,s3
    80002092:	00000097          	auipc	ra,0x0
    80002096:	d16080e7          	jalr	-746(ra) # 80001da8 <freeproc>
    release(&np->lock);
    8000209a:	854e                	mv	a0,s3
    8000209c:	fffff097          	auipc	ra,0xfffff
    800020a0:	c02080e7          	jalr	-1022(ra) # 80000c9e <release>
    return -1;
    800020a4:	5a7d                	li	s4,-1
    800020a6:	a069                	j	80002130 <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    800020a8:	00003097          	auipc	ra,0x3
    800020ac:	0fc080e7          	jalr	252(ra) # 800051a4 <filedup>
    800020b0:	009987b3          	add	a5,s3,s1
    800020b4:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    800020b6:	04a1                	addi	s1,s1,8
    800020b8:	01448763          	beq	s1,s4,800020c6 <fork+0xc4>
    if(p->ofile[i])
    800020bc:	009907b3          	add	a5,s2,s1
    800020c0:	6388                	ld	a0,0(a5)
    800020c2:	f17d                	bnez	a0,800020a8 <fork+0xa6>
    800020c4:	bfcd                	j	800020b6 <fork+0xb4>
  np->cwd = idup(p->cwd);
    800020c6:	15093503          	ld	a0,336(s2)
    800020ca:	00002097          	auipc	ra,0x2
    800020ce:	260080e7          	jalr	608(ra) # 8000432a <idup>
    800020d2:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800020d6:	4641                	li	a2,16
    800020d8:	15890593          	addi	a1,s2,344
    800020dc:	15898513          	addi	a0,s3,344
    800020e0:	fffff097          	auipc	ra,0xfffff
    800020e4:	d58080e7          	jalr	-680(ra) # 80000e38 <safestrcpy>
  pid = np->pid;
    800020e8:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    800020ec:	854e                	mv	a0,s3
    800020ee:	fffff097          	auipc	ra,0xfffff
    800020f2:	bb0080e7          	jalr	-1104(ra) # 80000c9e <release>
  acquire(&wait_lock);
    800020f6:	00010497          	auipc	s1,0x10
    800020fa:	d3248493          	addi	s1,s1,-718 # 80011e28 <wait_lock>
    800020fe:	8526                	mv	a0,s1
    80002100:	fffff097          	auipc	ra,0xfffff
    80002104:	aea080e7          	jalr	-1302(ra) # 80000bea <acquire>
  np->parent = p;
    80002108:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    8000210c:	8526                	mv	a0,s1
    8000210e:	fffff097          	auipc	ra,0xfffff
    80002112:	b90080e7          	jalr	-1136(ra) # 80000c9e <release>
  acquire(&np->lock);
    80002116:	854e                	mv	a0,s3
    80002118:	fffff097          	auipc	ra,0xfffff
    8000211c:	ad2080e7          	jalr	-1326(ra) # 80000bea <acquire>
  np->state = RUNNABLE;
    80002120:	478d                	li	a5,3
    80002122:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80002126:	854e                	mv	a0,s3
    80002128:	fffff097          	auipc	ra,0xfffff
    8000212c:	b76080e7          	jalr	-1162(ra) # 80000c9e <release>
}
    80002130:	8552                	mv	a0,s4
    80002132:	70a2                	ld	ra,40(sp)
    80002134:	7402                	ld	s0,32(sp)
    80002136:	64e2                	ld	s1,24(sp)
    80002138:	6942                	ld	s2,16(sp)
    8000213a:	69a2                	ld	s3,8(sp)
    8000213c:	6a02                	ld	s4,0(sp)
    8000213e:	6145                	addi	sp,sp,48
    80002140:	8082                	ret
    return -1;
    80002142:	5a7d                	li	s4,-1
    80002144:	b7f5                	j	80002130 <fork+0x12e>

0000000080002146 <scheduler>:
{
    80002146:	7175                	addi	sp,sp,-144
    80002148:	e506                	sd	ra,136(sp)
    8000214a:	e122                	sd	s0,128(sp)
    8000214c:	fca6                	sd	s1,120(sp)
    8000214e:	f8ca                	sd	s2,112(sp)
    80002150:	f4ce                	sd	s3,104(sp)
    80002152:	f0d2                	sd	s4,96(sp)
    80002154:	ecd6                	sd	s5,88(sp)
    80002156:	e8da                	sd	s6,80(sp)
    80002158:	e4de                	sd	s7,72(sp)
    8000215a:	e0e2                	sd	s8,64(sp)
    8000215c:	fc66                	sd	s9,56(sp)
    8000215e:	f86a                	sd	s10,48(sp)
    80002160:	f46e                	sd	s11,40(sp)
    80002162:	0900                	addi	s0,sp,144
    80002164:	8792                	mv	a5,tp
  int id = r_tp();
    80002166:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002168:	00779693          	slli	a3,a5,0x7
    8000216c:	00010717          	auipc	a4,0x10
    80002170:	ca470713          	addi	a4,a4,-860 # 80011e10 <pid_lock>
    80002174:	9736                	add	a4,a4,a3
    80002176:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &proc_to_run->context);
    8000217a:	00010717          	auipc	a4,0x10
    8000217e:	cce70713          	addi	a4,a4,-818 # 80011e48 <cpus+0x8>
    80002182:	9736                	add	a4,a4,a3
    80002184:	f8e43023          	sd	a4,-128(s0)
      for (p = proc; p < &proc[NPROC]; p++)
    80002188:	00018a97          	auipc	s5,0x18
    8000218c:	d30a8a93          	addi	s5,s5,-720 # 80019eb8 <tickslock>
          p = queues[i].procs[queues[i].front];
    80002190:	00010c17          	auipc	s8,0x10
    80002194:	0b0c0c13          	addi	s8,s8,176 # 80012240 <queues>
        for(int j = 0; j < queues[i].length; j++)
    80002198:	f8043423          	sd	zero,-120(s0)
        c->proc = proc_to_run;
    8000219c:	00010717          	auipc	a4,0x10
    800021a0:	c7470713          	addi	a4,a4,-908 # 80011e10 <pid_lock>
    800021a4:	00d707b3          	add	a5,a4,a3
    800021a8:	f6f43c23          	sd	a5,-136(s0)
    800021ac:	a8c9                	j	8000227e <scheduler+0x138>
          enqueue(p);
    800021ae:	8526                	mv	a0,s1
    800021b0:	fffff097          	auipc	ra,0xfffff
    800021b4:	6a0080e7          	jalr	1696(ra) # 80001850 <enqueue>
        release(&p->lock);
    800021b8:	8526                	mv	a0,s1
    800021ba:	fffff097          	auipc	ra,0xfffff
    800021be:	ae4080e7          	jalr	-1308(ra) # 80000c9e <release>
      for (p = proc; p < &proc[NPROC]; p++)
    800021c2:	1c848493          	addi	s1,s1,456
    800021c6:	01548e63          	beq	s1,s5,800021e2 <scheduler+0x9c>
        acquire(&p->lock);
    800021ca:	8526                	mv	a0,s1
    800021cc:	fffff097          	auipc	ra,0xfffff
    800021d0:	a1e080e7          	jalr	-1506(ra) # 80000bea <acquire>
        if (p->state == RUNNABLE && p->in_queue == 0)
    800021d4:	4c9c                	lw	a5,24(s1)
    800021d6:	ff3791e3          	bne	a5,s3,800021b8 <scheduler+0x72>
    800021da:	1b84a783          	lw	a5,440(s1)
    800021de:	ffe9                	bnez	a5,800021b8 <scheduler+0x72>
    800021e0:	b7f9                	j	800021ae <scheduler+0x68>
    800021e2:	00010d17          	auipc	s10,0x10
    800021e6:	066d0d13          	addi	s10,s10,102 # 80012248 <queues+0x8>
      for (int i = 0; i < 5; i++)
    800021ea:	4c81                	li	s9,0
    800021ec:	a031                	j	800021f8 <scheduler+0xb2>
    800021ee:	2c85                	addiw	s9,s9,1
    800021f0:	218d0d13          	addi	s10,s10,536
    800021f4:	09bc8763          	beq	s9,s11,80002282 <scheduler+0x13c>
        for(int j = 0; j < queues[i].length; j++)
    800021f8:	8a6a                	mv	s4,s10
    800021fa:	000d2783          	lw	a5,0(s10)
    800021fe:	f8843903          	ld	s2,-120(s0)
    80002202:	fef056e3          	blez	a5,800021ee <scheduler+0xa8>
          p = queues[i].procs[queues[i].front];
    80002206:	004c9b13          	slli	s6,s9,0x4
    8000220a:	9b66                	add	s6,s6,s9
    8000220c:	0b0a                	slli	s6,s6,0x2
    8000220e:	419b0b33          	sub	s6,s6,s9
    80002212:	ff8a2783          	lw	a5,-8(s4)
    80002216:	97da                	add	a5,a5,s6
    80002218:	0789                	addi	a5,a5,2
    8000221a:	078e                	slli	a5,a5,0x3
    8000221c:	97e2                	add	a5,a5,s8
    8000221e:	6384                	ld	s1,0(a5)
          acquire(&p->lock);
    80002220:	8526                	mv	a0,s1
    80002222:	fffff097          	auipc	ra,0xfffff
    80002226:	9c8080e7          	jalr	-1592(ra) # 80000bea <acquire>
          dequeue(p);  // clear out all the processes as it goes through all the levels
    8000222a:	8526                	mv	a0,s1
    8000222c:	fffff097          	auipc	ra,0xfffff
    80002230:	6e4080e7          	jalr	1764(ra) # 80001910 <dequeue>
          p->in_queue = 0;
    80002234:	1a04ac23          	sw	zero,440(s1)
          if (p->state == RUNNABLE)
    80002238:	4c9c                	lw	a5,24(s1)
    8000223a:	01378d63          	beq	a5,s3,80002254 <scheduler+0x10e>
          release(&p->lock);
    8000223e:	8526                	mv	a0,s1
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	a5e080e7          	jalr	-1442(ra) # 80000c9e <release>
        for(int j = 0; j < queues[i].length; j++)
    80002248:	2905                	addiw	s2,s2,1
    8000224a:	000a2783          	lw	a5,0(s4)
    8000224e:	fcf942e3          	blt	s2,a5,80002212 <scheduler+0xcc>
    80002252:	bf71                	j	800021ee <scheduler+0xa8>
        proc_to_run->state = RUNNING;
    80002254:	4791                	li	a5,4
    80002256:	cc9c                	sw	a5,24(s1)
        c->proc = proc_to_run;
    80002258:	f7843903          	ld	s2,-136(s0)
    8000225c:	02993823          	sd	s1,48(s2)
        swtch(&c->context, &proc_to_run->context);
    80002260:	06048593          	addi	a1,s1,96
    80002264:	f8043503          	ld	a0,-128(s0)
    80002268:	00001097          	auipc	ra,0x1
    8000226c:	916080e7          	jalr	-1770(ra) # 80002b7e <swtch>
        c->proc = 0;
    80002270:	02093823          	sd	zero,48(s2)
        release(&proc_to_run->lock);
    80002274:	8526                	mv	a0,s1
    80002276:	fffff097          	auipc	ra,0xfffff
    8000227a:	a28080e7          	jalr	-1496(ra) # 80000c9e <release>
        if (p->state == RUNNABLE && p->in_queue == 0)
    8000227e:	498d                	li	s3,3
      for (int i = 0; i < 5; i++)
    80002280:	4d95                	li	s11,5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002282:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002286:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000228a:	10079073          	csrw	sstatus,a5
      for (p = proc; p < &proc[NPROC]; p++)
    8000228e:	00011497          	auipc	s1,0x11
    80002292:	a2a48493          	addi	s1,s1,-1494 # 80012cb8 <proc>
    80002296:	bf15                	j	800021ca <scheduler+0x84>

0000000080002298 <sched>:
{
    80002298:	7179                	addi	sp,sp,-48
    8000229a:	f406                	sd	ra,40(sp)
    8000229c:	f022                	sd	s0,32(sp)
    8000229e:	ec26                	sd	s1,24(sp)
    800022a0:	e84a                	sd	s2,16(sp)
    800022a2:	e44e                	sd	s3,8(sp)
    800022a4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800022a6:	00000097          	auipc	ra,0x0
    800022aa:	950080e7          	jalr	-1712(ra) # 80001bf6 <myproc>
    800022ae:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800022b0:	fffff097          	auipc	ra,0xfffff
    800022b4:	8c0080e7          	jalr	-1856(ra) # 80000b70 <holding>
    800022b8:	c93d                	beqz	a0,8000232e <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022ba:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800022bc:	2781                	sext.w	a5,a5
    800022be:	079e                	slli	a5,a5,0x7
    800022c0:	00010717          	auipc	a4,0x10
    800022c4:	b5070713          	addi	a4,a4,-1200 # 80011e10 <pid_lock>
    800022c8:	97ba                	add	a5,a5,a4
    800022ca:	0a87a703          	lw	a4,168(a5)
    800022ce:	4785                	li	a5,1
    800022d0:	06f71763          	bne	a4,a5,8000233e <sched+0xa6>
  if(p->state == RUNNING)
    800022d4:	4c98                	lw	a4,24(s1)
    800022d6:	4791                	li	a5,4
    800022d8:	06f70b63          	beq	a4,a5,8000234e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022dc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800022e0:	8b89                	andi	a5,a5,2
  if(intr_get())
    800022e2:	efb5                	bnez	a5,8000235e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022e4:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800022e6:	00010917          	auipc	s2,0x10
    800022ea:	b2a90913          	addi	s2,s2,-1238 # 80011e10 <pid_lock>
    800022ee:	2781                	sext.w	a5,a5
    800022f0:	079e                	slli	a5,a5,0x7
    800022f2:	97ca                	add	a5,a5,s2
    800022f4:	0ac7a983          	lw	s3,172(a5)
    800022f8:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800022fa:	2781                	sext.w	a5,a5
    800022fc:	079e                	slli	a5,a5,0x7
    800022fe:	00010597          	auipc	a1,0x10
    80002302:	b4a58593          	addi	a1,a1,-1206 # 80011e48 <cpus+0x8>
    80002306:	95be                	add	a1,a1,a5
    80002308:	06048513          	addi	a0,s1,96
    8000230c:	00001097          	auipc	ra,0x1
    80002310:	872080e7          	jalr	-1934(ra) # 80002b7e <swtch>
    80002314:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002316:	2781                	sext.w	a5,a5
    80002318:	079e                	slli	a5,a5,0x7
    8000231a:	97ca                	add	a5,a5,s2
    8000231c:	0b37a623          	sw	s3,172(a5)
}
    80002320:	70a2                	ld	ra,40(sp)
    80002322:	7402                	ld	s0,32(sp)
    80002324:	64e2                	ld	s1,24(sp)
    80002326:	6942                	ld	s2,16(sp)
    80002328:	69a2                	ld	s3,8(sp)
    8000232a:	6145                	addi	sp,sp,48
    8000232c:	8082                	ret
    panic("sched p->lock");
    8000232e:	00007517          	auipc	a0,0x7
    80002332:	f0a50513          	addi	a0,a0,-246 # 80009238 <digits+0x1f8>
    80002336:	ffffe097          	auipc	ra,0xffffe
    8000233a:	20e080e7          	jalr	526(ra) # 80000544 <panic>
    panic("sched locks");
    8000233e:	00007517          	auipc	a0,0x7
    80002342:	f0a50513          	addi	a0,a0,-246 # 80009248 <digits+0x208>
    80002346:	ffffe097          	auipc	ra,0xffffe
    8000234a:	1fe080e7          	jalr	510(ra) # 80000544 <panic>
    panic("sched running");
    8000234e:	00007517          	auipc	a0,0x7
    80002352:	f0a50513          	addi	a0,a0,-246 # 80009258 <digits+0x218>
    80002356:	ffffe097          	auipc	ra,0xffffe
    8000235a:	1ee080e7          	jalr	494(ra) # 80000544 <panic>
    panic("sched interruptible");
    8000235e:	00007517          	auipc	a0,0x7
    80002362:	f0a50513          	addi	a0,a0,-246 # 80009268 <digits+0x228>
    80002366:	ffffe097          	auipc	ra,0xffffe
    8000236a:	1de080e7          	jalr	478(ra) # 80000544 <panic>

000000008000236e <yield>:
{
    8000236e:	1101                	addi	sp,sp,-32
    80002370:	ec06                	sd	ra,24(sp)
    80002372:	e822                	sd	s0,16(sp)
    80002374:	e426                	sd	s1,8(sp)
    80002376:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002378:	00000097          	auipc	ra,0x0
    8000237c:	87e080e7          	jalr	-1922(ra) # 80001bf6 <myproc>
    80002380:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002382:	fffff097          	auipc	ra,0xfffff
    80002386:	868080e7          	jalr	-1944(ra) # 80000bea <acquire>
  p->state = RUNNABLE;
    8000238a:	478d                	li	a5,3
    8000238c:	cc9c                	sw	a5,24(s1)
  sched();
    8000238e:	00000097          	auipc	ra,0x0
    80002392:	f0a080e7          	jalr	-246(ra) # 80002298 <sched>
  release(&p->lock);
    80002396:	8526                	mv	a0,s1
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	906080e7          	jalr	-1786(ra) # 80000c9e <release>
}
    800023a0:	60e2                	ld	ra,24(sp)
    800023a2:	6442                	ld	s0,16(sp)
    800023a4:	64a2                	ld	s1,8(sp)
    800023a6:	6105                	addi	sp,sp,32
    800023a8:	8082                	ret

00000000800023aa <update_time>:
{
    800023aa:	7139                	addi	sp,sp,-64
    800023ac:	fc06                	sd	ra,56(sp)
    800023ae:	f822                	sd	s0,48(sp)
    800023b0:	f426                	sd	s1,40(sp)
    800023b2:	f04a                	sd	s2,32(sp)
    800023b4:	ec4e                	sd	s3,24(sp)
    800023b6:	e852                	sd	s4,16(sp)
    800023b8:	e456                	sd	s5,8(sp)
    800023ba:	0080                	addi	s0,sp,64
  for(p = proc; p < &proc[NPROC]; p++){
    800023bc:	00011497          	auipc	s1,0x11
    800023c0:	8fc48493          	addi	s1,s1,-1796 # 80012cb8 <proc>
    if(p->state == RUNNING) {
    800023c4:	4991                	li	s3,4
    else if(p->state == RUNNABLE) {
    800023c6:	4a0d                	li	s4,3
    if(p->curr_wtime >= 30 && p->state == RUNNABLE) {
    800023c8:	4af5                	li	s5,29
  for(p = proc; p < &proc[NPROC]; p++){
    800023ca:	00018917          	auipc	s2,0x18
    800023ce:	aee90913          	addi	s2,s2,-1298 # 80019eb8 <tickslock>
    800023d2:	a025                	j	800023fa <update_time+0x50>
      p->curr_rtime++;
    800023d4:	1bc4a783          	lw	a5,444(s1)
    800023d8:	2785                	addiw	a5,a5,1
    800023da:	1af4ae23          	sw	a5,444(s1)
      p->rtime++;
    800023de:	1684a783          	lw	a5,360(s1)
    800023e2:	2785                	addiw	a5,a5,1
    800023e4:	16f4a423          	sw	a5,360(s1)
    release(&p->lock);
    800023e8:	8526                	mv	a0,s1
    800023ea:	fffff097          	auipc	ra,0xfffff
    800023ee:	8b4080e7          	jalr	-1868(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023f2:	1c848493          	addi	s1,s1,456
    800023f6:	05248763          	beq	s1,s2,80002444 <update_time+0x9a>
    acquire(&p->lock);
    800023fa:	8526                	mv	a0,s1
    800023fc:	ffffe097          	auipc	ra,0xffffe
    80002400:	7ee080e7          	jalr	2030(ra) # 80000bea <acquire>
    if(p->state == RUNNING) {
    80002404:	4c9c                	lw	a5,24(s1)
    80002406:	fd3787e3          	beq	a5,s3,800023d4 <update_time+0x2a>
    else if(p->state == RUNNABLE) {
    8000240a:	fd479fe3          	bne	a5,s4,800023e8 <update_time+0x3e>
      p->curr_wtime++;
    8000240e:	1c04a783          	lw	a5,448(s1)
    80002412:	2785                	addiw	a5,a5,1
    80002414:	0007871b          	sext.w	a4,a5
    80002418:	1cf4a023          	sw	a5,448(s1)
    if(p->curr_wtime >= 30 && p->state == RUNNABLE) {
    8000241c:	fcead6e3          	bge	s5,a4,800023e8 <update_time+0x3e>
      if(p->in_queue != 0) {
    80002420:	1b84a783          	lw	a5,440(s1)
    80002424:	eb81                	bnez	a5,80002434 <update_time+0x8a>
      if(p->priority != 0) {
    80002426:	1b44a783          	lw	a5,436(s1)
    8000242a:	dfdd                	beqz	a5,800023e8 <update_time+0x3e>
        p->priority--;
    8000242c:	37fd                	addiw	a5,a5,-1
    8000242e:	1af4aa23          	sw	a5,436(s1)
    80002432:	bf5d                	j	800023e8 <update_time+0x3e>
        delqueue(p);
    80002434:	8526                	mv	a0,s1
    80002436:	fffff097          	auipc	ra,0xfffff
    8000243a:	576080e7          	jalr	1398(ra) # 800019ac <delqueue>
        p->in_queue = 0;
    8000243e:	1a04ac23          	sw	zero,440(s1)
    80002442:	b7d5                	j	80002426 <update_time+0x7c>
}
    80002444:	70e2                	ld	ra,56(sp)
    80002446:	7442                	ld	s0,48(sp)
    80002448:	74a2                	ld	s1,40(sp)
    8000244a:	7902                	ld	s2,32(sp)
    8000244c:	69e2                	ld	s3,24(sp)
    8000244e:	6a42                	ld	s4,16(sp)
    80002450:	6aa2                	ld	s5,8(sp)
    80002452:	6121                	addi	sp,sp,64
    80002454:	8082                	ret

0000000080002456 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002456:	7179                	addi	sp,sp,-48
    80002458:	f406                	sd	ra,40(sp)
    8000245a:	f022                	sd	s0,32(sp)
    8000245c:	ec26                	sd	s1,24(sp)
    8000245e:	e84a                	sd	s2,16(sp)
    80002460:	e44e                	sd	s3,8(sp)
    80002462:	1800                	addi	s0,sp,48
    80002464:	89aa                	mv	s3,a0
    80002466:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002468:	fffff097          	auipc	ra,0xfffff
    8000246c:	78e080e7          	jalr	1934(ra) # 80001bf6 <myproc>
    80002470:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002472:	ffffe097          	auipc	ra,0xffffe
    80002476:	778080e7          	jalr	1912(ra) # 80000bea <acquire>
  release(lk);
    8000247a:	854a                	mv	a0,s2
    8000247c:	fffff097          	auipc	ra,0xfffff
    80002480:	822080e7          	jalr	-2014(ra) # 80000c9e <release>

  // Go to sleep.
  p->chan = chan;
    80002484:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002488:	4789                	li	a5,2
    8000248a:	cc9c                	sw	a5,24(s1)

  sched();
    8000248c:	00000097          	auipc	ra,0x0
    80002490:	e0c080e7          	jalr	-500(ra) # 80002298 <sched>

  // Tidy up.
  p->chan = 0;
    80002494:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002498:	8526                	mv	a0,s1
    8000249a:	fffff097          	auipc	ra,0xfffff
    8000249e:	804080e7          	jalr	-2044(ra) # 80000c9e <release>
  acquire(lk);
    800024a2:	854a                	mv	a0,s2
    800024a4:	ffffe097          	auipc	ra,0xffffe
    800024a8:	746080e7          	jalr	1862(ra) # 80000bea <acquire>
}
    800024ac:	70a2                	ld	ra,40(sp)
    800024ae:	7402                	ld	s0,32(sp)
    800024b0:	64e2                	ld	s1,24(sp)
    800024b2:	6942                	ld	s2,16(sp)
    800024b4:	69a2                	ld	s3,8(sp)
    800024b6:	6145                	addi	sp,sp,48
    800024b8:	8082                	ret

00000000800024ba <waitx>:
{
    800024ba:	711d                	addi	sp,sp,-96
    800024bc:	ec86                	sd	ra,88(sp)
    800024be:	e8a2                	sd	s0,80(sp)
    800024c0:	e4a6                	sd	s1,72(sp)
    800024c2:	e0ca                	sd	s2,64(sp)
    800024c4:	fc4e                	sd	s3,56(sp)
    800024c6:	f852                	sd	s4,48(sp)
    800024c8:	f456                	sd	s5,40(sp)
    800024ca:	f05a                	sd	s6,32(sp)
    800024cc:	ec5e                	sd	s7,24(sp)
    800024ce:	e862                	sd	s8,16(sp)
    800024d0:	e466                	sd	s9,8(sp)
    800024d2:	e06a                	sd	s10,0(sp)
    800024d4:	1080                	addi	s0,sp,96
    800024d6:	8b2a                	mv	s6,a0
    800024d8:	8bae                	mv	s7,a1
    800024da:	8c32                	mv	s8,a2
  struct proc *p = myproc();
    800024dc:	fffff097          	auipc	ra,0xfffff
    800024e0:	71a080e7          	jalr	1818(ra) # 80001bf6 <myproc>
    800024e4:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800024e6:	00010517          	auipc	a0,0x10
    800024ea:	94250513          	addi	a0,a0,-1726 # 80011e28 <wait_lock>
    800024ee:	ffffe097          	auipc	ra,0xffffe
    800024f2:	6fc080e7          	jalr	1788(ra) # 80000bea <acquire>
    havekids = 0;
    800024f6:	4c81                	li	s9,0
        if(np->state == ZOMBIE){
    800024f8:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800024fa:	00018997          	auipc	s3,0x18
    800024fe:	9be98993          	addi	s3,s3,-1602 # 80019eb8 <tickslock>
        havekids = 1;
    80002502:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002504:	00010d17          	auipc	s10,0x10
    80002508:	924d0d13          	addi	s10,s10,-1756 # 80011e28 <wait_lock>
    havekids = 0;
    8000250c:	8766                	mv	a4,s9
    for(np = proc; np < &proc[NPROC]; np++){
    8000250e:	00010497          	auipc	s1,0x10
    80002512:	7aa48493          	addi	s1,s1,1962 # 80012cb8 <proc>
    80002516:	a059                	j	8000259c <waitx+0xe2>
          pid = np->pid;
    80002518:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    8000251c:	1684a703          	lw	a4,360(s1)
    80002520:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002524:	16c4a783          	lw	a5,364(s1)
    80002528:	9f3d                	addw	a4,a4,a5
    8000252a:	1704a783          	lw	a5,368(s1)
    8000252e:	9f99                	subw	a5,a5,a4
    80002530:	00fba023          	sw	a5,0(s7) # fffffffffffff000 <end+0xffffffff7ffd89e8>
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002534:	000b0e63          	beqz	s6,80002550 <waitx+0x96>
    80002538:	4691                	li	a3,4
    8000253a:	02c48613          	addi	a2,s1,44
    8000253e:	85da                	mv	a1,s6
    80002540:	05093503          	ld	a0,80(s2)
    80002544:	fffff097          	auipc	ra,0xfffff
    80002548:	140080e7          	jalr	320(ra) # 80001684 <copyout>
    8000254c:	02054563          	bltz	a0,80002576 <waitx+0xbc>
          freeproc(np);
    80002550:	8526                	mv	a0,s1
    80002552:	00000097          	auipc	ra,0x0
    80002556:	856080e7          	jalr	-1962(ra) # 80001da8 <freeproc>
          release(&np->lock);
    8000255a:	8526                	mv	a0,s1
    8000255c:	ffffe097          	auipc	ra,0xffffe
    80002560:	742080e7          	jalr	1858(ra) # 80000c9e <release>
          release(&wait_lock);
    80002564:	00010517          	auipc	a0,0x10
    80002568:	8c450513          	addi	a0,a0,-1852 # 80011e28 <wait_lock>
    8000256c:	ffffe097          	auipc	ra,0xffffe
    80002570:	732080e7          	jalr	1842(ra) # 80000c9e <release>
          return pid;
    80002574:	a09d                	j	800025da <waitx+0x120>
            release(&np->lock);
    80002576:	8526                	mv	a0,s1
    80002578:	ffffe097          	auipc	ra,0xffffe
    8000257c:	726080e7          	jalr	1830(ra) # 80000c9e <release>
            release(&wait_lock);
    80002580:	00010517          	auipc	a0,0x10
    80002584:	8a850513          	addi	a0,a0,-1880 # 80011e28 <wait_lock>
    80002588:	ffffe097          	auipc	ra,0xffffe
    8000258c:	716080e7          	jalr	1814(ra) # 80000c9e <release>
            return -1;
    80002590:	59fd                	li	s3,-1
    80002592:	a0a1                	j	800025da <waitx+0x120>
    for(np = proc; np < &proc[NPROC]; np++){
    80002594:	1c848493          	addi	s1,s1,456
    80002598:	03348463          	beq	s1,s3,800025c0 <waitx+0x106>
      if(np->parent == p){
    8000259c:	7c9c                	ld	a5,56(s1)
    8000259e:	ff279be3          	bne	a5,s2,80002594 <waitx+0xda>
        acquire(&np->lock);
    800025a2:	8526                	mv	a0,s1
    800025a4:	ffffe097          	auipc	ra,0xffffe
    800025a8:	646080e7          	jalr	1606(ra) # 80000bea <acquire>
        if(np->state == ZOMBIE){
    800025ac:	4c9c                	lw	a5,24(s1)
    800025ae:	f74785e3          	beq	a5,s4,80002518 <waitx+0x5e>
        release(&np->lock);
    800025b2:	8526                	mv	a0,s1
    800025b4:	ffffe097          	auipc	ra,0xffffe
    800025b8:	6ea080e7          	jalr	1770(ra) # 80000c9e <release>
        havekids = 1;
    800025bc:	8756                	mv	a4,s5
    800025be:	bfd9                	j	80002594 <waitx+0xda>
    if(!havekids || p->killed){
    800025c0:	c701                	beqz	a4,800025c8 <waitx+0x10e>
    800025c2:	02892783          	lw	a5,40(s2)
    800025c6:	cb8d                	beqz	a5,800025f8 <waitx+0x13e>
      release(&wait_lock);
    800025c8:	00010517          	auipc	a0,0x10
    800025cc:	86050513          	addi	a0,a0,-1952 # 80011e28 <wait_lock>
    800025d0:	ffffe097          	auipc	ra,0xffffe
    800025d4:	6ce080e7          	jalr	1742(ra) # 80000c9e <release>
      return -1;
    800025d8:	59fd                	li	s3,-1
}
    800025da:	854e                	mv	a0,s3
    800025dc:	60e6                	ld	ra,88(sp)
    800025de:	6446                	ld	s0,80(sp)
    800025e0:	64a6                	ld	s1,72(sp)
    800025e2:	6906                	ld	s2,64(sp)
    800025e4:	79e2                	ld	s3,56(sp)
    800025e6:	7a42                	ld	s4,48(sp)
    800025e8:	7aa2                	ld	s5,40(sp)
    800025ea:	7b02                	ld	s6,32(sp)
    800025ec:	6be2                	ld	s7,24(sp)
    800025ee:	6c42                	ld	s8,16(sp)
    800025f0:	6ca2                	ld	s9,8(sp)
    800025f2:	6d02                	ld	s10,0(sp)
    800025f4:	6125                	addi	sp,sp,96
    800025f6:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800025f8:	85ea                	mv	a1,s10
    800025fa:	854a                	mv	a0,s2
    800025fc:	00000097          	auipc	ra,0x0
    80002600:	e5a080e7          	jalr	-422(ra) # 80002456 <sleep>
    havekids = 0;
    80002604:	b721                	j	8000250c <waitx+0x52>

0000000080002606 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002606:	7139                	addi	sp,sp,-64
    80002608:	fc06                	sd	ra,56(sp)
    8000260a:	f822                	sd	s0,48(sp)
    8000260c:	f426                	sd	s1,40(sp)
    8000260e:	f04a                	sd	s2,32(sp)
    80002610:	ec4e                	sd	s3,24(sp)
    80002612:	e852                	sd	s4,16(sp)
    80002614:	e456                	sd	s5,8(sp)
    80002616:	0080                	addi	s0,sp,64
    80002618:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000261a:	00010497          	auipc	s1,0x10
    8000261e:	69e48493          	addi	s1,s1,1694 # 80012cb8 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002622:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002624:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002626:	00018917          	auipc	s2,0x18
    8000262a:	89290913          	addi	s2,s2,-1902 # 80019eb8 <tickslock>
    8000262e:	a821                	j	80002646 <wakeup+0x40>
        p->state = RUNNABLE;
    80002630:	0154ac23          	sw	s5,24(s1)
        // #ifdef MLFQ
		    //   enqueue(p);
	      // #endif
      }
      release(&p->lock);
    80002634:	8526                	mv	a0,s1
    80002636:	ffffe097          	auipc	ra,0xffffe
    8000263a:	668080e7          	jalr	1640(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000263e:	1c848493          	addi	s1,s1,456
    80002642:	03248463          	beq	s1,s2,8000266a <wakeup+0x64>
    if(p != myproc()){
    80002646:	fffff097          	auipc	ra,0xfffff
    8000264a:	5b0080e7          	jalr	1456(ra) # 80001bf6 <myproc>
    8000264e:	fea488e3          	beq	s1,a0,8000263e <wakeup+0x38>
      acquire(&p->lock);
    80002652:	8526                	mv	a0,s1
    80002654:	ffffe097          	auipc	ra,0xffffe
    80002658:	596080e7          	jalr	1430(ra) # 80000bea <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000265c:	4c9c                	lw	a5,24(s1)
    8000265e:	fd379be3          	bne	a5,s3,80002634 <wakeup+0x2e>
    80002662:	709c                	ld	a5,32(s1)
    80002664:	fd4798e3          	bne	a5,s4,80002634 <wakeup+0x2e>
    80002668:	b7e1                	j	80002630 <wakeup+0x2a>
    }
  }
}
    8000266a:	70e2                	ld	ra,56(sp)
    8000266c:	7442                	ld	s0,48(sp)
    8000266e:	74a2                	ld	s1,40(sp)
    80002670:	7902                	ld	s2,32(sp)
    80002672:	69e2                	ld	s3,24(sp)
    80002674:	6a42                	ld	s4,16(sp)
    80002676:	6aa2                	ld	s5,8(sp)
    80002678:	6121                	addi	sp,sp,64
    8000267a:	8082                	ret

000000008000267c <reparent>:
{
    8000267c:	7179                	addi	sp,sp,-48
    8000267e:	f406                	sd	ra,40(sp)
    80002680:	f022                	sd	s0,32(sp)
    80002682:	ec26                	sd	s1,24(sp)
    80002684:	e84a                	sd	s2,16(sp)
    80002686:	e44e                	sd	s3,8(sp)
    80002688:	e052                	sd	s4,0(sp)
    8000268a:	1800                	addi	s0,sp,48
    8000268c:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000268e:	00010497          	auipc	s1,0x10
    80002692:	62a48493          	addi	s1,s1,1578 # 80012cb8 <proc>
      pp->parent = initproc;
    80002696:	00007a17          	auipc	s4,0x7
    8000269a:	502a0a13          	addi	s4,s4,1282 # 80009b98 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000269e:	00018997          	auipc	s3,0x18
    800026a2:	81a98993          	addi	s3,s3,-2022 # 80019eb8 <tickslock>
    800026a6:	a029                	j	800026b0 <reparent+0x34>
    800026a8:	1c848493          	addi	s1,s1,456
    800026ac:	01348d63          	beq	s1,s3,800026c6 <reparent+0x4a>
    if(pp->parent == p){
    800026b0:	7c9c                	ld	a5,56(s1)
    800026b2:	ff279be3          	bne	a5,s2,800026a8 <reparent+0x2c>
      pp->parent = initproc;
    800026b6:	000a3503          	ld	a0,0(s4)
    800026ba:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800026bc:	00000097          	auipc	ra,0x0
    800026c0:	f4a080e7          	jalr	-182(ra) # 80002606 <wakeup>
    800026c4:	b7d5                	j	800026a8 <reparent+0x2c>
}
    800026c6:	70a2                	ld	ra,40(sp)
    800026c8:	7402                	ld	s0,32(sp)
    800026ca:	64e2                	ld	s1,24(sp)
    800026cc:	6942                	ld	s2,16(sp)
    800026ce:	69a2                	ld	s3,8(sp)
    800026d0:	6a02                	ld	s4,0(sp)
    800026d2:	6145                	addi	sp,sp,48
    800026d4:	8082                	ret

00000000800026d6 <exit>:
{
    800026d6:	7179                	addi	sp,sp,-48
    800026d8:	f406                	sd	ra,40(sp)
    800026da:	f022                	sd	s0,32(sp)
    800026dc:	ec26                	sd	s1,24(sp)
    800026de:	e84a                	sd	s2,16(sp)
    800026e0:	e44e                	sd	s3,8(sp)
    800026e2:	e052                	sd	s4,0(sp)
    800026e4:	1800                	addi	s0,sp,48
    800026e6:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800026e8:	fffff097          	auipc	ra,0xfffff
    800026ec:	50e080e7          	jalr	1294(ra) # 80001bf6 <myproc>
    800026f0:	89aa                	mv	s3,a0
  if(p == initproc)
    800026f2:	00007797          	auipc	a5,0x7
    800026f6:	4a67b783          	ld	a5,1190(a5) # 80009b98 <initproc>
    800026fa:	0d050493          	addi	s1,a0,208
    800026fe:	15050913          	addi	s2,a0,336
    80002702:	02a79363          	bne	a5,a0,80002728 <exit+0x52>
    panic("init exiting");
    80002706:	00007517          	auipc	a0,0x7
    8000270a:	b7a50513          	addi	a0,a0,-1158 # 80009280 <digits+0x240>
    8000270e:	ffffe097          	auipc	ra,0xffffe
    80002712:	e36080e7          	jalr	-458(ra) # 80000544 <panic>
      fileclose(f);
    80002716:	00003097          	auipc	ra,0x3
    8000271a:	ae0080e7          	jalr	-1312(ra) # 800051f6 <fileclose>
      p->ofile[fd] = 0;
    8000271e:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002722:	04a1                	addi	s1,s1,8
    80002724:	01248563          	beq	s1,s2,8000272e <exit+0x58>
    if(p->ofile[fd]){
    80002728:	6088                	ld	a0,0(s1)
    8000272a:	f575                	bnez	a0,80002716 <exit+0x40>
    8000272c:	bfdd                	j	80002722 <exit+0x4c>
  begin_op();
    8000272e:	00002097          	auipc	ra,0x2
    80002732:	5fc080e7          	jalr	1532(ra) # 80004d2a <begin_op>
  iput(p->cwd);
    80002736:	1509b503          	ld	a0,336(s3)
    8000273a:	00002097          	auipc	ra,0x2
    8000273e:	de8080e7          	jalr	-536(ra) # 80004522 <iput>
  end_op();
    80002742:	00002097          	auipc	ra,0x2
    80002746:	668080e7          	jalr	1640(ra) # 80004daa <end_op>
  p->cwd = 0;
    8000274a:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000274e:	0000f497          	auipc	s1,0xf
    80002752:	6da48493          	addi	s1,s1,1754 # 80011e28 <wait_lock>
    80002756:	8526                	mv	a0,s1
    80002758:	ffffe097          	auipc	ra,0xffffe
    8000275c:	492080e7          	jalr	1170(ra) # 80000bea <acquire>
  reparent(p);
    80002760:	854e                	mv	a0,s3
    80002762:	00000097          	auipc	ra,0x0
    80002766:	f1a080e7          	jalr	-230(ra) # 8000267c <reparent>
  wakeup(p->parent);
    8000276a:	0389b503          	ld	a0,56(s3)
    8000276e:	00000097          	auipc	ra,0x0
    80002772:	e98080e7          	jalr	-360(ra) # 80002606 <wakeup>
  acquire(&p->lock);
    80002776:	854e                	mv	a0,s3
    80002778:	ffffe097          	auipc	ra,0xffffe
    8000277c:	472080e7          	jalr	1138(ra) # 80000bea <acquire>
  p->xstate = status;
    80002780:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002784:	4795                	li	a5,5
    80002786:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    8000278a:	00007797          	auipc	a5,0x7
    8000278e:	4167a783          	lw	a5,1046(a5) # 80009ba0 <ticks>
    80002792:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    80002796:	8526                	mv	a0,s1
    80002798:	ffffe097          	auipc	ra,0xffffe
    8000279c:	506080e7          	jalr	1286(ra) # 80000c9e <release>
  sched();
    800027a0:	00000097          	auipc	ra,0x0
    800027a4:	af8080e7          	jalr	-1288(ra) # 80002298 <sched>
  panic("zombie exit");
    800027a8:	00007517          	auipc	a0,0x7
    800027ac:	ae850513          	addi	a0,a0,-1304 # 80009290 <digits+0x250>
    800027b0:	ffffe097          	auipc	ra,0xffffe
    800027b4:	d94080e7          	jalr	-620(ra) # 80000544 <panic>

00000000800027b8 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800027b8:	7179                	addi	sp,sp,-48
    800027ba:	f406                	sd	ra,40(sp)
    800027bc:	f022                	sd	s0,32(sp)
    800027be:	ec26                	sd	s1,24(sp)
    800027c0:	e84a                	sd	s2,16(sp)
    800027c2:	e44e                	sd	s3,8(sp)
    800027c4:	1800                	addi	s0,sp,48
    800027c6:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800027c8:	00010497          	auipc	s1,0x10
    800027cc:	4f048493          	addi	s1,s1,1264 # 80012cb8 <proc>
    800027d0:	00017997          	auipc	s3,0x17
    800027d4:	6e898993          	addi	s3,s3,1768 # 80019eb8 <tickslock>
    acquire(&p->lock);
    800027d8:	8526                	mv	a0,s1
    800027da:	ffffe097          	auipc	ra,0xffffe
    800027de:	410080e7          	jalr	1040(ra) # 80000bea <acquire>
    if(p->pid == pid){
    800027e2:	589c                	lw	a5,48(s1)
    800027e4:	01278d63          	beq	a5,s2,800027fe <kill+0x46>
	      // #endif
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800027e8:	8526                	mv	a0,s1
    800027ea:	ffffe097          	auipc	ra,0xffffe
    800027ee:	4b4080e7          	jalr	1204(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800027f2:	1c848493          	addi	s1,s1,456
    800027f6:	ff3491e3          	bne	s1,s3,800027d8 <kill+0x20>
  }
  return -1;
    800027fa:	557d                	li	a0,-1
    800027fc:	a829                	j	80002816 <kill+0x5e>
      p->killed = 1;
    800027fe:	4785                	li	a5,1
    80002800:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002802:	4c98                	lw	a4,24(s1)
    80002804:	4789                	li	a5,2
    80002806:	00f70f63          	beq	a4,a5,80002824 <kill+0x6c>
      release(&p->lock);
    8000280a:	8526                	mv	a0,s1
    8000280c:	ffffe097          	auipc	ra,0xffffe
    80002810:	492080e7          	jalr	1170(ra) # 80000c9e <release>
      return 0;
    80002814:	4501                	li	a0,0
}
    80002816:	70a2                	ld	ra,40(sp)
    80002818:	7402                	ld	s0,32(sp)
    8000281a:	64e2                	ld	s1,24(sp)
    8000281c:	6942                	ld	s2,16(sp)
    8000281e:	69a2                	ld	s3,8(sp)
    80002820:	6145                	addi	sp,sp,48
    80002822:	8082                	ret
        p->state = RUNNABLE;
    80002824:	478d                	li	a5,3
    80002826:	cc9c                	sw	a5,24(s1)
    80002828:	b7cd                	j	8000280a <kill+0x52>

000000008000282a <setkilled>:

void
setkilled(struct proc *p)
{
    8000282a:	1101                	addi	sp,sp,-32
    8000282c:	ec06                	sd	ra,24(sp)
    8000282e:	e822                	sd	s0,16(sp)
    80002830:	e426                	sd	s1,8(sp)
    80002832:	1000                	addi	s0,sp,32
    80002834:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002836:	ffffe097          	auipc	ra,0xffffe
    8000283a:	3b4080e7          	jalr	948(ra) # 80000bea <acquire>
  p->killed = 1;
    8000283e:	4785                	li	a5,1
    80002840:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002842:	8526                	mv	a0,s1
    80002844:	ffffe097          	auipc	ra,0xffffe
    80002848:	45a080e7          	jalr	1114(ra) # 80000c9e <release>
}
    8000284c:	60e2                	ld	ra,24(sp)
    8000284e:	6442                	ld	s0,16(sp)
    80002850:	64a2                	ld	s1,8(sp)
    80002852:	6105                	addi	sp,sp,32
    80002854:	8082                	ret

0000000080002856 <killed>:

int
killed(struct proc *p)
{
    80002856:	1101                	addi	sp,sp,-32
    80002858:	ec06                	sd	ra,24(sp)
    8000285a:	e822                	sd	s0,16(sp)
    8000285c:	e426                	sd	s1,8(sp)
    8000285e:	e04a                	sd	s2,0(sp)
    80002860:	1000                	addi	s0,sp,32
    80002862:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002864:	ffffe097          	auipc	ra,0xffffe
    80002868:	386080e7          	jalr	902(ra) # 80000bea <acquire>
  k = p->killed;
    8000286c:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002870:	8526                	mv	a0,s1
    80002872:	ffffe097          	auipc	ra,0xffffe
    80002876:	42c080e7          	jalr	1068(ra) # 80000c9e <release>
  return k;
}
    8000287a:	854a                	mv	a0,s2
    8000287c:	60e2                	ld	ra,24(sp)
    8000287e:	6442                	ld	s0,16(sp)
    80002880:	64a2                	ld	s1,8(sp)
    80002882:	6902                	ld	s2,0(sp)
    80002884:	6105                	addi	sp,sp,32
    80002886:	8082                	ret

0000000080002888 <wait>:
{
    80002888:	715d                	addi	sp,sp,-80
    8000288a:	e486                	sd	ra,72(sp)
    8000288c:	e0a2                	sd	s0,64(sp)
    8000288e:	fc26                	sd	s1,56(sp)
    80002890:	f84a                	sd	s2,48(sp)
    80002892:	f44e                	sd	s3,40(sp)
    80002894:	f052                	sd	s4,32(sp)
    80002896:	ec56                	sd	s5,24(sp)
    80002898:	e85a                	sd	s6,16(sp)
    8000289a:	e45e                	sd	s7,8(sp)
    8000289c:	e062                	sd	s8,0(sp)
    8000289e:	0880                	addi	s0,sp,80
    800028a0:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800028a2:	fffff097          	auipc	ra,0xfffff
    800028a6:	354080e7          	jalr	852(ra) # 80001bf6 <myproc>
    800028aa:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800028ac:	0000f517          	auipc	a0,0xf
    800028b0:	57c50513          	addi	a0,a0,1404 # 80011e28 <wait_lock>
    800028b4:	ffffe097          	auipc	ra,0xffffe
    800028b8:	336080e7          	jalr	822(ra) # 80000bea <acquire>
    havekids = 0;
    800028bc:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    800028be:	4a15                	li	s4,5
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800028c0:	00017997          	auipc	s3,0x17
    800028c4:	5f898993          	addi	s3,s3,1528 # 80019eb8 <tickslock>
        havekids = 1;
    800028c8:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800028ca:	0000fc17          	auipc	s8,0xf
    800028ce:	55ec0c13          	addi	s8,s8,1374 # 80011e28 <wait_lock>
    havekids = 0;
    800028d2:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800028d4:	00010497          	auipc	s1,0x10
    800028d8:	3e448493          	addi	s1,s1,996 # 80012cb8 <proc>
    800028dc:	a0bd                	j	8000294a <wait+0xc2>
          pid = pp->pid;
    800028de:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800028e2:	000b0e63          	beqz	s6,800028fe <wait+0x76>
    800028e6:	4691                	li	a3,4
    800028e8:	02c48613          	addi	a2,s1,44
    800028ec:	85da                	mv	a1,s6
    800028ee:	05093503          	ld	a0,80(s2)
    800028f2:	fffff097          	auipc	ra,0xfffff
    800028f6:	d92080e7          	jalr	-622(ra) # 80001684 <copyout>
    800028fa:	02054563          	bltz	a0,80002924 <wait+0x9c>
          freeproc(pp);
    800028fe:	8526                	mv	a0,s1
    80002900:	fffff097          	auipc	ra,0xfffff
    80002904:	4a8080e7          	jalr	1192(ra) # 80001da8 <freeproc>
          release(&pp->lock);
    80002908:	8526                	mv	a0,s1
    8000290a:	ffffe097          	auipc	ra,0xffffe
    8000290e:	394080e7          	jalr	916(ra) # 80000c9e <release>
          release(&wait_lock);
    80002912:	0000f517          	auipc	a0,0xf
    80002916:	51650513          	addi	a0,a0,1302 # 80011e28 <wait_lock>
    8000291a:	ffffe097          	auipc	ra,0xffffe
    8000291e:	384080e7          	jalr	900(ra) # 80000c9e <release>
          return pid;
    80002922:	a0b5                	j	8000298e <wait+0x106>
            release(&pp->lock);
    80002924:	8526                	mv	a0,s1
    80002926:	ffffe097          	auipc	ra,0xffffe
    8000292a:	378080e7          	jalr	888(ra) # 80000c9e <release>
            release(&wait_lock);
    8000292e:	0000f517          	auipc	a0,0xf
    80002932:	4fa50513          	addi	a0,a0,1274 # 80011e28 <wait_lock>
    80002936:	ffffe097          	auipc	ra,0xffffe
    8000293a:	368080e7          	jalr	872(ra) # 80000c9e <release>
            return -1;
    8000293e:	59fd                	li	s3,-1
    80002940:	a0b9                	j	8000298e <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002942:	1c848493          	addi	s1,s1,456
    80002946:	03348463          	beq	s1,s3,8000296e <wait+0xe6>
      if(pp->parent == p){
    8000294a:	7c9c                	ld	a5,56(s1)
    8000294c:	ff279be3          	bne	a5,s2,80002942 <wait+0xba>
        acquire(&pp->lock);
    80002950:	8526                	mv	a0,s1
    80002952:	ffffe097          	auipc	ra,0xffffe
    80002956:	298080e7          	jalr	664(ra) # 80000bea <acquire>
        if(pp->state == ZOMBIE){
    8000295a:	4c9c                	lw	a5,24(s1)
    8000295c:	f94781e3          	beq	a5,s4,800028de <wait+0x56>
        release(&pp->lock);
    80002960:	8526                	mv	a0,s1
    80002962:	ffffe097          	auipc	ra,0xffffe
    80002966:	33c080e7          	jalr	828(ra) # 80000c9e <release>
        havekids = 1;
    8000296a:	8756                	mv	a4,s5
    8000296c:	bfd9                	j	80002942 <wait+0xba>
    if(!havekids || killed(p)){
    8000296e:	c719                	beqz	a4,8000297c <wait+0xf4>
    80002970:	854a                	mv	a0,s2
    80002972:	00000097          	auipc	ra,0x0
    80002976:	ee4080e7          	jalr	-284(ra) # 80002856 <killed>
    8000297a:	c51d                	beqz	a0,800029a8 <wait+0x120>
      release(&wait_lock);
    8000297c:	0000f517          	auipc	a0,0xf
    80002980:	4ac50513          	addi	a0,a0,1196 # 80011e28 <wait_lock>
    80002984:	ffffe097          	auipc	ra,0xffffe
    80002988:	31a080e7          	jalr	794(ra) # 80000c9e <release>
      return -1;
    8000298c:	59fd                	li	s3,-1
}
    8000298e:	854e                	mv	a0,s3
    80002990:	60a6                	ld	ra,72(sp)
    80002992:	6406                	ld	s0,64(sp)
    80002994:	74e2                	ld	s1,56(sp)
    80002996:	7942                	ld	s2,48(sp)
    80002998:	79a2                	ld	s3,40(sp)
    8000299a:	7a02                	ld	s4,32(sp)
    8000299c:	6ae2                	ld	s5,24(sp)
    8000299e:	6b42                	ld	s6,16(sp)
    800029a0:	6ba2                	ld	s7,8(sp)
    800029a2:	6c02                	ld	s8,0(sp)
    800029a4:	6161                	addi	sp,sp,80
    800029a6:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800029a8:	85e2                	mv	a1,s8
    800029aa:	854a                	mv	a0,s2
    800029ac:	00000097          	auipc	ra,0x0
    800029b0:	aaa080e7          	jalr	-1366(ra) # 80002456 <sleep>
    havekids = 0;
    800029b4:	bf39                	j	800028d2 <wait+0x4a>

00000000800029b6 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800029b6:	7179                	addi	sp,sp,-48
    800029b8:	f406                	sd	ra,40(sp)
    800029ba:	f022                	sd	s0,32(sp)
    800029bc:	ec26                	sd	s1,24(sp)
    800029be:	e84a                	sd	s2,16(sp)
    800029c0:	e44e                	sd	s3,8(sp)
    800029c2:	e052                	sd	s4,0(sp)
    800029c4:	1800                	addi	s0,sp,48
    800029c6:	84aa                	mv	s1,a0
    800029c8:	892e                	mv	s2,a1
    800029ca:	89b2                	mv	s3,a2
    800029cc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800029ce:	fffff097          	auipc	ra,0xfffff
    800029d2:	228080e7          	jalr	552(ra) # 80001bf6 <myproc>
  if(user_dst){
    800029d6:	c08d                	beqz	s1,800029f8 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800029d8:	86d2                	mv	a3,s4
    800029da:	864e                	mv	a2,s3
    800029dc:	85ca                	mv	a1,s2
    800029de:	6928                	ld	a0,80(a0)
    800029e0:	fffff097          	auipc	ra,0xfffff
    800029e4:	ca4080e7          	jalr	-860(ra) # 80001684 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800029e8:	70a2                	ld	ra,40(sp)
    800029ea:	7402                	ld	s0,32(sp)
    800029ec:	64e2                	ld	s1,24(sp)
    800029ee:	6942                	ld	s2,16(sp)
    800029f0:	69a2                	ld	s3,8(sp)
    800029f2:	6a02                	ld	s4,0(sp)
    800029f4:	6145                	addi	sp,sp,48
    800029f6:	8082                	ret
    memmove((char *)dst, src, len);
    800029f8:	000a061b          	sext.w	a2,s4
    800029fc:	85ce                	mv	a1,s3
    800029fe:	854a                	mv	a0,s2
    80002a00:	ffffe097          	auipc	ra,0xffffe
    80002a04:	346080e7          	jalr	838(ra) # 80000d46 <memmove>
    return 0;
    80002a08:	8526                	mv	a0,s1
    80002a0a:	bff9                	j	800029e8 <either_copyout+0x32>

0000000080002a0c <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002a0c:	7179                	addi	sp,sp,-48
    80002a0e:	f406                	sd	ra,40(sp)
    80002a10:	f022                	sd	s0,32(sp)
    80002a12:	ec26                	sd	s1,24(sp)
    80002a14:	e84a                	sd	s2,16(sp)
    80002a16:	e44e                	sd	s3,8(sp)
    80002a18:	e052                	sd	s4,0(sp)
    80002a1a:	1800                	addi	s0,sp,48
    80002a1c:	892a                	mv	s2,a0
    80002a1e:	84ae                	mv	s1,a1
    80002a20:	89b2                	mv	s3,a2
    80002a22:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a24:	fffff097          	auipc	ra,0xfffff
    80002a28:	1d2080e7          	jalr	466(ra) # 80001bf6 <myproc>
  if(user_src){
    80002a2c:	c08d                	beqz	s1,80002a4e <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002a2e:	86d2                	mv	a3,s4
    80002a30:	864e                	mv	a2,s3
    80002a32:	85ca                	mv	a1,s2
    80002a34:	6928                	ld	a0,80(a0)
    80002a36:	fffff097          	auipc	ra,0xfffff
    80002a3a:	cda080e7          	jalr	-806(ra) # 80001710 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002a3e:	70a2                	ld	ra,40(sp)
    80002a40:	7402                	ld	s0,32(sp)
    80002a42:	64e2                	ld	s1,24(sp)
    80002a44:	6942                	ld	s2,16(sp)
    80002a46:	69a2                	ld	s3,8(sp)
    80002a48:	6a02                	ld	s4,0(sp)
    80002a4a:	6145                	addi	sp,sp,48
    80002a4c:	8082                	ret
    memmove(dst, (char*)src, len);
    80002a4e:	000a061b          	sext.w	a2,s4
    80002a52:	85ce                	mv	a1,s3
    80002a54:	854a                	mv	a0,s2
    80002a56:	ffffe097          	auipc	ra,0xffffe
    80002a5a:	2f0080e7          	jalr	752(ra) # 80000d46 <memmove>
    return 0;
    80002a5e:	8526                	mv	a0,s1
    80002a60:	bff9                	j	80002a3e <either_copyin+0x32>

0000000080002a62 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002a62:	715d                	addi	sp,sp,-80
    80002a64:	e486                	sd	ra,72(sp)
    80002a66:	e0a2                	sd	s0,64(sp)
    80002a68:	fc26                	sd	s1,56(sp)
    80002a6a:	f84a                	sd	s2,48(sp)
    80002a6c:	f44e                	sd	s3,40(sp)
    80002a6e:	f052                	sd	s4,32(sp)
    80002a70:	ec56                	sd	s5,24(sp)
    80002a72:	e85a                	sd	s6,16(sp)
    80002a74:	e45e                	sd	s7,8(sp)
    80002a76:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002a78:	00006517          	auipc	a0,0x6
    80002a7c:	65050513          	addi	a0,a0,1616 # 800090c8 <digits+0x88>
    80002a80:	ffffe097          	auipc	ra,0xffffe
    80002a84:	b0e080e7          	jalr	-1266(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a88:	00010497          	auipc	s1,0x10
    80002a8c:	38848493          	addi	s1,s1,904 # 80012e10 <proc+0x158>
    80002a90:	00017917          	auipc	s2,0x17
    80002a94:	58090913          	addi	s2,s2,1408 # 8001a010 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a98:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002a9a:	00007997          	auipc	s3,0x7
    80002a9e:	80698993          	addi	s3,s3,-2042 # 800092a0 <digits+0x260>
    printf("%d %s %s", p->pid, state, p->name);
    80002aa2:	00007a97          	auipc	s5,0x7
    80002aa6:	806a8a93          	addi	s5,s5,-2042 # 800092a8 <digits+0x268>
    printf("\n");
    80002aaa:	00006a17          	auipc	s4,0x6
    80002aae:	61ea0a13          	addi	s4,s4,1566 # 800090c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ab2:	00007b97          	auipc	s7,0x7
    80002ab6:	836b8b93          	addi	s7,s7,-1994 # 800092e8 <states.1811>
    80002aba:	a00d                	j	80002adc <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002abc:	ed86a583          	lw	a1,-296(a3)
    80002ac0:	8556                	mv	a0,s5
    80002ac2:	ffffe097          	auipc	ra,0xffffe
    80002ac6:	acc080e7          	jalr	-1332(ra) # 8000058e <printf>
    printf("\n");
    80002aca:	8552                	mv	a0,s4
    80002acc:	ffffe097          	auipc	ra,0xffffe
    80002ad0:	ac2080e7          	jalr	-1342(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002ad4:	1c848493          	addi	s1,s1,456
    80002ad8:	03248163          	beq	s1,s2,80002afa <procdump+0x98>
    if(p->state == UNUSED)
    80002adc:	86a6                	mv	a3,s1
    80002ade:	ec04a783          	lw	a5,-320(s1)
    80002ae2:	dbed                	beqz	a5,80002ad4 <procdump+0x72>
      state = "???";
    80002ae4:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ae6:	fcfb6be3          	bltu	s6,a5,80002abc <procdump+0x5a>
    80002aea:	1782                	slli	a5,a5,0x20
    80002aec:	9381                	srli	a5,a5,0x20
    80002aee:	078e                	slli	a5,a5,0x3
    80002af0:	97de                	add	a5,a5,s7
    80002af2:	6390                	ld	a2,0(a5)
    80002af4:	f661                	bnez	a2,80002abc <procdump+0x5a>
      state = "???";
    80002af6:	864e                	mv	a2,s3
    80002af8:	b7d1                	j	80002abc <procdump+0x5a>
  }
}
    80002afa:	60a6                	ld	ra,72(sp)
    80002afc:	6406                	ld	s0,64(sp)
    80002afe:	74e2                	ld	s1,56(sp)
    80002b00:	7942                	ld	s2,48(sp)
    80002b02:	79a2                	ld	s3,40(sp)
    80002b04:	7a02                	ld	s4,32(sp)
    80002b06:	6ae2                	ld	s5,24(sp)
    80002b08:	6b42                	ld	s6,16(sp)
    80002b0a:	6ba2                	ld	s7,8(sp)
    80002b0c:	6161                	addi	sp,sp,80
    80002b0e:	8082                	ret

0000000080002b10 <setpriority>:

int setpriority(int new_priority, int proc_pid)
{
    80002b10:	7179                	addi	sp,sp,-48
    80002b12:	f406                	sd	ra,40(sp)
    80002b14:	f022                	sd	s0,32(sp)
    80002b16:	ec26                	sd	s1,24(sp)
    80002b18:	e84a                	sd	s2,16(sp)
    80002b1a:	e44e                	sd	s3,8(sp)
    80002b1c:	e052                	sd	s4,0(sp)
    80002b1e:	1800                	addi	s0,sp,48
    80002b20:	8a2a                	mv	s4,a0
    80002b22:	892e                	mv	s2,a1
  struct proc* p;
  int old_priority;
  int found_proc = 0;
  for(p = proc; p < &proc[NPROC]; p++)
    80002b24:	00010497          	auipc	s1,0x10
    80002b28:	19448493          	addi	s1,s1,404 # 80012cb8 <proc>
    80002b2c:	00017997          	auipc	s3,0x17
    80002b30:	38c98993          	addi	s3,s3,908 # 80019eb8 <tickslock>
  {
    acquire(&p->lock);
    80002b34:	8526                	mv	a0,s1
    80002b36:	ffffe097          	auipc	ra,0xffffe
    80002b3a:	0b4080e7          	jalr	180(ra) # 80000bea <acquire>
    if (p->pid == proc_pid)
    80002b3e:	589c                	lw	a5,48(s1)
    80002b40:	01278d63          	beq	a5,s2,80002b5a <setpriority+0x4a>
      p->priority_pbs = new_priority;
      release(&p->lock);
      found_proc = 1;
      break;
    }
    release(&p->lock);
    80002b44:	8526                	mv	a0,s1
    80002b46:	ffffe097          	auipc	ra,0xffffe
    80002b4a:	158080e7          	jalr	344(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++)
    80002b4e:	1c848493          	addi	s1,s1,456
    80002b52:	ff3491e3          	bne	s1,s3,80002b34 <setpriority+0x24>
  {
    return old_priority;
  }
  else
  {
    return -1;
    80002b56:	597d                	li	s2,-1
    80002b58:	a811                	j	80002b6c <setpriority+0x5c>
      old_priority = p->priority_pbs;
    80002b5a:	1a04a903          	lw	s2,416(s1)
      p->priority_pbs = new_priority;
    80002b5e:	1b44a023          	sw	s4,416(s1)
      release(&p->lock);
    80002b62:	8526                	mv	a0,s1
    80002b64:	ffffe097          	auipc	ra,0xffffe
    80002b68:	13a080e7          	jalr	314(ra) # 80000c9e <release>
  }
    80002b6c:	854a                	mv	a0,s2
    80002b6e:	70a2                	ld	ra,40(sp)
    80002b70:	7402                	ld	s0,32(sp)
    80002b72:	64e2                	ld	s1,24(sp)
    80002b74:	6942                	ld	s2,16(sp)
    80002b76:	69a2                	ld	s3,8(sp)
    80002b78:	6a02                	ld	s4,0(sp)
    80002b7a:	6145                	addi	sp,sp,48
    80002b7c:	8082                	ret

0000000080002b7e <swtch>:
    80002b7e:	00153023          	sd	ra,0(a0)
    80002b82:	00253423          	sd	sp,8(a0)
    80002b86:	e900                	sd	s0,16(a0)
    80002b88:	ed04                	sd	s1,24(a0)
    80002b8a:	03253023          	sd	s2,32(a0)
    80002b8e:	03353423          	sd	s3,40(a0)
    80002b92:	03453823          	sd	s4,48(a0)
    80002b96:	03553c23          	sd	s5,56(a0)
    80002b9a:	05653023          	sd	s6,64(a0)
    80002b9e:	05753423          	sd	s7,72(a0)
    80002ba2:	05853823          	sd	s8,80(a0)
    80002ba6:	05953c23          	sd	s9,88(a0)
    80002baa:	07a53023          	sd	s10,96(a0)
    80002bae:	07b53423          	sd	s11,104(a0)
    80002bb2:	0005b083          	ld	ra,0(a1)
    80002bb6:	0085b103          	ld	sp,8(a1)
    80002bba:	6980                	ld	s0,16(a1)
    80002bbc:	6d84                	ld	s1,24(a1)
    80002bbe:	0205b903          	ld	s2,32(a1)
    80002bc2:	0285b983          	ld	s3,40(a1)
    80002bc6:	0305ba03          	ld	s4,48(a1)
    80002bca:	0385ba83          	ld	s5,56(a1)
    80002bce:	0405bb03          	ld	s6,64(a1)
    80002bd2:	0485bb83          	ld	s7,72(a1)
    80002bd6:	0505bc03          	ld	s8,80(a1)
    80002bda:	0585bc83          	ld	s9,88(a1)
    80002bde:	0605bd03          	ld	s10,96(a1)
    80002be2:	0685bd83          	ld	s11,104(a1)
    80002be6:	8082                	ret

0000000080002be8 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002be8:	1141                	addi	sp,sp,-16
    80002bea:	e406                	sd	ra,8(sp)
    80002bec:	e022                	sd	s0,0(sp)
    80002bee:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002bf0:	00006597          	auipc	a1,0x6
    80002bf4:	72858593          	addi	a1,a1,1832 # 80009318 <states.1811+0x30>
    80002bf8:	00017517          	auipc	a0,0x17
    80002bfc:	2c050513          	addi	a0,a0,704 # 80019eb8 <tickslock>
    80002c00:	ffffe097          	auipc	ra,0xffffe
    80002c04:	f5a080e7          	jalr	-166(ra) # 80000b5a <initlock>
}
    80002c08:	60a2                	ld	ra,8(sp)
    80002c0a:	6402                	ld	s0,0(sp)
    80002c0c:	0141                	addi	sp,sp,16
    80002c0e:	8082                	ret

0000000080002c10 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002c10:	1141                	addi	sp,sp,-16
    80002c12:	e422                	sd	s0,8(sp)
    80002c14:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c16:	00004797          	auipc	a5,0x4
    80002c1a:	c1a78793          	addi	a5,a5,-998 # 80006830 <kernelvec>
    80002c1e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002c22:	6422                	ld	s0,8(sp)
    80002c24:	0141                	addi	sp,sp,16
    80002c26:	8082                	ret

0000000080002c28 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002c28:	1141                	addi	sp,sp,-16
    80002c2a:	e406                	sd	ra,8(sp)
    80002c2c:	e022                	sd	s0,0(sp)
    80002c2e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002c30:	fffff097          	auipc	ra,0xfffff
    80002c34:	fc6080e7          	jalr	-58(ra) # 80001bf6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c38:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002c3c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c3e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002c42:	00005617          	auipc	a2,0x5
    80002c46:	3be60613          	addi	a2,a2,958 # 80008000 <_trampoline>
    80002c4a:	00005697          	auipc	a3,0x5
    80002c4e:	3b668693          	addi	a3,a3,950 # 80008000 <_trampoline>
    80002c52:	8e91                	sub	a3,a3,a2
    80002c54:	040007b7          	lui	a5,0x4000
    80002c58:	17fd                	addi	a5,a5,-1
    80002c5a:	07b2                	slli	a5,a5,0xc
    80002c5c:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c5e:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002c62:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002c64:	180026f3          	csrr	a3,satp
    80002c68:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c6a:	6d38                	ld	a4,88(a0)
    80002c6c:	6134                	ld	a3,64(a0)
    80002c6e:	6585                	lui	a1,0x1
    80002c70:	96ae                	add	a3,a3,a1
    80002c72:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002c74:	6d38                	ld	a4,88(a0)
    80002c76:	00000697          	auipc	a3,0x0
    80002c7a:	13e68693          	addi	a3,a3,318 # 80002db4 <usertrap>
    80002c7e:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002c80:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c82:	8692                	mv	a3,tp
    80002c84:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c86:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c8a:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c8e:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c92:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002c96:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c98:	6f18                	ld	a4,24(a4)
    80002c9a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002c9e:	6928                	ld	a0,80(a0)
    80002ca0:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002ca2:	00005717          	auipc	a4,0x5
    80002ca6:	3fa70713          	addi	a4,a4,1018 # 8000809c <userret>
    80002caa:	8f11                	sub	a4,a4,a2
    80002cac:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002cae:	577d                	li	a4,-1
    80002cb0:	177e                	slli	a4,a4,0x3f
    80002cb2:	8d59                	or	a0,a0,a4
    80002cb4:	9782                	jalr	a5
}
    80002cb6:	60a2                	ld	ra,8(sp)
    80002cb8:	6402                	ld	s0,0(sp)
    80002cba:	0141                	addi	sp,sp,16
    80002cbc:	8082                	ret

0000000080002cbe <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002cbe:	1101                	addi	sp,sp,-32
    80002cc0:	ec06                	sd	ra,24(sp)
    80002cc2:	e822                	sd	s0,16(sp)
    80002cc4:	e426                	sd	s1,8(sp)
    80002cc6:	e04a                	sd	s2,0(sp)
    80002cc8:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002cca:	00017917          	auipc	s2,0x17
    80002cce:	1ee90913          	addi	s2,s2,494 # 80019eb8 <tickslock>
    80002cd2:	854a                	mv	a0,s2
    80002cd4:	ffffe097          	auipc	ra,0xffffe
    80002cd8:	f16080e7          	jalr	-234(ra) # 80000bea <acquire>
  ticks++;
    80002cdc:	00007497          	auipc	s1,0x7
    80002ce0:	ec448493          	addi	s1,s1,-316 # 80009ba0 <ticks>
    80002ce4:	409c                	lw	a5,0(s1)
    80002ce6:	2785                	addiw	a5,a5,1
    80002ce8:	c09c                	sw	a5,0(s1)
  update_time();
    80002cea:	fffff097          	auipc	ra,0xfffff
    80002cee:	6c0080e7          	jalr	1728(ra) # 800023aa <update_time>
  wakeup(&ticks);
    80002cf2:	8526                	mv	a0,s1
    80002cf4:	00000097          	auipc	ra,0x0
    80002cf8:	912080e7          	jalr	-1774(ra) # 80002606 <wakeup>
  release(&tickslock);
    80002cfc:	854a                	mv	a0,s2
    80002cfe:	ffffe097          	auipc	ra,0xffffe
    80002d02:	fa0080e7          	jalr	-96(ra) # 80000c9e <release>
}
    80002d06:	60e2                	ld	ra,24(sp)
    80002d08:	6442                	ld	s0,16(sp)
    80002d0a:	64a2                	ld	s1,8(sp)
    80002d0c:	6902                	ld	s2,0(sp)
    80002d0e:	6105                	addi	sp,sp,32
    80002d10:	8082                	ret

0000000080002d12 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002d12:	1101                	addi	sp,sp,-32
    80002d14:	ec06                	sd	ra,24(sp)
    80002d16:	e822                	sd	s0,16(sp)
    80002d18:	e426                	sd	s1,8(sp)
    80002d1a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d1c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002d20:	00074d63          	bltz	a4,80002d3a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002d24:	57fd                	li	a5,-1
    80002d26:	17fe                	slli	a5,a5,0x3f
    80002d28:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002d2a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002d2c:	06f70363          	beq	a4,a5,80002d92 <devintr+0x80>
  }
}
    80002d30:	60e2                	ld	ra,24(sp)
    80002d32:	6442                	ld	s0,16(sp)
    80002d34:	64a2                	ld	s1,8(sp)
    80002d36:	6105                	addi	sp,sp,32
    80002d38:	8082                	ret
     (scause & 0xff) == 9){
    80002d3a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002d3e:	46a5                	li	a3,9
    80002d40:	fed792e3          	bne	a5,a3,80002d24 <devintr+0x12>
    int irq = plic_claim();
    80002d44:	00004097          	auipc	ra,0x4
    80002d48:	bf4080e7          	jalr	-1036(ra) # 80006938 <plic_claim>
    80002d4c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002d4e:	47a9                	li	a5,10
    80002d50:	02f50763          	beq	a0,a5,80002d7e <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002d54:	4785                	li	a5,1
    80002d56:	02f50963          	beq	a0,a5,80002d88 <devintr+0x76>
    return 1;
    80002d5a:	4505                	li	a0,1
    } else if(irq){
    80002d5c:	d8f1                	beqz	s1,80002d30 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002d5e:	85a6                	mv	a1,s1
    80002d60:	00006517          	auipc	a0,0x6
    80002d64:	5c050513          	addi	a0,a0,1472 # 80009320 <states.1811+0x38>
    80002d68:	ffffe097          	auipc	ra,0xffffe
    80002d6c:	826080e7          	jalr	-2010(ra) # 8000058e <printf>
      plic_complete(irq);
    80002d70:	8526                	mv	a0,s1
    80002d72:	00004097          	auipc	ra,0x4
    80002d76:	bea080e7          	jalr	-1046(ra) # 8000695c <plic_complete>
    return 1;
    80002d7a:	4505                	li	a0,1
    80002d7c:	bf55                	j	80002d30 <devintr+0x1e>
      uartintr();
    80002d7e:	ffffe097          	auipc	ra,0xffffe
    80002d82:	c30080e7          	jalr	-976(ra) # 800009ae <uartintr>
    80002d86:	b7ed                	j	80002d70 <devintr+0x5e>
      virtio_disk_intr();
    80002d88:	00004097          	auipc	ra,0x4
    80002d8c:	0fe080e7          	jalr	254(ra) # 80006e86 <virtio_disk_intr>
    80002d90:	b7c5                	j	80002d70 <devintr+0x5e>
    if(cpuid() == 0){
    80002d92:	fffff097          	auipc	ra,0xfffff
    80002d96:	e38080e7          	jalr	-456(ra) # 80001bca <cpuid>
    80002d9a:	c901                	beqz	a0,80002daa <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002d9c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002da0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002da2:	14479073          	csrw	sip,a5
    return 2;
    80002da6:	4509                	li	a0,2
    80002da8:	b761                	j	80002d30 <devintr+0x1e>
      clockintr();
    80002daa:	00000097          	auipc	ra,0x0
    80002dae:	f14080e7          	jalr	-236(ra) # 80002cbe <clockintr>
    80002db2:	b7ed                	j	80002d9c <devintr+0x8a>

0000000080002db4 <usertrap>:
{
    80002db4:	7179                	addi	sp,sp,-48
    80002db6:	f406                	sd	ra,40(sp)
    80002db8:	f022                	sd	s0,32(sp)
    80002dba:	ec26                	sd	s1,24(sp)
    80002dbc:	e84a                	sd	s2,16(sp)
    80002dbe:	e44e                	sd	s3,8(sp)
    80002dc0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002dc2:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002dc6:	1007f793          	andi	a5,a5,256
    80002dca:	e3a5                	bnez	a5,80002e2a <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002dcc:	00004797          	auipc	a5,0x4
    80002dd0:	a6478793          	addi	a5,a5,-1436 # 80006830 <kernelvec>
    80002dd4:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002dd8:	fffff097          	auipc	ra,0xfffff
    80002ddc:	e1e080e7          	jalr	-482(ra) # 80001bf6 <myproc>
    80002de0:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002de2:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002de4:	14102773          	csrr	a4,sepc
    80002de8:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002dea:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002dee:	47a1                	li	a5,8
    80002df0:	04f70563          	beq	a4,a5,80002e3a <usertrap+0x86>
  } else if((which_dev = devintr()) != 0){
    80002df4:	00000097          	auipc	ra,0x0
    80002df8:	f1e080e7          	jalr	-226(ra) # 80002d12 <devintr>
    80002dfc:	892a                	mv	s2,a0
    80002dfe:	cd69                	beqz	a0,80002ed8 <usertrap+0x124>
    if(which_dev == 2 && myproc()->interval) {
    80002e00:	4789                	li	a5,2
    80002e02:	06f50763          	beq	a0,a5,80002e70 <usertrap+0xbc>
  if(killed(p))
    80002e06:	8526                	mv	a0,s1
    80002e08:	00000097          	auipc	ra,0x0
    80002e0c:	a4e080e7          	jalr	-1458(ra) # 80002856 <killed>
    80002e10:	10051163          	bnez	a0,80002f12 <usertrap+0x15e>
  usertrapret();
    80002e14:	00000097          	auipc	ra,0x0
    80002e18:	e14080e7          	jalr	-492(ra) # 80002c28 <usertrapret>
}
    80002e1c:	70a2                	ld	ra,40(sp)
    80002e1e:	7402                	ld	s0,32(sp)
    80002e20:	64e2                	ld	s1,24(sp)
    80002e22:	6942                	ld	s2,16(sp)
    80002e24:	69a2                	ld	s3,8(sp)
    80002e26:	6145                	addi	sp,sp,48
    80002e28:	8082                	ret
    panic("usertrap: not from user mode");
    80002e2a:	00006517          	auipc	a0,0x6
    80002e2e:	51650513          	addi	a0,a0,1302 # 80009340 <states.1811+0x58>
    80002e32:	ffffd097          	auipc	ra,0xffffd
    80002e36:	712080e7          	jalr	1810(ra) # 80000544 <panic>
    if(killed(p))
    80002e3a:	00000097          	auipc	ra,0x0
    80002e3e:	a1c080e7          	jalr	-1508(ra) # 80002856 <killed>
    80002e42:	e10d                	bnez	a0,80002e64 <usertrap+0xb0>
    p->trapframe->epc += 4;
    80002e44:	6cb8                	ld	a4,88(s1)
    80002e46:	6f1c                	ld	a5,24(a4)
    80002e48:	0791                	addi	a5,a5,4
    80002e4a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e4c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002e50:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e54:	10079073          	csrw	sstatus,a5
    syscall();
    80002e58:	00000097          	auipc	ra,0x0
    80002e5c:	404080e7          	jalr	1028(ra) # 8000325c <syscall>
  int which_dev = 0;
    80002e60:	4901                	li	s2,0
    80002e62:	b755                	j	80002e06 <usertrap+0x52>
      exit(-1);
    80002e64:	557d                	li	a0,-1
    80002e66:	00000097          	auipc	ra,0x0
    80002e6a:	870080e7          	jalr	-1936(ra) # 800026d6 <exit>
    80002e6e:	bfd9                	j	80002e44 <usertrap+0x90>
    if(which_dev == 2 && myproc()->interval) {
    80002e70:	fffff097          	auipc	ra,0xfffff
    80002e74:	d86080e7          	jalr	-634(ra) # 80001bf6 <myproc>
    80002e78:	17852783          	lw	a5,376(a0)
    80002e7c:	ef89                	bnez	a5,80002e96 <usertrap+0xe2>
  if(killed(p))
    80002e7e:	8526                	mv	a0,s1
    80002e80:	00000097          	auipc	ra,0x0
    80002e84:	9d6080e7          	jalr	-1578(ra) # 80002856 <killed>
    80002e88:	cd49                	beqz	a0,80002f22 <usertrap+0x16e>
    exit(-1);
    80002e8a:	557d                	li	a0,-1
    80002e8c:	00000097          	auipc	ra,0x0
    80002e90:	84a080e7          	jalr	-1974(ra) # 800026d6 <exit>
    if(which_dev == 2 && myproc()->state == RUNNING && myproc() != 0) {
    80002e94:	a079                	j	80002f22 <usertrap+0x16e>
      myproc()->ticks_left--;
    80002e96:	fffff097          	auipc	ra,0xfffff
    80002e9a:	d60080e7          	jalr	-672(ra) # 80001bf6 <myproc>
    80002e9e:	17c52783          	lw	a5,380(a0)
    80002ea2:	37fd                	addiw	a5,a5,-1
    80002ea4:	16f52e23          	sw	a5,380(a0)
      if(myproc()->ticks_left == 0) {
    80002ea8:	fffff097          	auipc	ra,0xfffff
    80002eac:	d4e080e7          	jalr	-690(ra) # 80001bf6 <myproc>
    80002eb0:	17c52783          	lw	a5,380(a0)
    80002eb4:	f7e9                	bnez	a5,80002e7e <usertrap+0xca>
        p->sigalarm_tf = kalloc();
    80002eb6:	ffffe097          	auipc	ra,0xffffe
    80002eba:	c44080e7          	jalr	-956(ra) # 80000afa <kalloc>
    80002ebe:	18a4b423          	sd	a0,392(s1)
        memmove(p->sigalarm_tf, p->trapframe, PGSIZE);
    80002ec2:	6605                	lui	a2,0x1
    80002ec4:	6cac                	ld	a1,88(s1)
    80002ec6:	ffffe097          	auipc	ra,0xffffe
    80002eca:	e80080e7          	jalr	-384(ra) # 80000d46 <memmove>
        p->trapframe->epc = p->sig_handler;
    80002ece:	6cbc                	ld	a5,88(s1)
    80002ed0:	1804b703          	ld	a4,384(s1)
    80002ed4:	ef98                	sd	a4,24(a5)
    80002ed6:	b765                	j	80002e7e <usertrap+0xca>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ed8:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002edc:	5890                	lw	a2,48(s1)
    80002ede:	00006517          	auipc	a0,0x6
    80002ee2:	48250513          	addi	a0,a0,1154 # 80009360 <states.1811+0x78>
    80002ee6:	ffffd097          	auipc	ra,0xffffd
    80002eea:	6a8080e7          	jalr	1704(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002eee:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ef2:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ef6:	00006517          	auipc	a0,0x6
    80002efa:	49a50513          	addi	a0,a0,1178 # 80009390 <states.1811+0xa8>
    80002efe:	ffffd097          	auipc	ra,0xffffd
    80002f02:	690080e7          	jalr	1680(ra) # 8000058e <printf>
    setkilled(p);
    80002f06:	8526                	mv	a0,s1
    80002f08:	00000097          	auipc	ra,0x0
    80002f0c:	922080e7          	jalr	-1758(ra) # 8000282a <setkilled>
    80002f10:	bddd                	j	80002e06 <usertrap+0x52>
    exit(-1);
    80002f12:	557d                	li	a0,-1
    80002f14:	fffff097          	auipc	ra,0xfffff
    80002f18:	7c2080e7          	jalr	1986(ra) # 800026d6 <exit>
    if(which_dev == 2 && myproc()->state == RUNNING && myproc() != 0) {
    80002f1c:	4789                	li	a5,2
    80002f1e:	eef91be3          	bne	s2,a5,80002e14 <usertrap+0x60>
    80002f22:	fffff097          	auipc	ra,0xfffff
    80002f26:	cd4080e7          	jalr	-812(ra) # 80001bf6 <myproc>
    80002f2a:	4d18                	lw	a4,24(a0)
    80002f2c:	4791                	li	a5,4
    80002f2e:	eef713e3          	bne	a4,a5,80002e14 <usertrap+0x60>
    80002f32:	fffff097          	auipc	ra,0xfffff
    80002f36:	cc4080e7          	jalr	-828(ra) # 80001bf6 <myproc>
    80002f3a:	ec050de3          	beqz	a0,80002e14 <usertrap+0x60>
      if(p->curr_rtime >= priority_levels[p->priority]) {
    80002f3e:	1b44a703          	lw	a4,436(s1)
    80002f42:	00271693          	slli	a3,a4,0x2
    80002f46:	00007797          	auipc	a5,0x7
    80002f4a:	b1278793          	addi	a5,a5,-1262 # 80009a58 <priority_levels>
    80002f4e:	97b6                	add	a5,a5,a3
    80002f50:	1bc4a683          	lw	a3,444(s1)
    80002f54:	439c                	lw	a5,0(a5)
    80002f56:	00f6da63          	bge	a3,a5,80002f6a <usertrap+0x1b6>
        for(int i = 0; i < p->priority; i++) {
    80002f5a:	0000f997          	auipc	s3,0xf
    80002f5e:	2ee98993          	addi	s3,s3,750 # 80012248 <queues+0x8>
    80002f62:	4901                	li	s2,0
    80002f64:	02e04963          	bgtz	a4,80002f96 <usertrap+0x1e2>
    80002f68:	b575                	j	80002e14 <usertrap+0x60>
        if(p->priority != 4) {
    80002f6a:	4791                	li	a5,4
    80002f6c:	00f70563          	beq	a4,a5,80002f76 <usertrap+0x1c2>
          p->priority++;
    80002f70:	2705                	addiw	a4,a4,1
    80002f72:	1ae4aa23          	sw	a4,436(s1)
        p->curr_rtime = 0;
    80002f76:	1a04ae23          	sw	zero,444(s1)
        p->curr_wtime = 0;
    80002f7a:	1c04a023          	sw	zero,448(s1)
        yield();
    80002f7e:	fffff097          	auipc	ra,0xfffff
    80002f82:	3f0080e7          	jalr	1008(ra) # 8000236e <yield>
    80002f86:	b579                	j	80002e14 <usertrap+0x60>
        for(int i = 0; i < p->priority; i++) {
    80002f88:	2905                	addiw	s2,s2,1
    80002f8a:	21898993          	addi	s3,s3,536
    80002f8e:	1b44a783          	lw	a5,436(s1)
    80002f92:	e8f951e3          	bge	s2,a5,80002e14 <usertrap+0x60>
          if(queues[i].length > 0) {
    80002f96:	0009a783          	lw	a5,0(s3)
    80002f9a:	fef057e3          	blez	a5,80002f88 <usertrap+0x1d4>
            yield();
    80002f9e:	fffff097          	auipc	ra,0xfffff
    80002fa2:	3d0080e7          	jalr	976(ra) # 8000236e <yield>
    80002fa6:	b7cd                	j	80002f88 <usertrap+0x1d4>

0000000080002fa8 <kerneltrap>:
{
    80002fa8:	7139                	addi	sp,sp,-64
    80002faa:	fc06                	sd	ra,56(sp)
    80002fac:	f822                	sd	s0,48(sp)
    80002fae:	f426                	sd	s1,40(sp)
    80002fb0:	f04a                	sd	s2,32(sp)
    80002fb2:	ec4e                	sd	s3,24(sp)
    80002fb4:	e852                	sd	s4,16(sp)
    80002fb6:	e456                	sd	s5,8(sp)
    80002fb8:	0080                	addi	s0,sp,64
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fba:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fbe:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002fc2:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002fc6:	1004f793          	andi	a5,s1,256
    80002fca:	cb95                	beqz	a5,80002ffe <kerneltrap+0x56>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fcc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002fd0:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002fd2:	ef95                	bnez	a5,8000300e <kerneltrap+0x66>
  if((which_dev = devintr()) == 0){
    80002fd4:	00000097          	auipc	ra,0x0
    80002fd8:	d3e080e7          	jalr	-706(ra) # 80002d12 <devintr>
    80002fdc:	c129                	beqz	a0,8000301e <kerneltrap+0x76>
    if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING) {
    80002fde:	4789                	li	a5,2
    80002fe0:	06f50c63          	beq	a0,a5,80003058 <kerneltrap+0xb0>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002fe4:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fe8:	10049073          	csrw	sstatus,s1
}
    80002fec:	70e2                	ld	ra,56(sp)
    80002fee:	7442                	ld	s0,48(sp)
    80002ff0:	74a2                	ld	s1,40(sp)
    80002ff2:	7902                	ld	s2,32(sp)
    80002ff4:	69e2                	ld	s3,24(sp)
    80002ff6:	6a42                	ld	s4,16(sp)
    80002ff8:	6aa2                	ld	s5,8(sp)
    80002ffa:	6121                	addi	sp,sp,64
    80002ffc:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ffe:	00006517          	auipc	a0,0x6
    80003002:	3b250513          	addi	a0,a0,946 # 800093b0 <states.1811+0xc8>
    80003006:	ffffd097          	auipc	ra,0xffffd
    8000300a:	53e080e7          	jalr	1342(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    8000300e:	00006517          	auipc	a0,0x6
    80003012:	3ca50513          	addi	a0,a0,970 # 800093d8 <states.1811+0xf0>
    80003016:	ffffd097          	auipc	ra,0xffffd
    8000301a:	52e080e7          	jalr	1326(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    8000301e:	85ce                	mv	a1,s3
    80003020:	00006517          	auipc	a0,0x6
    80003024:	3d850513          	addi	a0,a0,984 # 800093f8 <states.1811+0x110>
    80003028:	ffffd097          	auipc	ra,0xffffd
    8000302c:	566080e7          	jalr	1382(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003030:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003034:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003038:	00006517          	auipc	a0,0x6
    8000303c:	3d050513          	addi	a0,a0,976 # 80009408 <states.1811+0x120>
    80003040:	ffffd097          	auipc	ra,0xffffd
    80003044:	54e080e7          	jalr	1358(ra) # 8000058e <printf>
    panic("kerneltrap");
    80003048:	00006517          	auipc	a0,0x6
    8000304c:	3d850513          	addi	a0,a0,984 # 80009420 <states.1811+0x138>
    80003050:	ffffd097          	auipc	ra,0xffffd
    80003054:	4f4080e7          	jalr	1268(ra) # 80000544 <panic>
    if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING) {
    80003058:	fffff097          	auipc	ra,0xfffff
    8000305c:	b9e080e7          	jalr	-1122(ra) # 80001bf6 <myproc>
    80003060:	d151                	beqz	a0,80002fe4 <kerneltrap+0x3c>
    80003062:	fffff097          	auipc	ra,0xfffff
    80003066:	b94080e7          	jalr	-1132(ra) # 80001bf6 <myproc>
    8000306a:	4d18                	lw	a4,24(a0)
    8000306c:	4791                	li	a5,4
    8000306e:	f6f71be3          	bne	a4,a5,80002fe4 <kerneltrap+0x3c>
      struct proc* p = myproc();
    80003072:	fffff097          	auipc	ra,0xfffff
    80003076:	b84080e7          	jalr	-1148(ra) # 80001bf6 <myproc>
    8000307a:	8aaa                	mv	s5,a0
      if(p->curr_rtime >= priority_levels[p->priority]) {
    8000307c:	1b452703          	lw	a4,436(a0)
    80003080:	00271693          	slli	a3,a4,0x2
    80003084:	00007797          	auipc	a5,0x7
    80003088:	9d478793          	addi	a5,a5,-1580 # 80009a58 <priority_levels>
    8000308c:	97b6                	add	a5,a5,a3
    8000308e:	1bc52683          	lw	a3,444(a0)
    80003092:	439c                	lw	a5,0(a5)
    80003094:	00f6da63          	bge	a3,a5,800030a8 <kerneltrap+0x100>
        for(int i = 0; i < p->priority; i++) {
    80003098:	0000fa17          	auipc	s4,0xf
    8000309c:	1b0a0a13          	addi	s4,s4,432 # 80012248 <queues+0x8>
    800030a0:	4981                	li	s3,0
    800030a2:	02e04563          	bgtz	a4,800030cc <kerneltrap+0x124>
    800030a6:	bf3d                	j	80002fe4 <kerneltrap+0x3c>
        if(p->priority != 4) {
    800030a8:	4791                	li	a5,4
    800030aa:	00f70563          	beq	a4,a5,800030b4 <kerneltrap+0x10c>
          p->priority++;
    800030ae:	2705                	addiw	a4,a4,1
    800030b0:	1ae52a23          	sw	a4,436(a0)
        yield();
    800030b4:	fffff097          	auipc	ra,0xfffff
    800030b8:	2ba080e7          	jalr	698(ra) # 8000236e <yield>
    800030bc:	b725                	j	80002fe4 <kerneltrap+0x3c>
        for(int i = 0; i < p->priority; i++) {
    800030be:	2985                	addiw	s3,s3,1
    800030c0:	218a0a13          	addi	s4,s4,536
    800030c4:	1b4aa783          	lw	a5,436(s5)
    800030c8:	f0f9dee3          	bge	s3,a5,80002fe4 <kerneltrap+0x3c>
          if(queues[i].length > 0) {
    800030cc:	000a2783          	lw	a5,0(s4)
    800030d0:	fef057e3          	blez	a5,800030be <kerneltrap+0x116>
            yield();
    800030d4:	fffff097          	auipc	ra,0xfffff
    800030d8:	29a080e7          	jalr	666(ra) # 8000236e <yield>
    800030dc:	b7cd                	j	800030be <kerneltrap+0x116>

00000000800030de <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800030de:	1101                	addi	sp,sp,-32
    800030e0:	ec06                	sd	ra,24(sp)
    800030e2:	e822                	sd	s0,16(sp)
    800030e4:	e426                	sd	s1,8(sp)
    800030e6:	1000                	addi	s0,sp,32
    800030e8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800030ea:	fffff097          	auipc	ra,0xfffff
    800030ee:	b0c080e7          	jalr	-1268(ra) # 80001bf6 <myproc>
  switch (n) {
    800030f2:	4795                	li	a5,5
    800030f4:	0497e163          	bltu	a5,s1,80003136 <argraw+0x58>
    800030f8:	048a                	slli	s1,s1,0x2
    800030fa:	00006717          	auipc	a4,0x6
    800030fe:	4d670713          	addi	a4,a4,1238 # 800095d0 <states.1811+0x2e8>
    80003102:	94ba                	add	s1,s1,a4
    80003104:	409c                	lw	a5,0(s1)
    80003106:	97ba                	add	a5,a5,a4
    80003108:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    8000310a:	6d3c                	ld	a5,88(a0)
    8000310c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000310e:	60e2                	ld	ra,24(sp)
    80003110:	6442                	ld	s0,16(sp)
    80003112:	64a2                	ld	s1,8(sp)
    80003114:	6105                	addi	sp,sp,32
    80003116:	8082                	ret
    return p->trapframe->a1;
    80003118:	6d3c                	ld	a5,88(a0)
    8000311a:	7fa8                	ld	a0,120(a5)
    8000311c:	bfcd                	j	8000310e <argraw+0x30>
    return p->trapframe->a2;
    8000311e:	6d3c                	ld	a5,88(a0)
    80003120:	63c8                	ld	a0,128(a5)
    80003122:	b7f5                	j	8000310e <argraw+0x30>
    return p->trapframe->a3;
    80003124:	6d3c                	ld	a5,88(a0)
    80003126:	67c8                	ld	a0,136(a5)
    80003128:	b7dd                	j	8000310e <argraw+0x30>
    return p->trapframe->a4;
    8000312a:	6d3c                	ld	a5,88(a0)
    8000312c:	6bc8                	ld	a0,144(a5)
    8000312e:	b7c5                	j	8000310e <argraw+0x30>
    return p->trapframe->a5;
    80003130:	6d3c                	ld	a5,88(a0)
    80003132:	6fc8                	ld	a0,152(a5)
    80003134:	bfe9                	j	8000310e <argraw+0x30>
  panic("argraw");
    80003136:	00006517          	auipc	a0,0x6
    8000313a:	2fa50513          	addi	a0,a0,762 # 80009430 <states.1811+0x148>
    8000313e:	ffffd097          	auipc	ra,0xffffd
    80003142:	406080e7          	jalr	1030(ra) # 80000544 <panic>

0000000080003146 <fetchaddr>:
{
    80003146:	1101                	addi	sp,sp,-32
    80003148:	ec06                	sd	ra,24(sp)
    8000314a:	e822                	sd	s0,16(sp)
    8000314c:	e426                	sd	s1,8(sp)
    8000314e:	e04a                	sd	s2,0(sp)
    80003150:	1000                	addi	s0,sp,32
    80003152:	84aa                	mv	s1,a0
    80003154:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003156:	fffff097          	auipc	ra,0xfffff
    8000315a:	aa0080e7          	jalr	-1376(ra) # 80001bf6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    8000315e:	653c                	ld	a5,72(a0)
    80003160:	02f4f863          	bgeu	s1,a5,80003190 <fetchaddr+0x4a>
    80003164:	00848713          	addi	a4,s1,8
    80003168:	02e7e663          	bltu	a5,a4,80003194 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000316c:	46a1                	li	a3,8
    8000316e:	8626                	mv	a2,s1
    80003170:	85ca                	mv	a1,s2
    80003172:	6928                	ld	a0,80(a0)
    80003174:	ffffe097          	auipc	ra,0xffffe
    80003178:	59c080e7          	jalr	1436(ra) # 80001710 <copyin>
    8000317c:	00a03533          	snez	a0,a0
    80003180:	40a00533          	neg	a0,a0
}
    80003184:	60e2                	ld	ra,24(sp)
    80003186:	6442                	ld	s0,16(sp)
    80003188:	64a2                	ld	s1,8(sp)
    8000318a:	6902                	ld	s2,0(sp)
    8000318c:	6105                	addi	sp,sp,32
    8000318e:	8082                	ret
    return -1;
    80003190:	557d                	li	a0,-1
    80003192:	bfcd                	j	80003184 <fetchaddr+0x3e>
    80003194:	557d                	li	a0,-1
    80003196:	b7fd                	j	80003184 <fetchaddr+0x3e>

0000000080003198 <fetchstr>:
{
    80003198:	7179                	addi	sp,sp,-48
    8000319a:	f406                	sd	ra,40(sp)
    8000319c:	f022                	sd	s0,32(sp)
    8000319e:	ec26                	sd	s1,24(sp)
    800031a0:	e84a                	sd	s2,16(sp)
    800031a2:	e44e                	sd	s3,8(sp)
    800031a4:	1800                	addi	s0,sp,48
    800031a6:	892a                	mv	s2,a0
    800031a8:	84ae                	mv	s1,a1
    800031aa:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800031ac:	fffff097          	auipc	ra,0xfffff
    800031b0:	a4a080e7          	jalr	-1462(ra) # 80001bf6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    800031b4:	86ce                	mv	a3,s3
    800031b6:	864a                	mv	a2,s2
    800031b8:	85a6                	mv	a1,s1
    800031ba:	6928                	ld	a0,80(a0)
    800031bc:	ffffe097          	auipc	ra,0xffffe
    800031c0:	5e0080e7          	jalr	1504(ra) # 8000179c <copyinstr>
    800031c4:	00054e63          	bltz	a0,800031e0 <fetchstr+0x48>
  return strlen(buf);
    800031c8:	8526                	mv	a0,s1
    800031ca:	ffffe097          	auipc	ra,0xffffe
    800031ce:	ca0080e7          	jalr	-864(ra) # 80000e6a <strlen>
}
    800031d2:	70a2                	ld	ra,40(sp)
    800031d4:	7402                	ld	s0,32(sp)
    800031d6:	64e2                	ld	s1,24(sp)
    800031d8:	6942                	ld	s2,16(sp)
    800031da:	69a2                	ld	s3,8(sp)
    800031dc:	6145                	addi	sp,sp,48
    800031de:	8082                	ret
    return -1;
    800031e0:	557d                	li	a0,-1
    800031e2:	bfc5                	j	800031d2 <fetchstr+0x3a>

00000000800031e4 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    800031e4:	1101                	addi	sp,sp,-32
    800031e6:	ec06                	sd	ra,24(sp)
    800031e8:	e822                	sd	s0,16(sp)
    800031ea:	e426                	sd	s1,8(sp)
    800031ec:	1000                	addi	s0,sp,32
    800031ee:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800031f0:	00000097          	auipc	ra,0x0
    800031f4:	eee080e7          	jalr	-274(ra) # 800030de <argraw>
    800031f8:	c088                	sw	a0,0(s1)
}
    800031fa:	60e2                	ld	ra,24(sp)
    800031fc:	6442                	ld	s0,16(sp)
    800031fe:	64a2                	ld	s1,8(sp)
    80003200:	6105                	addi	sp,sp,32
    80003202:	8082                	ret

0000000080003204 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80003204:	1101                	addi	sp,sp,-32
    80003206:	ec06                	sd	ra,24(sp)
    80003208:	e822                	sd	s0,16(sp)
    8000320a:	e426                	sd	s1,8(sp)
    8000320c:	1000                	addi	s0,sp,32
    8000320e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003210:	00000097          	auipc	ra,0x0
    80003214:	ece080e7          	jalr	-306(ra) # 800030de <argraw>
    80003218:	e088                	sd	a0,0(s1)
}
    8000321a:	60e2                	ld	ra,24(sp)
    8000321c:	6442                	ld	s0,16(sp)
    8000321e:	64a2                	ld	s1,8(sp)
    80003220:	6105                	addi	sp,sp,32
    80003222:	8082                	ret

0000000080003224 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003224:	7179                	addi	sp,sp,-48
    80003226:	f406                	sd	ra,40(sp)
    80003228:	f022                	sd	s0,32(sp)
    8000322a:	ec26                	sd	s1,24(sp)
    8000322c:	e84a                	sd	s2,16(sp)
    8000322e:	1800                	addi	s0,sp,48
    80003230:	84ae                	mv	s1,a1
    80003232:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80003234:	fd840593          	addi	a1,s0,-40
    80003238:	00000097          	auipc	ra,0x0
    8000323c:	fcc080e7          	jalr	-52(ra) # 80003204 <argaddr>
  return fetchstr(addr, buf, max);
    80003240:	864a                	mv	a2,s2
    80003242:	85a6                	mv	a1,s1
    80003244:	fd843503          	ld	a0,-40(s0)
    80003248:	00000097          	auipc	ra,0x0
    8000324c:	f50080e7          	jalr	-176(ra) # 80003198 <fetchstr>
}
    80003250:	70a2                	ld	ra,40(sp)
    80003252:	7402                	ld	s0,32(sp)
    80003254:	64e2                	ld	s1,24(sp)
    80003256:	6942                	ld	s2,16(sp)
    80003258:	6145                	addi	sp,sp,48
    8000325a:	8082                	ret

000000008000325c <syscall>:
[SYS_setpriority] "sys_setpriority",
};

void
syscall(void)
{
    8000325c:	7179                	addi	sp,sp,-48
    8000325e:	f406                	sd	ra,40(sp)
    80003260:	f022                	sd	s0,32(sp)
    80003262:	ec26                	sd	s1,24(sp)
    80003264:	e84a                	sd	s2,16(sp)
    80003266:	e44e                	sd	s3,8(sp)
    80003268:	e052                	sd	s4,0(sp)
    8000326a:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    8000326c:	fffff097          	auipc	ra,0xfffff
    80003270:	98a080e7          	jalr	-1654(ra) # 80001bf6 <myproc>
    80003274:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003276:	05853903          	ld	s2,88(a0)
    8000327a:	0a893783          	ld	a5,168(s2)
    8000327e:	0007899b          	sext.w	s3,a5
  unsigned int tmp = p->trapframe->a0;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003282:	37fd                	addiw	a5,a5,-1
    80003284:	4769                	li	a4,26
    80003286:	44f76c63          	bltu	a4,a5,800036de <syscall+0x482>
    8000328a:	00399713          	slli	a4,s3,0x3
    8000328e:	00006797          	auipc	a5,0x6
    80003292:	35a78793          	addi	a5,a5,858 # 800095e8 <syscalls>
    80003296:	97ba                	add	a5,a5,a4
    80003298:	639c                	ld	a5,0(a5)
    8000329a:	44078263          	beqz	a5,800036de <syscall+0x482>
  unsigned int tmp = p->trapframe->a0;
    8000329e:	07093a03          	ld	s4,112(s2)
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    800032a2:	9782                	jalr	a5
    800032a4:	06a93823          	sd	a0,112(s2)

    // Check for trace_flag to be on
    if(p->trace_flag >> num) {  // check for '=='
    800032a8:	1744a783          	lw	a5,372(s1)
    800032ac:	4137d7bb          	sraw	a5,a5,s3
    800032b0:	44078663          	beqz	a5,800036fc <syscall+0x4a0>
      if(num == 1)      printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0);   //fork  
    800032b4:	4785                	li	a5,1
    800032b6:	0cf98363          	beq	s3,a5,8000337c <syscall+0x120>
  unsigned int tmp = p->trapframe->a0;
    800032ba:	000a069b          	sext.w	a3,s4
      else if(num == 2) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // exit
    800032be:	4789                	li	a5,2
    800032c0:	0cf98e63          	beq	s3,a5,8000339c <syscall+0x140>
      else if(num == 3) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // wait
    800032c4:	478d                	li	a5,3
    800032c6:	0ef98b63          	beq	s3,a5,800033bc <syscall+0x160>
      else if(num == 4) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // pipe
    800032ca:	4791                	li	a5,4
    800032cc:	10f98863          	beq	s3,a5,800033dc <syscall+0x180>
      else if(num == 5) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp,  p->trapframe->a1,  p->trapframe->a2, p->trapframe->a0);  // read
    800032d0:	4795                	li	a5,5
    800032d2:	12f98563          	beq	s3,a5,800033fc <syscall+0x1a0>
      else if(num == 6) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // kill
    800032d6:	4799                	li	a5,6
    800032d8:	14f98563          	beq	s3,a5,80003422 <syscall+0x1c6>
      else if(num == 7) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp,  p->trapframe->a1, p->trapframe->a0);   // exec
    800032dc:	479d                	li	a5,7
    800032de:	16f98263          	beq	s3,a5,80003442 <syscall+0x1e6>
      else if(num == 8) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp,  p->trapframe->a1, p->trapframe->a0);  // fstat
    800032e2:	47a1                	li	a5,8
    800032e4:	18f98063          	beq	s3,a5,80003464 <syscall+0x208>
      else if(num == 9) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // chdir
    800032e8:	47a5                	li	a5,9
    800032ea:	18f98e63          	beq	s3,a5,80003486 <syscall+0x22a>
      else if(num == 10) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // dup
    800032ee:	47a9                	li	a5,10
    800032f0:	1af98b63          	beq	s3,a5,800034a6 <syscall+0x24a>
      else if(num == 11) printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0);  // getpid
    800032f4:	47ad                	li	a5,11
    800032f6:	1cf98863          	beq	s3,a5,800034c6 <syscall+0x26a>
      else if(num == 12) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // sbrk
    800032fa:	47b1                	li	a5,12
    800032fc:	1ef98563          	beq	s3,a5,800034e6 <syscall+0x28a>
      else if(num == 13) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // sleep
    80003300:	47b5                	li	a5,13
    80003302:	20f98263          	beq	s3,a5,80003506 <syscall+0x2aa>
      else if(num == 14) printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0); // uptime
    80003306:	47b9                	li	a5,14
    80003308:	20f98f63          	beq	s3,a5,80003526 <syscall+0x2ca>
      else if(num == 15) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a0); // open
    8000330c:	47bd                	li	a5,15
    8000330e:	22f98c63          	beq	s3,a5,80003546 <syscall+0x2ea>
      else if(num == 16) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a3, p->trapframe->a0); // write
    80003312:	47c1                	li	a5,16
    80003314:	24f98a63          	beq	s3,a5,80003568 <syscall+0x30c>
      else if(num == 17) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a3, p->trapframe->a0); // mknod
    80003318:	47c5                	li	a5,17
    8000331a:	26f98a63          	beq	s3,a5,8000358e <syscall+0x332>
      else if(num == 18) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // unlink
    8000331e:	47c9                	li	a5,18
    80003320:	28f98a63          	beq	s3,a5,800035b4 <syscall+0x358>
      else if(num == 19) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a0); // link
    80003324:	47cd                	li	a5,19
    80003326:	2af98763          	beq	s3,a5,800035d4 <syscall+0x378>
      else if(num == 20) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // mkdir
    8000332a:	47d1                	li	a5,20
    8000332c:	2cf98563          	beq	s3,a5,800035f6 <syscall+0x39a>
      else if(num == 21) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // close
    80003330:	47d5                	li	a5,21
    80003332:	2ef98263          	beq	s3,a5,80003616 <syscall+0x3ba>
      else if(num == 22) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // trace
    80003336:	47d9                	li	a5,22
    80003338:	2ef98f63          	beq	s3,a5,80003636 <syscall+0x3da>
      else if(num == 23) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a0); // sigalarm
    8000333c:	47dd                	li	a5,23
    8000333e:	30f98c63          	beq	s3,a5,80003656 <syscall+0x3fa>
      else if(num == 24) printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0); // sigreturn
    80003342:	47e1                	li	a5,24
    80003344:	32f98a63          	beq	s3,a5,80003678 <syscall+0x41c>
      else if(num == 25) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // settickets
    80003348:	47e5                	li	a5,25
    8000334a:	34f98763          	beq	s3,a5,80003698 <syscall+0x43c>
      else if(num == 26) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a1, p->trapframe->a2, p->trapframe->a0); // waitx
    8000334e:	47e9                	li	a5,26
    80003350:	36f98463          	beq	s3,a5,800036b8 <syscall+0x45c>
      else if(num == 27) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a1, p->trapframe->a0); // setpriority
    80003354:	47ed                	li	a5,27
    80003356:	3af99363          	bne	s3,a5,800036fc <syscall+0x4a0>
    8000335a:	6cb8                	ld	a4,88(s1)
    8000335c:	7b3c                	ld	a5,112(a4)
    8000335e:	7f38                	ld	a4,120(a4)
    80003360:	00006617          	auipc	a2,0x6
    80003364:	7e863603          	ld	a2,2024(a2) # 80009b48 <syscall_names+0xd8>
    80003368:	588c                	lw	a1,48(s1)
    8000336a:	00006517          	auipc	a0,0x6
    8000336e:	12e50513          	addi	a0,a0,302 # 80009498 <states.1811+0x1b0>
    80003372:	ffffd097          	auipc	ra,0xffffd
    80003376:	21c080e7          	jalr	540(ra) # 8000058e <printf>
    8000337a:	a649                	j	800036fc <syscall+0x4a0>
      if(num == 1)      printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0);   //fork  
    8000337c:	6cbc                	ld	a5,88(s1)
    8000337e:	7bb4                	ld	a3,112(a5)
    80003380:	00006617          	auipc	a2,0x6
    80003384:	6f863603          	ld	a2,1784(a2) # 80009a78 <syscall_names+0x8>
    80003388:	588c                	lw	a1,48(s1)
    8000338a:	00006517          	auipc	a0,0x6
    8000338e:	0ae50513          	addi	a0,a0,174 # 80009438 <states.1811+0x150>
    80003392:	ffffd097          	auipc	ra,0xffffd
    80003396:	1fc080e7          	jalr	508(ra) # 8000058e <printf>
    8000339a:	a68d                	j	800036fc <syscall+0x4a0>
      else if(num == 2) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // exit
    8000339c:	6cbc                	ld	a5,88(s1)
    8000339e:	7bb8                	ld	a4,112(a5)
    800033a0:	00006617          	auipc	a2,0x6
    800033a4:	6e063603          	ld	a2,1760(a2) # 80009a80 <syscall_names+0x10>
    800033a8:	588c                	lw	a1,48(s1)
    800033aa:	00006517          	auipc	a0,0x6
    800033ae:	0a650513          	addi	a0,a0,166 # 80009450 <states.1811+0x168>
    800033b2:	ffffd097          	auipc	ra,0xffffd
    800033b6:	1dc080e7          	jalr	476(ra) # 8000058e <printf>
    800033ba:	a689                	j	800036fc <syscall+0x4a0>
      else if(num == 3) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // wait
    800033bc:	6cbc                	ld	a5,88(s1)
    800033be:	7bb8                	ld	a4,112(a5)
    800033c0:	00006617          	auipc	a2,0x6
    800033c4:	6c863603          	ld	a2,1736(a2) # 80009a88 <syscall_names+0x18>
    800033c8:	588c                	lw	a1,48(s1)
    800033ca:	00006517          	auipc	a0,0x6
    800033ce:	08650513          	addi	a0,a0,134 # 80009450 <states.1811+0x168>
    800033d2:	ffffd097          	auipc	ra,0xffffd
    800033d6:	1bc080e7          	jalr	444(ra) # 8000058e <printf>
    800033da:	a60d                	j	800036fc <syscall+0x4a0>
      else if(num == 4) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // pipe
    800033dc:	6cbc                	ld	a5,88(s1)
    800033de:	7bb8                	ld	a4,112(a5)
    800033e0:	00006617          	auipc	a2,0x6
    800033e4:	6b063603          	ld	a2,1712(a2) # 80009a90 <syscall_names+0x20>
    800033e8:	588c                	lw	a1,48(s1)
    800033ea:	00006517          	auipc	a0,0x6
    800033ee:	06650513          	addi	a0,a0,102 # 80009450 <states.1811+0x168>
    800033f2:	ffffd097          	auipc	ra,0xffffd
    800033f6:	19c080e7          	jalr	412(ra) # 8000058e <printf>
    800033fa:	a609                	j	800036fc <syscall+0x4a0>
      else if(num == 5) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp,  p->trapframe->a1,  p->trapframe->a2, p->trapframe->a0);  // read
    800033fc:	6cb8                	ld	a4,88(s1)
    800033fe:	07073803          	ld	a6,112(a4)
    80003402:	635c                	ld	a5,128(a4)
    80003404:	7f38                	ld	a4,120(a4)
    80003406:	00006617          	auipc	a2,0x6
    8000340a:	69263603          	ld	a2,1682(a2) # 80009a98 <syscall_names+0x28>
    8000340e:	588c                	lw	a1,48(s1)
    80003410:	00006517          	auipc	a0,0x6
    80003414:	06050513          	addi	a0,a0,96 # 80009470 <states.1811+0x188>
    80003418:	ffffd097          	auipc	ra,0xffffd
    8000341c:	176080e7          	jalr	374(ra) # 8000058e <printf>
    80003420:	acf1                	j	800036fc <syscall+0x4a0>
      else if(num == 6) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // kill
    80003422:	6cbc                	ld	a5,88(s1)
    80003424:	7bb8                	ld	a4,112(a5)
    80003426:	00006617          	auipc	a2,0x6
    8000342a:	67a63603          	ld	a2,1658(a2) # 80009aa0 <syscall_names+0x30>
    8000342e:	588c                	lw	a1,48(s1)
    80003430:	00006517          	auipc	a0,0x6
    80003434:	02050513          	addi	a0,a0,32 # 80009450 <states.1811+0x168>
    80003438:	ffffd097          	auipc	ra,0xffffd
    8000343c:	156080e7          	jalr	342(ra) # 8000058e <printf>
    80003440:	ac75                	j	800036fc <syscall+0x4a0>
      else if(num == 7) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp,  p->trapframe->a1, p->trapframe->a0);   // exec
    80003442:	6cb8                	ld	a4,88(s1)
    80003444:	7b3c                	ld	a5,112(a4)
    80003446:	7f38                	ld	a4,120(a4)
    80003448:	00006617          	auipc	a2,0x6
    8000344c:	66063603          	ld	a2,1632(a2) # 80009aa8 <syscall_names+0x38>
    80003450:	588c                	lw	a1,48(s1)
    80003452:	00006517          	auipc	a0,0x6
    80003456:	04650513          	addi	a0,a0,70 # 80009498 <states.1811+0x1b0>
    8000345a:	ffffd097          	auipc	ra,0xffffd
    8000345e:	134080e7          	jalr	308(ra) # 8000058e <printf>
    80003462:	ac69                	j	800036fc <syscall+0x4a0>
      else if(num == 8) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp,  p->trapframe->a1, p->trapframe->a0);  // fstat
    80003464:	6cb8                	ld	a4,88(s1)
    80003466:	7b3c                	ld	a5,112(a4)
    80003468:	7f38                	ld	a4,120(a4)
    8000346a:	00006617          	auipc	a2,0x6
    8000346e:	64663603          	ld	a2,1606(a2) # 80009ab0 <syscall_names+0x40>
    80003472:	588c                	lw	a1,48(s1)
    80003474:	00006517          	auipc	a0,0x6
    80003478:	02450513          	addi	a0,a0,36 # 80009498 <states.1811+0x1b0>
    8000347c:	ffffd097          	auipc	ra,0xffffd
    80003480:	112080e7          	jalr	274(ra) # 8000058e <printf>
    80003484:	aca5                	j	800036fc <syscall+0x4a0>
      else if(num == 9) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // chdir
    80003486:	6cbc                	ld	a5,88(s1)
    80003488:	7bb8                	ld	a4,112(a5)
    8000348a:	00006617          	auipc	a2,0x6
    8000348e:	62e63603          	ld	a2,1582(a2) # 80009ab8 <syscall_names+0x48>
    80003492:	588c                	lw	a1,48(s1)
    80003494:	00006517          	auipc	a0,0x6
    80003498:	fbc50513          	addi	a0,a0,-68 # 80009450 <states.1811+0x168>
    8000349c:	ffffd097          	auipc	ra,0xffffd
    800034a0:	0f2080e7          	jalr	242(ra) # 8000058e <printf>
    800034a4:	aca1                	j	800036fc <syscall+0x4a0>
      else if(num == 10) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // dup
    800034a6:	6cbc                	ld	a5,88(s1)
    800034a8:	7bb8                	ld	a4,112(a5)
    800034aa:	00006617          	auipc	a2,0x6
    800034ae:	61663603          	ld	a2,1558(a2) # 80009ac0 <syscall_names+0x50>
    800034b2:	588c                	lw	a1,48(s1)
    800034b4:	00006517          	auipc	a0,0x6
    800034b8:	f9c50513          	addi	a0,a0,-100 # 80009450 <states.1811+0x168>
    800034bc:	ffffd097          	auipc	ra,0xffffd
    800034c0:	0d2080e7          	jalr	210(ra) # 8000058e <printf>
    800034c4:	ac25                	j	800036fc <syscall+0x4a0>
      else if(num == 11) printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0);  // getpid
    800034c6:	6cbc                	ld	a5,88(s1)
    800034c8:	7bb4                	ld	a3,112(a5)
    800034ca:	00006617          	auipc	a2,0x6
    800034ce:	5fe63603          	ld	a2,1534(a2) # 80009ac8 <syscall_names+0x58>
    800034d2:	588c                	lw	a1,48(s1)
    800034d4:	00006517          	auipc	a0,0x6
    800034d8:	f6450513          	addi	a0,a0,-156 # 80009438 <states.1811+0x150>
    800034dc:	ffffd097          	auipc	ra,0xffffd
    800034e0:	0b2080e7          	jalr	178(ra) # 8000058e <printf>
    800034e4:	ac21                	j	800036fc <syscall+0x4a0>
      else if(num == 12) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // sbrk
    800034e6:	6cbc                	ld	a5,88(s1)
    800034e8:	7bb8                	ld	a4,112(a5)
    800034ea:	00006617          	auipc	a2,0x6
    800034ee:	5e663603          	ld	a2,1510(a2) # 80009ad0 <syscall_names+0x60>
    800034f2:	588c                	lw	a1,48(s1)
    800034f4:	00006517          	auipc	a0,0x6
    800034f8:	f5c50513          	addi	a0,a0,-164 # 80009450 <states.1811+0x168>
    800034fc:	ffffd097          	auipc	ra,0xffffd
    80003500:	092080e7          	jalr	146(ra) # 8000058e <printf>
    80003504:	aae5                	j	800036fc <syscall+0x4a0>
      else if(num == 13) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0);  // sleep
    80003506:	6cbc                	ld	a5,88(s1)
    80003508:	7bb8                	ld	a4,112(a5)
    8000350a:	00006617          	auipc	a2,0x6
    8000350e:	5ce63603          	ld	a2,1486(a2) # 80009ad8 <syscall_names+0x68>
    80003512:	588c                	lw	a1,48(s1)
    80003514:	00006517          	auipc	a0,0x6
    80003518:	f3c50513          	addi	a0,a0,-196 # 80009450 <states.1811+0x168>
    8000351c:	ffffd097          	auipc	ra,0xffffd
    80003520:	072080e7          	jalr	114(ra) # 8000058e <printf>
    80003524:	aae1                	j	800036fc <syscall+0x4a0>
      else if(num == 14) printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0); // uptime
    80003526:	6cbc                	ld	a5,88(s1)
    80003528:	7bb4                	ld	a3,112(a5)
    8000352a:	00006617          	auipc	a2,0x6
    8000352e:	5b663603          	ld	a2,1462(a2) # 80009ae0 <syscall_names+0x70>
    80003532:	588c                	lw	a1,48(s1)
    80003534:	00006517          	auipc	a0,0x6
    80003538:	f0450513          	addi	a0,a0,-252 # 80009438 <states.1811+0x150>
    8000353c:	ffffd097          	auipc	ra,0xffffd
    80003540:	052080e7          	jalr	82(ra) # 8000058e <printf>
    80003544:	aa65                	j	800036fc <syscall+0x4a0>
      else if(num == 15) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a0); // open
    80003546:	6cb8                	ld	a4,88(s1)
    80003548:	7b3c                	ld	a5,112(a4)
    8000354a:	6358                	ld	a4,128(a4)
    8000354c:	00006617          	auipc	a2,0x6
    80003550:	59c63603          	ld	a2,1436(a2) # 80009ae8 <syscall_names+0x78>
    80003554:	588c                	lw	a1,48(s1)
    80003556:	00006517          	auipc	a0,0x6
    8000355a:	f4250513          	addi	a0,a0,-190 # 80009498 <states.1811+0x1b0>
    8000355e:	ffffd097          	auipc	ra,0xffffd
    80003562:	030080e7          	jalr	48(ra) # 8000058e <printf>
    80003566:	aa59                	j	800036fc <syscall+0x4a0>
      else if(num == 16) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a3, p->trapframe->a0); // write
    80003568:	6cb8                	ld	a4,88(s1)
    8000356a:	07073803          	ld	a6,112(a4)
    8000356e:	675c                	ld	a5,136(a4)
    80003570:	6358                	ld	a4,128(a4)
    80003572:	00006617          	auipc	a2,0x6
    80003576:	57e63603          	ld	a2,1406(a2) # 80009af0 <syscall_names+0x80>
    8000357a:	588c                	lw	a1,48(s1)
    8000357c:	00006517          	auipc	a0,0x6
    80003580:	ef450513          	addi	a0,a0,-268 # 80009470 <states.1811+0x188>
    80003584:	ffffd097          	auipc	ra,0xffffd
    80003588:	00a080e7          	jalr	10(ra) # 8000058e <printf>
    8000358c:	aa85                	j	800036fc <syscall+0x4a0>
      else if(num == 17) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a3, p->trapframe->a0); // mknod
    8000358e:	6cb8                	ld	a4,88(s1)
    80003590:	07073803          	ld	a6,112(a4)
    80003594:	675c                	ld	a5,136(a4)
    80003596:	6358                	ld	a4,128(a4)
    80003598:	00006617          	auipc	a2,0x6
    8000359c:	56063603          	ld	a2,1376(a2) # 80009af8 <syscall_names+0x88>
    800035a0:	588c                	lw	a1,48(s1)
    800035a2:	00006517          	auipc	a0,0x6
    800035a6:	ece50513          	addi	a0,a0,-306 # 80009470 <states.1811+0x188>
    800035aa:	ffffd097          	auipc	ra,0xffffd
    800035ae:	fe4080e7          	jalr	-28(ra) # 8000058e <printf>
    800035b2:	a2a9                	j	800036fc <syscall+0x4a0>
      else if(num == 18) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // unlink
    800035b4:	6cbc                	ld	a5,88(s1)
    800035b6:	7bb8                	ld	a4,112(a5)
    800035b8:	00006617          	auipc	a2,0x6
    800035bc:	54863603          	ld	a2,1352(a2) # 80009b00 <syscall_names+0x90>
    800035c0:	588c                	lw	a1,48(s1)
    800035c2:	00006517          	auipc	a0,0x6
    800035c6:	e8e50513          	addi	a0,a0,-370 # 80009450 <states.1811+0x168>
    800035ca:	ffffd097          	auipc	ra,0xffffd
    800035ce:	fc4080e7          	jalr	-60(ra) # 8000058e <printf>
    800035d2:	a22d                	j	800036fc <syscall+0x4a0>
      else if(num == 19) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a0); // link
    800035d4:	6cb8                	ld	a4,88(s1)
    800035d6:	7b3c                	ld	a5,112(a4)
    800035d8:	6358                	ld	a4,128(a4)
    800035da:	00006617          	auipc	a2,0x6
    800035de:	52e63603          	ld	a2,1326(a2) # 80009b08 <syscall_names+0x98>
    800035e2:	588c                	lw	a1,48(s1)
    800035e4:	00006517          	auipc	a0,0x6
    800035e8:	eb450513          	addi	a0,a0,-332 # 80009498 <states.1811+0x1b0>
    800035ec:	ffffd097          	auipc	ra,0xffffd
    800035f0:	fa2080e7          	jalr	-94(ra) # 8000058e <printf>
    800035f4:	a221                	j	800036fc <syscall+0x4a0>
      else if(num == 20) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // mkdir
    800035f6:	6cbc                	ld	a5,88(s1)
    800035f8:	7bb8                	ld	a4,112(a5)
    800035fa:	00006617          	auipc	a2,0x6
    800035fe:	51663603          	ld	a2,1302(a2) # 80009b10 <syscall_names+0xa0>
    80003602:	588c                	lw	a1,48(s1)
    80003604:	00006517          	auipc	a0,0x6
    80003608:	e4c50513          	addi	a0,a0,-436 # 80009450 <states.1811+0x168>
    8000360c:	ffffd097          	auipc	ra,0xffffd
    80003610:	f82080e7          	jalr	-126(ra) # 8000058e <printf>
    80003614:	a0e5                	j	800036fc <syscall+0x4a0>
      else if(num == 21) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // close
    80003616:	6cbc                	ld	a5,88(s1)
    80003618:	7bb8                	ld	a4,112(a5)
    8000361a:	00006617          	auipc	a2,0x6
    8000361e:	4fe63603          	ld	a2,1278(a2) # 80009b18 <syscall_names+0xa8>
    80003622:	588c                	lw	a1,48(s1)
    80003624:	00006517          	auipc	a0,0x6
    80003628:	e2c50513          	addi	a0,a0,-468 # 80009450 <states.1811+0x168>
    8000362c:	ffffd097          	auipc	ra,0xffffd
    80003630:	f62080e7          	jalr	-158(ra) # 8000058e <printf>
    80003634:	a0e1                	j	800036fc <syscall+0x4a0>
      else if(num == 22) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // trace
    80003636:	6cbc                	ld	a5,88(s1)
    80003638:	7bb8                	ld	a4,112(a5)
    8000363a:	00006617          	auipc	a2,0x6
    8000363e:	4e663603          	ld	a2,1254(a2) # 80009b20 <syscall_names+0xb0>
    80003642:	588c                	lw	a1,48(s1)
    80003644:	00006517          	auipc	a0,0x6
    80003648:	e0c50513          	addi	a0,a0,-500 # 80009450 <states.1811+0x168>
    8000364c:	ffffd097          	auipc	ra,0xffffd
    80003650:	f42080e7          	jalr	-190(ra) # 8000058e <printf>
    80003654:	a065                	j	800036fc <syscall+0x4a0>
      else if(num == 23) printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a2, p->trapframe->a0); // sigalarm
    80003656:	6cb8                	ld	a4,88(s1)
    80003658:	7b3c                	ld	a5,112(a4)
    8000365a:	6358                	ld	a4,128(a4)
    8000365c:	00006617          	auipc	a2,0x6
    80003660:	4cc63603          	ld	a2,1228(a2) # 80009b28 <syscall_names+0xb8>
    80003664:	588c                	lw	a1,48(s1)
    80003666:	00006517          	auipc	a0,0x6
    8000366a:	e3250513          	addi	a0,a0,-462 # 80009498 <states.1811+0x1b0>
    8000366e:	ffffd097          	auipc	ra,0xffffd
    80003672:	f20080e7          	jalr	-224(ra) # 8000058e <printf>
    80003676:	a059                	j	800036fc <syscall+0x4a0>
      else if(num == 24) printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0); // sigreturn
    80003678:	6cbc                	ld	a5,88(s1)
    8000367a:	7bb4                	ld	a3,112(a5)
    8000367c:	00006617          	auipc	a2,0x6
    80003680:	4b463603          	ld	a2,1204(a2) # 80009b30 <syscall_names+0xc0>
    80003684:	588c                	lw	a1,48(s1)
    80003686:	00006517          	auipc	a0,0x6
    8000368a:	db250513          	addi	a0,a0,-590 # 80009438 <states.1811+0x150>
    8000368e:	ffffd097          	auipc	ra,0xffffd
    80003692:	f00080e7          	jalr	-256(ra) # 8000058e <printf>
    80003696:	a09d                	j	800036fc <syscall+0x4a0>
      else if(num == 25) printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a0); // settickets
    80003698:	6cbc                	ld	a5,88(s1)
    8000369a:	7bb8                	ld	a4,112(a5)
    8000369c:	00006617          	auipc	a2,0x6
    800036a0:	49c63603          	ld	a2,1180(a2) # 80009b38 <syscall_names+0xc8>
    800036a4:	588c                	lw	a1,48(s1)
    800036a6:	00006517          	auipc	a0,0x6
    800036aa:	daa50513          	addi	a0,a0,-598 # 80009450 <states.1811+0x168>
    800036ae:	ffffd097          	auipc	ra,0xffffd
    800036b2:	ee0080e7          	jalr	-288(ra) # 8000058e <printf>
    800036b6:	a099                	j	800036fc <syscall+0x4a0>
      else if(num == 26) printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], tmp, p->trapframe->a1, p->trapframe->a2, p->trapframe->a0); // waitx
    800036b8:	6cb8                	ld	a4,88(s1)
    800036ba:	07073803          	ld	a6,112(a4)
    800036be:	635c                	ld	a5,128(a4)
    800036c0:	7f38                	ld	a4,120(a4)
    800036c2:	00006617          	auipc	a2,0x6
    800036c6:	47e63603          	ld	a2,1150(a2) # 80009b40 <syscall_names+0xd0>
    800036ca:	588c                	lw	a1,48(s1)
    800036cc:	00006517          	auipc	a0,0x6
    800036d0:	da450513          	addi	a0,a0,-604 # 80009470 <states.1811+0x188>
    800036d4:	ffffd097          	auipc	ra,0xffffd
    800036d8:	eba080e7          	jalr	-326(ra) # 8000058e <printf>
    800036dc:	a005                	j	800036fc <syscall+0x4a0>
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    800036de:	86ce                	mv	a3,s3
    800036e0:	15848613          	addi	a2,s1,344
    800036e4:	588c                	lw	a1,48(s1)
    800036e6:	00006517          	auipc	a0,0x6
    800036ea:	dd250513          	addi	a0,a0,-558 # 800094b8 <states.1811+0x1d0>
    800036ee:	ffffd097          	auipc	ra,0xffffd
    800036f2:	ea0080e7          	jalr	-352(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800036f6:	6cbc                	ld	a5,88(s1)
    800036f8:	577d                	li	a4,-1
    800036fa:	fbb8                	sd	a4,112(a5)
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

000000008000370c <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000370c:	1101                	addi	sp,sp,-32
    8000370e:	ec06                	sd	ra,24(sp)
    80003710:	e822                	sd	s0,16(sp)
    80003712:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80003714:	fec40593          	addi	a1,s0,-20
    80003718:	4501                	li	a0,0
    8000371a:	00000097          	auipc	ra,0x0
    8000371e:	aca080e7          	jalr	-1334(ra) # 800031e4 <argint>
  exit(n);
    80003722:	fec42503          	lw	a0,-20(s0)
    80003726:	fffff097          	auipc	ra,0xfffff
    8000372a:	fb0080e7          	jalr	-80(ra) # 800026d6 <exit>
  return 0;  // not reached
}
    8000372e:	4501                	li	a0,0
    80003730:	60e2                	ld	ra,24(sp)
    80003732:	6442                	ld	s0,16(sp)
    80003734:	6105                	addi	sp,sp,32
    80003736:	8082                	ret

0000000080003738 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003738:	1141                	addi	sp,sp,-16
    8000373a:	e406                	sd	ra,8(sp)
    8000373c:	e022                	sd	s0,0(sp)
    8000373e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003740:	ffffe097          	auipc	ra,0xffffe
    80003744:	4b6080e7          	jalr	1206(ra) # 80001bf6 <myproc>
}
    80003748:	5908                	lw	a0,48(a0)
    8000374a:	60a2                	ld	ra,8(sp)
    8000374c:	6402                	ld	s0,0(sp)
    8000374e:	0141                	addi	sp,sp,16
    80003750:	8082                	ret

0000000080003752 <sys_fork>:

uint64
sys_fork(void)
{
    80003752:	1141                	addi	sp,sp,-16
    80003754:	e406                	sd	ra,8(sp)
    80003756:	e022                	sd	s0,0(sp)
    80003758:	0800                	addi	s0,sp,16
  return fork();
    8000375a:	fffff097          	auipc	ra,0xfffff
    8000375e:	8a8080e7          	jalr	-1880(ra) # 80002002 <fork>
}
    80003762:	60a2                	ld	ra,8(sp)
    80003764:	6402                	ld	s0,0(sp)
    80003766:	0141                	addi	sp,sp,16
    80003768:	8082                	ret

000000008000376a <sys_wait>:

uint64
sys_wait(void)
{
    8000376a:	1101                	addi	sp,sp,-32
    8000376c:	ec06                	sd	ra,24(sp)
    8000376e:	e822                	sd	s0,16(sp)
    80003770:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003772:	fe840593          	addi	a1,s0,-24
    80003776:	4501                	li	a0,0
    80003778:	00000097          	auipc	ra,0x0
    8000377c:	a8c080e7          	jalr	-1396(ra) # 80003204 <argaddr>
  return wait(p);
    80003780:	fe843503          	ld	a0,-24(s0)
    80003784:	fffff097          	auipc	ra,0xfffff
    80003788:	104080e7          	jalr	260(ra) # 80002888 <wait>
}
    8000378c:	60e2                	ld	ra,24(sp)
    8000378e:	6442                	ld	s0,16(sp)
    80003790:	6105                	addi	sp,sp,32
    80003792:	8082                	ret

0000000080003794 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003794:	7179                	addi	sp,sp,-48
    80003796:	f406                	sd	ra,40(sp)
    80003798:	f022                	sd	s0,32(sp)
    8000379a:	ec26                	sd	s1,24(sp)
    8000379c:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    8000379e:	fdc40593          	addi	a1,s0,-36
    800037a2:	4501                	li	a0,0
    800037a4:	00000097          	auipc	ra,0x0
    800037a8:	a40080e7          	jalr	-1472(ra) # 800031e4 <argint>
  addr = myproc()->sz;
    800037ac:	ffffe097          	auipc	ra,0xffffe
    800037b0:	44a080e7          	jalr	1098(ra) # 80001bf6 <myproc>
    800037b4:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    800037b6:	fdc42503          	lw	a0,-36(s0)
    800037ba:	ffffe097          	auipc	ra,0xffffe
    800037be:	7ec080e7          	jalr	2028(ra) # 80001fa6 <growproc>
    800037c2:	00054863          	bltz	a0,800037d2 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    800037c6:	8526                	mv	a0,s1
    800037c8:	70a2                	ld	ra,40(sp)
    800037ca:	7402                	ld	s0,32(sp)
    800037cc:	64e2                	ld	s1,24(sp)
    800037ce:	6145                	addi	sp,sp,48
    800037d0:	8082                	ret
    return -1;
    800037d2:	54fd                	li	s1,-1
    800037d4:	bfcd                	j	800037c6 <sys_sbrk+0x32>

00000000800037d6 <sys_sleep>:

uint64
sys_sleep(void)
{
    800037d6:	7139                	addi	sp,sp,-64
    800037d8:	fc06                	sd	ra,56(sp)
    800037da:	f822                	sd	s0,48(sp)
    800037dc:	f426                	sd	s1,40(sp)
    800037de:	f04a                	sd	s2,32(sp)
    800037e0:	ec4e                	sd	s3,24(sp)
    800037e2:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800037e4:	fcc40593          	addi	a1,s0,-52
    800037e8:	4501                	li	a0,0
    800037ea:	00000097          	auipc	ra,0x0
    800037ee:	9fa080e7          	jalr	-1542(ra) # 800031e4 <argint>
  acquire(&tickslock);
    800037f2:	00016517          	auipc	a0,0x16
    800037f6:	6c650513          	addi	a0,a0,1734 # 80019eb8 <tickslock>
    800037fa:	ffffd097          	auipc	ra,0xffffd
    800037fe:	3f0080e7          	jalr	1008(ra) # 80000bea <acquire>
  ticks0 = ticks;
    80003802:	00006917          	auipc	s2,0x6
    80003806:	39e92903          	lw	s2,926(s2) # 80009ba0 <ticks>
  while(ticks - ticks0 < n){
    8000380a:	fcc42783          	lw	a5,-52(s0)
    8000380e:	cf9d                	beqz	a5,8000384c <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003810:	00016997          	auipc	s3,0x16
    80003814:	6a898993          	addi	s3,s3,1704 # 80019eb8 <tickslock>
    80003818:	00006497          	auipc	s1,0x6
    8000381c:	38848493          	addi	s1,s1,904 # 80009ba0 <ticks>
    if(killed(myproc())){
    80003820:	ffffe097          	auipc	ra,0xffffe
    80003824:	3d6080e7          	jalr	982(ra) # 80001bf6 <myproc>
    80003828:	fffff097          	auipc	ra,0xfffff
    8000382c:	02e080e7          	jalr	46(ra) # 80002856 <killed>
    80003830:	ed15                	bnez	a0,8000386c <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003832:	85ce                	mv	a1,s3
    80003834:	8526                	mv	a0,s1
    80003836:	fffff097          	auipc	ra,0xfffff
    8000383a:	c20080e7          	jalr	-992(ra) # 80002456 <sleep>
  while(ticks - ticks0 < n){
    8000383e:	409c                	lw	a5,0(s1)
    80003840:	412787bb          	subw	a5,a5,s2
    80003844:	fcc42703          	lw	a4,-52(s0)
    80003848:	fce7ece3          	bltu	a5,a4,80003820 <sys_sleep+0x4a>
  }
  release(&tickslock);
    8000384c:	00016517          	auipc	a0,0x16
    80003850:	66c50513          	addi	a0,a0,1644 # 80019eb8 <tickslock>
    80003854:	ffffd097          	auipc	ra,0xffffd
    80003858:	44a080e7          	jalr	1098(ra) # 80000c9e <release>
  return 0;
    8000385c:	4501                	li	a0,0
}
    8000385e:	70e2                	ld	ra,56(sp)
    80003860:	7442                	ld	s0,48(sp)
    80003862:	74a2                	ld	s1,40(sp)
    80003864:	7902                	ld	s2,32(sp)
    80003866:	69e2                	ld	s3,24(sp)
    80003868:	6121                	addi	sp,sp,64
    8000386a:	8082                	ret
      release(&tickslock);
    8000386c:	00016517          	auipc	a0,0x16
    80003870:	64c50513          	addi	a0,a0,1612 # 80019eb8 <tickslock>
    80003874:	ffffd097          	auipc	ra,0xffffd
    80003878:	42a080e7          	jalr	1066(ra) # 80000c9e <release>
      return -1;
    8000387c:	557d                	li	a0,-1
    8000387e:	b7c5                	j	8000385e <sys_sleep+0x88>

0000000080003880 <sys_kill>:

uint64
sys_kill(void)
{
    80003880:	1101                	addi	sp,sp,-32
    80003882:	ec06                	sd	ra,24(sp)
    80003884:	e822                	sd	s0,16(sp)
    80003886:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003888:	fec40593          	addi	a1,s0,-20
    8000388c:	4501                	li	a0,0
    8000388e:	00000097          	auipc	ra,0x0
    80003892:	956080e7          	jalr	-1706(ra) # 800031e4 <argint>
  return kill(pid);
    80003896:	fec42503          	lw	a0,-20(s0)
    8000389a:	fffff097          	auipc	ra,0xfffff
    8000389e:	f1e080e7          	jalr	-226(ra) # 800027b8 <kill>
}
    800038a2:	60e2                	ld	ra,24(sp)
    800038a4:	6442                	ld	s0,16(sp)
    800038a6:	6105                	addi	sp,sp,32
    800038a8:	8082                	ret

00000000800038aa <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800038aa:	1101                	addi	sp,sp,-32
    800038ac:	ec06                	sd	ra,24(sp)
    800038ae:	e822                	sd	s0,16(sp)
    800038b0:	e426                	sd	s1,8(sp)
    800038b2:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800038b4:	00016517          	auipc	a0,0x16
    800038b8:	60450513          	addi	a0,a0,1540 # 80019eb8 <tickslock>
    800038bc:	ffffd097          	auipc	ra,0xffffd
    800038c0:	32e080e7          	jalr	814(ra) # 80000bea <acquire>
  xticks = ticks;
    800038c4:	00006497          	auipc	s1,0x6
    800038c8:	2dc4a483          	lw	s1,732(s1) # 80009ba0 <ticks>
  release(&tickslock);
    800038cc:	00016517          	auipc	a0,0x16
    800038d0:	5ec50513          	addi	a0,a0,1516 # 80019eb8 <tickslock>
    800038d4:	ffffd097          	auipc	ra,0xffffd
    800038d8:	3ca080e7          	jalr	970(ra) # 80000c9e <release>
  return xticks;
}
    800038dc:	02049513          	slli	a0,s1,0x20
    800038e0:	9101                	srli	a0,a0,0x20
    800038e2:	60e2                	ld	ra,24(sp)
    800038e4:	6442                	ld	s0,16(sp)
    800038e6:	64a2                	ld	s1,8(sp)
    800038e8:	6105                	addi	sp,sp,32
    800038ea:	8082                	ret

00000000800038ec <sys_trace>:

// sets the trace_flag to the first argument (a0)
uint64
sys_trace(void)
{
    800038ec:	1141                	addi	sp,sp,-16
    800038ee:	e406                	sd	ra,8(sp)
    800038f0:	e022                	sd	s0,0(sp)
    800038f2:	0800                	addi	s0,sp,16
  argint(0, &myproc()->trace_flag); //arg(a0, trace_flag) // returns void
    800038f4:	ffffe097          	auipc	ra,0xffffe
    800038f8:	302080e7          	jalr	770(ra) # 80001bf6 <myproc>
    800038fc:	17450593          	addi	a1,a0,372
    80003900:	4501                	li	a0,0
    80003902:	00000097          	auipc	ra,0x0
    80003906:	8e2080e7          	jalr	-1822(ra) # 800031e4 <argint>
  return 0;
}
    8000390a:	4501                	li	a0,0
    8000390c:	60a2                	ld	ra,8(sp)
    8000390e:	6402                	ld	s0,0(sp)
    80003910:	0141                	addi	sp,sp,16
    80003912:	8082                	ret

0000000080003914 <sys_sigalarm>:

// sets the 
uint64
sys_sigalarm(void)
{
    80003914:	1101                	addi	sp,sp,-32
    80003916:	ec06                	sd	ra,24(sp)
    80003918:	e822                	sd	s0,16(sp)
    8000391a:	e426                	sd	s1,8(sp)
    8000391c:	1000                	addi	s0,sp,32
  // sets the interval and handler after every tick
  argint(0, &myproc()->interval);
    8000391e:	ffffe097          	auipc	ra,0xffffe
    80003922:	2d8080e7          	jalr	728(ra) # 80001bf6 <myproc>
    80003926:	17850593          	addi	a1,a0,376
    8000392a:	4501                	li	a0,0
    8000392c:	00000097          	auipc	ra,0x0
    80003930:	8b8080e7          	jalr	-1864(ra) # 800031e4 <argint>
  argaddr(1, &myproc()->sig_handler);
    80003934:	ffffe097          	auipc	ra,0xffffe
    80003938:	2c2080e7          	jalr	706(ra) # 80001bf6 <myproc>
    8000393c:	18050593          	addi	a1,a0,384
    80003940:	4505                	li	a0,1
    80003942:	00000097          	auipc	ra,0x0
    80003946:	8c2080e7          	jalr	-1854(ra) # 80003204 <argaddr>
  
  // sets ticks_passed as the interval
  myproc()->ticks_left = myproc()->interval;
    8000394a:	ffffe097          	auipc	ra,0xffffe
    8000394e:	2ac080e7          	jalr	684(ra) # 80001bf6 <myproc>
    80003952:	84aa                	mv	s1,a0
    80003954:	ffffe097          	auipc	ra,0xffffe
    80003958:	2a2080e7          	jalr	674(ra) # 80001bf6 <myproc>
    8000395c:	1784a783          	lw	a5,376(s1)
    80003960:	16f52e23          	sw	a5,380(a0)
  return 0;
}
    80003964:	4501                	li	a0,0
    80003966:	60e2                	ld	ra,24(sp)
    80003968:	6442                	ld	s0,16(sp)
    8000396a:	64a2                	ld	s1,8(sp)
    8000396c:	6105                	addi	sp,sp,32
    8000396e:	8082                	ret

0000000080003970 <sys_sigreturn>:

uint64 
sys_sigreturn(void)
{
    80003970:	1101                	addi	sp,sp,-32
    80003972:	ec06                	sd	ra,24(sp)
    80003974:	e822                	sd	s0,16(sp)
    80003976:	e426                	sd	s1,8(sp)
    80003978:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000397a:	ffffe097          	auipc	ra,0xffffe
    8000397e:	27c080e7          	jalr	636(ra) # 80001bf6 <myproc>
    80003982:	84aa                	mv	s1,a0
  memmove(p->trapframe, p->sigalarm_tf, PGSIZE);
    80003984:	6605                	lui	a2,0x1
    80003986:	18853583          	ld	a1,392(a0)
    8000398a:	6d28                	ld	a0,88(a0)
    8000398c:	ffffd097          	auipc	ra,0xffffd
    80003990:	3ba080e7          	jalr	954(ra) # 80000d46 <memmove>
  kfree(p->sigalarm_tf);
    80003994:	1884b503          	ld	a0,392(s1)
    80003998:	ffffd097          	auipc	ra,0xffffd
    8000399c:	066080e7          	jalr	102(ra) # 800009fe <kfree>
  p->ticks_left = p->interval;
    800039a0:	1784a783          	lw	a5,376(s1)
    800039a4:	16f4ae23          	sw	a5,380(s1)
  return p->trapframe->a0;
    800039a8:	6cbc                	ld	a5,88(s1)
}
    800039aa:	7ba8                	ld	a0,112(a5)
    800039ac:	60e2                	ld	ra,24(sp)
    800039ae:	6442                	ld	s0,16(sp)
    800039b0:	64a2                	ld	s1,8(sp)
    800039b2:	6105                	addi	sp,sp,32
    800039b4:	8082                	ret

00000000800039b6 <sys_settickets>:

uint64 
sys_settickets(void)
{
    800039b6:	1141                	addi	sp,sp,-16
    800039b8:	e406                	sd	ra,8(sp)
    800039ba:	e022                	sd	s0,0(sp)
    800039bc:	0800                	addi	s0,sp,16
  argint(0, &myproc()->tickets);
    800039be:	ffffe097          	auipc	ra,0xffffe
    800039c2:	238080e7          	jalr	568(ra) # 80001bf6 <myproc>
    800039c6:	19450593          	addi	a1,a0,404
    800039ca:	4501                	li	a0,0
    800039cc:	00000097          	auipc	ra,0x0
    800039d0:	818080e7          	jalr	-2024(ra) # 800031e4 <argint>
  return myproc()->tickets;
    800039d4:	ffffe097          	auipc	ra,0xffffe
    800039d8:	222080e7          	jalr	546(ra) # 80001bf6 <myproc>
}
    800039dc:	19452503          	lw	a0,404(a0)
    800039e0:	60a2                	ld	ra,8(sp)
    800039e2:	6402                	ld	s0,0(sp)
    800039e4:	0141                	addi	sp,sp,16
    800039e6:	8082                	ret

00000000800039e8 <sys_waitx>:

uint64
sys_waitx(void)
{
    800039e8:	7139                	addi	sp,sp,-64
    800039ea:	fc06                	sd	ra,56(sp)
    800039ec:	f822                	sd	s0,48(sp)
    800039ee:	f426                	sd	s1,40(sp)
    800039f0:	f04a                	sd	s2,32(sp)
    800039f2:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800039f4:	fd840593          	addi	a1,s0,-40
    800039f8:	4501                	li	a0,0
    800039fa:	00000097          	auipc	ra,0x0
    800039fe:	80a080e7          	jalr	-2038(ra) # 80003204 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80003a02:	fd040593          	addi	a1,s0,-48
    80003a06:	4505                	li	a0,1
    80003a08:	fffff097          	auipc	ra,0xfffff
    80003a0c:	7fc080e7          	jalr	2044(ra) # 80003204 <argaddr>
  argaddr(2, &addr2);
    80003a10:	fc840593          	addi	a1,s0,-56
    80003a14:	4509                	li	a0,2
    80003a16:	fffff097          	auipc	ra,0xfffff
    80003a1a:	7ee080e7          	jalr	2030(ra) # 80003204 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003a1e:	fc040613          	addi	a2,s0,-64
    80003a22:	fc440593          	addi	a1,s0,-60
    80003a26:	fd843503          	ld	a0,-40(s0)
    80003a2a:	fffff097          	auipc	ra,0xfffff
    80003a2e:	a90080e7          	jalr	-1392(ra) # 800024ba <waitx>
    80003a32:	892a                	mv	s2,a0
  struct proc* p = myproc();
    80003a34:	ffffe097          	auipc	ra,0xffffe
    80003a38:	1c2080e7          	jalr	450(ra) # 80001bf6 <myproc>
    80003a3c:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80003a3e:	4691                	li	a3,4
    80003a40:	fc440613          	addi	a2,s0,-60
    80003a44:	fd043583          	ld	a1,-48(s0)
    80003a48:	6928                	ld	a0,80(a0)
    80003a4a:	ffffe097          	auipc	ra,0xffffe
    80003a4e:	c3a080e7          	jalr	-966(ra) # 80001684 <copyout>
    return -1;
    80003a52:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80003a54:	00054f63          	bltz	a0,80003a72 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    80003a58:	4691                	li	a3,4
    80003a5a:	fc040613          	addi	a2,s0,-64
    80003a5e:	fc843583          	ld	a1,-56(s0)
    80003a62:	68a8                	ld	a0,80(s1)
    80003a64:	ffffe097          	auipc	ra,0xffffe
    80003a68:	c20080e7          	jalr	-992(ra) # 80001684 <copyout>
    80003a6c:	00054a63          	bltz	a0,80003a80 <sys_waitx+0x98>
    return -1;
  return ret;
    80003a70:	87ca                	mv	a5,s2
}
    80003a72:	853e                	mv	a0,a5
    80003a74:	70e2                	ld	ra,56(sp)
    80003a76:	7442                	ld	s0,48(sp)
    80003a78:	74a2                	ld	s1,40(sp)
    80003a7a:	7902                	ld	s2,32(sp)
    80003a7c:	6121                	addi	sp,sp,64
    80003a7e:	8082                	ret
    return -1;
    80003a80:	57fd                	li	a5,-1
    80003a82:	bfc5                	j	80003a72 <sys_waitx+0x8a>

0000000080003a84 <sys_setpriority>:

uint64
sys_setpriority(void)
{
    80003a84:	1101                	addi	sp,sp,-32
    80003a86:	ec06                	sd	ra,24(sp)
    80003a88:	e822                	sd	s0,16(sp)
    80003a8a:	1000                	addi	s0,sp,32
  int new_priority, proc_pid;

  argint(0, &new_priority);
    80003a8c:	fec40593          	addi	a1,s0,-20
    80003a90:	4501                	li	a0,0
    80003a92:	fffff097          	auipc	ra,0xfffff
    80003a96:	752080e7          	jalr	1874(ra) # 800031e4 <argint>
  argint(1, &proc_pid);
    80003a9a:	fe840593          	addi	a1,s0,-24
    80003a9e:	4505                	li	a0,1
    80003aa0:	fffff097          	auipc	ra,0xfffff
    80003aa4:	744080e7          	jalr	1860(ra) # 800031e4 <argint>
  return setpriority(new_priority, proc_pid);
    80003aa8:	fe842583          	lw	a1,-24(s0)
    80003aac:	fec42503          	lw	a0,-20(s0)
    80003ab0:	fffff097          	auipc	ra,0xfffff
    80003ab4:	060080e7          	jalr	96(ra) # 80002b10 <setpriority>
}
    80003ab8:	60e2                	ld	ra,24(sp)
    80003aba:	6442                	ld	s0,16(sp)
    80003abc:	6105                	addi	sp,sp,32
    80003abe:	8082                	ret

0000000080003ac0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003ac0:	7179                	addi	sp,sp,-48
    80003ac2:	f406                	sd	ra,40(sp)
    80003ac4:	f022                	sd	s0,32(sp)
    80003ac6:	ec26                	sd	s1,24(sp)
    80003ac8:	e84a                	sd	s2,16(sp)
    80003aca:	e44e                	sd	s3,8(sp)
    80003acc:	e052                	sd	s4,0(sp)
    80003ace:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003ad0:	00006597          	auipc	a1,0x6
    80003ad4:	bf858593          	addi	a1,a1,-1032 # 800096c8 <syscalls+0xe0>
    80003ad8:	00016517          	auipc	a0,0x16
    80003adc:	3f850513          	addi	a0,a0,1016 # 80019ed0 <bcache>
    80003ae0:	ffffd097          	auipc	ra,0xffffd
    80003ae4:	07a080e7          	jalr	122(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003ae8:	0001e797          	auipc	a5,0x1e
    80003aec:	3e878793          	addi	a5,a5,1000 # 80021ed0 <bcache+0x8000>
    80003af0:	0001e717          	auipc	a4,0x1e
    80003af4:	64870713          	addi	a4,a4,1608 # 80022138 <bcache+0x8268>
    80003af8:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003afc:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003b00:	00016497          	auipc	s1,0x16
    80003b04:	3e848493          	addi	s1,s1,1000 # 80019ee8 <bcache+0x18>
    b->next = bcache.head.next;
    80003b08:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003b0a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003b0c:	00006a17          	auipc	s4,0x6
    80003b10:	bc4a0a13          	addi	s4,s4,-1084 # 800096d0 <syscalls+0xe8>
    b->next = bcache.head.next;
    80003b14:	2b893783          	ld	a5,696(s2)
    80003b18:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003b1a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003b1e:	85d2                	mv	a1,s4
    80003b20:	01048513          	addi	a0,s1,16
    80003b24:	00001097          	auipc	ra,0x1
    80003b28:	4c4080e7          	jalr	1220(ra) # 80004fe8 <initsleeplock>
    bcache.head.next->prev = b;
    80003b2c:	2b893783          	ld	a5,696(s2)
    80003b30:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003b32:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003b36:	45848493          	addi	s1,s1,1112
    80003b3a:	fd349de3          	bne	s1,s3,80003b14 <binit+0x54>
  }
}
    80003b3e:	70a2                	ld	ra,40(sp)
    80003b40:	7402                	ld	s0,32(sp)
    80003b42:	64e2                	ld	s1,24(sp)
    80003b44:	6942                	ld	s2,16(sp)
    80003b46:	69a2                	ld	s3,8(sp)
    80003b48:	6a02                	ld	s4,0(sp)
    80003b4a:	6145                	addi	sp,sp,48
    80003b4c:	8082                	ret

0000000080003b4e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003b4e:	7179                	addi	sp,sp,-48
    80003b50:	f406                	sd	ra,40(sp)
    80003b52:	f022                	sd	s0,32(sp)
    80003b54:	ec26                	sd	s1,24(sp)
    80003b56:	e84a                	sd	s2,16(sp)
    80003b58:	e44e                	sd	s3,8(sp)
    80003b5a:	1800                	addi	s0,sp,48
    80003b5c:	89aa                	mv	s3,a0
    80003b5e:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003b60:	00016517          	auipc	a0,0x16
    80003b64:	37050513          	addi	a0,a0,880 # 80019ed0 <bcache>
    80003b68:	ffffd097          	auipc	ra,0xffffd
    80003b6c:	082080e7          	jalr	130(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003b70:	0001e497          	auipc	s1,0x1e
    80003b74:	6184b483          	ld	s1,1560(s1) # 80022188 <bcache+0x82b8>
    80003b78:	0001e797          	auipc	a5,0x1e
    80003b7c:	5c078793          	addi	a5,a5,1472 # 80022138 <bcache+0x8268>
    80003b80:	02f48f63          	beq	s1,a5,80003bbe <bread+0x70>
    80003b84:	873e                	mv	a4,a5
    80003b86:	a021                	j	80003b8e <bread+0x40>
    80003b88:	68a4                	ld	s1,80(s1)
    80003b8a:	02e48a63          	beq	s1,a4,80003bbe <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003b8e:	449c                	lw	a5,8(s1)
    80003b90:	ff379ce3          	bne	a5,s3,80003b88 <bread+0x3a>
    80003b94:	44dc                	lw	a5,12(s1)
    80003b96:	ff2799e3          	bne	a5,s2,80003b88 <bread+0x3a>
      b->refcnt++;
    80003b9a:	40bc                	lw	a5,64(s1)
    80003b9c:	2785                	addiw	a5,a5,1
    80003b9e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003ba0:	00016517          	auipc	a0,0x16
    80003ba4:	33050513          	addi	a0,a0,816 # 80019ed0 <bcache>
    80003ba8:	ffffd097          	auipc	ra,0xffffd
    80003bac:	0f6080e7          	jalr	246(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80003bb0:	01048513          	addi	a0,s1,16
    80003bb4:	00001097          	auipc	ra,0x1
    80003bb8:	46e080e7          	jalr	1134(ra) # 80005022 <acquiresleep>
      return b;
    80003bbc:	a8b9                	j	80003c1a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003bbe:	0001e497          	auipc	s1,0x1e
    80003bc2:	5c24b483          	ld	s1,1474(s1) # 80022180 <bcache+0x82b0>
    80003bc6:	0001e797          	auipc	a5,0x1e
    80003bca:	57278793          	addi	a5,a5,1394 # 80022138 <bcache+0x8268>
    80003bce:	00f48863          	beq	s1,a5,80003bde <bread+0x90>
    80003bd2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003bd4:	40bc                	lw	a5,64(s1)
    80003bd6:	cf81                	beqz	a5,80003bee <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003bd8:	64a4                	ld	s1,72(s1)
    80003bda:	fee49de3          	bne	s1,a4,80003bd4 <bread+0x86>
  panic("bget: no buffers");
    80003bde:	00006517          	auipc	a0,0x6
    80003be2:	afa50513          	addi	a0,a0,-1286 # 800096d8 <syscalls+0xf0>
    80003be6:	ffffd097          	auipc	ra,0xffffd
    80003bea:	95e080e7          	jalr	-1698(ra) # 80000544 <panic>
      b->dev = dev;
    80003bee:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003bf2:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003bf6:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003bfa:	4785                	li	a5,1
    80003bfc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003bfe:	00016517          	auipc	a0,0x16
    80003c02:	2d250513          	addi	a0,a0,722 # 80019ed0 <bcache>
    80003c06:	ffffd097          	auipc	ra,0xffffd
    80003c0a:	098080e7          	jalr	152(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80003c0e:	01048513          	addi	a0,s1,16
    80003c12:	00001097          	auipc	ra,0x1
    80003c16:	410080e7          	jalr	1040(ra) # 80005022 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003c1a:	409c                	lw	a5,0(s1)
    80003c1c:	cb89                	beqz	a5,80003c2e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003c1e:	8526                	mv	a0,s1
    80003c20:	70a2                	ld	ra,40(sp)
    80003c22:	7402                	ld	s0,32(sp)
    80003c24:	64e2                	ld	s1,24(sp)
    80003c26:	6942                	ld	s2,16(sp)
    80003c28:	69a2                	ld	s3,8(sp)
    80003c2a:	6145                	addi	sp,sp,48
    80003c2c:	8082                	ret
    virtio_disk_rw(b, 0);
    80003c2e:	4581                	li	a1,0
    80003c30:	8526                	mv	a0,s1
    80003c32:	00003097          	auipc	ra,0x3
    80003c36:	fc6080e7          	jalr	-58(ra) # 80006bf8 <virtio_disk_rw>
    b->valid = 1;
    80003c3a:	4785                	li	a5,1
    80003c3c:	c09c                	sw	a5,0(s1)
  return b;
    80003c3e:	b7c5                	j	80003c1e <bread+0xd0>

0000000080003c40 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003c40:	1101                	addi	sp,sp,-32
    80003c42:	ec06                	sd	ra,24(sp)
    80003c44:	e822                	sd	s0,16(sp)
    80003c46:	e426                	sd	s1,8(sp)
    80003c48:	1000                	addi	s0,sp,32
    80003c4a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003c4c:	0541                	addi	a0,a0,16
    80003c4e:	00001097          	auipc	ra,0x1
    80003c52:	46e080e7          	jalr	1134(ra) # 800050bc <holdingsleep>
    80003c56:	cd01                	beqz	a0,80003c6e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003c58:	4585                	li	a1,1
    80003c5a:	8526                	mv	a0,s1
    80003c5c:	00003097          	auipc	ra,0x3
    80003c60:	f9c080e7          	jalr	-100(ra) # 80006bf8 <virtio_disk_rw>
}
    80003c64:	60e2                	ld	ra,24(sp)
    80003c66:	6442                	ld	s0,16(sp)
    80003c68:	64a2                	ld	s1,8(sp)
    80003c6a:	6105                	addi	sp,sp,32
    80003c6c:	8082                	ret
    panic("bwrite");
    80003c6e:	00006517          	auipc	a0,0x6
    80003c72:	a8250513          	addi	a0,a0,-1406 # 800096f0 <syscalls+0x108>
    80003c76:	ffffd097          	auipc	ra,0xffffd
    80003c7a:	8ce080e7          	jalr	-1842(ra) # 80000544 <panic>

0000000080003c7e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003c7e:	1101                	addi	sp,sp,-32
    80003c80:	ec06                	sd	ra,24(sp)
    80003c82:	e822                	sd	s0,16(sp)
    80003c84:	e426                	sd	s1,8(sp)
    80003c86:	e04a                	sd	s2,0(sp)
    80003c88:	1000                	addi	s0,sp,32
    80003c8a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003c8c:	01050913          	addi	s2,a0,16
    80003c90:	854a                	mv	a0,s2
    80003c92:	00001097          	auipc	ra,0x1
    80003c96:	42a080e7          	jalr	1066(ra) # 800050bc <holdingsleep>
    80003c9a:	c92d                	beqz	a0,80003d0c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003c9c:	854a                	mv	a0,s2
    80003c9e:	00001097          	auipc	ra,0x1
    80003ca2:	3da080e7          	jalr	986(ra) # 80005078 <releasesleep>

  acquire(&bcache.lock);
    80003ca6:	00016517          	auipc	a0,0x16
    80003caa:	22a50513          	addi	a0,a0,554 # 80019ed0 <bcache>
    80003cae:	ffffd097          	auipc	ra,0xffffd
    80003cb2:	f3c080e7          	jalr	-196(ra) # 80000bea <acquire>
  b->refcnt--;
    80003cb6:	40bc                	lw	a5,64(s1)
    80003cb8:	37fd                	addiw	a5,a5,-1
    80003cba:	0007871b          	sext.w	a4,a5
    80003cbe:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003cc0:	eb05                	bnez	a4,80003cf0 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003cc2:	68bc                	ld	a5,80(s1)
    80003cc4:	64b8                	ld	a4,72(s1)
    80003cc6:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003cc8:	64bc                	ld	a5,72(s1)
    80003cca:	68b8                	ld	a4,80(s1)
    80003ccc:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003cce:	0001e797          	auipc	a5,0x1e
    80003cd2:	20278793          	addi	a5,a5,514 # 80021ed0 <bcache+0x8000>
    80003cd6:	2b87b703          	ld	a4,696(a5)
    80003cda:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003cdc:	0001e717          	auipc	a4,0x1e
    80003ce0:	45c70713          	addi	a4,a4,1116 # 80022138 <bcache+0x8268>
    80003ce4:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003ce6:	2b87b703          	ld	a4,696(a5)
    80003cea:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003cec:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003cf0:	00016517          	auipc	a0,0x16
    80003cf4:	1e050513          	addi	a0,a0,480 # 80019ed0 <bcache>
    80003cf8:	ffffd097          	auipc	ra,0xffffd
    80003cfc:	fa6080e7          	jalr	-90(ra) # 80000c9e <release>
}
    80003d00:	60e2                	ld	ra,24(sp)
    80003d02:	6442                	ld	s0,16(sp)
    80003d04:	64a2                	ld	s1,8(sp)
    80003d06:	6902                	ld	s2,0(sp)
    80003d08:	6105                	addi	sp,sp,32
    80003d0a:	8082                	ret
    panic("brelse");
    80003d0c:	00006517          	auipc	a0,0x6
    80003d10:	9ec50513          	addi	a0,a0,-1556 # 800096f8 <syscalls+0x110>
    80003d14:	ffffd097          	auipc	ra,0xffffd
    80003d18:	830080e7          	jalr	-2000(ra) # 80000544 <panic>

0000000080003d1c <bpin>:

void
bpin(struct buf *b) {
    80003d1c:	1101                	addi	sp,sp,-32
    80003d1e:	ec06                	sd	ra,24(sp)
    80003d20:	e822                	sd	s0,16(sp)
    80003d22:	e426                	sd	s1,8(sp)
    80003d24:	1000                	addi	s0,sp,32
    80003d26:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003d28:	00016517          	auipc	a0,0x16
    80003d2c:	1a850513          	addi	a0,a0,424 # 80019ed0 <bcache>
    80003d30:	ffffd097          	auipc	ra,0xffffd
    80003d34:	eba080e7          	jalr	-326(ra) # 80000bea <acquire>
  b->refcnt++;
    80003d38:	40bc                	lw	a5,64(s1)
    80003d3a:	2785                	addiw	a5,a5,1
    80003d3c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003d3e:	00016517          	auipc	a0,0x16
    80003d42:	19250513          	addi	a0,a0,402 # 80019ed0 <bcache>
    80003d46:	ffffd097          	auipc	ra,0xffffd
    80003d4a:	f58080e7          	jalr	-168(ra) # 80000c9e <release>
}
    80003d4e:	60e2                	ld	ra,24(sp)
    80003d50:	6442                	ld	s0,16(sp)
    80003d52:	64a2                	ld	s1,8(sp)
    80003d54:	6105                	addi	sp,sp,32
    80003d56:	8082                	ret

0000000080003d58 <bunpin>:

void
bunpin(struct buf *b) {
    80003d58:	1101                	addi	sp,sp,-32
    80003d5a:	ec06                	sd	ra,24(sp)
    80003d5c:	e822                	sd	s0,16(sp)
    80003d5e:	e426                	sd	s1,8(sp)
    80003d60:	1000                	addi	s0,sp,32
    80003d62:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003d64:	00016517          	auipc	a0,0x16
    80003d68:	16c50513          	addi	a0,a0,364 # 80019ed0 <bcache>
    80003d6c:	ffffd097          	auipc	ra,0xffffd
    80003d70:	e7e080e7          	jalr	-386(ra) # 80000bea <acquire>
  b->refcnt--;
    80003d74:	40bc                	lw	a5,64(s1)
    80003d76:	37fd                	addiw	a5,a5,-1
    80003d78:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003d7a:	00016517          	auipc	a0,0x16
    80003d7e:	15650513          	addi	a0,a0,342 # 80019ed0 <bcache>
    80003d82:	ffffd097          	auipc	ra,0xffffd
    80003d86:	f1c080e7          	jalr	-228(ra) # 80000c9e <release>
}
    80003d8a:	60e2                	ld	ra,24(sp)
    80003d8c:	6442                	ld	s0,16(sp)
    80003d8e:	64a2                	ld	s1,8(sp)
    80003d90:	6105                	addi	sp,sp,32
    80003d92:	8082                	ret

0000000080003d94 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003d94:	1101                	addi	sp,sp,-32
    80003d96:	ec06                	sd	ra,24(sp)
    80003d98:	e822                	sd	s0,16(sp)
    80003d9a:	e426                	sd	s1,8(sp)
    80003d9c:	e04a                	sd	s2,0(sp)
    80003d9e:	1000                	addi	s0,sp,32
    80003da0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003da2:	00d5d59b          	srliw	a1,a1,0xd
    80003da6:	0001f797          	auipc	a5,0x1f
    80003daa:	8067a783          	lw	a5,-2042(a5) # 800225ac <sb+0x1c>
    80003dae:	9dbd                	addw	a1,a1,a5
    80003db0:	00000097          	auipc	ra,0x0
    80003db4:	d9e080e7          	jalr	-610(ra) # 80003b4e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003db8:	0074f713          	andi	a4,s1,7
    80003dbc:	4785                	li	a5,1
    80003dbe:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003dc2:	14ce                	slli	s1,s1,0x33
    80003dc4:	90d9                	srli	s1,s1,0x36
    80003dc6:	00950733          	add	a4,a0,s1
    80003dca:	05874703          	lbu	a4,88(a4)
    80003dce:	00e7f6b3          	and	a3,a5,a4
    80003dd2:	c69d                	beqz	a3,80003e00 <bfree+0x6c>
    80003dd4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003dd6:	94aa                	add	s1,s1,a0
    80003dd8:	fff7c793          	not	a5,a5
    80003ddc:	8ff9                	and	a5,a5,a4
    80003dde:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003de2:	00001097          	auipc	ra,0x1
    80003de6:	120080e7          	jalr	288(ra) # 80004f02 <log_write>
  brelse(bp);
    80003dea:	854a                	mv	a0,s2
    80003dec:	00000097          	auipc	ra,0x0
    80003df0:	e92080e7          	jalr	-366(ra) # 80003c7e <brelse>
}
    80003df4:	60e2                	ld	ra,24(sp)
    80003df6:	6442                	ld	s0,16(sp)
    80003df8:	64a2                	ld	s1,8(sp)
    80003dfa:	6902                	ld	s2,0(sp)
    80003dfc:	6105                	addi	sp,sp,32
    80003dfe:	8082                	ret
    panic("freeing free block");
    80003e00:	00006517          	auipc	a0,0x6
    80003e04:	90050513          	addi	a0,a0,-1792 # 80009700 <syscalls+0x118>
    80003e08:	ffffc097          	auipc	ra,0xffffc
    80003e0c:	73c080e7          	jalr	1852(ra) # 80000544 <panic>

0000000080003e10 <balloc>:
{
    80003e10:	711d                	addi	sp,sp,-96
    80003e12:	ec86                	sd	ra,88(sp)
    80003e14:	e8a2                	sd	s0,80(sp)
    80003e16:	e4a6                	sd	s1,72(sp)
    80003e18:	e0ca                	sd	s2,64(sp)
    80003e1a:	fc4e                	sd	s3,56(sp)
    80003e1c:	f852                	sd	s4,48(sp)
    80003e1e:	f456                	sd	s5,40(sp)
    80003e20:	f05a                	sd	s6,32(sp)
    80003e22:	ec5e                	sd	s7,24(sp)
    80003e24:	e862                	sd	s8,16(sp)
    80003e26:	e466                	sd	s9,8(sp)
    80003e28:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003e2a:	0001e797          	auipc	a5,0x1e
    80003e2e:	76a7a783          	lw	a5,1898(a5) # 80022594 <sb+0x4>
    80003e32:	10078163          	beqz	a5,80003f34 <balloc+0x124>
    80003e36:	8baa                	mv	s7,a0
    80003e38:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003e3a:	0001eb17          	auipc	s6,0x1e
    80003e3e:	756b0b13          	addi	s6,s6,1878 # 80022590 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e42:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003e44:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e46:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003e48:	6c89                	lui	s9,0x2
    80003e4a:	a061                	j	80003ed2 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003e4c:	974a                	add	a4,a4,s2
    80003e4e:	8fd5                	or	a5,a5,a3
    80003e50:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003e54:	854a                	mv	a0,s2
    80003e56:	00001097          	auipc	ra,0x1
    80003e5a:	0ac080e7          	jalr	172(ra) # 80004f02 <log_write>
        brelse(bp);
    80003e5e:	854a                	mv	a0,s2
    80003e60:	00000097          	auipc	ra,0x0
    80003e64:	e1e080e7          	jalr	-482(ra) # 80003c7e <brelse>
  bp = bread(dev, bno);
    80003e68:	85a6                	mv	a1,s1
    80003e6a:	855e                	mv	a0,s7
    80003e6c:	00000097          	auipc	ra,0x0
    80003e70:	ce2080e7          	jalr	-798(ra) # 80003b4e <bread>
    80003e74:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003e76:	40000613          	li	a2,1024
    80003e7a:	4581                	li	a1,0
    80003e7c:	05850513          	addi	a0,a0,88
    80003e80:	ffffd097          	auipc	ra,0xffffd
    80003e84:	e66080e7          	jalr	-410(ra) # 80000ce6 <memset>
  log_write(bp);
    80003e88:	854a                	mv	a0,s2
    80003e8a:	00001097          	auipc	ra,0x1
    80003e8e:	078080e7          	jalr	120(ra) # 80004f02 <log_write>
  brelse(bp);
    80003e92:	854a                	mv	a0,s2
    80003e94:	00000097          	auipc	ra,0x0
    80003e98:	dea080e7          	jalr	-534(ra) # 80003c7e <brelse>
}
    80003e9c:	8526                	mv	a0,s1
    80003e9e:	60e6                	ld	ra,88(sp)
    80003ea0:	6446                	ld	s0,80(sp)
    80003ea2:	64a6                	ld	s1,72(sp)
    80003ea4:	6906                	ld	s2,64(sp)
    80003ea6:	79e2                	ld	s3,56(sp)
    80003ea8:	7a42                	ld	s4,48(sp)
    80003eaa:	7aa2                	ld	s5,40(sp)
    80003eac:	7b02                	ld	s6,32(sp)
    80003eae:	6be2                	ld	s7,24(sp)
    80003eb0:	6c42                	ld	s8,16(sp)
    80003eb2:	6ca2                	ld	s9,8(sp)
    80003eb4:	6125                	addi	sp,sp,96
    80003eb6:	8082                	ret
    brelse(bp);
    80003eb8:	854a                	mv	a0,s2
    80003eba:	00000097          	auipc	ra,0x0
    80003ebe:	dc4080e7          	jalr	-572(ra) # 80003c7e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003ec2:	015c87bb          	addw	a5,s9,s5
    80003ec6:	00078a9b          	sext.w	s5,a5
    80003eca:	004b2703          	lw	a4,4(s6)
    80003ece:	06eaf363          	bgeu	s5,a4,80003f34 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003ed2:	41fad79b          	sraiw	a5,s5,0x1f
    80003ed6:	0137d79b          	srliw	a5,a5,0x13
    80003eda:	015787bb          	addw	a5,a5,s5
    80003ede:	40d7d79b          	sraiw	a5,a5,0xd
    80003ee2:	01cb2583          	lw	a1,28(s6)
    80003ee6:	9dbd                	addw	a1,a1,a5
    80003ee8:	855e                	mv	a0,s7
    80003eea:	00000097          	auipc	ra,0x0
    80003eee:	c64080e7          	jalr	-924(ra) # 80003b4e <bread>
    80003ef2:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003ef4:	004b2503          	lw	a0,4(s6)
    80003ef8:	000a849b          	sext.w	s1,s5
    80003efc:	8662                	mv	a2,s8
    80003efe:	faa4fde3          	bgeu	s1,a0,80003eb8 <balloc+0xa8>
      m = 1 << (bi % 8);
    80003f02:	41f6579b          	sraiw	a5,a2,0x1f
    80003f06:	01d7d69b          	srliw	a3,a5,0x1d
    80003f0a:	00c6873b          	addw	a4,a3,a2
    80003f0e:	00777793          	andi	a5,a4,7
    80003f12:	9f95                	subw	a5,a5,a3
    80003f14:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003f18:	4037571b          	sraiw	a4,a4,0x3
    80003f1c:	00e906b3          	add	a3,s2,a4
    80003f20:	0586c683          	lbu	a3,88(a3)
    80003f24:	00d7f5b3          	and	a1,a5,a3
    80003f28:	d195                	beqz	a1,80003e4c <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003f2a:	2605                	addiw	a2,a2,1
    80003f2c:	2485                	addiw	s1,s1,1
    80003f2e:	fd4618e3          	bne	a2,s4,80003efe <balloc+0xee>
    80003f32:	b759                	j	80003eb8 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003f34:	00005517          	auipc	a0,0x5
    80003f38:	7e450513          	addi	a0,a0,2020 # 80009718 <syscalls+0x130>
    80003f3c:	ffffc097          	auipc	ra,0xffffc
    80003f40:	652080e7          	jalr	1618(ra) # 8000058e <printf>
  return 0;
    80003f44:	4481                	li	s1,0
    80003f46:	bf99                	j	80003e9c <balloc+0x8c>

0000000080003f48 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003f48:	7179                	addi	sp,sp,-48
    80003f4a:	f406                	sd	ra,40(sp)
    80003f4c:	f022                	sd	s0,32(sp)
    80003f4e:	ec26                	sd	s1,24(sp)
    80003f50:	e84a                	sd	s2,16(sp)
    80003f52:	e44e                	sd	s3,8(sp)
    80003f54:	e052                	sd	s4,0(sp)
    80003f56:	1800                	addi	s0,sp,48
    80003f58:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003f5a:	47ad                	li	a5,11
    80003f5c:	02b7e763          	bltu	a5,a1,80003f8a <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003f60:	02059493          	slli	s1,a1,0x20
    80003f64:	9081                	srli	s1,s1,0x20
    80003f66:	048a                	slli	s1,s1,0x2
    80003f68:	94aa                	add	s1,s1,a0
    80003f6a:	0504a903          	lw	s2,80(s1)
    80003f6e:	06091e63          	bnez	s2,80003fea <bmap+0xa2>
      addr = balloc(ip->dev);
    80003f72:	4108                	lw	a0,0(a0)
    80003f74:	00000097          	auipc	ra,0x0
    80003f78:	e9c080e7          	jalr	-356(ra) # 80003e10 <balloc>
    80003f7c:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003f80:	06090563          	beqz	s2,80003fea <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003f84:	0524a823          	sw	s2,80(s1)
    80003f88:	a08d                	j	80003fea <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003f8a:	ff45849b          	addiw	s1,a1,-12
    80003f8e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003f92:	0ff00793          	li	a5,255
    80003f96:	08e7e563          	bltu	a5,a4,80004020 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003f9a:	08052903          	lw	s2,128(a0)
    80003f9e:	00091d63          	bnez	s2,80003fb8 <bmap+0x70>
      addr = balloc(ip->dev);
    80003fa2:	4108                	lw	a0,0(a0)
    80003fa4:	00000097          	auipc	ra,0x0
    80003fa8:	e6c080e7          	jalr	-404(ra) # 80003e10 <balloc>
    80003fac:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003fb0:	02090d63          	beqz	s2,80003fea <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003fb4:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003fb8:	85ca                	mv	a1,s2
    80003fba:	0009a503          	lw	a0,0(s3)
    80003fbe:	00000097          	auipc	ra,0x0
    80003fc2:	b90080e7          	jalr	-1136(ra) # 80003b4e <bread>
    80003fc6:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003fc8:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003fcc:	02049593          	slli	a1,s1,0x20
    80003fd0:	9181                	srli	a1,a1,0x20
    80003fd2:	058a                	slli	a1,a1,0x2
    80003fd4:	00b784b3          	add	s1,a5,a1
    80003fd8:	0004a903          	lw	s2,0(s1)
    80003fdc:	02090063          	beqz	s2,80003ffc <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003fe0:	8552                	mv	a0,s4
    80003fe2:	00000097          	auipc	ra,0x0
    80003fe6:	c9c080e7          	jalr	-868(ra) # 80003c7e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003fea:	854a                	mv	a0,s2
    80003fec:	70a2                	ld	ra,40(sp)
    80003fee:	7402                	ld	s0,32(sp)
    80003ff0:	64e2                	ld	s1,24(sp)
    80003ff2:	6942                	ld	s2,16(sp)
    80003ff4:	69a2                	ld	s3,8(sp)
    80003ff6:	6a02                	ld	s4,0(sp)
    80003ff8:	6145                	addi	sp,sp,48
    80003ffa:	8082                	ret
      addr = balloc(ip->dev);
    80003ffc:	0009a503          	lw	a0,0(s3)
    80004000:	00000097          	auipc	ra,0x0
    80004004:	e10080e7          	jalr	-496(ra) # 80003e10 <balloc>
    80004008:	0005091b          	sext.w	s2,a0
      if(addr){
    8000400c:	fc090ae3          	beqz	s2,80003fe0 <bmap+0x98>
        a[bn] = addr;
    80004010:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80004014:	8552                	mv	a0,s4
    80004016:	00001097          	auipc	ra,0x1
    8000401a:	eec080e7          	jalr	-276(ra) # 80004f02 <log_write>
    8000401e:	b7c9                	j	80003fe0 <bmap+0x98>
  panic("bmap: out of range");
    80004020:	00005517          	auipc	a0,0x5
    80004024:	71050513          	addi	a0,a0,1808 # 80009730 <syscalls+0x148>
    80004028:	ffffc097          	auipc	ra,0xffffc
    8000402c:	51c080e7          	jalr	1308(ra) # 80000544 <panic>

0000000080004030 <iget>:
{
    80004030:	7179                	addi	sp,sp,-48
    80004032:	f406                	sd	ra,40(sp)
    80004034:	f022                	sd	s0,32(sp)
    80004036:	ec26                	sd	s1,24(sp)
    80004038:	e84a                	sd	s2,16(sp)
    8000403a:	e44e                	sd	s3,8(sp)
    8000403c:	e052                	sd	s4,0(sp)
    8000403e:	1800                	addi	s0,sp,48
    80004040:	89aa                	mv	s3,a0
    80004042:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80004044:	0001e517          	auipc	a0,0x1e
    80004048:	56c50513          	addi	a0,a0,1388 # 800225b0 <itable>
    8000404c:	ffffd097          	auipc	ra,0xffffd
    80004050:	b9e080e7          	jalr	-1122(ra) # 80000bea <acquire>
  empty = 0;
    80004054:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80004056:	0001e497          	auipc	s1,0x1e
    8000405a:	57248493          	addi	s1,s1,1394 # 800225c8 <itable+0x18>
    8000405e:	00020697          	auipc	a3,0x20
    80004062:	ffa68693          	addi	a3,a3,-6 # 80024058 <log>
    80004066:	a039                	j	80004074 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80004068:	02090b63          	beqz	s2,8000409e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000406c:	08848493          	addi	s1,s1,136
    80004070:	02d48a63          	beq	s1,a3,800040a4 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80004074:	449c                	lw	a5,8(s1)
    80004076:	fef059e3          	blez	a5,80004068 <iget+0x38>
    8000407a:	4098                	lw	a4,0(s1)
    8000407c:	ff3716e3          	bne	a4,s3,80004068 <iget+0x38>
    80004080:	40d8                	lw	a4,4(s1)
    80004082:	ff4713e3          	bne	a4,s4,80004068 <iget+0x38>
      ip->ref++;
    80004086:	2785                	addiw	a5,a5,1
    80004088:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000408a:	0001e517          	auipc	a0,0x1e
    8000408e:	52650513          	addi	a0,a0,1318 # 800225b0 <itable>
    80004092:	ffffd097          	auipc	ra,0xffffd
    80004096:	c0c080e7          	jalr	-1012(ra) # 80000c9e <release>
      return ip;
    8000409a:	8926                	mv	s2,s1
    8000409c:	a03d                	j	800040ca <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000409e:	f7f9                	bnez	a5,8000406c <iget+0x3c>
    800040a0:	8926                	mv	s2,s1
    800040a2:	b7e9                	j	8000406c <iget+0x3c>
  if(empty == 0)
    800040a4:	02090c63          	beqz	s2,800040dc <iget+0xac>
  ip->dev = dev;
    800040a8:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800040ac:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800040b0:	4785                	li	a5,1
    800040b2:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800040b6:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800040ba:	0001e517          	auipc	a0,0x1e
    800040be:	4f650513          	addi	a0,a0,1270 # 800225b0 <itable>
    800040c2:	ffffd097          	auipc	ra,0xffffd
    800040c6:	bdc080e7          	jalr	-1060(ra) # 80000c9e <release>
}
    800040ca:	854a                	mv	a0,s2
    800040cc:	70a2                	ld	ra,40(sp)
    800040ce:	7402                	ld	s0,32(sp)
    800040d0:	64e2                	ld	s1,24(sp)
    800040d2:	6942                	ld	s2,16(sp)
    800040d4:	69a2                	ld	s3,8(sp)
    800040d6:	6a02                	ld	s4,0(sp)
    800040d8:	6145                	addi	sp,sp,48
    800040da:	8082                	ret
    panic("iget: no inodes");
    800040dc:	00005517          	auipc	a0,0x5
    800040e0:	66c50513          	addi	a0,a0,1644 # 80009748 <syscalls+0x160>
    800040e4:	ffffc097          	auipc	ra,0xffffc
    800040e8:	460080e7          	jalr	1120(ra) # 80000544 <panic>

00000000800040ec <fsinit>:
fsinit(int dev) {
    800040ec:	7179                	addi	sp,sp,-48
    800040ee:	f406                	sd	ra,40(sp)
    800040f0:	f022                	sd	s0,32(sp)
    800040f2:	ec26                	sd	s1,24(sp)
    800040f4:	e84a                	sd	s2,16(sp)
    800040f6:	e44e                	sd	s3,8(sp)
    800040f8:	1800                	addi	s0,sp,48
    800040fa:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800040fc:	4585                	li	a1,1
    800040fe:	00000097          	auipc	ra,0x0
    80004102:	a50080e7          	jalr	-1456(ra) # 80003b4e <bread>
    80004106:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80004108:	0001e997          	auipc	s3,0x1e
    8000410c:	48898993          	addi	s3,s3,1160 # 80022590 <sb>
    80004110:	02000613          	li	a2,32
    80004114:	05850593          	addi	a1,a0,88
    80004118:	854e                	mv	a0,s3
    8000411a:	ffffd097          	auipc	ra,0xffffd
    8000411e:	c2c080e7          	jalr	-980(ra) # 80000d46 <memmove>
  brelse(bp);
    80004122:	8526                	mv	a0,s1
    80004124:	00000097          	auipc	ra,0x0
    80004128:	b5a080e7          	jalr	-1190(ra) # 80003c7e <brelse>
  if(sb.magic != FSMAGIC)
    8000412c:	0009a703          	lw	a4,0(s3)
    80004130:	102037b7          	lui	a5,0x10203
    80004134:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80004138:	02f71263          	bne	a4,a5,8000415c <fsinit+0x70>
  initlog(dev, &sb);
    8000413c:	0001e597          	auipc	a1,0x1e
    80004140:	45458593          	addi	a1,a1,1108 # 80022590 <sb>
    80004144:	854a                	mv	a0,s2
    80004146:	00001097          	auipc	ra,0x1
    8000414a:	b40080e7          	jalr	-1216(ra) # 80004c86 <initlog>
}
    8000414e:	70a2                	ld	ra,40(sp)
    80004150:	7402                	ld	s0,32(sp)
    80004152:	64e2                	ld	s1,24(sp)
    80004154:	6942                	ld	s2,16(sp)
    80004156:	69a2                	ld	s3,8(sp)
    80004158:	6145                	addi	sp,sp,48
    8000415a:	8082                	ret
    panic("invalid file system");
    8000415c:	00005517          	auipc	a0,0x5
    80004160:	5fc50513          	addi	a0,a0,1532 # 80009758 <syscalls+0x170>
    80004164:	ffffc097          	auipc	ra,0xffffc
    80004168:	3e0080e7          	jalr	992(ra) # 80000544 <panic>

000000008000416c <iinit>:
{
    8000416c:	7179                	addi	sp,sp,-48
    8000416e:	f406                	sd	ra,40(sp)
    80004170:	f022                	sd	s0,32(sp)
    80004172:	ec26                	sd	s1,24(sp)
    80004174:	e84a                	sd	s2,16(sp)
    80004176:	e44e                	sd	s3,8(sp)
    80004178:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000417a:	00005597          	auipc	a1,0x5
    8000417e:	5f658593          	addi	a1,a1,1526 # 80009770 <syscalls+0x188>
    80004182:	0001e517          	auipc	a0,0x1e
    80004186:	42e50513          	addi	a0,a0,1070 # 800225b0 <itable>
    8000418a:	ffffd097          	auipc	ra,0xffffd
    8000418e:	9d0080e7          	jalr	-1584(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    80004192:	0001e497          	auipc	s1,0x1e
    80004196:	44648493          	addi	s1,s1,1094 # 800225d8 <itable+0x28>
    8000419a:	00020997          	auipc	s3,0x20
    8000419e:	ece98993          	addi	s3,s3,-306 # 80024068 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800041a2:	00005917          	auipc	s2,0x5
    800041a6:	5d690913          	addi	s2,s2,1494 # 80009778 <syscalls+0x190>
    800041aa:	85ca                	mv	a1,s2
    800041ac:	8526                	mv	a0,s1
    800041ae:	00001097          	auipc	ra,0x1
    800041b2:	e3a080e7          	jalr	-454(ra) # 80004fe8 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800041b6:	08848493          	addi	s1,s1,136
    800041ba:	ff3498e3          	bne	s1,s3,800041aa <iinit+0x3e>
}
    800041be:	70a2                	ld	ra,40(sp)
    800041c0:	7402                	ld	s0,32(sp)
    800041c2:	64e2                	ld	s1,24(sp)
    800041c4:	6942                	ld	s2,16(sp)
    800041c6:	69a2                	ld	s3,8(sp)
    800041c8:	6145                	addi	sp,sp,48
    800041ca:	8082                	ret

00000000800041cc <ialloc>:
{
    800041cc:	715d                	addi	sp,sp,-80
    800041ce:	e486                	sd	ra,72(sp)
    800041d0:	e0a2                	sd	s0,64(sp)
    800041d2:	fc26                	sd	s1,56(sp)
    800041d4:	f84a                	sd	s2,48(sp)
    800041d6:	f44e                	sd	s3,40(sp)
    800041d8:	f052                	sd	s4,32(sp)
    800041da:	ec56                	sd	s5,24(sp)
    800041dc:	e85a                	sd	s6,16(sp)
    800041de:	e45e                	sd	s7,8(sp)
    800041e0:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800041e2:	0001e717          	auipc	a4,0x1e
    800041e6:	3ba72703          	lw	a4,954(a4) # 8002259c <sb+0xc>
    800041ea:	4785                	li	a5,1
    800041ec:	04e7fa63          	bgeu	a5,a4,80004240 <ialloc+0x74>
    800041f0:	8aaa                	mv	s5,a0
    800041f2:	8bae                	mv	s7,a1
    800041f4:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800041f6:	0001ea17          	auipc	s4,0x1e
    800041fa:	39aa0a13          	addi	s4,s4,922 # 80022590 <sb>
    800041fe:	00048b1b          	sext.w	s6,s1
    80004202:	0044d593          	srli	a1,s1,0x4
    80004206:	018a2783          	lw	a5,24(s4)
    8000420a:	9dbd                	addw	a1,a1,a5
    8000420c:	8556                	mv	a0,s5
    8000420e:	00000097          	auipc	ra,0x0
    80004212:	940080e7          	jalr	-1728(ra) # 80003b4e <bread>
    80004216:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80004218:	05850993          	addi	s3,a0,88
    8000421c:	00f4f793          	andi	a5,s1,15
    80004220:	079a                	slli	a5,a5,0x6
    80004222:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80004224:	00099783          	lh	a5,0(s3)
    80004228:	c3a1                	beqz	a5,80004268 <ialloc+0x9c>
    brelse(bp);
    8000422a:	00000097          	auipc	ra,0x0
    8000422e:	a54080e7          	jalr	-1452(ra) # 80003c7e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80004232:	0485                	addi	s1,s1,1
    80004234:	00ca2703          	lw	a4,12(s4)
    80004238:	0004879b          	sext.w	a5,s1
    8000423c:	fce7e1e3          	bltu	a5,a4,800041fe <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80004240:	00005517          	auipc	a0,0x5
    80004244:	54050513          	addi	a0,a0,1344 # 80009780 <syscalls+0x198>
    80004248:	ffffc097          	auipc	ra,0xffffc
    8000424c:	346080e7          	jalr	838(ra) # 8000058e <printf>
  return 0;
    80004250:	4501                	li	a0,0
}
    80004252:	60a6                	ld	ra,72(sp)
    80004254:	6406                	ld	s0,64(sp)
    80004256:	74e2                	ld	s1,56(sp)
    80004258:	7942                	ld	s2,48(sp)
    8000425a:	79a2                	ld	s3,40(sp)
    8000425c:	7a02                	ld	s4,32(sp)
    8000425e:	6ae2                	ld	s5,24(sp)
    80004260:	6b42                	ld	s6,16(sp)
    80004262:	6ba2                	ld	s7,8(sp)
    80004264:	6161                	addi	sp,sp,80
    80004266:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80004268:	04000613          	li	a2,64
    8000426c:	4581                	li	a1,0
    8000426e:	854e                	mv	a0,s3
    80004270:	ffffd097          	auipc	ra,0xffffd
    80004274:	a76080e7          	jalr	-1418(ra) # 80000ce6 <memset>
      dip->type = type;
    80004278:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000427c:	854a                	mv	a0,s2
    8000427e:	00001097          	auipc	ra,0x1
    80004282:	c84080e7          	jalr	-892(ra) # 80004f02 <log_write>
      brelse(bp);
    80004286:	854a                	mv	a0,s2
    80004288:	00000097          	auipc	ra,0x0
    8000428c:	9f6080e7          	jalr	-1546(ra) # 80003c7e <brelse>
      return iget(dev, inum);
    80004290:	85da                	mv	a1,s6
    80004292:	8556                	mv	a0,s5
    80004294:	00000097          	auipc	ra,0x0
    80004298:	d9c080e7          	jalr	-612(ra) # 80004030 <iget>
    8000429c:	bf5d                	j	80004252 <ialloc+0x86>

000000008000429e <iupdate>:
{
    8000429e:	1101                	addi	sp,sp,-32
    800042a0:	ec06                	sd	ra,24(sp)
    800042a2:	e822                	sd	s0,16(sp)
    800042a4:	e426                	sd	s1,8(sp)
    800042a6:	e04a                	sd	s2,0(sp)
    800042a8:	1000                	addi	s0,sp,32
    800042aa:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800042ac:	415c                	lw	a5,4(a0)
    800042ae:	0047d79b          	srliw	a5,a5,0x4
    800042b2:	0001e597          	auipc	a1,0x1e
    800042b6:	2f65a583          	lw	a1,758(a1) # 800225a8 <sb+0x18>
    800042ba:	9dbd                	addw	a1,a1,a5
    800042bc:	4108                	lw	a0,0(a0)
    800042be:	00000097          	auipc	ra,0x0
    800042c2:	890080e7          	jalr	-1904(ra) # 80003b4e <bread>
    800042c6:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800042c8:	05850793          	addi	a5,a0,88
    800042cc:	40c8                	lw	a0,4(s1)
    800042ce:	893d                	andi	a0,a0,15
    800042d0:	051a                	slli	a0,a0,0x6
    800042d2:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800042d4:	04449703          	lh	a4,68(s1)
    800042d8:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800042dc:	04649703          	lh	a4,70(s1)
    800042e0:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800042e4:	04849703          	lh	a4,72(s1)
    800042e8:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800042ec:	04a49703          	lh	a4,74(s1)
    800042f0:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800042f4:	44f8                	lw	a4,76(s1)
    800042f6:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800042f8:	03400613          	li	a2,52
    800042fc:	05048593          	addi	a1,s1,80
    80004300:	0531                	addi	a0,a0,12
    80004302:	ffffd097          	auipc	ra,0xffffd
    80004306:	a44080e7          	jalr	-1468(ra) # 80000d46 <memmove>
  log_write(bp);
    8000430a:	854a                	mv	a0,s2
    8000430c:	00001097          	auipc	ra,0x1
    80004310:	bf6080e7          	jalr	-1034(ra) # 80004f02 <log_write>
  brelse(bp);
    80004314:	854a                	mv	a0,s2
    80004316:	00000097          	auipc	ra,0x0
    8000431a:	968080e7          	jalr	-1688(ra) # 80003c7e <brelse>
}
    8000431e:	60e2                	ld	ra,24(sp)
    80004320:	6442                	ld	s0,16(sp)
    80004322:	64a2                	ld	s1,8(sp)
    80004324:	6902                	ld	s2,0(sp)
    80004326:	6105                	addi	sp,sp,32
    80004328:	8082                	ret

000000008000432a <idup>:
{
    8000432a:	1101                	addi	sp,sp,-32
    8000432c:	ec06                	sd	ra,24(sp)
    8000432e:	e822                	sd	s0,16(sp)
    80004330:	e426                	sd	s1,8(sp)
    80004332:	1000                	addi	s0,sp,32
    80004334:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004336:	0001e517          	auipc	a0,0x1e
    8000433a:	27a50513          	addi	a0,a0,634 # 800225b0 <itable>
    8000433e:	ffffd097          	auipc	ra,0xffffd
    80004342:	8ac080e7          	jalr	-1876(ra) # 80000bea <acquire>
  ip->ref++;
    80004346:	449c                	lw	a5,8(s1)
    80004348:	2785                	addiw	a5,a5,1
    8000434a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000434c:	0001e517          	auipc	a0,0x1e
    80004350:	26450513          	addi	a0,a0,612 # 800225b0 <itable>
    80004354:	ffffd097          	auipc	ra,0xffffd
    80004358:	94a080e7          	jalr	-1718(ra) # 80000c9e <release>
}
    8000435c:	8526                	mv	a0,s1
    8000435e:	60e2                	ld	ra,24(sp)
    80004360:	6442                	ld	s0,16(sp)
    80004362:	64a2                	ld	s1,8(sp)
    80004364:	6105                	addi	sp,sp,32
    80004366:	8082                	ret

0000000080004368 <ilock>:
{
    80004368:	1101                	addi	sp,sp,-32
    8000436a:	ec06                	sd	ra,24(sp)
    8000436c:	e822                	sd	s0,16(sp)
    8000436e:	e426                	sd	s1,8(sp)
    80004370:	e04a                	sd	s2,0(sp)
    80004372:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80004374:	c115                	beqz	a0,80004398 <ilock+0x30>
    80004376:	84aa                	mv	s1,a0
    80004378:	451c                	lw	a5,8(a0)
    8000437a:	00f05f63          	blez	a5,80004398 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000437e:	0541                	addi	a0,a0,16
    80004380:	00001097          	auipc	ra,0x1
    80004384:	ca2080e7          	jalr	-862(ra) # 80005022 <acquiresleep>
  if(ip->valid == 0){
    80004388:	40bc                	lw	a5,64(s1)
    8000438a:	cf99                	beqz	a5,800043a8 <ilock+0x40>
}
    8000438c:	60e2                	ld	ra,24(sp)
    8000438e:	6442                	ld	s0,16(sp)
    80004390:	64a2                	ld	s1,8(sp)
    80004392:	6902                	ld	s2,0(sp)
    80004394:	6105                	addi	sp,sp,32
    80004396:	8082                	ret
    panic("ilock");
    80004398:	00005517          	auipc	a0,0x5
    8000439c:	40050513          	addi	a0,a0,1024 # 80009798 <syscalls+0x1b0>
    800043a0:	ffffc097          	auipc	ra,0xffffc
    800043a4:	1a4080e7          	jalr	420(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800043a8:	40dc                	lw	a5,4(s1)
    800043aa:	0047d79b          	srliw	a5,a5,0x4
    800043ae:	0001e597          	auipc	a1,0x1e
    800043b2:	1fa5a583          	lw	a1,506(a1) # 800225a8 <sb+0x18>
    800043b6:	9dbd                	addw	a1,a1,a5
    800043b8:	4088                	lw	a0,0(s1)
    800043ba:	fffff097          	auipc	ra,0xfffff
    800043be:	794080e7          	jalr	1940(ra) # 80003b4e <bread>
    800043c2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800043c4:	05850593          	addi	a1,a0,88
    800043c8:	40dc                	lw	a5,4(s1)
    800043ca:	8bbd                	andi	a5,a5,15
    800043cc:	079a                	slli	a5,a5,0x6
    800043ce:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800043d0:	00059783          	lh	a5,0(a1)
    800043d4:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800043d8:	00259783          	lh	a5,2(a1)
    800043dc:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800043e0:	00459783          	lh	a5,4(a1)
    800043e4:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800043e8:	00659783          	lh	a5,6(a1)
    800043ec:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800043f0:	459c                	lw	a5,8(a1)
    800043f2:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800043f4:	03400613          	li	a2,52
    800043f8:	05b1                	addi	a1,a1,12
    800043fa:	05048513          	addi	a0,s1,80
    800043fe:	ffffd097          	auipc	ra,0xffffd
    80004402:	948080e7          	jalr	-1720(ra) # 80000d46 <memmove>
    brelse(bp);
    80004406:	854a                	mv	a0,s2
    80004408:	00000097          	auipc	ra,0x0
    8000440c:	876080e7          	jalr	-1930(ra) # 80003c7e <brelse>
    ip->valid = 1;
    80004410:	4785                	li	a5,1
    80004412:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004414:	04449783          	lh	a5,68(s1)
    80004418:	fbb5                	bnez	a5,8000438c <ilock+0x24>
      panic("ilock: no type");
    8000441a:	00005517          	auipc	a0,0x5
    8000441e:	38650513          	addi	a0,a0,902 # 800097a0 <syscalls+0x1b8>
    80004422:	ffffc097          	auipc	ra,0xffffc
    80004426:	122080e7          	jalr	290(ra) # 80000544 <panic>

000000008000442a <iunlock>:
{
    8000442a:	1101                	addi	sp,sp,-32
    8000442c:	ec06                	sd	ra,24(sp)
    8000442e:	e822                	sd	s0,16(sp)
    80004430:	e426                	sd	s1,8(sp)
    80004432:	e04a                	sd	s2,0(sp)
    80004434:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004436:	c905                	beqz	a0,80004466 <iunlock+0x3c>
    80004438:	84aa                	mv	s1,a0
    8000443a:	01050913          	addi	s2,a0,16
    8000443e:	854a                	mv	a0,s2
    80004440:	00001097          	auipc	ra,0x1
    80004444:	c7c080e7          	jalr	-900(ra) # 800050bc <holdingsleep>
    80004448:	cd19                	beqz	a0,80004466 <iunlock+0x3c>
    8000444a:	449c                	lw	a5,8(s1)
    8000444c:	00f05d63          	blez	a5,80004466 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004450:	854a                	mv	a0,s2
    80004452:	00001097          	auipc	ra,0x1
    80004456:	c26080e7          	jalr	-986(ra) # 80005078 <releasesleep>
}
    8000445a:	60e2                	ld	ra,24(sp)
    8000445c:	6442                	ld	s0,16(sp)
    8000445e:	64a2                	ld	s1,8(sp)
    80004460:	6902                	ld	s2,0(sp)
    80004462:	6105                	addi	sp,sp,32
    80004464:	8082                	ret
    panic("iunlock");
    80004466:	00005517          	auipc	a0,0x5
    8000446a:	34a50513          	addi	a0,a0,842 # 800097b0 <syscalls+0x1c8>
    8000446e:	ffffc097          	auipc	ra,0xffffc
    80004472:	0d6080e7          	jalr	214(ra) # 80000544 <panic>

0000000080004476 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004476:	7179                	addi	sp,sp,-48
    80004478:	f406                	sd	ra,40(sp)
    8000447a:	f022                	sd	s0,32(sp)
    8000447c:	ec26                	sd	s1,24(sp)
    8000447e:	e84a                	sd	s2,16(sp)
    80004480:	e44e                	sd	s3,8(sp)
    80004482:	e052                	sd	s4,0(sp)
    80004484:	1800                	addi	s0,sp,48
    80004486:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004488:	05050493          	addi	s1,a0,80
    8000448c:	08050913          	addi	s2,a0,128
    80004490:	a021                	j	80004498 <itrunc+0x22>
    80004492:	0491                	addi	s1,s1,4
    80004494:	01248d63          	beq	s1,s2,800044ae <itrunc+0x38>
    if(ip->addrs[i]){
    80004498:	408c                	lw	a1,0(s1)
    8000449a:	dde5                	beqz	a1,80004492 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000449c:	0009a503          	lw	a0,0(s3)
    800044a0:	00000097          	auipc	ra,0x0
    800044a4:	8f4080e7          	jalr	-1804(ra) # 80003d94 <bfree>
      ip->addrs[i] = 0;
    800044a8:	0004a023          	sw	zero,0(s1)
    800044ac:	b7dd                	j	80004492 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800044ae:	0809a583          	lw	a1,128(s3)
    800044b2:	e185                	bnez	a1,800044d2 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800044b4:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800044b8:	854e                	mv	a0,s3
    800044ba:	00000097          	auipc	ra,0x0
    800044be:	de4080e7          	jalr	-540(ra) # 8000429e <iupdate>
}
    800044c2:	70a2                	ld	ra,40(sp)
    800044c4:	7402                	ld	s0,32(sp)
    800044c6:	64e2                	ld	s1,24(sp)
    800044c8:	6942                	ld	s2,16(sp)
    800044ca:	69a2                	ld	s3,8(sp)
    800044cc:	6a02                	ld	s4,0(sp)
    800044ce:	6145                	addi	sp,sp,48
    800044d0:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800044d2:	0009a503          	lw	a0,0(s3)
    800044d6:	fffff097          	auipc	ra,0xfffff
    800044da:	678080e7          	jalr	1656(ra) # 80003b4e <bread>
    800044de:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800044e0:	05850493          	addi	s1,a0,88
    800044e4:	45850913          	addi	s2,a0,1112
    800044e8:	a811                	j	800044fc <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800044ea:	0009a503          	lw	a0,0(s3)
    800044ee:	00000097          	auipc	ra,0x0
    800044f2:	8a6080e7          	jalr	-1882(ra) # 80003d94 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800044f6:	0491                	addi	s1,s1,4
    800044f8:	01248563          	beq	s1,s2,80004502 <itrunc+0x8c>
      if(a[j])
    800044fc:	408c                	lw	a1,0(s1)
    800044fe:	dde5                	beqz	a1,800044f6 <itrunc+0x80>
    80004500:	b7ed                	j	800044ea <itrunc+0x74>
    brelse(bp);
    80004502:	8552                	mv	a0,s4
    80004504:	fffff097          	auipc	ra,0xfffff
    80004508:	77a080e7          	jalr	1914(ra) # 80003c7e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000450c:	0809a583          	lw	a1,128(s3)
    80004510:	0009a503          	lw	a0,0(s3)
    80004514:	00000097          	auipc	ra,0x0
    80004518:	880080e7          	jalr	-1920(ra) # 80003d94 <bfree>
    ip->addrs[NDIRECT] = 0;
    8000451c:	0809a023          	sw	zero,128(s3)
    80004520:	bf51                	j	800044b4 <itrunc+0x3e>

0000000080004522 <iput>:
{
    80004522:	1101                	addi	sp,sp,-32
    80004524:	ec06                	sd	ra,24(sp)
    80004526:	e822                	sd	s0,16(sp)
    80004528:	e426                	sd	s1,8(sp)
    8000452a:	e04a                	sd	s2,0(sp)
    8000452c:	1000                	addi	s0,sp,32
    8000452e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004530:	0001e517          	auipc	a0,0x1e
    80004534:	08050513          	addi	a0,a0,128 # 800225b0 <itable>
    80004538:	ffffc097          	auipc	ra,0xffffc
    8000453c:	6b2080e7          	jalr	1714(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004540:	4498                	lw	a4,8(s1)
    80004542:	4785                	li	a5,1
    80004544:	02f70363          	beq	a4,a5,8000456a <iput+0x48>
  ip->ref--;
    80004548:	449c                	lw	a5,8(s1)
    8000454a:	37fd                	addiw	a5,a5,-1
    8000454c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000454e:	0001e517          	auipc	a0,0x1e
    80004552:	06250513          	addi	a0,a0,98 # 800225b0 <itable>
    80004556:	ffffc097          	auipc	ra,0xffffc
    8000455a:	748080e7          	jalr	1864(ra) # 80000c9e <release>
}
    8000455e:	60e2                	ld	ra,24(sp)
    80004560:	6442                	ld	s0,16(sp)
    80004562:	64a2                	ld	s1,8(sp)
    80004564:	6902                	ld	s2,0(sp)
    80004566:	6105                	addi	sp,sp,32
    80004568:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000456a:	40bc                	lw	a5,64(s1)
    8000456c:	dff1                	beqz	a5,80004548 <iput+0x26>
    8000456e:	04a49783          	lh	a5,74(s1)
    80004572:	fbf9                	bnez	a5,80004548 <iput+0x26>
    acquiresleep(&ip->lock);
    80004574:	01048913          	addi	s2,s1,16
    80004578:	854a                	mv	a0,s2
    8000457a:	00001097          	auipc	ra,0x1
    8000457e:	aa8080e7          	jalr	-1368(ra) # 80005022 <acquiresleep>
    release(&itable.lock);
    80004582:	0001e517          	auipc	a0,0x1e
    80004586:	02e50513          	addi	a0,a0,46 # 800225b0 <itable>
    8000458a:	ffffc097          	auipc	ra,0xffffc
    8000458e:	714080e7          	jalr	1812(ra) # 80000c9e <release>
    itrunc(ip);
    80004592:	8526                	mv	a0,s1
    80004594:	00000097          	auipc	ra,0x0
    80004598:	ee2080e7          	jalr	-286(ra) # 80004476 <itrunc>
    ip->type = 0;
    8000459c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800045a0:	8526                	mv	a0,s1
    800045a2:	00000097          	auipc	ra,0x0
    800045a6:	cfc080e7          	jalr	-772(ra) # 8000429e <iupdate>
    ip->valid = 0;
    800045aa:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800045ae:	854a                	mv	a0,s2
    800045b0:	00001097          	auipc	ra,0x1
    800045b4:	ac8080e7          	jalr	-1336(ra) # 80005078 <releasesleep>
    acquire(&itable.lock);
    800045b8:	0001e517          	auipc	a0,0x1e
    800045bc:	ff850513          	addi	a0,a0,-8 # 800225b0 <itable>
    800045c0:	ffffc097          	auipc	ra,0xffffc
    800045c4:	62a080e7          	jalr	1578(ra) # 80000bea <acquire>
    800045c8:	b741                	j	80004548 <iput+0x26>

00000000800045ca <iunlockput>:
{
    800045ca:	1101                	addi	sp,sp,-32
    800045cc:	ec06                	sd	ra,24(sp)
    800045ce:	e822                	sd	s0,16(sp)
    800045d0:	e426                	sd	s1,8(sp)
    800045d2:	1000                	addi	s0,sp,32
    800045d4:	84aa                	mv	s1,a0
  iunlock(ip);
    800045d6:	00000097          	auipc	ra,0x0
    800045da:	e54080e7          	jalr	-428(ra) # 8000442a <iunlock>
  iput(ip);
    800045de:	8526                	mv	a0,s1
    800045e0:	00000097          	auipc	ra,0x0
    800045e4:	f42080e7          	jalr	-190(ra) # 80004522 <iput>
}
    800045e8:	60e2                	ld	ra,24(sp)
    800045ea:	6442                	ld	s0,16(sp)
    800045ec:	64a2                	ld	s1,8(sp)
    800045ee:	6105                	addi	sp,sp,32
    800045f0:	8082                	ret

00000000800045f2 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800045f2:	1141                	addi	sp,sp,-16
    800045f4:	e422                	sd	s0,8(sp)
    800045f6:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800045f8:	411c                	lw	a5,0(a0)
    800045fa:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800045fc:	415c                	lw	a5,4(a0)
    800045fe:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004600:	04451783          	lh	a5,68(a0)
    80004604:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004608:	04a51783          	lh	a5,74(a0)
    8000460c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004610:	04c56783          	lwu	a5,76(a0)
    80004614:	e99c                	sd	a5,16(a1)
}
    80004616:	6422                	ld	s0,8(sp)
    80004618:	0141                	addi	sp,sp,16
    8000461a:	8082                	ret

000000008000461c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000461c:	457c                	lw	a5,76(a0)
    8000461e:	0ed7e963          	bltu	a5,a3,80004710 <readi+0xf4>
{
    80004622:	7159                	addi	sp,sp,-112
    80004624:	f486                	sd	ra,104(sp)
    80004626:	f0a2                	sd	s0,96(sp)
    80004628:	eca6                	sd	s1,88(sp)
    8000462a:	e8ca                	sd	s2,80(sp)
    8000462c:	e4ce                	sd	s3,72(sp)
    8000462e:	e0d2                	sd	s4,64(sp)
    80004630:	fc56                	sd	s5,56(sp)
    80004632:	f85a                	sd	s6,48(sp)
    80004634:	f45e                	sd	s7,40(sp)
    80004636:	f062                	sd	s8,32(sp)
    80004638:	ec66                	sd	s9,24(sp)
    8000463a:	e86a                	sd	s10,16(sp)
    8000463c:	e46e                	sd	s11,8(sp)
    8000463e:	1880                	addi	s0,sp,112
    80004640:	8b2a                	mv	s6,a0
    80004642:	8bae                	mv	s7,a1
    80004644:	8a32                	mv	s4,a2
    80004646:	84b6                	mv	s1,a3
    80004648:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    8000464a:	9f35                	addw	a4,a4,a3
    return 0;
    8000464c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000464e:	0ad76063          	bltu	a4,a3,800046ee <readi+0xd2>
  if(off + n > ip->size)
    80004652:	00e7f463          	bgeu	a5,a4,8000465a <readi+0x3e>
    n = ip->size - off;
    80004656:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000465a:	0a0a8963          	beqz	s5,8000470c <readi+0xf0>
    8000465e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004660:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004664:	5c7d                	li	s8,-1
    80004666:	a82d                	j	800046a0 <readi+0x84>
    80004668:	020d1d93          	slli	s11,s10,0x20
    8000466c:	020ddd93          	srli	s11,s11,0x20
    80004670:	05890613          	addi	a2,s2,88
    80004674:	86ee                	mv	a3,s11
    80004676:	963a                	add	a2,a2,a4
    80004678:	85d2                	mv	a1,s4
    8000467a:	855e                	mv	a0,s7
    8000467c:	ffffe097          	auipc	ra,0xffffe
    80004680:	33a080e7          	jalr	826(ra) # 800029b6 <either_copyout>
    80004684:	05850d63          	beq	a0,s8,800046de <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004688:	854a                	mv	a0,s2
    8000468a:	fffff097          	auipc	ra,0xfffff
    8000468e:	5f4080e7          	jalr	1524(ra) # 80003c7e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004692:	013d09bb          	addw	s3,s10,s3
    80004696:	009d04bb          	addw	s1,s10,s1
    8000469a:	9a6e                	add	s4,s4,s11
    8000469c:	0559f763          	bgeu	s3,s5,800046ea <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    800046a0:	00a4d59b          	srliw	a1,s1,0xa
    800046a4:	855a                	mv	a0,s6
    800046a6:	00000097          	auipc	ra,0x0
    800046aa:	8a2080e7          	jalr	-1886(ra) # 80003f48 <bmap>
    800046ae:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800046b2:	cd85                	beqz	a1,800046ea <readi+0xce>
    bp = bread(ip->dev, addr);
    800046b4:	000b2503          	lw	a0,0(s6)
    800046b8:	fffff097          	auipc	ra,0xfffff
    800046bc:	496080e7          	jalr	1174(ra) # 80003b4e <bread>
    800046c0:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800046c2:	3ff4f713          	andi	a4,s1,1023
    800046c6:	40ec87bb          	subw	a5,s9,a4
    800046ca:	413a86bb          	subw	a3,s5,s3
    800046ce:	8d3e                	mv	s10,a5
    800046d0:	2781                	sext.w	a5,a5
    800046d2:	0006861b          	sext.w	a2,a3
    800046d6:	f8f679e3          	bgeu	a2,a5,80004668 <readi+0x4c>
    800046da:	8d36                	mv	s10,a3
    800046dc:	b771                	j	80004668 <readi+0x4c>
      brelse(bp);
    800046de:	854a                	mv	a0,s2
    800046e0:	fffff097          	auipc	ra,0xfffff
    800046e4:	59e080e7          	jalr	1438(ra) # 80003c7e <brelse>
      tot = -1;
    800046e8:	59fd                	li	s3,-1
  }
  return tot;
    800046ea:	0009851b          	sext.w	a0,s3
}
    800046ee:	70a6                	ld	ra,104(sp)
    800046f0:	7406                	ld	s0,96(sp)
    800046f2:	64e6                	ld	s1,88(sp)
    800046f4:	6946                	ld	s2,80(sp)
    800046f6:	69a6                	ld	s3,72(sp)
    800046f8:	6a06                	ld	s4,64(sp)
    800046fa:	7ae2                	ld	s5,56(sp)
    800046fc:	7b42                	ld	s6,48(sp)
    800046fe:	7ba2                	ld	s7,40(sp)
    80004700:	7c02                	ld	s8,32(sp)
    80004702:	6ce2                	ld	s9,24(sp)
    80004704:	6d42                	ld	s10,16(sp)
    80004706:	6da2                	ld	s11,8(sp)
    80004708:	6165                	addi	sp,sp,112
    8000470a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000470c:	89d6                	mv	s3,s5
    8000470e:	bff1                	j	800046ea <readi+0xce>
    return 0;
    80004710:	4501                	li	a0,0
}
    80004712:	8082                	ret

0000000080004714 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004714:	457c                	lw	a5,76(a0)
    80004716:	10d7e863          	bltu	a5,a3,80004826 <writei+0x112>
{
    8000471a:	7159                	addi	sp,sp,-112
    8000471c:	f486                	sd	ra,104(sp)
    8000471e:	f0a2                	sd	s0,96(sp)
    80004720:	eca6                	sd	s1,88(sp)
    80004722:	e8ca                	sd	s2,80(sp)
    80004724:	e4ce                	sd	s3,72(sp)
    80004726:	e0d2                	sd	s4,64(sp)
    80004728:	fc56                	sd	s5,56(sp)
    8000472a:	f85a                	sd	s6,48(sp)
    8000472c:	f45e                	sd	s7,40(sp)
    8000472e:	f062                	sd	s8,32(sp)
    80004730:	ec66                	sd	s9,24(sp)
    80004732:	e86a                	sd	s10,16(sp)
    80004734:	e46e                	sd	s11,8(sp)
    80004736:	1880                	addi	s0,sp,112
    80004738:	8aaa                	mv	s5,a0
    8000473a:	8bae                	mv	s7,a1
    8000473c:	8a32                	mv	s4,a2
    8000473e:	8936                	mv	s2,a3
    80004740:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004742:	00e687bb          	addw	a5,a3,a4
    80004746:	0ed7e263          	bltu	a5,a3,8000482a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000474a:	00043737          	lui	a4,0x43
    8000474e:	0ef76063          	bltu	a4,a5,8000482e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004752:	0c0b0863          	beqz	s6,80004822 <writei+0x10e>
    80004756:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004758:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000475c:	5c7d                	li	s8,-1
    8000475e:	a091                	j	800047a2 <writei+0x8e>
    80004760:	020d1d93          	slli	s11,s10,0x20
    80004764:	020ddd93          	srli	s11,s11,0x20
    80004768:	05848513          	addi	a0,s1,88
    8000476c:	86ee                	mv	a3,s11
    8000476e:	8652                	mv	a2,s4
    80004770:	85de                	mv	a1,s7
    80004772:	953a                	add	a0,a0,a4
    80004774:	ffffe097          	auipc	ra,0xffffe
    80004778:	298080e7          	jalr	664(ra) # 80002a0c <either_copyin>
    8000477c:	07850263          	beq	a0,s8,800047e0 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004780:	8526                	mv	a0,s1
    80004782:	00000097          	auipc	ra,0x0
    80004786:	780080e7          	jalr	1920(ra) # 80004f02 <log_write>
    brelse(bp);
    8000478a:	8526                	mv	a0,s1
    8000478c:	fffff097          	auipc	ra,0xfffff
    80004790:	4f2080e7          	jalr	1266(ra) # 80003c7e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004794:	013d09bb          	addw	s3,s10,s3
    80004798:	012d093b          	addw	s2,s10,s2
    8000479c:	9a6e                	add	s4,s4,s11
    8000479e:	0569f663          	bgeu	s3,s6,800047ea <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    800047a2:	00a9559b          	srliw	a1,s2,0xa
    800047a6:	8556                	mv	a0,s5
    800047a8:	fffff097          	auipc	ra,0xfffff
    800047ac:	7a0080e7          	jalr	1952(ra) # 80003f48 <bmap>
    800047b0:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800047b4:	c99d                	beqz	a1,800047ea <writei+0xd6>
    bp = bread(ip->dev, addr);
    800047b6:	000aa503          	lw	a0,0(s5)
    800047ba:	fffff097          	auipc	ra,0xfffff
    800047be:	394080e7          	jalr	916(ra) # 80003b4e <bread>
    800047c2:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800047c4:	3ff97713          	andi	a4,s2,1023
    800047c8:	40ec87bb          	subw	a5,s9,a4
    800047cc:	413b06bb          	subw	a3,s6,s3
    800047d0:	8d3e                	mv	s10,a5
    800047d2:	2781                	sext.w	a5,a5
    800047d4:	0006861b          	sext.w	a2,a3
    800047d8:	f8f674e3          	bgeu	a2,a5,80004760 <writei+0x4c>
    800047dc:	8d36                	mv	s10,a3
    800047de:	b749                	j	80004760 <writei+0x4c>
      brelse(bp);
    800047e0:	8526                	mv	a0,s1
    800047e2:	fffff097          	auipc	ra,0xfffff
    800047e6:	49c080e7          	jalr	1180(ra) # 80003c7e <brelse>
  }

  if(off > ip->size)
    800047ea:	04caa783          	lw	a5,76(s5)
    800047ee:	0127f463          	bgeu	a5,s2,800047f6 <writei+0xe2>
    ip->size = off;
    800047f2:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800047f6:	8556                	mv	a0,s5
    800047f8:	00000097          	auipc	ra,0x0
    800047fc:	aa6080e7          	jalr	-1370(ra) # 8000429e <iupdate>

  return tot;
    80004800:	0009851b          	sext.w	a0,s3
}
    80004804:	70a6                	ld	ra,104(sp)
    80004806:	7406                	ld	s0,96(sp)
    80004808:	64e6                	ld	s1,88(sp)
    8000480a:	6946                	ld	s2,80(sp)
    8000480c:	69a6                	ld	s3,72(sp)
    8000480e:	6a06                	ld	s4,64(sp)
    80004810:	7ae2                	ld	s5,56(sp)
    80004812:	7b42                	ld	s6,48(sp)
    80004814:	7ba2                	ld	s7,40(sp)
    80004816:	7c02                	ld	s8,32(sp)
    80004818:	6ce2                	ld	s9,24(sp)
    8000481a:	6d42                	ld	s10,16(sp)
    8000481c:	6da2                	ld	s11,8(sp)
    8000481e:	6165                	addi	sp,sp,112
    80004820:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004822:	89da                	mv	s3,s6
    80004824:	bfc9                	j	800047f6 <writei+0xe2>
    return -1;
    80004826:	557d                	li	a0,-1
}
    80004828:	8082                	ret
    return -1;
    8000482a:	557d                	li	a0,-1
    8000482c:	bfe1                	j	80004804 <writei+0xf0>
    return -1;
    8000482e:	557d                	li	a0,-1
    80004830:	bfd1                	j	80004804 <writei+0xf0>

0000000080004832 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004832:	1141                	addi	sp,sp,-16
    80004834:	e406                	sd	ra,8(sp)
    80004836:	e022                	sd	s0,0(sp)
    80004838:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000483a:	4639                	li	a2,14
    8000483c:	ffffc097          	auipc	ra,0xffffc
    80004840:	582080e7          	jalr	1410(ra) # 80000dbe <strncmp>
}
    80004844:	60a2                	ld	ra,8(sp)
    80004846:	6402                	ld	s0,0(sp)
    80004848:	0141                	addi	sp,sp,16
    8000484a:	8082                	ret

000000008000484c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000484c:	7139                	addi	sp,sp,-64
    8000484e:	fc06                	sd	ra,56(sp)
    80004850:	f822                	sd	s0,48(sp)
    80004852:	f426                	sd	s1,40(sp)
    80004854:	f04a                	sd	s2,32(sp)
    80004856:	ec4e                	sd	s3,24(sp)
    80004858:	e852                	sd	s4,16(sp)
    8000485a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000485c:	04451703          	lh	a4,68(a0)
    80004860:	4785                	li	a5,1
    80004862:	00f71a63          	bne	a4,a5,80004876 <dirlookup+0x2a>
    80004866:	892a                	mv	s2,a0
    80004868:	89ae                	mv	s3,a1
    8000486a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000486c:	457c                	lw	a5,76(a0)
    8000486e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004870:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004872:	e79d                	bnez	a5,800048a0 <dirlookup+0x54>
    80004874:	a8a5                	j	800048ec <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004876:	00005517          	auipc	a0,0x5
    8000487a:	f4250513          	addi	a0,a0,-190 # 800097b8 <syscalls+0x1d0>
    8000487e:	ffffc097          	auipc	ra,0xffffc
    80004882:	cc6080e7          	jalr	-826(ra) # 80000544 <panic>
      panic("dirlookup read");
    80004886:	00005517          	auipc	a0,0x5
    8000488a:	f4a50513          	addi	a0,a0,-182 # 800097d0 <syscalls+0x1e8>
    8000488e:	ffffc097          	auipc	ra,0xffffc
    80004892:	cb6080e7          	jalr	-842(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004896:	24c1                	addiw	s1,s1,16
    80004898:	04c92783          	lw	a5,76(s2)
    8000489c:	04f4f763          	bgeu	s1,a5,800048ea <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800048a0:	4741                	li	a4,16
    800048a2:	86a6                	mv	a3,s1
    800048a4:	fc040613          	addi	a2,s0,-64
    800048a8:	4581                	li	a1,0
    800048aa:	854a                	mv	a0,s2
    800048ac:	00000097          	auipc	ra,0x0
    800048b0:	d70080e7          	jalr	-656(ra) # 8000461c <readi>
    800048b4:	47c1                	li	a5,16
    800048b6:	fcf518e3          	bne	a0,a5,80004886 <dirlookup+0x3a>
    if(de.inum == 0)
    800048ba:	fc045783          	lhu	a5,-64(s0)
    800048be:	dfe1                	beqz	a5,80004896 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800048c0:	fc240593          	addi	a1,s0,-62
    800048c4:	854e                	mv	a0,s3
    800048c6:	00000097          	auipc	ra,0x0
    800048ca:	f6c080e7          	jalr	-148(ra) # 80004832 <namecmp>
    800048ce:	f561                	bnez	a0,80004896 <dirlookup+0x4a>
      if(poff)
    800048d0:	000a0463          	beqz	s4,800048d8 <dirlookup+0x8c>
        *poff = off;
    800048d4:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800048d8:	fc045583          	lhu	a1,-64(s0)
    800048dc:	00092503          	lw	a0,0(s2)
    800048e0:	fffff097          	auipc	ra,0xfffff
    800048e4:	750080e7          	jalr	1872(ra) # 80004030 <iget>
    800048e8:	a011                	j	800048ec <dirlookup+0xa0>
  return 0;
    800048ea:	4501                	li	a0,0
}
    800048ec:	70e2                	ld	ra,56(sp)
    800048ee:	7442                	ld	s0,48(sp)
    800048f0:	74a2                	ld	s1,40(sp)
    800048f2:	7902                	ld	s2,32(sp)
    800048f4:	69e2                	ld	s3,24(sp)
    800048f6:	6a42                	ld	s4,16(sp)
    800048f8:	6121                	addi	sp,sp,64
    800048fa:	8082                	ret

00000000800048fc <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800048fc:	711d                	addi	sp,sp,-96
    800048fe:	ec86                	sd	ra,88(sp)
    80004900:	e8a2                	sd	s0,80(sp)
    80004902:	e4a6                	sd	s1,72(sp)
    80004904:	e0ca                	sd	s2,64(sp)
    80004906:	fc4e                	sd	s3,56(sp)
    80004908:	f852                	sd	s4,48(sp)
    8000490a:	f456                	sd	s5,40(sp)
    8000490c:	f05a                	sd	s6,32(sp)
    8000490e:	ec5e                	sd	s7,24(sp)
    80004910:	e862                	sd	s8,16(sp)
    80004912:	e466                	sd	s9,8(sp)
    80004914:	1080                	addi	s0,sp,96
    80004916:	84aa                	mv	s1,a0
    80004918:	8b2e                	mv	s6,a1
    8000491a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000491c:	00054703          	lbu	a4,0(a0)
    80004920:	02f00793          	li	a5,47
    80004924:	02f70363          	beq	a4,a5,8000494a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004928:	ffffd097          	auipc	ra,0xffffd
    8000492c:	2ce080e7          	jalr	718(ra) # 80001bf6 <myproc>
    80004930:	15053503          	ld	a0,336(a0)
    80004934:	00000097          	auipc	ra,0x0
    80004938:	9f6080e7          	jalr	-1546(ra) # 8000432a <idup>
    8000493c:	89aa                	mv	s3,a0
  while(*path == '/')
    8000493e:	02f00913          	li	s2,47
  len = path - s;
    80004942:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004944:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004946:	4c05                	li	s8,1
    80004948:	a865                	j	80004a00 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000494a:	4585                	li	a1,1
    8000494c:	4505                	li	a0,1
    8000494e:	fffff097          	auipc	ra,0xfffff
    80004952:	6e2080e7          	jalr	1762(ra) # 80004030 <iget>
    80004956:	89aa                	mv	s3,a0
    80004958:	b7dd                	j	8000493e <namex+0x42>
      iunlockput(ip);
    8000495a:	854e                	mv	a0,s3
    8000495c:	00000097          	auipc	ra,0x0
    80004960:	c6e080e7          	jalr	-914(ra) # 800045ca <iunlockput>
      return 0;
    80004964:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004966:	854e                	mv	a0,s3
    80004968:	60e6                	ld	ra,88(sp)
    8000496a:	6446                	ld	s0,80(sp)
    8000496c:	64a6                	ld	s1,72(sp)
    8000496e:	6906                	ld	s2,64(sp)
    80004970:	79e2                	ld	s3,56(sp)
    80004972:	7a42                	ld	s4,48(sp)
    80004974:	7aa2                	ld	s5,40(sp)
    80004976:	7b02                	ld	s6,32(sp)
    80004978:	6be2                	ld	s7,24(sp)
    8000497a:	6c42                	ld	s8,16(sp)
    8000497c:	6ca2                	ld	s9,8(sp)
    8000497e:	6125                	addi	sp,sp,96
    80004980:	8082                	ret
      iunlock(ip);
    80004982:	854e                	mv	a0,s3
    80004984:	00000097          	auipc	ra,0x0
    80004988:	aa6080e7          	jalr	-1370(ra) # 8000442a <iunlock>
      return ip;
    8000498c:	bfe9                	j	80004966 <namex+0x6a>
      iunlockput(ip);
    8000498e:	854e                	mv	a0,s3
    80004990:	00000097          	auipc	ra,0x0
    80004994:	c3a080e7          	jalr	-966(ra) # 800045ca <iunlockput>
      return 0;
    80004998:	89d2                	mv	s3,s4
    8000499a:	b7f1                	j	80004966 <namex+0x6a>
  len = path - s;
    8000499c:	40b48633          	sub	a2,s1,a1
    800049a0:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800049a4:	094cd463          	bge	s9,s4,80004a2c <namex+0x130>
    memmove(name, s, DIRSIZ);
    800049a8:	4639                	li	a2,14
    800049aa:	8556                	mv	a0,s5
    800049ac:	ffffc097          	auipc	ra,0xffffc
    800049b0:	39a080e7          	jalr	922(ra) # 80000d46 <memmove>
  while(*path == '/')
    800049b4:	0004c783          	lbu	a5,0(s1)
    800049b8:	01279763          	bne	a5,s2,800049c6 <namex+0xca>
    path++;
    800049bc:	0485                	addi	s1,s1,1
  while(*path == '/')
    800049be:	0004c783          	lbu	a5,0(s1)
    800049c2:	ff278de3          	beq	a5,s2,800049bc <namex+0xc0>
    ilock(ip);
    800049c6:	854e                	mv	a0,s3
    800049c8:	00000097          	auipc	ra,0x0
    800049cc:	9a0080e7          	jalr	-1632(ra) # 80004368 <ilock>
    if(ip->type != T_DIR){
    800049d0:	04499783          	lh	a5,68(s3)
    800049d4:	f98793e3          	bne	a5,s8,8000495a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800049d8:	000b0563          	beqz	s6,800049e2 <namex+0xe6>
    800049dc:	0004c783          	lbu	a5,0(s1)
    800049e0:	d3cd                	beqz	a5,80004982 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800049e2:	865e                	mv	a2,s7
    800049e4:	85d6                	mv	a1,s5
    800049e6:	854e                	mv	a0,s3
    800049e8:	00000097          	auipc	ra,0x0
    800049ec:	e64080e7          	jalr	-412(ra) # 8000484c <dirlookup>
    800049f0:	8a2a                	mv	s4,a0
    800049f2:	dd51                	beqz	a0,8000498e <namex+0x92>
    iunlockput(ip);
    800049f4:	854e                	mv	a0,s3
    800049f6:	00000097          	auipc	ra,0x0
    800049fa:	bd4080e7          	jalr	-1068(ra) # 800045ca <iunlockput>
    ip = next;
    800049fe:	89d2                	mv	s3,s4
  while(*path == '/')
    80004a00:	0004c783          	lbu	a5,0(s1)
    80004a04:	05279763          	bne	a5,s2,80004a52 <namex+0x156>
    path++;
    80004a08:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004a0a:	0004c783          	lbu	a5,0(s1)
    80004a0e:	ff278de3          	beq	a5,s2,80004a08 <namex+0x10c>
  if(*path == 0)
    80004a12:	c79d                	beqz	a5,80004a40 <namex+0x144>
    path++;
    80004a14:	85a6                	mv	a1,s1
  len = path - s;
    80004a16:	8a5e                	mv	s4,s7
    80004a18:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004a1a:	01278963          	beq	a5,s2,80004a2c <namex+0x130>
    80004a1e:	dfbd                	beqz	a5,8000499c <namex+0xa0>
    path++;
    80004a20:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004a22:	0004c783          	lbu	a5,0(s1)
    80004a26:	ff279ce3          	bne	a5,s2,80004a1e <namex+0x122>
    80004a2a:	bf8d                	j	8000499c <namex+0xa0>
    memmove(name, s, len);
    80004a2c:	2601                	sext.w	a2,a2
    80004a2e:	8556                	mv	a0,s5
    80004a30:	ffffc097          	auipc	ra,0xffffc
    80004a34:	316080e7          	jalr	790(ra) # 80000d46 <memmove>
    name[len] = 0;
    80004a38:	9a56                	add	s4,s4,s5
    80004a3a:	000a0023          	sb	zero,0(s4)
    80004a3e:	bf9d                	j	800049b4 <namex+0xb8>
  if(nameiparent){
    80004a40:	f20b03e3          	beqz	s6,80004966 <namex+0x6a>
    iput(ip);
    80004a44:	854e                	mv	a0,s3
    80004a46:	00000097          	auipc	ra,0x0
    80004a4a:	adc080e7          	jalr	-1316(ra) # 80004522 <iput>
    return 0;
    80004a4e:	4981                	li	s3,0
    80004a50:	bf19                	j	80004966 <namex+0x6a>
  if(*path == 0)
    80004a52:	d7fd                	beqz	a5,80004a40 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004a54:	0004c783          	lbu	a5,0(s1)
    80004a58:	85a6                	mv	a1,s1
    80004a5a:	b7d1                	j	80004a1e <namex+0x122>

0000000080004a5c <dirlink>:
{
    80004a5c:	7139                	addi	sp,sp,-64
    80004a5e:	fc06                	sd	ra,56(sp)
    80004a60:	f822                	sd	s0,48(sp)
    80004a62:	f426                	sd	s1,40(sp)
    80004a64:	f04a                	sd	s2,32(sp)
    80004a66:	ec4e                	sd	s3,24(sp)
    80004a68:	e852                	sd	s4,16(sp)
    80004a6a:	0080                	addi	s0,sp,64
    80004a6c:	892a                	mv	s2,a0
    80004a6e:	8a2e                	mv	s4,a1
    80004a70:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004a72:	4601                	li	a2,0
    80004a74:	00000097          	auipc	ra,0x0
    80004a78:	dd8080e7          	jalr	-552(ra) # 8000484c <dirlookup>
    80004a7c:	e93d                	bnez	a0,80004af2 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004a7e:	04c92483          	lw	s1,76(s2)
    80004a82:	c49d                	beqz	s1,80004ab0 <dirlink+0x54>
    80004a84:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004a86:	4741                	li	a4,16
    80004a88:	86a6                	mv	a3,s1
    80004a8a:	fc040613          	addi	a2,s0,-64
    80004a8e:	4581                	li	a1,0
    80004a90:	854a                	mv	a0,s2
    80004a92:	00000097          	auipc	ra,0x0
    80004a96:	b8a080e7          	jalr	-1142(ra) # 8000461c <readi>
    80004a9a:	47c1                	li	a5,16
    80004a9c:	06f51163          	bne	a0,a5,80004afe <dirlink+0xa2>
    if(de.inum == 0)
    80004aa0:	fc045783          	lhu	a5,-64(s0)
    80004aa4:	c791                	beqz	a5,80004ab0 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004aa6:	24c1                	addiw	s1,s1,16
    80004aa8:	04c92783          	lw	a5,76(s2)
    80004aac:	fcf4ede3          	bltu	s1,a5,80004a86 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004ab0:	4639                	li	a2,14
    80004ab2:	85d2                	mv	a1,s4
    80004ab4:	fc240513          	addi	a0,s0,-62
    80004ab8:	ffffc097          	auipc	ra,0xffffc
    80004abc:	342080e7          	jalr	834(ra) # 80000dfa <strncpy>
  de.inum = inum;
    80004ac0:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004ac4:	4741                	li	a4,16
    80004ac6:	86a6                	mv	a3,s1
    80004ac8:	fc040613          	addi	a2,s0,-64
    80004acc:	4581                	li	a1,0
    80004ace:	854a                	mv	a0,s2
    80004ad0:	00000097          	auipc	ra,0x0
    80004ad4:	c44080e7          	jalr	-956(ra) # 80004714 <writei>
    80004ad8:	1541                	addi	a0,a0,-16
    80004ada:	00a03533          	snez	a0,a0
    80004ade:	40a00533          	neg	a0,a0
}
    80004ae2:	70e2                	ld	ra,56(sp)
    80004ae4:	7442                	ld	s0,48(sp)
    80004ae6:	74a2                	ld	s1,40(sp)
    80004ae8:	7902                	ld	s2,32(sp)
    80004aea:	69e2                	ld	s3,24(sp)
    80004aec:	6a42                	ld	s4,16(sp)
    80004aee:	6121                	addi	sp,sp,64
    80004af0:	8082                	ret
    iput(ip);
    80004af2:	00000097          	auipc	ra,0x0
    80004af6:	a30080e7          	jalr	-1488(ra) # 80004522 <iput>
    return -1;
    80004afa:	557d                	li	a0,-1
    80004afc:	b7dd                	j	80004ae2 <dirlink+0x86>
      panic("dirlink read");
    80004afe:	00005517          	auipc	a0,0x5
    80004b02:	ce250513          	addi	a0,a0,-798 # 800097e0 <syscalls+0x1f8>
    80004b06:	ffffc097          	auipc	ra,0xffffc
    80004b0a:	a3e080e7          	jalr	-1474(ra) # 80000544 <panic>

0000000080004b0e <namei>:

struct inode*
namei(char *path)
{
    80004b0e:	1101                	addi	sp,sp,-32
    80004b10:	ec06                	sd	ra,24(sp)
    80004b12:	e822                	sd	s0,16(sp)
    80004b14:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004b16:	fe040613          	addi	a2,s0,-32
    80004b1a:	4581                	li	a1,0
    80004b1c:	00000097          	auipc	ra,0x0
    80004b20:	de0080e7          	jalr	-544(ra) # 800048fc <namex>
}
    80004b24:	60e2                	ld	ra,24(sp)
    80004b26:	6442                	ld	s0,16(sp)
    80004b28:	6105                	addi	sp,sp,32
    80004b2a:	8082                	ret

0000000080004b2c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004b2c:	1141                	addi	sp,sp,-16
    80004b2e:	e406                	sd	ra,8(sp)
    80004b30:	e022                	sd	s0,0(sp)
    80004b32:	0800                	addi	s0,sp,16
    80004b34:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004b36:	4585                	li	a1,1
    80004b38:	00000097          	auipc	ra,0x0
    80004b3c:	dc4080e7          	jalr	-572(ra) # 800048fc <namex>
}
    80004b40:	60a2                	ld	ra,8(sp)
    80004b42:	6402                	ld	s0,0(sp)
    80004b44:	0141                	addi	sp,sp,16
    80004b46:	8082                	ret

0000000080004b48 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004b48:	1101                	addi	sp,sp,-32
    80004b4a:	ec06                	sd	ra,24(sp)
    80004b4c:	e822                	sd	s0,16(sp)
    80004b4e:	e426                	sd	s1,8(sp)
    80004b50:	e04a                	sd	s2,0(sp)
    80004b52:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004b54:	0001f917          	auipc	s2,0x1f
    80004b58:	50490913          	addi	s2,s2,1284 # 80024058 <log>
    80004b5c:	01892583          	lw	a1,24(s2)
    80004b60:	02892503          	lw	a0,40(s2)
    80004b64:	fffff097          	auipc	ra,0xfffff
    80004b68:	fea080e7          	jalr	-22(ra) # 80003b4e <bread>
    80004b6c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004b6e:	02c92683          	lw	a3,44(s2)
    80004b72:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004b74:	02d05763          	blez	a3,80004ba2 <write_head+0x5a>
    80004b78:	0001f797          	auipc	a5,0x1f
    80004b7c:	51078793          	addi	a5,a5,1296 # 80024088 <log+0x30>
    80004b80:	05c50713          	addi	a4,a0,92
    80004b84:	36fd                	addiw	a3,a3,-1
    80004b86:	1682                	slli	a3,a3,0x20
    80004b88:	9281                	srli	a3,a3,0x20
    80004b8a:	068a                	slli	a3,a3,0x2
    80004b8c:	0001f617          	auipc	a2,0x1f
    80004b90:	50060613          	addi	a2,a2,1280 # 8002408c <log+0x34>
    80004b94:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004b96:	4390                	lw	a2,0(a5)
    80004b98:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004b9a:	0791                	addi	a5,a5,4
    80004b9c:	0711                	addi	a4,a4,4
    80004b9e:	fed79ce3          	bne	a5,a3,80004b96 <write_head+0x4e>
  }
  bwrite(buf);
    80004ba2:	8526                	mv	a0,s1
    80004ba4:	fffff097          	auipc	ra,0xfffff
    80004ba8:	09c080e7          	jalr	156(ra) # 80003c40 <bwrite>
  brelse(buf);
    80004bac:	8526                	mv	a0,s1
    80004bae:	fffff097          	auipc	ra,0xfffff
    80004bb2:	0d0080e7          	jalr	208(ra) # 80003c7e <brelse>
}
    80004bb6:	60e2                	ld	ra,24(sp)
    80004bb8:	6442                	ld	s0,16(sp)
    80004bba:	64a2                	ld	s1,8(sp)
    80004bbc:	6902                	ld	s2,0(sp)
    80004bbe:	6105                	addi	sp,sp,32
    80004bc0:	8082                	ret

0000000080004bc2 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004bc2:	0001f797          	auipc	a5,0x1f
    80004bc6:	4c27a783          	lw	a5,1218(a5) # 80024084 <log+0x2c>
    80004bca:	0af05d63          	blez	a5,80004c84 <install_trans+0xc2>
{
    80004bce:	7139                	addi	sp,sp,-64
    80004bd0:	fc06                	sd	ra,56(sp)
    80004bd2:	f822                	sd	s0,48(sp)
    80004bd4:	f426                	sd	s1,40(sp)
    80004bd6:	f04a                	sd	s2,32(sp)
    80004bd8:	ec4e                	sd	s3,24(sp)
    80004bda:	e852                	sd	s4,16(sp)
    80004bdc:	e456                	sd	s5,8(sp)
    80004bde:	e05a                	sd	s6,0(sp)
    80004be0:	0080                	addi	s0,sp,64
    80004be2:	8b2a                	mv	s6,a0
    80004be4:	0001fa97          	auipc	s5,0x1f
    80004be8:	4a4a8a93          	addi	s5,s5,1188 # 80024088 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004bec:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004bee:	0001f997          	auipc	s3,0x1f
    80004bf2:	46a98993          	addi	s3,s3,1130 # 80024058 <log>
    80004bf6:	a035                	j	80004c22 <install_trans+0x60>
      bunpin(dbuf);
    80004bf8:	8526                	mv	a0,s1
    80004bfa:	fffff097          	auipc	ra,0xfffff
    80004bfe:	15e080e7          	jalr	350(ra) # 80003d58 <bunpin>
    brelse(lbuf);
    80004c02:	854a                	mv	a0,s2
    80004c04:	fffff097          	auipc	ra,0xfffff
    80004c08:	07a080e7          	jalr	122(ra) # 80003c7e <brelse>
    brelse(dbuf);
    80004c0c:	8526                	mv	a0,s1
    80004c0e:	fffff097          	auipc	ra,0xfffff
    80004c12:	070080e7          	jalr	112(ra) # 80003c7e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004c16:	2a05                	addiw	s4,s4,1
    80004c18:	0a91                	addi	s5,s5,4
    80004c1a:	02c9a783          	lw	a5,44(s3)
    80004c1e:	04fa5963          	bge	s4,a5,80004c70 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004c22:	0189a583          	lw	a1,24(s3)
    80004c26:	014585bb          	addw	a1,a1,s4
    80004c2a:	2585                	addiw	a1,a1,1
    80004c2c:	0289a503          	lw	a0,40(s3)
    80004c30:	fffff097          	auipc	ra,0xfffff
    80004c34:	f1e080e7          	jalr	-226(ra) # 80003b4e <bread>
    80004c38:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004c3a:	000aa583          	lw	a1,0(s5)
    80004c3e:	0289a503          	lw	a0,40(s3)
    80004c42:	fffff097          	auipc	ra,0xfffff
    80004c46:	f0c080e7          	jalr	-244(ra) # 80003b4e <bread>
    80004c4a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004c4c:	40000613          	li	a2,1024
    80004c50:	05890593          	addi	a1,s2,88
    80004c54:	05850513          	addi	a0,a0,88
    80004c58:	ffffc097          	auipc	ra,0xffffc
    80004c5c:	0ee080e7          	jalr	238(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004c60:	8526                	mv	a0,s1
    80004c62:	fffff097          	auipc	ra,0xfffff
    80004c66:	fde080e7          	jalr	-34(ra) # 80003c40 <bwrite>
    if(recovering == 0)
    80004c6a:	f80b1ce3          	bnez	s6,80004c02 <install_trans+0x40>
    80004c6e:	b769                	j	80004bf8 <install_trans+0x36>
}
    80004c70:	70e2                	ld	ra,56(sp)
    80004c72:	7442                	ld	s0,48(sp)
    80004c74:	74a2                	ld	s1,40(sp)
    80004c76:	7902                	ld	s2,32(sp)
    80004c78:	69e2                	ld	s3,24(sp)
    80004c7a:	6a42                	ld	s4,16(sp)
    80004c7c:	6aa2                	ld	s5,8(sp)
    80004c7e:	6b02                	ld	s6,0(sp)
    80004c80:	6121                	addi	sp,sp,64
    80004c82:	8082                	ret
    80004c84:	8082                	ret

0000000080004c86 <initlog>:
{
    80004c86:	7179                	addi	sp,sp,-48
    80004c88:	f406                	sd	ra,40(sp)
    80004c8a:	f022                	sd	s0,32(sp)
    80004c8c:	ec26                	sd	s1,24(sp)
    80004c8e:	e84a                	sd	s2,16(sp)
    80004c90:	e44e                	sd	s3,8(sp)
    80004c92:	1800                	addi	s0,sp,48
    80004c94:	892a                	mv	s2,a0
    80004c96:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004c98:	0001f497          	auipc	s1,0x1f
    80004c9c:	3c048493          	addi	s1,s1,960 # 80024058 <log>
    80004ca0:	00005597          	auipc	a1,0x5
    80004ca4:	b5058593          	addi	a1,a1,-1200 # 800097f0 <syscalls+0x208>
    80004ca8:	8526                	mv	a0,s1
    80004caa:	ffffc097          	auipc	ra,0xffffc
    80004cae:	eb0080e7          	jalr	-336(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    80004cb2:	0149a583          	lw	a1,20(s3)
    80004cb6:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004cb8:	0109a783          	lw	a5,16(s3)
    80004cbc:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004cbe:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004cc2:	854a                	mv	a0,s2
    80004cc4:	fffff097          	auipc	ra,0xfffff
    80004cc8:	e8a080e7          	jalr	-374(ra) # 80003b4e <bread>
  log.lh.n = lh->n;
    80004ccc:	4d3c                	lw	a5,88(a0)
    80004cce:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004cd0:	02f05563          	blez	a5,80004cfa <initlog+0x74>
    80004cd4:	05c50713          	addi	a4,a0,92
    80004cd8:	0001f697          	auipc	a3,0x1f
    80004cdc:	3b068693          	addi	a3,a3,944 # 80024088 <log+0x30>
    80004ce0:	37fd                	addiw	a5,a5,-1
    80004ce2:	1782                	slli	a5,a5,0x20
    80004ce4:	9381                	srli	a5,a5,0x20
    80004ce6:	078a                	slli	a5,a5,0x2
    80004ce8:	06050613          	addi	a2,a0,96
    80004cec:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004cee:	4310                	lw	a2,0(a4)
    80004cf0:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004cf2:	0711                	addi	a4,a4,4
    80004cf4:	0691                	addi	a3,a3,4
    80004cf6:	fef71ce3          	bne	a4,a5,80004cee <initlog+0x68>
  brelse(buf);
    80004cfa:	fffff097          	auipc	ra,0xfffff
    80004cfe:	f84080e7          	jalr	-124(ra) # 80003c7e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004d02:	4505                	li	a0,1
    80004d04:	00000097          	auipc	ra,0x0
    80004d08:	ebe080e7          	jalr	-322(ra) # 80004bc2 <install_trans>
  log.lh.n = 0;
    80004d0c:	0001f797          	auipc	a5,0x1f
    80004d10:	3607ac23          	sw	zero,888(a5) # 80024084 <log+0x2c>
  write_head(); // clear the log
    80004d14:	00000097          	auipc	ra,0x0
    80004d18:	e34080e7          	jalr	-460(ra) # 80004b48 <write_head>
}
    80004d1c:	70a2                	ld	ra,40(sp)
    80004d1e:	7402                	ld	s0,32(sp)
    80004d20:	64e2                	ld	s1,24(sp)
    80004d22:	6942                	ld	s2,16(sp)
    80004d24:	69a2                	ld	s3,8(sp)
    80004d26:	6145                	addi	sp,sp,48
    80004d28:	8082                	ret

0000000080004d2a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004d2a:	1101                	addi	sp,sp,-32
    80004d2c:	ec06                	sd	ra,24(sp)
    80004d2e:	e822                	sd	s0,16(sp)
    80004d30:	e426                	sd	s1,8(sp)
    80004d32:	e04a                	sd	s2,0(sp)
    80004d34:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004d36:	0001f517          	auipc	a0,0x1f
    80004d3a:	32250513          	addi	a0,a0,802 # 80024058 <log>
    80004d3e:	ffffc097          	auipc	ra,0xffffc
    80004d42:	eac080e7          	jalr	-340(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    80004d46:	0001f497          	auipc	s1,0x1f
    80004d4a:	31248493          	addi	s1,s1,786 # 80024058 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004d4e:	4979                	li	s2,30
    80004d50:	a039                	j	80004d5e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004d52:	85a6                	mv	a1,s1
    80004d54:	8526                	mv	a0,s1
    80004d56:	ffffd097          	auipc	ra,0xffffd
    80004d5a:	700080e7          	jalr	1792(ra) # 80002456 <sleep>
    if(log.committing){
    80004d5e:	50dc                	lw	a5,36(s1)
    80004d60:	fbed                	bnez	a5,80004d52 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004d62:	509c                	lw	a5,32(s1)
    80004d64:	0017871b          	addiw	a4,a5,1
    80004d68:	0007069b          	sext.w	a3,a4
    80004d6c:	0027179b          	slliw	a5,a4,0x2
    80004d70:	9fb9                	addw	a5,a5,a4
    80004d72:	0017979b          	slliw	a5,a5,0x1
    80004d76:	54d8                	lw	a4,44(s1)
    80004d78:	9fb9                	addw	a5,a5,a4
    80004d7a:	00f95963          	bge	s2,a5,80004d8c <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004d7e:	85a6                	mv	a1,s1
    80004d80:	8526                	mv	a0,s1
    80004d82:	ffffd097          	auipc	ra,0xffffd
    80004d86:	6d4080e7          	jalr	1748(ra) # 80002456 <sleep>
    80004d8a:	bfd1                	j	80004d5e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004d8c:	0001f517          	auipc	a0,0x1f
    80004d90:	2cc50513          	addi	a0,a0,716 # 80024058 <log>
    80004d94:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004d96:	ffffc097          	auipc	ra,0xffffc
    80004d9a:	f08080e7          	jalr	-248(ra) # 80000c9e <release>
      break;
    }
  }
}
    80004d9e:	60e2                	ld	ra,24(sp)
    80004da0:	6442                	ld	s0,16(sp)
    80004da2:	64a2                	ld	s1,8(sp)
    80004da4:	6902                	ld	s2,0(sp)
    80004da6:	6105                	addi	sp,sp,32
    80004da8:	8082                	ret

0000000080004daa <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004daa:	7139                	addi	sp,sp,-64
    80004dac:	fc06                	sd	ra,56(sp)
    80004dae:	f822                	sd	s0,48(sp)
    80004db0:	f426                	sd	s1,40(sp)
    80004db2:	f04a                	sd	s2,32(sp)
    80004db4:	ec4e                	sd	s3,24(sp)
    80004db6:	e852                	sd	s4,16(sp)
    80004db8:	e456                	sd	s5,8(sp)
    80004dba:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004dbc:	0001f497          	auipc	s1,0x1f
    80004dc0:	29c48493          	addi	s1,s1,668 # 80024058 <log>
    80004dc4:	8526                	mv	a0,s1
    80004dc6:	ffffc097          	auipc	ra,0xffffc
    80004dca:	e24080e7          	jalr	-476(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    80004dce:	509c                	lw	a5,32(s1)
    80004dd0:	37fd                	addiw	a5,a5,-1
    80004dd2:	0007891b          	sext.w	s2,a5
    80004dd6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004dd8:	50dc                	lw	a5,36(s1)
    80004dda:	efb9                	bnez	a5,80004e38 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004ddc:	06091663          	bnez	s2,80004e48 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004de0:	0001f497          	auipc	s1,0x1f
    80004de4:	27848493          	addi	s1,s1,632 # 80024058 <log>
    80004de8:	4785                	li	a5,1
    80004dea:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004dec:	8526                	mv	a0,s1
    80004dee:	ffffc097          	auipc	ra,0xffffc
    80004df2:	eb0080e7          	jalr	-336(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004df6:	54dc                	lw	a5,44(s1)
    80004df8:	06f04763          	bgtz	a5,80004e66 <end_op+0xbc>
    acquire(&log.lock);
    80004dfc:	0001f497          	auipc	s1,0x1f
    80004e00:	25c48493          	addi	s1,s1,604 # 80024058 <log>
    80004e04:	8526                	mv	a0,s1
    80004e06:	ffffc097          	auipc	ra,0xffffc
    80004e0a:	de4080e7          	jalr	-540(ra) # 80000bea <acquire>
    log.committing = 0;
    80004e0e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004e12:	8526                	mv	a0,s1
    80004e14:	ffffd097          	auipc	ra,0xffffd
    80004e18:	7f2080e7          	jalr	2034(ra) # 80002606 <wakeup>
    release(&log.lock);
    80004e1c:	8526                	mv	a0,s1
    80004e1e:	ffffc097          	auipc	ra,0xffffc
    80004e22:	e80080e7          	jalr	-384(ra) # 80000c9e <release>
}
    80004e26:	70e2                	ld	ra,56(sp)
    80004e28:	7442                	ld	s0,48(sp)
    80004e2a:	74a2                	ld	s1,40(sp)
    80004e2c:	7902                	ld	s2,32(sp)
    80004e2e:	69e2                	ld	s3,24(sp)
    80004e30:	6a42                	ld	s4,16(sp)
    80004e32:	6aa2                	ld	s5,8(sp)
    80004e34:	6121                	addi	sp,sp,64
    80004e36:	8082                	ret
    panic("log.committing");
    80004e38:	00005517          	auipc	a0,0x5
    80004e3c:	9c050513          	addi	a0,a0,-1600 # 800097f8 <syscalls+0x210>
    80004e40:	ffffb097          	auipc	ra,0xffffb
    80004e44:	704080e7          	jalr	1796(ra) # 80000544 <panic>
    wakeup(&log);
    80004e48:	0001f497          	auipc	s1,0x1f
    80004e4c:	21048493          	addi	s1,s1,528 # 80024058 <log>
    80004e50:	8526                	mv	a0,s1
    80004e52:	ffffd097          	auipc	ra,0xffffd
    80004e56:	7b4080e7          	jalr	1972(ra) # 80002606 <wakeup>
  release(&log.lock);
    80004e5a:	8526                	mv	a0,s1
    80004e5c:	ffffc097          	auipc	ra,0xffffc
    80004e60:	e42080e7          	jalr	-446(ra) # 80000c9e <release>
  if(do_commit){
    80004e64:	b7c9                	j	80004e26 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004e66:	0001fa97          	auipc	s5,0x1f
    80004e6a:	222a8a93          	addi	s5,s5,546 # 80024088 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004e6e:	0001fa17          	auipc	s4,0x1f
    80004e72:	1eaa0a13          	addi	s4,s4,490 # 80024058 <log>
    80004e76:	018a2583          	lw	a1,24(s4)
    80004e7a:	012585bb          	addw	a1,a1,s2
    80004e7e:	2585                	addiw	a1,a1,1
    80004e80:	028a2503          	lw	a0,40(s4)
    80004e84:	fffff097          	auipc	ra,0xfffff
    80004e88:	cca080e7          	jalr	-822(ra) # 80003b4e <bread>
    80004e8c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004e8e:	000aa583          	lw	a1,0(s5)
    80004e92:	028a2503          	lw	a0,40(s4)
    80004e96:	fffff097          	auipc	ra,0xfffff
    80004e9a:	cb8080e7          	jalr	-840(ra) # 80003b4e <bread>
    80004e9e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004ea0:	40000613          	li	a2,1024
    80004ea4:	05850593          	addi	a1,a0,88
    80004ea8:	05848513          	addi	a0,s1,88
    80004eac:	ffffc097          	auipc	ra,0xffffc
    80004eb0:	e9a080e7          	jalr	-358(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    80004eb4:	8526                	mv	a0,s1
    80004eb6:	fffff097          	auipc	ra,0xfffff
    80004eba:	d8a080e7          	jalr	-630(ra) # 80003c40 <bwrite>
    brelse(from);
    80004ebe:	854e                	mv	a0,s3
    80004ec0:	fffff097          	auipc	ra,0xfffff
    80004ec4:	dbe080e7          	jalr	-578(ra) # 80003c7e <brelse>
    brelse(to);
    80004ec8:	8526                	mv	a0,s1
    80004eca:	fffff097          	auipc	ra,0xfffff
    80004ece:	db4080e7          	jalr	-588(ra) # 80003c7e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004ed2:	2905                	addiw	s2,s2,1
    80004ed4:	0a91                	addi	s5,s5,4
    80004ed6:	02ca2783          	lw	a5,44(s4)
    80004eda:	f8f94ee3          	blt	s2,a5,80004e76 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004ede:	00000097          	auipc	ra,0x0
    80004ee2:	c6a080e7          	jalr	-918(ra) # 80004b48 <write_head>
    install_trans(0); // Now install writes to home locations
    80004ee6:	4501                	li	a0,0
    80004ee8:	00000097          	auipc	ra,0x0
    80004eec:	cda080e7          	jalr	-806(ra) # 80004bc2 <install_trans>
    log.lh.n = 0;
    80004ef0:	0001f797          	auipc	a5,0x1f
    80004ef4:	1807aa23          	sw	zero,404(a5) # 80024084 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004ef8:	00000097          	auipc	ra,0x0
    80004efc:	c50080e7          	jalr	-944(ra) # 80004b48 <write_head>
    80004f00:	bdf5                	j	80004dfc <end_op+0x52>

0000000080004f02 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004f02:	1101                	addi	sp,sp,-32
    80004f04:	ec06                	sd	ra,24(sp)
    80004f06:	e822                	sd	s0,16(sp)
    80004f08:	e426                	sd	s1,8(sp)
    80004f0a:	e04a                	sd	s2,0(sp)
    80004f0c:	1000                	addi	s0,sp,32
    80004f0e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004f10:	0001f917          	auipc	s2,0x1f
    80004f14:	14890913          	addi	s2,s2,328 # 80024058 <log>
    80004f18:	854a                	mv	a0,s2
    80004f1a:	ffffc097          	auipc	ra,0xffffc
    80004f1e:	cd0080e7          	jalr	-816(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004f22:	02c92603          	lw	a2,44(s2)
    80004f26:	47f5                	li	a5,29
    80004f28:	06c7c563          	blt	a5,a2,80004f92 <log_write+0x90>
    80004f2c:	0001f797          	auipc	a5,0x1f
    80004f30:	1487a783          	lw	a5,328(a5) # 80024074 <log+0x1c>
    80004f34:	37fd                	addiw	a5,a5,-1
    80004f36:	04f65e63          	bge	a2,a5,80004f92 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004f3a:	0001f797          	auipc	a5,0x1f
    80004f3e:	13e7a783          	lw	a5,318(a5) # 80024078 <log+0x20>
    80004f42:	06f05063          	blez	a5,80004fa2 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004f46:	4781                	li	a5,0
    80004f48:	06c05563          	blez	a2,80004fb2 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004f4c:	44cc                	lw	a1,12(s1)
    80004f4e:	0001f717          	auipc	a4,0x1f
    80004f52:	13a70713          	addi	a4,a4,314 # 80024088 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004f56:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004f58:	4314                	lw	a3,0(a4)
    80004f5a:	04b68c63          	beq	a3,a1,80004fb2 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004f5e:	2785                	addiw	a5,a5,1
    80004f60:	0711                	addi	a4,a4,4
    80004f62:	fef61be3          	bne	a2,a5,80004f58 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004f66:	0621                	addi	a2,a2,8
    80004f68:	060a                	slli	a2,a2,0x2
    80004f6a:	0001f797          	auipc	a5,0x1f
    80004f6e:	0ee78793          	addi	a5,a5,238 # 80024058 <log>
    80004f72:	963e                	add	a2,a2,a5
    80004f74:	44dc                	lw	a5,12(s1)
    80004f76:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004f78:	8526                	mv	a0,s1
    80004f7a:	fffff097          	auipc	ra,0xfffff
    80004f7e:	da2080e7          	jalr	-606(ra) # 80003d1c <bpin>
    log.lh.n++;
    80004f82:	0001f717          	auipc	a4,0x1f
    80004f86:	0d670713          	addi	a4,a4,214 # 80024058 <log>
    80004f8a:	575c                	lw	a5,44(a4)
    80004f8c:	2785                	addiw	a5,a5,1
    80004f8e:	d75c                	sw	a5,44(a4)
    80004f90:	a835                	j	80004fcc <log_write+0xca>
    panic("too big a transaction");
    80004f92:	00005517          	auipc	a0,0x5
    80004f96:	87650513          	addi	a0,a0,-1930 # 80009808 <syscalls+0x220>
    80004f9a:	ffffb097          	auipc	ra,0xffffb
    80004f9e:	5aa080e7          	jalr	1450(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    80004fa2:	00005517          	auipc	a0,0x5
    80004fa6:	87e50513          	addi	a0,a0,-1922 # 80009820 <syscalls+0x238>
    80004faa:	ffffb097          	auipc	ra,0xffffb
    80004fae:	59a080e7          	jalr	1434(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    80004fb2:	00878713          	addi	a4,a5,8
    80004fb6:	00271693          	slli	a3,a4,0x2
    80004fba:	0001f717          	auipc	a4,0x1f
    80004fbe:	09e70713          	addi	a4,a4,158 # 80024058 <log>
    80004fc2:	9736                	add	a4,a4,a3
    80004fc4:	44d4                	lw	a3,12(s1)
    80004fc6:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004fc8:	faf608e3          	beq	a2,a5,80004f78 <log_write+0x76>
  }
  release(&log.lock);
    80004fcc:	0001f517          	auipc	a0,0x1f
    80004fd0:	08c50513          	addi	a0,a0,140 # 80024058 <log>
    80004fd4:	ffffc097          	auipc	ra,0xffffc
    80004fd8:	cca080e7          	jalr	-822(ra) # 80000c9e <release>
}
    80004fdc:	60e2                	ld	ra,24(sp)
    80004fde:	6442                	ld	s0,16(sp)
    80004fe0:	64a2                	ld	s1,8(sp)
    80004fe2:	6902                	ld	s2,0(sp)
    80004fe4:	6105                	addi	sp,sp,32
    80004fe6:	8082                	ret

0000000080004fe8 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004fe8:	1101                	addi	sp,sp,-32
    80004fea:	ec06                	sd	ra,24(sp)
    80004fec:	e822                	sd	s0,16(sp)
    80004fee:	e426                	sd	s1,8(sp)
    80004ff0:	e04a                	sd	s2,0(sp)
    80004ff2:	1000                	addi	s0,sp,32
    80004ff4:	84aa                	mv	s1,a0
    80004ff6:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004ff8:	00005597          	auipc	a1,0x5
    80004ffc:	84858593          	addi	a1,a1,-1976 # 80009840 <syscalls+0x258>
    80005000:	0521                	addi	a0,a0,8
    80005002:	ffffc097          	auipc	ra,0xffffc
    80005006:	b58080e7          	jalr	-1192(ra) # 80000b5a <initlock>
  lk->name = name;
    8000500a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000500e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80005012:	0204a423          	sw	zero,40(s1)
}
    80005016:	60e2                	ld	ra,24(sp)
    80005018:	6442                	ld	s0,16(sp)
    8000501a:	64a2                	ld	s1,8(sp)
    8000501c:	6902                	ld	s2,0(sp)
    8000501e:	6105                	addi	sp,sp,32
    80005020:	8082                	ret

0000000080005022 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80005022:	1101                	addi	sp,sp,-32
    80005024:	ec06                	sd	ra,24(sp)
    80005026:	e822                	sd	s0,16(sp)
    80005028:	e426                	sd	s1,8(sp)
    8000502a:	e04a                	sd	s2,0(sp)
    8000502c:	1000                	addi	s0,sp,32
    8000502e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80005030:	00850913          	addi	s2,a0,8
    80005034:	854a                	mv	a0,s2
    80005036:	ffffc097          	auipc	ra,0xffffc
    8000503a:	bb4080e7          	jalr	-1100(ra) # 80000bea <acquire>
  while (lk->locked) {
    8000503e:	409c                	lw	a5,0(s1)
    80005040:	cb89                	beqz	a5,80005052 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80005042:	85ca                	mv	a1,s2
    80005044:	8526                	mv	a0,s1
    80005046:	ffffd097          	auipc	ra,0xffffd
    8000504a:	410080e7          	jalr	1040(ra) # 80002456 <sleep>
  while (lk->locked) {
    8000504e:	409c                	lw	a5,0(s1)
    80005050:	fbed                	bnez	a5,80005042 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80005052:	4785                	li	a5,1
    80005054:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80005056:	ffffd097          	auipc	ra,0xffffd
    8000505a:	ba0080e7          	jalr	-1120(ra) # 80001bf6 <myproc>
    8000505e:	591c                	lw	a5,48(a0)
    80005060:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80005062:	854a                	mv	a0,s2
    80005064:	ffffc097          	auipc	ra,0xffffc
    80005068:	c3a080e7          	jalr	-966(ra) # 80000c9e <release>
}
    8000506c:	60e2                	ld	ra,24(sp)
    8000506e:	6442                	ld	s0,16(sp)
    80005070:	64a2                	ld	s1,8(sp)
    80005072:	6902                	ld	s2,0(sp)
    80005074:	6105                	addi	sp,sp,32
    80005076:	8082                	ret

0000000080005078 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80005078:	1101                	addi	sp,sp,-32
    8000507a:	ec06                	sd	ra,24(sp)
    8000507c:	e822                	sd	s0,16(sp)
    8000507e:	e426                	sd	s1,8(sp)
    80005080:	e04a                	sd	s2,0(sp)
    80005082:	1000                	addi	s0,sp,32
    80005084:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80005086:	00850913          	addi	s2,a0,8
    8000508a:	854a                	mv	a0,s2
    8000508c:	ffffc097          	auipc	ra,0xffffc
    80005090:	b5e080e7          	jalr	-1186(ra) # 80000bea <acquire>
  lk->locked = 0;
    80005094:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80005098:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000509c:	8526                	mv	a0,s1
    8000509e:	ffffd097          	auipc	ra,0xffffd
    800050a2:	568080e7          	jalr	1384(ra) # 80002606 <wakeup>
  release(&lk->lk);
    800050a6:	854a                	mv	a0,s2
    800050a8:	ffffc097          	auipc	ra,0xffffc
    800050ac:	bf6080e7          	jalr	-1034(ra) # 80000c9e <release>
}
    800050b0:	60e2                	ld	ra,24(sp)
    800050b2:	6442                	ld	s0,16(sp)
    800050b4:	64a2                	ld	s1,8(sp)
    800050b6:	6902                	ld	s2,0(sp)
    800050b8:	6105                	addi	sp,sp,32
    800050ba:	8082                	ret

00000000800050bc <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800050bc:	7179                	addi	sp,sp,-48
    800050be:	f406                	sd	ra,40(sp)
    800050c0:	f022                	sd	s0,32(sp)
    800050c2:	ec26                	sd	s1,24(sp)
    800050c4:	e84a                	sd	s2,16(sp)
    800050c6:	e44e                	sd	s3,8(sp)
    800050c8:	1800                	addi	s0,sp,48
    800050ca:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800050cc:	00850913          	addi	s2,a0,8
    800050d0:	854a                	mv	a0,s2
    800050d2:	ffffc097          	auipc	ra,0xffffc
    800050d6:	b18080e7          	jalr	-1256(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800050da:	409c                	lw	a5,0(s1)
    800050dc:	ef99                	bnez	a5,800050fa <holdingsleep+0x3e>
    800050de:	4481                	li	s1,0
  release(&lk->lk);
    800050e0:	854a                	mv	a0,s2
    800050e2:	ffffc097          	auipc	ra,0xffffc
    800050e6:	bbc080e7          	jalr	-1092(ra) # 80000c9e <release>
  return r;
}
    800050ea:	8526                	mv	a0,s1
    800050ec:	70a2                	ld	ra,40(sp)
    800050ee:	7402                	ld	s0,32(sp)
    800050f0:	64e2                	ld	s1,24(sp)
    800050f2:	6942                	ld	s2,16(sp)
    800050f4:	69a2                	ld	s3,8(sp)
    800050f6:	6145                	addi	sp,sp,48
    800050f8:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800050fa:	0284a983          	lw	s3,40(s1)
    800050fe:	ffffd097          	auipc	ra,0xffffd
    80005102:	af8080e7          	jalr	-1288(ra) # 80001bf6 <myproc>
    80005106:	5904                	lw	s1,48(a0)
    80005108:	413484b3          	sub	s1,s1,s3
    8000510c:	0014b493          	seqz	s1,s1
    80005110:	bfc1                	j	800050e0 <holdingsleep+0x24>

0000000080005112 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80005112:	1141                	addi	sp,sp,-16
    80005114:	e406                	sd	ra,8(sp)
    80005116:	e022                	sd	s0,0(sp)
    80005118:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000511a:	00004597          	auipc	a1,0x4
    8000511e:	73658593          	addi	a1,a1,1846 # 80009850 <syscalls+0x268>
    80005122:	0001f517          	auipc	a0,0x1f
    80005126:	07e50513          	addi	a0,a0,126 # 800241a0 <ftable>
    8000512a:	ffffc097          	auipc	ra,0xffffc
    8000512e:	a30080e7          	jalr	-1488(ra) # 80000b5a <initlock>
}
    80005132:	60a2                	ld	ra,8(sp)
    80005134:	6402                	ld	s0,0(sp)
    80005136:	0141                	addi	sp,sp,16
    80005138:	8082                	ret

000000008000513a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000513a:	1101                	addi	sp,sp,-32
    8000513c:	ec06                	sd	ra,24(sp)
    8000513e:	e822                	sd	s0,16(sp)
    80005140:	e426                	sd	s1,8(sp)
    80005142:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80005144:	0001f517          	auipc	a0,0x1f
    80005148:	05c50513          	addi	a0,a0,92 # 800241a0 <ftable>
    8000514c:	ffffc097          	auipc	ra,0xffffc
    80005150:	a9e080e7          	jalr	-1378(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005154:	0001f497          	auipc	s1,0x1f
    80005158:	06448493          	addi	s1,s1,100 # 800241b8 <ftable+0x18>
    8000515c:	00020717          	auipc	a4,0x20
    80005160:	ffc70713          	addi	a4,a4,-4 # 80025158 <disk>
    if(f->ref == 0){
    80005164:	40dc                	lw	a5,4(s1)
    80005166:	cf99                	beqz	a5,80005184 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005168:	02848493          	addi	s1,s1,40
    8000516c:	fee49ce3          	bne	s1,a4,80005164 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80005170:	0001f517          	auipc	a0,0x1f
    80005174:	03050513          	addi	a0,a0,48 # 800241a0 <ftable>
    80005178:	ffffc097          	auipc	ra,0xffffc
    8000517c:	b26080e7          	jalr	-1242(ra) # 80000c9e <release>
  return 0;
    80005180:	4481                	li	s1,0
    80005182:	a819                	j	80005198 <filealloc+0x5e>
      f->ref = 1;
    80005184:	4785                	li	a5,1
    80005186:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80005188:	0001f517          	auipc	a0,0x1f
    8000518c:	01850513          	addi	a0,a0,24 # 800241a0 <ftable>
    80005190:	ffffc097          	auipc	ra,0xffffc
    80005194:	b0e080e7          	jalr	-1266(ra) # 80000c9e <release>
}
    80005198:	8526                	mv	a0,s1
    8000519a:	60e2                	ld	ra,24(sp)
    8000519c:	6442                	ld	s0,16(sp)
    8000519e:	64a2                	ld	s1,8(sp)
    800051a0:	6105                	addi	sp,sp,32
    800051a2:	8082                	ret

00000000800051a4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800051a4:	1101                	addi	sp,sp,-32
    800051a6:	ec06                	sd	ra,24(sp)
    800051a8:	e822                	sd	s0,16(sp)
    800051aa:	e426                	sd	s1,8(sp)
    800051ac:	1000                	addi	s0,sp,32
    800051ae:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800051b0:	0001f517          	auipc	a0,0x1f
    800051b4:	ff050513          	addi	a0,a0,-16 # 800241a0 <ftable>
    800051b8:	ffffc097          	auipc	ra,0xffffc
    800051bc:	a32080e7          	jalr	-1486(ra) # 80000bea <acquire>
  if(f->ref < 1)
    800051c0:	40dc                	lw	a5,4(s1)
    800051c2:	02f05263          	blez	a5,800051e6 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800051c6:	2785                	addiw	a5,a5,1
    800051c8:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800051ca:	0001f517          	auipc	a0,0x1f
    800051ce:	fd650513          	addi	a0,a0,-42 # 800241a0 <ftable>
    800051d2:	ffffc097          	auipc	ra,0xffffc
    800051d6:	acc080e7          	jalr	-1332(ra) # 80000c9e <release>
  return f;
}
    800051da:	8526                	mv	a0,s1
    800051dc:	60e2                	ld	ra,24(sp)
    800051de:	6442                	ld	s0,16(sp)
    800051e0:	64a2                	ld	s1,8(sp)
    800051e2:	6105                	addi	sp,sp,32
    800051e4:	8082                	ret
    panic("filedup");
    800051e6:	00004517          	auipc	a0,0x4
    800051ea:	67250513          	addi	a0,a0,1650 # 80009858 <syscalls+0x270>
    800051ee:	ffffb097          	auipc	ra,0xffffb
    800051f2:	356080e7          	jalr	854(ra) # 80000544 <panic>

00000000800051f6 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800051f6:	7139                	addi	sp,sp,-64
    800051f8:	fc06                	sd	ra,56(sp)
    800051fa:	f822                	sd	s0,48(sp)
    800051fc:	f426                	sd	s1,40(sp)
    800051fe:	f04a                	sd	s2,32(sp)
    80005200:	ec4e                	sd	s3,24(sp)
    80005202:	e852                	sd	s4,16(sp)
    80005204:	e456                	sd	s5,8(sp)
    80005206:	0080                	addi	s0,sp,64
    80005208:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000520a:	0001f517          	auipc	a0,0x1f
    8000520e:	f9650513          	addi	a0,a0,-106 # 800241a0 <ftable>
    80005212:	ffffc097          	auipc	ra,0xffffc
    80005216:	9d8080e7          	jalr	-1576(ra) # 80000bea <acquire>
  if(f->ref < 1)
    8000521a:	40dc                	lw	a5,4(s1)
    8000521c:	06f05163          	blez	a5,8000527e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80005220:	37fd                	addiw	a5,a5,-1
    80005222:	0007871b          	sext.w	a4,a5
    80005226:	c0dc                	sw	a5,4(s1)
    80005228:	06e04363          	bgtz	a4,8000528e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000522c:	0004a903          	lw	s2,0(s1)
    80005230:	0094ca83          	lbu	s5,9(s1)
    80005234:	0104ba03          	ld	s4,16(s1)
    80005238:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000523c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80005240:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80005244:	0001f517          	auipc	a0,0x1f
    80005248:	f5c50513          	addi	a0,a0,-164 # 800241a0 <ftable>
    8000524c:	ffffc097          	auipc	ra,0xffffc
    80005250:	a52080e7          	jalr	-1454(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    80005254:	4785                	li	a5,1
    80005256:	04f90d63          	beq	s2,a5,800052b0 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000525a:	3979                	addiw	s2,s2,-2
    8000525c:	4785                	li	a5,1
    8000525e:	0527e063          	bltu	a5,s2,8000529e <fileclose+0xa8>
    begin_op();
    80005262:	00000097          	auipc	ra,0x0
    80005266:	ac8080e7          	jalr	-1336(ra) # 80004d2a <begin_op>
    iput(ff.ip);
    8000526a:	854e                	mv	a0,s3
    8000526c:	fffff097          	auipc	ra,0xfffff
    80005270:	2b6080e7          	jalr	694(ra) # 80004522 <iput>
    end_op();
    80005274:	00000097          	auipc	ra,0x0
    80005278:	b36080e7          	jalr	-1226(ra) # 80004daa <end_op>
    8000527c:	a00d                	j	8000529e <fileclose+0xa8>
    panic("fileclose");
    8000527e:	00004517          	auipc	a0,0x4
    80005282:	5e250513          	addi	a0,a0,1506 # 80009860 <syscalls+0x278>
    80005286:	ffffb097          	auipc	ra,0xffffb
    8000528a:	2be080e7          	jalr	702(ra) # 80000544 <panic>
    release(&ftable.lock);
    8000528e:	0001f517          	auipc	a0,0x1f
    80005292:	f1250513          	addi	a0,a0,-238 # 800241a0 <ftable>
    80005296:	ffffc097          	auipc	ra,0xffffc
    8000529a:	a08080e7          	jalr	-1528(ra) # 80000c9e <release>
  }
}
    8000529e:	70e2                	ld	ra,56(sp)
    800052a0:	7442                	ld	s0,48(sp)
    800052a2:	74a2                	ld	s1,40(sp)
    800052a4:	7902                	ld	s2,32(sp)
    800052a6:	69e2                	ld	s3,24(sp)
    800052a8:	6a42                	ld	s4,16(sp)
    800052aa:	6aa2                	ld	s5,8(sp)
    800052ac:	6121                	addi	sp,sp,64
    800052ae:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800052b0:	85d6                	mv	a1,s5
    800052b2:	8552                	mv	a0,s4
    800052b4:	00000097          	auipc	ra,0x0
    800052b8:	34c080e7          	jalr	844(ra) # 80005600 <pipeclose>
    800052bc:	b7cd                	j	8000529e <fileclose+0xa8>

00000000800052be <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800052be:	715d                	addi	sp,sp,-80
    800052c0:	e486                	sd	ra,72(sp)
    800052c2:	e0a2                	sd	s0,64(sp)
    800052c4:	fc26                	sd	s1,56(sp)
    800052c6:	f84a                	sd	s2,48(sp)
    800052c8:	f44e                	sd	s3,40(sp)
    800052ca:	0880                	addi	s0,sp,80
    800052cc:	84aa                	mv	s1,a0
    800052ce:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800052d0:	ffffd097          	auipc	ra,0xffffd
    800052d4:	926080e7          	jalr	-1754(ra) # 80001bf6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800052d8:	409c                	lw	a5,0(s1)
    800052da:	37f9                	addiw	a5,a5,-2
    800052dc:	4705                	li	a4,1
    800052de:	04f76763          	bltu	a4,a5,8000532c <filestat+0x6e>
    800052e2:	892a                	mv	s2,a0
    ilock(f->ip);
    800052e4:	6c88                	ld	a0,24(s1)
    800052e6:	fffff097          	auipc	ra,0xfffff
    800052ea:	082080e7          	jalr	130(ra) # 80004368 <ilock>
    stati(f->ip, &st);
    800052ee:	fb840593          	addi	a1,s0,-72
    800052f2:	6c88                	ld	a0,24(s1)
    800052f4:	fffff097          	auipc	ra,0xfffff
    800052f8:	2fe080e7          	jalr	766(ra) # 800045f2 <stati>
    iunlock(f->ip);
    800052fc:	6c88                	ld	a0,24(s1)
    800052fe:	fffff097          	auipc	ra,0xfffff
    80005302:	12c080e7          	jalr	300(ra) # 8000442a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80005306:	46e1                	li	a3,24
    80005308:	fb840613          	addi	a2,s0,-72
    8000530c:	85ce                	mv	a1,s3
    8000530e:	05093503          	ld	a0,80(s2)
    80005312:	ffffc097          	auipc	ra,0xffffc
    80005316:	372080e7          	jalr	882(ra) # 80001684 <copyout>
    8000531a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000531e:	60a6                	ld	ra,72(sp)
    80005320:	6406                	ld	s0,64(sp)
    80005322:	74e2                	ld	s1,56(sp)
    80005324:	7942                	ld	s2,48(sp)
    80005326:	79a2                	ld	s3,40(sp)
    80005328:	6161                	addi	sp,sp,80
    8000532a:	8082                	ret
  return -1;
    8000532c:	557d                	li	a0,-1
    8000532e:	bfc5                	j	8000531e <filestat+0x60>

0000000080005330 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80005330:	7179                	addi	sp,sp,-48
    80005332:	f406                	sd	ra,40(sp)
    80005334:	f022                	sd	s0,32(sp)
    80005336:	ec26                	sd	s1,24(sp)
    80005338:	e84a                	sd	s2,16(sp)
    8000533a:	e44e                	sd	s3,8(sp)
    8000533c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000533e:	00854783          	lbu	a5,8(a0)
    80005342:	c3d5                	beqz	a5,800053e6 <fileread+0xb6>
    80005344:	84aa                	mv	s1,a0
    80005346:	89ae                	mv	s3,a1
    80005348:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000534a:	411c                	lw	a5,0(a0)
    8000534c:	4705                	li	a4,1
    8000534e:	04e78963          	beq	a5,a4,800053a0 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005352:	470d                	li	a4,3
    80005354:	04e78d63          	beq	a5,a4,800053ae <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005358:	4709                	li	a4,2
    8000535a:	06e79e63          	bne	a5,a4,800053d6 <fileread+0xa6>
    ilock(f->ip);
    8000535e:	6d08                	ld	a0,24(a0)
    80005360:	fffff097          	auipc	ra,0xfffff
    80005364:	008080e7          	jalr	8(ra) # 80004368 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80005368:	874a                	mv	a4,s2
    8000536a:	5094                	lw	a3,32(s1)
    8000536c:	864e                	mv	a2,s3
    8000536e:	4585                	li	a1,1
    80005370:	6c88                	ld	a0,24(s1)
    80005372:	fffff097          	auipc	ra,0xfffff
    80005376:	2aa080e7          	jalr	682(ra) # 8000461c <readi>
    8000537a:	892a                	mv	s2,a0
    8000537c:	00a05563          	blez	a0,80005386 <fileread+0x56>
      f->off += r;
    80005380:	509c                	lw	a5,32(s1)
    80005382:	9fa9                	addw	a5,a5,a0
    80005384:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005386:	6c88                	ld	a0,24(s1)
    80005388:	fffff097          	auipc	ra,0xfffff
    8000538c:	0a2080e7          	jalr	162(ra) # 8000442a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005390:	854a                	mv	a0,s2
    80005392:	70a2                	ld	ra,40(sp)
    80005394:	7402                	ld	s0,32(sp)
    80005396:	64e2                	ld	s1,24(sp)
    80005398:	6942                	ld	s2,16(sp)
    8000539a:	69a2                	ld	s3,8(sp)
    8000539c:	6145                	addi	sp,sp,48
    8000539e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800053a0:	6908                	ld	a0,16(a0)
    800053a2:	00000097          	auipc	ra,0x0
    800053a6:	3ce080e7          	jalr	974(ra) # 80005770 <piperead>
    800053aa:	892a                	mv	s2,a0
    800053ac:	b7d5                	j	80005390 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800053ae:	02451783          	lh	a5,36(a0)
    800053b2:	03079693          	slli	a3,a5,0x30
    800053b6:	92c1                	srli	a3,a3,0x30
    800053b8:	4725                	li	a4,9
    800053ba:	02d76863          	bltu	a4,a3,800053ea <fileread+0xba>
    800053be:	0792                	slli	a5,a5,0x4
    800053c0:	0001f717          	auipc	a4,0x1f
    800053c4:	d4070713          	addi	a4,a4,-704 # 80024100 <devsw>
    800053c8:	97ba                	add	a5,a5,a4
    800053ca:	639c                	ld	a5,0(a5)
    800053cc:	c38d                	beqz	a5,800053ee <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800053ce:	4505                	li	a0,1
    800053d0:	9782                	jalr	a5
    800053d2:	892a                	mv	s2,a0
    800053d4:	bf75                	j	80005390 <fileread+0x60>
    panic("fileread");
    800053d6:	00004517          	auipc	a0,0x4
    800053da:	49a50513          	addi	a0,a0,1178 # 80009870 <syscalls+0x288>
    800053de:	ffffb097          	auipc	ra,0xffffb
    800053e2:	166080e7          	jalr	358(ra) # 80000544 <panic>
    return -1;
    800053e6:	597d                	li	s2,-1
    800053e8:	b765                	j	80005390 <fileread+0x60>
      return -1;
    800053ea:	597d                	li	s2,-1
    800053ec:	b755                	j	80005390 <fileread+0x60>
    800053ee:	597d                	li	s2,-1
    800053f0:	b745                	j	80005390 <fileread+0x60>

00000000800053f2 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800053f2:	715d                	addi	sp,sp,-80
    800053f4:	e486                	sd	ra,72(sp)
    800053f6:	e0a2                	sd	s0,64(sp)
    800053f8:	fc26                	sd	s1,56(sp)
    800053fa:	f84a                	sd	s2,48(sp)
    800053fc:	f44e                	sd	s3,40(sp)
    800053fe:	f052                	sd	s4,32(sp)
    80005400:	ec56                	sd	s5,24(sp)
    80005402:	e85a                	sd	s6,16(sp)
    80005404:	e45e                	sd	s7,8(sp)
    80005406:	e062                	sd	s8,0(sp)
    80005408:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000540a:	00954783          	lbu	a5,9(a0)
    8000540e:	10078663          	beqz	a5,8000551a <filewrite+0x128>
    80005412:	892a                	mv	s2,a0
    80005414:	8aae                	mv	s5,a1
    80005416:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005418:	411c                	lw	a5,0(a0)
    8000541a:	4705                	li	a4,1
    8000541c:	02e78263          	beq	a5,a4,80005440 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005420:	470d                	li	a4,3
    80005422:	02e78663          	beq	a5,a4,8000544e <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005426:	4709                	li	a4,2
    80005428:	0ee79163          	bne	a5,a4,8000550a <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000542c:	0ac05d63          	blez	a2,800054e6 <filewrite+0xf4>
    int i = 0;
    80005430:	4981                	li	s3,0
    80005432:	6b05                	lui	s6,0x1
    80005434:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005438:	6b85                	lui	s7,0x1
    8000543a:	c00b8b9b          	addiw	s7,s7,-1024
    8000543e:	a861                	j	800054d6 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005440:	6908                	ld	a0,16(a0)
    80005442:	00000097          	auipc	ra,0x0
    80005446:	22e080e7          	jalr	558(ra) # 80005670 <pipewrite>
    8000544a:	8a2a                	mv	s4,a0
    8000544c:	a045                	j	800054ec <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000544e:	02451783          	lh	a5,36(a0)
    80005452:	03079693          	slli	a3,a5,0x30
    80005456:	92c1                	srli	a3,a3,0x30
    80005458:	4725                	li	a4,9
    8000545a:	0cd76263          	bltu	a4,a3,8000551e <filewrite+0x12c>
    8000545e:	0792                	slli	a5,a5,0x4
    80005460:	0001f717          	auipc	a4,0x1f
    80005464:	ca070713          	addi	a4,a4,-864 # 80024100 <devsw>
    80005468:	97ba                	add	a5,a5,a4
    8000546a:	679c                	ld	a5,8(a5)
    8000546c:	cbdd                	beqz	a5,80005522 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000546e:	4505                	li	a0,1
    80005470:	9782                	jalr	a5
    80005472:	8a2a                	mv	s4,a0
    80005474:	a8a5                	j	800054ec <filewrite+0xfa>
    80005476:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000547a:	00000097          	auipc	ra,0x0
    8000547e:	8b0080e7          	jalr	-1872(ra) # 80004d2a <begin_op>
      ilock(f->ip);
    80005482:	01893503          	ld	a0,24(s2)
    80005486:	fffff097          	auipc	ra,0xfffff
    8000548a:	ee2080e7          	jalr	-286(ra) # 80004368 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000548e:	8762                	mv	a4,s8
    80005490:	02092683          	lw	a3,32(s2)
    80005494:	01598633          	add	a2,s3,s5
    80005498:	4585                	li	a1,1
    8000549a:	01893503          	ld	a0,24(s2)
    8000549e:	fffff097          	auipc	ra,0xfffff
    800054a2:	276080e7          	jalr	630(ra) # 80004714 <writei>
    800054a6:	84aa                	mv	s1,a0
    800054a8:	00a05763          	blez	a0,800054b6 <filewrite+0xc4>
        f->off += r;
    800054ac:	02092783          	lw	a5,32(s2)
    800054b0:	9fa9                	addw	a5,a5,a0
    800054b2:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800054b6:	01893503          	ld	a0,24(s2)
    800054ba:	fffff097          	auipc	ra,0xfffff
    800054be:	f70080e7          	jalr	-144(ra) # 8000442a <iunlock>
      end_op();
    800054c2:	00000097          	auipc	ra,0x0
    800054c6:	8e8080e7          	jalr	-1816(ra) # 80004daa <end_op>

      if(r != n1){
    800054ca:	009c1f63          	bne	s8,s1,800054e8 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800054ce:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800054d2:	0149db63          	bge	s3,s4,800054e8 <filewrite+0xf6>
      int n1 = n - i;
    800054d6:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800054da:	84be                	mv	s1,a5
    800054dc:	2781                	sext.w	a5,a5
    800054de:	f8fb5ce3          	bge	s6,a5,80005476 <filewrite+0x84>
    800054e2:	84de                	mv	s1,s7
    800054e4:	bf49                	j	80005476 <filewrite+0x84>
    int i = 0;
    800054e6:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800054e8:	013a1f63          	bne	s4,s3,80005506 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800054ec:	8552                	mv	a0,s4
    800054ee:	60a6                	ld	ra,72(sp)
    800054f0:	6406                	ld	s0,64(sp)
    800054f2:	74e2                	ld	s1,56(sp)
    800054f4:	7942                	ld	s2,48(sp)
    800054f6:	79a2                	ld	s3,40(sp)
    800054f8:	7a02                	ld	s4,32(sp)
    800054fa:	6ae2                	ld	s5,24(sp)
    800054fc:	6b42                	ld	s6,16(sp)
    800054fe:	6ba2                	ld	s7,8(sp)
    80005500:	6c02                	ld	s8,0(sp)
    80005502:	6161                	addi	sp,sp,80
    80005504:	8082                	ret
    ret = (i == n ? n : -1);
    80005506:	5a7d                	li	s4,-1
    80005508:	b7d5                	j	800054ec <filewrite+0xfa>
    panic("filewrite");
    8000550a:	00004517          	auipc	a0,0x4
    8000550e:	37650513          	addi	a0,a0,886 # 80009880 <syscalls+0x298>
    80005512:	ffffb097          	auipc	ra,0xffffb
    80005516:	032080e7          	jalr	50(ra) # 80000544 <panic>
    return -1;
    8000551a:	5a7d                	li	s4,-1
    8000551c:	bfc1                	j	800054ec <filewrite+0xfa>
      return -1;
    8000551e:	5a7d                	li	s4,-1
    80005520:	b7f1                	j	800054ec <filewrite+0xfa>
    80005522:	5a7d                	li	s4,-1
    80005524:	b7e1                	j	800054ec <filewrite+0xfa>

0000000080005526 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005526:	7179                	addi	sp,sp,-48
    80005528:	f406                	sd	ra,40(sp)
    8000552a:	f022                	sd	s0,32(sp)
    8000552c:	ec26                	sd	s1,24(sp)
    8000552e:	e84a                	sd	s2,16(sp)
    80005530:	e44e                	sd	s3,8(sp)
    80005532:	e052                	sd	s4,0(sp)
    80005534:	1800                	addi	s0,sp,48
    80005536:	84aa                	mv	s1,a0
    80005538:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000553a:	0005b023          	sd	zero,0(a1)
    8000553e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005542:	00000097          	auipc	ra,0x0
    80005546:	bf8080e7          	jalr	-1032(ra) # 8000513a <filealloc>
    8000554a:	e088                	sd	a0,0(s1)
    8000554c:	c551                	beqz	a0,800055d8 <pipealloc+0xb2>
    8000554e:	00000097          	auipc	ra,0x0
    80005552:	bec080e7          	jalr	-1044(ra) # 8000513a <filealloc>
    80005556:	00aa3023          	sd	a0,0(s4)
    8000555a:	c92d                	beqz	a0,800055cc <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000555c:	ffffb097          	auipc	ra,0xffffb
    80005560:	59e080e7          	jalr	1438(ra) # 80000afa <kalloc>
    80005564:	892a                	mv	s2,a0
    80005566:	c125                	beqz	a0,800055c6 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005568:	4985                	li	s3,1
    8000556a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000556e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005572:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005576:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000557a:	00004597          	auipc	a1,0x4
    8000557e:	f7658593          	addi	a1,a1,-138 # 800094f0 <states.1811+0x208>
    80005582:	ffffb097          	auipc	ra,0xffffb
    80005586:	5d8080e7          	jalr	1496(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    8000558a:	609c                	ld	a5,0(s1)
    8000558c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005590:	609c                	ld	a5,0(s1)
    80005592:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005596:	609c                	ld	a5,0(s1)
    80005598:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000559c:	609c                	ld	a5,0(s1)
    8000559e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800055a2:	000a3783          	ld	a5,0(s4)
    800055a6:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800055aa:	000a3783          	ld	a5,0(s4)
    800055ae:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800055b2:	000a3783          	ld	a5,0(s4)
    800055b6:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800055ba:	000a3783          	ld	a5,0(s4)
    800055be:	0127b823          	sd	s2,16(a5)
  return 0;
    800055c2:	4501                	li	a0,0
    800055c4:	a025                	j	800055ec <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800055c6:	6088                	ld	a0,0(s1)
    800055c8:	e501                	bnez	a0,800055d0 <pipealloc+0xaa>
    800055ca:	a039                	j	800055d8 <pipealloc+0xb2>
    800055cc:	6088                	ld	a0,0(s1)
    800055ce:	c51d                	beqz	a0,800055fc <pipealloc+0xd6>
    fileclose(*f0);
    800055d0:	00000097          	auipc	ra,0x0
    800055d4:	c26080e7          	jalr	-986(ra) # 800051f6 <fileclose>
  if(*f1)
    800055d8:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800055dc:	557d                	li	a0,-1
  if(*f1)
    800055de:	c799                	beqz	a5,800055ec <pipealloc+0xc6>
    fileclose(*f1);
    800055e0:	853e                	mv	a0,a5
    800055e2:	00000097          	auipc	ra,0x0
    800055e6:	c14080e7          	jalr	-1004(ra) # 800051f6 <fileclose>
  return -1;
    800055ea:	557d                	li	a0,-1
}
    800055ec:	70a2                	ld	ra,40(sp)
    800055ee:	7402                	ld	s0,32(sp)
    800055f0:	64e2                	ld	s1,24(sp)
    800055f2:	6942                	ld	s2,16(sp)
    800055f4:	69a2                	ld	s3,8(sp)
    800055f6:	6a02                	ld	s4,0(sp)
    800055f8:	6145                	addi	sp,sp,48
    800055fa:	8082                	ret
  return -1;
    800055fc:	557d                	li	a0,-1
    800055fe:	b7fd                	j	800055ec <pipealloc+0xc6>

0000000080005600 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005600:	1101                	addi	sp,sp,-32
    80005602:	ec06                	sd	ra,24(sp)
    80005604:	e822                	sd	s0,16(sp)
    80005606:	e426                	sd	s1,8(sp)
    80005608:	e04a                	sd	s2,0(sp)
    8000560a:	1000                	addi	s0,sp,32
    8000560c:	84aa                	mv	s1,a0
    8000560e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005610:	ffffb097          	auipc	ra,0xffffb
    80005614:	5da080e7          	jalr	1498(ra) # 80000bea <acquire>
  if(writable){
    80005618:	02090d63          	beqz	s2,80005652 <pipeclose+0x52>
    pi->writeopen = 0;
    8000561c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005620:	21848513          	addi	a0,s1,536
    80005624:	ffffd097          	auipc	ra,0xffffd
    80005628:	fe2080e7          	jalr	-30(ra) # 80002606 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000562c:	2204b783          	ld	a5,544(s1)
    80005630:	eb95                	bnez	a5,80005664 <pipeclose+0x64>
    release(&pi->lock);
    80005632:	8526                	mv	a0,s1
    80005634:	ffffb097          	auipc	ra,0xffffb
    80005638:	66a080e7          	jalr	1642(ra) # 80000c9e <release>
    kfree((char*)pi);
    8000563c:	8526                	mv	a0,s1
    8000563e:	ffffb097          	auipc	ra,0xffffb
    80005642:	3c0080e7          	jalr	960(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80005646:	60e2                	ld	ra,24(sp)
    80005648:	6442                	ld	s0,16(sp)
    8000564a:	64a2                	ld	s1,8(sp)
    8000564c:	6902                	ld	s2,0(sp)
    8000564e:	6105                	addi	sp,sp,32
    80005650:	8082                	ret
    pi->readopen = 0;
    80005652:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005656:	21c48513          	addi	a0,s1,540
    8000565a:	ffffd097          	auipc	ra,0xffffd
    8000565e:	fac080e7          	jalr	-84(ra) # 80002606 <wakeup>
    80005662:	b7e9                	j	8000562c <pipeclose+0x2c>
    release(&pi->lock);
    80005664:	8526                	mv	a0,s1
    80005666:	ffffb097          	auipc	ra,0xffffb
    8000566a:	638080e7          	jalr	1592(ra) # 80000c9e <release>
}
    8000566e:	bfe1                	j	80005646 <pipeclose+0x46>

0000000080005670 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005670:	7159                	addi	sp,sp,-112
    80005672:	f486                	sd	ra,104(sp)
    80005674:	f0a2                	sd	s0,96(sp)
    80005676:	eca6                	sd	s1,88(sp)
    80005678:	e8ca                	sd	s2,80(sp)
    8000567a:	e4ce                	sd	s3,72(sp)
    8000567c:	e0d2                	sd	s4,64(sp)
    8000567e:	fc56                	sd	s5,56(sp)
    80005680:	f85a                	sd	s6,48(sp)
    80005682:	f45e                	sd	s7,40(sp)
    80005684:	f062                	sd	s8,32(sp)
    80005686:	ec66                	sd	s9,24(sp)
    80005688:	1880                	addi	s0,sp,112
    8000568a:	84aa                	mv	s1,a0
    8000568c:	8aae                	mv	s5,a1
    8000568e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005690:	ffffc097          	auipc	ra,0xffffc
    80005694:	566080e7          	jalr	1382(ra) # 80001bf6 <myproc>
    80005698:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000569a:	8526                	mv	a0,s1
    8000569c:	ffffb097          	auipc	ra,0xffffb
    800056a0:	54e080e7          	jalr	1358(ra) # 80000bea <acquire>
  while(i < n){
    800056a4:	0d405463          	blez	s4,8000576c <pipewrite+0xfc>
    800056a8:	8ba6                	mv	s7,s1
  int i = 0;
    800056aa:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800056ac:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800056ae:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800056b2:	21c48c13          	addi	s8,s1,540
    800056b6:	a08d                	j	80005718 <pipewrite+0xa8>
      release(&pi->lock);
    800056b8:	8526                	mv	a0,s1
    800056ba:	ffffb097          	auipc	ra,0xffffb
    800056be:	5e4080e7          	jalr	1508(ra) # 80000c9e <release>
      return -1;
    800056c2:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800056c4:	854a                	mv	a0,s2
    800056c6:	70a6                	ld	ra,104(sp)
    800056c8:	7406                	ld	s0,96(sp)
    800056ca:	64e6                	ld	s1,88(sp)
    800056cc:	6946                	ld	s2,80(sp)
    800056ce:	69a6                	ld	s3,72(sp)
    800056d0:	6a06                	ld	s4,64(sp)
    800056d2:	7ae2                	ld	s5,56(sp)
    800056d4:	7b42                	ld	s6,48(sp)
    800056d6:	7ba2                	ld	s7,40(sp)
    800056d8:	7c02                	ld	s8,32(sp)
    800056da:	6ce2                	ld	s9,24(sp)
    800056dc:	6165                	addi	sp,sp,112
    800056de:	8082                	ret
      wakeup(&pi->nread);
    800056e0:	8566                	mv	a0,s9
    800056e2:	ffffd097          	auipc	ra,0xffffd
    800056e6:	f24080e7          	jalr	-220(ra) # 80002606 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800056ea:	85de                	mv	a1,s7
    800056ec:	8562                	mv	a0,s8
    800056ee:	ffffd097          	auipc	ra,0xffffd
    800056f2:	d68080e7          	jalr	-664(ra) # 80002456 <sleep>
    800056f6:	a839                	j	80005714 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800056f8:	21c4a783          	lw	a5,540(s1)
    800056fc:	0017871b          	addiw	a4,a5,1
    80005700:	20e4ae23          	sw	a4,540(s1)
    80005704:	1ff7f793          	andi	a5,a5,511
    80005708:	97a6                	add	a5,a5,s1
    8000570a:	f9f44703          	lbu	a4,-97(s0)
    8000570e:	00e78c23          	sb	a4,24(a5)
      i++;
    80005712:	2905                	addiw	s2,s2,1
  while(i < n){
    80005714:	05495063          	bge	s2,s4,80005754 <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80005718:	2204a783          	lw	a5,544(s1)
    8000571c:	dfd1                	beqz	a5,800056b8 <pipewrite+0x48>
    8000571e:	854e                	mv	a0,s3
    80005720:	ffffd097          	auipc	ra,0xffffd
    80005724:	136080e7          	jalr	310(ra) # 80002856 <killed>
    80005728:	f941                	bnez	a0,800056b8 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000572a:	2184a783          	lw	a5,536(s1)
    8000572e:	21c4a703          	lw	a4,540(s1)
    80005732:	2007879b          	addiw	a5,a5,512
    80005736:	faf705e3          	beq	a4,a5,800056e0 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000573a:	4685                	li	a3,1
    8000573c:	01590633          	add	a2,s2,s5
    80005740:	f9f40593          	addi	a1,s0,-97
    80005744:	0509b503          	ld	a0,80(s3)
    80005748:	ffffc097          	auipc	ra,0xffffc
    8000574c:	fc8080e7          	jalr	-56(ra) # 80001710 <copyin>
    80005750:	fb6514e3          	bne	a0,s6,800056f8 <pipewrite+0x88>
  wakeup(&pi->nread);
    80005754:	21848513          	addi	a0,s1,536
    80005758:	ffffd097          	auipc	ra,0xffffd
    8000575c:	eae080e7          	jalr	-338(ra) # 80002606 <wakeup>
  release(&pi->lock);
    80005760:	8526                	mv	a0,s1
    80005762:	ffffb097          	auipc	ra,0xffffb
    80005766:	53c080e7          	jalr	1340(ra) # 80000c9e <release>
  return i;
    8000576a:	bfa9                	j	800056c4 <pipewrite+0x54>
  int i = 0;
    8000576c:	4901                	li	s2,0
    8000576e:	b7dd                	j	80005754 <pipewrite+0xe4>

0000000080005770 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005770:	715d                	addi	sp,sp,-80
    80005772:	e486                	sd	ra,72(sp)
    80005774:	e0a2                	sd	s0,64(sp)
    80005776:	fc26                	sd	s1,56(sp)
    80005778:	f84a                	sd	s2,48(sp)
    8000577a:	f44e                	sd	s3,40(sp)
    8000577c:	f052                	sd	s4,32(sp)
    8000577e:	ec56                	sd	s5,24(sp)
    80005780:	e85a                	sd	s6,16(sp)
    80005782:	0880                	addi	s0,sp,80
    80005784:	84aa                	mv	s1,a0
    80005786:	892e                	mv	s2,a1
    80005788:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000578a:	ffffc097          	auipc	ra,0xffffc
    8000578e:	46c080e7          	jalr	1132(ra) # 80001bf6 <myproc>
    80005792:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005794:	8b26                	mv	s6,s1
    80005796:	8526                	mv	a0,s1
    80005798:	ffffb097          	auipc	ra,0xffffb
    8000579c:	452080e7          	jalr	1106(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800057a0:	2184a703          	lw	a4,536(s1)
    800057a4:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800057a8:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800057ac:	02f71763          	bne	a4,a5,800057da <piperead+0x6a>
    800057b0:	2244a783          	lw	a5,548(s1)
    800057b4:	c39d                	beqz	a5,800057da <piperead+0x6a>
    if(killed(pr)){
    800057b6:	8552                	mv	a0,s4
    800057b8:	ffffd097          	auipc	ra,0xffffd
    800057bc:	09e080e7          	jalr	158(ra) # 80002856 <killed>
    800057c0:	e941                	bnez	a0,80005850 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800057c2:	85da                	mv	a1,s6
    800057c4:	854e                	mv	a0,s3
    800057c6:	ffffd097          	auipc	ra,0xffffd
    800057ca:	c90080e7          	jalr	-880(ra) # 80002456 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800057ce:	2184a703          	lw	a4,536(s1)
    800057d2:	21c4a783          	lw	a5,540(s1)
    800057d6:	fcf70de3          	beq	a4,a5,800057b0 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800057da:	09505263          	blez	s5,8000585e <piperead+0xee>
    800057de:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800057e0:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800057e2:	2184a783          	lw	a5,536(s1)
    800057e6:	21c4a703          	lw	a4,540(s1)
    800057ea:	02f70d63          	beq	a4,a5,80005824 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800057ee:	0017871b          	addiw	a4,a5,1
    800057f2:	20e4ac23          	sw	a4,536(s1)
    800057f6:	1ff7f793          	andi	a5,a5,511
    800057fa:	97a6                	add	a5,a5,s1
    800057fc:	0187c783          	lbu	a5,24(a5)
    80005800:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005804:	4685                	li	a3,1
    80005806:	fbf40613          	addi	a2,s0,-65
    8000580a:	85ca                	mv	a1,s2
    8000580c:	050a3503          	ld	a0,80(s4)
    80005810:	ffffc097          	auipc	ra,0xffffc
    80005814:	e74080e7          	jalr	-396(ra) # 80001684 <copyout>
    80005818:	01650663          	beq	a0,s6,80005824 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000581c:	2985                	addiw	s3,s3,1
    8000581e:	0905                	addi	s2,s2,1
    80005820:	fd3a91e3          	bne	s5,s3,800057e2 <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005824:	21c48513          	addi	a0,s1,540
    80005828:	ffffd097          	auipc	ra,0xffffd
    8000582c:	dde080e7          	jalr	-546(ra) # 80002606 <wakeup>
  release(&pi->lock);
    80005830:	8526                	mv	a0,s1
    80005832:	ffffb097          	auipc	ra,0xffffb
    80005836:	46c080e7          	jalr	1132(ra) # 80000c9e <release>
  return i;
}
    8000583a:	854e                	mv	a0,s3
    8000583c:	60a6                	ld	ra,72(sp)
    8000583e:	6406                	ld	s0,64(sp)
    80005840:	74e2                	ld	s1,56(sp)
    80005842:	7942                	ld	s2,48(sp)
    80005844:	79a2                	ld	s3,40(sp)
    80005846:	7a02                	ld	s4,32(sp)
    80005848:	6ae2                	ld	s5,24(sp)
    8000584a:	6b42                	ld	s6,16(sp)
    8000584c:	6161                	addi	sp,sp,80
    8000584e:	8082                	ret
      release(&pi->lock);
    80005850:	8526                	mv	a0,s1
    80005852:	ffffb097          	auipc	ra,0xffffb
    80005856:	44c080e7          	jalr	1100(ra) # 80000c9e <release>
      return -1;
    8000585a:	59fd                	li	s3,-1
    8000585c:	bff9                	j	8000583a <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000585e:	4981                	li	s3,0
    80005860:	b7d1                	j	80005824 <piperead+0xb4>

0000000080005862 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005862:	1141                	addi	sp,sp,-16
    80005864:	e422                	sd	s0,8(sp)
    80005866:	0800                	addi	s0,sp,16
    80005868:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    8000586a:	8905                	andi	a0,a0,1
    8000586c:	c111                	beqz	a0,80005870 <flags2perm+0xe>
      perm = PTE_X;
    8000586e:	4521                	li	a0,8
    if(flags & 0x2)
    80005870:	8b89                	andi	a5,a5,2
    80005872:	c399                	beqz	a5,80005878 <flags2perm+0x16>
      perm |= PTE_W;
    80005874:	00456513          	ori	a0,a0,4
    return perm;
}
    80005878:	6422                	ld	s0,8(sp)
    8000587a:	0141                	addi	sp,sp,16
    8000587c:	8082                	ret

000000008000587e <exec>:

int
exec(char *path, char **argv)
{
    8000587e:	df010113          	addi	sp,sp,-528
    80005882:	20113423          	sd	ra,520(sp)
    80005886:	20813023          	sd	s0,512(sp)
    8000588a:	ffa6                	sd	s1,504(sp)
    8000588c:	fbca                	sd	s2,496(sp)
    8000588e:	f7ce                	sd	s3,488(sp)
    80005890:	f3d2                	sd	s4,480(sp)
    80005892:	efd6                	sd	s5,472(sp)
    80005894:	ebda                	sd	s6,464(sp)
    80005896:	e7de                	sd	s7,456(sp)
    80005898:	e3e2                	sd	s8,448(sp)
    8000589a:	ff66                	sd	s9,440(sp)
    8000589c:	fb6a                	sd	s10,432(sp)
    8000589e:	f76e                	sd	s11,424(sp)
    800058a0:	0c00                	addi	s0,sp,528
    800058a2:	84aa                	mv	s1,a0
    800058a4:	dea43c23          	sd	a0,-520(s0)
    800058a8:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800058ac:	ffffc097          	auipc	ra,0xffffc
    800058b0:	34a080e7          	jalr	842(ra) # 80001bf6 <myproc>
    800058b4:	892a                	mv	s2,a0

  begin_op();
    800058b6:	fffff097          	auipc	ra,0xfffff
    800058ba:	474080e7          	jalr	1140(ra) # 80004d2a <begin_op>

  if((ip = namei(path)) == 0){
    800058be:	8526                	mv	a0,s1
    800058c0:	fffff097          	auipc	ra,0xfffff
    800058c4:	24e080e7          	jalr	590(ra) # 80004b0e <namei>
    800058c8:	c92d                	beqz	a0,8000593a <exec+0xbc>
    800058ca:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800058cc:	fffff097          	auipc	ra,0xfffff
    800058d0:	a9c080e7          	jalr	-1380(ra) # 80004368 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800058d4:	04000713          	li	a4,64
    800058d8:	4681                	li	a3,0
    800058da:	e5040613          	addi	a2,s0,-432
    800058de:	4581                	li	a1,0
    800058e0:	8526                	mv	a0,s1
    800058e2:	fffff097          	auipc	ra,0xfffff
    800058e6:	d3a080e7          	jalr	-710(ra) # 8000461c <readi>
    800058ea:	04000793          	li	a5,64
    800058ee:	00f51a63          	bne	a0,a5,80005902 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800058f2:	e5042703          	lw	a4,-432(s0)
    800058f6:	464c47b7          	lui	a5,0x464c4
    800058fa:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800058fe:	04f70463          	beq	a4,a5,80005946 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005902:	8526                	mv	a0,s1
    80005904:	fffff097          	auipc	ra,0xfffff
    80005908:	cc6080e7          	jalr	-826(ra) # 800045ca <iunlockput>
    end_op();
    8000590c:	fffff097          	auipc	ra,0xfffff
    80005910:	49e080e7          	jalr	1182(ra) # 80004daa <end_op>
  }
  return -1;
    80005914:	557d                	li	a0,-1
}
    80005916:	20813083          	ld	ra,520(sp)
    8000591a:	20013403          	ld	s0,512(sp)
    8000591e:	74fe                	ld	s1,504(sp)
    80005920:	795e                	ld	s2,496(sp)
    80005922:	79be                	ld	s3,488(sp)
    80005924:	7a1e                	ld	s4,480(sp)
    80005926:	6afe                	ld	s5,472(sp)
    80005928:	6b5e                	ld	s6,464(sp)
    8000592a:	6bbe                	ld	s7,456(sp)
    8000592c:	6c1e                	ld	s8,448(sp)
    8000592e:	7cfa                	ld	s9,440(sp)
    80005930:	7d5a                	ld	s10,432(sp)
    80005932:	7dba                	ld	s11,424(sp)
    80005934:	21010113          	addi	sp,sp,528
    80005938:	8082                	ret
    end_op();
    8000593a:	fffff097          	auipc	ra,0xfffff
    8000593e:	470080e7          	jalr	1136(ra) # 80004daa <end_op>
    return -1;
    80005942:	557d                	li	a0,-1
    80005944:	bfc9                	j	80005916 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005946:	854a                	mv	a0,s2
    80005948:	ffffc097          	auipc	ra,0xffffc
    8000594c:	372080e7          	jalr	882(ra) # 80001cba <proc_pagetable>
    80005950:	8baa                	mv	s7,a0
    80005952:	d945                	beqz	a0,80005902 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005954:	e7042983          	lw	s3,-400(s0)
    80005958:	e8845783          	lhu	a5,-376(s0)
    8000595c:	c7ad                	beqz	a5,800059c6 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000595e:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005960:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80005962:	6c85                	lui	s9,0x1
    80005964:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005968:	def43823          	sd	a5,-528(s0)
    8000596c:	ac0d                	j	80005b9e <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000596e:	00004517          	auipc	a0,0x4
    80005972:	f2250513          	addi	a0,a0,-222 # 80009890 <syscalls+0x2a8>
    80005976:	ffffb097          	auipc	ra,0xffffb
    8000597a:	bce080e7          	jalr	-1074(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000597e:	8756                	mv	a4,s5
    80005980:	012d86bb          	addw	a3,s11,s2
    80005984:	4581                	li	a1,0
    80005986:	8526                	mv	a0,s1
    80005988:	fffff097          	auipc	ra,0xfffff
    8000598c:	c94080e7          	jalr	-876(ra) # 8000461c <readi>
    80005990:	2501                	sext.w	a0,a0
    80005992:	1aaa9a63          	bne	s5,a0,80005b46 <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    80005996:	6785                	lui	a5,0x1
    80005998:	0127893b          	addw	s2,a5,s2
    8000599c:	77fd                	lui	a5,0xfffff
    8000599e:	01478a3b          	addw	s4,a5,s4
    800059a2:	1f897563          	bgeu	s2,s8,80005b8c <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    800059a6:	02091593          	slli	a1,s2,0x20
    800059aa:	9181                	srli	a1,a1,0x20
    800059ac:	95ea                	add	a1,a1,s10
    800059ae:	855e                	mv	a0,s7
    800059b0:	ffffb097          	auipc	ra,0xffffb
    800059b4:	6c8080e7          	jalr	1736(ra) # 80001078 <walkaddr>
    800059b8:	862a                	mv	a2,a0
    if(pa == 0)
    800059ba:	d955                	beqz	a0,8000596e <exec+0xf0>
      n = PGSIZE;
    800059bc:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800059be:	fd9a70e3          	bgeu	s4,s9,8000597e <exec+0x100>
      n = sz - i;
    800059c2:	8ad2                	mv	s5,s4
    800059c4:	bf6d                	j	8000597e <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800059c6:	4a01                	li	s4,0
  iunlockput(ip);
    800059c8:	8526                	mv	a0,s1
    800059ca:	fffff097          	auipc	ra,0xfffff
    800059ce:	c00080e7          	jalr	-1024(ra) # 800045ca <iunlockput>
  end_op();
    800059d2:	fffff097          	auipc	ra,0xfffff
    800059d6:	3d8080e7          	jalr	984(ra) # 80004daa <end_op>
  p = myproc();
    800059da:	ffffc097          	auipc	ra,0xffffc
    800059de:	21c080e7          	jalr	540(ra) # 80001bf6 <myproc>
    800059e2:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800059e4:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800059e8:	6785                	lui	a5,0x1
    800059ea:	17fd                	addi	a5,a5,-1
    800059ec:	9a3e                	add	s4,s4,a5
    800059ee:	757d                	lui	a0,0xfffff
    800059f0:	00aa77b3          	and	a5,s4,a0
    800059f4:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800059f8:	4691                	li	a3,4
    800059fa:	6609                	lui	a2,0x2
    800059fc:	963e                	add	a2,a2,a5
    800059fe:	85be                	mv	a1,a5
    80005a00:	855e                	mv	a0,s7
    80005a02:	ffffc097          	auipc	ra,0xffffc
    80005a06:	a2a080e7          	jalr	-1494(ra) # 8000142c <uvmalloc>
    80005a0a:	8b2a                	mv	s6,a0
  ip = 0;
    80005a0c:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005a0e:	12050c63          	beqz	a0,80005b46 <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005a12:	75f9                	lui	a1,0xffffe
    80005a14:	95aa                	add	a1,a1,a0
    80005a16:	855e                	mv	a0,s7
    80005a18:	ffffc097          	auipc	ra,0xffffc
    80005a1c:	c3a080e7          	jalr	-966(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    80005a20:	7c7d                	lui	s8,0xfffff
    80005a22:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005a24:	e0043783          	ld	a5,-512(s0)
    80005a28:	6388                	ld	a0,0(a5)
    80005a2a:	c535                	beqz	a0,80005a96 <exec+0x218>
    80005a2c:	e9040993          	addi	s3,s0,-368
    80005a30:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005a34:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005a36:	ffffb097          	auipc	ra,0xffffb
    80005a3a:	434080e7          	jalr	1076(ra) # 80000e6a <strlen>
    80005a3e:	2505                	addiw	a0,a0,1
    80005a40:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005a44:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005a48:	13896663          	bltu	s2,s8,80005b74 <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005a4c:	e0043d83          	ld	s11,-512(s0)
    80005a50:	000dba03          	ld	s4,0(s11)
    80005a54:	8552                	mv	a0,s4
    80005a56:	ffffb097          	auipc	ra,0xffffb
    80005a5a:	414080e7          	jalr	1044(ra) # 80000e6a <strlen>
    80005a5e:	0015069b          	addiw	a3,a0,1
    80005a62:	8652                	mv	a2,s4
    80005a64:	85ca                	mv	a1,s2
    80005a66:	855e                	mv	a0,s7
    80005a68:	ffffc097          	auipc	ra,0xffffc
    80005a6c:	c1c080e7          	jalr	-996(ra) # 80001684 <copyout>
    80005a70:	10054663          	bltz	a0,80005b7c <exec+0x2fe>
    ustack[argc] = sp;
    80005a74:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005a78:	0485                	addi	s1,s1,1
    80005a7a:	008d8793          	addi	a5,s11,8
    80005a7e:	e0f43023          	sd	a5,-512(s0)
    80005a82:	008db503          	ld	a0,8(s11)
    80005a86:	c911                	beqz	a0,80005a9a <exec+0x21c>
    if(argc >= MAXARG)
    80005a88:	09a1                	addi	s3,s3,8
    80005a8a:	fb3c96e3          	bne	s9,s3,80005a36 <exec+0x1b8>
  sz = sz1;
    80005a8e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005a92:	4481                	li	s1,0
    80005a94:	a84d                	j	80005b46 <exec+0x2c8>
  sp = sz;
    80005a96:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005a98:	4481                	li	s1,0
  ustack[argc] = 0;
    80005a9a:	00349793          	slli	a5,s1,0x3
    80005a9e:	f9040713          	addi	a4,s0,-112
    80005aa2:	97ba                	add	a5,a5,a4
    80005aa4:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005aa8:	00148693          	addi	a3,s1,1
    80005aac:	068e                	slli	a3,a3,0x3
    80005aae:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005ab2:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005ab6:	01897663          	bgeu	s2,s8,80005ac2 <exec+0x244>
  sz = sz1;
    80005aba:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005abe:	4481                	li	s1,0
    80005ac0:	a059                	j	80005b46 <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005ac2:	e9040613          	addi	a2,s0,-368
    80005ac6:	85ca                	mv	a1,s2
    80005ac8:	855e                	mv	a0,s7
    80005aca:	ffffc097          	auipc	ra,0xffffc
    80005ace:	bba080e7          	jalr	-1094(ra) # 80001684 <copyout>
    80005ad2:	0a054963          	bltz	a0,80005b84 <exec+0x306>
  p->trapframe->a1 = sp;
    80005ad6:	058ab783          	ld	a5,88(s5)
    80005ada:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005ade:	df843783          	ld	a5,-520(s0)
    80005ae2:	0007c703          	lbu	a4,0(a5)
    80005ae6:	cf11                	beqz	a4,80005b02 <exec+0x284>
    80005ae8:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005aea:	02f00693          	li	a3,47
    80005aee:	a039                	j	80005afc <exec+0x27e>
      last = s+1;
    80005af0:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005af4:	0785                	addi	a5,a5,1
    80005af6:	fff7c703          	lbu	a4,-1(a5)
    80005afa:	c701                	beqz	a4,80005b02 <exec+0x284>
    if(*s == '/')
    80005afc:	fed71ce3          	bne	a4,a3,80005af4 <exec+0x276>
    80005b00:	bfc5                	j	80005af0 <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80005b02:	4641                	li	a2,16
    80005b04:	df843583          	ld	a1,-520(s0)
    80005b08:	158a8513          	addi	a0,s5,344
    80005b0c:	ffffb097          	auipc	ra,0xffffb
    80005b10:	32c080e7          	jalr	812(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    80005b14:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005b18:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005b1c:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005b20:	058ab783          	ld	a5,88(s5)
    80005b24:	e6843703          	ld	a4,-408(s0)
    80005b28:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005b2a:	058ab783          	ld	a5,88(s5)
    80005b2e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005b32:	85ea                	mv	a1,s10
    80005b34:	ffffc097          	auipc	ra,0xffffc
    80005b38:	222080e7          	jalr	546(ra) # 80001d56 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005b3c:	0004851b          	sext.w	a0,s1
    80005b40:	bbd9                	j	80005916 <exec+0x98>
    80005b42:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005b46:	e0843583          	ld	a1,-504(s0)
    80005b4a:	855e                	mv	a0,s7
    80005b4c:	ffffc097          	auipc	ra,0xffffc
    80005b50:	20a080e7          	jalr	522(ra) # 80001d56 <proc_freepagetable>
  if(ip){
    80005b54:	da0497e3          	bnez	s1,80005902 <exec+0x84>
  return -1;
    80005b58:	557d                	li	a0,-1
    80005b5a:	bb75                	j	80005916 <exec+0x98>
    80005b5c:	e1443423          	sd	s4,-504(s0)
    80005b60:	b7dd                	j	80005b46 <exec+0x2c8>
    80005b62:	e1443423          	sd	s4,-504(s0)
    80005b66:	b7c5                	j	80005b46 <exec+0x2c8>
    80005b68:	e1443423          	sd	s4,-504(s0)
    80005b6c:	bfe9                	j	80005b46 <exec+0x2c8>
    80005b6e:	e1443423          	sd	s4,-504(s0)
    80005b72:	bfd1                	j	80005b46 <exec+0x2c8>
  sz = sz1;
    80005b74:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005b78:	4481                	li	s1,0
    80005b7a:	b7f1                	j	80005b46 <exec+0x2c8>
  sz = sz1;
    80005b7c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005b80:	4481                	li	s1,0
    80005b82:	b7d1                	j	80005b46 <exec+0x2c8>
  sz = sz1;
    80005b84:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005b88:	4481                	li	s1,0
    80005b8a:	bf75                	j	80005b46 <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005b8c:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005b90:	2b05                	addiw	s6,s6,1
    80005b92:	0389899b          	addiw	s3,s3,56
    80005b96:	e8845783          	lhu	a5,-376(s0)
    80005b9a:	e2fb57e3          	bge	s6,a5,800059c8 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005b9e:	2981                	sext.w	s3,s3
    80005ba0:	03800713          	li	a4,56
    80005ba4:	86ce                	mv	a3,s3
    80005ba6:	e1840613          	addi	a2,s0,-488
    80005baa:	4581                	li	a1,0
    80005bac:	8526                	mv	a0,s1
    80005bae:	fffff097          	auipc	ra,0xfffff
    80005bb2:	a6e080e7          	jalr	-1426(ra) # 8000461c <readi>
    80005bb6:	03800793          	li	a5,56
    80005bba:	f8f514e3          	bne	a0,a5,80005b42 <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    80005bbe:	e1842783          	lw	a5,-488(s0)
    80005bc2:	4705                	li	a4,1
    80005bc4:	fce796e3          	bne	a5,a4,80005b90 <exec+0x312>
    if(ph.memsz < ph.filesz)
    80005bc8:	e4043903          	ld	s2,-448(s0)
    80005bcc:	e3843783          	ld	a5,-456(s0)
    80005bd0:	f8f966e3          	bltu	s2,a5,80005b5c <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005bd4:	e2843783          	ld	a5,-472(s0)
    80005bd8:	993e                	add	s2,s2,a5
    80005bda:	f8f964e3          	bltu	s2,a5,80005b62 <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    80005bde:	df043703          	ld	a4,-528(s0)
    80005be2:	8ff9                	and	a5,a5,a4
    80005be4:	f3d1                	bnez	a5,80005b68 <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005be6:	e1c42503          	lw	a0,-484(s0)
    80005bea:	00000097          	auipc	ra,0x0
    80005bee:	c78080e7          	jalr	-904(ra) # 80005862 <flags2perm>
    80005bf2:	86aa                	mv	a3,a0
    80005bf4:	864a                	mv	a2,s2
    80005bf6:	85d2                	mv	a1,s4
    80005bf8:	855e                	mv	a0,s7
    80005bfa:	ffffc097          	auipc	ra,0xffffc
    80005bfe:	832080e7          	jalr	-1998(ra) # 8000142c <uvmalloc>
    80005c02:	e0a43423          	sd	a0,-504(s0)
    80005c06:	d525                	beqz	a0,80005b6e <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005c08:	e2843d03          	ld	s10,-472(s0)
    80005c0c:	e2042d83          	lw	s11,-480(s0)
    80005c10:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005c14:	f60c0ce3          	beqz	s8,80005b8c <exec+0x30e>
    80005c18:	8a62                	mv	s4,s8
    80005c1a:	4901                	li	s2,0
    80005c1c:	b369                	j	800059a6 <exec+0x128>

0000000080005c1e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005c1e:	7179                	addi	sp,sp,-48
    80005c20:	f406                	sd	ra,40(sp)
    80005c22:	f022                	sd	s0,32(sp)
    80005c24:	ec26                	sd	s1,24(sp)
    80005c26:	e84a                	sd	s2,16(sp)
    80005c28:	1800                	addi	s0,sp,48
    80005c2a:	892e                	mv	s2,a1
    80005c2c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005c2e:	fdc40593          	addi	a1,s0,-36
    80005c32:	ffffd097          	auipc	ra,0xffffd
    80005c36:	5b2080e7          	jalr	1458(ra) # 800031e4 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005c3a:	fdc42703          	lw	a4,-36(s0)
    80005c3e:	47bd                	li	a5,15
    80005c40:	02e7eb63          	bltu	a5,a4,80005c76 <argfd+0x58>
    80005c44:	ffffc097          	auipc	ra,0xffffc
    80005c48:	fb2080e7          	jalr	-78(ra) # 80001bf6 <myproc>
    80005c4c:	fdc42703          	lw	a4,-36(s0)
    80005c50:	01a70793          	addi	a5,a4,26
    80005c54:	078e                	slli	a5,a5,0x3
    80005c56:	953e                	add	a0,a0,a5
    80005c58:	611c                	ld	a5,0(a0)
    80005c5a:	c385                	beqz	a5,80005c7a <argfd+0x5c>
    return -1;
  if(pfd)
    80005c5c:	00090463          	beqz	s2,80005c64 <argfd+0x46>
    *pfd = fd;
    80005c60:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005c64:	4501                	li	a0,0
  if(pf)
    80005c66:	c091                	beqz	s1,80005c6a <argfd+0x4c>
    *pf = f;
    80005c68:	e09c                	sd	a5,0(s1)
}
    80005c6a:	70a2                	ld	ra,40(sp)
    80005c6c:	7402                	ld	s0,32(sp)
    80005c6e:	64e2                	ld	s1,24(sp)
    80005c70:	6942                	ld	s2,16(sp)
    80005c72:	6145                	addi	sp,sp,48
    80005c74:	8082                	ret
    return -1;
    80005c76:	557d                	li	a0,-1
    80005c78:	bfcd                	j	80005c6a <argfd+0x4c>
    80005c7a:	557d                	li	a0,-1
    80005c7c:	b7fd                	j	80005c6a <argfd+0x4c>

0000000080005c7e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005c7e:	1101                	addi	sp,sp,-32
    80005c80:	ec06                	sd	ra,24(sp)
    80005c82:	e822                	sd	s0,16(sp)
    80005c84:	e426                	sd	s1,8(sp)
    80005c86:	1000                	addi	s0,sp,32
    80005c88:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005c8a:	ffffc097          	auipc	ra,0xffffc
    80005c8e:	f6c080e7          	jalr	-148(ra) # 80001bf6 <myproc>
    80005c92:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005c94:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd8ab8>
    80005c98:	4501                	li	a0,0
    80005c9a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005c9c:	6398                	ld	a4,0(a5)
    80005c9e:	cb19                	beqz	a4,80005cb4 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005ca0:	2505                	addiw	a0,a0,1
    80005ca2:	07a1                	addi	a5,a5,8
    80005ca4:	fed51ce3          	bne	a0,a3,80005c9c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005ca8:	557d                	li	a0,-1
}
    80005caa:	60e2                	ld	ra,24(sp)
    80005cac:	6442                	ld	s0,16(sp)
    80005cae:	64a2                	ld	s1,8(sp)
    80005cb0:	6105                	addi	sp,sp,32
    80005cb2:	8082                	ret
      p->ofile[fd] = f;
    80005cb4:	01a50793          	addi	a5,a0,26
    80005cb8:	078e                	slli	a5,a5,0x3
    80005cba:	963e                	add	a2,a2,a5
    80005cbc:	e204                	sd	s1,0(a2)
      return fd;
    80005cbe:	b7f5                	j	80005caa <fdalloc+0x2c>

0000000080005cc0 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005cc0:	715d                	addi	sp,sp,-80
    80005cc2:	e486                	sd	ra,72(sp)
    80005cc4:	e0a2                	sd	s0,64(sp)
    80005cc6:	fc26                	sd	s1,56(sp)
    80005cc8:	f84a                	sd	s2,48(sp)
    80005cca:	f44e                	sd	s3,40(sp)
    80005ccc:	f052                	sd	s4,32(sp)
    80005cce:	ec56                	sd	s5,24(sp)
    80005cd0:	e85a                	sd	s6,16(sp)
    80005cd2:	0880                	addi	s0,sp,80
    80005cd4:	8b2e                	mv	s6,a1
    80005cd6:	89b2                	mv	s3,a2
    80005cd8:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005cda:	fb040593          	addi	a1,s0,-80
    80005cde:	fffff097          	auipc	ra,0xfffff
    80005ce2:	e4e080e7          	jalr	-434(ra) # 80004b2c <nameiparent>
    80005ce6:	84aa                	mv	s1,a0
    80005ce8:	16050063          	beqz	a0,80005e48 <create+0x188>
    return 0;

  ilock(dp);
    80005cec:	ffffe097          	auipc	ra,0xffffe
    80005cf0:	67c080e7          	jalr	1660(ra) # 80004368 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005cf4:	4601                	li	a2,0
    80005cf6:	fb040593          	addi	a1,s0,-80
    80005cfa:	8526                	mv	a0,s1
    80005cfc:	fffff097          	auipc	ra,0xfffff
    80005d00:	b50080e7          	jalr	-1200(ra) # 8000484c <dirlookup>
    80005d04:	8aaa                	mv	s5,a0
    80005d06:	c931                	beqz	a0,80005d5a <create+0x9a>
    iunlockput(dp);
    80005d08:	8526                	mv	a0,s1
    80005d0a:	fffff097          	auipc	ra,0xfffff
    80005d0e:	8c0080e7          	jalr	-1856(ra) # 800045ca <iunlockput>
    ilock(ip);
    80005d12:	8556                	mv	a0,s5
    80005d14:	ffffe097          	auipc	ra,0xffffe
    80005d18:	654080e7          	jalr	1620(ra) # 80004368 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005d1c:	000b059b          	sext.w	a1,s6
    80005d20:	4789                	li	a5,2
    80005d22:	02f59563          	bne	a1,a5,80005d4c <create+0x8c>
    80005d26:	044ad783          	lhu	a5,68(s5)
    80005d2a:	37f9                	addiw	a5,a5,-2
    80005d2c:	17c2                	slli	a5,a5,0x30
    80005d2e:	93c1                	srli	a5,a5,0x30
    80005d30:	4705                	li	a4,1
    80005d32:	00f76d63          	bltu	a4,a5,80005d4c <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005d36:	8556                	mv	a0,s5
    80005d38:	60a6                	ld	ra,72(sp)
    80005d3a:	6406                	ld	s0,64(sp)
    80005d3c:	74e2                	ld	s1,56(sp)
    80005d3e:	7942                	ld	s2,48(sp)
    80005d40:	79a2                	ld	s3,40(sp)
    80005d42:	7a02                	ld	s4,32(sp)
    80005d44:	6ae2                	ld	s5,24(sp)
    80005d46:	6b42                	ld	s6,16(sp)
    80005d48:	6161                	addi	sp,sp,80
    80005d4a:	8082                	ret
    iunlockput(ip);
    80005d4c:	8556                	mv	a0,s5
    80005d4e:	fffff097          	auipc	ra,0xfffff
    80005d52:	87c080e7          	jalr	-1924(ra) # 800045ca <iunlockput>
    return 0;
    80005d56:	4a81                	li	s5,0
    80005d58:	bff9                	j	80005d36 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005d5a:	85da                	mv	a1,s6
    80005d5c:	4088                	lw	a0,0(s1)
    80005d5e:	ffffe097          	auipc	ra,0xffffe
    80005d62:	46e080e7          	jalr	1134(ra) # 800041cc <ialloc>
    80005d66:	8a2a                	mv	s4,a0
    80005d68:	c921                	beqz	a0,80005db8 <create+0xf8>
  ilock(ip);
    80005d6a:	ffffe097          	auipc	ra,0xffffe
    80005d6e:	5fe080e7          	jalr	1534(ra) # 80004368 <ilock>
  ip->major = major;
    80005d72:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005d76:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005d7a:	4785                	li	a5,1
    80005d7c:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    80005d80:	8552                	mv	a0,s4
    80005d82:	ffffe097          	auipc	ra,0xffffe
    80005d86:	51c080e7          	jalr	1308(ra) # 8000429e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005d8a:	000b059b          	sext.w	a1,s6
    80005d8e:	4785                	li	a5,1
    80005d90:	02f58b63          	beq	a1,a5,80005dc6 <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    80005d94:	004a2603          	lw	a2,4(s4)
    80005d98:	fb040593          	addi	a1,s0,-80
    80005d9c:	8526                	mv	a0,s1
    80005d9e:	fffff097          	auipc	ra,0xfffff
    80005da2:	cbe080e7          	jalr	-834(ra) # 80004a5c <dirlink>
    80005da6:	06054f63          	bltz	a0,80005e24 <create+0x164>
  iunlockput(dp);
    80005daa:	8526                	mv	a0,s1
    80005dac:	fffff097          	auipc	ra,0xfffff
    80005db0:	81e080e7          	jalr	-2018(ra) # 800045ca <iunlockput>
  return ip;
    80005db4:	8ad2                	mv	s5,s4
    80005db6:	b741                	j	80005d36 <create+0x76>
    iunlockput(dp);
    80005db8:	8526                	mv	a0,s1
    80005dba:	fffff097          	auipc	ra,0xfffff
    80005dbe:	810080e7          	jalr	-2032(ra) # 800045ca <iunlockput>
    return 0;
    80005dc2:	8ad2                	mv	s5,s4
    80005dc4:	bf8d                	j	80005d36 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005dc6:	004a2603          	lw	a2,4(s4)
    80005dca:	00004597          	auipc	a1,0x4
    80005dce:	ae658593          	addi	a1,a1,-1306 # 800098b0 <syscalls+0x2c8>
    80005dd2:	8552                	mv	a0,s4
    80005dd4:	fffff097          	auipc	ra,0xfffff
    80005dd8:	c88080e7          	jalr	-888(ra) # 80004a5c <dirlink>
    80005ddc:	04054463          	bltz	a0,80005e24 <create+0x164>
    80005de0:	40d0                	lw	a2,4(s1)
    80005de2:	00004597          	auipc	a1,0x4
    80005de6:	ad658593          	addi	a1,a1,-1322 # 800098b8 <syscalls+0x2d0>
    80005dea:	8552                	mv	a0,s4
    80005dec:	fffff097          	auipc	ra,0xfffff
    80005df0:	c70080e7          	jalr	-912(ra) # 80004a5c <dirlink>
    80005df4:	02054863          	bltz	a0,80005e24 <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    80005df8:	004a2603          	lw	a2,4(s4)
    80005dfc:	fb040593          	addi	a1,s0,-80
    80005e00:	8526                	mv	a0,s1
    80005e02:	fffff097          	auipc	ra,0xfffff
    80005e06:	c5a080e7          	jalr	-934(ra) # 80004a5c <dirlink>
    80005e0a:	00054d63          	bltz	a0,80005e24 <create+0x164>
    dp->nlink++;  // for ".."
    80005e0e:	04a4d783          	lhu	a5,74(s1)
    80005e12:	2785                	addiw	a5,a5,1
    80005e14:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005e18:	8526                	mv	a0,s1
    80005e1a:	ffffe097          	auipc	ra,0xffffe
    80005e1e:	484080e7          	jalr	1156(ra) # 8000429e <iupdate>
    80005e22:	b761                	j	80005daa <create+0xea>
  ip->nlink = 0;
    80005e24:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005e28:	8552                	mv	a0,s4
    80005e2a:	ffffe097          	auipc	ra,0xffffe
    80005e2e:	474080e7          	jalr	1140(ra) # 8000429e <iupdate>
  iunlockput(ip);
    80005e32:	8552                	mv	a0,s4
    80005e34:	ffffe097          	auipc	ra,0xffffe
    80005e38:	796080e7          	jalr	1942(ra) # 800045ca <iunlockput>
  iunlockput(dp);
    80005e3c:	8526                	mv	a0,s1
    80005e3e:	ffffe097          	auipc	ra,0xffffe
    80005e42:	78c080e7          	jalr	1932(ra) # 800045ca <iunlockput>
  return 0;
    80005e46:	bdc5                	j	80005d36 <create+0x76>
    return 0;
    80005e48:	8aaa                	mv	s5,a0
    80005e4a:	b5f5                	j	80005d36 <create+0x76>

0000000080005e4c <sys_dup>:
{
    80005e4c:	7179                	addi	sp,sp,-48
    80005e4e:	f406                	sd	ra,40(sp)
    80005e50:	f022                	sd	s0,32(sp)
    80005e52:	ec26                	sd	s1,24(sp)
    80005e54:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005e56:	fd840613          	addi	a2,s0,-40
    80005e5a:	4581                	li	a1,0
    80005e5c:	4501                	li	a0,0
    80005e5e:	00000097          	auipc	ra,0x0
    80005e62:	dc0080e7          	jalr	-576(ra) # 80005c1e <argfd>
    return -1;
    80005e66:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005e68:	02054363          	bltz	a0,80005e8e <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005e6c:	fd843503          	ld	a0,-40(s0)
    80005e70:	00000097          	auipc	ra,0x0
    80005e74:	e0e080e7          	jalr	-498(ra) # 80005c7e <fdalloc>
    80005e78:	84aa                	mv	s1,a0
    return -1;
    80005e7a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005e7c:	00054963          	bltz	a0,80005e8e <sys_dup+0x42>
  filedup(f);
    80005e80:	fd843503          	ld	a0,-40(s0)
    80005e84:	fffff097          	auipc	ra,0xfffff
    80005e88:	320080e7          	jalr	800(ra) # 800051a4 <filedup>
  return fd;
    80005e8c:	87a6                	mv	a5,s1
}
    80005e8e:	853e                	mv	a0,a5
    80005e90:	70a2                	ld	ra,40(sp)
    80005e92:	7402                	ld	s0,32(sp)
    80005e94:	64e2                	ld	s1,24(sp)
    80005e96:	6145                	addi	sp,sp,48
    80005e98:	8082                	ret

0000000080005e9a <sys_read>:
{
    80005e9a:	7179                	addi	sp,sp,-48
    80005e9c:	f406                	sd	ra,40(sp)
    80005e9e:	f022                	sd	s0,32(sp)
    80005ea0:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005ea2:	fd840593          	addi	a1,s0,-40
    80005ea6:	4505                	li	a0,1
    80005ea8:	ffffd097          	auipc	ra,0xffffd
    80005eac:	35c080e7          	jalr	860(ra) # 80003204 <argaddr>
  argint(2, &n);
    80005eb0:	fe440593          	addi	a1,s0,-28
    80005eb4:	4509                	li	a0,2
    80005eb6:	ffffd097          	auipc	ra,0xffffd
    80005eba:	32e080e7          	jalr	814(ra) # 800031e4 <argint>
  if(argfd(0, 0, &f) < 0)
    80005ebe:	fe840613          	addi	a2,s0,-24
    80005ec2:	4581                	li	a1,0
    80005ec4:	4501                	li	a0,0
    80005ec6:	00000097          	auipc	ra,0x0
    80005eca:	d58080e7          	jalr	-680(ra) # 80005c1e <argfd>
    80005ece:	87aa                	mv	a5,a0
    return -1;
    80005ed0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005ed2:	0007cc63          	bltz	a5,80005eea <sys_read+0x50>
  return fileread(f, p, n);
    80005ed6:	fe442603          	lw	a2,-28(s0)
    80005eda:	fd843583          	ld	a1,-40(s0)
    80005ede:	fe843503          	ld	a0,-24(s0)
    80005ee2:	fffff097          	auipc	ra,0xfffff
    80005ee6:	44e080e7          	jalr	1102(ra) # 80005330 <fileread>
}
    80005eea:	70a2                	ld	ra,40(sp)
    80005eec:	7402                	ld	s0,32(sp)
    80005eee:	6145                	addi	sp,sp,48
    80005ef0:	8082                	ret

0000000080005ef2 <sys_write>:
{
    80005ef2:	7179                	addi	sp,sp,-48
    80005ef4:	f406                	sd	ra,40(sp)
    80005ef6:	f022                	sd	s0,32(sp)
    80005ef8:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005efa:	fd840593          	addi	a1,s0,-40
    80005efe:	4505                	li	a0,1
    80005f00:	ffffd097          	auipc	ra,0xffffd
    80005f04:	304080e7          	jalr	772(ra) # 80003204 <argaddr>
  argint(2, &n);
    80005f08:	fe440593          	addi	a1,s0,-28
    80005f0c:	4509                	li	a0,2
    80005f0e:	ffffd097          	auipc	ra,0xffffd
    80005f12:	2d6080e7          	jalr	726(ra) # 800031e4 <argint>
  if(argfd(0, 0, &f) < 0)
    80005f16:	fe840613          	addi	a2,s0,-24
    80005f1a:	4581                	li	a1,0
    80005f1c:	4501                	li	a0,0
    80005f1e:	00000097          	auipc	ra,0x0
    80005f22:	d00080e7          	jalr	-768(ra) # 80005c1e <argfd>
    80005f26:	87aa                	mv	a5,a0
    return -1;
    80005f28:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005f2a:	0007cc63          	bltz	a5,80005f42 <sys_write+0x50>
  return filewrite(f, p, n);
    80005f2e:	fe442603          	lw	a2,-28(s0)
    80005f32:	fd843583          	ld	a1,-40(s0)
    80005f36:	fe843503          	ld	a0,-24(s0)
    80005f3a:	fffff097          	auipc	ra,0xfffff
    80005f3e:	4b8080e7          	jalr	1208(ra) # 800053f2 <filewrite>
}
    80005f42:	70a2                	ld	ra,40(sp)
    80005f44:	7402                	ld	s0,32(sp)
    80005f46:	6145                	addi	sp,sp,48
    80005f48:	8082                	ret

0000000080005f4a <sys_close>:
{
    80005f4a:	1101                	addi	sp,sp,-32
    80005f4c:	ec06                	sd	ra,24(sp)
    80005f4e:	e822                	sd	s0,16(sp)
    80005f50:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005f52:	fe040613          	addi	a2,s0,-32
    80005f56:	fec40593          	addi	a1,s0,-20
    80005f5a:	4501                	li	a0,0
    80005f5c:	00000097          	auipc	ra,0x0
    80005f60:	cc2080e7          	jalr	-830(ra) # 80005c1e <argfd>
    return -1;
    80005f64:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005f66:	02054463          	bltz	a0,80005f8e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005f6a:	ffffc097          	auipc	ra,0xffffc
    80005f6e:	c8c080e7          	jalr	-884(ra) # 80001bf6 <myproc>
    80005f72:	fec42783          	lw	a5,-20(s0)
    80005f76:	07e9                	addi	a5,a5,26
    80005f78:	078e                	slli	a5,a5,0x3
    80005f7a:	97aa                	add	a5,a5,a0
    80005f7c:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005f80:	fe043503          	ld	a0,-32(s0)
    80005f84:	fffff097          	auipc	ra,0xfffff
    80005f88:	272080e7          	jalr	626(ra) # 800051f6 <fileclose>
  return 0;
    80005f8c:	4781                	li	a5,0
}
    80005f8e:	853e                	mv	a0,a5
    80005f90:	60e2                	ld	ra,24(sp)
    80005f92:	6442                	ld	s0,16(sp)
    80005f94:	6105                	addi	sp,sp,32
    80005f96:	8082                	ret

0000000080005f98 <sys_fstat>:
{
    80005f98:	1101                	addi	sp,sp,-32
    80005f9a:	ec06                	sd	ra,24(sp)
    80005f9c:	e822                	sd	s0,16(sp)
    80005f9e:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005fa0:	fe040593          	addi	a1,s0,-32
    80005fa4:	4505                	li	a0,1
    80005fa6:	ffffd097          	auipc	ra,0xffffd
    80005faa:	25e080e7          	jalr	606(ra) # 80003204 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005fae:	fe840613          	addi	a2,s0,-24
    80005fb2:	4581                	li	a1,0
    80005fb4:	4501                	li	a0,0
    80005fb6:	00000097          	auipc	ra,0x0
    80005fba:	c68080e7          	jalr	-920(ra) # 80005c1e <argfd>
    80005fbe:	87aa                	mv	a5,a0
    return -1;
    80005fc0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005fc2:	0007ca63          	bltz	a5,80005fd6 <sys_fstat+0x3e>
  return filestat(f, st);
    80005fc6:	fe043583          	ld	a1,-32(s0)
    80005fca:	fe843503          	ld	a0,-24(s0)
    80005fce:	fffff097          	auipc	ra,0xfffff
    80005fd2:	2f0080e7          	jalr	752(ra) # 800052be <filestat>
}
    80005fd6:	60e2                	ld	ra,24(sp)
    80005fd8:	6442                	ld	s0,16(sp)
    80005fda:	6105                	addi	sp,sp,32
    80005fdc:	8082                	ret

0000000080005fde <sys_link>:
{
    80005fde:	7169                	addi	sp,sp,-304
    80005fe0:	f606                	sd	ra,296(sp)
    80005fe2:	f222                	sd	s0,288(sp)
    80005fe4:	ee26                	sd	s1,280(sp)
    80005fe6:	ea4a                	sd	s2,272(sp)
    80005fe8:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005fea:	08000613          	li	a2,128
    80005fee:	ed040593          	addi	a1,s0,-304
    80005ff2:	4501                	li	a0,0
    80005ff4:	ffffd097          	auipc	ra,0xffffd
    80005ff8:	230080e7          	jalr	560(ra) # 80003224 <argstr>
    return -1;
    80005ffc:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ffe:	10054e63          	bltz	a0,8000611a <sys_link+0x13c>
    80006002:	08000613          	li	a2,128
    80006006:	f5040593          	addi	a1,s0,-176
    8000600a:	4505                	li	a0,1
    8000600c:	ffffd097          	auipc	ra,0xffffd
    80006010:	218080e7          	jalr	536(ra) # 80003224 <argstr>
    return -1;
    80006014:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006016:	10054263          	bltz	a0,8000611a <sys_link+0x13c>
  begin_op();
    8000601a:	fffff097          	auipc	ra,0xfffff
    8000601e:	d10080e7          	jalr	-752(ra) # 80004d2a <begin_op>
  if((ip = namei(old)) == 0){
    80006022:	ed040513          	addi	a0,s0,-304
    80006026:	fffff097          	auipc	ra,0xfffff
    8000602a:	ae8080e7          	jalr	-1304(ra) # 80004b0e <namei>
    8000602e:	84aa                	mv	s1,a0
    80006030:	c551                	beqz	a0,800060bc <sys_link+0xde>
  ilock(ip);
    80006032:	ffffe097          	auipc	ra,0xffffe
    80006036:	336080e7          	jalr	822(ra) # 80004368 <ilock>
  if(ip->type == T_DIR){
    8000603a:	04449703          	lh	a4,68(s1)
    8000603e:	4785                	li	a5,1
    80006040:	08f70463          	beq	a4,a5,800060c8 <sys_link+0xea>
  ip->nlink++;
    80006044:	04a4d783          	lhu	a5,74(s1)
    80006048:	2785                	addiw	a5,a5,1
    8000604a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000604e:	8526                	mv	a0,s1
    80006050:	ffffe097          	auipc	ra,0xffffe
    80006054:	24e080e7          	jalr	590(ra) # 8000429e <iupdate>
  iunlock(ip);
    80006058:	8526                	mv	a0,s1
    8000605a:	ffffe097          	auipc	ra,0xffffe
    8000605e:	3d0080e7          	jalr	976(ra) # 8000442a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80006062:	fd040593          	addi	a1,s0,-48
    80006066:	f5040513          	addi	a0,s0,-176
    8000606a:	fffff097          	auipc	ra,0xfffff
    8000606e:	ac2080e7          	jalr	-1342(ra) # 80004b2c <nameiparent>
    80006072:	892a                	mv	s2,a0
    80006074:	c935                	beqz	a0,800060e8 <sys_link+0x10a>
  ilock(dp);
    80006076:	ffffe097          	auipc	ra,0xffffe
    8000607a:	2f2080e7          	jalr	754(ra) # 80004368 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000607e:	00092703          	lw	a4,0(s2)
    80006082:	409c                	lw	a5,0(s1)
    80006084:	04f71d63          	bne	a4,a5,800060de <sys_link+0x100>
    80006088:	40d0                	lw	a2,4(s1)
    8000608a:	fd040593          	addi	a1,s0,-48
    8000608e:	854a                	mv	a0,s2
    80006090:	fffff097          	auipc	ra,0xfffff
    80006094:	9cc080e7          	jalr	-1588(ra) # 80004a5c <dirlink>
    80006098:	04054363          	bltz	a0,800060de <sys_link+0x100>
  iunlockput(dp);
    8000609c:	854a                	mv	a0,s2
    8000609e:	ffffe097          	auipc	ra,0xffffe
    800060a2:	52c080e7          	jalr	1324(ra) # 800045ca <iunlockput>
  iput(ip);
    800060a6:	8526                	mv	a0,s1
    800060a8:	ffffe097          	auipc	ra,0xffffe
    800060ac:	47a080e7          	jalr	1146(ra) # 80004522 <iput>
  end_op();
    800060b0:	fffff097          	auipc	ra,0xfffff
    800060b4:	cfa080e7          	jalr	-774(ra) # 80004daa <end_op>
  return 0;
    800060b8:	4781                	li	a5,0
    800060ba:	a085                	j	8000611a <sys_link+0x13c>
    end_op();
    800060bc:	fffff097          	auipc	ra,0xfffff
    800060c0:	cee080e7          	jalr	-786(ra) # 80004daa <end_op>
    return -1;
    800060c4:	57fd                	li	a5,-1
    800060c6:	a891                	j	8000611a <sys_link+0x13c>
    iunlockput(ip);
    800060c8:	8526                	mv	a0,s1
    800060ca:	ffffe097          	auipc	ra,0xffffe
    800060ce:	500080e7          	jalr	1280(ra) # 800045ca <iunlockput>
    end_op();
    800060d2:	fffff097          	auipc	ra,0xfffff
    800060d6:	cd8080e7          	jalr	-808(ra) # 80004daa <end_op>
    return -1;
    800060da:	57fd                	li	a5,-1
    800060dc:	a83d                	j	8000611a <sys_link+0x13c>
    iunlockput(dp);
    800060de:	854a                	mv	a0,s2
    800060e0:	ffffe097          	auipc	ra,0xffffe
    800060e4:	4ea080e7          	jalr	1258(ra) # 800045ca <iunlockput>
  ilock(ip);
    800060e8:	8526                	mv	a0,s1
    800060ea:	ffffe097          	auipc	ra,0xffffe
    800060ee:	27e080e7          	jalr	638(ra) # 80004368 <ilock>
  ip->nlink--;
    800060f2:	04a4d783          	lhu	a5,74(s1)
    800060f6:	37fd                	addiw	a5,a5,-1
    800060f8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800060fc:	8526                	mv	a0,s1
    800060fe:	ffffe097          	auipc	ra,0xffffe
    80006102:	1a0080e7          	jalr	416(ra) # 8000429e <iupdate>
  iunlockput(ip);
    80006106:	8526                	mv	a0,s1
    80006108:	ffffe097          	auipc	ra,0xffffe
    8000610c:	4c2080e7          	jalr	1218(ra) # 800045ca <iunlockput>
  end_op();
    80006110:	fffff097          	auipc	ra,0xfffff
    80006114:	c9a080e7          	jalr	-870(ra) # 80004daa <end_op>
  return -1;
    80006118:	57fd                	li	a5,-1
}
    8000611a:	853e                	mv	a0,a5
    8000611c:	70b2                	ld	ra,296(sp)
    8000611e:	7412                	ld	s0,288(sp)
    80006120:	64f2                	ld	s1,280(sp)
    80006122:	6952                	ld	s2,272(sp)
    80006124:	6155                	addi	sp,sp,304
    80006126:	8082                	ret

0000000080006128 <sys_unlink>:
{
    80006128:	7151                	addi	sp,sp,-240
    8000612a:	f586                	sd	ra,232(sp)
    8000612c:	f1a2                	sd	s0,224(sp)
    8000612e:	eda6                	sd	s1,216(sp)
    80006130:	e9ca                	sd	s2,208(sp)
    80006132:	e5ce                	sd	s3,200(sp)
    80006134:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80006136:	08000613          	li	a2,128
    8000613a:	f3040593          	addi	a1,s0,-208
    8000613e:	4501                	li	a0,0
    80006140:	ffffd097          	auipc	ra,0xffffd
    80006144:	0e4080e7          	jalr	228(ra) # 80003224 <argstr>
    80006148:	18054163          	bltz	a0,800062ca <sys_unlink+0x1a2>
  begin_op();
    8000614c:	fffff097          	auipc	ra,0xfffff
    80006150:	bde080e7          	jalr	-1058(ra) # 80004d2a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80006154:	fb040593          	addi	a1,s0,-80
    80006158:	f3040513          	addi	a0,s0,-208
    8000615c:	fffff097          	auipc	ra,0xfffff
    80006160:	9d0080e7          	jalr	-1584(ra) # 80004b2c <nameiparent>
    80006164:	84aa                	mv	s1,a0
    80006166:	c979                	beqz	a0,8000623c <sys_unlink+0x114>
  ilock(dp);
    80006168:	ffffe097          	auipc	ra,0xffffe
    8000616c:	200080e7          	jalr	512(ra) # 80004368 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80006170:	00003597          	auipc	a1,0x3
    80006174:	74058593          	addi	a1,a1,1856 # 800098b0 <syscalls+0x2c8>
    80006178:	fb040513          	addi	a0,s0,-80
    8000617c:	ffffe097          	auipc	ra,0xffffe
    80006180:	6b6080e7          	jalr	1718(ra) # 80004832 <namecmp>
    80006184:	14050a63          	beqz	a0,800062d8 <sys_unlink+0x1b0>
    80006188:	00003597          	auipc	a1,0x3
    8000618c:	73058593          	addi	a1,a1,1840 # 800098b8 <syscalls+0x2d0>
    80006190:	fb040513          	addi	a0,s0,-80
    80006194:	ffffe097          	auipc	ra,0xffffe
    80006198:	69e080e7          	jalr	1694(ra) # 80004832 <namecmp>
    8000619c:	12050e63          	beqz	a0,800062d8 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800061a0:	f2c40613          	addi	a2,s0,-212
    800061a4:	fb040593          	addi	a1,s0,-80
    800061a8:	8526                	mv	a0,s1
    800061aa:	ffffe097          	auipc	ra,0xffffe
    800061ae:	6a2080e7          	jalr	1698(ra) # 8000484c <dirlookup>
    800061b2:	892a                	mv	s2,a0
    800061b4:	12050263          	beqz	a0,800062d8 <sys_unlink+0x1b0>
  ilock(ip);
    800061b8:	ffffe097          	auipc	ra,0xffffe
    800061bc:	1b0080e7          	jalr	432(ra) # 80004368 <ilock>
  if(ip->nlink < 1)
    800061c0:	04a91783          	lh	a5,74(s2)
    800061c4:	08f05263          	blez	a5,80006248 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800061c8:	04491703          	lh	a4,68(s2)
    800061cc:	4785                	li	a5,1
    800061ce:	08f70563          	beq	a4,a5,80006258 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800061d2:	4641                	li	a2,16
    800061d4:	4581                	li	a1,0
    800061d6:	fc040513          	addi	a0,s0,-64
    800061da:	ffffb097          	auipc	ra,0xffffb
    800061de:	b0c080e7          	jalr	-1268(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800061e2:	4741                	li	a4,16
    800061e4:	f2c42683          	lw	a3,-212(s0)
    800061e8:	fc040613          	addi	a2,s0,-64
    800061ec:	4581                	li	a1,0
    800061ee:	8526                	mv	a0,s1
    800061f0:	ffffe097          	auipc	ra,0xffffe
    800061f4:	524080e7          	jalr	1316(ra) # 80004714 <writei>
    800061f8:	47c1                	li	a5,16
    800061fa:	0af51563          	bne	a0,a5,800062a4 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800061fe:	04491703          	lh	a4,68(s2)
    80006202:	4785                	li	a5,1
    80006204:	0af70863          	beq	a4,a5,800062b4 <sys_unlink+0x18c>
  iunlockput(dp);
    80006208:	8526                	mv	a0,s1
    8000620a:	ffffe097          	auipc	ra,0xffffe
    8000620e:	3c0080e7          	jalr	960(ra) # 800045ca <iunlockput>
  ip->nlink--;
    80006212:	04a95783          	lhu	a5,74(s2)
    80006216:	37fd                	addiw	a5,a5,-1
    80006218:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000621c:	854a                	mv	a0,s2
    8000621e:	ffffe097          	auipc	ra,0xffffe
    80006222:	080080e7          	jalr	128(ra) # 8000429e <iupdate>
  iunlockput(ip);
    80006226:	854a                	mv	a0,s2
    80006228:	ffffe097          	auipc	ra,0xffffe
    8000622c:	3a2080e7          	jalr	930(ra) # 800045ca <iunlockput>
  end_op();
    80006230:	fffff097          	auipc	ra,0xfffff
    80006234:	b7a080e7          	jalr	-1158(ra) # 80004daa <end_op>
  return 0;
    80006238:	4501                	li	a0,0
    8000623a:	a84d                	j	800062ec <sys_unlink+0x1c4>
    end_op();
    8000623c:	fffff097          	auipc	ra,0xfffff
    80006240:	b6e080e7          	jalr	-1170(ra) # 80004daa <end_op>
    return -1;
    80006244:	557d                	li	a0,-1
    80006246:	a05d                	j	800062ec <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80006248:	00003517          	auipc	a0,0x3
    8000624c:	67850513          	addi	a0,a0,1656 # 800098c0 <syscalls+0x2d8>
    80006250:	ffffa097          	auipc	ra,0xffffa
    80006254:	2f4080e7          	jalr	756(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006258:	04c92703          	lw	a4,76(s2)
    8000625c:	02000793          	li	a5,32
    80006260:	f6e7f9e3          	bgeu	a5,a4,800061d2 <sys_unlink+0xaa>
    80006264:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006268:	4741                	li	a4,16
    8000626a:	86ce                	mv	a3,s3
    8000626c:	f1840613          	addi	a2,s0,-232
    80006270:	4581                	li	a1,0
    80006272:	854a                	mv	a0,s2
    80006274:	ffffe097          	auipc	ra,0xffffe
    80006278:	3a8080e7          	jalr	936(ra) # 8000461c <readi>
    8000627c:	47c1                	li	a5,16
    8000627e:	00f51b63          	bne	a0,a5,80006294 <sys_unlink+0x16c>
    if(de.inum != 0)
    80006282:	f1845783          	lhu	a5,-232(s0)
    80006286:	e7a1                	bnez	a5,800062ce <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006288:	29c1                	addiw	s3,s3,16
    8000628a:	04c92783          	lw	a5,76(s2)
    8000628e:	fcf9ede3          	bltu	s3,a5,80006268 <sys_unlink+0x140>
    80006292:	b781                	j	800061d2 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80006294:	00003517          	auipc	a0,0x3
    80006298:	64450513          	addi	a0,a0,1604 # 800098d8 <syscalls+0x2f0>
    8000629c:	ffffa097          	auipc	ra,0xffffa
    800062a0:	2a8080e7          	jalr	680(ra) # 80000544 <panic>
    panic("unlink: writei");
    800062a4:	00003517          	auipc	a0,0x3
    800062a8:	64c50513          	addi	a0,a0,1612 # 800098f0 <syscalls+0x308>
    800062ac:	ffffa097          	auipc	ra,0xffffa
    800062b0:	298080e7          	jalr	664(ra) # 80000544 <panic>
    dp->nlink--;
    800062b4:	04a4d783          	lhu	a5,74(s1)
    800062b8:	37fd                	addiw	a5,a5,-1
    800062ba:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800062be:	8526                	mv	a0,s1
    800062c0:	ffffe097          	auipc	ra,0xffffe
    800062c4:	fde080e7          	jalr	-34(ra) # 8000429e <iupdate>
    800062c8:	b781                	j	80006208 <sys_unlink+0xe0>
    return -1;
    800062ca:	557d                	li	a0,-1
    800062cc:	a005                	j	800062ec <sys_unlink+0x1c4>
    iunlockput(ip);
    800062ce:	854a                	mv	a0,s2
    800062d0:	ffffe097          	auipc	ra,0xffffe
    800062d4:	2fa080e7          	jalr	762(ra) # 800045ca <iunlockput>
  iunlockput(dp);
    800062d8:	8526                	mv	a0,s1
    800062da:	ffffe097          	auipc	ra,0xffffe
    800062de:	2f0080e7          	jalr	752(ra) # 800045ca <iunlockput>
  end_op();
    800062e2:	fffff097          	auipc	ra,0xfffff
    800062e6:	ac8080e7          	jalr	-1336(ra) # 80004daa <end_op>
  return -1;
    800062ea:	557d                	li	a0,-1
}
    800062ec:	70ae                	ld	ra,232(sp)
    800062ee:	740e                	ld	s0,224(sp)
    800062f0:	64ee                	ld	s1,216(sp)
    800062f2:	694e                	ld	s2,208(sp)
    800062f4:	69ae                	ld	s3,200(sp)
    800062f6:	616d                	addi	sp,sp,240
    800062f8:	8082                	ret

00000000800062fa <sys_open>:

uint64
sys_open(void)
{
    800062fa:	7131                	addi	sp,sp,-192
    800062fc:	fd06                	sd	ra,184(sp)
    800062fe:	f922                	sd	s0,176(sp)
    80006300:	f526                	sd	s1,168(sp)
    80006302:	f14a                	sd	s2,160(sp)
    80006304:	ed4e                	sd	s3,152(sp)
    80006306:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80006308:	f4c40593          	addi	a1,s0,-180
    8000630c:	4505                	li	a0,1
    8000630e:	ffffd097          	auipc	ra,0xffffd
    80006312:	ed6080e7          	jalr	-298(ra) # 800031e4 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80006316:	08000613          	li	a2,128
    8000631a:	f5040593          	addi	a1,s0,-176
    8000631e:	4501                	li	a0,0
    80006320:	ffffd097          	auipc	ra,0xffffd
    80006324:	f04080e7          	jalr	-252(ra) # 80003224 <argstr>
    80006328:	87aa                	mv	a5,a0
    return -1;
    8000632a:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000632c:	0a07c963          	bltz	a5,800063de <sys_open+0xe4>

  begin_op();
    80006330:	fffff097          	auipc	ra,0xfffff
    80006334:	9fa080e7          	jalr	-1542(ra) # 80004d2a <begin_op>

  if(omode & O_CREATE){
    80006338:	f4c42783          	lw	a5,-180(s0)
    8000633c:	2007f793          	andi	a5,a5,512
    80006340:	cfc5                	beqz	a5,800063f8 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80006342:	4681                	li	a3,0
    80006344:	4601                	li	a2,0
    80006346:	4589                	li	a1,2
    80006348:	f5040513          	addi	a0,s0,-176
    8000634c:	00000097          	auipc	ra,0x0
    80006350:	974080e7          	jalr	-1676(ra) # 80005cc0 <create>
    80006354:	84aa                	mv	s1,a0
    if(ip == 0){
    80006356:	c959                	beqz	a0,800063ec <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006358:	04449703          	lh	a4,68(s1)
    8000635c:	478d                	li	a5,3
    8000635e:	00f71763          	bne	a4,a5,8000636c <sys_open+0x72>
    80006362:	0464d703          	lhu	a4,70(s1)
    80006366:	47a5                	li	a5,9
    80006368:	0ce7ed63          	bltu	a5,a4,80006442 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000636c:	fffff097          	auipc	ra,0xfffff
    80006370:	dce080e7          	jalr	-562(ra) # 8000513a <filealloc>
    80006374:	89aa                	mv	s3,a0
    80006376:	10050363          	beqz	a0,8000647c <sys_open+0x182>
    8000637a:	00000097          	auipc	ra,0x0
    8000637e:	904080e7          	jalr	-1788(ra) # 80005c7e <fdalloc>
    80006382:	892a                	mv	s2,a0
    80006384:	0e054763          	bltz	a0,80006472 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006388:	04449703          	lh	a4,68(s1)
    8000638c:	478d                	li	a5,3
    8000638e:	0cf70563          	beq	a4,a5,80006458 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80006392:	4789                	li	a5,2
    80006394:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80006398:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000639c:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800063a0:	f4c42783          	lw	a5,-180(s0)
    800063a4:	0017c713          	xori	a4,a5,1
    800063a8:	8b05                	andi	a4,a4,1
    800063aa:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800063ae:	0037f713          	andi	a4,a5,3
    800063b2:	00e03733          	snez	a4,a4
    800063b6:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800063ba:	4007f793          	andi	a5,a5,1024
    800063be:	c791                	beqz	a5,800063ca <sys_open+0xd0>
    800063c0:	04449703          	lh	a4,68(s1)
    800063c4:	4789                	li	a5,2
    800063c6:	0af70063          	beq	a4,a5,80006466 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800063ca:	8526                	mv	a0,s1
    800063cc:	ffffe097          	auipc	ra,0xffffe
    800063d0:	05e080e7          	jalr	94(ra) # 8000442a <iunlock>
  end_op();
    800063d4:	fffff097          	auipc	ra,0xfffff
    800063d8:	9d6080e7          	jalr	-1578(ra) # 80004daa <end_op>

  return fd;
    800063dc:	854a                	mv	a0,s2
}
    800063de:	70ea                	ld	ra,184(sp)
    800063e0:	744a                	ld	s0,176(sp)
    800063e2:	74aa                	ld	s1,168(sp)
    800063e4:	790a                	ld	s2,160(sp)
    800063e6:	69ea                	ld	s3,152(sp)
    800063e8:	6129                	addi	sp,sp,192
    800063ea:	8082                	ret
      end_op();
    800063ec:	fffff097          	auipc	ra,0xfffff
    800063f0:	9be080e7          	jalr	-1602(ra) # 80004daa <end_op>
      return -1;
    800063f4:	557d                	li	a0,-1
    800063f6:	b7e5                	j	800063de <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800063f8:	f5040513          	addi	a0,s0,-176
    800063fc:	ffffe097          	auipc	ra,0xffffe
    80006400:	712080e7          	jalr	1810(ra) # 80004b0e <namei>
    80006404:	84aa                	mv	s1,a0
    80006406:	c905                	beqz	a0,80006436 <sys_open+0x13c>
    ilock(ip);
    80006408:	ffffe097          	auipc	ra,0xffffe
    8000640c:	f60080e7          	jalr	-160(ra) # 80004368 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006410:	04449703          	lh	a4,68(s1)
    80006414:	4785                	li	a5,1
    80006416:	f4f711e3          	bne	a4,a5,80006358 <sys_open+0x5e>
    8000641a:	f4c42783          	lw	a5,-180(s0)
    8000641e:	d7b9                	beqz	a5,8000636c <sys_open+0x72>
      iunlockput(ip);
    80006420:	8526                	mv	a0,s1
    80006422:	ffffe097          	auipc	ra,0xffffe
    80006426:	1a8080e7          	jalr	424(ra) # 800045ca <iunlockput>
      end_op();
    8000642a:	fffff097          	auipc	ra,0xfffff
    8000642e:	980080e7          	jalr	-1664(ra) # 80004daa <end_op>
      return -1;
    80006432:	557d                	li	a0,-1
    80006434:	b76d                	j	800063de <sys_open+0xe4>
      end_op();
    80006436:	fffff097          	auipc	ra,0xfffff
    8000643a:	974080e7          	jalr	-1676(ra) # 80004daa <end_op>
      return -1;
    8000643e:	557d                	li	a0,-1
    80006440:	bf79                	j	800063de <sys_open+0xe4>
    iunlockput(ip);
    80006442:	8526                	mv	a0,s1
    80006444:	ffffe097          	auipc	ra,0xffffe
    80006448:	186080e7          	jalr	390(ra) # 800045ca <iunlockput>
    end_op();
    8000644c:	fffff097          	auipc	ra,0xfffff
    80006450:	95e080e7          	jalr	-1698(ra) # 80004daa <end_op>
    return -1;
    80006454:	557d                	li	a0,-1
    80006456:	b761                	j	800063de <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006458:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000645c:	04649783          	lh	a5,70(s1)
    80006460:	02f99223          	sh	a5,36(s3)
    80006464:	bf25                	j	8000639c <sys_open+0xa2>
    itrunc(ip);
    80006466:	8526                	mv	a0,s1
    80006468:	ffffe097          	auipc	ra,0xffffe
    8000646c:	00e080e7          	jalr	14(ra) # 80004476 <itrunc>
    80006470:	bfa9                	j	800063ca <sys_open+0xd0>
      fileclose(f);
    80006472:	854e                	mv	a0,s3
    80006474:	fffff097          	auipc	ra,0xfffff
    80006478:	d82080e7          	jalr	-638(ra) # 800051f6 <fileclose>
    iunlockput(ip);
    8000647c:	8526                	mv	a0,s1
    8000647e:	ffffe097          	auipc	ra,0xffffe
    80006482:	14c080e7          	jalr	332(ra) # 800045ca <iunlockput>
    end_op();
    80006486:	fffff097          	auipc	ra,0xfffff
    8000648a:	924080e7          	jalr	-1756(ra) # 80004daa <end_op>
    return -1;
    8000648e:	557d                	li	a0,-1
    80006490:	b7b9                	j	800063de <sys_open+0xe4>

0000000080006492 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006492:	7175                	addi	sp,sp,-144
    80006494:	e506                	sd	ra,136(sp)
    80006496:	e122                	sd	s0,128(sp)
    80006498:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000649a:	fffff097          	auipc	ra,0xfffff
    8000649e:	890080e7          	jalr	-1904(ra) # 80004d2a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800064a2:	08000613          	li	a2,128
    800064a6:	f7040593          	addi	a1,s0,-144
    800064aa:	4501                	li	a0,0
    800064ac:	ffffd097          	auipc	ra,0xffffd
    800064b0:	d78080e7          	jalr	-648(ra) # 80003224 <argstr>
    800064b4:	02054963          	bltz	a0,800064e6 <sys_mkdir+0x54>
    800064b8:	4681                	li	a3,0
    800064ba:	4601                	li	a2,0
    800064bc:	4585                	li	a1,1
    800064be:	f7040513          	addi	a0,s0,-144
    800064c2:	fffff097          	auipc	ra,0xfffff
    800064c6:	7fe080e7          	jalr	2046(ra) # 80005cc0 <create>
    800064ca:	cd11                	beqz	a0,800064e6 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800064cc:	ffffe097          	auipc	ra,0xffffe
    800064d0:	0fe080e7          	jalr	254(ra) # 800045ca <iunlockput>
  end_op();
    800064d4:	fffff097          	auipc	ra,0xfffff
    800064d8:	8d6080e7          	jalr	-1834(ra) # 80004daa <end_op>
  return 0;
    800064dc:	4501                	li	a0,0
}
    800064de:	60aa                	ld	ra,136(sp)
    800064e0:	640a                	ld	s0,128(sp)
    800064e2:	6149                	addi	sp,sp,144
    800064e4:	8082                	ret
    end_op();
    800064e6:	fffff097          	auipc	ra,0xfffff
    800064ea:	8c4080e7          	jalr	-1852(ra) # 80004daa <end_op>
    return -1;
    800064ee:	557d                	li	a0,-1
    800064f0:	b7fd                	j	800064de <sys_mkdir+0x4c>

00000000800064f2 <sys_mknod>:

uint64
sys_mknod(void)
{
    800064f2:	7135                	addi	sp,sp,-160
    800064f4:	ed06                	sd	ra,152(sp)
    800064f6:	e922                	sd	s0,144(sp)
    800064f8:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800064fa:	fffff097          	auipc	ra,0xfffff
    800064fe:	830080e7          	jalr	-2000(ra) # 80004d2a <begin_op>
  argint(1, &major);
    80006502:	f6c40593          	addi	a1,s0,-148
    80006506:	4505                	li	a0,1
    80006508:	ffffd097          	auipc	ra,0xffffd
    8000650c:	cdc080e7          	jalr	-804(ra) # 800031e4 <argint>
  argint(2, &minor);
    80006510:	f6840593          	addi	a1,s0,-152
    80006514:	4509                	li	a0,2
    80006516:	ffffd097          	auipc	ra,0xffffd
    8000651a:	cce080e7          	jalr	-818(ra) # 800031e4 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000651e:	08000613          	li	a2,128
    80006522:	f7040593          	addi	a1,s0,-144
    80006526:	4501                	li	a0,0
    80006528:	ffffd097          	auipc	ra,0xffffd
    8000652c:	cfc080e7          	jalr	-772(ra) # 80003224 <argstr>
    80006530:	02054b63          	bltz	a0,80006566 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006534:	f6841683          	lh	a3,-152(s0)
    80006538:	f6c41603          	lh	a2,-148(s0)
    8000653c:	458d                	li	a1,3
    8000653e:	f7040513          	addi	a0,s0,-144
    80006542:	fffff097          	auipc	ra,0xfffff
    80006546:	77e080e7          	jalr	1918(ra) # 80005cc0 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000654a:	cd11                	beqz	a0,80006566 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000654c:	ffffe097          	auipc	ra,0xffffe
    80006550:	07e080e7          	jalr	126(ra) # 800045ca <iunlockput>
  end_op();
    80006554:	fffff097          	auipc	ra,0xfffff
    80006558:	856080e7          	jalr	-1962(ra) # 80004daa <end_op>
  return 0;
    8000655c:	4501                	li	a0,0
}
    8000655e:	60ea                	ld	ra,152(sp)
    80006560:	644a                	ld	s0,144(sp)
    80006562:	610d                	addi	sp,sp,160
    80006564:	8082                	ret
    end_op();
    80006566:	fffff097          	auipc	ra,0xfffff
    8000656a:	844080e7          	jalr	-1980(ra) # 80004daa <end_op>
    return -1;
    8000656e:	557d                	li	a0,-1
    80006570:	b7fd                	j	8000655e <sys_mknod+0x6c>

0000000080006572 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006572:	7135                	addi	sp,sp,-160
    80006574:	ed06                	sd	ra,152(sp)
    80006576:	e922                	sd	s0,144(sp)
    80006578:	e526                	sd	s1,136(sp)
    8000657a:	e14a                	sd	s2,128(sp)
    8000657c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000657e:	ffffb097          	auipc	ra,0xffffb
    80006582:	678080e7          	jalr	1656(ra) # 80001bf6 <myproc>
    80006586:	892a                	mv	s2,a0
  
  begin_op();
    80006588:	ffffe097          	auipc	ra,0xffffe
    8000658c:	7a2080e7          	jalr	1954(ra) # 80004d2a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006590:	08000613          	li	a2,128
    80006594:	f6040593          	addi	a1,s0,-160
    80006598:	4501                	li	a0,0
    8000659a:	ffffd097          	auipc	ra,0xffffd
    8000659e:	c8a080e7          	jalr	-886(ra) # 80003224 <argstr>
    800065a2:	04054b63          	bltz	a0,800065f8 <sys_chdir+0x86>
    800065a6:	f6040513          	addi	a0,s0,-160
    800065aa:	ffffe097          	auipc	ra,0xffffe
    800065ae:	564080e7          	jalr	1380(ra) # 80004b0e <namei>
    800065b2:	84aa                	mv	s1,a0
    800065b4:	c131                	beqz	a0,800065f8 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800065b6:	ffffe097          	auipc	ra,0xffffe
    800065ba:	db2080e7          	jalr	-590(ra) # 80004368 <ilock>
  if(ip->type != T_DIR){
    800065be:	04449703          	lh	a4,68(s1)
    800065c2:	4785                	li	a5,1
    800065c4:	04f71063          	bne	a4,a5,80006604 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800065c8:	8526                	mv	a0,s1
    800065ca:	ffffe097          	auipc	ra,0xffffe
    800065ce:	e60080e7          	jalr	-416(ra) # 8000442a <iunlock>
  iput(p->cwd);
    800065d2:	15093503          	ld	a0,336(s2)
    800065d6:	ffffe097          	auipc	ra,0xffffe
    800065da:	f4c080e7          	jalr	-180(ra) # 80004522 <iput>
  end_op();
    800065de:	ffffe097          	auipc	ra,0xffffe
    800065e2:	7cc080e7          	jalr	1996(ra) # 80004daa <end_op>
  p->cwd = ip;
    800065e6:	14993823          	sd	s1,336(s2)
  return 0;
    800065ea:	4501                	li	a0,0
}
    800065ec:	60ea                	ld	ra,152(sp)
    800065ee:	644a                	ld	s0,144(sp)
    800065f0:	64aa                	ld	s1,136(sp)
    800065f2:	690a                	ld	s2,128(sp)
    800065f4:	610d                	addi	sp,sp,160
    800065f6:	8082                	ret
    end_op();
    800065f8:	ffffe097          	auipc	ra,0xffffe
    800065fc:	7b2080e7          	jalr	1970(ra) # 80004daa <end_op>
    return -1;
    80006600:	557d                	li	a0,-1
    80006602:	b7ed                	j	800065ec <sys_chdir+0x7a>
    iunlockput(ip);
    80006604:	8526                	mv	a0,s1
    80006606:	ffffe097          	auipc	ra,0xffffe
    8000660a:	fc4080e7          	jalr	-60(ra) # 800045ca <iunlockput>
    end_op();
    8000660e:	ffffe097          	auipc	ra,0xffffe
    80006612:	79c080e7          	jalr	1948(ra) # 80004daa <end_op>
    return -1;
    80006616:	557d                	li	a0,-1
    80006618:	bfd1                	j	800065ec <sys_chdir+0x7a>

000000008000661a <sys_exec>:

uint64
sys_exec(void)
{
    8000661a:	7145                	addi	sp,sp,-464
    8000661c:	e786                	sd	ra,456(sp)
    8000661e:	e3a2                	sd	s0,448(sp)
    80006620:	ff26                	sd	s1,440(sp)
    80006622:	fb4a                	sd	s2,432(sp)
    80006624:	f74e                	sd	s3,424(sp)
    80006626:	f352                	sd	s4,416(sp)
    80006628:	ef56                	sd	s5,408(sp)
    8000662a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    8000662c:	e3840593          	addi	a1,s0,-456
    80006630:	4505                	li	a0,1
    80006632:	ffffd097          	auipc	ra,0xffffd
    80006636:	bd2080e7          	jalr	-1070(ra) # 80003204 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    8000663a:	08000613          	li	a2,128
    8000663e:	f4040593          	addi	a1,s0,-192
    80006642:	4501                	li	a0,0
    80006644:	ffffd097          	auipc	ra,0xffffd
    80006648:	be0080e7          	jalr	-1056(ra) # 80003224 <argstr>
    8000664c:	87aa                	mv	a5,a0
    return -1;
    8000664e:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80006650:	0c07c263          	bltz	a5,80006714 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006654:	10000613          	li	a2,256
    80006658:	4581                	li	a1,0
    8000665a:	e4040513          	addi	a0,s0,-448
    8000665e:	ffffa097          	auipc	ra,0xffffa
    80006662:	688080e7          	jalr	1672(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006666:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000666a:	89a6                	mv	s3,s1
    8000666c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000666e:	02000a13          	li	s4,32
    80006672:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006676:	00391513          	slli	a0,s2,0x3
    8000667a:	e3040593          	addi	a1,s0,-464
    8000667e:	e3843783          	ld	a5,-456(s0)
    80006682:	953e                	add	a0,a0,a5
    80006684:	ffffd097          	auipc	ra,0xffffd
    80006688:	ac2080e7          	jalr	-1342(ra) # 80003146 <fetchaddr>
    8000668c:	02054a63          	bltz	a0,800066c0 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80006690:	e3043783          	ld	a5,-464(s0)
    80006694:	c3b9                	beqz	a5,800066da <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006696:	ffffa097          	auipc	ra,0xffffa
    8000669a:	464080e7          	jalr	1124(ra) # 80000afa <kalloc>
    8000669e:	85aa                	mv	a1,a0
    800066a0:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800066a4:	cd11                	beqz	a0,800066c0 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800066a6:	6605                	lui	a2,0x1
    800066a8:	e3043503          	ld	a0,-464(s0)
    800066ac:	ffffd097          	auipc	ra,0xffffd
    800066b0:	aec080e7          	jalr	-1300(ra) # 80003198 <fetchstr>
    800066b4:	00054663          	bltz	a0,800066c0 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    800066b8:	0905                	addi	s2,s2,1
    800066ba:	09a1                	addi	s3,s3,8
    800066bc:	fb491be3          	bne	s2,s4,80006672 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800066c0:	10048913          	addi	s2,s1,256
    800066c4:	6088                	ld	a0,0(s1)
    800066c6:	c531                	beqz	a0,80006712 <sys_exec+0xf8>
    kfree(argv[i]);
    800066c8:	ffffa097          	auipc	ra,0xffffa
    800066cc:	336080e7          	jalr	822(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800066d0:	04a1                	addi	s1,s1,8
    800066d2:	ff2499e3          	bne	s1,s2,800066c4 <sys_exec+0xaa>
  return -1;
    800066d6:	557d                	li	a0,-1
    800066d8:	a835                	j	80006714 <sys_exec+0xfa>
      argv[i] = 0;
    800066da:	0a8e                	slli	s5,s5,0x3
    800066dc:	fc040793          	addi	a5,s0,-64
    800066e0:	9abe                	add	s5,s5,a5
    800066e2:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800066e6:	e4040593          	addi	a1,s0,-448
    800066ea:	f4040513          	addi	a0,s0,-192
    800066ee:	fffff097          	auipc	ra,0xfffff
    800066f2:	190080e7          	jalr	400(ra) # 8000587e <exec>
    800066f6:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800066f8:	10048993          	addi	s3,s1,256
    800066fc:	6088                	ld	a0,0(s1)
    800066fe:	c901                	beqz	a0,8000670e <sys_exec+0xf4>
    kfree(argv[i]);
    80006700:	ffffa097          	auipc	ra,0xffffa
    80006704:	2fe080e7          	jalr	766(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006708:	04a1                	addi	s1,s1,8
    8000670a:	ff3499e3          	bne	s1,s3,800066fc <sys_exec+0xe2>
  return ret;
    8000670e:	854a                	mv	a0,s2
    80006710:	a011                	j	80006714 <sys_exec+0xfa>
  return -1;
    80006712:	557d                	li	a0,-1
}
    80006714:	60be                	ld	ra,456(sp)
    80006716:	641e                	ld	s0,448(sp)
    80006718:	74fa                	ld	s1,440(sp)
    8000671a:	795a                	ld	s2,432(sp)
    8000671c:	79ba                	ld	s3,424(sp)
    8000671e:	7a1a                	ld	s4,416(sp)
    80006720:	6afa                	ld	s5,408(sp)
    80006722:	6179                	addi	sp,sp,464
    80006724:	8082                	ret

0000000080006726 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006726:	7139                	addi	sp,sp,-64
    80006728:	fc06                	sd	ra,56(sp)
    8000672a:	f822                	sd	s0,48(sp)
    8000672c:	f426                	sd	s1,40(sp)
    8000672e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006730:	ffffb097          	auipc	ra,0xffffb
    80006734:	4c6080e7          	jalr	1222(ra) # 80001bf6 <myproc>
    80006738:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    8000673a:	fd840593          	addi	a1,s0,-40
    8000673e:	4501                	li	a0,0
    80006740:	ffffd097          	auipc	ra,0xffffd
    80006744:	ac4080e7          	jalr	-1340(ra) # 80003204 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006748:	fc840593          	addi	a1,s0,-56
    8000674c:	fd040513          	addi	a0,s0,-48
    80006750:	fffff097          	auipc	ra,0xfffff
    80006754:	dd6080e7          	jalr	-554(ra) # 80005526 <pipealloc>
    return -1;
    80006758:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000675a:	0c054463          	bltz	a0,80006822 <sys_pipe+0xfc>
  fd0 = -1;
    8000675e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006762:	fd043503          	ld	a0,-48(s0)
    80006766:	fffff097          	auipc	ra,0xfffff
    8000676a:	518080e7          	jalr	1304(ra) # 80005c7e <fdalloc>
    8000676e:	fca42223          	sw	a0,-60(s0)
    80006772:	08054b63          	bltz	a0,80006808 <sys_pipe+0xe2>
    80006776:	fc843503          	ld	a0,-56(s0)
    8000677a:	fffff097          	auipc	ra,0xfffff
    8000677e:	504080e7          	jalr	1284(ra) # 80005c7e <fdalloc>
    80006782:	fca42023          	sw	a0,-64(s0)
    80006786:	06054863          	bltz	a0,800067f6 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000678a:	4691                	li	a3,4
    8000678c:	fc440613          	addi	a2,s0,-60
    80006790:	fd843583          	ld	a1,-40(s0)
    80006794:	68a8                	ld	a0,80(s1)
    80006796:	ffffb097          	auipc	ra,0xffffb
    8000679a:	eee080e7          	jalr	-274(ra) # 80001684 <copyout>
    8000679e:	02054063          	bltz	a0,800067be <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800067a2:	4691                	li	a3,4
    800067a4:	fc040613          	addi	a2,s0,-64
    800067a8:	fd843583          	ld	a1,-40(s0)
    800067ac:	0591                	addi	a1,a1,4
    800067ae:	68a8                	ld	a0,80(s1)
    800067b0:	ffffb097          	auipc	ra,0xffffb
    800067b4:	ed4080e7          	jalr	-300(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800067b8:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800067ba:	06055463          	bgez	a0,80006822 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    800067be:	fc442783          	lw	a5,-60(s0)
    800067c2:	07e9                	addi	a5,a5,26
    800067c4:	078e                	slli	a5,a5,0x3
    800067c6:	97a6                	add	a5,a5,s1
    800067c8:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800067cc:	fc042503          	lw	a0,-64(s0)
    800067d0:	0569                	addi	a0,a0,26
    800067d2:	050e                	slli	a0,a0,0x3
    800067d4:	94aa                	add	s1,s1,a0
    800067d6:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800067da:	fd043503          	ld	a0,-48(s0)
    800067de:	fffff097          	auipc	ra,0xfffff
    800067e2:	a18080e7          	jalr	-1512(ra) # 800051f6 <fileclose>
    fileclose(wf);
    800067e6:	fc843503          	ld	a0,-56(s0)
    800067ea:	fffff097          	auipc	ra,0xfffff
    800067ee:	a0c080e7          	jalr	-1524(ra) # 800051f6 <fileclose>
    return -1;
    800067f2:	57fd                	li	a5,-1
    800067f4:	a03d                	j	80006822 <sys_pipe+0xfc>
    if(fd0 >= 0)
    800067f6:	fc442783          	lw	a5,-60(s0)
    800067fa:	0007c763          	bltz	a5,80006808 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    800067fe:	07e9                	addi	a5,a5,26
    80006800:	078e                	slli	a5,a5,0x3
    80006802:	94be                	add	s1,s1,a5
    80006804:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006808:	fd043503          	ld	a0,-48(s0)
    8000680c:	fffff097          	auipc	ra,0xfffff
    80006810:	9ea080e7          	jalr	-1558(ra) # 800051f6 <fileclose>
    fileclose(wf);
    80006814:	fc843503          	ld	a0,-56(s0)
    80006818:	fffff097          	auipc	ra,0xfffff
    8000681c:	9de080e7          	jalr	-1570(ra) # 800051f6 <fileclose>
    return -1;
    80006820:	57fd                	li	a5,-1
}
    80006822:	853e                	mv	a0,a5
    80006824:	70e2                	ld	ra,56(sp)
    80006826:	7442                	ld	s0,48(sp)
    80006828:	74a2                	ld	s1,40(sp)
    8000682a:	6121                	addi	sp,sp,64
    8000682c:	8082                	ret
	...

0000000080006830 <kernelvec>:
    80006830:	7111                	addi	sp,sp,-256
    80006832:	e006                	sd	ra,0(sp)
    80006834:	e40a                	sd	sp,8(sp)
    80006836:	e80e                	sd	gp,16(sp)
    80006838:	ec12                	sd	tp,24(sp)
    8000683a:	f016                	sd	t0,32(sp)
    8000683c:	f41a                	sd	t1,40(sp)
    8000683e:	f81e                	sd	t2,48(sp)
    80006840:	fc22                	sd	s0,56(sp)
    80006842:	e0a6                	sd	s1,64(sp)
    80006844:	e4aa                	sd	a0,72(sp)
    80006846:	e8ae                	sd	a1,80(sp)
    80006848:	ecb2                	sd	a2,88(sp)
    8000684a:	f0b6                	sd	a3,96(sp)
    8000684c:	f4ba                	sd	a4,104(sp)
    8000684e:	f8be                	sd	a5,112(sp)
    80006850:	fcc2                	sd	a6,120(sp)
    80006852:	e146                	sd	a7,128(sp)
    80006854:	e54a                	sd	s2,136(sp)
    80006856:	e94e                	sd	s3,144(sp)
    80006858:	ed52                	sd	s4,152(sp)
    8000685a:	f156                	sd	s5,160(sp)
    8000685c:	f55a                	sd	s6,168(sp)
    8000685e:	f95e                	sd	s7,176(sp)
    80006860:	fd62                	sd	s8,184(sp)
    80006862:	e1e6                	sd	s9,192(sp)
    80006864:	e5ea                	sd	s10,200(sp)
    80006866:	e9ee                	sd	s11,208(sp)
    80006868:	edf2                	sd	t3,216(sp)
    8000686a:	f1f6                	sd	t4,224(sp)
    8000686c:	f5fa                	sd	t5,232(sp)
    8000686e:	f9fe                	sd	t6,240(sp)
    80006870:	f38fc0ef          	jal	ra,80002fa8 <kerneltrap>
    80006874:	6082                	ld	ra,0(sp)
    80006876:	6122                	ld	sp,8(sp)
    80006878:	61c2                	ld	gp,16(sp)
    8000687a:	7282                	ld	t0,32(sp)
    8000687c:	7322                	ld	t1,40(sp)
    8000687e:	73c2                	ld	t2,48(sp)
    80006880:	7462                	ld	s0,56(sp)
    80006882:	6486                	ld	s1,64(sp)
    80006884:	6526                	ld	a0,72(sp)
    80006886:	65c6                	ld	a1,80(sp)
    80006888:	6666                	ld	a2,88(sp)
    8000688a:	7686                	ld	a3,96(sp)
    8000688c:	7726                	ld	a4,104(sp)
    8000688e:	77c6                	ld	a5,112(sp)
    80006890:	7866                	ld	a6,120(sp)
    80006892:	688a                	ld	a7,128(sp)
    80006894:	692a                	ld	s2,136(sp)
    80006896:	69ca                	ld	s3,144(sp)
    80006898:	6a6a                	ld	s4,152(sp)
    8000689a:	7a8a                	ld	s5,160(sp)
    8000689c:	7b2a                	ld	s6,168(sp)
    8000689e:	7bca                	ld	s7,176(sp)
    800068a0:	7c6a                	ld	s8,184(sp)
    800068a2:	6c8e                	ld	s9,192(sp)
    800068a4:	6d2e                	ld	s10,200(sp)
    800068a6:	6dce                	ld	s11,208(sp)
    800068a8:	6e6e                	ld	t3,216(sp)
    800068aa:	7e8e                	ld	t4,224(sp)
    800068ac:	7f2e                	ld	t5,232(sp)
    800068ae:	7fce                	ld	t6,240(sp)
    800068b0:	6111                	addi	sp,sp,256
    800068b2:	10200073          	sret
    800068b6:	00000013          	nop
    800068ba:	00000013          	nop
    800068be:	0001                	nop

00000000800068c0 <timervec>:
    800068c0:	34051573          	csrrw	a0,mscratch,a0
    800068c4:	e10c                	sd	a1,0(a0)
    800068c6:	e510                	sd	a2,8(a0)
    800068c8:	e914                	sd	a3,16(a0)
    800068ca:	6d0c                	ld	a1,24(a0)
    800068cc:	7110                	ld	a2,32(a0)
    800068ce:	6194                	ld	a3,0(a1)
    800068d0:	96b2                	add	a3,a3,a2
    800068d2:	e194                	sd	a3,0(a1)
    800068d4:	4589                	li	a1,2
    800068d6:	14459073          	csrw	sip,a1
    800068da:	6914                	ld	a3,16(a0)
    800068dc:	6510                	ld	a2,8(a0)
    800068de:	610c                	ld	a1,0(a0)
    800068e0:	34051573          	csrrw	a0,mscratch,a0
    800068e4:	30200073          	mret
	...

00000000800068ea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800068ea:	1141                	addi	sp,sp,-16
    800068ec:	e422                	sd	s0,8(sp)
    800068ee:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800068f0:	0c0007b7          	lui	a5,0xc000
    800068f4:	4705                	li	a4,1
    800068f6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800068f8:	c3d8                	sw	a4,4(a5)
}
    800068fa:	6422                	ld	s0,8(sp)
    800068fc:	0141                	addi	sp,sp,16
    800068fe:	8082                	ret

0000000080006900 <plicinithart>:

void
plicinithart(void)
{
    80006900:	1141                	addi	sp,sp,-16
    80006902:	e406                	sd	ra,8(sp)
    80006904:	e022                	sd	s0,0(sp)
    80006906:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006908:	ffffb097          	auipc	ra,0xffffb
    8000690c:	2c2080e7          	jalr	706(ra) # 80001bca <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006910:	0085171b          	slliw	a4,a0,0x8
    80006914:	0c0027b7          	lui	a5,0xc002
    80006918:	97ba                	add	a5,a5,a4
    8000691a:	40200713          	li	a4,1026
    8000691e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006922:	00d5151b          	slliw	a0,a0,0xd
    80006926:	0c2017b7          	lui	a5,0xc201
    8000692a:	953e                	add	a0,a0,a5
    8000692c:	00052023          	sw	zero,0(a0)
}
    80006930:	60a2                	ld	ra,8(sp)
    80006932:	6402                	ld	s0,0(sp)
    80006934:	0141                	addi	sp,sp,16
    80006936:	8082                	ret

0000000080006938 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006938:	1141                	addi	sp,sp,-16
    8000693a:	e406                	sd	ra,8(sp)
    8000693c:	e022                	sd	s0,0(sp)
    8000693e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006940:	ffffb097          	auipc	ra,0xffffb
    80006944:	28a080e7          	jalr	650(ra) # 80001bca <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006948:	00d5179b          	slliw	a5,a0,0xd
    8000694c:	0c201537          	lui	a0,0xc201
    80006950:	953e                	add	a0,a0,a5
  return irq;
}
    80006952:	4148                	lw	a0,4(a0)
    80006954:	60a2                	ld	ra,8(sp)
    80006956:	6402                	ld	s0,0(sp)
    80006958:	0141                	addi	sp,sp,16
    8000695a:	8082                	ret

000000008000695c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000695c:	1101                	addi	sp,sp,-32
    8000695e:	ec06                	sd	ra,24(sp)
    80006960:	e822                	sd	s0,16(sp)
    80006962:	e426                	sd	s1,8(sp)
    80006964:	1000                	addi	s0,sp,32
    80006966:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006968:	ffffb097          	auipc	ra,0xffffb
    8000696c:	262080e7          	jalr	610(ra) # 80001bca <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006970:	00d5151b          	slliw	a0,a0,0xd
    80006974:	0c2017b7          	lui	a5,0xc201
    80006978:	97aa                	add	a5,a5,a0
    8000697a:	c3c4                	sw	s1,4(a5)
}
    8000697c:	60e2                	ld	ra,24(sp)
    8000697e:	6442                	ld	s0,16(sp)
    80006980:	64a2                	ld	s1,8(sp)
    80006982:	6105                	addi	sp,sp,32
    80006984:	8082                	ret

0000000080006986 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006986:	1141                	addi	sp,sp,-16
    80006988:	e406                	sd	ra,8(sp)
    8000698a:	e022                	sd	s0,0(sp)
    8000698c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000698e:	479d                	li	a5,7
    80006990:	04a7cc63          	blt	a5,a0,800069e8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006994:	0001e797          	auipc	a5,0x1e
    80006998:	7c478793          	addi	a5,a5,1988 # 80025158 <disk>
    8000699c:	97aa                	add	a5,a5,a0
    8000699e:	0187c783          	lbu	a5,24(a5)
    800069a2:	ebb9                	bnez	a5,800069f8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800069a4:	00451613          	slli	a2,a0,0x4
    800069a8:	0001e797          	auipc	a5,0x1e
    800069ac:	7b078793          	addi	a5,a5,1968 # 80025158 <disk>
    800069b0:	6394                	ld	a3,0(a5)
    800069b2:	96b2                	add	a3,a3,a2
    800069b4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800069b8:	6398                	ld	a4,0(a5)
    800069ba:	9732                	add	a4,a4,a2
    800069bc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800069c0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800069c4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800069c8:	953e                	add	a0,a0,a5
    800069ca:	4785                	li	a5,1
    800069cc:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    800069d0:	0001e517          	auipc	a0,0x1e
    800069d4:	7a050513          	addi	a0,a0,1952 # 80025170 <disk+0x18>
    800069d8:	ffffc097          	auipc	ra,0xffffc
    800069dc:	c2e080e7          	jalr	-978(ra) # 80002606 <wakeup>
}
    800069e0:	60a2                	ld	ra,8(sp)
    800069e2:	6402                	ld	s0,0(sp)
    800069e4:	0141                	addi	sp,sp,16
    800069e6:	8082                	ret
    panic("free_desc 1");
    800069e8:	00003517          	auipc	a0,0x3
    800069ec:	f1850513          	addi	a0,a0,-232 # 80009900 <syscalls+0x318>
    800069f0:	ffffa097          	auipc	ra,0xffffa
    800069f4:	b54080e7          	jalr	-1196(ra) # 80000544 <panic>
    panic("free_desc 2");
    800069f8:	00003517          	auipc	a0,0x3
    800069fc:	f1850513          	addi	a0,a0,-232 # 80009910 <syscalls+0x328>
    80006a00:	ffffa097          	auipc	ra,0xffffa
    80006a04:	b44080e7          	jalr	-1212(ra) # 80000544 <panic>

0000000080006a08 <virtio_disk_init>:
{
    80006a08:	1101                	addi	sp,sp,-32
    80006a0a:	ec06                	sd	ra,24(sp)
    80006a0c:	e822                	sd	s0,16(sp)
    80006a0e:	e426                	sd	s1,8(sp)
    80006a10:	e04a                	sd	s2,0(sp)
    80006a12:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006a14:	00003597          	auipc	a1,0x3
    80006a18:	f0c58593          	addi	a1,a1,-244 # 80009920 <syscalls+0x338>
    80006a1c:	0001f517          	auipc	a0,0x1f
    80006a20:	86450513          	addi	a0,a0,-1948 # 80025280 <disk+0x128>
    80006a24:	ffffa097          	auipc	ra,0xffffa
    80006a28:	136080e7          	jalr	310(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006a2c:	100017b7          	lui	a5,0x10001
    80006a30:	4398                	lw	a4,0(a5)
    80006a32:	2701                	sext.w	a4,a4
    80006a34:	747277b7          	lui	a5,0x74727
    80006a38:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006a3c:	14f71e63          	bne	a4,a5,80006b98 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006a40:	100017b7          	lui	a5,0x10001
    80006a44:	43dc                	lw	a5,4(a5)
    80006a46:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006a48:	4709                	li	a4,2
    80006a4a:	14e79763          	bne	a5,a4,80006b98 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006a4e:	100017b7          	lui	a5,0x10001
    80006a52:	479c                	lw	a5,8(a5)
    80006a54:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006a56:	14e79163          	bne	a5,a4,80006b98 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006a5a:	100017b7          	lui	a5,0x10001
    80006a5e:	47d8                	lw	a4,12(a5)
    80006a60:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006a62:	554d47b7          	lui	a5,0x554d4
    80006a66:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006a6a:	12f71763          	bne	a4,a5,80006b98 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a6e:	100017b7          	lui	a5,0x10001
    80006a72:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a76:	4705                	li	a4,1
    80006a78:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a7a:	470d                	li	a4,3
    80006a7c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006a7e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006a80:	c7ffe737          	lui	a4,0xc7ffe
    80006a84:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd8147>
    80006a88:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006a8a:	2701                	sext.w	a4,a4
    80006a8c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a8e:	472d                	li	a4,11
    80006a90:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006a92:	0707a903          	lw	s2,112(a5)
    80006a96:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006a98:	00897793          	andi	a5,s2,8
    80006a9c:	10078663          	beqz	a5,80006ba8 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006aa0:	100017b7          	lui	a5,0x10001
    80006aa4:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006aa8:	43fc                	lw	a5,68(a5)
    80006aaa:	2781                	sext.w	a5,a5
    80006aac:	10079663          	bnez	a5,80006bb8 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006ab0:	100017b7          	lui	a5,0x10001
    80006ab4:	5bdc                	lw	a5,52(a5)
    80006ab6:	2781                	sext.w	a5,a5
  if(max == 0)
    80006ab8:	10078863          	beqz	a5,80006bc8 <virtio_disk_init+0x1c0>
  if(max < NUM)
    80006abc:	471d                	li	a4,7
    80006abe:	10f77d63          	bgeu	a4,a5,80006bd8 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80006ac2:	ffffa097          	auipc	ra,0xffffa
    80006ac6:	038080e7          	jalr	56(ra) # 80000afa <kalloc>
    80006aca:	0001e497          	auipc	s1,0x1e
    80006ace:	68e48493          	addi	s1,s1,1678 # 80025158 <disk>
    80006ad2:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006ad4:	ffffa097          	auipc	ra,0xffffa
    80006ad8:	026080e7          	jalr	38(ra) # 80000afa <kalloc>
    80006adc:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80006ade:	ffffa097          	auipc	ra,0xffffa
    80006ae2:	01c080e7          	jalr	28(ra) # 80000afa <kalloc>
    80006ae6:	87aa                	mv	a5,a0
    80006ae8:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006aea:	6088                	ld	a0,0(s1)
    80006aec:	cd75                	beqz	a0,80006be8 <virtio_disk_init+0x1e0>
    80006aee:	0001e717          	auipc	a4,0x1e
    80006af2:	67273703          	ld	a4,1650(a4) # 80025160 <disk+0x8>
    80006af6:	cb6d                	beqz	a4,80006be8 <virtio_disk_init+0x1e0>
    80006af8:	cbe5                	beqz	a5,80006be8 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    80006afa:	6605                	lui	a2,0x1
    80006afc:	4581                	li	a1,0
    80006afe:	ffffa097          	auipc	ra,0xffffa
    80006b02:	1e8080e7          	jalr	488(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006b06:	0001e497          	auipc	s1,0x1e
    80006b0a:	65248493          	addi	s1,s1,1618 # 80025158 <disk>
    80006b0e:	6605                	lui	a2,0x1
    80006b10:	4581                	li	a1,0
    80006b12:	6488                	ld	a0,8(s1)
    80006b14:	ffffa097          	auipc	ra,0xffffa
    80006b18:	1d2080e7          	jalr	466(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    80006b1c:	6605                	lui	a2,0x1
    80006b1e:	4581                	li	a1,0
    80006b20:	6888                	ld	a0,16(s1)
    80006b22:	ffffa097          	auipc	ra,0xffffa
    80006b26:	1c4080e7          	jalr	452(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006b2a:	100017b7          	lui	a5,0x10001
    80006b2e:	4721                	li	a4,8
    80006b30:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006b32:	4098                	lw	a4,0(s1)
    80006b34:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006b38:	40d8                	lw	a4,4(s1)
    80006b3a:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80006b3e:	6498                	ld	a4,8(s1)
    80006b40:	0007069b          	sext.w	a3,a4
    80006b44:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006b48:	9701                	srai	a4,a4,0x20
    80006b4a:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80006b4e:	6898                	ld	a4,16(s1)
    80006b50:	0007069b          	sext.w	a3,a4
    80006b54:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006b58:	9701                	srai	a4,a4,0x20
    80006b5a:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80006b5e:	4685                	li	a3,1
    80006b60:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80006b62:	4705                	li	a4,1
    80006b64:	00d48c23          	sb	a3,24(s1)
    80006b68:	00e48ca3          	sb	a4,25(s1)
    80006b6c:	00e48d23          	sb	a4,26(s1)
    80006b70:	00e48da3          	sb	a4,27(s1)
    80006b74:	00e48e23          	sb	a4,28(s1)
    80006b78:	00e48ea3          	sb	a4,29(s1)
    80006b7c:	00e48f23          	sb	a4,30(s1)
    80006b80:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006b84:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006b88:	0727a823          	sw	s2,112(a5)
}
    80006b8c:	60e2                	ld	ra,24(sp)
    80006b8e:	6442                	ld	s0,16(sp)
    80006b90:	64a2                	ld	s1,8(sp)
    80006b92:	6902                	ld	s2,0(sp)
    80006b94:	6105                	addi	sp,sp,32
    80006b96:	8082                	ret
    panic("could not find virtio disk");
    80006b98:	00003517          	auipc	a0,0x3
    80006b9c:	d9850513          	addi	a0,a0,-616 # 80009930 <syscalls+0x348>
    80006ba0:	ffffa097          	auipc	ra,0xffffa
    80006ba4:	9a4080e7          	jalr	-1628(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006ba8:	00003517          	auipc	a0,0x3
    80006bac:	da850513          	addi	a0,a0,-600 # 80009950 <syscalls+0x368>
    80006bb0:	ffffa097          	auipc	ra,0xffffa
    80006bb4:	994080e7          	jalr	-1644(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80006bb8:	00003517          	auipc	a0,0x3
    80006bbc:	db850513          	addi	a0,a0,-584 # 80009970 <syscalls+0x388>
    80006bc0:	ffffa097          	auipc	ra,0xffffa
    80006bc4:	984080e7          	jalr	-1660(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80006bc8:	00003517          	auipc	a0,0x3
    80006bcc:	dc850513          	addi	a0,a0,-568 # 80009990 <syscalls+0x3a8>
    80006bd0:	ffffa097          	auipc	ra,0xffffa
    80006bd4:	974080e7          	jalr	-1676(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    80006bd8:	00003517          	auipc	a0,0x3
    80006bdc:	dd850513          	addi	a0,a0,-552 # 800099b0 <syscalls+0x3c8>
    80006be0:	ffffa097          	auipc	ra,0xffffa
    80006be4:	964080e7          	jalr	-1692(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    80006be8:	00003517          	auipc	a0,0x3
    80006bec:	de850513          	addi	a0,a0,-536 # 800099d0 <syscalls+0x3e8>
    80006bf0:	ffffa097          	auipc	ra,0xffffa
    80006bf4:	954080e7          	jalr	-1708(ra) # 80000544 <panic>

0000000080006bf8 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006bf8:	7159                	addi	sp,sp,-112
    80006bfa:	f486                	sd	ra,104(sp)
    80006bfc:	f0a2                	sd	s0,96(sp)
    80006bfe:	eca6                	sd	s1,88(sp)
    80006c00:	e8ca                	sd	s2,80(sp)
    80006c02:	e4ce                	sd	s3,72(sp)
    80006c04:	e0d2                	sd	s4,64(sp)
    80006c06:	fc56                	sd	s5,56(sp)
    80006c08:	f85a                	sd	s6,48(sp)
    80006c0a:	f45e                	sd	s7,40(sp)
    80006c0c:	f062                	sd	s8,32(sp)
    80006c0e:	ec66                	sd	s9,24(sp)
    80006c10:	e86a                	sd	s10,16(sp)
    80006c12:	1880                	addi	s0,sp,112
    80006c14:	892a                	mv	s2,a0
    80006c16:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006c18:	00c52c83          	lw	s9,12(a0)
    80006c1c:	001c9c9b          	slliw	s9,s9,0x1
    80006c20:	1c82                	slli	s9,s9,0x20
    80006c22:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006c26:	0001e517          	auipc	a0,0x1e
    80006c2a:	65a50513          	addi	a0,a0,1626 # 80025280 <disk+0x128>
    80006c2e:	ffffa097          	auipc	ra,0xffffa
    80006c32:	fbc080e7          	jalr	-68(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    80006c36:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006c38:	4ba1                	li	s7,8
      disk.free[i] = 0;
    80006c3a:	0001eb17          	auipc	s6,0x1e
    80006c3e:	51eb0b13          	addi	s6,s6,1310 # 80025158 <disk>
  for(int i = 0; i < 3; i++){
    80006c42:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006c44:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006c46:	0001ec17          	auipc	s8,0x1e
    80006c4a:	63ac0c13          	addi	s8,s8,1594 # 80025280 <disk+0x128>
    80006c4e:	a8b5                	j	80006cca <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    80006c50:	00fb06b3          	add	a3,s6,a5
    80006c54:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006c58:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006c5a:	0207c563          	bltz	a5,80006c84 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006c5e:	2485                	addiw	s1,s1,1
    80006c60:	0711                	addi	a4,a4,4
    80006c62:	1f548a63          	beq	s1,s5,80006e56 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    80006c66:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006c68:	0001e697          	auipc	a3,0x1e
    80006c6c:	4f068693          	addi	a3,a3,1264 # 80025158 <disk>
    80006c70:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006c72:	0186c583          	lbu	a1,24(a3)
    80006c76:	fde9                	bnez	a1,80006c50 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006c78:	2785                	addiw	a5,a5,1
    80006c7a:	0685                	addi	a3,a3,1
    80006c7c:	ff779be3          	bne	a5,s7,80006c72 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006c80:	57fd                	li	a5,-1
    80006c82:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006c84:	02905a63          	blez	s1,80006cb8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006c88:	f9042503          	lw	a0,-112(s0)
    80006c8c:	00000097          	auipc	ra,0x0
    80006c90:	cfa080e7          	jalr	-774(ra) # 80006986 <free_desc>
      for(int j = 0; j < i; j++)
    80006c94:	4785                	li	a5,1
    80006c96:	0297d163          	bge	a5,s1,80006cb8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006c9a:	f9442503          	lw	a0,-108(s0)
    80006c9e:	00000097          	auipc	ra,0x0
    80006ca2:	ce8080e7          	jalr	-792(ra) # 80006986 <free_desc>
      for(int j = 0; j < i; j++)
    80006ca6:	4789                	li	a5,2
    80006ca8:	0097d863          	bge	a5,s1,80006cb8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006cac:	f9842503          	lw	a0,-104(s0)
    80006cb0:	00000097          	auipc	ra,0x0
    80006cb4:	cd6080e7          	jalr	-810(ra) # 80006986 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006cb8:	85e2                	mv	a1,s8
    80006cba:	0001e517          	auipc	a0,0x1e
    80006cbe:	4b650513          	addi	a0,a0,1206 # 80025170 <disk+0x18>
    80006cc2:	ffffb097          	auipc	ra,0xffffb
    80006cc6:	794080e7          	jalr	1940(ra) # 80002456 <sleep>
  for(int i = 0; i < 3; i++){
    80006cca:	f9040713          	addi	a4,s0,-112
    80006cce:	84ce                	mv	s1,s3
    80006cd0:	bf59                	j	80006c66 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006cd2:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    80006cd6:	00479693          	slli	a3,a5,0x4
    80006cda:	0001e797          	auipc	a5,0x1e
    80006cde:	47e78793          	addi	a5,a5,1150 # 80025158 <disk>
    80006ce2:	97b6                	add	a5,a5,a3
    80006ce4:	4685                	li	a3,1
    80006ce6:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006ce8:	0001e597          	auipc	a1,0x1e
    80006cec:	47058593          	addi	a1,a1,1136 # 80025158 <disk>
    80006cf0:	00a60793          	addi	a5,a2,10
    80006cf4:	0792                	slli	a5,a5,0x4
    80006cf6:	97ae                	add	a5,a5,a1
    80006cf8:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    80006cfc:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006d00:	f6070693          	addi	a3,a4,-160
    80006d04:	619c                	ld	a5,0(a1)
    80006d06:	97b6                	add	a5,a5,a3
    80006d08:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006d0a:	6188                	ld	a0,0(a1)
    80006d0c:	96aa                	add	a3,a3,a0
    80006d0e:	47c1                	li	a5,16
    80006d10:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006d12:	4785                	li	a5,1
    80006d14:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006d18:	f9442783          	lw	a5,-108(s0)
    80006d1c:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006d20:	0792                	slli	a5,a5,0x4
    80006d22:	953e                	add	a0,a0,a5
    80006d24:	05890693          	addi	a3,s2,88
    80006d28:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    80006d2a:	6188                	ld	a0,0(a1)
    80006d2c:	97aa                	add	a5,a5,a0
    80006d2e:	40000693          	li	a3,1024
    80006d32:	c794                	sw	a3,8(a5)
  if(write)
    80006d34:	100d0d63          	beqz	s10,80006e4e <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006d38:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006d3c:	00c7d683          	lhu	a3,12(a5)
    80006d40:	0016e693          	ori	a3,a3,1
    80006d44:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    80006d48:	f9842583          	lw	a1,-104(s0)
    80006d4c:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006d50:	0001e697          	auipc	a3,0x1e
    80006d54:	40868693          	addi	a3,a3,1032 # 80025158 <disk>
    80006d58:	00260793          	addi	a5,a2,2
    80006d5c:	0792                	slli	a5,a5,0x4
    80006d5e:	97b6                	add	a5,a5,a3
    80006d60:	587d                	li	a6,-1
    80006d62:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006d66:	0592                	slli	a1,a1,0x4
    80006d68:	952e                	add	a0,a0,a1
    80006d6a:	f9070713          	addi	a4,a4,-112
    80006d6e:	9736                	add	a4,a4,a3
    80006d70:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    80006d72:	6298                	ld	a4,0(a3)
    80006d74:	972e                	add	a4,a4,a1
    80006d76:	4585                	li	a1,1
    80006d78:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006d7a:	4509                	li	a0,2
    80006d7c:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    80006d80:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006d84:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006d88:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006d8c:	6698                	ld	a4,8(a3)
    80006d8e:	00275783          	lhu	a5,2(a4)
    80006d92:	8b9d                	andi	a5,a5,7
    80006d94:	0786                	slli	a5,a5,0x1
    80006d96:	97ba                	add	a5,a5,a4
    80006d98:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    80006d9c:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006da0:	6698                	ld	a4,8(a3)
    80006da2:	00275783          	lhu	a5,2(a4)
    80006da6:	2785                	addiw	a5,a5,1
    80006da8:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006dac:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006db0:	100017b7          	lui	a5,0x10001
    80006db4:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006db8:	00492703          	lw	a4,4(s2)
    80006dbc:	4785                	li	a5,1
    80006dbe:	02f71163          	bne	a4,a5,80006de0 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    80006dc2:	0001e997          	auipc	s3,0x1e
    80006dc6:	4be98993          	addi	s3,s3,1214 # 80025280 <disk+0x128>
  while(b->disk == 1) {
    80006dca:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006dcc:	85ce                	mv	a1,s3
    80006dce:	854a                	mv	a0,s2
    80006dd0:	ffffb097          	auipc	ra,0xffffb
    80006dd4:	686080e7          	jalr	1670(ra) # 80002456 <sleep>
  while(b->disk == 1) {
    80006dd8:	00492783          	lw	a5,4(s2)
    80006ddc:	fe9788e3          	beq	a5,s1,80006dcc <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    80006de0:	f9042903          	lw	s2,-112(s0)
    80006de4:	00290793          	addi	a5,s2,2
    80006de8:	00479713          	slli	a4,a5,0x4
    80006dec:	0001e797          	auipc	a5,0x1e
    80006df0:	36c78793          	addi	a5,a5,876 # 80025158 <disk>
    80006df4:	97ba                	add	a5,a5,a4
    80006df6:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006dfa:	0001e997          	auipc	s3,0x1e
    80006dfe:	35e98993          	addi	s3,s3,862 # 80025158 <disk>
    80006e02:	00491713          	slli	a4,s2,0x4
    80006e06:	0009b783          	ld	a5,0(s3)
    80006e0a:	97ba                	add	a5,a5,a4
    80006e0c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006e10:	854a                	mv	a0,s2
    80006e12:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006e16:	00000097          	auipc	ra,0x0
    80006e1a:	b70080e7          	jalr	-1168(ra) # 80006986 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006e1e:	8885                	andi	s1,s1,1
    80006e20:	f0ed                	bnez	s1,80006e02 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006e22:	0001e517          	auipc	a0,0x1e
    80006e26:	45e50513          	addi	a0,a0,1118 # 80025280 <disk+0x128>
    80006e2a:	ffffa097          	auipc	ra,0xffffa
    80006e2e:	e74080e7          	jalr	-396(ra) # 80000c9e <release>
}
    80006e32:	70a6                	ld	ra,104(sp)
    80006e34:	7406                	ld	s0,96(sp)
    80006e36:	64e6                	ld	s1,88(sp)
    80006e38:	6946                	ld	s2,80(sp)
    80006e3a:	69a6                	ld	s3,72(sp)
    80006e3c:	6a06                	ld	s4,64(sp)
    80006e3e:	7ae2                	ld	s5,56(sp)
    80006e40:	7b42                	ld	s6,48(sp)
    80006e42:	7ba2                	ld	s7,40(sp)
    80006e44:	7c02                	ld	s8,32(sp)
    80006e46:	6ce2                	ld	s9,24(sp)
    80006e48:	6d42                	ld	s10,16(sp)
    80006e4a:	6165                	addi	sp,sp,112
    80006e4c:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006e4e:	4689                	li	a3,2
    80006e50:	00d79623          	sh	a3,12(a5)
    80006e54:	b5e5                	j	80006d3c <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006e56:	f9042603          	lw	a2,-112(s0)
    80006e5a:	00a60713          	addi	a4,a2,10
    80006e5e:	0712                	slli	a4,a4,0x4
    80006e60:	0001e517          	auipc	a0,0x1e
    80006e64:	30050513          	addi	a0,a0,768 # 80025160 <disk+0x8>
    80006e68:	953a                	add	a0,a0,a4
  if(write)
    80006e6a:	e60d14e3          	bnez	s10,80006cd2 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006e6e:	00a60793          	addi	a5,a2,10
    80006e72:	00479693          	slli	a3,a5,0x4
    80006e76:	0001e797          	auipc	a5,0x1e
    80006e7a:	2e278793          	addi	a5,a5,738 # 80025158 <disk>
    80006e7e:	97b6                	add	a5,a5,a3
    80006e80:	0007a423          	sw	zero,8(a5)
    80006e84:	b595                	j	80006ce8 <virtio_disk_rw+0xf0>

0000000080006e86 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006e86:	1101                	addi	sp,sp,-32
    80006e88:	ec06                	sd	ra,24(sp)
    80006e8a:	e822                	sd	s0,16(sp)
    80006e8c:	e426                	sd	s1,8(sp)
    80006e8e:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006e90:	0001e497          	auipc	s1,0x1e
    80006e94:	2c848493          	addi	s1,s1,712 # 80025158 <disk>
    80006e98:	0001e517          	auipc	a0,0x1e
    80006e9c:	3e850513          	addi	a0,a0,1000 # 80025280 <disk+0x128>
    80006ea0:	ffffa097          	auipc	ra,0xffffa
    80006ea4:	d4a080e7          	jalr	-694(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006ea8:	10001737          	lui	a4,0x10001
    80006eac:	533c                	lw	a5,96(a4)
    80006eae:	8b8d                	andi	a5,a5,3
    80006eb0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006eb2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006eb6:	689c                	ld	a5,16(s1)
    80006eb8:	0204d703          	lhu	a4,32(s1)
    80006ebc:	0027d783          	lhu	a5,2(a5)
    80006ec0:	04f70863          	beq	a4,a5,80006f10 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006ec4:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006ec8:	6898                	ld	a4,16(s1)
    80006eca:	0204d783          	lhu	a5,32(s1)
    80006ece:	8b9d                	andi	a5,a5,7
    80006ed0:	078e                	slli	a5,a5,0x3
    80006ed2:	97ba                	add	a5,a5,a4
    80006ed4:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006ed6:	00278713          	addi	a4,a5,2
    80006eda:	0712                	slli	a4,a4,0x4
    80006edc:	9726                	add	a4,a4,s1
    80006ede:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006ee2:	e721                	bnez	a4,80006f2a <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006ee4:	0789                	addi	a5,a5,2
    80006ee6:	0792                	slli	a5,a5,0x4
    80006ee8:	97a6                	add	a5,a5,s1
    80006eea:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006eec:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006ef0:	ffffb097          	auipc	ra,0xffffb
    80006ef4:	716080e7          	jalr	1814(ra) # 80002606 <wakeup>

    disk.used_idx += 1;
    80006ef8:	0204d783          	lhu	a5,32(s1)
    80006efc:	2785                	addiw	a5,a5,1
    80006efe:	17c2                	slli	a5,a5,0x30
    80006f00:	93c1                	srli	a5,a5,0x30
    80006f02:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006f06:	6898                	ld	a4,16(s1)
    80006f08:	00275703          	lhu	a4,2(a4)
    80006f0c:	faf71ce3          	bne	a4,a5,80006ec4 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006f10:	0001e517          	auipc	a0,0x1e
    80006f14:	37050513          	addi	a0,a0,880 # 80025280 <disk+0x128>
    80006f18:	ffffa097          	auipc	ra,0xffffa
    80006f1c:	d86080e7          	jalr	-634(ra) # 80000c9e <release>
}
    80006f20:	60e2                	ld	ra,24(sp)
    80006f22:	6442                	ld	s0,16(sp)
    80006f24:	64a2                	ld	s1,8(sp)
    80006f26:	6105                	addi	sp,sp,32
    80006f28:	8082                	ret
      panic("virtio_disk_intr status");
    80006f2a:	00003517          	auipc	a0,0x3
    80006f2e:	abe50513          	addi	a0,a0,-1346 # 800099e8 <syscalls+0x400>
    80006f32:	ffff9097          	auipc	ra,0xffff9
    80006f36:	612080e7          	jalr	1554(ra) # 80000544 <panic>

0000000080006f3a <sgenrand>:
static int mti=N+1; /* mti==N+1 means mt[N] is not initialized */

/* initializing the array with a NONZERO seed */
void
sgenrand(unsigned long seed)
{
    80006f3a:	1141                	addi	sp,sp,-16
    80006f3c:	e422                	sd	s0,8(sp)
    80006f3e:	0800                	addi	s0,sp,16
    /* setting initial seeds to mt[N] using         */
    /* the generator Line 25 of Table 1 in          */
    /* [KNUTH 1981, The Art of Computer Programming */
    /*    Vol. 2 (2nd Ed.), pp102]                  */
    mt[0]= seed & 0xffffffff;
    80006f40:	0001e717          	auipc	a4,0x1e
    80006f44:	35870713          	addi	a4,a4,856 # 80025298 <mt>
    80006f48:	1502                	slli	a0,a0,0x20
    80006f4a:	9101                	srli	a0,a0,0x20
    80006f4c:	e308                	sd	a0,0(a4)
    for (mti=1; mti<N; mti++)
    80006f4e:	0001f597          	auipc	a1,0x1f
    80006f52:	6c258593          	addi	a1,a1,1730 # 80026610 <mt+0x1378>
        mt[mti] = (69069 * mt[mti-1]) & 0xffffffff;
    80006f56:	6645                	lui	a2,0x11
    80006f58:	dcd60613          	addi	a2,a2,-563 # 10dcd <_entry-0x7ffef233>
    80006f5c:	56fd                	li	a3,-1
    80006f5e:	9281                	srli	a3,a3,0x20
    80006f60:	631c                	ld	a5,0(a4)
    80006f62:	02c787b3          	mul	a5,a5,a2
    80006f66:	8ff5                	and	a5,a5,a3
    80006f68:	e71c                	sd	a5,8(a4)
    for (mti=1; mti<N; mti++)
    80006f6a:	0721                	addi	a4,a4,8
    80006f6c:	feb71ae3          	bne	a4,a1,80006f60 <sgenrand+0x26>
    80006f70:	27000793          	li	a5,624
    80006f74:	00003717          	auipc	a4,0x3
    80006f78:	aaf72223          	sw	a5,-1372(a4) # 80009a18 <mti>
}
    80006f7c:	6422                	ld	s0,8(sp)
    80006f7e:	0141                	addi	sp,sp,16
    80006f80:	8082                	ret

0000000080006f82 <genrand>:

long /* for integer generation */
genrand()
{
    80006f82:	1141                	addi	sp,sp,-16
    80006f84:	e406                	sd	ra,8(sp)
    80006f86:	e022                	sd	s0,0(sp)
    80006f88:	0800                	addi	s0,sp,16
    unsigned long y;
    static unsigned long mag01[2]={0x0, MATRIX_A};
    /* mag01[x] = x * MATRIX_A  for x=0,1 */

    if (mti >= N) { /* generate N words at one time */
    80006f8a:	00003797          	auipc	a5,0x3
    80006f8e:	a8e7a783          	lw	a5,-1394(a5) # 80009a18 <mti>
    80006f92:	26f00713          	li	a4,623
    80006f96:	0ef75963          	bge	a4,a5,80007088 <genrand+0x106>
        int kk;

        if (mti == N+1)   /* if sgenrand() has not been called, */
    80006f9a:	27100713          	li	a4,625
    80006f9e:	12e78f63          	beq	a5,a4,800070dc <genrand+0x15a>
            sgenrand(4357); /* a default initial seed is used   */

        for (kk=0;kk<N-M;kk++) {
    80006fa2:	0001e817          	auipc	a6,0x1e
    80006fa6:	2f680813          	addi	a6,a6,758 # 80025298 <mt>
    80006faa:	0001fe17          	auipc	t3,0x1f
    80006fae:	a06e0e13          	addi	t3,t3,-1530 # 800259b0 <mt+0x718>
{
    80006fb2:	8742                	mv	a4,a6
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    80006fb4:	4885                	li	a7,1
    80006fb6:	08fe                	slli	a7,a7,0x1f
    80006fb8:	80000537          	lui	a0,0x80000
    80006fbc:	fff54513          	not	a0,a0
            mt[kk] = mt[kk+M] ^ (y >> 1) ^ mag01[y & 0x1];
    80006fc0:	6585                	lui	a1,0x1
    80006fc2:	c6858593          	addi	a1,a1,-920 # c68 <_entry-0x7ffff398>
    80006fc6:	00003317          	auipc	t1,0x3
    80006fca:	a3a30313          	addi	t1,t1,-1478 # 80009a00 <mag01.985>
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    80006fce:	631c                	ld	a5,0(a4)
    80006fd0:	0117f7b3          	and	a5,a5,a7
    80006fd4:	6714                	ld	a3,8(a4)
    80006fd6:	8ee9                	and	a3,a3,a0
    80006fd8:	8fd5                	or	a5,a5,a3
            mt[kk] = mt[kk+M] ^ (y >> 1) ^ mag01[y & 0x1];
    80006fda:	00b70633          	add	a2,a4,a1
    80006fde:	0017d693          	srli	a3,a5,0x1
    80006fe2:	6210                	ld	a2,0(a2)
    80006fe4:	8eb1                	xor	a3,a3,a2
    80006fe6:	8b85                	andi	a5,a5,1
    80006fe8:	078e                	slli	a5,a5,0x3
    80006fea:	979a                	add	a5,a5,t1
    80006fec:	639c                	ld	a5,0(a5)
    80006fee:	8fb5                	xor	a5,a5,a3
    80006ff0:	e31c                	sd	a5,0(a4)
        for (kk=0;kk<N-M;kk++) {
    80006ff2:	0721                	addi	a4,a4,8
    80006ff4:	fdc71de3          	bne	a4,t3,80006fce <genrand+0x4c>
        }
        for (;kk<N-1;kk++) {
    80006ff8:	6605                	lui	a2,0x1
    80006ffa:	c6060613          	addi	a2,a2,-928 # c60 <_entry-0x7ffff3a0>
    80006ffe:	9642                	add	a2,a2,a6
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    80007000:	4505                	li	a0,1
    80007002:	057e                	slli	a0,a0,0x1f
    80007004:	800005b7          	lui	a1,0x80000
    80007008:	fff5c593          	not	a1,a1
            mt[kk] = mt[kk+(M-N)] ^ (y >> 1) ^ mag01[y & 0x1];
    8000700c:	00003897          	auipc	a7,0x3
    80007010:	9f488893          	addi	a7,a7,-1548 # 80009a00 <mag01.985>
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    80007014:	71883783          	ld	a5,1816(a6)
    80007018:	8fe9                	and	a5,a5,a0
    8000701a:	72083703          	ld	a4,1824(a6)
    8000701e:	8f6d                	and	a4,a4,a1
    80007020:	8fd9                	or	a5,a5,a4
            mt[kk] = mt[kk+(M-N)] ^ (y >> 1) ^ mag01[y & 0x1];
    80007022:	0017d713          	srli	a4,a5,0x1
    80007026:	00083683          	ld	a3,0(a6)
    8000702a:	8f35                	xor	a4,a4,a3
    8000702c:	8b85                	andi	a5,a5,1
    8000702e:	078e                	slli	a5,a5,0x3
    80007030:	97c6                	add	a5,a5,a7
    80007032:	639c                	ld	a5,0(a5)
    80007034:	8fb9                	xor	a5,a5,a4
    80007036:	70f83c23          	sd	a5,1816(a6)
        for (;kk<N-1;kk++) {
    8000703a:	0821                	addi	a6,a6,8
    8000703c:	fcc81ce3          	bne	a6,a2,80007014 <genrand+0x92>
        }
        y = (mt[N-1]&UPPER_MASK)|(mt[0]&LOWER_MASK);
    80007040:	0001f697          	auipc	a3,0x1f
    80007044:	25868693          	addi	a3,a3,600 # 80026298 <mt+0x1000>
    80007048:	3786b783          	ld	a5,888(a3)
    8000704c:	4705                	li	a4,1
    8000704e:	077e                	slli	a4,a4,0x1f
    80007050:	8ff9                	and	a5,a5,a4
    80007052:	0001e717          	auipc	a4,0x1e
    80007056:	24673703          	ld	a4,582(a4) # 80025298 <mt>
    8000705a:	1706                	slli	a4,a4,0x21
    8000705c:	9305                	srli	a4,a4,0x21
    8000705e:	8fd9                	or	a5,a5,a4
        mt[N-1] = mt[M-1] ^ (y >> 1) ^ mag01[y & 0x1];
    80007060:	0017d713          	srli	a4,a5,0x1
    80007064:	c606b603          	ld	a2,-928(a3)
    80007068:	8f31                	xor	a4,a4,a2
    8000706a:	8b85                	andi	a5,a5,1
    8000706c:	078e                	slli	a5,a5,0x3
    8000706e:	00003617          	auipc	a2,0x3
    80007072:	99260613          	addi	a2,a2,-1646 # 80009a00 <mag01.985>
    80007076:	97b2                	add	a5,a5,a2
    80007078:	639c                	ld	a5,0(a5)
    8000707a:	8fb9                	xor	a5,a5,a4
    8000707c:	36f6bc23          	sd	a5,888(a3)

        mti = 0;
    80007080:	00003797          	auipc	a5,0x3
    80007084:	9807ac23          	sw	zero,-1640(a5) # 80009a18 <mti>
    }
  
    y = mt[mti++];
    80007088:	00003717          	auipc	a4,0x3
    8000708c:	99070713          	addi	a4,a4,-1648 # 80009a18 <mti>
    80007090:	431c                	lw	a5,0(a4)
    80007092:	0017869b          	addiw	a3,a5,1
    80007096:	c314                	sw	a3,0(a4)
    80007098:	078e                	slli	a5,a5,0x3
    8000709a:	0001e717          	auipc	a4,0x1e
    8000709e:	1fe70713          	addi	a4,a4,510 # 80025298 <mt>
    800070a2:	97ba                	add	a5,a5,a4
    800070a4:	6398                	ld	a4,0(a5)
    y ^= TEMPERING_SHIFT_U(y);
    800070a6:	00b75793          	srli	a5,a4,0xb
    800070aa:	8f3d                	xor	a4,a4,a5
    y ^= TEMPERING_SHIFT_S(y) & TEMPERING_MASK_B;
    800070ac:	013a67b7          	lui	a5,0x13a6
    800070b0:	8ad78793          	addi	a5,a5,-1875 # 13a58ad <_entry-0x7ec5a753>
    800070b4:	8ff9                	and	a5,a5,a4
    800070b6:	079e                	slli	a5,a5,0x7
    800070b8:	8fb9                	xor	a5,a5,a4
    y ^= TEMPERING_SHIFT_T(y) & TEMPERING_MASK_C;
    800070ba:	00f79713          	slli	a4,a5,0xf
    800070be:	077e36b7          	lui	a3,0x77e3
    800070c2:	0696                	slli	a3,a3,0x5
    800070c4:	8f75                	and	a4,a4,a3
    800070c6:	8fb9                	xor	a5,a5,a4
    y ^= TEMPERING_SHIFT_L(y);
    800070c8:	0127d513          	srli	a0,a5,0x12
    800070cc:	8fa9                	xor	a5,a5,a0

    // Strip off uppermost bit because we want a long,
    // not an unsigned long
    return y & RAND_MAX;
    800070ce:	02179513          	slli	a0,a5,0x21
}
    800070d2:	9105                	srli	a0,a0,0x21
    800070d4:	60a2                	ld	ra,8(sp)
    800070d6:	6402                	ld	s0,0(sp)
    800070d8:	0141                	addi	sp,sp,16
    800070da:	8082                	ret
            sgenrand(4357); /* a default initial seed is used   */
    800070dc:	6505                	lui	a0,0x1
    800070de:	10550513          	addi	a0,a0,261 # 1105 <_entry-0x7fffeefb>
    800070e2:	00000097          	auipc	ra,0x0
    800070e6:	e58080e7          	jalr	-424(ra) # 80006f3a <sgenrand>
    800070ea:	bd65                	j	80006fa2 <genrand+0x20>

00000000800070ec <random>:

// Assumes 0 <= max <= RAND_MAX
// Returns in the half-open interval [0, max]
long random(long max) {
    800070ec:	1101                	addi	sp,sp,-32
    800070ee:	ec06                	sd	ra,24(sp)
    800070f0:	e822                	sd	s0,16(sp)
    800070f2:	e426                	sd	s1,8(sp)
    800070f4:	1000                	addi	s0,sp,32
    800070f6:	84aa                	mv	s1,a0
    unsigned long random = (unsigned long)((long)genrand() % (max + 1)); 
    800070f8:	00000097          	auipc	ra,0x0
    800070fc:	e8a080e7          	jalr	-374(ra) # 80006f82 <genrand>
    80007100:	0485                	addi	s1,s1,1
    return random;
    80007102:	02956533          	rem	a0,a0,s1
    80007106:	60e2                	ld	ra,24(sp)
    80007108:	6442                	ld	s0,16(sp)
    8000710a:	64a2                	ld	s1,8(sp)
    8000710c:	6105                	addi	sp,sp,32
    8000710e:	8082                	ret
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
