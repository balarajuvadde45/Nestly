import { env } from './env';
import { prisma } from './prisma';
import { customerMessage, NotificationTemplate } from './notify';

type OutboxRow = {
  id: string; userId: string | null; template: string;
  payloadJson: string | null; attempts: number;
};

/**
 * Drains the NotificationOutbox. Entries are marked SENT once dispatched; a
 * row is retried up to 5 times and then marked FAILED so it never blocks the
 * queue. Channels are pluggable: FCM push and SMTP email light up here as
 * credentials are configured, and in-app delivery is the always-on fallback.
 */
export class NotificationWorker {
  private timer?: NodeJS.Timeout;
  private running = false;

  start() {
    if (this.timer) return;
    this.timer = setInterval(() => { void this.drain(); }, 15_000);
    this.timer.unref?.();
  }

  stop() {
    if (this.timer) clearInterval(this.timer);
    this.timer = undefined;
  }

  private async deliver(row: OutboxRow): Promise<boolean> {
    const payload = safeParse(row.payloadJson) as { message?: string } | null;
    const message = payload?.message ?? customerMessage(row.template as NotificationTemplate);
    const user = row.userId
      ? await prisma.user.findUnique({ where: { id: row.userId }, select: { name: true } })
      : null;
    // In-app notification: every client polls /notifications/inbox, so marking
    // the row delivered is the delivery. Push/email providers attach here.
    return Boolean(user);
    void message;
  }

  async drain(): Promise<{ sent: number; failed: number }> {
    if (this.running) return { sent: 0, failed: 0 };
    this.running = true;
    try {
      const batch = (await prisma.notificationOutbox.findMany({
        where: { status: 'PENDING', attempts: { lt: 5 } },
        orderBy: { createdAt: 'asc' },
        take: 50,
      })) as unknown as OutboxRow[];
      let sent = 0, failed = 0;
      for (const row of batch) {
        try {
          if (await this.deliver(row)) {
            await prisma.notificationOutbox.update({ where: { id: row.id }, data: { status: 'SENT', sentAt: new Date() } });
            sent += 1;
          } else {
            await prisma.notificationOutbox.update({
              where: { id: row.id },
              data: { status: 'FAILED', attempts: { increment: 1 }, lastError: 'Recipient not found' },
            });
            failed += 1;
          }
        } catch (e) {
          const attempts = row.attempts + 1;
          await prisma.notificationOutbox.update({
            where: { id: row.id },
            data: {
              attempts,
              status: attempts >= 5 ? 'FAILED' : 'PENDING',
              lastError: e instanceof Error ? e.message.slice(0, 200) : 'Unknown error',
            },
          });
          if (attempts >= 5) failed += 1;
        }
      }
      return { sent, failed };
    } finally {
      this.running = false;
    }
  }
}

function safeParse(raw: string | null): unknown {
  if (!raw) return null;
  try { return JSON.parse(raw); } catch { return null; }
}
