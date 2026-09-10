import { z } from 'zod';

export const vendorTypeValues = [
  'HOME_COOK',
  'CLOUD_KITCHEN',
  'HOME_BUSINESS',
  'BOUTIQUE',
  'FOOD_OUTLET',
  'PICKLES_AND_PACKAGED_FOOD',
  'SWEETS_SNACKS',
  'FMCG_DISTRIBUTOR',
  'HANDMADE_PRODUCTS',
] as const;

export const productTypeValues = [
  'FOOD',
  'PICKLE',
  'CLOTHES',
  'SNACK',
  'SWEET',
  'GROCERY',
  'FMCG',
  'PERSONAL_CARE',
  'HOME_CARE',
  'BEVERAGE',
  'READY_TO_COOK',
  'SAREE',
  'ACCESSORY',
  'OTHER',
] as const;

export const fulfillmentModeValues = [
  'LOCAL_DELIVERY',
  'PICKUP',
  'SHIPPING',
  'SCHEDULED',
] as const;

export const vendorTypeSchema = z.enum(vendorTypeValues);
export const productTypeSchema = z.enum(productTypeValues);
export const fulfillmentModeSchema = z.enum(fulfillmentModeValues);

export const wholesaleTierSchema = z.object({
  minQuantity: z.number().int().min(1),
  unitPrice: z.number().positive(),
  label: z.string().trim().max(40).optional(),
});

export type WholesaleTier = z.infer<typeof wholesaleTierSchema>;

export function normalizeString(value: string | null | undefined) {
  const trimmed = value?.trim();
  return trimmed && trimmed.length > 0 ? trimmed : null;
}

export function safeJsonArray(raw: string | null | undefined): unknown[] {
  if (!raw) return [];
  try {
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

export function normalizeWholesaleTiers(
  tiers: WholesaleTier[] | undefined,
): WholesaleTier[] {
  if (!tiers?.length) return [];
  const deduped = new Map<number, WholesaleTier>();
  for (const tier of tiers) {
    deduped.set(tier.minQuantity, {
      minQuantity: tier.minQuantity,
      unitPrice: Number(tier.unitPrice.toFixed(2)),
      ...(tier.label ? { label: tier.label.trim() } : {}),
    });
  }
  return [...deduped.values()].sort((a, b) => a.minQuantity - b.minQuantity);
}

export function parseWholesaleTiers(
  raw: string | null | undefined,
): WholesaleTier[] {
  const parsed = safeJsonArray(raw);
  const tiers: WholesaleTier[] = [];
  for (const entry of parsed) {
    const result = wholesaleTierSchema.safeParse(entry);
    if (result.success) tiers.push(result.data);
  }
  return normalizeWholesaleTiers(tiers);
}

export function priceForQuantity(
  basePrice: number,
  quantity: number,
  tiers: WholesaleTier[],
) {
  let price = basePrice;
  for (const tier of tiers) {
    if (quantity >= tier.minQuantity) {
      price = tier.unitPrice;
    }
  }
  return price;
}

export function defaultFulfillmentModes(_vendorType: string) {
  return ['LOCAL_DELIVERY'];
}
export function categoryForProductType(type: string): string {
  if (['CLOTHES', 'SAREE', 'ACCESSORY'].includes(type)) return 'cat_clothes';
  if (['FMCG', 'PERSONAL_CARE', 'HOME_CARE', 'GROCERY', 'BEVERAGE'].includes(type)) return 'cat_fmcg';
  if (type === 'PICKLE') return 'cat_pickle';
  if (['SWEET', 'SNACK'].includes(type)) return 'cat_sweets';
  return 'cat_food';
}
