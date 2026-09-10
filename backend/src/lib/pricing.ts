export function toPaise(amount: number): number {
  if (!Number.isFinite(amount) || amount < 0 || amount > 10000000) {
    throw Object.assign(new Error('Invalid amount'), { status: 400 });
  }
  return Math.round(amount * 100);
}
export function fromPaise(amount: number): number { return amount / 100; }

// Catalog prices include product GST. Fees are total amounts payable.
export function totals(lines: { unitPrice: number; quantity: number; gstRate: number }[], freeDelivery: boolean) {
  const itemPaise = lines.reduce((sum, line) => sum + toPaise(line.unitPrice) * line.quantity, 0);
  if (!Number.isSafeInteger(itemPaise) || itemPaise > 1000000000) {
    throw Object.assign(new Error('Order total exceeds the supported limit'), { status: 400 });
  }
  const taxPaise = lines.reduce((sum, line) => sum + Math.round(
    toPaise(line.unitPrice) * line.quantity * line.gstRate / (100 + line.gstRate),
  ), 0);
  const deliveryPaise = freeDelivery || itemPaise >= 19900 ? 0 : 2900;
  const platformPaise = 500;
  return {
    itemTotal: fromPaise(itemPaise), tax: fromPaise(taxPaise),
    deliveryFee: fromPaise(deliveryPaise), platformFee: fromPaise(platformPaise),
    discount: 0, grandTotal: fromPaise(itemPaise + deliveryPaise + platformPaise),
  };
}
