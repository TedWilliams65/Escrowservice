import { describe, it, expect } from 'vitest';

interface Escrow {
  escrowId: number;
  buyer: string;
  seller: string;
  amount: number;
  token?: any;
  deadline: number;
  isReleased: boolean;
  isDisputed: boolean;
  arbiter?: string;
}

const ERR_DEADLINE = 102;
const ERR_NOT_FOUND = 101;

function refund(escrowId: number, escrows: Record<number, Escrow>, blockHeight: number, sender: string) {
  const escrow = escrows[escrowId];
  if (!escrow) return { ok: false, err: ERR_NOT_FOUND };

  const isDeadlinePassed = blockHeight > escrow.deadline;
  const isBuyer = sender === escrow.buyer;
  const notReleased = !escrow.isReleased;

  if (isBuyer && isDeadlinePassed && notReleased) {
    escrow.isReleased = true;
    return { ok: true };
  }

  return { ok: false, err: ERR_DEADLINE };
}

describe('refund()', () => {
  it('should refund the buyer if deadline passed and funds not released', () => {
    const escrows = {
      1: {
        escrowId: 1,
        buyer: 'buyer-address',
        seller: 'seller-address',
        amount: 100,
        deadline: 1000,
        isReleased: false,
        isDisputed: false,
      },
    };

    const result = refund(1, escrows, 1001, 'buyer-address');
    expect(result.ok).toBe(true);
    expect(escrows[1].isReleased).toBe(true);
  });

  it('should return ERR_DEADLINE if deadline not passed', () => {
    const escrows = {
      1: {
        escrowId: 1,
        buyer: 'buyer-address',
        seller: 'seller-address',
        amount: 100,
        deadline: 1000,
        isReleased: false,
        isDisputed: false,
      },
    };

    const result = refund(1, escrows, 999, 'buyer-address');
    expect(result.ok).toBe(false);
    expect(result.err).toBe(ERR_DEADLINE);
  });

  it('should return ERR_DEADLINE if sender is not buyer', () => {
    const escrows = {
      1: {
        escrowId: 1,
        buyer: 'buyer-address',
        seller: 'seller-address',
        amount: 100,
        deadline: 900,
        isReleased: false,
        isDisputed: false,
      },
    };

    const result = refund(1, escrows, 1001, 'not-buyer');
    expect(result.ok).toBe(false);
    expect(result.err).toBe(ERR_DEADLINE);
  });

  it('should return ERR_NOT_FOUND if escrow ID does not exist', () => {
    const escrows = {};

    const result = refund(999, escrows, 1200, 'buyer-address');
    expect(result.ok).toBe(false);
    expect(result.err).toBe(ERR_NOT_FOUND);
  });

  it('should return ERR_DEADLINE if already released', () => {
    const escrows = {
      1: {
        escrowId: 1,
        buyer: 'buyer-address',
        seller: 'seller-address',
        amount: 100,
        deadline: 900,
        isReleased: true,
        isDisputed: false,
      },
    };

    const result = refund(1, escrows, 1200, 'buyer-address');
    expect(result.ok).toBe(false);
    expect(result.err).toBe(ERR_DEADLINE);
  });
});
