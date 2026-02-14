import { Injectable } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { LoggingRepository } from 'src/repositories/logging.repository';

export type PushMessage = {
  token: string;
  title: string;
  body: string;
  data?: Record<string, string>;
};

@Injectable()
export class PushRepository {
  private app: admin.app.App | null = null;

  constructor(private logger: LoggingRepository) {
    this.logger.setContext(PushRepository.name);
  }

  private getApp(): admin.app.App | null {
    if (this.app) {
      return this.app;
    }

    const credentialsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
    if (!credentialsPath) {
      return null;
    }

    try {
      this.app = admin.initializeApp({
        credential: admin.credential.applicationDefault(),
      });
      return this.app;
    } catch (error) {
      this.logger.error(`Failed to initialize Firebase: ${error}`);
      return null;
    }
  }

  isConfigured(): boolean {
    return this.getApp() !== null;
  }

  async send(message: PushMessage): Promise<boolean> {
    const app = this.getApp();
    if (!app) {
      this.logger.debug('Firebase not configured, skipping push notification');
      return false;
    }

    try {
      await app.messaging().send({
        token: message.token,
        notification: {
          title: message.title,
          body: message.body,
        },
        data: message.data,
        android: {
          priority: 'high',
          notification: {
            channelId: 'memories',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      });
      return true;
    } catch (error) {
      this.logger.error(`Failed to send push notification: ${error}`);
      return false;
    }
  }

  async sendMany(messages: PushMessage[]): Promise<number> {
    const app = this.getApp();
    if (!app) {
      return 0;
    }

    let successCount = 0;
    for (const message of messages) {
      const success = await this.send(message);
      if (success) {
        successCount++;
      }
    }
    return successCount;
  }
}
