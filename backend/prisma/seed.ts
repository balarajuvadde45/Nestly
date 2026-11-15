import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

// Reference data only. Never creates accounts, products, orders, or promotions.
const categories = [
  ['cat_food', 'Local Food', 'Fresh meals from local kitchens', 'restaurant_menu', '#E7E3FD'],
  ['cat_cloud', 'Cloud Kitchens', 'Meals from professional kitchens', 'storefront', '#DBD6F8'],
  ['cat_tiffin', 'Tiffin', 'Lunch and dinner', 'lunch_dining', '#CFC8FB'],
  ['cat_healthy', 'Healthy Food', 'Salads and balanced meals', 'favorite', '#D8D2F7'],
  ['cat_bakery', 'Bakery', 'Bread, cakes and bakes', 'bakery_dining', '#EFEDFD'],
  ['cat_sweets', 'Sweets & Snacks', 'Chikkis, sweets and savouries', 'cake', '#E7E3FD'],
  ['cat_pickle', 'Pickles & Spices', 'Vegetarian and non-vegetarian pickles', 'spa', '#CFC8FB'],
  ['cat_clothes', 'Boutiques', 'Sarees, dresses and handmade fashion', 'checkroom', '#E1DDFA'],
  ['cat_fmcg', 'FMCG Wholesale', 'Distributor supplies and case packs', 'inventory_2', '#DBD6F8'],
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
