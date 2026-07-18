/**
 * UAT seed — structural data + test accounts only.
 * No demo products: sellers add real catalog via Seller Dashboard.
 */
import path from 'path';
import dotenv from 'dotenv';
import {
  PrismaClient,
  Role,
  VendorType,
} from '@prisma/client';
import bcrypt from 'bcryptjs';

dotenv.config({ path: path.resolve(__dirname, '../.env') });

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding Nestly (UAT — no mock products)...');

  await prisma.orderEvent.deleteMany();
  await prisma.orderItem.deleteMany();
  await prisma.order.deleteMany();
  await prisma.favorite.deleteMany();
  await prisma.product.deleteMany();
  await prisma.vendor.deleteMany();
  await prisma.address.deleteMany();
  await prisma.banner.deleteMany();
  await prisma.coupon.deleteMany();
  await prisma.shopCategory.deleteMany();
  await prisma.user.deleteMany();

  const passwordHash = await bcrypt.hash('password123', 10);

  await prisma.user.create({
    data: {
      id: 'user-customer-1',
      name: 'Priya Sharma',
      email: 'priya@nestly.app',
      phone: '+91 98765 43210',
      passwordHash,
      role: Role.CUSTOMER,
      addresses: {
        create: [
          {
            id: 'addr-1',
            label: 'Home',
            fullAddress: 'Flat 402, Green Valley Apts, Road No. 12',
            area: 'Madhapur',
            city: 'Hyderabad',
            pincode: '500081',
            landmark: 'Near Inorbit Mall',
            lat: 17.4486,
            lng: 78.3908,
            isDefault: true,
          },
        ],
      },
    },
  });

  const sellerAmma = await prisma.user.create({
    data: {
      id: 'user-seller-1',
      name: 'Lakshmi Amma',
      email: 'amma@nestly.app',
      phone: '+91 90000 11111',
      passwordHash,
      role: Role.SELLER,
    },
  });

  await prisma.user.create({
    data: {
      id: 'user-seller-2',
      name: 'Boutique Owner',
      email: 'boutique@nestly.app',
      phone: '+91 90000 22222',
      passwordHash,
      role: Role.SELLER,
    },
  });

  await prisma.user.create({
    data: {
      id: 'user-admin-1',
      name: 'Admin',
      email: 'admin@nestly.app',
      phone: '+91 90000 00000',
      passwordHash,
      role: Role.ADMIN,
    },
  });

  // Categories only (hubs need these IDs)
  await prisma.shopCategory.createMany({
    data: [
      {
        id: 'cat_food',
        name: 'Home Food',
        description: 'Fresh homemade meals from local cooks',
        iconKey: 'restaurant_menu',
        colorHex: 'FFE0B2',
        imageUrl:
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
        vendorCount: 0,
        sortOrder: 1,
      },
      {
        id: 'cat_cloud',
        name: 'Cloud Kitchen',
        description: 'Pro kitchens delivering to your door',
        iconKey: 'storefront',
        colorHex: 'FFCDD2',
        imageUrl:
          'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=400',
        vendorCount: 0,
        sortOrder: 2,
      },
      {
        id: 'cat_pickle',
        name: 'Pickles & Spices',
        description: 'Homemade pickles, powders & masalas',
        iconKey: 'spa',
        colorHex: 'C8E6C9',
        imageUrl:
          'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=400',
        vendorCount: 0,
        sortOrder: 3,
      },
      {
        id: 'cat_sweets',
        name: 'Sweets & Snacks',
        description: 'Traditional sweets & crispy snacks',
        iconKey: 'cake',
        colorHex: 'BBDEFB',
        imageUrl:
          'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=400',
        vendorCount: 0,
        sortOrder: 4,
      },
      {
        id: 'cat_clothes',
        name: 'Home Clothes',
        description: 'Handcrafted & home-stitched fashion',
        iconKey: 'checkroom',
        colorHex: 'E1BEE7',
        imageUrl:
          'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=400',
        vendorCount: 0,
        sortOrder: 5,
      },
      {
        id: 'cat_bakery',
        name: 'Home Bakery',
        description: 'Cakes, cookies & fresh breads',
        iconKey: 'bakery_dining',
        colorHex: 'FFF9C4',
        imageUrl:
          'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400',
        vendorCount: 0,
        sortOrder: 6,
      },
      {
        id: 'cat_healthy',
        name: 'Healthy & Diet',
        description: 'Low-cal, keto & nutritious meals',
        iconKey: 'favorite',
        colorHex: 'B2DFDB',
        imageUrl:
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400',
        vendorCount: 0,
        sortOrder: 7,
      },
      {
        id: 'cat_tiffin',
        name: 'Tiffin Service',
        description: 'Daily lunch & dinner subscriptions',
        iconKey: 'lunch_dining',
        colorHex: 'F8BBD9',
        imageUrl:
          'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=400',
        vendorCount: 0,
        sortOrder: 8,
      },
    ],
  });

  await prisma.coupon.createMany({
    data: [
      {
        code: 'NESTLY20',
        type: 'PERCENT',
        value: 20,
        maxDiscount: 100,
        minOrder: 0,
        description: '20% off up to ₹100',
      },
      {
        code: 'FLAT50',
        type: 'FLAT',
        value: 50,
        minOrder: 199,
        description: '₹50 off above ₹199',
      },
      {
        code: 'FIRST100',
        type: 'FLAT',
        value: 100,
        minOrder: 0,
        description: '₹100 off first order',
      },
    ],
  });

  // Empty storefronts for UAT sellers (they add products themselves)
  await prisma.vendor.create({
    data: {
      id: 'v-amma',
      ownerId: sellerAmma.id,
      name: "Amma's Kitchen",
      tagline: 'Add your menu in Seller Dashboard',
      description:
        'UAT home kitchen. Login as amma@nestly.app and add products to go live.',
      imageUrl:
        'https://images.unsplash.com/photo-1556911220-bff31c812dba?w=400',
      coverUrl:
        'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=800',
      type: VendorType.HOME_COOK,
      rating: 0,
      reviewCount: 0,
      deliveryTimeMins: 35,
      distanceKm: 1.2,
      area: 'Madhapur',
      categoriesJson: JSON.stringify(['cat_food', 'cat_tiffin']),
      tagsJson: JSON.stringify(['Home kitchen', 'UAT']),
      freeDelivery: true,
      orderCount: 0,
      lat: 17.4486,
      lng: 78.3908,
      isApproved: true,
      isOpen: true,
    },
  });

  console.log('UAT seed complete — no products (sellers add them).');
  console.log('Password for all: password123');
  console.log('  Customer: priya@nestly.app');
  console.log('  Seller (food): amma@nestly.app  → store: Amma\'s Kitchen (empty menu)');
  console.log('  Seller (new boutique): boutique@nestly.app  → complete onboard in app');
  console.log('  Admin: admin@nestly.app');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
