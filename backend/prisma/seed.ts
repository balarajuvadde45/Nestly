/**
 * Production-ready seed — accounts, categories, sample home businesses & products.
 */
import path from 'path';
import dotenv from 'dotenv';
import {
  PrismaClient,
  Role,
  VendorType,
  ProductType,
} from '@prisma/client';
import bcrypt from 'bcryptjs';

dotenv.config({ path: path.resolve(__dirname, '../.env') });

const prisma = new PrismaClient();

async function main() {
  if (process.env.NODE_ENV === 'production' && process.env.ALLOW_PROD_SEED !== 'true') {
    throw new Error(
      'Refusing to seed: this deletes all users, orders and products. ' +
        'Never run seed against production. Set ALLOW_PROD_SEED=true only if you mean it.',
    );
  }
  console.log('Seeding Nestly (local/demo catalog)...');

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

  const sellerBoutique = await prisma.user.findUnique({
    where: { email: 'boutique@nestly.app' },
  });

  await prisma.vendor.create({
    data: {
      id: 'v-amma',
      ownerId: sellerAmma.id,
      name: "Amma's Kitchen",
      tagline: 'Home-style meals & pickles from Hyderabad',
      description:
        'Authentic home cooking — thalis, biryani, pickles and sweets made fresh every day.',
      imageUrl:
        'https://images.unsplash.com/photo-1556911220-bff31c812dba?w=400',
      coverUrl:
        'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=800',
      type: VendorType.HOME_COOK,
      rating: 4.8,
      reviewCount: 126,
      deliveryTimeMins: 35,
      distanceKm: 1.2,
      area: 'Madhapur',
      categoriesJson: JSON.stringify(['cat_food', 'cat_tiffin', 'cat_pickle']),
      tagsJson: JSON.stringify(['Home kitchen', 'Pure veg', 'Pickles']),
      freeDelivery: true,
      isPureVeg: true,
      orderCount: 420,
      lat: 17.4486,
      lng: 78.3908,
      isApproved: true,
      isOpen: true,
    },
  });

  await prisma.vendor.create({
    data: {
      id: 'v-boutique',
      ownerId: sellerBoutique!.id,
      name: 'Nest Stitch Boutique',
      tagline: 'Handcrafted kurtis & ethnic wear',
      description:
        'Home boutique with custom-fit kurtis, saree blouses and festive wear.',
      imageUrl:
        'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=400',
      coverUrl:
        'https://images.unsplash.com/photo-1467043237213-65f2da53396f?w=800',
      type: VendorType.BOUTIQUE,
      rating: 4.6,
      reviewCount: 58,
      deliveryTimeMins: 50,
      distanceKm: 2.4,
      area: 'Gachibowli',
      categoriesJson: JSON.stringify(['cat_clothes']),
      tagsJson: JSON.stringify(['Boutique', 'Kurtis', 'Custom fit']),
      freeDelivery: false,
      orderCount: 98,
      lat: 17.4401,
      lng: 78.3489,
      isApproved: true,
      isOpen: true,
    },
  });

  await prisma.product.createMany({
    data: [
      {
        id: 'p-thali',
        vendorId: 'v-amma',
        categoryId: 'cat_food',
        name: 'South Indian Thali',
        description: 'Rice, sambar, rasam, 2 veggies, curd & pickle',
        price: 149,
        mrp: 179,
        imageUrl:
          'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=400',
        type: ProductType.FOOD,
        isVeg: true,
        rating: 4.7,
        reviewCount: 89,
        tagsJson: JSON.stringify(['Thali', 'Lunch', 'Home food']),
        prepTimeMins: 25,
      },
      {
        id: 'p-biryani',
        vendorId: 'v-amma',
        categoryId: 'cat_food',
        name: 'Veg Dum Biryani',
        description: 'Slow-cooked basmati with home masala & raita',
        price: 199,
        mrp: 229,
        imageUrl:
          'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=400',
        type: ProductType.FOOD,
        isVeg: true,
        rating: 4.9,
        reviewCount: 210,
        tagsJson: JSON.stringify(['Biryani', 'Dinner']),
        prepTimeMins: 40,
      },
      {
        id: 'p-pickle',
        vendorId: 'v-amma',
        categoryId: 'cat_pickle',
        name: 'Mango Pickle (500g)',
        description: 'Traditional Andhra avakaya style, oil-cured',
        price: 249,
        mrp: 299,
        imageUrl:
          'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=400',
        type: ProductType.PICKLE,
        isVeg: true,
        rating: 4.8,
        reviewCount: 64,
        tagsJson: JSON.stringify(['Pickle', 'Mango', 'Andhra']),
      },
      {
        id: 'p-ladoo',
        vendorId: 'v-amma',
        categoryId: 'cat_sweets',
        name: 'Besan Ladoo (6 pcs)',
        description: 'Fresh ghee ladoos made this morning',
        price: 120,
        mrp: 140,
        imageUrl:
          'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=400',
        type: ProductType.SWEET,
        isVeg: true,
        rating: 4.6,
        reviewCount: 41,
        tagsJson: JSON.stringify(['Sweet', 'Ladoo']),
      },
      {
        id: 'p-tiffin',
        vendorId: 'v-amma',
        categoryId: 'cat_tiffin',
        name: 'Daily Lunch Tiffin',
        description: 'Weekday tiffin — rice, dal, sabzi, roti',
        price: 99,
        imageUrl:
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
        type: ProductType.FOOD,
        isVeg: true,
        rating: 4.5,
        reviewCount: 33,
        tagsJson: JSON.stringify(['Tiffin', 'Subscription']),
        prepTimeMins: 20,
      },
      {
        id: 'p-kurti',
        vendorId: 'v-boutique',
        categoryId: 'cat_clothes',
        name: 'Cotton Printed Kurti',
        description: 'Breathable cotton, S–XXL, home-stitched finish',
        price: 799,
        mrp: 999,
        imageUrl:
          'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=400',
        type: ProductType.CLOTHES,
        isVeg: true,
        rating: 4.5,
        reviewCount: 22,
        tagsJson: JSON.stringify(['Kurti', 'Cotton', 'Ethnic']),
        sizesJson: JSON.stringify(['S', 'M', 'L', 'XL']),
      },
      {
        id: 'p-blouse',
        vendorId: 'v-boutique',
        categoryId: 'cat_clothes',
        name: 'Designer Saree Blouse',
        description: 'Custom-fit blouse with lining, 7–10 day delivery',
        price: 1299,
        mrp: 1599,
        imageUrl:
          'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=400',
        type: ProductType.CLOTHES,
        isVeg: true,
        rating: 4.7,
        reviewCount: 15,
        tagsJson: JSON.stringify(['Blouse', 'Custom', 'Saree']),
        sizesJson: JSON.stringify(['32', '34', '36', '38', '40']),
      },
    ],
  });

  await prisma.banner.createMany({
    data: [
      {
        title: 'From home kitchens',
        subtitle: 'Order fresh food, pickles & more',
        imageUrl:
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800',
        categoryId: 'cat_food',
        sortOrder: 1,
      },
      {
        title: 'Handmade fashion',
        subtitle: 'Discover home boutiques near you',
        imageUrl:
          'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=800',
        categoryId: 'cat_clothes',
        sortOrder: 2,
      },
    ],
  });

  await prisma.shopCategory.update({
    where: { id: 'cat_food' },
    data: { vendorCount: 1 },
  });
  await prisma.shopCategory.update({
    where: { id: 'cat_clothes' },
    data: { vendorCount: 1 },
  });

  console.log('Seed complete — sample catalog ready for launch.');
  console.log('Password for all: password123');
  console.log('  Customer: priya@nestly.app');
  console.log("  Seller (food): amma@nestly.app  → Amma's Kitchen");
  console.log('  Seller (boutique): boutique@nestly.app');
  console.log('  Admin: admin@nestly.app');
  console.log('  Coupon: NESTLY20');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
