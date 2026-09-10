-- Expand Nestly from a home-food marketplace into a local retail, food, fashion,
-- and B2B wholesale marketplace.

ALTER TYPE "VendorType" ADD VALUE IF NOT EXISTS 'FOOD_OUTLET';
ALTER TYPE "VendorType" ADD VALUE IF NOT EXISTS 'PICKLES_AND_PACKAGED_FOOD';
ALTER TYPE "VendorType" ADD VALUE IF NOT EXISTS 'SWEETS_SNACKS';
ALTER TYPE "VendorType" ADD VALUE IF NOT EXISTS 'FMCG_DISTRIBUTOR';
ALTER TYPE "VendorType" ADD VALUE IF NOT EXISTS 'HANDMADE_PRODUCTS';

ALTER TYPE "ProductType" ADD VALUE IF NOT EXISTS 'FMCG';
ALTER TYPE "ProductType" ADD VALUE IF NOT EXISTS 'PERSONAL_CARE';
ALTER TYPE "ProductType" ADD VALUE IF NOT EXISTS 'HOME_CARE';
ALTER TYPE "ProductType" ADD VALUE IF NOT EXISTS 'BEVERAGE';
ALTER TYPE "ProductType" ADD VALUE IF NOT EXISTS 'READY_TO_COOK';
ALTER TYPE "ProductType" ADD VALUE IF NOT EXISTS 'SAREE';
ALTER TYPE "ProductType" ADD VALUE IF NOT EXISTS 'ACCESSORY';

ALTER TABLE "Vendor"
  ADD COLUMN "businessAddress" TEXT,
  ADD COLUMN "pincode" TEXT,
  ADD COLUMN "premisesType" TEXT NOT NULL DEFAULT 'BUSINESS_PLACE',
  ADD COLUMN "supportPhone" TEXT,
  ADD COLUMN "supportEmail" TEXT,
  ADD COLUMN "gstin" TEXT,
  ADD COLUMN "pan" TEXT,
  ADD COLUMN "fssaiLicense" TEXT,
  ADD COLUMN "fssaiExpiry" TIMESTAMP(3),
  ADD COLUMN "kycStatus" TEXT NOT NULL DEFAULT 'PENDING',
  ADD COLUMN "bankAccountLast4" TEXT,
  ADD COLUMN "bankVerified" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN "fulfillmentModesJson" TEXT NOT NULL DEFAULT '["LOCAL_DELIVERY"]',
  ADD COLUMN "serviceRadiusKm" DOUBLE PRECISION NOT NULL DEFAULT 5,
  ADD COLUMN "gstInvoiceAvailable" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN "acceptsWholesale" BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE "Product"
  ADD COLUMN "brandName" TEXT,
  ADD COLUMN "sku" TEXT,
  ADD COLUMN "unitLabel" TEXT,
  ADD COLUMN "minOrderQuantity" INTEGER NOT NULL DEFAULT 1,
  ADD COLUMN "casePackQuantity" INTEGER,
  ADD COLUMN "maxOrderQuantity" INTEGER,
  ADD COLUMN "stockQuantity" INTEGER,
  ADD COLUMN "hsnCode" TEXT,
  ADD COLUMN "gstRate" DOUBLE PRECISION,
  ADD COLUMN "batchNumber" TEXT,
  ADD COLUMN "manufactureDate" TIMESTAMP(3),
  ADD COLUMN "expiryDate" TIMESTAMP(3),
  ADD COLUMN "shelfLifeDays" INTEGER,
  ADD COLUMN "manufacturerName" TEXT,
  ADD COLUMN "packerName" TEXT,
  ADD COLUMN "originCountry" TEXT DEFAULT 'India',
  ADD COLUMN "fssaiLicense" TEXT,
  ADD COLUMN "isReturnable" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN "returnWindowDays" INTEGER,
  ADD COLUMN "madeToOrder" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN "dispatchTimeDays" INTEGER,
  ADD COLUMN "wholesaleTiersJson" TEXT NOT NULL DEFAULT '[]',
  ADD COLUMN "colorsJson" TEXT NOT NULL DEFAULT '[]',
  ADD COLUMN "material" TEXT;

ALTER TABLE "Order"
  ADD COLUMN "fulfillmentMode" TEXT NOT NULL DEFAULT 'LOCAL_DELIVERY',
  ADD COLUMN "invoiceRequired" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN "buyerGstin" TEXT,
  ADD COLUMN "sellerGstin" TEXT;

ALTER TABLE "OrderItem"
  ADD COLUMN "unitLabel" TEXT,
  ADD COLUMN "hsnCode" TEXT,
  ADD COLUMN "gstRate" DOUBLE PRECISION,
  ADD COLUMN "lineTax" DOUBLE PRECISION NOT NULL DEFAULT 0;

ALTER TABLE "SellerApplication"
  ADD COLUMN "premisesType" TEXT,
  ADD COLUMN "businessAddress" TEXT,
  ADD COLUMN "pincode" TEXT,
  ADD COLUMN "gstin" TEXT,
  ADD COLUMN "pan" TEXT,
  ADD COLUMN "fssaiLicense" TEXT,
  ADD COLUMN "categoriesJson" TEXT NOT NULL DEFAULT '[]',
  ADD COLUMN "documentsJson" TEXT NOT NULL DEFAULT '[]',
  ADD COLUMN "acceptsWholesale" BOOLEAN NOT NULL DEFAULT false;

CREATE INDEX "Vendor_type_city_idx" ON "Vendor"("type", "city");
CREATE INDEX "Vendor_acceptsWholesale_city_idx" ON "Vendor"("acceptsWholesale", "city");
CREATE INDEX "Product_type_isAvailable_idx" ON "Product"("type", "isAvailable");
CREATE INDEX "Product_sku_idx" ON "Product"("sku");
CREATE INDEX "Product_brandName_idx" ON "Product"("brandName");
