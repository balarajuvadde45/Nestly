-- Notification outbox gains delivery state so the worker can retry and fail rows safely.
ALTER TABLE "NotificationOutbox"
  ADD COLUMN "status" TEXT NOT NULL DEFAULT 'PENDING',
  ADD COLUMN "attempts" INTEGER NOT NULL DEFAULT 0;

-- Rows that already went out count as SENT.
UPDATE "NotificationOutbox" SET "status" = 'SENT' WHERE "sentAt" IS NOT NULL;

CREATE INDEX "NotificationOutbox_status_createdAt_idx" ON "NotificationOutbox"("status", "createdAt");
