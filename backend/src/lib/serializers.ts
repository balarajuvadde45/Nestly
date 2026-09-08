import {
  Address,
  Banner,
  Order,
  OrderEvent,
  OrderItem,
  Product,
  ShopCategory,
  User,
  Vendor,
} from '@prisma/client';

function parseJsonArray(raw: string | null | undefined): string[] {
  if (!raw) return [];
  try {
    const v = JSON.parse(raw);
    return Array.isArray(v) ? v.map(String) : [];
  } catch {
    return [];
  }
}

function parseJsonObjectArray(
  raw: string | null | undefined,
): Array<Record<string, unknown>> {
  if (!raw) return [];
  try {
    const v = JSON.parse(raw);
    return Array.isArray(v)
      ? v.filter((entry): entry is Record<string, unknown> => {
          return entry != null && typeof entry === 'object' && !Array.isArray(entry);
        })
      : [];
  } catch {
    return [];
  }
}

export function serializeUser(u: User, addresses?: Address[]) {
  return {
    id: u.id,
    name: u.name,
    email: u.email,
    phone: u.phone,
    role: u.role,
    avatarUrl: u.avatarUrl,
    addresses: addresses?.map(serializeAddress) ?? [],
  };
}

export function serializeAddress(a: Address) {
  return {
    id: a.id,
    label: a.label,
    fullAddress: a.fullAddress,
    area: a.area,
    city: a.city,
    pincode: a.pincode,
    landmark: a.landmark,
    lat: a.lat,
    lng: a.lng,
    isDefault: a.isDefault,
  };
}

export function serializeCategory(c: ShopCategory) {
  return {
    id: c.id,
    name: c.name,
    description: c.description,
    iconKey: c.iconKey,
    colorHex: c.colorHex,
    imageUrl: c.imageUrl,
    vendorCount: c.vendorCount,
  };
}

export function serializeVendor(v: Vendor, privateFields = false) {
  return {
    id: v.id,
    ownerId: v.ownerId,
    name: v.name,
    tagline: v.tagline,
    description: v.description,
    imageUrl: v.imageUrl,
    coverUrl: v.coverUrl,
    type: v.type,
    rating: v.rating,
    reviewCount: v.reviewCount,
    deliveryTimeMins: v.deliveryTimeMins,
    distanceKm: v.distanceKm,
    area: v.area,
    city: v.city,
    businessAddress: v.businessAddress,
    pincode: v.pincode,
    premisesType: v.premisesType,
    supportPhone: v.supportPhone,
    supportEmail: v.supportEmail,
    gstin: v.gstin,
    ...(privateFields ? { pan: v.pan, bankAccountLast4: v.bankAccountLast4 } : {}),
    fssaiLicense: v.fssaiLicense,
    fssaiExpiry: v.fssaiExpiry?.toISOString() ?? null,
    kycStatus: v.kycStatus,
    bankVerified: v.bankVerified,
    fulfillmentModes: parseJsonArray(v.fulfillmentModesJson),
    serviceRadiusKm: v.serviceRadiusKm,
    gstInvoiceAvailable: v.gstInvoiceAvailable,
    acceptsWholesale: v.acceptsWholesale,
    categories: parseJsonArray(v.categoriesJson),
    tags: parseJsonArray(v.tagsJson),
    isOpen: v.isOpen,
    isPureVeg: v.isPureVeg,
    freeDelivery: v.freeDelivery,
    minOrder: v.minOrder,
    offerText: v.offerText,
    orderCount: v.orderCount,
    lat: v.lat,
    lng: v.lng,
    isApproved: v.isApproved,
  };
}

