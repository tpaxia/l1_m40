// Standalone testbench for the UCY805 / MB15652 bus arbiter model.
// Checks the model against BOTH documented sequences:
//   * disk "test 13 — BUS ARBITER TEST"  (re/UCY805_bus_arbiter.md, image 0x6ce1c)
//   * the ROM power-on arbiter test       (boot ROM 0x02AA..0x032E, traced)
// The Arbiter struct is written exactly as it will be ported into
// src/mame/olivetti/m40.cpp.  In MAME the NVI is delayed by a one-shot timer
// (grant -> +50us -> NVI); here the delay is irrelevant, we only check the grant
// logic and the 0xff81 status the ROM reads.
//
// build:  c++ -std=c++17 -O0 -Wall arb_tb.cpp -o arb_tb && ./arb_tb

#include <cstdio>
#include <cstdint>

//========================= arbiter model (portable) =========================
struct Arbiter
{
	uint8_t req = 0;    // pending channel requests   (bit0=ch0 .. bit3=ch3)
	uint8_t grant = 0;  // channels currently granted (bit0=ch0 .. bit3=ch3)
	uint8_t rel = 0;    // release level from 0xFF8D/8E/8F (and 0xFF85/86/87)

	void reset() { req = grant = rel = 0; }

	// Priority ch0 > ch1 > ch2 > ch3: chN is granted only once requested AND the
	// release level has reached N (ch0 at level 0, ch1 needs 0xFF8D, ch2 8D+8E,
	// ch3 8D+8E+8F). Grants accumulate; they are cleared by the per-channel ack.
	void update()
	{
		uint8_t g = 0;
		for (int ch = 0; ch < 4; ch++)
			if ((req >> ch & 1) && rel >= ch)
				g |= (1 << ch);
		grant = g;
	}
	bool nvi() const { return grant != 0; }   // (delayed in MAME by a timer)

	uint8_t read(uint16_t port)
	{
		uint8_t reg = port & 0x0f;
		if (reg == 1)   // 0xFF81: grant bitmap high nibble, idle/active low nibble
		{
			uint8_t hi = ((grant >> 0 & 1) ? 0x80 : 0) | ((grant >> 1 & 1) ? 0x40 : 0)
			           | ((grant >> 2 & 1) ? 0x20 : 0) | ((grant >> 3 & 1) ? 0x10 : 0);
			return hi | (grant ? 0x08 : 0x0f);
		}
		return 0;
	}

	void write(uint16_t port, uint8_t /*data*/)
	{
		uint8_t reg = port & 0x0f;
		switch (reg)
		{
		case 0x0: case 0x1: case 0x2: case 0x3:      // ack/clear channel reg
			req &= ~(1 << reg);
			if (req == 0) rel = 0;                    // idle -> reset release level
			break;
		case 0x8: case 0x9: case 0xa: case 0xb:      // request channel reg-8
			req |= (1 << (reg - 8));
			break;
		case 0x5: case 0xd: if (rel < 1) rel = 1; break;   // release ch1
		case 0x6: case 0xe: if (rel < 2) rel = 2; break;   // release ch2
		case 0x7: case 0xf: if (rel < 3) rel = 3; break;   // release ch3
		default: break;                              // 0xFF84 / 0xFF8C: boot bus gate
		}
		update();
	}
	// NVI-acknowledge (vector fetch) clears only the interrupt line, NOT the grant,
	// so the disk handler can still read 0xff81 to identify the channel.
};

//========================= harness =========================
static Arbiter arb;
static int flag[5];           // disk-test per-channel software flags
static int fails = 0;

static void wr(uint16_t p) { arb.write(p, 0); }
static uint8_t rd(uint16_t p) { return arb.read(p); }

// disk NVI handler (image 0x6cd94): read 0xff81, branch on high nibble, ack channel
static void disk_isr()
{
	while (arb.nvi())
	{
		uint8_t st = rd(0xff81) & 0xf0;
		if      (st == 0x90) { flag[4]=1; wr(0xff80); wr(0xff81); wr(0xff82); wr(0xff83); }
		else if (st == 0x80) { flag[0]=1; wr(0xff80); }
		else if (st == 0x40) { flag[1]=1; wr(0xff81); }
		else if (st == 0x20) { flag[2]=1; wr(0xff82); }
		else if (st == 0x10) { flag[3]=1; wr(0xff83); }
		else return;
	}
}

