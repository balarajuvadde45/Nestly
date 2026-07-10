import {
  PrismaClient,
  ProductType,
  Role,
  VendorType,
} from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding Nestly database...');

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

  const customer = await prisma.user.create({
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
          {
            id: 'addr-2',
            label: 'Office',
            fullAddress: 'Floor 8, Tech Park Building B',
            area: 'Hitech City',
            city: 'Hyderabad',
            pincode: '500081',
            landmark: 'Gate 2',
            lat: 17.4435,
            lng: 78.3772,
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

  const sellerPickle = await prisma.user.create({
    data: {
      id: 'user-seller-2',
      name: 'Aunty Pickles',
      email: 'pickles@nestly.app',
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

  const categories = [
    {
      id: 'cat_food',
      name: 'Home Food',
      description: 'Fresh homemade meals from local cooks',
      iconKey: 'restaurant_menu',
      colorHex: 'FFE0B2',
      imageUrl:
        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
      vendorCount: 48,
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
      vendorCount: 22,
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
      vendorCount: 31,
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
      vendorCount: 27,
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
      vendorCount: 19,
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
      vendorCount: 15,
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
      vendorCount: 12,
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
      vendorCount: 18,
      sortOrder: 8,
    },
  ];
  await prisma.shopCategory.createMany({ data: categories });

  await prisma.banner.createMany({
    data: [
      {
        title: 'Homemade Happiness',
        subtitle: 'Get 40% OFF on first order',
        imageUrl:
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800',
        sortOrder: 1,
      },
      {
        title: 'Cloud Kitchen Deals',
        subtitle: 'Free delivery above ₹199',
        imageUrl:
          'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800',
        categoryId: 'cat_cloud',
        sortOrder: 2,
      },
      {
        title: "Grandma's Pickles",
        subtitle: 'Authentic recipes, pure ingredients',
        imageUrl:
          'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=800',
        categoryId: 'cat_pickle',
        sortOrder: 3,
      },
      {
        title: 'Festive Wear',
        subtitle: 'Handcrafted ethnic clothes',
        imageUrl:
          'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=800',
        categoryId: 'cat_clothes',
        sortOrder: 4,
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

  const v1 = await prisma.vendor.create({
    data: {
      id: 'v1',
      ownerId: sellerAmma.id,
      name: "Amma's Kitchen",
      tagline: 'Taste of home, every day',
      description:
        'Traditional Andhra & Telangana home-style meals cooked with love. Fresh ingredients, no preservatives.',
      imageUrl:
        'https://images.unsplash.com/photo-1556911220-bff31c812dba?w=400',
      coverUrl:
        'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=800',
      type: VendorType.HOME_COOK,
      rating: 4.7,
      reviewCount: 1240,
      deliveryTimeMins: 35,
      distanceKm: 1.2,
      area: 'Madhapur',
      categoriesJson: JSON.stringify(['cat_food', 'cat_tiffin']),
      tagsJson: JSON.stringify(['Andhra', 'Home-style', 'Pure Veg options']),
      freeDelivery: true,
      offerText: '30% OFF up to ₹100',
      orderCount: 8500,
      lat: 17.4486,
      lng: 78.3908,
    },
  });

  const v2 = await prisma.vendor.create({
    data: {
      id: 'v2',
      name: 'Spice Route Cloud',
      tagline: 'Restaurant-grade, home-delivered',
      description:
        'Multi-cuisine cloud kitchen serving biryanis, kebabs, Chinese & more.',
      imageUrl:
        'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400',
      coverUrl:
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800',
      type: VendorType.CLOUD_KITCHEN,
      rating: 4.5,
      reviewCount: 980,
      deliveryTimeMins: 40,
      distanceKm: 2.4,
      area: 'Hitech City',
      categoriesJson: JSON.stringify(['cat_cloud', 'cat_food']),
      tagsJson: JSON.stringify(['Biryani', 'North Indian', 'Chinese']),
      offerText: 'Buy 1 Get 1 on selected items',
      orderCount: 12000,
      lat: 17.4435,
      lng: 78.3772,
    },
  });

  const v3 = await prisma.vendor.create({
    data: {
      id: 'v3',
      ownerId: sellerPickle.id,
      name: "Aunty's Pickle Co.",
      tagline: 'From our kitchen to yours',
      description:
        'Handmade pickles, podis and spice mixes using recipes passed down three generations.',
      imageUrl:
        'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=400',
      coverUrl:
        'https://images.unsplash.com/photo-1506368249639-73a05d6f6488?w=800',
      type: VendorType.HOME_BUSINESS,
      rating: 4.9,
      reviewCount: 2100,
      deliveryTimeMins: 50,
      distanceKm: 3.1,
      area: 'Kukatpally',
      categoriesJson: JSON.stringify(['cat_pickle']),
      tagsJson: JSON.stringify(['Pickles', 'Spices', 'Organic']),
      isPureVeg: true,
      freeDelivery: true,
      offerText: 'Free sample with orders above ₹299',
      orderCount: 15000,
      lat: 17.4948,
      lng: 78.3996,
    },
  });

  await prisma.vendor.createMany({
    data: [
      {
        id: 'v4',
        name: "Meera's Mithai",
        tagline: 'Festival sweets, everyday joy',
        description: 'Homemade laddoos, barfis, mixture and traditional snacks.',
        imageUrl:
          'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=400',
        coverUrl:
          'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=800',
        type: VendorType.HOME_BUSINESS,
        rating: 4.6,
        reviewCount: 760,
        deliveryTimeMins: 45,
        distanceKm: 1.8,
        area: 'Jubilee Hills',
        categoriesJson: JSON.stringify(['cat_sweets', 'cat_bakery']),
        tagsJson: JSON.stringify(['Sweets', 'Snacks']),
        isPureVeg: true,
        offerText: '20% OFF on mithai boxes',
        orderCount: 5400,
        lat: 17.4326,
        lng: 78.4071,
      },
      {
        id: 'v5',
        name: 'Stitch & Style',
        tagline: 'Handcrafted ethnic wear',
        description:
          'Home boutique offering kurtis, sarees, kids wear and festive outfits.',
        imageUrl:
          'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=400',
        coverUrl:
          'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=800',
        type: VendorType.BOUTIQUE,
        rating: 4.4,
        reviewCount: 430,
        deliveryTimeMins: 60,
        distanceKm: 4.2,
        area: 'Banjara Hills',
        categoriesJson: JSON.stringify(['cat_clothes']),
        tagsJson: JSON.stringify(['Kurtis', 'Ethnic', 'Kids wear']),
        freeDelivery: true,
        offerText: 'Flat ₹150 OFF above ₹999',
        orderCount: 2100,
        lat: 17.4156,
        lng: 78.4347,
      },
      {
        id: 'v6',
        name: 'Green Bowl Kitchen',
        tagline: 'Eat clean, feel great',
        description:
          'Healthy bowls, salads, smoothies and calorie-counted meals.',
        imageUrl:
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
        coverUrl:
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800',
        type: VendorType.CLOUD_KITCHEN,
        rating: 4.8,
        reviewCount: 560,
        deliveryTimeMins: 30,
        distanceKm: 0.9,
        area: 'Gachibowli',
        categoriesJson: JSON.stringify(['cat_healthy', 'cat_cloud']),
        tagsJson: JSON.stringify(['Healthy', 'Keto', 'Salads']),
        freeDelivery: true,
        offerText: 'First week subscription 25% OFF',
        orderCount: 3200,
        lat: 17.4401,
        lng: 78.3489,
      },
      {
        id: 'v9',
        name: 'Biryani House Pro',
        tagline: 'Hyderabadi dum, done right',
        description:
          'Cloud kitchen specialising in authentic Hyderabadi dum biryani.',
        imageUrl:
          'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=400',
        coverUrl:
          'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=800',
        type: VendorType.CLOUD_KITCHEN,
        rating: 4.6,
        reviewCount: 3200,
        deliveryTimeMins: 42,
        distanceKm: 2.0,
        area: 'Madhapur',
        categoriesJson: JSON.stringify(['cat_cloud', 'cat_food']),
        tagsJson: JSON.stringify(['Biryani', 'Hyderabadi']),
        freeDelivery: true,
        offerText: 'Extra raita free on orders above ₹349',
        orderCount: 22000,
        lat: 17.4504,
        lng: 78.3885,
      },
    ],
  });

  await prisma.product.createMany({
    data: [
      {
        id: 'p1',
        vendorId: v1.id,
        categoryId: 'cat_food',
        name: 'Andhra Thali',
        description:
          'Rice, sambar, rasam, 2 curries, fry, pickle, curd & papad. Serves 1.',
        price: 149,
        mrp: 179,
        imageUrl:
          'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=400',
        type: ProductType.FOOD,
        isVeg: true,
        rating: 4.8,
        reviewCount: 420,
        tagsJson: JSON.stringify(['Bestseller', 'Thali']),
        prepTimeMins: 25,
      },
      {
        id: 'p2',
        vendorId: v1.id,
        categoryId: 'cat_food',
        name: 'Gongura Chicken',
        description: 'Tangy gongura leaves with tender chicken, Andhra style.',
        price: 199,
        mrp: 229,
        imageUrl:
          'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=400',
        type: ProductType.FOOD,
        isVeg: false,
        rating: 4.7,
        reviewCount: 310,
        tagsJson: JSON.stringify(['Spicy', 'Signature']),
        prepTimeMins: 30,
      },
      {
        id: 'p3',
        vendorId: v1.id,
        categoryId: 'cat_food',
        name: 'Pesarattu & Upma',
        description: 'Crispy green gram dosa with upma and ginger chutney.',
        price: 89,
        imageUrl:
          'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=400',
        type: ProductType.FOOD,
        isVeg: true,
        rating: 4.5,
        reviewCount: 180,
        tagsJson: JSON.stringify(['Breakfast']),
        prepTimeMins: 20,
      },
      {
        id: 'p4',
        vendorId: v1.id,
        categoryId: 'cat_food',
        name: 'Gutti Vankaya Curry',
        description: 'Stuffed brinjal in rich peanut-sesame gravy.',
        price: 129,
        imageUrl:
          'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400',
        type: ProductType.FOOD,
        isVeg: true,
        rating: 4.6,
        reviewCount: 95,
        tagsJson: JSON.stringify(['Curry']),
        prepTimeMins: 25,
      },
      {
        id: 'p5',
        vendorId: v2.id,
        categoryId: 'cat_cloud',
        name: 'Chicken Dum Biryani',
        description:
          'Aromatic basmati rice with marinated chicken, dum cooked.',
        price: 279,
        mrp: 329,
        imageUrl:
          'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=400',
        type: ProductType.FOOD,
        isVeg: false,
        rating: 4.6,
        reviewCount: 890,
        tagsJson: JSON.stringify(['Bestseller', 'Biryani']),
        prepTimeMins: 35,
      },
      {
        id: 'p6',
        vendorId: v2.id,
        categoryId: 'cat_cloud',
        name: 'Paneer Butter Masala',
        description:
          'Cottage cheese in creamy tomato-butter gravy. With 2 naan.',
        price: 249,
        mrp: 279,
        imageUrl:
          'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=400',
        type: ProductType.FOOD,
        isVeg: true,
        rating: 4.4,
        reviewCount: 340,
        tagsJson: JSON.stringify(['North Indian']),
        prepTimeMins: 25,
      },
      {
        id: 'p9',
        vendorId: v3.id,
        categoryId: 'cat_pickle',
        name: 'Mango Avakaya (500g)',
        description:
          'Classic Andhra mango pickle with mustard oil & spices.',
        price: 249,
        mrp: 299,
        imageUrl:
          'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=400',
        type: ProductType.PICKLE,
        isVeg: true,
        rating: 4.9,
        reviewCount: 1200,
        tagsJson: JSON.stringify(['Bestseller', 'Andhra']),
      },
      {
        id: 'p10',
        vendorId: v3.id,
        categoryId: 'cat_pickle',
        name: 'Gongura Pickle (250g)',
        description:
          'Tangy gongura leaves pickle — perfect with rice & ghee.',
        price: 149,
        imageUrl:
          'https://images.unsplash.com/photo-1506368249639-73a05d6f6488?w=400',
        type: ProductType.PICKLE,
        isVeg: true,
        rating: 4.8,
        reviewCount: 680,
        tagsJson: JSON.stringify(['Popular']),
      },
      {
        id: 'p11',
        vendorId: v3.id,
        categoryId: 'cat_pickle',
        name: 'Idli Karam Podi (200g)',
        description:
          'Spicy gunpowder for idli, dosa & rice. Made fresh weekly.',
        price: 99,
        mrp: 120,
        imageUrl:
          'https://images.unsplash.com/photo-1596797038530-2c107229654b?w=400',
        type: ProductType.PICKLE,
        isVeg: true,
        rating: 4.7,
        reviewCount: 450,
        tagsJson: JSON.stringify(['Podi']),
      },
      {
        id: 'p16',
        vendorId: 'v5',
        categoryId: 'cat_clothes',
        name: 'Cotton Printed Kurti',
        description:
          'Breathable cotton kurti with hand-block print. Casual & festive.',
        price: 799,
        mrp: 1299,
        imageUrl:
          'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=400',
        type: ProductType.CLOTHES,
        isVeg: true,
        rating: 4.5,
        reviewCount: 145,
        tagsJson: JSON.stringify(['Bestseller', 'Cotton']),
        sizesJson: JSON.stringify(['S', 'M', 'L', 'XL', 'XXL']),
      },
      {
        id: 'p19',
        vendorId: 'v6',
        categoryId: 'cat_healthy',
        name: 'Buddha Bowl',
        description:
          'Quinoa, roasted veggies, hummus, avocado & tahini dressing.',
        price: 249,
        imageUrl:
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
        type: ProductType.FOOD,
        isVeg: true,
        rating: 4.8,
        reviewCount: 240,
        tagsJson: JSON.stringify(['Healthy', 'Bestseller']),
        prepTimeMins: 15,
      },
      {
        id: 'p26',
        vendorId: 'v9',
        categoryId: 'cat_cloud',
        name: 'Hyderabadi Chicken Biryani',
        description:
          'Authentic kacchi dum biryani with raita & mirchi ka salan.',
        price: 299,
        mrp: 349,
        imageUrl:
          'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=400',
        type: ProductType.FOOD,
        isVeg: false,
        rating: 4.7,
        reviewCount: 2100,
        tagsJson: JSON.stringify(['Bestseller', 'Signature']),
        prepTimeMins: 40,
      },
      {
        id: 'p13',
        vendorId: 'v4',
        categoryId: 'cat_sweets',
        name: 'Besan Laddoo (6 pcs)',
        description:
          'Roasted gram flour laddoos with pure ghee & cardamom.',
        price: 180,
        mrp: 220,
        imageUrl:
          'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=400',
        type: ProductType.SWEET,
        isVeg: true,
        rating: 4.8,
        reviewCount: 320,
        tagsJson: JSON.stringify(['Bestseller']),
      },
    ],
  });

  console.log('Seed complete.');
  console.log('Demo logins (password: password123):');
  console.log('  Customer: priya@nestly.app');
  console.log('  Seller (Amma): amma@nestly.app');
  console.log('  Seller (Pickles): pickles@nestly.app');
  console.log('  Admin: admin@nestly.app');
  console.log('  Phone OTP: any 10-digit + OTP 123456');
  console.log(`Customer id: ${customer.id}`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
