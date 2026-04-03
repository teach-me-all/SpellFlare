// Unit tests for coin submission anti-cheat logic
// Uses Firebase Emulator for integration tests - these are pure logic tests

describe("Coin submission validation", () => {
  const MAX_BATCH_DELTA = 500;

  function validateDelta(delta: number): { valid: boolean; reason?: string } {
    if (!Number.isInteger(delta) || delta <= 0 || delta > MAX_BATCH_DELTA) {
      return { valid: false, reason: `Delta must be 1-${MAX_BATCH_DELTA}` };
    }
    return { valid: true };
  }

  it("accepts valid coin amounts", () => {
    expect(validateDelta(50).valid).toBe(true);
    expect(validateDelta(100).valid).toBe(true);
    expect(validateDelta(300).valid).toBe(true);
    expect(validateDelta(500).valid).toBe(true);
  });

  it("rejects zero or negative deltas", () => {
    expect(validateDelta(0).valid).toBe(false);
    expect(validateDelta(-10).valid).toBe(false);
  });

  it("rejects delta above max batch size", () => {
    expect(validateDelta(501).valid).toBe(false);
    expect(validateDelta(9999).valid).toBe(false);
  });

  it("rejects non-integer delta", () => {
    expect(validateDelta(50.5).valid).toBe(false);
  });
});

describe("Reward distribution", () => {
  function coinsForRank(rank: number): number {
    if (rank === 1) return 500;
    if (rank <= 3) return 300;
    return 100;
  }

  function getTop10PercentCount(total: number): number {
    return Math.max(1, Math.ceil(total * 0.1));
  }

  it("always rewards at least 1 person", () => {
    expect(getTop10PercentCount(1)).toBe(1);
    expect(getTop10PercentCount(5)).toBe(1);
    expect(getTop10PercentCount(9)).toBe(1);
  });

  it("rewards correct number for 10 participants", () => {
    expect(getTop10PercentCount(10)).toBe(1);
  });

  it("rewards correct number for 20 participants", () => {
    expect(getTop10PercentCount(20)).toBe(2);
  });

  it("rewards correct number for 50 participants", () => {
    expect(getTop10PercentCount(50)).toBe(5);
  });

  it("assigns correct coin amounts by rank", () => {
    expect(coinsForRank(1)).toBe(500);
    expect(coinsForRank(2)).toBe(300);
    expect(coinsForRank(3)).toBe(300);
    expect(coinsForRank(4)).toBe(100);
    expect(coinsForRank(10)).toBe(100);
  });
});