export function serializeProduct(p: Product) {
  return {
    id: p.id,
    vendorId: p.vendorId,
    categoryId: p.categoryId,
    name: p.name,
    description: p.description,
    price: p.price,
    mrp: p.mrp,
    brandName: p.brandName,
    sku: p.sku,
    unitLabel: p.unitLabel,
    minOrderQuantity: p.minOrderQuantity,
    casePackQuantity: p.casePackQuantity,
    maxOrderQuantity: p.maxOrderQuantity,
    stockQuantity: p.stockQuantity,
    hsnCode: p.hsnCode,
    gstRate: p.gstRate,
    batchNumber: p.batchNumber,
    manufactureDate: p.manufactureDate?.toISOString() ?? null,
    expiryDate: p.expiryDate?.toISOString() ?? null,
    shelfLifeDays: p.shelfLifeDays,
    manufacturerName: p.manufacturerName,
    packerName: p.packerName,
    originCountry: p.originCountry,
    fssaiLicense: p.fssaiLicense,
    isReturnable: p.isReturnable,
    returnWindowDays: p.returnWindowDays,
    madeToOrder: p.madeToOrder,
    dispatchTimeDays: p.dispatchTimeDays,
    wholesaleTiers: parseJsonObjectArray(p.wholesaleTiersJson),
    colors: parseJsonArray(p.colorsJson),
    material: p.material,
    imageUrl: p.imageUrl,
    type: p.type,
    isVeg: p.isVeg,
    isAvailable: p.isAvailable,
    rating: p.rating,
    reviewCount: p.reviewCount,
    tags: parseJsonArray(p.tagsJson),
    prepTimeMins: p.prepTimeMins,
    sizes: parseJsonArray(p.sizesJson),
  };
}

export function serializeBanner(b: Banner) {
  return {
    id: b.id,
    title: b.title,
    subtitle: b.subtitle,
    imageUrl: b.imageUrl,
    categoryId: b.categoryId,
    vendorId: b.vendorId,
  };
}

export function serializeOrderItem(i: OrderItem) {
  return {
    id: i.id,
    productId: i.productId,
    productName: i.productName,
    productImage: i.productImage,
    unitPrice: i.unitPrice,
    quantity: i.quantity,
    unitLabel: i.unitLabel,
    hsnCode: i.hsnCode,
    gstRate: i.gstRate,
    lineTax: i.lineTax,
    selectedSize: i.selectedSize,
    specialInstructions: i.specialInstructions,
    isVeg: i.isVeg,
    lineTotal: i.unitPrice * i.quantity,
  };
}

export function serializeOrderEvent(e: OrderEvent) {
  return {
    id: e.id,
    status: e.status,
    message: e.message,
    lat: e.lat,
    lng: e.lng,
    createdAt: e.createdAt.toISOString(),
  };
}

export function serializeOrder(
  o: Order & {
    items?: OrderItem[];
    events?: OrderEvent[];
    vendor?: Vendor;
    address?: Address;
  },
) {
  return {
    id: o.id,
    customerId: o.customerId,
    vendorId: o.vendorId,
    vendorName: o.vendor?.name ?? null,
    vendorLat: o.vendor?.lat ?? null,
    vendorLng: o.vendor?.lng ?? null,
    addressId: o.addressId,
    address: o.addressSnapshotJson
      ? JSON.parse(o.addressSnapshotJson) as Record<string, unknown>
      : o.address ? serializeAddress(o.address) : null,
    status: o.status,
    paymentMethod: o.paymentMethod,
    paymentStatus: o.paymentStatus,
    itemTotal: o.itemTotal,
    deliveryFee: o.deliveryFee,
    platformFee: o.platformFee,
    tax: o.tax,
    discount: o.discount,
    grandTotal: o.grandTotal,
    couponCode: o.couponCode,
    fulfillmentMode: o.fulfillmentMode,
    invoiceRequired: o.invoiceRequired,
    buyerGstin: o.buyerGstin,
    sellerGstin: o.sellerGstin,
    deliveryPartner: o.deliveryPartner,
    riderLat: o.riderLat,
    riderLng: o.riderLng,
    estimatedDelivery: o.estimatedDelivery?.toISOString() ?? null,
    placedAt: o.placedAt.toISOString(),
    updatedAt: o.updatedAt.toISOString(),
    notes: o.notes,
    items: o.items?.map(serializeOrderItem) ?? [],
    events: o.events?.map(serializeOrderEvent) ?? [],
  };
}
