/**
 * LOCAL DEV ONLY — creates demo seller/vendor/products/buyer/admin accounts
 * for UI/UX walkthrough testing against an isolated local database.
 * NEVER run against production. Delete or leave untracked after use.
 */
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();
const hash = (p: string) => bcrypt.hashSync(p, 10);
const img = (id: string) => `https://images.unsplash.com/photo-${id}?w=800&q=70&auto=format&fit=crop`;
const future = (days: number) => new Date(Date.now() + days * 86400000);
const past = (days: number) => new Date(Date.now() - days * 86400000);

async function main() {
  // ---- Users ----
  const admin = await prisma.user.upsert({
    where: { email: 'admin@tamarin.local' },
    update: {},
    create: { name: 'Tamarin Admin', email: 'admin@tamarin.local', phone: '+91 9000000001', passwordHash: hash('Admin#Tamarin2026'), role: 'ADMIN' },
  });
  const seller = await prisma.user.upsert({
    where: { email: 'seller@tamarin.test' },
    update: {},
    create: { name: 'Lakshmi Rao', email: 'seller@tamarin.test', phone: '+91 9000000002', passwordHash: hash('Seller#Tamarin2026'), role: 'SELLER' },
  });
  const seller2 = await prisma.user.upsert({
    where: { email: 'boutique@tamarin.test' },
    update: {},
    create: { name: 'Meena Reddy', email: 'boutique@tamarin.test', phone: '+91 9000000004', passwordHash: hash('Seller#Tamarin2026'), role: 'SELLER' },
  });
  const seller3 = await prisma.user.upsert({
    where: { email: 'fmcg@tamarin.test' },
    update: {},
    create: { name: 'Ravi Kumar', email: 'fmcg@tamarin.test', phone: '+91 9000000005', passwordHash: hash('Seller#Tamarin2026'), role: 'SELLER' },
  });
  const seller4 = await prisma.user.upsert({
    where: { email: 'kitchen@tamarin.test' },
    update: {},
    create: { name: 'Chef Anand', email: 'kitchen@tamarin.test', phone: '+91 9000000006', passwordHash: hash('Seller#Tamarin2026'), role: 'SELLER' },
  });
  await prisma.user.upsert({
    where: { email: 'buyer@tamarin.test' },
    update: {},
    create: { name: 'Priya Sharma', email: 'buyer@tamarin.test', phone: '+91 9000000003', passwordHash: hash('Buyer#Tamarin2026'), role: 'CUSTOMER' },
  });

  // ---- Vendors ----
  const food = await prisma.vendor.upsert({
    where: { ownerId: seller.id },
    update: {},
    create: {
      ownerId: seller.id, name: "Lakshmi's Pickles & Sweets", type: 'PICKLES_AND_PACKAGED_FOOD',
      tagline: 'Homemade-style pickles & chikkis', description: 'Small-batch vegetarian and non-vegetarian pickles, sweets and snacks made fresh every week from our commercial kitchen in Madhapur.',
      imageUrl: img('1596040033229-a9821ebd058d'), coverUrl: img('1555396273-367ea4eb4db5'),
      area: 'Madhapur', city: 'Hyderabad', businessAddress: 'Plot 12, Kavuri Hills Phase 2, Madhapur', pincode: '500081',
      premisesType: 'BUSINESS_PLACE', supportPhone: '+91 9000000002', supportEmail: 'seller@tamarin.test',
      gstin: '36ABCDE1234F1Z5', pan: 'ABCDE1234F', fssaiLicense: '12419002000123', fssaiExpiry: future(365),
      kycStatus: 'VERIFIED', bankAccountLast4: '4321', bankVerified: true,
      serviceablePincodesJson: '["500081","500082","500084","500034","500016"]',
      categoriesJson: '["cat_pickle","cat_sweets","cat_food"]', gstInvoiceAvailable: true, acceptsWholesale: true,
      isApproved: true, isOpen: true, rating: 4.6, reviewCount: 128, orderCount: 340, minOrder: 149,
      deliveryTimeMins: 45, offerText: 'Free delivery over ₹499',
    },
  });
  const boutique = await prisma.vendor.upsert({
    where: { ownerId: seller2.id },
    update: {},
    create: {
      ownerId: seller2.id, name: 'Silk & Loom Boutique', type: 'BOUTIQUE',
      tagline: 'Handloom sarees & handmade fashion', description: 'Curated handloom sarees, kurtis and handmade dresses from local weavers, stitched and dispatched from our studio.',
      imageUrl: img('1524758631624-e2822e304c36'), coverUrl: img('1571513722275-4b41940f54b8'),
      area: 'Jubilee Hills', city: 'Hyderabad', businessAddress: 'Road 45, Jubilee Hills', pincode: '500033',
      premisesType: 'SHOP', supportPhone: '+91 9000000004', supportEmail: 'boutique@tamarin.test',
      gstin: '36FGHIJ5678K1Z2', pan: 'FGHIJ5678K', kycStatus: 'VERIFIED', bankAccountLast4: '8842', bankVerified: true,
      serviceablePincodesJson: '["500033","500034","500081","500082"]',
      categoriesJson: '["cat_clothes"]', gstInvoiceAvailable: true,
      isApproved: true, isOpen: true, rating: 4.4, reviewCount: 86, orderCount: 190, deliveryTimeMins: 60,
    },
  });
  const fmcg = await prisma.vendor.upsert({
    where: { ownerId: seller3.id },
    update: {},
    create: {
      ownerId: seller3.id, name: 'Sri Sai FMCG Distribution', type: 'FMCG_DISTRIBUTOR',
      tagline: 'Wholesale case packs for retailers', description: 'Authorised FMCG distributor supplying grocery, oils and home-care case packs to retailers at wholesale slab pricing with GST invoices.',
      imageUrl: img('1585032226651-759b368d7246'), coverUrl: img('1607349913338-5ee6c7617d54'),
      area: 'Begumpet', city: 'Hyderabad', businessAddress: 'Shop 4, CGO Complex, Begumpet', pincode: '500016',
      premisesType: 'WAREHOUSE', supportPhone: '+91 9000000005', supportEmail: 'fmcg@tamarin.test',
      gstin: '36JKLMN9012P1Z9', pan: 'JKLMN9012P', kycStatus: 'VERIFIED', bankAccountLast4: '1120', bankVerified: true,
      serviceablePincodesJson: '["500016","500034","500081","500082","500084"]',
      categoriesJson: '["cat_fmcg"]', gstInvoiceAvailable: true, acceptsWholesale: true,
      isApproved: true, isOpen: true, rating: 4.2, reviewCount: 54, orderCount: 410, deliveryTimeMins: 90,
    },
  });
  const kitchen = await prisma.vendor.upsert({
    where: { ownerId: seller4.id },
    update: {},
    create: {
      ownerId: seller4.id, name: 'Spice Route Cloud Kitchen', type: 'CLOUD_KITCHEN',
      tagline: 'Fresh meals, cooked to order', description: 'FSSAI-licensed cloud kitchen serving homestyle meals, biryani and thalis across west Hyderabad.',
      imageUrl: img('1504674900247-0877df9cc836'), coverUrl: img('1590301157890-4810ed352733'),
      area: 'Gachibowli', city: 'Hyderabad', businessAddress: 'Unit 3, DLF Cyber City, Gachibowli', pincode: '500084',
      premisesType: 'CLOUD_KITCHEN', supportPhone: '+91 9000000006', supportEmail: 'kitchen@tamarin.test',
      fssaiLicense: '12421003000456', fssaiExpiry: future(300), kycStatus: 'VERIFIED', bankAccountLast4: '6677', bankVerified: true,
      serviceablePincodesJson: '["500084","500081","500032","500019"]',
      categoriesJson: '["cat_food","cat_cloud","cat_tiffin"]',
      isApproved: true, isOpen: true, rating: 4.5, reviewCount: 210, orderCount: 890, deliveryTimeMins: 35, freeDelivery: true,
    },
  });

  // ---- Products (fresh each run for this demo set) ----
  for (const v of [food, boutique, fmcg, kitchen]) {
    await prisma.product.deleteMany({ where: { vendorId: v.id } });
  }
  await prisma.product.createMany({
    data: [
      // Pickles — full compliance fields
      { vendorId: food.id, categoryId: 'cat_pickle', name: 'Avakaya Mango Pickle', description: 'Classic Andhra-style mango pickle in cold-pressed groundnut oil. Hand-pounded spices, no preservatives.', price: 149, mrp: 189, brandName: "Lakshmi's", sku: 'LP-AVK-250', unitLabel: '250 g jar', stockQuantity: 40, hsnCode: '20019030', gstRate: 12, batchNumber: 'BV202611', manufactureDate: past(10), expiryDate: future(180), shelfLifeDays: 180, manufacturerName: "Lakshmi's Pickles & Sweets", packerName: "Lakshmi's Pickles & Sweets", originCountry: 'India', fssaiLicense: '12419002000123', type: 'PICKLE', isVeg: true, rating: 4.7, reviewCount: 64, tagsJson: '["bestseller"]', imageUrl: img('1596040033229-a9821ebd058d') },
      { vendorId: food.id, categoryId: 'cat_pickle', name: 'Chicken Boneless Pickle', description: 'Spicy boneless chicken pickle, slow-cooked with Andhra spices.', price: 219, mrp: 259, brandName: "Lakshmi's", sku: 'LP-CHK-200', unitLabel: '200 g jar', stockQuantity: 25, hsnCode: '16023290', gstRate: 12, batchNumber: 'BC202611', manufactureDate: past(6), expiryDate: future(90), shelfLifeDays: 90, manufacturerName: "Lakshmi's Pickles & Sweets", packerName: "Lakshmi's Pickles & Sweets", fssaiLicense: '12419002000123', type: 'PICKLE', isVeg: false, rating: 4.5, reviewCount: 41, imageUrl: img('1546069901-ba9599a7e63c') },
      // Sweets & snacks
      { vendorId: food.id, categoryId: 'cat_sweets', name: 'Peanut Chikki (Jaggery)', description: 'Crunchy peanut chikki sweetened with organic jaggery.', price: 99, mrp: 120, sku: 'LP-PCH-500', unitLabel: '500 g box', stockQuantity: 60, hsnCode: '19059040', gstRate: 5, batchNumber: 'BP202611', expiryDate: future(60), shelfLifeDays: 60, manufacturerName: "Lakshmi's Pickles & Sweets", fssaiLicense: '12419002000123', type: 'SNACK', isVeg: true, rating: 4.6, reviewCount: 33, imageUrl: img('1601050690597-df0568f70950') },
      { vendorId: food.id, categoryId: 'cat_sweets', name: 'Kaju Katli Premium', description: 'Cashew fudge with edible silver leaf, made to order.', price: 349, mrp: 399, sku: 'LP-KKJ-250', unitLabel: '250 g box', stockQuantity: 20, madeToOrder: true, prepTimeMins: 120, hsnCode: '17049010', gstRate: 5, expiryDate: future(21), shelfLifeDays: 21, manufacturerName: "Lakshmi's Pickles & Sweets", fssaiLicense: '12419002000123', type: 'SWEET', isVeg: true, rating: 4.8, reviewCount: 27, imageUrl: img('1587049352846-4a222e784d38') },
      // Cloud kitchen
      { vendorId: kitchen.id, categoryId: 'cat_tiffin', name: 'Andhra Veg Thali', description: 'Rice, dal, two curries, sambar, pickle, curd and rotis.', price: 149, mrp: 169, unitLabel: '1 thali', stockQuantity: 15, prepTimeMins: 25, type: 'FOOD', isVeg: true, rating: 4.4, reviewCount: 95, imageUrl: img('1555396273-367ea4eb4db5') },
      { vendorId: kitchen.id, categoryId: 'cat_food', name: 'Hyderabadi Chicken Biryani', description: 'Dum-cooked long-grain biryani with raita and salan.', price: 219, mrp: 249, unitLabel: '500 g', stockQuantity: 0, prepTimeMins: 30, type: 'FOOD', isVeg: false, rating: 4.7, reviewCount: 143, imageUrl: img('1585032226651-759b368d7246') },
      { vendorId: kitchen.id, categoryId: 'cat_healthy', name: 'Millet Power Bowl', description: 'Foxtail millet bowl with seasonal vegetables and peanut chutney.', price: 129, unitLabel: '1 bowl', stockQuantity: 22, prepTimeMins: 20, type: 'FOOD', isVeg: true, rating: 4.3, reviewCount: 38, imageUrl: img('1546069901-ba9599a7e63c') },
      // Boutique
      { vendorId: boutique.id, categoryId: 'cat_clothes', name: 'Kanjivaram Silk Saree', description: 'Pure silk Kanjivaram with temple border, handwoven.', price: 2499, mrp: 3499, sku: 'SL-KSS-01', unitLabel: '1 saree', stockQuantity: 10, colorsJson: '["Ruby Red","Emerald Green"]', material: 'Pure silk with zari border', sizesJson: '["Free Size"]', isReturnable: true, returnWindowDays: 7, madeToOrder: false, dispatchTimeDays: 3, type: 'SAREE', rating: 4.8, reviewCount: 52, imageUrl: img('1524758631624-e2822e304c36') },
      { vendorId: boutique.id, categoryId: 'cat_clothes', name: 'Handloom Cotton Saree', description: 'Breathable handloom cotton saree with tassels.', price: 999, mrp: 1499, sku: 'SL-HCS-04', unitLabel: '1 saree', stockQuantity: 15, colorsJson: '["Indigo","Mustard"]', material: 'Handloom cotton', sizesJson: '["Free Size"]', isReturnable: true, returnWindowDays: 7, dispatchTimeDays: 2, type: 'SAREE', rating: 4.5, reviewCount: 30, imageUrl: img('1571513722275-4b41940f54b8') },
      { vendorId: boutique.id, categoryId: 'cat_clothes', name: 'Hand-Embroidered Kurti', description: 'Chikankari kurti on soft cotton, stitched in-house.', price: 749, mrp: 999, sku: 'SL-CHK-02', unitLabel: '1 piece', stockQuantity: 18, colorsJson: '["White","Sky Blue"]', material: 'Cotton', sizesJson: '["S","M","L","XL"]', isReturnable: true, returnWindowDays: 7, dispatchTimeDays: 2, type: 'CLOTHES', rating: 4.4, reviewCount: 21, imageUrl: img('1594633312681-425c7b97ccd1') },
      // FMCG wholesale — MOQ + case pack + slab pricing
      { vendorId: fmcg.id, categoryId: 'cat_fmcg', name: 'Sunflower Oil 1L (Case of 12)', description: 'Refined sunflower oil, 1 L pouch bottles. Wholesale case packs with GST invoice.', price: 142, mrp: 165, brandName: 'GoldDrop', sku: 'SS-OIL-1L', unitLabel: '1 L bottle', minOrderQuantity: 12, casePackQuantity: 12, maxOrderQuantity: 240, stockQuantity: 480, hsnCode: '15121110', gstRate: 5, batchNumber: 'OIL2611', expiryDate: future(270), shelfLifeDays: 270, manufacturerName: 'GoldDrop Refineries Pvt Ltd', packerName: 'Sri Sai FMCG Distribution', fssaiLicense: '10019022001234', wholesaleTiersJson: JSON.stringify([{ minQuantity: 12, unitPrice: 142 }, { minQuantity: 48, unitPrice: 135 }, { minQuantity: 96, unitPrice: 128, label: 'Distributor rate' }]), type: 'FMCG', isVeg: true, rating: 4.2, reviewCount: 18, imageUrl: img('1610030469983-98e550d6193c') },
      { vendorId: fmcg.id, categoryId: 'cat_fmcg', name: 'Detergent Powder 1kg (Case of 6)', description: 'Popular detergent powder, case of six 1 kg packs.', price: 210, mrp: 240, brandName: 'SparkleWash', sku: 'SS-DET-1K', unitLabel: '1 kg pack', minOrderQuantity: 6, casePackQuantity: 6, stockQuantity: 150, hsnCode: '34022010', gstRate: 18, batchNumber: 'DET2611', manufacturerName: 'Sparkle Home Care', packerName: 'Sri Sai FMCG Distribution', wholesaleTiersJson: JSON.stringify([{ minQuantity: 6, unitPrice: 210 }, { minQuantity: 24, unitPrice: 198 }]), type: 'HOME_CARE', rating: 4.1, reviewCount: 9, imageUrl: img('1618354691373-d851c5c3a990') },
      { vendorId: fmcg.id, categoryId: 'cat_fmcg', name: 'Basmati Rice 5kg (Case of 4)', description: 'Aged long-grain basmati rice, 5 kg packs, case of four.', price: 475, mrp: 525, brandName: 'KaveriGold', sku: 'SS-RIC-5K', unitLabel: '5 kg bag', minOrderQuantity: 4, casePackQuantity: 4, stockQuantity: 96, hsnCode: '10063020', gstRate: 5, manufacturerName: 'Kaveri Agro Mills', packerName: 'Sri Sai FMCG Distribution', wholesaleTiersJson: JSON.stringify([{ minQuantity: 4, unitPrice: 475 }, { minQuantity: 16, unitPrice: 455 }]), type: 'GROCERY', isVeg: true, rating: 4.3, reviewCount: 12, imageUrl: img('1504674900247-0877df9cc836') },
    ],
  });
  console.log('Demo data created. Vendors:', [food.id, boutique.id, fmcg.id, kitchen.id].length, 'Admin:', admin.email);
}

main()
  .catch((e) => { console.error(e); process.exitCode = 1; })
  .finally(() => prisma.$disconnect());
