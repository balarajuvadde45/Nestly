-- Add verified-purchase reviews, seller settlement ledger, notification outbox,
-- counters, serviceable delivery pincodes, commission rate, payment tracking, invoices.
CREATE TABLE "Review" (
    "id" TEXT NOT NULL,
    "productId" TEXT NOT NULL,
    "vendorId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "orderItemId" TEXT NOT NULL,
    "rating" INTEGER NOT NULL,
    "title" TEXT,
    "body" TEXT NOT NULL,
    "isHidden" BOOLEAN NOT NULL DEFAULT false,
    "moderatedBy" TEXT,
    "moderationNote" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Review_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "SellerLedgerEntry" (
    "id" TEXT NOT NULL,
    "vendorId" TEXT NOT NULL,
    "orderId" TEXT,
    "type" TEXT NOT NULL,
    "amount" DOUBLE PRECISION NOT NULL,
    "note" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SellerLedgerEntry_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "NotificationOutbox" (
    "id" TEXT NOT NULL,
    "userId" TEXT,
    "orderId" TEXT,
    "channel" TEXT NOT NULL,
    "template" TEXT NOT NULL,
    "payloadJson" TEXT NOT NULL DEFAULT '{}',
    "sentAt" TIMESTAMP(3),
    "failedAt" TIMESTAMP(3),
    "lastError" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "NotificationOutbox_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "Counter" (
    "id" TEXT NOT NULL,
    "value" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "Counter_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "Vendor" ADD COLUMN "serviceablePincodesJson" TEXT NOT NULL DEFAULT '[]';
ALTER TABLE "Vendor" ADD COLUMN "commissionRate" DOUBLE PRECISION NOT NULL DEFAULT 0;

ALTER TABLE "Order" ADD COLUMN "paymentProvider" TEXT;
ALTER TABLE "Order" ADD COLUMN "paymentProviderRef" TEXT;
ALTER TABLE "Order" ADD COLUMN "paymentUrl" TEXT;
ALTER TABLE "Order" ADD COLUMN "paidAt" TIMESTAMP(3);
ALTER TABLE "Order" ADD COLUMN "refundAmount" DOUBLE PRECISION;
ALTER TABLE "Order" ADD COLUMN "invoiceNumber" TEXT;

CREATE UNIQUE INDEX "Review.orderItemId_key" ON "Review"("orderItemId");
CREATE INDEX "Review_productId_isHidden_createdAt_idx" ON "Review"("productId", "isHidden", "createdAt");
CREATE INDEX "Review_vendorId_isHidden_idx" ON "Review"("vendorId", "isHidden");
CREATE INDEX "Review_userId_createdAt_idx" ON "Review"("userId", "createdAt");
CREATE INDEX "SellerLedgerEntry_vendorId_createdAt_idx" ON "SellerLedgerEntry"("vendorId", "createdAt");
CREATE INDEX "NotificationOutbox_sentAt_idx" ON "NotificationOutbox"("sentAt");
CREATE INDEX "NotificationOutbox_userId_createdAt_idx" ON "NotificationOutbox"("userId", "createdAt");
CREATE UNIQUE INDEX "Order.invoiceNumber_key" ON "Order"("invoiceNumber");

ALTER TABLE "Review" ADD CONSTRAINT "Review_productId_fkey" FOREIGN KEY ("productId") REFERENCES "Product"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Review" ADD CONSTRAINT "Review_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "Vendor"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Review" ADD CONSTRAINT "Review_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Review" ADD CONSTRAINT "Review_orderItemId_fkey" FOREIGN KEY ("orderItemId") REFERENCES "OrderItem"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "SellerLedgerEntry" ADD CONSTRAINT "SellerLedgerEntry_vendorId_fkey" FOREIGN KEY ("vendorId") REFERENCES "Vendor"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "Order" ADD COLUMN "paymentLinkId" TEXT;
