import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

// Reference data only. Never creates accounts, products, orders, or promotions.
const categories = [
  ['cat_food', 'Local Food', 'Fresh meals from local kitchens', 'restaurant_menu', '#FCE4EC'],
  ['cat_cloud', 'Cloud Kitchens', 'Meals from professional kitchens', 'storefront', '#E3F2FD'],
  ['cat_tiffin', 'Tiffin', 'Lunch and dinner', 'lunch_dining', '#E8F5E9'],
  ['cat_healthy', 'Healthy Food', 'Salads and balanced meals', 'favorite', '#E0F2F1'],
  ['cat_bakery', 'Bakery', 'Bread, cakes and bakes', 'bakery_dining', '#FFF3E0'],
  ['cat_sweets', 'Sweets & Snacks', 'Chikkis, sweets and savouries', 'cake', '#FCE4EC'],
  ['cat_pickle', 'Pickles & Spices', 'Vegetarian and non-vegetarian pickles', 'spa', '#E8F5E9'],
  ['cat_clothes', 'Boutiques', 'Sarees, dresses and handmade fashion', 'checkroom', '#F3E5F5'],
  ['cat_fmcg', 'FMCG Wholesale', 'Distributor supplies and case packs', 'inventory_2', '#E3F2FD'],
];
async function main() {
  for (const [sortOrder, [id, name, description, iconKey, colorHex]] of categories.entries()) {
    await prisma.shopCategory.upsert({
      where: { id }, update: {},
      create: { id, name, description, iconKey, colorHex, sortOrder, imageUrl: '' },
    });
  }
  console.log('Reference categories initialized');
}
main().catch(() => { console.error('Reference initialization failed'); process.exitCode = 1; })
  .finally(() => prisma.$disconnect());