static void expect81(uint8_t want, const char *what)
{
	uint8_t got = rd(0xff81);
	printf("  0xff81 %-30s want=%02X got=%02X  %s\n", what, want, got,
	       got == want ? "OK" : "*** FAIL ***");
	if (got != want) fails++;
}
static void expect(int cond, const char *what)
{
	printf("  %-37s %s\n", what, cond ? "OK" : "*** FAIL ***");
	if (!cond) fails++;
}

static void disk_test13()
{
	printf("=== disk test 13 (setup 0x6ce1c) ===\n");
	arb.reset();
	for (int i = 0; i < 5; i++) flag[i] = 0;
	wr(0xff8d); wr(0xff8e); wr(0xff8f);
	wr(0xff80); wr(0xff81); wr(0xff82); wr(0xff83);
	expect81(0x0f, "after ack all (idle)");
	wr(0xff88); wr(0xff89); wr(0xff8a); wr(0xff8b);
	wr(0xff85); wr(0xff86); wr(0xff87);
	expect81(0xf8, "after request all + release");
	wr(0xff80); wr(0xff81); wr(0xff82); wr(0xff83);
	for (int i = 0; i < 5; i++) flag[i] = 0;

	printf("=== disk test 13 (grant/priority body) ===\n");
	wr(0xff88); disk_isr();                    expect(flag[0]==1, "ch0 granted        (else 0x002d)");
	wr(0xff89); disk_isr();                    expect(flag[1]==0, "ch1 not-yet        (else 0x002e)");
	wr(0xff8d); disk_isr();                    expect(flag[1]==1, "ch1 granted        (else 0x002f)");
	wr(0xff8a); disk_isr();                    expect(flag[2]==0, "ch2 not-yet        (else 0x0030)");
	wr(0xff8d); wr(0xff8e); disk_isr();        expect(flag[2]==1, "ch2 granted        (else 0x0031)");
	wr(0xff8b); disk_isr();                    expect(flag[3]==0, "ch3 not-yet        (else 0x0032)");
	wr(0xff8d); wr(0xff8e); wr(0xff8f); disk_isr(); expect(flag[3]==1, "ch3 granted   (else 0x0033)");
}

// Power-on test (ROM 0x02AA..0x032E). Each step programs a request+release and
// spins on `ei nvi`; the ROM's minimal handler only advances, it does NOT ack, so
// grants accumulate until the four acks at the end. The invariant the ROM relies
// on: after each step's request+release an NVI must be pending (grant != 0).
static void poweron_test()
{
	printf("=== power-on arbiter test (ROM 0x02AA) ===\n");
	arb.reset();
	// setup block 0x02AA..0x02E2 (interleaved request/release/ack), NVI on
	wr(0xff80);
	wr(0xff89); wr(0xff8a); wr(0xff8b);       // request ch1,2,3
	wr(0xff85);                                // release ch1
	wr(0xff81); wr(0xff86); wr(0xff8d);        // ack ch1, release ch2
	wr(0xff82); wr(0xff87); wr(0xff8e);        // ack ch2, release ch3
	wr(0xff83); wr(0xff8f);                    // ack ch3
	// step A: request ch3 -> must grant (rel already 3)
	wr(0xff8b);                    expect(arb.nvi() && (arb.grant & 0x8), "step A ch3 grant -> NVI");
	// step B: request ch2 + release
	wr(0xff8a); wr(0xff87);        expect(arb.nvi() && (arb.grant & 0x4), "step B ch2 grant -> NVI");
	// step C: request ch1 + release
	wr(0xff89); wr(0xff86);        expect(arb.nvi() && (arb.grant & 0x2), "step C ch1 grant -> NVI");
	// step D: request ch0 + release
	wr(0xff88); wr(0xff85);        expect(arb.nvi() && (arb.grant & 0x1), "step D ch0 grant -> NVI");
	// final acks clear everything
	wr(0xff80); wr(0xff81); wr(0xff82); wr(0xff83);
	expect(!arb.nvi() && arb.grant == 0, "after final acks: idle, no NVI");
	expect81(0x0f, "final 0xff81 idle");
}

int main()
{
	disk_test13();
	poweron_test();
	printf("\n%s (%d failure%s)\n", fails ? "FAILED" : "PASSED", fails, fails==1?"":"s");
	return fails ? 1 : 0;
}
