import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ThrottlerModule } from '@nestjs/throttler';
import { ScheduleModule } from '@nestjs/schedule';
import { BullModule } from '@nestjs/bull';
import { JwtModule } from '@nestjs/jwt';

import { AppController } from './app.controller';
import { AppService } from './app.service';

// Core modules
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { CustomersModule } from './modules/customers/customers.module';
import { SubscriptionsModule } from './modules/subscriptions/subscriptions.module';
import { BillingModule } from './modules/billing/billing.module';
import { PaymentsModule } from './modules/payments/payments.module';
import { TicketsModule } from './modules/tickets/tickets.module';
import { NocModule } from './modules/noc/noc.module';
import { RadiusModule } from './modules/radius/radius.module';
import { ReportsModule } from './modules/reports/reports.module';
import { SystemModule } from './modules/system/system.module';
import { NotificationsModule } from './modules/notifications/notifications.module';

// Database entities
import { User } from './modules/users/entities/user.entity';
import { Role } from './modules/users/entities/role.entity';
import { Permission } from './modules/users/entities/permission.entity';
import { Customer } from './modules/customers/entities/customer.entity';
import { Subscription } from './modules/subscriptions/entities/subscription.entity';
import { ServicePlan } from './modules/subscriptions/entities/service-plan.entity';
import { Invoice } from './modules/billing/entities/invoice.entity';
import { Payment } from './modules/payments/entities/payment.entity';
import { Ticket } from './modules/tickets/entities/ticket.entity';
import { Location } from './modules/system/entities/location.entity';

// Configuration
import databaseConfig from './config/database.config';
import authConfig from './config/auth.config';
import redisConfig from './config/redis.config';

@Module({
  imports: [
    // Configuration
    ConfigModule.forRoot({
      isGlobal: true,
      load: [databaseConfig, authConfig, redisConfig],
      envFilePath: ['.env.local', '.env'],
    }),

    // Database connection
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        type: 'mysql',
        host: configService.get('database.host'),
        port: configService.get('database.port'),
        username: configService.get('database.username'),
        password: configService.get('database.password'),
        database: configService.get('database.name'),
        entities: [
          User,
          Role,
          Permission,
          Customer,
          Subscription,
          ServicePlan,
          Invoice,
          Payment,
          Ticket,
          Location,
        ],
        synchronize: configService.get('NODE_ENV') === 'development',
        logging: configService.get('NODE_ENV') === 'development',
        timezone: '+00:00',
        charset: 'utf8mb4',
        extra: {
          connectionLimit: 50,
          acquireTimeout: 60000,
          timeout: 60000,
        },
      }),
      inject: [ConfigService],
    }),

    // RADIUS database connection (separate)
    TypeOrmModule.forRootAsync({
      name: 'radius',
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        type: 'mysql',
        host: configService.get('database.host'),
        port: configService.get('database.port'),
        username: configService.get('RADIUS_DB_USER'),
        password: configService.get('RADIUS_DB_PASSWORD'),
        database: configService.get('RADIUS_DB_NAME'),
        entities: [], // RADIUS entities will be added in RadiusModule
        synchronize: false, // Never sync RADIUS schema
        logging: false,
      }),
      inject: [ConfigService],
    }),

    // JWT Module
    JwtModule.registerAsync({
      global: true,
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        secret: configService.get('auth.jwtSecret'),
        signOptions: {
          expiresIn: configService.get('auth.jwtExpiresIn'),
        },
      }),
      inject: [ConfigService],
    }),

    // Rate limiting
    ThrottlerModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        ttl: 60, // 1 minute
        limit: configService.get('NODE_ENV') === 'production' ? 100 : 1000,
      }),
      inject: [ConfigService],
    }),

    // Task scheduling
    ScheduleModule.forRoot(),

    // Queue management with Redis
    BullModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        redis: {
          host: configService.get('redis.host'),
          port: configService.get('redis.port'),
          password: configService.get('redis.password'),
        },
        defaultJobOptions: {
          removeOnComplete: 50,
          removeOnFail: 100,
        },
      }),
      inject: [ConfigService],
    }),

    // Feature modules
    AuthModule,
    UsersModule,
    CustomersModule,
    SubscriptionsModule,
    BillingModule,
    PaymentsModule,
    TicketsModule,
    NocModule,
    RadiusModule,
    ReportsModule,
    SystemModule,
    NotificationsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
